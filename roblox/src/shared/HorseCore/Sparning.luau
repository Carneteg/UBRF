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
]]

local Sparning = {}

Sparning.VERSION = 1

--[[ Taken finns för att en sparfil inte ska kunna växa obegränsat. Ett
	kvitto per pass, och de äldsta faller av först. 200 pass är långt bortom
	vad ett familjespel hinner, och en DataStore-nyckel har 4 MB. ]]
local MAX_KVITTON = 200

export type Skada = {
	passKvar: number,
	vad: string?,
}

export type Hastminne = {
	relation: number,
	skada: Skada?,
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
}

function Sparning.tom(): Save
	return {
		v = Sparning.VERSION,
		rev = 0,
		pass = 0,
		passId = {},
		forstaDagen = { klar = false, hastId = nil },
		hastar = {},
	}
end

local function tal(v: any, standard: number): number
	local n = tonumber(v)
	if n == nil or n ~= n then return standard end
	return n
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
		return Sparning.tom(), "framtida"
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

	ut.v = Sparning.VERSION
	return ut, nil
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
	return {
		v = save.v,
		rev = save.rev,
		pass = save.pass,
		passId = passId,
		forstaDagen = { klar = save.forstaDagen.klar, hastId = save.forstaDagen.hastId },
		hastar = hastar,
	}
end

return Sparning
