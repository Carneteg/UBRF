--!nostrict
-- BANK_ONLY: actual HorseService and built arena, no live save/engine.
local fails, total = 0, 0
local function check(name, yes)
	total += 1
	if not yes then fails += 1 end
	print((if yes then "  OK   " else "  FEL  ") .. name)
end
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local Tags = game:GetService("CollectionService")
local vec = Vector3.new
local RP = assert(Ridhusplats.los(workspace:FindFirstChild("Anläggning"):FindFirstChild("UBRF")))
Tags:nollstall(); Run._server = true; Run.Heartbeat:nollstall()
HorseService.setMountGate(nil); HorseService.start()
local writes = __datastore.forsok and __datastore.forsok.skriv or 0
local function player(id)
	local c = Instance.new("Model")
	local root = Instance.new("Part"); root.Name = "HumanoidRootPart"; root.Size = vec(2,2,1); root.Parent = c
	local h = Instance.new("Humanoid"); h.Name = "Humanoid"; h.Parent = c
	return { UserId = id, Name = "Tester" .. id, Character = c,
		CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }
end
local p, other = Players.LocalPlayer, player(912)
p.Character = player(911).Character
Players._spelare = {p, other}
local horse = HastRigg.bygg("circle_test", "Circle test", CFrame.new(Ridhusplats.tillVarld(RP, vec(0, 0, 2))))
horse.Parent = workspace; Tags:AddTag(horse, "Horse")
local s = HorseService.sessionFor(horse)
local function point(u,v)
	local a = Ridhusplats.tillVarld(RP, vec(u,0,v))
	return vec(a.X,s.rig.root.Position.Y,a.Z)
end
local function step(u,v,dt)
	local a = point(u,v); s.rig.root.CFrame = CFrame.new(a); s.rig.root.Position = a
	s.energi = 1; Run.Heartbeat:Fire(dt or 0.25)
end
local function mount()
	step(0,2)
	local a = point(0,2) + vec(6,0,0)
	local root = p.Character:FindFirstChild("HumanoidRootPart")
	root.CFrame = CFrame.new(a); root.Position = a
	local ok, reason, id = HorseService.tryMount(p,horse)
	assert(ok, tostring(reason)); step(0,2); step(0,2)
	return id
end
local id = mount()
local function request(op, seq) return HorseService.voltLektionsBegaran(p,id,op,seq) end
local function image() local ok,_,b = request("sync"); assert(ok); return b end
local function approach()
	for v=3,20 do step(0,v) end
	step(0,20); step(0,20); step(0,20)
end
local function circle(sign, radius)
	for i=1,76 do
		local a = -math.pi/2 + sign*2*math.pi*i/72
		step(radius*math.cos(a),30+radius*math.sin(a))
	end
end
check("no attempt on mounting", RidForsok.aktivt(id)==nil)
check("wrong player rejected", HorseService.voltLektionsBegaran(other,id,"start",1)==false)
check("unknown operation rejected", request("award",1)==false)
local ok,_,b = request("start",1)
check("start at A accepted in approach", ok and b.lage=="approach")
local first = b.forsokId
local before = HorseService.volt(id)
local _,_,dup = request("start",1)
check("duplicate start same id and no split", dup.forsokId==first and HorseService.volt(id)==before)
check("same sequence different operation rejected", request("finish",1)==false)
approach()
check("arrival arms once and reaches riding", image().lage=="riding")
circle(1,9)
local done = image()
check("approach then circle succeeds", done.lage=="complete")
check("completion not cancellation", HorseService.forsok(first).orsak=="slutford")
check("lifecycle is not judgement", HorseService.forsok(first).bedomning=="ingen")
local frozen = done.resultat
circle(1,9)
check("outcome immutable after later riding", image().resultat==frozen)
check("retry creates new attempt", select(3,request("retry",2)).forsokId~=first)
-- Recover at a known point without borrowing the previous turn.
step(0,20,5); step(0,20); step(0,20); step(0,20)
for i=1,25 do local a=-math.pi/2-2*math.pi*i/72; step(9*math.cos(a),30+9*math.sin(a)) end
check("partial circle never passes", image().lage~="complete")
for i=26,76 do local a=-math.pi/2-2*math.pi*i/72; step(9*math.cos(a),30+9*math.sin(a)) end
check("opposite direction succeeds", image().lage=="complete")
request("retry",3)
for i=1,12 do
	step(0,30,5); step(0,30); step(0,20,5); step(0,20); step(0,20)
