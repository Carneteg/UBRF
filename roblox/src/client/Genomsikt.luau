--!strict
--[[
	Inomhusläsbarhet: väggar mellan kameran och spelaren tonas.

	Product Owner 2026-09-03: "spelaren hamnar bakom väggar inomhus, man ser
	inte vart man går". Rummen får INTE flyttas för att lösa det (CLAUDE.md:
	flytta aldrig väggar för kamera-/UI-problem), så det är bilden som ger
	vika. Varje inre väggbit och sluten volym som anläggningsbygget märker
	med attributet `Genomsiktlig` och vars fotavtryck skär sträckan
	kamera → karaktär får LocalTransparencyModifier — bara på den här
	klienten, aldrig i den replikerade världen.

	Samma regel som webben (src/varld3d.js v3dTonas): sträckan provas i
	planet i korta steg med en marginal, och slutar en bit före karaktären
	så att väggen hon själv står intill inte tonas.

	Beslutet (`skymmer`, `valj`) är rena funktioner utan Roblox-API, så att
	de går att pröva i tests/genomsikt.spec.luau. `start` kopplar in dem.
]]

local Genomsikt = {}

Genomsikt.TONING = 0.78     -- LocalTransparencyModifier på skymmande delar
Genomsikt.MARGINAL = 1.0    -- studs runt delens fotavtryck
Genomsikt.STEG = 0.7        -- studs mellan provpunkterna
Genomsikt.SLUTMARGINAL = 1.2 -- studs före karaktären där provningen slutar

--[[ Står delen (position, storlek) mellan `fran` och `till` i planet? ]]
function Genomsikt.skymmer(pos: Vector3, size: Vector3, fran: Vector3, till: Vector3, marginal: number?): boolean
	local m = marginal or Genomsikt.MARGINAL
	local x0, x1 = pos.X - size.X / 2 - m, pos.X + size.X / 2 + m
	local z0, z1 = pos.Z - size.Z / 2 - m, pos.Z + size.Z / 2 + m
	local dx, dz = till.X - fran.X, till.Z - fran.Z
	local L = math.sqrt(dx * dx + dz * dz)
	if L < 1e-6 then return false end
	local n = math.max(1, math.ceil(L / Genomsikt.STEG))
	local slut = math.max(0, L - Genomsikt.SLUTMARGINAL) / L
	for i = 0, n do
		local t = (i / n) * slut
		local x, z = fran.X + dx * t, fran.Z + dz * t
		if x >= x0 and x <= x1 and z >= z0 and z <= z1 then return true end
	end
	return false
end

--[[ De delar i listan som skymmer sträckan. Delarna behöver bara ha
     `Position` och `Size`, så specen kan mata in tabeller. ]]
function Genomsikt.valj(delar: { any }, fran: Vector3, till: Vector3, marginal: number?): { any }
	local ut = {}
	for _, d in ipairs(delar) do
		if Genomsikt.skymmer(d.Position, d.Size, fran, till, marginal) then
			table.insert(ut, d)
		end
	end
	return ut
end

--[[ Kopplar in toningen på klienten. Kandidaterna samlas en gång och fylls
     på när anläggningen växer; en full genomsökning per bildruta hade
     kostat mer än själva provningen. ]]
function Genomsikt.start()
	local RunService = game:GetService("RunService")
	local Workspace = game:GetService("Workspace")
	local Players = game:GetService("Players")

	local kandidater: { BasePart } = {}
	local function kandidat(d: Instance)
		if d:IsA("BasePart") and d:GetAttribute("Genomsiktlig") == true then
			table.insert(kandidater, d :: BasePart)
		end
	end
	for _, d in ipairs(Workspace:GetDescendants()) do kandidat(d) end
	Workspace.DescendantAdded:Connect(kandidat)

	local tonade: { BasePart } = {}
	RunService.RenderStepped:Connect(function()
		local cam = Workspace.CurrentCamera
		local char = Players.LocalPlayer.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not cam or not root then return end
		local nya = Genomsikt.valj(kandidater, cam.CFrame.Position, (root :: BasePart).Position)
		for _, d in ipairs(tonade) do d.LocalTransparencyModifier = 0 end
		for _, d in ipairs(nya) do d.LocalTransparencyModifier = Genomsikt.TONING end
		tonade = nya
	end)
end

return Genomsikt
