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

if fails > 0 then
	print(string.format("\n%d FEL", fails))
	error("geometri.spec: " .. fails .. " fel")
end
print("\nalla gröna")
