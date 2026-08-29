--!nostrict
--[[
	Mätningar på ryttarens sekundärrörelse.

	Sekundärrörelsen är det som skiljer en ryttare från en last: kroppen
	hamnar efter när hästen ökar, kommer före när den bromsar, och söker sig
	inåt i svängen. Den påstådda känslan går att falsifiera med siffror —
	utslag i grader, riktning, tak och nollställning.

	Kör: python3 roblox/tests/build.py roblox/tests/rider.spec.luau
	     && luau roblox/tests/.build/rider.luau
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

local GRAD = 180 / math.pi

--[[ En rigg med sits. Attachment-punkterna saknas med flit: de hör till
     IK-kedjorna, som bara går att köra i Studio. Sekundärrörelsen ska
     fungera utan dem. ]]
local function newRC()
	local rig = __makeRig()
	rig.seat = __makeJoint("Seat")
	return RiderController.new(rig), rig
end

local function loco(speed, lean)
	return { speed = speed, lean = lean or 0, gait = "trot", phase = 0,
		heading = 0, turnRate = 0, grounded = true, airborne = false }
end

--[[ Kör en tempokurva och returnerar det extremvärde pitch nådde. Utslaget
     är utjämnat med ACCEL_TAU, så det syns inte i första bildrutan och är
     borta igen några tiondelar efter att farten planat ut — därför spåras
     extremvärdet under loopen, inte slutvärdet. ]]
local function svep(rc, fran, till, sekunder, dt)
	dt = dt or 1 / 60
	local steg = math.floor(sekunder / dt + 0.5)
	local topp, botten = 0, 0
	for i = 1, steg do
		local speed = fran + (till - fran) * (i / steg)
		rc:step(loco(speed), dt)
		topp = math.max(topp, rc.pitch)
		botten = math.min(botten, rc.pitch)
	end
	return topp, botten
end

print("\n── Tröghet: kroppen hamnar efter hästen ──")
do
	local rc = newRC()
	--[[ Stilla först: en ryttare som lutar utan att något händer är trasig. ]]
	for _ = 1, 60 do rc:step(loco(0), 1 / 60) end
	check("stillastående ger ingen lutning",
		math.abs(rc.pitch) < 1e-6 and math.abs(rc.roll) < 1e-6,
		string.format("(pitch %.4f°, roll %.4f°)", rc.pitch * GRAD, rc.roll * GRAD))

	--[[ Uppsläpp till trav på 1,2 s ≈ 2,7 m/s². ]]
	local _, ned = svep(rc, 0, 3.2, 1.2)
	local accel = 3.2 / 1.2
	check("acceleration lutar ryttaren bakåt", ned < -0.004,
		string.format("(%.2f m/s² → %.2f°)", accel, ned * GRAD))

	--[[ Och samma sak baklänges: hård inbromsning kastar henne framåt. ]]
	local rc2 = newRC()
	svep(rc2, 0, 5.6, 2.0)
	local upp = select(1, svep(rc2, 5.6, 0, 1.0))
	check("inbromsning lutar ryttaren framåt", upp > 0.004,
		string.format("(%.2f m/s² → %.2f°)", -5.6 / 1.0, upp * GRAD))

	--[[ Riktningarna ska vara motsatta, annars är tecknet fel någonstans. ]]
	check("acceleration och inbromsning ger motsatta tecken", ned < 0 and upp > 0)
end

print("\n── Taken: hård inbromsning blir inte en kullerbytta ──")
do
	--[[ En kollision är ett tempofall på en bildruta. Utan tak skulle
	     derivatan då bli hundratals m/s² och ryttaren slå runt. ]]
	local rc = newRC()
	for _ = 1, 120 do rc:step(loco(8), 1 / 60) end
	local topp = 0
	for _ = 1, 60 do
		rc:step(loco(0), 1 / 60)
		topp = math.max(topp, math.abs(rc.pitch))
	end
	check("tvärstopp håller sig innanför taket", topp <= 0.055 + 1e-9,
		string.format("(%.2f°, tak 3,15°)", topp * GRAD))

	--[[ Att utslaget stannar långt under taket vid ett tvärstopp är
	     utjämningen, inte taket: en enda bildruta hinner bara igenom
	     ~9 % av kurvan. Det är önskvärt — en krock ska kännas som ett
	     ryck, inte som ett kast. ]]
	check("utjämningen dämpar krockspiken av sig själv", topp < 0.015,
		string.format("(%.2f° av tillåtna 3,15°)", topp * GRAD))

	--[[ Taket ska ändå nås av en ihållande hård inbromsning, annars är
	     det bara dekoration. 5,6 → 0 på en halv sekund är −11 m/s², som
	     klampas till −6 och hålls där. ]]
	local rc2 = newRC()
	for _ = 1, 120 do rc2:step(loco(5.6), 1 / 60) end
	local nadd = select(1, svep(rc2, 5.6, 0, 0.5))
	check("ihållande hård inbromsning når taket", nadd >= 0.055 - 1e-9,
		string.format("(%.4f rad av 0,0550)", nadd))
end

print("\n── Balansen: en tredjedel av hästens lutning ──")
do
	local rc = newRC()
	local h = Config.MOVEMENT.LeanMax
	for _ = 1, 60 do rc:step(loco(3.2, h), 1 / 60) end
	check("balansen är en dryg tredjedel av hästens lutning",
		math.abs(rc.roll - h * 0.34) < 1e-9,
		string.format("(häst %.2f° → ryttare %.2f°)", h * GRAD, rc.roll * GRAD))
	check("ryttaren lutar åt samma håll som hästen", rc.roll > 0 and h > 0)
	check("balansen ligger under sitt tak", math.abs(rc.roll) <= 0.030 + 1e-9,
		string.format("(%.4f av 0,0300)", math.abs(rc.roll)))

	--[[ Vänstersväng ska spegla högersvängen. ]]
	local rcv = newRC()
	for _ = 1, 60 do rcv:step(loco(3.2, -h), 1 / 60) end
	check("vänstersväng speglar högersväng",
		math.abs(rcv.roll + rc.roll) < 1e-9,
		string.format("(%.2f° mot %.2f°)", rcv.roll * GRAD, rc.roll * GRAD))
end

print("\n── Sitsen: offsetten ackumuleras inte ──")
do
	--[[ Det klassiska felet är att skriva C0 = C0 * rotation varje bildruta:
	     efter en minut sitter ryttaren upp och ner. Basen sparas därför en
	     gång som attribut och varje bildruta räknas från den. ]]
	local rc, rig = newRC()
	svep(rc, 0, 5.6, 2.0)
	local bas = rig.seat:GetAttribute("BaseRiderC0")
	check("basposen sparas som attribut", bas ~= nil)
	check("sitsen roterar kring pitch och roll, inte yaw",
		math.abs(rig.seat.C0.Yaw) < 1e-9)

	--[[ Efter 20 s stillastående ska sitsen vara tillbaka i basposen. ]]
	for _ = 1, 20 * 60 do rc:step(loco(0), 1 / 60) end
	check("sitsen återgår helt till basposen",
		math.abs(rig.seat.C0.Pitch) < 1e-4 and math.abs(rig.seat.C0.Roll) < 1e-4,
		string.format("(pitch %.6f, roll %.6f)", rig.seat.C0.Pitch, rig.seat.C0.Roll))

	--[[ Och avsittning nollställer direkt, inte efter en utdöende kurva. ]]
	svep(rc, 0, 5.6, 1.0)
	rc:release()
	check("release nollställer sitsen på en gång",
		math.abs(rig.seat.C0.Pitch) < 1e-9 and math.abs(rig.seat.C0.Roll) < 1e-9
			and rc.pitch == 0 and rc.roll == 0)
end

print("\n── Degradering: rigg utan sits ──")
do
	--[[ Saknas sitsen ska modulen räkna vidare utan att krascha — samma
	     regel som IK-kedjorna följer. ]]
	local rig = __makeRig()
	local rc = RiderController.new(rig)
	local ok = pcall(function() svep(rc, 0, 5.6, 1.0) end)
	check("rigg utan sits kraschar inte", ok)
	check("signalerna räknas ändå", ok and math.abs(rc.pitch) > 0)
end

print("\n── Bildrutetakt: samma utslag vid 30 och 144 fps ──")
do
	--[[ Utjämningen är exponentiell i dt, inte en fast andel per bildruta.
	     Ett rimligt strängt krav är att topputslaget skiljer mindre än 2 %
	     mellan tre bildrutetakter. ]]
	local utslag = {}
	for _, fps in { 30, 60, 144 } do
		local rc = newRC()
		local _, ned = svep(rc, 0, 5.6, 1.5, 1 / fps)
		utslag[fps] = ned
	end
	local lag, hog = math.min(utslag[30], utslag[60], utslag[144]),
		math.max(utslag[30], utslag[60], utslag[144])
	local spridning = math.abs((hog - lag) / lag)
	check("utslaget är bildrutetaktoberoende", spridning < 0.02,
		string.format("(30: %.3f°, 60: %.3f°, 144: %.3f° — %.2f %% spridning)",
			utslag[30] * GRAD, utslag[60] * GRAD, utslag[144] * GRAD, spridning * 100))
end

print("")
if fails > 0 then
	print(string.format("%d mätning(ar) föll.", fails))
else
	print("Alla mätningar gick igenom.")
end
