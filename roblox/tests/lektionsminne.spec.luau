--!nostrict
--[[ LEKTIONSMINNET — första klarad och ett nästa förslag (C4).
	docs/LESSON-MEMORY-CONTRACT.md.

	KOHERENS-bänken med haltlektion-specens uppställning:
	- riktig HorseService, riktigt byggt ridhus och riktiga observationer;
	- riktig SparService mot den stubbade DataStore (`__datastore`);
	- riktig RidForsok och riktig VoltLektionController.

	SKRIVEN FÖR SENARE KÖRNING (bygg nu, testa sist). Inte körd.
	BÄNKANTAGANDEN:
	- `task.defer` körs DIREKT i bänken (stubben), så ett skrivförsök sker i
	  samma anrop som markören; `task.delay` sparas bara och körs inte. För
	  att se det väntande läget hålls skrivningen nere med
	  `__datastore.felSkriv` och drivs sedan med
	  `LektionsMinne._forsokSparaForProv`;
	- `__datastore.foreSkriv` körs före transformatorn och `efterSkriv` efter
	  att raden landat, som stubben säger;
	- klientens `InvokeServer` når serverns handlare synkront. ]]
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
local LM = LektionsMinne
local RP = assert(Ridhusplats.los(workspace:FindFirstChild("Anläggning"):FindFirstChild("UBRF")))
Tags:nollstall(); Run._server = true; Run.Heartbeat:nollstall()
__datastore.nollstall()

local function nyPlayer(id)
	local c = Instance.new("Model")
	local root = Instance.new("Part"); root.Name = "HumanoidRootPart"; root.Size = vec(2, 2, 1); root.Parent = c
	local h = Instance.new("Humanoid"); h.Name = "Humanoid"; h.Parent = c
	return { UserId = id, Name = "Minne" .. id, Character = c,
		CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }
end
local p = Players.LocalPlayer
p.Character = nyPlayer(931).Character
p.UserId = 931
Players._spelare = { p }
SparService._glomHookarForProv()
SparService._glomForProv(p)
SparService.start()
--[[ Bänken har ingen riktig tid: klientavsnitten skickar många begäranden i
	rad, och takten nekade dem (takt.for_snabbt). Skopas klocka hoppas fram vid
	varje läsning, som i instruktorstart.spec. ]]
Skopa._satKlockaForProv((function() local k = 0; return function() k += 100; return k end end)())
HorseService.setMountGate(nil); HorseService.start()
local function tillstand() return LM._tillstandForProv(p) end
local function proj() return LM._projektion(tillstand()) end
local function rad() return __datastore._data["spelare_931"] end
local function radMarkor(typ)
	local r = rad()
	local f = r and r.framsteg and r.framsteg[LM.nyckel(typ)]
	return f
end

print("\n── 1. Ny spelare: betrodd historik, inget klarat ──")
check("KONTROLL: laddad och betrodd", SparService.betroddLasning(p) and tillstand() ~= nil)
check("projektionen: betrodd, alla tio ej klarade", (function()
	local pr = proj()
	if pr.historik ~= "betrodd" then return false end
	for _, typ in LM.TYPER do if pr.lektioner[typ] ~= "ej_klarad" then return false end end
	return true
end)())
check("nycklarna är versionerade per lektion", LM.nyckel("halt") == "lektion:halt:" .. HaltLektion.VERSION
	and LM.nyckel("vag_mitt") ~= LM.nyckel("vag_diag") and LM.nyckel("okand") == nil)

-- ── Haltlektionens riktiga väg (samma uppställning som haltlektion.spec) ──
local G = HaltLektion.GRANSER
local horse = HastRigg.bygg("minne_test", "Minne test", CFrame.new(Ridhusplats.tillVarld(RP, vec(0, 0, 18))))
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
local function still(u, v, sek) for _ = 1, math.ceil(sek / 0.25) do step(u, v) end end
step(0, 18)
local root = p.Character:FindFirstChild("HumanoidRootPart")
local a0 = point(0, 18) + vec(6, 0, 0); root.CFrame = CFrame.new(a0); root.Position = a0
local okM, _, id = HorseService.tryMount(p, horse)
check("KONTROLL: uppsuten", okM == true)
step(0, 18); step(0, 18)
local seq = 0
local function request(op, typ)
	seq += 1
	return HorseService.voltLektionsBegaran(p, id, op, seq, typ or "halt")
end
local function image()
	local _, _, b = HorseService.voltLektionsBegaran(p, id, "sync", nil, "halt"); return b
end
local intentSeq = 0
local function aid(h)
	s.sisteHjalp = -math.huge
	s.intentPolletter = Config.RIDINPUT.SkopaTak
	intentSeq += 1
	Networking.get("RidingIntent").OnServerEvent:Fire(p, id, h, intentSeq)
