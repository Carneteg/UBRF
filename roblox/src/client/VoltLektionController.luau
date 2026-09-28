--!strict
-- Presentation of server circle evidence, never a client-side assessment.
local Net = require(game:GetService("ReplicatedStorage").HorseCore.Networking)
local Sprak = require(game:GetService("ReplicatedStorage").HorseCore.Sprak)
local Plats = require(game:GetService("ReplicatedStorage").HorseCore.Ridhusplats)
local Ugneta = require(script.Parent.UgnetaController)
local Aterkoppling = require(script.Parent.LektionsAterkoppling)
local Installning = require(script.Parent.LararInstallning)
--[[ C4: spelarens EGET lektionsminne, som serverns projektion (läsning
	bara). Tre lägen per lektion — "sparad", "vantar", "ej_klarad" — och
	"okand" när historiken inte gick att lita på. Aldrig ett betyg. ]]
local MINNE_TYPER = { volt = true, halt = true, overgang = true, serpentin = true, tempo = true,
	vag_mitt = true, vag_diag = true, halvvolt = true, galopp = true, markbom = true, hornet = true }
local MINNE_LAGEN = { sparad = true, vantar = true, ej_klarad = true, okand = true }
--[[ Den fasta pedagogiska ordningen för ETT förslag (kontraktet):
	halt och jämn skritt först, sedan volten, övergångar, raka linjer,
	serpentin, halvvolt, markbom och sist galoppfattningen. Ett förslag är
	en riktning, inte ett påstående om att något bedömts. ]]
local MINNE_ORDNING = { "halt", "tempo", "volt", "overgang", "vag_mitt", "vag_diag", "serpentin",
	"halvvolt", "hornet", "markbom", "galopp" }
local minne: { historik: string, lektioner: { [string]: string }, session: number, rev: number }? = nil
local minneLyssnare: any = nil

