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

-- ── R1: observationsbrott lämnar ingen återanvändbar bevisning ──
-- (Finish med typ "halt" avslutar den pågående voltlektionen: avsluta gäller
-- alltid den lektion som faktiskt pågår.)
local function borja()
	request("finish")
	local okB, _, bB = request("start")
	return okB == true and bB.lage == "halt1"
end
local function haltOchSkritt(u, v)
	still(u, v, G.HALT_FORE + 0.5)
	aid("driv")
end
local function avslutaIX()
	aid("broms")
	still(X.u, X.v, G.HALT_EFTER + 0.75)
end

check("R1 setup: fresh halt attempt", borja())
haltOchSkritt(X.u - 6, X.v - 11)
for v = X.v - 10, X.v - 6 do step(X.u - 6, v) end
step(X.u, X.v) -- teleport into X (far above the per-step limit)
avslutaIX()
check("4 m before a teleport into X never completes", image().lage ~= "complete")
still(X.u, X.v, G.HALT_FORE + 0.5)
aid("driv")
for v = X.v + 1, X.v + 3 do step(X.u, v) end
for v = X.v + 2, X.v, -1 do step(X.u, v) end
avslutaIX()
check("fresh post-break evidence recovers without Retry", image().lage == "complete")

check("R1 setup: gap attempt", borja())
haltOchSkritt(X.u, X.v - 6)
for v = X.v - 5, X.v - 3 do step(X.u, v) end
step(X.u, X.v - 3, 5) -- observation gap
for v = X.v - 2, X.v do step(X.u, v) end
avslutaIX()
check("walking split around a gap is not joined", image().lage ~= "complete")

check("R1 setup: missing-root attempt", borja())
haltOchSkritt(X.u, X.v - 6)
for v = X.v - 5, X.v - 1 do step(X.u, v) end
local rot = s.rig.root
local forald = rot.Parent
rot.Parent = nil; s.energi = 1; Run.Heartbeat:Fire(0.25); rot.Parent = forald
avslutaIX()
check("a missing root breaks the walking evidence", image().lage ~= "complete")

-- MODULKONTRAKT, inte produktionsväg: HorseService släpper aldrig igenom
-- dt = 0 (4 Hz-ackumulatorn), så det ogiltiga dt:t matas direkt till
-- RidObservation. Det räknas upp utan att `tid` ändras.
check("R1 setup: invalid-dt attempt", borja())
haltOchSkritt(X.u, X.v - 6)
for v = X.v - 5, X.v - 1 do step(X.u, v) end
local tidFore = HorseService.ridobservation(id).tid
RidObservation.sampla(id, point(X.u, X.v - 1), 0, "walk", false, 33)
check("KONTROLL: invalid dt leaves observation time unchanged",
	HorseService.ridobservation(id).tid == tidFore)
avslutaIX()
check("invalid dt with unchanged time still resets the evidence", image().lage ~= "complete")

-- ENHETSGRÄNS, inte spelarväg: en trötthetsövergång till skritt injiceras i
-- RidLogg och i den accepterade gångarten, eftersom tröttheten i banken
-- inte kan framkallas på bestämd plats.
check("R1 setup: fatigue attempt", borja())
still(X.u, X.v - 6, G.HALT_FORE + 0.5)
RidLogg.gangart(id, { fran = "halt", franRyggar = false, till = "walk", tillRyggar = false,
	orsak = "trotthet" }, os.clock())
s.stegIndex = Ridtrappa.index("walk")
for v = X.v - 5, X.v do step(X.u, v) end
RidLogg.gangart(id, { fran = "walk", franRyggar = false, till = "halt", tillRyggar = false,
	orsak = "hjalp" }, os.clock())
s.stegIndex = Ridtrappa.index("halt")
still(X.u, X.v, G.HALT_EFTER + 0.75)
check("a fatigue-only walk is not walking evidence", image().lage ~= "complete")

check("R1 setup: frame-change attempt", borja())
haltOchSkritt(X.u, X.v - 6)
for v = X.v - 5, X.v - 3 do step(X.u, v) end
local hus = workspace:FindFirstChild("Anläggning"):FindFirstChild("UBRF")
local bana, lay = hus:FindFirstChild("Ridbanan"), hus:FindFirstChild("Dressyrlayout 20x60")
local d = vec(0, 0, 0.5)
bana.CFrame = CFrame.new(bana.Position + d); lay.CFrame = CFrame.new(lay.Position + d)
step(X.u, X.v - 2)
local efterRam = image()
check("a frame change returns to the first task", efterRam.lage == "halt1" and efterRam.tips == "unknown")
bana.CFrame = CFrame.new(bana.Position - d); lay.CFrame = CFrame.new(lay.Position - d)
step(X.u, X.v - 2)

-- ── R1: rittens begäranbok överlever typbyte ──
request("finish")
local base = seq
HorseService.voltLektionsBegaran(p, id, "start", base + 1, "halt")
HorseService.voltLektionsBegaran(p, id, "finish", base + 2, "halt")
HorseService.voltLektionsBegaran(p, id, "start", base + 3, "volt")
HorseService.voltLektionsBegaran(p, id, "finish", base + 4, "volt")
seq = base + 4
HorseService.voltLektionsBegaran(p, id, "start", base + 1, "halt")
check("a delayed old halt start after a type switch opens no attempt", RidForsok.aktivt(id) == nil)
local okDiff, felDiff = HorseService.voltLektionsBegaran(p, id, "finish", base + 4, "halt")
check("same sequence and operation with another type is refused", okDiff == false and felDiff == "request")
local objFore = s.voltLektion
local okBad, felBad = HorseService.voltLektionsBegaran(p, id, "start", 2.5, "halt")
check("an invalid sequence on a type switch changes no lesson state", okBad == false
	and felBad == "request" and s.voltLektion == objFore)
