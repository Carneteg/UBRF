--!strict
--[[
	GameplayService — G01: förberedelse före uppsittning.

	ANSVARSGRÄNSER:
	- StallService äger vilken verklig UBRF-hästidentitet spelaren får.
	- GameplayService binder den identiteten till en fysisk Horse-rigg och äger
	  förberedelsefasen.
	- HorseService äger själva uppsittningen, ryttaren och ridfysiken.

	Det finns alltså en assignment authority och en riding engine.

	En fysisk modell måste vara taggad "Horse" och ha attributet HorseId som
	matchar id:t i UBRFSpel (t.ex. "toblerone"). Om modellen saknas väntar
	spelaren. Vi skapar aldrig en produktionshäst ur block som ersättning.
]]

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Core = require(ReplicatedStorage.HorseCore)
local Net = Core.Networking
local Preparation = Core.Preparation
local RigAdapter = Core.RigAdapter

local GameplayService = {}

local horseService: any = nil
local stallService: any = nil
local modelByPlayer: { [Player]: Model } = {}
local playerByModel: { [Model]: Player } = {}

local function assignedData(player: Player)
	return stallService and stallService.hastFor(player) or nil
end

local function phaseOf(player: Player): string
	local phase = player:GetAttribute("G01Phase")
	return if typeof(phase) == "string" then phase else "waiting_horse"
end

local function modelHorseId(model: Model): string?
	local id = model:GetAttribute("HorseId")
	return if typeof(id) == "string" and id ~= "" then id else nil
end

local function snapshot(player: Player)
	local data = assignedData(player)
	local model = modelByPlayer[player]
	local phase = phaseOf(player)
	return {
		enabled = player:GetAttribute("G01Enabled") == true,
		phase = phase,
		horse = model,
		horseId = data and data.id or nil,
		horseName = data and data.namn or nil,
		box = data and data.box or nil,
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

local function unbindModel(player: Player)
	local model = modelByPlayer[player]
	if not model then return end
	modelByPlayer[player] = nil
	playerByModel[model] = nil
	if model.Parent then
		model:SetAttribute("AssignedUserId", 0)
	end
end

local function findModel(horseId: string): Model?
	local candidates = {}
	for _, inst in CollectionService:GetTagged("Horse") do
		if inst:IsA("Model") and inst.Parent and modelHorseId(inst) == horseId
			and playerByModel[inst] == nil then
			table.insert(candidates, inst)
		end
	end
	table.sort(candidates, function(a, b)
		return a:GetFullName() < b:GetFullName()
	end)
	return candidates[1]
end

local function bindAssignedModel(player: Player)
	if player.Parent ~= Players then return end
	local data = assignedData(player)
	if not data then
		unbindModel(player)
		player:SetAttribute("G01HorseName", "")
		setPhase(player, "waiting_horse")
		return
	end

	player:SetAttribute("G01HorseName", data.namn)
	local current = modelByPlayer[player]
	if current and current.Parent and modelHorseId(current) == data.id then
		return
	end
	unbindModel(player)

	local model = findModel(data.id)
	if not model then
		setPhase(player, "waiting_model",
			("%s är din häst idag, men hennes ridmodell är inte inlagd i världen ännu."):format(data.namn))
		return
	end

	modelByPlayer[player] = model
	playerByModel[model] = player
	model:SetAttribute("AssignedUserId", player.UserId)
	model:SetAttribute("HorseName", data.namn)
	setPhase(player, "approach", ("I dag tar du hand om %s."):format(data.namn))
end

local function offerModelsToWaiting()
	for _, player in Players:GetPlayers() do
		local data = assignedData(player)
		if data and modelByPlayer[player] == nil then
			bindAssignedModel(player)
		end
	end
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
	if typeof(action) ~= "string" then return false, "Ogiltigt moment." end
	if typeof(model) ~= "Instance" or not model:IsA("Model") then
		return false, "Ogiltig häst."
	end
	if modelByPlayer[player] ~= model then
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
	-- HorseService har redan skapat remotes och standardhandlers. G01 ersätter
	-- bara fjärrgränsen; den faktiska uppsittningen delegeras tillbaka dit.
	Net.get("MountRequest").OnServerInvoke = function(player: Player, model: any)
		if typeof(model) ~= "Instance" or not model:IsA("Model") then
			return false, "Ogiltig häst"
		end
		if player:GetAttribute("G01Enabled") == true then
			if modelByPlayer[player] ~= model then
				return false, "Du ska rida hästen du har fått ansvar för i dag."
			end
			if not Preparation.mountUnlocked(phaseOf(player)) then
				return false, "Gör klart hästen innan du sitter upp."
			end
		end

		local ok, reason = horseService.tryMount(player, model)
		if ok and player:GetAttribute("G01Enabled") == true then
			setPhase(player, "mounted",
				"Bra. Förberedelserna är klara och du sitter upp på en häst som du själv gjort i ordning.")
		end
		return ok, reason
	end

	Net.get("DismountRequest").OnServerInvoke = function(player: Player)
		local ok = horseService.dismount(player)
		if ok and player:GetAttribute("G01Enabled") == true and phaseOf(player) == "mounted" then
			-- Eftervård finns inte ännu. Återgå till säkert remount-läge i
			-- stället för att låtsas att nästa G01-skiva redan är byggd.
			setPhase(player, "ready_to_mount")
		end
		return ok
	end
end

local function setupPlayer(player: Player)
	player:SetAttribute("G01Enabled", true)
	player:SetAttribute("G01Phase", "waiting_horse")
	player:SetAttribute("G01HorseName", "")

	player:GetAttributeChangedSignal("AssignedHorseId"):Connect(function()
		bindAssignedModel(player)
	end)
	bindAssignedModel(player)
end

function GameplayService.start(horse: any, stall: any)
	horseService = horse
	stallService = stall
	assert(horseService and horseService.tryMount and horseService.dismount,
		"GameplayService kräver HorseService")
	assert(stallService and stallService.hastFor,
		"GameplayService kräver StallService")

	Net.get("G01GetState").OnServerInvoke = function(player: Player)
		return snapshot(player)
	end
	Net.get("G01Action").OnServerInvoke = doPreparationAction

	for _, inst in CollectionService:GetTagged("Horse") do
		if inst:IsA("Model") then inst:SetAttribute("AssignedUserId", 0) end
	end

	for _, player in Players:GetPlayers() do setupPlayer(player) end
	Players.PlayerAdded:Connect(setupPlayer)
	Players.PlayerRemoving:Connect(function(player)
		unbindModel(player)
	end)

	CollectionService:GetInstanceAddedSignal("Horse"):Connect(function(inst)
		if not inst:IsA("Model") then return end
		inst:SetAttribute("AssignedUserId", 0)
		offerModelsToWaiting()
	end)

	CollectionService:GetInstanceRemovedSignal("Horse"):Connect(function(inst)
		if not inst:IsA("Model") then return end
		local player = playerByModel[inst]
		if not player then return end
		modelByPlayer[player] = nil
		playerByModel[inst] = nil
		setPhase(player, "waiting_model", "Hästens ridmodell försvann ur världen. Väntar på att den kommer tillbaka.")
	end)

	installMountGate()
	print("[G01] StallService-identitet + förberedelse + mount-gate igång")
end

return GameplayService
