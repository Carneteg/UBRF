--!strict
--[[
	Ridkameran.

	Ligger bakom och över hästen, och ändrar sig med gångarten: närmare och
	lugnare i skritt, längre bak och vidare i fyrsprång. Synfältet öppnar
	sig svagt i fart — det är den billigaste och tydligaste fartkänslan som
	finns, och den kostar ingenting i prestanda.

	Ingen skakning. Skakning läser som skada, inte som fart, och gör folk
	åksjuka i förstapersonsnära vinklar.
]]

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Core = require(game:GetService("ReplicatedStorage").HorseCore)
local Types = require(game:GetService("ReplicatedStorage").HorseCore.Types)
local Config, Gaits = Core.Config, Core.Gaits

local CameraController = {}
CameraController.__index = CameraController

local function smooth(current: number, target: number, tau: number, dt: number): number
	if tau <= 0 then return target end
	return current + (target - current) * (1 - math.exp(-dt / tau))
end

function CameraController.new(rig: Types.Rig)
	local self = setmetatable({}, CameraController)
	self.rig = rig
	self.camera = Workspace.CurrentCamera
	self.dist = Config.CAMERA.BaseFov and 15 or 15
	self.height = 5.2
	self.fov = Config.CAMERA.BaseFov
	self.previousType = self.camera.CameraType
	self.previousFov = self.camera.FieldOfView
	self.camera.CameraType = Enum.CameraType.Scriptable
	return self
end

function CameraController:step(loco: Types.Locomotion, dt: number)
	local gait = Gaits.get(loco.gait)
	local C = Config.CAMERA

	self.dist = smooth(self.dist, gait.camera.dist, C.Tau, dt)
	self.height = smooth(self.height, gait.camera.height, C.Tau, dt)
	self.fov = smooth(self.fov, math.min(C.BaseFov + gait.camera.fov, C.MaxFov), C.Tau, dt)

	local root = self.rig.root
	local heading = loco.heading
	local back = Vector3.new(-math.sin(heading), 0, -math.cos(heading))
	local right = Vector3.new(math.cos(heading), 0, -math.sin(heading))

	--[[ Kameran hänger efter i svängen i stället för att sitta stelt bakom.
	     Det är den detaljen som gör att svängar läses som svängar. ]]
	local trail = right * math.clamp(-loco.turnRate, -1, 1) * C.Shoulder

	--[[ Blicken går en bit in i svängen och längre fram ju fortare man
	     rider. Utan det tittar kameran på var hästen nyss var, och i en
	     volt ser man aldrig vart man är på väg. ]]
	local fram = Vector3.new(math.sin(heading), 0, math.cos(heading))
	local lead = right * math.clamp(loco.turnRate, -1.5, 1.5) * C.LeadGain
	local focus = root.Position + Vector3.new(0, 2, 0)
		+ fram * (C.LookAhead + math.abs(loco.speed) * C.SpeedLead) + lead
	local wanted = root.Position + back * self.dist + Vector3.new(0, self.height, 0) + trail

	--[[ Håll kameran ur väggar: en strålkastning från hästen ut mot
	     kamerapunkten, och dra in den om något ligger emellan. ]]
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { self.rig.model, game.Players.LocalPlayer.Character }
	local origin = root.Position + Vector3.new(0, 2, 0)
	local hit = Workspace:Raycast(origin, wanted - origin, params)
	if hit then
		wanted = hit.Position + (origin - wanted).Unit * 1.2
	end

	--[[ Lätt dämpning på själva kamerapositionen. Förut satt den klistrad
	     på roten och ärvde varje skutt i fysiken; nu filtreras skakningen
	     bort utan att styrningen känns fördröjd — tau är kort med flit. ]]
	local f = 1 - math.exp(-dt / math.max(C.FollowTau, 0.0001))
	self.pos = if self.pos then self.pos:Lerp(wanted, f) else wanted
	self.blick = if self.blick then self.blick:Lerp(focus, f) else focus

	self.camera.CFrame = CFrame.lookAt(self.pos, self.blick)
	self.camera.FieldOfView = self.fov
end

function CameraController:release()
	self.camera.CameraType = self.previousType
	self.camera.FieldOfView = self.previousFov
	local character = game.Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		self.camera.CameraSubject = humanoid
	end
end

return CameraController
