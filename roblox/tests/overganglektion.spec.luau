--!nostrict
--[[ ÖVERGÅNGSLEKTIONEN — docs/TRANSITION-LESSON-CONTRACT.md.

	BANK_ONLY, KOHERENS-bänken: riktig HorseService, riktigt byggt ridhus,
	riktiga observationer. Gångarten ändras genom produktionens
	`RidingIntent` (driv/broms); rotens läge sätts mellan hjärtslagen
	(syntetisk rutt, inte spelarens ridning).

	SKRIVEN FÖR SENARE KÖRNING (Tobias beslut 5855114357: bygg nu, testa
	sist). Inte körd när den skrevs. ]]
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
local G = OvergangLektion.GRANSER

local function player(id)
	local c = Instance.new("Model")
	local root = Instance.new("Part"); root.Name = "HumanoidRootPart"; root.Size = vec(2,2,1); root.Parent = c
	local h = Instance.new("Humanoid"); h.Name = "Humanoid"; h.Parent = c
	return { UserId = id, Name = "Overgang" .. id, Character = c,
		CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }
end
local p = Players.LocalPlayer
p.Character = player(931).Character
Players._spelare = { p }
local horse = HastRigg.bygg("overgang_test", "Overgang test", CFrame.new(Ridhusplats.tillVarld(RP, vec(0, 0, 4))))
horse.Parent = workspace; Tags:AddTag(horse, "Horse")
local s = HorseService.sessionFor(horse)
local function point(u, v)
	local a = Ridhusplats.tillVarld(RP, vec(u, 0, v))
	return vec(a.X, s.rig.root.Position.Y, a.Z)
end
local function step(u, v, dt)
	local a = point(u, v); s.rig.root.CFrame = CFrame.new(a); s.rig.root.Position = a
	s.energi = 1; Run.Heartbeat:Fire(dt or 0.25)
end
local function mount()
	step(0, 4)
	local a = point(0, 4) + vec(6, 0, 0)
	local root = p.Character:FindFirstChild("HumanoidRootPart")
	root.CFrame = CFrame.new(a); root.Position = a
	local ok, reason, marke = HorseService.tryMount(p, horse)
	assert(ok, tostring(reason)); step(0, 4); step(0, 4)
	return marke
end
local id = mount()
local seq = 0
local function request(op, typ)
	seq += 1
	return HorseService.voltLektionsBegaran(p, id, op, seq, typ or "overgang")
end
local function image()
	local ok, _, b = HorseService.voltLektionsBegaran(p, id, "sync", nil, "overgang"); assert(ok); return b
end
local intentSeq = 0
local function aid(handling)
	s.sisteHjalp = -math.huge
	s.intentPolletter = Config.RIDINPUT.SkopaTak
	intentSeq += 1
	Networking.get("RidingIntent").OnServerEvent:Fire(p, id, handling, intentSeq)
end
local U = HorseService.ridplats(id).dressyrMitt.u
local function linje(v0, v1)
	local d = if v1 >= v0 then 1 else -1
	for v = v0, v1, d do step(U, v) end
end
--[[ Helt varv genom lektionen från halt vid v=4: skritt, trav vid T1,
	trav, skritt vid T2, skritt. ]]
local function helaVagen()
	aid("driv"); linje(5, G.T1_V - 1)          -- skritt, ≥ 3 m
	aid("driv"); step(U, G.T1_V)               -- trav begärs inne i T1
	linje(G.T1_V + 1, G.T2_V - 2)              -- trav ≥ 6 m
	aid("broms"); step(U, G.T2_V - 1)          -- skritt begärs inne i T2
	linje(G.T2_V, G.T2_V + 2)                  -- skritt ≥ 2 m
end
local function tillbakaTillHalt()
	--[[ Bromsa tills hästen står i halt — inte längre. Tre blinda broms från
		skritt gav halt → ryggning, och tillbakavägen (ryggning → halt → skritt)
		loggades sedan som övergångar i det nya försöket. ]]
	for _ = 1, 4 do
		if Ridtrappa.gangart(s.stegIndex) == "halt" and not Ridtrappa.ryggar(s.stegIndex) then break end
		aid("broms"); step(U, 4)
	end
	step(U, 4, 5); step(U, 4); step(U, 4)
end

-- ── Lycklig väg T1 → T2 ──
local ok, _, b = request("start")
check("start opens a transition attempt in walk1", ok and b.lage == "walk1" and b.typ == "overgang")
check("transition attempt has its own definition", HorseService.forsok(b.forsokId).ovning == "overgangar")
helaVagen()
local done = image()
check("trot at T1 and walk at T2 completes", done.lage == "complete")
check("completion is slutford", HorseService.forsok(done.forsokId).orsak == "slutford")
check("frozen result records both transition places", done.resultat ~= nil and table.isfrozen(done.resultat)
	and done.resultat.vidT1 ~= nil and done.resultat.vidT2 ~= nil and done.resultat.travMeter >= G.TRAV_M)
