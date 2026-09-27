--!strict
--[[ ÖVERGÅNGSLEKTIONEN (`skritt_trav` + `trav_skritt`) —
	docs/TRANSITION-LESSON-CONTRACT.md.

	Skritt → trav vid träningsmål T1 → trav → skritt vid T2 → skritt.
	Samma livscykel och begäranregler som de andra lektionerna. Bevis bara
	ur befintliga observationer: RidLoggs accepterade övergångar efter
	Start, RidObservations observerade sträcka och RidPlatsObservations
	segment. En övergång räknas bara om BÅDA ändpunkterna i det observerade
	intervall där den först syns ligger i målzonen. T1 och T2 är
	träningsmål på mittlinjen, inga officiella bokstäver. Siffrorna är
	spelantaganden. Lektionen påstår övergångar PÅ AVSEDD PLATS, aldrig
	mjuka eller korrekt ridna övergångar. ]]
local Forsok = require(script.Parent.RidForsok)
local Observation = require(script.Parent.RidObservation)
local Plats = require(script.Parent.RidPlatsObservation)
local Logg = require(script.Parent.RidLogg)

local OvergangLektion = {}
OvergangLektion.OVNING = "overgangar"
OvergangLektion.VERSION = "server-overgang-1"

local DEADLINE = 180
local MAX_REQUESTS = 16
local M = 3 -- studs per meter, som BuildKit.M
local T1_V, T2_V = 18, 42 -- meter från A, på mittlinjen
local ZON_HALV = 3.0
local SKRITT_FORE = 3.0
local TRAV_M = 6.0
local SKRITT_EFTER = 2.0
OvergangLektion.GRANSER = table.freeze({ T1_V = T1_V, T2_V = T2_V, ZON_HALV = ZON_HALV,
	SKRITT_FORE = SKRITT_FORE, TRAV_M = TRAV_M, SKRITT_EFTER = SKRITT_EFTER, DEADLINE = DEADLINE })

local AKTIVA = { walk1 = true, trot = true, walk2 = true }

function OvergangLektion.ny(rittId: string, userId: number, hastId: string): any
	return { typ = "overgang", rittId = rittId, userId = userId, hastId = hastId, lage = "ready",
		revision = 0, hogsta = 0, svar = {}, ordning = {}, progress = 0, tips = "intro" }
end

