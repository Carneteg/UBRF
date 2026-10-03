--!strict
--[[ GENOM HÖRNET — docs/CORNER-LESSON-CONTRACT.md.

	Ett av spelets träningshörn, INTE ett officiellt program och inga
	påhittade bokstäver: hörnet på +u-sidan av C-änden i den lösta
	dressyrramen. Inridning längs spåret, en sammanhängande kvartsvolt och
	utridning längs kortsidan, i den ordningen. Samma livscykel och
	begäranregler som `VagLektion`. Bevis bara ur befintliga observationer:
	RidPlatsObservations segment, RidObservations brottsräknare, RidLoggs
	gångartshändelser och den accepterade gångarten. Lektionen påstår en
	ORDNAD genomridning av hörnet inom korridoren — aldrig böjning, balans,
	takt eller kontakt. Siffrorna är spelantaganden.

	Egen identitet: lektionstyp `hornet`, RidForsok-övning `genom_hornet`,
	definition `server-horn-1`. Den äldre klientövningen `horn` används inte. ]]
local Forsok = require(script.Parent.RidForsok)
local Observation = require(script.Parent.RidObservation)
local Plats = require(script.Parent.RidPlatsObservation)
local Logg = require(script.Parent.RidLogg)

local HornLektion = {}
HornLektion.OVNING = "genom_hornet"
HornLektion.VERSION = "server-horn-1"

local DEADLINE = 120
local MAX_REQUESTS = 16
local T = 1.5 -- spårlinjen innanför kanten
local R = 5.0 -- kvartsvoltens radie
local IN_M = 10.0 -- inridningen
local UT_M = 6.0 -- utridningen
local KORR = 1.2 -- korridoren (mindre än kordans 1,46 m)
local ZON = 2.0 -- start- och slutringen
local MITT = 1.0 -- kontrollpunkten mitt i bågen
local GROV_M = 4.0
local BAKAT_M = 1.0
local SLUT_M = 0.5
HornLektion.GRANSER = table.freeze({ T = T, R = R, IN_M = IN_M, UT_M = UT_M, KORR = KORR, ZON = ZON,
	MITT = MITT, GROV_M = GROV_M, BAKAT_M = BAKAT_M, SLUT_M = SLUT_M, DEADLINE = DEADLINE })

local AKTIVA = { to_start = true, route = true }
local BAGE = R * math.pi / 2

function HornLektion.ny(rittId: string, userId: number, hastId: string): any
	return { typ = "hornet", rittId = rittId, userId = userId, hastId = hastId, lage = "ready",
		revision = 0, hogsta = 0, svar = {}, ordning = {}, progress = 0, tips = "intro", delmal = 0 }
end

