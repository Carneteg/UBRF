--!nostrict
--[[
	PHYSICAL_WORLD_COHERENCE — punkt 1, 3 och 6

	Ordern på #162 efter Tobias andra Studio-test. Den här halvan av
	grinden mäter det som kräver BÅDE en byggd värld och en riktig HUD:

	  1  World ↔ gameplay parity — varje instruktion pekar på något som
	     faktiskt finns och går att nå i builden.
	  3  Equipment presence — skötselsteg som kräver utrustning har en
	     fysisk plats i miljön.
	  6  Contextual HUD — den aktiva instruktionen måste matcha spelarens
	     läge. Flytta henne ur kontext och HUD:en ska ändra sig.

	VARFÖR EN EGEN BANK. Det här är den enda specen som kör anläggningen,
	hela serverstacken OCH `init.client.luau` i samma körning. P0-3 var ett
	fel mellan två lager — servern nekade, gränssnittet lovade — och ett
	prov som bara kör det ena lagret kan inte se det.

	Kör: python3 roblox/tests/build.py tests/varldshud.spec.luau
	     && luau roblox/tests/.build/varldshud.spec.luau
]]

local fails = 0
local function check(namn, villkor, detalj)
	if villkor then
		print(string.format("  OK   %s%s", namn, detalj and ("  " .. detalj) or ""))
	else
		fails += 1
		print(string.format("  FEL  %s%s", namn, detalj and ("  " .. detalj) or ""))
	end
end
local function matning(namn, detalj)
	print(string.format("  mät  %s%s", namn, detalj and ("  " .. detalj) or ""))
end

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local M = BuildKit.M
local RACKVIDD = Config.STEG_RACKVIDD
local modell = workspace:FindFirstChild("Anläggning"):FindFirstChild("UBRF")
local bas = modell.PrimaryPart.CFrame

--[[ Hästarna byggs av produktionens egen startfunktion, samma anrop som
	`init.server.luau` gör. Att ställa dit en modell för hand hade mätt
	provets egen rigg. ]]
HastRigg.start()

local hastId = Stallet.FORSTA_DAGEN_HAST
local hastnamn = (UBRFSpelData.hastar[hastId] or {}).namn or hastId

local function hastModell(id)
	for _, m in ipairs(CollectionService:GetTagged("Horse")) do
		if m:GetAttribute("HorseId") == id then return m end
	end
	return nil
end

-- ══ 1. VÄRLD ↔ GAMEPLAY-PARITET ════════════════════════════════════════
print("\n1. Världen bär det spelet ber om")

local jack = hastModell(hastId)
check("första dagens häst finns som modell i den byggda världen",
	jack ~= nil, ("%s (%s)"):format(tostring(hastnamn), tostring(hastId)))

local rot = jack and ((jack :: any).PrimaryPart or jack:FindFirstChild("BodyCollider"))
check("hon har en fysisk rot att mäta avstånd mot", rot ~= nil,
	rot and rot.Name or "saknas")

--[[ Står hon på något? En häst som svävar över tomrummet är lika mycket
	ett brutet löfte som en instruktion utan mål. ]]
if rot then
	local p = rot.CFrame.Position
	local under, namn = nil, nil
	for _, d in ipairs(modell:GetDescendants()) do
		if d:IsA("BasePart") and d.CanCollide ~= false then
			local c, s = d.CFrame.Position, d.Size
			local y1 = (c.Y + s.Y / 2)
			if math.abs(p.X - c.X) <= s.X / 2 and math.abs(p.Z - c.Z) <= s.Z / 2
				and y1 <= p.Y + 0.1 and (under == nil or y1 > under) then
				under, namn = y1, d.Name
			end
		end
	end
	check("och hon står på en bärande yta, inte i tomrummet",
		under ~= nil and (p.Y - under) / M < 2.0,
		under and ("%s, %.2f m under hovarna"):format(namn, (p.Y - under) / M)
			or "INGEN YTA UNDER")
end

-- ══ 6. KONTEXTMEDVETEN HUD ═════════════════════════════════════════════
print("\n6. HUD:en säger sanningen om var spelaren står")

--[[ En riktig karaktär att flytta. Stubbens LocalPlayer har en attrapp
	utan rot; HUD:ens kontextfråga är ett AVSTÅND, och det behöver en
	kropp med ett läge. ]]
