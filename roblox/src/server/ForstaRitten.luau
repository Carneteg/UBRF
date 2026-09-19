--!strict
--[[ FIRST RIDE — hästen i rörelse inom trettio sekunder.

	#263 Gate 2A.

	══ SPELARPROBLEMET ═══════════════════════════════════════════════

	Vi har byggt en ridkärna och vet inte om den är rolig, för ingen
	kommer fram till den. Vägen på basen, läst i källan:

	    spawn vid stallentrén → hitta rätt box → interagera →
	    `RidaNu` förbereder → häst och spelare hamnar i ridhuset →
	    uppsittningsprompt → rida

	Flera minuter för någon som inte vet var boxen är. Kravet i #261
	§2.1 är trettio sekunder.

	══ VAD DEN HÄR MODULEN INTE GÖR ══════════════════════════════════

	Den skriver ingen ridlogik, äger ingen gångart, rör ingen fysik och
	har ingen egen uppsittningsregel. Ingen rad här kan sätta en spelare
	i sadeln — det gör `HorseService.tryMount`, genom `farSittaUpp`, som
	alla andra vägar.

	Den skriver framför allt **inte** att stallskötseln är gjord. Det är
	orderns skarpaste krav, och det är också varför `GameplayService.ridaNu`
	inte duger som First Ride-väg: den blir redo genom att bocka av varje
	moment med utföraren `"auto"`. Rätt för «Rida nu», där spelaren står
	vid hästen och ber stallet om hjälp — förbjudet här.

	Efter en First Ride står hennes checklista alltså **orörd och
	ogjord**. Stallkedjan väntar kvar på henne; den är inte bortskriven,
	bara flyttad bakom det första beviset på att ritten är rolig.

	══ MEN HÄSTEN ÄR FAKTISKT FÖRBEREDD ══════════════════════════════

	Sadel, underlägg och träns sätts på riktigt genom `TackService`, på
	den kanoniska tilldelade hästen. Det är inte en formalitet:
	`farSittaUpp` avslutas med `TackService.ridklar(modell)`, som läser
	MODELLEN och inte ett tillstånd — så en ospadlad häst går inte att
	sitta upp på ens här.

	Och kanon är entydig: hästen ska alltid vara korrekt och säkert
	förberedd när ritten börjar oavsett vem som gjorde arbetet, och
	spelet får aldrig lära ut fel hästhantering för att spara tid. En
	First Ride på en osadlad häst hade brutit båda.

	══ VILLKORET KOMMER UR SPARNINGEN ════════════════════════════════

	`save.pass == 0` — inga avslutade pass. Ingen ny sparflagga, för
	`Sparning` räknar redan, och `registreraPass` är det som gör en ritt
	genomförd. En återkommande spelare får stallvägen.

	Villkoret är serverägt hela vägen: klienten skickar ingenting, och
	det finns ingen remote att skicka det på.
]]

local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Sparning = require(ReplicatedStorage.HorseCore.Sparning)
local Gaits = require(ReplicatedStorage.HorseCore.Gaits)

local SparService = require(script.Parent.SparService)
local GameplayService = require(script.Parent.GameplayService)
local HorseService = require(script.Parent.HorseService)
local LedService = require(script.Parent.LedService)
local TackService = require(script.Parent.TackService)

local ForstaRitten = {}

--[[ Hur nära hästen spelaren ställs innan stallet börjar arbeta. Tre
	studs på hästens vänstra sida — samma plats `stallFram` ställer
	henne på, och samma sida man leder ifrån. ]]
local VANSTER = 3

--[[ Utrustningen i den ordning en människa gör det: underlägget först,
	sedan sadeln, sist tränset. Ordningen är inte kosmetik — den är
	samma som `GameplayService.sadla` håller, och `TackService.satPa`
	nekar en sadel på en häst utan underlägg. ]]
local UTRUSTNING = { "underlagg", "sadel", "trans" }

export type Utfall = {
	ok: boolean,
	steg: string,
	skal: string?,
}

