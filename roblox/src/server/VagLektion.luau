--!strict
--[[ RIDVÄGAR: MITTLINJEN OCH DIAGONALEN — docs/RIDING-PATH-LESSON-CONTRACT.md.

	Två spelets träningsvägar, INTE officiella program och inga påhittade
	bokstäver: en rak mittlinje och ett diagonalt sidbyte i den lösta
	dressyrramen. Figuren är lektionstypen (`vag_mitt`, `vag_diag`), så den
	ingår i ritt-bokens typmedvetna identitet. Samma livscykel och
	begäranregler som de andra lektionerna. Bevis bara ur befintliga
	observationer: RidPlatsObservations segment, RidObservations
	brottsräknare, RidLoggs gångartshändelser och den accepterade gångarten.
	Lektionen påstår en ORDNAD genomridning av linjen inom korridoren, aldrig
	hästens rakhet, böjning eller hjälper. Siffrorna är spelantaganden. ]]
local Forsok = require(script.Parent.RidForsok)
local Observation = require(script.Parent.RidObservation)
local Plats = require(script.Parent.RidPlatsObservation)
local Logg = require(script.Parent.RidLogg)

local VagLektion = {}
VagLektion.OVNING = "ridvag"
VagLektion.VERSION = "server-vag-1"

local DEADLINE = 120
local MAX_REQUESTS = 16
local KORR = 2.0
local ZON = 2.0
local GROV_M = 4.0
local BAKAT_M = 1.0
local SLUT_M = 0.5
--[[ Figurerna i meter, relativt mittlinjen u0 och A (v = 0). ]]
local FIGURER = table.freeze({
	vag_mitt = table.freeze({ du0 = 0, v0 = 6, du1 = 0, v1 = 54 }),
	vag_diag = table.freeze({ du0 = -7, v0 = 8, du1 = 7, v1 = 52 }),
})
VagLektion.FIGURER = FIGURER
VagLektion.GRANSER = table.freeze({ KORR = KORR, ZON = ZON, GROV_M = GROV_M, BAKAT_M = BAKAT_M,
	SLUT_M = SLUT_M, DEADLINE = DEADLINE })

local AKTIVA = { to_start = true, route = true }

function VagLektion.ny(rittId: string, userId: number, hastId: string, typ: string?): any
	local figur = if typ == "vag_diag" then "vag_diag" else "vag_mitt"
	return { typ = figur, rittId = rittId, userId = userId, hastId = hastId, lage = "ready",
		revision = 0, hogsta = 0, svar = {}, ordning = {}, progress = 0, tips = "intro", delmal = 0 }
end

