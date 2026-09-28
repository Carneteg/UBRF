--!nostrict
--[[ D2a CLEAR ROUND (UBRF-TRÄNING), FÖRENKLAD BEDÖMNING — docs/D2-CLEAR-ROUND-DAY-CONTRACT.md.

	BANK_ONLY, KOHERENS-bänken: riktig HorseService, riktigt byggt ridhus med
	de BEFINTLIGA hindren (blå 0,68 m, röd 0,52 m), riktig HinderObservation
	och riktiga observationer. Rotens läge sätts mellan hjärtslagen i
	ridhusets ram (u tvärs, v mot C) — syntetisk rutt, inte spelarens ridning. ]]
local fails, total = 0, 0
local function check(name, yes, detalj)
	total += 1
	if not yes then fails += 1 end
	print((if yes then "  OK   " else "  FEL  ") .. name .. (if detalj then "  " .. tostring(detalj) else ""))
end
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local Tags = game:GetService("CollectionService")
local vec = Vector3.new
local RP = assert(Ridhusplats.los(workspace:FindFirstChild("Anläggning"):FindFirstChild("UBRF")))
Tags:nollstall(); Run._server = true; Run.Heartbeat:nollstall()
HorseService.setMountGate(nil); HorseService.start()
local writes = __datastore.forsok and __datastore.forsok.skriv or 0
local G = ClearRoundLektion.GRANSER

local function player(id)
	local c = Instance.new("Model")
	local root = Instance.new("Part"); root.Name = "HumanoidRootPart"; root.Size = vec(2,2,1); root.Parent = c
	local h = Instance.new("Humanoid"); h.Name = "Humanoid"; h.Parent = c
	return { UserId = id, Name = "Clear" .. id, Character = c,
		CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }
end
local p = Players.LocalPlayer
p.Character = player(995).Character
Players._spelare = { p }
local horse = HastRigg.bygg("clear_test", "Clear test", CFrame.new(Ridhusplats.tillVarld(RP, vec(0, 0, 4))))
horse.Parent = workspace; Tags:AddTag(horse, "Horse")
local s = HorseService.sessionFor(horse)
local nu = { u = 0, v = 4 }
local function point(u, v)
	local a = Ridhusplats.tillVarld(RP, vec(u, 0, v))
	return vec(a.X, s.rig.root.Position.Y, a.Z)
end
local function step(u, v, dt)
	local a = point(u, v); s.rig.root.CFrame = CFrame.new(a); s.rig.root.Position = a
	s.energi = 1; Run.Heartbeat:Fire(dt or 0.25)
	nu = { u = u, v = v }
end
-- Rakt till (u, v) i steg om högst 0,8 m.
local function till(u, v)
	local n = math.max(1, math.ceil(math.sqrt((u - nu.u) ^ 2 + (v - nu.v) ^ 2) / 0.8))
	local u0, v0 = nu.u, nu.v
	for i = 1, n do step(u0 + (u - u0) * i / n, v0 + (v - v0) * i / n) end
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
local function request(op)
	seq += 1
	return HorseService.voltLektionsBegaran(p, id, op, seq, "clearround")
end
local function image()
	local ok, _, b = HorseService.voltLektionsBegaran(p, id, "sync", nil, "clearround"); assert(ok); return b
end
local function fmt(b)
	local r = b.resultat
	return ("lage=%s tips=%s utfall=%s orsak=%s olydnader=%s fel=%s omstart=%s"):format(tostring(b.lage),
		tostring(b.tips), tostring(r and r.utfall), tostring(r and r.orsak), tostring(r and r.olydnader),
		tostring(r and r.fel), tostring(r and r.omstartMojlig))
end

-- ── Hindren i ramen (ur registret, aldrig ur listan) ──
local reg = HinderObservation.register()
local function iRam(hid)
	local h = reg.hinder[hid]
	local c = Ridhusplats.tillLokal(RP, vec(h.x, h.y, h.z))
	return { u = c.X, v = c.Z }
end
local B, R = iRam("ridhus_hinder_bla_24"), iRam("ridhus_hinder_rod_38")
check("KONTROLL: blått och rött hinder finns, rött längre mot C", B and R and R.v > B.v + 6,
	("blå (%.1f, %.1f) röd (%.1f, %.1f)"):format(B.u, B.v, R.u, R.v))

