--!strict
--[[
	Ridningens pekkontroller.

	`Input` har haft `setTouch`, `touchGait` och `touchJump` sedan början,
	men ingen har anropat dem: API:t fanns, spelaren fanns inte. Den här
	modulen är den saknade anroparen och ingenting mer. Ingen ny
	rörelsearkitektur, ingen egen avsiktsmodell — spaken skriver samma
	normaliserade avsikter som W/A/S/D och gamepaden, och går genom samma
	`Input.consume()` in i `MovementController`.

	SPAKEN ÄR ANALOG, INTE FYRA KNAPPAR I EN CIRKEL. Det är hela poängen:
	en liten dragning ska ge en linjekorrigering, en halv ska ge en 20 m
	volt, en hel ska ge en snäv volt. Kurvan nedan är portad från
	webbversionen, där de tre nivåerna är uppmätta med riktiga pekhändelser.

	Ritas bara på pekenheter, bara när man sitter upp, och rivs vid avsittning.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
--[[ Pekknapparna är `ContextActionService` egna. Modulen SKAPAR ingen av
     dem — den sätter titel, plats och genomskinlighet på knappar tjänsten
     redan äger. Se noten vid `nyKnapp`, som är borta. ]]
local ContextActionService = game:GetService("ContextActionService")

--[[ #162: knapparnas etiketter kommer ur språkkanonen — samma nycklar
     som KontrollHjalp beskriver dem med. ]]
local Sprak = require(game:GetService("ReplicatedStorage").HorseCore.Sprak)

local TouchControls = {}

--[[ ── Kurvan ──────────────────────────────────────────────────────────
     Samma tal som `src/mobil.js`: expo 0,35 och dödzon 0,07 på styraxeln,
     0,12 på framåtaxeln. Den högre dödzonen framåt finns för att tummen
     nästan alltid har en liten lodrät komponent när man styr — utan den
     ökar hästen gångart av misstag mitt i en volt.

     Expo betyder att kurvan är delvis rak, delvis kubisk. En rent
     kvadratisk kurva provades i webben och föll: 25 % spakutslag gav 2 %
     styrning, alltså 203 m radie — i praktiken rakt fram, och därmed inte
     tre användbara nivåer. ]]
local EXPO = 0.35
local DEAD_STEER = 0.07
local DEAD_FORWARD = 0.12

local function dodzon(v: number, d: number): number
	local a = math.abs(v)
	if a <= d then return 0 end
	return math.sign(v) * (a - d) / (1 - d)
end

local function kurva(v: number): number
	local a = math.abs(v)
	return math.sign(v) * a * (EXPO + (1 - EXPO) * a * a)
end

--[[ Spakens läge → avsikt. Ren funktion, utan Roblox-beroenden, så att den
     går att mäta i bänken utan att någon GUI behöver finnas.

     `dx`/`dy` är pixlar från spakens mitt, `radie` dess yttermått. Y vänds:
     på skärmen växer Y nedåt, men framåt är uppåt. ]]
function TouchControls.axis(dx: number, dy: number, radie: number): (number, number)
	if radie <= 0 then return 0, 0 end
	local nx, ny = dx / radie, -dy / radie
	--[[ Utanför cirkeln normaliseras längden till 1 i stället för att
	     klampas per axel: annars blir diagonalen snabbare än rakt fram,
	     vilket är samma fel som ett odiagonalklampat WASD gör. ]]
	local len = math.sqrt(nx * nx + ny * ny)
	if len > 1 then nx, ny = nx / len, ny / len end
	return kurva(dodzon(ny, DEAD_FORWARD)), kurva(dodzon(nx, DEAD_STEER))
end

TouchControls.RADIE = 66          -- spakens yttermått i pixlar
TouchControls.KNAPP = 56          -- knopens diameter

--[[ ── GUI ─────────────────────────────────────────────────────────────
     Byggs först vid uppsittning, på en pekenhet. Allt nedanför är
     Roblox-instanser och kan därför bara köras i Studio eller i en klient;
     mätbänken testar `axis` och `Input`-kontraktet, inte gesterna. ]]
local gui: ScreenGui? = nil
local aktivFinger: InputObject? = nil
local Input = nil :: any            -- sätts av mount, för att undvika cykel

--[[ ── RYTTARENS BLICK PÅ PEKSKÄRM ──────────────────────────────────

     Ett EGET finger, skilt från spakens. De två spåras var för sig och
     jämförs på InputObject, inte på position — det är det som gör att
     vänstertummen kan styra medan högertummen tittar sig omkring.

     `blickSist` är fingrets förra läge. Allt som skickas vidare är
     SKILLNADEN mot det, så det första nedslaget aldrig kan rycka
     kameran till en absolut vinkel. ]]
--[[ Hur brett reglagen tar i högerkanten, inklusive luft. Lektionskortet
	läser den för att aldrig lägga sig över gångartsknapparna. Noll när
	pekreglagen inte är uppe — skrivbordet reserverar ingenting. ]]
local reglageBredd = 0

--[[ ══ LAYOUTEN RÄKNAS UR SKÄRMHÖJDEN — OCH HÖJDEN KAN ÄNDRAS (#208) ══

	`skala` nedan finns för att en låg skärm inte ska skjuta gångartsraden
	ur bild. Räkningen gjordes vid uppsittningen och aldrig igen. Vred
	spelaren plattan efteråt behöll reglagen sin gamla skala.

	Mätt i Studio på `754f2cc`, monterat på en hög yta och sedan vridet
	till iPhone 13 i landskap (749x367):

	    HALT   y -71..-19   helt utanför
	    SKRITT y -71..-19   helt utanför
	    TRAV   y -11..41    avklippt
	    GALOPP y -11..41    avklippt

	Det är exakt de tal noten i `mount` citerar som det gamla felet.

	TRE SAKER SOM MÅSTE STÄMMA, och som ett första försök missade:

	1. Ett enhetsbyte ger FLERA storleksändringar. Diagnos på `4d740b6`:
	   `1375x974 -> 1281x953 -> 749x309`, två händelser på 50 ms. Bygger
	   man om per händelse bygger man om i onödan.
	2. Ombyggnaden ÄNDRAR SJÄLV storleken — en ny ScreenGui får förälder
	   och fyrar signalen igen. Utan en terminerande vakt bygger den om
	   varje bildruta, för alltid.
	3. Bara HÖJDEN styr layouten. Bredden hanteras redan av ankringen i
	   högerkanten (`UDim2.new(1, -…)`), så en bredare skärm behöver
	   ingen ombyggnad alls.

	`byggdHojd` löser alla tre på en gång: den bär den höjd layouten
	FAKTISKT räknades ur, och ombyggnaden hoppas över när höjden är
	oförändrad. Efter en ombyggnad är den lika med den nya höjden, så
	den nya ytans egen händelse är en tom retur — ingen loop, ingen
	pollning, ingen väntan. ]]
local byggdHojd = 0
local senasteInput: any = nil
local senasteHooks: any = nil
local ytaKoppling: RBXScriptConnection? = nil
local planerad = false

function TouchControls.reglageBredd(): number
	return reglageBredd
end

--[[ Hur brett SPAKEN tar i vänsterkanten, inklusive luft (#206).

	Reserven har varit ensidig: `reglageBredd` ovan höll lektionskortet
	borta från gångarterna och hjälparna i högerkanten, men ingenting
	höll det borta från spaken i vänsterkanten. `UgnetaController`
	centrerar kortet i det fria utrymmet, och när det inte räcker till
	sköts kortet åt VÄNSTER — rakt ut över spaken.

	Mätt i Studio på `cdfe061`, emulerad iPad i landskap, kortet uppe och
	ryttaren uppsutten, träffprov över spakens bas (70 punkter):

	    1024x768  kort x  76..716  överlapp 80 px  spaken når 20 av 70
	    1080x810  kort x 105..745  överlapp 51 px  spaken når 34 av 70
	    1180x820  kort x 269..909  överlapp  0 px  spaken når 54 av 70

	De tappade punkterna svarade `Kort`, `Rubrik`, `Punkt1`, `Punkt2` och
	`Knapp` — alltsa kortet, som ligger i en ScreenGui med högre
	`DisplayOrder` (10 mot 8) och därför vinner fingret. Ett tumnedslag i
	spakens högra halva startar då ingen styrning alls, utan träffar
	kortet — i värsta fall dess kvitteringsknapp.

	Talet räknas här, av samma rader som ritar spaken, av exakt samma skäl
	som `reglageBredd`: ingen annan modul ska bära en kopia av layouten.
	Noll när pekreglagen inte är uppe — skrivbordet reserverar ingenting. ]]
local spakBredd = 0

function TouchControls.spakBredd(): number
	return spakBredd
end

--[[ Var spaken BÖRJAR, i GUI-pixlar uppifrån (#234). Samma yta och samma
	skäl som `reglageTopp` nedan, fast för vänsterkanten: Ugnetas lokala
	replikslogg bor i det vänstra bandet — det enda som varken blickytan
	(som börjar på 34 % av bredden) eller gångartsknapparna gör anspråk
	på — och den måste veta var spaken tar vid.

	Räknat med #208-skalan blir bandet olika högt på olika enheter:

	    1920x1080  PC, ingen pekyta   math.huge   loggen får sina tre rader
	     844x 390  iPhone 13 lands.   spaken 209  tre rader ryms
	     568x 320  liten telefon      spaken 168  loggen krymper till två

	Talet räknas HÄR, av samma rader som ritar spaken, precis som
	`reglageBredd` och `reglageTopp`. En kopia av layouten i loggmodulen
	hade glidit första gången skalan ändrades. `math.huge` när pekreglagen
	inte är uppe: skrivbordet reserverar ingenting. ]]
local spakTopp = math.huge

function TouchControls.spakTopp(): number
	return spakTopp
end

--[[ Var det övre gallret BÖRJAR, i GUI-pixlar uppifrån (samma yta som
	`reglageBredd`: viewporten minus topbaren). `math.huge` när reglagen inte
	är uppe. Hjälpknappen läser den (#227): på en telefon i landskap trycker
	skalan ovan ihop gallren tills gångartsraden når nästan upp till
	topbaren — mätt på iPhone 13 i landskap till 9 px — alltså rakt in i
	det band där `?` bor. Talet räknas här, av samma rader som ritar
	gallret, så att ingen annan modul behöver en egen kopia av layouten. ]]
local reglageTopp = math.huge

function TouchControls.reglageTopp(): number
	return reglageTopp
end

local blickFinger: InputObject? = nil
local blickSist: Vector2? = nil
local blickHook: ((number, number) -> ())? = nil

--[[ Hur mycket kameran vrids per dragen pixel. Radianer i sidled och
     studs i höjdled; framtagna så att ett tumdrag tvärs över halva
     skärmen vrider ungefär ett halvt varv. ]]
local BLICK_PER_PIXEL_X = 0.006
local BLICK_PER_PIXEL_Y = 0.02

local function nyRam(namn: string, parent: Instance): Frame
	local f = Instance.new("Frame")
	f.Name = namn
	f.BackgroundTransparency = 1
	f.BorderSizePixel = 0
	f.Parent = parent
	return f
end

--[[ `nyKnapp` ÄR BORTA, och det är inte en förenkling utan hela
     beslutet. Den byggde panelens tio `TextButton` i vår egen
     `ScreenGui`. Arkitekturbeslutet 2026-09-17 förbjuder uttryckligen
     just den konstruktionen för ridningens reglage: DRIV, BROMS och
     avsittningen är `ContextActionService`-handlingar, och knapparna är
     Roblox egna. Se `stallInHandlingar` i `mount`.

     Spaken och blickytan är `Frame`, inte knappar, och står kvar. De är
     styrning och kamera — inte det reglageblock som föll på QA. ]]

--[[ Spaken följer fingret som startade den, inte vilket finger som helst:
     annars kapar en tumme på gångartsknappen styrningen mitt i en volt. ]]
local function kopplaSpak(bas: Frame, knop: Frame)
	local function centrum(): Vector2
		local p, s = bas.AbsolutePosition, bas.AbsoluteSize
		return p + s / 2
	end

	local function flytta(pos: Vector2)
		local c = centrum()
		local dx, dy = pos.X - c.X, pos.Y - c.Y
		local len = math.sqrt(dx * dx + dy * dy)
		local r = TouchControls.RADIE
		if len > r then dx, dy = dx / len * r, dy / len * r end
		knop.Position = UDim2.new(0.5, dx, 0.5, dy)
		Input.setTouch(TouchControls.axis(dx, dy, r))
	end

	--[[ Att släppa MÅSTE nolla båda axlarna på en gång. Ett finger som
	     lyfts mitt i en sväng och lämnar kvar 0,6 styrning är en häst som
	     fortsätter svänga av sig själv. ]]
	local function slapp()
		aktivFinger = nil
		knop.Position = UDim2.fromScale(0.5, 0.5)
		Input.setTouch(0, 0)
	end

	bas.InputBegan:Connect(function(obj: InputObject)
		if obj.UserInputType ~= Enum.UserInputType.Touch then return end
		if aktivFinger then return end
		aktivFinger = obj
		flytta(Vector2.new(obj.Position.X, obj.Position.Y))
	end)

	--[[ Rörelsen lyssnas på globalt, inte på ramen: drar man tummen utanför
	     cirkeln ska styrningen ligga kvar på max i stället för att slockna. ]]
	UserInputService.InputChanged:Connect(function(obj: InputObject)
		if obj ~= aktivFinger then return end
		flytta(Vector2.new(obj.Position.X, obj.Position.Y))
	end)
	UserInputService.InputEnded:Connect(function(obj: InputObject)
		if obj == aktivFinger then slapp() end
	end)
end

--[[ ── BLICKYTAN ────────────────────────────────────────────────────

     En genomskinlig yta över högra delen av skärmen. Den ligger UNDERST
     i sin ScreenGui, så varje knapp och spaken ovanpå den tar sitt eget
     finger först — ett tryck på GALOPP är ett tryck på GALOPP, inte
     början på ett kamerakast. Lektions-, skötsel- och hjälp-GUI ligger i
     egna ScreenGui med högre DisplayOrder och tar också sina egna
     tryck.

     Vänstra tredjedelen lämnas fri: där bor spaken, och en yta under
     den hade gjort varje styrutslag till en kameravridning också. ]]
local function kopplaBlick(yta: Frame)
	yta.InputBegan:Connect(function(obj: InputObject)
		if obj.UserInputType ~= Enum.UserInputType.Touch then return end
		if blickFinger then return end
		if obj == aktivFinger then return end
		blickFinger = obj
		blickSist = Vector2.new(obj.Position.X, obj.Position.Y)
	end)

	UserInputService.InputChanged:Connect(function(obj: InputObject)
		if obj ~= blickFinger then return end
		local nu = Vector2.new(obj.Position.X, obj.Position.Y)
		local forra = blickSist or nu
		local d = nu - forra
		blickSist = nu
		local fn = blickHook
		if fn then
			--[[ Skärmens X åt höger ska vrida blicken åt höger, och att
			     dra NEDÅT ska sänka blicken — samma håll som fingret. ]]
			fn(d.X * BLICK_PER_PIXEL_X, -d.Y * BLICK_PER_PIXEL_Y)
		end
	end)

	--[[ Att släppa nollar BARA fingret. Kameran lämnas där den står —
	     ingen återfjädring, ingen omcentrering. ]]
	local function slappBlick(obj: InputObject)
		if obj == blickFinger then
			blickFinger = nil
			blickSist = nil
		end
	end
	UserInputService.InputEnded:Connect(slappBlick)
end

--[[ Roblox egna pekreglage flyttar KARAKTÄREN. Sitter hon i sadeln blir
     det två saker som drar i samma kropp, och i värsta fall reser hon sig
     ur sitsen mitt i galoppen. De stängs av medan man rider och sätts på
     igen vid avsittning — inte permanent, eftersom spelaren ska kunna gå
     till fots i stallet som vanligt. ]]
local styrningAv = false
local function egnaReglage(pa: boolean)
	--[[ ══ DET HÄR STYCKET STÄNGDE INGENTING ═══════════════════════════

	     Stycket ovanför beskriver avsikten. Koden nådde den aldrig:
	     `PlayerScripts` innehåller ingen `PlayerModule` i den här placen —
	     mätt i en simulerad iPad Air, där barnen var `RbxCharacterSounds`,
	     `Horse` och MCP-bryggan. `if not modul then return end` tog alltså
	     varje gång, och Roblox egna pekreglage låg kvar hela ritten.

	     VAD DET KOSTADE, mätt i landskap 1179×819:
	       `DynamicThumbstickFrame` 572×607 vid (−100 · 254) — en osynlig
	       träffyta över hela nedre vänstra halvan. Lektionskortets
	       "Continue"-knapp hamnade FJÄRDE i stacken under den:
	           [DynamicThumbstickUIModifier > DynamicThumbstickFrame >
	            TouchControlFrame > Knapp]
	       Spelaren kunde alltså inte starta lektionen på iPad alls.
	       `ThumbstickStart` 148×148 låg ovanpå vår egen spak, och
	       `JumpButton` 120×120 under DEEP SEAT och REIN.

	     `UserInputService.ModalEnabled` är Roblox egen väg att göra just
	     det här, och den gör det utan att leta reda på en modul som inte
	     finns: satt till true släcks pekreglagen (mätt: `TouchGui.Enabled`
	     gick själv till false, och kortets knapp blev överst igen).

	     Den sätts BARA härifrån, och hit kommer man bara på en pekenhet —
	     `mount` returnerar tidigt när `TouchEnabled` är falskt. Skrivbordet
	     rörs alltså inte. ]]
	local UIS = UserInputService
	UIS.ModalEnabled = not pa

	--[[ Modulvägen står kvar för de klienter som HAR en PlayerModule: där
	     gör den samma sak en nivå närmare källan. Saknas den är
	     `ModalEnabled` ovan hela rättelsen. ]]
	local scripts = Players.LocalPlayer:FindFirstChild("PlayerScripts")
	local modul = scripts and scripts:FindFirstChild("PlayerModule")
	if modul then
		local ok, controls = pcall(function()
			return (require(modul) :: any):GetControls()
		end)
		if ok and controls then
			if pa then controls:Enable() else controls:Disable() end
		end
	end
	styrningAv = not pa
end

--[[ `hooks.dismount` kallas när spelaren trycker på avsittningsknappen —
     pekskärmen har ingen E-tangent att trycka på. ]]
--[[ `blick` får skillnaden i radianer och studs från blickytan. Den är
     valfri, så en anropare som inte bryr sig om kameran fungerar ändå. ]]
--[[ Den höjd layouten räknas ur. EN funktion, så att lyssnaren och
	`mount` aldrig kan svara olika på samma fråga.

	`AbsoluteSize` kan vara noll bildrutan en ScreenGui fick förälder.
	Kameran vet ändå, och GUI-ytan är vyporten minus topbarens inset. ]]
local function layouthojd(g: ScreenGui): number
	local kam = workspace.CurrentCamera
	local vyH = if kam then kam.ViewportSize.Y - GuiService:GetGuiInset().Y else 0
	return math.max(g.AbsoluteSize.Y, vyH)
end

--[[ `efterLayout` kallas när reglagen byggts, byggts om eller rivits, med
	reservens bredd och överkant (`reglageBredd`, `reglageTopp`). Den som
	delar skärmkant med reglagen — hjälpknappen — lägger sig rätt i samma
	andetag, i stället för att gissa när #208-ombyggnaden är klar. ]]
function TouchControls.mount(input: any, hooks: {
	dismount: () -> (),
	blick: ((number, number) -> ())?,
	--[[ `modell` är borta. Den fanns bara för att gångartsraden skulle
	     kunna lysa på den gångart hästen faktiskt gick i, och raden finns
	     inte längre. ]]
	efterLayout: ((number, number) -> ())?,
})
	if gui then return end
	if not UserInputService.TouchEnabled then return end
	Input = input
	senasteInput, senasteHooks = input, hooks

	local spelare = Players.LocalPlayer
	local mapp = spelare:FindFirstChildOfClass("PlayerGui")
	if not mapp then return end

	gui = Instance.new("ScreenGui")
	local g = gui :: ScreenGui
	g.Name = "HorseTouch"
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = false
	g.DisplayOrder = 8
	--[[ Syskonordning: ritordningen följer barnens ordning, och blickytan
	     skapas först — alltså underst. ]]
	g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	g.Parent = mapp
	--[[ Vridning, delad skärm, fönsterändring. Se noten vid `byggdHojd`. ]]
	if ytaKoppling then ytaKoppling:Disconnect() end
	ytaKoppling = g:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if gui ~= g then return end
		if layouthojd(g) == byggdHojd then return end
		--[[ Flera händelser i samma bildruta ska ge EN ombyggnad. ]]
		if planerad then return end
		planerad = true
		task.defer(function()
			planerad = false
			if gui ~= g then return end
			if layouthojd(g) == byggdHojd then return end
			local i, h = senasteInput, senasteHooks
			if not (i and h) then return end
			TouchControls.unmount()
			TouchControls.mount(i, h)
		end)
	end)

	--[[ BLICKYTAN FÖRST, så att allt annat hamnar ovanpå den. Den täcker
	     högra två tredjedelarna; vänstra tredjedelen är spakens. ]]
	--[[ ══ EN LAYOUT, TRE SKÄRMHÖJDER ══════════════════════════════

	     Reglagen låg i fasta pixlar räknade från nederkanten: gångarterna
	     på `1, -380`. Det förutsätter att det FINNS 380 px. iPad i
	     landskap har 761 och klarar det; iPhone 13 i landskap har 309, och
	     då hamnar raden ovanför skärmkanten.

	     Mätt på iPhone 13 landskap före den här raden:
	         HALT   y -71..-19   helt utanför
	         SKRITT y -71..-19   helt utanför
	         TRAV   y -11..41    avklippt
	         GALOPP y -11..41    avklippt
	     Fyra av fem gångartsknappar gick alltså inte att träffa.

	     Svaret är INTE en egen telefonlayout — samma två galler, samma
	     ordning, samma plats. Talen skalas mot den höjd blocket faktiskt
	     behöver (två galler + mellanrum + marginal ≈ 380), och taket är 1
	     så att surfplattan är exakt som förut. ]]
	--[[ `AbsoluteSize` kan vara noll bildrutan en ScreenGui fick förälder.
	     Kameran vet ändå, och GUI-ytan är vyporten minus topbarens inset. ]]
	local skarmH = layouthojd(g)
	byggdHojd = skarmH
	--[[ 390 och inte 380: varje `px()` avrundar för sig, och summan av
	     avrundningarna sköt blocket 1 px över kanten på iPhone. Nämnaren
	     bär marginalen i stället för att varje tal gör det. ]]
	local skala = if skarmH > 0 then math.clamp(skarmH / 390, 0.62, 1) else 1
	local function px(n: number): number
		return math.floor(n * skala + 0.5)
	end
	--[[ Gallermåtten är borta med panelen. Kvar är kantmarginalen, som
	     spaken, blickytan och de två handlingarna delar. ]]
	local KANT = px(24)

	blickHook = hooks.blick
	local blickyta = nyRam("Blickyta", g)
	blickyta.Size = UDim2.new(0.66, 0, 1, 0)
	blickyta.Position = UDim2.fromScale(0.34, 0)
	blickyta.BackgroundTransparency = 1
	blickyta.ZIndex = 0
	--[[ `Active` gör att en genomskinlig ram tar emot fingret i stället
	     för att låta det falla igenom till världen bakom. ]]
	blickyta.Active = true
	kopplaBlick(blickyta)

	--[[ Spaken nere till vänster, knapparna nere till höger: samma sida som
	     webbversionen lägger dem, och samma sida som tummarna faktiskt är. ]]
	local bas = nyRam("Spak", g)
	local spakR = px(TouchControls.RADIE)
	bas.Size = UDim2.fromOffset(spakR * 2, spakR * 2)
	bas.Position = UDim2.new(0, KANT, 1, -(spakR * 2) - px(28))
	--[[ Vänsterkantens reserv: kanten, spaken och lika mycket luft som
		högerkanten får. Se noten vid `spakBredd`. ]]
	spakBredd = KANT + spakR * 2 + px(12)
	--[[ ...och var den BORJAR. Samma rad som placerar `bas` ovan, last av
	     Ugnetas replikslogg (#234). ]]
	spakTopp = skarmH - (spakR * 2) - px(28)
	bas.BackgroundTransparency = 0.55
	bas.BackgroundColor3 = Color3.fromRGB(24, 27, 33)
	local basHorn = Instance.new("UICorner")
	basHorn.CornerRadius = UDim.new(1, 0)
	basHorn.Parent = bas

	local knop = nyRam("Knop", bas)
	knop.Size = UDim2.fromOffset(TouchControls.KNAPP, TouchControls.KNAPP)
	knop.Position = UDim2.fromScale(0.5, 0.5)
	knop.AnchorPoint = Vector2.new(0.5, 0.5)
	knop.BackgroundTransparency = 0.1
	knop.BackgroundColor3 = Color3.fromRGB(214, 174, 60)
	local knopHorn = Instance.new("UICorner")
	knopHorn.CornerRadius = UDim.new(1, 0)
	knopHorn.Parent = knop

	--[[ ══ DE TVÅ KONTEXTUELLA KNAPPARNA ══════════════════════════════

	     HÄR LÅG PANELEN. Tio namngivna `TextButton` i två galler nere till
	     höger — HALT, SKRITT, TRAV, GALOPP, SAKTA i det ena; TYGEL, SITS,
	     HALVHALT, HOPPA, SITT AV i det andra. Fysisk QA på iPad 2026-09-17
	     underkände dem: det var en PC-simulators reglagepanel, inte en
	     ridyta. De var därefter släckta med `MINIMAL_UI`; arkitekturbeslutet
	     samma dag säger att de ska vara BORTA ur källan, inte osynliga.

	     I deras ställe finns två handlingar, och Roblox ritar dem själv:

	         DRIV   ett steg UPP i trappan
	         BROMS  ett steg NED, och ett steg till är rygga

	     `Input.bind()` band dem med `createTouchButton = true` innan den
	     här modulen monterades — ordningen är init.client:s, och den är
	     med flit: knappen måste finnas innan vi kan klä den.

	     VI RITAR INGEN AV DEM. Det enda som görs här är `SetTitle`,
	     `SetPosition` och genomskinlighet på knappar `ContextActionService`
	     äger. Det är skillnaden mot panelen, och det är den skillnaden
	     kontraktet handlar om. ]]

	--[[ Knappens sida och luften runt blocket, i samma skalade pixlar som
	     spaken. 86 px är större än panelens 52 — färre knappar får vara
	     större, och tummen som ska ge en hjälp mitt i en volt vill ha ett
	     stort mål. ]]
	local KD = px(86)
	local LUFT = px(12)
	--[[ ── TRE KNAPPAR I ETT 2×2, INTE EN STAPEL PÅ TRE ────────────────

	              [SITT AV] [DRIV ]
	                        [BROMS]

	     EN LODRÄT STAPEL PROVADES FÖRST och föll på mätning, av exakt
	     samma skäl som gångartsraden föll i #227: tre knappar à 86 px med
	     luft emellan är 294 px, och #208-skalan ger 249 px på iPhone 13 i
	     landskap där hela GUI-ytan är 331. Reserven sträckte sig då upp
	     till y = 62 och hjälpknappens `?` (y 48..96) låg rakt i den.

	     Ett 2×2 är hälften så högt (156 px) och lämnar hörnet fritt.

	     DRIV och BROMS står i HÖGERKOLUMNEN, ovanför varandra, där
	     högertummen vilar — upp är upp. Avsittningen ligger diagonalt
	     längst bort från BROMS, alltså i den ruta tummen når sist. Det är
	     medvetet: BROMS är den knapp man hamrar på, och en felträff ska
	     inte kasta av ryttaren. ]]
	local BLOCK_B = KD * 2 + LUFT
	local BLOCK_H = KD * 2 + LUFT
	reglageBredd = KANT + BLOCK_B + LUFT
	reglageTopp = skarmH - (BLOCK_H + KANT)

	--[[ Klär en handlings pekknapp. Allt går genom `ContextActionService`
	     — `SetTitle` och `SetPosition` är kontraktets, och `GetButton` är
	     vägen till de två egenskaper CAS inte har en setter för: storleken
	     och genomskinligheten.

	     `GetButton` svarar nil på skrivbordet, där ingen pekknapp skapades.
	     Det är inte ett fel — det är hela skälet att modulen bara monteras
	     på en pekenhet — så titeln sätts ändå och resten hoppas över. ]]
	local function klaHandling(handling: string, titel: string,
		franHoger: number, franBotten: number, genomskin: number)
		ContextActionService:SetTitle(handling, titel)
		--[[ Ankrat i skärmens nedre högra hörn, räknat inåt och uppåt.
		     Ankringen är knappens egen; positionen är det CAS-anrop
		     kontraktet pekar ut. ]]
		ContextActionService:SetPosition(handling,
			UDim2.new(1, -(KANT + franHoger), 1, -(KANT + franBotten)))
		local b = ContextActionService:GetButton(handling)
		if not b then return end
		b.AnchorPoint = Vector2.new(1, 1)
		b.Size = UDim2.fromOffset(KD, KD)
		--[[ Genomskinlighet, inte en solid platta: kontraktet säger att
		     knapparna ska ligga ÖVER ridningen utan att skymma den. ]]
		b.BackgroundTransparency = genomskin
		b.BackgroundColor3 = Color3.fromRGB(24, 27, 33)
		b.AutoButtonColor = false
		if b:IsA("ImageButton") then
			b.ImageTransparency = 1
		end
		local horn = b:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
		horn.CornerRadius = UDim.new(1, 0)
		horn.Parent = b
	end

	--[[ BROMS underst, DRIV ovanför. Tummen vilar lägst, och den hjälp man
	     ger oftast under en lektion är den som saktar ned. ]]
	klaHandling(Input.BROMS, Sprak.t("touch.broms"), 0, 0, 0.25)
	klaHandling(Input.DRIV, Sprak.t("touch.driv"), 0, KD + LUFT, 0.25)
	--[[ Avsittningen är svagare och sitter längst från tummen — den ska
	     vara hittbar, inte lättryckt. ]]
	--[[ Avsittningen är INTE ett reglage — den är enda vägen av hästen på
	     en ren pekenhet. #162 blockerare 2 var precis att en sådan väg
	     saknades: uppsittningen gick via en ProximityPrompt, avsittningen
	     låg bara på `E`, och en spelare utan tangentbord blev kvar i
	     sadeln. Panelens `SITT AV` löste det; när panelen rivs måste vägen
	     följa med, och den enda tillåtna vägen är en handling till.

	     `init.client` BINDER den — där ligger `begarAvsittning` — och den
	     är bunden hela ritten, också på skrivbordet. Här kläs den bara,
	     svagare och längst från tummen: den ska vara hittbar, inte
	     lättryckt. ]]
	klaHandling(Input.AVSITT, Sprak.t("touch.sitt_av"), KD + LUFT, KD + LUFT, 0.55)

	--[[ ══ EN VAKT MOT `ModalEnabled`, OCH EN MÄTPUNKT ════════════════

	     `egnaReglage(false)` nedan sätter `UserInputService.ModalEnabled`
	     för att släcka Roblox EGNA pekreglage — thumbsticken och
	     hoppknappen, som annars drar i samma kropp som vår spak (se noten
	     där). Den raden släcker `TouchGui`.

	     `ContextActionService` ritar sina knappar i en ANNAN yta,
	     `ContextActionGui`, och den ska inte beröras. Jag har läst det,
	     inte MÄTT det: bänken har ingen CoreGui och Studio har inte varit
	     tillgängligt i den här sessionen.

	     Det är den enda okända som kan göra iPad helt ostyrbar — knapparna
	     finns, men ingen ser dem — så vakten står här. Den gör ingenting i
	     normalfallet; blir ytan släckt tänds den igen, och `warn` gör att
	     Studio-QA kan SVARA på frågan i stället för att gissa.

	     Rapporteras som NOT_TESTED tills någon kört den på en enhet. ]]
	local function sakerstallSynlighet(handling: string)
		local b = ContextActionService:GetButton(handling)
		if not b then return end
		local yta = b:FindFirstAncestorWhichIsA("ScreenGui")
		if yta and yta.Enabled == false then
			yta.Enabled = true
			warn(("[UBRF] %s var släckt av en annan yta — tänd igen (%s)")
				:format(handling, yta.Name))
		end
	end
	kopplaSpak(bas, knop)
	egnaReglage(false)

	--[[ VAKTEN STÅR EFTER `egnaReglage`, OCH ORDNINGEN ÄR HELA POÄNGEN.

	     Den låg före. Då läste den ytan, fann den tänd, och gick vidare —
	     varefter `egnaReglage(false)` satte `ModalEnabled`. Är det den
	     raden som släcker `ContextActionGui`, vilket är precis det vakten
	     misstänker, hann vakten aldrig se sin egen skada. Den kunde bara
	     fånga en yta som var mörk REDAN INNAN monteringen började, och det
	     är inte det fall som gör en iPad ostyrbar.

	     Mätt i bänken: med `ModalEnabled` kopplad till det befarade
	     beteendet lämnade den gamla ordningen ytan `Enabled = false` efter
	     en fullständig montering. Nu tänds den igen, och `warn` gör att
	     Studio-QA kan SVARA på om raden behövdes. ]]
	for _, h in ipairs({ Input.DRIV, Input.BROMS, Input.AVSITT }) do
		sakerstallSynlighet(h)
	end

	local efter = hooks.efterLayout
	if efter then efter(reglageBredd, reglageTopp) end
end

function TouchControls.unmount()
	if gui then
		gui:Destroy()
		gui = nil
	end
	aktivFinger = nil
	--[[ Blicken hör till EN ritt. Lämnas fingret kvar hade nästa
	     uppsittning börjat med förra rittens finger fortfarande "nere".

	     DE TRE HANDLINGARNA RIVS INTE HÄR. `Input.unbind` river DRIV och
	     BROMS, `init.client` river avsittningen — de är bundna på alla
	     ytor, och pekytan är bara en av dem. Att riva dem härifrån hade
	     kopplat ur skrivbordets tangenter när en pekyta försvann. ]]
	reglageBredd = 0
	spakBredd = 0
	spakTopp = math.huge
	reglageTopp = math.huge
	blickFinger, blickSist, blickHook = nil, nil, nil
	if ytaKoppling then
		ytaKoppling:Disconnect()
		ytaKoppling = nil
	end
	--[[ Nollas så att nästa `mount` alltid räknar om, oavsett vilken yta
		den monteras på. ]]
	byggdHojd = 0
	if Input then Input.setTouch(0, 0) end
	if styrningAv then egnaReglage(true) end
	--[[ Reserven är borta: den som vek undan för den får hörnet tillbaka. ]]
	local h = senasteHooks
	local efter = h and h.efterLayout
	if efter then efter(0, math.huge) end
end

function TouchControls.isActive(): boolean
	return gui ~= nil
end

return TouchControls