--[[ ══ STARTHÄLSNINGEN (C2/#234) — docs/INSTRUCTOR-START-CONTRACT.md ══
	Skapas BARA i svaret på en egen start/retry som servern godtog, för det
	försök svaret bär, och bara om det försöket fortfarande är det aktuella
	och aktiva. Visas först i lektionssidans egen text i HALSNING_S sekunder
	(räknas i V.steg) och tas bort av allt som byter försök, läge, val,
	ritt eller ger vänta/fel. Förbrukas en gång per försök; kommer aldrig
	tillbaka. `halsadForsok` är det senast hälsade/förbrukade försöket i
	DENNA ritt. ]]
local HALSNING_S = 6
local halsning: { forsokId: any, typ: string, ritt: string, kvar: number }? = nil
local halsadForsok: any = nil
--[[ R1: VALETS GENERATION. Räknas upp vid VARJE `V.valj` (även samma typ,
	även när ingen sync kan skickas för att en begäran väntar), och vid
	`V.start`/`V.avbryt`. En begäran fångar den; en hälsning kräver att den
	är oförändrad när svaret kommer. ]]
local valGen = 0
--[[ R1: EN prenumeration för modulens livstid (som minnets lyssnare): "inga"
	tar bort en synlig hälsning direkt. Den är redan förbrukad (försöket är
	markerat), så den kommer inte tillbaka vid Inga -> Normalt/Färre. ]]
local installLyssnare: (() -> ())? = nil

--[[ ══ TEMPOCOACHNINGEN — docs/TEMPO-COACHING-CONTRACT.md ═══════════════
	Bara jämn skritt (typ "tempo"). `coachForsok`/`coachSedd` är baslinjen
	för det försök som visas: första bilden av ett försök sätter den utan
	att visa något; en HÖGRE `coachNr` i en godtagen bild av samma försök är
	en ny händelse. `coachCd` är spärren (LIVE_CD.fel), `coachning` den
	visade (LIVE_CD.visa). Ingen kö, ingen uppspelning. ]]
local COACH_SKAL = { too_slow = true, too_fast = true, steadier = true }
local COACH_CD = require(game:GetService("ReplicatedStorage").HorseCore.RidKanon).UGNETA.LIVE_CD
local coachForsok: any = nil
local coachSedd = 0
local coachCd = 0
local coachning: { forsokId: any, ritt: string, skal: string, kvar: number }? = nil
local AKTIVA_LAGEN = { approach = true, baseline = true, riding = true, halt1 = true, walk = true,
	walk1 = true, trot = true, walk2 = true, to_start = true, route = true, steady = true,
	canter = true, crossing = true, exit = true }

local function heltal(x: any): number
	if type(x) ~= "number" or x ~= x or x < 0 or x == math.huge or x % 1 ~= 0 then return -1 end
	return x
end

local function tvattMinne(p: any): any
	if type(p) ~= "table" or type(p.lektioner) ~= "table" then return nil end
	local ut = {}
	for typ in MINNE_TYPER do
		local l = p.lektioner[typ]
		ut[typ] = if type(l) == "string" and MINNE_LAGEN[l] then l else "okand"
	end
	return { historik = if p.historik == "betrodd" then "betrodd" else "okand", lektioner = ut,
		session = heltal(p.session), rev = heltal(p.rev) }
end

--[[ R1: ORDNINGEN. Push och läsningssvar tas emot likadant: bara en
	projektion från en NYARE serversession, eller samma session med minst
	samma revision, ersätter den som hålls. Ett gammalt svar som kommer efter
	en nyare push, eller ett svar från före en återkoppling, ignoreras. ]]
local function taEmotMinne(p: any)
	local m = tvattMinne(p)
	if not m or m.session < 0 or m.rev < 0 then return end
	local nu = minne
	if nu and (m.session < nu.session or (m.session == nu.session and m.rev < nu.rev)) then return end
	minne = m
end

--[[ Var förslaget finns i menyn: gruppen på toppnivån (nil = volten, som
	står direkt) och en eventuell undergrupp. ]]
local MINNE_GRUPP = { halt = "gangart", tempo = "gangart", overgang = "gangart", galopp = "gangart",
	serpentin = "vagar", halvvolt = "vagar", vag_mitt = "vagar", vag_diag = "vagar", markbom = "vagar",
	hornet = "vagar" }
local MINNE_UNDERGRUPP = { overgang = "overgangar", galopp = "overgangar", vag_mitt = "linjer",
	vag_diag = "linjer", markbom = "linjer", serpentin = "bojda", halvvolt = "bojda", hornet = "bojda" }

local function klarad(typ: string): boolean
	local l = minne and minne.lektioner[typ]
	return l == "sparad" or l == "vantar"
end

--[[ ETT förslag: första i ordningen som inte är klarad; alla klarade ger
	"öva igen" på den första. Okänd historik ger inget förslag. ]]
local function forslag(): (string?, boolean)
	local m = minne
	if not m or m.historik ~= "betrodd" then return nil, false end
	for _, typ in MINNE_ORDNING do
		if not klarad(typ) then return typ, false end
	end
	return MINNE_ORDNING[1], true
end
local V = {}
local ritt: string? = nil
local valt, fri = false, false
local attached = false
local bild: any = nil
local sekvens, generation, requestNr = 0, 0, 0
local pending, pendingTid = false, 0
local fel: string? = nil
local listener: any = nil
local guide: Model? = nil
local guideRef: any = nil
local gaLektion: (() -> ())? = nil
-- Vald lektion: "volt" (voltlektionen), "halt" (start/halt vid X),
-- "overgang" (övergångar vid T1/T2), "serpentin" (träningsserpentin) eller
-- "tempo" (jämn fart i skritt; ingen guide), "vag_mitt" eller "vag_diag"
-- (ridvägarna; figuren är typen), "halvvolt" (halvvolt tillbaka till spåret)
-- "galopp" (galoppfattning vid K, utan galoppsida) eller "markbom" (bom på marken).
local typ = "volt"
-- Valsidan före en vald lektion: nil = toppnivån, "topp" (ersättningssidan
-- bakom "Välj övning"), "gangart", "overgangar" (undergrupp i gangart),
-- "vagar" eller "linjer" (undergrupp i vagar). Naromrade visar högst fyra
-- val (MAX_VAL) och Ugnetas 0..3 kortknappar kommer först; toppnivån ger
-- därför också en kompakt lista med EN post (R1), som Ugneta väljer när den
-- fulla inte ryms. Varje sida har högst tre val plus Tillbaka.
local meny: string? = nil
local guideTyp: string? = nil
local guideDel: number? = nil
--[[ C3 (docs/ROUTE-LESS-GUIDANCE-CONTRACT.md): spelarens eget val "Rid utan streck"
	för ridvägarna. Sessionslokalt, aldrig sparat, aldrig automatiskt; ny ritt,
	typbyte och avbrott ger hela guiden igen. `guideUtan` är cachens nyckel. ]]
local utanStreck = false
local guideUtan: boolean? = nil

local function rivGuide()
	if guide then guide:Destroy() end
	guide, guideRef, guideDel, guideUtan = nil, nil, nil, nil
end

-- One flat non-colliding dash, only if the whole dash stays within the arena.
local function streck(m, p, pos, riktning, half, stark)
	local bound = half * 1.1
	if not (Plats.inom(p,"bana",pos+p.tvars*bound) and Plats.inom(p,"bana",pos-p.tvars*bound)
		and Plats.inom(p,"bana",pos+p.motC*bound) and Plats.inom(p,"bana",pos-p.motC*bound)) then
		return
	end
	local part = Instance.new("Part")
	part.Name = "Guide"; part.Anchored = true; part.CanCollide = false
	part.CanTouch = false; part.CanQuery = false; part.CastShadow = false
	part.Size = Vector3.new(half*0.65,0.05,half*2)
	part.CFrame = CFrame.lookAt(pos,pos+riktning)
	part.Color = Color3.fromRGB(77,174,142)
	part.Transparency = if stark then 0.25 else 0.8
	part.Parent = m
end

-- Serpentine: the three loops of the server's route, the start ring and the
-- end ring. The next portion (delmal 0 start ring, 1-3 loop, 4 end ring) is
-- solid, the rest faint.
local function serpentinGuide(m, ref, delmal)
	local p = ref.plats
	local half = 0.5 * p.studsPerMeter
	local function lokalt(u, v) return Plats.tillVarld(p, Vector3.new(u, 0.035, v)) end
	for k = 1, 3 do
		local c = ref.v0 + ref.r + (k - 1) * 2 * ref.r
		local side = ref.sidor[k]
		local antal = 20
		for i = 0, antal - 1 do
			local th = math.pi * (i + 0.5) / antal
			local pos = lokalt(ref.u + side*ref.r*math.sin(th), c - ref.r*math.cos(th))
			local fram = lokalt(ref.u + side*ref.r*math.sin(th + 0.05), c - ref.r*math.cos(th + 0.05))
			streck(m, p, pos, fram - pos, half, delmal == k)
		end
	end
	for j, v in ipairs({ ref.v0, ref.v0 + 6 * ref.r }) do
		local antal = 12
		for i = 0, antal - 1 do
			local a = 2 * math.pi * i / antal
			local pos = lokalt(ref.u + ref.ring*math.cos(a), v + ref.ring*math.sin(a))
			local fram = lokalt(ref.u + ref.ring*math.cos(a + 0.05), v + ref.ring*math.sin(a + 0.05))
			streck(m, p, pos, fram - pos, 0.3 * p.studsPerMeter,
				(j == 1 and delmal == 0) or (j == 2 and delmal == 4))
		end
	end
end

-- Riding paths: the selected line with direction chevrons, a start ring and
-- an end ring. The next target is solid (start ring before arming, the line
-- and end ring while riding), the rest faint.
local function vagGuide(m, ref, delmal, utan: boolean?)
	local p = ref.plats
	local function lokalt(u, v) return Plats.tillVarld(p, Vector3.new(u, 0.035, v)) end
	local du, dv = (ref.u1 - ref.u0) / ref.langd, (ref.v1 - ref.v0) / ref.langd
	local riktning = lokalt(ref.u0 + du, ref.v0 + dv) - lokalt(ref.u0, ref.v0)
	local korsVek = lokalt(ref.u0 + dv, ref.v0 - du) - lokalt(ref.u0, ref.v0)
	local ridning = delmal ~= nil and delmal >= 1
	local antal = math.max(2, math.floor(ref.langd / 1.5))
	-- C3: med mindre vägvisning ritas bara start- och slutringen nedan.
	for i = 1, if utan then 0 else antal - 1 do
		local t = ref.langd * i / antal
		local pos = lokalt(ref.u0 + du * t, ref.v0 + dv * t)
		streck(m, p, pos, riktning, 0.45 * p.studsPerMeter, ridning)
	end
	-- Chevrons every 6 m point from start to end.
	local t = if utan then math.huge else 6
	while t < ref.langd - 3 do
		local spets = lokalt(ref.u0 + du * t, ref.v0 + dv * t)
		for _, sida in ipairs({ 1, -1 }) do
			local fot = spets - riktning * 0.8 + korsVek * (0.8 * sida)
			streck(m, p, (spets + fot) / 2, spets - fot, 0.4 * p.studsPerMeter, ridning)
		end
		t += 6
	end
	for j, c in ipairs({ { ref.u0, ref.v0 }, { ref.u1, ref.v1 } }) do
		local n = 12
		for i = 0, n - 1 do
			local a = 2 * math.pi * i / n
			local pos = lokalt(c[1] + ref.ring*math.cos(a), c[2] + ref.ring*math.sin(a))
			local fram = lokalt(c[1] + ref.ring*math.cos(a + 0.05), c[2] + ref.ring*math.sin(a + 0.05))
			streck(m, p, pos, fram - pos, 0.3 * p.studsPerMeter,
				(j == 1 and not ridning) or (j == 2 and ridning))
		end
	end
end

-- Half-circle back to the track: the server's route parameters (track, arc,
-- return line), direction chevrons on the straight parts, and the start and end
-- rings. delmal: 0 start ring, 1 track, 2 half-circle, 3 return, 4 end ring.
local function halvvoltGuide(m, ref, delmal, utan: boolean?)
	local p = ref.plats
	local function lokalt(u, v) return Plats.tillVarld(p, Vector3.new(u, 0.035, v)) end
	local function rak(au, av, bu, bv, stark)
		local L = math.sqrt((bu - au) ^ 2 + (bv - av) ^ 2)
		local du, dv = (bu - au) / L, (bv - av) / L
		local riktning = lokalt(au + du, av + dv) - lokalt(au, av)
		local korsVek = lokalt(au + dv, av - du) - lokalt(au, av)
		local antal = math.max(2, math.floor(L / 1.5))
		for i = 1, antal - 1 do
			local t = L * i / antal
			streck(m, p, lokalt(au + du * t, av + dv * t), riktning, 0.45 * p.studsPerMeter, stark)
		end
		local t = 4
		while t < L - 2 do
			local spets = lokalt(au + du * t, av + dv * t)
			for _, sida in ipairs({ 1, -1 }) do
				local fot = spets - riktning * 0.8 + korsVek * (0.8 * sida)
				streck(m, p, (spets + fot) / 2, spets - fot, 0.4 * p.studsPerMeter, stark)
			end
			t += 5
		end
	end
	--[[ C3 (docs/HALF-CIRCLE-LESS-GUIDANCE-CONTRACT.md): med mindre vägvisning ritas inte
		inridningen längs spåret — bågen, returdiagonalen och ringarna står kvar. ]]
	if not utan then rak(ref.uT, ref.p0v, ref.uT, ref.t1v, delmal == 1) end
	local cu, cv = ref.uT - ref.r, ref.t1v
	local antal = 16
	for i = 0, antal - 1 do
		local th = math.pi * (i + 0.5) / antal
		local pos = lokalt(cu + ref.r * math.cos(th), cv + ref.r * math.sin(th))
		local fram = lokalt(cu + ref.r * math.cos(th + 0.05), cv + ref.r * math.sin(th + 0.05))
		streck(m, p, pos, fram - pos, 0.45 * p.studsPerMeter, delmal == 2)
	end
	rak(ref.uT - 2 * ref.r, ref.t1v, ref.uT, ref.ev, delmal == 3 or delmal == 4)
	for j, c in ipairs({ { ref.uT, ref.p0v }, { ref.uT, ref.ev } }) do
		local n = 12
		for i = 0, n - 1 do
			local a = 2 * math.pi * i / n
			local pos = lokalt(c[1] + ref.ring*math.cos(a), c[2] + ref.ring*math.sin(a))
			local fram = lokalt(c[1] + ref.ring*math.cos(a + 0.05), c[2] + ref.ring*math.sin(a + 0.05))
			streck(m, p, pos, fram - pos, 0.3 * p.studsPerMeter,
				(j == 1 and delmal == 0) or (j == 2 and delmal == 4))
		end
	end
