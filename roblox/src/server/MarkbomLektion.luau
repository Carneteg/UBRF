--!strict
--[[ BOM PÅ MARKEN I SKRITT (hoppning, första steget) — docs/GROUND-POLE-LESSON-CONTRACT.md.

	En guidad inridning i skritt, en OBSERVERAD passage av den BEFINTLIGA
	markbommens plan (`ridhus_hinder_rod_50`) mot C, och en kort bit
	skritt efteråt. Ingen bedömning av hopp, frigång, kontakt, rivning,
	takt, balans eller landning: bommen har `CanCollide = false` och
	passagen är ROTENS väg över planet, inte verifierad hovplacering.
	Passagen själv är HinderObservations (SID_TOL, sista observerade
	planmöte inom bredden); lektionen lägger på färskhet (`nr`/`tIn` efter
	armeringen), riktning mot C, skritt genom hela bevisningen och en
	korridor. Siffrorna är spelantaganden. ]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ridhusplats = require(ReplicatedStorage.HorseCore.Ridhusplats)
local Forsok = require(script.Parent.RidForsok)
local Observation = require(script.Parent.RidObservation)
local Plats = require(script.Parent.RidPlatsObservation)
local Logg = require(script.Parent.RidLogg)
local Hinder = require(script.Parent.HinderObservation)

local MarkbomLektion = {}
MarkbomLektion.OVNING = "markbom"
MarkbomLektion.VERSION = "server-markbom-1"
MarkbomLektion.HINDER_ID = "ridhus_hinder_rod_50"

local DEADLINE = 150
local MAX_REQUESTS = 16
local SIDA_EXTRA = 0.5 -- korridoren: |a| ≤ bredd/2 + 0,5 m
local DJUP = 10
local INRIDNING_M = 4.0
local INRIDNING_SLUT = -0.5 -- inridningen krediteras bara före w = −0,5
local UTRIDNING_M = 1.0
local BAKAT_M = 1.0
local MARK_TOPP = 0.25 -- en MARKbom: överkant högst så här över golvet (m)
MarkbomLektion.GRANSER = table.freeze({ SIDA_EXTRA = SIDA_EXTRA, DJUP = DJUP,
	INRIDNING_M = INRIDNING_M, INRIDNING_SLUT = INRIDNING_SLUT, UTRIDNING_M = UTRIDNING_M,
	BAKAT_M = BAKAT_M, MARK_TOPP = MARK_TOPP, DEADLINE = DEADLINE })

local AKTIVA = { approach = true, crossing = true, exit = true }

function MarkbomLektion.ny(rittId: string, userId: number, hastId: string): any
	return { typ = "markbom", rittId = rittId, userId = userId, hastId = hastId, lage = "ready",
		revision = 0, hogsta = 0, svar = {}, ordning = {}, progress = 0, tips = "intro" }
end

function MarkbomLektion.bild(s): any
	return table.freeze({ typ = "markbom", rittId = s.rittId, forsokId = s.forsokId,
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

--[[ Bommens geometri i ramen, eller nil med skäl. Läser registrets
	FAKTISKA post för just detta id — aldrig ett annat hinder. ]]
local function bomGeometri(plats): (any, string?)
	if type(plats) ~= "table" then return nil, "ram" end
	local reg = Hinder.register()
	local h = reg and reg.hinder and reg.hinder[MarkbomLektion.HINDER_ID]
	if not h then return nil, "saknas" end
	if h.flyttad then return nil, "flyttad" end
	local M = plats.studsPerMeter
	local c = Ridhusplats.tillLokal(plats, Vector3.new(h.x, h.y, h.z))
	local topp = Ridhusplats.tillLokal(plats, Vector3.new(h.x, h.topp, h.z))
	if topp.Y > MARK_TOPP then return nil, "upphojd" end
	local function iRam(vx: number, vz: number): (number, number)
		local d = Vector3.new(vx, 0, vz)
		return d.X * plats.tvars.X + d.Z * plats.tvars.Z, d.X * plats.motC.X + d.Z * plats.motC.Z
	end
	local au, av = iRam(h.breddaxel.x, h.breddaxel.z)
	local nu_, nv = iRam(h.normal.x, h.normal.z)
	--[[ W: normalen mot C (+v i ramen). Registrets `fram` är −v → +v längs
		registrets normal; pekar den mot C är avsedd riktning "fram". ]]
	local mot = if nv >= 0 then 1 else -1
	return table.freeze({ u = c.X, v = c.Z, au = au, av = av, wu = nu_ * mot, wv = nv * mot,
		bredd = h.bredd / M, riktning = if mot > 0 then "fram" else "bak",
		generation = h.generation, nyckel = string.format("%d|%.6f|%.6f|%.6f|%.6f|%.6f",
			h.generation, h.x, h.y, h.z, h.breddaxel.x, h.breddaxel.z) }), nil
end

local function lokal(g, q): (number, number)
	local du, dv = q.u - g.u, q.v - g.v
	return du * g.au + dv * g.av, du * g.wu + dv * g.wv
end

local function iKorridor(g, a: number, w: number): boolean
	return math.abs(a) <= g.bredd / 2 + SIDA_EXTRA and w >= -DJUP and w <= DJUP
end

--[[ Högsta försöksnummer vid bommen i ritten, inklusive ett öppet. ]]
local function hogstaNr(hs): number
	local n = 0
	for _, f in ipairs(hs and hs.forsok or {}) do
		if f.hinderId == MarkbomLektion.HINDER_ID and f.nr > n then n = f.nr end
	end
	return n
end

local function stang(s, orsak): boolean
	if not aktiv(s) then return false end
	if not Forsok.slutfor(s.rittId, s.forsokId, orsak, obsTid(s.rittId), nil) then return false end
	if orsak == "slutford" then
		s.resultat = table.freeze({ forsokId = s.forsokId, rittId = s.rittId, userId = s.userId,
			hastId = s.hastId, ovning = MarkbomLektion.OVNING, hinderId = MarkbomLektion.HINDER_ID,
			generation = s.geo.generation, riktning = s.geo.riktning, hinderForsokNr = s.passageNr,
			inridningM = s.inridning, utridningM = s.utridning, passage = "rotplan",
			kontakt = "otillganglig", rivning = false, start = Forsok.ogonblick(s.forsokId).start })
		s.progress = 100
		s.revision += 1
		andra(s, "complete", "complete")
	else
		andra(s, "timeout", "timeout")
	end
	return true
end

--[[ Återgång till inridningen: all bevisning bort, samma tidsgräns. ]]
local function tillInridning(s, tips)
	s.armerad, s.frontW, s.inridning, s.utridning = false, nil, 0, 0
	s.passageNr, s.passageW = nil, nil
	andra(s, "approach", tips)
	satProgress(s, 0)
end

local function nyBaslinje(s, o, p, logg)
	s.sistaT, s.sistaObs = o.tid, o.obsTid
	s.sistaBrott = brottAntal(o)
	s.loggSett = #logg.handelser
	local plats = Plats.lektionsRam(s.rittId)
	local geo = bomGeometri(plats)
	if p.ramId ~= nil and geo then
		s.ramId, s.geo = p.ramId, geo
		s.referens = table.freeze({ ramId = p.ramId, u = geo.u, v = geo.v, au = geo.au, av = geo.av,
			wu = geo.wu, wv = geo.wv, bredd = geo.bredd, sida = SIDA_EXTRA, djup = DJUP, plats = plats })
	else
		s.ramId, s.geo = nil, nil
	end
end

function MarkbomLektion.steg(s, now: number, gangart: string?, ryggar: boolean?)
	if not AKTIVA[s.lage] then return end
	if not aktiv(s) then andra(s, "closed", "closed"); return end
	if now >= s.deadline then stang(s, "tidsgrans"); return end
	local o = Observation.ogonblick(s.rittId)
	local p = Plats.ogonblick(s.rittId)
	local logg = Logg.ogonblick(s.rittId)
	local hs = Hinder.ogonblick(s.rittId)
	if not (agare(s, o) and agare(s, p) and logg and logg.rittId == s.rittId and agare(s, hs)) then
		return
	end

	--[[ AVBROTT FÖRE TIDSJÄMFÖRELSEN: brott, ramfel, ogiltigt läge,
		överfulla loggar och en bom som inte längre är SAMMA registrering. ]]
	local geoNu = bomGeometri(Plats.lektionsRam(s.rittId))
	local brott = brottAntal(o) ~= s.sistaBrott
	local ramFel = p.ramId == nil or p.ramId ~= s.ramId
	local lageFel = p.punkt == nil or (p.status ~= "segment" and p.status ~= "baslinje")
	local bomFel = geoNu == nil or s.geo == nil or geoNu.nyckel ~= s.geo.nyckel
	if brott or ramFel or lageFel or logg.overflode or hs.overflode or bomFel then
		local redanNollad = s.lage == "approach" and not s.armerad and not brott and not bomFel
			and s.ramId ~= nil and p.ramId == s.ramId and not logg.overflode and not hs.overflode
		nyBaslinje(s, o, p, logg)
		if not redanNollad then
			tillInridning(s, if geoNu == nil then "pole_missing" else "unknown")
		end
		return
	end
	if o.tid == s.sistaT then return end
	local observerad = o.obsTid > s.sistaObs
	s.sistaT, s.sistaObs = o.tid, o.obsTid

	local handelser = #logg.handelser > s.loggSett
	s.loggSett = #logg.handelser
	local g = s.geo
	local seg = if p.status == "segment" and observerad then p.segment else nil
	local skritt = gangart == "walk" and ryggar ~= true and not handelser
	if type(seg) ~= "table" or not seg.fran or not seg.till then
		if s.armerad then tillInridning(s, "unknown") end
		return
	end
	local a0, w0 = lokal(g, seg.fran)
	local a1, w1 = lokal(g, seg.till)
	local inne = iKorridor(g, a0, w0) and iKorridor(g, a1, w1)

	--[[ Skritt genom HELA bevisningen: en armerad bevisning kastas av halt,
		trav, galopp, ryggning eller en gångartshändelse i steget, och av att
		lämna korridoren. Inget färdas utan kredit och tas igen senare. ]]
	if s.armerad and not skritt then
		tillInridning(s, if gangart == "halt" and ryggar ~= true then "walk_on" else "walk_only")
		return
	end
	if s.armerad and not inne then tillInridning(s, "off_line"); return end
	if s.armerad and w1 < s.frontW - BAKAT_M then tillInridning(s, "reverse"); return end

	if s.lage == "approach" then
		if not s.armerad then
			--[[ Armering: ett skrittsteg i korridoren före bommen. Ger ingen
				kredit; fångar försöksnumret och tiden som färskhetsgräns. ]]
			if skritt and inne and w1 < INRIDNING_SLUT then
				s.armerad, s.frontW, s.inridning, s.utridning = true, w1, 0, 0
				s.nrBas, s.tBas = hogstaNr(hs), o.tid
				andra(s, "approach", "walk_to_pole")
			end
			return
		end
		local tak = math.min(w1, INRIDNING_SLUT)
		if tak > s.frontW then
			s.inridning += tak - s.frontW
			s.frontW = tak
		end
		if w1 > s.frontW then s.frontW = w1 end
		satProgress(s, 40 * math.min(s.inridning / INRIDNING_M, 1))
		if s.inridning >= INRIDNING_M then
			andra(s, "crossing", "over_pole")
		elseif w1 >= INRIDNING_SLUT then
			--[[ Framme vid bommen utan tillräcklig inridning. ]]
			tillInridning(s, "approach_longer")
		end
		return
	end

	-- crossing / exit: frontlinjen följer skrittens w.
	if w1 > s.frontW then s.frontW = w1 end
	if s.lage == "crossing" then
		local funnen = nil
		for _, f in ipairs(hs.forsok) do
			if f.hinderId == MarkbomLektion.HINDER_ID and f.nr > s.nrBas and f.tIn > s.tBas then
				funnen = f
			end
		end
		if funnen and funnen.giltighet ~= "pagar" then
			if funnen.giltighet ~= "fullstandig" then tillInridning(s, "unknown"); return end
			if funnen.utfall == "sidan_om" then tillInridning(s, "beside_pole"); return end
			if funnen.utfall ~= "passage" then tillInridning(s, "no_passage"); return end
			if funnen.riktning ~= g.riktning then tillInridning(s, "wrong_direction"); return end
			s.passageNr, s.passageW = funnen.nr, w1
			s.utridning = 0
			andra(s, "exit", "walk_on_after")
			satProgress(s, 80)
		end
		return
	end
	-- exit
	s.utridning = math.max(s.utridning, w1 - s.passageW)
	satProgress(s, 80 + 19 * math.min(s.utridning / UTRIDNING_M, 1))
	if s.utridning >= UTRIDNING_M then stang(s, "slutford") end
end

function MarkbomLektion.begar(s, op: any, seq: any, now: number, gangart: string?,
	ryggar: boolean?): (boolean, string?, any)
	if op == "sync" then
		MarkbomLektion.steg(s, now, gangart, ryggar)
		return true, nil, MarkbomLektion.bild(s)
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
	if op ~= "finish" then MarkbomLektion.steg(s, now, gangart, ryggar) end
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
		local hs = Hinder.ogonblick(s.rittId)
		if not (agare(s, o) and agare(s, p) and logg and agare(s, hs) and p.punkt
			and p.iBana == true and p.ramId ~= nil) then
			fel = "place"
		elseif bomGeometri(Plats.lektionsRam(s.rittId)) == nil then
			fel = "pole"
		else
			local id
			ok, fel, id = Forsok.starta(s.rittId, Forsok.nastaSekvens(s.rittId),
				MarkbomLektion.OVNING, MarkbomLektion.VERSION, o.tid, nil)
			if ok then
				s.forsokId, s.deadline = id, now + DEADLINE
				s.resultat = nil
				nyBaslinje(s, o, p, logg)
				s.armerad, s.frontW, s.inridning, s.utridning = false, nil, 0, 0
				s.passageNr, s.passageW, s.nrBas, s.tBas = nil, nil, 0, 0
				s.progress = 0
				s.revision += 1
				andra(s, "approach", "to_approach")
			end
		end
	end
	local b = MarkbomLektion.bild(s)
	s.svar[seq] = { op = op, ok = ok, fel = fel, bild = b }
	table.insert(s.ordning, seq)
	while #s.ordning > MAX_REQUESTS do s.svar[table.remove(s.ordning, 1)] = nil end
	return ok, fel, b
end

return MarkbomLektion
