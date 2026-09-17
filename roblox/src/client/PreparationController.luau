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

--[[ ══ EN SAK I TAGET (#185) ════════════════════════════════════════

	Produktordern: `1 uppgift → 1 handling → direkt feedback → nästa
	uppgift`. Tre saker i den här filen bröt mot den, och de mäts nu var
	för sig i `forberedelse.spec`:

	  1. HOPFÄLLD VISADE FEL RAD. Panelen valde raden med lägst
	     `LayoutOrder`, alltså listans FÖRSTA moment — inte det som stod på
	     tur. Iordningställandet har nio moment i fast ordning; så fort
	     vänster fram var kratsad visade panelen en avbockad hov medan
	     servern väntade på nästa. Spelaren läste alltså en instruktion hon
	     just utfört. Raden väljs nu på `nastaMoment`, samma tal servern
	     släpper fram.

	  2. "VISA ALLA 9 VAL" LÅG I HUVUDFLÖDET. En gul rad längst ned i
	     panelen bjöd in till att fälla ut hela checklistan — precis det
	     ordern kallar nio saker samtidigt. Kontrollen är nu ett diskret
	     `?` uppe i panelens hörn: samma växling, men den frågar i stället
	     för att erbjuda, och den tar ingen egen höjd (se `HJALPRUTA`).

	  3. INGEN KVITTENS. Ett lyckat moment gav ingen bekräftelse alls;
	     nästa instruktion bara ersatte den förra. Nu står ett kort `✓` en
	     stund innan vyn går vidare av sig själv — ingen "Nästa"-knapp,
	     för det finns inget för spelaren att besluta.

	Hästkunskapen är oförändrad. Det här är presentation: samma moment,
	samma ordning, samma serverregler. ]]
--[[ `?`-rutan i panelens övre högra hörn. Samma tal som en momentknapp:
	ordern förbjuder små träffytor, och en diskret kontroll får vara tyst
	i FÄRG men aldrig i yta. Den delar rad med instruktionen och kostar
	därför ingen egen höjd — den gamla växlingsraden längst ned gjorde
	det, och den var dessutom bara 22 px hög. ]]
local HJALPRUTA = 44
--[[ Hur länge kvittensen står kvar innan vyn ritas om utan den. Publik för
	att provet ska mäta samma tal som spelaren ser. ]]
PreparationController.BEKRAFTELSE_TID = 1.2
--[[ Och hur länge NEJET står kvar. Längre än jat: en kvittens bekräftar
	något spelaren just gjorde och som hon såg hända, medan ett nej ber
	henne göra något annat — hämta sadeln, öppna dörren — och det ska hinna
	läsas innan instruktionen kommer tillbaka. ]]
PreparationController.AVSLAG_TID = 3.0

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
--[[ DET SOM STÅR PÅ TUR, ur den vy som senast ritades. Hopfälld visar
	precis den här raden och ingen annan. Är den `nil` — en vy utan tur,
	till exempel fyndets svar — faller panelen tillbaka på den lägsta
	`LayoutOrder`, vilket är det gamla beteendet. ]]
local paTurNu: string? = nil
--[[ Är raderna ALTERNATIV (hälsningen, fyndets svar) i stället för en
	checklista? Härleds ur vyn själv: ett `fel`-märkt alternativ finns bara
	i en valfas. Används för att kalla hjälpen vid dess rätta namn — en
	checklista fälls ut, ett val har inget mer att visa. ]]
local arValNu = false
--[[ Ska ALLA rader visas trots att panelen är hopfälld? Sant bara för
	fyndets svar. Det är den enda vy som inte har något "på tur": den
	ställer en fråga, och en fråga med ett enda synligt svar är ingen
	fråga. Skötselns faser går aldrig hit — där finns alltid ett moment
	servern släpper fram, och det är det ordern vill se ensamt. ]]
local allaNu = false
--[[ KVITTENSEN. Sätts när servern sagt ja till ett moment och står kvar
	`BEKRAFTELSE_TID` sekunder, även genom de omritningar serverns nya vy
	utlöser. `bekraftelseNr` gör att en andra kvittens hinner före den
	förstas nedräkning utan att den förra släcker den nya. ]]
local bekraftelse: string? = nil
local bekraftelseNr = 0
--[[ ══ NEJET ÄR OCKSÅ ETT MEDDELANDE, INTE EN ETIKETTSKRIVNING (#201) ═══

	Kvittensen ovan är ett TILLSTÅND som `avsluta` läser varje omritning.
	Därför överlever den serverns nya vy — noten där säger precis varför den
	måste göra det.

	Avslaget fick aldrig samma behandling. Det skrev rakt på `instruktion`
	och `hjalp`, och `GameplayService.moment` anropar `skicka(player)` FÖRE
	`return false` i flera grenar. Vyn landar då i samma bildruta och ritar
	om panelen med den gamla instruktionen ovanpå nejet.

	Mätt i Studio på `e6a674c`, spelaren intill sin häst utan hämtad sadel:

	    serverns svar på utr:1  ->  false, tack.hamta_forst
	    skalText(skal)           =  "Saddle and bridle hang on the stall
	                                 front — fetch them first"
	    instruktionen FÖRE       =  "Walk up from the side…"
	    instruktionen EFTER      =  "Walk up from the side…"   <- nejet borta

	Och falsifieringen, ett nej som servern lämnar UTAN vy-push
	(`led.kvar_i_boxen`, som returnerar före `skicka`):

	    instruktionen EFTER      =  "She is still in her stall"   <- syns

	Rättelsen lägger alltså inte till en väntan eller en andra text. Den ger
	nejet SAMMA ägare som jat redan har: ett tillstånd som renderaren läser.
	Servern får fortsätta skicka sin nya vy precis som förut — vyn är sann,
	och den ska landa. ]]
local avslag: string? = nil
local avslagNr = 0
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

--[[ ══ ROBLOX EGNA PEKREGLAGE ═══════════════════════════════════════

	Tobias produktbeslut: spelaren ska KUNNA GÅ medan skötseln pågår, och
	skötselpanelen ska därför flytta på sig i stället för att reglagen
	stängs av.

	Panelen låg på `x = MARGINAL`, alltså nere till vänster — precis där
	Robloxs dynamiska spak bor. Mätt på iPad i landskap:

	    Interaktion      x  12..328   y 638..749
	    ThumbstickStart  x  58..206   y 575..723

	Knapparna låg alltså ovanpå spaken. Måtten läses ur `TouchGui` i
	stället för att skrivas av: spaken flyttar sig mellan enheter, och ett
	tal här hade blivit fel på nästa skärm. Finns inga pekreglage — hela
	skrivbordet — är svaret noll och layouten är oförändrad.

	══ ETT SLÄCKT REGLAGE TAR INGEN PLATS ═════════════════════════════

	`spak.Visible` räckte inte, och det syntes först i en levande klient.

	Spelet släcker Robloxs egna reglage självt medan man rider:
	`TouchControls.egnaReglage` sätter `UserInputService.ModalEnabled`,
	och Roblox svarar med `TouchGui.Enabled = false`. Men Roblox rör inte
	barnens `Visible` när det händer. Mätt på en iPad Air i landskap,
	samma klient, tre avläsningar i rad:

	    reglagen på           Enabled=true   ThumbstickStart.Visible=true
	    ModalEnabled = true   Enabled=FALSE  ThumbstickStart.Visible=true
	    ModalEnabled = false  Enabled=true   ThumbstickStart.Visible=true

	Spaken var alltså borta ur bilden i mittenraden — och panelen stod
	kvar på x 218 i stället för att gå tillbaka till 12. Den väjde för
	något spelaren inte kunde se, och gav bort 206 px av skärmen till
	ingenting. På en telefon i landskap är det skillnaden mellan 8,9 %
	och 17,8 % av siktrutan.

	Ett reglage räknas därför bara om det ÄR på skärmen: synligt självt,
	synligt hela vägen upp genom sina föräldrar, och i en yta som är
	påslagen. ]]

--[[ Är `o` faktiskt synlig för spelaren, hela vägen upp till och med
	ytan den ritas i? `Enabled` finns bara på en `LayerCollector`; ett
	explicit typtest, inget pcall — samma regel som `guiInset`. ]]
local function paSkarmen(o: Instance?, yta: Instance): boolean
	if not o or not o:IsA("GuiObject") or not o.Visible then return false end
	local n: Instance? = o.Parent
	while n do
		if n:IsA("GuiObject") and not n.Visible then return false end
		if n == yta then break end
		n = n.Parent
	end
	local pa = (yta :: any).Enabled
	if type(pa) == "boolean" then return pa end
	return true
end

local function pekreglagensKanter(): (number, number)
	local pg = player and player:FindFirstChildOfClass("PlayerGui")
	local tg = pg and pg:FindFirstChild("TouchGui")
	if not tg then return 0, math.huge end
	local spak = tg:FindFirstChild("ThumbstickStart", true)
	local hopp = tg:FindFirstChild("JumpButton", true)
	local hoger = 0
	if paSkarmen(spak, tg) then
		hoger = (spak :: any).AbsolutePosition.X + (spak :: any).AbsoluteSize.X
	end
	local vanster = math.huge
	if paSkarmen(hopp, tg) then
		vanster = (hopp :: any).AbsolutePosition.X
	end
	return hoger, vanster
end

--[[ ══ ETT HÖRN, ELLER ETT BAND ═══════════════════════════════════

	Panelen var ett hörn på varje skärm, 316 px bred. På en iPad är det
	27 % av bilden och den ligger under hästen. På en telefon i LANDSKAP
	är samma panel 42 % av bilden — och då ligger den inte under henne,
	den ligger framför henne. Avläst ur en levande iPhone 13-klient
	(749 × 367): 20,9 % av siktrutan mot de 3 % kontraktet ger.

	Orsaken är att panelen räknas i PIXLAR medan siktrutan räknas i
	ANDELAR. Samma 110 px är 10 % av en skrivbordshöjd och 30 % av en
	telefons.

	Ren geometri, samma skärm: under siktrutan finns 55 px, och en
	STAPLAD panel — text ovanför en 44 px träffyta — kan inte bli lägre
	än ~100 px. Det finns alltså ingen bredd som räddar hörnet. Att bara
	krympa det gör texten smalare, radbrytningarna fler och panelen
	HÖGRE; hela tabellen är mätt innan den här formen valdes.

	På tvären finns däremot gott om plats: mellan spaken och
	hoppknappen ligger 527 px oanvända. Panelen blir därför ett BAND
	längs nederkanten när hörnet inte får plats — instruktionen till
	vänster, handlingen till höger, i stället för på varandra. Då räcker
	44 px plus luft, och bandet hamnar UNDER siktrutan i stället för i
	den.

	Regeln är responsiv och härledd, inte en enhetsregel: bandet används
	när hörnet skulle ta mer av siktrutan än kontraktet tillåter, och
	bara när bandet tar mindre. En iPad når 0,8 % och behåller alltså
	sitt hörn pixel för pixel; en telefon i landskap byter form. Ingen
	rad i koden nämner en modell.

	Utfälld hjälp är undantaget: då är listan lång, och lång är spelarens
	eget beslut. Den staplas som förut. ]]
--[[ Så stor del av siktrutan panelen får ta innan den byter form. Samma
	tal som `varldshud.spec` mäter hörnet mot — kontraktet, inte ett nytt
	tal. ]]
local SIKT_BUDGET = 0.03
--[[ Bandets handlingskolumn: en andel av bandet, aldrig smalare än två
	träffytor. Resten är instruktionens. ]]
local BAND_RADANDEL = 0.38
--[[ Ett band som inte rymmer en läsbar instruktion är inget band. Under
	det här faller vi tillbaka på hörnet, hur trångt det än är. ]]
local BAND_MINSTA_TEXT = 150

--[[ Siktrutan i pixlar. `SIKTRUTA` är enda källan till talen. ]]
local function siktrutan(B: number, H: number)
	local S = PreparationController.SIKTRUTA
	return { x0 = B * S.x0, x1 = B * S.x1, y0 = H * S.y0, y1 = H * S.y1 }
end

--[[ Hur stor del av siktrutan en ruta tar. Ren räkning. ]]
local function andelAvSikt(x: number, y: number, bredd: number, hojd: number,
	B: number, H: number): number
	local s = siktrutan(B, H)
	local bx = math.max(0, math.min(x + bredd, s.x1) - math.max(x, s.x0))
	local by = math.max(0, math.min(y + hojd, s.y1) - math.max(y, s.y0))
	return (bx * by) / math.max(1, (s.x1 - s.x0) * (s.y1 - s.y0))
end

local function interaktionsLayout(antalVal: number, ledtext: string,
	ut: boolean, alla: boolean): { [string]: any }
	local B, H = viewport()
	--[[ HÖJDEN ÄR INNEHÅLLET. Hopfälld visas EN sak: den som står på tur.
		Det är ordern, och det är hela skillnaden mot att lägga fram nio. ]]
	local visade = if ut or alla then antalVal else math.min(antalVal, 1)
	--[[ HJÄLPEN DELAR RAD MED INSTRUKTIONEN. Huvudet är därför det högsta
		av texten och `?`-rutan — inte summan. Den gamla växlingsraden låg
		längst ned och lade 28 px på varje panel, i varje läge; ordern om
		att hjälpen inte får dominera huvudflödet handlar om plats lika
		mycket som om ord. Rutan finns bara när det FINNS något mer att
		visa: ett ensamt moment har ingen checklista bakom sig. ]]
	local hjalpSyns = antalVal > 1 and not alla
	local hjalpB = if hjalpSyns then HJALPRUTA + GAP else 0

	--[[ NERE, OCH TILL HÖGER OM SPAKEN. På skrivbordet är `spakHoger`
		noll och raden ger `MARGINAL` — samma läge som förut. ]]
	local spakHoger, hoppVanster = pekreglagensKanter()
	local x = MARGINAL
	if spakHoger > 0 then x = math.max(MARGINAL, spakHoger + MARGINAL) end
	--[[ Och aldrig in i hoppknappen. ]]
	local hogerTak = math.min(B - MARGINAL, hoppVanster - MARGINAL)

	local function listhojdFor(n: number): number
		if n <= 0 then return 0 end
		return n * PreparationController.TRAFFYTA + (n - 1) * INTERAKTION_RAD
	end

	--[[ ── FORM A: HÖRNET ─────────────────────────────────────────── ]]
	local function hornet()
		local bredd = math.min(INTERAKTION_BREDD, math.max(120, B - 2 * MARGINAL))
		--[[ Får panelen inte plats mellan spaken och hoppknappen krymper
			den hellre än lägger sig över något. ]]
		if spakHoger > 0 and x + bredd > hogerTak then
			bredd = math.max(120, hogerTak - x)
		end
		local textBredd = bredd - hjalpB
		local textHojd = textrader(ledtext, textBredd) * INTERAKTION_TEXTRAD
		local huvud = math.max(textHojd, if hjalpSyns then HJALPRUTA else 0)
		local listHojd = listhojdFor(visade)
		local hojd = 2 * INNER + huvud
			+ (if listHojd > 0 then GAP + listHojd else 0)
		--[[ Taket: hellre en lista som rullar än en panel som växer upp
			över spelet. Det är listan som ger vika, aldrig texten. ]]
		local tak = math.floor(H * INTERAKTION_TAK)
		if hojd > tak and listHojd > 0 then
			listHojd = math.max(PreparationController.TRAFFYTA,
				listHojd - (hojd - tak))
			hojd = 2 * INNER + huvud + GAP + listHojd
		end
		return { bredd = bredd, hojd = hojd, x = x, y = H - MARGINAL - hojd,
			textHojd = huvud, radHojd = textHojd, listHojd = listHojd,
			textBredd = textBredd, radBredd = bredd, band = 0 }
	end

	--[[ ── FORM B: BANDET ─────────────────────────────────────────── ]]
	local function bandet()
		local bredd = hogerTak - x
		local radBredd = math.max(2 * PreparationController.TRAFFYTA,
			math.floor((bredd - hjalpB) * BAND_RADANDEL))
		local textBredd = bredd - hjalpB - radBredd - GAP
		if textBredd < BAND_MINSTA_TEXT then return nil end
		local textHojd = textrader(ledtext, textBredd) * INTERAKTION_TEXTRAD
		local listHojd = listhojdFor(visade)
		local huvud = math.max(textHojd, if hjalpSyns then HJALPRUTA else 0)
		local hojd = 2 * INNER + math.max(huvud, listHojd)
		--[[ Bandet ligger AN mot nederkanten. Marginalen under det är den
			enda plats som finns kvar under siktrutan; ett band som lämnar
			12 px där hamnar 12 px längre upp — i den. ]]
		return { bredd = bredd, hojd = hojd, x = x, y = H - hojd,
			textHojd = huvud, radHojd = textHojd, listHojd = listHojd,
			textBredd = textBredd, radBredd = radBredd, band = 1 }
	end

	local vald = hornet()
	--[[ Bandet prövas bara när hörnet faktiskt bryter kontraktet, och
		väljs bara när det tar MINDRE av siktrutan än hörnet gör.

		Den jämförelsen är inte en artighet — den är det som håller den
		UTFÄLLDA listan kvar i hörnet. Nio rader är 428 px, och ett band
		med nio rader är högre än en telefon i landskap: det skulle täcka
		hela skärmen. Jämförelsen ser det och väljer hörnet. En separat
		`if not utfälld`-grind hade sagt samma sak en gång till, och den
		dubbleringen gjorde båda omätbara — tog man bort den ena höll den
		andra, och tvärtom. ]]
	local hornAndel = andelAvSikt(vald.x, vald.y, vald.bredd, vald.hojd, B, H)
	if hornAndel > SIKT_BUDGET then
		local b = bandet()
		if b and andelAvSikt(b.x, b.y, b.bredd, b.hojd, B, H) < hornAndel then
			vald = b
		end
	end

	vald.vpBredd, vald.vpHojd = B, H
	vald.visade = visade
	vald.hjalpSyns = if hjalpSyns then 1 else 0
	return vald
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
	--[[ Texten skickas in HEL. Radantalet räknades förut här ute, mot
		konstanten 316 — och det gick så länge panelen alltid var 316 bred.
		Nu väljer layouten både form och bredd, och radbrytningen måste
		räknas mot den bredd som faktiskt blev. ]]
	local I = interaktionsLayout(synligaVal, ledtext, interaktionUt, allaNu)
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
		interaktionLista = I.listHojd, interaktionHjalp = I.hjalpSyns == 1,
		interaktionBand = I.band == 1, interaktionTextBredd = I.textBredd,
		interaktionRadBredd = I.radBredd,
		interaktionPaTur = paTurNu, interaktionArVal = arValNu,
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
	if momentBehallare then
		--[[ I HÖRNET ligger raderna UNDER texten; i BANDET bredvid den.
			Samma instanser, samma innehåll — bara en annan plats, och
			platsen kommer ur layouten, inte härifrån. ]]
		if L.interaktionBand then
			momentBehallare.Position =
				UDim2.new(0, L.interaktionTextBredd + GAP, 0, 0)
			momentBehallare.Size =
				UDim2.new(0, L.interaktionRadBredd, 0, L.interaktionLista)
		else
			momentBehallare.Position = UDim2.new(0, 0, 0,
				L.interaktionText + (if L.interaktionLista > 0 then GAP else 0))
			momentBehallare.Size = UDim2.new(1, 0, 0, L.interaktionLista)
		end
	end
	--[[ HOPFÄLLD VISAR DET SOM STÅR PÅ TUR — och det är `nastaMoment`,
		inte listans första rad.

		Skillnaden är hela #185. `LayoutOrder` är kanonens ORDNING, och de
		avbockade momenten ligger kvar i listan: så fort vänster fram var
		kratsad pekade "lägst LayoutOrder" på en hov med bock medan servern
		väntade på vänster bak. Spelaren läste en instruktion hon redan
		utfört, och den enda knappen som fanns svarade `forb.redan_gjort`.

		`paTurNu` kommer ur vyn servern skickade. Saknas den — fyndets svar
		har ingen tur — faller valet tillbaka på lägsta `LayoutOrder`, som
		förut. ]]
	local lagsta, forst = math.huge, nil
	for id in pairs(anvandaNu) do
		local k = momentRader[id]
		if k and k.LayoutOrder < lagsta then lagsta, forst = k.LayoutOrder, k end
	end
	local paTur = if paTurNu and anvandaNu[paTurNu] then momentRader[paTurNu] else nil
	local enda = paTur or forst
	for id, knapp in pairs(momentRader) do
		knapp.Visible = anvandaNu[id] == true
			and (interaktionUt or allaNu or knapp == enda)
	end
	if interaktionVaxla then
		--[[ DEN FRIVILLIGA HJÄLPEN, och ingenting mer.

			Knappen hette förut "Visa alla 9 val" och låg som en gul rad
			tvärs över panelens nederkant. Den var en INBJUDAN att lägga
			fram hela checklistan, alltså precis det ordern river ut. Den
			är nu ett `?` i hörnet: samma växling, men den frågar i stället
			för att erbjuda, och den tar ingen egen höjd — se `HJALPRUTA`.

			Utfälld bär den en pil tillbaka i stället för ett frågetecken:
			då är frågan redan ställd. U+25B2 och inte U+25B4, för det
			senare saknas i Gotham och ritas som en tom ruta.

			Den LÄSBARA frasen ligger kvar i katalogen och hängs på knappen
			som attribut. Ett `?` utan ord är diskret på skärmen men tyst
			också för den som behöver texten uppläst. ]]
		interaktionVaxla.Visible = L.interaktionHjalp
		interaktionVaxla.Text = if interaktionUt then "\u{25B2}" else "?"
		interaktionVaxla.TextColor3 = if interaktionUt then FARG_TEXT else FARG_VILAR
		interaktionVaxla.Position = UDim2.new(1, -HJALPRUTA, 0, 0)
		interaktionVaxla.Size = UDim2.new(0, HJALPRUTA, 0, HJALPRUTA)
		interaktionVaxla:SetAttribute("Etikett", if interaktionUt
			then Sprak.t("hud.visa_mindre")
			else Sprak.t("hud.behover_du_hjalp"))
	end
	if instruktion then
		--[[ Instruktionen slutar där `?`-rutan börjar. Utan avdraget löper
			sista ordet in under knappen på varje panel som har en. I
			bandet slutar den i stället där handlingskolumnen börjar, och
			den centreras lodrätt mot träffytan bredvid. ]]
		instruktion.Size = UDim2.fromOffset(L.interaktionTextBredd,
			L.interaktionText)
		instruktion.TextYAlignment = if L.interaktionBand
			then Enum.TextYAlignment.Center
			else Enum.TextYAlignment.Top
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
	--[[ Texten börjar UPPTILL. Huvudet är minst `HJALPRUTA` högt så snart
		`?` finns, och en centrerad rad hade då glidit ned från knappen den
		hör ihop med. ]]
	ins.TextYAlignment = Enum.TextYAlignment.Top
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

	--[[ HJÄLPEN. Panelen är hopfälld som standard och visar då EN sak: den
		som står på tur. Den här knappen är vägen till hela checklistan —
		frivillig, diskret och i hörnet, aldrig en rad tvärs över flödet.
		Den finns bara när det finns mer än ett moment; se `tillampaLayout`
		för läge, storlek och text. ]]
	local iv = Instance.new("TextButton")
	iv.Name = "InteraktionVaxla"
	iv.AnchorPoint = Vector2.new(0, 0)
	iv.Size = UDim2.new(0, HJALPRUTA, 0, HJALPRUTA)
	iv.Position = UDim2.new(1, -HJALPRUTA, 0, 0)
	iv.BackgroundTransparency = 1
	iv.AutoButtonColor = false
	iv.Font = Enum.Font.GothamBold
	--[[ Ett ensamt `?` måste vara läsbart på en iPad i solljus utan att bli
		en skylt. 18 px i en 44 px ruta är tecknet litet och TRÄFFYTAN full
		— ordern förbjuder små träffytor, inte små tecken. ]]
	iv.TextSize = 18
	iv.TextXAlignment = Enum.TextXAlignment.Center
	iv.TextColor3 = FARG_VILAR
	iv.Text = "?"
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
	--[[ KVITTENSEN GÅR FÖRE INSTRUKTIONEN, men bara ett ögonblick.

		Serverns nya vy kommer inom någon bildruta efter ett lyckat moment,
		och den ritar om panelen med NÄSTA instruktion. Utan den här raden
		hade kvittensen skrivits över innan spelaren hunnit läsa den — hon
		hade sett listan hoppa ett steg och aldrig fått veta att det hon
		gjorde var rätt. `visaBekraftelse` släcker den själv efteråt. ]]
	if bekraftelse then ledtext = bekraftelse end
	--[[ NEJET GÅR FÖRE KVITTENSEN. De kan aldrig stå uppe samtidigt —
		`visaAvslag` och `visaBekraftelse` släcker varandra — men ordningen
		skrivs ut ändå, så att en framtida tredje sort inte hamnar i en
		tvetydig rad. ]]
	if avslag then ledtext = avslag end
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

--[[ ── DIREKT FEEDBACK ─────────────────────────────────────────────

	`1 uppgift → 1 handling → direkt feedback → nästa uppgift`.

	Servern svarar `(true)` på ett lyckat moment och skickar sedan en ny vy
	— ingen text. Det gjorde de tre första leden osynliga: instruktionen
	byttes ut, och det var allt spelaren fick. Kvittensen skrivs därför
	här, på klienten, av det momentet som just gick igenom.

	AVANCERINGEN ÄR FORTFARANDE SERVERNS. Ingen "Nästa"-knapp läggs till:
	det finns ingenting för spelaren att besluta mellan två moment, och en
	knapp som bara betyder "jag har läst" är en handling till per uppgift.
	Nedräkningen ritar om samma vy utan kvittensen, och då står nästa
	instruktion där av sig själv. ]]
local function visaBekraftelse(text: string?)
	if type(text) ~= "string" or text == "" then return end
	--[[ Ett JA släcker ett nej som står kvar: gjorde hon om momentet och
		det gick igenom är nejet inte längre sant. ]]
	avslag = nil
	avslagNr += 1
	bekraftelse = text
	bekraftelseNr += 1
	local nr = bekraftelseNr
	if instruktion then instruktion.Text = text end
	if hjalp then hjalp.Text = text end
	PreparationController.tillampaLayout()
	task.delay(PreparationController.BEKRAFTELSE_TID, function()
		--[[ En andra kvittens hinner före den förstas nedräkning när
			spelaren trycker snabbt. Numret gör att bara den SENASTE
			nedräkningen får släcka. ]]
		if bekraftelseNr ~= nr then return end
		bekraftelse = nil
		if senasteVy then rita(senasteVy) end
	end)
end

--[[ NEJET, med samma mekanik som kvittensen ovan.

	`avslagNr` gör att ett andra nej hinner före det förstas nedräkning utan
	att den förra släcker det nya — samma skäl som `bekraftelseNr`. ]]
local function visaAvslag(text: string?)
	if type(text) ~= "string" or text == "" then return end
	--[[ Ett NEJ släcker en kvittens som råkar stå kvar. Annars hade panelen
		kunnat visa ett bock-svar på ett moment servern just avvisat — och
		det är den sortens lögn HUD:en blivit rättad för förut. ]]
	bekraftelse = nil
	bekraftelseNr += 1
	avslag = text
	avslagNr += 1
	local nr = avslagNr
	if instruktion then instruktion.Text = text end
	if hjalp then hjalp.Text = text end
	PreparationController.tillampaLayout()
	task.delay(PreparationController.AVSLAG_TID, function()
		if avslagNr ~= nr then return end
		avslag = nil
		if senasteVy then rita(senasteVy) end
	end)
end

--[[ NEJET ÄR PANELENS, OCH DÄRFÖR FÅR ANDRA SKICKA HIT SITT.

	`Rida nu` sitter på en ProximityPrompt i `InteractionController`, som
	skrev sitt avslag med `warn()` — alltså i Output-fönstret. Kommentaren
	där sa "det ska LÄSAS, inte tystas", men en `warn` ser bara den som har
	Studio öppet. Spelaren tryckte på knappen och fick ingenting.

	Panelen äger redan spelarens meddelanderad. Den här funktionen är hela
	kopplingen: den som har ett nej att visa skickar en NYCKEL, och panelen
	översätter och visar det med samma livstid som sina egna. ]]
function PreparationController.visaAvslagFor(skal: any, extra: any?)
	visaAvslag(PreparationController.skalText(skal, extra))
end

--[[ En KVITTENS utifran (#182). Ledningen ager ingen egen meddelanderad
	och ska inte bygga en; den lanar panelens, precis som avslagen redan
	gor. Texten ar fardigformaterad av anroparen — den har filen
	oversatter inte nagon annans handling. ]]
function PreparationController.visaBekraftelseFor(text: any)
	if type(text) == "string" and text ~= "" then visaBekraftelse(text) end
end

--[[ Provets fönster in: står en kvittens uppe, och vilken? ]]
function PreparationController._bekraftelse(): string?
	return bekraftelse
end

--[[ Och står ett nej uppe? Provet läser det som HUD:en faktiskt bär, inte
	det servern råkade svara. ]]
function PreparationController._avslag(): string?
	return avslag
end

function rita(vy: any)
	bygg()
	senasteVy = vy

	--[[ Turen, valläget och "visa allt" hör till den vy som ritas NU.
		Nollställs här så att en gren som inte sätter dem aldrig ärver
		föregående vys tur — en tur som pekar på ett moment den här vyn
		inte har är samma sak som ingen tur alls, men den syns senare och
		är svårare att läsa. ]]
	paTurNu, arValNu, allaNu = nil, false, false

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
		--[[ FRÅGAN BEHÖVER SINA SVAR. Hopfälld visar panelen annars bara
			det första alternativet — "Säg till ridläraren" — och då är
			fyndet inget val längre utan en knapp att trycka bort. Det är
			raka motsatsen till ordern: en handling, ja, men inte spelarens
			egen. Här väger alternativen tyngre än höjden. ]]
		arValNu, allaNu = true, true
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
		paTurNu = nasta
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
	paTurNu = nasta
	local momenttext = ""
	for i, m in ipairs(vy.moment or {}) do
		anvanda[m.id] = true
		if m.fel then arValNu = true end
		local lm = lokalt(m)
		momentRad(lm, i, m.id == nasta, function()
			PreparationController.begar(vy.nasta, m.id)
		end)
		if m.id == nasta then momenttext = lm.text or "" end
	end
	doljOanvanda(anvanda)

	--[[ VAD SKA DET STÅ I INSTRUKTIONEN?

		För en CHECKLISTA är momentets egen text instruktionen: "Lyft upp
		underlägget i bommen. Manken ska vara fri." Den säger vad man gör
		härnäst, och det är precis vad raden ska säga.

		För en VALFAS är den det inte. Hälsningens `text` är kanonens SVAR
		på ett val — "Bra. Nu vet hon att du är där." — och den stod som
		instruktion INNAN spelaren valt. Panelen gratulerade alltså till
		något som ännu inte hänt, och frågan som faktiskt gällde ("Gå fram
		från sidan. Säg hennes namn innan du rör henne.") fanns bara i
		fasens egen text, som ingen yta visade. Nu är fasens text frågan
		och momentets text kvittensen — se `visaBekraftelse`. ]]
	if arValNu then
		for _, steg in ipairs(vy.steg or {}) do
			if steg.id == vy.nasta then
				momenttext = lokaltSteg(steg).text or momenttext
			end
		end
	end

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
			then Sprak.t("hud.ga_till", hastnamn)
			else Sprak.t("hud.ga_till_utan_namn")
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

--[[ Kvittensen för det moment som är på väg iväg. Läses INNAN anropet:
	efter svaret har servern redan skickat en ny vy, och då är momentet
	avbockat och listan kan ha bytt fas. ]]
local function kvittens(lista: any, momentId: string): string
	for _, m in ipairs(lista or {}) do
		if m.id == momentId then
			--[[ En VALFAS bär kanonens egen konsekvens som text — "Bra. Nu
				vet hon att du är där." Den är redan formulerad som svar på
				en handling och säger mer än ett generiskt ord.

				En CHECKLISTA bär i stället nästa instruktion som text, och
				att upprepa den man just följt vore ingen kvittens alls.
				Där räcker det korta ordet. ]]
			if m.fel == true or arValNu then
				local t = Preparation.momentPaSprak(m, Sprak.eget(),
					senasteVy and senasteVy.hastnamn).text
				if type(t) == "string" and t ~= "" then
					return "\u{2713}  " .. t
				end
			end
			break
		end
	end
	return "\u{2713}  " .. Sprak.t("hud.bra")
end

--[[ ── KVITTENSEN KAN KOMMA FRÅN SERVERN (#182) ──────────────────────

	Vilket utrustningssteg som lägger vilken del på hästen vet
	`TackService`, och bara den. Klienten kunde därför skriva "Bra" men
	inte "Sadeln sitter på Trixie" — och det var precis den kvittensen som
	saknades: ingenting namngav vare sig delen eller hästen, så spelaren
	fick ingen bekräftelse på att sadeln faktiskt kommit på plats.

	SERVERN SKICKAR NYCKLAR, ALDRIG FÄRDIG TEXT. Språket är klientens, och
	en server som formaterade texten hade skrivit sitt eget språk till alla
	spelare — samma fel som #162 rev ut ur nejen. Saknas eller går nyckeln
	inte att slå upp faller kvittensen tillbaka på den som räknades fram
	före anropet; en okänd nyckel ska inte kunna tysta feedbacken. ]]
local function serverKvittens(skal: any, extra: any): string?
	if type(skal) ~= "string" or skal == "" or not Sprak.finns(skal) then return nil end
	if type(extra) ~= "table" then return nil end
	local del = extra.del
	if type(del) ~= "string" or not Sprak.finns(del) then return nil end
	local hast = extra.hast
	if type(hast) ~= "string" or hast == "" then return nil end
	return "\u{2713}  " .. Sprak.t(skal, Sprak.t(del), hast)
end

local function skicka(nyckel: string, remote: string, bekrafta: string?, ...)
	if vantarPa then return end
	vantarPa = nyckel
	local args = table.pack(...)
	task.spawn(function()
		local ok, skal, extra = Net.get(remote):InvokeServer(table.unpack(args, 1, args.n))
		vantarPa = nil
		if ok then
			visaBekraftelse(serverKvittens(skal, extra) or bekrafta)
		else
			--[[ Nejet skrivs på BÅDA ytorna. Spelaren tittar på
				interaktionspanelen när hon just tryckt; ett avslag som bara
				stod i en hopfälld spårare hade aldrig blivit läst. ]]
			--[[ Genom `visaAvslag`, inte rakt på etiketterna: servern skickar
				en ny vy i samma bildruta i flera av de här grenarna, och en
				etikettskrivning hade varit borta innan spelaren läst den.
				Se noten vid `avslag`. ]]
			visaAvslag(PreparationController.skalText(skal, extra))
		end
	end)
end

function PreparationController.begar(fasId: string?, momentId: string?)
	if not fasId or not momentId then return end
	skicka(momentId, "PreparationMoment",
		kvittens(senasteVy and senasteVy.moment, momentId), fasId, momentId)
end

function PreparationController.svara(svarId: string)
	--[[ Fyndets svar har ingen egen kanontext — alternativens `text` är
		tom — så kvittensen är det korta ordet. Det RÄTTA svaret är dessutom
		"säg till ridläraren", och där är bekräftelsen att man gjorde rätt
		som sa till, inte en beskrivning av vad som händer sedan. ]]
	skicka(svarId, "PreparationSvar",
		"\u{2713}  " .. Sprak.t("hud.bra"), svarId)
end

function PreparationController.eftervard(momentId: string)
	skicka(momentId, "PassMoment",
		kvittens(senastePass and senastePass.moment, momentId), momentId)
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

--[[ Vad SERVERN säger att spelaren bär (#182). Klienten räknar inte ut
	det själv — `DinHast` ritar bara det vyn redan innehåller, av samma
	skäl som `hastId` ovan läses härifrån och inte ur en egen fråga. ]]
function PreparationController.burenUtrustning(): any
	return senasteVy and senasteVy.burenUtrustning or nil
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
