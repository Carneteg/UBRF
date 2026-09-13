--!strict
--[[
	LEDA HÄSTEN — spelaren går, hästen följer.

	Blockerare 2 i #162. Rutten var framkomlig (boxdörren i 27e5c2a, mätt
	0 av 9 punkter blockerade) men hästen leddes aldrig av någon: testet
	drev henne med `Humanoid:MoveTo` från en ingenjörs hand, och `leda`
	blev sann så fort spelaren tryckte — även med hästen kvar i boxen.

	DEN HÄR TJÄNSTEN ÄR AVSIKTLIGT LITEN. Scope guardrailen i CLAUDE.md
	säger ett lätt, responsivt ridspel och inte en simulator: ingen
	vägsökning, ingen egen fysik, ingen state machine. Hästen får ett mål
	bakom spelaren varje bildruta och går dit med sin EGEN Humanoid — samma
	lokomotion som Gate 1 mätte. Inget CFrame-släpande, ingen ankring,
	ingen teleport, ingen osynlig transportband.

	HYSTERESEN ÄR POÄNGEN. Ett enda avståndsvärde ger en häst som startar
	och stannar varje bildruta på gränsen — det syns som ryck och som att
	hon studsar kring målpunkten. Därför två trösklar: hon stannar när hon
	kommit innanför STOPP_R och börjar inte gå igen förrän avståndet
	passerat START_R. Mellan dem gör hon ingenting, och det är precis den
	dödzonen som gör att hon står stilla när spelaren står stilla.

	KOPPLET är inte en gräns för att vara sträng. Går spelaren ifrån henne
	ska ledningen SLÄPPA i stället för att hästen ska springa genom en
	vägg för att hinna ikapp — och spelaren ska få veta varför.
]]

local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HorseCore = require(ReplicatedStorage.HorseCore)
local Net = HorseCore.Networking
local Gaits = require(ReplicatedStorage.HorseCore.Gaits)
local Config = require(ReplicatedStorage.HorseCore.Config)

local LedService = {}

local M = 3                    -- studs per meter, som BuildKit.M

--[[ Måtten är spelkänsla, inte mätningar av verkligheten, och står därför
	här och inte i den delade världsdatan. ]]
local RACKVIDD   = 4.0         -- m: så nära måste man stå för att få börja leda
local FOLJ_BAKOM = 2.4         -- m: hästens målpunkt bakom spelaren
local STOPP_R    = 1.0         -- m: innanför detta står hon still
local START_R    = 1.8         -- m: utanför detta går hon igen (hysteres)
local KOPPEL     = 9.0         -- m: längre bort och kopplet släpper

--[[ ══ NAVIGERINGEN — PathfindingService som LOKAL RESERV ═══════════════

	Godkänd snävt av PO efter att tre billigare vägar mätts bort: bredare
	dörr (vändutrymmet fanns redan — 3,50 x 3,62 m mot en vändcirkel på
	1,85 m), dörr-waypoint (hon kilade sig på yaw −141° med
	MoveDirection 0), och att det skulle vara ett lokomotionsfel (Gate 1
	mätte 75,66 m förflyttning).

	DEN ERSÄTTER INGENTING. Spårföljningen, hysteresen, farterna, kopplet
	och alla nej-vägar står kvar. Planeraren kopplas in bara när hon är i
	trångt läge eller har slutat komma framåt, och släpper så fort hon är
	fri igen.

	AGENTEN MÅTTSÄTTS UR HÄSTENS EGET KOLLISIONSHÖLJE, inte ur Roblox
	standardvärden. En avvikelse måste förklaras, och här finns en:

	  PathfindingService modellerar agenten som en CYLINDER. Hästens
	  hölje är 1,86 x 2,34 x 5,55 studs — en avlång kropp. Sätts radien
	  till halva LÄNGDEN (2,775) krävs en öppning bredare än 5,55 studs,
	  och boxdörren är 3,60. Planeraren hade då svarat "ingen väg" på en
	  dörr hästen fysiskt ryms igenom, eftersom hon passerar på längden.

	  Bindande mått för en dörr är alltså kroppens BREDD. Radien sätts
	  till halva bredden, 0,93 studs, vilket lämnar 0,87 studs marginal
	  mot dörrens halva bredd. Höjden är mankhöjden: HipHeight 2,01 plus
	  kroppens 2,34 = 4,35 studs.

	Hon hoppar inte och klättrar inte när hon leds. ]]
local NAV_RADIE_FAKTOR = 0.5   -- av kroppens BREDD, se noten ovan
local NAV_VAGPUNKT     = 2.5   -- studs mellan vägpunkter; tätare än standard 4
local NAV_NA_VAGPUNKT  = 1.6   -- studs: så nära räknas en vägpunkt som nådd
local NAV_STILLA       = 1.2   -- s utan framsteg innan planeraren kopplas in
local NAV_OMPLAN_PAUS  = 1.0   -- s: kortaste tid mellan två planeringar
local NAV_MAX_PLANER   = 6     -- fler än så och vi ger upp i stället för att mala
local NAV_FASTNAT      = 8.0   -- s helt stilla trots order: kopplet släpper
local NAV_ANKARE       = 0.25  -- m hon måste förflytta sig för att räknas som i rörelse

--[[ EN LEDD HÄST SKRITTAR. Farten hämtas ur gångartskanonen och skrivs
	inte av som ett tal: `Gaits.DATA.walk.norm` är skrittens nominella
	fart i m/s och är samma siffra ridningen räknar med.

	Varför det behövs: en oriden häst har `WalkSpeed = 0` — `HorseService`
	nollar den när ryttaren stiger av, och klientens MovementController
	sätter den bara medan någon rider. Mätt i Studio gav `MoveTo` då en
	riktning men noll förflyttning. Ledningen måste alltså ge henne en
	fart, och lämna tillbaka den när kopplet släpper. ]]
local function skrittfart(): number
	local w = Gaits.DATA and Gaits.DATA.walk
	return ((w and w.norm) or 1.45) * M