local function nyKaraktar(p)
	local k = Instance.new("Model")
	k.Name = "Spelare"
	local r = Instance.new("Part")
	r.Name = "HumanoidRootPart"
	r.Size = Vector3.new(2, 2, 1)
	r.CFrame = CFrame.new(p)
	r.Parent = k
	k.Parent = workspace
	return k, r
end

local karaktar, kropp = nyKaraktar((rot and rot.CFrame.Position) or Vector3.new(0, 0, 0))
Players.LocalPlayer.Character = karaktar

local state = Preparation.nyState(hastId, 1)
local vy = Preparation.vy(state, "preparing", 1, hastnamn)
--[[ Avsnitt 8 mäter spårarens framstegsruta mot vyns egna faser och
	behöver därför samma vy som ritades. ]]
local senasteVyForProv = vy
PreparationController.tillampa(vy)
PreparationController.uppdateraKontext()

local nastaMoment = vy.nastaMoment
check("vyn har ett moment på tur att mäta mot", nastaMoment ~= nil,
	tostring(nastaMoment))

--[[ `_ritadText` ger raderna i ritordning och rubriken står först. ]]
local function rubrikNu()
	local rader = PreparationController._ritadText()
	return (rader and rader[1]) or "(ingen rubrik)"
end

--[[ VID HÄSTEN. ]]
check("vid hästen är hon INTE utom räckhåll",
	PreparationController._utomRackhall() == false,
	("avstånd 0 studs mot räckvidd %d"):format(RACKVIDD))
local rubrikVid = rubrikNu()
check("och momentet på tur går att trycka på",
	nastaMoment == nil or PreparationController._momentGarAttTrycka(nastaMoment) == true,
	rubrikVid)

--[[ LÅNGT BORT — samma vy, annat läge. ]]
kropp.CFrame = CFrame.new((rot.CFrame.Position) + Vector3.new(RACKVIDD * 4, 0, 0))
PreparationController.uppdateraKontext()

check("fyra gånger räckvidden bort ÄR hon utom räckhåll",
	PreparationController._utomRackhall() == true,
	("%d studs bort mot räckvidd %d"):format(RACKVIDD * 4, RACKVIDD))

local rubrikBort = rubrikNu()
local vantad = Sprak.t("hud.ga_tillbaka", hastnamn)
check("och rubriken pekar TILLBAKA till hästen i stället för att ge en order",
	rubrikBort == vantad,
	("\"%s\" (väntat \"%s\")"):format(tostring(rubrikBort), tostring(vantad)))
check("rubriken är dessutom en ANNAN än den vid hästen — provet mäter en skillnad",
	rubrikBort ~= rubrikVid,
	("vid hästen \"%s\""):format(tostring(rubrikVid)))
check("och momentet går INTE längre att trycka på",
	nastaMoment == nil or PreparationController._momentGarAttTrycka(nastaMoment) ~= true,
	"ingen lyssnare kopplad")

--[[ TILLBAKA IGEN. En HUD som fastnar i "gå tillbaka" är lika trasig som
	en som aldrig säger det. ]]
kropp.CFrame = CFrame.new(rot.CFrame.Position)
PreparationController.uppdateraKontext()
check("tillbaka vid hästen återgår HUD:en", 
	PreparationController._utomRackhall() == false and rubrikNu() == rubrikVid,
	("\"%s\""):format(tostring(rubrikNu())))

--[[ ── MUTATIONEN (ordern punkt 8): HUD-steget ligger kvar ─────────────
	Utan den här kontrollen mäter proven ovan ingenting: en HUD som ALDRIG
	byter rubrik skulle falla, men en grind som inte kan skilja på "bytte"
	och "bytte av rätt skäl" är en grind som går att lura. Här kopplas
	gränsen bort — räckvidden sätts oändlig — och då ska rubriken bli kvar
	trots att spelaren står långt borta. ]]
