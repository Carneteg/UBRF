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
local UserInputService = game:GetService("UserInputService")

local Ugneta = require(game:GetService("ReplicatedStorage").HorseCore.Ugneta)
local RidKanon = require(game:GetService("ReplicatedStorage").HorseCore.RidKanon)

--[[ #162: lärarkortets egen text ur språkkanonen. Undervisningstexten
     kommer ur RidKanon.UGNETA och är svensk kanon — se översättningsskulden
     i src/spel/sprak.js. ]]
local Sprak = require(game:GetService("ReplicatedStorage").HorseCore.Sprak)

local UgnetaController = {}

local player = Players.LocalPlayer

local gui: ScreenGui? = nil
local chip: TextLabel? = nil
local kort: Frame? = nil
local kortRubrik: TextLabel? = nil
local kortPunkter: { TextLabel } = {}
local kortKnapp: TextButton? = nil
--[[ G02-D: kortet efter ett försök bär numera TRE vägar vidare, inte en.
     Huvudknappen är kvar precis som den var (Prova igen / Nästa övning);
     de två nya är sidoval och styr därför sina egna knappar:

       "Se ritten"   öppnar ridanalysen. Den avslutar INTE väntan — kortet
                     står kvar bakom panelen, och när panelen stängs är
                     valet fortfarande hennes.
       "Gå vidare"   nöjer sig med försöket. Momentet betygsätts ändå;
                     det är omridningen hon hoppar över, inte bedömningen.

     Kortet efter det SISTA försöket får ingen "Gå vidare" — huvudknappen
     ÄR att gå vidare då, och två knappar för samma sak är ingen valfrihet.
     Ett kort utan inspelning får ingen "Se ritten": ett val som inte kan
     leda någonstans är sämre än inget val. ]]
local replayKnapp: TextButton? = nil
local vidareKnapp: TextButton? = nil
local replayFn: (() -> ())? = nil
local vidareFn: (() -> ())? = nil

--[[ ÅTERFÖRSÖKET ÄR EN HANDLING, INTE EN SKYLT (senior review av
	c53a2c7). Knappen var en TextLabel utan input-handler, och lifecyclen
	gick vidare på en sexsekunderstimer: kortet SÅG ut som ett val men var
	en nedräkning. En skylt som ser ut som en knapp är inte en knapp.

	Nu väntar lektionen på spelaren. `vantarPa` ÄR den väntan, och så
	länge den är sann mäts ingenting — se LektionController.steg. Det är
	också därför tre ingångar (knapp, tangent, gamepad) går genom EN
	`fortsatt`: en väntan som kan avslutas på tre ställen skulle kunna
	avslutas två gånger. ]]
local vantarPa = false
local fortsattFn: (() -> ())? = nil

local FARG_GULD = Color3.fromRGB(232, 181, 74)
local FARG_BRA = Color3.fromRGB(140, 196, 120)
local FARG_MORK = Color3.fromRGB(12, 14, 18)
local FARG_TEXT = Color3.fromRGB(246, 242, 232)

--[[ Live-orden: korta cues, en för fel och en för rätt. Registret är
	avsiktligt litet — fler ord blir en textström, och det är precis det
	variant 1+3 säger nej till.

	Det stod förut som en handskriven kopia här. Samma ord som webbens,
	men en KOPIA, och en kopia kan glida. Nu läses både orden och hur
	länge chipet står kvar ur kanonen. ]]
local LIVE = RidKanon.UGNETA.LIVE
local LIVE_CD = RidKanon.UGNETA.LIVE_CD

