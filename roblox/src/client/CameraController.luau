--!strict
--[[
	Ridkameran.

	STANDARD ÄR SADELN (G02-E del 1, issue #150, Tobias produktbeslut
	2026-09-08). Fram till dess låg kameran på en bom 14–23 studs BAKOM
	hästen: en tredjepersonskamera, alltså vyn av att se sig själv rida.
	Beslutet är att standardvyn ska vara RYTTARENS — vyn från sadeln, med
	hästens hals och öron och vägen framåt.

	Kameran har därför två färdiga mål varje bildruta:

	  A. SADELN — ögonpunkten hämtas ur den uppsuttna karaktärens EGET
	     huvud (`Head`), alltså ur riggen och sitsen som redan finns.
	     Ingen uppfunnen ögonhöjd och inga anläggningskoordinater.
	  B. BOMMEN — den gamla utifrånvyn, oförändrad tal för tal, numera
	     utlånad som feedbackvinkeln `utifran`.

	`Kameralage` ger vikten mellan dem: 0 är sadeln, 1 är vinkeln, och
	kameran interpolerar. En halv vikt är en kamera på väg — inte ett
	tredje specialfall som kan gå sönder för sig.

	Bommen ändrar sig med gångarten: närmare och lugnare i skritt, längre
	bak och vidare i fyrsprång. Synfältet öppnar sig svagt i fart — den
	billigaste och tydligaste fartkänslan som finns.

	INGEN SKAKNING. Skakning läser som skada, inte som fart, och gör folk
	åksjuka i förstapersonsnära vinklar — vilket sadelvyn per definition
	är. Sadeln LÄGGER därför inte till någon rörelse. Den DÄMPAR den
	riggen redan har: höjdled mjukas hårt och klampas mot huvudets
	faktiska läge, sidled sitter nästan stelt. Man ska sitta i sadeln,
	inte sväva bredvid den.

	Kameran har en EGEN kurs som följer hästens med en kort fördröjning.
	Läser den hästens kurs rakt av sitter den stelt fastskruvad i nacken,
	och varje styrutslag rycker hela bilden — det är den vanligaste
	orsaken till att en tredjepersonskamera känns instabil. Med en egen
	kurs svänger hästen först och bilden hinner ifatt. I sadeln är
	fördröjningen kortare: där ÄR man ryttaren, och en ryttare vrider
	huvudet in i svängen tidigare än en släpande bom gör.
]]

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Core = require(game:GetService("ReplicatedStorage").HorseCore)
local Types = require(game:GetService("ReplicatedStorage").HorseCore.Types)
local Config, Gaits, Kameralage = Core.Config, Core.Gaits, Core.Kameralage

local CameraController = {}
CameraController.__index = CameraController

local function smooth(current: number, target: number, tau: number, dt: number): number
	if tau <= 0 then return target end
	return current + (target - current) * (1 - math.exp(-dt / tau))
end

--[[ Samma utjämning för en vinkel. Skillnaden räknas via den korta vägen
     runt cirkeln, annars snurrar kameran ett helt varv varje gång hästens
     kurs passerar noll. ]]
local TWO_PI = 2 * math.pi
local function smoothAngle(current: number, target: number, tau: number, dt: number): number
	local delta = (target - current + math.pi) % TWO_PI - math.pi
	if tau <= 0 then return target end
	return current + delta * (1 - math.exp(-dt / tau))
end

function CameraController.new(rig: Types.Rig)
	local self = setmetatable({}, CameraController)
	self.rig = rig
	self.camera = Workspace.CurrentCamera
	self.dist = Config.CAMERA.BaseFov and 15 or 15
	self.height = 5.2
	self.fov = Config.CAMERA.BaseFov
	self.yaw = math.atan2(rig.root.CFrame.LookVector.X, rig.root.CFrame.LookVector.Z)
	self.previousType = self.camera.CameraType
	self.previousFov = self.camera.FieldOfView
	self.camera.CameraType = Enum.CameraType.Scriptable
	--[[ G02-E del 1: läget ägs här, en instans per ritt. Det rivs i
	     `release`, som `dismount` redan anropar — så ingen begäran kan
	     överleva en avsittning och tändas på nästa häst. ]]
	self.lage = Kameralage.skapa()
	self.eye = nil :: Vector3?          -- dämpad ögonpunkt i sadeln
	self.dolda = {} :: { [BasePart]: number }  -- eget huvud som tonats bort
	return self
end

