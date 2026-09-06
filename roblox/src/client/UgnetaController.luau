--!strict
--[[ UGNETAS LÄRAR-UX PÅ ROBLOX (G02-C, UX-variant 1 + 3).

	Samma upplevelse som webben, inte en egen tolkning:

	  LIVE under ridning — några ord i ett litet chip ("Mjukare hand",
	  "Bra rytm", "Precis så"). Ingen panel, ingen textström. Ridningen
	  ska vinna över UI:t.

	  MELLAN FÖRSÖKEN — kortet. Efter försök 1: högst en sak som var bra,
	  en att förbättra och ett tydligt "Prova igen". Efter försök 2: en
	  konkret jämförelse mot försök 1.

	  SÄKERHET vinner alltid. Ett säkerhetsmeddelande släcker live-chipet
	  och tar över ytan, precis som på webben.

	INGEN PARALLELL SANNING. Vilka dimensioner en övning bedöms på, hur
	många observationer som får visas och hur de rangordnas kommer ur
	HorseCore/Ugneta, som i sin tur läser RidKanon.UGNETA — genererad ur
	webbens src/larare.js. Den här filen räknar inte om bedömningen; den
	visar den.

	Mätvärdena kommer ur HorseCore/Telemetri, samma källa som webbens
	G.telemetri. Kvalitetsmåtten byggs av `Ugneta.kvalitet`, inte av
	egna formler här.

	Layouten är byggd för 320 px bredd först — samma skäl som
	PreparationController: familjen spelar på iPad och telefon.
]]

local Players = game:GetService("Players")

local Core = require(game:GetService("ReplicatedStorage").HorseCore)
local Ugneta = require(game:GetService("ReplicatedStorage").HorseCore.Ugneta)

local UgnetaController = {}

local player = Players.LocalPlayer

local gui: ScreenGui? = nil
local chip: TextLabel? = nil
local kort: Frame? = nil
local kortRubrik: TextLabel? = nil
local kortPunkter: { TextLabel } = {}
local kortKnapp: TextLabel? = nil

local FARG_GULD = Color3.fromRGB(232, 181, 74)
local FARG_BRA = Color3.fromRGB(140, 196, 120)
local FARG_MORK = Color3.fromRGB(12, 14, 18)
local FARG_TEXT = Color3.fromRGB(246, 242, 232)

--[[ Live-orden. Samma register som webbens UGNETA_LIVE — korta cues, en
	för fel och en för rätt. Listan är avsiktligt liten: fler ord blir en
	textström, och det är precis det variant 1+3 säger nej till. ]]
local LIVE = {
	hand = { fel = "Mjukare hand", bra = "Mjuk hand" },
	framat = { fel = "Rid framåt", bra = "Bra rytm" },
	sits = { fel = "Sitt stilla", bra = "Bra sits" },
	lugn = { fel = "Andas ut", bra = "Fint lugn" },
	timing = { fel = "Vänta på svaret", bra = "Precis så" },
	vagen = { fel = "Titta dit du ska", bra = "Bra linje" },
}

local DIM_ORD = {
	linje = "linjen", rytm = "rytmen", balans = "balansen",
	timing = "timingen", mjukhet = "mjukheten", respons = "hästens svar",
	tempo = "tempot",
}

local liveTid = 0
local liveSagt = ""