end
local X = HorseService.ridplats(id).dressyrMitt
local function haltForsok()
	still(0, 18, G.HALT_FORE + 0.5)
	aid("driv")
	for v = 19, X.v - 1 do step(X.u, v) end
	aid("broms")
	still(X.u, X.v - 0.5, G.HALT_EFTER + 0.75)
end

print("\n── 2. Riktig slutförd halt (Heartbeat-provet) → väntande → sparad → betrodd omläsning ──")
do
	request("start")
	__datastore.felSkriv = true -- håll skrivningen nere så att väntande syns
	haltForsok()
	__datastore.felSkriv = false
	check("KONTROLL: halten slutfördes", image().lage == "complete")
	check("markören väntar direkt, i minnet och i den cachade saven",
		tillstand().vantar.halt == true and SparService.save(p).framsteg[LM.nyckel("halt")].klarade == 1)
	check("projektionen säger 'vantar', inte 'sparad'", proj().lektioner.halt == "vantar")
	check("ännu inget i lagret av markören", radMarkor("halt") == nil)
	LM._forsokSparaForProv(p)
	check("efter en bekräftad skrivning: sparad", proj().lektioner.halt == "sparad"
		and tillstand().vantar.halt == nil)
	local f = radMarkor("halt")
	check("lagret: exakt en boolesk markör (1/1, ingen tid, ingen kvalitet)",
		f ~= nil and f.forsok == 1 and f.klarade == 1 and f.basta == nil and f.senast == 0)
end

print("\n── 3. Samma lektion igen, och Retry ──")
do
	request("retry")
	haltForsok()
	check("KONTROLL: andra halten slutfördes", image().lage == "complete")
	check("ingen ny väntande markör för en redan sparad lektion", tillstand().vantar.halt == nil)
	LM._forsokSparaForProv(p)
	local f = radMarkor("halt")
	check("markören räknas aldrig upp", f.forsok == 1 and f.klarade == 1)
	request("retry")
	check("Retry direkt efteråt tar inte bort minnet", proj().lektioner.halt == "sparad")
	request("finish")
end

print("\n── 3b. R1: klar INNE i begar — sync, och retry som nollställer i samma anrop ──")
--[[ BÄNKANTAGANDEN (KONTROLL nedan):
	- HorseService stegar lektionerna när dess ackumulator når 0,25 s;
	  varje 0,25 s-steg nollar den;
	- med dt 0,0625 (exakt i binärt) stegas lektionen var fjärde bildruta;
	- halten mäts i observationens tid, inte i lektionens `now`.
	Precis före den bildruta som skulle stega lektionen anropas begäran i
	stället: blir halten klar just där, sker övergången INNE i `begar`. En
	KONTROLL säger om Heartbeaten hann före (då mäter fallet inget). ]]
local function nollstall(typ)
	tillstand().bekraftad[typ] = nil
	tillstand().vantar[typ] = nil
	SparService.save(p).framsteg[LM.nyckel(typ)] = nil
	if rad() then rad().framsteg[LM.nyckel(typ)] = nil end
end
local function tillKlarIBegar(op)
	still(0, 18, G.HALT_FORE + 0.5)
	aid("driv")
	for v = 19, X.v - 1 do step(X.u, v) end
	aid("broms")
	local fore = s.voltLektion and s.voltLektion.forsokId
	local acc, iBegar, iHjarta = 0, false, false
	for _ = 1, math.ceil((G.HALT_EFTER + 2) / 0.0625) do
		if acc + 0.0625 >= 0.25 then
			request(op)
			local l = s.voltLektion
			if op == "sync" and l and l.lage == "complete" then iBegar = true; break end
			if op == "retry" and l and l.forsokId ~= fore then iBegar = true; break end
		end
		step(X.u, X.v - 0.5, 0.0625)
		acc += 0.0625
		if acc >= 0.25 then acc = 0 end
		local l = s.voltLektion
		if l and l.lage == "complete" then iHjarta = true; break end
	end
	return iBegar, iHjarta, fore
end
do
	nollstall("halt")
	request("start")
	local iBegar, iHjarta = tillKlarIBegar("sync")
	check("KONTROLL: övergången skedde i sync, inte i Heartbeaten", iBegar and not iHjarta)
	check("sync: markören föddes av övergången inne i begar",
		tillstand().vantar.halt == true or tillstand().bekraftad.halt == true)
	nollstall("halt")
	request("retry")
	local iBegarR, iHjartaR, foreR = tillKlarIBegar("retry")
	check("KONTROLL: övergången skedde i retry, inte i Heartbeaten", iBegarR and not iHjartaR)
	local ny = s.voltLektion
	check("retry: det nya försöket bär inget resultat (nollställt i samma anrop)",
		ny ~= nil and ny.forsokId ~= foreR and ny.resultat == nil)
	check("retry: det gamla försöket är slutfört i RidForsok", (RidForsok.ogonblick(foreR) or {}).orsak == "slutford")
	check("retry: markören föddes ändå, innan nollställningen",
		tillstand().vantar.halt == true or tillstand().bekraftad.halt == true)
	LM._forsokSparaForProv(p)
	request("finish")
