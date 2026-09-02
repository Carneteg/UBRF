--!strict
--[[ FÖRBEREDELSENS HUD.

	Visar serverns sanning och inget annat. Den här filen räknar aldrig ut
	om ett steg är klart — den ritar `PreparationSync`. Skälet är krav 10:
	en sen init eller en refresh får inte skriva över nyare serverfeedback,
	och det enda sättet att garantera det är att klienten inte har någon egen
	uppfattning som kan vara nyare.

	Layouten är byggd för 320 px bredd först. Det är inte en artig gest mot
	mobilen — Tobias familj spelar på iPad, och en HUD som kräver 900 px är
	inte spelbar för dem.
]]

local Players = game:GetService("Players")

local Core = require(game:GetService("ReplicatedStorage").HorseCore)
local Preparation = require(game:GetService("ReplicatedStorage").HorseCore.Preparation)
local Net = Core.Networking

local PreparationController = {}

local player = Players.LocalPlayer

local gui: ScreenGui? = nil
local radBehallare: Frame? = nil
local rubrik: TextLabel? = nil
local hjalp: TextLabel? = nil
local rader: { [string]: { ram: Frame, bock: TextLabel, namn: TextLabel } } = {}
local senasteVy: any = nil
--[[ Revisionen på det som faktiskt ritats. `nil` = ingenting ritat än. ]]
local senasteRev: number? = nil
local rita

--[[ Steg-id:t klienten senast bad om, och när. Används bara för att gråa ut
	knappen medan svaret är på väg — inte för att gissa utfallet. ]]
local vantarPa: string? = nil

local FARG_KLAR = Color3.fromRGB(127, 180, 137)
local FARG_TUR = Color3.fromRGB(214, 174, 60)
local FARG_VILAR = Color3.fromRGB(120, 124, 128)

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
		halvmeter bred. ]]
	panel.Size = UDim2.new(0.92, 0, 0, 190)
	panel.SizeConstraint = Enum.SizeConstraint.RelativeXX
	panel.Position = UDim2.new(0.5, 0, 1, -12)
	panel.AnchorPoint = Vector2.new(0.5, 1)
	panel.BackgroundColor3 = Color3.fromRGB(24, 26, 28)
	panel.BackgroundTransparency = 0.15
	panel.BorderSizePixel = 0
	panel.Parent = g

	local max = Instance.new("UISizeConstraint")
	max.MaxSize = Vector2.new(420, 260)
	max.MinSize = Vector2.new(240, 150)
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
	r.TextColor3 = Color3.fromRGB(238, 240, 242)
	r.Text = "Gör i ordning din häst"
	r.Parent = panel
	rubrik = r

	local lista = Instance.new("Frame")
	lista.Name = "Steg"
	lista.Position = UDim2.new(0, 0, 0, 24)
	lista.Size = UDim2.new(1, 0, 1, -52)
	lista.BackgroundTransparency = 1
	lista.Parent = panel

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = lista
	radBehallare = lista

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

local function rad(steg: any, ordning: number)
	local befintlig = rader[steg.id]
	if not befintlig then
		local ram = Instance.new("TextButton")
		ram.Name = steg.id
		ram.Size = UDim2.new(1, 0, 0, 26)
		ram.BackgroundColor3 = Color3.fromRGB(38, 41, 44)
		ram.BorderSizePixel = 0
		ram.AutoButtonColor = true
		ram.Text = ""
		ram.Parent = radBehallare

		local horn = Instance.new("UICorner")
		horn.CornerRadius = UDim.new(0, 6)
		horn.Parent = ram

		local bock = Instance.new("TextLabel")
		bock.Name = "Bock"
		bock.Size = UDim2.new(0, 22, 1, 0)
		bock.BackgroundTransparency = 1
		bock.Font = Enum.Font.GothamBold
		bock.TextSize = 14
		bock.Parent = ram

		local namn = Instance.new("TextLabel")
		namn.Name = "Namn"
		namn.Position = UDim2.new(0, 24, 0, 0)
		namn.Size = UDim2.new(1, -28, 1, 0)
		namn.BackgroundTransparency = 1
		namn.Font = Enum.Font.Gotham
		namn.TextSize = 13
		namn.TextXAlignment = Enum.TextXAlignment.Left
		namn.Parent = ram

		ram.Activated:Connect(function()
			PreparationController.begar(steg.id)
		end)

		befintlig = { ram = ram :: any, bock = bock, namn = namn }
		rader[steg.id] = befintlig
	end

	befintlig.ram.LayoutOrder = ordning
	befintlig.namn.Text = steg.namn
	if steg.klar then
		befintlig.bock.Text = "✓"
		befintlig.bock.TextColor3 = FARG_KLAR
		befintlig.namn.TextColor3 = FARG_KLAR
	elseif senasteVy and senasteVy.nasta == steg.id then
		befintlig.bock.Text = "•"
		befintlig.bock.TextColor3 = FARG_TUR
		befintlig.namn.TextColor3 = Color3.fromRGB(238, 240, 242)
	else
		befintlig.bock.Text = "·"
		befintlig.bock.TextColor3 = FARG_VILAR
		befintlig.namn.TextColor3 = FARG_VILAR
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

function rita(vy: any)
	bygg()
	senasteVy = vy
	for i, steg in ipairs(vy.steg or {}) do
		rad(steg, i)
	end

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
		if rubrik then rubrik.Text = "Gör i ordning din häst" end
		local nasta = nil
		for _, steg in ipairs(vy.steg or {}) do
			if steg.id == vy.nasta then nasta = steg end
		end
		if hjalp then hjalp.Text = nasta and nasta.text or "" end
	end
	if gui then gui.Enabled = vy.status ~= "riding" end
end

function PreparationController.begar(fasId: string)
	if vantarPa then return end
	vantarPa = fasId
	task.spawn(function()
		local ok, skal = Net.get("PreparationStep"):InvokeServer(fasId)
		vantarPa = nil
		--[[ Ett avslag ritar INTE om listan. Servern skickar alltid en färsk
			`PreparationSync` efter varje försök, och den är sanningen; skulle
			det här svaret rita något eget skulle det kunna komma efter och
			skriva över den. Bara texten byts. ]]
		if not ok and hjalp then
			hjalp.Text = tostring(skal or "Det gick inte just nu")
		end
	end)
end

function PreparationController.redo(): boolean
	return senasteVy ~= nil and senasteVy.redo == true
end

function PreparationController.hastId(): string?
	return senasteVy and senasteVy.hastId or nil
end

function PreparationController.start()
	--[[ ORDNINGEN ÄR KONTRAKTET: listenern ansluts FÖRST, handskakningen
		anropas sedan. Servern skickar sin första vy från `bind()` vid
		PlayerAdded, och en RemoteEvent som avfyras innan någon lyssnar är
		borta för alltid — den köas inte. Utan handskakningen startade
		klienten därför utan hästId, steg och ready-state, utan någon
		deterministisk ny sync att vänta på. ]]
	Net.get("PreparationSync").OnClientEvent:Connect(ritaOmNyare)

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