do
	local sant = RACKVIDD
	kropp.CFrame = CFrame.new((rot.CFrame.Position) + Vector3.new(sant * 4, 0, 0))
	Config.STEG_RACKVIDD = math.huge
	--[[ Kontexten läses ur en local som togs vid inladdning, så mutationen
		måste gå genom samma väg spelaren gör: flytta, uppdatera. Att
		räckvidden är oändlig kan controllern inte se — den jämför bara. ]]
	PreparationController.uppdateraKontext()
	Config.STEG_RACKVIDD = sant
	check("MUTATION: med oändlig räckvidd blir spelaren aldrig 'borta' — regeln mäter avståndet",
		PreparationController._utomRackhall() == false,
		("48 studs bort, räckvidd ∞ → utomRackhall = %s")
			:format(tostring(PreparationController._utomRackhall())))
	kropp.CFrame = CFrame.new(rot.CFrame.Position)
	PreparationController.uppdateraKontext()
end

--[[ ── 7. INGEN INTERN ETIKETT NÅR SPELAREN ──────────────────────────
	Ordern punkt 7 räknar upp "intern etikett (`dorrgul`) till spelare"
	bland de fynd som ska bli permanent regression. Felet är rättat i
	`DorrService.objektFor`, men rättningen har aldrig haft en grind:
	texten kunde glida tillbaka utan att något blev rött.

	Tokenen är datans egna ord för en öppning — de säger färg och
	fabrikat, inte vad saken heter på svenska. Ingen av dem får stå i en
	prompt. ]]
