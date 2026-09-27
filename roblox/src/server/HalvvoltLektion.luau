--!strict
--[[ HALVVOLT TILLBAKA TILL SPÅRET — docs/HALF-CIRCLE-LESSON-CONTRACT.md.

	En spelets egen träningsväg, INTE ett officiellt program och inga
	påhittade bokstäver: spåret längs +u-långsidan mot C, en halvvolt på
	10 m in mot mitten och en tillbakaväg till spåret mot A — bytt
	riktning. Samma livscykel och begäranregler som de andra lektionerna.
	Bevis bara ur befintliga observationer: RidPlatsObservations segment,
	RidObservations brottsräknare, RidLoggs gångartshändelser och den
	accepterade gångarten. Bågen är inte konvex, så varje segment provas
	längs kordan (≤ 0,5 m) och varje prov ska ligga i korridoren, entydigt
	och sammanhängande. Lektionen påstår en ORDNAD genomridning av vägen,
	aldrig böjning, balans, takt eller galoppsida. Siffrorna är
	spelantaganden. ]]
local Forsok = require(script.Parent.RidForsok)
local Observation = require(script.Parent.RidObservation)
local Plats = require(script.Parent.RidPlatsObservation)
local Logg = require(script.Parent.RidLogg)

local HalvvoltLektion = {}
HalvvoltLektion.OVNING = "halvvolt"
HalvvoltLektion.VERSION = "server-halvvolt-1"

local DEADLINE = 150
local MAX_REQUESTS = 16
local SPAR_DU = 8.5 -- spåret: u0 + 8,5, 1,5 m innanför +u-långsidan
local P0_V, T1_V = 16, 26 -- del 1 längs spåret mot C
local R = 5 -- halvvoltens radie (10 m)
local E_V = 8 -- slutet på spåret, mot A
local L1 = T1_V - P0_V
local L2 = math.pi * R
local L3 = math.sqrt((2 * R) ^ 2 + (T1_V - E_V) ^ 2)
local LANGD = L1 + L2 + L3
local KORR = 1.5
local RING = 2.0
local STEG_M = 0.5
local GROV_M = 4.0
local TVETYDIG_M = 3.0
local BAKAT_M = 1.0
local SKARV_R = 1.5
local SKARV_SLACK = 1.0
local SLUT_M = 0.5
local HALT_R = 0.5 -- R1: tillåten rörelse från haltens ankare (darrning)
HalvvoltLektion.GRANSER = table.freeze({ SPAR_DU = SPAR_DU, P0_V = P0_V, T1_V = T1_V, R = R,
	E_V = E_V, L1 = L1, L2 = L2, L3 = L3, LANGD = LANGD, KORR = KORR, RING = RING,
	STEG_M = STEG_M, GROV_M = GROV_M, TVETYDIG_M = TVETYDIG_M, BAKAT_M = BAKAT_M,
	SKARV_R = SKARV_R, SKARV_SLACK = SKARV_SLACK, SLUT_M = SLUT_M, HALT_R = HALT_R,
	DEADLINE = DEADLINE })

local AKTIVA = { to_start = true, route = true }

function HalvvoltLektion.ny(rittId: string, userId: number, hastId: string): any
	return { typ = "halvvolt", rittId = rittId, userId = userId, hastId = hastId, lage = "ready",
		revision = 0, hogsta = 0, svar = {}, ordning = {}, progress = 0, tips = "intro", delmal = 0 }
end

