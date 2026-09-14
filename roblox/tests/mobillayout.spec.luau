--!nostrict
--[[ SKÖTSELPANELEN MOT MOBILENS RÖRELSEREGLAGE

	QA-order 2026-09-13 11:43, punkt 1–5. Provet mäter INGEN produktionsfil
	om — det mäter skötsellayouten mot en explicit modellerad reservzon för
	rörelsereglaget, vid två riktiga skärmstorlekar.

	══ VARFÖR DET HÄR PROVET BEHÖVDES ══════════════════════════════════

	`PreparationController` väjer redan för spaken. Men väjningen börjar i
	`pekreglagensKanter()` med

	    player:FindFirstChildOfClass("PlayerGui"):FindFirstChild("TouchGui")

	och letar sedan barnet `ThumbstickStart`. Saknas något av namnen, eller
	är spaken inte `Visible`, svarar funktionen 0 — och då faller panelens
	`x` tillbaka till `MARGINAL`, alltså rakt över spaken. Tyst: inget fel
	kastas, ingenting loggas.

	Och bänken kunde inte se det. `Players.LocalPlayer.FindFirstChildOfClass`
	svarade hårdkodat nil och `AbsolutePosition` fanns inte i stubben, så
	väjningsgrenen KÖRDES ALDRIG i något prov. Uppmätt före den här
	leveransen, med tom bänk: panelen låg på x 12..328 vid ALLA tre
	viewportar — iPhone, iPad och skrivbord — alltså alltid oväjd.

	══ RESERVZONEN ÄR MODELLERAD, INTE SLAGEN UPP ══════════════════════

	Punkt 5 i ordern: provet får inte hänga på ETT Roblox-internt barnnamn
	som enda sanning. Reserven nedan räknas därför ur projektets egna,
	dokumenterade reglagemått i `TouchControls` — samma hörn, samma skala —
	och namnuppslaget provas separat som en av flera vägar.

	`[antagande]` Robloxs default-tumspak har inte mätts i Studio av den
	här sessionen. Reserven är en modell av det nedre vänstra reglagefältet
	byggd på våra egna tal; exakta mått för standardspaken ska bekräftas i
	runtime. Modellen kan vara för snäv eller för generös — men den är
	EXPLICIT, och det är skillnaden mot att läsa ett namn och hoppas. ]]

local fails = 0
local function check(vad: string, ok: boolean, extra: any?)
	if ok then
		print(("  OK   %s%s"):format(vad, if extra ~= nil then "  " .. tostring(extra) else ""))
	else
		fails += 1
		print(("  FEL  %s%s"):format(vad, if extra ~= nil then "  " .. tostring(extra) else ""))
	end
end

local Players = game:GetService("Players")
local usv = game:GetService("UserInputService")
local cam = game:GetService("Workspace").CurrentCamera

--[[ Skärmar familjen faktiskt spelar på. Talen är dem projektet redan
	räknar med i `KontrollHjalp` och `UgnetaController`: iPhone i landskap
	har 749 px GUI-bredd och 309 px höjd, iPad 1194 x 761. ]]
local SKARMAR = {
	{ namn = "iPhone landskap", B = 749, H = 309 },
	{ namn = "iPad landskap", B = 1194, H = 761 },
}

--[[ Reglagets egna mått, ur `TouchControls`: RADIE 66 px yttermått, 24 px
	från vänsterkanten, 28 px upp från nederkanten, allt skalat med
	`clamp(H / 390, 0.62, 1)` precis som reglagen själva gör. ]]
local RADIE, KANT, BOTTEN, REF_H = 66, 24, 28, 390
local function reserv(B: number, H: number)
	local skala = math.clamp(H / REF_H, 0.62, 1)
	local sida = 2 * RADIE * skala
	local x0 = KANT * skala
	local y1 = H - BOTTEN * skala
	return { x0 = x0, x1 = x0 + sida, y0 = y1 - sida, y1 = y1, skala = skala }
end

local function overlappar(a, b): boolean
	return a.x0 < b.x1 and a.x1 > b.x0 and a.y0 < b.y1 and a.y1 > b.y0
end

--[[ En representativ pekreglagehierarki: `PlayerGui/TouchGui/<spaknamn>`,
	där spaken ligger exakt på reserven. Namnet är en PARAMETER — det är så
	provet kan visa att väjningen tystnar när Roblox kallar spaken något
	annat än `ThumbstickStart`. ]]
