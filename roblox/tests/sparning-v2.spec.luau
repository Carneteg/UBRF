--!nostrict
--[[
	SPARNING v2 — #264 COMPLETION_FIRST_INFRA1.

	Mäter produktionsmodulerna `Sparning` och `SparService` — samma som
	servern kör — mot den stubbade `DataStoreService` i `stubs.luau`
	(`__datastore`). Ingen egen kopia av schemat eller sammanslagningen.

	EVIDENSNIVÅ: BANK_ONLY. Det här är bänken: en handskriven DataStore med
	`GetAsync`/`UpdateAsync`, felknappar och omkörning. Den bevisar att
	reglerna och tjänstens läs-/skriv-/omladdningsväg håller i bänken, INTE
	att Roblox riktiga datalager, kvoter eller nät beter sig likadant. Inga
	riktiga DataStore-skrivningar görs.

	Kör: python3 tests/build.py tests/sparning-v2.spec.luau
	     && luau tests/.build/sparning-v2.spec.luau   (från roblox/)
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

print("\n── v1 → v2: inget v1-fält ändras ──")
do
	local v1 = {
		v = 1, rev = 7, pass = 3,
		passId = { ["9001:cosmo:1"] = 11, ["9001:cosmo:2"] = 12, ["9001:air:3"] = 13 },
		forstaDagen = { klar = true, hastId = "cosmo" },
		hastar = { cosmo = { relation = 0.4, skada = { passKvar = 2, vad = "sadel" } },
			air = { relation = 0.1 } },
	}
	local s, n = Sparning.migrera(v1)
	check("v1-raden läses utan anmärkning", n == nil, tostring(n))
	check("och blir v2", s.v == 2 and Sparning.VERSION == 2, tostring(s.v))
	check("rev bevaras", s.rev == 7)
	check("pass bevaras", s.pass == 3)
	check("passId bevaras", antal(s.passId) == 3 and s.passId["9001:air:3"] == 13)
	check("forstaDagen bevaras", s.forstaDagen.klar == true and s.forstaDagen.hastId == "cosmo")
	check("HÄSTMINNET bevaras (relation och skada)",
		s.hastar.cosmo and s.hastar.cosmo.relation == 0.4 and s.hastar.cosmo.skada
			and s.hastar.cosmo.skada.passKvar == 2 and s.hastar.cosmo.skada.vad == "sadel"
			and s.hastar.air and s.hastar.air.relation == 0.1)
	check("v2-kartorna är tomma", antal(s.framsteg) == 0 and antal(s.resultat) == 0
		and antal(s.priser) == 0)

	local tom = Sparning.tom()
	check("en ny save är v2 med tomma kartor", tom.v == 2 and type(tom.framsteg) == "table"
		and type(tom.resultat) == "table" and type(tom.priser) == "table")
	local rond = Sparning.migrera(Sparning.tillRad(s))
	check("v2 → rad → v2 behåller hästminnet", rond.hastar.cosmo.skada.passKvar == 2)
end

print("\n── Trasiga v2-fält tvättas, icke-ändliga tal nekas ──")
do
	local lang = string.rep("x", 65)
	local s, n = Sparning.migrera({
		v = 2, rev = math.huge, pass = math.huge,
		framsteg = {
			volt = { forsok = 3, klarade = 9, basta = 1.7, senast = 5 },
			[lang] = { forsok = 1 },
			[""] = { forsok = 1 },
			trasig = "inte en tabell",
		},
		resultat = {
			ok = resultatPost(),
			utanKlass = resultatPost({ klass = "" }),
			nanDatum = resultatPost({ datum = 0 / 0 }),
			infDatum = resultatPost({ datum = math.huge }),
			felStatus = resultatPost({ status = "vann" }),
			infFel = resultatPost({ fel = math.huge }),
			[42] = resultatPost(),
		},
		priser = {
			p1 = { typ = "placering", resultatId = "ok", farg = "blagul", nar = 5 },
			utanResultat = { typ = "placering", nar = 5 },
			felTyp = { typ = "guld", nar = 5 },
			infNar = { typ = "deltagare", nar = math.huge },
			cr = { typ = "clear_round", resultatId = "ok", nar = 6 },
		},
	})
	check("raden läses", n == nil, tostring(n))
	check("oändligt pass blir NOLL, inte oändligt", s.pass == 0, tostring(s.pass))
	check("oändlig rev blir noll", s.rev == 0, tostring(s.rev))
	check("framsteg: klarade klipps NED till försöken", s.framsteg.volt and s.framsteg.volt.klarade == 3)
	check("framsteg: bästa kvalitet klipps till 1", s.framsteg.volt.basta == 1)
	check("framsteg: för långt och tomt id tas bort", s.framsteg[lang] == nil and s.framsteg[""] == nil)
	check("framsteg: en icke-tabell tas bort", s.framsteg.trasig == nil)
	check("resultat: den giltiga posten finns kvar", s.resultat.ok ~= nil and s.resultat.ok.tid == 61.5)
	check("resultat: tomt obligatoriskt fält tas bort", s.resultat.utanKlass == nil)
	check("resultat: NaN- och oändligt datum tas bort", s.resultat.nanDatum == nil and s.resultat.infDatum == nil)
	check("resultat: okänd status tas bort", s.resultat.felStatus == nil)
	check("resultat: oändligt fel-tal tas bort ur posten, inte gissas",
		s.resultat.infFel ~= nil and s.resultat.infFel.fel == nil)
	check("resultat: ett icke-sträng-id tas bort", antal(s.resultat) == 2, tostring(antal(s.resultat)))
	check("priser: giltiga finns kvar", s.priser.p1 ~= nil and s.priser.cr ~= nil)
	check("priser: placering utan resultat, okänd typ och oändlig tid tas bort",
		s.priser.utanResultat == nil and s.priser.felTyp == nil and s.priser.infNar == nil)

	local f, fn = Sparning.migrera({ v = 3, pass = 50, priser = { x = { typ = "deltagare", nar = 1 } } })
	check("en FRAMTIDA rad (v3) förstås inte", fn == "spar.framtida_sparfil", tostring(fn))
	check("och ger varken pass eller pris", f.pass == 0 and antal(f.priser) == 0)
end

print("\n── Kvitton: samma id två gånger ger en post ──")
do
	local s = Sparning.tom()
	local ok1 = Sparning.registreraResultat(s, "r1", resultatPost())
	local ok2, skal2 = Sparning.registreraResultat(s, "r1", resultatPost({ fel = 0, tid = 50 }))
	check("första resultatet registreras", ok1 == true)
	check("samma id nekas med «finns»", ok2 == false and skal2 == "finns", tostring(skal2))
	check("och det fastställda resultatet ändras inte", s.resultat.r1.tid == 61.5)

	local okP, skalP = Sparning.registreraPris(s, "pris-r1", { typ = "placering", resultatId = "saknas", nar = 1 })
	check("en placeringsrosett utan känt resultat nekas", okP == false and skalP == "ogiltig")
	local p1 = Sparning.registreraPris(s, "pris-r1", { typ = "placering", resultatId = "r1", farg = "blagul", nar = 1 })
	local p2, skalP2 = Sparning.registreraPris(s, "pris-r1", { typ = "placering", resultatId = "r1", farg = "blagul", nar = 1 })
	check("priset delas ut en gång", p1 == true and p2 == false and skalP2 == "finns")
	check("en post, inte två", antal(s.priser) == 1)

	local ogiltig, skalO = Sparning.registreraResultat(s, "r2", resultatPost({ datum = math.huge }))
	check("ett resultat med oändligt datum nekas", ogiltig == false and skalO == "ogiltig")

	--[[ TAKET: fullt ger ett nej, och INGET gammalt kvitto tas bort — ett
		gallrat priskvitto hade gjort samma pris utdelningsbart igen. ]]
	local t = Sparning.tom()
	for i = 1, Sparning.MAX_PRISER do
		Sparning.registreraPris(t, "d" .. i, { typ = "deltagare", nar = i })
	end
	local fullt, skalF = Sparning.registreraPris(t, "ny", { typ = "deltagare", nar = 9999 })
	check("vid taket nekas ett nytt pris med «fullt»", fullt == false and skalF == "fullt", tostring(skalF))
	check("och det äldsta kvittot finns kvar", t.priser.d1 ~= nil and antal(t.priser) == Sparning.MAX_PRISER)
	local igen = Sparning.registreraPris(t, "d1", { typ = "deltagare", nar = 1 })
	check("så det äldsta priset kan inte delas ut igen", igen == false)

	local fr = Sparning.tom()
	Sparning.noteraForsok(fr, "volt", false, 0.4, 10)
	Sparning.noteraForsok(fr, "volt", true, 0.7, 20)
	Sparning.noteraForsok(fr, "volt", true, 0.5, 15)
	local v = fr.framsteg.volt
	check("framsteg räknar försök och klarade", v.forsok == 3 and v.klarade == 2)
	check("bästa kvalitet sänks aldrig", v.basta == 0.7)
	check("senaste tiden går aldrig bakåt", v.senast == 20)
end

print("\n── SparService: skriv → ladda om, genom den riktiga tjänsten ──")
local spelare = { Name = "V2", UserId = 7001 }
local NYCKEL = "spelare_7001"
do
	game:GetService("RunService")._server = true
	__datastore.nollstall()
	SparService._glomButikForProv()
	__datastore._data[NYCKEL] = {
		v = 1, rev = 4, pass = 2, passId = { a = 1, b = 2 },
		forstaDagen = { klar = true, hastId = "cosmo" },
		hastar = { cosmo = { relation = 0.3, skada = { passKvar = 1 } } },
	}
	local s = SparService.ladda(spelare)
	check("en v1-rad i lagret laddas", SparService.kanSpara(spelare) == true and s.v == 2)
	Sparning.registreraResultat(s, "r1", resultatPost())
	Sparning.registreraPris(s, "cr-r1", { typ = "clear_round", resultatId = "r1", nar = 2 })
	Sparning.noteraForsok(s, "halt_skritt", true, 0.8, 3)
	check("skrivningen går fram", SparService.skriv(spelare) == true)
	local rad = __datastore._data[NYCKEL]
	check("lagret bär v2", rad.v == 2, tostring(rad.v))
	check("lagret bär resultat, pris och framsteg",
		rad.resultat and rad.resultat.r1 and rad.priser and rad.priser["cr-r1"]
			and rad.framsteg and rad.framsteg.halt_skritt)
	check("och v1-fälten är orörda", rad.pass == 2 and rad.forstaDagen.klar == true
		and rad.hastar.cosmo.skada.passKvar == 1 and rad.passId.a == 1)
	check("revisionen gick upp ett steg", rad.rev == 5, tostring(rad.rev))

	SparService._glomForProv(spelare)
	local igen = SparService.ladda(spelare)
	check("efter återanslutning finns resultatet", igen.resultat.r1 ~= nil)
	check("och priset", igen.priser["cr-r1"] ~= nil)
	check("och framsteget", igen.framsteg.halt_skritt and igen.framsteg.halt_skritt.klarade == 1)
	check("och hästminnet", igen.hastar.cosmo.skada.passKvar == 1)

	--[[ SAMMA PRIS IGEN efter omladdningen: kvittot ligger nu i lagret. ]]
	local dubbel = Sparning.registreraPris(igen, "cr-r1", { typ = "clear_round", resultatId = "r1", nar = 3 })
	check("samma pris-id efter återanslutning delas inte ut", dubbel == false)
	SparService.skriv(spelare)
	check("och lagret har fortfarande ETT pris", antal(__datastore._data[NYCKEL].priser) == 1)
	SparService._glomForProv(spelare)
end

print("\n── Omförsök: skrivningen landade men anropet kastade ──")
do
	__datastore.nollstall()
	local s = SparService.ladda(spelare)
	Sparning.registreraPass(s, "p1", 1)
	Sparning.registreraPris(s, "d1", { typ = "deltagare", nar = 1 })
	Sparning.noteraForsok(s, "volt", true, 0.5, 1)
	local kast = 1
	__datastore.efterSkriv = function()
		if kast > 0 then kast -= 1; error("svaret tappades (stub)") end
	end
	local ok = SparService.skriv(spelare)
	__datastore.efterSkriv = nil
	check("tjänsten försökte om och lyckades", ok == true and __datastore.forsok.skriv == 2,
		__datastore.forsok.skriv .. " skrivförsök")
	local rad = __datastore._data[NYCKEL]
	check("ETT pris efter omförsöket", antal(rad.priser) == 1)
	check("ETT pass efter omförsöket", rad.pass == 1, tostring(rad.pass))
	check("framsteget räknades inte två gånger", rad.framsteg.volt.forsok == 1, tostring(rad.framsteg.volt.forsok))
	SparService._glomForProv(spelare)

	--[[ Roblox får köra om transformatorn och kasta det första svaret. ]]
	__datastore.nollstall()
	local t = SparService.ladda(spelare)
	Sparning.registreraPass(t, "p1", 1)
	Sparning.registreraPris(t, "d1", { typ = "deltagare", nar = 1 })
	__datastore.omkorTransform = true
	check("skrivning med omkörd transformator går fram", SparService.skriv(spelare) == true)
	__datastore.omkorTransform = false
	local r2 = __datastore._data[NYCKEL]
	check("och ger ETT pris och ETT pass", antal(r2.priser) == 1 and r2.pass == 1,
		antal(r2.priser) .. " priser, " .. tostring(r2.pass) .. " pass")
	SparService._glomForProv(spelare)
end

print("\n── En inaktuell skrivare skriver inte över en nyare revision ──")
do
	__datastore.nollstall()
	--[[ Två servrar, samma spelare: två Player-objekt med samma UserId och
		därmed samma nyckel, men var sin session i tjänsten. ]]
	local a = { Name = "ServerA", UserId = 7001 }
	local b = { Name = "ServerB", UserId = 7001 }
	local sa = SparService.ladda(a)
	local sb = SparService.ladda(b)
	Sparning.registreraResultat(sb, "r-b", resultatPost({ fel = 4 }))
	Sparning.registreraResultat(sb, "delad", resultatPost({ tid = 70 }))
	Sparning.satSkada(sb, "cosmo", 3, "senan")
	Sparning.noteraForsok(sb, "volt", true, 0.9, 50)
	check("B skriver först", SparService.skriv(b) == true)

	Sparning.registreraResultat(sa, "r-a", resultatPost())
	Sparning.registreraResultat(sa, "delad", resultatPost({ tid = 55 }))
	Sparning.noteraForsok(sa, "volt", false, 0.2, 10)
	check("A (inaktuell) skriver sedan", SparService.skriv(a) == true)
	local rad = __datastore._data[NYCKEL]
	check("B:s resultat finns kvar", rad.resultat["r-b"] ~= nil)
	check("A:s nya resultat lades till", rad.resultat["r-a"] ~= nil)
	check("ett resultat som redan stod i lagret skrevs INTE över", rad.resultat.delad.tid == 70,
		tostring(rad.resultat.delad.tid))
	check("B:s skada på hästen finns kvar", rad.hastar.cosmo and rad.hastar.cosmo.skada
		and rad.hastar.cosmo.skada.passKvar == 3)
	check("framsteg sänktes inte", rad.framsteg.volt.basta == 0.9 and rad.framsteg.volt.senast == 50)
	check("revisionen gick förbi B:s", rad.rev == 2, tostring(rad.rev))
	SparService._glomForProv(a)
	SparService._glomForProv(b)
end

print("\n── Läsfel och framtida rad: ingenting skrivs, ingenting delas ut ──")
do
	__datastore.nollstall()
	__datastore._data[NYCKEL] = { v = 3, pass = 9, framtidaFalt = "okänt" }
	local s = SparService.ladda(spelare)
	check("en framtida rad stänger sparningen", SparService.kanSpara(spelare) == false)
	Sparning.registreraPris(s, "d1", { typ = "deltagare", nar = 1 })
	check("skrivningen nekas", SparService.skriv(spelare) == false)
	local rad = __datastore._data[NYCKEL]
	check("den framtida raden ligger orörd", rad.v == 3 and rad.pass == 9 and rad.priser == nil
		and rad.framtidaFalt == "okänt")
	SparService._glomForProv(spelare)

	__datastore.nollstall()
	__datastore._data[NYCKEL] = { v = 2, rev = 1, pass = 4, priser = { d1 = { typ = "deltagare", nar = 1 } } }
	__datastore.felLas = true
	local l = SparService.ladda(spelare)
	__datastore.felLas = false
	check("ett läsfel ger en sessionsave utan pris", antal(l.priser) == 0 and l.pass == 0)
	Sparning.registreraPris(l, "d1", { typ = "deltagare", nar = 2 })
	check("och den skrivs inte", SparService.skriv(spelare) == false)
	check("lagret är orört", __datastore._data[NYCKEL].pass == 4
		and __datastore._data[NYCKEL].priser.d1.nar == 1)
	SparService._glomForProv(spelare)
end

if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("\nsparning-v2.spec: alla gröna")
end
