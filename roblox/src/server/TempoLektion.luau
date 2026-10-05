--!strict
--[[ JÄMN FART I SKRITT — docs/TEMPO-LESSON-CONTRACT.md.

	EN övning i tempoområdet: jämn OBSERVERAD fart i skritt. Den mäter
	inte hovtakt, kadens, steglängd, böjning eller hjälper; den befintliga
	okända `rytm` förblir okänd. Samma livscykel och begäranregler som de
	andra lektionerna. Bevis bara ur befintliga observationer i den
	befintliga takten: RidObservations egna räknare och dess nyaste
	fönsterprov, RidPlatsObservations `iDressyr` och RidLoggs
	gångartshändelser. Fönstrets samlade `tempo`, gamla prov och summor
	från före baslinjen används aldrig. Siffrorna är spelantaganden ur
	skrittens konfiguration. ]]
local Forsok = require(script.Parent.RidForsok)
local Observation = require(script.Parent.RidObservation)
local Plats = require(script.Parent.RidPlatsObservation)
local Logg = require(script.Parent.RidLogg)

local TempoLektion = {}
TempoLektion.OVNING = "jamn_skritt"
TempoLektion.VERSION = "server-tempo-1"

local DEADLINE = 120
local MAX_REQUESTS = 16
local M = 3 -- studs per meter, som BuildKit.M / Config.STUDS_PER_METRE
local GOLV = 0.90 -- m/s, Gaits.BY_NAME.walk.min
local TAK = 2.20 -- m/s, skritt → trav-tröskeln i Gaits
local SPRIDNING = 0.25 -- (max − min) / medel i den kvalificerande serien
local MIN_PROV = 30
local MIN_TID = 8.0 -- observerade sekunder
local MIN_M = 10.0 -- meter
TempoLektion.GRANSER = table.freeze({ GOLV = GOLV, TAK = TAK, SPRIDNING = SPRIDNING,
	MIN_PROV = MIN_PROV, MIN_TID = MIN_TID, MIN_M = MIN_M, DEADLINE = DEADLINE })

function TempoLektion.ny(rittId: string, userId: number, hastId: string): any
	return { typ = "tempo", rittId = rittId, userId = userId, hastId = hastId, lage = "ready",
		revision = 0, hogsta = 0, svar = {}, ordning = {}, progress = 0, tips = "intro",
		--[[ Tempocoachning (docs/TEMPO-COACHING-CONTRACT.md): händelseräknaren
			för det aktuella försöket, och den förra DISTINKTA fullföljningen i
			det här lektionsobjektet (samma ritt, häst och definition). ]]
		coachNr = 0, coachSkal = nil, forraKlar = nil, jamforelse = nil }
end

function TempoLektion.bild(s): any
	local j = s.jamforelse
	return table.freeze({ typ = "tempo", rittId = s.rittId, forsokId = s.forsokId,
		revision = s.revision, sekvens = s.hogsta, lage = s.lage, progress = s.progress,
		tips = s.tips, resultat = s.resultat,
		coachNr = s.coachNr or 0, coachSkal = s.coachSkal,
		jamforelse = if s.lage == "complete" and j and j.forsokId == s.forsokId then j else nil })
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

local function segmentAntal(o): number
	local g = o.giltighet
	return if type(g) == "table" and type(g.segment) == "number" then g.segment else -1
end

--[[ En tom kvalificerande serie. ]]
local function tomSerie(s)
	s.prov, s.sek, s.meter, s.summa = 0, 0, 0, 0
	s.minFart, s.maxFart = math.huge, -math.huge
end

--[[ Serien bort, med tips. Progress till 0 (bara en revision om den
	faktiskt ändras, så ingen återstartskedja). ]]
local function omSerie(s, tips)
	--[[ R1: skälet gäller bara så länge det är den AKTUELLA klassningen.
		Varje återställning rensar det; `coach()` sätter det igen direkt efter
		när återställningen själv är en coachningshändelse. `coachNr` rörs
		inte. ]]
	s.coachSkal = nil
	tomSerie(s)
	andra(s, "steady", tips)
	satProgress(s, 0)
