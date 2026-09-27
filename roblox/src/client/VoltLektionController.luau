--!strict
-- Presentation of server circle evidence, never a client-side assessment.
local Net = require(game:GetService("ReplicatedStorage").HorseCore.Networking)
local Sprak = require(game:GetService("ReplicatedStorage").HorseCore.Sprak)
local Plats = require(game:GetService("ReplicatedStorage").HorseCore.Ridhusplats)
local Ugneta = require(script.Parent.UgnetaController)
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
-- "tempo" (jämn fart i skritt; ingen guide).
local typ = "volt"
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

local function visaGuide(ref, delmal)
	if not ref or not ref.plats then rivGuide(); return end
	if guideRef and guideRef.ramId == ref.ramId and guideTyp == typ and guideDel == delmal then return end
	rivGuide()
	local m = Instance.new("Model"); m.Name = "Voltguide"
	if typ == "serpentin" then
		serpentinGuide(m, ref, delmal)
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
		or b.lage=="to_start" or b.lage=="route") then
		visaGuide(b.referens, if typ == "serpentin" then b.delmal else nil)
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
			fel = if reason=="place" then "place" elseif reason=="active" then "active" else "network"
		elseif op=="finish" then
			valt, fri = false, true; rivGuide()
		end
	end)
end

function V.valj(vald: string?)
	if not ritt then return end
	local ny = if vald == "halt" or vald == "overgang" or vald == "serpentin" or vald == "tempo"
		then vald else "volt"
	if ny ~= typ then typ, bild = ny, nil; rivGuide() end
	valt, fri, fel = true, false, nil
	Ugneta.dolj()
	skicka("sync")
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
		local knappar = { val("choose",function() V.valj("volt") end),
			val("choose_halt",function() V.valj("halt") end),
			val("choose_overgang",function() V.valj("overgang") end),
			val("choose_serpentin",function() V.valj("serpentin") end),
			val("choose_tempo",function() V.valj("tempo") end) }
		if fri then
			table.insert(knappar,val("lessons",function()
				fri=false; if gaLektion then gaLektion() end
			end))
		end
		return { ersatt=fri, knappar=knappar, text=nil, vantar=false, ovning="" }
	end
	local b = bild or {lage="ready",progress=0,tips="approach"}
	local key = if pending then "pending" elseif fel then fel
		elseif b.lage=="ready" or b.lage=="closed" then "intro"
		else b.tips
	local txt = text(key)
	if (b.lage=="riding" or b.lage=="halt1" or b.lage=="walk" or b.lage=="walk1"
		or b.lage=="trot" or b.lage=="walk2" or b.lage=="route" or b.lage=="steady")
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
	if not samma then valt,fri,bild,sekvens=false,false,nil,0 end
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
