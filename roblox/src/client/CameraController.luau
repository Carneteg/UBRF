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
	--[[ ══ RYTTARENS EGEN BLICK ════════════════════════════════════════

	     `self.yaw` följer HÄSTENS kurs och ska fortsätta göra det — det
	     är den som gör att svängar läses som svängar. Det här är ett
	     TILLÄGG ovanpå den: hur långt ryttaren vridit huvudet i
	     förhållande till färdriktningen.

	     Att det är en offset och inte en egen kurs är hela poängen:
	     vrider hästen sig följer bilden med, och ryttaren behåller sin
	     blickriktning i förhållande till hästen. Den nollställs aldrig av
	     sig själv — ett släppt finger ska lämna kameran stilla, inte dra
	     tillbaka den.

	     Den rör BARA kameran. `loco.heading` och styrningen är orörda, så
	     att titta åt sidan svänger inte hästen. ]]
	self.lookYaw = 0
	self.lookPitch = 0
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

--[[ ══ DITT EGET HUVUD ═══════════════════════════════════════════════

     Ditt eget huvud sitter runt objektivet i sadeln, och ett huvud som
     ritas ovanpå kameran är bara en vägg. Det tonas bort med
     `LocalTransparencyModifier` — bara på den här klienten, precis som
     Genomsikt gör med väggar. Resten av kroppen lämnas: armar, händer,
     tyglar och ben är vad man SKA se från sadeln.

     ══ VARFÖR TONNINGEN RÄKNAS UR AVSTÅNDET OCH INTE UR KAMERALÄGET ══

     Första versionen tonade ur `vb`, kameralägets egen vikt: 0 i sadeln,
     1 på bommen. Uppmätt uppsutten i spel:

         HUVUD Transparency=0.000  LocalTransparencyModifier=1.000
         KAMERA->HUVUD 0.570 studs
         varje ANNAN kroppsdel     LocalTransparencyModifier=0.000

     Huvudet var alltså varken borttaget, flyttat, skymt eller offer för
     någon förstapersonshantering i Roblox. Vi gömde det själva — och vi
     gömde det utifrån ett ABSTRAKT läge i stället för utifrån var kameran
     faktiskt stod. Det ger fel i båda riktningarna: står kameran redan
     flera studs bakom huvudet men vikten inte hunnit ikapp ser man en
     ryttare utan huvud, och slutar `step()` köras utan att `release()`
     hinner köra blir huvudet kvar borta i alla andra lägen också.

     Nu mäts det som frågan faktiskt gäller: VAR KAMERAN STÅR I
     FÖRHÅLLANDE TILL HUVUDET. Gränserna räknas ur delens egna mått, så
     ett annat avatarhuvud följer med.

     Det gör regeln självrättande: varje bildruta där kameran KAN se
     huvudet visas det, oavsett vilket läge, vilken övergång eller vilket
     avbrott som ledde dit.

     ══ OCH VARFÖR AVSTÅNDET RÄKNAS MOT LÅDAN, INTE MOT EN RADIE ══════

     Första rättningen mätte avståndet mot `Size.Magnitude / 2`. Det är
     rymddiagonalen och alltså den STÖRSTA radie ett huvud har: för ett
     R15-huvud på 1,16 x 1,11 x 1,14 blir den 0,98 studs, medan huvudet
     bara sträcker sig 0,58 studs ut åt något håll. Med marginalerna
     ovanpå var huvudet helt borta ut till 1,13 studs och fullt synligt
     först på 2,35 — kameran kunde alltså stå en hel stud UTANFÖR huvudet
     och ändå rita det osynligt. Det var kvar av samma bugg, bara i en
     mindre form, och Tobias såg den i nästa skärmbild.

     Regeln är enkel och ska vara det: ÄR KAMERAN UTANFÖR HUVUDET SKA
     HUVUDET SYNAS. Därför mäts nu kamerans läge i HUVUDETS EGET RUM mot
     huvudets halva mått — en låda, inte en sfär. Är den innanför lådan
     plus objektivets egen marginal är huvudet en vägg och tonas bort;
     är den utanför syns det, med en kort övergång som bara finns för att
     bytet inte ska poppa.

     Marginalen är kamerans nära klippplan plus lite: står objektivet
     precis i huvudets framkant — vilket är exakt var sadelvyns ögonpunkt
     ligger — ser man insidan av sitt eget huvud, och då hjälper det inte
     att man tekniskt sett är utanför med en hundradel. ]]
local HUVUD_MARGINAL = 0.25   -- studs utanför lådan som fortfarande räknas som inuti
local HUVUD_OVERGANG = 0.35   -- studs därefter innan huvudet är helt synligt

--[[ Hur synligt det egna huvudet ska vara när kameran står i `lokal`,
     uttryckt i huvudets eget rum, och huvudet är `matt` stort.

     Ren funktion utan Instance: provet kan visa den röd utan att starta
     vare sig kamera, karaktär eller häst. ]]
function CameraController.huvudsynlighet(lokal: Vector3, matt: Vector3): number
	--[[ Hur långt UTANFÖR lådan punkten ligger, längs den axel där den
	     sticker ut minst. Noll eller mindre betyder inuti. ]]
	local ut = math.max(
		math.abs(lokal.X) - matt.X / 2,
		math.abs(lokal.Y) - matt.Y / 2,
		math.abs(lokal.Z) - matt.Z / 2)
	local t = math.clamp((ut - HUVUD_MARGINAL) / HUVUD_OVERGANG, 0, 1)
	--[[ Mjuk i båda ändar (`smoothstep`) så att bytet inte poppar mitt i
	     en kamerarörelse. ]]
	return t * t * (3 - 2 * t)
