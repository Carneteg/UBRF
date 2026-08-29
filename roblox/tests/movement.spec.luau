--!nostrict
--[[
	Mätningar på rörelsen. Varje rad är ett påstående om känsla som går att
	falsifiera med en siffra — inte ett omdöme.

	Kör: python3 roblox/tests/build.py && luau roblox/tests/.build/movement.luau
]]


local STATS = {
	Speed = 0.5, Acceleration = 0.5, Agility = 0.5, Stamina = 0.5,
	MaxStamina = 100, Temperament = "Calm",
}

local function intent(o)
	o = o or {}
	return { forward = o.forward or 0, steer = o.steer or 0,
		gaitUp = o.gaitUp or false, gaitDown = o.gaitDown or false,
		jump = o.jump or false }
end

--[[ Kör n sekunder med fast dt och samma avsikt. Returnerar controllern. ]]
local function run(mc, seconds, o, dt)
	dt = dt or 1 / 60
	local steps = math.floor(seconds / dt + 0.5)
	for _ = 1, steps do mc:step(intent(o), dt) end
	return mc
end

local function newMC()
	return MovementController.new(__makeRig(), STATS)
end

local fails = 0
local function check(namn, villkor, detalj)
	if villkor then
		print(string.format("  OK   %s%s", namn, detalj and ("  " .. detalj) or ""))
	else
		fails += 1
		print(string.format("  FEL  %s%s", namn, detalj and ("  " .. detalj) or ""))
	end
end

print("\n── Insticksrespons (mindre binär A/D) ──")
do
	--[[ Hur mycket svänger hästen på ETT kort tryck? Ett binärt instick ger
	     samma utslag oavsett hur kort man rör tangenten — det är känslan
	     issue #12 kallar binär. Ett rampat instick ger mindre utslag på
	     kortare tryck, alltså går det att styra fint. ]]
	local function headingAfterTap(hold)
		local mc = newMC()
		run(mc, 2.0, { forward = 1 })              -- upp i skritt först
		local h0 = mc.loco.heading
		run(mc, hold, { forward = 1, steer = 1 })
		run(mc, 0.6, { forward = 1 })              -- låt svängen dö ut
		return math.abs(mc.loco.heading - h0)
	end
	local kort, lang = headingAfterTap(0.08), headingAfterTap(0.50)
	local kvot = lang / math.max(kort, 1e-6)
	print(string.format("  kort tryck 0,08 s → %.3f rad", kort))
	print(string.format("  långt tryck 0,50 s → %.3f rad", lang))
	print(string.format("  kvot lång/kort = %.1f", kvot))
	check("kort tryck ger märkbart mindre utslag än långt", kvot >= 4.0,
		string.format("(kvot %.1f, kräver ≥ 4)", kvot))
end

print("\n── Låg fart: creep och vändning på stället ──")
do
	local mc = newMC()
	run(mc, 1.0, {})                                -- står stilla i halt
	local mcSpeedBefore = mc.loco.speed
	local rig = mc.rig
	rig.humanoid._moves = {}
	run(mc, 1.0, { steer = 1 })                     -- vänd på stället
	local ws = rig.humanoid.WalkSpeed
	print(string.format("  fart i halt: %.3f m/s", mcSpeedBefore))
	print(string.format("  WalkSpeed vid vändning på stället: %.3f studs/s", ws))
	print(string.format("  heading vred sig: %.3f rad", math.abs(mc.loco.heading)))
	check("ingen synlig creep när hästen vänder på stället", ws < 0.05,
		string.format("(WalkSpeed %.3f, kräver < 0,05)", ws))
	check("hästen vänder sig ändå på stället", math.abs(mc.loco.heading) > 0.2,
		string.format("(%.3f rad)", math.abs(mc.loco.heading)))
end

print("\n── Bildfrekvensoberoende ──")
do
	local function after(dt)
		local mc = newMC()
		run(mc, 3.0, { forward = 1, steer = 1 }, dt)
		return mc.loco.speed, mc.loco.heading
	end
	local s30, h30 = after(1 / 30)
	local s60, h60 = after(1 / 60)
	local s144, h144 = after(1 / 144)
	local ds = math.max(math.abs(s30 - s144), math.abs(s60 - s144))
	local dh = math.max(math.abs(h30 - h144), math.abs(h60 - h144))
	print(string.format("  fart  30 Hz %.4f | 60 Hz %.4f | 144 Hz %.4f", s30, s60, s144))
	print(string.format("  kurs  30 Hz %.4f | 60 Hz %.4f | 144 Hz %.4f", h30, h60, h144))
	check("farten är oberoende av bildfrekvens", ds < 0.02,
		string.format("(spridning %.4f m/s)", ds))
	check("kursen är oberoende av bildfrekvens", dh < 0.05,
		string.format("(spridning %.4f rad)", dh))
end

print("\n── Acceleration och inbromsning ──")
do
	local mc = newMC()
	local t, dt, tider = 0, 1 / 60, {}
	local mal = { walk = false, trot = false }
	for _ = 1, 60 * 12 do
		mc:step(intent({ forward = 1, gaitUp = (t > 3 and t < 3 + dt) }), dt)
		t += dt
		if not mal.walk and mc.loco.speed > 1.40 then mal.walk = t end
		if not mal.trot and mc.loco.speed > 3.10 then mal.trot = t end
	end
	print(string.format("  nådde skritt-tempo efter %.2f s", mal.walk or -1))
	print(string.format("  nådde trav-tempo efter %.2f s (bytte vid 3,00)", mal.trot or -1))
	check("skritt tar fäste inom en sekund", mal.walk and mal.walk < 1.0,
		string.format("(%.2f s)", mal.walk or -1))
	check("gångartsbytet syns inom en sekund", mal.trot and (mal.trot - 3.0) < 1.0,
		string.format("(%.2f s efter bytet)", (mal.trot or 0) - 3.0))