end

-- Ground pole: the server's pole frame (centre, width axis A, intended
-- direction W towards C). Dashed corridor edges on the approach, chevrons on
-- a = 0 towards the pole, a mark beside each pole end (never on the pole) and
-- an exit lane. delmal: 0 approach, 1 crossing, 2 exit.
local function markbomGuide(m, ref, delmal)
	local p = ref.plats
	local function lokalt(a, w)
		return Plats.tillVarld(p, Vector3.new(ref.u + ref.au * a + ref.wu * w, 0.035,
			ref.v + ref.av * a + ref.wv * w))
	end
	local fram = lokalt(0, 1) - lokalt(0, 0)
	local sidled = lokalt(1, 0) - lokalt(0, 0)
	local kant = ref.bredd / 2 + ref.sida
	local w = -ref.djup
	while w < -0.6 do
		for _, a in ipairs({ -kant, kant }) do
			streck(m, p, lokalt(a, w), fram, 0.35 * p.studsPerMeter, delmal == 0)
		end
		w += 1.2
	end
	w = -ref.djup + 1
	while w < -1.5 do
		local spets = lokalt(0, w)
		for _, sida in ipairs({ 1, -1 }) do
			local fot = spets - fram * 0.7 + sidled * (0.7 * sida)
			streck(m, p, (spets + fot) / 2, spets - fot, 0.35 * p.studsPerMeter, delmal == 0)
		end
		w += 2.5
	end
	for _, a in ipairs({ -(ref.bredd / 2 + 0.3), ref.bredd / 2 + 0.3 }) do
		streck(m, p, lokalt(a, 0), fram, 0.3 * p.studsPerMeter, delmal == 1)
	end
	w = 0.6
	while w <= 3 do
		for _, a in ipairs({ -kant, kant }) do
			streck(m, p, lokalt(a, w), fram, 0.35 * p.studsPerMeter, delmal == 2)
		end
		w += 1.2
	end
end

--[[ GENOM HÖRNET: inridning, kvartsvolt och utridning ur SAMMA `referens`
	som servern projicerar mot (uT, cu, cv, r, p0, p3, ring). Pilar visar
	riktningen; delmålet (1 inridning, 2 bågen, 3 utridning) lyses starkare. ]]
local function hornGuide(m, ref, delmal, utan: boolean?)
	local p = ref.plats
	local function lokalt(u, v) return Plats.tillVarld(p, Vector3.new(u, 0.035, v)) end
	local function rak(au, av, bu, bv, stark)
		local L = math.sqrt((bu - au) ^ 2 + (bv - av) ^ 2)
		if L <= 0 then return end
		local du, dv = (bu - au) / L, (bv - av) / L
		local riktning = lokalt(au + du, av + dv) - lokalt(au, av)
		local korsVek = lokalt(au + dv, av - du) - lokalt(au, av)
		local antal = math.max(2, math.floor(L / 1.5))
		for i = 1, antal - 1 do
			local t = L * i / antal
			streck(m, p, lokalt(au + du * t, av + dv * t), riktning, 0.45 * p.studsPerMeter, stark)
		end
		local t = 3
		while t < L - 1 do
			local spets = lokalt(au + du * t, av + dv * t)
			for _, sida in ipairs({ 1, -1 }) do
				local fot = spets - riktning * 0.8 + korsVek * (0.8 * sida)
				streck(m, p, (spets + fot) / 2, spets - fot, 0.4 * p.studsPerMeter, stark)
			end
			t += 4
		end
	end
	--[[ C3 (docs/CORNER-LESS-GUIDANCE-CONTRACT.md): med mindre vägvisning ritas inte
		inridningens och utridningens raka delar — bågen och ringarna står kvar. ]]
	if not utan then rak(ref.p0u, ref.p0v, ref.uT, ref.cv, delmal == 1) end
	local antal = 10
	for i = 0, antal - 1 do
		local th = (math.pi / 2) * (i + 0.5) / antal
		local pos = lokalt(ref.cu + ref.r * math.cos(th), ref.cv + ref.r * math.sin(th))
		local fram = lokalt(ref.cu + ref.r * math.cos(th + 0.05), ref.cv + ref.r * math.sin(th + 0.05))
		streck(m, p, pos, fram - pos, 0.45 * p.studsPerMeter, delmal == 2)
	end
	if not utan then rak(ref.cu, ref.cv + ref.r, ref.p3u, ref.p3v, delmal == 3) end
	for j, c in ipairs({ { ref.p0u, ref.p0v }, { ref.p3u, ref.p3v } }) do
		local n = 12
		for i = 0, n - 1 do
			local a = 2 * math.pi * i / n
			local pos = lokalt(c[1] + ref.ring*math.cos(a), c[2] + ref.ring*math.sin(a))
			local fram = lokalt(c[1] + ref.ring*math.cos(a + 0.05), c[2] + ref.ring*math.sin(a + 0.05))
			streck(m, p, pos, fram - pos, 0.3 * p.studsPerMeter,
				(j == 1 and delmal == 0) or (j == 2 and delmal == 3))
		end
	end
end

local function vagTyp(t: string?): boolean
	return t == "vag_mitt" or t == "vag_diag"
end

local function visaGuide(ref, delmal)
	if not ref or not ref.plats then rivGuide(); return end
	local utan = utanStreck and (vagTyp(typ) or typ == "hornet" or typ == "halvvolt")
	if guideRef and guideRef.ramId == ref.ramId and guideRef.nyckel == ref.nyckel and guideTyp == typ
		and guideDel == delmal and guideUtan == utan then return end
	rivGuide()
	local m = Instance.new("Model"); m.Name = "Voltguide"
	if typ == "serpentin" or vagTyp(typ) or typ == "halvvolt" or typ == "markbom" or typ == "hornet" then
		if typ == "serpentin" then serpentinGuide(m, ref, delmal)
		elseif typ == "hornet" then hornGuide(m, ref, delmal, utan)
		elseif typ == "halvvolt" then halvvoltGuide(m, ref, delmal, utan)
		elseif typ == "markbom" then markbomGuide(m, ref, delmal)
		else vagGuide(m, ref, delmal, utan) end
		m.Parent = workspace; guide, guideRef, guideTyp, guideDel, guideUtan = m, ref, typ, delmal, utan
		return
	end
	local p = ref.plats
	-- Volt: dashes fill the allowed inner band. Halt: a small ring marks the
	-- stopping zone at X. Transitions: one ring per training target (T1, T2).
	-- Each whole dash stays within the arena.
	local ringar
	if typ == "overgang" then
		ringar = { { u = ref.u, v = ref.v1, r = ref.halv }, { u = ref.u, v = ref.v2, r = ref.halv } }
	elseif typ == "galopp" then
		-- Canter departure: one ring at K, the same radius as the server zone.
		ringar = { { u = ref.u, v = ref.v, r = ref.radie } }
	elseif typ == "halt" then
		ringar = { { u = ref.u, v = ref.v, r = ref.radie } }
	else
		ringar = { { u = ref.u, v = ref.v, r = ref.radie - 1 } }
	end
	local antal = if typ == "volt" then 72 else 16
	for _, ring in ipairs(ringar) do
	for i = 0, antal - 1 do
		local a = 2 * math.pi * i / antal
		local pos = Plats.tillVarld(p, Vector3.new(ring.u + ring.r*math.cos(a),
			0.035, ring.v + ring.r*math.sin(a)))
		local half = (if typ == "volt" then 0.8 else 0.3) * p.studsPerMeter
		local bound = half * 1.1
		if Plats.inom(p,"bana",pos+ p.tvars*bound) and Plats.inom(p,"bana",pos-p.tvars*bound)
			and Plats.inom(p,"bana",pos+p.motC*bound) and Plats.inom(p,"bana",pos-p.motC*bound) then
			local part = Instance.new("Part")
			part.Name = "Guide"; part.Anchored = true; part.CanCollide = false
			part.CanTouch = false; part.CanQuery = false; part.CastShadow = false
			part.Size = Vector3.new(half*2,0.05,half*0.65)
			part.CFrame = CFrame.lookAt(pos,pos+p.motC) * CFrame.Angles(0,-a,0)
			part.Color = Color3.fromRGB(77,174,142); part.Transparency = 0.5
			part.Parent = m
		end
	end
	end
	m.Parent = workspace; guide, guideRef, guideTyp, guideUtan = m, ref, typ, utan
