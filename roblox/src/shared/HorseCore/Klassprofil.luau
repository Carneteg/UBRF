--!strict
--[[ KLASSPROFILER — D1 (#266), docs/D1-CLEAR-ROUND-PROFILE-CONTRACT.md.

	En ren, versionerad regelmodul: ETT redan avgjort rittutfall in, ett
	klassutfall ut. Ingen UI, inget servertillstånd, ingen tävlingsdag.
	Källan är SvRF TR III Hoppning 2025, citerad i
	references/rules/TR-III-2025-hoppning-A-clear-round.md. Allt som den
	källan inte säger är [REFERENCE GAP] och räknas aldrig fram.

	D1 byggdes utanför Rojo-mappningen; sedan D2a (ClearRoundLektion) har den
	en konsument och ligger i HorseCore. ]]

local Klassprofil = {}

local REGEL = "SvRF TR III 2025"
local MOMENT = table.freeze({ "314.1", "314.1.1", "301.3.1.2", "381", "384.1", "388.2" })

local function heltal(x: any): boolean
	return type(x) == "number" and x == x and x >= 0 and x % 1 == 0 and x ~= math.huge
end
local function andligtIckeNeg(x: any): boolean
	return type(x) == "number" and x == x and x >= 0 and x ~= math.huge
end

local function ogiltig(skal: string): any
	return table.freeze({ profil = "A_CLEAR_ROUND", regel = REGEL, moment = MOMENT,
		giltig = false, skal = skal })
end

--[[ A: CLEAR ROUND (TR III 2025 moment 314.1.1, fel enligt 381).

	runda = { forsok = 1|2, hojdM, ponny, nedslag, olydnader, avfallning,
	          felVag, overMaxtidS, overTillatenTid }

	Svar: giltig, utesluten (true/false/nil = ej fastställt), felfri, fel
	(felpoäng, nil när uteslutning eller ej verifierat), rosett
	("clear_round" eller nil), omstartMojlig, omstartRaknasSomStart,
	profil, regel, moment. Aldrig placering eller rosettfärg. ]]
function Klassprofil.clearRound(runda: any): any
	if type(runda) ~= "table" then return ogiltig("indata") end
	local r = runda
	if not (r.forsok == 1 or r.forsok == 2) then return ogiltig("indata") end
	if type(r.ponny) ~= "boolean" or type(r.avfallning) ~= "boolean" or type(r.felVag) ~= "boolean"
		or type(r.overTillatenTid) ~= "boolean" then
		return ogiltig("indata")
	end
	if not (heltal(r.nedslag) and heltal(r.olydnader) and andligtIckeNeg(r.overMaxtidS)) then
		return ogiltig("indata")
	end
	-- [REFERENCE GAP] ponnyns klassordning under Lätt D finns inte i de citerade momenten.
	if r.ponny then return ogiltig("ponny_klassordning_okand") end
	if not andligtIckeNeg(r.hojdM) then return ogiltig("indata") end
	-- 314.1.1: A: Clear round får endast förekomma i 0,90 hoppning och lägre för häst.
	if r.hojdM > 0.90 + 1e-9 then return ogiltig("klass_over_090") end

	--[[ 381: nedslag 4; första olydnaden 4; andra olydnaden i klasser t.o.m.
		1,05/Lätt C +5 «8 fel» — [REFERENCE GAP] om det är tillägget eller
		summan, så ingen felsumma med två olydnader; tredje: uteslutning.
		Tid: 1 felpoäng per påbörjat 4-sekundersintervall över maximitiden. ]]
	local nedslagFel = 4 * r.nedslag
	local tidsFel = math.ceil(r.overMaxtidS / 4)
	-- Hinderfel (nedslag och olydnader) med den okända andra olydnaden som ett intervall.
	local hinderLag, hinderHog
	if r.olydnader == 0 then hinderLag, hinderHog = nedslagFel, nedslagFel
	elseif r.olydnader == 1 then hinderLag, hinderHog = nedslagFel + 4, nedslagFel + 4
	else hinderLag, hinderHog = nedslagFel + 8, nedslagFel + 12 end

	-- 381/388.2: automatisk uteslutning.
	local utesluten: boolean? = false
	if r.olydnader >= 3 or r.avfallning or r.felVag or r.overTillatenTid then
		utesluten = true
	elseif hinderLag > 16 then
		utesluten = true -- mer än 16 hinderfel, oavsett tolkning
	elseif hinderHog > 16 then
		utesluten = nil -- beror på den okända tolkningen av «8 fel»
	end

	local fel: number? = nil
	if utesluten == false and r.olydnader <= 1 then fel = hinderLag + tidsFel end
	local felfri = utesluten == false and fel == 0
	return table.freeze({
		profil = "A_CLEAR_ROUND", regel = REGEL, moment = MOMENT, giltig = true,
		utesluten = utesluten, felfri = felfri, fel = fel,
		-- 314.1.1: rosett bara för felfritt FÖRSTA försök. [REFERENCE GAP] för försök 2.
		rosett = if felfri and r.forsok == 1 then "clear_round" else nil,
		-- 314.1.1: vid felpoäng eller uteslutning i första försöket, ett försök till.
		omstartMojlig = r.forsok == 1 and not felfri,
		-- 301.3.1.2: omstarten räknas inte som en andra start.
		omstartRaknasSomStart = false,
	})
end

return Klassprofil
