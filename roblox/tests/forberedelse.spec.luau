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

--[[ ── VÄLFÄRDEN: en häst som vilar arbetar inte (#153 fix 1) ────────
	Webbens spärr satt på ett ställe men kringgicks på tre. Roblox har
	EN choke point — `tilldelaLedig` — och den här gruppen håller den. ]]
do
	--[[ Regeln som läser minnet. Samma form som webbens SPAR.fortroende. ]]
	check("frisk häst vilar inte", Stallet.vilarForSkada({ rang = .5 }) == false)
	check("skada med pass kvar räknas som vila",
		Stallet.vilarForSkada({ skada = { passKvar = 2 } }) == true)
	check("utläkt skada räknas inte som vila",
		Stallet.vilarForSkada({ skada = { passKvar = 0 } }) == false)
	check("skräp i minnet räknas inte som vila",
		Stallet.vilarForSkada(nil) == false
		and Stallet.vilarForSkada({ skada = true }) == false
		and Stallet.vilarForSkada({ skada = { passKvar = "två" } }) == false)

	local minnen = { toblerone = { skada = { passKvar = 2 } },
		lydia = { rang = .5 } }
	local vilar = Stallet.vilandeHastar(minnen)
	check("vilandeHastar plockar ut precis de skadade",
		vilar.toblerone == true and vilar.lydia == nil)

	--[[ Spärren vid tilldelningen: den skadade hästen får aldrig komma ut,
		oavsett vilket UserId som frågar. ]]
	local traffar = 0
	for uid = 1, 40 do
		if Stallet.tilldelaLedig(uid, nil, { toblerone = true }) == "toblerone" then
			traffar += 1
		end
	end
	check("en vilande häst tilldelas aldrig", traffar == 0, traffar .. " av 40")

	--[[ Och när ALLA vilar är tomt ett riktigt svar — ingen tillbakafallning
		på den ofiltrerade listan, vilket var precis webbens fel. ]]
	local allaVilar = {}
	for _, id in ipairs(UBRFSpel.ordning) do allaVilar[id] = true end
	check("alla vilar ⇒ ingen häst delas ut",
		Stallet.tilldelaLedig(7, nil, allaVilar) == nil)
	check("dagensHast ärver välfärdsspärren",
		Stallet.dagensHast(7, nil, allaVilar) == nil)

	--[[ En frisk häst påverkas inte — spärren får inte låsa hela stallet. ]]
	local d2 = Stallet.dagensHast(3, nil, { [UBRFSpel.ordning[1]] = true })
	check("en frisk häst delas fortfarande ut",
		d2 ~= nil and d2.id ~= UBRFSpel.ordning[1], d2 and d2.id or "nil")
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

--[[ ══ HÄSTENS EGNA VÄRDEN HELA VÄGEN TILL RIDNINGEN ═══════════════════
     Senior re-review av #87, blocker 1: profilerna fanns i datat och
     provades syntetiskt, men den VERKLIGA vägen — tilldelning, bindning,
     registrering, MovementController — tappade dem. `resolveStats` läste
     bara Studio-attribut, så varje individ red som `skolhast` med
     standardvärden hur noga tilldelningen än var gjord.

     Provet tar TVÅ RIKTIGA HÄSTAR med olika profil genom hela kedjan och
     kräver att samma hjälp ger mätbart olika svar. En mutation som tar
     bort kanonpåläggningen i HorseService.register ska fälla det. ]]
print("\n── Hästens egna värden når ridningen ──")
do
	local Spel = UBRFSpel

	--[[ Två hästar ur den riktiga rostern, med olika profil OCH olika
	     känslighet. Namnen slås upp i datat i stället för att skrivas av,
	     så provet inte kan bli grönt av att någon bytt profil i källan. ]]
	local kanslig, tung
	for id, h in Spel.hastar do
		if h.profil == "kanslig" and not kanslig then kanslig = id end
		if h.profil == "tung" and not tung then tung = id end
	end
	check("rostern har både en känslig och en tyngre häst att prova med",
		kanslig ~= nil and tung ~= nil,
		string.format("(%s / %s)", tostring(kanslig), tostring(tung)))

	local function ridEfterRegistrering(id)
		local modell = Instance.new("Model")
		modell.Name = "Hast_" .. id
		modell:SetAttribute("HorseId", id)
		local rot = Instance.new("Part")
		rot.Name = "HumanoidRootPart"
		rot.Parent = modell
		modell.PrimaryPart = rot
		local hum = Instance.new("Humanoid")
		hum.Parent = modell
		game:GetService("CollectionService"):AddTag(modell, "Horse")
		HorseService._registerForProv(modell)
		local stats = HorseService._statsFor(modell)
		return stats
	end

	local sK = ridEfterRegistrering(kanslig)
	local sT = ridEfterRegistrering(tung)
	check("den tilldelade hästens profil når HorseStats",
		sK ~= nil and sT ~= nil and sK.Profil == "kanslig" and sT.Profil == "tung",
		string.format("%s → %s · %s → %s", kanslig, tostring(sK and sK.Profil),
			tung, tostring(sT and sT.Profil)))

	--[[ Och att den FAKTISKT ändrar ridningen: samma hjälp, samma
	     bildruta, två olika svar. Det är skillnaden mellan att datat
	     finns och att hästen rider med det. ]]
	local svarK = Svar.svarstid(sK, Svar.kanslighet(
		Config.TEMPERAMENTS[sK.Temperament], sK), 0.8, 1, 0.5)
	local svarT = Svar.svarstid(sT, Svar.kanslighet(
		Config.TEMPERAMENTS[sT.Temperament], sT), 0.8, 1, 0.5)
	check("och den ändrar ridningen: samma hjälp ger olika svar",
		svarK < svarT - 0.02,
		string.format("%s (%s, %s) svarar på %.3f s · %s (%s, %s) på %.3f s",
			kanslig, sK.Profil, sK.Temperament, svarK,
			tung, sT.Profil, sT.Temperament, svarT))
end

--[[ ══ CROSS-PLATFORM-SCENARIOT ═══════════════════════════════════════
     Senior re-review av #87, blocker 2: "formelparitet är grön men
     runtimeparitet är inte samma produktbeteende".

     Golden-raderna bevisade att funktionerna räknar lika på givna tal.
     De bevisade INTE att en ritt utvecklar sig lika — utgångsläget skilde
     sig (webben spänning 0,15 / energi 0,835, Roblox 0 / 1) och ingen
     körning jämfördes.

     Här körs RITTEN. RidKanon.SCENARIO bär webbens egen stepRide, bildruta
     för bildruta, med två verkliga UBRF-hästar och med den context Roblox
     faktiskt har. Uppspelningen går genom en RIKTIG MovementController med
     den häst Stallet delar ut — inte genom direktanrop av svarsmodellen,
     vilket är exakt vad ordern i #83 förbjöd.

     GRÄNSEN, uttryckligen: jämförelsen börjar vid SEMANTISKA HJÄLPER per
     bildruta. Inputadaptern får vara plattformsspecifik enligt
     paritetsregeln — hjälpaxlarna räknas därför om till Roblox
     intent-axlar med KONTAKT:s egna neutrallägen, alltså genom det
     riktiga inputlagret och inte förbi det. ]]
print("\n── Cross-platform: samma ritt på båda ytorna ──")
do
	local SC = RidKanon.SCENARIO
	local KN = RidKanon.KONTAKT
	local dt = 1 / SC.HZ

	--[[ Hjälpsemantiken tillbaka till intent-axlarna. Inversen av det
	     MovementController:step gör i sin första halva, med samma
	     konstanter — så att en scenariorad ger EXAKT den hjälp webben red
	     med, och inte en ungefärlig. ]]
	local function axlar(a)
		local forward = if a.skankel >= KN.SKANKEL_NEUTRAL
			then (a.skankel - KN.SKANKEL_NEUTRAL) / (0.78 - KN.SKANKEL_NEUTRAL)
			else (a.skankel - KN.SKANKEL_NEUTRAL) / (KN.SKANKEL_NEUTRAL - 0.05)
		local rein = (a.tygel - KN.TYGEL_NEUTRAL) / (KN.TYGEL_MAX - KN.TYGEL_NEUTRAL)
		local seat = if a.sits >= KN.SITS_NEUTRAL
			then (a.sits - KN.SITS_NEUTRAL) / (KN.SITS_MAX - KN.SITS_NEUTRAL)
			else (a.sits - KN.SITS_NEUTRAL) / (KN.SITS_NEUTRAL + 0.6)
		return math.clamp(forward, -1, 1), math.clamp(rein, 0, 1),
			math.clamp(seat, -1, 1)
	end

	--[[ Vilken gångart ryttaren bad om vid varje bildruta, ur BEDD. ]]
	local function beddVid(hast)
		local karta, nu = {}, "halt"
		local n = 1
		for i = 0, SC.RUTOR - 1 do
			while n <= #hast.BEDD and hast.BEDD[n].i == i do
				nu = hast.BEDD[n].gangart
				n += 1
			end
			karta[i] = nu
		end
		return karta
	end

	--[[ Hjälperna är GLESA i kanonen — en rad först när något ändras. ]]
	local function hjalpVid()
		local karta, nu = {}, SC.STEG[1]
		local n = 1
		for i = 0, SC.RUTOR - 1 do
			while n <= #SC.STEG and SC.STEG[n].i == i do
				nu = SC.STEG[n]
				n += 1
			end
			karta[i] = nu
		end
		return karta
	end
	local HJALP = hjalpVid()

	--[[ Kör ritten genom en riktig controller och plocka ut samma
	     mätpunkter som webben mätte. Returnerar också hur många bildrutor
	     som behövde mer än ETT steg i gångartstrappan för att hamna rätt
	     — blir det fler än noll jämför scenariot två olika ritter, och
	     då är siffrorna nedan inte värda något. ]]
	local function korRitt(id)
		local hast
		for _, h in SC.HASTAR do if h.id == id then hast = h end end
		--[[ SAMMA VÄG SOM HORSESERVICE tar vid registrering: en riktig
		     Configuration, kanonen påskriven FÖRE writeDefaults, och
		     resolveStats därefter. Att bygga stats-tabellen för hand hade
		     hoppat över exakt den ordning blocker 1 handlade om. ]]
		local cfg = Instance.new("Configuration")
		for nyckel, varde in Stallet.statsFor(id) do
			if varde ~= nil and cfg:GetAttribute(nyckel) == nil then
				cfg:SetAttribute(nyckel, varde)
			end
		end
		Config.writeDefaults(cfg, Config.STATS)
		local mc = MovementController.new(__makeRig(), Config.resolveStats(cfg))
		local BEDD = beddVid(hast)
		local matt, hopp = {}, 0
		local n = 1
		for i = 0, SC.RUTOR - 1 do
			local a = HJALP[i]
			local forward, rein, seat = axlar(a)
			local intent = { forward = forward, steer = a.styrning, rein = rein,
				seat = seat, parad = a.parad, gaitUp = false, gaitDown = false,
				jump = false }
			--[[ SAMMA BEGÄRAN, INTE SAMMA TANGENT. Webbens cue faller ur
			     hjälpens impuls över ett fönster, Roblox ur flanker och
			     W-regeln. Här frågas controllerns EGNA regel vad den skulle
			     välja, och flanken sätts bara för att stänga skillnaden mot
			     vad webbens ryttare bad om. Utan det hade scenariot jämfört
			     två olika ritter — och med mer än ett steg kvar går det inte
			     att stänga på en bildruta, vilket `hopp` räknar. ]]
			local onskad = RidKanon.MOTSVARIGHET[BEDD[i]] or "halt"
			--[[ Paraden räknas på sin STIGANDE FLANK i controllern, så
			     förhandsfrågan här måste ställas med samma flank — annars
			     hade korrigeringen nedan stängt en skillnad som inte finns. ]]
			local paradNu = a.parad > RidKanon.HJALP.PARAD_TROSKEL
			local flank = paradNu and not mc._paradHalls
			local d = Gaits.index(onskad) - Gaits.index(mc:_targetGait(intent, flank))
			if d > 0 then intent.gaitUp = true elseif d < 0 then intent.gaitDown = true end
			if math.abs(d) > 1 then hopp += 1 end
			mc:step(intent, dt)
			while n <= #hast.MATT and hast.MATT[n].i == i do
				local L = mc.loco
				table.insert(matt, { t = hast.MATT[n].t, facit = hast.MATT[n],
					svarstid = L.svarstid or 0, balans = L.balans or 0,
					fokus = L.fokus or 0, spanning = L.spanning or 0,
					energi = L.energi or 0 })
				n += 1
			end
		end
		return matt, hopp, hast
	end

	--[[ TOLERANSERNA. Satta strax över det som FAKTISKT uppmätts, inte
	     löst nog att passera. Uppmätt på den här ritten, största avvikelse
	     över båda hästarna och alla åtta mätpunkter:

	       svarstid  0,0002   (tak 0,005)
	       spanning  0,0087   (tak 0,010)
	       fokus     0,0021   (tak 0,005)
	       balans    0,0122   (tak 0,020)
	       energi    0,0001   (tak 0,005)

	     BALANSEN har det största utrymmet av ett känt skäl: dess
	     övergångsterm är på/av, och de två gångartstabellerna (webbens
	     BAND och Roblox Gaits) släpper förloppet på olika bildruta. De
	     avvikelserna är listade i paritetsspecen och är produktbeslut,
	     inte drift.

	     SPÄNNINGENS 0,0087 ligger i ETT ENDA fönster — 0,30 s, mitt i
	     uppsittningens avklingning — och ingen annanstans i ritten
	     (0,0001 vid 6,0 s, där spänningen är som störst). Storheten
	     faller 0,0074 per bildruta där, så avvikelsen är drygt EN
	     BILDRUTAS förskjutning i när vändpunkten infaller, inte en
	     skillnad i nivå eller form.

	     [ÄRLIG BEGRÄNSNING] Exakt vilken bildruta som skiljer är inte
	     rotorsaksanalyserad. Den syns bara för den känsliga hästen och
	     bara i övergående läge; att jaga den vidare vore att trimma
	     bildruteordning utan spelarvinst. Den är MÄTT och avgränsad, och
	     taket är satt strax över det uppmätta — inte löst nog att gömma
	     något större.

	     RESAN HIT ÄR POÄNGEN: första körningen låg spänningen 0,119 fel
	     och fokus 0,047 fel. Tre riktiga fel föll ut av det —
	     känsligheten kvantiserad genom Temperament, halvhalten läst bara
	     när den råkade byta gångart, och paraden läst per bildruta i
	     stället för per tryck. Formelpariteten var grön hela tiden. ]]
	local TOL = { svarstid = 0.005, spanning = 0.010, fokus = 0.005,
		balans = 0.020, energi = 0.005 }

	for _, hastKanon in SC.HASTAR do
		local matt, hopp = korRitt(hastKanon.id)
		check(string.format("%s: samma gångartsbegäran på båda ytorna",
			hastKanon.id), hopp == 0,
			string.format("(%d bildrutor låg mer än ett steg fel)", hopp))
		check(string.format("%s: alla %d mätpunkter nåddes",
			hastKanon.id, #hastKanon.MATT),
			#matt == #hastKanon.MATT, string.format("(%d av %d)", #matt, #hastKanon.MATT))

		for _, storhet in { "svarstid", "balans", "fokus", "spanning", "energi" } do
			local varst, varstT, rader = 0, 0, {}
			for _, m in matt do
				local d = math.abs(m[storhet] - m.facit[storhet])
				if d > varst then varst, varstT = d, m.t end
				table.insert(rader, string.format("%.1f s %.4f/%.4f",
					m.t, m[storhet], m.facit[storhet]))
			end
			check(string.format("%s · %s följer webben inom %.3f",
				hastKanon.id, storhet, TOL[storhet]),
				varst <= TOL[storhet],
				string.format("(störst %.4f vid %.1f s) %s", varst, varstT,
					table.concat(rader, " · ")))
		end
	end

	--[[ VAD LUCKAN ÄR VÄRD. De nio contextkällor Roblox saknar är inte
	     gratis, och att bara namnge dem säger inte hur mycket de betyder.
	     Samma ritt kördes på webben med webbens egen context, och
	     skillnaden mot facit ovan mäts här. Den ska vara SKILD FRÅN NOLL —
	     annars vore luckorna inget att deklarera — och samtidigt liten nog
	     att den inte förklarar bort en verklig avvikelse. ]]
	for _, h in SC.HASTAR do
		local varst, namn = 0, ""
		for k = 1, #h.MATT do
			for _, storhet in { "svarstid", "balans", "fokus", "spanning", "energi" } do
				local d = math.abs(h.MATT[k][storhet] - h.WEBB[k][storhet])
				if d > varst then varst, namn = d, storhet end
			end
		end
		check(string.format("%s: de deklarerade contextluckorna är MÄTTA, inte gissade",
			h.id), varst > 0.0005 and varst < 0.10,
			string.format("(största skillnad mot webbens egen context: %.4f i %s)",
				varst, namn))
	end
end

if fails > 0 then
	print(string.format("\n%d FEL", fails))
	error("forberedelse.spec: " .. fails .. " fel")
end
print("\nalla gröna")
