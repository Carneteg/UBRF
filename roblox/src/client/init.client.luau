--!strict
--[[
	Klientens start och den enda uppdateringsloopen.

	En loop, inte en per delsystem. Ordningen per bildruta är input → rörelse →
	animation → ryttare → ljud/effekter → kamera. G01-HUD och interaktion är
	händelsedrivna och skapar därför ingen extra RenderStepped-loop.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Core = require(game:GetService("ReplicatedStorage").HorseCore)
local Config, RigAdapter, Net = Core.Config, Core.RigAdapter, Core.Networking

local Input = require(script.Input)
local TouchControls = require(script.TouchControls)
local MovementController = require(script.MovementController)
local AnimationController = require(script.AnimationController)
local CameraController = require(script.CameraController)
local SoundController = require(script.SoundController)
local EffectsController = require(script.EffectsController)
local RiderController = require(script.RiderController)
local InteractionController = require(script.InteractionController)
local GameplayController = require(script.GameplayController)
local Debug = require(script.Debug)

local player = Players.LocalPlayer
local ride: { [string]: any }? = nil

local function dismount()
	if not ride then return end
	Input.unbind()
	TouchControls.unmount()
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
	if character then ride.rider:attach(character) end

	Input.bind()
	TouchControls.mount(Input, { dismount = function()
		Net.get("DismountRequest"):InvokeServer()
		dismount()
	end })
	InteractionController.setEnabled(false)
	Debug.attach(rig, stats)

	local missing = (ride.animation :: any).missing
	if missing and #missing > 0 then
		warn(("[Horse] Saknade animationer (%d): %s")
			:format(#missing, table.concat(missing, ", ")))
	end
end

-- HUD först: join-racet ska hellre visa "väntar" än en felaktig uppsittningsknapp.
GameplayController.start()
InteractionController.start(mount)

Net.get("MountChanged").OnClientEvent:Connect(function(model: Model, rider: Player?)
	if rider == player then
		if not ride or ride.model ~= model then mount(model) end
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

	ride.syncTimer += dt
	if ride.syncTimer >= 0.1 then
		ride.syncTimer = 0
		Net.get("StateSync"):FireServer(loco.gait, loco.speed)
	end
end)

print("[Horse] Klienten igång")
