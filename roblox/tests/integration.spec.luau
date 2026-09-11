--!nostrict
--[[
	INTEGRATIONSGRINDEN — END_TO_END_PLAYABILITY_GATE punkt 7-11 (#162).

	Skillnaden mot `skotselpass.spec` och `forberedelse.spec` är VAD kedjan
	mäts MOT. De två mäter reglerna: Preparation, Pass, Sparning och
	tjänsternas beslut. Den här filen bygger den RIKTIGA riggen ur
	`HastRigg` — med en riktig `Seat` — och kör dagen genom tjänsterna mot
	just den modellen:

	    tilldelning → bindning → visitera → rykta → hovar → utrustning
	      → leda → uppsittning → en ryttarbildruta → avsittning
	      → eftervård → passet räknat en gång → sparat och laddat igen

	SKÄLET till att filen finns står i #162: Tobias fick hitta felen
	fysiskt i Studio. En place utan häst gick genom min egen grind, och
	uppsittningen kunde krascha på första bildrutan med varje regel grön.
	Det som saknades var inte fler regler utan en mätning av UTFÖRANDET.

	Mätverktygen kom med den här grinden och hör till evidensen: stubbarna
	hade ingen `Seat:Sit`, ingen `Humanoid.Died`, ingen
	`GetPropertyChangedSignal` och inga taggsignaler som fyrar. Utan dem
	har hela uppsittnings- och städningskedjan varit omätbar utanför
	Studio — vilket är precis varför den kunde vara trasig.

	NOT TESTED, uttryckligen: fysik, animationer, IK, kamera, verklig
	nätverkslatens och Studio-känsla. Riggen är HastRiggs platshållare, inte
	en modellerad häst. Grinden säger att KEDJAN går att spela igenom, inte
	att den känns rätt — det avgör Tobias i Studio.

	Kör: python3 roblox/tests/build.py tests/integration.spec.luau
	     && luau roblox/tests/.build/integration.spec.luau
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

--[[ ── EN SPELARE MED KROPP ─────────────────────────────────────────────
	Karaktären är en riktig (stubbad) Model med `HumanoidRootPart` och
	`Humanoid`, för det är vad tjänsterna läser: avståndet mäts från roten,
	sitsen tar humanoiden, och städningen hänger på `Humanoid.Died` och
	`Player.CharacterRemoving`. Läget sätts genom CFrame — `Position`
	härleds ur den, precis som på en riktig BasePart. ]]
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

--[[ Flyttar spelaren. Ett eget anrop för att avståndsproven ska läsa som
	det de är: hon GÅR någon annanstans, hon får ingen ny kropp. ]]
local function stall(spelare, pos)
	spelare.Character:FindFirstChild("HumanoidRootPart").CFrame = CFrame.new(pos)
end

--[[ ── EN VÄRLD MED EN HÄST ─────────────────────────────────────────────
	Startar tjänsterna i produktionens ordning, släpper in spelaren genom
	`PlayerAdded` (samma väg som init.server), läser vilken häst stallet
	gav och bygger riggen för DEN hästen. Taggen sätts sist, och därför går
	registreringen och bindningen genom produktionens taggsignal. ]]
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
	return {
		spelare = spelare, karaktar = karaktar, rot = rot, hum = hum,
		hastId = hastId, modell = modell,
	}
end

local function stadaSession(s)
	Players.PlayerRemoving:Fire(s.spelare)
	Players._spelare = {}
	SparService._glomForProv(s.spelare)
	RunService._server = false
end

--[[ Hela skötseln genom TJÄNSTEN, moment för moment. Inget anrop går
	direkt till `Preparation`: det är skillnaden mot forberedelse.spec. ]]
local function skotselGenomTjansten(spelare)
	for _, fas in ipairs(Preparation.stegFaser()) do
		--[[ `leda` KRÄVER numera att hästen faktiskt har letts dit (#162
			blockerare 2). Den här specen driver därför den riktiga
			ledningen i stället för att kvittera steget: den börjar leda,
			flyttar SPELAREN mot ridbanan och låter `LedService._steg`
			köra tjänstens egen följlogik. Hästen flyttas aldrig direkt —
			det är hela skillnaden mot den gamla versionen. ]]
		--[[ `leda` KRÄVER numera att hästen fysiskt letts till ridbanan
			(#162 blockerare 2). Den här specen mäter INTE följfysiken —
			den hör hemma i `ledning.spec` och i Studio-runtime. Här drivs
			tjänstens tillstånd: ledningen startas, hästen ställs där
			fysiken hade fört henne, och `LedService._steg` får SJÄLV
			avgöra att hon lämnat boxen och nått zonen. Specen sätter
			aldrig flaggorna. ]]
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
		--[[ UTRUSTNINGEN HÄMTAS FÖRST, som på webben (`sysslor.js:239`).
			Sedan blockerare 5 vägrar `GameplayService.moment` ett
			`utr:`-steg utan hämtad utrustning, och det är avsiktligt: utan
			kravet tas hästens egen sadel tyst och felvalet blir omöjligt
			att göra. I spelet gör spelaren det här vid boxfronten
			(`TackForradService`); här drivs samma väg genom tjänsten. ]]
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
			if not ok then
				return false, string.format("%s/%s: %s", fas.id, m.id, tostring(skal))
			end
		end
	end
	return true, nil
end

--[[ ══ PUNKT 7: SKÖTSELKEDJAN MOT DEN RIKTIGA RIGGEN ═══════════════════ ]]
print("\n── Punkt 7: skötselkedjan mot riggen i världen ──")
do
	local S = nySession("Kedja", 9201)
	check("stallet gav en häst och det är första dagens",
		S.hastId == Stallet.FORSTA_DAGEN_HAST,
		string.format("%s (väntat %s)", tostring(S.hastId), tostring(Stallet.FORSTA_DAGEN_HAST)))
	check("riggen är byggd med rätt identitet och en riktig sits",
		S.modell ~= nil and S.modell:GetAttribute("HorseId") == S.hastId
			and S.modell:FindFirstChild("RiderSeat") ~= nil
			and S.modell:FindFirstChild("RiderSeat").ClassName == "Seat",
		S.modell and tostring(S.modell:GetAttribute("HorseId")) or "ingen modell")

	--[[ Taggen — inte provkroken — registrerade hästen och band spelaren.
		Det är produktionens väg för en rigg som dyker upp efter start. ]]
	check("taggsignalen registrerade hästen i HorseService",
		HorseService.sessionFor(S.modell) ~= nil)
	check("och band spelarens identitet till modellen i världen",
		GameplayService.modellFor(S.spelare) == S.modell,
		"status " .. tostring(GameplayService.statusFor(S.spelare)))

	local ok, skal = skotselGenomTjansten(S.spelare)
	check("hela skötseln går igenom tjänsten mot riggen", ok, tostring(skal))
	check("och statusen är REDO att sitta upp",
		GameplayService.statusFor(S.spelare) == Preparation.STATUS.REDO,
		tostring(GameplayService.statusFor(S.spelare)))
	stadaSession(S)
end

--[[ ══ PUNKT 8: NEJEN I INTEGRATIONSLÄGE ══════════════════════════════

	Reglerna är provade i `forberedelse.spec` och `skotselpass.spec`. Det
	som INTE var provat är att de gäller när anropet går genom tjänsten mot
	en riktig rigg i världen: fel häst, för långt bort, fel ordning,
	dubbeltryck, uppsittning för tidigt och välfärdsstopp.

	Ett nej ska dessutom komma med SITT skäl. Ett "nej" av fel orsak är en
	spärr som råkar hålla, och den kan sluta hålla utan att något prov
	märker det. ]]
print("\n── Punkt 8: nejen mot riggen, genom tjänsten ──")
do
	local S = nySession("Nej", 9202)

	--[[ a) UPPSITTNING FÖR TIDIGT. Ingen skötsel gjord alls. ]]
	local ok, skal = HorseService.tryMount(S.spelare, S.modell)
	check("a) uppsittning innan skötseln nekas", ok == false, tostring(skal))
	check("   och sitsen är tom efteråt",
		S.modell:FindFirstChild("RiderSeat").Occupant == nil
			and HorseService.horseOf(S.spelare) == nil)

	--[[ b) FÖR LÅNGT BORT. Hon går 40 studs bort — samma häst, samma
		skötsel, bara avståndet skiljer. ]]
	local forstaFas = Preparation.stegFaser()[1]
	local forstaMoment = Preparation.nastaMoment(GameplayService.stateFor(S.spelare), forstaFas.id)
	stall(S.spelare, vec(40, 0, 0))
	local okAvst, skalAvst = GameplayService.moment(S.spelare, forstaFas.id, forstaMoment.id)
	check("b) ett skötselmoment på 40 studs avstånd nekas", okAvst == false, tostring(skalAvst))
	--[[ Nejet är en SPRÅKNYCKEL sedan lokaliseringen (#162): servern skickar
		aldrig svensk prosa över nätet. Provet mäter nyckeln, och att den
		finns i katalogen — en nyckel som inte gör det visas som sin egen
		text för spelaren. ]]
	check("   och nejet handlar om avståndet, inte något annat",
		skalAvst == "spel.for_langt" and Sprak.finns(skalAvst), tostring(skalAvst))
	local okMont, skalMont = HorseService.tryMount(S.spelare, S.modell)
	check("   uppsittning på samma avstånd nekas också", okMont == false, tostring(skalMont))

	--[[ …och när hon går tillbaka går samma moment igenom. Utan den här
		raden vore avståndsspärren omöjlig att skilja från en spärr som
		alltid säger nej. ]]
	stall(S.spelare, vec(6, 0, 0))
	local okNara = GameplayService.moment(S.spelare, forstaFas.id, forstaMoment.id)
	check("   men går igenom när hon står vid hästen igen", okNara == true)

	--[[ c) FEL ORDNING. Ett moment ur en SENARE fas innan de tidigare är
		klara. Fasen räknas fram ur kanonen, inte skrivs av. ]]
	local faser = Preparation.stegFaser()
	local sen = faser[#faser]
	local senMoment = Preparation.moment(sen.id)[1]
	local okOrd, skalOrd = GameplayService.moment(S.spelare, sen.id, senMoment.id)
	check("c) ett moment ur sista fasen nekas innan de tidigare är klara",
		okOrd == false, string.format("%s/%s: %s", sen.id, senMoment.id, tostring(skalOrd)))

	--[[ d) DUBBELTRYCK. Samma moment igen, direkt. ]]
	local okDubbel, skalDubbel = GameplayService.moment(S.spelare, forstaFas.id, forstaMoment.id)
	check("d) samma moment en andra gång nekas", okDubbel == false, tostring(skalDubbel))

	--[[ e) FEL HÄST. En andra rigg med en annan kanonisk identitet står
		på gården. Den får varken bli spelarens bundna modell eller gå att
		sitta upp på. ]]
	local annanId
	for id in pairs(UBRFSpel.hastar) do
		if id ~= S.hastId then annanId = id break end
	end
	local annan = HastRigg.bygg(annanId, tostring(annanId), CFrame.new(vec(3, 0, 0)))
	annan.Parent = workspace
	Taggar:AddTag(annan, "Horse")
	check("e) den andra hästen registreras också", HorseService.sessionFor(annan) ~= nil,
		tostring(annanId))
	check("   men spelarens bundna modell är fortfarande hennes egen",
		GameplayService.modellFor(S.spelare) == S.modell)
	local okFel, skalFel = HorseService.tryMount(S.spelare, annan)
	check("   och uppsittning på fel häst nekas", okFel == false, tostring(skalFel))
	Taggar:RemoveTag(annan, "Horse")
	annan:Destroy()
	stadaSession(S)
end

--[[ ══ g) UTRUSTNINGEN SOM INTE ÄR HÄMTAD ═════════════════════════════

	Blockerare 5, och den mätning som gör felutrustningen SPELBAR i stället
	för bara implementerad.

	Webben vägrar öppna "visitera, rykta, kratsa, sadla" utan `G.utrustning`
	(`sysslor.js:239`): hästens sadel hänger på sin egen plats och man måste
	gå och hämta den. Roblox gör nu samma sak, och kravet är inte kosmetik —
	fölle det bort skulle `TackService.satPa` tyst få spelarens egen häst som
	ägare, och då går felvalet INTE att göra. Hela webbens pedagogik ligger i
	att det går.

	Kedjan som mäts: hämta först → rätt utrustning på → fel hästs sadel nekad
	med webbens skäl och räknad som `G.felUtrustning`. ]]
