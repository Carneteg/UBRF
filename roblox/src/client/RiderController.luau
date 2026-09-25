--!strict
--[[
	Ryttaren i sadeln.

	Kroppen sitter fast i sitsen — det sköter Roblox. Den här modulen gör
	det som skiljer en ryttare från en last: händerna hittar tyglarna och
	fötterna hittar stigbyglarna, med IKControl i stället för fastsvetsade
	lemmar. Svetsar man fast varje lem i en pose blir ryttaren en docka som
	inte reagerar på något.

	Saknas attachment-punkterna händer ingenting — då sitter ryttaren i
	sadeln i sin vanliga pose. Det är rätt sorts degradering.
]]

local Players = game:GetService("Players")

local Core = require(game:GetService("ReplicatedStorage").HorseCore)
local Types = require(game:GetService("ReplicatedStorage").HorseCore.Types)
local RigAdapter = Core.RigAdapter
local Gangfas, RidKanon, Config = Core.Gangfas, Core.RidKanon, Core.Config

local RiderController = {}
RiderController.__index = RiderController

--[[ Vilken IK-kedja som ska nå vilken punkt på hästen.

	══ HÄNDERNA SIKTAR PÅ HANDLÄGET, INTE PÅ BETTET ═══════════════════

	Förut stod `LeftReinAttachment`/`RightReinAttachment` här — alltså
	BETTET, i hästens mun. Uppmätt på K3 ligger bettet 3,3 studs framför
	och 1,5 studs under sadelpunkten. IK drar handen dit, handen drar
	underarmen, underarmen överarmen och till slut hela överkroppen: det
	är den framstupa ryttaren granskningen såg, cirka 45 grader framåt,
	sittande på manken i stället för i sadeln.

	Felet var inte IK-vikten utan MÅLET. En ryttare sträcker sig inte
	efter bettet; hon håller tyglarna över manken med böjd armbåge, och
	det är TYGELN som spänner mellan handen och bettet. Kedjorna siktar
	därför på `handV`/`handH` — en punkt som ligger strax framför och
	ovanför sadeln — och `TackRigg.byggTyglar` drar tygeln från bettet
	hit, så att bilden hänger ihop.

	Fotmålen är oförändrade som NAMN. Punkterna de pekar på har däremot
	flyttats bakåt i `Riggprofiler`; se motiveringen där. ]]
local CHAINS = {
	{ name = "LeftHand",  endEffector = "LeftHand",  target = "LeftHandAttachment",     chainRoot = "LeftUpperArm" },
	{ name = "RightHand", endEffector = "RightHand", target = "RightHandAttachment",    chainRoot = "RightUpperArm" },
	{ name = "LeftFoot",  endEffector = "LeftFoot",  target = "LeftStirrupAttachment",  chainRoot = "LeftUpperLeg" },
	{ name = "RightFoot", endEffector = "RightFoot", target = "RightStirrupAttachment", chainRoot = "RightUpperLeg" },
}

function RiderController.new(rig: Types.Rig)
	local self = setmetatable({}, RiderController)
	self.rig = rig
	self.controls = {} :: { IKControl }
	self.track = nil :: AnimationTrack?
	return self
end