end

--[[ ══ VRIDNINGEN — LEDNINGEN ÄGER DEN ═══════════════════════════════

	MÄTT I STUDIO, och det här är den verkliga blockeraren: hästen kunde
	inte vrida sig. `HorseService` sätter `AutoRotate = false` på varenda
	häst — 33 av 33 — med motiveringen att spelet äger vridningen, och
	under ritt är det sant: `MovementController` skriver kursen på roten
	varje bildruta. Men den modulen kör bara för den som SITTER UPP. En
	oriden häst hade därmed ingen som vred henne alls.

	Följden var precis det som mättes om och om igen: hon gick mot dörren
	MED SIDAN FÖRE. Kroppen är 1,85 m lång och 0,62 m bred, öppningen
	1,20 m — bredsidan går aldrig igenom, hur rätt vägpunkten än ligger.
	Därav `MoveDirection = 0` mot `Boxfront MB 5`, och därav att varken
	dörr-waypointen eller vägsökningen hjälpte: båda pekade rätt, men
	kroppen pekade fel.

	LEDNINGEN ÄGER DÄRFÖR KURSEN så länge hon leds, på exakt samma sätt
	som `MovementController` gör under ritt: bara rotation, aldrig läge.
	Förflyttningen sköter Humanoiden, höjden sköter fysiken. Att i stället
	slå på `AutoRotate` hade lämnat vridtakten till Roblox, och det är den
	fordonskänsla gaten uttryckligen ska bort ifrån.

	VRIDTAKTEN KOMMER UR KANON, inte ur ett tal här: `CurvatureMax` gånger
	tempot medan hon går (0,42 × 1,45 = 0,61 rad/s, alltså 2,4 m radie —
	samma båge som ridningen), och `TurnInPlaceRate` när hon nästan står
	stilla. En häst som står får vrida sig; en häst i rörelse får det inte
	snurra på fläcken.

	OCH HON GÅR DIT HON PEKAR. `Humanoid:Move` med hennes egen framåtvektor
	i stället för `MoveTo` mot punkten: annars går hon i sidled mot målet
	med kroppen kvar på tvären, vilket är exakt det som kilade fast henne.
	Är kursfelet stort går hon inte alls utan vänder först. ]]
local VAND_FULL   = math.rad(40)   -- under detta kursfel: full fart
local VAND_STOPP  = math.rad(75)   -- över detta: vänd på stället, gå inte

--[[ KURSEN ÄR BLICKRIKTNINGEN, samma definition som
	`MovementController` använder: `heading = atan2(Look.X, Look.Z)`, och
	därmed är `(sin h, 0, cos h)` exakt `LookVector`.

	Förut lästes kursen som `ToOrientation().Y`, alltså den vinkel man
	skickar till `CFrame.Angles` — vars blickriktning är den MOTSATTA. Med
	`framat()` nedan gav det en häst som leddes med svansen före: mätt i
	Studio låg huvudet 3,32 studs BAKOM färdriktningen. ]]
local function kurs(pivot: BasePart): number
	local look = pivot.CFrame.LookVector
	return math.atan2(look.X, look.Z)
end

local function framat(h: number): Vector3
	return Vector3.new(math.sin(h), 0, math.cos(h))
end

--[[ Vrid roten mot `onskad` med kanonens takt, och svara hur stort
	kursfelet var EFTER vridningen. Position rörs inte. ]]
local function vridMot(pivot: BasePart, onskad: number, fartMS: number, dt: number): number
	local nu = kurs(pivot)
	local fel = (onskad - nu + math.pi) % (2 * math.pi) - math.pi

	local MO = Config.MOVEMENT
	local omega = (MO.CurvatureMax :: number) * fartMS
	local underGrans = (MO.TurnInPlaceBelow :: number)
	if fartMS < underGrans then
		local andel = 1 - fartMS / underGrans
		omega = math.max(omega, (MO.TurnInPlaceRate :: number) * andel)
	end

	local steg = math.clamp(fel, -omega * dt, omega * dt)
	--[[ Blickriktningen skrivs DIREKT, inte via en vinkel vars
		teckenkonvention går att missa. Positionen rörs inte. ]]
	local p = pivot.CFrame.Position
	pivot.CFrame = CFrame.lookAt(p, p + framat(nu + steg), Vector3.yAxis)
	return math.abs(fel - steg)
end

export type Led = {
	modell: Model,
	hastId: string,
	gar: boolean,          -- hysteresens läge: går hon just nu?
	lamnatBox: boolean,    -- har hon FYSISKT varit utanför boxen?
	malNatt: boolean,      -- har hon FYSISKT varit i målzonen?
	boxX: number, boxY: number,
	tidigareFart: number,
	tidigareSpelarfart: number,
	tidigareAgare: Player?,
	tidigareAuto: boolean,
	spar: { Vector3 },
	dorr: BasePart?,
	dorrMitt: Vector3?,
	dorrUt: Vector3?,
	dorrsteg: number,
	-- navigeringen
	navVag: { Vector3 },
	navIx: number,
	navPlaner: number,
	navSenast: number,
	planerar: boolean,
	tid: number,
	stillaSedan: number,
	badGa: boolean,
	ankare: Vector3,
}

local ledd: { [Player]: Led } = {}
local hakar: { [string]: (Player, Led) -> () } = {}

--[[ ══ DET UPPNÅDDA ÖVERLEVER KOPPLET ═══════════════════════════════════

	`lamnatBox` och `malNatt` är inte kopplets tillstånd — de är sådant som
	HÄNT och inte kan hända ogjort. De låg ändå bara i `ledd[player]`, och
	`slapp` tömmer den posten. Att leda hästen hela vägen till ridhuset och
	sedan släppa kopplet — alltså det spelaren faktiskt gör när hon är
	framme — nollade därför beviset för att hon varit framme.

	Mätt i runtime: hästen stod i målzonen (`iRekt` = true på
	(419,1 · 257,0)), men `harLamnatBox` och `harNattMal` svarade båda
	false efter `LedSlapp`, och `PreparationMoment("leda")` svarade
	`led.kvar_i_boxen` — "kvar i boxen" om en häst som står i ridhuset.

	Därför bokförs det uppnådda här, per spelare OCH per häst. Per häst
	för att en ny häst ska börja om från noll: byter spelaren häst är det
	en ny ledning som ska gå hela vägen igen. ]]
