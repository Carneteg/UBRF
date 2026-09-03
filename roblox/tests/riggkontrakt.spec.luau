--!nocheck
--[[ Riggkontraktet — issue #31.

	Provet bygger sina egna instanser i stället för att låna `__makeRig`.
	Skälet är att det som ska mätas här ÄR modellens form: vilka delar som
	finns, vad de heter och hur deras flaggor står. En riggfabrik som redan
	gör allting rätt kan inte visa att kontrollen fäller något.

	Varje regel prövas därför i par: en komplett rigg som ska vara ren, och
	samma rigg med precis en sak sönder som ska fälla på just den regeln.
]]

local fails = 0
local function check(namn, villkor, detalj)
	if villkor then
		print(string.format("  OK   %s%s", namn, detalj and ("  " .. detalj) or ""))
	else
		fails += 1
		print(string.format("  FEL  %s%s", namn, detalj and ("  " .. detalj) or ""))
	end
end

--[[ ── En minimal instansvärld ─────────────────────────────────────────
	 Arvet måste vara med: en Seat ÄR en BasePart, en MeshPart ÄR en
	 BasePart, och en LocalScript ÄR en BaseScript. Utan arvet skulle
	 kontrollens `IsA` svara fel och proven mäta stubben, inte modulen. ]]
local ARV = {
	Part = { "BasePart", "PVInstance", "Instance" },
	MeshPart = { "BasePart", "PVInstance", "Instance" },
	Seat = { "Part", "BasePart", "PVInstance", "Instance" },
	Model = { "PVInstance", "Instance" },
	Humanoid = { "Instance" },
	Animator = { "Instance" },
	Attachment = { "Instance" },
	Configuration = { "Instance" },
	Script = { "BaseScript", "LuaSourceContainer", "Instance" },
	LocalScript = { "BaseScript", "LuaSourceContainer", "Instance" },
	ModuleScript = { "LuaSourceContainer", "Instance" },
	Bone = { "Attachment", "Instance" },
}

local function inst(klass, namn, props)
	local i = {
		ClassName = klass,
		Name = namn,
		_barn = {},
		_attr = {},
	}
	for k, v in props or {} do
		i[k] = v
	end

	function i:IsA(k)
		if k == self.ClassName then return true end
		for _, f in ARV[self.ClassName] or {} do
			if f == k then return true end
		end
		return false
	end

	function i:GetChildren() return self._barn end

	function i:GetDescendants()
		local ut = {}
		for _, b in self._barn do
			table.insert(ut, b)
			for _, d in b:GetDescendants() do table.insert(ut, d) end
		end
		return ut
	end

	function i:FindFirstChild(n, rekursivt)
		for _, b in self._barn do
			if b.Name == n then return b end
		end
		if rekursivt then
			for _, b in self._barn do
				local tr = b:FindFirstChild(n, true)
				if tr then return tr end
			end
		end
		return nil
	end

	function i:FindFirstChildOfClass(k)
		for _, b in self._barn do
			if b.ClassName == k then return b end
		end
		return nil
	end

	function i:GetAttribute(k) return self._attr[k] end
	function i:SetAttribute(k, v) self._attr[k] = v end

	function i:lagg(barn)
		table.insert(self._barn, barn)
		barn.Parent = self
		return barn
	end

	return i
end

--[[ Varmblod: mankhöjd 1,66 m × 3,0 studs/m = 4,98 studs. Måtten nedan är
	 specens egna 5,98 × 3,98 × 2,49, och HipHeight 4,98 − 3,98/2 = 2,99. ]]
local function heltRigg()
	local m = inst("Model", "Fjodor")
	m:SetAttribute("HorseId", "fjodor")

	m:lagg(inst("Part", "BodyCollider", {
		Size = vec(2.49, 3.98, 5.98),
		CanCollide = true, Massless = false, Transparency = 1,
	}))
	m:lagg(inst("Seat", "RiderSeat", {
		CanCollide = false, Massless = true, Transparency = 1,
	}))

	local h = m:lagg(inst("Humanoid", "Humanoid", {
		HipHeight = 2.99, RequiresNeck = false,
		BreakJointsOnDeath = false, MaxSlopeAngle = 55,
	}))
	h:lagg(inst("Animator", "Animator"))

	local fasten = m:lagg(inst("Configuration", "Attachments"))
	for _, namn in {
		"SaddleAttachment", "LeftReinAttachment", "RightReinAttachment",
		"LeftStirrupAttachment", "RightStirrupAttachment",
	} do
		fasten:lagg(inst("Attachment", namn))
	end

	local stats = m:lagg(inst("Configuration", "HorseStats"))
	stats:SetAttribute("Breed", "Warmblood")

	local anim = m:lagg(inst("Configuration", "AnimationConfig"))
	for _, nyckel in RigContract.KLIPP do
		anim:SetAttribute(nyckel, "rbxassetid://1")
	end

	return m