print("")
print("── Punkt 8g: utrustningen måste hämtas, och kan hämtas fel ──")
do
	local S = nySession("Utrustning", 9203)
	stall(S.spelare, vec(6, 0, 0))
	for _, fas in ipairs(Preparation.stegFaser()) do
		if fas.id == "iordning" then break end
		while true do
			local m = Preparation.nastaMoment(GameplayService.stateFor(S.spelare), fas.id)
			if not m then break end
			if not GameplayService.moment(S.spelare, fas.id, m.id) then break end
		end
	end
	--[[ HOVARNA FÖRST. `iordning` börjar med fyra `hov:`-moment och först
		därefter kommer `utr:`-stegen — sadeln läggs inte på innan man
		krupit under henne. Kravet på hämtad utrustning gäller bara
		`utr:`-stegen, så hovarna ska gå igenom UTAN någon utrustning alls;
		gör de inte det sitter spärren på fel moment. ]]
	local hovar = 0
	while true do
		local m = Preparation.nastaMoment(GameplayService.stateFor(S.spelare), "iordning")
		if not m or m.id:match("^utr:") then break end
		if not GameplayService.moment(S.spelare, "iordning", m.id) then break end
		hovar += 1
	end
	check("hovarna går igenom utan utrustning — spärren sitter på utr:",
		hovar == #UBRFSkotsel.hovar, ("%d av %d"):format(hovar, #UBRFSkotsel.hovar))

	local forsta = Preparation.nastaMoment(GameplayService.stateFor(S.spelare), "iordning")
	check("och utrustningssteget står på tur", forsta ~= nil and forsta.id == "utr:1",
		forsta and forsta.id or "inget moment")

	local okU, skalU = GameplayService.moment(S.spelare, "iordning", forsta.id)
	check("g) att sadla utan hämtad utrustning nekas", okU == false, tostring(skalU))
	check("   och nejet säger just det, på en nyckel som finns",
		skalU == "tack.hamta_forst" and Sprak.finns(skalU), tostring(skalU))
	check("   och ingenting ligger på hästen",
		TackService.harTack(S.modell, "underlagg") == false)

	--[[ Hämtad — det här är vad prompten på boxfronten gör. ]]
	GameplayService.valjUtrustning(S.spelare, "sadel", S.hastId)
	GameplayService.valjUtrustning(S.spelare, "trans", S.hastId)
	local okU2, skalU2 = GameplayService.moment(S.spelare, "iordning", forsta.id)
	check("   men går igenom när utrustningen är hämtad", okU2 == true, tostring(skalU2))
	check("   och underlägget ligger nu FYSISKT på henne",
		TackService.harTack(S.modell, "underlagg") == true)

	--[[ FEL HÄSTS SADEL — hämtad vid grannens boxfront. ]]
	local grannId
	for _, id in ipairs(UBRFSpel.ordning) do
		if id ~= S.hastId then grannId = id break end
	end
	local fore = TackService.felAntal(S.spelare)
	GameplayService.valjUtrustning(S.spelare, "sadel", grannId)
	local sadelMoment = Preparation.nastaMoment(GameplayService.stateFor(S.spelare), "iordning")
	local okF, skalF = GameplayService.moment(S.spelare, "iordning", sadelMoment.id)
	check("   grannens sadel nekas", okF == false, tostring(skalF))
	check("   med webbens skäl: den är formad efter en annan rygg",
		skalF == "tack.fel_sadel" and Sprak.finns(skalF), tostring(skalF))
	check("   felet RÄKNAS, som G.felUtrustning",
		TackService.felAntal(S.spelare) == fore + 1,
		("%d -> %d"):format(fore, TackService.felAntal(S.spelare)))
	check("   och ingen sadel ligger på hästen",
		TackService.harTack(S.modell, "sadel") == false)

	GameplayService.valjUtrustning(S.spelare, "sadel", S.hastId)
	local okR = GameplayService.moment(S.spelare, "iordning", sadelMoment.id)
	check("   rätt sadel går på", okR == true)
	check("   och ligger då FYSISKT på henne",
		TackService.harTack(S.modell, "sadel") == true)
	stadaSession(S)
end

--[[ f) VÄLFÄRDSSTOPPET, hela vägen genom tjänsten. Fyndet kommer ur
	`Preparation.fyndFor` och finns bara från pass 2; sessionen förbereds
	därför med en sparfil som har pass bakom sig. ]]
