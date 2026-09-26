--!strict
--[[ RIDOBSERVATIONEN — serverns egen mätning av ridväg och tempo per ritt
	(#264 INFRA-2B1).

	`HorseService` matar den en gång per uthållighetssteg (hjärtslagen
	samlas till steg om minst 0,25 s) med den ridna hästens rotposition,
	stegets längd och den gångart servern själv accepterat. Inget annat.
	Klientens StateSync-fart, klientens inspelning och klientens påståenden
	om väg eller tid används inte.

	VAD DET ÄR, OCH INTE ÄR:
	  · Det är en OBSERVATION av en häst vars fysik fortfarande ägs av
	    ryttarens klient (`SetNetworkOwner`). Den är inte ett fuskskydd,
	    och den ger ingen belöning eller tävlingsbehörighet.
	  · "Tempojämnhet" är hur jämn den observerade planfarten är i ett
	    kort fönster inom samma accepterade gångart. Det är INTE uppmätt
	    hovtakt och inte ett bevis på korrekt ryttmik i ridlärans mening.
	  · Den bedömer ingenting: ingen lektion klaras, ingen domare dömer.
	  · Hinder (INFRA-2B2) mäts inte här.

	── ENHETER ──────────────────────────────────────────────────────
	Längd i studs, tid i sekunder, fart i studs/s, vinklar i radianer.
	Kurs = atan2(dx, dz) i världens plan (X, Z). Svängar räknas som
	kursändringen mellan två på varandra följande giltiga rörelsesegment,
	omslagen till (−π, π].

	── GILTIGHET, per steg ──────────────────────────────────────────
	  · dt ej ändligt eller ≤ 0        → `ogiltigaDt`, ingenting räknas
	  · dt > MAX_DT                     → `luckor`, baslinjen nollställs,
	                                      tiden räknas som oobserverad
	  · rot saknas eller icke-ändlig    → `saknade`, baslinjen nollställs
	  · första giltiga läget            → baslinje, ingen sträcka
	  · planförflyttning > teleportgräns → `teleporter`, baslinjen flyttas
	    (samma gräns som `HorseService.observera`, TELEPORT_GRANS·dt)
	  · annars                          → ett giltigt segment
	Saknad observation är aldrig en halt: stillastående räknas bara ur
	GILTIGA segment med liten fart.

	Varje brott (ogiltigt dt, lucka, saknat läge, teleport) tömmer också
	tempofönstret. Tempot gäller bara det pågående sammanhängande
	avsnittet: inget numeriskt tempo förrän avsnittet har MIN_TEMPO_PROV
	nya segment i samma gångart, och under tiden bär tempot brottets skäl.
	Summorna för hela ritten påverkas inte.

	Höjdled räknas för sig (`hojdSumma` = Σ|dy|) och aldrig som fart
	eller sträcka.

	── SPELANTAGANDEN (inga verklighetsfakta) ────────────────────────
	  · MAX_DT = 1,0 s: normalt steg är ~0,25 s; ett längre glapp är ett
	    serverhack, och en sträcka över det går inte att lita på.
	  · MIN_KURS_FART = 0,5 studs/s: under det är kursen brus, och den
	    nollställs i stället för att ge svängar vid halt.
	  · RUTT_STEG = 2 studs mellan sparade ruttpunkter.

	── MINNE ─────────────────────────────────────────────────────────
	  · per steg: O(1). Tempot räknas först när någon läser.
	  · fönster: de senaste FONSTER giltiga segmenten (ring).
	  · rutt: nedsamplad, högst MAX_RUTT punkter. Punkter efter taket
	    sparas inte, och `ruttTrunkerad` sätts. Varje diskontinuitet
	    (teleport, lucka, saknad rot) börjar ett nytt `del`, så att ingen
	    konsument drar en linje över ett hopp.
	  · summor för HELA ritten: sträcka, tider, svängar, räknare.
	  · avslutade ritter: en ring om MAX_AVSLUTADE; den äldsta hela posten
	    faller bort och räknas i `gallrade()`. Öppna gallras aldrig.
	Ögonblicksbilden är en fryst djupkopia. ]]

local RidObservation = {}

RidObservation.VERSION = 1
RidObservation.MAX_DT = 1.0
RidObservation.MIN_KURS_FART = 0.5
RidObservation.RUTT_STEG = 2
RidObservation.MAX_RUTT = 512
RidObservation.FONSTER = 40
RidObservation.MIN_TEMPO_PROV = 8
RidObservation.MAX_AVSLUTADE = 32

type Sampel = { t: number, x: number, y: number, z: number, fart: number, gangart: string, ryggar: boolean }
type Punkt = { t: number, x: number, z: number, del: number }
type Obs = {
	v: number, rittId: string, hastId: string, userId: number,
	oppen: boolean, satt: string?,
	tid: number, obsTid: number, oobsTid: number,
	distans: number, maxFart: number, hojdSumma: number,
	svangAbs: number, svangNetto: number,
	tidPerGangart: { [string]: number },
	ogiltigaDt: number, luckor: number, saknade: number, teleporter: number, segment: number,
	rutt: { Punkt }, ruttTrunkerad: boolean, del: number,
	_fonster: { Sampel }, _fonsterNasta: number, _sistaBrott: string?,
	_bas: Vector3?, _kurs: number?, _ruttSist: Vector3?,
}

local poster: { [string]: Obs } = {}
local avslutade: { string } = {}
local gallrade = 0

local function andligt(v: any): boolean
	return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge
end

--[[ Tre ändliga komponenter. Läses i pcall: ett värde som inte är en
	vektor ska ge ett nej, inte ett fel mitt i hjärtslaget. ]]
local function andligVektor(p: any): boolean
	if p == nil then return false end
	local ok, x, y, z = pcall(function() return p.X, p.Y, p.Z end)
	return ok and andligt(x) and andligt(y) and andligt(z)
end

local function omslag(v: number): number
	while v > math.pi do v -= 2 * math.pi end
	while v <= -math.pi do v += 2 * math.pi end
	return v
end

--[[ ETT BROTT I OBSERVATIONEN (granskning R1). Baslinje, kurs och rutt
	börjar om — och det gör TEMPOFÖNSTRET också. Tempot beskriver det
	pågående, sammanhängande avsnittet; prov från andra sidan en lucka får
	aldrig blandas in i det, och ett gammalt jämnt tempo får inte stå kvar
	som "nu" efter ett avbrott. Summorna för hela ritten, räknarna och
	ruttens delar rörs inte. `skal` blir tempots besked tills avsnittet
	har MIN_TEMPO_PROV nya segment. ]]
local function brott(o: Obs, skal: string)
	o._bas = nil
	o._kurs = nil
	o._ruttSist = nil
	o.del += 1
	o._fonster = {}
	o._fonsterNasta = 1
	o._sistaBrott = skal
end

function RidObservation.starta(rittId: string, hastId: string, userId: number): boolean
	if type(rittId) ~= "string" or rittId == "" or poster[rittId] then return false end
	poster[rittId] = {
		v = RidObservation.VERSION, rittId = rittId, hastId = tostring(hastId), userId = tonumber(userId) or 0,
		oppen = true, satt = nil,
		tid = 0, obsTid = 0, oobsTid = 0,
		distans = 0, maxFart = 0, hojdSumma = 0,
		svangAbs = 0, svangNetto = 0,
		tidPerGangart = {},
		ogiltigaDt = 0, luckor = 0, saknade = 0, teleporter = 0, segment = 0,
		rutt = {}, ruttTrunkerad = false, del = 1,
		_fonster = {}, _fonsterNasta = 1, _sistaBrott = nil,
		_bas = nil, _kurs = nil, _ruttSist = nil,
	}
	return true
end

local function laggRutt(o: Obs, p: Vector3)
	if o.ruttTrunkerad then return end
	if #o.rutt >= RidObservation.MAX_RUTT then
		o.ruttTrunkerad = true
		return
	end
	table.insert(o.rutt, { t = o.tid, x = p.X, z = p.Z, del = o.del })
	o._ruttSist = p
end

--[[ Ett uthållighetssteg för en riden häst. `pos` är rotens läge eller
	nil när roten saknas; `gangart`/`ryggar` är serverns accepterade läge.

	Returnerar (giltigt segment?, status, från, ritt-tid). Status är
	"segment", "baslinje", "brott" eller "stangd". Bara vid "segment" finns
	`fran` — föregående giltiga läge — så att en konsument (hinder-
	observationen, INFRA-2B2) aldrig kan bygga ett segment över ett brott. ]]
function RidObservation.sampla(rittId: string?, pos: Vector3?, dt: number, gangart: string,
	ryggar: boolean, teleportGrans: number): (boolean, string, Vector3?, number?)
	local o = rittId and poster[rittId]
	if not o or not o.oppen then return false, "stangd" end
	if not andligt(dt) or dt <= 0 then
		--[[ Ett förkastat steg är också ett brott: annars kunde nästa
			giltiga steg bilda ett segment över ett intervall som aldrig
			räknades. ]]
		o.ogiltigaDt += 1
		brott(o, "ogiltigt_dt")
		return false, "brott", nil, o.tid
	end
	o.tid += dt
	--[[ Tid i ACCEPTERAD gångart räknas alltid — det är serverns trappa,
		inte en observation. Ryggning räknas under egen nyckel. ]]
	local nyckel = if ryggar then "rygga" else gangart
	o.tidPerGangart[nyckel] = (o.tidPerGangart[nyckel] or 0) + dt

	if dt > RidObservation.MAX_DT then
		o.luckor += 1
		o.oobsTid += dt
		brott(o, "lucka")
		if pos and andligVektor(pos) then o._bas = pos end
		return false, "brott", nil, o.tid
	end
	if not pos or not andligVektor(pos) then
		o.saknade += 1
		o.oobsTid += dt
		brott(o, "saknat_lage")
		return false, "brott", nil, o.tid
	end
	local bas = o._bas
	if not bas then
		o._bas = pos
		o.oobsTid += dt
		laggRutt(o, pos)
		return false, "baslinje", nil, o.tid
	end
	local dx, dy, dz = pos.X - bas.X, pos.Y - bas.Y, pos.Z - bas.Z
	local plan = math.sqrt(dx * dx + dz * dz)
	if plan > teleportGrans * dt then
		o.teleporter += 1
		o.oobsTid += dt
		brott(o, "teleport")
		o._bas = pos
		laggRutt(o, pos)
		return false, "brott", nil, o.tid
	end

	o._bas = pos
	o.segment += 1
	o.obsTid += dt
	o.distans += plan
	o.hojdSumma += math.abs(dy)
	local fart = plan / dt
	if fart > o.maxFart then o.maxFart = fart end

	if fart >= RidObservation.MIN_KURS_FART then
		local kurs = math.atan2(dx, dz)
		if o._kurs then
			local d = omslag(kurs - o._kurs)
			o.svangAbs += math.abs(d)
			o.svangNetto += d
		end
		o._kurs = kurs
	else
		o._kurs = nil
	end

	local sist = o._ruttSist
	if not sist or math.sqrt((pos.X - sist.X) ^ 2 + (pos.Z - sist.Z) ^ 2) >= RidObservation.RUTT_STEG then
		laggRutt(o, pos)
	end

	o._fonster[o._fonsterNasta] = { t = o.tid, x = pos.X, y = pos.Y, z = pos.Z, fart = fart,
		gangart = gangart, ryggar = ryggar }
	o._fonsterNasta = (o._fonsterNasta % RidObservation.FONSTER) + 1
	return true, "segment", bas, o.tid
end

function RidObservation.avsluta(rittId: string?, satt: string): boolean
	local o = rittId and poster[rittId]
	if not o or not o.oppen then return false end
	o.oppen = false
	o.satt = satt
	table.insert(avslutade, o.rittId)
	while #avslutade > RidObservation.MAX_AVSLUTADE do
		local aldst = table.remove(avslutade, 1)
		poster[aldst] = nil
		gallrade += 1
	end
	return true
end

--[[ Fönstret i tidsordning, äldst först. ]]
local function fonster(o: Obs): { Sampel }
	local ut = {}
	local n = #o._fonster
	if n < RidObservation.FONSTER then
		for i = 1, n do table.insert(ut, o._fonster[i]) end
	else
		for i = 0, n - 1 do
			table.insert(ut, o._fonster[((o._fonsterNasta - 1 + i) % n) + 1])
		end
	end
	return ut
end

--[[ Tempojämnhet i fönstret: bara segment i SAMMA accepterade gångart som
	det senaste, och bara om hästen rör sig. Variationskoefficienten
	(std/medel) för den observerade planfarten. Nil med ett skäl när
	underlaget inte räcker — aldrig ett påhittat tal. ]]
local function tempo(f: { Sampel }, sistaBrott: string?): any
	local sist = f[#f]
	--[[ Tomt fönster efter ett brott: inget "nu" att beskriva, och
		framför allt ingen halt — saknad observation är inte stillastående. ]]
	if not sist then
		return if sistaBrott then { skal = "brott_i_observationen", brott = sistaBrott }
			else { skal = "inga_prov" }
	end
	if sist.ryggar or sist.gangart == "halt" then return { skal = "ingen_rorelse", gangart = sist.gangart } end
	local farter = {}
	for i = #f, 1, -1 do
		local s = f[i]
		if s.gangart ~= sist.gangart or s.ryggar then break end
		table.insert(farter, s.fart)
	end
	if #farter < RidObservation.MIN_TEMPO_PROV then
		return { skal = "for_fa_prov", gangart = sist.gangart, n = #farter, brott = sistaBrott }
	end
	local summa = 0
	for _, v in ipairs(farter) do summa += v end
	local medel = summa / #farter
	if medel < RidObservation.MIN_KURS_FART then
		return { skal = "ingen_rorelse", gangart = sist.gangart, n = #farter }
	end
	local kv = 0
	for _, v in ipairs(farter) do kv += (v - medel) ^ 2 end
	local std = math.sqrt(kv / #farter)
	return { gangart = sist.gangart, n = #farter, medelFart = medel, stdFart = std, variation = std / medel }
end

local function frys(t: any): any
	if type(t) ~= "table" then return t end
	local kopia = {}
	for k, v in pairs(t) do kopia[k] = frys(v) end
	return table.freeze(kopia)
end

function RidObservation.ogonblick(rittId: string?): any
	local o = rittId and poster[rittId]
	if not o then return nil end
	local f = fonster(o)
	--[[ Ogiltigt dt räknas också: sedan R1 bryter det avsnittet, och två
		olika svar om giltigheten ska inte kunna ges (INFRA-2B2). ]]
	local antalBrott = o.luckor + o.saknade + o.teleporter + o.ogiltigaDt
	return frys({
		v = o.v, rittId = o.rittId, hastId = o.hastId, userId = o.userId,
		oppen = o.oppen, satt = o.satt,
		enheter = { langd = "studs", tid = "s", fart = "studs/s", vinkel = "rad" },
		tid = o.tid, obsTid = o.obsTid, oobsTid = o.oobsTid,
		tackning = if o.tid > 0 then o.obsTid / o.tid else 0,
		distans = o.distans, maxFart = o.maxFart, hojdSumma = o.hojdSumma,
		medelFart = if o.obsTid > 0 then o.distans / o.obsTid else nil,
		svangAbs = o.svangAbs, svangNetto = o.svangNetto,
		tidPerGangart = o.tidPerGangart,
		giltighet = {
			segment = o.segment, ogiltigaDt = o.ogiltigaDt, luckor = o.luckor,
			saknade = o.saknade, teleporter = o.teleporter,
			obruten = antalBrott == 0,
		},
		behallet = {
			fonster = "de senaste " .. RidObservation.FONSTER .. " giltiga segmenten",
			rutt = "nedsamplad var " .. RidObservation.RUTT_STEG .. " studs, högst "
				.. RidObservation.MAX_RUTT .. " punkter",
			ruttTrunkerad = o.ruttTrunkerad,
			summor = "hela ritten",
		},
		fonster = f,
		rutt = o.rutt,
		tempo = tempo(f, o._sistaBrott),
	})
end

function RidObservation.gallrade(): number
	return gallrade
end

function RidObservation._glomForProv()
	poster = {}
	avslutade = {}
	gallrade = 0
end

return RidObservation
