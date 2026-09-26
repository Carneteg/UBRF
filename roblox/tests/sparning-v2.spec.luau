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
	check("priser: placering utan resultat, okänd typ och oändlig tid är INTE giltiga",
		s.priser.utanResultat == nil and s.priser.felTyp == nil and s.priser.infNar == nil)
	check("men deras id karantänsätts i stället för att raderas (R1 fynd 3)",
		s.karantan.utanResultat ~= nil and s.karantan.felTyp ~= nil and s.karantan.infNar ~= nil)

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
	check("samma pris-id förbereds bara en gång lokalt", p1 == true and p2 == false and skalP2 == "finns")
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
	check("så det äldsta priskvittot kan inte förberedas igen", igen == false)

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
	check("samma pris-id efter återanslutning kan inte förberedas igen", dubbel == false)
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

print("\n── Läsfel och framtida rad: ingenting sparas ──")
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

--[[ ══ GRANSKNING R1 ════════════════════════════════════════════════ ]]

--[[ En rad i lagret med `nR` resultat, `nP` priser och `nF` områden. ]]
local function fylldRad(nR, nP, nF)
	local rad = { v = 2, rev = 1, pass = 0, passId = {}, forstaDagen = { klar = false },
		hastar = {}, resultat = {}, priser = {}, framsteg = {} }
	for i = 1, nR do rad.resultat["r" .. i] = resultatPost() end
	for i = 1, nP do rad.priser["p" .. i] = { typ = "deltagare", nar = i } end
	for i = 1, nF do rad.framsteg["f" .. i] = { forsok = 1, klarade = 1, senast = 1 } end
	return rad
end

local function antalIRad()
	local r = __datastore._data[NYCKEL]
	return antal(r.resultat), antal(r.priser), antal(r.framsteg)
end

