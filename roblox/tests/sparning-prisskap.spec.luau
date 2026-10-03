--!nostrict
--[[ D4a PRISGRUNDEN — docs/D4A-PRIZE-PERSISTENCE-CONTRACT.md.

	Produktionsmodulerna `Sparning` och `SparService` mot den stubbade
	`DataStoreService` (`__datastore`). Mäter kvittonyckeln, den BEKRÄFTADE
	rätten (D4-RÄTT: bara det som ligger i lagret, ur en lyckad läsning eller
	en committad skrivning) och prisskåpets läsmodell. Inert: ingen
	utdelning, ingen UI. EVIDENSNIVÅ: BANK_ONLY. ]]
local fails, total = 0, 0
local function check(namn, villkor, detalj)
	total += 1
	if not villkor then fails += 1 end
	print((if villkor then "  OK   " else "  FEL  ") .. namn .. (if detalj then "  " .. tostring(detalj) else ""))
end
local function antal(t)
	local n = 0
	for _ in pairs(t or {}) do n += 1 end
	return n
end
local function resultatPost(over)
	local r = { tavling = "ubrf-2026-10-01", klass = "clear_round", hastId = "cosmo",
		regelversion = "prov-1", datum = 1000, status = "fullfoljd", fel = 0, tid = 61.5 }
	for k, v in pairs(over or {}) do r[k] = v end
	return r
end
game:GetService("RunService")._server = true
local spelare = { Name = "Pris", UserId = 7101 }
local NYCKEL = "spelare_7101"
local function ny()
	__datastore.nollstall()
	SparService._glomButikForProv()
	SparService._glomForProv(spelare)
end

print("\n── 1. Kvittonyckeln är deterministisk ──")
do
	local a = Sparning.prisId("clear_round", "r1")
	check("samma indata → samma id", a ~= nil and a == Sparning.prisId("clear_round", "r1") and a == "pris:clear_round:r1", tostring(a))
	check("olika typ → olika id", Sparning.prisId("deltagare", "r1") ~= a)
	check("okänd typ, tomt eller ogiltigt resultat → nil", Sparning.prisId("guld", "r1") == nil
		and Sparning.prisId("clear_round", "") == nil and Sparning.prisId("clear_round", nil) == nil
		and Sparning.prisId(nil, "r1") == nil)
	check("för lång total längd → nil (stängt vid fel)", Sparning.prisId("clear_round", string.rep("x", 60)) == nil)
end

