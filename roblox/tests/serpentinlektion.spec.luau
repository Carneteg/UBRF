--!nostrict
--[[ SERPENTINLEKTIONEN — docs/SERPENTINE-LESSON-CONTRACT.md.

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
local G = SerpentinLektion.GRANSER

local function player(id)
	local c = Instance.new("Model")
	local root = Instance.new("Part"); root.Name = "HumanoidRootPart"; root.Size = vec(2,2,1); root.Parent = c
	local h = Instance.new("Humanoid"); h.Name = "Humanoid"; h.Parent = c
	return { UserId = id, Name = "Serpentin" .. id, Character = c,
		CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }
end
local p = Players.LocalPlayer
p.Character = player(941).Character
Players._spelare = { p }
local horse = HastRigg.bygg("serpentin_test", "Serpentin test", CFrame.new(Ridhusplats.tillVarld(RP, vec(0, 0, 4))))
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
	return HorseService.voltLektionsBegaran(p, id, op, seq, typ or "serpentin")
end
local function image()
	local ok, _, b = HorseService.voltLektionsBegaran(p, id, "sync", nil, "serpentin"); assert(ok); return b
end
local intentSeq = 0
local function aid(handling)
	s.sisteHjalp = -math.huge
	s.intentPolletter = Config.RIDINPUT.SkopaTak
	intentSeq += 1
	Networking.get("RidingIntent").OnServerEvent:Fire(p, id, handling, intentSeq)
end
local U = HorseService.ridplats(id).dressyrMitt.u
local BAGE = math.pi * G.R
local SIDOR = { 1, -1, 1 }
local nu = { u = 0, v = 4 }
local function ga(u, v, dt) step(u, v, dt); nu = { u = u, v = v } end
--[[ Punkten på vägen vid läget S (meter längs vägen). ]]
local function vag(S)
	local k = math.clamp(math.floor(S / BAGE) + 1, 1, 3)
	local th = (S - (k - 1) * BAGE) / G.R
	local c = G.V0 + G.R + (k - 1) * 2 * G.R
	return U + SIDOR[k] * G.R * math.sin(th), c - G.R * math.cos(th)
end
--[[ Längs vägen från S0 till S1 i steg om högst 0,9 m (framåt eller bakåt). ]]
local function rutt(S0, S1)
	local n = math.max(1, math.ceil(math.abs(S1 - S0) / 0.9))
	for i = 1, n do ga(vag(S0 + (S1 - S0) * i / n)) end
end
--[[ Rakt till (u, v) i steg om högst 1 m. ]]
local function rakt(u, v)
	local n = math.max(1, math.ceil(math.sqrt((u - nu.u) ^ 2 + (v - nu.v) ^ 2)))
	local u0, v0 = nu.u, nu.v
	for i = 1, n do ga(u0 + (u - u0) * i / n, v0 + (v - v0) * i / n) end
end
--[[ Utanför vägen längs långsidan tillbaka till startringen, in från −u. ]]
local function tillStartring()
	rakt(U - 9.5, nu.v); rakt(U - 9.5, G.V0); rakt(U - 2, G.V0); rakt(U, G.V0)
end

-- ── Hel genomridning A → C ──
aid("driv") -- skritt
local ok, _, b = request("start")
check("start opens a serpentine attempt at the start ring", ok and b.lage == "to_start"
	and b.typ == "serpentin" and b.delmal == 0)
check("serpentine attempt has its own definition", HorseService.forsok(b.forsokId).ovning == "serpentin")
rakt(U, 5)
check("entering the start ring begins the route", image().lage == "route" and image().delmal == 1)
rutt(0, G.LANGD)
local done = image()
check("complete ordered traversal completes", done.lage == "complete")
check("completion is slutford", HorseService.forsok(done.forsokId).orsak == "slutford")
check("frozen result records two ordered crossings", done.resultat ~= nil and table.isfrozen(done.resultat)
	and #done.resultat.korsningar == 2 and done.resultat.korsningar[1].v < done.resultat.korsningar[2].v)
rakt(U, 50)
check("later riding cannot change the frozen result", image().resultat == done.resultat)

-- ── Bara slutringen, genväg, baklänges ──
local okR = request("retry")
check("retry opens a fresh attempt", okR == true and image().lage == "to_start" and image().progress == 0)
rakt(U, G.V0 + 6 * G.R + 1); rakt(U + 1, G.V0 + 6 * G.R)
check("visiting only the end ring does not complete", image().lage == "to_start" and image().progress == 0)
tillStartring()
check("KONTROLL: back on the route at the start", image().lage == "route")
rakt(U, 30)
check("a shortcut along the centre line leaves the corridor", image().lage == "to_start"
	and image().tips == "off_route" and image().progress == 0)
rakt(U + 1, G.V0 + 6 * G.R); ga(vag(G.LANGD))
rutt(G.LANGD, 0)
check("reverse traversal from the end makes no progress", image().lage ~= "complete" and image().progress <= 2)

-- ── Tillbaka längs vägen, runt startmarkören, stillastående ──
tillStartring()
rutt(0, 20)
local innan = image().progress
rutt(20, 15)
check("going back along the route resets", image().lage == "to_start" and image().tips == "reverse"
	and innan > 0 and image().progress == 0)
tillStartring()
for _ = 1, 3 do
	for i = 1, 8 do
		local a = 2 * math.pi * i / 8
		ga(U + 1.5 * math.cos(a), G.V0 + 1.5 * math.sin(a))
	end
end
check("circling at the start marker gives no progress beyond the start", image().lage ~= "complete"
	and image().progress < 6 and image().delmal <= 1)
tillStartring()
for _ = 1, 20 do ga(nu.u, nu.v) end
check("standing still gives no progress", image().lage == "route" and image().progress == 0)

-- ── Grovt segment, teleport, galopp ──
rutt(0, 10)
do
	local u, v = vag(15)
	ga(u, v, 0.5) -- ~4,9 m på 0,5 s: under teleportgränsen, över grovgränsen
end
check("a coarse segment is unknown, never progress", image().lage == "to_start" and image().tips == "unknown")
tillStartring()
rutt(0, 20)
ga(U - 8, 30) -- teleport till andra bågen
check("a teleport mid-route resets, never joins", image().lage == "to_start" and image().progress == 0)
tillStartring()
rutt(0, G.LANGD)
check("fresh evidence after the break completes", image().lage == "complete")

-- ── R1: exakt på mittlinjen (atan2 med −0 får inte ge −π) ──
local proj = SerpentinLektion._projiceraForProv
local function nara(S, mal) return S ~= nil and math.abs(S - mal) < 1e-6 end
local S22, t22 = proj(U, U, G.V0 + 2 * G.R)
local S38, t38 = proj(U, U, G.V0 + 4 * G.R)
check("R1: literal centre-line crossing (u0, 22) projects to the end of loop 1",
	nara(S22, BAGE) and t22 == false)
check("R1: literal centre-line crossing (u0, 38) projects to the end of loop 2, not 0",
	nara(S38, 2 * BAGE) and t38 == false)
local S6, t6 = proj(U, U, G.V0)
local S54, t54 = proj(U, U, G.V0 + 6 * G.R)
check("R1: literal start and end points project to 0 and the full length",
	nara(S6, 0) and t6 == false and nara(S54, G.LANGD) and t54 == false)
local Sa, ta = proj(U, U + 1e-9, G.V0 + 4 * G.R)
local Sb, tb = proj(U, U - 1e-9, G.V0 + 4 * G.R)
check("R1: points just either side of (u0, 38) stay unambiguous near 2·BAGE",
	Sa ~= nil and Sb ~= nil and ta == false and tb == false
	and math.abs(Sa - 2 * BAGE) < 0.01 and math.abs(Sb - 2 * BAGE) < 0.01)
local Sm2 = proj(U, U - G.R, G.V0 + 3 * G.R)
local Sm3 = proj(U, U + G.R, G.V0 + 5 * G.R)
check("R1: the widest points of loops 2 and 3 project to their middles",
	nara(Sm2, 1.5 * BAGE) and nara(Sm3, 2.5 * BAGE))
local Sut = proj(U, U, G.V0 + 3 * G.R)
check("R1: the centre line between crossings stays outside the corridor", Sut == nil)

request("retry")
tillStartring()
--[[ Varje båge slutar EXAKT på mittlinjen (u = U, inte sin(π)·R), så
	produktionsvägen passerar de bokstavliga korsningspunkterna. ]]
for k = 1, 3 do
	local S0, S1 = (k - 1) * BAGE, k * BAGE
	local n = math.ceil(BAGE / 0.9)
	for i = 1, n do
		if i == n then ga(U, G.V0 + 2 * G.R * k) else ga(vag(S0 + (S1 - S0) * i / n)) end
	end
	if k < 3 then
		check("R1: exact crossing " .. k .. " keeps the route (no unknown reset)",
			image().lage == "route" and image().tips ~= "unknown")
	end
end
local exakt = image()
check("R1: a traversal through the literal crossings completes", exakt.lage == "complete"
	and #exakt.resultat.korsningar == 2)

request("retry")
tillStartring()
rutt(0, 10)
aid("driv"); aid("driv") -- trav, sedan galopp
ga(vag(10.9))
check("canter resets to the start ring", image().lage == "to_start" and image().tips == "walk_or_trot")
aid("broms"); aid("broms")

-- ── Tidsgräns, begäranbok över typbyte, alla lektioner ──
tillStartring()
s.voltLektion.deadline = os.clock()
ga(vag(1))
local timed = image()
check("deadline gives incomplete, never success", timed.lage == "timeout"
	and HorseService.forsok(timed.forsokId).orsak == "tidsgrans")

request("finish")
local base = seq
HorseService.voltLektionsBegaran(p, id, "start", base + 1, "serpentin")
HorseService.voltLektionsBegaran(p, id, "finish", base + 2, "serpentin")
HorseService.voltLektionsBegaran(p, id, "start", base + 3, "halt")
HorseService.voltLektionsBegaran(p, id, "finish", base + 4, "halt")
seq = base + 4
HorseService.voltLektionsBegaran(p, id, "start", base + 1, "serpentin")
check("a delayed old serpentine start after a type switch opens no attempt", RidForsok.aktivt(id) == nil)
local okDup = HorseService.voltLektionsBegaran(p, id, "start", base + 3, "serpentin")
check("the same sequence with another type is refused", okDup == false)

rakt(U, 4)
local okV = request("start", "volt")
local okVF = request("finish", "volt")
local okH = request("start", "halt")
local okHF = request("finish", "halt")
local okO = request("start", "overgang")
local okOF = request("finish", "overgang")
local okS = request("start")
local okSF, _, sf = request("finish")
check("circle, start/halt, transitions and serpentine all start and finish", okV == true and okVF == true
	and okH == true and okHF == true and okO == true and okOF == true and okS == true and okSF == true
	and sf.lage == "closed")

local sync = Networking.get("VoltLektionSync")
local toOther = 0
for _, rad in ipairs(sync._skickat) do if rad[1] ~= p then toOther += 1 end end
check("owner events only to the owner", toOther == 0)
check("lesson never writes persistent data", (__datastore.forsok and __datastore.forsok.skriv or 0) == writes)
if fails > 0 then error(tostring(fails) .. " FEL") end
print(string.format("\nSERPENTINLEKTION: %d prov, alla gröna", total))
