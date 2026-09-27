--!strict
--[[ LEKTIONSMINNET — vilka av de tio ridlektionerna spelaren har KLARAT minst
	en gång. docs/LESSON-MEMORY-CONTRACT.md (C4, första delen).

	Inget betyg, ingen skicklighet, ingen förbättring, inget antal. Bara en
	monoton markör per lektion och definition: "klarad minst en gång".

	── VAR MARKÖREN FÖDS ────────────────────────────────────────────
	`slutford(session, lektion)` anropas av lektionens egen övergång till
	`complete` (via `lektion.vidKlar`, satt av HorseService), alltså i SAMMA
	anrop som sätter det frysta resultatet — oavsett om övergången kom i
	Heartbeat-steget eller i ett `steg` inne i en sync/start/retry-begäran,
	och innan en omedelbar Retry hinner nollställa resultatet. Den prövar:
	  · ritten: sessionens ryttare, ritt och häst = lektionens,
	  · spelaren: en riktig spelare med klient och en laddad sparfil,
	  · försöket: RidForsok-bilden för exakt försöket är stängd med
	    "slutford", med samma ritt, spelare och häst, och med just den här
	    lektionens övning OCH definitionsversion,
	  · resultatet: fryst, samma försök/ritt/spelare/häst och producentens
	    egen identitet (mål, rutt, övning, figur, galoppsida, passage).
	Ingen klient, ingen Start/Finish-begäran, ingen timeout/stängning, ingen
	gammal bild och ingen annan spelares lektion kan föda den.

	── LAGRINGEN ────────────────────────────────────────────────────
	I v2:s `framsteg`, under en egen namnrymd per lektion OCH definition:
	`lektion:<typ>:<VERSION>` (t.ex. "lektion:halt:server-halt-1"). Värdet är
	{ forsok = 1, klarade = 1, basta = nil, senast = 0 } och betyder BARA
	"klarad minst en gång": inget antal, ingen kvalitet, ingen tid (0 = ingen
	tid sparad). Den sätts EN gång och sammanslagningen (max) kan aldrig
	sänka den. Ändras en lektions definition byts nyckeln, och en gammal
	markör räknas inte för den nya.

	── BEKRÄFTAT, VÄNTANDE, OKÄNT ───────────────────────────────────
	  · `bekraftad`: fanns i en BETRODD läsning, eller täcktes av en av
	    den här modulens egna skrivningar som SparService svarade sant på.
	  · `vantar`: klarad nu, markerad i minnet, inte bekräftat sparad.
	  · historiken `okand`: läsningen gick inte att lita på (läsfel,
	    framtida, trasig, inget datalager, inte laddad). Då sägs aldrig
	    "inga lektioner".
	Att UpdateAsync-callbacken kördes, att `save().framsteg` ändrades eller
	att en skrivning köades är INTE en bekräftelse.

	── SKRIVNINGEN ──────────────────────────────────────────────────
	Aldrig i ridloopen: en ny markör schemalägger ett försök med
	`task.defer`. Försöket anropar `SparService.skriv`. Via
	`SparService.foreSkrivning` läggs de väntande markörerna in i minnet i
	BÖRJAN av varje körning av transformatorn (idempotent), så att en
	markör som noterats medan en annan skrivning var i luften — och vars
	cachade tabell ersattes — ändå följer med. Den körning som faktiskt
	sparades är den sista, och dess väntande mängd är vad som bekräftas när
	`skriv` svarar sant. Nej/upptaget/fullt: markörerna står kvar som
	väntande; ett nytt försök görs efter RETRY_S sekunder, högst MAX_RETRY
	gånger per ny markör, och vid varje ny klarad lektion. Vid avfärd skriver
	SparService som förut, och markörerna finns då i minnet.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Sparning = require(ReplicatedStorage.HorseCore.Sparning)
local Aktor = require(ReplicatedStorage.HorseCore.Aktor)
local Net = require(ReplicatedStorage.HorseCore.Networking)
local SparService = require(script.Parent.SparService)
local RidForsok = require(script.Parent.RidForsok)
local Skopa = require(script.Parent.Skopa)
local VoltObservation = require(script.Parent.VoltObservation)
local HaltLektion = require(script.Parent.HaltLektion)
local OvergangLektion = require(script.Parent.OvergangLektion)
local SerpentinLektion = require(script.Parent.SerpentinLektion)
local TempoLektion = require(script.Parent.TempoLektion)
local VagLektion = require(script.Parent.VagLektion)
local HalvvoltLektion = require(script.Parent.HalvvoltLektion)
local GaloppLektion = require(script.Parent.GaloppLektion)
local MarkbomLektion = require(script.Parent.MarkbomLektion)

local LektionsMinne = {}

--[[ De tio lektionerna, med producentens egen övning och version (det
	RidForsok-försöket startas med) och resultatets identitet. ]]
local DEF: { [string]: { ovning: string, version: string, ok: (any) -> boolean } } = {
	volt = { ovning = "storvolt", version = VoltObservation.VERSION,
		ok = function(r) return type(r.avsnitt) == "table" end },
	halt = { ovning = HaltLektion.OVNING, version = HaltLektion.VERSION,
		ok = function(r) return r.mal == "X" end },
	overgang = { ovning = OvergangLektion.OVNING, version = OvergangLektion.VERSION,
		ok = function(r) return r.mal == "T1->T2" end },
	serpentin = { ovning = SerpentinLektion.OVNING, version = SerpentinLektion.VERSION,
		ok = function(r) return r.rutt == "serpentin-3" end },
	tempo = { ovning = TempoLektion.OVNING, version = TempoLektion.VERSION,
		ok = function(r) return r.ovning == TempoLektion.OVNING end },
	vag_mitt = { ovning = VagLektion.OVNING, version = VagLektion.VERSION,
		ok = function(r) return r.figur == "vag_mitt" end },
	vag_diag = { ovning = VagLektion.OVNING, version = VagLektion.VERSION,
		ok = function(r) return r.figur == "vag_diag" end },
	halvvolt = { ovning = HalvvoltLektion.OVNING, version = HalvvoltLektion.VERSION,
		ok = function(r) return r.figur == "halvvolt" end },
	galopp = { ovning = GaloppLektion.OVNING, version = GaloppLektion.VERSION,
		ok = function(r) return r.ovning == GaloppLektion.OVNING and r.galoppsida == "ej_bedomd" end },
	markbom = { ovning = MarkbomLektion.OVNING, version = MarkbomLektion.VERSION,
		ok = function(r) return r.ovning == MarkbomLektion.OVNING and r.passage == "rotplan" end },
}
LektionsMinne.TYPER = table.freeze({ "volt", "halt", "overgang", "serpentin", "tempo", "vag_mitt",
	"vag_diag", "halvvolt", "galopp", "markbom" })

local RETRY_S = 20
local MAX_RETRY = 3

function LektionsMinne.nyckel(typ: string): string?
	local d = DEF[typ]
	if not d then return nil end
	return "lektion:" .. typ .. ":" .. tostring(d.version)
end

type Tillstand = {
	token: {},
	betrodd: boolean,
	bekraftad: { [string]: boolean },
	vantar: { [string]: boolean },
	tackt: { [string]: boolean }?,
	retry: number,
	skriverNu: boolean,
	--[[ R1: ordningen till klienten. `session` är serverns ökande nummer
		för det här tillståndet, `rev` räknas upp vid varje ändring. ]]
	session: number,
	rev: number,
	--[[ R1: spelaren lämnar. Ingen UI, inga nya försök; det väntande står
		kvar tills SparService:s sista skrivning har körts. ]]
	lamnar: boolean,
}
local tillstand: { [Player]: Tillstand } = {}
local sessionNr = 0

--[[ Markören i en save: bara "klarad minst en gång". ]]
local function harMarkor(save: any, typ: string): boolean
	local n = LektionsMinne.nyckel(typ)
	local f = n and save and save.framsteg and save.framsteg[n]
	return type(f) == "table" and type(f.klarade) == "number" and f.klarade >= 1
end

--[[ Lägger in markören i en save, idempotent. Taket respekteras genom
	Sparning (en ny post nekas när `framsteg` är fullt). ]]
local function markera(save: any, typ: string): boolean
	if not save then return false end
	if harMarkor(save, typ) then return true end
	local n = LektionsMinne.nyckel(typ) :: string
	local f = save.framsteg[n]
	if f then
		f.forsok = math.max(f.forsok, 1)
		f.klarade = math.max(f.klarade, 1)
		return true
	end
	local ok = Sparning.noteraForsok(save, n, true, nil, nil)
	return ok == true
end

--[[ Projektionen till klienten: bara de tio, bara tre lägen per lektion,
	och historikens läge. Ingen annan spelare kan väljas. ]]
local function projektion(t: Tillstand?): any
	local lektioner = {}
	for _, typ in LektionsMinne.TYPER do
		local lage = "okand"
		if t then
			if t.bekraftad[typ] then lage = "sparad"
			elseif t.vantar[typ] then lage = "vantar"
			elseif t.betrodd then lage = "ej_klarad" end
		end
		lektioner[typ] = lage
	end
	return table.freeze({ historik = if t and t.betrodd then "betrodd" else "okand",
		lektioner = table.freeze(lektioner),
		session = if t then t.session else 0, rev = if t then t.rev else 0 })
end
LektionsMinne._projektion = projektion

local function skicka(player: Player)
	local t = tillstand[player]
	if t and t.lamnar then return end -- R1: aldrig UI efter avfärden
	if t then t.rev += 1 end
	local k = Aktor.klient(player)
	if not k then return end
	pcall(function() Net.get("LektionsMinneSync"):FireClient(k, projektion(t)) end)
end

local forsokSpara: (Player, {}) -> ()

local function schemalagg(player: Player, token: {}, fordrojning: number)
	if fordrojning <= 0 then
		task.defer(forsokSpara, player, token)
	else
		task.delay(fordrojning, forsokSpara, player, token)
	end
end

forsokSpara = function(player: Player, token: {})
	local t = tillstand[player]
	if not t or t.token ~= token then return end -- glömd, eller ny session
	--[[ R1: under avfärden skriver bara SparService:s sista skrivning; ett
		schemalagt eller sent försök gör ingenting (ingen samtidig skrivning
		på samma nyckel). ]]
	if t.lamnar then return end
	if next(t.vantar) == nil or t.skriverNu then return end
	--[[ Markörerna in i den AKTUELLA cachade saven (den kan ha ersatts sedan
		de noterades). Transformatorn gör samma sak igen i varje körning. ]]
	local save = SparService.save(player)
	for typ in t.vantar do markera(save, typ) end
	t.tackt = nil
	t.skriverNu = true
	local ok = SparService.skriv(player, nil)
	local nu = tillstand[player]
	if not nu or nu.token ~= token then return end -- ett sent svar till en ny session rör ingenting
	nu.skriverNu = false
	if nu.lamnar then
		--[[ R1: skrivningen var i luften när spelaren lämnade. Det den bar är
			bekräftat; resten tar SparService:s sista skrivning (kroken lägger in
			det). Ingen UI, inga nya försök. ]]
		if ok and nu.tackt then
			for typ in nu.tackt do nu.bekraftad[typ] = true; nu.vantar[typ] = nil end
		end
		nu.tackt = nil
		return
	end
	if ok and nu.tackt then
		local nagot = false
		for typ in nu.tackt do
			nu.bekraftad[typ] = true
			nu.vantar[typ] = nil
			nagot = true
		end
		if nagot then nu.retry = 0 end
	end
	nu.tackt = nil
	skicka(player)
	--[[ Står något kvar som väntande — en markör som kom efter att
		transformatorn kört, eller ett nej — görs ett nytt försök: direkt
		efter ett ja (skrivvägen är ledig), annars efter RETRY_S. Högst
		MAX_RETRY i rad utan att något bekräftas, så att en markör som inte
		ryms (fullt) aldrig blir en slinga. ]]
	if next(nu.vantar) ~= nil and nu.retry < MAX_RETRY then
		nu.retry += 1
		schemalagg(player, token, if ok then 0 else RETRY_S)
	end
end

--[[ I början av VARJE körning av SparService-transformatorn: de väntande
	markörerna in i minnet (idempotent), och mängden noteras som den körningen
	bär. Körs för alla skrivningar (även avfärd); bekräftelse sker bara i
	`forsokSpara`, som vet sitt eget svar. ]]
local function foreSkrivning(player: Player, minnet: any)
	local t = tillstand[player]
	if not t then return end
	local bar = {}
	for typ in t.vantar do
		if markera(minnet, typ) then bar[typ] = true end
	end
	t.tackt = bar
end

--[[ ── NÄR EN LEKTION ÖVERGÅR TILL "complete" ─────────────────────── ]]
function LektionsMinne.slutford(session: any, s: any)
	if type(session) ~= "table" or type(s) ~= "table" then return end
	local typ = s.typ or "volt"
	local d = DEF[typ]
	if not d or s.lage ~= "complete" then return end
	local player = session.rider
	if player == nil or Aktor.klient(player) == nil then return end
	if session.rittId ~= s.rittId or s.rittId == nil then return end
	local t = tillstand[player]
	if not t or SparService.save(player) == nil then return end -- ingen laddad spelare
	if (player :: any).UserId ~= s.userId then return end
	local modell = session.rig and session.rig.model
	local hastId = modell and tostring(modell:GetAttribute("HorseId") or modell.Name)
	if hastId ~= s.hastId then return end
	local r = s.resultat
	if type(r) ~= "table" or not table.isfrozen(r) then return end
	if r.forsokId ~= s.forsokId or r.rittId ~= s.rittId or r.userId ~= s.userId
		or r.hastId ~= s.hastId then return end
	if not d.ok(r) then return end
	local f = RidForsok.ogonblick(s.forsokId)
	if type(f) ~= "table" or f.orsak ~= "slutford" or f.tillstand == "aktivt"
		or f.rittId ~= s.rittId or f.userId ~= s.userId or f.hastId ~= s.hastId
		or f.ovning ~= d.ovning or f.definition ~= d.version then return end
	if t.bekraftad[typ] or t.vantar[typ] then return end -- redan känd: ingen ny markör
	t.vantar[typ] = true
	markera(SparService.save(player), typ)
	t.retry = 0
	skicka(player)
	schemalagg(player, t.token, 0)
end

--[[ ── LADDNING, AVFÄRD, KLIENTENS LÄSNING ─────────────────────────── ]]
local function efterLaddning(player: Player, save: any)
	sessionNr += 1
	local t: Tillstand = { token = {}, betrodd = SparService.betroddLasning(player), bekraftad = {},
		vantar = {}, tackt = nil, retry = 0, skriverNu = false, session = sessionNr, rev = 0,
		lamnar = false }
	if t.betrodd then
		for _, typ in LektionsMinne.TYPER do
			if harMarkor(save, typ) then t.bekraftad[typ] = true end
		end
	end
	tillstand[player] = t
	skicka(player)
end

local startad = false
function LektionsMinne.start()
	Net.get("LektionsMinne").OnServerInvoke = Skopa.grind("LektionsMinne", function(player: Player, op: any)
		if op ~= "sync" then return nil end
		return projektion(tillstand[player])
	end)
	if startad then return end
	startad = true
	SparService.foreSkrivning(foreSkrivning)
	SparService.efterLaddning(efterLaddning)
	--[[ R1: AVFÄRDEN DRÄNERAR, den kastar inte. Före SparService:s sista
		skrivning: markera att spelaren lämnar (ingen UI, inga nya försök) men
		BEHÅLL det väntande och tokenen, så att `foreSkrivning` lägger in dem i
		varje körning av den sista skrivningen. Efter den: släpp tillståndet.
		Föll den sista skrivningen är markörerna förlorade — det sägs i en
		varning, aldrig till spelaren som sparat. ]]
	SparService.foreAvfard(function(player: Player)
		local t = tillstand[player]
		if t then t.lamnar = true end
	end)
	SparService.efterAvfard(function(player: Player, ok: boolean)
		local t = tillstand[player]
		if t and not ok and next(t.vantar) ~= nil then
			local lista = {}
			for typ in t.vantar do table.insert(lista, typ) end
			warn(("[LektionsMinne] %s lämnade och den sista skrivningen föll: %s sparades INTE.")
				:format(Aktor.namn(player), table.concat(lista, ", ")))
		end
		tillstand[player] = nil
	end)
	Players.PlayerRemoving:Connect(function(player)
		--[[ Säkerhetsnät om SparService inte är startad: utan dess avfärd
			finns ingen sista skrivning att vänta på. ]]
		if not SparService.redo(player) and SparService.save(player) == nil then
			tillstand[player] = nil
		end
	end)
end

--[[ Provkrokar. ]]
function LektionsMinne._tillstandForProv(player: Player): any
	return tillstand[player]
end
function LektionsMinne._forsokSparaForProv(player: Player)
	local t = tillstand[player]
	if t then forsokSpara(player, t.token) end
end
--[[ Provkrok: ett försök med en GIVEN token (t.ex. en gammal session). ]]
function LektionsMinne._forsokSparaMedTokenForProv(player: Player, token: {})
	forsokSpara(player, token)
end
function LektionsMinne._efterLaddningForProv(player: Player)
	local s = SparService.save(player)
	if s then efterLaddning(player, s) end
end

return LektionsMinne