local function bygg()
	if gui then return end
	local g = Instance.new("ScreenGui")
	g.Name = "UBRFUgneta"
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = true
	g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	g.Parent = player:WaitForChild("PlayerGui")
	--[[ Sätts HÄR, inte i slutet: vakten `if gui then return end` ovan
	     läser den, och utan tilldelningen byggde varje anrop en ny HUD
	     ovanpå den förra. Specen fångade två "Live" i samma ScreenGui. ]]
	gui = g

	--[[ LIVE-CHIPET. Uppe i kanten, aldrig över ridvägen, och utan
		porträtt eller rubrik — det är skillnaden mot kortet. ]]
	local c = Instance.new("TextLabel")
	c.Name = "Live"
	c.AnchorPoint = Vector2.new(0.5, 0)
	c.Position = UDim2.new(0.5, 0, 0, 10)
	c.Size = UDim2.new(0, 0, 0, 30)
	c.AutomaticSize = Enum.AutomaticSize.X
	c.BackgroundColor3 = FARG_MORK
	c.BackgroundTransparency = 0.18
	c.TextColor3 = FARG_TEXT
	c.Font = Enum.Font.GothamBold
	c.TextSize = 15
	c.Text = ""
	c.Visible = false
	c.ZIndex = 6
	local cpad = Instance.new("UIPadding")
	cpad.PaddingLeft = UDim.new(0, 14)
	cpad.PaddingRight = UDim.new(0, 14)
	cpad.Parent = c
	local ccorner = Instance.new("UICorner")
	ccorner.CornerRadius = UDim.new(1, 0)
	ccorner.Parent = c
	local cstroke = Instance.new("UIStroke")
	cstroke.Color = FARG_GULD
	cstroke.Transparency = 0.5
	cstroke.Parent = c
	c.Parent = g
	chip = c

	--[[ KORTET. Visas bara mellan försöken. ]]
	local k = Instance.new("Frame")
	k.Name = "Kort"
	k.AnchorPoint = Vector2.new(0.5, 1)
	k.Position = UDim2.new(0.5, 0, 1, -14)
	k.Size = UDim2.new(0.92, 0, 0, 108)
	k.SizeConstraint = Enum.SizeConstraint.RelativeXX
	k.BackgroundColor3 = FARG_MORK
	k.BackgroundTransparency = 0.08
	k.Visible = false
	k.ZIndex = 5
	local kmax = Instance.new("UISizeConstraint")
	kmax.MaxSize = Vector2.new(640, 200)
	kmax.Parent = k
	local kcorner = Instance.new("UICorner")
	kcorner.CornerRadius = UDim.new(0, 10)
	kcorner.Parent = k
	local kstroke = Instance.new("UIStroke")
	kstroke.Color = FARG_GULD
	kstroke.Transparency = 0.52
	kstroke.Parent = k
	local kpad = Instance.new("UIPadding")
	kpad.PaddingTop = UDim.new(0, 10)
	kpad.PaddingBottom = UDim.new(0, 10)
	kpad.PaddingLeft = UDim.new(0, 13)
	kpad.PaddingRight = UDim.new(0, 13)
	kpad.Parent = k
	local klista = Instance.new("UIListLayout")
	klista.Padding = UDim.new(0, 3)
	klista.SortOrder = Enum.SortOrder.LayoutOrder
	klista.Parent = k
	k.Parent = g
	kort = k

	local namn = Instance.new("TextLabel")
	namn.Name = "Avsandare"
	namn.LayoutOrder = 1
	namn.Size = UDim2.new(1, 0, 0, 13)
	namn.BackgroundTransparency = 1
	namn.TextXAlignment = Enum.TextXAlignment.Left
	namn.Font = Enum.Font.RobotoMono
	namn.TextSize = 11
	namn.TextColor3 = Color3.fromRGB(231, 200, 107)
	namn.Text = "UGNETA · RIDINSTRUKTÖR"
	namn.ZIndex = 6
	namn.Parent = k

	local r = Instance.new("TextLabel")
	r.Name = "Rubrik"
	r.LayoutOrder = 2
	r.Size = UDim2.new(1, 0, 0, 20)
	r.BackgroundTransparency = 1
	r.TextXAlignment = Enum.TextXAlignment.Left
	r.Font = Enum.Font.GothamBold
	r.TextSize = 16
	r.TextColor3 = FARG_TEXT
	r.Text = ""
	r.ZIndex = 6
	r.Parent = k
	kortRubrik = r

	for i = 1, Ugneta.MAX_OBSERVATIONER do
		local p = Instance.new("TextLabel")
		p.Name = "Punkt" .. i
		p.LayoutOrder = 2 + i
		p.Size = UDim2.new(1, 0, 0, 18)
		p.BackgroundTransparency = 1
		p.TextXAlignment = Enum.TextXAlignment.Left
		p.Font = Enum.Font.Gotham
		p.TextSize = 14
		p.TextColor3 = FARG_TEXT
		p.Text = ""
		p.Visible = false
		p.ZIndex = 6
		p.Parent = k
		table.insert(kortPunkter, p)
	end

	local kn = Instance.new("TextLabel")
	kn.Name = "Knapp"
	kn.LayoutOrder = 9
	kn.Size = UDim2.new(0, 108, 0, 22)
	kn.BackgroundColor3 = FARG_GULD
	kn.TextColor3 = Color3.fromRGB(23, 20, 10)
	kn.Font = Enum.Font.GothamBold
	kn.TextSize = 12
	kn.Text = "Prova igen"
	kn.Visible = false
	kn.ZIndex = 6
	local kncorner = Instance.new("UICorner")
	kncorner.CornerRadius = UDim.new(1, 0)
	kncorner.Parent = kn
	kn.Parent = k
	kortKnapp = kn
