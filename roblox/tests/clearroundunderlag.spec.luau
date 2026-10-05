--!nostrict
--[[ B4c SKUGGBEDÖMNINGEN — docs/B4C-COURSE-EVIDENCE-CONSUMER-CONTRACT.md.
	Ren modul, syntetiska försökslistor (samma fält som HinderObservation ger).
	Aldrig officiell. ]]
local fails, total = 0, 0
local function check(name, yes, detalj)
	total += 1
	if not yes then fails += 1 end
	print((if yes then "  OK   " else "  FEL  ") .. name .. (if detalj then "  " .. tostring(detalj) else ""))
end
local U = ClearRoundUnderlag
local BANA = { { id = "bla", riktning = "fram" }, { id = "rod", riktning = "fram" },
	{ id = "bla", riktning = "bak" }, { id = "rod", riktning = "fram" } }
local NRBAS = { bla = 0, rod = 0 }

local tt = 0
local nr = { bla = 0, rod = 0 }
local function f(id, utfall, riktning, over)
	tt += 1
	nr[id] = (nr[id] or 0) + 1
	local x = { hinderId = id, nr = nr[id], tUt = tt, utfall = utfall, riktning = riktning,
		giltighet = "fullstandig", evidensGrund = nil, inSida = riktning or "fram",
		stoppObserverat = false, bakatEfterStopp = false, sidanOm = false, nedslag = "okand" }
	for k, v in pairs(over or {}) do x[k] = v end
	return x
end
local function nollstall() tt = 0; nr = { bla = 0, rod = 0 } end
local function ren(nedslag)
	nollstall()
	return { f("bla", "passage", "fram", { nedslag = nedslag }), f("rod", "passage", "fram", { nedslag = nedslag }),
		f("bla", "passage", "bak", { nedslag = nedslag, inSida = "bak" }), f("rod", "passage", "fram", { nedslag = nedslag }) }
end
local function doms(u, i)
	local t = {}
	for _, h in ipairs(u.steg[i].handelser) do table.insert(t, h.dom .. "/" .. tostring(h.grund)) end
	return table.concat(t, ",")
end

print("\n── 1. Ren bana med dagens bommar: inget officiellt, inte fullständigt ──")
do
	local u = U.bygg(BANA, ren("okand"), NRBAS)
	check("fyra steg passerade, nedslag okand", u.steg[4].passerad and u.steg[1].nedslag == "okand" and #u.steg == 4)
	check("0 olydnader, 4 okända nedslag, fullstandigt=false, officiell=false", u.summa.olydnader == 0
		and u.summa.nedslagOkanda == 4 and u.summa.fullstandigt == false and u.officiell == false)
	check("fryst", table.isfrozen(u) and table.isfrozen(u.steg[1]))
end

print("\n── 2. Fysiskt «nej» överallt, inget stopp: fullständigt — men ALDRIG officiellt ──")
do
	local u = U.bygg(BANA, ren("nej"), NRBAS)
	check("fullstandigt=true, 0 nedslag", u.summa.fullstandigt == true and u.summa.nedslag == 0)
	check("officiell är fortfarande false", u.officiell == false and U.OFFICIELL == false)
end

print("\n── 3. Evidens vid nästa hinder → dom ──")
do
	nollstall()
	local lista = {
		f("bla", "ingen_passage", nil, { inSida = "fram", stoppObserverat = true, bakatEfterStopp = true }),
		f("bla", "sidan_om", nil, { inSida = "fram", sidanOm = true }),
		f("bla", "ingen_passage", nil, { inSida = "fram" }),
		f("bla", "ingen_passage", nil, { inSida = "fram", giltighet = "brott", evidensGrund = "ofullstandigt" }),
		f("bla", "ingen_passage", nil, { inSida = "bak" }),
		f("bla", "passage", "fram", { stoppObserverat = true }),
	}
	local u = U.bygg(BANA, lista, NRBAS)
	check("vägran, utbrytning, okänd ingen_passage, ofullständigt, fel sida, stopp-sedan-passage",
		doms(u, 1) == "vagran/stopp_och_bakat,utbrytning/sidan_om,okand/ingen_passage,okand/ofullstandigt,okand/fel_sida,okand/stopp_sedan_passage",
		doms(u, 1))
	check("steg 1 passerat, summan: 2 olydnader, 4 okända", u.steg[1].passerad and u.summa.olydnader == 2
		and u.summa.olydnaderOkanda == 4, ("%d/%d"):format(u.summa.olydnader, u.summa.olydnaderOkanda))
	check("ett stopp ENSAMT (utan bakåt) ger aldrig vägran", not string.find(doms(u, 1), "vagran/stopp_sedan", 1, true))
end

print("\n── 4. Försök vid ett annat hinder dömer den inte ──")
do
	nollstall()
	local lista = { f("rod", "sidan_om", nil, { sidanOm = true }), f("rod", "ingen_passage", nil,
		{ stoppObserverat = true, bakatEfterStopp = true }), f("bla", "passage", "fram") }
	local u = U.bygg(BANA, lista, NRBAS)
	check("inga händelser vid rött när blått är nästa; steg 1 ren", #u.steg[1].handelser == 1
		and u.steg[1].handelser[1].dom == "ingen" and #u.steg[2].handelser == 0 and u.summa.olydnader == 0, doms(u, 1))
end

print("\n── 5. vantar räknas som okand; ja räknas ──")
do
	nollstall()
	local lista = { f("bla", "passage", "fram", { nedslag = "ja" }), f("rod", "passage", "fram", { nedslag = "vantar" }) }
	local u = U.bygg(BANA, lista, NRBAS)
	check("steg 1 ja, steg 2 okand (vantar)", u.steg[1].nedslag == "ja" and u.steg[2].nedslag == "okand"
		and u.summa.nedslag == 1 and u.summa.nedslagOkanda == 1)
end

print("\n── 6. Försök före startlinjen och öppna försök ignoreras ──")
do
	nollstall()
	local fore = f("bla", "sidan_om", nil, { sidanOm = true })
	local oppen = f("bla", "pagar", nil, { giltighet = "pagar", sidanOm = true })
	local u = U.bygg(BANA, { fore, oppen }, { bla = 1, rod = 0 })
	check("inga händelser: nr ≤ nrBas och «pagar» räknas inte", #u.steg[1].handelser == 0 and u.summa.olydnader == 0)
	check("felaktig indata ger nil", U.bygg(nil, {}, {}) == nil and U.bygg(BANA, nil, {}) == nil)
end

print("\n── 7. Passage i fel riktning flyttar inte pekaren ──")
do
	nollstall()
	local u = U.bygg(BANA, { f("bla", "passage", "bak", { inSida = "bak" }) }, NRBAS)
	check("steg 1 inte passerat, domen okand/fel_sida", not u.steg[1].passerad and doms(u, 1) == "okand/fel_sida", doms(u, 1))
end

if fails > 0 then error(("%d mätning(ar) föll."):format(fails), 0) end
print(string.format("\nclearroundunderlag.spec: %d prov, alla gröna", total))