end

print("\n── Svarsprofil: tar snabbt, släpper mjukt ──")
do
	--[[ En bra styrning bygger upp svängen fort när man ber om den och
	     lämnar den mjukt när man släpper. Mäts som tid till halva utslaget
	     respektive tid tillbaka till nära noll. ]]
	local mc = newMC()
	run(mc, 3.0, { forward = 1, gaitUp = false })
	run(mc, 0.5, { forward = 1, gaitUp = true })
	local dt, t = 1 / 240, 0
	local topp, tHalv = 0, nil
	for _ = 1, 240 * 2 do
		mc:step(intent({ forward = 1, steer = 1 }), dt); t += dt
		topp = math.max(topp, math.abs(mc.loco.turnRate))
	end
	local mal = topp
	mc = newMC(); run(mc, 3.5, { forward = 1 }); t = 0
	for _ = 1, 240 * 2 do
		mc:step(intent({ forward = 1, steer = 1 }), dt); t += dt
		if not tHalv and math.abs(mc.loco.turnRate) >= mal * 0.5 then tHalv = t end
	end
	local tSlapp = 0
	for _ = 1, 240 * 2 do
		mc:step(intent({ forward = 1 }), dt); tSlapp += dt
		if math.abs(mc.loco.turnRate) <= mal * 0.1 then break end
	end
	print(string.format("  tid till halva svängen: %.3f s", tHalv or -1))
	print(string.format("  tid tillbaka till nära noll: %.3f s", tSlapp))
	check("svängen tar fäste snabbt", tHalv and tHalv < 0.30,
		string.format("(%.3f s, kräver < 0,30)", tHalv or -1))
	check("svängen släpper utan att snäppa", tSlapp > 0.05,
		string.format("(%.3f s)", tSlapp))
end

print("")
if fails > 0 then
	print(string.format("%d mätning(ar) föll.", fails))
else
	print("Alla mätningar gick igenom.")
end

print("\n── Gångartsbyten: inget flimmer vid gränserna ──")
do
	--[[ Det som gör ett gångartsbyte orent är flimmer: hästen ligger på en
	     bandgräns och gångarten hoppar fram och tillbaka mellan bildrutor,
	     så animationen studsar. Mäts genom att sakta rulla farten genom
	     hela spannet och räkna hur många gånger gångarten byter. En ren
	     upprullning från halt till fyrsprång ska ge fyra byten, inte fler. ]]
	local mc = newMC()
	local dt = 1 / 60
	local byten, forra = 0, mc.loco.gait
	local sekvens = { mc.loco.gait }
	--[[ Stega upp en gångart var tredje sekund och låt farten hinna ifatt. ]]
	for steg = 1, 4 do
		for i = 1, 180 do
			mc:step(intent({ forward = 1, gaitUp = (i == 1) }), dt)
			if mc.loco.gait ~= forra then
				byten += 1; forra = mc.loco.gait
				table.insert(sekvens, mc.loco.gait)
			end
		end
	end
	print("  uppåt:  " .. table.concat(sekvens, " → "))
	check("fyra byten upp, inget flimmer", byten == 4,
		string.format("(%d byten)", byten))

	--[[ Och samma väg ned. ]]
	local ned, forraNed = 0, mc.loco.gait
	local sekvensNed = { mc.loco.gait }
	for steg = 1, 4 do
		for i = 1, 180 do
			mc:step(intent({ forward = 0, gaitDown = (i == 1) }), dt)
			if mc.loco.gait ~= forraNed then
				ned += 1; forraNed = mc.loco.gait
				table.insert(sekvensNed, mc.loco.gait)
			end
		end
	end
	print("  nedåt:  " .. table.concat(sekvensNed, " → "))
	check("fyra byten ned, inget flimmer", ned == 4,
		string.format("(%d byten)", ned))
end

print("\n── Låg fart: precision i skritt ──")
do
	--[[ Precision vid låg fart betyder att man kan lägga en liten
	     kursändring utan att hästen kastar sig runt. Mäts som kurs efter
	     ett halvsekunds utslag i skritt jämfört med i fyrsprång — skritt
	     ska ge finare kontroll, alltså mindre utslag per tidsenhet. ]]
	local function svangIGangart(gangart, steg)
		local mc = newMC()
		for _ = 1, steg do mc:step(intent({ forward = 1, gaitUp = true }), 1 / 60) end
		run(mc, 4.0, { forward = 1 })
		local h0 = mc.loco.heading
		run(mc, 0.5, { forward = 1, steer = 1 })
		local d = math.abs((mc.loco.heading - h0 + math.pi) % (2 * math.pi) - math.pi)
		return d, mc.loco.speed
	end
	local dSkritt, vSkritt = svangIGangart("walk", 1)
	local dGalopp, vGalopp = svangIGangart("gallop", 4)
	print(string.format("  skritt    (%.1f m/s): %.3f rad på 0,5 s", vSkritt, dSkritt))
	print(string.format("  fyrsprång (%.1f m/s): %.3f rad på 0,5 s", vGalopp, dGalopp))
	check("skritt ger finare kontroll än fyrsprång", dSkritt < dGalopp,
		string.format("(%.3f mot %.3f rad)", dSkritt, dGalopp))
end
