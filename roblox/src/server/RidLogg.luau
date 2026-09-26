--!strict
--[[ RIDLOGGEN — serverns egen händelselogg per ritt (#264 INFRA-2A).

	En ritt = ett `rittId` ur `HorseService` (samma märke som `RidSession`).
	Loggen skrivs BARA av `HorseService`, och bara vid övergångar servern
	själv har accepterat:

	  · `uppsittning`  en lyckad uppsittning (i `setRider`),
	  · `gangart`      en accepterad ändring av serverns trappa — hjälp,
	                   trötthetstak — med gammalt och nytt läge,
	  · `avslut`       avsittning eller städning, EN gång, med sättet:
	                   "avslutad" (ryttaren bad om det) eller "avbruten"
	                   (död, karaktären borta, sitsen släppte, spelaren
	                   lämnade, hästen avregistrerades).

	VAD LOGGEN INTE ÄR:
	  · Den tar inte emot något från klienten. Det finns inget fjärranrop in
	    hit, och ingen klient kan lägga till en händelse, en poäng eller ett
	    resultat.
	  · Den mäter inte ridväg, rytm eller hinder. Det är INFRA-2B, och
	    instruktören och domaren får inte bygga på loggen förrän den
	    mätningen finns.
	  · Den gör inte klientens fysik auktoritativ. Farten ur StateSync och
	    klientens inspelning är inte evidens här.
	  · Den sparas inte. Persistens är ett eget beslut.

	── SCHEMA (version 1) ────────────────────────────────────────────

	  post = {
	    v, rittId, hastId, userId,
	    oppen      true tills `avsluta`,
	    satt       nil | "avslutad" | "avbruten",
	    overflode  true om händelser tappades vid taket,
	    tappade    antal tappade händelser,
	    handelser  = { { n, t, typ, data }, ... },
	  }

	`n` är serverns löpnummer i ritten (1, 2, 3 …). `t` är sekunder sedan
	uppsittningen, ändlig och aldrig minskande. `data` innehåller bara
	strängar, tal och sanningsvärden, och går därför att serialisera.

	── MINNE OCH KVARHÅLLNING ────────────────────────────────────────

	  · Högst `MAX_HANDELSER` händelser per ritt. Den sista platsen är
	    reserverad för `avslut`, så att en full ritt alltid kan stängas.
	    Tappas något sätts `overflode`, och posten är då aldrig bedömbar.
	    Ingen händelse tas bort tyst ur en post som ser komplett ut.
	  · Avslutade poster ligger kvar i en ring om `MAX_AVSLUTADE`. Den
	    äldsta HELA posten faller bort när ringen är full, och det räknas
	    i `gallrade()`. Det finns alltså ingen obegränsad historik.
	  · Öppna poster finns en per pågående ritt, och alla stängs av
	    `avsluta`.

	`ogonblick` returnerar en fryst djupkopia. En konsument kan inte skriva
	om historiken. ]]

local RidLogg = {}

RidLogg.VERSION = 1
RidLogg.MAX_HANDELSER = 256
RidLogg.MAX_AVSLUTADE = 32

type Handelse = { n: number, t: number, typ: string, data: { [string]: any } }
type Post = {
	v: number,
	rittId: string,
	hastId: string,
	userId: number,
	oppen: boolean,
	satt: string?,
	overflode: boolean,
	tappade: number,
	handelser: { Handelse },
	_start: number,
	_senastT: number,
}

local poster: { [string]: Post } = {}
local avslutadeOrdning: { string } = {}
local gallrade = 0

local function andligt(v: any): boolean
	return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge
end

--[[ Bara serialiserbara skalärer i data. Något annat är ett
	programmeringsfel i anroparen, och det ska synas i stället för att en
	Instance eller funktion tyst hamnar i historiken. ]]
local function ren(data: { [string]: any }?): { [string]: any }
	local ut = {}
	for k, v in pairs(data or {}) do
		assert(type(k) == "string", "RidLogg: nyckeln måste vara en sträng")
		local t = type(v)
		assert(t == "string" or t == "boolean" or (t == "number" and andligt(v)),
			"RidLogg: " .. k .. " är inte serialiserbar")
		ut[k] = v
	end
	return ut
end

local function tidFor(p: Post, nu: number): number
	local t = if andligt(nu) then nu - p._start else p._senastT
	if not andligt(t) or t < p._senastT then t = p._senastT end
	p._senastT = t
	return t
end

local function lagg(p: Post, typ: string, data: { [string]: any }?, nu: number, arAvslut: boolean): boolean
	local plats = RidLogg.MAX_HANDELSER - (if arAvslut then 0 else 1)
	if #p.handelser >= plats then
		p.overflode = true
		p.tappade += 1
		return false
	end
	table.insert(p.handelser, { n = #p.handelser + 1, t = tidFor(p, nu), typ = typ, data = ren(data) })
	return true
end

--[[ Startar en post för en ritt som just ACCEPTERATS. Ett rittId som
	redan finns startas inte om — märket är färskt per ritt, så det vore
	ett fel i anroparen, inte en ny ritt. ]]
function RidLogg.starta(rittId: string, hastId: string, userId: number, gangart: string, nu: number): boolean
	if type(rittId) ~= "string" or rittId == "" or poster[rittId] then return false end
	local start = if andligt(nu) then nu else 0
	local p: Post = {
		v = RidLogg.VERSION, rittId = rittId, hastId = tostring(hastId), userId = tonumber(userId) or 0,
		oppen = true, satt = nil, overflode = false, tappade = 0, handelser = {},
		_start = start, _senastT = 0,
	}
	poster[rittId] = p
	lagg(p, "uppsittning", { gangart = gangart }, start, false)
	return true
end

--[[ En accepterad ändring av serverns trappa. Bara i en ÖPPEN post: en
	sen ändring efter avslutet hör inte till ritten. ]]
function RidLogg.gangart(rittId: string?, data: { [string]: any }, nu: number): boolean
	local p = rittId and poster[rittId]
	if not p or not p.oppen then return false end
	return lagg(p, "gangart", data, nu, false)
end

--[[ Stänger posten EN gång. Andra anropet är ett nej, inte en andra
	avslutshändelse. ]]
function RidLogg.avsluta(rittId: string?, satt: string, orsak: string, nu: number): boolean
	local p = rittId and poster[rittId]
	if not p or not p.oppen then return false end
	assert(satt == "avslutad" or satt == "avbruten", "RidLogg: okänt sätt " .. tostring(satt))
	lagg(p, "avslut", { satt = satt, orsak = orsak }, nu, true)
	p.oppen = false
	p.satt = satt
	table.insert(avslutadeOrdning, p.rittId)
	while #avslutadeOrdning > RidLogg.MAX_AVSLUTADE do
		local aldst = table.remove(avslutadeOrdning, 1)
		poster[aldst] = nil
		gallrade += 1
	end
	return true
end

local function frys(t: any): any
	if type(t) ~= "table" then return t end
	local kopia = {}
	for k, v in pairs(t) do kopia[k] = frys(v) end
	return table.freeze(kopia)
end

--[[ En fryst djupkopia, eller nil. `bedombar` är sant bara för en
	stängd, normalt avslutad post utan tappade händelser — och även då är
	den bara livscykel och accepterade gångarter, inte en mätning av
	ridningen (se filhuvudet). ]]
function RidLogg.ogonblick(rittId: string?): any
	local p = rittId and poster[rittId]
	if not p then return nil end
	local ut = {
		v = p.v, rittId = p.rittId, hastId = p.hastId, userId = p.userId,
		oppen = p.oppen, satt = p.satt, overflode = p.overflode, tappade = p.tappade,
		bedombar = (not p.oppen) and p.satt == "avslutad" and not p.overflode,
		handelser = p.handelser,
	}
	return frys(ut)
end

function RidLogg.gallrade(): number
	return gallrade
end

--[[ Provkrok: nollställer allt mellan provblock. ]]
function RidLogg._glomForProv()
	poster = {}
	avslutadeOrdning = {}
	gallrade = 0
end

return RidLogg
