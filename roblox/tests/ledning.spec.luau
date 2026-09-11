--!nostrict
--[[
	LEDNINGEN — beslut och nej-vägar (#162 blockerare 2).

	Den fysiska följningen mäts i Studio-runtime; det här är tjänstens
	BESLUT. Varje negativt fall i ordern har en egen mätning, och varje
	mätning kräver ett SÄRSKILT skäl: ett samlat "gick inte" hade gjort
	fallen omöjliga att skilja åt, och då mäter specen ingenting.

	Specen sätter aldrig `lamnatBox` eller `malNatt` själv. Den flyttar
	hästen och låter `LedService._steg` — samma funktion Heartbeat kör i
	produktionen — avgöra. Skulle någon byta ut villkoren mot något som
	läser gränssnittet faller mätningarna.

	Kör: python3 roblox/tests/build.py tests/ledning.spec.luau
	     && luau roblox/tests/.build/ledning.spec.luau
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

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

RunService._server = true

local M = 3
local function vec(x, y, z) return Vector3.new(x, y, z) end

--[[ En karaktär: det tjänsten faktiskt läser. ]]
local function nyKaraktar(pos)
	local k = Instance.new("Model")
	k.Name = "Karaktar"
	local rot = Instance.new("Part")
	rot.Name = "HumanoidRootPart"
	rot.Size = vec(2, 2, 1)
	rot.CFrame = CFrame.new(pos)
	rot.Parent = k
	local hum = Instance.new("Humanoid")
	hum.Name = "Humanoid"
	hum.Parent = k
	return k, rot, hum
end

--[[ Samma spelarform som bänkens övriga specar: en tabell med det
	tjänsten läser. `Instance.new("Player")` finns inte i stubben. ]]
local function nySpelare(namn, pos)
	local k, rot, hum = nyKaraktar(pos)
	local p = {
		Name = namn, UserId = 1, Character = k,
		CharacterAdded = __signal_ny(),
		CharacterRemoving = __signal_ny(),
	}
	return p, rot, hum
end

local function nyHast(namn, pos)
	local m = Instance.new("Model")
	m.Name = namn
	m:SetAttribute("HorseId", namn)
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
	return m, kropp, hum
end

--[[ Tomtkoordinat → värld, samma omräkning som tjänsten. ]]
local function varld(x, y) return vec(x * M, 3, (170 - y) * M) end

print("\n── Att börja leda ──")

LedService._glomForProv()

local BOX = { x = 163.68, y = 77.60 }
local hast, hastKropp, hastHum = nyHast("blackrock_jack", varld(BOX.x, BOX.y))
local annanHast = nyHast("marabou", varld(170.10, 84.60))
local spelare, rot, hum = nySpelare("SagaAberg", varld(BOX.x + 1.0, BOX.y))

--[[ ── NEGATIVT: för långt bort ───────────────────────────────────── ]]
rot.CFrame = CFrame.new(varld(BOX.x + 20, BOX.y))
local ok1, skal1 = LedService.borja(spelare, hast, hast)
check("för långt bort → nekas med eget skäl", ok1 == false and skal1 == "led.for_langt",
	tostring(skal1))

--[[ ── NEGATIVT: fel häst ──────────────────────────────────────────── ]]
rot.CFrame = CFrame.new(varld(BOX.x + 1.0, BOX.y))
local ok2, skal2 = LedService.borja(spelare, annanHast, hast)
check("fel häst → nekas med eget skäl", ok2 == false and skal2 == "led.fel_hast",
	tostring(skal2))

--[[ ── NEGATIVT: sitter upp ────────────────────────────────────────── ]]
hum.Sit = true
local ok3, skal3 = LedService.borja(spelare, hast, hast)
check("sitter upp → leder inte, man rider", ok3 == false and skal3 == "led.rider",
	tostring(skal3))
hum.Sit = false

--[[ ── POSITIVT: intill rätt häst ──────────────────────────────────── ]]
local ok4, skal4 = LedService.borja(spelare, hast, hast)
check("intill rätt häst → ledningen börjar", ok4 == true, tostring(skal4))
check("tjänsten vet vilken häst som leds", LedService.aktiv(spelare) == hast)

--[[ ── NEGATIVT: dubbeltrigger ─────────────────────────────────────── ]]
local ok5, skal5 = LedService.borja(spelare, hast, hast)
check("dubbeltrigger → nekas", ok5 == false and skal5 == "led.leder_redan", tostring(skal5))

--[[ ── NEGATIVT: någon annan leder henne ───────────────────────────── ]]
local spelare2, rot2 = nySpelare("AnnanRyttare", varld(BOX.x + 1.0, BOX.y))
local ok6, skal6 = LedService.borja(spelare2, hast, hast)
check("två spelare kan inte leda samma häst", ok6 == false and skal6 == "led.upptagen",
	tostring(skal6))

print("\n── Hästen står kvar i boxen ──")

--[[ Tjänsten ska INTE tro att något hänt bara för att ledningen är på. ]]
LedService._steg(1 / 30)
check("hästen har inte lämnat boxen än", LedService.harLamnatBox(spelare) == false)
check("och hon har inte nått målet", LedService.harNattMal(spelare) == false)

local zon = { x = 122.4, y = 41.97, w = 20, h = 65.53 }
LedService.satMalzon(zon)

--[[ ── Hon lämnar boxen ───────────────────────────────────────────── ]]
hastKropp.CFrame = CFrame.new(varld(BOX.x + 4, BOX.y))
LedService._steg(1 / 30)
check("när hon fysiskt lämnat boxen ser tjänsten det",
	LedService.harLamnatBox(spelare) == true)
check("men målet är fortfarande inte nått", LedService.harNattMal(spelare) == false)

--[[ ── Hon når ridbanan ───────────────────────────────────────────── ]]
rot.CFrame = CFrame.new(varld(132, 70))
hastKropp.CFrame = CFrame.new(varld(132, 72))
LedService._steg(1 / 30)
check("när hon fysiskt står i ridbanan ser tjänsten det",
	LedService.harNattMal(spelare) == true)

print("\n── Följandet ──")

--[[ Målpunkten ska ligga BAKOM spelaren, inte på henne. ]]
rot.CFrame = CFrame.new(varld(132, 60))
hastKropp.CFrame = CFrame.new(varld(132, 66))
LedService._steg(1 / 30)
local mal = hastHum._moveMal
check("tjänsten ger hästen ett mål när avståndet växer", mal ~= nil)
if mal then
	local avstTillSpelare = (mal - rot.Position).Magnitude / M
	check("målet ligger bakom spelaren, inte på henne",
		avstTillSpelare > 1.5 and avstTillSpelare < 4.0,
		string.format("%.2f m", avstTillSpelare))
end

--[[ HYSTERESEN: står hon nära nog ska hon STÅ, inte pendla. ]]
hastKropp.CFrame = CFrame.new(rot.Position - vec(0, 0, 2.2 * M))
hastHum._moveDir = nil
LedService._steg(1 / 30)
LedService._steg(1 / 30)
check("innanför dödzonen får hon order att STÅ, inte att gå",
	hastHum._moveDir ~= nil, tostring(hastHum._moveDir))

print("\n── Kopplet ──")

--[[ ── NEGATIVT: spelaren lämnar hästen ────────────────────────────── ]]
rot.CFrame = CFrame.new(varld(132, 20))
LedService._steg(1 / 30)
check("spelaren går ifrån henne → kopplet släpper",
	LedService.aktiv(spelare) == nil)

print("\n── Att släppa ──")

rot.CFrame = CFrame.new(varld(BOX.x + 1.0, BOX.y))
hastKropp.CFrame = CFrame.new(varld(BOX.x, BOX.y))
LedService.borja(spelare, hast, hast)
local ok7 = LedService.slapp(spelare)
check("spelaren kan avbryta ledningen", ok7 == true)
check("och då leder hon ingen", LedService.aktiv(spelare) == nil)
local ok8, skal8 = LedService.slapp(spelare)
check("att släppa när man inte leder nekas", ok8 == false and skal8 == "led.leder_inte",
	tostring(skal8))

--[[ ── NEGATIVT: spelaren sitter upp mitt i ledningen ──────────────── ]]
LedService.borja(spelare, hast, hast)
hum.Sit = true
LedService._steg(1 / 30)
check("sitter man upp mitt i ledningen släpper den",
	LedService.aktiv(spelare) == nil)
hum.Sit = false

if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("\nledning.spec: alla gröna")
end