function OvergangLektion.bild(s): any
	return table.freeze({ typ = "overgang", rittId = s.rittId, forsokId = s.forsokId,
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

local function referens(s, p)
	return table.freeze({ ramId = p.ramId, u = p.dressyrMitt.u, v1 = T1_V, v2 = T2_V,
		halv = ZON_HALV, plats = Plats.lektionsRam(s.rittId) })
end

--[[ Första fasen med nya baslinjer och samma tidsgräns: vid Start,
	efter observationsbrott, ramfel och fel plats/ordning. ]]
local function tillSkritt(s, tips)
	s.skritt1, s.trav, s.skritt2 = 0, 0, 0
	andra(s, "walk1", tips)
	satProgress(s, 0)
end

local function nyBaslinje(s, o, p, logg)
	s.sistaT, s.sistaD, s.sistaObs = o.tid, o.distans, o.obsTid
	s.sistaBrott = brottAntal(o)
	s.loggSett = #logg.handelser
	if p.ramId ~= nil and p.dressyrMitt ~= nil then
		s.ramId = p.ramId
		s.referens = referens(s, p)
	else
		s.ramId = nil
	end
end

--[[ Båda ändpunkterna i stegets observerade intervall inne i målzonen. ]]
local function iMal(s, p, malV: number): boolean
	local seg = p.segment
	if type(seg) ~= "table" or not seg.fran or not seg.till or not s.referens then return false end
	local function inne(q): boolean
		return math.abs(q.u - s.referens.u) <= ZON_HALV and math.abs(q.v - malV) <= ZON_HALV
	end
	return inne(seg.fran) and inne(seg.till)
end

local function stang(s, orsak): boolean
	if not aktiv(s) then return false end
	if not Forsok.slutfor(s.rittId, s.forsokId, orsak, obsTid(s.rittId), nil) then return false end
	if orsak == "slutford" then
		s.resultat = table.freeze({ forsokId = s.forsokId, rittId = s.rittId, userId = s.userId,
			hastId = s.hastId, mal = "T1->T2", travMeter = s.trav, skrittMeter = s.skritt2,
			vidT1 = s.vidT1, vidT2 = s.vidT2, start = Forsok.ogonblick(s.forsokId).start })
		s.progress = 100
		s.revision += 1
		andra(s, "complete", "complete")
	else
		andra(s, "timeout", "timeout")
	end
	return true
end

--[[ En övergång som stegets observerade intervall visar. Returnerar
	false om försöket återgick till första fasen. ]]
local function overgang(s, p, d): boolean
	local hjalp = d.orsak == "hjalp" and not d.tillRyggar and not d.franRyggar
	if s.lage == "walk1" then
		if d.till == "trot" and hjalp and d.fran == "walk" and s.skritt1 >= SKRITT_FORE
			and iMal(s, p, T1_V) then
			s.vidT1 = table.freeze({ u = p.segment.till.u, v = p.segment.till.v })
			s.trav = 0
			andra(s, "trot", "trot_on")
			return true
		elseif d.till == "trot" then
			tillSkritt(s, if s.skritt1 < SKRITT_FORE then "walk_first" else "trot_outside")
			return false
		elseif d.till ~= "walk" or d.tillRyggar then
			tillSkritt(s, "walk_only")
			return false
		end
		-- En övergång till skritt (t.ex. tillbaka efter fel plats) behåller fasen.
		return true
	elseif s.lage == "trot" then
		if d.till == "walk" and hjalp and d.fran == "trot" and s.trav >= TRAV_M
			and iMal(s, p, T2_V) then
			s.vidT2 = table.freeze({ u = p.segment.till.u, v = p.segment.till.v })
			s.skritt2 = 0
			andra(s, "walk2", "walk_calm")
			return true
		elseif d.till == "walk" and d.orsak == "trotthet" then
			tillSkritt(s, "tired")
			return false
		elseif d.till == "walk" then
			tillSkritt(s, if s.trav < TRAV_M then "trot_longer" else "walk_outside")
			return false
		end
		tillSkritt(s, "trot_only")
		return false
	end
	-- walk2: varje ny övergång före slutet bryter sekvensen.
	tillSkritt(s, "walk_only")
	return false
end

function OvergangLektion.steg(s, now: number, gangart: string?, ryggar: boolean?)
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
		local redanNollad = s.lage == "walk1" and s.skritt1 == 0 and not brott
			and s.ramId ~= nil and p.ramId == s.ramId and not logg.overflode
		nyBaslinje(s, o, p, logg)
		if not redanNollad then tillSkritt(s, "unknown") end
		return
	end
	if o.tid == s.sistaT then return end

	local observerad = o.obsTid > s.sistaObs
	local meter = (o.distans - s.sistaD) / M
	s.sistaT, s.sistaD, s.sistaObs = o.tid, o.distans, o.obsTid

	--[[ Nya övergångar i det här steget. Deras läge är stegets observerade
		intervall; är det inget giltigt segment finns ingen säker plats. Ett
		steg med övergångar krediterar ingen sträcka åt någon fas. ]]
	local nya = #logg.handelser > s.loggSett
	if nya then
		local giltigt = p.status == "segment" and type(p.segment) == "table"
		for i = s.loggSett + 1, #logg.handelser do
			local e = logg.handelser[i]
			if e.typ == "gangart" and type(e.data) == "table" then
				if not giltigt then
					s.loggSett = #logg.handelser
					tillSkritt(s, "unknown")
					return
				end
				if not overgang(s, p, e.data) then break end
			end
		end
		s.loggSett = #logg.handelser
		return
	end

	if not observerad or ryggar then return end
	if s.lage == "walk1" then
		if gangart == "walk" then s.skritt1 += meter end
		--[[ Återhämtningstipset står kvar tills spelaren faktiskt skrittar. ]]
		local tips = s.tips
		if s.skritt1 >= SKRITT_FORE then
			tips = "trot_at_t1"
		elseif gangart == "walk" and meter > 0 then
			tips = "walk_on"
		end
		andra(s, "walk1", tips)
		satProgress(s, 20 * math.min(s.skritt1 / SKRITT_FORE, 1))
	elseif s.lage == "trot" then
		if gangart == "trot" then s.trav += meter end
		if s.trav >= TRAV_M then andra(s, "trot", "walk_at_t2") end
		satProgress(s, 25 + 45 * math.min(s.trav / TRAV_M, 1))
	elseif s.lage == "walk2" then
		if gangart == "walk" then s.skritt2 += meter end
		satProgress(s, 75 + 25 * math.min(s.skritt2 / SKRITT_EFTER, 1))
		if s.skritt2 >= SKRITT_EFTER then stang(s, "slutford") end
	end
end

function OvergangLektion.begar(s, op: any, seq: any, now: number, gangart: string?,
	ryggar: boolean?): (boolean, string?, any)
	if op == "sync" then
		OvergangLektion.steg(s, now, gangart, ryggar)
		return true, nil, OvergangLektion.bild(s)
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
	if op ~= "finish" then OvergangLektion.steg(s, now, gangart, ryggar) end
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
			and p.iDressyr == true and p.ramId ~= nil) then
			fel = "place"
		else
			local id
			ok, fel, id = Forsok.starta(s.rittId, Forsok.nastaSekvens(s.rittId),
				OvergangLektion.OVNING, OvergangLektion.VERSION, o.tid, nil)
			if ok then
				s.forsokId, s.deadline = id, now + DEADLINE
				s.resultat, s.vidT1, s.vidT2 = nil, nil, nil
				nyBaslinje(s, o, p, logg)
				s.skritt1, s.trav, s.skritt2 = 0, 0, 0
				s.progress = 0
				andra(s, "walk1", "walk_on")
			end
		end
	end
	local b = OvergangLektion.bild(s)
	s.svar[seq] = { op = op, ok = ok, fel = fel, bild = b }
	table.insert(s.ordning, seq)
	while #s.ordning > MAX_REQUESTS do s.svar[table.remove(s.ordning, 1)] = nil end
	return ok, fel, b
end

return OvergangLektion
