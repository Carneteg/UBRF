--!nostrict
--[[
	FIRST RIDE (#263 Gate 2A).

	══ VAD SOM FAKTISKT KÖRS HÄR ═════════════════════════════════════

	Riktiga tjänster hela vägen: `SparService` mot den stubbade butiken,
	`StallService`s tilldelning, `GameplayService.bind`, en byggd
	`HastRigg`-modell med sits, `LedService`s målzon, `TackService`s
	fysiska utrustning och `HorseService.tryMount`. Provet anropar
	`ForstaRitten.starta` — samma funktion servern kör.

	Det spelar roll för nästan varje mätning nedan. En bänk som
	stubbade uppsittningen hade kunnat vara grön med en mount-grind som
	inte höll, och det är precis den grinden First Ride öppnar en gren
	i.

	══ VAD SOM INTE MÄTS ═════════════════════════════════════════════

	Trettio- och nittiosekundersmålen. Tiden här är en injicerad klocka,
	inte en spelares väntan, och bänken har varken Roblox-motor, nätverk
	eller en iPad. De målen är `NOT_TESTED` och avgörs av mänsklig QA.

	Det provet KAN mäta är att klockan startar på rätt ställe — att
	`spelKlar` sätts innan First Ride gör sitt arbete och inte efter.
	Det är skydd 8 i arkitekturbeslutet, och det var fel i mitt första
	utkast.

	Kör: python3 roblox/tests/build.py tests/forstaritten.spec.luau
	     && luau roblox/tests/.build/forstaritten.spec.luau
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

local FR = ForstaRitten
local Players = game:GetService("Players")

game:GetService("RunService")._server = true

--[[ ══ BÄNKENS VÄRLD ════════════════════════════════════════════════ ]]

--[[ Målzonen. Samma form `GameplayService.start` räknar fram ur
	`Komplex`, men skriven här för att provet ska äga sin geometri —
	annars mäter det anläggningens placering i stället för First Ride. ]]
local ZON = { x = 40, y = 40, w = 30, h = 20 }

local __id = 7000
local function nyKaraktar()
	local k = Instance.new("Model")
	k.Name = "Karaktar"
	local rot = Instance.new("Part")
	rot.Name = "HumanoidRootPart"
	rot.Size = Vector3.new(2, 2, 1)
	--[[ Bänkens delar har ingen CFrame förrän någon skriver en. ]]
	rot.CFrame = CFrame.new(0, 3, 0)
	rot.Parent = k
	k.PrimaryPart = rot
	local hum = Instance.new("Humanoid")
	hum.Name = "Humanoid"
	hum.Parent = k
	k.Parent = workspace
	return k, rot, hum
end

local function nySpelare(namn)
	__id += 1
	local kar = nyKaraktar()
	return { Name = namn, UserId = __id, Character = kar,
		CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }, kar
end

local nu = 0
local function ga(s) nu += s end

--[[ Var står hon? Läst ur `HumanoidRootPart` och inte ur `PrimaryPart`
	— det är den delen produktionen flyttar, och den enda bänken lovar
	finns. ]]
local function var(kar)
	local rot = kar and kar:FindFirstChild("HumanoidRootPart")
	return (rot and rot.CFrame) and rot.CFrame.Position or nil
end

--[[ Bygger en riktig rigg för det id spelaren faktiskt tilldelats, och
	registrerar den. Att läsa id:t ur tilldelningen och inte skriva av
	ett namn är samma regel som resten av bänken följer: hästen kommer
	ur rostern, inte ur provet. ]]
--[[ Hästarna provet byggt, för att kunna rivas mellan block. Utan det
	ligger förra blockets modell kvar TAGGAD i världen med samma
	`HorseId`, och `hittaModell` kan välja den i stället — en häst som
	redan har en ryttare. Felet syntes som `hast.upptagen` på en
	spelare som aldrig suttit upp. ]]
local byggda = {}

local function nyHastFor(hastId, x)
	local m = HastRigg.bygg(hastId, hastId, CFrame.new(Vector3.new(x, 0, 0)), 1.45)
	m.Parent = workspace
	--[[ TAGGEN ÄR DET `bind` LETAR EFTER. `HastRigg.bygg` bygger kroppen;
		`Horse`-taggen sätts i drift av den som ställer henne i världen,
		och utan den hittar `hittaModell` ingenting. ]]
	game:GetService("CollectionService"):AddTag(m, "Horse")
	HorseService._registerForProv(m)
	table.insert(byggda, m)
	return m
end

--[[ ── TJÄNSTERNA STARTAS EN GÅNG ───────────────────────────────────

	Och den ordningen är produktionens egen, ur `init.server.luau`:
	`SparService` först, sedan `StallService`, sedan `GameplayService`.

	Det spelar roll för mer än prydlighet. `SparService.redo` — barriären
	First Ride frågar i skydd 1 — sätts BARA av `laddaOchStarta`, alltså
	av `PlayerAdded`-vägen. Ett prov som anropade `SparService.ladda`
	rakt av hade fått `redo == false` och aldrig nått en enda mätning.
	Det var precis vad mitt första utkast gjorde. ]]
__datastore.nollstall()
SparService.start()
StallService.start()
GameplayService.start()
LedService.start()
--[[ EN GÅNG, inte per block. `SparService.efterLaddning` kör hooken
	DIREKT för alla som redan är redo — så ett andra `FR.start()` mitt i
	provet hade startat om varenda spelare från tidigare block. Det var
	precis vad som hände: `kvarvarande()` svarade 4 där provet väntade
	1. ]]
ForstaRitten.start()

local function rent()
	FR._nollstallForProv()
	FR._satKlockaForProv(function() return nu end)
	nu = 0
	--[[ LYSSNARNA RIVS INTE. `PlayerRemoving` och ryttarlyssnaren
		registrerades EN gång av tjänsternas `start()`, precis som i
		drift — river blocket dem mäter nästa block en server där
		städningen aldrig kopplades in. Det var exakt vad som hände:
		"avsittning river sessionsstatusen" föll på att provet självt
		hade tagit bort lyssnaren som gör det.

		Spelarna ur förra blocket ska däremot bort. `efterLaddning`
		läser `GetPlayers()` och kör hooken direkt för alla som är redo,
		så en kvarglömd spelare räknas in i nästa blocks mätning. ]]
	table.clear(Players._spelare)
	--[[ Och förra blockets hästar rivs ur världen. Se noten vid
		`byggda`. ]]
	for _, m in ipairs(byggda) do
		game:GetService("CollectionService"):RemoveTag(m, "Horse")
		m:Destroy()
	end
	table.clear(byggda)
	HorseService.setMountGate(GameplayService.farSittaUpp)
	GameplayService.satForstaRitten(function(p) return FR.galler(p) end)
	LedService.satMalzon(ZON)
	__varningar = {}
end

--[[ Hela uppställningen genom PRODUKTIONENS väg in: spelaren anländer,
	`PlayerAdded` driver laddningen, barriären släpper, och hookarna
	tilldelar och binder. Sedan byggs riggen för det id hon faktiskt
	fick. ]]
local function uppstallning(namn, x)
	local spelare, kar = nySpelare(namn)
	table.insert(Players._spelare, spelare)
	Players.PlayerAdded:Fire(spelare)
	local hastId = StallService.hastIdFor(spelare)
	local hast = if hastId then nyHastFor(hastId, x or 0) else nil
	--[[ Riggen taggas efter tilldelningen, så bindningen görs om nu när
		modellen finns. Samma väg `CollectionService`-lyssnaren tar i
		drift. ]]
	if hast then GameplayService.bind(spelare) end
	return spelare, kar, hast, hastId
end

print("")
print("FIRST RIDE (#263 Gate 2A)")

--[[ ══ 1. VILLKORET ÄR SERVERÄGT OCH UR BEFINTLIG SANNING ═══════════

	Acceptanskriterium 1 och 3, plus skydd 1. ]]
print("\n-- Villkoret läses ur sparningen --")
do
	rent()
	local spelare = nySpelare("Oladdad")
	--[[ SKYDD 1: en spelare som inte gått genom barriären får INTE se ut
		som pass == 0. `SparService.redo` är grinden, och den säger ja
		först när `laddaOchStarta` kört klart. ]]
	check("en spelare som inte gått genom laddningen får inte First Ride",
		FR.galler(spelare) == false)

	table.insert(Players._spelare, spelare)
	Players.PlayerAdded:Fire(spelare)
	check("men en laddad spelare utan pass får det",
		FR.galler(spelare) == true)
end

do
	rent()
	local spelare = nySpelare("Erfaren")
	table.insert(Players._spelare, spelare)
	Players.PlayerAdded:Fire(spelare)
	local save = SparService.save(spelare)
	--[[ Ett genomfört pass, genom kanonens egen väg. ]]
	Sparning.registreraPass(save, "prov-pass-1", 1)
	check("en spelare med ett genomfört pass får INTE First Ride",
		FR.galler(spelare) == false,
		("pass=%d"):format(save.pass))
end

do
	rent()
	local spelare = nySpelare("Trasig")
	table.insert(Players._spelare, spelare)
	Players.PlayerAdded:Fire(spelare)
	SparService._glomForProv(spelare)
	--[[ Glömd save = som oladdad igen. Fail closed åt rätt håll: hellre
		stallvägen än att skriva över någons progression med en
		nybörjarupplevelse. ]]
	check("en glömd save stänger First Ride",
		FR.galler(spelare) == false)
end

--[[ SKYDD 1 ISOLERAT. Blocken ovan mäter en spelare som saknar BÅDE
	save och barriär, och en mutation som tar bort barriärkontrollen
	hade därför kunnat komma ut grön — `save == nil` fångade den ändå.

	Här finns saven men inte barriären: `SparService.ladda` anropas rakt
	av, precis som mitt eget första provutkast gjorde, och `redo` sätts
	bara av `laddaOchStarta`. Det är läget "laddningen pågår", och det
	är precis det läget skydd 1 finns för. ]]
do
	rent()
	local spelare = nySpelare("Mittiladdningen")
	SparService.ladda(spelare)
	check("saven finns", SparService.save(spelare) ~= nil)
	check("men barriären har inte släppt", SparService.redo(spelare) == false)
	check("och då får hon INTE First Ride",
		FR.galler(spelare) == false)
end

--[[ ══ DE FAKTISKA SPARUTFALLEN (re-review P1-1) ══════════════════

	`redo` betyder bara att laddningen natt ett slutlage. Vid saknat
	datalager, lasfel, framtida sparfil eller en olasbar rad publicerar
	`ladda` en `Sparning.tom()` — samma nollpassbild som en verkligt ny
	spelare. Provet matte forut bara `redo=false` och `save=nil`, och
	missade alltsa hela den har klassen.

	Har provas UTFALLEN, ett i taget, genom datalagerstubben. ]]
print("\n-- Sparlasningen maste vara betrodd --")
do
	rent()
	local spelare = nySpelare("Nyspelare")
	table.insert(Players._spelare, spelare)
	Players.PlayerAdded:Fire(spelare)
	check("en verkligt ny spelare har en betrodd lasning",
		SparService.betroddLasning(spelare) == true,
		tostring(SparService.anmarkning(spelare)))
	check("och far First Ride", FR.galler(spelare) == true)
end

do
	rent()
	--[[ INGET DATALAGER. `hamtaButik` faller, och `ladda` publicerar en
		sessionssave. Den ser ut som noll pass. ]]
	SparService._glomButikForProv()
	__datastore.felButik = true
	local spelare = nySpelare("Utan datalager")
	table.insert(Players._spelare, spelare)
	Players.PlayerAdded:Fire(spelare)
	local save = SparService.save(spelare)
	check("saven ser ut som noll pass",
		save ~= nil and save.pass == 0, tostring(save and save.pass))
	check("men lasningen ar INTE betrodd",
		SparService.betroddLasning(spelare) == false,
		tostring(SparService.anmarkning(spelare)))
	check("och First Ride nekas", FR.galler(spelare) == false)
	__datastore.felButik = false
	SparService._glomButikForProv()
end

do
	rent()
	--[[ EN FRAMTIDA SPARFIL. Raden finns men ar skriven av en nyare
		version; `migrera` ger en tom save och `spar.framtida_sparfil`. ]]
	local spelare = nySpelare("Framtida")
	__datastore._data["spelare_" .. spelare.UserId] = { v = 9999, pass = 7 }
	table.insert(Players._spelare, spelare)
	Players.PlayerAdded:Fire(spelare)
	check("anmarkningen ar framtida sparfil",
		SparService.anmarkning(spelare) == "spar.framtida_sparfil",
		tostring(SparService.anmarkning(spelare)))
	check("lasningen ar inte betrodd",
		SparService.betroddLasning(spelare) == false)
	check("och First Ride nekas trots noll pass",
		FR.galler(spelare) == false)
end

do
	rent()
	--[[ EN TRASIG RAD. `kanSpara` blir SANT har — hon maste kunna komma
		vidare — men vi vet inte om hon ridit forut, och da ar
		nyborjarupplevelsen en gissning at fel hall. ]]
	local spelare = nySpelare("Trasig rad")
	__datastore._data["spelare_" .. spelare.UserId] = "inte en tabell"
	table.insert(Players._spelare, spelare)
	Players.PlayerAdded:Fire(spelare)
	check("anmarkningen ar trasig",
		SparService.anmarkning(spelare) == "trasig",
		tostring(SparService.anmarkning(spelare)))
	check("och lasningen ar inte betrodd trots att hon FAR spara",
		SparService.betroddLasning(spelare) == false
			and SparService.kanSpara(spelare) == true)
	check("First Ride nekas", FR.galler(spelare) == false)
end

do
	rent()
	--[[ EN GILTIG RAD MED NOLL PASS. Den ska SLAPPAS igenom — annars
		har rattelsen gjort First Ride omojlig for alla. ]]
	local spelare = nySpelare("Giltig nolla")
	__datastore._data["spelare_" .. spelare.UserId] =
		{ v = Sparning.VERSION, pass = 0, rev = 3 }
	table.insert(Players._spelare, spelare)
	Players.PlayerAdded:Fire(spelare)
	check("en giltig rad med noll pass ar betrodd",
		SparService.betroddLasning(spelare) == true,
		tostring(SparService.anmarkning(spelare)))
	check("och far First Ride", FR.galler(spelare) == true)
end

--[[ ══ 2. HELA VÄGEN UPP ════════════════════════════════════════════ ]]
print("\n-- En ny spelare hamnar i sadeln --")
do
	rent()
	local spelare, kar, hast, hastId = uppstallning("Nybörjare", 0)
	check("hon har fått en häst ur rostern", hast ~= nil, tostring(hastId))

	local utfall = FR.starta(spelare)
	check("First Ride går igenom", utfall.ok == true,
		("%s %s"):format(utfall.steg, tostring(utfall.skal)))
	check("och steget är uppsutten", utfall.steg == "uppsutten")

	local sits = hast and hast:FindFirstChild("RiderSeat")
	local hum = kar:FindFirstChildOfClass("Humanoid")
	check("sitsen har henne", sits ~= nil and sits.Occupant == hum)
	check("och hästen bär hennes id",
		hast:GetAttribute("RiderUserId") == spelare.UserId)

	--[[ KRITERIUM 2: hästen är FYSISKT förberedd. ]]
	check("hästen bär sadel", TackService.sadlad(hast) == true)
	check("hästen bär träns", TackService.transad(hast) == true)
	check("och är därmed ridklar i världen", (TackService.ridklar(hast)))

	--[[ …och hon står i ridhuset, inte i boxen. ]]
	local pivot = hast.PrimaryPart
	check("hästen står i målzonen",
		LedService.iRekt(pivot.Position, ZON) == true)
end

--[[ ══ 3. INGEN FALSK PROGRESSION ════════════════════════════════════

	Orderns skarpaste krav, och kriterium 2. ]]
print("\n-- Stallskötseln är INTE avbockad --")
do
	rent()
	local spelare, kar, hast, hastId = uppstallning("Obockad", 30)
	local utfall = FR.starta(spelare)
	check("hon sitter upp", utfall.ok == true, utfall.steg)

	--[[ CHECKLISTAN LÄSES UR DEN SKICKADE VYN, inte ur en provkrok.
		`PreparationSync` är samma paket klienten ritar HUD:en av, så det
		provet läser är exakt det spelaren skulle se. En uppfunnen
		testkrok hade kunnat säga något annat än gränssnittet. ]]
	local sync = Networking.get("PreparationSync")
	local sista = sync._skickat[#sync._skickat]
	local vy = sista and sista[2]
	check("en vy har skickats till henne", vy ~= nil)
	if vy ~= nil then
		check("spelarens egen checklista är fortfarande OGJORD",
			vy.redo == false, tostring(vy.redo))
		check("och hennes nästa fas finns kvar att göra",
			vy.nasta ~= nil, tostring(vy.nasta))
		local gjorda = 0
		for _, steg in ipairs(vy.steg or {}) do
			if steg.klar then gjorda += 1 end
		end
		check("ingen enda fas är avbockad", gjorda == 0,
			("%d avbockade"):format(gjorda))
	end

	--[[ Ledningen är inte heller kvitterad — hon har inte lett henne. ]]
	check("ledningen är inte bokförd som gjord",
		LedService.harNattMal(spelare) == false)
	check("och hon står inte som att hon lämnat boxen",
		LedService.harLamnatBox(spelare) == false)

	--[[ Passräknaren rörs inte av en uppsittning. ]]
	local save = SparService.save(spelare)
	check("passräknaren står kvar på noll", save.pass == 0,
		("%d"):format(save.pass))
end

--[[ ══ VÄLFÄRDSSTOPPET GÄLLER ÄVEN EN NYBÖRJARE ══════════════════

	Den skarpaste mätningen i hela specen. First Ride-grenen ersätter
	checklistan — och ingenting annat. En häst med ett fynd ska ingen
	sitta upp på, aldrig, hur ny ryttaren än är.

	Utan den här mätningen kom en mutation som tog bort `s.stoppad`-
	raden ut GRÖN i falsifieringen. Provet mätte alltså inte det
	villkor som skyddar hästen. ]]
print("\n-- Ett välfärdsstopp stoppar även First Ride --")
do
	rent()
	local spelare, kar, hast = uppstallning("Stoppad", 700)
	--[[ Fyndet sätts i spelarens EGNA tillstånd, samma väg
		`Preparation.svaraFynd` och visitationen använder. Vyn är
		serverns, så provet läser den för att bekräfta att stoppet
		faktiskt sitter. ]]
	local sync = Networking.get("PreparationSync")
	GameplayService._stoppaForProv(spelare, "Hon är öm i vänster framben")

	local utfall = FR.starta(spelare)
	check("First Ride nekas av välfärdsstoppet",
		utfall.ok == false, utfall.steg)
	check("och nejet kommer från uppsittningen, inte från något annat",
		utfall.steg == "uppsittningen_nekades", utfall.steg)
	check("hon sitter inte upp",
		hast:GetAttribute("RiderUserId") == nil,
		tostring(hast:GetAttribute("RiderUserId")))
	local _ = sync
end

--[[ ══ 4. SOLO KAN INTE FÅ forb.fel_tur ══════════════════════════════

	Kriterium 4. First Ride rör aldrig `GameplayService.moment`, så
	fasordningen kan inte neka — men det ska MÄTAS och inte antas. ]]
print("\n-- Ingen turordning kan neka --")
do
	rent()
	local spelare = uppstallning("Solo", 60)
	local utfall = FR.starta(spelare)
	check("solospelaren kommer upp", utfall.ok == true, utfall.steg)
	check("och inget svar bär forb.fel_tur",
		tostring(utfall.skal) ~= "forb.fel_tur", tostring(utfall.skal))
	local flod = 0
	for _, rad in ipairs(__varningar) do
		if string.find(rad, "fel_tur", 1, true) then flod += 1 end
	end
	check("och ingen loggrad nämner den heller", flod == 0)
end

--[[ ══ 5. ADVERSARIALT ═══════════════════════════════════════════════

	Kriterium 6 och 9. ]]
print("\n-- En manipulerad klient kommer ingenstans --")
do
	rent()
	local spelare = uppstallning("Ärlig", 90)
	--[[ En andra häst som INTE är hennes. ]]
	local annan = nyHastFor("nagon_annans_hast", 120)

	local nekad, skal = HorseService.tryMount(spelare, annan)
	check("hon kan inte sitta upp på någon annans häst",
		nekad == false, tostring(skal))
	check("och nejet är ett identitetsnej, inte ett taktnej",
		skal == "spel.inte_din_hast" or skal == "forb.inte_din_hast"
			or skal == "spel.ingen_hast", tostring(skal))

	--[[ Och First Ride öppnar inte den dörren: grenen prövar bara
		`pass.aterstar`, alltså checklistan. ]]
	check("First Ride ändrar inte det",
		FR.galler(spelare) == true and nekad == false)
end

do
	rent()
	local spelare, kar, hast = uppstallning("Fuskare", 150)
	FR.starta(spelare)
	local fore = tostring(hast:GetAttribute("Gait"))
	--[[ Gångarten går inte att skicka. `RidingIntent` bär ett ORD ur
		`Ridtrappa`, och servern äger trappan sedan #233 Fas 4b. Ett
		påhittat ord ska inte flytta någonting. ]]
	local intent = Networking.get("RidingIntent")
	local rittId = hast:GetAttribute("RittId")
	intent.OnServerEvent:Fire(spelare, rittId, "galopp", 1)
	intent.OnServerEvent:Fire(spelare, rittId, "GALOPP", 2)
	intent.OnServerEvent:Fire(spelare, rittId, 99, 3)
	intent.OnServerEvent:Fire(spelare, rittId, { hoppa = "galopp" }, 4)
	check("en påhittad gångart flyttar ingenting",
		tostring(hast:GetAttribute("Gait")) == fore,
		("%s -> %s"):format(fore, tostring(hast:GetAttribute("Gait"))))
end

--[[ ══ 6. FAIL CLOSED PÅ VÄRLDEN ═════════════════════════════════════

	Skydd 4: en spelare får aldrig teleporteras till ett trasigt läge. ]]
print("\n-- En trasig värld stoppar flödet FÖRE teleporten --")
do
	rent()
	local spelare, kar, hast = uppstallning("Sitslos", 200)
	local sits = hast:FindFirstChild("RiderSeat")
	check("riggen har en sits att ta bort", sits ~= nil)
	local fore = var(kar)
	if sits then sits:Destroy() end

	local utfall = FR.starta(spelare)
	check("en rigg utan sits stoppar flödet",
		utfall.ok == false and utfall.steg == "riggen_saknar_sits",
		utfall.steg)
	local efter = var(kar)
	check("och spelaren har INTE teleporterats",
		(efter - fore).Magnitude < 0.001,
		("flyttades %.2f studs"):format((efter - fore).Magnitude))
end

do
	rent()
	LedService.satMalzon(nil)
	local spelare, kar = uppstallning("Utan zon", 240)
	local fore = var(kar)
	local utfall = FR.starta(spelare)
	check("utan ridhuszon stoppar flödet",
		utfall.ok == false and utfall.steg == "ingen_ridhuszon", utfall.steg)
	check("och spelaren står kvar",
		(var(kar) - fore).Magnitude < 0.001)
	LedService.satMalzon(ZON)
end

--[[ ══ 7. TELEMETRIN MÄTER FRÅN RÄTT STÄLLE ═════════════════════════

	Skydd 8. Det här är mätningen som fällde mitt första utkast: där
	sattes klockan NÄR UPPSITTNINGEN LYCKATS, så tiden till första
	rörelse mätte bara sadeln → tangenttryckning och var alltid grön. ]]
print("\n-- Klockan startar innan First Ride gör sitt arbete --")
do
	rent()
	local spelare, kar, hast = uppstallning("Mätt", 280)
	nu = 100
	local utfall = FR.starta(spelare)
	check("hon sitter upp", utfall.ok == true, utfall.steg)
	local m = FR.matningFor(spelare)
	check("mätningen finns", m ~= nil)
	check("och spelKlar sattes vid startens BÖRJAN, inte efter",
		m ~= nil and m.spelKlar == 100, tostring(m and m.spelKlar))

	--[[ KANONISK SKRITT, I 0,1-SEKUNDSSTEG.

		Det har provet flyttade forst hasten TIO studs i ett enda prov,
		och det dolde en riktig defekt: troskeln jamforde mot foregaende
		prov och krävde over 15 studs/s. En skrittande hast kunde alltsa
		aldrig passera matningen, och provet var gront anda.

		Nu gar hon i kanonisk skritt — `Gaits.BY_NAME.walk.norm` m/s
		gange tre studs per meter — och provet skriver inte av en enda
		siffra. ]]
	local M = 3
	local SKRITT = Gaits.BY_NAME.walk.norm * M
	local STEG = SKRITT * FR.TAKT
	check("kanonisk skritt ar under den gamla troskeln per prov",
		STEG < 1.5, ("%.2f studs per prov"):format(STEG))

	local pivot = hast.PrimaryPart
	FR._observeraForProv()
	--[[ Tre sekunder skritt, ett prov var 0,1 s. ]]
	local prov = 0
	while m.forstaRorelse == nil and prov < 60 do
		prov += 1
		ga(FR.TAKT)
		pivot.CFrame = pivot.CFrame * CFrame.new(0, 0, -STEG)
		FR._observeraForProv()
	end
	check("servern ser en SKRITTANDE hast",
		m.forstaRorelse ~= nil,
		("%d prov (%.1f studs)"):format(prov, prov * STEG))
	check("och den ser den inom nagra sekunder",
		m.forstaRorelse ~= nil and m.forstaRorelse < 3,
		tostring(m.forstaRorelse))
	check("tiden raknas fran spelKlar",
		m.forstaRorelse ~= nil
			and math.abs(m.forstaRorelse - prov * FR.TAKT) < 0.01,
		tostring(m.forstaRorelse))
end

do
	rent()
	local spelare, kar, hast = uppstallning("Svängare", 320)
	FR.starta(spelare)
	local m = FR.matningFor(spelare)
	local pivot = hast.PrimaryPart
	FR._observeraForProv()
	--[[ REALISTISK SVANGHASTIGHET, i samma 0,1-sekundssteg.

		Forsta versionen vred hasten ett halvt radian i ETT prov — nara
		trettio grader pa en tiondel, alltsa ingenting en hast gor. Den
		matningen holl aven nar ackumuleringen saknades.

		En ridande sving ligger runt 0,5 rad/s, alltsa 0,05 rad per
		prov: UNDER trosklen, och bara synlig nar den ackumuleras. ]]
	local SVANG = 0.05
	check("ett enskilt svangsteg ar under troskeln", SVANG < 0.105)

	for _ = 1, 3 do
		ga(FR.TAKT)
		pivot.CFrame = pivot.CFrame * CFrame.Angles(0, SVANG, 0)
		FR._observeraForProv()
	end
	check("tre sma steg at vanster racker nar de ackumuleras",
		m.styrtVanster == true)
	check("men hogern ar orord", m.styrtHoger == false)

	for _ = 1, 3 do
		ga(FR.TAKT)
		pivot.CFrame = pivot.CFrame * CFrame.Angles(0, -SVANG, 0)
		FR._observeraForProv()
	end
	check("och tre sma steg at hoger syns ocksa", m.styrtHoger == true)
end

do
	rent()
	local spelare, kar, hast = uppstallning("Bromsare", 360)
	FR.starta(spelare)
	local m = FR.matningFor(spelare)
	--[[ GÅNGARTSNAMNEN LÄSES UR KANONEN. Första utkastet skrev svenska
		namn — `trav`, `skritt` — och kanonen använder engelska
		(`Gaits.SPELBAR_TOPP` är "canter"). `Gaits.index` svarade då 1 på
		allt, och nedväxlingen gick inte att se. Provet skriver inte av
		ett enda gångartsnamn längre. ]]
	local HALT, UPP = Gaits.ORDER[1], Gaits.ORDER[3]
	local NED = Gaits.ORDER[2]
	check("kanonens ordning går att läsa",
		HALT ~= nil and NED ~= nil and UPP ~= nil,
		("%s < %s < %s"):format(tostring(HALT), tostring(NED), tostring(UPP)))
	FR._observeraForProv()
	ga(3)
	hast:SetAttribute("Gait", UPP)
	FR._observeraForProv()
	check("en gångartsövergång noteras", m.forstaOvergang ~= nil,
		tostring(m.forstaOvergang))
	check("och även den räknas från spelKlar",
		m.forstaOvergang ~= nil and math.abs(m.forstaOvergang - 3) < 0.001,
		tostring(m.forstaOvergang))
	check("men bromsen är inte satt av en uppväxling", m.bromsat == false)
	hast:SetAttribute("Gait", NED)
	FR._observeraForProv()
	check("en NEDväxling räknas som broms", m.bromsat == true,
		("%s -> %s"):format(tostring(UPP), tostring(NED)))
end

do
	rent()
	check("världsbygget redovisas separat och är inte satt av sig självt",
		FR.varldsbygge() == nil)
	FR.satVarldsbygge(12.5)
	check("men går att sätta av startordningen", FR.varldsbygge() == 12.5)
	FR.satVarldsbygge(nil)
end

--[[ ══ KARAKTAREN KOMMER I DELAR (re-review P1-3) ═════════════════

	`CharacterAdded` fyrar nar modellen parentas, inte nar den ar
	komplett. `HumanoidRootPart` och `Humanoid` strommar in efterat.

	Forsta versionen startade flodet direkt: hasten flyttades,
	utrustningen byggdes, och forst `stallVidHasten` foll. Spelaren fick
	ingen ny chans forran nasta respawn, och hasten stod flyttad och
	sadlad utan ryttare.

	Karaktaren har nedan svarar `nil` pa `HumanoidRootPart` de forsta
	gangerna och lamnar sedan ut den — precis som en kropp som stromma
	in. ]]
print("\n-- Karaktaren kommer i delar --")
do
	rent()
	local spelare, kar, hast = uppstallning("Fordrojd", 900)
	local riktigRot = kar:FindFirstChild("HumanoidRootPart")
	local riktigHum = kar:FindFirstChildOfClass("Humanoid")
	check("bankens karaktar har bada delarna",
		riktigRot ~= nil and riktigHum ~= nil)

	--[[ En kropp som lamnar ut roten forst vid fjarde fragan. ]]
	local fragor = 0
	spelare.Character = {
		Name = "Fordrojd karaktar",
		FindFirstChild = function(_, namn)
			if namn ~= "HumanoidRootPart" then return nil end
			fragor += 1
			if fragor < 4 then return nil end
			return riktigRot
		end,
		FindFirstChildOfClass = function(_, klass)
			if klass == "Humanoid" then return riktigHum end
			return nil
		end,
	}

	local hastFore = hast.PrimaryPart.CFrame.Position
	local utfall = FR.starta(spelare)
	check("flodet vantar in kroppen och lyckas anda",
		utfall.ok == true, ("%s %s"):format(utfall.steg, tostring(utfall.skal)))
	check("och roten fragades flera ganger innan den fanns",
		fragor >= 4, ("%d fragor"):format(fragor))
	local _ = hastFore
end

do
	rent()
	local spelare, kar, hast = uppstallning("Aldrig klar", 940)
	--[[ En kropp som ALDRIG blir ridklar. ]]
	spelare.Character = {
		Name = "Halv karaktar",
		FindFirstChild = function() return nil end,
		FindFirstChildOfClass = function() return nil end,
	}
	local hastFore = hast.PrimaryPart.CFrame.Position
	local sadladFore = TackService.sadlad(hast)

	local utfall = FR.starta(spelare)
	check("timeouten ger ett nej med diagnostik",
		utfall.ok == false and utfall.steg == "ingen_ridklar_karaktar",
		utfall.steg)
	--[[ DET VIKTIGA: ingenting i varlden hann mutera. ]]
	check("hasten star kvar dar hon stod",
		(hast.PrimaryPart.CFrame.Position - hastFore).Magnitude < 0.001,
		("flyttades %.2f studs"):format(
			(hast.PrimaryPart.CFrame.Position - hastFore).Magnitude))
	check("ingen utrustning byggdes",
		TackService.sadlad(hast) == sadladFore
			and TackService.sadlad(hast) == false)
	check("och ingen sessionspost lamnades",
		FR.kvarvarande() == 0, ("%d"):format(FR.kvarvarande()))
end

do
	rent()
	local spelare, kar, hast = uppstallning("Kroppsbytare", 960)
	local riktigRot = kar:FindFirstChild("HumanoidRootPart")
	local riktigHum = kar:FindFirstChildOfClass("Humanoid")
	local nyKropp = nyKaraktar()
	--[[ EN RESPAWN SOM LANDAR MITT I FLODET. Kroppen svarar ridklart —
		men byter ut spelarens karaktar i samma andetag, precis som en
		respawn gor. Det arbete som just gjorts hor da till en kropp som
		inte finns langre. ]]
	spelare.Character = {
		Name = "Kropp som byts",
		FindFirstChild = function() return riktigRot end,
		FindFirstChildOfClass = function(_, klass)
			if klass ~= "Humanoid" then return nil end
			spelare.Character = nyKropp
			return riktigHum
		end,
	}
	local utfall = FR.starta(spelare)
	check("ett kroppsbyte under flodet avbryter det",
		utfall.ok == false and utfall.steg == "karaktaren_byttes",
		utfall.steg)
	check("och lamnar ingen sessionspost",
		FR.kvarvarande() == 0, ("%d"):format(FR.kvarvarande()))
end

do
	rent()
	local spelare, kar, hast = uppstallning("Dod", 980)
	local hum = kar:FindFirstChildOfClass("Humanoid")
	hum.Health = 0
	local hastFore = hast.PrimaryPart.CFrame.Position
	local utfall = FR.starta(spelare)
	check("en dod karaktar ar inte ridklar",
		utfall.ok == false and utfall.steg == "ingen_ridklar_karaktar",
		utfall.steg)
	check("och varlden ar orord",
		(hast.PrimaryPart.CFrame.Position - hastFore).Magnitude < 0.001
			and TackService.sadlad(hast) == false)
end

--[[ ══ 8. CLEANUP ════════════════════════════════════════════════════

	Kriterium 7 och skydd 6. ]]
print("\n-- Cleanup lämnar ingenting kvar --")
do
	rent()
	local spelare, kar, hast = uppstallning("Avsittare", 400)
	FR.starta(spelare)
	check("mätningen lever medan hon rider", FR.kvarvarande() == 1,
		("%d"):format(FR.kvarvarande()))

	HorseService.dismount(spelare)
	check("avsittning river sessionsstatusen",
		FR.kvarvarande() == 0, ("%d"):format(FR.kvarvarande()))
	--[[ SKYDD 6: standard är JA — hon ska kunna få First Ride igen så
		länge hon inte genomfört ett pass. ]]
	local save = SparService.save(spelare)
	check("passet är fortfarande inte genomfört", save.pass == 0)
	check("så First Ride erbjuds igen", FR.galler(spelare) == true)
end

do
	rent()
	local spelare = uppstallning("Lämnare", 440)
	FR.starta(spelare)
	check("hon håller en post", FR.kvarvarande() == 1)
	Players.PlayerRemoving:Fire(spelare)
	check("frånkoppling lämnar ingenting", FR.kvarvarande() == 0,
		("%d"):format(FR.kvarvarande()))
end

do
	rent()
	local spelare = uppstallning("Dubbel", 480)
	local ett = FR.starta(spelare)
	local tva = FR.starta(spelare)
	check("första försöket lyckas", ett.ok == true,
		("%s %s"):format(ett.steg, tostring(ett.skal)))
	--[[ SKYDD 3: dubbla livscykelsignaler får inte ge dubbel mount. ]]
	check("ett andra försök gör ingenting", tva.ok == false
		and tva.steg == "redan_startad", tva.steg)
	check("och lämnar en enda post", FR.kvarvarande() == 1,
		("%d"):format(FR.kvarvarande()))
end

--[[ ══ 9. EN ERFAREN SPELARE FÅR STALLVÄGEN ═════════════════════════ ]]
print("\n-- Den som ridit förut går till stallet --")
do
	rent()
	local spelare, kar, hast = uppstallning("Veteran", 520)
	local save = SparService.save(spelare)
	Sparning.registreraPass(save, "prov-pass-9", 1)
	local fore = var(kar)
	local utfall = FR.starta(spelare)
	check("First Ride nekar henne", utfall.ok == false
		and utfall.steg == "inte_forsta_ritten", utfall.steg)
	check("och hon teleporteras inte",
		(var(kar) - fore).Magnitude < 0.001)
	check("hästen är inte heller sadlad åt henne",
		TackService.sadlad(hast) == false)
end

FR._satKlockaForProv(nil)
game:GetService("RunService")._server = false

print("")
if fails > 0 then
	print(string.format("%d mätning(ar) föll.", fails))
else
	print("Alla mätningar gick igenom.")
end
