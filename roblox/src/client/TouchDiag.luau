--!strict
--[[ TOUCHDIAG — TILLFÄLLIG MÄTUTRUSTNING FÖR ACCEPTANSEN PÅ RIKTIG iPAD.

	╔══════════════════════════════════════════════════════════════════╗
	║  DEN HÄR FILEN SKA BORT EFTER ACCEPTANSEN.                       ║
	║  Allt som rör den är märkt `TOUCHDIAG` — sök på ordet och ta      ║
	║  bort träffarna, så är den ur spelet:                            ║
	║      · den här filen                                             ║
	║      · fyra rader i `TouchControls.luau`                         ║
	║      · två rader i `init.client.luau`                            ║
	╚══════════════════════════════════════════════════════════════════╝

	VARFÖR EN RUTA PÅ SKÄRMEN OCH INTE EN LOGG. Mätningen ska göras på en
	fysisk iPad. Där finns ingen Studio-utskrift att läsa, och frågan
	"satt ett finger kvar?" går inte att svara på i efterhand från minnet.
	Alltså måste svaret stå på skärmen medan handen ligger kvar.

	Den mäter ÄGARSKAP, inte rörelse: vilket `InputObject` som äger spaken
	och vilket som äger blicken, när de togs, när de släpptes, och — det
	som hela multi-touch-grinden hänger på — om något fortfarande ägs när
	alla fingrar lyfts. Det sista är den enda frågan man inte kan se med
	ögat.

	Den rör ingenting. Den läser och ritar. ]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local TouchDiag = {}

--[[ Alla anrop går genom `pa`. Står den falskt är modulen några döda
	 funktionsanrop och ingenting annat — så att en kvarglömd rad aldrig
	 kan kosta något i en riktig spelsession. ]]
TouchDiag.pa = true

local gui: ScreenGui? = nil
local rutor: { [string]: TextLabel } = {}
local logg: { string } = {}
local LOGG_MAX = 8

--[[ `InputObject` har inget läsbart namn. Fingrarna får ett eget löpnummer
	 första gången de ses, så att två rader i loggen går att para ihop. ]]
local nummer: { [InputObject]: number } = {}
local nastaNummer = 0
local function nr(obj: InputObject?): string
	if not obj then return "–" end
	local o = obj :: InputObject
	if not nummer[o] then
		nastaNummer += 1
		nummer[o] = nastaNummer
	end
	return "#" .. tostring(nummer[o])
end

--[[ Vad modulen känner till om världen. Fylls av anroparna. ]]
local agare: { [string]: { obj: InputObject?, tagen: number? } } = {
	spak = {},
	blick = {},
}
local axelX, axelY = 0, 0
local levandeFingrar: { [InputObject]: boolean } = {}
local antalFingrar = 0
local foraldralost: string? = nil
local ctx: { movement: any?, modell: Instance? } = {}

local function nu(): number
	return os.clock()
end

local function skrivLogg(rad: string)
	table.insert(logg, ("%7.2f  %s"):format(nu() % 1000, rad))
	while #logg > LOGG_MAX do table.remove(logg, 1) end
end

--[[ ── DET ANROPARNA SÄGER ──────────────────────────────────────────── ]]

--[[ `kanal` är "spak" eller "blick". `handelse` är "CLAIM" eller "END".
	 Läget på fingret följer med vid släpp: `Cancel` är det iOS gör när en
	 systemgest tar över, och det är precis det fall som kan lämna ett
	 ägarskap kvar utan att någon lyft handen. ]]
function TouchDiag.hand(kanal: string, obj: InputObject?, handelse: string)
	if not TouchDiag.pa then return end
	local a = agare[kanal]
	if not a then return end
	if handelse == "CLAIM" then
		a.obj, a.tagen = obj, nu()
		skrivLogg(("%-5s CLAIM %s"):format(kanal, nr(obj)))
	else
		local lage = if obj then obj.UserInputState.Name else "?"
		skrivLogg(("%-5s END   %s (%s)"):format(kanal, nr(obj), lage))
		a.obj, a.tagen = nil, nil
	end
end

--[[ Spakens FAKTISKA utslag, som `TouchControls` räknat fram det och
	 skickat till `Input` — inte en gissning ur rörelsen efteråt. ]]
function TouchDiag.axlar(x: number, y: number)
	if not TouchDiag.pa then return end
	axelX, axelY = x, y
end

function TouchDiag.start(k: { movement: any?, modell: Instance? })
	if not TouchDiag.pa then return end
	--[[ Bara på pekytan. Mätningen gäller fingrar, och skrivbordet ska
	     inte få en ruta över bilden av att filen råkar ligga kvar. ]]
	if not UserInputService.TouchEnabled then return end
	ctx = k
	if gui then return end

	local g = Instance.new("ScreenGui")
	g.Name = "TouchDiag"
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = true
	--[[ Över allt annat: den ska kunna läsas medan lektionskortet ligger
	     uppe, annars går halva mätningen inte att göra. ]]
	g.DisplayOrder = 50
	g.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	gui = g

	local p = Instance.new("Frame")
	p.Name = "Panel"
	--[[ Uppe till vänster: spaken bor nere till vänster och reglagen nere
	     till höger, så det är den enda hörnan som inte används. ]]
	p.Position = UDim2.fromOffset(12, 70)
	p.Size = UDim2.fromOffset(330, 250)
	p.BackgroundColor3 = Color3.fromRGB(8, 10, 14)
	p.BackgroundTransparency = 0.25
	p.BorderSizePixel = 0
	p.Parent = g
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = p

	local function rad(namn: string, y: number, storlek: number?): TextLabel
		local l = Instance.new("TextLabel")
		l.Name = namn
		l.Size = UDim2.new(1, -16, 0, storlek or 15)
		l.Position = UDim2.fromOffset(8, y)
		l.BackgroundTransparency = 1
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.TextYAlignment = Enum.TextYAlignment.Top
		l.Font = Enum.Font.Code
		l.TextSize = 12
		l.TextColor3 = Color3.fromRGB(220, 226, 235)
		l.Text = ""
		l.Parent = p
		rutor[namn] = l
		return l
	end

	local rubrik = rad("Rubrik", 6)
	rubrik.Text = "TOUCHDIAG"
	rubrik.TextColor3 = Color3.fromRGB(214, 174, 60)
	rubrik.Font = Enum.Font.GothamBold

	rad("Spak", 26)
	rad("Blick", 42)
	rad("Fingrar", 58)
	rad("Gang", 74)
	rad("Foraldralost", 90)
	rad("Logg", 112, 130).TextColor3 = Color3.fromRGB(150, 160, 175)

	--[[ Går att vika undan: den täcker en bit av bilden, och ett par av
	     kontrollerna ska kunna provas med ren sikt. ]]
	local knapp = Instance.new("TextButton")
	knapp.Name = "Vik"
	knapp.Size = UDim2.fromOffset(44, 30)
	knapp.Position = UDim2.new(1, -52, 0, 4)
	knapp.BackgroundColor3 = Color3.fromRGB(40, 46, 56)
	knapp.TextColor3 = Color3.fromRGB(236, 232, 222)
	knapp.Font = Enum.Font.GothamBold
	knapp.TextSize = 12
	knapp.Text = "–"
	knapp.ZIndex = 3
	knapp.Parent = p
	local kc = Instance.new("UICorner"); kc.CornerRadius = UDim.new(0, 6); kc.Parent = knapp
	local vikt = false
	knapp.MouseButton1Click:Connect(function()
		vikt = not vikt
		knapp.Text = if vikt then "+" else "–"
		p.Size = if vikt then UDim2.fromOffset(330, 38) else UDim2.fromOffset(330, 250)
		for namn, l in pairs(rutor) do
			if namn ~= "Rubrik" then l.Visible = not vikt end
		end
	end)

	--[[ ── FINGERRÄKNINGEN ──────────────────────────────────────────────
	     Den enda vägen till frågan "ligger något kvar när alla lyft?".
	     Räknas på UIS och inte på ramarna: ett finger som aldrig tog
	     någonting ska också räknas, annars går noll aldrig att nå. ]]
	UserInputService.InputBegan:Connect(function(obj)
		if obj.UserInputType ~= Enum.UserInputType.Touch then return end
		if not levandeFingrar[obj] then
			levandeFingrar[obj] = true
			antalFingrar += 1
		end
	end)
	local function slut(obj: InputObject)
		if obj.UserInputType ~= Enum.UserInputType.Touch then return end
		if levandeFingrar[obj] then
			levandeFingrar[obj] = nil
			antalFingrar -= 1
		end
		if antalFingrar <= 0 then
			antalFingrar = 0
			--[[ HÄR STÄLLS FRÅGAN. Alla fingrar är lyfta; äger något
			     fortfarande en kanal är det ett kvarhängande ägarskap, och
			     det är kvar tills mätningen läses av — det får inte
			     försvinna av sig självt.

			     `task.defer` OCH INTE DIREKT: spakens och blickens egna
			     `InputEnded` är andra lyssnare på SAMMA händelse, och
			     ordningen dem emellan är inte given. Mätt: frågan ställdes
			     före spakens släpp och rapporterade
			     `!! FORALDRALOST: spak #1` på ett fullständigt normalt
			     fingerlyft — alltså falskt larm på precis den rad hela
			     multi-touch-grinden hänger på. Uppskjuten till efter att
			     bildrutans alla lyssnare kört är svaret det verkliga. ]]
			task.defer(function()
				if antalFingrar > 0 then return end
				local kvar = {}
				if agare.spak.obj then table.insert(kvar, "spak " .. nr(agare.spak.obj)) end
				if agare.blick.obj then table.insert(kvar, "blick " .. nr(agare.blick.obj)) end
				if #kvar > 0 then
					foraldralost = table.concat(kvar, " + ")
					skrivLogg("!! FORALDRALOST: " .. (foraldralost :: string))
				end
			end)
		end
	end
	UserInputService.InputEnded:Connect(slut)

	RunService.RenderStepped:Connect(function()
		if not gui or vikt then return end
		local function alder(a): string
			return if a.tagen then ("%.1fs"):format(nu() - a.tagen) else "–"
		end
		local mv = ctx.movement
		rutor.Spak.Text = ("spak   %-4s tagen %-6s  axlar %+.2f/%+.2f"):format(
			nr(agare.spak.obj), alder(agare.spak), axelX, axelY)
		rutor.Blick.Text = ("blick  %-4s tagen %-6s  %s"):format(
			nr(agare.blick.obj), alder(agare.blick),
			if agare.blick.obj then "AKTIV" else "vilande")
		rutor.Fingrar.Text = ("fingrar nere: %d"):format(antalFingrar)
		local gang = if ctx.modell then tostring(ctx.modell:GetAttribute("Gait")) else "–"
		local bedd = if mv and mv.loco then tostring(mv.loco.beddGangart or mv.loco.targetGait) else "–"
		local las = if mv then (if mv.haltLas then "JA" else "nej") else "–"
		rutor.Gang.Text = ("gang %-7s begard %-7s haltlas %s"):format(gang, bedd, las)
		rutor.Foraldralost.Text = if foraldralost
			then "FORALDRALOST: " .. (foraldralost :: string)
			else "foraldralost: nej"
		rutor.Foraldralost.TextColor3 = if foraldralost
			then Color3.fromRGB(255, 120, 120)
			else Color3.fromRGB(140, 200, 150)
		rutor.Logg.Text = table.concat(logg, "\n")
	end)
end

function TouchDiag.stopp()
	if gui then
		gui:Destroy()
		gui = nil
	end
	rutor = {}
	logg = {}
	agare.spak = {}
	agare.blick = {}
	foraldralost = nil
end

return TouchDiag
