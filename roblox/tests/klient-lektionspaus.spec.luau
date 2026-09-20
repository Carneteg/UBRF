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

if fel > 0 then
	print(("\nKLIENT-LEKTIONSPAUS: %d fel"):format(fel))
	error(("%d fel"):format(fel))
end
print("\nKLIENT-LEKTIONSPAUS: alla gröna")