--[[ ── Ögonpunkten i sadeln ─────────────────────────────────────────
     Karaktären sitter i `RiderSeat`, så dess `Head` ÄR ryttarens huvud.
     Ögonen ligger i huvudets framkant, och den kanten läses ur delens
     egen storlek i stället för att gissas: ändras huvudmodellen följer
     kameran med.

     Saknas karaktären finns ingen sadel att sitta i. Då säger funktionen
     nil och kameran faller tillbaka på bommen — hellre den gamla kända
     vyn än en påhittad punkt i luften. Samma degradering som resten av
     modulerna: saknas underlaget händer ingenting. ]]
local function ogonpunkt(): (Vector3?, BasePart?)
	local player = game:GetService("Players").LocalPlayer
	local character = player and player.Character
	if not character then return nil, nil end
	local head = character:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then return nil, nil end
	return head.Position + head.CFrame.LookVector * (head.Size.Z * 0.5), head
end

--[[ Ditt eget huvud sitter runt objektivet i sadeln, och ett huvud som
     ritas ovanpå kameran är bara en vägg. Det tonas bort med
     `LocalTransparencyModifier` — bara på den här klienten, precis som
     Genomsikt gör med väggar. Resten av kroppen lämnas: armar, händer,
     tyglar och ben är vad man SKA se från sadeln. ]]
function CameraController:_egetHuvud(alfa: number, head: BasePart?)
	local player = game:GetService("Players").LocalPlayer
	local character = player and player.Character
	if not character then return end
	local delar: { BasePart } = {}
	if head then table.insert(delar, head) end
	--[[ `GetChildren` finns på varje riktig Instance, men karaktären kan
	     i en degraderad/ofullständig respawn vara ett placeholder-objekt
	     som ännu inte har den (samma "rätt sorts degradering" som
	     `ogonpunkt()` ovan redan tillämpar på `FindFirstChild`). Ett
	     saknat huvud/accessoarer är då rätt svar — inte en krasch. ]]
	if typeof(character.GetChildren) == "function" then
		for _, barn in character:GetChildren() do
			if barn:IsA("Accessory") then
				local handle = barn:FindFirstChild("Handle")
				if handle and handle:IsA("BasePart") then table.insert(delar, handle) end
			end
		end
	end
	for _, del in delar do
		if self.dolda[del] == nil then self.dolda[del] = del.LocalTransparencyModifier end
		del.LocalTransparencyModifier = 1 - alfa
	end
end

function CameraController:_aterstallHuvud()
	for del, varde in self.dolda do
		if del and del.Parent then del.LocalTransparencyModifier = varde end
	end
	table.clear(self.dolda)
end

--[[ ── Kameralägets API ─────────────────────────────────────────────
     Finns för att DEL 2 ska kunna be om en vinkel utan att röra kameran
     själv. Ingen händelse är kopplad ännu — det är uttryckligen inte
     auktoriserat i den här leveransen. ]]
function CameraController:begarFeedback(id: string, orsak: string?): boolean
	return Kameralage.begar(self.lage, id, orsak)
end
function CameraController:slappFeedback(orsak: string?): boolean
	return Kameralage.slapp(self.lage, orsak)
end
function CameraController:nollstallLage(orsak: string?): boolean
	return Kameralage.nollstall(self.lage, orsak)
end

