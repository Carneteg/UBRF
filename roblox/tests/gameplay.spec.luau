--!nostrict
--[[ GameplayService — bevisar ansvargränsen StallService → rigg → HorseService. ]]
local fails = 0
local function check(namn, villkor, detalj)
	if villkor then
		print(string.format("  OK   %s%s", namn, detalj and ("  " .. detalj) or ""))
	else
		fails += 1
		print(string.format("  FEL  %s%s", namn, detalj and ("  " .. detalj) or ""))
	end
end

local function hast(namn, id, x)
	local m = __instans("Model", namn)
	m.Parent = { Name = "Workspace" }
	m.Position = Vector3.new(x or 0, 0, 0)
	m:SetAttribute("HorseId", id)
	m:SetAttribute("HorseName", namn)
	return m
end

local function spelare(namn, uid, id, hastnamn)
	local p = __medAttributsignal(__spelare(namn, uid))
	__stallTilldela(p, id, hastnamn)
	return p
end

local function stall(player, x) player._root.Position = Vector3.new(x, 0, 0) end
local function forbered(player, model, steg)
	for _, action in ipairs(steg) do __anropa("G01Action", player, action, model) end
end

GameplayService.start(__HorseServiceStub, __StallServiceStub)

print("\n── 1: StallService-identiteten väljer exakt fysisk rigg ──")
local hTob = hast("TobleroneRig", "toblerone", 0)
local hCos = hast("CosmoRig", "cosmo", 0)
__taggaHast(hCos) -- medvetet omvänd ordning: sortering får inte välja identitet
__taggaHast(hTob)

local anna = spelare("Anna", 101, "toblerone", "Toblerone")
local bo = spelare("Bo", 102, "cosmo", "Cosmo M Z")
__ansluter(anna)
__ansluter(bo)
local sa = __anropa("G01GetState", anna)
local sb = __anropa("G01GetState", bo)
check("Anna binds till Toblerones HorseId", sa.horse == hTob and sa.horseId == "toblerone", tostring(sa.horseName))
check("Bo binds till Cosmos HorseId", sb.horse == hCos and sb.horseId == "cosmo", tostring(sb.horseName))
check("fysiska modeller är exklusiva", sa.horse ~= sb.horse)
check("AssignedUserId pekar rätt", hTob:GetAttribute("AssignedUserId") == anna.UserId and hCos:GetAttribute("AssignedUserId") == bo.UserId)
check("displaynamnet kommer från StallService", hTob:GetAttribute("HorseName") == "Toblerone")

print("\n── 2: tilldelad identitet utan rigg ger vänteläge, inte låtsashäst ──")
local cilla = spelare("Cilla", 103, "air", "Air Italia")
__ansluter(cilla)
local sc = __anropa("G01GetState", cilla)
check("ingen fysisk rigg skapas", sc.horse == nil)
check("fasen säger waiting_model", sc.phase == "waiting_model", sc.phase)
check("identiteten finns kvar trots saknad rigg", sc.horseId == "air" and sc.horseName == "Air Italia")

local hAir = hast("AirRig", "air", 0)
__taggaHast(hAir)
sc = __anropa("G01GetState", cilla)
check("sen rigg binds automatiskt", sc.horse == hAir and sc.phase == "approach", sc.phase)

print("\n── 3: man kan inte sköta någon annans häst ──")
stall(anna, 0)
local okAnnan = __anropa("G01Action", anna, "approach", hCos)
check("annans rigg nekas", okAnnan == false)
check("Annas fas står kvar", __anropa("G01GetState", anna).phase == "approach")

print("\n── 4: avstånd och ordning valideras av servern ──")
stall(anna, 500)
check("för långt bort nekas", __anropa("G01Action", anna, "approach", hTob) == false)
stall(anna, 0)
check("approach går nära hästen", __anropa("G01Action", anna, "approach", hTob) == true)
check("tack kan inte hoppa check/groom", __anropa("G01Action", anna, "tack", hTob) == false)
check("groom kan inte hoppa check", __anropa("G01Action", anna, "groom", hTob) == false)
check("fasen är fortfarande check", __anropa("G01GetState", anna).phase == "check")

print("\n── 5: HorseService nås först efter full förberedelse ──")
local tidig, tidigOrsak = __anropa("MountRequest", anna, hTob)
check("tidig mount nekas", tidig == false, tostring(tidigOrsak))
check("ingen tidig mount nådde HorseService", #__monteringar == 0, tostring(#__monteringar))

forbered(anna, hTob, { "check", "groom", "tack" })
local klar = __anropa("G01GetState", anna)
check("full sekvens ger ready_to_mount", klar.phase == "ready_to_mount", klar.phase)
check("mountUnlocked är sant", klar.mountUnlocked == true)
check("annans häst är fortsatt spärrad", __anropa("MountRequest", anna, hCos) == false)
local okMount = __anropa("MountRequest", anna, hTob)
check("egen förberedd häst får mount", okMount == true)
check("exakt en mount nådde HorseService", #__monteringar == 1, tostring(#__monteringar))
check("fasen blir mounted", __anropa("G01GetState", anna).phase == "mounted")

print("\n── 6: avsittning återgår säkert tills eftervård finns ──")
__anropa("DismountRequest", anna)
local efter = __anropa("G01GetState", anna)
check("avsittning → ready_to_mount", efter.phase == "ready_to_mount", efter.phase)
check("prep går inte att mala igen", __anropa("G01Action", anna, "tack", hTob) == false)

print("\n── 7: försvunnen rigg tappar inte hästidentiteten ──")
__avtaggaHast(hAir)
sc = __anropa("G01GetState", cilla)
check("Cilla går till waiting_model", sc.phase == "waiting_model", sc.phase)
check("Air Italia är fortfarande hennes identitet", sc.horseId == "air" and sc.horseName == "Air Italia")
local hAir2 = hast("AirRigNy", "air", 0)
__taggaHast(hAir2)
sc = __anropa("G01GetState", cilla)
check("ersättningsriggen binds på samma HorseId", sc.horse == hAir2 and sc.phase == "approach")

print("\n── 8: pedagogisk feedback skickas från serverns godkända action ──")
stall(bo, 0)
__anropa("G01Action", bo, "approach", hCos)
local sista = __sistaTill(bo)
check("feedback följde med state-eventet",
	sista ~= nil and typeof(sista[2]) == "string" and sista[2] ~= "",
	sista and tostring(sista[2]) or "inget skickat")

if fails > 0 then
	print(string.format("\n%d FEL", fails))
	error("gameplay.spec: " .. fails .. " fel")
end
print("\nG01 gameplay: alla gröna")