end

local function mottag(b)
	if not attached or not ritt or type(b)~="table" or b.rittId~=ritt or type(b.revision)~="number" then return end
	if (b.typ or "volt") ~= typ then return end
	if bild and b.revision < bild.revision then return end
	bild = b
	--[[ Tempocoachning: baslinje eller ny händelse, bara i en GODTAGEN bild. ]]
	if typ == "tempo" and b.forsokId ~= nil then
		local nr = if type(b.coachNr) == "number" and b.coachNr == b.coachNr then b.coachNr else 0
		--[[ R1: en SYNLIG rad tas bort direkt när den nyss godtagna bilden inte
			längre stöder den (annat försök, inte steady, eller aktuellt tips
			≠ radens skäl). Spärren och Färre rörs inte; inget köas. ]]
		local cg0 = coachning
		if cg0 and (b.forsokId ~= cg0.forsokId or b.lage ~= "steady" or b.tips ~= cg0.skal) then
			coachning = nil
		end
		if coachForsok ~= b.forsokId then
			coachForsok, coachSedd, coachning = b.forsokId, nr, nil
		elseif nr > coachSedd then
			coachSedd = nr
			local halsar = halsning ~= nil and halsning.forsokId == b.forsokId
			--[[ R1: bara ett skäl som ÄR den aktuella klassningen (tips == skäl);
				ett högre, osett nummer i en oförenlig bild förbrukas tyst. ]]
			if b.lage == "steady" and COACH_SKAL[b.coachSkal] and b.tips == b.coachSkal and coachCd <= 0 and not halsar
				and not pending and not fel then
				coachCd = COACH_CD.fel
				if Ugneta.valfriKommentar() then
					coachning = { forsokId = b.forsokId, ritt = ritt :: string, skal = b.coachSkal, kvar = COACH_CD.visa }
				end
			end
		end
	end
	sekvens = math.max(sekvens,b.sekvens or 0)
	if valt and (b.lage=="approach" or b.lage=="baseline" or b.lage=="riding"
		or b.lage=="halt1" or b.lage=="walk"
		or b.lage=="walk1" or b.lage=="trot" or b.lage=="walk2"
		or b.lage=="to_start" or b.lage=="route" or b.lage=="canter"
		or b.lage=="approach" or b.lage=="crossing" or b.lage=="exit") then
		local delmal = if typ == "serpentin" or vagTyp(typ) or typ == "halvvolt" or typ == "hornet" then b.delmal
			elseif typ == "markbom" then (if b.lage == "exit" then 2 elseif b.lage == "crossing" then 1 else 0)
			else nil
		visaGuide(b.referens, delmal)
	else rivGuide() end
end

local function skicka(op)
	if not ritt or (pending and op~="finish") then return end
	requestNr += 1
	local token, gen, id = requestNr, generation, ritt
	local typVid, valVid = typ, valGen
	if op~="sync" then sekvens += 1 end
	local seq = sekvens
	pending, pendingTid, fel = true, 0, nil
	--[[ C2: en ny begäran tar bort en stående hälsning (den gäller ett
		försök som inte längre är det enda möjliga). Tempocoachningen likaså,
		direkt (spärren och Färre rörs inte). ]]
	halsning = nil
	coachning = nil
	task.spawn(function()
		local transport, ok, reason, b = pcall(function()
			return Net.get("VoltLektion"):InvokeServer(id,op,seq,typVid)
		end)
		if gen~=generation or token~=requestNr or ritt~=id then return end
		pending = false
		if not transport then fel="network"; return end
		mottag(b)
		--[[ C2: STARTHÄLSNINGEN. Bara ett godtaget start/retry, för det försök
			svaret bär, när samma försök fortfarande är aktuellt och aktivt i den
			bild som hålls (en nyare push kan ha kommit först), och när försöket
			inte redan hälsats. Samma typ som begäran skickades med. ]]
		if ok == true and (op == "start" or op == "retry") and typ == typVid and valGen == valVid
			and type(b) == "table" and b.forsokId ~= nil and b.rittId == id and (b.typ or "volt") == typVid
			and bild ~= nil and bild.forsokId == b.forsokId and AKTIVA_LAGEN[bild.lage]
			and halsadForsok ~= b.forsokId then
			halsadForsok = b.forsokId
			if Ugneta.valfriKommentar() then
				halsning = { forsokId = b.forsokId, typ = typVid, ritt = id, kvar = HALSNING_S }
			end
		end
		if ok~=true then
			fel = if reason=="place" or reason=="pole" then reason elseif reason=="active" then "active"
				else "network"
		elseif op=="finish" then
			valt, fri, meny = false, true, nil; rivGuide()
		end
	end)
end

function V.valj(vald: string?)
	if not ritt then return end
	local ny = if vald == "halt" or vald == "overgang" or vald == "serpentin" or vald == "tempo"
		or vald == "vag_mitt" or vald == "vag_diag" or vald == "halvvolt" or vald == "galopp"
		or vald == "markbom" or vald == "hornet" then vald else "volt"
	if ny ~= typ then typ, bild = ny, nil; utanStreck = false; rivGuide() end
	halsning = nil
	valGen += 1
	coachning, coachForsok = nil, nil
	valt, fri, fel, meny = true, false, nil, nil
	Ugneta.dolj()
	skicka("sync")
end

-- Markbommens egna texter; gemensamma nycklar faller igenom.
local function markbomText(key): string?
	if key=="choose_markbom" then return Sprak.t("markbomlektion.choose") end
	if typ ~= "markbom" then return nil end
	if key=="start" then return Sprak.t("markbomlektion.start") end
	if key=="finish" then return Sprak.t("markbomlektion.finish") end
	if key=="intro" then return Sprak.t("markbomlektion.intro") end
	if key=="to_approach" then return Sprak.t("markbomlektion.to_approach") end
	if key=="walk_to_pole" then return Sprak.t("markbomlektion.walk_to_pole") end
	if key=="approach_longer" then return Sprak.t("markbomlektion.approach_longer") end
	if key=="over_pole" then return Sprak.t("markbomlektion.over_pole") end
	if key=="walk_on_after" then return Sprak.t("markbomlektion.walk_on_after") end
	if key=="walk_on" then return Sprak.t("markbomlektion.walk_on") end
	if key=="walk_only" then return Sprak.t("markbomlektion.walk_only") end
	if key=="off_line" then return Sprak.t("markbomlektion.off_line") end
	if key=="reverse" then return Sprak.t("markbomlektion.reverse") end
	if key=="beside_pole" then return Sprak.t("markbomlektion.beside_pole") end
	if key=="no_passage" then return Sprak.t("markbomlektion.no_passage") end
	if key=="wrong_direction" then return Sprak.t("markbomlektion.wrong_direction") end
	if key=="pole_missing" then return Sprak.t("markbomlektion.pole_missing") end
	if key=="pole" then return Sprak.t("markbomlektion.pole_missing") end
	if key=="unknown" then return Sprak.t("markbomlektion.unknown") end
	if key=="complete" then return Sprak.t("markbomlektion.complete") end
	if key=="timeout" then return Sprak.t("markbomlektion.timeout") end
	if key=="closed" then return Sprak.t("markbomlektion.closed") end
	if key=="place" then return Sprak.t("markbomlektion.place") end
	return nil
