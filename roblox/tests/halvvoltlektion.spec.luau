--!nostrict
--[[ HALVVOLT TILLBAKA TILL SPÅRET — docs/HALF-CIRCLE-LESSON-CONTRACT.md.

	BANK_ONLY, KOHERENS-bänken: riktig HorseService, riktigt byggt ridhus,
	riktiga observationer och den riktiga klientmenyn (källnivå).
	Gångarten ändras genom produktionens `RidingIntent`; rotens läge sätts
	mellan hjärtslagen (syntetisk rutt, inte spelarens ridning).

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
local G = HalvvoltLektion.GRANSER

local function player(id)
	local c = Instance.new("Model")
	local root = Instance.new("Part"); root.Name = "HumanoidRootPart"; root.Size = vec(2,2,1); root.Parent = c
	local h = Instance.new("Humanoid"); h.Name = "Humanoid"; h.Parent = c
	return { UserId = id, Name = "Halvvolt" .. id, Character = c,
		CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }
end
local p = Players.LocalPlayer
p.Character = player(971).Character
Players._spelare = { p }
local horse = HastRigg.bygg("halvvolt_test", "Halvvolt test", CFrame.new(Ridhusplats.tillVarld(RP, vec(0, 0, 4))))
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
	return HorseService.voltLektionsBegaran(p, id, op, seq, typ or "halvvolt")
end
local function image()
	local ok, _, b = HorseService.voltLektionsBegaran(p, id, "sync", nil, "halvvolt"); assert(ok); return b
end
local intentSeq = 0
local function aid(handling)
	s.sisteHjalp = -math.huge
	s.intentPolletter = Config.RIDINPUT.SkopaTak
	intentSeq += 1
	Networking.get("RidingIntent").OnServerEvent:Fire(p, id, handling, intentSeq)
end
local U = HorseService.ridplats(id).dressyrMitt.u
local uT = U + G.SPAR_DU
local nu = { u = 0, v = 4 }
local function ga(u, v, dt) step(u, v, dt); nu = { u = u, v = v } end
local function rakt(u, v)
	local n = math.max(1, math.ceil(math.sqrt((u - nu.u) ^ 2 + (v - nu.v) ^ 2)))
	local u0, v0 = nu.u, nu.v
	for i = 1, n do ga(u0 + (u - u0) * i / n, v0 + (v - v0) * i / n) end
end
--[[ Punkten på vägen vid S; skarvarna T1, H och slutet E är bokstavliga. ]]
local SK1, SK2 = G.L1, G.L1 + G.L2
local function vag(S)
	if S == SK1 then return uT, G.T1_V end
	if S == SK2 then return uT - 2 * G.R, G.T1_V end
	if S == G.LANGD then return uT, G.E_V end
	if S < SK1 then return uT, G.P0_V + S end
	if S < SK2 then
		local th = (S - SK1) / G.R
		return uT - G.R + G.R * math.cos(th), G.T1_V + G.R * math.sin(th)
	end
	local s3 = S - SK2
	return uT - 2 * G.R + 2 * G.R * s3 / G.L3, G.T1_V - (G.T1_V - G.E_V) * s3 / G.L3
end
--[[ Längs vägen från S0 till S1 i steg om högst 0,9 m, genom skarvarna. ]]
local function rutt(S0, S1)
	local punkter = {}
	local n = math.max(1, math.ceil(math.abs(S1 - S0) / 0.9))
	for i = 1, n do table.insert(punkter, S0 + (S1 - S0) * i / n) end
	for _, sk in ipairs({ SK1, SK2 }) do
		if (sk - S0) * (sk - S1) < 0 then table.insert(punkter, sk) end
	end
	table.sort(punkter, function(a, b) return if S1 >= S0 then a < b else a > b end)
	if S1 == G.LANGD then punkter[#punkter] = G.LANGD end
	for _, S in ipairs(punkter) do ga(vag(S)) end
end
--[[ Utanför vägen tillbaka till spåret 3 m bakom startringen. ]]
local function tillStart()
	rakt(U - 9, nu.v); rakt(U - 9, 11); rakt(uT, 11); rakt(uT, G.P0_V - 3)
end

-- ── Hela figuren; armering i ringens bakre halva med haltpaus ──
aid("driv") -- skritt
local ok, _, b = request("start")
check("start opens a half-circle attempt", ok and b.lage == "to_start" and b.typ == "halvvolt")
check("half-circle attempt has its own definition", HorseService.forsok(b.forsokId).ovning == "halvvolt")
tillStart()
ga(uT, G.P0_V - 1.9) -- exakt −1,9: bakre halvan
check("arming at the literal rear-half point gives no credit", image().lage == "route"
	and image().progress == 0 and image().delmal == 1)
aid("broms")
for _ = 1, 3 do ga(nu.u, nu.v) end
check("a halt right after rear-half arming is a pause, not reverse", image().lage == "route")
aid("driv")
for _, d in ipairs({ -1.7, -1.5, -1.2 }) do ga(uT, G.P0_V + d) end
check("small forward steps below -1 keep the route", image().lage == "route" and image().tips ~= "reverse")
rutt(-1.2, G.LANGD)
local done = image()
check("the full figure through the literal joins completes", done.lage == "complete")
check("completion is slutford", HorseService.forsok(done.forsokId).orsak == "slutford")
check("frozen result: figure, arming point, metres and both joins", done.resultat ~= nil
	and table.isfrozen(done.resultat) and done.resultat.figur == "halvvolt"
	and math.abs(done.resultat.armS - -1.9) < 1e-6
	and math.abs(done.resultat.slutS - G.LANGD) < 1e-6
	and math.abs(done.resultat.meter - (done.resultat.slutS - done.resultat.armS)) < 1e-9
	and #done.resultat.skarvar == 2)
rakt(uT - 3, 20)
check("later riding cannot change the frozen result", image().resultat == done.resultat)

-- ── Projektionens gränser (provkrok på den riktiga projektionen) ──
local ref = done.referens
local proj = HalvvoltLektion._projiceraForProv
local function nara(S, mal, tol) return S ~= nil and math.abs(S - mal) < (tol or 1e-6) end
local sT1, tT1 = proj(ref, uT, G.T1_V)
local sH, tH = proj(ref, uT - 2 * G.R, G.T1_V)
check("literal join T1 projects to L1, unambiguous", nara(sT1, SK1) and tT1 == false)
check("literal join H projects to L1 + 5pi, never to L1 - 5pi", nara(sH, SK2) and tH == false)
check("the top of the half-circle projects to its middle", nara(proj(ref, uT - G.R, G.T1_V + G.R), SK1 + G.L2 / 2))
check("the chord middle (the centre) is outside the corridor", proj(ref, uT - G.R, G.T1_V) == nil)
check("a point just below the diameter projects to an arc end", nara(proj(ref, uT - 0.2, G.T1_V - 0.1), SK1, 0.25))
local sa, ta = proj(ref, uT - 2 * G.R + 1e-9, G.T1_V)
local sb, tb = proj(ref, uT - 2 * G.R - 1e-9, G.T1_V)
local sc, tc = proj(ref, uT - 2 * G.R, G.T1_V - 1e-9)
check("points 1e-9 around H stay unambiguous at the join", nara(sa, SK2, 0.01) and nara(sb, SK2, 0.01)
	and nara(sc, SK2, 0.01) and not ta and not tb and not tc)
check("the literal end E projects to the full length", nara(proj(ref, uT, G.E_V), G.LANGD))

-- ── Genväg, bara slutringen, baklänges, bakåt, stillastående ──
request("retry")
tillStart()
rutt(-3, SK1)
for i = 1, 10 do ga(uT - i, G.T1_V) end -- kordan T1 → H
check("the chord shortcut across the half-circle resets", image().lage == "to_start"
	and image().tips == "off_route")
rakt(uT - 1, G.E_V); rakt(uT, G.E_V)
check("visiting only the end ring does not complete", image().lage == "to_start")
ga(vag(G.LANGD))
rutt(G.LANGD, 0)
check("riding the figure backwards from E makes no progress", image().lage ~= "complete"
	and image().progress <= 2)
tillStart()
rutt(-3, 18)
local p18 = image().progress
rutt(18, 16.5)
check("going back along the arc resets", p18 > 0 and image().lage == "to_start" and image().tips == "reverse")
tillStart()
rutt(-3, 0)
for _ = 1, 10 do ga(nu.u, nu.v) end
check("standing still gives no progress", image().lage == "route" and image().progress == 0)

-- ── Galopp, grovt segment, teleport och färsk återhämtning ──
rutt(0, 5)
aid("driv"); aid("driv") -- trav, galopp
rutt(5, 6)
check("canter resets", image().lage == "to_start" and image().tips == "walk_or_trot")
aid("broms"); aid("broms") -- skritt
tillStart()
rutt(-3, 5)
ga(uT, G.P0_V + 9.5, 0.5) -- 4,5 m på 0,5 s: under teleportgränsen, över grovgränsen
check("a coarse segment is unknown, never progress", image().lage == "to_start" and image().tips == "unknown")
tillStart()
rutt(-3, 5)
ga(vag(30)) -- teleport
check("a teleport resets, never joins", image().lage == "to_start" and image().progress == 0)
tillStart()
rutt(-3, G.LANGD)
check("fresh recovery after the break completes", image().lage == "complete")

-- ── R1: halt utan kredit kan inte bankas ──
-- Stillastående halt, sedan färsk skritt: fullföljs.
request("retry")
tillStart()
rutt(-3, 5)
local pA = image().progress
aid("broms")
for _ = 1, 5 do ga(nu.u, nu.v) end
check("R1: a stationary halt keeps progress and the route", image().lage == "route" and image().progress == pA)
aid("driv")
rutt(5, G.LANGD)
check("R1: fresh walking after a stationary halt completes", image().lage == "complete")

-- Förflyttning under halt genom skarven T1: tillbaka till start, ingen skarv.
request("retry")
tillStart()
rutt(-3, 8)
aid("broms")
for i = 1, 15 do ga(vag(8 + 0.2 * i)) end -- 8 → 11 m i halt, förbi T1
check("R1: moving through a join during halt returns to the start ring", image().lage == "to_start"
	and image().tips == "halt_moved")
aid("driv")

-- Hela vägen i halt och sedan ett stillastående skrittprov vid E: aldrig klart.
tillStart()
rutt(-3, 0)
aid("broms")
rutt(0, G.LANGD)
aid("driv")
ga(nu.u, nu.v)
check("R1: a full halted traversal then a stationary walk sample does not complete",
	image().lage ~= "complete")
ga(nu.u, nu.v + 0.5)
check("R1: nor does the next moving sample", image().lage ~= "complete")

-- Krediterad bit, tolererad förflyttning i halt (0,4 m), sedan skritt: ingen
-- vinst i efterhand; resultatet skiljer fysiskt slutläge och krediterade meter.
tillStart()
rutt(-3, 5)
local k5 = s.voltLektion.kreditM
aid("broms")
ga(vag(5.2)); ga(vag(5.4))
check("R1: movement within 0.5 m of the halt anchor is tolerated", image().lage == "route")
aid("driv")
ga(nu.u, nu.v)
check("R1: resuming walk on a stationary sample credits nothing", s.voltLektion.kreditM == k5)
rutt(5.4, G.LANGD)
local efterHalt = image()
check("R2: one tolerated pause still completes; its 0.4 m stays uncredited debt",
	efterHalt.lage == "complete" and efterHalt.resultat.slutS >= G.LANGD - G.SLUT_M
	and math.abs(efterHalt.resultat.skuld - 0.4) < 0.05
	and math.abs(efterHalt.resultat.meter
		- (efterHalt.resultat.slutS - efterHalt.resultat.armS - efterHalt.resultat.skuld)) < 1e-6)
rakt(uT - 1, G.E_V - 1)
check("R2: moving on past E inside the end ring cannot change the result", image().resultat == efterHalt.resultat)

-- R2: två åtskilda tillåtna pauser — skulden passerar 0,5 m, försöket går
-- tillbaka till startringen (återhämtningsbart), aldrig ett olåsbart läge.
request("retry")
tillStart()
rutt(-3, 5)
aid("broms")
ga(vag(5.2)); ga(vag(5.4))
check("R2: the first 0.4 m pause is tolerated", image().lage == "route")
aid("driv")
rutt(5.4, 10)
aid("broms")
ga(vag(10.2))
check("R2: a second pause pushing the debt past 0.5 m returns to the start ring",
	image().lage == "to_start" and image().tips == "halt_moved")
aid("driv")
tillStart()
rutt(-3, G.LANGD)
check("R2: after two pauses the route is recoverable and completes", image().lage == "complete")

-- R2: ett litet fram-och-tillbaka efter en paus tar aldrig igen skulden.
request("retry")
tillStart()
rutt(-3, 5)
local kA = s.voltLektion.kreditM
aid("broms")
ga(vag(5.2)); ga(vag(5.4))
aid("driv")
ga(nu.u, nu.v)
rutt(5.4, 5.0)
rutt(5.0, 5.4)
check("R2: walking back and forward over the paused 0.4 m credits nothing",
	image().lage == "route" and s.voltLektion.kreditM == kA)
rutt(5.4, 6)
check("R2: new ground beyond the furthest point is credited",
	math.abs(s.voltLektion.kreditM - (kA + 0.6)) < 1e-6)
rutt(6, G.LANGD)
check("R2: that attempt completes with its debt reported", image().lage == "complete"
	and math.abs(image().resultat.skuld - 0.4) < 0.05)

-- Ofarlig, begränsad darrning i halt: pausen står kvar och figuren fullföljs.
request("retry")
tillStart()
rutt(-3, 5)
local pJ = image().progress
aid("broms")
local ju, jv = nu.u, nu.v
for i = 1, 12 do ga(ju + (if i % 2 == 0 then 0.1 else -0.1), jv) end
check("R1: bounded jitter in halt keeps the route and the progress", image().lage == "route"
	and image().tips ~= "halt_moved" and image().progress == pJ)
aid("driv")
rutt(5, G.LANGD)
check("R1: after the jitter the genuine figure completes", image().lage == "complete")

-- ── Tidsgräns, figurbyte, begäranbok, alla lektioner ──
request("retry")
s.voltLektion.deadline = os.clock()
ga(nu.u, nu.v)
local timed = image()
check("deadline gives incomplete, never success", timed.lage == "timeout"
	and HorseService.forsok(timed.forsokId).orsak == "tidsgrans")
request("retry")
local okByt, felByt = request("start", "vag_mitt")
check("switching to a riding-path figure while active is refused", okByt == false and felByt == "active")
local okFin = request("finish", "vag_mitt")
check("finish acts on the current half-circle", okFin == true and image().lage == "closed")

local base = seq
HorseService.voltLektionsBegaran(p, id, "start", base + 1, "halvvolt")
HorseService.voltLektionsBegaran(p, id, "finish", base + 2, "halvvolt")
HorseService.voltLektionsBegaran(p, id, "start", base + 3, "vag_diag")
HorseService.voltLektionsBegaran(p, id, "finish", base + 4, "vag_diag")
seq = base + 4
HorseService.voltLektionsBegaran(p, id, "start", base + 1, "halvvolt")
check("a delayed old half-circle start after a figure switch opens no attempt", RidForsok.aktivt(id) == nil)
local okDup = HorseService.voltLektionsBegaran(p, id, "start", base + 3, "halvvolt")
check("the same sequence with another type is refused", okDup == false)

rakt(U, 4)
local alla = true
for _, t in ipairs({ "volt", "halt", "overgang", "serpentin", "tempo", "vag_mitt", "vag_diag", "halvvolt" }) do
	local okS = request("start", t)
	local okF, _, bf = request("finish", t)
	if not (okS == true and okF == true and bf.lage == "closed") then alla = false end
end
check("all eight lesson types start and finish", alla)

-- ── Menyn: åtta lektioner bredvid 0..3 kortknappar (källnivå) ──
local V = VoltLektionController
local KAP = 4 -- Naromrades MAX_VAL
local function hitta(lista, txt)
	for _, k in ipairs(lista) do if k.text == txt then return k end end
	return nil
end
local function kort(n)
	UgnetaController.dolj()
	if n > 0 then UgnetaController.visa("Kort", {}, n >= 1, nil, n >= 2, n >= 3) end
end
local blad = {
	{ vag = {}, text = "voltlektion.choose", slut = "voltlektion.finish" },
	{ vag = { "lektionsval.gangart" }, text = "haltlektion.choose", slut = "haltlektion.finish" },
	{ vag = { "lektionsval.gangart", "lektionsval.overgangar" }, text = "overganglektion.choose", slut = "overganglektion.finish" },
	{ vag = { "lektionsval.gangart" }, text = "tempolektion.choose", slut = "tempolektion.finish" },
	{ vag = { "lektionsval.vagar" }, text = "serpentinlektion.choose", slut = "serpentinlektion.finish" },
	{ vag = { "lektionsval.vagar" }, text = "halvvoltlektion.choose", slut = "halvvoltlektion.finish" },
	{ vag = { "lektionsval.vagar", "lektionsval.linjer" }, text = "vaglektion.choose_mitt", slut = "vaglektion.finish" },
	{ vag = { "lektionsval.vagar", "lektionsval.linjer" }, text = "vaglektion.choose_diag", slut = "vaglektion.finish" },
}
local menyOk, ryms = true, true
for n = 0, 3 do
	for _, bl in ipairs(blad) do
		V.avbryt(); V.start("halvvolt-meny-" .. n .. "-" .. bl.text, nil)
		UgnetaController.satLektionsVal(V.panel)
		kort(n)
		local sida = UgnetaController.panel(KAP).knappar
		if #sida > KAP then ryms = false end
		local oppna = hitta(sida, Sprak.t("lektionsval.oppna"))
		if oppna then oppna.skicka(); sida = UgnetaController.panel(KAP).knappar end
		for _, steg in ipairs(bl.vag) do
			if #sida > KAP then ryms = false end
			local g = hitta(sida, Sprak.t(steg))
			if not g then menyOk = false; break end
			g.skicka(); sida = UgnetaController.panel(KAP).knappar
		end
		if #sida > KAP then ryms = false end
		local lov = hitta(sida, Sprak.t(bl.text))
		if not lov then menyOk = false else
			lov.skicka()
			if not (V.lektion() and hitta(UgnetaController.panel(KAP).knappar, Sprak.t(bl.slut))) then
				menyOk = false
			end
		end
	end
end
check("the eighth lesson and every old leaf are selectable beside 0..3 cards", menyOk)
check("every composed page fits the four-row renderer", ryms)
-- Undergruppens Tillbaka leder till Ridvägar, och dess Tillbaka till toppen.
V.avbryt(); V.start("halvvolt-meny-tillbaka", nil)
kort(0)
local g1 = hitta(UgnetaController.panel(KAP).knappar, Sprak.t("lektionsval.vagar"))
if g1 then g1.skicka() end
local g2 = hitta(UgnetaController.panel(KAP).knappar, Sprak.t("lektionsval.linjer"))
if g2 then g2.skicka() end
local tb1 = hitta(UgnetaController.panel(KAP).knappar, Sprak.t("lektionsval.tillbaka"))
if tb1 then tb1.skicka() end
check("Back from the subgroup returns to Riding paths",
	hitta(UgnetaController.panel(KAP).knappar, Sprak.t("halvvoltlektion.choose")) ~= nil)
UgnetaController.dolj()

local sync = Networking.get("VoltLektionSync")
local toOther = 0
for _, rad in ipairs(sync._skickat) do if rad[1] ~= p then toOther += 1 end end
check("owner events only to the owner", toOther == 0)
check("lesson never writes persistent data", (__datastore.forsok and __datastore.forsok.skriv or 0) == writes)
if fails > 0 then error(tostring(fails) .. " FEL") end
print(string.format("\nHALVVOLTLEKTION: %d prov, alla gröna", total))
