--!nostrict
--[[ EN HJÄLP FÅR INTE FÖRSVINNA I ETT LEKTIONSKORT (#263, P1)

	Uppmätt i Studio på `96efb06`, färsk First Ride, riktig W-tangent:

	    drivImpuls anropad -> true
	    UIS KeyCode.W gpe=true
	    consume  gaitUp=true
	    (ingen step-rad — avsikten var borta)
	    Gait = halt, Speed = 0

	Hela inmatningskedjan var alltså hel. Det som saknades var att
	`LektionController.vantar()` är SANT i samma ögonblick spelaren
	sätter sig upp — kortet «Continue to start the lesson» står uppe —
	och pausgrenen i `init.client.luau` anropade `Input.consume()` och
	kastade resultatet. Efter ett tryck på kortets egen knapp gav samma
	W omedelbart `halt → walk`, `Gait = walk`, `Speed = 1.45` och ett
	`RidingIntent(driv, sekvens 1)` på servern.

	── VARFÖR INGEN GRIND FÅNGADE DET ────────────────────────────────

	Den fanns dokumenterad i bänken, som en omväg. `klient-ridhandlingar`
	har en hjälpare `kvitteraKort()` med kommentaren:

	    "Kortet tar över en bildruta in i ritten och kastar varje avsikt
	     tills det kvitteras — samma väg som klient.spec går."

	Varje spec kvitterade alltså kortet med `gaVidare()` innan den mätte
	ridningen. Ingen mätte det spelaren faktiskt gör: sätta sig upp och
	trycka DRIV. Gate 2A gjorde det akut genom att sätta spelaren i
	sadeln automatiskt — rakt framför kortet.

	── KONTRAKTET SOM MÄTS HÄR ───────────────────────────────────────

	  1. REPRODUKTIONEN — kortet står uppe direkt efter uppsittning, och
	     en hjälp given då ska INTE försvinna.
	  2. En hjälp BESVARAR kortet och verkar i samma bildruta: trappan
	     flyttar sig och EN `RidingIntent` går iväg.
	  3. En bildruta UTAN hjälp lämnar kortet uppe. Kortet försvinner
	     inte av sig självt.
	  4. REPLAYEN ÄR KVAR SOM HÅRD PAUS. Att titta på sin ritt ska inte
	     gå att avbryta med en tygel — där gäller pausen fullt ut.

	Kör: python3 roblox/tests/build.py tests/klient-lektionspaus.spec.luau
	     && luau roblox/tests/.build/klient-lektionspaus.spec.luau ]]

local fel = 0
local function prova(vad, ok, detalj)
	if ok then
		print(("  OK   %s%s"):format(vad, if detalj then "  " .. detalj else ""))
	else
		fel += 1
		print(("  FEL  %s%s"):format(vad, if detalj then "  " .. detalj else ""))
	end
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CAS = game:GetService("ContextActionService")
local player = Players.LocalPlayer
local Net = Networking

local dt = 1 / 30
local function bildrutor(n)
	for _ = 1, n do RunService.RenderStepped:Fire(dt) end
end

local remote = Net.get("RidingIntent")
local function nollaSkickat()
	remote._skickat = {}
end
local function skickade()
	local ut = {}
	for _, p in ipairs(remote._skickat or {}) do
		table.insert(ut, ("%s/%s"):format(tostring(p[2]), tostring(p[3])))
	end
	return ut
end

--[[ KLOCKAN ÄR UTBYTBAR, och provet måste byta den. `Input.IMPULS_SPARR`
	är en TIDSREGEL: två tryck i rad inom spärren är EN hjälp, och det
	är avsiktligt. Utan en styrd klocka mätte blocket nedan spärren i
	stället för trappan — första omgången av det här provet gjorde
	precis det och blev röd av fel skäl. ]]
local nu = 1000
Input._klocka = function() return nu end
local function gaTiden(sek) nu += sek end

--[[ DRIV genom den RIKTIGA CAS-handlaren, inte genom `Input.drivImpuls`.
	Skillnaden är hela poängen: provet ska gå in där tangenten går in,
	annars mäter det sin egen genväg. Samma mönster som
	`driv-broms.spec` och `klient-ridhandlingar.spec`. ]]
local function drivTryck()
	local fn = CAS._bound[Input.DRIV]
	if fn == nil then return false end
	fn(Input.DRIV, Enum.UserInputState.Begin, {})
	return true
end

local hastNr = 0
local function nyRitt()
	hastNr += 1
	gaTiden(Input.IMPULS_SPARR + 0.05)
	local h = __makeHastModell("Lektionshast" .. hastNr)
	h:SetAttribute("RidSession", "ritt-paus-" .. hastNr)
	h.Parent = workspace
	Net.get("MountChanged").OnClientEvent:Fire(h, player)
	bildrutor(1)
	return h
end

--[[ INGEN SÖM IN I `ride`. `init.client.luau` håller ritten i en local,
	och jag lägger ingen provkrok i produktionskoden för att komma åt
	den. `RidingIntent` är ändå det observerbara kontraktet — loopen
	skickar den ENDAST när trappan faktiskt flyttade sig, så en avsikt
	på tråden ÄR beviset att steget togs. ]]

print("\n── 1. Kortet står uppe direkt efter uppsittning ──")
local hast = nyRitt()
prova("uppsittningen startade lektionen", LektionController.pagar() == true)
prova("och kortet väntar på spelaren — reproduktionen",
	LektionController.vantar() == true,
	("vantar=%s"):format(tostring(LektionController.vantar())))
nollaSkickat()
bildrutor(2)
prova("och ingenting har ridits ännu", #skickade() == 0,
	table.concat(skickade(), ", "))

print("\n── 2. En hjälp besvarar kortet OCH verkar i samma bildruta ──")
do
	nollaSkickat()
	prova("DRIV är bunden i CAS", drivTryck() == true)
	bildrutor(1)

	prova("kortet är kvitterat av hjälpen",
		LektionController.vantar() == false,
		("vantar=%s"):format(tostring(LektionController.vantar())))
	local s = skickade()
	prova("exakt en RidingIntent gick iväg", #s == 1, table.concat(s, ", "))
	prova("och den bar ordet driv", s[1] ~= nil and s[1]:match("^driv/") ~= nil,
		tostring(s[1]))

	--[[ Ett andra tryck ska ta NÄSTA pinne. Det visar att trappan
		verkligen flyttade sig och inte bara att en avsikt råkade gå.
		Tiden flyttas förbi impulsspärren först — annars mäter raden
		spärren, inte trappan. ]]
	nollaSkickat()
	gaTiden(Input.IMPULS_SPARR + 0.05)
	drivTryck()
	bildrutor(1)
	local s2 = skickade()
	prova("ett andra DRIV tar nästa pinne", #s2 == 1, table.concat(s2, ", "))
	prova("med högre sekvensnummer",
		s2[1] ~= nil and s[1] ~= nil and s2[1] ~= s[1],
		("%s efter %s"):format(tostring(s2[1]), tostring(s[1])))
end

print("\n── 3. En bildruta utan hjälp lämnar kortet uppe ──")
do
	local h2 = nyRitt()
	local _ = h2
	prova("nytt kort uppe", LektionController.vantar() == true)
	nollaSkickat()
	bildrutor(3)
	prova("kortet står kvar när ingen hjälp ges",
		LektionController.vantar() == true,
		("vantar=%s"):format(tostring(LektionController.vantar())))
	prova("och ingen avsikt gick iväg", #skickade() == 0,
		table.concat(skickade(), ", "))
end

print("\n── 4. Replayen är kvar som hård paus ──")
do
	local h3 = nyRitt()
	local _ = h3
	--[[ Kvittera kortet först, så att det är REPLAYEN och inget annat
		som pausar. Annars hade blocket mätt punkt 2 en gång till. ]]
	for _ = 1, 8 do
		if not LektionController.vantar() then break end
		LektionController.gaVidare()
		bildrutor(1)
	end
	prova("kortet är borta innan replayen öppnas",
		LektionController.vantar() == false)

	local r = Inspelning.ny("storvolt", "bamse")
	for i = 1, 30 do
		Inspelning.sampla(r, 0.06, { gangart = "trav" }, { x = i, z = i, yaw = 0 })
	end
	ReplayController.oppna(Inspelning.avsluta(r))
	prova("replayen är aktiv", LektionController.replayAktiv() == true)

	nollaSkickat()
	--[[ Förbi spärren, så att det är PAUSEN som mäts och inte tiden. ]]
	gaTiden(Input.IMPULS_SPARR + 0.05)
	drivTryck()
	bildrutor(2)
	prova("en hjälp rider INTE vidare bakom replayen",
		#skickade() == 0, table.concat(skickade(), ", "))
	prova("replayen står kvar — en tygel stänger den inte",
		LektionController.replayAktiv() == true)
	ReplayController.stang()
end

--[[ == 5. LEKTIONSKORTET FAR INTE FRYSA STYRNINGEN =================

	LESSON_CARD_RIDING_INPUT_ACCEPTANCE. Uppmätt i Studio 2026-09-20,
	uppsutten på Trixie i ridbanan, med `D` HÅLLEN (`action: "press"`,
	`UserInputService:IsKeyDown(D) == true` bekräftat) i 2,5 sekunder:

		LektionController.vantar()   true   (lage = "efter")
		yaw före                     -156,8 grader
		yaw efter                    -156,8 grader
		förflyttning                 0,0 studs

	Hästen svarade inte alls. Samma tangent, med kortet kvitterat, gav
	omedelbart en obruten båge -58 grader -> +66 grader.

	Orsaken är EN rad: pausgrenen anropar `ride.movement:release()` så
	snart `vantar()` är sann, och `release` nollar styrutslaget och
	hoppar över `movement:step` — det enda stället som skriver hästens
	kurs. Punkt 2 ovan löste halva problemet (#263 P1): en HJÄLP besvarar
	kortet. Men styrning är ingen hjälp, så A och D föll fortfarande i
	tomma intet.

	PRODUKTREGELN: ett kort som SYNS får aldrig i sig självt bli ett
	rörelselås. Bara en uttrycklig intervention som verkligen kräver
	skritt eller halt får stoppa framdrivningen. Replayen är en sådan —
	spelaren har själv valt att titta på sin ritt — och den mäts som
	hård paus i punkt 4 och 5d.

	MATNINGEN AR HASTENS EGEN KURS, inte ett fält i klienten:
	`MovementController:step` skriver `root.CFrame` genom `CFrame.lookAt`,
	och ingenting annat rör den. Ändras den har styrningen nått fram. ]]
print("\n-- 5. Kortet far inte frysa styrningen --")

--[[ A och D gar genom CAS-handlingen `HorseControl`, inte genom DRIV.
	Samma princip som `drivTryck`: in dar tangenten gar in. ]]
local function styrTryck(keyCode, lage)
	local fn = CAS._bound["HorseControl"]
	if fn == nil then return false end
	fn("HorseControl", lage or Enum.UserInputState.Begin, { KeyCode = keyCode })
	return true
end

local function kurs(h)
	local lv = h:FindFirstChild("HumanoidRootPart").CFrame.LookVector
	return math.deg(math.atan2(lv.X, lv.Z))
end

local function fart(h)
	return h:FindFirstChildOfClass("Humanoid").WalkSpeed
end

do
	local h5 = nyRitt()
	prova("kortet star uppe — reproduktionens forutsattning",
		LektionController.vantar() == true)
	prova("och HorseControl ar bunden", styrTryck(Enum.KeyCode.A) == true)

	local fore = kurs(h5)
	bildrutor(12)
	local efter = kurs(h5)
	styrTryck(Enum.KeyCode.A, Enum.UserInputState.End)
	prova("A svanger hasten FAST kortet star uppe",
		math.abs(efter - fore) > 1,
		("kurs %.1f -> %.1f grader"):format(fore, efter))

	--[[ 5b. Styrning ar ingen hjalp. Kortet ska sta kvar. ]]
	prova("men styrningen KVITTERAR inte kortet",
		LektionController.vantar() == true,
		("vantar=%s"):format(tostring(LektionController.vantar())))
	prova("och ingen ridavsikt gick ivag pa en styrning",
		#skickade() == 0, table.concat(skickade(), ", "))

	--[[ At andra hallet, sa att provet inte kan vara gront av en drift
		som rakar ga at ratt hall. ]]
	local fore2 = kurs(h5)
	styrTryck(Enum.KeyCode.D)
	bildrutor(12)
	local efter2 = kurs(h5)
	styrTryck(Enum.KeyCode.D, Enum.UserInputState.End)
	prova("och D svanger at andra hallet",
		(efter2 - fore2) * (efter - fore) < 0,
		("kurs %.1f -> %.1f grader"):format(fore2, efter2))
end

--[[ 5c. FRAMDRIVNINGEN stoppas inte av ett kort som dyker upp mitt i
	ritten. Kortet reses genom `UgnetaController.visa` — exakt samma
	anrop som `presentera` och `efterForsok` gor, alltsa produktens egen
	vag och ingen provkrok. ]]
do
	local h6 = nyRitt()
	gaTiden(Input.IMPULS_SPARR + 0.05)
	drivTryck()
	bildrutor(10)
	prova("hasten gar efter ett DRIV", fart(h6) > 0,
		("WalkSpeed %.2f"):format(fart(h6)))
	prova("och kortet ar kvitterat av hjalpen",
		LektionController.vantar() == false)

	UgnetaController.visa("Prov", { "Ett kort mitt i ritten" }, true, "Fortsatt")
	prova("ett nytt kort star uppe mitt i ritten",
		LektionController.vantar() == true)
	local fartMedKort = fart(h6)
	bildrutor(6)
	prova("framdrivningen fortsatter bakom kortet",
		fart(h6) > 0, ("WalkSpeed %.2f -> %.2f"):format(fartMedKort, fart(h6)))

	--[[ Och styrningen nar fram ocksa mitt i ritten, inte bara i halt. ]]
	local fore = kurs(h6)
	styrTryck(Enum.KeyCode.D)
	bildrutor(12)
	local efter = kurs(h6)
	styrTryck(Enum.KeyCode.D, Enum.UserInputState.End)
	prova("och styrningen nar fram mitt i ritten",
		math.abs(efter - fore) > 1,
		("kurs %.1f -> %.1f grader"):format(fore, efter))

	--[[ ══ OCH FORSOKET MATS INTE MEDAN KORTET STAR UPPE ══════════

		Det HAR ar vakten som skyddar forsoket nu nar hasten inte langre
		fryses: `LektionController.steg` returnerar pa
		`UgnetaController.vantar()` innan den rakar upp `pass.tid`.

		MATT HAR OCH INTE I `klient.spec`, och skalet ar en falsifiering
		som kom ut GRON. Den forsta versionen av matningen lag vid
		PRESENTATIONSKORTET, dar `lage` ar "presentation" — och da
		returnerar `steg` redan pa `lage ~= "rider"` en rad senare. Tva
		vakter tackte varandra, och en mutation som rev den ena andrade
		ingenting. Matningen sag ut att mata skyddet men matte den andra
		vakten.

		Mitt i ritten ar `lage` "rider", och da ar `vantar()`-vakten den
		ENDA som star mellan kortet och en tickande matning. ]]
	do
		local pRider = LektionController.pass()
		prova("lektionen ar i lage rider — ratt vakt star pa tur",
			LektionController.lage() == "rider",
			("lage=%s"):format(tostring(LektionController.lage())))
		local tidFore = pRider.tid
		bildrutor(20)
		prova("och forsoket mats INTE medan kortet star uppe",
			math.abs(pRider.tid - tidFore) < 1e-6,
			("tid %.3f -> %.3f"):format(tidFore, pRider.tid))
	end

	--[[ Kortet gar fortfarande att svara pa. ]]
	nollaSkickat()
	gaTiden(Input.IMPULS_SPARR + 0.05)
	drivTryck()
	bildrutor(1)
	prova("kortet gar att besvara med en hjalp som forr",
		LektionController.vantar() == false)
	prova("och hjalpen verkade — en avsikt gick ivag",
		#skickade() == 1, table.concat(skickade(), ", "))
end

--[[ 5d. REPLAYEN AR KVAR SOM HARD PAUS, ocksa for styrningen. Punkt 4
	mater hjalpen; den har mater tygeln. ]]
do
	local h7 = nyRitt()
	for _ = 1, 8 do
		if not LektionController.vantar() then break end
		LektionController.gaVidare()
		bildrutor(1)
	end
	local r = Inspelning.ny("storvolt", "bamse")
	for i = 1, 30 do
		Inspelning.sampla(r, 0.06, { gangart = "trav" }, { x = i, z = i, yaw = 0 })
	end
	ReplayController.oppna(Inspelning.avsluta(r))
	prova("replayen ar aktiv", LektionController.replayAktiv() == true)

	local fore = kurs(h7)
	styrTryck(Enum.KeyCode.D)
	bildrutor(12)
	local efter = kurs(h7)
	styrTryck(Enum.KeyCode.D, Enum.UserInputState.End)
	prova("styrningen svanger INTE hasten bakom replayen",
		math.abs(efter - fore) < 0.001,
		("kurs %.3f -> %.3f grader"):format(fore, efter))
	ReplayController.stang()
end

--[[ == EFTERRITTENS SUMMERING VISAS BARA VID GILTIG AVSITTNING ======

	Teaching Loop. En summering efter en ritt man avslutat ar en
	beloning; samma summering efter en respawn ar forvirrande — och
	efter en riven rigg ar den en yta som ligger kvar over ett ekipage
	som inte finns.

	`dismount` bar darfor ett skal, och `avbryt` slapper bara igenom
	«avsittning». Provet matar bada riktningarna, for en grind som bara
	provats at ena hallet ar ingen grind. ]]
do
	print("")
	print("-- Efterritt: summeringen ar grindad --")

	UgnetaController.dolj()
	prova("ytan ar tom innan provet", UgnetaController.vantar() == false)

	--[[ AVBROTT: respawn, riven rigg, serverns egen rattelse. Tyst. ]]
	LektionController.avbryt("avbrott")
	prova("ett avbrott ger INGEN summering",
		UgnetaController.vantar() == false,
		tostring(UgnetaController.vantar()))

	--[[ Utan skal alls ska det ocksa vara tyst: en ny anropare som
	     glommer argumentet far tystnad, inte en felaktig summering. ]]
	LektionController.avbryt()
	prova("utan skal ger det ocksa tystnad",
		UgnetaController.vantar() == false,
		tostring(UgnetaController.vantar()))

	--[[ Och sa ytan sjalv: far den punkter reser den ett besked med en
	     knapp, far den inga sager den ingenting. ]]
	UgnetaController.efterritt({})
	prova("en tom summering reser ingen yta",
		UgnetaController.vantar() == false)

	UgnetaController.efterritt({
		{ dim = "balans", sort = "battre" },
		{ dim = "mjukhet", sort = "kvar" },
	})
	prova("tva punkter reser ett besked med en knapp",
		UgnetaController.vantar() == true,
		tostring(UgnetaController.vantar()))
	UgnetaController.dolj()
end

--[[ == SUMMERINGEN FOLJER SERVERNS JA, INTE SPELARENS TRYCK ========

	QA-review av `082062c`, blockerare 1.

	Ordningen i `begarAvsittning` ar medveten: klienten river LOKALT
	forst och fragar servern sedan, sa att ett langsamt svar aldrig
	lamnar lararytan uppe over en spelare som bett om att fa sitta av.
	Sakerhet fore undervisning.

	Men rivningen ar inte samma sak som att ritten AVSLUTADES. Servern
	kan neka: `pass.rider_inte`, `hast.oregistrerad`, och `Skopa.grind`
	lagger till `takt.for_snabbt`. Inget av de tre KASTAR, sa `pcall`
	svarar `true` — och summeringen visades anda. En nekad avsittning
	presenterades som en fullbordad ritt.

	── EN FALLGROP SOM FORSTA VERSIONEN AV DET HAR PROVET GICK I ─────

	`UgnetaController.vantar()` ar SANT direkt efter uppsittning: da
	star lektionskortet uppe. Matte man bara «vantar() efter trycket»
	sa var svaret `true` i alla tre armarna — bade nejen och jaet — och
	provet hade varit gront for att det inte kunde se nagon skillnad.

	Ytan tvingas darfor tom omedelbart fore trycket, och att den ar tom
	kontrolleras. Forst da betyder `vantar() == true` efterat att just
	summeringen reste sig. ]]
do
	print("")
	print("-- Efterritten kraver serverns ja --")

	local dr = Net.get("DismountRequest")
	local originalHandlare = dr.OnServerInvoke

	--[[ Ett underlag som SAKERT ger minst en punkt: samma matning
	     forbattrad fran 0.20 till 0.90 over tva forsok, alltsa langt
	     over `KVALITET.BATTRE` (0.045). Blir summeringen tom mater
	     provet ingenting, och da ar bada armarna gronna av fel skal. ]]
	local function nyttUnderlag()
		return { provovning = {
			{ rytm = 0.20, balans = 0.20, mjukhet = 0.20 },
			{ rytm = 0.90, balans = 0.90, mjukhet = 0.90 },
		} }
	end

	--[[ Handlaren maste fangas FORE trycket: `dismount` river ritten och
	     `UnbindAction(Input.AVSITT)` tar bort bindningen pa vagen. ]]
	local function sittAv(): boolean
		local fn = CAS._bound[Input.AVSITT]
		if fn == nil then return false end
		fn(Input.AVSITT, Enum.UserInputState.Begin, {})
		return true
	end

	--[[ En ritt med underlag, och en TOM yta att mata mot. Returnerar
	     hasten sa att armen kan stada efter sig. ]]
	local function riddenRittMedUnderlag(): Model
		local h = nyRitt()
		local pass = LektionController.pass()
		if pass then pass.historik = nyttUnderlag() end
		UgnetaController.dolj()
		return h
	end

	--[[ KONTROLLEN FORST. Utan den kan en tyst arm nedan betyda «grinden
	     holl» ELLER «det fanns inget att visa», och de tva far inte ga
	     att blanda ihop. ]]
	do
		local h = riddenRittMedUnderlag()
		prova("KONTROLL: ytan ar tom fore matningen",
			UgnetaController.vantar() == false)
		local punkter = LektionController.avbryt("avsittning")
		prova("KONTROLL: underlaget ger faktiskt en summering",
			punkter ~= nil and #punkter > 0,
			("punkter=%d"):format(if punkter then #punkter else -1))
		prova("och `avbryt` VISAR den inte langre sjalv",
			UgnetaController.vantar() == false,
			tostring(UgnetaController.vantar()))
		h:Destroy()
	end

	--[[ ARM 1 — SERVERN NEKAR med tjanstens eget skal. ]]
	do
		local h = riddenRittMedUnderlag()
		dr.OnServerInvoke = function() return false, "pass.rider_inte" end
		prova("ytan ar tom nar trycket sker", UgnetaController.vantar() == false)
		prova("avsittningen gick att trycka", sittAv() == true)
		prova("en NEKAD avsittning ger INGEN summering",
			UgnetaController.vantar() == false,
			("vantar=%s"):format(tostring(UgnetaController.vantar())))
		prova("men ritten ar anda riven — sakerhet fore undervisning",
			LektionController.pagar() == false,
			("pagar=%s"):format(tostring(LektionController.pagar())))
		h:Destroy()
	end

	--[[ ARM 2 — `takt.for_snabbt`. Skopans nej ser annorlunda ut an
	     tjanstens och kommer fran ett annat stalle i kedjan; en grind som
	     bara provats mot det ena nejet ar provad mot halva kontraktet. ]]
	do
		local h = riddenRittMedUnderlag()
		dr.OnServerInvoke = function() return false, "takt.for_snabbt" end
		sittAv()
		prova("skopans nej ger heller ingen summering",
			UgnetaController.vantar() == false,
			("vantar=%s"):format(tostring(UgnetaController.vantar())))
		h:Destroy()
	end

	--[[ ARM 3 — SERVERN SAGER JA. Nu, och forst nu, far ritten sitt
	     avslut. Utan den har armen vore grinden uppfylld av en klient
	     som aldrig summerar alls. ]]
	do
		local h = riddenRittMedUnderlag()
		dr.OnServerInvoke = function() return true end
		sittAv()
		prova("ETT JA FRAN SERVERN GER SUMMERINGEN",
			UgnetaController.vantar() == true,
			("vantar=%s"):format(tostring(UgnetaController.vantar())))
		h:Destroy()
	end

	UgnetaController.dolj()
	dr.OnServerInvoke = originalHandlare
end

--[[ == DAGSFORMEN FAR KOMMA EFTER UPPSITTNINGEN ====================

	Re-review runda 2, blockerare 3.

	Servern satter attributet `Dagsform` fore den fyrar `MountChanged`.
	Det racker inte: attributreplikering och en RemoteEvent ar tva olika
	kanaler, och deras inbordes ordning ar inte garanterad hos
	mottagaren. Kom handelsen forst las `satHast` ett `nil` — och
	eftersom vardet bara lastes EN gang var dagsformen okand hela ritten.

	Felet var TYST. `hastensEgen` svarar `nil` pa okant och tiger, sa
	ingenting sag fel ut; hon hade bara aldrig sagt «det dar kom fran
	henne», inte ens nar det gjorde det.

	Provet monterar darfor i den DALIGA ordningen med flit: hasten far
	inget attribut nar `MountChanged` gar, och det satts forst efterat. ]]
do
	print("")
	print("-- Dagsformen far komma efter uppsittningen --")

	local h = __makeHastModell("Dagsformshast")
	h:SetAttribute("RidSession", "ritt-dagsform-1")
	h.Parent = workspace
	--[[ INGET `Dagsform` satt an. Det ar hela poangen. ]]
	Net.get("MountChanged").OnClientEvent:Fire(h, player)
	bildrutor(1)

	prova("vid uppsittningen ar dagsformen OKAND",
		LektionController.dagsform() == nil,
		tostring(LektionController.dagsform()))

	--[[ …och sa landar attributet, en stund senare. ]]
	h:SetAttribute("Dagsform", 0.30)
	bildrutor(1)
	prova("EN SENARE DAGSFORM NAR ANDA FRAM TILL UGNETA",
		LektionController.dagsform() == 0.30,
		tostring(LektionController.dagsform()))

	--[[ ── LACKAN SYNS FORST MOT NASTA HAST ─────────────────────

		Forsta versionen satte attributet pa den AVSUTTNA hasten och
		kollade att kontexten inte tog det. Den var gron aven med
		rivningen borttagen: efter avsittningen ar `hastKontext` nil,
		sa `satDagsform` skriver ingenstans anda. Provet matte inget.

		Skadan uppstar forst nar det finns en NY kontext att skriva i.
		En kvarlevande lyssnare pa hast A skulle da lagga A:s dagsform
		i B:s kontext — spelaren far veta att B har en dalig dag fast
		det ar A som har det. ]]
	Net.get("MountChanged").OnClientEvent:Fire(h, nil)
	bildrutor(1)

	local h2 = __makeHastModell("Dagsformshast2")
	h2:SetAttribute("RidSession", "ritt-dagsform-2")
	h2:SetAttribute("Dagsform", 0.80)
	h2.Parent = workspace
	Net.get("MountChanged").OnClientEvent:Fire(h2, player)
	bildrutor(1)
	prova("nasta hast bar sin EGEN dagsform",
		LektionController.dagsform() == 0.80,
		tostring(LektionController.dagsform()))

	--[[ …och sa rors den GAMLA hastens attribut. ]]
	h:SetAttribute("Dagsform", 0.10)
	bildrutor(1)
	prova("EN AVSUTTEN HAST SKRIVER INTE I NASTA RITTS KONTEXT",
		LektionController.dagsform() == 0.80,
		tostring(LektionController.dagsform()))

	Net.get("MountChanged").OnClientEvent:Fire(h2, nil)
	bildrutor(1)
	h2:Destroy()
	h:Destroy()
end

--[[ == RITTENS RAKNARE OVERLEVER EN ATERFORENING ====================

	Re-review runda 2, blockerare 1.

	Nar servern nekar en avsittning skickar den `MountChanged` tillbaka
	med spelaren som ryttare — `HorseService.aterforena`. Klientens
	lyssnare satte da upp en HELT NY ritt med `ridSekvens = 0`.

	Servern hade inte nollat nagot. Den nekade ju. `session.sekvens` stod
	kvar pa N, och regeln ar `sekvens > session.sekvens`, sa varje
	foljande hjalp kastades TYST. Hasten slutade svara pa DRIV och BROMS.

	`ride` ar en local i `init.client` och provet lagger ingen krok i
	produktionskoden for att na den. Sekvensen gar anda att lasa: den
	foljer med varje `RidingIntent` pa traden. ]]
do
	print("")
	print("-- Rittens raknare overlever en aterforening --")

	local dr = Net.get("DismountRequest")
	local originalHandlare = dr.OnServerInvoke
	local intent = Net.get("RidingIntent")

	local function sistaSekvens(): number?
		local sista = nil
		for _, paket in ipairs(intent._skickat or {}) do
			local n = tonumber(paket[3])
			if n then sista = n end
		end
		return sista
	end

	local h = nyRitt()
	intent._skickat = {}
	--[[ Passets IDENTITET, inte bara «pagar det ett pass». En
	     aterforening som startar om lektionen ger ett NYTT pass med
	     samma svar pa `pagar()`, sa den fragan kan inte skilja dem at.
	     Tabellreferensen kan. ]]
	LektionController.fortsatt()
	bildrutor(1)
	local passFore = LektionController.pass()
	prova("det pagar ett pass innan avsittningen", passFore ~= nil)

	--[[ Tre hjalper, med spärren utvantad mellan varje. ]]
	for _ = 1, 3 do
		gaTiden(Input.IMPULS_SPARR + 0.05)
		drivTryck()
		bildrutor(1)
	end
	local fore = sistaSekvens()
	prova("hon har hunnit skicka nagra hjalper",
		fore ~= nil and fore >= 2, tostring(fore))

	--[[ SERVERN NEKAR, och aterforenar sedan precis som
	     `HorseService.aterforena` gor: `MountChanged` med henne sjalv. ]]
	dr.OnServerInvoke = function() return false, "takt.for_snabbt" end
	local fn = CAS._bound[Input.AVSITT]
	prova("avsittningen gick att trycka", fn ~= nil)
	if fn then fn(Input.AVSITT, Enum.UserInputState.Begin, {}) end
	Net.get("MountChanged").OnClientEvent:Fire(h, player)
	bildrutor(1)

	gaTiden(Input.IMPULS_SPARR + 0.05)
	drivTryck()
	bildrutor(1)
	local efter = sistaSekvens()
	prova("RAKNAREN FORTSATTER — DEN BORJAR INTE OM PA 1",
		efter ~= nil and fore ~= nil and efter > fore,
		("fore=%s  efter=%s"):format(tostring(fore), tostring(efter)))

	--[[ OCH LEKTIONEN AR SAMMA LEKTION. Utan den har raden var
	     «lektionstillstandet nollstalls inte» ett pastaende utan matning:
	     en falsifiering som tog bort aterupptagandet gav ingen rod rad
	     alls. Passet ar en tabell, och samma ritt ska ge samma tabell. ]]
	prova("LEKTIONEN FORTSATTER — DET AR SAMMA PASS, INTE ETT NYTT",
		LektionController.pass() == passFore and passFore ~= nil,
		("samma=%s"):format(tostring(LektionController.pass() == passFore)))
	--[[ …och kortet star inte uppe igen. Ett nytt pass hade lagt sig i
	     lage «ny» och pausat ritten bakom en presentation hon redan
	     kvitterat. ]]
	prova("och lektionskortet reser sig inte pa nytt",
		LektionController.vantar() == false,
		tostring(LektionController.vantar()))

	dr.OnServerInvoke = originalHandlare
	UgnetaController.dolj()
	h:Destroy()
end

--[[ == ATERFORENINGEN KAN BEHOVA MER AN ETT FORSOK ==================

	Robustness Slice G.

	Klienten river ritten INNAN `DismountRequest` svarat. Nekar servern
	skickar den `MountChanged(model, player)` tillbaka. Men `mount` gav
	upp tyst om `RigAdapter.build` foll — och da stod klienten avsutten
	medan servern hade en levande ritt. Ingen vag tillbaka.

	Riggen kan vara tillfalligt ofullstandig i just det ogonblicket:
	replikeringen av en modells delar ar inte atomar, och
	aterforeningen kommer ofta mitt i.

	PROVET GAR GENOM PRODUKTIONENS LYSSNARE. `RigAdapter.build` byts ut
	av provet sjalvt — ingen krok i produktionskoden — och stalls
	tillbaka efterat. ]]
do
	print("")
	print("-- Aterforeningen kan behova mer an ett forsok --")

	local riktigBygg = RigAdapter.build
	local dr = Net.get("DismountRequest")
	local originalHandlare = dr.OnServerInvoke
	local intent = Net.get("RidingIntent")

	local function sistaSekvens(): number?
		local sista = nil
		for _, paket in ipairs(intent._skickat or {}) do
			local n = tonumber(paket[3])
			if n then sista = n end
		end
		return sista
	end

	--[[ Lat bygget falla de N forsta gangerna, sedan slappa igenom. ]]
	local function byggFallerNGanger(n)
		local kvar = n
		RigAdapter.build = function(m)
			if kvar > 0 then
				kvar -= 1
				return nil, "provets riggfel"
			end
			return riktigBygg(m)
		end
	end

	local function nekaAvsittning()
		dr.OnServerInvoke = function() return false, "takt.for_snabbt" end
	end

	local function sittAv()
		local fn = CAS._bound[Input.AVSITT]
		if fn then fn(Input.AVSITT, Enum.UserInputState.Begin, {}) end
	end

	--[[ ── EN TRANSIENT RIGG LAKER ──────────────────────────────── ]]
	do
		local h = nyRitt()
		h:SetAttribute("RiderUserId", player.UserId)
		local marke = h:GetAttribute("RidSession")
		LektionController.fortsatt()
		bildrutor(1)

		intent._skickat = {}
		for _ = 1, 3 do
			gaTiden(Input.IMPULS_SPARR + 0.05)
			drivTryck()
			bildrutor(1)
		end
		local foreSekvens = sistaSekvens()
		prova("hon har en sekvens igang", foreSekvens ~= nil and foreSekvens >= 2,
			tostring(foreSekvens))
		local passFore = LektionController.pass()

		--[[ Servern nekar, och riggen ar trasig de tva forsta
		     forsoken — sedan lakar den. ]]
		nekaAvsittning()
		byggFallerNGanger(2)
		sittAv()
		prova("ritten ar riven efter det lokala nejet",
			LektionController.pagar() == false)

		--[[ …och sa kommer serverns aterforening. ]]
		Net.get("MountChanged").OnClientEvent:Fire(h, player)
		bildrutor(2)
		RigAdapter.build = riktigBygg

		prova("OMFORSOKET SATTE UPP HENNE IGEN",
			LektionController.pagar() == true,
			tostring(LektionController.pagar()))
		prova("och det ar SAMMA rittmarke",
			h:GetAttribute("RidSession") == marke, tostring(marke))
		prova("och SAMMA pass — ingen andra lektion",
			LektionController.pass() == passFore)

		gaTiden(Input.IMPULS_SPARR + 0.05)
		drivTryck()
		bildrutor(1)
		local efterSekvens = sistaSekvens()
		prova("OCH SEKVENSEN FORTSATTER — INGEN ETTA",
			efterSekvens ~= nil and foreSekvens ~= nil and efterSekvens > foreSekvens,
			("fore=%s efter=%s"):format(tostring(foreSekvens), tostring(efterSekvens)))
		h:Destroy()
	end

	--[[ ── SERVERNS FAKTA HAR ANDRATS ────────────────────────────── ]]
	do
		local h = nyRitt()
		h:SetAttribute("RiderUserId", player.UserId)
		LektionController.fortsatt()
		bildrutor(1)
		nekaAvsittning()
		byggFallerNGanger(99)
		sittAv()
		--[[ Nagon ANNAN har tagit henne innan omforsoket hinner. ]]
		h:SetAttribute("RiderUserId", player.UserId + 1)
		Net.get("MountChanged").OnClientEvent:Fire(h, player)
		bildrutor(2)
		RigAdapter.build = riktigBygg
		prova("EN ANNAN RYTTARE STOPPAR OMFORSOKET",
			LektionController.pagar() == false,
			tostring(LektionController.pagar()))
		h:Destroy()
	end

	do
		local h = nyRitt()
		h:SetAttribute("RiderUserId", player.UserId)
		LektionController.fortsatt()
		bildrutor(1)
		nekaAvsittning()
		byggFallerNGanger(99)
		sittAv()
		h:SetAttribute("RidSession", "ett-annat-marke")
		Net.get("MountChanged").OnClientEvent:Fire(h, player)
		bildrutor(2)
		RigAdapter.build = riktigBygg
		prova("ETT ANNAT RITTMARKE STOPPAR OMFORSOKET",
			LektionController.pagar() == false,
			tostring(LektionController.pagar()))
		h:Destroy()
	end

	--[[ ── SERVERN SAGER ATT HON STIGIT AV ───────────────────────── ]]
	do
		local h = nyRitt()
		h:SetAttribute("RiderUserId", player.UserId)
		LektionController.fortsatt()
		bildrutor(1)
		nekaAvsittning()
		byggFallerNGanger(99)
		sittAv()

		__schemaPa(true)
		Net.get("MountChanged").OnClientEvent:Fire(h, player)
		--[[ Omforsoket ligger i kon. NU sager servern att ingen rider. ]]
		Net.get("MountChanged").OnClientEvent:Fire(h, nil)
		RigAdapter.build = riktigBygg
		__schemaTomKo()
		__schemaPa(false)

		prova("EN AUKTORITATIV AVSITTNING AVBRYTER OMFORSOKET",
			LektionController.pagar() == false,
			tostring(LektionController.pagar()))
		h:Destroy()
	end

	--[[ ── DUBBLA PAKET GER INTE TVA LOOPAR ──────────────────────── ]]
	do
		local h = nyRitt()
		h:SetAttribute("RiderUserId", player.UserId)
		LektionController.fortsatt()
		bildrutor(1)
		nekaAvsittning()
		local byggForsok = 0
		RigAdapter.build = function()
			byggForsok += 1
			return nil, "provets riggfel"
		end
		sittAv()

		__schemaPa(true)
		Net.get("MountChanged").OnClientEvent:Fire(h, player)
		Net.get("MountChanged").OnClientEvent:Fire(h, player)
		Net.get("MountChanged").OnClientEvent:Fire(h, player)
		local kvar = __schemaKvar()
		__schemaTomKo()
		__schemaPa(false)
		RigAdapter.build = riktigBygg

		prova("TRE PAKET GER EN ENDA LOOP", kvar == 1,
			("%d tradar i kon"):format(kvar))
		--[[ …och den loopen ar BUNDEN. Tre samtidiga hade gett tre
		     ganger sa manga byggforsok. ]]
		prova("OCH DEN AR BUNDEN", byggForsok > 0 and byggForsok <= 16,
			("%d byggforsok"):format(byggForsok))

		local sagt = 0
		for _, rad in ipairs(__varningar) do
			--[[ ASCII-bit ur varningen. Lua har ingen \u-escape, och en
			     literal med a-ring i provet ar latt att stava fel.
			     "MISSLYCKADES efter" ar unikt for just den raden. ]]
			if string.find(rad, "MISSLYCKADES efter", 1, true) then
				sagt += 1
			end
		end
		prova("OCH DEN LAMNAR EN EGEN, LETBAR RAD", sagt >= 1,
			("%d rader"):format(sagt))
		h:Destroy()
	end

	RigAdapter.build = riktigBygg
	dr.OnServerInvoke = originalHandlare
	UgnetaController.dolj()
end

if fel > 0 then
	print(("\nKLIENT-LEKTIONSPAUS: %d fel"):format(fel))
	error(("%d fel"):format(fel))
end
print("\nKLIENT-LEKTIONSPAUS: alla gröna")
