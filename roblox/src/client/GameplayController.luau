--!strict
--[[
	GameplayController — den tunna klientytan för G01.1.

	Den visar bara serverns sanning: tilldelad häst, nästa mål och eventuell
	feedback. Progressionen flyttas aldrig lokalt innan servern godkänt den.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Core = require(ReplicatedStorage.HorseCore)
local Net = Core.Networking
local RigAdapter = Core.RigAdapter

local GameplayController = {}

local player = Players.LocalPlayer
local gui: ScreenGui? = nil
local objectiveLabel: TextLabel? = nil
local horseLabel: TextLabel? = nil
local feedbackLabel: TextLabel? = nil
local prepPrompt: ProximityPrompt? = nil
local refreshSerial = 0

local function ensureGui()
	if gui then return end

	local screen = Instance.new("ScreenGui")
	screen.Name = "UBRFG01"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = false
	screen.DisplayOrder = 20

	local panel = Instance.new("Frame")
	panel.Name = "ObjectivePanel"
	panel.AnchorPoint = Vector2.new(0, 0)
	panel.Position = UDim2.fromOffset(12, 12)
	panel.Size = UDim2.new(1, -24, 0, 132)
	panel.BackgroundColor3 = Color3.fromRGB(25, 27, 27)
	panel.BackgroundTransparency = 0.12
	panel.BorderSizePixel = 0
	panel.Parent = screen

	-- Telefonen får nästan hela skärmbredden, surfplatta/dator stannar vid
	-- 360 px. Samma panel ska alltså aldrig gå utanför en 320 px viewport.
	local size = Instance.new("UISizeConstraint")
	size.MinSize = Vector2.new(240, 132)
	size.MaxSize = Vector2.new(360, 132)
	size.Parent = panel

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = panel

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 14)
	padding.PaddingRight = UDim.new(0, 14)
	padding.PaddingTop = UDim.new(0, 11)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.Parent = panel

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 18)
	title.Font = Enum.Font.GothamBold
	title.Text = "UBRF · DITT ANSVAR"
	title.TextColor3 = Color3.fromRGB(226, 205, 145)
	title.TextSize = 12
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel

	local horse = Instance.new("TextLabel")
	horse.Name = "Horse"
	horse.BackgroundTransparency = 1
	horse.Position = UDim2.fromOffset(0, 21)
	horse.Size = UDim2.new(1, 0, 0, 22)
	horse.Font = Enum.Font.GothamSemibold
	horse.Text = ""
	horse.TextColor3 = Color3.fromRGB(245, 245, 240)
	horse.TextSize = 16
	horse.TextXAlignment = Enum.TextXAlignment.Left
	horse.Parent = panel
	horseLabel = horse

	local objective = Instance.new("TextLabel")
	objective.Name = "Objective"
	objective.BackgroundTransparency = 1
	objective.Position = UDim2.fromOffset(0, 44)
	objective.Size = UDim2.new(1, 0, 0, 48)
	objective.Font = Enum.Font.Gotham
	objective.Text = ""
	objective.TextWrapped = true
	objective.TextColor3 = Color3.fromRGB(232, 232, 226)
	objective.TextSize = 13
	objective.TextXAlignment = Enum.TextXAlignment.Left
	objective.TextYAlignment = Enum.TextYAlignment.Top
	objective.Parent = panel
	objectiveLabel = objective

	local feedback = Instance.new("TextLabel")
	feedback.Name = "Feedback"
	feedback.BackgroundTransparency = 1
	feedback.Position = UDim2.fromOffset(0, 96)
	feedback.Size = UDim2.new(1, 0, 0, 24)
	feedback.Font = Enum.Font.Gotham
	feedback.Text = ""
	feedback.TextWrapped = true
	feedback.TextColor3 = Color3.fromRGB(185, 198, 181)
	feedback.TextSize = 11
	feedback.TextXAlignment = Enum.TextXAlignment.Left
	feedback.TextYAlignment = Enum.TextYAlignment.Top
	feedback.Parent = panel
	feedbackLabel = feedback

	screen.Parent = player:WaitForChild("PlayerGui")
	gui = screen
end

local function clearPrompt()
	if prepPrompt then
		prepPrompt:Destroy()
		prepPrompt = nil
	end
end

local function attachPrompt(state: any)
	clearPrompt()
	local model = state.horse
	local action = state.action
	if typeof(model) ~= "Instance" or not model:IsA("Model") or typeof(action) ~= "string" then
		return
	end

	local rig = RigAdapter.build(model)
	if not rig then return end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "G01PreparationPrompt"
	prompt.ActionText = state.actionText or "Fortsätt"
	prompt.ObjectText = state.horseName or model.Name
	prompt.HoldDuration = if action == "approach" then 0.35 else 0.75
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = rig.attachments.Head or rig.root

	prompt.Triggered:Connect(function()
		prompt.Enabled = false
		local ok, accepted, message = pcall(function()
			return Net.get("G01Action"):InvokeServer(action, model)
		end)
		if not ok then
			if feedbackLabel then feedbackLabel.Text = "Momentet kunde inte skickas. Försök igen." end
			prompt.Enabled = true
			return
		end
		if accepted ~= true then
			if feedbackLabel then feedbackLabel.Text = tostring(message or "Det gick inte ännu.") end
			prompt.Enabled = true
		end
	end)

	prepPrompt = prompt
end

local function render(state: any, feedback: string?)
	ensureGui()
	if horseLabel then
		horseLabel.Text = if state.horseName and state.horseName ~= "" then state.horseName else "Ingen häst tilldelad ännu"
	end
	if objectiveLabel then
		objectiveLabel.Text = state.objective or "Fortsätt med din häst."
	end
	if feedbackLabel then
		feedbackLabel.Text = feedback or ""
	end
	attachPrompt(state)
end

local function refresh(): boolean
	refreshSerial += 1
	local mySerial = refreshSerial
	local ok, state = pcall(function()
		return Net.get("G01GetState"):InvokeServer()
	end)
	if mySerial ~= refreshSerial then return true end
	if ok and state then
		render(state, nil)
		return true
	end
	if feedbackLabel then
		feedbackLabel.Text = "Kunde inte läsa dagens hästuppgift."
	end
	return false
end

local function initialRefresh(attempt: number)
	if refresh() then return end
	if attempt < 4 then
		task.delay(0.5, function()
			initialRefresh(attempt + 1)
		end)
	end
end

function GameplayController.start()
	ensureGui()
	-- G01StateChanged är den enda live-källan för fas + pedagogisk feedback.
	-- Att dessutom refresha på G01Phase-attributet raderade feedbacken i nästa
	-- scheduler-varv, eftersom refreshen inte bär med sig föregående feedback.
	Net.get("G01StateChanged").OnClientEvent:Connect(function(state, feedback)
		render(state, feedback)
	end)
	initialRefresh(1)
end

return GameplayController