end

-- Galoppfattningens egna texter; gemensamma nycklar faller igenom.
local function galoppText(key): string?
	if key=="choose_galopp" then return Sprak.t("galopplektion.choose") end
	if typ ~= "galopp" then return nil end
	if key=="start" then return Sprak.t("galopplektion.start") end
	if key=="finish" then return Sprak.t("galopplektion.finish") end
	if key=="intro" then return Sprak.t("galopplektion.intro") end
	if key=="trot_on" then return Sprak.t("galopplektion.trot_on") end
	if key=="trot_first" then return Sprak.t("galopplektion.trot_first") end
	if key=="canter_at_k" then return Sprak.t("galopplektion.canter_at_k") end
	if key=="canter_outside" then return Sprak.t("galopplektion.canter_outside") end
	if key=="canter_on" then return Sprak.t("galopplektion.canter_on") end
	if key=="canter_longer" then return Sprak.t("galopplektion.canter_longer") end
	if key=="tired" then return Sprak.t("galopplektion.tired") end
	if key=="unknown" then return Sprak.t("galopplektion.unknown") end
	if key=="complete" then return Sprak.t("galopplektion.complete") end
	if key=="timeout" then return Sprak.t("galopplektion.timeout") end
	if key=="closed" then return Sprak.t("galopplektion.closed") end
	if key=="place" then return Sprak.t("galopplektion.place") end
	return nil
end

-- Halvvoltens egna texter; gemensamma nycklar faller igenom.
-- Genom hörnets egna texter; gemensamma nycklar faller igenom.
local function hornText(key): string?
	if key=="choose_hornet" then return Sprak.t("hornlektion.choose") end
	if key=="group_bojda" then return Sprak.t("lektionsval.bojda") end
	if typ ~= "hornet" then return nil end
	if key=="start" then return Sprak.t("hornlektion.start") end
	if key=="finish" then return Sprak.t("hornlektion.finish") end
	if key=="intro" then return Sprak.t("hornlektion.intro") end
	if key=="to_start" then return Sprak.t("hornlektion.to_start") end
	if key=="ride_in" then return Sprak.t("hornlektion.ride_in") end
	if key=="bend" then return Sprak.t("hornlektion.bend") end
	if key=="ride_out" then return Sprak.t("hornlektion.ride_out") end
	if key=="off_route" then return Sprak.t("hornlektion.off_route") end
	if key=="reverse" then return Sprak.t("hornlektion.reverse") end
	if key=="walk_or_trot" then return Sprak.t("hornlektion.walk_or_trot") end
	if key=="unknown" then return Sprak.t("hornlektion.unknown") end
	if key=="complete" then return Sprak.t("hornlektion.complete") end
	if key=="timeout" then return Sprak.t("hornlektion.timeout") end
	if key=="closed" then return Sprak.t("hornlektion.closed") end
	if key=="place" then return Sprak.t("hornlektion.place") end
	if key=="mindre_stod" then return Sprak.t("hornlektion.mindre_stod") end
	if key=="visa_vagen" then return Sprak.t("vaglektion.visa_vagen") end
	return nil
end

local function halvvoltText(key): string?
	if key=="choose_halvvolt" then return Sprak.t("halvvoltlektion.choose") end
	if typ ~= "halvvolt" then return nil end
	if key=="start" then return Sprak.t("halvvoltlektion.start") end
	if key=="finish" then return Sprak.t("halvvoltlektion.finish") end
	if key=="intro" then return Sprak.t("halvvoltlektion.intro") end
	if key=="to_start" then return Sprak.t("halvvoltlektion.to_start") end
	if key=="track" then return Sprak.t("halvvoltlektion.track") end
	if key=="half_circle" then return Sprak.t("halvvoltlektion.half_circle") end
	if key=="return" then return Sprak.t("halvvoltlektion.return") end
	if key=="to_end" then return Sprak.t("halvvoltlektion.to_end") end
	if key=="off_route" then return Sprak.t("halvvoltlektion.off_route") end
	if key=="reverse" then return Sprak.t("halvvoltlektion.reverse") end
	if key=="halt_moved" then return Sprak.t("halvvoltlektion.halt_moved") end
	if key=="walk_or_trot" then return Sprak.t("halvvoltlektion.walk_or_trot") end
	if key=="unknown" then return Sprak.t("halvvoltlektion.unknown") end
	if key=="complete" then return Sprak.t("halvvoltlektion.complete") end
	if key=="timeout" then return Sprak.t("halvvoltlektion.timeout") end
	if key=="closed" then return Sprak.t("halvvoltlektion.closed") end
	if key=="place" then return Sprak.t("halvvoltlektion.place") end
	if key=="mindre_stod" then return Sprak.t("halvvoltlektion.mindre_stod") end
	if key=="visa_vagen" then return Sprak.t("vaglektion.visa_vagen") end
	return nil
end

-- Valsidornas och ridvägarnas egna texter; gemensamma nycklar faller igenom.
local function vagText(key): string?
	if key=="group_gangart" then return Sprak.t("lektionsval.gangart") end
	if key=="group_vagar" then return Sprak.t("lektionsval.vagar") end
	if key=="back" then return Sprak.t("lektionsval.tillbaka") end
	if key=="pick" then return Sprak.t("lektionsval.valj") end
	if key=="choose_lesson" then return Sprak.t("lektionsval.oppna") end
	if key=="group_linjer" then return Sprak.t("lektionsval.linjer") end
	if key=="group_overgangar" then return Sprak.t("lektionsval.overgangar") end
	if key=="choose_vag_mitt" then return Sprak.t("vaglektion.choose_mitt") end
	if key=="choose_vag_diag" then return Sprak.t("vaglektion.choose_diag") end
	if not vagTyp(typ) then return nil end
	if key=="start" then return Sprak.t("vaglektion.start") end
	if key=="finish" then return Sprak.t("vaglektion.finish") end
	if key=="intro" then
		return Sprak.t(if typ=="vag_diag" then "vaglektion.intro_diag" else "vaglektion.intro_mitt")
	end
	if key=="to_start" then return Sprak.t("vaglektion.to_start") end
	if key=="ride_mitt" then return Sprak.t("vaglektion.ride_mitt") end
	if key=="ride_diag" then return Sprak.t("vaglektion.ride_diag") end
	if key=="to_end" then return Sprak.t("vaglektion.to_end") end
	if key=="off_route" then return Sprak.t("vaglektion.off_route") end
	if key=="reverse" then return Sprak.t("vaglektion.reverse") end
	if key=="walk_or_trot" then return Sprak.t("vaglektion.walk_or_trot") end
	if key=="utan_streck" then return Sprak.t("vaglektion.utan_streck") end
	if key=="visa_vagen" then return Sprak.t("vaglektion.visa_vagen") end
	if key=="unknown" then return Sprak.t("vaglektion.unknown") end
	if key=="complete" then return Sprak.t("vaglektion.complete") end
	if key=="timeout" then return Sprak.t("vaglektion.timeout") end
	if key=="closed" then return Sprak.t("vaglektion.closed") end
	if key=="place" then return Sprak.t("vaglektion.place") end
	return nil
end

