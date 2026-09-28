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
-- D2b: anmälan → banskiss → startsignal (start gäller bara i banskissen).
local function starta()
	request("anmal"); request("ga_banan")
	return request("start")
end
local function nyttForsok()
	request("finish")
	tillStart()
	return starta()
end

print("\n── 1. Hela banan i ordning: inga observerade fel, förenklad, ingen rosett ──")
tillStart()
check("D2b: startsignal direkt ur «ready» nekas (anmälan först), inget försök", image().lage == "ready"
	and request("start") == false and RidForsok.aktivt(id) == nil)
local ok, _, b = starta()
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

print("\n── 7. Avsittning mitt i banan: ETT slutligt utfall, «avbruten» ──")
nyttForsok(); overStartlinjen(); hopp1()
local aktivt = RidForsok.aktivt(id)
check("avsittning mitt i banan", aktivt ~= nil and HorseService.dismount(p) == true)
local avb = ClearRoundLektion._senasteForProv(p.UserId)
check("utfallet är «avbruten» (avsittning), aldrig framgång, ingen omstart, ingen rosett", avb ~= nil
	and avb.utfall == "avbruten" and avb.orsak == "avsittning" and avb.omstartMojlig == false
	and avb.rosett == nil and avb.felfri == nil and avb.fel == nil and avb.forsokId == aktivt.forsokId)
check("försöket är avbrutet, en gång (inte ett slutfört)", HorseService.forsok(aktivt.forsokId).orsak == "avbrutet")
id = mount(); nu = { u = 0, v = 4 }
local bi = image()
check("nästa gång clear round öppnas syns det avbrutna utfallet", bi.lage == "ready" and bi.forraAvbruten ~= nil
	and bi.forraAvbruten.utfall == "avbruten")
tillStart(); starta()
check("en ny ritt tar bort det", image().forraAvbruten == nil and ClearRoundLektion._senasteForProv(p.UserId) == nil)
-- En avsittning EFTER ett färdigt resultat ändrar ingenting.
overStartlinjen(); hopp1(); hopp2(); hopp3(); hopp4(); malet()
local fardig = image().resultat
check("KONTROLL: ett färdigt resultat", fardig and fardig.utfall == "inga_observerade_fel")
HorseService.dismount(p)
check("avsittning efter ett färdigt resultat ger inget avbrutet utfall",
	ClearRoundLektion._senasteForProv(p.UserId) == nil)
id = mount(); nu = { u = 0, v = 4 }
check("och nästa öppning visar inget avbrutet", image().forraAvbruten == nil)
-- R2: ett rittslut som INTE är en avsittning (karaktären försvinner) ger samma
-- slutliga utfall, med sitt riktiga skäl — aldrig framgång, omstart eller rosett.
tillStart(); starta(); overStartlinjen(); hopp1()
local aktivt2 = RidForsok.aktivt(id)
p.CharacterRemoving:Fire(p.Character)
local avb2 = ClearRoundLektion._senasteForProv(p.UserId)
check("karaktären borta mitt i banan: «avbruten» med skälet karaktar_borta", avb2 ~= nil
	and avb2.utfall == "avbruten" and avb2.orsak == "karaktar_borta" and avb2.omstartMojlig == false
	and avb2.rosett == nil and avb2.felfri == nil and avb2.fel == nil
	and aktivt2 ~= nil and avb2.forsokId == aktivt2.forsokId, avb2 and avb2.orsak)
check("det försöket är också avbrutet, inte slutfört", aktivt2 ~= nil
	and HorseService.forsok(aktivt2.forsokId).orsak == "avbrutet")
p.Character = player(996).Character
id = mount(); nu = { u = 0, v = 4 }
local bk = image()
check("nästa öppning bär skälet karaktar_borta", bk.forraAvbruten ~= nil and bk.forraAvbruten.orsak == "karaktar_borta")
KARAKTAR_BORTA_BILD = bk
tillStart(); starta()

