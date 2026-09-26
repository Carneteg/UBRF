--!strict
--[[ RIDFÖRSÖKEN — serverns försökslivscykel (#264 INFRA-FORSOK1).

	En grund före instruktörens konsumenter, inte en övning i sig. Ett
	försök är en serverägd post: "den här ryttaren sa, under den här
	ritten, att hon nu gör övningen X enligt definitionen Y" — med start-
	och slutmarkörer, tillstånd och avbrottsorsak. Inget mer.

	── VAD ETT FÖRSÖK INTE ÄR ────────────────────────────────────────
	  · Inte ett resultat, betyg eller en godkänd övning. Ett STÄNGT försök
	    betyder bara att försöket är slut. Posten har inget resultatfält.
	  · Ingen egen mätning. Försöket nollställer ingenting i ritternas
	    gemensamma observationer; det markerar bara VAR i dem det började
	    och slutade.
	  · Inget som startas av sig självt: uppsittning skapar inget försök —
	    fri ridning är fri.
	  · Ingen persistens, ingen klient, ingen RemoteEvent. Startas bara av
	    serverkod via HorseService.

	── ÖVNINGAR ──────────────────────────────────────────────────────
	Bara `storvolt` med serverns definition `server-referens-1`
	(`VoltObservation.VERSION`). Klientens `storvolt` version 1 är en ANNAN
	definition och godtas inte.

	── IDENTITET ─────────────────────────────────────────────────────
	Ritt, häst och ryttare kommer ur HorseService (den accepterade ritten),
	aldrig ur anroparens indata. `forsokId` genereras här.

	── BEGÄRAN, DUBBLETTER OCH RETRY ─────────────────────────────────
	Varje start/avbryt bär en `sekvens` (heltal ≥ 1) i rittens egen följd:
	  · sekvens > högsta hittills → begäran prövas; utfallet (även ett nej)
	    sparas under sin sekvens.
	  · sekvens som finns i minnet → SAMMA utfall igen, ingen ny mutation
	    (retry är idempotent; en dubblett av en start ger samma forsokId).
	  · sekvens ≤ högsta men inte i minnet (gallrad) → `forsok.inaktuell_begaran`,
	    utan mutation.
	En gammal start som kommer fram efter att försöket stängts kan därför
	aldrig öppna ett nytt: antingen minns vi den (samma, stängda, försök)
	eller så är den för gammal. Minnet är MAX_BEGARAN utfall per ritt.

	── OBSERVATIONSURSPRUNG (vad markörerna bevisar) ─────────────────
	Vid start och slut sparas `t` (ridobservationens ritt-tid, s) och
	`voltHogsta` (högsta voltavsnitts-nr som fanns, 0 om inget). Ett
	voltavsnitt kan tillskrivas försöket bara om dess nr > startens
	`voltHogsta` — alltså om det BÖRJADE efter starten — och, för ett
	stängt försök, nr ≤ slutets `voltHogsta`.
	  · Bevisar: att avsnittet inte innehåller något segment från före
	    starten (avsnitt numreras strikt stigande och ett avsnitt som
	    pågick vid starten har ett nr ≤ `voltHogsta`).
	  · Bevisar INTE: att övningen är gjord, att avsnittet är komplett,
	    att det var ryttarens avsikt, eller att historiken finns kvar —
	    voltobservationen sparar bara sina senaste avsnitt. Saknas ett
	    avsnitt som borde finnas ger läsningen `forsok.historik_gallrad`.
	  · Ett avsnitt som pågick vid starten tillskrivs INTE försöket, även
	    om ryttaren fortsätter i det.

	── MINNE ─────────────────────────────────────────────────────────
	Per ritt: högst MAX_PER_RITT försök och MAX_BEGARAN begäranutfall.
	Avslutade ritter: ring om MAX_AVSLUTADE; deras försök gallras med dem,
	och en läsning av ett gallrat försök ger nil. Frysta bilder. ]]

local VoltObservation = require(script.Parent.VoltObservation)

local RidForsok = {}

RidForsok.OVNINGAR = table.freeze({
	storvolt = table.freeze({ [VoltObservation.VERSION] = true }),
})
RidForsok.MAX_PER_RITT = 8
RidForsok.MAX_BEGARAN = 16
RidForsok.MAX_AVSLUTADE = 32

type Markor = { t: number, voltHogsta: number }
type Forsok = {
	forsokId: string, rittId: string, hastId: string, userId: number,
	ovning: string, definition: string, tillstand: string, orsak: string?,
	start: Markor, slut: Markor?, bild: any,
}
type Utfall = { ok: boolean, skal: string?, forsokId: string? }
type Ritt = {
	rittId: string, hastId: string, userId: number, oppen: boolean,
	forsok: { Forsok }, aktivt: Forsok?,
	hogstaSekvens: number, utfall: { [number]: Utfall }, utfallOrdning: { number },
}

local ritter: { [string]: Ritt } = {}
local avslutadeRitter: { string } = {}
local perId: { [string]: Forsok } = {}
local nasta = 0

local function andligt(v: any): boolean
	return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge
end

local function markor(rittTid: number, volt: any): Markor
	local hogsta = 0
	if type(volt) == "table" then
		for _, a in ipairs(volt.avslutade or {}) do hogsta = math.max(hogsta, a.nr) end
		if volt.pagar then hogsta = math.max(hogsta, volt.pagar.nr) end
	end
	return table.freeze({ t = rittTid, voltHogsta = hogsta })
end

local function bygg(f: Forsok)
	f.bild = table.freeze({
		forsokId = f.forsokId, rittId = f.rittId, hastId = f.hastId, userId = f.userId,
		ovning = f.ovning, definition = f.definition,
		tillstand = f.tillstand, orsak = f.orsak,
		start = f.start, slut = f.slut,
		bedomning = "ingen",
	})
end

function RidForsok.rittStart(rittId: string, hastId: string, userId: number): boolean
	if type(rittId) ~= "string" or rittId == "" or ritter[rittId] then return false end
	ritter[rittId] = {
		rittId = rittId, hastId = tostring(hastId), userId = tonumber(userId) or 0, oppen = true,
		forsok = {}, aktivt = nil, hogstaSekvens = 0, utfall = {}, utfallOrdning = {},
	}
	return true
end

local function stang(r: Ritt, orsak: string, rittTid: number, volt: any): boolean
	local f = r.aktivt
	if not f then return false end
	local t = if andligt(rittTid) and rittTid >= f.start.t then rittTid else f.start.t
	f.tillstand = "stangt"
	f.orsak = orsak
	f.slut = markor(t, volt)
	r.aktivt = nil
	bygg(f)
	return true
end

--[[ Ritten är slut (avsittning, död, lämnande, avregistrering, byte):
	ett aktivt försök stängs med ritten, exakt en gång. ]]
function RidForsok.rittSlut(rittId: string?, orsak: string, rittTid: number, volt: any): boolean
	local r = rittId and ritter[rittId]
	if not r or not r.oppen then return false end
	r.oppen = false
	stang(r, "ritt_slut:" .. tostring(orsak), rittTid, volt)
	table.insert(avslutadeRitter, r.rittId)
	while #avslutadeRitter > RidForsok.MAX_AVSLUTADE do
		local bort = ritter[table.remove(avslutadeRitter, 1)]
		if bort then
			for _, f in ipairs(bort.forsok) do perId[f.forsokId] = nil end
			ritter[bort.rittId] = nil
		end
	end
	return true
end

local function sekvensOk(s: any): boolean
	return andligt(s) and s >= 1 and s % 1 == 0
end

--[[ Dubblett och retry, se huvudkommentaren. Returnerar ett tidigare
	utfall, ett nej för en inaktuell begäran, eller nil (pröva). ]]
local function tidigare(r: Ritt, sekvens: number): Utfall?
	local u = r.utfall[sekvens]
	if u then return u end
	if sekvens <= r.hogstaSekvens then
		return { ok = false, skal = "forsok.inaktuell_begaran" }
	end
	return nil
end

local function minns(r: Ritt, sekvens: number, u: Utfall): Utfall
	r.hogstaSekvens = sekvens
	r.utfall[sekvens] = u
	table.insert(r.utfallOrdning, sekvens)
	while #r.utfallOrdning > RidForsok.MAX_BEGARAN do
		r.utfall[table.remove(r.utfallOrdning, 1)] = nil
	end
	return u
end

--[[ Start. `rittId` är den ritt HorseService redan har bekräftat som
	anroparens aktuella; här prövas bara att den är öppen och känd. ]]
function RidForsok.starta(rittId: string, sekvens: any, ovning: any, definition: any,
	rittTid: number, volt: any): (boolean, string?, string?)
	local r = ritter[rittId]
	if not r or not r.oppen then return false, "forsok.inaktuell_ritt", nil end
	if not sekvensOk(sekvens) then return false, "forsok.ogiltig_sekvens", nil end
	local fore = tidigare(r, sekvens)
	if fore then return fore.ok, fore.skal, fore.forsokId end

	local defs = type(ovning) == "string" and RidForsok.OVNINGAR[ovning]
	if not defs or type(definition) ~= "string" or not defs[definition] then
		local u = minns(r, sekvens, { ok = false, skal = "forsok.okand_definition" })
		return u.ok, u.skal, nil
	end
	if r.aktivt then
		local u = minns(r, sekvens, { ok = false, skal = "forsok.redan_aktivt", forsokId = r.aktivt.forsokId })
		return u.ok, u.skal, u.forsokId
	end
	if not andligt(rittTid) then
		return false, "forsok.ogiltig_tid", nil
	end
	nasta += 1
	local f: Forsok = {
		forsokId = ("f%d-%x"):format(nasta, math.random(0, 0xffffff)),
		rittId = r.rittId, hastId = r.hastId, userId = r.userId,
		ovning = ovning :: string, definition = definition :: string,
		tillstand = "aktivt", orsak = nil,
		start = markor(rittTid, volt), slut = nil, bild = nil,
	}
	bygg(f)
	r.aktivt = f
	perId[f.forsokId] = f
	table.insert(r.forsok, f)
	while #r.forsok > RidForsok.MAX_PER_RITT do
		local bort = table.remove(r.forsok, 1)
		perId[bort.forsokId] = nil
	end
	local u = minns(r, sekvens, { ok = true, skal = nil, forsokId = f.forsokId })
	return u.ok, u.skal, u.forsokId
end

function RidForsok.avbryt(rittId: string, sekvens: any, forsokId: any,
	rittTid: number, volt: any): (boolean, string?, string?)
	local r = ritter[rittId]
	if not r or not r.oppen then return false, "forsok.inaktuell_ritt", nil end
	if not sekvensOk(sekvens) then return false, "forsok.ogiltig_sekvens", nil end
	local fore = tidigare(r, sekvens)
	if fore then return fore.ok, fore.skal, fore.forsokId end
	local f = type(forsokId) == "string" and perId[forsokId] or nil
	if not f or f.rittId ~= r.rittId then
		local u = minns(r, sekvens, { ok = false, skal = "forsok.okant" })
		return u.ok, u.skal, nil
	end
	if r.aktivt ~= f then
		local u = minns(r, sekvens, { ok = false, skal = "forsok.redan_stangt", forsokId = f.forsokId })
		return u.ok, u.skal, u.forsokId
	end
	if not andligt(rittTid) then
		return false, "forsok.ogiltig_tid", nil
	end
	stang(r, "avbrutet", rittTid, volt)
	local u = minns(r, sekvens, { ok = true, skal = nil, forsokId = f.forsokId })
	return u.ok, u.skal, u.forsokId
end

function RidForsok.ogonblick(forsokId: string?): any
	local f = forsokId and perId[forsokId]
	return if f then f.bild else nil
end

function RidForsok.aktivt(rittId: string?): any
	local r = rittId and ritter[rittId]
	return if r and r.aktivt then r.aktivt.bild else nil
end

--[[ Voltavsnitten som kan tillskrivas försöket (se huvudkommentaren).
	Inga nya beräkningar: bara urval ur voltbilden. Fel: `forsok.okant`,
	`forsok.ingen_observation` och `forsok.historik_gallrad`. ]]
function RidForsok.voltUnderlag(forsokId: string?, volt: any): (any, string?)
	local f = forsokId and perId[forsokId]
	if not f then return nil, "forsok.okant" end
	if type(volt) ~= "table" or volt.rittId ~= f.rittId then return nil, "forsok.ingen_observation" end
	local fran = f.start.voltHogsta + 1
	local till = if f.slut then f.slut.voltHogsta else math.huge
	local valda = {}
	local lagst = math.huge
	for _, a in ipairs(volt.avslutade or {}) do
		lagst = math.min(lagst, a.nr)
		if a.nr >= fran and a.nr <= till then table.insert(valda, a) end
	end
	if volt.pagar then
		lagst = math.min(lagst, volt.pagar.nr)
		if volt.pagar.nr >= fran and volt.pagar.nr <= till then table.insert(valda, volt.pagar) end
	end
	--[[ Ett avsnitt i försökets spann som redan har gallrats: det äldsta
		kvarvarande är nyare än försökets första möjliga. ]]
	if lagst ~= math.huge and lagst > fran and fran <= till then
		return nil, "forsok.historik_gallrad"
	end
	return table.freeze(valda), nil
end

function RidForsok._antalForProv(): (number, number)
	local r, f = 0, 0
	for _ in pairs(ritter) do r += 1 end
	for _ in pairs(perId) do f += 1 end
	return r, f
end

return RidForsok
