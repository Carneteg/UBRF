--!nostrict
--[[
	SESSIONSKEDJAN: BÖRJA, SLUTA, BÖRJA OM (#264, FIRST PLAYABLE SESSION).

	Tre fel ur produktägarens spelbarhetsgranskning, alla i samma
	livscykel och alla med samma form: klienten och servern tappar bort
	varandra, och spelaren blir sittande utan väg tillbaka.

	  1. FÖRSTA UPPSITTNINGEN FICK INGEN ÅTERHÄMTNING.
	     `startaAterforening` returnerade när det inte redan fanns en
	     `avbrutenRitt` för hästen. Den posten skrivs bara i `dismount`,
	     så den finns per definition inte vid den FÖRSTA uppsittningen.
	     En häst vars rigg är halvreplikerad gav alltså ett enda
	     byggförsök och sedan ingenting — spelaren står kvar bredvid en
	     häst som servern säger att hon rider.

	  2. ETT FELANDE AVSITTNINGSANROP REV KONTROLLERNA PERMANENT.
	     `begarAvsittning` river lokalt FÖRE `InvokeServer`. Kastade
	     anropet blev det bara `warn` och `return`. Men ett kastat anrop
	     betyder att servern kanske aldrig behandlade begäran — då kommer
	     ingen `MountChanged` som rättar oss, och DRIV är borta för gott.

	  3. ETT GAMMALT JA ÖPPNADE SUMMERINGEN UNDER EN NY RITT.
	     Den väntande coroutinen i `begarAvsittning` bar med sig ritt A:s
	     summering och visade den utan att fråga vilken ritt som pågår
	     NU. Ett fördröjt `true` från A la alltså upp A:s efterritt över
	     ritt B.

	VAD PROVET MÄTER, OCH VAD DET INTE GÖR. Allt går genom de riktiga
	vägarna: `MountChanged` som servern fyrar den, CAS-handlaren för
	AVSITT som tangenten når den, och `RigAdapter.build` som den
	faktiskt faller — en modell utan `Humanoid` ger
	«Saknar Humanoid (rekommenderat) eller AnimationController», inte ett
	påhittat fel. Det här är stubbad Luau-evidens. Det är INTE verklig
	motor, verkligt nät eller device-acceptans.

	Kör: python3 roblox/tests/build.py tests/klient-sessionskedja.spec.luau
	     && luau roblox/tests/.build/klient-sessionskedja.spec.luau ]]

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

local nu = 1000
Input._klocka = function() return nu end
local function gaTiden(sek) nu += sek end

local hastNr = 0

--[[ En häst som servern anser att SPELAREN rider: rittmärke och ryttare
     satta, modellen i världen. Ingen uppsittning ännu. ]]
local function nyHast(): Model
	hastNr += 1
	gaTiden(Input.IMPULS_SPARR + 0.05)
	local h = __makeHastModell("Sessionshast" .. hastNr)
	h:SetAttribute("RidSession", "ritt-session-" .. hastNr)
	h:SetAttribute("RiderUserId", player.UserId)
	h.Parent = workspace
	return h
end

--[[ RIGGEN GÖRS OFULLSTÄNDIG PÅ RIKTIGT. Ingen krok i RigAdapter: vi tar
     bort `Humanoid`, precis som en halvreplikerad modell saknar den, och
     låter adaptern falla på sin egen rad. ]]
local function rivHumanoid(h: Model)
	local hum = h:FindFirstChildOfClass("Humanoid")
	if hum then hum:Destroy() end
	return hum
end

local function aterstallHumanoid(h: Model)
	local hum = Instance.new("Humanoid")
	hum.Name = "Humanoid"
	hum.WalkSpeed = 0
	function hum:Move() end
	function hum:GetState() return Enum.HumanoidStateType.Running end
	function hum:ChangeState() end
	hum.Parent = h
	local anim = Instance.new("Animator")
	anim.Name = "Animator"
	anim.Parent = hum
	return hum
end

local function sittAv()
	local fn = CAS._bound[Input.AVSITT]
	if fn then fn(Input.AVSITT, Enum.UserInputState.Begin, {}) end
	return fn ~= nil
end

local dr = Net.get("DismountRequest")

print("\n══ 1. FÖRSTA UPPSITTNINGEN MED EN SEN RIGG ═══════════════════")
do
	local h = nyHast()
	rivHumanoid(h)

	--[[ Servern säger att hon sitter upp. Riggen går inte att bygga än. ]]
	__schemaPa(true)
	Net.get("MountChanged").OnClientEvent:Fire(h, player)
	bildrutor(1)
	prova("REPRODUKTION: den halva riggen gav ingen ritt",
		LektionController.pagar() == false,
		tostring(LektionController.pagar()))

	--[[ Delarna kommer fram. Nu SKA återhämtningen sätta upp henne. ]]
	aterstallHumanoid(h)
	__schemaTomKo()
	bildrutor(2)
	prova("SENA DELAR GER ÄNDÅ EN FÖRSTA RITT",
		LektionController.pagar() == true,
		tostring(LektionController.pagar()))
	__schemaPa(false)
	h:Destroy()
	bildrutor(1)
end

print("\n══ 1b. DEN INITIALA ÅTERHÄMTNINGEN VÄCKER INGET DÖTT ═══════")
do
	--[[ Fel 1:s rättelse öppnar en NY väg in i `mount`: den första
	     uppsittningen går nu genom samma bundna omförsök som en
	     återupptagen ritt. Slice G bevisade vakterna på den gamla vägen.
	     Här bevisas de på den nya — annars vore rättelsen en oprovad
	     ingång. Riggen läker i varje arm, så det enda som kan stoppa
	     uppsittningen är vakten. ]]
	local function koadInitialAterhamtning(): Model
		local h = nyHast()
		rivHumanoid(h)
		__schemaPa(true)
		Net.get("MountChanged").OnClientEvent:Fire(h, player)
		bildrutor(1)
		aterstallHumanoid(h)
		return h
	end

	local function stadaEfter(h: Model)
		__schemaTomKo()
		bildrutor(1)
		__schemaPa(false)
		if h.Parent then h:Destroy() end
		bildrutor(1)
	end

	do
		local h = koadInitialAterhamtning()
		h:SetAttribute("RiderUserId", player.UserId + 7)
		__schemaTomKo()
		bildrutor(2)
		prova("EN ANNAN RYTTARE STOPPAR DEN INITIALA ÅTERHÄMTNINGEN",
			LektionController.pagar() == false,
			tostring(LektionController.pagar()))
		stadaEfter(h)
	end

	do
		local h = koadInitialAterhamtning()
		h:SetAttribute("RidSession", "ett-annat-marke")
		__schemaTomKo()
		bildrutor(2)
		prova("ETT ANNAT RITTMÄRKE STOPPAR DEN",
			LektionController.pagar() == false,
			tostring(LektionController.pagar()))
		stadaEfter(h)
	end

	do
		local h = koadInitialAterhamtning()
		--[[ Modellen tas ur världen. `model.Parent ~= nil` räcker inte —
		     se fynd 1 i Slice G-reviewen; vakten frågar efter medlemskap. ]]
		local mapp = Instance.new("Folder")
		mapp.Name = "Bortkopplad"
		mapp.Parent = workspace
		h.Parent = mapp
		mapp.Parent = nil
		__schemaTomKo()
		bildrutor(2)
		prova("EN MODELL UTANFÖR VÄRLDEN STOPPAR DEN",
			LektionController.pagar() == false,
			tostring(LektionController.pagar()))
		prova("och hästen hade hela tiden en egen förälder",
			h.Parent == mapp, tostring(h.Parent))
		__schemaPa(false)
		h:Destroy()
		mapp:Destroy()
		bildrutor(1)
	end

	do
		local h = koadInitialAterhamtning()
		--[[ SERVERN HAR ÅTERKALLAT UPPSITTNINGEN. Ingen rider henne. ]]
		Net.get("MountChanged").OnClientEvent:Fire(h, nil)
		__schemaTomKo()
		bildrutor(2)
		prova("EN ÅTERKALLAD UPPSITTNING STOPPAR DEN",
			LektionController.pagar() == false,
			tostring(LektionController.pagar()))
		stadaEfter(h)
	end

	--[[ KONTROLLEN SIST: utan den kan alla fyra tystnader betyda att den
	     initiala återhämtningen aldrig fungerar i den här uppställningen. ]]
	do
		local h = koadInitialAterhamtning()
		__schemaTomKo()
		bildrutor(2)
		prova("KONTROLL: orörd auktoritet sätter upp henne",
			LektionController.pagar() == true,
			tostring(LektionController.pagar()))
		stadaEfter(h)
	end
end

print("\n══ 2. ETT KASTAT AVSITTNINGSANROP ════════════════════════════")
do
	local h = nyHast()
	Net.get("MountChanged").OnClientEvent:Fire(h, player)
	bildrutor(1)
	prova("hon rider", LektionController.pagar() == true)

	--[[ Anropet KASTAR. Servern kan mycket väl ha kvar henne uppsutten. ]]
	local originalHandlare = dr.OnServerInvoke
	dr.OnServerInvoke = function() error("natet foll") end

	--[[ SCHEMAT PÅ FÖRE TRYCKET. Utan det körs `task.spawn` synkront i
	     bänken, hela försoningen hinner klart inne i själva trycket, och
	     mätningen av rivningen skulle avläsa ett tillstånd som redan
	     passerat. Första versionen av blocket gjorde precis det och blev
	     röd fast koden var rätt. ]]
	__schemaPa(true)
	prova("AVSITT var bunden", sittAv() == true)
	bildrutor(1)
	prova("ritten är lokalt riven efter kastet — säkerhet före allt",
		LektionController.pagar() == false,
		tostring(LektionController.pagar()))
	prova("och kontrollerna är borta så länge",
		CAS._bound[Input.AVSITT] == nil)

	--[[ Servern har henne kvar. Klienten ska ta reda på det och komma
	     tillbaka i sadeln — inte stå kvar utan kontroller. ]]
	__schemaTomKo()
	bildrutor(2)
	prova("KLIENTEN FÖRSONAS MOT SERVERNS SANNING EFTER ETT KAST",
		LektionController.pagar() == true,
		tostring(LektionController.pagar()))
	prova("och AVSITT är bunden igen",
		CAS._bound[Input.AVSITT] ~= nil)
	__schemaPa(false)

	dr.OnServerInvoke = originalHandlare
	h:Destroy()
	bildrutor(1)
end

print("\n══ 3. ETT GAMMALT JA UNDER EN NY RITT ════════════════════")
do
	--[[ UNDERLAGET MÅSTE FINNAS, annars är provet grönt av fel skäl:
	     `Ugneta.efterrittFor` svarar `nil` när historiken är tom, och
	     `visaEfterritt(nil)` är tyst. Första versionen av det här blocket
	     var precis så grön — den mätte att ingenting fanns att visa, inte
	     att en vakt höll. Samma injektion som `klient-lektionspaus`. ]]
	local function nyttUnderlag()
		return { provovning = {
			{ rytm = 0.20, balans = 0.20, mjukhet = 0.20 },
			{ rytm = 0.90, balans = 0.90, mjukhet = 0.90 },
		} }
	end

	local function riddenRittMedUnderlag(): Model
		local h = nyHast()
		Net.get("MountChanged").OnClientEvent:Fire(h, player)
		bildrutor(1)
		local pass = LektionController.pass()
		if pass then pass.historik = nyttUnderlag() end
		UgnetaController.dolj()
		return h
	end

	local originalHandlare = dr.OnServerInvoke

	--[[ KONTROLLEN FÖRST. Utan den kan tystnaden nedan betyda antingen
	     «vakten höll» eller «ingenting kunde någonsin visas». ]]
	do
		local h = riddenRittMedUnderlag()
		prova("KONTROLL: ytan är tom före mätningen",
			UgnetaController.vantar() == false)
		dr.OnServerInvoke = function() return true end
		__schemaPa(true)
		sittAv()
		__schemaTomKo()
		bildrutor(2)
		prova("KONTROLL: ett giltigt avslut VISAR sin summering",
			UgnetaController.vantar() == true,
			tostring(UgnetaController.vantar()))
		__schemaPa(false)
		UgnetaController.dolj()
		dr.OnServerInvoke = originalHandlare
		h:Destroy()
		bildrutor(1)
	end

	--[[ Ritt A:s svar HÅLLS. Coroutinen står och väntar i produktionskoden. ]]
	local slappA
	local a = riddenRittMedUnderlag()
	prova("ritt A pågår med underlag",
		LektionController.pagar() == true
		and LektionController.pass() ~= nil)

	dr.OnServerInvoke = function()
		local slapp = false
		slappA = function() slapp = true end
		while not slapp do task.wait() end
		return true
	end

	__schemaPa(true)
	sittAv()
	__schemaSteg()
	bildrutor(1)
	prova("A:s avsittning väntar på servern",
		slappA ~= nil and LektionController.pagar() == false,
		("vantar=%s pagar=%s"):format(tostring(slappA ~= nil),
			tostring(LektionController.pagar())))

	--[[ RITT B BÖRJAR. Kortet kvitteras så att ytan är tom. ]]
	dr.OnServerInvoke = originalHandlare
	local b = nyHast()
	Net.get("MountChanged").OnClientEvent:Fire(b, player)
	bildrutor(1)
	LektionController.fortsatt()
	UgnetaController.dolj()
	bildrutor(1)
	prova("ritt B pågår och ytan är tom",
		LektionController.pagar() == true and UgnetaController.vantar() == false,
		("pagar=%s vantar=%s"):format(tostring(LektionController.pagar()),
			tostring(UgnetaController.vantar())))

	--[[ Nu släpper A:s ja. Det hör till en avslutad ritt som inte är den
	     som pågår, och får inte lägga upp något över B. ]]
	if slappA then slappA() end
	__schemaTomKo()
	bildrutor(2)
	prova("A:S SUMMERING ÖPPNAS INTE ÖVER B",
		UgnetaController.vantar() == false,
		tostring(UgnetaController.vantar()))
	prova("och B rider vidare orörd",
		LektionController.pagar() == true,
		tostring(LektionController.pagar()))
	__schemaPa(false)

	dr.OnServerInvoke = originalHandlare
	a:Destroy()
	b:Destroy()
	bildrutor(1)
end

print("\n══ 4. ORDNINGEN MELLAN HÄNDELSERNA ════════════════════════")
--[[ ChatGPT-review av `f4cecb8`. Rättelserna ovan höll för de fel de
     skrevs mot, men fyra ordningsfall gick förbi dem. Alla fyra kör mot
     den riktiga `init.client`-modulen med simulerad leveransordning. ]]

--[[ ── 4a. EN ÅTERKALLELSE SOM HINNER FÖRE ETT KAST ──────────────────

	Servern säger att INGEN rider henne, och FÖRST därefter körs undantags-
	grenen i avsittningen. Modellens attribut är kvar från före — de är
	cachade, inte sanna — så varje vakt släpper igenom och klienten satte
	upp sig själv på en häst servern redan tagit ifrån henne.
	`avbrytAterforening` rörde bara en redan startad återförening, och här
	hade ingen hunnit starta. ]]
do
	local h = nyHast()
	Net.get("MountChanged").OnClientEvent:Fire(h, player)
	bildrutor(1)
	prova("hon rider", LektionController.pagar() == true)

	local originalHandlare = dr.OnServerInvoke
	dr.OnServerInvoke = function() error("natet foll") end

	__schemaPa(true)
	sittAv()
	bildrutor(1)
	--[[ ÅTERKALLELSEN KOMMER FÖRST. Kastets gren har inte körts än. ]]
	Net.get("MountChanged").OnClientEvent:Fire(h, nil)
	bildrutor(1)
	__schemaTomKo()
	bildrutor(2)
	prova("EN ÅTERKALLELSE FÖRE KASTET STOPPAR ÅTERFÖRENINGEN",
		LektionController.pagar() == false,
		tostring(LektionController.pagar()))
	prova("och attributen är fortfarande kvar — det är poängen",
		h:GetAttribute("RiderUserId") == player.UserId,
		tostring(h:GetAttribute("RiderUserId")))
	__schemaPa(false)

	dr.OnServerInvoke = originalHandlare
	h:Destroy()
	bildrutor(1)
end

--[[ ── 4b. EN NY RITT PÅ SAMMA HÄST ────────────────────────────────

	`avbrutenRitt` överlever en avslutad ritt. Sitter spelaren upp på
	SAMMA häst igen, med ett nytt rittmärke, valde återhämtningen det
	GAMLA märket ur posten i stället för modellens nuvarande `RidSession`.
	Attributet är serverns sanning; posten är bara reserv för det som
	ännu inte replikerat. ]]
do
	local h = nyHast()
	local forstaMarket = h:GetAttribute("RidSession")
	Net.get("MountChanged").OnClientEvent:Fire(h, player)
	bildrutor(1)
	prova("ritt 1 pågår", LektionController.pagar() == true)

	local originalHandlare = dr.OnServerInvoke
	dr.OnServerInvoke = function() return true end
	sittAv()
	bildrutor(2)
	prova("och är avslutad", LektionController.pagar() == false)
	dr.OnServerInvoke = originalHandlare
	UgnetaController.dolj()

	--[[ NY RITT PÅ SAMMA HÄST, nytt märke. Riggen är sen en bildruta. ]]
	local andraMarket = "ritt-session-nytt-marke"
	h:SetAttribute("RidSession", andraMarket)
	rivHumanoid(h)
	__schemaPa(true)
	Net.get("MountChanged").OnClientEvent:Fire(h, player)
	bildrutor(1)
	aterstallHumanoid(h)
	__schemaTomKo()
	bildrutor(2)
	prova("EN NY RITT PÅ SAMMA HÄST ÅTERHÄMTAS MOT SITT EGET MÄRKE",
		LektionController.pagar() == true,
		tostring(LektionController.pagar()))
	prova("och märkena var verkligen olika",
		forstaMarket ~= andraMarket,
		("%s -> %s"):format(tostring(forstaMarket), tostring(andraMarket)))
	__schemaPa(false)
	h:Destroy()
	bildrutor(1)
end

--[[ ── 4c. IDENTITETEN REPLIKERAR SENT ─────────────────────────────

	Servern har redan auktoriserat uppsittningen genom att fyra händelsen.
	Men `RidSession` och `RiderUserId` har inte kommit fram än, och
	riggen saknar `Humanoid`. Återhämtningen returnerade direkt på ett
	`marke == nil` och köade ingenting alls — kontrollerna startade
	aldrig. Väntan ska vara bunden och identiteten får inte hittas på:
	första observationen av `RidSession` blir märket, och därefter gäller
	vakterna oförändrat. ]]
do
	hastNr += 1
	local h = __makeHastModell("Senidentitet" .. hastNr)
	h.Parent = workspace
	rivHumanoid(h)
	prova("REPRODUKTION: varken märke eller ryttare har replikerat",
		h:GetAttribute("RidSession") == nil
		and h:GetAttribute("RiderUserId") == nil)

	__schemaPa(true)
	Net.get("MountChanged").OnClientEvent:Fire(h, player)
	bildrutor(1)
	prova("ingen ritt ännu", LektionController.pagar() == false)

	--[[ Allt kommer fram. ]]
	h:SetAttribute("RidSession", "ritt-sen-identitet")
	h:SetAttribute("RiderUserId", player.UserId)
	aterstallHumanoid(h)
	__schemaTomKo()
	bildrutor(2)
	prova("SEN IDENTITET GER ÄNDÅ EN RITT",
		LektionController.pagar() == true,
		tostring(LektionController.pagar()))
	__schemaPa(false)
	h:Destroy()
	bildrutor(1)
end

--[[ ── 4d. KARAKTÄREN FÖRSVINNER MEDAN SVARET ÄR I LUFTEN ──────────

	`CharacterRemoving` anropar `dismount("avbrott")`, som returnerar
	direkt eftersom den begärda avsittningen redan nollat `ride`.
	`sessionGen` rörde sig alltså inte, och min egen vakt vinkade igenom
	den gamla summeringen. ]]
do
	local function nyttUnderlag()
		return { provovning = {
			{ rytm = 0.20, balans = 0.20, mjukhet = 0.20 },
			{ rytm = 0.90, balans = 0.90, mjukhet = 0.90 },
		} }
	end
	local h = nyHast()
	Net.get("MountChanged").OnClientEvent:Fire(h, player)
	bildrutor(1)
	local pass = LektionController.pass()
	if pass then pass.historik = nyttUnderlag() end
	UgnetaController.dolj()
	prova("ritten har underlag och ytan är tom",
		pass ~= nil and UgnetaController.vantar() == false)

	local originalHandlare = dr.OnServerInvoke
	local slapp
	dr.OnServerInvoke = function()
		local ute = false
		slapp = function() ute = true end
		while not ute do task.wait() end
		return true
	end

	__schemaPa(true)
	sittAv()
	__schemaSteg()
	bildrutor(1)
	prova("svaret är i luften", slapp ~= nil)

	--[[ KARAKTÄREN DÖR. Ingen lokal ritt finns kvar att riva. ]]
	player.CharacterRemoving:Fire(player.Character)
	bildrutor(1)

	if slapp then slapp() end
	__schemaTomKo()
	bildrutor(2)
	prova("EN DÖD KARAKTÄR GÖR DET VÄNTANDE SVARET INERT",
		UgnetaController.vantar() == false,
		tostring(UgnetaController.vantar()))
	__schemaPa(false)

	dr.OnServerInvoke = originalHandlare
	UgnetaController.dolj()
	h:Destroy()
	bildrutor(1)
end

print("\n══ 5. HÄNDELSER FÖR ANDRA HÄSTAR, OCH SENA FÄLT ══════════")
--[[ Uppföljningsreview av `b9a1362`. Två luckor kvar i 4a och 4c. ]]

--[[ ── 5a. EN ORELATERAD HÄST FÅR INTE RADERA VÅR ÅTERKALLELSE ─────

	`MountChanged` går ut med `FireAllClients` (`HorseService:516`), så
	klienten får beskedet om VARJE häst — inte bara sin egen. Jag band
	ogiltigförklaringen till ett enda fält med motiveringen att spelaren
	har en häst i taget. Det är sant om vad hon RIDER och irrelevant för
	vad hon får för händelser: ett besked om häst B skrev över
	återkallelsen av häst A, och sedan återauktoriserade B en återhämtning
	av A mot A:s gamla attribut. ]]
do
	local a = nyHast()
	local b = nyHast()
	Net.get("MountChanged").OnClientEvent:Fire(a, player)
	bildrutor(1)
	prova("hon rider A", LektionController.pagar() == true)

	local originalHandlare = dr.OnServerInvoke
	dr.OnServerInvoke = function() error("natet foll") end

	__schemaPa(true)
	sittAv()
	bildrutor(1)
	--[[ Återkallelsen av A kommer först... ]]
	Net.get("MountChanged").OnClientEvent:Fire(a, nil)
	bildrutor(1)
	--[[ ...och sedan ett HELT ORELATERAT besked om B. ]]
	Net.get("MountChanged").OnClientEvent:Fire(b, nil)
	bildrutor(1)
	__schemaTomKo()
	bildrutor(2)
	prova("EN ANNAN HÄSTS BESKED RADERAR INTE ÅTERKALLELSEN AV A",
		LektionController.pagar() == false,
		tostring(LektionController.pagar()))
	prova("och A:s attribut är fortfarande gamla — det är poängen",
		a:GetAttribute("RiderUserId") == player.UserId,
		tostring(a:GetAttribute("RiderUserId")))
	__schemaPa(false)

	dr.OnServerInvoke = originalHandlare
	a:Destroy()
	b:Destroy()
	bildrutor(1)
end

--[[ ── 5b. RYTTAREN ANLÄNDER SOM ANDRA FÄLT ────────────────────────

	Väntan gällde bara `RidSession`. Fanns märket men inte `RiderUserId`
	föll vakten direkt och loopen tog slut på första Heartbeat. Min egen
	rapport påstod att båda fälten kunde komma sent; koden bar inte det
	påståendet. Ett SAKNAT fält ska behandlas som «har inte replikerat
	än» inom samma budget — ett FRÄMMANDE värde stoppar fortfarande.

	HUR DET LEVERERAS, och varför. Bänkens `Heartbeat:Wait()` returnerar
	0 utan att lämna tråden, så hela återhämtningsloopen kör klart inuti
	ett enda schemasteg. Ett attribut som sätts EFTER draneringen kommer
	alltså alltid för sent, och ett som sätts före är inte «sent» alls —
	första versionen av det här blocket mätte därför ingenting. Provet
	räknar i stället väntevarven och levererar fältet vid ett bestämt
	varv. Bara bänkens egen `Wait` byts ut; ingen produktionskod rörs. ]]
local riktigWait = RunService.Heartbeat.Wait

--[[ Levererar `varde` som `RiderUserId` vid väntevarv `vidVarv`. ]]
local function medSentFalt(h: Model, vidVarv: number, varde: any, fn)
	local varv = 0
	RunService.Heartbeat.Wait = function(self)
		varv += 1
		if varv == vidVarv then h:SetAttribute("RiderUserId", varde) end
		return 0
	end
	fn()
	RunService.Heartbeat.Wait = riktigWait
	return varv
end

do
	hastNr += 1
	local h = __makeHastModell("Senryttare" .. hastNr)
	h:SetAttribute("RidSession", "ritt-sen-ryttare")
	h.Parent = workspace
	rivHumanoid(h)
	prova("REPRODUKTION: märket finns, ryttaren saknas",
		h:GetAttribute("RidSession") ~= nil
		and h:GetAttribute("RiderUserId") == nil)

	local varv = medSentFalt(h, 2, player.UserId, function()
		__schemaPa(true)
		Net.get("MountChanged").OnClientEvent:Fire(h, player)
		bildrutor(1)
		aterstallHumanoid(h)
		__schemaTomKo()
		bildrutor(2)
		__schemaPa(false)
	end)
	prova("EN SEN RYTTARE VÄNTAS IN INOM BUDGETEN",
		LektionController.pagar() == true,
		("pagar=%s efter %d vantevarv"):format(
			tostring(LektionController.pagar()), varv))
	prova("och den kom verkligen efter första varvet",
		varv >= 2, ("%d varv"):format(varv))
	h:Destroy()
	bildrutor(1)
end

--[[ ── 5c. MEN EN FRÄMMANDE ÄGARE STOPPAR FORTFARANDE ──────────────

	Kontrollen som gör 5b meningsfull: att vänta in ett SAKNAT fält får
	inte bli att vänta bort ett fält som säger nej. Samma leverans, samma
	varv — bara ett annat användar-id. ]]
do
	hastNr += 1
	local h = __makeHastModell("Frammandeagare" .. hastNr)
	h:SetAttribute("RidSession", "ritt-frammande")
	h.Parent = workspace
	rivHumanoid(h)

	medSentFalt(h, 2, player.UserId + 5, function()
		__schemaPa(true)
		Net.get("MountChanged").OnClientEvent:Fire(h, player)
		bildrutor(1)
		aterstallHumanoid(h)
		__schemaTomKo()
		bildrutor(2)
		__schemaPa(false)
	end)
	prova("EN FRÄMMANDE ÄGARE STOPPAR ÄNDÅ",
		LektionController.pagar() == false,
		tostring(LektionController.pagar()))
	h:Destroy()
	bildrutor(1)
end

print("")
if fel > 0 then
	print(("SESSIONSKEDJAN: %d FEL"):format(fel))
	error("sessionskedjan foll")
end
--[[ SLUTRADEN AR ETT KONTRAKT mot `kor.sh`: den letar efter
     "alla gröna" och tolkar franvaron som en KRASCH. ]]
print("SESSIONSKEDJAN: alla gröna")