end

--[[ Tempocoachning: en HÄNDELSE — bara vid de tre fartklassningarna, som
	redan ligger efter varje avbrotts- och färskhetsprövning. En revision per
	händelse, så att klienten kan skilja en ny händelse från en omritning. ]]
local function coach(s, skal: string)
	s.coachNr = (s.coachNr or 0) + 1
	s.coachSkal = skal
	s.revision += 1
end

local function andligtPositivt(x: any): boolean
	return type(x) == "number" and x == x and x ~= math.huge and x > 0
end
local function andligtIckeNeg(x: any): boolean
	return type(x) == "number" and x == x and x ~= math.huge and x >= 0
end

--[[ Ny baslinje: bara steg EFTER den räknas, och det första steget efter
	den krediteras aldrig (dess intervall kan börja före baslinjen). ]]
local function nyBaslinje(s, o, p, logg)
	s.sistaT, s.sistaD, s.sistaSeg = o.tid, o.distans, segmentAntal(o)
	s.sistaBrott = brottAntal(o)
	s.loggSett = #logg.handelser
	s.ramId = p.ramId
	s.sistaInne = p.iDressyr == true
	s.hoppa = true
end

local function stang(s, orsak): boolean
	if not aktiv(s) then return false end
	if not Forsok.slutfor(s.rittId, s.forsokId, orsak, obsTid(s.rittId), nil) then return false end
	if orsak == "slutford" then
		local medel = s.summa / s.prov
		s.resultat = table.freeze({ forsokId = s.forsokId, rittId = s.rittId, userId = s.userId,
			hastId = s.hastId, ovning = TempoLektion.OVNING, prov = s.prov, sekunder = s.sek,
			meter = s.meter, medelFart = medel, spridning = (s.maxFart - s.minFart) / medel,
			enhet = "m/s", start = Forsok.ogonblick(s.forsokId).start })
		--[[ Tempocoachning: jämförelsen med den FÖRRA distinkta fullföljningen
			i samma lektionsobjekt, bara med ändliga, jämförbara fakta. ]]
		local ny, forra = s.resultat, s.forraKlar
		s.jamforelse = nil
		if forra and forra.forsokId ~= ny.forsokId and forra.rittId == ny.rittId and forra.hastId == ny.hastId
			and forra.ovning == ny.ovning and andligtIckeNeg(forra.spridning) and andligtIckeNeg(ny.spridning)
			and andligtPositivt(forra.medelFart) and andligtPositivt(ny.medelFart) then
			s.jamforelse = table.freeze({ forsokId = ny.forsokId, forraForsokId = forra.forsokId,
				forraSpridning = forra.spridning, spridning = ny.spridning })
		end
		if andligtIckeNeg(ny.spridning) and andligtPositivt(ny.medelFart) then s.forraKlar = ny end
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

