--!nostrict
--[[ B4b R1 EVIDENS FÖR OLYDNAD PER HINDERFÖRSÖK — docs/B4B-DISOBEDIENCE-CLASSIFIER-CONTRACT.md (R1).
	Bara neutral evidens: observationslagret dömer aldrig vägran eller utbrytning.
	Källa: SvRF TR III 2025 moment 385 (references/rules/TR-III-2025-hoppning-A-clear-round.md).

	MODULKONTRAKT, minimal bänk: bara HinderObservation. Provet bygger en bom
	(längs x, planet z = 0) och matar segment med exakta lägen och ritt-tid:
	0,1 s per segment. Farten är provets egen — att verkliga stopp och
	fartprofiler ser ut så här är NOT_TESTED (Studio). ]]
local fails, total = 0, 0
local function check(name, yes, detalj)
	total += 1
	if not yes then fails += 1 end
	print((if yes then "  OK   " else "  FEL  ") .. name .. (if detalj then "  " .. tostring(detalj) else ""))
end
local vec = Vector3.new
local HO = HinderObservation
local HALV = vec(1, 1, 2)
local DT = 0.1

local ritt, t, nu
local function ny(namn, x, z)
	HO._glomForProv()
	local p = Instance.new("Part")
	p.Size = vec(8, 0.3, 0.3)
	local cf = CFrame.new(0, 1.5, 0)
	p.CFrame = cf; p.Position = cf.Position
	p.Anchored = true; p.CanCollide = false
	p:SetAttribute("HinderId", "a")
	p.Parent = workspace
	assert(HO.registrera(p))
	ritt, t, nu = "ritt_" .. namn, 0, { x = x or 0, z = z or -9 }
	assert(HO.starta(ritt, "h", 1))
	-- Ett första segment på plats (ger rittens första tid; ingen fart räknas för det).
	t += DT
	HO.segment(ritt, vec(nu.x, 2.5, nu.z), vec(nu.x, 2.5, nu.z), t, "mark", HALV)
end
local function steg(x, z)
	t += DT
	HO.segment(ritt, vec(nu.x, 2.5, nu.z), vec(x, 2.5, z), t, "mark", HALV)
	nu = { x = x, z = z }
end
-- Rakt till (x, z) med högst `d` studs per segment (d = 1 → 10 studs/s).
local function till(x, z, d)
	d = d or 1
	local n = math.max(1, math.ceil(math.sqrt((x - nu.x) ^ 2 + (z - nu.z) ^ 2) / d))
	local x0, z0 = nu.x, nu.z
	for i = 1, n do steg(x0 + (x - x0) * i / n, z0 + (z - z0) * i / n) end
