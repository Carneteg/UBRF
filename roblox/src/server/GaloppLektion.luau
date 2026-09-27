--!strict
--[[ GALOPPFATTNING VID TRÄNINGSMÅL K (DELVIS) — docs/CANTER-DEPARTURE-LESSON-CONTRACT.md.

	En begärd övergång trav → galopp inne i träningsmålet K, efter färsk
	trav, följd av observerad galopp. INTE igenkänning av höger/vänster
	galopp och ingen bedömning av fattningens kvalitet: galoppsidan är ett
	uttryckligt, obyggt beroende. Samma livscykel och begäranregler som de
	andra lektionerna. Bevis bara ur befintliga observationer: RidLoggs
	accepterade övergångar (`orsak = "hjalp"` ur `onRidingIntent`), RidObservations
	observerade sträcka och RidPlatsObservations segment. En fattning
	räknas bara om BÅDA ändpunkterna i det observerade intervall där den
	först syns ligger i K. TIDEN binds genom loggens ORDNING, inte genom
	klockor: RidLoggs `t` är sekunder sedan uppsittningen i loggens egen
	klocka (`_start` exponeras inte) och jämförs aldrig med lektionens
	`now`. En händelse hör till stegets intervall om den lagts till efter
	föregående bearbetade steg och steget har exakt ETT nytt giltigt
	observerat segment (samplingen och lektionen går i samma hjärtslag). K är ett
	träningsmål på mittlinjen, ingen bokstav. Siffrorna är spelantaganden. ]]
local Forsok = require(script.Parent.RidForsok)
local Observation = require(script.Parent.RidObservation)
local Plats = require(script.Parent.RidPlatsObservation)
local Logg = require(script.Parent.RidLogg)

local GaloppLektion = {}
GaloppLektion.OVNING = "galoppfattning"
GaloppLektion.VERSION = "server-galopp-1"

local DEADLINE = 150
local MAX_REQUESTS = 16
local M = 3 -- studs per meter, som BuildKit.M
local K_V = 30 -- meter från A, på mittlinjen
local ZON_R = 3.0 -- K är en cirkel, samma radie som guidens ring
local TRAV_M = 8.0
local GALOPP_M = 6.0
GaloppLektion.GRANSER = table.freeze({ K_V = K_V, ZON_R = ZON_R, TRAV_M = TRAV_M,
	GALOPP_M = GALOPP_M, DEADLINE = DEADLINE })

local AKTIVA = { trot = true, canter = true }

function GaloppLektion.ny(rittId: string, userId: number, hastId: string): any
	return { typ = "galopp", rittId = rittId, userId = userId, hastId = hastId, lage = "ready",
		revision = 0, hogsta = 0, svar = {}, ordning = {}, progress = 0, tips = "intro" }
end

function GaloppLektion.bild(s): any
	return table.freeze({ typ = "galopp", rittId = s.rittId, forsokId = s.forsokId,
		revision = s.revision, sekvens = s.hogsta, lage = s.lage, progress = s.progress,
		tips = s.tips, resultat = s.resultat, referens = s.referens })
end

local function andra(s, lage, tips)
	if s.lage == lage and s.tips == tips then return end
	s.lage, s.tips = lage, tips
	s.revision += 1
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

local function ryms(plats): boolean
	if type(plats) ~= "table" or type(plats.dressyr) ~= "table" then return false end
	local halvBredd = plats.dressyr.halvTvars / plats.studsPerMeter
	local langd = 2 * plats.dressyr.halvLangs / plats.studsPerMeter
	return halvBredd >= ZON_R + 1 and langd >= K_V + GALOPP_M
end

local function referens(s, p, plats)
	return table.freeze({ ramId = p.ramId, u = p.dressyrMitt.u, v = K_V, radie = ZON_R, plats = plats })
end