print("\n── Punkt 8f: fyndet stoppar arbetet och ritten ──")
do
	--[[ Fyndet är DETERMINISTISKT ur häst och passnummer (`fyndFor`), och
		första passet är fritt. Provet får därför inte skriva ett passnummer
		på måfå: det räknar först fram vilken häst stallet ger just den här
		userId:t när första dagen är avklarad, och sedan ETT passnummer där
		den hästen faktiskt bär ett fynd. Skrevs talet av för hand vore
		provet grönt eller rött beroende på hästdatan, inte på koden. ]]
	local FYND_ID = 9203
	local fyndHast = Stallet.tilldelaLedig(FYND_ID, {}, {})
	local fyndPass
	for p = 2, 40 do
		if Preparation.fyndFor(fyndHast, p) then fyndPass = p break end
	end
	check("det finns ett passnummer där hästen bär ett fynd",
		fyndHast ~= nil and fyndPass ~= nil,
		string.format("%s, pass %s", tostring(fyndHast), tostring(fyndPass)))

	local S = nySession("Fynd", FYND_ID, function(spelare)
		local befintlig = Sparning.tom()
		--[[ `aktuelltPass` är sparade pass + 1, så dagen som BÖRJAR blir
			`fyndPass` när lagret bär ett mindre. ]]
		befintlig.pass = (fyndPass or 2) - 1
		befintlig.forstaDagen = { klar = true, hastId = Stallet.FORSTA_DAGEN_HAST }
		__datastore._data["spelare_" .. spelare.UserId] = Sparning.tillRad(befintlig)
	end)
	check("och stallet gav just den hästen", S.hastId == fyndHast,
		string.format("%s (väntat %s)", tostring(S.hastId), tostring(fyndHast)))
	local s = GameplayService.stateFor(S.spelare)
	check("dagen bär ett fynd att hitta", s ~= nil and s.fynd ~= nil,
		s and tostring(s.fynd) or "ingen state")

	--[[ Visitationen fram till fyndet, genom tjänsten. ]]
	local visitera
	for _, f in ipairs(Preparation.stegFaser()) do
		if f.id == "visitera" then visitera = f end
	end
	check("visitationen finns som fas i kanonen", visitera ~= nil)

	--[[ Hälsningen först. Visitationen står inte på tur förrän man har
		hälsat, och att hoppa över den hade mätt turordningen igen i
		stället för fyndet. ]]
	local halsa = Preparation.stegFaser()[1]
	while true do
		local m = Preparation.nastaMoment(GameplayService.stateFor(S.spelare), halsa.id)
		if not m then break end
		local okH = GameplayService.moment(S.spelare, halsa.id, m.id)
		if not okH then break end
	end
	check("hälsningen är gjord, så visitationen står på tur",
		Preparation.fasKlar(GameplayService.stateFor(S.spelare), halsa.id) == true)

	local hittade = false
	for _, m in ipairs(Preparation.moment(visitera.id)) do
		local okM = GameplayService.moment(S.spelare, visitera.id, m.id)
		if m.id == "vis:" .. tostring(s.fynd) then hittade = okM == true break end
	end
	check("fyndmomentet gick att utföra", hittade == true)
	check("och fyndet är SETT men inte rapporterat",
		s.fyndSett == true and s.fyndRapporterat == false)

	--[[ Ett obesvarat fynd blockerar allt annat arbete OCH ritten. ]]
	local nastaFas
	for _, f in ipairs(Preparation.stegFaser()) do
		if f.id ~= "halsa" and f.id ~= "visitera" then nastaFas = f break end
	end
	local okBlock, skalBlock = GameplayService.moment(S.spelare, nastaFas.id,
		Preparation.moment(nastaFas.id)[1].id)
	check("ett obesvarat fynd blockerar nästa fas", okBlock == false, tostring(skalBlock))
	local okRitt, skalRitt = HorseService.tryMount(S.spelare, S.modell)
	check("och uppsittningen", okRitt == false, tostring(skalRitt))

	--[[ Rätt svar — det som INTE är märkt som fel — stoppar arbetet. ]]
	local ratt
	for _, sv in ipairs(Preparation.fyndSvar()) do
		if not sv.fel then ratt = sv break end
	end
	local okSvar, skalSvar = GameplayService.svara(S.spelare, ratt.id)
	check("rätt svar på fyndet går fram", okSvar == true, tostring(skalSvar))
	check("och statusen är välfärdsstopp, inte 'förbereder'",
		GameplayService.statusFor(S.spelare) == Preparation.STATUS.STOPPAD,
		tostring(GameplayService.statusFor(S.spelare)))
	local okEfter, skalEfter = HorseService.tryMount(S.spelare, S.modell)
	check("hästen går inte att rida efter ett välfärdsstopp", okEfter == false,
		tostring(skalEfter))
	check("sitsen är tom", S.modell:FindFirstChild("RiderSeat").Occupant == nil)
	stadaSession(S)