-- Tempolektionens (jämn fart i skritt) egna texter; gemensamma nycklar faller igenom.
local function tempoText(key): string?
	if key=="choose_tempo" then return Sprak.t("tempolektion.choose") end
	if typ ~= "tempo" then return nil end
	if key=="start" then return Sprak.t("tempolektion.start") end
	if key=="finish" then return Sprak.t("tempolektion.finish") end
	if key=="intro" then return Sprak.t("tempolektion.intro") end
	if key=="walk_on" then return Sprak.t("tempolektion.walk_on") end
	if key=="keep_going" then return Sprak.t("tempolektion.keep_going") end
	if key=="too_slow" then return Sprak.t("tempolektion.too_slow") end
	if key=="too_fast" then return Sprak.t("tempolektion.too_fast") end
	if key=="steadier" then return Sprak.t("tempolektion.steadier") end
	if key=="walk_only" then return Sprak.t("tempolektion.walk_only") end
	if key=="stay_inside" then return Sprak.t("tempolektion.stay_inside") end
	if key=="unknown" then return Sprak.t("tempolektion.unknown") end
	if key=="complete" then return Sprak.t("tempolektion.complete") end
	if key=="timeout" then return Sprak.t("tempolektion.timeout") end
	if key=="closed" then return Sprak.t("tempolektion.closed") end
	if key=="place" then return Sprak.t("tempolektion.place") end
	return nil
end

-- Serpentinlektionens egna texter; gemensamma nycklar faller igenom.
local function serpentinText(key): string?
	if key=="choose_serpentin" then return Sprak.t("serpentinlektion.choose") end
	if typ ~= "serpentin" then return nil end
	if key=="start" then return Sprak.t("serpentinlektion.start") end
	if key=="finish" then return Sprak.t("serpentinlektion.finish") end
	if key=="intro" then return Sprak.t("serpentinlektion.intro") end
	if key=="to_start" then return Sprak.t("serpentinlektion.to_start") end
	if key=="loop1" then return Sprak.t("serpentinlektion.loop1") end
	if key=="loop2" then return Sprak.t("serpentinlektion.loop2") end
	if key=="loop3" then return Sprak.t("serpentinlektion.loop3") end
	if key=="to_end" then return Sprak.t("serpentinlektion.to_end") end
	if key=="off_route" then return Sprak.t("serpentinlektion.off_route") end
	if key=="reverse" then return Sprak.t("serpentinlektion.reverse") end
	if key=="walk_or_trot" then return Sprak.t("serpentinlektion.walk_or_trot") end
	if key=="unknown" then return Sprak.t("serpentinlektion.unknown") end
	if key=="complete" then return Sprak.t("serpentinlektion.complete") end
	if key=="timeout" then return Sprak.t("serpentinlektion.timeout") end
	if key=="closed" then return Sprak.t("serpentinlektion.closed") end
	if key=="place" then return Sprak.t("serpentinlektion.place") end
	return nil
end

-- Övergångslektionens egna texter; gemensamma nycklar faller igenom.
local function overgangText(key): string?
	if key=="choose_overgang" then return Sprak.t("overganglektion.choose") end
	if typ ~= "overgang" then return nil end
	if key=="start" then return Sprak.t("overganglektion.start") end
	if key=="finish" then return Sprak.t("overganglektion.finish") end
	if key=="intro" then return Sprak.t("overganglektion.intro") end
	if key=="walk_on" then return Sprak.t("overganglektion.walk_on") end
	if key=="walk_first" then return Sprak.t("overganglektion.walk_first") end
	if key=="trot_at_t1" then return Sprak.t("overganglektion.trot_at_t1") end
	if key=="trot_outside" then return Sprak.t("overganglektion.trot_outside") end
	if key=="trot_on" then return Sprak.t("overganglektion.trot_on") end
	if key=="trot_longer" then return Sprak.t("overganglektion.trot_longer") end
	if key=="walk_at_t2" then return Sprak.t("overganglektion.walk_at_t2") end
	if key=="walk_outside" then return Sprak.t("overganglektion.walk_outside") end
	if key=="walk_calm" then return Sprak.t("overganglektion.walk_calm") end
	if key=="tired" then return Sprak.t("overganglektion.tired") end
	if key=="walk_only" then return Sprak.t("overganglektion.walk_only") end
	if key=="trot_only" then return Sprak.t("overganglektion.trot_only") end
	if key=="unknown" then return Sprak.t("overganglektion.unknown") end
	if key=="complete" then return Sprak.t("overganglektion.complete") end
	if key=="timeout" then return Sprak.t("overganglektion.timeout") end
	if key=="closed" then return Sprak.t("overganglektion.closed") end
	if key=="place" then return Sprak.t("overganglektion.place") end
	return nil
end

-- Start/halt-lektionens egna texter; gemensamma nycklar faller igenom.
local function haltText(key): string?
	if key=="choose_halt" then return Sprak.t("haltlektion.choose") end
	if typ ~= "halt" then return nil end
	if key=="start" then return Sprak.t("haltlektion.start") end
	if key=="finish" then return Sprak.t("haltlektion.finish") end
	if key=="intro" then return Sprak.t("haltlektion.intro") end
	if key=="halt_first" then return Sprak.t("haltlektion.halt_first") end
	if key=="walk_on" then return Sprak.t("haltlektion.walk_on") end
	if key=="walk_only" then return Sprak.t("haltlektion.walk_only") end
	if key=="to_x" then return Sprak.t("haltlektion.to_x") end
	if key=="hold" then return Sprak.t("haltlektion.hold") end
	if key=="halt_outside" then return Sprak.t("haltlektion.halt_outside") end
	if key=="halt_at_x" then return Sprak.t("haltlektion.halt_at_x") end
	if key=="unknown" then return Sprak.t("haltlektion.unknown") end
	if key=="complete" then return Sprak.t("haltlektion.complete") end
	if key=="timeout" then return Sprak.t("haltlektion.timeout") end
	if key=="closed" then return Sprak.t("haltlektion.closed") end
	if key=="place" then return Sprak.t("haltlektion.place") end
	return nil
end

local function text(key)
	local mb = markbomText(key)
	if mb then return mb end
	local ga = galoppText(key)
	if ga then return ga end
	local ho = hornText(key)
	if ho then return ho end
	local hv = halvvoltText(key)
	if hv then return hv end
	local va = vagText(key)
	if va then return va end
	local te = tempoText(key)
	if te then return te end
	local sp = serpentinText(key)
	if sp then return sp end
	local o = overgangText(key)
	if o then return o end
	local h = haltText(key)
	if h then return h end
	if key=="choose" then return Sprak.t("voltlektion.choose") end
	--[[ C3 alternativ A (docs/FREE-PRACTICE-FRAMING-CONTRACT.md): det gamla 22 s-passet är
		fri träning med återspelning, inte "andra övningar" bredvid lektionerna. ]]
	if key=="lessons" then return Sprak.t("voltlektion.fri_traning") end
	if key=="start" then return Sprak.t("voltlektion.start") end
	if key=="retry" then return Sprak.t("voltlektion.retry") end
	if key=="finish" then return Sprak.t("voltlektion.finish") end
	if key=="sync" then return Sprak.t("voltlektion.sync") end
	if key=="intro" then return Sprak.t("voltlektion.intro") end
	if key=="approach" then return Sprak.t("voltlektion.approach") end
	if key=="ride" then return Sprak.t("voltlektion.ride") end
	if key=="line" then return Sprak.t("voltlektion.line") end
	if key=="unknown" then return Sprak.t("voltlektion.unknown") end
	if key=="complete" then return Sprak.t("voltlektion.complete") end
	if key=="timeout" then return Sprak.t("voltlektion.timeout") end
	if key=="closed" then return Sprak.t("voltlektion.closed") end
	if key=="pending" then return Sprak.t("voltlektion.pending") end
	if key=="place" then return Sprak.t("voltlektion.place") end
	if key=="active" then return Sprak.t("voltlektion.active") end
	return Sprak.t("voltlektion.network")
end

local function val(key, fn)
	local gen, id, token = generation, ritt, requestNr
	return { text=text(key), aktiv=true,
		skicka=function() if attached and gen==generation and id==ritt and token==requestNr then fn() end end }
end

--[[ C4: lektionens namnnyckel i menyn. ]]
local function valNyckel(typ: string): string
	return if typ == "volt" then "choose" else "choose_" .. typ
end

--[[ C4: ett lektionsval med minnets markering: "· klarad" när den är
	sparad, "· klarad nu" när den väntar på att sparas. ]]