print("\n7. Datans egna ord stannar i datan")
do
	local TOKEN = { "dorrgul", "dorrvit", "dorrmork", "dorr", "portbla", "portplat",
		"portsilver", "valv", "rund", "fonster" }
	DorrService.start()
	local prompts = {}
	for _, d in ipairs(workspace:GetDescendants()) do
		if d.ClassName == "ProximityPrompt" then table.insert(prompts, d) end
	end
	local function lackor(): { string }
		local ut = {}
		for _, pr in ipairs(prompts) do
			for _, falt in ipairs({ "ObjectText", "ActionText" }) do
				local txt = string.lower(tostring((pr :: any)[falt]))
				for _, t in ipairs(TOKEN) do
					if string.find(txt, t, 1, true) then
						table.insert(ut, ("%s.%s = %q"):format(pr.Parent and pr.Parent.Name or "?", falt, (pr :: any)[falt]))
					end
				end
			end
		end
		return ut
	end
	local nu = lackor()
	check("ingen prompt skriver datans interna typnamn",
		#nu == 0 and #prompts > 0,
		#nu == 0 and ("%d prompts, inga tokenläckor"):format(#prompts)
			or table.concat(nu, " · "))

	--[[ MUTATIONEN: skriv tillbaka felet på EN prompt. Kan grinden inte bli
		röd av det har den inte fångat fyndet — den har bara råkat vara
		grön. ]]
	local offer, gammalText = nil, nil
	for _, pr in ipairs(prompts) do
		local blad = pr.Parent
		local typ = blad and blad:GetAttribute("Oppningstyp")
		if typeof(typ) == "string" then
			offer, gammalText = pr, pr.ObjectText
			pr.ObjectText = typ
			break
		end
	end
	if offer then
		check("MUTATION: en prompt som skriver `Oppningstyp` rakt av fälls",
			#lackor() > 0,
			("satte ObjectText = %q → %d läcka(or)"):format(offer.ObjectText, #lackor()))
		offer.ObjectText = gammalText
	end
end

--[[ ── 7b. DÖRRENS HANDLINGSTEXT PÅ SPELARENS SPRÅK ─────────────────

	Lokal Studio-QA, §8: `ProximityPrompt.ActionText` stod kvar på `Öppna`
	och `Stäng` under `en-us` på SAMTLIGA tretton dörrar, medan `ObjectText`
	bredvid stod korrekt på `Door`. Att objektet översattes bevisade att
	`Prompttext` kördes — det var handlingen som skrevs över.

	Orsaken är ORDNINGEN. Klienten översätter när ATTRIBUTET ändras;
	`DorrService` satte attributet först och skrev sedan över `ActionText`
	med en hårdkodad svensk sträng. Serverns skrivning replikerar och kom
	sist.

	VARFÖR INGEN GRIND SÅG DET. Bänken hade ingen `GetAttributeChangedSignal`
	alls, så `Prompttext` kunde aldrig köras här — modulen var omätt, och
	ordningen mellan två skrivningar går inte att mäta utan den. Signalen
	finns nu i stubben, och det här provet driver den riktiga klientmodulen
	mot den riktiga servertjänsten. ]]
print("\n7b. Dörren talar spelarens språk")
do
	local prompts = {}
	for _, blad in ipairs(DorrService.dorrar()) do
		local pr = blad:FindFirstChild("DorrPrompt")
		if pr then table.insert(prompts, pr) end
	end
	check("det finns dörrprompter att mäta", #prompts > 0,
		("%d st"):format(#prompts))

	local fore = Sprak.eget()
	Sprak.satLocale("en-us")
	--[[ Klientmodulen startas EFTER att locale bytts, precis som en engelsk
		spelares klient gör. ]]
	Prompttext.start()

	local function svenska(): { string }
		local ut = {}
		for _, pr in ipairs(prompts) do
			if pr.ActionText ~= Sprak.iSprak("en", pr:GetAttribute("SprakNyckel")) then
				table.insert(ut, ("%s=%q"):format(
					tostring(pr:GetAttribute("SprakNyckel")), tostring(pr.ActionText)))
			end
		end
		return ut
	end

	local kvar = svenska()
	check("varje dörr säger Open, inte Öppna, på en-us",
		#kvar == 0,
		#kvar == 0 and ("%d prompts, alla översatta"):format(#prompts)
			or table.concat(kvar, " · "))

	--[[ OCH EFTER ETT TRYCK. Det var där felet satt: `Triggered` skrev om
		texten, och en dörr som öppnats sa `Stäng` till en engelsk spelare
		resten av sessionen. ]]
	local en = prompts[1]
	en.Triggered:Fire()
	check("och efter ett tryck står det Close, inte Stäng",
		en.ActionText == Sprak.iSprak("en", "dorr.stang"),
		('nyckel %s → "%s"'):format(tostring(en:GetAttribute("SprakNyckel")),
			tostring(en.ActionText)))
	en.Triggered:Fire()
	check("och tillbaka till Open när den stängs",
		en.ActionText == Sprak.iSprak("en", "dorr.oppna"),
		('nyckel %s → "%s"'):format(tostring(en:GetAttribute("SprakNyckel")),
			tostring(en.ActionText)))

	--[[ MUTATIONEN: skriv över texten EFTER attributet, precis som den
		gamla ordningen gjorde. Håller rättelsen i `Prompttext` — som
		hävdar översättningen tillbaka — ska den mätningen ändå bli grön,
		och då är det försvaret som mäts. Blir den svensk är grinden
		blind. ]]
	do
		en.ActionText = "Öppna"
		check("MUTATION: en överskrivning med svensk text hävdas tillbaka",
			en.ActionText == Sprak.iSprak("en", "dorr.oppna"),
			('efter överskrivning: "%s"'):format(tostring(en.ActionText)))
	end

	--[[ …och att provet mäter en SKILLNAD: på svenska ska det stå Öppna. ]]
	Sprak.satLocale("sv-se")
	Prompttext.skrivOm(en)
	check("på sv-se står det Öppna igen — provet mäter språket, inte en konstant",
		en.ActionText == Sprak.iSprak("sv", "dorr.oppna"),
		('"%s"'):format(tostring(en.ActionText)))
	Sprak.satLocale(fore)
	Prompttext.skrivOm(en)
end

--[[ ── 8. HUD:EN SKYMMER INTE SPELET ────────────────────────────────

	PO-order 09:36. Quest-/HUD-panelen låg mitt på skärmen nedtill, 92 %
	bred och 300 px hög, och den låg där hela tiden — med hela steglistan
	och alla stora val uppe även när spelaren inte höll på med någonting.
	Den skymde hästen, avataren och sikten framåt.

	Ordern har fyra krav, och de mäts var för sig här:

	  a  spåraren sitter uppe till HÖGER,
	  b  den är HOPFÄLLD som standard och går att fälla ut och ihop igen,
	  c  hopfälld går den aldrig in i siktrutan — på någon av de skärmar
	     familjen spelar på,
	  d  de STORA VALEN finns bara medan spelaren faktiskt interagerar.

	Talen läses ur `PreparationController.layout()`, som är samma räkning
	panelen ritas med, och de synliga lägena ur de BYGGDA instanserna. Ett
	prov som hade burit sin egen kopia av layouten hade kunnat vara grönt
	medan skärmen visade något annat. ]]
print("\n8. HUD:en skymmer inte spelet")
do
	local cam = game:GetService("Workspace").CurrentCamera
	local vpFore = cam.ViewportSize
	local ytor = PreparationController._ytor()

	local function vid(b, h)
		cam.ViewportSize = { _typ = "Vector2", X = b, Y = h }
		PreparationController.tillampaLayout()
		return PreparationController.layout()
	end
	--[[ Skär två rutor varandra? Kant i kant räknas inte som överlapp. ]]
	local function skar(a, b)
		return a.x0 < b.x1 and b.x0 < a.x1 and a.y0 < b.y1 and b.y0 < a.y1
	end

	--[[ a. UPPE TILL HÖGER. ]]
	local L = vid(1920, 1080)
	check("spåraren sitter uppe till höger, inte mitt på skärmen nedtill",
		L.kompakt.x1 <= L.vpBredd and L.kompakt.x0 > L.vpBredd * 0.5
			and L.kompakt.y1 < L.vpHojd * 0.5,
		("ruta %d,%d–%d,%d av %d×%d"):format(L.kompakt.x0, L.kompakt.y0,
			L.kompakt.x1, L.kompakt.y1, L.vpBredd, L.vpHojd))

	--[[ b. HOPFÄLLD SOM STANDARD, och den går att fälla. ]]
	check("den är hopfälld som standard",
		PreparationController._utvidgad() == false
			and ytor.steg.Visible == false and ytor.hjalp.Visible == false,
		("utvidgad %s · steglista %s · hjälptext %s"):format(
			tostring(PreparationController._utvidgad()),
			tostring(ytor.steg.Visible), tostring(ytor.hjalp.Visible)))
	check("växlingen är en riktig knapp med full träffyta",
		ytor.vaxla ~= nil and ytor.vaxla.ClassName == "TextButton"
			and ytor.vaxla.Size.Y.Offset >= PreparationController.TRAFFYTA,
		("%s · %d px hög"):format(tostring(ytor.vaxla and ytor.vaxla.ClassName),
			ytor.vaxla and ytor.vaxla.Size.Y.Offset or -1))

	ytor.vaxla.Activated:Fire()
	local Lut = PreparationController.layout()
	check("ett tryck fäller UT den: stegen och hjälptexten kommer fram",
		PreparationController._utvidgad() == true
			and ytor.steg.Visible == true and ytor.hjalp.Visible == true
			and Lut.sparare.y1 > Lut.kompakt.y1,
		("%d px hög utfälld mot %d px hopfälld, %d steg"):format(
			Lut.sparare.y1 - Lut.sparare.y0,
			Lut.kompakt.y1 - Lut.kompakt.y0, Lut.antalSteg))
	ytor.vaxla.Activated:Fire()
	check("och ett tryck till fäller ihop den igen",
		PreparationController._utvidgad() == false
			and ytor.steg.Visible == false,
		("utvidgad %s"):format(tostring(PreparationController._utvidgad())))

	--[[ c. SIKTRUTAN — på varje skärm familjen spelar på. ]]
	local skarmar = {
		{ namn = "iPad landskap 1024×768", b = 1024, h = 768 },
		{ namn = "iPad porträtt 768×1024", b = 768, h = 1024 },
		{ namn = "laptop 1440×900", b = 1440, h = 900 },
		{ namn = "skrivbord 1920×1080", b = 1920, h = 1080 },
		{ namn = "telefon 390×844", b = 390, h = 844 },
	}
	for _, sk in ipairs(skarmar) do
		local m = vid(sk.b, sk.h)
		check(("hopfälld skymmer den inget på %s"):format(sk.namn),
			not skar(m.kompakt, m.sikt),
			("spårare %d,%d–%d,%d · sikt %d,%d–%d,%d"):format(
				m.kompakt.x0, m.kompakt.y0, m.kompakt.x1, m.kompakt.y1,
				m.sikt.x0, m.sikt.y0, m.sikt.x1, m.sikt.y1))
	end

	--[[ MUTATIONEN: kan mätningen ÖVER HUVUD TAGET bli röd?

		En "skär inte"-kontroll är grön av sig själv så fort någon av
		rutorna råkar hamna utanför. Här krymps skärmen till en höjd ingen
		spelar på (320×200). Då NÅR den hopfällda spåraren ned i siktrutan,
		och skärningen ska slå till. Blir den inte röd mäter raderna ovan
		ingenting. ]]
	do
		local m = vid(320, 200)
		check("MUTATION: på en 320×200-skärm når spåraren ned i siktrutan — mätningen kan bli röd",
			skar(m.kompakt, m.sikt),
			("spårare %d,%d–%d,%d · sikt %d,%d–%d,%d"):format(
				m.kompakt.x0, m.kompakt.y0, m.kompakt.x1, m.kompakt.y1,
				m.sikt.x0, m.sikt.y0, m.sikt.x1, m.sikt.y1))
	end

	--[[ Interaktionspanelen FÅR vara central — det är ordens egen
		formulering, och den gäller bara medan man håller på. Mäts för att
		skillnaden mot spåraren ska vara avsiktlig och inte en slump. ]]
	local mi = vid(1024, 768)
	check("interaktionspanelen ligger däremot centralt — tillfälligt, som ordern säger",
		skar(mi.interaktion, mi.sikt),
		("interaktion %d,%d–%d,%d"):format(mi.interaktion.x0, mi.interaktion.y0,
			mi.interaktion.x1, mi.interaktion.y1))

	cam.ViewportSize = vpFore
	PreparationController.tillampaLayout()

	--[[ d. DE STORA VALEN HÖR TILL STUNDEN.

		Samma kropp och samma häst som i avsnitt 6. Vid hästen ska valen
		finnas; fyra räckvidder bort ska de inte finnas alls — inte gråa,
		inte kvar, utan borta med panelen de bor i. ]]
	kropp.CFrame = CFrame.new(rot.CFrame.Position)
	PreparationController.uppdateraKontext()
	PreparationController.tillampa(Preparation.vy(state, "preparing", 2, hastnamn))
	local valVid = #PreparationController._synligaMoment()
	check("vid hästen finns de stora valen, och de ligger i interaktionspanelen",
		valVid > 0 and ytor.interaktion.Visible == true,
		("%d val · panel %s"):format(valVid, tostring(ytor.interaktion.Visible)))

	--[[ Framstegen är riktiga tal ur vyn, inte en dekoration. ]]
	do
		local klara, totalt = PreparationController._framsteg()
		check("spåraren räknar framsteg ur vyns egna faser",
			totalt == #(senasteVyForProv.steg or {}) and totalt > 0
				and klara >= 0 and klara <= totalt,
			("%d/%d mot %d faser i vyn"):format(klara, totalt,
				#(senasteVyForProv.steg or {})))
		check("och rutan visar samma tal som räkningen",
			ytor.framsteg.Text == ("%d/%d"):format(klara, totalt),
			('"%s"'):format(tostring(ytor.framsteg.Text)))
	end

	kropp.CFrame = CFrame.new((rot.CFrame.Position) + Vector3.new(RACKVIDD * 4, 0, 0))
	PreparationController.uppdateraKontext()
	check("fyra räckvidder bort är de stora valen BORTA, inte bara gråa",
		#PreparationController._synligaMoment() == 0
			and ytor.interaktion.Visible == false,
		("%d val · panel %s"):format(#PreparationController._synligaMoment(),
			tostring(ytor.interaktion.Visible)))
	check("men spåraren står kvar och säger vad som gäller",
		ytor.sparare.Visible ~= false and ytor.rubrik.Text ~= "",
		('"%s"'):format(tostring(ytor.rubrik.Text)))

	--[[ MUTATIONEN: valen får inte tas bort av något ANNAT än räckvidden.
		Med oändlig räckvidd är spelaren aldrig borta, och då ska panelen
		stå kvar trots att kroppen står 48 studs bort. Faller den ändå är
		det inte avståndet regeln mäter. ]]
	do
		local sant = Config.STEG_RACKVIDD
		Config.STEG_RACKVIDD = math.huge
		PreparationController.uppdateraKontext()
		Config.STEG_RACKVIDD = sant
		check("MUTATION: med oändlig räckvidd står valen kvar — det är avståndet som styr dem",
			#PreparationController._synligaMoment() > 0
				and ytor.interaktion.Visible == true,
			("%d val 48 studs bort"):format(#PreparationController._synligaMoment()))
	end

	kropp.CFrame = CFrame.new(rot.CFrame.Position)
	PreparationController.uppdateraKontext()
end

if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	print("PHYSICAL_WORLD_COHERENCE (HUD): FAIL")
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error("varldshud.spec: " .. fails .. " fel")
end
print("\nPHYSICAL_WORLD_COHERENCE (HUD): alla gröna")