function HornLektion.bild(s): any
	return table.freeze({ typ = "hornet", rittId = s.rittId, forsokId = s.forsokId,
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

local function matt(plats): (number?, number?)
	if type(plats) ~= "table" or type(plats.dressyr) ~= "table" then return nil, nil end
	local spm = plats.studsPerMeter
	if type(spm) ~= "number" or spm <= 0 then return nil, nil end
	return plats.dressyr.halvTvars / spm, 2 * plats.dressyr.halvLangs / spm
end

--[[ Ryms hörnet med korridor och ringar i layouten? ]]
local function ryms(plats): boolean
	local W, L = matt(plats)
	if not W or not L then return false end
	return 2 * W >= R + T + UT_M + 2 * KORR + 1 and L >= T + R + IN_M + ZON
end

local function referens(s, p, plats)
	local W, L = matt(plats)
	local uT = p.dressyrMitt.u + (W :: number) - T
	local cu, cv = uT - R, (L :: number) - T - R
	return table.freeze({ ramId = p.ramId, figur = "hornet", uT = uT, cu = cu, cv = cv, r = R,
		p0u = uT, p0v = cv - IN_M, p3u = cu - UT_M, p3v = cv + R,
		--[[ R1: geometrins nyckel. Klientens guidecache jämför den, så en ny
			referens i samma ram (ny start efter en ändrad layout) ritas om. ]]
		nyckel = string.format("hornet|%.6f|%.6f|%.6f|%.6f", uT, cu, cv, R),
		mu = cu + R * math.cos(math.pi / 4), mv = cv + R * math.sin(math.pi / 4),
		inM = IN_M, utM = UT_M, langd = IN_M + BAGE + UT_M, korr = KORR, ring = ZON, mitt = MITT,
		plats = plats })
end
HornLektion._referensForProv = referens

--[[ Läget längs vägen (s, från P0; negativt bakom den) och avståndet från
	den (e), ur den NÄRMASTE av de tre delarna. ]]
local function projektion(ref, q): (number, number)
	-- 1. Inridningen: u = uT, v från p0v uppåt.
	local tA = q.v - ref.p0v
	local sA, eA
	if tA <= 0 then
		-- Bakom P0: negativt läge (startringens bakre halva), sidled som avstånd.
		sA, eA = tA, math.abs(q.u - ref.uT)
	elseif tA >= ref.inM then
		sA, eA = ref.inM, math.sqrt((q.u - ref.uT) ^ 2 + (q.v - ref.cv) ^ 2)
	else
		sA, eA = tA, math.abs(q.u - ref.uT)
	end
	-- 2. Bågen kring (cu, cv), θ i [0, π/2].
	local th = math.atan2(q.v - ref.cv, q.u - ref.cu)
	th = math.clamp(th, 0, math.pi / 2)
	local bu, bv = ref.cu + ref.r * math.cos(th), ref.cv + ref.r * math.sin(th)
	local sB, eB = ref.inM + ref.r * th, math.sqrt((q.u - bu) ^ 2 + (q.v - bv) ^ 2)
	-- 3. Utridningen: v = p3v, u från cu nedåt.
	local tC = ref.cu - q.u
	local sC, eC
	if tC <= 0 then
		sC, eC = ref.inM + BAGE, math.sqrt((q.u - ref.cu) ^ 2 + (q.v - ref.p3v) ^ 2)
	else
		sC, eC = ref.inM + BAGE + tC, math.abs(q.v - ref.p3v)
	end
	if eA <= eB and eA <= eC then return sA, eA end
	if eB <= eC then return sB, eB end
	return sC, eC
end
HornLektion._projektionForProv = projektion

local function iKorridor(ref, q): boolean
	local sL, e = projektion(ref, q)
	return e <= KORR and sL >= -ZON and sL <= ref.langd + ZON
end

local function stang(s, orsak): boolean
	if not aktiv(s) then return false end
	if not Forsok.slutfor(s.rittId, s.forsokId, orsak, obsTid(s.rittId), nil) then return false end
	if orsak == "slutford" then
		s.resultat = table.freeze({ forsokId = s.forsokId, rittId = s.rittId, userId = s.userId,
			hastId = s.hastId, figur = "hornet",
			-- R1: räknat från vägens början (armS kan ligga bakom P0), som framsteget.
			meter = s.langst - math.max(s.armS, 0), armS = s.armS,
			slutS = s.langst, langd = s.referens.langd, mitt = s.mittNadd == true, radie = R,
			start = Forsok.ogonblick(s.forsokId).start })
		s.progress = 100
		s.revision += 1
		andra(s, "complete", "complete")
		--[[ C4: övergången till "complete", med det frysta resultatet på
			plats — minnet prövar och noterar (docs/LESSON-MEMORY-CONTRACT.md). ]]
		if type(s.vidKlar) == "function" then s.vidKlar(s) end
	else
		andra(s, "timeout", "timeout")
	end
	return true
end

local function tillStart(s, tips)
	s.armS, s.langst, s.sistaPunkt, s.mittNadd = nil, nil, nil, nil
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

local function delFor(s): number
	local l = s.langst or 0
	if l < IN_M then return 1 end
	if l < IN_M + BAGE then return 2 end
	return 3
end

local function ridTips(s): string
	local d = delFor(s)
	return if d == 1 then "ride_in" elseif d == 2 then "bend" else "ride_out"
end

function HornLektion.steg(s, now: number, gangart: string?, ryggar: boolean?)
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
		local sL = projektion(ref, q)
		local iRing = math.sqrt((q.u - ref.p0u) ^ 2 + (q.v - ref.p0v) ^ 2) <= ZON
		if iRing and iKorridor(ref, q) and sL <= ZON and p.iDressyr == true then
			-- Armeringen ger ingen kredit; `langst` börjar vid det observerade läget.
			s.armS, s.langst = sL, sL
			s.mittNadd = false
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
	--[[ Korridoren är INTE konvex i hörnet, så båda ändpunkterna OCH
		segmentets mittpunkt prövas; segment är högst GROV_M långa. ]]
	local mid = { u = (fr.u + ti.u) / 2, v = (fr.v + ti.v) / 2 }
	if not (iKorridor(ref, fr) and iKorridor(ref, mid) and iKorridor(ref, ti) and varInne
		and p.iDressyr == true) then
		tillStart(s, "off_route"); return
	end
	local sL = projektion(ref, ti)
	if sL < s.langst - BAKAT_M then tillStart(s, "reverse"); return end
	if (gangart == "walk" or gangart == "trot") and sL > s.langst then
		s.langst = math.min(sL, ref.langd)
	end
	--[[ Kontrollpunkten mitt i bågen, i ordning: bara efter inridningen.
		R1: ordningen är nu ett uttryckligt villkor (`langst >= IN_M`), inte
		bara en följd av korridoren, backgränsen och segmenttaket. ]]
	if not s.mittNadd and s.langst >= IN_M and (gangart == "walk" or gangart == "trot") then
		for _, q in ipairs({ mid, ti }) do
			if math.sqrt((q.u - ref.mu) ^ 2 + (q.v - ref.mv) ^ 2) <= MITT then s.mittNadd = true end
		end
	end
	s.sistaPunkt = { u = ti.u, v = ti.v }
	andra(s, "route", ridTips(s))
	satDelmal(s, delFor(s))
	local fran = math.max(s.armS, 0)
	satProgress(s, 99 * math.max(s.langst - fran, 0) / (ref.langd - fran))
	local iSlut = math.sqrt((ti.u - ref.p3u) ^ 2 + (ti.v - ref.p3v) ^ 2) <= ZON
	if s.mittNadd and s.langst >= ref.langd - SLUT_M and iSlut then stang(s, "slutford") end
end

function HornLektion.begar(s, op: any, seq: any, now: number, gangart: string?,
	ryggar: boolean?): (boolean, string?, any)
	if op == "sync" then
		HornLektion.steg(s, now, gangart, ryggar)
		return true, nil, HornLektion.bild(s)
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
	if op ~= "finish" then HornLektion.steg(s, now, gangart, ryggar) end
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
				HornLektion.OVNING, HornLektion.VERSION, o.tid, nil)
			if ok then
				s.forsokId, s.deadline = id, now + DEADLINE
				s.resultat = nil
				nyBaslinje(s, o, p, logg)
				s.progress, s.delmal = 0, 0
				s.armS, s.langst, s.sistaPunkt, s.mittNadd = nil, nil, nil, nil
				s.revision += 1
				andra(s, "to_start", "to_start")
			end
		end
	end
	local b = HornLektion.bild(s)
	s.svar[seq] = { op = op, ok = ok, fel = fel, bild = b }
	table.insert(s.ordning, seq)
	while #s.ordning > MAX_REQUESTS do s.svar[table.remove(s.ordning, 1)] = nil end
	return ok, fel, b
end

return HornLektion
