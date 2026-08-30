--!strict
--[[ STALLSERVICE — din häst, och skylten vid hennes box.

	Gate G01, första skivan. Före det här mötte en Roblox-spelare en
	hästMODELL: HorseStats stod på "Namnlös" av rasen "Warmblood", medan de
	sjutton riktiga UBRF-hästarna bara fanns i webbversionens JS.

	Tjänsten gör tre saker och inget mer:
	  1. tilldelar spelaren en häst vid ankomsten,
	  2. sätter en ProximityPrompt vid hennes box,
	  3. svarar på frågan "vilken är min häst" över nätet.

	Reglerna ligger i ReplicatedStorage.Stallet, som är ren logik och provas
	i roblox/tests/spel.spec.luau utan Studio. Den här filen är bara
	instanserna. Den uppdelningen finns för att regler ska gå att falsifiera
	härifrån; en ProximityPrompt går inte.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Stallet = require(ReplicatedStorage.Stallet)

local StallService = {}

local M = 3          -- studs per meter, samma som BuildKit.M
local ANLAGGNING = "Anläggning"

local tilldelade: { [Player]: any } = {}
local markorer: { [Player]: Model } = {}

--[[ Anläggningens bas. Byggskriptet lägger allt relativt PrimaryPart, så
	utan den vet vi inte var i världen stallet står. Saknas den är
	anläggningen inte byggd — säg det rakt ut i stället för att lägga en
	skylt i origo och låta någon leta. ]]
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

--[[ Skylten vid boxen. Osynlig och genomsläpplig — den är bara en bärare
	för prompten, inte något att gå in i. ]]
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
		--[[ Ingen egen text hittas på: beskrivningen är ordagrann från
			ubrf.se/hastar och foderraden kommer ur samma delade data. ]]
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

function StallService.tilldela(player: Player)
	local dagens = Stallet.dagensHast(player.UserId)
	if not dagens then
		warn("[Stallet] Ingen häst kunde tilldelas " .. player.Name)
		return nil
	end
	tilldelade[player] = dagens
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

function StallService.start()
	local fraga = Instance.new("RemoteFunction")
	fraga.Name = "MinHast"
	fraga.Parent = ReplicatedStorage
	fraga.OnServerInvoke = function(player)
		--[[ Klienten får FRÅGA, aldrig bestämma. Samma regel som
			uppsittningen redan följer. ]]
		return tilldelade[player] or StallService.tilldela(player)
	end

	Players.PlayerAdded:Connect(function(player)
		StallService.tilldela(player)
	end)
	for _, player in Players:GetPlayers() do
		StallService.tilldela(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		taBortMarkor(player)
		tilldelade[player] = nil
	end)

	print("[Stallet] Igång")
end

return StallService
