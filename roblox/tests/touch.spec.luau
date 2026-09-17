--!nostrict
--[[
	Mätningar på pekkontrakten.

	Gesterna går inte att köra utanför Studio, men allt under dem gör det:
	spakens kurva är en ren funktion, och `Input` är en ren tillståndsmaskin.
	Det som mäts här är alltså precis det review 02 kräver bevis för — att
	tre spaklägen ger tre skilda avsikter, att ett släpp nollar, och att
	tangent och gamepad inte regredierar.

	Kör: python3 roblox/tests/build.py tests/touch.spec.luau
	     && luau roblox/tests/.build/touch.spec.luau
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

local R = TouchControls.RADIE

--[[ Nollställ mellan mätningarna: Input är en modul med delat tillstånd. ]]
--[[ ══ EN STYRD KLOCKA ═══════════════════════════════════════════════

     DRIV och BROMS har en spärr på `Input.IMPULS_SPARR` sekunder, och den
     är hela poängen med impulsmodellen: ett tryck ska vara EN hjälp, inte
     tre steg i trappan för den som hamrar.

     En spärr som bara går att mäta med riktig tid går bara att mäta åt ett
     håll — att andra trycket stoppas. Att det SLÄPPS IGENOM när tiden gått
     hade krävt att sviten sover 0,6 s per mätning. Klockan är därför
     utbytbar i `Input`, och provet flyttar den själv. ]]
local klocka = 1000.0
Input._klocka = function() return klocka end
local function ticka(sekunder: number)
	klocka += sekunder
end
--[[ Ett steg längre fram än spärren, så nästa impuls garanterat går in. ]]
local function efterSparren()
	ticka(Input.IMPULS_SPARR + 0.01)
end

local function nollstall()
	Input.unbind()
	__setStick(nil)
	Input.bind()
	--[[ `bind` nollar spärren till `-math.huge`; klockan flyttas ändå
	     framåt så att inget prov ärver föregående provs tidslinje. ]]
	efterSparren()
end

print("\n── Spaken är analog, inte fyra knappar i en cirkel ──")
do
	--[[ Kravet ur reviewen: 25, 50 och 100 % vågrätt utslag ska ge tre
	     monotont skilda styrvärden. Samma tre nivåer webben mäter med
	     riktiga pekhändelser. ]]
	local rader = {}
	for _, andel in { 0.25, 0.50, 1.00 } do
		local _, steer = TouchControls.axis(R * andel, 0, R)
		table.insert(rader, { andel = andel, steer = steer })
	end
	print("  spakutslag   styravsikt")
	for _, r in rader do
		print(string.format("  %3d %%        %.4f", r.andel * 100, r.steer))
	end
	check("tre spaklägen ger tre monotont skilda avsikter",
		rader[1].steer < rader[2].steer and rader[2].steer < rader[3].steer,
		string.format("(%.4f < %.4f < %.4f)", rader[1].steer, rader[2].steer, rader[3].steer))
	check("fullt utslag ger full avsikt", math.abs(rader[3].steer - 1) < 1e-9,
		string.format("(%.6f)", rader[3].steer))
	--[[ Ett litet utslag ska vara litet. En kurva som ger 0,6 på 25 % är
	     en knapp med rundade hörn. ]]
	check("kvartsutslag är en linjekorrigering, inte en volt",
		rader[1].steer > 0.01 and rader[1].steer < 0.15,
		string.format("(%.4f)", rader[1].steer))
end

print("\n── Tecken, dödzon och diagonal ──")
do
	local _, hoger = TouchControls.axis(R, 0, R)
	local _, vanster = TouchControls.axis(-R, 0, R)
	check("höger är positivt, vänster negativt", hoger > 0 and vanster < 0,
		string.format("(%.3f / %.3f)", hoger, vanster))
	check("vänster speglar höger", math.abs(hoger + vanster) < 1e-9)

	local fram = select(1, TouchControls.axis(0, -R, R))
	local bak = select(1, TouchControls.axis(0, R, R))
	check("uppåt är framåt, nedåt är bakåt", fram > 0 and bak < 0,
		string.format("(%.3f / %.3f)", fram, bak))

	--[[ Dödzonen: tummen darrar, hästen ska inte svara. ]]
	local _, darr = TouchControls.axis(R * 0.05, 0, R)
	check("små darrningar inom dödzonen ger noll", darr == 0,
		string.format("(5 %% utslag → %.6f)", darr))

	--[[ Diagonalen får inte vara snabbare än rakt fram — samma fel som ett
	     oklampat WASD gör. ]]
	local dF, dS = TouchControls.axis(R, -R, R)
	local langd = math.sqrt(dF * dF + dS * dS)
	check("diagonalen är inte snabbare än rakt fram", langd <= 1 + 1e-9,
		string.format("(längd %.4f)", langd))

	check("spak utan radie ger noll i stället för att dela med noll",
		select(1, TouchControls.axis(10, 10, 0)) == 0)
end

print("\n── Släpp nollar båda axlarna på en gång ──")
do
	nollstall()
	Input.setTouch(TouchControls.axis(R * 0.8, -R * 0.8, R))
	local i1 = Input.consume()
	check("spaken når fram till avsikten", math.abs(i1.steer) > 0.1 and i1.forward > 0.1,
		string.format("(forward %.3f, steer %.3f)", i1.forward, i1.steer))
	Input.setTouch(0, 0)
	local i2 = Input.consume()
	check("släppet nollar båda axlarna direkt",
		i2.forward == 0 and i2.steer == 0,
		string.format("(forward %.6f, steer %.6f)", i2.forward, i2.steer))
end

print("\n── Gångart och hopp ──")
do
	nollstall()
	check("DRIV går in", Input.drivImpuls() == true)
	local a = Input.consume()
	local b = Input.consume()
	check("ett tryck uppåt ger exakt ett gångartsbyte",
		a.gaitUp and not b.gaitUp)
	--[[ BROMS direkt efter DRIV ska gå igenom. Spärren är PER HANDLING:
	     att ta tillbaka en hjälp man nyss gav är ridning, att hamra på
	     samma hjälp är det inte. ]]
	check("BROMS går in direkt efter DRIV — spärren är per handling",
		Input.bromsImpuls() == true)
	local c = Input.consume()
	local d = Input.consume()
	check("ett tryck nedåt ger exakt ett gångartsbyte",
		c.gaitDown and not d.gaitDown)
	--[[ Ett tryck ska bäras av exakt en bildruta och sedan vara borta. Utan
	     flanktriggningen skulle en hjälp rusa genom skritt–trav–galopp så
	     länge flaggan låg kvar. ]]
	efterSparren()
	Input.drivImpuls()
	local barande, efterat = 0, 0
	for i = 1, 31 do
		if Input.consume().gaitUp then
			if i == 1 then barande += 1 else efterat += 1 end
		end
	end
	check("ett tryck bärs av exakt en bildruta och sedan inga fler",
		barande == 1 and efterat == 0,
		string.format("(%d bärande, %d extra på 30 följande bildrutor)", barande, efterat))

	Input.touchJump()
	check("hoppknappen tänder hoppet", Input.consume().jump)
	if __senasteDelay then __senasteDelay() end
	check("och släpper det igen", not Input.consume().jump)

	--[[ G02-B: TYGELN OCH PARADEN på pekskärmen.

	     De två har olika natur med flit, och provet är vad som håller dem
	     isär: kontakten är ett TILLSTÅND som ligger kvar så länge fingret
	     ligger på, paraden är en IMPULS som bärs av exakt en bildruta.
	     Byter de plats får man en tygel man knäpper på och en halvhalt
	     man kan hålla inne, och ingetdera är ridning. ]]
	nollstall()
	Input.setTouchRein(1)
	local r1, r2 = Input.consume().rein, Input.consume().rein
	Input.setTouchRein(0)
	local r3 = Input.consume().rein
	check("tygeln HÅLLS: kontakten ligger kvar tills fingret lyfts",
		r1 == 1 and r2 == 1 and r3 == 0,
		string.format("(%.0f, %.0f, sedan %.0f)", r1, r2, r3))
	--[[ Och att den är ANALOG i kontraktet: halva utslaget ska nå fram
	     som halvt. Pekskärmens knapp ger 1, men gamepadens avtryckare är
	     en axel, och det är samma fält de skriver i. ]]
	Input.setTouchRein(0.45)
	check("tygeln är analog hela vägen genom kontraktet",
		math.abs(Input.consume().rein - 0.45) < 1e-6)
	Input.setTouchRein(0)

	Input.touchParad()
	local barandeP, efteratP = 0, 0
	for i = 1, 31 do
		if Input.consume().parad > 0 then
			if i == 1 then barandeP += 1 else efteratP += 1 end
		end
	end
	check("paraden är en IMPULS: ett tryck bärs av exakt en bildruta",
		barandeP == 1 and efteratP == 0,
		string.format("(%d bärande, %d extra på 30 följande bildrutor)", barandeP, efteratP))

	--[[ SITSEN (senior review #87). Hålls som tygeln — hur djupt man
	     sitter är ett tillstånd — och är analog i kontraktet, så att
	     vänster avtryckare kan dosera den. Utan knappen är sätet som
	     balansmodifierare stängt för hela pekskärmen. ]]
	nollstall()
	Input.setTouchSeat(1)
	local s1, s2 = Input.consume().seat, Input.consume().seat
	Input.setTouchSeat(0)
	local s3 = Input.consume().seat
	check("sitsen HÅLLS: djupet ligger kvar tills fingret lyfts",
		s1 == 1 and s2 == 1 and s3 == 0,
		string.format("(%.0f, %.0f, sedan %.0f)", s1, s2, s3))
	Input.setTouchSeat(0.6)
	check("sitsen är analog hela vägen genom kontraktet",
		math.abs(Input.consume().seat - 0.6) < 1e-6)
	Input.setTouchSeat(0)
end

print("\n── Ingen regression för tangent och gamepad ──")
do
	--[[ W SKRIVER INTE LÄNGRE I FRAMÅTAXELN (arkitekturbeslut 2026-09-17).
	     Den är DRIV, alltså ett steg i trappan. Provet mäter BÅDA halvorna
	     av bytet i samma andetag: att axeln står still och att trappan
	     rörde sig. Bara den första hade varit grön också om W helt enkelt
	     slutat göra något. ]]
	nollstall()
	__key(Enum.KeyCode.W, true)
	__key(Enum.KeyCode.D, true)
	local i = Input.consume()
	check("W rör inte framåtaxeln — den är DRIV numera",
		i.forward == 0, string.format("(forward %.1f)", i.forward))
	check("och W gav faktiskt en DRIV-impuls", i.gaitUp == true)
	check("D styr som förut", i.steer == 1,
		string.format("(steer %.1f)", i.steer))
	__key(Enum.KeyCode.W, false)
	__key(Enum.KeyCode.D, false)
	local sl = Input.consume()
	check("och släpper till noll", sl.forward == 0 and sl.steer == 0)

	--[[ S likadant, åt andra hållet. ]]
	nollstall()
	__key(Enum.KeyCode.S, true)
	local ned = Input.consume()
	check("S rör inte framåtaxeln heller", ned.forward == 0,
		string.format("(forward %.1f)", ned.forward))
	check("och S gav en BROMS-impuls", ned.gaitDown == true)

	--[[ PILTANGENTERNA är kontraktets andra par och måste vara bundna.
	     Utan mätningen hade en spelare som lärt sig ↑/↓ mött tystnad. ]]
	nollstall()
	check("↑ är bunden", __key(Enum.KeyCode.Up, true) == true)
	check("och ger DRIV", Input.consume().gaitUp == true)
	efterSparren()
	check("↓ är bunden", __key(Enum.KeyCode.Down, true) == true)
	check("och ger BROMS", Input.consume().gaitDown == true)

	nollstall()
	__setStick(0.5, 0.5)
	local p = Input.consume()
	check("gamepadens spak fungerar som förut",
		math.abs(p.steer - 0.5) < 1e-9 and math.abs(p.forward - 0.5) < 1e-9,
		string.format("(forward %.3f, steer %.3f)", p.forward, p.steer))

	--[[ Det gamla `setTouch` skrev i tangenternas egna fält. Höll man D och
	     drog spaken åt vänster slog de ut varandra beroende på ordning. Nu
	     summeras de som gamepaden gör. ]]
	nollstall()
	__key(Enum.KeyCode.D, true)
	Input.setTouch(0, -0.4)
	local blandat = Input.consume()
	check("tangent och pekskärm slår inte ut varandra",
		math.abs(blandat.steer - 0.6) < 1e-9,
		string.format("(D + spak −0,4 → %.3f)", blandat.steer))

	--[[ Summan får aldrig lämna −1..1: rörelsemodellen räknar med det. ]]
	nollstall()
	__key(Enum.KeyCode.D, true)
	__setStick(1, 0)
	Input.setTouch(0, 1)
	local mattad = Input.consume()
	check("summan klampas till kontraktets intervall",
		mattad.steer == 1, string.format("(%.3f)", mattad.steer))

	--[[ Och avsikter utanför intervallet klampas redan vid ingången. ]]
	nollstall()
	Input.setTouch(9, -9)
	local vild = Input.consume()
	check("orimliga pekvärden klampas vid ingången",
		vild.forward == 1 and vild.steer == -1,
		string.format("(%.1f / %.1f)", vild.forward, vild.steer))
end

print("\n── Avsittning lämnar ingenting kvar ──")
do
	nollstall()
	Input.setTouch(TouchControls.axis(R, -R, R))
	Input.drivImpuls()
	Input.unbind()
	local efter = Input.consume()
	check("unbind nollar pekaxlarna, inte bara tangenterna",
		efter.forward == 0 and efter.steer == 0,
		string.format("(forward %.3f, steer %.3f)", efter.forward, efter.steer))
	check("pekkontrollerna finns inte på en enhet utan pekskärm",
		not TouchControls.isActive())
	TouchControls.unmount()
	check("unmount är ofarlig även när inget är byggt", true)
end

--[[ ══ GÅNGARTSBEGÄRAN: ETT STEG PER BEGÄRAN ══════════════════════
	PO-tillägget på #151: "halt → skritt → trav → galopp och tillbaka ska
	kunna begäras avsiktligt, ETT STEG PER BEGÄRAN, utan att en hållen
	knapp eller ett hållet finger ger flera oavsiktliga byten."

	Begäran är en FLANK i Input: `_upEdge` sätts när tangenten går ned och
	nollas av `consume`. Provet håller tangenten nere över flera bildrutor
	och räknar hur många begäranden inputlagret lämnar ifrån sig. ]]
print("\n── Gångartsbegäran: en flank, inte en ström ──")
do
	--[[ Tangenterna gar genom __key, som slar upp AGANDE handling i CAS. ]]
	local function ned(kod)
		__key(kod, true)
	end
	local function upp(kod)
		__key(kod, false)
	end

	nollstall()
	ned(Enum.KeyCode.LeftShift)
	local begaranden = 0
	--[[ Tangenten HÅLLS: tio bildrutor utan att släppa. ]]
	for _ = 1, 10 do
		if Input.consume().gaitUp then begaranden += 1 end
	end
	check("en hållen Shift ger EN gångartsbegäran, inte tio",
		begaranden == 1, string.format("(%d begäranden på 10 bildrutor)", begaranden))
	upp(Enum.KeyCode.LeftShift)

	--[[ En NY begäran efter släpp ska gå igenom — annars vore hästen låst
	     i en gångart efter första bytet. NU KRÄVS ATT TIDEN GÅTT: spärren
	     är det som skiljer en andra hjälp från hamrande, och provet flyttar
	     därför klockan i stället för att bara släppa knappen. ]]
	nollstall()
	ned(Enum.KeyCode.LeftShift); local a = Input.consume().gaitUp
	upp(Enum.KeyCode.LeftShift); Input.consume()
	efterSparren()
	ned(Enum.KeyCode.LeftShift); local b = Input.consume().gaitUp
	upp(Enum.KeyCode.LeftShift)
	check("ett nytt tryck efter släpp och spärr ger en ny begäran",
		a == true and b == true, string.format("(%s, %s)", tostring(a), tostring(b)))

	--[[ Ner-vägen mäts likadant: tillbaka genom gångarterna. ]]
	nollstall()
	ned(Enum.KeyCode.LeftControl)
	local ner = 0
	for _ = 1, 10 do
		if Input.consume().gaitDown then ner += 1 end
	end
	check("en hållen Ctrl ger EN begäran neråt",
		ner == 1, string.format("(%d begäranden)", ner))
	upp(Enum.KeyCode.LeftControl)

	--[[ Pekytans knapp går genom SAMMA handling som tangenten. Det är hela
	     arkitekturbeslutet: en handling, tre inmatningsslag, en spärr. ]]
	nollstall()
	check("DRIV finns som handling i CAS", __handling(Input.DRIV) == true)
	local pek = 0
	for _ = 1, 10 do
		if Input.consume().gaitUp then pek += 1 end
	end
	check("ett fingertryck ger EN begäran",
		pek == 1, string.format("(%d begäranden)", pek))

	--[[ BILDRUTETAKTEN FÅR INTE ÄNDRA UPPLEVELSEN. Samma tryck, dubbelt
	     så många bildrutor: fortfarande en begäran. ]]
	nollstall()
	ned(Enum.KeyCode.LeftShift)
	local snabb = 0
	for _ = 1, 120 do
		if Input.consume().gaitUp then snabb += 1 end
	end
	upp(Enum.KeyCode.LeftShift)
	check("120 bildrutor ger inte fler begäranden än 10",
		snabb == 1, string.format("(%d begäranden på 120 bildrutor)", snabb))
end

--[[ ══ SPÄRREN: ETT TRYCK ÄR EN HJÄLP ══════════════════════════════════

     Kontraktets punkt 3: "Implementera en kort debounce (0.5–0.8 sekunder)
     per handling för att förhindra att spelaren hoppar över gångarter
     genom att spamma knappen."

     Tre saker måste stämma, och två av dem går bara att mäta med en styrd
     klocka. Ett prov som bara mäter att andra trycket stoppas är grönt
     också om spärren aldrig släpper — alltså om knappen är trasig. ]]
print("\n── Spärren mellan två hjälper ──")
do
	check("spärren ligger i kontraktets spann 0,5–0,8 s",
		Input.IMPULS_SPARR >= 0.5 and Input.IMPULS_SPARR <= 0.8,
		string.format("(%.2f s)", Input.IMPULS_SPARR))

	--[[ 1. HAMRANDE GER ETT STEG. Tio tryck på samma bildruta är precis
	     vad spelaren gör när hon vill komma iväg fort. ]]
	nollstall()
	local inne = 0
	for _ = 1, 10 do
		if Input.drivImpuls() then inne += 1 end
	end
	check("tio tryck på noll sekunder ger EN hjälp",
		inne == 1, string.format("(%d gick in)", inne))
	local rutor = 0
	for _ = 1, 10 do
		if Input.consume().gaitUp then rutor += 1 end
	end
	check("och trappan ser bara ett steg",
		rutor == 1, string.format("(%d flanker)", rutor))

	--[[ 2. STRAX FÖRE SPÄRRENS SLUT ÄR FORTFARANDE FÖR TIDIGT. ]]
	nollstall()
	check("första hjälpen går in", Input.drivImpuls() == true)
	ticka(Input.IMPULS_SPARR - 0.01)
	check("en hundradel före spärrens slut är det fortfarande hamrande",
		Input.drivImpuls() == false)

	--[[ 3. OCH STRAX EFTER SLÄPPS DEN IGENOM. Utan den här mätningen kan
	     provet inte skilja en spärr från en trasig knapp. ]]
	ticka(0.02)
	check("en hundradel efter spärrens slut är det en ny hjälp",
		Input.drivImpuls() == true)

	--[[ 4. SPÄRREN ÄR PER HANDLING, INTE GEMENSAM. Att ge för mycket och
	     genast ta tillbaka är ridning; det får inte kosta en halv sekund. ]]
	nollstall()
	check("DRIV går in", Input.drivImpuls() == true)
	check("BROMS samma bildruta går också in", Input.bromsImpuls() == true)
	check("men ett andra DRIV gör det inte", Input.drivImpuls() == false)

	--[[ 5. EN AVSITTNING NOLLAR SPÄRREN. Den som satt av mitt i en spärr
	     ska inte sitta upp och få sin första hjälp slukad. ]]
	Input.drivImpuls()
	Input.unbind()
	Input.bind()
	check("första hjälpen efter en ny uppsittning går in",
		Input.drivImpuls() == true)
end

--[[ ══ INGEN FASTNAD INPUT ÖVER EN AV- OCH UPPSITTNING ═════════════
	PO-tillägget: "ingen fastnad input vid focus loss, multitouch,
	scenbyte, upp-/avsittning, respawn eller när en panel öppnas/stängs."

	`Input.unbind()` körs vid avsittning. Den nollade tillstånden men INTE
	de två flankerna `_upEdge`/`_downEdge` — en begäran som gjordes strax
	före avsittningen låg alltså kvar och fyrade på FÖRSTA bildrutan efter
	nästa uppsittning. Hästen bytte gångart av sig själv innan ryttaren
	rört en tangent. Mätt här. ]]
print("\n── Av- och uppsittning lämnar ingen begäran kvar ──")
do
	--[[ Tangenterna gar genom __key, som slar upp AGANDE handling i CAS. ]]
	local function ned(kod)
		__key(kod, true)
	end

	nollstall()
	ned(Enum.KeyCode.LeftShift)      -- begäran gjord …
	Input.unbind()                    -- … men avsittningen kom före bildrutan
	Input.bind()                      -- ny uppsittning
	local i = Input.consume()
	check("en obehandlad gångartsbegäran överlever inte avsittningen",
		i.gaitUp == false, string.format("(gaitUp %s)", tostring(i.gaitUp)))

	nollstall()
	ned(Enum.KeyCode.LeftControl)
	Input.unbind(); Input.bind()
	check("och inte heller neråt",
		Input.consume().gaitDown == false, "(gaitDown)")

	--[[ Samma sak från pekytans knapp, alltså genom CAS. ]]
	nollstall()
	__handling(Input.DRIV)
	Input.unbind(); Input.bind()
	check("ett fingertryck strax före avsittningen fyrar inte efteråt",
		Input.consume().gaitUp == false, "(gaitUp)")

	--[[ NEUTRAL UPPSITTNING STÅR STILLA: ingen avsikt alls i första
	     bildrutan efter en ren uppsittning. ]]
	nollstall()
	local n = Input.consume()
	check("en neutral uppsittning begär ingenting",
		n.forward == 0 and n.steer == 0 and n.rein == 0
			and n.gaitUp == false and n.gaitDown == false and n.jump == false
			and n.parad == 0,
		string.format("(fram %.2f · styr %.2f · tygel %.2f)",
			n.forward, n.steer, n.rein))

	--[[ …och ett släppt finger driver inte vidare. ]]
	nollstall()
	Input.setTouch(0.8, -0.6)
	check("spaken ger utslag medan fingret ligger kvar",
		math.abs(Input.consume().steer + 0.6) < 0.001, "(styr -0.60)")
	Input.setTouch(0, 0)
	local slappt = Input.consume()
	check("och noll så snart fingret lyfts — ingen drift",
		slappt.forward == 0 and slappt.steer == 0,
		string.format("(fram %.2f · styr %.2f)", slappt.forward, slappt.steer))
end

print("")

--[[ ══ REGLAGEN BYGGS OM NÄR SKÄRMHÖJDEN ÄNDRAS (#208) ═════════════════

	`skala` i `mount` finns för att en låg skärm inte ska skjuta
	gångartsraden ur bild. Räkningen gjordes vid uppsittningen och aldrig
	igen, så en vridning efteråt lämnade kvar den gamla skalan.

	Mätt i Studio på `754f2cc`, monterat på iPad Pro 13in och sedan vridet
	till iPhone 13 i landskap (749x367):

	    HALT   y -71..-19   helt utanför
	    SKRITT y -71..-19   helt utanför
	    TRAV   y -11..41    avklippt
	    GALOPP y -11..41    avklippt

	Exakt de tal noten i `mount` citerar som det gamla felet.

	Diagnosen före rättelsen, på `4d740b6`: lyssnaren FYRAR, två gånger per
	enhetsbyte (`1375x974 -> 1281x953 -> 749x309`), och `gui == g` är sant
	båda gångerna. Mekanismen var alltså aldrig problemet — det som saknades
	var att någon räknade om. ]]
print("\n── Reglagen byggs om när skärmhöjden ändras ──")
do
	local UIS = game:GetService("UserInputService")
	local spelare = game:GetService("Players").LocalPlayer
	local kam = workspace.CurrentCamera
	local foreTouch = UIS.TouchEnabled
	local foreVy = kam.ViewportSize
	UIS.TouchEnabled = true

	--[[ Bänkens PlayerGui skapas först när någon frågar efter den med
		`WaitForChild`, precis som `init.client` gör. ]]
	spelare:WaitForChild("PlayerGui")
	local function montera(hojd)
		kam.ViewportSize = { _typ = "Vector2", X = 1180, Y = hojd }
		TouchControls.mount(Input, { dismount = function() end })
	end

	--[[ Hög yta först: surfplattans skala, alltså taket 1. ]]
	montera(1000)
	local bredPlatta = TouchControls.reglageBredd()
	check("reglagen monterades på den höga ytan", bredPlatta > 0,
		("reglageBredd %d"):format(bredPlatta))

	local gui = spelare:FindFirstChildOfClass("PlayerGui")
	local ht
	for _, g in ipairs(gui._barn or {}) do
		if g.Name == "HorseTouch" then ht = g end
	end
	check("det finns EN uppsättning reglage", ht ~= nil)

	--[[ Och så krymper ytan, som vid en vridning. Bänkens `AbsoluteSize`
		är ett rått fält, så provet fyrar signalen självt — att det är RÄTT
		signal modulen lyssnar på pinnas av raden nedan. ]]
	check("modulen lyssnar på ytans storlek",
		ht ~= nil and ht._sig ~= nil and ht._sig.AbsoluteSize ~= nil,
		"GetPropertyChangedSignal(\"AbsoluteSize\")")

	--[[ 345 − 36 px inset = 309, samma hojd iPhone 13 i landskap gav i
		Studio. 390 ar namnaren i `mount`, sa skalan blir 0,79 mot
		surfplattans 1,0 — hade jag valt en hojd nara 390 hade provet varit
		gront utan att mata nagot. ]]
	kam.ViewportSize = { _typ = "Vector2", X = 749, Y = 345 }
	if ht then ht:GetPropertyChangedSignal("AbsoluteSize"):Fire() end
	--[[ Ombyggnaden ligger i en `task.defer`; bänken kör den direkt. ]]
	task.wait()
	local smalTelefon = TouchControls.reglageBredd()
	check("reglagen byggdes OM när höjden krympte — inte kvar i gammal skala",
		smalTelefon > 0 and smalTelefon < bredPlatta,
		("%d -> %d"):format(bredPlatta, smalTelefon))

	--[[ Och tillbaka upp igen: regeln är symmetrisk. ]]
	kam.ViewportSize = { _typ = "Vector2", X = 1180, Y = 1000 }
	local ht2 = nil
	for _, g in ipairs(gui._barn or {}) do
		if g.Name == "HorseTouch" then ht2 = g end
	end
	if ht2 then ht2:GetPropertyChangedSignal("AbsoluteSize"):Fire() end
	task.wait()
	check("och tillbaka när ytan växer igen",
		TouchControls.reglageBredd() == bredPlatta,
		("%d (var %d)"):format(TouchControls.reglageBredd(), bredPlatta))

	--[[ SAMMA HÖJD FÅR INTE GE EN OMBYGGNAD. Utan den vakten bygger den
		nya ytans egen storlekshändelse om igen, varje bildruta, för alltid. ]]
	local fore = TouchControls.reglageBredd()
	local ht3 = nil
	for _, g in ipairs(gui._barn or {}) do
		if g.Name == "HorseTouch" then ht3 = g end
	end
	local byggdeOm = false
	if ht3 then
		local gammal = ht3
		ht3:GetPropertyChangedSignal("AbsoluteSize"):Fire()
		task.wait()
		for _, g in ipairs(gui._barn or {}) do
			if g.Name == "HorseTouch" and g ~= gammal then byggdeOm = true end
		end
	end
	check("oförändrad höjd bygger INTE om — ingen loop",
		not byggdeOm and TouchControls.reglageBredd() == fore,
		("byggde om: %s · bredd %d"):format(tostring(byggdeOm), TouchControls.reglageBredd()))

	--[[ Och det ska fortfarande bara finnas EN uppsättning. ]]
	local antal = 0
	for _, g in ipairs(gui._barn or {}) do
		if g.Name == "HorseTouch" then antal += 1 end
	end
	check("efter alla ombyggnader finns exakt EN uppsättning reglage",
		antal == 1, ("%d st"):format(antal))

	TouchControls.unmount()
	UIS.TouchEnabled = foreTouch
	kam.ViewportSize = foreVy
end

if fails > 0 then
	print(string.format("%d mätning(ar) föll.", fails))
else
	print("Alla mätningar gick igenom.")
end
