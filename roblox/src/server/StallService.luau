--!strict
--[[ STALLSERVICE — en enda auktoritet för vilken UBRF-häst spelaren har.

	Gate G01. Tjänsten äger IDENTITETEN och boxen:
	  1. väljer en ledig hästidentitet deterministiskt,
	  2. reserverar den så två aktiva spelare inte får samma häst,
	  3. sätter boxprompten,
	  4. publicerar tilldelningen till övriga serversystem och klienten.

	GameplayService får binda identiteten till en fysisk Horse-rigg och äga
	förberedelseprogressionen, men får INTE välja en annan häst. Det håller
	StallService som enda assignment authority.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Stallet = require(ReplicatedStorage.Stallet)

local StallService = {}

local M = 3
local ANLAGGNING = "Anläggning"

local tilldelade: { [Player]: any } = {}
local upptagna: { [string]: Player } = {}
local markorer: { [Player]: Model } = {}

local function bas(): CFrame?
	local modell = workspace:FindFirstChild(ANLAGGNING)
	local ubrf = modell and modell:FindFirstChild("UBRF")
	return ubrf and ubrf.PrimaryPart and ubrf.PrimaryPart.CFrame or nil
end

local function taBortMarkor(player: Player)
	local m = markorer[player]
	if m then
		m:Destroy()
		markorer[player] = nil
	end
end

local function publicera(player: Player, dagens: any?)
	if dagens then
		player:SetAttribute("AssignedHorseId", dagens.id)
		player:SetAttribute("AssignedHorseName", dagens.namn)
		player:SetAttribute("AssignedHorseBox", dagens.box and dagens.box.nummer or 0)
	else
		player:SetAttribute("AssignedHorseId", "")
		player:SetAttribute("AssignedHorseName", "")
		player:SetAttribute("AssignedHorseBox", 0)
	end
end

local function satMarkor(player: Player, dagens: any): Model?
	local b = bas()
	if not b then
		warn("[Stallet] Anläggningen är inte byggd — ingen boxmarkör satt.")
		return nil
	end

	local modell = Instance.new("Model")
	modell.Name = "Boxmarkor_" .. player.Name

	local del = Instance.new("Part")
	del.Name = "Box"
	del.Anchored = true
	del.CanCollide = false
	del.CanQuery = false
	del.Transparency = 1
	del.Size = Vector3.new(1, 2, 1)
	del.CFrame = b * CFrame.new(dagens.box.varld.x * M, 1 * M, dagens.box.varld.y * M)
	del.Parent = modell

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BoxPrompt"
	prompt.ActionText = "Titta in"
	prompt.ObjectText = dagens.namn .. " står här"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = del

	prompt.Triggered:Connect(function(spelare)
		if spelare ~= player then return end
		print(("[Stallet] %s — %s, %s. %s"):format(
			dagens.namn, dagens.ras, dagens.typ, dagens.besk))
		if dagens.foder then
			print(("[Stallet] Foder: %d kg hö, kraftfoder %s. %s"):format(
				dagens.foder.ho, tostring(dagens.foder.kraft), dagens.foder.notis))
		end
	end)

	modell.PrimaryPart = del
	modell.Parent = workspace
	return modell
end

local function upptagenMangd(): { [string]: boolean }
	local ut = {}
	for id in upptagna do ut[id] = true end
	return ut
end

function StallService.tilldela(player: Player)
	if player.Parent ~= Players then return nil end
	local befintlig = tilldelade[player]
	if befintlig then return befintlig end

	local dagens = Stallet.dagensHast(player.UserId, upptagenMangd())
	if not dagens then
		publicera(player, nil)
		warn("[Stallet] Ingen ledig häst kunde tilldelas " .. player.Name)
		return nil
	end

	tilldelade[player] = dagens
	upptagna[dagens.id] = player
	publicera(player, dagens)
	taBortMarkor(player)
	local m = satMarkor(player, dagens)
	if m then markorer[player] = m end

	print(("[Stallet] %s rider %s idag — box %d, rad %s, gång %s."):format(
		player.Name, dagens.namn, dagens.box.nummer, dagens.box.rad, dagens.box.gang))
	return dagens
end

function StallService.hastFor(player: Player)
	return tilldelade[player]
end

function StallService.frigiv(player: Player)
	local dagens = tilldelade[player]
	if dagens and upptagna[dagens.id] == player then
		upptagna[dagens.id] = nil
	end
	tilldelade[player] = nil
	taBortMarkor(player)
	publicera(player, nil)
end

local function erbjudVantande()
	-- Direkt, inte task.defer: varje tilldelning reserverar identiteten innan
	-- nästa spelare provas, så två väntande aldrig ser samma häst som ledig.
	for _, player in Players:GetPlayers() do
		if not tilldelade[player] then
			StallService.tilldela(player)
		end
	end
end

function StallService.start()
	local befintlig = ReplicatedStorage:FindFirstChild("MinHast")
	local fraga: RemoteFunction
	if befintlig and befintlig:IsA("RemoteFunction") then
		fraga = befintlig
	else
		if befintlig then befintlig:Destroy() end
		fraga = Instance.new("RemoteFunction")
		fraga.Name = "MinHast"
		fraga.Parent = ReplicatedStorage
	end
	fraga.OnServerInvoke = function(player)
		return tilldelade[player] or StallService.tilldela(player)
	end

	Players.PlayerAdded:Connect(function(player)
		StallService.tilldela(player)
	end)
	for _, player in Players:GetPlayers() do
		StallService.tilldela(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		StallService.frigiv(player)
		erbjudVantande()
	end)

	print("[Stallet] Igång — unik hästidentitet per aktiv spelare")
end

return StallService