end
local function sta(n) for _ = 1, n do steg(nu.x, nu.z) end end
local function forsok()
	local b = HO.ogonblick(ritt)
	return b and b.forsok[#b.forsok] or nil
end
local function fmt(f)
	return f and ("%s | stopp=%s bakat=%s sidanOm=%s in=%s tStopp=%s grund=%s"):format(f.utfall,
		tostring(f.stoppObserverat), tostring(f.bakatEfterStopp), tostring(f.sidanOm), tostring(f.inSida),
		tostring(f.tStopp), tostring(f.evidensGrund)) or "inget försök"
end
local function ev(f, stopp, bakat, sidan)
	return f ~= nil and f.stoppObserverat == stopp and f.bakatEfterStopp == bakat and f.sidanOm == sidan
end
-- Inget domslut någonstans i bilden: inga domfält, inga domvärden.
local DOMVARDEN = { vagran = true, utbrytning = true, ingen = true }
local function domfri(v, djup)
	djup = djup or 0
	if djup > 8 then return true end
	if type(v) == "string" then return not DOMVARDEN[v] end
	if type(v) ~= "table" then return true end
	for k, x in pairs(v) do
		if k == "olydnad" or k == "olydnadGrund" then return false end
		if not domfri(x, djup + 1) then return false end
	end
	return true
end

print("\n── 1. Vid sidan om: bara evidensen sidanOm (ingen «utbrytning») ──")
do
	ny("sidan", 5, -9)
	till(5, 8)
	local f = forsok()
	check("sidan_om: sidanOm=true, inget stopp, inridning «fram»", f and f.utfall == "sidan_om"
		and ev(f, false, false, true) and f.inSida == "fram" and f.evidensGrund == nil, fmt(f))
end

print("\n── 2. Stopp framför, bakåt, ut ur zonen: evidens, ingen «vagran» ──")
do
	ny("stoppBak")
	till(0, -2)
	local tFore = t
	sta(3)
	till(0, -5)
	till(0, -9)
	local f = forsok()
	check("stoppObserverat och bakatEfterStopp, utfall ingen_passage", f and f.utfall == "ingen_passage"
		and ev(f, true, true, false), fmt(f))
	check("tStopp är första stoppsegmentet", f.tStopp ~= nil and math.abs(f.tStopp - (tFore + DT)) < 1e-9, tostring(f.tStopp))
end

print("\n── 3. Stopp, bakåt, sedan hopp i samma försök ──")
do
	ny("stoppBakHopp")
	till(0, -2); sta(2); till(0, -4); till(0, 8)
	local f = forsok()
	check("utfall passage/fram oförändrat, evidensen stopp + bakåt", f and f.utfall == "passage" and f.riktning == "fram"
		and ev(f, true, true, false), fmt(f))
end

print("\n── 4. Stopp, sedan hopp utan att backa ──")
do
	ny("stoppHopp")
	till(0, -2); sta(3); till(0, 8)
	local f = forsok()
	check("stopp=true, bakat=false, passage", f and f.utfall == "passage" and ev(f, true, false, false), fmt(f))
end

print("\n── 5. Passage utan stopp, åt båda hållen ──")
do
	ny("ren")
	till(0, 8)
	local f = forsok()
	check("ingen evidens för stopp, bakåt eller sidan om", f and f.utfall == "passage" and ev(f, false, false, false)
		and f.evidensGrund == nil, fmt(f))
	ny("renBak", 0, 9)
	till(0, -8)
	f = forsok()
	check("från andra hållet: inSida «bak», riktning «bak»", f and f.inSida == "bak" and f.riktning == "bak"
		and ev(f, false, false, false), fmt(f))
end

print("\n── 6. Ingen passage: vek av utan stopp; stopp utan bakåt ──")
do
	ny("vek")
	till(0, -2); till(12, -2)
	local f = forsok()
	check("vek av: ingen_passage, inget stopp", f and f.utfall == "ingen_passage" and ev(f, false, false, false), fmt(f))
	ny("stodKvar")
	till(0, -2); sta(4); till(12, -2)
	f = forsok()
	check("stopp, sidled ut: stopp=true, bakat=false", f and f.utfall == "ingen_passage" and ev(f, true, false, false), fmt(f))
end

print("\n── 7. Inbromsning över stoppgränsen: inget stopp ──")
do
	ny("inbromsning")
	till(0, -2)
	till(0, -1.8, 0.05) -- 0,5 studs/s
	till(0, -9)
	local f = forsok()
	check("stopp=false, bakat=false, inget tStopp", f and ev(f, false, false, false) and f.tStopp == nil, fmt(f))
end

print("\n── 8. Bakåt mindre än toleransen ──")
do
	ny("litenBak")
	till(0, -2); sta(2); till(0, -2.5, 0.5); sta(1); till(0, 8)
	local f = forsok()
	check("stopp=true, bakat=false", f and ev(f, true, false, false), fmt(f))
end

print("\n── 9. Stopp EFTER korsningen räknas inte ──")
do
	ny("stoppEfter")
	till(0, 2); sta(3); till(0, 8)
	local f = forsok()
	check("stopp=false efter korsningen, inget tStopp", f and ev(f, false, false, false) and f.tStopp == nil, fmt(f))
end

print("\n── 9b. Över, tillbaka över till inridningssidan, stopp där: räknas inte ──")
do
	ny("overOchTillbaka")
	till(0, 3); till(0, -2); sta(3); till(0, -9)
	local f = forsok()
	check("stopp EFTER en korsning (fast på inridningssidan) ger inget stoppObserverat", f and f.utfall == "passage"
		and f.stoppObserverat == false and f.tStopp == nil, fmt(f))
end

print("\n── 10. Sidan om, sedan tillbaka och över innanför: sidanOm står kvar ──")
do
	ny("sidanSedanOver", 5, -9)
	till(5, 2); till(0, 2); till(0, -4); till(0, -9)
	local f = forsok()
	check("utfall passage (bak), sidanOm=true", f and f.utfall == "passage" and f.sidanOm == true, fmt(f))
end

print("\n── 11. Brott mitt i försöket ──")
do
	ny("brott")
	till(0, -2); sta(2); till(0, -5)
	HO.brott(ritt, t)
	local f = forsok()
	check("evidensGrund «ofullstandigt», den observerade evidensen redovisas som den var", f
		and f.evidensGrund == "ofullstandigt" and ev(f, true, true, false), fmt(f))
end

print("\n── 12. Ingen dom i observationslagret; befintliga fält oförändrade ──")
do
	local alla = {}
	for _, fall in ipairs({ { "d1", 5, -9, function() till(5, 8) end },
		{ "d2", 0, -9, function() till(0, -2); sta(3); till(0, -5); till(0, -9) end },
		{ "d3", 0, -9, function() till(0, 8) end } }) do
		ny(fall[1], fall[2], fall[3]); fall[4]()
		table.insert(alla, HO.ogonblick(ritt))
	end
	local okAlla = true
	for _, b in ipairs(alla) do if not domfri(b) then okAlla = false end end
	check("inga fält olydnad/olydnadGrund och inga värden vagran/utbrytning/ingen i någon bild", okAlla)
	ny("falt")
	till(0, -2); sta(2); till(0, -4); till(0, 8)
	local f = forsok()
	local privata = 0
	for k in pairs(f) do if string.sub(k, 1, 1) == "_" then privata += 1 end end
	check("nedslag som förut (okand / bom_ej_fysisk), rivning false, fryst, inga privata",
		f.nedslag == "okand" and f.nedslagGrund == "bom_ej_fysisk" and f.rivning == false
		and table.isfrozen(f) and privata == 0, tostring(privata))
end

if fails > 0 then error(("%d mätning(ar) föll."):format(fails), 0) end
print(string.format("\nhinderolydnad.spec: %d prov, alla gröna", total))
