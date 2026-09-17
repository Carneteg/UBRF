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
			på skärmen: spelaren kan inte välja. ]]
		local gp = {}
		local krock = {}
		for _, x in ipairs(alla) do
			local k = tostring(x.GamepadKeyCode)
			if gp[k] then table.insert(krock, k) end
			gp[k] = true
		end
		check("de tre har var sin knapp på handkontrollen", #krock == 0,
			table.concat(krock, ", "))

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

if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("\nklient-ledprompt.spec: alla gröna")
end
