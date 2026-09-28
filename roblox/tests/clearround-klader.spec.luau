--!nostrict
--[[ D5 TÄVLINGSKLÄDER VID CLEAR ROUND-ANMÄLAN — docs/D5-COMPETITION-CLOTHING-CONTRACT.md (Tobias A).

	KOHERENS-bänken: riktig HorseService, ClearRoundLektion och
	TavlingskladerService (oförändrad), byggt ridhus med de befintliga hindren.
	KATALOGEN ÄR INJICERAD: Roblox katalog-API går inte att fråga härifrån, så
	en attrapp svarar (rätt, nej, eller pausar mitt i uppslaget). Avatarsidan är
	tjänstens standardadapter mot bänkens Instance — den skriver Shirt/Pants på
	karaktären. Att det syns på en RIKTIG avatar är NOT_TESTED (Studio). ]]
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
local T = Tavlingsklader

-- ── Katalogattrappen (som i tavlingsklader-session.spec) ──
local function allaRatta()
	local svar = {}
	for _, set in ipairs(T.alla()) do
		svar[set.shirtAssetId] = { ok = true, assetTypeId = T.ASSETTYPE_SHIRT }
		svar[set.pantsAssetId] = { ok = true, assetTypeId = T.ASSETTYPE_PANTS }
	end
	return svar
end
local function nyKatalog(svar, pausa)
	local a = { anrop = 0 }
	a.assetTyp = function(assetId)
		a.anrop += 1
		if pausa then coroutine.yield() end
		local s = svar[assetId]
		if s == nil then return { ok = false, fel = "okand post" } end
		return s
	end
	return a
end
local katalog, aktivTjanst
local function tjanst(svar, pausa)
	katalog = nyKatalog(svar, pausa)
	aktivTjanst = TavlingskladerService.nya({ katalog = katalog })
	ClearRoundLektion._satKladerForProv(aktivTjanst)
end

-- ── Spelare med EGNA kläder ──
local EGEN_T, EGEN_B = "rbxassetid://1000001", "rbxassetid://1000002"
local function player(id)
	local c = Instance.new("Model")
	local root = Instance.new("Part"); root.Name = "HumanoidRootPart"; root.Size = vec(2, 2, 1); root.Parent = c
	local h = Instance.new("Humanoid"); h.Name = "Humanoid"; h.Parent = c
	local sh = Instance.new("Shirt"); sh.Name = "Shirt"; sh.ShirtTemplate = EGEN_T; sh.Parent = c
	local pa = Instance.new("Pants"); pa.Name = "Pants"; pa.PantsTemplate = EGEN_B; pa.Parent = c
	return { UserId = id, Name = "Klader" .. id, Character = c,
		CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }
end
local function buren(p)
	local s = p.Character:FindFirstChildOfClass("Shirt")
	local b = p.Character:FindFirstChildOfClass("Pants")
	return (s and s.ShirtTemplate or nil), (b and b.PantsTemplate or nil)
end
local function egna(p) local s, b = buren(p); return s == EGEN_T and b == EGEN_B end
local function iSet(p, id)
	local set = T.set(id); local s, b = buren(p)
	return s == TavlingskladerService.mall(set.shirtAssetId) and b == TavlingskladerService.mall(set.pantsAssetId)
end

-- ── En häst i ridhuset, ryttaren flyttas mellan hjärtslagen ──
local horse = HastRigg.bygg("klader_test", "Kläder test", CFrame.new(Ridhusplats.tillVarld(RP, vec(0, 0, 4))))
horse.Parent = workspace; Tags:AddTag(horse, "Horse")
local sess = HorseService.sessionFor(horse)
local p, id, seq, nu, P1
local function point(u, v)
	local a = Ridhusplats.tillVarld(RP, vec(u, 0, v))
	return vec(a.X, sess.rig.root.Position.Y, a.Z)
end
local function step(u, v)
	local a = point(u, v); sess.rig.root.CFrame = CFrame.new(a); sess.rig.root.Position = a
	sess.energi = 1; Run.Heartbeat:Fire(0.25)
	nu = { u = u, v = v }
