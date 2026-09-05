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

--[[ HÄR STOD EN SAMMANFATTNING MITT I SPECEN, och den var ett hål.

     roblox/tests/kor.sh kräver tre saker för grönt: exitkod 0, inga
     FEL-rader, och att specen NÅDDE SIN SLUTRAD. Det tredje finns för att
     en krasch inte ska se ut som grönt. En "Alla mätningar gick igenom."
     halvvägs in gjorde det kravet uppfyllt oavsett vad som hände sedan —
     kraschade specen efter den här punkten var slutradskravet ändå
     uppfyllt, och bara exitkoden återstod som skydd.

     Borttagen i G02-A. Sammanfattningen skrivs en gång, sist. ]]

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
	local start = mcv.curvature
	local minsta = math.abs(start)
	for _ = 1, math.floor(3.0 / dt) do
		runMoving(mcv, dt, { forward = 1, steer = 1 }, dt)
		minsta = math.min(minsta, math.abs(mcv.curvature))
		local nu = rigYaw(mcv)
		storst = math.max(storst, math.abs(vinkelDiff(nu, forra)))
		forra = nu
	end
	--[[ Provet letade förut efter ett TECKENBYTE mellan två bildrutor
	     (innan * nu < 0). Det missar det starkaste utfallet av alla: att
	     hästen råkar landa EXAKT på noll en bildruta, vilket kurvaturens
	     dödband gör att den kan. Då är produkten noll, inte negativ, och
	     ett perfekt genomgående såg ut som ett hopp. Kravet är i stället
	     att svängen bytte håll OCH att den var nära noll på vägen. ]]
	--[[ Mätt på KURVATUREN och inte på vridhastigheten. Vridhastigheten
	     är kurvatur × fart, så samma båge ger olika tal i olika gångart
	     — en gräns i rad/s hade mätt farten lika mycket som bågen. ]]
	local passerade = start * mcv.curvature < 0 and minsta < 0.02
	check("vänster → höger passerar faktiskt genom neutralt", passerade,
		string.format("(κ %.4f → %.4f, minst %.5f 1/m på vägen)",
			start, mcv.curvature, minsta))
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

