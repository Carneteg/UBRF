--!strict
--[[ FÖRBEREDELSEN — reglerna för att göra i ordning en häst, som ren logik.

	Ingen Roblox-anrop här inne. Det är samma val som `Stallet.luau` gör och
	av samma skäl: det här ÄR reglerna, och regler ska gå att falsifiera utan
	Studio. `GameplayService` äger instanserna, nätverket och avstånden.

	Faserna hittas inte på här. De kommer ur `UBRFSkotsel.faser`, som
	genereras ur `src/spel/skotsel.js` — samma källa som webben lär ut. Den
	gamla Roblox-sidan hade en egen lista med fyra etiketter utan innehåll,
	och det var precis den dubbla sanningen som S2a fanns till för att ta
	bort. Läs aldrig fasordningen från något annat än den här modulen.

	Tillståndet är ett rent värde: `GameplayService` håller ett per spelare,
	provet håller sina egna. Modulen har medvetet inget eget minne — hade den
	haft det gick den inte att prova två spelare samtidigt i samma process.

	── MOMENTEN (#161) ──────────────────────────────────────────────

	Fram till First Playable kvitterades en fas med ETT tryck: `utfor(s,
	"rykta")` och hästen var ryktad. Det var en checklista, inte gameplay,
	och issue #161 säger rakt ut att skötseln ska vara det senare.

	Varje fas har nu MOMENT — de faktiska handlingarna. De hittas inte på
	här heller: de HÄRLEDS ur `UBRFSkotsel`, alltså ur samma
	`src/spel/skotsel.js` som webben lär ut. Ryktningens moment är
	`rykt.krav` läst per redskap, visitationens är `visitation.punkter`,
	hovarna är `hovar`, utrustningen är `sadelfaser` och hälsningen är
	`halsning`. Lägger någon till en visitpunkt i JS-källan dyker den upp
	som ett moment här utan att en rad Luau ändras — och gör den inte det
	är det en bugg, inte en frihet.

	`steg` är ordningskravet, och det är EN siffra av ett skäl: allt är
	inte lika strikt. Att ta kardborsten före gummiskrapan är fel
	hästkunskap; att ta kroppen före benen med samma borste är bara en
	smaksak. Moment med samma `steg` får därför göras i valfri ordning,
	medan ett högre `steg` kräver att alla lägre är klara. Hade ordningen
	varit total hade modulen lärt ut pedanteri som om det vore kunskap.

	── VÄLFÄRDSSTOPPET ──────────────────────────────────────────────

	Visitationen kan ge ett FYND, precis som på webben. Rapporteras det
	rätt — "Säg till ridläraren" — STOPPAS arbetet. Hästen sätts inte i
	arbete med en varm sena, och det är inte en förlust: det är momentet
	som lärs ut. Spärren är fail-closed hela vägen upp genom
	`provaUppsittning`, så ingen väg runt den går genom att sitta upp ändå.
]]

local RS = game:GetService("ReplicatedStorage")
local Skotsel = require(RS.UBRFSkotsel)

local Preparation = {}

Preparation.FASER = Skotsel.faser

--[[ Statusorden går ut till klienten och in i provet. De är engelska för att
	arbetsordern (issue #58) namnger dem så; texten spelaren ser är svensk
	och kommer ur fasernas `namn`/`text`. ]]
Preparation.STATUS = {
	VANTAR_MODELL = "waiting_model",   -- identiteten är tilldelad, riggen saknas
	FORBEREDER = "preparing",
	REDO = "ready_to_mount",
	RIDER = "riding",
	--[[ Välfärdsstoppet (#161). Eget statusord och inte "preparing med ett
		felmeddelande": HUD:en ska säga något helt annat, och en klient som
		inte känner igen ordet ska inte råka rita en halvfärdig förberedelse
		som om arbetet kunde fortsätta. ]]
	STOPPAD = "welfare_stop",
}

export type State = {
	hastId: string,
	klara: { [string]: boolean },
	--[[ fasId → momentId → true. Skilt från `klara` med flit: `klara` är
		"fasen är avklarad", `gjorda` är "de här handlingarna är utförda".
		En fas kvitteras aldrig annat än genom att dess moment blir klara,
		men de två frågorna ställs på olika ställen. ]]
	gjorda: { [string]: { [string]: boolean } },
	--[[ Visitpunkten med ett fynd den här dagen, eller nil. Sätts av
		`nyState` ur hästen och passnumret, aldrig av klienten. ]]
	fynd: string?,
	fyndSett: boolean,
	fyndRapporterat: boolean,
	--[[ Välfärdsstoppet: texten om varför arbetet är avbrutet. Icke-nil
		betyder att hästen inte får sättas i arbete. ]]
	stoppad: string?,
}

--[[ Index i fasordningen, eller nil för ett okänt id. Slås upp linjärt över
	fasordningen; en tabell hade varit snabbare och svårare att läsa. ]]
function Preparation.fasIndex(fasId: string): number?
	for i, f in ipairs(Preparation.FASER) do
		if f.id == fasId then return i end
	end
	return nil
end

function Preparation.fas(fasId: string)
	local i = Preparation.fasIndex(fasId)
	return i and Preparation.FASER[i] or nil
end

--[[ Faserna som faktiskt utförs — alla utom den avslutande uppsittningen.
	Uppsittningen är inte ett moment i förberedelsen, den är det man får göra
	NÄR förberedelsen är klar. Räknas den som ett steg blir hästen redo att
	sitta upp på först efter att man redan suttit upp. ]]
function Preparation.stegFaser()
	local ut = {}
	for _, f in ipairs(Preparation.FASER) do
		if not f.sitt then table.insert(ut, f) end
	end
	return ut
end

--[[ ── MOMENTEN ────────────────────────────────────────────────────

	Härledda ur skötselkanonen, aldrig skrivna av. Varje moment är

	    { id, namn, text, steg, fel? }

	`fel = true` märker ett alternativ som ÄR valbart men som är fel svar —
	hälsningens "rakt bakifrån" och fyndets "det går nog bra idag". De
	ligger med för att de är själva lärandet: ett alternativ man inte kan
	välja lär inte ut någonting. ]]

local function halsMoment()
	local ut = {}
	for i, h in ipairs(Skotsel.halsning or {}) do
		table.insert(ut, {
			id = "halsa" .. i,
			namn = h.t,
			text = h.svar,
			steg = 1,
			fel = not h.ratt,
		})
	end
	return ut
end

local function visitMoment()
	local ut = {}
	--[[ Punkterna tas i tur och ordning, framifrån och bakåt — samma regel
		som webbens `visitNasta`. Därför ETT steg per punkt: här är
		ordningen hela poängen, inte en smaksak. ]]
	for i, p in ipairs(Skotsel.visitation.punkter) do
		table.insert(ut, { id = "vis:" .. p.id, namn = p.namn, text = p.ok, steg = i })
	end
	return ut
end

--[[ Zontyperna i den ordning de först dyker upp i `rykt.zoner`. Läses ur
	zonlistan i stället för att skrivas som { "kropp", "huvud", "ben" }: en
	ny zontyp i JS-källan ska bli ett moment, inte försvinna tyst. ]]
local function zontyper()
	local sedda, ut = {}, {}
	for _, z in ipairs(Skotsel.rykt.zoner) do
		if not sedda[z.typ] then
			sedda[z.typ] = true
			table.insert(ut, z.typ)
		end
	end
	return ut
end

local function ryktMoment()
	local ut = {}
	--[[ Redskapen i kanonens ordning — skrapa, kardborste, mjuk borste —
		och för varje redskap de zoner som kräver det. Steget är REDSKAPETS
		index: att ta kardborsten före gummiskrapan är fel hästkunskap och
		spärras, men kropp före ben med samma borste är fritt. Huvudet dyker
		bara upp under den mjuka borsten, för det är det enda
		`rykt.krav.huvud` innehåller. ]]
	local typer = zontyper()
	for redskapIndex, r in ipairs(Skotsel.rykt.redskap) do
		for _, typ in ipairs(typer) do
			local kravd = false
			for _, id in ipairs(Skotsel.rykt.krav[typ] or {}) do
				if id == r.id then kravd = true end
			end
			if kravd then
				table.insert(ut, {
					id = "rykt:" .. r.id .. ":" .. typ,
					namn = r.namn .. " — " .. typ,
					text = r.text,
					steg = redskapIndex,
				})
			end
		end
	end
	return ut
end

local function iordningMoment()
	local ut = {}
	--[[ Hovarna först, ETT varv runt hästen, ett steg var: ordningen är
		kanon (`vf, vb, hb, hf`) och skyddad av exportgrinden. ]]
	for i, h in ipairs(Skotsel.hovar or {}) do
		table.insert(ut, { id = "hov:" .. h.id, namn = h.namn, text = h.text, steg = i })
	end
	--[[ ...sedan utrustningen. `sadelfaser` har ingen egen id-kolumn i
		källan — den är en ordnad lista med text — så id:t är dess index.
		Stegen fortsätter efter hovarna: sadeln läggs inte på innan hovarna
		är gjorda, för då står hon sadlad och väntar medan man kryper under
		henne. ]]
	local efterHovar = #ut
	for i, f in ipairs(Skotsel.sadelfaser) do
		table.insert(ut, {
			id = "utr:" .. i,
			namn = ("Utrustning %d/%d"):format(i, #Skotsel.sadelfaser),
			text = f.t,
			steg = efterHovar + i,
		})
	end
	return ut
end

local momentCache: { [string]: any } = {}

--[[ Momenten för en fas. Cachad för att listan är ren härledning ur en
	oföränderlig kanon — men cachen är per fas-id, inte per spelare, så den
	kan aldrig bära något spelartillstånd. ]]
function Preparation.moment(fasId: string)
	local cachad = momentCache[fasId]
	if cachad then return cachad end
	local fas = Preparation.fas(fasId)
	if not fas then return {} end
	local ut
	if fasId == "halsa" then ut = halsMoment()
	elseif fasId == "visitera" then ut = visitMoment()
	elseif fasId == "rykta" then ut = ryktMoment()
	elseif fasId == "iordning" then ut = iordningMoment()
	else
		--[[ En fas utan egen härledning får ETT moment med fasens egen
			text — så är `leda` byggd, och det är med flit: källan säger hur
			man leder, inte i hur många tag, och att dela upp den hade varit
			att hitta på. En NY fas i JS-källan blir därmed spelbar direkt i
			stället för att bli osynlig. Uppsittningsfasen kommer aldrig hit;
			`stegFaser` sorterar bort den. ]]
		ut = { { id = fasId, namn = fas.namn, text = fas.text, steg = 1 } }
	end
	momentCache[fasId] = ut
	return ut
end

--[[ Är fasens moment ALTERNATIV eller en checklista?

	Hälsningen är ett val: man går fram framifrån ELLER från sidan vid
	bogen, inte båda, och det tredje sättet är fel. Ryktningen är motsatsen
	— varje redskap ska användas, inget är ett alternativ till ett annat.

	Skillnaden HÄRLEDS ur kanonen i stället för att listas här: bara ett
	val har ett felaktigt alternativ, för det är det ett `ratt`-fält i
	`src/spel/skotsel.js` betyder. En checklista har inget fel steg, bara
	steg. Skrivs skillnaden som `if fasId == "halsa"` i stället, måste den
	raden hittas och ändras varje gång källan får ett nytt val — och den
	dagen den missas blir hälsningen tyst en checklista där spelaren måste
	gå fram till hästen på tre sätt i rad. ]]
function Preparation.arVal(fasId: string): boolean
	for _, m in ipairs(Preparation.moment(fasId)) do
		if m.fel then return true end
	end
	return false
end

--[[ Har spelaren gjort ett riktigt val i fasen? Bara meningsfullt för en
	val-fas; för en checklista är svaret "hon har gjort minst ett steg". ]]
local function harValt(state: State, fasId: string): boolean
	local gjort = state.gjorda[fasId] or {}
	for _, m in ipairs(Preparation.moment(fasId)) do
		if not m.fel and gjort[m.id] then return true end
	end
	return false
end

--[[ Det moment som står på tur i fasen, eller nil när fasen är klar.
	Felaktiga alternativ räknas aldrig som något att göra. ]]
function Preparation.nastaMoment(state: State, fasId: string)
	if Preparation.arVal(fasId) and harValt(state, fasId) then
		--[[ Valet är gjort. Att peka ut ett moment till hade gjort
			alternativen till en checklista. ]]
		return nil
	end
	local gjort = state.gjorda[fasId] or {}
	for _, m in ipairs(Preparation.moment(fasId)) do
		if not m.fel and not gjort[m.id] then return m end
	end
	return nil
end

--[[ Är fasen klar? För en checklista: varje moment som inte är ett
	felaktigt alternativ är gjort. För ett val: ett riktigt alternativ är
	valt. ]]
function Preparation.fasKlar(state: State, fasId: string): boolean
	return Preparation.nastaMoment(state, fasId) == nil
end

--[[ ── FYNDET ──────────────────────────────────────────────────────

	Vilken visitpunkt bär ett fynd idag? Deterministiskt ur hästen och
	passnumret, så samma dag på samma häst ger samma svar hur många gånger
	man än ansluter om — det är samma krav som webbens `momentFro`, och
	utan det kunde en spelare rulla om fyndet genom att lämna och komma
	tillbaka.

	FÖRSTA PASSET ÄR ALLTID RENT. Produktbeslutet i docs/FIRST-DAY-HORSE.md
	ger nybörjaren Jack, och #161 säger att Jack fortfarande måste vara
	tjänstbar. Ett fynd på första passet hade stoppat arbetet innan
	spelaren ens ryktat en häst — tutorialdagen hade slutat med en tom
	spilta. Från pass 2 gäller webbens egen frekvens.

	`LCG` är Numerical Recipes-konstanterna. Kvaliteten spelar ingen roll —
	det som krävs är att den är REPRODUCERBAR och inte beror på os.time.  ]]
local FYNDCHANS = 0.42

--[[ En vanlig multiplikativ strängsumma. Luau har inga bitoperatorer —
	`~` är ett syntaxfel, inte XOR — så FNV går inte att skriva rakt av, och
	`bit32.bxor` hade bara gjort raden svårare att läsa för en hash vars enda
	krav är att den är REPRODUCERBAR. 31 och 104729 är primtal; talet
	behöver inte vara jämnt fördelat, det behöver vara samma varje gång. ]]
local function fro(hastId: string, pass: number): number
	local h = 2166136261
	for i = 1, #hastId do
		h = (h * 31 + string.byte(hastId, i)) % 4294967296
	end
	return (h + pass * 104729) % 4294967296
end

local function nasta(f: number): number
	return (1664525 * f + 1013904223) % 4294967296
end

function Preparation.fyndFor(hastId: string, pass: number): string?
	if type(hastId) ~= "string" or hastId == "" then return nil end
	if type(pass) ~= "number" or pass < 1 then return nil end
	if pass <= 1 then return nil end
	local f = nasta(fro(hastId, pass))
	if f / 4294967296 >= FYNDCHANS then return nil end
	f = nasta(f)
	local punkter = Skotsel.visitation.punkter
	local i = math.floor(f / 4294967296 * #punkter) + 1
	local p = punkter[math.clamp(i, 1, #punkter)]
	return p and p.id or nil
end

--[[ Svarsalternativen på ett fynd, som moment. Samma form som fasernas
	moment så att klienten kan rita dem med samma kod. ]]
function Preparation.fyndSvar()
	local ut = {}
	for i, s in ipairs(Skotsel.visitation.svar) do
		table.insert(ut, {
			id = "svar:" .. i,
			namn = s.t,
			text = "",
			steg = 1,
			fel = not s.ratt,
		})
	end
	return ut
end

--[[ `pass` är spelarens passnummer, 1 för första dagen. Det kommer ur det
	sparade läget och är serverns tal, aldrig klientens. ]]
function Preparation.nyState(hastId: string, pass: number?): State
	local p = if type(pass) == "number" and pass >= 1 then pass else 1
	return {
		hastId = hastId,
		klara = {},
		gjorda = {},
		fynd = Preparation.fyndFor(hastId, p),
		fyndSett = false,
		fyndRapporterat = false,
		stoppad = nil,
	}
end

--[[ Nästa fas som ska göras, eller nil när alla steg är klara. Ordningen är
	fasernas ordning — det finns ingen valfrihet och ska inte finnas. ]]
function Preparation.nasta(state: State)
	for _, f in ipairs(Preparation.stegFaser()) do
		if not state.klara[f.id] then return f end
	end
	return nil
end

function Preparation.redo(state: State): boolean
	--[[ Ett välfärdsstopp gör aldrig hästen redo, hur många faser som än är
		avbockade. Regeln står HÄR och inte bara i `provaUppsittning`, för
		`redo` är det HUD och status läser. ]]
	if state.stoppad then return false end
	return Preparation.nasta(state) == nil
end

--[[ Får spelaren utföra `fasId` på hästen `hastId` just nu?

	Fem nej, i den ordning de ska prövas:
	  1. arbetet är stoppat av välfärdsskäl,
	  2. fel häst — förberedelsen gäller EN tilldelad identitet,
	  3. ett fynd står obesvarat,
	  4. okänd eller redan gjord fas,
	  5. fel tur.

	ORDNINGEN ÄR SJÄLVA MEDDELANDET, inte en implementationsdetalj. Står
	man vid fel häst ska man få veta det, inte att "det är inte din tur att
	rykta". Och har man just hittat en varm sena ska man få veta att DET är
	det som stoppar en — inte att visitationen står på tur.

	Det tredje ledet låg först i `provaMoment`, alltså EFTER turordningen,
	och det gjorde spärren obevisbar: ett försök att rykta avvisades med
	"fel tur" ändå, så fyndspärren gick att ta bort utan att något prov
	blev rött. Falsifieringspasset fällde det. ]]
--[[ KANONTEXT SOM SKÄL.

	Nästan alla nej går numera över nätet som SPRÅKNYCKLAR ("pass.fel_tur")
	som klienten skriver ut i spelarens språk. Två skäl kan inte göra det:
	välfärdsstoppets mening och ett moments egen förklaring kommer ur
	skötselkanonen, alltså ur undervisningstexten — och den är svensk och
	får inte maskinöversättas av en agent (`CLAUDE.md`).

	De skickas därför med prefixet `kanon:`. Det är AVSIKTLIGT synligt:
	klienten vet att texten är innehåll och inte en nyckel, och
	språkgrinden kan RÄKNA dem och redovisa dem som översättningsskuld i
	stället för att en svensk mening tystnar in i en engelsk HUD. Får
	kanonen engelska poster är det här stället som slår upp dem. ]]
local KANON = "kanon:"

function Preparation.kanontext(text: string?): string
	return KANON .. tostring(text or "")
end

function Preparation.arKanontext(skal: string?): boolean
	return type(skal) == "string" and string.sub(skal, 1, #KANON) == KANON
end

function Preparation.utanKanonprefix(skal: string): string
	return if Preparation.arKanontext(skal) then string.sub(skal, #KANON + 1) else skal
end

function Preparation.provaSteg(state: State, fasId: string, hastId: string): (boolean, string?)
	if state.stoppad then
		return false, Preparation.kanontext(state.stoppad)
	end
	if hastId ~= state.hastId then
		return false, "forb.fel_hast"
	end
	--[[ Ett fynd som setts men inte rapporterats blockerar allt annat. Det
		är hela poängen med momentet: man går inte vidare och sadlar över en
		varm sena för att listan säger att ryktningen står på tur. ]]
	if state.fyndSett and not state.fyndRapporterat then
		return false, "forb.oppet_fynd"
	end
	local fas = Preparation.fas(fasId)
	if not fas then
		return false, "forb.okand_fas"
	end
	if fas.sitt then
		return false, "forb.uppsittning_inte_steg"
	end
	if state.klara[fasId] then
		return false, "forb.redan_gjort"
	end
	local nastaFas = Preparation.nasta(state)
	if not nastaFas or nastaFas.id ~= fasId then
		return false, "forb.fel_tur", (if nastaFas then nastaFas.namn else nil)
	end
	return true, nil
end

--[[ ── MOMENTPROVNINGEN ────────────────────────────────────────────

	Den här är den som klienten faktiskt kör mot, och den är därför också
	den som varje bypass-försök går emot. Nejen i ordning:

	  1–5. allt `provaSteg` säger nej till (stopp, fel häst, öppet fynd,
	       okänd fas, fel tur),
	  6.   okänt moment-id,
	  7.   redan gjort — dubbeltryck flyttar ingenting,
	  8.   fel tur INOM fasen, alltså ett högre `steg` än det lägsta ogjorda. ]]
function Preparation.provaMoment(state: State, fasId: string, momentId: string,
	hastId: string): (boolean, string?, any?)
	local ok, skal = Preparation.provaSteg(state, fasId, hastId)
	if not ok then return false, skal, nil end

	local moment = nil
	for _, m in ipairs(Preparation.moment(fasId)) do
		if m.id == momentId then moment = m end
	end
	if not moment then
		return false, "forb.okant_moment", nil
	end

	local gjort = state.gjorda[fasId] or {}
	if gjort[momentId] then
		return false, "forb.redan_gjort", nil
	end

	--[[ Ett felaktigt alternativ får VÄLJAS — det är så det lär ut — men
		det flyttar ingenting framåt. Texten är kanonens egen konsekvens,
		inte en tillrättavisning skriven här. ]]
	if moment.fel then
		return false, Preparation.kanontext(moment.text), moment
	end

	local lagsta = nil
	for _, m in ipairs(Preparation.moment(fasId)) do
		if not m.fel and not gjort[m.id] then
			if lagsta == nil or m.steg < lagsta then lagsta = m.steg end
		end
	end
	if lagsta and moment.steg > lagsta then
		local pa_tur = Preparation.nastaMoment(state, fasId)
		return false, "forb.fel_tur", (if pa_tur then pa_tur.namn else nil)
			.. " står på tur", nil
	end

	return true, nil, moment
end

--[[ Utför momentet. Muterar `state` bara när provningen gick igenom, så ett
	avvisat försök aldrig kan flytta fram förberedelsen halvvägs.

	Returnerar (ok, skäl, handelse) där `handelse` är "fynd" när
	visitationen just avslöjade något. Servern behöver veta det för att
	kunna skicka svarsalternativen. ]]
function Preparation.utforMoment(state: State, fasId: string, momentId: string,
	hastId: string): (boolean, string?, string?)
	local ok, skal, moment = Preparation.provaMoment(state, fasId, momentId, hastId)
	if not ok then return false, skal, nil end

	state.gjorda[fasId] = state.gjorda[fasId] or {}
	state.gjorda[fasId][momentId] = true

	--[[ Avslöjade det här momentet fyndet? Visitpunktens moment-id är
		`vis:<punkt>`, och fyndet bär punktens id. ]]
	local handelse = nil
	if fasId == "visitera" and state.fynd and momentId == "vis:" .. state.fynd then
		state.fyndSett = true
		handelse = "fynd"
	end

	if Preparation.fasKlar(state, fasId) then
		--[[ En visitation med ett OSETT fynd kan inte vara klar — men det
			kan den heller inte vara, för fyndets punkt är ett moment som
			måste göras. Kontrollen står ändå kvar: hittar någon en väg dit
			ska fasen inte kvitteras. ]]
		if fasId == "visitera" and state.fynd and not state.fyndRapporterat then
			return true, nil, handelse
		end
		state.klara[fasId] = true
	end
	return true, nil, handelse
end

--[[ Svaret på ett fynd. Rätt svar STOPPAR arbetet — det är inte ett fel,
	det är momentet. Fel svar avvisas och fyndet står kvar öppet. ]]
function Preparation.svaraFynd(state: State, svarId: string): (boolean, string?)
	if not state.fyndSett then
		return false, "forb.inget_att_rapportera"
	end
	if state.fyndRapporterat then
		return false, "forb.redan_rapporterat"
	end
	local valt = nil
	for _, s in ipairs(Preparation.fyndSvar()) do
		if s.id == svarId then valt = s end
	end
	if not valt then
		return false, "forb.okant_svar"
	end
	if valt.fel then
		--[[ "Det går nog bra idag" och "lös det själv" avvisas och fyndet
			står kvar. Att låta dem gå igenom med en sämre poäng hade gjort
			dem till en genväg; här finns ingen genväg, bara ett rätt svar. ]]
		return false, "forb.inte_ditt_beslut"
	end
	state.fyndRapporterat = true
	local text = Skotsel.visitation.fynd[state.fynd or ""] or "Något är inte som det ska."
	state.stoppad = text .. " Ridläraren tar över — "
		.. "hon ska inte arbeta idag. Du har gjort precis rätt."
	return true, nil
end

--[[ Får spelaren sitta upp? Egen fråga, inte `redo` — uppsittningen prövas
	mot BÅDE förberedelsen och hästens identitet, och den som frågar sitter i
	`GameplayService` med en modell i handen. ]]
function Preparation.provaUppsittning(state: State, hastId: string): (boolean, string?)
	if hastId ~= state.hastId then
		return false, "forb.inte_din_hast"
	end
	--[[ FAIL-CLOSED. Välfärdsstoppet prövas före allt annat och kan inte
		kringgås av att faserna råkar vara avbockade. ]]
	if state.stoppad then
		return false, Preparation.kanontext(state.stoppad)
	end
	--[[ En fas som står som klar men vars moment inte är gjorda får inte
		heller släppa igenom. `klara` sätts bara av `utforMoment`, men
		grinden kostar en loop och stänger vägen för alla framtida sätt att
		sätta flaggan. ]]
	for _, f in ipairs(Preparation.stegFaser()) do
		if not Preparation.fasKlar(state, f.id) then
			return false, "pass.aterstar", f.namn
		end
	end
	local nastaFas = Preparation.nasta(state)
	if nastaFas then
		return false, "pass.aterstar", nastaFas.namn
	end
	return true, nil
end

--[[ Får klienten rita `ny` när den redan ritat revisionen `senasteRev`?

	Regeln är ett enda `>`, men den bor här och inte i klienten av samma skäl
	som allt annat i modulen: den ska gå att fälla utan Studio. Utan den kan
	handskakningens svar landa efter en nyare spontan sync och backa HUD:en
	till ett äldre läge — krav 10. ]]
function Preparation.farRita(senasteRev: number?, ny): boolean
	if type(ny) ~= "table" or type(ny.rev) ~= "number" then return false end
	if senasteRev == nil then return true end
	return ny.rev > senasteRev
end

--[[ ── Bindningen ──────────────────────────────────────────────────

	Valet av modell är också en REGEL, inte instanshantering, så den bor
	här och inte i `GameplayService`. Tjänsten samlar ihop kandidaterna ur
	`CollectionService` och frågar; den letar aldrig själv.

	Uppdelningen finns av samma skäl som i riggkontraktet: hade tjänsten
	haft en egen kopia av villkoret gick regeln bara att prova genom att
	starta en server, och då provas den aldrig. ]]

--[[ Väljer den modell vars id är EXAKT det tilldelade och som ingen annan
	spelare håller.

	`kandidater` är { { id = <HorseId>, modell = <valfritt> } }.
	`upptagna` är { [modell] = true } för modeller andra redan bundit.

	Ingen närmast-häst-fallback, med flit. Att binda närmaste Horse-taggade
	modell gör att något alltid händer — och att spelaren gör i ordning fel
	individ utan att få veta det. Hellre nil, som blir `waiting_model`. ]]
function Preparation.valjModell(kandidater, hastId: string, upptagna)
	local taget = upptagna or {}
	for _, kandidat in ipairs(kandidater or {}) do
		if kandidat.id == hastId and not taget[kandidat.modell] then
			return kandidat.modell
		end
	end
	return nil
end

--[[ Får spelaren sitta upp på en modell vars HorseId är `modellHastId`?

	Krav 6 och 7 i ett: rätt identitet OCH färdig förberedelse. Identiteten
	prövas först — en fullt förberedd spelare som står vid någon annans häst
	ska få veta att det är fel häst, inte att något återstår. ]]
function Preparation.provaModell(state: State?, modellHastId): (boolean, string?)
	if not state then
		return false, "spel.ingen_hast"
	end
	if modellHastId ~= state.hastId then
		return false, "spel.inte_din_hast"
	end
	return Preparation.provaUppsittning(state, state.hastId)
end

--[[ Det klienten ska visa. Servern skickar hela den här tabellen; klienten
	räknar inte ut någon del av den själv.

	`rev` är ett strikt växande serienummer per spelare. Det finns för krav
	10: handskakningens svar och en spontan `PreparationSync` kan komma i
	vilken ordning som helst över nätet, och utan serienummer kan det äldre
	svaret skriva över det nyare. ]]
function Preparation.vy(state: State?, status: string, rev: number?)
	if not state then
		return { status = status, hastId = nil, steg = {}, nasta = nil,
			moment = {}, nastaMoment = nil, fynd = nil, svar = {},
			stoppad = nil, redo = false, rev = rev or 0 }
	end
	local steg = {}
	for _, f in ipairs(Preparation.stegFaser()) do
		table.insert(steg, {
			id = f.id,
			namn = f.namn,
			text = f.text,
			klar = state.klara[f.id] == true,
		})
	end
	local nastaFas = Preparation.nasta(state)

	--[[ Bara den AKTUELLA fasens moment går över nätet. Att skicka alla
		faser gånger alla moment vore ett par hundra rader per sync för en
		HUD som ändå bara ritar en fas i taget. ]]
	local moment = {}
	local nastaM = nil
	if nastaFas then
		local gjort = state.gjorda[nastaFas.id] or {}
		for _, m in ipairs(Preparation.moment(nastaFas.id)) do
			table.insert(moment, {
				id = m.id,
				namn = m.namn,
				text = m.text,
				fel = m.fel == true,
				klar = gjort[m.id] == true,
			})
		end
		local pa_tur = Preparation.nastaMoment(state, nastaFas.id)
		nastaM = pa_tur and pa_tur.id or nil
	end

	--[[ Svarsalternativen skickas bara när det finns ett obesvarat fynd.
		Ligger de alltid i vyn kan en klient rita dem när det inte finns
		något att svara på. ]]
	local svar = {}
	local fyndtext = nil
	if state.fyndSett and not state.fyndRapporterat then
		svar = Preparation.fyndSvar()
		fyndtext = Skotsel.visitation.fynd[state.fynd or ""]
	end

	return {
		status = status,
		hastId = state.hastId,
		steg = steg,
		nasta = nastaFas and nastaFas.id or nil,
		moment = moment,
		nastaMoment = nastaM,
		fynd = fyndtext,
		svar = svar,
		stoppad = state.stoppad,
		redo = Preparation.redo(state),
		rev = rev or 0,
	}
end

return Preparation