--[[ Banans väg: hopp 1 blå mot C, 2 röd mot C, 3 blå mot A, 4 röd mot C.
	Förflyttningar mellan hoppen går vid sidan om det andra hindrets zon. ]]
local function tillStart() till(B.u, nu.v); till(B.u, B.v - 13) end
local function overStartlinjen() till(B.u, B.v - G.LINJE_M + 1) end
local function hopp1() till(B.u, B.v + 4) end
local function hopp2() till(R.u, B.v + 4); till(R.u, R.v - 5); till(R.u, R.v + 4) end
local function hopp3() till(B.u, R.v + 4); till(B.u, B.v + 5); till(B.u, B.v - 4) end
local function hopp4() till(R.u, B.v - 4); till(R.u, R.v - 5); till(R.u, R.v + 4) end
local function malet() till(R.u, R.v + G.LINJE_M + 1) end
local function helaBanan() overStartlinjen(); hopp1(); hopp2(); hopp3(); hopp4(); malet() end
--[[ En utbrytning vid blått: över hindrets plan UTANFÖR bredden (1,4 m) men
	inne i zonen (bredd/2 + 1,5 studs = 1,9 m; djup 6 studs = 2 m), ut ur zonen
	framåt, och tillbaka runt zonen till inridningen framför blått. ]]
local function utbrytningBla()
	till(B.u + 1.65, B.v - 3); till(B.u + 1.65, B.v + 3)
	till(B.u + 4, B.v + 3); till(B.u + 4, B.v - 3); till(B.u, B.v - 3)
end
local function nyttForsok()
	request("finish")
	tillStart()
	return request("start")
end

print("\n── 1. Hela banan i ordning: inga observerade fel, förenklad, ingen rosett ──")
tillStart()
local ok, _, b = request("start")
check("start (startsignalen) öppnar försök 1 mot startlinjen", ok and b.lage == "to_start" and b.forsokNr == 1
	and HorseService.forsok(b.forsokId).ovning == "clearround", fmt(b))
overStartlinjen()
check("startlinjen öppnar banan, nästa: hopp 1 blått mot C", image().lage == "course" and image().nasta ~= nil
	and image().nasta.nr == 1 and image().nasta.farg == "bla" and image().nasta.mot == "C", fmt(image()))
hopp1()
check("hopp 1 räknas, nästa: hopp 2 rött mot C", image().nasta and image().nasta.nr == 2
	and image().nasta.farg == "rod", fmt(image()))
hopp2(); hopp3()
check("hopp 3 blått mot A räknas", image().nasta and image().nasta.nr == 4, fmt(image()))
hopp4()
check("efter hopp 4: mot mållinjen", image().lage == "to_finish", fmt(image()))
malet()
local klar = image()
local r = klar.resultat
check("mållinjen: inga observerade fel, 0 fel, förenklad bedömning", klar.lage == "complete" and r ~= nil
	and r.utfall == "inga_observerade_fel" and r.fel == 0 and r.bedomning == "forenklad"
	and r.nedslag == "bedoms_inte" and r.bana == "traningsbana", fmt(klar))
check("ALDRIG felfri och ALDRIG rosett i resultatet", r ~= nil and r.felfri == nil and r.rosett == nil)
check("utan fel ingen omstart; tiden är mätt", r ~= nil and r.omstartMojlig == false and type(r.tid) == "number"
	and r.tid > 0, tostring(r and r.tid))
check("försöket är slutfört i RidForsok", HorseService.forsok(klar.forsokId).orsak == "slutford")
check("en omstart efter ett försök utan fel nekas", request("retry") == false)

print("\n── 2. Olydnader (utbrytningar, TR 385) ──")
nyttForsok(); overStartlinjen()
utbrytningBla()
check("en utbrytning vid hopp 1: hopp 1 kvar", image().lage == "course" and image().nasta.nr == 1, fmt(image()))
hopp1(); hopp2(); hopp3(); hopp4(); malet()
r = image().resultat
check("resultat: 1 olydnad = 4 fel, observerade fel, omstart möjlig", r and r.utfall == "observerade_fel"
	and r.olydnader == 1 and r.fel == 4 and r.omstartMojlig == true, fmt(image()))
nyttForsok(); overStartlinjen()
for _ = 1, 3 do utbrytningBla() end
r = image().resultat
check("tre utbrytningar: utesluten", image().lage == "complete" and r and r.utfall == "utesluten"
	and r.orsak == "olydnader" and r.omstartMojlig == true, fmt(image()))

