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

local RiderController = {}
RiderController.__index = RiderController

--[[ Vilken IK-kedja som ska nå vilken punkt på hästen. ]]
local CHAINS = {
	{ name = "LeftHand",  endEffector = "LeftHand",  target = "LeftReinAttachment",     chainRoot = "LeftUpperArm" },
	{ name = "RightHand", endEffector = "RightHand", target = "RightReinAttachment",    chainRoot = "RightUpperArm" },
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
end

function RiderController:release()
	self.accel, self.pitch, self.roll, self.lastSpeed = 0, 0, 0, nil
	RigAdapter.setRiderLean(self.rig, 0, 0)
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
