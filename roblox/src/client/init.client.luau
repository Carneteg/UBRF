--!strict
--[[
	Klientens start och den enda uppdateringsloopen.

	En loop, inte en per delsystem. Det är skillnaden mellan tio hästar och
	hundra: varje extra Heartbeat-koppling kostar även när den inte gör
	något, och ordningen mellan delsystemen blir odefinierad om de har varsin.

	Ordningen här är inte godtycklig:
	  1. inmatning   — avsikten läses en gång per bildruta
	  2. rörelse     — tillstånd och fart räknas fram
	  3. animation   — läser tillståndet, skriver benen
	  4. ryttare     — IK ovanpå benen
	  5. ljud, damm  — läser fasen
	  6. kamera      — sist, så den ser slutgiltig position
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local Core = require(game:GetService("ReplicatedStorage").HorseCore)
local Config, RigAdapter, Net = Core.Config, Core.RigAdapter, Core.Networking
local Ridtrappa = Core.Ridtrappa
local Telemetri = require(game:GetService("ReplicatedStorage").HorseCore.Telemetri)

local Input = require(script.Input)
local TouchControls = require(script.TouchControls)
local DinHast = require(script.DinHast)
local Naromrade = require(script.Naromrade)
local MovementController = require(script.MovementController)
--[[ HORSE_VISUAL_QUALITY_GATE: benen på de hästar som bär ett riktigt nät
     drivs procedurellt härifrån. Modulen rör bara `Motor6D.Transform`,
     som är lokalt och oreplikerat — den kan inte påverka lokomotionen. ]]
local HastGang = require(script.HastGang)
local AnimationController = require(script.AnimationController)
local CameraController = require(script.CameraController)
local SoundController = require(script.SoundController)
local EffectsController = require(script.EffectsController)
local RiderController = require(script.RiderController)
local InteractionController = require(script.InteractionController)
local PreparationController = require(script.PreparationController)
local UgnetaController = require(script.UgnetaController)
local LektionController = require(script.LektionController)
local KontrollHjalp = require(script.KontrollHjalp)
--[[ #263: vilken build sitter jag i? Egen liten yta, se modulhuvudet. ]]
local Byggidentitet = require(script.Byggidentitet)
--[[ #162: världens prompter skrivs om till spelarens språk på klienten —
     en ProximityPrompt replikeras till alla och kan inte ha ett språk
     på servern. ]]
local Prompttext = require(script.Prompttext)
local Debug = require(script.Debug)
local Genomsikt = require(script.Genomsikt)

local player = Players.LocalPlayer
local ride: { [string]: any }? = nil

--[[ POSEN TILL INSPELNINGEN (G02-D).

     Inspelningen behöver VAR hästen var och ÅT VILKET HÅLL hon stod. Båda
     läses ur riggens root, och båda kan saknas i den bildruta där riggen
     håller på att rivas.

     Kontrollerna är explicita typtest, inte ett pcall. Ett pcall runt den
     här avläsningen hade svalt varje annat fel i samma andetag — och det
     är precis så en riktig krasch blir osynlig i stället för åtgärdad.

     Fälten valideras var för sig i HorseCore/Inspelning: en pose där
     positionen är omätbar men riktningen är ett riktigt tal BEHÅLLER
     riktningen. Att kasta hela posen för ett trasigt fält hade tappat en
     yaw som faktiskt var mätt. ]]
local function poseAv(rig: { [string]: any }?): { [string]: any }?
	if type(rig) ~= "table" then return nil end
	local root = rig.root
	if not root then return nil end
	local pos = root.Position
	local cf = root.CFrame
	if pos == nil or cf == nil then return nil end
	local _, yaw = cf:ToOrientation()
	return { x = pos.X, z = pos.Z, yaw = yaw }
end

--[[ VARFÖR RITTEN TOG SLUT, och inte bara ATT den gjorde det.

	`dismount` hade inget skäl, och därför kunde ingenting nedströms
	skilja «spelaren steg av» från «karaktären dog» eller «riggen
	försvann ur workspace». För rivningen spelade det ingen roll — allt
	ska ner ändå — men Teaching Loop behöver skillnaden: en summering
	efter en ritt man avslutat är en belöning, samma summering efter en
	respawn är förvirrande.

	Skälet är därför ett argument, och den som ANROPAR vet det. Utan
	argument antas det otrygga fallet: ingen summering. En ny anropare
	som glömmer skälet får alltså tystnad, inte en felaktig summering. ]]
export type Slutskal = "avsittning" | "avbrott"

local function dismount(skal: Slutskal?)
	if not ride then return end
	Telemetri.sittAv(ride.ritt)
	Input.unbind()
	--[[ Avsittningens handling rivs med ritten, av samma skäl som `E`
	     förut satt bakom `if not ride`: tangenten ska vara fri till fots.
	     `UnbindAction` river också pekknappen. ]]
	ContextActionService:UnbindAction(Input.AVSITT)
	TouchControls.unmount()
	ride.movement:release()
	ride.animation:release()
	ride.camera:release()
	ride.sound:release()
	ride.effects:release()
	ride.rider:release()
	--[[ SÄKERHET FÖRE UNDERVISNING (G02-C). Ritten är slut — av vilket
	     skäl som helst, och flera av dem ÄR säkerhetshändelser: karaktären
	     försvinner, riggen är borta ur workspace, servern flyttar
	     uppsittningen. Lärarytan släcks här, i samma andetag som resten av
	     ekipaget rivs, så att "Bra rytm" aldrig blir kvar på skärmen. ]]
	LektionController.avbryt(skal)
	--[[ Hjälpen hör till ritten. Den ska inte ligga kvar över en spelare
	     som just klivit av. ]]
	KontrollHjalp.dolj()
	Debug.clear()
	InteractionController.setEnabled(true)
	--[[ Skylten svarar på "vilken av dem?". Den frågan är inte aktuell
		medan man sitter på henne. ]]
	DinHast.satDold(false)
	--[[ #235: till fots agar naromradet skarmen igen. ]]
	Naromrade.satRider(false)
	ride = nil
end

--[[ SPELAREN BEGÄR AVSITTNING — lokalt först, servern sedan.

	Förut gjorde både E-vägen och touchkontrollen `InvokeServer()` FÖRE
	`dismount()`. `InvokeServer` yieldar, så ett långsamt eller uteblivet
	serversvar lämnade lektionen igång, den väntande fortsättningen kvar
	och lärarytan uppe — efter att spelaren bett om att få sitta av. Det
	är oförenligt med att säkerhet går före undervisning (senior review av
	b303530, punkt 1).

	Ordningen är därför omvänd:

	  1. `dismount()` städar LOKALT och omedelbart — lärarytan släcks, den
	     väntande fortsättningen kastas, touchkontrollerna rivs och
	     inmatningen kopplas ur. Inget av det behöver serverns tillstånd.
	  2. Serveranropet läggs i en egen tråd, så att svarstiden aldrig kan
	     hålla kvar något lokalt.

	SERVERN ÄGER FORTFARANDE SANNINGEN. Den validerar avsittningen, och
	nekar den skickar den `MountChanged` — då sätter klienten upp igen på
	serverns ord, vilket är en legitim rättelse och inte en egen
	uppsittning. `dismount` är idempotent (`if not ride then return end`),
	och vakten här gör att upprepade tryck varken städar två gånger eller
	skickar en andra begäran. ]]
local function begarAvsittning()
	if not ride then return end
	--[[ DEN ENDA GILTIGA VAGEN UT. Spelaren tryckte sjalv, och servern
	     far begaran direkt efterat. Summeringen hor hit och ingen
	     annanstans. ]]
	dismount("avsittning")
	task.spawn(function()
		local ok, err = pcall(function()
			Net.get("DismountRequest"):InvokeServer()
		end)
		if not ok then
			--[[ Uteblivet eller felande svar får inte återuppliva något
			     lokalt. Servern rättar oss via MountChanged om den vill. ]]
			warn("[Horse] DismountRequest misslyckades: " .. tostring(err))
		end
	end)
end

local function mount(model: Model, rittId: string?)
	--[[ RITTMARKET kommer ur `MountRequest`-svaret och binder varje
	     avsikt till DEN HAR ritten (#233, ChatGPT-review av #241). Utan
	     det kunde ett fordrojt paket fran en tidigare ritt landa efter
	     nasta uppsittning och accepteras mot fel ritt eller fel hast. ]]
	if ride then dismount("avbrott") end

	local rig, err = RigAdapter.build(model)
	if not rig then
		warn("[Horse] " .. tostring(err))
		return
	end
	local stats = Config.resolveStats(rig.stats)

	ride = {
		model = model,
		rig = rig,
		stats = stats,
		movement = MovementController.new(rig, stats),
		animation = AnimationController.new(rig, stats),
		camera = CameraController.new(rig),
		sound = SoundController.new(rig, stats),
		effects = EffectsController.new(rig),
		rider = RiderController.new(rig),
		--[[ G02-A: ridningens tillstånd och telemetri, samma kontrakt som
		     webbens src/riding/telemetri.js. Sätts FÖRE första bildrutan
		     av samma skäl som på webben — annars finns ett fönster där
		     loopen kan läsa en avsutten ryttare mitt i en ritt. ]]
		ritt = Telemetri.sittUpp(Telemetri.nyRitt(), model.Name, "ridhus"),
		telemetri = nil :: { [string]: any }?,
		syncTimer = 0,
		--[[ #233 Fas 4b. Monotont löpnummer på avsikterna, så att servern
		     kan kasta ett återspelat paket. Börjar om vid varje
		     uppsittning, precis som serverns räknare gör i
		     `nollstallRitt` — de två måste nollas ihop, annars läser
		     servern den nya rittens första hjälp som en gammal. ]]
		ridSekvens = 0,
		--[[ Serverns märke på DEN HÄR ritten. Följer med varje avsikt, och
		     varje svar måste bära samma märke för att få rätta klienten.

		     ATTRIBUTET ÄR SANNINGEN, handskakningen bara en tidig antydan.
		     `MountChanged` fyras inne i serverns `setRider`, alltså FÖRE
		     `tryMount` returnerar — en ritt som startar den vägen har
		     inget handskakningsvärde alls, och utan attributet hade den
		     ritten fått `rittId = nil` och servern hade nekat varje
		     hjälp. ]]
		rittId = rittId or model:GetAttribute("RidSession"),
	}

	local character = player.Character
	if character then
		ride.rider:attach(character)
	end

	Input.bind()
	--[[ AVSITTNINGEN ÄR EN KONTEXTUELL HANDLING (#233, arkitekturbeslut
	     2026-09-17). Den låg förut i `InputBegan`-lyssnaren längst ned,
	     och pekytan hade en egen `SITT AV`-knapp i panelen. Panelen är
	     riven, och en tangentlyssnare kan inte ge en iPad någon knapp.

	     `ContextActionService` ger alla tre ytorna samma handling: `E`,
	     styrkorset ned, och en pekknapp som `TouchControls` kläder. Den
	     binds vid uppsittningen och rivs vid avsittningen, så att `E` är
	     fri till fots — det var den förut också, genom `if not ride`. ]]
	ContextActionService:BindAction(Input.AVSITT,
		function(_, inputState: Enum.UserInputState)
			if inputState == Enum.UserInputState.Begin then begarAvsittning() end
			return Enum.ContextActionResult.Sink
		end, true, Enum.KeyCode.E, KontrollHjalp.AVSITTNING_GAMEPAD)
	--[[ Pekkontrollerna byggs först här, och bara på en pekenhet: en
	     spelare vid tangentbordet ska inte få en spak över bilden. De river
	     sig själva i `dismount`, så de kan aldrig ligga kvar och styra en
	     häst man klivit av. ]]
	--[[ `blick` går till kameran och INGEN ANNANSTANS: pekytan vrider
	     bilden, inte hästen. ]]
	TouchControls.mount(Input, {
		dismount = begarAvsittning,
		blick = function(dYaw, dPitch)
			local r = ride
			if r then r.camera:vridBlick(dYaw, dPitch) end
		end,
		--[[ #227: hjälpknappen viker undan för reglagen på en telefon i
		     landskap. Reserven rapporteras härifrån, i samma andetag som
		     reglagen byggs, byggs om (#208) eller rivs. ]]
		--[[ TVÅ lyssnare, inte en. `Byggidentitet` viker undan för
		     samma reserv och genom samma kontrakt (#263); slotten bär
		     en funktion, så de kopplas ihop här i stället för att
		     `TouchControls` får en lista. Ordningen spelar ingen roll —
		     båda räknar bara om sin egen knapps plats. ]]
		efterLayout = function(bredd: number, topp: number)
			KontrollHjalp.reservAndrad(bredd, topp)
			Byggidentitet.reservAndrad(bredd, topp)
		end,
	})
	InteractionController.setEnabled(false)
	DinHast.satDold(true)
	--[[ #235: medan man rider ager `TouchControls` skarmen. ]]
	Naromrade.satRider(true)
	Debug.attach(rig, stats)

	--[[ G02-C: lektionen börjar när man sitter upp i ridhuset. Ugneta
	     ställer sig vid sargen och undervisningen kör i den ordinarie
	     loopen nedan — det är hela skillnaden mot en HUD som bara går att
	     anropa. Gestalten placeras mot den BYGGDA banan; hittas den inte
	     körs lektionen ändå, utan figur. ]]
	--[[ Hela anläggningen är EN modell, "UBRF" i mappen "Anläggning"
	     (BuildKit.newBuilding i roblox/buildings/Anlaggningen.luau).
	     Ridbanan och sargen hänger direkt under den. ]]
	local anlaggning = workspace:FindFirstChild("Anläggning")
	LektionController.start(anlaggning and anlaggning:FindFirstChild("UBRF"))
	--[[ Första uppsittningen: visa reglagen en gång, av sig själv. Då är
	     frågan "vad gör jag nu?" som mest aktuell. ]]
	KontrollHjalp.vidUppsittning()

	--[[ ══ EN VARNING SOM ALLTID FYRAR ÄR INGEN VARNING ═══════════════

		Raden varnade förut så fort NÅGOT klipp saknades. I den här builden
		saknas ALLA arton, och det är ett beslut: `HastGang` driver benen
		procedurellt just för att hästens kärnrörelse inte ska hänga på en
		annan skapares assets (se modulens egen not). `AnimationConfig`
		skapas därför tom av `HorseService`, och ingenting fyller den.

		Följden var en `warn` med arton namn vid VARJE uppsittning, i ett
		läge som fungerar som avsett. Mätt i Studio 2026-09-20, två gånger
		i samma pass:

		    [Horse] Saknade animationer (18): Idle, …, Graze

		Det är inte gratis. Runtime-QA:s fråga är "varnar den här builden
		om något?", och en varning som alltid fyrar gör svaret värdelöst —
		den drunknade två riktiga `led.`-rader i samma logg.

		Nu varnar raden bara för det den kan betyda något om: en
		AnimationConfig som är HALVFYLLD. Då är ett saknat id ett riktigt
		paketeringsfel. Är den tom körs det procedurella läget, och det
		sägs i klartext en gång i stället. ]]
	local missing = (ride.animation :: any).missing
	local laddade = (ride.animation :: any).laddade or 0
	if missing and #missing > 0 and laddade > 0 then
		warn(("[Horse] Saknade animationer (%d av %d): %s")
			:format(#missing, #missing + laddade, table.concat(missing, ", ")))
	elseif missing and #missing > 0 then
		print("[Horse] Inga animationsklipp konfigurerade — benen drivs "
			.. "procedurellt av HastGang. Det är avsett.")
	end
end

--[[ Inomhusläsbarhet, till fots och till häst: väggar mellan kameran och
     karaktären tonas på den här klienten. ]]
Genomsikt.start()

--[[ Gånglagret startas EN gång och lever hela sessionen: det animerar alla
     hästar i sikte, inte bara den man rider. En häst som leds ska röra
     benen lika mycket som en som bär ryttare. ]]
HastGang.start()

InteractionController.start(mount)

--[[ Förberedelsen. Prompten "Sitt upp" får bara finnas på den häst servern
     säger att spelaren är klar med — och `redo` läses ur den senast
     mottagna `PreparationSync`, aldrig ur något klienten räknat ut själv. ]]
InteractionController.setReadyCheck(function(model: Model): boolean
	local id = PreparationController.hastId()
	if not id then return false end
	if model:GetAttribute("HorseId") ~= id then return false end
	--[[ ══ «MOUNT» VIKER FÖR ETT VÄNTANDE SKÖTSELSTEG (2026-09-20) ═════

	     Det finns exakt ETT läge där `redo` och en full panel möts, och
	     det är EFTERVÅRDEN: `Pass.farSittaUpp` släpper med flit en andra
	     uppsittning så länge inget eftervårdsmoment är gjort, så «Sitt
	     upp» stod bredvid «Lossa sadelgjorden». Det är bilden i PO-orderns
	     acceptansstycke, och punkt 3 avgör den: knappen ska inte stå där
	     «merely because a second ride is technically allowed».

	     HANDLINGEN TAS INTE BORT. `MountRequest` svarar precis som förut,
	     och `Pass.farSittaUpp` är orörd — det här är en
	     interaktionsprioritet, inte en behörighet. Så fort eftervårdens
	     moment är gjorda är uppgiften "rida" igen och knappen är tillbaka.

	     EN TIDIGARE VERSION AV DEN HÄR GRINDEN MÄTTES SOM ONÖDIG, och den
	     mätningen var riktig så länge regeln bara frågade «väntar ett
	     steg?»: i förberedelsen är `redo` falskt ändå, så en mutation som
	     rev grinden kom ut grön. Skillnaden nu är eftervården, och
	     `klient-uikontext.spec` avsnitt 3c mäter just den — inte det läge
	     där `redo` redan svarat nej. ]]
	if PreparationController.skotselstegAgerFokus() then return false end
	return PreparationController.redo()
end)
--[[ Ledningen öppnas av att `leda` är spelarens tur — inte av `redo`.
	Se noten i `InteractionController.farVisasLed`: den gamla regeln låste
	loopen, eftersom `leda` måste vara avbockad för att `redo` ska bli sant
	och kopplet måste fästas för att `leda` ska kunna bockas av. ]]
--[[ RIDE FIRST: «Rida nu» visas så länge förberedelsen ÄTERSTÅR. Är den
     klar är uppsittningsprompten svaret i stället — två knappar som gör
     nästan samma sak vore precis den valfrihet som bromsar. ]]
InteractionController.setRidaCheck(function(model: Model): boolean
	local id = PreparationController.hastId()
	if not id then return false end
	if model:GetAttribute("HorseId") ~= id then return false end
	return PreparationController.nastaFas() ~= nil
end)

--[[ Nejet från «Rida nu» ska läsas av SPELAREN, inte av Output-fönstret.
	Panelen äger meddelanderaden; knappen skickar dit sitt skäl. ]]
--[[ #182: kvittensen och den bestaende statusraden. Knapparna ager
	ingen text-yta sjalva — panelen ager meddelanderaden och `DinHast`
	statusraden, precis som avslagen redan var kopplade. ]]
InteractionController.setBekraftelseVisare(function(text: any)
	PreparationController.visaBekraftelseFor(text)
end)

InteractionController.setLedStatus(function(model: Model?)
	DinHast.satLedstatus(if model
		then tostring(model:GetAttribute("HorseName") or model.Name)
		else nil)
	--[[ PO-order 2026-09-20: skötselns framstegskort hör till boxen, inte
	     till kopplet. Ledningens ENDA övergång driver HUD-kontexten —
	     samma väg statusraden redan gick, så de två kan inte glida isär.
	     Se noten vid `PreparationController.kontext`. ]]
	PreparationController.satLeder(model ~= nil)
	--[[ Och prompterna räknas om DIREKT. `aktuellUppgift` svarar
	     annorlunda nu — ledningen äger fokus, eller släppte det — och utan
	     den här raden hade knapparna burit föregående läges svar tills
	     nästa `PreparationSync` råkade komma. Servern kan släppa kopplet
	     utan att spelaren tryckt (för långt, fastnat, satte sig upp), och
	     då finns ingen sådan sync att vänta på. ]]
	InteractionController.uppdatera()
end)

InteractionController.setAvslagVisare(function(skal: any, extra: any?)
	PreparationController.visaAvslagFor(skal, extra)
end)

--[[ ══ RIDE FIRST: LEDNINGEN AR INTE LAST BAKOM TEORIN ═══════════════

     Produktbeslut 2026-09-17, efter fysisk QA. Villkoret lod förut
     `nastaFas() == "leda"` — alltså fas FEM av fem. Spelaren kunde inte
     röra hästen förrän hon hälsat, visiterat, ryktat och gjort i ordning,
     och fick ingen som helst indikation om varför ledknappen saknades.

     Det bröt mot FUN FIRST / RIDE FIRST: skötseln ska göra ritten bättre,
     inte vara en vägspärr. Att leda sin häst är dessutom en av de
     handlingar man naturligast vill göra direkt.

     KLIENTEN RITAR NU KNAPPEN på spelarens egen häst, oavsett fas.
     SERVERN AVGÖR FORTFARANDE ALLT annat — rätt häst, avstånd, om hon
     leds av någon annan, om hon rids, om spelaren redan leder. Den här
     raden flyttar ingen behörighet; den slutar bara gömma knappen. ]]
--[[ ══ LEDKNAPPEN VIKER FÖR ETT VÄNTANDE SKÖTSELSTEG — MED GRÄNS ════

     PO-order 2026-09-20 PRODUCT CLARIFICATION: «Treat prompt visibility
     by current task relevance, not by «care panel visible» as a blanket
     rule.»

     Ett första försök (`8aba0f3`) gjorde just det som ordern förbjuder:
     det frågade om PANELEN. Mätningen som fällde det står kvar, för den
     är fortfarande sann och den är hela skälet till gränsen nedan:

         skötselpanelen visas      `Config.STEG_RACKVIDD` = 12 studs
         servern släpper ledning   `LedService.RACKVIDD` 4,0 m × M 3
                                   = 12 studs

     SAMMA RADIE. Innanför 12 studs finns knappen bara om regeln släpper
     den; utanför svarar servern `led.for_langt`. En ytregel lämnar därför
     ingen position alls där ledningen både syns och fungerar.

     DÄRFÖR FRÅGAR REGELN UPPGIFTEN I STÄLLET. `aktuellUppgift` svarar
     "leda" i de två lägen där ledningen ÄR handlingen — `leda` står på
     tur, eller repet är redan i handen — och knappen finns då mitt inne i
     radien, där servern också säger ja. Ordern punkt 2 och 4 är alltså
     uppfyllda i själva regeln, inte som undantag bredvid den.

     Det som SMALNAS mot 2026-09-17 är faserna före `leda`, och bara i det
     ögonblick de själva står i nederkanten och ber om ett tryck. Går man
     ifrån hästen, eller gör steget, är knappen tillbaka.

     BEHÖRIGHETEN FLYTTAS INTE. `LedBorja` svarar som förut; servern äger
     rätt häst, avstånd, om hon leds av någon annan, om hon rids. ]]
InteractionController.setLedCheck(function(model: Model): boolean
	local id = PreparationController.hastId()
	if not id then return false end
	if model:GetAttribute("HorseId") ~= id then return false end
	return not PreparationController.skotselstegAgerFokus()
end)
--[[ Prompt-uppdateringen hänger på ATT EN NY VY ACCEPTERATS, inte på
     RemoteEvent-händelsen. Skillnaden är hela rättelsen efter senior review
     runda 2: handskakningens svar kommer inte som en `PreparationSync`, så
     en andra listener på det eventet missade det helt och en sent
     initierad klient fick aldrig sin "Sitt upp"-prompt. ]]
PreparationController.vidNyVy(function()
	InteractionController.uppdatera()
end)
--[[ #182: den beständiga statusraden för buren utrustning. Driven av
     SERVERNS vy och inte av boxfrontens knapptryck, av exakt samma skäl
     som ledningens rad lyssnar på `LedSync`: hämtningen kan ändras av
     något annat än det senaste trycket — «Rida nu» hämtar också, och
     varje påsatt del släcker sin egen del av raden — och två vägar in
     hade kunnat glida isär. ]]
PreparationController.vidNyVy(function(vy: any)
	DinHast.satBurenstatus(if type(vy) == "table" then vy.burenUtrustning else nil)
end)

--[[ #235 FAS 2: «Sadla». Knappen far bara finnas nar spelaren FAKTISKT
     bar sadeln, och servern ar den enda som vet det.

     `vy.burenUtrustning` ar redan precis den sanningen och behover ingen
     ny kanal: `Preparation.buren` drar bort det som redan ligger pa
     hasten, sa «sadel» star kvar i listan exakt sa lange den ar i
     handerna. Nar servern byggt den pa ryggen forsvinner den ur listan i
     samma sync, och knappen med den.

     Det ar samma val som ledningens statusrad gjorde: LYSSNA PA SERVERNS
     VY, inte pa det senaste knapptrycket. Tva vagar in hade kunnat glida
     isar — och «Rida nu» hamtar ocksa utrustning, utan att ga via
     sadelknappen. ]]
local barSadelNu = false
--[[ #235 FAS 3: transet foljer samma vag. Listan bar bada delarna, och
     `Preparation.buren` drar bort det som redan sitter pa hasten — sa
     varje del star kvar exakt sa lange den ar i handerna. ]]
local barTransNu = false
PreparationController.vidNyVy(function(vy: any)
	local buren = if type(vy) == "table" then vy.burenUtrustning else nil
	local har, harTrans = false, false
	if type(buren) == "table" then
		for _, typ in ipairs(buren.delar or {}) do
			if tostring(typ) == "sadel" then har = true end
			if tostring(typ) == "trans" then harTrans = true end
		end
	end
	barSadelNu = har
	barTransNu = harTrans
	--[[ OCH RITA OM DIREKT. `vidNyVy`-hookarna kors i den ordning de
	     registrerats, och promptuppdateringen ovan star FORE den har — sa
	     utan raden nedan hade sadelknappen alltid speglat FOREGAENDE sync.
	     Spelaren hade sett knappen forst efter nasta serverbesked, och den
	     hade statt kvar ett varv efter att sadeln lagts pa. ]]
	InteractionController.uppdatera()
end)
InteractionController.setSadlaCheck(function(model: Model): boolean
	if not barSadelNu then return false end
	local id = PreparationController.hastId()
	if not id then return false end
	return model:GetAttribute("HorseId") == id
end)

--[[ #235 FAS 3. Samma fraga, en annan del. Att knapparna inte kan vara
     uppe samtidigt avgors inte har utan av KANON: transet kraver att hon
     ar sadlad, och nar hon ar det har `burenUtrustning` redan slappt
     sadeln. Servern bar regeln (`tack.sadeln_forst`); den har raden ritar
     bara knappen. ]]
InteractionController.setTransaCheck(function(model: Model): boolean
	if not barTransNu then return false end
	local id = PreparationController.hastId()
	if not id then return false end
	return model:GetAttribute("HorseId") == id
end)
PreparationController.start()
DinHast.start()
--[[ #235: den gemensamma touchytan. Returnerar direkt utan pekskarm. ]]
Naromrade.start()
--[[ P0-3: HUD:ens KONTEXT stegas av sin egen loop, inte av ridloopen längst
     ned — den återvänder direkt när man inte rider, och det är precis då
     frågan "står jag vid min häst?" spelar roll. Heartbeat räcker: det är
     ett avståndsmått, och HUD:en ritas bara om när svaret FAKTISKT byter. ]]
RunService.Heartbeat:Connect(function()
	PreparationController.uppdateraKontext()
end)
--[[ G02-C: Ugnetas lärar-UX byggs vid uppstart så att den finns när
     första ritten börjar. Själva LEKTIONEN startas av `mount` och stegas
     av loopen längst ned — HUD:en är ytan, LektionController är kedjan. ]]
UgnetaController.start()
--[[ #161: `?`-knappen byggs vid uppstart och lever hela sessionen. Att
     bygga den vid uppsittning hade gett samma hål vi just stängde — hjälpen
     ska finnas i stallet också. ]]
KontrollHjalp.start()
--[[ #263: byggidentiteten lever hela sessionen, av samma skäl som
     hjälpknappen — QA ska kunna läsa av builden i stallet också, inte
     bara i sadeln. ]]
Byggidentitet.start()
Prompttext.start()

--[[ Servern talar om när uppsittningen ändras — även när den ändras av
     något annat än oss, som respawn eller att hästen tas bort. ]]
Net.get("MountChanged").OnClientEvent:Connect(function(model: Model, rider: Player?)
	if rider == player then
		if not ride or ride.model ~= model then
			mount(model)
		end
	elseif ride and ride.model == model then
		--[[ Serverns besked, inte spelarens tryck. Den egna avsittningen
		     har redan summerat i `begarAvsittning`; att summera igen har
		     hade gett tva besked om samma ritt. ]]
		dismount("avbrott")
	end
end)

--[[ Servern äger energin; klienten predikterar mellan synkarna och
     RÄTTAS här (senior re-review #87, blocker 3). Utan rättelsen hade
     klienten och servern varit två trötthetssanningar igen — nu är
     klientens värde en prediktion av serverns, inte en egen modell. ]]
Net.get("StaminaSync").OnClientEvent:Connect(function(stamina, max, ceiling, energi)
	if ride then
		ride.movement:setCeiling(ceiling)
		if energi ~= nil then ride.movement:setEnergi(energi) end
		Debug.setStamina(stamina, max, ceiling)
	end
end)

--[[ ── SERVERNS ACCEPTERADE GÅNGART (#233 Fas 4b) ─────────────────────

     Svaret på varje avsikt, och på varje gångart uthålligheten sänkt av
     sig själv. Klienten predikterade steget när knappen trycktes; det här
     är facit.

     Lyssnaren sitter på MODULNIVÅ och inte i `mount()`, av samma skäl som
     `StaminaSync` gör det: en lyssnare som kopplas per uppsittning
     kopplas också EN GÅNG PER uppsittning, och den som glömmer riva den
     får två. `if ride` är hela grinden som behövs — ett svar som kommer
     efter avsittningen hör inte till någon ritt och ska falla. ]]
Net.get("RidTillstand").OnClientEvent:Connect(function(tillstand)
	if not ride then return end
	if typeof(tillstand) ~= "table" then return end
	--[[ ── SVARET MÅSTE HÖRA TILL DEN RITT SOM PÅGÅR ──────────────────
	     Krav ur ChatGPT-reviewen av #241. Lyssnaren låg på modulnivå och
	     reconcilade VILKET svar som helst mot den ritt som råkade vara
	     aktiv när paketet kom. `version` ordnar paket inom en
	     hästsession; den säger ingenting om vilken häst eller vilken
	     ritt svaret gäller.

	     BÅDA kontrollerna behövs, och det är inte dubbelarbete:

	       hästen   fångar svar från en ANNAN häst efter hästbyte,
	       ritten   fångar svar från en TIDIGARE ritt på SAMMA häst —
	                det fallet ser identiskt ut i hästledet.

	     Ett svar som kommer efter avsittningen faller redan på `ride`. ]]
	if tillstand.hast ~= ride.model then return end
	if tillstand.ritt ~= ride.rittId then return end
	ride.movement:reconcile(tillstand.gangart, tillstand.ryggar, tillstand.version)
end)

--[[ Sitt av med E, och alltid om karaktären dör. Lektionens fortsättning
     ligger före avsittningen: den är ett svar på ett kort som står uppe,
     och får aldrig kunna tolkas som något annat. ]]
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end

	--[[ HJÄLPEN LIGGER FÖRE `not ride`-GRINDEN, och det är rättelsen i
	     #161 (P2-4b ur #153).

	     Hela den här lyssnaren började med `if processed or not ride then
	     return end`, vilket var rätt för avsittning och lektionskort — de
	     betyder ingenting när man står i stallet. Men det gällde alltså
	     ÄVEN `H`: kontrollhjälpen gick bara att öppna medan man satt upp,
	     och att stänga den och sitta av var samma sak som att bli av med
	     den. Det var precis den oåterkalleliga stängningen QA rapporterade.

	     `DPadUp` är gamepadens väg in, kontrollerat ledig: Input.luau tar
	     Thumbstick1, ButtonA/B/R1/L1/R2/L2 och den här filen tar
	     ButtonY/ButtonX. Till skillnad från ButtonStart/ButtonSelect är
	     det inte reserverat av Roblox egna menyer. Ingen befintlig rid-,
	     hopp- eller replaybindning har flyttats.

	     STYRKORSET ÄR NUMERA FULLT (#182 omtag): ned är avsittningen,
	     vänster och höger är hästens två nya prompter
	     (`InteractionController.GAMEPAD`). Hjälpen är den ENDA bindningen
	     som lever i båda lägena — den ligger ju före `not ride`-grinden —
	     och just därför får ingen prompt röra `DPadUp`. ]]
	if input.KeyCode == Enum.KeyCode.H
		or input.KeyCode == KontrollHjalp.GAMEPADKNAPP then
		KontrollHjalp.vaxla()
		return
	end

	if not ride then return end
	--[[ G02-C: spelaren går vidare i lektionen. R och gamepadens Y är
	     valda för att de INTE är bundna i ridningen — Input.luau tar
	     W A S D, Space, Shift, Ctrl, Q, F, Z, C och ButtonA/B/R1/L1, och
	     E betyder redan sitt av. Musen och fingret går in genom knappens
	     eget Activated, inte här.

	     `fortsatt` returnerar false när inget kort väntar, så tangenten
	     stjäl ingenting när lektionen inte frågar. ]]
	if input.KeyCode == Enum.KeyCode.R or input.KeyCode == Enum.KeyCode.ButtonY then
		--[[ Står ridanalysen uppe betyder R "tillbaka", inte "vidare":
		     panelen ligger ovanpå kortet, och den översta ytan äger
		     tangenten. Utan det hade ett R stängt kortet BAKOM panelen och
		     lämnat analysen kvar över nästa försök. ]]
		if LektionController.replayAktiv() then
			LektionController.stangReplay()
			return
		end
		if LektionController.fortsatt() then return end
	end
	--[[ G02-D: "Se ritten". T och gamepadens X är valda av samma skäl som
	     R och Y — Input.luau tar dem inte, och E betyder redan sitt av. ]]
	if input.KeyCode == Enum.KeyCode.T or input.KeyCode == Enum.KeyCode.ButtonX then
		if LektionController.replayAktiv() then
			LektionController.stangReplay()
			return
		end
		if LektionController.replay() then return end
	end
	--[[ "Gå vidare": nöj dig med försöket. Momentet bedöms ändå. ]]
	if input.KeyCode == Enum.KeyCode.G then
		if LektionController.gaVidare() then return end
	end
	--[[ H och styrkorset hanteras ovanför `not ride`-grinden — se noten
	     där. Tangenten är fri: Input.luau tar W A S D, Space, Shift, Ctrl,
	     Q, F, Z, C och spakarna, och E/R/T/G är tagna här. ]]
	--[[ AVSITTNINGEN LIGGER INTE LÄNGRE HÄR. `E` och styrkorset ned är
	     `Input.AVSITT` i `mount()` ovan — en `ContextActionService`-
	     handling, samma på alla tre ytorna, och den enda som kan ge en
	     iPad en knapp. Tangenterna är oförändrade; det som ändrats är vem
	     som äger dem. #162 blockerare 2 mäts fortsatt av klientprovet. ]]
end)

--[[ Dod eller respawn. INGEN summering: en ritt som tog slut for att
     karaktaren forsvann ar inget att gratulera till. Wrappen finns for
     att signalen annars skickar karaktaren som forsta argument — och
     det hade lasts som ett skal. ]]
player.CharacterRemoving:Connect(function() dismount("avbrott") end)

RunService.RenderStepped:Connect(function(dt)
	if not ride then return end
	if not ride.rig.root:IsDescendantOf(workspace) then
		dismount("avbrott")
		return
	end

	--[[ PAUS: världen ritas fortfarande — spelaren ska se var hon står —
	     men hästen stegas inte. Utan det red hon vidare bakom kortet och
	     bakom ridanalysen, och det försök spelaren just tittade på hann bli
	     ogiltigt medan hon tittade.

	     `Input.consume()` körs ÄNDÅ och kastas. Den nollställer
	     engångsflankerna (gångart upp/ner, parad); låg de kvar hade varje
	     tryck under pausen fyrat på en gång när pausen släppte. En impuls
	     ska verka en gång, i den bildruta den gjordes — inte sparas. ]]
	local intent = Input.consume()
	--[[ Vad ryttaren bad om den här bildrutan. Räknas FÖRE pausgrenen
	     sedan #263: grenen behöver veta om det kom en hjälp. Samma
	     uttryck som förut, bara flyttat hit. ]]
	local hjalp = intent.gaitUp or intent.gaitDown or (intent.parad or 0) > 0

	--[[ ══ EN HJÄLP ÄR ETT SVAR (#263 P1) ═══════════════════════════

	     Uppmätt i Studio: `vantar()` är SANT i samma ögonblick spelaren
	     sätter sig upp — First Ride sätter henne i sadeln rakt framför
	     kortet «Continue to start the lesson». Varje DRIV hon gav
	     försvann här, tyst: inmatningen gick hela vägen till `consume`
	     och kastades sedan. Hästen stod kvar i halt och ingenting sa
	     varför.

	     Det var inte en trasig inmatningskedja. Kedjan var hel —
	     `drivImpuls` svarade `true`, servern hade `ActionDriv` bunden,
	     och ett tryck på kortets knapp gav omedelbart `halt → walk`.
	     Det som fattades var att kortet åt hjälpen.

	     Bänken visste om det och gick runt det: `klient-ridhandlingar`
	     har en hjälpare `kvitteraKort()` vars kommentar säger att kortet
	     "kastar varje avsikt tills det kvitteras". Varje spec kvitterade
	     först och mätte sedan. Ingen mätte spelarens egen väg.

	     Nu besvarar en hjälp kortet OCH verkar i samma bildruta. Det är
	     det enda rimliga: kortet ber om en skänkelhjälp, och när hon ger
	     den ska hästen gå — inte be henne trycka en knapp först. ]]

	--[[ ══ ETT KORT SOM SYNS ÄR INGET RÖRELSELÅS ════════════════════
	     LESSON_CARD_RIDING_INPUT_ACCEPTANCE (PO-order 2026-09-20).

	     #263 P1 ovan löste halva problemet. En HJÄLP besvarade kortet —
	     men styrning är ingen hjälp, så `vantar() and not hjalp` var
	     sant i varje bildruta där ryttaren bara höll en tygel. Då kördes
	     `release()`, `movement:step` hoppades över, och `step` är enda
	     stället som skriver hästens kurs.

	     Uppmätt i Studio 2026-09-20, uppsutten på Trixie i ridbanan, med
	     `D` bevisligen nere (`UserInputService:IsKeyDown(D) == true`) i
	     2,5 s medan `vantar()` var sann:

	         yaw före  −156,8°      yaw efter  −156,8°      flytt 0,0 studs

	     Samma tangent med kortet kvitterat gav omedelbart en obruten båge
	     −58° → +66°. Hästen var alltså inte trasig; kortet höll henne.

	     REGELN: att visa coaching får aldrig i sig självt stoppa
	     ridningen. Bara en uttrycklig intervention som verkligen kräver
	     skritt eller halt får ta framdrivningen — och en sådan ska säga
	     det själv, inte härledas ur att någon panel råkar vara synlig.

	     I dag finns exakt EN sådan: REPLAYEN. Den är inte ett
	     lektionskort utan en analys spelaren själv öppnat med `R`
	     eller `T` för att titta på sin ritt, och att rida vidare bakom
	     den vore att titta på en inspelning av något annat än det som
	     händer. Den är därför kvar som hård paus, mätt i punkt 4 och 5d
	     i `klient-lektionspaus.spec`.

	     Kortets egen skyddsuppgift är kvar och ligger där den hör hemma:
	     `LektionController.steg` mäter ingenting medan `vantar()` är
	     sann, så försöket kan inte bli ogiltigt av att hon rider under
	     tiden. Att FRYSA hästen var aldrig det som skyddade mätningen. ]]
	if LektionController.replayAktiv() then
		--[[ ══ PAUSEN MÅSTE STANNA HÄSTEN, INTE BARA SLUTA STYRA HENNE ══

		     Stycket ovanför säger "hästen stegas inte", och det stämde —
		     men att sluta stega henne är inte att stanna henne.
		     `movement:step` är enda stället som skriver `Humanoid.WalkSpeed`
		     och `Humanoid:Move`. Hoppas den över ligger BÅDA kvar på
		     förra bildrutans värden, och Roblox humanoid fortsätter gå på
		     dem. Hästen red alltså vidare bakom kortet ändå — utan att
		     spelaren kunde styra henne.

		     Mätt i Studio, ridd, med kortet uppe och spelaren utan kontroll:
		         kurs låst 0,0°, WalkSpeed 4,35, D utan verkan
		         (427,16 · 173,44) -> (427,16 · 161,24) = 12,2 studs på 4,6 s
		     och i ett hörn i stället: noll förflyttning, noll kursändring,
		     full hjälp given — hon stod och tryckte mot sargen. Det är det
		     här som såg ut som "locomotion är död": hon svarar inte, för
		     ingen läser spelarens hjälper, och hon står still för att en
		     vägg tog emot — inte för att pausen höll.

		     `release()` finns redan och gör precis det pausen behöver:
		     nollar WalkSpeed, skickar `Move(0)`, släpper styrutslag och
		     kroppslutning. Ingen ny rörelsekod, ingen ny trimning. ]]
		ride.movement:release()
		local loco = ride.movement.loco
		ride.animation:step(loco, dt)
		ride.rider:step(loco, dt)
		ride.camera:step(loco, dt)
		return
	end

	--[[ Hjälpen besvarar kortet. `fortsatt()` gör exakt det knappen gör
	     och returnerar false när det inte fanns något att kvittera — då
	     har raden ingen verkan, vilket är rätt.

	     `hjalp`-villkoret är NYTT och nödvändigt sedan pausgrenen ovan
	     bara stoppar på replayen: utan det hade varje bildruta med ett
	     kort uppe kvitterat det, och kortet försvunnit av sig självt
	     innan spelaren hunnit läsa en rad. Ett kort ska besvaras av ett
	     SVAR — en hjälp eller ett tryck på knappen — och en tygel är
	     inget svar. Mätt i `klient-lektionspaus.spec` punkt 5b. ]]
	if hjalp and LektionController.vantar() then LektionController.fortsatt() end

	--[[ ── AVSIKTEN SKICKAS, INTE RESULTATET (#233 Fas 4b) ─────────────

	     Trappans läge läses FÖRE och EFTER `step`. Flyttade ryttarens
	     hjälp den, är det en avsikt — `driv` uppåt, `broms` nedåt — och
	     den går på tråden som just det ordet.

	     VARFÖR MÄTT OCH INTE AVLÄST UR `intent`: paraden stegar också ned,
	     men bara på sin FLANK, och flanken räknas inne i
	     `MovementController`. Att läsa `intent.parad` här hade krävt en
	     andra kopia av flanklogiken, och två kopior av en flank är två
	     flanker. Mätningen fångar alla tre vägarna — DRIV, BROMS och
	     parad — utan att veta något om dem.

	     `hjalp`-villkoret är inte överflödigt. Trappan kan flytta sig utan
	     att ryttaren rört något: sjunker uthållighetstaket klampar
	     `_targetGait` ned av sig själv. Den rörelsen är INTE en avsikt,
	     och servern gör redan samma sänkning på sin sida — skickades den
	     som `broms` hade hästen stegat ned två pinnar på en trötthet. ]]
	local trappaFore = Ridtrappa.index(
		ride.movement.loco.beddGangart, ride.movement.ryggar)

	ride.movement:step(intent, dt)

	if hjalp then
		local trappaEfter = Ridtrappa.index(
			ride.movement.loco.beddGangart, ride.movement.ryggar)
		if trappaEfter ~= trappaFore then
			ride.ridSekvens += 1
			--[[ SEN REPLIKERING FÅR INTE DÖDA RITTEN. Hann attributet inte
			     fram när `mount()` kördes står märket som nil, och då
			     hade varje hjälp nekats tyst för resten av ritten. Läs om
			     det en gång till här i stället: en avsikt är sällsynt nog
			     att en attributläsning inte märks, och alternativet är en
			     häst som aldrig svarar. ]]
			if ride.rittId == nil then
				ride.rittId = ride.model:GetAttribute("RidSession")
			end
			--[[ RITTMÄRKET FÖRST i anropet, av samma skäl som servern
			     prövar det först: det är avsiktens adress, inte dess
			     innehåll. Utan märket kunde ett fördröjt paket från en
			     tidigare ritt landa efter nästa uppsittning och stega en
			     annan häst. ]]
			Net.get("RidingIntent"):FireServer(
				ride.rittId,
				if trappaEfter > trappaFore then Ridtrappa.DRIV else Ridtrappa.BROMS,
				ride.ridSekvens)
		end
	end

	local loco = ride.movement.loco

	--[[ G02-A: gångarten följs av övergångskontraktet och telemetrin läggs
	     på ride.telemetri, så att G02-B/C har EN avläsningspunkt på båda
	     ytorna. REN AVLÄSNING — modulen räknar ingen fysik, rör ingen
	     Instance och ligger efter movement:step, så den kan varken ändra
	     rörelsen eller ridkänslan. ]]
	Telemetri.foljGangart(ride.ritt, loco.gait)
	ride.telemetri = Telemetri.las(ride.ritt, loco, ride.movement.curvature,
		ride.movement.hjalper)

	--[[ G02-C: lektionen läser telemetrin som just skrivits. Den ligger
	     EFTER avläsningen och FÖRE renderingen av samma skäl som allt
	     annat i den här ordningen: den ska se bildrutans mätning, inte
	     förra bildrutans, och den rör varken rörelse eller kamera. ]]
	LektionController.steg(dt, ride.telemetri, poseAv(ride.rig))

	ride.animation:step(loco, dt)
	ride.rider:step(loco, dt)
	ride.sound:step(loco, dt)
	ride.effects:step(loco, dt)
	ride.camera:step(loco, dt)
	Debug.step(loco)

	--[[ Servern behöver inte 60 uppdateringar i sekunden för att validera
	     en gångart. Tio räcker, och skillnaden märks direkt i bandbredd när
	     flera spelare rider samtidigt. ]]
	ride.syncTimer += dt
	if ride.syncTimer >= 0.1 then
		ride.syncTimer = 0
		--[[ GÅNGARTEN LIGGER INTE LÄNGRE PÅ TRÅDEN (#233 Fas 4b).
		     Anropet var `FireServer(loco.gait, loco.speed)`, och den
		     första halvan var hela auktoritetshålet: servern hade ingen
		     annan källa till vilken gångart hästen var i än klientens
		     ord. Nu bär remoten farten, som är en OBSERVATION och inte
		     ett beslut — serverns gångart kommer ur `RidingIntent`. ]]
		Net.get("StateSync"):FireServer(loco.speed)
	end
end)

print("[Horse] Klienten igång")
