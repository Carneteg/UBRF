--!strict
--[[
	Dammet under hovarna.

	Sparsamt med flit. Partiklar i ett ridspel ska bekräfta att marken
	finns, inte fira att man rör sig. Damm kommer bara i trav och uppåt,
	bara på mark som dammar, och bara när hovarna slår i.
]]

local Core = require(game:GetService("ReplicatedStorage").HorseCore)
local Types = require(game:GetService("ReplicatedStorage").HorseCore.Types)
local Gaits = Core.Gaits

local EffectsController = {}
EffectsController.__index = EffectsController

local DUSTY = {
	[Enum.Material.Sand] = true, [Enum.Material.Ground] = true,
	[Enum.Material.Sandstone] = true, [Enum.Material.Slate] = true,
	[Enum.Material.Concrete] = true, [Enum.Material.Cobblestone] = true,
}

function EffectsController.new(rig: Types.Rig)
	local self = setmetatable({}, EffectsController)
	self.rig = rig
	self.emitter = nil :: ParticleEmitter?
	self.lastPhase = 0

	--[[ Emittern skapas en gång och släpps i korta skurar i stället för att
	     ligga och gå. En emitter som alltid är på kostar även när hästen står. ]]
	local existing = rig.model:FindFirstChild("HoofDust", true)
	if existing and existing:IsA("ParticleEmitter") then
		self.emitter = existing
		existing.Enabled = false
	end
	return self
end

function EffectsController:step(loco: Types.Locomotion, dt: number)
	local emitter = self.emitter
	if not emitter then return end
	if not loco.grounded or loco.airborne then return end

	local gait = Gaits.get(loco.gait)
	if gait.steps == 0 or Gaits.index(loco.gait) < Gaits.index("trot") then
		return
	end

	local beats = gait.steps
	local now = math.floor(loco.phase * beats)
	if now == math.floor(self.lastPhase * beats) then
		self.lastPhase = loco.phase
		return
	end
	self.lastPhase = loco.phase

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { self.rig.model }
	local hit = workspace:Raycast(self.rig.root.Position, Vector3.new(0, -8, 0), params)
	if not (hit and DUSTY[hit.Material]) then return end

	-- Mängden följer farten: en puff i trav, en tydlig sky i fyrsprång.
	emitter:Emit(math.floor(2 + math.abs(loco.speed)))
end

function EffectsController:release() end

return EffectsController