end

--[[ ── Live-registret ─────────────────────────────────────────── ]]
function UgnetaController.liveText(fokusId: string, bra: boolean): string
	local r = LIVE[fokusId]
	if not r then return if bra then "Precis så" else "" end
	return if bra then r.bra else r.fel
end

function UgnetaController.live(txt: string, bra: boolean)
	if txt == "" then return end
	bygg()
	local c = chip
	if not c then return end
	c.Text = txt
	c.Visible = true
	local stroke = c:FindFirstChildOfClass("UIStroke")
	if stroke then stroke.Color = if bra then FARG_BRA else FARG_GULD end
	liveTid = 2.6
	liveSagt = txt
end

function UgnetaController.steg(dt: number)
	if liveTid > 0 then
		liveTid -= dt
		if liveTid <= 0 then
			local c = chip
			if c then c.Visible = false end
			liveSagt = ""
		end
	end
end

--[[ SÄKERHET VINNER. Släcker live-chipet och stänger kortet, så att
	"Bra rytm" aldrig står kvar bredvid en varning. ]]
function UgnetaController.sakerhetTarOver()
	local c = chip
	if c then c.Visible = false end
	local k = kort
	if k then k.Visible = false end
	liveTid = 0
	liveSagt = ""
end

--[[ ── Kortet mellan försöken ─────────────────────────────────── ]]
local function visaKort(rubrik: string, punkter: { string }, knapp: boolean)
	bygg()
	local k, r = kort, kortRubrik
	if not k or not r then return end
	r.Text = rubrik
	for i, p in kortPunkter do
		local txt = punkter[i]
		p.Text = txt or ""
		p.Visible = txt ~= nil
	end
	local kn = kortKnapp
	if kn then kn.Visible = knapp end
	k.Visible = true
	--[[ Kortet hör till pausen mellan försöken. Går ridningen vidare
		ska det bort — det får aldrig ligga kvar över en aktiv ritt. ]]
	local c = chip
	if c then c.Visible = false end
end

function UgnetaController.dolj()
	local k = kort
	if k then k.Visible = false end
end

--[[ Efter ett försök. `fore` är nil på första försöket. Observationerna
	kommer ur HorseCore/Ugneta — samma rangordning som webben. ]]
function UgnetaController.efterForsok(ovningId: string, nu: { [string]: number },
	fore: { [string]: number }?, forsokNr: number)
	local obs = Ugneta.observationer(ovningId, nu, fore)
	local punkter = {}
	for _, o in obs do
		local ord = DIM_ORD[o.dim] or o.dim
		if o.sort == "battre" then
			table.insert(punkter, `Bättre {ord} den här gången.`)
		elseif o.sort == "kvar" then
			table.insert(punkter, `Fortsätt med {ord}.`)
		elseif o.sort == "bra" then
			table.insert(punkter, `Bra {ord}.`)
		else
			table.insert(punkter, `Jobba på {ord}.`)
		end
	end
	if #punkter == 0 then table.insert(punkter, "Jämnare försök. Behåll samma känsla.") end
	local forsta = fore == nil
	visaKort(if forsta then "Prova igen" else `Försök {forsokNr}`, punkter, forsta)
	return punkter
end

function UgnetaController.start()
	bygg()
end

return UgnetaController
