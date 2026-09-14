--!nostrict
--[[
	RIDE FIRST — skötseln ska göra ritten bättre, inte spärra den.

	Produktbeslutet: spelaren kommer främst för att rida. Förberedelserna är
	bonus, inte barriär. Men två saker får aldrig gå förlorade på vägen:

	1. Hästen ska VARA korrekt och säkert förberedd även när spelaren valde
	   "Rida nu". Spelet får inte lära ut fel hästhantering för att spara
	   tid — och den fysiska utrustningen måste faktiskt sitta på hästen,
	   inte bara vara en bock i en tabell (#162 blockerare 5).

	2. Välfärdsstoppet ska överleva genvägen. Hästens dagstillstånd finns
	   oavsett om någon tittar.

	Och belöningen ska läsa rätt håll: den som skött om henne får en
	harmoniskare häst — inte "den som hoppade över får en trasig".

	Kör: python3 roblox/tests/build.py tests/ridefirst.spec.luau
	     && luau roblox/tests/.build/ridefirst.spec.luau
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

local HAST = "blackrock_jack"

print("\n── Utan skötsel spärrar grinden, som förut ──")

do
	local s = Preparation.nyState(HAST, 1)
	local ok, skal = Preparation.provaUppsittning(s, HAST)
	check("en orörd häst får inte ridas", ok == false and skal == "pass.aterstar",
		tostring(skal))
end

print("\n── «Rida nu»: stallets förberedelse räcker hela vägen ──")

do
	local s = Preparation.nyState(HAST, 1)
	local ok = Preparation.autoForbered(s)
	check("autoForbered svarar", ok == true)
	for _, f in ipairs(Preparation.stegFaser()) do
		if f.id ~= "leda" then
			check(("fasen «%s» är klar"):format(f.id),
				Preparation.fasKlar(s, f.id) == true)
		end
	end

	--[[ ── DEN VIKTIGASTE RADEN I HELA PROVET ──────────────────────────
		Stallets hand får ALDRIG kvittera en förflyttning som inte skett.
		Står hästen kvar i boxen ska hon inte vara uppsittningsklar. ]]
	check("«leda» är INTE kvitterad av stallet",
		Preparation.fasKlar(s, "leda") == false)
	check("och inget är skrivet i state om att hon letts någonstans",
		next(s.gjorda["leda"] or {}) == nil)
	local klar, skal = Preparation.provaUppsittning(s, HAST)
	check("en häst som står kvar i boxen är INTE uppsittningsklar",
		klar == false, tostring(skal))
end

print("\n── Genvägen kvitterar ALDRIG ett felaktigt moment ──")

do
	--[[ `m.fel` är fel hästhantering. Att markera dem som gjorda vore att
		låta genvägen lära ut precis det spelet finns för att lära rätt. ]]
	local s = Preparation.nyState(HAST, 1)
	Preparation.autoForbered(s)
	local felkvitterade = {}
	for _, f in ipairs(Preparation.stegFaser()) do
		for _, m in ipairs(Preparation.moment(f.id)) do
			if m.fel and (s.gjorda[f.id] or {})[m.id] then
				table.insert(felkvitterade, f.id .. "/" .. tostring(m.id))
			end
		end
	end
	check("inget felaktigt alternativ är kvitterat", #felkvitterade == 0,
		#felkvitterade == 0 and "-" or table.concat(felkvitterade, ", "))
end

print("\n── Välfärdsstoppet överlever genvägen ──")

do
	--[[ Ett pass med fynd. Stallet SER det — men beslutet är spelarens, och
		hästen rids inte förrän hon fått sitt svar. ]]
	local pass, s = 2, nil
	for p = 2, 40 do
		local kandidat = Preparation.nyState(HAST, p)
		if kandidat.fynd then pass, s = p, kandidat break end
	end
	if not s then
		check("hittade ett pass med fynd att prova mot", false,
			"inget fynd i pass 2–40 för " .. HAST)
	else
		check(("pass %d bär ett fynd"):format(pass), s.fynd ~= nil, tostring(s.fynd))
		Preparation.autoForbered(s)
		check("stallet SÅG fyndet", s.fyndSett == true)
		check("men det är inte besvarat åt spelaren", s.fyndRapporterat ~= true)
		--[[ `fasKlar` räknas ur MOMENTEN och är sann — punkterna är
			visiterade. Spärren ligger i `klara`, som `Preparation.nasta`
			läser, och den sätts inte förrän fyndet är besvarat. ]]
		check("visitationen är inte AVBOCKAD förrän fyndet är besvarat",
			s.klara["visitera"] ~= true)
		local klar, skal = Preparation.provaUppsittning(s, HAST)
		check("hästen får INTE ridas förrän fyndet är besvarat",
			klar == false, tostring(skal))
	end
end

print("\n── Första passet är alltid rent — nybörjaren kommer upp direkt ──")

do
	local s = Preparation.nyState(HAST, 1)
	check("pass 1 bär aldrig ett fynd", s.fynd == nil, tostring(s.fynd))
	Preparation.autoForbered(s)
	--[[ Skötseln är klar — men hon måste fortfarande ut ur boxen, och det
		är en fysisk förflyttning som `GameplayService.ridaNu` gör på
		riktigt genom `LedService.placeraVidMal`. ]]
	check("skötseln är klar efter «Rida nu»",
		Preparation.fasKlar(s, "iordning") == true)
	check("men ledningen är kvar som fysiskt krav",
		Preparation.fasKlar(s, "leda") == false)
end

print("\n── Perfekt skötsel är 100 %, inte 96 ──")

do
	local egen = Preparation.nyState(HAST, 1)
	for _, f in ipairs(Preparation.stegFaser()) do
		local val = Preparation.arVal(f.id)
		for _, m in ipairs(Preparation.moment(f.id)) do
			if not m.fel and m.id then
				Preparation.utforMoment(egen, f.id, m.id, HAST)
				if val then break end
			end
		end
	end
	--[[ `leda` går inte att utföra i bänken: den mäter hästens FYSISKA läge
		och kräver världen. Här mäts att ALLT ÖVRIGT ger den andel det ska,
		och sedan att hela vägen ger exakt 1,0 — inte 0,96. ]]
	--[[ NÄMNAREN. `halsa` är en valfas med två riktiga alternativ som
		utesluter varandra — spelaren kan omöjligt hälsa både framifrån och
		bakifrån. Räknades båda kunde perfekt skötsel aldrig nå 1,0, och
		det gjorde den inte heller: full manuell vård landade på 0,96.

		Beviset står i blocket längst ned: ETT utfört moment ger 1/22, inte
		1/23. Nämnaren är alltså det arbete som faktiskt går att utföra
		rätt, inte varje alternativ som finns att rita. ]]
	for _, m in ipairs(Preparation.moment("leda")) do
		if not m.fel and m.id then
			egen.gjorda["leda"] = egen.gjorda["leda"] or {}
			egen.gjorda["leda"][m.id] = true
		end
	end
	check("PERFEKT skötsel når exakt 1,0", Preparation.egenAndel(egen) == 1,
		("%.6f"):format(Preparation.egenAndel(egen)))
end

print("\n── Belöningen märks, men blir aldrig ett dolt krav ──")

do
	local bas = RidKanon.START.DAGSFORM
	local BONUS = 0.06
	local eAuto = Svar.startEnergi(bas)
	local ePerfekt = Svar.startEnergi(math.clamp(bas + BONUS, 0, 1))

	check("«Rida nu» ger exakt kanonens standardhäst",
		math.abs(eAuto - Svar.startEnergi()) < 1e-9, ("%.3f"):format(eAuto))
	check("ingen väg ger en SÄMRE häst än standard", eAuto >= Svar.startEnergi())
	check("egen skötsel märks", ePerfekt > eAuto,
		("%.3f → %.3f"):format(eAuto, ePerfekt))

	--[[ TAKET. En bonus som blir för stor gör frivillig skötsel till en
		optimeringsplikt: den som vill ha bästa hästen MÅSTE då borsta.
		Fem procent är gränsen den här raden håller. ]]
	local lyft = (ePerfekt - eAuto) / eAuto
	check("men lyftet är under 5 % — ingen optimeringsplikt", lyft < 0.05,
		("%.1f %%"):format(lyft * 100))
end


print("\n── FAIL CLOSED: ett misslyckat steg döljs aldrig av auto-state ──")

do
	--[[ `autoForbered` fyller i skötseln. Men den får ALDRIG göra en häst
		färdig vars fysiska steg inte skett — då hade ett produktfel
		maskerats av stallets hand, vilket var hela P0:an i reviewen.

		Två egenskaper bevisar det utan att behöva en värld:
		1. `leda` rörs inte alls — varken `klara` eller `gjorda` får en rad.
		2. `provaUppsittning` faller därför, och faller på `leda`. ]]
	local s = Preparation.nyState(HAST, 1)
	Preparation.autoForbered(s)

	check("auto rör inte «leda» i klara", s.klara["leda"] ~= true)
	check("auto rör inte «leda» i gjorda", next(s.gjorda["leda"] or {}) == nil)

	local klar, skal = Preparation.provaUppsittning(s, HAST)
	check("hästen är INTE uppsittningsklar utan fysisk ledning",
		klar == false, tostring(skal))
	local nasta = Preparation.nasta(s)
	check("och det som återstår ÄR ledningen",
		nasta ~= nil and nasta.id == "leda",
		tostring(nasta and nasta.id))

	--[[ Och när ledningen VERKLIGEN skett — i spelet sätts flaggan av
		`LedService` ur hästens position — då, men först då, är hon klar. ]]
	for _, m in ipairs(Preparation.moment("leda")) do
		if not m.fel and m.id then
			Preparation.utforMoment(s, "leda", m.id, HAST)
		end
	end
	check("men med ledningen verkligen gjord är hon det",
		Preparation.provaUppsittning(s, HAST) == true)
end


print("\n── Egen skötsel räknas, stallets gör det inte ──")

do
	local s = Preparation.nyState(HAST, 1)
	--[[ Ett enda moment gjort för hand, resten av stallet. Momentet måste
		tas ur FÖRSTA fasen: faserna är ordnade med flit, och ett moment ur
		en senare fas nekas av `provaMoment`. ]]
	local forstaFas = Preparation.stegFaser()[1]
	local forsta = Preparation.moment(forstaFas.id)[1]
	local gjord = Preparation.utforMoment(s, forstaFas.id, forsta.id, HAST)
	check(("momentet «%s/%s» gick igenom"):format(forstaFas.id, tostring(forsta.id)),
		gjord == true)
	local eftEtt = Preparation.egenAndel(s)
	Preparation.autoForbered(s)
	local eftAuto = Preparation.egenAndel(s)
	check("andelen ändras inte av att stallet fyller i resten",
		math.abs(eftEtt - eftAuto) < 1e-9,
		("%.4f → %.4f"):format(eftEtt, eftAuto))
	check("och den är större än noll", eftAuto > 0, ("%.4f"):format(eftAuto))
end

if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("\nridefirst.spec: alla gröna")
end