end
local function till(u, v)
	local n = math.max(1, math.ceil(math.sqrt((u - nu.u) ^ 2 + (v - nu.v) ^ 2) / 0.8))
	local u0, v0 = nu.u, nu.v
	for i = 1, n do step(u0 + (u - u0) * i / n, v0 + (v - v0) * i / n) end
end
local function mount(pl)
	p = pl; Players._spelare = { p }
	nu = { u = 0, v = 4 }; step(0, 4)
	local a = point(0, 4) + vec(6, 0, 0)
	local root = p.Character:FindFirstChild("HumanoidRootPart")
	root.CFrame = CFrame.new(a); root.Position = a
	local ok, reason, marke = HorseService.tryMount(p, horse)
	assert(ok, tostring(reason)); step(0, 4); step(0, 4)
	id, seq = marke, 0
end
local function request(op, typ)
	seq += 1
	return HorseService.voltLektionsBegaran(p, id, op, seq, typ or "clearround")
end
local function image()
	local ok, _, b = HorseService.voltLektionsBegaran(p, id, "sync", nil, "clearround"); assert(ok); return b
end
local B, R
do
	local reg = HinderObservation.register()
	local function iRam(hid)
		local h = reg.hinder[hid]
		local c = Ridhusplats.tillLokal(RP, vec(h.x, h.y, h.z))
		return { u = c.X, v = c.Z }
	end
	B, R = iRam("ridhus_hinder_bla_24"), iRam("ridhus_hinder_rod_38")
end
local function tillStart() till(B.u, nu.v); till(B.u, B.v - 13) end
local function overStartlinjen() till(B.u, B.v - G.LINJE_M + 1) end
local function helaBanan()
	overStartlinjen(); till(B.u, B.v + 4)
	till(R.u, B.v + 4); till(R.u, R.v - 5); till(R.u, R.v + 4)
	till(B.u, R.v + 4); till(B.u, B.v + 5); till(B.u, B.v - 4)
	till(R.u, B.v - 4); till(R.u, R.v - 5); till(R.u, R.v + 4)
	till(R.u, R.v + G.LINJE_M + 1)
end
local function felvag() overStartlinjen(); till(R.u, B.v - 6); till(R.u, R.v - 5); till(R.u, R.v + 4) end

print("\n── 1. Egna kläder och valen i bilden ──")
;(function()
	tjanst(allaRatta())
	P1 = Players.LocalPlayer
	P1.Character = player(801).Character
	-- En riktig Player har alltid signalerna; bänkens LocalPlayer får dem här
	-- (tjänsten binder sina vakter på dem).
	P1.CharacterAdded = P1.CharacterAdded or __signal_ny()
	P1.CharacterRemoving = P1.CharacterRemoving or __signal_ny()
	mount(P1)
	tillStart()
	local b0 = image()
	local ids = {}
	for _, v in ipairs(b0.kladerVal or {}) do
		table.insert(ids, v.id)
		if v.shirtAssetId ~= nil or v.pantsAssetId ~= nil then ids = { "ASSET-LÄCKA" } break end
	end
	check("valen i «ready»: katalogens id i ordning, med namn, aldrig asset-nummer",
		table.concat(ids, ",") == "white,pink,oak" and b0.kladerVal[1].namn == "White Equestrian Set", table.concat(ids, ","))
	local okA, _, ba = request("anmal")
	check("anmal med egna kläder: startlistan, inga kläder rörda, ingen katalogfråga",
		okA and ba.lage == "startlista" and ba.klader == nil and egna(p) and katalog.anrop == 0)
	check("valen visas inte efter anmälan", ba.kladerVal == nil)
	request("finish")
	check("avsluta: fortfarande egna", egna(p) and image().klader == nil)
end)()

