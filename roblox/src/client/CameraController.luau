--!strict
--[[
	Ridkameran.

	Ligger bakom och över hästen, och ändrar sig med gångarten: närmare och
	lugnare i skritt, längre bak och vidare i fyrsprång. Synfältet öppnar
	sig svagt i fart — det är den billigaste och tydligaste fartkänslan som
	finns, och den kostar ingenting i prestanda.

	Ingen skakning. Skakning läser som skada, inte som fart, och gör folk
	åksjuka i förstapersonsnära vinklar.

	Kameran har en EGEN kurs som följer hästens med en kort fördröjning.
	Läser den hästens kurs rakt av sitter den stelt fastskruvad i nacken,
	och varje styrutslag rycker hela bilden — det är den vanligaste
	orsaken till att en tredjepersonskamera känns instabil. Med en egen
	kurs svänger hästen först och bilden hinner ifatt.
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

--[[ Samma utjämning för en vinkel. Skillnaden räknas via den korta vägen
     runt cirkeln, annars snurrar kameran ett helt varv varje gång hästens
     kurs passerar noll. ]]
local TWO_PI = 2 * math.pi
local function smoothAngle(current: number, target: number, tau: number, dt: number): number
	local delta = (target - current + math.pi) % TWO_PI - math.pi
	if tau <= 0 then return target end
	return current + delta * (1 - math.exp(-dt / tau))
end

function CameraController.new(rig: Types.Rig)
	local self = setmetatable({}, CameraController)
	self.rig = rig
	self.camera = Workspace.CurrentCamera
	self.dist = Config.CAMERA.BaseFov and 15 or 15
	self.height = 5.2
	self.fov = Config.CAMERA.BaseFov
	self.yaw = math.atan2(rig.root.CFrame.LookVector.X, rig.root.CFrame.LookVector.Z)
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
	--[[ Kamerans egen kurs, inte hästens. Fördröjningen är kort nog att
	     man aldrig tappar bort vart man är på väg, och lång nog att
	     styrutslag inte rycker i bilden. ]]
	self.yaw = smoothAngle(self.yaw, loco.heading, C.YawTau, dt)
	local heading = self.yaw
	local back = Vector3.new(-math.sin(heading), 0, -math.cos(heading))
	local right = Vector3.new(math.cos(heading), 0, -math.sin(heading))

	--[[ Kameran hänger efter i svängen i stället för att sitta stelt bakom.
	     Det är den detaljen som gör att svängar läses som svängar. ]]
	local trail = right * math.clamp(-loco.turnRate, -1, 1) * C.Shoulder

	local focus = root.Position + Vector3.new(0, 2, 0)
		+ Vector3.new(math.sin(heading), 0, math.cos(heading)) * C.LookAhead
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

	self.camera.CFrame = CFrame.lookAt(wanted, focus)
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