local function byggTouchGui(spakNamn: string, B: number, H: number)
	local pg = Instance.new("PlayerGui")
	pg.Name = "PlayerGui"
	local tg = Instance.new("ScreenGui")
	tg.Name = "TouchGui"
	tg.Parent = pg
	local r = reserv(B, H)
	local spak = Instance.new("Frame")
	spak.Name = spakNamn
	spak.Position = UDim2.fromOffset(r.x0, r.y0)
	spak.Size = UDim2.fromOffset(r.x1 - r.x0, r.y1 - r.y0)
	spak.Visible = true
	spak.Parent = tg
	local hopp = Instance.new("Frame")
	hopp.Name = "JumpButton"
	hopp.Position = UDim2.fromOffset(B - 140, H - 150)
	hopp.Size = UDim2.fromOffset(120, 120)
	hopp.Visible = true
	hopp.Parent = tg
	Players.LocalPlayer._barn = { pg }
	usv.TouchEnabled = true
	return spak
end

--[[ TOUCH PÅ, men INGEN `TouchGui` alls. Det är tidsfallet: reglagen kan
	vara oskapade när layouten körs första gången, och då finns inget att
	slå upp. Uppslaget kan aldrig klara det här — bara en reservzon kan. ]]
local function touchUtanTouchGui()
	Players.LocalPlayer._barn = {}
	usv.TouchEnabled = true
end

local function utanPekreglage()
	Players.LocalPlayer._barn = {}
	usv.TouchEnabled = false
end

local function panelenVid(B: number, H: number)
	cam.ViewportSize = { _typ = "Vector2", X = B, Y = H }
	return PreparationController.layout().interaktion
end

--[[ ══ 0. BÄNKEN KAN SE REGLAGEN ═══════════════════════════════════════
	Utan den här mätningen bevisar ingenting nedan något: en stub som
	svarar noll på alla mått ger en reserv som inget kan krocka med. ]]
print("\nSKÖTSELPANELEN MOT MOBILENS RÖRELSEREGLAGE")
print("\n── 0. Bänken kan mäta reglagens läge ──")
do
	local spak = byggTouchGui("ThumbstickStart", 749, 309)
	cam.ViewportSize = { _typ = "Vector2", X = 749, Y = 309 }
	local p, s = spak.AbsolutePosition, spak.AbsoluteSize
	check("spaken har ett läge i pixlar, inte nil",
		p ~= nil and s ~= nil and s.X > 1 and s.Y > 1,
		p and ("(%.0f · %.0f) %.0f x %.0f"):format(p.X, p.Y, s.X, s.Y) or "nil")
	local r = reserv(749, 309)
	check("reservzonen är en verklig yta", r.x1 - r.x0 > 10 and r.y1 - r.y0 > 10,
		("x %.0f..%.0f  y %.0f..%.0f  skala %.3f"):format(r.x0, r.x1, r.y0, r.y1, r.skala))
	check("spaken ligger där reserven säger",
		math.abs(p.X - r.x0) < 0.51 and math.abs(p.Y - r.y0) < 0.51,
		("spak (%.0f · %.0f) mot reserv (%.0f · %.0f)"):format(p.X, p.Y, r.x0, r.y0))
end

--[[ ══ 1. KRAVET: PANELEN LIGGER ALDRIG PÅ REGLAGET ════════════════════

	MÄTT PÅ X-AXELN, och det är ett medvetet val som kostade en omskrivning.

	Första versionen mätte rektangelöverlapp i två dimensioner. Den kunde
	inte bli röd på iPad: med tom bänk är panelen bara 16 px hög (höjden ÄR
	innehållet, och provet bygger inget innehåll), så den ligger y 733..749
	medan reserven slutar på 733 — de nuddar varandra utan att överlappa.
	Falsifieringen visade det: med väjningen urkopplad gav iPad ändå
	`OK   krockar alltså inte med reglaget  panel x 12..328`. En mätning som
	inte kan falla mäter ingenting.

	X-axeln är dessutom den RÄTTA axeln: den är den enda väjningen styr, och
	båda ytorna är bottenankrade, så en panel med verkligt innehåll växer
	UPPÅT och överlappar mer — aldrig mindre. Klarar vänsterkanten spaken
	klarar hela panelen den.

	Andra mätningen nedan binder ihop det: panelen ska ligga i samma
	nederkantsband som reserven. Utan den kunde x-kravet uppfyllas av en
	panel som flyttat upp i bild, och då mätte provet fel sak. ]]
