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
local Net = Core.Networking

local PreparationController = {}

local player = Players.LocalPlayer

local gui: ScreenGui? = nil
local radBehallare: Frame? = nil
local momentBehallare: Frame? = nil
local rubrik: TextLabel? = nil
local hjalp: TextLabel? = nil
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

local FARG_KLAR = Color3.fromRGB(127, 180, 137)
local FARG_TUR = Color3.fromRGB(214, 174, 60)
local FARG_VILAR = Color3.fromRGB(120, 124, 128)
local FARG_FEL = Color3.fromRGB(208, 101, 90)
local FARG_TEXT = Color3.fromRGB(238, 240, 242)

--[[ Golvet för en träffyta. Står som en namngiven konstant för att provet
	ska kunna läsa samma tal som knappen ritas med. ]]
PreparationController.TRAFFYTA = 44

local function bygg()
	if gui then return end
	local g = Instance.new("ScreenGui")
	g.Name = "UBRFForberedelse"
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = true
	g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	g.Parent = player:WaitForChild("PlayerGui")

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	--[[ Skalan är i procent av skärmen med ett tak i pixlar: på en telefon
		får panelen ta 92 % av bredden, på en 4K-skärm ska den inte bli en
		halvmeter bred.

		Höjden växte från 190 till 300 px när momenten kom till: fasraden
		och momentraden ligger under varandra, och en panel som klipper av
		momentlistan hade gjort de sista momenten omöjliga att trycka på. ]]
	panel.Size = UDim2.new(0.92, 0, 0, 300)
	panel.SizeConstraint = Enum.SizeConstraint.RelativeXX
	panel.Position = UDim2.new(0.5, 0, 1, -12)
	panel.AnchorPoint = Vector2.new(0.5, 1)
	panel.BackgroundColor3 = Color3.fromRGB(24, 26, 28)
	panel.BackgroundTransparency = 0.15
	panel.BorderSizePixel = 0
	panel.Parent = g

	local max = Instance.new("UISizeConstraint")
	max.MaxSize = Vector2.new(420, 380)
	max.MinSize = Vector2.new(240, 220)
	max.Parent = panel

	local horn = Instance.new("UICorner")
	horn.CornerRadius = UDim.new(0, 10)
	horn.Parent = panel

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 10)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.PaddingLeft = UDim.new(0, 12)
	pad.PaddingRight = UDim.new(0, 12)
	pad.Parent = panel

	local r = Instance.new("TextLabel")
	r.Name = "Rubrik"
	r.Size = UDim2.new(1, 0, 0, 20)
	r.BackgroundTransparency = 1
	r.Font = Enum.Font.GothamBold
	r.TextSize = 15
	r.TextXAlignment = Enum.TextXAlignment.Left
	r.TextColor3 = FARG_TEXT
	r.Text = "Gör i ordning din häst"
	r.Parent = panel
	rubrik = r

	local lista = Instance.new("Frame")
	lista.Name = "Steg"
	lista.Position = UDim2.new(0, 0, 0, 24)
	lista.Size = UDim2.new(1, 0, 0, 100)
	lista.BackgroundTransparency = 1
	lista.Parent = panel

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, 2)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = lista
	radBehallare = lista

	--[[ Momenten scrollar. Ryktningen har sex och iordningställandet åtta;
		på en telefon i liggande läge ryms de inte alla, och en lista som
		klipps av utan att gå att rulla är en lista där de sista stegen inte
		finns. ScrollBarThickness 4 för att stapeln inte ska äta träffytan. ]]
	local mlista = Instance.new("ScrollingFrame")
	mlista.Name = "Moment"
	mlista.Position = UDim2.new(0, 0, 0, 128)
	mlista.Size = UDim2.new(1, 0, 1, -152)
	mlista.BackgroundTransparency = 1
	mlista.BorderSizePixel = 0
	mlista.ScrollBarThickness = 4
	mlista.AutomaticCanvasSize = Enum.AutomaticSize.Y
	mlista.CanvasSize = UDim2.new(0, 0, 0, 0)
	mlista.Parent = panel

	local mlayout = Instance.new("UIListLayout")
	mlayout.FillDirection = Enum.FillDirection.Vertical
	mlayout.Padding = UDim.new(0, 4)
	mlayout.SortOrder = Enum.SortOrder.LayoutOrder
	mlayout.Parent = mlista
	momentBehallare = mlista :: any

	local h = Instance.new("TextLabel")
	h.Name = "Hjalp"
	h.Position = UDim2.new(0, 0, 1, -24)
	h.Size = UDim2.new(1, 0, 0, 24)
	h.BackgroundTransparency = 1
	h.Font = Enum.Font.Gotham
	h.TextSize = 12
	h.TextWrapped = true
	h.TextXAlignment = Enum.TextXAlignment.Left
	h.TextColor3 = Color3.fromRGB(186, 190, 194)
	h.Text = ""
	h.Parent = panel
	hjalp = h

	gui = g
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
	momentKoppling[m.id] = knapp.Activated:Connect(skicka)

	knapp.LayoutOrder = ordning
	knapp.Visible = true
	knapp.Text = (if m.klar then "✓  " else "")  .. m.namn

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

