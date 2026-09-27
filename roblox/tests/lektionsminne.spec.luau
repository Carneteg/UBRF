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
	for i = 1, Sparning.MAX_FRAMSTEG do save.framsteg["annat" .. i] = nil end
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

print("\n── 9. Avfärd och återkomst ──")
do
	local tp = tillstand()
	Players.PlayerRemoving:Fire(p)
	check("avfärd: modulens tillstånd är borta", LM._tillstandForProv(p) == nil)
	LM._forsokSparaForProv(p) -- ett sent schemalagt försök
	check("ett sent försök efter avfärden rör ingenting", LM._tillstandForProv(p) == nil)
	SparService._glomForProv(p)
	Players._spelare = { p }
	Players.PlayerAdded:Fire(p)
	if Players.PlayerAdded.slutfor then Players.PlayerAdded:slutfor() end
	local t2 = LM._tillstandForProv(p)
	check("återkomst: ny session, ny token", t2 ~= nil and t2.token ~= tp.token)
	check("den betrodda omläsningen visar sparade lektioner som sparade",
		t2.betrodd and t2.bekraftad.halt == true and LM._projektion(t2).lektioner.halt == "sparad")
end

print("\n── 10. Klientens väljare: markering, ETT förslag, okänt, SV/EN, Tillbaka ──")
do
	local VC = VoltLektionController
	local function hitta(lista, del)
		for _, k in ipairs(lista) do if string.find(k.text, del, 1, true) then return k end end
		return nil
	end
	Sprak.satVal("sv")
	VC.avbryt(); VC.start(id, nil)
	local m = VC._minneForProv()
	check("KONTROLL: klienten fick sin projektion", m ~= nil and m.historik == "betrodd")
	local topp = VC.panel().knappar
	check("toppnivån: högst fyra val", #topp <= 4, #topp)
	local tempoSparad = m.lektioner.tempo == "sparad" and m.lektioner.halt == "sparad"
	local function forslagen(lista)
		local n, k = 0, nil
		for _, x in ipairs(lista) do
			if string.find(x.text, "Förslag", 1, true) or string.find(x.text, "Öva igen", 1, true) then n += 1; k = x end
		end
		return n, k
	end
	local antalF, fk = forslagen(topp)
	--[[ Efter avsnitt 7 fick halvvolten aldrig plats; efter omläsningen är
		den alltså den första oklarade i ordningen. ]]
	check("ETT förslag på toppnivån, och det är första oklarade i ordningen (halvvolt)",
		antalF == 1 and fk ~= nil and string.find(fk.text, Sprak.t("halvvoltlektion.choose"), 1, true) ~= nil,
		fk and fk.text)
	-- Gruppsidan: markering.
	local grupp = hitta(topp, Sprak.t("lektionsval.gangart"))
	if grupp then grupp.skicka() end
	local sida = VC.panel()
	check("gruppsidan: halt är markerad som klarad", hitta(sida.knappar, Sprak.t("lektionsminne.markering.sparad")) ~= nil
		and tempoSparad)
	Sprak.satVal("en")
	sida = VC.panel()
	check("på engelska: samma markering, engelska ord", hitta(sida.knappar, " · done") ~= nil)
	Sprak.satVal("sv")
	local tillbaka = hitta(sida.knappar, Sprak.t("lektionsval.tillbaka"))
	if tillbaka then tillbaka.skicka() end
	check("Tillbaka leder till toppnivån som förut", VC.panel().ersatt ~= true or #VC.panel().knappar <= 4)
	-- Förslaget väljer lektionen men startar ingenting.
	_, fk = forslagen(VC.panel().knappar)
	if fk then fk.skicka() end
	--[[ Efter avsnitt 9 kan ritten vara riven av avfärden; frågan är bara
		att valet inte öppnade något försök. ]]
	check("förslaget startar inget försök (Start krävs)", fk ~= nil and RidForsok.aktivt(id) == nil)
	-- Okänd historik: inget förslag, neutral rad.
	-- En NY ritt (annat märke): valet nollställs och toppnivån visas.
	VC.avbryt(); VC.start(id .. "-okand", nil)
	-- Efter startens egen läsning: en push med okänd historik.
	Networking.get("LektionsMinneSync").OnClientEvent:Fire({ historik = "okand", lektioner = {} })
	check("KONTROLL: klienten håller nu okänd historik", VC._minneForProv().historik == "okand")
	topp = VC.panel().knappar
	check("okänd historik: inget förslag", (forslagen(topp)) == 0)
	-- Främmande typer och värden tvättas bort.
	Networking.get("LektionsMinneSync").OnClientEvent:Fire({ historik = "betrodd",
		lektioner = { halt = "sparad", hopp = "sparad", tempo = "mastare" } })
	local mm = VC._minneForProv()
	check("projektionen tvättas: bara de tio, bara kända lägen", mm.lektioner.hopp == nil
		and mm.lektioner.tempo == "okand" and mm.lektioner.halt == "sparad")
	VC.avbryt()
end

if fails > 0 then error(tostring(fails) .. " FEL") end
print(string.format("\nLEKTIONSMINNE: %d prov, alla gröna", total))
