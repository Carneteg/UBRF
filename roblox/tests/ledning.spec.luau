--!nostrict
--[[
	LEDNINGEN — beslut och nej-vägar (#162 blockerare 2).

	Den fysiska följningen mäts i Studio-runtime; det här är tjänstens
	BESLUT. Varje negativt fall i ordern har en egen mätning, och varje
	mätning kräver ett SÄRSKILT skäl: ett samlat "gick inte" hade gjort
	fallen omöjliga att skilja åt, och då mäter specen ingenting.

	Specen sätter aldrig `lamnatBox` eller `malNatt` själv. Den flyttar
	hästen och låter `LedService._steg` — samma funktion Heartbeat kör i
	produktionen — avgöra. Skulle någon byta ut villkoren mot något som
	läser gränssnittet faller mätningarna.

	Kör: python3 roblox/tests/build.py tests/ledning.spec.luau
	     && luau roblox/tests/.build/ledning.spec.luau
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
local function vec(x, y, z) return Vector3.new(x, y, z) end

--[[ KURSEN LÄSES SOM BLICKRIKTNING, samma definition som tjänsten och
	`MovementController`: `heading = atan2(Look.X, Look.Z)`, alltså är
	`(sin h, 0, cos h)` exakt `LookVector`.

	Specen läste förut `ToOrientation().Y` — vinkeln man skickar till
	`CFrame.Angles`, vars blickriktning är den MOTSATTA. Den mätte alltså
	den felvända konventionen och blev grön på en häst som gick baklänges. ]]
local function kursAv(cf)
	local look = cf.LookVector
	return math.atan2(look.X, look.Z)
end
local function framatAv(cf)
	local h = kursAv(cf)
	return Vector3.new(math.sin(h), 0, math.cos(h))
end

--[[ En karaktär: det tjänsten faktiskt läser. ]]
local function nyKaraktar(pos)
	local k = Instance.new("Model")
	k.Name = "Karaktar"
	local rot = Instance.new("Part")
	rot.Name = "HumanoidRootPart"
	rot.Size = vec(2, 2, 1)
	rot.CFrame = CFrame.new(pos)
	rot.Parent = k
	local hum = Instance.new("Humanoid")
	hum.Name = "Humanoid"
	hum.Parent = k
	return k, rot, hum
end

--[[ Samma spelarform som bänkens övriga specar: en tabell med det
	tjänsten läser. `Instance.new("Player")` finns inte i stubben. ]]
local function nySpelare(namn, pos)
	local k, rot, hum = nyKaraktar(pos)
	local p = {
		Name = namn, UserId = 1, Character = k,
		CharacterAdded = __signal_ny(),
		CharacterRemoving = __signal_ny(),
	}
	return p, rot, hum
end

local function nyHast(namn, pos)
	local m = Instance.new("Model")
	m.Name = namn
	m:SetAttribute("HorseId", namn)
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

--[[ Tomtkoordinat → värld, samma omräkning som tjänsten. ]]
local function varld(x, y) return vec(x * M, 3, (170 - y) * M) end

--[[ ══ SCENBYTE ÄR INTE ETT STEG (reviewrond 6) ═════════════════════

	Bänken har ingen fysik, så specen FLYTTAR aktörerna dit scenariot
	behöver dem. Det gick bra så länge hoppvakten svarade med
	`table.clear(spar)`: varje sådan förflyttning nollade spåret.

	Rond 6 tog bort den raderingen — ett hopp får inte längre påstå att
	hästen gått den antecknade vägen. Då blev bänkens egna teleporter
	synliga. Två av dem är SCENBYTEN över tio respektive knappt fyra
	meter, och scenarierna kallar dem själva gång: «hon når ridbanan»,
	«rutten fortsätter västerut». Så nu går de — 0,5 m per bildruta,
	häst och spelare tillsammans så att kopplet håller.

	DÖRRUTGÅNGEN LÄMNAS SOM DEN ÄR, med flit. Där är teleporten poängen:
	spelaren ska stå kvar på boxsidan i samma bildruta som hästen
	passerar dörrplanet, för det är den engångsgallringen provet mäter.
	Går man även den blir provet grönt utan att gallringen körs — mätt:
	med gallringen borttagen blev specen ändå grön. ]]
local function ga(par, steg)
	local n = 0
	while n < 400 do
		local klara = true
		for _, p in ipairs(par) do
			local nu = p.del.Position
			local d = p.till - nu
			if d.Magnitude > 0.05 then
				klara = false
				p.del.CFrame = CFrame.new(nu + d.Unit * math.min(steg or (0.5 * M), d.Magnitude))
			end
		end
		LedService._steg(1 / 30)
		n += 1
		if klara then break end
	end
	return n
end

print("\n── Att börja leda ──")

LedService._glomForProv()

local BOX = { x = 163.68, y = 77.60 }
local hast, hastKropp, hastHum = nyHast("blackrock_jack", varld(BOX.x, BOX.y))
local annanHast = nyHast("marabou", varld(170.10, 84.60))
local spelare, rot, hum = nySpelare("SagaAberg", varld(BOX.x + 1.0, BOX.y))

--[[ ── NEGATIVT: för långt bort ───────────────────────────────────── ]]
rot.CFrame = CFrame.new(varld(BOX.x + 20, BOX.y))
local ok1, skal1 = LedService.borja(spelare, hast, hast)
check("för långt bort → nekas med eget skäl", ok1 == false and skal1 == "led.for_langt",
	tostring(skal1))

--[[ ── NEGATIVT: fel häst ──────────────────────────────────────────── ]]
rot.CFrame = CFrame.new(varld(BOX.x + 1.0, BOX.y))
local ok2, skal2 = LedService.borja(spelare, annanHast, hast)
check("fel häst → nekas med eget skäl", ok2 == false and skal2 == "led.fel_hast",
	tostring(skal2))

--[[ ── NEGATIVT: sitter upp ────────────────────────────────────────── ]]
hum.Sit = true
local ok3, skal3 = LedService.borja(spelare, hast, hast)
check("sitter upp → leder inte, man rider", ok3 == false and skal3 == "led.rider",
	tostring(skal3))
hum.Sit = false

--[[ ── POSITIVT: intill rätt häst ──────────────────────────────────── ]]
local ok4, skal4 = LedService.borja(spelare, hast, hast)
check("intill rätt häst → ledningen börjar", ok4 == true, tostring(skal4))
check("tjänsten vet vilken häst som leds", LedService.aktiv(spelare) == hast)

--[[ ── NEGATIVT: dubbeltrigger ─────────────────────────────────────── ]]
local ok5, skal5 = LedService.borja(spelare, hast, hast)
check("dubbeltrigger → nekas", ok5 == false and skal5 == "led.leder_redan", tostring(skal5))

--[[ ── NEGATIVT: någon annan leder henne ───────────────────────────── ]]
local spelare2, rot2 = nySpelare("AnnanRyttare", varld(BOX.x + 1.0, BOX.y))
local ok6, skal6 = LedService.borja(spelare2, hast, hast)
check("två spelare kan inte leda samma häst", ok6 == false and skal6 == "led.upptagen",
	tostring(skal6))

print("\n── Hästen står kvar i boxen ──")

--[[ Tjänsten ska INTE tro att något hänt bara för att ledningen är på. ]]
LedService._steg(1 / 30)
check("hästen har inte lämnat boxen än", LedService.harLamnatBox(spelare) == false)
check("och hon har inte nått målet", LedService.harNattMal(spelare) == false)

local zon = { x = 122.4, y = 41.97, w = 20, h = 65.53 }
LedService.satMalzon(zon)

--[[ ── Hon lämnar boxen ───────────────────────────────────────────── ]]
hastKropp.CFrame = CFrame.new(varld(BOX.x + 4, BOX.y))
LedService._steg(1 / 30)
check("när hon fysiskt lämnat boxen ser tjänsten det",
	LedService.harLamnatBox(spelare) == true)
check("men målet är fortfarande inte nått", LedService.harNattMal(spelare) == false)

--[[ ── Hon når ridbanan ───────────────────────────────────────────── ]]
--[[ De GÅR dit tillsammans — se noten vid `ga`. ]]
ga({ { del = rot, till = varld(132, 70) },
     { del = hastKropp, till = varld(132, 72) } })
LedService._steg(1 / 30)
check("när hon fysiskt står i ridbanan ser tjänsten det",
	LedService.harNattMal(spelare) == true)

print("\n── Följandet ──")

--[[ Hon ska få order att GÅ när avståndet växer — och ordern ska vara
	en RÖRELSERIKTNING, inte en punkt. Skillnaden är hela blockeraren:
	`MoveTo` skjuter kroppen mot punkten oavsett hur den står, och en häst
	som går i sidled in i en 1,20 m öppning fastnar. ]]
ga({ { del = rot, till = varld(132, 60) },
     { del = hastKropp, till = varld(132, 66) } })
LedService._steg(1 / 30)
--[[ ══ FÖLJNINGEN ÄR CONSTRAINTS NU (#182 del 2) ═══════════════════

	Mätningarna här mätte förut `Humanoid:Move` och `WalkSpeed`. Den
	aktueringen finns inte längre: arkitekturkontraktet i #235 FAS 4 kräver
	`AlignPosition` + `AlignOrientation`, och förbjuder uttryckligen
	loopreglering — `Humanoid:Move` varje bildruta och direkt skrivning av
	`CFrame` var två av de förbjudna sakerna.

	Det som mäts är därför inte längre en rörelseorder utan REGULATORN:
	att den är påslagen, att den drar mot rätt punkt, och att den slås av
	i dödzonen. Att Roblox sedan flyttar henne är fysikmotorns jobb och
	kan inte mätas i en bänk utan fysik — det är en Studio-grind. ]]
local rigg = LedService.riggFor(spelare)
check("följriggen byggdes när ledningen började", rigg ~= nil)
check("och den har båda regulatorerna, ingen tredje",
	rigg ~= nil and rigg.drag ~= nil and rigg.vrid ~= nil)
check("dragets fästpunkt sitter på hästen, målet på spelaren",
	rigg ~= nil and rigg.hastfast ~= nil and rigg.mal ~= nil
		and rigg.hastfast.Parent == hastKropp
		and rigg.mal.Parent == rot,
	rigg and ("%s / %s"):format(
		tostring(rigg.hastfast and rigg.hastfast.Parent and rigg.hastfast.Parent.Name),
		tostring(rigg.mal and rigg.mal.Parent and rigg.mal.Parent.Name)) or "-")
check("draget är MJUKT, inte stelt — hon dras, teleporteras inte",
	rigg ~= nil and rigg.drag.RigidityEnabled == false)

check("regulatorn är påslagen när avståndet växer",
	rigg ~= nil and rigg.drag.Enabled == true)
check("och hon får skrittfart, inte noll",
	rigg ~= nil and rigg.drag.MaxVelocity > 0,
	rigg and string.format("%.2f studs/s", rigg.drag.MaxVelocity) or "-")

--[[ HON PEKAR DIT HON GÅR. `AlignOrientation` får en kurs ur
	färdriktningen, inte ur spelarens kropp — en häst som kopierat
	ryttarens vridning hade gått i sidled genom dörren. ]]
if rigg then
	local mot = Vector3.new(rigg.mal.WorldPosition.X - hastKropp.Position.X, 0,
		rigg.mal.WorldPosition.Z - hastKropp.Position.Z)
	local kurs = rigg.vrid.CFrame and rigg.vrid.CFrame.LookVector
	local prick = kurs and mot.Magnitude > 0.01
		and (kurs.X * mot.Unit.X + kurs.Z * mot.Unit.Z) or -1
	check("kursen pekar mot målpunkten, inte i sidled",
		prick > 0.99, string.format("prickprodukt %.4f", prick))
end

--[[ HYSTERESEN: står hon nära nog ska hon STÅ, inte pendla.

	MED CONSTRAINTS RÄCKER DET INTE att sluta flytta målet — draget hade
	fortsatt skjuta mot den sista punkten för evigt. Regulatorn måste
	SLÄCKAS. ]]
hastKropp.CFrame = CFrame.new(rot.Position - vec(0, 0, 2.2 * M))
LedService._steg(1 / 30)
LedService._steg(1 / 30)
check("innanför dödzonen är draget AVSLAGET, inte bara omriktat",
	rigg ~= nil and rigg.drag.Enabled == false,
	rigg and tostring(rigg.drag.Enabled) or "-")
check("och kursregulatorn med den",
	rigg ~= nil and rigg.vrid.Enabled == false)

--[[ HON FÅR INTE LÅSA SIG PÅ SITT EGET SPÅR.

	Mätt i Studio, söder om boxraderna: hästen stod blickstilla 1,21 m
	från sin egen äldsta brödsmula, med spelaren 6,30 m bort och utan att
	röra någonting alls. Smulan låg i GLAPPET mellan STOPP_R (1,0 m) och
	START_R (1,8 m): för nära för att vara värd att gå till, för långt för
	att räknas som nådd. Inget i tillståndet såg trasigt ut.

	Specen bygger exakt det läget — hon står, spelaren är långt borta, och
	den enda smulan ligger i glappet — och kräver att hon ändå går. ]]
do
	LedService._glomForProv()
	local h5, kropp5, hum5 = nyHast("sparhast", varld(140, 70))
	local sp5, rot5 = nySpelare("Spårryttare", varld(140.5, 70))
	LedService.borja(sp5, h5, h5)
	local l5 = LedService.lage(sp5)
	check("hon står stilla när provet börjar", l5.gar == false)

	--[[ Spelaren går ifrån henne och lägger ett RIKTIGT spår — smulorna
		måste komma ur tjänsten själv, annars slår hoppdetektorn till och
		kastar dem, och då mäter provet ingenting. ]]
	for i = 1, 14 do
		rot5.CFrame = CFrame.new(varld(140 - i * 0.5, 70))
		LedService._steg(1 / 30)
	end
	local antalSmulor = #l5.spar
	check("spåret finns att låsa sig på", antalSmulor >= 3, tostring(antalSmulor))

	--[[ Hon ställs 1,4 m från den ÄLDSTA smulan — mitt i glappet — med
		spelaren långt borta. Precis så stod hon i stallet. ]]
	kropp5.CFrame = CFrame.new(l5.spar[1] + Vector3.new(1.4 * M, 0, 0))
	l5.gar = false
	--[[ 90 bildrutor: kravet är att hon KOMMER IVÄG, inte att hon gör det
		i samma bildruta.

		MÄTT PÅ REGULATORN, inte på `WalkSpeed`: följningen är constraints
		sedan #182 del 2, och `WalkSpeed` rör inte längre en ledd häst. ]]
	for _ = 1, 90 do LedService._steg(1 / 30) end
	local rigg5 = LedService.riggFor(sp5)
	check("hon låser sig inte i glappet vid sin egen brödsmula",
		l5.gar == true and rigg5 ~= nil and rigg5.drag.Enabled == true
			and rigg5.drag.MaxVelocity > 0,
		string.format("gar=%s drag=%s fart %.2f", tostring(l5.gar),
			tostring(rigg5 and rigg5.drag.Enabled),
			rigg5 and rigg5.drag.MaxVelocity or -1))
	if LedService.lage(sp5) then LedService.slapp(sp5) end
end

print("\n── Kopplet ──")

--[[ ── NEGATIVT: spelaren lämnar hästen ────────────────────────────── ]]
rot.CFrame = CFrame.new(varld(132, 20))
LedService._steg(1 / 30)
check("spelaren går ifrån henne → kopplet släpper",
	LedService.aktiv(spelare) == nil)

print("\n── Att släppa ──")

rot.CFrame = CFrame.new(varld(BOX.x + 1.0, BOX.y))
hastKropp.CFrame = CFrame.new(varld(BOX.x, BOX.y))
LedService.borja(spelare, hast, hast)
local ok7 = LedService.slapp(spelare)
check("spelaren kan avbryta ledningen", ok7 == true)
check("och då leder hon ingen", LedService.aktiv(spelare) == nil)
local ok8, skal8 = LedService.slapp(spelare)
check("att släppa när man inte leder nekas", ok8 == false and skal8 == "led.leder_inte",
	tostring(skal8))

--[[ ── NEGATIVT: spelaren sitter upp mitt i ledningen ──────────────── ]]
LedService.borja(spelare, hast, hast)
hum.Sit = true
LedService._steg(1 / 30)
check("sitter man upp mitt i ledningen släpper den",
	LedService.aktiv(spelare) == nil)
hum.Sit = false


print("\n── Vridningen ──")

--[[ DEN VERKLIGA BLOCKERAREN, och den mätning som saknades.

	`HorseService` sätter `AutoRotate = false` på varenda häst — 33 av 33,
	mätt i Studio — med motiveringen att spelet äger vridningen. Under ritt
	är det sant: `MovementController` skriver kursen varje bildruta. Men
	den modulen kör bara för den som SITTER UPP. En oriden häst hade därför
	ingen alls som vred henne, och gick mot boxdörren MED SIDAN FÖRE: 1,85 m
	kropp mot 1,20 m öppning. Vägpunkten pekade rätt hela tiden — kroppen
	pekade fel.

	Specen sätter aldrig kursen själv. Den ställer hästen åt fel håll och
	låter `LedService._steg` vrida henne. ]]
do
	LedService._glomForProv()
	local h4, kropp4, hum4 = nyHast("vridhast", varld(140, 70))
	local sp4, rot4 = nySpelare("Vridryttare", varld(140.5, 70))
	local okV = LedService.borja(sp4, h4, h4)
	check("ledningen börjar", okV == true)

	--[[ Spelaren går rakt västerut; hästen står vänd norrut. Hon MÅSTE
		vrida sig ett kvarts varv för att kunna följa. ]]
	kropp4.CFrame = CFrame.new(varld(140, 70)) * CFrame.Angles(0, 0, 0)
	rot4.CFrame = CFrame.new(varld(134, 70))
	local kurs0 = kursAv(kropp4.CFrame)

	LedService._steg(1 / 30)

	--[[ ══ KURSEN ÄR EN REGULATOR NU, INTE EN CFRAME-SKRIVNING ═══════

		Mätningarna här mätte förut att `LedService` skrev `pivot.CFrame`
		med kanonens `TurnInPlaceRate`, och att `WalkSpeed` var noll tills
		hon vänt färdigt.

		BÅDA MEKANISMERNA ÄR BORTA MED FLIT. Arkitekturkontraktet i #235
		FAS 4 förbjuder direkt CFrame-skrivning, och vändtröskeln fanns
		bara för att `Humanoid:Move` sköt kroppen rakt fram oavsett hur den
		stod. `AlignOrientation` vrider henne kontinuerligt MEDAN
		`AlignPosition` drar, så hon kan inte längre gå i sidled in i en
		dörrkarm — problemet vändtröskeln löste uppstår inte.

		Det som mäts är därför att kursen ÄGS av ledningen och pekar rätt,
		och att vridningen är mjuk. Hur fort hon faktiskt vrider sig är
		fysikmotorns svar på `Responsiveness` och `MaxTorque`, och det är
		en Studio-grind. ]]
	local rigg4 = LedService.riggFor(sp4)
	check("ledningen äger kursen — regulatorn är påslagen",
		rigg4 ~= nil and rigg4.vrid.Enabled == true)
	check("vridningen är MJUK, inte ett snäpp",
		rigg4 ~= nil and rigg4.vrid.RigidityEnabled == false)
	check("och den styr mot EN riktning, inte mot spelarens kropp",
		rigg4 ~= nil
			and rigg4.vrid.Mode == Enum.OrientationAlignmentMode.OneAttachment,
		rigg4 and tostring(rigg4.vrid.Mode) or "-")

	--[[ KURSEN PEKAR MOT SPELAREN. Invarianten hela
		konventionsrättelsen handlade om: hästen ska gå ÅT DET HÅLL HON
		TITTAR. Mätt i Studio före rättelsen var prickprodukten -1,00 —
		ekipaget färdades med svansen före.

		Nu läses den ur regulatorns egen målkurs, som är det ledningen
		FAKTISKT beordrar. ]]
	for _ = 1, 90 do LedService._steg(1 / 30) end
	if rigg4 then
		local mot = rot4.Position - kropp4.Position
		local langd = math.sqrt(mot.X * mot.X + mot.Z * mot.Z)
		local look = rigg4.vrid.CFrame and rigg4.vrid.CFrame.LookVector
		local prick = look and langd > 1e-6
			and (mot.X * look.X + mot.Z * look.Z) / langd or -1
		check("den beordrade kursen pekar MOT spelaren, inte från",
			prick > 0.9, string.format("prickprodukt %.3f", prick))
		check("och draget är påslaget — hon ska faktiskt iväg",
			rigg4.drag.Enabled == true and rigg4.drag.MaxVelocity > 0,
			string.format("%.2f studs/s", rigg4.drag.MaxVelocity))
	end

	--[[ INGEN PARALLELL REGLERING. Kontraktet förbjuder en andra kraft om
		samma mål — `VectorForce`, `BodyVelocity`, en dragande
		`RopeConstraint`. Provet letar i hästen efter allt sådant. ]]
	do
		local forbjudna = {}
		for _, d in ipairs(kropp4:GetChildren()) do
			local k = tostring(d.ClassName)
			if k == "VectorForce" or k == "BodyVelocity" or k == "BodyPosition"
				or k == "BodyGyro" or k == "RopeConstraint" or k == "LinearVelocity" then
				table.insert(forbjudna, k)
			end
		end
		check("ingen andra regulator drar i samma häst", #forbjudna == 0,
			table.concat(forbjudna, " "))
	end

	--[[ NÄTVERKSÄGARSKAPET. Mätt i Studio: en oriden häst intill en
		spelare ägs AUTOMATISKT av den klienten, och serverns order når då
		aldrig fram — noll förflyttning med spelaren stående bredvid. ]]
	check("hon simuleras på servern medan hon leds",
		kropp4:GetNetworkOwnershipAuto() == false and kropp4:GetNetworkOwner() == nil)
	LedService.slapp(sp4)
	check("och ägarskapet lämnas tillbaka när kopplet släpper",
		kropp4:GetNetworkOwnershipAuto() == true)
end

print("\n── Att fastna ──")

--[[ EN HÄST SOM INTE KOMMER FRAM SKA SLÄPPAS MED EGET SKÄL.

	Mätt i Studio, vid södra änden av MA-raden: hon låg kilad mot ett
	fronthörn på en vägpunkt hon inte kunde nå, med full skrittfart och
	noll hastighet, och stod så i 24 sekunder. Ingenting i tillståndet såg
	trasigt ut — ledningen var på, hästen var "på väg".

	I bänken står hästen alltid stilla (stubbens hastighet är noll), så en
	häst som får order att gå och ändå inte rör sig är exakt det fallet.
	Planeraren får sina sex försök, och därefter ska kopplet släppa med
	`led.fastnat` — inte tyst, och inte med samma skäl som att spelaren
	gick ifrån henne. ]]
do
	LedService._glomForProv()
	local h6, kropp6 = nyHast("fasthast", varld(140, 70))
	local sp6, rot6 = nySpelare("Fastryttare", varld(140.5, 70))
	LedService.borja(sp6, h6, h6)
	rot6.CFrame = CFrame.new(varld(136, 70))
	local ev = Networking.get("LedSync")
	for _ = 1, 1200 do
		LedService._steg(1 / 30)
		if LedService.lage(sp6) == nil then break end
	end
	check("en häst som inte kommer fram släpps",
		LedService.lage(sp6) == nil)
	local sista = ev._skickat[#ev._skickat]
	local nyttolast = sista and sista[2]
	check("och skälet är hennes eget, inte ett allmänt fel",
		type(nyttolast) == "table" and nyttolast.skal == "led.fastnat",
		type(nyttolast) == "table" and tostring(nyttolast.skal) or "ingen LedSync")
end

print("\n── Navigeringens agent ──")

--[[ PathfindingService modellerar agenten som en CYLINDER. Hästens
	hölje är avlångt — 1,86 x 2,34 x 5,55 studs — och hon passerar en dörr
	på LÄNGDEN. Sätts radien till halva längden (2,775) krävs en öppning
	bredare än 5,55 studs, och boxdörren är 3,60: planeraren hade svarat
	"ingen väg" på en dörr hon fysiskt ryms igenom.

	Radien måste alltså komma ur BREDDEN. Den här mätningen faller om
	någon sätter den efter längden, efter Roblox standard, eller efter ett
	tal som inte är hästens eget. ]]
do
	LedService._glomForProv()
	local h2, kropp2 = nyHast("provhast", varld(BOX.x, BOX.y))
	local sp2, rot2 = nySpelare("Provryttare", varld(BOX.x + 1.0, BOX.y))
	LedService.borja(sp2, h2, h2)
	--[[ Tvinga fram ett planeringsanrop: hon står i boxen, alltså trångt. ]]
	rot2.CFrame = CFrame.new(varld(BOX.x + 3.0, BOX.y))
	--[[ I specvärlden finns ingen boxdörr, så planeraren utlöses av att
		hon slutat komma framåt — NAV_STILLA är 1,2 s, alltså ~36 steg. ]]
	for _ = 1, 50 do LedService._steg(1 / 30) end
	local pp = __senastePathParams
	check("planeraren anropades med agentparametrar", pp ~= nil)
	if pp then
		check("AgentRadius kommer ur kroppens BREDD, inte längden",
			pp.AgentRadius >= kropp2.Size.X * 0.5
				and pp.AgentRadius < kropp2.Size.Z * 0.5,
			string.format("%.3f studs (bredd/2 = %.3f, längd/2 = %.3f)",
				pp.AgentRadius, kropp2.Size.X * 0.5, kropp2.Size.Z * 0.5))
		check("AgentRadius ryms i boxdörrens 3,60 studs",
			pp.AgentRadius * 2 < 3.60,
			string.format("diameter %.2f studs", pp.AgentRadius * 2))

		--[[ ══ RADIEN SKA UTESLUTA KLUBBDELENS BRANDDÖRRAR (#190) ═══════

			De två talen nedan är MÄTTA i Studio på `a1826fc` med
			binärsökning på `AgentRadius`, inte valda här:

			  klubbdelen -> gång B, genom branddörrarna   bär <= 1,000
			  kanoniska hästrutten box MB 5 -> ridbanan   bär <= 1,521

			Klubbdelen är uppehållsrum, pentry, sadelkammare, teorisal och
			WC bakom en branddörr — en människoväg. Hästen ska ledas genom
			hästgången, inte genom klubbrummet.

			Med den gamla radien, exakt halva bredden (0,930), låg agenten
			UNDER 1,000 och planeraren fick lov att träda en häst genom en
			0,88 m bred branddörr. Den här mätningen är hela #190: sänks
			radien tillbaka dit blir raden röd. Höjs den förbi 1,521
			stängs den riktiga hästrutten, och då blir den också röd. ]]
		local KLUBBDELEN_BAR_UPP_TILL = 1.000
		local HASTRUTTEN_BAR_UPP_TILL = 1.521
		check("AgentRadius utesluter klubbdelens branddörrar",
			pp.AgentRadius > KLUBBDELEN_BAR_UPP_TILL,
			string.format("%.3f > %.3f", pp.AgentRadius, KLUBBDELEN_BAR_UPP_TILL))
		check("…utan att stänga den kanoniska hästrutten",
			pp.AgentRadius <= HASTRUTTEN_BAR_UPP_TILL,
			string.format("%.3f <= %.3f", pp.AgentRadius, HASTRUTTEN_BAR_UPP_TILL))
		check("AgentHeight är mankhöjden: HipHeight plus kroppen",
			math.abs(pp.AgentHeight - (2.01 + kropp2.Size.Y)) < 0.01,
			string.format("%.2f studs", pp.AgentHeight))
		check("en ledd häst varken hoppar eller klättrar",
			pp.AgentCanJump == false and pp.AgentCanClimb == false)
		check("vägpunkterna ligger tätare än standard 4 studs",
			pp.WaypointSpacing < 4, tostring(pp.WaypointSpacing))
	end

	--[[ Ingen väg får inte bli en malande loop. Stubben svarar NoPath. ]]
	for _ = 1, 60 do LedService._steg(1 / 30) end
	local l2 = LedService.lage(sp2)
	check("utan väg mal planeraren inte — försöken är tak-begränsade",
		l2 == nil or l2.navPlaner <= 6,
		l2 and tostring(l2.navPlaner) or "ledningen släppte")
end

--[[ ══ ETT ONÅBART MÅL FÅR INTE DÖDFÖRKLARA HENNE (#182) ═══════════════

	Mätt i Studio på `ad44dfe`, första divergensen efter boxutgången:

	    spar = 1 punkt          gallringen tömmer spåret när hon går nära
	    mål = 494,1 · 269,4     `rot.Position - LookVector * FOLJ_BAKOM*M`
	    ComputeAsync(mål)       → NoPath, 0 vägpunkter
	    ComputeAsync(spelaren)  → Success, 2 vägpunkter   SAMMA bildruta
	    mål krockar med         INGENTING

	Fallbackpunkten låg inne i boxradens fotavtryck bakom fronten. Gångbar
	yta tog slut där, men ingenting krockade — så inget i tillståndet såg
	trasigt ut. Alla sex omplaneringarna fick samma omöjliga mål, `navVag`
	förblev tom, och kopplet släppte med `led.fastnat` vid 16,6 studs.

	Provet spelar upp exakt den situationen: pathfinding-stubben säger NEJ
	till varje mål UTOM spelarens egen punkt. Utan reservmålet står hästen
	utan väg; med det får hon en.

	Det här är inte ett prov på att brödsmulorna slutat gälla — de äger
	fortfarande vägen genom dörren. Det är ett prov på att ETT dåligt mål
	inte ska kosta hela planeringsbudgeten. ]]
print("\n── Ett onåbart mål dödförklarar inte hästen ──")
do
	LedService._glomForProv()
	local h7, kropp7 = nyHast("reservhast", varld(140, 70))
	local sp7, rot7 = nySpelare("Reservryttare", varld(140.5, 70))

	--[[ Spelaren står ETT stycke bort så att hon behöver gå, och vänd så
		att fallbackpunkten hamnar någon annanstans än på henne själv. ]]
	rot7.CFrame = CFrame.new(varld(143, 70), varld(140, 70))

	local ok = LedService.borja(sp7, h7, h7)
	check("ledningen startar", ok)

	--[[ STUBBEN ÄR VÄRLDEN. Bara spelarens egen punkt bär; allt annat är
		utanför navmeshen, precis som fallbacken var i Studio. ]]
	__pathMal = {}
	__pathSvar = function(_, till)
		if (till - rot7.Position).Magnitude < 4 then
			return { rot7.Position }
		end
		return nil
	end

	--[[ MÄT UNDER TIDEN, inte efteråt. Bänken har ingen fysik, så hon
		står still hur bra vägen än är — och `steg` kastar med flit en väg
		som inte bär (`stillaSedan > NAV_STILLA`). Att läsa `navVag` vid
		steg 80 mäter därför städningen, inte planeringen. Det som ska
		bevisas är att hon FICK en väg. ]]
	local mestVag = 0
	for _ = 1, 80 do
		LedService._steg(1 / 30)
		local li = LedService.lage(sp7)
		if li and #li.navVag > mestVag then mestVag = #li.navVag end
	end

	local l7 = LedService.lage(sp7)
	check("kopplet håller — hon dödförklaras inte som fastnad",
		l7 ~= nil,
		l7 and "aktiv" or "SLÄPPT")

	--[[ Bad hon om reserven? Två olika mål i samma försök är hela
		rättelsen; ett enda mål betyder att den inte prövades. ]]
	local olika = {}
	for _, m in ipairs(__pathMal) do
		local sedd = false
		for _, o in ipairs(olika) do
			if (o - m).Magnitude < 0.01 then sedd = true end
		end
		if not sedd then table.insert(olika, m) end
	end
	check("planeraren prövade mer än ett mål",
		#olika >= 2,
		("%d anrop, %d olika mål"):format(#__pathMal, #olika))

	local badOmSpelaren = false
	for _, m in ipairs(__pathMal) do
		if (m - rot7.Position).Magnitude < 4 then badOmSpelaren = true end
	end
	check("och ett av dem var spelarens egen punkt", badOmSpelaren)

	check("hon fick en väg trots att det valda målet inte bar",
		mestVag > 0,
		("som mest %d vägpunkter"):format(mestVag))

	--[[ MUTATIONEN: utan reservmålet finns ingen väg att få.

		Samma uppspelning, men stubben säger nej till ALLT. Då ska hon bli
		utan väg — annars mäter raderna ovan inte reserven utan något som
		råkar lyckas ändå. ]]
	LedService._glomForProv()
	local h8, kropp8 = nyHast("nekadhast", varld(150, 70))
	local sp8, rot8 = nySpelare("Nekadryttare", varld(150.5, 70))
	rot8.CFrame = CFrame.new(varld(153, 70), varld(150, 70))
	LedService.borja(sp8, h8, h8)
	__pathMal = {}
	__pathSvar = function() return nil end
	local mestVag8 = 0
	for _ = 1, 80 do
		LedService._steg(1 / 30)
		local li = LedService.lage(sp8)
		if li and #li.navVag > mestVag8 then mestVag8 = #li.navVag end
	end
	local l8 = LedService.lage(sp8)
	check("MUTATION: nekas VARJE mål blir hon utan väg — provet mäter reserven",
		mestVag8 == 0,
		("som mest %d vägpunkter"):format(mestVag8))

	--[[ Och taket står kvar: reserven prövas i SAMMA försök, inte som ett
		sjunde. En blockerad häst ska fortfarande inte mala servern. ]]
	check("planeringstaket är inte urholkat",
		l8 == nil or l8.navPlaner <= 6,
		l8 and tostring(l8.navPlaner) or "släppt")

	__pathSvar = nil
end


--[[ ══ EN PASSERAD DÖRR GÖR SMULORNA BAKOM DEN FÖRBRUKADE (#182) ═══════

	Mätt i Studio på `5bdd45e`, första divergensen efter boxutgången.
	Vänsterkolumnen är hästens signerade läge mot boxdörrens plan, `+` är
	gången och `−` är boxen:

	    häst 500,0 · 272,0  (plan +1.18)   spar = 7 smulor
	    vald smula spar[1]  494,8 · 276,7  (plan −0.56)
	    häst 499,9 (+1.15) → 499,3 (+0.93) → … → 497,1 (+0.19)

	Smulan var spelarens gamla läge från när hon stod INNE i boxen.
	Gallringen tar bara smulor närmare än `START_R`; den låg 2,0 m bort och
	blev därför kvar, valdes som mål, och drog hästen bakåt mot dörren hon
	just kommit ut genom — fyrtiosju bildrutor i rad med sjunkande plan,
	medan spelaren gick söderut. Sedan slog `led.fastnat` till.

	Provet bygger en riktig boxdörr med attributen `borja` letar efter,
	lägger smulor på boxsidan, flyttar hästen ut, och kräver att inget som
	ligger kvar bakom dörrplanet får vara kvar i kön.

	Följningen GENOM dörren mäts inte bort: så länge `lamnatBox` är falsk
	äger `viaDorr` målpunkterna och gallringen nedan kör inte alls. ]]
print("\n── En passerad dörr gör smulorna bakom den förbrukade ──")
do
	LedService._glomForProv()

	--[[ Anläggningen med EN boxdörr. `borja` letar i `workspace.Anläggning`
		efter delar med `UBRFBoxdorr`, och läser `Langs`/`Utat` för att veta
		åt vilket håll gången ligger. Samma attribut `Anlaggningen` sätter. ]]
	local anl = Instance.new("Model")
	anl.Name = "Anläggning"
	anl.Parent = workspace
	local DX, DZ = varld(163.68, 77.60).X + 5.5, varld(163.68, 77.60).Z
	local blad = Instance.new("Part")
	blad.Name = "Boxdörr prov"
	blad.Size = vec(0.18, 4.44, 3.60)
	blad.CFrame = CFrame.new(vec(DX, 2.22, DZ))
	blad:SetAttribute("UBRFBoxdorr", true)
	blad:SetAttribute("Langs", "Z")
	blad:SetAttribute("Utat", 1)
	blad:SetAttribute("UBRFOppningsmitt", vec(DX, 2.22, DZ))
	blad.Parent = anl

	local hS, kroppS = nyHast("smulhast", vec(DX - 5, 3, DZ))
	local spS, rotS = nySpelare("Smulryttare", vec(DX - 3, 3, DZ))
	local ok = LedService.borja(spS, hS, hS)
	check("ledningen startar med en modellerad boxdörr", ok)

	local lS = LedService.lage(spS)
	check("dörren hittades och planet är känt",
		lS ~= nil and lS.dorrMitt ~= nil and lS.dorrUt ~= nil,
		lS and tostring(lS.dorrMitt) or "-")

	local function plan(p)
		local l = LedService.lage(spS)
		if not (l and l.dorrMitt and l.dorrUt) then return 0 end
		return (p - l.dorrMitt):Dot(l.dorrUt) / M
	end

	--[[ Spelaren rör sig INNE i boxen så att smulor hamnar på boxsidan. ]]
	for i = 1, 20 do
		rotS.CFrame = CFrame.new(vec(DX - 3 - (i % 3), 3, DZ + (i % 4) * 0.5))
		LedService._steg(1 / 30)
	end
	local fore = LedService.lage(spS)
	local pabox = 0
	for _, c in ipairs(fore and fore.spar or {}) do
		if plan(c) <= 0 then pabox += 1 end
	end
	check("smulor hamnade på boxsidan medan hon var kvar inne",
		pabox > 0, ("%d av %d"):format(pabox, #(fore and fore.spar or {})))

	--[[ Hästen går UT genom dörren, och spelaren går ut i gången. ]]
	kroppS.CFrame = CFrame.new(vec(DX + 4, 3, DZ))
	LedService._steg(1 / 30)
	check("hon räknas som ute ur boxen",
		LedService.harLamnatBox(spS) == true)

	--[[ Kort sträcka med flit: bänken har ingen fysik, så hästen står
		kvar hur rätt målet än är. Går spelaren längre än KOPPEL (9 m)
		släpper leden på `tappade_bort` och provet mäter det i stället för
		smulorna. Fjorton studs håller oss innanför. ]]
	for i = 1, 12 do
		rotS.CFrame = CFrame.new(vec(DX + 4 + i * 0.2, 3, DZ + i * 1.1))
		LedService._steg(1 / 30)
	end

	local efter = LedService.lage(spS)
	local kvar = {}
	for _, c in ipairs(efter and efter.spar or {}) do
		if plan(c) <= 0 then table.insert(kvar, string.format("%.1f,%.1f", c.X, c.Z)) end
	end
	check("ingen smula bakom den passerade dörren finns kvar i kön",
		#kvar == 0,
		(#kvar == 0 and ("%d smulor kvar, alla i gången"):format(#(efter and efter.spar or {})))
			or table.concat(kvar, " · "))

	--[[ …och hon dras inte bakåt: målet ska ligga på gångsidan. ]]
	local FOLJ_BAKOM, START_R = 2.4, 1.8
	local function aM(a, b) return (a - b).Magnitude / M end
	local spar = efter and efter.spar or {}
	local bakom = rotS.Position - rotS.CFrame.LookVector * (FOLJ_BAKOM * M)
	for i = 1, #spar do
		if aM(spar[i], rotS.Position) >= FOLJ_BAKOM
			and aM(spar[i], kroppS.Position) >= START_R then
			bakom = spar[i]
			break
		end
	end
	check("kopplet håller genom hela utgången",
		efter ~= nil,
		efter and ("spar " .. #spar) or "SLÄPPT")
	check("och det valda målet ligger på gångsidan av dörren",
		efter ~= nil and plan(bakom) > 0,
		("plan %+.2f · spar %d · spelare %.1f,%.1f"):format(
			plan(bakom), #spar, rotS.Position.X, rotS.Position.Z))

	--[[ ── OCH NYA SMULOR PÅ SAMMA SIDA SKA ÖVERLEVA ──────────────

		Det här är andra halvan, och den halvan saknades i första
		utkastet. Gallringen låg då i bildruteloopen och körde så länge
		`lamnatBox` var sann. Men `dorrUt` för en box i MB-raden pekar
		ÖSTERUT, och hela den södra rutten västerut — gång A, hästgången,
		ridhuset — ligger därmed på minussidan av samma plan. Gallringen
		åt alltså upp varenda ny smula resten av vägen, och
		brödsmulefölningen var i praktiken avstängd. Mätt i Studio: 76
		träffar över 7 533 bildrutor, och rutten räddades av planeraren,
		inte av spåret.

		Nu gallras det EN gång, vid övergången. Smulor som skapas
		EFTERÅT ska ligga kvar även om de hamnar på boxsidan av planet —
		precis som de gör när rutten fortsätter västerut. ]]
	--[[ Spelaren GÅR västerut hit; scenbytet var 3,8 m på en bildruta. ]]
	ga({ { del = rotS, till = vec(DX - 2.4, 3, DZ + 6) } })
	for i = 1, 14 do
		rotS.CFrame = CFrame.new(vec(DX - 2 - i * 0.4, 3, DZ + 6))
		LedService._steg(1 / 30)
	end
	local sent = LedService.lage(spS)
	local nyaPaBoxsidan = 0
	for _, c in ipairs(sent and sent.spar or {}) do
		if plan(c) <= 0 then nyaPaBoxsidan += 1 end
	end
	check("NYA smulor väster om dörrplanet överlever — spåret lever vidare",
		sent ~= nil and nyaPaBoxsidan > 0,
		sent and ("%d av %d smulor på boxsidan"):format(nyaPaBoxsidan, #sent.spar)
			or "SLÄPPT")

	--[[ ══ OCH DET RÄCKER INTE ATT RÄKNA DEM ════════════════════════════

		Raden ovan går inte att lita på, och det är hela poängen med den
		här: den är GRÖN även med den förkastade gallringen.

		Ordningen i `steg` är gallring först, spårpåfyllning sedan. Gallras
		det varje bildruta så länge `lamnatBox` är sann, försvinner alla
		boxsidiga smulor i början av bildrutan — och så lägger spårlogiken
		till spelarens NUVARANDE läge i slutet av samma bildruta. Står hon
		på boxsidan är den nya smulan också boxsidig, och antalet är
		därmed 1 när mätningen tittar. `> 0` är uppfyllt utan att en enda
		smula har överlevt någonting.

		Mätt: mutationen som flyttar tillbaka gallringen till varje
		bildruta gav 37/37 gröna i hela sviten. Regressionen `b7fcf42`
		rättade gick alltså att återinföra utan att någon grind blev röd.

		DET SOM FAKTISKT SKILJER DE TVÅ FORMERNA ÅT ÄR ÖVERLEVNAD ÖVER
		TID. En enda smula, utpekad medan hon går, ska finnas kvar flera
		bildrutor senare. Med engångsgallringen ligger den kvar; med
		varje-bildrute-formen är den borta nästa bildruta.

		Smulan väljs så att de VANLIGA gallringsreglerna inte kan ta den
		och göra provet grönt av fel skäl: den ska ligga längre bort än
		`START_R` från hästen (annars äts den som "framme vid smulan") och
		långt innanför `KOPPEL` från spelaren (annars äts den som
		bortglömd). Båda marginalerna mäts ut nedan i stället för att
		antas. ]]
	local START_R_M, KOPPEL_M = 1.8, 9.0
	local function metar(c)
		return aM(c, kroppS.Position), aM(c, rotS.Position)
	end
	local markerad, mHast, mSpelare = nil, 0, 0
	for _, c in ipairs(sent and sent.spar or {}) do
		local dHast, dSpelare = metar(c)
		if plan(c) <= 0 and dHast > START_R_M and dSpelare < KOPPEL_M - 2 then
			markerad, mHast, mSpelare = c, dHast, dSpelare
			break
		end
	end
	check("en boxsidig smula finns att peka ut, utanför de vanliga gallringsreglerna",
		markerad ~= nil,
		markerad and ("häst %.2f m (> %.1f) · spelare %.2f m (< %.1f)"):format(
			mHast, START_R_M, mSpelare, KOPPEL_M) or "ingen kandidat")

	--[[ Spelaren går vidare VÄSTERUT — alltså djupare in på boxsidan av
		planet — så att den utpekade smulan inte längre är den nyaste. Kort
		sträcka: kopplet ska hålla, annars mäter provet ett släpp. ]]
	for i = 15, 22 do
		rotS.CFrame = CFrame.new(vec(DX - 2 - i * 0.4, 3, DZ + 6))
		LedService._steg(1 / 30)
	end
	local efterat = LedService.lage(spS)
	local kvarKvar = false
	for _, c in ipairs(efterat and efterat.spar or {}) do
		if markerad and (c - markerad).Magnitude < 0.01 then kvarKvar = true end
	end
	local boxsidiga = 0
	for _, c in ipairs(efterat and efterat.spar or {}) do
		if plan(c) <= 0 then boxsidiga += 1 end
	end
	check("en smula skapad EFTER utgången finns kvar åtta bildrutor senare",
		efterat ~= nil and markerad ~= nil and kvarKvar,
		efterat and ("%d smulor, %d på boxsidan"):format(#efterat.spar, boxsidiga)
			or "SLÄPPT")

	--[[ Och de ska vara FLERA. Varje-bildrute-formen kan som mest lämna
		den enda smula som lades till efter gallringen i samma bildruta. ]]
	check("flera boxsidiga smulor samtidigt — spåret byggs på, inte nollas",
		boxsidiga > 1, ("%d på boxsidan"):format(boxsidiga))

	anl:Destroy()
end


--[[ ══ UTGÅNGSGALLRINGEN FÅR INTE RADERA FRAMTIDA RUTT ═══════════════

	ChatGPT:s sjunde reviewrond, på `da0392e`. Rond 6b flyttade
	engångsgallringen till efter antecknandet — men den filtrerade HELA
	kön på dörrplanets sida, och plansida är inte förbrukning.

	Spåret är ORDNAT. En smula som ligger SENARE i kön och råkar hamna på
	boxsidan är framtida väg: rutten kan mycket väl vika tillbaka förbi
	dörrplanet längre fram. Att radera den är samma fel som hela den här
	serien handlar om — ett geometriskt sammanträffande som får betyda
	«hon har gått här».

	Reviewens fall, ordnat:

	    1  gammal historik inne i boxen   plan −
	    2  nästa punkt ute i gången       plan +
	    3  SENARE återgång till boxsidan  plan −      ← framtida väg
	    4  senare punkt ute               plan +

	Med helköfiltret överlevde 2 och 4 och 3 raderades — enbart på
	plansida. Koppel 5,90 m, alltså en fullt giltig ledning.

	POLICYN: bara den LEDANDE serien av boxsidiga smulor gallras. Den är
	per definition historiken före utgången, för spåret byggs framifrån
	och spelaren stod inne i boxen. Första smulan på gångsidan avslutar
	gallringen, och allt därefter är framtid. ]]
print("\n── En framtida återgång är inte förbrukad historik ──")
do
	LedService._glomForProv()

	local anl = Instance.new("Model")
	anl.Name = "Anläggning"
	anl.Parent = workspace
	local DX, DZ = 700, 500
	local blad = Instance.new("Part")
	blad.Name = "Boxdörr ordning"
	blad.Size = vec(0.18, 4.44, 3.60)
	blad.CFrame = CFrame.new(vec(DX, 2.22, DZ))
	blad:SetAttribute("UBRFBoxdorr", true)
	blad:SetAttribute("Langs", "Z")
	blad:SetAttribute("Utat", 1)
	blad:SetAttribute("UBRFOppningsmitt", vec(DX, 2.22, DZ))
	blad.Parent = anl

	local hO, kroppO = nyHast("ordninghast", vec(DX - 5, 3, DZ))
	local spO, rotO = nySpelare("Ordningsryttare", vec(DX - 3, 3, DZ))
	check("ledningen startar for ordningsprovet", LedService.borja(spO, hO, hO) == true)
	local lO = LedService.lage(spO)
	check("dorrplanet ar kant for ordningsprovet",
		lO ~= nil and lO.dorrMitt ~= nil and lO.dorrUt ~= nil)

	local function plan(p)
		return lO and lO.dorrMitt and lO.dorrUt
			and (p - lO.dorrMitt):Dot(lO.dorrUt) / M or 0
	end

	--[[ Kön sätts DIREKT, och det är avsiktligt: fallet handlar om
		ORDNINGEN i en given kö, inte om hur den blev till. Samma fyra
		punkter som reviewen mätte. ]]
	--[[ Punkterna ligger ALLA utanfor `START_R` fran hasten dar hon
		hamnar, sa ingen av dem kan gallras som gangen. Da finns bara en
		forklaring kvar till att nagon forsvinner: plansidan. ]]
	local GAMMAL  = vec(DX - 4.5, 3, DZ)
	local UTE1    = vec(DX + 3, 3, DZ + 8)
	local FRAMTID = vec(DX - 2, 3, DZ + 10)
	local UTE2    = vec(DX + 5, 3, DZ + 14)
	if lO then
		table.clear(lO.spar)
		for _, p in ipairs({ GAMMAL, UTE1, FRAMTID, UTE2 }) do table.insert(lO.spar, p) end
	end
	check("kon ar ordnad gammal-inne / ute / framtida atergang / ute",
		lO ~= nil and #lO.spar == 4
			and plan(GAMMAL) < 0 and plan(UTE1) > 0
			and plan(FRAMTID) < 0 and plan(UTE2) > 0,
		("plan %+.2f %+.2f %+.2f %+.2f"):format(
			plan(GAMMAL), plan(UTE1), plan(FRAMTID), plan(UTE2)))

	--[[ Spelaren står 5,90 m bort — innanför `KOPPEL`, ledningen giltig.
		Hästen går UT genom dörren, och gallringen löser ut. ]]
	rotO.CFrame = CFrame.new(vec(DX + 4, 3, DZ + 5.90 * M))
	kroppO.CFrame = CFrame.new(vec(DX + 4, 3, DZ))
	local START_R = 1.8
	local narmast = math.huge
	for _, q in ipairs({ GAMMAL, UTE1, FRAMTID, UTE2 }) do
		local d2 = (q - kroppO.Position).Magnitude / M
		if d2 < narmast then narmast = d2 end
	end
	check("ingen av smulorna ar gangen — narmast ligger utanfor START_R",
		narmast > START_R, ("narmaste %.2f m"):format(narmast))
	LedService._steg(1 / 30)

	lO = LedService.lage(spO)
	local koppel = lO and (kroppO.Position - rotO.Position).Magnitude / M or -1
	check("ledningen lever och kopplet holl", lO ~= nil,
		("koppel %.2f m"):format(koppel))
	check("hon raknas som ute ur boxen", LedService.harLamnatBox(spO) == true)

	local harFramtid, harGammal = false, false
	for _, c in ipairs(lO and lO.spar or {}) do
		if (c - FRAMTID).Magnitude < 0.01 then harFramtid = true end
		if (c - GAMMAL).Magnitude < 0.01 then harGammal = true end
	end
	--[[ DEN RÖDA MÄTNINGEN. Helköfiltret raderar FRAMTID. ]]
	check("utgangsgallringen far inte radera en SENARE framtida atergang bara pga plansida",
		harFramtid,
		("framtida atergang kvar=%s; %d smulor kvar"):format(
			tostring(harFramtid), #(lO and lO.spar or {})))
	--[[ …och rond 6b:s poäng står kvar: historiken före utgången GÅR. ]]
	check("den gamla historiken inne i boxen gallras fortfarande",
		not harGammal,
		("gammal kvar=%s"):format(tostring(harGammal)))
	--[[ …och hon dras inte tillbaka in. Delmålet ska ligga på gångsidan. ]]
	check("och delmalet ligger pa gangsidan av dorren",
		lO ~= nil and lO.delmal ~= nil and plan(lO.delmal) > 0,
		lO and lO.delmal and ("plan %+.2f"):format(plan(lO.delmal)) or "-")

	anl:Destroy()
end


--[[ ══ SMULAN FRÅN SJÄLVA UTGÅNGSBILDRUTAN ═══════════════════════════

	ChatGPT:s åttonde reviewrond, på `1f0b60e`. Rond 7 gallrar den
	LEDANDE serien av boxsidiga smulor och stannar vid första smulan på
	gångsidan. Det är rätt för rutthistorik — men det räcker inte, och
	skälet är en ordningsfråga.

	Ligger det redan en utsidespunkt i kön när hon passerar dörrplanet,
	så hamnar spelarens boxsidiga läge från SAMMA bildruta EFTER den:

	    [ gammal box , UTE , ny box från utgångsbildrutan ]
	         ^gallras    ^stopp      ^överlever

	Hon förbrukar sedan UTE, spelaren går normalt ut i 0,5 m steg — och
	den bevarade boxsmulan väljs som delmål tillbaka in i boxen. Mätt i
	review: `delmal plan −2,00`, utan hopp och med sessionen vid liv.

	DE TVÅ FALLEN MÅSTE SKILJAS ÅT. En genuin SENARE återgång till
	boxsidan är framtida väg och ska leva (rond 7). Smulan som skapas i
	själva den fysiska utgångsbildrutan är spelarens läge INNAN hon kom
	ut — den är historik, oavsett var i kön den hamnar. ]]
print("\n── Smulan från utgångsbildrutan är historik, inte framtid ──")
do
	LedService._glomForProv()

	local anl = Instance.new("Model")
	anl.Name = "Anläggning"
	anl.Parent = workspace
	local DX, DZ = 800, 600
	local blad = Instance.new("Part")
	blad.Name = "Boxdörr utgångsruta"
	blad.Size = vec(0.18, 4.44, 3.60)
	blad.CFrame = CFrame.new(vec(DX, 2.22, DZ))
	blad:SetAttribute("UBRFBoxdorr", true)
	blad:SetAttribute("Langs", "Z")
	blad:SetAttribute("Utat", 1)
	blad:SetAttribute("UBRFOppningsmitt", vec(DX, 2.22, DZ))
	blad.Parent = anl

	local hU, kroppU = nyHast("utgangshast", vec(DX - 5, 3, DZ))
	local spU, rotU = nySpelare("Utgangsryttare", vec(DX - 3, 3, DZ))
	check("ledningen startar for utgangsrutan", LedService.borja(spU, hU, hU) == true)
	local lU = LedService.lage(spU)
	local function plan(p)
		local li = LedService.lage(spU)
		if not (li and li.dorrMitt and li.dorrUt) then return 0 end
		return (p - li.dorrMitt):Dot(li.dorrUt) / M
	end

	--[[ 1 · gammal boxhistorik OCH en utsidespunkt som redan ligger i kön. ]]
	local GAMMAL = vec(DX - 4.5, 3, DZ)
	local UTE    = vec(DX + 3, 3, DZ + 8)
	if lU then
		table.clear(lU.spar)
		table.insert(lU.spar, GAMMAL)
		table.insert(lU.spar, UTE)
	end
	check("kon ar gammal box + en utsidespunkt",
		lU ~= nil and #lU.spar == 2 and plan(GAMMAL) < 0 and plan(UTE) > 0,
		("plan %+.2f %+.2f"):format(plan(GAMMAL), plan(UTE)))

	--[[ 2 · UTGÅNGSBILDRUTAN. Hästen passerar planet; spelaren står kvar
		på boxsidan. Hans läge ligger mer än 0,6 m från sista smulan, så
		den vanliga loggningen antecknar det — EFTER `UTE`. ]]
	local EXITPOS = vec(DX - 6, 3, DZ)
	rotU.CFrame = CFrame.new(EXITPOS)
	kroppU.CFrame = CFrame.new(vec(DX + 4, 3, DZ))
	LedService._steg(1 / 30)

	lU = LedService.lage(spU)
	check("hon raknas som ute ur boxen", LedService.harLamnatBox(spU) == true)
	check("ledningen lever — inget hopp, inget slapp", lU ~= nil,
		("koppel %.2f m"):format((kroppU.Position - rotU.Position).Magnitude / M))

	local inneKvar, antal = false, 0
	for _, c in ipairs(lU and lU.spar or {}) do
		antal += 1
		if plan(c) <= 0 then inneKvar = true end
	end
	--[[ DEN FÖRSTA RÖDA MÄTNINGEN. Med enbart ledande gallring
		överlever exit-frame-smulan, för den ligger efter `UTE`. ]]
	check("smulan fran utgangsbildrutan far inte overleva",
		not inneKvar,
		("boxsidig smula kvar=%s; %d smulor"):format(tostring(inneKvar), antal))

	--[[ 3 · HON FÖRBRUKAR UTSIDESPUNKTEN, och spelaren går normalt ut
		i 0,5 m steg. Nu ska ingenting peka tillbaka in i boxen. ]]
	kroppU.CFrame = CFrame.new(UTE)
	LedService._steg(1 / 30)
	kroppU.CFrame = CFrame.new(vec(DX + 4, 3, DZ + 2))

	--[[ Spelaren gar UT, 0,5 m per bildruta. Mats gor det inte an: sa
		lange han sjalv star kvar inne ar det RATT att hon gar mot honom.
		Forsta versionen av provet raknade med de bildrutorna och var rod
		av fel skal. ]]
	for _ = 1, 24 do
		local nu = rotU.Position
		local mot = vec(DX + 6, 3, DZ + 4)
		local d = mot - nu
		if d.Magnitude > 0.05 then
			rotU.CFrame = CFrame.new(nu + d.Unit * math.min(0.5 * M, d.Magnitude))
		end
		LedService._steg(1 / 30)
	end
	check("spelaren ar ute i gangen nu", plan(rotU.Position) > 0,
		("spelarens plan %+.2f"):format(plan(rotU.Position)))

	--[[ NU mats det. Bada ar ute; ingenting far peka tillbaka in. ]]
	local varstaPlan = math.huge
	for _ = 1, 16 do
		LedService._steg(1 / 30)
		local li = LedService.lage(spU)
		if li and li.delmal then
			local p = plan(li.delmal)
			if p < varstaPlan then varstaPlan = p end
		end
	end
	--[[ DEN ANDRA RÖDA MÄTNINGEN — reviewens egen: delmal plan −2,00. ]]
	check("bevarad ny boxsmula far inte senare bli valt mal tillbaka in",
		varstaPlan > 0,
		("samsta delmal plan %+.2f"):format(varstaPlan))

	anl:Destroy()
end


--[[ ══ EN PAUSAD SVANS ÄR INTE LEDARENS NULÄGE ══════════════════════

	ChatGPT:s nionde reviewrond, på `c5f4b81`. Rond 8 gallrar också den
	AVSLUTANDE boxsidiga serien vid utgången, med motiveringen «där står
	ledaren just nu — han släpper fram henne och blir kvar innanför
	dörren».

	DEN MOTIVERINGEN ÄR ETT PÅSTÅENDE OM TIDEN, och rond 8 bevisade den
	aldrig. Den läste bara kön: sist + boxsidig = ledarens nuläge.

	Under den klistriga pausen från rond 5/6 är svansen gammal. Den är
	det sista som hann antecknas innan taket slog i, och spelaren kan ha
	gått hur långt som helst sedan dess — i reviewens fall är han redan
	UTE när hon passerar planet. Då raderar suffixregeln en framtida
	återgång som ingen har gått, av samma skäl som hela den här serien
	handlar om: en position i kön fick betyda ett framsteg.

	    sparFullt = true
	    [ gammal box , UTE , framtida återgång ]   ledaren står UTE
	                            ^raderades

	Kravet är alltså inte att sluta gallra svansen, utan att först BEVISA
	att den är ledarens nuläge. ]]
print("\n── En pausad svans är inte ledarens nuläge ──")
do
	LedService._glomForProv()

	local anl = Instance.new("Model")
	anl.Name = "Anläggning"
	anl.Parent = workspace
	local DX, DZ = 1000, 700
	local blad = Instance.new("Part")
	blad.Name = "Boxdörr pausad svans"
	blad.Size = vec(0.18, 4.44, 3.60)
	blad.CFrame = CFrame.new(vec(DX, 2.22, DZ))
	blad:SetAttribute("UBRFBoxdorr", true)
	blad:SetAttribute("Langs", "Z")
	blad:SetAttribute("Utat", 1)
	blad:SetAttribute("UBRFOppningsmitt", vec(DX, 2.22, DZ))
	blad.Parent = anl

	local hP, kroppP = nyHast("pausadhast", vec(DX - 5, 3, DZ))
	local spP, rotP = nySpelare("Pausadryttare", vec(DX - 3, 3, DZ))
	check("ledningen startar for pausprovet", LedService.borja(spP, hP, hP) == true)
	local lP = LedService.lage(spP)
	local function plan(p)
		local li = LedService.lage(spP)
		if not (li and li.dorrMitt and li.dorrUt) then return 0 end
		return (p - li.dorrMitt):Dot(li.dorrUt) / M
	end

	--[[ 1 · Kön som rond 5/6 lämnar den: pausad, med en framtida
		återgång sist. Ingen av punkterna ar gången. ]]
	local GAMMAL  = vec(DX - 4.5, 3, DZ)
	local UTE     = vec(DX + 3, 3, DZ + 8)
	local SVANS   = vec(DX - 2, 3, DZ + 10)
	if lP then
		table.clear(lP.spar)
		for _, p in ipairs({ GAMMAL, UTE, SVANS }) do table.insert(lP.spar, p) end
		lP.sparFullt = true
	end
	check("kon ar pausad med en framtida atergang sist",
		lP ~= nil and lP.sparFullt == true and #lP.spar == 3
			and plan(GAMMAL) < 0 and plan(UTE) > 0 and plan(SVANS) < 0,
		("sparFullt=%s  plan %+.2f %+.2f %+.2f"):format(
			tostring(lP and lP.sparFullt), plan(GAMMAL), plan(UTE), plan(SVANS)))

	--[[ 2 · LEDAREN ÄR REDAN UTE när hon passerar planet. Det är beviset
		som saknades: svansen kan omöjligt vara hans nuläge. Koppel
		5,90 m, alltså innanför `KOPPEL`. ]]
	rotP.CFrame = CFrame.new(vec(DX + 4, 3, DZ + 5.90 * M))
	kroppP.CFrame = CFrame.new(vec(DX + 4, 3, DZ))
	check("ledaren star UTE, och svansen ar inte hans lage",
		plan(rotP.Position) > 0 and (SVANS - rotP.Position).Magnitude / M > 0.6,
		("ledarens plan %+.2f, avstand till svansen %.2f m"):format(
			plan(rotP.Position), (SVANS - rotP.Position).Magnitude / M))
	local START_R, narmast = 1.8, math.huge
	for _, q in ipairs({ GAMMAL, UTE, SVANS }) do
		local d = (q - kroppP.Position).Magnitude / M
		if d < narmast then narmast = d end
	end
	check("ingen av smulorna ar gangen", narmast > START_R,
		("narmaste %.2f m"):format(narmast))

	LedService._steg(1 / 30)
	lP = LedService.lage(spP)
	check("hon raknas som ute ur boxen", LedService.harLamnatBox(spP) == true)
	check("ledningen lever", lP ~= nil,
		("koppel %.2f m"):format((kroppP.Position - rotP.Position).Magnitude / M))

	local svansKvar, gammalKvar = false, false
	for _, c in ipairs(lP and lP.spar or {}) do
		if (c - SVANS).Magnitude < 0.05 then svansKvar = true end
		if (c - GAMMAL).Magnitude < 0.05 then gammalKvar = true end
	end
	--[[ DEN RÖDA MÄTNINGEN. ]]
	check("avslutande plansidegallring far inte radera en STALE framtida atergang nar sparloggen ar pausad och ledaren redan ar ute",
		svansKvar,
		("framtida svans kvar=%s; %d smulor kvar; sparFullt=%s"):format(
			tostring(svansKvar), #(lP and lP.spar or {}),
			tostring(lP and lP.sparFullt)))
	--[[ …och rond 6b/7 står kvar: historiken före utgången går. ]]
	check("den gamla historiken inne i boxen gallras fortfarande",
		not gammalKvar, ("gammal kvar=%s"):format(tostring(gammalKvar)))
	check("pausen ar kvar — rond 5/6 ar orord",
		lP ~= nil and lP.sparFullt == true,
		("sparFullt=%s"):format(tostring(lP and lP.sparFullt)))

	anl:Destroy()
end


--[[ ══ NÄRHET ÄR INTE PROVENIENS ═══════════════════════════════════

	ChatGPT:s tionde reviewrond, på `f8877d6`. Rond 9 bytte ut
	suffixregeln mot ett «tidsbevis» som i själva verket var ett
	AVSTÅND: svansen räknades som ledarens nuläge om den låg inom
	0,6 m från honom.

	DET ÄR ROND 5:s INVARIANT IGEN. Närhet mellan två punkter säger
	ingenting om NÄR de uppstod. En gammal, pausad svans kan ligga
	tjugo centimeter från en spelare som kom dit långt senare, och då
	raderade rond 9 framtida rutt på ett sammanträffande.

	    sparFullt = true
	    ledaren     plan +0,10
	    svansen     plan −0,10       gap 0,20 m  <  0,6 m
	    -> raderades

	BEVISET MÅSTE VARA TIDSLIGT. Det finns redan i tillståndet, och det
	är exakt: antecknandet sker BARA när loggen är levande, och pausen
	släpper BARA när kön är tom. Kön är därför homogen — alla smulor i
	den hör till samma antecknandeomgång — och med levande logg ÄR
	svansen det senaste provet. Är loggen pausad är den per definition
	inte det, hur nära ledaren den än råkar ligga.

	Den homogeniteten är inget påstående i en kommentar; den mäts i
	nästa sektion. ]]
print("\n── Närhet är inte proveniens ──")
do
	LedService._glomForProv()

	local anl = Instance.new("Model")
	anl.Name = "Anläggning"
	anl.Parent = workspace
	local DX, DZ = 1200, 900
	local blad = Instance.new("Part")
	blad.Name = "Boxdörr narsvans"
	blad.Size = vec(0.18, 4.44, 3.60)
	blad.CFrame = CFrame.new(vec(DX, 2.22, DZ))
	blad:SetAttribute("UBRFBoxdorr", true)
	blad:SetAttribute("Langs", "Z")
	blad:SetAttribute("Utat", 1)
	blad:SetAttribute("UBRFOppningsmitt", vec(DX, 2.22, DZ))
	blad.Parent = anl

	--[[ Hon staller sig inom RACKVIDD (4,0 m) sa ledningen far borja;
		forsta versionen satte henne 4,25 m bort och nekades. ]]
	local hN, kroppN = nyHast("narsvanshast", vec(DX - 2, 3, DZ + 2))
	local spN, rotN = nySpelare("Narsvansryttare", vec(DX + 0.3, 3, DZ))
	check("ledningen startar for narhetsprovet", LedService.borja(spN, hN, hN) == true)
	local lN = LedService.lage(spN)
	local function plan(p)
		local li = LedService.lage(spN)
		if not (li and li.dorrMitt and li.dorrUt) then return 0 end
		return (p - li.dorrMitt):Dot(li.dorrUt) / M
	end

	--[[ Pausad kö med en framtida återgång sist — och den ligger NÄRA
		ledaren, inte långt bort som i rond 9. ]]
	local GAMMAL = vec(DX - 4.5, 3, DZ)
	local UTE    = vec(DX + 3, 3, DZ - 8)
	local SVANS  = vec(DX - 0.3, 3, DZ)
	if lN then
		table.clear(lN.spar)
		for _, p in ipairs({ GAMMAL, UTE, SVANS }) do table.insert(lN.spar, p) end
		lN.sparFullt = true
	end
	local gap = (SVANS - rotN.Position).Magnitude / M
	check("svansen ligger NARA ledaren — det ar hela poangen",
		gap < 0.6, ("gap %.2f m, under antecknandets 0,6 m"):format(gap))
	check("kon ar pausad, ledaren ute, svansen inne",
		lN ~= nil and lN.sparFullt == true
			and plan(rotN.Position) > 0 and plan(SVANS) < 0,
		("sparFullt=%s  ledaren %+.2f  svansen %+.2f"):format(
			tostring(lN and lN.sparFullt), plan(rotN.Position), plan(SVANS)))

	--[[ Hon gar ut. Kopplet haller, och ingen smula ar gangen. ]]
	kroppN.CFrame = CFrame.new(vec(DX + 2, 3, DZ + 11.58))
	local koppel = (kroppN.Position - rotN.Position).Magnitude / M
	local START_R, narmast = 1.8, math.huge
	for _, q in ipairs({ GAMMAL, UTE, SVANS }) do
		local d = (q - kroppN.Position).Magnitude / M
		if d < narmast then narmast = d end
	end
	check("kopplet haller och ingen smula ar gangen",
		koppel < 9.0 and narmast > START_R,
		("koppel %.2f m, narmaste smula %.2f m"):format(koppel, narmast))

	LedService._steg(1 / 30)
	lN = LedService.lage(spN)
	check("hon raknas som ute ur boxen", LedService.harLamnatBox(spN) == true)
	check("ledningen lever", lN ~= nil)

	local svansKvar, gammalKvar = false, false
	for _, c in ipairs(lN and lN.spar or {}) do
		if (c - SVANS).Magnitude < 0.05 then svansKvar = true end
		if (c - GAMMAL).Magnitude < 0.05 then gammalKvar = true end
	end
	--[[ DEN RÖDA MÄTNINGEN. ]]
	check("narhet till spelaren ar inte tidsbevis: stale framtida svans inom 0,6 m far inte raderas",
		svansKvar,
		("svans kvar=%s; gap %.2f m; %d smulor kvar; sparFullt=%s"):format(
			tostring(svansKvar), gap, #(lN and lN.spar or {}),
			tostring(lN and lN.sparFullt)))
	check("den gamla historiken inne i boxen gallras fortfarande",
		not gammalKvar, ("gammal kvar=%s"):format(tostring(gammalKvar)))

	anl:Destroy()
end


--[[ ══ PAUSEN ANTECKNAR INTE — DET ÄR PROVENIENSENS GRUND ══════════

	Rättelsen i rond 10 vilar på en enda egenskap: antecknandet sker
	bara när loggen är LEVANDE, och pausen släpper bara när kön är tom.
	Då är kön homogen — alla smulor i den hör till samma omgång — och
	med levande logg ÄR svansen det senaste provet.

	Den egenskapen får inte vara ett påstående i en kommentar. Här mäts
	den: med `sparFullt` satt läggs ingen smula till hur mycket
	spelaren än går, och kön krymper bara framifrån. ]]
print("\n── Pausen antecknar inte, och kön förblir homogen ──")
do
	LedService._glomForProv()
	local MITT = vec(1400, 3, 1100)
	local hH, kroppH = nyHast("homogenhast", MITT)
	local spH, rotH = nySpelare("Homogenryttare", MITT + vec(2 * M, 0, 0))
	check("ledningen startar for homogenitetsprovet",
		LedService.borja(spH, hH, hH) == true)
	local lH = LedService.lage(spH)
	if lH then lH.lamnatBox = true end

	--[[ Sa en kand ko och pausa den. ]]
	local A = MITT + vec(3 * M, 0, 0)
	local B = MITT + vec(3 * M, 0, 4 * M)
	if lH then
		table.clear(lH.spar)
		table.insert(lH.spar, A)
		table.insert(lH.spar, B)
		lH.sparFullt = true
	end
	local fore = lH and #lH.spar or -1

	--[[ Spelaren gar en lang vag medan det ar pausat. Innanfor kopplet. ]]
	local lades, vaxte = 0, false
	for i = 1, 30 do
		local a = (i / 30) * 2 * math.pi
		rotH.CFrame = CFrame.new(MITT + vec(math.cos(a) * 5 * M, 0, math.sin(a) * 5 * M))
		LedService._steg(1 / 30)
		local li = LedService.lage(spH)
		if li == nil then break end
		if #li.spar > fore then vaxte = true end
		lades = #li.spar
	end
	lH = LedService.lage(spH)
	check("ingen smula antecknas medan loggen ar pausad",
		lH ~= nil and not vaxte and lades <= fore,
		("kon gick %d -> %d, vaxte=%s"):format(fore, lades, tostring(vaxte)))
	check("och pausen star kvar sa lange kon inte ar tom",
		lH ~= nil and (#lH.spar == 0 or lH.sparFullt == true),
		("%d smulor, sparFullt=%s"):format(
			#(lH and lH.spar or {}), tostring(lH and lH.sparFullt)))
end


--[[ ══ HON GÅR UT I GÅNGEN, INTE TVÄRS ÖVER DEN (#182) ═════════════════

	Mätt i Studio på `6350c15`, bildruta 237:

	    boxdörr MB 5      x 496,49        gång B  x 496,6 .. 504,3
	    gammalt ut2       x 503,09        hästens collider 6,82 studs
	    häst 500,29 · 273,98  kurs 90°
	    kontakt: Workspace.Anläggning.UBRF.Boxdörr E 5

	Delmålet låg 1,2 studs från MOTSATTA radens front. Hon kördes rakt
	tvärs över en gång som är 0,9 studs bredare än hon är lång, kilade
	fast, och kopplet släppte på `led.fastnat` med en giltig väg hon inte
	kunde bära.

	Provet mäter KURSEN: med dörren öppen åt +x och spelaren i +z ska hon
	svänga mellan de två riktningarna, inte rakt ut. Rakt ut är 90°; längs
	gången är 0°; det nya delmålet ligger däremellan.

	Båda gångriktningarna provas — spelaren på var sida om dörren — för
	att svängen ska följa VART hon ska och inte en konstant. ]]
print("\n── Hon går ut i gången, inte tvärs över den ──")
do
	--[[ Mäter DELMÅLET, inte kursen. Kursen är en släpande avbildning av
		delmålet: den kan stämma av fel skäl, och den kan vara rätt medan
		punkten hon siktar på ligger i en vägg — vilket är exakt det #182
		mätte i Studio på `fe7ac37`.

		Som i blocket nedan mäts båda sidor om dörrplanet i en körning. ]]
	local function prova(motZ: number, namn: string)
		LedService._glomForProv()
		local anl = Instance.new("Model")
		anl.Name = "Anläggning"
		anl.Parent = workspace
		local DX, DZ = 600, 400
		local blad = Instance.new("Part")
		blad.Name = "Boxdörr sväng"
		blad.Size = vec(0.18, 4.44, 3.60)
		blad.CFrame = CFrame.new(vec(DX, 2.22, DZ))
		blad:SetAttribute("UBRFBoxdorr", true)
		blad:SetAttribute("Langs", "Z")
		blad:SetAttribute("Utat", 1)
		blad:SetAttribute("UBRFOppningsmitt", vec(DX, 2.22, DZ))
		blad.Parent = anl

		--[[ Hästen inne i boxen, vänd rakt ut mot dörren. ]]
		local h, kropp = nyHast("svänghäst" .. namn, vec(DX - 4, 3, DZ))
		--[[ Inom räckhåll — `borja` nekar annars — men tydligt på en sida
			om dörren, så att gångriktningen går att avgöra. ]]
		local sp, rot = nySpelare("Svängryttare" .. namn, vec(DX + 2, 3, DZ + motZ * 4))
		local ok, skal = LedService.borja(sp, h, h)
		if not ok then
			anl:Destroy()
			return false, nil, nil, tostring(skal)
		end

		--[[ Kör dörrsekvensen tills hon är förbi steg 1. ]]
		for _ = 1, 140 do LedService._steg(1 / 30) end
		local l = LedService.lage(sp)
		local inne = l and l.delmal and { ut = l.delmal.X - DX, langs = l.delmal.Z - DZ } or nil
		local dsteg = l and l.dorrsteg or -1

		--[[ Hon kliver ut genom öppningen — kortare än 2,5 m, så
			`lamnatBox` är fortfarande falsk och dörrgrenen kvar. ]]
		kropp.CFrame = CFrame.new(vec(DX + 1, 3, DZ))
		LedService._steg(1 / 30)
		l = LedService.lage(sp)
		local ute = l and l.delmal and { ut = l.delmal.X - DX, langs = l.delmal.Z - DZ } or nil
		local info = ("dsteg=%d spelare z%+.1f"):format(dsteg, rot.Position.Z - DZ)
		anl:Destroy()
		return ok, inne, ute, info
	end

	--[[ Gång B är 7,75 studs bred; motsatta radens front ligger alltså
		7,75 studs ut från dörrplanet. Delmålet får inte ligga där. ]]
	local GANGBREDD = 7.75
	local HALVA = 3.60 / 2

	--[[ Spelaren SÖDER om dörren (+z). ]]
	local okA, inneA, uteA, infoA = prova(1, "A")
	check("ledningen startar med boxdörr (spelaren i +z)", okA == true, tostring(infoA))
	check("delmålet ligger INTE vid motsatta radens front",
		uteA ~= nil and uteA.ut < GANGBREDD - 2.0,
		uteA and ("ut %+.2f av gångens %.2f · %s"):format(uteA.ut, GANGBREDD, infoA) or "inget delmål")
	check("inne i boxen siktar hon genom öppningen, inte förbi karmen",
		inneA ~= nil and math.abs(inneA.langs) <= HALVA,
		inneA and ("längs %+.2f av halva öppningen %.2f"):format(inneA.langs, HALVA) or "inget delmål")
	check("hästen svänger MOT gången, inte rakt tvärs över den",
		uteA ~= nil and uteA.langs > HALVA,
		uteA and ("ut %+.2f längs %+.2f · %s"):format(uteA.ut, uteA.langs, infoA) or "inget delmål")

	--[[ Spelaren NORR om dörren (−z): svängen ska gå åt andra hållet. ]]
	local okB, inneB, uteB, infoB = prova(-1, "B")
	check("ledningen startar med boxdörr (spelaren i −z)", okB == true, tostring(infoB))
	check("och åt andra hållet när hon ska åt andra hållet",
		uteB ~= nil and uteB.langs < -HALVA,
		uteB and ("ut %+.2f längs %+.2f · %s"):format(uteB.ut, uteB.langs, infoB) or "inget delmål")
	check("de två riktningarna ger OLIKA delmål — svängen följer målet",
		uteA ~= nil and uteB ~= nil and uteA.langs * uteB.langs < 0,
		(uteA and uteB) and ("längs %+.2f mot %+.2f"):format(uteA.langs, uteB.langs) or "inget delmål")
	check("men inne i boxen är de LIKA — karmen går före svängen",
		inneA ~= nil and inneB ~= nil
			and math.abs(inneA.langs) < 0.01 and math.abs(inneB.langs) < 0.01,
		(inneA and inneB) and ("längs %+.2f mot %+.2f"):format(inneA.langs, inneB.langs) or "inget delmål")
end


--[[ ══ DEN SOM STÅR I DÖRREN PEKAR INTE ÅT NÅGOT HÅLL (#194) ═══════════

	Mätt i Studio på `b934ddb`, och det var den verkliga orsaken till att
	boxutgången kostade tre sekunder och kopplet:

	    spelaren  −0.02 studs längs gången  ->  mot −1  ->  ut2 NORRUT
	    spelaren  +0.00 studs längs gången  ->  mot +1  ->  ut2 SÖDERUT

	Provet ovan ställer spelaren FYRA studs åt ena hållet, och där är
	tecknet välbestämt. Men den som leder en häst ut ur en box står i
	öppningen, och då är projektionen på gångens riktning noll. Tecknet
	avgjordes av fysikjitter, och delmålet hamnade 1,2 m åt fel håll lika
	ofta som åt rätt. Hästen lämnade dörren på kurs 127,7° medan rutten bar
	≈ −6°, och fick vrida 133° medan spelaren gick ifrån henne.

	Två mätningar, och båda saknades:

	1. MÅLZONEN avgör när spelarens läge inte gör det. Hon ska ledas ut åt
	   det håll hon faktiskt ska gå.
	2. TECKNET FÅR INTE VIPPA. Två spelarlägen som skiljer 0,04 studs ska
	   ge SAMMA sväng. Det är den raden som blir röd med det gamla
	   villkoret. ]]
print("\n── Den som står i dörren pekar inte åt något håll ──")
do
	--[[ Samma dörr som provet ovan, men spelaren står I öppningen och
		målzonen ligger tydligt åt ett håll längs gången. ]]
	--[[ Provet mäter DELMÅLET på båda sidor om dörrplanet i EN körning.

		Att bara mäta inne i boxen räcker inte längre, och det är #182:s
		fynd: delmålets offset LÄNGS gången är 1,2 m medan öppningens halva
		bredd är 0,60 m, så innanför karmen pekar delmålet alltid utanför
		hålet. Först när hon passerat dörrplanet är offseten fri att gälla.

		Hästen flyttas därför i provet, från 4 studs innanför till 1 studs
		utanför — kortare än de 2,5 m som gör `lamnatBox` sann, så
		dörrgrenen är kvar i båda mätningarna. ]]
	local function provaZon(spelarOffsetZ, zonY, namn)
		LedService._glomForProv()
		local anl = Instance.new("Model")
		anl.Name = "Anläggning"
		anl.Parent = workspace
		local DX, DZ = 600, 400
		local blad = Instance.new("Part")
		blad.Name = "Boxdörr zonsväng"
		blad.Size = vec(0.18, 4.44, 3.60)
		blad.CFrame = CFrame.new(vec(DX, 2.22, DZ))
		blad:SetAttribute("UBRFBoxdorr", true)
		blad:SetAttribute("Langs", "Z")
		blad:SetAttribute("Utat", 1)
		blad:SetAttribute("UBRFOppningsmitt", vec(DX, 2.22, DZ))
		blad.Parent = anl

		--[[ Målzonen i TOMTKOORDINATER, som `GameplayService` sätter den.
			Dörren ligger på tomt-y = 170 − 400/3 ≈ 36,7; en zon norr eller
			söder om det ger ett entydigt tecken längs gången. ]]
		LedService.satMalzon({ x = 190, y = zonY, w = 10, h = 10 })

		local h, kropp = nyHast("zonhäst" .. namn, vec(DX - 4, 3, DZ))
		--[[ I ÖPPNINGEN: offsetten är bråkdelar av en studs. ]]
		local sp, rot = nySpelare("Zonryttare" .. namn, vec(DX + 2, 3, DZ + spelarOffsetZ))
		local ok, skal = LedService.borja(sp, h, h)
		if not ok then
			anl:Destroy()
			LedService.satMalzon(nil)
			return false, nil, nil, tostring(skal)
		end
		for _ = 1, 140 do LedService._steg(1 / 30) end
		local l = LedService.lage(sp)
		local inne = l and l.delmal and { ut = l.delmal.X - DX, langs = l.delmal.Z - DZ } or nil
		local dsteg = l and l.dorrsteg or -1

		--[[ Hon kliver ut genom öppningen. Provet flyttar henne; tjänsten
			ska svara på var hon FAKTISKT är. ]]
		kropp.CFrame = CFrame.new(vec(DX + 1, 3, DZ))
		LedService._steg(1 / 30)
		l = LedService.lage(sp)
		local ute = l and l.delmal and { ut = l.delmal.X - DX, langs = l.delmal.Z - DZ } or nil
		local info = ("spelare z%+.2f · zon y=%.0f · dsteg=%d"):format(
			rot.Position.Z - DZ, zonY, dsteg)
		anl:Destroy()
		LedService.satMalzon(nil)
		return ok, inne, ute, info
	end

	--[[ Halva öppningen, ur bladets egen bredd — samma tal tjänsten
		använder för att avgöra om spelaren står "tydligt" åt ett håll. ]]
	local HALVA = 3.60 / 2

	--[[ ── #182: INNE I BOXEN SIKTAR HON GENOM HÅLET ──────────────────

		Mätt i Studio på `fe7ac37`, box MB 5 med dörren öppen: strålen från
		hästen till det gamla delmålet blockeras av `Boxfront MB 5` på
		1,36 m, medan strålen till dörrmitten och rakt ut är fri. Hon stod
		med kurs 88,0°, WalkSpeed 4,3 och flyttade sig 1,23 m på 7,5 s.

		Raden nedan är den som blir röd utan rättelsen: den gamla formen
		ger |längs| = 3,6 studs mot öppningens halva bredd 1,8. ]]
	local okS, inneS, uteS, infoS = provaZon(0, 20, "S")
	check("ledningen startar med boxdörr och målzon", okS == true, tostring(infoS))
	check("inne i boxen ligger delmålet INNANFÖR öppningen",
		inneS ~= nil and math.abs(inneS.langs) <= HALVA,
		inneS and ("längs %+.2f av halva öppningen %.2f · ut %+.2f · %s"):format(
			inneS.langs, HALVA, inneS.ut, infoS) or "inget delmål")
	check("inne i boxen siktar hon rakt ut genom dörren",
		inneS ~= nil and inneS.ut > 0 and math.abs(inneS.langs) < 0.01,
		inneS and ("ut %+.2f längs %+.2f"):format(inneS.ut, inneS.langs) or "inget delmål")

	--[[ ── #194: UTE I GÅNGEN AVGÖR MÅLZONEN SVÄNGEN ──────────────────

		Oförändrad avsikt, mätt där den nu gäller. Zonen SÖDER om dörren i
		världen (+z, alltså lägre tomt-y) ska ge ett delmål söderut. ]]
	check("ute i gången, målzonen söderut → delmålet går söderut",
		uteS ~= nil and uteS.langs > HALVA,
		uteS and ("längs %+.2f · %s"):format(uteS.langs, infoS) or "inget delmål")

	--[[ Zonen NORR om dörren (−z, högre tomt-y). ]]
	local _, inneN, uteN, infoN = provaZon(0, 55, "N")
	check("ute i gången, målzonen norrut → delmålet går norrut",
		uteN ~= nil and uteN.langs < -HALVA,
		uteN and ("längs %+.2f · %s"):format(uteN.langs, infoN) or "inget delmål")
	check("målzonen avgör svängen när spelarens läge inte gör det",
		uteS ~= nil and uteN ~= nil and uteS.langs * uteN.langs < 0,
		(uteS and uteN) and ("längs %+.2f mot %+.2f"):format(uteS.langs, uteN.langs) or "inget delmål")
	check("och samma zon ger samma svar på båda sidor om planet",
		inneN ~= nil and math.abs(inneN.langs) < 0.01,
		inneN and ("inne längs %+.2f"):format(inneN.langs) or "inget delmål")

	--[[ ── OCH TECKNET FÅR INTE VIPPA PÅ HUNDRADELAR (#194) ───────────

		Två lägen som skiljer 0,04 studs — mindre än en hovbredd — låg på
		var sin sida om `>= 0` och gav delmål 2,4 m från varandra. ]]
	local _, _, uteMinus, infoMinus = provaZon(-0.02, 20, "J1")
	local _, _, utePlus, infoPlus = provaZon(0.02, 20, "J2")
	check("±0,02 studs i öppningen ger SAMMA sväng — tecknet vippar inte",
		uteMinus ~= nil and utePlus ~= nil
			and uteMinus.langs * utePlus.langs > 0
			and math.abs(uteMinus.langs - utePlus.langs) < 0.1,
		(uteMinus and utePlus)
			and ("längs %+.2f mot %+.2f  ·  %s  ·  %s"):format(
				uteMinus.langs, utePlus.langs, infoMinus, infoPlus)
			or "inget delmål")
end


--[[ ══ HÄSTEN LÄMNAS INTE I GÅNGEN (#202 punkt 4) ═════════════════════

	Mätt i Studio på `e6a674c`: Player2 ledde Troy ut ur box E 8 och
	kopplade sedan ned. `PlayerRemoving` släppte kopplet — och lämnade henne
	stående på (166,57 · 96,80), mitt i gång B.

	`aterstallTillBox` ställer henne tillbaka där hon stod när kopplet
	fästes. Provet mäter alla tre spärrarna, inte bara det lyckade fallet:
	utan dem hade städningen kunnat flytta en häst som aldrig varit i en
	box, eller en som står kvar i sin. ]]
print("\n── Hästen lämnas inte i gången ──")
do
	local function uppstallning(namn)
		LedService._glomForProv()
		local anl = Instance.new("Model")
		anl.Name = "Anläggning"
		anl.Parent = workspace
		local DX, DZ = 900, 300
		local blad = Instance.new("Part")
		blad.Name = "Boxdörr städ"
		blad.Size = vec(0.18, 4.44, 3.60)
		blad.CFrame = CFrame.new(vec(DX, 2.22, DZ))
		blad:SetAttribute("UBRFBoxdorr", true)
		blad:SetAttribute("Langs", "Z")
		blad:SetAttribute("Utat", 1)
		blad:SetAttribute("UBRFOppningsmitt", vec(DX, 2.22, DZ))
		blad.Parent = anl
		local h, kropp = nyHast("städhäst" .. namn, vec(DX - 4, 3, DZ))
		local sp = nySpelare("Städryttare" .. namn, vec(DX + 2, 3, DZ))
		local ok, skal = LedService.borja(sp, h, h)
		return anl, h, kropp, sp, ok, skal
	end

	--[[ a. Hon har letts ut i gången. Då ska hon tillbaka. ]]
	local anl, h, kropp, sp, ok, skal = uppstallning("A")
	check("ledningen startade", ok == true, tostring(skal))
	local start = kropp.Position
	--[[ Ut i gången, längre än de 2,5 m som `lamnatBox` mäts på. ]]
	kropp.CFrame = CFrame.new(vec(900 + 8, 3, 300))
	local lamnad = kropp.Position
	local stadat, stadskal = LedService.aterstallTillBox(LedService.boxminne(sp))
	check("städningen körde", stadat == true, tostring(stadskal))
	check("hästen står tillbaka där kopplet fästes",
		(kropp.Position - start).Magnitude < 0.5 * 3,
		("%.2f studs från startpunkten, %.2f studs från gången"):format(
			(kropp.Position - start).Magnitude, (kropp.Position - lamnad).Magnitude))
	check("och hon står INTE kvar i gången",
		(kropp.Position - lamnad).Magnitude > 2.0 * 3,
		("%.2f studs"):format((kropp.Position - lamnad).Magnitude))
	anl:Destroy()

	--[[ b. Hon står kvar i boxen. Då finns inget att städa. ]]
	local anl2, h2, kropp2, sp2 = uppstallning("B")
	local kvar = kropp2.Position
	local stadat2, skal2 = LedService.aterstallTillBox(LedService.boxminne(sp2))
	check("en häst som står kvar i boxen städas INTE",
		stadat2 == false, tostring(skal2))
	check("och hon flyttades inte en millimeter",
		(kropp2.Position - kvar).Magnitude < 1e-6,
		("%.6f studs"):format((kropp2.Position - kvar).Magnitude))
	anl2:Destroy()

	--[[ c. Hela vägen genom `PlayerRemoving` — den kroken är det som
		faktiskt kör i drift, och den var tom på städning. Utan den här
		raden mäter provet bara funktionen, inte att någon anropar den.

		`start()` körs EN gång, här, och först nu: den kopplar Heartbeat och
		fjärrobjekt, och blocken ovan ska köra utan dem. ]]
	LedService.start()
	local anl3, h3, kropp3, sp3 = uppstallning("C")
	local start3 = kropp3.Position
	kropp3.CFrame = CFrame.new(vec(900 + 8, 3, 300))
	Players.PlayerRemoving:Fire(sp3)
	if Players.PlayerRemoving.slutfor then Players.PlayerRemoving:slutfor() end
	check("PlayerRemoving släpper kopplet", LedService.lage(sp3) == nil)
	check("och minnet är rivet — bokföringen är sessionsbunden",
		LedService.boxminne(sp3) == nil)
	check("OCH ställer tillbaka hästen — inte bara släpper henne",
		(kropp3.Position - start3).Magnitude < 0.5 * 3,
		("%.2f studs från startpunkten"):format((kropp3.Position - start3).Magnitude))
	anl3:Destroy()

	--[[ d. DET VANLIGA FÖRLOPPET: kopplet har redan släppt när spelaren
		stänger spelet. Hon blir efter, `led.tappade_bort` fyrar, spelaren
		ger upp. Mätt i Studio på `5c70963`: `Led.aktiv = nil` medan hon
		stod 3,44 m ut i gång A, och första rättelsen städade aldrig. ]]
	local anl4, h4, kropp4, sp4 = uppstallning("D")
	local start4 = kropp4.Position
	kropp4.CFrame = CFrame.new(vec(900 + 8, 3, 300))
	LedService.slapp(sp4, "led.tappade_bort")
	check("kopplet har släppt innan nedkopplingen", LedService.lage(sp4) == nil)
	check("men minnet finns kvar", LedService.boxminne(sp4) ~= nil)
	Players.PlayerRemoving:Fire(sp4)
	if Players.PlayerRemoving.slutfor then Players.PlayerRemoving:slutfor() end
	check("hästen ställs tillbaka ÄVEN när kopplet redan släppt",
		(kropp4.Position - start4).Magnitude < 0.5 * 3,
		("%.2f studs från startpunkten"):format((kropp4.Position - start4).Magnitude))
	anl4:Destroy()
end

if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("\nledning.spec: alla gröna")
end
