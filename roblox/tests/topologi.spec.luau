--!nostrict
--[[
	BUILDING_TOPOLOGY_TRAVERSAL_GATE

	Bindande arbetsorder på #162 efter Tobias tredje Studio-test. Fem fynd,
	och ordern är tydlig med att de inte är fem dörrfixar:

	  1  en entré/öppning leder rakt in i ett BÅS
	  2  en gate leder till en vägg / dead end
	  3  en öppning mot ridhuset leder inte till faktisk traversal
	  5  ytterligare en dörr går inte att använda för att komma in

	── VAD SOM ÄR NYTT MOT `varldskoherens.spec` ──────────────────────────

	Den grinden mäter att en dörr går att GÅ IGENOM. Den säger ingenting om
	VAR man hamnar. En dörr från gårdsplanen rakt in i en box är
	passerbar — och fel.

	Här mäts därför topologin som en GRAF: varje portal får sina två zoner
	lästa ur den byggda världen, och kontrakten handlar om zonerna.

	    stallets ytterentré  →  en GÅNG, aldrig en box
	    varje portal         →  två OLIKA, kända zoner
	    ingen portal         →  en sida utan zon (vägg/tomrum)

	Zonerna kommer ur källdatan, inte ur bygget: `S.gangytor` är gångarna,
	`S.rader` × `S.fack` är boxarna, `R.bana` är ridbanan, `R.entre` är
	entrédelen, hästgången är sin egen byggnad. Ett prov som läser zoner ur
	det byggda hade inte kunnat se en portal som landar fel — den hade
	definierat "rätt" som "dit den råkar leda".

	Kör: python3 roblox/tests/build.py tests/topologi.spec.luau
	     && luau roblox/tests/.build/topologi.spec.luau
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
local function matning(namn, detalj)
	print(string.format("  mät  %s%s", namn, detalj and ("  " .. detalj) or ""))
end

local M = BuildKit.M
local G = UBRFKomplex
local modell = workspace:FindFirstChild("Anläggning"):FindFirstChild("UBRF")
local bas = modell.PrimaryPart.CFrame

--[[ ══ ZONERNA, UR KÄLLDATAN ════════════════════════════════════════════ ]]
local zoner: { { id: string, sort: string, x0: number, x1: number, y0: number, y1: number } } = {}
local function zon(id, sort, x0, y0, w, h)
	table.insert(zoner, { id = id, sort = sort, x0 = x0, x1 = x0 + w, y0 = y0, y1 = y0 + h })
end

local S, R = G.stall, G.ridhus
local So, Ro = S.origo, R.origo

--[[ Gångarna och servicezonerna i stallet — `S.gangytor` är samma lista
	bygget lägger sina gångytor av. ]]
for i, g in ipairs(S.gangytor or {}) do
	zon(("stall.gang.%d"):format(i), "gang", So.x + g.x, So.y + g.y, g.w, g.h)
end

--[[ Boxarna. Raden ger djup och åt vilket håll den vetter; facken ger
	spannen längs raden. Samma tal `Stallet.box` räknar ur. ]]
for _, rad in ipairs(S.rader or {}) do
	local fack = (S.fack or {})[rad.id] or {}
	for n, f in ipairs(fack) do
		--[[ Radens KROPP är [x0, x0 + djup]; `vetter` säger bara vilken sida
			fronten sitter på. Samma tolkning som `byggBoxrader` bygger
			efter. Första versionen här läste `vetter` som riktning och lade
			halva boxarna i gången — vilket är exakt det fel provet sedan
			hittade i `Stallet.box`. ]]
		zon(("stall.box.%s.%d"):format(rad.id, n), "box",
			So.x + rad.x0, So.y + f.y0, rad.djup, f.y1 - f.y0)
	end
end

--[[ Ridhuset: banan och entrédelen. Entrédelen är hallens norra ände,
	`R.entre` meter djup. ]]
zon("ridhus.bana", "bana", Ro.x + R.bana.x, Ro.y + R.bana.y, R.bana.w, R.bana.h)
zon("ridhus.entre", "entre", Ro.x, Ro.y + R.langd - R.entre, R.bredd, R.entre)

--[[ Hästgången är en egen byggnad i datan. ]]
for _, b in ipairs(G.byggnader) do
	if b.id == "hastgang" then
		zon("hastgang", "gang", b.rekt.x, b.rekt.y, b.rekt.w, b.rekt.h)
	end
end

--[[ Gården mellan husen: ytan mellan ridhusets östra vägg och stallets
	västra, i deras gemensamma spann. Härledd, inte skriven. ]]
do
	local rh, st = nil, nil
	for _, b in ipairs(G.byggnader) do
		if b.id == "ridhus" then rh = b.rekt elseif b.id == "stall" then st = b.rekt end
	end
	if rh and st then
		local x0 = rh.x + rh.w
		local x1 = st.x
		local y0 = math.max(rh.y, st.y)
		local y1 = math.min(rh.y + rh.h, st.y + st.h)
		if x1 > x0 and y1 > y0 then zon("gard", "gard", x0, y0, x1 - x0, y1 - y0) end
	end
end

print(("\nZoner ur källdatan: %d"):format(#zoner))
do
	local per = {}
	for _, z in ipairs(zoner) do per[z.sort] = (per[z.sort] or 0) + 1 end
	local rader = {}
	for k, v in pairs(per) do table.insert(rader, ("%s×%d"):format(k, v)) end
	table.sort(rader)
	matning("fördelning", table.concat(rader, " · "))
end

--[[ Vilken zon ligger punkten i? Byggnadernas fotavtryck används som
	fallback så att "inne i ett hus men i ingen känd zon" går att skilja
	från "utomhus". ]]
local function zonFor(x, y): (string, string)
	for _, z in ipairs(zoner) do
		if x >= z.x0 and x <= z.x1 and y >= z.y0 and y <= z.y1 then
			return z.id, z.sort
		end
	end
	for _, b in ipairs(G.byggnader) do
		local r = b.rekt
		if x >= r.x and x <= r.x + r.w and y >= r.y and y <= r.y + r.h then
			return ("%s.okand"):format(b.id), "okand"
		end
	end
	return "utomhus", "utomhus"
end

--[[ ══ PORTALERNA ════════════════════════════════════════════════════════ ]]
print("\nPortalerna och deras två zoner")

local UT = 0.9
local portaler = {}
for _, d in ipairs(modell:GetDescendants()) do
	if d:GetAttribute("UBRFDorr") == true then
		local cx, cz = BuildKit.tomtkoord(bas, d.CFrame.Position)
		local along = d:GetAttribute("Langs")
		local utat = d:GetAttribute("Utat") or 1
		local nx, nz = 0, 0
		if along == "X" then nz = utat else nx = utat end
		local uz, us = zonFor(cx + nx * UT, cz + nz * UT)
		local iz, is = zonFor(cx - nx * UT, cz - nz * UT)
		table.insert(portaler, {
			del = d,
			id = ("%s %s %s"):format(tostring(d:GetAttribute("Byggnad")),
				tostring(d:GetAttribute("Sida")), tostring(d:GetAttribute("Oppningstyp"))),
			hus = tostring(d:GetAttribute("Byggnad")),
			sida = tostring(d:GetAttribute("Sida")),
			typ = tostring(d:GetAttribute("Oppningstyp")),
			ute = uz, uteSort = us, inne = iz, inneSort = is,
		})
	end
end
check("det finns portaler att mäta", #portaler > 0, ("%d portaler"):format(#portaler))

for _, pt in ipairs(portaler) do
	matning(("%-26s"):format(pt.id), ("%s  ⟷  %s"):format(pt.ute, pt.inne))
end

--[[ ── KONTRAKT 1: INGEN PORTAL LANDAR I ETT BÅS ────────────────────────
	Ordern, fynd 1: "Entré/öppning leder direkt in i ett bås. Det ska mynna
	i stallgången, inte i en box." Det gäller varje FASADöppning: en
	ytterdörr är husets entré, och en entré till ett bås är ingen entré. ]]
do
	local fel = {}
	for _, pt in ipairs(portaler) do
		if pt.uteSort == "box" or pt.inneSort == "box" then
			table.insert(fel, ("%s → %s/%s"):format(pt.id, pt.ute, pt.inne))
		end
	end
	check("ingen fasadportal mynnar i ett bås",
		#fel == 0, #fel == 0 and ("%d portaler"):format(#portaler)
			or table.concat(fel, " · "))
end

--[[ ── KONTRAKT 2: STALLETS YTTERENTRÉER MYNNAR I EN GÅNG ───────────────
	Positivt formulerat, inte bara "inte i en box": en ytterdörr i stallet
	ska leda in i gången eller klubbdelens gångyta. ]]
do
	local fel, funna = {}, 0
	for _, pt in ipairs(portaler) do
		if pt.hus == "stall" then
			funna += 1
			local inne = if pt.inneSort == "utomhus" then pt.uteSort else pt.inneSort
			if inne ~= "gang" then
				table.insert(fel, ("%s → %s"):format(pt.id, inne))
			end
		end
	end
	check("varje ytterdörr i stallet mynnar i en gång",
		funna > 0 and #fel == 0,
		#fel == 0 and ("%d dörrar"):format(funna) or table.concat(fel, " · "))
end

--[[ ── KONTRAKT 3: EN PORTAL FÖRBINDER TVÅ OLIKA ZONER ──────────────────
	Ordern, fynd 2 och 3: en gate som leder till en vägg, och en öppning
	som inte leder till traversal. En portal vars båda sidor ligger i
	SAMMA zon förbinder ingenting, och en sida utan känd zon inne i ett
	hus är precis "vägg/dead end". ]]
do
	local samma, okand = {}, {}
	for _, pt in ipairs(portaler) do
		if pt.ute == pt.inne then
			table.insert(samma, ("%s (%s)"):format(pt.id, pt.ute))
		end
		if pt.uteSort == "okand" or pt.inneSort == "okand" then
			table.insert(okand, ("%s → %s/%s"):format(pt.id, pt.ute, pt.inne))
		end
	end
	check("varje portal förbinder TVÅ olika zoner",
		#samma == 0, #samma == 0 and "inga" or table.concat(samma, " · "))
	matning("portaler med en sida i en ännu odefinierad zon",
		#okand == 0 and "inga" or table.concat(okand, " · "))
end

--[[ ══ HÄSTARNA STÅR I BOXAR, INTE I GÅNGEN ════════════════════════════

	Ordern (processändringen 05:42, punkt 5): "hästspel-build utan minst en
	fysisk häst i avsett stallområde → RED". Här mäts det strängare: VARJE
	häst ska stå i en BOXZON.

	Det är den frågan som hittade felet. `varldskoherens` frågade om hästen
	står nära `box.varld` — och det är att jämföra ett tal med sig självt.
	Zonfrågan är en annan fråga, och svaret var att sexton av trettiotre
	stod i stallgången. ]]
print("\nHästarna — i box, inte i gång")

HastRigg.start()

do
	local iGang, utanZon, iBox = {}, {}, 0
	for _, m in ipairs(game:GetService("CollectionService"):GetTagged("Horse")) do
		local rot = (m :: any).PrimaryPart or m:FindFirstChild("BodyCollider")
		if rot then
			local x, y = BuildKit.tomtkoord(bas, rot.CFrame.Position)
			local id, sort = zonFor(x, y)
			if sort == "box" then
				iBox += 1
			elseif sort == "gang" then
				table.insert(iGang, ("%s i %s"):format(tostring(m:GetAttribute("HorseId")), id))
			else
				table.insert(utanZon, ("%s i %s"):format(tostring(m:GetAttribute("HorseId")), id))
			end
		end
	end
	check("ingen häst står i en gång",
		#iGang == 0,
		#iGang == 0 and ("%d hästar i box"):format(iBox)
			or ("%d i gången: %s"):format(#iGang, table.concat(iGang, " · ")))
	check("och varje häst står i en boxzon",
		#utanZon == 0 and iBox > 0,
		#utanZon == 0 and ("%d av %d"):format(iBox, iBox + #iGang + #utanZon)
			or table.concat(utanZon, " · "))
end

--[[ ══ MUTATIONERNA ══════════════════════════════════════════════════════
	Ordern, punkt C. Var och en ska ge RÖTT. ]]
print("\nMutationer — varje topologiregel ska gå att fälla")

local function zonerFor(pt)
	local cx, cz = BuildKit.tomtkoord(bas, pt.del.CFrame.Position)
	local along = pt.del:GetAttribute("Langs")
	local utat = pt.del:GetAttribute("Utat") or 1
	local nx, nz = 0, 0
	if along == "X" then nz = utat else nx = utat end
	local uz, us = zonFor(cx + nx * UT, cz + nz * UT)
	local iz, is = zonFor(cx - nx * UT, cz - nz * UT)
	return uz, us, iz, is
end

--[[ MT1: flytta stallentréns MÅL till en box — här görs det genom att
	flytta boxzonen så att den täcker punkten innanför dörren. Effekten är
	densamma och den mäter samma regel: entrén mynnar i ett bås. ]]
do
	local entre = nil
	for _, pt in ipairs(portaler) do
		if pt.hus == "stall" and pt.typ == "dorrgul" and pt.sida == "N" then entre = pt end
	end
	if entre then
		local cx, cz = BuildKit.tomtkoord(bas, entre.del.CFrame.Position)
		local along = entre.del:GetAttribute("Langs")
		local utat = entre.del:GetAttribute("Utat") or 1
		local px = cx - (if along == "Z" then utat * UT else 0)
		local pz = cz - (if along == "X" then utat * UT else 0)
		table.insert(zoner, 1, { id = "MUTATION.box", sort = "box",
			x0 = px - 1, x1 = px + 1, y0 = pz - 1, y1 = pz + 1 })
		local _, us, _, is = zonerFor(entre)
		check("MT1: en entré som mynnar i ett bås fälls",
			us == "box" or is == "box",
			("%s / %s"):format(us, is))
		table.remove(zoner, 1)
	end
end

--[[ MT2: låt en portals båda sidor ligga i samma zon — en portal som
	förbinder ingenting. ]]
do
	local pt = portaler[1]
	if pt then
		table.insert(zoner, 1, { id = "MUTATION.allt", sort = "gang",
			x0 = -1e6, x1 = 1e6, y0 = -1e6, y1 = 1e6 })
		local uz, _, iz = zonerFor(pt)
		check("MT2: en portal med samma zon på båda sidor fälls",
			uz == iz, ("%s ⟷ %s"):format(uz, iz))
		table.remove(zoner, 1)
	end
end

--[[ MT3: ta bort en kritisk portal helt. ]]
do
	local innan = #portaler
	local pt = nil
	for _, q in ipairs(portaler) do
		if q.hus == "stall" and q.typ == "dorrgul" and q.sida == "N" then pt = q end
	end
	if pt then
		pt.del:SetAttribute("UBRFDorr", nil)
		local kvar = 0
		for _, d in ipairs(modell:GetDescendants()) do
			if d:GetAttribute("UBRFDorr") == true then kvar += 1 end
		end
		check("MT3: en borttagen kritisk portal syns i portalräkningen",
			kvar < innan, ("%d kvar av %d"):format(kvar, innan))
		pt.del:SetAttribute("UBRFDorr", true)
	end
end

if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	print("BUILDING_TOPOLOGY_TRAVERSAL_GATE: FAIL")
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error("topologi.spec: " .. fails .. " fel")
end
print("\nBUILDING_TOPOLOGY_TRAVERSAL_GATE: alla gröna")