end

--[[ ══ VAKTEN: ETT GÖMT HUVUD MÅSTE KUNNA KOMMA TILLBAKA SJÄLVT ══════

	Regeln ovan räknas i `step()`. Den är rätt så länge `step()` körs —
	men `LocalTransparencyModifier` är ett TILLSTÅND, inte en ritning:
	slutar någon skriva det ligger sista värdet kvar för evigt.

	Och uppsutten ridning är FÖRSTAPERSON i varje vy. Kameran står i
	ögonpunkten, huvudet är korrekt gömt, och ryttaren syns aldrig i
	bild — så länge kameran är kamerans. Den enda situation där man ser
	en ryttare utan huvud är alltså när kameran INTE längre styrs av
	modulen: en frusen bildruta, ett avbrutet spelprov, en kamera som
	flyttats utifrån. Då slutade `step()` köra medan huvudet råkade vara
	gömt, och ingenting tänder det igen.

	Det är den kvarvarande buggen, och den går inte att rätta i `step()`
	— den handlar just om att `step()` inte kör. Vakten nedan gör det:
	har ingen skrivit huvudets synlighet på en halv sekund lämnas det
	tillbaka som det var.

	En enda `Heartbeat` för hela modulen, kopplad först när något
	faktiskt gömts. Kostar ingenting när ingen rider. ]]
local VAKT_TYST = 0.5   -- sekunder utan skrivning innan huvudet lämnas tillbaka
local vakt: RBXScriptConnection? = nil
local vaktar: { [any]: number } = {}

local function vaktaHuvud(self: any)
	vaktar[self] = os.clock()
	if vakt then return end
	vakt = RunService.Heartbeat:Connect(function()
		local nu = os.clock()
		local kvar = false
		for ctrl, sist in pairs(vaktar) do
			if nu - sist > VAKT_TYST then
				ctrl:_aterstallHuvud()
				vaktar[ctrl] = nil
			else
				kvar = true
			end
		end
		if not kvar and vakt then
			vakt:Disconnect()
			vakt = nil
		end
	end)
end

--[[ Hur länge ett gömt huvud får ligga gömt utan att någon skriver om
	det. Egen funktion för att provet ska kunna läsa samma tal som
	vakten använder. ]]
function CameraController.vakttystnad(): number
	return VAKT_TYST
end

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
	--[[ Vakten vet nu att någon skrev. Se noten vid `vaktaHuvud`. ]]
	if alfa < 1 then
		vaktaHuvud(self)
	elseif vaktar[self] then
		vaktar[self] = nil
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

--[[ ── RYTTARENS BLICK ──────────────────────────────────────────────

     Pekytan drar hit. Båda värdena är RELATIVA — kameran flyttas från
     där den redan står — så det första fingret på skärmen aldrig kan
     rycka bilden till ett absolut läge.

     `dYaw` i radianer, `dPitch` i studs som fokuspunkten lyfts. Höjden
     har ett tak åt båda håll: ryttaren tittar sig omkring, hon tittar
     inte rakt upp i taket eller rakt ned i marken. ]]
local BLICK_UPP = 7      -- studs som blicken får lyftas
local BLICK_NED = 4      -- studs som den får sänkas

function CameraController:vridBlick(dYaw: number, dPitch: number)
	if dYaw ~= dYaw or dPitch ~= dPitch then return end   -- NaN-vakt
	self.lookYaw = (self.lookYaw + dYaw + math.pi) % (2 * math.pi) - math.pi
	self.lookPitch = math.clamp(self.lookPitch + dPitch, -BLICK_NED, BLICK_UPP)
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
	--[[ Ryttarens blick läggs på hästens kurs EFTER utjämningen: annars
	     hade utjämningen dragit tillbaka den mot hästens kurs och
	     blicken hade glidit iväg av sig själv. ]]
	local heading = self.yaw + self.lookYaw
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
	--[[ Blickens höjd. `lookPitch` är studs som fokuspunkten lyfts eller
	     sänks — inte en vinkel — så att den verkar likadant oavsett hur
	     långt bak bommen råkar ligga i gångarten. ]]
	local bomFokus = root.Position + Vector3.new(0, 2 + self.lookPitch, 0)
		+ framat * (C.LookAhead * KL.blick)
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
		local sadelFokus = sadelLage + framat * S.LookAhead
			- Vector3.new(0, S.Fall - self.lookPitch, 0)
		lage = sadelLage:Lerp(bomLage, vb)
		fokus = sadelFokus:Lerp(bomFokus, vb)
		fov = S.Fov + (self.fov - S.Fov) * vb
	else
		self.eye = nil
		lage, fokus, fov = bomLage, bomFokus, self.fov
	end

	self.camera.CFrame = CFrame.lookAt(lage, fokus)
	self.camera.FieldOfView = fov

	--[[ Eget huvud: räknas EFTER att kameran flyttats, mot den position
	     som faktiskt ritas den här bildrutan. Se blocket vid
	     `huvudsynlighet` för varför det inte längre läser kameraläget. ]]
	if head then
		local lokal = head.CFrame:PointToObjectSpace(lage)
		self:_egetHuvud(CameraController.huvudsynlighet(lokal, head.Size), head)
	else
		--[[ Ingen karaktär att gömma — men det som redan gömts ska tillbaka,
		     annars överlever en bortonad del sin egen anledning. ]]
		self:_aterstallHuvud()
	end
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
