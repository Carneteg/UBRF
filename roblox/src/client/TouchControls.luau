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
local blickFinger: InputObject? = nil
local blickSist: Vector2? = nil
local blickHook: ((number, number) -> ())? = nil
local gaitKoppling: RBXScriptConnection? = nil

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

local function nyKnapp(namn: string, text: string, parent: Instance,
	bredd: number?, hojd: number?): TextButton
	local b = Instance.new("TextButton")
	b.Name = namn
	b.Text = text
	b.AutoButtonColor = false
	--[[ 44 px är golvet för ett touchmål, och 56 är vad en tumme vill ha
	     när man samtidigt håller i telefonen med samma hand.

	     BREDDEN VAR 64 OCH TEXTEN FICK INTE PLATS. Mätt i landskap på
	     iPad Air, `TextBounds.X` mot knappens bredd:
	         ▲ FORWARD 86 · HALF-HALT 78 · DISMOUNT 76 · DEEP SEAT 76
	         ▼ SLOWER 73   mot 64 px — fem av sju spillde över kanten
	     och klipptes mot skärmkanten, eftersom `TextScaled` är false och
	     ingenting klipper. 92 px rymmer den längsta med luft kvar, ligger
	     fortfarande innanför knappramens 150, och ger tummen ett STÖRRE
	     mål — inte ett mindre. `TextWrapped` finns för översättningar som
	     är längre än de engelska. ]]
	b.Size = UDim2.fromOffset(bredd or 92, hojd or 56)
	b.TextWrapped = true
	b.BackgroundColor3 = Color3.fromRGB(24, 27, 33)
	b.BackgroundTransparency = 0.18
	b.TextColor3 = Color3.fromRGB(236, 232, 222)
	b.TextSize = 15
	b.Font = Enum.Font.GothamMedium
	b.BorderSizePixel = 0
	b.Parent = parent
	local horn = Instance.new("UICorner")
	horn.CornerRadius = UDim.new(0, 14)
	horn.Parent = b
	return b
end

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
--[[ `blick` får skillnaden i radianer och studs från blickytan; `modell`
     är hästen, och används bara för att visa vilken gångart som är
     aktiv. Båda är valfria, så en anropare som inte bryr sig om dem
     fortfarande fungerar. ]]
