--!strict
--[[
	Rörelsen — den modul som avgör om hästen känns som ett djur eller ett fordon.

	Körs hos den som äger nätverket, alltså ryttarens egen klient. Servern
	validerar resultatet men simulerar det inte, för annars ligger latensen
	i varje styrutslag och hästen känns som en båt.

	Fyra saker gör skillnaden mot ett fordon:

	  1. Tempot dras mot gångartens hemtempo, inte mot en knapp. Släpper man
	     W stannar hästen inte — den rullar ned i skritt.
	  2. Svarvheten sjunker med farten. I fyrsprång svänger man vidsträckt.
	  3. Svängen tar tag gradvis (TurnAccel), så inget snäpper till 90 grader.
	  4. Accelerationen är olika uppåt och nedåt, och tyngre hästar är trögare.
	  5. Styrutslaget rampas innan det används. En tangent är av eller på,
	     och utan rampen finns bara tre lägen: helt vänster, rakt, helt
	     höger. Med den doserar man svängen genom hur länge man håller, och
	     en gamepadspak som redan står halvvägs rampas mot just halvvägs.

	Marken sköts av Humanoid. Det är medvetet: Roblox löser sluttningar,
	kanter och trappor bättre än en egen strålkastning gör, och det som
	känns fordonsaktigt kommer från styrmodellen — inte från Humanoid.
]]

local RunService = game:GetService("RunService")

local Core = require(game:GetService("ReplicatedStorage").HorseCore)
local Types = require(game:GetService("ReplicatedStorage").HorseCore.Types)
local Config, Gaits, RigAdapter = Core.Config, Core.Gaits, Core.RigAdapter
local StateMachine = Core.StateMachine

local MovementController = {}
MovementController.__index = MovementController

local function approach(current: number, target: number, up: number, down: number, dt: number): number
	if target > current then
		return current + math.min(target - current, up * dt)
	end
	return current - math.min(current - target, down * dt)
end

--[[ Exponentiell utjämning som är oberoende av bildfrekvens. Ett rakt
     lerp med fast faktor ger olika känsla vid 30 och 144 Hz. ]]
local function smooth(current: number, target: number, tau: number, dt: number): number
	if tau <= 0 then return target end
	return current + (target - current) * (1 - math.exp(-dt / tau))
end

function MovementController.new(rig: Types.Rig, stats: { [string]: any })
	local self = setmetatable({}, MovementController)
	self.rig = rig
	self.stats = stats
	self.temperament = Config.TEMPERAMENTS[stats.Temperament] or Config.TEMPERAMENTS.Calm
	self.machine = StateMachine.new()
	self.jumpReady = 0
	self.ceiling = "gallop"

	local heading = math.atan2(rig.root.CFrame.LookVector.X, rig.root.CFrame.LookVector.Z)
	self.loco = {
		speed = 0, heading = heading, turnRate = 0, lean = 0,
		gait = "halt", targetGait = "halt", state = "Idle",
		phase = 0, airborne = false, grounded = true,
		slope = Vector3.yAxis, stamina = stats.MaxStamina,
	} :: Types.Locomotion

	self.slopePitch = 0
	self.steerInput = 0        -- rampat styrutslag, se _steer nedan
	return self
end

--[[ Styrutslaget mellan tangent och sväng. Tar snabbare än det släpper:
     att börja svänga ska kännas omedelbart, att sluta svänga ska kännas
     som att hästen rätar upp sig — inte som att någon släpper ett reglage. ]]
function MovementController:_steer(raw: number, dt: number): number
	local M = Config.MOVEMENT
	local tau = if math.abs(raw) > math.abs(self.steerInput)
		then M.SteerTauPress else M.SteerTauRelease
	self.steerInput = smooth(self.steerInput, raw, tau, dt)
	if math.abs(self.steerInput) < 0.004 then self.steerInput = 0 end
	return self.steerInput
end

--[[ Vilken gångart spelaren begär. W från stillastående startar skritt,
     Shift/Ctrl stegar, S rullar ned och backar till slut. Spelaren väljer
     alltså gångart, aldrig ett exakt tempo — det är skillnaden mot en
     gaspedal, och det är därför hästen känns som en häst. ]]