function TempoLektion.steg(s, now: number, gangart: string?, ryggar: boolean?)
	if s.lage ~= "steady" then return end
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
		local hadeKredit = s.prov > 0
		nyBaslinje(s, o, p, logg)
		if hadeKredit or brott or ramFel or logg.overflode then omSerie(s, "unknown") end
		return
	end
	if o.tid == s.sistaT then return end

	local dt = o.tid - s.sistaT
	local meter = (o.distans - s.sistaD) / M
	local nyaSeg = segmentAntal(o) - s.sistaSeg
	local varInne = s.sistaInne
	local nyaHandelser = false
	for i = s.loggSett + 1, #logg.handelser do
		if logg.handelser[i].typ == "gangart" then nyaHandelser = true end
	end
	local hoppa = s.hoppa
	s.sistaT, s.sistaD, s.sistaSeg = o.tid, o.distans, segmentAntal(o)
	s.loggSett = #logg.handelser
	s.sistaInne = p.iDressyr == true
	s.hoppa = false

	--[[ Gångart och läge först: de kastar serien även på gränssteget. ]]
	if ryggar == true or gangart ~= "walk" then
		omSerie(s, if gangart == "halt" and ryggar ~= true then "walk_on" else "walk_only")
		return
	end
	if not (varInne and p.iDressyr == true) then omSerie(s, "stay_inside"); return end
	if hoppa then return end
	if nyaHandelser then omSerie(s, "walk_on"); return end

	--[[ Ett steg, ett nytt prov: exakt ett nytt giltigt segment, och
		fönstrets nyaste prov slutar vid just det här stegets tid. ]]
	local f = o.fonster
	local sist = type(f) == "table" and f[#f] or nil
	if nyaSeg ~= 1 or not sist or sist.t ~= o.tid or sist.gangart ~= "walk" or sist.ryggar
		or not (dt > 0) then
		omSerie(s, "unknown")
		return
	end

	local fart = meter / dt
	if fart < GOLV then omSerie(s, "too_slow"); coach(s, "too_slow"); return end
	if fart > TAK then omSerie(s, "too_fast"); coach(s, "too_fast"); return end
	local lo, hi = math.min(s.minFart, fart), math.max(s.maxFart, fart)
	local medel = (s.summa + fart) / (s.prov + 1)
	if s.prov > 0 and (hi - lo) / medel > SPRIDNING then
		--[[ För ojämnt: serien börjar om MED det här steget som första
			prov — färskt bevis, ingen återstartskedja. ]]
		tomSerie(s)
		s.prov, s.sek, s.meter, s.summa = 1, dt, meter, fart
		s.minFart, s.maxFart = fart, fart
		andra(s, "steady", "steadier")
		coach(s, "steadier")
	else
		s.prov += 1
		s.sek += dt
		s.meter += meter
		s.summa += fart
		s.minFart, s.maxFart = lo, hi
		s.coachSkal = nil -- R1: återhämtning är inget coachningsskäl (och inget beröm)
		andra(s, "steady", "keep_going")
	end
	satProgress(s, 99 * math.min(s.prov / MIN_PROV, s.sek / MIN_TID, s.meter / MIN_M, 1))
	if s.prov >= MIN_PROV and s.sek >= MIN_TID and s.meter >= MIN_M then stang(s, "slutford") end
end

function TempoLektion.begar(s, op: any, seq: any, now: number, gangart: string?,
	ryggar: boolean?): (boolean, string?, any)
	if op == "sync" then
		TempoLektion.steg(s, now, gangart, ryggar)
		return true, nil, TempoLektion.bild(s)
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
	if op ~= "finish" then TempoLektion.steg(s, now, gangart, ryggar) end
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
		if not (agare(s, o) and agare(s, p) and logg and p.punkt and p.iDressyr == true
			and p.ramId ~= nil) then
			fel = "place"
		else
			local id
			ok, fel, id = Forsok.starta(s.rittId, Forsok.nastaSekvens(s.rittId),
				TempoLektion.OVNING, TempoLektion.VERSION, o.tid, nil)
			if ok then
				s.forsokId, s.deadline = id, now + DEADLINE
				s.resultat = nil
				-- Nytt försök: räknaren om, jämförelsen bort (den förra fullföljningen står kvar).
				s.coachNr, s.coachSkal, s.jamforelse = 0, nil, nil
				nyBaslinje(s, o, p, logg)
				tomSerie(s)
				s.progress = 0
				s.revision += 1
				andra(s, "steady", "walk_on")
			end
		end
	end
	local b = TempoLektion.bild(s)
	s.svar[seq] = { op = op, ok = ok, fel = fel, bild = b }
	table.insert(s.ordning, seq)
	while #s.ordning > MAX_REQUESTS do s.svar[table.remove(s.ordning, 1)] = nil end
	return ok, fel, b
end

return TempoLektion
