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
rot.CFrame = CFrame.new(varld(132, 70))
hastKropp.CFrame = CFrame.new(varld(132, 72))
LedService._steg(1 / 30)
check("när hon fysiskt står i ridbanan ser tjänsten det",
	LedService.harNattMal(spelare) == true)

print("\n── Följandet ──")

--[[ Hon ska få order att GÅ när avståndet växer — och ordern ska vara
	en RÖRELSERIKTNING, inte en punkt. Skillnaden är hela blockeraren:
	`MoveTo` skjuter kroppen mot punkten oavsett hur den står, och en häst
	som går i sidled in i en 1,20 m öppning fastnar. ]]
rot.CFrame = CFrame.new(varld(132, 60))
hastKropp.CFrame = CFrame.new(varld(132, 66))
LedService._steg(1 / 30)
local dir = hastHum._moveDir
check("tjänsten ger hästen en rörelseriktning när avståndet växer",
	dir ~= nil and dir.Magnitude > 0.5,
	dir and string.format("%.2f", dir.Magnitude) or "nil")
check("och hon får skrittfart, inte noll", hastHum.WalkSpeed > 0,
	string.format("%.2f studs/s", hastHum.WalkSpeed))

--[[ HON GÅR DIT HON PEKAR. Riktningen som skickas ska vara hästens EGEN
	framåtvektor, inte fågelvägen till målpunkten. ]]
if dir then
	local _, kursen = hastKropp.CFrame:ToOrientation()
	local framatV = Vector3.new(math.sin(kursen), 0, math.cos(kursen))
	local prick = dir.X * framatV.X + dir.Z * framatV.Z
	check("ordern går i hästens egen riktning, inte i sidled",
		prick > 0.99, string.format("prickprodukt %.4f", prick))
end

--[[ HYSTERESEN: står hon nära nog ska hon STÅ, inte pendla. ]]
hastKropp.CFrame = CFrame.new(rot.Position - vec(0, 0, 2.2 * M))
hastHum._moveDir = nil
LedService._steg(1 / 30)
LedService._steg(1 / 30)
check("innanför dödzonen får hon order att STÅ, inte att gå",
	hastHum._moveDir ~= nil, tostring(hastHum._moveDir))

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
	hum5.WalkSpeed = 0
	--[[ 90 bildrutor: hon hinner vända sig först — det SKA ta tid — och
		sedan gå. Kravet är att hon kommer iväg, inte att hon gör det i
		samma bildruta. ]]
	for _ = 1, 90 do LedService._steg(1 / 30) end
	check("hon låser sig inte i glappet vid sin egen brödsmula",
		l5.gar == true and hum5.WalkSpeed > 0,
		string.format("gar=%s fart %.2f", tostring(l5.gar), hum5.WalkSpeed))
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
	local _, kurs0 = kropp4.CFrame:ToOrientation()

	LedService._steg(1 / 30)
	local _, kurs1 = kropp4.CFrame:ToOrientation()
	check("ledningen äger kursen — hästen vrider sig",
		math.abs(kurs1 - kurs0) > 1e-4,
		string.format("%.4f rad på en bildruta", math.abs(kurs1 - kurs0)))

	--[[ VRIDTAKTEN KOMMER UR KANON, inte ur ett tal i tjänsten.
		`TurnInPlaceRate` är takten en STÅENDE häst får vrida sig i. Faller
		den här mätningen har någon satt en egen siffra. ]]
	local takt = math.abs(kurs1 - kurs0) * 30
	check("vridtakten är kanonens, inte en egen siffra",
		math.abs(takt - Config.MOVEMENT.TurnInPlaceRate) < 0.02,
		string.format("%.3f rad/s mot kanonens %.3f", takt,
			Config.MOVEMENT.TurnInPlaceRate))

	--[[ MED KROPPEN PÅ TVÄREN GÅR HON INTE. Ett kvarts varv fel och full
		fart framåt är exakt det som kilade fast henne. ]]
	check("med stort kursfel vänder hon först och går inte",
		hum4.WalkSpeed == 0, string.format("%.2f studs/s", hum4.WalkSpeed))

	--[[ Och hon ska vrida sig ÄNDA FRAM och sedan gå. Utan den här raden
		kunde tjänsten bara vrida, aldrig komma iväg. ]]
	for _ = 1, 90 do LedService._steg(1 / 30) end
	local _, kurs2 = kropp4.CFrame:ToOrientation()
	local framatV = Vector3.new(math.sin(kurs2), 0, math.cos(kurs2))
	local mot = rot4.Position - kropp4.Position
	local langd = math.sqrt(mot.X * mot.X + mot.Z * mot.Z)
	local prick = (mot.X * framatV.X + mot.Z * framatV.Z) / math.max(langd, 1e-6)
	check("hon vänder sig ända fram till rätt kurs och går sedan",
		prick > 0.9 and hum4.WalkSpeed > 0,
		string.format("prickprodukt %.3f, fart %.2f studs/s", prick, hum4.WalkSpeed))

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
			math.abs(pp.AgentRadius - kropp2.Size.X * 0.5) < 0.01,
			string.format("%.3f studs (bredd/2 = %.3f, längd/2 = %.3f)",
				pp.AgentRadius, kropp2.Size.X * 0.5, kropp2.Size.Z * 0.5))
		check("AgentRadius ryms i boxdörrens 3,60 studs",
			pp.AgentRadius * 2 < 3.60,
			string.format("diameter %.2f studs", pp.AgentRadius * 2))
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
if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("\nledning.spec: alla gröna")
end
