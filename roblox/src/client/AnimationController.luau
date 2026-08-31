--!strict
--[[
	Animationslagret.

	Skilt från rörelsen med flit: den här modulen läser tillstånd och fart,
	och rör aldrig fysik. Byter man animationspaket är det bara den här
	modulen och AnimationConfig som berörs.

	Tre saker gör att det ser dyrt ut i stället för billigt:

	  1. Övertoning mellan spår. Ett spår stannar aldrig tvärt.
	  2. De cykliska gångarterna spolas av `loco.phase`, alltså av
	     tillryggalagd sträcka, inte av en klocka. Hovarna landar därmed där
	     marken är även när bildfrekvensen svajar. Utan det ser hästen ut att
	     åka skridskor.
	  3. Händelseklippen (hopp, landning, stopp, vändning) spelas av sin egen
	     klocka med farten som fart, klampad till [0,72 ; 1,32]. Räcker inte
	     bandet ska gångarten byta i stället — det är därför gångartsbanden
	     överlappar.
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

	--[[ ── VEM SPOLAR KLIPPET ───────────────────────────────────────────
	     Förut stod det bara `AdjustSpeed(playbackRate)` här, alltså:
	     klippet spelas av Roblox egen klocka, och vi justerar farten.

	     Det gav TVÅ klockor i samma häst. `loco.phase` räknas distanslåst i
	     `MovementController` — tillryggalagd sträcka delat med gångartens
	     cykellängd — och `SoundController` lägger hovljuden på just den
	     fasen. Benen följde en annan tid än ljudet.

	     De gled isär precis när det syns mest. `playbackRate` är klampad
	     till [0,72 ; 1,32]: utanför bandet går benen med fel takt medan
	     fasen fortsatte rätt. Och `AdjustSpeed` är en ÖNSKAN — blir
	     bildrutan lång, hästen krockar eller terrängen bromsar, så fortsatte
	     klippet ändå medan hästen stod still. Hovljudet tystnade, benen
	     trampade vidare i luften.

	     Nu spolas de cykliska gångarterna av fasen i stället. `TimePosition`
	     är inte en önskan utan ett läge, och samma sträcka ger samma
	     benställning oavsett vad bildfrekvensen gjorde på vägen. Ljud, damm
	     och ben läser därmed EN klocka, och den klockan är marken.

	     `AdjustSpeed(0)` är nödvändig och inte prydnad: utan den skulle
	     Roblox egen framdrivning ligga kvar ovanpå vår spolning och lägga
	     till en halv bildruta i taget — samma glid som vi just tog bort.

	     `Length` är 0 innan klippet hämtats från servern. Då faller vi
	     tillbaka på klockan: hellre en häst som går något fel de första
	     bildrutorna än en häst som står fastfrusen i ruta ett. ]]
	local track = self.tracks[key]
	if track and track.IsPlaying then
		if entry.phase and track.Length > 0 then
			track:AdjustSpeed(0)
			track.TimePosition = (loco.phase % 1) * track.Length
		else
			track:AdjustSpeed(Gaits.playbackRate(loco.gait, math.abs(loco.speed)))
		end
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
