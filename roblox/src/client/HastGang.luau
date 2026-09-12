--!strict
--[[
	GÅNGEN I BENEN — procedurell, och därför vår egen.

	══ VARFÖR INTE KÖPTA ANIMATIONER ══════════════════════════════════

	K3 kom med tre publicerade animationer: `Idle 5278859309`,
	`Walk 5278868188`, `Run 5278865536`. De ligger på en annan skapares
	konto. Försvinner de, eller modereras de bort, står trettiotre hästar
	stilla i en produktion där Roblox är primär plattform. Ordern är
	uttrycklig: hästens kärnrörelse får inte hänga på någon annans assets.

	Så benen drivs härifrån i stället. Ingen `AnimationId`, inget konto att
	vara beroende av, ingenting som kan tas bort under fötterna på oss.

	══ VARFÖR DET INTE ÄR "SLIDING FEET" ══════════════════════════════

	Fasen stegas med FÖRFLYTTNINGEN, inte med klockan:

	    fas += tillryggalagd sträcka / steglängd

	Går hästen långsammare tar stegen längre tid av sig själva, och hoven
	står still i marken i stödfasen därför att benet svänger exakt lika
	fort som marken glider förbi. Det är samma sak en bra gånganimation
	gör, fast utan att behöva matcha en fast klipphastighet.

	══ VAD DEN INTE RÖR ═══════════════════════════════════════════════

	Ingenting i lokomotionen. Modulen läser hästens POSITION mellan två
	bildrutor och skriver `Motor6D.Transform`, som är ett rent LOKALT
	renderingsvärde —
	det replikeras inte och kan inte påverka fysik, kollision eller kurs.
	Faller modulen bort står hästen stilla men går fortfarande att rida.
]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Riggprofiler = require(ReplicatedStorage.HorseCore.Riggprofiler)

local HastGang = {}

--[[ Steglängden i studs. Kortare ger fler steg per meter. Uppmätt mot
	riggens egen benlängd; en ponny i skritt tar ungefär 1,5 m steg. ]]
local STEGLANGD = 4.5
--[[ Så långt bort slutar vi räkna. Trettiotre hästar i ett stall ska inte
	kosta trettiotre gångcykler när spelaren ser fem av dem. ]]
local SYNAVSTAND = 220
--[[ Under den här farten räknas hästen som stillastående. ]]
local STILLA = 0.6

--[[ Fyrtakten i skritt: vänster fram, höger bak, höger fram, vänster bak.
	Det är hästens verkliga benföljd, och den är det som gör att en
	skrittande häst läses som en häst och inte som en hund. ]]
local FAS = { framV = 0.00, bakH = 0.25, framH = 0.50, bakV = 0.75 }

local tillstand: { [Model]: { fas: number, sistPos: Vector3, vikt: number } } = {}

local function svang(fas: number): number
	return math.sin(fas * math.pi * 2)
end

--[[ Lyftet i svängfasen: benet ska upp när det förs fram och ligga kvar
	när det bär. En halvvågs sinus gör just det. ]]
local function lyft(fas: number): number
	local f = fas % 1
	if f > 0.5 then return 0 end
	return math.sin(f * math.pi * 2)
end

local function satLed(led: Motor6D?, cf: CFrame)
	if led then led.Transform = cf end
end

--[[ Ett ben: skuldra/lår svänger, knä/has böjer med lyftet. Kedjan kommer
	anatomiskt ordnad från `Riggprofiler.leder`, så den här funktionen vet
	inte vad delarna heter. ]]
local function benet(kedja: { Motor6D }, fas: number, vikt: number, bak: boolean)
	if #kedja == 0 then return end
	local s = svang(fas) * vikt
	local l = lyft(fas) * vikt
	--[[ Tecknet skiljer fram- och bakben: knäet böjer framåt, hasen bakåt. ]]
	local riktning = if bak then -1 else 1
	satLed(kedja[1], CFrame.Angles(s * 0.42, 0, 0))
	if kedja[2] then satLed(kedja[2], CFrame.Angles(-l * 0.55 * riktning, 0, 0)) end
	if kedja[3] then satLed(kedja[3], CFrame.Angles(l * 0.40 * riktning, 0, 0)) end
	if kedja[4] then satLed(kedja[4], CFrame.Angles(-l * 0.22 * riktning, 0, 0)) end
	if kedja[5] then satLed(kedja[5], CFrame.Angles(l * 0.12 * riktning, 0, 0)) end
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
					t = { fas = 0, sistPos = rot.Position, vikt = 0 }
					tillstand[hast] = t
				end
				--[[ FASEN UR FÖRFLYTTNINGEN. Mätt på faktisk position och
					inte på hastighet: en häst som trycker mot ett staket
					har fart i motorn men rör sig inte, och då ska benen
					inte heller trampa. ]]
				local d = rot.Position - t.sistPos
				local langd = Vector3.new(d.X, 0, d.Z).Magnitude
				t.sistPos = rot.Position
				t.fas = (t.fas + langd / STEGLANGD) % 1

				--[[ Vikten tonar in och ur så att start och halt inte
					hackar. ]]
				local vill = if langd / math.max(dt, 1e-3) > STILLA then 1 else 0
				t.vikt += (vill - t.vikt) * math.min(dt * 6, 1)

				benet(leder.framben.v, t.fas + FAS.framV, t.vikt, false)
				benet(leder.framben.h, t.fas + FAS.framH, t.vikt, false)
				benet(leder.bakben.v, t.fas + FAS.bakV, t.vikt, true)
				benet(leder.bakben.h, t.fas + FAS.bakH, t.vikt, true)

				--[[ Kroppen gungar i takt med bakbenen, halsen nickar mot
					stegen och svansen svajar. Små tal med flit: det är
					det som skiljer levande från studsande. ]]
				local gung = svang(t.fas * 2) * 0.03 * t.vikt
				for i, halsled in ipairs(leder.hals) do
					satLed(halsled, CFrame.Angles(gung * (0.6 - i * 0.1), 0, 0))
				end
				satLed(leder.huvud, CFrame.Angles(-gung * 0.8, 0, 0))
				--[[ Svansen lever även när hon står still. ]]
				local tid = os.clock()
				satLed(leder.svans, CFrame.Angles(
					math.sin(tid * 1.1) * 0.05,
					math.sin(tid * 0.7) * 0.10, 0))
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

return HastGang
