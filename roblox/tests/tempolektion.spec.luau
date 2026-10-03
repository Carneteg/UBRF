--!nostrict
--[[ JÄMN FART I SKRITT — docs/TEMPO-LESSON-CONTRACT.md.

	BANK_ONLY, KOHERENS-bänken: riktig HorseService, riktigt byggt ridhus,
	riktiga observationer. Gångarten ändras genom produktionens
	`RidingIntent` (driv/broms); rotens läge sätts mellan hjärtslagen på
	en cirkel (R 8 m kring (U, 16)) inne i layouten, så att farten per steg
	är känd (syntetisk rutt, inte spelarens ridning).

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
local G = TempoLektion.GRANSER

local function player(id)
	local c = Instance.new("Model")
	local root = Instance.new("Part"); root.Name = "HumanoidRootPart"; root.Size = vec(2,2,1); root.Parent = c
	local h = Instance.new("Humanoid"); h.Name = "Humanoid"; h.Parent = c
	return { UserId = id, Name = "Tempo" .. id, Character = c,
		CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }
end
local p = Players.LocalPlayer
p.Character = player(951).Character
Players._spelare = { p }
local horse = HastRigg.bygg("tempo_test", "Tempo test", CFrame.new(Ridhusplats.tillVarld(RP, vec(0, 0, 4))))
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
	return HorseService.voltLektionsBegaran(p, id, op, seq, typ or "tempo")
end
local function image()
	local ok, _, b = HorseService.voltLektionsBegaran(p, id, "sync", nil, "tempo"); assert(ok); return b
end
local intentSeq = 0
local function aid(handling)
	s.sisteHjalp = -math.huge
	s.intentPolletter = Config.RIDINPUT.SkopaTak
	intentSeq += 1
	Networking.get("RidingIntent").OnServerEvent:Fire(p, id, handling, intentSeq)
end
local U = HorseService.ridplats(id).dressyrMitt.u
local nu = { u = 0, v = 4 }
local function ga(u, v, dt) step(u, v, dt); nu = { u = u, v = v } end
--[[ Rakt till (u, v) med fart m/s (steg om 0,25 s). ]]
local function rakt(u, v, fart)
	local d = math.sqrt((u - nu.u) ^ 2 + (v - nu.v) ^ 2)
	local n = math.max(1, math.ceil(d / ((fart or 1.45) * 0.25)))
	local u0, v0 = nu.u, nu.v
	for i = 1, n do ga(u0 + (u - u0) * i / n, v0 + (v - v0) * i / n) end
end
--[[ Cirkeln R 8 m kring (U, 16): nederst i (U, 8). ]]
local KR, KV = 8, 16
local fi = -math.pi / 2
local function gaFart(fart, n, dt)
	dt = dt or 0.25
	for _ = 1, n do
		fi += fart * dt / KR
		ga(U + KR * math.cos(fi), KV + KR * math.sin(fi), dt)
	end
end
local function tillsKlar(fart, max)
	for _ = 1, max do
		if image().lage == "complete" then return true end
		gaFart(fart, 1)
	end
	return image().lage == "complete"
end

-- ── Färsk jämn skritt; jämn historik före Start räknas inte ──
aid("driv") -- skritt
rakt(U, 8)
gaFart(1.45, 20) -- jämn skritt FÖRE Start
local ok, _, b = request("start")
check("start opens a steady-walk attempt from zero", ok and b.lage == "steady" and b.typ == "tempo"
	and b.progress == 0)
check("steady walk attempt has its own definition", HorseService.forsok(b.forsokId).ovning == "jamn_skritt")
gaFart(1.45, 1)
check("steady history before Start and the boundary step give no credit", image().progress == 0)
gaFart(1.45, 1)
local p1 = image().progress
for _ = 1, 5 do image() end
check("repeated reads of the same snapshot add nothing", p1 > 0 and image().progress == p1)
gaFart(1.45, 29) -- 30 krediterade: 7,5 s
check("too short observed time does not complete (30 samples, 7.5 s)", image().lage == "steady")
gaFart(1.45, 1) -- 31: 7,75 s
check("still under 8 s does not complete", image().lage == "steady")
gaFart(1.45, 1) -- 32: 8,0 s
local done = image()
check("fresh steady walk completes", done.lage == "complete")
check("completion is slutford", HorseService.forsok(done.forsokId).orsak == "slutford")
check("frozen result has samples, seconds, metres and a walking mean", done.resultat ~= nil
	and table.isfrozen(done.resultat) and done.resultat.prov >= G.MIN_PROV
	and done.resultat.sekunder >= G.MIN_TID and done.resultat.meter >= G.MIN_M
	and math.abs(done.resultat.medelFart - 1.45) < 0.05 and done.resultat.enhet == "m/s")
gaFart(1.9, 10)
check("later riding cannot change the frozen result", image().resultat == done.resultat)

-- ── Stillastående, darrning, ojämn fart, för kort sträcka ──
local okR = request("retry")
check("retry opens a fresh attempt", okR == true and image().lage == "steady" and image().progress == 0)
for _ = 1, 10 do ga(nu.u, nu.v) end
check("standing still in walk is too slow and gives no progress", image().tips == "too_slow"
	and image().progress == 0)
for i = 1, 10 do ga(nu.u + (if i % 2 == 0 then 0.02 else -0.02), nu.v) end
check("tiny jitter is too slow and gives no progress", image().tips == "too_slow" and image().progress == 0)
for _ = 1, 30 do gaFart(1.0, 1); gaFart(1.9, 1) end
check("varying speed asks for steadier and never completes", image().lage == "steady"
	and image().tips == "steadier" and image().progress < 10)
ga(nu.u, nu.v) -- för långsamt: serien bort
gaFart(0.95, 40) -- 40 prov, 10 s, 9,5 m
check("too short distance does not complete (40 samples, 10 s, 9.5 m)", image().lage == "steady")
check("slow but steady walk completes once the distance is reached", tillsKlar(0.95, 5))

-- ── För få prov (steg om 0,5 s) ──
request("retry")
gaFart(1.45, 1)
gaFart(1.45, 16, 0.5) -- 16 prov, 8 s, 11,6 m
check("too few samples do not complete (16 samples, 8 s)", image().lage == "steady")
gaFart(1.45, 14, 0.5)
check("thirty samples at 0.5 s complete", image().lage == "complete")

-- ── Halt, ny gångart, trav, ryggning ──
request("retry")
gaFart(1.45, 10)
check("KONTROLL: credit before the halt", image().progress > 0)
aid("broms")
ga(nu.u, nu.v)
check("halt discards the run", image().progress == 0 and image().tips == "walk_on")
aid("driv")
gaFart(1.45, 1)
check("the step with a gait change is not credited", image().progress == 0)
gaFart(1.45, 5)
check("KONTROLL: credit again in walk", image().progress > 0)
aid("driv") -- trav
gaFart(3.2, 1)
check("trot discards the run", image().progress == 0 and image().tips == "walk_only")
aid("broms") -- skritt
aid("broms") -- halt
aid("broms") -- ryggning
check("KONTROLL: the server accepted reversing", Ridtrappa.ryggar(s.stegIndex) == true)
ga(nu.u, nu.v - 0.1)
check("reversing discards the run", image().progress == 0 and image().tips == "walk_only")
aid("driv"); aid("driv")
check("KONTROLL: back in walk", Ridtrappa.gangart(s.stegIndex) == "walk"
	and not Ridtrappa.ryggar(s.stegIndex))

-- ── Utanför layouten, teleport, återhämtning ──
gaFart(1.45, 10)
--[[ Ut över NÄRMASTE långsidan. Vägen till U + 11 korsade hela banan från
	cirkelns vänstra sida (u ≈ U − 8) och gav en fullföljd serie innan
	kanten nåddes. ]]
rakt(if nu.u < U then U - 11 else U + 11, nu.v)
check("leaving the layout discards the run", image().lage == "steady" and image().tips == "stay_inside"
	and image().progress == 0)
rakt(U + KR * math.cos(fi), KV + KR * math.sin(fi))
check("recovery after leaving the layout completes", tillsKlar(1.45, 45))

request("retry")
gaFart(1.45, 10)
fi += math.pi
ga(U + KR * math.cos(fi), KV + KR * math.sin(fi)) -- teleport, 16 m på 0,25 s
check("a teleport discards the run, never joins", image().lage == "steady" and image().progress == 0)
check("fresh recovery after the break completes", tillsKlar(1.45, 45))

-- ── Tidsgräns, begäranbok över typbyte, alla lektioner ──
request("retry")
s.voltLektion.deadline = os.clock()
gaFart(1.45, 1)
local timed = image()
check("deadline gives incomplete, never success", timed.lage == "timeout"
	and HorseService.forsok(timed.forsokId).orsak == "tidsgrans")

request("finish")
local base = seq
HorseService.voltLektionsBegaran(p, id, "start", base + 1, "tempo")
HorseService.voltLektionsBegaran(p, id, "finish", base + 2, "tempo")
HorseService.voltLektionsBegaran(p, id, "start", base + 3, "halt")
HorseService.voltLektionsBegaran(p, id, "finish", base + 4, "halt")
seq = base + 4
HorseService.voltLektionsBegaran(p, id, "start", base + 1, "tempo")
check("a delayed old tempo start after a type switch opens no attempt", RidForsok.aktivt(id) == nil)
local okDup = HorseService.voltLektionsBegaran(p, id, "start", base + 3, "tempo")
check("the same sequence with another type is refused", okDup == false)

rakt(U, 4)
local okV = request("start", "volt")
local okVF = request("finish", "volt")
local okH = request("start", "halt")
local okHF = request("finish", "halt")
local okO = request("start", "overgang")
local okOF = request("finish", "overgang")
local okS = request("start", "serpentin")
local okSF = request("finish", "serpentin")
local okT = request("start")
local okTF, _, tf = request("finish")
check("all five lessons start and finish", okV == true and okVF == true and okH == true
	and okHF == true and okO == true and okOF == true and okS == true and okSF == true
	and okT == true and okTF == true and tf.lage == "closed")

local sync = Networking.get("VoltLektionSync")
local toOther = 0
for _, rad in ipairs(sync._skickat) do if rad[1] ~= p then toOther += 1 end end
check("owner events only to the owner", toOther == 0)
check("lesson never writes persistent data", (__datastore.forsok and __datastore.forsok.skriv or 0) == writes)
if fails > 0 then error(tostring(fails) .. " FEL") end
print(string.format("\nTEMPOLEKTION: %d prov, alla gröna", total))
