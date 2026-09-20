--!nostrict
--[[
	ETT FJÄRROBJEKT SOM REDAN FINNS SKA ÅTERANVÄNDAS, INTE DUBBLERAS.

	ROBLOX_RUNTIME_ROUTING_ACCEPTANCE, mätt i Studio 2026-09-20 i placen
	`106030782437053`, Play-läge, på head `f508f69`:

	    ReplicatedStorage-barn med namnet MinHast      2
	    PreparationHello:InvokeServer()                svar på 0,06 s
	    MinHast:InvokeServer()                         återvände ALDRIG
	                                                   (5,01 s, inget fel)

	`ReplicatedStorage` är en del av den SPARADE placen. Skapar en tjänst
	sitt fjärrobjekt med `Instance.new` i stället för att återanvända det
	som redan ligger där, får placen två objekt med samma namn — Roblox
	kräver inte unika syskonnamn. `FindFirstChild` svarar med det FÖRSTA,
	alltså den sparade kopian, som ingen satte `OnServerInvoke` på. En
	`RemoteFunction` utan handlare svarar inte; den yieldar för evigt.

	`Networking.get` gjorde redan rätt. `StallService.start` gjorde det
	inte, och `MinHast` är den enda klientanropade fjärrfunktionen som
	ligger utanför `Networking`.

	KONTROLLMÄTNINGEN ÄR HALVA BEVISET. Att ett anrop hänger kan lika
	gärna vara bänken, nätet eller harnessen. `PreparationHello` går
	genom samma klient-VM, samma `Skopa.grind` och samma
	`OnServerInvoke` — och svarade direkt. Skillnaden var dubbletten.

	Provet mäter TRE saker, och ordningen är avsiktlig:

	  1. att starten inte lägger till ett andra objekt,
	  2. att handlaren hamnar på det objekt som REDAN LÅG DÄR — det är
	     det klienten hittar, och ett prov som bara räknar till ett hade
	     varit grönt även om tjänsten rivit det gamla och lagt ett nytt
	     som klienten inte har någon referens till,
	  3. att objektet SVARAR, alltså att kedjan är hel och inte bara att
	     ett fält är satt.

	Kör: python3 roblox/tests/build.py tests/fjarrdublett.spec.luau
	     && luau roblox/tests/.build/fjarrdublett.spec.luau
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

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

--[[ Hur många barn i ReplicatedStorage som bär namnet. `FindFirstChild`
     duger inte: den svarar med ETT även när det finns fem, och det är
     precis den blindheten som lät felet leva. ]]
local function antalMedNamn(namn)
	local n = 0
	for _, b in ipairs(RS:GetChildren()) do
		if b.Name == namn then n += 1 end
	end
	return n
end

local function taBortAlla(namn)
	for _, b in ipairs(RS:GetChildren()) do
		if b.Name == namn then b:Destroy() end
	end
end

local function nySpelare()
	return { Name = "QA", UserId = 9263,
		CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }
end

print("")
print("FJÄRRDUBLETT — MinHast får inte bli två (ROBLOX_RUNTIME_ROUTING)")

--[[ ══ EN TOM PLACE ═══════════════════════════════════════════════════

	Utgångsläget: ingen `MinHast` finns. Tjänsten ska skapa EN. ]]
print("\n── En place utan MinHast ──")

do
	taBortAlla("MinHast")
	Players.PlayerAdded:nollstall()
	Players.PlayerRemoving:nollstall()
	RunService._server = true
	Players._spelare = {}
	SparService._glomHookarForProv()

	check("utgångsläget har ingen MinHast", antalMedNamn("MinHast") == 0,
		tostring(antalMedNamn("MinHast")))

	SparService.start()
	StallService.start()

	check("starten skapar exakt EN", antalMedNamn("MinHast") == 1,
		tostring(antalMedNamn("MinHast")))
	local skapad = RS:FindFirstChild("MinHast")
	check("och den är en RemoteFunction",
		skapad ~= nil and skapad.ClassName == "RemoteFunction",
		skapad and skapad.ClassName or "saknas")
	check("och den har en handlare",
		skapad ~= nil and type(skapad.OnServerInvoke) == "function")
end

--[[ ══ EN PLACE SOM REDAN BÄR OBJEKTET ════════════════════════════════

	Det verkliga fallet. Någon sparade placen efter en Play-session, och
	fjärrfunktionen ligger kvar i filen. ]]
print("\n── En sparad place som redan bär MinHast ──")

do
	taBortAlla("MinHast")
	Players.PlayerAdded:nollstall()
	Players.PlayerRemoving:nollstall()
	RunService._server = true
	Players._spelare = {}
	SparService._glomHookarForProv()

	--[[ Den sparade kopian. Namnet är satt FÖRE `Parent`, precis som
		Roblox laddar en sparad place: objektet finns med sitt namn när
		det dyker upp i trädet. ]]
	local sparad = Instance.new("RemoteFunction")
	sparad.Name = "MinHast"
	sparad.Parent = RS
	check("placen bär redan en MinHast utan handlare",
		antalMedNamn("MinHast") == 1 and type(sparad.OnServerInvoke) ~= "function")

	SparService.start()
	StallService.start()

	check("starten lägger INTE till en andra", antalMedNamn("MinHast") == 1,
		tostring(antalMedNamn("MinHast")))
	--[[ Punkt 2: handlaren ska sitta på den som LÅG DÄR. Klienten har
		ingen annan referens. ]]
	check("handlaren hamnar på det objekt som redan låg där",
		type(sparad.OnServerInvoke) == "function")
	check("och FindFirstChild hittar just det objektet",
		RS:FindFirstChild("MinHast") == sparad)

	--[[ Punkt 3: att den SVARAR. Ett satt fält är inte en hel kedja. ]]
	local sp = nySpelare()
	SparService._glomForProv(sp)
	Players._spelare = { sp }
	Players.PlayerAdded:Fire(sp)
	Players.PlayerAdded:slutfor()

	local ok, svar = pcall(function() return sparad.OnServerInvoke(sp) end)
	check("objektet klienten hittar SVARAR", ok == true and svar ~= nil,
		if not ok then tostring(svar)
		elseif svar == nil then "svarade nil" else tostring(svar.id))
	check("och svaret är spelarens tilldelade häst",
		ok and svar ~= nil and svar.id == StallService.hastIdFor(sp),
		ok and svar ~= nil and tostring(svar.id) or "-")
end

--[[ ══ FEL KLASS UNDER SAMMA NAMN ══════════════════════════════════════

	En trasig place är inte något att bygga vidare på. Att lägga ett
	andra objekt bredvid hade återskapat exakt dubblettfelet, så det
	felklassade rivs. ]]
print("\n── Fel klass under namnet MinHast ──")

do
	taBortAlla("MinHast")
	Players.PlayerAdded:nollstall()
	Players.PlayerRemoving:nollstall()
	RunService._server = true
	Players._spelare = {}
	SparService._glomHookarForProv()

	local fel = Instance.new("RemoteEvent")
	fel.Name = "MinHast"
	fel.Parent = RS

	SparService.start()
	StallService.start()

	check("fortfarande bara ETT objekt med namnet", antalMedNamn("MinHast") == 1,
		tostring(antalMedNamn("MinHast")))
	local nu = RS:FindFirstChild("MinHast")
	check("och det är en RemoteFunction",
		nu ~= nil and nu.ClassName == "RemoteFunction",
		nu and nu.ClassName or "saknas")
	check("det felklassade objektet är rivet, inte kvarlämnat", nu ~= fel)
	check("och den nya har en handlare",
		nu ~= nil and type(nu.OnServerInvoke) == "function")
end

if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("\nfjarrdublett.spec: alla gröna")
end
