--!strict
--[[
	Uppsittningen.

	En ProximityPrompt per häst, skapad på klienten så att servern slipper
	replikera dem. Prompten frågar servern om lov — klienten bestämmer
	aldrig själv att den sitter upp.

	G01-regeln ligger både här och på servern: klienten DÖLJER uppsittning
	innan den är relevant, servern AVGÖR om den verkligen är tillåten.
]]

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local Core = require(game:GetService("ReplicatedStorage").HorseCore)
local Net, RigAdapter = Core.Networking, Core.RigAdapter

local InteractionController = {}
local player = Players.LocalPlayer

local prompts: { [Model]: ProximityPrompt } = {}
local onMount: ((Model) -> ())? = nil
local interactionEnabled = true

local function canOfferMount(model: Model): boolean
	if player:GetAttribute("G01Enabled") == true then
		return model:GetAttribute("AssignedUserId") == player.UserId
			and player:GetAttribute("G01Phase") == "ready_to_mount"
	end
	return true
end

local function refreshPrompt(model: Model)
	local prompt = prompts[model]
	if prompt then
		prompt.Enabled = interactionEnabled and canOfferMount(model)
	end
end

local function refreshAll()
	for model in prompts do
		refreshPrompt(model)
	end
end

local function addPrompt(model: Model)
	if prompts[model] then return end
	local rig = RigAdapter.build(model)
	if not rig then return end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "MountPrompt"
	prompt.ActionText = "Sitt upp"
	prompt.ObjectText = model:GetAttribute("HorseName") or model.Name
	prompt.HoldDuration = 0.35
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = rig.attachments.Saddle or rig.root

	prompt.Triggered:Connect(function()
		local ok, reason = Net.get("MountRequest"):InvokeServer(model)
		if ok and onMount then
			onMount(model)
		elseif not ok then
			warn("[Horse] Kunde inte sitta upp: " .. tostring(reason))
			refreshPrompt(model)
		end
	end)

	model:GetAttributeChangedSignal("AssignedUserId"):Connect(function()
		refreshPrompt(model)
	end)

	prompts[model] = prompt
	refreshPrompt(model)
end

local function removePrompt(model: Model)
	local prompt = prompts[model]
	if prompt then
		prompt:Destroy()
		prompts[model] = nil
	end
end

function InteractionController.start(mountCallback: (Model) -> ())
	onMount = mountCallback
	for _, model in CollectionService:GetTagged("Horse") do
		if model:IsA("Model") then addPrompt(model) end
	end
	CollectionService:GetInstanceAddedSignal("Horse"):Connect(function(inst)
		if inst:IsA("Model") then addPrompt(inst) end
	end)
	CollectionService:GetInstanceRemovedSignal("Horse"):Connect(function(inst)
		if inst:IsA("Model") then removePrompt(inst :: Model) end
	end)
	player:GetAttributeChangedSignal("G01Enabled"):Connect(refreshAll)
	player:GetAttributeChangedSignal("G01Phase"):Connect(refreshAll)
	refreshAll()
end

function InteractionController.setEnabled(enabled: boolean)
	interactionEnabled = enabled
	refreshAll()
end

return InteractionController
