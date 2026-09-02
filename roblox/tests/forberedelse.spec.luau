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

if fails > 0 then
	print(string.format("\n%d FEL", fails))
	error("forberedelse.spec: " .. fails .. " fel")
end
print("\nalla gröna")
