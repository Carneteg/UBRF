--!strict
--[[ START/HALT-LEKTIONEN (`halt_skritt`) — docs/HALT-LESSON-CONTRACT.md.

	Samma livscykel som VoltLektion: ett FORSOK1-försök, samma begäran-
	och dublettregler, samma stängningsorsaker. Egen uppgift: halt, skritt
	på spelarens hjälp, halt vid X. Bara befintliga observationer:
	  · serverns accepterade gångart (skickas in av HorseService),
	  · RidLoggs gångartshändelser efter Start (orsak skiljer spelarens
	    hjälp från trötthet),
	  · RidObservations observerade sträcka och tid,
	  · RidPlatsObservations läge och ram.
	Siffrorna är spelantaganden, inte uppmätta ridfakta. Lektionen
	påstår ett halt PÅ AVSEDD PLATS, aldrig ett korrekt samlat halt. ]]
local Forsok = require(script.Parent.RidForsok)
local Observation = require(script.Parent.RidObservation)
local Plats = require(script.Parent.RidPlatsObservation)
local Logg = require(script.Parent.RidLogg)

local HaltLektion = {}
HaltLektion.OVNING = "starthalt"
HaltLektion.VERSION = "server-halt-1"

local DEADLINE = 120
local MAX_REQUESTS = 16
local M = 3 -- studs per meter, som BuildKit.M
local ZON_R = 1.5
local STILLA_M = 0.15
local HALT_FORE = 1.0
local SKRITT_M = 4.0
local HALT_EFTER = 2.0
HaltLektion.GRANSER = table.freeze({ ZON_R = ZON_R, STILLA_M = STILLA_M, HALT_FORE = HALT_FORE,
	SKRITT_M = SKRITT_M, HALT_EFTER = HALT_EFTER, DEADLINE = DEADLINE })

local AKTIVA = { halt1 = true, walk = true }

function HaltLektion.ny(rittId: string, userId: number, hastId: string): any
	return { typ = "halt", rittId = rittId, userId = userId, hastId = hastId, lage = "ready",
		revision = 0, hogsta = 0, svar = {}, ordning = {}, progress = 0, tips = "intro" }
end

