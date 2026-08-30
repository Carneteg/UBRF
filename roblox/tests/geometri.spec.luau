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

-- Husen är FÖRSKJUTNA i längdled, inte i liv. Testet krävde tidigare att de
-- norra gavlarna sammanföll och kallade det satellitverifierat; det var en
-- starkare utsaga än underlaget bär, och satellitbilden visar förskjutning.
-- Nu kontrolleras att förskjutningen FINNS och har rätt tecken: stallets
-- norra gavel ligger söder om ridhusets. Storleken är REFERENCE GAP.
do
	local rn = ridhus.rekt.y + ridhus.rekt.h
	local sn = stall.rekt.y + stall.rekt.h
	-- Tecknet spelar roll: stallet ligger NORR om ridhuset. Med fel tecken
	-- hamnade husens södra ändar nästan i liv, vilket stall-gavel-06-silon.jpg
	-- motsäger direkt — ridhusets södra ände går långt närmare kameran.
	check("stallets norra gavel ligger norr om ridhusets",
		sn - rn > 0.5,
		string.format("ridhusets norra gavel y = %.2f, stallets y = %.2f (%.2f m isär)",
			rn, sn, sn - rn))
end

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
	-- Antalet fack ska vara precis så många som planen säger. Testet hade
	-- "#fack < 11" hårdkodat, en gräns skriven för den gamla nioboxplanen;
	-- när längden mättes till 69,95 m och boxantalet blev 12 föll den utan
	-- att något var fel. En gräns som inte läser datan mäter inte datan.
	check("lika många fack som planen har boxar", #fack == S.antalBoxar,
		#fack .. " fack mot " .. S.antalBoxar .. " i planen")
	check("facken ryms mellan service och klubbdel",
		#fack > 0 and fack[1].y0 >= S.boxStartY - 0.001
			and fack[#fack].y1 <= S.klubbY + 0.001,
		#fack > 0 and string.format("%.2f..%.2f mot %.2f..%.2f",
			fack[1].y0, fack[#fack].y1, S.boxStartY, S.klubbY) or "inga fack")
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
		w = R.laktare.dackDjup, h = R.laktare.y1 - R.laktare.y0 }
	local bana = { x = R.bana.x, y = R.bana.y, w = R.bana.w, h = R.bana.h }
	check("läktaren tränger inte in på banan",
		Geometri.overlapp(laktare, bana) < 0.01,
		string.format("%.2f m²", Geometri.overlapp(laktare, bana)))

--[[ ORIENTERINGEN är en öppen fråga (se noten vid RIDHUSINNE.sidor). Kravet
	från reviewn är att en framtida SPEGLING ska vara en dataändring och inte
	ett ombygge. Testet mäter att läktarens läge och panelens sida FÖLJER
	`sidor` — skrivs de som tal igen går det sönder, och då är speglingen
	inte längre en dataändring. ]]
do
	local R = UBRFKomplex.ridhus
	local S = R.sidor
	local D = R.laktare.dackDjup
	--[[ Testet skrev förut av formeln för x0 och föll när härledningen
		rättades — det mätte formeln, inte regeln. Regeln är: läktaren står
		på den sida `sidor` pekar ut, och banan tätt mot den andra väggen. ]]
	local ostS = S ~= nil and S.laktare == "E"
	check("läktarens sida följer RIDHUSINNE.sidor",
		S ~= nil and (if ostS then R.laktare.x0 > R.bredd / 2
		              else R.laktare.x0 < R.bredd / 2),
		string.format("sidor.laktare=%s, x0 %.2f av bredd %.2f",
			tostring(S and S.laktare), R.laktare.x0, R.bredd))
	check("panelens sida följer RIDHUSINNE.sidor",
		S ~= nil and UBRFKomplex.identitet.ridhus.ovreVagg.sida == S.panel,
		string.format("sidor.panel=%s, ovreVagg.sida=%s",
			tostring(S and S.panel),
			tostring(UBRFKomplex.identitet.ridhus.ovreVagg.sida)))
	local Lk = R.laktare
	check("domarbåset står PÅ läktardäcket, inte bredvid det",
		R.domarbas ~= nil
			and R.domarbas.x >= math.min(Lk.x0, Lk.x0 + Lk.dackDjup) - 0.01
			and R.domarbas.x <= math.max(Lk.x0, Lk.x0 + Lk.dackDjup) + 0.01,
		string.format("bås x %.2f, däck %.2f–%.2f", R.domarbas and R.domarbas.x or -1,
			Lk.x0, Lk.x0 + Lk.dackDjup))
	check("läktaren och panelen ligger på MOTSATTA långsidor",
		S ~= nil and S.laktare ~= S.panel,
		tostring(S and S.laktare) .. " mot " .. tostring(S and S.panel))
end

--[[ Sponsorskyltarna ska hänga PÅ den rostbruna panelen, inte på den ljusa
	väggen. Läget låg förut som literaler som råkade ligga rätt; flyttades
	panelen följde de inte med. Testet läser BÅDA ur datan, så det mäter
	relationen och inte ett minne av talen. Samma sjuka som fällt silon och
	gårdsplanen i det här arbetet. ]]
do
	local O = UBRFKomplex.identitet.ridhus.ovreVagg
	local utanfor, n = 0, 0
	for _, sk in ipairs(UBRFKomplex.ridhus.skyltar) do
		n += 1
		if sk.y - sk.b / 2 < O.y0 - 0.01 or sk.y + sk.b / 2 > O.y1 + 0.01 then
			utanfor += 1
		end
	end
	check("alla sponsorskyltar hänger innanför den rostbruna panelen",
		n > 0 and utanfor == 0,
		string.format("%d av %d utanför stycket y %.1f–%.1f", utanfor, n, O.y0, O.y1))

	--[[ Det räcker inte. Testet ovan passerar för VILKA literaler som helst
		som råkar hamna innanför ett brett stycke — jag prövade det genom att
		frikoppla skyltarna och ge dem tal i intervallet 8–12, och det
		förblev grönt. Det mätte alltså inte kopplingen, bara att de låg
		innanför.

		Det här testet mäter KOPPLINGEN: varje skylts y ska vara exakt det
		som andelen ger ur panelens stycke. Ersätter någon härledningen med
		tal faller det, även om talen ligger rätt just då. ]]
	local losa = 0
	for _, sk in ipairs(UBRFKomplex.ridhus.skyltar) do
		if sk.andel ~= nil then
			local vantat = O.y0 + (O.y1 - O.y0) * sk.andel
			if math.abs(sk.y - vantat) > 0.01 then losa += 1 end
		end
	end
	check("skyltarnas läge är HÄRLETT ur panelen, inte skrivet som tal",
		losa == 0, losa .. " skyltar följer inte sin andel")
end
	--[[ Löd förut "läktaren ligger öster om banan" och mätte alltså ÖSTER,
		inte relationen. Under ett speglingsprov föll den fast bygget var
		riktigt — den mätte ett minne av datan. Nu: läktaren ska ligga
		bredvid banan på den sida `sidor` pekar ut, aldrig inne på den. ]]
	local ost = R.sidor == nil or R.sidor.laktare == "E"
	check("läktaren ligger BREDVID banan, på den sida sidor pekar ut",
		if ost then R.laktare.x0 >= R.bana.x + R.bana.w - 0.01
		else R.laktare.x0 + R.laktare.dackDjup <= R.bana.x + 0.01,
		string.format("läktare %.2f–%.2f, bana %.2f–%.2f",
			R.laktare.x0, R.laktare.x0 + R.laktare.dackDjup,
			R.bana.x, R.bana.x + R.bana.w))
end

do
	-- Sargporten är gapet i norra kortsidan. Där rider man in, och där står A.
	local bredd = R.port.x1 - R.port.x0
	check("sargporten är en användbar öppning", bredd > 1.5 and bredd < 4,
		string.format("%.1f m bred, vid x %g–%g", bredd, R.port.x0, R.port.x1))
	check("porten ligger inom banans kortsida",
		R.port.x0 >= R.bana.x and R.port.x1 <= R.bana.x + R.bana.w)
end

do
	-- Kortändans läktare ligger vid bokstaven C, alltså mitt på en kortsida,
	-- och glasbandet sitter ovanför den. Att den ligger vid RÄTT kortända är
	-- poängen: läggs den vid fel ände hamnar den bakom A i stället för C.
	local K = R.kortanda
	check("kortändans läktare finns", K ~= nil)
	if K then
		check("den ligger vid södra kortändan, där C sitter",
			K.y1 < R.bana.y + R.bana.h * 0.25,
			string.format("blocket y %.2f–%.2f, banan y %.2f–%.2f",
				K.y0, K.y1, R.bana.y, R.bana.y + R.bana.h))
		check("den har två trappor upp", #K.trappor == 2, #K.trappor .. " st")
		check("blocket spänner över större delen av kortsidan",
			(K.x1 - K.x0) > R.bredd * 0.7,
			string.format("%.1f m av husets %.1f", K.x1 - K.x0, R.bredd))
	end
end

do
	--[[ Grinden i sargens östra långsida. Utan den är hästgången dekoration:
	     man kommer in i ridhuset men inte ut på banan. Webbens vägsökning
	     hittade ingen väg dit förrän grinden fanns. ]]
	local gr = R.sargGrind
	check("sargen har en grind mot hästgången", gr ~= nil)
	if gr then
		check("grinden är bred nog att leda en häst igenom", gr.y1 - gr.y0 >= 2.5,
			string.format("%.1f m", gr.y1 - gr.y0))
		check("grinden ligger inom läktargapet",
			gr.y0 >= R.laktare.gap.y0 - 0.01 and gr.y1 <= R.laktare.gap.y1 + 0.01,
			string.format("grind %g–%g, gap %g–%g",
				gr.y0, gr.y1, R.laktare.gap.y0, R.laktare.gap.y1))
		local gMitt = R.origo.y + (gr.y0 + gr.y1) / 2
		local hMitt = hastgang.rekt.y + hastgang.rekt.h / 2
		check("grinden ligger mitt för hästgången", math.abs(gMitt - hMitt) < 1.5,
			string.format("grindens mitt y = %.2f, gångens y = %.2f", gMitt, hMitt))
	end
end

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

do
	-- Ingenting får stå INNE i en ridbana. Domarkuren gjorde det: den låg
	-- på x 184..188,5 / y 148..151,5, alltså helt innanför uteridbanans
	-- staket (x 176..196 / y 119..159) — en byggnad mitt i banan man rider
	-- på. Ingen källa sade det; läget hade helt enkelt aldrig prövats mot
	-- staketrektangeln. Det här testet ser till att det inte kan hända igen,
	-- vare sig för kuren eller för något hus som läggs till senare.
	--
	-- En ridbana = en sluten "tra"-staketslinga vars insida är sandmark.
	local banor = {}
	for _, st in ipairs(UBRFKomplex.staket) do
		if st.typ == "tra" and #st.p >= 5 then
			local x0, y0 = math.huge, math.huge
			local x1, y1 = -math.huge, -math.huge
			for _, pt in ipairs(st.p) do
				x0 = math.min(x0, pt[1]); x1 = math.max(x1, pt[1])
				y0 = math.min(y0, pt[2]); y1 = math.max(y1, pt[2])
			end
			for _, m in ipairs(UBRFKomplex.mark) do
				if m.typ == "sand"
					and math.abs(m.rekt.x - x0) < 1 and math.abs(m.rekt.y - y0) < 1
					and math.abs(m.rekt.w - (x1 - x0)) < 1
					and math.abs(m.rekt.h - (y1 - y0)) < 1 then
					table.insert(banor, { x0 = x0, y0 = y0, x1 = x1, y1 = y1 })
					break
				end
			end
		end
	end
	check("ridbanorna hittades ur staket + sandmark", #banor >= 1, #banor .. " banor")

	for _, ban in ipairs(banor) do
		for _, b in ipairs(UBRFKomplex.byggnader) do
			local r = b.rekt
			local overlappar = r.x < ban.x1 and r.x + r.w > ban.x0
				and r.y < ban.y1 and r.y + r.h > ban.y0
			check(("%s står inte i ridbanan %g,%g"):format(b.id, ban.x0, ban.y0),
				not overlappar,
				overlappar and ("%g..%g / %g..%g krockar"):format(
					r.x, r.x + r.w, r.y, r.y + r.h) or nil)
		end
	end
end

do
	-- Gångytorna är spelarens enda framkomliga mängd i stallet. Två ytor som
	-- bara TANGERAR varandra räcker inte: kollisionsradien klämmer punkten in
	-- i den ena eller den andra och lämnar ett dödband emellan. Vid
	-- brandväggen gav det ingen väg alls mellan stallgången och klubbhallen —
	-- den som gick in genom entrén blev stående i klubbdelen.
	--
	-- Testet kräver därför att ytorna hänger ihop med RIKTIGT överlapp, och
	-- att alla ytor når varandra. Ett tangerande hörn räknas inte.
	local ytor = UBRFKomplex.stall.gangytor
	check("det finns gångytor att mäta på", #ytor >= 2, #ytor .. " ytor")

	local MARGINAL = 0.2
	local function overlappar(a, b)
		local x = math.min(a.x + a.w, b.x + b.w) - math.max(a.x, b.x)
		local y = math.min(a.y + a.h, b.y + b.h) - math.max(a.y, b.y)
		return x > MARGINAL and y > MARGINAL
	end

	-- Sammanhängande? Flodfyll från första ytan.
	local natt = { [1] = true }
	local andrad = true
	while andrad do
		andrad = false
		for i = 1, #ytor do
			if not natt[i] then
				for j = 1, #ytor do
					if natt[j] and overlappar(ytor[i], ytor[j]) then
						natt[i] = true; andrad = true; break
					end
				end
			end
		end
	end
	local onadda = {}
	for i = 1, #ytor do
		if not natt[i] then
			table.insert(onadda, string.format("#%d (%.1f,%.1f %.1fx%.1f)",
				i, ytor[i].x, ytor[i].y, ytor[i].w, ytor[i].h))
		end
	end
	check("alla gångytor hänger ihop med varandra", #onadda == 0,
		#onadda == 0 and (#ytor .. " ytor i ett stycke")
			or ("onådda: " .. table.concat(onadda, ", ")))
end

do
	-- Ingen byggnad får överlappa en annan. Sviten hade inget sådant test alls,
	-- och när de mätta bredderna gjorde stallet 8 m bredare fanns ingenting som
	-- hade fångat en krock. Att det råkade gå bra är inte ett test.
	local b = UBRFKomplex.byggnader
	local krockar = {}
	for i = 1, #b do
		for j = i + 1, #b do
			local p, q = b[i].rekt, b[j].rekt
			local ox = math.min(p.x + p.w, q.x + q.w) - math.max(p.x, q.x)
			local oy = math.min(p.y + p.h, q.y + q.h) - math.max(p.y, q.y)
			if ox > 0.01 and oy > 0.01 then
				table.insert(krockar, string.format("%s x %s (%.2f m²)",
					b[i].id, b[j].id, ox * oy))
			end
		end
	end
	check("ingen byggnad överlappar en annan", #krockar == 0,
		#krockar == 0 and (#b .. " byggnader") or table.concat(krockar, ", "))
end

do
	-- Träningsytorna listas med NEUTRALA plats-ID, oberoende av spelnamn.
	-- Måttet 33,57 hör till marken, inte till spelobjektet, så testet frågar
	-- efter ytan — inte efter "uteridbanan".
	local Y = UBRFKomplex.traningsytor
	check("den stora nordöstra ytan finns i listan", Y.NO_STOR ~= nil)
	check("dess mätta kortsida är 33,57",
		Y.NO_STOR ~= nil and math.abs(Y.NO_STOR.w - 33.57) < 0.01,
		Y.NO_STOR and string.format("%.2f m", Y.NO_STOR.w) or "saknas")
	check("den mindre ytan finns också", Y.NO_LITEN ~= nil)

	-- Båda ska ligga norr om husens gavellinje och innanför tomten.
	for namn, r in pairs(Y) do
		check(namn .. " ligger norr om husen och innanför tomten",
			r.y >= 119 - 6.5 and r.x >= 0 and r.x + r.w <= UBRFKomplex.bredd
				and r.y + r.h <= UBRFKomplex.djup,
			string.format("x %.1f..%.1f  y %.1f..%.1f", r.x, r.x + r.w, r.y, r.y + r.h))
	end

	-- Ytorna får inte överlappa varandra.
	local a, b = Y.NO_STOR, Y.NO_LITEN
	if a and b then
		local ox = math.min(a.x + a.w, b.x + b.w) - math.max(a.x, b.x)
		local oy = math.min(a.y + a.h, b.y + b.h) - math.max(a.y, b.y)
		check("de två ytorna överlappar inte varandra",
			not (ox > 0.01 and oy > 0.01),
			(ox > 0.01 and oy > 0.01) and string.format("%.1f m²", ox * oy) or nil)
	end
end

do
	-- Silon står TÄTT MOT stallets södra gavel — det är vad
	-- references/buildings/stall/stall-gavel-06-silon.jpg visar.
	--
	-- Testet finns för att just det här har glidit TVÅ gånger. Silons läge
	-- var skrivet som ett tal; när gaveln flyttade (först vid längdmätningen,
	-- sedan vid gavelförskjutningens teckenvändning) stod talet kvar och
	-- silon lämnades ute på gården. Läget räknas nu ur gaveln, och det här
	-- testet ser till att det förblir så.
	local silo
	for _, p in ipairs(UBRFKomplex.props) do
		if p.typ == "silo" then silo = p end
	end
	check("silon finns i rekvisitan", silo ~= nil)
	if silo and stall then
		local RADIE = 1.5                      -- samma som v3dRekvisita bygger
		local avstand = stall.rekt.y - (silo.pos[2] + RADIE)
		check("silon står tätt mot stallets södra gavel",
			avstand >= -0.2 and avstand <= 0.3,
			string.format("mantelkant y = %.2f, gavel y = %.2f (%.2f m glapp)",
				silo.pos[2] + RADIE, stall.rekt.y, avstand))
		check("silon står mitt för gaveln",
			math.abs(silo.pos[1] - (stall.rekt.x + stall.rekt.w / 2)) < 0.5,
			string.format("silon x = %.2f, gavelns mitt x = %.2f",
				silo.pos[1], stall.rekt.x + stall.rekt.w / 2))
	end

	-- Gårdsplanen ska MÖTA gaveln, inte sluta en bit ifrån den.
	local gard
	for _, m in ipairs(UBRFKomplex.mark) do
		if m.typ == "grus" and math.abs(m.rekt.x - 148) < 0.01 then gard = m end
	end
	if gard and stall then
		check("gårdsplanen når fram till stallets gavel",
			math.abs((gard.rekt.y + gard.rekt.h) - stall.rekt.y) < 0.3,
			string.format("grusets norra kant y = %.2f, gavel y = %.2f",
				gard.rekt.y + gard.rekt.h, stall.rekt.y))
	end
end

if fails > 0 then
	print(string.format("\n%d FEL", fails))
	error("geometri.spec: " .. fails .. " fel")
end
print("\nalla gröna")