print("\n── R1 fynd 1: taket prövas mot den auktoritativa raden ──")
do
	local MR, MP, MF = Sparning.MAX_RESULTAT, Sparning.MAX_PRISER, Sparning.MAX_FRAMSTEG
	--[[ ALLA TRE TILLSAMMANS: A och B laddar samma nyckel på 499/499/63.
		Var för sig ryms en post till; tillsammans ryms de inte. ]]
	__datastore.nollstall()
	__datastore._data[NYCKEL] = fylldRad(MR - 1, MP - 1, MF - 1)
	local a = { Name = "A", UserId = 7001 }
	local b = { Name = "B", UserId = 7001 }
	local sa, sb = SparService.ladda(a), SparService.ladda(b)
	check("A förbereder lokalt (under sitt tak)", Sparning.registreraResultat(sa, "ra", resultatPost()) == true
		and Sparning.registreraPris(sa, "pa", { typ = "placering", resultatId = "ra", nar = 1 }) == true
		and Sparning.noteraForsok(sa, "fa", true, 0.5, 1) == true)
	check("B förbereder lokalt (under sitt tak)", Sparning.registreraResultat(sb, "rb", resultatPost()) == true
		and Sparning.registreraPris(sb, "pb", { typ = "deltagare", nar = 1 }) == true
		and Sparning.noteraForsok(sb, "fb", true, 0.5, 1) == true)
	check("KONTROLL: B skriver och når exakt taket", SparService.skriv(b) == true)
	local r1, p1, f1 = antalIRad()
	check("lagret står på exakt 500/500/64", r1 == MR and p1 == MP and f1 == MF,
		("%d/%d/%d"):format(r1, p1, f1))
	local revFore = __datastore._data[NYCKEL].rev
	check("den inaktuella A:s skrivning NEKAS", SparService.skriv(a) == false)
	check("med skälet fullt", string.sub(SparService.senasteNej(a) or "", 1, 6) == "fullt_",
		tostring(SparService.senasteNej(a)))
	local r2, p2, f2 = antalIRad()
	check("lagret gick INTE över taket", r2 == MR and p2 == MP and f2 == MF, ("%d/%d/%d"):format(r2, p2, f2))
	check("ingen delcommit: revisionen står still", __datastore._data[NYCKEL].rev == revFore)
	check("B:s poster finns kvar", __datastore._data[NYCKEL].resultat.rb ~= nil
		and __datastore._data[NYCKEL].priser.pb ~= nil)
	check("inget föräldralöst pris: A:s placering landade inte utan sitt resultat",
		__datastore._data[NYCKEL].priser.pa == nil and __datastore._data[NYCKEL].resultat.ra == nil)
	check("A:s väntande poster ligger kvar i minnet", SparService.save(a).resultat.ra ~= nil
		and SparService.save(a).priser.pa ~= nil and SparService.save(a).framsteg.fa ~= nil)
	check("och A får fortfarande spara (inget läsfel)", SparService.kanSpara(a) == true)
	check("omförsök nekas igen, lika tydligt", SparService.skriv(a) == false
		and string.sub(SparService.senasteNej(a) or "", 1, 6) == "fullt_")
	SparService._glomForProv(a)
	local om = SparService.ladda(a)
	check("efter omladdning ser A lagrets sanning, inga föräldralösa poster",
		om.resultat.ra == nil and om.priser.pa == nil and antal(om.priser) == MP)
	check("och kan inte förbereda en post till lokalt", Sparning.registreraResultat(om, "ra", resultatPost()) == false)
	SparService._glomForProv(a)
	SparService._glomForProv(b)

	--[[ VAR KARTA FÖR SIG. ]]
	local function enKarta(namn, forbered, forvantat)
		__datastore.nollstall()
		__datastore._data[NYCKEL] = fylldRad(MR - 1, MP - 1, MF - 1)
		local x, y = { Name = "X", UserId = 7001 }, { Name = "Y", UserId = 7001 }
		local sx, sy = SparService.ladda(x), SparService.ladda(y)
		forbered(sx, "x")
		forbered(sy, "y")
		local okY = SparService.skriv(y)
		local okX = SparService.skriv(x)
		check(namn .. ": första skrivaren når taket, den andra nekas",
			okY == true and okX == false and SparService.senasteNej(x) == forvantat,
			tostring(SparService.senasteNej(x)))
		SparService._glomForProv(x)
		SparService._glomForProv(y)
	end
	enKarta("resultat", function(sv, t) Sparning.registreraResultat(sv, "r-" .. t, resultatPost()) end, "fullt_resultat")
	enKarta("priser", function(sv, t) Sparning.registreraPris(sv, "p-" .. t, { typ = "deltagare", nar = 1 }) end, "fullt_priser")
	enKarta("framsteg", function(sv, t) Sparning.noteraForsok(sv, "f-" .. t, true, 0.5, 1) end, "fullt_framsteg")

	--[[ KONTROLL: en enda session som fyller upp till exakt taket skriver. ]]
	__datastore.nollstall()
	__datastore._data[NYCKEL] = fylldRad(MR - 1, MP - 1, MF - 1)
	local e = SparService.ladda(spelare)
	Sparning.registreraResultat(e, "sista", resultatPost())
	Sparning.registreraPris(e, "sista", { typ = "deltagare", nar = 1 })
	Sparning.noteraForsok(e, "sista", true, 0.5, 1)
	check("KONTROLL: exakt taket i en session skrivs", SparService.skriv(spelare) == true)
	local r3, p3, f3 = antalIRad()
	check("och lagret står på 500/500/64", r3 == MR and p3 == MP and f3 == MF, ("%d/%d/%d"):format(r3, p3, f3))

	--[[ En rad som REDAN ligger över taket gallras inte, och en skrivning
		utan nya v2-poster (t.ex. ett pass) går fortfarande igenom. ]]
	SparService._glomForProv(spelare)
	__datastore.nollstall()
	__datastore._data[NYCKEL] = fylldRad(MR + 3, MP + 3, MF + 3)
	local o = SparService.ladda(spelare)
	Sparning.registreraPass(o, "p-over", 1)
	check("en rad över taket: skrivning utan nya v2-poster går fram", SparService.skriv(spelare) == true)
	local r4, p4, f4 = antalIRad()
	check("och ingenting gallrades", r4 == MR + 3 and p4 == MP + 3 and f4 == MF + 3,
		("%d/%d/%d"):format(r4, p4, f4))
	SparService._glomForProv(spelare)
end

print("\n── R1 fynd 2: registreraPris är lokal förberedelse, inte utdelning ──")
do
	--[[ MOTEXEMPEL, inte en utdelning (ingen finns ännu): två sessioner som laddat samma nyckel
		får BÅDA true för samma pris-id. Det visar varför en framtida
		konsument aldrig får ge ett pris på det svaret (D4-RÄTT). ]]
	__datastore.nollstall()
	local a = { Name = "A", UserId = 7001 }
	local b = { Name = "B", UserId = 7001 }
	local sa, sb = SparService.ladda(a), SparService.ladda(b)
	local ta = Sparning.registreraPris(sa, "samma", { typ = "deltagare", nar = 1 })
	local tb = Sparning.registreraPris(sb, "samma", { typ = "deltagare", nar = 2 })
	check("MOTEXEMPEL: båda sessionerna får lokalt true för samma id", ta == true and tb == true)
	SparService.skriv(b)
	SparService.skriv(a)
	check("lagret har ett kvitto — men två lokala true har redan givits",
		antal(__datastore._data[NYCKEL].priser) == 1)
	check("och det kvitto som står är det som skrevs först (B)", __datastore._data[NYCKEL].priser.samma.nar == 2)
	SparService._glomForProv(a)
	SparService._glomForProv(b)

	--[[ MOTEXEMPEL: en session som inte får spara förbereder ändå lokalt. ]]
	__datastore.nollstall()
	__datastore._data[NYCKEL] = { v = 3, pass = 1 }
	local f = SparService.ladda(spelare)
	local lokal = Sparning.registreraPris(f, "ro", { typ = "deltagare", nar = 1 })
	check("MOTEXEMPEL: en skrivskyddad session får lokalt true", lokal == true)
	check("fast den inte får spara och ingenting skrivs",
		SparService.kanSpara(spelare) == false and SparService.skriv(spelare) == false
			and __datastore._data[NYCKEL].priser == nil)
	SparService._glomForProv(spelare)
