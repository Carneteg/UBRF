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

local HastGang = {}

--[[ Steglängden i studs: så långt färdas hon per hel gångcykel. Kortare
	ger fler steg per meter. ]]
local STEGLANGD = 4.5
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

--[[ Fyrtakten i skritt: vänster fram, höger bak, höger fram, vänster bak.
	Det är hästens verkliga benföljd, och den är det som gör att en
	skrittande häst läses som en häst och inte som en hund. ]]
local FAS = { framV = 0.00, bakH = 0.25, framH = 0.50, bakV = 0.75 }

type Tillstand = {
	fas: number,
	fart: number,
	sistPos: Vector3,
	vikt: number,
	led: { [Motor6D]: CFrame },
}
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

--[[ Lyftet i svängfasen: benet ska upp när det förs fram och ligga kvar
	när det bär.

	Första versionen klippte till noll vid halva fasen — en hård kant som
	syns som ett ryck precis när hoven sätts i. Nu används en mjuk puckel
	(`sin²`) över svänghalvan, så både början och slutet av svängen går mot
	noll med noll lutning. Stödfasen är fortfarande helt stilla. ]]
local function lyft(fas: number): number
	local f = fas % 1
	if f > 0.5 then return 0 end
	local s = math.sin(f * math.pi * 2)
	return s * s * 1.15
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

--[[ Ett ben: skuldra/lår svänger, knä/has böjer med lyftet. Kedjan kommer
	anatomiskt ordnad från `Riggprofiler.leder`, så den här funktionen vet
	inte vad delarna heter. ]]
local function benet(t: Tillstand, kedja: { Motor6D }, fas: number, vikt: number,
	bak: boolean, dt: number)
	if #kedja == 0 then return end
	local s = svang(fas) * vikt
	local l = lyft(fas) * vikt
	--[[ Tecknet skiljer fram- och bakben: knäet böjer framåt, hasen bakåt. ]]
	local riktning = if bak then -1 else 1
	satLed(t, kedja[1], CFrame.Angles(s * 0.40, 0, 0), dt)
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

				--[[ FASEN stegas med FARTEN, inte med bildrutans hopp. Hon
					går fortfarande exakt så långt som hon färdas i snitt —
					det är det som håller hoven still i stödfasen — men en
					trappa in ger inte längre en trappa ut. ]]
				t.fas = (t.fas + (t.fart * dt) / STEGLANGD) % 1

				local vill = if t.fart > STILLA then 1 else 0
				t.vikt = mjuk(t.vikt, vill, 0.22, dt)

				benet(t, leder.framben.v, t.fas + FAS.framV, t.vikt, false, dt)
				benet(t, leder.framben.h, t.fas + FAS.framH, t.vikt, false, dt)
				benet(t, leder.bakben.v, t.fas + FAS.bakV, t.vikt, true, dt)
				benet(t, leder.bakben.h, t.fas + FAS.bakH, t.vikt, true, dt)

				--[[ KROPPEN. En häst i skritt gungar två gånger per cykel i
					höjdled och vaggar en gång i sidled. Talen är små med
					flit: det är det som skiljer levande från studsande. ]]
				local gung = svang(t.fas * 2) * t.vikt
				local vagga = svang(t.fas) * t.vikt
				satLed(t, leder.bal, CFrame.new(0, gung * 0.055, 0)
					* CFrame.Angles(gung * 0.020, 0, vagga * 0.030), dt)

				--[[ HALSEN nickar mot stegen, svagare ju längre upp mot
					huvudet, så att nicken går genom halsen i stället för att
					knycka i nacken. ]]
				for i, halsled in ipairs(leder.hals) do
					satLed(t, halsled, CFrame.Angles(gung * 0.030 * (1 - i * 0.18), 0, 0), dt)
				end
				satLed(t, leder.huvud, CFrame.Angles(-gung * 0.022, 0, 0), dt)

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
	return { fas = t.fas, fart = t.fart, vikt = t.vikt }
end

return HastGang
