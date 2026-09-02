--!strict
--[[ GAMEPLAYSERVICE — förberedelsen, server-auktoritativt.

	Gate G01, skiva S2b. Loopen är:

	    Hälsa lugnt → Visitera → Rykta → Gör i ordning → Sitt upp

	Ansvarsfördelningen är hela poängen med filen:

	  · `StallService` äger vilken kanonisk `HorseId` spelaren fått.
	  · `Preparation` äger reglerna — ordningen, vad som är gjort, vad som
	    återstår. Ren logik, provas utan Studio.
	  · `HorseService` äger uppsittning, avsittning och ridningen. Den här
	    filen sitter uppsittning ALDRIG själv; den registrerar ett villkor
	    via `setMountGate`.
	  · Den här filen äger BINDNINGEN: vilken modell i världen som är den
	    tilldelade identiteten, och avstånden.

	Klienten får aldrig flytta fram förberedelsen. Den skickar en avsikt
	("jag vill rykta") och får hela sanningen tillbaka. Skälet är inte fusk
	i ett familjespel — det är att två klienter annars kan tro olika saker om
	samma häst, och då är det inte längre servern som håller loopen.
]]

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Core = require(ReplicatedStorage.HorseCore)
local Preparation = require(ReplicatedStorage.HorseCore.Preparation)
local Net = Core.Networking

local HorseService = require(script.Parent.HorseService)
local StallService = require(script.Parent.StallService)

local GameplayService = {}

local TAG = "Horse"

--[[ Så nära man måste stå för att få göra ett steg. Servern äger talet;
	klienten får inte skicka med sitt eget avstånd. Lite rundare än
	`MountRange` (14) med flit — man ryktar närmare än man sitter upp. ]]
local STEG_RACKVIDD = 16

local state: { [Player]: Preparation.State } = {}
local bunden: { [Player]: Model } = {}

--[[ ── Bindningen ──────────────────────────────────────────────────── ]]

--[[ Modellen vars `HorseId` är EXAKT den tilldelade, och som ingen annan
	spelare redan är bunden till.

	Ingen närmast-häst-fallback. Att binda närmaste Horse-taggade modell är
	frestande — det gör att något alltid händer — men det gör också att
	spelaren gör i ordning fel individ utan att få veta det. Hellre
	`waiting_model`. ]]
local function hittaModell(player: Player, hastId: string): Model?
	--[[ Kandidaterna samlas här; VALET görs i Preparation. Tjänsten har med
		flit ingen egen kopia av villkoret — se modulens kommentar. ]]
	local kandidater = {}
	for _, modell in CollectionService:GetTagged(TAG) do
		if modell:IsA("Model") then
			table.insert(kandidater, { id = modell:GetAttribute("HorseId"), modell = modell })
		end
	end
	local upptagna = {}
	for annan, m in pairs(bunden) do
		if annan ~= player then upptagna[m] = true end
	end
	return Preparation.valjModell(kandidater, hastId, upptagna) :: Model?
end

local function status(player: Player): string
	local s = state[player]
	if not s then return Preparation.STATUS.VANTAR_MODELL end
	if HorseService.horseOf(player) then return Preparation.STATUS.RIDER end
	if not bunden[player] then return Preparation.STATUS.VANTAR_MODELL end
	return if Preparation.redo(s) then Preparation.STATUS.REDO else Preparation.STATUS.FORBEREDER
end

local function skicka(player: Player)
	Net.get("PreparationSync"):FireClient(player, Preparation.vy(state[player], status(player)))
end

--[[ Försök binda identiteten till en modell. Anropas vid ankomst och varje
	gång en Horse-taggad modell dyker upp — en rigg som strömmas in eller
	byggs senare ska fångas upp utan att spelaren gör om något. ]]
function GameplayService.bind(player: Player): Model?
	local hastId = StallService.hastIdFor(player)
	if not hastId then return nil end

	if not state[player] or state[player].hastId ~= hastId then
		state[player] = Preparation.nyState(hastId)
		bunden[player] = nil
	end

	local modell = hittaModell(player, hastId)
	if modell then
		bunden[player] = modell
	else
		bunden[player] = nil
	end
	skicka(player)
	return modell
