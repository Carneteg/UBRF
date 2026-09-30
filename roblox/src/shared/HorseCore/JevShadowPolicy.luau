--!strict
--[[
	JEV-SKUGGAN — regeln (JEV-POC-2, #270, arkitektur A').

	Ren modul: inga tjänster, ingen klocka, inget nätverk. Allt som avgör
	OM ett prov får gå till Jev, VAD Ugneta säger om samma försök och HUR
	Jevs svar får läsas står här, så att det går att mäta utan Studio.

	Kontraktet: docs/JEV-POC-2-SHADOW-CONTRACT.md.

	TVÅ SAKER MODULEN INTE GÖR, och inte får göra:

	1. Den rangordnar ingenting själv. Jämförelsen är `Ugneta.observationer`
	   — exakt den regel klientens försökskort använder. En egen rangordning
	   här hade varit en andra Ugneta, och då hade skuggan jämfört Jev mot
	   något spelaren aldrig sett.

	2. Den litar inte på klienten. Underlaget kommer ur `Lektion.avslutaForsok`
	   på klienten och är OBETRott skugg-indata. Allt som inte är exakt
	   formen ur den funktionen avvisas — och ett avvisat prov går aldrig
	   till nätverket.
]]

local RidKanon = require(script.Parent.RidKanon)
local Ugneta = require(script.Parent.Ugneta)
local Lektion = require(script.Parent.Lektion)

local JevShadowPolicy = {}

--[[ Ett prov är skugg-indata och inget annat. Fälten är exakt de som
     `Lektion.avslutaForsok` lämnar till `UgnetaController.efterForsok` —
     utom `sista`, som ingen regel läser. ]]
JevShadowPolicy.FALT = { "ovningId", "forsokNr", "nu", "fore" }

--[[ Det Roblox INTE mäter, uttryckligen. Skickas till Jev som en lista i
     stället för att fyllas i: en påhittad tygeltrycksiffra hade varit
     precis den fabricering #270 förbjuder. ]]
JevShadowPolicy.SAKNAS_FALT = { "rytm", "rein_pressure", "rider_body", "free_text" }

JevShadowPolicy.INGEN = "ingen"
JevShadowPolicy.MODELL = "jev-latest"
JevShadowPolicy.URL = "https://api.typesafe.ai/v1/systemone"

--[[ Vad varje dimension betyder för Jev. Fasta konstanter — ingen text
     från spelaren kan någonsin hamna här. ]]
JevShadowPolicy.BESKRIVNING = {
	linje = "Vägen: rätt spår och rätt storlek på figuren.",
	rytm = "Rytmen: jämn takt i gångarten.",
	balans = "Sitsen och balansen: ryttaren sitter stilla och i balans.",
	timing = "Timing: hjälpen i rätt ögonblick och att vänta på hästens svar.",
	mjukhet = "Handen: mjuk och jämn kontakt.",
	respons = "Svaret: hästen svarar lugnt och fokuserat på hjälpen.",
	tempo = "Tempot: rätt fart och jämnt framåt.",
	ingen = "Inget behöver förbättras just nu.",
}

JevShadowPolicy.INSTRUKTION = "Du är ridlärare på en ridskola. Du får medelvärden "
	.. "0 till 1 per bedömd dimension för ryttarens senaste försök på en övning "
	.. "(högre är bättre) och, om det finns, samma mått för förra försöket på samma "
	.. "övning. Fält i `saknas` är inte uppmätta och får inte gissas. Välj den enda "
	.. "dimension som ryttaren mest bör arbeta på i nästa försök, eller `ingen` om "
	.. "inget behöver förbättras."

--[[ ── Tillåtna mängder, ur kanon ─────────────────────────────────── ]]

local OVNINGAR: { [string]: boolean } = {}
for _, id in Lektion.ORDNING do OVNINGAR[id] = true end

local EJ_MATT: { [string]: boolean } = {}
for _, k in Lektion.SAKNAS do EJ_MATT[k] = true end

--[[ Dimensioner Roblox faktiskt kan leverera ett medelvärde för. `rytm`
     står i kanon men mäts aldrig (Lektion.SAKNAS) — ett prov som bär den
     kommer alltså inte ur `avslutaForsok` och avvisas. ]]
local MATTBAR: { [string]: boolean } = {}
local ANTAL_MATTBARA = 0
for _, k in RidKanon.UGNETA.DIMENSIONER do
	if not EJ_MATT[k] then
		MATTBAR[k] = true
		ANTAL_MATTBARA += 1
	end
end
JevShadowPolicy.MAX_DIM = ANTAL_MATTBARA

local TILLATNA_FALT: { [string]: boolean } = {}
for _, k in JevShadowPolicy.FALT do TILLATNA_FALT[k] = true end

--[[ ── Validering ─────────────────────────────────────────────────── ]]

local function arTal(v: any): boolean
	return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge
end

--[[ Ett `nu`/`fore`: icke-tom tabell, bara mätbara dimensioner, bara
     ändliga tal i [0, 1]. Varje dimension klampas i `Lektion.kvalitet`,
     så ett medelvärde utanför [0, 1] kan inte komma ur riktig ritt. ]]
local function dimTabell(t: any, namn: string): ({ [string]: number }?, string?)
	if type(t) ~= "table" then return nil, namn .. ":inte_tabell" end
	if getmetatable(t) ~= nil then return nil, namn .. ":metatabell" end
	local ut: { [string]: number } = {}
	local n = 0
	for k, v in t do
		n += 1
		if n > ANTAL_MATTBARA then return nil, namn .. ":for_manga" end
		if type(k) ~= "string" then return nil, namn .. ":nyckeltyp" end
		if not MATTBAR[k] then return nil, namn .. ":okand_dim" end
		if not arTal(v) then return nil, namn .. ":inte_andligt" end
		if v < 0 or v > 1 then return nil, namn .. ":utanfor_intervall" end
		ut[k] = v
	end
	if n == 0 then return nil, namn .. ":tom" end
	return ut, nil
end

export type Rent = {
	ovningId: string,
	forsokNr: number,
	nu: { [string]: number },
	fore: { [string]: number }?,
}

--[[ Obetrott in, rent ut — eller ett skäl. Resultatet är en NY tabell
     byggd av det som godkänts, aldrig klientens egen. ]]
function JevShadowPolicy.validera(p: any): (Rent?, string?)
	if type(p) ~= "table" then return nil, "inte_tabell" end
	if getmetatable(p) ~= nil then return nil, "metatabell" end
	for k in p do
		if type(k) ~= "string" or not TILLATNA_FALT[k] then
			return nil, "okant_falt"
		end
	end
	local id = p.ovningId
	if type(id) ~= "string" or not OVNINGAR[id] then return nil, "okand_ovning" end
	local nr = p.forsokNr
	if not arTal(nr) or (nr ~= 1 and nr ~= 2) then return nil, "forsokNr" end
	local nu, felNu = dimTabell(p.nu, "nu")
	if not nu then return nil, felNu end
	local fore: { [string]: number }? = nil
	if p.fore ~= nil then
		local f, felFore = dimTabell(p.fore, "fore")
		if not f then return nil, felFore end
		fore = f
	end
	return { ovningId = id, forsokNr = nr, nu = nu, fore = fore }, nil
end

--[[ ── Jämförelsen: den befintliga regeln ──────────────────────────

	Ugnetas FOKUS är den dimension hon säger åt ryttaren att arbeta på:
	punkten med `sort` `forbattra` (första försöket) eller `kvar` (andra).
	Finns ingen sådan — hon berömmer bara, eller har inget att säga — är
	fokus `ingen`. Det är en projektion av hennes svar, inte en ny regel. ]]
function JevShadowPolicy.ugneta(rent: Rent): (string, { { dim: string, sort: string } })
	local obs = Ugneta.observationer(rent.ovningId, rent.nu, rent.fore)
	local fokus = JevShadowPolicy.INGEN
	local kort = {}
	for _, o in obs do
		table.insert(kort, { dim = o.dim, sort = o.sort })
		if fokus == JevShadowPolicy.INGEN and (o.sort == "forbattra" or o.sort == "kvar") then
			fokus = o.dim
		end
	end
	return fokus, kort
end

--[[ Jevs tillåtna svar: övningens MÄTBARA dimensioner, plus `ingen`.
     Samma mängd som Ugneta kan svara ur — `rytm` i en volt är ett svar
     hon aldrig kan ge, eftersom den aldrig mäts. ]]
function JevShadowPolicy.etiketter(ovningId: string): { string }
	local ut = {}
	for _, k in Ugneta.dimensionerFor(ovningId) do
		if MATTBAR[k] then table.insert(ut, k) end
	end
	table.insert(ut, JevShadowPolicy.INGEN)
	return ut
end

--[[ ── Förfrågan ──────────────────────────────────────────────────

	Byggd ENBART ur det validerade. Ingen annan källa läses, så ett fält
	som inte står här kan inte följa med — oavsett vad klienten skickade. ]]
local function kopia(t: { [string]: number }?): { [string]: number }?
	if t == nil then return nil end
	local ut = {}
	for k, v in t do ut[k] = v end
	return ut
end

function JevShadowPolicy.kropp(rent: Rent): { [string]: any }
	local kriterier = {}
	for _, e in JevShadowPolicy.etiketter(rent.ovningId) do
		kriterier[e] = JevShadowPolicy.BESKRIVNING[e]
	end
	local dims = {}
	for _, k in Ugneta.dimensionerFor(rent.ovningId) do
		if MATTBAR[k] then table.insert(dims, k) end
	end
	return {
		state = {
			ovning = rent.ovningId,
			forsok = rent.forsokNr,
			nu = kopia(rent.nu),
			fore = kopia(rent.fore),
			dimensioner = dims,
			saknas = table.clone(JevShadowPolicy.SAKNAS_FALT),
		},
		questions = {
			focus = {
				type = "choice",
				instructions = JevShadowPolicy.INSTRUKTION,
				criteria = kriterier,
			},
		},
		model = JevShadowPolicy.MODELL,
	}
end

--[[ ── Svaret ─────────────────────────────────────────────────────

	`choice` måste stå i provets egen etikettmängd — exakt skiftläge — och
	`confidence` vara ett ändligt tal i [0, 1]. Allt annat är ett trasigt
	svar, inte ett svar att räkna med. ]]
export type Tolkat = { fokus: string, confidence: number, model: string? }

function JevShadowPolicy.tolka(svar: any, ovningId: string): (Tolkat?, string?)
	if type(svar) ~= "table" then return nil, "svar_inte_tabell" end
	local answers = svar.answers
	if type(answers) ~= "table" then return nil, "saknar_answers" end
	local f = answers.focus
	if type(f) ~= "table" then return nil, "saknar_focus" end
	local val = f.choice
	if type(val) ~= "string" then return nil, "choice_typ" end
	local tillaten = false
	for _, e in JevShadowPolicy.etiketter(ovningId) do
		if e == val then tillaten = true break end
	end
	if not tillaten then return nil, "okand_etikett" end
	local c = f.confidence
	if not arTal(c) or c < 0 or c > 1 then return nil, "confidence" end
	local modell = if type(svar.model) == "string" then string.sub(svar.model, 1, 40) else nil
	return { fokus = val, confidence = c, model = modell }, nil
end

return JevShadowPolicy
