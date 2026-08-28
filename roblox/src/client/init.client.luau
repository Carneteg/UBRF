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

local Input = require(script.Input)
local MovementController = require(script.MovementController)
local AnimationController = require(script.AnimationController)
local CameraController = require(script.CameraController)
local SoundController = require(script.SoundController)
local EffectsController = require(script.EffectsController)
local RiderController = require(script.RiderController)
local InteractionController = require(script.InteractionController)
local Debug = require(script.Debug)

local player = Players.LocalPlayer
local ride: { [string]: any }? = nil

local function dismount()
	if not ride then return end
	Input.unbind()
	ride.movement:release()
	ride.animation:release()
	ride.camera:release()
	ride.sound:release()
	ride.effects:release()
	ride.rider:release()
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
		syncTimer = 0,
	}

	local character = player.Character
	if character then
		ride.rider:attach(character)
	end

	Input.bind()
	InteractionController.setEnabled(false)
	Debug.attach(rig, stats)

	local missing = (ride.animation :: any).missing
	if missing and #missing > 0 then
		warn(("[Horse] Saknade animationer (%d): %s")
			:format(#missing, table.concat(missing, ", ")))
	end
end

InteractionController.start(mount)

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

Net.get("StaminaSync").OnClientEvent:Connect(function(stamina, max, ceiling)
	if ride then
		ride.movement:setCeiling(ceiling)
		Debug.setStamina(stamina, max, ceiling)
	end
end)

--[[ Sitt av med E, och alltid om karaktären dör. ]]
UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not ride then return end
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
