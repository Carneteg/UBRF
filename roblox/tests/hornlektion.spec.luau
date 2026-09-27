--!nostrict
--[[ GENOM HÖRNET — docs/CORNER-LESSON-CONTRACT.md. Uppställningen är vaglektion-specens,
	ordagrant utom figuren och SparService (för minnet). Dess ursprungliga huvud:

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
--[[ Minnet: SparService laddar spelaren FÖRE HorseService.start (som startar
	LektionsMinne), mot den stubbade DataStore. ]]
__datastore.nollstall()
Players._spelare = { Players.LocalPlayer }
SparService._glomHookarForProv()
SparService._glomForProv(Players.LocalPlayer)
SparService.start()
HorseService.setMountGate(nil); HorseService.start()
local writes = __datastore.forsok and __datastore.forsok.skriv or 0
local F = VagLektion.FIGURER -- oanvänd här; kvar från fixturen

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
local figur = "hornet"
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

--[[ ══ GENOM HÖRNET — docs/CORNER-LESSON-CONTRACT.md ═══════════════════════
	Ovan: vaglektion-specens uppställning ordagrant (fixturen), med figuren
	`hornet` och SparService startad för minnet. SKRIVNA FÖR SENARE KÖRNING,
	inte körda.
	ETIKETTER:
	- SAMMANFOGAT, SYNKRONT: H1–H11 och H14 (riktig HorseService,
	  observationer och väg; klientens knappar där det står);
	- PÅHITTAD GEOMETRI: H12 prövar guidens delar mot serverns projektion;
	- PÅHITTADE KLIENTBILDER: H13 (felformat resultat);
	- VERKLIGT FÖRDRÖJT: H16 (Start på schemat);
	- PLANERAT: fysisk rendering, respawn på enhet, minnets fördröjda
	  sparning med ett riktigt hörn (samma rörledning är skriven i
	  lektionsminne/skotselminne). ]]
local G = HornLektion.GRANSER
local LM = LektionsMinne
local ref = nil
--[[ Punkten vid läget sL längs vägen, ur serverns referens (samma fält
	som servern projicerar mot). Negativt sL: bakom P0 på spårlinjen. ]]
local function vagPunkt(r, sL)
	if sL <= r.inM then return r.uT, r.p0v + sL end
	local b = r.r * math.pi / 2
	if sL <= r.inM + b then
		local th = (sL - r.inM) / r.r
		return r.cu + r.r * math.cos(th), r.cv + r.r * math.sin(th)
	end
	return r.cu - (sL - r.inM - b), r.p3v
end
local function langs(s0, s1)
	local n = math.max(1, math.ceil(math.abs(s1 - s0) / 0.9))
	for i = 1, n do ga(vagPunkt(ref, s0 + (s1 - s0) * i / n)) end
end
local function tillHornStart()
	rakt(U, 2); rakt(ref.uT, 2); rakt(vagPunkt(ref, -3))
end
local function hamta()
	ref = image().referens
	return ref
end
local function avslutaNu()
	local bok = s.lektionsBegaran
	seq = (bok and bok.hogsta or 0) + 1
	return HorseService.voltLektionsBegaran(p, id, "finish", seq, "hornet")
end

print("\n── H1. Hela hörnet: inridning, bågen, utridning (SAMMANFOGAT, SYNKRONT) ──")
do
	aid("driv") -- skritt
	local ok, _, b = request("start")
	check("start öppnar ett hörnförsök med egen definition", ok and b.lage == "to_start" and b.typ == "hornet"
		and HorseService.forsok(b.forsokId).ovning == "genom_hornet"
		and HorseService.forsok(b.forsokId).definition == "server-horn-1")
	check("KONTROLL: referensen finns och ryms", hamta() ~= nil and ref.figur == "hornet")
	tillHornStart()
	langs(-3, -1.5)
	check("genom startringen: armerad utan kredit", image().lage == "route" and image().progress == 0
		and image().delmal == 1)
	langs(-1.5, ref.langd)
	local done = image()
	check("hela vägen fullföljer", done.lage == "complete" and HorseService.forsok(done.forsokId).orsak == "slutford")
	check("det frysta resultatet: figur, kontrollpunkt, meter och längd", done.resultat ~= nil
		and table.isfrozen(done.resultat) and done.resultat.figur == "hornet" and done.resultat.mitt == true
		and math.abs(done.resultat.langd - ref.langd) < 1e-6 and done.resultat.meter > 0)
	-- R1: metrarna räknas från vägens början, så de överstiger aldrig vägens längd.
	check("det frysta resultatets meter överstiger inte vägens längd", done.resultat ~= nil
		and done.resultat.meter <= done.resultat.langd + 1e-6)
	check("minnet: markören för hörnet (egen nyckel)", LM.nyckel("hornet") == "lektion:hornet:server-horn-1"
		and LM._projektion(LM._tillstandForProv(p)).lektioner.hornet == "sparad")
	local skriv0 = __datastore.forsok.skriv
	request("retry")
	hamta(); tillHornStart(); langs(-3, ref.langd)
	check("KONTROLL: andra fullföljandet", image().lage == "complete")
	check("ett andra fullföljande ger ingen ny markör och ingen ny skrivning",
		__datastore.forsok.skriv == skriv0)
end

print("\n── H2–H5. Korda, utanför, bakåt, rakt in i hörnet (SAMMANFOGAT, SYNKRONT) ──")
do
	request("retry"); hamta()
	tillHornStart(); langs(-3, ref.inM)
	local p1u, p1v = vagPunkt(ref, ref.inM)
	local p2u, p2v = vagPunkt(ref, ref.inM + ref.r * math.pi / 2)
	for i = 1, 6 do ga(p1u + (p2u - p1u) * i / 6, p1v + (p2v - p1v) * i / 6) end
	check("H2 en korda tvärs över hörnet: utanför strecken, ingen fullföljning",
		image().lage == "to_start" and image().tips == "off_route")
	-- H3: parallellt 2 m innanför spåret.
	rakt(ref.uT - 2, ref.p0v - 3)
	for v = ref.p0v - 2, ref.cv do ga(ref.uT - 2, v) end
	check("H3 två meter vid sidan av spåret armerar aldrig", image().lage == "to_start" and image().progress == 0)
	-- H4: bakåt i bågen.
	tillHornStart(); langs(-3, ref.inM + 3)
	langs(ref.inM + 3, ref.inM + 1.5)
	check("H4 bakåt i bågen nollställer", image().lage == "to_start" and image().tips == "reverse")
	-- H5: rakt fram förbi bågen, in i staketets hörn.
	tillHornStart(); langs(-3, ref.inM)
	for i = 1, 5 do ga(ref.uT, ref.cv + i) end
	check("H5 rakt in i hörnet (förbi bågen) är utanför strecken", image().lage == "to_start"
		and image().tips == "off_route")
end

print("\n── H6–H9. Stillastående, fel gångart, före start, lucka och teleport (SAMMANFOGAT, SYNKRONT) ──")
do
	tillHornStart(); langs(-3, 2)
	local p2 = image().progress
	for _ = 1, 10 do ga(nu.u, nu.v) end
	check("H6 stillastående ger inget framsteg", image().progress == p2 and image().lage == "route")
	aid("driv"); aid("driv") -- galopp
	langs(2, 3)
	check("H7 galopp nollställer", image().lage == "to_start" and image().tips == "walk_or_trot")
	aid("broms"); aid("broms") -- skritt
	local okF = avslutaNu()
	check("KONTROLL: Avsluta godtogs", okF == true and image().lage == "closed")
	-- H8: hela vägen FÖRE start ger ingenting.
	tillHornStart(); langs(-3, ref.langd)
	request("start"); hamta()
	check("H8 bevis från före start räknas inte", image().lage == "to_start" and image().progress == 0)
	tillHornStart(); langs(-3, 5)
	ga(nu.u, nu.v, 5) -- lucka
	check("H9 en lucka nollställer", image().lage == "to_start" and image().progress == 0)
	tillHornStart(); langs(-3, 5)
	ga(vagPunkt(ref, ref.langd)) -- teleport till slutet
	check("H9 en teleport nollställer, aldrig fullföljt", image().lage ~= "complete" and image().progress == 0)
end

print("\n── H10–H11. Tidsgräns, Avsluta, A-B-A och en annan aktiv lektion (SAMMANFOGAT, SYNKRONT) ──")
do
	s.voltLektion.deadline = os.clock()
	ga(nu.u, nu.v)
	check("H10 tidsgräns ger timeout, aldrig framgång", image().lage == "timeout"
		and HorseService.forsok(image().forsokId).orsak == "tidsgrans")
	request("retry")
	local okByt, felByt = request("start", "vag_mitt")
	check("H11 en annan lektion nekas medan hörnet är aktivt", okByt == false and felByt == "active")
	local okF = avslutaNu()
	check("H10 Avsluta stänger", okF == true and image().lage == "closed")
	local hornObjekt = s.voltLektion
	request("start", "vag_mitt"); request("finish", "vag_mitt")
	--[[ En sync läser bara den pågående lektionen (ändrar aldrig typ); tillbaka
		till hörnet går genom ett Start med typen, som skapar ett nytt objekt. ]]
	local okNy, _, bNy = request("start", "hornet")
	check("H11 A-B-A: tillbaka till hörnet är ett nytt lektionsobjekt, utan gammalt resultat",
		okNy == true and bNy ~= nil and bNy.typ == "hornet" and bNy.lage == "to_start" and bNy.resultat == nil
		and s.voltLektion ~= hornObjekt)
	avslutaNu()
end

print("\n── H12. Guiden: varje del ligger på serverns väg (PÅHITTAD GEOMETRI mot riktig referens) ──")
do
	local VC = VoltLektionController
	VC.avbryt(); VC.start(id, nil)
	VC.valj("hornet")
	local okS = request("start"); hamta()
	local _, _, bS = HorseService.voltLektionsBegaran(p, id, "sync", nil, "hornet")
	Networking.get("VoltLektionSync").OnClientEvent:Fire(bS)
	local guide = workspace:FindFirstChild("Voltguide")
	check("KONTROLL H12: guiden byggdes", okS == true and guide ~= nil)
	local allaNara, antal = true, 0
	for _, d in ipairs(guide and guide:GetChildren() or {}) do
		antal += 1
		local l = Ridhusplats.tillLokal(ref.plats, d.CFrame.Position)
		local _, e = HornLektion._projektionForProv(ref, { u = l.X, v = l.Z })
		if e > ref.ring + 0.6 then allaNara = false end
	end
	check("H12 guidens alla streck, pilar och ringar ligger vid serverns väg", antal > 0 and allaNara)
	check("H12 projektionen: kordans mittpunkt ligger utanför korridoren",
		select(2, HornLektion._projektionForProv(ref, { u = (ref.uT + ref.cu) / 2, v = (ref.cv + ref.cv + ref.r) / 2 }))
			> G.KORR)
	--[[ R1: geometrins nyckel. Samma indata ger samma nyckel, en flyttad
		dressyrmitt ger en annan — klientens guidecache ritar då om. ]]
	local function refMed(u) return HornLektion._referensForProv(nil,
		{ ramId = ref.ramId, dressyrMitt = { u = u } }, ref.plats) end
	-- Dressyrmittens u ur referensen: uT = u0 + W − T.
	local u0 = ref.uT - ref.plats.dressyr.halvTvars / ref.plats.studsPerMeter + G.T
	check("H12 referensen bär en geometrinyckel", type(ref.nyckel) == "string" and ref.nyckel ~= "")
	check("H12 samma geometri ger samma nyckel", refMed(u0).nyckel == ref.nyckel)
	check("H12 en flyttad geometri ger en ny nyckel", refMed(u0 - 1).nyckel ~= ref.nyckel)
	avslutaNu()
	VC.avbryt()
end

print("\n── H13. Återkopplingen: riktigt resultat, felformat resultat, kort, SV/EN ──")
do
	local A = LektionsAterkoppling
	request("start"); hamta(); tillHornStart(); langs(-3, ref.langd)
	local klar = image()
	check("KONTROLL H13: fullföljt", klar.lage == "complete")
	local t = A.text(klar, { typ = "hornet", ritt = id })
	check("H13 detaljerat: fakta ur det frysta resultatet och ETT nästa steg",
		string.find(t, Sprak.t("aterkoppling.hornet.nasta"), 1, true) ~= nil, t)
	LararInstallning.satDetalj("kort")
	check("H13 kort: utan siffror", string.find(A.text(klar, { typ = "hornet", ritt = id }),
		Sprak.t("aterkoppling.hornet.kort"), 1, true) ~= nil)
	LararInstallning.satDetalj("detaljerad")
	local fel = table.clone(klar); local r = table.clone(klar.resultat); r.mitt = false; fel.resultat = table.freeze(r)
	check("H13 PÅHITTAT felformat resultat (utan kontrollpunkten): neutralt",
		A.text(fel, { typ = "hornet", ritt = id }) == Sprak.t("aterkoppling.okant"))
	Sprak.satVal("en")
	check("H13 engelska", string.find(A.text(klar, { typ = "hornet", ritt = id }), "Next time", 1, true) ~= nil)
	Sprak.satVal("sv")
end

print("\n── H14–H15. Menyn och hälsningen i den FAKTISKA värden (SAMMANFOGAT, SYNKRONT) ──")
do
	-- Bänken har ingen riktig tid: takten nollställs, annars nekas Start med takt.for_snabbt.
	Skopa._nollstallForProv()
	local VC, UC = VoltLektionController, UgnetaController
	local function hitta(lista, txt)
		for _, k in ipairs(lista) do if string.find(k.text, txt, 1, true) then return k end end
		return nil
	end
	VC.avbryt(); VC.start(id .. "-meny", nil)
	UC.satLektionsVal(VC.panel)
	UC.dolj()
	local rot = UC.panel(4).knappar
	check("H15 roten ryms i fyra rader", #rot <= 4)
	local vagar = hitta(rot, Sprak.t("lektionsval.vagar"))
	if vagar then vagar.skicka() end
	local sidaV = UC.panel(4).knappar
	check("H15 Ridvägar: Böjda vägar, Raka linjer och Tillbaka", #sidaV == 3
		and hitta(sidaV, Sprak.t("lektionsval.bojda")) ~= nil and hitta(sidaV, Sprak.t("lektionsval.linjer")) ~= nil)
	hitta(sidaV, Sprak.t("lektionsval.bojda")).skicka()
	local sidaB = UC.panel(4).knappar
	check("H15 Böjda vägar: serpentin, halvvolt, hörnet och Tillbaka",
		#sidaB == 4 and hitta(sidaB, Sprak.t("serpentinlektion.choose")) ~= nil
		and hitta(sidaB, Sprak.t("halvvoltlektion.choose")) ~= nil and hitta(sidaB, Sprak.t("hornlektion.choose")) ~= nil)
	hitta(sidaB, Sprak.t("hornlektion.choose")).skicka()
	-- H14: hälsningen efter ett godtaget Start genom värdens knapp, i den riktiga ritten.
	-- H13 lämnade ett fullföljt hörn; Avsluta först, så att sidan erbjuder Start.
	avslutaNu()
	VC.avbryt(); VC.start(id, nil); UC.satLektionsVal(VC.panel)
	VC.valj("tempo"); VC.valj("hornet")
	local start = hitta(UC.panel(4).knappar, Sprak.t("hornlektion.start"))
	check("KONTROLL H14: Start finns", start ~= nil)
	if start then start.skicka() end
	check("H14 hälsningen står först i sidans text", string.sub(UC.panel(4).text or "", 1,
		#Sprak.t("halsning.hornet")) == Sprak.t("halsning.hornet"))
	LararInstallning.satKommentarer("inga")
	check("H14 Inga tar bort hälsningen direkt", VC._halsningForProv() == nil)
	LararInstallning.satKommentarer("normal")
	avslutaNu()
	UC.satLektionsVal(nil)
	VC.avbryt()
end

print("\n── H16. VERKLIGT FÖRDRÖJT: Start på schemat, pushen före det sena svaret ──")
do
	Skopa._nollstallForProv()
	local VC, UC = VoltLektionController, UgnetaController
	local remote = Networking.get("VoltLektion")
	local riktig = remote.InvokeServer
	VC.avbryt(); VC.start(id, nil); UC.satLektionsVal(VC.panel)
	VC.valj("tempo"); VC.valj("hornet") -- valet före schemat
	__schemaPa(true)
	remote.InvokeServer = function(self, ...)
		local svar = table.pack(riktig(self, ...))
		task.wait()
		return table.unpack(svar, 1, svar.n)
	end
	local start = nil
	for _, k in ipairs(UC.panel(4).knappar) do if k.text == Sprak.t("hornlektion.start") then start = k end end
	check("KONTROLL H16: Start finns", start ~= nil)
	if start then start.skicka() end
	__schemaSteg()
	check("KONTROLL H16: servern godtog", RidForsok.aktivt(id) ~= nil)
	local _, _, pushad = HorseService.voltLektionsBegaran(p, id, "sync", nil, "hornet")
	Networking.get("VoltLektionSync").OnClientEvent:Fire(pushad)
	check("H16 pushen före svaret: ingen hälsning än", VC._halsningForProv() == nil)
	__schemaTomKo()
	remote.InvokeServer = riktig
	__schemaPa(false)
	check("H16 hälsningen kommer med det godtagna svaret", VC._halsningForProv() ~= nil)
	avslutaNu()
	UC.satLektionsVal(nil)
	VC.avbryt()
end

if fails > 0 then error(tostring(fails) .. " FEL") end
print(string.format("\nHORNLEKTION: %d prov, alla gröna", total))
