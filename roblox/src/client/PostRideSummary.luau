--!strict
--[[ EFTER PASSET — den lokala sammanfattningen (#234, visuellt delkontrakt).

	Beställningen 2026-09-19: när en giltig lektionsritt avslutas genom en
	auktoritativ avsittning ska spelaren få EN ruta som summerar passet —
	ett par resultatrader, en kort kommentar från Ugneta och ett stycke
	teori ur Ridhandboken — och sedan komma tillbaka till stallet.

	DEN RÄKNAR INGENTING. Vyn får en färdig tabell och ritar den. Den
	väljer ingen kommentar, den betygsätter inget försök och den skapar
	ingen XP: `UgnetaTema.summering` samlar, `UgnetaController` översätter,
	den här modulen visar. Skulle en manipulerad tabell komma hit är det
	värsta som kan hända att rutan visar fel text — det finns ingen väg
	härifrån till servern, och `varde` klampas till 0..1 innan den ritas.

	── EN YTA, INTE TVÅ ─────────────────────────────────────────────────

	Samma regel som `CoachBanner` (#244): `montera(förälder)` kräver en
	förälder och skapar ingen egen `ScreenGui`. Lektionen har redan
	`UBRFUgneta`, och kontraktet förbjuder en andra väg in. Det här är
	alltså inte ett konkurrerande post-ride-system — det är en zon till i
	den yta som redan finns, och den gamla nederpanelen väcks inte till
	liv: rutan visas EFTER avsittningen, aldrig under ritten.

	── LAYOUTEN RÄKNAS, DEN ANTAS INTE ──────────────────────────────────

	`layout(W, H)` är en REN funktion. Den bygger ingen Instance och går
	att prova mot en telefon, en iPad och en PC utan att något ritas —
	samma disciplin som `ReplayController.radLayout` och `CoachBanner
	.bredden`. Panelen krymper innehållet när höjden kräver det i stället
	för att låta knappen hamna utanför bild; att en stängningsknapp ska gå
	att nå är inte en designdetalj utan hela vägen ut ur rutan.

	── SKUGGAN LIGGER BAKOM, INTE UNDER ─────────────────────────────────

	Kontraktets 6 px droppskugga får inte flytta knappens träffyta eller
	skifta layouten. Den är därför ett SYSKON till knappen inuti en
	behållare som är exakt lika stor som knappen: skuggan sticker ut ur
	behållaren, men behållaren är det som layouten mäter. En skugga som
	varit barn till knappen hade ärvt dess klipp; en som varit en egen rad
	hade skjutit ned allt under sig 6 px.
]]

local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

local PostRideSummary = {}

--[[ ── KONTRAKTETS TAL, SAMLADE ────────────────────────────────────────
     De står här och inte utspridda i bygget så att en review kan läsa dem
     mot beställningen utan att leta. ]]
local PANEL_FARG = Color3.fromRGB(138, 59, 212)      -- --panel-top
local GULD = Color3.fromRGB(246, 196, 69)            -- --gold
local GRON = Color3.fromRGB(126, 217, 87)            -- --btn-green-top
local KRAM = Color3.fromRGB(245, 239, 224)           -- --cream
local KRAM_TEXT = Color3.fromRGB(46, 34, 62)
local TEXT = Color3.fromRGB(255, 255, 255)
local SPAR = Color3.fromRGB(74, 27, 109)             -- --panel-bottom
local KNAPP_TEXT = Color3.fromRGB(23, 20, 10)
local SKUGGA = Color3.fromRGB(40, 10, 60)

local RAM_PX = 4                                     -- guldramens tjocklek
local HORN_PX = 22                                   -- panelens hörnradie
local KNAPP_HORN = 18
local RAND_PX = 4                                    -- NoteBox vänsterrand
local SKUGGA_PX = 6                                  -- droppskuggans offset
local KNAPP_MIN_HOJD = 48                            -- tumgreppets golv + luft

local ANDEL_B = 0.72
local MIN_B = 280
local MAX_B = 520
local SIDLUFT = 0.92
local HOJDLUFT = 0.94

--[[ Innehållets höjder vid full skala. `layout` skalar ned dem som ett
     block när viewporten är för låg — proportionerna hålls, och ingen zon
     kan äta en annans plats. ]]
local PAD = 18
local GAP = 12
local MATARE_HOJD = 34
local MATARE_GAP = 8
local KOMMENTAR_HOJD = 52
local TEORI_HOJD = 104
local KNAPP_HOJD = 48
--[[ Under 0,60 blir texten oläslig, och då är det viewporten som är fel,
     inte layouten. Golvet gör att provet FALLER i stället för att tyst
     rita något ingen kan läsa. ]]
local SKALA_GOLV = 0.60

--[[ Längsta text vyn ritar. Kontraktet kräver att lång svensk text inte
     krockar med nästa zon; det hålls av TVÅ oberoende saker — zonen
     klipper sitt innehåll, och strängen kortas redan här. Bältet är
     klippningen, hängslena är den här gränsen: en klippt etikett utan
     ellips ser ut som ett fel, en kortad med ellips ser ut som ett val. ]]
local MAX_KOMMENTAR = 160
local MAX_BROD = 280
local MAX_KORT = 48

PostRideSummary.MAX_KOMMENTAR = MAX_KOMMENTAR
PostRideSummary.MAX_BROD = MAX_BROD
PostRideSummary.MAX_KORT = MAX_KORT
PostRideSummary.SKUGGA_PX = SKUGGA_PX
PostRideSummary.RAM_PX = RAM_PX
PostRideSummary.RAND_PX = RAND_PX

export type Layout = {
	bredd: number, hojd: number, skala: number,
	matare: number, kommentar: number, teori: number, knapp: number,
}

--[[ ── DEN RENA RÄKNINGEN ──────────────────────────────────────────────
     `W`/`H` är ytans mått i GUI-pixlar. `antal` är hur många
     resultatrader tabellen faktiskt bar — 0, 1 eller 2. En panel som
     alltid reserverar två rader hade fått ett tomt hål när passet bara
     mätte en. ]]
function PostRideSummary.layout(W: number, H: number, antal: number): Layout
	local w = math.max(0, W)
	local h = math.max(0, H)
	local n = math.clamp(math.floor(antal or 0), 0, 2)

	local golv = math.min(SIDLUFT * w, MIN_B)
	local bredd = math.clamp(ANDEL_B * w, golv, MAX_B)

	local matare = if n > 0 then n * MATARE_HOJD + (n - 1) * MATARE_GAP else 0
	local innehall = matare + KOMMENTAR_HOJD + TEORI_HOJD + KNAPP_HOJD
	--[[ Mellanrum bara mellan zoner som FINNS. Utan raden hade en panel
	     utan resultatrader burit ett tomt 12 px-gap överst. ]]
	local gap = GAP * (if n > 0 then 3 else 2)
	local full = 2 * PAD + innehall + gap

	local tak = HOJDLUFT * h
	local skala = if tak > 0 and full > tak
		then math.max(SKALA_GOLV, tak / full)
		else 1

	return {
		bredd = math.floor(bredd),
		hojd = math.floor(full * skala),
		skala = skala,
		matare = matare * skala,
		kommentar = KOMMENTAR_HOJD * skala,
		teori = TEORI_HOJD * skala,
		knapp = math.max(KNAPP_MIN_HOJD * SKALA_GOLV, KNAPP_HOJD * skala),
	}
end

--[[ ── VALIDERINGEN ────────────────────────────────────────────────────
     Tabellen kommer utifrån. Den kan sakna fält, bära nil, bära tal där
     text ska stå och bära en text som är längre än rutan. Ingen av de
     fyra får ge ett runtimefel, och ingen av dem får ge en tom ruta utan
     förklaring. ]]
local function txt(v: any, tak: number, reserv: string): string
	local s = if type(v) == "string" then v else ""
	if s == "" then s = reserv end
	if utf8.len(s) == nil then return reserv end
	local n = utf8.len(s) :: number
	if n > tak then
		--[[ Kapas på en TECKENGRÄNS, inte på en byte: `string.sub` mitt i
		     ett ä hade gett ett trasigt tecken i HUD:en. ]]
		local slut = utf8.offset(s, tak + 1)
		if slut then s = string.sub(s, 1, slut - 1) .. "…" end
	end
	return s
end

local function andel(v: any): number
	if type(v) ~= "number" then return 0 end
	if v ~= v then return 0 end                       -- NaN
	return math.clamp(v, 0, 1)
end

--[[ ── TILLSTÅNDET ─────────────────────────────────────────────────────
     Modulnivå, som CoachBanner: det finns exakt en lokal spelare och
     exakt en sammanfattning. ]]
local forlader: Instance? = nil
local panel: Frame? = nil
local matarLista: Frame? = nil
local matarRader: { { ram: Frame, etikett: TextLabel, fyll: Frame, glans: Frame } } = {}
local kommentarZon: Frame? = nil
local kommentarText: TextLabel? = nil
local teoriZon: Frame? = nil
local teoriRubrik: TextLabel? = nil
local teoriRegel: TextLabel? = nil
local teoriBrod: TextLabel? = nil
local knappBox: Frame? = nil
local knapp: TextButton? = nil
local knappSkugga: Frame? = nil
local ytsignal: RBXScriptConnection? = nil
local knappsignal: RBXScriptConnection? = nil
local levande: { Tween } = {}
local stangFn: (() -> ())? = nil
local sistaAntal = 0
local valdFore: any = nil

local function slapp()
	for _, t in levande do
		local avbryt = (t :: any).Cancel
		if avbryt then avbryt(t) end
	end
	table.clear(levande)
end

local function reducerRorelse(): boolean
	return (GuiService :: any).ReducedMotionEnabled == true
end

--[[ Topbarens höjd. Ytan har `IgnoreGuiInset = true`, så den räknas inte
     bort åt oss — panelen skulle annars kunna centreras under Roblox egen
     meny på en låg skärm. ]]
local function inset(): number
	local ok, topp = pcall(function()
		return (GuiService :: any):GetGuiInset()
	end)
	if ok and topp and type(topp.Y) == "number" then return topp.Y end
	return 0
end

local function nyRam(namn: string, mor: Instance, ordning: number?): Frame
	local f = Instance.new("Frame")
	f.Name = namn
	f.BackgroundTransparency = 1
	f.BorderSizePixel = 0
	if ordning then f.LayoutOrder = ordning end
	f.Parent = mor
	return f
end

local function nyText(namn: string, mor: Instance, storlek: number, farg: Color3,
	font: Enum.Font): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = namn
	l.BackgroundTransparency = 1
	l.BorderSizePixel = 0
	l.Font = font
	l.TextSize = storlek
	l.TextColor3 = farg
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Top
	l.TextWrapped = true
	l.RichText = false
	l.Text = ""
	l.Parent = mor
	return l
end

--[[ ── UTLÄGGNINGEN ───────────────────────────────────────────────────
     Körs när panelen visas OCH när ytan ändrar storlek. Samma lärdom som
     #206 och #208: en layout som räknas en gång lämnas i gammal geometri
     av en vridning, och då hamnar knappen utanför bild. ]]
local function laggUt()
	local p = panel
	if not p then return end
	local f = forlader :: any
	local W = if f and f.AbsoluteSize then f.AbsoluteSize.X else 0
	local H = if f and f.AbsoluteSize then f.AbsoluteSize.Y else 0
	if W <= 0 or H <= 0 then return end
	local topp = inset()
	local L = PostRideSummary.layout(W, H - topp, sistaAntal)
	p.Size = UDim2.new(0, L.bredd, 0, L.hojd)
	--[[ Centrerad i den yta som ÄR spelarens — alltså under topbaren. ]]
	p.Position = UDim2.new(0.5, 0, 0, math.floor(topp + (H - topp) / 2))

	local pad = p:FindFirstChildOfClass("UIPadding")
	if pad then
		local q = math.floor(PAD * L.skala)
		pad.PaddingTop = UDim.new(0, q)
		pad.PaddingBottom = UDim.new(0, q)
		pad.PaddingLeft = UDim.new(0, q)
		pad.PaddingRight = UDim.new(0, q)
	end
	local lista = p:FindFirstChildOfClass("UIListLayout")
	if lista then lista.Padding = UDim.new(0, math.floor(GAP * L.skala)) end

	local ml = matarLista
	if ml then
		ml.Visible = sistaAntal > 0
		ml.Size = UDim2.new(1, 0, 0, math.floor(L.matare))
		local ll = ml:FindFirstChildOfClass("UIListLayout")
		if ll then ll.Padding = UDim.new(0, math.floor(MATARE_GAP * L.skala)) end
		for i, rad in matarRader do
			rad.ram.Size = UDim2.new(1, 0, 0, math.floor(MATARE_HOJD * L.skala))
			rad.etikett.TextSize = math.max(10, math.floor(14 * L.skala))
			rad.ram.Visible = i <= sistaAntal
		end
	end
	local kz, kt = kommentarZon, kommentarText
	if kz then kz.Size = UDim2.new(1, 0, 0, math.floor(L.kommentar)) end
	if kt then kt.TextSize = math.max(10, math.floor(15 * L.skala)) end
	local tz = teoriZon
	if tz then tz.Size = UDim2.new(1, 0, 0, math.floor(L.teori)) end
	if teoriRubrik then teoriRubrik.TextSize = math.max(9, math.floor(11 * L.skala)) end
	if teoriRegel then teoriRegel.TextSize = math.max(10, math.floor(14 * L.skala)) end
	if teoriBrod then teoriBrod.TextSize = math.max(9, math.floor(12 * L.skala)) end
	local kb, kn, ks = knappBox, knapp, knappSkugga
	if kb then kb.Size = UDim2.new(1, 0, 0, math.floor(L.knapp)) end
	if kn then
		kn.Size = UDim2.new(1, 0, 1, 0)
		kn.TextSize = math.max(11, math.floor(16 * L.skala))
	end
	--[[ Skuggan följer knappens storlek men ligger i BEHÅLLAREN, förskjuten
	     6 px. Den har ingen `LayoutOrder` och ingen egen rad — se
	     modulhuvudet. ]]
	if ks then
		ks.Size = UDim2.new(1, 0, 1, 0)
		ks.Position = UDim2.new(0, SKUGGA_PX, 0, SKUGGA_PX)
	end
end

--[[ Provets fönster in: lägg ut igen utan att visa något nytt. ]]
function PostRideSummary._laggUt()
	laggUt()
end

--[[ ── MÄTAREN: TRE LAGER ─────────────────────────────────────────────
     spår, fyllning och glans — precis som ART_STYLE:s `.bar/.fill/.gloss`.

     GLANSEN ÄR BARN TILL FYLLNINGEN och 100 % bred i skala. Det är det som
     gör att den följer fyllningens KLIPPTA bredd utan en enda extra
     uträkning: växer fyllningen växer glansen, och en glans som räknats
     separat hade kunnat hamna utanför den vid ett avbrutet tween. ]]
local function byggMatare(mor: Instance, ordning: number)
	local ram = nyRam("Matare" .. ordning, mor, ordning)
	ram.Size = UDim2.new(1, 0, 0, MATARE_HOJD)
	ram.Visible = false

	local etikett = nyText("Etikett", ram, 14, TEXT, Enum.Font.GothamBold)
	etikett.Size = UDim2.new(1, 0, 0, 16)
	etikett.TextYAlignment = Enum.TextYAlignment.Center
	etikett.TextWrapped = false
	etikett.TextTruncate = Enum.TextTruncate.AtEnd

	local spar = nyRam("Spar", ram)
	spar.Size = UDim2.new(1, 0, 0, 12)
	spar.Position = UDim2.new(0, 0, 1, -12)
	spar.BackgroundTransparency = 0
	spar.BackgroundColor3 = SPAR
	spar.ClipsDescendants = true
	local sh = Instance.new("UICorner")
	sh.CornerRadius = UDim.new(1, 0)
	sh.Parent = spar

	local fyll = nyRam("Fyll", spar)
	fyll.Size = UDim2.new(0, 0, 1, 0)
	fyll.BackgroundTransparency = 0
	fyll.BackgroundColor3 = GRON
	local fh = Instance.new("UICorner")
	fh.CornerRadius = UDim.new(1, 0)
	fh.Parent = fyll

	local glans = nyRam("Glans", fyll)
	glans.Size = UDim2.new(1, 0, 0.45, 0)
	glans.BackgroundTransparency = 0.62
	glans.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	local gh = Instance.new("UICorner")
	gh.CornerRadius = UDim.new(1, 0)
	gh.Parent = glans

	table.insert(matarRader, { ram = ram, etikett = etikett, fyll = fyll, glans = glans })
end

--[[ ── BYGGET ─────────────────────────────────────────────────────────
     En gång. Ett andra `montera` med samma förälder är en no-op; med en
     NY förälder rivs den gamla panelen först, så att en respawn inte kan
     lämna två. Samma kontrakt som CoachBanner. ]]
function PostRideSummary.montera(mor: Instance?)
	if not mor then return end
	if panel and forlader == mor then return end
	PostRideSummary.Destroy()
	forlader = mor

	local p = Instance.new("Frame")
	p.Name = "PostRideSummary"
	p.AnchorPoint = Vector2.new(0.5, 0.5)
	p.Position = UDim2.new(0.5, 0, 0.5, 0)
	p.Size = UDim2.new(0, MIN_B, 0, 260)
	p.BackgroundColor3 = PANEL_FARG
	p.BackgroundTransparency = 0
	p.BorderSizePixel = 0
	p.Visible = false
	p.ZIndex = 20
	local horn = Instance.new("UICorner")
	horn.CornerRadius = UDim.new(0, HORN_PX)
	horn.Parent = p
	local kant = Instance.new("UIStroke")
	kant.Name = "Guldram"
	kant.Color = GULD
	kant.Thickness = RAM_PX
	kant.Parent = p
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, PAD)
	pad.PaddingBottom = UDim.new(0, PAD)
	pad.PaddingLeft = UDim.new(0, PAD)
	pad.PaddingRight = UDim.new(0, PAD)
	pad.Parent = p
	local lista = Instance.new("UIListLayout")
	lista.FillDirection = Enum.FillDirection.Vertical
	lista.SortOrder = Enum.SortOrder.LayoutOrder
	lista.HorizontalAlignment = Enum.HorizontalAlignment.Center
	lista.Padding = UDim.new(0, GAP)
	lista.Parent = p
	p.Parent = mor
	panel = p

	--[[ ZON 1 — RESULTATET. ]]
	local ml = nyRam("Resultat", p, 1)
	ml.Size = UDim2.new(1, 0, 0, MATARE_HOJD)
	local mll = Instance.new("UIListLayout")
	mll.FillDirection = Enum.FillDirection.Vertical
	mll.SortOrder = Enum.SortOrder.LayoutOrder
	mll.Padding = UDim.new(0, MATARE_GAP)
	mll.Parent = ml
	matarLista = ml
	table.clear(matarRader)
	byggMatare(ml, 1)
	byggMatare(ml, 2)

	--[[ ZON 2 — UGNETAS KOMMENTAR. Kursiv, och kursiveringen kommer ur
	     `FontFace`: `TextLabel.Font` är en gammal enum utan stil, och
	     `Enum.Font` har ingen kursiv Gotham. `Font.new` med
	     `Enum.FontStyle.Italic` är vägen som faktiskt finns — kontrollerat
	     mot create.roblox.com/docs/reference/engine/datatypes/Font
	     (uppdaterad 2026-09-18). BuilderSans ÄR Gothams familj i samma
	     tabell, så typsnittet är detsamma som resten av HUD:en.

	     Zonen klipper. Se noten vid MAX_KOMMENTAR. ]]
	local kz = nyRam("Kommentar", p, 2)
	kz.Size = UDim2.new(1, 0, 0, KOMMENTAR_HOJD)
	kz.ClipsDescendants = true
	kommentarZon = kz
	local kt = nyText("UgnetaKommentar", kz, 15, TEXT, Enum.Font.Gotham)
	kt.Size = UDim2.new(1, 0, 1, 0)
	kt.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json",
		Enum.FontWeight.Regular, Enum.FontStyle.Italic)
	kommentarText = kt

	--[[ ZON 3 — NOTEBOX. Krämvit botten, EN guldrand till vänster och
	     ingen ram runt om: randen är hela markeringen, precis som webbens
	     `.note` i rapportvarianten. En UIStroke här hade konkurrerat med
	     den. ]]
	local tz = nyRam("NoteBox", p, 3)
	tz.Size = UDim2.new(1, 0, 0, TEORI_HOJD)
	tz.BackgroundTransparency = 0
	tz.BackgroundColor3 = KRAM
	tz.ClipsDescendants = true
	local tzh = Instance.new("UICorner")
	tzh.CornerRadius = UDim.new(0, 8)
	tzh.Parent = tz
	teoriZon = tz
	local rand = nyRam("Vansterrand", tz)
	rand.Size = UDim2.new(0, RAND_PX, 1, 0)
	rand.Position = UDim2.new(0, 0, 0, 0)
	rand.BackgroundTransparency = 0
	rand.BackgroundColor3 = GULD
	rand.ZIndex = 21
	local tpad = Instance.new("UIPadding")
	tpad.PaddingLeft = UDim.new(0, RAND_PX + 10)
	tpad.PaddingRight = UDim.new(0, 10)
	tpad.PaddingTop = UDim.new(0, 8)
	tpad.PaddingBottom = UDim.new(0, 8)
	tpad.Parent = tz
	local tlista = Instance.new("UIListLayout")
	tlista.FillDirection = Enum.FillDirection.Vertical
	tlista.SortOrder = Enum.SortOrder.LayoutOrder
	tlista.Padding = UDim.new(0, 3)
	tlista.Parent = tz
	teoriRubrik = nyText("Overrubrik", tz, 11, Color3.fromRGB(150, 110, 30),
		Enum.Font.GothamBold)
	teoriRubrik.LayoutOrder = 1
	teoriRubrik.Size = UDim2.new(1, 0, 0, 13)
	teoriRubrik.TextWrapped = false
	teoriRubrik.TextTruncate = Enum.TextTruncate.AtEnd
	teoriRegel = nyText("Karnregel", tz, 14, KRAM_TEXT, Enum.Font.GothamBold)
	teoriRegel.LayoutOrder = 2
	teoriRegel.Size = UDim2.new(1, 0, 0, 17)
	teoriRegel.TextWrapped = false
	teoriRegel.TextTruncate = Enum.TextTruncate.AtEnd
	teoriBrod = nyText("Brodtext", tz, 12, KRAM_TEXT, Enum.Font.Gotham)
	teoriBrod.LayoutOrder = 3
	teoriBrod.Size = UDim2.new(1, 0, 1, -34)

	--[[ ZON 4 — VÄGEN UT. ]]
	local kb = nyRam("KnappBox", p, 4)
	kb.Size = UDim2.new(1, 0, 0, KNAPP_HOJD)
	knappBox = kb
	local ks = nyRam("Skugga", kb)
	ks.Size = UDim2.new(1, 0, 1, 0)
	ks.Position = UDim2.new(0, SKUGGA_PX, 0, SKUGGA_PX)
	ks.BackgroundTransparency = 0.45
	ks.BackgroundColor3 = SKUGGA
	ks.ZIndex = 20
	local ksh = Instance.new("UICorner")
	ksh.CornerRadius = UDim.new(0, KNAPP_HORN)
	ksh.Parent = ks
	knappSkugga = ks

	local kn = Instance.new("TextButton")
	kn.Name = "TillbakaTillStallet"
	kn.AutoButtonColor = true
	kn.Size = UDim2.new(1, 0, 1, 0)
	kn.Position = UDim2.new(0, 0, 0, 0)
	kn.BackgroundColor3 = GULD
	kn.TextColor3 = KNAPP_TEXT
	kn.Font = Enum.Font.GothamBold
	kn.TextSize = 16
	kn.Text = ""
	kn.BorderSizePixel = 0
	kn.ZIndex = 22
	--[[ Gamepad: knappen måste vara VALBAR för att styrkorset ska hitta
	     den. `GuiService.SelectedObject` pekas hit i `visa`. ]]
	kn.Selectable = true
	local knh = Instance.new("UICorner")
	knh.CornerRadius = UDim.new(0, KNAPP_HORN)
	knh.Parent = kn
	kn.Parent = kb
	knapp = kn

	knappsignal = kn.Activated:Connect(function()
		PostRideSummary.stang()
	end)

	local f = mor :: any
	if f.GetPropertyChangedSignal then
		ytsignal = f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			local pp = panel
			if pp and pp.Visible then laggUt() end
		end)
	end
