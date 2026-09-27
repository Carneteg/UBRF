--!strict
--[[ SERPENTINLEKTIONEN — docs/SERPENTINE-LESSON-CONTRACT.md.

	En spelets träningsväg, INTE ett officiellt dressyrprogram: tre
	halvcirkelbågar som växlar sida, från startringen på mittlinjen nära A
	till slutringen nära C, med två korsningar av mittlinjen däremellan.
	Samma livscykel och begäranregler som de andra lektionerna. Bevis bara
	ur befintliga observationer: RidPlatsObservations segment (båda
	ändpunkterna, samma ram), RidObservations brottsräknare, RidLoggs
	gångartshändelser och den accepterade gångarten. Ingen voltbedömning
	och inga radiella voltmått. Lektionen påstår en ORDNAD genomridning av
	den ritade vägen inom korridoren, aldrig böjning, takt eller hjälper.
	Siffrorna är spelantaganden. ]]
local Forsok = require(script.Parent.RidForsok)
local Observation = require(script.Parent.RidObservation)
local Plats = require(script.Parent.RidPlatsObservation)
local Logg = require(script.Parent.RidLogg)

local SerpentinLektion = {}
SerpentinLektion.OVNING = "serpentin"
SerpentinLektion.VERSION = "server-serpentin-1"

local DEADLINE = 240
local MAX_REQUESTS = 16
local M = 3 -- studs per meter, som BuildKit.M
local R = 8.0 -- bågradie
local V0 = 6.0 -- startkorsningen, meter från A
local SIDOR = { 1, -1, 1 }
local BAGE = math.pi * R
local LANGD = 3 * BAGE
local KORR = 2.5
local RING = 3.0
local STEG_M = 0.5
local GROV_M = 4.0
local TVETYDIG_M = 3.0
local BAKAT_M = 1.5
local KORS_R = 3.5
local KORS_SLACK = 1.0
local SLUT_M = 0.5
SerpentinLektion.GRANSER = table.freeze({ R = R, V0 = V0, LANGD = LANGD, KORR = KORR, RING = RING,
	STEG_M = STEG_M, GROV_M = GROV_M, TVETYDIG_M = TVETYDIG_M, BAKAT_M = BAKAT_M,
	KORS_R = KORS_R, KORS_SLACK = KORS_SLACK, SLUT_M = SLUT_M, DEADLINE = DEADLINE })

local AKTIVA = { to_start = true, route = true }

function SerpentinLektion.ny(rittId: string, userId: number, hastId: string): any
	return { typ = "serpentin", rittId = rittId, userId = userId, hastId = hastId, lage = "ready",
		revision = 0, hogsta = 0, svar = {}, ordning = {}, progress = 0, tips = "intro", delmal = 0 }
end

function SerpentinLektion.bild(s): any
	return table.freeze({ typ = "serpentin", rittId = s.rittId, forsokId = s.forsokId,
		revision = s.revision, sekvens = s.hogsta, lage = s.lage, progress = s.progress,
		tips = s.tips, delmal = s.delmal, resultat = s.resultat, referens = s.referens })
end

local function andra(s, lage, tips)
	if s.lage == lage and s.tips == tips then return end
	s.lage, s.tips = lage, tips
	s.revision += 1
end

local function satDelmal(s, d: number)
	if d ~= s.delmal then s.delmal = d; s.revision += 1 end
end

local function satProgress(s, p: number)
	p = math.clamp(math.floor(p), 0, 99)
	if p ~= s.progress then s.progress = p; s.revision += 1 end
end

local function agare(s, b): boolean
	return b ~= nil and b.rittId == s.rittId and b.userId == s.userId and b.hastId == s.hastId
end

local function aktiv(s): boolean
	local f = Forsok.ogonblick(s.forsokId)
	return agare(s, f) and f.tillstand == "aktivt"
end

local function obsTid(id): number
	local o = Observation.ogonblick(id)
	return if o then o.tid else 0
end

local function brottAntal(o): number
	local g = o.giltighet
	if type(g) ~= "table" then return -1 end
	return (g.luckor or 0) + (g.saknade or 0) + (g.teleporter or 0) + (g.ogiltigaDt or 0)
end

--[[ Ryms vägen i den lösta layouten? Halva bredden ≥ R + 1 och längden
	≥ slutkorsningen + ringen. ]]
local function ryms(plats): boolean
	if type(plats) ~= "table" or type(plats.dressyr) ~= "table" then return false end
	local halvBredd = plats.dressyr.halvTvars / plats.studsPerMeter
	local langd = 2 * plats.dressyr.halvLangs / plats.studsPerMeter
	return halvBredd >= R + 1 and langd >= V0 + 6 * R + RING