print("\n── 2. anmal_white: på vid anmälan, kvar genom resultat och omstart, av vid Avsluta ──")
;(function()
	__schemaPa(true)
	local okA, _, ba = request("anmal_white")
	check("anmälan sker DIREKT: startlistan med «laddar», egna kläder än så länge",
		okA and ba.lage == "startlista" and ba.klader and ba.klader.lage == "laddar" and ba.klader.set == "white"
		and egna(p), ba.klader and ba.klader.lage)
	local rev = image().revision
	__schemaTomKo(); __schemaPa(false)
	local b = image()
	check("uppslaget klart: «pa», katalogens mallar på karaktären, revisionen räknad upp",
		b.klader and b.klader.lage == "pa" and b.klader.namn == "White Equestrian Set" and iSet(p, "white")
		and b.revision > rev, b.klader and b.klader.lage)
	request("ga_banan"); request("start")
	check("genom banskiss och startsignal: kvar", iSet(p, "white") and image().klader.lage == "pa")
	felvag(); tillStart()
	local bf = image()
	check("resultat (complete): kvar", bf.lage == "complete" and iSet(p, "white"), bf.lage)
	local okR, _, br = request("retry")
	check("omstart: kvar, samma anmälan", okR and br.lage == "to_start" and iSet(p, "white") and br.klader.lage == "pa")
	request("finish")
	check("Avsluta: EGNA kläder tillbaka, klädläget borta", egna(p) and image().klader == nil)
end)()

print("\n── 3. Avsluta i startlistan och banskissen; lektionsbyte; rittslut ──")
;(function()
	request("anmal_pink")
	check("pink på", iSet(p, "pink"))
	request("finish")
	check("Avsluta i startlistan: egna", egna(p))
	request("anmal_oak"); request("ga_banan")
	check("oak på i banskissen", iSet(p, "oak"))
	request("finish")
	check("Avsluta i banskissen: egna", egna(p))
	request("anmal_white")
	check("white på i startlistan", iSet(p, "white"))
	local okB = request("sync", "halt") -- läsning skapar/visar, ändrar inget
	request("start", "halt") -- ett riktigt lektionsbyte
	check("lektionsbyte bort från clear round: egna", egna(p))
	-- Tillbaka till clear round, på igen, och sitt av mitt i banan.
	request("finish", "halt")
	request("anmal_white", "clearround"); request("ga_banan"); request("start")
	overStartlinjen(); till(B.u, B.v + 4)
	check("mitt i banan med white", iSet(p, "white") and RidForsok.aktivt(id) ~= nil)
	HorseService.dismount(p)
	check("rittslut (avsittning) mitt i banan: egna", egna(p))
	mount(p)
end)()

print("\n── 4. Katalogen nekar: anmälan och ritten går ändå, egna kläder ──")
;(function()
	tjanst({}) -- inga poster: varje uppslag nekas
	tillStart()
	local okA, _, ba = request("anmal_pink")
	check("anmälan går igenom", okA and ba.lage == "startlista")
	local b = image()
	check("«misslyckades», avataren orörd", b.klader and b.klader.lage == "misslyckades" and egna(p),
		b.klader and b.klader.lage)
	check("anmälan står kvar: startlistan, startnummer 1", b.lage == "startlista" and b.anmalan ~= nil
		and b.anmalan.startnummer == 1, b.lage)
	request("ga_banan")
	local okS, _, bs = request("start")
	check("startsignal och bana fungerar", okS and bs.lage == "to_start")
	helaBanan()
	check("hela banan: resultat, egna kläder", image().lage == "complete" and egna(p))
	request("finish")
	-- Fel AssetType: samma sak.
	local fel = allaRatta()
	fel[T.set("oak").shirtAssetId] = { ok = true, assetTypeId = T.ASSETTYPE_PANTS }
	tjanst(fel)
	request("anmal_oak")
	check("fel AssetType: «misslyckades», egna", image().klader.lage == "misslyckades" and egna(p))
	request("finish")
end)()

print("\n── 5. Sent svar: Avsluta medan uppslaget väntar ──")
;(function()
	tjanst(allaRatta(), true)
	__schemaPa(true)
	request("anmal_white")
	__schemaSteg() -- uppslaget börjar och pausar mitt i
	check("uppslaget pågår (pausat), «laddar»", katalog.anrop >= 1 and image().klader.lage == "laddar")
	request("finish")
	__schemaTomKo(); __schemaPa(false)
	check("efter Avsluta: aldrig skrivet, aldrig «pa»", egna(p) and image().klader == nil and image().lage == "closed")
	tjanst(allaRatta())
end)()