function rita(vy: any)
	bygg()
	senasteVy = vy

	local anvanda: { [string]: boolean } = {}

	--[[ ── 1. VÄLFÄRDSSTOPPET ─────────────────────────────────────
		Ligger först för att det stänger allt annat. Ingen fas, inget
		moment, ingen uppsittning — bara texten om varför. ]]
	if vy.stoppad then
		for _, r in pairs(rader) do r.ram.Visible = false end
		doljOanvanda(anvanda)
		if rubrik then rubrik.Text = "Ridläraren tar över" end
		if hjalp then hjalp.Text = tostring(vy.stoppad) end
		if gui then gui.Enabled = true end
		return
	end

	--[[ ── 2. FYNDET ──────────────────────────────────────────────
		Ett obesvarat fynd tar över panelen. Faserna ritas kvar som lägesbild
		— spelaren ska se var i dagen hon är — men det enda som går att
		trycka på är svaren. ]]
	for i, steg in ipairs(vy.steg or {}) do
		rad(steg, i)
	end

	if vy.svar and #vy.svar > 0 then
		for i, s in ipairs(vy.svar) do
			anvanda[s.id] = true
			momentRad({ id = s.id, namn = s.namn, klar = false, fel = s.fel }, i, not s.fel,
				function() PreparationController.svara(s.id) end)
		end
		doljOanvanda(anvanda)
		if rubrik then rubrik.Text = "Du hittade något" end
		if hjalp then hjalp.Text = tostring(vy.fynd or "") end
		if gui then gui.Enabled = true end
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
			momentRad(m, i, m.id == nasta, function()
				PreparationController.eftervard(m.id)
			end)
			if m.id == nasta then text = m.text or "" end
		end
		doljOanvanda(anvanda)
		if rubrik then rubrik.Text = "Ta hand om henne" end
		if hjalp then hjalp.Text = text end
		if gui then gui.Enabled = true end
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
		if rubrik then rubrik.Text = "Passet är klart och sparat" end
		if hjalp then
			hjalp.Text = "Bra jobbat. Du har ridit ditt pass idag."
		end
		if gui then gui.Enabled = true end
		return
	end

	--[[ ── 4. SKÖTSELN ────────────────────────────────────────────── ]]
	local nasta = vy.nastaMoment
	local momenttext = ""
	for i, m in ipairs(vy.moment or {}) do
		anvanda[m.id] = true
		momentRad(m, i, m.id == nasta, function()
			PreparationController.begar(vy.nasta, m.id)
		end)
		if m.id == nasta then momenttext = m.text or "" end
	end
	doljOanvanda(anvanda)

	if vy.status == "waiting_model" then
		if rubrik then rubrik.Text = "Väntar på din häst" end
		if hjalp then hjalp.Text = "Hon är tilldelad men står inte i världen än." end
	elseif vy.status == "riding" then
		if rubrik then rubrik.Text = "Du rider" end
		if hjalp then hjalp.Text = "" end
	elseif vy.redo then
		if rubrik then rubrik.Text = "Klar — du kan sitta upp" end
		if hjalp then hjalp.Text = "Kontrollera gjorden en sista gång." end
	else
		local fasnamn = nil
		for _, steg in ipairs(vy.steg or {}) do
			if steg.id == vy.nasta then fasnamn = steg.namn end
		end
		if rubrik then rubrik.Text = fasnamn or "Gör i ordning din häst" end
		if hjalp then hjalp.Text = momenttext end
	end

	--[[ HUD:en göms medan man rider — men INTE när eftervården väntar, och
		det är hela skillnaden mot före #161: en spelare som satt av mötte
		förut en tom skärm, och passet tog aldrig slut. ]]
	if gui then gui.Enabled = vy.status ~= "riding" end
end

--[[ ── AVSIKTERNA UT ────────────────────────────────────────────────

	Alla tre går samma väg: ett fjärranrop med en AVSIKT, ett svar som bara
	får ändra hjälptexten. Ett avslag ritar INTE om listan. Servern skickar
	alltid en färsk sync efter varje försök, och den är sanningen; skulle
	det här svaret rita något eget skulle det kunna komma efter och skriva
	över den. ]]
local function skicka(nyckel: string, remote: string, ...)
	if vantarPa then return end
	vantarPa = nyckel
	local args = table.pack(...)
	task.spawn(function()
		local ok, skal = Net.get(remote):InvokeServer(table.unpack(args, 1, args.n))
		vantarPa = nil
		if not ok and hjalp then
			hjalp.Text = tostring(skal or "Det gick inte just nu")
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

function PreparationController.hastId(): string?
	return senasteVy and senasteVy.hastId or nil
end

--[[ Provkrokar: vad HUD:en faktiskt ritade. Provet läser dem i stället för
	att bygga en egen uppfattning om vad som borde ha ritats. ]]
function PreparationController._synligaMoment(): { string }
	local ut = {}
	for id, knapp in pairs(momentRader) do
		if knapp.Visible then table.insert(ut, id) end
	end
	table.sort(ut)
	return ut
end

function PreparationController._rubrik(): string
	return rubrik and rubrik.Text or ""
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
