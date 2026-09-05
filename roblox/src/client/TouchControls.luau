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

local function nyRam(namn: string, parent: Instance): Frame
	local f = Instance.new("Frame")
	f.Name = namn
	f.BackgroundTransparency = 1
	f.BorderSizePixel = 0
	f.Parent = parent
	return f
end

local function nyKnapp(namn: string, text: string, parent: Instance): TextButton
	local b = Instance.new("TextButton")
	b.Name = namn
	b.Text = text
	b.AutoButtonColor = false
	--[[ 44 px är golvet för ett touchmål, och 56 är vad en tumme vill ha
	     när man samtidigt håller i telefonen med samma hand. ]]
	b.Size = UDim2.fromOffset(64, 56)
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

--[[ Roblox egna pekreglage flyttar KARAKTÄREN. Sitter hon i sadeln blir
     det två saker som drar i samma kropp, och i värsta fall reser hon sig
     ur sitsen mitt i galoppen. De stängs av medan man rider och sätts på
     igen vid avsittning — inte permanent, eftersom spelaren ska kunna gå
     till fots i stallet som vanligt. ]]
local styrningAv = false
local function egnaReglage(pa: boolean)
	local scripts = Players.LocalPlayer:FindFirstChild("PlayerScripts")
	local modul = scripts and scripts:FindFirstChild("PlayerModule")
	if not modul then return end
	local ok, controls = pcall(function()
		return (require(modul) :: any):GetControls()
	end)
	if not ok or not controls then return end
	if pa then controls:Enable() else controls:Disable() end
	styrningAv = not pa
end

--[[ `hooks.dismount` kallas när spelaren trycker på avsittningsknappen —
     pekskärmen har ingen E-tangent att trycka på. ]]
function TouchControls.mount(input: any, hooks: { dismount: () -> () })
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
	g.Parent = mapp

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

	local knappar = nyRam("Knappar", g)
	knappar.Size = UDim2.fromOffset(150, 296)
	knappar.Position = UDim2.new(1, -168, 1, -324)
	local rad = Instance.new("UIListLayout")
	rad.FillDirection = Enum.FillDirection.Vertical
	rad.HorizontalAlignment = Enum.HorizontalAlignment.Right
	rad.VerticalAlignment = Enum.VerticalAlignment.Bottom
	rad.Padding = UDim.new(0, 10)
	rad.Parent = knappar

	local av = nyKnapp("Av", "SITT AV", knappar)
	local hoppa = nyKnapp("Hoppa", "HOPP", knappar)
	local ned = nyKnapp("Ned", "▼ LUGNARE", knappar)
	local upp = nyKnapp("Upp", "▲ FRAMÅT", knappar)
	--[[ G02-B: TYGELN och PARADEN på pekskärmen. Utan dem kan en spelare
	     med pekskärm varken hålla kontakten eller ge en halvhalt, och då
	     är yttertygelstödet — och därmed hästens balans i svängen —
	     stängt för hela den plattformen. Webben har samma två på sin
	     pekskärm (HALVHALT-knappen och tygeln). ]]
	local tygel = nyKnapp("Tygel", "TYGEL", knappar)
	local parad = nyKnapp("Parad", "HALVHALT", knappar)
	upp.LayoutOrder, ned.LayoutOrder = 1, 2
	tygel.LayoutOrder, parad.LayoutOrder = 3, 4
	hoppa.LayoutOrder, av.LayoutOrder = 5, 6

	--[[ Gångartsknapparna är flanktriggade i `Input`: ett tryck ger ett
	     byte, hur länge man än håller kvar. Att hålla ned ska inte rusa
	     genom skritt–trav–galopp. ]]
	upp.MouseButton1Click:Connect(function() Input.touchGait(true) end)
	ned.MouseButton1Click:Connect(function() Input.touchGait(false) end)
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

	kopplaSpak(bas, knop)
	egnaReglage(false)
end

function TouchControls.unmount()
	if gui then
		gui:Destroy()
		gui = nil
	end
	aktivFinger = nil
	if Input then Input.setTouch(0, 0) end
	if styrningAv then egnaReglage(true) end
end

function TouchControls.isActive(): boolean
	return gui ~= nil
end

return TouchControls