print("\n── 7b. D2b före ritten: anmälan, solo startlista, banskiss ──")
;(function()
	request("finish")
	tillStart()
	local okA, _, ba = request("anmal")
	check("anmälan ger startlistan, inget försök öppnas", okA and ba.lage == "startlista"
		and RidForsok.aktivt(id) == nil, fmt(ba))
	check("anmälan: startnummer 1, 1 anmäld (solo), klassens höjd och hästen", type(ba.anmalan) == "table"
		and ba.anmalan.startnummer == 1 and ba.anmalan.anmalda == 1 and ba.anmalan.hojdM == G.HOJD_M
		and ba.anmalan.hastId ~= nil)
	local h = ba.referens and ba.referens.hinder
	check("banans geometri följer med: fyra hinder i ordning, färg och riktning ur servern", type(h) == "table"
		and #h == 4 and h[1].farg == "bla" and h[1].mot == "C" and h[2].farg == "rod" and h[2].mot == "C"
		and h[3].farg == "bla" and h[3].mot == "A" and h[4].farg == "rod" and h[4].mot == "C")
	check("startsignal i startlistan nekas", request("start") == false and image().lage == "startlista")
	check("en andra anmälan nekas", request("anmal") == false)
	local okF, _, bf = request("finish")
	check("avsluta i startlistan: stängd, anmälan borta, inget försök", okF and bf.lage == "closed"
		and bf.anmalan == nil and RidForsok.aktivt(id) == nil)
	check("startsignal från stängd nekas (anmälan först)", request("start") == false)
	request("anmal")
	local okG, _, bg = request("ga_banan")
	check("gå banan ger banskissen", okG and bg.lage == "banskiss" and bg.delmal == 0 and bg.anmalan ~= nil)
	check("gå banan en gång till nekas", request("ga_banan") == false)
	local okF2, _, bf2 = request("finish")
	check("avsluta i banskissen: stängd, anmälan borta, inget försök", okF2 and bf2.lage == "closed"
		and bf2.anmalan == nil and RidForsok.aktivt(id) == nil)
	-- Utanför banan: ingen anmälan.
	till(B.u - 12, nu.v)
	local okU, felU = request("anmal")
	check("anmälan utanför banan nekas (place), inget registreras", okU == false and felU == "place"
		and image().anmalan == nil and image().lage == "closed", tostring(felU))
	tillStart()
	-- Omstart efter fel behåller anmälan och går direkt mot startlinjen.
	starta(); overStartlinjen()
	till(R.u, B.v - 6); till(R.u, R.v - 5); till(R.u, R.v + 4) -- fel väg
	tillStart()
	local okR2, _, br = request("retry")
	check("omstart efter fel: direkt mot startlinjen, anmälan kvar", okR2 and br.lage == "to_start"
		and br.forsokNr == 2 and br.anmalan ~= nil and br.anmalan.startnummer == 1)
	request("finish")
end)()

-- Avbruten igen, för klientprovet nedan.
tillStart(); starta(); overStartlinjen(); hopp1()
HorseService.dismount(p)