function MovementController:_targetGait(intent: Types.Intent): string
	local index = Gaits.index(self.loco.targetGait)

	if intent.gaitUp then index += 1 end
	if intent.gaitDown then index -= 1 end

	if intent.forward > 0.5 and index <= 1 then
		index = 2                                   -- W ur halt startar skritt
	elseif intent.forward < -0.5 then
		index -= 1                                   -- S rullar ned en gångart
	end

	local ceilingIndex = Gaits.index(self.ceiling)
	index = math.clamp(index, 1, math.min(#Gaits.ORDER, ceilingIndex))
	return Gaits.byIndex(index)
end

function MovementController:step(intent: Types.Intent, dt: number)
	local loco = self.loco
	local rig = self.rig
	local stats = self.stats
	local M = Config.MOVEMENT

	loco.targetGait = self:_targetGait(intent)
	local gait = Gaits.get(loco.targetGait)

	--[[ ── Tempo ──────────────────────────────────────────────────────
	     Målet är gångartens hemtempo, med ett litet spann som ryttaren kan
	     skjuta inom. Hästen får aldrig ligga still mellan två gångarter. ]]
	local reverse = loco.targetGait == "halt" and intent.forward < -0.5
	local target = if reverse then -M.ReverseSpeed else gait.norm
	if not reverse and gait.norm > 0 then
		target += intent.forward * (gait.max - gait.norm) * 0.35
		target = math.clamp(target, gait.min, gait.max) * (0.85 + 0.30 * stats.Speed)
	end

	local accelScale = (0.65 + 0.70 * stats.Acceleration) * self.temperament.accelBias
	local up = gait.accel * accelScale
	local down = gait.retard * accelScale
	if intent.forward < -0.5 then
		down += M.BrakeExtra
	end
	loco.speed = approach(loco.speed, target, up, down, dt)

	--[[ ── Sväng ──────────────────────────────────────────────────────
	     Grundsvarvheten stiger med farten, men gångartens turn-faktor drar
	     ned den mer, så nettoresultatet är vidare svängar i högre fart.
	     Svängen tar tag gradvis — utan det snäpper hästen runt hörn. ]]
	local speedAbs = math.abs(loco.speed)
	local base = math.clamp(M.TurnRateBase + M.TurnRateGain * speedAbs, M.TurnRateMin, M.TurnRateMax)
	local steer = self:_steer(intent.steer, dt)
	local wanted = steer * base * gait.turn * (0.70 + 0.60 * stats.Agility)
	if loco.speed < -0.05 then
		wanted = -wanted                              -- backar man styr man spegelvänt
	end
	loco.turnRate = approach(loco.turnRate, wanted, M.TurnAccel, M.TurnAccel * 1.4, dt)
	loco.heading = (loco.heading + loco.turnRate * dt) % (2 * math.pi)

	--[[ ── Lutning ─────────────────────────────────────────────────────
	     Proportionell mot svängkraften, alltså turnRate × fart. Klampad så
	     att den aldrig ser ut som en motorcykel. ]]
	local leanTarget = math.clamp(loco.turnRate * speedAbs * M.LeanGain, -M.LeanMax, M.LeanMax)
	loco.lean = smooth(loco.lean, leanTarget, M.LeanTau, dt)

	--[[ ── Mark ────────────────────────────────────────────────────────
	     En strålkastning per bildruta och häst, inte fyra. Normalen jämnas
	     ut hårt: utan det skakar kroppen på varje liten terrängkant. ]]
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { rig.model }
	local hit = workspace:Raycast(rig.root.Position, Vector3.new(0, -M.ProbeDepth, 0), params)

	loco.grounded = hit ~= nil
	local normal = if hit then hit.Normal else Vector3.yAxis
	loco.slope = loco.slope:Lerp(normal, 1 - math.exp(-dt / M.SlopeTau))

	local forwardVector = Vector3.new(math.sin(loco.heading), 0, math.cos(loco.heading))
	local grade = -loco.slope:Dot(forwardVector)
	self.slopePitch = smooth(self.slopePitch, grade * M.SlopeAlign, M.SlopeTau, dt)

	--[[ ── Hopp ───────────────────────────────────────────────────────
	     Kräver fart och mark, och har nedkylning. Ingen luftdubbelhopp. ]]
	local hum = rig.humanoid
	local jumpFired = false
	self.jumpReady = math.max(0, self.jumpReady - dt)
	if intent.jump and hum and loco.grounded and self.jumpReady <= 0
		and speedAbs >= M.JumpMinSpeed then
		hum.Jump = true
		self.jumpReady = M.JumpCooldown
		jumpFired = true
	end

	loco.airborne = if hum then
		hum:GetState() == Enum.HumanoidStateType.Freefall
			or hum:GetState() == Enum.HumanoidStateType.Jumping
		else false

	--[[ ── Tillstånd och fas ──────────────────────────────────────────── ]]
	loco.state = self.machine:step({
		speed = loco.speed,
		turnRate = loco.turnRate,
		airborne = loco.airborne,
		braking = intent.forward < -0.5,
		jumpFired = jumpFired,
	}, dt)
	loco.gait = self.machine.gait
	loco.phase = (loco.phase + Gaits.beatRate(loco.gait, speedAbs) * dt) % 1

	--[[ ── Ut i världen ───────────────────────────────────────────────
	     Humanoid får riktningen som VI har räknat fram, inte spelarens råa
	     input. AutoRotate vrider mot den, och eftersom riktningen bara
	     ändras i vår egen svängtakt syns aldrig Humanoids snärt.

	     AutoRotate slutar vrida vid noll fart. Förut löstes det med ett
	     golv på 0,35 studs/s, men då gled hästen synligt i sidled medan den
	     vände — en krypning som syns i alla stillastående lägen. I stället
	     vrids roten direkt när farten är noll: samma vändning, ingen glidning.
	     Det krockar inte med kroppens lutning, som ligger i rootJoint.C0. ]]
	if hum then
		local studs = Config.toStuds(math.abs(loco.speed))
		local turningInPlace = math.abs(loco.turnRate) > 0.05 and studs < 0.35
		if turningInPlace then
			hum.WalkSpeed = 0
			local root = rig.root
			root.CFrame = CFrame.new(root.CFrame.Position) * CFrame.Angles(0, loco.heading, 0)
		else
			hum.WalkSpeed = studs
		end
		local dir = if loco.speed < -0.05 then -forwardVector else forwardVector
		hum:Move(dir, false)
	end

	RigAdapter.setBodyTilt(rig, loco.lean, self.slopePitch)
end

function MovementController:setCeiling(gait: string)
	self.ceiling = gait
end

function MovementController:release()
	self.steerInput = 0
	local hum = self.rig.humanoid
	if hum then
		hum.WalkSpeed = 0
		hum:Move(Vector3.zero, false)
	end
	RigAdapter.setBodyTilt(self.rig, 0, 0)
end

return MovementController
