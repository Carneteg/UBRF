--!strict
--[[
	Uppsittningen.

	En ProximityPrompt per häst, skapad på klienten så att servern slipper
	replikera dem. Prompten frågar servern om lov — klienten bestämmer
	aldrig själv att den sitter upp.
]]

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Core = require(game:GetService("ReplicatedStorage").HorseCore)
local Net, RigAdapter = Core.Networking, Core.RigAdapter

local InteractionController = {}

local prompts: { [Model]: ProximityPrompt } = {}
local onMount: ((Model) -> ())? = nil

--[[ Får uppsittningsprompten visas för den här modellen?

	Krav 8 i arbetsordern: `G01Enabled == nil` vid klientjoin får INTE ge en
	falsk uppsittningsprompt. Attributet replikeras, och en klient som hinner
	fram före servern läser nil — inte false. Skrivs villkoret som
	`if enabled ~= false` blir det tysta felet att varje spelare ser "Sitt
	upp" på varje häst under de första sekunderna, innan förberedelsen ens
	börjat. Därför prövas nil som INTE påslaget.

	Är loopen påslagen bestämmer serverns senaste `PreparationSync` — inte
	klienten. `redoFor` sätts av init.client. ]]
local redoFor: ((Model) -> boolean)? = nil

local function g01Pa(): boolean
	return ReplicatedStorage:GetAttribute("G01Enabled") == true
end

local function farVisas(model: Model): boolean
	if not g01Pa() then
		--[[ Utan G01-loopen är hästsystemet som det var före den här skivan:
			prompten sköter sig själv och servern avgör i tryMount. ]]
		return true
	end
	return redoFor ~= nil and redoFor(model)
end

function InteractionController.setReadyCheck(fn: ((Model) -> boolean)?)
	redoFor = fn
end

local function addPrompt(model: Model)
	if prompts[model] then return end
	if not farVisas(model) then return end
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

--[[ Räkna om vilka prompter som får finnas.

	Behövs för att `addPrompt` bara körs när en modell dyker upp. Utan det
	här skulle en spelare som blir klar med förberedelsen aldrig få sin
	prompt — modellen fanns ju redan när loopen startade — och en som sitter
	upp skulle behålla den. Anropas när servern skickat ny sanning. ]]
function InteractionController.uppdatera()
	for _, model in CollectionService:GetTagged("Horse") do
		if model:IsA("Model") then
			if farVisas(model) then
				addPrompt(model)
			else
				removePrompt(model)
			end
		end
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