function CameraController:step(loco: Types.Locomotion, dt: number)
	local gait = Gaits.get(loco.gait)
	local C = Config.CAMERA
	local S = C.Saddle

	--[[ Läget stegas med samma dt som kameran, aldrig med väggklockan.
	     Det är vad som gör den automatiska återgången deterministisk. ]]
	local KL = Kameralage.stega(self.lage, dt)

	self.dist = smooth(self.dist, gait.camera.dist * KL.bak, C.Tau, dt)
	self.height = smooth(self.height, gait.camera.height * KL.hojd, C.Tau, dt)
	self.fov = smooth(self.fov,
		math.min((C.BaseFov + gait.camera.fov) * KL.fov, C.MaxFov), C.Tau, dt)

	local root = self.rig.root
	--[[ Kamerans egen kurs, inte hästens. Fördröjningen är kort nog att
	     man aldrig tappar bort vart man är på väg, och lång nog att
	     styrutslag inte rycker i bilden. Den glider med vikten, så att det
	     bara finns EN kurs att hålla reda på. ]]
	local w = math.clamp(KL.vikt, 0, 1)
	local yawTau = S.YawTau + (C.YawTau - S.YawTau) * w
	self.yaw = smoothAngle(self.yaw, loco.heading, yawTau, dt)
	local heading = self.yaw
	local framat = Vector3.new(math.sin(heading), 0, math.cos(heading))
	local back = -framat
	local right = Vector3.new(math.cos(heading), 0, -math.sin(heading))

	--[[ ── MÅL B: BOMMEN ────────────────────────────────────────────
	     Oförändrad. Feedbackvinkeln vrider bommen runt hästen och skalar
	     dess tal; vid vikt 1 och vinkeln `utifran` är uttrycket exakt det
	     gamla, tal för tal.

	     Kameran hänger efter i svängen i stället för att sitta stelt
	     bakom. Det är den detaljen som gör att svängar läses som svängar. ]]
	local trail = right * math.clamp(-loco.turnRate, -1, 1) * C.Shoulder
	local bomBak = if KL.yaw ~= 0
		then Vector3.new(-math.sin(heading + KL.yaw), 0, -math.cos(heading + KL.yaw))
		else back
	local bomFokus = root.Position + Vector3.new(0, 2, 0) + framat * (C.LookAhead * KL.blick)
	local bomLage = root.Position + bomBak * self.dist + Vector3.new(0, self.height, 0) + trail

	--[[ Håll bommen ur väggar: en strålkastning från hästen ut mot
	     kamerapunkten, och dra in den om något ligger emellan. ]]
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { self.rig.model, game.Players.LocalPlayer.Character }
	local origin = root.Position + Vector3.new(0, 2, 0)
	local hit = Workspace:Raycast(origin, bomLage - origin, params)
	if hit then
		bomLage = hit.Position + (origin - bomLage).Unit * 1.2
	end

	--[[ ── MÅL A: SADELN ────────────────────────────────────────────── ]]
	local raOga, head = ogonpunkt()
	local vb = if raOga then w else 1   -- ingen sadel ⇒ full bomvikt

	local lage, fokus, fov
	if raOga then
		local ra = raOga :: Vector3
		--[[ Dämpningen: höjdled mjukt, sidled nästan stelt, och ögat får
		     aldrig glida längre från huvudets faktiska höjd än taket. Utan
		     taket blir dämpningen en gummisnodd i stället för en sits. ]]
		if not self.eye then self.eye = ra end
		local e = self.eye :: Vector3
		local fxz = 1 - math.exp(-dt / S.TauXZ)
		local fy = 1 - math.exp(-dt / S.TauY)
		local ny = math.clamp(e.Y + (ra.Y - e.Y) * fy, ra.Y - S.CapY, ra.Y + S.CapY)
		self.eye = Vector3.new(e.X + (ra.X - e.X) * fxz, ny, e.Z + (ra.Z - e.Z) * fxz)
		local sadelLage = self.eye :: Vector3
		--[[ Blicken siktar framåt och något nedåt, så att både hästens hals
		     och vägen framför henne ligger i bild. Fallet är litet — en
		     ryttare tittar dit hon ska, inte ner i manen. ]]
		local sadelFokus = sadelLage + framat * S.LookAhead - Vector3.new(0, S.Fall, 0)
		lage = sadelLage:Lerp(bomLage, vb)
		fokus = sadelFokus:Lerp(bomFokus, vb)
		fov = S.Fov + (self.fov - S.Fov) * vb
	else
		self.eye = nil
		lage, fokus, fov = bomLage, bomFokus, self.fov
	end

	--[[ Eget huvud: borta i sadeln, tillbaka på bommen, tonat däremellan
	     så att bytet inte poppar mitt i en övergång. Vikten är kamerans
	     EGEN — den kan alltså inte glida ur synk med var kameran står. ]]
	local p = math.clamp((vb - 0.30) / 0.40, 0, 1)
	self:_egetHuvud(p * p * (3 - 2 * p), head)

	self.camera.CFrame = CFrame.lookAt(lage, fokus)
	self.camera.FieldOfView = fov
	--[[ Läget sparas för specarna och för Debug: EN sanning om vad kameran
	     gör, avläst där den faktiskt gör det. ]]
	self.vikt = vb
	self.lageNamn = if vb < 0.5 then "ryttare" else "feedback"
	self.vinkel = KL.id
end

function CameraController:release()
	--[[ Ritten är slut. Läget släpps HÅRT: ingen uttoning över en
	     avsittning, och ingen begäran kvar som kan tändas på nästa häst. ]]
	Kameralage.nollstall(self.lage, "avsittning")
	self.eye = nil
	self:_aterstallHuvud()
	self.camera.CameraType = self.previousType
	self.camera.FieldOfView = self.previousFov
	local character = game.Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		self.camera.CameraSubject = humanoid
	end
end

return CameraController
