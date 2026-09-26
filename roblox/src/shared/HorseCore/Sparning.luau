--!strict
--[[ SPARNINGEN — vad som får överleva att spelaren stänger klienten.

	Ren logik. Ingen `DataStoreService` här inne, ingen `Player`, ingen
	pcall. Samma val som `Preparation.luau` och `Stallet.luau` gör, och av
	samma skäl: schemat, migrationen och idempotensen ÄR reglerna, och
	regler ska gå att fälla i bänken utan att någon startar en Roblox-server
	med ett riktigt datalager. `SparService.luau` äger nyckeln, nätet,
	retryn och felen.

	── VAD SOM SPARAS ───────────────────────────────────────────────

	Bara det som behövs för att återuppta rätt, enligt #161:

	  · `pass`        antal AVSLUTADE pass — spelarens progression,
	  · `passId`      kvitton, för att samma pass aldrig ska räknas två gånger,
	  · `forstaDagen` om första dagen är avklarad och på vilken häst,
	  · `hastar`      hästminnet: relation och aktiv skada/vila.

	Och inget annat. Ingen input, ingen kamera, ingen replaypanel, ingen
	tillfällig UI-state. Det är inte en storleksfråga — det är att en
	sparfil som bär presentationslager blir omöjlig att migrera den dag
	presentationen ändras.

	── HÄSTMINNETS FORM ÄR INTE VALD HÄR ────────────────────────────

	`hastar[id] = { skada = { passKvar = n } }` är EXAKT den form
	`Stallet.vilandeHastar` redan läser (PR #154), som i sin tur är webbens
	form i `src/ryttare.js`. Att välja en egen form här och konvertera i
	`StallService` hade varit en tredje sanning om samma sak.

	── VERSIONEN ────────────────────────────────────────────────────

	`v` finns för att schemat SKA kunna ändras. Två fall, och de är olika:

	  · äldre `v` → `migrera` fyller i det som saknas och lämnar resten,
	  · nyare `v` → vi förstår den inte. Då returneras en tom save MED
	    flaggan `framtida`, och `SparService` vägrar skriva över. Att i
	    stället starta om från noll hade raderat en spelares framsteg för
	    att servern var gammal.

	Ett trasigt värde ger aldrig gratis progression: `migrera` faller alltid
	tillbaka till NOLL pass, aldrig till "alla pass klara".

	── VERSION 2 (#264 COMPLETION_FIRST_INFRA1) ─────────────────────

	v2 lägger till tre kartor och ändrar inget i v1:s fält:

	  · `framsteg`  per övnings-/lektionsområde: försök, klarade, bästa
	                kvalitet och senaste tid. Bara monotona tal, så att en
	                sammanslagning mellan två servrar aldrig kan sänka dem.
	  · `resultat`  tävlingsresultat, ett per resultat-id. SKRIVS EN GÅNG:
	                ett id som redan finns skrivs aldrig över.
	  · `priser`    utdelade priser, ett per pris-id. Pris-id:t ÄR kvittot;
	                samma id två gånger ger ett pris, inte två.

	Kompatibilitet:
	  · en v1-rad läses som v2 med tomma kartor. Inget v1-fält ändras.
	  · en v2-rad läst av en v1-server är "framtida": v1-servern spelar men
	    skriver INTE (se `SparService`, fall 2). Det är avsiktligt och
	    fail-closed — en gammal server får aldrig tappa v2:s kartor genom
	    att skriva tillbaka en v1-rad. Följden är att en spelare som har
	    skrivits av en v2-server inte sparas på en kvarvarande v1-server.
	  · butiksnamnet `UBRF_Spelare_v1` behålls: bytet är kompatibelt, och
	    `migrera` bär det. Ett inkompatibelt schema byter butik i stället.

	Resultat och priser GALLRAS ALDRIG. `passId` gallras (de äldsta faller
	av vid `MAX_KVITTON`), men ett gallrat priskvitto vore ett pris som kan
	delas ut igen. I stället har kartorna ett TAK: är det nått nekas nya
	poster med "fullt", och ingenting gammalt tas bort. Taket är långt över
	vad ett familjespel hinner (se `MAX_RESULTAT`), och en nekad post är ett
	synligt nej i stället för en tyst dubblett.

	Ogiltiga poster i en lagrad rad (fel typ, tomma id, tal som inte är
	ändliga) tas bort vid läsningen. De ger aldrig progression eller pris.
]]

local Sparning = {}

Sparning.VERSION = 2

--[[ Taken finns för att en sparfil inte ska kunna växa obegränsat. Ett
	kvitto per pass, och de äldsta faller av först. 200 pass är långt bortom
	vad ett familjespel hinner, och en DataStore-nyckel har 4 MB. ]]
local MAX_KVITTON = 200

--[[ v2-kartornas tak. Ett resultat är några hundra byte serialiserat; 500
	resultat, 500 priser och 64 framstegsområden ryms med god marginal i en
	nyckel på 4 MB tillsammans med v1:s fält. ]]
local MAX_RESULTAT = 500
local MAX_PRISER = 500
local MAX_FRAMSTEG = 64
local MAX_ID = 64
Sparning.MAX_RESULTAT = MAX_RESULTAT
Sparning.MAX_PRISER = MAX_PRISER
Sparning.MAX_FRAMSTEG = MAX_FRAMSTEG

--[[ Resultatets status och prisets typ, som i #266 §7–8. Placering, clear
	round och deltagarminne hålls isär redan i datan. ]]
local STATUS = { fullfoljd = true, utesluten = true, ej_start = true, avbruten = true }
local PRISTYP = { placering = true, clear_round = true, deltagare = true }

export type Skada = {
	passKvar: number,
	vad: string?,
}

export type Hastminne = {
	relation: number,
	skada: Skada?,
}

export type Framsteg = {
	forsok: number,
	klarade: number,
	basta: number?,
	senast: number,
}

export type Resultat = {
	tavling: string,
	klass: string,
	hastId: string,
	regelversion: string,
	datum: number,
	status: string,
	fel: number?,
	tid: number?,
	procent: number?,
	placering: number?,
}

export type Pris = {
	typ: string,
	resultatId: string?,
	farg: string?,
	nar: number,
}

export type Save = {
	v: number,
	--[[ REVISIONEN. Monoton räknare som ökar vid varje lyckad skrivning,
		och som är HELT skild från `v`: `v` är schemaversionen, `rev` är
		"hur många gånger den här sparfilen har skrivits".

		Den finns för omreviewens fynd 1 (#162). Sammanslagningen i
		`SparService.skriv` behöll den LÄNGSTA vilan, så en nedräkning från
		2 till 1 aldrig gick fram — lagrets 2 vann över minnets 1, och en
		häst kunde vila för evigt. Att bara byta `>` mot `<` hade bytt buggen
		mot dess spegelbild: en gammal server hade då kunnat korta en färsk
		skada.

		Med `rev` behövs ingen sådan gissning. Servern jämför den rad som
		ligger i lagret med den den själv läste: är lagret NYARE har någon
		annan skrivit, och då avbryts skrivningen i stället för att slås
		ihop. Är den inte nyare är den här sessionen den enda som ändrat
		något sedan läsningen, och då äger minnet vilan. ]]
	rev: number,
	pass: number,
	passId: { [string]: number },
	forstaDagen: { klar: boolean, hastId: string? },
	hastar: { [string]: Hastminne },
	framsteg: { [string]: Framsteg },
	resultat: { [string]: Resultat },
	priser: { [string]: Pris },
}

function Sparning.tom(): Save
	return {
		v = Sparning.VERSION,
		rev = 0,
		pass = 0,
		passId = {},
		forstaDagen = { klar = false, hastId = nil },
		hastar = {},
		framsteg = {},
		resultat = {},
		priser = {},
	}
end

--[[ Ett ÄNDLIGT tal, annars standardvärdet. v1 släppte igenom `math.huge`
	(bara NaN nekades), och `pass = inf` i en trasig rad hade då blivit
	oändligt många avslutade pass — gratis progression. ]]
local function tal(v: any, standard: number): number
	local n = tonumber(v)
	if n == nil or n ~= n or n == math.huge or n == -math.huge then return standard end
	return n
end

local function andligt(v: any): number?
	if type(v) ~= "number" then return nil end
	if v ~= v or v == math.huge or v == -math.huge then return nil end
	return v
end

local function giltigtId(id: any): boolean
	return type(id) == "string" and id ~= "" and #id <= MAX_ID
end

local function kortText(v: any): string?
	if type(v) ~= "string" or v == "" or #v > MAX_ID then return nil end
	return v
end

local function antal(t: { [string]: any }): number
	local n = 0
	for _ in pairs(t) do n += 1 end
	return n
end

--[[ En resultatpost i den form som lagras, eller nil om den inte går att
	lita på. Obligatoriska fält saknas → nil. Valfria tal som inte är
	ändliga tas bort, de gissas inte fram. ]]
local function tvattResultat(r: any): Resultat?
	if type(r) ~= "table" then return nil end
	local tavling, klass, hastId, regel = kortText(r.tavling), kortText(r.klass),
		kortText(r.hastId), kortText(r.regelversion)
	local datum = andligt(r.datum)
	if not (tavling and klass and hastId and regel and datum) then return nil end
	if type(r.status) ~= "string" or not STATUS[r.status] then return nil end
	local fel, tid, procent = andligt(r.fel), andligt(r.tid), andligt(r.procent)
	local placering = andligt(r.placering)
	if fel and fel < 0 then fel = nil end
	if tid and tid < 0 then tid = nil end
	if procent and (procent < 0 or procent > 100) then procent = nil end
	if placering then
		placering = math.floor(placering)
		if placering < 1 then placering = nil end
	end
	return {
		tavling = tavling, klass = klass, hastId = hastId, regelversion = regel,
		datum = math.floor(datum), status = r.status,
		fel = fel, tid = tid, procent = procent, placering = placering,
	}
end

local function tvattPris(p: any): Pris?
	if type(p) ~= "table" then return nil end
	if type(p.typ) ~= "string" or not PRISTYP[p.typ] then return nil end
	local nar = andligt(p.nar)
	if not nar then return nil end
	local resultatId: string? = nil
	if p.resultatId ~= nil then
		if not giltigtId(p.resultatId) then return nil end
		resultatId = p.resultatId
	end
	--[[ En placeringsrosett utan resultat är ett pris utan orsak. ]]
	if p.typ == "placering" and not resultatId then return nil end
	return { typ = p.typ, resultatId = resultatId, farg = kortText(p.farg), nar = math.floor(nar) }
end

local function tvattFramsteg(f: any): Framsteg?
	if type(f) ~= "table" then return nil end
	local forsok = math.floor(math.max(0, tal(f.forsok, 0)))
	local klarade = math.floor(math.max(0, tal(f.klarade, 0)))
	--[[ Fler klarade än försök går inte; det är en trasig rad, och den
		klipps nedåt, aldrig uppåt. ]]
	if klarade > forsok then klarade = forsok end
	local basta = andligt(f.basta)
	if basta then basta = math.clamp(basta, 0, 1) end
	return { forsok = forsok, klarade = klarade, basta = basta,
		senast = math.floor(math.max(0, tal(f.senast, 0))) }
end

--[[ Läser en rad ur datalagret och gör den till en Save vi litar på.

	Returnerar (save, anmarkning). `anmarkning` är nil när allt var i
	ordning, annars ett av:

	  "tom"       ingen tidigare save — ny spelare,
	  "trasig"    raden fanns men gick inte att läsa som en save,
	  "framtida"  raden är skriven av en NYARE version än den här servern.

	Anropen får aldrig strunta i `anmarkning`. "framtida" betyder att
	servern ska köra sessionen men INTE spara — se filhuvudet. ]]
function Sparning.migrera(rad: any): (Save, string?)
	if rad == nil then
		return Sparning.tom(), "tom"
	end
	if type(rad) ~= "table" then
		return Sparning.tom(), "trasig"
	end

	local v = tal(rad.v, 0)
	if v > Sparning.VERSION then
		return Sparning.tom(), "spar.framtida_sparfil"
	end
	if v < 1 then
		--[[ En tabell utan igenkännbar version. Den kan vara en tidig
			handskriven rad eller skräp; vi vet inte, och att gissa åt en
			spelares fördel är precis den fail-open vi inte får ha. ]]
		return Sparning.tom(), "trasig"
	end

	local ut = Sparning.tom()
	--[[ Revisionen läses med 0 som standard, så rader skrivna före #162
		går in som rev 0 och nästa skrivning blir rev 1. Ingen migrering
		behövs; en saknad räknare ÄR noll skrivningar. ]]
	ut.rev = math.max(0, math.floor(tal(rad.rev, 0)))
	ut.pass = math.max(0, math.floor(tal(rad.pass, 0)))

	if type(rad.passId) == "table" then
		for id, nar in pairs(rad.passId) do
			if type(id) == "string" then
				ut.passId[id] = math.floor(tal(nar, 0))
			end
		end
	end

	if type(rad.forstaDagen) == "table" then
		ut.forstaDagen.klar = rad.forstaDagen.klar == true
		if type(rad.forstaDagen.hastId) == "string" then
			ut.forstaDagen.hastId = rad.forstaDagen.hastId
		end
	end

	if type(rad.hastar) == "table" then
		for id, m in pairs(rad.hastar) do
			if type(id) == "string" and type(m) == "table" then
				local minne: Hastminne = {
					relation = math.clamp(tal(m.relation, 0), 0, 1),
					skada = nil,
				}
				if type(m.skada) == "table" then
					local kvar = math.floor(tal(m.skada.passKvar, 0))
					--[[ Bara en LEVANDE skada bärs vidare. En utläkt
						(`passKvar <= 0`) skrivs inte tillbaka, så att
						sparfilen inte samlar på sig gamla krämpor. ]]
					if kvar > 0 then
						minne.skada = {
							passKvar = kvar,
							vad = if type(m.skada.vad) == "string" then m.skada.vad else nil,
						}
					end
				end
				ut.hastar[id] = minne
			end
		end
	end

	--[[ v2-kartorna. En v1-rad saknar dem och får tomma kartor; en v2-rad
		får varje post tvättad. Poster över taket i en lagrad rad behålls —
		taket stoppar NYA poster, det raderar aldrig ett utdelat pris. ]]
	if type(rad.framsteg) == "table" then
		for id, f in pairs(rad.framsteg) do
			if giltigtId(id) then
				local ren = tvattFramsteg(f)
				if ren then ut.framsteg[id] = ren end
			end
		end
	end
	if type(rad.resultat) == "table" then
		for id, r in pairs(rad.resultat) do
			if giltigtId(id) then
				local ren = tvattResultat(r)
				if ren then ut.resultat[id] = ren end
			end
		end
	end
	if type(rad.priser) == "table" then
		for id, p in pairs(rad.priser) do
			if giltigtId(id) then
				local ren = tvattPris(p)
				if ren then ut.priser[id] = ren end
			end
		end
	end

	ut.v = Sparning.VERSION
	return ut, nil
end

--[[ ── FRAMSTEG, RESULTAT OCH PRISER (v2) ─────────────────────────────

	Inga spelvägar anropar dessa ännu (INFRA-1). De är grunden som
	lektionernas framsteg och tävlingsdagens resultat och priser ska
	skrivas genom, och de har samma form som `registreraPass`: returnerar
	(true) när posten var NY och räknades, annars (false, skäl). Ett
	false är aldrig ett fel — det är skyddet som gör ett omsänt pris till
	ett pris.

	Skälen är nycklar, inte text: "ogiltig", "finns", "fullt". ]]

--[[ Noterar ett försök i ett område. `klar` räknar det som klarat, och
	`kvalitet` (0–1) höjer bästa värdet om det är bättre. Idempotens är
	INTE den här funktionens sak — ett försök har inget eget id. Den som
	anropar noterar ett försök en gång. ]]
function Sparning.noteraForsok(save: Save, omrade: string, klar: boolean,
	kvalitet: number?, nar: number?): (boolean, string?)
	if not giltigtId(omrade) then return false, "ogiltig" end
	local f = save.framsteg[omrade]
	if not f then
		if antal(save.framsteg) >= MAX_FRAMSTEG then return false, "fullt" end
		f = { forsok = 0, klarade = 0, basta = nil, senast = 0 }
		save.framsteg[omrade] = f
	end
	f.forsok += 1
	if klar == true then f.klarade += 1 end
	local k = andligt(kvalitet)
	if k then
		k = math.clamp(k, 0, 1)
		if f.basta == nil or k > f.basta then f.basta = k end
	end
	local t = andligt(nar)
	if t and t > f.senast then f.senast = math.floor(t) end
	return true, nil
end

function Sparning.harResultat(save: Save, id: string): boolean
	return giltigtId(id) and save.resultat[id] ~= nil
end

--[[ Skriver ett resultat EN gång. Ett id som finns skrivs aldrig över —
	inte ens med ett "bättre" resultat: ett fastställt resultat ändras
	inte i efterhand (#266 §6). ]]
function Sparning.registreraResultat(save: Save, id: string, post: any): (boolean, string?)
	if not giltigtId(id) then return false, "ogiltig" end
	if save.resultat[id] ~= nil then return false, "finns" end
	local ren = tvattResultat(post)
	if not ren then return false, "ogiltig" end
	if antal(save.resultat) >= MAX_RESULTAT then return false, "fullt" end
	save.resultat[id] = ren
	return true, nil
end

function Sparning.harPris(save: Save, id: string): boolean
	return giltigtId(id) and save.priser[id] ~= nil
end

--[[ Delar ut ett pris EN gång. Pris-id:t är kvittot; den som delar ut
	ska ge spelaren priset bara när svaret är true. En placeringsrosett
	kräver att dess resultat redan finns i saven. ]]
function Sparning.registreraPris(save: Save, id: string, pris: any): (boolean, string?)
	if not giltigtId(id) then return false, "ogiltig" end
	if save.priser[id] ~= nil then return false, "finns" end
	local ren = tvattPris(pris)
	if not ren then return false, "ogiltig" end
	if ren.resultatId and save.resultat[ren.resultatId] == nil then
		return false, "ogiltig"
	end
	if antal(save.priser) >= MAX_PRISER then return false, "fullt" end
	save.priser[id] = ren
	return true, nil
end

--[[ Slår ihop v2-kartorna från `fran` in i `till`, för `SparService.skriv`.
	Resultat och priser: unionen, och en post som redan finns i `till`
	vinner (den ligger i lagret, alltså fastställd först). Framsteg: det
	högsta av varje tal — aldrig en sänkning. På konfliktvägen kan två
	servrars försök då räknas som det största av de två i stället för
	summan; det underskattar, det blåser aldrig upp.

	Operationen är idempotent: att slå ihop samma `fran` två gånger ger
	samma `till`. Det krävs, eftersom Roblox får köra om `UpdateAsync`. ]]
function Sparning.slaIhopV2(till: Save, fran: Save)
	for id, r in pairs(fran.resultat) do
		if till.resultat[id] == nil then till.resultat[id] = table.clone(r) end
	end
	for id, p in pairs(fran.priser) do
		if till.priser[id] == nil then till.priser[id] = table.clone(p) end
	end
	for id, f in pairs(fran.framsteg) do
		local t = till.framsteg[id]
		if not t then
			till.framsteg[id] = table.clone(f)
		else
			t.forsok = math.max(t.forsok, f.forsok)
			t.klarade = math.max(t.klarade, f.klarade)
			if f.basta ~= nil and (t.basta == nil or f.basta > t.basta) then t.basta = f.basta end
			t.senast = math.max(t.senast, f.senast)
		end
	end
end

--[[ ── PASSEN ──────────────────────────────────────────────────────

	`registreraPass` är idempotent, och det är hela dess uppgift.

	Ett avslutat pass kan nå servern mer än en gång: klienten kan skicka om,
	`PlayerRemoving` kan komma ovanpå ett avslut som redan sparats, och en
	retry efter ett DataStore-fel kan lyckas efter att det första försöket
	i själva verket gick fram. Utan ett kvitto blir varje sådan gång ett
	pass till, och progressionen skulle gå att pumpa genom att koppla ned.

	Nyckeln är `passId`, som sätts EN gång när passet börjar (se
	`Pass.luau`). Räknas den om vid avslutet blir varje försök ett nytt id
	och kvittot värdelöst. ]]
function Sparning.harPass(save: Save, passId: string): boolean
	return type(passId) == "string" and save.passId[passId] ~= nil
end

--[[ Returnerar true om passet var NYTT och räknades, false om det redan
	fanns. Ingen av grenarna är ett fel — den andra är precis det skydd
	funktionen finns för. ]]
function Sparning.registreraPass(save: Save, passId: string, nar: number?): boolean
	if type(passId) ~= "string" or passId == "" then return false end
	if save.passId[passId] ~= nil then return false end
	save.passId[passId] = math.floor(tal(nar, 0))
	save.pass += 1

	--[[ Rensa de äldsta kvittona när de blir för många. Ordningen är
		tidsstämpeln; kvitton utan tid (0) faller först, och det är rätt
		ordning — de är från en gammal skrivning. ]]
	local antal = 0
	for _ in pairs(save.passId) do antal += 1 end
	if antal > MAX_KVITTON then
		local lista = {}
		for id, t in pairs(save.passId) do table.insert(lista, { id = id, t = t }) end
		table.sort(lista, function(a, b)
			if a.t == b.t then return a.id < b.id end
			return a.t < b.t
		end)
		for i = 1, antal - MAX_KVITTON do
			save.passId[lista[i].id] = nil
		end
	end
	return true
end

--[[ ── HÄSTMINNET ──────────────────────────────────────────────────── ]]

function Sparning.hastminne(save: Save, hastId: string): Hastminne
	local m = save.hastar[hastId]
	if not m then
		m = { relation = 0, skada = nil }
		save.hastar[hastId] = m
	end
	return m
end

--[[ Formen `Stallet.vilandeHastar` läser. Returneras direkt ur sparfilen
	utan konvertering — se filhuvudet om varför den formen inte väljs här. ]]
function Sparning.hastminnen(save: Save): { [string]: Hastminne }
	return save.hastar
end

function Sparning.vilar(save: Save, hastId: string): boolean
	local m = save.hastar[hastId]
	return m ~= nil and m.skada ~= nil and m.skada.passKvar > 0
end

--[[ Sätter en skada. Höjer ALDRIG hälsan: en ny skada på en häst som redan
	vilar förlänger vilan, den ersätter den inte med ett kortare tal.

	Det är samma hål som PR #154 stängde på webben, fast i andra änden.
	Där gjorde `delete ny.skada` hästen frisk av att ha arbetat; här skulle
	ett `passKvar = 1` ovanpå ett `passKvar = 4` göra henne nästan frisk av
	att bli skadad igen. ]]
function Sparning.satSkada(save: Save, hastId: string, passKvar: number, vad: string?)
	local kvar = math.max(0, math.floor(tal(passKvar, 0)))
	if kvar <= 0 then return end
	local m = Sparning.hastminne(save, hastId)
	if m.skada and m.skada.passKvar >= kvar then
		--[[ Redan minst så länge. Uppdatera bara beskrivningen om vi fick
			en ny; talet rörs inte. ]]
		if vad then m.skada.vad = vad end
		return
	end
	m.skada = { passKvar = kvar, vad = vad }
end

--[[ Ett pass har gått. Vilan räknas ner för ALLA hästar med en aktiv skada.

	VIKTIGT: nedräkningen hänger på att TID GÅTT, inte på att den skadade
	hästen arbetat. Hade den hängt på arbetet vore vilan självupphävande —
	att rida en halt häst skulle göra henne frisk — och det är exakt den
	buggen #154 hittade i webbens `delete ny.skada`. En häst som vilar går
	inte att tilldela (`Stallet.vilandeHastar`), så hon KAN inte arbeta av
	sig frisk här. ]]
function Sparning.raknaNerVila(save: Save)
	for _, m in pairs(save.hastar) do
		if m.skada then
			m.skada.passKvar -= 1
			if m.skada.passKvar <= 0 then
				m.skada = nil
			end
		end
	end
end

function Sparning.hojRelation(save: Save, hastId: string, delta: number)
	local m = Sparning.hastminne(save, hastId)
	m.relation = math.clamp(m.relation + tal(delta, 0), 0, 1)
end

--[[ ── FÖRSTA DAGEN ───────────────────────────────────────────────── ]]

function Sparning.forstaDagen(save: Save): boolean
	return save.forstaDagen.klar ~= true
end

function Sparning.markeraForstaDagen(save: Save, hastId: string)
	if save.forstaDagen.klar then return end
	save.forstaDagen.klar = true
	save.forstaDagen.hastId = hastId
end

--[[ Passnumret för det pass som just NU pågår — alltså avslutade pass plus
	ett. `Preparation.nyState` behöver det för att veta om dagen är första
	dagen (som alltid är fri från fynd). ]]
function Sparning.aktuelltPass(save: Save): number
	return save.pass + 1
end

--[[ ── UT TILL DATALAGRET ──────────────────────────────────────────

	En ren tabell utan metatabeller och utan funktioner. DataStore
	serialiserar inte annat, och en save som tyst tappar ett fält vid
	skrivning är svårare att upptäcka än en som vägrar. ]]
function Sparning.tillRad(save: Save): any
	local hastar = {}
	for id, m in pairs(save.hastar) do
		local rad: any = { relation = m.relation }
		if m.skada and m.skada.passKvar > 0 then
			rad.skada = { passKvar = m.skada.passKvar, vad = m.skada.vad }
		end
		hastar[id] = rad
	end
	local passId = {}
	for id, t in pairs(save.passId) do passId[id] = t end
	local framsteg, resultat, priser = {}, {}, {}
	for id, f in pairs(save.framsteg) do framsteg[id] = table.clone(f) end
	for id, r in pairs(save.resultat) do resultat[id] = table.clone(r) end
	for id, p in pairs(save.priser) do priser[id] = table.clone(p) end
	return {
		v = save.v,
		rev = save.rev,
		pass = save.pass,
		passId = passId,
		forstaDagen = { klar = save.forstaDagen.klar, hastId = save.forstaDagen.hastId },
		hastar = hastar,
		framsteg = framsteg,
		resultat = resultat,
		priser = priser,
	}
end

return Sparning
