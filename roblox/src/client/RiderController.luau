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

--[[ Liten reaktion i sadeln: ryttaren följer med i lutningen. Vikten på
     IK sänks i fyrsprång så att armarna får ge efter i stället för att stå
     stelt fast i tyglarna. ]]
function RiderController:step(loco: Types.Locomotion, dt: number)
	local give = 1 - math.clamp(math.abs(loco.speed) / 14, 0, 0.35)
	for _, control in self.controls do
		control.Weight = 0.85 * give
	end
end

function RiderController:release()
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