function TouchControls.mount(input: any, hooks: {
	dismount: () -> (),
	blick: ((number, number) -> ())?,
	modell: Instance?,
})
	if gui then return end
	if not UserInputService.TouchEnabled then return end
	Input = input

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

	--[[ BLICKYTAN FÖRST, så att allt annat hamnar ovanpå den. Den täcker
	     högra två tredjedelarna; vänstra tredjedelen är spakens. ]]
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
	bas.Size = UDim2.fromOffset(TouchControls.RADIE * 2, TouchControls.RADIE * 2)
	bas.Position = UDim2.new(0, 24, 1, -(TouchControls.RADIE * 2) - 28)
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

	--[[ ══ EN KOMPAKT LANDSKAPSLAYOUT ═══════════════════════════════════

	     Den gamla var EN lodrät stapel till höger. Med de namngivna
	     gångarterna hade den blivit tolv knappar på rad: mätt rymde
	     ramen 344 px medan sju knappar redan krävde 7·56 + 6·10 = 452.
	     Att bara förlänga den hade skjutit knappar ur bild.

	     Nu ligger de i två 2-kolumnsgaller, båda ankrade i högerkanten,
	     båda 194 px breda (2·92 + 10) och 172 px höga (3·52 + 2·8):

	         HJÄLPERNA nederst: tygel, sits, halvhalt, hopp, avsittning.
	         GÅNGARTERNA ovanför: halt, skritt, trav, galopp, sakta.

	     Total höjd i högerkanten: 24 + 172 + 12 + 172 = 380 px av 768 på
	     den lägsta iPad:en i landskap.

	     EN VÅGRÄT GÅNGARTSRAD PROVADES FÖRST och föll på mätning: 462 px
	     bred längst ned lade GALOPP och HALT under lektionskortet, som
	     står på (270 · 577) och är 640×170. Träffprovet sa `overst=Kort`
	     för båda. Kortet äger mitten; reglagen håller sig i kanten.

	     Mitten lämnas alltså fri — hästen, banan och lektionstexten ska
	     synas, och spaken har hela vänsterkanten för sig. ]]

	--[[ GÅNGARTERNA. Namngivna knappar, inte bara ▲/▼: en ryttare tänker
	     "trav", inte "ett steg upp". De stegar i samma trappa som
	     tangenterna — `Input.touchGaitTo` lämnar ett namn, och
	     `MovementController:_targetGait` gör om det till samma index och
	     samma tak som förut. ]]
	local gangrad = nyRam("Gangarter", g)
	gangrad.Size = UDim2.fromOffset(194, 172)
	gangrad.Position = UDim2.new(1, -218, 1, -380)
	local grad = Instance.new("UIGridLayout")
	grad.CellSize = UDim2.fromOffset(92, 52)
	grad.CellPadding = UDim2.fromOffset(10, 8)
	grad.FillDirectionMaxCells = 2
	--[[ `SortOrder` är `Name` som standard, och då står gångarterna i
	     bokstavsordning: galopp, halt, sakta, skritt, trav. Mätt precis
	     så på iPad innan den här raden fanns. Trappan ska läsas som en
	     trappa, alltså efter `LayoutOrder`. ]]
	grad.SortOrder = Enum.SortOrder.LayoutOrder
	grad.HorizontalAlignment = Enum.HorizontalAlignment.Right
	grad.VerticalAlignment = Enum.VerticalAlignment.Bottom
	grad.Parent = gangrad

	local gangKnapp: { [string]: TextButton } = {}
	local function nyGang(namn: string, nyckel: string, gait: string, ordning: number)
		local b = nyKnapp(namn, Sprak.t(nyckel), gangrad, 92, 52)
		b.LayoutOrder = ordning
		b.MouseButton1Click:Connect(function() Input.touchGaitTo(gait) end)
		gangKnapp[gait] = b
		return b
	end
	--[[ Ordningen läses rad för rad och går från stillastående till
	     snabbast, med SAKTA sist som handlingen tillbaka nedåt:
	         HALT   SKRITT
	         TRAV   GALOPP
	         SAKTA ]]
	nyGang("Halt", "touch.halt", "halt", 1)
	nyGang("Skritt", "touch.skritt", "walk", 2)
	nyGang("Trav", "touch.trav", "trot", 3)
	nyGang("Galopp", "touch.galopp", "canter", 4)
	--[[ SAKTA är med flit RELATIV och inte en plats i trappan: den är
	     "ett steg ned härifrån", vilket är vad en ryttare menar med att
	     sakta. Den delar knappordning med de namngivna för att raden ska
	     läsas som en skala från lugnast till snabbast och tillbaka. ]]
	local sakta = nyKnapp("Sakta", Sprak.t("touch.sakta"), gangrad, 92, 52)
	sakta.LayoutOrder = 5
	sakta.MouseButton1Click:Connect(function() Input.touchGait(false) end)

	--[[ VILKEN GÅNGART ÄR AKTIV. Läses ur hästens egen `Gait`-attribut,
	     alltså samma sanning som allt annat visar — knapparna håller
	     inget eget läge som kan glida isär från hästen. ]]
	local function malaAktiv(gait: string?)
		for namn, b in pairs(gangKnapp) do
			local pa = (namn == gait)
			b.BackgroundColor3 = if pa then Color3.fromRGB(214, 174, 60)
				else Color3.fromRGB(24, 27, 33)
			b.TextColor3 = if pa then Color3.fromRGB(28, 24, 12)
				else Color3.fromRGB(236, 232, 222)
			b.BackgroundTransparency = if pa then 0.05 else 0.18
		end
		--[[ SAKTA är en handling, inte ett läge, och lyser därför aldrig. ]]
	end
	local modell = hooks.modell
	if modell then
		malaAktiv(modell:GetAttribute("Gait") :: string?)
		gaitKoppling = modell:GetAttributeChangedSignal("Gait"):Connect(function()
			malaAktiv(modell:GetAttribute("Gait") :: string?)
		end)
	end

	--[[ HJÄLPERNA i två kolumner. ]]
	local knappar = nyRam("Knappar", g)
	knappar.Size = UDim2.fromOffset(194, 172)
	knappar.Position = UDim2.new(1, -218, 1, -196)
	local rad = Instance.new("UIGridLayout")
	rad.CellSize = UDim2.fromOffset(92, 52)
	rad.CellPadding = UDim2.fromOffset(10, 8)
	rad.FillDirectionMaxCells = 2
	rad.SortOrder = Enum.SortOrder.LayoutOrder
	rad.HorizontalAlignment = Enum.HorizontalAlignment.Right
	rad.VerticalAlignment = Enum.VerticalAlignment.Bottom
	rad.Parent = knappar

	local av = nyKnapp("Av", Sprak.t("touch.sitt_av"), knappar, 92, 52)
	local hoppa = nyKnapp("Hoppa", Sprak.t("touch.hoppa"), knappar, 92, 52)
	--[[ ▲ FRAMÅT och ▼ LUGNARE finns inte längre som egna knappar på
	     pekskärmen: gångartsraden nedanför säger samma sak med namn i
	     stället för pilar, och SAKTA är exakt samma relativa steg ned som
	     ▼ var. Tangentbordets Shift/Ctrl är orörda. ]]
	--[[ G02-B: TYGELN och PARADEN på pekskärmen. Utan dem kan en spelare
	     med pekskärm varken hålla kontakten eller ge en halvhalt, och då
	     är yttertygelstödet — och därmed hästens balans i svängen —
	     stängt för hela den plattformen. Webben har samma två på sin
	     pekskärm (HALVHALT-knappen och tygeln). ]]
	local tygel = nyKnapp("Tygel", Sprak.t("touch.tygel"), knappar, 92, 52)
	local parad = nyKnapp("Parad", Sprak.t("touch.halvhalt"), knappar, 92, 52)
	--[[ Sitsen: hålls, som tygeln. Djup sits bär bågen — se
	     SVAR.BALANS_VIKT. Utan knappen kan en spelare med pekskärm inte
	     stödja volten med sätet, och då är den delen av modellen stängd
	     för hela plattformen. ]]
	local sits = nyKnapp("Sits", Sprak.t("touch.djup_sits"), knappar, 92, 52)
	tygel.LayoutOrder, sits.LayoutOrder, parad.LayoutOrder = 1, 2, 3
	hoppa.LayoutOrder, av.LayoutOrder = 4, 5

	hoppa.MouseButton1Click:Connect(function() Input.touchJump() end)
	av.MouseButton1Click:Connect(hooks.dismount)

	--[[ Tygeln HÅLLS — kontakten är ett tillstånd, inte en händelse — och
	     paraden är en impuls, precis som flanken på F. Att göra tvärtom
	     hade gett en tygel man knäpper på och en halvhalt man kan hålla
	     inne, och ingetdera är ridning. ]]
	tygel.MouseButton1Down:Connect(function() Input.setTouchRein(1) end)
	tygel.MouseButton1Up:Connect(function() Input.setTouchRein(0) end)
	tygel.MouseLeave:Connect(function() Input.setTouchRein(0) end)
	parad.MouseButton1Click:Connect(function() Input.touchParad() end)
	sits.MouseButton1Down:Connect(function() Input.setTouchSeat(1) end)
	sits.MouseButton1Up:Connect(function() Input.setTouchSeat(0) end)
	sits.MouseLeave:Connect(function() Input.setTouchSeat(0) end)

	kopplaSpak(bas, knop)
	egnaReglage(false)
end

function TouchControls.unmount()
	if gui then
		gui:Destroy()
		gui = nil
	end
	aktivFinger = nil
	--[[ Blicken och gångartslyset hör till EN ritt. Lämnas de kvar pekar
	     kopplingen på en häst man klivit av, och nästa uppsittning hade
	     börjat med förra rittens finger fortfarande "nere". ]]
	blickFinger, blickSist, blickHook = nil, nil, nil
	if gaitKoppling then
		gaitKoppling:Disconnect()
		gaitKoppling = nil
	end
	if Input then Input.setTouch(0, 0) end
	if styrningAv then egnaReglage(true) end
end

function TouchControls.isActive(): boolean
	return gui ~= nil
end

return TouchControls
