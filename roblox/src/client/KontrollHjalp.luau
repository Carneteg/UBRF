--!strict
--[[
	KONTROLLERNA, KORT — vad gör jag för att sitta upp, byta gångart och hoppa?

	Tobias frågade, och frågan var befogad: reglagen fanns bara i koden.
	Den här modulen svarar med de reglage som FAKTISKT är bundna, läst ur
	src/client/Input.luau, src/client/TouchControls.luau och
	init.client.luau. Ingenting här är påhittat, och ingenting här ÄNDRAR
	en bindning — ridfysik, hjälpsemantik och hoppmodell rörs inte.

	REGLAGEN FÖLJER INMATNINGEN, inte plattformen. Samma regel som
	UgnetaController.medLedtext: en ren pekenhet ska aldrig få en bokstav
	hon inte kan trycka på, och en iPad med tangentbord ska få bokstaven.
	Ordningen är tangentbord → gamepad → touch, för att det är den
	inmatning spelaren faktiskt har framför sig.

	VAD SOM INTE STÅR HÄR: webbens reglage. De skiljer sig verkligt —
	webben har ingen gångartsknapp (gångarten följer av skänkel och tygel)
	och inget hoppreglage (avsprånget kommer ur anridningen). Att skriva
	Roblox-tangenter i webbens hjälp, eller tvärtom, vore att påstå en
	paritet som inte finns. Varje yta visar sina egna.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local KontrollHjalp = {}

local player = Players.LocalPlayer

local gui: ScreenGui? = nil
local panel: Frame? = nil
local rader: { TextLabel } = {}
local visadEnGang = false

local FARG_MORK = Color3.fromRGB(12, 14, 18)
local FARG_TEXT = Color3.fromRGB(246, 242, 232)
local FARG_GULD = Color3.fromRGB(232, 181, 74)

--[[ RADERNA. `tgb`/`pad`/`pek` är de reglage som är bundna i produktionen:

     tangentbord  Input.luau: W/S framåt-bakåt, A/D styr, LeftShift gångart
                  upp, LeftControl gångart ner, Q tygel, F parad, Z/C sits,
                  Space hopp. init.client.luau: E sitt upp/av.
     gamepad      Input.luau: Thumbstick1 styr och framåt, ButtonR1 gångart
                  upp, ButtonL1 gångart ner, ButtonR2 tygel, ButtonB parad,
                  ButtonL2 sits, ButtonA hopp.
     touch        TouchControls.luau bygger Spak samt knapparna SITT AV,
                  ▲ FRAMÅT, ▼ LUGNARE, TYGEL, HALVHALT, DJUP SITS, HOPP.
                  Texterna nedan är knapparnas EGNA etiketter.

     Ändras en bindning ska den här tabellen ändras med den. Provet läser
     Input.luau:s egna KeyCodes och faller när en rad påstår en tangent som
     inte längre är bunden. ]]
local RADER = {
	{ vad = "Sitt upp / sitt av", tgb = "E",        pad = "E",        pek = "SITT AV" },
	{ vad = "Framåt / bakåt",     tgb = "W / S",    pad = "Vänster spak", pek = "Spaken" },
	{ vad = "Styr",               tgb = "A / D",    pad = "Vänster spak", pek = "Spaken" },
	{ vad = "Högre gångart",      tgb = "Shift",    pad = "R1",       pek = "▲ FRAMÅT" },
	{ vad = "Lägre gångart",      tgb = "Ctrl",     pad = "L1",       pek = "▼ LUGNARE" },
	{ vad = "Tygel (kontakt)",    tgb = "Q",        pad = "R2",       pek = "TYGEL" },
	{ vad = "Halvhalt",           tgb = "F",        pad = "B",        pek = "HALVHALT" },
	{ vad = "Djupare sits",       tgb = "Z / C",    pad = "L2",       pek = "DJUP SITS" },
	{ vad = "Hoppa",              tgb = "Space",    pad = "A",        pek = "HOPP" },
}

--[[ Vilken sorts inmatning ska hjälpen tala om? Publik för att provet ska
     kunna läsa samma beslut som panelen. ]]
function KontrollHjalp.inmatning(): string
	if UserInputService.KeyboardEnabled then return "tangentbord" end
	if UserInputService.GamepadEnabled then return "gamepad" end
	if UserInputService.TouchEnabled then return "touch" end
	--[[ Ingen känd inmatning: beskriv handlingarna utan reglage hellre än
	     att gissa en tangent hon kanske inte har. ]]
	return "okand"
end

--[[ Raderna som text, för panelen och för provet. Ren avläsning. ]]
function KontrollHjalp.rader(): { { vad: string, reglage: string } }
	local sort = KontrollHjalp.inmatning()
	local ut = {}
	for _, r in RADER do
		local reglage =
			if sort == "tangentbord" then r.tgb
			elseif sort == "gamepad" then r.pad
			elseif sort == "touch" then r.pek
			else ""
		table.insert(ut, { vad = r.vad, reglage = reglage })
	end
	return ut
end

local function bygg()
	if gui then return end
	local g = Instance.new("ScreenGui")
	g.Name = "UBRFKontroller"
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = true
	g.DisplayOrder = 15
	g.Enabled = false
	g.Parent = player:WaitForChild("PlayerGui")
	gui = g

	local p = Instance.new("Frame")
	p.Name = "Panel"
	--[[ Smal och vid kanten: hjälpen ska kunna stå uppe medan man rider,
	     inte lägga sig över vägen framåt. ]]
	p.AnchorPoint = Vector2.new(0, 0.5)
	p.Position = UDim2.new(0, 12, 0.5, 0)
	p.Size = UDim2.new(0, 250, 0, 44 * (#RADER + 2))
	p.BackgroundColor3 = FARG_MORK
	p.BackgroundTransparency = 0.12
	p.Parent = g
	panel = p
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = p

	local rubrik = Instance.new("TextLabel")
	rubrik.Name = "Rubrik"
	rubrik.Size = UDim2.new(1, -20, 0, 26)
	rubrik.Position = UDim2.fromOffset(10, 8)
	rubrik.BackgroundTransparency = 1
	rubrik.Text = "Kontroller"
	rubrik.TextColor3 = FARG_GULD
	rubrik.TextXAlignment = Enum.TextXAlignment.Left
	rubrik.Font = Enum.Font.GothamBold
	rubrik.TextSize = 15
	rubrik.Parent = p

	for i = 1, #RADER do
		local l = Instance.new("TextLabel")
		l.Name = "Rad" .. i
		l.Size = UDim2.new(1, -20, 0, 20)
		l.Position = UDim2.fromOffset(10, 34 + (i - 1) * 21)
		l.BackgroundTransparency = 1
		l.TextColor3 = FARG_TEXT
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.Font = Enum.Font.Gotham
		l.TextSize = 12
		l.Text = ""
		l.Parent = p
		table.insert(rader, l)
	end

	--[[ En stängknapp, inte bara en tangent: på en ren pekenhet finns
	     ingen H att trycka på, och en panel som inte går att stänga är
	     värre än ingen panel. 44 px, samma regel som ridanalysen. ]]
	local kn = Instance.new("TextButton")
	kn.Name = "StangHjalp"
	kn.AutoButtonColor = true
	kn.Size = UDim2.new(1, -20, 0, 44)
	kn.Position = UDim2.new(0, 10, 1, -52)
	kn.BackgroundColor3 = FARG_GULD
	kn.TextColor3 = Color3.fromRGB(23, 20, 10)
	kn.Font = Enum.Font.GothamBold
	kn.TextSize = 12
	kn.Text = "Stäng"
	kn.ZIndex = 6
	kn.Parent = p
	local kc = Instance.new("UICorner"); kc.CornerRadius = UDim.new(1, 0); kc.Parent = kn
	kn.Activated:Connect(function() KontrollHjalp.dolj() end)
end

local function fyll()
	local lista = KontrollHjalp.rader()
	for i, l in ipairs(rader) do
		local r = lista[i]
		if r then
			l.Text = if r.reglage ~= "" then `{r.vad}  ·  {r.reglage}` else r.vad
			l.Visible = true
		else
			l.Text = ""
			l.Visible = false
		end
	end
	local kn = panel and panel:FindFirstChild("StangHjalp")
	if kn then
		--[[ Ledtexten bara där tangenten finns. ]]
		(kn :: TextButton).Text =
			if UserInputService.KeyboardEnabled then "Stäng  (H)" else "Stäng"
	end
end

function KontrollHjalp.visa()
	bygg()
	fyll()
	local g = gui
	if g then g.Enabled = true end
end

function KontrollHjalp.dolj()
	local g = gui
	if g then g.Enabled = false end
end

function KontrollHjalp.synlig(): boolean
	local g = gui
	return g ~= nil and g.Enabled == true
end

function KontrollHjalp.vaxla(): boolean
	if KontrollHjalp.synlig() then KontrollHjalp.dolj() else KontrollHjalp.visa() end
	return KontrollHjalp.synlig()
end

--[[ FÖRSTA UPPSITTNINGEN. Hjälpen visas en gång av sig själv — då är
     frågan "vad gör jag nu?" som mest aktuell — och sedan bara när
     spelaren ber om den. Att visa den vid varje uppsittning hade blivit
     en ruta att stänga bort, inte en hjälp. ]]
function KontrollHjalp.vidUppsittning()
	if visadEnGang then return end
	visadEnGang = true
	KontrollHjalp.visa()
end

return KontrollHjalp