print("\n── 8. Klienten: menyn, sidans texter, guiden och resultatkortet ──")
;(function()
	Skopa._nollstallForProv()
	id = mount(); nu = { u = 0, v = 4 }
	local VC, UC = VoltLektionController, UgnetaController
	local sync0 = Networking.get("VoltLektionSync")
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
	check("valet öppnar clear round med «Anmäl dig» (ingen startsignal ännu)", VC.lektion()
		and hitta(VC.panel().knappar, Sprak.t("clearround.anmal")) ~= nil
		and hitta(VC.panel().knappar, Sprak.t("clearround.start")) == nil)
	sync0.OnClientEvent:Fire(image())
	check("avsittning: sidan säger att förra ritten avbröts när ni satt av",
		borjar(VC.panel().text, Sprak.t("clearround.forra_avbruten_avsittning")), VC.panel().text)
	--[[ R2: ett annat rittslut säger det neutrala — aldrig «satt av». Bilden med
		skälet karaktar_borta levereras med högre revision (deklarerad klientbild). ]]
	do
		local fake = table.clone(KARAKTAR_BORTA_BILD)
		fake.rittId = id; fake.revision = image().revision + 1000
		sync0.OnClientEvent:Fire(table.freeze(fake))
		local tt = VC.panel().text
		check("karaktären borta: sidan säger det neutrala, inte «satt av»",
			borjar(tt, Sprak.t("clearround.forra_avbruten")) and not string.find(tt, "satt av", 1, true), tt)
		Sprak.satVal("en")
		tt = VC.panel().text
		check("engelska, neutralt: inte «dismounted»", not string.find(tt, "dismounted", 1, true)
			and string.find(tt, "interrupted mid-course", 1, true) ~= nil, tt)
		Sprak.satVal("sv")
		-- Klientens bild nollställs (typbyte och tillbaka), så att serverns riktiga,
		-- lägre revisioner tas emot igen för resten av provet.
		VC.valj("halt"); VC.valj("clearround")
	end
	-- D2b: anmälan och banskiss i den riktiga panelen.
	tillStart()
	request("anmal"); leverera()
	check("startlistan: «Anmäld … startnummer 1 · 1 anmäld» och knappen «Gå banan»",
		borjar(VC.panel().text, Sprak.t("clearround.startlista", "0,68", 1, 1))
		and hitta(VC.panel().knappar, Sprak.t("clearround.ga_banan")) ~= nil, VC.panel().text)
	request("ga_banan"); leverera()
	local sk = VC.panel().text
	check("banskissen: 1–4 med färg och riktning, «förenkling», knappen «Starta ritten»",
		string.find(sk, "1 blått mot C · 2 rött mot C · 3 blått mot A · 4 rött mot C", 1, true) ~= nil
		and string.find(sk, "förenkling", 1, true) ~= nil
		and hitta(VC.panel().knappar, Sprak.t("clearround.start")) ~= nil, sk)
	check("banskissen visar start- och mållinjen i guiden", workspace:FindFirstChild("Voltguide") ~= nil)
	Sprak.satVal("en")
	check("banskissen på engelska", string.find(VC.panel().text, "1 blue towards C", 1, true) ~= nil
		and string.find(VC.panel().text, "walk the course on foot", 1, true) ~= nil, VC.panel().text)
	Sprak.satVal("sv")
	-- Startsignalen och startlinjen.
	request("start"); leverera()
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
	--[[ Sist i klientdelen, före nedmonteringen (ingen återställning behövs efteråt).
		Banskissen följer SERVERNS geometri, inte en bana i klienten: en deklarerad
		bild med en annan bana (tre hinder, andra färger och riktningar) ger det kortet. ]]
	do
		local fake = table.clone(image())
		local ref = table.clone(fake.referens or {})
		ref.hinder = { { farg = "rod", mot = "A" }, { farg = "bla", mot = "A" }, { farg = "rod", mot = "C" } }
		fake.lage, fake.tips, fake.anmalan = "banskiss", "banskiss", image().anmalan
		fake.referens = ref; fake.revision = image().revision + 1000
		sync0.OnClientEvent:Fire(table.freeze(fake))
		local tt = VC.panel().text
		check("banskissen läser serverns bana (deklarerad annan bana syns ordagrant)",
			string.find(tt, "1 rött mot A · 2 blått mot A · 3 rött mot C.", 1, true) ~= nil
			and string.find(tt, "efter hinder 3", 1, true) ~= nil, tt)
	end
	UC.satLektionsVal(nil)
	VC.avbryt()
	request("finish")
end)()

check("lektionen skriver aldrig persistent data", (__datastore.forsok and __datastore.forsok.skriv or 0) == writes)
if fails > 0 then error(("%d mätning(ar) föll."):format(fails), 0) end
print(string.format("\nclearroundlektion.spec: %d prov, alla gröna", total))