end

--[[ Den som ska veta att spelaren valde att gå tillbaka. Registreras av
     `UgnetaController`; vyn själv gör ingenting mer än att stänga. ]]
function PostRideSummary.vidStang(fn: (() -> ())?)
	stangFn = fn
end

--[[ ── VISNINGEN ──────────────────────────────────────────────────────

	`data` är kontraktets tabell:

	    { telemetri = { { nyckel/etikett, varde }, … },
	      ugnetaKommentar = "…",
	      teoriText = { overRubrik, karnregel, brodtext } }

	IDEMPOTENT. Ett andra anrop med samma pass byter innehåll och lägger ut
	igen — det bygger ingen andra panel och startar ingen andra
	knapplyssnare. Står rutan redan uppe blinkar den inte. ]]
function PostRideSummary.visa(data: { [string]: any }?)
	local p = panel
	if not p then return end
	--[[ STOD RUTAN REDAN UPPE? Frågan avgör EN sak, och den är inte
	     kosmetisk: gamepadens gamla fokus får bara sparas när panelen
	     öppnas, inte vid varje innehållsuppdatering.

	     Första utkastet sparade det varje gång. Ett andra `visa` sparade
	     då knappen som "det som var valt förut", och stängningen lämnade
	     tillbaka fokus till en knapp i en dold ruta — styrkorset pekade på
	     något spelaren inte kunde se. Provet fällde det på
	     `GuiService.SelectedObject == nil`. ]]
	local varOppen = p.Visible == true
	slapp()

	local d = if type(data) == "table" then data else {}
	local rader = if type(d.telemetri) == "table" then d.telemetri else {}
	sistaAntal = math.clamp(#rader, 0, 2)

	for i, rad in matarRader do
		local post = rader[i]
		if i <= sistaAntal and type(post) == "table" then
			rad.etikett.Text = txt(post.etikett or post.namn, MAX_KORT, "—")
			local mal = andel(post.varde)
			rad.fyll.BackgroundColor3 = if mal >= 0.5 then GRON else GULD
			--[[ NOLL, FULLT OCH SAKNAT SKA VARA VISUELLT STABILA. Fyllningen
			     sätts till noll FÖRST och tonas sedan till målet; utan det
			     hade en ny rad ärvt förra passets bredd i en bildruta. ]]
			rad.fyll.Size = UDim2.new(0, 0, 1, 0)
			if reducerRorelse() or mal <= 0 then
				rad.fyll.Size = UDim2.new(mal, 0, 1, 0)
			else
				local t = TweenService:Create(rad.fyll,
					TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Size = UDim2.new(mal, 0, 1, 0) })
				table.insert(levande, t)
				t:Play()
			end
			rad.ram.Visible = true
		else
			rad.ram.Visible = false
			rad.fyll.Size = UDim2.new(0, 0, 1, 0)
			rad.etikett.Text = ""
		end
	end

	local kt = kommentarText
	if kt then
		kt.Text = txt(d.ugnetaKommentar, MAX_KOMMENTAR, "")
		--[[ Ingen kommentar OCH ingen reserv är ett tomt fält, och ett tomt
		     fält säger ingenting. Den som ropar lämnar reserven; saknas
		     även den döljs zonen hellre än att stå tom. ]]
		local kz = kommentarZon
		if kz then kz.Visible = kt.Text ~= "" end
	end

	local teori = if type(d.teoriText) == "table" then d.teoriText else {}
	if teoriRubrik then teoriRubrik.Text = txt(teori.overRubrik, MAX_KORT, "") end
	if teoriRegel then teoriRegel.Text = txt(teori.karnregel, MAX_KORT, "") end
	if teoriBrod then teoriBrod.Text = txt(teori.brodtext, MAX_BROD, "") end
	local tz = teoriZon
	if tz then
		tz.Visible = (teoriRegel ~= nil and teoriRegel.Text ~= "")
			or (teoriBrod ~= nil and teoriBrod.Text ~= "")
	end

	local kn = knapp
	if kn then kn.Text = txt(d.knappText, MAX_KORT, "") end

	p.Visible = true
	laggUt()

	--[[ Gamepadens fokus flyttas hit, och det GAMLA fokuset sparas så att
	     stängningen kan lämna tillbaka det. En panel som kastar fokus utan
	     att lämna tillbaka det låser styrkorset i tomma intet. ]]
	if kn then
		if not varOppen then valdFore = (GuiService :: any).SelectedObject end
		;(GuiService :: any).SelectedObject = kn
	end
