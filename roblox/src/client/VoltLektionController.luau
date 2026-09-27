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
-- Vald lektion: "volt" (voltlektionen) eller "halt" (start/halt vid X).
local typ = "volt"
local guideTyp: string? = nil

local function rivGuide()
	if guide then guide:Destroy() end
	guide, guideRef = nil, nil
end

local function visaGuide(ref)
	if not ref or not ref.plats then rivGuide(); return end
	if guideRef and guideRef.ramId == ref.ramId and guideTyp == typ then return end
	rivGuide()
	local m = Instance.new("Model"); m.Name = "Voltguide"
	local p = ref.plats
	-- Volt: dashes fill the allowed inner band. Halt: a small ring marks the
	-- stopping zone at X. Each whole dash stays within the arena.
	local radie = if typ == "halt" then ref.radie else ref.radie - 1
	local antal = if typ == "halt" then 16 else 72
	for i = 0, antal - 1 do
		local a = 2 * math.pi * i / antal
		local pos = Plats.tillVarld(p, Vector3.new(ref.u + radie*math.cos(a),
			0.035, ref.v + radie*math.sin(a)))
		local half = (if typ == "halt" then 0.3 else 0.8) * p.studsPerMeter
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
	m.Parent = workspace; guide, guideRef, guideTyp = m, ref, typ
end

local function mottag(b)
	if not attached or not ritt or type(b)~="table" or b.rittId~=ritt or type(b.revision)~="number" then return end
	if (b.typ or "volt") ~= typ then return end
	if bild and b.revision < bild.revision then return end
	bild = b
	sekvens = math.max(sekvens,b.sekvens or 0)
	if valt and (b.lage=="approach" or b.lage=="baseline" or b.lage=="riding"
		or b.lage=="halt1" or b.lage=="walk") then
		visaGuide(b.referens)
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
	local ny = if vald == "halt" then "halt" else "volt"
	if ny ~= typ then typ, bild = ny, nil; rivGuide() end
	valt, fri, fel = true, false, nil
	Ugneta.dolj()
	skicka("sync")
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
			val("choose_halt",function() V.valj("halt") end) }
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
	if (b.lage=="riding" or b.lage=="halt1" or b.lage=="walk") and not pending and not fel then
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
