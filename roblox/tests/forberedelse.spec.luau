--!nostrict
--[[
	FÖRBEREDELSEN — reglerna för G01-S2b, provade utan Studio.

	Specen mäter `Preparation` och `Stallet.tilldelaLedig`, alltså de
	moduler som FAKTISKT kör i spelet. Den bygger ingen egen kopia av
	ordningen eller bindningsvillkoret; gjorde den det vore varje prov här
	grönt även om servern gjorde något helt annat. Det är samma fälla som
	tools/prov-spegla.py skrevs om för att undvika.

	Vad specen INTE når står i PR-texten under Not tested: allt som kräver
	instanser, replikering och avstånd i en riktig värld.

	Kör: python3 roblox/tests/build.py tests/forberedelse.spec.luau
	     && luau roblox/tests/.build/forberedelse.spec.luau
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

--[[ ── Fasordningen kommer ur exporten ────────────────────────────
	Krav 11: ingen hårdkodad parallell lista i Luau. Provet läser samma
	tabell som modulen, och kontrollerar att den kommer FRÅN skötseln. ]]
do
	check("faserna kommer ur UBRFSkotsel",
		Preparation.FASER == UBRFSkotsel.faser,
		"samma tabell, inte en kopia")

	check("det finns fem faser", #Preparation.FASER == 5,
		#Preparation.FASER .. " st")

	local id = {}
	for _, f in ipairs(Preparation.FASER) do table.insert(id, f.id) end
	check("ordningen är hälsa → visitera → rykta → iordning → sittupp",
		table.concat(id, ",") == "halsa,visitera,rykta,iordning,sittupp",
		table.concat(id, " → "))

	--[[ HÄSTKUNSKAP, inte layout: visitationen måste ligga före ryktningen.
		Ett fynd på gjordläget ska upptäckas medan det fortfarande går att
		avbryta — inte efter att gruset arbetats in. ]]
	check("visitationen kommer före ryktningen",
		Preparation.fasIndex("visitera") < Preparation.fasIndex("rykta"),
		"visitera " .. Preparation.fasIndex("visitera")
			.. " < rykta " .. Preparation.fasIndex("rykta"))

	--[[ Uppsittningen är inte ett förberedelsesteg. Räknas den som ett blir
		hästen redo att sitta upp på först efter att man redan suttit upp. ]]
	local steg = Preparation.stegFaser()
	check("uppsittningen räknas inte som ett steg", #steg == 4,
		#steg .. " steg av " .. #Preparation.FASER .. " faser")
	check("den sitt-märkta fasen ligger sist",
		Preparation.FASER[#Preparation.FASER].sitt == true,
		Preparation.FASER[#Preparation.FASER].id)

	local utanText = {}
	for _, f in ipairs(Preparation.FASER) do
		if not f.namn or f.namn == "" or not f.text or f.text == "" then
			table.insert(utanText, tostring(f.id))
		end
	end
	check("varje fas har namn och text", #utanText == 0, table.concat(utanText, ", "))
end

--[[ ── Krav 4: steg kan inte hoppas över ──────────────────────────── ]]
do
	local s = Preparation.nyState("cosmo")

	check("första steget är att hälsa", Preparation.nasta(s).id == "halsa")

	local ok, skal = Preparation.utfor(s, "rykta", "cosmo")
	check("går inte att rykta först", not ok, tostring(skal))
	check("ett avvisat steg flyttar inte fram förberedelsen",
		Preparation.nasta(s).id == "halsa" and s.klara.rykta == nil)

	check("hälsa går", (Preparation.utfor(s, "halsa", "cosmo")))
	local ok2, skal2 = Preparation.utfor(s, "iordning", "cosmo")
	check("går inte att hoppa över visitationen", not ok2, tostring(skal2))

	check("visitera går som nästa", (Preparation.utfor(s, "visitera", "cosmo")))
	local ok3, skal3 = Preparation.utfor(s, "visitera", "cosmo")
	check("samma steg går inte att göra två gånger", not ok3, tostring(skal3))

	--[[ Uppsittningen får inte gå att kvittera som ett steg och därmed
		hoppa över resten. ]]
	local ok4 = Preparation.utfor(s, "sittupp", "cosmo")
	check("uppsittningen går inte att utföra som ett steg", not ok4)

	check("rykta går", (Preparation.utfor(s, "rykta", "cosmo")))
	check("inte redo förrän allt är gjort", not Preparation.redo(s),
		"återstår: " .. Preparation.nasta(s).id)
	check("gör i ordning går", (Preparation.utfor(s, "iordning", "cosmo")))
	check("redo när alla fyra är gjorda", Preparation.redo(s))
end

--[[ ── Krav 4 och 7: fel häst ─────────────────────────────────────── ]]
do
	local s = Preparation.nyState("cosmo")
	local ok, skal = Preparation.utfor(s, "halsa", "air")
	check("steg på fel häst avvisas", not ok, tostring(skal))
	check("fel häst hindrar inte rätt häst efteråt",
		(Preparation.utfor(s, "halsa", "cosmo")))
end

--[[ ── Krav 6: uppsittning före ready_to_mount ─────────────────────── ]]
do
	local s = Preparation.nyState("cosmo")
	local ok, skal = Preparation.provaModell(s, "cosmo")
	check("oförberedd spelare får inte sitta upp", not ok, tostring(skal))

	for _, f in ipairs(Preparation.stegFaser()) do
		Preparation.utfor(s, f.id, "cosmo")
	end
	check("förberedd spelare får sitta upp", (Preparation.provaModell(s, "cosmo")))

	--[[ Krav 7: färdig förberedelse ger INTE tillgång till någon annans
		häst. Det här är fallet som gör att en spelare annars kan rykta sin
		egen och sedan sitta upp på grannens. ]]
	local ok2, skal2 = Preparation.provaModell(s, "air")
	check("förberedd spelare får ändå inte sitta upp på annans häst",
		not ok2, tostring(skal2))

	check("ingen tilldelning alls ger nej", not Preparation.provaModell(nil, "cosmo"))
end

--[[ ── Krav 1 och 2: bindningen ────────────────────────────────────── ]]
do
	local cosmoModell, airModell = { "cosmo-rigg" }, { "air-rigg" }

	--[[ Krav 1: tilldelad air, bara cosmo finns i världen → INGEN modell.
		Det är hela poängen: hellre waiting_model än fel häst. ]]
	local vald = Preparation.valjModell({ { id = "cosmo", modell = cosmoModell } }, "air", {})
	check("fel rigg i världen ger ingen bindning", vald == nil,
		"tilldelad air, bara cosmo finns")

	--[[ Krav 2: rätt rigg dyker upp senare → bind automatiskt. ]]
	local vald2 = Preparation.valjModell({
		{ id = "cosmo", modell = cosmoModell },
		{ id = "air", modell = airModell },
	}, "air", {})
	check("rätt rigg binds när den tillkommer", vald2 == airModell)

	--[[ Krav 3, modellsidan: en modell som en annan spelare håller får inte
		bindas igen. ]]
	local vald3 = Preparation.valjModell({ { id = "air", modell = airModell } },
		"air", { [airModell] = true })
	check("upptagen modell binds inte om", vald3 == nil)

	--[[ En modell utan HorseId får aldrig råka matcha. GetAttribute ger nil
		på en otaggad modell, och nil == nil hade bundit vad som helst om
		villkoret skrivits slarvigt. ]]
	local vald4 = Preparation.valjModell({ { id = nil, modell = { "namnlos" } } }, "air", {})
	check("modell utan HorseId binds aldrig", vald4 == nil)
end

--[[ ── Krav 3: två spelare får aldrig samma hästidentitet ───────────── ]]
do
	local n = #UBRFSpel.ordning
	check("stallet har hästar att dela ut", n > 0, n .. " st")

	--[[ Utan reservation ger ren modulo samma häst till två spelare vars
		UserId skiljer sig med exakt antalet hästar. Det är inte en
		konstruerad situation — det är var 33:e spelare. ]]
	local a, b = Stallet.tilldela(1000), Stallet.tilldela(1000 + n)
	check("ren modulo krockar för userId som skiljer antalet hästar", a == b,
		a .. " för både 1000 och " .. (1000 + n))

	local forst = Stallet.tilldelaLedig(1000, {})
	local sedan = Stallet.tilldelaLedig(1000 + n, { [forst] = true })
	check("reservationen ger den andra spelaren en annan häst",
		sedan ~= nil and sedan ~= forst, tostring(forst) .. " → " .. tostring(sedan))

	--[[ Stabiliteten får inte gå förlorad: är din häst ledig ska du få
		henne, varje gång. Annars finns inget förhållande att bygga. ]]
	check("samma spelare får samma häst när hon är ledig",
		Stallet.tilldelaLedig(1000, {}) == forst, forst)

	--[[ Fullt stall ska ge nil — vänta — inte en dubblett. ]]
	local alla = {}
	for _, id in ipairs(UBRFSpel.ordning) do alla[id] = true end
	check("fullt stall ger nil i stället för en dubblett",
		Stallet.tilldelaLedig(7, alla) == nil)

	--[[ Alla n spelare i följd ska få var sin unik häst, och den n+1:e ska
		få nil. Provet räknar unika svar i stället för att lita på ett par. ]]
	local tagna, unika = {}, 0
	for uid = 1, n do
		local id = Stallet.tilldelaLedig(uid, tagna)
		if id and not tagna[id] then
			tagna[id] = true
			unika += 1
		end
	end
	check("hela stallet kan delas ut utan dubbletter", unika == n,
		unika .. " unika av " .. n)
	check("spelare " .. (n + 1) .. " får vänta", Stallet.tilldelaLedig(n + 1, tagna) == nil)

	--[[ dagensHast ska ärva reservationen, inte gå förbi den. ]]
	local d = Stallet.dagensHast(1000, { [forst] = true })
	check("dagensHast respekterar upptagna hästar",
		d ~= nil and d.id ~= forst, d and d.id or "nil")
end

--[[ ── Vyn som går till klienten ───────────────────────────────────── ]]
do
	local s = Preparation.nyState("cosmo")
	Preparation.utfor(s, "halsa", "cosmo")
	local vy = Preparation.vy(s, Preparation.STATUS.FORBEREDER)

	check("vyn har ett steg per förberedelsefas", #vy.steg == 4, #vy.steg .. " rader")
	check("vyn markerar det som är gjort", vy.steg[1].klar == true and vy.steg[2].klar == false)
	check("vyn pekar ut nästa steg", vy.nasta == "visitera", tostring(vy.nasta))
	check("vyn är inte redo än", vy.redo == false)

	--[[ Utan tilldelning ska vyn vara tom men giltig — klienten ritar den
		utan att först behöva kontrollera nil. ]]
	local tom = Preparation.vy(nil, Preparation.STATUS.VANTAR_MODELL)
	check("vy utan tilldelning är tom men giltig",
		tom.status == "waiting_model" and #tom.steg == 0 and tom.redo == false)
end

--[[ ── Krav 8: uppsittningsprompten fail-closed ────────────────────
	Fälldes av senior review på #61. Den första versionen prövade riktigt
	`G01Enabled == true`, men använde svaret som `if not g01Pa() then return
	true` — så `nil` gick rakt in i legacy-grenen och VISADE prompten. Precis
	det join-race kravet finns till för, bakom en kommentar som påstod rätt
	beteende. Beslutet är därför utflyttat ur en lokal funktion och provas
	här. ]]
do
	local P = InteractionController.promptSynlig

	--[[ Det här är provet som saknades. Faller det är loopen fail-open igen. ]]
	check("nil (klienten hann före servern) gömmer prompten",
		P(nil, false) == false and P(nil, true) == false,
		"nil → aldrig synlig, oavsett ready-check")

	check("true + inte redo gömmer prompten", P(true, false) == false)
	check("true + redo visar prompten", P(true, true) == true)

	--[[ nil och false får INTE ge samma svar. Slås de ihop till en boolean är
		buggen tillbaka utan att något annat prov märker det. ]]
	check("false (loopen avstängd) är legacy och visar prompten",
		P(false, false) == true)
	check("nil och false ger olika svar",
		P(nil, false) ~= P(false, false), "nil=false, false=true")
end

--[[ ── Krav 10: en äldre vy får aldrig skriva över en nyare ──────────
	Handskakningens svar och en spontan sync kan komma i vilken ordning som
	helst. Utan serienummer backar HUD:en till ett äldre läge. ]]
do
	local F = Preparation.farRita

	check("första vyn ritas alltid", F(nil, { rev = 1 }) == true)
	check("nyare vy ritas", F(3, { rev = 4 }) == true)
	check("äldre vy kastas", F(4, { rev = 3 }) == false)
	check("samma revision ritas inte om", F(4, { rev = 4 }) == false)

	--[[ Skräp över nätet ska inte kunna nolla HUD:en. ]]
	check("vy utan revision kastas", F(1, {}) == false)
	check("icke-tabell kastas", F(1, "hej") == false)

	--[[ Revisionen måste finnas i det servern faktiskt skickar, annars är
		regeln ovan verkningslös. ]]
	local st = Preparation.nyState("cosmo")
	local vy = Preparation.vy(st, Preparation.STATUS.FORBEREDER, 7)
	check("servervyn bär sin revision", vy.rev == 7, tostring(vy.rev))
	local tomVy = Preparation.vy(nil, Preparation.STATUS.VANTAR_MODELL, 2)
	check("även den tomma vyn bär revision", tomVy.rev == 2)
end

--[[ ── Krav 6: grindens INKOPPLING, inte bara dess regel ─────────────
	Senior review accepterade placeringen (först i `HorseService.tryMount`
	i stället för före anropet) men krävde bevis för att den faktiskt körs
	före sessions-/seat-/mount-logiken.

	Beviset ligger i VILKET fel som kommer tillbaka. Modellen nedan är
	oregistrerad, så mount-logiken skulle svara "Hästen är inte registrerad".
	Får vi i stället grindens eget skäl har grinden kört FÖRST. Får vi
	registreringsfelet har grinden släppt igenom — och då är det beviset att
	den passerade, inte att den saknas. ]]
do
	local cosmoModell = { HorseId = "cosmo" }
	function cosmoModell:GetAttribute(k) return (self :: any)[k] end
	local airModell = { HorseId = "air" }
	function airModell:GetAttribute(k) return (self :: any)[k] end

	local spelare = { Name = "Prov", UserId = 1 }
	local st = Preparation.nyState("cosmo")

	--[[ Samma funktion som GameplayService registrerar. ]]
	HorseService.setMountGate(function(_, modell)
		return Preparation.provaModell(st, modell:GetAttribute("HorseId"))
	end)

	local ok, skal = HorseService.tryMount(spelare, cosmoModell)
	check("oförberedd spelare stoppas av grinden", not ok, tostring(skal))
	check("...och stoppas FÖRE mount-logiken",
		skal ~= nil and skal ~= "Hästen är inte registrerad",
		"fick: " .. tostring(skal))

	local ok2, skal2 = HorseService.tryMount(spelare, airModell)
	check("annans häst stoppas av grinden", not ok2 and skal2 == "Det är inte din häst",
		tostring(skal2))

	for _, f in ipairs(Preparation.stegFaser()) do
		Preparation.utfor(st, f.id, "cosmo")
	end
	local ok3, skal3 = HorseService.tryMount(spelare, cosmoModell)
	check("färdig förberedelse SLÄPPS IGENOM till mount-logiken",
		not ok3 and skal3 == "Hästen är inte registrerad",
		"grinden passerade; mount-logiken svarade: " .. tostring(skal3))

	--[[ Utan registrerad grind ska hästsystemet bete sig precis som före den
		här skivan, annars kan movement-specarna inte köra det ensamt. ]]
	HorseService.setMountGate(nil)
	local ok4, skal4 = HorseService.tryMount(spelare, cosmoModell)
	check("utan grind är beteendet oförändrat",
		not ok4 and skal4 == "Hästen är inte registrerad", tostring(skal4))
end

--[[ ── Produktionens UPPKOPPLING, inte bara dess regler ────────────
	Senior review runda 2 fällde tre saker som alla var samma sak: specen
	provade regler och lät wiringen vara oprovad. Ett prov som registrerar
	sin EGEN grind bevisar att kroken fungerar — inte att GameplayService
	använder den.

	Här körs riktiga `GameplayService.start()`. Faller något av proven nedan
	är det produktionens uppkoppling som gått sönder, inte en regel. ]]
do
	--[[ Serverläge: Networking väljer väg på IsServer, och utan det här
		väntar den på en mapp som ingen skapar. ]]
	game:GetService("RunService")._server = true

	local spelare = { Name = "Prov", UserId = 4242 }
	game:GetService("Players")._spelare = { spelare }

	--[[ Riggen står i världen med rätt identitet. `tilldela` körs av
		StallService.start(); vi läser vilken häst spelaren fick och taggar
		en modell med exakt det id:t. ]]
	StallService.start()
	local hastId = StallService.hastIdFor(spelare)
	check("StallService äger tilldelad HorseId", hastId ~= nil, tostring(hastId))

	local modell = Instance.new("Model")
	modell.Name = "Hast"
	modell:SetAttribute("HorseId", hastId)
	modell.PrimaryPart = nil
	game:GetService("CollectionService"):AddTag(modell, "Horse")

	GameplayService.start()

	--[[ KRAV: en mutation som tar bort
		`HorseService.setMountGate(GameplayService.farSittaUpp)` ur start()
		ska fälla det här. Utan registrering svarar tryMount med
		"Hästen är inte registrerad" i stället för förberedelsens skäl. ]]
	local ok, skal = HorseService.tryMount(spelare, modell)
	check("start() registrerar den riktiga grinden i HorseService",
		not ok and skal ~= "Hästen är inte registrerad",
		"tryMount svarade: " .. tostring(skal))

	--[[ G01-flaggan sätts av servern, inte av klienten. ]]
	check("start() sätter G01Enabled",
		game:GetService("ReplicatedStorage"):GetAttribute("G01Enabled") == true)

	--[[ KRAV: handskakningen ska faktiskt vara registrerad server-side.
		En mutation som tar bort `PreparationHello`-wiringen fäller det här. ]]
	local hello = Networking.get("PreparationHello")
	check("PreparationHello är registrerad server-side",
		type(hello.OnServerInvoke) == "function")

	local snapshot = hello.OnServerInvoke(spelare)
	check("handskakningen ger hela nuläget",
		type(snapshot) == "table" and snapshot.hastId == hastId
			and #snapshot.steg == 4 and type(snapshot.rev) == "number",
		"hastId=" .. tostring(snapshot and snapshot.hastId))

	--[[ Steg hela vägen till redo. Avståndet kan inte prövas i bänken (ingen
		karaktär), så regeln körs direkt på tillståndet — samma
		`Preparation.utfor` som servern anropar. ]]
	local st = GameplayService.stateFor(spelare)
	check("GameplayService håller ett tillstånd för spelaren", st ~= nil)
	for _, f in ipairs(Preparation.stegFaser()) do
		Preparation.utfor(st, f.id, hastId)
	end

	--[[ Produktionsregeln `bunden[player] == modell`: en ANNAN modell med
		samma id som tjänsten inte bundit får inte släppas igenom.

		Provet ligger EFTER att förberedelsen är klar med flit. Låg det före
		blev det grönt av fel skäl — då avvisades dubbletten för att stegen
		återstod, inte för att den var obunden, och regeln kunde tas bort
		utan att något blev rött. Därför krävs det exakta skälet. ]]
	local dubblett = Instance.new("Model")
	dubblett.Name = "Kopia"
	dubblett:SetAttribute("HorseId", hastId)
	local okD, skalD = GameplayService.farSittaUpp(spelare, dubblett)
	check("en obunden modell med samma id avvisas ÄVEN när allt är gjort",
		not okD and skalD == "Det är inte din häst", tostring(skalD))
	local ok2, skal2 = HorseService.tryMount(spelare, modell)
	check("färdig förberedelse släpps igenom av den RIKTIGA grinden",
		not ok2 and skal2 == "Hästen är inte registrerad",
		"grinden passerade; mount-logiken svarade: " .. tostring(skal2))

	game:GetService("RunService")._server = false
end

--[[ ── Sen klient-init: snapshot ska väcka prompten ─────────────────
	Senior review runda 2, blockerare 3. Prompt-uppdateringen låg i en EGEN
	`PreparationSync`-listener. Handskakningens svar går inte genom den, så
	en klient som initierades sent när servern redan stod på ready_to_mount
	fick rätt HUD men aldrig någon "Sitt upp"-prompt.

	Provet driver den riktiga `PreparationController.tillampa` — samma väg
	som nätet — och kräver att observatören körs UTAN att någon
	`PreparationSync` följer efter. ]]
do
	local vackt = 0
	PreparationController.vidNyVy(function() vackt += 1 end)

	local st = Preparation.nyState("cosmo")
	for _, f in ipairs(Preparation.stegFaser()) do
		Preparation.utfor(st, f.id, "cosmo")
	end
	local snapshot = Preparation.vy(st, Preparation.STATUS.REDO, 1)
	check("snapshoten är redo", snapshot.redo == true)

	PreparationController.tillampa(snapshot)
	check("en accepterad snapshot väcker prompt-uppdateringen", vackt == 1,
		vackt .. " anrop — utan efterföljande PreparationSync")
	check("klienten läser redo ur snapshoten", PreparationController.redo() == true)
	check("klienten läser hästId ur snapshoten",
		PreparationController.hastId() == "cosmo")

	--[[ En äldre vy får varken ritas eller väcka observatören — annars kan
		en sen snapshot backa både HUD och prompt. ]]
	local gammal = Preparation.vy(Preparation.nyState("air"),
		Preparation.STATUS.FORBEREDER, 0)
	PreparationController.tillampa(gammal)
	check("en äldre vy väcker inte observatören", vackt == 1, vackt .. " anrop")
	check("en äldre vy ändrar inte klientens läge",
		PreparationController.hastId() == "cosmo" and PreparationController.redo() == true)
end

--[[ ── start(): listenern FÖRE handskakningen ──────────────────────
	Den sista biten oprovad wiring. `PreparationController.start()` ansluter
	`PreparationSync` och anropar sedan `PreparationHello`. Ordningen ÄR
	kontraktet: en RemoteEvent som avfyras innan någon lyssnar är borta för
	alltid, så anropas handskakningen först kan serverns svar — och varje
	sync som hinner emellan — gå förlorat.

	Provet kör riktiga `start()` och mäter hur många lyssnare som fanns på
	`PreparationSync` i det ögonblick handskakningen anropades. Byts de två
	raderna i produktionen blir siffran 0. ]]
do
	game:GetService("RunService")._server = true
	local sync = Networking.get("PreparationSync")
	local hello = Networking.get("PreparationHello")

	local lyssnareVidAnrop = -1
	local anropad = false
	hello.InvokeServer = function()
		anropad = true
		lyssnareVidAnrop = #sync.OnClientEvent._lyssnare
		local st = Preparation.nyState("cosmo")
		for _, f in ipairs(Preparation.stegFaser()) do
			Preparation.utfor(st, f.id, "cosmo")
		end
		return Preparation.vy(st, Preparation.STATUS.REDO, 99)
	end

	PreparationController.start()

	check("start() anropar handskakningen", anropad)
	check("listenern var ansluten INNAN handskakningen anropades",
		lyssnareVidAnrop >= 1, lyssnareVidAnrop .. " lyssnare vid anropet")

	--[[ Och snapshoten ska faktiskt ha tagits emot, inte bara hämtats. ]]
	check("snapshoten från start() är mottagen",
		PreparationController.hastId() == "cosmo" and PreparationController.redo() == true)

	--[[ En sync som kommer efter med LÄGRE revision får inte backa läget —
		det är den vägen som finns i produktionen, via listenern. ]]
	sync.OnClientEvent:Fire(Preparation.vy(Preparation.nyState("air"),
		Preparation.STATUS.FORBEREDER, 5))
	check("en äldre sync via den riktiga listenern backar inte läget",
		PreparationController.hastId() == "cosmo" and PreparationController.redo() == true)

	--[[ ...men en NYARE ska gå igenom hela vägen. ]]
	sync.OnClientEvent:Fire(Preparation.vy(Preparation.nyState("air"),
		Preparation.STATUS.FORBEREDER, 100))
	check("en nyare sync via den riktiga listenern går igenom",
		PreparationController.hastId() == "air" and PreparationController.redo() == false)

	game:GetService("RunService")._server = false
end

if fails > 0 then
	print(string.format("\n%d FEL", fails))
	error("forberedelse.spec: " .. fails .. " fel")
end
print("\nalla gröna")