end

function PostRideSummary.oppen(): boolean
	local p = panel
	return p ~= nil and p.Visible == true
end

--[[ ── STÄNGNINGEN ────────────────────────────────────────────────────

	ETT TRYCK GER EXAKT EN STÄNGNINGSAVSIKT, och gaten är `Visible` —
	inte en egen flagga bredvid den.

	HÄR STOD EN EGEN `debounce`-BOOLEAN, OCH DEN VAR EN ANDRA SANNING.
	Falsifieringen avslöjade den: provet "tre snabba tryck ger EN
	stängning" var GRÖNT även när flaggan togs bort, alltså mätte det
	aldrig flaggan. Skälet är att `Visible` sätts till false FÖRE
	`stangFn` körs — det andra och tredje trycket faller redan på raden
	ovanför, och samma rad stänger dessutom återinträde ur callbacken.

	En vakt som aldrig kan fyra ser ut som säkerhet men är en andra
	tillståndsvariabel att hålla i synk. Den är borta; kvar är EN gate,
	och den går att falsifiera — tas raden nedan bort räknar provet två
	stängningar på tre tryck.

	Städar tweens och lämnar ingen osynlig inputblockerare: en `Frame`
	med `Visible = false` tar inte emot input i Roblox, och knappen är
	dessutom den enda `Selectable` ytan här. ]]