end

local function referens(s, p, plats)
	return table.freeze({ ramId = p.ramId, u = p.dressyrMitt.u, v0 = V0, r = R, korr = KORR,
		ring = RING, sidor = table.freeze({ SIDOR[1], SIDOR[2], SIDOR[3] }), plats = plats })
end

local function korsV(k: number): number return V0 + 2 * R * k end

--[[ Vägläge S (meter längs vägen) för en punkt, eller nil om den ligger
	utanför korridoren. Andra värdet är sant för en tvetydig projektion
	(kandidater från olika bågar som inte stämmer överens). ]]
local function projicera(u0: number, u: number, v: number): (number?, boolean)
	local minS, maxS, basta, bastaD = math.huge, -math.huge, nil, math.huge
	for k = 1, 3 do
		local c = V0 + R + (k - 1) * 2 * R
		local side = SIDOR[k]
		local du, dv = u - u0, v - c
		local S, d
		if side * du >= 0 then
			local r = math.sqrt(du * du + dv * dv)
			--[[ R1: vinkeln ska ligga i [0, π] också exakt på mittlinjen.
				`side * du` blir −0 för en vänsterbåge när du = +0, och
				atan2(−0, negativt) kan ge −π i stället för π — en giltig
				korsning hade då blivit tvetydig. Rätt sida är redan vald här,
				så tvärsavståndet är en storlek: math.abs ger alltid +0/+tal. ]]
			local th = math.clamp(math.atan2(math.abs(du), -dv), 0, math.pi)
			S = (k - 1) * BAGE + th * R
			d = math.abs(r - R)
		else
			--[[ Fel sida om bågen: närmaste ände. ]]
			local d1 = math.sqrt(du * du + (dv + R) * (dv + R))
			local d2 = math.sqrt(du * du + (dv - R) * (dv - R))
			if d1 <= d2 then S, d = (k - 1) * BAGE, d1 else S, d = k * BAGE, d2 end
		end
		if d <= KORR then
			minS, maxS = math.min(minS, S), math.max(maxS, S)
			if d < bastaD then basta, bastaD = S, d end
		end
	end
	if basta == nil then return nil, false end
	return basta, maxS - minS > TVETYDIG_M
end

--[[ Provkrok: projektionen, för gränsfallen på mittlinjen (R1). ]]
function SerpentinLektion._projiceraForProv(u0: number, u: number, v: number): (number?, boolean)
	return projicera(u0, u, v)
end

local function stang(s, orsak): boolean
	if not aktiv(s) then return false end
	if not Forsok.slutfor(s.rittId, s.forsokId, orsak, obsTid(s.rittId), nil) then return false end
	if orsak == "slutford" then
		s.resultat = table.freeze({ forsokId = s.forsokId, rittId = s.rittId, userId = s.userId,
			hastId = s.hastId, rutt = "serpentin-3", meter = s.front,
			korsningar = table.freeze(table.clone(s.korsningar)),
			start = Forsok.ogonblick(s.forsokId).start })
		s.progress = 100
		s.revision += 1
		satDelmal(s, 4)
		andra(s, "complete", "complete")
	else
		andra(s, "timeout", "timeout")
	end
	return true
end

--[[ Tillbaka till startringen: all bågkredit och alla korsningar bort,
	samma tidsgräns. Inga fler nollställningar förrän spelaren åter är på
	vägen, så ingen återstartskedja. ]]
local function tillStart(s, tips)
	s.front, s.sistaS, s.sistaPunkt = 0, nil, nil
	s.korsningar = {}
	andra(s, "to_start", tips)
	satDelmal(s, 0)
	satProgress(s, 0)
end

local function nyBaslinje(s, o, p, logg)
	s.sistaT, s.sistaObs = o.tid, o.obsTid
	s.sistaBrott = brottAntal(o)
	s.loggSett = #logg.handelser
	local plats = Plats.lektionsRam(s.rittId)
	if p.ramId ~= nil and p.dressyrMitt ~= nil and ryms(plats) then
		s.ramId = p.ramId
		s.referens = referens(s, p, plats)
	else
		s.ramId = nil
	end
end

