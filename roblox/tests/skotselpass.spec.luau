--!nostrict
--[[
	SKÖTSELN OCH PASSET — First Playable, issue #161, provat utan Studio.

	Specen mäter de moduler som FAKTISKT kör i spelet: `Preparation` med sin
	momentlayer, `Pass`, `Sparning` och `SparService` mot en stubbad
	`DataStoreService`. Den bygger ingen egen kopia av fasordningen, av
	eftervården eller av sparschemat — gjorde den det vore varje prov här
	grönt även om servern gjorde något helt annat.

	VAD SOM PROVAS ÄR NEJEN. Ett skötselsystem som bara provats med rätt
	tryck i rätt ordning har inte provats alls: hela värdet ligger i att
	fel häst, fel ordning, dubbeltryck, för långt avstånd och en skadad
	häst FALLER. Därför är merparten av fallen nedan negativa, och varje
	positivt fall finns för att visa att spärren inte är på hela tiden.

	Vad specen INTE når står i PR-texten under Not tested: allt som kräver
	ett riktigt DataStore, en riktig klient och riktiga avstånd i en värld.
	Den här filen kan visa att REGLERNA håller, inte att Roblox
	datalagerkvot räcker en fredagskväll.

	Kör: python3 roblox/tests/build.py tests/skotselpass.spec.luau
	     && luau roblox/tests/.build/skotselpass.spec.luau
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

--[[ Utför en hel fas genom den RIKTIGA momentvägen, ett moment i taget.
	Samma hjälpare som `forberedelse.spec.luau` — se noten där om varför
	den inte får vara ett enda anrop. ]]
local function gorFas(state, fasId, hastId)
	--[[ #162: nejen bär numera (nyckel, argument). Hjälparen SKICKAR VIDARE
		argumentet — annars tappade provet det värde som säger VILKET fynd
		som stoppade arbetet, och en generisk nyckel hade passerat. ]]
	local ok, skal, arg = Preparation.provaSteg(state, fasId, hastId)
	if not ok then return false, skal, arg end
	while true do
		local m = Preparation.nastaMoment(state, fasId)
		if not m then break end
		local mok, mskal, marg = Preparation.utforMoment(state, fasId, m.id, hastId)
		if not mok then return false, mskal, marg end
	end
	return true, nil
end

local function gorAllt(state, hastId)
	for _, f in ipairs(Preparation.stegFaser()) do
		local ok, skal = gorFas(state, f.id, hastId)
		if not ok then return false, f.id .. ": " .. tostring(skal) end
	end
	return true, nil
end

print("\n── Momenten kommer ur skötselkanonen ──")
do
	--[[ Krav: ingen hårdkodad parallell lista i Luau. Momenten ska HÄRLEDAS
		ur `UBRFSkotsel`, alltså ur src/spel/skotsel.js. Proven nedan läser
		kanonen och kräver att momentlistan följer den — lägger någon till en
		visitpunkt i JS-källan utan att momenten följer med, faller det här. ]]
	local vis = Preparation.moment("visitera")
	check("visitationen har ett moment per kanonisk punkt",
		#vis == #UBRFSkotsel.visitation.punkter,
		#vis .. " moment mot " .. #UBRFSkotsel.visitation.punkter .. " punkter")

	local idn = {}
	for _, m in ipairs(vis) do table.insert(idn, m.id) end
	local vantat = {}
	for _, p in ipairs(UBRFSkotsel.visitation.punkter) do
		table.insert(vantat, "vis:" .. p.id)
	end
	check("och i kanonens ordning, framifrån och bakåt",
		table.concat(idn, ",") == table.concat(vantat, ","),
		table.concat(idn, " → "))

	local hals = Preparation.moment("halsa")
	check("hälsningen har ett alternativ per kanonisk framgång",
		#hals == #UBRFSkotsel.halsning, #hals .. " st")
	local felAlt = 0
	for _, m in ipairs(hals) do if m.fel then felAlt += 1 end end
	check("exakt ett hälsningsalternativ är fel", felAlt == 1, felAlt .. " st")

	local iordning = Preparation.moment("iordning")
	check("iordningställandet är fyra hovar plus utrustningen",
		#iordning == #UBRFSkotsel.hovar + #UBRFSkotsel.sadelfaser,
		#iordning .. " moment")
	check("hovarna kommer före utrustningen",
		iordning[1].id == "hov:" .. UBRFSkotsel.hovar[1].id
			and iordning[#iordning].id == "utr:" .. #UBRFSkotsel.sadelfaser,
		iordning[1].id .. " … " .. iordning[#iordning].id)

	--[[ HÄSTKUNSKAP, inte layout. Huvudet får bara den mjuka borsten, och
		det syns som att det bara finns ETT huvudmoment och att det ligger
		under den mjuka borstens redskaps-id. ]]
	local rykt = Preparation.moment("rykta")
	local huvud = {}
	for _, m in ipairs(rykt) do
		if m.id:match(":huvud$") then table.insert(huvud, m.id) end
	end
	check("huvudet ryktas bara med ett redskap", #huvud == 1,
		table.concat(huvud, ", "))
	check("och det redskapet är den mjuka borsten", huvud[1] == "rykt:mjuk:huvud",
		tostring(huvud[1]))
end

print("\n── Bypass: en fas går inte att kvittera med ett tryck ──")
do
	--[[ DET HÄR ÄR SKIVANS KÄRNA. Före #161 fanns
		`Preparation.utfor(state, fasId, hastId)` och den kvitterade en hel
		fas. En klient som fick anropa den kunde göra i ordning en häst på
		fem anrop utan att röra ett enda moment.

		Funktionen ska inte finnas kvar. Ett prov som bara mätte att
		momenten fungerar hade varit grönt även om genvägen låg kvar bredvid
		dem. ]]
	check("den fas-kvitterande genvägen finns inte längre",
		Preparation.utfor == nil,
		"Preparation.utfor = " .. tostring(Preparation.utfor))

	--[[ ...och inte heller i tjänsten. `GameplayService.utfor(player, fasId)`
		var den som faktiskt låg på en RemoteFunction. ]]
	check("och inte heller i GameplayService",
		GameplayService.utfor == nil,
		"GameplayService.utfor = " .. tostring(GameplayService.utfor))

	--[[ En fas kan inte heller flaggas klar utan sina moment: `fasKlar`
		läser momenten, inte `klara`. Sätter någon flaggan direkt ska
		uppsittningen ändå säga nej. ]]
	local s = Preparation.nyState("cosmo", 1)
	for _, f in ipairs(Preparation.stegFaser()) do
		s.klara[f.id] = true
	end
	local ok, skal = Preparation.provaUppsittning(s, "cosmo")
	check("en fas som flaggats klar utan moment släpper inte upp någon",
		not ok, tostring(skal))
end

print("\n── Fel häst, fel ordning, dubbeltryck ──")
do
	local s = Preparation.nyState("cosmo", 1)
	local m = Preparation.nastaMoment(s, "halsa")

	local ok1, skal1 = Preparation.utforMoment(s, "halsa", m.id, "air")
	check("moment på fel häst avvisas", not ok1, tostring(skal1))
	check("och flyttar ingenting", Preparation.nastaMoment(s, "halsa").id == m.id)

	--[[ Fel FAS: ryktningen står inte på tur medan hälsningen återstår. ]]
	local ryktM = Preparation.moment("rykta")[1]
	local ok2, skal2 = Preparation.utforMoment(s, "rykta", ryktM.id, "cosmo")
	check("moment i fel fas avvisas", not ok2, tostring(skal2))

	check("rätt moment på rätt häst går",
		(Preparation.utforMoment(s, "halsa", m.id, "cosmo")))

	--[[ Fel MOMENT inom rätt fas: visitationen tas framifrån och bakåt. ]]
	local vis = Preparation.moment("visitera")
	local ok4, skal4 = Preparation.utforMoment(s, "visitera", vis[3].id, "cosmo")
	check("visitpunkt ur ordning avvisas", not ok4, tostring(skal4))
	check("den första punkten går", (Preparation.utforMoment(s, "visitera", vis[1].id, "cosmo")))

	--[[ DUBBELTRYCK. Provas på en visitpunkt, INTE på hälsningen.

		Falsifieringspasset fällde den tidigare versionen: den tryckte
		`halsa1` två gånger, men hälsningen är ett VAL och blir klar av
		första trycket — så andra trycket avvisades av `provaSteg` med
		"redan gjort" på FASEN. Momentspärren gick att ta bort helt utan
		att något blev rött. Visitationen har fem moment och är inte klar
		efter det första, så här är det bara momentspärren som kan säga nej. ]]
	local ok3, skal3 = Preparation.utforMoment(s, "visitera", vis[1].id, "cosmo")
	check("dubbeltryck på samma moment avvisas",
		not ok3 and skal3 == "forb.redan_gjort", tostring(skal3))
	check("dubbeltryck flyttar inte fram fasen", s.klara.visitera == nil)
	check("och nästa moment står kvar på tur",
		Preparation.nastaMoment(s, "visitera").id == vis[2].id,
		Preparation.nastaMoment(s, "visitera").id)
end

print("\n── Ryktningen: redskapsordning spärras, zonordning gör det inte ──")
do
	local s = Preparation.nyState("cosmo", 1)
	gorFas(s, "halsa", "cosmo")
	gorFas(s, "visitera", "cosmo")

	--[[ Kardborsten före gummiskrapan är fel hästkunskap — spärras. ]]
	local ok1, skal1 = Preparation.utforMoment(s, "rykta", "rykt:hard:kropp", "cosmo")
	check("kardborsten före gummiskrapan avvisas", not ok1, tostring(skal1))

	--[[ Den mjuka borsten på huvudet innan skrapan gjort kroppen: samma
		spärr, och det är den som skyddar regeln "huvudet bara med den
		mjuka" från att bli en genväg förbi de andra redskapen. ]]
	local ok2 = Preparation.utforMoment(s, "rykta", "rykt:mjuk:huvud", "cosmo")
	check("mjuka borsten på huvudet först avvisas", not ok2)

	check("gummiskrapan på kroppen går",
		(Preparation.utforMoment(s, "rykta", "rykt:skrapa:kropp", "cosmo")))

	--[[ ...men INOM ett redskap är zonordningen fri. Det är skillnaden
		mellan hästkunskap och pedanteri, och den finns i `steg`. Faller
		det här har någon gjort ordningen total. ]]
	local benForstOk = Preparation.utforMoment(s, "rykta", "rykt:hard:ben", "cosmo")
	check("inom samma redskap är zonordningen fri", benForstOk,
		"kardborste på ben före kropp")
	check("och kroppen går fortfarande efteråt",
		(Preparation.utforMoment(s, "rykta", "rykt:hard:kropp", "cosmo")))
end

print("\n── Välfärdsfyndet stoppar arbetet ──")
do
	--[[ Fyndet är deterministiskt ur häst och pass. Provet letar upp ett
		pass där kanonen faktiskt ger ett fynd i stället för att skriva in
		ett — ett handskrivet fynd hade provat provets tabell, inte
		modulens. ]]
	local hast, passnr = "cosmo", nil
	for p = 2, 60 do
		if Preparation.fyndFor(hast, p) then passnr = p break end
	end
	check("kanonen ger fynd på något pass", passnr ~= nil, "pass " .. tostring(passnr))

	local s = Preparation.nyState(hast, passnr)
	check("staten bär dagens fynd", s.fynd ~= nil, tostring(s.fynd))
	--[[ Determinismen är hela poängen: en spelare som kopplar ner och upp
		igen ska inte kunna rulla om fyndet. ]]
	check("samma häst och pass ger samma fynd",
		Preparation.nyState(hast, passnr).fynd == s.fynd)

	gorFas(s, "halsa", hast)
	--[[ Gå fram till fyndets punkt. ]]
	local traffad = false
	for _, m in ipairs(Preparation.moment("visitera")) do
		local ok = Preparation.utforMoment(s, "visitera", m.id, hast)
		if m.id == "vis:" .. s.fynd then traffad = ok break end
	end
	check("fyndets punkt gick att visitera", traffad)
	check("fyndet är sett men inte rapporterat",
		s.fyndSett == true and s.fyndRapporterat == false)

	--[[ SPÄRREN: inget annat moment går medan fyndet står öppet.

		SKÄLET krävs, inte bara ett nej. Falsifieringspasset fällde en
		tidigare version av de här två raderna: med fyndspärren BORTTAGEN
		var de fortfarande gröna, för `provaSteg` avvisade ryktningen med
		"fel tur" ändå (visitationen var inte klar). Ett nej av fel skäl är
		inget bevis — spärren gick att ta bort utan att något blev rött. ]]
	--[[ #162 lokalisering: nejen går över nätet som SPRÅKNYCKLAR, inte som
		svensk prosa, så att en engelsk spelare får engelska. Provet mäter
		nyckeln — det är kontraktet nu. ]]
	local FYNDSKAL = "forb.oppet_fynd"
	local ok1, skal1 = Preparation.utforMoment(s, "visitera",
		Preparation.moment("visitera")[#UBRFSkotsel.visitation.punkter].id, hast)
	local ok2, skal2 = Preparation.utforMoment(s, "rykta", "rykt:skrapa:kropp", hast)
	check("visitationen går inte vidare med ett öppet fynd",
		not ok1 and skal1 == FYNDSKAL, tostring(skal1))
	check("och ryktningen stoppas AV FYNDET, inte av fasordningen",
		not ok2 and skal2 == FYNDSKAL, tostring(skal2))

	--[[ Fel svar är ett riktigt val som avvisas — det är lärandet. ]]
	local felSvar = nil
	for _, sv in ipairs(Preparation.fyndSvar()) do
		if sv.fel then felSvar = sv.id end
	end
	local ok3, skal3 = Preparation.svaraFynd(s, felSvar)
	check("'det går nog bra idag' avvisas", not ok3, tostring(skal3))
	check("och fyndet står kvar öppet", s.fyndRapporterat == false)

	local rattSvar = nil
	for _, sv in ipairs(Preparation.fyndSvar()) do
		if not sv.fel then rattSvar = sv.id end
	end
	check("'säg till ridläraren' går igenom", (Preparation.svaraFynd(s, rattSvar)))
	check("arbetet är stoppat", s.stoppad ~= nil, tostring(s.stoppad))

	--[[ FAIL-CLOSED. En stoppad häst får inte sättas i arbete, hur mycket
		som än är avbockat, och inte heller genom att fortsätta skötseln. ]]
	check("hästen är inte redo", Preparation.redo(s) == false)

	--[[ Också här krävs SKÄLET. Med välfärdsspärren borttagen ur
		`provaUppsittning` var ett tidigare `not ok4` fortfarande grönt:
		visitationen var ju avbruten, så uppsittningen nekades med
		"Visitera återstår". Provet mätte alltså fasordningen och trodde
		att det mätte välfärden. Falsifieringspasset fällde det. ]]
	local ok4, skal4, arg4 = Preparation.provaUppsittning(s, hast)
	--[[ Välfärdsstoppets mening kommer ur skötselkanonen och skickas med
		prefixet `kanon:` — den är undervisningstext, inte gränssnitt, och
		översätts inte av en agent. Provet kräver därför BÅDE att skälet är
		kanontext och att det är just den här hästens stoppmening: annars
		hade en generisk nyckel kunnat passera som "stoppad av välfärden". ]]
	--[[ Skälet är RAMEN som nyckel (`forb.lararen_tar_over`) och fyndets
		mening ur skötselkanonen som ARGUMENT, taggat `kanon:`. Provet
		kräver båda: en generisk nyckel utan rätt fynd ska inte kunna
		passera som "stoppad av välfärden". ]]
	check("uppsittningen är stängd AV VÄLFÄRDEN, inte av fasordningen",
		not ok4 and skal4 == "forb.lararen_tar_over"
			and Preparation.utanKanonprefix(arg4) == s.stoppad,
		string.format("%s + %s", tostring(skal4), tostring(arg4)))
	local ok5, skal5, arg5 = gorFas(s, "rykta", hast)
	check("skötseln går inte vidare heller", not ok5
		and skal5 == "forb.lararen_tar_over"
		and Preparation.utanKanonprefix(arg5) == s.stoppad,
		string.format("%s + %s", tostring(skal5), tostring(arg5)))

	--[[ Och inte via `provaModell`, som är den väg servern faktiskt går. ]]
	local ok6, skal6, arg6 = Preparation.provaModell(s, hast)
	check("provaModell säger också nej av samma skäl",
		not ok6 and skal6 == "forb.lararen_tar_over"
			and Preparation.utanKanonprefix(arg6) == s.stoppad,
		string.format("%s + %s", tostring(skal6), tostring(arg6)))

	--[[ Det starkaste fallet: en spelare som fått ALLA faser avbockade och
		SEDAN blir stoppad. Nu finns ingen fasordning kvar att förväxla
		spärren med — faller det här är välfärden borta, punkt. ]]
	local t = Preparation.nyState(hast, passnr)
	t.stoppad = "MUTATIONSPROV: hon vilar"
	for _, f in ipairs(Preparation.stegFaser()) do
		for _, m in ipairs(Preparation.moment(f.id)) do
			if not m.fel then
				t.gjorda[f.id] = t.gjorda[f.id] or {}
				t.gjorda[f.id][m.id] = true
			end
		end
		t.klara[f.id] = true
	end
	local ok7, skal7, arg7 = Preparation.provaUppsittning(t, hast)
	check("en fullt förberedd men stoppad häst släpps ändå inte upp",
		not ok7 and skal7 == "forb.lararen_tar_over"
			and Preparation.utanKanonprefix(arg7) == t.stoppad,
		string.format("%s + %s", tostring(skal7), tostring(arg7)))
end

print("\n── Första dagen med Jack är tjänstbar ──")
do
	--[[ Produktbeslutet i docs/FIRST-DAY-HORSE.md ger nybörjaren Jack, och
		#161 kräver att Jack fortfarande MÅSTE gå att rida. Ett fynd på
		första passet hade avslutat tutorialdagen innan spelaren ryktat en
		häst.

		Provet kör alla 33 kanoniska hästar: INGEN av dem får bära ett fynd
		på pass 1. ]]
	local medFynd = {}
	for _, id in ipairs(UBRFSpel.ordning) do
		if Preparation.fyndFor(id, 1) then table.insert(medFynd, id) end
	end
	check("ingen häst har fynd på första passet", #medFynd == 0,
		#UBRFSpel.ordning .. " hästar provade")

	local s = Preparation.nyState("blackrock_jack", 1)
	check("Jacks första dag är fri från fynd", s.fynd == nil)
	local ok, skal = gorAllt(s, "blackrock_jack")
	check("och hela skötseln går att slutföra", ok, tostring(skal))
	check("Jack blir redo att sitta upp på", Preparation.redo(s) == true)

	--[[ ...men fynd ska finnas SENARE, annars är momentet dekoration.
		Provet mäter att kanonen ger fynd på minst en häst inom rimlig tid. ]]
	local senare = 0
	for _, id in ipairs(UBRFSpel.ordning) do
		for p = 2, 10 do
			if Preparation.fyndFor(id, p) then senare += 1 break end
		end
	end
	check("men fynd förekommer på senare pass", senare > 0,
		senare .. " av " .. #UBRFSpel.ordning .. " hästar inom 10 pass")
end

print("\n── Passet: avsittning leder till faktisk eftervård ──")
do
	local p = Pass.nyState("cosmo", Pass.byggId(7, "cosmo", 1))
	check("passet börjar före ritten", p.lage == Pass.LAGE.FORE)

	--[[ Eftervård utan ritt: nej. Annars kunde en spelare bocka av fem
		moment och få ett pass utan att ha suttit upp. ]]
	local ok1, skal1 = Pass.utfor(p, Pass.moment()[1].id)
	check("eftervård utan ritt avvisas", not ok1, tostring(skal1))
	local ok2, skal2 = Pass.farAvsluta(p)
	check("passet går inte att avsluta före ritten", not ok2, tostring(skal2))

	check("uppsittningen startar ritten", (Pass.vidUppsittning(p)))
	local ok3, skal3 = Pass.farAvsluta(p)
	check("passet går inte att avsluta medan man rider", not ok3, tostring(skal3))

	check("avsittningen öppnar eftervården", (Pass.vidAvsittning(p)))
	check("läget är eftervård", p.lage == Pass.LAGE.EFTERVARD)

	local ok4, skal4 = Pass.farAvsluta(p)
	check("passet går INTE att avsluta med eftervård kvar", not ok4, tostring(skal4))

	--[[ Ordningen är kanon: gjorden lossas före sadeln tas av. ]]
	local moment = Pass.moment()
	local ok5, skal5 = Pass.utfor(p, moment[2].id)
	check("eftervård ur ordning avvisas", not ok5, tostring(skal5))

	check("första eftervårdsmomentet går", (Pass.utfor(p, moment[1].id)))
	local ok6 = Pass.utfor(p, moment[1].id)
	check("dubbeltryck i eftervården avvisas", not ok6)

	for i = 2, #moment do
		Pass.utfor(p, moment[i].id)
	end
	check("passet är klart när eftervården är gjord", p.lage == Pass.LAGE.KLART)
	check("och får då avslutas", (Pass.farAvsluta(p)))

	--[[ Dubbel avsittning får inte nollställa eftervården: `dismount` nås
		från E, från karaktärens död och från utloggning. ]]
	local q = Pass.nyState("cosmo", "q")
	Pass.vidUppsittning(q)
	Pass.vidAvsittning(q)
	Pass.utfor(q, moment[1].id)
	Pass.vidAvsittning(q)
	check("en andra avsittning nollställer inte eftervården",
		q.gjorda[moment[1].id] == true and q.lage == Pass.LAGE.EFTERVARD)
end

print("\n── Sparschemat: version, migration och idempotens ──")
do
	local tom, notering = Sparning.migrera(nil)
	check("ingen tidigare save ger en tom", notering == "tom" and tom.pass == 0)

	local trasig, n2 = Sparning.migrera("det här är inte en tabell")
	check("skräp ger noll pass, inte gratis progression",
		n2 == "trasig" and trasig.pass == 0, tostring(n2))

	local framtida, n3 = Sparning.migrera({ v = Sparning.VERSION + 1, pass = 99 })
	check("en NYARE sparfil flaggas som framtida", n3 == "spar.framtida_sparfil", tostring(n3))
	check("och dess passtal tas inte över", framtida.pass == 0, framtida.pass .. " pass")

	--[[ Migrationen ska bära över det den förstår. ]]
	local las = Sparning.migrera({
		v = 1, pass = 3,
		passId = { ["1:cosmo:1"] = 10 },
		forstaDagen = { klar = true, hastId = "blackrock_jack" },
		hastar = { cosmo = { relation = 0.4, skada = { passKvar = 2, vad = "gjord" } } },
	})
	check("passtalet bärs över", las.pass == 3)
	check("första dagen bärs över", las.forstaDagen.klar == true)
	check("hästminnet bärs över", las.hastar.cosmo.skada.passKvar == 2)

	--[[ En UTLÄKT skada skrivs inte tillbaka: sparfilen ska inte samla på
		sig gamla krämpor. ]]
	local utlakt = Sparning.migrera({ v = 1, pass = 1,
		hastar = { cosmo = { relation = 0.2, skada = { passKvar = 0 } } } })
	check("en utläkt skada bärs inte vidare", utlakt.hastar.cosmo.skada == nil)

	--[[ IDEMPOTENSEN. Acceptanskravet "dubbel serverhändelse får inte
		registrera samma pass två gånger". ]]
	local save = Sparning.tom()
	local passId = Pass.byggId(7, "cosmo", 1)
	check("första registreringen räknas", Sparning.registreraPass(save, passId, 1))
	check("passtalet är 1", save.pass == 1, save.pass .. "")
	check("andra registreringen av samma pass räknas INTE",
		not Sparning.registreraPass(save, passId, 2))
	check("passtalet är fortfarande 1", save.pass == 1, save.pass .. "")

	--[[ ...men NÄSTA pass ska räknas. Faller det här har idempotensen
		blivit en spärr mot all progression. ]]
	check("nästa pass får ett eget id och räknas",
		Sparning.registreraPass(save, Pass.byggId(7, "cosmo", 2), 3))
	check("passtalet är 2", save.pass == 2, save.pass .. "")
end

print("\n── Vilan kan inte tvättas bort ──")
do
	local save = Sparning.tom()
	Sparning.satSkada(save, "cosmo", 2, "gjord")
	check("skadan är satt", Sparning.vilar(save, "cosmo") == true)

	--[[ Formen är EXAKT den `Stallet.vilandeHastar` läser. En översättning
		mellan lagren hade varit en tredje sanning om samma sak. ]]
	local vilande = Stallet.vilandeHastar(Sparning.hastminnen(save))
	check("Stallet ser hästen som vilande", vilande.cosmo == true)
	check("och delar inte ut henne",
		Stallet.tilldelaLedig(0, nil, vilande) ~= "cosmo")

	--[[ Samma hål som PR #154 stängde på webben, fast i andra änden: en NY
		skada får inte FÖRKORTA en pågående vila. ]]
	Sparning.satSkada(save, "cosmo", 1, "ben")
	check("en ny kortare skada förkortar inte vilan",
		save.hastar.cosmo.skada.passKvar == 2,
		save.hastar.cosmo.skada.passKvar .. " pass kvar")

	--[[ Nedräkningen hänger på att TID gått, inte på att hästen arbetat.
		Hade den hängt på arbetet vore vilan självupphävande — precis
		`delete ny.skada`-buggen. ]]
	Sparning.raknaNerVila(save)
	check("ett pass senare återstår ett", save.hastar.cosmo.skada.passKvar == 1)
	Sparning.raknaNerVila(save)
	check("två pass senare är hon frisk", Sparning.vilar(save, "cosmo") == false)

	--[[ En rond genom lagret: skadan ska överleva en serialisering. ]]
	local s2 = Sparning.tom()
	Sparning.satSkada(s2, "air", 3, "sadel")
	local tillbaka = Sparning.migrera(Sparning.tillRad(s2))
	check("skadan överlever en rond genom sparformen",
		tillbaka.hastar.air.skada.passKvar == 3)
end

print("\n── Datalagret: fel ger varken krasch eller gratis progression ──")
do
	game:GetService("RunService")._server = true
	local spelare = { Name = "Spar", UserId = 9001 }

	--[[ 1. LÄSFEL. Spelaren ska kunna spela, men INTE spara — annars
		raderar ett tre sekunder långt nätverkshack hennes framsteg. ]]
	__datastore.nollstall()
	__datastore._data["spelare_9001"] = { v = 1, pass = 5 }
	__datastore.felLas = true
	local save = SparService.ladda(spelare)
	check("ett läsfel kraschar inte", type(save) == "table")
	check("och ger noll pass, inte fem", save.pass == 0, save.pass .. " pass")
	check("och stänger av sparningen", SparService.kanSpara(spelare) == false)
	check("läsningen försöktes om", __datastore.forsok.las >= 3,
		__datastore.forsok.las .. " försök")

	--[[ ...och den viktiga följden: den tomma saven skrivs INTE över den
		riktiga. Faller det här raderar ett läsfel spelarens framsteg. ]]
	local skrevs = SparService.skriv(spelare)
	check("en session utan läsning skriver ingenting", skrevs == false)
	check("och den riktiga saven ligger kvar i lagret",
		__datastore._data["spelare_9001"].pass == 5)
	SparService._glomForProv(spelare)

	--[[ 2. NORMALFALL. ]]
	__datastore.nollstall()
	local ny = SparService.ladda(spelare)
	check("en ny spelare får en tom save", ny.pass == 0)
	check("och får spara", SparService.kanSpara(spelare) == true)

	Sparning.registreraPass(ny, Pass.byggId(9001, "cosmo", 1), 1)
	Sparning.markeraForstaDagen(ny, "cosmo")
	check("skrivningen går fram", SparService.skriv(spelare) == true)
	check("och landar i lagret", __datastore._data["spelare_9001"].pass == 1,
		tostring(__datastore._data["spelare_9001"].pass))

	--[[ 3. RECONNECT: pass och hästminne ska finnas kvar. ]]
	SparService._glomForProv(spelare)
	local igen = SparService.ladda(spelare)
	check("passet finns kvar efter reconnect", igen.pass == 1, igen.pass .. " pass")
	check("första dagen är kvar", igen.forstaDagen.klar == true)
	check("och nästa pass är nummer två", Sparning.aktuelltPass(igen) == 2)

	--[[ 4. SKADAN ÖVERLEVER RECONNECT och kan inte ridas bort. ]]
	Sparning.satSkada(igen, "cosmo", 2, "gjord")
	SparService.skriv(spelare)
	SparService._glomForProv(spelare)
	local tredje = SparService.ladda(spelare)
	check("skadan överlever reconnect", Sparning.vilar(tredje, "cosmo") == true)
	check("och StallService ser den",
		Stallet.vilandeHastar(Sparning.hastminnen(tredje)).cosmo == true)

	--[[ 5. DUBBEL SKRIVNING av samma pass: ett pass, inte två. Det är
		samma kvitto som ovan, men nu HELA VÄGEN genom UpdateAsync och
		sammanslagningen — den vägen har sin egen räkning och kunde
		dubbelräkna även om `registreraPass` inte gjorde det. ]]
	local foreDubbel = tredje.pass
	Sparning.registreraPass(tredje, Pass.byggId(9001, "cosmo", 2), 5)
	SparService.skriv(spelare)
	SparService.skriv(spelare)
	SparService._glomForProv(spelare)
	local fjarde = SparService.ladda(spelare)
	check("två skrivningar av samma pass ger ett pass",
		fjarde.pass == foreDubbel + 1,
		fjarde.pass .. " pass, väntat " .. (foreDubbel + 1))

	--[[ 6. SKRIVFEL. Ingen krasch, ingen förlorad läsning, inget påhittat
		pass i lagret. ]]
	__datastore.felSkriv = true
	local forsokFore = __datastore.forsok.skriv
	local misslyckad = SparService.skriv(spelare)
	check("ett skrivfel kraschar inte", misslyckad == false)
	check("och försöktes om", __datastore.forsok.skriv - forsokFore >= 3,
		(__datastore.forsok.skriv - forsokFore) .. " försök")
	__datastore.felSkriv = false

	--[[ 7. INGET DATALAGER ALLS (Studio utan API-åtkomst). Spelet ska gå
		att spela; det ska bara inte spara. ]]
	SparService._glomForProv(spelare)
	SparService._glomButikForProv()
	__datastore.nollstall()
	__datastore.felButik = true
	local utan = SparService.ladda(spelare)
	check("utan datalager kraschar ingenting", type(utan) == "table")
	check("och sparningen är av", SparService.kanSpara(spelare) == false)
	__datastore.felButik = false

	game:GetService("RunService")._server = false
	SparService._glomForProv(spelare)
end

print("\n── Två spelare kan inte dela en häst ──")
do
	--[[ Reservationen ligger i `Stallet`, välfärden bredvid den. Provet
		mäter att de är TVÅ mängder: mjukar någon upp schemakravet får
		välfärden inte följa med. ]]
	local forst = Stallet.tilldelaLedig(1, nil, nil)
	local sedan = Stallet.tilldelaLedig(1, { [forst] = true }, nil)
	check("samma userId får inte samma häst två gånger när den är tagen",
		sedan ~= forst, tostring(forst) .. " → " .. tostring(sedan))

	--[[ Bindningen: två spelare kan inte binda samma MODELL heller. ]]
	local modell = { Name = "Cosmo" }
	local kandidater = { { id = "cosmo", modell = modell } }
	check("första spelaren binder modellen",
		Preparation.valjModell(kandidater, "cosmo", {}) == modell)
	check("andra spelaren får nil, inte samma modell",
		Preparation.valjModell(kandidater, "cosmo", { [modell] = true }) == nil)
end

print("\n── Reconnect mitt i loopen ger inte gratis completion ──")
do
	--[[ Acceptanskravet: "Återanslutning mitt i loopen återställer rätt
		serverstate utan gratis completion."

		Skötselns delframsteg sparas INTE — bara passet gör det. Det är
		medvetet och det är också det säkra hållet: en spelare som kopplar
		ner mitt i ryktningen börjar om med hästen, hon får inte en färdig
		häst. Provet mäter just det. ]]
	game:GetService("RunService")._server = true
	local spelare = { Name = "Halv", UserId = 9002 }
	__datastore.nollstall()
	SparService.ladda(spelare)

	local save = SparService.save(spelare)
	local s = Preparation.nyState("cosmo", Sparning.aktuelltPass(save))
	gorFas(s, "halsa", "cosmo")
	gorFas(s, "visitera", "cosmo")
	check("halvvägs: inte redo", Preparation.redo(s) == false)

	--[[ Passet räknas inte av att skötseln påbörjats. ]]
	SparService.skriv(spelare)
	SparService._glomForProv(spelare)
	local efter = SparService.ladda(spelare)
	check("en avbruten dag räknas inte som ett pass", efter.pass == 0,
		efter.pass .. " pass")

	local ny = Preparation.nyState("cosmo", Sparning.aktuelltPass(efter))
	check("och skötseln börjar om från hälsningen",
		Preparation.nasta(ny).id == "halsa")
	check("ingen fas är gratis avbockad", Preparation.redo(ny) == false)

	game:GetService("RunService")._server = false
	SparService._glomForProv(spelare)
end

print("\n── Hela vägen: en dag från hälsning till sparat pass ──")
do
	--[[ Det positiva fallet, sist. Alla nej ovan är värdelösa om loopen
		inte GÅR att spela igenom — då hade en spärr som alltid säger nej
		varit grön. ]]
	game:GetService("RunService")._server = true
	local spelare = { Name = "Hel", UserId = 9003 }
	__datastore.nollstall()
	SparService.ladda(spelare)
	local save = SparService.save(spelare)

	local hast = "blackrock_jack"
	local s = Preparation.nyState(hast, Sparning.aktuelltPass(save))
	local ok, skal = gorAllt(s, hast)
	check("skötseln går igenom", ok, tostring(skal))
	check("hästen är redo", Preparation.redo(s) == true)
	check("uppsittningen släpps igenom", (Preparation.provaUppsittning(s, hast)))

	local p = Pass.nyState(hast, Pass.byggId(spelare.UserId, hast, Sparning.aktuelltPass(save)))
	Pass.vidUppsittning(p)
	Pass.vidAvsittning(p)
	for _, m in ipairs(Pass.moment()) do
		Pass.utfor(p, m.id)
	end
	check("passet får avslutas", (Pass.farAvsluta(p)))

	Sparning.registreraPass(save, p.passId, 1)
	Sparning.markeraForstaDagen(save, hast)
	Sparning.hojRelation(save, hast, 0.04)
	check("skrivningen går fram", SparService.skriv(spelare) == true)

	SparService._glomForProv(spelare)
	local imorgon = SparService.ladda(spelare)
	check("passet finns kvar i morgon", imorgon.pass == 1, imorgon.pass .. " pass")
	check("första dagen är avklarad", imorgon.forstaDagen.klar == true)
	check("relationen till Jack finns kvar",
		imorgon.hastar[hast] ~= nil and imorgon.hastar[hast].relation > 0,
		tostring(imorgon.hastar[hast] and imorgon.hastar[hast].relation))
	check("och nästa dag är pass två", Sparning.aktuelltPass(imorgon) == 2)

	game:GetService("RunService")._server = false
	SparService._glomForProv(spelare)
end

--[[ ══ BLOCKERARE 1 (#162): PlayerAdded-RACET ═══════════════════════

	ChatGPT:s oberoende review av `6f0c915`: `SparService.start()` kopplar
	`Players.PlayerAdded` och anropar `ladda()`, som YIELDAR i `GetAsync`.
	`StallService.start()` och `GameplayService.start()` kopplade samma
	signal var för sig. Roblox startar varje anslutning på egen tråd, så när
	den första suspenderar körs de andra omedelbart — mot en save som ännu
	är nil. Följden: `hastminnen()` ger nil, en vilande häst kan tilldelas,
	och `passnummer()` faller till 1 alltså "första dagen".

	Startordningen i `init.server.luau` är INGEN barriär. Den bestämmer i
	vilken ordning anslutningarna görs, inte att den första hinner klart.

	Provet nedan mäter fönstret i två steg, och det är hela poängen:
	  · efter `Fire` men FÖRE `slutfor` — där ska ingenting ha hänt ännu,
	  · efter `slutfor` — där ska tilldelningen finnas och vara riktig.
	Med den gamla koden är den första mätningen röd.
]]
do
	print("\n── Blockerare 1: tilldelning får inte ske innan saven laddat ──")
	__datastore.nollstall()
	game:GetService("RunService")._server = true
	local Players = game:GetService("Players")
	Players.PlayerAdded:nollstall()
	--[[ Reservationerna i StallService.tilldelade ligger kvar mellan block
		och räknas då som "upptagna" av nästa provs spelare. Blocken städar
		därför genom PRODUKTIONENS egen väg, `PlayerRemoving`, i stället för
		genom en ny provlucka. Signalen nollställs här av samma skäl som
		PlayerAdded: lyssnarna ackumuleras annars. ]]
	Players.PlayerRemoving:nollstall()
	SparService._glomHookarForProv()
	local spelare = { Name = "Race", UserId = 9101,
		--[[ GameplayService kopplar respawnen i samma andetag som
			ankomsten. Utan signalen kraschar lyssnaren, och en krasch är
			inte samma sak som ett fynd. ]]
		CharacterAdded = { Connect = function() return { Disconnect = function() end } end } }

	--[[ Hästen som `tilldelaLedig` skulle valt UTAN välfärdsfiltret. Den
		räknas fram ur modulen i stället för att skrivas som ett namn här:
		skulle stallets ordning ändras följer provet med. ]]
	local utanFilter = Stallet.tilldelaLedig(spelare.UserId, {}, {})
	check("stallet har en häst att ge", utanFilter ~= nil, tostring(utanFilter))

	--[[ En sparfil som finns i lagret: tre pass avklarade, första dagen
		klar, och just den hästen vilar för en skada. Ligger den läsningen
		efter tilldelningen ser servern ingen av de tre sanningarna. ]]
	local befintlig = Sparning.tom()
	befintlig.pass = 3
	befintlig.forstaDagen = { klar = true, hastId = "blackrock_jack" }
	Sparning.satSkada(befintlig, utanFilter, 2, "sten i hoven")
	__datastore._data["spelare_" .. spelare.UserId] = Sparning.tillRad(befintlig)

	--[[ Läsningen ska göra sin nätverkstur, precis som en riktig GetAsync. ]]
	__datastore.fordrojLas = true

	--[[ Tom spelarlista under start(): annars laddar startens egen
		GetPlayers-loop spelaren i förväg och racet maskeras. ]]
	Players._spelare = {}
	SparService._glomForProv(spelare)
	SparService.start()
	StallService.start()
	GameplayService.start()

	Players._spelare = { spelare }
	Players.PlayerAdded:Fire(spelare)

	--[[ MÄTNING 1 — fönstret. Läsningen är suspenderad; ingenting som beror
		på saven får ha bestämt något ännu. ]]
	check("läsningen är fortfarande i luften", Players.PlayerAdded:harVantande(),
		"suspenderade lyssnare: " .. tostring(Players.PlayerAdded:harVantande()))
	check("ingen häst är tilldelad innan saven laddat",
		StallService.hastFor(spelare) == nil,
		"tilldelad: " .. tostring(StallService.hastIdFor(spelare)))

	--[[ Väck läsningen och låt allt gå klart. ]]
	Players.PlayerAdded:slutfor()

	--[[ MÄTNING 2 — efteråt ska det vara både gjort och riktigt. ]]
	local efter = StallService.hastIdFor(spelare)
	check("en häst är tilldelad när saven laddat", efter ~= nil, tostring(efter))
	check("och det är INTE hästen som vilar för en skada", efter ~= utanFilter,
		("fick %s, vilande %s"):format(tostring(efter), tostring(utanFilter)))
	check("saven som lästes är den som låg i lagret",
		SparService.save(spelare) ~= nil and SparService.save(spelare).pass == 3,
		"pass " .. tostring(SparService.save(spelare) and SparService.save(spelare).pass))

	__datastore.fordrojLas = false
	Players.PlayerRemoving:Fire(spelare)
	Players._spelare = {}
	SparService._glomForProv(spelare)
	game:GetService("RunService")._server = false
end

--[[ ══ KONTROLL: FAIL-SAFE-VÄGEN ÄR ORÖRD ═══════════════════════════

	Barriären får inte råka göra läsfelet till en låsning. Faller läsningen
	på riktigt ska spelaren fortfarande få en häst och kunna spela — bara
	inte spara. Utan den här kontrollen kunde blockerare 1 "lösas" genom att
	vänta för evigt på en save som aldrig kommer.
]]
do
	print("\n── Kontroll: läsfel ger spelbar session utan sparning ──")
	__datastore.nollstall()
	game:GetService("RunService")._server = true
	local Players = game:GetService("Players")
	Players.PlayerAdded:nollstall()
	--[[ Reservationerna i StallService.tilldelade ligger kvar mellan block
		och räknas då som "upptagna" av nästa provs spelare. Blocken städar
		därför genom PRODUKTIONENS egen väg, `PlayerRemoving`, i stället för
		genom en ny provlucka. Signalen nollställs här av samma skäl som
		PlayerAdded: lyssnarna ackumuleras annars. ]]
	Players.PlayerRemoving:nollstall()
	SparService._glomHookarForProv()
	local spelare = { Name = "Lasfel", UserId = 9102,
		--[[ GameplayService kopplar respawnen i samma andetag som
			ankomsten. Utan signalen kraschar lyssnaren, och en krasch är
			inte samma sak som ett fynd. ]]
		CharacterAdded = { Connect = function() return { Disconnect = function() end } end } }

	__datastore.felLas = true
	__datastore.fordrojLas = true
	Players._spelare = {}
	SparService._glomForProv(spelare)
	SparService.start()
	StallService.start()
	GameplayService.start()

	Players._spelare = { spelare }
	Players.PlayerAdded:Fire(spelare)
	Players.PlayerAdded:slutfor()

	check("spelaren fick en häst trots läsfel",
		StallService.hastIdFor(spelare) ~= nil,
		tostring(StallService.hastIdFor(spelare)))
	check("men sessionen sparas inte", SparService.kanSpara(spelare) == false)
	check("och anmärkningen säger varför",
		SparService.anmarkning(spelare) == "spar.lasfel",
		tostring(SparService.anmarkning(spelare)))
	check("ingenting skrevs över i lagret",
		__datastore._data["spelare_" .. spelare.UserId] == nil)

	__datastore.felLas = false
	__datastore.fordrojLas = false
	Players.PlayerRemoving:Fire(spelare)
	Players._spelare = {}
	SparService._glomForProv(spelare)
	game:GetService("RunService")._server = false
end

--[[ ══ BLOCKERARE 3 (#162): FÖRSTA DAGEN ÄR JACK — I PRODUKTIONEN ══

	ChatGPT:s addendum: den riktiga vägen är
	`StallService.tilldela` → `Stallet.dagensHast` → `Stallet.tilldelaLedig`,
	och den sista väljer ur `userId % #Spel.ordning`. Den fick varken saven
	eller `Sparning.forstaDagen(save)`. En ny spelare kunde alltså få vilken
	häst som helst, och produktkravet "ny spelare → Jack" var inte uppfyllt.

	Det positiva provet längre upp bygger `Preparation.nyState("blackrock_jack")`
	för HANDEN — det bevisar att loopen fungerar OM Jack redan valts, inte
	att produktionen väljer honom. Det här provet börjar i stället från en
	TOM save och går genom tjänsterna.

	Tre mätningar, och den tredje är den som gör de två första ärliga:
	  1. ny spelare får Jack,
	  2. när första dagen är avklarad är hon INTE längre låst till Jack,
	  3. vilar Jack för en skada blir det VÄNTELÄGE — ingen ersättare, ingen
	     kringgången välfärdsspärr. Utan den kunde "tvinga Jack" ha
	     implementerats som ett hopp över reservationen.

	UserId 9103 är valt så att rotationens naturliga val INTE är Jack
	(9103 % 33 = 28 → `replay`). Vore det Jack ändå kunde mätning 1 bli
	grön utan att någon regel fanns. ]]
do
	print("\n── Blockerare 3: första dagen är Jack, resten är rotationen ──")
	__datastore.nollstall()
	game:GetService("RunService")._server = true
	local Players = game:GetService("Players")
	Players.PlayerAdded:nollstall()
	--[[ Reservationerna i StallService.tilldelade ligger kvar mellan block
		och räknas då som "upptagna" av nästa provs spelare. Blocken städar
		därför genom PRODUKTIONENS egen väg, `PlayerRemoving`, i stället för
		genom en ny provlucka. Signalen nollställs här av samma skäl som
		PlayerAdded: lyssnarna ackumuleras annars. ]]
	Players.PlayerRemoving:nollstall()
	SparService._glomHookarForProv()
	local spelare = { Name = "Nyborjare", UserId = 9103,
		CharacterAdded = { Connect = function() return { Disconnect = function() end } end } }

	local rotationen = Stallet.tilldelaLedig(spelare.UserId, {}, {})
	check("rotationens naturliga val är någon annan än Jack",
		rotationen ~= nil and rotationen ~= "blackrock_jack", tostring(rotationen))

	--[[ Tomt lager: ingen rad för spelaren alls. Det är en helt ny spelare. ]]
	Players._spelare = {}
	SparService._glomForProv(spelare)
	SparService.start()
	StallService.start()
	GameplayService.start()
	Players._spelare = { spelare }
	Players.PlayerAdded:Fire(spelare)
	Players.PlayerAdded:slutfor()

	check("saven är tom, alltså är det första dagen",
		SparService.save(spelare) ~= nil
			and Sparning.forstaDagen(SparService.save(spelare)) == true)
	check("och den riktiga vägen delar ut JACK",
		StallService.hastIdFor(spelare) == "blackrock_jack",
		tostring(StallService.hastIdFor(spelare)))

	--[[ Första dagen avklarad — då släpper tvånget. ]]
	local save = SparService.save(spelare)
	Sparning.markeraForstaDagen(save, "blackrock_jack")
	local imorgon = StallService.tilldela(spelare)
	check("när första dagen är avklarad tvingas inte Jack längre",
		imorgon ~= nil and imorgon.id ~= "blackrock_jack",
		tostring(imorgon and imorgon.id))
	check("och det är rotationens val hon får",
		imorgon ~= nil and imorgon.id == rotationen,
		("fick %s, rotationen ger %s"):format(
			tostring(imorgon and imorgon.id), tostring(rotationen)))

	Players.PlayerRemoving:Fire(spelare)
	Players._spelare = {}
	SparService._glomForProv(spelare)
	game:GetService("RunService")._server = false
end

--[[ ══ KONTROLL: JACK SOM VILAR GER VÄNTELÄGE, INTE ERSÄTTARE ═══════

	#161: *"Första dagen med Jack ska bevaras som produktregel, men Jack
	måste fortfarande vara tjänstbar."* Och #162: *"Do not silently
	substitute another horse … use an explicit unavailable/wait state."*

	Samma svar som webben ger i `visaIngenHastIdag` sedan #154. Utan den
	här mätningen vore ett hopp över reservationen en grön lösning. ]]
do
	print("\n── Kontroll: vilar Jack blir det vänteläge, inte en annan häst ──")
	__datastore.nollstall()
	game:GetService("RunService")._server = true
	local Players = game:GetService("Players")
	Players.PlayerAdded:nollstall()
	--[[ Reservationerna i StallService.tilldelade ligger kvar mellan block
		och räknas då som "upptagna" av nästa provs spelare. Blocken städar
		därför genom PRODUKTIONENS egen väg, `PlayerRemoving`, i stället för
		genom en ny provlucka. Signalen nollställs här av samma skäl som
		PlayerAdded: lyssnarna ackumuleras annars. ]]
	Players.PlayerRemoving:nollstall()
	SparService._glomHookarForProv()
	local spelare = { Name = "Jackvilar", UserId = 9104,
		CharacterAdded = { Connect = function() return { Disconnect = function() end } end } }

	--[[ Ny spelare — utom att Jack redan bär en skada i hennes minne. ]]
	local rad = Sparning.tom()
	Sparning.satSkada(rad, "blackrock_jack", 2, "sten i hoven")
	__datastore._data["spelare_" .. spelare.UserId] = Sparning.tillRad(rad)

	Players._spelare = {}
	SparService._glomForProv(spelare)
	SparService.start()
	StallService.start()
	GameplayService.start()
	Players._spelare = { spelare }
	Players.PlayerAdded:Fire(spelare)
	Players.PlayerAdded:slutfor()

	check("det är fortfarande första dagen",
		Sparning.forstaDagen(SparService.save(spelare)) == true)
	check("Jack vilar", Sparning.vilar(SparService.save(spelare), "blackrock_jack") == true)
	check("ingen häst delas ut — spelaren får vänta",
		StallService.hastIdFor(spelare) == nil,
		tostring(StallService.hastIdFor(spelare)))

	Players.PlayerRemoving:Fire(spelare)
	Players._spelare = {}
	SparService._glomForProv(spelare)
	game:GetService("RunService")._server = false
end

--[[ ══ RE-REVIEW AV 2a8938e: TVÅ VÄGAR FÖRBI BARRIÄREN ═════════════

	ChatGPT:s omreview: barriären höll på `PlayerAdded`, men två vägar gick
	fortfarande runt den.

	  1. `StallService.start()` och `GameplayService.start()` itererade
	     `Players:GetPlayers()` och tilldelade/band direkt. En spelare kan
	     ha anlänt medan SparService läste — då är hennes laddning kvar i
	     luften när nästa tjänst startar, och startloopen sprang förbi.
	  2. `MinHast.OnServerInvoke` gjorde `tilldelade[player] or tilldela(...)`.
	     Ett tidigt klientanrop tilldelade alltså också mot `save == nil`.

	Och kritiken mot mitt eget prov var riktig: det satte
	`Players._spelare = {}` under starten, just för att inte maskera racet —
	men därmed kunde det aldrig se startloopen.

	Här är spelaren INNE i `GetPlayers()` medan `GetAsync` är suspenderad. ]]
do
	print("\n── Re-review: startloop och MinHast går inte förbi barriären ──")
	__datastore.nollstall()
	game:GetService("RunService")._server = true
	local Players = game:GetService("Players")
	Players.PlayerAdded:nollstall()
	Players.PlayerRemoving:nollstall()
	SparService._glomHookarForProv()
	local spelare = { Name = "Startloop", UserId = 9105,
		CharacterAdded = { Connect = function() return { Disconnect = function() end } end } }

	local utanFilter = Stallet.tilldelaLedig(spelare.UserId, {}, {})
	local rad = Sparning.tom()
	rad.pass = 5
	rad.forstaDagen = { klar = true, hastId = "blackrock_jack" }
	Sparning.satSkada(rad, utanFilter, 2, "sten i hoven")
	__datastore._data["spelare_" .. spelare.UserId] = Sparning.tillRad(rad)
	__datastore.fordrojLas = true

	--[[ 1. SparService startar utan någon inne. ]]
	Players._spelare = {}
	SparService._glomForProv(spelare)
	SparService.start()

	--[[ 2. Spelaren ANLÄNDER. Läsningen suspenderar, och hookregistret är
		ännu tomt — de andra tjänsterna har inte startat. ]]
	Players._spelare = { spelare }
	Players.PlayerAdded:Fire(spelare)
	check("läsningen är i luften", Players.PlayerAdded:harVantande())
	check("och spelaren är inte redo än", SparService.redo(spelare) == false,
		"redo: " .. tostring(SparService.redo(spelare)))

	--[[ 3. NU startar de andra, med spelaren redan i GetPlayers. Det här är
		fönstret omreviewen pekade ut. ]]
	StallService.start()
	GameplayService.start()
	check("startloopen tilldelar ingen häst förbi barriären",
		StallService.hastFor(spelare) == nil,
		"tilldelad: " .. tostring(StallService.hastIdFor(spelare)))

	--[[ 4. Tidigt MinHast-anrop, den andra vägen runt. ]]
	local minHast = nil
	for _, b in ipairs(game:GetService("ReplicatedStorage")._barn) do
		if b.Name == "MinHast" then minHast = b end
	end
	check("MinHast finns att fråga", minHast ~= nil and minHast.OnServerInvoke ~= nil)
	check("MinHast svarar nil innan laddningen landat",
		minHast.OnServerInvoke(spelare) == nil,
		tostring(minHast.OnServerInvoke(spelare)))
	check("och frågan tilldelade ingen häst heller",
		StallService.hastFor(spelare) == nil,
		"tilldelad: " .. tostring(StallService.hastIdFor(spelare)))

	--[[ 5. Läsningen landar. Nu ska allt ha hänt, och hänt rätt. ]]
	Players.PlayerAdded:slutfor()
	check("spelaren är redo när laddningen nått slutläge",
		SparService.redo(spelare) == true)
	local efter = StallService.hastIdFor(spelare)
	check("hooken tilldelade hästen då", efter ~= nil, tostring(efter))
	check("och det är INTE hästen som vilar", efter ~= utanFilter,
		("fick %s, vilande %s"):format(tostring(efter), tostring(utanFilter)))
	check("saven som lästes är den som låg i lagret",
		SparService.save(spelare).pass == 5,
		"pass " .. tostring(SparService.save(spelare).pass))
	check("MinHast svarar nu med hästen",
		minHast.OnServerInvoke(spelare) ~= nil)

	__datastore.fordrojLas = false
	Players.PlayerRemoving:Fire(spelare)
	Players._spelare = {}
	SparService._glomForProv(spelare)
	game:GetService("RunService")._server = false
end

--[[ ══ KONTROLL: EN FALLERAD LADDNING BLIR REDO, INTE LÅST ═══════════

	Omreviewen är uttrycklig: *"Do not deadlock failed loads; failed/no-store
	sessions must become ready with kanSpara=false and remain playable."*

	Utan den här mätningen kunde barriären "lösas" genom att aldrig släppa
	igenom en spelare vars datalager är nere — ett race utbytt mot en
	låsning, vilket är sämre. ]]
do
	print("\n── Kontroll: utan datalager blir spelaren redo och spelbar ──")
	__datastore.nollstall()
	game:GetService("RunService")._server = true
	local Players = game:GetService("Players")
	Players.PlayerAdded:nollstall()
	Players.PlayerRemoving:nollstall()
	SparService._glomHookarForProv()
	local spelare = { Name = "Ingenbutik", UserId = 9106,
		CharacterAdded = { Connect = function() return { Disconnect = function() end } end } }

	--[[ Studio utan API-åtkomst: `GetDataStore` självt kastar. ]]
	__datastore.felButik = true
	SparService._glomButikForProv()

	Players._spelare = {}
	SparService._glomForProv(spelare)
	SparService.start()
	StallService.start()
	GameplayService.start()
	Players._spelare = { spelare }
	Players.PlayerAdded:Fire(spelare)
	Players.PlayerAdded:slutfor()

	check("spelaren blev redo trots att datalagret saknas",
		SparService.redo(spelare) == true)
	check("hon fick en häst och kan spela",
		StallService.hastIdFor(spelare) ~= nil,
		tostring(StallService.hastIdFor(spelare)))
	check("men sessionen sparas inte", SparService.kanSpara(spelare) == false)
	check("och anmärkningen säger varför",
		SparService.anmarkning(spelare) == "spar.inget_datalager",
		tostring(SparService.anmarkning(spelare)))

	__datastore.felButik = false
	SparService._glomButikForProv()
	Players.PlayerRemoving:Fire(spelare)
	Players._spelare = {}
	SparService._glomForProv(spelare)
	game:GetService("RunService")._server = false
end

-- Sen laddning efter utloggning får inte återskapa save eller reservation.
-- Samma produktionssignaler som vid ankomst; inga direkta stateändringar.
do
	__datastore.nollstall()
	game:GetService("RunService")._server = true
	local Players = game:GetService("Players")
	Players.PlayerAdded:nollstall()
	Players.PlayerRemoving:nollstall()
	SparService._glomHookarForProv()
	Players._spelare = {}
	local p = { Name = "LamnarUnderLasning", UserId = 99101,
		CharacterAdded = { Connect = function() return { Disconnect = function() end } end } }
	SparService._glomForProv(p)
	SparService.start()
	StallService.start()
	GameplayService.start()
	__datastore.fordrojLas = true
	Players._spelare = {p}
	Players.PlayerAdded:Fire(p)
	check("utloggningsprovet har en pågående läsning", Players.PlayerAdded:harVantande())
	Players._spelare = {}
	Players.PlayerRemoving:Fire(p)
	Players.PlayerAdded:slutfor()
	check("sent svar publicerar ingen save", SparService.save(p) == nil)
	check("utloggad spelare blir inte redo", not SparService.redo(p))
	check("utloggad spelare får ingen häst", StallService.hastIdFor(p) == nil)
	__datastore.fordrojLas = false
	local ny = { Name = "NastaSpelare", UserId = 99102,
		CharacterAdded = p.CharacterAdded }
	Players._spelare = {ny}
	Players.PlayerAdded:Fire(ny)
	Players.PlayerAdded:slutfor()
	check("nästa spelare kan få Jack", StallService.hastIdFor(ny) == "blackrock_jack")
	Players.PlayerRemoving:Fire(ny)
	Players._spelare = {}
	game:GetService("RunService")._server = false
end

--[[ ══ OMREVIEW AV caac3f5, FYND 1: VILAN RÄKNAS NER I LAGRET ══════

	`GameplayService.avslutaPass` anropar `Sparning.raknaNerVila(save)` och
	sedan `SparService.skriv`. Enhetsprovet på `raknaNerVila` är grönt — men
	det provar bara funktionen, inte vägen genom `UpdateAsync`.

	I sammanslagningen vinner den LÄNGSTA vilan:

	    if m.skada and (not fanns.skada or m.skada.passKvar > fanns.skada.passKvar)

	Lagret har 2, minnet har 1 efter nedräkningen — och 1 > 2 är falskt, så
	lagrets 2 vinner. `sparade[player] = bas` skriver sedan tillbaka 2 i
	minnet också. Samma villkor gör att 1 → nil aldrig går fram: att `skada`
	SAKNAS i minnet kan inte rensa en lagrad skada.

	Följden i drift: en häst vilar för evigt. Det är värre än buggen #154
	stängde, för den gick åtminstone att rida sig ur.

	Provet går HELA vägen: seedad rad → ladda → räkna ner → skriv →
	glöm → ladda igen. ]]
do
	print("\n── Omreview fynd 1: vilan ska räknas ner i själva lagret ──")
	__datastore.nollstall()
	game:GetService("RunService")._server = true
	local spelare = { Name = "Vila", UserId = 9201 }
	SparService._glomForProv(spelare)

	--[[ Lagret har en häst som vilar två pass. ]]
	local rad = Sparning.tom()
	Sparning.satSkada(rad, "cosmo", 2, "sten i hoven")
	__datastore._data["spelare_" .. spelare.UserId] = Sparning.tillRad(rad)

	local save = SparService.ladda(spelare)
	check("laddad med två pass kvar",
		save.hastar.cosmo ~= nil and save.hastar.cosmo.skada ~= nil
			and save.hastar.cosmo.skada.passKvar == 2,
		"passKvar " .. tostring(save.hastar.cosmo and save.hastar.cosmo.skada
			and save.hastar.cosmo.skada.passKvar))

	--[[ Ett pass rids och avslutas: nedräkningen sker i minnet, sedan skrivs
		den. Exakt ordningen i `GameplayService.avslutaPass`. ]]
	Sparning.raknaNerVila(save)
	check("minnet räknade ner till ett pass",
		save.hastar.cosmo.skada ~= nil and save.hastar.cosmo.skada.passKvar == 1,
		"passKvar " .. tostring(save.hastar.cosmo.skada
			and save.hastar.cosmo.skada.passKvar))
	check("skrivningen gick fram", SparService.skriv(spelare) == true)

	SparService._glomForProv(spelare)
	local igen = SparService.ladda(spelare)
	check("LAGRET har ett pass kvar, inte två",
		igen.hastar.cosmo ~= nil and igen.hastar.cosmo.skada ~= nil
			and igen.hastar.cosmo.skada.passKvar == 1,
		"passKvar " .. tostring(igen.hastar.cosmo and igen.hastar.cosmo.skada
			and igen.hastar.cosmo.skada.passKvar))

	--[[ Andra passet: 1 → 0 → skadan ska bort ur lagret. ]]
	Sparning.raknaNerVila(igen)
	check("minnet är fritt från skada", igen.hastar.cosmo.skada == nil)
	check("skrivningen gick fram igen", SparService.skriv(spelare) == true)

	SparService._glomForProv(spelare)
	local sista = SparService.ladda(spelare)
	check("skadan är BORTA ur lagret",
		sista.hastar.cosmo == nil or sista.hastar.cosmo.skada == nil,
		"skada " .. tostring(sista.hastar.cosmo and sista.hastar.cosmo.skada
			and sista.hastar.cosmo.skada.passKvar))

	SparService._glomForProv(spelare)
	game:GetService("RunService")._server = false
end

--[[ ══ OMREVIEW FYND 2: EN NYARE SPARFIL FÅR INTE SKRIVAS ÖVER ═══════

	Läsningen behandlar `migrera(...) == "framtida"` som icke-skrivbar och
	sätter `kanSpara = false`. `UpdateAsync`-callbacken gör INTE det:

	    local bas = select(1, Sparning.migrera(gammal))

	Anteckningen kastas. Läste den här servern en giltig v1-rad, och en
	nyare server skrev ett framtida schema innan vår nästa skrivning, så
	konverterar callbacken den framtida raden till en TOM v1-save och
	slår in vår gamla session i den. Filhuvudets egen utfästelse — *"en
	gammal server ska inte skriva över en nyare sparfil den inte förstår"* —
	gäller alltså bara vid inloggningen, inte vid skrivningen. ]]
do
	print("\n── Omreview fynd 2: framtida sparfil skrivs inte över ──")
	__datastore.nollstall()
	game:GetService("RunService")._server = true
	local spelare = { Name = "Framtid", UserId = 9202 }
	SparService._glomForProv(spelare)

	--[[ En vanlig v1-rad läses in och är skrivbar. ]]
	local rad = Sparning.tom()
	rad.pass = 4
	__datastore._data["spelare_" .. spelare.UserId] = Sparning.tillRad(rad)
	local save = SparService.ladda(spelare)
	check("sessionen är skrivbar", SparService.kanSpara(spelare) == true)
	check("och har fyra pass", save.pass == 4, tostring(save.pass))

	--[[ En NYARE server hinner före oss. ]]
	local framtida = Sparning.tillRad(rad)
	framtida.v = Sparning.VERSION + 1
	framtida.pass = 9
	framtida.nyttFalt = "något vi inte förstår"
	__datastore._data["spelare_" .. spelare.UserId] = framtida

	SparService.skriv(spelare)

	local kvar = __datastore._data["spelare_" .. spelare.UserId]
	check("den framtida raden ligger kvar orörd",
		kvar ~= nil and kvar.v == Sparning.VERSION + 1,
		"v " .. tostring(kvar and kvar.v))
	check("och dess pass är inte sänkta till våra",
		kvar ~= nil and kvar.pass == 9, "pass " .. tostring(kvar and kvar.pass))
	check("det okända fältet finns kvar",
		kvar ~= nil and kvar.nyttFalt == "något vi inte förstår",
		tostring(kvar and kvar.nyttFalt))

	--[[ Omreviewen ber uttryckligen om att sessionstillståndet efter
		konflikten redovisas. Sessionen blir icke-skrivbar och bär skälet —
		samma beslut som läsningen tar för en framtida rad. ]]
	check("sessionen är inte längre skrivbar",
		SparService.kanSpara(spelare) == false)
	check("och anmärkningen säger framtida",
		SparService.anmarkning(spelare) == "spar.framtida_sparfil",
		tostring(SparService.anmarkning(spelare)))

	SparService._glomForProv(spelare)
	game:GetService("RunService")._server = false
end

--[[ ══ OMREVIEW: BÅDA EGENSKAPERNA, INTE BARA DEN ENA ════════════════

	*"Do not simply switch `max` to `min`… both properties must hold: stale
	writes cannot heal a new injury, and legitimate rest progression can
	persist."*

	Provet ovan visade den andra. Det här visar den FÖRSTA, och det är den
	som en `min`-regel hade gått sönder på: en gammal server, med en session
	som läste innan skadan fanns, försöker skriva. Lagret har hunnit före.
	Skrivningen får inte läka hästen.

	RUNDA 4: kravet är detsamma, utgången är en annan. Förut avbröts
	skrivningen — vilket bevarade skadan men låste sessionen (se blocket
	längre ned). Nu basar den om på den färska raden, och den färska skadan
	ska stå kvar ändå. Provet mäter alltså EGENSKAPEN (ingen läkning), inte
	mekanismen, och vår session bär med flit en hästminnesrad UTAN skada —
	det är precis den bild som en `min`-regel hade låtit skriva över. ]]
do
	print("\n── Omreview: en gammal server får inte läka en färsk skada ──")
	__datastore.nollstall()
	game:GetService("RunService")._server = true
	local spelare = { Name = "Gammal", UserId = 9203 }
	SparService._glomForProv(spelare)

	--[[ Servern läser en rad UTAN skada. ]]
	local rad = Sparning.tom()
	rad.pass = 2
	__datastore._data["spelare_" .. spelare.UserId] = Sparning.tillRad(rad)
	local save = SparService.ladda(spelare)
	check("vår session ser ingen skada",
		save.hastar.cosmo == nil or save.hastar.cosmo.skada == nil)

	--[[ En NYARE server sätter en skada och skriver — revisionen stiger. ]]
	local nyare = Sparning.migrera(__datastore._data["spelare_" .. spelare.UserId])
	Sparning.satSkada(nyare, "cosmo", 3, "hälta bak")
	nyare.rev = save.rev + 1
	__datastore._data["spelare_" .. spelare.UserId] = Sparning.tillRad(nyare)

	--[[ Vår gamla session har en bild av cosmo UTAN skada, och skriver. ]]
	Sparning.hojRelation(save, "cosmo", 0.2)
	check("vår bild av cosmo saknar skada",
		save.hastar.cosmo ~= nil and save.hastar.cosmo.skada == nil)
	local skrevs = SparService.skriv(spelare)
	check("skrivningen går fram", skrevs == true, tostring(skrevs))

	local kvar = Sparning.migrera(__datastore._data["spelare_" .. spelare.UserId])
	check("den färska skadan finns kvar i lagret — ingen läkning",
		kvar.hastar.cosmo ~= nil and kvar.hastar.cosmo.skada ~= nil
			and kvar.hastar.cosmo.skada.passKvar == 3,
		"passKvar " .. tostring(kvar.hastar.cosmo and kvar.hastar.cosmo.skada
			and kvar.hastar.cosmo.skada.passKvar))
	check("och skälet följde med, inte bara talet",
		kvar.hastar.cosmo.skada.vad == "hälta bak",
		tostring(kvar.hastar.cosmo.skada.vad))
	check("revisionen ligger förbi den nyare serverns",
		kvar.rev == save.rev + 2, "rev " .. tostring(kvar.rev))

	SparService._glomForProv(spelare)
	game:GetService("RunService")._server = false
end

--[[ ══ OMREVIEW FYND 3: ETT RÄKNAT PASS BER INTE OM UPPSITTNING ══════

	ChatGPT:s omreview av `caac3f5`: `Pass.markeraRaknat` sätter
	`lage = "recorded"`, men klientens panel kände bara igen `"aftercare"`.
	`recorded` föll därför igenom till skötselvyn — och där är
	förberedelsen fortfarande komplett, så rubriken blev
	**"Klar — du kan sitta upp"**. Samtidigt nekar serverns egen grind
	`GameplayService.farSittaUpp` samma spelare med
	**"Du har redan ridit idag"**, eftersom `lage ~= before_ride`.

	Grinden är rätt. Det var PRESENTATIONEN som ljög, och en First Playable
	får aldrig be spelaren om något servern uttryckligen nekar.

	Provet mäter BÅDA sidorna av motsägelsen på samma spelare, i tre steg:

	  1. BASLINJEN — med passet i `before_ride` säger servern JA och
	     klienten "Klar — du kan sitta upp". Utan det här steget mätte
	     provet ingenting: en rubrik som aldrig visats kunna säga
	     "sitta upp" faller inte av att felet kommer tillbaka.
	  2. Passet rids och avslutas genom `GameplayService.avslutaPass`,
	     alltså serverns riktiga väg, med de sparningar den gör.
	  3. MÄTNINGEN — samma spelare får nu NEJ av grinden, och de vyer
	     servern FAKTISKT skickade matas in i klientens riktiga
	     `PreparationSync`/`PassSync`-lyssnare. Panelen får inte längre
	     nämna uppsittning.

	Provet bygger ingen egen vy och ingen egen rubrik: payloaden kommer ur
	`_skickat` på fjärrobjektet, och rubriken läses med
	`PreparationController._rubrik()`, alltså det HUD:en ritade.

	Bänkgräns: `CollectionService:GetInstanceAddedSignal` i stubbarna
	dispatchar inte, så riggens ankomst kan inte fjärra hooken i
	`GameplayService.start()`. Provet anropar därför `GameplayService.bind`
	direkt — exakt den funktion hooken anropar — och att hooken är kopplad
	står oprovad här. Avståndsregeln kan heller inte prövas utan karaktär,
	så eftervårdens moment körs genom `Pass.utfor`, samma modulfunktion som
	`GameplayService.eftervard` anropar efter sin närvarokontroll.
]]
do
	print("\n── Fynd 3: ett räknat pass får inte be om uppsittning ──")
	__datastore.nollstall()
	game:GetService("RunService")._server = true
	local Players = game:GetService("Players")
	Players.PlayerAdded:nollstall()
	Players.PlayerRemoving:nollstall()
	SparService._glomHookarForProv()

	local spelare = { Name = "Fynd3", UserId = 9303,
		CharacterAdded = { Connect = function() return { Disconnect = function() end } end } }

	Players._spelare = {}
	SparService._glomForProv(spelare)
	SparService.start()
	StallService.start()
	GameplayService.start()

	Players._spelare = { spelare }
	Players.PlayerAdded:Fire(spelare)

	local hastId = StallService.hastIdFor(spelare)
	check("spelaren har en tilldelad häst", hastId ~= nil, tostring(hastId))

	--[[ Riggen står i världen med rätt identitet. ]]
	local modell = Instance.new("Model")
	modell.Name = "Hast"
	modell:SetAttribute("HorseId", hastId)
	game:GetService("CollectionService"):AddTag(modell, "Horse")
	GameplayService.bind(spelare)
	check("modellen är bunden", GameplayService.modellFor(spelare) == modell)

	--[[ Hela förberedelsen, moment för moment genom den riktiga regeln. ]]
	local st = GameplayService.stateFor(spelare)
	check("tjänsten håller ett förberedelsetillstånd", st ~= nil)
	for _, f in ipairs(Preparation.stegFaser()) do
		local ok, skal = gorFas(st, f.id, hastId)
		check("fasen " .. f.id .. " går att göra", ok, tostring(skal))
	end

	--[[ ── 1. BASLINJEN ───────────────────────────────────────────
		Servern säger ja, och klientens panel ska säga det samma. ]]
	local okFore, skalFore = GameplayService.farSittaUpp(spelare, modell)
	check("servern släpper upp en förberedd spelare", okFore, tostring(skalFore))

	local prepSync = Networking.get("PreparationSync")
	local passSync = Networking.get("PassSync")
	local hello = Networking.get("PreparationHello")

	--[[ Handskakningen genom klientens riktiga `start()`. Stubbens
		`InvokeServer` svarar `true`, så den kopplas till serverns riktiga
		`OnServerInvoke` — samma funktion nätet hade nått. ]]
	hello.InvokeServer = function()
		return hello.OnServerInvoke(spelare)
	end
	PreparationController.start()

	check("klienten fick sin häst i handskakningen",
		PreparationController.hastId() == hastId,
		tostring(PreparationController.hastId()))
	check("BASLINJE: panelen bjuder in till uppsittning när passet inte är ridet",
		PreparationController._rubrik() == "Klar — du kan sitta upp",
		"rubrik: " .. PreparationController._rubrik())

	--[[ ── 2. PASSET RIDS OCH AVSLUTAS ────────────────────────────
		Lägesbytena är modulens egna; det är dem `GameplayService` driver
		från uppsittningen, avsittningen och eftervårdens moment. ]]
	local p = GameplayService.passFor(spelare)
	check("tjänsten håller ett pass", p ~= nil)
	local okUpp, skalUpp = Pass.vidUppsittning(p)
	check("uppsittningen tas emot", okUpp, tostring(skalUpp))
	local okAv, skalAv = Pass.vidAvsittning(p)
	check("avsittningen tas emot", okAv, tostring(skalAv))

	--[[ Eftervården ska nu stå i panelen, med sina moment att trycka på.
		Serverns passvy hämtas genom handskakningen — samma väg en klient
		som anslutit mitt i eftervården går, och den ENDA vägen i bänken
		som får servern att skicka en passvy utan avståndsprövning.

		De synliga raderna mätta HÄR är förutsättningen för mätningen
		längre ned: utan dem vore "inga moment står kvar att trycka på"
		grönt av sig självt, alltså ett krav som inte mäter någonting. ]]
	local foreEftervard = #passSync._skickat
	hello.OnServerInvoke(spelare)
	for i = foreEftervard + 1, #passSync._skickat do
		passSync.OnClientEvent:Fire(passSync._skickat[i][2])
	end
	check("panelen står i eftervården", PreparationController._rubrik() == "Ta hand om henne",
		"rubrik: " .. PreparationController._rubrik())
	check("och har moment att trycka på",
		#PreparationController._synligaMoment() > 0,
		table.concat(PreparationController._synligaMoment(), ", "))

	while true do
		local m = Pass.nastaMoment(p)
		if not m then break end
		local okM, skalM = Pass.utfor(p, m.id)
		check("eftervårdsmomentet " .. m.id .. " går att göra", okM, tostring(skalM))
	end
	check("passet är klart att avsluta", p.lage == Pass.LAGE.KLART, tostring(p.lage))

	local foreP = #prepSync._skickat
	local foreS = #passSync._skickat

	local okSlut, skalSlut = GameplayService.avslutaPass(spelare)
	check("passet avslutas", okSlut, tostring(skalSlut))
	check("och är RÄKNAT i serverns minne", p.lage == Pass.LAGE.RAKNAT, tostring(p.lage))

	--[[ ── 3. MÄTNINGEN ───────────────────────────────────────────
		Först serverns nej — det är den motsägelse presentationen låg fel
		mot, och kravet står och faller med att den finns. ]]
	local okEfter, skalEfter = GameplayService.farSittaUpp(spelare, modell)
	check("servern NEKAR en andra uppsittning samma dag",
		not okEfter and skalEfter == "spel.redan_ridit", tostring(skalEfter))

	--[[ Och så de vyer servern faktiskt skickade, in genom klientens
		riktiga lyssnare i den ordning de gick ut. ]]
	check("servern skickade en ny förberedelsevy", #prepSync._skickat > foreP,
		("%d → %d"):format(foreP, #prepSync._skickat))
	check("servern skickade en ny passvy", #passSync._skickat > foreS,
		("%d → %d"):format(foreS, #passSync._skickat))

	local sistaPass = passSync._skickat[#passSync._skickat][2]
	check("passvyn bär läget recorded", sistaPass.lage == "recorded",
		tostring(sistaPass.lage))

	for i = foreP + 1, #prepSync._skickat do
		prepSync.OnClientEvent:Fire(prepSync._skickat[i][2])
	end
	for i = foreS + 1, #passSync._skickat do
		passSync.OnClientEvent:Fire(passSync._skickat[i][2])
	end

	--[[ KRAVET. Tas `passRaknat()`-grenen ur `PreparationController.rita`
		faller vyn igenom till skötseln, där förberedelsen fortfarande är
		komplett, och rubriken blir baslinjens "Klar — du kan sitta upp"
		igen. Det är mutationen som ska fälla det här. ]]
	local rubrikEfter = PreparationController._rubrik()
	check("panelen säger att passet är klart och sparat",
		rubrikEfter == "Passet är klart och sparat", "rubrik: " .. rubrikEfter)
	check("och nämner inte uppsittning någonstans",
		not string.find(rubrikEfter, "sitta upp", 1, true), "rubrik: " .. rubrikEfter)
	check("inga moment står kvar att trycka på",
		#PreparationController._synligaMoment() == 0,
		table.concat(PreparationController._synligaMoment(), ", "))

	Players.PlayerRemoving:Fire(spelare)
	Players._spelare = {}
	SparService._glomForProv(spelare)
	game:GetService("RunService")._server = false
end

--[[ ══ RUNDA 4, P1: KONFLIKTEN FÅR INTE LÅSA SESSIONEN ═══════════════

	ChatGPT:s omreview av `3b0e84d`: revisionsspärren avbryter riktigt när
	lagret hunnit före, men den avancerar inte `laddadRev` och lämnar
	`kanSpara` sann. Nästa `UpdateAsync` läser samma högre `bas.rev` mot
	samma gamla `laddadRev` och avbryter igen — för alltid. Sessionen kunde
	alltså tro att den sparade medan ingenting gick fram.

	Provet nedan mäter det som saknades: att nästa läge är BESTÄMT. Inte
	bara att den färska skadan finns kvar, utan att sessionen kommer vidare.

	Regeln som gör det möjligt utan att gissa:

	  · lagret står på samma revision som vi läste ⇒ ingen annan har
	    skrivit, minnet ÄR den senaste sanningen, och minnet äger vilan
	    (det är fynd 1 och nedräkningen hänger på det),
	  · lagret står HÖGRE ⇒ någon annan skrev efter vår läsning. Då basar
	    vi om på den FÄRSKA raden och slår bara ihop det som är monotont
	    (kvitton, passtal, relation, första dagen). För vilan väljs den
	    LÄNGSTA, för vi vet inte vems som är färskast — och att korta en
	    vila på en gissning vore att släppa ut en halt häst, medan att
	    förlänga den kostar ett pass.

	Ombaseringen är begränsad till ett enda försök inne i samma
	`UpdateAsync`: den läser färskt, slår ihop, skriver en gång. Ingen
	omkörningsslinga, ingen väntan.
]]
do
	print("\n── Runda 4: konflikten basar om i stället för att låsa ──")
	__datastore.nollstall()
	game:GetService("RunService")._server = true
	local spelare = { Name = "Rebas", UserId = 9204 }
	local nyckel = "spelare_" .. spelare.UserId
	SparService._glomForProv(spelare)

	--[[ Lagret: två pass, ingen skada. Vår session läser den raden. ]]
	local rad = Sparning.tom()
	rad.pass = 2
	__datastore._data[nyckel] = Sparning.tillRad(rad)
	local save = SparService.ladda(spelare)
	local lastRev = save.rev

	--[[ Vår session gör dagens pass: ett kvitto och en höjd relation. Det
		är progression som INTE får gå förlorad av en konflikt. ]]
	Sparning.registreraPass(save, "pass-rebas-1", 1000)
	Sparning.hojRelation(save, "cosmo", 0.5)

	--[[ En NYARE server sätter en skada och skriver. Revisionen stiger. ]]
	local nyare = Sparning.migrera(__datastore._data[nyckel])
	Sparning.satSkada(nyare, "cosmo", 3, "hälta bak")
	nyare.rev = lastRev + 1
	__datastore._data[nyckel] = Sparning.tillRad(nyare)

	--[[ Vår skrivning möter konflikten. ]]
	local skrevs1 = SparService.skriv(spelare)
	check("skrivningen går fram genom en säker ombasering", skrevs1 == true,
		tostring(skrevs1))

	local kvar = Sparning.migrera(__datastore._data[nyckel])
	check("den nyare serverns färska skada är BEVARAD",
		kvar.hastar.cosmo ~= nil and kvar.hastar.cosmo.skada ~= nil
			and kvar.hastar.cosmo.skada.passKvar == 3,
		"passKvar " .. tostring(kvar.hastar.cosmo and kvar.hastar.cosmo.skada
			and kvar.hastar.cosmo.skada.passKvar))
	check("vårt kvitto följde med", kvar.passId["pass-rebas-1"] ~= nil)
	--[[ Och passet räknades EN gång. Arbetsordern 2026-09-10 kräver det
		uttryckligen: en ombasering som adderar vårt kvitto till en färsk rad
		får inte också ta med minnets passtal och räkna dagen två gånger.
		Lagret stod på 2, vi la ett kvitto → 3. ]]
	check("passet räknades en gång, inte två", kvar.pass == 3,
		"pass " .. tostring(kvar.pass))
	check("och relationen vi byggde",
		kvar.hastar.cosmo ~= nil and kvar.hastar.cosmo.relation >= 0.5,
		tostring(kvar.hastar.cosmo and kvar.hastar.cosmo.relation))
	check("revisionen steg FÖRBI den nyare serverns",
		kvar.rev == lastRev + 2, "rev " .. tostring(kvar.rev))

	--[[ DET DETERMINISTISKA NÄSTA LÄGET. Med den gamla koden låg sessionen
		kvar på sin gamla `laddadRev` och varje följande skrivning avbröts
		på nytt. Här ska nästa skrivning i samma session gå fram. ]]
	Sparning.hojRelation(SparService.save(spelare), "cosmo", 0.1)
	local skrevs2 = SparService.skriv(spelare)
	check("nästa skrivning i samma session går också fram", skrevs2 == true,
		tostring(skrevs2))
	check("sessionen är fortfarande skrivbar",
		SparService.kanSpara(spelare) == true)

	local kvar2 = Sparning.migrera(__datastore._data[nyckel])
	check("och den andra skrivningen räknade inte passet igen", kvar2.pass == 3,
		"pass " .. tostring(kvar2.pass))
	check("och skadan står kvar även efter den andra skrivningen",
		kvar2.hastar.cosmo ~= nil and kvar2.hastar.cosmo.skada ~= nil
			and kvar2.hastar.cosmo.skada.passKvar == 3,
		"passKvar " .. tostring(kvar2.hastar.cosmo and kvar2.hastar.cosmo.skada
			and kvar2.hastar.cosmo.skada.passKvar))

	--[[ KONTRAST: en FRAMTIDA rad är fortfarande terminal. Den ska INTE
		basas om — vi förstår inte schemat och får inte röra raden. Utan
		den här kontrollen kunde ombaseringen ha svalt fynd 2. ]]
	__datastore._data[nyckel] = { v = 99, rev = 500, framtidaFalt = "okänt" }
	local skrevs3 = SparService.skriv(spelare)
	check("en framtida rad basas INTE om", skrevs3 == false, tostring(skrevs3))
	check("sessionen blev icke-skrivbar av den framtida raden",
		SparService.kanSpara(spelare) == false)
	check("och anmärkningen säger framtida",
		SparService.anmarkning(spelare) == "spar.framtida_sparfil",
		tostring(SparService.anmarkning(spelare)))
	local orord = __datastore._data[nyckel]
	check("den framtida raden ligger orörd",
		orord.v == 99 and orord.framtidaFalt == "okänt",
		"v " .. tostring(orord.v) .. " fält " .. tostring(orord.framtidaFalt))

	SparService._glomForProv(spelare)
	game:GetService("RunService")._server = false
end

if fails > 0 then
	error(("skotselpass.spec: %d fel"):format(fails))
end
print("\nskotselpass.spec: alla gröna")