--[[ Dimensionsorden bär nycklar; texten hämtas när kortet ritas. ]]
local DIM_NYCKEL = {
	linje = "ugneta.dim.linje", rytm = "ugneta.dim.rytm", balans = "ugneta.dim.balans",
	timing = "ugneta.dim.timing", mjukhet = "ugneta.dim.mjukhet",
	respons = "ugneta.dim.respons", tempo = "ugneta.dim.tempo",
}
local DIM_ORD = setmetatable({}, {
	__index = function(_, dim)
		local nyckel = DIM_NYCKEL[dim]
		return if nyckel then Sprak.t(nyckel) else nil
	end,
})

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
	k.Size = UDim2.new(0.92, 0, 0, 170)
	k.SizeConstraint = Enum.SizeConstraint.RelativeXX
	k.BackgroundColor3 = FARG_MORK
	k.BackgroundTransparency = 0.08
	k.Visible = false
	k.ZIndex = 5
	local kmax = Instance.new("UISizeConstraint")
	kmax.MaxSize = Vector2.new(640, 260)
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
	namn.Text = Sprak.t("ugneta.rubrik")
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

	local kn = Instance.new("TextButton")
	kn.Name = "Knapp"
	kn.AutoButtonColor = true
	kn.LayoutOrder = 9
	kn.Size = UDim2.new(0, 108, 0, 22)
	kn.BackgroundColor3 = FARG_GULD
	kn.TextColor3 = Color3.fromRGB(23, 20, 10)
	kn.Font = Enum.Font.GothamBold
	kn.TextSize = 12
	kn.Text = Sprak.t("ugneta.prova_igen")
	kn.Visible = false
	kn.ZIndex = 6
	local kncorner = Instance.new("UICorner")
	kncorner.CornerRadius = UDim.new(1, 0)
	kncorner.Parent = kn
	kn.Parent = k
	kortKnapp = kn

	--[[ Sidoknapparna. Samma yta, samma träffstorlek, tydligt underordnad
	     färg — huvudvalet ska fortfarande vara det som syns först. ]]
	local function sidoKnapp(namn: string, txt: string, ordning: number,
		fn: () -> ()): TextButton
		local x = Instance.new("TextButton")
		x.Name = namn
		x.AutoButtonColor = true
		x.LayoutOrder = ordning
		x.Size = UDim2.new(0, 108, 0, 22)
		x.BackgroundColor3 = Color3.fromRGB(60, 72, 68)
		x.TextColor3 = FARG_TEXT
		x.Font = Enum.Font.GothamBold
		x.TextSize = 12
		x.Text = txt
		x.Visible = false
		x.ZIndex = 6
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(1, 0)
		c.Parent = x
		x.Parent = k
		x.Activated:Connect(fn)
		return x
	end
	replayKnapp = sidoKnapp("SeRitten", Sprak.t("ugneta.se_ritten"), 10, function()
		UgnetaController.replay()
	end)
	vidareKnapp = sidoKnapp("GaVidare", Sprak.t("ugneta.ga_vidare"), 11, function()
		UgnetaController.gaVidare()
	end)

	--[[ Mus och finger går in här. Tangent och gamepad kommer in via
	     init.client.luau, som äger inmatningen — HUD:en lyssnar inte
	     själv på UserInputService, av samma skäl som allt annat ligger i
	     den enda loopen. ]]
	kn.Activated:Connect(function()
		UgnetaController.fortsatt()
	end)
end

--[[ TANGENTLEDTEXT PÅ KNAPPEN (Tobias beslut 2026-09-07).

	Spelaren såg "Prova igen" men ingenting om att R gör samma sak —
	knappen var träffbar men tangenten var osynlig.

	Ledtexten visas bara där tangenten FINNS. En ren pekenhet ska inte
	få en bokstav hon inte kan trycka på, och det är inmatningen som
	avgör, inte plattformen: en iPad med tangentbord får ledtexten, en
	telefon får den inte. Tangenterna är desamma som init.client lyssnar
	på — R och gamepadens Y.

	Webben har ingen motsvarande ledtext, och ska inte ha det: den styrs
	med mus och finger. Paritetsregeln säger uttryckligen att inputadapter
	och UI får vara plattformsspecifika. ]]
local function medLedtext(txt: string): string
	if UserInputService.KeyboardEnabled then return txt .. "  (R)" end
	if UserInputService.GamepadEnabled then return txt .. "  (Y)" end
	return txt
end

--[[ ── Live-registret ─────────────────────────────────────────── ]]
function UgnetaController.liveText(fokusId: string, bra: boolean): string
	local r = LIVE[fokusId]
	if not r then return if bra then Sprak.t("ugneta.precis_sa") else "" end
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
	liveTid = LIVE_CD.visa
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
	--[[ SÄKERHET FÖRE UNDERVISNING. Även sidovalen kastas: ett "Se ritten"
	     som överlevde avsittningen hade kunnat öppna en analys av en ritt
	     på en häst som inte finns. ]]
	replayFn = nil
	vidareFn = nil
	local rk = replayKnapp
	if rk then rk.Visible = false end
	local vk = vidareKnapp
	if vk then vk.Visible = false end
	liveTid = 0
	liveSagt = ""
	--[[ SÄKERHET FÖRE UNDERVISNING. En väntande fortsättning får inte
	     överleva ett säkerhetsavbrott: annars kunde ett R-tryck efter
	     avsittningen starta ett försök på en häst som inte finns. ]]
	vantarPa = false
end

