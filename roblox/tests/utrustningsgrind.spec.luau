--!nostrict
--[[
	EQUIPMENT & RIDER GEAR GATE (#165) — servern.

	Det som mäts:
	  1. katalogen är EN sanning: typer, assets, licens, attribution, beslut;
	  2. hjälmen är FYSISK på spelaren, som sadeln är på hästen;
	  3. Creator Store-modeller laddas genom `InsertService`, passas in,
	     svetsas — och FALLER TILLBAKA på primitiven när laddningen inte
	     går, när modellen bär ett skript, och när Studio-QA tvingar den;
	  4. genom `GameplayService`: hjälmen krävs för att sitta upp, sadel och
	     träns går att ta AV igen och checklistan följer världen, eftervården
	     tar av på riktigt, ingenting byts på hästryggen, hjälmen kommer
	     tillbaka efter respawn.

	Kör: python3 roblox/tests/build.py tests/utrustningsgrind.spec.luau
	     && luau roblox/tests/.build/utrustningsgrind.spec.luau
]]

local fails = 0
local function check(namn, villkor, detalj)
	if villkor then
		print(string.format("  OK   %s%s", namn, detalj and ("  " .. detalj) or ""))
	else
		fails += 1
		print(string.format("  FEL  %s%s", namn, detalj and ("  " .. detalj) or ""))
	end
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local InsertService = game:GetService("InsertService")
local Taggar = game:GetService("CollectionService")
RunService._server = true

local function vec(x, y, z) return Vector3.new(x, y, z) end

local function nyKaraktar(pos, utanHuvud)
	local k = Instance.new("Model")
	k.Name = "Karaktar"
	local rot = Instance.new("Part")
	rot.Name = "HumanoidRootPart"
	rot.Size = vec(2, 2, 1)
	rot.CFrame = CFrame.new(pos)
	rot.Parent = k
	if not utanHuvud then
		local huvud = Instance.new("Part")
		huvud.Name = "Head"
		huvud.Size = vec(2, 1, 1)
		huvud.CFrame = CFrame.new(pos) * CFrame.new(0, 1.5, 0)
		huvud.Parent = k
	end
	local hum = Instance.new("Humanoid")
	hum.Name = "Humanoid"
	hum.Parent = k
	local anim = Instance.new("Animator")
	anim.Name = "Animator"
	anim.Parent = hum
	k.Parent = workspace
	return k, rot, hum
end

local function nySpelare(namn, userId, pos, utanHuvud)
	local k, rot, hum = nyKaraktar(pos, utanHuvud)
	return { Name = namn, UserId = userId, Character = k,
		CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }, k, rot, hum
end

-- ══ 1. KATALOGEN ═══════════════════════════════════════════════════════
print("\n── 1. Katalogen är en sanning ──")
do
	for _, typ in ipairs(Utrustning.PANEL) do
		check("panelens typ " .. typ .. " finns i katalogen", Utrustning.post(typ) ~= nil)
	end
	local hj = Utrustning.post("hjalm")
	check("hjälmen krävs för ridning (ridskolans regel, datastyrd)",
		Utrustning.kravsForRidning("hjalm") == true)
	--[[ PO-val 2026-09-14 05:02: 92445706145003 ersätter både den avvisade
		123547958 och den ersatta 11611844698. Provet spikar ID:t så att en
		redigering inte kan byta det tyst — och att inget av de två
		utmönstrade ID:na finns i någon katalogpost. ]]
	check("hjälmens Creator Store-modell är 92445706145003 (rosto do silva 25k), antagen utan skript",
		hj.assetId == 92445706145003 and hj.skript == 0 and hj.visual == "asset"
			and hj.beslut:find("ANTAGEN", 1, true) ~= nil, tostring(hj.assetId) .. " " .. tostring(hj.beslut))
	do
		local avvisat, ersatt = false, false
		for _, a in ipairs(Utrustning.AVVISADE) do
			if a.assetId == 123547958 then avvisat = true end
			if a.assetId == 11611844698 then ersatt = true end
		end
		local aterkommet = false
		for _, post in ipairs(Utrustning.katalog()) do
			for _, a in ipairs(Utrustning.AVVISADE) do
				if post.assetId == a.assetId then aterkommet = true end
			end
		end
		check("de utmönstrade hjälmarna 123547958 och 11611844698 står i AVVISADE och i ingen katalogpost",
			avvisat and ersatt and not aterkommet)
	end
	local sa, tr = Utrustning.post("sadel"), Utrustning.post("trans")
	check("sadel och träns är antagna runtime-kandidater utan skript",
		sa.assetId == 9639407836 and sa.skript == 0 and sa.visual == "asset"
			and tr.assetId == 15966015286 and tr.skript == 0 and tr.visual == "asset")
	check("båda bär licensfyndet", type(sa.licens) == "string" and type(tr.licens) == "string"
		and sa.licens:find("Creator Store", 1, true) ~= nil)
	local attr = Utrustning.attributioner()
	check("RHS-krediten för tränset står i attributionslistan",
		#attr >= 1 and attr[1]:find("RHS", 1, true) ~= nil and attr[1]:find("corvyyn", 1, true) ~= nil,
		table.concat(attr, " | "))
	check("Studio-QA kan tvinga primitiven utan kodändring",
		Utrustning.visualFor("sadel", "primitiv") == "primitiv"
			and Utrustning.visualFor("sadel", nil) == "asset"
			and Utrustning.visualFor("hjalm", "asset") == "asset")
	check("hoppen är utvärderade: exakt ett rekommenderas, inget integreras",
		#Utrustning.HOPP == 4 and Utrustning.HOPP[1].assetId == 2780160044
			and Utrustning.HOPP[1].beslut:find("REKOMMENDERAD", 1, true) ~= nil)
end

-- ══ 2. HJÄLMEN ÄR FYSISK ═══════════════════════════════════════════════
print("\n── 2. Hjälmen är fysisk på spelaren ──")
do
	local spelare, k = nySpelare("Hjalm", 7001, vec(0, 0, 0))
	check("ingen hjälm från början", not TackService.harHjalm(spelare))
	local ok, skal = TackService.satPaHjalm(spelare)
	check("hjälmen går på", ok, tostring(skal))
	check("och tillståndet läses ur världen", TackService.harHjalm(spelare))
	local d = TackRigg.hittaDel(k, "hjalm")
	check("delen finns i karaktärens Tack-mapp", d ~= nil and d.Parent and d.Parent.Name == "Tack")
	local svets = d and d:FindFirstChildOfClass("WeldConstraint")
	check("svetsad i HUVUDET", svets ~= nil and svets.Part0 == k:FindFirstChild("Head"),
		svets and tostring(svets.Part0 and svets.Part0.Name) or "-")
	check("kolliderar inte och väger inget — kameran och rörelsen märker den inte",
		d ~= nil and d.CanCollide == false and d.Massless == true)
	check("bär vem den tillhör", d ~= nil and d:GetAttribute("ForSpelare") == "7001")
	check("utan nåbar modell ritas primitiven — tillståndet är detsamma",
		d ~= nil and d:GetAttribute("UBRFVisual") == "primitiv")
	local ok2, skal2 = TackService.satPaHjalm(spelare)
	check("en andra hjälm nekas", ok2 == false and skal2 == "tack.hjalm_redan_pa", tostring(skal2))
	local ok3 = TackService.taAvHjalm(spelare)
	check("hjälmen går av", ok3 and not TackService.harHjalm(spelare))
	check("och ingenting ligger kvar i mappen", TackRigg.hittaDel(k, "hjalm") == nil)
	local ok4, skal4 = TackService.taAvHjalm(spelare)
	check("av utan hjälm nekas", ok4 == false and skal4 == "tack.ingen_hjalm", tostring(skal4))
	local utan = nySpelare("Huvudlos", 7002, vec(5, 0, 0), true)
	local ok5, skal5 = TackService.satPaHjalm(utan)
	check("en karaktär utan huvud kan inte ta på hjälmen — inget tyst tillstånd",
		ok5 == false and skal5 == "tack.kunde_inte_byggas" and not TackService.harHjalm(utan),
		tostring(skal5))
	local ok6, skal6 = TackService.ryttareKlar(utan)
	check("och är inte ridklar som ryttare", ok6 == false and skal6 == "tack.saknar_hjalm")
end

-- ══ 3. CREATOR STORE-MODELLERNA ═══════════════════════════════════════
print("\n── 3. Modellerna laddas, passas in och faller tillbaka ──")
local hast = HastRigg.bygg("blackrock_jack", "Blackrock Jack", CFrame.new(vec(30, 0, 0)))
hast.Parent = workspace
local spelare3, _, rot3 = nySpelare("Modell", 7003, vec(33, 0, 0))

local function modellMed(delar, medSkript)
	return function()
		local m = Instance.new("Model")
		m.Name = "Laddad"
		for i, storlek in ipairs(delar) do
			local p = Instance.new("MeshPart")
			p.Name = "Del" .. i
			p.Size = storlek
			p.CFrame = CFrame.new(vec(i * 2, 0, 0))
			p.Anchored = true
			p.CanCollide = true
			p.Parent = m
		end
		if medSkript then
			local sk = Instance.new("Script")
			sk.Name = "Farligt"
			sk.Parent = m
		end
		return m
	end
end
local function antalDelar()
	local f = hast:FindFirstChild("Tack")
	return f and #f:GetChildren() or 0
end

do
	--[[ a) ingen stubbad modell → laddningen faller → primitiven. ]]
	InsertService._svar = {}
	InsertService._anrop = {}
	TackService.satPa(spelare3, hast, "underlagg", nil, hast)
	local ok = TackService.satPa(spelare3, hast, "sadel", nil, hast)
	local sits = TackRigg.hittaDel(hast, "sadel")
	check("a) utan nåbar modell går sadeln ändå på — som primitiv",
		ok and sits ~= nil and sits:GetAttribute("UBRFVisual") == "primitiv",
		sits and tostring(sits:GetAttribute("UBRFVisual")) or "-")
	check("   och laddningen PRÖVADES (vägen är inte död)",
		#InsertService._anrop == 1 and InsertService._anrop[1] == 9639407836,
		tostring(InsertService._anrop[1]))
	TackService.taAvAllt(hast)

	--[[ b) en stubbad modell med två delar, mycket större än lådan. ]]
	InsertService._svar[9639407836] = modellMed({ vec(10, 4, 14), vec(3, 3, 3) })
	TackService.satPa(spelare3, hast, "underlagg", nil, hast)
	local ok2 = TackService.satPa(spelare3, hast, "sadel", nil, hast)
	local rot = TackRigg.hittaDel(hast, "sadel")
	check("b) modellen laddas och bär tillståndet", ok2 and rot ~= nil
		and rot:GetAttribute("UBRFVisual") == "asset"
		and rot:GetAttribute("UBRFAssetId") == 9639407836
		and rot:GetAttribute("ForHast") == "blackrock_jack")
	check("   den största delen är bäraren", rot ~= nil and rot.Name == "Del1")
	check("   passad in i primitivens låda (0,44 x 0,30 x 0,62 m)",
		rot ~= nil and rot.Size.X <= 0.44 * 3 + 0.01 and rot.Size.Y <= 0.30 * 3 + 0.01
			and rot.Size.Z <= 0.62 * 3 + 0.01,
		rot and string.format("%.2f x %.2f x %.2f studs", rot.Size.X, rot.Size.Y, rot.Size.Z) or "-")
	local svets = rot and rot:FindFirstChildOfClass("WeldConstraint")
	check("   svetsad i hästen", svets ~= nil and svets.Part0 ~= nil and svets.Part0:IsDescendantOf(hast))
	check("   och ingen del kolliderar, väger eller är förankrad",
		rot ~= nil and rot.CanCollide == false and rot.Anchored == false and rot.Massless == true)
	local andra = nil
	for _, d in ipairs(hast:FindFirstChild("Tack"):GetChildren()) do if d.Name == "Del2" then andra = d end end
	local w2 = andra and andra:FindFirstChildOfClass("WeldConstraint")
	check("   den andra delen ligger platt i Tack-mappen, svetsad i bäraren",
		andra ~= nil and w2 ~= nil and w2.Part0 == rot)
	local med = antalDelar()
	TackService.taAv(spelare3, hast, "sadel")
	check("   sadeln av river hela modellen", TackRigg.hittaDel(hast, "sadel") == nil
		and antalDelar() == med - 2, string.format("%d → %d delar", med, antalDelar()))
	TackService.taAvAllt(hast)

	--[[ c) ett skript i modellen → avvisas → primitiv. ]]
	InsertService._svar[9639407836] = modellMed({ vec(4, 2, 6) }, true)
	TackService.satPa(spelare3, hast, "underlagg", nil, hast)
	TackService.satPa(spelare3, hast, "sadel", nil, hast)
	local s3 = TackRigg.hittaDel(hast, "sadel")
	check("c) en modell med ett Script avvisas — primitiven ritas",
		s3 ~= nil and s3:GetAttribute("UBRFVisual") == "primitiv",
		s3 and tostring(s3:GetAttribute("UBRFVisual")) or "-")
	local farligt = false
	for _, d in ipairs(workspace:GetDescendants()) do
		if d.Name == "Farligt" then farligt = true end
	end
	check("   och skriptet finns ingenstans i världen", not farligt)
	TackService.taAvAllt(hast)

	--[[ d) Studio-QA:s tvingande attribut. ]]
	InsertService._svar[9639407836] = modellMed({ vec(4, 2, 6) })
	local gammal = workspace.GetAttribute
	workspace.GetAttribute = function(_, k) if k == "UBRFUtrustningVisual" then return "primitiv" end return nil end
	TackService.satPa(spelare3, hast, "underlagg", nil, hast)
	TackService.satPa(spelare3, hast, "sadel", nil, hast)
	local s4 = TackRigg.hittaDel(hast, "sadel")
	check("d) workspace.UBRFUtrustningVisual = primitiv tvingar primitiven trots laddbar modell",
		s4 ~= nil and s4:GetAttribute("UBRFVisual") == "primitiv")
	workspace.GetAttribute = gammal
	TackService.taAvAllt(hast)

	--[[ e) tränset går samma väg, i huvudets låda. ]]
	InsertService._svar[15966015286] = modellMed({ vec(8, 8, 8) })
	TackService.satPa(spelare3, hast, "underlagg", nil, hast)
	TackService.satPa(spelare3, hast, "sadel", nil, hast)
	TackService.satPa(spelare3, hast, "trans", nil, hast)
	local t = TackRigg.hittaDel(hast, "trans")
	local huvud = hast:FindFirstChild("Visual"):FindFirstChild("Head")
	local ws = t and t:FindFirstChildOfClass("WeldConstraint")
	check("e) tränset laddas och svetsas i HUVUDET",
		t ~= nil and t:GetAttribute("UBRFVisual") == "asset" and ws ~= nil and ws.Part0 == huvud)
	check("   tyglarna kom ändå med (de hör till tränset, inte till modellen)",
		TackRigg.hittaDel(hast, "tygel") ~= nil)
	TackService.taAvAllt(hast)

	--[[ f) HJÄLMEN laddas samma väg: i huvudets låda, svetsad i Head, med
		spelarens ägarskap — och ett skript i den avvisar den. ]]
	InsertService._svar[92445706145003] = modellMed({ vec(6, 4, 6), vec(2, 1, 2) })
	local spH, kH = nySpelare("Silva", 7004, vec(40, 0, 0))
	local okH, skalH = TackService.satPaHjalm(spH)
	local dH = TackRigg.hittaDel(kH, "hjalm")
	local wH = dH and dH:FindFirstChildOfClass("WeldConstraint")
	check("f) hjälmen 92445706145003 laddas som hjälmens visual och svetsas i Head",
		okH and dH ~= nil and dH:GetAttribute("UBRFVisual") == "asset"
			and dH:GetAttribute("UBRFAssetId") == 92445706145003
			and wH ~= nil and wH.Part0 == kH:FindFirstChild("Head"), tostring(skalH))
	check("   den bär spelarens ägarskap och räknas som påsatt",
		dH ~= nil and dH:GetAttribute("ForSpelare") == "7004" and TackService.harHjalm(spH))
	local huvudH = kH:FindFirstChild("Head")
	check("   passad in i huvudets låda (inte större än 1,25/0,9/1,3 × huvudet)",
		dH ~= nil and dH.Size.X <= huvudH.Size.X * 1.25 + 0.01 and dH.Size.Y <= huvudH.Size.Y * 0.9 + 0.01
			and dH.Size.Z <= huvudH.Size.Z * 1.3 + 0.01,
		dH and string.format("%.2f x %.2f x %.2f", dH.Size.X, dH.Size.Y, dH.Size.Z) or "-")
	check("   ingen del kolliderar eller väger", dH ~= nil and dH.CanCollide == false and dH.Massless == true)
	TackService.taAvHjalm(spH)
	check("   hjälmen av river hela modellen", TackRigg.hittaDel(kH, "hjalm") == nil
		and (kH:FindFirstChild("Tack") == nil or #kH:FindFirstChild("Tack"):GetChildren() == 0))
	InsertService._svar[92445706145003] = modellMed({ vec(6, 4, 6) }, true)
	TackService.satPaHjalm(spH)
	local dS = TackRigg.hittaDel(kH, "hjalm")
	check("   en hjälmmodell med Script avvisas — primitiven ritas",
		dS ~= nil and dS:GetAttribute("UBRFVisual") == "primitiv")
	TackService.taAvHjalm(spH)
	InsertService._svar = {}
end

-- ══ 4. GENOM GAMEPLAYSERVICE ══════════════════════════════════════════
print("\n── 4. Genom tjänsten: krav, ångra, eftervård, respawn ──")

local function nySession(namn, userId)
	__datastore.nollstall()
	Taggar:nollstall()
	Players.PlayerAdded:nollstall()
	Players.PlayerRemoving:nollstall()
	Players._spelare = {}
	SparService._glomHookarForProv()
	local spelare, karaktar, rot, hum = nySpelare(namn, userId, vec(6, 0, 0))
	SparService._glomForProv(spelare)
	SparService.start()
	StallService.start()
	HorseService.start()
	GameplayService.start()
	Players._spelare = { spelare }
	Players.PlayerAdded:Fire(spelare)
	Players.PlayerAdded:slutfor()
	local hastId = StallService.hastIdFor(spelare)
	local h = (UBRFSpel.hastar or {})[hastId]
	local modell = HastRigg.bygg(hastId, (h and h.namn) or hastId, CFrame.new(vec(0, 0, 0)))
	modell.Parent = workspace
	Taggar:AddTag(modell, "Horse")
	return { spelare = spelare, karaktar = karaktar, rot = rot, hum = hum, hastId = hastId, modell = modell }
end

local function skotsel(spelare)
	for _, fas in ipairs(Preparation.stegFaser()) do
		if fas.id == "leda" then
			local modell = GameplayService.modellFor(spelare)
			local zon = LedService.malzon()
			local rot = spelare.Character and spelare.Character:FindFirstChild("HumanoidRootPart")
			if modell and zon and rot and modell.PrimaryPart then
				LedService.borja(spelare, modell, modell)
				local mx = (zon.x + zon.w / 2) * 3
				local mz = (170 - (zon.y + zon.h / 2)) * 3
				modell.PrimaryPart.CFrame = CFrame.new(mx, modell.PrimaryPart.Position.Y, mz)
				rot.CFrame = CFrame.new(mx + 6, rot.Position.Y, mz)
				LedService._steg(1 / 30)
			end
		end
		if fas.id == "iordning" then
			local s0 = GameplayService.stateFor(spelare)
			GameplayService.valjUtrustning(spelare, "sadel", s0.hastId)
			GameplayService.valjUtrustning(spelare, "trans", s0.hastId)
		end
		while true do
			local s = GameplayService.stateFor(spelare)
			local m = Preparation.nastaMoment(s, fas.id)
			if not m then break end
			local ok, skal = GameplayService.moment(spelare, fas.id, m.id)
			if not ok then return false, string.format("%s/%s: %s", fas.id, m.id, tostring(skal)) end
		end
	end
	return true
end

local function sistaSync(spelare)
	local ev = Networking.get("PreparationSync")
	for i = #ev._skickat, 1, -1 do
		if ev._skickat[i][1] == spelare then return ev._skickat[i][2] end
	end
	return nil
end

do
	local S = nySession("Grind", 7101)
	local ok, skal = skotsel(S.spelare)
	check("skötseln gick igenom utan hjälmsteg", ok == true, tostring(skal))
	check("hon är sadlad och tränsad", TackService.ridklar(S.modell))

	--[[ a) hjälmen krävs. ]]
	local okU, skalU = GameplayService.farSittaUpp(S.spelare, S.modell)
	check("a) utan hjälm nekas uppsittningen med hjälmens skäl",
		okU == false and skalU == "tack.saknar_hjalm" and Sprak.finns(skalU), tostring(skalU))
	local okH, skalH = GameplayService.utrustning(S.spelare, "hjalm", true)
	check("   hjälmen på genom tjänsten", okH, tostring(skalH))
	local vy = sistaSync(S.spelare)
	check("   och vyn läser hjälmen ur världen",
		vy ~= nil and vy.utrustning and vy.utrustning.hjalm == true and vy.utrustning.sadel == true
			and vy.utrustning.trans == true and vy.utrustning.hjalmKravs == true)
	check("   nu släpper grinden", (GameplayService.farSittaUpp(S.spelare, S.modell)) == true)

	--[[ b) ångra: sadeln av före ritten. ]]
	local okA, skalA = GameplayService.utrustning(S.spelare, "sadel", false)
	check("b) sadeln går att ta av igen", okA, tostring(skalA))
	check("   fysiskt: varken sadel eller underlägg kvar",
		not TackService.sadlad(S.modell) and not TackService.harTack(S.modell, "underlagg"))
	local st = GameplayService.stateFor(S.spelare)
	check("   och checklistan följer världen: utr:1–4 ogjorda, utr:5 kvar",
		st.gjorda.iordning["utr:1"] == nil and st.gjorda.iordning["utr:4"] == nil
			and st.gjorda.iordning["utr:5"] == true and st.klara.iordning == nil)
	check("   statusen är inte längre 'redo'",
		GameplayService.statusFor(S.spelare) ~= Preparation.STATUS.REDO,
		tostring(GameplayService.statusFor(S.spelare)))
	local okP, skalP = GameplayService.utrustning(S.spelare, "sadel", true)
	check("   påsättning går INTE genom panelen — momenten är vägen",
		okP == false and skalP == "tack.pa_via_momenten", tostring(skalP))
	local okT = GameplayService.utrustning(S.spelare, "trans", false)
	check("   tränset av också", okT and not TackService.transad(S.modell)
		and GameplayService.stateFor(S.spelare).gjorda.iordning["utr:5"] == nil)
	local okOm, skalOm = skotsel(S.spelare)
	check("   momenten görs om och hon är redo igen", okOm and TackService.ridklar(S.modell)
		and GameplayService.statusFor(S.spelare) == Preparation.STATUS.REDO, tostring(skalOm))
	local okOk, skalOk = GameplayService.utrustning(S.spelare, "grimskaft", false)
	check("   okänd typ nekas", okOk == false and skalOk == "tack.okand_utrustning")

	--[[ c) ingenting byts på hästryggen. ]]
	check("c) hon sitter upp", (HorseService.tryMount(S.spelare, S.modell)) == true)
	local okR, skalR = GameplayService.utrustning(S.spelare, "hjalm", false)
	check("   hjälmen av på hästryggen nekas", okR == false and skalR == "tack.sitter_upp", tostring(skalR))
	local okR2, skalR2 = GameplayService.utrustning(S.spelare, "sadel", false)
	check("   sadeln av under ryttaren nekas", okR2 == false and skalR2 == "tack.sitter_upp", tostring(skalR2))
	check("   och hon sitter fortfarande upp", HorseService.horseOf(S.spelare) == S.modell)

	--[[ d) eftervården tar av på riktigt. ]]
	HorseService.dismount(S.spelare)
	local p = GameplayService.passFor(S.spelare)
	check("d) passet är i eftervården", p ~= nil and p.lage == Pass.LAGE.EFTERVARD, p and tostring(p.lage) or "-")
	local fore = TackService.sadlad(S.modell)
	for _, m in ipairs(Pass.moment()) do
		local okE, skalE = GameplayService.eftervard(S.spelare, m.id)
		if m.id == "sadel" then
			check("   'Ta av sadeln' tar av sadel OCH underlägg fysiskt",
				okE and fore and not TackService.sadlad(S.modell)
					and not TackService.harTack(S.modell, "underlagg"), tostring(skalE))
			check("   medan tränset sitter kvar tills sitt moment", TackService.transad(S.modell))
		elseif m.id == "trans" then
			check("   'Ta av tränset' tar av tränset och tyglarna",
				okE and not TackService.transad(S.modell) and TackRigg.hittaDel(S.modell, "tygel") == nil,
				tostring(skalE))
		end
	end
	local vyE = sistaSync(S.spelare)
	check("   vyn efter eftervården: inget på hästen, hjälmen kvar",
		vyE ~= nil and vyE.utrustning.sadel == false and vyE.utrustning.trans == false
			and vyE.utrustning.hjalm == true)
	local okHa = GameplayService.utrustning(S.spelare, "hjalm", false)
	check("   hjälmen av efter ritten — utrustningen lämnas tillbaka", okHa and not TackService.harHjalm(S.spelare))

	--[[ e) respawn ger hjälmen tillbaka om hon hade den på. ]]
	GameplayService.utrustning(S.spelare, "hjalm", true)
	local k2 = nyKaraktar(vec(6, 0, 0))
	S.spelare.Character = k2
	S.spelare.CharacterAdded:Fire(k2)
	check("e) efter respawn sitter hjälmen på den NYA kroppen",
		TackService.harHjalm(S.spelare) and TackRigg.hittaDel(k2, "hjalm") ~= nil)
	GameplayService.utrustning(S.spelare, "hjalm", false)
	local k3 = nyKaraktar(vec(6, 0, 0))
	S.spelare.Character = k3
	S.spelare.CharacterAdded:Fire(k3)
	check("   men inte om hon tagit av den", not TackService.harHjalm(S.spelare))
end

if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("\nutrustningsgrind.spec: alla gröna")
end