function HalvvoltLektion.bild(s): any
	return table.freeze({ typ = "halvvolt", rittId = s.rittId, forsokId = s.forsokId,
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

local function ryms(plats): boolean
	if type(plats) ~= "table" or type(plats.dressyr) ~= "table" then return false end
	local halvBredd = plats.dressyr.halvTvars / plats.studsPerMeter
	local langd = 2 * plats.dressyr.halvLangs / plats.studsPerMeter
	return halvBredd >= SPAR_DU + KORR and langd >= T1_V + R + RING
end

local function referens(s, p, plats)
	local uT = p.dressyrMitt.u + SPAR_DU
	return table.freeze({ ramId = p.ramId, uT = uT, p0v = P0_V, t1v = T1_V, r = R, ev = E_V,
		korr = KORR, ring = RING, langd = LANGD, plats = plats })
end

--[[ Rak del från (au, av) till (bu, bv) med tillåtet s-intervall
	[smin, längd]: (s, avstånd), s klämt. ]]
local function rak(au, av, bu, bv, smin, u, v): (number, number)
	local lx, ly = bu - au, bv - av
	local L = math.sqrt(lx * lx + ly * ly)
	local dx, dy = lx / L, ly / L
	local s = math.clamp((u - au) * dx + (v - av) * dy, smin, L)
	local pu, pv = au + dx * s, av + dy * s
	return s, math.sqrt((u - pu) ^ 2 + (v - pv) ^ 2)
end

--[[ Vägläge S för en punkt, eller nil utanför korridoren; andra värdet
	sant för en tvetydig projektion. ]]
local function projicera(ref, u: number, v: number): (number?, boolean)
	local uT = ref.uT
	local minS, maxS, basta, bastaD = math.huge, -math.huge, nil, math.huge
	local function kandidat(S, d)
		if d <= KORR then
			minS, maxS = math.min(minS, S), math.max(maxS, S)
			if d < bastaD then basta, bastaD = S, d end
		end
	end
	-- Del 1: spåret mot C; s från −2 (bakre halvan av startringen).
	local s1, d1 = rak(uT, P0_V, uT, T1_V, -RING, u, v)
	kandidat(s1, d1)
	-- Del 2: halvvolten ovanför diametern (dv ≥ 0, även −0).
	local cu, cv = uT - R, T1_V
	local du, dv = u - cu, v - cv
	if dv >= 0 then
		local th = math.clamp(math.atan2(math.abs(dv), du), 0, math.pi)
		kandidat(L1 + th * R, math.abs(math.sqrt(du * du + dv * dv) - R))
	else
		local dT = math.sqrt((u - uT) ^ 2 + (v - T1_V) ^ 2)
		local dH = math.sqrt((u - (uT - 2 * R)) ^ 2 + (v - T1_V) ^ 2)
		if dT <= dH then kandidat(L1, dT) else kandidat(L1 + L2, dH) end
	end
	-- Del 3: tillbaka till spåret mot A.
	local s3, d3 = rak(uT - 2 * R, T1_V, uT, E_V, 0, u, v)
	kandidat(L1 + L2 + s3, d3)
	if basta == nil then return nil, false end
	return basta, maxS - minS > TVETYDIG_M
end

--[[ Provkrok: projektionen, för gränsfallen (skarvar, vinkel, −0). ]]
function HalvvoltLektion._projiceraForProv(ref, u: number, v: number): (number?, boolean)
	return projicera(ref, u, v)
end

local function stang(s, orsak): boolean
	if not aktiv(s) then return false end
	if not Forsok.slutfor(s.rittId, s.forsokId, orsak, obsTid(s.rittId), nil) then return false end
	if orsak == "slutford" then
		s.resultat = table.freeze({ forsokId = s.forsokId, rittId = s.rittId, userId = s.userId,
			hastId = s.hastId, figur = "halvvolt", armS = s.armS, slutS = s.langst,
			meter = s.langst - s.armS, langd = LANGD,
			skarvar = table.freeze(table.clone(s.skarvar)),
			start = Forsok.ogonblick(s.forsokId).start })
		s.progress = 100
		s.revision += 1
		andra(s, "complete", "complete")
	else
		andra(s, "timeout", "timeout")
	end
	return true
end

local function tillStart(s, tips)
	s.armS, s.langst, s.sistaS, s.sistaPunkt, s.haltAnkare = nil, nil, nil, nil, nil
	s.skarvar = {}
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

--[[ Delmålet för guiden och tipset: 1 spåret, 2 halvvolten, 3 tillbaka. ]]
local function delFor(S: number): number
	if S < L1 then return 1 elseif S < L1 + L2 then return 2 else return 3 end
end

local function vagTips(s): string
	if s.langst >= LANGD - 4 then return "to_end" end
	local d = delFor(s.langst)
	return if d == 1 then "track" elseif d == 2 then "half_circle" else "return"
end

--[[ Ett giltigt segment på vägen: varje prov längs kordan i korridoren,
	entydigt och sammanhängande. false om försöket gick till startringen. ]]
local function paVagen(s, seg, kredit: boolean): boolean
	local ref = s.referens
	local fu, fv, tu, tv = seg.fran.u, seg.fran.v, seg.till.u, seg.till.v
	local langd = math.sqrt((tu - fu) ^ 2 + (tv - fv) ^ 2)
	if langd > GROV_M then tillStart(s, "unknown"); return false end
	local fore = s.sistaPunkt
	if not fore or math.sqrt((fore.u - fu) ^ 2 + (fore.v - fv) ^ 2) > 0.05 then
		tillStart(s, "unknown"); return false
	end
	--[[ R1: HALT UTAN KREDIT KAN INTE BANKAS. Under halt förankras läget
		där halten började; darrning inom HALT_R (0,5 m) från ankaret är
		tillåten hur länge som helst, men mer okrediterad förflyttning går
		tillbaka till startringen. Ankaret släpps vid nästa krediterade steg. ]]
	if not kredit then
		local a = s.haltAnkare or { u = fu, v = fv }
		s.haltAnkare = a
		if math.sqrt((tu - a.u) ^ 2 + (tv - a.v) ^ 2) > HALT_R then
			tillStart(s, "halt_moved"); return false
		end
	else
		s.haltAnkare = nil
	end
	local n = math.max(1, math.ceil(langd / STEG_M))
	local skarvPunkter = {
		{ u = ref.uT, v = T1_V, S = L1 },
		{ u = ref.uT - 2 * R, v = T1_V, S = L1 + L2 },
	}
	for i = 0, n do
		local u = if i == n then tu else fu + (tu - fu) * i / n
		local v = if i == n then tv else fv + (tv - fv) * i / n
		local S, tvetydig = projicera(ref, u, v)
		if S == nil then tillStart(s, "off_route"); return false end
		if tvetydig then tillStart(s, "unknown"); return false end
		local d = math.sqrt((u - fore.u) ^ 2 + (v - fore.v) ^ 2)
		if s.sistaS ~= nil and math.abs(S - s.sistaS) > 1.6 * d + 0.3 then
			tillStart(s, "unknown"); return false
		end
		if S < s.langst - BAKAT_M then tillStart(s, "reverse"); return false end
		--[[ Skarvarna i ordning: ett KREDITERAT prov nära nästa skarv (R1:
			okrediterad rörelse räknar aldrig en skarv). ]]
		local nasta = skarvPunkter[#s.skarvar + 1]
		if kredit and nasta and math.sqrt((u - nasta.u) ^ 2 + (v - nasta.v) ^ 2) <= SKARV_R then
			table.insert(s.skarvar, table.freeze({ u = u, v = v }))
		end
		--[[ R1: STEGVIS KREDIT. `langst` växer bara med rörelsen sedan
			föregående prov (eller från `langst`, om den ligger längre fram) —
			aldrig med ett absolut hopp till S. Det som flyttats utan kredit
			kan därför inte tas igen av ett senare prov. ]]
		local fore_S = s.sistaS or S
		local fran = math.max(fore_S, s.langst)
		if kredit and S > fran then
			local tak = if #s.skarvar < 2 then skarvPunkter[#s.skarvar + 1].S + SKARV_SLACK else LANGD
			s.langst = math.max(s.langst, math.min(s.langst + (S - fran), tak))
		end
		s.sistaS, fore = S, { u = u, v = v }
	end
	s.sistaPunkt = fore
	return true
end

function HalvvoltLektion.steg(s, now: number, gangart: string?, ryggar: boolean?)
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
		local S, tvetydig = projicera(ref, q.u, q.v)
		local iRing = math.sqrt((q.u - ref.uT) ^ 2 + (q.v - P0_V) ^ 2) <= RING
		if iRing and S ~= nil and not tvetydig and S >= -RING and S <= RING
			and p.iDressyr == true then
			--[[ Armeringssteget ger INGEN kredit; armS och langst börjar i
				det observerade läget (bakre eller främre halvan). ]]
			s.armS, s.langst, s.sistaS, s.haltAnkare = S, S, S, nil
			s.sistaPunkt = { u = q.u, v = q.v }
			s.skarvar = {}
			andra(s, "route", "track")
			satDelmal(s, 1)
		end
		return
	end

	-- route
	if fel then tillStart(s, "walk_or_trot"); return end
	if type(seg) ~= "table" or not seg.fran or not seg.till then tillStart(s, "unknown"); return end
	if not (varInne and p.iDressyr == true) then tillStart(s, "off_route"); return end
	if not paVagen(s, seg, gangart == "walk" or gangart == "trot") then return end
	local tips = vagTips(s)
	andra(s, "route", tips)
	satDelmal(s, if tips == "to_end" then 4 else delFor(s.langst))
	local fran = math.max(s.armS, 0)
	satProgress(s, 99 * math.max(s.langst - fran, 0) / (LANGD - fran))
	local q = seg.till
	local iSlut = math.sqrt((q.u - ref.uT) ^ 2 + (q.v - E_V) ^ 2) <= RING
	if s.langst >= LANGD - SLUT_M and #s.skarvar >= 2 and iSlut then stang(s, "slutford") end
end

function HalvvoltLektion.begar(s, op: any, seq: any, now: number, gangart: string?,
	ryggar: boolean?): (boolean, string?, any)
	if op == "sync" then
		HalvvoltLektion.steg(s, now, gangart, ryggar)
		return true, nil, HalvvoltLektion.bild(s)
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
	if op ~= "finish" then HalvvoltLektion.steg(s, now, gangart, ryggar) end
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
				HalvvoltLektion.OVNING, HalvvoltLektion.VERSION, o.tid, nil)
			if ok then
				s.forsokId, s.deadline = id, now + DEADLINE
				s.resultat = nil
				nyBaslinje(s, o, p, logg)
				s.progress, s.delmal = 0, 0
				s.armS, s.langst, s.sistaS, s.sistaPunkt, s.skarvar = nil, nil, nil, nil, {}
				s.revision += 1
				andra(s, "to_start", "to_start")
			end
		end
	end
	local b = HalvvoltLektion.bild(s)
	s.svar[seq] = { op = op, ok = ok, fel = fel, bild = b }
	table.insert(s.ordning, seq)
	while #s.ordning > MAX_REQUESTS do s.svar[table.remove(s.ordning, 1)] = nil end
	return ok, fel, b
end

return HalvvoltLektion
