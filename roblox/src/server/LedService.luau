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
local Aktor = require(ReplicatedStorage.HorseCore.Aktor)
--[[ #259 Gate 1A. `LedBorja` var den ena av de tva konkreta
	vagarna i #258 P1-2: ett anrop med `nil` nekas pa forsta raden i
	`borjaInre` och skrev anda en `warn` genom `logg`. Grinden ligger
	nu FORE bada. ]]
local Skopa = require(script.Parent.Skopa)

local LedService = {}

local M = 3                    -- studs per meter, som BuildKit.M

--[[ Måtten är spelkänsla, inte mätningar av verkligheten, och står därför
	här och inte i den delade världsdatan. ]]
local RACKVIDD   = 4.0         -- m: så nära måste man stå för att få börja leda
local FOLJ_BAKOM = 2.4         -- m: hästens målpunkt bakom spelaren
local STOPP_R    = 1.0         -- m: innanför detta står hon still
local START_R    = 1.8         -- m: utanför detta går hon igen (hysteres)
local KOPPEL     = 9.0         -- m: längre bort och kopplet släpper

--[[ ══ SAKERHETSKOPPLET: NORMAL / CATCH-UP / RELEASE (#182 del 2) ═══

	Kopplet slapptes forut pa AVSTAND ENSAMT. En enda bildruta dar
	fysiken kastade henne — en teleport, en respawn, en kollision mot en
	dorrkarm — rackte darfor for att tappa hasten, fast ingenting
	verkligt hant.

	Tre lagen i stallet, och slappet kraver BADE avstand OCH tid:

	  NORMAL     under CATCHUP_R — hon foljer i lugn takt
	  CATCH-UP   mellan CATCHUP_R och KOPPEL — hon far mer fart for att
	             hinna ifatt, men kopplet haller
	  RELEASE    over KOPPEL i mer an KOPPEL_TID sekunder i strack

	Tiden ar det som gor skillnad pa «spelaren sprang ifran henne» och
	«en bildruta ljog». Ett fysikhack ska inte kunna slita kopplet. ]]
local CATCHUP_R  = 5.0         -- m: harifran far hon mer fart for att hinna ifatt
local KOPPEL_TID = 0.75        -- s: sa lange maste hon vara for langt bort

--[[ HUR LANGT MALPUNKTEN FAR AVVIKA FRAN SPELAREN (#182 del 2, villkor
	ur arkitektreviewen). Spelaren ar den SEMANTISKA destinationen; att
	malet far flyttas till en brodsmula ar en routing-detalj som finns
	for att hasten ska runda dorrkarmen i stallet for att ga in i den.

	Utan tak kunde en gammal smula ligga var som helst i ringbufferten
	och dra henne at ett hall spelaren inte ar. Taket gor avvikelsen
	till just en detalj: den kan kroka vagen, aldrig byta mal.

	Satt strax under kopplets slapp-avstand — ett mal som ligger langre
	bort an kopplet racker ar per definition orimligt. ]]
local MAL_AVVIK  = 7.0         -- m: sa langt fran spelaren far malpunkten ligga
local SPAR_TAK   = 40          -- smulor: minnestaket, se noten vid inläggningen

--[[ Hur mycket snabbare spelaren gar an hasten SKRITTAR. Marginalen
	finns for att hon ska kunna ga fore utan att kopplet strammar — men
	den maste ligga hos HASTENS tak ocksa, annars ar den en sparr.
	Se noten vid fartrampen i `steg`. ]]
local LEDNINGSTAKT = 1.15


--[[ ══ FOLJNINGEN AR CONSTRAINTS, INTE EN LOOP (#182 del 2) ═════════

	Arkitekturkontraktet i #235 FAS 4 ar bindande: `AlignPosition` och
	`AlignOrientation` mot serverskapade fastpunkter, `RigidityEnabled`
	av, konservativa varden, och INGEN parallell reglering — ingen
	`VectorForce`, ingen `RopeConstraint` som drar, ingen loopad
	`PivotTo` och ingen direkt CFrame-skrivning.

	Forut gjorde `styrMot` tva forbjudna saker i samma andetag: den
	skrev `pivot.CFrame` direkt for att vrida henne, och den korde
	`Humanoid:Move` varje bildruta for att driva henne. Bada ar
	loopreglering, och bada slogs mot Roblox egen fysik.

	VARDENA ar avsiktligt trubbiga. De ar tuningvarden, inte kanon, och
	ska stallas in mot kansla i Studio — inte raknas fram har. ]]
local ALIGN_KRAFT   = 24000    -- N: rackligt for en hast, inte for en bil
local ALIGN_SVAR    = 12       -- Responsiveness: mjukt, inte ryckigt
local ALIGN_VRID    = 8000     -- Nm: vridmomentet for kursen
local ALIGN_VRIDSVAR = 8       -- Responsiveness for kursen


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
--[[ ══ RADIEN MÅSTE UTESLUTA MÄNNISKODÖRRARNA (#190) ═══════════════════

	Halva kroppsbredden ensam räcker inte, och det är #190:s sidofynd.
	Mätt i Studio på `a1826fc`, med binärsökning på `AgentRadius`:

	  klubbdelens branddörrar, 0,88 m och 1,06 m     bär radie <= 1,000
	  hela sträckan klubbdelen -> gång B             bär radie <= 1,000
	  kanoniska hästrutten box MB 5 -> ridbanan      bär radie <= 1,521
	  gång A -> W-passagen -> hästgången             bär radie <= 1,581

	Med enbart halva bredden (0,930) ligger agenten UNDER 1,000, och
	planeraren får därmed lov att träda en häst genom klubbdelens
	branddörrar — med 0,070 studs, alltså 2,3 cm, till godo. Klubbdelen är
	uppehållsrum, pentry, sadelkammare, teorisal och WC, avskild från
	stallgången med en branddörr (`references/buildings/stall/KORT.md`,
	`stall-entre-12.jpg`). Den är en människoväg. Hästen leds inomhus via
	hästgången till ridhuset, inte genom klubbrummet.

	Det här är alltså inte att göra hästen smalare eller bredare än hon är:
	det är att sluta påstå att en korridor exakt lika bred som hennes kropp
	är en väg hon kan ledas genom. Hon är 5,55 studs LÅNG; en gång utan
	mån åt sidorna ger henne ingenstans att svänga — vilket #194 mätte i
	praktiken.

	Fönstret mellan de två mätningarna är (1,000 .. 1,521]. Värdet nedan
	lägger sig mitt i det: 0,930 + 0,320 = 1,250, med 0,250 studs marginal
	ned till människodörrarna och 0,271 upp till hästruttens tak.

	Kontrollerat: samtliga 49 boxutgångar bär 1,250 lika väl som 0,930.
	Halva LÄNGDEN (2,775) är fortfarande fel av skälet i noten ovan — en
	sådan radie hade krävt en öppning bredare än hela hennes kropp. ]]
local NAV_RADIE_FAKTOR = 0.5   -- av kroppens BREDD, se noten ovan
local NAV_RADIE_MAN    = 0.32  -- studs fri mån utöver kroppen, se noten ovan
local NAV_VAGPUNKT     = 2.5   -- studs mellan vägpunkter; tätare än standard 4
local NAV_NA_VAGPUNKT  = 1.6   -- studs: så nära räknas en vägpunkt som nådd
local NAV_STILLA       = 1.2   -- s utan framsteg innan planeraren kopplas in
local NAV_OMPLAN_PAUS  = 1.0   -- s: kortaste tid mellan två planeringar
local NAV_MAX_PLANER   = 6     -- fler än så och vi ger upp i stället för att mala
local NAV_FASTNAT      = 8.0   -- s helt stilla trots order: kopplet släpper
local NAV_ANKARE       = 0.25  -- m hon måste förflytta sig för att räknas som i rörelse
local NAV_TAKT         = 0.5   -- andel av BEORDRAD fart som räknas som att hon går

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
--[[ KURSEN ÄR BLICKRIKTNINGEN, samma definition som
	`MovementController` använder: `heading = atan2(Look.X, Look.Z)`, och
	därmed är `(sin h, 0, cos h)` exakt `LookVector`.

	Förut lästes kursen som `ToOrientation().Y`, alltså den vinkel man
	skickar till `CFrame.Angles` — vars blickriktning är den MOTSATTA. Det
	gav en häst som leddes med svansen före: mätt i Studio låg huvudet
	3,32 studs BAKOM färdriktningen.

	`kurs` läses fortfarande, av spårföljningen och av dörrlogiken. Den
	SKRIVER ingenting. ]]
local function kurs(pivot: BasePart): number
	local look = pivot.CFrame.LookVector
	return math.atan2(look.X, look.Z)
end

--[[ ══ BORTTAGET MED FLIT: `vridMot`, `framat`, `VAND_FULL`, `VAND_STOPP`

	De hörde till den gamla aktueringen. `vridMot` skrev `pivot.CFrame`
	direkt varje bildruta för att vrida henne, och vändtrösklarna fanns
	för att `Humanoid:Move` sköt kroppen rakt fram oavsett hur den stod —
	en häst med kroppen på tvären gick in i dörrkarmen, så hon fick inte
	gå förrän hon vänt.

	`AlignOrientation` vrider henne kontinuerligt MEDAN `AlignPosition`
	drar. Problemet vändtröskeln löste kan inte uppstå, och direkt
	CFrame-skrivning i en runtime-loop är uttryckligen förbjuden av
	arkitekturkontraktet i #235 FAS 4.

	DE LIGGER INTE KVAR SOM DÖD KOD. En oanvänd funktion som skriver
	CFrame är en inbjudan att anropa den igen, och nästa läsare ser inte
	att den bröt kontraktet. Kvar finns bara `kurs`, som läser. ]]

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
	--[[ Punkten hon faktiskt styr mot den här bildrutan. Skrivs av `steg`
		varje bildruta och läses av prov och runtimemätning. ]]
	delmal: Vector3?,
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
	ankartid: number,
	sparFullt: boolean,
	forraSpelarPos: Vector3?,
}

local ledd: { [Player]: Led } = {}

export type Boxminne = {
	modell: Model,
	boxX: number,
	boxY: number,
	dorrKand: boolean,
}

--[[ Vad spelaren SENAST ledde, kvar efter att kopplet släppt. Rivs i
	`PlayerRemoving` — bokföringen är sessionsbunden av samma skäl som
	`uppnatt`. ]]
local senasteLedning: { [Player]: Boxminne } = {}

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

--[[ LEDS DEN HAR HASTEN AV NAGON? Registret ar per SPELARE, och fragan
	"vem leder henne" fanns darfor bara som en inbaddad loop inne i
	`borja`. #235 FAS 2 behover samma sanning utifran — en hast som leds
	far inte sadlas — och en andra loop nagon annanstans hade varit en
	andra sanning om vad "ledd" betyder.

	`borja` anropar numera den har, sa det finns EN loop och ett svar. ]]
function LedService.ledsAv(modell: Model?): Player?
	if modell == nil then return nil end
	for annan, l in pairs(ledd) do
		if l.modell == modell then return annan end
	end
	return nil
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

--[[ ══ STALLET LEDDE HENNE DIT ═══════════════════════════════════════════

	FUN FIRST / RIDE FIRST: väljer spelaren "Rida nu" gör stallet i ordning
	hästen — och leder henne också ut. Det är en VERKLIG förflyttning, inte
	en bock i en tabell.

	Skillnaden är hela poängen. Att markera `leda` som gjort medan hon står
	kvar i boxen hade återinfört exakt den klass av fel som #162 blockerare 2
	och #180 handlade om: logiskt färdig, fysiskt kvar. Här flyttas hon
	först, och flaggorna sätts BARA om `iRekt` sedan säger att hon faktiskt
	är i målzonen. Går flytten inte igenom sätts ingenting alls.

	Ryttaren får ingen ny position: hon går dit själv. Det stallet gör är
	att lämna hästen framme, precis som en stallpersonal som ställt fram
	henne inför lektionen. ]]
--[[ STALL FRAM HAST OCH RYTTARE I MALZONEN — utan att bokfora nagot.

	Bruten ur `placeraVidMal` for #263 Gate 2A. Delningen ar inte
	kosmetisk: `placeraVidMal` gor TVA saker, och First Ride far bara
	gora den ena.

	  GEOMETRIN — dar malzonen ligger i varlden, och var hasten och
	  ryttaren hamnar. Ren fysisk placering.

	  BOKFORINGEN — `noteraUppnatt(lamnatBox, malNatt)`, alltsa beviset
	  for att SPELAREN ledde henne dit. Det ar en ledningsprestation.

	First Ride flyttar hasten till ridhuset at spelaren; hon har inte
	lett henne. Skrev den har funktionen flaggorna hade hennes senare
	`leda`-fas passerat sin fysiska kontroll utan att hon gjort
	arbetet, och ordern i #263 forbjuder uttryckligen att stallskotsel
	markeras som utford.

	Geometrin star kvar pa ETT stalle. Tva kopior av samma
	koordinatmatematik hade varit precis den dubbla sanning kanon
	forbjuder. ]]
function LedService.stallFram(player: Player, modell: Model): (boolean, string?)
	if typeof(modell) ~= "Instance" or not modell:IsA("Model") then
		return false, "spel.ingen_hast"
	end
	local zon = malzon
	if not zon then return false, "led.ingen_malzon" end
	local pivot = modell.PrimaryPart
	if not pivot then return false, "spel.ingen_hast" end

	--[[ Mitten av zonen, på hästens nuvarande höjd: zonen är en yta i
		tomtkoordinater och bär ingen egen Y. ]]
	--[[ Vägen tillbaka från tomtkoordinater: `tomt()` ovan är
		`x/M, TOMTDJUP - z/M`, så världen blir `x*M, (TOMTDJUP-y)*M`. ]]
	local mitt = Vector3.new((zon.x + zon.w / 2) * M, pivot.Position.Y,
		(TOMTDJUP - (zon.y + zon.h / 2)) * M)
	local fore = pivot.Position
	modell:PivotTo(CFrame.new(mitt) * (pivot.CFrame - pivot.Position))

	--[[ BEVISET, inte avsikten. Hamnade hon inte i zonen ska ingenting
		bokföras — och hon ställs tillbaka, så att ett halvt utfört
		stallarbete inte lämnar henne mitt i en vägg. ]]
	if not LedService.iRekt((modell.PrimaryPart :: BasePart).Position, zon) then
		modell:PivotTo(CFrame.new(fore) * (pivot.CFrame - pivot.Position))
		return false, "led.kunde_inte_stalla_fram"
	end

	--[[ ── SPELAREN GÅR MED ──────────────────────────────────────────

		Att LEDA en häst betyder att man går bredvid henne. Första
		versionen flyttade bara hästen, och mätt i Studio blev följden
		precis det #182 varnade för: hon försvann 98 studs (32,7 m) till
		ridhuset medan spelaren stod kvar i stallet.

		Värre än förvirringen var att det bröt kedjan. Varje steg i
		`GameplayService` prövar `narvaro(player)`, så nästa moment föll
		på `spel.for_langt` — förberedelsen blev ofullständig och spelaren
		fick ett nej på en knapp hon just tryckt på.

		Hon ställs vid hästens vänstra sida, där man leder ifrån, och på
		hästens marknivå. ]]
	local karaktar = player.Character
	local hrp = karaktar and karaktar:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then
		local hast = (modell.PrimaryPart :: BasePart).CFrame
		hrp.CFrame = hast * CFrame.new(-3, 0, 0)
	end

	return true, nil
end

--[[ Stall fram HENNE, och bokfor att spelaren tog henne dit.

	Den har ar ledningens och «Rida nu»:s vag: bada ar handlingar dar
	spelaren bett om eller utfort forflyttningen, och da ar flaggorna
	sanna. Se noten vid `stallFram` for varfor First Ride inte far
	anvanda den. ]]
function LedService.placeraVidMal(player: Player, modell: Model): (boolean, string?)
	local ok, fel = LedService.stallFram(player, modell)
	if not ok then return false, fel end

	local hastId = tostring(modell:GetAttribute("HorseId") or "")
	noteraUppnatt(player, hastId, "lamnatBox")
	noteraUppnatt(player, hastId, "malNatt")
	local l = ledd[player]
	if l and l.modell == modell then
		l.lamnatBox = true
		l.malNatt = true
	end
	return true, nil
end

--[[ ── Att börja leda ───────────────────────────────────────────────
	Varje nej har en egen nyckel. Ett enda "gick inte" hade gjort de
	negativa fallen omöjliga att skilja åt i ett test. ]]
--[[ ══ LOGGEVIDENS (#182 del 2) ════════════════════════════════════

	SPARSAM MEN ANVANDBAR. Raden ska svara pa de tre fragor man faktiskt
	har nar nagot gatt fel i Studio eller i en spelares session:

	    VEM, VILKEN HAST, och VAD SOM HANDE — med skal nar svaret ar nej.

	Hastens id ar med i VARJE rad, for det ar den enda nyckeln som binder
	ihop `LedBorja`, `LedSync` och `_steg` i samma logg. Ett nej utan id
	gar inte att folja tillbaka till en hast.

	INGEN LOOP-LOGG. `_steg` kor varje bildruta; en rad dar hade dranktt
	allt annat. Bara OVERGANGARNA loggas — start, slut, frankoppling. ]]
local function logg(player: Player, handling: string, hastId: string?, skal: string?)
	local vem = tostring((player :: any) and (player :: any).Name or "?")
	local vilken = if hastId ~= nil and hastId ~= "" then hastId else "-"
	if skal ~= nil then
		warn(("[Led] %s · %s · %s NEKAD: %s"):format(vem, vilken, handling, tostring(skal)))
	else
		print(("[Led] %s · %s · %s"):format(vem, vilken, handling))
	end
end

--[[ ══ FOLJRIGGEN: TVA FASTPUNKTER OCH TVA REGULATORER ═════════════

	`LeadTargetAttachment` sitter pa SPELARENS `HumanoidRootPart`, pa hennes
	HOGRA sida och nagot bakom. Det ar inte en detalj: det ar det som gor
	att spelaren gar vid hastens VANSTRA sida, som man leder en hast.

	`LeadRootAttachment` sitter pa hastens root.

	`AlignPosition` drar roten mot malet, `AlignOrientation` vrider kursen.
	Ingen tredje reglering finns, och det ar hela poangen — tva krafter om
	samma mal ar det som ger studs och oscillation.

	MALPUNKTEN FLYTTAS, INTE FASTPUNKTENS FORALDER. `styrMot` skriver
	`WorldPosition` pa targetfastet varje bildruta. Normalt ar det punkten
	vid spelarens hogra hoft; nar sparfoljningen sager att hon maste runda
	en dorrkarm ar det brodsmulan i stallet. Fastpunkten hanger kvar dar
	kontraktet sager att den ska hanga, men vad den PEKAR PA ags av
	foljningen. ]]
local function byggFoljrigg(karaktar: Model, modell: Model): { [string]: any }?
	local rot = karaktar:FindFirstChild("HumanoidRootPart")
	local pivot = modell.PrimaryPart
	if not (rot and rot:IsA("BasePart") and pivot) then return nil end

	local mal = Instance.new("Attachment")
	mal.Name = "LeadTargetAttachment"
	--[[ Hoger sida, nagot bakom: `+X` ar hoger, `+Z` ar bakat i Roblox. ]]
	mal.Position = Vector3.new(0.9 * M, 0, 0.6 * M)
	mal.Parent = rot

	local hastfast = Instance.new("Attachment")
	hastfast.Name = "LeadRootAttachment"
	hastfast.Parent = pivot

	local drag = Instance.new("AlignPosition")
	drag.Name = "UBRFLedDrag"
	drag.Attachment0 = hastfast
	drag.Attachment1 = mal
	--[[ INTE STEL. En stel `AlignPosition` teleporterar henne dit; det ar
		precis den «hasten ar ett fordon»-kansla kontraktet forbjuder. ]]
	drag.RigidityEnabled = false
	drag.MaxForce = ALIGN_KRAFT
	drag.Responsiveness = ALIGN_SVAR
	drag.MaxVelocity = skrittfart()
	--[[ Planet ager vi inte: hon ska inte lyftas mot marken. ]]
	drag.ApplyAtCenterOfMass = true
	drag.Enabled = false
	drag.Parent = pivot

	local vrid = Instance.new("AlignOrientation")
	vrid.Name = "UBRFLedVrid"
	vrid.Attachment0 = hastfast
	vrid.RigidityEnabled = false
	vrid.MaxTorque = ALIGN_VRID
	vrid.Responsiveness = ALIGN_VRIDSVAR
	--[[ En RIKTNING, inte en andra fastpunkt: hon ska peka dit hon gar,
		inte kopiera spelarens kropp. ]]
	vrid.Mode = Enum.OrientationAlignmentMode.OneAttachment
	vrid.Enabled = false
	vrid.Parent = pivot

	return { mal = mal, hastfast = hastfast, drag = drag, vrid = vrid }
end

local function rivFoljrigg(l: any)
	local r = l and l.rigg
	if not r then return end
	for _, namn in ipairs({ "drag", "vrid", "mal", "hastfast" }) do
		local d = r[namn]
		if d then pcall(function() d:Destroy() end) end
	end
	l.rigg = nil
end

--[[ Provets fonster in. ]]
function LedService.riggFor(player: Player): { [string]: any }?
	local l = ledd[player]
	return l and l.rigg or nil
end

--[[ ══ LEDREPET (#182 del 2) ═══════════════════════════════════════

	Spelaren ska SE att hon leder, inte bara laesa det. Repet gar fran
	hennes hand till hastens huvud sa lange servern sager att ledningen
	pagar, och forsvinner i samma andetag som den upphor.

	DET AR EN `Beam`, INTE EN `RopeConstraint`, och det ar ett medvetet
	val av tva skal:

	  1. ARKITEKTURORDERN I #235 forbjuder uttryckligen `RopeConstraint`
	     som primar locomotion. Ett rep som DRAR skulle dessutom sla sig
	     mot `_steg`, som ar den auktoritativa foljningen — tva krafter om
	     samma mal ar exakt det som ger studs och oscillation.
	  2. En `Beam` har ingen fysik alls. Den kan darfor aldrig paverka vart
	     hasten gar, hur fort hon gar eller om hon fastnar. Repet ar
	     presentation; `LedService._steg` ar sanningen.

	Kurvan gor att repet HANGER i stallet for att sta spikrakt, vilket ar
	sa ett koppel ser ut nar hasten foljer lugnt bredvid.

	EN RIVNINGSPUNKT. `rivRep` anropas fran `slapp`, och varje avslut —
	manuellt slapp, for langt, fastnat, uppsittning, spelaren gar, hasten
	forsvinner — gar genom `slapp`. Det ar darfor repet inte kan bli kvar
	hangande i luften efter en hast som inte finns. ]]

--[[ Var pa hasten repet ska sitta. Transets nackstycke forst — det ar dit
	ett koppel faktiskt kopplas — sedan huvudet, sist kroppen. Ingen av
	dem far antas finnas. ]]
local function hastfaste(modell: Model): BasePart?
	for _, namn in ipairs({ "Head", "Bone_Head_01", "Neck01" }) do
		local d = modell:FindFirstChild(namn, true)
		if d and d:IsA("BasePart") then return d end
	end
	return modell.PrimaryPart
end

local function handfaste(karaktar: Model): BasePart?
	for _, namn in ipairs({ "RightHand", "RightLowerArm", "UpperTorso", "HumanoidRootPart" }) do
		local d = karaktar:FindFirstChild(namn)
		if d and d:IsA("BasePart") then return d end
	end
	return nil
end

local function byggRep(karaktar: Model, modell: Model): { [string]: any }?
	local hand = handfaste(karaktar)
	local huvud = hastfaste(modell)
	if not (hand and huvud) then return nil end

	local a0 = Instance.new("Attachment")
	a0.Name = "UBRFLedrepHand"
	a0.Parent = hand
	local a1 = Instance.new("Attachment")
	a1.Name = "UBRFLedrepHast"
	a1.Parent = huvud

	local beam = Instance.new("Beam")
	beam.Name = "UBRFLedrep"
	beam.Attachment0 = a0
	beam.Attachment1 = a1
	beam.Width0 = 0.06 * M
	beam.Width1 = 0.06 * M
	beam.FaceCamera = true
	beam.Color = ColorSequence.new(Color3.fromRGB(122, 102, 78))
	beam.LightInfluence = 1
	--[[ Repet HANGER. Kurvorna pekar nedat i ledningens riktning, sa att
		det bagnar som ett koppel i stallet for att sta spant. ]]
	beam.CurveSize0 = -0.18 * M
	beam.CurveSize1 = -0.18 * M
	beam.Segments = 12
	beam.Parent = a0

	return { beam = beam, a0 = a0, a1 = a1 }
end

local function rivRep(l: any)
	local rep = l and l.rep
	if not rep then return end
	for _, namn in ipairs({ "beam", "a0", "a1" }) do
		local d = rep[namn]
		if d then pcall(function() d:Destroy() end) end
	end
	l.rep = nil
end

--[[ Provets fonster in: hanger det ett rep mellan spelaren och hasten? ]]
function LedService.repFor(player: Player): Instance?
	local l = ledd[player]
	return l and l.rep and l.rep.beam or nil
end

--[[ Sjalva provningen. Loggen ligger i skalet nedan, sa att varje nej —
	och det ar tio stycken — kommer ut i loggen utan att tio rader
	behover halla sig synkade med tio `return`. ]]
local function borjaInre(player: Player, modell: Model?, ratt: Model?): (boolean, string?)
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
	--[[ Fragan stalls genom `ledsAv` sa att den har regeln och #235
		FAS 2:s sadelgrind laser SAMMA register. ]]
	if LedService.ledsAv(modell) ~= nil then
		return false, "led.upptagen"
	end

	--[[ EN UPPSUTTEN HAST LEDS INTE (#182 del 2). Kroken svarar ur
		`HorseService` egna sessioner — samma falt uppsittningen laser
		nar den nekar med `hast.upptagen`. Utan den har grinden gick en
		hast med ryttare att koppla i, och da hade tva spelare styrt
		samma djur at olika hall. ]]
	local riden = hakar.riden
	if riden ~= nil and riden(modell) == true then
		return false, "led.rids"
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
	--[[ VET VI ÖVER HUVUD TAGET VAR BOXEN ÄR? (#180)

		`iBox` svarade förut på två olika frågor med samma false: "dörren
		säger att hon står i gången" OCH "det finns ingen dörr att fråga".
		`lamnatBox = not iBox` gjorde därför det senare till ett påstående
		om att hon redan lämnat boxen — innan hon rört sig en centimeter.

		Det är fail-open på precis den fråga som ska vara fail-closed.
		Konsekvensen är inte teoretisk: `PreparationMoment("leda")` kvitterar
		momentet på `harLamnatBox`, så en box utan modellerad dörr hade
		godkänt en ledning som aldrig utförts. Samma tysta falska PASS som
		#162 och #171 handlade om.

		`dorrKand` skiljer de två fallen åt. Fångas FÖRE nollställningen
		nedan, som annars suddar just det vi frågar om. ]]
	local dorrKand = dorrMitt ~= nil and dorrUt ~= nil
	local iBox = false
	if dorrKand then
		iBox = (pivot.Position - (dorrMitt :: Vector3)):Dot(dorrUt :: Vector3) <= 0
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
		spelarHum2.WalkSpeed = skrittfart() * LEDNINGSTAKT
	end
	ledd[player] = {
		tidigareFart = tidigareFart,
		tidigareSpelarfart = tidigareSpelarfart,
		modell = modell,
		hastId = tostring(modell:GetAttribute("HorseId") or ""),
		gar = false,
		--[[ Står hon redan i gången finns ingen box kvar att lämna. Då är
			flaggan sann direkt, och `boxX`/`boxY` nedan konsulteras aldrig
			— de gäller bara så länge hon faktiskt är kvar i facket.

			Men BARA när en dörr faktiskt svarat på frågan (#180). Utan
			dörr vet tjänsten ingenting om var facket slutar, och då ska
			den inte påstå något: flaggan är false, och avståndsregeln i
			`_steg` — som mäter FAKTISK förflyttning från startpunkten och
			inte behöver någon dörrgeometri — får avgöra när hon är ute. ]]
		lamnatBox = dorrKand and not iBox,
		malNatt = false,
		boxX = bx, boxY = by,
		dorrMitt = dorrMitt,
		tidigareAgare = tidigareAgare,
		tidigareAuto = tidigareAuto,
		spar = {},
		dorr = narmasteDorr,
		dorrUt = dorrUt,
		dorrsteg = 1,
		delmal = nil,
		navVag = {}, navIx = 1, navPlaner = 0, navSenast = -NAV_OMPLAN_PAUS, planerar = false, tid = 0,
		stillaSedan = 0, badGa = false, ankare = pivot.Position, ankartid = 0,
		sparFullt = false, forraSpelarPos = nil,
	}
	--[[ REPET (#182 del 2). Byggs SIST, nar tillstandet finns: ett rep
		utan en ledning bakom sig vore en lognaktig bild. ]]
	ledd[player].rep = byggRep(karaktar, modell)
	--[[ OCH FOLJRIGGEN. Det ar den som faktiskt flyttar henne; repet
		ovan ar bilden av det. ]]
	ledd[player].rigg = byggFoljrigg(karaktar, modell)
	--[[ OCH DORREN. Se noten vid `satDorrKrok`: ett tryck, inte tva.
		Bara nar hon faktiskt star kvar i facket — star hon redan i
		gangen finns ingen dorr att oppna, och da ska ingen oppnas. ]]
	if not ledd[player].lamnatBox and narmasteDorr and hakar.dorr then
		pcall(function() (hakar.dorr :: any)(narmasteDorr) end)
	end
	ledd[player].forLangtSedan = 0

	--[[ Minnet som överlever släppet, se `aterstallTillBox`. ]]
	senasteLedning[player] = {
		modell = modell,
		boxX = bx, boxY = by,
		dorrKand = dorrMitt ~= nil,
	}
	LedService._sync(player)
	return true, nil
end

function LedService.borja(player: Player, modell: Model?, ratt: Model?): (boolean, string?)
	--[[ ID:T LASES FORE FORSOKET. Nekas det finns ingen ledning att
		fraga efteraat, och ett nej utan hast gar inte att folja
		tillbaka i loggen. ]]
	local id: string? = nil
	if modell ~= nil and (modell :: any).GetAttribute ~= nil then
		local ok, v = pcall(function() return modell:GetAttribute("HorseId") end)
		if ok and v ~= nil then id = tostring(v) end
	end
	local ok, skal = borjaInre(player, modell, ratt)
	logg(player, "LedBorja", id, if ok then nil else tostring(skal))
	return ok, skal
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
	--[[ REPET FORST. Det ar det spelaren SER, och det ska vara borta
		i samma ogonblick ledningen upphor — vilket avslut det an ar.
		Alla vagar ut gar genom den har funktionen, sa det racker med
		en rivningspunkt. ]]
	rivRep(l)
	rivFoljrigg(l)

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
	--[[ MANUELLT SLAPP eller AUTOMATISK FRANKOPPLING? `skal` ar nil nar
		spelaren sjalv slappte och en nyckel nar kopplet, doden eller
		uppsittningen gjorde det. Loggen skiljer dem at, for det ar
		precis den skillnaden man vill veta efterat. ]]
	if skal ~= nil then
		logg(player, "frankoppling", l.hastId, tostring(skal))
	else
		logg(player, "LedSlapp", l.hastId, nil)
	end
	LedService._sync(player, skal)
	return true, skal
end

--[[ ══ HÄSTEN FÅR INTE LÄMNAS I GÅNGEN (#202 punkt 4) ══════════════════

	Mätt i Studio på `e6a674c`: Player2 ledde Troy ut ur box E 8 och kopplade
	sedan ned. Hon lämnades stående på (166,57 · 96,80), mitt i gång B.
	Fysiskt sant, men över en session fylls gångarna av hästar ingen längre
	håller i.

	OCH KOPPLET HADE REDAN SLÄPPT. Det är hela poängen med `senasteLedning`
	nedan. Första rättelsen städade bara när `ledd[player]` fanns kvar vid
	nedkopplingen — men det vanliga förloppet är det omvända: hon blir
	efter, kopplet släpper på `led.tappade_bort`, spelaren ger upp och
	stänger spelet. Mätt om i Studio på `5c70963`: `Led.aktiv = nil` medan
	hon stod 3,44 m ut i gång A. Städningen fyrade aldrig.

	Minnet överlever därför släppet och rivs först när spelaren är borta.

	VART hon ska är inte definierat i kanon. Stallkortet säger ingenting om
	vad personalen gör med en häst vars handhavare försvinner, och det finns
	ingen bild på saken. `[antagande]`: hon ställs tillbaka DÄR HON STOD när
	kopplet fästes — `boxX`/`boxY`, som tjänsten redan bokför. Det är den
	enda punkt som är härledd ur befintlig data och inte vald av mig, och i
	det normala flödet är den hennes egen box.

	Tre spärrar, så att städningen aldrig kan göra saken värre:

	  1. bara när hon FAKTISKT startade i en box (`dorrKand` — samma villkor
	     som `#180` använder för att veta att facket är känt),
	  2. bara när hon FAKTISKT har lämnat den (samma 2,5 m som `lamnatBox`
	     mäts på; står hon kvar finns inget att städa),
	  3. och flytten VERIFIERAS. Hamnade hon inte där ställs hon tillbaka
	     precis som `placeraVidMal` gör — hellre kvar i gången än inne i en
	     vägg.

	Skälen nedan är diagnostik. De når aldrig en spelare: den som skulle ha
	läst dem har just lämnat spelet. ]]
function LedService.aterstallTillBox(minne: Boxminne?): (boolean, string?)
	if minne == nil then return false, "ingen ledning" end
	if not minne.dorrKand then return false, "ingen känd box" end
	local modell = minne.modell
	local pivot = modell and modell.PrimaryPart
	if not (modell and modell.Parent and pivot) then return false, "hästen borta" end

	local x, y = tomt(pivot.Position)
	if math.sqrt((x - minne.boxX) ^ 2 + (y - minne.boxY) ^ 2) <= 2.5 then
		return false, "står kvar i boxen"
	end

	local fore = pivot.CFrame
	local mitt = Vector3.new(minne.boxX * M, pivot.Position.Y,
		(TOMTDJUP - minne.boxY) * M)
	--[[ Läget byts, blickriktningen behålls. `CFrame.lookAt` i stället för
		`CFrame.new(mitt) * (fore - fore.Position)`: samma resultat, och den
		formen uttrycker vad som faktiskt ska bevaras. ]]
	modell:PivotTo(CFrame.lookAt(mitt, mitt + fore.LookVector, Vector3.yAxis))

	local nx, ny = tomt((modell.PrimaryPart :: BasePart).Position)
	if math.sqrt((nx - minne.boxX) ^ 2 + (ny - minne.boxY) ^ 2) > 0.5 then
		modell:PivotTo(fore)
		return false, "kunde inte ställa tillbaka"
	end
	return true, nil
end

--[[ Vad tjänsten minns om spelarens senaste ledning. Provets fönster in. ]]
function LedService.boxminne(player: Player): Boxminne?
	return senasteLedning[player]
end

function LedService._glomBoxminne(player: Player)
	senasteLedning[player] = nil
end

function LedService._sync(player: Player, skal: string?)
	local k = Aktor.klient(player)
	if not k then return end
	local ev = Net.get("LedSync")
	local l = ledd[player]
	ev:FireClient(k, {
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
		AgentRadius = pivot.Size.X * NAV_RADIE_FAKTOR + NAV_RADIE_MAN,
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
--[[ RESERVMÅLET ÄR RÄTTELSEN (#182).

	Mätt i Studio på `ad44dfe`, första divergensen efter boxutgången:

	    spar = 1 punkt          gallringen tömmer spåret när hon går nära
	    källa = fallback        `rot.Position - LookVector * FOLJ_BAKOM*M`
	    mål   = 494,1 · 269,4   krockar med INGENTING
	    ComputeAsync(mål)       → NoPath, 0 vägpunkter
	    ComputeAsync(spelaren)  → Success, 2 vägpunkter   SAMMA bildruta

	Fallbackpunkten ligger 7,2 studs rakt bakom spelarens blickriktning.
	Står hon vänd mot hästen i en box hamnar den punkten inne i boxradens
	fotavtryck bakom fronten — gångbar yta tar slut där, men ingenting
	KROCKAR, så inget i tillståndet ser trasigt ut.

	Alla sex omplaneringarna fick samma omöjliga mål, `navVag` förblev tom,
	och kopplet släppte med `led.fastnat` vid 16,6 studs — långt inom
	kopplet. Hästen stod blickstilla på samma decimal i 7,8 sekunder.

	Rättelsen är INTE att sluta följa brödsmulorna: genom dörrar är spåret
	det enda som bär, och `viaDorr` äger fortfarande sina delmål. Rättelsen
	är att ett ONÅBART mål inte ska få kosta ett helt planeringsförsök när
	det finns ett mål vi VET är nåbart — spelaren själv, som hästen leds av
	och som per definition står på gångbar yta.

	Reserven prövas i SAMMA försök, inte som ett sjunde. Taket
	`NAV_MAX_PLANER` finns för att en blockerad häst inte ska mala servern,
	och det skyddet ska inte urholkas. ]]
local function planera(l: Led, pivot: BasePart, mal: Vector3, reserv: Vector3?)
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
		local function berakna(till: Vector3)
			local v = PathfindingService:CreatePath(param)
			local ok = pcall(function()
				v:ComputeAsync(start, till)
			end)
			if ok and v.Status == Enum.PathStatus.Success then return v end
			return nil
		end

		local vag = berakna(mal)
		--[[ Bar inte det valda målet, prova det vi vet bär. Se noten över
			`planera`: ett mål utanför navmeshen ska inte kunna förbruka
			alla omplaneringar och få henne dödförklarad som fastnad. ]]
		if vag == nil and reserv ~= nil then
			vag = berakna(reserv)
		end

		--[[ Flaggan släpps FÖRST när båda försöken är gjorda — annars kunde
			omplaneringspausen kringgås av en beräkning som ännu inte
			svarat, vilket är precis vad flaggan finns för att hindra. ]]
		l.planerar = false
		if vag == nil then
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
		--[[ ══ EN NY VÄG FÅR BÖRJA MED REN KLOCKA ═══════════════════

			MÄTT I STUDIO under M3.1, i gluggen mellan Tvärvägg 1:1 och 1:2.
			Hästen låg kilad mot väggens norra sida — flanken nådde Z 185,68
			och väggen börjar 185,70, alltså två hundradels studs mellan dem.
			Hennes mål låg rakt söder om väggen.

			Planeraren KLARADE det. `ComputeAsync` från exakt den posen ger
			sex vägpunkter rakt genom gluggen — uppmätt efteråt på samma
			koordinater. Men i körningen var `navVag` tom bildrutan efter:

			     9,9 s   nav 2/5   en väg på fem punkter fanns
			    10,1 s   nav 1/0   den var borta

			Skyldig ar «EN VÄG SOM INTE BÄR SKA KASTAS» i `_steg`: den kastar
			vagen nar `stillaSedan > NAV_STILLA`. Klockan stod redan på fem
			sekunder från tiden FÖRE vägen fanns, så varje ny väg revs innan
			hon hunnit ta ett enda steg på den. Alla sex planöken gick samma
			väg, och sedan släppte kopplet på `led.fastnat`.

			Den regelns EGEN avsikt är att mäta tid PÅ VÄGEN — «hon låg på en
			vägpunkt hon inte kunde nå». Klockan nollställs därför när vägen
			installeras, så att den mäter just det. Ingen tidsgräns är ändrad.

			`navPlaner` rörs INTE här. Nollställningen av den ligger i `_steg`
			bakom `navigerar(l)`-grenens `continue`, så en häst som följer en
			väg får inga nya försök gratis. Taket består, och bär ingen av de
			sex vägarna släpper kopplet som förr. ]]
		l.stillaSedan = 0
		l.ankare = pivot.Position
		l.ankartid = 0
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
--[[ ETT ENDA STALLE DRIVER HENNE, och det ar tva constraints.

	Allt nedanfor valjer bara MALPUNKTEN; den har funktionen ar det enda
	som ror fysiken.

	FORUT GJORDE DEN TVA FORBJUDNA SAKER: `vridMot` skrev `pivot.CFrame`
	direkt for att vrida henne, och `Humanoid:Move` korde varje bildruta
	for att driva henne. Bada ar loopreglering, bada slogs mot Roblox egen
	fysik, och bada ar uttryckligen forbjudna av arkitekturkontraktet i
	#235 FAS 4.

	Nu satts malet och regulatorerna far gora jobbet:

	  · `AlignPosition` drar roten mot `LeadTargetAttachment`
	  · `AlignOrientation` vrider kursen mot fardriktningen

	`onskadFartMS` blir `MaxVelocity`, inte `WalkSpeed`. Det ar samma
	storhet — hur fort hon FAR ga — men den ager nu constrainten i stallet
	for en Humanoid som ocksa styrs av annat.

	INGEN VANDTROSKEL LANGRE. `VAND_STOPP`/`VAND_FULL` fanns for att
	`Humanoid:Move` sköt kroppen rakt fram oavsett hur den stod, sa hon
	maste vanda forst for att inte ga in i dorrkarmen pa tvaren.
	`AlignOrientation` vrider henne kontinuerligt medan `AlignPosition`
	drar, sa problemet uppstar inte. Kursen ar mjuk och kan inte snappa. ]]
--[[ ══ SPÅRET ÄR RUTTHISTORIK — BARA HÄSTEN FÅR FÖRBRUKA EN SMULA ═══

	Produktbeslut 2026-09-20, efter M3:

	  > En ledd häst får inte förlora en OFÖRBRUKAD smula medan ledningen
	  > fortfarande är giltig. Spelarens avstånd får avgöra kopplet. Det
	  > får inte radera rutthistorik som hästen ännu inte har gått igenom.

	FÖRUT GALLRADE DEN PÅ SPELARENS AVSTÅND, med `MAL_AVVIK` som gräns.
	Mätt i Studio, hela ledrutten box E 8 -> ridhuset, sju pass med samma
	utfall:

	    häst      488,6 · 184,8   v 0,01
	    spelare   471,3 · 207,2   koppel 9,4 m
	    delmål    472,8 · 187,1
	    rör       Tvärvägg 1:2 @ 485 · 186
	    strålen mot målet   Tvärvägg 1:2 på 5,8 studs

	Hon stod NORR om väggen, målet låg SÖDER om den, och linjen dit gick
	rakt igenom. Spelaren hade tagit sig runt väggens västra ände — men
	smulorna längs den vägen, 488 · 184 och 480 · 184 och 475 · 184, låg
	7,7..9,7 m från spelaren och var därför redan kastade. Kvar fanns
	bara en punkt på fel sida om väggen.

	OCH TALEN GARANTERADE DET:

	    MAL_AVVIK  7,0 m   så långt från SPELAREN fick en smula ligga
	    KOPPEL     9,0 m   så långt efter får HÄSTEN hamna

	Spåret gallrades 2 m INNANFÖR kopplet. Det fanns alltså ett band där
	kopplet höll men vägen redan var borta — hon var garanterat väglös
	innan hon släpptes.

	NU MÄTS FÖRBRUKNINGEN I STÄLLET, och den ägs av hästen: en smula hon
	har kommit fram till är gången, resten är väg hon har kvar. Gränsen
	är `START_R`, samma tal hysteresen börjar gå vid — en punkt hon inte
	tänker gå till får inte vara hennes mål. Minnet begränsas som förut
	av ringbufferten, och den sista smulan gallras aldrig, så hon blir
	aldrig mållös av en städning.

	STALENESS-REGELN ÄR DÄRMED BORTA, med flit. Vänder spelaren tvärt
	följer hästen den väg hon faktiskt leddes i stället för att skära
	hörnet — och det är samma sak som att hon går runt väggen.

	EGEN FUNKTION AV SAMMA SKÄL SOM `klampMal`: inbakad i loopen kom
	mutationen som tog bort den ut GRÖN — spårgrenen kräver att hästen
	lämnat en box, och inget bänkscenario nådde dit. En regel som bara går
	att mäta genom ett scenario man inte kan bygga är obevisad. ]]
local function gallraSpar(spar: { Vector3 }, hastPos: Vector3)
	--[[ FÖRBRUKNINGEN ÄR MONOTON I RUTTENS ORDNING — bara framifrån.

		En smula är förbrukad när hästen har KOMMIT FRAM TILL den, inom
		`START_R`. Inget annat. Gallringen går därför framifrån och
		stannar vid den första hon inte nått; allt bakom den ligger kvar
		som väg hon har att gå.

		══ VARFÖR DEN INTE FÅR SÖKA NÄRMASTE SMULA ═══════════════════

		Den sökte förut den GLOBALT närmaste smulan i hela spåret och
		kastade allt före den. Det var samma fel som hela regeln finns
		för att stänga — rak linje i stället för färdväg — och ChatGPT:s
		slutreview på `3ecaa16` reproducerade det:

		    fyra oförbrukade smulor på rutten
		    den fjärde korsar tillbaka till 0,5 m från hästen
		    nästa hon faktiskt ska gå till ligger 2,0 m bort
		    -> 1 av 4 kvar

		En väg som böjer tillbaka — spelaren rundar ett hinder och
		passerar nära hästen igen — har en SENARE smula fysiskt
		närmast. Hela sträckan hon hade kvar raderades då i ett svep,
		och hon lämnades med ett mål på andra sidan omvägen. 2,0 m är
		dessutom mer än `START_R`: hon hade inte nått någon av dem.

		FYSISK NÄRHET TILL NÅGOT LÄNGRE FRAM ÄR INTE FRAMSTEG.

	══ OCH NÄRHET ÄR INTE FRAMSTEG — INTE HELLER TILL NÄSTA GRANNE ══

	Regeln skrevs om två gånger innan den blev riktig, och båda de
	underkända formerna var samma fel i olika kläder.

	  1 · GLOBALT NÄRMASTE. Kastade allt före den närmaste smulan i
	      hela spåret. En väg som böjer tillbaka har en SENARE smula
	      närmast, och hela sträckan hon hade kvar försvann:
	      fyra smålor, den fjärde 0,5 m bort — 1 av 4 kvar.

	  2 · «NÄSTA GRANNE NÄRMARE». Samma fel, en granne i taget. En rutt
	      som böjer sig successivt tillbaka mot en eftersäpande häst
	      har fallande avstånd hela vägen — 4,00 · 3,16 · 2,24 · 0,50 —
	      och loopen gick framåt genom alla tre. Också 1 av 4.

	DET ENDA BEVISET ATT HON GÅTT EN PUNKT ÄR ATT HON HAR VARIT DÄR.
	Ingen geometrisk genväg duger: varje form av «hon är nära något
	senare» kan konstrueras till ett falskt framsteg, eftersom rutten
	själv får böja sig hur som helst. Därför `START_R`, och bara det:
	hon var framme.

	Den sista smulan gallras aldrig, så hon blir aldrig mållös. ]]
	while #spar > 1 and avstandM(spar[1], hastPos) < START_R do
		table.remove(spar, 1)
	end
end

--[[ Provets fönster in. Referensen är HÄSTENS läge, inte spelarens. ]]
function LedService._gallraSpar(spar: { Vector3 }, hastPos: Vector3)
	gallraSpar(spar, hastPos)
end

--[[ TAKET PÅ MÅLPUNKTENS AVVIKELSE (#182 del 2, arkitektens villkor).

	Målet får KROKA VÄGEN, aldrig byta mål. Ligger punkten längre än
	`MAL_AVVIK` från spelaren dras den tillbaka mot henne längs samma
	riktning — routingen behålls, men spelaren förblir destinationen.

	EGEN FUNKTION, INTE INBAKAD I `styrMot`, och det är inte kosmetik. Min
	egen falsifiering visade varför: mutationen som tog bort taket kom ut
	GRÖN, eftersom spårgrenen kräver att hästen lämnat en box och inget
	scenario i bänken nådde dit. En regel som bara går att mäta genom ett
	scenario man inte kan bygga är obevisad.

	Som ren funktion går den att pröva direkt, med vilket läge som helst.

	TAKET GÄLLER INTE RUTTHISTORIK (produktbeslut 2026-09-20).

	Mätt i Studio under M3: att BEHÅLLA smulan runt hindret räckte inte.
	Hästen på 488,6 · 184,8 fick smulan 480 · 184 — rätt väg, norr om
	Tvärvägg 1:2 — men spelaren stod 8,2 m bort, och taket drog punkten
	tillbaka längs linjen mot henne till 483,5 · 190,1. Det är SÖDER om
	väggen. Klampningen un-krokade alltså precis den omväg den säger sig
	bevara, och linjen gick genom väggen igen.

	Arkitektens villkor var att spelaren förblir den SEMANTISKA
	destinationen. En smula är en punkt spelaren själv gick på — att gå
	dit är att gå till henne, längs hennes egen väg. Villkoret hålls
	alltså bättre utan klampningen än med den.

	Funktionen själv är OFÖRÄNDRAD. Det är anroparen som avgör: ett mål
	ur spåret eller ur en planerad väg skickas utan `spelarPos`, medan
	reservpunkten bakom spelaren och dörrens delmål klampas som förr.
	Taket finns därmed kvar för allt som INTE är en gången väg. ]]
local function klampMal(mal: Vector3, spelarPos: Vector3?, y: number): Vector3
	local punkt = Vector3.new(mal.X, y, mal.Z)
	if not spelarPos then return punkt end
	local fran = Vector3.new(punkt.X - spelarPos.X, 0, punkt.Z - spelarPos.Z)
	if fran.Magnitude / M <= MAL_AVVIK then return punkt end
	local klamd = spelarPos + fran.Unit * (MAL_AVVIK * M)
	return Vector3.new(klamd.X, y, klamd.Z)
end

--[[ Provets fönster in: taket går att pröva utan att bygga ett scenario. ]]
function LedService._klampMal(mal: Vector3, spelarPos: Vector3?, y: number): Vector3
	return klampMal(mal, spelarPos, y)
end

local function styrMot(pivot: BasePart, hum: Humanoid, mal: Vector3,
	onskadFartMS: number, dt: number, rigg: { [string]: any }?,
	spelarPos: Vector3?): boolean
	--[[ Utan rigg finns ingen foljning. Det ar ett fel, inte ett lage att
		tyst falla tillbaka fran — en tyst reserv hade dolt att kontraktet
		inte holls. ]]
	if not rigg then return false end
	local drag, vrid, malfast = rigg.drag, rigg.vrid, rigg.mal
	if not (drag and vrid and malfast) then return false end

	local d = Vector3.new(mal.X - pivot.Position.X, 0, mal.Z - pivot.Position.Z)
	if d.Magnitude < 0.05 then
		drag.Enabled = false
		vrid.Enabled = false
		return false
	end

	--[[ MALET. Fastpunkten hanger kvar pa spelaren dar kontraktet sager,
		men vad den PEKAR PA ags av foljningen — normalt hennes hogra hoft,
		och brodsmulan nar en dorr ska rundas. ]]
	local punkt = klampMal(mal, spelarPos, pivot.Position.Y)
	malfast.WorldPosition = punkt

	drag.MaxVelocity = onskadFartMS * M
	drag.Enabled = true

	--[[ Hon ska peka DIT HON GAR. `CFrame.lookAt` ur riktningen, inte ur
		spelarens kropp: en hast som kopierat ryttarens vridning hade gatt
		i sidled genom dorren. ]]
	--[[ Kursen foljer den KLAMDA punkten, inte den obegransade: hon ska
		peka dit hon faktiskt dras. ]]
	local dk = Vector3.new(punkt.X - pivot.Position.X, 0, punkt.Z - pivot.Position.Z)
	if dk.Magnitude < 0.05 then dk = d end
	local kurspunkt = pivot.Position + dk.Unit
	vrid.CFrame = CFrame.lookAt(pivot.Position, kurspunkt, Vector3.yAxis)
	vrid.Enabled = true
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

		--[[ ── SAKERHETSKOPPLET: NORMAL / CATCH-UP / RELEASE ──────────

			Slappet kravde forut bara AVSTAND. En enda bildruta dar fysiken
			kastade henne — teleport, respawn, en karm — rackte darfor for
			att tappa hasten fast ingenting verkligt hant.

			Nu kravs avstand OCH tid, och emellan finns ett catch-up-lage
			dar hon far mer fart for att hinna ifatt i stallet for att
			slappas. ]]
		local avst = avstandM(rot.Position, pivot.Position)
		if avst > KOPPEL then
			l.forLangtSedan = (l.forLangtSedan or 0) + _dt
			if l.forLangtSedan >= KOPPEL_TID then
				LedService.slapp(player, "led.tappade_bort")
				continue
			end
		else
			l.forLangtSedan = 0
		end

		--[[ Har hon lämnat boxen? Mäts på FAKTISK position, inte på att
			spelaren tryckt på något. ]]
		if not l.lamnatBox then
			local x, y = tomt(pivot.Position)
			if math.sqrt((x - l.boxX) ^ 2 + (y - l.boxY) ^ 2) > 2.5 then
				l.lamnatBox = true

				--[[ SMULORNA FRÅN INNE I BOXEN FÖRBRUKAS — EN GÅNG, HÄR.

					Mätt i Studio, första divergensen efter boxutgången.
					Vänsterkolumnen är hästens signerade läge mot
					boxdörrens plan; `+` är gången och `−` är boxen:

					    häst 500,0 · 272,0  (plan +1.18)   spar = 7
					    vald smula spar[1]  494,8 · 276,7  (plan −0.56)
					    häst +1.15 → +0.93 → … → +0.19

					Smulan var spelarens gamla läge från när hon stod inne
					i boxen. Den vanliga gallringen tar bara smulor närmare
					än `START_R`; den låg 2,0 m bort, blev kvar, valdes som
					mål, och drog hästen bakåt in genom dörren hon just
					kommit ut ur.

					GALLRINGEN SKER EN ENDA GÅNG, i samma bildruta som
					`lamnatBox` går false → true.

					Ett första försök gallrade i stället varje bildruta så
					länge `lamnatBox` var sann. Det såg riktigt ut och
					rutten gick — men `dorrUt` för en box i MB-raden pekar
					österut, och HELA den södra rutten västerut ligger
					därmed på minussidan av samma plan. Gallringen åt
					alltså upp varenda ny smula i gång A, hästgången och
					ridhuset, och brödsmulefölningen var i praktiken
					avstängd resten av vägen. Mätt: 76 träffar över 7 533
					bildrutor i slutpasset. Rutten räddades av att
					planeraren tog över — inte av att spåret fungerade.

					Här kan det inte hända: efter den här bildrutan läggs
					nya smulor till som vanligt och väljs som vanligt,
					oavsett vilken sida om dörrplanet de hamnar på. Bara de
					som fanns i kön I UTGÅNGSÖGONBLICKET, och som låg på
					boxsidan, försvinner. ]]
				if l.dorrMitt and l.dorrUt then
					local kvar = {}
					for _, c in ipairs(l.spar) do
						if (c - l.dorrMitt):Dot(l.dorrUt) > 0 then
							table.insert(kvar, c)
						end
					end
					table.clear(l.spar)
					for _, c in ipairs(kvar) do table.insert(l.spar, c) end
				end

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
		--[[ ETT HOPP ÄR INGEN VÄG. Flyttas spelaren långt på en bildruta —
			respawn, en spec som ställer henne någon annanstans — är spåret
			dit inte gångbart, och hästen skulle skickas till en punkt hon
			aldrig kan nå. Då kastas spåret.

			HOPPET MÄTS MOT SPELARENS FÖRRA LÄGE, inte mot sista smulan.
			Smulan var en proxy som bara höll så länge vi antecknade var
			0,6 m. När taket pausar antecknandet (se noten nedan) blir
			avståndet till sista smulan större för varje steg, och vakten
			tömde då hela spåret fast spelaren gick något hundradels varv
			i taget. Mätt i bänken: ett varv med 6 m radie lämnade 4 smulor
			av 40. Förra läget är det vakten faktiskt menar. ]]
		local forra = l.forraSpelarPos
		if forra and (rot.Position - forra).Magnitude > 3.0 * M then
			table.clear(spar)
		end
		l.forraSpelarPos = rot.Position
		local senaste = spar[#spar]
		--[[ ══ TAKET FÅR INTE ÄTA FRAMSIDAN (reviewrond 3) ═══════════

			Raden löd `if #spar > 40 then table.remove(spar, 1) end`, och
			den tar bort FRAMSIDAN — alltid, oavsett om hon gått dit.

			Reproducerat i review: spelaren går ett varv med 6 m radie,
			hela tiden innanför kopplets 9 m, med hästen kvar i mitten.
			Varje smula ligger 6 m bort, alltså långt utanför `START_R`:
			hon har inte gått en enda. Ändå började den äldsta vägen falla
			bort så fort bufferten nått taket. Samma invariant som
			gallringen skyddar, brutet i minneshanteringen i stället.

			POLICYN: är bufferten full och framsidan oförbrukad, så slutar
			vi ANTECKNA. Minnet förblir bundet vid `SPAR_TAK`, och ingen
			väg hon har kvar att gå raderas. Att i stället kasta framsidan
			vore att påstå ett framsteg som inte hänt.

			VARFÖR DEN NYASTE ÄNDEN ÄR DEN BILLIGA ATT TAPPA: hon går
			spåret framifrån. Framsidan är hennes nästa steg; baksidan är
			det hon behöver sist. När hon förbrukar något frigörs plats och
			antecknandet börjar igen av sig självt.

			OCH VAD DET KOSTAR, utskrivet: går spelaren en omväg just medan
			bufferten är full, hamnar den omvägen inte i spåret. Då är hon
			redan så långt efter att bufferten räcker till — och då är det
			planeraren och kopplet som är skydden, inte spåret.

			`sparFullt` finns för att läget ska gå att SE i runtime i
			stället för att vara tyst. ]]
		if not senaste or (senaste - rot.Position).Magnitude > 0.6 * M then
			if #spar < SPAR_TAK then
				table.insert(spar, rot.Position)
				l.sparFullt = false
			else
				l.sparFullt = true
			end
		end
		--[[ EN SMULA HÄSTEN STÅR PÅ ÄR FÖRBRUKAD, och det gäller ÄVEN NÄR
			HON STÅR STILL.

			Mätt i Studio, mitt i stallgången: gallringen låg förut inne i
			grenen som bara körs medan hon GÅR. Hon stannade därför en gång
			med den äldsta smulan under sig, och då låg målpunkten inom
			dödzonen — vilket gjorde att hon stod kvar, vilket gjorde att
			smulan aldrig gallrades. Spelaren 6,1 m bort, hästen blickstilla,
			och ingenting i tillståndet såg trasigt ut. En lås-i-sig-själv.

			RADIEN ÄR START_R, INTE ETT MINDRE TAL, och det är hela poängen.
			Gallringen låg på 1,2 m medan hysteresen börjar gå först vid
			1,8 m. En smula i bandet däremellan var varken förbrukad eller
			värd att gå till: mätt i Studio, söder om boxraderna, stod hästen
			stilla 1,21 m från sin egen brödsmula med spelaren 6,30 m bort
			och rörde ingenting alls.

			DET ÄR NUMERA DEN ENDA GALLRINGEN. Se noten över `gallraSpar`:
			spelarens avstånd får avgöra kopplet, aldrig radera väg hon inte
			har gått än. ]]
		gallraSpar(spar, pivot.Position)

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
		--[[ ÄR MÅLET RUTTHISTORIK? Se noten över `klampMal`: en smula är
			en punkt spelaren FAKTISKT gick på, och den får inte dras
			tillämpas mot henne. Reservpunkten bakom spelaren är däremot
			härledd ur hennes blickriktning just nu och hör till taket. ]]
		local urSpar = false
		for i = 1, #spar do
			if avstandM(spar[i], rot.Position) >= FOLJ_BAKOM
				and avstandM(spar[i], pivot.Position) >= START_R then
				bakom = spar[i]
				urSpar = true
				break
			end
		end

		--[[ Så länge hon inte lämnat boxen går dörren före spåret. Steg 1
			ställer henne rakt innanför öppningen, steg 2 tar henne ut. ]]
		local viaDorr = false
		if not l.lamnatBox and l.dorr and l.dorrMitt and l.dorrUt and l.dorr.Parent then
			viaDorr = true
			local ut1 = l.dorrMitt - l.dorrUt * (1.3 * M)
			--[[ UT I GÅNGEN — INTE TVÄRS ÖVER DEN (#182).

				`ut2` låg rakt ut från dörren, 2,2 m. Mätt i Studio:

				    boxdörr MB 5      x 496,49
				    ut2               x 503,09
				    gång B            x 496,6 .. 504,3   (7,75 studs bred)
				    hästens collider  6,82 studs lång

				Delmålet låg alltså 1,2 studs från MOTSATTA radens front,
				och hon kördes rakt tvärs över en gång som är 0,9 studs
				bredare än hon är lång. Bildruta 237 i diagnosloggen:
				hästen på 500,29 · 273,98, kurs 90°, i kontakt med
				`Workspace.Anläggning.UBRF.Boxdörr E 5` — kilad tvärs i
				gången med en giltig väg hon inte kunde bära.

				Collidern är inte för grov: bara två delar kolliderar,
				`HumanoidRootPart` och `Huvudskydd`, och skyddet finns med
				flit för att huvudet inte ska gå genom väggar. Det är
				delmålet som är fel.

				Nu går andra steget ut till GÅNGENS MITT och samtidigt ett
				stycke LÄNGS gången, åt det håll hon ska. Då svänger hon
				vid dörren i stället för att köra in i väggen mitt emot —
				vilket också är så man leder en häst ut ur en box: ut, och
				sedan med i gångens riktning.

				Riktningen längs gången är dörrnormalen vriden 90°, och
				tecknet väljs efter var spelaren står. Ingen gissad
				koordinat: båda talen kommer ur dörrens egen geometri. ]]
			local langs = Vector3.new(-l.dorrUt.Z, 0, l.dorrUt.X)
			--[[ ══ TECKNET FÅR INTE AVGÖRAS AV SJU MILLIMETER ══════════════

				Mätt i Studio på `b934ddb`, och det här är den verkliga
				orsaken till att boxutgången kostade tre sekunder:

				    spelaren  −0.02 studs längs gången  ->  mot −1
				    spelaren  +0.00 studs längs gången  ->  mot +1
				    mot −1  ->  ut2 tomt (166.70, 79.87)   NORRUT
				    mot +1  ->  ut2 tomt (166.70, 77.47)   SÖDERUT

				`mot` läste spelarens läge LÄNGS gången, projicerat på
				dörrens mitt. Men den som leder en häst ut ur en box står i
				öppningen — och där är projektionen noll. Tecknet avgjordes
				alltså av fysikjitter på hundradels studs, och sköt delmålet
				1,2 m åt FEL håll lika ofta som åt rätt.

				Följden, mätt bildruta för bildruta: planeraren fick det
				norra delmålet, la en väg dit, och körde den hela vägen ut
				— hästen lämnade dörren på kurs 127,7° medan rutten bar
				≈ −6°. `mot` rättade sig visserligen själv nästa bildruta när
				spelaren gått en decimeter, men då fanns redan en giltig väg,
				och `navigerar(l)` styr mot vägpunkten och hoppar över
				delmålet. Hon gick alltså färdigt en väg till fel plats.

				Sedan kostade rättningen 133° vridning: `styrMot` sätter
				`andel = 0` över `VAND_STOPP`, så hon stod still 1,35 s och
				kröp därefter i 0,3–0,4 m/s medan spelaren gick 1,67 m/s.
				Separationen växte ~1,25 m/s och kopplet släppte på
				`led.tappade_bort` vid 9,0 m — utan att hästen gjort något
				annat än att lyda.

				RÄTTELSEN RÖR INTE geometrin, kopplet eller vridtakten. Den
				byter bara ut myntkastet mot ett stabilt tecken:

				1. står spelaren TYDLIGT åt ena hållet gäller hon, precis som
				   förr — #194:s avsikt är oförändrad där den var definierad,
				2. står hon i öppningen säger hennes läge ingenting, och då
				   används MÅLZONEN: hästen ska ledas ut åt det håll hon
				   faktiskt ska gå. Det är också så man leder en häst.
				3. finns ingen målzon behålls det gamla beteendet.

				"Tydligt" mäts ur dörrens EGEN bredd, inte ur ett valt tal:
				halva öppningen. För MB 5 är bladet 3,60 studs längs gången,
				alltså 1,80 studs. Innanför det står man i dörren. ]]
			local langsSpelare = langs:Dot(rot.Position - l.dorrMitt)
			local dorrBredd = math.abs((l.dorr :: BasePart).Size.X * langs.X)
				+ math.abs((l.dorr :: BasePart).Size.Z * langs.Z)
			local mot
			if math.abs(langsSpelare) > dorrBredd * 0.5 then
				mot = if langsSpelare >= 0 then 1 else -1
			else
				--[[ Målzonens mitt, samma omräkning som `placeraVidMal`. ]]
				local langsMal = 0
				if malzon then
					local z = malzon :: Rekt
					local mittV = Vector3.new((z.x + z.w / 2) * M, l.dorrMitt.Y,
						(TOMTDJUP - (z.y + z.h / 2)) * M)
					langsMal = langs:Dot(mittV - l.dorrMitt)
				end
				if math.abs(langsMal) > dorrBredd * 0.5 then
					mot = if langsMal >= 0 then 1 else -1
				else
					mot = if langsSpelare >= 0 then 1 else -1
				end
			end
			--[[ ══ SVÄNGEN BÖRJAR I GÅNGEN, INTE INNE I BOXEN ═════════════

				Mätt i Studio på `fe7ac37`, box MB 5 med dörren ÖPPEN,
				spelaren gående söderut:

				    öppningen längs gången   y 78,07 .. 79,27  (1,20 m)
				    ut2 (mot = +1)                (166,70 · 77,47)
				    hästen                        (164,11 · 77,56)

				    strålen häst -> ut2        BLOCKERAD av Boxfront MB 5
				                               på 1,36 m
				    strålen häst -> dörrmitt   FRI
				    strålen häst -> rakt ut     FRI
				    ut2 (mot = −1)             BLOCKERAD av bladet, 2,46 m

				Offseten LÄNGS gången är 1,2 m; öppningens HALVA bredd är
				0,60 m. Delmålet hamnar alltså alltid utanför karmen — åt
				BÅDA hållen. Det gör ingen skada så länge planeraren har en
				väg, för `navigerar(l)` styr då mot vägpunkten och rör inte
				delmålet. Men `dorrsteg` slår om till 2 redan 1,1 m innanför
				öppningen (`ut1` ligger 1,3 m in och radien är `START_R` +
				0,4), och när planeraren gett upp efter `NAV_MAX_PLANER`
				återstår bara den raka styrningen — rakt in i fronten.

				Loggen, samma körning, bildruta 1409 och framåt:

				    häst (164,11 · 77,56) kurs 88,0°  WalkSpeed 4,3
				    navVag tom · navPlaner 6 · stillaSedan 3,28 -> 7,96
				    förflyttning 1,23 m på 7,5 s medan spelaren gick 11,09

				Hon står alltså med rätt kurs, full skrittorder och noll
				hastighet tills `led.fastnat` släpper — eller, om spelaren
				hinner längre bort först, `led.tappade_bort` vid 9,0 m.

				#194 valde TECKNET på `mot` rätt. Det som fattades är att
				offseten inte får läggas på förrän hon är UTE: så leder man
				också en häst — rakt ut genom öppningen, och sedan med i
				gångens riktning. `utRakt` är dörrens egen normal och bär
				ingen gissad koordinat; `ut2` är oförändrad och gäller från
				och med det ögonblick hon passerat dörrplanet. ]]
			local utRakt = l.dorrMitt + l.dorrUt * (1.2 * M)
			local ut2 = utRakt + langs * (mot * 1.2 * M)
			local igenomDorren = (pivot.Position - l.dorrMitt):Dot(l.dorrUt) > 0
			--[[ DELMÅLET SKA NÅS, OCH DET KRÄVER EN RADIE UTANFÖR DÖDZONEN.
				Radien stod på 0,9 m medan hysteresen börjar gå först vid 1,8 m:
				mätt i Studio hamnade hästen 0,98 m från punkten, alltså i
				glappet mellan "för nära för att gå" och "för långt för att
				vara framme", och stod där. Radien måste vara större än
				START_R, annars finns bandet kvar. ]]
			--[[ Dörrens delmål är inte en smula. Det är härlett ur dörrens
				egen geometri, ligger några meter bort, och taket är därför
				oförändrat här — det löser ändå aldrig ut på de avstånden. ]]
			urSpar = false
			if l.dorrsteg == 1 then
				if avstandM(pivot.Position, ut1) < START_R + 0.4 then
					l.dorrsteg = 2
				else
					bakom = ut1
				end
			end
			if l.dorrsteg == 2 then
				bakom = if igenomDorren then ut2 else utRakt
			end
		end
		--[[ Delmålet som faktiskt styr henne, synligt för prov och för den
			som mäter i runtime. Utan det gick fyndet ovan bara att se som
			ett symtom: rätt kurs, full fart, noll förflyttning. ]]
		l.delmal = bakom
		local tillMal = avstandM(pivot.Position, bakom)

		--[[ Hon får skynda på inom SKRITTENS eget band när hon hamnat
			efter. Bandet kommer ur `Gaits`; hon börjar aldrig trava.

			FARTEN SKRIVS INTE HAR. Den lamnas till `styrMot`, som satter
			den som `MaxVelocity` pa `AlignPosition`. Forut sankte `styrMot`
			ocksa farten vid stora kursfel, for att `Humanoid:Move` skot
			kroppen rakt fram oavsett hur den stod. `AlignOrientation`
			vrider henne kontinuerligt medan hon dras, sa den troskeln
			behovs inte langre. ]]
		--[[ ── KOPPLETS TRE LAGEN, UTTRYCKLIGA ────────────────────────

			NORMAL    under CATCHUP_R: skrittfart, hon foljer lugnt.
			CATCH-UP  over CATCHUP_R: farten rampas mot gangartens max sa
					  att hon hinner ifatt i stallet for att slappas.
			RELEASE   ligger ovan, pa avstand OCH tid.

			Rampen ar mjuk med flit: ett troskelhopp hade gett ett ryck i
			`MaxVelocity` mitt i en skritt. ]]
		local gang = Gaits.DATA and Gaits.DATA.walk
		local normalfart = (gang and gang.norm) or 1.45
		local maxfart = (gang and gang.max) or 2.0
		--[[ ── DET HAR VAR VARFOR HON INTE FOLJDE (QA 2026-09-17) ──────

			Matt i Studio: spelaren gick 11,5 studs pa tre sekunder, hasten
			1,0. Draget var pasalaget hela tiden, hon var oankrad, rorde
			ingenting och en ren `AlignPosition` flyttade henne utan
			problem. Det var inte kraften, inte humanoiden och inte
			geometrin.

			DET VAR ARITMETIKEN. `borja` ger spelaren `skrittfart() * 1.15`
			= 5,0 studs/s sa att hon ska kunna ga fore utan att hasten
			halkar efter. Hastens `MaxVelocity` var samtidigt skrittfarten
			sjalv, 4,35 studs/s. Spelaren var alltsa PER KONSTRUKTION 15 %
			snabbare an hastens tak — hon kunde inte hinna ifatt, bara
			tappa mark, tills kopplet slappte.

			I den gamla aktueringen doldes det: `WalkSpeed` var en onskan
			som humanoiden fick overskrida i praktiken. En `MaxVelocity` ar
			ett HART tak, och da blev marginalen till en spärr.

			TVA RATTELSER:

			  1. Hastens tak far aldrig understiga spelarens ledningstakt.
			     Marginalen ska ligga hos HENNE, inte mot henne.
			  2. Catch-up borjar vid foljavstandet, inte vid 5 m. Att vanta
			     tills hon ar 15 studs efter ar att vanta tills det redan
			     ser trasigt ut. ]]
		local lag = math.clamp((avst - FOLJ_BAKOM) / (CATCHUP_R - FOLJ_BAKOM), 0, 1)
		l.kopplingslage = if lag > 0 then "catchup" else "normal"
		local onskadFart = normalfart + lag * (maxfart - normalfart)
		--[[ GOLVET: aldrig langsammare an den som leder henne. ]]
		onskadFart = math.max(onskadFart, LEDNINGSTAKT * normalfart)

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
		l.ankartid = (l.ankartid or 0) + _dt
		--[[ ANKARET HAR EN TAKT, INTE BARA EN RADIE (M3, hela ledrutten).

			Mätt i Studio under hela rutten box E 8 -> ridhuset, tre pass med
			samma utfall. Hon växlade mellan att följa i 5,74 studs/s och att
			KRYPA:

			    11,9 -> 15,5 s   hasten 2,2 studs     = 0,6 studs/s
			                     spelaren 17 studs    = 4,7 studs/s
			    draget            på, MaxVelocity 6,00
			    stillaSedan       0,0  0,4  0,1  0,6  1,2  0,1  0,0

			Radien är 0,25 m. En krypning på 0,2 m/s lämnar den på 1,25 s och
			NOLLSTÄLLER därmed stillaståendet strax innan NAV_STILLA nås. Hon
			räknades alltså som GÅENDE medan hon förlorade fyra studs i sekunden
			mot den som ledde henne. Planeraren kopplades aldrig in, och kopplet
			släppte på `led.tappade_bort` vid waypoint 41 av 94.

			FÖRFLYTTNINGEN ÄR FORTFARANDE MÅTTET — en ankrad häst rapporterade
			1,59 studs/s utan att röra sig, och det är därför ankaret finns.
			Det som saknades var att förflyttningen också måste ske i NÅGON takt.
			Tiden det tog att lämna ankaret jämförs därför med tiden hon fick på
			sig vid `NAV_TAKT` av den fart hon FAKTISKT beordrats hålla. Hann hon
			det är hon i rörelse och klockan nollställs som förr; hann hon inte
			flyttas ankaret ändå — hon är ju någon annanstans — men klockan får
			gå vidare, så en krypning inte längre kan köpa sig fri en gång per
			radie. Tröskeln är RELATIV till ordern och inte ett valt tal: går hon
			långsamt för att hon beordrats långsamt räknas hon fortfarande som
			gående. ]]
		if l.badGa then
			if avstandM(pivot.Position, l.ankare) > NAV_ANKARE then
				local budget = NAV_ANKARE / math.max(onskadFart * NAV_TAKT, 0.01)
				local holltTakten = l.ankartid <= budget
				l.ankare = pivot.Position
				l.ankartid = 0
				if holltTakten then l.stillaSedan = 0 end
			else
				l.stillaSedan += _dt
			end
		else
			l.ankare = pivot.Position
			l.ankartid = 0
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
			--[[ Reserven är SPELARENS EGEN punkt: hon leder hästen, alltså
				står hon på gångbar yta. Höjden tas ur hästen, precis som
				för huvudmålet, så att båda snappar mot samma navmesh. ]]
			planera(l, pivot,
				Vector3.new(bakom.X, pivot.Position.Y, bakom.Z),
				Vector3.new(rot.Position.X, pivot.Position.Y, rot.Position.Z))
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
				--[[ En vägpunkt är också rutthistorik — planeraren har lagt den
					runt hindret. Klampas den mot spelaren un-krokas omvägen,
					och det är samma fel som spelaravståndsgallringen gjorde. ]]
				l.badGa = styrMot(pivot, hum, Vector3.new(w.X, pivot.Position.Y, w.Z),
					onskadFart, _dt, l.rigg, nil)
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
				--[[ DODZONEN SLACKER REGULATORERNA. Att bara sluta flytta
					malet hade latit `AlignPosition` fortsatta dra mot den
					sista punkten — och da star hon och skjuter mot den
					for evigt. Hysteresen ar mellan STOPP_R och START_R. ]]
				if l.rigg then
					if l.rigg.drag then l.rigg.drag.Enabled = false end
					if l.rigg.vrid then l.rigg.vrid.Enabled = false end
				end
			else
				--[[ CATCH-UP. Har hon halkat efter far hon mer fart — inte
					en annan gangart, bara ratt att ta igen. Kopplet haller.
					Regeln ar samma i bada grenarna nedan. ]]
				l.badGa = styrMot(pivot, hum, Vector3.new(bakom.X, pivot.Position.Y, bakom.Z),
					onskadFart, _dt, l.rigg, if urSpar then nil else rot.Position)
			end
		else
			if tillMal > START_R then
				l.gar = true
				l.badGa = styrMot(pivot, hum, Vector3.new(bakom.X, pivot.Position.Y, bakom.Z),
					onskadFart, _dt, l.rigg, if urSpar then nil else rot.Position)
			end
		end
	end
end

function LedService.start()
	Net.get("LedSync")

	Net.get("LedBorja").OnServerInvoke = Skopa.grind("LedBorja",
		function(player, modell)
			local hak = hakar.ratt
			local ratt = hak and hak(player, nil :: any) or nil
			return LedService.borja(player, modell, ratt)
		end)
	Net.get("LedSlapp").OnServerInvoke = Skopa.grind("LedSlapp",
		function(player)
			return LedService.slapp(player)
		end)

	Players.PlayerRemoving:Connect(LedService.lamnar)

	RunService.Heartbeat:Connect(steg)
	print("[Led] Ledningen igång")
end

--[[ ── DEN SOM LÄMNAR (#252 DEL C) ──────────────────────────

	Samma skäl som `GameplayService.lamnar`: städningen efter en spelare
	som går är en av de fyra saker runtime-grinden ska kunna falla på,
	och den måste då kunna köras genom produktionens EGEN handlare i
	stället för genom en kopia av den. ]]
function LedService.lamnar(player: Player)
	if ledd[player] then LedService.slapp(player, "led.tappad") end
	--[[ Städningen läser MINNET, inte den aktiva ledningen: kopplet har
		oftast släppt långt innan spelaren stänger spelet. ]]
	LedService.aterstallTillBox(senasteLedning[player])
	senasteLedning[player] = nil
	--[[ Bokföringen är sessionsbunden och hör till spelaren som gick.
		Lämnas den kvar läcker den, och nästa spelare på samma
		Player-objekt hade ärvt någon annans framsteg. ]]
	uppnatt[player] = nil
end

--[[ Den som äger tilldelningen (GameplayService) lämnar en krok som
	svarar VILKEN häst spelaren får leda. Tjänsten slår inte upp det
	själv: då hade den behövt känna till skötseln. ]]
function LedService.satRattHastKrok(f: ((Player, Model?) -> Model?)?)
	hakar.ratt = f :: any
end

--[[ RIDS HON JUST NU? Samma monster och samma skal som kroken ovan:
	`HorseService` ager sessionerna, och `LedService` ska inte behova
	kanna till uppsittningen for att veta att en hast med ryttare inte
	gar att leda.

	EN KROK OCH INTE ETT REQUIRE, for att tjansternas ordning i
	bankarna da hade blivit ett dolt beroende. `GameplayService` kanner
	redan bada och kopplar ihop dem.

	Regeln ar verklig: pa en uppsutten hast sitter redan nagon, och
	ingen leder en hast som bars av en ryttare. ]]
function LedService.satRidenKrok(f: ((Model) -> boolean)?)
	hakar.riden = f :: any
end

--[[ ETT TRYCK, INTE TVA (#182, PO-beslut efter QA 2026-09-17).

	Spelaren tryckte «Led», och ingenting hande: hasten star i sin box
	bakom en STANGD dorr, och dorren ar ett eget tryck pa en egen
	prompt. Matt i Studio stod draget avstangt i 120 bildrutor av 120 —
	hon drevs aldrig, och inget pa skarmen forklarade varfor.

	Att oppna boxdorren ar inte ett eget beslut nar man ska leda ut
	henne. Det ar samma handling: man oppnar dorren OCH tar henne ut.
	Servern gor darfor bada nar ledningen borjar.

	EN KROK OCH INTE ETT REQUIRE, av samma skal som de tva ovan:
	`DorrService` ager dorrarna, och `LedService` ska inte behova kanna
	till dem for att kunna leda. `GameplayService` kanner bada.

	GEOMETRIN AR INTE PROBLEMET, och det ar matt: oppningen ar 3,60
	studs (1,20 m) och hasten 1,86 studs (0,62 m) bred — nastan en
	hastbredd fri pa var sida. En OPPEN dorr har dessutom redan
	`CanCollide = false`. Det var den STANGDA dorren som holl henne. ]]
function LedService.satDorrKrok(f: ((BasePart) -> boolean)?)
	hakar.dorr = f :: any
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
