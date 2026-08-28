--!strict
--[[
	Uppsittningen.

	En ProximityPrompt per häst, skapad på klienten så att servern slipper
	replikera dem. Prompten frågar servern om lov — klienten bestämmer
	aldrig själv att den sitter upp.
]]

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local Core = require(game:GetService("ReplicatedStorage").HorseCore)
local Net, RigAdapter = Core.Networking, Core.RigAdapter

local InteractionController = {}

local prompts: { [Model]: ProximityPrompt } = {}
local onMount: ((Model) -> ())? = nil

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
		end
	end)

	prompts[model] = prompt
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
end

function InteractionController.setEnabled(enabled: boolean)
	for _, prompt in prompts do
		prompt.Enabled = enabled
	end
end

return InteractionController
