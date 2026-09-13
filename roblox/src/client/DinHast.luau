--!strict
--[[ DINHAST — vilken häst som är MIN, och var hon står.

	Spelet visste redan vilken häst spelaren skulle rida. Spelaren gjorde
	det inte: trettiotre hästar står i fyra rader, alla ser likadana ut på
	avstånd, och ingenting pekade ut den rätta. Man fick gå från box till
	box och läsa.

	Två saker, båda LOKALA:

	  · en rad i HUD:en vid ankomsten — "Idag rider du Blackrock Jack" —
	    som svarar på frågan innan man ens gått in i stallet,
	  · en liten skylt över hästen själv, så att rätt box går att känna
	    igen från gången.

	ATT DE ÄR LOKALA ÄR POÄNGEN. Allt här byggs i spelarens egen
	`PlayerGui` och når därför aldrig någon annan. En annan ryttares
	tilldelning är inte min information, och trettiotre skyltar i ett stall
	vore inte en hjälp utan en tapet.

	SKYLTEN SKA TONA BORT. Den är ett svar på "vilken av dem?", och den
	frågan är besvarad när man står framför henne. På nära håll bleknar
	den därför nästan helt, och under ritten är den släckt. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local Sprak = require(ReplicatedStorage.HorseCore.Sprak)
local PreparationController = require(script.Parent.PreparationController)

local DinHast = {}

local spelare = Players.LocalPlayer
local dagens: any = nil
local skylt: BillboardGui? = nil
local hudGui: ScreenGui? = nil
local hudRad: TextLabel? = nil
local loop: RBXScriptConnection? = nil
local dold = false

local FARG_GULD = Color3.fromRGB(214, 174, 60)
local FARG_TEXT = Color3.fromRGB(236, 232, 222)

--[[ Avstånden som styr tonandet. Bortom `LANGT` syns skylten fullt —
	det är då man letar. Innanför `NARA` är man framme, och då har den
	gjort sitt. ]]
local NARA = 12
local LANGT = 30

local function hastModell(id: string): Model?
	for _, m in ipairs(CollectionService:GetTagged("Horse")) do
		if m:IsA("Model") and m:GetAttribute("HorseId") == id then
			return m
		end
	end
	return nil
end

--[[ ── ANDRA SPELARES BOXMARKÖRER ────────────────────────────────────

	`StallService` lägger en markör med en ProximityPrompt vid VARJE
	spelares box, och den ligger i `workspace`. Med två ryttare inne ser
	båda alltså båda prompterna, och "Titta in — Troy står här" dyker upp
	för den som inte rider Troy.

	Prompten kan inte döljas per spelare från servern. Klienten kan
	däremot släcka det som inte är hennes, och det är vad som händer här.
	Handlingen är redan skyddad på servern (`if spelare ~= player then
	return end`); det här är synligheten. ]]
local function slackAndrasMarkorer()
	local mitt = "Boxmarkor_" .. spelare.Name
	for _, m in ipairs(workspace:GetChildren()) do
		if m.Name:sub(1, 10) == "Boxmarkor_" and m.Name ~= mitt then
			for _, d in ipairs(m:GetDescendants()) do
				if d:IsA("ProximityPrompt") then d.Enabled = false end
			end
		end
	end
end

local function byggHud()
	if hudGui then return end
	local g = Instance.new("ScreenGui")
	g.Name = "UBRFDinHast"
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = false
	g.DisplayOrder = 6
	g.Parent = spelare:WaitForChild("PlayerGui")
	hudGui = g

	local l = Instance.new("TextLabel")
	l.Name = "Rad"
	--[[ Uppe till vänster och smal: den ska kunna läsas i förbifarten och
		aldrig ligga i vägen för kortet, spaken eller reglagen. ]]
	l.AnchorPoint = Vector2.new(0, 0)
	l.Position = UDim2.fromOffset(12, 12)
	l.Size = UDim2.fromOffset(320, 28)
	l.BackgroundColor3 = Color3.fromRGB(8, 10, 14)
	l.BackgroundTransparency = 0.25
	l.TextColor3 = FARG_TEXT
	l.Font = Enum.Font.GothamMedium
	l.TextSize = 14
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Text = ""
	l.Visible = false
	l.Parent = g
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.Parent = l
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = l
	local tak = Instance.new("UITextSizeConstraint")
	tak.MaxTextSize = 14
	tak.MinTextSize = 9
	tak.Parent = l
	l.TextScaled = true
	hudRad = l
end

local function byggSkylt(modell: Model)
	if skylt then skylt:Destroy() end
	local rot = modell.PrimaryPart or modell:FindFirstChild("HumanoidRootPart", true)
	if not rot then return end

	local b = Instance.new("BillboardGui")
	b.Name = "DinHastSkylt"
	b.Adornee = rot
	b.Size = UDim2.fromOffset(160, 44)
	b.StudsOffsetWorldSpace = Vector3.new(0, 4.6, 0)
	b.AlwaysOnTop = true
	b.MaxDistance = 120
	--[[ I spelarens EGEN PlayerGui, inte i världen: det är det som gör
		skylten lokal utan en enda extra rad logik. ]]
	b.Parent = spelare:WaitForChild("PlayerGui")
	skylt = b

	local ram = Instance.new("Frame")
	ram.Name = "Ram"
	ram.Size = UDim2.fromScale(1, 1)
	ram.BackgroundColor3 = Color3.fromRGB(8, 10, 14)
	ram.BackgroundTransparency = 0.3
	ram.Parent = b
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = ram

	local rubrik = Instance.new("TextLabel")
	rubrik.Name = "Rubrik"
	rubrik.Size = UDim2.new(1, -12, 0, 14)
	rubrik.Position = UDim2.fromOffset(6, 4)
	rubrik.BackgroundTransparency = 1
	rubrik.Text = Sprak.t("stall.din_hast")
	rubrik.TextColor3 = FARG_GULD
	rubrik.Font = Enum.Font.GothamBold
	rubrik.TextSize = 11
	rubrik.Parent = ram

	local namn = Instance.new("TextLabel")
	namn.Name = "Namn"
	namn.Size = UDim2.new(1, -12, 0, 20)
	namn.Position = UDim2.fromOffset(6, 18)
	namn.BackgroundTransparency = 1
	namn.Text = tostring(dagens and dagens.namn or "")
	namn.TextColor3 = FARG_TEXT
	namn.Font = Enum.Font.GothamMedium
	namn.TextSize = 14
	namn.TextScaled = true
	namn.Parent = ram
	local tak = Instance.new("UITextSizeConstraint")
	tak.MaxTextSize = 14
	tak.MinTextSize = 8
	tak.Parent = namn
end

--[[ Tonandet. Ett tal mellan 0 och 1 där 1 är "syns fullt". ]]
local function styrka(avstand: number): number
	if avstand <= NARA then return 0.12 end
	if avstand >= LANGT then return 1 end
	return 0.12 + (avstand - NARA) / (LANGT - NARA) * 0.88
end

local function steg()
	local b = skylt
	local rad = hudRad
	if not dagens then return end
	local karaktar = spelare.Character
	local rot = karaktar and karaktar:FindFirstChild("HumanoidRootPart")
	local modell = hastModell(dagens.id)

	if dold or not modell or not rot then
		if b then b.Enabled = false end
		if rad then rad.Visible = false end
		return
	end

	local hastRot = modell.PrimaryPart or modell:FindFirstChild("HumanoidRootPart", true)
	if not hastRot then return end
	local avstand = ((hastRot :: BasePart).Position - (rot :: BasePart).Position).Magnitude
	local s = styrka(avstand)

	if b then
		b.Enabled = true
		local ram = b:FindFirstChild("Ram") :: Frame?
		if ram then ram.BackgroundTransparency = 1 - 0.7 * s end
		for _, d in ipairs(b:GetDescendants()) do
			if d:IsA("TextLabel") then d.TextTransparency = 1 - s end
		end
	end

	--[[ HUD-raden är ett svar på "vem ska jag rida", och den frågan är
		besvarad när man står vid henne. Den slocknar därför helt på nära
		håll i stället för att blekna — en rad som ligger kvar halvsynlig
		är en rad man slutar läsa. ]]
	if rad then rad.Visible = avstand > NARA end
end

--[[ Under ritten och medan man leder är frågan besvarad. ]]
function DinHast.satDold(v: boolean)
	dold = v
end

--[[ ── VARIFRÅN SVARET KOMMER ──────────────────────────────────────

	Det stod först en `MinHast:InvokeServer()` här. Den HÄNGDE i
	flerspelarläge: anropet återvände aldrig, `dagens` blev aldrig satt,
	och varken raden eller skylten byggdes. Mätt med två spelare inne —
	skylten saknades helt hos båda.

	Den behövdes inte heller. Klienten har redan allt den ska visa:
	`PreparationController` får hästens id i sin vanliga vy, och namnet
	står på modellen i världen.

	Ingen rundtur, inget att hänga på, och ett svar som kommer lika fort
	som förberedelsevyn. ]]
local function lasAssignment(): boolean
	local id = PreparationController.hastId()
	if type(id) ~= "string" then return false end
	if dagens and dagens.id == id then return true end
	local modell = hastModell(id)
	local namn = modell and (modell:GetAttribute("HorseName") or modell.Name) or id
	dagens = { id = id, namn = namn }

	local rad = hudRad
	if rad then
		rad.Text = Sprak.t("stall.idag_rider_du", tostring(namn))
	end
	if modell then byggSkylt(modell) end
	slackAndrasMarkorer()
	return true
end

function DinHast.start()
	byggHud()
	--[[ Andra spelares boxmarkörer dyker upp när DE kommer in, alltså
		också efter att vi själva är igång. Att bara släcka en gång vid
		start hade missat varje spelare som anslöt senare. ]]
	workspace.ChildAdded:Connect(function(inst)
		if inst.Name:sub(1, 10) == "Boxmarkor_" then
			task.defer(slackAndrasMarkorer)
		end
	end)

	if loop then loop:Disconnect() end
	local sedan, sedanSvep = 0, 0
	loop = RunService.Heartbeat:Connect(function(dt)
		sedan += dt
		sedanSvep += dt
		--[[ `ChildAdded` ensam räckte inte: markörerna rivs och byggs om
			när servern delar ut hästar, och en markör som återskapades i
			samma bildruta som vårt första svep blev kvar tänd. Mätt med två
			spelare inne — Player2 såg fortfarande Player1:s prompt.

			Ett svep i sekunden är billigt och självläkande, och gör
			ordningen mellan spelarnas inloggning likgiltig. ]]
		if sedanSvep >= 1 then
			sedanSvep = 0
			slackAndrasMarkorer()
		end
		--[[ Fem gånger i sekunden räcker för ett avståndsmått. ]]
		if sedan < 0.2 then return end
		sedan = 0
		if not lasAssignment() then return end
		if not skylt and dagens then
			local m = hastModell(dagens.id)
			if m then byggSkylt(m) end
		end
		steg()
	end)
end

function DinHast.stopp()
	if loop then loop:Disconnect(); loop = nil end
	if skylt then skylt:Destroy(); skylt = nil end
	if hudGui then hudGui:Destroy(); hudGui = nil end
	hudRad = nil
	dagens = nil
end

return DinHast
