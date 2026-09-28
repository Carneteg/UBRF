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
	and math.abs(done.resultat.slutS - langd("vag_mitt")) < 1e-6
	and math.abs(done.resultat.armS - -1.9) < 1e-6
	and math.abs(done.resultat.meter - (done.resultat.slutS - done.resultat.armS)) < 1e-9)
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

-- ── R1: armering i ringens bakre och främre halva ──
figur = "vag_mitt"
request("finish")
request("start")
tillStart("vag_mitt")
linje("vag_mitt", -3, -1.9) -- exakt −1,9: bakre halvan
check("R1: arming at the literal rear-half point s = -1.9", image().lage == "route"
	and image().progress == 0)
aid("broms") -- halt
for _ = 1, 3 do ga(nu.u, nu.v) end
check("R1: a halt at -1.9 right after arming is a pause, not reverse", image().lage == "route")
aid("driv") -- skritt
for _, sL in ipairs({ -1.7, -1.5, -1.2 }) do ga(lp("vag_mitt", sL)) end
check("R1: small forward steps still below -1 m keep the route", image().lage == "route"
	and image().tips ~= "reverse")
linje("vag_mitt", -1.2, langd("vag_mitt"))
local bak = image()
check("R1: a rear-half arming completes with metres counted from the arming point",
	bak.lage == "complete" and math.abs(bak.resultat.armS - -1.9) < 1e-6
	and math.abs(bak.resultat.meter - (langd("vag_mitt") + 1.9)) < 1e-6)

request("retry")
tillStart("vag_mitt")
linje("vag_mitt", -3, 3)
linje("vag_mitt", 3, 1.8)
check("R1: genuine backwards travel beyond the allowance still resets", image().lage == "to_start"
	and image().tips == "reverse")

rakt(U + 1.5, 9); ga(U + 1.5, 7.5) -- utanför ringen (2,12 m från P0)
check("KONTROLL: not armed beside the ring", image().lage == "to_start")
ga(U, 7.5) -- in i ringens främre halva, s = 1,5
check("R1: arming in the front half of the ring", image().lage == "route")
ga(U, 7.5)
ga(U, 7.5)
check("R1: a stationary first route sample in the front half gives no progress",
	image().lage == "route" and image().progress == 0)
linje("vag_mitt", 1.5, langd("vag_mitt"))
local fram = image()
check("R1: a front-half arming completes without crediting the approach",
	fram.lage == "complete" and math.abs(fram.resultat.armS - 1.5) < 1e-6
	and math.abs(fram.resultat.meter - (langd("vag_mitt") - 1.5)) < 1e-6)

-- ── R1: lektionsvalet bredvid Ugnetas 0..3 kortknappar (källnivå) ──
local V = VoltLektionController
local KAP = 4 -- Naromrades MAX_VAL, som Naromrade skickar till panel()
local function texter(lista)
	local ut = {}
	for _, k in ipairs(lista) do table.insert(ut, k.text) end
	return ut
end
local function hitta(lista, txt)
	for _, k in ipairs(lista) do if k.text == txt then return k end end
	return nil
end
local function kort(n)
	UgnetaController.dolj()
	if n > 0 then UgnetaController.visa("Kort", {}, n >= 1, nil, n >= 2, n >= 3) end
end
local menyOk = true
--[[ Ridmenyn prövas MONTERAD. Utan installerad ridlektionspanel visar Ugneta
	ledningslektionens val till fots ("Leda till ridhuset", sedan 784e8c1) —
	rätt till fots, men inte en av de gamla kortknapparna provet räknar. Det
	valet kopplas ur under menyprovet och tillbaka efteråt. ]]