function RiderController:attach(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	local animator = humanoid:FindFirstChildOfClass("Animator")

	--[[ Ridposen spelas med Action-prioritet så att den vinner över
	     Roblox egen sittanimation, som annars lägger ryttaren i stolspose. ]]
	local id = self.rig.animConfig and self.rig.animConfig:GetAttribute("RiderSeated")
	if animator and typeof(id) == "string" and id ~= "" then
		local anim = Instance.new("Animation")
		anim.AnimationId = if id:match("^rbxassetid://") then id else "rbxassetid://" .. id
		local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
		if ok and track then
			track.Priority = Enum.AnimationPriority.Action
			track.Looped = true
			track:Play(0.25)
			self.track = track
		end
	end

	--[[ IK i stället för svetsar. Roblox löser kedjan varje bildruta, så
	     händerna följer med när hästens huvud rör sig och fötterna hänger
	     kvar i stigbyglarna även när kroppen gungar. ]]
	for _, chain in CHAINS do
		local target = self.rig.attachments[chain.target]
		local effector = character:FindFirstChild(chain.endEffector)
		local root = character:FindFirstChild(chain.chainRoot)
		if target and effector and root then
			local control = Instance.new("IKControl")
			control.Name = "Horse_" .. chain.name
			control.Type = Enum.IKControlType.Position
			control.EndEffector = effector
			control.ChainRoot = root
			control.Target = target
			control.Weight = 0.85
			control.Parent = humanoid
			table.insert(self.controls, control)
		end
	end
end

--[[ ── Sekundärrörelsen ────────────────────────────────────────────
     De ofrivilliga rörelser en kropp gör när den sitter på en annan
     kropp som rör sig. Läggs OVANPÅ sitsen, aldrig i stället för den.

       · TRÖGHETEN — accelererar hästen hamnar ryttaren efter och lutar
         bakåt en aning; bromsar hästen kommer hon före. Signalen är
         tempoderivatan, hårt utjämnad: rå derivata hackar, och en
         ryttare som ryckte per bildruta skulle läsa som ragdoll.
       · BALANSEN — i en sväng söker hon sig inåt, men bara en tredjedel
         av hästens lutning. Kroppen ska följa hästen, inte tävla med den.

     Talen är desamma som webbversionens, så att en spelare som byter
     plattform känner igen sig: ±0,055 rad (3,2°) tröghet och ±0,030
     (1,7°) balans. Utan taken blir en hård inbromsning en kullerbytta.

     Rotationen läggs på HumanoidRootPart via en egen Motor6D-offset om
     riggen har en; saknas den händer ingenting, vilket är rätt sorts
     degradering — samma regel som resten av modulen. ]]
local INERTIA_GAIN = 0.014
local INERTIA_MAX = 0.055
local BALANCE_SHARE = 0.34
local BALANCE_MAX = 0.030
local ACCEL_TAU = 0.18

function RiderController:step(loco: Types.Locomotion, dt: number)
	local give = 1 - math.clamp(math.abs(loco.speed) / 14, 0, 0.35)
	for _, control in self.controls do
		control.Weight = 0.85 * give
	end

	--[[ Tempoderivatan, utjämnad. Klampningen på ±6 m/s² finns för att
	     ett gångartsbyte eller en kollision annars ger en spik. ]]
	local prev = self.lastSpeed or loco.speed
	self.lastSpeed = loco.speed
	local raw = math.clamp((loco.speed - prev) / math.max(dt, 1e-4), -6, 6)
	self.accel = (self.accel or 0) + (raw - (self.accel or 0))
		* (1 - math.exp(-dt / ACCEL_TAU))

	self.pitch = math.clamp(-(self.accel) * INERTIA_GAIN, -INERTIA_MAX, INERTIA_MAX)
	self.roll = math.clamp(loco.lean * BALANCE_SHARE, -BALANCE_MAX, BALANCE_MAX)
	RigAdapter.setRiderLean(self.rig, self.roll, self.pitch)
	self:_gangartsSits(loco, dt)
end

--[[ ── SITSEN FÖLJER GÅNGARTEN (#264 GAIT_READABILITY_AND_UGNETA) ────────

	Automatisk grundsits för nybörjaren: ingen knapp i takt. I skritt en
	liten sidledes följning ur höften, i trav LÄTTRIDNING — EN uppresning
	per hel travcykel, medan det yttre frambenet förs fram — och i galopp
	en sittande ryttare som följer bålens rullning en gång per cykel.

	VARFÖR SÄTETS SVETS OCH INTE `RiderJoint`: mätt i Studio har K3:s
	`RiderJoint` ingen `Part1`, så den lutningen når ingen del. Sätets
	`SeatWeld` (Part0 = sätet, Part1 = ryttarens rot) är den led som faktiskt
	håller ryttaren, och C0 är ett lokalt värde: den ridna hästen ägs av
	ryttarens klient. Kameran följer hästens rot och gungar inte med.

	Fasen är hästens (`loco.phase`), densamma som ben och hovslag läser, och
	tabellen är `RidKanon.GANGFAS`. Ingen egen klocka. ]]
local SITS_TAU = 0.25

function RiderController:_sitsSvets(): Weld?
	local seat: any = self.rig.seat
	local ok, w = pcall(function()
		return if seat then seat:FindFirstChild("SeatWeld") else nil
	end)
	if ok and w and w:IsA("Weld") then
		if self.svets ~= w then
			self.svets = w
			self.svetsBas = w.C0
		end
		return w
	end
	self.svets = nil
	return nil
end

function RiderController:_gangartsSits(loco: Types.Locomotion, dt: number)
	local namn = Gangfas.monsterNamn(loco.gait, loco.lead, loco.ryggar)
	local monster = Gangfas.monster(namn)
	local lyft, gung, vagg = 0, 0, 0
	local sits = "seated"
	local tpi = math.pi * 2
	if monster and not loco.ryggar and loco.grounded and not loco.airborne then
		if loco.gait == "trot" then
			--[[ Okänt varv (utanför banan): behåll senast giltiga yttre ben.
			     Det bedöms aldrig som rätt eller fel här. ]]
			local yttre = Gangfas.yttreFram(loco.varv) or self.yttre or "LF"
			self.yttre = yttre
			lyft = Gangfas.lattridning(monster, loco.phase, yttre)
			sits = "rising"
		elseif loco.gait == "canter" or loco.gait == "gallop" then
			gung = math.sin(tpi * loco.phase) * 0.035
		elseif loco.gait == "walk" then
			vagg = math.sin(tpi * loco.phase) * 0.015
		end
	end
	--[[ IN I lättridningen: vikten växer mjukt, och uppresningen följer
	     traven exakt (en per cykel) gånger vikten.

	     UT UR den (#264 GAIT_UGNETA_REVIEW_R1): det FAKTISKA lyftet klingar
	     av. Förut blev `lyft` noll i samma bildruta som gångarten byttes,
	     och vikten multiplicerades med noll — mätt i bänken: 0,33 studs
	     till 0 på en bildruta, så att ryttaren föll i sadeln. Nu går hon ned
	     ur den höjd hon faktiskt hade, med samma tidskonstant. ]]
	local vill = if sits == "rising" then 1 else 0
	local mjuk = 1 - math.exp(-dt / SITS_TAU)
	self.lyftVikt = (self.lyftVikt or 0) + (vill - (self.lyftVikt or 0)) * mjuk
	self.sits = sits
	if sits == "rising" then
		self.uppe = lyft * self.lyftVikt
	else
		self.uppe = (self.uppe or 0) * (1 - mjuk)
		if self.uppe < 1e-4 then self.uppe = 0 end
	end
	local w = self:_sitsSvets()
	if w and self.svetsBas then
		local dy = self.uppe * RidKanon.LATTRIDNING.hojd_m * Config.STUDS_PER_METRE
		--[[ I SÄTETS RUM, alltså FÖRE basen. Mätt i Studio: K3:s SeatWeld.C0
		     är vriden 90° kring X, och `bas * CFrame.new(0, dy, 0)` flyttade
		     därför ryttaren längs svetsens lokala Y — i världens Z-led —
		     medan hon skulle upp. Bänkens CFrame-stubbe har ingen riktig
		     rotationsmatris och kunde inte se det. ]]
		w.C0 = CFrame.new(0, dy, 0) * CFrame.Angles(gung, 0, vagg) * (self.svetsBas :: CFrame)
	end
end

--[[ Provets och panelens fönster in: vilken sits, och hur högt hon står. ]]
function RiderController:sitsLage(): (string, number)
	return self.sits or "seated", self.uppe or 0
end

function RiderController:release()
	self.accel, self.pitch, self.roll, self.lastSpeed = 0, 0, 0, nil
	RigAdapter.setRiderLean(self.rig, 0, 0)
	--[[ Sätets svets tillbaka till sitt utgångsläge, om den finns kvar. ]]
	local w = self.svets
	if w and self.svetsBas and w.Parent then
		w.C0 = self.svetsBas :: CFrame
	end
	self.svets, self.svetsBas, self.sits, self.uppe, self.lyftVikt = nil, nil, nil, 0, 0
	for _, control in self.controls do
		control:Destroy()
	end
	table.clear(self.controls)
	if self.track then
		self.track:Stop(0.25)
		self.track = nil
	end
end

return RiderController
