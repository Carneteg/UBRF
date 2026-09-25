--!strict
--[[ UGNETAS LÄRAR-UX PÅ ROBLOX (G02-C, UX-variant 1 + 3).

	  LIVE under ridning — några ord i ett litet chip ("Mjukare hand",
	  "Bra rytm", "Precis så"). Ingen panel, ingen textström. Ridningen
	  ska vinna över UI:t.

	  MELLAN FÖRSÖKEN — Ugnetas ord i CoachBanner, uppe i kanten, plus de
	  VAL spelaren har. Efter försök 1: högst en sak som var bra, en att
	  förbättra och ett tydligt "Prova igen". Efter försök 2: en konkret
	  jämförelse mot försök 1.

	  SÄKERHET vinner alltid. Ett säkerhetsmeddelande släcker live-chipet
	  och tar över ytan, precis som på webben.

	── KORTET ÄR RIVET, VALEN ÄR KVAR (#244, PO-beslut 2026-09-18) ────────

	Fram till nu bodde undervisningen i ett bottenankrat kort med
	avsändarnamn ("UGNETA · RIDINSTRUKTÖR"), rubrikrad och upp till två
	punktrader — en RPG-lik dialogruta mitt över underlaget där hästen rör
	sig. Den är borta. Texten ligger i `CoachBanner`, uppe under
	Roblox-menyn, och tonar ut av sig själv.

	Det som INTE försvann är valen. Kortet bar lektionens enda vägar
	vidare — "Fortsätt för att börja lektionen", "Prova igen" / "Nästa
	övning", "Se ritten" och "Gå vidare" — och att de är HANDLINGAR och
	inte en nedräkning är en uttrycklig rättelse ur senior review av
	c53a2c7. En banner som tonar ut kan inte bära ett val. Knapparna står
	därför kvar, men utan ruta omkring sig: en ramlös rad i underkanten.

	Skillnaden mot förut är alltså vad ytan SÄGER, inte vad spelaren KAN.
	Väntan, progressionen och G02-D:s replayval är oförändrade.

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
local TouchControls = require(script.Parent.TouchControls)
--[[ #244: undervisningens text bor här numera. Modulen ritar bara det den
     får — orden kommer fortfarande ur katalogen och kanonen. ]]
local CoachBanner = require(script.Parent.CoachBanner)

local UgnetaController = {}

local player = Players.LocalPlayer

local gui: ScreenGui? = nil
--[[ Den enhetliga panelen, när den är värd. Se `satVard`. ]]
local vard: (() -> ())? = nil
local chip: TextLabel? = nil
--[[ Knappraden. Ramlös och utan bakgrund: den är en rad val, inte en
     panel. Frame:en finns bara för att layouten ska ha något att ankra
     och för att #206:s reserv ska kunna räknas på EN bredd. ]]
local valrad: Frame? = nil
local kortKnapp: TextButton? = nil
--[[ G02-D: efter ett försök bär raden TRE vägar vidare, inte en.
     Huvudknappen är kvar precis som den var (Prova igen / Nästa övning);
     de två andra är sidoval och styr därför sina egna knappar:

       "Se ritten"   öppnar ridanalysen. Den avslutar INTE väntan — valet
                     står kvar bakom panelen, och när panelen stängs är
                     det fortfarande hennes.
       "Gå vidare"   nöjer sig med försöket. Momentet betygsätts ändå;
                     det är omridningen hon hoppar över, inte bedömningen.

     Efter det SISTA försöket ges ingen "Gå vidare": huvudknappen ÄR att
     gå vidare då, och två knappar för samma sak är ingen valfrihet.
     Ett försök utan inspelning får ingen "Se ritten": ett val som inte kan
     leda någonstans är sämre än inget val. ]]
local replayKnapp: TextButton? = nil
local vidareKnapp: TextButton? = nil
local replayFn: (() -> ())? = nil
local vidareFn: (() -> ())? = nil

--[[ ÅTERFÖRSÖKET ÄR EN HANDLING, INTE EN SKYLT (senior review av
	c53a2c7). Knappen var en TextLabel utan input-handler, och lifecyclen
	gick vidare på en sexsekunderstimer: valet SÅG ut som ett val men var
	en nedräkning. En skylt som ser ut som en knapp är inte en knapp.

	Nu väntar lektionen på spelaren. `vantarPa` ÄR den väntan, och så
	länge den är sann mäts ingenting — se LektionController.steg. Det är
	också därför tre ingångar (knapp, tangent, gamepad) går genom EN
	`fortsatt`: en väntan som kan avslutas på tre ställen skulle kunna
	avslutas två gånger.

	#244: väntan hänger på VALEN, inte på texten. Bannern tonar ut efter
	några sekunder; knappen står kvar tills spelaren tryckt. Att låta
	väntan följa texten hade gjort lektionen till en nedräkning igen. ]]
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

--[[ Dimensionsorden bär nycklar; texten hämtas när besked ges. ]]
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

--[[ ══ UGNETAS YTA UPPE TILL HÖGER (#264 GAIT_READABILITY_AND_UGNETA) ════

	Ordern ändrar #5826875383 på en punkt: undervisningen får bo i EN liten
	yta uppe till höger i stället för i panelen nere till vänster. Panelen
	behåller handlingarna — även lektionens Fortsätt/Prova igen — och
	uppgiftens nej. Ytan här bär Ugnetas namn och titel, språkflaggan och
	högst ETT meddelande: en instruktion eller en återkoppling.

	Ingen ny ScreenGui (#244 förbjuder en andra): ytan bor i `UBRFUgneta`.
	Bannern, chipet och valraden flyttas in i en dold behållare medan
	panelen är värd — deras eget tillstånd, och varje prov som läser det,
	är orört; det är bara ritningen som flyttat.

	SPRÅKET. Flaggan visar det språk som GÄLLER och byter vid tryck. Valet
	går till `Sprak.satVal` (klientens text) och till servern (spelarens
	attribut, så att serverns text till henne följer). Det som redan står
	ritas om på plats: beskedet byggs om ur sin byggare, chipet — en
	kortlivad kommentar — släcks, och värden ritar om panelen. ]]
local dolt: Frame? = nil
local larare: Frame? = nil
local lararTitel: TextLabel? = nil
local lararText: TextLabel? = nil
local lararTips: TextLabel? = nil
local flaggKnapp: TextButton? = nil
local flaggSv: Frame? = nil
local flaggEn: Frame? = nil
local flaggNamn: TextLabel? = nil
local sprakKoppling: (() -> ())? = nil
local ritKoppling: RBXScriptConnection? = nil
--[[ Senaste beskedets BYGGARE: den ger rubrik, punkter och knapptext på
     det språk som gäller när den körs. Nil när inget besked finns. ]]
local senasteBygg: (() -> (string, { string }, boolean, string?, boolean?, boolean?))? = nil
--[[ Ridraden utanför lektionen, som nyckel + argument (aldrig en fryst
     mening), och när den senast matades. ]]
local radNyckel: string? = nil
local radArgs: { any } = {}
local radTid = -math.huge
local RAD_FARSK = 0.6
local lektionSteg = -math.huge

local LARARE_BREDD = 280
local LARARE_TOPP = 8
--[[ Spelarlistan i Roblox högra hörn: ytan lägger sig till vänster om den
     när den är på, i stället för att täcka den. ]]
local SPELARLISTA_B = 190

--[[ ══ UTLÄGGNINGEN MÅSTE KÖRAS OM NÄR YTAN ÄNDRAS (#206) ═══════════

	Regeln nedan var rätt från början och rörs inte av #244 — den flyttade
	bara med från kortet till knappraden, som ärvde dess plats i
	underkanten. Felet den rättar var att den kördes EN gång, när ytan
	visades, och aldrig igen. Det som låg uppe när spelaren vred på
	plattan behöll sin gamla geometri — och reglagen, som är ankrade i
	högerkanten, flyttade sig in under det.

	Mätt i Studio på `754f2cc`, emulerad iPad, kortet uppe hela tiden:

	    iPad Pro 13in 1376x1032   kort x 367..1007   inget överlapp
	    -> iPad 9     1080x 810   kort x 367..1007   SITT AV 100 % täckt

	    träffprov på SITT AV: 0 av 66 punkter når knappen

	Alltså: den som vrider plattan medan ett val ligger uppe kan inte
	längre sitta av. TYGEL och PARAD hade 0 px kvar att träffa, och
	HOPP och DJUP SITS 49 px mot golvet 44.

	Utläggningen är bruten ut hit och körs både när raden visas och när
	ytan ändrar storlek. Ingen ny regel, ingen ny layout, inget nytt system
	— samma tal, körda vid rätt tillfällen. ]]
--[[ Smalast rad som fortfarande rymmer en knapp med text. Samma tal som
	golvet i `bredd` nedan har haft sedan början. ]]
local VAL_MIN = 160

--[[ Under den här bredden är raden inte längre värd att behålla
	vänsterreserven för — se noten i `laggUtVal`. ]]
local VAL_LASBAR = 480

--[[ Radens höjd. 44 px är tumgreppets golv och gäller knapparna själva;
	raden är lika hög och inget mer, för att inte lägga en osynlig yta
	över underlaget. ]]
local VAL_HOJD = 44

local function laggUtVal()
	local v = valrad
	if not v then return end
	local foralder = v.Parent :: GuiObject
	local W = foralder and foralder.AbsoluteSize.X or 0
	if W <= 0 then return end
	--[[ ── RESERVEN HAR TVÅ KANTER, INTE EN (#206) ────────────────────

		Regeln har alltid vikt undan för gångarterna och hjälparna i
		högerkanten. Den vek ALDRIG undan för spaken i vänsterkanten —
		och eftersom den skjuter ytan åt vänster när mitten inte räcker
		till, sköt den den rakt ut över spaken.

		Mätt i Studio på `cdfe061`, emulerad iPad i landskap med kortet
		uppe och ryttaren uppsutten — träffprov över spakens bas:

		    1024x768  överlapp 80 px  spaken når 20 av 70 punkter
		    1080x810  överlapp 51 px  spaken når 34 av 70 punkter
		    1180x820  överlapp  0 px  spaken når 54 av 70 punkter

		Brännpunkten är ren geometri: ytan får plats mitt på skärmen
		så länge `W/2 + bredd/2 <= fritt`. Under ungefär 1100 px bredd
		håller det inte längre, och då centreras den i `fritt` — vars
		vänsterkant var skärmens egen, alltså spakens.

		Nu är spannet [vänster, höger] i stället för [0, höger].

		FALLBACK, för att telefonen inte ska bli sämre (krav 7): blir
		spannet för smalt för en läsbar rad räknas layouten som förut,
		utan vänsterreserv. En liten skärm ska hellre ha en knapprad som
		delar plats med spaken än knappar som inte går att träffa — den
		avvägningen är 568x320-konflikten, och den rörs inte här. ]]
	local hoger = W - TouchControls.reglageBredd()
	local vanster = TouchControls.spakBredd()
	--[[ VÄNSTERRESERVEN KOSTAR BREDD, och på en liten skärm kostar den
		för mycket. `VAL_LASBAR` är gränsen där raden fortfarande rymmer
		sina knappar: håller reserven kvar den, tillämpas den; gör den
		inte det räknas layouten EXAKT som förut.

		Talet är valt för att dra gränsen mellan surfplatta och telefon,
		och det är avsiktligt att den hamnar där. Räknat på kanonens egna
		provskärmar:

		    1024x768  iPad      rad 640 -> 594  reserven tillämpas
		    1080x810  iPad      rad 640 -> 640  reserven tillämpas
		    1180x820  iPad      rad 640 -> 640  oförändrat, låg redan rätt
		     844x390  iPhone 13 rad skulle bli 475  reserven UTEBLIR
		     568x320  liten tel rad skulle bli 269  reserven UTEBLIR

		Telefonerna får alltså exakt den layout de hade. Att spaken ligger
		under raden där är samma 568x320-avvägning som redan är
		dokumenterad som en produktkonflikt, och den löses inte här. ]]
	local reserverad = math.min(640, 0.92 * W, math.max(VAL_MIN, (hoger - vanster) - 32))
	if reserverad < VAL_LASBAR then vanster = 0 end
	local fritt = hoger - vanster
	local bredd = math.min(640, 0.92 * W, math.max(VAL_MIN, fritt - 32))
	local centrum = if W / 2 - bredd / 2 >= vanster and W / 2 + bredd / 2 <= hoger
		then W / 2
		else vanster + fritt / 2
	v.Size = UDim2.new(0, math.floor(bredd), 0, VAL_HOJD)
	v.Position = UDim2.new(0, math.floor(centrum), 1, -14)
end

--[[ Provets fönster in: lägg ut raden igen utan att visa ett nytt besked. ]]
function UgnetaController._laggUtVal()
	laggUtVal()
end

--[[ ── FLAGGORNA, RITADE AV RAMAR ────────────────────────────────────

	Inga flagg-emoji: de blir bokstäver på Windows och i Roblox. Ingen
	bildresurs heller — en uppladdad bild vore ett konto att vara beroende
	av, samma skäl som `HastGang` ritar benen själv. Ramar i rätt färger och
	proportioner är en pålitlig grafik; förenklingen redovisas. ]]
local function ruta(namn: string, farg: Color3, x: number, y: number, b: number, h: number,
	mor: Instance, rot: number?): Frame
	local f = Instance.new("Frame")
	f.Name = namn
	f.BackgroundColor3 = farg
	f.BorderSizePixel = 0
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromOffset(x + b / 2, y + h / 2)
	f.Size = UDim2.fromOffset(b, h)
	if rot then f.Rotation = rot end
	f.Parent = mor
	return f
end

local FLAGG_B, FLAGG_H = 30, 18

local function svenskFlagga(mor: Instance): Frame
	--[[ Sveriges flagga, 16:10: blått 5 + gult 2 + blått 9 i längd,
	     blått 4 + gult 2 + blått 4 i höjd. ]]
	local f = ruta("FlaggaSv", Color3.fromRGB(0, 106, 167), 0, 0, FLAGG_B, FLAGG_H, mor)
	f.ClipsDescendants = true
	local gul = Color3.fromRGB(254, 204, 2)
	ruta("Lodratt", gul, math.floor(FLAGG_B * 5 / 16), 0, math.ceil(FLAGG_B * 2 / 16), FLAGG_H, f)
	ruta("Vagratt", gul, 0, math.floor(FLAGG_H * 4 / 10), FLAGG_B, math.ceil(FLAGG_H * 2 / 10), f)
	return f
end

local function brittiskFlagga(mor: Instance): Frame
	--[[ Union Jack, förenklad: blått fält, vita och röda diagonaler, vitt
	     och rött kors. Diagonalernas längd är rutans diagonal, så de slutar
	     i hörnen även utan klippning av roterade ramar. ]]
	local f = ruta("FlaggaEn", Color3.fromRGB(1, 33, 105), 0, 0, FLAGG_B, FLAGG_H, mor)
	f.ClipsDescendants = true
	local vit, rod = Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 16, 46)
	local diag = math.sqrt(FLAGG_B * FLAGG_B + FLAGG_H * FLAGG_H)
	local vinkel = math.deg(math.atan2(FLAGG_H, FLAGG_B))
	local cx, cy = FLAGG_B / 2, FLAGG_H / 2
	ruta("DiagVit1", vit, cx - diag / 2, cy - 1.8, diag, 3.6, f, vinkel)
	ruta("DiagVit2", vit, cx - diag / 2, cy - 1.8, diag, 3.6, f, -vinkel)
	ruta("DiagRod1", rod, cx - diag / 2, cy - 0.8, diag, 1.6, f, vinkel)
	ruta("DiagRod2", rod, cx - diag / 2, cy - 0.8, diag, 1.6, f, -vinkel)
	ruta("KorsVitV", vit, 0, cy - 3, FLAGG_B, 6, f)
	ruta("KorsVitL", vit, cx - 3, 0, 6, FLAGG_H, f)
	ruta("KorsRodV", rod, 0, cy - 1.8, FLAGG_B, 3.6, f)
	ruta("KorsRodL", rod, cx - 1.8, 0, 3.6, FLAGG_H, f)
	return f
end

local function vaxlaSprak()
	local ny = if Sprak.eget() == "sv" then "en" else "sv"
	Sprak.satVal(ny)
	--[[ Servern får veta, så att dess text till spelaren följer. Svaret
	     väntas inte in: klientens text har redan bytt. ]]
	task.spawn(function()
		pcall(function()
			local Net = require(game:GetService("ReplicatedStorage").HorseCore.Networking)
			Net.get("SprakVal"):InvokeServer(ny)
		end)
	end)
end

local function byggLarare(g: ScreenGui)
	local d = Instance.new("Frame")
	d.Name = "Dolt"
	d.BackgroundTransparency = 1
	d.Size = UDim2.fromScale(1, 1)
	d.Visible = false
	d.Parent = g
	dolt = d

	local l = Instance.new("Frame")
	l.Name = "Larare"
	l.AnchorPoint = Vector2.new(1, 0)
	l.Position = UDim2.new(1, -16, 0, LARARE_TOPP)
	l.Size = UDim2.fromOffset(LARARE_BREDD, 0)
	l.AutomaticSize = Enum.AutomaticSize.Y
	l.BackgroundColor3 = FARG_MORK
	l.BackgroundTransparency = 0.3
	l.BorderSizePixel = 0
	l.Visible = false
	l.ZIndex = 5
	local horn = Instance.new("UICorner")
	horn.CornerRadius = UDim.new(0, 8)
	horn.Parent = l
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 8)
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 6)
	pad.Parent = l
	local lista = Instance.new("UIListLayout")
	lista.FillDirection = Enum.FillDirection.Vertical
	lista.SortOrder = Enum.SortOrder.LayoutOrder
	lista.Padding = UDim.new(0, 2)
	lista.Parent = l

	local huvud = Instance.new("Frame")
	huvud.Name = "Huvud"
	huvud.BackgroundTransparency = 1
	huvud.Size = UDim2.new(1, 0, 0, 44)
	huvud.LayoutOrder = 1
	huvud.Parent = l

	local t = Instance.new("TextLabel")
	t.Name = "Titel"
	t.BackgroundTransparency = 1
	t.Size = UDim2.new(1, -118, 1, 0)
	t.Font = Enum.Font.GothamBold
	t.TextSize = 14
	t.TextColor3 = FARG_GULD
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.TextWrapped = true
	t.Text = Sprak.t("ugneta.titel")
	t.Parent = huvud
	lararTitel = t

	--[[ Flaggknappen: hela träffytan minst 44×44, fokuserbar (Selectable)
	     för tangentbord och handkontroll. Den visar det språk som GÄLLER. ]]
	local k = Instance.new("TextButton")
	k.Name = "SprakFlagga"
	k.AnchorPoint = Vector2.new(1, 0)
	k.Position = UDim2.new(1, 0, 0, 0)
	k.Size = UDim2.fromOffset(112, 44)
	k.BackgroundColor3 = Color3.fromRGB(38, 41, 47)
	k.BackgroundTransparency = 0.2
	k.AutoButtonColor = true
	k.Selectable = true
	k.Text = ""
	k.ZIndex = 6
	local kh = Instance.new("UICorner")
	kh.CornerRadius = UDim.new(0, 6)
	kh.Parent = k
	local ytaFlagga = Instance.new("Frame")
	ytaFlagga.Name = "Flagga"
	ytaFlagga.BackgroundTransparency = 1
	ytaFlagga.Position = UDim2.fromOffset(8, 13)
	ytaFlagga.Size = UDim2.fromOffset(FLAGG_B, FLAGG_H)
	ytaFlagga.ZIndex = 7
	ytaFlagga.Parent = k
	flaggSv = svenskFlagga(ytaFlagga)
	flaggEn = brittiskFlagga(ytaFlagga)
	local n = Instance.new("TextLabel")
	n.Name = "Namn"
	n.BackgroundTransparency = 1
	n.Position = UDim2.fromOffset(8 + FLAGG_B + 6, 0)
	n.Size = UDim2.new(1, -(8 + FLAGG_B + 8), 1, 0)
	n.Font = Enum.Font.GothamMedium
	n.TextSize = 14
	n.TextColor3 = FARG_TEXT
	n.TextXAlignment = Enum.TextXAlignment.Left
	n.ZIndex = 7
	n.Parent = k
	flaggNamn = n
	k.Parent = huvud
	k.Activated:Connect(vaxlaSprak)
	flaggKnapp = k

	--[[ Tips i stället för en verktygstips-API som Roblox inte har: när
	     pekaren står på flaggan säger raden vad ett tryck gör. ]]
	local tips = Instance.new("TextLabel")
	tips.Name = "Tips"
	tips.BackgroundTransparency = 1
	tips.Size = UDim2.new(1, 0, 0, 0)
	tips.AutomaticSize = Enum.AutomaticSize.Y
	tips.Font = Enum.Font.Gotham
	tips.TextSize = 13
	tips.TextColor3 = Color3.fromRGB(200, 200, 205)
	tips.TextXAlignment = Enum.TextXAlignment.Left
	tips.TextWrapped = true
	tips.Visible = false
	tips.LayoutOrder = 2
	tips.Parent = l
	lararTips = tips
	k.MouseEnter:Connect(function() tips.Text = Sprak.t("sprak.byt"); tips.Visible = true end)
	k.MouseLeave:Connect(function() tips.Visible = false end)
	k.SelectionGained:Connect(function() tips.Text = Sprak.t("sprak.byt"); tips.Visible = true end)
	k.SelectionLost:Connect(function() tips.Visible = false end)

	local m = Instance.new("TextLabel")
	m.Name = "Meddelande"
	m.BackgroundTransparency = 1
	m.Size = UDim2.new(1, -4, 0, 0)
	m.AutomaticSize = Enum.AutomaticSize.Y
	m.Font = Enum.Font.Gotham
	m.TextSize = 16
	m.TextColor3 = FARG_TEXT
	m.TextXAlignment = Enum.TextXAlignment.Left
	m.TextWrapped = true
	m.Text = ""
	m.Visible = false
	m.LayoutOrder = 3
	m.Parent = l
	lararText = m

	l.Parent = g
	larare = l
end

--[[ Framåtdeklarerade: bygget kopplar dem, de definieras nedanför. ]]
local sprakBytt: () -> ()
local vardLage: () -> ()

local function bygg()
	if gui then return end
	local g = Instance.new("ScreenGui")
	g.Name = "UBRFUgneta"
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = true
	--[[ Samma skäl som skötselpanelen: vid lika `DisplayOrder` vinner
	     Roblox `TouchGui`, och lektionens knapp hamnade under den
	     dynamiska spakens osynliga träffyta. Mätt på iPad Air:
	         [DynamicThumbstickUIModifier > DynamicThumbstickFrame >
	          TouchControlFrame > Knapp]
	     alltså fjärde i stacken — valet gick inte att kvittera, och det
	     är enda vägen in i lektionen. Med 10 ligger `Knapp` överst. ]]
	g.DisplayOrder = 10
	g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	g.Parent = player:WaitForChild("PlayerGui")
	--[[ Sätts HÄR, inte i slutet: vakten `if gui then return end` ovan
	     läser den, och utan tilldelningen byggde varje anrop en ny HUD
	     ovanpå den förra. Specen fångade två "Live" i samma ScreenGui. ]]
	gui = g
	--[[ ── OCH OM YTAN ÄNDRAR STORLEK (#206) ─────────────────────────

		Vridning, delad skärm och fönsterändring. Knappraden ligger i
		absoluta offset och följer därför INTE med av sig självt, medan
		reglagen är ankrade i högerkanten och gör det. Utan den här raden
		hamnar de på varandra — se noten vid `laggUtVal`.

		Villkoret `v.Visible` är med för att en dold rad inte ska räknas
		om i onödan; den läggs ändå ut när den visas. ]]
	g:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		local v = valrad
		if v and v.Visible then laggUtVal() end
	end)

	--[[ BANNERN. Den bor i den här ytan och bygger ingen egen ScreenGui —
	     kontraktet i #244 förbjuder en andra. ]]
	CoachBanner.montera(g)

	--[[ LIVE-CHIPET. Uppe i kanten, aldrig över ridvägen, och utan
		porträtt eller rubrik — det är skillnaden mot ett besked.

		#244: chipet ligger kvar där det låg, ÖVER bannern. De två krockar
		inte i tid: chipet kommer bara medan hon rider, bannern bara när
		lektionen säger något mellan försöken, och `visaBesked` släcker
		chipet innan bannern skrivs. ]]
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

	--[[ VALEN. En ramlös rad, inte ett kort: ingen bakgrund, ingen kant,
	     inget avsändarnamn, ingen rubrik. Bara det spelaren kan göra. ]]
	local v = Instance.new("Frame")
	v.Name = "Val"
	v.AnchorPoint = Vector2.new(0.5, 1)
	v.Position = UDim2.new(0.5, 0, 1, -14)
	v.Size = UDim2.new(0, 320, 0, VAL_HOJD)
	v.BackgroundTransparency = 1
	v.BorderSizePixel = 0
	v.Visible = false
	v.ZIndex = 5
	local vlista = Instance.new("UIListLayout")
	vlista.FillDirection = Enum.FillDirection.Horizontal
	vlista.HorizontalAlignment = Enum.HorizontalAlignment.Center
	vlista.VerticalAlignment = Enum.VerticalAlignment.Center
	vlista.Padding = UDim.new(0, 8)
	vlista.SortOrder = Enum.SortOrder.LayoutOrder
	vlista.Parent = v
	v.Parent = g
	valrad = v

	local kn = Instance.new("TextButton")
	kn.Name = "Knapp"
	kn.AutoButtonColor = true
	kn.LayoutOrder = 1
	--[[ ══ KNAPPEN VAR SMALARE ÄN SIN EGEN TEXT ════════════════════════

	     108×22 var en fast storlek, men texten sätts per besked och är
	     olika lång. Mätt på iPad Air i landskap: `TextBounds.X` = 157 mot
	     knappens 108 för "Continue to start the lesson  (R)" — texten
	     klipptes mitt i ordet, och det här är den ENDA vägen vidare i
	     lektionen. 22 px höjd är dessutom under det som går att träffa
	     med en tumme; 44 är golvet man brukar räkna med.

	     `AutomaticSize.X` låter pillret växa med sin text i stället för
	     att texten ska krympas eller kapas, så översättningar av olika
	     längd får plats utan att någon måste räkna pixlar. Bredden blir
	     ett minimum i stället för ett tak. ]]
	kn.Size = UDim2.new(0, 108, 0, 40)
	kn.AutomaticSize = Enum.AutomaticSize.X
	local knPad = Instance.new("UIPadding")
	knPad.PaddingLeft = UDim.new(0, 16)
	knPad.PaddingRight = UDim.new(0, 16)
	knPad.Parent = kn
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
	kn.Parent = v
	kortKnapp = kn

	--[[ Sidoknapparna. Samma yta, samma träffstorlek, tydligt underordnad
	     färg — huvudvalet ska fortfarande vara det som syns först. ]]
	local function sidoKnapp(namn: string, txt: string, ordning: number,
		fn: () -> ()): TextButton
		local x = Instance.new("TextButton")
		x.Name = namn
		x.AutoButtonColor = true
		x.LayoutOrder = ordning
		--[[ Samma skäl som huvudknappen ovan: texten är olika lång per
		     besked och per språk, och 22 px är inte ett tumgrepp. ]]
		x.Size = UDim2.new(0, 108, 0, 40)
		x.AutomaticSize = Enum.AutomaticSize.X
		local xPad = Instance.new("UIPadding")
		xPad.PaddingLeft = UDim.new(0, 16)
		xPad.PaddingRight = UDim.new(0, 16)
		xPad.Parent = x
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
		x.Parent = v
		x.Activated:Connect(fn)
		return x
	end
	replayKnapp = sidoKnapp("SeRitten", Sprak.t("ugneta.se_ritten"), 2, function()
		UgnetaController.replay()
	end)
	vidareKnapp = sidoKnapp("GaVidare", Sprak.t("ugneta.ga_vidare"), 3, function()
		UgnetaController.gaVidare()
	end)

	--[[ Mus och finger går in här. Tangent och gamepad kommer in via
	     init.client.luau, som äger inmatningen — HUD:en lyssnar inte
	     själv på UserInputService, av samma skäl som allt annat ligger i
	     den enda loopen. ]]
	kn.Activated:Connect(function()
		UgnetaController.fortsatt()
	end)

	byggLarare(g)
	--[[ Ytor som redan visar text ritas om vid språkbyte. Kopplingen ägs
	     här och rivs i `Destroy`-vägen nedan. ]]
	if sprakKoppling then sprakKoppling() end
	sprakKoppling = Sprak.vidByte(function() sprakBytt() end)
	vardLage()
end

--[[ TANGENTLEDTEXT PÅ KNAPPEN (Tobias beslut 2026-09-07).

	Spelaren såg "Prova igen" men ingenting om att R gör samma sak —
	knappen var träffbar men tangenten var osynlig.

	Ledtexten visas bara där tangenten FINNS. En ren pekenhet ska inte
	få en bokstav hon inte kan trycka på, och det är inmatningen som
	avgör, inte plattformen: en iPad med tangentbord får ledtexten, en
	telefon får den inte. Tangenterna är desamma som init.client lyssnar
	på — R och gamepadens Y.

	#244: ledtexten hör till KNAPPEN och får aldrig följa med in i
	bannern. Kontraktets krav 3 är uttryckligt — `(R)`, `(H)` eller
	motsvarande får inte stå i bannerns text — och skälet är att bannern
	läses på iPad där tangenten inte finns. `visaBesked` skickar därför
	rubriken rå till `CoachBanner.Show` och kör `medLedtext` bara på
	knappens egen etikett.

	Webben har ingen motsvarande ledtext, och ska inte ha det: den styrs
	med mus och finger. Paritetsregeln säger uttryckligen att inputadapter
	och UI får vara plattformsspecifika. ]]
local function medLedtext(txt: string): string
	if UserInputService.KeyboardEnabled then return txt .. "  (R)" end
	if UserInputService.GamepadEnabled then return txt .. "  (Y)" end
	return txt
end

--[[ ── Live-registret ─────────────────────────────────────────── ]]
--[[ #264 GAIT_UGNETA_REVIEW_R1: live-signalernas NYCKLAR, utskrivna en och
     en (språkgrinden läser källan). Kanonens `LIVE` är den svenska
     identiteten; det spelaren läser slås upp här, på det språk som gäller
     när det VISAS. Förut gick kanonens svenska rakt till ytan, även på
     engelska. ]]
local LIVE_NYCKEL: { [string]: { fel: string, bra: string } } = {
	framat = { fel = "ugneta.live.framat.fel", bra = "ugneta.live.framat.bra" },
	hand = { fel = "ugneta.live.hand.fel", bra = "ugneta.live.hand.bra" },
	lugn = { fel = "ugneta.live.lugn.fel", bra = "ugneta.live.lugn.bra" },
	sits = { fel = "ugneta.live.sits.fel", bra = "ugneta.live.sits.bra" },
	timing = { fel = "ugneta.live.timing.fel", bra = "ugneta.live.timing.bra" },
	vagen = { fel = "ugneta.live.vagen.fel", bra = "ugneta.live.vagen.bra" },
}
UgnetaController.LIVE_NYCKEL = LIVE_NYCKEL

--[[ Nyckeln för en signal, eller nil för en signal kanonen inte har. ]]
function UgnetaController.liveNyckel(fokusId: string?, bra: boolean): string?
	local r = fokusId and LIVE_NYCKEL[fokusId]
	if not r then return nil end
	return if bra then r.bra else r.fel
end

function UgnetaController.liveText(fokusId: string, bra: boolean): string
	local nyckel = UgnetaController.liveNyckel(fokusId, bra)
	if nyckel then return Sprak.t(nyckel) end
	if not LIVE[fokusId] then return if bra then Sprak.t("ugneta.precis_sa") else "" end
	return ""
end

--[[ #264 GAIT_UGNETA_REVIEW_R1: `nyckel` och `args` är kommentarens
     identitet. Finns de slås texten upp HÄR och igen varje gång ytan ritas,
     på det språk som gäller då; `txt` är bara reserven för en anropare
     utan nyckel. ]]
local liveNyckelNu: string? = nil
local liveArgsNu: { any } = {}

local function liveTextNu(): string?
	if liveNyckelNu then return Sprak.t(liveNyckelNu, table.unpack(liveArgsNu)) end
	return nil
end

function UgnetaController.live(txt: string, bra: boolean, nyckel: string?, args: { any }?)
	liveNyckelNu = nyckel
	liveArgsNu = args or {}
	if nyckel then txt = liveTextNu() or txt end
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
	lektionSteg = os.clock()
	--[[ Bannerns visningstid går HÄR, i klientens enda loop. Modulen har
	     ingen egen timer och ingen `task.delay` — se noten i dess huvud. ]]
	CoachBanner.steg(dt)
	if liveTid > 0 then
		liveTid -= dt
		if liveTid <= 0 then
			local c = chip
			if c then c.Visible = false end
			liveSagt = ""
		end
	end
end

--[[ SÄKERHET VINNER. Släcker live-chipet, bannern och valen, så att
	"Bra rytm" aldrig står kvar bredvid en varning. ]]
function UgnetaController.sakerhetTarOver()
	local c = chip
	if c then c.Visible = false end
	--[[ Bannern släcks DIREKT, utan uttoning att invänta: en text om en
	     ritt som just avbröts ska inte tona bort i lugn och ro. ]]
	CoachBanner.Hide()
	local v = valrad
	if v then v.Visible = false end
	--[[ SÄKERHET FÖRE UNDERVISNING. Även sidovalen kastas: ett "Se ritten"
	     som överlevde avsittningen hade kunnat öppna en analys av en ritt
	     på en häst som inte finns. ]]
	replayFn = nil
	vidareFn = nil
	local kn = kortKnapp
	if kn then kn.Visible = false end
	local rk = replayKnapp
	if rk then rk.Visible = false end
	local vk = vidareKnapp
	if vk then vk.Visible = false end
	liveTid = 0
	liveSagt = ""
	--[[ `senasteBygg` KASTAS INTE här: bannerns etiketter behåller sin text
	     (övningen läses därur), och byggaren är det som gör att texten kan
	     översättas. Mätt i Studio: en återförening efter två monteringar
	     inom 23 ms visade övningen ur etiketterna, byggaren var kastad, och
	     språkbytet lämnade den på svenska. Väntan är släckt ovan, så ett
	     byte kan bara skriva om texten — aldrig väcka ett val. ]]
	lektionSteg = -math.huge
	--[[ SÄKERHET FÖRE UNDERVISNING. En väntande fortsättning får inte
	     överleva ett säkerhetsavbrott: annars kunde ett R-tryck efter
	     avsittningen starta ett försök på en häst som inte finns. ]]
	vantarPa = false
end

--[[ ── Beskedet mellan försöken ────────────────────────────────── ]]

--[[ Punkterna blir bannerns instruktionsrad. De sätts ihop med mellanslag
	och INTE med radbrytning: bannerns höjd är låst till 52 px av
	kontraktet, och en andra rad hade vuxit ramen i stället för att kapa
	texten. Antalet punkter är redan begränsat av `Ugneta.observationer`. ]]
local function enRad(punkter: { string }): string
	local rader = {}
	for _, p in punkter do
		if p ~= nil and p ~= "" then table.insert(rader, p) end
	end
	return table.concat(rader, " ")
end

local function visaBesked(rubrik: string, punkter: { string }, knapp: boolean,
	knappText: string?, replay: boolean?, vidare: boolean?)
	bygg()
	local v = valrad
	if not v then return end

	--[[ TEXTEN UPP, VALEN NER. Bannern får rubriken rå — ingen ledtext,
	     ingen tangentbokstav; se noten vid `medLedtext`. ]]
	CoachBanner.Show(rubrik, enRad(punkter))

	--[[ ── RADEN VIKER FÖR REGLAGEN ───────────────────────────────────

		Raden är centrerad och 92 % bred, max 640. På iPad ryms den:
		reglagen bor på x 961..1155 och raden slutar på 909. På iPhone i
		landskap är skärmen 749 bred, raden blir ändå 640 och lägger sig
		rakt över knappraden — mätt: SAKTA, SITT AV, HOPP, TYGEL, PARAD och
		DJUP SITS skymdes alla av `Kort`.

		Regeln nedan rör INTE surfplattan: ryms raden centrerad innanför
		den fria ytan står den kvar exakt där den stod. Bara när den inte
		ryms krymper den och centreras i det som är kvar. ]]
	laggUtVal()

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
	--[[ Lektionen väntar exakt när det FINNS ett val. Ett besked utan
	     knapp är en upplysning, inte ett val — och då står bara bannern
	     kvar, som tonar ut av sig själv. ]]
	vantarPa = knapp
	v.Visible = knapp or replay == true or vidare == true
	--[[ Beskedet hör till pausen mellan försöken. Går ridningen vidare
		ska chipet inte stå kvar bredvid det. ]]
	local c = chip
	if c then c.Visible = false end
end

--[[ Beskedet, öppet för den som kör lektionen. Presentationen av en övning
	och återkopplingen efter ett försök är samma yta — skillnaden är vad
	som står i den, inte vilken ruta den ritas i. ]]
--[[ #264: `rubrik` får vara en BYGGARE — en funktion som ger (rubrik,
     punkter, knapp, knappText, replay, vidare) på det språk som gäller när
     den körs. Då kan ett språkbyte skriva om beskedet på plats. Strängar
     tas emot som förut; de kan bara inte översättas i efterhand. ]]
function UgnetaController.visa(rubrik: any, punkter: { string }?, knapp: boolean?,
	knappText: string?, replay: boolean?, vidare: boolean?)
	if type(rubrik) == "function" then
		senasteBygg = rubrik
		visaBesked(rubrik())
		return
	end
	senasteBygg = nil
	visaBesked(rubrik, punkter or {}, knapp == true, knappText, replay, vidare)
end

function UgnetaController.dolj()
	local v = valrad
	if v then v.Visible = false end
	CoachBanner.Hide()
	vantarPa = false
end

--[[ Efter ett försök. `fore` är nil på första försöket. Observationerna
	kommer ur HorseCore/Ugneta — samma rangordning som webben. ]]
function UgnetaController.efterForsok(ovningId: string, nu: { [string]: number },
	fore: { [string]: number }?, forsokNr: number, kanSeRitten: boolean?)
	local obs = Ugneta.observationer(ovningId, nu, fore)
	local forsta = fore == nil
	--[[ #264: beskedet är en BYGGARE, så att ett språkbyte kan skriva om det
	     på plats. Observationerna räknas EN gång; bara orden slås upp igen. ]]
	local function bygget()
		local punkter = {}
		for _, o in obs do
			local ord = DIM_ORD[o.dim] or o.dim
			--[[ Mallarna låg som svenska literaler här och följde aldrig med
			     locale. Nu är de nycklar som alla andra spelarvända fält. ]]
			local nyckel = if o.sort == "battre" then "ugneta.obs.battre"
				elseif o.sort == "kvar" then "ugneta.obs.kvar"
				elseif o.sort == "bra" then "ugneta.obs.bra"
				else "ugneta.obs.jobba"
			table.insert(punkter, Sprak.t(nyckel, ord))
		end
		if #punkter == 0 then table.insert(punkter, Sprak.t("ugneta.jamnare_forsok")) end
		--[[ Beskedet har alltid en fortsättning nu. Förut fick bara försök 1 en
		     knapp och försök 2 låg kvar tills timern tog det — spelaren hade
		     inget sätt att säga "klar". ]]
		--[[ "Se ritten" bara när det FINNS en inspelning av försöket, och
		     "Gå vidare" bara efter första försöket — efter det sista är
		     huvudknappen redan vägen vidare. ]]
		return (if forsta then Sprak.t("ugneta.prova_igen") else Sprak.t("ugneta.forsok", forsokNr)),
			punkter, true,
			(if forsta then Sprak.t("ugneta.prova_igen") else Sprak.t("ugneta.nasta_ovning")),
			kanSeRitten == true, forsta
	end
	senasteBygg = bygget
	local rubrik, punkter, knapp, knappText, replay, vidare = bygget()
	visaBesked(rubrik, punkter, knapp, knappText, replay, vidare)
	return punkter
end

--[[ ── EFTER RITTEN: två eller tre punkter, sedan tyst ──────────────

	Samma yta, samma ordval och samma språknycklar som varje besked
	under ritten. Skälet är inte sparsamhet: en summering som ser
	annorlunda ut än coachningen läses som ett annat system, och
	kanon säger uttryckligen att det här inte får bli en dashboard.

	ORDEN KOMMER HÄRIFRÅN, inte från anroparen. `DIM_ORD` finns bara på
	ett ställe, och en andra avskrift i LektionController hade kunnat
	glida isär utan att något blev rött.

	Knappen är enda vägen ut — ingen timer. Den som just stigit av ska
	få läsa klart i sin egen takt, och en summering som försvinner av
	sig själv är en summering hon kanske aldrig såg. ]]
function UgnetaController.efterritt(punkter: { { dim: string, sort: string } })
	local function raderna(): { string }
		local rader = {}
		for _, o in ipairs(punkter) do
			local ord = DIM_ORD[o.dim] or o.dim
			local nyckel = if o.sort == "battre" then "ugneta.obs.battre"
				elseif o.sort == "kvar" then "ugneta.obs.kvar"
				elseif o.sort == "bra" then "ugneta.obs.bra"
				else "ugneta.obs.jobba"
			table.insert(rader, Sprak.t(nyckel, ord))
		end
		return rader
	end
	local rader = raderna()
	if #rader == 0 then return end
	--[[ #264: en byggare, så att summeringen följer ett språkbyte. ]]
	senasteBygg = function()
		return Sprak.t("ugneta.efterritt.rubrik"), raderna(), true,
			Sprak.t("ugneta.efterritt.stang"), false, false
	end
	visaBesked(Sprak.t("ugneta.efterritt.rubrik"), rader, true,
		Sprak.t("ugneta.efterritt.stang"), false, false)
	return rader
end

--[[ ── Fortsättningen: spelarens handling ──────────────────────────
	Valet mellan försöken stänger inte sig självt. Den som kör lektionen
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

--[[ SE RITTEN. Öppnar analysen och LÄMNAR KVAR väntan — valen ligger
     bakom panelen och beslutet är fortfarande spelarens när hon stänger
     den. Returnerar false när det inte finns någon väntan eller ingen
     ritt att visa, så att tangenten faller igenom till sin vanliga
     betydelse. ]]
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
	local v = valrad
	if v then v.Visible = false end
	fn()
	return true
end

--[[ Står lektionen och väntar på spelaren? ]]
function UgnetaController.vantar(): boolean
	return vantarPa
end

--[[ Spelaren gick vidare. Returnerar false när det inte fanns någon
	väntan att avsluta — så att en tangenttryckning utan val aldrig kan
	starta ett försök i smyg, och så att init.client kan låta samma
	tangent falla igenom till sin vanliga betydelse. ]]
function UgnetaController.fortsatt(): boolean
	if not vantarPa then return false end
	vantarPa = false
	local v = valrad
	if v then v.Visible = false end
	local fn = fortsattFn
	if fn then fn() end
	return true
end

--[[ ── UGNETAS YTA: VAD SOM STÅR, OCH NÄR DET RITAS OM (#264) ───────────

	HÖGST ETT MEDDELANDE, i den här ordningen:
	  1. lektionens återkoppling just nu (chipet, kort),
	  2. lektionens besked (bannerns text medan den står uppe),
	  3. lektionens övning (vägledningen, så länge lektionen pågår),
	  4. ridraden utanför lektionen (nyckel + argument, översätts vid ritning).
	Uppgiftens nej står INTE här: det hör till handlingen, i panelen. ]]
local function lararMeddelande(): string?
	local c = chip
	--[[ Kommentaren slogs upp ur sin nyckel när den kom, på det språk som
	     gällde då; ett språkbyte släcker den (`sprakBytt`), så den står
	     aldrig kvar på ett språk som inte gäller. ]]
	if c and c.Visible and c.Text ~= "" then return c.Text end
	if CoachBanner.synlig() then
		local m, d = CoachBanner.text()
		if m ~= "" or d ~= "" then
			return if d ~= "" and m ~= "" then (m .. " — " .. d) else (m .. d)
		end
	end
	--[[ Lektionen stegar den här modulen varje bildruta medan den pågår
	     (`steg`); det är svaret på «pågår en lektion», utan ett beroende
	     tillbaka till LektionController. ]]
	local pagar = os.clock() - lektionSteg < RAD_FARSK
	if pagar then
		local m, d = CoachBanner.text()
		if m ~= "" or d ~= "" then
			return if d ~= "" and m ~= "" then (m .. " — " .. d) else (m .. d)
		end
	end
	if radNyckel and os.clock() - radTid < RAD_FARSK then
		return Sprak.t(radNyckel, table.unpack(radArgs))
	end
	return nil
end

local function ritaLarare()
	local l = larare
	if not l or not l.Visible then return end
	local t = lararTitel
	if t then t.Text = Sprak.t("ugneta.titel") end
	local sv = Sprak.eget() == "sv"
	if flaggSv then flaggSv.Visible = sv end
	if flaggEn then flaggEn.Visible = not sv end
	if flaggNamn then flaggNamn.Text = Sprak.t("sprak.nuvarande") end
	local tips = lararTips
	if tips and tips.Visible then tips.Text = Sprak.t("sprak.byt") end
	--[[ Spelarlistan i högra hörnet: lägg ytan till vänster om den. ]]
	local hoger = 16
	pcall(function()
		if game:GetService("StarterGui"):GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList) then
			hoger = SPELARLISTA_B
		end
	end)
	local topp = LARARE_TOPP
	pcall(function()
		local inset = game:GetService("GuiService"):GetGuiInset()
		topp = inset.Y + LARARE_TOPP
	end)
	l.Position = UDim2.new(1, -hoger, 0, topp)
	local m = lararText
	if m then
		local txt = lararMeddelande()
		m.Text = txt or ""
		m.Visible = txt ~= nil and txt ~= ""
	end
end

--[[ Var ritas lektionens egna delar? Med en värd (panelen) i den dolda
     behållaren och Ugnetas yta synlig; utan värd där de alltid bott. ]]
vardLage = function()
	local g = gui
	if not g then return end
	local d = dolt
	local malet: Instance = if vard and d then d else g
	local c = chip
	if c then c.Parent = malet end
	local v = valrad
	if v then v.Parent = malet end
	local r = CoachBanner.ram()
	if r then r.Parent = malet end
	g.Enabled = true
	local l = larare
	if l then l.Visible = vard ~= nil end
	ritaLarare()
end

--[[ SPRÅKET BYTTES: skriv om det som står, på plats.
	  · chipet är en kortlivad kommentar på det gamla språket — släcks,
	  · knapparnas egna texter skrivs om,
	  · beskedet byggs om ur sin byggare. Väntar lektionen på ett val ritas
	    hela beskedet om — samma knappar, samma väntan. Står bara texten
	    kvar (bannern uppe eller övningen i etiketterna) skrivs den om utan
	    att visas igen eller få ny tid — inget går vidare, inget visas två
	    gånger. ]]
sprakBytt = function()
	local c = chip
	if c then c.Visible = false end
	liveTid = 0
	liveSagt = ""
	if replayKnapp then replayKnapp.Text = Sprak.t("ugneta.se_ritten") end
	if vidareKnapp then vidareKnapp.Text = Sprak.t("ugneta.ga_vidare") end
	local bygg = senasteBygg
	if bygg then
		local rubrik, punkter, knapp, knappText, replay, vidare = bygg()
		local v = valrad
		if vantarPa and v and v.Visible then
			visaBesked(rubrik, punkter, knapp, knappText, replay, vidare)
		elseif CoachBanner.synlig() then
			CoachBanner.Show(rubrik, enRad(punkter), CoachBanner.kvar())
		else
			CoachBanner.skrivTyst(rubrik, enRad(punkter))
		end
	end
	ritaLarare()
	if vard then vard() end
end

--[[ Ridraden utanför lektionen, som NYCKEL och argument. Matas varje
     bildruta medan hon rider; slutar matningen försvinner raden. ]]
function UgnetaController.ridrad(nyckel: string?, args: { any }?)
	radNyckel = nyckel
	radArgs = args or {}
	radTid = os.clock()
end

--[[ Provets fönster in: vad Ugnetas yta visar just nu. ]]
function UgnetaController._larare(): { [string]: any }
	ritaLarare()
	local l = larare
	return {
		synlig = l ~= nil and l.Visible,
		titel = if lararTitel then lararTitel.Text else "",
		text = if lararText and lararText.Visible then lararText.Text else "",
		flagga = if flaggNamn then flaggNamn.Text else "",
		sv = flaggSv ~= nil and flaggSv.Visible,
		en = flaggEn ~= nil and flaggEn.Visible,
		knapp = flaggKnapp,
		ram = l,
	}
end

function UgnetaController._vaxlaSprak()
	vaxlaSprak()
end

function UgnetaController.start()
	bygg()
	vardLage()
	--[[ Ett val spelaren redan gjort (attributet överlever respawn) gäller
	     från start, och serverns bekräftelse följs. ]]
	local function lasAttribut()
		local val = player:GetAttribute(Sprak.ATTRIBUT)
		if val == "sv" or val == "en" then Sprak.satVal(val) end
	end
	lasAttribut()
	pcall(function()
		player:GetAttributeChangedSignal(Sprak.ATTRIBUT):Connect(lasAttribut)
	end)
	--[[ Ytan ritas om i lugn takt: meddelandet följer chipet, bannern och
	     ridraden, som alla lever i andra loopar. ]]
	if ritKoppling == nil then
		local RunService = game:GetService("RunService")
		local sedan = 0
		ritKoppling = RunService.Heartbeat:Connect(function(dt)
			sedan += dt
			if sedan < 0.2 then return end
			sedan = 0
			ritaLarare()
		end)
	end
end

--[[ ══ EN PANEL (#264 PLAYER_INTERACTION_CONSOLIDATION) ════════════════

	Lektionens röst — bannern, live-chipet — och dess val (Prova igen, Se
	ritten, Gå vidare) ritades i en egen yta bredvid spelarens panel.
	Kontraktet: uppsutten visar panelen lektionens vägledning, kort coachning
	står i dess återkopplingsfält, och en giltig efterritt läses i panelen
	och avfärdas där.

	`panel()` lämnar det här modulen redan ritar, som data. Knapparna bär sina
	befintliga handlingar (`fortsatt`, `replay`, `gaVidare`) — samma väg som
	tangenten och knappen gick, med samma vakt (`vantarPa`). Med en värd
	(`satVard`) är den egna ytan släckt; elementens eget tillstånd, och alltså
	varje prov som läser det, är orört. ]]
function UgnetaController.satVard(fn: (() -> ())?)
	vard = fn
	vardLage()
end

function UgnetaController.panel(): any
	local knappar = {}
	local v = valrad
	if v and v.Visible then
		local kn = kortKnapp
		if kn and kn.Visible then
			table.insert(knappar, { text = kn.Text, aktiv = true, paTur = true,
				skicka = function() UgnetaController.fortsatt() end })
		end
		local rk = replayKnapp
		if rk and rk.Visible then
			table.insert(knappar, { text = rk.Text, aktiv = true,
				skicka = function() UgnetaController.replay() end })
		end
		local vk = vidareKnapp
		if vk and vk.Visible then
			table.insert(knappar, { text = vk.Text, aktiv = true,
				skicka = function() UgnetaController.gaVidare() end })
		end
	end
	local text: string? = nil
	local c = chip
	if c and c.Visible and c.Text ~= "" then
		text = c.Text
	elseif CoachBanner.synlig() then
		local m, d = CoachBanner.text()
		text = if d ~= "" then (m .. " — " .. d) else m
	end
	--[[ ÖVNINGEN står kvar i bannerns etiketter även när bannern tonat ut.
	     Den är lektionens VÄGLEDNING, inte en kort coachning, och panelen
	     visar den så länge lektionen pågår. ]]
	local m, d = CoachBanner.text()
	local ovning = if m ~= "" and d ~= "" then (m .. " — " .. d) else (m .. d)
	return { text = text, knappar = knappar, vantar = vantarPa, ovning = ovning }
end

return UgnetaController
