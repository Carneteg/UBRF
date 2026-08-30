--!strict
--[[
	GameplayService — G01.1: tilldelad häst + förberedelse före uppsittning.

	Servern äger progressionen. Klienten visar bara målet och skickar avsikt.
	Vi skapar inga produktionshästar här: om Studio-världen saknar en taggad
	Horse rapporteras vänteläget, eftersom modell/identitet är ett assetansvar.
]]

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Core = require(ReplicatedStorage.HorseCore)
local Net = Core.Networking
local Preparation = Core.Preparation
local RigAdapter = Core.RigAdapter

local GameplayService = {}

local horseByPlayer: { [Player]: Model } = {}
local playerByHorse: { [Model]: Player } = {}
local horseService: any = nil

local function horseName(model: Model): string
	local n = model:GetAttribute("HorseName")
	return if typeof(n) == "string" and n ~= "" then n else model.Name
end

local function phaseOf(player: Player): string
	local phase = player:GetAttribute("G01Phase")
	return if typeof(phase) == "string" then phase else "waiting_horse"
end

local function snapshot(player: Player)
	local model = horseByPlayer[player]
	local phase = phaseOf(player)
	return {
		enabled = player:GetAttribute("G01Enabled") == true,
		phase = phase,
		horse = model,
		horseName = if model then horseName(model) else nil,
		objective = Preparation.OBJECTIVE[phase] or "Fortsätt med din häst.",
		action = Preparation.expectedAction(phase),
		actionText = Preparation.ACTION_TEXT[phase],
		mountUnlocked = Preparation.mountUnlocked(phase),
	}
end

local function publish(player: Player, feedback: string?)
	if player.Parent ~= Players then return end
	Net.get("G01StateChanged"):FireClient(player, snapshot(player), feedback)
end

local function setPhase(player: Player, phase: string, feedback: string?)
	player:SetAttribute("G01Phase", phase)
	publish(player, feedback)
end

local function release(player: Player)
	local model = horseByPlayer[player]
	if not model then return end
	horseByPlayer[player] = nil
	playerByHorse[model] = nil
	if model.Parent then
		model:SetAttribute("AssignedUserId", 0)
	end
end

local function availableHorses(): { Model }
	local horses: { Model } = {}
	for _, inst in CollectionService:GetTagged("Horse") do
		if inst:IsA("Model") and inst.Parent and playerByHorse[inst] == nil then
			table.insert(horses, inst)
		end
	end
	table.sort(horses, function(a, b)
		local an, bn = horseName(a), horseName(b)
		if an == bn then return a:GetFullName() < b:GetFullName() end
		return an < bn
	end)
	return horses
end

local function assign(player: Player)
	if player.Parent ~= Players then return end
	local current = horseByPlayer[player]
	if current and current.Parent then return end

	release(player)
	local horses = availableHorses()
	local model = horses[1]
	if not model then
		player:SetAttribute("G01HorseName", "")
		setPhase(player, "waiting_horse")
		return
	end

	horseByPlayer[player] = model
	playerByHorse[model] = player
	model:SetAttribute("AssignedUserId", player.UserId)
	player:SetAttribute("G01HorseName", horseName(model))
	setPhase(player, "approach", ("I dag tar du hand om %s."):format(horseName(model)))
end

local function setupPlayer(player: Player)
	player:SetAttribute("G01Enabled", true)
	player:SetAttribute("G01Phase", "waiting_horse")
	player:SetAttribute("G01HorseName", "")
	task.defer(assign, player)
end

local function closeEnough(player: Player, model: Model): (boolean, string?)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return false, "Din karaktär är inte redo."
	end
	local rig, err = RigAdapter.build(model)
	if not rig then
		return false, err or "Hästen saknar en användbar rigg."
	end
	if (root.Position - rig.root.Position).Magnitude > 12 then
		return false, "Gå närmare din häst först."
	end
	return true, nil
end