end

local function harRegel(fynd, regel)
	for _, f in fynd do
		if f.regel == regel and f.allvar == "FEL" then return true end
	end
	return false
end

local function text(fynd)
	local d = {}
	for _, f in fynd do table.insert(d, f.regel) end
	return "[" .. table.concat(d, ",") .. "]"
end

print("\n── En komplett rigg går igenom ──")
do
	local fynd = RigContract.kontrollera(heltRigg(), { hastar = { fjodor = true } })
	check("noll fynd på en rigg som följer specen", #fynd == 0, text(fynd))
end

print("\n── Måtten är utlästa ur specen, inte påhittade ──")
do
	--[[ Regeln reproducerar HORSE-MODEL-SPEC:s egna varmblodssiffror. Gör den
	     inte det är antingen regeln eller specen fel, och då ska det synas
	     här och inte i Studio. ]]
	local m = RigContract.matt(1.66)
	check("varmblodets mått blir specens 5,98 × 3,98 × 2,49",
		math.abs(m.langd - 5.98) < 0.01
			and math.abs(m.djup - 3.98) < 0.01
			and math.abs(m.bredd - 2.49) < 0.01,
		string.format("%.2f × %.2f × %.2f", m.langd, m.djup, m.bredd))

	--[[ En shetlandsponny får inte samma låda som ett varmblod. Specen säger
	     det uttryckligen; utan skalning blir ponnyn lägre än sin collider. ]]
	local ponny = RigContract.matt(1.38)
	check("en lägre ras ger en lägre låda", ponny.djup < m.djup,
		string.format("%.2f < %.2f", ponny.djup, m.djup))
end

print("\n── Kollisionen: den viktigaste regeln ──")
do
	local m = heltRigg()
	m:FindFirstChild("BodyCollider").CanCollide = false
	check("en BodyCollider utan kollision fälls",
		harRegel(RigContract.kontrollera(m), "kollision"))

	local m2 = heltRigg()
	local nat = m2:FindFirstChild("BodyCollider")
	nat.ClassName = "MeshPart"
	nat:lagg(inst("Bone", "Root"))
	check("ett skinnat nät som kollision fälls",
		harRegel(RigContract.kontrollera(m2), "kollision"))

	local m3 = heltRigg()
	m3._barn[1].Name = "Torso"
	check("utan BodyCollider och utan Map_ fälls riggen",
		harRegel(RigContract.kontrollera(m3), "kollision"))
end

print("\n── Map_ följs, annars fälls en korrekt köpt modell ──")
do
	--[[ En köpt modell där delen heter Torso pekas om med Map_BodyCollider.
	     Kontrollen MÅSTE följa den omdöpningen — annars underkänner den en
	     rigg som fungerar, och det är ett dyrare fel än att släppa igenom
	     en trasig: ingen letar efter en bugg i något som redan sagts vara
	     fel på riggen. ]]
	local m = heltRigg()
	m._barn[1].Name = "Torso"
	m:SetAttribute("Map_BodyCollider", "Torso")
	local fynd = RigContract.kontrollera(m)
	check("omdöpt del med Map_ ger inget kollisionsfynd",
		not harRegel(fynd, "kollision"), text(fynd))
end

print("\n── Sätet, fästena, Humanoid ──")
do
	local m = heltRigg()
	m:FindFirstChild("RiderSeat").CanCollide = true
	check("ett kolliderande RiderSeat fälls",
		harRegel(RigContract.kontrollera(m), "sate"))

	local m2 = heltRigg()
	m2:FindFirstChild("Attachments")._barn[3].ClassName = "Part"
	check("en fästpunkt som inte är en Attachment fälls",
		harRegel(RigContract.kontrollera(m2), "attachment"))

	local m3 = heltRigg()
	table.remove(m3._barn, 3)
	m3:lagg(inst("AnimationController", "AnimationController"))
	check("AnimationController utan Humanoid fälls",
		harRegel(RigContract.kontrollera(m3), "humanoid"))

	local m4 = heltRigg()
	local h = m4:FindFirstChildOfClass("Humanoid")
	table.remove(h._barn, 1)
	check("Humanoid utan Animator fälls",
		harRegel(RigContract.kontrollera(m4), "humanoid"))
end

print("\n── Skalan mäts mot rasens mankhöjd ──")
do
	--[[ 19 % för stor är inte ett påhittat tal: det är vad en modell skalad
	     efter Roblox avatarkonvention (3,57 studs/m) blir i en värld som
	     räknar 3,0. HASTRIGG-KRAVSPEC § 1. ]]
	local m = heltRigg()
	local d = m:FindFirstChild("BodyCollider")
	d.Size = vec(2.49 * 1.19, 3.98 * 1.19, 5.98 * 1.19)
	check("en rigg skalad efter Roblox avatarkonvention fälls",
		harRegel(RigContract.kontrollera(m), "skala"))

	local m2 = heltRigg()
	m2:FindFirstChildOfClass("Humanoid").HipHeight = 0
	check("fel HipHeight fälls", harRegel(RigContract.kontrollera(m2), "skala"))

	--[[ Utan läsbar ras ska kontrollen SÄGA att måtten inte gick att pröva,
	     inte räkna på ett antaget varmblod. Ett tyst antagande här hade
	     gjort mätningen till en gissning med grön färg. ]]
	local m3 = heltRigg()
	m3:FindFirstChild("HorseStats"):SetAttribute("Breed", nil)
	local fynd = RigContract.kontrollera(m3)
	local sagt = false
	for _, f in fynd do
		if f.regel == "skala" and f.allvar == "VARNING" then sagt = true end
	end
	check("utan ras redovisas att måtten inte kunde prövas", sagt, text(fynd))
	check("och den saknade rasen räknas inte som FEL",
		not harRegel(fynd, "skala"))
end

print("\n── Klippen och identiteten ──")
do
	local m = heltRigg()
	m:FindFirstChild("AnimationConfig"):SetAttribute("Canter", nil)
	check("ett saknat obligatoriskt klipp fälls",
		harRegel(RigContract.kontrollera(m), "klipp"))

	local m2 = heltRigg()
	m2:SetAttribute("HorseId", "")
	check("tomt HorseId fälls", harRegel(RigContract.kontrollera(m2), "horseid"))

	local m3 = heltRigg()
	check("HorseId utanför rostern fälls",
		harRegel(RigContract.kontrollera(m3, { hastar = { nagon_annan = true } }),
			"horseid"))

	local m4 = heltRigg()
	check("utan roster prövas inte HorseId mot den",
		not harRegel(RigContract.kontrollera(m4), "horseid"))

	local m5 = heltRigg()
	m5:lagg(inst("LocalScript", "AutoRide"))
	check("ett medföljande skript fälls",
		harRegel(RigContract.kontrollera(m5), "skript"))

	local m6 = heltRigg()
	check("taggen prövas när den som kör svarar på den",
		harRegel(RigContract.kontrollera(m6, { harTagg = function() return false end }),
			"tagg"))
end

print("\n── Adaptern och kontraktet svarar på olika frågor ──")
do
	--[[ DET HÄR ÄR HELA POÄNGEN med modulen.

	     En modell med en stor namnlös låda och en Humanoid laddas utan
	     knot av RigAdapter: den faller tillbaka på största delen. Spelet
	     startar, hästen syns, och ingenting säger ifrån. Men den har ingen
	     BodyCollider, inget säte, inga fästen och inga klipp.

	     Att `build()` lyckas är alltså inget besked om att riggen duger.
	     Om det här provet någon gång blir grönt åt fel håll — att kontraktet
	     släpper igenom vad adaptern släpper igenom — har den stränga halvan
	     tappat sitt syfte. ]]
	local m = inst("Model", "Slarvig")
	m:lagg(inst("Part", "Nagot", { Size = vec(6, 4, 2.5), CanCollide = true }))
	local h = m:lagg(inst("Humanoid", "Humanoid"))
	h:lagg(inst("Animator", "Animator"))

	local rig, skal = RigAdapter.build(m)
	check("RigAdapter laddar den utan invändning", rig ~= nil, skal or "")

	local fynd = RigContract.kontrollera(m)
	check("kontraktet underkänner samma rigg", RigContract.fel(fynd) > 0,
		RigContract.fel(fynd) .. " fel")
	check("och pekar ut kollisionen, sätet, fästena och klippen",
		harRegel(fynd, "kollision") and harRegel(fynd, "sate")
			and harRegel(fynd, "attachment") and harRegel(fynd, "klipp"),
		text(fynd))
end

print("\n── Rapporten döljer inte vad den inte vet ──")
do
	local rapport = RigContract.rapport(RigContract.kontrollera(heltRigg()))
	check("en ren rigg redovisar ändå EJ PROVAT",
		string.find(rapport, "EJ PROVAT", 1, true) ~= nil)
	check("Studio-importen står bland det oprovade",
		string.find(rapport, "importerar rent i Studio", 1, true) ~= nil)
	check("och rotbenets riktning också",
		string.find(rapport, "+Z", 1, true) ~= nil)
end

print("")
if fails > 0 then
	print(string.format("%d mätning(ar) föll.", fails))
else
	print("Alla mätningar gick igenom.")
end
