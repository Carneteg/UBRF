--!strict
--[[ UGNETAS REPLIKER I VÄRLDEN — bubblan och reservloggen (#234 §4).

	Repliken ska komma FRÅN HENNE. Hon står vid sargen bortom C och
	spelaren rider; en text som bara dyker upp i skärmkanten hör inte ihop
	med figuren, och en figur som aldrig säger något är rekvisita.

	Två ytor, EN replik:

	  1. `TextChatService:DisplayBubble` över Ugnetas ansikte. Metoden är
	     klientens egen (kontrollerad mot
	     create.roblox.com/docs/reference/engine/classes/TextChatService,
	     uppdaterad 2026-09-18: "only available for use in a LocalScript")
	     och tar en DEL i figuren — inte figuren — vilket är precis vad
	     gestalten kan ge: hon har ingen `HumanoidRootPart`, och det är
	     `BubbleChatConfiguration.AdorneeName` standard.
	  2. En diskret lokal logg, för när hon är utom synhåll. Samma text,
	     samma ögonblick — `sag` skriver båda eller ingen.

	── DEN GLOBALA BIEFFEKTEN, REDOVISAD OCH BEGRÄNSAD ──────────────────

	`BubbleChatConfiguration` är en SINGLETON under `TextChatService` och
	är dessutom `NotCreatable`. `MaxDistance` och `MinimizeDistance` gäller
	därför ALLA bubblor på den här klienten, inte bara Ugnetas — och de
	går inte att sätta per bubbla: `TextChatService.OnBubbleAdded` kan
	lämna en `BubbleChatMessageProperties`, men den klassen bär bara
	utseende (bakgrund, färg, typsnitt, textstorlek, svans). Ingen
	avståndsegenskap finns i den. Kontrollerat mot samma referens.

	Beställningen säger: begränsa till Ugneta om arkitekturen tillåter,
	annars redovisa bieffekten. Arkitekturen tillåter det inte, så
	bieffekten redovisas — OCH begränsas så långt den går: de gamla
	värdena sparas och LÄMNAS TILLBAKA när lektionen slutar. En spelare
	som inte rider får alltså exakt den bubbelräckvidd hon hade.

	Kvar som verklig bieffekt: under en lektion syns andra spelares
	bubblor längre bort än vanligt på DEN HÄR klienten. Ridhuset är stort
	och glest, avståndet är räknat på banan och inte på hela anläggningen,
	och effekten är lokal — men den är verklig och står därför här i
	stället för i en commit-rad.

	── VAD DEN INTE GÖR ─────────────────────────────────────────────────

	Ingen `TextChannel`, ingen `SendAsync`, inget serveranrop. Bubblan är
	ren presentation på den egna klienten: ingen annan spelare ser Ugnetas
	replik, och ingenting av det här kan skriva världssanning.

	── VARFÖR INTE "RÖSTEN" ─────────────────────────────────────────────

	Första rubriken kallade det hon säger för en talande stämma, och
	`tools/rostgrind.mjs` fällde den. Grinden håller Tobias produktbeslut 2026-09-10: **ingen röst
	får agera ridlärare**, och den letar bland annat efter mönstret
	`ugneta…röst`. Dess kommentarstrippning kan JavaScript men inte Luau, så
	den läste rubriken som kod.

	Ordet är bytt, inte grinden. Modulen har ingen ljuduppspelning alls —
	den skriver text i en bubbla och i en logg — men "rösten" är en metafor
	som kolliderar med ett låst produktbeslut, och ett låst beslut ska
	vinna över en rubrik. Att i stället lära strippningen Luau hade varit
	att försvaga en produktlås-grind i en PR som inte handlar om den.
	[REVIEW] Om strippningen BÖR lära sig Luau är det ett eget beslut.
]]

local GuiService = game:GetService("GuiService")
local TextChatService = game:GetService("TextChatService")

local TouchControls = require(script.Parent.TouchControls)
local UgnetaTema = require(game:GetService("ReplicatedStorage").HorseCore.UgnetaTema)

local UgnetaBubbla = {}

--[[ Bubblans utseende. Ur ART_STYLE:s tokens, så att hon låter som spelet
     ser ut: krämvit botten, mörk lila text. ]]
local BUBBEL_BAK = Color3.fromRGB(245, 239, 224)     -- --cream
local BUBBEL_TEXT = Color3.fromRGB(46, 34, 62)
local BUBBEL_SEK = 6
local BUBBEL_TEXTSTORLEK = 18

--[[ ── RESERVLOGGEN ───────────────────────────────────────────────────
     Tre rader som mest, uppe i VÄNSTERBANDET. Bandet är valt och inte
     hittat: `TouchControls` blickyta börjar på 34 % av bredden, alltså är
     vänstra tredjedelen det enda som varken kameran eller gångarts-
     knapparna gör anspråk på. Loggen ligger dessutom UNDER bannern
     (`CoachBanner.TOPP + HOJD`) och OVANFÖR spaken
     (`TouchControls.spakTopp`). ]]
local LOGG_X = 10
local LOGG_Y0 = 110                                  -- under bannerns 48 + 52
--[[ Bandets högerkant som andel av bredden. 0,34 är inte valt — det är
     där `TouchControls` blickyta BÖRJAR (`Position = fromScale(0.34, 0)`),
     alltså exakt den gräns kameran gör anspråk på. ]]
local LOGG_ANDEL = 0.34
--[[ Smalast läsbara logg. UNDER den ritas ingen alls, och det är avsiktligt
     ett nej och inte en krympning: en rad på 90 px rymmer fyra tecken och
     en ellips, vilket är sämre än ingen rad.

     Talet var först ett GOLV på bredden, och det var fel håll. Provet mätte
     loggen till x 10..296 på en iPhone 13 i landskap, där bandet slutar på
     287 — golvet sköt alltså ut den i kameraytan för att den skulle "få
     plats". Nu är bandet taket och golvet ett villkor. ]]
local LOGG_MIN_B = 110
local LOGG_MAX_B = 300
local RAD_HOJD = 18
local RAD_GAP = 4
local MAX_RADER = 3
local RAD_SEK = 12                                   -- hur länge en rad står kvar

UgnetaBubbla.MAX_RADER = MAX_RADER
UgnetaBubbla.RAD_SEK = RAD_SEK
UgnetaBubbla.LOGG_Y0 = LOGG_Y0

export type Logglayout = { x: number, y: number, bredd: number,
	rader: number, hojd: number }

--[[ ── DEN RENA RÄKNINGEN ──────────────────────────────────────────────
     Ingen Instance, inga beroenden — samma disciplin som
     `CoachBanner.bredden` och `PostRideSummary.layout`. `spakTopp` är
     `math.huge` på en klient utan pekreglage.

     Räknat på kanonens provskärmar (GUI-yta = viewport minus topbarens
     36 px):

         1920x1044  PC              spaken saknas    3 rader, 300 px bred
         1376x 996  iPad Pro        spaken 828       3 rader, 300 px
          844x 354  iPhone 13 lands spaken 209       3 rader, 277 px
          568x 284  liten telefon   spaken 168       2 rader, 183 px
          390x 808  iPhone portratt spaken 646       3 rader, 122 px

     Den sista raden är hela skälet till att antalet räknas i stället för
     att antas: tre rader hade nått 172 px och lagt sig över spakens
     överkant på 168. ]]
function UgnetaBubbla.loggLayout(W: number, H: number, spakTopp: number): Logglayout
	local w = math.max(0, W)
	local h = math.max(0, H)
	--[[ BREDDEN ÄR BANDET, inte en andel som får svämma över det. ]]
	local bredd = math.min(LOGG_ANDEL * w - LOGG_X, LOGG_MAX_B)
	local golv = math.min(if type(spakTopp) == "number" then spakTopp else math.huge, h)
	local ledigt = (golv - 10) - LOGG_Y0
	local rader = math.floor((ledigt + RAD_GAP) / (RAD_HOJD + RAD_GAP))
	rader = math.clamp(rader, 0, MAX_RADER)
	--[[ För smalt band = ingen logg. Se noten vid `LOGG_MIN_B`. ]]
	if bredd < LOGG_MIN_B then
		bredd = 0
		rader = 0
	end
	return {
		x = LOGG_X,
		y = LOGG_Y0,
		bredd = math.floor(bredd),
		rader = rader,
		hojd = if rader > 0 then rader * RAD_HOJD + (rader - 1) * RAD_GAP else 0,
	}
end

--[[ ── TILLSTÅNDET ───────────────────────────────────────────────────── ]]
local forlader: Instance? = nil
local loggRam: Frame? = nil
local loggRader: { TextLabel } = {}
local ytsignal: RBXScriptConnection? = nil
--[[ Posterna: nyast först. Tiden räknas ned i `steg`, i klientens enda
     loop — ingen `task.delay`, av exakt samma skäl som `CoachBanner` har
     (se dess modulhuvud och `tools/kolla-nederpanel.py`). ]]
local poster: { { text: string, kvar: number } } = {}
local synligaRader = 0

--[[ Bubbelkonfigurationens ursprungliga värden, sparade vid första
     lektionen och återlämnade när sista lektionen slutar. `nil` betyder
     "inte rörd ännu". ]]
local sparat: { [string]: any }? = nil

local function konfiguration(): Instance?
	--[[ `BubbleChatConfiguration` är `NotCreatable` och skapas av motorn.
	     `FindFirstChildOfClass` och inte `WaitForChild`: en klient som
	     körs med LegacyChatService har ingen, och undervisningen ska då
	     degraderas till loggen — inte blockeras i en väntan. ]]
	local ok, k = pcall(function()
		return (TextChatService :: any):FindFirstChildOfClass("BubbleChatConfiguration")
	end)
	if ok and k then return k end
	return nil
end

--[[ Sätter räckvidden och utseendet. Idempotent: ett andra anrop sparar
     inte om de redan sparade värdena — annars hade den andra lektionen
     "sparat" den första lektionens inställningar som original. ]]
function UgnetaBubbla.konfigurera(): boolean
	local k = konfiguration()
	if not k then return false end
	local c = k :: any
	if not sparat then
		sparat = {
			Enabled = c.Enabled,
			MaxDistance = c.MaxDistance,
			MinimizeDistance = c.MinimizeDistance,
			BackgroundColor3 = c.BackgroundColor3,
			TextColor3 = c.TextColor3,
			TextSize = c.TextSize,
			BubbleDuration = c.BubbleDuration,
		}
	end
	--[[ `Enabled` är FALSKT som standard i Roblox. Utan raden ritas ingen
	     bubbla alls, och §4 hade varit tyst grön. ]]
	c.Enabled = true
	c.MaxDistance = UgnetaTema.BUBBEL_AVSTAND
	--[[ Minimeringen MÅSTE följa med. Bortom `MinimizeDistance` (40 studs
	     som standard) ritar Roblox bubblan som en ensam ellips — en höjd
	     `MaxDistance` ensam hade gett en läsbar räckvidd på 40 studs och
	     en prick på resten av banan. ]]
	c.MinimizeDistance = UgnetaTema.BUBBEL_MINIMERING
	c.BackgroundColor3 = BUBBEL_BAK
	c.TextColor3 = BUBBEL_TEXT
	c.TextSize = BUBBEL_TEXTSTORLEK
	c.BubbleDuration = BUBBEL_SEK
	return true
end

--[[ Lämnar tillbaka det som var. Den här raden är vad som gör den globala
     bieffekten LEKTIONSLÅNG i stället för sessionslång. ]]
function UgnetaBubbla.aterstall()
	local s = sparat
	if not s then return end
	local k = konfiguration()
	if k then
		local c = k :: any
		for namn, varde in s do
			if varde ~= nil then c[namn] = varde end
		end
	end
	sparat = nil
end

--[[ Provets fönster in: vad står i konfigurationen just nu? ]]
function UgnetaBubbla.installning(): { [string]: any }?
	local k = konfiguration()
	if not k then return nil end
	local c = k :: any
	return {
		Enabled = c.Enabled,
		MaxDistance = c.MaxDistance,
		MinimizeDistance = c.MinimizeDistance,
	}
end

--[[ ── LOGGEN ────────────────────────────────────────────────────────── ]]
local function laggUt()
	local r = loggRam
	if not r then return end
	local f = forlader :: any
	local W = if f and f.AbsoluteSize then f.AbsoluteSize.X else 0
	local H = if f and f.AbsoluteSize then f.AbsoluteSize.Y else 0
	if W <= 0 or H <= 0 then return end
	local L = UgnetaBubbla.loggLayout(W, H, TouchControls.spakTopp())
	synligaRader = L.rader
	r.Position = UDim2.new(0, L.x, 0, L.y)
	r.Size = UDim2.new(0, L.bredd, 0, math.max(0, L.hojd))
	r.Visible = L.rader > 0 and #poster > 0
	for i, etikett in loggRader do
		etikett.Visible = i <= L.rader and poster[i] ~= nil
	end
end

function UgnetaBubbla._laggUt()
	laggUt()
end

local function rita()
	for i, etikett in loggRader do
		local post = poster[i]
		if post and i <= synligaRader then
			etikett.Text = post.text
			etikett.Visible = true
		else
			etikett.Text = ""
			etikett.Visible = false
		end
	end
	local r = loggRam
	if r then r.Visible = synligaRader > 0 and #poster > 0 end
end

--[[ Monterar loggen i lektionens befintliga yta. Som `CoachBanner`:
     ingen egen ScreenGui, och ett andra anrop med samma förälder är en
     no-op. ]]
function UgnetaBubbla.montera(mor: Instance?)
	if not mor then return end
	if loggRam and forlader == mor then return end
	UgnetaBubbla.Destroy()
	forlader = mor

	local r = Instance.new("Frame")
	r.Name = "UgnetaLogg"
	r.AnchorPoint = Vector2.new(0, 0)
	r.Position = UDim2.new(0, LOGG_X, 0, LOGG_Y0)
	r.Size = UDim2.new(0, LOGG_MIN_B, 0, RAD_HOJD)
	r.BackgroundTransparency = 1
	r.BorderSizePixel = 0
	--[[ Loggen tar ALDRIG emot input. Den är en avläsning, och en osynlig
	     yta över vänsterbandet hade kunnat äta ett tumnedslag. ]]
	r.Active = false
	r.Visible = false
	r.ZIndex = 4
	local lista = Instance.new("UIListLayout")
	lista.FillDirection = Enum.FillDirection.Vertical
	lista.SortOrder = Enum.SortOrder.LayoutOrder
	lista.HorizontalAlignment = Enum.HorizontalAlignment.Left
	lista.Padding = UDim.new(0, RAD_GAP)
	lista.Parent = r
	r.Parent = mor
	loggRam = r
	table.clear(loggRader)
	for i = 1, MAX_RADER do
		local l = Instance.new("TextLabel")
		l.Name = "Replik" .. i
		l.LayoutOrder = i
		l.Size = UDim2.new(1, 0, 0, RAD_HOJD)
		l.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
		--[[ Diskret: nästan genomskinlig platta, ljus text. Den ska gå att
		     läsa när man tittar dit och glömmas bort när man inte gör det. ]]
		l.BackgroundTransparency = 0.45
		l.TextColor3 = Color3.fromRGB(246, 242, 232)
		l.Font = Enum.Font.Gotham
		l.TextSize = 12
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.TextWrapped = false
		l.TextTruncate = Enum.TextTruncate.AtEnd
		l.RichText = false
		l.Text = ""
		l.Visible = false
		l.ZIndex = 4
		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, 8)
		pad.PaddingRight = UDim.new(0, 8)
		pad.Parent = l
		local horn = Instance.new("UICorner")
		horn.CornerRadius = UDim.new(0, 6)
		horn.Parent = l
		l.Parent = r
		table.insert(loggRader, l)
	end

	local f = mor :: any
	if f.GetPropertyChangedSignal then
		ytsignal = f:GetPropertyChangedSignal("AbsoluteSize"):Connect(laggUt)
	end
	laggUt()
end

--[[ ── REPLIKEN ────────────────────────────────────────────────────────

	EN replik, TVÅ ytor. Returnerar om bubblan faktiskt gick fram; loggen
	får raden oavsett, och det är hela poängen med en reservlogg — en
	klient utan bubbelchatt ska fortfarande kunna läsa vad hon sa.

	`del` är den del i gestalten bubblan ska hänga över. Saknas gestalten
	(hon placeras bara när ridbanan är byggd) blir det bara loggen. ]]
function UgnetaBubbla.sag(text: string?, del: Instance?): boolean
	local t = if type(text) == "string" then text else ""
	if t == "" then return false end

	table.insert(poster, 1, { text = t, kvar = RAD_SEK })
	while #poster > MAX_RADER do table.remove(poster) end
	laggUt()
	rita()

	if not del then return false end
	local ok = pcall(function()
		(TextChatService :: any):DisplayBubble(del, t)
	end)
	return ok
end

--[[ ETT STEG. Anropas ur klientens enda uppdateringsloop via
     `UgnetaController.steg`. Det är här raderna åldras. ]]
function UgnetaBubbla.steg(dt: number)
	if #poster == 0 then return end
	local d = if type(dt) == "number" and dt > 0 then dt else 0
	local i = #poster
	local andrat = false
	while i >= 1 do
		poster[i].kvar -= d
		if poster[i].kvar <= 0 then
			table.remove(poster, i)
			andrat = true
		end
		i -= 1
	end
	if andrat then rita() end
end

--[[ Tömmer loggen. Säkerhetsvägen: en replik om en häst spelaren inte
     sitter på längre ska inte bli stående. ]]
function UgnetaBubbla.rensa()
	table.clear(poster)
	rita()
	local r = loggRam
	if r then r.Visible = false end
end

function UgnetaBubbla.Destroy()
	local s = ytsignal
	if s then s:Disconnect() end
	ytsignal = nil
	local r = loggRam
	if r then r:Destroy() end
	loggRam = nil
	table.clear(loggRader)
	table.clear(poster)
	forlader = nil
	synligaRader = 0
end

--[[ ── PROVETS AVLÄSNINGAR ───────────────────────────────────────────── ]]

function UgnetaBubbla.rader(): { string }
	local ut = {}
	for _, p in poster do table.insert(ut, p.text) end
	return ut
end

function UgnetaBubbla.ram(): Frame?
	return loggRam
end

--[[ Reducerad rörelse rör inte loggen: den tonar inte, den byter text.
     Funktionen finns för att provet ska kunna visa just det. ]]
function UgnetaBubbla.reducerRorelse(): boolean
	return (GuiService :: any).ReducedMotionEnabled == true
end

return UgnetaBubbla
