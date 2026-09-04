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
	-- Tvärkorridoren mellan boxhallen och klubbdelen ska nå BÅDA långsidorna.
	-- Planen har utrymningsvägar där (`DEFERRED BY EXTERIOR LOCK`), och en
	-- korridor som tar slut halvvägs är ingen utrymningsväg. Korridoren mitt
	-- i boxhallen som stod här förut finns inte i planen — se `brott`.
	local nadde = false
	for _, g in ipairs(S.gangytor) do
		if g.y <= S.klubbY + 0.5 and g.y + g.h >= S.klubb.y0 - 0.5
			and g.x < 1.0 and g.x + g.w > S.bredd - 1.0 then nadde = true end
	end
	check("tvärkorridoren mellan boxhall och klubbdel når båda långsidorna", nadde)
end

do
	-- Det Review 02 kallar "no overlapping solid geometry blocks the intended
	-- circulation": inget byggt boxfack får ligga i en gångyta.
	local varsta, var = 0, nil
	for _, rad in ipairs(S.rader) do
		for i, f in ipairs(Geometri.boxfack(S, rad)) do
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

for _, rad in ipairs(S.rader) do
	local fack = Geometri.boxfack(S, rad)
	-- Antalet fack per rad ska vara precis så många som planen säger, minus
	-- de brott hästförbindelsen gör i just den raden. Testet hade "#fack < 11"
	-- hårdkodat en gång; en gräns som inte läser datan mäter inte datan.
	local brott = 0
	for _, b in ipairs(S.brott or {}) do if b.rad == rad.id then brott += 1 end end
	check(string.format("rad %s: lika många fack som planen har boxar, minus radens brott", rad.id),
		#fack == S.antalBoxar - brott,
		string.format("%d fack mot %d − %d", #fack, S.antalBoxar, brott))
	check(string.format("rad %s: facken ryms mellan service och klubbdel", rad.id),
		#fack > 0 and fack[1].y0 >= S.boxStartY - 0.001
			and fack[#fack].y1 <= S.klubbY + 0.001,
		#fack > 0 and string.format("%.2f..%.2f mot %.2f..%.2f",
			fack[1].y0, fack[#fack].y1, S.boxStartY, S.klubbY) or "inga fack")
	for _, b in ipairs(S.brott or {}) do
		if b.rad ~= rad.id then continue end
		for _, f in ipairs(fack) do
			if f.y1 > b.y0 + 0.01 and f.y0 < b.y1 - 0.01 then
				check("inget fack i hästförbindelsens brott", false,
					string.format("rad %s fack %g–%g mot brott %g–%g", rad.id, f.y0, f.y1, b.y0, b.y1))
			end
		end
	end
end

do
	local K = S.klubb
	local namn = {}
	for _, r in ipairs(K.rum) do namn[r.id] = true end
	check("klubbdelens rum ur planen finns med",
		namn.uppehallsrum and namn.teorisal and namn.sadelkammare and namn.wc_v and namn.wc_o,
		#K.rum .. " rum, " .. #K.vaggar .. " väggar, " .. #S.service .. " servicedelar")
	--[[ Planens symbolruta x 5,9–7,3 är plan-belagd som fotavtryck; vad den
		är finns ingen oberoende källa för. Datan får inte kalla den trapphus
		eller hiss och inte sätta någon spelarsynlig etikett på den — samma
		regel som för ridhusets `schakt`. Geometrin PLAN, funktionen
		REFERENCE GAP. ]]
	do
		local sv, funktionsnamn = nil, nil
		for _, r in ipairs(K.rum) do
			if r.id == "sluten_volym" then sv = r end
			if r.id == "trapphus" or r.id == "hiss" then funktionsnamn = r.id end
			local et = (r.label or ""):upper()
			if et:find("TRAPP", 1, true) or et:find("HISS", 1, true) then funktionsnamn = r.id .. ":" .. r.label end
		end
		check("planens symbolruta är en namnlös sluten volym: inget `trapphus`/`hiss`, ingen etikett",
			sv ~= nil and sv.stangt == true and (sv.label == nil or sv.label == "") and funktionsnamn == nil,
			funktionsnamn or (sv and "sluten_volym utan etikett" or "sluten_volym saknas"))
		local ok = sv ~= nil
		for _, v in ipairs(K.vaggar) do
			if v.id:find("trapphus", 1, true) then ok = false end
		end
		check("inga väggar i klubbdelen bär trapphusnamn", ok)
	end
	--[[ Uppehållsrummet — Product Owner 2026-09-03: "för litet". Läst om i
		originalplanen (4032 px): rummet är L-format, västdelen x 0–5,9 ×
		N 0–10 och östdelen x 5,9–11,2 × N 0–5,6 utan vägg emellan; WC-V är
		3,0 m bred med dörr mot lobbyn; den dubbellinjeritade rutan är en
		sluten volym 1,0 × 4,4 m, inte en tjock vägg. Grinden mäter det som
		går att mäta: att delarna finns, hänger ihop och att golvytan inte
		krymper tillbaka. ]]
	do
		local U, Uo, W, L = nil, nil, nil, nil
		local slutna = {}
		for _, r in ipairs(K.rum) do
			if r.id == "uppehallsrum" then U = r end
			if r.id == "uppehallsrum_o" then Uo = r end
			if r.id == "wc_v" then W = r end
			if r.id == "lobby" then L = r end
			if r.stangt then table.insert(slutna, r) end
		end
		check("uppehållsrummet har en västdel och en östdel som hör ihop",
			U ~= nil and Uo ~= nil and Uo.del == "uppehallsrum" and (Uo.label == nil or Uo.label == ""))
		if U and Uo then
			-- ingen vägg får skilja delarna längs x 5,9 mellan vindfånget och volymen
			local skiljer = nil
			for _, v in ipairs(K.vaggar) do
				if v.typ == "langs" and math.abs(v.x - 5.9) < 0.05 then
					local y0, y1 = v.y0, v.y1
					if y1 > 65.1 and y0 < 67.9 and not (v.oppningar and #v.oppningar > 0) then skiljer = v.id end
				end
			end
			check("ingen vägg skiljer uppehållsrummets väst- och östdel", skiljer == nil, skiljer or "öppet x 5,9 mellan volymen och vindfånget")
			-- golvyta: delarna minus de slutna volymer som står i dem
			local function area(r) return r.rekt.w * r.rekt.h end
			local yta = area(U) + area(Uo)
			for _, s in ipairs(slutna) do
				for _, del in ipairs({ U, Uo }) do
					local a, b = s.rekt, del.rekt
					local ox = math.max(0, math.min(a.x + a.w, b.x + b.w) - math.max(a.x, b.x))
					local oy = math.max(0, math.min(a.y + a.h, b.y + b.h) - math.max(a.y, b.y))
					yta -= ox * oy
				end
			end
			check("uppehållsrummets golvyta är minst 75 m² (PO: rummet var för litet)",
				yta >= 75, string.format("%.1f m²", yta))
			check("uppehållsrummets västdel når hela vägen till WC-väggen N 10,0",
				math.abs(U.rekt.y - 59.95) < 0.05 and math.abs(U.rekt.y + U.rekt.h - S.langd) < 0.05,
				string.format("y %.2f–%.2f", U.rekt.y, U.rekt.y + U.rekt.h))
		end
		if W and L then
			check("WC-V är 3,0 m bred och lobbyn tar resten fram till volymen",
				math.abs(W.rekt.w - 3.0) < 0.05 and math.abs(L.rekt.x - 3.0) < 0.05 and math.abs(L.rekt.x + L.rekt.w - 5.9) < 0.05,
				string.format("WC x %.1f–%.1f, lobby x %.1f–%.1f", W.rekt.x, W.rekt.x + W.rekt.w, L.rekt.x, L.rekt.x + L.rekt.w))
			local dorr = nil
			for _, v in ipairs(K.vaggar) do
				if v.id == "wc_v_o" then for _, o in ipairs(v.oppningar or {}) do dorr = o end end
			end
			check("WC-V:s dörr sitter i östväggen mot lobbyn", dorr ~= nil and dorr.y0 > 57.45 and dorr.y1 < 59.95)
		end
		local spar = false
		for _, v in ipairs(K.vaggar) do if v.id == "spar" then spar = true end end
		check("den gamla tjocka väggen `spar` är borta", not spar)
	end

	--[[ SPATIAL CANON v2 (references/spatial/UBRF-SPATIAL-CANON-v2.json).
		SCV2-01: ingen runtime-vägg och ingen sluten volym skär det inre av
		stall_uppehall_open; PO-2026-09-03-STALL-OPEN-01 återkallade
		sluten_volym_v. SCV2-02: varje vägg/sluten volym i klubbdelen bär
		primitiv/canon_id/source_id/confidence. SCV2-04: confidence ur den
		tillåtna mängden — ett rumsnamn är inget belägg. ]]
	do
		local oppna = K.oppna or {}
		local zon = nil
		for _, z in ipairs(oppna) do if z.id == "stall_uppehall_open" then zon = z end end
		check("OPEN_AREA stall_uppehall_open finns i datan med PO-källa",
			zon ~= nil and zon.typ == "OPEN_AREA" and zon.confidence == "PRODUCT_OWNER_VERIFIED" and #zon.rekt >= 2)
		local ingen = nil
		for _, z in ipairs(K.ingaVaggar or {}) do if z.tacker == "stall_uppehall_open" then ingen = z end end
		check("NO_WALL_ZONE täcker uppehållsrummet", ingen ~= nil and ingen.typ == "NO_WALL_ZONE")
		local function skarInre(r)
			if not zon then return false end
			for _, q in ipairs(zon.rekt) do
				local ox = math.min(r.x + r.w, q.x + q.w) - math.max(r.x, q.x)
				local oy = math.min(r.y + r.h, q.y + q.h) - math.max(r.y, q.y)
				-- tröskeln är större än en halv väggtjocklek (0,08): en vägg PÅ ytans
				-- gräns räknas inte, en vägg INNE i ytan gör det
				if ox > 0.12 and oy > 0.12 then return true end
			end
			return false
		end
		local intrang = {}
		for _, v in ipairs(K.vaggar) do
			local t = (v.tjock or 0.16) / 2
			for _, bit in ipairs(Geometri.vaggBitar(v)) do
				local r = if v.typ == "tvar" then { x = bit.a0, y = v.y - t, w = bit.a1 - bit.a0, h = 2 * t }
					else { x = v.x - t, y = bit.a0, w = 2 * t, h = bit.a1 - bit.a0 }
				if skarInre(r) then table.insert(intrang, v.id) end
			end
		end
		for _, r in ipairs(K.rum) do
			if r.stangt and skarInre(r.rekt) then table.insert(intrang, r.id) end
		end
		check("SCV2-01: ingen vägg eller sluten volym skär uppehållsrummets öppna yta",
			#intrang == 0, #intrang > 0 and table.concat(intrang, ", ") or "ytan är öppen")
		local aterkallade = { sluten_volym_v = true, litet_rum = true, vindfang_v = true, vindfang_o = true, vindfang_fot = true, litet_v = true, litet_s = true, spar = true }
		local kvar = {}
		for _, v in ipairs(K.vaggar) do if aterkallade[v.id] then table.insert(kvar, v.id) end end
		for _, r in ipairs(K.rum) do if r.stangt and aterkallade[r.id] then table.insert(kvar, r.id) end end
		check("återkallad geometri är borta (sluten_volym_v, vindfångets stumpar, det lilla rummet)",
			#kvar == 0, #kvar > 0 and table.concat(kvar, ", ") or "borta")
		local tillat = { PRODUCT_OWNER_VERIFIED = true, VERIFIED_PLAN_OR_PHOTO = true }
		local utan, felTillit = {}, {}
		local function prova(o, id)
			if not (o.primitiv == "WALL" or o.primitiv == "GLASS") or not o.canon_id or not o.source_id or not o.confidence then
				table.insert(utan, id)
			elseif not tillat[o.confidence] then
				table.insert(felTillit, id)
			end
		end
		for _, v in ipairs(K.vaggar) do prova(v, v.id) end
		for _, r in ipairs(K.rum) do if r.stangt then prova(r, r.id) end end
		check("SCV2-02: varje vägg och sluten volym i klubbdelen bär primitiv, canon_id, source_id och confidence",
			#utan == 0, #utan > 0 and table.concat(utan, ", ") or "alla har provenance")
		check("SCV2-04: ingen partition i klubbdelen vilar på lägre belägg än plan/foto eller PO",
			#felTillit == 0, #felTillit > 0 and table.concat(felTillit, ", ") or "ok")
	end
	-- Alla rum ligger norr om den genomgående väggen, inuti huset.
	local utanfor = nil
	for _, r in ipairs(K.rum) do
		local k = r.rekt
		if k.y < K.y0 - 0.01 or k.y + k.h > S.langd + 0.01 or k.x < -0.01 or k.x + k.w > S.bredd + 0.01 then
			utanfor = r.id
		end
	end
	check("klubbdelens rum ligger alla i klubbdelen", utanfor == nil, utanfor or "alla innanför")
end

print("\nRidhusets insida")

local R = UBRFKomplex.ridhus

--[[ Senior review 2026-09-03: den FYSISKA banan (sarg till sarg) och
	DRESSYRLAYOUTEN (20 × 60) är två saker. Banan går från A-sargen mot
	gaveln (ridhus-inne-23) till entrédelens gräns (planen); layouten är 60 m
	oavsett hallens längd och förankrad i A. ]]
check("dressyrlayouten är 20 × 60", R.dressyr ~= nil and nara(R.dressyr.w, 20) and nara(R.dressyr.h, 60),
	R.dressyr and string.format("%g × %g", R.dressyr.w, R.dressyr.h) or "saknas")
check("A-sargen står mot A-gaveln — ingen flermeterszon bakom den (ridhus-inne-23)",
	R.bana.y >= 0 and R.bana.y <= 0.5,
	string.format("bana y0 %.2f (gap till gaveln)", R.bana.y))
check("den fysiska banan når entrédelens gräns och är längre än layouten",
	nara(R.bana.y + R.bana.h, R.langd - R.entre) and R.bana.h > 60 and nara(R.bana.w, 20),
	string.format("bana y %.2f–%.2f (h %.2f), entrédelen börjar %.2f", R.bana.y, R.bana.y + R.bana.h, R.bana.h, R.langd - R.entre))
check("dressyrlayouten ligger inne på banan, förankrad i A på södra sargen",
	R.dressyr ~= nil and nara(R.dressyr.x, R.bana.x) and nara(R.dressyr.y, R.bana.y)
		and R.dressyr.y + R.dressyr.h <= R.bana.y + R.bana.h + 0.01 and R.dressyr.forankring == "A")
check("domarbåset står vid E — layoutens mitt, inte banans",
	R.domarbas ~= nil and R.dressyr ~= nil and nara(R.domarbas.y, R.dressyr.y + R.dressyr.h / 2),
	R.domarbas and string.format("bås y %.2f, E %.2f", R.domarbas.y, R.dressyr.y + R.dressyr.h / 2) or "saknas")

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

	--[[ Omgranskning 2026-09-03 (docs/F02-RIDHUS-OMGRANSKNING.md):
		panelen går hörn till hörn (rad 3), fönstren är ett per fält (rad 5),
		läktarsidan har egen väggtyp med pelare (rad 2), och skyltordningen
		följer ridhus-inne-31/-17 (rad 8): VÄLKOMMEN längst norrut, två
		RS Mustang längst söderut, Hästsportbutik söder om Agria. ]]
	local R = UBRFKomplex.ridhus
	check("panelen täcker hallens hela långsida i datan",
		math.abs(O.y0) < 0.01 and math.abs(O.y1 - (R.langd - R.entre)) < 0.01,
		string.format("y %.1f–%.1f, hallen 0–%.1f", O.y0, O.y1, R.langd - R.entre))
	check("fönstren är separata per väggfält", UBRFKomplex.identitet.ridhus.fonsterband.perFalt == true)
	local LV = UBRFKomplex.identitet.ridhus.laktarVagg
	check("läktarlångsidan har en egen väggtyp med mörka pelare", LV ~= nil and LV.pelareB > 0 and LV.pelareFarg ~= nil)
	local S = R.skyltar
	local valk, mustang, agria, hast = nil, {}, nil, nil
	for _, sk in ipairs(S) do
		if sk.text:find("VÄLKOMMEN", 1, true) then valk = sk end
		if sk.text:find("RS Mustang", 1, true) then table.insert(mustang, sk) end
		if sk.text:find("Agria", 1, true) then agria = sk end
		if sk.text:find("Hästsportbutik", 1, true) then hast = sk end
	end
	local nordligast = true
	for _, sk in ipairs(S) do if valk and sk.y > valk.y + 0.01 then nordligast = false end end
	check("VÄLKOMMEN-skylten hänger längst norrut, som i ridhus-inne-31", valk ~= nil and nordligast)
	check("två separata RS Mustang-skyltar, söder om Agria och Hästsportbutik (ridhus-inne-17)",
		#mustang == 2 and agria and hast and hast.y < agria.y
			and mustang[1].y < hast.y and mustang[2].y < hast.y)
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

--[[ SPELABSTRAKTIONER (Senior Re-review 2026-09-03, blocker 2). Sargporten
	för folk till fots är INTE fidelity: ingen bild visar en grind i sargen
	och bredden är vald. Den får därför inte ligga i `ridhus` (fidelity-
	datan) utan i `spelabstraktioner`, märkt som sådan. Testet mäter
	MÄRKNINGEN och att spelet kan använda öppningen — inte att den är
	verklighet. ]]
do
	check("sargporten finns INTE i fidelity-datan `ridhus`", R.port == nil)
	local SA = UBRFKomplex.spelabstraktioner
	local sp = SA and SA.ridhus and SA.ridhus.sargport
	check("sargporten ligger i spelabstraktioner, märkt SPELABSTRAKTION med REFERENCE GAP i fidelity",
		sp ~= nil and sp.klass == "SPELABSTRAKTION" and sp.fidelity == "REFERENCE GAP" and sp.motiv ~= nil)
	if sp then
		local bredd = sp.x1 - sp.x0
		check("spelets sargport är bred nog att gå igenom (spelkrav, inte fidelity)", bredd > 1.5 and bredd < 4,
			string.format("%.1f m bred, vid x %g–%g", bredd, sp.x0, sp.x1))
		check("spelets sargport ligger i banans norra sarg", sp.x0 >= R.bana.x and sp.x1 <= R.bana.x + R.bana.w
			and math.abs(sp.y - (R.bana.y + R.bana.h)) < 0.01)
	end
end

do
	-- Kortändans läktare ligger vid bokstaven C, alltså mitt på en kortsida,
	-- och glasbandet sitter ovanför den. Att den ligger vid RÄTT kortända är
	-- poängen: läggs den vid fel ände hamnar den bakom A i stället för C.
	local K = R.kortanda
	check("kortändans läktare finns", K ~= nil)
	if K then
		--[[ Planen (ridhus-entreplan-utrymning.jpg) lägger bänkblocket vid
			NORRA änden, 7,05–11,5 m från gaveln, mellan banan och entrédelen.
			C står alltså i norr. Förut låg det i söder — en slutledning ur var
			C antogs sitta — och testet mätte den slutledningen. ]]
		check("C-blocket ligger vid norra änden, mot banans norra kant",
			K.vand == "S" and math.abs(K.y0 - (R.bana.y + R.bana.h)) < 0.05,
			string.format("blocket y %.2f–%.2f, banans norra kant %.2f",
				K.y0, K.y1, R.bana.y + R.bana.h))
		check("blocket lämnar entrédelens rum bakom sig",
			K.y1 <= R.langd - 5 and K.y1 > R.langd - R.entre,
			string.format("blocket slutar %.2f, huset %.2f, entrédelen %.1f djup", K.y1, R.langd, R.entre))
		check("den har två trappor upp", #K.trappor == 2, #K.trappor .. " st")
		check("blocket upptar den östra delen av bredden, som planen ritar det",
			(K.x1 - K.x0) > R.bredd * 0.45 and K.x1 > R.bredd * 0.8 and K.x0 > R.bredd * 0.25,
			string.format("x %.1f–%.1f av husets %.1f", K.x0, K.x1, R.bredd))
		--[[ Loppen går LÄNGS gaveln (`ridhus-inne-01`, `IMG_0192-f01/-f02`):
			planens 12,4–15,2 och 16,4–18,9 m från väster, med luft emellan
			för klockväggen, och foten vid mitten — det vänstra stiger mot
			väster, det högra mot öster. ]]
		local tv, to = K.trappor[1], K.trappor[2]
		if tv.x0 > to.x0 then tv, to = to, tv end
		check("trapporna står inne i blocket, med luft emellan för klockan",
			tv.x0 > K.x0 + 0.5 and to.x1 < K.x1 - 0.5 and to.x0 - tv.x1 > 0.8,
			string.format("lopp %.1f–%.1f och %.1f–%.1f i block %.1f–%.1f", tv.x0, tv.x1, to.x0, to.x1, K.x0, K.x1))
		check("trapporna stiger utåt från klockväggen: vänstra foten i öster, högra foten i väster",
			tv.fot == "E" and to.fot == "W")
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
		--[[ Grinden sitter i sargens ÖSTRA långsida, mot stallet. Läktaren
			står i väster enligt planen: gången bryter alltså ingen läktare,
			och sidan mitt emot grinden ska vara läktarens. ]]
		check("grinden sitter på sidan mitt emot läktaren",
			R.sidor ~= nil and R.sidor.laktare == "W",
			"läktaren på " .. tostring(R.sidor and R.sidor.laktare))
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
	local kMitt = S.origo.y + (S.brott[1].y0 + S.brott[1].y1) / 2
	local hMitt = hastgang.rekt.y + hastgang.rekt.h / 2
	check("gången möter stallets tvärkorridor", math.abs(kMitt - hMitt) < 1.5,
		string.format("korridorens mitt y = %.2f, gångens y = %.2f", kMitt, hMitt))
end

do
	--[[ Läktaren är OBRUTEN och löper längs hela banan: planens fem
		parallella linjer går från södra änden upp till entrédelen, på
		västra långsidan. Gapet för hästgången är borta — gången kommer in
		på den andra sidan. ]]
	local L = R.laktare
	check("läktaren har inget gap: hästgången bryter den inte", L.gap == nil)
	check("läktaren är ett stycke", #Geometri.laktarSektioner(L) == 1,
		#Geometri.laktarSektioner(L) .. " sektioner")
	check("läktaren löper längs hela banan",
		L.y0 <= R.bana.y + 0.05 and L.y1 >= R.bana.y + R.bana.h - 0.05,
		string.format("läktare y %.1f–%.1f, bana y %.1f–%.1f", L.y0, L.y1, R.bana.y, R.bana.y + R.bana.h))
	check("entrédelen är planens 11,5 m och banans norra sarg ligger vid dess gräns",
		math.abs(R.entre - 11.5) < 0.01 and math.abs(R.bana.y + R.bana.h - (R.langd - 11.5)) < 0.01,
		string.format("entre %.1f, bana y1 %.2f", R.entre, R.bana.y + R.bana.h))
end

do
	--[[ TRAPPORNA (Product Owner 2026-09-03 17:16; senior review 17:18: de
		två C-trapporna ur C-kortandan-och-kafeet.md). Datan provas här:
		båda C-trapporna finns som STAIR-primitiver härledda ur
		kortanda.trappor, går längs gaveln från översta bänkraden (sockel +
		steg × stegH) till caféplanet, stiger utåt från klockväggen; stegen
		(Geometri.trappsteg) är under 0,2 m och sammanhängande; övre gången
		ligger på caféplanet norr om vägglinjen; allt bär provenance med FOTO
		som källa och VERIFIED_PLAN_OR_PHOTO som confidence.

		Senior review 2026-09-04 04:08 (blocker 1): vägen hallgolvet → nedersta
		bänkraden har INGET foto och får inte ligga i fidelity-datan. Den
		finns bara som spelabstraktion (SPELABSTRAKTIONER.ridhus.bankradSteg),
		utan canon_id/source_id/confidence, och räknas inte in i F02. ]]
	local trappor = {}
	for _, t in ipairs(R.trappor or {}) do trappor[t.id] = t end
	local cv, co = trappor.c_trappa_v, trappor.c_trappa_o
	local K = R.kortanda
	check("båda C-trapporna finns i datan som STAIR-primitiver", cv ~= nil and co ~= nil)
	check("fidelity-datan innehåller BARA de två fotobelagda C-trapporna (inga bänkradssteg)",
		#(R.trappor or {}) == 2 and trappor.bankrad_upp == nil, #(R.trappor or {}) .. " trappor")
	for id, t in pairs(trappor) do
		check(string.format("trappan %s bär confidence VERIFIED_PLAN_OR_PHOTO och en FOTO-källa (ingen PO-verifierad fidelity utan bild)", id),
			t.confidence == "VERIFIED_PLAN_OR_PHOTO" and type(t.source_id) == "string" and t.source_id:find("FOTO:", 1, true) ~= nil
				and t.klass == nil,
			tostring(t.confidence) .. " / " .. tostring(t.source_id))
	end
	local SA = UBRFKomplex.spelabstraktioner
	local bs = SA and SA.ridhus and SA.ridhus.bankradSteg
	check("spelets bänkradssteg ligger i spelabstraktioner, märkta SPELABSTRAKTION med REFERENCE GAP i fidelity",
		bs ~= nil and bs.klass == "SPELABSTRAKTION" and bs.fidelity == "REFERENCE GAP" and type(bs.motiv) == "string" and #bs.motiv > 10)
	check("spelets bänkradssteg bär INGEN kanonprovenance (ingen canon_id/source_id/confidence/primitiv)",
		bs ~= nil and bs.canon_id == nil and bs.source_id == nil and bs.confidence == nil and bs.primitiv == nil)
	if bs and K then
		-- spelkrav (inte fidelity): stegen måste faktiskt ansluta golvet till nedersta raden
		local T = Geometri.trappsteg(bs)
		local ok, forra = true, bs.z0
		for _, st in ipairs(T.steg) do
			if math.abs(st.z - forra) > 0.2 + 1e-6 or st.a1 - st.a0 < 0.2 then ok = false end
			forra = st.z
		end
		check("spelkrav: bänkradsstegen går från golvet (0) till nedersta raden i steg under 0,2 m (inte fidelity)",
			bs.z0 == 0 and math.abs(bs.z1 - ((K.sockelH or 0) + K.stegH)) < 0.01 and ok and math.abs(forra - bs.z1) < 1e-6
				and bs.y0 >= K.y0 - 0.01 and bs.y1 <= K.y1 + 0.01,
			string.format("z %.2f → %.2f, %d steg", bs.z0, bs.z1, T.n))
	end
	if cv and co and K then
		local topp = (K.sockelH or 0) + K.steg * K.stegH
		for _, t in ipairs({ cv, co }) do
			check(string.format("%s går längs gaveln från översta bänkraden (%.2f) till caféplanet (%.2f)", t.id, topp, R.cafe.z0),
				t.axel == "x" and math.abs(t.z0 - topp) < 0.01 and math.abs(t.z1 - R.cafe.z0) < 0.01
					and t.y1 - t.y0 >= 1.0 and math.abs(t.y1 - K.y1) < 0.01,
				string.format("axel %s, z %.2f → %.2f, y %.2f–%.2f", tostring(t.axel), t.z0, t.z1, t.y0, t.y1))
		end
		check("vänstra trappan stiger mot väster, högra mot öster — foten vid klockväggen",
			cv.stiger == "W" and co.stiger == "E" and cv.x1 < co.x0
				and K.klocka ~= nil and K.klocka.x > cv.x1 and K.klocka.x < co.x0,
			string.format("v %.1f–%.1f (%s), o %.1f–%.1f (%s), klocka %.1f", cv.x0, cv.x1, tostring(cv.stiger), co.x0, co.x1, tostring(co.stiger), K.klocka and K.klocka.x or -1))
		check("trapporna följer planens lägen (12,4–15,2 och 16,4–18,9 m från väster, ±0,3)",
			math.abs(cv.x0 - 12.4) < 0.3 and math.abs(cv.x1 - 15.2) < 0.3 and math.abs(co.x0 - 16.4) < 0.3 and math.abs(co.x1 - 18.9) < 0.3)
	end
	for id, t in pairs(trappor) do
		local T = Geometri.trappsteg(t)
		local ok, forra = true, t.z0
		for _, st in ipairs(T.steg) do
			if math.abs(st.z - forra) > 0.2 + 1e-6 or st.a1 - st.a0 < 0.2 then ok = false end
			forra = st.z
		end
		check(string.format("trappan %s har %d steg under 0,2 m som når toppen", id, T.n),
			ok and math.abs(forra - t.z1) < 1e-6, string.format("stig %.3f, djup %.2f", T.stig, T.djup))
		check(string.format("trappan %s bär primitiv STAIR, canon_id, source_id och confidence", id),
			t.primitiv == "STAIR" and t.canon_id ~= nil and t.source_id ~= nil and t.confidence ~= nil)
	end
	local G2 = R.ovreGang
	check("övre gången ligger på caféplanet norr om C-blockets vägglinje och är minst 2 m bred",
		G2 ~= nil and K ~= nil and math.abs(G2.z - R.cafe.z0) < 0.01 and math.abs(G2.y0 - K.y1) < 0.01
			and G2.y1 - G2.y0 >= 2.0 and (cv == nil or (G2.x0 <= cv.x0 and G2.x1 >= co.x1)),
		G2 and string.format("z %.2f, y %.1f–%.1f, x %.1f–%.1f", G2.z, G2.y0, G2.y1, G2.x0, G2.x1) or "saknas")
end

do
	--[[ ENTRÉDELEN — Spatial Canon v2 (references/spatial/UBRF-SPATIAL-CANON-v2.json
		§ buildings.ridhus). Den gamla vägglistan är återkallad; bara
		källspårade WALL/GLASS får finnas, resten är OPEN_AREA. Bara datan
		provas här; bygget och rutten provas i bygge.spec. ]]
	local E = R.entrehall
	check("entrédelen finns i datan", E ~= nil)
	if E then
		local namn = {}
		for _, r in ipairs(E.rum) do namn[r.id] = r end
		check("entrén, receptionen, de två toaletterna och den kryssade rutan (schakt) finns som regioner",
			namn.entre and namn.reception and namn.wc_n1 and namn.wc_n2 and namn.schakt)
		--[[ Blocker 1: rutan är plan-belagd som fotavtryck, funktionen är
			okänd. Datan får inte kalla den hiss och inte sätta någon
			spelarsynlig etikett — regeln "hitta inte på rumsidentitet". ]]
		check("den kryssade rutan är neutral: inget `hiss`-id, ingen etikett",
			namn.hiss == nil and namn.schakt ~= nil and (namn.schakt.label == nil or namn.schakt.label == ""))
		if namn.entre and namn.wc_n1 and namn.wc_n2 then
			check("toaletterna ligger norr om entrén, längs västväggen",
				namn.wc_n1.rekt.y >= namn.entre.rekt.y + namn.entre.rekt.h - 0.01
					and namn.wc_n2.rekt.y >= namn.entre.rekt.y + namn.entre.rekt.h - 0.01
					and namn.wc_n1.rekt.x < 0.01 and namn.wc_n2.rekt.x < 0.01,
				string.format("entré y %.1f–%.1f, WC y %.1f och %.1f",
					namn.entre.rekt.y, namn.entre.rekt.y + namn.entre.rekt.h,
					namn.wc_n1.rekt.y, namn.wc_n2.rekt.y))
			check("toaletterna och schaktet är slutna tills dörrar/funktion är belagda",
				namn.wc_n1.stangt and namn.wc_n2.stangt and namn.schakt.stangt)
		end
		-- Kanonen § 3: rumsmetadata är passiv. Receptionen och entrén är regioner, inte volymer.
		check("SCV2-04: receptionen och entrén är passiva regioner — inget `stangt` ur en etikett",
			namn.reception ~= nil and not namn.reception.stangt and namn.entre ~= nil and not namn.entre.stangt)
		local utanfor = nil
		for _, r in ipairs(E.rum) do
			local k = r.rekt
			if k.x < -0.01 or k.x + k.w > R.bredd + 0.01 or k.y + k.h > R.langd + 0.01 then utanfor = r.id end
		end
		check("entrédelens rum ligger i huset", utanfor == nil, utanfor or "alla innanför")

		--[[ SCV2 — OPEN_AREA ridhus_open_entrance_hall och NO_WALL_ZONE
			ridhus_open_hall_no_room_boxes finns; ingen WALL/GLASS och ingen
			sluten volym skär den öppna ytans inre (SCV2-01-analogen för
			ridhuset); de 14 återkallade segmenten är borta. ]]
		local zon = nil
		for _, z in ipairs(E.oppna or {}) do if z.id == "ridhus_open_entrance_hall" then zon = z end end
		check("OPEN_AREA ridhus_open_entrance_hall finns i datan med PO-källa",
			zon ~= nil and zon.typ == "OPEN_AREA" and zon.source_id ~= nil
				and string.find(zon.source_id, "PO-2026-09-03-RIDHUS-OPEN-01", 1, true) ~= nil and #zon.rekt >= 3)
		local ingen = nil
		for _, z in ipairs(E.ingaVaggar or {}) do if z.tacker == "ridhus_open_entrance_hall" then ingen = z end end
		check("NO_WALL_ZONE täcker den öppna entréhallen och listar det återkallade",
			ingen ~= nil and ingen.typ == "NO_WALL_ZONE" and #ingen.aterkallat >= 14)
		local function skarInre(r)
			if not zon then return false end
			for _, q in ipairs(zon.rekt) do
				local ox = math.min(r.x + r.w, q.x + q.w) - math.max(r.x, q.x)
				local oy = math.min(r.y + r.h, q.y + q.h) - math.max(r.y, q.y)
				if ox > 0.12 and oy > 0.12 then return true end
			end
			return false
		end
		local intrang = {}
		for _, v in ipairs(E.vaggar) do
			local t = (v.tjock or 0.16) / 2
			for _, bit in ipairs(Geometri.vaggBitar(v)) do
				local r = if v.typ == "tvar" then { x = bit.a0, y = v.y - t, w = bit.a1 - bit.a0, h = 2 * t }
					else { x = v.x - t, y = bit.a0, w = 2 * t, h = bit.a1 - bit.a0 }
				if skarInre(r) then table.insert(intrang, v.id) end
			end
		end
		for _, r in ipairs(E.rum) do
			if r.stangt and skarInre(r.rekt) then table.insert(intrang, r.id) end
		end
		check("SCV2-01 (ridhus): ingen vägg, inget glas och ingen sluten volym skär den öppna entréhallen",
			#intrang == 0, #intrang > 0 and table.concat(intrang, ", ") or "hallen är öppen")
		local aterkallade = {}
		if ingen then for _, id in ipairs(ingen.aterkallat) do aterkallade[id] = true end end
		for _, id in ipairs({ "korridor_o", "skap_v", "skap_o", "cell_1", "cell_2", "cell_3", "cell_4",
			"hall_n_v", "hall_n_o", "hall_nv_s", "hall_mitt", "hall_no", "hall_no_s", "ostkorridor_v" }) do
			aterkallade[id] = true
		end
		local kvar = {}
		for _, v in ipairs(E.vaggar) do if aterkallade[v.id] then table.insert(kvar, v.id) end end
		check("den återkallade vägglistan är borta (korridor_o, skåpkorridorens väggar, cellraden, hallens rumslådor, östkorridoren)",
			#kvar == 0, #kvar > 0 and table.concat(kvar, ", ") or "borta")
		-- SCV2-02/04: provenance på varje WALL/GLASS och sluten volym; tillåten confidence.
		local tillat = { PRODUCT_OWNER_VERIFIED = true, VERIFIED_PLAN_OR_PHOTO = true }
		local utan, felTillit = {}, {}
		local function prova(o, id)
			if not (o.primitiv == "WALL" or o.primitiv == "GLASS") or not o.canon_id or not o.source_id or not o.confidence then
				table.insert(utan, id)
			elseif not tillat[o.confidence] then
				table.insert(felTillit, id)
			end
		end
		for _, v in ipairs(E.vaggar) do prova(v, v.id) end
		for _, r in ipairs(E.rum) do if r.stangt then prova(r, r.id) end end
		check("SCV2-02: varje vägg/glas och sluten volym i entrédelen bär primitiv, canon_id, source_id och confidence",
			#utan == 0, #utan > 0 and table.concat(utan, ", ") or "alla har provenance")
		check("SCV2-04: ingen partition i entrédelen vilar på lägre belägg än plan/foto eller PO",
			#felTillit == 0, #felTillit > 0 and table.concat(felTillit, ", ") or "ok")
		-- Receptionen är GLASS (PO-2026-09-03-RIDHUS-GLASS-01), aldrig en opak vägg.
		local glas, opakRec = nil, {}
		for _, v in ipairs(E.vaggar) do
			if v.canon_id == "ridhus_reception_glass" then
				if v.primitiv == "GLASS" then glas = v else table.insert(opakRec, v.id) end
			end
		end
		for _, r in ipairs(E.rum) do
			if r.id == "reception" and r.stangt then table.insert(opakRec, "reception(stangt)") end
		end
		check("receptionens avgränsning är GLASS med PO- och fotokälla, inte en opak vägg",
			glas ~= nil and #opakRec == 0 and string.find(glas.source_id, "RIDHUS-GLASS-01", 1, true) ~= nil
				and (glas.y1 - glas.y0) >= 3.0,
			#opakRec > 0 and ("opakt: " .. table.concat(opakRec, ", ")) or (glas and string.format("glas %.1f m", glas.y1 - glas.y0) or "saknas"))
		--[[ Spelets sargport (SPELABSTRAKTION, inte fidelity) måste hamna
			väster om C-blocket för att rutten entré → bana ska finnas; det
			är ett SPELKRAV på abstraktionen, inte ett påstående om UBRF. ]]
		local sp = UBRFKomplex.spelabstraktioner and UBRFKomplex.spelabstraktioner.ridhus.sargport
		check("spelets sargport (abstraktion) ligger väster om C-blocket så att rutten finns",
			sp ~= nil and sp.x1 <= R.kortanda.x0 + 0.01 and sp.x0 >= R.bana.x - 0.01,
			sp and string.format("port x %.1f–%.1f, block från %.1f", sp.x0, sp.x1, R.kortanda.x0) or "saknas")
		--[[ SCV2-03 i datan: kedjan main_entrance → open_entrance_hall →
			arena_access → physical_riding_area. Huvudentréns innerpunkt
			(fasadens dörr) ligger i OPEN_AREA, sargporten öppnar ur samma
			OPEN_AREA, och ingen vägg/volym i datan står mellan dem. ]]
		local dorr = nil
		for _, d in ipairs(R.dorrar or {}) do if d.id == "ut_ridhus_W_9" then dorr = d end end
		local function iZon(x, y)
			if not zon then return false end
			for _, q in ipairs(zon.rekt) do
				if x >= q.x - 0.01 and x <= q.x + q.w + 0.01 and y >= q.y - 0.01 and y <= q.y + q.h + 0.01 then return true end
			end
			return false
		end
		local kedja = dorr ~= nil and sp ~= nil and iZon(dorr.pos[1], dorr.pos[2]) and iZon((sp.x0 + sp.x1) / 2, sp.y + 0.2)
		local spar = nil
		if kedja then
			local x0, x1 = math.min(dorr.pos[1], (sp.x0 + sp.x1) / 2) - 0.35, math.max(dorr.pos[1], (sp.x0 + sp.x1) / 2) + 0.35
			local y0, y1 = sp.y, dorr.pos[2]
			local function skar(r)
				return r.x < x1 and r.x + r.w > x0 and r.y < y1 and r.y + r.h > y0
			end
			for _, v in ipairs(E.vaggar) do
				local t = (v.tjock or 0.16) / 2
				for _, bit in ipairs(Geometri.vaggBitar(v)) do
					local r = if v.typ == "tvar" then { x = bit.a0, y = v.y - t, w = bit.a1 - bit.a0, h = 2 * t }
						else { x = v.x - t, y = bit.a0, w = 2 * t, h = bit.a1 - bit.a0 }
					if skar(r) then spar = spar or v.id end
				end
			end
			for _, r in ipairs(E.rum) do if r.stangt and skar(r.rekt) then spar = spar or r.id end end
		end
		check("SCV2-03 (data): huvudentrén och sargporten ligger i den öppna hallen och inget står emellan",
			kedja and spar == nil,
			not kedja and "kedjan bruten: dörr eller port utanför OPEN_AREA" or (spar or "fri"))
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

--[[ F02-B — LÄKTARENS RADER I DATAN. Sarg + gångbräda + stegade bänkrader
	(INTERIOR-MATRIS § 2). Regeln mäts, inte talen: raderna stiger inåt,
	ryms på däcket, och den återkallade fronten finns inte i datan. ]]
do
	local L = R.laktare
	local rader = Geometri.laktarRader(L)
	check("läktaren har gångbräda och bänkrader i datan", L.gangbrada ~= nil and L.rader ~= nil and #rader == 3,
		#rader .. " rader")
	local stiger, inuti = true, true
	for i, rad in ipairs(rader) do
		if i > 1 and rad.z <= rader[i - 1].z then stiger = false end
		if rad.in0 < (L.gangbrada and L.gangbrada.djup or 0) - 0.01 or rad.in1 > L.dackDjup + 0.01 then inuti = false end
	end
	check("raderna stiger inåt från gångbrädan", stiger and #rader > 0)
	check("gångbrädan och raderna ryms på däckdjupet", inuti,
		string.format("däck %.2f, sista raden till %.2f", L.dackDjup, rader[#rader] and rader[#rader].in1 or -1))
	check("den återkallade solida fronten finns inte längre i datan",
		L.frontTopp == nil and L.kappH == nil and UBRFKomplex.identitet.ridhus.laktarfront == nil)
	check("de sourcelösa speglarna på y 19/37 finns inte längre i datan", R.speglar == nil)
end

--[[ F02-B — INREDNINGEN. Varje objekt bär källa och klass, har ett unikt
	id, står i sitt rum och har rimliga mått. Regeln "aldrig hitta på" mäts
	som: inga objekt utan källa, inga klasser utanför vokabulären. ]]
do
	local I = UBRFKomplex.inredning
	check("inredningslistan finns för båda husen", I ~= nil and I.stall ~= nil and I.ridhus ~= nil
		and #I.stall > 0 and #I.ridhus > 0)
	if I then
		local klasser = { VERIFIED = true, FOTO = true, DERIVED = true, ASSUMPTION = true }
		local rumRekt = {}
		for _, r in ipairs(UBRFKomplex.stall.klubb.rum) do rumRekt["stall:" .. r.id] = r.rekt end
		for _, r in ipairs(R.entrehall.rum) do rumRekt["ridhus:" .. r.id] = r.rekt end
		rumRekt["ridhus:laktare"] = { x = R.laktare.x0, y = R.laktare.y0, w = R.laktare.dackDjup, h = R.laktare.y1 - R.laktare.y0 }
		rumRekt["ridhus:bana"] = { x = 0, y = R.bana.y, w = R.bredd, h = R.bana.h }
		rumRekt["ridhus:sydzon"] = { x = 0, y = 0, w = R.bredd, h = R.bana.y }
		rumRekt["stall:gangA"] = { x = 0, y = 0, w = UBRFKomplex.stall.bredd, h = UBRFKomplex.stall.klubb.y0 }
		local ids, dubbla, utanfor, felKlass, utanKalla, orimliga = {}, {}, {}, {}, {}, {}
		for _, hus in ipairs({ { "stall", I.stall }, { "ridhus", I.ridhus } }) do
			for _, ob in ipairs(hus[2]) do
				if ids[ob.id] then table.insert(dubbla, ob.id) end
				ids[ob.id] = true
				if not klasser[ob.klass] or (ob.lage and not klasser[ob.lage]) then table.insert(felKlass, ob.id) end
				if not ob.kalla or ob.kalla == "" then table.insert(utanKalla, ob.id) end
				local q = Geometri.inredningRekt(ob)
				local rr = rumRekt[hus[1] .. ":" .. ob.rum]
				if not rr or q.x < rr.x - 0.3 or q.x + q.w > rr.x + rr.w + 0.3 or q.y < rr.y - 0.3 or q.y + q.h > rr.y + rr.h + 0.3 then
					table.insert(utanfor, ob.id .. " (" .. tostring(ob.rum) .. ")")
				end
				local m = ob.matt
				if m.b <= 0 or m.d <= 0 or m.h <= 0 or m.b > 8 or m.d > 3 or m.h > 3 or (ob.z0 or 0) + m.h > 6.5 then
					table.insert(orimliga, ob.id)
				end
			end
		end
		check("inredningens id är unika", #dubbla == 0, table.concat(dubbla, ", "))
		check("inredningens klasser hör till vokabulären", #felKlass == 0, table.concat(felKlass, ", "))
		check("varje inredningsobjekt anger sin källa", #utanKalla == 0, table.concat(utanKalla, ", "))
		check("varje inredningsobjekt står i sitt rum", #utanfor == 0, table.concat(utanfor, ", "))
		check("inredningens mått är rimliga för möbler", #orimliga == 0, table.concat(orimliga, ", "))
		--[[ Det som bilderna kräver ska finnas — och det som saknar bild får
			inte finnas. Pentryt (stall-inne-02) är fotograferat men INTE
			placerbart (runt fönster + valvfönster i ett hörn som fasaden
			inte har i uppehållsrummet): ingen post får heta pentry. ]]
		local krav = { "uppehall_soffa_v", "uppehall_ponny", "teori_whiteboard_1", "sadel_stovelhylla",
			"spegel_B", "spegel_A_v", "laktare_bommar", "skap_v_1", "skap_stovelbank" }
		local saknas = {}
		for _, id in ipairs(krav) do if not ids[id] then table.insert(saknas, id) end end
		check("de belagda objekten finns i listan", #saknas == 0, "saknas: " .. table.concat(saknas, ", "))
		local forbjudna = {}
		for id in pairs(ids) do
			if string.find(id, "pentry", 1, true) or string.find(id, "cafe_", 1, true) or string.find(id, "reception", 1, true) then
				table.insert(forbjudna, id)
			end
		end
		check("rum utan placerbart belägg har ingen inredning (pentry, café, reception)", #forbjudna == 0,
			table.concat(forbjudna, ", "))
	end
end

if fails > 0 then
	print(string.format("\n%d FEL", fails))
	error("geometri.spec: " .. fails .. " fel")
end
print("\nalla gröna")
