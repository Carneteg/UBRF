--!strict
--[[
	Klientens start och den enda uppdateringsloopen.

	En loop, inte en per delsystem. Det är skillnaden mellan tio hästar och
	hundra: varje extra Heartbeat-koppling kostar även när den inte gör
	något, och ordningen mellan delsystemen blir odefinierad om de har varsin.

	Ordningen här är inte godtycklig:
	  1. inmatning   — avsikten läses en gång per bildruta
	  2. rörelse     — tillstånd och fart räknas fram
	  3. animation   — läser tillståndet, skriver benen
	  4. ryttare     — IK ovanpå benen
	  5. ljud, damm  — läser fasen
	  6. kamera      — sist, så den ser slutgiltig position
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Core = require(game:GetService("ReplicatedStorage").HorseCore)
local Config, RigAdapter, Net = Core.Config, Core.RigAdapter, Core.Networking
local Telemetri = require(game:GetService("ReplicatedStorage").HorseCore.Telemetri)

local Input = require(script.Input)
local TouchControls = require(script.TouchControls)
local MovementController = require(script.MovementController)
local AnimationController = require(script.AnimationController)
local CameraController = require(script.CameraController)
local SoundController = require(script.SoundController)
local EffectsController = require(script.EffectsController)
local RiderController = require(script.RiderController)
local InteractionController = require(script.InteractionController)
local PreparationController = require(script.PreparationController)
local UgnetaController = require(script.UgnetaController)
local LektionController = require(script.LektionController)
local Debug = require(script.Debug)
local Genomsikt = require(script.Genomsikt)

local player = Players.LocalPlayer
local ride: { [string]: any }? = nil

local function dismount()
	if not ride then return end
	Telemetri.sittAv(ride.ritt)
	Input.unbind()
	TouchControls.unmount()
	ride.movement:release()
	ride.animation:release()
	ride.camera:release()
	ride.sound:release()
	ride.effects:release()
	ride.rider:release()
	--[[ SÄKERHET FÖRE UNDERVISNING (G02-C). Ritten är slut — av vilket
	     skäl som helst, och flera av dem ÄR säkerhetshändelser: karaktären
	     försvinner, riggen är borta ur workspace, servern flyttar
	     uppsittningen. Lärarytan släcks här, i samma andetag som resten av
	     ekipaget rivs, så att "Bra rytm" aldrig blir kvar på skärmen. ]]
	LektionController.avbryt()
	Debug.clear()
	InteractionController.setEnabled(true)
	ride = nil
end

local function mount(model: Model)
	if ride then dismount() end

	local rig, err = RigAdapter.build(model)
	if not rig then
		warn("[Horse] " .. tostring(err))
		return
	end
	local stats = Config.resolveStats(rig.stats)

	ride = {
		model = model,
		rig = rig,
		stats = stats,
		movement = MovementController.new(rig, stats),
		animation = AnimationController.new(rig, stats),
		camera = CameraController.new(rig),
		sound = SoundController.new(rig, stats),
		effects = EffectsController.new(rig),
		rider = RiderController.new(rig),
		--[[ G02-A: ridningens tillstånd och telemetri, samma kontrakt som
		     webbens src/riding/telemetri.js. Sätts FÖRE första bildrutan
		     av samma skäl som på webben — annars finns ett fönster där
		     loopen kan läsa en avsutten ryttare mitt i en ritt. ]]
		ritt = Telemetri.sittUpp(Telemetri.nyRitt(), model.Name, "ridhus"),
		telemetri = nil :: { [string]: any }?,
		syncTimer = 0,
	}

	local character = player.Character
	if character then
		ride.rider:attach(character)
	end

	Input.bind()
	--[[ Pekkontrollerna byggs först här, och bara på en pekenhet: en
	     spelare vid tangentbordet ska inte få en spak över bilden. De river
	     sig själva i `dismount`, så de kan aldrig ligga kvar och styra en
	     häst man klivit av. ]]
	TouchControls.mount(Input, { dismount = function()
		Net.get("DismountRequest"):InvokeServer()
		dismount()
	end })
	InteractionController.setEnabled(false)
	Debug.attach(rig, stats)

	--[[ G02-C: lektionen börjar när man sitter upp i ridhuset. Ugneta
	     ställer sig vid sargen och undervisningen kör i den ordinarie
	     loopen nedan — det är hela skillnaden mot en HUD som bara går att
	     anropa. Gestalten placeras mot den BYGGDA banan; hittas den inte
	     körs lektionen ändå, utan figur. ]]
	--[[ Hela anläggningen är EN modell, "UBRF" i mappen "Anläggning"
	     (BuildKit.newBuilding i roblox/buildings/Anlaggningen.luau).
	     Ridbanan och sargen hänger direkt under den. ]]
	local anlaggning = workspace:FindFirstChild("Anläggning")
	LektionController.start(anlaggning and anlaggning:FindFirstChild("UBRF"))

	local missing = (ride.animation :: any).missing
	if missing and #missing > 0 then
		warn(("[Horse] Saknade animationer (%d): %s")
			:format(#missing, table.concat(missing, ", ")))
	end
end

--[[ Inomhusläsbarhet, till fots och till häst: väggar mellan kameran och
     karaktären tonas på den här klienten. ]]
Genomsikt.start()

InteractionController.start(mount)

--[[ Förberedelsen. Prompten "Sitt upp" får bara finnas på den häst servern
     säger att spelaren är klar med — och `redo` läses ur den senast
     mottagna `PreparationSync`, aldrig ur något klienten räknat ut själv. ]]
InteractionController.setReadyCheck(function(model: Model): boolean
	local id = PreparationController.hastId()
	if not id then return false end
	if model:GetAttribute("HorseId") ~= id then return false end
	return PreparationController.redo()
end)
--[[ Prompt-uppdateringen hänger på ATT EN NY VY ACCEPTERATS, inte på
     RemoteEvent-händelsen. Skillnaden är hela rättelsen efter senior review
     runda 2: handskakningens svar kommer inte som en `PreparationSync`, så
     en andra listener på det eventet missade det helt och en sent
     initierad klient fick aldrig sin "Sitt upp"-prompt. ]]
PreparationController.vidNyVy(function()
	InteractionController.uppdatera()
end)
PreparationController.start()
--[[ G02-C: Ugnetas lärar-UX byggs vid uppstart så att den finns när
     första ritten börjar. Själva LEKTIONEN startas av `mount` och stegas
     av loopen längst ned — HUD:en är ytan, LektionController är kedjan. ]]
UgnetaController.start()

--[[ Servern talar om när uppsittningen ändras — även när den ändras av
     något annat än oss, som respawn eller att hästen tas bort. ]]
Net.get("MountChanged").OnClientEvent:Connect(function(model: Model, rider: Player?)
	if rider == player then
		if not ride or ride.model ~= model then
			mount(model)
		end
	elseif ride and ride.model == model then
		dismount()
	end
end)

--[[ Servern äger energin; klienten predikterar mellan synkarna och
     RÄTTAS här (senior re-review #87, blocker 3). Utan rättelsen hade
     klienten och servern varit två trötthetssanningar igen — nu är
     klientens värde en prediktion av serverns, inte en egen modell. ]]
Net.get("StaminaSync").OnClientEvent:Connect(function(stamina, max, ceiling, energi)
	if ride then
		ride.movement:setCeiling(ceiling)
		if energi ~= nil then ride.movement:setEnergi(energi) end
		Debug.setStamina(stamina, max, ceiling)
	end
end)

--[[ Sitt av med E, och alltid om karaktären dör. Lektionens fortsättning
     ligger före avsittningen: den är ett svar på ett kort som står uppe,
     och får aldrig kunna tolkas som något annat. ]]
UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not ride then return end
	--[[ G02-C: spelaren går vidare i lektionen. R och gamepadens Y är
	     valda för att de INTE är bundna i ridningen — Input.luau tar
	     W A S D, Space, Shift, Ctrl, Q, F, Z, C och ButtonA/B/R1/L1, och
	     E betyder redan sitt av. Musen och fingret går in genom knappens
	     eget Activated, inte här.

	     `fortsatt` returnerar false när inget kort väntar, så tangenten
	     stjäl ingenting när lektionen inte frågar. ]]
	if input.KeyCode == Enum.KeyCode.R or input.KeyCode == Enum.KeyCode.ButtonY then
		if LektionController.fortsatt() then return end
	end
	if input.KeyCode == Enum.KeyCode.E then
		Net.get("DismountRequest"):InvokeServer()
		dismount()
	end
end)

player.CharacterRemoving:Connect(dismount)

RunService.RenderStepped:Connect(function(dt)
	if not ride then return end
	if not ride.rig.root:IsDescendantOf(workspace) then
		dismount()
		return
	end

	local intent = Input.consume()
	ride.movement:step(intent, dt)

	local loco = ride.movement.loco

	--[[ G02-A: gångarten följs av övergångskontraktet och telemetrin läggs
	     på ride.telemetri, så att G02-B/C har EN avläsningspunkt på båda
	     ytorna. REN AVLÄSNING — modulen räknar ingen fysik, rör ingen
	     Instance och ligger efter movement:step, så den kan varken ändra
	     rörelsen eller ridkänslan. ]]
	Telemetri.foljGangart(ride.ritt, loco.gait)
	ride.telemetri = Telemetri.las(ride.ritt, loco, ride.movement.curvature,
		ride.movement.hjalper)

	--[[ G02-C: lektionen läser telemetrin som just skrivits. Den ligger
	     EFTER avläsningen och FÖRE renderingen av samma skäl som allt
	     annat i den här ordningen: den ska se bildrutans mätning, inte
	     förra bildrutans, och den rör varken rörelse eller kamera. ]]
	LektionController.steg(dt, ride.telemetri)

	ride.animation:step(loco, dt)
	ride.rider:step(loco, dt)
	ride.sound:step(loco, dt)
	ride.effects:step(loco, dt)
	ride.camera:step(loco, dt)
	Debug.step(loco)

	--[[ Servern behöver inte 60 uppdateringar i sekunden för att validera
	     en gångart. Tio räcker, och skillnaden märks direkt i bandbredd när
	     flera spelare rider samtidigt. ]]
	ride.syncTimer += dt
	if ride.syncTimer >= 0.1 then
		ride.syncTimer = 0
		Net.get("StateSync"):FireServer(loco.gait, loco.speed)
	end
end)

print("[Horse] Klienten igång")
