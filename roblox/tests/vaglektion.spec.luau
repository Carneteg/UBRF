--!nostrict
--[[ RIDVÄGAR: MITTLINJEN OCH DIAGONALEN — docs/RIDING-PATH-LESSON-CONTRACT.md.

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
local F = VagLektion.FIGURER

local function player(id)
	local c = Instance.new("Model")
	local root = Instance.new("Part"); root.Name = "HumanoidRootPart"; root.Size = vec(2,2,1); root.Parent = c
	local h = Instance.new("Humanoid"); h.Name = "Humanoid"; h.Parent = c
	return { UserId = id, Name = "Vag" .. id, Character = c,
		CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }
end
local p = Players.LocalPlayer
p.Character = player(961).Character
Players._spelare = { p }
local horse = HastRigg.bygg("vag_test", "Vag test", CFrame.new(Ridhusplats.tillVarld(RP, vec(0, 0, 4))))
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
local figur = "vag_mitt"
local function request(op, typ)
	seq += 1
	return HorseService.voltLektionsBegaran(p, id, op, seq, typ or figur)
end
local function image()
	local ok, _, b = HorseService.voltLektionsBegaran(p, id, "sync", nil, figur); assert(ok); return b
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
local function rakt(u, v)
	local n = math.max(1, math.ceil(math.sqrt((u - nu.u) ^ 2 + (v - nu.v) ^ 2)))
	local u0, v0 = nu.u, nu.v
	for i = 1, n do ga(u0 + (u - u0) * i / n, v0 + (v - v0) * i / n) end
end
--[[ Figurens linje: punkten vid läget sL (meter från P0). ]]
local function langd(fig)
	local f = F[fig]
	return math.sqrt((f.du1 - f.du0) ^ 2 + (f.v1 - f.v0) ^ 2)
end
local function lp(fig, sL)
	local f = F[fig]
	local L = langd(fig)
	return U + f.du0 + (f.du1 - f.du0) * sL / L, f.v0 + (f.v1 - f.v0) * sL / L
end
--[[ Längs linjen från s0 till s1 i steg om högst 0,9 m; sista punkten exakt. ]]
local function linje(fig, s0, s1)
	local n = math.max(1, math.ceil(math.abs(s1 - s0) / 0.9))
	for i = 1, n do
		if i == n and s1 == langd(fig) then
			local f = F[fig]; ga(U + f.du1, f.v1)
		elseif i == n and s1 == 0 then
			local f = F[fig]; ga(U + f.du0, f.v0)
		else
			ga(lp(fig, s0 + (s1 - s0) * i / n))
		end
	end
end
--[[ Utanför linjen längs långsidan, sedan in bakifrån: 3 m bakom P0. ]]
local function tillStart(fig)
	rakt(U - 9.5, nu.v); rakt(U - 9.5, 2)
	rakt(lp(fig, -3))
end

-- ── Mittlinjen hela vägen; inflygning bakifrån ger ingen kredit ──
aid("driv") -- skritt
local ok, _, b = request("start")
check("start opens a riding-path attempt for the chosen figure", ok and b.lage == "to_start"
	and b.typ == "vag_mitt" and b.delmal == 0)
check("riding-path attempt has its own definition", HorseService.forsok(b.forsokId).ovning == "ridvag")
rakt(U, 2)
linje("vag_mitt", -4, -1.9)
check("approaching through the start ring arms with no credit", image().lage == "route"
	and image().progress == 0 and image().delmal == 1)
linje("vag_mitt", -1.9, 0) -- exakt P0
linje("vag_mitt", 0, langd("vag_mitt")) -- exakt P1
local done = image()
check("the full centre line completes", done.lage == "complete")
check("completion is slutford", HorseService.forsok(done.forsokId).orsak == "slutford")
check("frozen result records the figure and the metres", done.resultat ~= nil
	and table.isfrozen(done.resultat) and done.resultat.figur == "vag_mitt"
	and math.abs(done.resultat.meter - langd("vag_mitt")) < 1e-6)
rakt(U + 3, 50)
check("later riding cannot change the frozen result", image().resultat == done.resultat)

-- ── Parallellt fel, bara slutringen ──
local okR = request("retry")
check("retry opens a fresh attempt", okR == true and image().lage == "to_start" and image().progress == 0)
rakt(U + 4, 2)
for v = 3, 54 do ga(U + 4, v) end
check("a parallel line 4 m beside the centre line never arms", image().lage == "to_start"
	and image().progress == 0)
rakt(U, 54)
check("visiting only the end ring does not complete", image().lage == "to_start")

-- ── Bakåt, pendling, stillastående, haltpaus ──
tillStart("vag_mitt")
linje("vag_mitt", -3, 10)
local p10 = image().progress
linje("vag_mitt", 10, 8.5)
check("backwards travel resets", p10 > 0 and image().lage == "to_start" and image().tips == "reverse")
tillStart("vag_mitt")
linje("vag_mitt", -3, 0)
for _ = 1, 5 do linje("vag_mitt", 0, 0.8); linje("vag_mitt", 0.8, 0) end
check("oscillating near the start gives no progress", image().lage == "route" and image().progress <= 2)
for _ = 1, 10 do ga(nu.u, nu.v) end
check("standing still gives no progress", image().progress <= 2)
linje("vag_mitt", 0, 12)
local p12 = image().progress
aid("broms") -- halt
for _ = 1, 5 do ga(nu.u, nu.v) end
check("a halt pause keeps the credit", image().lage == "route" and image().progress == p12)
aid("driv") -- skritt
linje("vag_mitt", 12, 16)
check("walking on after the halt continues", image().lage == "route" and image().progress > p12)
aid("broms"); aid("broms") -- halt, ryggning
check("KONTROLL: the server accepted reversing", Ridtrappa.ryggar(s.stegIndex) == true)
ga(nu.u, nu.v - 0.1)
check("reversing resets", image().lage == "to_start" and image().tips == "walk_or_trot")
aid("driv"); aid("driv")
check("KONTROLL: back in walk", Ridtrappa.gangart(s.stegIndex) == "walk")

-- ── Trav räknas, galopp nollställer; grovt segment; teleport ──
tillStart("vag_mitt")
aid("driv") -- trav
linje("vag_mitt", -3, 10)
check("trot counts", image().lage == "route" and image().progress > 0)
aid("driv") -- galopp
linje("vag_mitt", 10, 11)
check("canter resets", image().lage == "to_start" and image().tips == "walk_or_trot")
aid("broms"); aid("broms") -- skritt
tillStart("vag_mitt")
linje("vag_mitt", -3, 10)
do
	local u, v = lp("vag_mitt", 14.5)
	ga(u, v, 0.5) -- 4,5 m på 0,5 s: under teleportgränsen, över grovgränsen
end
check("a coarse segment is unknown, never progress", image().lage == "to_start")
tillStart("vag_mitt")
linje("vag_mitt", -3, 10)
ga(lp("vag_mitt", 40)) -- teleport
check("a teleport resets, never joins", image().lage == "to_start" and image().progress == 0)
tillStart("vag_mitt")
linje("vag_mitt", -3, langd("vag_mitt"))
check("fresh recovery after the break completes", image().lage == "complete")

-- ── Figurbyte under aktivt försök; diagonalen ──
request("retry")
local okByt, felByt = request("start", "vag_diag")
check("switching figure while an attempt is active is refused", okByt == false and felByt == "active")
local okFin = request("finish", "vag_diag")
check("finish acts on the current figure", okFin == true and image().lage == "closed")
figur = "vag_diag"
local okD, _, bd = request("start")
check("the diagonal starts as its own figure", okD == true and bd.typ == "vag_diag")
tillStart("vag_diag")
linje("vag_diag", -3, 5)
rakt(nu.u, nu.v + 10) -- rakt mot C i stället för diagonalen
check("leaving the diagonal towards C resets", image().lage == "to_start" and image().tips == "off_route")
tillStart("vag_diag")
linje("vag_diag", -3, langd("vag_diag"))
local dd = image()
check("the full diagonal completes with its figure", dd.lage == "complete" and dd.resultat.figur == "vag_diag")

-- ── Tidsgräns, begäranbok över figurer och typer, alla lektioner ──
request("retry")
s.voltLektion.deadline = os.clock()
ga(nu.u, nu.v)
local timed = image()
check("deadline gives incomplete, never success", timed.lage == "timeout"
	and HorseService.forsok(timed.forsokId).orsak == "tidsgrans")

request("finish")
local base = seq
HorseService.voltLektionsBegaran(p, id, "start", base + 1, "vag_mitt")
HorseService.voltLektionsBegaran(p, id, "finish", base + 2, "vag_mitt")
HorseService.voltLektionsBegaran(p, id, "start", base + 3, "vag_diag")
HorseService.voltLektionsBegaran(p, id, "finish", base + 4, "vag_diag")
seq = base + 4
HorseService.voltLektionsBegaran(p, id, "start", base + 1, "vag_mitt")
check("a delayed old start of the other figure opens no attempt", RidForsok.aktivt(id) == nil)
local okDup = HorseService.voltLektionsBegaran(p, id, "start", base + 3, "vag_mitt")
check("the same sequence with the other figure is refused", okDup == false)

rakt(U, 4)
local alla = true
for _, t in ipairs({ "volt", "halt", "overgang", "serpentin", "tempo", "vag_mitt", "vag_diag" }) do
	local okS = request("start", t)
	local okF, _, bf = request("finish", t)
	if not (okS == true and okF == true and bf.lage == "closed") then alla = false end
end
check("all seven lesson types start and finish", alla)

local sync = Networking.get("VoltLektionSync")
local toOther = 0
for _, rad in ipairs(sync._skickat) do if rad[1] ~= p then toOther += 1 end end
check("owner events only to the owner", toOther == 0)
check("lesson never writes persistent data", (__datastore.forsok and __datastore.forsok.skriv or 0) == writes)
if fails > 0 then error(tostring(fails) .. " FEL") end
print(string.format("\nVAGLEKTION: %d prov, alla gröna", total))
