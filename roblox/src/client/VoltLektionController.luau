--!strict
-- Presentation of server circle evidence, never a client-side assessment.
local Net = require(game:GetService("ReplicatedStorage").HorseCore.Networking)
local Sprak = require(game:GetService("ReplicatedStorage").HorseCore.Sprak)
local Plats = require(game:GetService("ReplicatedStorage").HorseCore.Ridhusplats)
local Ugneta = require(script.Parent.UgnetaController)
local Aterkoppling = require(script.Parent.LektionsAterkoppling)
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

local function rivGuide()
	if guide then guide:Destroy() end
	guide, guideRef, guideDel = nil, nil, nil
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
local function vagGuide(m, ref, delmal)
	local p = ref.plats
	local function lokalt(u, v) return Plats.tillVarld(p, Vector3.new(u, 0.035, v)) end
	local du, dv = (ref.u1 - ref.u0) / ref.langd, (ref.v1 - ref.v0) / ref.langd
	local riktning = lokalt(ref.u0 + du, ref.v0 + dv) - lokalt(ref.u0, ref.v0)
	local korsVek = lokalt(ref.u0 + dv, ref.v0 - du) - lokalt(ref.u0, ref.v0)
	local ridning = delmal ~= nil and delmal >= 1
	local antal = math.max(2, math.floor(ref.langd / 1.5))
	for i = 1, antal - 1 do
		local t = ref.langd * i / antal
		local pos = lokalt(ref.u0 + du * t, ref.v0 + dv * t)
		streck(m, p, pos, riktning, 0.45 * p.studsPerMeter, ridning)
	end
	-- Chevrons every 6 m point from start to end.
	local t = 6
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
local function halvvoltGuide(m, ref, delmal)
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
	rak(ref.uT, ref.p0v, ref.uT, ref.t1v, delmal == 1)
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

local function vagTyp(t: string?): boolean
	return t == "vag_mitt" or t == "vag_diag"
end

local function visaGuide(ref, delmal)
	if not ref or not ref.plats then rivGuide(); return end
	if guideRef and guideRef.ramId == ref.ramId and guideRef.nyckel == ref.nyckel and guideTyp == typ
		and guideDel == delmal then return end
	rivGuide()
	local m = Instance.new("Model"); m.Name = "Voltguide"
	if typ == "serpentin" or vagTyp(typ) or typ == "halvvolt" or typ == "markbom" then
		if typ == "serpentin" then serpentinGuide(m, ref, delmal)
		elseif typ == "halvvolt" then halvvoltGuide(m, ref, delmal)
		elseif typ == "markbom" then markbomGuide(m, ref, delmal)
		else vagGuide(m, ref, delmal) end
		m.Parent = workspace; guide, guideRef, guideTyp, guideDel = m, ref, typ, delmal
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
	m.Parent = workspace; guide, guideRef, guideTyp = m, ref, typ
end

local function mottag(b)
	if not attached or not ritt or type(b)~="table" or b.rittId~=ritt or type(b.revision)~="number" then return end
	if (b.typ or "volt") ~= typ then return end
	if bild and b.revision < bild.revision then return end
	bild = b
	sekvens = math.max(sekvens,b.sekvens or 0)
	if valt and (b.lage=="approach" or b.lage=="baseline" or b.lage=="riding"
		or b.lage=="halt1" or b.lage=="walk"
		or b.lage=="walk1" or b.lage=="trot" or b.lage=="walk2"
		or b.lage=="to_start" or b.lage=="route" or b.lage=="canter"
		or b.lage=="approach" or b.lage=="crossing" or b.lage=="exit") then
		local delmal = if typ == "serpentin" or vagTyp(typ) or typ == "halvvolt" then b.delmal
			elseif typ == "markbom" then (if b.lage == "exit" then 2 elseif b.lage == "crossing" then 1 else 0)
			else nil
		visaGuide(b.referens, delmal)
	else rivGuide() end
end