--[[ ══ TELEMETRIN ═══════════════════════════════════════════════════

	Diagnostik för QA, inte en spelar-HUD (#263). Den svarar på de fem
	frågor gaten faktiskt avgörs av, och ingenting mer. Tiderna räknas
	från att karaktären är spelklar — inte från serverstart, för det är
	spelarens väntan som mäts. ]]
export type Matning = {
	spelKlar: number,
	forstaRorelse: number?,
	forstaOvergang: number?,
	styrtVanster: boolean,
	styrtHoger: boolean,
	bromsat: boolean,
	suttitAv: boolean,
}

local matning: { [Player]: Matning } = {}
local startad: { [Player]: boolean } = {}

--[[ ══ SKYDD 8: VARIFRAN KLOCKAN GAR ═══════════════════════════════

	Arkitekturbeslutet ar uttryckligt: 30-sekundersmalet far inte kunna
	goras gront genom att starta klockan sent. Forsta utkastet gjorde
	precis det — det satte `start` NAR UPPSITTNINGEN LYCKATS, sa
	"tid till forsta rorelse" mätte bara tiden fran sadeln till forsta
	tangenttryckningen. Det hade alltid varit gront.

	`spelKlar` sats nu NAR SPELAREN HADE KUNNAT BORJA GA: saven laddad,
	karaktaren pa plats, hasten hittad. Allt First Ride sjalv gor —
	framstallning, utrustning, placering, uppsittning — ligger INNANFOR
	matningen och raknas mot malet.

	Varldsbygget redovisas SEPARAT och ingar inte. Det ar inte fusk:
	bygget sker en gang per server, fore spelaren finns, och att lagga
	det pa hennes konto hade gjort malet omojligt av fel skal. Men det
	ska SYNAS, for en spelare som vantar nittio sekunder pa en varld
	bryr sig inte om vilken halva som var langsam. ]]
local varldsbyggeSekunder: number? = nil

function ForstaRitten.satVarldsbygge(sekunder: number)
	varldsbyggeSekunder = sekunder
end

function ForstaRitten.varldsbygge(): number?
	return varldsbyggeSekunder
end

--[[ Injicerbar av samma skäl som `Skopa`s: bänken har ingen riktig tid,
	och en tidsmätning som inte går att mäta är ett påstående. ]]
local klocka: () -> number = os.clock

function ForstaRitten._satKlockaForProv(fn: (() -> number)?)
	klocka = fn or os.clock
end

--[[ ── VILLKORET ────────────────────────────────────────────────────

	Ur beständig sparning, aldrig ur ett klientargument. Faller
	sparningen svarar den `false`: en spelare vars datalager inte gick
	att läsa ska INTE få First Ride, för då vet vi inte om hon ridit
	förut, och att gissa åt det hållet skriver över någons progression
	med en nybörjarupplevelse. Fail closed åt rätt håll. ]]
function ForstaRitten.galler(player: Player): boolean
	--[[ SKYDD 1 (arkitekturbeslutet): laddningen ska vara UTTRYCKLIGT
		klar. `save == nil` rackte inte — en oladdad spelare och en
		spelare utan pass ser likadana ut har nere, och den forvaxlingen
		hade gjort `pass == 0` till standardsvaret under hela laddningen.
		`redo` ar SparServices egen barriar och sags ja forst efter att
		lasningen returnerat, aven nar den foll. ]]
	if not SparService.redo(player) then return false end
	local save = SparService.save(player)
	if save == nil then return false end
	local ok, svar = pcall(function()
		return Sparning.aktuelltPass(save) == 1
	end)
	return ok and svar == true
end

function ForstaRitten.matningFor(player: Player): Matning?
	return matning[player]
end

function ForstaRitten.kvarvarande(): number
	local sedda: { [Player]: boolean } = {}
	local n = 0
	for p in pairs(matning) do
		if not sedda[p] then sedda[p] = true; n += 1 end
	end
	for p in pairs(startad) do
		if not sedda[p] then sedda[p] = true; n += 1 end
	end
	return n
end

--[[ FORHANDSDEKLARERAD. Observatoren bor langre ned — den hor ihop
	med telemetrin och inte med starten — men `starta` vacker den. Utan
	den har raden hade `vaxKnapp` varit en global `nil` vid anropet, och
	slingan hade aldrig startat. ]]
local vaxKnapp: () -> ()

--[[ Ställer spelaren vid hästens vänstra sida. ]]
local function stallVidHasten(player: Player, modell: Model): boolean
	local karaktar = player.Character
	local hrp = karaktar and karaktar:FindFirstChild("HumanoidRootPart")
	if not (hrp and hrp:IsA("BasePart")) then return false end
	local pivot = modell.PrimaryPart or modell:FindFirstChildWhichIsA("BasePart")
	if not pivot then return false end
	(hrp :: BasePart).CFrame = pivot.CFrame * CFrame.new(-VANSTER, 0, 0)
	return true
end

--[[ Stallet gör i ordning henne. FYSISKT, och fail closed: faller ett
	steg avbryts hela förberedelsen, för en halvsadlad häst är precis
	det tillstånd `ridklar` finns för att stoppa. ]]
local function forbered(player: Player, modell: Model): (boolean, string?)
	local hastId = tostring(modell:GetAttribute("HorseId") or "")
	if hastId == "" then return false, "spel.ingen_hast" end
	for _, typ in ipairs(UTRUSTNING) do
		if not TackService.harTack(modell, typ) then
			local ok, skal = TackService.satPa(player, modell, typ, hastId, modell)
			if not ok then return false, skal end
		end
	end
	--[[ VÄRLDEN ÄR FACIT, inte den här loopen. Samma rad som
		`farSittaUpp` avslutas med, ställd redan här så att ett halvt
		bygge upptäcks där det uppstod. ]]
	return TackService.ridklar(modell)
end

--[[ ── HELA FIRST RIDE ──────────────────────────────────────────────

	`Utfall` bär VILKET led som föll. Fem led utan det hade gett en
	Studio-logg som bara säger "det gick inte". ]]
function ForstaRitten.starta(player: Player): Utfall
	if startad[player] then
		return { ok = false, steg = "redan_startad" }
	end
	if not ForstaRitten.galler(player) then
		return { ok = false, steg = "inte_forsta_ritten" }
	end

	--[[ KLOCKAN STARTAR HAR. Se noten vid `varldsbyggeSekunder`: allt
		First Ride sjalv gor ligger innanfor matningen. ]]
	matning[player] = {
		spelKlar = klocka(),
		styrtVanster = false, styrtHoger = false,
		bromsat = false, suttitAv = false,
	}

	--[[ 1. HÄSTEN. `bind` är enda vägen till modellen och hänger på att
		sparningen landat — därför är hela modulen hakad på
		`efterLaddning` och inte på `PlayerAdded`. ]]
	local modell = GameplayService.bind(player)
	if not modell then
		return { ok = false, steg = "ingen_hast" }
	end

	--[[ 2. ÄR VÄRLDEN HEL? SKYDD 4, och ordningen är hela poängen.
		Prövningen ligger FORE teleporten: faller den efterat star
		spelaren ensam i ett ridhus utan hast, och arkitekturbeslutet
		sager uttryckligen att en spelare aldrig ska teleporteras till
		ett trasigt lage.

		Sitsen ar det som faktiskt satter henne upp — `tryMount` gor
		`seat:Sit(humanoid)` — sa en rigg utan sits ar en rigg det inte
		gar att rida, hur ratt allt annat an ser ut. ]]
	local sess = HorseService.sessionFor(modell)
	if sess == nil then
		return { ok = false, steg = "hasten_oregistrerad" }
	end
	local sits = (sess :: any).rig ~= nil and (sess :: any).rig.seat or nil
	--[[ SITSEN SKA FINNAS I HASTEN, inte bara i sessionens rigg-tabell.
		En sits som rivits ur varlden ar fortfarande ett objekt dar —
		referensen lever, delen gor det inte — och `tryMount` gor
		`seat:Sit(humanoid)` pa den. En foraldralos sits satter ingen i
		sadeln.

		Uppslaget gors mot MODELLEN och inte mot `sits.Parent`, for det
		ar den enda formen som betyder samma sak i motorn och i banken:
		Robloxs `Destroy` nollar foraldern, bankens stub river bara
		barnet ur `_barn`. Att fraga hasten om hon fortfarande har sin
		sits ar sant i bada. ]]
	local sitsNamn = sits ~= nil and tostring((sits :: any).Name) or nil
	if sits == nil or sitsNamn == nil
		or modell:FindFirstChild(sitsNamn) ~= sits then
		return { ok = false, steg = "riggen_saknar_sits" }
	end
	if LedService.malzon() == nil then
		return { ok = false, steg = "ingen_ridhuszon" }
	end

	--[[ 3. FRAM TILL RIDHUSET. `stallFram` flyttar både häst och
		ryttare, men bokför INGENTING — se noten där. Hon har inte lett
		henne, och det ska hennes `leda`-fas fortsätta att veta. ]]
	local framme, framfel = LedService.stallFram(player, modell)
	if not framme then
		return { ok = false, steg = "kom_inte_till_ridhuset", skal = framfel }
	end

	--[[ 4. FÖRBEREDELSEN. Fysisk, inte bokförd. ]]
	local redo, redofel = forbered(player, modell)
	if not redo then
		return { ok = false, steg = "forberedelsen_foll", skal = redofel }
	end

	--[[ 5. INTILL HENNE. `tryMount` kräver `MountRange`, och efter
		`stallFram` står hon redan där — men utrustningsbygget kan ha
		flyttat pivoten, så avståndet stängs om. ]]
	if not stallVidHasten(player, modell) then
		return { ok = false, steg = "ingen_karaktar" }
	end

	--[[ 6. UPP. Samma `tryMount` och samma `farSittaUpp` som alla
		andra. Nekas den sitter ingen upp — inte heller här. ]]
	local uppe, mskal, marg = HorseService.tryMount(player, modell)
	if not uppe then
		--[[ Ingen ritt, ingen matning. En halv matning hade sett ut som
			en ritt som aldrig kom igang. ]]
		matning[player] = nil
		return { ok = false, steg = "uppsittningen_nekades",
			skal = tostring(mskal or marg or "") }
	end

	startad[player] = true
	vaxKnapp()
	return { ok = true, steg = "uppsutten" }
end

--[[ ══ OBSERVATOREN ═══════════════════════════════════════════════

	Telemetrin lases ur VARLDEN, inte ur klienten.

	Det ar inte forsiktighet for sakerhets skull — det ar den enda vag
	som faktiskt kan svara. Servern tar inte emot nagon yaw: `StateSync`
	bar sedan #233 Fas 4b ETT argument, farten, och ingenting annat. Att
	fraga klienten hade krävt en ny remote, alltsa en ny klientyta att
	validera, for nagot som bara ar diagnostik.

	Hasten sjalv vet allt vi behover:

	  RORELSE      pivotens position andras mer an `RORELSE_TROSKEL`
	  STYRNING     pivotens yaw andras at vanster respektive hoger
	  OVERGANG     `Gait`-attributet byter varde — serverns egen
	               replikering, skriven av `replikera`
	  BROMS        gangarten gar NEDAT i trappan

	Ingen av dem gar att forfalska fran en klient, och ingen av dem
	kravde en rad ny kod i `HorseService`.

	Slingan lever bara medan nagon faktiskt mats. Ar `matning` tom
	kopplar den bort sig sjalv — samma monster som
	`CameraController`s sjalvdisconnectande vakt. ]]

local RunService = game:GetService("RunService")

--[[ Studs. Under det ar det mätbrus och sadelryck, inte en hast som
	gar nagonstans. ]]
local RORELSE_TROSKEL = 1.5
--[[ Radianer. Ungefar sex grader — mindre an sa ar inte ett styrval. ]]
local YAW_TROSKEL = 0.1
local TAKT = 0.1

type Prov = { pos: Vector3, yaw: number, gait: string }
local forra: { [Player]: Prov } = {}
local slinga: RBXScriptConnection? = nil

local function yawAv(cf: CFrame): number
	local _, y = cf:ToOrientation()
	return y
end

--[[ Gangartens plats i trappan, for att kunna se NEDAT. Lases ur
	kanonen och inte ur en egen lista. ]]
local function index(gait: string): number
	local ok, i = pcall(function() return Gaits.index(gait) end)
	return if ok and type(i) == "number" then i else -1
end

local function observera(player: Player, m: Matning)
	local modell = HorseService.horseOf(player)
	if modell == nil then return end
	local pivot = modell.PrimaryPart or modell:FindFirstChildWhichIsA("BasePart")
	if pivot == nil then return end

	local nu: Prov = {
		pos = pivot.Position,
		yaw = yawAv(pivot.CFrame),
		gait = tostring(modell:GetAttribute("Gait") or "halt"),
	}
	local f = forra[player]
	forra[player] = nu
	if f == nil then return end

	if m.forstaRorelse == nil and (nu.pos - f.pos).Magnitude > RORELSE_TROSKEL then
		m.forstaRorelse = klocka() - m.spelKlar
		print(("[FirstRide] %s: forsta hastrorelse efter %.1f s")
			:format(tostring(player.Name), m.forstaRorelse))
	end

	local dyaw = nu.yaw - f.yaw
	--[[ Runt +-pi hoppar yaw. Ett hopp ar ingen styrning. ]]
	if math.abs(dyaw) < math.pi then
		if dyaw > YAW_TROSKEL then m.styrtVanster = true end
		if dyaw < -YAW_TROSKEL then m.styrtHoger = true end
	end

	if nu.gait ~= f.gait then
		if m.forstaOvergang == nil then
			m.forstaOvergang = klocka() - m.spelKlar
			print(("[FirstRide] %s: forsta gangartsovergang efter %.1f s (%s -> %s)")
				:format(tostring(player.Name), m.forstaOvergang, f.gait, nu.gait))
		end
		local fore, efter = index(f.gait), index(nu.gait)
		if fore >= 0 and efter >= 0 and efter < fore then
			m.bromsat = true
		end
	end
end

local function driv()
	local nagon = false
	for player, m in pairs(matning) do
		nagon = true
		observera(player, m)
	end
	if not nagon and slinga ~= nil then
		slinga:Disconnect()
		slinga = nil
	end
end

function vaxKnapp()
	if slinga ~= nil then return end
	local samlat = 0
	slinga = RunService.Heartbeat:Connect(function(dt: number)
		samlat += dt
		if samlat < TAKT then return end
		samlat = 0
		driv()
	end)
end

--[[ Provkrok: banken har ingen Heartbeat att lita pa, och ett prov ska
	kunna stega observationen sjalvt. ]]
function ForstaRitten._observeraForProv()
	driv()
end

function ForstaRitten.noteraAvsittning(player: Player)
	local m = matning[player]
	if not m then return end
	m.suttitAv = true
	print(("[FirstRide] %s satt av — rorelse %s, overgang %s, styrt %s, bromsat %s")
		:format(tostring(player.Name),
			if m.forstaRorelse then ("%.1f s"):format(m.forstaRorelse) else "aldrig",
			if m.forstaOvergang then ("%.1f s"):format(m.forstaOvergang) else "aldrig",
			if m.styrtVanster and m.styrtHoger then "bada hall"
				elseif m.styrtVanster or m.styrtHoger then "ett hall" else "nej",
			if m.bromsat then "ja" else "nej"))
end

function ForstaRitten.glom(player: Player)
	startad[player] = nil
	matning[player] = nil
	forra[player] = nil
end

function ForstaRitten._nollstallForProv()
	startad = {}
	matning = {}
	forra = {}
	if slinga ~= nil then
		slinga:Disconnect()
		slinga = nil
	end
end

function ForstaRitten.start()
	--[[ Kroken som öppnar mount-grindens First Ride-gren. Den svarar ur
		sparningen och tar inget klientargument. ]]
	GameplayService.satForstaRitten(function(player: Player, _modell: Model): boolean
		--[[ Under själva `starta` är `startad` ännu inte satt — det sätts
			först efter att `tryMount` lyckats. Grenen ska alltså vara
			öppen för den som HÅLLER PÅ med sin första ritt, och stängd
			för alla andra. ]]
		return ForstaRitten.galler(player)
	end)

	Players.PlayerRemoving:Connect(ForstaRitten.glom)

	--[[ SKYDD 6 (arkitekturbeslutet): avsittning river sessionsstatus
		utan att skriva nagon progression.

		Standard ar JA pa fragan om en spelare som avbryter ska erbjudas
		First Ride igen, och det foljer av sig sjalvt: `pass` okar bara
		genom `GameplayService.avslutaPass`, som ar fail closed mot varje
		eftervardsmoment. En First Ride-spelare som sitter av har inte
		gjort eftervarden, sa hennes `pass` star kvar pa noll — och da
		sager `galler` fortfarande ja vid nasta respawn.

		Att nolla `startad` ar det som gor den andra chansen mojlig.
		Utan det hade hon suttit av en gang och sedan statt till fots i
		ett ridhus utan vag tillbaka. ]]
	HorseService.lyssnaRyttare(function(player: Player, sitter: boolean)
		if sitter then return end
		ForstaRitten.noteraAvsittning(player)
		startad[player] = nil
		matning[player] = nil
		forra[player] = nil
	end)

	SparService.efterLaddning(function(player: Player)
		if player.Character then
			ForstaRitten.rapportera(player, ForstaRitten.starta(player))
		end
		player.CharacterAdded:Connect(function()
			--[[ En respawn MITT I en ritt ska inte sätta upp henne igen.
				Ett nytt försök efter en misslyckad start ska den däremot
				få — `startad` sätts bara vid lyckad uppsittning. ]]
			if startad[player] then return end
			ForstaRitten.rapportera(player, ForstaRitten.starta(player))
		end)
	end)

	print("[FirstRide] First Ride igång")
end

--[[ Enda vägen att se i Studio VAR en First Ride föll, och gaten avgörs
	i Studio och på en iPad — inte i bänken. ]]
function ForstaRitten.rapportera(player: Player, utfall: Utfall)
	if utfall.ok then
		print(("[FirstRide] %s sitter upp"):format(tostring(player.Name)))
	elseif utfall.steg == "inte_forsta_ritten" or utfall.steg == "redan_startad" then
		--[[ Inga fel. Att varna om dem vore brus — de är det normala för
			varje spelare som ridit förut. ]]
	else
		warn(("[FirstRide] %s fick ingen ridstart: %s%s"):format(
			tostring(player.Name), utfall.steg,
			if utfall.skal and utfall.skal ~= "" then " (" .. utfall.skal .. ")" else ""))
	end
end

return ForstaRitten
