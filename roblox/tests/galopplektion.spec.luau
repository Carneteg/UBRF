--!nostrict
--[[ GALOPPFATTNING I GALOPPRINGEN (DELVIS) — docs/CANTER-DEPARTURE-LESSON-CONTRACT.md.

	BANK_ONLY, KOHERENS-bänken: riktig HorseService, riktigt byggt ridhus,
	riktiga observationer och den riktiga klientmenyn (källnivå).
	Gångarten ändras genom produktionens `RidingIntent`; rotens läge sätts
	mellan hjärtslagen längs mittlinjen (syntetisk rutt).

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
local G = GaloppLektion.GRANSER

local function player(id)
	local c = Instance.new("Model")
	local root = Instance.new("Part"); root.Name = "HumanoidRootPart"; root.Size = vec(2,2,1); root.Parent = c
	local h = Instance.new("Humanoid"); h.Name = "Humanoid"; h.Parent = c
	return { UserId = id, Name = "Galopp" .. id, Character = c,
		CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }
end
local p = Players.LocalPlayer
p.Character = player(981).Character
Players._spelare = { p }
local horse = HastRigg.bygg("galopp_test", "Galopp test", CFrame.new(Ridhusplats.tillVarld(RP, vec(0, 0, 4))))
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
	return HorseService.voltLektionsBegaran(p, id, op, seq, typ or "galopp")
end
local function image()
	local ok, _, b = HorseService.voltLektionsBegaran(p, id, "sync", nil, "galopp"); assert(ok); return b
end
local intentSeq = 0
local function aid(handling)
	s.sisteHjalp = -math.huge
	s.intentPolletter = Config.RIDINPUT.SkopaTak
	intentSeq += 1
	Networking.get("RidingIntent").OnServerEvent:Fire(p, id, handling, intentSeq)
end
local function gangart() return Ridtrappa.gangart(s.stegIndex) end
local U = HorseService.ridplats(id).dressyrMitt.u
local nuV = 4
local function ga(v, dt) step(U, v, dt); nuV = v end
--[[ Längs mittlinjen till v i steg om högst `m` meter. ]]
local function linje(v, m)
	local n = math.max(1, math.ceil(math.abs(v - nuV) / m))
	local v0 = nuV
	for i = 1, n do ga(v0 + (v - v0) * i / n) end
end
local function trav(v) linje(v, 0.8) end
local function galopp(v) linje(v, 1.4) end
local function tillGangart(mal)
	for _ = 1, 4 do
		if gangart() == mal then return end
		local i, j = Gaits.index(gangart()), Gaits.index(mal)
		aid(if i < j then "driv" else "broms")
	end
end

-- ── Hela sekvensen: trav ≥ 8 m, galopp i K, galopp ≥ 6 m ──
tillGangart("trot")
check("KONTROLL: trot accepted before Start", gangart() == "trot")
local ok, _, b = request("start")
check("start opens a canter-departure attempt in trot", ok and b.lage == "trot" and b.typ == "galopp")
check("canter-departure attempt has its own definition",
	HorseService.forsok(b.forsokId).ovning == "galoppfattning")
trav(28)
check("trot preparation over 8 m asks for canter at K", image().tips == "canter_at_k")
local fore = s.voltLektion.trav
aid("driv")
ga(28.8)
check("KONTROLL: canter accepted", gangart() == "canter")
check("canter asked inside the ring starts the canter phase", image().lage == "canter")
check("the departure step itself credits neither trot nor canter",
	s.voltLektion.trav == fore and s.voltLektion.galopp == 0)
galopp(36)
local done = image()
check("trot, canter in the ring and 6 m of canter completes", done.lage == "complete")
check("completion is slutford", HorseService.forsok(done.forsokId).orsak == "slutford")
check("frozen result holds identity and the evidence summary, and no lead claim",
	done.resultat ~= nil and table.isfrozen(done.resultat) and done.resultat.rittId == id
	and done.resultat.vidRingen ~= nil and done.resultat.travMeter >= G.TRAV_M
	and done.resultat.galoppMeter >= G.GALOPP_M and done.resultat.galoppsida == "ej_bedomd")
galopp(40)
check("later riding cannot change the frozen result", image().resultat == done.resultat)

-- ── Redan i galopp vid Start, gammal händelse ──
local okR = request("retry")
check("retry opens a fresh attempt in the trot phase", okR == true and image().lage == "trot"
	and image().progress == 0)
galopp(26); galopp(34)
check("already cantering at Start is never preparation or a departure", image().lage == "trot"
	and image().progress == 0)

-- ── Fel plats, för kort trav ──
tillGangart("trot")
trav(10); trav(18)
aid("driv")
ga(18.8) -- utanför K
check("canter asked outside K gives canter_outside and stays in trot", image().lage == "trot"
	and image().tips == "canter_outside")
tillGangart("trot")
tillGangart("walk")
linje(26, 0.4)
tillGangart("trot")
trav(28)
aid("driv")
ga(28.8)
check("canter asked after too little trot gives trot_first", image().lage == "trot"
	and image().tips == "trot_first")
tillGangart("trot")

-- ── Händelse utan giltigt läge (lucka i steget) ──
trav(18); trav(27)
aid("driv")
ga(28.5, 1.5) -- lucka: dt över MAX_DT
check("a canter request whose step breaks with a gap is never a departure",
	image().lage == "trot" and image().tips == "unknown")
tillGangart("trot")

-- ── Trötthet, injicerad trött galopp, stillastående galopp ──
trav(18); trav(28)
aid("driv"); ga(28.8)
check("KONTROLL: valid departure before fatigue", image().lage == "canter")
RidLogg.gangart(id, { fran = "canter", franRyggar = false, till = "trot", tillRyggar = false,
	orsak = "trotthet" }, os.clock())
s.stegIndex = Ridtrappa.index("trot")
ga(29.6)
check("a fatigue-forced drop from canter gives tired", image().lage == "trot" and image().tips == "tired")
trav(20); trav(28)
RidLogg.gangart(id, { fran = "trot", franRyggar = false, till = "canter", tillRyggar = false,
	orsak = "trotthet" }, os.clock())
s.stegIndex = Ridtrappa.index("canter")
ga(28.8)
check("a canter event that is not the rider's aid is never a departure", image().lage == "trot")
s.stegIndex = Ridtrappa.index("trot")
trav(20); trav(28)
aid("driv"); ga(28.8)
for _ = 1, 10 do ga(28.8) end
check("a stationary accepted canter stays incomplete", image().lage == "canter"
	and s.voltLektion.galopp == 0)

-- ── Teleport och färsk återhämtning ──
ga(50) -- teleport
check("a teleport resets to the trot phase", image().lage == "trot" and image().tips == "unknown")
tillGangart("trot")
linje(40, 1) -- trav, 10 m förberedelse
trav(31.5)
aid("driv"); ga(30.7) -- in i K från C-hållet går lika bra
galopp(20)
check("fresh recovery after the break completes", image().lage == "complete")

-- ── Tidsgräns, begäranbok, alla lektioner ──
request("retry")
s.voltLektion.deadline = os.clock()
galopp(44)
local timed = image()
check("deadline gives incomplete, never success", timed.lage == "timeout"
	and HorseService.forsok(timed.forsokId).orsak == "tidsgrans")
request("finish")
local base = seq
HorseService.voltLektionsBegaran(p, id, "start", base + 1, "galopp")
HorseService.voltLektionsBegaran(p, id, "finish", base + 2, "galopp")
HorseService.voltLektionsBegaran(p, id, "start", base + 3, "overgang")
HorseService.voltLektionsBegaran(p, id, "finish", base + 4, "overgang")
seq = base + 4
HorseService.voltLektionsBegaran(p, id, "start", base + 1, "galopp")
check("a delayed old canter start after a type switch opens no attempt", RidForsok.aktivt(id) == nil)
local okDup = HorseService.voltLektionsBegaran(p, id, "start", base + 3, "galopp")
check("the same sequence with another type is refused", okDup == false)

tillGangart("walk")
linje(4, 1)
local alla = true
for _, t in ipairs({ "volt", "halt", "overgang", "serpentin", "tempo", "vag_mitt", "vag_diag",
	"halvvolt", "galopp" }) do
	local okS = request("start", t)
	local okF, _, bf = request("finish", t)
	if not (okS == true and okF == true and bf.lage == "closed") then alla = false end
end
check("all nine lesson types start and finish", alla)

-- ── Menyn: nio lektioner bredvid 0..3 kortknappar (källnivå) ──
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
}
local menyOk, ryms = true, true
for n = 0, 3 do
	for _, bl in ipairs(blad) do
		V.avbryt(); V.start("galopp-meny-" .. n .. "-" .. bl.text, nil)
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
check("the ninth lesson and every old leaf are selectable beside 0..3 cards", menyOk)
check("every composed page fits the four-row renderer", ryms)
V.avbryt(); V.start("galopp-meny-tillbaka", nil)
-- Som LektionController gör efter varje start: `avbryt` släpper lektionsvalet.
UgnetaController.satLektionsVal(V.panel)
kort(0)
local g1 = hitta(UgnetaController.panel(KAP).knappar, Sprak.t("lektionsval.gangart"))
if g1 then g1.skicka() end
local g2 = hitta(UgnetaController.panel(KAP).knappar, Sprak.t("lektionsval.overgangar"))
if g2 then g2.skicka() end
local tb = hitta(UgnetaController.panel(KAP).knappar, Sprak.t("lektionsval.tillbaka"))
if tb then tb.skicka() end
check("Back from the Transitions subgroup returns to Gaits and pace",
	hitta(UgnetaController.panel(KAP).knappar, Sprak.t("tempolektion.choose")) ~= nil)
UgnetaController.dolj()

local sync = Networking.get("VoltLektionSync")
local toOther = 0
for _, rad in ipairs(sync._skickat) do if rad[1] ~= p then toOther += 1 end end
check("owner events only to the owner", toOther == 0)
-- ── C1 (docs/CANTER-TIMING-ADVICE-CONTRACT.md): före eller efter K, på en ny ritt ──
-- Egen funktion: huvudchunken har högst 200 lokala register.
;(function()
	HorseService.dismount(p)
	id = mount()
	nuV = 4
	local VC = VoltLektionController
	local syncC = Networking.get("VoltLektionSync")
	local function leverera(bb) syncC.OnClientEvent:Fire(bb) end
	local function panelText() leverera(image()); local sida = VC.panel(); return sida and sida.text end
	-- Panelen lägger till framstegen ("… 0%") i trot, som för varje text där.
	local function borjar(t, x) return type(t) == "string" and string.sub(t, 1, #x) == x end
	local T = function(k) return Sprak.t("galopplektion." .. k) end
	Sprak.satVal("sv")
	--[[ PÅHITTAT/KONTROLL (som hornlektion.spec): menysektionen ovan startar dussintals
		kontroller i samma ögonblick och tömmer fjärranropens takt; utan nollställning
		nekas kontrollerns egen sync och sidan visar "network". ]]
	Skopa._nollstallForProv()
	VC.avbryt(); VC.start(id, nil)
	UgnetaController.satLektionsVal(VC.panel)
	VC.valj("galopp")
	-- Vid sidan av linjen: steg direkt, och `nuV` följer med.
	local function sida(u, v) step(U + u, v); nuV = v end
	tillGangart("trot")
	request("start")
	-- Före K (v 18 → 18,8; K är 27–33).
	trav(10); trav(18)
	aid("driv"); ga(18.8)
	local b = image()
	check("C1 canter: a canter before K gives canter_outside + fore", b.lage == "trot" and b.tips == "canter_outside"
		and b.malSida == "fore")
	check("C1 canter: the real panel shows the early advice", borjar(panelText(), T("canter_early")))
	Sprak.satVal("en")
	check("C1 canter: the locale changes the words", borjar(panelText(), T("canter_early"))
		and not borjar(panelText(), Sprak.iSprak("sv", "galopplektion.canter_early")))
	Sprak.satVal("sv")
	tillGangart("trot"); trav(22)
	check("C1 canter: trotting again removes the side", image().tips ~= "canter_outside" and image().malSida == nil
		and not borjar(panelText(), T("canter_early")))
	-- Efter K (v 34 → 34,8).
	trav(34)
	aid("driv"); ga(34.8)
	b = image()
	check("C1 canter: a canter past K gives efter", b.tips == "canter_outside" and b.malSida == "efter")
	check("C1 canter: the real panel shows the late advice", borjar(panelText(), T("canter_late")))
	-- Mot A: galopp vid v 38 → 37,2 har ännu inte nått K i färdriktningen.
	tillGangart("trot"); trav(44); trav(38)
	aid("driv"); ga(37.2)
	b = image()
	check("C1 canter: towards A, a canter not yet at K is fore", b.tips == "canter_outside" and b.malSida == "fore")
	-- Vid sidan av linjen (u + 4) mot A, i v-läge "efter": ingen sida.
	tillGangart("trot"); trav(22)
	sida(1, 21.2); sida(2, 20.4); sida(3, 19.6); sida(4, 18.8)
	aid("driv"); sida(4, 18)
	b = image()
	check("C1 canter: beside the line has NO side", b.tips == "canter_outside" and b.malSida == nil)
	check("C1 canter: and the panel shows the generic text", borjar(panelText(), T("canter_outside")))
	-- Tillbaka på linjen, sedan över kanten: 26,2 utanför K, 27,0 exakt på kanten (−ZON_R).
	tillGangart("trot")
	sida(3, 17.5); sida(2, 17); sida(1, 16.5); sida(0, 16)
	trav(26.2)
	aid("driv"); ga(27)
	b = image()
	check("C1 canter: a canter across the ring edge has NO side", b.tips == "canter_outside" and b.malSida == nil)
	-- En annan miss (trot_first) bär ingen sida.
	tillGangart("trot"); trav(28)
	aid("driv"); ga(28.8)
	b = image()
	check("C1 canter: another failure (trot_first) has no side", b.tips == "trot_first" and b.malSida == nil)
	request("finish")
	check("C1 canter: finish carries no side", image().lage == "closed" and image().malSida == nil)
	tillGangart("trot")
	request("start")
	check("C1 canter: a new attempt starts without a side", image().lage == "trot" and image().malSida == nil)
	-- KONTROLL (deklarerad klientbild): en sida blir råd bara med nyckeln canter_outside.
	do
		local cur = image(); local fake = table.clone(cur)
		fake.revision = cur.revision + 1000; fake.tips = "canter_at_k"; fake.malSida = "fore"
		leverera(table.freeze(fake))
		local t = VC.panel().text
		check("C1 canter: the client never shows the advice outside canter_outside",
			not borjar(t, T("canter_early")) and borjar(t, T("canter_at_k")))
	end
	request("finish")
	VC.avbryt()
	UgnetaController.satLektionsVal(nil)
	for _, k in ipairs({ "canter_early", "canter_late" }) do
		local n = "galopplektion." .. k
		check("C1 canter: " .. n .. " exists in SV and EN", Sprak.iSprak("sv", n) ~= n and Sprak.iSprak("en", n) ~= n)
	end
end)()

check("lesson never writes persistent data", (__datastore.forsok and __datastore.forsok.skriv or 0) == writes)
if fails > 0 then error(tostring(fails) .. " FEL") end
print(string.format("\nGALOPPLEKTION: %d prov, alla gröna", total))
