--!strict
--[[
	Hovljud och hästljud.

	Hovarna slår i takt med gångarten, inte med en timer: fasen kommer från
	rörelsemodulen, som räknar den ur farten. Det gör att ljudet stämmer med
	benen även när animationen sträcks eller hästen bromsar.

	Underlaget läses av med samma strålkastning som marken redan gör, och
	byter ljudmapp. Saknas ett ljud spelas inget — tystnad är bättre än fel
	ljud, och ett saknat ljud får aldrig stoppa något.
]]

local Core = require(game:GetService("ReplicatedStorage").HorseCore)
local Types = require(game:GetService("ReplicatedStorage").HorseCore.Types)
local Config, Gaits = Core.Config, Core.Gaits

local SoundController = {}
SoundController.__index = SoundController

--[[ Ljud-id:n sätts som attribut på en Configuration som heter Sounds i
     hästmodellen, med namn som Hoof_Grass, Hoof_Stone, Snort, Neigh. ]]
local SURFACES = {
	[Enum.Material.Grass] = "Grass", [Enum.Material.LeafyGrass] = "Grass",
	[Enum.Material.Ground] = "Dirt", [Enum.Material.Mud] = "Dirt",
	[Enum.Material.Sand] = "Sand", [Enum.Material.Sandstone] = "Sand",
	[Enum.Material.Wood] = "Wood", [Enum.Material.WoodPlanks] = "Wood",
	[Enum.Material.Concrete] = "Stone", [Enum.Material.Slate] = "Stone",
	[Enum.Material.Cobblestone] = "Stone", [Enum.Material.Rock] = "Stone",
}

function SoundController.new(rig: Types.Rig, stats: { [string]: any })
	local self = setmetatable({}, SoundController)
	self.rig = rig
	self.stats = stats
	self.temperament = Config.TEMPERAMENTS[stats.Temperament] or Config.TEMPERAMENTS.Calm
	self.config = rig.model:FindFirstChild("Sounds")
	self.lastPhase = 0
	self.surface = "Grass"
	self.nextVocal = os.clock() + 12
	self.pool = {} :: { [string]: Sound }
	return self
end

function SoundController:_sound(key: string): Sound?
	if self.pool[key] then return self.pool[key] end
	local id = Config.attr(self.config, key, "")
	if typeof(id) ~= "string" or id == "" then return nil end
	local s = Instance.new("Sound")
	s.Name = key
	s.SoundId = if id:match("^rbxassetid://") then id else "rbxassetid://" .. id
	s.RollOffMaxDistance = 120
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.Parent = self.rig.root
	self.pool[key] = s
	return s
end

function SoundController:_hoof()
	local sound = self:_sound("Hoof_" .. self.surface) or self:_sound("Hoof_Dirt")
	if not sound then return end
	--[[ Slumpad tonhöjd. Fyra identiska hovslag i rad låter som en maskin;
	     några procents variation räcker för att det ska låta levande. ]]
	sound.PlaybackSpeed = 0.92 + math.random() * 0.16
	sound:Play()
end

function SoundController:step(loco: Types.Locomotion, dt: number)
	--[[ Ett hovslag varje gång fasen passerar en delning. Antalet delningar
	     är gångartens takt: skritt fyra, trav två, galopp tre, fyrsprång fyra. ]]
	local gait = Gaits.get(loco.gait)
	if gait.steps > 0 and loco.grounded and not loco.airborne then
		local beats = gait.steps
		local now = math.floor(loco.phase * beats)
		local before = math.floor(self.lastPhase * beats)
		if now ~= before then
			self:_hoof()
		end
	end
	self.lastPhase = loco.phase

	-- Underlaget uppdateras sällan; materialet ändras inte per bildruta.
	if math.random() < dt * 4 then
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { self.rig.model }
		local hit = workspace:Raycast(self.rig.root.Position, Vector3.new(0, -8, 0), params)
		if hit then
			self.surface = SURFACES[hit.Material] or "Dirt"
		end
	end

	--[[ Läten kommer sällan och aldrig i rad. En häst som gnäggar var femte
	     sekund blir outhärdlig efter en minut. ]]
	if os.clock() > self.nextVocal then
		local key = if math.abs(loco.speed) > 5 then "Snort" else "Breath"
		local sound = self:_sound(key)
		if sound then sound:Play() end
		self.nextVocal = os.clock() + (14 + math.random() * 16) / self.temperament.soundRate
	end
end

function SoundController:release()
	for _, sound in self.pool do
		sound:Stop()
	end
end

return SoundController