end

--[[ ══ PUNKT 9: UPPSITTNING, EN RIDBILDRUTA, AVSITTNING ════════════════

	Det här är den mätning som saknades när `RigAdapter.setRiderLean` skrev
	på `seat.C0`: koden gick att kalla, regeln var grön, och första
	ridbildrutan mot en riktig rigg hade kastat. Här körs den mot HastRiggs
	rigg med sitsen HorseService faktiskt sitter i. ]]
print("\n── Punkt 9: uppsittning → en ridbildruta → avsittning ──")
do
	local S = nySession("Ritt", 9204)
	local ok, skal = skotselGenomTjansten(S.spelare)
	check("skötseln är gjord", ok, tostring(skal))

	local session = HorseService.sessionFor(S.modell)
	local rig = session and session.rig
	check("riggen som tjänsten registrerade har sits OCH ryttarled",
		rig ~= nil and rig.seat ~= nil and rig.riderJoint ~= nil,
		rig and string.format("sits %s · led %s", tostring(rig.seat and rig.seat.ClassName),
			tostring(rig.riderJoint and rig.riderJoint.ClassName)) or "ingen rigg")
	--[[ Kontraktet ur HORSE-MODEL-SPEC: lutningen får ALDRIG ligga på
		sitsen. En `Seat` har ingen `C0`, och den dagen någon lägger den
		där igen ska den här raden falla. ]]
	check("sitsen är en Seat utan C0 — lutningen hör inte där",
		rig.seat.ClassName == "Seat" and rig.seat.C0 == nil)
	--[[ Namnet `SeatWeld` är Roblox eget: sitsen skapar en sådan när någon
		sätter sig, och avsittningen letar just den. Bär riggen ett EGET
		objekt med samma namn kan avsittningen få tag i den bärande
		svetsen. Före uppsittningen ska namnet därför inte finnas alls. ]]
	local fore = rig.seat:FindFirstChild("SeatWeld")
	check("riggen bär inget eget SeatWeld — namnet är Roblox eget",
		fore == nil, fore and fore:GetFullName() or "inget")

	local okM, skalM = HorseService.tryMount(S.spelare, S.modell)
	check("uppsittningen går igenom", okM == true, tostring(skalM))
	check("och sitsen bär FAKTISKT spelarens humanoid",
		rig.seat.Occupant == S.hum, tostring(rig.seat.Occupant and "occupant satt"))
	check("servern vet att hon rider hästen",
		HorseService.horseOf(S.spelare) == S.modell
			and GameplayService.statusFor(S.spelare) == Preparation.STATUS.RIDER,
		tostring(GameplayService.statusFor(S.spelare)))
	check("men efter uppsittningen finns sitsens egen SeatWeld",
		rig.seat:FindFirstChild("SeatWeld") ~= nil)
	check("passet gick in i ridläget genom produktionens egen krok",
		GameplayService.passFor(S.spelare).lage == Pass.LAGE.RIDER,
		tostring(GameplayService.passFor(S.spelare).lage))

	--[[ EN RIKTIG RIDBILDRUTA. Ryttarkontrollern får riggen tjänsten
		byggde, kopplas till karaktären och stegas — det anrop som hade
		kastat mot en riktig Seat. ]]
	local rc = RiderController.new(rig)
	rc:attach(S.karaktar)
	local fore = rig.riderJoint.C0
	local okSteg = pcall(function()
		--[[ Två bildrutor: tröghetsutslaget kommer ur tempoDERIVATAN, så
			en enda bildruta ger noll oavsett fart. ]]
		rc:step({ speed = 0, lean = 0, gait = "walk", phase = 0, heading = 0,
			turnRate = 0, grounded = true, airborne = false }, 1 / 60)
		rc:step({ speed = 3.5, lean = 0.4, gait = "trot", phase = 0.5, heading = 0,
			turnRate = 0.2, grounded = true, airborne = false }, 1 / 60)
	end)
	check("en ridbildruta går att köra mot riggen utan att kasta", okSteg == true)
	check("och ryttarlutningen hamnade på ryttarleden, inte på sitsen",
		rig.riderJoint.C0 ~= nil and rig.riderJoint.C0 ~= fore
			and math.abs(rig.riderJoint.C0.Roll or 0) > 1e-6,
		string.format("roll %.4f · pitch %.4f", rig.riderJoint.C0.Roll or 0,
			rig.riderJoint.C0.Pitch or 0))
	check("sitsen har fortfarande ingen C0 efter bildrutan", rig.seat.C0 == nil)
	rc:release()

	local okAv = HorseService.dismount(S.spelare)
	check("avsittningen går igenom", okAv == true)
	check("sitsen är släppt och ingen spökryttare finns kvar",
		rig.seat.Occupant == nil and HorseService.horseOf(S.spelare) == nil
			and S.hum.Sit == false)
	check("och passet gick vidare till eftervården",
		GameplayService.passFor(S.spelare).lage == Pass.LAGE.EFTERVARD,
		tostring(GameplayService.passFor(S.spelare).lage))
	stadaSession(S)