local okH = request("start")
local okHF, _, hf = request("finish")
local okV = request("start", "volt")
local okVF = request("finish", "volt")
check("ordinary volt -> halt -> volt selection and Finish still work", okH == true and okHF == true
	and hf.lage == "closed" and okV == true and okVF == true)

-- ── C1 R1: återkopplingen genom den RIKTIGA panelen (VoltLektionController) ──
--[[ Bilderna är producentens egna (HorseService.voltLektionsBegaran sync) och
	levereras genom den riktiga lyssnaren på `VoltLektionSync`; texten läses
	ur `VoltLektionController.panel()` — anropsstället — och ur Ugnetas
	sammansatta sida med 0..3 kortknappar (MAX_VAL = 4). ]]
do
	local VC = VoltLektionController
	local syncC = Networking.get("VoltLektionSync")
	local function hitta(lista, txt)
		for _, k in ipairs(lista) do if k.text == txt then return k end end
		return nil
	end
	local function leverera(b) syncC.OnClientEvent:Fire(b) end
	local function panelText() local sida = VC.panel(); return sida and sida.text end
	local function har(t, del) return type(t) == "string" and string.find(t, del, 1, true) ~= nil end
	local function tal1(x) return (string.gsub(string.format("%.1f", x), "%.", ",")) end
	Sprak.satVal("sv")
	UgnetaController.dolj()
	VC.avbryt(); VC.start(id, nil)
	UgnetaController.satLektionsVal(VC.panel)
	VC.valj("halt")
	request("finish")
	-- Ett riktigt slutfört halt-försök (samma väg som den lyckliga vägen ovan).
	still(0, 18, 1) -- hästen står vid starten FÖRE Start: ingen förflyttning bryter försöket
	request("start")
	still(0, 18, G.HALT_FORE + 0.5)
	aid("driv")
	for v = 19, X.v - 1 do step(X.u, v) end
	aid("broms")
	still(X.u, X.v - 0.5, G.HALT_EFTER + 0.75)
	local klar = image()
	check("KONTROLL C1: a real completed halt attempt", klar.lage == "complete" and klar.resultat ~= nil)
	leverera(klar)
	local t = panelText()
	check("C1: the panel shows the frozen result's walked metres and the next step",
		har(t, tal1(klar.resultat.skrittMeter)) and har(t, Sprak.t("aterkoppling.halt.nasta")))
	local sida = UgnetaController.panel(4)
	check("C1: the composed page keeps Retry and Finish within capacity", #sida.knappar <= 4
		and hitta(sida.knappar, Sprak.t("voltlektion.retry")) ~= nil
		and hitta(sida.knappar, Sprak.t("haltlektion.finish")) ~= nil)
	UgnetaController.visa("Kort", {}, true, nil, true, true) -- tre äldre kortknappar
	sida = UgnetaController.panel(4)
	check("C1: beside three legacy card buttons the page fits, keeps Retry, and the text is unchanged",
		#sida.knappar <= 4 and hitta(sida.knappar, Sprak.t("voltlektion.retry")) ~= nil and panelText() == t)
	UgnetaController.dolj()
	leverera(klar)
	check("C1: a duplicate snapshot gives the same single summary", panelText() == t)
	Sprak.satVal("en")
	local tEn = panelText()
	check("C1: a locale switch redraws the words from the same attempt",
		har(tEn, "Next time") and tEn ~= t)
	Sprak.satVal("sv")

	-- Retry: nytt försök, inget resultat, ingen gammal sammanfattning.
	request("retry")
	local ny = image()
	leverera(ny)
	check("C1: after Retry the new attempt never shows the previous summary",
		ny.resultat == nil and not har(panelText(), tal1(klar.resultat.skrittMeter))
		and not har(panelText(), Sprak.t("aterkoppling.halt.nasta")))
	-- Timeout efter ett lyckat försök.
	s.voltLektion.deadline = os.clock()
	step(X.u, X.v)
	local slut = image()
	check("KONTROLL C1: the next attempt timed out", slut.lage == "timeout")
	leverera(slut)
	t = panelText()
	check("C1: timeout after a success is neutral with a retry hint, no borrowed result",
		har(t, Sprak.t("aterkoppling.halt.igen")) and not har(t, tal1(klar.resultat.skrittMeter))
		and not har(t, Sprak.t("aterkoppling.halt.nasta")))
	-- En försenad äldre bild (lägre revision) ersätter inte timeouten.
	leverera(klar)
	check("C1: a delayed older complete snapshot does not replace the timeout", panelText() == t)
	-- Stängt efter ett lyckat försök.
	request("finish")
	local stangd = image()
	leverera(stangd)
	check("C1: closed shows the ordinary text, never an old result",
		stangd.lage == "closed" and not har(panelText(), tal1(klar.resultat.skrittMeter)))
	-- En annan ritt: kontrollern tar inte emot den gamla rittens bild.
	VC.avbryt(); VC.start("annan-ritt-c1", nil); VC.valj("halt")
	leverera(klar)
	local ann = VC.panel()
	check("C1: another ride never shows this ride's result",
		ann == nil or not har(ann.text, tal1(klar.resultat.skrittMeter)))
	VC.avbryt()
	UgnetaController.satLektionsVal(nil)
end

local sync = Networking.get("VoltLektionSync")
local toOther = 0
for _, rad in ipairs(sync._skickat) do if rad[1] ~= p then toOther += 1 end end
check("owner events only to the owner", toOther == 0)
check("lesson never writes persistent data", (__datastore.forsok and __datastore.forsok.skriv or 0) == writes)
if fails > 0 then error(tostring(fails) .. " FEL") end
print(string.format("\nHALTLEKTION: %d prov, alla gröna", total))
