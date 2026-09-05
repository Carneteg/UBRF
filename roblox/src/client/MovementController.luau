--!strict
--[[
	Rörelsen — den modul som avgör om hästen känns som ett djur eller ett fordon.

	Körs hos den som äger nätverket, alltså ryttarens egen klient. Servern
	validerar resultatet men simulerar det inte, för annars ligger latensen
	i varje styrutslag och hästen känns som en båt.

	Fyra saker gör skillnaden mot ett fordon:

	  1. Tempot dras mot gångartens hemtempo, inte mot en knapp. Släpper man
	     W stannar hästen inte — den rullar ned i skritt.
	  2. Styraxeln ber om en KURVATUR, inte om en vridhastighet. Radien
	     blir 1/kurvatur oavsett fart, så en snabbare gångart ger en
	     vidare båge av sig själv i stället för genom en motkraft.
	  3. Svängen tar tag gradvis, så inget snäpper till 90 grader.
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
	self.curvature = 0         -- aktuell kurvatur, 1/m
	self.lastPos = nil         -- förra bildrutans läge, driver fasen
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

	--[[ CUE OCH ÖVERGÅNGSTID (G02-A, PO 2026-09-05). Modellen fanns redan
	     — spelaren väljer gångart, inte tempo — men den mättes inte. Här
	     bokförs NÄR begäran ändrades och hur lång tid hästen tog på sig,
	     så telemetrin kan visa samma sak som webben. Ingen regel ändras. ]]
	loco.tid = (loco.tid or 0) + dt
	local forraMal = loco.targetGait
	loco.targetGait = self:_targetGait(intent)
	if loco.targetGait ~= forraMal then
		local upp = Gaits.index(loco.targetGait) > Gaits.index(forraMal)
		loco.cue = if upp then "framåt" else "nedåt"
		loco.cueTid = loco.tid
		loco._overgangKlar = false
	end
	if not loco._overgangKlar and loco.gait == loco.targetGait and loco.cueTid then
		loco.senasteOvergang = loco.tid - loco.cueTid
		loco._overgangKlar = true
	end
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
	     Kurvaturen är det spelaren styr: hur snävt hästen böjer sig, i
	     1/meter. Gångartens turn-faktor sätter taket — en häst i fyrsprång
	     böjer sig inte som en häst i skritt — och vridhastigheten faller
	     ut som kurvatur × tempo. Radien blir därmed 1/kurvatur oavsett
	     fart, alltså vidare bågar i högre gångart utan att någon motkraft
	     behöver räknas fram.

	     Kurvaturen tar tag snabbare än den släpper: att lägga sig i en
	     båge går fortare än att räta upp sig ur den, både i verkligheten
	     och i känslan. ]]
	local speedAbs = math.abs(loco.speed)
	local steer = self:_steer(intent.steer, dt)
	local kappaCeiling = M.CurvatureMax * gait.turn * (0.70 + 0.60 * stats.Agility)
	local kappaWanted = steer * kappaCeiling
	if loco.speed < -0.05 then
		kappaWanted = -kappaWanted                    -- backar man styr man spegelvänt
	end
	local kappaTau = if math.abs(kappaWanted) > math.abs(self.curvature)
		then M.CurvatureTauPress else M.CurvatureTauRelease
	self.curvature = smooth(self.curvature, kappaWanted, kappaTau, dt)
	if math.abs(self.curvature) < 0.0015 then self.curvature = 0 end
	loco.turnRate = self.curvature * loco.speed
	--[[ Vändning på stället läggs till där farten är låg. Utan den kan en
	     stående häst inte vrida sig alls, eftersom omega är kurvatur
	     gånger tempo — och tillståndsmaskinen har ett eget läge för just
	     att vända på stället. Termen tonas ut linjärt och är helt borta
	     när hästen går, så den kan aldrig ge en pivot under ritt. ]]
	if speedAbs < M.TurnInPlaceBelow then
		local andel = 1 - speedAbs / M.TurnInPlaceBelow
		loco.turnRate += steer * M.TurnInPlaceRate
			* (0.70 + 0.60 * stats.Agility) * andel
	end
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

	--[[ ── Fasen följer MARKEN ────────────────────────────────────────
	     Förut drevs fasen av beatRate × dt, alltså av den fart vi BEGÄRT.
	     Nu mäts hur långt hästen faktiskt kom sedan förra bildrutan, och
	     fasen är den sträckan delad med gångartens cykellängd. Krockar
	     hästen med något eller bromsas av terrängen slutar hovarna att
	     trampa i luften, och stillastående häst går inte på stället.

	     Rootens läge är i studs; cykellängden i meter. ]]
	local pos = rig.root.Position
	local moved = if self.lastPos then (pos - self.lastPos).Magnitude else 0
	self.lastPos = pos
	local cycle = Gaits.cycleLength(loco.gait)
	if cycle > 0 then
		loco.phase = (loco.phase + (moved / Config.STUDS_PER_METRE) / cycle) % 1
	end

	--[[ ── Ut i världen ───────────────────────────────────────────────
	     VRIDNINGEN HAR EN ÄGARE, OCH DET ÄR DEN HÄR RADEN.

	     `HorseService` sätter `AutoRotate = false` med motiveringen att
	     spelet äger vridningen. Den här modulen räknade fram `loco.heading`
	     och lämnade sedan över till en AutoRotate som inte fanns — så bara
	     vändning på stället vred faktiskt riggen. Under ritt kunde
	     rörelsevektorn böja av medan hästen fortsatte peka rakt fram: en
	     häst som åker i sidled genom svängen.

	     Nu skrivs kursen på roten varje bildruta, i alla lägen. Positionen
	     lämnas orörd — `Humanoid:Move` sköter förflyttningen, fysiken sköter
	     höjden — och roten hålls upprätt: kroppens lutning och sluttningens
	     pitch ligger i `rootJoint.C0`, inte här. Skriver man dem på samma
	     ställe går den ena inte att trimma utan att den andra ändras.

	     `loco.heading` är redan utjämnad genom kurvaturens tidskonstanter,
	     så det finns ingen snärt att dämpa här. Att i stället slå på
	     AutoRotate igen vore att lämna vridtakten till Roblox, och det är
	     precis den fordonskänsla gaten ska bort ifrån. ]]
	local root = rig.root
	root.CFrame = CFrame.new(root.CFrame.Position) * CFrame.Angles(0, loco.heading, 0)

	if hum then
		--[[ Vändning på stället: farten noll, men kursen ändras ändå av
		     raden ovan. Golvet på 0,35 studs/s som fanns förut gav en
		     synlig sidledsglidning i alla stillastående lägen. ]]
		local studs = Config.toStuds(math.abs(loco.speed))
		local turningInPlace = math.abs(loco.turnRate) > 0.05 and studs < 0.35
		hum.WalkSpeed = if turningInPlace then 0 else studs
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
	self.curvature = 0
	self.lastPos = nil
	local hum = self.rig.humanoid
	if hum then
		hum.WalkSpeed = 0
		hum:Move(Vector3.zero, false)
	end
	RigAdapter.setBodyTilt(self.rig, 0, 0)
end

return MovementController
