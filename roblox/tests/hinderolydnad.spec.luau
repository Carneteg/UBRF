--!nostrict
--[[ B4b OLYDNAD PER HINDERFÖRSÖK — docs/B4B-DISOBEDIENCE-CLASSIFIER-CONTRACT.md.
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
	return f and ("%s | %s/%s in=%s tStopp=%s"):format(f.utfall, f.olydnad, tostring(f.olydnadGrund),
		tostring(f.inSida), tostring(f.tStopp)) or "inget försök"
end

print("\n── 1. Utbrytning (4.1): planet korsas vid sidan av bommen ──")
do
	ny("utbrytning", 5, -9)
	till(5, 8)
	local f = forsok()
	check("utbrytning / sidan_om, inridning «fram»", f and f.utfall == "sidan_om" and f.olydnad == "utbrytning"
		and f.olydnadGrund == "sidan_om" and f.inSida == "fram", fmt(f))
end

print("\n── 2. Vägran (3.1): stopp framför, sedan bakåt, lämnar zonen ──")
do
	ny("vagran")
	till(0, -2)
	local tFore = t
	sta(3)
	till(0, -5)
	till(0, -9)
	local f = forsok()
	check("vägran / stopp_och_bakat", f and f.utfall == "ingen_passage" and f.olydnad == "vagran"
		and f.olydnadGrund == "stopp_och_bakat", fmt(f))
	check("tStopp är första stoppsegmentet", f.tStopp ~= nil and math.abs(f.tStopp - (tFore + DT)) < 1e-9, tostring(f.tStopp))
end

print("\n── 3. Vägran, sedan hopp i samma försök ──")
do
	ny("vagranHopp")
	till(0, -2); sta(2); till(0, -4); till(0, 8)
	local f = forsok()
	check("utfallet är passage (oförändrat), olydnaden vägran", f and f.utfall == "passage" and f.riktning == "fram"
		and f.olydnad == "vagran", fmt(f))
end

print("\n── 4. Stopp, sedan hopp utan att backa: okänt (3.1 mot 3.5) ──")
do
	ny("stoppHopp")
	till(0, -2); sta(3); till(0, 8)
	local f = forsok()
	check("okand / stopp_sedan_passage, aldrig vägran", f and f.utfall == "passage" and f.olydnad == "okand"
		and f.olydnadGrund == "stopp_sedan_passage", fmt(f))
end

print("\n── 5. Passage utan stopp ──")
do
	ny("ren")
	till(0, 8)
	local f = forsok()
	check("ingen / passage_utan_stopp", f and f.olydnad == "ingen" and f.olydnadGrund == "passage_utan_stopp", fmt(f))
	ny("renBak", 0, 9)
	till(0, -8)
	f = forsok()
	check("från andra hållet: inridning «bak», riktning «bak»", f and f.inSida == "bak" and f.riktning == "bak"
		and f.olydnad == "ingen", fmt(f))
end

print("\n── 6. Ingen passage: utan stopp okänt; stopp utan bakåt okänt ──")
do
	ny("vek")
	till(0, -2); till(12, -2)
	local f = forsok()
	check("vek av utan observerat stopp: okand / ingen_passage", f and f.utfall == "ingen_passage"
		and f.olydnad == "okand" and f.olydnadGrund == "ingen_passage", fmt(f))
	ny("stodKvar")
	till(0, -2); sta(4); till(12, -2)
	f = forsok()
	check("stopp, sedan i sidled ut utan bakåt: okand / stopp_utan_bakat", f and f.olydnad == "okand"
		and f.olydnadGrund == "stopp_utan_bakat", fmt(f))
end

print("\n── 7. Inbromsning (över stoppgränsen) och bakåt: ingen vägran ──")
do
	ny("inbromsning")
	till(0, -2)
	till(0, -1.8, 0.05) -- 0,5 studs/s: långsamt, men inget stopp
	till(0, -9)
	local f = forsok()
	check("ingen vägran utan stopp (okand / ingen_passage)", f and f.olydnad == "okand"
		and f.olydnadGrund == "ingen_passage" and f.tStopp == nil, fmt(f))
end

print("\n── 8. Bakåt mindre än toleransen: ingen vägran ──")
do
	ny("litenBak")
	till(0, -2); sta(2); till(0, -2.5, 0.5); sta(1); till(0, 8)
	local f = forsok()
	check("stopp + litet steg bakåt + hopp: okand / stopp_sedan_passage", f and f.olydnad == "okand"
		and f.olydnadGrund == "stopp_sedan_passage", fmt(f))
end

print("\n── 9. Stopp EFTER korsningen räknas inte ──")
do
	ny("stoppEfter")
	till(0, 2); sta(3); till(0, 8)
	local f = forsok()
	check("ingen / passage_utan_stopp, inget tStopp", f and f.olydnad == "ingen" and f.tStopp == nil, fmt(f))
end

print("\n── 10. Brott mitt i försöket ──")
do
	ny("brott")
	till(0, -2); sta(2); till(0, -5)
	HO.brott(ritt, t)
	local f = forsok()
	check("okand / ofullstandigt, även efter stopp och bakåt", f and f.olydnad == "okand"
		and f.olydnadGrund == "ofullstandigt", fmt(f))
end

print("\n── 11. Befintliga fält oförändrade, bilden utan privata nycklar ──")
do
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
