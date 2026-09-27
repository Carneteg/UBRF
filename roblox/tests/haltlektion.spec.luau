--!nostrict
--[[ START/HALT-LEKTIONEN — docs/HALT-LESSON-CONTRACT.md.

	BANK_ONLY, KOHERENS-bänken: riktig HorseService, riktigt byggt ridhus,
	riktiga observationer (RidObservation, RidPlatsObservation, RidLogg).
	Gångarten ändras genom produktionens `RidingIntent` (driv/broms).

	SKRIVEN FÖR SENARE KÖRNING (Tobias beslut 5855114357: bygg nu, testa
	sist). Inte körd när den skrevs — ett första körresultat är den
	verkliga verifieringen, inte den här texten. ]]
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
local G = HaltLektion.GRANSER

local function player(id)
	local c = Instance.new("Model")
	local root = Instance.new("Part"); root.Name = "HumanoidRootPart"; root.Size = vec(2,2,1); root.Parent = c
	local h = Instance.new("Humanoid"); h.Name = "Humanoid"; h.Parent = c
	return { UserId = id, Name = "Halt" .. id, Character = c,
		CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }
end
local p = Players.LocalPlayer
p.Character = player(921).Character
Players._spelare = { p }
local horse = HastRigg.bygg("halt_test", "Halt test", CFrame.new(Ridhusplats.tillVarld(RP, vec(0, 0, 18))))
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
local id
local function mount()
	step(0, 18)
	local a = point(0, 18) + vec(6, 0, 0)
	local root = p.Character:FindFirstChild("HumanoidRootPart")
	root.CFrame = CFrame.new(a); root.Position = a
	local ok, reason, marke = HorseService.tryMount(p, horse)
	assert(ok, tostring(reason)); step(0, 18); step(0, 18)
	return marke
end
id = mount()
local seq = 0
local function request(op, typ)
	seq += 1
	return HorseService.voltLektionsBegaran(p, id, op, seq, typ or "halt")
end
local function image()
	local ok, _, b = HorseService.voltLektionsBegaran(p, id, "sync", nil, "halt"); assert(ok); return b
end
local intentSeq = 0
local function aid(handling)
	s.sisteHjalp = -math.huge
	s.intentPolletter = Config.RIDINPUT.SkopaTak
	intentSeq += 1
	Networking.get("RidingIntent").OnServerEvent:Fire(p, id, handling, intentSeq)
end
local function still(u, v, sekunder)
	for _ = 1, math.ceil(sekunder / 0.25) do step(u, v) end
end
local X = HorseService.ridplats(id).dressyrMitt

-- ── Lycklig väg: halt, skritt på hjälp, halt vid X ──
local ok, _, b = request("start")
check("start opens a halt attempt", ok and b.lage == "halt1" and b.typ == "halt")
check("start/halt attempt uses its own definition", HorseService.forsok(b.forsokId).ovning == "starthalt")
still(0, 18, G.HALT_FORE + 0.5)
check("fresh still halt moves on to walk", image().lage == "walk")
aid("driv")
check("accepted walk after the aid", Ridtrappa.gangart(s.stegIndex) == "walk")
for v = 19, X.v - 1 do step(X.u, v) end
aid("broms")
still(X.u, X.v - 0.5, G.HALT_EFTER + 0.75)
local done = image()
check("halt inside the zone at X completes", done.lage == "complete")
check("completion is slutford, not cancellation", HorseService.forsok(done.forsokId).orsak == "slutford")
check("result is frozen and records walked metres", done.resultat ~= nil and table.isfrozen(done.resultat)
	and done.resultat.skrittMeter >= G.SKRITT_M)
step(X.u, X.v + 3)
check("later riding cannot change the frozen result", image().resultat == done.resultat)

-- ── Halt utanför X räknas inte, återhämtning utan Retry ──
local ok2, _, b2 = request("retry")
check("retry opens a fresh attempt", ok2 and b2.forsokId ~= done.forsokId and b2.lage == "halt1")
still(X.u, X.v - 8, G.HALT_FORE + 0.5)
aid("driv")
for v = X.v - 7, X.v - 2 do step(X.u - 4, v) end
aid("broms")
still(X.u - 4, X.v - 2, G.HALT_EFTER + 0.75)
check("halt outside the zone never completes", image().lage == "walk" and image().tips == "halt_outside")
aid("driv")
step(X.u - 3, X.v - 1); step(X.u - 2, X.v - 0.5); step(X.u - 1, X.v)
aid("broms")
still(X.u - 0.5, X.v, G.HALT_EFTER + 0.75)
check("walking on to X recovers without Retry", image().lage == "complete")

-- ── Stilla hela försöket, trav, lucka, deadline ──
request("retry")
still(X.u, X.v, 10)
check("standing still the whole time never completes", image().lage == "walk")
aid("driv"); aid("driv")
check("trot is not walk", Ridtrappa.gangart(s.stegIndex) ~= "walk")
for v = X.v, X.v + 6 do step(X.u, v) end
check("trot distance is not walking evidence", image().progress <= 15)
aid("broms"); aid("broms")
still(X.u, X.v, 1)
step(X.u, X.v, 5)
check("unobserved gap is never stillness", image().lage ~= "complete")
s.voltLektion.deadline = os.clock()
step(X.u, X.v)
local timed = image()
check("deadline gives incomplete, never success", timed.lage == "timeout"
	and HorseService.forsok(timed.forsokId).orsak == "tidsgrans")

-- ── Byte av lektion, Finish, ägarbesked ──
request("retry")
local okSwitch, felSwitch = request("start", "volt")
check("switching lesson is refused while an attempt is active", okSwitch == false and felSwitch == "active")
local okFin, _, fin = request("finish")
check("finish cancels the active attempt", okFin and fin.lage == "closed")
local okVolt = request("start", "volt")
check("circle lesson still starts afterwards", okVolt == true)

local sync = Networking.get("VoltLektionSync")
local toOther = 0
for _, rad in ipairs(sync._skickat) do if rad[1] ~= p then toOther += 1 end end
check("owner events only to the owner", toOther == 0)
check("lesson never writes persistent data", (__datastore.forsok and __datastore.forsok.skriv or 0) == writes)
if fails > 0 then error(tostring(fails) .. " FEL") end
print(string.format("\nHALTLEKTION: %d prov, alla gröna", total))
