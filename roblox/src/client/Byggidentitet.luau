--!strict
--[[
	VILKEN BUILD SITTER JAG I? — läsbar för ett vanligt spelarkonto.

	Problemet kommer ur #263. Fysisk QA på iPad kan inte genomföras
	meningsfullt förrän testaren kan se VILKEN build enheten kör. De två
	vägar som fanns räcker inte:

	  · `kallhash` läst ur Studios VM bevisar vad STUDIO kör, inte vad
	    en publicerad server skickar till en iPad,
	  · `FIRST_PLAYABLE_PREFLIGHT: PASS` skrivs på SERVERN, och
	    utvecklarkonsolens serverflik visas bara för den som äger placen
	    eller har team create. Ett separat testkonto ser en tom flik.

	Den här modulen stänger hålet på den enda yta som är öppen för alla:
	klienten. `ReplicatedStorage.UBRFBuild` REPLIKERAS, så identiteten
	finns redan hos varje spelare — ingen har behövt se den.

	── VAD DEN INTE ÄR ──────────────────────────────────────────────

	Den är en LÄSARE, inte en sanning. Den skapar ingen ny version, ber
	inte servern om något, och har inget eget remote. Finns identiteten
	inte, eller går den inte att läsa, står det **okänd** — aldrig ett
	standardvärde som ser matchat ut. En felaktig grön rad vore värre än
	ingen rad alls: den skulle få en QA-omgång att tro att fel build var
	rätt.

	`sha` VISAS INTE som den körande buildens commit. Fältet finns i
	identiteten men släpar per konstruktion — en committad fil kan inte
	känna sitt eget commit-SHA. `UBRFBuild.luau`:s eget filhuvud säger
	"gissa aldrig på det", och #263 upprepar förbudet. `kallhash` är den
	som går att räkna om och jämföra exakt, och det är den vyn vilar på.

	── VARFÖR EGEN KNAPP OCH INTE HJÄLPPANELEN ──────────────────────

	`KontrollHjalp` hade varit den naturliga platsen: den har redan en
	permanent knapp, tre vägar in och en färdig undanvikning för
	pekreglagen. Men den är SLÄCKT — `MINIMAL_UI = true`, PO-beslutet i
	#182 om en helt ren skärm. Att tända den för att lösa ett QA-problem
	vore att riva ett produktbeslut, så identiteten får en egen liten yta
	i stället. Den lyder alltså inte under `MINIMAL_UI`: den är inte
	spelyta, den är det som gör spelytan verifierbar.

	── PLACERING ────────────────────────────────────────────────────

	Uppe till höger, UNDER hjälpknappens band. Hörnet är ledigt i dag
	eftersom `?` är släckt, men knappen skriver inte in sig i det: den
	börjar ett knappband ned, så att `?` kan tändas igen utan att de två
	hamnar på varandra. Ingen befintlig yta flyttas.

	Och den viker undan för pekreglagen av samma skäl som `?` gör det,
	genom samma publika kontrakt — `TouchControls.reglageBredd()` och
	`reglageTopp()`, rapporterade via `efterLayout`. Talen skrivs inte
	av; de kommer ur reglagens egen layout. Se `klient-reservzon.spec`.

	Mätt i `klient-byggidentitet.spec`.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Sprak = require(ReplicatedStorage.HorseCore.Sprak)

local Byggidentitet = {}

local player = Players.LocalPlayer

local knappGui: ScreenGui? = nil
local knapp: TextButton? = nil
local panelGui: ScreenGui? = nil
local panel: Frame? = nil
local radLabels: { TextLabel } = {}
local hashKort = true

local FARG_MORK = Color3.fromRGB(12, 14, 18)
local FARG_TEXT = Color3.fromRGB(246, 242, 232)
local FARG_DIM = Color3.fromRGB(150, 152, 158)
local FARG_GULD = Color3.fromRGB(232, 181, 74)

--[[ 44 px är golvet i `docs/KONTROLLMATRIS.md` regel 5 för varje knapp
	spelaren måste kunna nå. Hjälpknappen är 48; den här är avsiktligt
	mindre — den ska vara diskret — men går inte under golvet. ]]
local KNAPPSTORLEK = 44
local KNAPPMARGINAL = 12
--[[ Hjälpknappens band, så att `?` kan tändas igen utan kollision. ]]
local HJALPBAND = 12 + 48

--[[ ══ IDENTITETEN ══════════════════════════════════════════════════

	Fail closed på varje steg, precis som `Integritet.identitet` på
	servern: saknas modulen, är den fel klass, eller kastar `require`
	så är svaret `nil`. Ingen tom tabell — en tom tabell hade sett ut
	som en läst identitet utan innehåll. ]]
function Byggidentitet.identitet(): { [string]: any }?
	local m = ReplicatedStorage:FindFirstChild("UBRFBuild")
	if m == nil or not m:IsA("ModuleScript") then return nil end
	local ok, data = pcall(require, m :: any)
	if not ok or typeof(data) ~= "table" then return nil end
	return data :: any
end

local function okand(): string
	return Sprak.t("bygg.okand")
end

--[[ En sträng ur identiteten, eller "okänd". Tomma strängar räknas som
	saknade: ett fält som finns men är tomt bevisar ingenting. ]]
local function text(id: { [string]: any }?, falt: string): string
	if id == nil then return okand() end
	local v = id[falt]
	if typeof(v) ~= "string" or v == "" then return okand() end
	return v
end

local function tal(id: { [string]: any }?, falt: string): string
	if id == nil then return okand() end
	local v = id[falt]
	if typeof(v) ~= "number" then return okand() end
	return tostring(v)
end

--[[ Hashen i två former. Kort är de tolv första tecknen — nog för att
	jämföra mot en rapport i förbifarten, och det minimum #263 begär.
	Hela värdet är ett tryck bort; QA ska kunna läsa av alla 64 utan att
	behöva utvecklarrättigheter. Har hashen fel form visas den som okänd
	i stället för att en trasig sträng får se ut som en identitet. ]]
function Byggidentitet.hash(kort: boolean): string
	local id = Byggidentitet.identitet()
	local h = id and id.kallhash
	if typeof(h) ~= "string" then return okand() end
	if #h ~= 64 or h:match("^%x+$") == nil then return okand() end
	return if kort then h:sub(1, 12) else h
end

--[[ ══ VAR KÖR JAG? ═══════════════════════════════════════════════

	Tre `DataModel`-egenskaper plus ett `RunService`-anrop. Alla fyra är
	uppslagna i den officiella referensen innan de skrevs — #263 förbjuder
	gissade fältnamn, och det är ett befogat förbud: ett påhittat fält
	hade blivit `nil` och därmed sett ut som "okänd identitet" i stället
	för som en bugg i den här filen.

	  `game.PlaceId`       int64, läsbar utan rättigheter
	                       DataModel.yaml:251
	  `game.PlaceVersion`  int. "This property is 0 for all unpublished
	                       experiences." Referensen rekommenderar rakt ut
	                       just det här bruket: "can be used to display a
	                       ScreenGui showing the current version of the
	                       game to Players to assist with debugging."
	                       DataModel.yaml:283
	  `game.JobId`         string, "Defaults to an empty string in
	                       Studio." DataModel.yaml:165
	  `RunService:IsStudio()`  security None, alltså anropbar från en
	                       LocalScript. DataModel:IsEdit går INTE — den
	                       kräver PluginSecurity. RunService.yaml:578

	VARFÖR BÅDE VERSION OCH `IsStudio`: version 0 betyder "opublicerad"
	enligt referensen, men 0 ensamt säger inte VARFÖR. `IsStudio` skiljer
	Studio från en publicerad server, och det är precis den skillnad
	iPad-testet står och faller med.

	Alla läses defensivt med typtest. En egenskap som saknas ger "okänd",
	aldrig en nolla som ser ut som ett svar. ]]
local function placeId(): string
	local v = (game :: any).PlaceId
	if typeof(v) ~= "number" then return okand() end
	return ("%d"):format(v)
end

local function arStudio(): boolean
	local f = (RunService :: any).IsStudio
	if type(f) ~= "function" then return false end
	return f(RunService) == true
end

--[[ Versionen, eller varför den inte finns. Tre utfall och inget tyst
	fjärde: ett tal, "opublicerad" när motorn säger 0, och "okänd" när
	egenskapen inte går att läsa alls. ]]
local function placeVersion(): string
	local v = (game :: any).PlaceVersion
	if typeof(v) ~= "number" then return okand() end
	if v == 0 then return Sprak.t("bygg.opublicerad") end
	return ("%d"):format(v)
end

--[[ Miljön: Studio eller publicerad server. `JobId` läggs till när den
	finns — den namnger den enskilda serverinstansen, vilket är det som
	skiljer två samtidiga sessioner åt. Tom sträng betyder Studio enligt
	referensen, och då skriver vi inte ut den. ]]
local function miljo(): string
	local namn = if arStudio() then Sprak.t("bygg.studio")
		else Sprak.t("bygg.server")
	local j = (game :: any).JobId
	if typeof(j) == "string" and j ~= "" then
		return ("%s · %s"):format(namn, j:sub(1, 8))
	end
	return namn
end

export type Rad = { nyckel: string, varde: string }

--[[ Raderna som REN DATA, utan GUI. Provet mäter innehållet här och
	ritningen separat — annars hade en tom panel och en felaktig rad
	sett likadana ut i mätningen. ]]
function Byggidentitet.rader(): { Rad }
	local id = Byggidentitet.identitet()
	return {
		{ nyckel = "bygg.kallhash", varde = Byggidentitet.hash(hashKort) },
		{ nyckel = "bygg.kallor", varde = tal(id, "kallor") },
		{ nyckel = "bygg.lage", varde = text(id, "lage") },
		{ nyckel = "bygg.genererad", varde = text(id, "genererad") },
		{ nyckel = "bygg.plats", varde = placeId() },
		{ nyckel = "bygg.version", varde = placeVersion() },
		{ nyckel = "bygg.miljo", varde = miljo() },
	}
end

--[[ ══ RITNINGEN ════════════════════════════════════════════════════

	Ingen egen insetsräkning här. Båda ytorna har `IgnoreGuiInset =
	false`, så motorn lägger dem under topbaren åt oss — samma val som
	hjälpknappen. Provet räknar inseten själv när det översätter
	GUI-pixlar till skärmpixlar. ]]

--[[ Ridreserven, som `TouchControls` senast rapporterade den. Samma två
	tal `KontrollHjalp` viker undan för, lästa genom samma kontrakt.
	Noll och oändligt när pekreglagen inte är uppe. ]]
local reservBredd = 0
local reservTopp = math.huge

--[[ Knappens band: under hjälpknappens, så att `?` kan tändas igen utan
	att de två hamnar på varandra. Viker undan i sidled när reserven når
	upp i bandet — ren geometri, inget enhetsvillkor. ]]
local function placera()
	local b = knapp
	if b == nil then return end
	local topp = HJALPBAND + KNAPPMARGINAL
	local botten = topp + KNAPPSTORLEK
	if reservBredd > 0 and reservTopp < botten then
		b.Position = UDim2.new(1, -(reservBredd + KNAPPMARGINAL), 0, topp)
	else
		b.Position = UDim2.new(1, -KNAPPMARGINAL, 0, topp)
	end
end

--[[ Anropas av `TouchControls` genom `init.client`, i samma andetag som
	reglagen byggs, byggs om eller rivs. ]]
function Byggidentitet.reservAndrad(bredd: number, topp: number)
	reservBredd, reservTopp = bredd, topp
	placera()
end

--[[ Panelens mått, och HELA höjdbudgeten utskriven — för den är trång
	och gick sönder en gång.

	Den minsta skärm klienten mäts på är 568×320 i landskap. Topbaren
	tar 36, alltså finns 284 GUI-pixlar. Panelen börjar vid
	`KNAPPMARGINAL`, så den får vara högst 284 − 12 = 272 hög.

	    rubrik            28
	    7 rader à 24     168
	    stängknappen      44   (44 är golvet, KONTROLLMATRIS regel 5)
	    padding 10 × 2    20
	    ────────────────────
	    summa            260   ≤ 272, tolv pixlar över

	Första försöket hade 26-pixelsrader och 12 i padding och landade på
	280 — åtta pixlar utanför skärmen på just den telefonen. Provet
	fångade det, inte jag. Höjden RÄKNAS därför ur radantalet i stället
	för att skrivas som en konstant: en åttonde rad skjuter ut
	underkanten, och då faller `klient-byggidentitet.spec` i stället för
	att raden tyst hamnar utanför bilden på den enhet QA sitter med. ]]
local PANELBREDD = 340
local RAD_HOJD = 24
local RUBRIK_HOJD = 28
local STANG_HOJD = 44
local PANELPADDING = 10

local function panelHojd(antalRader: number): number
	return RUBRIK_HOJD + antalRader * RAD_HOJD + STANG_HOJD + PANELPADDING * 2
end

--[[ Knappen göms medan panelen står uppe: panelen har sin egen «Stäng»,
	och två reglage för samma sak samtidigt är en fråga, inte en hjälp.
	Samma regel som `KontrollHjalp.speglaOppna`. ]]
local function speglaKnapp()
	local b = knapp
	if b ~= nil then b.Visible = not Byggidentitet.synlig() end
end

function Byggidentitet.synlig(): boolean
	local g = panelGui
	return g ~= nil and g.Enabled == true
end

--[[ En rad: etikett till vänster, värde till höger. Två labels och inte
	en sammanslagen sträng — provet ska kunna läsa VÄRDET utan att tolka
	en formatering, och en etikett som saknar översättning ska synas som
	en tom etikett, inte gömmas mitt i en rad. ]]
local function byggRad(foralder: Frame, index: number): TextLabel
	local rad = Instance.new("Frame")
	rad.Name = ("Rad%d"):format(index)
	rad.BackgroundTransparency = 1
	rad.Size = UDim2.new(1, 0, 0, RAD_HOJD)
	rad.Position = UDim2.new(0, 0, 0, RUBRIK_HOJD + (index - 1) * RAD_HOJD)
	rad.Parent = foralder

	local etikett = Instance.new("TextLabel")
	etikett.Name = "Etikett"
	etikett.BackgroundTransparency = 1
	etikett.Size = UDim2.new(0.38, 0, 1, 0)
	etikett.TextColor3 = FARG_DIM
	etikett.Font = Enum.Font.Gotham
	etikett.TextSize = 13
	etikett.TextXAlignment = Enum.TextXAlignment.Left
	etikett.Text = ""
	etikett.Parent = rad

	local varde = Instance.new("TextLabel")
	varde.Name = "Varde"
	varde.BackgroundTransparency = 1
	varde.Size = UDim2.new(0.62, 0, 1, 0)
	varde.Position = UDim2.new(0.38, 0, 0, 0)
	varde.TextColor3 = FARG_TEXT
	--[[ `Code` för att en hash ska gå att läsa av tecken för tecken:
		nollan och O, ettan och l. QA jämför den mot en rapport. ]]
	varde.Font = Enum.Font.Code
	varde.TextSize = 13
	varde.TextXAlignment = Enum.TextXAlignment.Left
	varde.TextTruncate = Enum.TextTruncate.None
	varde.TextWrapped = true
	varde.Text = ""
	varde.Parent = rad
	return varde
end

local function byggPanel()
	if panelGui ~= nil then return end
	local rader = Byggidentitet.rader()

	local g = Instance.new("ScreenGui")
	g.Name = "UBRFByggidentitet"
	--[[ Överlever respawn. Utan den byggs en andra panel vid varje
		återuppståndelse, och `start` hade inte sett den — vakten ovan
		läser vår egen referens, inte PlayerGui. ]]
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = false
	--[[ Över hjälpknappen (16) och hjälppanelen (15), under ridanalysen
		(20): identiteten ska gå att läsa medan hjälpen ligger uppe, men
		aldrig skymma en pågående ridanalys. ]]
	g.DisplayOrder = 18
	--[[ STÄNGD SOM UTGÅNGSLÄGE, och släckt på ScreenGui-nivå. Det är
		skillnaden mot en osynlig ram: en släckt `ScreenGui` tar inga
		träffar alls, så panelen kan inte fånga styrning när den är
		stängd. Kravet står i #263. ]]
	g.Enabled = false
	g.Parent = player:WaitForChild("PlayerGui")
	panelGui = g

	--[[ NAMNEN ÄR NAMNRYMDADE, och det är inte kosmetik. `PlayerGui` är
		EN trädrymd som alla klientytor delar, och flera specar letar i
		den med ett rent namnuppslag — `hitta("Stang")`, `hitta("Rubrik")`.
		Mina första namn var just `Panel`, `Rubrik` och `Stang`, och då
		svarade min stängknapp på `klient.spec`:s uppslag av ridanalysens.
		Tre mätningar blev röda av en knapp som inte hade med dem att
		göra. `KontrollHjalp` lärde sig samma sak före mig och heter
		därför `StangHjalp`. ]]
	local p = Instance.new("Frame")
	p.Name = "PanelBygg"
	p.AnchorPoint = Vector2.new(1, 0)
	p.Position = UDim2.new(1, -KNAPPMARGINAL, 0, KNAPPMARGINAL)
	p.Size = UDim2.fromOffset(PANELBREDD, panelHojd(#rader))
	p.BackgroundColor3 = FARG_MORK
	p.BackgroundTransparency = 0.06
	p.BorderSizePixel = 0
	p.Parent = g
	local horn = Instance.new("UICorner")
	horn.CornerRadius = UDim.new(0, 10)
	horn.Parent = p
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, PANELPADDING)
	padding.PaddingRight = UDim.new(0, PANELPADDING)
	padding.PaddingTop = UDim.new(0, PANELPADDING)
	padding.PaddingBottom = UDim.new(0, PANELPADDING)
	padding.Parent = p
	panel = p

	local rubrik = Instance.new("TextLabel")
	rubrik.Name = "RubrikBygg"
	rubrik.BackgroundTransparency = 1
	rubrik.Size = UDim2.new(1, 0, 0, RUBRIK_HOJD)
	rubrik.TextColor3 = FARG_GULD
	rubrik.Font = Enum.Font.GothamBold
	rubrik.TextSize = 16
	rubrik.TextXAlignment = Enum.TextXAlignment.Left
	rubrik.Text = Sprak.t("bygg.rubrik")
	rubrik.Parent = p

	radLabels = {}
	for i = 1, #rader do
		table.insert(radLabels, byggRad(p, i))
	end
	--[[ HELA HASHEN ÄR ETT TRYCK BORT. Raden är själv knappen: 64 tecken
		får inte plats bredvid en etikett på en telefon, och QA måste ändå
		kunna läsa av alla. Träffytan är hela radens bredd. ]]
	local hashKnapp = Instance.new("TextButton")
	hashKnapp.Name = "HashVaxel"
	hashKnapp.BackgroundTransparency = 1
	hashKnapp.Text = ""
	hashKnapp.Size = UDim2.new(1, 0, 0, RAD_HOJD)
	hashKnapp.Position = UDim2.new(0, 0, 0, RUBRIK_HOJD)
	hashKnapp.ZIndex = 2
	hashKnapp.Parent = p
	hashKnapp.Activated:Connect(function()
		hashKort = not hashKort
		Byggidentitet.rita()
	end)

	local stang = Instance.new("TextButton")
	stang.Name = "StangBygg"
	stang.AnchorPoint = Vector2.new(1, 1)
	stang.Position = UDim2.new(1, 0, 1, 0)
	--[[ 44 px hög: golvet i KONTROLLMATRIS regel 5. En stängknapp som
		inte går att träffa gör panelen till en engångsruta — exakt det
		fel #153 rapporterade som P2-4b. ]]
	stang.Size = UDim2.fromOffset(96, 44)
	stang.BackgroundColor3 = FARG_GULD
	stang.TextColor3 = FARG_MORK
	stang.Font = Enum.Font.GothamBold
	stang.TextSize = 14
	stang.Text = Sprak.t("bygg.stang")
	stang.BorderSizePixel = 0
	stang.Parent = p
	local sh = Instance.new("UICorner")
	sh.CornerRadius = UDim.new(0, 8)
	sh.Parent = stang
	stang.Activated:Connect(function() Byggidentitet.dolj() end)
end

--[[ Skriver om raderna ur `rader()`. Skild från bygget så att språkbyte
	och hashväxling går genom EN väg — samma skäl som `KontrollHjalp`
	skiljer ritning från konstruktion. ]]
function Byggidentitet.rita()
	local p = panel
	if p == nil then return end
	local rader = Byggidentitet.rader()
	for i, label in ipairs(radLabels) do
		local r = rader[i]
		if r == nil then
			label.Text = ""
			local far = label.Parent
			if far ~= nil then
				local e = far:FindFirstChild("Etikett")
				if e ~= nil and e:IsA("TextLabel") then e.Text = "" end
			end
		else
			label.Text = r.varde
			local far = label.Parent
			if far ~= nil then
				local e = far:FindFirstChild("Etikett")
				if e ~= nil and e:IsA("TextLabel") then e.Text = Sprak.t(r.nyckel) end
			end
		end
	end
	local rubrik = p:FindFirstChild("RubrikBygg")
	if rubrik ~= nil and rubrik:IsA("TextLabel") then
		rubrik.Text = Sprak.t("bygg.rubrik")
	end
	local stang = p:FindFirstChild("StangBygg")
	if stang ~= nil and stang:IsA("TextButton") then
		stang.Text = Sprak.t("bygg.stang")
	end
end

function Byggidentitet.visa()
	byggPanel()
	local g = panelGui
	if g ~= nil then g.Enabled = true end
	Byggidentitet.rita()
	speglaKnapp()
end

function Byggidentitet.dolj()
	local g = panelGui
	if g ~= nil then g.Enabled = false end
	--[[ Hashen fälls ihop igen. Nästa öppning börjar i samma läge för
		alla, så att en skärmbild ur QA går att jämföra med nästa. ]]
	hashKort = true
	speglaKnapp()
end

function Byggidentitet.vaxla()
	if Byggidentitet.synlig() then Byggidentitet.dolj() else Byggidentitet.visa() end
end

local function byggKnapp()
	if knappGui ~= nil then return end
	local g = Instance.new("ScreenGui")
	g.Name = "UBRFByggidentitetKnapp"
	g.ResetOnSpawn = false
	--[[ `false`: knappen lägger sig UNDER topbaren i stället för bakom
		den. Samma val som hjälpknappen, av samma skäl. ]]
	g.IgnoreGuiInset = false
	--[[ Över hjälpknappen (16), under panelen (18) och ridanalysen (20). ]]
	g.DisplayOrder = 17
	g.Parent = player:WaitForChild("PlayerGui")
	knappGui = g

	local b = Instance.new("TextButton")
	b.Name = "Byggidentitet"
	b.AnchorPoint = Vector2.new(1, 0)
	b.Size = UDim2.fromOffset(KNAPPSTORLEK, KNAPPSTORLEK)
	b.BackgroundColor3 = FARG_MORK
	--[[ Diskret: mer genomskinlig än hjälpknappens 0.12. Den ska gå att
		hitta när man letar och inte dra blicken när man rider. ]]
	b.BackgroundTransparency = 0.35
	b.TextColor3 = FARG_DIM
	b.Font = Enum.Font.GothamBold
	b.TextSize = 18
	b.Text = "i"
	b.AutoButtonColor = true
	b.BorderSizePixel = 0
	b.Parent = g
	local horn = Instance.new("UICorner")
	horn.CornerRadius = UDim.new(1, 0)
	horn.Parent = b
	b.Activated:Connect(function() Byggidentitet.vaxla() end)
	knapp = b
	placera()
	speglaKnapp()
end

--[[ Byggs vid uppstart och lever hela sessionen, som hjälpknappen.
	Idempotent: två anrop ger en knapp och en panel, inte två. ]]
function Byggidentitet.start()
	byggKnapp()
	byggPanel()
end

--[[ Provets fönster in. Samma mönster som `KontrollHjalp._oppnaKnapp`:
	provet ska mäta DE INSTANSER modulen faktiskt byggde, inte leta upp
	något med samma namn i hierarkin och hoppas att det är rätt. ]]
function Byggidentitet._knapp(): TextButton?
	return knapp
end

function Byggidentitet._panel(): Frame?
	return panel
end

function Byggidentitet._panelGui(): ScreenGui?
	return panelGui
end

--[[ Bara för provet: river ytorna och nollställer modulens state, så att
	nästa block börjar rent. Produktionen anropar den aldrig — knappen
	ska finnas hela sessionen. ]]
function Byggidentitet._nollstallForProv()
	if panelGui ~= nil then panelGui:Destroy() end
	if knappGui ~= nil then knappGui:Destroy() end
	panelGui, panel, knappGui, knapp = nil, nil, nil, nil
	radLabels = {}
	hashKort = true
	reservBredd, reservTopp = 0, math.huge
end

return Byggidentitet