function HaltLektion.bild(s): any
	return table.freeze({ typ = "halt", rittId = s.rittId, forsokId = s.forsokId,
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

local function referens(s, p)
	return table.freeze({ ramId = p.ramId, u = p.dressyrMitt.u, v = p.dressyrMitt.v,
		radie = ZON_R, plats = Plats.lektionsRam(s.rittId) })
end

--[[ Antalet observationsbrott hittills (lucka, saknad rot, teleport,
	ogiltigt dt). Ett ogiltigt dt räknas upp UTAN att `tid` ändras, så
	räknaren — inte tiden — avgör om något hänt sedan förra steget. ]]
local function brottAntal(o): number
	local g = o.giltighet
	if type(g) ~= "table" then return -1 end
	return (g.luckor or 0) + (g.saknade or 0) + (g.teleporter or 0) + (g.ogiltigaDt or 0)
end

--[[ Nollställer uppgiften till första steget i samma försök: nya
	baslinjer, ingen gammal bevisning, samma tidsgräns. Används vid Start,
	efter ett observationsbrott och när ramen byts eller saknas
	(återhämtning utan Retry). Saknas en giltig ram hålls `ramId` tomt, så
	att nästa giltiga ram baslinjeras på nytt i stället för att fogas ihop
	med den gamla. ]]
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
	s.stilla1, s.haltTid, s.skritt = 0, 0, 0
	s.harSkritt, s.haltHjalp, s.okant = false, false, false
end

local function stang(s, orsak): boolean
	if not aktiv(s) then return false end
	if not Forsok.slutfor(s.rittId, s.forsokId, orsak, obsTid(s.rittId), nil) then return false end
	if orsak == "slutford" then
		s.resultat = table.freeze({ forsokId = s.forsokId, rittId = s.rittId, userId = s.userId,
			hastId = s.hastId, mal = "X", zonRadie = ZON_R, skrittMeter = s.skritt,
			haltSekunder = s.haltTid, slutpunkt = s.slutpunkt,
			start = Forsok.ogonblick(s.forsokId).start })
		s.progress = 100
		s.revision += 1
		andra(s, "complete", "complete")
	else
		andra(s, "timeout", "timeout")
	end
	return true
end

--[[ Läser RidLoggs nya gångartshändelser sedan förra steget. Bara en
	övergång på spelarens hjälp ger skritt- eller haltbevis; trav, galopp
	och ryggning nollar skrittbeviset. Ett överfullt logg gör försöket
	okänt: då finns ingen säker bild av övergångarna. ]]
local function lasOvergangar(s, logg)
	for i = s.loggSett + 1, #logg.handelser do
		local e = logg.handelser[i]
		local d = e.data
		if e.typ == "gangart" and type(d) == "table" then
			if d.till == "walk" and not d.tillRyggar then
				s.harSkritt = d.orsak == "hjalp"
			elseif d.till == "halt" and not d.tillRyggar then
				s.haltHjalp = d.orsak == "hjalp"
			else
				s.harSkritt, s.haltHjalp, s.skritt = false, false, 0
			end
		end
	end
	s.loggSett = #logg.handelser
	if logg.overflode then s.okant = true end
end

function HaltLektion.steg(s, now: number, gangart: string?, ryggar: boolean?)
	if not AKTIVA[s.lage] then return end
	if not aktiv(s) then andra(s, "closed", "closed"); return end
	if now >= s.deadline then stang(s, "tidsgrans"); return end
	local o = Observation.ogonblick(s.rittId)
	local p = Plats.ogonblick(s.rittId)
	local logg = Logg.ogonblick(s.rittId)
	if not (agare(s, o) and agare(s, p) and logg and logg.rittId == s.rittId) then return end

	--[[ AVBROTT FÖRE TIDSJÄMFÖRELSEN. Ett observationsbrott (också ett
		ogiltigt dt som inte flyttar `tid`), en ram som bytts eller saknas,
		eller en ridplatsbild utan giltigt läge lämnar ingen återanvändbar
		bevisning: tillbaka till första uppgiften med nya baslinjer, samma
		tidsgräns. Okänt är inte uppmätt noll — inget räknas över brottet. ]]
	local brott = brottAntal(o) ~= s.sistaBrott
	local ramFel = p.ramId == nil or p.ramId ~= s.ramId
	local lageFel = p.punkt == nil or (p.status ~= "segment" and p.status ~= "baslinje")
	if brott or ramFel or lageFel then
		local redanNollad = s.lage == "halt1" and s.stilla1 == 0 and not brott
			and s.ramId ~= nil and p.ramId == s.ramId
		nyBaslinje(s, o, p, logg)
		if not redanNollad then
			andra(s, "halt1", "unknown")
			satProgress(s, 0)
		end
		return
	end
	if o.tid == s.sistaT then return end

	lasOvergangar(s, logg)

	local dt = o.tid - s.sistaT
	local observerad = o.obsTid > s.sistaObs
	local meter = (o.distans - s.sistaD) / M
	s.sistaT, s.sistaD, s.sistaObs = o.tid, o.distans, o.obsTid
	local platsOk = p.punkt ~= nil and p.ramId == s.ramId
		and (p.status == "segment" or p.status == "baslinje")
	local halt = gangart == "halt" and not ryggar
	local stilla = observerad and platsOk and halt and meter <= STILLA_M
	local iZon = false
	if platsOk then
		local du, dv = p.punkt.u - s.referens.u, p.punkt.v - s.referens.v
		iZon = math.sqrt(du * du + dv * dv) <= ZON_R
	end

	if s.lage == "halt1" then
		s.stilla1 = if stilla then s.stilla1 + dt else 0
		satProgress(s, 15 * math.min(s.stilla1 / HALT_FORE, 1))
		andra(s, "halt1", if s.okant then "unknown" else "halt_first")
		if s.stilla1 >= HALT_FORE and not s.okant then
			--[[ Skrittbeviset måste komma EFTER det första haltet. ]]
			s.harSkritt, s.haltHjalp, s.skritt = false, false, 0
			andra(s, "walk", "walk_on")
		end
		return
	end

	-- lage == "walk": skritt på hjälp, verklig sträcka, halt på hjälp vid X.
	if observerad and gangart == "walk" and not ryggar and s.harSkritt then
		s.skritt += meter
	end
	if s.okant then
		s.haltTid = 0
		andra(s, "walk", "unknown")
	elseif ryggar or (gangart ~= "walk" and gangart ~= "halt") then
		s.haltTid = 0
		andra(s, "walk", "walk_only")
	elseif s.skritt < SKRITT_M then
		s.haltTid = 0
		andra(s, "walk", if s.harSkritt then "to_x" else "walk_on")
	elseif halt and s.haltHjalp and stilla and iZon then
		s.haltTid += dt
		s.slutpunkt = table.freeze({ u = p.punkt.u, v = p.punkt.v })
		andra(s, "walk", "hold")
	elseif halt and platsOk and not iZon then
		s.haltTid = 0
		andra(s, "walk", "halt_outside")
	else
		s.haltTid = 0
		andra(s, "walk", "halt_at_x")
	end
	satProgress(s, 15 + 45 * math.min(s.skritt / SKRITT_M, 1) + 40 * math.min(s.haltTid / HALT_EFTER, 1))
	if s.haltTid >= HALT_EFTER then stang(s, "slutford") end
end

function HaltLektion.begar(s, op: any, seq: any, now: number, gangart: string?,
	ryggar: boolean?): (boolean, string?, any)
	if op == "sync" then
		HaltLektion.steg(s, now, gangart, ryggar)
		return true, nil, HaltLektion.bild(s)
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
	if op ~= "finish" then HaltLektion.steg(s, now, gangart, ryggar) end
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
			ok, fel, id = Forsok.starta(s.rittId, Forsok.nastaSekvens(s.rittId), HaltLektion.OVNING,
				HaltLektion.VERSION, o.tid, nil)
			if ok then
				s.forsokId, s.deadline = id, now + DEADLINE
				s.resultat, s.slutpunkt, s.progress = nil, nil, 0
				nyBaslinje(s, o, p, logg)
				andra(s, "halt1", "halt_first")
			end
		end
	end
	local b = HaltLektion.bild(s)
	s.svar[seq] = { op = op, ok = ok, fel = fel, bild = b }
	table.insert(s.ordning, seq)
	while #s.ordning > MAX_REQUESTS do s.svar[table.remove(s.ordning, 1)] = nil end
	return ok, fel, b
end

return HaltLektion
