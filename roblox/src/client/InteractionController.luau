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

--[[ #162: prompttexten kommer ur språkkanonen. ]]
local Sprak = require(game:GetService("ReplicatedStorage").HorseCore.Sprak)

local InteractionController = {}

local prompts: { [Model]: ProximityPrompt } = {}
--[[ Ledningens egen knapp och dess läge. Läget speglar serverns svar
     och sätts aldrig av en gissning. ]]
local ledKnappar: { [Model]: ProximityPrompt } = {}
local ledPrompts: { [Model]: boolean } = {}
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

--[[ ══ LEDNINGEN HAR EN EGEN SYNLIGHETSREGEL ════════════════════════

	Uppsittningens prompt ska vara borta tills hästen är REDO — det är
	hela poängen med förberedelsen. Ledningen fick samma regel, och det
	låste loopen:

	    för att bocka av `leda` måste hästen fysiskt ha lämnat boxen
	      → för att hon ska gå måste kopplet fästas med `LedBorja`
	        → `LedBorja` nås bara via `LedPrompt`
	          → `LedPrompt` fanns bara när `redo` var sant
	            → `redo` är `Preparation.nasta(state) == nil`, alltså
	              sant först när `leda` REDAN är avbockad.

	Mätt i Studio, stående vid sin egen häst med allt utom `leda` klart:
	`redo=false`, noll prompter i världen. Det fanns alltså ingen väg alls
	att börja leda — inte bara en otydlig väg, och inte bara på pekskärm.

	Regeln nedan är den lilla: ledningen syns också när `leda` är det steg
	spelaren står på. Servern äger fortfarande vem som får leda vad
	(`satRattHastKrok`) och när steget får bockas av — klienten bestämmer
	bara om knappen ritas. ]]
local ledFor: ((Model) -> boolean)? = nil

function InteractionController.setLedCheck(fn: ((Model) -> boolean)?)
	ledFor = fn
end

local function farVisasLed(model: Model): boolean
	if farVisas(model) then return true end
	if InteractionController.g01Lage() ~= true then return false end
	return ledFor ~= nil and ledFor(model)
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
	prompt.ActionText = Sprak.t("interaktion.sitt_upp")
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
			--[[ Skälet är en språknyckel sedan #162. Loggen skriver båda:
				nyckeln för den som felsöker, texten för den som läser
				vad spelaren faktiskt fick se. ]]
			warn(("[Horse] Kunde inte sitta upp: %s (%s)"):format(
				Sprak.t(tostring(reason)), tostring(reason)))
		end
	end)

	prompts[model] = prompt
end

local function addLedPrompt(model: Model)
	if ledKnappar[model] then return end
	if not farVisasLed(model) then return end
	local rig = RigAdapter.build(model)
	if not rig then return end

	--[[ ── LEDA (#162 blockerare 2) ──────────────────────────────────

		Ledningen behöver en egen knapp: uppsittningen och ledningen är
		två olika handlingar, och en gemensam prompt hade tvingat spelaren
		att gissa vilken hon fick. Den här sitter på samma rot men är ett
		eget objekt, och den växlar text efter läget — precis som dörrarna.

		Servern äger sanningen. Klienten frågar och skriver ut skälet;
		den avgör ingenting själv. ]]
	local led = Instance.new("ProximityPrompt")
	led.Name = "LedPrompt"
	led.ActionText = Sprak.t("led.borja")
	led.ObjectText = model:GetAttribute("HorseName") or model.Name
	led.HoldDuration = 0.2
	led.MaxActivationDistance = 12
	led.RequiresLineOfSight = false
	led.KeyboardKeyCode = Enum.KeyCode.L
	led.Parent = rig.root

	led.Triggered:Connect(function()
		local leder = ledPrompts[model] == true
		local remote = if leder then "LedSlapp" else "LedBorja"
		local ok, skal = if leder
			then Net.get(remote):InvokeServer()
			else Net.get(remote):InvokeServer(model)
		if ok then
			ledPrompts[model] = not leder
			led.ActionText = Sprak.t(if ledPrompts[model] then "led.slapp" else "led.borja")
		else
			warn(("[Led] %s (%s)"):format(Sprak.t(tostring(skal)), tostring(skal)))
		end
	end)
	ledKnappar[model] = led
end

local function removeMount(model: Model)
	local prompt = prompts[model]
	if prompt then
		prompt:Destroy()
		prompts[model] = nil
	end
end

--[[ Kopplet rivs ALDRIG medan hon faktiskt leds: prompten är spelarens
	enda väg att släppa igen, och en knapp som försvinner mitt i ledningen
	hade lämnat henne fast i andra änden av repet. ]]
local function removeLed(model: Model)
	if ledPrompts[model] == true then return end
	local led = ledKnappar[model]
	if led then
		led:Destroy()
		ledKnappar[model] = nil
		ledPrompts[model] = nil
	end
end

local function removePrompt(model: Model)
	removeMount(model)
	removeLed(model)
end

--[[ Räkna om vilka prompter som får finnas.

	Behövs för att `addPrompt` bara körs när en modell dyker upp. Utan det
	här skulle en spelare som blir klar med förberedelsen aldrig få sin
	prompt — modellen fanns ju redan när loopen startade — och en som sitter
	upp skulle behålla den. Anropas när servern skickat ny sanning. ]]
function InteractionController.uppdatera()
	for _, model in CollectionService:GetTagged("Horse") do
		if model:IsA("Model") then
			if farVisas(model) then addPrompt(model) else removeMount(model) end
			if farVisasLed(model) then addLedPrompt(model) else removeLed(model) end
		end
	end
end

function InteractionController.start(mountCallback: (Model) -> ())
	onMount = mountCallback
	for _, model in CollectionService:GetTagged("Horse") do
		if model:IsA("Model") then addPrompt(model); addLedPrompt(model) end
	end
	CollectionService:GetInstanceAddedSignal("Horse"):Connect(function(inst)
		if inst:IsA("Model") then addPrompt(inst); addLedPrompt(inst) end
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