type Uppnatt = { hastId: string, lamnatBox: boolean, malNatt: boolean }
local uppnatt: { [Player]: Uppnatt } = {}

local function noteraUppnatt(player: Player, hastId: string, falt: string)
	local u = uppnatt[player]
	if not u or u.hastId ~= hastId then
		u = { hastId = hastId, lamnatBox = false, malNatt = false }
		uppnatt[player] = u
	end
	(u :: any)[falt] = true
end

--[[ Har spelaren uppnått det här med DEN HÄR hästen? `hastId` är nil när
	frågan gäller "vilken häst som helst", vilket är vad de publika
	frågorna nedan gör: de känner bara spelaren. ]]
local function harUppnatt(player: Player, falt: string): boolean
	local u = uppnatt[player]
	return u ~= nil and (u :: any)[falt] == true
end

--[[ ── Koordinater ──────────────────────────────────────────────────
	Samma omräkning som BuildKit.tomtkoord, men utan att kräva
	anläggningens bas: världen byggs alltid med tomtens origo i (0, 0,
	djup) och norr = −Z. Tjänsten ska kunna svara även innan modellen
	hittats. ]]
local TOMTDJUP = 170

local function tomt(p: Vector3): (number, number)
	return p.X / M, TOMTDJUP - p.Z / M
end

local function avstandM(a: Vector3, b: Vector3): number
	return (Vector3.new(a.X, 0, a.Z) - Vector3.new(b.X, 0, b.Z)).Magnitude / M
end

--[[ En rektangel i tomtkoordinater. `iRekt` används både för boxen och
	för målzonen, så det finns en enda regel för "är hon där". ]]
export type Rekt = { x: number, y: number, w: number, h: number }

function LedService.iRekt(p: Vector3, r: Rekt): boolean
	local x, y = tomt(p)
	return x >= r.x and x <= r.x + r.w and y >= r.y and y <= r.y + r.h
end

--[[ ── Tillståndet ─────────────────────────────────────────────────── ]]

function LedService.aktiv(player: Player): Model?
	local l = ledd[player]
	return l and l.modell or nil
end

function LedService.lage(player: Player): Led?
	return ledd[player]
end

--[[ Har hästen fysiskt lämnat sin box? Sätts av loopen när hon faktiskt
	är utanför, och nollställs aldrig — steget ska inte kunna ångras av
	att hon råkar backa tillbaka en halvmeter. ]]
function LedService.harLamnatBox(player: Player): boolean
	local l = ledd[player]
	if l ~= nil and l.lamnatBox then return true end
	return harUppnatt(player, "lamnatBox")
end

function LedService.harNattMal(player: Player): boolean
	local l = ledd[player]
	if l ~= nil and l.malNatt then return true end
	return harUppnatt(player, "malNatt")
end

--[[ Målzonen. Sätts av den som äger gameplayet (GameplayService) så att
	tjänsten inte behöver känna till vare sig ridhuset eller faserna. ]]
local malzon: Rekt? = nil
function LedService.satMalzon(r: Rekt?)
	malzon = r
end
function LedService.malzon(): Rekt?
	return malzon
end

--[[ ── Att börja leda ───────────────────────────────────────────────
	Varje nej har en egen nyckel. Ett enda "gick inte" hade gjort de
	negativa fallen omöjliga att skilja åt i ett test. ]]