end

--[[ Ett riktigt RidForsok-försök med en given övning och definition, stängt
	med `orsak`, och en lektionsbild formad som producentens. ]]
local function forsok(ovning, definition, orsak)
	local ok, _, fid = RidForsok.starta(id, RidForsok.nastaSekvens(id), ovning, definition, os.clock(), nil)
	if not ok then return nil end
	RidForsok.slutfor(id, fid, orsak or "slutford", os.clock(), nil)
	return fid
end
local HID = tostring(horse:GetAttribute("HorseId") or horse.Name)
local IDENT = {
	volt = { "storvolt", VoltObservation.VERSION, { avsnitt = {} } },
	halt = { HaltLektion.OVNING, HaltLektion.VERSION, { mal = "X" } },
	overgang = { OvergangLektion.OVNING, OvergangLektion.VERSION, { mal = "T1->T2" } },
	serpentin = { SerpentinLektion.OVNING, SerpentinLektion.VERSION, { rutt = "serpentin-3" } },
	tempo = { TempoLektion.OVNING, TempoLektion.VERSION, { ovning = TempoLektion.OVNING } },
	vag_mitt = { VagLektion.OVNING, VagLektion.VERSION, { figur = "vag_mitt" } },
	vag_diag = { VagLektion.OVNING, VagLektion.VERSION, { figur = "vag_diag" } },
	halvvolt = { HalvvoltLektion.OVNING, HalvvoltLektion.VERSION, { figur = "halvvolt" } },
	galopp = { GaloppLektion.OVNING, GaloppLektion.VERSION, { ovning = GaloppLektion.OVNING, galoppsida = "ej_bedomd" } },
	markbom = { MarkbomLektion.OVNING, MarkbomLektion.VERSION, { ovning = MarkbomLektion.OVNING, passage = "rotplan" } },
	hornet = { HornLektion.OVNING, HornLektion.VERSION, { figur = "hornet", mitt = true } },
}
local function lektion(typ, fid, andra, lage)
	local r = { forsokId = fid, rittId = id, userId = p.UserId, hastId = HID }
	for k, v in IDENT[typ][3] do r[k] = v end
	for k, v in (andra or {}) do r[k] = v end
	return { typ = if typ == "volt" then nil else typ, lage = lage or "complete", rittId = id,
		userId = p.UserId, hastId = HID, forsokId = fid, resultat = table.freeze(r) }
end

print("\n── 4. Ogiltiga övergångar ger ingen markör ──")
do
	local function ingen(namn, sess, l, typ)
		LM.slutford(sess, l)
		check(namn, tillstand().vantar[typ] == nil and tillstand().bekraftad[typ] == nil)
	end
	local fid = forsok(OvergangLektion.OVNING, OvergangLektion.VERSION)
	ingen("fel producentidentitet (mål)", s, lektion("overgang", fid, { mal = "X" }), "overgang")
	ingen("läget är inte complete", s, lektion("overgang", fid, nil, "timeout"), "overgang")
	local ofryst = lektion("overgang", fid); ofryst.resultat = { forsokId = fid, rittId = id, userId = p.UserId,
		hastId = HID, mal = "T1->T2" }
	ingen("ett ofryst resultat", s, ofryst, "overgang")
	ingen("resultatet tillhör ett annat försök", s, lektion("overgang", fid, { forsokId = "annat" }), "overgang")
	local l2 = lektion("overgang", fid); l2.rittId = "annan-ritt"
	ingen("en annan ritt", s, l2, "overgang")
	local tid = forsok(OvergangLektion.OVNING, OvergangLektion.VERSION, "tidsgrans")
	ingen("ett försök stängt av tidsgränsen", s, lektion("overgang", tid), "overgang")
	local gammal = forsok(OvergangLektion.OVNING, "server-overgang-0")
	ingen("en gammal definition", s, lektion("overgang", gammal), "overgang")
	local fel = forsok(TempoLektion.OVNING, TempoLektion.VERSION)
	ingen("RidForsok-försöket är en annan övning", s, lektion("overgang", fel), "overgang")
	local annan = nyPlayer(932)
	ingen("en annan spelare i sessionen", { rider = annan, rittId = id, rig = s.rig }, lektion("overgang", fid),
		"overgang")
	annan.harKlient = false
	ingen("en aktör utan klient", { rider = annan, rittId = id, rig = s.rig }, lektion("overgang", fid), "overgang")
	ingen("ingen resultattabell", s, (function() local l = lektion("overgang", fid); l.resultat = nil; return l end)(),
		"overgang")
