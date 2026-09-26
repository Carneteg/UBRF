--!nostrict
--[[
	«RIDA NU» — AVSLAGET SKA BÄRA SITT ARGUMENT HELA VÄGEN (#246 A).

	Fysisk Studio-QA 2026-09-18, touch, dagens häst Trixie: sadeln hämtad,
	ledning igång, spelaren trycker «Rida nu». Loggen:

	    [Tack] SagaAberg tog Trixies sadel.
	    [Led]  SagaAberg · trixie · LedBorja
	    [Led]  SagaAberg · trixie · RidaNu NEKAD: forb.fel_tur
	    [Horse] Rida nu: wrong turn — %s is next (forb.fel_tur)

	Sista raden är felet. Spelaren fick se ett bokstavligt `%s` i stället
	för vilket moment som stod på tur — alltså ett avslag utan väg vidare.

	ARGUMENTET FINNS VID KÄLLAN. `Preparation.provaSteg` och
	`Preparation.provaMoment` lämnar båda namnet som TREDJE returvärde.
	Det tappas sedan, och den här specen mäter varje led för sig så att
	fyndet pekar på en RAD och inte på "någonstans i kedjan":

	    provaSteg      -> (false, "forb.fel_tur", namn)   källan
	    provaMoment    -> tappar det                      led 1
	    utforMoment    -> tappar det                      led 2
	    Gameplay.moment-> tappar det                      led 3
	    ridaNuInre     -> tappar det                      led 4
	    (klienten      -> tappar det                      led 5, se
	     klient-ridanu.spec.luau — den hör hemma i klientbänken)

	Samma felklass är redan rättad två gånger i repot, i
	`HorseService.tryMount` och i passets `Pass.utfor` — se noten vid
	`GameplayService.luau:1184`. Den här gången gällde det förberedelsen.

	Kör: python3 roblox/tests/build.py tests/ridanu-avslag.spec.luau
	     && luau roblox/tests/.build/ridanu-avslag.spec.luau
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

local HAST = "blackrock_jack"

--[[ En fas som INTE står på tur, och ett giltigt moment i den. Provet
     letar upp den i stället för att skriva in ett fasnamn: fasordningen är
     kanonens, och ett hårdkodat id här hade blivit en andra sanning om
     den. ]]
local function felTurFas(state)
	local nasta = Preparation.nasta(state)
	for _, f in ipairs(Preparation.stegFaser()) do
		if nasta == nil or f.id ~= nasta.id then
			for _, m in ipairs(Preparation.moment(f.id)) do
				if not m.fel and m.id then return f, m end
			end
		end
	end
	return nil, nil
end

print("")
print("RIDA NU — AVSLAGETS ARGUMENT (#246 A)")

print("\n── Källan bär namnet ──")

local state = Preparation.nyState(HAST, 1)
local fas, moment = felTurFas(state)
check("provet hittade en fas som inte står på tur", fas ~= nil and moment ~= nil,
	fas and ("%s · %s"):format(fas.id, moment.id) or "ingen")

local kallArg
do
	local ok, skal, arg = Preparation.provaSteg(state, fas.id, HAST)
	kallArg = arg
	check("provaSteg nekar med forb.fel_tur",
		ok == false and skal == "forb.fel_tur", tostring(skal))
	--[[ DET HÄR ÄR HELA POÄNGEN: namnet finns, och det är inte tomt. ]]
	check("och lämnar namnet på den fas som står på tur som tredje värde",
		type(arg) == "string" and arg ~= "" and arg ~= "%s",
		("arg = %s"):format(tostring(arg)))
end

print("\n── Led 1: provaMoment ──")
do
	local ok, skal, arg = Preparation.provaMoment(state, fas.id, moment.id, HAST)
	check("provaMoment nekar med samma skäl",
		ok == false and skal == "forb.fel_tur", tostring(skal))
	check("och FÖR VIDARE argumentet från provaSteg",
		arg == kallArg, ("arg = %s (väntat %s)"):format(tostring(arg), tostring(kallArg)))
end

print("\n── Led 2: utforMoment ──")
do
	local ok, skal, arg = Preparation.utforMoment(state, fas.id, moment.id, HAST)
	check("utforMoment nekar med samma skäl",
		ok == false and skal == "forb.fel_tur", tostring(skal))
	check("och FÖR VIDARE argumentet",
		arg == kallArg, ("arg = %s (väntat %s)"):format(tostring(arg), tostring(kallArg)))
	--[[ Och den nekade provningen får inte ha flyttat förberedelsen. ]]
	check("ett avvisat moment flyttar ingenting",
		(state.gjorda[fas.id] or {})[moment.id] == nil)
end

print("\n── Texten spelaren möter ──")
do
	--[[ Nyckeln bär ett `%s`. Utan argument ser spelaren det bokstavligt,
	     vilket är precis vad Studio-loggen visade. Provet mäter bådadera:
	     att formateringen MED argument blir läsbar, och att den UTAN blir
	     det oläsliga som rapporterades. ]]
	check("språknyckeln finns", Sprak.finns("forb.fel_tur") == true)
	local med = Sprak.t("forb.fel_tur", kallArg)
	local utan = Sprak.t("forb.fel_tur")
	check("med argument nämner texten vad som står på tur",
		string.find(med, "%%s") == nil and string.find(med, kallArg, 1, true) ~= nil,
		("%q"):format(med))
	check("och utan argument blir det just det oläsliga QA såg",
		string.find(utan, "%%s") ~= nil, ("%q"):format(utan))
end

--[[ ══ DET EXAKTA QA-SCENARIOT (#246 B) ═══════════════════════════════

	Ordern säger: falsifiera exakt scenariot. Alltså inte en förenkling,
	utan den sekvens Studio-loggen visar:

	    1. spelaren står vid boxområdet,
	    2. hon TAR dagens hästs sadel ur boxfronten,
	    3. hon startar LEDNING,
	    4. hon trycker «Rida nu».

	Att den här sekvensen över huvud taget går att köra i bänken är nytt.
	Tre hål stod i vägen och är rättade i samma gren: `TackForradService`
	saknades i integrationsbunten, `typeof` var ostubbad så
	`placeraVidMal` alltid nekade, och `CFrame - Vector3` saknades så
	samma funktion kraschade när vakten väl släppte igenom.

	KRAVET ur acceptance contract B:

	  "Den ska antingen slutföra återstående giltiga moment och göra
	   hästen redo, eller neka med en specifik, begriplig nästa handling.
	   Ett generiskt «fel tur» utan användbar väg vidare är inte
	   accepterat."

	Provet mäter därför inte ETT utfall utan att utfallet tillhör den
	tillåtna mängden — och att ett nej faktiskt bär en läsbar nästa
	handling. ]]
print("\n── Exakt QA-sekvens: sadel tagen, ledning igång, Rida nu ──")

local Players = game:GetService("Players")
local Taggar = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local function nyKaraktar(pos)
	local k = Instance.new("Model")
	k.Name = "Karaktar"
	local rot = Instance.new("Part")
	rot.Name = "HumanoidRootPart"
	rot.Size = Vector3.new(2, 2, 1)
	rot.CFrame = CFrame.new(pos)
	rot.Parent = k
	local hum = Instance.new("Humanoid")
	hum.Name = "Humanoid"
	hum.Parent = k
	local anim = Instance.new("Animator")
	anim.Name = "Animator"
	anim.Parent = hum
	k.Parent = workspace
	return k
end

--[[ Flyttar spelaren dit hon måste stå. `narvaro` och `tagSadel` mäter
	båda avstånd, och ett nej av den anledningen mäter inte förberedelsen. ]]
local function stallDig(sp, pos)
	sp.Character:FindFirstChild("HumanoidRootPart").CFrame =
		CFrame.new(pos + Vector3.new(2, 0, 0))
end

do
	__datastore.nollstall()
	Taggar:nollstall()
	Players.PlayerAdded:nollstall()
	Players.PlayerRemoving:nollstall()
	RunService._server = true
	Players._spelare = {}
	SparService._glomHookarForProv()

	--[[ Boxfronterna hängs av tjänsten, som i produktionen. ]]
	TackForradService.start(GameplayService.valjEn)

	local k = nyKaraktar(Vector3.new(2, 0, 0))
	local sp = { Name = "QA", UserId = 9246, Character = k,
		CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }
	SparService._glomForProv(sp)
	SparService.start()
	StallService.start()
	HorseService.start()
	GameplayService.start()
	Players._spelare = { sp }
	Players.PlayerAdded:Fire(sp)
	Players.PlayerAdded:slutfor()

	local hastId = StallService.hastIdFor(sp)
	local mod = HastRigg.bygg(hastId, hastId, CFrame.new(Vector3.new(0, 0, 0)))
	mod.Parent = workspace
	Taggar:AddTag(mod, "Horse")
	check("spelaren har fått dagens häst", hastId ~= nil, tostring(hastId))
	check("och hästen är bunden", GameplayService.bind(sp) ~= nil)

	--[[ Målzonen, som `GameplayService.start` sätter den i drift. ]]
	local M = 3
	local hp = mod.PrimaryPart.Position
	LedService.satMalzon({ x = hp.X / M - 5, y = 170 - hp.Z / M - 5, w = 10, h = 10 })

	--[[ STEG 2: sadeln ur boxfronten. ]]
	local front = TackForradService.forHast(hastId)
	check("dagens häst har en boxfront med sadel",
		front ~= nil and TackForradService.paFronten(hastId, "sadel") == true)
	if front and front.PrimaryPart then stallDig(sp, front.PrimaryPart.Position) end
	local togSadel, sadelSkal = TackForradService.tagSadel(sp, hastId)
	check("«Ta sadeln» går igenom", togSadel == true, tostring(sadelSkal))
	check("och sadeln bärs i handen",
		TackService.barBuren(sp, "sadel") ~= nil)

	--[[ STEG 3: ledningen startar. ]]
	stallDig(sp, hp)
	local ledOk, ledSkal = LedService.borja(sp, mod)
	check("ledningen startar", ledOk == true, tostring(ledSkal))

	--[[ STEG 4: «Rida nu», med sadeln buren och ledningen igång. ]]
	local ok, skal, arg = GameplayService.ridaNu(sp)
	local text = if ok then "" else PreparationController.skalText(skal, arg)
	print(("       [QA] RidaNu -> ok=%s skal=%s arg=%s"):format(
		tostring(ok), tostring(skal), tostring(arg)))

	check("«Rida nu» från delvis förberedd häst ger ett användbart utfall",
		ok == true or (type(skal) == "string" and skal ~= ""
			and text ~= "" and string.find(text, "%%s") == nil),
		("ok=%s skal=%s text=%q"):format(tostring(ok), tostring(skal), text))

	--[[ Gick det igenom ska hästen VERKLIGEN vara redo — inte bara
	     avbockad. Regeln är densamma som uppsittningen använder. ]]
	if ok then
		local redo = Preparation.provaUppsittning(GameplayService.stateFor(sp), hastId)
		check("och hästen är faktiskt uppsittningsklar", redo == true,
			tostring(redo))
	end

	--[[ IDEMPOTENS: ett andra tryck rör ingenting och svarar stabilt. ]]
	local ok2, skal2 = GameplayService.ridaNu(sp)
	check("ett andra «Rida nu» svarar stabilt, aldrig med ett utrustningsfel",
		skal2 ~= "tack.redan_pa" and skal2 ~= "tack.saknar_sadel"
			and (tostring(skal) == tostring(skal2)
				or (ok == true and skal2 == "spel.redan_redo")),
		("1: %s/%s   2: %s/%s"):format(tostring(ok), tostring(skal),
			tostring(ok2), tostring(skal2)))
end

--[[ ══ SPELARENS TEXT — DE TVÅ KRAVEN UR PRECISERINGEN ══════════════

	Arkitekturpreciseringen 2026-09-18 på #246 är uttrycklig om vem som
	äger texten: `PreparationController.skalText(skal, arg)` och
	språkkanonen. Två prov krävs, och de mäter motsatta fall.

	Notera att argumentet är en KANON-token (`kanon:…`), inte färdig text.
	`skalText` löser upp den på spelarens språk — provet mäter alltså vad
	spelaren faktiskt läser, inte att en token råkar finnas med. ]]
print("\n── Vad spelaren läser ──")
do
	local med = PreparationController.skalText("forb.fel_tur", kallArg)
	check("med argument ersätts %s av nästa FÖRBEREDELSEMOMENT",
		string.find(med, "%%s") == nil
			and string.find(med, Preparation.utanKanonprefix(kallArg), 1, true) ~= nil,
		("%q"):format(med))
	--[[ …och prefixet får inte läcka ut. "kanon:Hälsa lugnt" är en
	     intern token; spelaren ska läsa meningen, inte nyckeln. ]]
	check("och kanon-prefixet syns aldrig för spelaren",
		string.find(med, "kanon:", 1, true) == nil, ("%q"):format(med))

	--[[ DET ANDRA KRAVET: saknat argument får ALDRIG ge rå %s. ]]
	local utan = PreparationController.skalText("forb.fel_tur", nil)
	check("utan argument visas ingen rå %s",
		string.find(utan, "%%s") == nil, ("%q"):format(utan))
	check("och fallbacken håller sig i förberedelsens domän",
		string.find(utan, Sprak.t("forb.nasta_steget"), 1, true) ~= nil,
		("%q"):format(utan))
	--[[ Ingen ryttarkö, ingen "vänta på din tur" — preciseringen förbjuder
	     uttryckligen att felet ges en annan domänbetydelse. ]]
	check("och nämner ingen annan ryttare",
		string.find(string.lower(utan), "ryttare") == nil
			and string.find(string.lower(utan), "rider") == nil,
		("%q"):format(utan))
end

print("")
--[[ ══ HAN SADLADE SJÄLV, OCH «RIDA NU» NEKADE (#264) ═══════════════

	Tobias playtest 2026-09-24, 08:19-08:21: Troy tilldelad, träns och
	sadel tagna, «Rida nu» nekad TVÅ gånger med `forb.fel_tur` och
	argumentet `kanon:Utrustning 1/5` — alltså «det är inte din tur att
	göra det du redan gjort».

	KEDJAN, läst i källan: `TackService.satPa` svarar `tack.redan_pa` när
	en del av den sorten redan sitter på hästen. `GameplayService.moment`
	returnerade DÅ direkt, innan `Preparation.utforMoment` — det FYSISKA
	steget var gjort men det LOGISKA momentet kvitterades aldrig.
	`ridaNuInre` tolererar `tack.redan_pa` och gick vidare till nästa
	moment, som därmed låg ur tur, och nejet namngav det moment som
	faktiskt stod på tur.

	Blocket ovanför missade det här: det godtar ett avslag så länge
	avslaget är LÄSBART. Tobias fall är inte ett läsbart avslag — det är
	ett avslag som inte borde finnas. ]]
do
	print("\n── Spelaren sadlade själv: «Rida nu» ska gå igenom ──")
	local k = nyKaraktar(Vector3.new(2, 0, 0))
	local sp = { Name = "QA2", UserId = 9247, Character = k,
		CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }
	SparService._glomForProv(sp)
	Players._spelare = { sp }
	Players.PlayerAdded:Fire(sp)
	Players.PlayerAdded:slutfor()

	local hastId = StallService.hastIdFor(sp)
	local mod = HastRigg.bygg(hastId, hastId, CFrame.new(Vector3.new(0, 0, 0)))
	mod.Parent = workspace
	Taggar:AddTag(mod, "Horse")
	local M = 3
	local hp = mod.PrimaryPart.Position
	LedService.satMalzon({ x = hp.X / M - 5, y = 170 - hp.Z / M - 5, w = 10, h = 10 })

	--[[ Han tog utrustningen ur boxfronten, precis som i loggen. ]]
	local front = TackForradService.forHast(hastId)
	if front and front.PrimaryPart then stallDig(sp, front.PrimaryPart.Position) end
	TackForradService.tagSadel(sp, hastId)
	stallDig(sp, hp)

	--[[ OCH HAN SATTE PÅ DEN SJÄLV. Det fysiska steget är gjort; det
	     logiska momentet är det inte. Det är hela reproduktionen. ]]
	local okU = TackService.satPa(sp, mod, "underlagg", hastId, mod)
	local okS = TackService.satPa(sp, mod, "sadel", hastId, mod)
	check("REPRODUKTION: sadeln sitter fysiskt på hästen",
		TackService.harTack(mod, "sadel") == true,
		("underlagg=%s sadel=%s"):format(tostring(okU), tostring(okS)))

	--[[ Och momentet är INTE kvitterat — annars mäter provet fel sak. ]]
	local st = GameplayService.stateFor(sp)
	local gjorda = st and st.gjorda and st.gjorda["iordning"]
	check("och det logiska momentet är ännu inte kvitterat",
		gjorda == nil or next(gjorda) == nil,
		tostring(gjorda and next(gjorda)))

	local ok, skal, arg = GameplayService.ridaNu(sp)
	print(("       [QA] RidaNu -> ok=%s skal=%s arg=%s"):format(
		tostring(ok), tostring(skal), tostring(arg)))
	check("«RIDA NU» GÅR IGENOM NÄR SPELAREN SADLAT SJÄLV",
		ok == true, ("ok=%s skal=%s arg=%s"):format(
			tostring(ok), tostring(skal), tostring(arg)))
	check("och nejet är i synnerhet inte forb.fel_tur",
		skal ~= "forb.fel_tur" and skal ~= "pass.fel_tur", tostring(skal))

	if ok then
		local redo = Preparation.provaUppsittning(GameplayService.stateFor(sp), hastId)
		check("och hästen är faktiskt uppsittningsklar", redo == true,
			tostring(redo))
		--[[ ── VEM SOM GJORDE DET GÅR INTE ATT LÄSA UR GEOMETRIN ──────

		     Här stod att sadlingen skulle bokföras som SPELARENS, och
		     rättelsen bakom det slöt sig till utföraren ur att
		     utrustningen redan satt på hästen. Granskningen underkände
		     det, med rätta: en påsatt sadel är ett faktum om VÄRLDEN,
		     inte om vem som lyfte den. I ett rent auto-pass gav samma
		     slutledning `ownU1=auto ownU2=true` — stallet fick kredit
		     för handarbete som ingen människa gjort.

		     Kontraktet är därför: momentet KVITTERAS, vilket var
		     `fel_tur`-felet, med den utförare anropet faktiskt bär.
		     «Rida nu» är stallets arbete och bokförs som `auto`.
		     Verkligt registrerat handarbete rörs inte, och påhittat
		     blir det aldrig. ]]
		local st2 = GameplayService.stateFor(sp)
		local iord = st2 and st2.gjorda and st2.gjorda["iordning"] or {}
		local auto, ospec = 0, 0
		for _, v in pairs(iord) do
			if v == "auto" then auto += 1 else ospec += 1 end
		end
		check("momenten kvitteras av «Rida nu», som stallets arbete",
			auto > 0 and ospec == 0,
			("auto=%d ovrigt=%d"):format(auto, ospec))
	end
end

--[[ ══ KREDITEN ÅT BÅDA HÅLL, OCH ETT AUTO-PASS SOM FALLER (#264 R2) ══

	Blocket ovanför mäter ena riktningen: «Rida nu» är stallets arbete och
	bokförs som `auto` även när spelaren råkat sadla själv först.

	Granskningen bad om de två som saknades.

	  · PRODUKTIONENS MANUELLA VÄG. Spelaren trycker på momentet SJÄLV,
	    med sin egen hand, på en häst där delen redan sitter. Då ska
	    kvittensen bära HENNE — inte «auto». Det är samma fall-through
	    genom `tack.redan_pa`, men med en riktig utförare i anropet, och
	    det är vägen Tobias faktiskt gick i stallet.

	  · ETT AUTO-PASS SOM FAKTISKT MISSLYCKAS, och sedan görs om. Ett
	    fysiskt steg som inte går fram ska avbryta HELA förberedelsen med
	    sitt riktiga nej — och framför allt inte lämna någon påhittad
	    kredit efter sig i liggaren. Går felet över ska omförsöket lyckas
	    på riktigt.

	LIGGAREN är `state.gjorda[fas][moment]`: `"auto"` för stallets arbete,
	`true` för spelarens eget. Att skilja dem åt är hela poängen med
	FUN FIRST · RIDE FIRST — egen omsorg ska peka uppåt, och då får den
	inte delas ut gratis. ]]
do
	print("\n── Krediten åt båda håll, och ett auto-pass som faller ──")

	--[[ ── A · DEN MANUELLA PRODUKTIONSVÄGEN ─────────────────────────── ]]
	local k = nyKaraktar(Vector3.new(2, 0, 0))
	local sp = { Name = "QA3", UserId = 9248, Character = k,
		CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }
	SparService._glomForProv(sp)
	Players._spelare = { sp }
	Players.PlayerAdded:Fire(sp)
	Players.PlayerAdded:slutfor()

	local hastId = StallService.hastIdFor(sp)
	local mod = HastRigg.bygg(hastId, hastId, CFrame.new(Vector3.new(0, 0, 0)))
	mod.Parent = workspace
	Taggar:AddTag(mod, "Horse")
	local M = 3
	local hp = mod.PrimaryPart.Position
	LedService.satMalzon({ x = hp.X / M - 5, y = 170 - hp.Z / M - 5, w = 10, h = 10 })

	local front = TackForradService.forHast(hastId)
	if front and front.PrimaryPart then stallDig(sp, front.PrimaryPart.Position) end
	TackForradService.tagSadel(sp, hastId)
	stallDig(sp, hp)

	--[[ FRAM TILL UTRUSTNINGEN GENOM PRODUKTIONENS EGEN VÄG: varje fas
	     före `iordning`, och sedan hovarna. Utan den här vandringen
	     nekas `utr:1` med `forb.fel_tur` av ett HELT ANNAT skäl än det
	     provet vill mäta, och mätningen hade sagt fel sak om rätt rad.
	     Allt görs med hennes egen hand — ingen «auto» någonstans. ]]
	do
		local st = GameplayService.stateFor(sp)
		for _, f in ipairs(Preparation.stegFaser()) do
			if f.id == "iordning" then break end
			for _, m in ipairs(Preparation.moment(f.id)) do
				if not m.fel and m.id then
					GameplayService.moment(sp, f.id, m.id)
					if Preparation.arVal(f.id) and Preparation.fasKlar(st, f.id) then break end
				end
			end
		end
		for _, m in ipairs(Preparation.moment("iordning")) do
			if not m.id:match("^utr:") then
				GameplayService.moment(sp, "iordning", m.id)
			end
		end
		check("utr:1 står på tur — annars mäter provet fel sak",
			Preparation.nastaMoment(st, "iordning").id == "utr:1",
			tostring(Preparation.nastaMoment(st, "iordning").id))
	end

	--[[ Hon lägger på underlägget med sin egen hand — `TackService.satPa`
	     är samma anrop promptvägen gör. Det LOGISKA momentet står kvar. ]]
	TackService.satPa(sp, mod, "underlagg", hastId, mod)
	check("REPRODUKTION: underlägget sitter fysiskt, momentet är okvitterat",
		TackService.harTack(mod, "underlagg") == true
			and (GameplayService.stateFor(sp).gjorda["iordning"] or {})["utr:1"] == nil)

	--[[ OCH NU TRYCKER HON SJÄLV. Inget «auto» någonstans i anropet. ]]
	local okM, skalM = GameplayService.moment(sp, "iordning", "utr:1")
	check("det egna momentet går igenom trots att delen redan satt där",
		okM == true, ("ok=%s skal=%s"):format(tostring(okM), tostring(skalM)))
	local iordM = GameplayService.stateFor(sp).gjorda["iordning"] or {}
	check("KREDITEN ÄR HENNES — inte stallets",
		iordM["utr:1"] == true, tostring(iordM["utr:1"]))
	check("och i synnerhet inte bokförd som auto",
		iordM["utr:1"] ~= "auto", tostring(iordM["utr:1"]))

	--[[ ── B · AUTO-PASSET FALLER, OCH GÖRS OM ─────────────────────────

	     Ett fysiskt steg vägrar. Fail-closed betyder att HELA
	     förberedelsen avbryts med det riktiga nejet — inte att resten
	     fylls i och hästen kallas klar. ]]
	local k2 = nyKaraktar(Vector3.new(2, 0, 0))
	local sp2 = { Name = "QA4", UserId = 9249, Character = k2,
		CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }
	SparService._glomForProv(sp2)
	Players._spelare = { sp2 }
	Players.PlayerAdded:Fire(sp2)
	Players.PlayerAdded:slutfor()

	local hastId2 = StallService.hastIdFor(sp2)
	local mod2 = HastRigg.bygg(hastId2, hastId2, CFrame.new(Vector3.new(0, 0, 0)))
	mod2.Parent = workspace
	Taggar:AddTag(mod2, "Horse")
	local hp2 = mod2.PrimaryPart.Position
	LedService.satMalzon({ x = hp2.X / M - 5, y = 170 - hp2.Z / M - 5, w = 10, h = 10 })
	stallDig(sp2, hp2)

	local riktigSatPa = TackService.satPa
	local nekade = 0
	TackService.satPa = function(...)
		nekade += 1
		return false, "tack.kunde_inte_byggas"
	end
	local okF, skalF = GameplayService.ridaNu(sp2)
	TackService.satPa = riktigSatPa

	check("det fysiska steget nekade verkligen", nekade > 0, ("%d"):format(nekade))
	check("AUTO-PASSET FALLER MED SITT RIKTIGA NEJ",
		okF == false and skalF == "tack.kunde_inte_byggas",
		("ok=%s skal=%s"):format(tostring(okF), tostring(skalF)))
	check("och hästen är INTE uppsittningsklar efter ett fallet pass",
		Preparation.provaUppsittning(GameplayService.stateFor(sp2), hastId2) ~= true)
	--[[ DET VIKTIGASTE I HELA BLOCKET: ett fallet auto-pass får inte ha
	     delat ut spelarkredit på vägen. ]]
	local iordF = GameplayService.stateFor(sp2).gjorda["iordning"] or {}
	local falskKredit = 0
	for _, v in pairs(iordF) do
		if v ~= "auto" then falskKredit += 1 end
	end
	check("INGEN PÅHITTAD KREDIT LIGGER KVAR EFTER FELET",
		falskKredit == 0, ("%d egna i liggaren"):format(falskKredit))

	--[[ OMFÖRSÖKET. Felet är över; nu ska det gå fram på riktigt. ]]
	local okR, skalR = GameplayService.ridaNu(sp2)
	check("OMFÖRSÖKET LYCKAS när det fysiska felet är över",
		okR == true, ("ok=%s skal=%s"):format(tostring(okR), tostring(skalR)))
	check("och hästen är uppsittningsklar efter omförsöket",
		Preparation.provaUppsittning(GameplayService.stateFor(sp2), hastId2) == true)
	local iordR = GameplayService.stateFor(sp2).gjorda["iordning"] or {}
	local autoR, egnaR = 0, 0
	for _, v in pairs(iordR) do
		if v == "auto" then autoR += 1 else egnaR += 1 end
	end
	check("och allt omförsöket gjorde står som stallets arbete",
		autoR > 0 and egnaR == 0, ("auto=%d egna=%d"):format(autoR, egnaR))
end

if fails > 0 then
	print(string.format("%d mätning(ar) föll.", fails))
else
	print("Alla mätningar gick igenom.")
end