function LedService.borja(player: Player, modell: Model?, ratt: Model?): (boolean, string?)
	--[[ `IsA` i stället för `typeof`: bänkens stubbinstanser rapporterar
		"table", och en typeof-vakt hade gjort tjänsten omöjlig att mäta
		utan att säga något om produktionen. Att modellen svarar på `IsA`
		och säger sig vara en Model är det som faktiskt betyder något. ]]
	if type(modell) ~= "table" and typeof(modell) ~= "Instance" then
		return false, "led.ingen_hast"
	end
	local kanIsA = modell ~= nil and (modell :: any).IsA ~= nil
	if not kanIsA or not (modell :: any):IsA("Model") then
		return false, "led.ingen_hast"
	end
	--[[ RÄTT HÄST. Att leda någon annans häst är inte en teknikalitet:
		hela skötselkanonen bygger på att man arbetar med SIN häst. ]]
	if ratt ~= nil and modell ~= ratt then
		return false, "led.fel_hast"
	end
	local karaktar = player.Character
	local rot = karaktar and karaktar:FindFirstChild("HumanoidRootPart")
	if not (rot and rot:IsA("BasePart")) then
		return false, "led.ingen_karaktar"
	end
	local hum = karaktar and karaktar:FindFirstChildOfClass("Humanoid")
	--[[ Sitter man upp leder man inte — då rider man. ]]
	if hum and hum.Sit then
		return false, "led.rider"
	end
	local pivot = modell.PrimaryPart or modell:FindFirstChildWhichIsA("BasePart")
	if not pivot then
		return false, "led.hast_saknar_kropp"
	end
	if avstandM(rot.Position, pivot.Position) > RACKVIDD then
		return false, "led.for_langt"
	end
	if ledd[player] then
		return false, "led.leder_redan"
	end
	--[[ Två spelare kan inte leda samma häst. ]]
	for annan, l in pairs(ledd) do
		if l.modell == modell then
			return false, "led.upptagen"
		end
	end
	local bx, by = tomt(pivot.Position)

	--[[ ── BOXDÖRREN SOM WAYPOINT ──────────────────────────────────────

		Mätt i Studio: hästen kilade sig mot `Boxfront MB 5` och norra
		skiljeväggen med `MoveDirection = 0`. Hon är 1,85 m lång och
		öppningen 1,20 m bred, och `MoveTo` styr RAKT mot målet — från ett
		hörn i facket går den linjen genom panelen.

		Spårföljningen räcker inte här: brödsmulorna ligger rätt, men hon
		måste RIKTA UPP kroppen mot öppningen innan hon går igenom. Därför
		två delmål — först en punkt rakt innanför dörren, sedan en rakt
		utanför. Två punkter, ingen vägsökning.

		Dörren letas upp EN gång, vid start, och bara om hon faktiskt står
		i en box. Leds hon på öppen yta finns ingen dörr och hela grenen
		hoppas över.

		PUNKTEN ÄR ÖPPNINGENS, INTE BLADETS. Ett öppet blad har svängt 85
		grader ut i gången: mätt i Studio låg dörrens `Position` då 1,7 m
		fel, och hästen fick ett delmål mitt i gången i stället för i luckan.
		`DorrService` skriver det stängda läget som `UBRFOppningsmitt` vid
		riggningen, och det är hålet i fronten. ]]
	local function oppningsmitt(d: BasePart): Vector3
		local m = d:GetAttribute("UBRFOppningsmitt")
		return if typeof(m) == "Vector3" then m else d.Position
	end
	local narmasteDorr, narmast = nil, 3.2 * M
	local anlaggning = workspace:FindFirstChild("Anläggning")
	if anlaggning then
		for _, d in ipairs(anlaggning:GetDescendants()) do
			if d:IsA("BasePart") and d:GetAttribute("UBRFBoxdorr") == true then
				local avst = (oppningsmitt(d) - pivot.Position).Magnitude
				if avst < narmast then narmasteDorr, narmast = d, avst end
			end
		end
	end
	local dorrMitt: Vector3? = nil
	local dorrUt: Vector3? = nil
	if narmasteDorr then
		dorrMitt = oppningsmitt(narmasteDorr)
		--[[ `Langs` säger vilken axel fronten löper i; `Utat` åt vilket
			håll gången ligger. Båda sätts av `Anlaggningen`. ]]
		local langs = narmasteDorr:GetAttribute("Langs")
		local utat = tonumber(narmasteDorr:GetAttribute("Utat")) or 1
		dorrUt = if langs == "Z"
			then Vector3.new(utat, 0, 0)
			else Vector3.new(0, 0, utat)
	end

	--[[ ══ STÅR HON ÖVER HUVUD TAGET I EN BOX? ═════════════════════════

		Stycket ovanför säger att dörren letas upp "bara om hon faktiskt
		står i en box". Det var en avsikt, inte en kontroll: enda villkoret
		var att NÅGON boxdörr låg inom 3,2 m. I en stallgång kantad av
		boxar är det alltid sant, och därför fick en häst som redan stod i
		gången ett delmål INNE i närmaste främmande box.

		Mätt i runtime-acceptansen: hon stod i gång B på (499,9 · 265,6),
		drygt 4,8 m ur sin egen box, med `lamnatBox = false`, `dorrsteg = 2`
		och kursen (−0,59 · −0,81) rakt in i `Boxfront MB 7`. Gången är
		7,75 studs och hennes kropp 5,55 — på snedden kilar hon fast,
		`MoveDirection` går till 0, planeraren gör slut på sina omplaneringar
		och kopplet släpper med `led.fastnat`.

		`Utat` pekar ut mot gången. Ligger hon på den sidan av öppningen är
		hon redan ute, och då finns ingen box att ta sig ur: dörrgrenen
		hoppas över och `lamnatBox` är sann från början. Exakt i luckan
		(punkt 0) räknas som inne, så den som står mitt i öppningen får
		behålla sin utgång. ]]
	local iBox = false
	if dorrMitt and dorrUt then
		iBox = (pivot.Position - dorrMitt):Dot(dorrUt) <= 0
	end
	if not iBox then
		narmasteDorr, dorrMitt, dorrUt = nil, nil, nil
	end

	local hastHum = (modell :: any):FindFirstChildOfClass("Humanoid")
	local tidigareFart = hastHum and hastHum.WalkSpeed or 0
	if hastHum then
		hastHum.WalkSpeed = skrittfart()
	end

	--[[ NÄTVERKSÄGARSKAPET MÅSTE TILL SERVERN MEDAN HON LEDS.

		Mätt i Studio: en oriden häst intill en spelare ägs AUTOMATISKT av
		den spelaren — Roblox delar ut oankrade delar till närmaste klient.
		Servern räknade alltså ut en kurs som klienten omedelbart skrev
		över, och ordern att gå nådde aldrig fram: `MoveDirection = 0` och
		noll förflyttning, med spelaren stående bredvid.

		Ledningen är serverauktoritär, så simuleringen ska ligga på servern
		medan den pågår. Ryttarens ägarskap är en annan sak och rörs inte:
		`HorseService` ger det vid uppsittning, och sitter man upp mitt i
		ledningen släpper ledningen först. Läget före sparas och lämnas
		tillbaka — annars hade en ledd häst blivit permanent serversimulerad
		och ridningen fått tillbaka den halvsekunds fördröjning som
		ägarskapet finns för att slippa. ]]
	local tidigareAgare: Player? = nil
	local tidigareAuto = false
	if pivot:IsA("BasePart") then
		pcall(function()
			tidigareAuto = pivot:GetNetworkOwnershipAuto()
			if not tidigareAuto then tidigareAgare = pivot:GetNetworkOwner() end
			pivot:SetNetworkOwner(nil)
		end)
	end
	--[[ MAN SPRINGER INTE MED EN HÄST I HANDEN.

		Roblox default är 16 studs/s — 5,3 m/s, alltså språng. En skrittande
		häst går 1,45 m/s. Mätt i Studio: spelaren drog ifrån 22 m på fyra
		sekunder, kopplet löste ut som det ska, och ledningen blev därmed
		oanvändbar.

		Spelaren går därför i ledningstakt så länge hon leder, och får sin
		egen fart tillbaka när hon släpper. Marginalen gör att hon kan gå
		före utan att hästen halkar efter. ]]
	local spelarHum2 = karaktar and karaktar:FindFirstChildOfClass("Humanoid")
	local tidigareSpelarfart = spelarHum2 and spelarHum2.WalkSpeed or 16
	if spelarHum2 then
		spelarHum2.WalkSpeed = skrittfart() * 1.15
	end
	ledd[player] = {
		tidigareFart = tidigareFart,
		tidigareSpelarfart = tidigareSpelarfart,
		modell = modell,
		hastId = tostring(modell:GetAttribute("HorseId") or ""),
		gar = false,
		--[[ Står hon redan i gången finns ingen box kvar att lämna. Då är
			flaggan sann direkt, och `boxX`/`boxY` nedan konsulteras aldrig
			— de gäller bara så länge hon faktiskt är kvar i facket. ]]
		lamnatBox = not iBox,
		malNatt = false,
		boxX = bx, boxY = by,
		dorrMitt = dorrMitt,
		tidigareAgare = tidigareAgare,
		tidigareAuto = tidigareAuto,
		spar = {},
		dorr = narmasteDorr,
		dorrUt = dorrUt,
		dorrsteg = 1,
		navVag = {}, navIx = 1, navPlaner = 0, navSenast = -NAV_OMPLAN_PAUS, planerar = false, tid = 0,
		stillaSedan = 0, badGa = false, ankare = pivot.Position,
	}
	LedService._sync(player)
	return true, nil
