--!nostrict
--[[ TEMPOCOACHNING — docs/TEMPO-COACHING-CONTRACT.md. Uppställningen är tempolektion-
	specens egen, ordagrant; dess ursprungliga huvud följer. ]]
--[[

	BANK_ONLY, KOHERENS-bänken: riktig HorseService, riktigt byggt ridhus,
	riktiga observationer. Gångarten ändras genom produktionens
	`RidingIntent` (driv/broms); rotens läge sätts mellan hjärtslagen på
	en cirkel (R 8 m kring (U, 16)) inne i layouten, så att farten per steg
	är känd (syntetisk rutt, inte spelarens ridning).

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
--[[ Bänken har ingen riktig tid: klientavsnitten skickar många begäranden i
	rad, och takten nekade dem (takt.for_snabbt). Skopas klocka hoppas fram vid
	varje läsning, som i instruktorstart.spec. ]]
Skopa._satKlockaForProv((function() local k = 0; return function() k += 100; return k end end)())
HorseService.setMountGate(nil); HorseService.start()
local writes = __datastore.forsok and __datastore.forsok.skriv or 0
local G = TempoLektion.GRANSER

local function player(id)
	local c = Instance.new("Model")
	local root = Instance.new("Part"); root.Name = "HumanoidRootPart"; root.Size = vec(2,2,1); root.Parent = c
	local h = Instance.new("Humanoid"); h.Name = "Humanoid"; h.Parent = c
	return { UserId = id, Name = "Tempo" .. id, Character = c,
		CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }
end
local p = Players.LocalPlayer
p.Character = player(951).Character
Players._spelare = { p }
local horse = HastRigg.bygg("tempo_test", "Tempo test", CFrame.new(Ridhusplats.tillVarld(RP, vec(0, 0, 4))))
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
	return HorseService.voltLektionsBegaran(p, id, op, seq, typ or "tempo")
end
local function image()
	local ok, _, b = HorseService.voltLektionsBegaran(p, id, "sync", nil, "tempo"); assert(ok); return b
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
--[[ Rakt till (u, v) med fart m/s (steg om 0,25 s). ]]
local function rakt(u, v, fart)
	local d = math.sqrt((u - nu.u) ^ 2 + (v - nu.v) ^ 2)
	local n = math.max(1, math.ceil(d / ((fart or 1.45) * 0.25)))
	local u0, v0 = nu.u, nu.v
	for i = 1, n do ga(u0 + (u - u0) * i / n, v0 + (v - v0) * i / n) end
end
--[[ Cirkeln R 8 m kring (U, 16): nederst i (U, 8). ]]
local KR, KV = 8, 16
local fi = -math.pi / 2
local function gaFart(fart, n, dt)
	dt = dt or 0.25
	for _ = 1, n do
		fi += fart * dt / KR
		ga(U + KR * math.cos(fi), KV + KR * math.sin(fi), dt)
	end
end
local function tillsKlar(fart, max)
	for _ = 1, max do
		if image().lage == "complete" then return true end
		gaFart(fart, 1)
	end
	return image().lage == "complete"
end


--[[ ══ TEMPOCOACHNING — docs/TEMPO-COACHING-CONTRACT.md ════════════════
	Ovan: tempolektion-specens uppställning ordagrant (fixturen). Nedan:
	coachningens fall. SKRIVNA FÖR SENARE KÖRNING, inte körda.
	ETIKETTER:
	- PROV-DRIVET (SYNKRONT): avsnitt C1–C5 går genom riktiga
	  observationer och HorseService;
	- PÅHITTADE KLIENTBILDER: avsnitt C6–C8 levererar bilder genom
	  VoltLektionSync till den riktiga VoltLektionController och värden;
	  fälten har producentens form;
	- SAMMANFOGAT (R1): avsnitt J och J9 går från riktiga prov genom serverns
	  push till LocalPlayer, den riktiga kontrollern och
	  `UgnetaController.panel(4)`;
	- VERKLIGT FÖRDRÖJT (R1): avsnitt JD, Start på schemat.
	PLANERAT (inte skrivet genom den sammanfogade vägen): plats-nej, dubblett,
	timeout och Avsluta som FALL — Avsluta används här bara som städning, med
	identiteten ur serverns begäranbok och godkännandet kontrollerat. ]]
local function nr() return image().coachNr or 0 end

print("\n── C1. För långsamt: en händelse per färskt prov, inte per läsning ──")
do
	request("finish")
	aid("driv")
	rakt(U, 8)
	gaFart(1.45, 3)
	request("start")
	gaFart(1.45, 2)
	local n0 = nr()
	for _ = 1, 4 do ga(nu.u, nu.v) end -- står still i skritt: för långsamt
	local n1 = nr()
	check("fyra färska långsamma prov ger fyra händelser (samma skäl två gånger ÄR två händelser)",
		n1 == n0 + 4 and image().coachSkal == "too_slow")
	for _ = 1, 5 do image() end
	check("upprepade läsningar ger inga händelser", nr() == n1)
end

print("\n── C2. För fort och ojämnt ──")
do
	local n0 = nr()
	gaFart(2.8, 3)
	check("för fort ger händelser med skälet too_fast", nr() > n0 and image().coachSkal == "too_fast")
	gaFart(1.45, 3)
	local n1 = nr()
	for _ = 1, 3 do gaFart(1.0, 1); gaFart(1.9, 1) end
	check("ojämn fart ger händelser med skälet steadier", nr() > n1 and image().coachSkal == "steadier")
end

print("\n── C3. Okänt, lucka, teleport och fel gångart är INTE fartbevis ──")
do
	gaFart(1.45, 3)
	local n0 = nr()
	ga(nu.u, nu.v, 5) -- lucka i provtakten
	check("en lucka ger ingen händelse", nr() == n0)
	ga(nu.u + 30, nu.v) -- teleport
	check("en teleport ger ingen händelse", nr() == n0)
	aid("driv") -- trav
	gaFart(3.0, 3)
	check("fel gångart ger ingen händelse (bara uppgiftstexten)", nr() == n0 and image().tips == "walk_only")
	aid("broms")
	gaFart(1.45, 3)
end

print("\n── C4. Jämförelsen: två riktiga fullföljanden i samma ritt ──")
local forsta, andra_
do
	request("finish")
	request("start")
	gaFart(1.45, 2)
	for _ = 1, 20 do gaFart(1.3, 1); gaFart(1.5, 1) end -- lätt ojämnt men inom gränsen
	check("KONTROLL: första fullföljandet", tillsKlar(1.45, 80))
	forsta = image()
	check("första fullföljandet har ingen jämförelse", forsta.jamforelse == nil)
	request("retry")
	gaFart(1.45, 2)
	check("KONTROLL: andra fullföljandet", tillsKlar(1.45, 80))
	andra_ = image()
	local j = andra_.jamforelse
	check("andra fullföljandet jämförs med det förra DISTINKTA", j ~= nil and j.forsokId == andra_.forsokId
		and j.forraForsokId == forsta.forsokId and j.forraSpridning == forsta.resultat.spridning
		and j.spridning == andra_.resultat.spridning)
	for _ = 1, 3 do image() end
	check("en dubblettläsning ändrar inte jämförelsen", image().jamforelse == j)
end

print("\n── C5. Tidsgräns skriver inte över baslinjen; typbyte (A-B-A) nollställer ──")
do
	request("retry")
	s.voltLektion.deadline = os.clock()
	gaFart(1.45, 1)
	check("KONTROLL: tidsgräns", image().lage == "timeout" and image().jamforelse == nil)
	request("retry")
	gaFart(1.45, 2)
	check("KONTROLL: tredje fullföljandet", tillsKlar(1.45, 80))
	check("jämförelsen är mot det förra GILTIGA fullföljandet, inte tidsgränsen",
		image().jamforelse ~= nil and image().jamforelse.forraForsokId == andra_.forsokId)
	request("finish")
	request("start", "halt"); request("finish", "halt")
	request("start")
	gaFart(1.45, 2)
	check("KONTROLL: efter typbytet", tillsKlar(1.45, 80))
	check("A-B-A: nytt lektionsobjekt, ingen baslinje, ingen jämförelse", image().jamforelse == nil)
	request("finish")
end

print("\n── C6. Klientens händelse: baslinje, spärr, visning, Inga/Färre, språk (PÅHITTADE BILDER) ──")
local VC, UC, I = VoltLektionController, UgnetaController, LararInstallning
local ev = Networking.get("VoltLektionSync")
local R = 10 ^ 6
local function bild_(f, nrNu, skal, lage)
	R += 1
	return { rittId = id, typ = "tempo", forsokId = f, revision = R, sekvens = 0, lage = lage or "steady",
		tips = skal or "keep_going", progress = 10, coachNr = nrNu, coachSkal = skal }
end
local function cue() return VC._coachningForProv() end
do
	I._aterstallForProv()
	Sprak.satVal("sv")
	VC.avbryt(); VC.start(id, nil)
	UC.satLektionsVal(VC.panel)
	UC.dolj()
	VC.valj("tempo")
	ev.OnClientEvent:Fire(bild_("F1", 3, "too_slow"))
	check("första bilden av ett försök sätter baslinjen, ingen coachning", cue() == nil)
	ev.OnClientEvent:Fire(bild_("F1", 3, "too_slow"))
	check("samma räknare igen (omritning) ger ingen coachning", cue() == nil)
	ev.OnClientEvent:Fire(bild_("F1", 4, "too_slow"))
	local t = UC.panel(4).text or ""
	check("en ny händelse: coachningen först, uppgiften efter", cue() ~= nil
		and string.sub(t, 1, #Sprak.t("tempocoach.too_slow")) == Sprak.t("tempocoach.too_slow")
		and string.find(t, Sprak.t("tempolektion.too_slow"), 1, true) ~= nil, t)
	check("högst fyra rader i den sammansatta värden", #UC.panel(4).knappar <= 4)
	Sprak.satVal("en")
	check("språkbyte: samma coachning på engelska", cue() ~= nil and string.find(UC.panel(4).text or "",
		Sprak.iSprak("en", "tempocoach.too_slow"), 1, true) ~= nil)
	Sprak.satVal("sv")
	I.satDetalj("kort"); I.satDetalj("detaljerad")
	check("detaljbyte skapar ingen ny", cue() ~= nil)
	ev.OnClientEvent:Fire(bild_("F1", 5, "too_fast"))
	--[[ R1: den nya, oförenliga klassningen tar bort den synliga raden DIREKT;
		under spärren visas ingen ny. ]]
	check("under spärren: den oförenliga händelsen tar bort raden direkt, ingen ny", cue() == nil)
	for _ = 1, 540 do VC.steg(1 / 60) end -- 9 s: spärren slut
	ev.OnClientEvent:Fire(bild_("F1", 6, "steadier"))
	check("efter spärren: en ny händelse visas", cue() ~= nil and cue().skal == "steadier")
	I.satKommentarer("inga")
	check("Inga medan den syns: borta direkt", cue() == nil and not string.find(UC.panel(4).text or "",
		Sprak.t("tempocoach.steadier"), 1, true))
	I.satKommentarer("normal")
	check("tillbaka till Normalt: den förbrukade kommer inte tillbaka", cue() == nil)
	for _ = 1, 600 do VC.steg(1 / 60) end
	I.satKommentarer("farre")
	ev.OnClientEvent:Fire(bild_("F1", 7, "too_slow"))
	check("Färre, första valbara händelsen: visas", cue() ~= nil)
	for _ = 1, 600 do VC.steg(1 / 60) end
	ev.OnClientEvent:Fire(bild_("F1", 8, "too_slow"))
	check("Färre, andra: förbrukas", cue() == nil)
	I.satKommentarer("normal")
end

print("\n── C7. Omvända svar, A-B-A, återkoppling, ritt, hälsningens företräde (PÅHITTADE BILDER) ──")
do
	for _ = 1, 600 do VC.steg(1 / 60) end
	local gammal = bild_("F1", 20, "too_fast")
	gammal.revision = 1 -- ett försenat äldre svar
	ev.OnClientEvent:Fire(gammal)
	check("ett äldre (omvänt) svar med högre räknare ger ingen coachning", cue() == nil)
	VC.valj("halt"); VC.valj("tempo")
	ev.OnClientEvent:Fire(bild_("F1", 21, "too_fast"))
	check("A-B-A: första bilden efteråt är baslinje, ingen coachning", cue() == nil)
	VC.start(id, nil)
	ev.OnClientEvent:Fire(bild_("F1", 22, "too_fast"))
	check("återkoppling: baslinje, ingen coachning", cue() == nil)
	ev.OnClientEvent:Fire(bild_("F2", 1, "too_slow"))
	check("ett nytt försök: baslinje, ingen coachning", cue() == nil)
	local annanRitt = bild_("F2", 2, "too_slow"); annanRitt.rittId = "annan"
	ev.OnClientEvent:Fire(annanRitt)
	check("en annan ritts bild ger ingen coachning", cue() == nil)
	ev.OnClientEvent:Fire(bild_("F2", 2, "too_slow", "complete"))
	check("utanför steady ger ingen coachning", cue() == nil)
	-- Hälsningens företräde: ett godtaget start med en påhittad svarsbild.
	local remote = Networking.get("VoltLektion")
	local riktig = remote.InvokeServer
	VC.valj("halt"); VC.valj("tempo")
	remote.InvokeServer = function(_, rid, op, seqNu, t)
		return true, nil, { rittId = rid, typ = "tempo", forsokId = "F9", revision = 10 ^ 8, sekvens = seqNu,
			lage = "steady", tips = "walk_on", progress = 0, coachNr = 0 }
	end
	local forstaKnapp = VC.panel().knappar[1]
	if forstaKnapp then forstaKnapp.skicka() end
	remote.InvokeServer = riktig
	check("KONTROLL: hälsningen visas", VC._halsningForProv() ~= nil)
	local b9 = bild_("F9", 1, "too_slow"); b9.revision = 10 ^ 8 + 1
	ev.OnClientEvent:Fire(b9)
	check("hälsningen vinner: ingen coachning samtidigt, och händelsen köas inte", cue() == nil)
	VC.avbryt()
	check("avsittning: ingen coachning", cue() == nil)
end

print("\n── C8. Jämförelsens text: jämnare, lika, sämre, ojämförbar, dubblett, kort, SV/EN (PÅHITTADE BILDER) ──")
do
	local A = LektionsAterkoppling
	local function klar(sp, forraSp, forraId)
		local r = table.freeze({ forsokId = "K2", rittId = "r", userId = 1, hastId = "h", ovning = "jamn_skritt",
			enhet = "m/s", prov = 32, sekunder = 8, meter = 11.6, medelFart = 1.45, spridning = sp })
		return { lage = "complete", typ = "tempo", forsokId = "K2", rittId = "r", resultat = r,
			jamforelse = if forraSp then { forsokId = "K2", forraForsokId = forraId or "K1",
				forraSpridning = forraSp, spridning = sp } else nil }
	end
	local k = { typ = "tempo", ritt = "r" }
	check("jämnare när de avrundade procenten skiljer sig rätt håll",
		string.find(A.text(klar(0.02, 0.14), k), Sprak.t("tempocoach.jamnare", "14", "2"), 1, true) ~= nil)
	check("lika (avrundat lika) är neutralt", string.find(A.text(klar(0.101, 0.098), k),
		Sprak.t("tempocoach.forra", "10", "10"), 1, true) ~= nil)
	check("sämre är neutralt, aldrig 'jämnare'", string.find(A.text(klar(0.2, 0.05), k),
		Sprak.t("tempocoach.forra", "5", "20"), 1, true) ~= nil)
	check("ojämförbar (NaN): ingen jämförelse", not string.find(A.text(klar(0.1, 0 / 0), k), "%", 1, true)
		or string.find(A.text(klar(0.1, 0 / 0), k), Sprak.t("tempocoach.forra", "nan", "10"), 1, true) == nil)
	check("en jämförelse med sig själv visas aldrig", string.find(A.text(klar(0.02, 0.14, "K2"), k),
		Sprak.t("tempocoach.jamnare", "14", "2"), 1, true) == nil)
	I.satDetalj("kort")
	check("kort: bara 'jämnare än förra gången' när det håller", string.find(A.text(klar(0.02, 0.14), k),
		Sprak.t("tempocoach.jamnare_kort"), 1, true) ~= nil and string.find(A.text(klar(0.2, 0.05), k),
		Sprak.t("tempocoach.jamnare_kort"), 1, true) == nil)
	I.satDetalj("detaljerad")
	Sprak.satVal("en")
	check("på engelska", string.find(A.text(klar(0.02, 0.14), k), "More even than your previous attempt", 1, true) ~= nil)
	Sprak.satVal("sv")
end

print("\n── J. R1: DEN SAMMANFOGADE VÄGEN — riktiga prov → serverns push → klienten → den sammansatta värden (SYNKRONT) ──")
--[[ Fixturens spelare ÄR `Players.LocalPlayer`, så serverns
	`VoltLektionSync:FireClient` levererar till den riktiga
	VoltLektionController (bänkens FireClient levererar till LocalPlayer). ]]
local jEv = Networking.get("VoltLektionSync")
local function jCue() return VoltLektionController._coachningForProv() end
local function jText() return UgnetaController.panel(4).text or "" end
local function borjarMed(t, del) return string.sub(t, 1, #del) == del end
local function jKnapp(nyckel)
	local t = Sprak.t(nyckel)
	for _, k in ipairs(UgnetaController.panel(4).knappar) do if k.text == t then return k end end
	return nil
end
local function vantaUtSparren() for _ = 1, 600 do VoltLektionController.steg(1 / 60) end end
--[[ R1-uppföljning: en direkt begäran tar sin identitet ur serverns
	begäranbok (högsta + 1), eftersom klientens egna begäranden också har
	flyttat den — fixturens egen räknare kan vara inaktuell. ]]
local function begaranNu(op, t)
	local bok = s.lektionsBegaran
	seq = (bok and bok.hogsta or 0) + 1
	return HorseService.voltLektionsBegaran(p, id, op, seq, t or "tempo")
end
local function avslutaNu(namn)
	local okA = begaranNu("finish")
	check("KONTROLL " .. namn .. ": Avsluta godtogs av servern", okA == true)
end
do
	local VCj, UCj = VoltLektionController, UgnetaController
	LararInstallning._aterstallForProv()
	Sprak.satVal("sv")
	avslutaNu("J")
	-- Hästen går redan i skritt (C3 slutade med broms från trav till skritt).
	gaFart(1.45, 3)
	VCj.avbryt(); VCj.start(id, nil)
	UCj.satLektionsVal(VCj.panel)
	UCj.dolj()
	--[[ Ett typbyte på klienten släpper dess gamla bild (som ett riktigt val gör);
		utan det kunde en bild från ett tidigare lektionsobjekt med högre revision
		vinna över serverns nya. Avsluta gick direkt till servern (inte genom
		klienten), så klienten får den stängda bilden som en push. ]]
	VCj.valj("volt"); VCj.valj("tempo")
	Networking.get("VoltLektionSync").OnClientEvent:Fire(
		select(3, HorseService.voltLektionsBegaran(p, id, "sync", nil, "tempo")))
	local start = jKnapp("tempolektion.start")
	check("KONTROLL J: Start finns i den sammansatta värden", start ~= nil)
	if start then start.skicka() end
	check("KONTROLL J: servern godtog startet", RidForsok.aktivt(id) ~= nil)
	for _ = 1, 480 do VCj.steg(1 / 60) end -- hälsningen (6 s) ute ur vägen
	gaFart(1.45, 3)
	check("KONTROLL J: ingen coachning av jämn skritt", jCue() == nil)
	-- J1: för långsamt.
	for _ = 1, 2 do ga(nu.u, nu.v) end
	check("J1 långsamt: raden först i värdens text, uppgiften efter", jCue() ~= nil and jCue().skal == "too_slow"
		and borjarMed(jText(), Sprak.t("tempocoach.too_slow")) and string.find(jText(), Sprak.t("tempolektion.too_slow"), 1, true) ~= nil,
		jText())
	-- J2: långsamt -> fort under spärren: bort direkt, ingen ny.
	gaFart(2.8, 1)
	check("J2 långsamt -> fort under spärren: raden bort direkt, ingen ny", jCue() == nil
		and not string.find(jText(), Sprak.t("tempocoach.too_slow"), 1, true)
		and not string.find(jText(), Sprak.t("tempocoach.too_fast"), 1, true), jText())
	-- J6 (efter en ritning i J2): samma skäl igen under spärren visar ingenting.
	for _ = 1, 2 do ga(nu.u, nu.v) end -- långsamt igen, fortfarande under spärren
	check("J6 samma skäl under spärren efter en borttagning: ingenting visas", jCue() == nil)
	-- J8: färsk händelse efter spärren.
	vantaUtSparren()
	ga(nu.u, nu.v)
	check("J8 en färsk händelse efter spärren visas", jCue() ~= nil)
	-- J3: långsamt -> lucka.
	ga(nu.u, nu.v, 5)
	check("J3 långsamt -> lucka (okänt): raden bort", jCue() == nil)
	-- J4: fel gångart.
	vantaUtSparren()
	gaFart(1.45, 3)
	ga(nu.u, nu.v)
	check("KONTROLL J4: en rad visas", jCue() ~= nil)
	aid("driv") -- trav
	gaFart(3.0, 1)
	check("J4 fel gångart (walk_only): raden bort", jCue() == nil)
	aid("broms")
	gaFart(1.45, 3)
	-- J6b: bort och återhämtning UTAN någon ritning emellan (bara `_coachningForProv` läses).
	vantaUtSparren()
	gaFart(1.45, 3)
	ga(nu.u, nu.v)
	check("KONTROLL J6b: en rad visas (utan att värden ritats)", jCue() ~= nil)
	gaFart(2.8, 1) -- fort: den godtagna bilden stöder inte raden
	ga(nu.u, nu.v) -- långsamt igen, under spärren
	check("J6b borttagen i mottag före någon ritning, och återhämtningen visar inget", jCue() == nil)
	check("J6b och den första ritningen därefter saknar raden",
		not string.find(jText(), Sprak.t("tempocoach.too_slow"), 1, true))
	gaFart(1.45, 3)
	-- J5: ett högre osett nummer i en nyare oförenlig bild.
	vantaUtSparren()
	local riktigFire = jEv.FireClient
	jEv.FireClient = function() end -- klienten missar pushen
	ga(nu.u, nu.v) -- långsamt: servern räknar upp
	jEv.FireClient = riktigFire
	ga(nu.u, nu.v, 5) -- lucka: nyare bild, tips unknown, högre coachNr
	check("KONTROLL J5: bilden bär ett högre nummer men inget aktuellt skäl",
		image().tips == "unknown" and image().coachSkal == nil)
	check("J5 ett osett högre nummer i en oförenlig bild ger ingen rad", jCue() == nil)
	-- J7: dubblett / äldre bild.
	gaFart(1.45, 3)
	local gammal = image()
	vantaUtSparren()
	ga(nu.u, nu.v)
	local nyRad = jCue()
	jEv.OnClientEvent:Fire(gammal)
	check("J7 en äldre bild förkastas och tar inte bort den aktuella raden", nyRad ~= nil and jCue() == nyRad)
end

print("\n── J9. R1: två riktiga fullföljanden med Retry genom klientens knapp → jämförelsen i värden (SYNKRONT) ──")
do
	local VCj, UCj = VoltLektionController, UgnetaController
	gaFart(1.45, 3)
	check("KONTROLL J9: första fullföljandet", tillsKlar(1.45, 80))
	local retry = jKnapp("voltlektion.retry")
	check("KONTROLL J9: Prova igen finns", retry ~= nil)
	if retry then retry.skicka() end
	gaFart(1.45, 2)
	check("KONTROLL J9: andra fullföljandet", tillsKlar(1.45, 80))
	local j = image().jamforelse
	check("KONTROLL J9: jämförelsen finns i bilden", j ~= nil)
	if j then
		local nuP, forrP = math.floor(j.spridning * 100 + 0.5), math.floor(j.forraSpridning * 100 + 0.5)
		local vantad = Sprak.t(if nuP < forrP then "tempocoach.jamnare" else "tempocoach.forra", tostring(forrP),
			tostring(nuP))
		check("J9 jämförelsens text står i den sammansatta värden", string.find(jText(), vantad, 1, true) ~= nil, jText())
	end
end

print("\n── JD. R1: VERKLIGT FÖRDRÖJT — Start på schemat, pushen (med händelsen) före det sena svaret ──")
do
	local VCj, UCj = VoltLektionController, UgnetaController
	local remote = Networking.get("VoltLektion")
	local riktig = remote.InvokeServer
	avslutaNu("JD")
	VCj.valj("halt"); VCj.valj("tempo") -- ny baslinje; valet före schemat
	gaFart(1.45, 3)
	__schemaPa(true)
	remote.InvokeServer = function(self, ...)
		local svar = table.pack(riktig(self, ...))
		task.wait() -- svaret dröjer
		return table.unpack(svar, 1, svar.n)
	end
	local start = jKnapp("tempolektion.start")
	check("KONTROLL JD: Start finns", start ~= nil)
	if start then start.skicka() end
	__schemaSteg() -- servern har godtagit, svaret väntar
	check("KONTROLL JD: försöket är aktivt", RidForsok.aktivt(id) ~= nil)
	gaFart(1.45, 3)
	for _ = 1, 2 do ga(nu.u, nu.v) end -- händelser, pushade FÖRE svaret
	check("JD pushen före svaret sätter baslinjen: ingen rad", jCue() == nil)
	__schemaTomKo()
	remote.InvokeServer = riktig
	__schemaPa(false)
	check("JD det sena (äldre) svaret skapar ingen rad", jCue() == nil)
	for _ = 1, 480 do VCj.steg(1 / 60) end
	vantaUtSparren()
	ga(nu.u, nu.v)
	check("JD en färsk händelse efter svaret visas", jCue() ~= nil)
	--[[ JS (R1-uppföljningen i 2522225): en ny begäran från klienten tar bort
		den synliga raden DIREKT i `skicka` — före svaret, som hålls kvar här. ]]
	local fin = jKnapp("tempolektion.finish")
	check("KONTROLL JS: Avsluta finns medan raden står", fin ~= nil and jCue() ~= nil)
	__schemaPa(true)
	remote.InvokeServer = function(self, ...)
		local svar = table.pack(riktig(self, ...))
		task.wait() -- svaret dröjer
		return table.unpack(svar, 1, svar.n)
	end
	if fin then fin.skicka() end
	check("JS en ny begäran tar bort raden direkt, före svaret", jCue() == nil)
	__schemaTomKo()
	remote.InvokeServer = riktig
	__schemaPa(false)
	avslutaNu("JD slut")
	UCj.satLektionsVal(nil)
	VCj.avbryt()
end

UC.satLektionsVal(nil)
Skopa._satKlockaForProv(nil)
if fails > 0 then error(tostring(fails) .. " FEL") end
print(string.format("\nTEMPOCOACHNING: %d prov, alla gröna", total))
