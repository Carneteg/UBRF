--!strict
--[[
	GÅNGEN I BENEN — procedurell, och därför vår egen.

	══ VARFÖR INTE KÖPTA ANIMATIONER ══════════════════════════════════

	K3 kom med tre publicerade animationer: `Idle 5278859309`,
	`Walk 5278868188`, `Run 5278865536`. De ligger på en annan skapares
	konto. Försvinner de, eller modereras de bort, står trettiotre hästar
	stilla i en produktion där Roblox är primär plattform. Hästens
	kärnrörelse får inte hänga på någon annans assets.

	Så benen drivs härifrån i stället. Ingen `AnimationId`, inget konto att
	vara beroende av.

	══ VARFÖR FASEN INTE LÄNGRE LÄSER POSITIONEN DIREKT ═══════════════

	Första versionen stegade fasen med hästens förflyttning mellan två
	bildrutor. Det var rätt tänkt — foten ska följa marken — men fel mätt.

	Uppmätt under ledning, 439 bildrutor:

	    bildrutor utan rörelse       152 av 439  (35 %)
	    rotens flytt per bildruta    median 0,066 studs, MAX 0,319  (4,9x)
	    bogleden per bildruta        median 0,87°,  MAX 9,73°       (11,2x)

	Hästen leds av SERVERN, och hennes läge kommer till klienten i hopp.
	En fas som läser det hoppet rakt av FÖRSTÄRKER det: en tredjedel av
	bildrutorna stod benen still, och nästa ruta hoppade leden nästan tio
	grader. Det var inte fasen som var fel utan att den läste en trappa som
	om den vore en ramp.

	Nu lågpassfiltreras FARTEN, och fasen stegas med `fart * dt`. Foten
	följer fortfarande marken i snitt — hon går inte fortare än hon färdas
	— men en hoppig inmatning ger inte längre en hoppig utmatning.

	Dessutom filtreras varje led mot sitt MÅL i stället för att skrivas
	rakt på. Två filter i serie gör att en trappa aldrig kan bli ett ryck,
	hur låg bildfrekvensen än är.

	══ VAD DEN INTE RÖR ═══════════════════════════════════════════════

	Ingenting i lokomotionen. Modulen läser hästens position och skriver
	`Motor6D.Transform`, som är ett rent LOKALT renderingsvärde — det
	replikeras inte och kan inte påverka fysik, kollision eller kurs.
	Faller modulen bort står hästen stilla men går fortfarande att rida.
]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Riggprofiler = require(ReplicatedStorage.HorseCore.Riggprofiler)
local Gangfas = require(ReplicatedStorage.HorseCore.Gangfas)
local Gaits = require(ReplicatedStorage.HorseCore.Gaits)
local Config = require(ReplicatedStorage.HorseCore.Config)

local HastGang = {}

--[[ ══ GÅNGARTEN SYNS (#264 GAIT_READABILITY_AND_UGNETA) ══════════════

	Förut: ett fast fyrtaktsmönster och en fast steglängd på 4,5 studs
	oavsett gångart, och en EGEN fasklocka bredvid rörelsemodulens. En trav
	såg ut som en snabbare skritt, och benen och hovslagen gick på var sin
	klocka.

	Nu läses benföljden ur `RidKanon.GANGFAS` genom `Gangfas` — samma rad
	som hovslagen och lättridningen läser. Varje ben har en isättning och
	en STÖDANDEL: under stödet förs hoven bakåt i markens takt, under
	svängen lyfts den och förs fram. Trav blir diagonala par med
	svävmoment, galopp tre slag och en paus på rätt sida.

	DEN RIDNA HÄSTEN har redan en fas: `MovementController` räknar den ur
	faktisk förflyttning, och ljudet läser den. Den matas hit (`mata`), så
	att ekipaget har EN klocka. Övriga hästar — ledda, observerade — har
	som förut en utjämnad egen fas, nu med gångartens egen cykellängd. ]]

--[[ Reservlängd för en cykel, i studs, när gångarten saknar cykel (halt
	som ändå rör sig, t.ex. under ledning innan attributet hunnit ändras). ]]
local STEGLANGD = Gaits.cycleLength("walk") * Config.STUDS_PER_METRE
--[[ Så långt bort slutar vi räkna. Trettiotre hästar i ett stall ska inte
	kosta trettiotre gångcykler när spelaren ser fem av dem. ]]
local SYNAVSTAND = 220
--[[ Under den här farten räknas hästen som stillastående. ]]
local STILLA = 0.5

--[[ Tidskonstanter. `TAU_FART` jämnar ut den hoppiga inmatningen,
	`TAU_LED` den färdiga ledvinkeln. Båda är korta nog att inte kännas
	som eftersläpning och långa nog att äta en trappa: vid 15 bilder per
	sekund är en bildruta 67 ms, alltså i samma storleksordning. ]]
local TAU_FART = 0.16
local TAU_LED = 0.075

--[[ Benens svängvinkel per gångart (radianer i skuldra/lår). Större steg i
	trav och galopp; ryggningen kort. Stiliserade tal för visuell granskning. ]]
local AMPLITUD = { skritt = 0.40, trav = 0.50, galopp_hoger = 0.58,
	galopp_vanster = 0.58, rygga = 0.30 }

type Tillstand = {
	fas: number,
	fart: number,
	sistPos: Vector3,
	vikt: number,
	led: { [Motor6D]: CFrame },
	monster: string?,
}

--[[ Den ridna hästens rörelse, matad av klientens ritloop. Läses bara om
	den är färsk — en häst man sitter av ska inte gå vidare på en gammal
	fas. ]]
local matning: { [Model]: { loco: any, tid: number } } = {}
local MATNING_FARSK = 0.5
local tillstand: { [Model]: Tillstand } = {}

--[[ Exponentiellt filter med samma form som kamerans: `1 - e^(-dt/tau)`.
	Bildrutelängden ligger i uttrycket, så resultatet blir detsamma vid 15
	som vid 60 bilder per sekund. Det är hela skillnaden mot en fast
	lerp-faktor, som blir olika snabb vid olika bildfrekvens. ]]
local function mjuk(nu: number, mal: number, tau: number, dt: number): number
	return nu + (mal - nu) * (1 - math.exp(-dt / math.max(tau, 1e-4)))
end

local function svang(fas: number): number
	return math.sin(fas * math.pi * 2)
end

--[[ Skriver en led genom filtret. Målet räknas fram av gången; det som
	faktiskt hamnar i `Transform` är det filtrerade värdet, och DET är vad
	som gör att en hoppig inmatning inte blir ett ryck. ]]
local function satLed(t: Tillstand, led: Motor6D?, mal: CFrame, dt: number)
	if not led then return end
	local nu = t.led[led] or led.Transform
	local ny = nu:Lerp(mal, 1 - math.exp(-dt / TAU_LED))
	t.led[led] = ny
	led.Transform = ny
end

--[[ ETT BENS LÄGE ur isättning och stödandel. `u` är tiden sedan
	isättningen (0..1 av cykeln).

	  stöd  (u < stod)  hoven står; benet förs LINJÄRT från fram till bak,
	                    alltså i markens jämna takt — det är det som håller
	                    hoven stilla mot marken i stället för att glida.
	  sväng (u ≥ stod)  hoven lyfts (sin²-puckel) och förs fram, mjukt i
	                    båda ändar (smoothstep), så isättningen inte rycker.

	Returnerar svängvinkel (-1..1, fram = +) och lyft (0..1,15). ]]
local function benLage(u: number, stod: number): (number, number)
	if u < stod then
		local p = u / math.max(stod, 1e-3)
		return 1 - 2 * p, 0
	end
	local q = (u - stod) / math.max(1 - stod, 1e-3)
	local sm = q * q * (3 - 2 * q)
	local s = math.sin(math.pi * q)
	return -1 + 2 * sm, s * s * 1.15
end

--[[ Ett ben: skuldra/lår svänger, knä/has böjer med lyftet. Kedjan kommer
	anatomiskt ordnad från `Riggprofiler.leder`, så den här funktionen vet
	inte vad delarna heter. ]]
local function benet(t: Tillstand, kedja: { Motor6D }, u: number, stod: number,
	amp: number, bakat: boolean, vikt: number, bak: boolean, dt: number)
	if #kedja == 0 then return end
	local sv, ly = benLage(u, stod)
	--[[ Baklänges förs hoven FRAMÅT under stödet: samma kontakter, omvänd
	     riktning. Så används aldrig framåtgångens svep för ryggning. ]]
	if bakat then sv = -sv end
	local s = sv * amp * vikt
	local l = ly * vikt
	--[[ Tecknet skiljer fram- och bakben: knäet böjer framåt, hasen bakåt. ]]
	local riktning = if bak then -1 else 1
	satLed(t, kedja[1], CFrame.Angles(s, 0, 0), dt)
	if kedja[2] then satLed(t, kedja[2], CFrame.Angles(-l * 0.52 * riktning, 0, 0), dt) end
	if kedja[3] then satLed(t, kedja[3], CFrame.Angles(l * 0.38 * riktning, 0, 0), dt) end
	if kedja[4] then satLed(t, kedja[4], CFrame.Angles(-l * 0.20 * riktning, 0, 0), dt) end
	if kedja[5] then satLed(t, kedja[5], CFrame.Angles(l * 0.11 * riktning, 0, 0), dt) end
end

--[[ Registret över hästar med visuellt nät. Byggs om sällan: att leta
	igenom workspace varje bildruta vore att betala för trettiotre hästar
	i varje ruta. ]]
local hastar: { Model } = {}
local sistaSok = 0

local function sokHastar()
	table.clear(hastar)
	for _, m in ipairs(workspace:GetDescendants()) do
		if m:IsA("Model") and m:GetAttribute("VisuellProfil") ~= nil then
			table.insert(hastar, m)
		end
	end
end

--[[ Lederna cachas per häst: `FindFirstChild(namn, true)` per ben och
	bildruta är precis den sortens kostnad som inte syns förrän det står
	trettiotre hästar i stallet. ]]
local ledCache: { [Model]: any } = {}

local function lederFor(hast: Model): any?
	local c = ledCache[hast]
	if c ~= nil then return c or nil end
	local l = Riggprofiler.leder(hast)
	ledCache[hast] = l or false
	return l
end

local function steg(dt: number, kamera: Vector3)
	for _, hast in ipairs(hastar) do
		local rot = hast.PrimaryPart or hast:FindFirstChild("HumanoidRootPart")
		if rot and rot:IsA("BasePart") and (rot.Position - kamera).Magnitude < SYNAVSTAND then
			local leder = lederFor(hast)
			if leder then
				local t = tillstand[hast]
				if not t then
					t = { fas = 0, fart = 0, sistPos = rot.Position, vikt = 0, led = {} }
					tillstand[hast] = t
				end

				--[[ FARTEN, LÅGPASSAD. Mätt på faktisk position och inte på
					`AssemblyLinearVelocity`: en häst som trycker mot ett
					staket har fart i motorn men rör sig inte, och då ska
					benen inte heller trampa. Filtret gör serverns hoppiga
					leverans till en jämn fart. ]]
				local d = rot.Position - t.sistPos
				local langd = Vector3.new(d.X, 0, d.Z).Magnitude
				t.sistPos = rot.Position
				t.fart = mjuk(t.fart, langd / math.max(dt, 1e-3), TAU_FART, dt)

				--[[ VILKEN RAD, OCH VILKEN FAS. Den ridna hästen läser
					rörelsemodulens egen fas och gångart (en klocka för ben,
					ljud och ryttare). Övriga läser serverns replikerade
					gångart och stegar en utjämnad egen fas med gångartens
					cykellängd. En häst som rör sig i halt — ledd, innan
					attributet hunnit ändras — går i skritt. ]]
				local mat = matning[hast]
				local loco = if mat and os.clock() - mat.tid < MATNING_FARSK
					then mat.loco else nil
				local namn: string?
				local luft = false
				if loco then
					namn = Gangfas.monsterNamn(loco.gait, loco.lead, loco.ryggar)
					luft = loco.airborne == true
					t.fas = loco.phase % 1
					t.fart = math.abs(loco.speed or 0) * Config.STUDS_PER_METRE
				else
					local gang = hast:GetAttribute("Gait")
					local ryggar = hast:GetAttribute("Ryggar") == true
					if typeof(gang) ~= "string" or gang == "halt" then
						gang = if t.fart > STILLA then "walk" else "halt"
					end
					namn = Gangfas.monsterNamn(gang :: string, nil, ryggar)
					local cykel = if ryggar then Config.RYGGNING.CycleLength * Config.STUDS_PER_METRE
						else Gaits.cycleLength(gang :: string) * Config.STUDS_PER_METRE
					if cykel <= 0 then cykel = STEGLANGD end
					--[[ FASEN stegas med FARTEN, inte med bildrutans hopp. Hon
						går fortfarande exakt så långt som hon färdas i snitt —
						det är det som håller hoven still i stödfasen — men en
						trappa in ger inte längre en trappa ut. ]]
					t.fas = (t.fas + (t.fart * dt) / cykel) % 1
				end
				t.monster = namn
				local monster = Gangfas.monster(namn)

				--[[ Halt, luft och okänd rad: benen går mot neutralt. I
					hoppets flygfas ska ingen benföljd ritas. ]]
				local vill = if monster and not luft and t.fart > STILLA then 1 else 0
				t.vikt = mjuk(t.vikt, vill, 0.22, dt)

				if monster then
					local amp = AMPLITUD[namn :: string] or 0.40
					local bakat = namn == "rygga"
					local function ettBen(kedja: { Motor6D }, ben: string, bak: boolean)
						local u, stod = Gangfas.ben(monster, ben, t.fas)
						benet(t, kedja, u, stod, amp, bakat, t.vikt, bak, dt)
					end
					ettBen(leder.framben.v, "LF", false)
					ettBen(leder.framben.h, "RF", false)
					ettBen(leder.bakben.v, "LH", true)
					ettBen(leder.bakben.h, "RH", true)
				else
					for _, kedja in ipairs({ leder.framben.v, leder.framben.h,
						leder.bakben.v, leder.bakben.h }) do
						benet(t, kedja, 0, 1, 0, false, 0, false, dt)
					end
				end

				--[[ KROPPEN, per gångart. Skritt: gung två gånger per cykel
					och en vagga. Trav: en tydligare studs per diagonalpar
					(två per cykel), stadig hals. Galopp: EN rullning per
					cykel — bogen upp när bakdelen bär — och halsen nickar
					med den. Talen är små med flit: levande, inte studsande. ]]
				local gung, vagga, rull, nick = 0, 0, 0, 0
				if namn == "trav" then
					gung = svang(t.fas * 2) * 1.35
					nick = gung * 0.35
				elseif namn == "galopp_hoger" or namn == "galopp_vanster" then
					rull = svang(t.fas - 0.12)
					gung = rull * 0.9
					nick = rull * 1.4
				else
					gung = svang(t.fas * 2)
					vagga = svang(t.fas)
					nick = gung
				end
				gung *= t.vikt
				vagga *= t.vikt
				rull *= t.vikt
				nick *= t.vikt
				satLed(t, leder.bal, CFrame.new(0, gung * 0.055, 0)
					* CFrame.Angles(gung * 0.020 + rull * 0.045, 0, vagga * 0.030), dt)

				--[[ HALSEN nickar mot stegen, svagare ju längre upp mot
					huvudet, så att nicken går genom halsen i stället för att
					knycka i nacken. ]]
				for i, halsled in ipairs(leder.hals) do
					satLed(t, halsled, CFrame.Angles(nick * 0.030 * (1 - i * 0.18), 0, 0), dt)
				end
				satLed(t, leder.huvud, CFrame.Angles(-nick * 0.022, 0, 0), dt)

				--[[ SVANSEN lever även när hon står still — det är den detalj
					som mest skiljer en häst från en staty. ]]
				local tid = os.clock()
				satLed(t, leder.svans, CFrame.Angles(
					math.sin(tid * 1.1) * 0.05 + gung * 0.03,
					math.sin(tid * 0.7) * 0.10, 0), dt)
			end
		end
	end
end

function HastGang.start()
	sokHastar()
	RunService.RenderStepped:Connect(function(dt)
		if os.clock() - sistaSok > 3 then
			sistaSok = os.clock()
			sokHastar()
		end
		local kam = workspace.CurrentCamera
		steg(dt, kam and kam.CFrame.Position or Vector3.zero)
	end)
end

--[[ För prov: hur många hästar som faktiskt animeras just nu. ]]
function HastGang._antal(): number
	return #hastar
end

--[[ För mätning: gångens tillstånd för en häst, utan att provet behöver
	känna till modulens interna tabeller. ]]
function HastGang._tillstand(hast: Model): { [string]: any }?
	local t = tillstand[hast]
	if not t then return nil end
	return { fas = t.fas, fart = t.fart, vikt = t.vikt, monster = t.monster }
end

--[[ Den ridna hästens rörelse. Anropas varje bildruta av ritloopen medan
	hon rids; slutar matningen går hon tillbaka till sin egen fas. ]]
function HastGang.mata(hast: Model?, loco: any)
	if not hast then return end
	matning[hast] = { loco = loco, tid = os.clock() }
end

--[[ För prov: kör ett steg utan RenderStepped, mot given kamera. ]]
function HastGang._steg(dt: number, kamera: Vector3)
	steg(dt, kamera)
end

function HastGang._satHastar(lista: { Model })
	table.clear(hastar)
	for _, h in ipairs(lista) do table.insert(hastar, h) end
	sistaSok = os.clock()
end

return HastGang