end

--[[ ══ PUNKT 10: DÖD, RESPAWN OCH NY UPPSITTNING ═══════════════════════

	Städningskoden finns sedan blockerare 3, men ingen körning har rört
	den: stubbarna hade ingen `Humanoid.Died` och ingen Occupant-signal.
	Det som mäts är att servern inte lämnar en spökryttare — och att
	spelaren kan sitta upp IGEN efteråt, vilket är det spelaren märker. ]]
print("\n── Punkt 10: döden och respawnen lämnar ingen spökryttare ──")
do
	local S = nySession("Dod", 9205)
	local ok = skotselGenomTjansten(S.spelare)
	check("skötseln är gjord", ok == true)
	local rig = HorseService.sessionFor(S.modell).rig
	check("hon sitter upp", (HorseService.tryMount(S.spelare, S.modell)) == true)

	--[[ DÖDEN. `Health = 0` fyrar `Died` precis som i Roblox. ]]
	S.hum.Health = 0
	check("döden släppte sitsen", rig.seat.Occupant == nil)
	check("och servern räknar henne inte längre som ryttare",
		HorseService.horseOf(S.spelare) == nil)
	check("hästen är ledig för nästa uppsittning",
		HorseService.sessionFor(S.modell).rider == nil)

	--[[ RESPAWN: en ny kropp, samma spelare. Produktionen binder om på
		`CharacterAdded`, så signalen fyras — inte bara fältet sätts. ]]
	local k2, _, hum2 = nyKaraktar(vec(6, 0, 0))
	S.spelare.Character = k2
	S.spelare.CharacterAdded:Fire(k2)
	S.karaktar, S.hum = k2, hum2
	--[[ Hästen står numera i RIDHUSET, dit hon leddes — inte kvar i sin
		box. En spelare som respawnar går fram till henne igen, och det är
		det den här raden gör. Utan den mäter specen bara att `tryMount`
		nekar på avstånd, vilket den redan har ett eget prov för. ]]
	do
		local r2 = k2:FindFirstChild("HumanoidRootPart")
		local pivot = S.modell.PrimaryPart
		if r2 and pivot then
			r2.CFrame = CFrame.new(pivot.Position.X + 4, r2.Position.Y, pivot.Position.Z)
		end
	end
	check("skötseln räknas fortfarande som gjord efter respawnen",
		GameplayService.statusFor(S.spelare) == Preparation.STATUS.REDO,
		tostring(GameplayService.statusFor(S.spelare)))
	local okOm, skalOm = HorseService.tryMount(S.spelare, S.modell)
	check("och hon kan sitta upp igen", okOm == true, tostring(skalOm))
	check("med den NYA kroppen i sitsen", rig.seat.Occupant == hum2)

	--[[ CharacterRemoving — den tredje vägen ut. En utloggning eller ett
		byte av karaktär mitt i ritten ska städa likadant. ]]
	S.spelare.CharacterRemoving:Fire(k2)
	check("CharacterRemoving städar också",
		rig.seat.Occupant == nil and HorseService.horseOf(S.spelare) == nil)
	stadaSession(S)