local function valLektion(typ: string)
	local k = val(valNyckel(typ), function() V.valj(typ) end)
	local l = minne and minne.lektioner[typ]
	if l == "sparad" then k.text ..= Sprak.t("lektionsminne.markering.sparad")
	elseif l == "vantar" then k.text ..= Sprak.t("lektionsminne.markering.vantar") end
	--[[ R1: förslaget syns också där det faktiskt väljs. ]]
	if forslag() == typ then k.text ..= Sprak.t("lektionsminne.markering.forslag") end
	return k
end

--[[ R1: en gruppknapp som leder mot förslaget bär en markering. ]]
local function valGrupp(nyckel: string, grupp: string, fn: () -> ())
	local k = val(nyckel, fn)
	local typ = forslag()
	if typ and (MINNE_GRUPP[typ] == grupp or MINNE_UNDERGRUPP[typ] == grupp) then
		k.text ..= Sprak.t("lektionsminne.markering.forslag")
	end
	return k
end

--[[ R1: förslaget som en mening med var det finns, för ersättningssidorna
	(vars text faktiskt ritas). ]]
local function forslagsRad(): string?
	local typ, igen = forslag()
	if not typ then return nil end
	local namn = text(valNyckel(typ))
	local grupp = MINNE_GRUPP[typ]
	if grupp then
		return Sprak.t(if igen then "lektionsminne.igen_var" else "lektionsminne.forslag_var", namn,
			text(if grupp == "gangart" then "group_gangart" else "group_vagar"))
	end
	return Sprak.t(if igen then "lektionsminne.igen_rad" else "lektionsminne.forslag_rad", namn)
end

--[[ C4: sidans rad om minnet (okänd historik eller osparat), eller nil. ]]
local function minnesRad(): string?
	local m = minne
	if not m or m.historik ~= "betrodd" then return Sprak.t("lektionsminne.okand") end
	for _, l in m.lektioner do
		if l == "vantar" then return Sprak.t("lektionsminne.vantar_info") end
	end
	return nil
end

local function medMinne(t: string): string
	local r = minnesRad()
	return if r then (t .. " " .. r) else t
end

--[[ C4: förslagets knapp — samma valväg som menyn (V.valj), och Start
	krävs fortfarande. ]]
local function forslagsKnapp()
	local typ, igen = forslag()
	if not typ then return nil end
	--[[ R1: bunden till SITT förslag — har minnet ändrats sedan knappen
		ritades gör den ingenting (panelen ritas om med det nya). ]]
	local k = val(valNyckel(typ), function() if forslag() == typ then V.valj(typ) end end)
	k.text = Sprak.t(if igen then "lektionsminne.igen" else "lektionsminne.forslag", text(valNyckel(typ)))
	return k
end

function V.panel()
	if not attached or not ritt then return nil end
	if not valt then
		--[[ Högst fyra val per sida (Naromrades MAX_VAL): grupperna har
			högst tre lektioner plus Tillbaka. Gruppsidan ersätter Ugnetas
			egna kortknappar, så att inget val trängs ut. ]]
		-- Tillbaka leder alltid till toppnivån med de ursprungliga kortknapparna.
		--[[ C4: lektionsvalen bär minnets markering, och sidans text säger när
			historiken är okänd eller något ännu inte är sparat. Samma knappar,
			samma antal, samma Tillbaka. ]]
		if meny == "gangart" then
			return { ersatt=true, text=medMinne(text("pick")), ovning="", vantar=false, knappar={
				valLektion("halt"),
				valLektion("tempo"),
				valGrupp("group_overgangar", "overgangar", function() meny = "overgangar" end),
				val("back",function() meny = nil end) } }
		elseif meny == "overgangar" then
			-- Undergrupp: Tillbaka leder till Gångarter och fart.
			return { ersatt=true, text=medMinne(text("pick")), ovning="", vantar=false, knappar={
				valLektion("overgang"),
				valLektion("galopp"),
				val("back",function() meny = "gangart" end) } }
		elseif meny == "vagar" then
			--[[ Genom hörnet: Ridvägar får undergruppen Böjda vägar (serpentin,
				halvvolt, hörnet) bredvid Raka linjer och markbom — alla val finns
				kvar, fyra rader, serpentin och halvvolt en nivå längre ner. ]]
			return { ersatt=true, text=medMinne(text("pick")), ovning="", vantar=false, knappar={
				valGrupp("group_bojda", "bojda", function() meny = "bojda" end),
				valGrupp("group_linjer", "linjer", function() meny = "linjer" end),
				val("back",function() meny = nil end) } }
		elseif meny == "bojda" then
			-- Undergrupp: böjda vägar; Tillbaka leder till Ridvägar.
			return { ersatt=true, text=medMinne(text("pick")), ovning="", vantar=false, knappar={
				valLektion("serpentin"),
				valLektion("halvvolt"),
				valLektion("hornet"),
				val("back",function() meny = "vagar" end) } }
		elseif meny == "linjer" then
			-- Undergrupp: raka linjer och markbommen; Tillbaka leder till Ridvägar.
			return { ersatt=true, text=medMinne(text("pick")), ovning="", vantar=false, knappar={
				valLektion("vag_mitt"),
				valLektion("vag_diag"),
				valLektion("markbom"),
				val("back",function() meny = "vagar" end) } }
		elseif meny == "topp" then
			--[[ R1: den KOMPAKTA vägen (med Ugnetas kortknappar) landar här.
				Knapparna är desamma; texten — som ritas på en ersättningssida —
				säger förslaget och var det finns, och minnets rad. ]]
			local rad = forslagsRad()
			local t = medMinne(text("pick"))
			return { ersatt=true, text=if rad then (t .. " " .. rad) else t, ovning="", vantar=false, knappar={
				valLektion("volt"),
				valGrupp("group_gangart", "gangart", function() meny = "gangart" end),
				valGrupp("group_vagar", "vagar", function() meny = "vagar" end),
				val("back",function() meny = nil end) } }
		end
		local knappar = { valLektion("volt"),
			valGrupp("group_gangart", "gangart", function() meny = "gangart" end),
			valGrupp("group_vagar", "vagar", function() meny = "vagar" end) }
		local forslagsText: string? = nil
		if fri then
			table.insert(knappar,val("lessons",function()
				fri=false; if gaLektion then gaLektion() end
			end))
			--[[ C4: vid fri ridning är sidan full (fyra val); förslaget nämns i
				texten i stället för att tränga ut ett val. ]]
			--[[ R1: ersättningssida — texten ritas: förslaget med plats, och
				minnets rad (okänt/osparat). ]]
			local rad, minnesText = forslagsRad(), minnesRad()
			if rad or minnesText then
				forslagsText = table.concat({ rad or "", minnesText or "" }, if rad and minnesText then " " else "")
			end
		else
			--[[ C4: utan fri ridning finns en fjärde plats: ETT valfritt förslag. ]]
			local fk = forslagsKnapp()
			if fk then table.insert(knappar, fk) end
		end
		--[[ R1: bredvid Ugnetas 0..3 kortknappar ryms inte alltid tre val;
			då visar Ugneta den kompakta listan — en post som öppnar
			toppsidan. Vid fri ridning ersätts kortknapparna ändå. ]]
		return { ersatt=fri, knappar=knappar, text=forslagsText, vantar=false, ovning="",
			kompakt = if fri then nil else { val("choose_lesson",function() meny = "topp" end) } }
	end
	local b = bild or {lage="ready",progress=0,tips="approach"}
	local key = if pending then "pending" elseif fel then fel
		elseif b.lage=="ready" or b.lage=="closed" then "intro"
		else b.tips
	local txt = text(key)
	--[[ C1 (docs/CIRCLE-LINE-ADVICE-CONTRACT.md): nollställdes volten för att
		en punkt låg för långt från linjen, och vet servern åt vilket håll, blir
		sidans text ETT konkret råd för just det hållet. Annars den vanliga. ]]
	if key == "line" and typ == "volt" then
		if b.linjeSida == "ut" then txt = Sprak.t("voltlektion.line_ut")
		elseif b.linjeSida == "in" then txt = Sprak.t("voltlektion.line_in") end
	end
	--[[ C1 (docs/TRANSITION-TIMING-ADVICE-CONTRACT.md): kom övergången före
		eller efter sin ring, och vet servern vilket, blir texten ETT råd om
		när den ska be om övergången. Annars den vanliga. ]]
	if typ == "overgang" and key == "trot_outside" then
		if b.malSida == "fore" then txt = Sprak.t("overganglektion.trot_early")
		elseif b.malSida == "efter" then txt = Sprak.t("overganglektion.trot_late") end
	elseif typ == "overgang" and key == "walk_outside" then
		if b.malSida == "fore" then txt = Sprak.t("overganglektion.walk_early")
		elseif b.malSida == "efter" then txt = Sprak.t("overganglektion.walk_late") end
	elseif typ == "galopp" and key == "canter_outside" then
		-- C1 (docs/CANTER-TIMING-ADVICE-CONTRACT.md): samma regel för galoppfattningen vid K.
		if b.malSida == "fore" then txt = Sprak.t("galopplektion.canter_early")
		elseif b.malSida == "efter" then txt = Sprak.t("galopplektion.canter_late") end
	end
	--[[ Slutet på en övning: Ugnetas sammanfattning av JUST det här försökets
		frysta resultat och ett nästa steg (docs/LESSON-FEEDBACK-CONTRACT.md). ]]
	if not pending and not fel then
		local at = Aterkoppling.text(b, { typ = typ, ritt = ritt })
		if at then txt = at end
	end
	--[[ C2: starthälsningen först i sidans egen text — bara för exakt det
		försöket, i samma typ och ritt, i ett aktivt läge och utan vänta/fel.
		Stämmer något inte längre tas den bort för gott. Uppgiften och
		framstegen står kvar efter den. ]]
	--[[ R1: Inga tar bort hälsningen även här (en läsning av valet, inte
		`valfriKommentar` — Färre-räknaren rörs inte av en omritning). ]]
	if halsning and Installning.kommentarer() == "inga" then halsning = nil end
	if coachning and Installning.kommentarer() == "inga" then coachning = nil end
	--[[ Tempocoachningen: bara för exakt det försöket, i steady, utan
		vänta/fel och utan en synlig hälsning (hälsningen vinner). ]]
	local cg = coachning
	if cg then
		if cg.ritt == ritt and typ == "tempo" and b.forsokId == cg.forsokId and b.lage == "steady"
			and b.tips == cg.skal and not pending and not fel and halsning == nil then
			txt = Sprak.t("tempocoach." .. cg.skal) .. " " .. txt
		elseif pending or fel or cg.ritt ~= ritt or typ ~= "tempo" or b.forsokId ~= cg.forsokId
			or b.lage ~= "steady" or b.tips ~= cg.skal then
			coachning = nil
		end
	end
	local h = halsning
	if h then
		if h.ritt == ritt and h.typ == typ and b.forsokId == h.forsokId and AKTIVA_LAGEN[b.lage]
			and not pending and not fel then
			txt = Sprak.t("halsning." .. h.typ) .. " " .. txt
		elseif pending or fel or h.ritt ~= ritt or h.typ ~= typ or b.forsokId ~= h.forsokId
			or not AKTIVA_LAGEN[b.lage] then
			halsning = nil
		end
	end
	if (b.lage=="riding" or b.lage=="halt1" or b.lage=="walk" or b.lage=="walk1"
		or b.lage=="trot" or b.lage=="walk2" or b.lage=="route" or b.lage=="steady"
		or b.lage=="canter" or b.lage=="approach" or b.lage=="crossing" or b.lage=="exit")
		and not pending and not fel then
		txt ..= " "..tostring(b.progress).."%"
	end
	local knappar = {}
	if not pending then
		if fel=="network" then table.insert(knappar,val("sync",function() skicka("sync") end))
		elseif b.lage=="ready" or b.lage=="closed" then
			table.insert(knappar,val("start",function() skicka("start") end))
		elseif b.lage=="complete" or b.lage=="timeout" then
			table.insert(knappar,val("retry",function() skicka("retry") end))
		end
	end
	--[[ C3 (docs/ROUTE-LESS-GUIDANCE-CONTRACT.md): ridvägarnas egna val. "Rid utan
		streck" bara när lektionen är klarad enligt minnet; "Visa vägen" alltid när
		mindre vägvisning är på. Lokalt — inget skickas till servern. ]]
	--[[ Hörnet (docs/CORNER-LESS-GUIDANCE-CONTRACT.md): samma val med egen etikett —
		bågens streck står kvar, så "utan streck" vore osant där. ]]
	if (vagTyp(typ) or typ == "hornet" or typ == "halvvolt") and (utanStreck or klarad(typ)) then
		local nyckel = if utanStreck then "visa_vagen"
			elseif typ == "hornet" or typ == "halvvolt" then "mindre_stod" else "utan_streck"
		table.insert(knappar, val(nyckel, function()
			utanStreck = not utanStreck
			local visad = guide ~= nil
			rivGuide()
			if visad and bild then visaGuide(bild.referens, bild.delmal) end
		end))
	end
	table.insert(knappar,val("finish",function() skicka("finish") end))
	return { ersatt=true, knappar=knappar, text=txt, ovning=txt, vantar=false }