end

print("\n── 5. Alla tio mappningar ──")
for _, typ in LM.TYPER do
	if typ ~= "halt" then
		local fid = forsok(IDENT[typ][1], IDENT[typ][2])
		LM.slutford(s, lektion(typ, fid))
		check(typ .. ": giltigt producentformat ger en markör (väntande eller redan sparad)",
			(tillstand().vantar[typ] == true or tillstand().bekraftad[typ] == true)
			and SparService.save(p).framsteg[LM.nyckel(typ)] ~= nil)
	end
end
LM._forsokSparaForProv(p)
check("en skrivning bekräftar alla väntande", (function()
	for _, typ in LM.TYPER do if proj().lektioner[typ] ~= "sparad" then return false end end
	return true
end)())

print("\n── 6. Skrivningen: upptagen, i luften, omkörd transform, fel och återhämtning ──")
do
	-- Nollställ minnet för en ny sessionsprovning: ny spelare 933.
	local q = nyPlayer(933)
	Players._spelare = { p, q }
	Players.PlayerAdded:Fire(q)
	if Players.PlayerAdded.slutfor then Players.PlayerAdded:slutfor() end
	local t = LM._tillstandForProv(q)
	check("KONTROLL: andra spelaren laddad och betrodd", t ~= nil and t.betrodd)
	local sq = { rider = q, rittId = id, rig = s.rig }
	--[[ Försöken tillhör ritten `id` med spelaren p; för q prövas bara
		lagringen, genom att lektionsbilden bär q och försöken skapas med q:s
		id i bilden (RidForsok binder ritten till p, så en q-bild nekas). ]]
	local fid = forsok(HaltLektion.OVNING, HaltLektion.VERSION)
	local l = lektion("halt", fid); l.userId = q.UserId
	LM.slutford(sq, l)
	check("RidForsok-bilden tillhör p: en q-lektion på p:s försök nekas", t.vantar.halt == nil)
	-- Lagringsfallen provas därför på p, med en ny lektionstyp genom Sparning-nyckeln.
	Players._spelare = { p }
	Players.PlayerRemoving:Fire(q)
end
do
	local tp = tillstand()
	-- Återställ halt och tempo till "ej klarad" i det här minnet för att kunna prova skrivvägen.
	tp.bekraftad.tempo = nil
	SparService.save(p).framsteg[LM.nyckel("tempo")] = nil
	__datastore._data["spelare_931"].framsteg[LM.nyckel("tempo")] = nil
	tp.bekraftad.serpentin = nil
	SparService.save(p).framsteg[LM.nyckel("serpentin")] = nil
	__datastore._data["spelare_931"].framsteg[LM.nyckel("serpentin")] = nil
	-- Skrivfel: väntar kvar.
	__datastore.felSkriv = true
	LM.slutford(s, lektion("tempo", forsok(TempoLektion.OVNING, TempoLektion.VERSION)))
	LM._forsokSparaForProv(p)
	check("en fallerad skrivning: fortfarande väntande, aldrig 'sparad'", proj().lektioner.tempo == "vantar")
	__datastore.felSkriv = false
	-- Klar MEDAN skrivningen är i luften (före transformatorn).
	__datastore.foreSkriv = function()
		__datastore.foreSkriv = nil
		LM.slutford(s, lektion("serpentin", forsok(SerpentinLektion.OVNING, SerpentinLektion.VERSION)))
	end
	LM._forsokSparaForProv(p)
	check("återhämtning: tempo sparad", proj().lektioner.tempo == "sparad" and radMarkor("tempo") ~= nil)
	check("klar medan skrivningen var i luften: följde med och bekräftades",
		proj().lektioner.serpentin == "sparad" and radMarkor("serpentin") ~= nil)
	-- Klar EFTER att transformatorn kört (cachen ersatt): väntar, sparas nästa gång.
	tp.bekraftad.volt = nil
	SparService.save(p).framsteg[LM.nyckel("volt")] = nil
	__datastore._data["spelare_931"].framsteg[LM.nyckel("volt")] = nil
	tp.bekraftad.markbom = nil
	SparService.save(p).framsteg[LM.nyckel("markbom")] = nil
	__datastore._data["spelare_931"].framsteg[LM.nyckel("markbom")] = nil
	__datastore.felSkriv = true
	LM.slutford(s, lektion("volt", forsok("storvolt", VoltObservation.VERSION)))
	__datastore.felSkriv = false
	local markbomIForsta = nil
	__datastore.efterSkriv = function()
		__datastore.efterSkriv = nil
		LM.slutford(s, lektion("markbom", forsok(MarkbomLektion.OVNING, MarkbomLektion.VERSION)))
		-- Raden har landat; markbommen var alltså inte med i den.
		markbomIForsta = radMarkor("markbom") ~= nil
	end
	local skrivFore = __datastore.forsok.skriv
	LM._forsokSparaForProv(p)
	check("den som var med i skrivningen är sparad", proj().lektioner.volt == "sparad")
	check("den som kom efter transformatorn var INTE med i den skrivningen, men låg i den ersatta cachen",
		markbomIForsta == false and SparService.save(p).framsteg[LM.nyckel("markbom")] ~= nil)
	check("och sparades av uppföljningsförsöket direkt efter (två skrivningar)",
		proj().lektioner.markbom == "sparad" and radMarkor("markbom") ~= nil
		and __datastore.forsok.skriv - skrivFore == 2, __datastore.forsok.skriv - skrivFore)
	-- Omkörd transform: idempotent, inga dubbletter.
	tp.bekraftad.galopp = nil
	SparService.save(p).framsteg[LM.nyckel("galopp")] = nil
	__datastore._data["spelare_931"].framsteg[LM.nyckel("galopp")] = nil
	__datastore.omkorTransform = true
	LM.slutford(s, lektion("galopp", forsok(GaloppLektion.OVNING, GaloppLektion.VERSION)))
	LM._forsokSparaForProv(p)
	__datastore.omkorTransform = false
	local g = radMarkor("galopp")
	check("en omkörd transform ger en markör 1/1", g ~= nil and g.forsok == 1 and g.klarade == 1
		and proj().lektioner.galopp == "sparad")
