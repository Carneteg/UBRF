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

	Krav 8: `G01Enabled == nil` vid klientjoin får INTE ge en uppsittnings-
	prompt. Attributet replikeras, och en klient som hinner fram före servern
	läser nil — inte false.

	FÖRSTA VERSIONEN VAR FAIL-OPEN, och kommentaren påstod motsatsen.
	`g01Pa()` prövade riktigt `== true`, men svaret användes som
	`if not g01Pa() then return true` — så nil gick rakt in i legacy-grenen
	och VISADE prompten. Exakt det race kravet finns till för. Fälldes av
	senior review på #61.

	Rättningen är att sluta behandla flaggan som boolean. Den har TRE lägen:

	  nil   → göm. Vi vet ännu inte om loopen är på, och att gissa "av" är
	          att gissa åt fel håll.
	  true  → serverns ready-check avgör (`redoFor`).
	  false → legacy: hästsystemet utan G01-loopen, som före den här skivan.

	Att nil och false ger OLIKA svar är hela rättningen. ]]
local redoFor: ((Model) -> boolean)? = nil

--[[ Returnerar nil / true / false — inte en boolean. ]]
function InteractionController.g01Lage(): boolean?
	local v = ReplicatedStorage:GetAttribute("G01Enabled")
	if v == nil then return nil end
	return v == true
end

--[[ Själva beslutet, utan instanser, så att det går att fälla i en spec.
	Låg först som en lokal funktion och var då oprovbar — vilket är hur
	fail-open-buggen kunde ligga kvar bakom en kommentar som påstod rätt
	beteende. ]]
function InteractionController.promptSynlig(lage: boolean?, redo: boolean): boolean
	if lage == nil then
		return false          -- fail closed: vi vet inte än
	end
	if lage == false then
		return true           -- legacy, utan G01-loopen
	end
	return redo
end

local function farVisas(model: Model): boolean
	local redo = redoFor ~= nil and redoFor(model)
	return InteractionController.promptSynlig(InteractionController.g01Lage(), redo)
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