UgnetaController.satFotVal(nil)
for n = 0, 3 do
	V.avbryt(); V.start("meny-prov-" .. n, nil)
	UgnetaController.satLektionsVal(nil)
	kort(n)
	local egna = texter(UgnetaController.panel(KAP).knappar)
	check("KONTROLL: " .. n .. " legacy card actions are visible", #egna == n)
	UgnetaController.satLektionsVal(V.panel)
	local ug = UgnetaController.panel(KAP)
	local synliga = texter(ug.knappar)
	local ryms = #ug.knappar <= KAP
	local kortKvar = true
	for i = 1, n do if synliga[i] ~= egna[i] then kortKvar = false end end
	local ingang = hitta(ug.knappar, Sprak.t("voltlektion.choose"))
		or hitta(ug.knappar, Sprak.t("lektionsval.oppna"))
	check("R1: " .. n .. " cards: the lesson entry is visible, the cards are kept and it fits",
		ryms and kortKvar and ingang ~= nil)
	-- Öppna varje grupp och välj varje löv; Tillbaka ger kortknapparna igen.
	local blad = {
		{ grupp = nil, text = Sprak.t("voltlektion.choose"), slut = Sprak.t("voltlektion.finish") },
		{ grupp = "lektionsval.gangart", text = Sprak.t("haltlektion.choose"), slut = Sprak.t("haltlektion.finish") },
		-- Sedan galoppfattningen ligger övergångarna i undergruppen.
		{ grupp = "lektionsval.gangart", under = "lektionsval.overgangar", text = Sprak.t("overganglektion.choose"), slut = Sprak.t("overganglektion.finish") },
		{ grupp = "lektionsval.gangart", text = Sprak.t("tempolektion.choose"), slut = Sprak.t("tempolektion.finish") },
		{ grupp = "lektionsval.vagar", under = "lektionsval.bojda", text = Sprak.t("serpentinlektion.choose"), slut = Sprak.t("serpentinlektion.finish") },
		-- Sedan halvvolten ligger mittlinjen och diagonalen i undergruppen.
		{ grupp = "lektionsval.vagar", under = "lektionsval.linjer", text = Sprak.t("vaglektion.choose_mitt"), slut = Sprak.t("vaglektion.finish") },
		{ grupp = "lektionsval.vagar", under = "lektionsval.linjer", text = Sprak.t("vaglektion.choose_diag"), slut = Sprak.t("vaglektion.finish") },
	}
	for _, b in ipairs(blad) do
		V.avbryt(); V.start("meny-prov-" .. n .. "-" .. b.text, nil)
		UgnetaController.satLektionsVal(V.panel) -- som LektionController efter varje start
		kort(n)
		local sida = UgnetaController.panel(KAP).knappar
		local oppna = hitta(sida, Sprak.t("lektionsval.oppna"))
		if oppna then oppna.skicka(); sida = UgnetaController.panel(KAP).knappar end
		if b.grupp then
			local g = hitta(sida, Sprak.t(b.grupp))
			if not g then menyOk = false else g.skicka(); sida = UgnetaController.panel(KAP).knappar end
		end
		if b.under then
			if #sida > KAP then menyOk = false end
			local g = hitta(sida, Sprak.t(b.under))
			if not g then menyOk = false else g.skicka(); sida = UgnetaController.panel(KAP).knappar end
		end
		if #sida > KAP then menyOk = false end
		local lov = hitta(sida, b.text)
		if not lov then menyOk = false else
			lov.skicka()
			local vald = UgnetaController.panel(KAP)
			if not (V.lektion() and hitta(vald.knappar, b.slut)) then menyOk = false end
		end
	end
	-- Tillbaka från en grupp ger de ursprungliga kortknapparna.
	V.avbryt(); V.start("meny-prov-" .. n .. "-tillbaka", nil)
	-- Som LektionController gör efter varje start: `avbryt` släpper lektionsvalet.
	UgnetaController.satLektionsVal(V.panel)
	kort(n)
	local sida = UgnetaController.panel(KAP).knappar
	local oppna = hitta(sida, Sprak.t("lektionsval.oppna"))
	if oppna then oppna.skicka(); sida = UgnetaController.panel(KAP).knappar end
	local g = hitta(sida, Sprak.t("lektionsval.vagar"))
	if g then g.skicka() end
	local tb = hitta(UgnetaController.panel(KAP).knappar, Sprak.t("lektionsval.tillbaka"))
	if tb then tb.skicka() end
	local efter = texter(UgnetaController.panel(KAP).knappar)
	local igen = tb ~= nil
	for i = 1, n do if efter[i] ~= egna[i] then igen = false end end
	check("R1: " .. n .. " cards: Back from a group returns to the original card actions", igen)
end
check("R1: every group opens and every leaf is selectable beside 0..3 cards", menyOk)
UgnetaController.satFotVal(LedLektionController.panel)
UgnetaController.dolj()

-- Menyprovet ovan skickar många begäranden (också till påhittade ritter);
-- takten nollställs så att nästa avsnitt inte nekas med takt.for_snabbt.
Skopa._nollstallForProv()
-- Fri ridning efter Finish, och återanslutning till samma ritt. En ny ritt
-- ger en tom begäranbok, så klientens egen sekvens (från 0) är inte inaktuell.
check("KONTROLL: dismount for a fresh ride", HorseService.dismount(p) == true)
id = mount(); nu = { u = 0, v = 4 }
V.avbryt(); V.start(id, nil)
UgnetaController.satLektionsVal(V.panel)
local c = hitta(UgnetaController.panel(KAP).knappar, Sprak.t("voltlektion.choose"))
if c then c.skicka() end
local f = hitta(UgnetaController.panel(KAP).knappar, Sprak.t("voltlektion.finish"))
if f then f.skicka() end
local friSida = UgnetaController.panel(KAP)
check("R1: after Finish, free riding shows all groups and the way back to lessons",
	#friSida.knappar == 4 and hitta(friSida.knappar, Sprak.t("lektionsval.vagar")) ~= nil
	and hitta(friSida.knappar, Sprak.t("voltlektion.fri_traning")) ~= nil)
V.avbryt(); V.start(id, nil)
UgnetaController.satLektionsVal(V.panel) -- som LektionController efter varje start
check("R1: reattaching to the same ride keeps free-riding navigation",
	#UgnetaController.panel(KAP).knappar == 4)

-- ── C3 (docs/ROUTE-LESS-GUIDANCE-CONTRACT.md): "Rid utan streck", spelarens eget val ──
-- Egen funktion: huvudchunken har högst 200 lokala register.
;(function()
	Skopa._nollstallForProv()
	HorseService.dismount(p)
	id = mount(); nu = { u = 0, v = 4 }
	local remote = Networking.get("VoltLektion")
	local minneSync = Networking.get("LektionsMinneSync")
	local syncC = Networking.get("VoltLektionSync")
	--[[ PÅHITTAT/KONTROLL: lektionsminnet levereras genom klientens riktiga kanal
		(LektionsMinneSync) med en hög session, eftersom den här bänken inte sparar. ]]
	local rev = 0
	local function minne(lektioner)
		rev += 1
		minneSync.OnClientEvent:Fire({ historik = "betrodd", lektioner = lektioner, session = 1000000, rev = rev })
	end
	local function knapp(nyckel)
		local sida = V.panel()
		return sida and hitta(sida.knappar, Sprak.t(nyckel)) or nil
	end
	local function leverera() syncC.OnClientEvent:Fire(image()) end
	--[[ Guidens delar efter bredd: ringstreck 0,3·spm, linjestreck 0,45·spm och
		pilstreck 0,4·spm, var och en × 0,65 (VoltLektionController.streck). ]]
	local function delar()
		local g = workspace:FindFirstChild("Voltguide")
		if not g then return nil end
		local spm = HorseService.ridplats(id).studsPerMeter or 3
		local ring, ovr = 0, 0
		for _, d in ipairs(g:GetChildren()) do
			if math.abs(d.Size.X - 0.3 * spm * 0.65) < 1e-3 then ring += 1 else ovr += 1 end
		end
		return { ring = ring, ovr = ovr }
	end
	Sprak.satVal("sv")
	V.avbryt(); V.start(id, nil)
	UgnetaController.satLektionsVal(V.panel)
	V.valj("vag_mitt")
	minne({ vag_mitt = "okand", halt = "sparad" })
	check("C3: not completed gives no 'Rid utan streck'", knapp("vaglektion.utan_streck") == nil
		and knapp("vaglektion.visa_vagen") == nil)
	aid("driv")
	knapp("vaglektion.start").skicka(); leverera()
	local full = delar()
	check("C3: the full guide has rings and line/chevron parts", full ~= nil and full.ring > 0 and full.ovr > 0,
		full and ("%d ringar, %d övriga"):format(full.ring, full.ovr))
	minne({ vag_mitt = "sparad", halt = "sparad" })
	local k = knapp("vaglektion.utan_streck")
	check("C3: completed gives 'Rid utan streck'", k ~= nil)
	local n = #remote._skickat
	k.skicka()
	local mindre = delar()
	check("C3: pressing it sends nothing to the server", #remote._skickat == n)
	check("C3: less guidance keeps only the start and end rings", mindre ~= nil and mindre.ovr == 0
		and mindre.ring == full.ring, mindre and ("%d ringar, %d övriga"):format(mindre.ring, mindre.ovr))
	check("C3: the button is now 'Visa vägen'", knapp("vaglektion.visa_vagen") ~= nil
		and knapp("vaglektion.utan_streck") == nil)
	Sprak.satVal("en")
	check("C3: English words", knapp("vaglektion.visa_vagen") ~= nil and Sprak.t("vaglektion.visa_vagen") == "Show the way")
	Sprak.satVal("sv")
	-- Samma uppgift: en ordnad genomridning slutförs som förut.
	rakt(U, 2)
	linje("vag_mitt", -4, -1.9); leverera()
	check("C3: with less guidance the guide during the route is still rings only",
		delar() ~= nil and delar().ovr == 0)
	linje("vag_mitt", -1.9, 0)
	linje("vag_mitt", 0, langd("vag_mitt"))
	local klar = image()
	check("C3: the task completes exactly as before with less guidance", klar.lage == "complete"
		and klar.resultat ~= nil and klar.resultat.figur == "vag_mitt"
		and math.abs(klar.resultat.slutS - langd("vag_mitt")) < 1e-6)
	leverera()
	knapp("vaglektion.visa_vagen").skicka()
	knapp("voltlektion.retry").skicka(); leverera()
	local igen = delar()
	check("C3: 'Visa vägen' restores the full guide", igen ~= nil and igen.ovr == full.ovr and igen.ring == full.ring,
		igen and ("%d ringar, %d övriga"):format(igen.ring, igen.ovr))
	-- Typbyte ger hela guiden igen.
	knapp("vaglektion.utan_streck").skicka()
	knapp("vaglektion.finish").skicka(); leverera()
	V.valj("halt")
	check("C3: another lesson type never shows the choice, even when completed",
		knapp("vaglektion.utan_streck") == nil and knapp("vaglektion.visa_vagen") == nil)
	V.valj("vag_mitt")
	check("C3: a type switch resets to the full guide", knapp("vaglektion.utan_streck") ~= nil
		and knapp("vaglektion.visa_vagen") == nil)
	-- Ny ritt ger hela guiden igen.
	knapp("vaglektion.utan_streck").skicka()
	HorseService.dismount(p)
	id = mount(); nu = { u = 0, v = 4 }
	V.avbryt(); V.start(id, nil)
	UgnetaController.satLektionsVal(V.panel)
	V.valj("vag_mitt")
	check("C3: a new ride resets to the full guide", knapp("vaglektion.utan_streck") ~= nil
		and knapp("vaglektion.visa_vagen") == nil)
	V.avbryt()
	for _, nyckel in ipairs({ "vaglektion.utan_streck", "vaglektion.visa_vagen" }) do
		check("C3: " .. nyckel .. " exists in SV and EN", Sprak.iSprak("sv", nyckel) ~= nyckel
			and Sprak.iSprak("en", nyckel) ~= nyckel)
	end
end)()

local sync = Networking.get("VoltLektionSync")
local toOther = 0
for _, rad in ipairs(sync._skickat) do if rad[1] ~= p then toOther += 1 end end
check("owner events only to the owner", toOther == 0)
check("lesson never writes persistent data", (__datastore.forsok and __datastore.forsok.skriv or 0) == writes)
if fails > 0 then error(tostring(fails) .. " FEL") end
print(string.format("\nVAGLEKTION: %d prov, alla gröna", total))