end

--[[ Att sluta leda. `skal` är nil när spelaren själv släpper och en
	nyckel när kopplet, döden eller uppsittningen gjorde det. ]]
function LedService.slapp(player: Player, skal: string?): (boolean, string?)
	local l = ledd[player]
	if not l then
		return false, "led.leder_inte"
	end
	--[[ Hästen ska STÅ, inte fortsätta mot sitt sista mål. Utan den här
		raden gick hon vidare några meter efter att kopplet släppt. ]]
	local hum = l.modell:FindFirstChildOfClass("Humanoid")
	if hum then
		hum:Move(Vector3.zero, false)
		--[[ Farten tillbaka som den var. Lämnas den kvar står en släppt
			häst och skrittar iväg av sig själv nästa gång något rör
			hennes Humanoid. ]]
		hum.WalkSpeed = l.tidigareFart
	end
	--[[ Ägarskapet tillbaka som det var. ]]
	local pivot = l.modell.PrimaryPart
	if pivot then
		pcall(function()
			if l.tidigareAuto then
				pivot:SetNetworkOwnershipAuto()
			else
				pivot:SetNetworkOwner(l.tidigareAgare)
			end
		end)
	end

	--[[ Spelarens egen fart tillbaka. Utan den går hon kvar i
		ledningstakt resten av passet. ]]
	local karaktar2 = player.Character
	local spelarHum3 = karaktar2 and karaktar2:FindFirstChildOfClass("Humanoid")
	if spelarHum3 then
		spelarHum3.WalkSpeed = l.tidigareSpelarfart
	end
	ledd[player] = nil
	LedService._sync(player, skal)
	return true, skal
end

function LedService._sync(player: Player, skal: string?)
	local ev = Net.get("LedSync")
	local l = ledd[player]
	ev:FireClient(player, {
		leder = l ~= nil,
		hastId = l and l.hastId or nil,
		lamnatBox = l ~= nil and l.lamnatBox or false,
		malNatt = l ~= nil and l.malNatt or false,
		skal = skal,
	})
end

--[[ ── Planeraren ──────────────────────────────────────────────────
	Ett anrop, en väg, och sedan går hon på den med sin egen Humanoid.
	Ingen väg per bildruta: `NAV_OMPLAN_PAUS` och `NAV_MAX_PLANER` finns
	för att en blockerad häst inte ska mala servern. ]]
local function agentparametrar(pivot: BasePart)
	return {
		AgentRadius = pivot.Size.X * NAV_RADIE_FAKTOR,
		AgentHeight = 2.01 + pivot.Size.Y,
		AgentCanJump = false,
		AgentCanClimb = false,
		WaypointSpacing = NAV_VAGPUNKT,
	}
end

--[[ Tiden räknas i BILDRUTOR, inte i väggklocka. `os.clock` gjorde
	omplaneringspausen omätbar: en spec kör tusen bildrutor på någon
	millisekund, så pausen slog alltid till och taket kunde aldrig nås —
	precis den gren som ska hindra en blockerad häst från att mala servern
	var alltså den enda som inte gick att pröva. ]]
