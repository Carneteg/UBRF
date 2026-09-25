--!nostrict
--[[
	GÅNGARTERNA SYNS OCH HÖRS OLIKA (#264 GAIT_READABILITY_AND_UGNETA).

	Ordern: skritt, diagonal trav och vänster/höger galopp med samma
	kontakttider i ben, ljud och ryttare. Falsifieringen ska kunna fånga
	fyrtakt i trav, fel galoppsida, dubbel lättridning per cykel, en
	fristående ljudklocka och en fas som beror på bildfrekvensen.

	Det som mäts går genom produktionskoden: `Gangfas` (uppslaget i
	RidKanon.GANGFAS), `SoundController:step` (bara uppspelningen `_hoof` är
	utbytt — bänken har ingen ljudmotor) och `RiderController:step` (sätets
	svets är en stubbe med `C0`).

	BÄNKGRÄNS: hur det SER ut — om hovarna glider, om ryttaren ser naturlig
	ut — är visuell granskning i Studio och står som NOT_TESTED här.

	Kör: python3 roblox/tests/build.py tests/gangfas.spec.luau
	     && luau roblox/tests/.build/gangfas.spec.luau
]]

local fel = 0
local function check(vad, ok, detalj)
	if ok then
		print(("  OK   %s%s"):format(vad, if detalj then "  " .. detalj else ""))
	else
		fel += 1
		print(("  FEL  %s%s"):format(vad, if detalj then "  " .. detalj else ""))
	end
end

local Gangfas = __Core.Gangfas
local RidKanon = __Core.RidKanon

local function iStod(m, ben, fas) return Gangfas.iStod(m, ben, fas) end

print("\n── 1. Benföljden per gångart ──")
do
	local skritt = Gangfas.monster("skritt")
	local s = Gangfas.slag(skritt)
	local ordning = {}
	for _, x in ipairs(s) do table.insert(ordning, table.concat(x.ben, "+")) end
	check("SKRITT: fyra separata isättningar, LH LF RH RF",
		#s == 4 and table.concat(ordning, " ") == "LH LF RH RF",
		table.concat(ordning, " "))
	--[[ Skritt har inget svävmoment: minst två ben bär hela cykeln. ]]
	local minst = 4
	for i = 0, 199 do
		local f, n = i / 200, 0
		for _, b in ipairs(Gangfas.BEN) do if iStod(skritt, b, f) then n += 1 end end
		minst = math.min(minst, n)
	end
	check("och skritten har inget svävmoment (minst två ben bär)", minst >= 2,
		("minst %d ben"):format(minst))

	local trav = Gangfas.monster("trav")
	local t = Gangfas.slag(trav)
	local par = {}
	for _, x in ipairs(t) do table.sort(x.ben); table.insert(par, table.concat(x.ben, "+")) end
	check("TRAV: två slag, diagonala par LH+RF och LF+RH",
		#t == 2 and par[1] == "LH+RF" and par[2] == "LF+RH", table.concat(par, " | "))
	--[[ Svävmomentet: någonstans i cykeln bär INGET ben. ]]
	local svav = false
	for i = 0, 399 do
		local f, n = i / 400, 0
		for _, b in ipairs(Gangfas.BEN) do if iStod(trav, b, f) then n += 1 end end
		if n == 0 then svav = true end
	end
	check("och traven har ett svävmoment mellan paren", svav)
	--[[ Diagonalt, inte lateralt: vänster fram och vänster bak bär aldrig
	     samtidigt i ett rent par. ]]
	check("och paren är diagonala — LH och RF bär samtidigt, LH och LF inte",
		iStod(trav, "LH", 0.1) and iStod(trav, "RF", 0.1)
			and not iStod(trav, "LF", 0.1))

	local hog = Gangfas.monster("galopp_hoger")
	local g = Gangfas.slag(hog)
	local gs = {}
	for _, x in ipairs(g) do table.sort(x.ben); table.insert(gs, table.concat(x.ben, "+")) end
	check("HÖGER GALOPP: tre slag, LH · LF+RH · RF",
		#g == 3 and gs[1] == "LH" and gs[2] == "LF+RH" and gs[3] == "RF",
		table.concat(gs, " · "))
	--[[ Tre slag och en paus: avståndet efter sista slaget är längre än
	     mellan slagen. ]]
	local luckor = { g[2].fas - g[1].fas, g[3].fas - g[2].fas, 1 + g[1].fas - g[3].fas }
	check("och galoppen är tre slag och en PAUS, inte tre lika",
		luckor[3] > luckor[1] and luckor[3] > luckor[2],
		("%.2f %.2f %.2f"):format(luckor[1], luckor[2], luckor[3]))
	local vanster = Gangfas.monster("galopp_vanster")
	local v = Gangfas.slag(vanster)
	local vs = {}
	for _, x in ipairs(v) do table.sort(x.ben); table.insert(vs, table.concat(x.ben, "+")) end
	check("VÄNSTER GALOPP är höger speglad: RH · LH+RF · LF",
		#v == 3 and vs[1] == "RH" and vs[2] == "LH+RF" and vs[3] == "LF",
		table.concat(vs, " · "))
	check("och sidan väljs av `lead`, ryggning av sin egen rad",
		Gangfas.monsterNamn("canter", "left") == "galopp_vanster"
			and Gangfas.monsterNamn("canter", "right") == "galopp_hoger"
			and Gangfas.monsterNamn("walk", nil, true) == "rygga"
			and Gangfas.monsterNamn("halt") == nil)
end

print("\n── 2. Lättridningen: EN uppresning per travcykel ──")
do
	local trav = Gangfas.monster("trav")
	--[[ CIRKULÄRT räknat: cykeln är en ring, och ett uppresningsfönster
	     som går över fasens nollpunkt är EN uppresning, inte två. ]]
	--[[ TOPPAR, inte nollgenomgångar: två uppresningar tätt efter varandra
	     behöver inte nå noll emellan, och ett prov som räknade kanter mot
	     noll såg dem som en (fångat i falsifieringen). ]]
	local function toppar(h)
		local n, N = 0, #h
		for i = 1, N do
			local a, b, c = h[((i - 2) % N) + 1], h[i], h[(i % N) + 1]
			if b > 0.05 and b > a and b >= c then n += 1 end
		end
		return n
	end
	local function uppresningar(yttre)
		local h = {}
		for i = 0, 999 do h[i + 1] = Gangfas.lattridning(trav, i / 1000, yttre) end
		return toppar(h)
	end
	check("en uppresning per cykel med vänster fram yttre", uppresningar("LF") == 1,
		tostring(uppresningar("LF")))
	check("och med höger fram yttre", uppresningar("RF") == 1, tostring(uppresningar("RF")))
	--[[ Diagonalbytet flyttar uppresningen ett halvt varv — det ändrar inte
	     hästens gångart. ]]
	local function topp(yttre)
		local bast, fas = -1, 0
		for i = 0, 999 do
			local h = Gangfas.lattridning(trav, i / 1000, yttre)
			if h > bast then bast, fas = h, i / 1000 end
		end
		return fas
	end
	local skift = (topp("RF") - topp("LF")) % 1
	check("diagonalbytet flyttar uppresningen ett halvt varv",
		math.abs(skift - 0.5) < 0.01, ("%.3f"):format(skift))
	--[[ Hon reser sig medan det YTTRE frambenet förs fram, inte medan det bär. ]]
	local fel_bar = false
	for i = 0, 999 do
		local f = i / 1000
		if Gangfas.lattridning(trav, f, "LF") > 0 and iStod(trav, "LF", f) then fel_bar = true end
	end
	check("och hon står bara upp medan det yttre frambenet svänger fram", not fel_bar)
	check("varvet ur banan: mitten till höger ger höger varv och vänster fram yttre",
		Gangfas.varv(Vector3.new(0, 0, 0), Vector3.new(0, 0, -1), Vector3.new(10, 0, 0)) == "right"
			and Gangfas.yttreFram("right") == "LF" and Gangfas.yttreFram("left") == "RF")
end

print("\n── 3. Fasen beror på sträckan, inte på bildfrekvensen ──")
do
	local galopp = Gangfas.monster("galopp_hoger")
	--[[ Samma sträcka (tre hela cykler) i 30, 60 och 120 bildrutor/s. ]]
	local function slagVid(hz)
		--[[ Startar strax efter ett slag: ett slag EXAKT på start- eller
		     slutgränsen avgörs annars av flyttalsavrundningen i summan,
		     inte av koden. ]]
		local n, lopande = 0, 0.013
		local steg = 3 / (hz * 2)   -- tre cykler på två sekunder
		for _ = 1, hz * 2 do
			n += #Gangfas.passerade(galopp, lopande, lopande + steg)
			lopande += steg
		end
		return n
	end
	check("samma sträcka ger samma slag vid 30/60/120 bildrutor/s",
		slagVid(30) == 9 and slagVid(60) == 9 and slagVid(120) == 9,
		("%d %d %d"):format(slagVid(30), slagVid(60), slagVid(120)))
	--[[ En lång bildruta: flera slag räknas i ordning, faswrap tappar inget. ]]
	local p = Gangfas.passerade(galopp, 0.9, 2.3)
	local ok = #p >= 4 and p[1].lage < p[2].lage
	check("en lång bildruta över en faswrap tappar inga slag", ok, ("%d slag"):format(#p))
	check("och ett stort hopp ger högst MAX_SLAG, ingen salva",
		#Gangfas.passerade(galopp, 0, 50) == Gangfas.MAX_SLAG)
end

print("\n── 4. Hovslagen följer benen — ingen egen klocka ──")
do
	local STATS = { Speed = 0.5, Acceleration = 0.5, Agility = 0.5, Endurance = 0.5,
		Temperament = "Calm", MaxStamina = 100 }
	local rig = __makeRig()
	rig.model.FindFirstChild = function() return nil end
	local sc = SoundController.new(rig, STATS)
	local slagFaser = {}
	local nuFas = 0
	sc._hoof = function() table.insert(slagFaser, nuFas) end
	local function loco(gait, fas, lead)
		return { gait = gait, lead = lead, phase = fas, ryggar = false,
			grounded = true, airborne = false, speed = 5 }
	end
	--[[ Två hela galoppcykler, 60 steg per cykel. ]]
	local fas = 0.013   -- strax efter ett slag, se noten i avsnitt 3
	sc:step(loco("canter", fas), 1 / 60)
	for _ = 1, 120 do
		fas = (fas + 1 / 60) % 1
		nuFas = fas
		sc:step(loco("canter", fas), 1 / 60)
	end
	check("GALOPP: tre hovslag per cykel", #slagFaser == 6, ("%d slag på två cykler"):format(#slagFaser))
	--[[ Slagen ska ligga på benens isättningar: 0, 0,25 och 0,5. ]]
	local nara = 0
	for _, f in ipairs(slagFaser) do
		for _, s in ipairs(Gangfas.slag(Gangfas.monster("galopp_hoger"))) do
			if math.abs(((f - s.fas + 0.5) % 1) - 0.5) < 1 / 60 + 1e-6 then nara += 1 break end
		end
	end
	check("och varje slag ligger på en isättning i benföljden", nara == #slagFaser,
		("%d av %d"):format(nara, #slagFaser))

	table.clear(slagFaser)
	sc:step(loco("trot", fas), 1 / 60)   -- ny rad: seed, inget slag
	local seedSlag = #slagFaser
	for _ = 1, 60 do
		fas = (fas + 1 / 60) % 1
		nuFas = fas
		sc:step(loco("trot", fas), 1 / 60)
	end
	check("TRAV: två slag per cykel — ett diagonalpar är ETT slag",
		#slagFaser == 2, ("%d slag"):format(#slagFaser))
	check("och radbytet galopp → trav gav inget extra slag", seedSlag == 0)

	table.clear(slagFaser)
	sc:step(loco("walk", fas), 1 / 60)
	for _ = 1, 60 do
		fas = (fas + 1 / 60) % 1
		sc:step(loco("walk", fas), 1 / 60)
	end
	check("SKRITT: fyra slag per cykel", #slagFaser == 4, ("%d slag"):format(#slagFaser))

	table.clear(slagFaser)
	local l = loco("canter", fas)
	l.airborne = true
	for _ = 1, 30 do
		fas = (fas + 1 / 60) % 1
		l.phase = fas
		sc:step(l, 1 / 60)
	end
	check("inga markslag i luften", #slagFaser == 0, ("%d slag"):format(#slagFaser))
end

print("\n── 4b. Rörelse → ljud: en bildruta över en hel cykel tappar inga slag (R1) ──")
do
	--[[ GAIT_UGNETA_REVIEW_R1 fynd 4, genom PRODUKTIONENS väg: en riktig
	     MovementController räknar fasen ur rotens förflyttning, och en
	     riktig SoundController läser `loco`. Bara uppspelningen är utbytt. ]]
	local STATS = { Speed = 0.5, Acceleration = 0.5, Agility = 0.5, Endurance = 0.5,
		Temperament = "Calm", MaxStamina = 100 }
	local rig = __makeRig()
	rig.model.FindFirstChild = function() return nil end
	local mc = MovementController.new(rig, STATS)
	local sc = SoundController.new(rig, STATS)
	local slag = 0
	sc._hoof = function() slag += 1 end
	local function intent(o)
		o = o or {}
		return { forward = 0, steer = 0, rein = 0, seat = 0, parad = 0,
			gaitUp = o.gaitUp or false, gaitDown = false, jump = false }
	end
	local function flytta(studs)
		local ny = rig.root.Position + Vector3.new(0, 0, studs)
		rig.root.Position = ny
		rig.root.CFrame = CFrame.new(ny)
	end
	local function ruta(studs, o)
		mc:step(intent(o), 1 / 60)
		flytta(studs)
		sc:step(mc.loco, 1 / 60)
	end
	--[[ Upp i trav: två tryck, med tid emellan för övergången. ]]
	for _ = 1, 2 do
		ruta(0, { gaitUp = true })
		for _ = 1, 150 do ruta(0.05) end
	end
	check("utgångsläget: hon travar", mc.loco.gait == "trot", tostring(mc.loco.gait))
	for _ = 1, 10 do ruta(0.05) end
	local cykel = Gaits.cycleLength("trot") * Config.STUDS_PER_METRE
	--[[ EN lång bildruta: 1,1 cykel (2,4 m, under teleportgränsen 3 m). ]]
	slag = 0
	mc:step(intent(), 1 / 60)
	sc:step(mc.loco, 1 / 60)
	slag = 0
	local fore = mc.loco.fasLopande
	flytta(cykel * 1.1)
	mc:step(intent(), 1 / 60)
	sc:step(mc.loco, 1 / 60)
	--[[ Facit: hur många isättningar spannet faktiskt rymmer — 1,1 cykel
	     trav är två eller tre beroende på var den börjar. ]]
	local vantat = #Gangfas.passerade(Gangfas.monster("trav"), fore, mc.loco.fasLopande)
	check("en bildruta över en hel travcykel ger sina slag, inte noll",
		vantat >= 2 and slag == vantat, ("%d slag, facit %d"):format(slag, vantat))
	--[[ Stillastående: inga slag. ]]
	slag = 0
	for _ = 1, 30 do ruta(0) end
	check("stillastående: inga slag", slag == 0, ("%d slag"):format(slag))
	--[[ Teleport: seedas om, ingen salva. ]]
	slag = 0
	mc:step(intent(), 1 / 60)
	flytta(60)
	mc:step(intent(), 1 / 60)
	sc:step(mc.loco, 1 / 60)
	check("en teleport ger ingen salva", slag == 0, ("%d slag"):format(slag))
	--[[ Ljudets EGEN spärr: ett läge som hoppar tio cykler eller går bakåt
	     (återställning) seedas om — ingen eftersläpning spelas upp. ]]
	slag = 0
	local l = table.clone(mc.loco)
	l.fasLopande = (mc.loco.fasLopande or 0) + 10.3
	l.phase = l.fasLopande % 1
	sc:step(l, 1 / 60)
	local l2 = table.clone(l)
	l2.fasLopande = 0.05
	l2.phase = 0.05
	sc:step(l2, 1 / 60)
	check("ett läge som hoppar tio cykler, eller bakåt, ger ingen salva",
		slag == 0, ("%d slag"):format(slag))
	sc:step(mc.loco, 1 / 60)
	--[[ Vanlig faswrap i jämn trav: två slag per cykel. ]]
	slag = 0
	local per = cykel / 60
	for _ = 1, 120 do ruta(per) end
	check("jämn trav, två cykler: fyra slag", slag == 4, ("%d slag"):format(slag))
end

print("\n── 5. Ryttaren: lättridning i trav, sittande i skritt och galopp ──")
do
	local rig = __makeRig()
	local bas = CFrame.new(Vector3.new(0, 1, 0))
	local svets = { Name = "SeatWeld", C0 = bas, Parent = true,
		IsA = function(_, k) return k == "Weld" end }
	rig.seat = { FindFirstChild = function(_, n) if n == "SeatWeld" then return svets end return nil end }
	local rc = RiderController.new(rig)
	local function lyft() return (svets.C0.Position.Y or 0) - 1 end
	local function rid(gait, cykler, varv)
		local hojder = {}
		local fas = 0
		for _ = 1, math.floor(60 * cykler) do
			fas = (fas + 1 / 60) % 1
			rc:step({ gait = gait, phase = fas, ryggar = false, grounded = true,
				airborne = false, speed = 3, lean = 0, varv = varv }, 1 / 60)
			table.insert(hojder, lyft())
		end
		return hojder
	end
	rid("trot", 2, "right")          -- in i lättridningen
	local h = rid("trot", 3, "right")
	--[[ Toppar, cirkulärt: tre hela cykler börjar och slutar på samma fas. ]]
	local n, N = 0, #h
	for i = 1, N do
		local a, b, c = h[((i - 2) % N) + 1], h[i], h[(i % N) + 1]
		if b > 0.02 and b > a and b >= c then n += 1 end
	end
	check("TRAV: exakt en uppresning per cykel (tre cykler, tre uppresningar)",
		n == 3, ("%d uppresningar"):format(n))
	local sits = rc:sitsLage()
	check("och sitsen redovisas som lättridning", sits == "rising", tostring(sits))
	rid("walk", 1, "right")   -- utgången ur traven klingar av först (R1)
	local w = rid("walk", 3, "right")
	local maxW = 0
	for _, y in ipairs(w) do maxW = math.max(maxW, y) end
	check("SKRITT: ingen uppresning", maxW < 0.01, ("max %.3f"):format(maxW))
	--[[ R1 fynd 3: UT UR lättridningen klingar det faktiska lyftet av. ]]
	local function tillTopp()
		rid("trot", 2, "right")
		local bast, fasTopp = -1, 0
		for i = 0, 99 do
			local h = Gangfas.lattridning(Gangfas.monster("trav"), i / 100, "LF")
			if h > bast then bast, fasTopp = h, i / 100 end
		end
		for _ = 1, 30 do
			rc:step({ gait = "trot", phase = fasTopp, ryggar = false, grounded = true,
				airborne = false, speed = 3, lean = 0, varv = "right" }, 1 / 60)
		end
		return lyft()
	end
	for _, till in ipairs({ "walk", "canter", "halt" }) do
		local topp = tillTopp()
		rc:step({ gait = till, phase = 0.3, ryggar = false, grounded = true,
			airborne = false, speed = 2, lean = 0, varv = "right" }, 1 / 60)
		local efter = lyft()
		check(("trav → %s vid toppen: inget fall i sadeln på en bildruta"):format(till),
			topp > 0.25 and efter > topp * 0.85,
			("%.3f → %.3f"):format(topp, efter))
		for _ = 1, 120 do
			rc:step({ gait = till, phase = 0.3, ryggar = false, grounded = true,
				airborne = false, speed = 2, lean = 0, varv = "right" }, 1 / 60)
		end
		check(("och efter två sekunder i %s sitter hon"):format(till), math.abs(lyft()) < 0.01,
			("%.4f"):format(lyft()))
	end
	rc:release()
	check("och avsittningen lämnar sätets svets i utgångsläget",
		math.abs(svets.C0.Position.Y - 1) < 1e-6)
end

print("\n── 6. De synliga benen följer samma rad (HastGang) ──")
do
	--[[ En häst med fyra benkedjor. Riggprofilens svar byts mot kedjor av
	     leder med `Transform` — det som mäts är vilka ben HastGang lyfter
	     vid en given fas, inte hur K3:s leder heter. ]]
	local function led() return { Transform = CFrame.new() } end
	local function kedja() return { led(), led(), led() } end
	local L = {
		framben = { v = kedja(), h = kedja() },
		bakben = { v = kedja(), h = kedja() },
		hals = {}, bal = nil, huvud = nil, svans = nil,
	}
	local fore = Riggprofiler.leder
	Riggprofiler.leder = function() return L end
	local rot = { Position = Vector3.new(0, 3, 0) }
	rot.IsA = function(_, k) return k == "BasePart" end
	local hast = { Name = "Provhast", PrimaryPart = rot,
		GetAttribute = function() return nil end,
		FindFirstChild = function() return nil end }
	HastGang._satHastar({ hast })
	--[[ Lyftet i ett ben = knäledens vinkel. I stöd är den noll; i sväng inte. ]]
	local function lyfter(k) return math.abs(k[2].Transform.Pitch or 0) > 0.02 end
	local function vid(gait, fas, lead)
		for _ = 1, 40 do
			HastGang.mata(hast, { gait = gait, phase = fas, lead = lead, ryggar = false,
				airborne = false, speed = 3 })
			HastGang._steg(1 / 60, Vector3.new(0, 3, 10))
		end
		return {
			LF = lyfter(L.framben.v), RF = lyfter(L.framben.h),
			LH = lyfter(L.bakben.v), RH = lyfter(L.bakben.h),
		}
	end
	--[[ Trav vid fas 0,2: LH+RF bär (isättning 0, stöd 0,42), LF+RH svänger. ]]
	local t = vid("trot", 0.2)
	check("TRAV i benen: LH och RF bär, LF och RH lyfts — diagonalt",
		not t.LH and not t.RF and t.LF and t.RH,
		("LF %s RF %s LH %s RH %s"):format(tostring(t.LF), tostring(t.RF),
			tostring(t.LH), tostring(t.RH)))
	check("och HastGang läste traven ur den matade rörelsen",
		(HastGang._tillstand(hast) or {}).monster == "trav")
	--[[ Höger galopp vid fas 0,65: RF (isättning 0,5, stöd 0,25) bär ensam,
	     de andra tre svänger. Vänster galopp vid samma fas: LF bär. ]]
	local h = vid("canter", 0.65, "right")
	check("HÖGER GALOPP i benen: ledande höger fram bär ensam vid 0,65",
		not h.RF and h.LF and h.LH and h.RH)
	local v = vid("canter", 0.65, "left")
	check("VÄNSTER GALOPP i benen: vänster fram bär ensam vid samma fas",
		not v.LF and v.RF and v.LH and v.RH)
	--[[ RYGGNING: samma kontakter, men hoven förs FRAMÅT under stödet.
	     Tidigt i LH:s stöd står låret framåt i trav och bakåt i ryggning. ]]
	local function lar(ryggar, gait)
		for _ = 1, 40 do
			HastGang.mata(hast, { gait = gait, phase = 0.05, ryggar = ryggar,
				airborne = false, speed = if ryggar then -1 else 3 })
			HastGang._steg(1 / 60, Vector3.new(0, 3, 10))
		end
		return L.bakben.v[1].Transform.Pitch or 0
	end
	local fram, bak = lar(false, "trot"), lar(true, "halt")
	check("RYGGNING: stödbenet förs åt motsatt håll mot framåtgång",
		fram > 0.05 and bak < -0.05, ("fram %.3f · bak %.3f"):format(fram, bak))
	check("och ryggningen läser sin egen rad", (HastGang._tillstand(hast) or {}).monster == "rygga")
	Riggprofiler.leder = fore
end

print("\n── 7. Galoppens sida väljs ur banan när galoppen börjar ──")
do
	MovementController._satBanaForProv(0, 0, 60, 120)
	local loco = { gait = "trot" }
	--[[ Längs banans västra långsida, norrut (−Z): mitten ligger åt öster,
	     alltså till höger — höger varv. ]]
	local pos, framat = Vector3.new(5, 0, 60), Vector3.new(0, 0, -1)
	MovementController._varvOchLedande(loco, pos, framat, "walk")
	check("varvet räknas ur banan: höger", loco.varv == "right", tostring(loco.varv))
	loco.gait = "canter"
	MovementController._varvOchLedande(loco, pos, framat, "trot")
	check("galoppen börjar på höger varv: höger galopp", loco.lead == "right", tostring(loco.lead))
	--[[ Ett styrutslag åt andra hållet mitt i galoppen byter inte ben. ]]
	MovementController._varvOchLedande(loco, pos, Vector3.new(0, 0, 1), "canter")
	check("ett varvbyte mitt i galoppen byter inte ledande ben", loco.lead == "right",
		tostring(loco.lead))
	loco.gait = "trot"
	MovementController._varvOchLedande(loco, pos, Vector3.new(0, 0, 1), "canter")
	check("efter galoppen finns ingen sida", loco.lead == nil)
	MovementController._varvOchLedande(loco, Vector3.new(500, 0, 500), framat, "trot")
	check("utanför banan är varvet okänt", loco.varv == nil)
end

if fel > 0 then
	print(("\n%d mätning(ar) föll."):format(fel))
	error("gangfas.spec: " .. fel .. " fel")
end
print("\ngangfas.spec: alla gröna")
