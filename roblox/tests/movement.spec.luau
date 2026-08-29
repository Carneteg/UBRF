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

--[[ ── En rigg som faktiskt förflyttar sig ────────────────────────────
     `run` ovan låter roten stå still: Humanoid finns inte här, så ingen
     flyttar den. Det räcker för att mäta styrning och gångarter, men inte
     för att mäta något som beror på verklig förflyttning — och fasen gör
     numera just det.

     `runMoving` gör det Roblox Humanoid gör: den tar riktningen och
     farten koden själv skrev, och integrerar positionen med samma dt.
     Ingen fysik, ingen friktion — bara den förflyttning koden begärt.
     Blockeras hästen (`block = true`) skrivs ingen position alls, vilket
     är precis vad en vägg gör. ]]
local function runMoving(mc, seconds, o, dt, block)
	dt = dt or 1 / 60
	local rig = mc.rig
	local steps = math.floor(seconds / dt + 0.5)
	local travelled = 0
	for _ = 1, steps do
		mc:step(intent(o), dt)
		local hum = rig.humanoid
		local dir = hum._moves[#hum._moves]
		if dir and not block then
			local steg = hum.WalkSpeed * dt
			local ny = rig.root.Position + dir * steg
			travelled += steg
			rig.root.Position = ny
			rig.root.CFrame = CFrame.new(ny) * CFrame.Angles(0, mc.loco.heading, 0)
		end
	end
	return travelled / Config.STUDS_PER_METRE
end

--[[ Kursen som faktiskt står skriven på riggen, inte den vi räknat fram. ]]
local function rigYaw(mc)
	return mc.rig.root.CFrame.Yaw % (2 * math.pi)
end

local function vinkelDiff(a, b)
	local d = (a - b) % (2 * math.pi)
	if d > math.pi then d -= 2 * math.pi end
	return d
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
	     lämnar den mjukt när man släpper. Mäts som tid till halva
	     utslaget respektive tid tillbaka till nära noll.

	     Referensvärdet MÅSTE mätas i samma gångart som mätningen sker i:
	     med kurvaturmodellen skalar vridhastigheten med tempot, så ett
	     toppvärde från en högre gångart går aldrig att nå i en lägre.
	     Den första versionen av det här testet gjorde just det och
	     rapporterade ett fel som inte fanns. ]]
	local dt = 1 / 240
	local function varmUpp()
		local mc = newMC()
		run(mc, 3.0, { forward = 1 })       -- upp i skritt och låt tempot sätta sig
		return mc
	end
	--[[ Steg 1: vad ÄR full sväng i den här gångarten? ]]
	local mc = varmUpp()
	local topp = 0
	for _ = 1, 240 * 2 do
		mc:step(intent({ forward = 1, steer = 1 }), dt)
		topp = math.max(topp, math.abs(mc.loco.turnRate))
	end
	--[[ Steg 2: hur fort når vi halva den? ]]
	mc = varmUpp()
	local t, tHalv = 0, nil
	for _ = 1, 240 * 2 do
		mc:step(intent({ forward = 1, steer = 1 }), dt); t += dt
		if not tHalv and math.abs(mc.loco.turnRate) >= topp * 0.5 then tHalv = t end
	end
	--[[ Steg 3: hur mjukt släpper den? ]]
	local tSlapp = 0
	for _ = 1, 240 * 3 do
		mc:step(intent({ forward = 1 }), dt); tSlapp += dt
		if math.abs(mc.loco.turnRate) <= topp * 0.1 then break end
	end
	print(string.format("  full sväng i skritt: %.3f rad/s", topp))
	print(string.format("  tid till halva svängen: %.3f s", tHalv or -1))
	print(string.format("  tid tillbaka till nära noll: %.3f s", tSlapp))
	check("svängen tar fäste snabbt", tHalv ~= nil and tHalv < 0.30,
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

print("\n── Svängradie per gångart och nivå (paritet mot webben) ──")
do
	--[[ Samma tabell som webbversionens mätning, så att paritetsraden i
	     auditen bygger på jämförbara siffror och inte på en beskrivning.
	     Tempot låses vid gångartens hemtempo och styrningen hålls tills
	     kurvaturen satt sig. ]]
	local dt = 1 / 120
	local rader = {}
	for _, rad in { { "walk", 1.45, 2 }, { "trot", 3.20, 3 }, { "canter", 5.60, 4 } } do
		local namn, tempo, steg = rad[1], rad[2], rad[3]
		for _, s in { 0.25, 0.50, 1.00 } do
			local mc = newMC()
			--[[ Stega upp i rätt gångart, lås sedan tempot. ]]
			for _ = 1, steg do
				for i = 1, 120 * 3 do
					mc:step(intent({ forward = 1, gaitUp = (i == 1) }), dt)
				end
			end
			mc.loco.speed = tempo
			for _ = 1, 120 * 3 do
				mc.loco.speed = tempo
				mc:step(intent({ forward = 1, steer = s }), dt)
			end
			local k = math.abs(mc.curvature)
			local omega = math.abs(mc.loco.turnRate)
			rader[#rader + 1] = { namn = namn, tempo = tempo, styr = s,
				kappa = k, radie = if k > 1e-4 then 1 / k else 999,
				grader = omega * 180 / math.pi }
		end
	end
	print("  gångart  tempo  styr   kurvatur  radie(m)   °/s")
	for _, r in rader do
		print(string.format("  %-8s %5.2f  %.2f   %.4f   %7.2f   %5.1f",
			r.namn, r.tempo, r.styr, r.kappa, r.radie, r.grader))
	end
	--[[ Kravet: radien ska ÖKA med gångarten vid samma styrutslag. ]]
	local full = {}
	for _, r in rader do if r.styr == 1.00 then full[r.namn] = r.radie end end
	check("radien ökar med gångarten vid full styrning",
		full.walk < full.trot and full.trot < full.canter,
		string.format("(%.1f → %.1f → %.1f m)", full.walk, full.trot, full.canter))
	--[[ Och 25 < 50 < 100 i kurvatur, alltså tre användbara nivåer. ]]
	local w = {}
	for _, r in rader do if r.namn == "walk" then w[r.styr] = r.kappa end end
	check("25/50/100 % ger tre skilda kurvaturer",
		w[0.25] < w[0.50] and w[0.50] < w[1.00],
		string.format("(%.4f < %.4f < %.4f)", w[0.25], w[0.50], w[1.00]))
end

--[[ Stega upp till en gångart med samma gaitUp-pulser som spelaren ger. ]]
local function upToGait(mc, steg, dt)
	dt = dt or 1 / 60
	for _ = 1, steg do
		for i = 1, math.floor(2.5 / dt) do
			mc:step(intent({ forward = 1, gaitUp = (i == 1) }), dt)
			local hum = mc.rig.humanoid
			local dir = hum._moves[#hum._moves]
			if dir then
				local ny = mc.rig.root.Position + dir * (hum.WalkSpeed * dt)
				mc.rig.root.Position = ny
				mc.rig.root.CFrame = CFrame.new(ny) * CFrame.Angles(0, mc.loco.heading, 0)
			end
		end
	end
end

print("\n── Blocker A: riggens kurs följer den vi räknat fram ──")
do
	--[[ `HorseService` sätter AutoRotate = false. Då finns det ingen som
	     vrider riggen åt oss, och den enda kurs spelaren ser är den som
	     står skriven på roten. Mätningen jämför den mot `loco.heading`.
	     Innan rättningen skrevs kursen bara vid vändning på stället: under
	     ritt böjde rörelsevektorn av medan riggen stod kvar och pekade
	     rakt fram. ]]
	local rader = {}
	for _, fall in { { 1, "walk" }, { 2, "trot" }, { 3, "canter" } } do
		local mc = newMC()
		upToGait(mc, fall[1])
		runMoving(mc, 2.0, { forward = 1, steer = 1 })
		local avvik = math.abs(vinkelDiff(rigYaw(mc), mc.loco.heading))
		table.insert(rader, { gangart = mc.loco.gait, heading = mc.loco.heading,
			yaw = rigYaw(mc), avvik = avvik })
	end
	print("  gångart   loco.heading  riggens yaw   avvikelse")
	local varst = 0
	for _, r in rader do
		varst = math.max(varst, r.avvik)
		print(string.format("  %-8s  %8.4f      %8.4f     %.2e rad",
			r.gangart, r.heading, r.yaw, r.avvik))
	end
	check("riggen pekar dit hästen är på väg i alla gångarter", varst < 1e-6,
		string.format("(värsta avvikelsen %.2e rad)", varst))

	--[[ Rak linje: ingen drift. En kurs som kryper utan styrning är det
	     som får en häst att gå snett över ridhuset. ]]
	local mc = newMC()
	upToGait(mc, 2)
	local h0 = mc.loco.heading
	runMoving(mc, 5.0, { forward = 1 })
	local drift = math.abs(vinkelDiff(rigYaw(mc), h0))
	check("ingen kursdrift utan styrutslag", drift < 1e-9,
		string.format("(%.2e rad på 5 s i %s)", drift, mc.loco.gait))

	--[[ Vändning vänster → höger ska passera neutralläget utan snärt.
	     Måttet är största kurssteg per bildruta: ett snäpp syns som en
	     enda ruta som är mångdubbelt större än de omkring. ]]
	local mcv = newMC()
	upToGait(mcv, 2)
	runMoving(mcv, 1.5, { forward = 1, steer = -1 })
	local forra, storst, dt = rigYaw(mcv), 0, 1 / 60
	local passerade = false
	for _ = 1, math.floor(3.0 / dt) do
		local innan = mcv.loco.turnRate
		runMoving(mcv, dt, { forward = 1, steer = 1 }, dt)
		if innan * mcv.loco.turnRate < 0 then passerade = true end
		local nu = rigYaw(mcv)
		storst = math.max(storst, math.abs(vinkelDiff(nu, forra)))
		forra = nu
	end
	check("vänster → höger passerar faktiskt genom neutralt", passerade)
	check("och gör det utan snäpp", storst < 0.03,
		string.format("(största kurssteg %.4f rad/bildruta i %s)", storst, mcv.loco.gait))

	--[[ Vändning på stället ska fortfarande fungera, och övergången till
	     framåtrörelse får inte ge ett hopp i kursen. ]]
	local mcs = newMC()
	local fore = rigYaw(mcs)
	runMoving(mcs, 1.5, { steer = 1 })
	local efterStilla = rigYaw(mcs)
	check("vändning på stället vrider riggen",
		math.abs(vinkelDiff(efterStilla, fore)) > 0.3,
		string.format("(%.3f rad)", math.abs(vinkelDiff(efterStilla, fore))))

	local forraS, storstS = efterStilla, 0
	for _ = 1, math.floor(2.5 / dt) do
		runMoving(mcs, dt, { forward = 1, steer = 1 }, dt)
		local nu = rigYaw(mcs)
		storstS = math.max(storstS, math.abs(vinkelDiff(nu, forraS)))
		forraS = nu
	end
	check("övergången från vändning på stället till ritt är kontinuerlig",
		storstS < 0.03, string.format("(största kurssteg %.4f rad/bildruta)", storstS))
end

print("\n── Blocker B: sträcka per fasvarv ──")
do
	--[[ CYKELLÄNGD = sträckan under ETT helt normaliserat fasvarv, fas
	     0 → 1. Den mäts här som den faktiskt blir, inte som tabellen
	     påstår. Fasen summeras kontinuerligt i stället för att räkna hela
	     varv: annars kastas den sista ofullständiga biten och siffran blir
	     några procent fel av ren avrundning. ]]
	local function matCykel(steg, sekunder)
		local mc = newMC()
		upToGait(mc, steg)
		local dt, forra, varv, stracka = 1 / 60, mc.loco.phase, 0, 0
		for _ = 1, math.floor(sekunder / dt) do
			stracka += runMoving(mc, dt, { forward = 1 }, dt)
			varv += (mc.loco.phase - forra) % 1
			forra = mc.loco.phase
		end
		return { gangart = mc.loco.gait, stracka = stracka, varv = varv,
			perVarv = stracka / varv, tabell = Gaits.cycleLength(mc.loco.gait) }
	end

	print("  gångart   sträcka   fasvarv   m/varv   tabell   avvikelse")
	local varst = 0
	for _, steg in { 1, 2, 3 } do
		local r = matCykel(steg, 20.0)
		local avvik = math.abs(r.perVarv - r.tabell) / r.tabell
		varst = math.max(varst, avvik)
		print(string.format("  %-8s  %6.1f m   %6.2f   %.3f    %.3f    %.2f %%",
			r.gangart, r.stracka, r.varv, r.perVarv, r.tabell, avvik * 100))
	end
	check("uppmätt sträcka per fasvarv följer cycleLength", varst < 0.005,
		string.format("(värsta avvikelsen %.3f %%)", varst * 100))

	--[[ 10 m och 20 m rak linje: antalet fasvarv ska fördubblas. ]]
	local varvVid = {}
	for _, mal in { 10, 20 } do
		local mc = newMC()
		upToGait(mc, 2)
		local dt, forra, varv, gatt = 1 / 60, mc.loco.phase, 0, 0
		while gatt < mal do
			gatt += runMoving(mc, dt, { forward = 1 }, dt)
			varv += (mc.loco.phase - forra) % 1
			forra = mc.loco.phase
		end
		varvVid[mal] = varv
		print(string.format("  %2d m i %-7s → %.2f fasvarv", mal, mc.loco.gait, varv))
	end
	check("dubbel sträcka ger dubbelt antal fasvarv",
		math.abs(varvVid[20] / varvVid[10] - 2) < 0.02,
		string.format("(kvot %.4f)", varvVid[20] / varvVid[10]))

	--[[ Ingen förflyttning ska inte flytta fasen — inte ens när koden
	     begär full fart. Det är krocken mot väggen. Den allra första
	     bildrutan efter blockeringen bär den sträcka hästen HANN gå innan
	     den tog i väggen, så kravet är att fasen stannar därefter. ]]
	local mcb = newMC()
	upToGait(mcb, 2)
	local dt = 1 / 60
	runMoving(mcb, dt, { forward = 1 }, dt, true)      -- bildrutan som bär resten
	local fasFore = mcb.loco.phase
	runMoving(mcb, 3.0, { forward = 1 }, dt, true)
	check("blockerad häst trampar inte i luften",
		math.abs(mcb.loco.phase - fasFore) < 1e-9,
		string.format("(fasen rörde sig %.2e på 3 s mot vägg)",
			math.abs(mcb.loco.phase - fasFore)))

	--[[ Och stillastående häst med noll begärd fart. ]]
	local mch = newMC()
	local fasH = mch.loco.phase
	runMoving(mch, 3.0, {})
	check("stillastående häst går inte på stället",
		math.abs(mch.loco.phase - fasH) < 1e-9)
end

print("")
if fails > 0 then
	print(string.format("%d mätning(ar) föll.", fails))
else
	print("Alla mätningar gick igenom.")
end