local function planera(l: Led, pivot: BasePart, mal: Vector3)
	--[[ VÄGBERÄKNINGEN FÅR INTE LIGGA I BILDRUTAN.

		Mätt på plats: `ComputeAsync` tar 94 ms för boxutgången och 100 ms
		för hela den kanoniska rutten. Anropet YIELDAR, och `steg` körs ur
		Heartbeat — en beräkning mitt i loopen sköt alltså upp resten av de
		ledda hästarna den bildrutan OCH lät nästa Heartbeat starta ett nytt
		`steg` medan det förra stod och väntade. Två samtidiga steg som
		skriver på samma tillstånd är inget man felsöker i efterhand.

		Nu läggs beräkningen i en egen tråd och bildrutan går vidare. En
		flagga håller EN beräkning i luften per häst: utan den hade
		omplaneringspausen kunnat kringgås av en beräkning som ännu inte
		svarat. Hon fortsätter under tiden på spåret — det är sämre än en
		väg, men det är att röra sig. ]]
	if l.planerar then return end
	if l.tid - l.navSenast < NAV_OMPLAN_PAUS then return end
	if l.navPlaner >= NAV_MAX_PLANER then return end
	l.navSenast = l.tid
	l.navPlaner += 1
	l.planerar = true

	local param = agentparametrar(pivot)
	local start = pivot.Position
	task.spawn(function()
		local vag = PathfindingService:CreatePath(param)
		local ok = pcall(function()
			vag:ComputeAsync(start, mal)
		end)
		l.planerar = false
		if not ok or vag.Status ~= Enum.PathStatus.Success then
			table.clear(l.navVag)
			l.navIx = 1
			return
		end
		table.clear(l.navVag)
		for _, w in ipairs(vag:GetWaypoints()) do
			table.insert(l.navVag, w.Position)
		end
		--[[ Första vägpunkten ligger i hästens egen fot; att gå dit är att
			stå still. ]]
		l.navIx = math.min(2, #l.navVag)
	end)
end

local function navigerar(l: Led): boolean
	return #l.navVag > 0 and l.navIx <= #l.navVag
end

--[[ ETT ENDA STÄLLE VRIDER OCH DRIVER HENNE. Allt nedanför väljer bara
	MÅLPUNKTEN. Förut gick `MoveTo` från tre ställen, och det är därför
	kroppens riktning aldrig hade någon ägare alls.

	`Humanoid:Move` med hennes EGEN framåtvektor, inte `MoveTo` mot punkten:
	`MoveTo` skjuter kroppen rakt mot målet oavsett hur den står, och en
	häst som går i sidled in i en 1,20 m dörr fastnar. Nu går hon dit hon
	pekar, och pekar hon fel vänder hon först. ]]
local function styrMot(pivot: BasePart, hum: Humanoid, mal: Vector3,
	onskadFartMS: number, dt: number): boolean
	local d = Vector3.new(mal.X - pivot.Position.X, 0, mal.Z - pivot.Position.Z)
	if d.Magnitude < 0.05 then
		hum:Move(Vector3.zero, false)
		return false
	end
	local fartMS = pivot.AssemblyLinearVelocity.Magnitude / M
	local kvar = vridMot(pivot, math.atan2(d.X, d.Z), fartMS, dt)
	--[[ Är kursfelet stort VÄNDER HON FÖRST. Att gå framåt på tvären är
		precis det som kilade fast henne i boxen. ]]
	local andel = math.clamp((VAND_STOPP - kvar) / (VAND_STOPP - VAND_FULL), 0, 1)
	hum.WalkSpeed = onskadFartMS * andel * M
	if andel <= 0 then
		hum:Move(Vector3.zero, false)
		return false
	end
	hum:Move(framat(kurs(pivot)), false)
	return true
end

--[[ ── Följandet ────────────────────────────────────────────────────
	Ett steg per bildruta. Allt som händer här är att hästen får ett mål
	och att tre tillstånd uppdateras. ]]
local function steg(_dt: number)
	for player, l in pairs(ledd) do
		local karaktar = player.Character
		local rot = karaktar and karaktar:FindFirstChild("HumanoidRootPart")
		local hum = l.modell:FindFirstChildOfClass("Humanoid")
		local pivot = l.modell.PrimaryPart

		--[[ Försvann något — karaktären dog, hästen togs bort — släpper
			kopplet i stället för att loopen ska räkna på nil. ]]
		if not (rot and rot:IsA("BasePart")) or not hum or not pivot
			or not l.modell.Parent then
			LedService.slapp(player, "led.tappad")
			continue
		end

		--[[ Sitter spelaren upp mitt i ledningen är hon ryttare nu. ]]
		local spelarHum = karaktar and karaktar:FindFirstChildOfClass("Humanoid")
		if spelarHum and spelarHum.Sit then
			LedService.slapp(player, "led.rider")
			continue
		end

		local avst = avstandM(rot.Position, pivot.Position)
		if avst > KOPPEL then
			LedService.slapp(player, "led.tappade_bort")
			continue
		end

		--[[ Har hon lämnat boxen? Mäts på FAKTISK position, inte på att
			spelaren tryckt på något. ]]
		if not l.lamnatBox then
			local x, y = tomt(pivot.Position)
			if math.sqrt((x - l.boxX) ^ 2 + (y - l.boxY) ^ 2) > 2.5 then
				l.lamnatBox = true
				noteraUppnatt(player, l.hastId, "lamnatBox")
				LedService._sync(player)
			end
		end
		if malzon and not l.malNatt and LedService.iRekt(pivot.Position, malzon) then
			l.malNatt = true
			noteraUppnatt(player, l.hastId, "malNatt")
			LedService._sync(player)
		end

		--[[ HÄSTEN GÅR I SPELARENS SPÅR, inte mot en punkt bakom henne.

			En rak linje till en punkt bakom spelaren fungerar på öppen
			yta men inte genom en dörr: mätt i Studio kilade sig hästen
			fast mot `Boxfront MB 5` och norra skiljeväggen med
			`MoveDirection = 0`, för att linjen gick genom väggen.
			Boxdörren är 1,20 m och hästen 1,85 m lång — hon måste rikta
			upp sig mot öppningen, inte skära hörnet.

			Spåret löser det utan vägsökning: spelaren gick ju själv genom
			dörren. Vi sparar hennes senaste lägen och skickar hästen till
			den äldsta brödsmulan som ligger minst FOLJ_BAKOM bort. Då
			följer hon vägen som fungerade i stället för fågelvägen.

			Ringbufferten är kort med flit — den ska bära genom en dörr,
			inte minnas en rundtur. ]]
		local spar = l.spar
		local senaste = spar[#spar]
		--[[ ETT HOPP ÄR INGEN VÄG. Flyttas spelaren långt på en bildruta —
			respawn, en spec som ställer henne någon annanstans — är spåret
			dit inte gångbart, och hästen skulle skickas till en punkt hon
			aldrig kan nå. Då kastas spåret. ]]
		if senaste and (senaste - rot.Position).Magnitude > 3.0 * M then
			table.clear(spar)
			senaste = nil
		end
		if not senaste or (senaste - rot.Position).Magnitude > 0.6 * M then
			table.insert(spar, rot.Position)
			if #spar > 40 then table.remove(spar, 1) end
		end
		--[[ Smulor längre bort än kopplet hör inte hit heller. ]]
		while #spar > 0 and avstandM(spar[1], rot.Position) > KOPPEL do
			table.remove(spar, 1)
		end
		--[[ EN SMULA HÄSTEN STÅR PÅ ÄR FÖRBRUKAD, och det gäller ÄVEN NÄR
			HON STÅR STILL.

			Mätt i Studio, mitt i stallgången: gallringen låg förut inne i
			grenen som bara körs medan hon GÅR. Hon stannade därför en gång
			med den äldsta smulan under sig, och då låg målpunkten inom
			dödzonen — vilket gjorde att hon stod kvar, vilket gjorde att
			smulan aldrig gallrades. Spelaren 6,1 m bort, hästen blickstilla,
			och ingenting i tillståndet såg trasigt ut. En lås-i-sig-själv. ]]
		--[[ RADIEN ÄR START_R, INTE ETT MINDRE TAL, och det är hela poängen.

			Gallringen låg på 1,2 m medan hysteresen börjar gå först vid 1,8 m.
			En smula som hamnade i bandet däremellan var varken förbrukad eller
			värd att gå till: mätt i Studio, söder om boxraderna, stod hästen
			stilla 1,21 m från sin egen brödsmula med spelaren 6,30 m bort och
			rörde ingenting alls. Samma sorts glapp som dörrens delmål hade.

			En punkt hon inte tänker gå till får alltså inte vara hennes mål. ]]
		while #spar > 1 and avstandM(pivot.Position, spar[1]) < START_R do
			table.remove(spar, 1)
		end

		--[[ MÅLPUNKTEN FÅR ALDRIG LIGGA I DÖDZONEN.

			Smulan ska ligga minst FOLJ_BAKOM bakom spelaren — det är
			följavståndet — OCH minst START_R från hästen själv. Det andra
			villkoret är rättelsen: en smula närmare än så är en punkt hon
			aldrig tänker gå till, och att sikta på den är att stå still.
			Mätt i Studio, söder om boxraderna: hästen stod 1,21 m från sin
			egen smula med spelaren 6,30 m bort, rörde ingenting, och inget
			i tillståndet såg trasigt ut. Duger ingen smula tas punkten
			bakom spelaren i stället. ]]
		local bakom = rot.Position - rot.CFrame.LookVector * (FOLJ_BAKOM * M)
		for i = 1, #spar do
			if avstandM(spar[i], rot.Position) >= FOLJ_BAKOM
				and avstandM(spar[i], pivot.Position) >= START_R then
				bakom = spar[i]
				break
			end
		end

		--[[ Så länge hon inte lämnat boxen går dörren före spåret. Steg 1
			ställer henne rakt innanför öppningen, steg 2 tar henne ut. ]]
		local viaDorr = false
		if not l.lamnatBox and l.dorr and l.dorrMitt and l.dorrUt and l.dorr.Parent then
			viaDorr = true
			local ut1 = l.dorrMitt - l.dorrUt * (1.3 * M)
			local ut2 = l.dorrMitt + l.dorrUt * (2.2 * M)
			--[[ DELMÅLET SKA NÅS, OCH DET KRÄVER EN RADIE UTANFÖR DÖDZONEN.
				Radien stod på 0,9 m medan hysteresen börjar gå först vid 1,8 m:
				mätt i Studio hamnade hästen 0,98 m från punkten, alltså i
				glappet mellan "för nära för att gå" och "för långt för att
				vara framme", och stod där. Radien måste vara större än
				START_R, annars finns bandet kvar. ]]
			if l.dorrsteg == 1 then
				if avstandM(pivot.Position, ut1) < START_R + 0.4 then
					l.dorrsteg = 2
				else
					bakom = ut1
				end
			end
			if l.dorrsteg == 2 then bakom = ut2 end
		end
		local tillMal = avstandM(pivot.Position, bakom)

		--[[ Hon får skynda på inom SKRITTENS eget band när hon hamnat
			efter. Bandet kommer ur `Gaits`; hon börjar aldrig trava.

			FARTEN SKRIVS INTE HÄR. Den lämnas till `styrMot`, som sänker den
			när kursfelet är stort: en häst som behöver vända ska vända, inte
			gå framåt på tvären. Förut satt raden här bakom `WalkSpeed > 0`,
			som aldrig kunde bli sann igen om något nollat farten. ]]
		local gang = Gaits.DATA and Gaits.DATA.walk
		local lag = math.clamp((avst - FOLJ_BAKOM) / 4.0, 0, 1)
		local onskadFart = ((gang and gang.norm) or 1.45)
			+ lag * (((gang and gang.max) or 2.0) - ((gang and gang.norm) or 1.45))

		--[[ ── KOMMER HON FRAMÅT? ──────────────────────────────────────

			MÄTT PÅ KROPPEN, inte på ett avstånd som krymper. Villkoret var
			förut "minskar inte avståndet till målet", och det ljuger på två
			sätt: målpunkten rör sig med spelaren, och under en vändning på
			stället krymper inget avstånd fast hon gör precis rätt.

			Nu räknas hon som stillastående bara när hon FICK ORDER ATT GÅ
			och ändå inte KOM NÅGONSTANS. Står hon i dödzonen, eller vänder
			sig innan hon går, är det inte att ha fastnat.

			MÄTT SOM FÖRFLYTTNING, inte som hastighet. Hastigheten ljuger:
			en häst som ankrats fast — ett prov där hon bevisligen inte kan
			röra sig ur fläcken — rapporterade 1,59 studs/s, och stillamåttet
			nollställdes varje bildruta. Ett ankare i världen och ett krav på
			att hon faktiskt LÄMNAR det kan inte ljuga på samma sätt. ]]
		l.tid += _dt
		if l.badGa then
			if avstandM(pivot.Position, l.ankare) > NAV_ANKARE then
				l.ankare = pivot.Position
				l.stillaSedan = 0
			else
				l.stillaSedan += _dt
			end
		else
			l.ankare = pivot.Position
			l.stillaSedan = 0
		end
		l.badGa = false
		local trangt = not l.lamnatBox and l.dorr ~= nil
		local behoverVag = (trangt or l.stillaSedan > NAV_STILLA) and tillMal > STOPP_R

		--[[ EN VÄG SOM INTE BÄR SKA KASTAS.

			Mätt i Studio, vid södra änden av MA-raden: hon låg på en
			vägpunkt hon inte kunde nå, kilad mot fronthörnet, med full
			skrittfart och noll hastighet. Stillaståendet mättes bara när
			hon INTE navigerade, så ingenting planerade om — hon stod i 24
			sekunder och tillståndet såg friskt ut. En väg som inte bär
			måste kunna överges. ]]
		if l.stillaSedan > NAV_STILLA and navigerar(l) then
			table.clear(l.navVag)
			l.navIx = 1
		end

		if behoverVag and not navigerar(l) then
			planera(l, pivot, Vector3.new(bakom.X, pivot.Position.Y, bakom.Z))
		end

		--[[ FASTNAT PÅ RIKTIGT. Planeraren har gett upp och hon rör sig
			fortfarande inte: då ska kopplet SLÄPPA med ett eget skäl i
			stället för att hon ska stå och mala. Spelaren får veta det och
			kan leda henne en annan väg. ]]
		if l.stillaSedan > NAV_FASTNAT and l.navPlaner >= NAV_MAX_PLANER then
			--[[ VARFÖR hon inte kommer ut avgör vad spelaren ska få höra.

				"Prova en annan väg" är rätt svar när hon kilat fast i
				gången — men det är fel svar i det vanligaste fallet av
				alla: hon står kvar i sin egen box och bladet stänger
				fortfarande öppningen. Då finns ingen annan väg. Då ska
				dörren öppnas, och det ska sägas rakt ut.

				Villkoret läser bladets EGEN kollision, inte ett register:
				`DorrService.satt` skriver `CanCollide = not vidoppen`, så
				`CanCollide` ÄR det som spärrar öppningen. Att fråga
				geometrin i stället för en tabell gör att svaret inte kan
				glida isär från det hästen faktiskt går emot. ]]
			local stangdBoxdorr = not l.lamnatBox
				and l.dorr ~= nil
				and (l.dorr :: BasePart).Parent ~= nil
				and (l.dorr :: BasePart).CanCollide
			LedService.slapp(player,
				if stangdBoxdorr then "led.stangd_boxdorr" else "led.fastnat")
			continue
		end

		--[[ ── PÅ VÄG ────────────────────────────────────────────────── ]]
		if navigerar(l) then
			local wp = l.navVag[l.navIx]
			if (Vector3.new(wp.X, 0, wp.Z) - Vector3.new(pivot.Position.X, 0, pivot.Position.Z)).Magnitude
				< NAV_NA_VAGPUNKT then
				l.navIx += 1
				l.stillaSedan = 0
			end
			if navigerar(l) then
				local w = l.navVag[l.navIx]
				l.gar = true
				l.badGa = styrMot(pivot, hum, Vector3.new(w.X, pivot.Position.Y, w.Z),
					onskadFart, _dt)
			else
				--[[ Vägen är slut. Tillbaka till spårföljningen; blev hon
					ändå inte fri märks det som stillastående igen. ]]
				table.clear(l.navVag)
				l.navIx = 1
				l.stillaSedan = 0
			end
			continue
		end

		--[[ Fri igen: nollställ planeringsräknaren så nästa trånga läge
			får sina egna försök. ]]
		if l.lamnatBox and l.stillaSedan == 0 then l.navPlaner = 0 end

		--[[ HYSTERESEN GÄLLER FÖLJANDET.

			Dödzonen finns för att hon inte ska pendla kring en punkt som
			rör sig med spelaren. ]]
		if l.gar then
			if tillMal < STOPP_R then
				l.gar = false
				hum:Move(Vector3.zero, false)
			else
				l.badGa = styrMot(pivot, hum, Vector3.new(bakom.X, pivot.Position.Y, bakom.Z),
					onskadFart, _dt)
			end
		else
			if tillMal > START_R then
				l.gar = true
				l.badGa = styrMot(pivot, hum, Vector3.new(bakom.X, pivot.Position.Y, bakom.Z),
					onskadFart, _dt)
			end
		end
	end
end

function LedService.start()
	Net.get("LedSync")

	Net.get("LedBorja").OnServerInvoke = function(player, modell)
		local hak = hakar.ratt
		local ratt = hak and hak(player, nil :: any) or nil
		return LedService.borja(player, modell, ratt)
	end
	Net.get("LedSlapp").OnServerInvoke = function(player)
		return LedService.slapp(player)
	end

	Players.PlayerRemoving:Connect(function(player)
		if ledd[player] then LedService.slapp(player, "led.tappad") end
		--[[ Bokföringen är sessionsbunden och hör till spelaren som gick.
			Lämnas den kvar läcker den, och nästa spelare på samma
			Player-objekt hade ärvt någon annans framsteg. ]]
		uppnatt[player] = nil
	end)

	RunService.Heartbeat:Connect(steg)
	print("[Led] Ledningen igång")
end

--[[ Den som äger tilldelningen (GameplayService) lämnar en krok som
	svarar VILKEN häst spelaren får leda. Tjänsten slår inte upp det
	själv: då hade den behövt känna till skötseln. ]]
function LedService.satRattHastKrok(f: ((Player, Model?) -> Model?)?)
	hakar.ratt = f :: any
end

--[[ För specar: kör EN bildruta explicit.

	Heartbeat tickar inte i en spec, och att låta testet sätta flaggorna
	själv hade gjort mätningen värdelös — då prövar den sin egen
	uppfattning i stället för tjänstens. Den här sömmen kör exakt samma
	`steg` som produktionen, så det som mäts är det som körs. ]]
function LedService._steg(dt: number?)
	steg(dt or (1 / 60))
end

--[[ För specar: nollställ utan att röra spelare. ]]
function LedService._glomForProv()
	for p in pairs(ledd) do ledd[p] = nil end
	for p in pairs(uppnatt) do uppnatt[p] = nil end
	malzon = nil
end

return LedService
