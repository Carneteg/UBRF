--!strict
--[[
	Animationslagret.

	Skilt från rörelsen med flit: den här modulen läser tillstånd och fart,
	och rör aldrig fysik. Byter man animationspaket är det bara den här
	modulen och AnimationConfig som berörs.

	Tre saker gör att det ser dyrt ut i stället för billigt:

	  1. Övertoning mellan spår. Ett spår stannar aldrig tvärt.
	  2. Uppspelningshastigheten följer farten, så hovarna landar där marken
	     är. Utan det ser hästen ut att åka skridskor.
	  3. Klippet sträcks bara inom ±30 %. Räcker inte det ska gångarten
	     byta i stället — det är därför gångartsbanden överlappar.
]]

local Core = require(game:GetService("ReplicatedStorage").HorseCore)
local Types = require(game:GetService("ReplicatedStorage").HorseCore.Types)
local Config, Gaits, RigAdapter = Core.Config, Core.Gaits, Core.RigAdapter

local AnimationController = {}
AnimationController.__index = AnimationController

function AnimationController.new(rig: Types.Rig, stats: { [string]: any })
	local self = setmetatable({}, AnimationController)
	self.rig = rig
	self.stats = stats
	self.temperament = Config.TEMPERAMENTS[stats.Temperament] or Config.TEMPERAMENTS.Calm
	self.tracks = {} :: { [string]: AnimationTrack }
	self.current = nil :: string?
	self.idleTimer = 0
	self.variantTrack = nil :: AnimationTrack?
	self:_load()
	return self
end

--[[ Id:na är attribut på AnimationConfig, inte konstanter i kod. Saknas ett
     id hoppas spåret över tyst — hästen rör sig ändå, den blir bara stel i
     just det tillståndet. Ett saknat id ska aldrig stoppa spelet. ]]
function AnimationController:_load()
	local config = self.rig.animConfig
	for _, key in Config.ANIMATION_KEYS do
		local id = Config.attr(config, key, "")
		if typeof(id) == "string" and id ~= "" then
			local anim = Instance.new("Animation")
			anim.Name = key
			anim.AnimationId = if id:match("^rbxassetid://") then id else "rbxassetid://" .. id
			local ok, track = pcall(function()
				return self.rig.animator:LoadAnimation(anim)
			end)
			if ok and track then
				self.tracks[key] = track
			else
				warn(("[Horse] Kunde inte ladda animationen %s (%s)"):format(key, anim.AnimationId))
			end
		end
	end
	self.missing = {}
	for _, key in Config.ANIMATION_KEYS do
		if not self.tracks[key] then
			table.insert(self.missing, key)
		end
	end
end

function AnimationController:_play(key: string, fade: number, looped: boolean)
	local track = self.tracks[key]
	if not track then return end
	track.Looped = looped
	track.Priority = Enum.AnimationPriority.Movement
	if not track.IsPlaying then
		track:Play(fade)
	end
end

function AnimationController:_stopAllExcept(key: string?, fade: number)
	for name, track in self.tracks do
		if name ~= key and track.IsPlaying and track ~= self.variantTrack then
			track:Stop(fade)
		end
	end
end

--[[ Idle-varianterna är det som gör att en stillastående häst ser levande
     ut i stället för fryst. De läggs ovanpå grund-idle med högre prioritet
     och tar slut av sig själva. Lynnet styr hur ofta de kommer. ]]
function AnimationController:_stepIdleVariation(loco: Types.Locomotion, dt: number)
	if loco.state ~= "Idle" then
		self.idleTimer = 0
		return
	end
	self.idleTimer += dt
	local interval = self.temperament.idleInterval * (0.7 + math.random() * 0.6)
	if self.idleTimer < interval then return end
	self.idleTimer = 0

	local candidates = {}
	for _, key in Config.IDLE_VARIANTS do
		if self.tracks[key] then table.insert(candidates, key) end
	end
	if #candidates == 0 then return end

	local track = self.tracks[candidates[math.random(#candidates)]]
	track.Looped = false
	track.Priority = Enum.AnimationPriority.Action
	track:Play(0.25)
	self.variantTrack = track
end

function AnimationController:step(loco: Types.Locomotion, dt: number)
	local entry = Config.STATE_ANIMATION[loco.state]
	if not entry then return end

	--[[ Sväng på stället har två klipp; välj efter riktning. ]]
	local key = entry.key
	if loco.state == "TurningInPlace" then
		key = if loco.turnRate < 0 then "TurnLeft" else "TurnRight"
		if not self.tracks[key] then key = "Idle" end
	end

	if key ~= self.current then
		self:_stopAllExcept(key, entry.fade)
		self:_play(key, entry.fade, entry.looped)
		self.current = key
	end

	local track = self.tracks[key]
	if track and track.IsPlaying then
		track:AdjustSpeed(Gaits.playbackRate(loco.gait, math.abs(loco.speed)))
	end

	self:_stepIdleVariation(loco, dt)
	self:_stepProcedural(loco, dt)
end

--[[ Procedurell påbyggnad. Subtil med flit: den ska kännas, inte synas.
     Skrivs efter att animationen uppdaterat benen. Saknas benen händer
     ingenting alls — då tappar man polish, inte spel. ]]
function AnimationController:_stepProcedural(loco: Types.Locomotion, dt: number)
	local gain = self.temperament.reactGain
	local speedFraction = math.clamp(math.abs(loco.speed) / 9, 0, 1)

	-- Halsen leder svängen något. En häst tittar dit den ska.
	local neckYaw = math.clamp(-loco.turnRate * 0.22, -0.20, 0.20) * gain
	RigAdapter.setBoneOffset(self.rig, "Neck01", CFrame.Angles(0, neckYaw * 0.5, 0))
	RigAdapter.setBoneOffset(self.rig, "Head", CFrame.Angles(0, neckYaw * 0.5, 0))

	-- Svansen svänger med farten.
	local t = os.clock()
	local swish = math.sin(t * (1.4 + speedFraction * 3.0)) * (0.05 + speedFraction * 0.10) * gain
	RigAdapter.setBoneOffset(self.rig, "TailBase", CFrame.Angles(0, swish, 0))

	-- Öronen rör sig oberoende, sällan och olika.
	RigAdapter.setBoneOffset(self.rig, "LeftEar",
		CFrame.Angles(math.sin(t * 0.9) * 0.05 * gain, 0, 0))
	RigAdapter.setBoneOffset(self.rig, "RightEar",
		CFrame.Angles(math.sin(t * 1.13 + 2.0) * 0.05 * gain, 0, 0))
end

function AnimationController:release()
	for _, track in self.tracks do
		if track.IsPlaying then track:Stop(0.2) end
	end
	self.current = nil
end

return AnimationController