print("\n── 6. Manipulerade val nekas; andra lektioner rör inte kläder ──")
;(function()
	for _, op in ipairs({ "anmal_xyz", "anmal_White", "anmal_11268412339", "anmal_" }) do
		local ok, fel = request(op)
		check("«" .. op .. "» nekas, ingen anmälan, ingen katalogfråga", ok == false and image().anmalan == nil
			and katalog.anrop == 0 and egna(p), tostring(fel))
	end
	local okV = request("anmal_white", "volt")
	check("anmal_white i en annan lektion nekas, kläderna orörda", okV == false and egna(p) and katalog.anrop == 0)
	request("finish", "volt")
end)()

print("\n── 7. Två spelare, olika set ──")
;(function()
	local p1 = P1
	tillStart(); request("anmal_white")
	check("spelare 1: white", iSet(p1, "white"))
	-- Spelare 2 på samma häst efter spelare 1 (en häst i bänken): 1 sitter av först.
	HorseService.dismount(p1)
	check("spelare 1 efter rittslut: egna", egna(p1))
	local p2 = player(802)
	mount(p2)
	tillStart(); request("anmal_oak")
	check("spelare 2: oak, spelare 1 opåverkad", iSet(p2, "oak") and egna(p1))
	request("finish")
	check("spelare 2 Avsluta: egna, spelare 1 opåverkad", egna(p2) and egna(p1))
end)()