function PostRideSummary.stang(): boolean
	local p = panel
	if not p or not p.Visible then return false end
	slapp()
	p.Visible = false
	;(GuiService :: any).SelectedObject = valdFore
	valdFore = nil
	local fn = stangFn
	if fn then fn() end
	return true
end

function PostRideSummary.Destroy()
	slapp()
	local s = ytsignal
	if s then s:Disconnect() end
	ytsignal = nil
	local k = knappsignal
	if k then k:Disconnect() end
	knappsignal = nil
	local p = panel
	if p then p:Destroy() end
	panel = nil
	matarLista = nil
	table.clear(matarRader)
	kommentarZon, kommentarText = nil, nil
	teoriZon, teoriRubrik, teoriRegel, teoriBrod = nil, nil, nil, nil
	knappBox, knapp, knappSkugga = nil, nil, nil
	forlader = nil
	sistaAntal = 0
	valdFore = nil
end

--[[ ── PROVETS AVLÄSNINGAR ───────────────────────────────────────────── ]]

function PostRideSummary.ram(): Frame?
	return panel
end

function PostRideSummary.matare(): { { ram: Frame, etikett: TextLabel,
	fyll: Frame, glans: Frame } }
	return matarRader
end

function PostRideSummary.text(): (string, string, string, string)
	return
		if kommentarText then kommentarText.Text else "",
		if teoriRubrik then teoriRubrik.Text else "",
		if teoriRegel then teoriRegel.Text else "",
		if teoriBrod then teoriBrod.Text else ""
end

function PostRideSummary.knapp(): TextButton?
	return knapp
end

return PostRideSummary
