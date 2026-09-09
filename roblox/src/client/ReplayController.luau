--!strict
--[[
	RIDANALYSEN PÅ ROBLOX — spelaren får se sin egen ritt.

	G02-D (#137): efter ett avslutat försök ska ritten gå att SE, inte
	bara läsas om i två meningar. Panelen ritar den inspelade vägen i
	planvy, låter spelaren spela, pausa, hoppa och sakta ned — och lägger
	FÖRRA försöket bakom som ett spöke, så att "bättre linje den här
	gången" är något hon kan se och inte bara ett påstående.

	LÄSER, ÄNDRAR ALDRIG. Panelen rör inte posten, inte hästen, inte
	progressionen och inget serverauktoritativt tillstånd. Den svarar bara
	på frågan "hur såg ritten ut vid tiden t?" genom Inspelning.vid, som
	är ren avläsning. Det finns ingen andra bedömningsmodell här: panelen
	betygsätter ingenting.

	INGEN PÅHITTAD IDEALLINJE. Spöket är spelarens EGET förra försök. En
	streckad "så borde du ha ridit"-kurva hade varit en uppfunnen referens
	och är uttryckligen inte beställd — finns inget förra försök ritas
	inget spöke, och panelen säger det i stället för att fylla hålet.

	SÄKERHET VINNER, precis som i UgnetaController. `stang` kan anropas
	från avsittningen, från karaktärens försvinnande eller från
	LektionController.avbryt, och den släpper då både RenderStepped-
	kopplingen och alla referenser till posterna. En panel får aldrig bli
	kvar över en ritt som inte finns längre.

	INMATNINGEN ÄGS AV init.client.luau. Musen och fingret går in genom
	knapparnas egna Activated; tangent och gamepad kommer in genom de
	publika funktionerna nedan. HUD:en lyssnar inte själv på
	UserInputService — samma regel som resten av klienten.

	MINDRE RÖRELSE OM SPELAREN BETT OM DET. Är GuiService.
	ReducedMotionEnabled satt startar panelen PAUSAD i stället för att
	genast sätta igång en markör som rör sig av sig själv. Spelaren
	scrubbar då i sin egen takt. Inget innehåll går förlorat — bara den
	automatiska rörelsen.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local Inspelning = require(game:GetService("ReplicatedStorage").HorseCore.Inspelning)

local ReplayController = {}

local player = Players.LocalPlayer

local gui: ScreenGui? = nil
local bana: Frame? = nil
local markor: Frame? = nil
local tidLabel: TextLabel? = nil
local statusLabel: TextLabel? = nil
local spelaKnapp: TextButton? = nil

local aktiv = false
local post: Inspelning.Post? = nil
local ghost: Inspelning.Post? = nil
local tid = 0
local fart = 1
local spelar = false
local conn: RBXScriptConnection? = nil
local stangFn: (() -> ())? = nil

--[[ Banans utsträckning i postens egna koordinater. Räknas om vid varje
     öppning: två försök på samma övning kan täcka olika stor yta, och en
     fast ram hade klippt det ena. ]]
local minx, maxx, minz, maxz = 0, 1, 0, 1

local FARG_MORK = Color3.fromRGB(12, 14, 18)
local FARG_GULD = Color3.fromRGB(232, 181, 74)
local FARG_TEXT = Color3.fromRGB(246, 242, 232)
local FARG_NU = Color3.fromRGB(127, 180, 137)
local FARG_FORE = Color3.fromRGB(214, 174, 60)

--[[ Högst så många punkter ritas per ritt. En 120-sekunders post har 2400
     sampel; att rita dem alla vore 2400 Frames för en linje ögat ändå
     läser som en kurva. Steget räknas ur postens längd, så en kort och en
     lång ritt kostar lika mycket att rita. ]]
local PUNKTER_NU = 120
local PUNKTER_FORE = 100

local function reducerRorelse(): boolean
	--[[ Egenskapen finns inte på alla klienter. Ett explicit typtest, inte
	     ett pcall: ett pcall hade dolt varje annat fel i samma andetag. ]]
	local v = (GuiService :: any).ReducedMotionEnabled
	return v == true
end

local function tomBana()
	local b = bana
	if not b then return end
	for _, c in b:GetChildren() do
		if c.Name == "Nu" or c.Name == "Fore" then c:Destroy() end
	end
end

--[[ Utsträckningen över BÅDA posterna, så att spöket och ritten ligger i
     samma skala. Ligger de i var sin ram går de inte att jämföra, och
     jämförelsen är hela poängen med spöket. ]]
local function ram()
	minx, maxx, minz, maxz = math.huge, -math.huge, math.huge, -math.huge
	local function ta(p: Inspelning.Post?)
		if not p then return end
		for _, s in p.sampel do
			if s.x ~= nil and s.z ~= nil then
				minx = math.min(minx, s.x); maxx = math.max(maxx, s.x)
				minz = math.min(minz, s.z); maxz = math.max(maxz, s.z)
			end
		end
	end
	ta(post); ta(ghost)
	--[[ Ingen mätt position alls — då finns ingen bana att rita. En
	     hopfallen ram (division med noll) är värre än en tom ruta. ]]
	if minx == math.huge then minx, maxx, minz, maxz = 0, 1, 0, 1 end
	if maxx - minx < 1 then maxx = minx + 1 end
	if maxz - minz < 1 then maxz = minz + 1 end
end

local function skala(x: number, z: number): (number, number)
	return (x - minx) / (maxx - minx), (z - minz) / (maxz - minz)
end

local function punkt(s: Inspelning.Sampel, namn: string, farg: Color3, genomskin: number)
	local b = bana
	if not b or s.x == nil or s.z == nil then return end
	local u, v = skala(s.x, s.z)
	local d = Instance.new("Frame")
	d.Name = namn
	d.Size = UDim2.fromOffset(4, 4)
	d.AnchorPoint = Vector2.new(0.5, 0.5)
	d.Position = UDim2.fromScale(u, 1 - v)
	d.BackgroundColor3 = farg
	d.BackgroundTransparency = genomskin
	d.BorderSizePixel = 0
	d.ZIndex = 3
	d.Parent = b
end

local function ritaSpar(p: Inspelning.Post?, namn: string, farg: Color3,
	genomskin: number, tak: number)
	if not p or #p.sampel == 0 then return end
	local steg = math.max(1, math.floor(#p.sampel / tak))
	for i = 1, #p.sampel, steg do
		punkt(p.sampel[i], namn, farg, genomskin)
	end
end

--[[ Tangentledtext bara där tangenten FINNS — samma regel som
     UgnetaController.medLedtext, och av samma skäl: en ren pekenhet ska
     inte få en bokstav hon inte kan trycka på. ]]
local function medLedtext(txt: string, tangent: string, pad: string): string
	if UserInputService.KeyboardEnabled then return `{txt}  ({tangent})` end
	if UserInputService.GamepadEnabled then return `{txt}  ({pad})` end
	return txt
end

local function bygg()
	if gui then return end
	local g = Instance.new("ScreenGui")
	g.Name = "UBRFReplay"
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = true
	g.DisplayOrder = 20
	g.Enabled = false
	g.Parent = player:WaitForChild("PlayerGui")
	gui = g

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Size = UDim2.new(0.9, 0, 0.78, 0)
	panel.Position = UDim2.new(0.05, 0, 0.11, 0)
	panel.BackgroundColor3 = FARG_MORK
	panel.BackgroundTransparency = 0.04
	panel.Parent = g
	local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0, 10); pc.Parent = panel

	local rubrik = Instance.new("TextLabel")
	rubrik.Name = "Rubrik"
	rubrik.Size = UDim2.new(1, -24, 0, 30)
	rubrik.Position = UDim2.fromOffset(12, 8)
	rubrik.BackgroundTransparency = 1
	rubrik.Text = "Din ritt"
	rubrik.TextColor3 = FARG_TEXT
	rubrik.TextXAlignment = Enum.TextXAlignment.Left
	rubrik.Font = Enum.Font.GothamBold
	rubrik.TextSize = 18
	rubrik.Parent = panel

	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.Size = UDim2.new(1, -24, 0, 18)
	status.Position = UDim2.fromOffset(12, 34)
	status.BackgroundTransparency = 1
	status.Text = ""
	status.TextColor3 = FARG_FORE
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.Font = Enum.Font.Gotham
	status.TextSize = 12
	status.Parent = panel
	statusLabel = status

	local b = Instance.new("Frame")
	b.Name = "Bana"
	b.Size = UDim2.new(1, -24, 1, -118)
	b.Position = UDim2.fromOffset(12, 56)
	b.BackgroundColor3 = Color3.fromRGB(24, 27, 33)
	b.ClipsDescendants = true
	b.Parent = panel
	bana = b

	local m = Instance.new("Frame")
	m.Name = "Markor"
	m.Size = UDim2.fromOffset(10, 10)
	m.AnchorPoint = Vector2.new(0.5, 0.5)
	m.BackgroundColor3 = Color3.fromRGB(255, 249, 236)
	m.BorderSizePixel = 0
	m.ZIndex = 5
	m.Parent = b
	markor = m

	local rad = Instance.new("Frame")
	rad.Name = "Kontroller"
	rad.Size = UDim2.new(1, -24, 0, 48)
	rad.Position = UDim2.new(0, 12, 1, -56)
	rad.BackgroundTransparency = 1
	rad.Parent = panel
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 6)
	layout.Parent = rad

	local function knapp(namn: string, txt: string, ordning: number, fn: () -> ()): TextButton
		local x = Instance.new("TextButton")
		x.Name = namn
		x.AutoButtonColor = true
		x.LayoutOrder = ordning
		--[[ 44 px hög: minsta träffyta som går att peka på med ett finger.
		     Familjen spelar på iPad och telefon. ]]
		x.Size = UDim2.fromOffset(104, 44)
		x.BackgroundColor3 = FARG_GULD
		x.TextColor3 = Color3.fromRGB(23, 20, 10)
		x.Font = Enum.Font.GothamBold
		x.TextSize = 12
		x.Text = txt
		x.ZIndex = 6
		x.Parent = rad
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = x
		x.Activated:Connect(fn)
		return x
	end

	spelaKnapp = knapp("Spela", medLedtext("Spela", "T", "X"), 1, function()
		ReplayController.spelaPausa()
	end)
	knapp("Bak", "−5 s", 2, function() ReplayController.hoppa(-5) end)
	knapp("Fram", "+5 s", 3, function() ReplayController.hoppa(5) end)
	knapp("Fart", "0,5×", 4, function() ReplayController.vaxlaFart() end)
	knapp("Stang", medLedtext("Tillbaka", "R", "Y"), 5, function()
		ReplayController.stang()
	end)

	local tl = Instance.new("TextLabel")
	tl.Name = "Tid"
	tl.Size = UDim2.fromOffset(120, 44)
	tl.BackgroundTransparency = 1
	tl.TextColor3 = FARG_TEXT
	tl.LayoutOrder = 6
	tl.Font = Enum.Font.Gotham
	tl.TextSize = 12
	tl.Text = ""
	tl.Parent = rad
	tidLabel = tl
end

local function rita()
	local p = post
	if not p then return end
	local m = markor
	if m then
		local s = Inspelning.vid(p, tid)
		if s and s.x ~= nil and s.z ~= nil then
			local u, v = skala(s.x, s.z)
			m.Position = UDim2.fromScale(u, 1 - v)
			m.Visible = true
		else
			--[[ Ingen mätt position vid den här tidpunkten. Markören
			     försvinner hellre än ställer sig i ett hörn och påstår
			     att hästen var där. ]]
			m.Visible = false
		end
	end
	local tl = tidLabel
	if tl then tl.Text = string.format("%.1f / %.1f s", tid, p.sekunder) end
	local sk = spelaKnapp
	if sk then
		sk.Text = medLedtext(if spelar then "Pausa" else "Spela", "T", "X")
	end
end

--[[ ── Publikt: öppna, stäng, styr ──────────────────────────────── ]]

--[[ Öppnar panelen på en post. `fore` är förra försöket på samma övning,
     eller nil. Returnerar false när posten inte går att spela upp — då
     har ingenting öppnats och den som frågade får veta det i stället för
     att stå med en tom panel.

     Posten VERSIONSKONTROLLERAS. En post skriven av ett äldre schema
     tolkas inte tyst mot dagens definition; ett spöke från en äldre
     övningsversion visas men MÄRKS, eftersom en jämförelse mot den inte
     betyder samma sak. ]]
function ReplayController.oppna(nyPost: Inspelning.Post?, fore: Inspelning.Post?,
	nyStangFn: (() -> ())?): boolean
	if type(nyPost) ~= "table" then return false end
	local las = Inspelning.lasbar(nyPost)
	if not las.ok then return false end
	if #nyPost.sampel == 0 then return false end

	bygg()
	post = nyPost
	--[[ Ett spöke som inte går att läsa är inget spöke. Hellre ingen
	     jämförelse än en jämförelse mot något vi inte vet betydelsen av. ]]
	local foreLas = if type(fore) == "table" then Inspelning.lasbar(fore) else nil
	ghost = if foreLas and foreLas.ok and fore and #fore.sampel > 0 then fore else nil
	stangFn = nyStangFn
	tid = 0
	fart = 1
	--[[ Startar pausad när spelaren bett om mindre rörelse. ]]
	spelar = not reducerRorelse()
	aktiv = true

	local g = gui
	if g then g.Enabled = true end
	tomBana()
	ram()
	ritaSpar(ghost, "Fore", FARG_FORE, 0.45, PUNKTER_FORE)
	ritaSpar(post, "Nu", FARG_NU, 0.15, PUNKTER_NU)

	local st = statusLabel
	if st then
		if not ghost then
			st.Text = "Första försöket — inget tidigare att jämföra med."
		elseif foreLas and foreLas.lage == "gammal" then
			st.Text = `Förra försöket ligger bakom i gult ({foreLas.skal}).`
		elseif las.lage == "gammal" then
			st.Text = `Förra försöket ligger bakom i gult ({las.skal}).`
		else
			st.Text = "Förra försöket ligger bakom i gult."
		end
	end

	if conn then conn:Disconnect() end
	conn = RunService.RenderStepped:Connect(function(dt: number)
		--[[ En bildruta som redan var i luften när panelen stängdes får
		     inte rita i en stängd panel. ]]
		if not aktiv then return end
		local p = post
		if not p then return end
		if spelar and type(dt) == "number" and dt > 0 then
			tid = math.min(p.sekunder, tid + dt * fart)
			if tid >= p.sekunder then spelar = false end
		end
		rita()
	end)
	rita()
	return true
end

--[[ Stänger panelen. Idempotent, och släpper ALLT: kopplingen, posterna
     och återanropet. Anropas från avsittningen och från
     LektionController.avbryt lika gärna som från Tillbaka-knappen. ]]
function ReplayController.stang()
	if conn then conn:Disconnect(); conn = nil end
	aktiv = false
	spelar = false
	post = nil
	ghost = nil
	tid = 0
	local g = gui
	if g then g.Enabled = false end
	tomBana()
	--[[ Återanropet nollas FÖRE det körs. Annars kunde ett `stang` inuti
	     återanropet köra samma callback en gång till. ]]
	local fn = stangFn
	stangFn = nil
	if fn then fn() end
end

function ReplayController.aktiv(): boolean
	return aktiv
end

function ReplayController.spelaPausa(): boolean
	if not aktiv or not post then return false end
	spelar = not spelar
	--[[ Står uppspelningen på slutet betyder Spela "spela om", inte
	     "stå kvar på sista bildrutan". ]]
	if spelar and tid >= (post :: Inspelning.Post).sekunder then tid = 0 end
	rita()
	return true
end

function ReplayController.hoppa(delta: number): boolean
	local p = post
	if not aktiv or not p then return false end
	if type(delta) ~= "number" or delta ~= delta then return false end
	tid = math.max(0, math.min(p.sekunder, tid + delta))
	rita()
	return true
end

function ReplayController.vaxlaFart(): number
	if not aktiv then return fart end
	fart = if fart == 1 then 0.5 else 1
	return fart
end

--[[ Läget, för prov och för den som kör lektionen. Ren avläsning — en
     kopia, så att ingen kan skriva i panelens tillstånd genom den. ]]
function ReplayController.lage(): { [string]: any }
	return {
		aktiv = aktiv, spelar = spelar, tid = tid, fart = fart,
		harFore = ghost ~= nil,
		sekunder = if post then (post :: Inspelning.Post).sekunder else 0,
	}
end

return ReplayController
