--!strict
--[[
	Felsökningsrutan.

	Avstängd som standard. Slås på med attributet HorseDebug på
	ReplicatedStorage, eller med F8 under utveckling — aldrig kvar påslagen
	i en publicerad plats.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Debug = {}

local gui: ScreenGui? = nil
local label: TextLabel? = nil
local rigDescription = ""
local statsLine = ""
local staminaLine = ""
local enabled = ReplicatedStorage:GetAttribute("HorseDebug") == true

local function ensureGui()
	if gui then return end
	local screen = Instance.new("ScreenGui")
	screen.Name = "HorseDebug"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromOffset(420, 190)
	text.Position = UDim2.fromOffset(12, 12)
	text.BackgroundColor3 = Color3.fromRGB(12, 10, 18)
	text.BackgroundTransparency = 0.25
	text.TextColor3 = Color3.fromRGB(235, 230, 245)
	text.Font = Enum.Font.Code
	text.TextSize = 14
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.TextYAlignment = Enum.TextYAlignment.Top
	text.Text = ""
	text.Parent = screen

	gui, label = screen, text
end

function Debug.attach(rig, stats)
	local RigAdapter = require(ReplicatedStorage.HorseCore.RigAdapter)
	rigDescription = RigAdapter.describe(rig)
	statsLine = ("%s · %s · nivå %d"):format(
		tostring(stats.HorseName), tostring(stats.Breed), stats.Level)
end

function Debug.setStamina(value: number, max: number, ceiling: string)
	staminaLine = ("uthållighet %d/%d  tak %s"):format(value, max, ceiling)
end

function Debug.step(loco)
	if not enabled then
		if gui then gui.Enabled = false end
		return
	end
	ensureGui()
	if gui then gui.Enabled = true end
	if not label then return end

	label.Text = table.concat({
		statsLine,
		("tillstånd  %s"):format(loco.state),
		("gångart    %s → %s"):format(loco.gait, loco.targetGait),
		("fart       %.2f m/s"):format(loco.speed),
		("sväng      %.2f rad/s   lutning %.3f"):format(loco.turnRate, loco.lean),
		("mark       %s   luft %s"):format(tostring(loco.grounded), tostring(loco.airborne)),
		staminaLine,
		rigDescription,
	}, "\n")
end

function Debug.clear()
	if gui then gui.Enabled = false end
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.F8 then
		enabled = not enabled
	end
end)

return Debug
