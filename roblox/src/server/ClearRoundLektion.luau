--!strict
--[[ CLEAR ROUND (UBRF-TRÄNING), FÖRENKLAD BEDÖMNING — docs/D2-CLEAR-ROUND-DAY-CONTRACT.md.

	D2a: EN ritt över träningsbanan blå → röd → blå → röd i ridhuset.
	Startsignal (Start) → startlinjen inom 45 s → banan i ordning → mållinjen
	→ bedömning. Bedömningen är FÖRENKLAD och säger det: bommarna kan inte
	rivas (`CanCollide = false`, HinderObservation), så nedslag är alltid 0
	och "felfri" går inte att fastställa — resultatet säger "inga observerade
	fel", aldrig "felfri", och ingen clear round-rosett delas ut
	(CHATGPT_CORRECTION_D2_SIMPLIFIED_JUDGING). Felen räknas med D1:s
	`Klassprofil.clearRound` (SvRF TR III 2025).

	Observerat: HinderObservations försök per hinder (passage med riktning,
	`sidan_om`, `ingen_passage`), ridobservationens tid och brott, och
	RidPlatsObservations segment i ridhusets ram för start- och mållinjen.
	`ingen_passage` bedöms inte (en vägran eller volt observeras inte).
	Banans riktningar, linjernas 8 m och deras bredd är [antagande]. ]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ridhusplats = require(ReplicatedStorage.HorseCore.Ridhusplats)
local Klassprofil = require(ReplicatedStorage.HorseCore.Klassprofil)
local Forsok = require(script.Parent.RidForsok)
local Observation = require(script.Parent.RidObservation)
local Plats = require(script.Parent.RidPlatsObservation)
local Hinder = require(script.Parent.HinderObservation)

local ClearRoundLektion = {}
ClearRoundLektion.OVNING = "clearround"
ClearRoundLektion.VERSION = "server-clearround-1"

--[[ Banan (ii), Tobias beslut #5865730798. Riktningarna är [antagande]:
	spelets träningsbana, inte UBRF-verifierad. Höjden är de byggda hindrens
	(src/site.js): blå 0,68 m, röd 0,52 m — klassens höjd är den högsta. ]]
local BANA = table.freeze({
	table.freeze({ id = "ridhus_hinder_bla_24", mot = "C", farg = "bla" }),
	table.freeze({ id = "ridhus_hinder_rod_38", mot = "C", farg = "rod" }),
	table.freeze({ id = "ridhus_hinder_bla_24", mot = "A", farg = "bla" }),
	table.freeze({ id = "ridhus_hinder_rod_38", mot = "C", farg = "rod" }),
})
ClearRoundLektion.BANA = BANA
local HOJD_M = 0.68
local LINJE_M = 8 -- TR 352.3: 6–15 m före första / efter sista hindret [antagande: 8]
local LINJE_HALV = 4 -- linjens halva bredd [antagande]
local START_S = 45 -- TR 388.2.3.2
local TILLATEN_S = 180 -- TR 312.3.2 (häst t.o.m. 1,05 m)
local MAX_REQUESTS = 16
ClearRoundLektion.GRANSER = table.freeze({ HOJD_M = HOJD_M, LINJE_M = LINJE_M, LINJE_HALV = LINJE_HALV,
	START_S = START_S, TILLATEN_S = TILLATEN_S })

local AKTIVA = { to_start = true, course = true, to_finish = true }

--[[ CHATGPT_REVIEW_D2A_CHANGES_REQUESTED: en ritt som slutar MITT I banan
	(avsittning eller annat rittslut) får ETT slutligt utfall, "avbruten" —
	aldrig ett fall (en frivillig avsittning skiljs inte från ett fall) och
	aldrig framgång. Lektionsobjektet rivs med ritten, så utfallet sparas per
	spelare här och visas nästa gång hon öppnar clear round; det tas bort när
	hon startar en ny ritt. Sessionslokalt, aldrig persistent. ]]
local senaste: { [number]: any } = {}

function ClearRoundLektion.ny(rittId: string, userId: number, hastId: string): any
	return { typ = "clearround", rittId = rittId, userId = userId, hastId = hastId, lage = "ready",
		revision = 0, hogsta = 0, svar = {}, ordning = {}, progress = 0, tips = "intro", forsokNr = 0 }
end

local function nasta(s): any
	if s.lage ~= "course" then return nil end
	local b = BANA[s.steg]
	return b and table.freeze({ nr = s.steg, farg = b.farg, mot = b.mot }) or nil
end

function ClearRoundLektion.bild(s): any
	local forra = senaste[s.userId]
	return table.freeze({ typ = "clearround", rittId = s.rittId, forsokId = s.forsokId,
		revision = s.revision, sekvens = s.hogsta, lage = s.lage, progress = s.progress,
		tips = s.tips, resultat = s.resultat, referens = s.referens, forsokNr = s.forsokNr,
		-- Förra rittens avbrutna utfall, bara innan en ny ritt startats.
		forraAvbruten = if (s.lage == "ready" or s.lage == "closed") and forra then forra else nil,
		nasta = nasta(s), delmal = if s.lage == "to_start" then 0 elseif s.lage == "course" then s.steg
			elseif s.lage == "to_finish" then 5 else nil })
end

local function andra(s, lage, tips)
	if s.lage == lage and s.tips == tips then return end
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

local function obsTid(id): number
	local o = Observation.ogonblick(id)
	return if o then o.tid else 0
end

local function brottAntal(o): number
	local g = o.giltighet
	if type(g) ~= "table" then return -1 end
	return (g.luckor or 0) + (g.saknade or 0) + (g.teleporter or 0) + (g.ogiltigaDt or 0)
end

--[[ Ett hinders läge i ramen och vilken av registrets riktningar som är
	"mot C". nil när hindret saknas, är avvisat eller flyttat. ]]
local function hinderGeo(plats, id: string): any
	local reg = Hinder.register()
	local h = reg and reg.hinder and reg.hinder[id]
	if not h or h.flyttad then return nil end
	local c = Ridhusplats.tillLokal(plats, Vector3.new(h.x, h.y, h.z))
	local nv = h.normal.x * plats.motC.X + h.normal.z * plats.motC.Z
	return { u = c.X, v = c.Z, motC = if nv >= 0 then "fram" else "bak",
		nyckel = string.format("%s|%d|%.4f|%.4f|%.4f", id, h.generation, h.x, h.z, h.bredd) }
end

--[[ Banans geometri: hindren, startlinjen och mållinjen, eller nil. ]]
local function banGeometri(plats): any
	if type(plats) ~= "table" then return nil end
	local hinder, nycklar = {}, {}
	for i, b in ipairs(BANA) do
		local g = hinderGeo(plats, b.id)
		if not g then return nil end
		local riktning = if b.mot == "C" then g.motC elseif g.motC == "fram" then "bak" else "fram"
		hinder[i] = table.freeze({ id = b.id, u = g.u, v = g.v, riktning = riktning, farg = b.farg, mot = b.mot })
		nycklar[i] = g.nyckel
	end
	-- Hopp 1 och 4 rids båda mot C: startlinjen före hopp 1, mållinjen efter hopp 4.
	local h1, h4 = hinder[1], hinder[#hinder]
	return table.freeze({ hinder = table.freeze(hinder),
		start = table.freeze({ u = h1.u, v = h1.v - LINJE_M }), mal = table.freeze({ u = h4.u, v = h4.v + LINJE_M }),
		halv = LINJE_HALV, nyckel = table.concat(nycklar, ";") })
end

--[[ Korsar segmentet linjen v = L.v mot C (växande v), inom linjens bredd? ]]
local function korsarMotC(seg, L): boolean
	if type(seg) ~= "table" or type(seg.fran) ~= "table" or type(seg.till) ~= "table" then return false end
	local v0, v1 = seg.fran.v, seg.till.v
	if not (v0 < L.v and v1 >= L.v) then return false end
	local t = (L.v - v0) / (v1 - v0)
	local u = seg.fran.u + (seg.till.u - seg.fran.u) * t
	return math.abs(u - L.u) <= LINJE_HALV
end

local function hogstaNr(hs, id: string): number
	local n = 0
	for _, f in ipairs(hs and hs.forsok or {}) do
		if f.hinderId == id and f.nr > n then n = f.nr end
	end
	return n
end

--[[ Försöket slutar. `utfall`: "bedomd" (med profilens fel), "ej_startad"
	eller "ej_bedomd". Ingen rosett, aldrig "felfri". ]]
local function avsluta(s, utfall: string, orsak: string?)
	local tid = if s.tStart then math.max(0, obsTid(s.rittId) - s.tStart) else nil
	local profil = nil
	if utfall == "bedomd" then
		profil = Klassprofil.clearRound({ forsok = s.forsokNr, hojdM = HOJD_M, ponny = false, nedslag = 0,
			olydnader = s.olydnader, avfallning = false, felVag = orsak == "fel_vag", overMaxtidS = 0,
			overTillatenTid = orsak == "tillaten_tid" })
	end
	local utesluten = profil and profil.utesluten
	local resultatUtfall = if utfall ~= "bedomd" then utfall
		elseif utesluten == true then "utesluten"
		elseif utesluten == nil then "utesluten_ej_faststalld"
		elseif profil.fel == 0 then "inga_observerade_fel"
		else "observerade_fel"
	local omstart = s.forsokNr == 1 and utfall == "bedomd" and resultatUtfall ~= "inga_observerade_fel"
	s.resultat = table.freeze({ forsokId = s.forsokId, rittId = s.rittId, userId = s.userId, hastId = s.hastId,
		ovning = ClearRoundLektion.OVNING, forsokNr = s.forsokNr, bedomning = "forenklad",
		utfall = resultatUtfall, orsak = orsak, olydnader = s.olydnader,
		fel = if profil then profil.fel else nil, nedslag = "bedoms_inte", tid = tid,
		hojdM = HOJD_M, bana = "traningsbana", omstartMojlig = omstart,
		regel = if profil then profil.regel else nil })
	if utfall == "ej_bedomd" then
		Forsok.avbryt(s.rittId, Forsok.nastaSekvens(s.rittId), s.forsokId, obsTid(s.rittId), nil)
	else
		Forsok.slutfor(s.rittId, s.forsokId, if utfall == "ej_startad" then "tidsgrans" else "slutford",
			obsTid(s.rittId), nil)
	end
	s.progress = 100
	s.revision += 1
	andra(s, "complete", resultatUtfall)
end

local function nyBaslinje(s, o, p)
	s.sistaT, s.sistaObs = o.tid, o.obsTid
	s.sistaBrott = brottAntal(o)
	local plats = Plats.lektionsRam(s.rittId)
	local geo = banGeometri(plats)
	if p.ramId ~= nil and geo then
		s.ramId, s.geo = p.ramId, geo
		s.referens = table.freeze({ ramId = p.ramId, nyckel = geo.nyckel, plats = plats, start = geo.start,
			mal = geo.mal, halv = geo.halv, hinder = geo.hinder })
	else
		s.ramId, s.geo, s.referens = nil, nil, nil
	end
end

function ClearRoundLektion.steg(s, now: number)
	if not AKTIVA[s.lage] then return end
	if not aktiv(s) then andra(s, "closed", "closed"); return end
	local o = Observation.ogonblick(s.rittId)
	local p = Plats.ogonblick(s.rittId)
	local hs = Hinder.ogonblick(s.rittId)
	if not (agare(s, o) and agare(s, p) and agare(s, hs)) then return end
	--[[ Ett brott i observationen, ett bytt eller saknat hinder eller en ny
		ram: ritten kan inte bedömas — aldrig en gissning. ]]
	local geoNu = banGeometri(Plats.lektionsRam(s.rittId))
	if brottAntal(o) ~= s.sistaBrott or p.ramId == nil or p.ramId ~= s.ramId or hs.overflode
		or geoNu == nil or s.geo == nil or geoNu.nyckel ~= s.geo.nyckel then
		avsluta(s, "ej_bedomd", "observation")
		return
	end
	if o.tid == s.sistaT then return end
	local observerad = o.obsTid > s.sistaObs
	s.sistaT, s.sistaObs = o.tid, o.obsTid
	local seg = if p.status == "segment" and observerad then p.segment else nil

	if s.lage == "to_start" then
		if o.tid - s.tSignal > START_S then avsluta(s, "ej_startad", "start_45"); return end
		if korsarMotC(seg, s.geo.start) then
			s.tStart = o.tid
			s.nrBas = {}
			for _, b in ipairs(BANA) do s.nrBas[b.id] = hogstaNr(hs, b.id) end
			s.sett = {}
			s.steg, s.olydnader = 1, 0
			andra(s, "course", "jump")
		end
		return
	end
	-- TR 312.3.2 / 388.2.6: tillåten tid 180 s från startlinjen.
	if o.tid - s.tStart > TILLATEN_S then avsluta(s, "bedomd", "tillaten_tid"); return end

	if s.lage == "course" then
		-- Nya, AVSLUTADE hinderförsök efter startlinjen, i tidsordning.
		local nya = {}
		for _, f in ipairs(hs.forsok) do
			local nyckel = f.hinderId .. "#" .. tostring(f.nr)
			if s.nrBas[f.hinderId] ~= nil and f.nr > s.nrBas[f.hinderId] and f.giltighet ~= "pagar"
				and not s.sett[nyckel] then
				table.insert(nya, f)
			end
		end
		table.sort(nya, function(a, b) return (a.tUt or 0) < (b.tUt or 0) end)
		for _, f in ipairs(nya) do
			s.sett[f.hinderId .. "#" .. tostring(f.nr)] = true
			if f.giltighet ~= "fullstandig" then avsluta(s, "ej_bedomd", "observation"); return end
			local mal = s.geo.hinder[s.steg]
			if f.hinderId == mal.id then
				if f.utfall == "passage" then
					if f.riktning ~= mal.riktning then avsluta(s, "bedomd", "fel_vag"); return end
					s.steg += 1
					s.progress = math.floor(90 * (s.steg - 1) / #BANA); s.revision += 1
					if s.steg > #BANA then andra(s, "to_finish", "to_finish"); return end
					andra(s, "course", "jump")
				elseif f.utfall == "sidan_om" then
					-- TR 385: utbrytning är en olydnad; ekipaget rider hindret igen.
					s.olydnader += 1
					s.revision += 1
					if s.olydnader >= 3 then avsluta(s, "bedomd", "olydnader"); return end
				end
				-- ingen_passage bedöms inte.
			elseif f.utfall == "passage" then
				-- Ett annat banhinder hoppat (eller nästa i fel riktning ovan): fel väg (384.1, 388.2.2).
				avsluta(s, "bedomd", "fel_vag")
				return
			end
		end
		return
	end
	-- to_finish: mållinjen efter sista hindret.
	if korsarMotC(seg, s.geo.mal) then avsluta(s, "bedomd", nil) end
end

--[[ Anropas av HorseService när ritten slutar, FÖRE rivningen (försöket och
	observationerna är då fortfarande öppna). Bara en PÅGÅENDE clear round-ritt
	får utfallet; en färdig bedömning ändras aldrig. ]]
function ClearRoundLektion.vidRittSlut(s, orsak: string?)
	if type(s) ~= "table" or not AKTIVA[s.lage] or not aktiv(s) then return end
	local tid = if s.tStart then math.max(0, obsTid(s.rittId) - s.tStart) else nil
	s.resultat = table.freeze({ forsokId = s.forsokId, rittId = s.rittId, userId = s.userId, hastId = s.hastId,
		ovning = ClearRoundLektion.OVNING, forsokNr = s.forsokNr, bedomning = "forenklad",
		utfall = "avbruten", orsak = orsak or "avsittning", olydnader = s.olydnader, fel = nil,
		nedslag = "bedoms_inte", tid = tid, hojdM = HOJD_M, bana = "traningsbana", omstartMojlig = false })
	Forsok.avbryt(s.rittId, Forsok.nastaSekvens(s.rittId), s.forsokId, obsTid(s.rittId), nil)
	s.revision += 1
	andra(s, "complete", "avbruten")
	senaste[s.userId] = s.resultat
end

--[[ Provkrok: det senast avbrutna utfallet för en spelare. ]]
function ClearRoundLektion._senasteForProv(userId: number): any
	return senaste[userId]
end

function ClearRoundLektion.begar(s, op: any, seq: any, now: number): (boolean, string?, any)
	if op == "sync" then
		ClearRoundLektion.steg(s, now)
		return true, nil, ClearRoundLektion.bild(s)
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
	if op ~= "finish" then ClearRoundLektion.steg(s, now) end
	local ok, fel = false, nil
	if op == "finish" then
		if aktiv(s) then
			ok, fel = Forsok.avbryt(s.rittId, Forsok.nastaSekvens(s.rittId), s.forsokId, obsTid(s.rittId), nil)
		else ok = true end
		if ok then andra(s, "closed", "closed") end
	elseif aktiv(s) or Forsok.aktivt(s.rittId) then fel = "active"
	-- TR 314.1.1: ETT försök till, och bara efter fel eller uteslutning i det första.
	elseif op == "retry" and not (s.lage == "complete" and s.resultat and s.resultat.omstartMojlig) then
		fel = "request"
	elseif op == "start" and s.lage ~= "ready" and s.lage ~= "closed" then
		fel = "request"
	else
		local o = Observation.ogonblick(s.rittId)
		local p = Plats.ogonblick(s.rittId)
		local hs = Hinder.ogonblick(s.rittId)
		if not (agare(s, o) and agare(s, p) and agare(s, hs) and p.punkt and p.iBana == true and p.ramId ~= nil) then
			fel = "place"
		elseif banGeometri(Plats.lektionsRam(s.rittId)) == nil then
			fel = "course"
		else
			local id
			ok, fel, id = Forsok.starta(s.rittId, Forsok.nastaSekvens(s.rittId),
				ClearRoundLektion.OVNING, ClearRoundLektion.VERSION, o.tid, nil)
			if ok then
				senaste[s.userId] = nil -- en ny ritt: förra avbrutna utfallet är visat och klart
				s.forsokId = id
				s.forsokNr = if op == "retry" then 2 else 1
				s.resultat = nil
				nyBaslinje(s, o, p)
				s.tSignal, s.tStart, s.steg, s.olydnader = o.tid, nil, 0, 0
				s.progress = 0
				s.revision += 1
				andra(s, "to_start", "to_start")
			end
		end
	end
	local b = ClearRoundLektion.bild(s)
	s.svar[seq] = { op = op, ok = ok, fel = fel, bild = b }
	table.insert(s.ordning, seq)
	while #s.ordning > MAX_REQUESTS do s.svar[table.remove(s.ordning, 1)] = nil end
	return ok, fel, b
end

return ClearRoundLektion
