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
	local klar, skal = Preparation.provaUppsittning(s, HAST)
	check("efter stallets förberedelse går hon att sitta upp på",
		klar == true, tostring(skal))
	for _, f in ipairs(Preparation.stegFaser()) do
		check(("fasen «%s» är klar"):format(f.id), Preparation.fasKlar(s, f.id) == true)
	end
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
	check("och då räcker «Rida nu» hela vägen",
		Preparation.provaUppsittning(s, HAST) == true)
end

print("\n── Belöningen pekar UPPÅT, aldrig nedåt ──")

do
	--[[ `RidKanon` är redan inlinad av bänken; ett dynamiskt require här
		hade letat i en stubbad ReplicatedStorage. ]]
	local bas = RidKanon.START.DAGSFORM

	local auto = Preparation.nyState(HAST, 1)
	Preparation.autoForbered(auto)
	check("«Rida nu» ger noll egen andel", Preparation.egenAndel(auto) == 0,
		("%.2f"):format(Preparation.egenAndel(auto)))

	--[[ Spelaren gör allt själv, genom den riktiga momentvägen. ]]
	local egen = Preparation.nyState(HAST, 1)
	for _, f in ipairs(Preparation.stegFaser()) do
		for _, m in ipairs(Preparation.moment(f.id)) do
			if not m.fel and m.id then
				Preparation.utforMoment(egen, f.id, m.id, HAST)
			end
		end
	end
	local andel = Preparation.egenAndel(egen)
	check("egen skötsel ger en andel över noll", andel > 0, ("%.2f"):format(andel))

	--[[ Energin vid uppsittning: omsorgen ska SYNAS, och botten ska vara
		kanonens standardhäst — inte sämre. ]]
	local eAuto = Svar.startEnergi(bas)
	local eEgen = Svar.startEnergi(math.clamp(bas + 0.25 * andel, 0, 1))
	check("den som skött om henne får mer att ge", eEgen > eAuto,
		("auto %.3f → egen %.3f"):format(eAuto, eEgen))
	check("och «Rida nu» ger exakt kanonens standardhäst",
		math.abs(eAuto - Svar.startEnergi()) < 1e-9,
		("%.3f"):format(eAuto))
	check("ingen väg ger en SÄMRE häst än standard", eAuto >= Svar.startEnergi(),
		("%.3f >= %.3f"):format(eAuto, Svar.startEnergi()))
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
