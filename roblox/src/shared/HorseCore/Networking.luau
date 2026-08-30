--!strict
--[[
	Nätverkslagret.

	Ett ställe som skapar och hittar fjärrobjekten, så att varken servern
	eller klienten letar i ReplicatedStorage på egen hand. Servern skapar
	dem; klienten väntar in dem.

	Regeln för vad som får skickas: klienten skickar *avsikt* och sin egen
	simulerade position. Servern skickar *sanning* om ägarskap, uppsittning,
	förberedelse och uthållighet. Klienten får aldrig sätta ett värde som
	andra spelare påverkas av.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Networking = {}

local FOLDER_NAME = "HorseRemotes"

local DEFINITIONS = {
	MountRequest = "RemoteFunction",
	DismountRequest = "RemoteFunction",
	MountChanged = "RemoteEvent",
	StateSync = "RemoteEvent",
	StaminaSync = "RemoteEvent",
	HorseReaction = "RemoteEvent",
	G01GetState = "RemoteFunction",
	G01Action = "RemoteFunction",
	G01StateChanged = "RemoteEvent",
}

local cache: { [string]: Instance } = {}

local function folder(): Folder
	local existing = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if existing then
		return existing :: Folder
	end
	if RunService:IsServer() then
		local f = Instance.new("Folder")
		f.Name = FOLDER_NAME
		f.Parent = ReplicatedStorage
		return f
	end
	return ReplicatedStorage:WaitForChild(FOLDER_NAME, 30) :: Folder
end

function Networking.get(name: string): any
	if cache[name] then return cache[name] end
	local class = DEFINITIONS[name]
	assert(class, ("[Horse] Okänt fjärrobjekt %q"):format(name))

	local parent = folder()
	local existing = parent:FindFirstChild(name)
	if not existing and RunService:IsServer() then
		existing = Instance.new(class)
		existing.Name = name
		existing.Parent = parent
	elseif not existing then
		existing = parent:WaitForChild(name, 30)
	end
	cache[name] = existing :: Instance
	return existing
end

function Networking.init()
	assert(RunService:IsServer(), "Networking.init körs bara på servern")
	for name in DEFINITIONS do
		Networking.get(name)
	end
end

return Networking