local function skicka(op)
	if not ritt or (pending and op~="finish") then return end
	requestNr += 1
	local token, gen, id = requestNr, generation, ritt
	if op~="sync" then sekvens += 1 end
	local seq = sekvens
	pending, pendingTid, fel = true, 0, nil
	task.spawn(function()
		local transport, ok, reason, b = pcall(function()
			return Net.get("VoltLektion"):InvokeServer(id,op,seq,typ)
		end)
		if gen~=generation or token~=requestNr or ritt~=id then return end
		pending = false
		if not transport then fel="network"; return end
		mottag(b)
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
		or vald == "markbom" then vald else "volt"
	if ny ~= typ then typ, bild = ny, nil; rivGuide() end
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
	if key=="lessons" then return Sprak.t("voltlektion.lessons") end
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

function V.panel()
	if not attached or not ritt then return nil end
	if not valt then
		--[[ Högst fyra val per sida (Naromrades MAX_VAL): grupperna har
			högst tre lektioner plus Tillbaka. Gruppsidan ersätter Ugnetas
			egna kortknappar, så att inget val trängs ut. ]]
		-- Tillbaka leder alltid till toppnivån med de ursprungliga kortknapparna.
		if meny == "gangart" then
			return { ersatt=true, text=text("pick"), ovning="", vantar=false, knappar={
				val("choose_halt",function() V.valj("halt") end),
				val("choose_tempo",function() V.valj("tempo") end),
				val("group_overgangar",function() meny = "overgangar" end),
				val("back",function() meny = nil end) } }
		elseif meny == "overgangar" then
			-- Undergrupp: Tillbaka leder till Gångarter och fart.
			return { ersatt=true, text=text("pick"), ovning="", vantar=false, knappar={
				val("choose_overgang",function() V.valj("overgang") end),
				val("choose_galopp",function() V.valj("galopp") end),
				val("back",function() meny = "gangart" end) } }
		elseif meny == "vagar" then
			return { ersatt=true, text=text("pick"), ovning="", vantar=false, knappar={
				val("choose_serpentin",function() V.valj("serpentin") end),
				val("choose_halvvolt",function() V.valj("halvvolt") end),
				val("group_linjer",function() meny = "linjer" end),
				val("back",function() meny = nil end) } }
		elseif meny == "linjer" then
			-- Undergrupp: raka linjer och markbommen; Tillbaka leder till Ridvägar.
			return { ersatt=true, text=text("pick"), ovning="", vantar=false, knappar={
				val("choose_vag_mitt",function() V.valj("vag_mitt") end),
				val("choose_vag_diag",function() V.valj("vag_diag") end),
				val("choose_markbom",function() V.valj("markbom") end),
				val("back",function() meny = "vagar" end) } }
		elseif meny == "topp" then
			return { ersatt=true, text=text("pick"), ovning="", vantar=false, knappar={
				val("choose",function() V.valj("volt") end),
				val("group_gangart",function() meny = "gangart" end),
				val("group_vagar",function() meny = "vagar" end),
				val("back",function() meny = nil end) } }
		end
		local knappar = { val("choose",function() V.valj("volt") end),
			val("group_gangart",function() meny = "gangart" end),
			val("group_vagar",function() meny = "vagar" end) }
		if fri then
			table.insert(knappar,val("lessons",function()
				fri=false; if gaLektion then gaLektion() end
			end))
		end
		--[[ R1: bredvid Ugnetas 0..3 kortknappar ryms inte alltid tre val;
			då visar Ugneta den kompakta listan — en post som öppnar
			toppsidan. Vid fri ridning ersätts kortknapparna ändå. ]]
		return { ersatt=fri, knappar=knappar, text=nil, vantar=false, ovning="",
			kompakt = if fri then nil else { val("choose_lesson",function() meny = "topp" end) } }
	end
	local b = bild or {lage="ready",progress=0,tips="approach"}
	local key = if pending then "pending" elseif fel then fel
		elseif b.lage=="ready" or b.lage=="closed" then "intro"
		else b.tips
	local txt = text(key)
	--[[ Slutet på en övning: Ugnetas sammanfattning av JUST det här försökets
		frysta resultat och ett nästa steg (docs/LESSON-FEEDBACK-CONTRACT.md). ]]
	if not pending and not fel then
		local at = Aterkoppling.text(b, { typ = typ, ritt = ritt })
		if at then txt = at end
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
	table.insert(knappar,val("finish",function() skicka("finish") end))
	return { ersatt=true, knappar=knappar, text=txt, ovning=txt, vantar=false }
end

function V.start(marke, legacy)
	local samma = ritt==marke
	generation += 1; requestNr += 1
	if not samma then valt,fri,bild,sekvens,meny=false,false,nil,0,nil end
	ritt,gaLektion,pending,fel=marke,legacy,false,nil
	attached = true
	if not listener then
		listener=Net.get("VoltLektionSync").OnClientEvent:Connect(mottag)
	end
	if valt then skicka("sync") end
end

function V.steg(dt)
	if pending then
		pendingTid += dt
		if pendingTid>=10 then
			pending=false; requestNr+=1; fel="network"
		end
	end
end

function V.tarOver(): boolean return attached and (valt or fri) end
function V.lektion(): boolean return attached and valt end

function V.avbryt()
	-- Keep selection only for reattachment to this SAME accepted ride.
	generation+=1; requestNr+=1; pending=false; attached=false; rivGuide()
	Ugneta.satLektionsVal(nil)
end

return V