end

print("\n── 7. Taket: fullt framsteg ger 'väntar', inget annat rörs ──")
do
	local tp = tillstand()
	tp.bekraftad.halvvolt = nil
	local save = SparService.save(p)
	save.framsteg[LM.nyckel("halvvolt")] = nil
	__datastore._data["spelare_931"].framsteg[LM.nyckel("halvvolt")] = nil
	local fore = 0
	for _ in pairs(save.framsteg) do fore += 1 end
	for i = 1, Sparning.MAX_FRAMSTEG - fore do save.framsteg["annat" .. i] = { forsok = 1, klarade = 0, senast = 0 } end
	LM.slutford(s, lektion("halvvolt", forsok(HalvvoltLektion.OVNING, HalvvoltLektion.VERSION)))
	check("fullt: uppföljningen stannar efter högst tre försök (ingen slinga)", tillstand().retry <= 3)
	LM._forsokSparaForProv(p)
	check("fullt: markören får inte plats och står som väntande", proj().lektioner.halvvolt == "vantar"
		and save.framsteg[LM.nyckel("halvvolt")] == nil)
	check("inga andra framsteg togs bort", save.framsteg["annat1"] ~= nil)
	--[[ Städa: fyllnaden bort ur minnet OCH ur lagret (skrivningarna ovan
		lade dit den), och den väntande halvvolten släpps — annars skulle
		avsnitt 9:s sista skrivning nekas som full av fel skäl. ]]
	for i = 1, Sparning.MAX_FRAMSTEG do
		save.framsteg["annat" .. i] = nil
		if rad() then rad().framsteg["annat" .. i] = nil end
	end
	tillstand().vantar.halvvolt = nil
end

