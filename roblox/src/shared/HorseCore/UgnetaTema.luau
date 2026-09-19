--!strict
--[[
	RIDE FIRST-TEMAT — Ugnetas pedagogik som mätbar regel (#234).

	Beställningen 2026-09-19 är att Ugneta ska driva EN sak i taget före,
	under och efter ritten: en kort startreplik, temafiltrerad återkoppling
	medan spelaren rider, och fördjupad teori först efter avsittningen.

	DEN HÄR MODULEN ÄR REGELN, INTE YTAN. Den rör ingen Instance, ritar
	ingenting, läser ingen klocka och kan därför inte påverka ridkänslan.
	`UgnetaController` presenterar det den svarar; `LektionController`
	stegar den. Att skilja de två åt är vad som gör kontraktets tolv
	punkter prövbara utan Studio.

	── VARFÖR EN EGEN MODUL OCH INTE EN GREN I LEKTIONEN ─────────────────

	`HorseCore/Lektion` äger FÖRSÖKET: den mäter en övning i taget, stänger
	den efter `FORSOK_SEK` och lämnar medelvärden till `Ugneta` som
	rangordnar dem. Det är en bedömning av ett avgränsat moment.

	Det här är något annat: en löpande observation av VANOR över hela
	passet, med ett mönsterkrav före varje ord. De två delar telemetri och
	språkkatalog men inte lifecycle, och att bygga in det ena i det andra
	hade gett en modul med två klockor. Live-chipets cue-kanal
	(`Lektion.liveCue`) rörs inte alls — den säger några ord om DEN HÄR
	bildrutan, den här modulen säger något om de senaste sekunderna.

	── TIDEN ÄR ACKUMULERAD dt, ALDRIG VÄGGKLOCKAN ───────────────────────

	`sess.tid` växer med den `dt` anroparen lämnar. Samma skäl som
	`CoachBanner` har för att räkna sin visningstid i klientens enda loop:
	ett prov ska kunna stega exakt 7,0 sekunder i stället för att hoppas på
	en schemaläggare, och beteendet ska vara identiskt på 30 och 144 Hz.

	── TRE REGLER, ALLA UR TABELLEN ──────────────────────────────────────

	  1. TEMAFILTRET är strukturellt, inte ett undantag i en if-sats.
	     `varde()` vägrar läsa ett fält som inte står i det aktiva temats
	     `falt`, och `steg()` itererar bara det aktiva temats `signal`.
	     Ett tema utan `sits` i listan KAN alltså inte kommentera sitsen.
	  2. MÖNSTRET FÖRE KOMMENTAREN. `antal` inom `fonster` sekunder, med
	     `aterstall` som glapptak och `nollas_av` som korrekt signal.
	  3. ORSAKEN FÖLJER MED. Varje replik bär `orsak` — "ryttare" eller
	     "dagsform" — och nyckeln kommer ur motsvarande språkfamilj.
	     Modulen KAN inte välja en ryttartext till en dagsformsobservation:
	     nyckeln står i samma tabellpost som orsaken.

	Talen står i `RidKanon.UGNETA.TEMA`, genererad ur webbens src/larare.js.
	Ingen tröskel skrivs av här.
]]

local RidKanon = require(script.Parent.RidKanon)

local UgnetaTema = {}

local TEMA = RidKanon.UGNETA.TEMA

UgnetaTema.ORDNING = TEMA.ORDNING
UgnetaTema.COOLDOWN = TEMA.COOLDOWN

--[[ ── BUBBELRÄCKVIDDEN, MÄTT OCH INTE GISSAD ──────────────────────────

	`BubbleChatConfiguration.MaxDistance` är 100 studs som standard, och
	den mäts från KAMERAN — inte från spelaren. Ugneta står bortom C och
	ryttaren kan vara var som helst på den fysiska banan, så standarden
	räcker inte på långsidan.

	Talet nedan är det MINSTA som täcker banan, räknat ur kanonens egna
	mått i stället för ur ridhusets ungefärliga "25 × 75 m":

	    hennes plats      PLATS.langd + PLATS.bortomC = 60 + 1,4 = 61,4 m
	                      från A, mitt på bredden (PLATS.u = 0,5)
	    värsta ryttarhörn A-änden, ytterkant: dy 61,4 m · dx 10 m
	    avstånd           sqrt(61,4² + 10²) = 62,21 m = 186,6 studs
	    kameran bakom     `Gaits.camera.dist` är som mest 23 studs i
	                      fyrsprång, och den ligger BAKOM ryttaren, alltså
	                      längre bort från Ugneta i värsta fall
	    summa             186,6 + 23 = 209,6 studs

	210 är alltså inte en marginal ovanpå en gissning — det är taket
	avrundat uppåt till närmaste hela stud. `ugneta-gestalt.spec` räknar om
	samma sak mot den BYGGDA banan och faller om talet inte räcker eller om
	det är onödigt stort.

	MINIMERINGEN måste följa med. Roblox ritar en bubbla som en ensam
	ellips bortom `MinimizeDistance` (40 studs som standard), så en höjd
	`MaxDistance` utan en höjd `MinimizeDistance` hade gett en läsbar
	räckvidd på 40 studs och en prick på resten av banan. Det är just
	därför fallback-loggen finns — men en prick där texten kunde stått är
	ändå fel. ]]
UgnetaTema.BUBBEL_AVSTAND = 210
UgnetaTema.BUBBEL_MINIMERING = 210

export type Replik = {
	tema: string,
	nyckel: string,
	orsak: string,
	signal: string?,
}

export type Matt = { summa: number, n: number }

export type Session = {
	tema: string,
	tid: number,
	cdTill: number,
	startSagd: boolean,
	armerad: { [string]: boolean },
	hall: { [string]: number },
	serie: { [string]: { number } },
	dagsformTid: number,
	dagsformSagd: boolean,
	sedda: { [string]: boolean },
	matt: { [string]: Matt },
	ramar: number,
	sista: Replik?,
}

--[[ Finns temat i kanonen? Ett okänt tema ska aldrig tyst bli "handen":
     då hade en felstavning sett ut som en pedagogik. ]]
function UgnetaTema.finns(id: string?): boolean
	if type(id) ~= "string" then return false end
	return type(TEMA[id]) == "table"
end

--[[ Temat lektionen börjar i. Ride First-starten tar det första i
     kanonens ordning — den ordningen är ett produktbeslut i src/larare.js,
     inte något den här modulen får välja om. ]]
function UgnetaTema.forsta(): string
	return TEMA.ORDNING[1]
end

function UgnetaTema.def(id: string): { [string]: any }?
	if not UgnetaTema.finns(id) then return nil end
	return TEMA[id]
end

--[[ ── SESSIONEN ───────────────────────────────────────────────────────
     Ett pass. `ny` är den enda vägen till ett rent tillstånd, och det är
     därför inget kan läcka mellan två ritter: `LektionController.avbryt`
     släpper sessionen, och nästa uppsittning skapar en NY. Att nollställa
     fält för hand hade lämnat frågan "glömde vi något?" öppen vid varje
     nytt fält. ]]
--[[ ── nil BETYDER STANDARD, EN OKAND STRANG BETYDER FEL ──────────────

     De tva ar inte samma sak, och forsta utkastet behandlade dem sa:
     `finns(temaId)` var falskt for bada, och bada blev `forsta()`. Senior
     review 2026-09-19 fallde det med ratta — en felstavad eller framtida
     temastrang blev da TYST 'handen', alltsa en annan undervisning an den
     som bestalldes, utan ett spar nagonstans.

       nil            ingen har valt tema -> kanonens forsta, som forut,
       kand strang    det temat,
       allt annat     INGEN session.

     Att returnera nil och inte en session pa standardtemat ar avsiktligt.
     En okand temastrang ar ett fel hos den som ropar, och det ska synas
     som UTEBLIVEN undervisning i stallet for att gomma sig som FEL
     undervisning. `UgnetaController.startaPass` varnar och startar inget
     pass — fail closed, samma hallning som ett saknat `orsak` i
     `LektionController.avbryt`. ]]
function UgnetaTema.ny(temaId: string?): Session?
	local id: string
	if temaId == nil then
		id = UgnetaTema.forsta()
	elseif UgnetaTema.finns(temaId) then
		id = temaId :: string
	else
		return nil
	end
	if not UgnetaTema.finns(id) then return nil end
	return {
		tema = id,
		tid = 0,
		cdTill = 0,
		startSagd = false,
		armerad = {},
		hall = {},
		serie = {},
		dagsformTid = 0,
		dagsformSagd = false,
		sedda = {},
		matt = {},
		ramar = 0,
		sista = nil,
	}
end

--[[ ── TEMAFILTRET ─────────────────────────────────────────────────────
     Läser ett telemetrifält — men BARA om temat får läsa det. Fältet söks
     först på telemetrins toppnivå (`mjukhet`, `spanning`, `balans`,
     `paradKvalitet`) och sedan i hjälplagret (`tygel`, `sits`, `parad`),
     alltså i samma två skikt som `Telemetri.las` faktiskt skriver.

     Returnerar nil för allt annat: ett fält utanför temat, ett saknat
     fält och ett ogiltigt tal är samma sak här — ingen mätning. Att läsa
     en saknad mjukhet som 0 hade gjort varje oskriven ritt till en dålig
     ritt, vilket är exakt felet `Ugneta.observationer` en gång rättade. ]]
local function tal(v: any): number?
	if type(v) ~= "number" then return nil end
	if v ~= v then return nil end                 -- NaN
	if v == math.huge or v == -math.huge then return nil end
	return v
end

function UgnetaTema.varde(def: { [string]: any }, tm: { [string]: any }?,
	falt: string): number?
	if type(tm) ~= "table" then return nil end
	local tillaten = false
	for _, f in def.falt do
		if f == falt then tillaten = true; break end
	end
	if not tillaten then return nil end
	local v = tal(tm[falt])
	if v ~= nil then return v end
	local h = tm.hjalper
	if type(h) == "table" then return tal(h[falt]) end
	return nil
end

--[[ ── FLANKEN ─────────────────────────────────────────────────────────
     En signal räknas EN gång per gest, inte en gång per bildruta. `over`/
     `under` är utlösningen och `ater` återarmeringen, och en signal börjar
     OARMERAD: står handen redan hårt när passet börjar ska det första
     tygeltaget vara det som räknas, inte tillståndet den ärvde. ]]
local function flank(sess: Session, namn: string, regel: { [string]: any },
	v: number): boolean
	local armerad = sess.armerad[namn]
	if armerad == nil then
		--[[ Första avläsningen armerar bara. Ett värde som redan ligger
		     över tröskeln är ingen HÄNDELSE — den skedde före passet. ]]
		sess.armerad[namn] = not UgnetaTema._utlost(regel, v)
		return false
	end
	if not armerad then
		if UgnetaTema._aterarmerad(regel, v) then sess.armerad[namn] = true end
		return false
	end
	if UgnetaTema._utlost(regel, v) then
		sess.armerad[namn] = false
		return true
	end
	return false
end

--[[ ── HÅLLET ────────────────────────────────────────────────────────

	En KORREKT signal är sällan en flank. Att handen släpper efter ett
	hårt tag är inte en mjuk hand — det är slutet på det hårda taget. Det
	som är rätt är att handen LIGGER KVAR i kontaktbandet, och det är en
	varaktighet, inte ett ögonblick.

	Det här var inte en smaksak utan en rättelse. Med släppet som korrekt
	signal nollställdes serien mellan varje tygeltag, och "tre hårda tag i
	följd" kunde ALDRIG inträffa: hårt-släpp-hårt-släpp-hårt gav serie 1
	tre gånger. Mönstret hade varit omätbart, och provet hade visat grönt
	på en regel som aldrig kunde fyra.

	Räknaren nollställs så fort värdet lämnar bandet, och EFTER en
	utlösning — annars hade en hand som ligger still i bandet fyrat varje
	bildruta och nollställt varje serie för alltid. ]]
local function hallet(sess: Session, namn: string, regel: { [string]: any },
	v: number, dt: number): boolean
	local band = regel.band
	local lo, hi = band[1], band[2]
	if v < lo or v > hi then
		sess.hall[namn] = 0
		return false
	end
	local t = (sess.hall[namn] or 0) + (if dt > 0 then dt else 0)
	if t >= regel.hall then
		sess.hall[namn] = 0
		return true
	end
	sess.hall[namn] = t
	return false
end

function UgnetaTema._utlost(regel: { [string]: any }, v: number): boolean
	if regel.over ~= nil then return v >= regel.over end
	if regel.under ~= nil then return v <= regel.under end
	return false
end

function UgnetaTema._aterarmerad(regel: { [string]: any }, v: number): boolean
	if regel.ater == nil then return true end
	if regel.over ~= nil then return v < regel.ater end
	return v > regel.ater
end

--[[ ── MÖNSTRET ────────────────────────────────────────────────────────
     Tidsstämplarna för en signal, beskurna till `fonster` sekunder. Ett
     glapp längre än `aterstall` tömmer serien helt: tre hårda tag med en
     halv minut emellan är inte en vana, och beställningen kräver en
     EXPLICIT återställningsregel — inte en som råkar falla ut ur
     fönstret. ]]
local function raknaSerie(sess: Session, namn: string, m: { [string]: any }): number
	local lista = sess.serie[namn]
	if not lista then lista = {}; sess.serie[namn] = lista end
	local sist = lista[#lista]
	if sist and (sess.tid - sist) > m.aterstall then
		table.clear(lista)
	end
	table.insert(lista, sess.tid)
	--[[ Beskär framifrån: allt äldre än fönstret hör inte till serien. ]]
	while #lista > 0 and (sess.tid - lista[1]) > m.fonster do
		table.remove(lista, 1)
	end
	return #lista
end

--[[ ── STARTREPLIKEN ───────────────────────────────────────────────────
     Exakt en per giltig lektionsstart. Vakten sitter på SESSIONEN och
     inte på en modulvariabel, vilket är det som gör att StateSync,
     respawn och reconnect inte kan upprepa den: de skapar ingen ny
     session, och den befintliga har redan sagt sitt. ]]
function UgnetaTema.startReplik(sess: Session?): Replik?
	if not sess then return nil end
	if sess.startSagd then return nil end
	local def = UgnetaTema.def(sess.tema)
	if not def then return nil end
	sess.startSagd = true
	--[[ Startrepliken tar INTE cooldownen i anspråk. Den är passets
	     inledning, inte en kommentar om något spelaren gjort — och en
	     spelare som gör fel direkt ska inte behöva vänta sju sekunder på
	     sin första riktiga återkoppling för att hon fick höra hej. ]]
	local r: Replik = { tema = sess.tema, nyckel = def.start, orsak = "start" }
	sess.sista = r
	return r
end

--[[ ── ETT STEG ────────────────────────────────────────────────────────

	`tm` är ridningens telemetri (`HorseCore/Telemetri.las`), alltså exakt
	samma avläsning lektionen och webben använder. `handelseId` är märket
	på det serverbekräftade paketet: samma id två gånger är samma händelse,
	och den får inte räknas två gånger. En bildruta utan id är en lokal
	avläsning och utvärderas alltid — det är den omedelbara pedagogiska
	kontexten beställningen tillåter.

	Returnerar högst EN replik per anrop. Ordningen är avsiktlig:
	ryttarens mönster före hästens dagsform, därför att det förra är något
	spelaren kan göra något åt just nu. ]]
function UgnetaTema.steg(sess: Session?, dt: number, tm: { [string]: any }?,
	handelseId: string?): Replik?
	if not sess then return nil end
	local def = UgnetaTema.def(sess.tema)
	if not def then return nil end
	--[[ TIDEN GÅR ALLTID. Cooldownen är monoton, och en bildruta som
	     inte utvärderas är ändå en bildruta som passerat. ]]
	sess.tid += if type(dt) == "number" and dt > 0 then dt else 0

	if type(tm) ~= "table" or tm.uppsutten ~= true then return nil end

	--[[ DUBBLETTEN. Ett återspelat eller upprepat paket uppdaterar
	     varken serier, mätvärden eller dagsform. Det är skillnaden mot
	     att bara tysta kommentaren: ett paket som räknas men inte hörs
	     hade fortfarande flyttat mönstret. ]]
	if handelseId ~= nil then
		if sess.sedda[handelseId] then return nil end
		sess.sedda[handelseId] = true
	end

	sess.ramar += 1

	--[[ MÄTVÄRDENA till sammanfattningen. Bara temats egna mätare, bara
	     fält temat får läsa, och bara tal som faktiskt är tal. ]]
	for _, m in def.matare do
		local v = UgnetaTema.varde(def, tm, m.falt)
		if v ~= nil then
			local post = sess.matt[m.falt]
			if not post then post = { summa = 0, n = 0 }; sess.matt[m.falt] = post end
			post.summa += math.clamp(v, 0, 1)
			post.n += 1
		end
	end

	--[[ SIGNALERNA. Bara det aktiva temats — ett annat temas signal
	     itereras aldrig, och dess fält är dessutom spärrat av `varde`. ]]
	local utlosta: { [string]: boolean } = {}
	local d = if type(dt) == "number" and dt > 0 then dt else 0
	for namn, regel in def.signal do
		local v = UgnetaTema.varde(def, tm, regel.falt)
		if v ~= nil then
			--[[ TVÅ FORMER, OCH TABELLEN VÄLJER. `band` + `hall` är en
			     varaktighet, `over`/`under` en flank. Vilken en signal är
			     står i kanonen och inte i en if-sats om signalens NAMN —
			     ett namnberoende hade gjort en ny signal till en
			     kodändring i stället för en datarad. ]]
			local traff = if regel.band ~= nil
				then hallet(sess, namn, regel, v, d)
				else flank(sess, namn, regel, v)
			if traff then utlosta[namn] = true end
		end
	end

	--[[ DEN KORREKTA SIGNALEN AVTRUBBAR SERIEN. Regeln står i mönstret
	     (`nollas_av`) och inte här: vilket rätt som väger upp vilket fel
	     är pedagogik, och pedagogiken bor i kanonen. ]]
	for namn, m in def.monster do
		for _, rensare in (m.nollas_av or {}) do
			if utlosta[rensare] then
				local lista = sess.serie[namn]
				if lista then table.clear(lista) end
			end
		end
	end

	local blockerad = sess.tid < sess.cdTill

	for namn, m in def.monster do
		if utlosta[namn] then
			local antal = raknaSerie(sess, namn, m)
			if antal >= m.antal then
				--[[ MÖNSTRET ÄR FULLT. Serien töms oavsett om repliken
				     får sägas: en kommentar som inte fick plats KASTAS,
				     den köas inte. Annars hade sju sekunders tystnad
				     följts av en kommentar om något som hände för länge
				     sedan — precis den fördröjda kön beställningen
				     förbjuder. ]]
				local lista = sess.serie[namn]
				if lista then table.clear(lista) end
				if not blockerad then
					sess.cdTill = sess.tid + TEMA.COOLDOWN
					local r: Replik = { tema = sess.tema, nyckel = m.nyckel,
						orsak = m.orsak, signal = namn }
					sess.sista = r
					return r
				end
			end
		end
	end

	--[[ ── HÄSTENS DAG ──────────────────────────────────────────────
	     Spänningen måste HÅLLA i sig innan hon nämner den. En topp under
	     ett hörn är inte en dagsform, och att kalla den för det hade varit
	     att skylla hästens tillfälliga reaktion på dagen — eller värre, på
	     ryttaren. Sägs en gång per pass. ]]
	--[[ Heter `dag` och inte `d`: `d` är bildrutans dt några rader upp, och
	     ett `d` till hade skuggat den. Första utkastet gjorde precis det,
	     och `sess.dagsformTid += d` lade då till en TABELL. Provet fällde
	     det direkt ("attempt to perform arithmetic on number and table") —
	     men bara därför att dagsformsgrenen faktiskt körs i en mätning. ]]
	local dag = def.dagsform
	if dag then
		local v = UgnetaTema.varde(def, tm, dag.falt)
		if v ~= nil and v >= TEMA.DAGSFORM_TROSK then
			sess.dagsformTid += d
		else
			sess.dagsformTid = 0
		end
		if not sess.dagsformSagd and sess.dagsformTid >= TEMA.DAGSFORM_HALL
			and not blockerad then
			sess.dagsformSagd = true
			sess.cdTill = sess.tid + TEMA.COOLDOWN
			local r: Replik = { tema = sess.tema, nyckel = dag.nyckel, orsak = dag.orsak }
			sess.sista = r
			return r
		end
	end

	return nil
end

--[[ Har passet sett något alls? Sammanfattningen får inte öppnas på ett
     pass utan underlag — en ruta som säger ingenting om ingenting är
     sämre än ingen ruta. ]]
function UgnetaTema.harUnderlag(sess: Session?): boolean
	return sess ~= nil and (sess :: Session).ramar > 0
end

--[[ ── SAMMANFATTNINGEN, SOM NYCKLAR ───────────────────────────────────

	Returnerar det passet FAKTISKT samlat, och inget annat:

	  · en rad per mätare som har underlag — 0, 1 eller 2, aldrig en
	    påhittad nolla för en dimension ingen mätte,
	  · nyckeln till den sista repliken, med sin orsak,
	  · teorins tre nycklar och källraden ur kanonen.

	Modulen översätter INTE. Den som har spelarens locale sätter texten —
	samma arbetsdelning som `Sprak`s modulhuvud beskriver — och vyn får
	färdiga strängar, inte en regelmotor. ]]
function UgnetaTema.summering(sess: Session?): { [string]: any }?
	if not sess then return nil end
	local def = UgnetaTema.def(sess.tema)
	if not def then return nil end
	local rader = {}
	for _, m in def.matare do
		local post = sess.matt[m.falt]
		if post and post.n > 0 then
			local snitt = math.clamp(post.summa / post.n, 0, 1)
			table.insert(rader, {
				nyckel = m.nyckel,
				orsak = m.orsak,
				varde = if m.invertera then 1 - snitt else snitt,
			})
		end
	end
	local sista = sess.sista
	return {
		tema = sess.tema,
		telemetri = rader,
		kommentar = if sista and sista.orsak ~= "start" then sista.nyckel else nil,
		kommentarOrsak = if sista and sista.orsak ~= "start" then sista.orsak else nil,
		teori = {
			regel = def.teori.regel,
			text = def.teori.text,
			kalla = def.teori.kalla,
		},
	}
end

return UgnetaTema