end

--[[ ══ PUNKT 11: DAGEN RÄKNAS EN GÅNG, OCH FINNS KVAR I MORGON ═════════

	Genom TJÄNSTERNA hela vägen, mot riggen, med datalagret under. Det som
	mäts utöver `skotselpass.spec` är att kedjan går att spela igenom i
	integrationsläge och att passet räknas EXAKT en gång även om avslutet
	kommer två gånger. ]]
print("\n── Punkt 11: ett pass, räknat en gång, kvar i morgon ──")
do
	local S = nySession("Dag", 9206)
	local ok, skal = skotselGenomTjansten(S.spelare)
	check("skötseln går igenom", ok, tostring(skal))
	check("uppsittningen går igenom", (HorseService.tryMount(S.spelare, S.modell)) == true)
	check("avsittningen går igenom", HorseService.dismount(S.spelare) == true)

	--[[ EFTERVÅRDEN genom tjänsten, moment för moment. ]]
	local kvar = {}
	for _, m in ipairs(Pass.moment()) do table.insert(kvar, m.id) end
	local allaOk, sista = true, nil
	for _, id in ipairs(kvar) do
		local okE, skalE = GameplayService.eftervard(S.spelare, id)
		if not okE then allaOk = false sista = id .. ": " .. tostring(skalE) end
	end
	check("hela eftervården går igenom mot hästen", allaOk, tostring(sista))

	local save = SparService.save(S.spelare)
	check("passet är räknat en gång", save ~= nil and save.pass == 1,
		save and tostring(save.pass) or "ingen save")
	check("och passet är markerat räknat, så eftervården inte ber om mer",
		GameplayService.passFor(S.spelare).lage == Pass.LAGE.RAKNAT,
		tostring(GameplayService.passFor(S.spelare).lage))

	--[[ DUBBELAVSLUT. En andra `avslutaPass` — utloggning i samma sekund —
		får inte ge ett andra pass. ]]
	GameplayService.avslutaPass(S.spelare)
	GameplayService.avslutaPass(S.spelare)
	check("ett dubbelt avslut ger fortfarande ETT pass", save.pass == 1,
		tostring(save.pass))

	--[[ OCH I MORGON. Sparfilen läses om ur lagret, som en ny session. ]]
	SparService._glomForProv(S.spelare)
	local imorgon = SparService.ladda(S.spelare)
	check("passet finns kvar när sparfilen läses om", imorgon.pass == 1,
		tostring(imorgon.pass))
	check("första dagen är avklarad med rätt häst",
		imorgon.forstaDagen.klar == true and imorgon.forstaDagen.hastId == S.hastId,
		tostring(imorgon.forstaDagen.hastId))
	check("och nästa dag är pass två", Sparning.aktuelltPass(imorgon) == 2,
		tostring(Sparning.aktuelltPass(imorgon)))
	stadaSession(S)
