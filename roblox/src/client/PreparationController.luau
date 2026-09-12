--!strict
--[[ SKÖTSELNS HUD — förberedelsen, fyndet och eftervården.

	Visar serverns sanning och inget annat. Den här filen räknar aldrig ut
	om ett steg är klart — den ritar `PreparationSync` och `PassSync`.
	Skälet är krav 10: en sen init eller en refresh får inte skriva över
	nyare serverfeedback, och det enda sättet att garantera det är att
	klienten inte har någon egen uppfattning som kan vara nyare.

	Layouten är byggd för 320 px bredd först. Det är inte en artig gest mot
	mobilen — Tobias familj spelar på iPad, och en HUD som kräver 900 px är
	inte spelbar för dem.

	── TVÅ YTOR, INTE EN PANEL (PO-order 09:36) ─────────────────────

	Allt det här ritas på två ytor med olika livslängd: SPÅRAREN uppe till
	höger, som alltid finns och normalt är hopfälld, och INTERAKTIONS-
	PANELEN, som bara finns medan spelaren faktiskt står vid hästen och har
	något att välja på. Se noten vid `SIKTRUTA` längre ned för skälet och
	för kontraktet i tal.

	── TVÅ LISTOR, INTE TVÅ HUD:AR (#161) ───────────────────────────

	Panelen visar numera fyra olika saker, men aldrig mer än en i taget:

	  faser + moment   den vanliga skötseln,
	  fyndets svar     visitationen hittade något,
	  välfärdsstoppet  arbetet är avbrutet, ridläraren tar över,
	  eftervården      passets andra halva, efter avsittning.

	Alla fyra ritas med SAMMA radkod. Ett moment och en fas har samma form
	i vyn (`id`, `namn`, `klar`), och eftervårdens moment har det också —
	det är därför `Pass.vy` medvetet härmar `Preparation.vy`. En egen
	eftervårds-HUD hade varit en femte plats där samma bock ritas på ett
	femte sätt.

	── TRÄFFYTAN ────────────────────────────────────────────────────

	Fasraderna är 26 px höga och INTE tryckbara längre: en fas kvitteras
	inte med ett tryck sedan #161, den blir klar av sina moment. De är
	alltså en LÄGESVISNING, och behöver därför inte 44 px.

	Momentknapparna är det man faktiskt trycker på, och de är 44 px —
	`docs/KONTROLLMATRIS.md` regel 5, samma golv som ridanalysen och
	pekreglagen redan följer.
]]

local Players = game:GetService("Players")

local Core = require(game:GetService("ReplicatedStorage").HorseCore)
local Preparation = require(game:GetService("ReplicatedStorage").HorseCore.Preparation)
--[[ #162: spelarens text kommer ur språkkanonen, aldrig ur den här filen.
     Klienten översätter — här är spelarens locale känd. ]]
local Sprak = require(game:GetService("ReplicatedStorage").HorseCore.Sprak)
local Net = Core.Networking

local PreparationController = {}

local player = Players.LocalPlayer

--[[ ══ KONTEXTEN — HUD:EN FÅR INTE LOVA VAD SPELAREN INTE KAN GÖRA ══════

	P0-3 ur Tobias andra Studio-test: "Greet her calmly" låg kvar medan han
	stod någon annanstans i anläggningen. Servern nekade samtidigt samma
	handling med `spel.for_langt` — alltså sa gränssnittet en sak och
	spelet en annan, och det är spelaren som får skulden för det.

	Gränsen är SERVERNS: `Core.Config.STEG_RACKVIDD`, samma tal
	`GameplayService.avstandOk` mäter mot. Klienten beslutar ingenting; den
	visar bara samma sanning i förväg. Skulle talen glida isär vore HUD:en
	lögnaktig igen, och därför står talet på ETT ställe.

	Är hästen utom räckhåll pekar rubriken tillbaka till henne och
	momentknapparna slutar vara knappar. Instruktionen försvinner inte —
	spelaren ska se vad som står på tur — men den utger sig inte längre för
	att vara något att trycka på här. ]]
local CollectionService = game:GetService("CollectionService")
--[[ Läses vid ANROP, inte vid inladdning: talet ska gå att trimma i
	Studio utan att klienten startas om, och en kopia tagen en gång är
	precis den sortens andra sanning som lät HUD:en och servern glida
	isär från början. ]]
local function rackvidd(): number
	return Core.Config.STEG_RACKVIDD
end
local utomRackhall = false

local function hastModell(hastId: any): Model?
	if type(hastId) ~= "string" then return nil end
	for _, m in ipairs(CollectionService:GetTagged("Horse")) do
		if m:GetAttribute("HorseId") == hastId then return m end
	end
	return nil
end

--[[ Avståndet till den tilldelade hästen, eller nil när frågan inte går
	att ställa (ingen kropp, ingen häst i världen än). Nil betyder INTE
	"för långt": de lägena har sina egna rubriker, och att skriva "gå
	tillbaka" till någon som inte fått en häst vore en ny lögn. ]]
local function avstandTillHast(vy: any): number?
	local tecken = player.Character
	local rot = tecken and tecken:FindFirstChild("HumanoidRootPart")
	local modell = hastModell(vy and vy.hastId)
	local pivot = modell and ((modell :: any).PrimaryPart
		or modell:FindFirstChild("HumanoidRootPart")
		or modell:FindFirstChild("BodyCollider"))
	if not rot or not pivot then return nil end
	return ((rot :: any).Position - (pivot :: any).Position).Magnitude
end


local Workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")

--[[ ══ TVÅ YTOR MED OLIKA LIVSLÄNGD (PO-order 09:36) ═══════════════════

	Panelen låg mitt på skärmen nedtill, 92 % bred och 300 px hög, och den
	låg där hela tiden. Den skymde hästen, avataren och sikten framåt, och
	den visade hela steglistan OCH alla stora val även när spelaren inte
	höll på med någonting alls.

	Samma innehåll ritas nu på två ytor som lever olika länge:

	  SPÅRAREN        uppe till höger, alltid, liten. HOPFÄLLD visar den
	                  målet och `3/5`; UTFÄLLD målet, stegen och en kort
	                  hjälptext. Spelaren fäller själv, och valet står kvar.
	  INTERAKTIONEN   de stora valen. Finns BARA medan spelaren står vid
	                  hästen och faktiskt har något att välja på — och
	                  ligger i NEDRE VÄNSTRA hörnet, hopfälld som standard.
	                  Se noten vid `INTERAKTION_BREDD`.

	SIKTRUTAN är kontraktet i tal: mitten av skärmen, där avataren står och
	dit man tittar. VARKEN den hopfällda spåraren eller interaktionspanelen
	får gå in i den i onödan. Den UTFÄLLDA spåraren får — den är spelarens
	eget beslut och varar bara medan hon läser.

	Den äldre formuleringen här sa att interaktionspanelen "får vara stor
	och central, för då ÄR den spelet". Tobias order 2026-09-12 ersätter
	den: panelen ska ligga i ett hörn och aldrig i onödan skymma häst,
	ryttare, dörrar, prompter eller vägen framåt. Grinden mäter det på de
	skärmar familjen faktiskt spelar på; talen här är enda källan. ]]
PreparationController.SIKTRUTA = { x0 = 0.30, x1 = 0.70, y0 = 0.25, y1 = 0.85 }

local MARGINAL = 12
--[[ Bandet allra överst till höger är UPPTAGET: `KontrollHjalp` ritar sin
	runda `?`-knapp där på pek-klienter, 48 px med 12 px marginal. Spåraren
	börjar under den.

	Talet står här och inte som ett `require` — bankerna som kör den här
	filen laddar inte alltid `KontrollHjalp`, och ett require som bara
	finns ibland är en krasch som väntar. `klient.spec` MÄTER i stället att
	de två ytorna aldrig går i varandra; glider talen isär blir det rött
	där, inte hos spelaren. ]]
local HJALPKNAPP = 48
local SPARARE_ANDEL = 0.30
local SPARARE_MIN = 132
local SPARARE_MAX = 300
--[[ Utfälld får spåraren ta högst så här stor del av skärmhöjden. Det är
	steglistan som ger vika när det inte räcker: hellre en lista som rullar
	än en panel som växer ned över spelet. ]]
local SPARARE_TAK = 0.45
local INNER = 8
local STEGRAD = 22
--[[ ══ INTERAKTIONSPANELEN ═══════════════════════════════════════════

	Panelen var 420 x 300 px mitt på skärmens nederkant, oavsett om den
	bar ett ord eller åtta val. En rad text fick en panel lika stor som
	hela iordningställandet, och båda låg rakt över hästen.

	Tobias order 2026-09-12 ersätter den äldre "den får vara stor och
	central": panelen ska ligga i ett HÖRN, vara kompakt som standard, gå
	att fälla ut och in, och aldrig i onödan skymma häst, ryttare, dörrar,
	prompter eller vägen framåt.

	Den ligger nu nere till VÄNSTER — spåraren äger uppe till höger,
	avataren mitten — och höjden RÄKNAS UR INNEHÅLLET: instruktionens
	verkliga radantal plus de val som faktiskt visas. Det finns alltså
	ingen tom panel kvar att fylla, för det finns ingen fast höjd. ]]
local INTERAKTION_BREDD = 316
local INTERAKTION_RAD = 4            -- luft mellan valen, som UIListLayout
local INTERAKTION_TEXTRAD = 17       -- en rad instruktionstext
local INTERAKTION_TAK = 0.52         -- högst så här stor del av skärmhöjden
local HJALP_HOJD = 34
local GAP = 6

local gui: ScreenGui? = nil
--[[ SPÅRAREN. ]]
local sparare: Frame? = nil
local huvudKnapp: TextButton? = nil
local rubrik: TextLabel? = nil
local framsteg: TextLabel? = nil
local pil: TextLabel? = nil
local stegLista: ScrollingFrame? = nil
local hjalp: TextLabel? = nil
--[[ INTERAKTIONEN. ]]
local interaktion: Frame? = nil
local instruktion: TextLabel? = nil
local interaktionVaxla: TextButton? = nil
local momentBehallare: Frame? = nil

local radBehallare: Frame? = nil
local rader: { [string]: { ram: Frame, bock: TextLabel, namn: TextLabel } } = {}
local momentRader: { [string]: TextButton } = {}
--[[ En aktiv `Activated`-anslutning per momentknapp. Se `momentRad`. ]]
local momentKoppling: { [string]: RBXScriptConnection } = {}
local senasteVy: any = nil
local senastePass: any = nil
--[[ Revisionen på det som faktiskt ritats. `nil` = ingenting ritat än.
	Förberedelsen och passet har VAR SIN, trots att servern räknar dem ur
	samma serie: de kommer som två olika event och en passvy får inte
	kastas för att en förberedelsevy råkade ha ett högre nummer. ]]
local senasteRev: number? = nil
local senastePassRev: number? = nil
local rita

--[[ Det klienten senast bad om, och därmed väntar svar på. Används bara för
	att gråa ut knappen medan svaret är på väg — inte för att gissa utfallet. ]]
local vantarPa: string? = nil

--[[ HOPFÄLLD ÄR STANDARD. Läget är spelarens och överlever varje
	omritning: en HUD som fäller ihop sig själv mitt i ett moment tar
	tillbaka ett beslut spelaren just fattade. ]]
local utvidgad = false
--[[ Interaktionspanelens eget läge, skilt från spårarens. Standard är
	HOPFÄLLD, som ordern säger. Hopfälld visar instruktionen och det val
	som står på tur — det ÄR målet just nu — plus växlingen. ]]
local interaktionUt = false
--[[ Vilka moment den senaste vyn faktiskt innehåller. Skilt från
	knapparnas `Visible`, som dessutom bär hopfällningen: två betydelser i
	samma flagga hade gjort räkningen till en gissning. ]]
local anvandaNu: { [string]: boolean } = {}
--[[ Det läge som senast ritades. Enda syftet är att fälla UT spåraren EN
	gång när spelet går in i ett läge som inte har något att trycka på men
	allt att förklara — välfärdsstoppet, passet sparat, väntar på hästen.
	Där är texten hela innehållet, och en hopfälld panel hade dolt det enda
	som fanns att säga. Sedan är läget spelarens igen. ]]
local senasteLage: string? = nil

local FARG_KLAR = Color3.fromRGB(127, 180, 137)
local FARG_TUR = Color3.fromRGB(214, 174, 60)
local FARG_VILAR = Color3.fromRGB(120, 124, 128)
local FARG_FEL = Color3.fromRGB(208, 101, 90)
local FARG_TEXT = Color3.fromRGB(238, 240, 242)

--[[ Golvet för en träffyta. Står som en namngiven konstant för att provet
	ska kunna läsa samma tal som knappen ritas med. ]]
PreparationController.TRAFFYTA = 44

--[[ Topbarens höjd. Spårarens ScreenGui ignorerar inseten (`IgnoreGuiInset`)
	och räknar alltså i hela viewportens koordinater, medan `KontrollHjalp`
	INTE gör det — dess `?`-knapp hamnar därför 36 px längre ned på skärmen
	än dess egna tal säger. Räknades inseten inte in här skulle knappen
	ligga över spårarens rubrik på varje riktig klient, och en grind med
	inset noll hade aldrig sett det.

	Egenskapen finns inte överallt: ett explicit typtest, inget pcall. ]]
local function guiInset(): number
	local f = (GuiService :: any).GetGuiInset
	if type(f) ~= "function" then return 0 end
	local topp = f(GuiService)
	if topp and type(topp.Y) == "number" then return topp.Y end
	return 0
end

--[[ Överkanten spåraren får börja på: under topbaren, under `?`-knappen
	och med luft emellan. `klient.spec` mäter att det stämmer mot den knapp
	som faktiskt byggdes. ]]
local function toppband(): number
	return guiInset() + MARGINAL + HJALPKNAPP + GAP
end

--[[ Viewporten i pixlar. Saknas kameran — vilket den gör i vissa
	uppstartslägen — antas ett skrivbord hellre än noll: en nolla hade gett
	en panel utan bredd och en siktruta utan innehåll. ]]
local function viewport(): (number, number)
	local cam = Workspace.CurrentCamera
	local vp = cam and (cam :: any).ViewportSize
	if vp and type(vp.X) == "number" and type(vp.Y) == "number"
		and vp.X > 0 and vp.Y > 0 then
		return vp.X, vp.Y
	end
	return 1280, 720
end

--[[ Ren räkning: spårarens ruta i pixlar, utan att bygga en enda Instance.
	Provet läser SAMMA funktion som `tillampaLayout` sedan ritar med — två
	räkningar hade kunnat glida isär, och då hade grinden mätt sin egen
	kopia av layouten i stället för HUD:ens. ]]
local function spararLayout(antalSteg: number, ut: boolean): { [string]: number }
	local B, H = viewport()
	local bredd = math.clamp(math.floor(B * SPARARE_ANDEL), SPARARE_MIN, SPARARE_MAX)
	bredd = math.min(bredd, math.max(80, math.floor(B - 2 * MARGINAL)))
	local x = B - MARGINAL - bredd
	local y = toppband()
	local kompakt = 2 * INNER + PreparationController.TRAFFYTA
	if not ut then
		return { x = x, y = y, bredd = bredd, hojd = kompakt, stegHojd = 0,
			kompakt = kompakt, vpBredd = B, vpHojd = H }
	end
	local tak = math.floor(H * SPARARE_TAK) - y - MARGINAL
	local fast = kompakt + GAP + GAP + HJALP_HOJD
	local stegHojd = 0
	if antalSteg > 0 then
		--[[ Minst en rad syns alltid. Ryms inte fler rullar listan; att
			klippa listan utan att gå att rulla hade gjort de sista stegen
			osynliga, och det var precis felet den gamla panelen hade. ]]
		stegHojd = math.max(STEGRAD, math.min(antalSteg * STEGRAD, tak - fast))
	end
	local hojd = fast + stegHojd - (if antalSteg > 0 then 0 else GAP)
	return { x = x, y = y, bredd = bredd, hojd = hojd, stegHojd = stegHojd,
		kompakt = kompakt, vpBredd = B, vpHojd = H }
end

--[[ Interaktionspanelens ruta. Den får vara central och stor — men bara
	medan den finns, och den finns bara under interaktionen. ]]
--[[ Hur många rader instruktionstexten tar vid panelens bredd. Ren
	räkning, för att höjden ska följa innehållet utan att någon läser av
	en `TextBounds` som bara finns när Roblox redan ritat. ]]
local function textrader(text: string, bredd: number): number
	if text == "" then return 0 end
	--[[ Gotham 14 px ger ungefär 7,4 px per tecken i snitt. Talet är
		avsiktligt lågt satt: hellre en rad för mycket än en text som
		klipps. ]]
	local perRad = math.max(10, math.floor((bredd - 2 * INNER) / 7.4))
	local tecken = utf8.len(text) or #text
	return math.max(1, math.ceil(tecken / perRad))
end

local function interaktionsLayout(antalVal: number, rader: number,
	ut: boolean): { [string]: number }
	local B, H = viewport()
	local bredd = math.min(INTERAKTION_BREDD, math.max(120, B - 2 * MARGINAL))
	--[[ HÖJDEN ÄR INNEHÅLLET. Hopfälld visas det val som står på tur; det
		är objektivet, och det är vad ordern ber om. ]]
	local visade = if ut then antalVal else math.min(antalVal, 1)
	local textHojd = rader * INTERAKTION_TEXTRAD
	local listHojd = 0
	if visade > 0 then
		listHojd = visade * PreparationController.TRAFFYTA
			+ (visade - 1) * INTERAKTION_RAD
	end
	--[[ Växlingen ritas bara när det FINNS något att fälla ut. Ett ensamt
		val ska inte bära en knapp som inte gör något. ]]
	local vaxling = if antalVal > 1 then GAP + STEGRAD else 0
	local hojd = 2 * INNER + textHojd
		+ (if listHojd > 0 then GAP + listHojd else 0) + vaxling
	--[[ Taket: hellre en lista som rullar än en panel som växer upp över
		spelet. Det är listan som ger vika, aldrig texten. ]]
	local tak = math.floor(H * INTERAKTION_TAK)
	if hojd > tak and listHojd > 0 then
		listHojd = math.max(PreparationController.TRAFFYTA, listHojd - (hojd - tak))
		hojd = 2 * INNER + textHojd + GAP + listHojd + vaxling
	end
	return { bredd = bredd, hojd = hojd, vpBredd = B, vpHojd = H,
		--[[ NERE TILL VÄNSTER. ]]
		x = MARGINAL, y = H - MARGINAL - hojd,
		textHojd = textHojd, listHojd = listHojd, visade = visade,
		vaxling = vaxling }
end

--[[ Layouten som tal, för prov och felsökning. Ren avläsning — den bygger
	ingenting och ändrar ingenting. ]]
function PreparationController.layout(): { [string]: any }
	local antal = 0
	for _, r in pairs(rader) do
		if r.ram.Visible then antal += 1 end
	end
	local S = spararLayout(antal, utvidgad)
	local K = spararLayout(antal, false)
	local synligaVal = 0
	for id in pairs(anvandaNu) do
		if momentRader[id] then synligaVal += 1 end
	end
	local ledtext = if instruktion then instruktion.Text else ""
	local I = interaktionsLayout(synligaVal,
		textrader(ledtext, INTERAKTION_BREDD), interaktionUt)
	return {
		sparare = { x0 = S.x, y0 = S.y, x1 = S.x + S.bredd, y1 = S.y + S.hojd },
		kompakt = { x0 = K.x, y0 = K.y, x1 = K.x + K.bredd, y1 = K.y + K.kompakt },
		interaktion = { x0 = I.x, y0 = I.y, x1 = I.x + I.bredd, y1 = I.y + I.hojd },
		sikt = {
			x0 = S.vpBredd * PreparationController.SIKTRUTA.x0,
			x1 = S.vpBredd * PreparationController.SIKTRUTA.x1,
			y0 = S.vpHojd * PreparationController.SIKTRUTA.y0,
			y1 = S.vpHojd * PreparationController.SIKTRUTA.y1,
		},
		vpBredd = S.vpBredd, vpHojd = S.vpHojd,
		utvidgad = utvidgad, stegHojd = S.stegHojd, antalSteg = antal,
		interaktionUt = interaktionUt, interaktionVal = synligaVal,
		interaktionVisade = I.visade, interaktionText = I.textHojd,
		interaktionLista = I.listHojd,
	}
end

--[[ Ritar om ytorna efter den skärm som faktiskt finns. Publik för att
	provet ska kunna kalla den efter att ha ändrat viewporten — samma väg
	en skärmrotation tar. ]]
function PreparationController.tillampaLayout()
	local s = sparare
	if not s then return end
	local L = PreparationController.layout()
	s.Position = UDim2.fromOffset(L.sparare.x0, L.sparare.y0)
	s.Size = UDim2.fromOffset(L.sparare.x1 - L.sparare.x0,
		L.sparare.y1 - L.sparare.y0)
	if stegLista then
		stegLista.Size = UDim2.new(1, 0, 0, L.stegHojd)
		stegLista.Visible = utvidgad and L.stegHojd > 0
	end
	if hjalp then
		hjalp.Visible = utvidgad
	end
	if pil then
		pil.Text = if utvidgad then "▲" else "▼"
	end
	local p = interaktion
	if p then
		p.Position = UDim2.fromOffset(L.interaktion.x0, L.interaktion.y0)
		p.Size = UDim2.fromOffset(L.interaktion.x1 - L.interaktion.x0,
			L.interaktion.y1 - L.interaktion.y0)
	end
	if instruktion then
		instruktion.Size = UDim2.new(1, 0, 0, L.interaktionText)
	end
	if momentBehallare then
		momentBehallare.Position = UDim2.new(0, 0, 0,
			L.interaktionText + (if L.interaktionLista > 0 then GAP else 0))
		momentBehallare.Size = UDim2.new(1, 0, 0, L.interaktionLista)
	end
	--[[ HOPFÄLLD VISAR DET SOM STÅR PÅ TUR. Raderna sorteras på
		`LayoutOrder`, och den lägsta är nästa moment. ]]
	local lagsta, forst = math.huge, nil
	for id in pairs(anvandaNu) do
		local k = momentRader[id]
		if k and k.LayoutOrder < lagsta then lagsta, forst = k.LayoutOrder, k end
	end
	for id, knapp in pairs(momentRader) do
		knapp.Visible = anvandaNu[id] == true
			and (interaktionUt or knapp == forst)
	end
	if interaktionVaxla then
		interaktionVaxla.Visible = L.interaktionVal > 1
		--[[ Texten går genom katalogen, inte som en literal. Den stod först
			som svenska rakt i modulen och blev då svensk också i ett
			engelskt gränssnitt — precis det språkkanonen finns för.

			Pilen är U+25BC/25B2 och inte U+25BE/25B4: de senare saknas i
			Gotham och ritades som en tom ruta. Samma sak gällde spårarens
			egen pil, och den är bytt på samma sätt. ]]
		interaktionVaxla.Text = if interaktionUt
			then Sprak.t("hud.visa_mindre") .. "  \u{25B2}"
			else Sprak.t("hud.visa_alla", L.interaktionVal) .. "  \u{25BC}"
		interaktionVaxla.Position = UDim2.new(0, 0, 1, -STEGRAD)
		interaktionVaxla.Size = UDim2.new(1, 0, 0, STEGRAD)
	end
end

--[[ Fäller ut eller ihop spåraren. Knappen i huvudet gör detta och inget
	annat, och provet går samma väg. ]]
function PreparationController.vaxla()
	utvidgad = not utvidgad
	PreparationController.tillampaLayout()
end

function PreparationController._utvidgad(): boolean
	return utvidgad
end

--[[ Interaktionspanelens läge, och en väg att växla det utan att trycka
	på knappen. Provet och granskningen behöver båda: `Activated` går inte
	att fyra utifrån i en riktig klient, och en bild av det utfällda läget
	ska kunna tas utan att någon sitter med musen. Växlingen går genom
	SAMMA väg som knappen — det är knappens lyssnare som anropar den. ]]
function PreparationController._vaxlaInteraktion(): boolean
	interaktionUt = not interaktionUt
	PreparationController.tillampaLayout()
	return interaktionUt
end

--[[ De byggda ytorna själva, för grinden. Provet läser RIKTIGA instanser
	— storlek, synlighet, knappen det trycker på — och inte en rapport
	modulen skriver om sig själv. En sådan rapport kan vara sann medan
	skärmen visar något annat, och det är exakt den sortens fel den här
	grinden finns för. ]]
function PreparationController._ytor(): { [string]: any }
	return { sparare = sparare, vaxla = huvudKnapp, steg = stegLista,
		hjalp = hjalp, interaktion = interaktion, rubrik = rubrik,
		framsteg = framsteg, instruktion = instruktion,
		interaktionVaxla = interaktionVaxla, moment = momentBehallare }
end

local function bygg()
	if gui then return end
	local g = Instance.new("ScreenGui")
	g.Name = "UBRFForberedelse"
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = true
	--[[ ══ ÖVER ROBLOX EGNA PEKREGLAGE ═════════════════════════════════

	     `DisplayOrder` låg på 0, och det gör `TouchGui` också. Vid lika
	     ordning vinner Roblox, och på en pekskärm ligger den dynamiska
	     spaken som en osynlig träffyta över hela nedre vänstra hörnet —
	     alltså precis där skötselpanelen står.

	     Mätt på iPad Air i landskap, samma synliga panel, bara ordningen
	     ändrad:
	         DisplayOrder 0  → översta träffen på momentknappen var
	                           `ThumbstickStart` — knappen gick inte att
	                           trycka på
	         DisplayOrder 10 → översta träffen var `halsa1`, alltså
	                           knappen själv
	     Utan det här kan en iPad-spelare inte hälsa, rykta eller sadla,
	     och kommer därmed aldrig ens fram till uppsittningen.

	     10 ligger över `TouchGui` (0) och över ridningens egen
	     `HorseTouch` (8), men under hjälpknappen (16). ]]
	g.DisplayOrder = 10
	g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	g.Parent = player:WaitForChild("PlayerGui")

	-- ── SPÅRAREN ────────────────────────────────────────────────────
	local sp = Instance.new("Frame")
	sp.Name = "Sparare"
	sp.BackgroundColor3 = Color3.fromRGB(24, 26, 28)
	--[[ Lätt. Den ligger över spelet hela tiden och ska läsas i förbifarten,
		inte konkurrera med det. ]]
	sp.BackgroundTransparency = 0.35
	sp.BorderSizePixel = 0
	sp.Parent = g
	sparare = sp

	local sphorn = Instance.new("UICorner")
	sphorn.CornerRadius = UDim.new(0, 10)
	sphorn.Parent = sp

	local sppad = Instance.new("UIPadding")
	sppad.PaddingTop = UDim.new(0, INNER)
	sppad.PaddingBottom = UDim.new(0, INNER)
	sppad.PaddingLeft = UDim.new(0, INNER)
	sppad.PaddingRight = UDim.new(0, INNER)
	sppad.Parent = sp

	--[[ HELA HUVUDRADEN är knappen. Ett fingertryck var som helst på
		rubriken fäller ut eller ihop, och träffytan blir 44 px utan att
		en separat liten chevron ska behöva träffas. ]]
	local hk = Instance.new("TextButton")
	hk.Name = "Vaxla"
	hk.Size = UDim2.new(1, 0, 0, PreparationController.TRAFFYTA)
	hk.BackgroundTransparency = 1
	hk.AutoButtonColor = false
	hk.Text = ""
	hk.Parent = sp
	huvudKnapp = hk

	local r = Instance.new("TextLabel")
	r.Name = "Rubrik"
	r.Size = UDim2.new(1, -64, 1, 0)
	r.BackgroundTransparency = 1
	r.Font = Enum.Font.GothamBold
	r.TextSize = 14
	r.TextXAlignment = Enum.TextXAlignment.Left
	r.TextTruncate = Enum.TextTruncate.AtEnd
	r.TextColor3 = FARG_TEXT
	r.Text = Sprak.t("hud.gor_i_ordning")
	r.Parent = hk
	rubrik = r

	local fs = Instance.new("TextLabel")
	fs.Name = "Framsteg"
	fs.AnchorPoint = Vector2.new(1, 0)
	fs.Position = UDim2.new(1, -20, 0, 0)
	fs.Size = UDim2.new(0, 42, 1, 0)
	fs.BackgroundTransparency = 1
	fs.Font = Enum.Font.GothamBold
	fs.TextSize = 13
	fs.TextXAlignment = Enum.TextXAlignment.Right
	fs.TextColor3 = FARG_TUR
	fs.Text = ""
	fs.Parent = hk
	framsteg = fs

	local pl = Instance.new("TextLabel")
	pl.Name = "Pil"
	pl.AnchorPoint = Vector2.new(1, 0)
	pl.Position = UDim2.new(1, 0, 0, 0)
	pl.Size = UDim2.new(0, 16, 1, 0)
	pl.BackgroundTransparency = 1
	pl.Font = Enum.Font.GothamBold
	pl.TextSize = 14
	pl.TextColor3 = FARG_VILAR
	pl.Text = "▼"
	pl.Parent = hk
	pil = pl

	hk.Activated:Connect(function() PreparationController.vaxla() end)

	--[[ Faserna rullar: på en liten skärm ryms inte fem rader under
		huvudet utan att panelen växer ned i siktrutan. ]]
	local lista = Instance.new("ScrollingFrame")
	lista.Name = "Steg"
	lista.Position = UDim2.new(0, 0, 0, PreparationController.TRAFFYTA + GAP)
	lista.Size = UDim2.new(1, 0, 0, 0)
	lista.BackgroundTransparency = 1
	lista.BorderSizePixel = 0
	lista.ScrollBarThickness = 3
	lista.AutomaticCanvasSize = Enum.AutomaticSize.Y
	lista.CanvasSize = UDim2.new(0, 0, 0, 0)
	lista.Visible = false
	lista.Parent = sp

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, 2)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = lista
	stegLista = lista :: any
	radBehallare = lista :: any

	local h = Instance.new("TextLabel")
	h.Name = "Hjalp"
	h.AnchorPoint = Vector2.new(0, 1)
	h.Position = UDim2.new(0, 0, 1, 0)
	h.Size = UDim2.new(1, 0, 0, HJALP_HOJD)
	h.BackgroundTransparency = 1
	h.Font = Enum.Font.Gotham
	h.TextSize = 12
	h.TextWrapped = true
	h.TextXAlignment = Enum.TextXAlignment.Left
	h.TextYAlignment = Enum.TextYAlignment.Bottom
	h.TextColor3 = Color3.fromRGB(186, 190, 194)
	h.Text = ""
	h.Visible = false
	h.Parent = sp
	hjalp = h

	-- ── INTERAKTIONEN ───────────────────────────────────────────────
	local ip = Instance.new("Frame")
	ip.Name = "Interaktion"
	ip.BackgroundColor3 = Color3.fromRGB(24, 26, 28)
	ip.BackgroundTransparency = 0.1
	ip.BorderSizePixel = 0
	ip.Visible = false
	ip.Parent = g
	interaktion = ip

	local iphorn = Instance.new("UICorner")
	iphorn.CornerRadius = UDim.new(0, 10)
	iphorn.Parent = ip

	local ippad = Instance.new("UIPadding")
	ippad.PaddingTop = UDim.new(0, 10)
	ippad.PaddingBottom = UDim.new(0, 10)
	ippad.PaddingLeft = UDim.new(0, 12)
	ippad.PaddingRight = UDim.new(0, 12)
	ippad.Parent = ip

	--[[ Samma text som spårarens hjälprad, på det ställe spelaren tittar
		medan hon väljer. Servern skriver sitt nej hit, och det är hela
		skälet till att den finns: ett avslag som bara stod i en hopfälld
		panel hade aldrig blivit läst. ]]
	local ins = Instance.new("TextLabel")
	ins.Name = "Instruktion"
	ins.Size = UDim2.new(1, 0, 0, 36)
	ins.BackgroundTransparency = 1
	ins.Font = Enum.Font.GothamBold
	ins.TextSize = 14
	ins.TextWrapped = true
	ins.TextXAlignment = Enum.TextXAlignment.Left
	ins.TextColor3 = FARG_TEXT
	ins.Text = ""
	ins.Parent = ip
	instruktion = ins

	--[[ Momenten rullar. Ryktningen har sex och iordningställandet åtta;
		på en telefon i liggande läge ryms de inte alla, och en lista som
		klipps av utan att gå att rulla är en lista där de sista stegen inte
		finns. ScrollBarThickness 4 för att stapeln inte ska äta träffytan. ]]
	local mlista = Instance.new("ScrollingFrame")
	mlista.Name = "Moment"
	mlista.Position = UDim2.new(0, 0, 0, 42)
	mlista.Size = UDim2.new(1, 0, 1, -42)
	mlista.BackgroundTransparency = 1
	mlista.BorderSizePixel = 0
	mlista.ScrollBarThickness = 4
	mlista.AutomaticCanvasSize = Enum.AutomaticSize.Y
	mlista.CanvasSize = UDim2.new(0, 0, 0, 0)
	mlista.Parent = ip

	local mlayout = Instance.new("UIListLayout")
	mlayout.FillDirection = Enum.FillDirection.Vertical
	mlayout.Padding = UDim.new(0, INTERAKTION_RAD)
	mlayout.SortOrder = Enum.SortOrder.LayoutOrder
	mlayout.Parent = mlista
	momentBehallare = mlista :: any

	--[[ VÄXLINGEN. Panelen är hopfälld som standard och visar då bara det
		val som står på tur; den här knappen fäller ut resten. Den finns
		bara när det finns mer än ett val — se `tillampaLayout`. ]]
	local iv = Instance.new("TextButton")
	iv.Name = "InteraktionVaxla"
	iv.AnchorPoint = Vector2.new(0, 0)
	iv.Size = UDim2.new(1, 0, 0, STEGRAD)
	iv.Position = UDim2.new(0, 0, 1, -STEGRAD)
	iv.BackgroundTransparency = 1
	iv.AutoButtonColor = false
	iv.Font = Enum.Font.Gotham
	iv.TextSize = 12
	iv.TextXAlignment = Enum.TextXAlignment.Left
	iv.TextColor3 = FARG_TUR
	iv.Text = ""
	iv.Visible = false
	iv.Parent = ip
	iv.Activated:Connect(function()
		PreparationController._vaxlaInteraktion()
	end)
	interaktionVaxla = iv

	gui = g
	PreparationController.tillampaLayout()

	--[[ Skärmen kan ändra storlek medan HUD:en står uppe: rotation på en
		iPad, ett fönster som dras. Layouten räknas om då. Signalen finns
		inte på alla klienter — ett explicit typtest, inget pcall. ]]
	local cam = Workspace.CurrentCamera
	if cam and type((cam :: any).GetPropertyChangedSignal) == "function" then
		(cam :: any):GetPropertyChangedSignal("ViewportSize"):Connect(function()
			PreparationController.tillampaLayout()
		end)
	end
end

--[[ En fasrad. LÄGESVISNING, inte en knapp — se filhuvudet. ]]
local function rad(steg: any, ordning: number)
	local befintlig = rader[steg.id]
	if not befintlig then
		local ram = Instance.new("Frame")
		ram.Name = steg.id
		ram.Size = UDim2.new(1, 0, 0, 20)
		ram.BackgroundTransparency = 1
		ram.BorderSizePixel = 0
		ram.Parent = radBehallare

		local bock = Instance.new("TextLabel")
		bock.Name = "Bock"
		bock.Size = UDim2.new(0, 22, 1, 0)
		bock.BackgroundTransparency = 1
		bock.Font = Enum.Font.GothamBold
		bock.TextSize = 13
		bock.Parent = ram

		local namn = Instance.new("TextLabel")
		namn.Name = "Namn"
		namn.Position = UDim2.new(0, 24, 0, 0)
		namn.Size = UDim2.new(1, -28, 1, 0)
		namn.BackgroundTransparency = 1
		namn.Font = Enum.Font.Gotham
		namn.TextSize = 12
		namn.TextXAlignment = Enum.TextXAlignment.Left
		namn.Parent = ram

		befintlig = { ram = ram, bock = bock, namn = namn }
		rader[steg.id] = befintlig
	end

	befintlig.ram.LayoutOrder = ordning
	befintlig.ram.Visible = true
	befintlig.namn.Text = steg.namn
	if steg.klar then
		befintlig.bock.Text = "✓"
		befintlig.bock.TextColor3 = FARG_KLAR
		befintlig.namn.TextColor3 = FARG_KLAR
	elseif senasteVy and senasteVy.nasta == steg.id then
		befintlig.bock.Text = "•"
		befintlig.bock.TextColor3 = FARG_TUR
		befintlig.namn.TextColor3 = FARG_TEXT
	else
		befintlig.bock.Text = "·"
		befintlig.bock.TextColor3 = FARG_VILAR
		befintlig.namn.TextColor3 = FARG_VILAR
	end
end

--[[ En momentknapp. `skicka` är vad ett tryck gör — den skiljer sig mellan
	skötselmoment, fyndsvar och eftervård, men RADEN är densamma. ]]
local function momentRad(m: any, ordning: number, paTur: boolean, skicka: () -> ())
	local knapp = momentRader[m.id]
	if not knapp then
		knapp = Instance.new("TextButton")
		knapp.Name = m.id
		knapp.Size = UDim2.new(1, -6, 0, PreparationController.TRAFFYTA)
		knapp.BackgroundColor3 = Color3.fromRGB(38, 41, 44)
		knapp.BorderSizePixel = 0
		knapp.AutoButtonColor = true
		knapp.Font = Enum.Font.Gotham
		knapp.TextSize = 13
		knapp.TextXAlignment = Enum.TextXAlignment.Left
		knapp.TextWrapped = true
		knapp.Text = ""
		knapp.Parent = momentBehallare

		local horn = Instance.new("UICorner")
		horn.CornerRadius = UDim.new(0, 6)
		horn.Parent = knapp

		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, 10)
		pad.PaddingRight = UDim.new(0, 10)
		pad.Parent = knapp

		momentRader[m.id] = knapp
	end
	--[[ Lyssnaren kopplas om varje gång: samma knapp-id kan betyda ett
		skötselmoment i en vy och ett eftervårdsmoment i nästa, och en
		gammal lyssnare som ligger kvar skickar fel avsikt till servern.

		Anslutningarna hålls i en egen tabell och inte som ett barn till
		knappen. Ett barn hade krävt `Destroying` för att städas, och det
		är en signal HUD:en inte behöver bry sig om — den vet redan exakt
		när den kopplar om. ]]
	local gammal = momentKoppling[m.id]
	if gammal then gammal:Disconnect() end
	--[[ Utom räckhåll kopplas ingen lyssnare alls. Att koppla en som
		skickar och låta servern neka hade gett spelaren ett nej på något
		HUD:en själv redan visste var omöjligt. ]]
	if utomRackhall then
		momentKoppling[m.id] = nil
	else
		momentKoppling[m.id] = knapp.Activated:Connect(skicka)
	end

	knapp.LayoutOrder = ordning
	knapp.Visible = true
	knapp.Text = (if m.klar then "✓  " else "")  .. m.namn

	if utomRackhall and not m.klar then
		--[[ Död knapp. Sedan PO-ordern 09:36 GÖMS hela interaktionspanelen
			när spelaren är utom räckhåll, så den här stilen når normalt
			ingen skärm — den står kvar som fail-safe: skulle panelen av
			något skäl ändå visas får knappen inte se ut som ett löfte
			servern samtidigt nekar. ]]
		knapp.TextColor3 = FARG_VILAR
		knapp.BackgroundColor3 = Color3.fromRGB(30, 31, 33)
		knapp.AutoButtonColor = false
		knapp.Active = false
		return
	end
	knapp.Active = true

	if m.klar then
		knapp.TextColor3 = FARG_KLAR
		knapp.BackgroundColor3 = Color3.fromRGB(30, 38, 32)
		knapp.AutoButtonColor = false
	elseif m.fel then
		--[[ Ett felaktigt alternativ ritas som ett alternativ, inte som en
			varning. Att gråa ut det hade tagit bort valet, och därmed hela
			lärandet — se `Preparation`s not om `fel`. ]]
		knapp.TextColor3 = FARG_TEXT
		knapp.BackgroundColor3 = Color3.fromRGB(38, 41, 44)
		knapp.AutoButtonColor = true
	elseif paTur then
		knapp.TextColor3 = Color3.fromRGB(23, 20, 10)
		knapp.BackgroundColor3 = FARG_TUR
		knapp.AutoButtonColor = true
	else
		knapp.TextColor3 = FARG_VILAR
		knapp.BackgroundColor3 = Color3.fromRGB(32, 34, 37)
		knapp.AutoButtonColor = true
	end
end

local function doljOanvanda(anvanda: { [string]: boolean })
	--[[ Registret först, synligheten sedan. `tillampaLayout` äger den
		andra halvan: den vet om panelen är hopfälld, och det gör inte
		den här funktionen. ]]
	table.clear(anvandaNu)
	for id in pairs(anvanda) do anvandaNu[id] = true end
	for id, knapp in pairs(momentRader) do
		knapp.Visible = anvanda[id] == true
	end
end

--[[ Observatörer som körs EFTER att en ny vy tagits emot och skrivits ned.
	Uppsittningsprompten hänger här. ]]
local lyssnare: { (any) -> () } = {}

function PreparationController.vidNyVy(fn: (any) -> ())
	table.insert(lyssnare, fn)
end

--[[ Enda vägen in till HUD:en. Allt som kommer utifrån — spontan sync eller
	svar på handskakningen — går genom den här, och den släpper bara igenom
	en NYARE vy (krav 10).

	Den anropar också observatörerna, och det är en RÄTTELSE: förut låg
	prompt-uppdateringen i en EGEN `PreparationSync`-listener i init.client.
	Handskakningens svar går inte genom den listenern, så en klient som
	initierades sent när servern redan stod på `ready_to_mount` fick rätt
	HUD men ALDRIG någon "Sitt upp"-prompt — det kom ingen ny sync att
	väcka den. Fälldes av senior review, runda 2.

	Att lägga det här i stället för i en andra listener tar dessutom bort
	beroendet av i vilken ordning två listeners på samma RemoteEvent råkar
	köra: observatören kan inte köra före den vy den beskriver. ]]
local function ritaOmNyare(vy: any)
	if not Preparation.farRita(senasteRev, vy) then return end
	senasteRev = vy.rev
	rita(vy)
	for _, fn in ipairs(lyssnare) do
		fn(vy)
	end
end

--[[ Exporterad för provet: samma väg in som nätet använder. Provet ska driva
	den riktiga funktionen, inte en kopia av regeln. ]]
function PreparationController.tillampa(vy: any)
	ritaOmNyare(vy)
end

function PreparationController.tillampaPass(vy: any)
	--[[ Samma revisionsregel som förberedelsen, men på sin egen räknare. ]]
	if not Preparation.farRita(senastePassRev, vy) then return end
	senastePassRev = vy.rev
	senastePass = vy
	if senasteVy then rita(senasteVy) end
end

--[[ Står eftervården på tur? Passvyn äger frågan; förberedelsen vet inget
	om den. ]]
local function iEftervard(): boolean
	return senastePass ~= nil and senastePass.lage == "aftercare"
end

--[[ Är passet RÄKNAT och sparat? (#162 omreview, fynd 3.)

	`Pass.markeraRaknat` sätter `lage = "recorded"`. Den här vyn kände bara
	igen `aftercare`, så `recorded` föll igenom till skötselvyn — och där är
	förberedelsen fortfarande komplett, så rubriken blev **"Klar — du kan
	sitta upp"**. Samtidigt nekar `GameplayService.farSittaUpp` samma
	spelare med **"Du har redan ridit idag"**, eftersom `lage ~= before_ride`.

	Servergrinden är rätt: den är fail-closed. Det var PRESENTATIONEN som
	ljög, och en First Playable får aldrig be spelaren om något servern
	uttryckligen nekar. ]]
local function passRaknat(): boolean
	return senastePass ~= nil and senastePass.lage == "recorded"
end

--[[ Framstegen som två tal: avklarade av totalt. Faserna är målet under
	skötseln; i eftervården är det passets egna moment som räknas, för då
	finns inga faser kvar att göra. ]]
local function raknaFramsteg(): (number, number)
	local klara, totalt = 0, 0
	if iEftervard() and senastePass then
		for _, m in ipairs(senastePass.moment or {}) do
			totalt += 1
			if m.klar then klara += 1 end
		end
	elseif senasteVy then
		for _, s in ipairs(senasteVy.steg or {}) do
			totalt += 1
			if s.klar then klara += 1 end
		end
	end
	return klara, totalt
end

function PreparationController._framsteg(): (number, number)
	return raknaFramsteg()
end

--[[ HÅLLER SPELAREN PÅ MED NÅGOT JUST NU?

	Två villkor, båda nödvändiga: det finns något att välja på, och hon är
	inom räckhåll för hästen. Annars finns interaktionspanelen inte alls.

	Det är hela PO-ordern om de stora valen: de hör till STUNDEN, inte till
	skärmen. Räckvidden är serverns egen (`utomRackhall`), samma gräns som
	avgör om ett moment ens går att trycka på — HUD:en hittar alltså ingen
	ny regel på, den slutar bara rita det den redan visste var omöjligt. ]]
local function interaktionPagar(antalVal: number): boolean
	return antalVal > 0 and not utomRackhall
end

--[[ SLUTET PÅ VARJE VY, på ett ställe.

	Alla fem grenar i `rita` hamnar här, och det är avsiktligt: läget,
	hjälptexten, framstegen, interaktionspanelens existens och layouten
	hänger ihop, och fem kopior av den kopplingen hade glidit isär vid
	första ändringen — precis som rubriken och servern gjorde i P0-3. ]]
local function avsluta(lage: string, antalVal: number, ledtext: string,
	synlig: boolean)
	--[[ Ett läge utan något att trycka på men med något att förklara
		fäller UT spåraren EN gång. Sedan är läget spelarens igen. ]]
	if lage ~= senasteLage then
		senasteLage = lage
		if antalVal == 0 and ledtext ~= "" then utvidgad = true end
	end
	if hjalp then hjalp.Text = ledtext end
	if instruktion then instruktion.Text = ledtext end
	local h = interaktion
	if h then h.Visible = interaktionPagar(antalVal) end
	local klara, totalt = raknaFramsteg()
	if framsteg then
		framsteg.Text = if totalt > 0 then ("%d/%d"):format(klara, totalt) else ""
	end
	PreparationController.tillampaLayout()
	if gui then gui.Enabled = synlig end
end

function rita(vy: any)
	bygg()
	senasteVy = vy

	local anvanda: { [string]: boolean } = {}

	--[[ #162 punkt 1: KANONEN BYTER SPRÅK HÄR. Servern skickar
		skötselkanonens svenska mening — den är kanonens stabila identitet —
		och klienten slår upp den engelska syskontexten, för det är först
		här spelarens locale finns. Hästens egennamn sätts in samtidigt
		(`%N`) och översätts aldrig. ]]
	local sprak = Sprak.eget()
	local hastnamn = if type(vy.hastnamn) == "string" then vy.hastnamn else nil
	local function lokalt(m: any) return Preparation.momentPaSprak(m, sprak, hastnamn) end
	local function lokaltSteg(s: any) return Preparation.stegPaSprak(s, sprak) end
	local function lokalKanon(s: any)
		local ut = Preparation.kanonPaSprak(if type(s) == "string" then s else nil, sprak)
		if hastnamn and type(ut) == "string" then ut = string.gsub(ut, "%%N", hastnamn) end
		return ut or ""
	end

	--[[ ── 1. VÄLFÄRDSSTOPPET ─────────────────────────────────────
		Ligger först för att det stänger allt annat. Ingen fas, inget
		moment, ingen uppsittning — bara texten om varför. ]]
	if vy.stoppad then
		for _, r in pairs(rader) do r.ram.Visible = false end
		doljOanvanda(anvanda)
		if rubrik then rubrik.Text = Sprak.t("hud.lararen_tar_over") end
		avsluta("stoppad", 0, lokalKanon(vy.stoppad), true)
		return
	end

	--[[ ── 2. FYNDET ──────────────────────────────────────────────
		Ett obesvarat fynd tar över panelen. Faserna ritas kvar som lägesbild
		— spelaren ska se var i dagen hon är — men det enda som går att
		trycka på är svaren. ]]
	for i, steg in ipairs(vy.steg or {}) do
		rad(lokaltSteg(steg), i)
	end

	if vy.svar and #vy.svar > 0 then
		for i, s in ipairs(vy.svar) do
			anvanda[s.id] = true
			momentRad(lokalt({ id = s.id, namn = s.namn, klar = false, fel = s.fel }),
				i, not s.fel, function() PreparationController.svara(s.id) end)
		end
		doljOanvanda(anvanda)
		if rubrik then rubrik.Text = Sprak.t("hud.du_hittade_nagot") end
		avsluta("fynd", #vy.svar, lokalKanon(vy.fynd), true)
		return
	end

	--[[ ── 3. EFTERVÅRDEN ─────────────────────────────────────────
		Passet är i `aftercare`. Faserna är avklarade och ointressanta nu;
		det som återstår är hästen. ]]
	if iEftervard() then
		for _, r in pairs(rader) do r.ram.Visible = false end
		local nasta = senastePass.nastaMoment
		local text = ""
		for i, m in ipairs(senastePass.moment or {}) do
			anvanda[m.id] = true
			local lm = lokalt(m)
			momentRad(lm, i, m.id == nasta, function()
				PreparationController.eftervard(m.id)
			end)
			if m.id == nasta then text = lm.text or "" end
		end
		doljOanvanda(anvanda)
		if rubrik then rubrik.Text = Sprak.t("hud.ta_hand_om_henne") end
		avsluta("eftervard", #(senastePass.moment or {}), text, true)
		return
	end

	--[[ ── 3b. PASSET ÄR RÄKNAT ───────────────────────────────────
		Dagens pass är avslutat och sparat. Det finns ingenting kvar att
		göra på den här hästen idag, och framför allt: sitt INTE upp — det
		nekar servern. Raderna släcks; ett moment att trycka på här vore
		samma lögn som rubriken var. ]]
	if passRaknat() then
		for _, r in pairs(rader) do r.ram.Visible = false end
		doljOanvanda(anvanda)
		if rubrik then rubrik.Text = Sprak.t("hud.passet_sparat") end
		avsluta("raknat", 0, Sprak.t("hud.bra_jobbat"), true)
		return
	end

	--[[ ── 4. SKÖTSELN ────────────────────────────────────────────── ]]
	local nasta = vy.nastaMoment
	local momenttext = ""
	for i, m in ipairs(vy.moment or {}) do
		anvanda[m.id] = true
		local lm = lokalt(m)
		momentRad(lm, i, m.id == nasta, function()
			PreparationController.begar(vy.nasta, m.id)
		end)
		if m.id == nasta then momenttext = lm.text or "" end
	end
	doljOanvanda(anvanda)

	local lage, ledtext = "skotsel", momenttext
	if vy.status == "waiting_model" then
		lage, ledtext = "vantar", Sprak.t("hud.hast_inte_i_varlden")
		if rubrik then rubrik.Text = Sprak.t("hud.vantar_pa_hast") end
	elseif vy.status == "riding" then
		lage, ledtext = "rider", ""
		if rubrik then rubrik.Text = Sprak.t("hud.du_rider") end
	elseif vy.redo then
		lage, ledtext = "redo", Sprak.t("hud.kolla_gjorden")
		if rubrik then rubrik.Text = Sprak.t("hud.klar_sitt_upp") end
	else
		local fasnamn = nil
		for _, steg in ipairs(vy.steg or {}) do
			if steg.id == vy.nasta then fasnamn = lokaltSteg(steg).namn end
		end
		lage = "skotsel:" .. tostring(vy.nasta)
		if rubrik then rubrik.Text = fasnamn or Sprak.t("hud.gor_i_ordning") end
	end

	--[[ RUBRIKEN PEKAR TILLBAKA när hästen är utom räckhåll. Den skrivs
		SIST och över allt annat: vilket läge vyn än beskriver är det inte
		det som gäller för spelaren just nu, och en instruktion man inte
		kan följa är värre än ingen. Lägen som inte handlar om att göra
		något vid hästen (välfärdsstopp, passet sparat, man rider) rörs
		inte — de har inget att lova. ]]
	if utomRackhall and rubrik
		and vy.status ~= "riding" and vy.status ~= "welfare_stop"
		and not passRaknat() then
		rubrik.Text = if hastnamn
			then Sprak.t("hud.ga_tillbaka", hastnamn)
			else Sprak.t("hud.ga_tillbaka_utan_namn")
	end

	--[[ HUD:en göms medan man rider — men INTE när eftervården väntar, och
		det är hela skillnaden mot före #161: en spelare som satt av mötte
		förut en tom skärm, och passet tog aldrig slut. ]]
	avsluta(lage, #(vy.moment or {}), ledtext, vy.status ~= "riding")
end

--[[ Körs av klientens loop. Ritar bara om när kontexten FAKTISKT byter —
	en HUD som byggs om varje bildruta är en HUD som flimrar. ]]
function PreparationController.uppdateraKontext()
	local d = avstandTillHast(senasteVy)
	local nu = d ~= nil and d > rackvidd()
	if nu ~= utomRackhall then
		utomRackhall = nu
		if senasteVy then rita(senasteVy) end
	end
end

--[[ Provets fönster in. Grinden ska mäta samma tillstånd spelaren ser. ]]
function PreparationController._utomRackhall(): boolean
	return utomRackhall
end
function PreparationController._momentGarAttTrycka(id: string): boolean
	return momentKoppling[id] ~= nil
end

--[[ ── AVSIKTERNA UT ────────────────────────────────────────────────

	Alla tre går samma väg: ett fjärranrop med en AVSIKT, ett svar som bara
	får ändra hjälptexten. Ett avslag ritar INTE om listan. Servern skickar
	alltid en färsk sync efter varje försök, och den är sanningen; skulle
	det här svaret rita något eget skulle det kunna komma efter och skriva
	över den. ]]
--[[ SERVERNS NEJ, I SPELARENS SPRÅK.

	Servern skickar aldrig svensk prosa över nätet sedan #162. Den skickar
	en SPRÅKNYCKEL ("spel.for_langt") och ibland ett argument (fasens namn),
	och den här funktionen skriver texten — här, där spelarens locale är
	känd. Tre fall, i den ordningen:

	  1. `kanon:…` — skötselkanonens egen mening (välfärdsstoppet, ett
	     moments förklaring). Innehåll, inte gränssnitt — men sedan
	     produktbeslutet i #162 HAR kanonen engelska poster, så meningen
	     slås upp på spelarens språk i stället för att visas rå.
	  2. en nyckel som finns i katalogen — översätts, med argumentet.
	  3. något annat — visas som det är. Det ska inte hända, och att det
	     syns i klartext är avsiktligt: ett kvarglömt rått skäl ska
	     upptäckas, inte döljas bakom en generisk fras.

	Publik för att grinden ska kunna mäta samma funktion klienten kör. ]]
--[[ Kanonens mening på spelarens språk, med hästens egennamn insatt där
	kanonen skriver `%N`. Egennamnet kommer ur den senaste vyn och
	översätts aldrig. ]]
local function kanonPaEgetSprak(text: string): string
	local ut = Preparation.kanonPaSprak(text, Sprak.eget()) or text
	local namn = senasteVy and senasteVy.hastnamn
	if type(namn) == "string" and namn ~= "" then
		ut = string.gsub(ut, "%%N", namn)
	end
	return ut
end

function PreparationController.skalText(skal: any, extra: any?): string
	if type(skal) ~= "string" or skal == "" then
		return Sprak.t("hud.gick_inte_nu")
	end
	if Preparation.arKanontext(skal) then
		return kanonPaEgetSprak(Preparation.utanKanonprefix(skal))
	end
	if Sprak.finns(skal) then
		--[[ ARGUMENTET kan i sin tur vara kanontext: välfärdsstoppet är en
			engelsk RAM runt fyndets svenska mening ur skötselkanonen.
			Prefixet strippas här, och grinden räknar posten som redovisad
			översättningsskuld — ramen ska vara på spelarens språk även när
			meningen inuti ännu inte är översatt. ]]
		local arg = extra
		if Preparation.arKanontext(arg) then
			arg = kanonPaEgetSprak(Preparation.utanKanonprefix(arg))
		elseif type(arg) == "string" and Sprak.finns(arg) then
			arg = Sprak.t(arg)
		end
		return if arg ~= nil then Sprak.t(skal, arg) else Sprak.t(skal)
	end
	return skal
end

local function skicka(nyckel: string, remote: string, ...)
	if vantarPa then return end
	vantarPa = nyckel
	local args = table.pack(...)
	task.spawn(function()
		local ok, skal, extra = Net.get(remote):InvokeServer(table.unpack(args, 1, args.n))
		vantarPa = nil
		if not ok then
			--[[ Nejet skrivs på BÅDA ytorna. Spelaren tittar på
				interaktionspanelen när hon just tryckt; ett avslag som bara
				stod i en hopfälld spårare hade aldrig blivit läst. ]]
			local text = PreparationController.skalText(skal, extra)
			if hjalp then hjalp.Text = text end
			if instruktion then instruktion.Text = text end
		end
	end)
end

function PreparationController.begar(fasId: string?, momentId: string?)
	if not fasId or not momentId then return end
	skicka(momentId, "PreparationMoment", fasId, momentId)
end

function PreparationController.svara(svarId: string)
	skicka(svarId, "PreparationSvar", svarId)
end

function PreparationController.eftervard(momentId: string)
	skicka(momentId, "PassMoment", momentId)
end

function PreparationController.redo(): boolean
	return senasteVy ~= nil and senasteVy.redo == true
end

--[[ Vilket steg spelaren STÅR PÅ. Ledningens prompt hänger på den:
	`redo` blir sant först när ALLA faser är avbockade, och `leda` är en av
	dem — så `redo` kan aldrig vara det som öppnar ledningen. ]]
function PreparationController.nastaFas(): string?
	return senasteVy and senasteVy.nasta or nil
end

function PreparationController.hastId(): string?
	return senasteVy and senasteVy.hastId or nil
end

--[[ Provkrokar: vad HUD:en faktiskt ritade. Provet läser dem i stället för
	att bygga en egen uppfattning om vad som borde ha ritats. ]]
--[[ De moment spelaren FAKTISKT ser. Knapparna bor i
	interaktionspanelen, och är den gömd finns de inte på skärmen —
	att räkna dem ändå hade gjort grinden till en mätning av
	instanser i stället för av spelarens vy. ]]
function PreparationController._synligaMoment(): { string }
	local ut = {}
	if not (interaktion and interaktion.Visible) then return ut end
	for id, knapp in pairs(momentRader) do
		if knapp.Visible then table.insert(ut, id) end
	end
	table.sort(ut)
	return ut
end

function PreparationController._rubrik(): string
	return rubrik and rubrik.Text or ""
end

function PreparationController._hjalptext(): string
	return hjalp and hjalp.Text or ""
end

--[[ ALLT HUD:EN FAKTISKT RITADE, som text. Grinden (#162 punkt 4) sveper
	hela First Playable-dagen på en-us och läser den här listan; den får
	inte innehålla en enda svensk bokstav. Att provet läser de RITADE
	etiketterna, inte vyn det skickade in, är hela poängen: en översättning
	som aldrig når TextLabel:en är ingen översättning. ]]
function PreparationController._ritadText(): { string }
	local ut = {}
	if rubrik then table.insert(ut, rubrik.Text) end
	if hjalp then table.insert(ut, hjalp.Text) end
	if instruktion and interaktion and interaktion.Visible then
		table.insert(ut, instruktion.Text)
	end
	for _, r in pairs(rader) do
		if r.ram.Visible then table.insert(ut, r.namn.Text) end
	end
	for _, id in ipairs(PreparationController._synligaMoment()) do
		local knapp = momentRader[id]
		if knapp then table.insert(ut, knapp.Text) end
	end
	return ut
end

function PreparationController.start()
	--[[ ORDNINGEN ÄR KONTRAKTET: listenerna ansluts FÖRST, handskakningen
		anropas sedan. Servern skickar sin första vy från `bind()` vid
		PlayerAdded, och en RemoteEvent som avfyras innan någon lyssnar är
		borta för alltid — den köas inte. Utan handskakningen startade
		klienten därför utan hästId, steg och ready-state, utan någon
		deterministisk ny sync att vänta på.

		`PassSync` ansluts i samma andetag och av exakt samma skäl: servern
		skickar passvyn direkt i handskakningen, och en klient som inte
		lyssnade än hade missat att eftervården väntade. ]]
	Net.get("PreparationSync").OnClientEvent:Connect(ritaOmNyare)
	Net.get("PassSync").OnClientEvent:Connect(PreparationController.tillampaPass)

	task.spawn(function()
		local ok, vy = pcall(function()
			return Net.get("PreparationHello"):InvokeServer()
		end)
		if ok and vy then
			ritaOmNyare(vy)
		end
	end)
end

return PreparationController
