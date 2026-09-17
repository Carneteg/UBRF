--!nostrict
--[[
	LEDNINGENS KNAPP OCH DESS TILLSTÅND (#182).

	Human-QA på #182 sa två saker som inte gick att se i någon grind:

	  1. knapparna på hästen låg PÅ VARANDRA — `Sitt upp`, `Rida nu` och
	     `Led hästen` ritas alla på riggens rot eller sadelpunkt, alltså
	     inom någon decimeter, och spelaren läste bara den översta;
	  2. det gick inte att se ATT man ledde. Enda skillnaden mellan
	     "leder" och "leder inte" var att en knapptext bytt ord.

	Den här specen mäter båda, och den mäter dem på det controllern
	FAKTISKT bygger — inte på en avskrift av layouten.

	VAD SOM INTE MÄTS HÄR: hur det ser ut i Studio. Bänken har ingen
	rendering. Att 64 px verkligen känns åtskilt för en tumme är en
	mänsklig grind och står som sådan i PR-texten.

	Kör: python3 roblox/tests/build.py tests/klient-ledprompt.spec.luau
	     && luau roblox/tests/.build/klient-ledprompt.spec.luau
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

local Taggar = game:GetService("CollectionService")
local RSt = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local IC = InteractionController

--[[ En häst med den rigg `RigAdapter` behöver: rot, humanoid, taggen. ]]
local function nyHast(namn, visningsnamn)
	local m = Instance.new("Model")
	m.Name = namn
	m:SetAttribute("HorseId", namn)
	if visningsnamn then m:SetAttribute("HorseName", visningsnamn) end
	local rot = Instance.new("Part")
	rot.Name = "HumanoidRootPart"
	rot.Size = Vector3.new(1.86, 2.34, 5.55)
	rot.Parent = m
	m.PrimaryPart = rot
	local hum = Instance.new("Humanoid")
	hum.Name = "Humanoid"
	hum.Parent = m
	m.Parent = workspace
	Taggar:AddTag(m, "Horse")
	return m
end

local function promptar(modell)
	local ut = {}
	for _, d in ipairs(modell:GetDescendants()) do
		if d.Name == "MountPrompt" or d.Name == "LedPrompt" or d.Name == "RidaNuPrompt" then
			ut[d.Name] = d
		end
	end
	return ut
end

--[[ Fjärrobjekten skapas bara på servern; bänken är klient. Samma knep
	som forberedelse.spec använder. ]]
RunService._server = true
Networking.get("MountRequest")
Networking.get("LedBorja")
Networking.get("LedSlapp")
Networking.get("LedSync")
RunService._server = false

RSt:SetAttribute("G01Enabled", true)
IC.setReadyCheck(function() return true end)
IC.setLedCheck(function() return true end)
IC.setRidaCheck(function() return true end)

--[[ Kvittenser och statusrad fångas här i stället för att gå till HUD:en,
	så att provet mäter VAD som skickas och inte hur det ritas. ]]
local kvittenser = {}
IC.setBekraftelseVisare(function(text) table.insert(kvittenser, tostring(text)) end)
local status = { namn = nil, antal = 0 }
IC.setLedStatus(function(model)
	status.namn = if model then tostring(model:GetAttribute("HorseName") or model.Name) else nil
	status.antal += 1
end)

local hast = nyHast("trixie", "Trixie")
IC.uppdatera()
local p = promptar(hast)

print("\n── Tre knappar, tre platser ──")

do
	check("alla tre knapparna byggdes samtidigt",
		p.MountPrompt ~= nil and p.LedPrompt ~= nil and p.RidaNuPrompt ~= nil,
		("mount %s · rida %s · led %s"):format(
			tostring(p.MountPrompt ~= nil), tostring(p.RidaNuPrompt ~= nil),
			tostring(p.LedPrompt ~= nil)))

	if p.MountPrompt and p.LedPrompt and p.RidaNuPrompt then
		local y = {
			mount = p.MountPrompt.UIOffset.Y,
			rida = p.RidaNuPrompt.UIOffset.Y,
			led = p.LedPrompt.UIOffset.Y,
		}
		--[[ DET HÄR ÄR PROVET SOM SAKNADES. Låg alla tre på 0 var de
			ritade på samma punkt, och det var precis vad human-QA såg. ]]
		local unika = {}
		for _, v in pairs(y) do unika[v] = true end
		local antal = 0
		for _ in pairs(unika) do antal += 1 end
		check("de tre ligger på tre OLIKA höjder", antal == 3,
			("mount %d · rida %d · led %d"):format(y.mount, y.rida, y.led))

		--[[ 44 px är golvet för en träffyta i KONTROLLMATRIS regel 5, och
			en ProximityPrompt är tryckbar med finger. Två knappar
			närmare än så går inte att träffa var för sig. ]]
		local par = {
			{ "mount", "rida", math.abs(y.mount - y.rida) },
			{ "rida", "led", math.abs(y.rida - y.led) },
			{ "mount", "led", math.abs(y.mount - y.led) },
		}
		local trangt = {}
		for _, x in ipairs(par) do
			if x[3] < 44 then table.insert(trangt, ("%s×%s=%d"):format(x[1], x[2], x[3])) end
		end
		check("inget par ligger närmare än 44 px", #trangt == 0,
			table.concat(trangt, " "))

		--[[ ORDNINGEN ÄR PRODUKTORDNING: sitt upp överst, rida nu i
			mitten, den frivilliga omsorgen underst. Ett negativt
			UIOffset.Y är uppåt. ]]
		check("ordningen är sitt upp → rida nu → led, uppifrån och ned",
			y.mount < y.rida and y.rida < y.led,
			("%d < %d < %d"):format(y.mount, y.rida, y.led))
	end
end

print("\n── Tangent, finger och handkontroll ──")

do
	if p.MountPrompt and p.LedPrompt and p.RidaNuPrompt then
		local alla = { p.MountPrompt, p.RidaNuPrompt, p.LedPrompt }
		local ejKlick = {}
		for _, x in ipairs(alla) do
			if x.ClickablePrompt ~= true then table.insert(ejKlick, x.Name) end
		end
		check("alla tre går att trycka på med ett finger", #ejKlick == 0,
			table.concat(ejKlick, ", "))

		--[[ Delade knappar på handkontrollen är samma fel som delad plats
			på skärmen: spelaren kan inte välja.

			DEN HÄR MÄTNINGEN RÄCKTE INTE, och det är hela skälet till
			avsnittet «Handkontrollen mot HELA kontrollmatrisen» längst ned.
			Tre knappar kan vara olika VARANDRA och ändå vara «se ritten»,
			«lektionen vidare» och «halvhalt» — vilket var precis vad de
			blev. Raden står kvar för att den mäter något verkligt; den är
			bara inte tillräcklig. ]]
		local gp = {}
		local krock = {}
		for _, x in ipairs(alla) do
			local k = tostring(x.GamepadKeyCode)
			if gp[k] then table.insert(krock, k) end
			gp[k] = true
		end
		check("de tre har var sin knapp på handkontrollen", #krock == 0,
			table.concat(krock, ", "))

		--[[ …och knapparna är DE SOM STÅR I KÄLLAN. Utan den här raden
			kunde `InteractionController.GAMEPAD` vara en dekoration som
			matrisen och provet läser medan prompterna bär något annat. ]]
		local avvik = {}
		for _, x in ipairs(alla) do
			if x.GamepadKeyCode ~= IC.GAMEPAD[x.Name] then
				table.insert(avvik, ("%s %s≠%s"):format(x.Name,
					tostring(x.GamepadKeyCode), tostring(IC.GAMEPAD[x.Name])))
			end
		end
		check("knapparna bär det GAMEPAD-tabellen säger", #avvik == 0,
			table.concat(avvik, " "))

		check("ledningen har en egen tangent (L), skild från E och R",
			tostring(p.LedPrompt.KeyboardKeyCode):find("L") ~= nil
				and tostring(p.RidaNuPrompt.KeyboardKeyCode):find("R") ~= nil,
			("led %s · rida %s"):format(tostring(p.LedPrompt.KeyboardKeyCode),
				tostring(p.RidaNuPrompt.KeyboardKeyCode)))
	end
end

print("\n── Handlingen bär hästens namn ──")

do
	if p.LedPrompt then
		check("knappen heter «Led Trixie», inte «Led hästen»",
			p.LedPrompt.ActionText == Sprak.t("led.borja_namn", "Trixie")
				and p.LedPrompt.ActionText:find("Trixie") ~= nil,
			("[%s]"):format(tostring(p.LedPrompt.ActionText)))
		check("och namnet står också på objektraden",
			p.LedPrompt.ObjectText == "Trixie",
			("[%s]"):format(tostring(p.LedPrompt.ObjectText)))
	end
end

print("\n── Leder inte → leder → leder inte ──")

do
	local led = p.LedPrompt
	local borja = Networking.get("LedBorja")
	local slapp = Networking.get("LedSlapp")
	borja.InvokeServer = function() return true end
	slapp.InvokeServer = function() return true end

	--[[ 1. UTGÅNGSLÄGET. ]]
	check("ingen häst leds vid start", IC._lederNu() == nil)
	check("statusraden är släckt", status.namn == nil)

	--[[ 2. LEDNINGEN BÖRJAR, genom knappens egen väg. ]]
	kvittenser = {}
	led.Triggered:Fire()
	task.wait()
	check("klienten vet nu vilken häst hon leder", IC._lederNu() == hast,
		tostring(IC._lederNu() and IC._lederNu().Name))
	check("knappen erbjuder att släppa Trixie",
		led.ActionText == Sprak.t("led.slapp_namn", "Trixie"),
		("[%s]"):format(tostring(led.ActionText)))
	check("den beständiga statusraden säger vem hon leder",
		status.namn == "Trixie", tostring(status.namn))
	check("och spelaren fick EN kvittens om att ledningen börjat",
		#kvittenser == 1 and kvittenser[1] == Sprak.t("led.leder", "Trixie"),
		("%d st · [%s]"):format(#kvittenser, tostring(kvittenser[1])))

	--[[ 3. LEDNINGEN SLUTAR, samma väg tillbaka. ]]
	kvittenser = {}
	led.Triggered:Fire()
	task.wait()
	check("ingen häst leds längre", IC._lederNu() == nil)
	check("knappen erbjuder att leda Trixie igen",
		led.ActionText == Sprak.t("led.borja_namn", "Trixie"),
		("[%s]"):format(tostring(led.ActionText)))
	check("statusraden är släckt igen", status.namn == nil, tostring(status.namn))
	check("och avslutet kvitterades lika tydligt som starten",
		#kvittenser == 1 and kvittenser[1] == Sprak.t("led.slutade", "Trixie"),
		("%d st · [%s]"):format(#kvittenser, tostring(kvittenser[1])))
end

print("\n── Servern får släppa kopplet utan att spelaren tryckt ──")

do
	local led = p.LedPrompt
	local sync = Networking.get("LedSync")

	--[[ Tillbaka till «leder», via knappen. ]]
	led.Triggered:Fire()
	task.wait()
	check("hon leder igen", IC._lederNu() == hast)

	--[[ Och så släpper servern: för långt bort, fastnat, satte sig upp.
		Spelaren tryckte INTE. Utan den här vägen stod knappen kvar på
		«Släpp Trixie» för ett koppel som inte fanns — det felet #204
		rättade för texten, men status och kvittens fanns inte då. ]]
	kvittenser = {}
	sync.OnClientEvent:Fire({ leder = false, hastId = nil, skal = "led.tappade_bort" })
	task.wait()
	check("serverns släpp nollar klientens uppfattning", IC._lederNu() == nil)
	check("knappen går tillbaka till «Led Trixie»",
		led.ActionText == Sprak.t("led.borja_namn", "Trixie"),
		("[%s]"):format(tostring(led.ActionText)))
	check("statusraden släcks av serverns besked", status.namn == nil)
	check("och spelaren får veta att ledningen upphörde",
		#kvittenser == 1 and kvittenser[1] == Sprak.t("led.slutade", "Trixie"),
		("%d st · [%s]"):format(#kvittenser, tostring(kvittenser[1])))
end

print("\n── En andra häst får inte ärva den förstas knapptext ──")

do
	local andra = nyHast("marabou", "Marabou")
	IC.uppdatera()
	local p2 = promptar(andra)
	check("den andra hästen fick sina egna knappar", p2.LedPrompt ~= nil)
	if p2.LedPrompt then
		check("och hennes knapp bär HENNES namn",
			p2.LedPrompt.ActionText == Sprak.t("led.borja_namn", "Marabou"),
			("[%s]"):format(tostring(p2.LedPrompt.ActionText)))

		--[[ Leder man den ena ska den ANDRA knappen inte påstå något. ]]
		p.LedPrompt.Triggered:Fire()
		task.wait()
		check("medan Trixie leds står Marabous knapp kvar på «Led Marabou»",
			p2.LedPrompt.ActionText == Sprak.t("led.borja_namn", "Marabou")
				and p.LedPrompt.ActionText == Sprak.t("led.slapp_namn", "Trixie"),
			("Marabou [%s] · Trixie [%s]"):format(
				tostring(p2.LedPrompt.ActionText), tostring(p.LedPrompt.ActionText)))
		p.LedPrompt.Triggered:Fire()
		task.wait()
	end
end

--[[ ══ HANDKONTROLLEN MOT HELA KONTROLLMATRISEN ══════════════════════════

	Blockerande fynd i senior review av `e57314e`: de tre prompterna fick
	`ButtonX`, `ButtonY` och `ButtonB`, som är «se ritten», «lektionen
	vidare» och «halvhalt». Provet ovan kunde inte se det, eftersom det
	bara jämförde de tre knapparna med varandra.

	Det här avsnittet bygger i stället HELA huvudboken ur källan och mäter
	promptknapparna mot den. Ingenting nedan är en avskrift av
	`docs/KONTROLLMATRIS.md`:

	  · ridningens knappar FYRAS genom `Input.luau`s egen bindning och
	    läses ur `Input.consume()` — både knapparna och de analoga axlarna,
	  · init.clients knappar fyras genom klientens EGEN `InputBegan` och
	    läses på vad de faktiskt anropade,
	  · hjälpens och avsittningens knappar läses ur `KontrollHjalp`, som är
	    den publika källan till just dem.

	Och kontraktet mäts i BÅDA lägena, för det är kontextregeln som bär
	`ButtonX`: knapparna på hästen lever bara på marken, ridningens reglage
	bara i sadeln.

	VAD BÄNKEN INTE KAN: den har ingen prompt-motor. Att Roblox VÄGRAR
	fyra en `Enabled = false`-prompt är enginens beteende, inte vårt — här
	mäts att flaggan är satt. Att styrkorssymbolen faktiskt ritas i
	prompten är `NOT_TESTED` och står så i PR-texten. ]]

print("\n── Handkontrollen mot HELA kontrollmatrisen ──")

do
	local Players = game:GetService("Players")
	local usv = game:GetService("UserInputService")
	local spelare = Players.LocalPlayer

	--[[ Varje knapp en handkontroll har. Listan är kandidater att PRÖVA,
		inte ett facit över vem som äger vad — ägarskapet härleds nedan. ]]
	local KANDIDATER = {
		"ButtonA", "ButtonB", "ButtonX", "ButtonY",
		"ButtonR1", "ButtonL1", "ButtonR2", "ButtonL2",
		"ButtonR3", "ButtonL3",
		"DPadUp", "DPadDown", "DPadLeft", "DPadRight",
		"ButtonStart", "ButtonSelect", "Thumbstick1", "Thumbstick2",
	}

	local function rort(i)
		return i.forward ~= 0 or i.steer ~= 0 or i.gaitUp or i.gaitDown
			or i.jump or i.rein ~= 0 or i.seat ~= 0 or i.parad ~= 0
			or i.gaitTo ~= nil
	end

	--[[ ── 1. RIDNINGENS KNAPPAR, ur Input.luau ─────────────────────────
		Varje kandidat fyras som knapp OCH som analog axel: tygeln, sitsen
		och spaken läses ur `GetGamepadState` och syns inte i bindningen. ]]
	local huvudbok = {}
	Input.bind()
	for _, namn in ipairs(KANDIDATER) do
		local kod = Enum.KeyCode[namn]

		Input.consume()
		__key(kod, true)
		local somKnapp = Input.consume()
		__key(kod, false)
		Input.consume()
		if rort(somKnapp) then huvudbok[kod] = "ridning (i sadeln)" end

		usv._pad = { { KeyCode = kod, Position = Vector3.new(1, 1, 1) } }
		local somAxel = Input.consume()
		usv._pad = {}
		Input.consume()
		if rort(somAxel) then huvudbok[kod] = "ridning (i sadeln)" end
	end
	Input.unbind()

	check("ridningens gamepadknappar gick att härleda ur Input.luau",
		huvudbok[Enum.KeyCode.ButtonA] ~= nil
			and huvudbok[Enum.KeyCode.ButtonB] ~= nil
			and huvudbok[Enum.KeyCode.ButtonR2] ~= nil
			and huvudbok[Enum.KeyCode.Thumbstick1] ~= nil,
		"(hopp, halvhalt, tygel och spak hittade)")

	--[[ ── 2. DE TVÅ SOM LÄSES UR SIN EGEN MODUL ────────────────────────
		Hjälpen och avsittningen är publika konstanter just för att de ska
		gå att läsa här. De fyras INTE i loopen nedan: avsittningen river
		ritten mitt i mätningen, och hjälpen är redan provad i
		klient.spec. ]]
	huvudbok[KontrollHjalp.GAMEPADKNAPP] = "kontrollhjälpen (lever ALLTID)"
	huvudbok[KontrollHjalp.AVSITTNING_GAMEPAD] = "avsittning (i sadeln)"

	--[[ ── 3. INIT.CLIENTS KNAPPAR, genom klientens egen InputBegan ─────
		Lektionen och ridanalysen svarar bara när något väntar, så de
		patchas till räknare. Det är inte en genväg förbi produktionen:
		anropen kommer fortfarande ur klientens lyssnare. ]]
	local LC = LektionController
	local ursprung = {
		fortsatt = LC.fortsatt, replay = LC.replay,
		gaVidare = LC.gaVidare, replayAktiv = LC.replayAktiv,
	}
	local traffad = nil
	LC.replayAktiv = function() return false end
	LC.fortsatt = function() traffad = "lektionen vidare"; return false end
	LC.replay = function() traffad = "se ritten"; return false end
	LC.gaVidare = function() traffad = "gå vidare"; return false end

	local function svepKlienten(lage)
		local funna = {}
		for _, namn in ipairs(KANDIDATER) do
			local kod = Enum.KeyCode[namn]
			--[[ Hjälpen och avsittningen hoppas över — se noten vid 2. ]]
			if kod ~= KontrollHjalp.GAMEPADKNAPP
				and kod ~= KontrollHjalp.AVSITTNING_GAMEPAD then
				traffad = nil
				usv.InputBegan:Fire({ KeyCode = kod }, false)
				if traffad then
					funna[kod] = ("%s (%s)"):format(traffad, lage)
					huvudbok[kod] = funna[kod]
				end
			end
		end
		return funna
	end

	--[[ PÅ MARKEN, alltså precis där de tre knapparna på hästen lever. ]]
	local paMarken = svepKlienten("på marken")
	local antalMark = 0
	for _ in pairs(paMarken) do antalMark += 1 end
	check("ingen av init.clients knappar svarar när spelaren står på marken",
		antalMark == 0, ("%d svarade"):format(antalMark))

	--[[ I SADELN. Uppsittningen går genom produktionens MountChanged, inte
		genom ett direktanrop av `mount`. ]]
	local bamse = __makeHastModell("Bamse")
	bamse:SetAttribute("HorseId", "bamse")
	bamse:SetAttribute("HorseName", "Bamse")
	bamse.Parent = workspace
	Taggar:AddTag(bamse, "Horse")
	IC.uppdatera()

	Networking.get("MountChanged").OnClientEvent:Fire(bamse, spelare)
	task.wait()

	local iSadeln = svepKlienten("i sadeln")
	check("«se ritten» och «lektionen vidare» svarar däremot i sadeln",
		iSadeln[Enum.KeyCode.ButtonX] ~= nil
			and iSadeln[Enum.KeyCode.ButtonY] ~= nil,
		("X %s · Y %s"):format(tostring(iSadeln[Enum.KeyCode.ButtonX]),
			tostring(iSadeln[Enum.KeyCode.ButtonY])))

	print("\n  Härledd huvudbok:")
	for _, namn in ipairs(KANDIDATER) do
		local kod = Enum.KeyCode[namn]
		if huvudbok[kod] then
			print(("    %-14s %s"):format(namn, huvudbok[kod]))
		end
	end
	print("")

	--[[ ── 4. KNAPPARNA PÅ HÄSTEN MOT HUVUDBOKEN ────────────────────────

		Regeln, i tre mätningar:

		  a) ingen promptknapp får vara RIDNINGENS — den lever i sadeln,
		     men `Input.luau` är också det lager som «halvhalt» ligger i,
		     och en promptknapp där vore exakt det blockerande fyndet,
		  b) ingen promptknapp får vara den som lever i BÅDA lägena
		     (hjälpen), för då finns ingen kontext som skiljer dem,
		  c) ingen promptknapp får svara på något medan spelaren står PÅ
		     MARKEN, alltså i det läge prompten faktiskt går att trycka. ]]
	local pa = {
		{ "sitt upp", IC.GAMEPAD.MountPrompt },
		{ "rida nu", IC.GAMEPAD.RidaNuPrompt },
		{ "led", IC.GAMEPAD.LedPrompt },
	}

	local iRidningen = {}
	for _, x in ipairs(pa) do
		if huvudbok[x[2]] == "ridning (i sadeln)" then
			table.insert(iRidningen, ("%s=%s"):format(x[1], tostring(x[2])))
		end
	end
	check("ingen knapp på hästen är en av ridningens (halvhalt, hopp, tygel…)",
		#iRidningen == 0, table.concat(iRidningen, " "))

	local motHjalpen = {}
	for _, x in ipairs(pa) do
		if x[2] == KontrollHjalp.GAMEPADKNAPP then
			table.insert(motHjalpen, x[1])
		end
	end
	check("ingen knapp på hästen är hjälpens — den enda som lever i båda lägena",
		#motHjalpen == 0, table.concat(motHjalpen, " "))

	local krockarPaMarken = {}
	for _, x in ipairs(pa) do
		if paMarken[x[2]] then
			table.insert(krockarPaMarken, ("%s→%s"):format(x[1], paMarken[x[2]]))
		end
	end
	check("ingen knapp på hästen gör något ANNAT där hon står, på marken",
		#krockarPaMarken == 0, table.concat(krockarPaMarken, " "))

	--[[ De två NYA knapparna ska vara lediga i hela huvudboken, i båda
		lägena. Bara uppsittningens `ButtonX` — Roblox eget standardvärde
		för en ProximityPrompt — delas, och den delningen bärs av
		kontextregeln som mäts i 5 nedan. ]]
	local ejLediga = {}
	for _, x in ipairs({ pa[2], pa[3] }) do
		if huvudbok[x[2]] then
			table.insert(ejLediga, ("%s=%s→%s"):format(x[1], tostring(x[2]),
				huvudbok[x[2]]))
		end
	end
	check("«rida nu» och «led» står på knappar som är lediga i HELA matrisen",
		#ejLediga == 0, table.concat(ejLediga, " "))

	check("uppsittningens delade knapp är delad med något som bara lever i sadeln",
		huvudbok[IC.GAMEPAD.MountPrompt] == nil
			or huvudbok[IC.GAMEPAD.MountPrompt]:find("i sadeln") ~= nil,
		("%s → %s"):format(tostring(IC.GAMEPAD.MountPrompt),
			tostring(huvudbok[IC.GAMEPAD.MountPrompt])))

	--[[ ── 5. KONTEXTREGELN, den som bär delningen ──────────────────────

		`setEnabled` tog förut BARA uppsittningens tabell. Led- och
		rida-knapparna stod alltså kvar påslagna i sadeln, och en
		ProximityPrompt kräver bara närhet — närmare hästen än på hennes
		rygg kommer man inte. Det gällde tangentbordet lika hårt: `R` för
		«lektionen vidare» fyrade «Rida nu» i samma tryck. ]]
	local TRE = { "MountPrompt", "RidaNuPrompt", "LedPrompt" }
	local pMin = promptar(hast)
	local kvarPa = {}
	for _, namn in ipairs(TRE) do
		--[[ En SAKNAD knapp får inte räknas som avstängd — då hade
			mätningen blivit grön av att prompten inte fanns. ]]
		if pMin[namn] == nil or pMin[namn].Enabled ~= false then
			table.insert(kvarPa, namn)
		end
	end
	check("i sadeln är ALLA tre knapparna på hästen avstängda", #kvarPa == 0,
		table.concat(kvarPa, " "))

	--[[ …också de som byggs MEDAN hon rider. `uppdatera()` körs under
		ritten, och en knapp som föds påslagen är samma hål igen. ]]
	local sen = nyHast("sent", "Senkommen")
	IC.uppdatera()
	local pSen = promptar(sen)
	local sentPa = {}
	for _, namn in ipairs(TRE) do
		if pSen[namn] and pSen[namn].Enabled ~= false then
			table.insert(sentPa, namn)
		end
	end
	check("en knapp som byggs MITT i ritten föds avstängd",
		pSen.MountPrompt ~= nil and #sentPa == 0,
		("byggd %s · påslagna: %s"):format(tostring(pSen.MountPrompt ~= nil),
			table.concat(sentPa, " ")))

	--[[ …och de tänds igen när ritten är slut. En grind som stänger utan
		att öppna är samma engångsruta som #161 rättade för hjälpen. ]]
	spelare.CharacterRemoving:Fire(spelare.Character)
	task.wait()
	local pEfter = promptar(hast)
	local slacktaEfter = {}
	for _, namn in ipairs(TRE) do
		if pEfter[namn] == nil or pEfter[namn].Enabled ~= true then
			table.insert(slacktaEfter, namn)
		end
	end
	check("och alla tre tänds igen när spelaren sitter av", #slacktaEfter == 0,
		table.concat(slacktaEfter, " "))

	LC.fortsatt, LC.replay = ursprung.fortsatt, ursprung.replay
	LC.gaVidare, LC.replayAktiv = ursprung.gaVidare, ursprung.replayAktiv
end

if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("\nklient-ledprompt.spec: alla gröna")
end