print("\n── 2–3. Lokal registrering är INTE bekräftad; en lyckad skrivning bekräftar ──")
do
	ny()
	local s = SparService.ladda(spelare)
	Sparning.registreraResultat(s, "r1", resultatPost())
	local id = Sparning.prisId("clear_round", "r1")
	local okLokal = Sparning.registreraPris(s, id, { typ = "clear_round", resultatId = "r1", nar = 5 })
	check("lokalt: registreraPris svarar true …", okLokal == true)
	check("… men prisskåpet är TOMT före skrivningen", #SparService.bekraftadePriser(spelare) == 0)
	check("skrivningen går fram", SparService.skriv(spelare) == true)
	local lista = SparService.bekraftadePriser(spelare)
	local p = lista[1]
	check("efter skrivningen: ETT bekräftat pris", #lista == 1 and p.id == id, tostring(#lista))
	check("typ, källa och visning åtskilda; källan bär resultatet", p.typ == "clear_round"
		and p.kalla.resultatId == "r1" and p.kalla.resultat and p.kalla.resultat.klass == "clear_round"
		and type(p.visning) == "table" and p.nar == 5)
	local nycklar = {}
	for k in pairs(p) do table.insert(nycklar, k) end
	table.sort(nycklar)
	check("exakt nyckeluppsättning, inga prestations- eller bonusfält",
		table.concat(nycklar, ",") == "id,kalla,nar,typ,visning", table.concat(nycklar, ","))
	check("fryst", table.isfrozen(lista) and table.isfrozen(p) and table.isfrozen(p.kalla))
end

print("\n── 4. Omförsök: landade, svaret tappades en gång ──")
do
	ny()
	local s = SparService.ladda(spelare)
	Sparning.registreraResultat(s, "r2", resultatPost())
	Sparning.registreraPris(s, Sparning.prisId("clear_round", "r2"), { typ = "clear_round", resultatId = "r2", nar = 1 })
	local kast = 1
	__datastore.efterSkriv = function() if kast > 0 then kast -= 1; error("svaret tappades (stub)") end end
	local ok = SparService.skriv(spelare)
	__datastore.efterSkriv = nil
	check("omförsöket lyckades: ETT pris i lagret och bekräftat", ok == true
		and antal(__datastore._data[NYCKEL].priser) == 1 and #SparService.bekraftadePriser(spelare) == 1)
end

print("\n── 5. Tvetydig skrivning: i lagret men INTE bekräftat — tills en läsning ser det ──")
do
	ny()
	local s = SparService.ladda(spelare)
	Sparning.registreraResultat(s, "r3", resultatPost())
	Sparning.registreraPris(s, Sparning.prisId("clear_round", "r3"), { typ = "clear_round", resultatId = "r3", nar = 1 })
	__datastore.efterSkriv = function() error("svaret tappades varje gång (stub)") end
	local ok = SparService.skriv(spelare)
	__datastore.efterSkriv = nil
	check("skriv svarar false (tvetydigt)", ok == false)
	check("priset LIGGER i lagret", __datastore._data[NYCKEL] and antal(__datastore._data[NYCKEL].priser) == 1)
	check("men är INTE bekräftat", #SparService.bekraftadePriser(spelare) == 0)
	SparService._glomForProv(spelare)
	SparService.ladda(spelare)
	local l = SparService.bekraftadePriser(spelare)
	check("en ny läsning bekräftar det, EN gång", #l == 1 and l[1].id == "pris:clear_round:r3", tostring(#l))
end

print("\n── 6. Samma id igen: efter återanslutning och i två samtidiga sessioner ──")
do
	ny()
	local s = SparService.ladda(spelare)
	Sparning.registreraResultat(s, "r4", resultatPost())
	local id = Sparning.prisId("clear_round", "r4")
	Sparning.registreraPris(s, id, { typ = "clear_round", resultatId = "r4", nar = 1 })
	SparService.skriv(spelare)
	SparService._glomForProv(spelare)
	local igen = SparService.ladda(spelare)
	check("efter återanslutning: samma id kan inte förberedas igen",
		select(2, Sparning.registreraPris(igen, id, { typ = "clear_round", resultatId = "r4", nar = 2 })) == "finns")
	SparService.skriv(spelare)
	check("och lagret har fortfarande ETT", antal(__datastore._data[NYCKEL].priser) == 1)
	-- Två sessioner (två spelarobjekt, samma nyckel) som båda förbereder samma pris.
	ny()
	local a = { Name = "A", UserId = 7102 }
	local b = { Name = "B", UserId = 7102 }
	local sa, sb = SparService.ladda(a), SparService.ladda(b)
	for _, x in ipairs({ sa, sb }) do
		Sparning.registreraResultat(x, "r5", resultatPost())
		Sparning.registreraPris(x, Sparning.prisId("clear_round", "r5"), { typ = "clear_round", resultatId = "r5", nar = 1 })
	end
	SparService.skriv(a); SparService.skriv(b)
	local la, lb = SparService.bekraftadePriser(a), SparService.bekraftadePriser(b)
	check("två sessioner: ETT i lagret, båda listar samma enda post",
		antal(__datastore._data["spelare_7102"].priser) == 1 and #la == 1 and #lb == 1 and la[1].id == lb[1].id,
		("%d / %d / %d"):format(antal(__datastore._data["spelare_7102"].priser), #la, #lb))
	SparService._glomForProv(a); SparService._glomForProv(b)
end

print("\n── 7. Nekad skrivning bekräftar inget ──")
do
	ny()
	__datastore._data[NYCKEL] = { v = 99, rev = 1, pass = 0 }
	local s = SparService.ladda(spelare)
	Sparning.registreraResultat(s, "r6", resultatPost())
	Sparning.registreraPris(s, Sparning.prisId("clear_round", "r6"), { typ = "clear_round", resultatId = "r6", nar = 1 })
	check("framtida sparfil: skrivs inte, inget bekräftat", SparService.skriv(spelare) == false
		and #SparService.bekraftadePriser(spelare) == 0)
	ny()
	local t = SparService.ladda(spelare)
	Sparning.registreraResultat(t, "r7", resultatPost())
	Sparning.registreraPris(t, Sparning.prisId("clear_round", "r7"), { typ = "clear_round", resultatId = "r7", nar = 1 })
	-- Lagret fylls till taket av en annan server medan sessionen spelar.
	local full = { v = 2, rev = 50, pass = 0, passId = {}, forstaDagen = { klar = false }, hastar = {},
		framsteg = {}, resultat = {}, priser = {}, karantan = {} }
	for i = 1, Sparning.MAX_PRISER do full.priser["x" .. i] = { typ = "deltagare", nar = 1 } end
	__datastore._data[NYCKEL] = full
	check("taket nått i lagret: nekad, det nya priset inte bekräftat", SparService.skriv(spelare) == false
		and #SparService.bekraftadePriser(spelare) == 0)
end

print("\n── 8. Migration: v1 → tomt skåp; trasig prispost → karantän, aldrig listad ──")
do
	ny()
	__datastore._data[NYCKEL] = { v = 1, rev = 3, pass = 2, passId = { a = 1 }, forstaDagen = { klar = true, hastId = "cosmo" }, hastar = {} }
	SparService.ladda(spelare)
	check("v1-rad: tomt prisskåp", #SparService.bekraftadePriser(spelare) == 0)
	ny()
	__datastore._data[NYCKEL] = { v = 2, rev = 3, pass = 0, passId = {}, forstaDagen = { klar = false }, hastar = {},
		framsteg = {}, resultat = { r8 = resultatPost() },
		priser = { ["pris:clear_round:r8"] = { typ = "clear_round", resultatId = "r8", nar = 2 },
			trasig = { typ = "guld", nar = "igår" } }, karantan = {} }
	local s = SparService.ladda(spelare)
	local l = SparService.bekraftadePriser(spelare)
	check("den giltiga listas, den trasiga ligger i karantän och listas inte",
		#l == 1 and l[1].id == "pris:clear_round:r8" and s.karantan.trasig ~= nil, tostring(#l))
	check("läsmodellen ur en karta med en ogiltig post hoppar över den", #Sparning.prisskap(
		{ ok = { typ = "deltagare", resultatId = "r8", nar = 1 }, fel = { typ = "guld", nar = 1 } }, s.resultat) == 1)
end

if fails > 0 then error(("%d mätning(ar) föll."):format(fails), 0) end
print(string.format("\nsparning-prisskap.spec: %d prov, alla gröna", total))