print("\n── 3. Fel väg (TR 384.1, 388.2.2) ──")
nyttForsok(); overStartlinjen()
till(R.u, B.v - 6); till(R.u, R.v - 5); till(R.u, R.v + 4)
r = image().resultat
check("rött först: fel väg, utesluten", r and r.utfall == "utesluten" and r.orsak == "fel_vag", fmt(image()))
nyttForsok(); overStartlinjen(); hopp1(); hopp2()
-- Hopp 3 ska vara blått mot A; här blått mot C.
till(B.u, R.v + 4); till(B.u, R.v + 8); till(B.u + 5, R.v + 8); till(B.u + 5, B.v - 6); till(B.u, B.v - 6); till(B.u, B.v + 4)
r = image().resultat
check("blått åt fel håll som hopp 3: fel väg, utesluten", r and r.utfall == "utesluten" and r.orsak == "fel_vag",
	fmt(image()))

print("\n── 4. Tid: startlinjen inom 45 s och tillåten tid 180 s ──")
nyttForsok()
for _ = 1, math.ceil((G.START_S + 1) / 0.25) do step(nu.u, nu.v) end
r = image().resultat
check("ingen startlinje inom 45 s: ej startad, ingen bedömning, ingen omstart", r and r.utfall == "ej_startad"
	and r.fel == nil and r.omstartMojlig == false, fmt(image()))
nyttForsok(); overStartlinjen(); hopp1()
for _ = 1, math.ceil((G.TILLATEN_S + 1) / 0.25) do step(nu.u, nu.v) end
r = image().resultat
check("mer än 180 s: utesluten (tillåten tid)", r and r.utfall == "utesluten" and r.orsak == "tillaten_tid", fmt(image()))

print("\n── 5. Observationsbrott: kan inte bedömas ──")
nyttForsok(); overStartlinjen(); hopp1()
step(nu.u, nu.v, 5) -- en lucka i observationen
r = image().resultat
check("ett brott mitt i banan: ej bedömd, inget utfall, ingen omstart", r and r.utfall == "ej_bedomd"
	and r.fel == nil and r.omstartMojlig == false and r.rosett == nil, fmt(image()))

print("\n── 6. Omstart (TR 314.1.1, 301.3.1.2) ──")
nyttForsok(); overStartlinjen()
till(R.u, B.v - 6); till(R.u, R.v - 5); till(R.u, R.v + 4) -- fel väg i försök 1
check("KONTROLL: försök 1 utesluten med omstart möjlig", image().resultat and image().resultat.omstartMojlig == true)
tillStart()
local okR, _, b2 = request("retry")
check("omstart öppnar försök 2", okR and b2.forsokNr == 2 and b2.lage == "to_start", fmt(b2))
helaBanan()
r = image().resultat
check("försök 2 utan fel: inga observerade fel, ingen rosett, ingen ny omstart", r and r.forsokNr == 2
	and r.utfall == "inga_observerade_fel" and r.rosett == nil and r.omstartMojlig == false, fmt(image()))
check("ingen tredje start via omstart", request("retry") == false)
-- Försök 2 MED fel: TR 314.1.1 ger bara ett försök till, så ingen ny omstart.
nyttForsok(); overStartlinjen()
till(R.u, B.v - 6); till(R.u, R.v - 5); till(R.u, R.v + 4) -- fel väg i försök 1
tillStart(); request("retry")
overStartlinjen(); utbrytningBla(); hopp1(); hopp2(); hopp3(); hopp4(); malet()
r = image().resultat
check("försök 2 med en olydnad: observerade fel men INGEN omstart", r and r.forsokNr == 2
	and r.utfall == "observerade_fel" and r.omstartMojlig == false, fmt(image()))
check("och servern nekar en tredje start via omstart", request("retry") == false)

print("\n── 7. Avsittning mitt i banan: ritten avbryts ──")
nyttForsok(); overStartlinjen(); hopp1()
local aktivt = RidForsok.aktivt(id)
check("avsittning stänger försöket (ritten slut)", aktivt ~= nil and HorseService.dismount(p) == true
	and HorseService.forsok(aktivt.forsokId).orsak == "ritt_slut:avsittning")

