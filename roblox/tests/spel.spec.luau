--!nostrict
--[[
	Speldatan och stallet — provar REGLERNA, inte bara att filerna finns.

	Två saker som lätt går sönder tyst:
	  · exporten glider isär från src/spel/hastar.js (samma fel som redan
	    fällt geometrin: två sanningar om samma sak),
	  · en hästs box hamnar utanför stallet, eller två hästar i samma box.

	Kör: python3 roblox/tests/build.py tests/spel.spec.luau
	     && luau roblox/tests/.build/spel.spec.luau
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

local S = UBRFKomplex.stall

--[[ ── Datan ──────────────────────────────────────────────────────── ]]
do
	local antal = #UBRFSpel.ordning
	check("hästarna finns", antal > 0, antal .. " st")

	local saknar = {}
	for _, id in ipairs(UBRFSpel.ordning) do
		if not UBRFSpel.hastar[id] then table.insert(saknar, id) end
	end
	check("varje id i ordning har en häst", #saknar == 0, table.concat(saknar, ", "))

	--[[ Ordningen ska täcka HELA rostern. Fattas en häst i ordning blir hon
		osynlig i listor och kan aldrig tilldelas — utan att något går fel. ]]
	local iOrdning = {}
	for _, id in ipairs(UBRFSpel.ordning) do iOrdning[id] = true end
	local utanfor = {}
	for id in pairs(UBRFSpel.hastar) do
		if not iOrdning[id] then table.insert(utanfor, id) end
	end
	check("ingen häst saknas i ordning", #utanfor == 0, table.concat(utanfor, ", "))

	local utanFoder = {}
	for _, id in ipairs(UBRFSpel.ordning) do
		if not UBRFSpel.foder[id] then table.insert(utanFoder, id) end
	end
	check("varje häst har en foderrad", #utanFoder == 0, table.concat(utanFoder, ", "))

	--[[ Kraftfodret måste vara ett av de val spelet kan visa. Ett stavfel
		här ger en tom knapp i stallet i stället för ett fel. ]]
	local giltigt = {}
	for _, k in ipairs(UBRFSpel.kraftval) do giltigt[k] = true end
	local okant = {}
	for id, f in pairs(UBRFSpel.foder) do
		if not giltigt[f.kraft] then table.insert(okant, id .. "=" .. tostring(f.kraft)) end
	end
	check("allt kraftfoder finns i kraftval", #okant == 0, table.concat(okant, ", "))

	--[[ Beskrivningarna är ordagranna från ubrf.se. En tom sådan betyder att
		någon råkat tappa den i en flytt. ]]
	local tomma = {}
	for _, id in ipairs(UBRFSpel.ordning) do
		local h = UBRFSpel.hastar[id]
		if not h.besk or h.besk == "" or not h.namn or h.namn == "" then
			table.insert(tomma, id)
		end
	end
	check("alla har namn och beskrivning", #tomma == 0, table.concat(tomma, ", "))
end

--[[ ── Boxarna ────────────────────────────────────────────────────── ]]
do
	local antal = Stallet.boxantal()
	check("boxantalet följer stalldatan",
		antal == #S.rader * S.antalBoxar,
		antal .. " = " .. #S.rader .. " rader × " .. S.antalBoxar)

	check("det finns fler boxar än hästar", antal >= #UBRFSpel.ordning,
		antal .. " boxar, " .. #UBRFSpel.ordning .. " hästar")

	check("box utanför intervallet ger nil",
		Stallet.box(0) == nil and Stallet.box(antal + 1) == nil)

	--[[ Varje box ska ligga INNE i stallet. Ett fel i vetter-tecknet lägger
		halva stallet utanför väggen, och det märks inte förrän någon står
		i Studio och undrar var hästarna tog vägen. ]]
	local utanfor = 0
	for n = 1, antal do
		local b = Stallet.box(n)
		if b.lokal.x < 0 or b.lokal.x > S.bredd
			or b.lokal.y < 0 or b.lokal.y > S.langd then
			utanfor += 1
		end
	end
	check("alla boxar ligger inom stallets fotavtryck", utanfor == 0,
		utanfor .. " utanför av " .. antal)

	--[[ Världskoordinaten ska vara lokal + origo. Testet finns för att den
		förväxlingen redan hänt en gång i det här repot. ]]
	local b1 = Stallet.box(1)
	check("världskoordinaten är lokal + origo",
		math.abs(b1.varld.x - (S.origo.x + b1.lokal.x)) < 0.001
			and math.abs(b1.varld.y - (S.origo.y + b1.lokal.y)) < 0.001,
		string.format("box 1 lokalt (%.2f, %.2f)", b1.lokal.x, b1.lokal.y))
end

--[[ ── Tilldelningen ──────────────────────────────────────────────── ]]
do
	--[[ Ingen häst får dela box med en annan. Utan det här provet kan
		fördelningen se rimlig ut och ändå stapla två hästar på varandra. ]]
	local upptagen, krockar = {}, {}
	for _, id in ipairs(UBRFSpel.ordning) do
		local n = Stallet.boxNummerFor(id)
		if not n then
			table.insert(krockar, id .. " fick ingen box")
		elseif upptagen[n] then
			table.insert(krockar, id .. " delar box " .. n .. " med " .. upptagen[n])
		else
			upptagen[n] = id
		end
	end
	check("varje häst har en egen box", #krockar == 0, table.concat(krockar, "; "))

	--[[ Fördelningen ska sprida sig över raderna. Fyller den en rad i taget
		står halva stallet tomt — inte fel, men fel KÄNSLA. ]]
	local perRad = {}
	for _, id in ipairs(UBRFSpel.ordning) do
		local b = Stallet.boxFor(id)
		perRad[b.rad] = (perRad[b.rad] or 0) + 1
	end
	local anvanda = 0
	for _ in pairs(perRad) do anvanda += 1 end
	check("hästarna sprids över alla boxrader", anvanda == #S.rader,
		anvanda .. " rader av " .. #S.rader)

	--[[ Samma spelare ska möta samma häst nästa gång. Utan stabilitet finns
		inget förhållande att bygga, och hela loopen tappar sin poäng. ]]
	local a = Stallet.tilldela(123456)
	local b = Stallet.tilldela(123456)
	check("tilldelningen är stabil för samma spelare", a == b, a)

	--[[ ...men får inte ge ALLA samma häst. ]]
	local sedda = {}
	for uid = 1, 200 do sedda[Stallet.tilldela(uid)] = true end
	local olika = 0
	for _ in pairs(sedda) do olika += 1 end
	check("olika spelare kan få olika hästar", olika > 1,
		olika .. " olika hästar på 200 spelare")

	--[[ Ett negativt UserId ska inte ge nil. Roblox Studio kör med negativa
		id:n i Play Solo, så det är inte ett teoretiskt fall — det är det
		Tobias faktiskt kommer att köra.

		Provet är SVAGT: det föll inte när skyddet mot negativa tal togs bort,
		för Luas modulo klarar dem redan. Det står kvar som en spärr mot att
		någon senare byter till en formel som INTE gör det. ]]
	local solo = Stallet.tilldela(-12345)
	check("negativt UserId ger en häst (Studio Play Solo)",
		solo ~= nil and UBRFSpel.hastar[solo] ~= nil, tostring(solo))

	local d = Stallet.dagensHast(1)
	check("dagensHast ger namn, foder och box",
		d ~= nil and d.namn ~= nil and d.foder ~= nil and d.box ~= nil,
		d and (d.namn .. " i box " .. d.box.nummer .. " (rad " .. d.box.rad .. ")") or "nil")
end

--[[ ── Skötseln ───────────────────────────────────────────────────
	Reglerna är hästkunskap, inte spelbalans. Provet vaktar just det som
	skulle göra spelet lättare och sämre om någon justerade det slarvigt. ]]
do
	local R = UBRFSpel.rykt
	check("ryktzonerna finns", R and #R.zoner > 0, R and #R.zoner .. " zoner")
	check("redskapen finns", R and #R.redskap > 0, R and #R.redskap .. " st")

	--[[ Varje zontyp måste ha ett krav, annars går zonen inte att bli klar
		med och spelaren fastnar utan att förstå varför. ]]
	local utanKrav = {}
	local sedda = {}
	for _, z in ipairs(R.zoner) do
		if not sedda[z.typ] then
			sedda[z.typ] = true
			if not R.krav[z.typ] then table.insert(utanKrav, z.typ) end
		end
	end
	check("varje zontyp har ett redskapskrav", #utanKrav == 0, table.concat(utanKrav, ", "))

	--[[ Ett krav som nämner ett redskap som inte finns ger en zon som aldrig
		blir ren, oavsett vad spelaren gör. ]]
	local finns = {}
	for _, r in ipairs(R.redskap) do finns[r.id] = true end
	local okant = {}
	for typ, lista in pairs(R.krav) do
		for _, id in ipairs(lista) do
			if not finns[id] then table.insert(okant, typ .. "=" .. id) end
		end
	end
	check("alla krav pekar på ett redskap som finns", #okant == 0, table.concat(okant, ", "))

	--[[ HÄSTKUNSKAP, inte balans: huvudet tål bara den mjuka borsten. Skrapa
		och kardborste på ett huvud gör ont. Faller det här har någon gjort
		spelet "smidigare" och tagit bort själva lärdomen. ]]
	local huvud = R.krav.huvud
	check("huvudet tål BARA den mjuka borsten",
		huvud ~= nil and #huvud == 1 and huvud[1] == "mjuk",
		huvud and table.concat(huvud, ", ") or "inget krav")

	--[[ Benen tål inte gummiskrapan heller. ]]
	local ben = R.krav.ben
	local benHarSkrapa = false
	for _, id in ipairs(ben or {}) do if id == "skrapa" then benHarSkrapa = true end end
	check("benen ryktas inte med gummiskrapa", ben ~= nil and not benHarSkrapa,
		ben and table.concat(ben, ", ") or "inget krav")

	check("sadlingen har sina faser", #UBRFSpel.sadelfaser >= 4,
		#UBRFSpel.sadelfaser .. " faser")

	local V = UBRFSpel.visitation
	check("visitpunkterna finns", V and #V.punkter > 0, V and #V.punkter .. " punkter")

	--[[ En punkt utan fynd kan aldrig ge något att rapportera. ]]
	local utanFynd = {}
	for _, pkt in ipairs(V.punkter) do
		if not V.fynd[pkt.id] then table.insert(utanFynd, pkt.id) end
	end
	check("varje visitpunkt har ett möjligt fynd", #utanFynd == 0, table.concat(utanFynd, ", "))

	--[[ HÄSTKUNSKAP: eleven RAPPORTERAR ett fynd, hon diagnostiserar inte.
		Exakt ett rätt svar. Två rätta upphäver hela lärdomen. ]]
	local ratta = 0
	for _, sv in ipairs(V.svar) do if sv.ratt then ratta += 1 end end
	check("exakt ETT rätt svar vid ett fynd", ratta == 1, ratta .. " rätta")
end

if fails > 0 then
	print(string.format("\n%d FEL", fails))
	error("spel.spec: " .. fails .. " fel")
end
print("\nalla gröna")