local function doPreparationAction(player: Player, action: any, model: any): (boolean, string?)
	if typeof(action) ~= "string" then
		return false, "Ogiltigt moment."
	end
	if typeof(model) ~= "Instance" or not model:IsA("Model") then
		return false, "Ogiltig häst."
	end
	if horseByPlayer[player] ~= model then
		return false, "Det här är inte hästen du har fått ansvar för i dag."
	end

	local near, reason = closeEnough(player, model)
	if not near then return false, reason end

	local phase = phaseOf(player)
	local ok, nextPhase, feedback = Preparation.advance(phase, action)
	if not ok then return false, feedback end

	setPhase(player, nextPhase, feedback)
	return true, feedback
end

local function installMountGate()
	-- HorseService har redan initierat remotes och sin standardhandler. G01
	-- ersätter bara fjärrgränsen och återanvänder samma tryMount/dismount.
	Net.get("MountRequest").OnServerInvoke = function(player: Player, model: any)
		if typeof(model) ~= "Instance" or not model:IsA("Model") then
			return false, "Ogiltig häst"
		end

		if player:GetAttribute("G01Enabled") == true then
			if horseByPlayer[player] ~= model then
				return false, "Du ska rida hästen du har fått ansvar för i dag."
			end
			local phase = phaseOf(player)
			if not Preparation.mountUnlocked(phase) then
				return false, "Gör klart hästen innan du sitter upp."
			end
		end

		local ok, reason = horseService.tryMount(player, model)
		if ok and player:GetAttribute("G01Enabled") == true then
			setPhase(player, "mounted", "Bra. Förberedelserna är klara och du sitter upp på en häst som du själv gjort i ordning.")
		end
		return ok, reason
	end

	Net.get("DismountRequest").OnServerInvoke = function(player: Player)
		local ok = horseService.dismount(player)
		if ok and player:GetAttribute("G01Enabled") == true and phaseOf(player) == "mounted" then
			-- G01.1 slutar vid uppsittningen. Tills G01.4 finns går vi tillbaka
			-- till ett säkert remount-läge i stället för att låtsas att eftervård
			-- redan är implementerad.
			setPhase(player, "ready_to_mount")
		end
		return ok
	end
end

function GameplayService.start(service: any)
	horseService = service
	assert(horseService and horseService.tryMount and horseService.dismount,
		"GameplayService kräver HorseService")

	Net.get("G01GetState").OnServerInvoke = function(player: Player)
		return snapshot(player)
	end
	Net.get("G01Action").OnServerInvoke = doPreparationAction

	-- En ny server har inga legitima gamla spelartilldelningar.
	for _, inst in CollectionService:GetTagged("Horse") do
		if inst:IsA("Model") then
			inst:SetAttribute("AssignedUserId", 0)
		end
	end

	for _, player in Players:GetPlayers() do
		setupPlayer(player)
	end
	Players.PlayerAdded:Connect(setupPlayer)
	Players.PlayerRemoving:Connect(function(player)
		release(player)
	end)

	CollectionService:GetInstanceAddedSignal("Horse"):Connect(function(inst)
		if not inst:IsA("Model") then return end
		inst:SetAttribute("AssignedUserId", 0)
		for _, player in Players:GetPlayers() do
			if phaseOf(player) == "waiting_horse" then
				task.defer(assign, player)
			end
		end
	end)

	CollectionService:GetInstanceRemovedSignal("Horse"):Connect(function(inst)
		if not inst:IsA("Model") then return end
		local player = playerByHorse[inst]
		if not player then return end
		horseByPlayer[player] = nil
		playerByHorse[inst] = nil
		player:SetAttribute("G01HorseName", "")
		setPhase(player, "waiting_horse", "Din häst försvann ur världen. Väntar på en tillgänglig häst.")
		task.defer(assign, player)
	end)

	installMountGate()
	print("[G01] Tilldelning och förberedelse igång")
end

return GameplayService