print("\n── 8. Klienten: menyn, sidans texter, guiden och resultatkortet ──")
;(function()
	Skopa._nollstallForProv()
	id = mount(); nu = { u = 0, v = 4 }
	local VC, UC = VoltLektionController, UgnetaController
	local syncC = Networking.get("VoltLektionSync")
	local function leverera() syncC.OnClientEvent:Fire(image()) end
	local function hitta(lista, txt)
		for _, k in ipairs(lista) do if k.text == txt then return k end end
		return nil
	end
	local function borjar(t, x) return type(t) == "string" and string.sub(t, 1, #x) == x end
	local function har(t, x) return type(t) == "string" and string.find(t, x, 1, true) ~= nil end
	Sprak.satVal("sv")
	VC.avbryt(); VC.start(id, nil)
	UC.satLektionsVal(VC.panel)
	UC.dolj()
	-- Menyn: Ridvägar → Clear round (träning).
	local vag = hitta(UC.panel(4).knappar, Sprak.t("lektionsval.vagar"))
	if vag then vag.skicka() end
	local sida = UC.panel(4).knappar
	local val = hitta(sida, Sprak.t("clearround.choose"))
	check("menyn: Ridvägar bär «Clear round (träning)» och ryms i fyra rader", val ~= nil and #sida <= 4,
		("%d rader"):format(#sida))
	if val then val.skicka() end
	check("valet öppnar clear round med Starta ritten", VC.lektion() and hitta(VC.panel().knappar,
		Sprak.t("clearround.start")) ~= nil)
	-- Startsignalen och startlinjen.
	tillStart(); request("start"); leverera()
	check("sidan säger startsignal och startlinjen", borjar(VC.panel().text, Sprak.t("clearround.to_start")),
		VC.panel().text)
	local guide = workspace:FindFirstChild("Voltguide")
	check("guiden ritar start- och mållinjen (streck, inga hinder)", guide ~= nil and #guide:GetChildren() > 0,
		guide and #guide:GetChildren() or 0)
	overStartlinjen(); leverera()
	check("sidan säger nästa hinder: «Hinder 1: blått, mot C.»",
		borjar(VC.panel().text, Sprak.t("clearround.hopp", 1, Sprak.t("clearround.farg_bla"), "C")), VC.panel().text)
	hopp1(); hopp2(); leverera()
	check("efter två hopp: «Hinder 3: blått, mot A.»",
		borjar(VC.panel().text, Sprak.t("clearround.hopp", 3, Sprak.t("clearround.farg_bla"), "A")), VC.panel().text)
	hopp3(); hopp4(); leverera()
	check("efter sista hoppet: mot mållinjen", borjar(VC.panel().text, Sprak.t("clearround.to_finish")), VC.panel().text)
	malet(); leverera()
	local t = VC.panel().text
	check("resultatkortet: inga observerade fel, förenklad bedömning, träningsbana", har(t,
		string.sub(Sprak.t("aterkoppling.clearround.inga_fel", "X"), 1, 22)) and har(t, Sprak.t("aterkoppling.clearround.forenklad")), t)
	check("resultatkortet säger aldrig felfri", not har(string.lower(t), "felfri"), t)
	check("utan fel: ingen omstartsknapp", hitta(VC.panel().knappar, Sprak.t("clearround.retry")) == nil)
	LararInstallning.satDetalj("kort")
	check("kort text: domen och förbehållet står kvar", har(VC.panel().text, Sprak.t("aterkoppling.clearround.forenklad")))
	LararInstallning.satDetalj("detaljerad")
	-- Med fel: omstart erbjuds.
	nyttForsok(); overStartlinjen(); utbrytningBla(); hopp1(); hopp2(); hopp3(); hopp4(); malet(); leverera()
	t = VC.panel().text
	check("med en olydnad: felraden och omstart", har(t, Sprak.t("aterkoppling.clearround.omstart"))
		and hitta(VC.panel().knappar, Sprak.t("clearround.retry")) ~= nil, t)
	Sprak.satVal("en")
	check("engelska: förenklad bedömning", har(VC.panel().text, Sprak.t("aterkoppling.clearround.forenklad"))
		and har(VC.panel().text, "Simplified judging"), VC.panel().text)
	Sprak.satVal("sv")
	UC.satLektionsVal(nil)
	VC.avbryt()
	request("finish")
end)()

check("lektionen skriver aldrig persistent data", (__datastore.forsok and __datastore.forsok.skriv or 0) == writes)
if fails > 0 then error(("%d mätning(ar) föll."):format(fails), 0) end
print(string.format("\nclearroundlektion.spec: %d prov, alla gröna", total))