step(U, G.T2_V + 3)
check("later riding cannot change the frozen result", image().resultat == done.resultat)

-- ── Tidig trav, skritt utanför T2, skritt vid T1 i stället för T2 ──
tillbakaTillHalt()
local okR = request("retry")
check("retry opens a fresh attempt", okR == true and image().lage == "walk1")
aid("driv"); linje(5, 10)
aid("driv"); step(U, 11)
check("trot requested before T1 is not success", image().lage == "walk1" and image().tips == "trot_outside")
aid("broms"); linje(12, G.T1_V - 1)
aid("driv"); step(U, G.T1_V)
check("recovery: trot at T1 after fresh walk", image().lage == "trot")
linje(G.T1_V + 1, 30)
aid("broms"); step(U, 31)
check("walk requested outside T2 is not success", image().lage == "walk1" and image().tips == "walk_outside")
linje(30, 20) -- already in walk after the reset: fresh walking back towards T1
check("KONTROLL: back in walk1", image().lage == "walk1")
aid("driv"); step(U, G.T1_V)
linje(G.T1_V + 1, G.T1_V + 8); linje(G.T1_V + 7, G.T1_V)
aid("broms"); step(U, G.T1_V - 0.5)
check("walk at T1 instead of T2 is not success", image().lage == "walk1")

-- ── Gångart utan rörelse, för kort trav ──
tillbakaTillHalt()
request("finish"); request("start")
step(U, G.T1_V, 5); step(U, G.T1_V)
aid("driv")
for _ = 1, 8 do step(U, G.T1_V) end
aid("driv"); step(U, G.T1_V)
check("walk label without movement is not walking evidence", image().lage == "walk1"
	and image().tips == "walk_first")
aid("broms"); linje(G.T1_V - 6, G.T1_V - 1)
aid("driv"); step(U, G.T1_V)
linje(G.T1_V + 1, G.T1_V + 3)
aid("broms"); step(U, G.T1_V + 4)
check("walking after under 6 m of trot restarts", image().lage == "walk1" and image().tips == "trot_longer")

-- ── Trötthet (enhetsgräns: injicerad) och teleport ──
tillbakaTillHalt()
request("finish"); request("start")
aid("driv"); linje(5, G.T1_V - 1)
aid("driv"); step(U, G.T1_V)
linje(G.T1_V + 1, G.T1_V + 8)
RidLogg.gangart(id, { fran = "trot", franRyggar = false, till = "walk", tillRyggar = false,
	orsak = "trotthet" }, os.clock())
s.stegIndex = Ridtrappa.index("walk")
step(U, G.T1_V + 9)
check("a fatigue-forced walk is never the requested walk", image().lage == "walk1" and image().tips == "tired")

tillbakaTillHalt()
request("finish"); request("start")
aid("driv"); linje(5, G.T1_V - 1)
aid("driv"); step(U, G.T1_V)
linje(G.T1_V + 1, G.T1_V + 4)
step(U, G.T2_V) -- teleport forward into T2
aid("broms"); step(U, G.T2_V + 0.5)
check("a teleport between T1 and T2 resets, never joins", image().lage == "walk1")
tillbakaTillHalt()
request("finish"); request("start")
helaVagen()
check("fresh evidence after the break completes", image().lage == "complete")

-- ── Tidsgräns, begäranbok över typbyte, Retry/Finish, andra lektioner ──
tillbakaTillHalt()
request("retry")
s.voltLektion.deadline = os.clock()
step(U, 4)
local timed = image()
check("deadline gives incomplete, never success", timed.lage == "timeout"
	and HorseService.forsok(timed.forsokId).orsak == "tidsgrans")

request("finish")
local base = seq
HorseService.voltLektionsBegaran(p, id, "start", base + 1, "overgang")
HorseService.voltLektionsBegaran(p, id, "finish", base + 2, "overgang")
HorseService.voltLektionsBegaran(p, id, "start", base + 3, "halt")
HorseService.voltLektionsBegaran(p, id, "finish", base + 4, "halt")
seq = base + 4
HorseService.voltLektionsBegaran(p, id, "start", base + 1, "overgang")
check("a delayed old transition start after a type switch opens no attempt", RidForsok.aktivt(id) == nil)

local okV = request("start", "volt")
local okVF = request("finish", "volt")
local okH = request("start", "halt")
local okHF = request("finish", "halt")
local okO = request("start")
local okOF, _, of = request("finish")
check("circle, start/halt and transitions all start and finish", okV == true and okVF == true
	and okH == true and okHF == true and okO == true and okOF == true and of.lage == "closed")

local sync = Networking.get("VoltLektionSync")
local toOther = 0
for _, rad in ipairs(sync._skickat) do if rad[1] ~= p then toOther += 1 end end
check("owner events only to the owner", toOther == 0)
check("lesson never writes persistent data", (__datastore.forsok and __datastore.forsok.skriv or 0) == writes)
if fails > 0 then error(tostring(fails) .. " FEL") end
print(string.format("\nOVERGANGLEKTION: %d prov, alla gröna", total))