print("\n── 1. Panelen viker för spaken, på riktiga skärmar ──")
for _, sk in ipairs(SKARMAR) do
	byggTouchGui("ThumbstickStart", sk.B, sk.H)
	local p = panelenVid(sk.B, sk.H)
	local r = reserv(sk.B, sk.H)
	check(("%s: panelen börjar till höger om spaken"):format(sk.namn),
		p.x0 >= r.x1 - 0.01,
		("panel x0 %.0f mot spakens högerkant %.0f"):format(p.x0, r.x1))
	check(("%s: och den ligger i samma nederkantsband som reglaget"):format(sk.namn),
		p.y1 > r.y0 and p.y1 <= sk.H,
		("panelens nederkant %.0f, reserven y %.0f..%.0f"):format(p.y1, r.y0, r.y1))
end

--[[ ══ 2. FYNDET: VÄJNINGEN TYSTNAR PÅ ETT NAMN ════════════════════════
	Samma skärm, samma reserv, samma spak — men barnet heter något annat,
	vilket är fallet med Robloxs nyare dynamiska tumspak. Kravet är att
	panelen viker ÄNDÅ. Gör den inte det ligger den på reglaget, och det
	är då spelaren tar i skötselpanelen i stället för att gå. ]]
print("\n── 2. Väjningen får inte hänga på ett enda internt namn ──")
for _, spakNamn in ipairs({ "DynamicThumbstickFrame", "ThumbstickFrame" }) do
	byggTouchGui(spakNamn, 749, 309)
	local p = panelenVid(749, 309)
	local r = reserv(749, 309)
	check(("iPhone, spaken heter %s: panelen viker ändå"):format(spakNamn),
		p.x0 >= r.x1 - 0.01,
		("panel x0 %.0f, reserv slutar %.0f"):format(p.x0, r.x1))
end

--[[ ══ 2b. RESERVEN MÅSTE KLARA SIG UTAN UPPSLAG ══════════════════════
	Touch är på men det finns ingen `TouchGui` att läsa. Uppslaget svarar 0
	av rätt skäl — det finns inget att hitta — och bara en reservzon räddar
	panelen. Det här fallet är omöjligt att klara med namnuppslag, och det
	är därför reserven är golvet och inte en fallback. ]]
print("\n── 2b. Touch på, men reglagen inte skapade än ──")
for _, sk in ipairs(SKARMAR) do
	touchUtanTouchGui()
	local p = panelenVid(sk.B, sk.H)
	local r = reserv(sk.B, sk.H)
	check(("%s: panelen viker utan att kunna slå upp spaken"):format(sk.namn),
		p.x0 >= r.x1 - 0.01,
		("panel x0 %.0f, reserv slutar %.0f"):format(p.x0, r.x1))
end

--[[ ══ 3. SKRIVBORDET RÖRS INTE ═════════════════════════════════════════
	Finns inga pekreglage ska panelen stå kvar på marginalen. En "fix" som
	flyttar den på skrivbordet har brutit något annat. ]]
print("\n── 3. Skrivbordet står kvar ──")
do
	utanPekreglage()
	local p = panelenVid(1280, 720)
	check("utan pekreglage ligger panelen kvar vid marginalen",
		p.x0 < 20, ("panel x0 %.0f"):format(p.x0))
end

--[[ ══ 4. KONTROLL: STEGPANELEN ÄR INTE PART I KROCKEN ══════════════════
	`spararLayout` är högerställd (`x = B - MARGINAL - bredd`) och kan inte
	nå det nedre vänstra hörnet. Mäts så att en framtida omflyttning av den
	inte tystar den här grinden. ]]
print("\n── 4. Stegpanelen ligger högerställd, utom räckhåll för spaken ──")
for _, sk in ipairs(SKARMAR) do
	byggTouchGui("ThumbstickStart", sk.B, sk.H)
	cam.ViewportSize = { _typ = "Vector2", X = sk.B, Y = sk.H }
	local s = PreparationController.layout().sparare
	local r = reserv(sk.B, sk.H)
	check(("%s: stegpanelen krockar inte med reglaget"):format(sk.namn),
		not overlappar(s, r),
		("sparare x %.0f..%.0f"):format(s.x0, s.x1))
end

if fails > 0 then
	print(("\n%d mätning(ar) föll."):format(fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("\nmobillayout.spec: alla gröna")
end
