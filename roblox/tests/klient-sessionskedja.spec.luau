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

print("")
if fel > 0 then
	print(("SESSIONSKEDJAN: %d FEL"):format(fel))
	error("sessionskedjan foll")
end
--[[ SLUTRADEN AR ETT KONTRAKT mot `kor.sh`: den letar efter
     "alla gröna" och tolkar franvaron som en KRASCH. ]]
print("SESSIONSKEDJAN: alla gröna")