--[[ Förberedelsen från början, med nya baslinjer och samma tidsgräns. ]]
local function tillTrav(s, tips)
	s.trav, s.galopp = 0, 0
	andra(s, "trot", tips)
	satProgress(s, 0)
end

local function segmentAntal(o): number
	local g = o.giltighet
	return if type(g) == "table" and type(g.segment) == "number" then g.segment else -1
end

local function nyBaslinje(s, o, p, logg)
	s.sistaT, s.sistaD, s.sistaObs = o.tid, o.distans, o.obsTid
	s.sistaBrott = brottAntal(o)
	s.sistaSeg = segmentAntal(o)
	s.loggSett = #logg.handelser
	s.sistaInne = p.iDressyr == true
	local plats = Plats.lektionsRam(s.rittId)
	if p.ramId ~= nil and p.dressyrMitt ~= nil and ryms(plats) then
		s.ramId = p.ramId
		s.referens = referens(s, p, plats)
	else
		s.ramId = nil
	end
end

--[[ Båda ändpunkterna i stegets observerade intervall inne i K. ]]
local function iK(s, p): boolean
	local seg = p.segment
	if type(seg) ~= "table" or not seg.fran or not seg.till or not s.referens then return false end
	local function inne(q): boolean
		return math.sqrt((q.u - s.referens.u) ^ 2 + (q.v - K_V) ^ 2) <= ZON_R
	end
	return inne(seg.fran) and inne(seg.till)
end

local function stang(s, orsak): boolean
	if not aktiv(s) then return false end
	if not Forsok.slutfor(s.rittId, s.forsokId, orsak, obsTid(s.rittId), nil) then return false end
	if orsak == "slutford" then
		s.resultat = table.freeze({ forsokId = s.forsokId, rittId = s.rittId, userId = s.userId,
			hastId = s.hastId, ovning = GaloppLektion.OVNING, mal = "K", vidK = s.vidK,
			travMeter = s.travVid, galoppMeter = s.galopp, galoppsida = "ej_bedomd",
			start = Forsok.ogonblick(s.forsokId).start })
		s.progress = 100
		s.revision += 1
		andra(s, "complete", "complete")
	else
		andra(s, "timeout", "timeout")
	end
	return true
end

--[[ En övergång i stegets intervall. false = försöket gick till förberedelsen. ]]
local function overgang(s, p, d): boolean
	local hjalp = d.orsak == "hjalp" and not d.tillRyggar and not d.franRyggar
	if s.lage == "trot" then
		if d.till == "canter" and d.fran == "trot" and hjalp then
			if s.trav < TRAV_M then tillTrav(s, "trot_first"); return false end
			if not iK(s, p) then tillTrav(s, "canter_outside"); return false end
			s.vidK = table.freeze({ u = p.segment.till.u, v = p.segment.till.v })
			s.travVid, s.galopp = s.trav, 0
			andra(s, "canter", "canter_on")
			return true
		elseif d.fran == "trot" then
			-- Ut ur trav på annat sätt (skritt, halt, trötthet): färsk trav igen.
			tillTrav(s, "trot_on"); return false
		end
		-- In i trav, eller mellan andra gångarter: förberedelsen står kvar (0 om inte trav).
		return true
	end
	-- canter: varje övergång före klart bryter.
	tillTrav(s, if d.orsak == "trotthet" then "tired" else "canter_longer")
	return false
end