--[[ ── Kortet mellan försöken ─────────────────────────────────── ]]
local function visaKort(rubrik: string, punkter: { string }, knapp: boolean,
	knappText: string?, replay: boolean?, vidare: boolean?)
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
	if kn then
		kn.Visible = knapp
		if knapp and knappText then kn.Text = medLedtext(knappText) end
	end
	--[[ Sidovalen visas bara när de FINNS. Den som ropar avgör: en övning
	     utan inspelning har ingen ritt att se, och det sista försöket har
	     ingen omridning att hoppa över. ]]
	local rk = replayKnapp
	if rk then rk.Visible = replay == true end
	local vk = vidareKnapp
	if vk then vk.Visible = vidare == true end
	--[[ Kortet väntar exakt när det har en knapp. Ett kort utan knapp är
	     en upplysning, inte ett val. ]]
	vantarPa = knapp
	k.Visible = true
	--[[ Kortet hör till pausen mellan försöken. Går ridningen vidare
		ska det bort — det får aldrig ligga kvar över en aktiv ritt. ]]
	local c = chip
	if c then c.Visible = false end
end

--[[ Kortet, öppet för den som kör lektionen. Presentationen av en övning
	och återkopplingen efter ett försök är samma yta — skillnaden är vad
	som står i den, inte vilken ruta den ritas i. ]]
function UgnetaController.visa(rubrik: string, punkter: { string }, knapp: boolean,
	knappText: string?, replay: boolean?, vidare: boolean?)
	visaKort(rubrik, punkter, knapp, knappText, replay, vidare)
end

function UgnetaController.dolj()
	local k = kort
	if k then k.Visible = false end
	vantarPa = false
end

--[[ Efter ett försök. `fore` är nil på första försöket. Observationerna
	kommer ur HorseCore/Ugneta — samma rangordning som webben. ]]
function UgnetaController.efterForsok(ovningId: string, nu: { [string]: number },
	fore: { [string]: number }?, forsokNr: number, kanSeRitten: boolean?)
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
	if #punkter == 0 then table.insert(punkter, Sprak.t("ugneta.jamnare_forsok")) end
	local forsta = fore == nil
	--[[ Kortet har alltid en fortsättning nu. Förut fick bara försök 1 en
	     knapp och försök 2 låg kvar tills timern tog det — spelaren hade
	     inget sätt att säga "klar". ]]
	--[[ "Se ritten" bara när det FINNS en inspelning av försöket, och
	     "Gå vidare" bara efter första försöket — efter det sista är
	     huvudknappen redan vägen vidare. ]]
	visaKort(if forsta then Sprak.t("ugneta.prova_igen") else Sprak.t("ugneta.forsok", forsokNr),
		punkter, true,
		if forsta then Sprak.t("ugneta.prova_igen") else Sprak.t("ugneta.nasta_ovning"),
		kanSeRitten == true, forsta)
	return punkter
end

--[[ ── Fortsättningen: spelarens handling ──────────────────────────
	Kortet mellan försöken stänger inte sig självt. Den som kör lektionen
	registrerar vad som ska hända när spelaren väljer att gå vidare. ]]
function UgnetaController.vidFortsatt(fn: (() -> ())?)
	fortsattFn = fn
end

function UgnetaController.vidReplay(fn: (() -> ())?)
	replayFn = fn
end

function UgnetaController.vidVidare(fn: (() -> ())?)
	vidareFn = fn
end

--[[ SE RITTEN. Öppnar analysen och LÄMNAR KVAR väntan — kortet ligger
     bakom panelen och valet är fortfarande spelarens när hon stänger den.
     Returnerar false när det inte finns någon väntan eller ingen ritt att
     visa, så att tangenten faller igenom till sin vanliga betydelse. ]]
function UgnetaController.replay(): boolean
	if not vantarPa then return false end
	local fn = replayFn
	if not fn then return false end
	fn()
	return true
end

--[[ GÅ VIDARE. Avslutar väntan precis som `fortsatt`, men kör den andra
     vägen ut. De två delar vakt med flit: en väntan som kan avslutas på
     två ställen får inte kunna avslutas två gånger — det var så ett
     tidigare utkast räknade samma moment i `bedomda` en gång för mycket. ]]
function UgnetaController.gaVidare(): boolean
	if not vantarPa then return false end
	local fn = vidareFn
	if not fn then return false end
	vantarPa = false
	local k = kort
	if k then k.Visible = false end
	fn()
	return true
end

--[[ Står kortet och väntar på spelaren? ]]
function UgnetaController.vantar(): boolean
	return vantarPa
end

--[[ Spelaren gick vidare. Returnerar false när det inte fanns någon
	väntan att avsluta — så att en tangenttryckning utan kort aldrig kan
	starta ett försök i smyg, och så att init.client kan låta samma
	tangent falla igenom till sin vanliga betydelse. ]]
function UgnetaController.fortsatt(): boolean
	if not vantarPa then return false end
	vantarPa = false
	local k = kort
	if k then k.Visible = false end
	local fn = fortsattFn
	if fn then fn() end
	return true
end

function UgnetaController.start()
	bygg()
end

return UgnetaController