print("\n── 8. Klienten: knapparna, bläddringen och raderna ──")
;(function()
	-- Spelare 2 sitter av; spelare 1 (LocalPlayer) upp igen. Riktig controller och synk.
	HorseService.dismount(p)
	Skopa._nollstallForProv()
	mount(P1)
	tillStart()
	local VC, UC = VoltLektionController, UgnetaController
	local syncC = Networking.get("VoltLektionSync")
	local function leverera() syncC.OnClientEvent:Fire(image()) end
	local function hitta(knappar, txt)
		for _, k in ipairs(knappar) do if k.text == txt then return k end end
		return nil
	end
	local PREFIX = Sprak.t("clearround.klader_val", "")
	local function kladknapp()
		for _, k in ipairs(VC.panel().knappar) do
			if type(k.text) == "string" and string.sub(k.text, 1, #PREFIX) == PREFIX then return k end
		end
		return nil
	end
	local function alla(knappar)
		local t = {}
		for _, k in ipairs(knappar) do table.insert(t, tostring(k.text)) end
		return table.concat(t, " | ")
	end
	Sprak.satVal("sv")
	VC.avbryt(); VC.start(id, nil)
	UC.satLektionsVal(VC.panel); UC.dolj()
	VC.valj("clearround"); leverera()
	local kn = VC.panel().knappar
	local kl = kladknapp()
	check("«Kläder: Egna kläder» och «Anmäl dig», högst fyra knappar", kl ~= nil
		and kl.text == Sprak.t("clearround.klader_val", Sprak.t("clearround.klader_egna"))
		and hitta(kn, Sprak.t("clearround.anmal")) ~= nil and #kn <= 4, alla(kn))
	local ordning = {}
	for _ = 1, 4 do
		local k = kladknapp()
		if k then k.skicka() end
		local k2 = kladknapp()
		table.insert(ordning, k2 and k2.text or "?")
	end
	check("bläddringen: White → Pink → Oak → Egna (serverns ordning)",
		ordning[1] == Sprak.t("clearround.klader_val", "White Equestrian Set")
		and ordning[2] == Sprak.t("clearround.klader_val", "Pink Equestrian Set")
		and ordning[3] == Sprak.t("clearround.klader_val", "Oak Equestrian Set")
		and ordning[4] == Sprak.t("clearround.klader_val", Sprak.t("clearround.klader_egna")), table.concat(ordning, " / "))
	kladknapp().skicka(); kladknapp().skicka() -- Pink
	local fore = katalog.anrop
	hitta(VC.panel().knappar, Sprak.t("clearround.anmal")).skicka()
	leverera()
	local b = image()
	check("«Anmäl dig» med Pink valt: servern får anmal_pink och klär i pink", b.lage == "startlista"
		and b.klader and b.klader.set == "pink" and katalog.anrop > fore and iSet(p, "pink"),
		b.klader and b.klader.set)
	check("startlistan: «Tävlingskläder: Pink Equestrian Set.»",
		string.find(VC.panel().text, Sprak.t("clearround.klader_pa", "Pink Equestrian Set"), 1, true) ~= nil, VC.panel().text)
	-- Deklarerade bilder för «laddar» och «misslyckades» (högre revision).
	local bas = image().revision + 1000
	local function fake(lage, plus)
		local f = table.clone(image())
		f.klader = { set = "oak", namn = "Oak Equestrian Set", lage = lage }
		f.revision = bas + plus
		syncC.OnClientEvent:Fire(table.freeze(f))
	end
	fake("laddar", 0)
	check("«laddar»: «Tävlingskläderna laddas …»",
		string.find(VC.panel().text, Sprak.t("clearround.klader_laddar"), 1, true) ~= nil, VC.panel().text)
	fake("misslyckades", 1)
	check("«misslyckades»: du rider i dina egna kläder", string.find(VC.panel().text,
		Sprak.t("clearround.klader_misslyckades"), 1, true) ~= nil, VC.panel().text)
	Sprak.satVal("en")
	check("en: «you ride in your own clothes»", string.find(VC.panel().text,
		"you ride in your own clothes", 1, true) ~= nil, VC.panel().text)
	Sprak.satVal("sv")
	-- Klientens egna anrop drev ritten begäranbok framåt; provets sekvens hoppar förbi.
	seq += 1000
	local okF = request("finish")
	check("och Avsluta: egna", okF and egna(p))
	UC.satLektionsVal(nil)
	VC.avbryt()
end)()

print("\n── 9. Varje livscykelutgång i bänken: död, karaktär borta, respawn, lämnar ──")
;(function()
	HorseService.dismount(p)
	--[[ Varje utgång med EN ny spelare i white. Död, karaktär borta och lämnar
		går både genom rittslutet (HorseService sitter av → kladerAv) och genom
		tjänstens egen vakt; respawn går bara genom tjänstens vakt. ]]
	local function klarSpelare(uid)
		local pl = player(uid)
		mount(pl)
		tillStart()
		request("anmal_white")
		return pl
	end
	-- Död.
	local pd = klarSpelare(811)
	local kd = pd.Character
	check("död: white på före", iSet(pd, "white"))
	kd:FindFirstChildOfClass("Humanoid").Health = 0
	check("död: egna kläder tillbaka, hästen ledig", egna(pd) and HorseService.horseOf(pd) == nil)
	-- Karaktären borta.
	local pk = klarSpelare(812)
	check("karaktär borta: white på före", iSet(pk, "white"))
	pk.CharacterRemoving:Fire(pk.Character)
	check("karaktär borta: egna kläder tillbaka, hästen ledig", egna(pk) and HorseService.horseOf(pk) == nil)
	--[[ Respawn, i Robloxs ordning: den gamla kroppen tas bort (CharacterRemoving)
		och en ny läggs till (CharacterAdded). Tjänsten skriver ALDRIG på en gammal
		kropp (TavlingskladerService: «den gamla kroppen skrivs aldrig på någon
		annan») — återställningen sker innan bytet, via rittslutet och vakten. ]]
	local pr = klarSpelare(813)
	local gammal = pr.Character
	check("respawn: white på före, tjänsten håller en session", iSet(pr, "white") and aktivTjanst.aktivt(pr) == "white")
	pr.CharacterRemoving:Fire(gammal)
	local ny = player(9813).Character
	pr.Character = ny
	pr.CharacterAdded:Fire(ny)
	local gs, gb = gammal:FindFirstChildOfClass("Shirt"), gammal:FindFirstChildOfClass("Pants")
	check("respawn: gamla kroppen återställd innan bytet, nya kroppen orörd, ingen session kvar",
		gs and gs.ShirtTemplate == EGEN_T and gb and gb.PantsTemplate == EGEN_B and egna(pr)
		and aktivTjanst.aktivt(pr) == nil and HorseService.horseOf(pr) == nil,
		("gammal %s, ny %s, session %s"):format(tostring(gs and gs.ShirtTemplate), tostring(egna(pr)),
			tostring(aktivTjanst.aktivt(pr))))
	--[[ Bara CharacterAdded (utan borttagning): tjänstens vakt avslutar sessionen
		och rör inte den gamla kroppen — dess design. Mäts för att den vägen
		också lämnar noll kvar, inte för att den förekommer i spelet. ]]
	local pa2 = klarSpelare(815)
	local gammal2 = pa2.Character
	local ny2 = player(9815).Character
	pa2.Character = ny2
	pa2.CharacterAdded:Fire(ny2)
	check("bara CharacterAdded: sessionen slut, nya kroppen orörd, gamla kroppen inte skriven på igen",
		aktivTjanst.aktivt(pa2) == nil and egna(pa2) and iSet({ Character = gammal2 }, "white"))
	HorseService.dismount(pa2)
	-- Lämnar spelet.
	local pl = klarSpelare(814)
	check("lämnar: white på före", iSet(pl, "white"))
	Players.PlayerRemoving:Fire(pl)
	check("lämnar: egna kläder tillbaka, hästen ledig", egna(pl) and HorseService.horseOf(pl) == nil)
end)()

print("\n── 10. R1: vakterna faller EFTER skrivningen — egna kläder, ingen session, anmälan går vidare ──")
;(function()
	local function provSignal(karaktarFor)
		--[[ En signal som kan fås att FALLA vid Connect, och som räknar sina
			levande kopplingar. `karaktarFor` ger kroppen vars tröja noteras i
			felögonblicket — beviset att felet kom EFTER skrivningen. ]]
		local sig = { kopplingar = {}, fela = false, vidFel = nil }
		function sig:Connect(fn)
			if self.fela then
				local k = karaktarFor and karaktarFor()
				local sh = k and k:FindFirstChildOfClass("Shirt")
				self.vidFel = sh and sh.ShirtTemplate or "ingen"
				error("bindningen föll (prov)")
			end
			local c = { Connected = true, fn = fn }
			function c:Disconnect() self.Connected = false end
			table.insert(self.kopplingar, c)
			return c
		end
		function sig:Fire(...)
			for _, c in ipairs(self.kopplingar) do if c.Connected then c.fn(...) end end
		end
		function sig:anslutna()
			local n = 0
			for _, c in ipairs(self.kopplingar) do if c.Connected then n += 1 end end
			return n
		end
		return sig
	end
	local pf = player(820)
	pf.CharacterAdded = provSignal(nil)
	pf.CharacterRemoving = provSignal(function() return pf.Character end)
	mount(pf)
	tillStart()
	local fore = pf.CharacterAdded:anslutna()
	pf.CharacterRemoving.fela = true -- vakt nummer två faller, efter att nummer ett bundits
	local okA, felA, ba = request("anmal_white")
	pf.CharacterRemoving.fela = false
	check("felet kom EFTER skrivningen (tröjan var tävlingens i felögonblicket)",
		pf.CharacterRemoving.vidFel == TavlingskladerService.mall(T.set("white").shirtAssetId),
		tostring(pf.CharacterRemoving.vidFel))
	check("anmälan gick igenom: startlistan", okA and ba.lage == "startlista", tostring(felA))
	local b = image()
	check("bilden säger «misslyckades»", b.klader and b.klader.lage == "misslyckades", b.klader and b.klader.lage)
	check("EGNA kläder tillbaka (exakt läget före skrivningen)", egna(pf))
	check("ingen klädsession registrerad", aktivTjanst.aktivt(pf) == nil and #aktivTjanst.aktivaSpelare() == 0)
	check("den redan bundna vakten (CharacterAdded) är bortkopplad", pf.CharacterAdded:anslutna() == fore,
		("%d anslutna, %d före"):format(pf.CharacterAdded:anslutna(), fore))
	check("tjänsten håller inget kvar om spelaren", aktivTjanst.kvarvarande() == 0, aktivTjanst.kvarvarande())
	request("ga_banan")
	local okS, _, bs = request("start")
	check("ritten går vidare: banskiss och startsignal", okS and bs.lage == "to_start")
	request("finish")
	check("och Avsluta: fortfarande egna", egna(pf))
	HorseService.dismount(pf)
end)()

check("inget persistent skrevs", (__datastore.forsok and __datastore.forsok.skriv or 0) == writes)
if fails > 0 then error(("%d mätning(ar) föll."):format(fails), 0) end
print(string.format("\nclearround-klader.spec: %d prov, alla gröna", total))