end

print("\n── Punkt 11b: kvittot är det som håller när skrivningen faller ──")
do
	--[[ DEN VÄG SOM FAKTISKT KAN RÄKNA TVÅ GÅNGER.
	Mätningen ovan är sann men slö: `Pass.markeraRaknat` har satt läget
	till `recorded`, så det andra avslutet nekas redan av läget och
	kvittot i `Sparning.registreraPass` provas inte. Det syntes när
	kvittot muterades bort — grinden förblev grön.

	Vägen som verkligen kallar `registreraPass` två gånger med samma
	`passId` är den som koden själv beskriver: SKRIVNINGEN FALLER.
	Passet räknas då i minnesbilden men markeras INTE räknat, just för
	att nästa försök ska ta det igen. Kommer det försöket fram ska
	dagen ändå vara ETT pass. ]]
	local T = nySession("Kvitto", 9207)
	local okT = skotselGenomTjansten(T.spelare)
	check("skötseln går igenom", okT == true)
	HorseService.tryMount(T.spelare, T.modell)
	HorseService.dismount(T.spelare)

	--[[ Skrivningen faller under hela eftervården. ]]
	__datastore.felSkriv = true
	for _, m in ipairs(Pass.moment()) do
		GameplayService.eftervard(T.spelare, m.id)
	end
	local p = GameplayService.passFor(T.spelare)
	local saveT = SparService.save(T.spelare)
	check("passet är räknat i minnet trots att skrivningen föll",
		saveT.pass == 1, tostring(saveT.pass))
	check("men INTE markerat räknat — nästa försök ska ta det igen",
		p.lage ~= Pass.LAGE.RAKNAT, tostring(p.lage))

	--[[ Nästa försök går fram. Kvittot är det enda som står mellan
		spelaren och två pass för en dag. ]]
	__datastore.felSkriv = false
	GameplayService.avslutaPass(T.spelare)
	check("det andra avslutet ger fortfarande ETT pass", saveT.pass == 1,
		tostring(saveT.pass))
	check("och nu är passet markerat räknat", p.lage == Pass.LAGE.RAKNAT,
		tostring(p.lage))
	stadaSession(T)
end

--[[ `os.exit` finns INTE i luau-CLI:t (den är nil). Ett anrop rakt ut gav
	en "attempt to call a nil value" i loggen i stället för ett läsbart
	slut — rött blev det, men av fel anledning i texten. Här används den
	om den finns, annars ger `error` den icke-nollskilda exitkoden. ]]
if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("\nintegration.spec: alla gröna")
end
