--!nostrict
--[[
	Mätningar på anläggningens geometri i Roblox-spåret.

	Den här specen finns för att paritet inte ska vara ett påstående. Den läser
	UBRFKomplex.luau — filen som genereras ur src/site.js — och kontrollerar att
	Roblox-sidan får ut samma anläggning som webben bygger: att husen sitter
	ihop, att hästgången möter båda, och att öppningarna hamnar i rätt ände av
	rätt fasad.

	Den kan INTE se om src/site.js har ändrats utan att exporten körts om. Det
	kontrollerar node-sviten med `git diff --exit-code` efter en export, och de
	två hör ihop: den här mäter innehållet, den där mäter synken.

	Kör: python3 roblox/tests/build.py tests/geometri.spec.luau
	     && luau roblox/tests/.build/geometri.spec.luau
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

local function nara(a, b, tol)
	return math.abs(a - b) <= (tol or 0.001)
end

local function hus(id)
	for _, b in ipairs(UBRFKomplex.byggnader) do
		if b.id == id then return b end
	end
	return nil
end

print("Anläggningens geometri, ur UBRFKomplex.luau")

local ridhus, stall, hastgang = hus("ridhus"), hus("stall"), hus("hastgang")
check("ridhuset finns i den exporterade geometrin", ridhus ~= nil)
check("stallet finns", stall ~= nil)
check("hästgången finns", hastgang ~= nil)

--[[ ── Byggnadskomplexet ──────────────────────────────────────────────
	Gate F01:s connected-complex-krav. Om någon flyttar ett hus i src/site.js
	och glömmer hästgången faller de här tre, på båda plattformarna samtidigt. ]]

check("hästgången sitter ihop med ridhuset",
	Geometri.sitterIhop(hastgang.rekt, ridhus.rekt),
	string.format("ridhusets östvägg x=%g, hästgångens västvägg x=%g",
		ridhus.rekt.x + ridhus.rekt.w, hastgang.rekt.x))

check("hästgången sitter ihop med stallet",
	Geometri.sitterIhop(hastgang.rekt, stall.rekt),
	string.format("hästgångens östvägg x=%g, stallets västvägg x=%g",
		hastgang.rekt.x + hastgang.rekt.w, stall.rekt.x))

check("ridhus och stall möts inte direkt — hästgången är det som binder dem",
	not Geometri.sitterIhop(ridhus.rekt, stall.rekt))

do
	--[[ Satellitbilden visar EN tvärgående förbindelse och ger inte stöd för
	     två. Alltså får ingen annan byggnad binda ihop båda husen — den låga
	     längan i söder allra minst, den är overifierad. Räknas här i stället
	     för att kommenteras: en framtida ändring som råkar låta längan nudda
	     båda husen ska falla direkt. ]]
	local forbindelser = {}
	for _, b in ipairs(UBRFKomplex.byggnader) do
		if b.id ~= "ridhus" and b.id ~= "stall"
			and Geometri.sitterIhop(b.rekt, ridhus.rekt)
			and Geometri.sitterIhop(b.rekt, stall.rekt) then
			table.insert(forbindelser, b.id)
		end
	end
	check("exakt en byggnad binder ihop husen", #forbindelser == 1,
		table.concat(forbindelser, ", "))
	check("och det är hästgången", forbindelser[1] == "hastgang",
		tostring(forbindelser[1]))

	-- Den låga längan i söder är overifierad och får inte vara en förbindelse.
	local langa = hus("langa")
	if langa then
		check("den låga längan i söder binder inte ihop husen",
			not (Geometri.sitterIhop(langa.rekt, ridhus.rekt)
				and Geometri.sitterIhop(langa.rekt, stall.rekt)))
	end
end

check("hästgången ligger inom båda husens längd",
	hastgang.rekt.y >= math.max(ridhus.rekt.y, stall.rekt.y)
		and hastgang.rekt.y + hastgang.rekt.h
			<= math.min(ridhus.rekt.y + ridhus.rekt.h, stall.rekt.y + stall.rekt.h),
	string.format("hästgången y %g–%g", hastgang.rekt.y, hastgang.rekt.y + hastgang.rekt.h))

check("de norra gavlarna ligger i liv, som i satellitbilden",
	nara(ridhus.rekt.y + ridhus.rekt.h, stall.rekt.y + stall.rekt.h))

--[[ ── Interna öppningar ──────────────────────────────────────────────
	En öppning märkt intern vetter mot ett grannhus, inte ut mot gården. Den
	ska alltså ligga i den vägg som faktiskt möter grannen, annars är den en
	dörr rakt ut i luften som ingen markör varnar för. ]]

local internaFunna = 0
for _, b in ipairs(UBRFKomplex.byggnader) do
	for _, o in ipairs(b.oppningar or {}) do
		if o.intern then
			internaFunna += 1
			local mx, mz = Geometri.oppningsMitt(b.rekt, o.sida, o.u, o.b)
			local nx, nz = Geometri.normal(o.sida)
			-- En halvmeter utanför fasaden ska ligga inuti ett annat hus.
			local px, pz = mx + nx * 0.5, mz + nz * 0.5
			local inuti = false
			for _, annan in ipairs(UBRFKomplex.byggnader) do
				local r = annan.rekt
				if annan.id ~= b.id and px >= r.x and px <= r.x + r.w
					and pz >= r.y and pz <= r.y + r.h then inuti = true end
			end
			check(string.format("intern öppning i %s (%s) vetter mot ett grannhus",
				b.id, o.sida), inuti, string.format("mitt (%.1f, %.1f)", mx, mz))
		end
	end
end
check("det finns interna öppningar alls", internaFunna >= 2,
	internaFunna .. " st")

--[[ ── Öppningarnas placering i fasaden ────────────────────────────────
	u mäts från fasadens p0, och p0 → p1 går medurs sett utifrån. På N och W
	betyder det mot MINSKANDE koordinat. Får man det bakvänt hamnar varje dörr
	i fel ände av sitt hus — och den vanliga rundvandringen märker det inte,
	för husen är symmetriska nog att se rimliga ut ändå. ]]

local prov = { x = 10, y = 20, w = 30, h = 40 }

do
	local x, z, along, side = Geometri.oppningsHorn(prov, "S", 5, 2)
	check("S: u räknas österut från sydvästra hörnet",
		nara(x, 15) and nara(z, 20) and along == "X" and side == -1)
end
do
	local x, z, along, side = Geometri.oppningsHorn(prov, "N", 5, 2)
	check("N: u räknas västerut från nordöstra hörnet",
		nara(x, 33) and nara(z, 60) and along == "X" and side == 1,
		string.format("x=%g (väntat 33)", x))
end
do
	local x, z, along, side = Geometri.oppningsHorn(prov, "E", 5, 2)
	check("E: u räknas norrut från sydöstra hörnet",
		nara(x, 40) and nara(z, 25) and along == "Z" and side == 1)
end
do
	local x, z, along, side = Geometri.oppningsHorn(prov, "W", 5, 2)
	check("W: u räknas söderut från nordvästra hörnet",
		nara(x, 10) and nara(z, 53) and along == "Z" and side == -1,
		string.format("z=%g (väntat 53)", z))
end

--[[ ── Taken ───────────────────────────────────────────────────────────
	Lutningen anges inte utan räknas ur takfot och nock, så att ett ändrat
	nockmått inte kan lämna ett tak med gammal lutning efter sig. ]]

for _, b in ipairs(UBRFKomplex.byggnader) do
	local grader = Geometri.taklutning(b.rekt, b.hV, b.hN, b.nock)
	check(string.format("%s har en byggbar taklutning", b.id),
		grader > 5 and grader < 50, string.format("%.1f°", grader))
end

do
	-- Stallets 28° är det tal byggnadskortet och auditen räknar med. Faller
	-- den här har bredden eller nockhöjden ändrats utan att kortet följt med.
	local grader = Geometri.taklutning(stall.rekt, stall.hV, stall.hN, stall.nock)
	check("stallets taklutning stämmer med byggnadskortets 28°",
		nara(grader, 28, 1.5), string.format("%.1f°", grader))
end

--[[ ── Dörrarna ────────────────────────────────────────────────────────
	Markörerna på gården ska stå utanför husen. 0,55 m är kollisionsmarginalen
	mot en byggnad i webbspelet; står markören närmare går den inte att nå. ]]

for _, d in ipairs(UBRFKomplex.dorrar) do
	local inuti = nil
	for _, b in ipairs(UBRFKomplex.byggnader) do
		local r = b.rekt
		if d.pos[1] > r.x + 0.05 and d.pos[1] < r.x + r.w - 0.05
			and d.pos[2] > r.y + 0.05 and d.pos[2] < r.y + r.h - 0.05 then inuti = b.id end
	end
	check("dörrmarkören " .. d.id .. " står utanför husen", inuti == nil,
		inuti and ("ligger inne i " .. inuti) or nil)
end

--[[ ══ INSIDORNA ═════════════════════════════════════════════════════════
	Review 02: datan i modulen räcker inte om byggaren struntar i den. Här mäts
	att Roblox faktiskt får ut Gate F01:s planform — och att den går att gå i. ]]

print("\nStallets insida")

local S = UBRFKomplex.stall

do
	local rader, gangar = 0, 0
	for _, b in ipairs(S.band) do
		if b.typ == "rad" then rader += 1 else gangar += 1 end
	end
	check("planen ger fyra boxrader och två gångar", rader == 4 and gangar == 2,
		string.format("%d rader, %d gångar", rader, gangar))
end

do
	local summa = 0
	for _, b in ipairs(S.band) do summa += b.andel end
	check("bandens andelar summerar till hela bredden", nara(summa, 1, 0.005),
		string.format("%.3f", summa))
end

check("interiören och fotavtrycket har samma mått",
	nara(S.bredd, stall.rekt.w) and nara(S.langd, stall.rekt.h),
	string.format("%g×%g mot %g×%g", S.bredd, S.langd, stall.rekt.w, stall.rekt.h))

check("interiörens origo är husets sydvästra hörn",
	nara(S.origo.x, stall.rekt.x) and nara(S.origo.y, stall.rekt.y))

do
	-- Tvärkorridoren ska nå BÅDA långsidorna. Planen har utrymningsvägar där,
	-- och en korridor som tar slut halvvägs är ingen utrymningsväg.
	local nadde = false
	for _, g in ipairs(S.gangytor) do
		if g.y >= S.tvarGang.y0 - 0.5 and g.y + g.h <= S.tvarGang.y1 + 0.5
			and g.x < 1.0 and g.x + g.w > S.bredd - 1.0 then nadde = true end
	end
	check("tvärkorridoren når båda långsidorna", nadde)
end

do
	-- Det Review 02 kallar "no overlapping solid geometry blocks the intended
	-- circulation": inget byggt boxfack får ligga i en gångyta.
	local varsta, var = 0, nil
	for _, rad in ipairs(S.rader) do
		for i, f in ipairs(Geometri.boxfack(S)) do
			local fack = { x = rad.x0, y = f.y0, w = rad.djup, h = f.y1 - f.y0 }
			for j, g in ipairs(S.gangytor) do
				local a = Geometri.overlapp(fack, g)
				if a > varsta then varsta, var = a, rad.id .. "/" .. i .. " mot gångyta " .. j end
			end
		end
	end
	check("inget boxfack ligger i en gångyta", varsta < 0.01,
		if var then string.format("värst %.2f m² vid %s", varsta, var)
		else "inget överlapp alls")
end

do
	local fack = Geometri.boxfack(S)
	check("boxfacken hoppar över tvärkorridoren", #fack > 0 and #fack < 11,
		#fack .. " fack per rad")
	for _, f in ipairs(fack) do
		local mitt = (f.y0 + f.y1) / 2
		if mitt > S.tvarGang.y0 and mitt < S.tvarGang.y1 then
			check("inget fack mitt i tvärkorridoren", false,
				string.format("fack %g–%g", f.y0, f.y1))
		end
	end
end

check("de namngivna rummen ur planen finns med", #S.rum >= 3,
	#S.rum .. " rum, " .. #S.service .. " servicedelar")

print("\nRidhusets insida")

local R = UBRFKomplex.ridhus

check("banan är 20 × 60", nara(R.bana.w, 20) and nara(R.bana.h, 60),
	string.format("%g × %g", R.bana.w, R.bana.h))

check("banan får plats i byggnaden",
	R.bana.x >= 0 and R.bana.y >= 0
		and R.bana.x + R.bana.w <= R.bredd and R.bana.y + R.bana.h <= R.langd,
	string.format("banan x %g–%g av %g, y %g–%g av %g",
		R.bana.x, R.bana.x + R.bana.w, R.bredd, R.bana.y, R.bana.y + R.bana.h, R.langd))

check("interiören och fotavtrycket har samma mått",
	nara(R.bredd, ridhus.rekt.w) and nara(R.langd, ridhus.rekt.h))

check("interiörens origo är husets sydvästra hörn",
	nara(R.origo.x, ridhus.rekt.x) and nara(R.origo.y, ridhus.rekt.y))

do
	-- Läktaren ligger öster om banan och får inte äta in i den.
	local laktare = { x = R.laktare.x0, y = R.laktare.y0,
		w = R.laktare.steg * R.laktare.stegD, h = R.laktare.y1 - R.laktare.y0 }
	local bana = { x = R.bana.x, y = R.bana.y, w = R.bana.w, h = R.bana.h }
	check("läktaren tränger inte in på banan",
		Geometri.overlapp(laktare, bana) < 0.01,
		string.format("%.2f m²", Geometri.overlapp(laktare, bana)))
	check("läktaren ligger öster om banan", R.laktare.x0 >= R.bana.x + R.bana.w - 0.01)
end

do
	-- Sargporten är gapet i norra kortsidan. Där rider man in, och där står A.
	local bredd = R.port.x1 - R.port.x0
	check("sargporten är en användbar öppning", bredd > 1.5 and bredd < 4,
		string.format("%.1f m bred, vid x %g–%g", bredd, R.port.x0, R.port.x1))
	check("porten ligger inom banans kortsida",
		R.port.x0 >= R.bana.x and R.port.x1 <= R.bana.x + R.bana.w)
end

check("de tre glasade rummen finns med", #R.glasrum == 3, #R.glasrum .. " st")

do
	--[[ Satellitbilden (references/plans/SATELLIT-HASTGANG-2026-08-30.md):
	     förbindelsen ligger CENTRALT i husens gemensamma längd, inte vid en
	     ände, och delar mellanrummet i två skilda gårdsytor. Flyttar någon
	     tillbaka den till en ände faller det här. ]]
	local g0 = math.max(ridhus.rekt.y, stall.rekt.y)
	local g1 = math.min(ridhus.rekt.y + ridhus.rekt.h, stall.rekt.y + stall.rekt.h)
	local norr = g1 - (hastgang.rekt.y + hastgang.rekt.h)
	local soder = hastgang.rekt.y - g0
	check("hästgången ligger centralt, med gårdsyta kvar på båda sidor",
		norr > 8 and soder > 8,
		string.format("%.1f m norr om den, %.1f m söder", norr, soder))

	-- Och den ska ligga i liv med stallets tvärkorridor, som planen visar når
	-- båda långsidorna. Det är den ena av de två källorna som pekar hit.
	local kMitt = S.origo.y + (S.tvarGang.y0 + S.tvarGang.y1) / 2
	local hMitt = hastgang.rekt.y + hastgang.rekt.h / 2
	check("gången möter stallets tvärkorridor", math.abs(kMitt - hMitt) < 1.5,
		string.format("korridorens mitt y = %.2f, gångens y = %.2f", kMitt, hMitt))
end

do
	-- Läktaren måste ha ett gap där gången kommer in, annars är den murad.
	local L = R.laktare
	check("läktaren har ett gap för hästgången", L.gap ~= nil)
	if L.gap then
		check("gapet är brett nog att leda en häst igenom", L.gap.y1 - L.gap.y0 >= 2.5,
			string.format("%.1f m", L.gap.y1 - L.gap.y0))
		local vartRi = R.origo.y + (L.gap.y0 + L.gap.y1) / 2
		local hMitt = hastgang.rekt.y + hastgang.rekt.h / 2
		check("gapet ligger mitt för hästgången", math.abs(vartRi - hMitt) < 1.5,
			string.format("gapets mitt y = %.2f, gångens y = %.2f", vartRi, hMitt))
		check("läktaren blir två sektioner", #Geometri.laktarSektioner(L) == 2,
			#Geometri.laktarSektioner(L) .. " sektioner")
	end
end
check("domarbåset har trappa och exit-skylt", R.domarbas.trappa and R.domarbas.exit)

do
	-- Insidorna får inte sticka ut ur sina hus i världskoordinater.
	for _, par in ipairs({ { "stall", S, stall }, { "ridhus", R, ridhus } }) do
		local namn, inre, hus = par[1], par[2], par[3]
		check(namn .. "s insida ligger innanför sitt fotavtryck",
			nara(inre.origo.x + inre.bredd, hus.rekt.x + hus.rekt.w)
				and nara(inre.origo.y + inre.langd, hus.rekt.y + hus.rekt.h))
	end
end

if fails > 0 then
	print(string.format("\n%d FEL", fails))
	error("geometri.spec: " .. fails .. " fel")
end
print("\nalla gröna")
