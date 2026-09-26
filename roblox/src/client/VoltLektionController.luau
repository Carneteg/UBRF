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

local function rivGuide()
	if guide then guide:Destroy() end
	guide, guideRef = nil, nil
end

local function visaGuide(ref)
	if not ref or not ref.plats then rivGuide(); return end
	if guideRef and guideRef.ramId == ref.ramId then return end
	rivGuide()
	local m = Instance.new("Model"); m.Name = "Voltguide"
	local p = ref.plats
	-- Dashes fill the allowed inner band; each whole dash stays within the arena.
	for i = 0, 71 do
		local a = 2 * math.pi * i / 72
		local pos = Plats.tillVarld(p, Vector3.new(ref.u + (ref.radie-1)*math.cos(a),
			0.035, ref.v + (ref.radie-1)*math.sin(a)))
		local half = 0.8 * p.studsPerMeter
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
	m.Parent = workspace; guide, guideRef = m, ref
end

local function mottag(b)
	if not attached or not ritt or type(b)~="table" or b.rittId~=ritt or type(b.revision)~="number" then return end
	if bild and b.revision < bild.revision then return end
	bild = b
	sekvens = math.max(sekvens,b.sekvens or 0)
	if valt and (b.lage=="approach" or b.lage=="baseline" or b.lage=="riding") then
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
			return Net.get("VoltLektion"):InvokeServer(id,op,seq)
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

function V.valj()
	if not ritt then return end
	valt, fri, fel = true, false, nil
	Ugneta.dolj()
	skicka("sync")
end

local function val(key, fn)
	local gen, id, token = generation, ritt, requestNr
	return { text=Sprak.t("voltlektion."..key), aktiv=true,
		skicka=function() if attached and gen==generation and id==ritt and token==requestNr then fn() end end }
end

function V.panel()
	if not attached or not ritt then return nil end
	if not valt then
		local knappar = { val("choose",V.valj) }
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
	local txt = Sprak.t("voltlektion."..key)
	if b.lage=="riding" and not pending and not fel then txt ..= " "..tostring(b.progress).."%" end
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
