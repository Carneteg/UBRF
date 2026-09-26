--!strict
-- One session-local lesson. HorseService validates the actual mounted owner.
local Forsok = require(script.Parent.RidForsok)
local Volt = require(script.Parent.VoltObservation)
local Plats = require(script.Parent.RidPlatsObservation)
local Observation = require(script.Parent.RidObservation)

local VoltLektion = {}
local DEADLINE = 120
local MAX_REQUESTS = 16

local function tid(id)
	local b = Observation.ogonblick(id)
	return if b then b.tid else 0
end

function VoltLektion.ny(rittId: string, userId: number, hastId: string): any
	return { rittId = rittId, userId = userId, hastId = hastId, lage = "ready",
		revision = 0, hogsta = 0, svar = {}, ordning = {}, progress = 0, tips = "approach" }
end

function VoltLektion.bild(s): any
	return table.freeze({ rittId = s.rittId, forsokId = s.forsokId, revision = s.revision,
		sekvens = s.hogsta, lage = s.lage, progress = s.progress, tips = s.tips,
		resultat = s.resultat, referens = s.referens })
end

local function referens(s, p)
	return table.freeze({ ramId = p.ramId, u = p.dressyrMitt.u, v = p.dressyrMitt.v,
		radie = Volt.RADIE, plats = Plats.lektionsRam(s.rittId) })
end

local function andra(s, lage, tips)
	s.lage, s.tips = lage, tips
	s.revision += 1
end

local function agare(s, b): boolean
	return b ~= nil and b.rittId == s.rittId and b.userId == s.userId and b.hastId == s.hastId
end

local function aktiv(s): boolean
	local f = Forsok.ogonblick(s.forsokId)
	return agare(s, f) and f.tillstand == "aktivt"
end

local function stang(s, orsak, a): boolean
	if not aktiv(s) then return false end
	if not Forsok.slutfor(s.rittId, s.forsokId, orsak, tid(s.rittId), Volt.ogonblick(s.rittId)) then
		return false
	end
	if orsak == "slutford" then
		s.resultat = table.freeze({ forsokId = s.forsokId, rittId = s.rittId,
			userId = s.userId, hastId = s.hastId, armAfter = s.armAfter,
			start = Forsok.ogonblick(s.forsokId).start, avsnitt = a })
		s.progress = 100
		andra(s, "complete", "complete")
	else
		andra(s, "timeout", "timeout")
	end
	return true
end

local function punkt(s, p): boolean
	return agare(s, p) and p.iDressyr == true and p.punkt ~= nil and p.dressyrMitt ~= nil
		and p.ramId ~= nil and (p.status == "segment" or p.status == "baslinje")
end

local function avvikelse(p): number
	return math.abs(math.sqrt((p.punkt.u - p.dressyrMitt.u)^2
		+ (p.punkt.v - p.dressyrMitt.v)^2) - Volt.RADIE)
end

local function disarm(s, tips)
	Volt.lektionsGrans(s.rittId)
	s.armAfter, s.avsnitt, s.progress = nil, nil, 0
	andra(s, "approach", tips)
end

-- Called once after observation sampling, even if that sampling failed.
function VoltLektion.steg(s, now: number)
	if s.lage ~= "approach" and s.lage ~= "baseline" and s.lage ~= "riding" then return end
	if not aktiv(s) then andra(s, "closed", "closed"); return end
	if now >= s.deadline then stang(s, "tidsgrans", nil); return end
	local p = Plats.ogonblick(s.rittId)
	if p == s.sistaP then return end
	s.sistaP = p
	local v = Volt.ogonblick(s.rittId)
	if not agare(s, v) or v.version ~= Volt.VERSION then disarm(s, "unknown"); return end
	if s.lage == "approach" then
		if punkt(s, p) and avvikelse(p) <= 2 then
			s.armAfter = Volt.lektionsGrans(s.rittId)
			if s.armAfter == nil then return end
			s.referens = referens(s, p)
			s.avsnitt = nil
			andra(s, "baseline", "ride")
		end
		return
	end
	local r = s.referens
	if not punkt(s, p) or p.ramId ~= r.ramId or p.dressyrMitt.u ~= r.u
		or p.dressyrMitt.v ~= r.v then disarm(s, "unknown"); return end
	if avvikelse(p) > 4 then disarm(s, "line"); return end
	if s.lage == "baseline" then
		if v.status ~= "lektions_baslinje" then disarm(s, "unknown"); return end
		andra(s, "riding", "ride")
		return
	end
	local a = v.pagar
	local f = Forsok.ogonblick(s.forsokId)
	if not a or a.nr <= math.max(s.armAfter, f.start.voltHogsta)
		or a.ramId ~= r.ramId or a.referens.u ~= r.u or a.referens.v ~= r.v
		or a.referens.radie ~= r.radie or a.underlag == "okant"
		or (s.avsnitt ~= nil and s.avsnitt ~= a.nr) then
		disarm(s, "unknown"); return
	end
	s.avsnitt = a.nr
	if a.underlag ~= "tillrackligt" then return end
	if a.maxAvvikelse > 4 or a.motriktning > math.pi / 4 then disarm(s, "line"); return end
	if a.varv >= 1 then
		if a.medelAvvikelse <= 2 and a.aterkomst <= 3 then stang(s, "slutford", a)
		else disarm(s, "line") end
		return
	end
	local progress = math.clamp(math.floor(math.abs(a.netto) / (2 * math.pi) * 10) * 10, 0, 90)
	if progress ~= s.progress then s.progress = progress; s.revision += 1 end
end

function VoltLektion.begar(s, op: any, seq: any, now: number): (boolean, string?, any)
	if op == "sync" then
		VoltLektion.steg(s, now)
		return true, nil, VoltLektion.bild(s)
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
	if op ~= "finish" then VoltLektion.steg(s, now) end
	local ok, fel = false, nil
	if op == "finish" then
		if aktiv(s) then
			ok, fel = Forsok.avbryt(s.rittId, Forsok.nastaSekvens(s.rittId), s.forsokId,
				tid(s.rittId), Volt.ogonblick(s.rittId))
		else ok = true end
		if ok then andra(s, "closed", "closed") end
	elseif aktiv(s) or Forsok.aktivt(s.rittId) then fel = "active"
	elseif op == "retry" and s.lage ~= "complete" and s.lage ~= "timeout" then fel = "request"
	elseif op == "start" and s.lage ~= "ready" and s.lage ~= "closed" then fel = "request"
	else
		local p = Plats.ogonblick(s.rittId)
		if not punkt(s, p) then fel = "place"
		else
			local id
			ok, fel, id = Forsok.starta(s.rittId, Forsok.nastaSekvens(s.rittId), "storvolt",
				Volt.VERSION, tid(s.rittId), Volt.ogonblick(s.rittId))
			if ok then
				s.forsokId, s.deadline, s.startP = id, now + DEADLINE, p
				s.sistaP, s.armAfter, s.avsnitt, s.resultat = p, nil, nil, nil
				s.referens = referens(s, p)
				s.progress = 0
				andra(s, "approach", "approach")
			end
		end
	end
	local b = VoltLektion.bild(s)
	s.svar[seq] = { op = op, ok = ok, fel = fel, bild = b }
	table.insert(s.ordning, seq)
	while #s.ordning > MAX_REQUESTS do s.svar[table.remove(s.ordning, 1)] = nil end
	return ok, fel, b
end

return VoltLektion
