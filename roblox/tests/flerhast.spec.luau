--!nostrict
--[[
	FLERA LEDNINGAR SAMTIDIGT — isolering mellan sessioner.

	MULTI_HORSE_LEADING_ACCEPTANCE, punkt 1, 2, 5 och 6 i matrisen.

	── VARFÖR SPECEN BEHÖVS ──────────────────────────────────────────

	Punkt 3 och 4 — att en andra ledare nekas (`led.upptagen`) och att en
	spelare inte får leda två (`led.leder_redan`) — är redan täckta i
	`ledning.spec` och `ledning-integration.spec`. Det är NEJ-vägarna.

	JA-vägen är otäckt. `ledning.spec:459` ser ut att köra två sessioner:
	den skapar `sp2` och `h2`. Men den anropar `LedService._glomForProv()`
	först och mäter agentparametrar — det finns alltså i dag **inget prov
	någonstans där två ledningar lever samtidigt**.

	Det spelar roll därför att tjänsten håller tre register per spelare
	(`ledd`, `senasteLedning`, `uppnatt`) och varje session ett eget
	spår (`spar`), en egen navväg (`navVag`, `navIx`), ett eget ankare
	och en egen dörrplan. Delas något av dem av misstag syns det inte i
	ett enspelarprov — det syns först när två sessioner lever.

	`ledning-integration.spec:406` bär varningen som gäller här:
	«mutationen som tog bort `led.leder_redan` kom ut GRÖN, för ingen …».
	En vakt som ingen mäter är ingen vakt. Varje mätning nedan har därför
	en mutation som gör den röd, och de står i falsifieringen.

	── SEMANTIKEN SOM MÄTS, LÄST UR KODEN ────────────────────────────

	  · en spelare leder EN häst      `ledd` är { [Player]: Led }
	  · en häst har EN ledare         `ledsAv` sveper samma register
	  · flera hästar = flera DISTINKTA spelare↔häst-par

	Specen uppfinner ingen ny regel. Den provar att den befintliga bär
	när mer än ett par finns.

	Kör: python3 roblox/tests/build.py tests/flerhast.spec.luau
	     && luau roblox/tests/.build/flerhast.spec.luau
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

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
RunService._server = true

local M = 3
local function varld(x, y) return vec(x * M, 3, (170 - y) * M) end

local function nyKaraktar(pos)
	local k = Instance.new("Model")
	k.Name = "Karaktar"
	local rot = Instance.new("Part")
	rot.Name = "HumanoidRootPart"
	rot.Size = vec(2, 2, 1)
	rot.CFrame = CFrame.new(pos)
	rot.Parent = k
	k.PrimaryPart = rot
	local hum = Instance.new("Humanoid")
	hum.Name = "Humanoid"
	hum.Parent = k
	k.Parent = workspace
	return k, rot, hum
end

local nastaId = 100
local function nySpelare(namn, pos)
	nastaId += 1
	local k, rot, hum = nyKaraktar(pos)
	return {
		Name = namn, UserId = nastaId, Character = k,
		CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny(),
	}, rot, hum
end

local function nyHast(id, pos)
	local m = Instance.new("Model")
	m.Name = id
	m:SetAttribute("HorseId", id)
	local kropp = Instance.new("Part")
	kropp.Name = "HumanoidRootPart"
	kropp.Size = vec(1.86, 2.34, 5.55)
	kropp.CFrame = CFrame.new(pos)
	kropp.Parent = m
	m.PrimaryPart = kropp
	local hum = Instance.new("Humanoid")
	hum.Name = "Humanoid"
	hum.Parent = m
	m.Parent = workspace
	return m, kropp, hum
end

--[[ IDENTITETEN i en session — de falt som ALDRIG far andras av att en
	annan session lever, slapps eller stegas. Progressionsfalten (`spar`,
	`tid`, `ankare`, `forLangtSedan`) ligger med FLIT utanfor: `_steg` kor
	alla sessioner, sa de SKA rora sig nar tiden gar. Att krava dem
	konstanta hade gjort provet rott av ratt beteende — forsta versionen
	av den har specen gjorde precis det och foll pa `sparN: 0 -> 1`.

	Isoleringen mats i stallet pa tva satt som bada bar:
	  · identiteten nedan ar invariant,
	  · och spar/ankare pekar pa EGEN hast, mats separat i `egetSpar`. ]]
local function identitet(l)
	if l == nil then return nil end
	return {
		hastId = l.hastId,
		modell = l.modell,
		lamnatBox = l.lamnatBox,
		malNatt = l.malNatt,
		boxX = l.boxX, boxY = l.boxY,
	}
end

--[[ Vems brodsmulor ligger i sessionens spar?

	`spar` bokfor LEDARENS positioner — `table.insert(spar, rot.Position)`
	i `_steg`, appenderad nar hon gatt mer an 0,6 m fran forra smulan och
	gallrad nar en smula hamnar langre bort an `MAL_AVVIK`. Det ar hennes
	VAG genom dorren hasten ska folja, inte hastens egen bana.

	Forsta versionen av den har hjalparen jamforde mot HASTARNA. Den blev
	gron — men av en tillfallighet: A:s ledare och A:s hast star nara
	varandra och langt fran B:s par, sa bada jamforelserna pekade at samma
	hall. En mating som ar gron av fel skal ar ingen mating.

	Ankaret ar daremot HASTENS (`l.ankare = pivot.Position`), sa det mats
	mot hasten. Tva olika objekt, med flit, och skalet utskrivet. ]]
local function egetSpar(l, egenLedare, annanLedare, egenHast, annanHast)
	if l == nil then return false, "ingen session" end
	local ep = egenLedare.Position
	local ap = annanLedare.Position
	local fel = 0
	for _, v in ipairs(l.spar or {}) do
		if (v - ap).Magnitude < (v - ep).Magnitude then fel += 1 end
	end
	local ank = l.ankare
	local ankOk = ank == nil
		or (ank - egenHast.PrimaryPart.Position).Magnitude
		   <= (ank - annanHast.PrimaryPart.Position).Magnitude
	return fel == 0 and ankOk,
		("%d av %d smulor vid FEL ledare, ankare %s"):format(
			fel, #(l.spar or {}), ankOk and "vid egen hast" or "vid FEL hast")
end

local function lika(a, b)
	if (a == nil) ~= (b == nil) then return false, "den ena är nil" end
	if a == nil then return true end
	for k, v in pairs(a) do
		if b[k] ~= v then
			return false, ("%s: %s -> %s"):format(k, tostring(v), tostring(b[k]))
		end
	end
	return true
end

--[[ Två boxar långt ifrån varandra, så att ingen mätning kan bli grön av
	att hästarna råkar stå på samma ställe. ]]
local BOX_A = { x = 163.68, y = 77.60 }
local BOX_B = { x = 170.10, y = 95.40 }

print("")
print("FLERA LEDNINGAR SAMTIDIGT (MULTI_HORSE punkt 1, 2, 5, 6)")

--[[ ══ 2. TVÅ SESSIONER LEVER SAMTIDIGT ═══════════════════════════════ ]]
print("\n── 2. Två distinkta par kan leda samtidigt ──")

LedService._glomForProv()

local hastA = nyHast("hast_a", varld(BOX_A.x, BOX_A.y))
local hastB = nyHast("hast_b", varld(BOX_B.x, BOX_B.y))
local spA, rotA, humA = nySpelare("RyttareA", varld(BOX_A.x + 1.0, BOX_A.y))
local spB, rotB, humB = nySpelare("RyttareB", varld(BOX_B.x + 1.0, BOX_B.y))

local okA, skalA = LedService.borja(spA, hastA, hastA)
check("A börjar leda sin häst", okA == true, tostring(skalA))
local okB, skalB = LedService.borja(spB, hastB, hastB)
check("B börjar leda SIN häst medan A leder", okB == true, tostring(skalB))

check("båda sessionerna lever", LedService.aktiv(spA) ~= nil and LedService.aktiv(spB) ~= nil)
check("A:s häst tillhör A", LedService.ledsAv(hastA) == spA)
check("B:s häst tillhör B", LedService.ledsAv(hastB) == spB)
check("ingen korsning i id:na",
	LedService.lage(spA).hastId == "hast_a" and LedService.lage(spB).hastId == "hast_b",
	("%s / %s"):format(LedService.lage(spA).hastId, LedService.lage(spB).hastId))
check("sessionerna är SKILDA tabeller — inte en delad referens",
	LedService.lage(spA) ~= LedService.lage(spB))
check("och spåren är skilda tabeller",
	LedService.lage(spA).spar ~= LedService.lage(spB).spar)
check("och navvägarna är skilda tabeller",
	LedService.lage(spA).navVag ~= LedService.lage(spB).navVag)

--[[ == 5. EGET SPAR, EGEN NAVVAG ====================================

	BANKEN SIMULERAR INGEN HASTFYSIK. `Humanoid:MoveTo` i stubben flyttar
	ingenting, sa ett prov som kraver att hasten FORFLYTTAR sig mater
	stubben och inte produkten — forsta versionen gjorde det och foll pa
	«0.00 studs». `ledning.spec` loser det pa samma satt: den flyttar
	hasten sjalv och later `_steg` avgora.

	Hastarna flyttas darfor for hand at var sitt hall, och det som mats ar
	vad SESSIONEN bokforde: ligger hennes spar och ankare vid hennes egen
	hast? Delades ringbufferten skulle den ena sessionens brodsmulor
	hamna vid den andras hast, och det ar precis vad `egetSpar` letar
	efter. ]]
print("\n-- 5. Eget spar, egen navvag --")

for i = 1, 40 do
	--[[ Hasten slapar EFTER ledaren, som en ledd hast gor. Ligger hon
		ovanpa honom gallras sparet till en enda punkt och provet blir
		tunt — forsta versionen matte pa ETT sparvarde. Nu ligger hon
		ett par studs bakom, inom kopplet, och brodsmulorna samlas. ]]
	rotA.CFrame = CFrame.new(varld(BOX_A.x + 1.0 + i * 0.30, BOX_A.y))
	rotB.CFrame = CFrame.new(varld(BOX_B.x + 1.0, BOX_B.y - i * 0.30))
	hastA.PrimaryPart.CFrame = CFrame.new(varld(BOX_A.x + i * 0.30 - 0.6, BOX_A.y))
	hastB.PrimaryPart.CFrame = CFrame.new(varld(BOX_B.x, BOX_B.y - i * 0.30 + 0.6))
	LedService._steg(1 / 30)
end

local lA, lB = LedService.lage(spA), LedService.lage(spB)
check("bada sessionerna lever efter 40 steg", lA ~= nil and lB ~= nil)

if lA and lB then
	check("A:s smulor ar A:s ledares, ankaret A:s hasts", egetSpar(lA, rotA, rotB, hastA, hastB),
		select(2, egetSpar(lA, rotA, rotB, hastA, hastB)))
	check("B:s smulor ar B:s ledares, ankaret B:s hasts", egetSpar(lB, rotB, rotA, hastB, hastA),
		select(2, egetSpar(lB, rotB, rotA, hastB, hastA)))
	check("bada spar innehaller nagot — matningen ar inte tom",
		#(lA.spar or {}) > 0 and #(lB.spar or {}) > 0,
		("A %d punkter, B %d punkter"):format(#(lA.spar or {}), #(lB.spar or {})))
	check("navraknarna ar per session, inte delade",
		lA.navIx ~= nil and lB.navIx ~= nil and lA.navVag ~= lB.navVag)
end

--[[ == 1. ISOLATION: A:S SLAPP ROR INTE B ============================ ]]
print("\n-- 1. Att slappa A lamnar B orord --")

local foreB = identitet(LedService.lage(spB))
local slapptA, skalSlapp = LedService.slapp(spA)
check("A slapper", slapptA == true, tostring(skalSlapp))
check("A:s session ar borta", LedService.aktiv(spA) == nil)
check("B:s session lever kvar", LedService.aktiv(spB) ~= nil)
check("B:s hast har fortfarande B som ledare", LedService.ledsAv(hastB) == spB)
local likaB, varfor = lika(foreB, identitet(LedService.lage(spB)))
check("och B:s identitet ar oforandrad", likaB, varfor or "-")
check("B:s spar och ankare hor fortfarande till B",
	egetSpar(LedService.lage(spB), rotB, rotA, hastB, hastA),
	select(2, egetSpar(LedService.lage(spB), rotB, rotA, hastB, hastA)))
check("B:s boxminne finns kvar efter A:s slapp", LedService.boxminne(spB) ~= nil)

--[[ == 6. VARJE VAG UT SLAPPER BARA SIN EGEN SESSION ================= ]]
print("\n-- 6. Varje vag ut slapper bara sin egen session --")

--[[ a) UPPSITTNING. ]]
do
	LedService._glomForProv()
	local h1 = nyHast("ride_a", varld(BOX_A.x, BOX_A.y))
	local h2 = nyHast("ride_b", varld(BOX_B.x, BOX_B.y))
	local p1, r1, hum1 = nySpelare("Upp1", varld(BOX_A.x + 1.0, BOX_A.y))
	local p2 = nySpelare("Upp2", varld(BOX_B.x + 1.0, BOX_B.y))
	LedService.borja(p1, h1, h1)
	LedService.borja(p2, h2, h2)
	local fore2 = identitet(LedService.lage(p2))
	hum1.Sit = true
	LedService._steg(1 / 30)
	check("uppsittning slapper ledaren som satte sig", LedService.aktiv(p1) == nil)
	check("...men inte den andra", LedService.aktiv(p2) ~= nil)
	check("...och lamnar hennes identitet orord",
		lika(fore2, identitet(LedService.lage(p2))),
		select(2, lika(fore2, identitet(LedService.lage(p2)))) or "-")
	check("...och hennes hast ar fortfarande hennes", LedService.ledsAv(h2) == p2)
end

--[[ b) FOR LANGT. Kopplet kraver avstand OCH tid. ]]
do
	LedService._glomForProv()
	local h1 = nyHast("langt_a", varld(BOX_A.x, BOX_A.y))
	local h2 = nyHast("langt_b", varld(BOX_B.x, BOX_B.y))
	local p1, r1 = nySpelare("Langt1", varld(BOX_A.x + 1.0, BOX_A.y))
	local p2 = nySpelare("Langt2", varld(BOX_B.x + 1.0, BOX_B.y))
	LedService.borja(p1, h1, h1)
	LedService.borja(p2, h2, h2)
	local fore2 = identitet(LedService.lage(p2))
	for _ = 1, 300 do
		r1.CFrame = CFrame.new(varld(BOX_A.x + 60, BOX_A.y))
		LedService._steg(1 / 30)
		if LedService.aktiv(p1) == nil then break end
	end
	check("for langt bort slapper kopplet", LedService.aktiv(p1) == nil)
	check("...men den andra leder vidare", LedService.aktiv(p2) ~= nil)
	check("...med ororD identitet",
		lika(fore2, identitet(LedService.lage(p2))),
		select(2, lika(fore2, identitet(LedService.lage(p2)))) or "-")
end

--[[ c) SPELAREN GAR. `PlayerRemoving`-kroken kopplas i `start()` —
	utan det anropet mater provet en osluten signal. ]]
do
	LedService._glomForProv()
	LedService.start()
	local h1 = nyHast("ut_a", varld(BOX_A.x, BOX_A.y))
	local h2 = nyHast("ut_b", varld(BOX_B.x, BOX_B.y))
	local p1 = nySpelare("Ut1", varld(BOX_A.x + 1.0, BOX_A.y))
	local p2 = nySpelare("Ut2", varld(BOX_B.x + 1.0, BOX_B.y))
	LedService.borja(p1, h1, h1)
	LedService.borja(p2, h2, h2)
	local fore2 = identitet(LedService.lage(p2))
	Players.PlayerRemoving:Fire(p1)
	if Players.PlayerRemoving.slutfor then Players.PlayerRemoving:slutfor() end
	check("spelaren som gick slappte sin hast", LedService.aktiv(p1) == nil)
	check("...och den kvarvarande leder fortfarande", LedService.aktiv(p2) ~= nil)
	check("...hennes hast har henne kvar som ledare", LedService.ledsAv(h2) == p2)
	check("...och hennes identitet ar ororD",
		lika(fore2, identitet(LedService.lage(p2))),
		select(2, lika(fore2, identitet(LedService.lage(p2)))) or "-")
end

--[[ == 9. SKALNING: 1, 2, 4 OCH 8 SAMTIDIGA LEDNINGAR ==============

	DETERMINISTISK BANKMATNING, INTE RUNTIME — och skalet ar matt, inte
	antaget: en syntetisk aktor gar inte att leda i den riktiga motorn.
	`LedService._sync` anropar `ev:FireClient(player, ...)` (rad 1119), och
	en vanlig tabell ger «Unable to cast value to Object». Ingen `Player`
	gar att skapa i nagon trad, och `HorseCore/Aktor.luau` — det deklarerade
	testsatet — finns inte pa den har grenen. Bankens stubbade `FireClient`
	tar daremot en tabell, sa det ar har flera sessioner gar att stalla upp.

	INGEN TIDSTROSKEL PASTAS. Tiden skrivs ut som evidens; det som FALLER
	provet ar korrekthet vid skala — att alla sessioner lever och att varje
	hast fortfarande har ratt ledare nar atta ledningar stegas tillsammans.
	En tidsgrans i en bank pa en maskin vore ett uppfunnet tal. ]]
print("\n-- 9. Skalning: 1, 2, 4, 8 samtidiga ledningar --")

local function skala(n)
	LedService._glomForProv()
	local par = {}
	for i = 1, n do
		--[[ Sex site-enheter isar: langt bortom RACKVIDD, sa att ingen
			session kan rakna en grannes hast som sin. ]]
		local bx = 140 + i * 6
		local h = nyHast("skala_" .. n .. "_" .. i, varld(bx, 80))
		local sp, r = nySpelare("Skala" .. n .. "_" .. i, varld(bx + 1.0, 80))
		local ok = LedService.borja(sp, h, h)
		par[i] = { sp = sp, h = h, r = r, ok = ok }
	end
	local startade = 0
	for _, x in ipairs(par) do if x.ok then startade += 1 end end

	local t0 = os.clock()
	for _ = 1, 60 do LedService._steg(1 / 30) end
	local ms = (os.clock() - t0) * 1000

	local levande, rattAgare = 0, 0
	for _, x in ipairs(par) do
		if LedService.aktiv(x.sp) ~= nil then levande += 1 end
		if LedService.ledsAv(x.h) == x.sp then rattAgare += 1 end
	end
	return { n = n, startade = startade, levande = levande,
		rattAgare = rattAgare, ms = ms, perSession = ms / n }
end

local matningar = {}
for _, n in ipairs({ 1, 2, 4, 8 }) do
	local r = skala(n)
	matningar[#matningar + 1] = r
	check(("%d samtidiga ledningar startade alla"):format(n),
		r.startade == n, ("%d av %d"):format(r.startade, n))
	check(("...alla %d lever efter 60 steg"):format(n),
		r.levande == n, ("%d av %d"):format(r.levande, n))
	check(("...och varje hast har kvar RATT ledare vid %d"):format(n),
		r.rattAgare == n, ("%d av %d"):format(r.rattAgare, n))
end

do
	local rader = {}
	for _, r in ipairs(matningar) do
		rader[#rader + 1] = ("n=%d: %.2f ms / 60 steg (%.3f ms per session)")
			:format(r.n, r.ms, r.perSession)
	end
	print("       kostnad (evidens, ingen troskel): " .. table.concat(rader, " | "))
	--[[ Det enda som FALLER har ar en kostnad som skenar: atta sessioner
		far inte kosta mer an tjugo ganger en. Taket ar avsiktligt slappt —
		det letar efter n-kvadrat-beteende, inte efter en prestandagrans. ]]
	local en = matningar[1].ms
	local atta = matningar[#matningar].ms
	check("kostnaden skenar inte med antalet sessioner",
		en <= 0 or atta <= en * 20,
		("1 -> %.2f ms, 8 -> %.2f ms (kvot %.1f)"):format(en, atta,
			en > 0 and atta / en or 0))
end

if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("\nflerhast.spec: alla gröna")
end