local function delmalFor(s): number
	local k = math.min(3, math.floor(s.front / BAGE) + 1)
	return math.min(k, #s.korsningar + 1)
end

local function vagTips(s): string
	if s.front >= LANGD - 4 then return "to_end" end
	local k = delmalFor(s)
	return if k == 1 then "loop1" elseif k == 2 then "loop2" else "loop3"
end

--[[ Ett giltigt segment på vägen. Varje prov längs kordan ska ligga i
	korridoren, vara entydigt och sammanhänga med föregående prov. Returnerar
	false om försöket gick tillbaka till startringen. ]]
local function paVagen(s, seg, kredit: boolean): boolean
	local u0 = s.referens.u
	local fu, fv, tu, tv = seg.fran.u, seg.fran.v, seg.till.u, seg.till.v
	local langd = math.sqrt((tu - fu) ^ 2 + (tv - fv) ^ 2)
	if langd > GROV_M then tillStart(s, "unknown"); return false end
	local n = math.max(1, math.ceil(langd / STEG_M))
	local fore = s.sistaPunkt or { u = fu, v = fv }
	--[[ Segmentet ska börja där förra slutade (samplingen och lektionen går
		i samma hjärtslag). Ett oobserverat mellanrum är okänd geometri. ]]
	if math.sqrt((fore.u - fu) ^ 2 + (fore.v - fv) ^ 2) > 0.05 then
		tillStart(s, "unknown"); return false
	end
	for i = 0, n do
		--[[ R1: ändpunkterna provas exakt som observerade, inte avrundade. ]]
		local u = if i == n then tu else fu + (tu - fu) * i / n
		local v = if i == n then tv else fv + (tv - fv) * i / n
		local S, tvetydig = projicera(u0, u, v)
		if S == nil then tillStart(s, "off_route"); return false end
		if tvetydig then tillStart(s, "unknown"); return false end
		local d = math.sqrt((u - fore.u) ^ 2 + (v - fore.v) ^ 2)
		if s.sistaS ~= nil and math.abs(S - s.sistaS) > 1.6 * d + 0.3 then
			tillStart(s, "unknown"); return false
		end
		if S < s.front - BAKAT_M then tillStart(s, "reverse"); return false end
		--[[ Nästa korsning: två på varandra följande prov på var sin sida
			om (eller på) mittlinjen, båda nära korsningspunkten. ]]
		local nasta = #s.korsningar + 1
		if nasta <= 2 then
			local kv = korsV(nasta)
			local nara = function(q) return math.sqrt((q.u - u0) ^ 2 + (q.v - kv) ^ 2) <= KORS_R end
			local punkt = { u = u, v = v }
			if (fore.u - u0) * (u - u0) <= 0 and nara(fore) and nara(punkt)
				and s.front >= nasta * BAGE - KORS_SLACK - BAKAT_M then
				table.insert(s.korsningar, table.freeze({ u = u, v = v }))
			end
		end
		if kredit and S > s.front then
			local tak = if #s.korsningar < 2 then (#s.korsningar + 1) * BAGE + KORS_SLACK else LANGD
			s.front = math.min(S, tak)
		end
		s.sistaS, fore = S, { u = u, v = v }
	end
	s.sistaPunkt = fore
	return true
end

function SerpentinLektion.steg(s, now: number, gangart: string?, ryggar: boolean?)
	if not AKTIVA[s.lage] then return end
	if not aktiv(s) then andra(s, "closed", "closed"); return end
	if now >= s.deadline then stang(s, "tidsgrans"); return end
	local o = Observation.ogonblick(s.rittId)
	local p = Plats.ogonblick(s.rittId)
	local logg = Logg.ogonblick(s.rittId)
	if not (agare(s, o) and agare(s, p) and logg and logg.rittId == s.rittId) then return end

	--[[ AVBROTT FÖRE TIDSJÄMFÖRELSEN, som i start/halt: brott, ramfel,
		ogiltigt läge och överfullt logg lämnar ingen återanvändbar bevisning. ]]
	local brott = brottAntal(o) ~= s.sistaBrott
	local ramFel = p.ramId == nil or p.ramId ~= s.ramId
	local lageFel = p.punkt == nil or (p.status ~= "segment" and p.status ~= "baslinje")
	if brott or ramFel or lageFel or logg.overflode then
		local redanNollad = s.lage == "to_start" and not brott and s.ramId ~= nil
			and p.ramId == s.ramId and not logg.overflode
		nyBaslinje(s, o, p, logg)
		if not redanNollad then tillStart(s, "unknown") end
		return
	end
	if o.tid == s.sistaT then return end
	local observerad = o.obsTid > s.sistaObs
	s.sistaT, s.sistaObs = o.tid, o.obsTid

	--[[ Galopp, ryggning eller en övergång dit i det här steget: tillbaka
		till startringen (skritt eller trav gäller). ]]
	local fel = ryggar == true or (gangart ~= "walk" and gangart ~= "trot" and gangart ~= "halt")
	for i = s.loggSett + 1, #logg.handelser do
		local e = logg.handelser[i]
		if e.typ == "gangart" and type(e.data) == "table" and (e.data.tillRyggar
			or (e.data.till ~= "walk" and e.data.till ~= "trot" and e.data.till ~= "halt")) then
			fel = true
		end
	end
	s.loggSett = #logg.handelser

	local seg = if p.status == "segment" and observerad then p.segment else nil
	if s.lage == "to_start" then
		if fel or type(seg) ~= "table" or not seg.till then return end
		local u0 = s.referens.u
		local q = seg.till
		local S, tvetydig = projicera(u0, q.u, q.v)
		local iRing = math.sqrt((q.u - u0) ^ 2 + (q.v - V0) ^ 2) <= RING
		if iRing and S ~= nil and not tvetydig and S <= RING then
			s.front, s.sistaS = math.max(S, 0), S
			s.sistaPunkt = { u = q.u, v = q.v }
			s.korsningar = {}
			andra(s, "route", "loop1")
			satDelmal(s, 1)
		end
		return
	end

	-- route
	if fel then tillStart(s, "walk_or_trot"); return end
	if type(seg) ~= "table" or not seg.fran or not seg.till then
		tillStart(s, "unknown"); return
	end
	if not paVagen(s, seg, gangart == "walk" or gangart == "trot") then return end
	local tips = vagTips(s)
	satDelmal(s, if tips == "to_end" then 4 else delmalFor(s))
	andra(s, "route", tips)
	satProgress(s, 99 * s.front / LANGD)
	local q = seg.till
	local iSlut = math.sqrt((q.u - s.referens.u) ^ 2 + (q.v - korsV(3)) ^ 2) <= RING
	if s.front >= LANGD - SLUT_M and #s.korsningar >= 2 and iSlut then stang(s, "slutford") end
end

function SerpentinLektion.begar(s, op: any, seq: any, now: number, gangart: string?,
	ryggar: boolean?): (boolean, string?, any)
	if op == "sync" then
		SerpentinLektion.steg(s, now, gangart, ryggar)
		return true, nil, SerpentinLektion.bild(s)
	end
	if op ~= "start" and op ~= "retry" and op ~= "finish" then return false, "unknown", nil end
	if type(seq) ~= "number" or seq ~= seq or seq < 1 or seq > 2147483647 or seq % 1 ~= 0 then
		return false, "request", nil
	end
	local prev = s.svar[seq]
	if prev then
		if prev.op ~= op then return false, "request", nil end
		return prev.ok, prev.fel, prev.bild
	end
	if seq <= s.hogsta then return false, "stale", nil end
	s.hogsta = seq
	if op ~= "finish" then SerpentinLektion.steg(s, now, gangart, ryggar) end
	local ok, fel = false, nil
	if op == "finish" then
		if aktiv(s) then
			ok, fel = Forsok.avbryt(s.rittId, Forsok.nastaSekvens(s.rittId), s.forsokId,
				obsTid(s.rittId), nil)
		else ok = true end
		if ok then andra(s, "closed", "closed") end
	elseif aktiv(s) or Forsok.aktivt(s.rittId) then fel = "active"
	elseif op == "retry" and s.lage ~= "complete" and s.lage ~= "timeout" then fel = "request"
	elseif op == "start" and s.lage ~= "ready" and s.lage ~= "closed" then fel = "request"
	else
		local o = Observation.ogonblick(s.rittId)
		local p = Plats.ogonblick(s.rittId)
		local logg = Logg.ogonblick(s.rittId)
		if not (agare(s, o) and agare(s, p) and logg and p.punkt and p.dressyrMitt
			and p.iDressyr == true and p.ramId ~= nil and ryms(Plats.lektionsRam(s.rittId))) then
			fel = "place"
		else
			local id
			ok, fel, id = Forsok.starta(s.rittId, Forsok.nastaSekvens(s.rittId),
				SerpentinLektion.OVNING, SerpentinLektion.VERSION, o.tid, nil)
			if ok then
				s.forsokId, s.deadline = id, now + DEADLINE
				s.resultat = nil
				nyBaslinje(s, o, p, logg)
				s.progress, s.delmal = 0, 0
				s.front, s.sistaS, s.sistaPunkt, s.korsningar = 0, nil, nil, {}
				s.revision += 1
				andra(s, "to_start", "to_start")
			end
		end
	end
	local b = SerpentinLektion.bild(s)
	s.svar[seq] = { op = op, ok = ok, fel = fel, bild = b }
	table.insert(s.ordning, seq)
	while #s.ordning > MAX_REQUESTS do s.svar[table.remove(s.ordning, 1)] = nil end
	return ok, fel, b
end

return SerpentinLektion