end

--[[ ── Stegen ──────────────────────────────────────────────────────── ]]

local function avstandOk(player: Player, modell: Model): boolean
	local karaktar = player.Character
	local rot = karaktar and karaktar:FindFirstChild("HumanoidRootPart")
	if not (rot and rot:IsA("BasePart")) then return false end
	local pivot = modell.PrimaryPart or modell:FindFirstChildWhichIsA("BasePart")
	if not pivot then return false end
	return (rot.Position - pivot.Position).Magnitude <= STEG_RACKVIDD
end

function GameplayService.utfor(player: Player, fasId: string): (boolean, string?)
	if typeof(fasId) ~= "string" then
		return false, "Ogiltigt steg"
	end
	local s = state[player]
	if not s then
		return false, "Du har ingen tilldelad häst"
	end
	local modell = bunden[player]
	if not modell then
		--[[ Prova en gång till: riggen kan ha dykt upp sedan sist. ]]
		modell = GameplayService.bind(player)
		if not modell then
			return false, "Din häst finns inte i världen än"
		end
	end
	if not avstandOk(player, modell) then
		return false, "Du står för långt bort"
	end

	local ok, skal = Preparation.utfor(s, fasId, s.hastId)
	skicka(player)
	return ok, skal
end

--[[ ── Uppsittningsgrinden ─────────────────────────────────────────── ]]

--[[ Registreras i `HorseService`. Körs FÖRE all uppsittningslogik, så en
	oförberedd spelare aldrig hinner bli monterad och sedan kastas av. ]]
function GameplayService.farSittaUpp(player: Player, modell: Model): (boolean, string?)
	local s = state[player]
	--[[ Krav 6 och 7 avgörs av regeln, inte här. Kvar i tjänsten är bara
		det instansnära: att modellen dessutom är den vi FAKTISKT bundit,
		så att två modeller med samma id aldrig kan bli utbytbara. ]]
	local ok, skal = Preparation.provaModell(s, modell:GetAttribute("HorseId"))
	if not ok then
		return false, skal
	end
	if bunden[player] ~= modell then
		return false, "Det är inte din häst"
	end
	return true, nil
end

--[[ ── Livscykel ───────────────────────────────────────────────────── ]]

local function glom(player: Player)
	state[player] = nil
	bunden[player] = nil
end

function GameplayService.start()
	HorseService.setMountGate(GameplayService.farSittaUpp)

	Net.get("PreparationStep").OnServerInvoke = function(player, fasId)
		return GameplayService.utfor(player, fasId)
	end

	--[[ Flaggan är serverns svar på "är loopen igång". Klienten läser den
		och visar ingen uppsittningsprompt förrän den är sann. Sätts SIST i
		start(), så att den aldrig är sann innan grinden är registrerad. ]]

	Players.PlayerAdded:Connect(function(player)
		GameplayService.bind(player)
		player.CharacterAdded:Connect(function()
			GameplayService.bind(player)
		end)
	end)
	for _, player in Players:GetPlayers() do
		GameplayService.bind(player)
	end
	Players.PlayerRemoving:Connect(glom)

	--[[ En rigg som kommer in senare ska plockas upp av den som väntar på
		henne. Det är krav 2: `waiting_model` ska läka av sig själv. ]]
	CollectionService:GetInstanceAddedSignal(TAG):Connect(function(inst)
		if not inst:IsA("Model") then return end
		for _, player in Players:GetPlayers() do
			if not bunden[player] then
				GameplayService.bind(player)
			end
		end
	end)
	CollectionService:GetInstanceRemovedSignal(TAG):Connect(function(inst)
		for player, m in pairs(bunden) do
			if m == inst then
				bunden[player] = nil
				skicka(player)
			end
		end
	end)

	ReplicatedStorage:SetAttribute("G01Enabled", true)
	print("[Gameplay] Förberedelsen igång")
end

function GameplayService.stateFor(player: Player): Preparation.State?
	return state[player]
end

function GameplayService.modellFor(player: Player): Model?
	return bunden[player]
end

function GameplayService.statusFor(player: Player): string
	return status(player)
end

return GameplayService