function VagLektion.bild(s): any
	return table.freeze({ typ = s.typ, rittId = s.rittId, forsokId = s.forsokId,
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

--[[ Ryms figurerna i layouten? Halva bredden ≥ 7 + korridor + 1 och
	längden ≥ 54 + ringen. ]]
local function ryms(plats): boolean
	if type(plats) ~= "table" or type(plats.dressyr) ~= "table" then return false end
	local halvBredd = plats.dressyr.halvTvars / plats.studsPerMeter
	local langd = 2 * plats.dressyr.halvLangs / plats.studsPerMeter
	return halvBredd >= 7 + KORR + 1 and langd >= 54 + ZON
end

local function referens(s, p, plats)
	local f = FIGURER[s.typ]
	local u0 = p.dressyrMitt.u
	local a = { u = u0 + f.du0, v = f.v0 }
	local b = { u = u0 + f.du1, v = f.v1 }
	local L = math.sqrt((b.u - a.u) ^ 2 + (b.v - a.v) ^ 2)
	return table.freeze({ ramId = p.ramId, figur = s.typ, u0 = a.u, v0 = a.v, u1 = b.u, v1 = b.v,
		langd = L, korr = KORR, ring = ZON, plats = plats })
end

--[[ Läget längs linjen (s, från P0) och avståndet från den (e), i meter. ]]
local function linje(ref, q): (number, number)
	local du, dv = (ref.u1 - ref.u0) / ref.langd, (ref.v1 - ref.v0) / ref.langd
	local x, y = q.u - ref.u0, q.v - ref.v0
	return x * du + y * dv, math.abs(x * dv - y * du)
end

local function iKorridor(ref, q): boolean
	local sL, e = linje(ref, q)
	return e <= KORR and sL >= -ZON and sL <= ref.langd + ZON
end

local function stang(s, orsak): boolean
	if not aktiv(s) then return false end
	if not Forsok.slutfor(s.rittId, s.forsokId, orsak, obsTid(s.rittId), nil) then return false end
	if orsak == "slutford" then
		s.resultat = table.freeze({ forsokId = s.forsokId, rittId = s.rittId, userId = s.userId,
			hastId = s.hastId, figur = s.typ, meter = s.langst - s.armS, armS = s.armS,
			slutS = s.langst, langd = s.referens.langd,
			start = Forsok.ogonblick(s.forsokId).start })
		s.progress = 100
		s.revision += 1
		andra(s, "complete", "complete")
	else
		andra(s, "timeout", "timeout")
	end
	return true
end

--[[ Tillbaka till startringen: all linjekredit bort, samma tidsgräns. Inga
	fler nollställningar förrän spelaren åter är armerad. ]]
local function tillStart(s, tips)
	s.armS, s.langst, s.sistaPunkt = nil, nil, nil
	andra(s, "to_start", tips)
	satDelmal(s, 0)
	satProgress(s, 0)
end

local function nyBaslinje(s, o, p, logg)
	s.sistaT, s.sistaObs = o.tid, o.obsTid
	s.sistaBrott = brottAntal(o)
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

local function ridTips(s): string
	if s.langst ~= nil and s.langst >= s.referens.langd - 4 then return "to_end" end
	return if s.typ == "vag_diag" then "ride_diag" else "ride_mitt"
end

function VagLektion.steg(s, now: number, gangart: string?, ryggar: boolean?)
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
		local redanNollad = s.lage == "to_start" and not brott and s.ramId ~= nil
			and p.ramId == s.ramId and not logg.overflode
		nyBaslinje(s, o, p, logg)
		if not redanNollad then tillStart(s, "unknown") end
		return
	end
	if o.tid == s.sistaT then return end
	local observerad = o.obsTid > s.sistaObs
	s.sistaT, s.sistaObs = o.tid, o.obsTid
	local varInne = s.sistaInne
	s.sistaInne = p.iDressyr == true

	--[[ Skritt, trav och halt (paus) gäller; ryggning, galopp eller en
		övergång dit i steget gör det inte. ]]
	local fel = ryggar == true or (gangart ~= "walk" and gangart ~= "trot" and gangart ~= "halt")
	for i = s.loggSett + 1, #logg.handelser do
		local e = logg.handelser[i]
		if e.typ == "gangart" and type(e.data) == "table" and (e.data.tillRyggar
			or (e.data.till ~= "walk" and e.data.till ~= "trot" and e.data.till ~= "halt")) then
			fel = true
		end
	end
	s.loggSett = #logg.handelser

	local ref = s.referens
	local seg = if p.status == "segment" and observerad then p.segment else nil
	if s.lage == "to_start" then
		if fel or type(seg) ~= "table" or not seg.till then return end
		local q = seg.till
		local sL = linje(ref, q)
		local iRing = math.sqrt((q.u - ref.u0) ^ 2 + (q.v - ref.v0) ^ 2) <= ZON
		if iRing and iKorridor(ref, q) and sL <= ZON and p.iDressyr == true then
			--[[ Armeringssteget ger INGEN kredit (R1). `armS` är det
				OBSERVERADE läget längs linjen vid armeringen (−2..2, även
				ringens bakre halva), och `langst` — längsta nådda läget, som
				bakåtspärren mäts mot — börjar där. Framsteg och resultatets
				meter räknas bara från `armS`, så varken inflygningen eller ett
				stillastående första steg i ringens främre halva ger kredit. ]]
			s.armS, s.langst = sL, sL
			s.sistaPunkt = { u = q.u, v = q.v }
			andra(s, "route", ridTips(s))
			satDelmal(s, 1)
		end
		return
	end

	-- route
	if fel then tillStart(s, "walk_or_trot"); return end
	if type(seg) ~= "table" or not seg.fran or not seg.till then tillStart(s, "unknown"); return end
	local fr, ti = seg.fran, seg.till
	local sp = s.sistaPunkt
	if not sp or math.sqrt((sp.u - fr.u) ^ 2 + (sp.v - fr.v) ^ 2) > 0.05 then
		tillStart(s, "unknown"); return
	end
	if math.sqrt((ti.u - fr.u) ^ 2 + (ti.v - fr.v) ^ 2) > GROV_M then tillStart(s, "unknown"); return end
	--[[ Korridoren är konvex: båda ändpunkterna inne ⇒ hela segmentet inne. ]]
	if not (iKorridor(ref, fr) and iKorridor(ref, ti) and varInne and p.iDressyr == true) then
		tillStart(s, "off_route"); return
	end
	local sL = linje(ref, ti)
	if sL < s.langst - BAKAT_M then tillStart(s, "reverse"); return end
	if (gangart == "walk" or gangart == "trot") and sL > s.langst then
		s.langst = math.min(sL, ref.langd)
	end
	s.sistaPunkt = { u = ti.u, v = ti.v }
	andra(s, "route", ridTips(s))
	--[[ Framsteg = ridet framåt sedan armeringen, räknat från P0,
		eller från armeringsläget om det ligger framför P0. ]]
	local fran = math.max(s.armS, 0)
	satProgress(s, 99 * math.max(s.langst - fran, 0) / (ref.langd - fran))
	local iSlut = math.sqrt((ti.u - ref.u1) ^ 2 + (ti.v - ref.v1) ^ 2) <= ZON
	if s.langst >= ref.langd - SLUT_M and iSlut then stang(s, "slutford") end
end

function VagLektion.begar(s, op: any, seq: any, now: number, gangart: string?,
	ryggar: boolean?): (boolean, string?, any)
	if op == "sync" then
		VagLektion.steg(s, now, gangart, ryggar)
		return true, nil, VagLektion.bild(s)
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
	if op ~= "finish" then VagLektion.steg(s, now, gangart, ryggar) end
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
				VagLektion.OVNING, VagLektion.VERSION, o.tid, nil)
			if ok then
				s.forsokId, s.deadline = id, now + DEADLINE
				s.resultat = nil
				nyBaslinje(s, o, p, logg)
				s.progress, s.delmal = 0, 0
				s.armS, s.langst, s.sistaPunkt = nil, nil, nil
				s.revision += 1
				andra(s, "to_start", "to_start")
			end
		end
	end
	local b = VagLektion.bild(s)
	s.svar[seq] = { op = op, ok = ok, fel = fel, bild = b }
	table.insert(s.ordning, seq)
	while #s.ordning > MAX_REQUESTS do s.svar[table.remove(s.ordning, 1)] = nil end
	return ok, fel, b
end

return VagLektion
