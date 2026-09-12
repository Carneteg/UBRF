--!strict
--[[
	KONTROLLERNA, KORT — vad gör jag för att sitta upp, byta gångart och hoppa?

	Tobias frågade, och frågan var befogad: reglagen fanns bara i koden.
	Den här modulen svarar med de reglage som FAKTISKT är bundna, läst ur
	src/client/Input.luau, src/client/TouchControls.luau och
	init.client.luau. Ingenting här är påhittat, och ingenting här ÄNDRAR
	en bindning — ridfysik, hjälpsemantik och hoppmodell rörs inte.

	REGLAGEN FÖLJER INMATNINGEN, inte plattformen. Samma regel som
	UgnetaController.medLedtext: en ren pekenhet ska aldrig få en bokstav
	hon inte kan trycka på, och en iPad med tangentbord ska få bokstaven.
	Ordningen är tangentbord → gamepad → touch, för att det är den
	inmatning spelaren faktiskt har framför sig.

	VAD SOM INTE STÅR HÄR: webbens reglage. De skiljer sig verkligt —
	webben har ingen gångartsknapp (gångarten följer av skänkel och tygel)
	och inget hoppreglage (avsprånget kommer ur anridningen). Att skriva
	Roblox-tangenter i webbens hjälp, eller tvärtom, vore att påstå en
	paritet som inte finns. Varje yta visar sina egna.

	── ÅTERÖPPNINGEN (#161) ─────────────────────────────────────────

	Panelen gick att STÄNGA på varje yta men bara att ÖPPNA med `H`. På en
	iPad utan tangentbord var hjälpen därmed en engångsruta: när den väl
	var bortstängd fanns ingen väg tillbaka. QA-rapporten i #153 kallade
	det P2-4b, och #161 löser det med tre vägar in, en per inmatning:

	  · tangentbord  `H`, oförändrad,
	  · pekskärm     en liten permanent `?`-knapp uppe till höger,
	  · gamepad      `DPadUp`.

	`DPadUp` är vald för att den är LEDIG, och det är kontrollerat, inte
	antaget: `Input.luau` binder Thumbstick1, ButtonA, ButtonB, ButtonR1,
	ButtonL1, ButtonR2 och ButtonL2, och `init.client.luau` binder ButtonY
	(lektionen vidare) och ButtonX (se ritten). Styrkorset rörs inte av
	någon av dem, och till skillnad från ButtonStart och ButtonSelect är
	det inte heller reserverat av Roblox egna menyer. Ingen rid-, hopp-
	eller replaybindning har flyttats för att göra plats — det var ett
	uttryckligt krav i #161.

	`?`-KNAPPEN ÄR EGEN GUI, inte en del av `TouchControls`. Skälet är att
	`TouchControls` rivs vid avsittning: en hjälpknapp som bara finns i
	sadeln hade varit borta i stallet, alltså precis när frågan "vad gör
	jag nu?" är som vanligast. Den ligger uppe till höger, där varken
	spaken (nere vänster), ridknapparna (nere höger), förberedelse-HUD:en
	(nere mitten), Ugnetas kort (uppe mitten) eller ridanalysen (uppe
	vänster) ligger — och därmed blockerar den varken ridkontroller eller
	replay.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

--[[ #162: raderna bär NYCKLAR, texten kommer ur språkkanonen. Se
     `RADER` nedan för varför nyckeln och inte texten är radens identitet. ]]
local Sprak = require(game:GetService("ReplicatedStorage").HorseCore.Sprak)

local KontrollHjalp = {}

local player = Players.LocalPlayer

local gui: ScreenGui? = nil
local panel: Frame? = nil
local rader: { TextLabel } = {}
local visadEnGang = false
--[[ Den permanenta öppningsknappen. Egen ScreenGui, se filhuvudet. ]]
local oppnaGui: ScreenGui? = nil
local oppnaKnapp: TextButton? = nil

local FARG_MORK = Color3.fromRGB(12, 14, 18)
local FARG_TEXT = Color3.fromRGB(246, 242, 232)
local FARG_GULD = Color3.fromRGB(232, 181, 74)

--[[ Reglaget som öppnar hjälpen igen, per inmatning. Publik för att provet
     ska läsa samma beslut som panelen — och för att `docs/KONTROLLMATRIS.md`
     ska gå att kontrollera mot källan i stället för mot minnet. ]]
KontrollHjalp.GAMEPADKNAPP = Enum.KeyCode.DPadUp

--[[ Avsittningens gamepadknapp (#162 blockerare 2). Samma skäl till att den
     är publik: `init.client.luau` binder den, panelen skriver ut den och
     provet läser den — ett beslut, en plats.

     `DPadDown` är valt för att det är den enda naturliga knappen som är
     LEDIG, kontrollerat mot hela `roblox/src`:
       Input.luau       Thumbstick1, ButtonA/B, R1/L1, R2/L2
       init.client      ButtonY (lektionen), ButtonX (se ritten), DPadUp (hjälp)
     Kvar av styrkorset: ned, vänster, höger. `ButtonStart`/`ButtonSelect`
     rörs inte — Roblox har egna menyer på dem.

     Styrkors ned parar sig dessutom med styrkors upp: hjälpen upp, av
     hästen ned. Ingen befintlig rid-, hopp-, replay- eller hjälpbindning
     ändras. ]]
KontrollHjalp.AVSITTNING_GAMEPAD = Enum.KeyCode.DPadDown

--[[ LEDTEXTEN HÄRLEDS UR BINDNINGEN, inte skriven för hand vid sidan om.

     Blockerare 2 var två fel i samma rad: bindningen saknades OCH raden
     påstod "E", en tangent, som gamepadens reglage. Det andra felet är
     möjligt så länge texten och bindningen är två oberoende strängar —
     precis den dubbla sanning `CLAUDE.md` varnar för, i miniatyr.

     Nu slår panelen upp knappen här. Byts konstanten följer texten med,
     och en knapp utan namn syns direkt i panelen i stället för att bli en
     tyst lögn. ]]
local PADNAMN: { [Enum.KeyCode]: string } = {
	[Enum.KeyCode.DPadUp] = "hjalp.styrkors_upp",
	[Enum.KeyCode.DPadDown] = "hjalp.styrkors_ned",
	[Enum.KeyCode.DPadLeft] = "hjalp.styrkors_vanster",
	[Enum.KeyCode.DPadRight] = "hjalp.styrkors_hoger",
}

local function padNamn(kod: Enum.KeyCode): string
	local nyckel = PADNAMN[kod]
	if nyckel then return Sprak.t(nyckel) end
	return Sprak.t("hjalp.namnlos_knapp", tostring(kod))
end

--[[ RADERNA. `tgb`/`pad`/`pek` är de reglage som är bundna i produktionen:

     tangentbord  Input.luau: W/S framåt-bakåt, A/D styr, LeftShift gångart
                  upp, LeftControl gångart ner, Q tygel, F parad, Z/C sits,
                  Space hopp. init.client.luau: E sitt upp/av.
     gamepad      Input.luau: Thumbstick1 styr och framåt, ButtonR1 gångart
                  upp, ButtonL1 gångart ner, ButtonR2 tygel, ButtonB parad,
                  ButtonL2 sits, ButtonA hopp.
     touch        TouchControls.luau bygger Spak samt knapparna SITT AV,
                  ▲ FRAMÅT, ▼ LUGNARE, TYGEL, HALVHALT, DJUP SITS, HOPP.
                  Texterna nedan är knapparnas EGNA etiketter.

     Ändras en bindning ska den här tabellen ändras med den. Provet läser
     Input.luau:s egna KeyCodes och faller när en rad påstår en tangent som
     inte längre är bunden. ]]
local RADER = {
	--[[ VARJE RAD BÄR EN NYCKEL, inte en färdig text. Nyckeln är radens
	     identitet: `_rad()` slår upp på den, och texten sätts när panelen
	     ritas — där spelarens språk är känt. Låg den svenska texten kvar
	     som identitet hade en engelsk spelare fått en panel som slog upp
	     rader på ett språk hon inte läser.

	     `pek` pekar på pekknappens EGEN etikett i språkkanonen
	     (`touch.*`), samma nyckel som `TouchControls` ritar knappen med.
	     Två sanningar där vore en instruktion som säger något annat än
	     knappen den beskriver. ]]
	--[[ `pad` stod "E" här (#162 blockerare 2). `E` är en TANGENT. En spelare
	     med bara handkontroll läste alltså en instruktion hon inte kunde
	     följa — och kunde faktiskt inte sitta av alls, för `begarAvsittning`
	     var bara bunden till `E`. Uppsittningen gick via ProximityPrompt,
	     så hon kom UPP på hästen och blev kvar där. ]]
	{ nyckel = "hjalp.sitt_upp_av", tgb = "E",
	  pad = padNamn(KontrollHjalp.AVSITTNING_GAMEPAD),   pek = "touch.sitt_av" },
	{ nyckel = "hjalp.framat_bakat", tgb = "W / S", padNyckel = "hjalp.vanster_spak", pek = "hjalp.spaken" },
	{ nyckel = "hjalp.styr",         tgb = "A / D", padNyckel = "hjalp.vanster_spak", pek = "hjalp.spaken" },
	--[[ #162 iPad: pekytan har inte längre ▲/▼ som huvudreglage — gångarten
	     väljs på en NAMNGIVEN knapp (HALT/SKRITT/TRAV/GALOPP). Raderna pekar
	     därför på knappgruppen i stället för på en knapp som inte ritas
	     längre; en hjälp som namnger ett reglage spelaren inte kan se är
	     precis det fel `pek`-kolumnen finns för att undvika. ]]
	{ nyckel = "hjalp.hogre_gangart", tgb = "Shift", pad = "R1", pek = "touch.gangartsknappar" },
	{ nyckel = "hjalp.lagre_gangart", tgb = "Ctrl",  pad = "L1", pek = "touch.sakta" },
	--[[ Blicken finns bara på pekytan: tangentbord och handkontroll har
	     ingen fri blick i den här kameran, och `bara` håller raden borta
	     därifrån hellre än att visa en handling utan reglage. ]]
	{ nyckel = "hjalp.blick", bara = "touch", pek = "touch.blickytan" },
	{ nyckel = "hjalp.tygel",        tgb = "Q",      pad = "R2", pek = "touch.tygel" },
	{ nyckel = "hjalp.halvhalt",     tgb = "F",      pad = "B",  pek = "touch.halvhalt" },
	{ nyckel = "hjalp.djupare_sits", tgb = "Z / C",  pad = "L2", pek = "touch.djup_sits" },
	{ nyckel = "hjalp.hoppa",        tgb = "Space",  pad = "A",  pek = "touch.hoppa" },
	--[[ #161: hjälpen kan öppnas igen på varje yta, och står därför i sin
	     egen hjälp. En rad som säger "H" till en spelare utan tangentbord
	     hade varit precis det problemet raden beskriver. ]]
	{ nyckel = "hjalp.denna_hjalp",  tgb = "H",
	  pad = padNamn(KontrollHjalp.GAMEPADKNAPP),        pek = "?" },
}

--[[ Radens text och reglage i spelarens språk. `pek`/`padNyckel` är
     nycklar när de pekar på något spelet SÄGER, och råa tecken när de är
     tangentnamn ("W / S", "R1") — de översätts inte, de är knappar. ]]
local function radText(r): string
	return Sprak.t(r.nyckel)
end
local function reglageText(varde: string?): string
	if varde == nil then return "" end
	if Sprak.finns(varde) then return Sprak.t(varde) end
	return varde
end

--[[ Vilken sorts inmatning ska hjälpen tala om? Publik för att provet ska
     kunna läsa samma beslut som panelen. ]]
--[[ Raden för ett reglage, som panelen faktiskt skriver ut den. Publik
     för att provet ska kunna mäta LEDTEXTEN och inte bara bindningen —
     blockerare 2 var trasig i just texten. ]]
--[[ Slår upp en rad. Tar NYCKELN ("hjalp.sitt_upp_av") eller texten i
	något av språken — det senare för att ett prov som frågar efter
	"Sitt upp / sitt av" ska fortsätta mäta samma rad efter att texten
	flyttat till språkkanonen. Identiteten är nyckeln; texten är en
	bekvämlighet. ]]
function KontrollHjalp._rad(vad: string): { [string]: string }?
	for _, r in RADER do
		if r.nyckel == vad
			or Sprak.iSprak("sv", r.nyckel) == vad
			or Sprak.iSprak("en", r.nyckel) == vad then
			return r
		end
	end
	return nil
end

function KontrollHjalp.inmatning(): string
	if UserInputService.KeyboardEnabled then return "tangentbord" end
	if UserInputService.GamepadEnabled then return "gamepad" end
	if UserInputService.TouchEnabled then return "touch" end
	--[[ Ingen känd inmatning: beskriv handlingarna utan reglage hellre än
	     att gissa en tangent hon kanske inte har. ]]
	return "okand"
end

--[[ Raderna som text, för panelen och för provet. Ren avläsning. ]]
function KontrollHjalp.rader(): { { vad: string, reglage: string } }
	local sort = KontrollHjalp.inmatning()
	local ut = {}
	for _, r in RADER do
		--[[ En rad med `bara` hör hemma på EN inmatning. ]]
		if (r :: any).bara == nil or (r :: any).bara == sort then
			local reglage =
				if sort == "tangentbord" then r.tgb
				elseif sort == "gamepad" then (r.pad or reglageText(r.padNyckel))
				elseif sort == "touch" then reglageText(r.pek)
				else ""
			table.insert(ut, { vad = radText(r), reglage = reglage })
		end
	end
	return ut
end

local function bygg()
	if gui then return end
	local g = Instance.new("ScreenGui")
	g.Name = "UBRFKontroller"
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = true
	g.DisplayOrder = 15
	g.Enabled = false
	g.Parent = player:WaitForChild("PlayerGui")
	gui = g

	local p = Instance.new("Frame")
	p.Name = "Panel"
	--[[ Smal och vid kanten: hjälpen ska kunna stå uppe medan man rider,
	     inte lägga sig över vägen framåt. ]]
	p.AnchorPoint = Vector2.new(0, 0.5)
	p.Position = UDim2.new(0, 12, 0.5, 0)
	p.Size = UDim2.new(0, 250, 0, 44 * (#RADER + 2))
	p.BackgroundColor3 = FARG_MORK
	p.BackgroundTransparency = 0.12
	p.Parent = g
	panel = p
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = p

	local rubrik = Instance.new("TextLabel")
	rubrik.Name = "Rubrik"
	rubrik.Size = UDim2.new(1, -20, 0, 26)
	rubrik.Position = UDim2.fromOffset(10, 8)
	rubrik.BackgroundTransparency = 1
	rubrik.Text = Sprak.t("hjalp.rubrik")
	rubrik.TextColor3 = FARG_GULD
	rubrik.TextXAlignment = Enum.TextXAlignment.Left
	rubrik.Font = Enum.Font.GothamBold
	rubrik.TextSize = 15
	rubrik.Parent = p

	for i = 1, #RADER do
		local l = Instance.new("TextLabel")
		l.Name = "Rad" .. i
		l.Size = UDim2.new(1, -20, 0, 20)
		l.Position = UDim2.fromOffset(10, 34 + (i - 1) * 21)
		l.BackgroundTransparency = 1
		l.TextColor3 = FARG_TEXT
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.Font = Enum.Font.Gotham
		l.TextSize = 12
		l.Text = ""
		l.Parent = p
		table.insert(rader, l)
	end

	--[[ En stängknapp, inte bara en tangent: på en ren pekenhet finns
	     ingen H att trycka på, och en panel som inte går att stänga är
	     värre än ingen panel. 44 px, samma regel som ridanalysen. ]]
	local kn = Instance.new("TextButton")
	kn.Name = "StangHjalp"
	kn.AutoButtonColor = true
	kn.Size = UDim2.new(1, -20, 0, 44)
	kn.Position = UDim2.new(0, 10, 1, -52)
	kn.BackgroundColor3 = FARG_GULD
	kn.TextColor3 = Color3.fromRGB(23, 20, 10)
	kn.Font = Enum.Font.GothamBold
	kn.TextSize = 12
	kn.Text = Sprak.t("hjalp.stang")
	kn.ZIndex = 6
	kn.Parent = p
	local kc = Instance.new("UICorner"); kc.CornerRadius = UDim.new(1, 0); kc.Parent = kn
	kn.Activated:Connect(function() KontrollHjalp.dolj() end)
end

local function fyll()
	local lista = KontrollHjalp.rader()
	for i, l in ipairs(rader) do
		local r = lista[i]
		if r then
			l.Text = if r.reglage ~= "" then `{r.vad}  ·  {r.reglage}` else r.vad
			l.Visible = true
		else
			l.Text = ""
			l.Visible = false
		end
	end
	local kn = panel and panel:FindFirstChild("StangHjalp")
	if kn then
		--[[ Ledtexten bara där tangenten finns. ]]
		(kn :: TextButton).Text =
			if UserInputService.KeyboardEnabled then Sprak.t("hjalp.stang_tangent", "H") else Sprak.t("hjalp.stang")
	end
end

--[[ ── ÖPPNINGSKNAPPEN ──────────────────────────────────────────────

     En egen ScreenGui som lever hela sessionen. `ResetOnSpawn = false` gör
     att den överlever respawn; `IgnoreGuiInset = false` gör att den lägger
     sig UNDER Roblox egen topbar i stället för bakom den.

     48 px, alltså över golvet på 44 som `docs/KONTROLLMATRIS.md` regel 5
     sätter och som resten av pek-UI:t redan följer. Träffytan är knappens
     egen storlek — ingen genomskinlig marginal som ser mindre ut än den
     är, och ingen etikett som sticker utanför sin knapp.

     Den ritas för TOUCH och GAMEPAD men inte för en ren tangentbords-
     klient: där finns `H`, och en musanvändare får ändå knappen om hon
     saknar tangentbord. Samma regel som resten av modulen — reglagen
     följer inmatningen, inte plattformen. ]]
local KNAPPSTORLEK = 48

local function byggOppna()
	if oppnaGui then return end
	if UserInputService.KeyboardEnabled and not UserInputService.TouchEnabled then
		--[[ Ren tangentbordsklient: `H` finns och knappen skulle bara ta
		     plats. Beslutet läses om vid varje `KontrollHjalp.start`, så en
		     iPad som kopplar bort sitt tangentbord får knappen. ]]
		return
	end
	local g = Instance.new("ScreenGui")
	g.Name = "UBRFHjalpknapp"
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = false
	--[[ Under ridanalysen (20) men över kontrollpanelen (15): panelen ska
	     kunna ligga över knappen utan att knappen försvinner bakom den. ]]
	g.DisplayOrder = 16
	g.Parent = player:WaitForChild("PlayerGui")
	oppnaGui = g

	local b = Instance.new("TextButton")
	b.Name = "Hjalp"
	b.AnchorPoint = Vector2.new(1, 0)
	b.Position = UDim2.new(1, -12, 0, 12)
	b.Size = UDim2.fromOffset(KNAPPSTORLEK, KNAPPSTORLEK)
	b.BackgroundColor3 = FARG_MORK
	b.BackgroundTransparency = 0.12
	b.TextColor3 = FARG_GULD
	b.Font = Enum.Font.GothamBold
	b.TextSize = 22
	b.Text = "?"
	b.AutoButtonColor = true
	b.BorderSizePixel = 0
	b.Parent = g
	local horn = Instance.new("UICorner")
	horn.CornerRadius = UDim.new(1, 0)
	horn.Parent = b
	b.Activated:Connect(function() KontrollHjalp.vaxla() end)
	oppnaKnapp = b
end

--[[ Knappen göms medan panelen står uppe: panelen har sin egen `Stäng`, och
     två reglage för samma sak på skärmen samtidigt är en fråga, inte en
     hjälp. Den kommer tillbaka i samma ögonblick panelen stängs. ]]
local function speglaOppna()
	local b = oppnaKnapp
	if b then b.Visible = not KontrollHjalp.synlig() end
end

function KontrollHjalp.visa()
	bygg()
	fyll()
	local g = gui
	if g then g.Enabled = true end
	speglaOppna()
end

function KontrollHjalp.dolj()
	local g = gui
	if g then g.Enabled = false end
	speglaOppna()
end

--[[ Startas av `init.client.luau`. Bygger bara öppningsknappen — panelen
     byggs först när den behövs, som förut. ]]
function KontrollHjalp.start()
	byggOppna()
	speglaOppna()
end

--[[ Provkrok: knappen som faktiskt ritats, eller nil när inmatningen inte
     ska ha någon. Provet läser den i stället för att bygga en egen. ]]
function KontrollHjalp._oppnaKnapp(): TextButton?
	return oppnaKnapp
end

function KontrollHjalp.synlig(): boolean
	local g = gui
	return g ~= nil and g.Enabled == true
end

function KontrollHjalp.vaxla(): boolean
	if KontrollHjalp.synlig() then KontrollHjalp.dolj() else KontrollHjalp.visa() end
	return KontrollHjalp.synlig()
end

--[[ FÖRSTA UPPSITTNINGEN. Hjälpen visas en gång av sig själv — då är
     frågan "vad gör jag nu?" som mest aktuell — och sedan bara när
     spelaren ber om den. Att visa den vid varje uppsittning hade blivit
     en ruta att stänga bort, inte en hjälp. ]]
function KontrollHjalp.vidUppsittning()
	if visadEnGang then return end
	visadEnGang = true
	KontrollHjalp.visa()
end

return KontrollHjalp