end

function V.start(marke, legacy)
	local samma = ritt==marke
	generation += 1; requestNr += 1
	--[[ C2: återkoppling eller ny ritt: en hälsning visas aldrig igen. I en
		NY ritt glöms även det senast hälsade försöket (ritten avgränsar det). ]]
	halsning = nil
	valGen += 1
	--[[ Återkoppling eller ny ritt: coachningen bort och baslinjen om (nästa
		bild sätter den, utan att visa något). ]]
	coachning, coachForsok = nil, nil
	if not samma then halsadForsok = nil end
	if not installLyssnare then
		installLyssnare = Installning.vidByte(function()
			if Installning.kommentarer() == "inga" then halsning = nil; coachning = nil end
		end)
	end
	if not samma then valt,fri,bild,sekvens,meny=false,false,nil,0,nil; utanStreck=false end
	ritt,gaLektion,pending,fel=marke,legacy,false,nil
	attached = true
	if not listener then
		listener=Net.get("VoltLektionSync").OnClientEvent:Connect(mottag)
	end
	--[[ C4: minnet är spelarens eget och gäller över ritter; det hämtas vid
		varje start (läsning bara) och följer serverns push. EN lyssnare. ]]
	if not minneLyssnare then
		minneLyssnare = Net.get("LektionsMinneSync").OnClientEvent:Connect(taEmotMinne)
	end
	task.spawn(function()
		local ok, p = pcall(function() return Net.get("LektionsMinne"):InvokeServer("sync") end)
		if ok then taEmotMinne(p) end
	end)
	if valt then skicka("sync") end
end

function V.steg(dt)
	local steglangd = if type(dt) == "number" and dt == dt and dt > 0 then math.min(dt, 1) else 0
	if coachCd > 0 then coachCd -= steglangd end
	local cg = coachning
	if cg then
		cg.kvar -= steglangd
		if cg.kvar <= 0 then coachning = nil end
	end
	local h = halsning
	if h then
		h.kvar -= (if type(dt) == "number" and dt == dt and dt > 0 then math.min(dt, 1) else 0)
		if h.kvar <= 0 then halsning = nil end
	end
	if pending then
		pendingTid += dt
		if pendingTid>=10 then
			pending=false; requestNr+=1; fel="network"
		end
	end
end

function V.tarOver(): boolean return attached and (valt or fri) end
--[[ Provkrok: minnets projektion som klienten håller. ]]
function V._minneForProv(): any return minne end
--[[ Provkrok: hälsningens läge. ]]
function V._halsningForProv(): any return halsning end
function V._coachningForProv(): any return coachning end
function V.lektion(): boolean return attached and valt end

function V.avbryt()
	-- Keep selection only for reattachment to this SAME accepted ride.
	generation+=1; requestNr+=1; pending=false; attached=false; rivGuide()
	utanStreck = false
	halsning = nil
	valGen += 1
	coachning, coachForsok = nil, nil
	Ugneta.satLektionsVal(nil)
end

return V