function GaloppLektion.steg(s, now: number, gangart: string?, ryggar: boolean?)
	if not AKTIVA[s.lage] then return end
	if not aktiv(s) then andra(s, "closed", "closed"); return end
	if now >= s.deadline then stang(s, "tidsgrans"); return end
	local o = Observation.ogonblick(s.rittId)
	local p = Plats.ogonblick(s.rittId)
	local logg = Logg.ogonblick(s.rittId)
	if not (agare(s, o) and agare(s, p) and logg and logg.rittId == s.rittId) then return end

	--[[ AVBROTT FÖRE TIDSJÄMFÖRELSEN, som i de andra lektionerna. ]]
	local brott = brottAntal(o) ~= s.sistaBrott
	local ramFel = p.ramId == nil or p.ramId ~= s.ramId
	local lageFel = p.punkt == nil or (p.status ~= "segment" and p.status ~= "baslinje")
	if brott or ramFel or lageFel or logg.overflode then
		local redanNollad = s.lage == "trot" and s.trav == 0 and not brott
			and s.ramId ~= nil and p.ramId == s.ramId and not logg.overflode
		nyBaslinje(s, o, p, logg)
		if not redanNollad then tillTrav(s, "unknown") end
		return
	end
	if o.tid == s.sistaT then return end

	local observerad = o.obsTid > s.sistaObs
	local meter = (o.distans - s.sistaD) / M
	local nyaSeg = segmentAntal(o) - s.sistaSeg
	s.sistaT, s.sistaD, s.sistaObs, s.sistaSeg = o.tid, o.distans, o.obsTid, segmentAntal(o)
	local varInne = s.sistaInne
	s.sistaInne = p.iDressyr == true

	--[[ Nya övergångar i steget: deras läge är stegets observerade intervall.
		Ett steg med övergångar krediterar ingen sträcka åt någon fas. ]]
	if #logg.handelser > s.loggSett then
		--[[ Händelsens läge: ett giltigt segment, observerat, och exakt ett
			nytt segment sedan förra bearbetade steget — annars är intervallet
			inte entydigt stegets, och läget är okänt. ]]
		local giltigt = p.status == "segment" and type(p.segment) == "table" and observerad
			and nyaSeg == 1
		for i = s.loggSett + 1, #logg.handelser do
			local e = logg.handelser[i]
			if e.typ == "gangart" and type(e.data) == "table" then
				if not giltigt then
					s.loggSett = #logg.handelser
					tillTrav(s, "unknown")
					return
				end
				if not overgang(s, p, e.data) then break end
			end
		end
		s.loggSett = #logg.handelser
		return
	end

	if not observerad or ryggar or not (varInne and p.iDressyr == true) then return end
	if s.lage == "trot" then
		if gangart == "trot" then s.trav += meter end
		local tips = s.tips
		if s.trav >= TRAV_M then
			tips = "canter_at_k"
		elseif gangart == "trot" and meter > 0 then
			tips = "trot_on"
		end
		andra(s, "trot", tips)
		satProgress(s, 50 * math.min(s.trav / TRAV_M, 1))
	elseif s.lage == "canter" then
		if gangart == "canter" then s.galopp += meter end
		satProgress(s, 60 + 39 * math.min(s.galopp / GALOPP_M, 1))
		if s.galopp >= GALOPP_M then stang(s, "slutford") end
	end
end

function GaloppLektion.begar(s, op: any, seq: any, now: number, gangart: string?,
	ryggar: boolean?): (boolean, string?, any)
	if op == "sync" then
		GaloppLektion.steg(s, now, gangart, ryggar)
		return true, nil, GaloppLektion.bild(s)
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
	if op ~= "finish" then GaloppLektion.steg(s, now, gangart, ryggar) end
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
				GaloppLektion.OVNING, GaloppLektion.VERSION, o.tid, nil)
			if ok then
				s.forsokId, s.deadline = id, now + DEADLINE
				s.resultat, s.vidK, s.travVid = nil, nil, nil
				nyBaslinje(s, o, p, logg)
				s.trav, s.galopp = 0, 0
				s.progress = 0
				s.revision += 1
				andra(s, "trot", "trot_on")
			end
		end
	end
	local b = GaloppLektion.bild(s)
	s.svar[seq] = { op = op, ok = ok, fel = fel, bild = b }
	table.insert(s.ordning, seq)
	while #s.ordning > MAX_REQUESTS do s.svar[table.remove(s.ordning, 1)] = nil end
	return ok, fel, b
end

return GaloppLektion
