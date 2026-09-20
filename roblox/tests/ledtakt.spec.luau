--!nostrict
--[[
	ANKARET HAR EN TAKT — kryphastighet ar inte att ga.

	ROBLOX_RUNTIME_ROUTING_ACCEPTANCE / M3, hela ledrutten box E 8 -> ridhuset.

	── VARFOR SPECEN FINNS ───────────────────────────────────────────

	Matt i Studio, tre pass med samma utfall. Hasten vaxlade mellan att
	folja i 5,74 studs/s och att KRYPA:

	    11,9 -> 15,5 s   hasten 2,2 studs   = 0,6 studs/s
	                     spelaren 17 studs  = 4,7 studs/s
	    draget            pa, MaxVelocity 6,00
	    stillaSedan       0,0  0,4  0,1  0,6  1,2  0,1  0,0

	Stillamattet ar ett ANKARE: har hon flyttat sig mer an NAV_ANKARE
	(0,25 m) raknas hon som i rorelse och klockan nollstalls. En krypning
	pa 0,2 m/s lamnar den radien pa 1,25 s och kopte sig darmed fri strax
	innan NAV_STILLA (1,2 s) nåddes. Hon raknades som GAENDE medan hon
	forlorade fyra studs i sekunden mot den som ledde henne, planeraren
	kopplades aldrig in, och kopplet slapptes pa `led.tappade_bort` vid
	waypoint 41 av 94.

	Forflyttningen ar fortfarande mattet — en ankrad hast rapporterade
	1,59 studs/s utan att flytta sig, och det ar darfor ankaret finns.
	Det som saknades var att forflyttningen ocksa maste ske i NAGON takt.

	── VAD SOM MATS ──────────────────────────────────────────────────

	  1. gar hon i takt raknas hon som gaende, precis som forr,
	  2. kryper hon raknas hon INTE som gaende, och klockan nar NAV_STILLA,
	  3. och tröskeln ar RELATIV till den fart hon faktiskt beordrats halla.

	Matning 2 kan bara bli gron om `badGa` verkligen var sann i banken —
	`stillaSedan` vaxer ingen annanstans. Den ar darfor samtidigt beviset
	for att drivgrenen nas har, och inte bara else-grenen.

	Kor: python3 roblox/tests/build.py tests/ledtakt.spec.luau
	     && luau roblox/tests/.build/ledtakt.spec.luau
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

local RunService = game:GetService("RunService")
RunService._server = true

local M = 3
local DT = 1 / 30
local NAV_STILLA = 1.2          -- samma tal som LedService, medvetet duplicerat
local LEDARFART  = 1.15 * 1.45  -- m/s: `skrittfart() * LEDNINGSTAKT`

local function vpos(xm, ym) return vec(xm * M, 3, ym * M) end

local nastaId = 200
local function nySpelare(namn, pos)
	nastaId += 1
	local k = Instance.new("Model")
	k.Name = "Karaktar"
	local rot = Instance.new("Part")
	rot.Name = "HumanoidRootPart"
	rot.Size = vec(2, 2, 1)
	rot.CFrame = CFrame.new(pos)
	rot.Parent = k
	k.PrimaryPart = rot
	local hum = Instance.new("Humanoid")
	hum.Name = "Humanoid"
	hum.Parent = k
	k.Parent = workspace
	return { Name = namn, UserId = nastaId, Character = k,
		CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }, rot
end

local function nyHast(id, pos)
	local m = Instance.new("Model")
	m.Name = id
	m:SetAttribute("HorseId", id)
	local kropp = Instance.new("Part")
	kropp.Name = "HumanoidRootPart"
	kropp.Size = vec(1.86, 2.34, 5.55)
	kropp.CFrame = CFrame.new(pos)
	kropp.Parent = m
	m.PrimaryPart = kropp
	local hum = Instance.new("Humanoid")
	hum.Name = "Humanoid"
	hum.Parent = m
	m.Parent = workspace
	return m, kropp
end

--[[ Ett pass: spelaren gar i ledningstakt, hasten i `hastfart` m/s, bada
	rakt vasterut. Startavstandet ligger over `START_R` sa att drivgrenen
	nas — ligger hon i dodzonen far hon ingen order alls, och da mater
	provet ingenting. Returnerar sessionens hogsta `stillaSedan`. ]]
local function pass(namn, hastfart, sekunder)
	LedService._glomForProv()
	local HX, HY = 100.0, 50.0
	local hast = nyHast("hast_" .. namn, vpos(HX, HY))
	local sp, rot = nySpelare("Ledare_" .. namn, vpos(HX + 3.5, HY))
	local ok, skal = LedService.borja(sp, hast, hast)
	if not ok then return nil, ("borja nekade: %s"):format(tostring(skal)) end

	local sx, hx = HX + 3.5, HX
	local hogsta, drevs, steg, fastnade, planerMax = 0, false, 0, 0, 0
	for _ = 1, math.floor(sekunder / DT) do
		sx += LEDARFART * DT
		hx += hastfart * DT
		rot.CFrame = CFrame.new(vpos(sx, HY))
		hast.PrimaryPart.CFrame = CFrame.new(vpos(hx, HY))
		LedService._steg(DT)
		local l = LedService.lage(sp)
		if l == nil then break end
		if l.delmal ~= nil then drevs = true end
		if (l.stillaSedan or 0) > hogsta then hogsta = l.stillaSedan end
		steg += 1
		if (l.stillaSedan or 0) > NAV_STILLA then fastnade += 1 end
		if (l.navPlaner or 0) > planerMax then planerMax = l.navPlaner end
	end
	--[[ `navPlaner` lases som TOPPVARDE under passet, inte efterat:
		kryppasset slapper pa `led.tappade_bort` innan det ar slut — kopplet
		vaxer 1,47 m/s nar hon gor 0,20 och ledaren 1,667 — och da finns
		ingen session kvar att fraga. ]]
	return {
		hogsta = hogsta,
		andel = if steg > 0 then fastnade / steg else 0,
		planer = planerMax,
		levde = LedService.lage(sp) ~= nil,
		drevs = drevs,
	}, nil
end

print("")
print("ANKARETS TAKT (M3 — kryphastighet ar inte att ga)")

print("")
print("-- 1. Gar hon i takt raknas hon som gaende --")
local takt, felA = pass("takt", 1.45, 6.0)
check("passet kom igang", felA == nil, tostring(felA))
check("drivgrenen nåddes — delmal sattes", takt ~= nil and takt.drevs == true)
check("i skritt (1,45 m/s) registreras hon ALDRIG som fastnad",
	takt ~= nil and takt.andel == 0,
	("andel fastnad %.0f %%, hogsta %.2f s"):format((takt and takt.andel or 1) * 100, takt and takt.hogsta or -1))
check("och planeraren behover aldrig kopplas in", takt ~= nil and takt.planer == 0,
	("navPlaner som mest %d"):format(takt and takt.planer or -1))
check("sessionen lever hela passet nar hon gar i takt", takt ~= nil and takt.levde == true)

print("")
print("-- 2. Kryper hon raknas hon INTE som gaende --")
--[[ ANDELEN, INTE TOPPVARDET, och det ar falsifieringen som tvingade
	fram det. Med den gamla regeln kopte krypningen sig fri en gang per
	radie, sa `stillaSedan` hann precis over NAV_STILLA en enda bildruta
	per cykel: toppvardet blev 1,23 mot gransen 1,20 och matningen kom ut
	GRON fast regeln var borttagen. Det ar samma sorts knivsegg som
	Studio matte — planeraren fick ett ogonblick och tappade det igen.

	Det som faktiskt betyder nagot ar hur STOR DEL av passet hon
	registreras som fastnad, for det ar den tiden `behoverVag` ar sann
	och atervinningen har en chans att bara. ]]
local kryp, felB = pass("kryp", 0.20, 6.0)
check("passet kom igang", felB == nil, tostring(felB))
check("drivgrenen nåddes — delmal sattes", kryp ~= nil and kryp.drevs == true)
check("vid 0,20 m/s — den uppmatta krypningen — ar hon fastnad merparten av tiden",
	kryp ~= nil and kryp.andel > 0.5,
	("andel fastnad %.0f %%, hogsta %.2f s"):format((kryp and kryp.andel or 0) * 100, kryp and kryp.hogsta or -1))
check("och planeraren kopplas in i stallet for att hon raknas som gaende",
	kryp ~= nil and kryp.planer > 0, ("navPlaner som mest %d"):format(kryp and kryp.planer or -1))

print("")
print("-- 3. Troskeln ar relativ till ordern, inte ett valt tal --")
--[[ NAV_TAKT ar 0,5 och ordern under catch-up ligger mellan 1,667 och
	2,00 m/s, sa gransen hamnar mellan 0,83 och 1,00 m/s. Talen 1,20 och
	0,60 star pa var sin sida om det bandet utan att specen skriver ut
	nagon egen troskel. ]]
local over = pass("over", 1.20, 6.0)
local under = pass("under", 0.60, 6.0)
check("1,20 m/s ligger over halva ordern och raknas som gaende",
	over ~= nil and over.andel == 0, ("andel %.0f %%"):format((over and over.andel or 1) * 100))
check("0,60 m/s ligger under och raknas inte",
	under ~= nil and under.andel > 0.5, ("andel %.0f %%"):format((under and under.andel or 0) * 100))

print("")
if fails > 0 then
	print(("ledtakt.spec: %d matning(ar) foll."):format(fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d matning(ar) foll."):format(fails), 0)
else
	print("ledtakt.spec: alla gröna")
end
