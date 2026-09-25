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
local Config = Core.Config
local Gangfas = Core.Gangfas

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
	--[[ Slagräknarens minne. `monster = nil` betyder "ingen takt igång",
	     alltså seedas nästa rörelse utan att fyra ett slag. `lopande` är
	     läget i cykler + fas sedan seedningen. ]]
	self.monster = nil :: string?
	self.lopande = 0
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
	--[[ RYGGNINGEN HAR EN EGEN TAKT (#233).

	     `Gaits.get("halt").steps` är 0, och hon ryggar i halt — så den
	     här raden hoppade över slaget och ryggningen var tyst. Det var
	     den ena av tystnadens två orsaker; den andra var att fasen inte
	     växte, och den sitter i `MovementController`.

	     TVÅ SLAG, inte fyra: ryggningen är en tvåtaktig diagonal gångart.
	     Talet står i `Config.RYGGNING` tillsammans med cykellängden, så
	     att takt och steglängd inte kan glida isär — de är två halvor av
	     samma kadens och hör ihop på ett ställe.

	     `loco.ryggar` speglar den `reverse` som driver rörelsen, alltså
	     samma sanning som benen. Ingen egen gångartsstate här. ]]
	--[[ ── SLAGEN KOMMER UR BENFÖLJDEN (#264 GAIT_READABILITY_AND_UGNETA) ──

	     Förut delades fasen jämnt i `steps` delar: `floor(phase × steps)`.
	     Det gav galoppen tre LIKA långa slag — men galopp är tre slag och
	     en paus — och ljudet hade ingen koppling till vilka ben som
	     faktiskt sattes i. Nu läser ljudet samma rad i `RidKanon.GANGFAS`
	     som benen, med samma fas: ett slag hörs när en isättning passeras,
	     och ett diagonalpar är ETT slag.

	     Läget bärs som ett LÖPANDE tal (cykler + fas), så att flera slag i
	     en lång bildruta räknas i ordning och en faswrap inte tappar något.

	     ── TAKTBYTET FÅR INTE GE ETT EXTRA SLAG (oförändrat krav) ───────

	     Byter raden — halt ↔ rygga ↔ skritt ↔ trav ↔ galopp, eller
	     galoppens sida — SEEDAS läget om utan att fyra. Det gör övergången
	     ren i båda riktningarna: inga dubbla eller kvarhängande steg. ]]
	local namn = Gangfas.monsterNamn(loco.gait, loco.lead, loco.ryggar)
	local monster = Gangfas.monster(namn)
	local rullar = monster ~= nil and loco.grounded and not loco.airborne
	if not rullar or monster == nil then
		--[[ Tystnad nollar minnet. Annars ligger ett gammalt läge kvar och
		     kan fyra på första bildrutan hon börjar röra sig igen — ett
		     kvarhängande steg ur förra rörelsen. ]]
		self.monster = nil
	else
		local steg = (loco.phase - self.lastPhase) % 1
		if self.monster ~= namn then
			--[[ Ny rad: seed, inget slag. ]]
			self.monster = namn
			self.lopande = loco.phase
		else
			local fran = self.lopande
			local till = fran + steg
			self.lopande = till
			for _ in ipairs(Gangfas.passerade(monster, fran, till)) do
				self:_hoof()
			end
			--[[ Talet hålls litet; bara skillnaden mellan två lägen räknas. ]]
			if self.lopande > 1e6 then self.lopande = self.lopande % 1 end
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
