--!nostrict
--[[ BOM PÅ MARKEN I SKRITT — docs/GROUND-POLE-LESSON-CONTRACT.md.

	BANK_ONLY, KOHERENS-bänken: riktig HorseService, riktigt byggt ridhus med
	den BEFINTLIGA markbommen `ridhus_hinder_rod_50`, riktig HinderObservation
	och riktig klientmeny (källnivå). Rotens läge sätts mellan hjärtslagen i
	bommens eget system (a längs bommen, w mot C) — syntetisk rutt.

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
local ID = MarkbomLektion.HINDER_ID

local function player(id)
	local c = Instance.new("Model")
	local root = Instance.new("Part"); root.Name = "HumanoidRootPart"; root.Size = vec(2,2,1); root.Parent = c
	local h = Instance.new("Humanoid"); h.Name = "Humanoid"; h.Parent = c
	return { UserId = id, Name = "Markbom" .. id, Character = c,
		CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }
end
local p = Players.LocalPlayer
p.Character = player(991).Character
Players._spelare = { p }
local horse = HastRigg.bygg("markbom_test", "Markbom test", CFrame.new(Ridhusplats.tillVarld(RP, vec(0, 0, 4))))
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
	return HorseService.voltLektionsBegaran(p, id, op, seq, typ or "markbom")
end
local function image()
	local ok, _, b = HorseService.voltLektionsBegaran(p, id, "sync", nil, "markbom"); assert(ok); return b
end
local intentSeq = 0
local function aid(handling)
	s.sisteHjalp = -math.huge
	s.intentPolletter = Config.RIDINPUT.SkopaTak
	intentSeq += 1
	Networking.get("RidingIntent").OnServerEvent:Fire(p, id, handling, intentSeq)
end

-- ── Bommen och dess system (ur lektionens egen referens) ──
local bom
for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("BasePart") and d:GetAttribute("HinderId") == ID then bom = d end
end
check("KONTROLL: the existing ground pole is built and registered", bom ~= nil
	and HinderObservation.register().hinder[ID] ~= nil)
aid("driv") -- skritt
local okS0, _, b0 = request("start")
check("start opens a ground-pole attempt in the approach", okS0 and b0.lage == "approach"
	and b0.typ == "markbom" and HorseService.forsok(b0.forsokId).ovning == "markbom")
local ref = b0.referens
request("finish")
local reg = HinderObservation.register()
local c50 = Ridhusplats.tillLokal(RP, vec(reg.hinder[ID].x, reg.hinder[ID].y, reg.hinder[ID].z))
check("the lesson uses the ground pole rod_50, never a raised pole",
	math.abs(ref.u - c50.X) < 1e-6 and math.abs(ref.v - c50.Z) < 1e-6
	and reg.hinder["ridhus_hinder_bla_24"] ~= nil)
check("the intended direction points towards C", ref.wv > 0)

local nu = { a = 0, w = -12 }
local function ga(a, w, dt)
	step(ref.u + ref.au * a + ref.wu * w, ref.v + ref.av * a + ref.wv * w, dt)
	nu = { a = a, w = w }
end
--[[ Rakt i bommens system i skrittsteg (0,35 m). ]]
local function till(a, w, m)
	m = m or 0.35
	local d = math.sqrt((a - nu.a) ^ 2 + (w - nu.w) ^ 2)
	local n = math.max(1, math.ceil(d / m))
	local a0, w0 = nu.a, nu.w
	for i = 1, n do ga(a0 + (a - a0) * i / n, w0 + (w - w0) * i / n) end
end
--[[ Runt bommen utanför zonen (|a| > 2,5) till (a, w). ]]
local function runt(a, w)
	till(4.5, nu.w, 1); till(4.5, w, 1); till(a, w, 1)
end
ga(0, -12)
runt(0, -12)

-- ── En passage FÖRE Start räknas aldrig ──
till(0, 5) -- inridning, passage och utridning före Start
local okS1 = request("start")
till(0, 7)
check("a passage completed before Start never counts", okS1 == true and image().lage == "approach"
	and image().progress == 0)
request("finish")

-- ── Ett försök som redan var öppet vid Start räknas aldrig ──
runt(0, -1.5) -- in i zonen: HinderObservation öppnar ett försök
request("start")
till(0, 5)
check("an attempt already open at Start never becomes fresh evidence", image().lage ~= "complete")
request("finish")

-- ── Hela sekvensen ──
runt(0, -9)
request("start")
ga(0, -8.6) -- ETT prov (R1): armeringen
check("the first walk step in the corridor arms without credit", image().lage == "approach"
	and image().tips == "walk_to_pole" and image().progress == 0)
till(0, -8)
check("subsequent forward walk earns approach progress", image().progress > 0)
till(0, -4)
check("4 m of fresh walk leads to the crossing", image().lage == "crossing")
till(0, 4)
local done = image()
check("approach, crossing towards C and exit completes", done.lage == "complete")
check("completion is slutford", HorseService.forsok(done.forsokId).orsak == "slutford")
check("frozen result: pole, generation, attempt nr, metres and no contact claim",
	done.resultat ~= nil and table.isfrozen(done.resultat) and done.resultat.hinderId == ID
	and done.resultat.generation == reg.hinder[ID].generation and done.resultat.hinderForsokNr ~= nil
	and done.resultat.inridningM >= 4 and done.resultat.utridningM >= 1
	and done.resultat.passage == "rotplan" and done.resultat.kontakt == "otillganglig"
	and done.resultat.rivning == false)
till(0, 6)
check("later riding cannot change the frozen result", image().resultat == done.resultat)

-- ── Fel riktning, vid sidan om ──
request("retry")
runt(0, 7)
till(0, -9)
check("crossing from the C side never completes", image().lage ~= "complete"
	and image().lage == "approach")
runt(1.8, -9)
till(1.8, 4)
check("crossing beside the pole end gives beside_pole", image().lage == "approach"
	and image().tips == "beside_pole")

-- ── Planet: bokstavligt på planet, inom SID_TOL, och vända ──
runt(0, -9)
till(0, -0.35)
ga(0, 0); ga(0, 0.05); ga(0, 0) -- på planet och inom SID_TOL (0,083 m)
till(0, -1.6)
check("reaching the plane and turning back resets and never completes",
	image().lage == "approach" and image().lage ~= "complete")

-- ── Stillastående, darrning, trav, halt, galopp ──
runt(0, -9)
ga(0, -8.6)
--[[ Armeringen sker redan på vägen in (`runt` slutar i korridoren), så steget
	till −8,6 är ett krediterat skrittsteg. Det som prövas är att stillastående
	och darrning INTE lägger till något därefter. ]]
local fore = image().progress
check("KONTROLL: armed in approach before standing still", image().lage == "approach")
for _ = 1, 10 do ga(nu.a, nu.w) end
for i = 1, 8 do ga(if i % 2 == 0 then 0.05 else -0.05, nu.w) end
check("standing still and jitter add no approach", image().progress == fore)
till(0, -7)
aid("driv") -- trav
ga(0, -6.2)
check("trot in the approach resets", image().lage == "approach" and image().tips == "walk_only")
aid("broms") -- skritt
runt(0, -9)
till(0, -6)
aid("broms") -- halt
ga(0, -5.8)
check("a halt in the approach resets; nothing halted is banked", image().progress == 0
	and image().tips == "walk_on")
till(0, -4)
check("halted travel never arms or credits", image().progress == 0)
aid("driv") -- skritt
runt(0, -9)
till(0, -4)
aid("driv"); aid("driv") -- trav, galopp
till(0, 4, 1.4)
check("a canter over the pole resets and never completes", image().lage ~= "complete")
aid("broms"); aid("broms") -- skritt

-- ── Teleport, flyttad bom, borttagen och återlagd bom ──
runt(0, -9)
till(0, -5)
ga(0, 6) -- teleport
check("a teleport resets the evidence", image().lage == "approach" and image().tips == "unknown")
runt(0, -9)
till(0, 4)
check("fresh recovery after the break completes", image().lage == "complete")

request("retry")
runt(0, -9)
till(0, -5)
local cf0, pos0 = bom.CFrame, bom.Position
bom.CFrame = cf0 + vec(0, 0, 1); bom.Position = pos0 + vec(0, 0, 1)
ga(0, -4.8)
check("a moved pole makes the evidence unusable", image().lage == "approach"
	and image().tips == "pole_missing")
bom.CFrame = cf0; bom.Position = pos0
ga(0, -4.6)
check("back in place, a fresh approach is needed", image().lage == "approach" and image().progress == 0)
local gen0 = HinderObservation.register().hinder[ID].generation
local forald = bom.Parent
-- Bänken avfyrar inte signalerna vid Parent-byte (som hinderobservation.spec).
workspace.DescendantRemoving:Fire(bom)
bom.Parent = nil
ga(0, -4.4)
check("a removed pole gives pole_missing", image().tips == "pole_missing")
bom.Parent = forald
workspace.DescendantAdded:Fire(bom)
check("KONTROLL: the re-added pole is a new registration",
	HinderObservation.register().hinder[ID] ~= nil and HinderObservation.register().hinder[ID].generation > gen0)
ga(0, -4.2)
check("an identical replacement does not reuse earlier evidence", image().lage == "approach"
	and image().progress == 0)

-- ── R1: vridning och ändrade mått på plats, och guiden ──
runt(0, -9)
ga(0, -8.6)
till(0, -6)
local cfR, posR, storR = bom.CFrame, bom.Position, bom.Size
bom.CFrame = cfR * CFrame.Angles(0, math.rad(20), 0) -- vriden kring samma centrum
ga(0, -5.8)
check("R1: a pole rotated in place is unusable, never the old plane", image().lage == "approach"
	and image().tips == "pole_missing" and image().referens == nil)
bom.CFrame = cfR
ga(0, -5.6)
check("R1: restored, the evidence is fresh and the guide reference returns", image().progress == 0
	and image().referens ~= nil)
runt(0, -9); ga(0, -8.6); till(0, -6)
bom.Size = storR + vec(0, 0.6, 0) -- högre överkant, samma läge
ga(0, -5.8)
check("R1: a resized pole (height) in place is unusable", image().tips == "pole_missing"
	and image().referens == nil)
bom.Size = storR
runt(0, -9); ga(0, -8.6); till(0, -6)
bom.Size = storR + vec(0.5, 0, 0) -- bredare, samma läge
ga(0, -5.8)
check("R1: a resized pole (width) in place is unusable", image().tips == "pole_missing")
bom.Size = storR

-- Guiden på klienten: borttagen när bommen saknas, förnyad när en giltig
-- ändrad registrering kommer i SAMMA ram och SAMMA fas, orörd annars.
local V = VoltLektionController
V.avbryt(); V.start(id, nil)
V.valj("markbom")
local g0 = workspace:FindFirstChild("Voltguide")
check("KONTROLL: the ground-pole guide is drawn", g0 ~= nil)
V.valj("markbom")
check("R1: an unchanged sample does not rebuild the guide", workspace:FindFirstChild("Voltguide") == g0)
local forald2 = bom.Parent
workspace.DescendantRemoving:Fire(bom); bom.Parent = nil
ga(nu.a, nu.w)
V.valj("markbom")
check("R1: a missing pole removes the guide", image().referens == nil
	and workspace:FindFirstChild("Voltguide") == nil)
bom.CFrame = cfR + vec(0, 0, 3); bom.Position = posR + vec(0, 0, 3)
bom.Parent = forald2; workspace.DescendantAdded:Fire(bom)
ga(nu.a, nu.w)
local nyckel1 = image().referens and image().referens.nyckel
V.valj("markbom")
local g1 = workspace:FindFirstChild("Voltguide")
check("R1: a changed valid pole in the same frame and phase refreshes the guide",
	image().lage == "approach" and nyckel1 ~= nil and g1 ~= nil and g1 ~= g0)
-- Uppföljning (#5856139668): en BEFINTLIG guide ersätts av en giltig ändrad
-- registrering utan en mellanliggande leverans utan referens — borttagning och
-- återläggning sker mellan två lektionssteg, så steget ser bara nyckelbytet.
check("KONTROLL: a guide exists before the in-step replacement", workspace:FindFirstChild("Voltguide") == g1)
workspace.DescendantRemoving:Fire(bom); bom.Parent = nil
bom.CFrame = cfR; bom.Position = posR
bom.Parent = forald2; workspace.DescendantAdded:Fire(bom)
ga(nu.a, nu.w)
local nyckel2 = image().referens and image().referens.nyckel
V.valj("markbom")
local g2 = workspace:FindFirstChild("Voltguide")
check("R1 follow-up: a changed registration with no missing-reference delivery replaces the guide",
	nyckel2 ~= nil and nyckel2 ~= nyckel1 and g2 ~= nil and g2 ~= g1)
V.avbryt()

-- ── Tidsgräns, begäranbok, alla lektioner ──
s.voltLektion.deadline = os.clock()
ga(nu.a, nu.w)
local timed = image()
check("deadline gives incomplete, never success", timed.lage == "timeout"
	and HorseService.forsok(timed.forsokId).orsak == "tidsgrans")
request("finish")
local base = seq
HorseService.voltLektionsBegaran(p, id, "start", base + 1, "markbom")
HorseService.voltLektionsBegaran(p, id, "finish", base + 2, "markbom")
HorseService.voltLektionsBegaran(p, id, "start", base + 3, "galopp")
HorseService.voltLektionsBegaran(p, id, "finish", base + 4, "galopp")
seq = base + 4
HorseService.voltLektionsBegaran(p, id, "start", base + 1, "markbom")
check("a delayed old ground-pole start after a type switch opens no attempt", RidForsok.aktivt(id) == nil)
local okDup = HorseService.voltLektionsBegaran(p, id, "start", base + 3, "markbom")
check("the same sequence with another type is refused", okDup == false)

step(0, 20); step(0, 12); step(0, 6); step(0, 4)
local alla = true
for _, t in ipairs({ "volt", "halt", "overgang", "serpentin", "tempo", "vag_mitt", "vag_diag",
	"halvvolt", "galopp", "markbom" }) do
	local okS = request("start", t)
	local okF, _, bf = request("finish", t)
	if not (okS == true and okF == true and bf.lage == "closed") then alla = false end
end
check("all ten lesson types start and finish", alla)

-- ── Menyn: tio lektioner bredvid 0..3 kortknappar (källnivå) ──
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
	{ vag = { "lektionsval.gangart" }, text = "tempolektion.choose", slut = "tempolektion.finish" },
	{ vag = { "lektionsval.gangart", "lektionsval.overgangar" }, text = "overganglektion.choose", slut = "overganglektion.finish" },
	{ vag = { "lektionsval.gangart", "lektionsval.overgangar" }, text = "galopplektion.choose", slut = "galopplektion.finish" },
	{ vag = { "lektionsval.vagar", "lektionsval.bojda" }, text = "serpentinlektion.choose", slut = "serpentinlektion.finish" },
	{ vag = { "lektionsval.vagar", "lektionsval.bojda" }, text = "halvvoltlektion.choose", slut = "halvvoltlektion.finish" },
	{ vag = { "lektionsval.vagar", "lektionsval.linjer" }, text = "vaglektion.choose_mitt", slut = "vaglektion.finish" },
	{ vag = { "lektionsval.vagar", "lektionsval.linjer" }, text = "vaglektion.choose_diag", slut = "vaglektion.finish" },
	{ vag = { "lektionsval.vagar", "lektionsval.linjer" }, text = "markbomlektion.choose", slut = "markbomlektion.finish" },
}
local menyOk, ryms = true, true
for n = 0, 3 do
	for _, bl in ipairs(blad) do
		V.avbryt(); V.start("markbom-meny-" .. n .. "-" .. bl.text, nil)
		UgnetaController.satLektionsVal(V.panel)
		kort(n)
		local sida = UgnetaController.panel(KAP).knappar
		if #sida > KAP then ryms = false end
		local oppna = hitta(sida, Sprak.t("lektionsval.oppna"))
		if oppna then oppna.skicka(); sida = UgnetaController.panel(KAP).knappar end
		for _, g in ipairs(bl.vag) do
			if #sida > KAP then ryms = false end
			local k = hitta(sida, Sprak.t(g))
			if not k then menyOk = false; break end
			k.skicka(); sida = UgnetaController.panel(KAP).knappar
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
check("the tenth lesson and every old leaf are selectable beside 0..3 cards", menyOk)
check("every composed page fits the four-row renderer", ryms)
V.avbryt(); V.start("markbom-meny-tillbaka", nil)
-- Som LektionController gör efter varje start: `avbryt` släpper lektionsvalet.
UgnetaController.satLektionsVal(V.panel)
kort(0)
for _, g in ipairs({ "lektionsval.vagar", "lektionsval.linjer" }) do
	local k = hitta(UgnetaController.panel(KAP).knappar, Sprak.t(g))
	if k then k.skicka() end
end
local tb = hitta(UgnetaController.panel(KAP).knappar, Sprak.t("lektionsval.tillbaka"))
if tb then tb.skicka() end
check("Back from the lines-and-pole subgroup returns to Riding paths",
	-- Sedan Genom hörnet ligger halvvolten under Böjda vägar; Ridvägar visar gruppen.
	hitta(UgnetaController.panel(KAP).knappar, Sprak.t("lektionsval.bojda")) ~= nil)
UgnetaController.dolj()

local sync = Networking.get("VoltLektionSync")
local toOther = 0
for _, rad in ipairs(sync._skickat) do if rad[1] ~= p then toOther += 1 end end
check("owner events only to the owner", toOther == 0)
check("lesson never writes persistent data", (__datastore.forsok and __datastore.forsok.skriv or 0) == writes)
if fails > 0 then error(tostring(fails) .. " FEL") end
print(string.format("\nMARKBOMLEKTION: %d prov, alla gröna", total))
