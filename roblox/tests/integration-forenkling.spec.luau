--!nostrict
--[[
	FÖRENKLINGEN GENOM TJÄNSTEN — #273 SIMPLIFY, paket S2 och S3.

	Tobias beslut 2026-10-01 (T1, T2):

	  T2  en meningsfull spelarhandling per fas:
	      hälsa → kolla → rykta → kratsa → sadla → tränsa → leda → sitt upp.
	      Detaljtexterna är inga obligatoriska stopp. Säkerhets- och
	      välfärdsgrindarna står kvar.
	  T1  efter avsittningen ett enkelt val: «Stallet tar hand om henne»
	      (passet räknas, ingen straffavgift) eller «Ta hand om henne själv»
	      (frivilligt, liten positiv effekt). Fem obligatoriska klick är borta.

	Allt mäts genom `GameplayService`, mot den RIKTIGA riggen ur `HastRigg`
	— samma mätnivå som `integration.spec`. Inget anrop går direkt till
	`Preparation` eller `Pass` för att flytta tillståndet.

	VAD SOM MÄTS:

	  A  sex handlingar + två hämtningar ger EXAKT samma checklista som de
	     23 momentklicken: samma moment, spelaren som utförare, samma egen
	     andel, samma dagsform, och utrustningen fysiskt på hästen,
	  B  grindarna håller: fel tur, ohämtad utrustning, för långt bort,
	  C  fyndet stoppar kollen, blockerar allt annat, nekar fel svar och
	     nekar uppsittningen,
	  D  uppsittningsgrinden nekar som förut när något återstår,
	  E  «Stallet tar hand om henne»: passet räknas en gång, utrustningen tas
	     av på riktigt, relationen får grundtalet — ingen straffavgift,
	  F  «Ta hand om henne själv»: tre handlingar, samma kanoniska ordning,
	     liten extra relation,
	  G  valet kan inte räkna ett pass som aldrig reds.

	NOT TESTED: hur det KÄNNS. Det avgör Tobias i ett riktigt speltest.

	Kör: python3 roblox/tests/build.py tests/integration-forenkling.spec.luau
	     && luau roblox/tests/.build/integration-forenkling.spec.luau
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
local Taggar = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local function nyKaraktar(pos)
	local k = Instance.new("Model")
	k.Name = "Karaktar"
	local rot = Instance.new("Part")
	rot.Name = "HumanoidRootPart"
	rot.Size = vec(2, 2, 1)
	rot.CFrame = CFrame.new(pos)
	rot.Parent = k
	local hum = Instance.new("Humanoid")
	hum.Name = "Humanoid"
	hum.Parent = k
	local anim = Instance.new("Animator")
	anim.Name = "Animator"
	anim.Parent = hum
	return k, rot, hum
end

local function nySpelare(namn, userId, pos)
	local k, rot, hum = nyKaraktar(pos)
	local spelare = {
		Name = namn, UserId = userId, Character = k,
		CharacterAdded = __signal_ny(),
		CharacterRemoving = __signal_ny(),
	}
	return spelare, k, rot, hum
end

local function stall(spelare, pos)
	spelare.Character:FindFirstChild("HumanoidRootPart").CFrame = CFrame.new(pos)
end

local RIGG_LAGE = vec(0, 0, 0)

local function nySession(namn, userId, forbered)
	__datastore.nollstall()
	Taggar:nollstall()
	Players.PlayerAdded:nollstall()
	Players.PlayerRemoving:nollstall()
	RunService._server = true
	Players._spelare = {}
	SparService._glomHookarForProv()

	local spelare, karaktar, rot, hum = nySpelare(namn, userId, vec(6, 0, 0))
	SparService._glomForProv(spelare)
	if forbered then forbered(spelare) end

	SparService.start()
	StallService.start()
	HorseService.start()
	GameplayService.start()

	Players._spelare = { spelare }
	Players.PlayerAdded:Fire(spelare)
	Players.PlayerAdded:slutfor()

	local hastId = StallService.hastIdFor(spelare)
	local modell = nil
	if hastId then
		local h = (UBRFSpel.hastar or {})[hastId]
		modell = HastRigg.bygg(hastId, (h and h.namn) or hastId, CFrame.new(RIGG_LAGE))
		modell.Parent = workspace
		Taggar:AddTag(modell, "Horse")
	end
	return { spelare = spelare, karaktar = karaktar, rot = rot, hum = hum,
		hastId = hastId, modell = modell }
end

local function stadaSession(s)
	Players.PlayerRemoving:Fire(s.spelare)
	Players._spelare = {}
	SparService._glomForProv(s.spelare)
	RunService._server = false
end

--[[ Ledningen: samma drivning som `integration.spec` — tjänstens eget
	tillstånd avgör att hon lämnat boxen och nått zonen. ]]
local function ledTill(spelare)
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
	while true do
		local m = Preparation.nastaMoment(GameplayService.stateFor(spelare), "leda")
		if not m then break end
		if not GameplayService.moment(spelare, "leda", m.id) then break end
	end
end

--[[ DEN GAMLA VÄGEN: varje moment för sig, 23 anrop före ledningen. ]]
local function skotselMomentForMoment(spelare)
	local anrop = 0
	for _, fas in ipairs(Preparation.stegFaser()) do
		if fas.id == "leda" then
			ledTill(spelare)
		else
			if fas.id == "iordning" then
				local s0 = GameplayService.stateFor(spelare)
				GameplayService.valjUtrustning(spelare, "sadel", s0.hastId)
				GameplayService.valjUtrustning(spelare, "trans", s0.hastId)
			end
			while true do
				local m = Preparation.nastaMoment(GameplayService.stateFor(spelare), fas.id)
				if not m then break end
				local ok, skal = GameplayService.moment(spelare, fas.id, m.id)
				anrop += 1
				if not ok then return false, fas.id .. "/" .. m.id .. ": " .. tostring(skal), anrop end
			end
		end
	end
	return true, nil, anrop
end

--[[ DEN NYA VÄGEN: sex handlingar och två hämtningar. ]]
local HANDLINGAR = { "halsa", "kolla", "rykta", "kratsa", "sadla", "transa" }
local function skotselMedHandlingar(spelare)
	local anrop = 0
	for _, id in ipairs(HANDLINGAR) do
		if id == "sadla" then
			local s0 = GameplayService.stateFor(spelare)
			GameplayService.valjUtrustning(spelare, "sadel", s0.hastId)
			GameplayService.valjUtrustning(spelare, "trans", s0.hastId)
		end
		local ok, skal = GameplayService.handling(spelare, id)
		anrop += 1
		if not ok then return false, id .. ": " .. tostring(skal), anrop end
	end
	ledTill(spelare)
	return true, nil, anrop
end

--[[ Checklistan som en jämförbar sträng: fas/moment=utförare, sorterad. ]]
local function avtryck(s)
	local rader = {}
	for _, f in ipairs(Preparation.stegFaser()) do
		for _, m in ipairs(Preparation.moment(f.id)) do
			table.insert(rader, f.id .. "/" .. m.id .. "=" .. tostring((s.gjorda[f.id] or {})[m.id]))
		end
		table.insert(rader, f.id .. ":klar=" .. tostring(s.klara[f.id]))
	end
	return table.concat(rader, "\n"), #rader
end

--[[ ══ A: SEX HANDLINGAR GER SAMMA CHECKLISTA SOM 23 KLICK ════════════════ ]]
print("\n── A. Sex handlingar ger samma checklista som 23 momentklick ──")
local referens, referensDagsform, referensAndel
do
	local S = nySession("Moment", 9301)
	local ok, skal, anrop = skotselMomentForMoment(S.spelare)
	check("REFERENSEN: den gamla momentvägen går igenom", ok, tostring(skal))
	check("och den kostar 23 momentanrop före ledningen", anrop == 23, tostring(anrop))
	local s = GameplayService.stateFor(S.spelare)
	referens = avtryck(s)
	referensDagsform = GameplayService.dagsformFor(S.spelare)
	referensAndel = Preparation.egenAndel(s)
	check("referensen är klar att sitta upp på", (GameplayService.farSittaUpp(S.spelare, S.modell)) == true)
	stadaSession(S)
end
do
	local S = nySession("Handling", 9301)
	local ok, skal, anrop = skotselMedHandlingar(S.spelare)
	check("den nya vägen går igenom", ok, tostring(skal))
	check("och den kostar SEX handlingar före ledningen", anrop == 6, tostring(anrop))
	local s = GameplayService.stateFor(S.spelare)
	local nu, antal = avtryck(s)
	check("checklistan är IDENTISK med referensens — samma moment, spelaren som utförare",
		nu == referens and antal > 23, ("%d rader"):format(antal))
	check("egen andel är densamma (1,0 — allt gjort själv)",
		Preparation.egenAndel(s) == referensAndel and referensAndel == 1,
		tostring(Preparation.egenAndel(s)))
	check("dagsformen är densamma som de 23 klicken gav",
		math.abs(GameplayService.dagsformFor(S.spelare) - referensDagsform) < 1e-9,
		("%.4f mot %.4f"):format(GameplayService.dagsformFor(S.spelare), referensDagsform))
	check("utrustningen sitter FYSISKT på hästen",
		TackService.sadlad(S.modell) and TackService.transad(S.modell)
			and TackService.harTack(S.modell, "underlagg"))
	check("och uppsittningsgrinden släpper",
		(GameplayService.farSittaUpp(S.spelare, S.modell)) == true)
	check("uppsittningen går igenom", (HorseService.tryMount(S.spelare, S.modell)) == true)
	HorseService.dismount(S.spelare)
	stadaSession(S)
end

--[[ ══ B: GRINDARNA ═══════════════════════════════════════════════════════ ]]
print("\n── B. Grindarna håller: tur, hämtad utrustning, räckvidd ──")
do
	local S = nySession("Grind", 9302)
	local sp = S.spelare
	local ok1, skal1 = GameplayService.handling(sp, "rykta")
	check("«Rykta» före hälsningen nekas med fel tur", ok1 == false and skal1 == "forb.fel_tur", tostring(skal1))
	local okO, skalO = GameplayService.handling(sp, "finns_inte")
	check("en okänd handling nekas", okO == false and skalO == "forb.okant_moment", tostring(skalO))
	local okT, skalT = GameplayService.handling(sp, 17)
	check("ett argument som inte är en sträng nekas", okT == false and skalT == "spel.ogiltigt_steg", tostring(skalT))

	--[[ FÖR LÅNGT BORT. Samma närvarokrav som varje moment har. ]]
	stall(sp, vec(400, 0, 400))
	local okL, skalL = GameplayService.handling(sp, "halsa")
	check("från andra sidan gården nekas handlingen", okL == false and skalL == "spel.for_langt", tostring(skalL))
	check("och inget moment blev gjort",
		next(GameplayService.stateFor(sp).gjorda.halsa or {}) == nil)
	stall(sp, vec(6, 0, 0))

	check("hälsa går igenom", (GameplayService.handling(sp, "halsa")) == true)
	local okD, skalD = GameplayService.handling(sp, "halsa")
	check("en gång till: redan gjort", okD == false and skalD == "forb.redan_gjort", tostring(skalD))
	check("kolla går igenom", (GameplayService.handling(sp, "kolla")) == true)
	check("rykta går igenom", (GameplayService.handling(sp, "rykta")) == true)

	--[[ SADLA FÖRE HOVARNA. Ordningen inom fasen är kanonens. ]]
	local okS, skalS = GameplayService.handling(sp, "sadla")
	check("«Sadla» före hovarna nekas med fel tur", okS == false and skalS == "forb.fel_tur", tostring(skalS))
	check("kratsa går igenom", (GameplayService.handling(sp, "kratsa")) == true)

	--[[ UTRUSTNINGEN MÅSTE VARA HÄMTAD — en handling i världen, kvar. ]]
	local okU, skalU = GameplayService.handling(sp, "sadla")
	check("«Sadla» utan hämtad sadel nekas: hämta den först", okU == false and skalU == "tack.hamta_forst",
		tostring(skalU))
	local g = GameplayService.stateFor(sp).gjorda.iordning or {}
	check("och inget utrustningsmoment blev gjort, ingen sadel på hästen",
		g["utr:1"] == nil and not TackService.harTack(S.modell, "sadel")
			and not TackService.harTack(S.modell, "underlagg"))

	--[[ TRÄNSET FÖRE SADELN. ]]
	local okTr, skalTr = GameplayService.handling(sp, "transa")
	check("«Tränsa» före sadeln nekas med fel tur", okTr == false and skalTr == "forb.fel_tur", tostring(skalTr))

	--[[ FEL HÄSTS SADEL går fortfarande att ta — och nekas vid hästen. ]]
	local annan = nil
	for id in pairs(UBRFSpel.hastar or {}) do
		if id ~= S.hastId then annan = id break end
	end
	GameplayService.valjUtrustning(sp, "sadel", annan)
	local okF, skalF = GameplayService.handling(sp, "sadla")
	check("en ANNAN hästs sadel nekas vid hästen", okF == false and skalF ~= nil
		and not TackService.harTack(S.modell, "sadel"), tostring(skalF))

	GameplayService.valjUtrustning(sp, "sadel", S.hastId)
	local okR, skalR, argR = GameplayService.handling(sp, "sadla")
	check("med rätt sadel hämtad går «Sadla» igenom", okR == true, tostring(skalR))
	check("och kvittensen namnger delen och hästen", skalR == "tack.pa_plats" and type(argR) == "table"
		and type(argR.hast) == "string", tostring(skalR))
	check("sadeln och underlägget ligger på henne", TackService.sadlad(S.modell)
		and TackService.harTack(S.modell, "underlagg"))
	local okB, skalB = GameplayService.handling(sp, "transa")
	check("«Tränsa» utan hämtat träns nekas", okB == false and skalB == "tack.hamta_forst", tostring(skalB))
	GameplayService.valjUtrustning(sp, "trans", S.hastId)
	check("med tränset hämtat går den igenom", (GameplayService.handling(sp, "transa")) == true)

	--[[ D: UPPSITTNINGSGRINDEN — ledningen återstår, och den är fysisk. ]]
	local okM, skalM = GameplayService.farSittaUpp(sp, S.modell)
	check("uppsittningen nekas: ledningen återstår", okM == false and skalM == "pass.aterstar", tostring(skalM))
	check("och ingen handling kan kvittera ledningen",
		(GameplayService.handling(sp, "leda")) == false)
	stadaSession(S)
end

--[[ ══ C: FYNDET ══════════════════════════════════════════════════════════ ]]
print("\n── C. Fyndet stoppar kollen, och välfärdsstoppet står kvar ──")
do
	local FYND_ID = 9303
	local fyndHast = Stallet.tilldelaLedig(FYND_ID, {}, {})
	local fyndPass
	for p = 2, 40 do
		if Preparation.fyndFor(fyndHast, p) then fyndPass = p break end
	end
	check("det finns ett pass där hästen bär ett fynd", fyndHast ~= nil and fyndPass ~= nil,
		("%s, pass %s"):format(tostring(fyndHast), tostring(fyndPass)))
	local S = nySession("Fynd", FYND_ID, function(spelare)
		local befintlig = Sparning.tom()
		befintlig.pass = (fyndPass or 2) - 1
		befintlig.forstaDagen = { klar = true, hastId = Stallet.FORSTA_DAGEN_HAST }
		__datastore._data["spelare_" .. spelare.UserId] = Sparning.tillRad(befintlig)
	end)
	local sp = S.spelare
	local s = GameplayService.stateFor(sp)
	check("dagen bär ett fynd", s ~= nil and s.fynd ~= nil, s and tostring(s.fynd) or "-")
	check("hälsa går igenom", (GameplayService.handling(sp, "halsa")) == true)

	local okK, skalK = GameplayService.handling(sp, "kolla")
	check("«Kolla» går igenom och svarar att ett fynd står öppet",
		okK == true and skalK == "forb.oppet_fynd", tostring(skalK))
	check("fyndet är SETT men inte rapporterat", s.fyndSett == true and s.fyndRapporterat == false)
	--[[ Kollen STANNADE vid fyndet: punkterna efter den är inte gjorda. ]]
	local efterFynd, gjordaEfter = false, 0
	for _, m in ipairs(Preparation.moment("visitera")) do
		if efterFynd and (s.gjorda.visitera or {})[m.id] then gjordaEfter += 1 end
		if m.id == "vis:" .. s.fynd then efterFynd = true end
	end
	check("kollen stannade vid fyndet — inget moment efter det utfördes", gjordaEfter == 0,
		gjordaEfter .. " efter fyndet")
	check("visitationen är inte klar", s.klara.visitera ~= true)

	local okV, skalV = GameplayService.handling(sp, "rykta")
	check("ett öppet fynd blockerar nästa handling", okV == false and skalV == "forb.oppet_fynd", tostring(skalV))
	local okK2, skalK2 = GameplayService.handling(sp, "kolla")
	check("och kollen själv", okK2 == false and skalK2 == "forb.oppet_fynd", tostring(skalK2))
	local okRitt = HorseService.tryMount(sp, S.modell)
	check("och uppsittningen", okRitt == false)

	local fel, ratt = {}, nil
	for _, sv in ipairs(Preparation.fyndSvar()) do
		if sv.fel then table.insert(fel, sv) else ratt = sv end
	end
	local allaNekade = #fel == 2
	for _, sv in ipairs(fel) do
		local okF, skalF = GameplayService.svara(sp, sv.id)
		if okF ~= false or skalF ~= "forb.inte_ditt_beslut" then allaNekade = false end
	end
	check("de två felaktiga svaren nekas: inte ditt beslut", allaNekade)
	check("rätt svar går fram", (GameplayService.svara(sp, ratt.id)) == true)
	check("statusen är välfärdsstopp", GameplayService.statusFor(sp) == Preparation.STATUS.STOPPAD,
		tostring(GameplayService.statusFor(sp)))
	local okS, skalS = GameplayService.handling(sp, "rykta")
	check("efter stoppet nekas varje handling: ridläraren tar över",
		okS == false and skalS == "forb.lararen_tar_over", tostring(skalS))
	check("hästen går inte att rida", (HorseService.tryMount(sp, S.modell)) == false)
	stadaSession(S)
end

--[[ ══ E, F, G: EFTERVÅRDEN ═══════════════════════════════════════════════ ]]
local function relationFor(S)
	local save = SparService.save(S.spelare)
	return save and Sparning.hastminne(save, S.hastId).relation or -1, save
end

print("\n── E. «Stallet tar hand om henne»: passet räknas, ingen straffavgift ──")
do
	local S = nySession("Stallet", 9304)
	local sp = S.spelare
	check("skötseln går igenom", (skotselMedHandlingar(sp)) == true)

	--[[ G: före ritten och i sadeln går valet inte att använda. ]]
	local okF, skalF = GameplayService.eftervardStallet(sp)
	check("FÖRE ritten: stallet kan inte räkna ett pass som inte ridits",
		okF == false and skalF == "pass.inte_dags", tostring(skalF))
	check("uppsittningen går igenom", (HorseService.tryMount(sp, S.modell)) == true)
	local okR, skalR = GameplayService.eftervardStallet(sp)
	check("I SADELN: sitt av först", okR == false and skalR == "pass.sitt_av_forst", tostring(skalR))
	check("och passet är oräknat, utrustningen kvar",
		GameplayService.passFor(sp).lage == Pass.LAGE.RIDER and TackService.sadlad(S.modell))
	check("avsittningen går igenom", HorseService.dismount(sp) == true)
	check("passet väntar i eftervården", GameplayService.passFor(sp).lage == Pass.LAGE.EFTERVARD)

	--[[ STALLETS HAND KRÄVER INGEN NÄRVARO: hon får gå. ]]
	stall(sp, vec(400, 0, 400))
	local relFore = relationFor(S)
	local ok, skal = GameplayService.eftervardStallet(sp)
	check("«Stallet tar hand om henne» går igenom, även på avstånd",
		ok == true and skal == "eftervard.stallet_klar", tostring(skal))
	local p = GameplayService.passFor(sp)
	check("passet är RÄKNAT", p.lage == Pass.LAGE.RAKNAT, tostring(p.lage))
	local rel, save = relationFor(S)
	check("och räknat exakt en gång", save.pass == 1, tostring(save.pass))
	local alla = true
	for _, m in ipairs(Pass.moment()) do
		if p.gjorda[m.id] ~= "auto" then alla = false end
	end
	check("alla fem moment står som STALLETS, inte spelarens", alla and Pass.egenAndel(p) == 0)
	check("utrustningen är av på riktigt: ingen sadel, inget underlägg, inget träns",
		not TackService.harTack(S.modell, "sadel") and not TackService.harTack(S.modell, "underlagg")
			and not TackService.harTack(S.modell, "trans") and not TackService.harTack(S.modell, "tygel"))
	check("relationen fick grundtalet 0,04 — ingen straffavgift för att låta stallet göra det",
		math.abs((rel - relFore) - 0.04) < 1e-9, ("%.4f"):format(rel - relFore))
	local ok2, skal2 = GameplayService.eftervardStallet(sp)
	check("en gång till ger inget andra pass", ok2 == false and save.pass == 1, tostring(skal2))
	stadaSession(S)
end

print("\n── F. «Ta hand om henne själv»: tre handlingar, liten extra relation ──")
do
	local S = nySession("Sjalv", 9305)
	local sp = S.spelare
	check("skötseln går igenom", (skotselMedHandlingar(sp)) == true)
	check("uppsittningen går igenom", (HorseService.tryMount(sp, S.modell)) == true)
	check("avsittningen går igenom", HorseService.dismount(sp) == true)

	local h = Pass.handlingar()
	check("eftervården är tre handlingar: ta av sadeln, ta av tränset, vatten och hö",
		#h == 3 and h[1].id == "sadla_av" and h[2].id == "transa_av" and h[3].id == "ta_hand",
		#h .. " st")
	local antal = 0
	for _, x in ipairs(h) do antal += #x.moment end
	check("och de bär kanonens fem moment, inget tappat", antal == #Pass.moment() and antal == 5, tostring(antal))

	--[[ ORDNINGEN: sadeln av innan tränset — kanon, och `TackService`. ]]
	local okT, skalT = GameplayService.eftervardHandling(sp, "transa_av")
	check("tränset före sadeln nekas med fel tur", okT == false and skalT == "pass.fel_tur", tostring(skalT))
	check("och tränset sitter kvar", TackService.transad(S.modell))

	--[[ NÄRVARON: man tar av sadeln vid hästen. ]]
	stall(sp, vec(400, 0, 400))
	local okL, skalL = GameplayService.eftervardHandling(sp, "sadla_av")
	check("från andra sidan gården nekas den egna eftervården", okL == false and skalL == "spel.for_langt",
		tostring(skalL))
	check("och sadeln ligger kvar", TackService.sadlad(S.modell))
	local rot = S.modell.PrimaryPart.Position
	stall(sp, rot + vec(4, 0, 0))

	local relFore = relationFor(S)
	check("«Ta av sadeln» går igenom", (GameplayService.eftervardHandling(sp, "sadla_av")) == true)
	check("sadeln och underlägget är av, tränset sitter kvar",
		not TackService.harTack(S.modell, "sadel") and not TackService.harTack(S.modell, "underlagg")
			and TackService.transad(S.modell))
	local okIgen, skalIgen = GameplayService.eftervardHandling(sp, "sadla_av")
	check("«Ta av sadeln» en gång till: redan gjort, inget kvitteras", okIgen == false
		and skalIgen == "pass.redan_gjort", tostring(skalIgen))
	check("eftervården har börjat: hon sitter inte upp igen",
		(Pass.farSittaUpp(GameplayService.passFor(sp))) == false)
	check("«Ta av tränset» går igenom", (GameplayService.eftervardHandling(sp, "transa_av")) == true)
	check("tränset och tyglarna är av",
		not TackService.harTack(S.modell, "trans") and not TackService.harTack(S.modell, "tygel"))
	check("passet är ännu inte räknat", GameplayService.passFor(sp).lage == Pass.LAGE.EFTERVARD)
	check("«Vatten och hö» går igenom", (GameplayService.eftervardHandling(sp, "ta_hand")) == true)

	local p = GameplayService.passFor(sp)
	local rel, save = relationFor(S)
	check("passet är räknat en gång", p.lage == Pass.LAGE.RAKNAT and save.pass == 1, tostring(p.lage))
	check("alla fem moment är spelarens egna", Pass.egenAndel(p) == 1)
	check("relationen fick grundtalet plus den lilla egna bonusen: 0,06",
		math.abs((rel - relFore) - 0.06) < 1e-9, ("%.4f"):format(rel - relFore))
	stadaSession(S)
end

print("\n── F2. Börja själv, låt stallet göra resten ──")
do
	local S = nySession("Blandat", 9306)
	local sp = S.spelare
	check("skötseln går igenom", (skotselMedHandlingar(sp)) == true)
	HorseService.tryMount(sp, S.modell)
	HorseService.dismount(sp)
	stall(sp, S.modell.PrimaryPart.Position + vec(4, 0, 0))
	local relFore = relationFor(S)
	check("«Ta av sadeln» själv", (GameplayService.eftervardHandling(sp, "sadla_av")) == true)
	check("sedan stallet", (GameplayService.eftervardStallet(sp)) == true)
	local p = GameplayService.passFor(sp)
	local rel, save = relationFor(S)
	check("passet är räknat en gång", p.lage == Pass.LAGE.RAKNAT and save.pass == 1)
	check("två av fem moment är hennes egna", math.abs(Pass.egenAndel(p) - 0.4) < 1e-9,
		tostring(Pass.egenAndel(p)))
	check("bonusen följer andelen: 0,04 + 0,02 × 0,4", math.abs((rel - relFore) - 0.048) < 1e-9,
		("%.4f"):format(rel - relFore))
	check("hästen är avtacklad", not TackService.harTack(S.modell, "sadel")
		and not TackService.harTack(S.modell, "trans"))
	stadaSession(S)
end

print("")
if fails > 0 then
	print(fails .. " FEL")
	error(fails .. " fel")
end
print("integration-forenkling.spec: alla gröna")
