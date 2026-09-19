--!nostrict
--[[ RIDE FIRST-TEMAT — KONTRAKTET I #234, MÄTT.

	Beställningen 2026-09-19 säger vad Ugneta ska göra före och under
	ritten. Den här specen mäter punkt 1–7 och 9–11 i kontraktets egen
	ordning, plus falsifieringen av de tre gater som bär pedagogiken:
	temafiltret, tremönstret och cooldownen.

	  1. startrepliken visas exakt en gång per giltig lektionsstart,
	  2. fel tema ignorerar orelaterade signaler,
	  3. två hårda tygeltag ger ingen kommentar, det tredje gör det,
	  4. enstaka misstag ger ingen kommentar,
	  5. cooldown blockerar spam i 7 sekunder utan fördröjd kommentarskö,
	  6. duplicerad StateSync/händelse räknas inte flera gånger,
	  7. dagsform och ryttarmisstag väljer olika språkfamiljer,
	  9. sessionsdata från föregående ritt läcker inte till nästa,
	 10. BubbleChat + lokal logg får samma replik,
	 11. Ugneta LookAt påverkar inte häst-, spelar- eller världsauktoritet.

	Punkt 8 och 12 mäts av `ugneta-summering.spec` — de hör till rutan
	efter passet, och den har ett eget delkontrakt.

	TVÅ NIVÅER, MED FLIT. Regeln provas direkt mot `UgnetaTema`, som är ren
	logik och går att stega exakt; KEDJAN provas genom `init.client.luau`
	och dess RenderStepped, alltså genom det spelaren faktiskt kör. Ett
	prov som bara anropar modulen bevisar att funktionen finns — samma
	lärdom som läktarprovet (#114) och klient-specens eget huvud.

	GRÄNSEN, uttalad: bänken är inte en klient. Ingenting här säger hur
	bubblan SER UT i Studio eller hur den känns på en iPad.

	Kör: python3 roblox/tests/build.py tests/ugneta-tema.spec.luau
	     && luau roblox/tests/.build/ugneta-tema.spec.luau
]]

local fel = 0
local function prova(vad, ok, detalj)
	if ok then
		print(("  OK   %s%s"):format(vad, if detalj then " " .. detalj else ""))
	else
		fel += 1
		print(("  FEL  %s%s"):format(vad, if detalj then " " .. detalj else ""))
	end
end

print("\nRIDE FIRST-TEMAT (#234)\n")

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
--[[ Samma väg in som klient-specen: remoterna hämtas genom `Networking`,
     alltså genom den mapp produktionen själv slår upp. ]]
local Net = Networking

local TEMA = RidKanon.UGNETA.TEMA
local K = RidKanon.KONTAKT

--[[ ══ 0. KANONEN ═══════════════════════════════════════════════════════

	Talen ska komma ur `src/larare.js` genom exporten, och trösklarna ur
	ridmodellens egna kontaktband. En avskriven 0,72 i modulen hade varit
	en andra sanning — det är precis vad `Ugneta.luau` en gång rättade. ]]
print("── Kanonen ──")
do
	prova("temat finns i den genererade kanonen",
		type(TEMA) == "table" and type(TEMA.ORDNING) == "table",
		("(%d teman)"):format(if TEMA and TEMA.ORDNING then #TEMA.ORDNING else 0))
	prova("lektionen börjar i Handen",
		UgnetaTema.forsta() == "handen", ("(%s)"):format(UgnetaTema.forsta()))
	prova("cooldownen är beställningens 7 sekunder",
		TEMA.COOLDOWN == 7, ("(%s s)"):format(tostring(TEMA.COOLDOWN)))
	prova("ett hårt tygeltag är kontaktkanonens TYGEL_HART, inte ett eget tal",
		TEMA.handen.signal.hard_tygel.over == K.TYGEL_HART,
		("(%s == %s)"):format(tostring(TEMA.handen.signal.hard_tygel.over),
			tostring(K.TYGEL_HART)))
	prova("återarmeringen är kontaktbandets övre kant",
		TEMA.handen.signal.hard_tygel.ater == K.TYGEL_BAND_MAX,
		("(%s == %s)"):format(tostring(TEMA.handen.signal.hard_tygel.ater),
			tostring(K.TYGEL_BAND_MAX)))
	prova("den korrekta signalen är ett HÅLL i kontaktbandet, inte en släpp",
		TEMA.handen.signal.mjuk_tygel.band ~= nil
			and TEMA.handen.signal.mjuk_tygel.hall ~= nil
			and TEMA.handen.signal.mjuk_tygel.band[1] == K.TYGEL_BAND_MIN
			and TEMA.handen.signal.mjuk_tygel.band[2] == K.TYGEL_BAND_MAX,
		("(band %s..%s i %s s)"):format(
			tostring(TEMA.handen.signal.mjuk_tygel.band
				and TEMA.handen.signal.mjuk_tygel.band[1]),
			tostring(TEMA.handen.signal.mjuk_tygel.band
				and TEMA.handen.signal.mjuk_tygel.band[2]),
			tostring(TEMA.handen.signal.mjuk_tygel.hall)))
	prova("mönstret kräver tre inom ett dokumenterat fönster",
		TEMA.handen.monster.hard_tygel.antal == 3
			and TEMA.handen.monster.hard_tygel.fonster > 0
			and TEMA.handen.monster.hard_tygel.aterstall > 0,
		("(%d st inom %s s, glapptak %s s)"):format(
			TEMA.handen.monster.hard_tygel.antal,
			tostring(TEMA.handen.monster.hard_tygel.fonster),
			tostring(TEMA.handen.monster.hard_tygel.aterstall)))
end

--[[ ── TELEMETRIRAMEN ──────────────────────────────────────────────────
     Samma två skikt som `Telemetri.las` skriver: hjälperna i `hjalper`,
     hästens svar på toppnivå. Hjälparen bygger ingen egen modell — den
     sorterar bara fälten dit produktionen lägger dem. ]]
local HJALP = { tygel = true, sits = true, parad = true }
local function ram(falt)
	local t = { uppsutten = true, hjalper = {} }
	for k, v in falt do
		if HJALP[k] then t.hjalper[k] = v else t[k] = v end
	end
	return t
end

local DT = 1 / 30

--[[ Ett tygeltag: ett hårt ryck och en återgång. Två bildrutor, alltså
     0,067 s — långt under både fönstret och hållets 1,2 s.

     BÅDA bildrutornas svar räknas. Kommentaren faller ut på den HÅRDA
     bildrutan, inte på återgången, och ett första utkast som bara
     returnerade den andra rapporterade "tyst" på ett mönster som
     faktiskt fyrade. En hjälpare som tappar sitt eget mätvärde är ett
     falskt rött — lika illa som ett falskt grönt. ]]
local function tygeltag(sess, hart, mjukt)
	local a = UgnetaTema.steg(sess, DT, ram({ tygel = hart or 0.80 }))
	local b = UgnetaTema.steg(sess, DT, ram({ tygel = mjukt or 0.40 }))
	return a or b
end

local function serie(sess, namn)
	local l = sess.serie[namn]
	return if l then #l else 0
end

--[[ ══ 2. TEMAFILTRET ════════════════════════════════════════════════ ]]
print("\n── 2. Fel tema ignorerar orelaterade signaler ──")
do
	local handen = UgnetaTema.def("handen")
	prova("Handen får läsa tygeln",
		UgnetaTema.varde(handen, ram({ tygel = 0.9 }), "tygel") == 0.9)
	prova("men INTE sitsen — fältet står inte i temats lista",
		UgnetaTema.varde(handen, ram({ sits = 0.9 }), "sits") == nil,
		("(%s)"):format(tostring(UgnetaTema.varde(handen, ram({ sits = 0.9 }), "sits"))))

	local sess = UgnetaTema.ny("handen")
	--[[ Tre fullgoda sitsmönster, som hade kommenterats i temat Sitsen. ]]
	local sagt = nil
	UgnetaTema.steg(sess, DT, ram({ sits = 0.05 }))
	for _ = 1, 3 do
		sagt = UgnetaTema.steg(sess, DT, ram({ sits = 0.90 })) or sagt
		sagt = UgnetaTema.steg(sess, DT, ram({ sits = 0.05 })) or sagt
	end
	prova("Handen kommenterar inte en tung sits", sagt == nil,
		("(%s)"):format(if sagt then sagt.nyckel else "tyst"))
	prova("och den räknar inte ens serien", serie(sess, "tung_sits") == 0)

	--[[ SAMMA signaler, ANNAT tema. Skillnaden är temavalet och inget
	     annat — samma tabell, samma bildrutor, samma trösklar. ]]
	local sits = UgnetaTema.ny("sitsen")
	local r = nil
	UgnetaTema.steg(sits, DT, ram({ sits = 0.05 }))
	for _ = 1, 3 do
		r = UgnetaTema.steg(sits, DT, ram({ sits = 0.90 })) or r
		r = UgnetaTema.steg(sits, DT, ram({ sits = 0.05 })) or r
	end
	prova("temat Sitsen kommenterar samma bildrutor",
		r ~= nil and r.nyckel == TEMA.sitsen.monster.tung_sits.nyckel,
		("(%s)"):format(if r then r.nyckel else "tyst"))
	prova("och temat Sitsen läser i sin tur INTE tygeln",
		UgnetaTema.varde(UgnetaTema.def("sitsen"), ram({ tygel = 0.9 }), "tygel") == nil)
end

--[[ ══ 2b. ETT OKÄNT TEMA FALLER STÄNGT ════════════════════════════

	Senior review 2026-09-19, blockerare 2: `ny(temaId)` behandlade nil och
	en okänd sträng lika — båda blev `forsta()`. En felstavad temasträng
	blev alltså TYST "handen", och spelaren fick en annan undervisning än
	den som beställdes, utan ett spår någonstans.

	nil betyder fortfarande standard; det är en frånvaro av val, inte ett
	fel. Allt annat okänt ger INGEN session. ]]
print("\n── 2b. nil är standard, en okänd sträng är ett fel ──")
do
	local standard = UgnetaTema.ny(nil)
	prova("nil ger kanonens första tema",
		standard ~= nil and standard.tema == UgnetaTema.forsta(),
		("(%s)"):format(if standard then standard.tema else "ingen"))
	local kant = UgnetaTema.ny("sitsen")
	prova("en känd sträng ger precis det temat",
		kant ~= nil and kant.tema == "sitsen",
		("(%s)"):format(if kant then kant.tema else "ingen"))

	--[[ FYRA FORMER AV "inte ett tema", och ingen av dem får bli handen. ]]
	prova("en felstavad sträng ger INGEN session — inte tyst handen",
		UgnetaTema.ny("hnaden") == nil,
		("(%s)"):format(tostring(UgnetaTema.ny("hnaden"))))
	prova("och inte heller en tom sträng", UgnetaTema.ny("") == nil)
	prova("och inte heller ett framtida tema som inte finns än",
		UgnetaTema.ny("skanklarna") == nil)
	prova("och inte heller ett icke-strängvärde", UgnetaTema.ny(42) == nil)

	--[[ GENOM PRODUKTIONENS VÄG. Regeln är värdelös om ytan ändå startar
	     ett standardpass ovanpå den. ]]
	local bubblorFore = #__BUBBLOR
	local sagt = UgnetaController.startaPass("hnaden", "ritt-okand")
	prova("startaPass med okänt tema säger ingenting",
		sagt == "" and #__BUBBLOR == bubblorFore,
		("(\"%s\" · %d nya bubblor)"):format(sagt, #__BUBBLOR - bubblorFore))
	prova("och startar inget pass alls",
		UgnetaController.passSession() == nil)
	prova("en bildruta på ett pass som inte finns är också tyst",
		UgnetaController.ritt(DT, ram({ tygel = 0.95 })) == "")
end

--[[ ══ 3 och 4. MÖNSTRET FÖRE KOMMENTAREN ═══════════════════════════ ]]
print("\n── 3/4. Tre i följd, inte ett enstaka fel ──")
do
	local sess = UgnetaTema.ny("handen")
	UgnetaTema.steg(sess, DT, ram({ tygel = 0.40 }))       -- armerar

	local ett = tygeltag(sess)
	prova("ETT hårt tygeltag ger ingen kommentar", ett == nil,
		("(serie %d)"):format(serie(sess, "hard_tygel")))
	local tva = tygeltag(sess)
	prova("TVÅ hårda tygeltag ger fortfarande ingen kommentar", tva == nil,
		("(serie %d)"):format(serie(sess, "hard_tygel")))
	local tre = tygeltag(sess)
	prova("det TREDJE ger en kommentar",
		tre ~= nil and tre.nyckel == TEMA.handen.monster.hard_tygel.nyckel,
		("(%s)"):format(if tre then tre.nyckel else "tyst"))
	prova("och kommentaren är ryttarens mönster, inte hästens dagsform",
		tre ~= nil and tre.orsak == "ryttare",
		("(orsak %s)"):format(if tre then tre.orsak else "-"))
end

print("\n── En korrekt signal avtrubbar serien ──")
do
	local sess = UgnetaTema.ny("handen")
	UgnetaTema.steg(sess, DT, ram({ tygel = 0.40 }))
	tygeltag(sess); tygeltag(sess)
	prova("två tag ligger i serien", serie(sess, "hard_tygel") == 2,
		("(%d)"):format(serie(sess, "hard_tygel")))
	--[[ Handen ligger kvar i kontaktbandet längre än `hall`. ]]
	local hall = TEMA.handen.signal.mjuk_tygel.hall
	for _ = 1, math.ceil(hall / DT) + 2 do
		UgnetaTema.steg(sess, DT, ram({ tygel = 0.40 }))
	end
	prova("en mjuk hand i kontaktbandet nollställer serien",
		serie(sess, "hard_tygel") == 0, ("(%d)"):format(serie(sess, "hard_tygel")))
	local tre = tygeltag(sess); tygeltag(sess); tre = tygeltag(sess)
	prova("och räkningen börjar om från noll — tre nya tag krävs igen",
		tre ~= nil, ("(%s)"):format(if tre then tre.nyckel else "tyst"))
end

print("\n── Ett glapp längre än återställningstiden tömmer serien ──")
do
	local sess = UgnetaTema.ny("handen")
	UgnetaTema.steg(sess, DT, ram({ tygel = 0.40 }))
	tygeltag(sess); tygeltag(sess)
	--[[ Tystnad: uppsutten men ingen hand alls att läsa. Hållet kan inte
	     heller fyra, så det är GLAPPET som mäts och inget annat. ]]
	local glapp = TEMA.handen.monster.hard_tygel.aterstall
	for _ = 1, math.ceil((glapp + 0.5) / DT) do
		UgnetaTema.steg(sess, DT, { uppsutten = true, hjalper = {} })
	end
	local tredje = tygeltag(sess)
	prova("tre tag med ett långt glapp emellan är ingen vana", tredje == nil,
		("(serie %d efter %s s tystnad)"):format(serie(sess, "hard_tygel"),
			tostring(glapp + 0.5)))
end

--[[ ══ 5. COOLDOWNEN ════════════════════════════════════════════════ ]]
print("\n── 5. Sju sekunders cooldown, utan kö ──")
do
	local sess = UgnetaTema.ny("handen")
	UgnetaTema.steg(sess, DT, ram({ tygel = 0.40 }))
	tygeltag(sess); tygeltag(sess)
	local forsta = tygeltag(sess)
	prova("första kommentaren kommer", forsta ~= nil)
	local t0 = sess.tid

	--[[ Ett HELT nytt mönster direkt efteråt. Mönsterdatan får uppdateras
	     — men ingen kommentar får komma, och ingen får ligga och vänta. ]]
	local under = nil
	tygeltag(sess); tygeltag(sess)
	under = tygeltag(sess)
	prova("ett nytt fullgott mönster under cooldownen är tyst", under == nil,
		("(t = %.2f s)"):format(sess.tid - t0))

	--[[ INGEN KÖ. Sju sekunders tystnad, bildruta för bildruta, utan en
	     enda ny signal. Kommer det en fördröjd kommentar syns den här. ]]
	local kvarglomd = nil
	local steg = 0
	while sess.tid - t0 < TEMA.COOLDOWN + 1.0 do
		local r = UgnetaTema.steg(sess, DT, { uppsutten = true, hjalper = {} })
		if r then kvarglomd = r end
		steg += 1
	end
	prova("och den spelas aldrig upp senare — ingen kö", kvarglomd == nil,
		("(%d tysta bildrutor, %.2f s)"):format(steg, sess.tid - t0))

	--[[ EFTER cooldownen ska ett NYTT mönster höras igen. ]]
	tygeltag(sess); tygeltag(sess)
	local efter = tygeltag(sess)
	prova("efter cooldownen hörs ett nytt mönster", efter ~= nil,
		("(%s vid %.2f s)"):format(if efter then efter.nyckel else "tyst",
			sess.tid - t0))

	--[[ MONOTON OCH BILDRUTEOBEROENDE: samma sak på 144 Hz. ]]
	local snabb = UgnetaTema.ny("handen")
	local DT2 = 1 / 144
	UgnetaTema.steg(snabb, DT2, ram({ tygel = 0.40 }))
	for _ = 1, 3 do
		UgnetaTema.steg(snabb, DT2, ram({ tygel = 0.80 }))
		UgnetaTema.steg(snabb, DT2, ram({ tygel = 0.40 }))
	end
	local cd144 = snabb.cdTill - snabb.tid
	prova("cooldownen är lika lång på 144 Hz som på 30 Hz",
		math.abs(cd144 - TEMA.COOLDOWN) < 0.02,
		("(%.3f s kvar)"):format(cd144))
end

--[[ ══ 6. DUBBLETTEN ════════════════════════════════════════════════ ]]
print("\n── 6. Samma händelse-ID räknas en gång ──")
do
	local sess = UgnetaTema.ny("handen")
	UgnetaTema.steg(sess, DT, ram({ tygel = 0.40 }), "p0")
	UgnetaTema.steg(sess, DT, ram({ tygel = 0.80 }), "p1")
	prova("ett nytt paket räknas", serie(sess, "hard_tygel") == 1,
		("(serie %d)"):format(serie(sess, "hard_tygel")))
	UgnetaTema.steg(sess, DT, ram({ tygel = 0.40 }), "p2")
	UgnetaTema.steg(sess, DT, ram({ tygel = 0.80 }), "p1")
	prova("men SAMMA paket-id igen räknas inte", serie(sess, "hard_tygel") == 1,
		("(serie %d)"):format(serie(sess, "hard_tygel")))
	UgnetaTema.steg(sess, DT, ram({ tygel = 0.80 }), "p3")
	prova("ett NYTT id räknas igen", serie(sess, "hard_tygel") == 2,
		("(serie %d)"):format(serie(sess, "hard_tygel")))
	--[[ Tiden går ändå. En dubblett tystar utvärderingen, den stoppar inte
	     klockan — annars hade en spammande server frusit cooldownen. ]]
	local fore = sess.tid
	UgnetaTema.steg(sess, DT, ram({ tygel = 0.80 }), "p1")
	prova("och tiden går även under en dubblett",
		sess.tid > fore, ("(%.3f -> %.3f)"):format(fore, sess.tid))
end

--[[ ══ 7. ORSAKSSPRÅKET ═════════════════════════════════════════════ ]]
print("\n── 7. Dagsform och ryttarmönster är olika språkfamiljer ──")
do
	local sess = UgnetaTema.ny("handen")
	--[[ Hästen är spänd, handen är lugn. Ingen ryttarsignal alls. ]]
	local dags = nil
	local n = math.ceil((TEMA.DAGSFORM_HALL + 0.5) / DT)
	for _ = 1, n do
		local r = UgnetaTema.steg(sess, DT, ram({ spanning = 0.90 }))
		if r then dags = r end
	end
	prova("en ihållande hög spänning nämns", dags ~= nil,
		("(%s)"):format(if dags then dags.nyckel else "tyst"))
	prova("och den är HÄSTENS dagsform, inte ryttarens fel",
		dags ~= nil and dags.orsak == "dagsform",
		("(orsak %s)"):format(if dags then dags.orsak else "-"))
	prova("dagsformen talar ur familjen ugneta.dagsform.",
		dags ~= nil and string.sub(dags.nyckel, 1, 16) == "ugneta.dagsform.",
		("(%s)"):format(if dags then dags.nyckel else "-"))

	local ryttare = TEMA.handen.monster.hard_tygel
	prova("ryttarens mönster talar ur familjen ugneta.tema.",
		string.sub(ryttare.nyckel, 1, 12) == "ugneta.tema." and ryttare.orsak == "ryttare",
		("(%s · %s)"):format(ryttare.nyckel, ryttare.orsak))
	prova("de två familjerna kan inte råka bli samma nyckel",
		ryttare.nyckel ~= TEMA.handen.dagsform.nyckel,
		("(%s vs %s)"):format(ryttare.nyckel, TEMA.handen.dagsform.nyckel))
	prova("och de två texterna är olika i katalogen",
		Sprak.t(ryttare.nyckel) ~= Sprak.t(TEMA.handen.dagsform.nyckel)
			and Sprak.t(ryttare.nyckel) ~= ryttare.nyckel
			and Sprak.t(TEMA.handen.dagsform.nyckel) ~= TEMA.handen.dagsform.nyckel,
		('("%s" / "%s")'):format(Sprak.t(ryttare.nyckel),
			Sprak.t(TEMA.handen.dagsform.nyckel)))

	--[[ Dagsformen sägs EN gång per pass. Hon ska anpassa sig, inte
	     påminnas var sjunde sekund. ]]
	local igen = nil
	for _ = 1, n * 3 do
		local r = UgnetaTema.steg(sess, DT, ram({ spanning = 0.95 }))
		if r then igen = r end
	end
	prova("dagsformen nämns en gång, inte var sjunde sekund", igen == nil,
		("(%s)"):format(if igen then igen.nyckel else "tyst"))
end

--[[ ══ 9. INGEN LÄCKA MELLAN PASS ════════════════════════════════════ ]]
print("\n── 9. Sessionsdata läcker inte till nästa ritt ──")
do
	local ett = UgnetaTema.ny("handen")
	UgnetaTema.steg(ett, DT, ram({ tygel = 0.40, mjukhet = 0.9, spanning = 0.1 }))
	tygeltag(ett); tygeltag(ett)
	local s1 = UgnetaTema.summering(ett)
	prova("första passet samlade mätvärden",
		s1 ~= nil and #s1.telemetri > 0, ("(%d rader)"):format(#s1.telemetri))

	local tva = UgnetaTema.ny("handen")
	prova("nästa pass börjar på noll bildrutor", tva.ramar == 0)
	prova("...utan serier", next(tva.serie) == nil)
	prova("...utan sedda händelse-ID", next(tva.sedda) == nil)
	prova("...utan mätvärden", next(tva.matt) == nil)
	prova("...utan cooldown", tva.cdTill == 0 and tva.tid == 0)
	prova("...och utan en sagd startreplik", tva.startSagd == false)
	local s2 = UgnetaTema.summering(tva)
	prova("och dess sammanfattning har inga rader att visa",
		s2 ~= nil and #s2.telemetri == 0, ("(%d rader)"):format(#s2.telemetri))
	prova("ett pass utan bildrutor har inget underlag",
		UgnetaTema.harUnderlag(tva) == false)
	prova("men ett pass med bildrutor har det",
		UgnetaTema.harUnderlag(ett) == true, ("(%d ramar)"):format(ett.ramar))
end

--[[ ══ FALSIFIERING ══════════════════════════════════════════════════

	De tre gater som BÄR pedagogiken muteras var för sig, och provet visar
	att mätningen då faller. Utan det här stycket vore de gröna raderna
	ovan bara påståenden om att ingenting hände.

	Kanonen återställs efter varje mutation — resten av specen läser samma
	tabell. ]]
print("\n── Falsifiering ──")
do
	--[[ 1. TEMAFILTRET. Ge Handen sitsens fält och signal: då MÅSTE den
	     kommentera de bildrutor den nyss var tyst om. ]]
	local falt = TEMA.handen.falt
	local signal = TEMA.handen.signal
	local monster = TEMA.handen.monster
	TEMA.handen.falt = { "tygel", "sits", "mjukhet", "spanning" }
	TEMA.handen.signal = {
		tung_sits = TEMA.sitsen.signal.tung_sits,
		lugn_sits = TEMA.sitsen.signal.lugn_sits,
	}
	TEMA.handen.monster = { tung_sits = TEMA.sitsen.monster.tung_sits }
	local sess = UgnetaTema.ny("handen")
	local sagt = nil
	UgnetaTema.steg(sess, DT, ram({ sits = 0.05 }))
	for _ = 1, 3 do
		sagt = UgnetaTema.steg(sess, DT, ram({ sits = 0.90 })) or sagt
		sagt = UgnetaTema.steg(sess, DT, ram({ sits = 0.05 })) or sagt
	end
	prova("MUTATION: släpps sitsen in i Handen kommenteras den — filtret var det som tystade",
		sagt ~= nil, ("(%s)"):format(if sagt then sagt.nyckel else "fortfarande tyst"))
	TEMA.handen.falt, TEMA.handen.signal, TEMA.handen.monster = falt, signal, monster

	--[[ 2. TREMÖNSTRET. Sänk kravet till ett: då kommenteras det FÖRSTA
	     tygeltaget, alltså var tröskeln det som höll tyst. ]]
	local antal = TEMA.handen.monster.hard_tygel.antal
	TEMA.handen.monster.hard_tygel.antal = 1
	local s2 = UgnetaTema.ny("handen")
	UgnetaTema.steg(s2, DT, ram({ tygel = 0.40 }))
	local ett = tygeltag(s2)
	prova("MUTATION: med antal = 1 kommenteras det första taget — tröskeln var gaten",
		ett ~= nil, ("(%s)"):format(if ett then ett.nyckel else "fortfarande tyst"))
	TEMA.handen.monster.hard_tygel.antal = antal

	--[[ 3. COOLDOWNEN. Nolla den: då hörs två mönster i rad. ]]
	local cd = TEMA.COOLDOWN
	TEMA.COOLDOWN = 0
	local s3 = UgnetaTema.ny("handen")
	UgnetaTema.steg(s3, DT, ram({ tygel = 0.40 }))
	tygeltag(s3); tygeltag(s3)
	local a = tygeltag(s3)
	tygeltag(s3); tygeltag(s3)
	local b = tygeltag(s3)
	prova("MUTATION: utan cooldown hörs två mönster i rad — de 7 sekunderna var gaten",
		a ~= nil and b ~= nil,
		("(%s, %s)"):format(if a then "1:a" else "tyst", if b then "2:a" else "tyst"))
	TEMA.COOLDOWN = cd

	--[[ Kanonen är hel igen — resten av sviten läser samma tabell. ]]
	local s4 = UgnetaTema.ny("handen")
	UgnetaTema.steg(s4, DT, ram({ tygel = 0.40 }))
	tygeltag(s4); tygeltag(s4)
	local c = tygeltag(s4)
	tygeltag(s4); tygeltag(s4)
	local d = tygeltag(s4)
	prova("kanonen är återställd efter mutationerna",
		c ~= nil and d == nil and TEMA.COOLDOWN == 7
			and TEMA.handen.monster.hard_tygel.antal == 3,
		("(cd %s · antal %d)"):format(tostring(TEMA.COOLDOWN),
			TEMA.handen.monster.hard_tygel.antal))
end

--[[ ══ KEDJAN: GENOM KLIENTENS EGEN VÄG ═══════════════════════════════

	Allt ovan mäter REGELN. Nedan mäts att spelaren får den — genom
	`init.client.luau`, dess `MountChanged` och dess RenderStepped. ]]
print("\n── Ridhuset, så att gestalten kan placeras ──")
local ridhus
do
	--[[ Två delar räcker: `UgnetaGestalt.plats` löser upp hennes punkt mot
	     "Ridbanan" och "Sarg syd" och behöver inget annat av huset. Att
	     bygga hela anläggningen här hade kopplat den här specen till
	     byggbanken utan att mäta något mer. ]]
	local anlaggning = Instance.new("Folder")
	anlaggning.Name = "Anläggning"
	anlaggning.Parent = workspace
	ridhus = Instance.new("Model")
	ridhus.Name = "UBRF"
	ridhus.Parent = anlaggning
	local bana = Instance.new("Part")
	bana.Name = "Ridbanan"
	bana.Size = Vector3.new(60, 0.18, 196)
	bana.Position = Vector3.new(0, 0, 98)
	bana.Parent = ridhus
	local syd = Instance.new("Part")
	syd.Name = "Sarg syd"
	syd.Size = Vector3.new(60, 4, 0.3)
	syd.Position = Vector3.new(0, 0, 0)
	syd.Parent = ridhus
	prova("bänken har ett ridhus gestalten kan placeras i",
		UgnetaGestalt.plats(ridhus) ~= nil)
end

print("\n── 1. Startrepliken, exakt en gång per giltig lektionsstart ──")
local hast = __makeHastModell("Bamse")
hast.Parent = workspace
--[[ SERVERNS MÄRKE PÅ RITTEN. `HorseService.setRider` sätter `RidSession`
     på modellen FÖRE den fyrar `MountChanged`, och `init.client` läser
     det där. Bänken gör samma sak, så att vakten mot en upprepad
     startreplik mäts på den identitet den faktiskt bär. ]]
hast:SetAttribute("RidSession", "ritt-1")
local STARTTEXT = Sprak.t("ugneta.tema.handen.start")

--[[ Loggens innehåll direkt efter startrepliken. Se noten vid mätningen. ]]
local loggEfterStart = {}

local function raknaStart()
	local n = 0
	for _, b in __BUBBLOR do
		if b.text == STARTTEXT then n += 1 end
	end
	return n
end

do
	prova("startrepliken finns i språkkatalogen och är beställningens mening",
		STARTTEXT == "Idag fokuserar vi på din hand. Rid fram!",
		('("%s")'):format(STARTTEXT))

	Net.get("MountChanged").OnClientEvent:Fire(hast, player)
	prova("uppsittningen startade lektionen", LektionController.pagar() == true)
	prova("Ugneta står i ridhuset", UgnetaGestalt.finns() == true)
	prova("startrepliken sades EN gång", raknaStart() == 1,
		("(%d gånger)"):format(raknaStart()))
	--[[ Loggen läses HÄR och inte längre ned: `sakerhetTarOver` tömmer den
	     vid varje avbruten ritt, och respawnen nedan är en sådan. Att mäta
	     efter den hade mätt städningen, inte spegelingen. ]]
	loggEfterStart = UgnetaBubbla.rader()

	--[[ StateSync-liknande upprepning: samma häst, samma spelare igen.
	     Produktionens `mount` hoppar över den, och ingen ny replik får
	     komma. ]]
	Net.get("MountChanged").OnClientEvent:Fire(hast, player)
	Net.get("MountChanged").OnClientEvent:Fire(hast, player)
	prova("en upprepad MountChanged ger ingen ny startreplik", raknaStart() == 1,
		("(%d gånger)"):format(raknaStart()))

	--[[ RESPAWN. Karaktären försvinner och servern sätter upp henne igen.
	     Ritten avbröts men passet avslutades aldrig — och beställningen är
	     uttrycklig: ingen upprepad startreplik då. ]]
	player.CharacterRemoving:Fire(player.Character)
	Net.get("MountChanged").OnClientEvent:Fire(hast, player)
	prova("och inte heller efter en respawn", raknaStart() == 1,
		("(%d gånger)"):format(raknaStart()))
	prova("men lektionen går igen efter respawnen", LektionController.pagar() == true)

	--[[ ── VAKTENS IDENTITET ÄR SERVERNS, INTE KLIENTENS ─────────────

	     Senior review 2026-09-19, blockerare 4. Vakten bar TEMASTRÄNGEN,
	     alltså ett klientlokalt minne av "vi har hälsat om handen någon
	     gång" — och "handen" är inte en ritt. Den bär nu `RidSession`,
	     serverns eget märke, läst ur modellens attribut av `init.client`.

	     Mätningen ISOLERAR märket: respawnen ovan är ett ogiltigt slut, så
	     `startKvitterad` nollställs inte av den. Det enda som skiljer de
	     två uppsittningarna nedan är alltså vilket märke servern satt.

	     GRÄNSEN, UTTALAD: det här är INTE ett reconnect-prov. En verklig
	     reconnect skapar en ny klient (tomt modulminne) OCH en ny
	     serverritt (nytt märke) — och då SKA hon hälsa, för det är en ny
	     lektion. Bänken har en klient och kan inte skapa den andra.
	     Verklig reconnect är NOT_TESTED, och påstås inte. ]]
	prova("hästen bär serverns rittmärke",
		hast:GetAttribute("RidSession") == "ritt-1",
		("(%s)"):format(tostring(hast:GetAttribute("RidSession"))))

	player.CharacterRemoving:Fire(player.Character)
	hast:SetAttribute("RidSession", "ritt-2")
	Net.get("MountChanged").OnClientEvent:Fire(hast, player)
	prova("ett NYTT rittmärke från servern hälsar igen", raknaStart() == 2,
		("(%d gånger)"):format(raknaStart()))

	--[[ Och samma märke två gånger gör det fortfarande inte. Utan den här
	     raden hade mätningen ovan kunnat vara grön för att vakten slutat
	     fungera helt i stället för att den bytt identitet. ]]
	player.CharacterRemoving:Fire(player.Character)
	Net.get("MountChanged").OnClientEvent:Fire(hast, player)
	prova("men samma märke två gånger hälsar inte", raknaStart() == 2,
		("(%d gånger)"):format(raknaStart()))
end

--[[ ══ 10. SAMMA REPLIK PÅ BÅDA YTORNA ═══════════════════════════════ ]]
print("\n── 10. BubbleChat och den lokala loggen får samma replik ──")
do
	local sista = __BUBBLOR[#__BUBBLOR]
	prova("repliken gick till en bubbla i världen", sista ~= nil,
		("(%d bubblor)"):format(#__BUBBLOR))
	prova("och den hängdes på Ugnetas ansikte, inte på hästen",
		sista ~= nil and sista.del ~= nil and sista.del.Name == "Ansikte",
		("(%s)"):format(if sista and sista.del then sista.del.Name else "-"))
	prova("den lokala loggen bär SAMMA sträng",
		#loggEfterStart > 0 and loggEfterStart[1] == STARTTEXT,
		('("%s" / "%s")'):format(loggEfterStart[1] or "-", STARTTEXT))
	prova("loggen håller sig till ett litet antal rader",
		#loggEfterStart <= UgnetaBubbla.MAX_RADER,
		("(%d av högst %d)"):format(#loggEfterStart, UgnetaBubbla.MAX_RADER))
	prova("loggen tar aldrig emot input",
		UgnetaBubbla.ram() ~= nil and UgnetaBubbla.ram().Active == false)
	--[[ SÄKERHET FÖRE UNDERVISNING, också här: respawnen ovan tömde
	     loggen. En replik om en häst spelaren inte sitter på ska inte bli
	     stående. ]]
	prova("och en avbruten ritt tömmer den", #UgnetaBubbla.rader() == 0,
		("(%d rader kvar)"):format(#UgnetaBubbla.rader()))
end

print("\n── Bubbelchatten når hela banan, och lämnas tillbaka ──")
do
	local i = UgnetaBubbla.installning()
	prova("bubbelchatten är påslagen — den är AVSTÄNGD som standard",
		i ~= nil and i.Enabled == true)
	prova("räckvidden är kanonens mätta tal, inte Roblox 100 studs",
		i ~= nil and i.MaxDistance == UgnetaTema.BUBBEL_AVSTAND,
		("(%s studs)"):format(tostring(i and i.MaxDistance)))
	prova("och minimeringen följde med — annars blir texten en prick",
		i ~= nil and i.MinimizeDistance == UgnetaTema.BUBBEL_MINIMERING,
		("(%s studs)"):format(tostring(i and i.MinimizeDistance)))

	--[[ ── DEN GLOBALA BIEFFEKTEN ÄR LEKTIONSLÅNG ─────────────────────

	     `BubbleChatConfiguration` är en singleton och räckvidden går inte
	     att sätta per bubbla — se `UgnetaBubbla`s modulhuvud. Det enda som
	     KAN begränsas är hur länge den gäller, och det mäts här: efter en
	     auktoritativ avsittning ska klienten ha exakt de värden den hade
	     innan lektionen.

	     Avsittningen nedan är serverns egen (`MountChanged` utan ryttare).
	     Ingen sammanfattning öppnas av den: passet har noll ridna
	     bildrutor, och ett pass utan underlag får ingen ruta. Den regeln
	     mäts för sig i `ugneta-summering.spec`. ]]
	Net.get("MountChanged").OnClientEvent:Fire(hast, nil)
	local efter = UgnetaBubbla.installning()
	prova("efter avsittningen är räckvidden spelarens egen igen",
		efter ~= nil and efter.MaxDistance == 100 and efter.MinimizeDistance == 40,
		("(%s / %s studs)"):format(tostring(efter and efter.MaxDistance),
			tostring(efter and efter.MinimizeDistance)))
	prova("och bubbelchatten är avstängd igen, som den var",
		efter ~= nil and efter.Enabled == false,
		("(Enabled %s)"):format(tostring(efter and efter.Enabled)))

	--[[ Och den går att slå på igen. Utan den här raden vore rättelsen
	     ovan bara en avstängning som råkade mätas som en återställning. ]]
	Net.get("MountChanged").OnClientEvent:Fire(hast, player)
	local igen = UgnetaBubbla.installning()
	prova("nästa lektion sätter räckvidden på nytt",
		igen ~= nil and igen.MaxDistance == UgnetaTema.BUBBEL_AVSTAND
			and igen.Enabled == true,
		("(%s studs · Enabled %s)"):format(tostring(igen and igen.MaxDistance),
			tostring(igen and igen.Enabled)))
end

--[[ ══ 11. LOOKAT RÖR INGEN AUKTORITET ═══════════════════════════════ ]]
print("\n── 11. LookAt är ren klientpresentation ──")
do
	local ugneta = workspace:FindFirstChild("Ugneta")
	prova("gestalten finns i workspace", ugneta ~= nil)
	local nav = UgnetaGestalt.navPunkt()
	prova("hon har ett nav att vridas kring", nav ~= nil)

	--[[ ALLT hon består av ska vara förankrat och genomsläppligt. En del
	     som varken är `Anchored` eller `CanCollide = false` hade kunnat
	     knuffa en häst — och en oförankrad del är precis den sortens
	     modell servern och klienten kan börja slåss om ägarskapet till. ]]
	local alltForankrat, allaGenom = true, true
	for _, d in ugneta:GetChildren() do
		if d.ClassName == "Part" then
			if d.Anchored ~= true then alltForankrat = false end
			if d.CanCollide ~= false then allaGenom = false end
		end
	end
	prova("varje del är förankrad — ingen nätverkskamp om modellen",
		alltForankrat)
	prova("och ingen del kolliderar med hästen", allaGenom)

	local hastCF = hast.PrimaryPart and hast.PrimaryPart.CFrame
	local hastPos = hastCF and hastCF.Position
	local fore = UgnetaGestalt.yaw()
	local intentFore = #Net.get("RidingIntent")._skickat
	local syncFore = #Net.get("StateSync")._skickat
	local avsittFore = #Net.get("DismountRequest")._skickat

	UgnetaGestalt.blickMot(Vector3.new(nav.X + 40, 0, nav.Z + 40), 1 / 60)
	local efter = UgnetaGestalt.yaw()
	prova("hon börjar vrida sig mot målet", efter ~= fore,
		("(%.4f -> %.4f rad)"):format(fore, efter))

	--[[ MJUKT, inte ett hopp: en bildruta får inte ta henne hela vägen. ]]
	prova("och hon hoppar inte dit på en bildruta",
		math.abs(efter - UgnetaGestalt.malYaw()) > 1e-4,
		("(%.4f av %.4f rad)"):format(efter, UgnetaGestalt.malYaw()))

	for _ = 1, 240 do UgnetaGestalt.blickMot(nil, 1 / 60) end
	prova("men hon kommer fram till slut",
		math.abs(UgnetaGestalt.yaw() - UgnetaGestalt.malYaw()) < 1e-3,
		("(%.4f av %.4f rad)"):format(UgnetaGestalt.yaw(), UgnetaGestalt.malYaw()))

	--[[ INGEN TELEPORT. Navet är oförändrat efter 240 bildrutors vridning. ]]
	local nav2 = UgnetaGestalt.navPunkt()
	prova("hon har inte flyttat sig en enda stud",
		math.abs(nav2.X - nav.X) < 1e-6 and math.abs(nav2.Z - nav.Z) < 1e-6
			and math.abs(nav2.Y - nav.Y) < 1e-6,
		("(%.3f,%.3f,%.3f)"):format(nav2.X, nav2.Y, nav2.Z))
	local nuCF = hast.PrimaryPart and hast.PrimaryPart.CFrame
	prova("och hästen står kvar där servern satte henne",
		hastPos ~= nil and nuCF ~= nil
			and math.abs(nuCF.Position.X - hastPos.X) < 1e-6
			and math.abs(nuCF.Position.Z - hastPos.Z) < 1e-6)
	--[[ INGEN TRAFIK. Ridningen äger `RidingIntent`, `StateSync` och
	     `DismountRequest`; blicken får inte röra någon av dem. Räknat FÖRE
	     och EFTER de 240 bildrutorna ovan, så att mätningen gäller just
	     vridningen och inte sessionen i stort. ]]
	prova("blicken skickade ingenting till servern",
		#Net.get("RidingIntent")._skickat == intentFore
			and #Net.get("StateSync")._skickat == syncFore
			and #Net.get("DismountRequest")._skickat == avsittFore,
		("(intent %d->%d · sync %d->%d · avsittning %d->%d)"):format(
			intentFore, #Net.get("RidingIntent")._skickat,
			syncFore, #Net.get("StateSync")._skickat,
			avsittFore, #Net.get("DismountRequest")._skickat))
end

print("")
if fel == 0 then
	print("Alla mätningar gick igenom.")
else
	print(("%d FEL"):format(fel))
end