print("\n── Animationen följer marken, inte klockan (#44) ──")
do
	--[[ Fasen räknades distanslåst redan, och hovljuden låg på den. Men
	     BENEN spelades av Roblox egen klocka via `AdjustSpeed`, alltså av en
	     annan tid än ljudet. Mätningarna nedan är skrivna för att falla på
	     den gamla koden och hålla på den nya.

	     `AnimationController` har aldrig förr nåtts av en spec — riggstubben
	     lämnade `animator = nil`, så modulen gick inte ens att konstruera.
	     Därför kunde felet ligga kvar. ]]
	local function anim(length)
		local rig = __makeAnimRig(length)
		return AnimationController.new(rig, STATS), rig
	end

	local function loco(o)
		return { state = o.state or "Trot", gait = o.gait or "trot",
			speed = o.speed or 4.0, phase = o.phase or 0,
			turnRate = 0, grounded = true, airborne = false, heading = 0 }
	end

	--[[ 1. Läget ska vara fasen gånger klipplängden. Längden är med flit inte
	     1 i stubben, så ett glömt multiplicerande syns. ]]
	local ac, rig = anim(0.86)
	ac:step(loco({ phase = 0.25 }), 1 / 60)
	local tr = rig._tracks.Trot
	check("läget i klippet är fasen gånger klipplängden",
		tr ~= nil and math.abs(tr.TimePosition - 0.25 * 0.86) < 1e-9,
		tr and string.format("(TimePosition %.4f, väntade %.4f)",
			tr.TimePosition, 0.25 * 0.86) or "(spåret Trot laddades inte)")

	--[[ 2. Roblox egen framdrivning måste vara avstängd. Lämnas den på lägger
	     den till en halv bildruta i taget ovanpå vår spolning — samma glid vi
	     just tog bort, men långsammare och svårare att se. ]]
	check("klippets egen klocka är avstängd i gångart",
		tr ~= nil and tr.Speed == 0,
		tr and string.format("(Speed %.3f)", tr.Speed) or "")

	--[[ 3. LÄGET I KLIPPET SKA FÖLJA UPPMÄTT STRÄCKA, inte förfluten tid.

	     Provet räknar förväntat läge ur den sträcka hästen FAKTISKT kom och
	     ur `Gaits.cycleLength` — två vägar som inte är samma kod som den
	     provade raden. Gångarten hålls konstant hela mätningen, annars
	     blandas två cykellängder i samma summa.

	     Det körs vid 60 och 20 bilder/s med samma krav på båda. Målgruppen
	     sitter på skolutrustning: en klockdriven animation glider ifrån
	     marken just när bildrutan svajar, och då landar hovljudet på ett
	     ställe medan hoven syns på ett annat. ]]
	local function lagePerStracka(dt)
		local a, r = anim(0.86)
		local mc = MovementController.new(r, STATS)
		local function flytta()
			local hum = r.humanoid
			local dir = hum._moves[#hum._moves]
			if dir then
				local ny = r.root.Position + dir * (hum.WalkSpeed * dt)
				r.root.Position = ny
				r.root.CFrame = CFrame.new(ny) * CFrame.Angles(0, mc.loco.heading, 0)
				return (dir * (hum.WalkSpeed * dt)).Magnitude
			end
			return 0
		end
		-- Upp i trav och låt farten sätta sig, utan att mäta sträckan än.
		for i = 1, math.floor(6.0 / dt + 0.5) do
			mc:step(intent({ forward = 1, gaitUp = (i == 1 or i == math.floor(1.5 / dt)) }), dt)
			flytta()
			a:step(mc.loco, dt)
		end
		if mc.loco.state ~= "Trot" then return nil, mc.loco.state end
		-- Nu mäts: fas och sträcka från samma nollpunkt, konstant gångart.
		local fas0 = mc.loco.phase
		local strackaStuds = 0
		for _ = 1, math.floor(4.0 / dt + 0.5) do
			mc:step(intent({ forward = 1 }), dt)
			strackaStuds += flytta()
			a:step(mc.loco, dt)
			if mc.loco.state ~= "Trot" then return nil, mc.loco.state end
		end
		local meter = strackaStuds / Config.STUDS_PER_METRE
		local varv = meter / Gaits.cycleLength("trot")
		local vantat = ((fas0 + varv) % 1) * 0.86
		local faktiskt = r._tracks.Trot.TimePosition
		-- En bildrutas förflyttning, uttryckt i klipptid.
		local marginal = ((mc.rig.humanoid.WalkSpeed * dt) / Config.STUDS_PER_METRE)
			/ Gaits.cycleLength("trot") * 0.86 + 1e-6
		return math.abs(faktiskt - vantat), marginal, meter, mc.loco.state
	end
	for _, dt in { 1 / 60, 1 / 20 } do
		local avvikelse, marginal, meter, tillstand = lagePerStracka(dt)
		check(string.format("läget följer uppmätt sträcka vid %d bilder/s",
			math.floor(1 / dt + 0.5)),
			avvikelse ~= nil and avvikelse <= marginal,
			avvikelse and string.format("(avvikelse %.5f s, marginal %.5f s, %.1f m i %s)",
				avvikelse, marginal, meter, tostring(tillstand))
				or string.format("(gångarten bytte till %s under mätningen)",
					tostring(marginal)))
	end

	--[[ 4. Krock mot vägg. Fasen står still, alltså ska benen också göra det.
	     Förut fortsatte klippet av sig självt och hästen trampade i luften
	     med tysta hovar, eftersom ljudet låg på fasen och benen inte. ]]
	local ab, rb = anim(0.86)
	local l = loco({ phase = 0.4 })
	ab:step(l, 1 / 60)
	local fore = rb._tracks.Trot.TimePosition
	for _ = 1, 180 do ab:step(l, 1 / 60) end   -- fasen rörs inte: väggen
	check("blockerad häst trampar inte i luften med benen heller",
		math.abs(rb._tracks.Trot.TimePosition - fore) < 1e-9,
		string.format("(läget rörde sig %.2e på 3 s mot vägg)",
			math.abs(rb._tracks.Trot.TimePosition - fore)))

	--[[ 5. HÄNDELSEKLIPPEN ska INTE spolas av fasen. Ett stopp ska ta lika
	     lång tid varje gång, och en fas som slutar ticka när hästen står
	     still skulle frysa klippet i sin första bildruta. ]]
	local ah, rh = anim(0.86)
	ah:step(loco({ state = "Stopping", gait = "halt", speed = 0.5 }), 1 / 60)
	local stopp = rh._tracks.Stop
	check("händelseklipp spelas av sin egen klocka",
		stopp ~= nil and stopp.Speed ~= 0,
		stopp and string.format("(Speed %.3f)", stopp.Speed) or "(Stop laddades inte)")

	--[[ 6. Reservfallet. `Length` är 0 innan klippet hämtats från servern.
	     Då ska klockan användas — hellre något fel de första bildrutorna än
	     en häst fastfrusen i ruta ett. ]]
	local a0, r0 = anim(0)
	a0:step(loco({ phase = 0.3 }), 1 / 60)
	local t0 = r0._tracks.Trot
	check("oläst klipplängd faller tillbaka på klockan i stället för att frysa",
		t0 ~= nil and t0.Speed ~= 0 and t0.TimePosition == 0,
		t0 and string.format("(Speed %.3f, läge %.3f)", t0.Speed, t0.TimePosition) or "")
end

--[[ ── G02-A: TELEMETRIN UR EN RIKTIG CONTROLLER-FRAME ──────────────
     Senior review av #86, blocker B: paritetsspecen provade Telemetri.las()
     mot en HANDSKRIVEN `loco`-tabell, alltså mot något jag själv hittat på.
     Det bevisar att funktionen läser en tabell, inte att den läser hästen.

     Här körs en verklig MovementController i verkliga bildrutor — samma
     `runMoving` som resten av specen använder, med riktig förflyttning —
     och telemetrin läses ur DESS loco och DESS kurvatur, precis som
     klientens ridloop gör.

     Kontrollen är också att lagret är RENT: samma frames körda med och utan
     telemetriavläsning ska ge exakt samma rörelse. Kan avläsningen ändra
     hästen är den inte read-only, och då hör den inte hemma i ridloopen. ]]
do
	print("")
	print("── G02-A: telemetri ur en riktig MovementController-frame ───")

	local ritt = Telemetri.sittUpp(Telemetri.nyRitt(), "bandit", "ridhus")

	local mc = newMC()
	runMoving(mc, 6, { forward = 1, steer = 0.6 })
	local loco = mc.loco
	Telemetri.foljGangart(ritt, loco.gait)
	local tm = Telemetri.las(ritt, loco, mc.curvature)

	check("controllern rörde sig på riktigt innan telemetrin lästes",
		loco.speed > 0.5 and math.abs(mc.curvature) > 1e-4,
		string.format("(fart %.2f m/s, gångart %s, κ %.4f 1/m)", loco.speed, loco.gait, mc.curvature))

	local kravda = { "uppsutten", "hast", "gangart", "gangartGlapp", "fart",
		"onskadFart", "kurvatur", "svangradie", "vridhastighet", "rytm", "steglangd" }
	local saknas = {}
	for _, k in kravda do if tm[k] == nil then table.insert(saknas, k) end end
	check("telemetrin fylls ur controllerns eget tillstånd",
		#saknas == 0 and tm.uppsutten == true and tm.hast == "bandit",
		if #saknas > 0 then "saknas: " .. table.concat(saknas, ", ")
		else string.format("gångart %s, fart %.2f, radie %.1f m, rytm %.2f",
			tm.gangart, tm.fart, tm.svangradie, tm.rytm))

	check("vridhastighet = kurvatur × tempo, mätt på controllern",
		math.abs(tm.vridhastighet - tm.kurvatur * tm.fart) < 1e-6,
		string.format("(%.4f rad/s = %.4f × %.2f)", tm.vridhastighet, tm.kurvatur, tm.fart))

	--[[ REN AVLÄSNING: två identiska körningar, en med telemetri varje
	     bildruta och en utan. Skiljer de sig har lagret rört rörelsen. ]]
	local a, b = newMC(), newMC()
	local r2 = Telemetri.sittUpp(Telemetri.nyRitt(), "bandit", "ridhus")
	local dt = 1 / 60
	for _ = 1, 360 do
		a:step(intent({ forward = 1, steer = 0.6 }), dt)
		b:step(intent({ forward = 1, steer = 0.6 }), dt)
		Telemetri.foljGangart(r2, b.loco.gait)
		Telemetri.las(r2, b.loco, b.curvature)
	end
	local dFart = math.abs(a.loco.speed - b.loco.speed)
	local dKurv = math.abs(a.curvature - b.curvature)
	local dKurs = math.abs(a.loco.heading - b.loco.heading)
	check("avläsningen ändrar inte rörelsen (fart, kurvatur, kurs identiska)",
		dFart < 1e-12 and dKurv < 1e-12 and dKurs < 1e-12,
		string.format("(Δfart %.2e, Δκ %.2e, Δkurs %.2e)", dFart, dKurv, dKurs))

	--[[ Uppsittningen är ett tillstånd även här: släpps ritten ska
	     telemetrin sluta påstå att någon sitter upp. ]]
	Telemetri.sittAv(ritt)
	local efter = Telemetri.las(ritt, loco, mc.curvature)
	check("avsittning syns i telemetrin ur samma controller",
		efter.uppsutten == false and efter.hast == nil,
		string.format("uppsutten %s", tostring(efter.uppsutten)))
end

--[[ PARADEN — G02-A.1 P5, paritet med webben.

     Webben mätte fram att hjälpens styrka inte påverkade halten alls:
     varje parad var en nödbromsning. Roblox hade redan skillnaden, men
     ingen mätte den. Mekanismen skiljer sig — Roblox lägger på
     M.BrakeExtra när S hålls, webben läser tygelns och sitsens styrka —
     men BETEENDET ska vara detsamma: ber du bestämdare stannar hon
     fortare. Det är den sortens paritet som gäller när ytorna har olika
     inputmodell. ]]
do
	print("\n── Paraden: ber man bestämdare stannar hon fortare ──")
	local dt = 1 / 240
	local function stoppa(bakat)
		local mc = newMC()
		upToGait(mc, 3)                       -- upp i galopp
		run(mc, 2.0, { forward = 1 }, 1 / 60) -- låt tempot sätta sig
		local fran = mc.loco.speed
		local t, ret, forra = 0, 0, mc.loco.speed
		for _ = 1, math.floor(12 / dt) do
			mc:step(intent({ forward = if bakat then -1 else 0, gaitDown = (t < dt) }), dt)
			ret = math.max(ret, (forra - mc.loco.speed) / dt)
			forra = mc.loco.speed
			t += dt
			if mc.loco.speed < 0.02 then break end
		end
		return fran, t, ret
	end
	--[[ Nedstegning utan S mot nedstegning MED S. Samma häst, samma
	     startläge, samma gångartsbegäran — bara bromshjälpen skiljer. ]]
	local f1, t1, r1 = stoppa(false)
	local f2, t2, r2 = stoppa(true)
	check("bestämd broms bromsar hårdare än enbart nedstegning", r2 > r1 * 1.10,
		string.format("topp %.2f mot %.2f m/s² (från %.2f respektive %.2f m/s)",
			r2, r1, f2, f1))
end

--[[ BÅGEN ÄNDRAS ALDRIG FORTARE VID ETT BYTE ÄN VID EN INSVÄNGNING.

     G02-A.1 P4, samma självrefererande krav som webbens ridtest.
     Kurvaturens ändringstakt vid ett riktningsbyte jämförs med samma
     takt vid den hårdaste insvängningen från rakt. Bytet får inte vara
     snabbare: det är fysiskt samma rörelse, att lägga en båge i
     kroppen, och ett byte som går fortare är ett ryck.

     Utan taket i MovementController mäter webben 1,43 gånger snabbare.
     Marginalen 1,15 är taket självt — CurvatureRateTime är satt med
     luft så att en vanlig insvängning aldrig bromsas. ]]
do
	print("\n── Bågen ändras aldrig fortare vid ett byte än vid en insvängning ──")
	local dt = 1 / 60
	local function takt(spar)
		local m = 0
		for i = 2, #spar do m = math.max(m, math.abs(spar[i] - spar[i - 1]) / dt) end
		return m
	end
	--[[ Insvängning från rakt. ]]
	local a = newMC(); upToGait(a, 2); run(a, 2.0, { forward = 1 }, dt)
	local sIn = {}
	for _ = 1, math.floor(3.0 / dt) do
		a:step(intent({ forward = 1, steer = 1 }), dt)
		table.insert(sIn, a.curvature)
	end
	--[[ Riktningsbyte från etablerad full vänster. ]]
	local b = newMC(); upToGait(b, 2); run(b, 3.0, { forward = 1, steer = -1 }, dt)
	local sByte = {}
	for _ = 1, math.floor(3.0 / dt) do
		b:step(intent({ forward = 1, steer = 1 }), dt)
		table.insert(sByte, b.curvature)
	end
	local tIn, tByte = takt(sIn), takt(sByte)
	check("bytets takt överstiger inte insvängningens", tByte <= tIn * 1.15,
		string.format("byte %.3f mot insvängning %.3f 1/(m·s) = %.2f×",
			tByte, tIn, tByte / tIn))
end

--[[ GÅNGARTENS TRÖGHET I SVÄNGEN — G02-A.1 P3, mätt.

     Talet svangTau kom in i Gaits.luau i P3, men BARA som data: det
     lästes inte av någon och Roblox svängde likadant i alla gångarter
     medan tabellen påstod motsatsen. Webben hade det inkopplat, Roblox
     inte, och paritetsspecen jämförde tabeller — inte beteende. Nu läser
     MovementController det, och det här provet mäter att den gör det.

     Mätt som tiden till 90 % av sin egen slutkurvatur vid fullt utslag.
     Taken skiljer sig mellan gångarterna (galoppen svänger vidare), så
     jämförelsen görs mot varje gångarts EGET slutvärde — annars mäter
     man turn och inte svangTau. ]]
do
	print("\n── Galoppen lägger sig i bågen trögare än skritten ──")
	local dt = 1 / 240                              -- fin upplösning: tiden mäts
	local function tid90(steg)
		local mc = newMC()
		upToGait(mc, steg, 1 / 60)
		--[[ Rakt fram tills kurvaturen dött ut, så mätningen börjar från noll. ]]
		run(mc, 2.0, { forward = 1 }, 1 / 60)
		local slut = 0
		local mc2 = newMC()
		upToGait(mc2, steg, 1 / 60); run(mc2, 2.0, { forward = 1 }, 1 / 60)
		for _ = 1, math.floor(4.0 / dt) do mc2:step(intent({ forward = 1, steer = 1 }), dt) end
		slut = math.abs(mc2.curvature)
		local t = 0
		for _ = 1, math.floor(4.0 / dt) do
			mc:step(intent({ forward = 1, steer = 1 }), dt)
			t += dt
			if math.abs(mc.curvature) >= 0.90 * slut then break end
		end
		return t, slut, mc.loco.gait
	end
	local tW, kW, gW = tid90(1)
	local tC, kC, gC = tid90(3)
	check("galopp tar längre tid till 90 % av sin båge än skritt",
		tC > tW * 1.15,
		string.format("%s %.3f s (κ %.3f) mot %s %.3f s (κ %.3f)", gC, tC, kC, gW, tW, kW))
end

--[[ HÅLLEN TANGENT GER ETT STEG — paritet med webbens G02-A.1 P4.

     Webben mätte fram att en HÅLLEN framåthjälp inte kunde ge något
     gångartsbyte alls, och rättade det genom att läsa hjälpens resa över
     ett fönster i stället för per bildruta. Roblox har inte det felet,
     men det är värt att visa VARFÖR: här är gaitUp redan en flank,
     satt i Input.luau när tangenten går ned och nollställd i consume().

     Regeln är alltså densamma på båda ytorna — ett tryck är en begäran,
     att fortsätta hålla är ingen ny begäran — men den bor på olika
     ställen. Roblox löser den i inputlagret därför att tangenten är
     diskret; webben måste lösa den i modellen därför att hjälpen är
     analog och utjämnad och först DÄR har en historia att jämföras med.

     Faller det här provet klättrar hästen en gångart per bildruta så
     länge Shift hålls nere, alltså från halt till fyrsprång på under en
     tiondels sekund. ]]
do
	print("\n── Hållen tangent är EN begäran, inte en per bildruta ──")
	Input.unbind(); __setStick(nil); Input.bind()
	local mc = newMC()
	local dt = 1 / 60
	--[[ Upp i skritt först, så att steget som mäts inte är W:s egen
	     "ur halt startar skritt". ]]
	for i = 1, 180 do mc:step(intent({ forward = 1 }), dt) end
	local fore = mc.loco.targetGait
	__key(Enum.KeyCode.LeftShift, true)             -- Shift NED och kvar där
	for i = 1, 300 do
		local avsikt = Input.consume()
		avsikt.forward = 1
		mc:step(avsikt, dt)
	end
	local efter = mc.loco.targetGait
	__key(Enum.KeyCode.LeftShift, false)
	local steg = Gaits.index(efter) - Gaits.index(fore)
	check("hållen Shift i fem sekunder ger ETT steg upp", steg == 1,
		string.format("%s → %s (%d steg)", fore, efter, steg))
	Input.unbind()
end

--[[ DEN VERTIKALA SLICEN — G02-A.1 P7, Roblox logik-/speclager.

     Samma obrutna pass som webbens ridtest kör i sin runtime:

       sitt upp → halt → skritt → HÅLL skritt → trav → volt → galopp
       → sväng → trav → skritt → halt → sitt av

     Delarna provas var för sig ovanför. Det nya är att de körs efter
     varandra på SAMMA controller — tillstånd som bara stämmer när
     provet börjar om syns bara här.

     Arbetsordern räknar upp vad telemetrin ska visa: cue, begärd
     gångart, verklig gångart, tempo, kurvatur, övergångstillstånd och
     inga olagliga hopp. Allt läses ur samma controller, inte ur en
     konstruerad Locomotion. ]]
do
	print("\n── Den vertikala slicen ──")
	local dt = 1 / 60
	local mc = newMC()
	local ritt = Telemetri.sittUpp(Telemetri.nyRitt(), "bandit", "ridhus")
	local uppe = ritt.uppsutten

	local sedda = { mc.loco.gait }
	local moment = {}
	local function kor(o, sek)
		for i = 1, math.floor(sek / dt) do
			local avsikt = intent(o)
			--[[ gaitUp/gaitDown är flanker: bara första bildrutan. ]]
			if i > 1 then avsikt.gaitUp, avsikt.gaitDown = false, false end
			mc:step(avsikt, dt)
			local hum = mc.rig.humanoid
			local dir = hum._moves[#hum._moves]
			if dir then
				local ny = mc.rig.root.Position + dir * (hum.WalkSpeed * dt)
				mc.rig.root.Position = ny
				mc.rig.root.CFrame = CFrame.new(ny) * CFrame.Angles(0, mc.loco.heading, 0)
			end
			if sedda[#sedda] ~= mc.loco.gait then table.insert(sedda, mc.loco.gait) end
		end
	end
	local function notera(vad)
		local t = Telemetri.las(ritt, mc.loco, mc.curvature)
		table.insert(moment, { vad = vad, gangart = mc.loco.gait, bad = mc.loco.targetGait,
			cue = mc.loco.cue, fart = t.fart, kurvatur = t.kurvatur,
			overgang = mc.loco.senasteOvergang })
	end

	kor({}, 2.0)                                    notera("halt")
	kor({ forward = 1 }, 3.0)                       notera("skritt")
	kor({ forward = 1 }, 6.0)                       notera("håll skritt")
	kor({ forward = 1, gaitUp = true }, 3.0)        notera("trav")
	kor({ forward = 1, steer = 1 }, 4.0)            notera("volt")
	kor({ forward = 1 }, 2.0)
	kor({ forward = 1, gaitUp = true }, 3.0)        notera("galopp")
	kor({ forward = 1, steer = 0.6 }, 3.0)          notera("sväng")
	kor({ forward = 1 }, 2.0)
	--[[ NED med gaitDown och forward 0. `forward = -1` betyder BACKA på
	     Roblox — den tar targetGait hela vägen till halt och rullar sedan
	     bakåt, vilket är en annan manöver än en parad. Första versionen
	     av slicen gjorde det och mätte en häst som gick baklänges i
	     1,10 m/s medan den påstod sig parera. ]]
	kor({ gaitDown = true }, 4.0)                   notera("trav igen")
	kor({ gaitDown = true }, 4.0)                   notera("skritt igen")
	kor({ gaitDown = true }, 6.0)                   notera("halt igen")
	Telemetri.sittAv(ritt)

	for _, m in moment do
		print(string.format("  %-12s %-7s bad %-7s cue %-7s %.2f m/s  κ %.4f  %.2f s",
			m.vad, m.gangart, tostring(m.bad), tostring(m.cue),
			m.fart or -1, m.kurvatur or 0, m.overgang or 0))
	end
	print("  sedda: " .. table.concat(sedda, " → "))

	--[[ Inga olagliga hopp: varje byte i sekvensen ska vara ETT steg. ]]
	local olagliga = 0
	for i = 2, #sedda do
		if math.abs(Gaits.index(sedda[i]) - Gaits.index(sedda[i - 1])) ~= 1 then
			olagliga += 1
		end
	end
	local g = {}
	for _, m in moment do table.insert(g, m.gangart) end
	local vantad = { "halt", "walk", "walk", "trot", "trot", "canter", "canter", "trot", "walk", "halt" }
	local rattKedja = #g == #vantad
	if rattKedja then
		for i, v in vantad do if g[i] ~= v then rattKedja = false end end
	end
	check("slicen: hela passet på samma controller, utan olagliga hopp",
		uppe == true and ritt.uppsutten == false and rattKedja and olagliga == 0,
		string.format("uppsutten %s → %s, moment %s, %d olagliga",
			tostring(uppe), tostring(ritt.uppsutten), table.concat(g, " → "), olagliga))
	--[[ Hållet: sex sekunder med samma avsikt ska inte flytta henne. ]]
	check("slicen: hästen BÄR skritten genom hela hållet",
		moment[2].gangart == "walk" and moment[3].gangart == "walk",
		string.format("efter W %s %.2f m/s, sex sekunder senare %s %.2f m/s",
			moment[2].gangart, moment[2].fart or -1, moment[3].gangart, moment[3].fart or -1))
	--[[ Telemetrin ska bära hela vägen. ]]
	local telOk = true
	for _, m in moment do if m.fart == nil or m.kurvatur == nil then telOk = false end end
	check("slicen: telemetrin följer med genom hela passet", telOk,
		string.format("(%d moment)", #moment))
end

print("")
if fails > 0 then
	print(string.format("%d mätning(ar) föll.", fails))
else
	print("Alla mätningar gick igenom.")
end