end
step(0,20); step(0,20); step(0,20)
circle(1,9)
check("fresh circle after more than8 discarded sections succeeds", image().lage=="complete")
request("retry",4)
local active = image().forsokId
request("finish",5)
check("finish cancels active attempt", HorseService.forsok(active).orsak=="avbrutet")
check("finish exits lesson", image().lage=="closed")
circle(1,9)
check("cancelled attempt never upgraded", HorseService.forsok(active).orsak=="avbrutet")
check("stale ride rejected", HorseService.voltLektionsBegaran(p,"wrong","start",9)==false)
for _, seq in ipairs({0, -1, 1.5, math.huge, 0/0, 2147483648}) do
	check("invalid sequence rejected", request("start",seq)==false)
end
check("malformed ride rejected", HorseService.voltLektionsBegaran(p,{},"start",9)==false)
check("oversized ride rejected", HorseService.voltLektionsBegaran(p,string.rep("x",129),"start",9)==false)

step(0,20,5); step(0,20)
request("start",6)
step(0,20); step(0,20); step(0,20)
local armed = HorseService.volt(id)
check("active start rejected", request("start",7)==false)
check("rejected start does not split current arm", HorseService.volt(id)==armed)
for i=1,36 do local a=-math.pi/2+2*math.pi*i/72; step(9*math.cos(a),30+9*math.sin(a)) end
request("finish",8)
request("start",9)
for i=37,76 do local a=-math.pi/2+2*math.pi*i/72; step(9*math.cos(a),30+9*math.sin(a)) end
check("pre-start half circle plus remainder cannot pass", image().lage~="complete")
for _=1,100 do step(0,20) end
check("stationary and legacy22 seconds cannot pass", image().lage~="complete")
local timed = image().forsokId
-- Supply exact wall-clock boundary to the actual evaluator, not an artificial sleep.
VoltLektion.steg(s.voltLektion,s.voltLektion.deadline)
check("deadline equality times out", image().lage=="timeout" and HorseService.forsok(timed).orsak=="tidsgrans")
request("retry",10)
check("retry deadline reset only for new attempt", image().lage=="approach")
local deadline = s.voltLektion.deadline
step(0,30,5); step(0,20,5); step(0,20); step(0,20)
check("recovery preserves deadline", s.voltLektion.deadline==deadline)
local _,_,original = request("finish",11)
for seq=12,32 do request("finish",seq) end
check("request response retention bounded", #s.voltLektion.ordning==16)
check("evicted old request rejected", request("start",6)==false)
check("retained duplicate still exact response", select(3,request("finish",32))==s.voltLektion.svar[32].bild)

local sequence=32
local function beginAt(v)
	sequence+=1; request("finish",sequence)
	step(0,v,5); step(0,v)
	sequence+=1; assert(request("start",sequence))
	step(0,v)
end
beginAt(22.001)
check("outside arming band does not arm", image().lage=="approach")
step(0,22)
check("arming band equality arms", image().lage=="baseline")
step(0,22)
check("next fresh sample only establishes baseline", image().lage=="riding" and HorseService.volt(id).pagar==nil)
step(0,22)
check("insufficient aggregates are not perfect metrics", HorseService.volt(id).pagar.medelAvvikelse==nil
	and image().lage~="complete")
step(0,23); step(0,24)
check("point deviation equality4 remains armed", image().lage=="riding")
step(0,24.001)
check("outward endpoint invalidates even with insufficient midpoint metrics", image().lage=="approach")
step(0,20); step(0,20); step(0,20)
circle(1,9)
check("endpoint excursion recovers without Retry", image().lage=="complete")
beginAt(20)
step(0,20); step(0,20)
for i=1,30 do local a=-math.pi/2+2*math.pi*i/72; step(9*math.cos(a),30+9*math.sin(a)) end
local reverseArm=s.voltLektion.armAfter
for i=29,15,-1 do local a=-math.pi/2+2*math.pi*i/72; step(9*math.cos(a),30+9*math.sin(a)) end
check("reverse arc clears original arm", s.voltLektion.armAfter==nil or s.voltLektion.armAfter>reverseArm)
check("reverse arc not completion", image().lage~="complete")
beginAt(20)
step(0,20); step(0,20)
for i=1,36 do local a=-math.pi/2+2*math.pi*i/72; step(9*math.cos(a),30+9*math.sin(a)) end
for v=38,21,-1 do step(0,v) end
for i=1,36 do local a=-math.pi/2+2*math.pi*i/72; step(9*math.cos(a),30+9*math.sin(a)) end
check("half circles joined through centre never complete", image().lage~="complete")
beginAt(20)
step(0,20); step(0,20)
local beforeGap=s.voltLektion.armAfter
step(0,20,5)
check("sample gap disarms current section", image().lage=="approach")
step(0,20); step(0,20); step(0,20)
check("recovered gap gets newer boundary", s.voltLektion.armAfter>beforeGap)
circle(-1,9)
local preserved=image().resultat
for _=1,12 do step(0,30,5); step(0,20,5); step(0,20) end
check("lesson result survives observation history pruning", image().resultat==preserved and preserved~=nil)

-- Consumer-boundary unit cases: the real lifecycle and evaluator receive a
-- substituted immutable observation snapshot. These are NOT geometry/engine evidence.
local realVolt=VoltObservation.ogonblick
local function metricCase(field,value,expected,label)
	beginAt(20); step(0,20); step(0,20)
	for i=1,18 do local a=-math.pi/2+2*math.pi*i/72; step(9*math.cos(a),30+9*math.sin(a)) end
	local source=realVolt(id)
	local section=table.clone(source.pagar)
	section.underlag="tillrackligt"; section.varv=1; section.netto=2*math.pi
	section.medelAvvikelse=1; section.maxAvvikelse=2; section.motriktning=0; section.aterkomst=1
	local candidate=table.clone(source)
	if string.sub(field,1,5)=="meta:" then candidate[string.sub(field,6)]=value else section[field]=value end
	candidate.pagar=table.freeze(section)
	candidate=table.freeze(candidate)
	VoltObservation.ogonblick=function(rid) return if rid==id then candidate else realVolt(rid) end
	s.voltLektion.sistaP=nil
	VoltLektion.steg(s.voltLektion,s.voltLektion.deadline-1)
	VoltObservation.ogonblick=realVolt
	check(label,(s.voltLektion.lage=="complete")==expected)
end
for _, limit in ipairs({{"medelAvvikelse",2},{"maxAvvikelse",4},{"motriktning",math.pi/4},{"aterkomst",3}}) do
	metricCase(limit[1],limit[2]-1e-6,true,limit[1].." below threshold")
	metricCase(limit[1],limit[2],true,limit[1].." equality")
	metricCase(limit[1],limit[2]+1e-6,false,limit[1].." beyond threshold")
end
metricCase("underlag","otillrackligt",false,"insufficient evidence cannot complete")
metricCase("underlag","okant",false,"unknown evidence cannot complete")
metricCase("varv",0,false,"no completed turn cannot complete")
metricCase("meta:version","legacy-1",false,"old observation version rejected")
metricCase("meta:userId",-100,false,"wrong observation owner rejected")
metricCase("meta:rittId","old-ride",false,"wrong observation ride rejected")
metricCase("meta:hastId","another-horse",false,"wrong observation horse rejected")

-- Baseline is consumed even when the first fresh source is a break.
VoltObservation.starta("baseline-probe","probe",123)
VoltObservation.lektionsGrans("baseline-probe")
VoltObservation.sampla("baseline-probe",{rittId="baseline-probe",t=1,status="brott"})
VoltObservation.sampla("baseline-probe",{rittId="baseline-probe",t=2,status="segment",ramId=1,
	dressyrMitt={u=0,v=30},segment={fran={u=0,v=20},till={u=1,v=20}}})
check("break consumes baseline without swallowing later valid segment", VoltObservation.ogonblick("baseline-probe").pagar~=nil)
VoltObservation.avsluta("baseline-probe","test")
beginAt(20)
local mountAttempt=RidForsok.aktivt(id)
for _=1,Skopa.GRANSER.DismountRequest.tak do Skopa.slapp(p,"DismountRequest") end
check("denied real dismount keeps lesson attempt", Networking.get("DismountRequest").OnServerInvoke(p)==false
	and RidForsok.aktivt(id)==mountAttempt)
check("accepted real dismount closes lesson attempt", HorseService.dismount(p)==true
	and HorseService.forsok(mountAttempt.forsokId).orsak=="ritt_slut:avsittning")
check("old lesson request denied after dismount", request("start",999)==false)
local previousRide=id
id=mount()
check("new mount has fresh lesson state", id~=previousRide and image().lage=="ready"
	and RidForsok.aktivt(id)==nil)

-- Actual client -> bounded remote -> HorseService -> owner event -> Ugneta surface.
local Net, V = Networking, VoltLektionController
local nu = 1000
Skopa._satKlockaForProv(function() return nu end)
Input._klocka = function() return nu end
local function render() for _=1,8 do Run.RenderStepped:Fire(1/30) end end
local function button(key)
	for _, k in ipairs(UgnetaController.panel().knappar) do
		if k.text==Sprak.t("voltlektion."..key) then return k end
	end
	return nil
end
local function click(key)
	nu+=2
	render()
	local panel=Naromrade._panel()
	assert(panel.synlig,"actual action panel hidden")
	local found
	for _, b in ipairs(panel.ram:GetDescendants()) do
		if b:IsA("TextButton") and b.Visible and b.Text==Sprak.t("voltlektion."..key) then found=b; break end
	end
	assert(found,"missing rendered button "..key)
	found.Activated:Fire()
	render()
end
render()
check("circle choice reachable without legacy lesson prerequisite", button("choose")~=nil)
click("choose")
check("choosing is not starting", button("start")~=nil and RidForsok.aktivt(id)==nil)
local remote=Net.get("VoltLektion")
local n=#remote._skickat
local cas=game:GetService("ContextActionService")
cas._bound[Input.DRIV](Input.DRIV,Enum.UserInputState.Begin,{})
render()
check("drive aid cannot start circle", #remote._skickat==n and button("start")~=nil)
check("circle disables legacy pause/advance/replay", not LektionController.vantar()
	and not LektionController.fortsatt() and not LektionController.gaVidare() and not LektionController.replay())
Sprak.satVal("en")
check("intro language changes", UgnetaController.panel().text==Sprak.t("voltlektion.intro"))
step(0,20,5); step(0,20)
click("start")
check("explicit start reaches actual server", RidForsok.aktivt(id)~=nil)
check("noncolliding local guide is created", workspace:FindFirstChild("Voltguide")~=nil)
local safeGuide=true
for _, part in ipairs(workspace:FindFirstChild("Voltguide"):GetChildren()) do
	safeGuide=safeGuide and part.Anchored and not part.CanCollide and not part.CanTouch and not part.CanQuery
end
check("every guide part is nonphysical", safeGuide)
step(0,20); step(0,20); step(0,20)
circle(1,9)
render()
check("server completion visibly reaches Ugneta", UgnetaController.panel().text==Sprak.t("voltlektion.complete")
	and button("retry")~=nil)
check("real teacher label renders completion", UgnetaController._larare().synlig
	and UgnetaController._larare().text==Sprak.t("voltlektion.complete"))
local completedAttempt=image().forsokId
check("guide removed on completion", workspace:FindFirstChild("Voltguide")==nil)
n=#remote._skickat; nu+=2
cas._bound[Input.DRIV](Input.DRIV,Enum.UserInputState.Begin,{})
render()
check("drive aid cannot retry or finish", #remote._skickat==n and button("retry")~=nil)
Sprak.satVal("sv")
check("result changes language without recomputation", UgnetaController.panel().text==Sprak.t("voltlektion.complete"))
click("retry")
local current=RidForsok.aktivt(id)
check("explicit retry creates actual new attempt", current~=nil and current.forsokId~=completedAttempt)
local oldButton=button("finish")
LektionController.avbryt("nekad")
check("detached UI has no actions or guide", V.panel()==nil and workspace:FindFirstChild("Voltguide")==nil)
LektionController.start(nil,id)
check("same ride reattachment preserves attempt", RidForsok.aktivt(id)==current and V.lektion())
n=#remote._skickat; oldButton.skicka()
check("old detached button ignored", #remote._skickat==n)
click("finish")
check("explicit finish returns to free riding", not LektionController.pagar() and button("lessons")~=nil)
click("lessons")
check("legacy lessons still reachable", not V.tarOver() and LektionController.vantar())

-- Delay only the transport; production client owns pending/late response logic.
local handler=remote.OnServerInvoke
local held
remote.OnServerInvoke=function(_,rid,op,seq)
	held={rid=rid,op=op,seq=seq}
	coroutine.yield()
	return true,nil,{rittId=rid,revision=999,sekvens=seq,lage="complete",tips="complete",progress=100}
end
local originalSpawn=task.spawn
local suspended
task.spawn=function(fn) suspended=coroutine.create(fn); assert(coroutine.resume(suspended)) end
click("choose")
check("pending request is not optimistic success", UgnetaController.panel().text==Sprak.t("voltlektion.pending"))
V.steg(10)
check("lost response offers bounded resync and finish", button("sync")~=nil and button("finish")~=nil)
local late=suspended
V.avbryt(); V.start("another-ride",nil)
assert(coroutine.resume(late))
check("late response cannot contaminate new ride", not V.lektion() and V.panel().text==nil)
task.spawn=originalSpawn; remote.OnServerInvoke=handler
check("lesson never writes persistent data", (__datastore.forsok and __datastore.forsok.skriv or 0)==writes)
if fails>0 then error(tostring(fails).." FEL") end
print(string.format("\nVOLTLEKTION: %d prov, alla gröna",total))
