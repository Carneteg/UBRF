--!strict
--[[ COACH BANNER — EN RAD LÄRARTEXT, INTE EN DIALOGRUTA (#244).

	Beställningen 2026-09-18: Ugnetas gamla RPG-lika nederpanel ersätts av
	en minimalistisk, toppcentrerad banner. Två rader — MÅLET i versaler och
	en kort instruktion under — som tonar in, står kvar några sekunder och
	tonar ut igen. Primära ytor är iPad och PC.

	RIDE FIRST är hela skälet. Panelen låg i underkanten, över underlaget
	precis där hästen rör sig, och den bar ett avsändarnamn, en rubrikrad
	och upp till två punktrader. Bannern säger samma sak på två rader uppe
	i kanten och lämnar sikten fri.

	DEN HITTAR INTE PÅ NÅGON TEXT. `Show` visar det den får. Lektionen äger
	orden, och de kommer som förut ur språkkatalogen och `RidKanon.UGNETA` —
	se `UgnetaController` och `LektionController`. En demonstrationsreplik
	här hade varit en andra sanning om vad Ugneta säger.

	── VARFÖR TIDEN RÄKNAS I `steg` OCH INTE I `task.delay` ──────────────

	Kontraktets krav 5 är att gamla fördröjda callbacks inte får komma
	tillbaka och släcka en ny text. Det går att bevaka med en
	generationsräknare — men det går också att göra OMÖJLIGT, och det är
	vad som gjorts här: modulen har ingen `task.delay` alls. Visningstiden
	är ett tal som minskar i klientens enda uppdateringsloop, precis som
	live-chipets `liveTid` bredvid. Ett nytt `Show` skriver om talet; det
	finns ingen andra tråd som kan skriva det igen efteråt.

	Det ger också ett deterministiskt prov: `coachbanner.spec.luau` kan
	stega exakt 4,5 sekunder i stället för att hoppas på en schemaläggare.

	TweenService används för det den är till för — själva toningen av
	genomskinlighet. Den bär ingen lifecycle: `Visible` sätts av `steg`,
	inte av en `Completed`-callback. En tween som avbryts mitt i kan alltså
	inte lämna bannern i ett läge ingen städar bort.

	── EN YTA, INTE TVÅ ──────────────────────────────────────────────────

	`montera(förälder)` kräver en förälder och skapar ingen egen ScreenGui.
	Kontraktet förbjuder dubbla ScreenGui-instanser, och lektionen har
	redan en: `UBRFUgneta`, med `ResetOnSpawn = false` och
	`IgnoreGuiInset = true`. Bannern bor i den.
]]

local TweenService = game:GetService("TweenService")

local CoachBanner = {}

--[[ ── Kontraktets tal, samlade ───────────────────────────────────────
	De står här och inte utspridda i bygget för att en review ska kunna
	läsa dem mot beställningen utan att leta. ]]
local FADE = 0.4                                   -- in och ut, sekunder
local STANDARD_TID = 4.5                           -- kontraktet: 4–5 s
local HOJD = 52                                    -- kontraktet: 50–54 px
local TOPP = 48                                    -- under Roblox-menyn
local ANDEL = 0.42                                 -- av bredden, stor skärm
local MIN_BREDD = 300                              -- telefonens golv
local MAX_BREDD = 560                              -- PC:ns tak
local SIDLUFT = 0.92                               -- aldrig bredare än så

local RAM_FARG = Color3.fromRGB(20, 20, 25)
local RAM_TRANSPARENS = 0.35
local STROKE_TRANSPARENS = 0.75
local MAL_FARG = Color3.fromRGB(255, 255, 255)
local DETALJ_FARG = Color3.fromRGB(200, 200, 205)

--[[ ══ VERSALERNA RÄKNAS HÄR, INTE AV EN EGENSKAP ══════════════════════

	Kontraktet vill ha målraden i versaler. Första utkastet satte
	`TextLabel.TextTransform = Enum.TextTransform.UppercaseAll` — och den
	egenskapen FINNS INTE på `TextLabel`. Kontrollerat mot
	create.roblox.com/docs/reference/engine/classes/TextLabel (uppdaterad
	2026-09-17): klassen har TextTruncate, TextDirection, TextScaled och
	TextWrapped, men ingen TextTransform. Raden hade kastat
	"TextTransform is not a valid member of TextLabel" i Studio och tagit
	hela lektionsytan med sig.

	Bänken kunde inte se det: stubben hade fått enumen påhittad åt sig. Det
	är samma lärdom som `Enum.Material` en gång gav — en enum-mock som
	svarar ja på allt flyttar felet från sviten till Studio.

	`string.upper` ensam räcker inte: den arbetar per byte och lämnar å, ä
	och ö orörda i UTF-8, vilket hade gett "STOR VOLT" men "ÖKNING" som
	"öKNING". Tabellen nedan täcker de tecken svensk spelartext faktiskt
	använder. Pilen → och andra flerbytetecken passerar oförändrade, vilket
	är rätt: de har ingen versalform. ]]
local GEMENA_VERSALER = {
	["å"] = "Å", ["ä"] = "Ä", ["ö"] = "Ö",
	["é"] = "É", ["è"] = "È", ["ü"] = "Ü", ["á"] = "Á",
}

local function versaler(txt: string): string
	local ut = string.upper(txt)
	for gemen, versal in GEMENA_VERSALER do
		ut = string.gsub(ut, gemen, versal)
	end
	return ut
end

local INFO_IN = TweenInfo.new(FADE, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local INFO_UT = TweenInfo.new(FADE, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local forlader: Instance? = nil
local ram: Frame? = nil
local malEtikett: TextLabel? = nil
local detaljEtikett: TextLabel? = nil
local stroke: UIStroke? = nil
local ytsignal: RBXScriptConnection? = nil

--[[ Tweens som fortfarande kan skriva på genomskinligheten. De avbryts av
	nästa `Show` och av `Hide`; utan det hade en utton som startat före ett
	nytt `Show` fortsatt tona ned den NYA texten. ]]
local levande: { Tween } = {}

--[[ Lifecyclen. `fas` är det enda tillståndet, och `steg` är det enda som
	flyttar den. ]]
local fas = "dold"                                 -- dold · in · kvar · ut
local kvarTid = 0
local fastid = 0

local function slapp()
	for _, t in levande do
		--[[ Bänkens TweenService är en stub; produktionens `Cancel` finns
		     alltid, men ett vaktat anrop kostar ingenting och gör modulen
		     körbar i en bank som bara stubbar `Play`. ]]
		local avbryt = (t :: any).Cancel
		if avbryt then avbryt(t) end
	end
	table.clear(levande)
end

local function tona(info: TweenInfo, ramT: number, strokeT: number, textT: number)
	local r, m, d, s = ram, malEtikett, detaljEtikett, stroke
	if not r or not m or not d or not s then return end
	local function starta(objekt: Instance, mal: { [string]: any })
		local t = TweenService:Create(objekt, info, mal)
		table.insert(levande, t)
		t:Play()
	end
	starta(r, { BackgroundTransparency = ramT })
	starta(s, { Transparency = strokeT })
	starta(m, { TextTransparency = textT })
	starta(d, { TextTransparency = textT })
end

--[[ Sätter genomskinligheten direkt, utan tween. Används som STARTLÄGE för
	en intoning och som slutläge när bannern släcks — bänken har ingen
	riktig tween, och produktionen ska inte heller vara beroende av att en
	tween hinner köra för att hamna rätt. ]]
local function satt(ramT: number, strokeT: number, textT: number)
	local r, m, d, s = ram, malEtikett, detaljEtikett, stroke
	if not r or not m or not d or not s then return end
	r.BackgroundTransparency = ramT
	s.Transparency = strokeT
	m.TextTransparency = textT
	d.TextTransparency = textT
end

--[[ ── UTLÄGGNINGEN ────────────────────────────────────────────────────

	42 % av bredden är kontraktets tal för en stor skärm, och det är
	uttryckligen inte ett tillräckligt mobilkontrakt. Golvet och taket
	nedan är därför inte dekoration: de är det som gör talet användbart på
	en telefon respektive på en 4K-skärm.

	Räknat på de skärmar kanonen redan provar mot:

	    1920 x 1080  PC          0,42 → 806  → taket 560
	    1376 x 1032  iPad Pro    0,42 → 578  → taket 560
	    1080 x  810  iPad 9      0,42 → 454
	     810 x 1080  iPad porträtt 0,42 → 340
	     844 x  390  iPhone 13   0,42 → 354
	     390 x  844  iPhone port. 0,42 → 164  → golvet 300
	     320 x  568  liten tel.  0,42 → 134  → 0,92·320 = 294

	Sista raden är varför golvet i sin tur är begränsat av `SIDLUFT`: en
	banner får aldrig bli bredare än skärmen för att golvet säger så. ]]
local function bredden(W: number): number
	local golv = math.min(SIDLUFT * W, MIN_BREDD)
	return math.clamp(ANDEL * W, golv, MAX_BREDD)
end

local function laggUt()
	local r = ram
	if not r then return end
	local f = forlader :: any
	local W = if f and f.AbsoluteSize then f.AbsoluteSize.X else 0
	if W <= 0 then return end
	r.Size = UDim2.new(0, math.floor(bredden(W)), 0, HOJD)
end

--[[ Provets fönster in: lägg ut igen utan att visa något nytt. ]]
function CoachBanner._laggUt()
	laggUt()
end

--[[ ── BYGGET ─────────────────────────────────────────────────────────
	Två rader i en vertikal `UIListLayout`. Båda raderna har fast höjd och
	`TextTruncate`, vilket är det som håller kontraktets strikta 52 px: en
	rad som får radbryta hade vuxit ramen i stället för att kapa texten,
	och då flyttar layouten sig under spelaren mitt i en ritt. ]]
local function rad(namn: string, ordning: number, font: Enum.Font, storlek: number,
	farg: Color3): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = namn
	l.LayoutOrder = ordning
	l.Size = UDim2.new(1, 0, 0, 17)
	l.BackgroundTransparency = 1
	l.Font = font
	l.TextSize = storlek
	l.TextColor3 = farg
	l.TextXAlignment = Enum.TextXAlignment.Center
	l.TextWrapped = false
	l.TextTruncate = Enum.TextTruncate.AtEnd
	l.RichText = false
	l.Text = ""
	l.ZIndex = 8
	return l
end

--[[ Monterar bannern i en befintlig yta. Kontraktet förbjuder en andra
	ScreenGui, så modulen skapar ingen: den som äger lektionens yta lämnar
	den hit. Ett andra anrop med samma förälder är en no-op; med en NY
	förälder rivs den gamla bannern först, så att en respawn inte kan lämna
	två. ]]
function CoachBanner.montera(mor: Instance?)
	if not mor then return end
	if ram and forlader == mor then return end
	CoachBanner.Destroy()
	forlader = mor

	local r = Instance.new("Frame")
	r.Name = "CoachBanner"
	r.AnchorPoint = Vector2.new(0.5, 0)
	r.Position = UDim2.new(0.5, 0, 0, TOPP)
	r.Size = UDim2.new(0, MIN_BREDD, 0, HOJD)
	r.BackgroundColor3 = RAM_FARG
	r.BackgroundTransparency = 1
	r.BorderSizePixel = 0
	r.Visible = false
	r.ZIndex = 7
	local horn = Instance.new("UICorner")
	horn.CornerRadius = UDim.new(0, 10)
	horn.Parent = r
	local kant = Instance.new("UIStroke")
	kant.Color = Color3.fromRGB(255, 255, 255)
	kant.Thickness = 1
	kant.Transparency = 1
	kant.Parent = r
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 8)
	pad.PaddingBottom = UDim.new(0, 8)
	pad.PaddingLeft = UDim.new(0, 14)
	pad.PaddingRight = UDim.new(0, 14)
	pad.Parent = r
	local lista = Instance.new("UIListLayout")
	lista.FillDirection = Enum.FillDirection.Vertical
	lista.Padding = UDim.new(0, 2)
	lista.SortOrder = Enum.SortOrder.LayoutOrder
	lista.HorizontalAlignment = Enum.HorizontalAlignment.Center
	lista.Parent = r

	local m = rad("GoalLabel", 1, Enum.Font.GothamBold, 13, MAL_FARG)
	m.Parent = r
	local d = rad("InstructionLabel", 2, Enum.Font.Gotham, 12, DETALJ_FARG)
	d.Parent = r

	r.Parent = mor
	ram, malEtikett, detaljEtikett, stroke = r, m, d, kant

	--[[ Vridning, delad skärm och fönsterändring. Samma skäl som
	     `UgnetaController` har för sin knapprad: bredden räknas ur ytan, och
	     en yta som ändrar storlek utan omräkning lämnar bannern i gammal
	     geometri. ]]
	local f = mor :: any
	if f.GetPropertyChangedSignal then
		ytsignal = f:GetPropertyChangedSignal("AbsoluteSize"):Connect(laggUt)
	end
	laggUt()
end

--[[ ── VISNINGEN ──────────────────────────────────────────────────────

	`Show` är atomisk: texten skrivs, tiden förnyas och gamla tweens
	avbryts i samma anrop. Den blinkar aldrig — en banner som redan står
	uppe sätts INTE till `Visible = false` först, den byter bara text. ]]
function CoachBanner.Show(mal: string, detalj: string, duration: number?)
	local r, m, d = ram, malEtikett, detaljEtikett
	if not r or not m or not d then return end
	slapp()
	--[[ Målet i versaler, instruktionen som den är. Se noten vid
	     `versaler` — Roblox har ingen egenskap som gör det åt oss. ]]
	m.Text = versaler(mal or "")
	d.Text = detalj or ""
	kvarTid = duration or STANDARD_TID
	laggUt()

	if fas == "dold" then
		--[[ Helt genomskinlig först, sedan in. Ordningen är viktig: sattes
		     `Visible` efter tweenens start hade första bildrutan visat den
		     fullt tänd. ]]
		satt(1, 1, 1)
		r.Visible = true
		fas = "in"
		fastid = FADE
		tona(INFO_IN, RAM_TRANSPARENS, STROKE_TRANSPARENS, 0)
	else
		--[[ Stod den redan uppe — eller höll på att tona ut — tas den
		     tillbaka till fullt läge och tiden börjar om. ]]
		satt(RAM_TRANSPARENS, STROKE_TRANSPARENS, 0)
		r.Visible = true
		fas = "kvar"
		fastid = 0
	end
end

--[[ #264 GAIT_READABILITY_AND_UGNETA: ramen, så att värden kan flytta den
     in i en dold behållare medan Ugnetas yta uppe till höger visar texten. ]]
function CoachBanner.ram(): Frame?
	return ram
end

--[[ Skriver om texten UTAN att visa bannern eller förnya tiden. Ett
     språkbyte ska översätta det som står — inte ta fram en utmattad banner
     igen. ]]
function CoachBanner.skrivTyst(mal: string, detalj: string)
	local m, d = malEtikett, detaljEtikett
	if not m or not d then return end
	m.Text = versaler(mal)
	d.Text = detalj
end

--[[ Släcker direkt och kastar tiden. Det här är säkerhetsvägen:
	avsittning, lektionsavbrott och respawn ska inte lämna en text som
	handlar om en häst spelaren inte sitter på längre. ]]
function CoachBanner.Hide()
	slapp()
	local r = ram
	if r then
		r.Visible = false
		satt(1, 1, 1)
	end
	fas = "dold"
	kvarTid = 0
	fastid = 0
end

--[[ Städvägen. Efter den finns ingen banner, ingen signal och inget
	tillstånd kvar — `montera` måste köras igen. ]]
function CoachBanner.Destroy()
	slapp()
	local s = ytsignal
	if s then s:Disconnect() end
	ytsignal = nil
	local r = ram
	if r then r:Destroy() end
	ram, malEtikett, detaljEtikett, stroke = nil, nil, nil, nil
	forlader = nil
	fas = "dold"
	kvarTid = 0
	fastid = 0
end

--[[ ETT STEG. Anropas ur klientens enda uppdateringsloop, via
	`UgnetaController.steg`. Det är här visningstiden faktiskt går. ]]
function CoachBanner.steg(dt: number)
	if fas == "dold" then return end
	if fas == "in" then
		fastid -= dt
		if fastid <= 0 then fas = "kvar" end
		return
	end
	if fas == "kvar" then
		kvarTid -= dt
		if kvarTid <= 0 then
			fas = "ut"
			fastid = FADE
			tona(INFO_UT, 1, 1, 1)
		end
		return
	end
	--[[ fas == "ut" ]]
	fastid -= dt
	if fastid <= 0 then
		slapp()
		local r = ram
		if r then
			r.Visible = false
			satt(1, 1, 1)
		end
		fas = "dold"
	end
end

--[[ ── Provets avläsningar ───────────────────────────────────────────── ]]

function CoachBanner.synlig(): boolean
	local r = ram
	return r ~= nil and r.Visible == true
end

function CoachBanner.text(): (string, string)
	local m, d = malEtikett, detaljEtikett
	return if m then m.Text else "", if d then d.Text else ""
end

function CoachBanner.fas(): string
	return fas
end

function CoachBanner.kvar(): number
	return kvarTid
end

--[[ Talen ur kontraktet, för den spec som mäter dem mot beställningen. ]]
CoachBanner.FADE = FADE
CoachBanner.STANDARD_TID = STANDARD_TID
CoachBanner.HOJD = HOJD
CoachBanner.TOPP = TOPP
CoachBanner.bredden = bredden
--[[ Versalregeln är en RENDERINGSregel, och provet ska kunna mäta den mot
     kanonens egen rubrik i stället för att skriva av resultatet. ]]
CoachBanner.versaler = versaler

return CoachBanner