print("\n── 8. Otillförlitlig historik: okänd, aldrig 'inga lektioner' ──")
do
	local function laddaMed(uid, forbered)
		local q = nyPlayer(uid)
		forbered(q)
		Players._spelare = { p, q }
		Players.PlayerAdded:Fire(q)
		if Players.PlayerAdded.slutfor then Players.PlayerAdded:slutfor() end
		local pr = LM._projektion(LM._tillstandForProv(q))
		Players.PlayerRemoving:Fire(q)
		Players._spelare = { p }
		__datastore.felLas = false
		return pr
	end
	local ok = true
	for namn, forbered in {
		framtida = function(q) __datastore._data["spelare_" .. q.UserId] = { v = 99 } end,
		trasig = function(q) __datastore._data["spelare_" .. q.UserId] = "skräp" end,
		lasfel = function(_) __datastore.felLas = true end,
	} do
		local pr = laddaMed(940 + #namn, forbered)
		local alla = pr.historik == "okand"
		for _, typ in LM.TYPER do if pr.lektioner[typ] ~= "okand" then alla = false end end
		check(namn .. ": historiken och alla tio är okända", alla)
		if not alla then ok = false end
	end
end

print("\n── 9. R1: avfärd MEDAN en skrivning är i luften — dränering, omkörning, fel ──")
--[[ På schemat (`__schemaPa`): `task.spawn` köar en korutin, `task.wait` i
	huvudtråden stegar kön och lämnar över i en schemalagd tråd.
	`efterSkriv` väntar (`task.wait`) EFTER att raden landat, så skrivning A
	står utestående med cachen redan ersatt. Klar B kommer då; sedan fyras
	PlayerRemoving medan A väntar.
	BÄNKANTAGANDE: SparService:s avfärdshanterare körs i huvudtråden, och dess
	`stangningFor` stegar schemat med `task.wait` tills A blivit klar. ]]
local function aterkom()
	SparService._glomForProv(p)
	Players._spelare = { p }
	Players.PlayerAdded:Fire(p)
	if Players.PlayerAdded.slutfor then Players.PlayerAdded:slutfor() end
	step(0, 18)
	root.CFrame = CFrame.new(a0); root.Position = a0
	local ok2, _, id2 = HorseService.tryMount(p, horse)
	if ok2 then id = id2 end
	step(0, 18); step(0, 18)
	return ok2 == true
end
local gammalToken = nil
local function avfardsfall(namn, typA, typB, variant)
	nollstall(typA); nollstall(typB)
	__datastore.felSkriv = true
	LM.slutford(s, lektion(typA, forsok(IDENT[typA][1], IDENT[typA][2])))
	__datastore.felSkriv = false
	check(namn .. " KONTROLL: A väntar", tillstand().vantar[typA] == true)
	gammalToken = tillstand().token
	__schemaPa(true)
	__datastore.efterSkriv = function()
		__datastore.efterSkriv = nil
		task.wait() -- A står utestående efter att raden landat
	end
	task.spawn(LM._forsokSparaForProv, p)
	__schemaSteg()
	check(namn .. " KONTROLL: A utestående, raden landad", tillstand().skriverNu == true and radMarkor(typA) ~= nil)
	LM.slutford(s, lektion(typB, forsok(IDENT[typB][1], IDENT[typB][2])))
	check(namn .. " KONTROLL: B väntar, finns i den ersatta cachen men inte i lagret",
		tillstand().vantar[typB] == true and SparService.save(p).framsteg[LM.nyckel(typB)] ~= nil
		and radMarkor(typB) == nil)
	if variant == "omkor" then __datastore.omkorTransform = true end
	if variant == "fel" then __datastore.felSkriv = true end
	local skickatFore = #(Networking.get("LektionsMinneSync")._skickat or {})
	Players.PlayerRemoving:Fire(p)
	__datastore.omkorTransform = false
	__datastore.felSkriv = false
	__schemaTomKo()
	__schemaPa(false)
	check(namn .. ": ingen UI efter avfärden",
		#(Networking.get("LektionsMinneSync")._skickat or {}) == skickatFore)
	check(namn .. ": tillståndet släpptes först efter den sista skrivningen", LM._tillstandForProv(p) == nil)
	local fB = radMarkor(typB)
	if variant == "fel" then
		check(namn .. ": den sista skrivningen föll — B finns INTE i lagret", fB == nil)
	else
		check(namn .. ": B följde med den sista skrivningen, en boolesk markör", fB ~= nil and fB.forsok == 1
			and fB.klarade == 1)
	end
	check(namn .. ": A finns i lagret", radMarkor(typA) ~= nil)
	check(namn .. " KONTROLL: återkomst och ny ritt", aterkom())
	local pr = proj()
	check(namn .. ": betrodd omläsning — A sparad", pr.historik == "betrodd" and pr.lektioner[typA] == "sparad")
	check(namn .. ": betrodd omläsning — B " .. (if variant == "fel" then "ej klarad" else "sparad"),
		pr.lektioner[typB] == (if variant == "fel" then "ej_klarad" else "sparad"))
end
do
	-- Ritten efter avsnitt 8 är öppen (p lämnade aldrig där).
	avfardsfall("dränering", "tempo", "overgang", nil)
	avfardsfall("omkörd transform", "serpentin", "vag_mitt", "omkor")
	avfardsfall("fel i sista skrivningen", "vag_diag", "markbom", "fel")
	local skriv0 = __datastore.forsok.skriv
	LM._forsokSparaMedTokenForProv(p, gammalToken)
	check("en gammal sessions token gör ingenting i den nya sessionen", __datastore.forsok.skriv == skriv0)
end

print("\n── 10. R1: klientens ordning — gamla svar ersätter aldrig nyare fakta ──")
local VC = VoltLektionController
local syncEv = Networking.get("LektionsMinneSync")
local function hitta(lista, del)
	for _, k in ipairs(lista) do if string.find(k.text, del, 1, true) then return k end end
	return nil
end
do
	Sprak.satVal("sv")
	VC.avbryt(); VC.start(id, nil)
	local m0 = VC._minneForProv()
	check("KONTROLL: klienten har serverns projektion", m0 ~= nil and m0.session >= 1)
	local S, R = m0.session, m0.rev
	local function med(lage, session, rev)
		local l = {}
		for _, typ in LM.TYPER do l[typ] = lage end
		return { historik = "betrodd", lektioner = l, session = session, rev = rev }
	end
	-- En läsning före en push: pushen (nyare) kommer först, läsningens svar (äldre) sist.
	syncEv.OnClientEvent:Fire(med("sparad", S, R + 5))
	syncEv.OnClientEvent:Fire(med("ej_klarad", S, R + 3))
	check("ett äldre svar efter en nyare push ignoreras", VC._minneForProv().lektioner.halt == "sparad"
		and VC._minneForProv().rev == R + 5)
	syncEv.OnClientEvent:Fire(med("vantar", S, R + 5))
	check("samma revision tas emot (samma fakta, idempotent)", VC._minneForProv().lektioner.halt == "vantar")
	syncEv.OnClientEvent:Fire(med("ej_klarad", S - 1, R + 99))
	check("en ÄLDRE serversession ignoreras hur hög revisionen än är",
		VC._minneForProv().lektioner.halt == "vantar")
	syncEv.OnClientEvent:Fire({ historik = "betrodd", lektioner = {}, session = "x", rev = 1 })
	check("en projektion utan giltig ordning tas inte emot", VC._minneForProv().lektioner.halt == "vantar")
	-- Återkoppling: klientens nya läsning svarar med serverns ÄLDRE revision (R)
	-- än den den håller (R + 5) — svaret från före ersätter inte det nyare.
	VC.avbryt(); VC.start(id, nil)
	check("efter återkoppling: ett äldre läsningssvar ersätter inte nyare fakta",
		VC._minneForProv().lektioner.halt == "vantar" and VC._minneForProv().rev == R + 5)
	-- En NY serversession (ny laddning på servern) tas emot och ersätter.
	LM._efterLaddningForProv(p)
	local server = LM._projektion(tillstand())
	check("en nyare serversession från servern tas emot och gäller",
		server.session > S and VC._minneForProv().session == server.session
		and VC._minneForProv().lektioner.halt == server.lektioner.halt)
	VC.avbryt()
end

print("\n── 11. R1: den FAKTISKA väljaren i Ugneta/Naromrade — 0 och 1..3 kort, kompakt, Tillbaka, fri, SV/EN ──")
do
	local UC = UgnetaController
	local function sida(n)
		UC.dolj()
		if n and n > 0 then UC.visa("Kort", {}, n >= 1, nil, n >= 2, n >= 3) end
		return UC.panel(4)
	end
	local function push(lektioner, historik)
		local nu = VC._minneForProv()
		syncEv.OnClientEvent:Fire({ historik = historik or "betrodd", lektioner = lektioner,
			session = nu.session, rev = nu.rev + 1 })
	end
	Sprak.satVal("sv")
	VC.avbryt(); VC.start(id, nil)
	UC.satLektionsVal(VC.panel)
	-- Känt läge: allt klart utom halvvolt och galopp → förslaget är halvvolt.
	local l = {}
	for _, typ in LM.TYPER do l[typ] = "sparad" end
	l.halvvolt, l.galopp = "ej_klarad", "ej_klarad"
	push(l)
	local noll = sida(0)
	check("0 kort: toppnivån har förslagsknappen och högst fyra rader",
		#noll.knappar <= 4 and hitta(noll.knappar, "Förslag: " .. Sprak.t("halvvoltlektion.choose")) ~= nil)
	for n = 1, 3 do
		local sd = sida(n)
		local kompakt = sd.knappar[#sd.knappar] -- den kompakta posten kommer efter korten
		check(("%d kort: högst fyra rader, korten först, en kompakt post"):format(n), #sd.knappar <= 4
			and #sd.knappar == n + 1, #sd.knappar)
		if n == 1 then
			kompakt.skicka()
			local topp = UC.panel(4)
			check("kompakt → toppsidan: ersättningssida vars TEXT säger förslaget och var det finns",
				topp.ersatt == true and string.find(topp.text or "", Sprak.t("lektionsminne.forslag_var",
					Sprak.t("halvvoltlektion.choose"), Sprak.t("lektionsval.vagar")), 1, true) ~= nil, topp.text)
			check("toppsidan: gruppen mot förslaget är markerad, samma fyra knappar",
				#topp.knappar == 4 and hitta(topp.knappar, Sprak.t("lektionsval.vagar")
					.. Sprak.t("lektionsminne.markering.forslag")) ~= nil)
			hitta(topp.knappar, Sprak.t("lektionsval.vagar")).skicka()
			-- Genom hörnet: halvvolten ligger nu under Böjda vägar.
			local bojda = hitta(UC.panel(4).knappar, Sprak.t("lektionsval.bojda"))
			check("KONTROLL: Böjda vägar finns och är markerad mot förslaget", bojda ~= nil
				and string.find(bojda.text, Sprak.t("lektionsminne.markering.forslag"), 1, true) ~= nil)
			if bojda then bojda.skicka() end
			local vag = UC.panel(4)
			check("gruppsidan: lektionen är markerad som förslag", hitta(vag.knappar,
				Sprak.t("halvvoltlektion.choose") .. Sprak.t("lektionsminne.markering.forslag")) ~= nil)
			Sprak.satVal("en")
			vag = UC.panel(4) -- byggs OM efter språkbytet
			check("på engelska: markeringen på engelska", hitta(vag.knappar, " · suggested") ~= nil)
			Sprak.satVal("sv")
			vag = UC.panel(4) -- och om igen, på svenska, innan Tillbaka söks
			local tb = hitta(vag.knappar, Sprak.t("lektionsval.tillbaka"))
			check("KONTROLL: Tillbaka finns på den ombyggda sidan", tb ~= nil)
			if tb then tb.skicka() end
			--[[ Genom hörnet: Böjda vägar är en nivå under Ridvägar; dess Tillbaka
				landar på Ridvägar, och Ridvägars Tillbaka på toppnivån. ]]
			local vagarSida = UC.panel(4)
			check("Tillbaka från Böjda vägar landar på Ridvägar",
				hitta(vagarSida.knappar, Sprak.t("lektionsval.bojda")) ~= nil)
			local tb2 = hitta(vagarSida.knappar, Sprak.t("lektionsval.tillbaka"))
			if tb2 then tb2.skicka() end
			local ut = VC.panel()
			check("Tillbaka landar på toppnivån (inte en ersättningssida, gruppknapparna där)",
				ut.ersatt ~= true and hitta(ut.knappar, Sprak.t("lektionsval.gangart")) ~= nil)
		end
	end
	-- Alla klarade: öva igen.
	for _, typ in LM.TYPER do l[typ] = "sparad" end
	push(l)
	local alla = sida(0)
	check("alla klarade: 'Öva igen' på den första, inget diplom",
		hitta(alla.knappar, "Öva igen: " .. Sprak.t("haltlektion.choose")) ~= nil)
	-- Okänd historik: inget förslag; toppsidan säger det neutralt.
	push({}, "okand")
	local ok0 = sida(0)
	check("okänd historik: inget förslag på toppnivån", hitta(ok0.knappar, "Förslag") == nil
		and hitta(ok0.knappar, "Öva igen") == nil)
	local ok1 = sida(1)
	ok1.knappar[#ok1.knappar].skicka()
	check("okänd historik: toppsidan säger den neutrala raden", string.find(UC.panel(4).text or "",
		Sprak.t("lektionsminne.okand"), 1, true) ~= nil)
	-- Fri ridning: välj en lektion och avsluta den på riktigt → fri.
	for _, typ in LM.TYPER do l[typ] = "sparad" end
	l.galopp = "ej_klarad"
	push(l)
	VC.avbryt(); VC.start(id, nil)
	UC.dolj()
	VC.valj("halt")
	local fin = hitta(VC.panel().knappar, Sprak.t("haltlektion.finish"))
	if fin then fin.skicka() end
	local friSida = UC.panel(4)
	check("KONTROLL: fri ridning (ersättningssida med 'Andra övningar')", friSida.ersatt == true
		and hitta(friSida.knappar, Sprak.t("voltlektion.lessons")) ~= nil)
	check("fri ridning: fyra rader, och förslaget med plats står i texten",
		#friSida.knappar <= 4 and string.find(friSida.text or "", Sprak.t("lektionsminne.forslag_var",
			Sprak.t("galopplektion.choose"), Sprak.t("lektionsval.gangart")), 1, true) ~= nil, friSida.text)
	-- Förslagsknappen är bunden till sitt förslag.
	VC.avbryt(); VC.start(id .. "-bunden", nil)
	UC.dolj()
	l.galopp = "ej_klarad"
	push(l)
	local fk = hitta(VC.panel().knappar, "Förslag")
	l.galopp = "sparad"; l.markbom = "ej_klarad"
	push(l)
	if fk then fk.skicka() end
	check("en förslagsknapp från före en minnesändring väljer ingenting", VC.lektion() == false)
	-- Främmande typer och lägen tvättas bort.
	push({ halt = "sparad", hopp = "sparad", tempo = "mastare" })
	local mm = VC._minneForProv()
	check("projektionen tvättas: bara de tio, bara kända lägen", mm.lektioner.hopp == nil
		and mm.lektioner.tempo == "okand" and mm.lektioner.halt == "sparad")
	UC.satLektionsVal(nil)
	VC.avbryt()
end

Skopa._satKlockaForProv(nil)
if fails > 0 then error(tostring(fails) .. " FEL") end
print(string.format("\nLEKTIONSMINNE: %d prov, alla gröna", total))