end

print("\n── R1 fynd 3: ett pris utan giltigt resultat karantänsätts ──")
do
	__datastore.nollstall()
	__datastore._data[NYCKEL] = {
		v = 2, rev = 1, pass = 0,
		resultat = {
			bad = resultatPost({ datum = math.huge }),
			ok = resultatPost(),
		},
		priser = {
			avvisat = { typ = "placering", resultatId = "bad", farg = "blagul", nar = 1 },
			saknas = { typ = "clear_round", resultatId = "finnsInte", nar = 2 },
			giltigt = { typ = "placering", resultatId = "ok", farg = "bla", nar = 3 },
			trasig = { typ = "placering", nar = "inte ett tal" },
		},
	}
	local s = SparService.ladda(spelare)
	check("det avvisade resultatet är borta", s.resultat.bad == nil)
	check("pris vars resultat avvisades är INTE ett giltigt pris", Sparning.harPris(s, "avvisat") == false)
	check("pris vars resultat saknas är INTE ett giltigt pris", Sparning.harPris(s, "saknas") == false)
	check("KONTROLL: pris med giltigt resultat är giltigt", Sparning.harPris(s, "giltigt") == true)
	check("de ogiltiga ligger i karantän med orsak",
		s.karantan.avvisat and s.karantan.avvisat.orsak == "saknat_resultat"
			and s.karantan.saknas and s.karantan.saknas.orsak == "saknat_resultat"
			and s.karantan.trasig and s.karantan.trasig.orsak == "ogiltig_post")
	local igen, skal = Sparning.registreraPris(s, "avvisat",
		{ typ = "placering", resultatId = "ok", farg = "blagul", nar = 9 })
	check("samma pris-id kan INTE förberedas igen", igen == false and skal == "karantan", tostring(skal))
	check("inte heller det trasiga", Sparning.registreraPris(s, "trasig", { typ = "deltagare", nar = 9 }) == false)

	check("skrivningen går fram", SparService.skriv(spelare) == true)
	local rad = __datastore._data[NYCKEL]
	check("karantänen bevaras i lagret", rad.karantan and rad.karantan.avvisat and rad.karantan.saknas
		and rad.karantan.trasig)
	check("och de karantänsatta står inte som priser", rad.priser.avvisat == nil and rad.priser.saknas == nil
		and rad.priser.giltigt ~= nil)
	SparService._glomForProv(spelare)
	local om = SparService.ladda(spelare)
	check("efter omladdning är de fortfarande karantänsatta", om.karantan.avvisat ~= nil
		and Sparning.harPris(om, "avvisat") == false)
	check("och fortfarande förbrukade", Sparning.registreraPris(om, "saknas", { typ = "deltagare", nar = 9 }) == false)
	SparService._glomForProv(spelare)

	--[[ Sammanslagningen bär karantänen: står den bara i minnet (lagrets
		rad saknar den) ska den ändå med, och id:t får inte komma in som
		giltigt pris från någon av sidorna. ]]
	local minnet = Sparning.migrera({ v = 2, priser = { k = { typ = "placering", resultatId = "borta", nar = 1 } } })
	local lagret = Sparning.tom()
	lagret.priser.k2 = { typ = "deltagare", nar = 1 }
	minnet.karantan.k2 = { orsak = "saknat_resultat", pris = nil }
	Sparning.slaIhopV2(lagret, minnet)
	check("karantän i minnet följer med in i lagrets rad", lagret.karantan.k ~= nil)
	check("och id:t är förbrukat efter sammanslagningen",
		Sparning.registreraPris(lagret, "k", { typ = "deltagare", nar = 2 }) == false)
	check("ett id som redan är giltigt pris i lagret karantänsätts inte i efterhand",
		lagret.priser.k2 ~= nil and lagret.karantan.k2 == nil)
end

if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("\nsparning-v2.spec: alla gröna")
end
