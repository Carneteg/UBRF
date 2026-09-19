--!nostrict
--[[ EFTER PASSET — DET VISUELLA DELKONTRAKTET I #234, MÄTT.

	Delkontraktet 2026-09-19 beskriver `ShowPostRideSummary()` zon för zon:
	den lila panelen med guldram, 1–2 mätare i tre lager, Ugnetas kursiva
	kommentar, NoteBoxen ur Ridhandboken och en chunky knapp tillbaka till
	stallet. Den här specen mäter det, plus huvudkontraktets punkt 8 och
	12:

	   8. sammanfattningen öppnas exakt en gång vid giltig dismount och
	      aldrig vid ogiltig exit,
	  12. fallback-loggen håller accepterade telefon-/iPad-/desktop-
	      reservzoner.

	TVÅ NIVÅER, samma skäl som i `ugneta-tema.spec`: layouten och
	valideringen provas mot de RENA funktionerna, och lifecyclen provas
	genom `init.client.luau` och dess `MountChanged`.

	GRÄNSEN, uttalad: bänken är inte en klient. Ingenting här säger hur
	rutan SER UT i Studio, hur guldramen läser mot det lila eller hur
	knappen känns under en tumme. Det är Tobias human gate.

	Kör: python3 roblox/tests/build.py tests/ugneta-summering.spec.luau
	     && luau roblox/tests/.build/ugneta-summering.spec.luau
]]

local fel = 0
local function prova(vad, ok, detalj)
	if ok then
		print(("  OK   %s%s"):format(vad, if detalj then " " .. detalj else ""))
	else
		fel += 1
		print(("  FEL  %s%s"):format(vad, if detalj then " " .. detalj else ""))
	end
end

print("\nEFTER PASSET — DET VISUELLA DELKONTRAKTET (#234)\n")

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local player = Players.LocalPlayer
local Net = Networking

--[[ `Color3.R` är 0–1 i Roblox, kontraktet talar i 0–255. Provet räknar
     tillbaka i stället för att jämföra mot en bråkdel — samma hjälpare och
     samma skäl som `coachbanner.spec`. ]]
local function rgb(f)
	if not f then return -1, -1, -1 end
	local function b(x) return math.floor((x or 0) * 255 + 0.5) end
	return b(f.R), b(f.G), b(f.B)
end
local function arFarg(f, r, g, b)
	local fr, fg, fb = rgb(f)
	return fr == r and fg == g and fb == b
end

local gui = player._gui
local function sokI(rot, namn)
	if type(rot) ~= "table" then return nil end
	if rot.Name == namn then return rot end
	for _, b in ipairs(rot._barn or {}) do
		local t = sokI(b, namn)
		if t then return t end
	end
	return nil
end
local function rakna(namn)
	local n = 0
	local function sok(nod)
		if type(nod) ~= "table" then return end
		if nod.Name == namn then n += 1 end
		for _, b in ipairs(nod._barn or {}) do sok(b) end
	end
	sok(gui)
	return n
end
local function hitta(namn)
	return sokI(sokI(gui, "UBRFUgneta"), namn)
end

UgnetaController.start()

--[[ En giltig kontraktstabell. Provet muterar kopior av den; originalet
     står kvar som referens på vad vyn SKA klara. ]]
local function data(over)
	local d = {
		telemetri = {
			{ etikett = "Hästen slappnar av", varde = 0.62, orsak = "dagsform" },
			{ etikett = "Din mjukhet", varde = 0.41, orsak = "ryttare" },
		},
		ugnetaKommentar = "Du tar i lite för hårt. Korta tag, och ge efter emellan.",
		teoriText = {
			overRubrik = "UR RIDHANDBOKEN",
			karnregel = "Tygeltag är korta — aldrig hängande.",
			brodtext = "Handen hör till en mjuk och jämn förbindelse.",
		},
		knappText = "Tillbaka till stallet",
	}
	for k, v in (over or {}) do d[k] = v end
	return d
end

--[[ ══ 1. MAINFRAME ═══════════════════════════════════════════════════ ]]
print("── 1. MainFrame ──")
do
	UgnetaController.ShowPostRideSummary(data())
	local p = hitta("PostRideSummary")
	prova("panelen finns i lektionens egen yta — ingen andra ScreenGui",
		p ~= nil and rakna("UBRFUgneta") == 1,
		("(%d st UBRFUgneta)"):format(rakna("UBRFUgneta")))
	prova("bakgrunden är kontraktets lila 138,59,212",
		p ~= nil and arFarg(p.BackgroundColor3, 138, 59, 212),
		("(%d,%d,%d)"):format(rgb(p and p.BackgroundColor3)))
	local stroke = p and sokI(p, "Guldram")
	--[[ `rgb` lämnar TRE värden, och ett flervärdesanrop mitt i en
	     argumentlista trunkeras till ett. Därför plockas de ut först. ]]
	local sr, sg, sb = rgb(stroke and stroke.Color)
	prova("guldramen är 246,196,69 och 4 px",
		stroke ~= nil and arFarg(stroke.Color, 246, 196, 69)
			and stroke.Thickness == PostRideSummary.RAM_PX,
		("(%d,%d,%d · %s px)"):format(sr, sg, sb,
			tostring(stroke and stroke.Thickness)))
	local horn = p and p:FindFirstChildOfClass("UICorner")
	prova("hörnradien är 22 px",
		horn ~= nil and horn.CornerRadius.Offset == 22,
		("(%s px)"):format(tostring(horn and horn.CornerRadius.Offset)))
	prova("och den är centrerad, inte ankrad i en kant",
		p ~= nil and p.AnchorPoint.X == 0.5 and p.AnchorPoint.Y == 0.5)
end

--[[ ══ 2. ZON 1 — RESULTATET ═════════════════════════════════════════ ]]
print("\n── 2. Mätarna: tre lager, klampad progress ──")
do
	local matare = PostRideSummary.matare()
	prova("två mätare byggdes", #matare == 2, ("(%d)"):format(#matare))
	local m = matare[1]
	prova("mätaren har spår, fyllning och glans — tre lager",
		m ~= nil and sokI(m.ram, "Spar") ~= nil and m.fyll ~= nil
			and m.glans ~= nil)
	prova("glansen är BARN till fyllningen och full bredd i skala",
		m ~= nil and m.glans.Parent == m.fyll
			and m.glans.Size.X.Scale == 1 and m.glans.Size.X.Offset == 0,
		("(förälder %s · X %s+%s)"):format(
			m and m.glans.Parent and m.glans.Parent.Name or "-",
			tostring(m and m.glans.Size.X.Scale),
			tostring(m and m.glans.Size.X.Offset)))
	prova("spåret klipper — fyllningen kan inte rita utanför sin ram",
		m ~= nil and sokI(m.ram, "Spar").ClipsDescendants == true)
	prova("etiketterna kommer ur tabellen",
		matare[1].etikett.Text == "Hästen slappnar av"
			and matare[2].etikett.Text == "Din mjukhet",
		('("%s" / "%s")'):format(matare[1].etikett.Text, matare[2].etikett.Text))
end

--[[ Fyllningens MÅL, oavsett om den tonas dit eller sätts direkt.
     `TweenService` i bänken spelar ingen tween — den bokför den — så en
     mätning som läser `Size` direkt hade läst startläget noll och kallat
     det "klampat". Hjälparen läser därför det tween som SENAST skapades
     för fyllningen, och faller tillbaka på den satta storleken. ]]
local function fyllMal(m)
	for i = #__tweens, 1, -1 do
		local tw = __tweens[i]
		if tw.Instance == m.fyll and tw._mal and tw._mal.Size then
			return tw._mal.Size.X.Scale
		end
	end
	return m.fyll.Size.X.Scale
end

print("\n── Noll, fullt, över och under ──")
do
	--[[ REDUCERAD RÖRELSE PÅ: mätarna sätts då direkt i stället för att
	     tonas, vilket gör klampningen deterministisk att mäta OCH provar
	     reduced-motion-kontraktet i samma andetag. Tonat läge mäts för sig
	     längre ned. ]]
	GuiService.ReducedMotionEnabled = true
	UgnetaController.ShowPostRideSummary(data({
		telemetri = {
			{ etikett = "Under noll", varde = -4 },
			{ etikett = "Över ett", varde = 17.5 },
		},
	}))
	local m = PostRideSummary.matare()
	prova("progress under 0 klampas till noll",
		m[1].fyll.Size.X.Scale == 0, ("(%s)"):format(tostring(m[1].fyll.Size.X.Scale)))
	prova("progress över 1 klampas till ett",
		m[2].fyll.Size.X.Scale == 1, ("(%s)"):format(tostring(m[2].fyll.Size.X.Scale)))

	UgnetaController.ShowPostRideSummary(data({
		telemetri = { { etikett = "Saknat värde" } },
	}))
	m = PostRideSummary.matare()
	prova("ett saknat värde är noll, inte ett runtimefel",
		m[1].fyll.Size.X.Scale == 0 and m[1].ram.Visible == true)
	prova("och den andra mätaren är dold när bara en rad finns",
		m[2].ram.Visible == false)

	UgnetaController.ShowPostRideSummary(data({ telemetri = {} }))
	m = PostRideSummary.matare()
	prova("noll mätare döljer båda raderna",
		m[1].ram.Visible == false and m[2].ram.Visible == false)
	prova("och panelen står ändå kvar med kommentar och teori",
		PostRideSummary.oppen() == true)

	--[[ NaN får inte smyga igenom klampningen: `math.clamp` på NaN svarar
	     NaN, och en NaN-bredd är en osynlig mätare ingen kan förklara. ]]
	UgnetaController.ShowPostRideSummary(data({
		telemetri = { { etikett = "NaN", varde = 0 / 0 } },
	}))
	m = PostRideSummary.matare()
	prova("NaN blir noll, inte NaN", m[1].fyll.Size.X.Scale == 0,
		("(%s)"):format(tostring(m[1].fyll.Size.X.Scale)))
	GuiService.ReducedMotionEnabled = false
end

print("\n── ...och med rörelse på tonas de dit ──")
do
	table.clear(__tweens)
	UgnetaController.ShowPostRideSummary(data({
		telemetri = {
			{ etikett = "Tonas", varde = 0.75 },
			{ etikett = "Över ett", varde = 17.5 },
		},
	}))
	local m = PostRideSummary.matare()
	prova("fyllningen startar på noll — den ärver inte förra passets bredd",
		m[1].fyll.Size.X.Scale == 0,
		("(%s)"):format(tostring(m[1].fyll.Size.X.Scale)))
	prova("och tonas mot sitt mål", math.abs(fyllMal(m[1]) - 0.75) < 1e-6,
		("(%s)"):format(tostring(fyllMal(m[1]))))
	prova("även tonat klampas ett omöjligt värde till ett",
		fyllMal(m[2]) == 1, ("(%s)"):format(tostring(fyllMal(m[2]))))
	local tid = nil
	for i = #__tweens, 1, -1 do
		if __tweens[i].Instance == m[1].fyll then
			tid = __tweens[i].TweenInfo.Time
			break
		end
	end
	prova("toningen har en rimlig tid, inte ett hopp",
		tid ~= nil and tid > 0.1 and tid < 1.0,
		("(%s s)"):format(tostring(tid)))
end

--[[ ══ 3 och 4. KOMMENTAREN OCH NOTEBOXEN ═══════════════════════════ ]]
print("\n── 3/4. Kommentaren och Markus Ridhandbok ──")
do
	UgnetaController.ShowPostRideSummary(data())
	local kommentar, rubrik, regel, brod = PostRideSummary.text()
	prova("Ugnetas kommentar står i vyn", kommentar ~= "" ,
		('("%s")'):format(kommentar))
	local kt = hitta("UgnetaKommentar")
	prova("den är kursiv genom FontFace — Enum.Font har ingen kursiv Gotham",
		kt ~= nil and kt.FontFace ~= nil
			and kt.FontFace.Style == Enum.FontStyle.Italic,
		("(%s)"):format(tostring(kt and kt.FontFace and kt.FontFace.Style)))
	prova("och den radbryter i stället för att svämma över",
		kt ~= nil and kt.TextWrapped == true)
	prova("ingen RichText från nätverksdata",
		kt ~= nil and kt.RichText == false)

	prova("NoteBoxen har krämvit botten",
		arFarg(hitta("NoteBox").BackgroundColor3, 245, 239, 224),
		("(%d,%d,%d)"):format(rgb(hitta("NoteBox").BackgroundColor3)))
	local rand = hitta("Vansterrand")
	prova("och EN 4 px guldrand, bara till vänster",
		rand ~= nil and rand.Size.X.Offset == 4 and rand.Size.Y.Scale == 1
			and rand.Position.X.Offset == 0
			and arFarg(rand.BackgroundColor3, 246, 196, 69),
		("(%s px vid x %s)"):format(tostring(rand and rand.Size.X.Offset),
			tostring(rand and rand.Position.X.Offset)))
	prova("ingen konkurrerande ram runt NoteBoxen",
		hitta("NoteBox"):FindFirstChildOfClass("UIStroke") == nil)
	prova("innehållet står i ordning: överrubrik, kärnregel, brödtext",
		rubrik == "UR RIDHANDBOKEN" and regel ~= "" and brod ~= "",
		('("%s" · "%s")'):format(rubrik, regel))
	prova("brödtexten radbryter",
		hitta("Brodtext").TextWrapped == true)
end

print("\n── Saknad och trasig data ger en trygg reserv ──")
do
	UgnetaController.ShowPostRideSummary({})
	prova("en tom tabell ger ingen krasch och ingen panel med skräp",
		PostRideSummary.oppen() == true)
	local kommentar, rubrik, regel = PostRideSummary.text()
	prova("utan kommentar står fältet tomt och zonen döljs",
		kommentar == "" and hitta("Kommentar").Visible == false,
		('("%s")'):format(kommentar))
	prova("utan teori döljs NoteBoxen i stället för att stå tom",
		regel == "" and hitta("NoteBox").Visible == false)

	UgnetaController.ShowPostRideSummary(data({
		ugnetaKommentar = 42,
		teoriText = "inte en tabell",
		telemetri = "inte en lista",
	}))
	prova("fel TYP på varje fält ger inte heller ett runtimefel",
		PostRideSummary.oppen() == true)
	local k2 = select(1, PostRideSummary.text())
	prova("ett tal där text ska stå blir tomt, inte \"42\"", k2 == "",
		('("%s")'):format(k2))
end

print("\n── Mycket lång svensk text ──")
do
	local lang = string.rep("Mjukare hand i vändningen, och håll kontakten. ", 40)
	UgnetaController.ShowPostRideSummary(data({
		ugnetaKommentar = lang,
		teoriText = { overRubrik = lang, karnregel = lang, brodtext = lang },
	}))
	local kommentar, rubrik, regel, brod = PostRideSummary.text()
	prova("kommentaren kortas till kontraktets gräns",
		utf8.len(kommentar) <= PostRideSummary.MAX_KOMMENTAR + 1,
		("(%d av %d tecken)"):format(utf8.len(kommentar), PostRideSummary.MAX_KOMMENTAR))
	prova("brödtexten likaså",
		utf8.len(brod) <= PostRideSummary.MAX_BROD + 1,
		("(%d av %d)"):format(utf8.len(brod), PostRideSummary.MAX_BROD))
	prova("och de korta raderna likaså",
		utf8.len(rubrik) <= PostRideSummary.MAX_KORT + 1
			and utf8.len(regel) <= PostRideSummary.MAX_KORT + 1,
		("(%d / %d av %d)"):format(utf8.len(rubrik), utf8.len(regel),
			PostRideSummary.MAX_KORT))
	prova("kapningen sker på ett TECKEN — ingen trasig UTF-8",
		utf8.len(kommentar) ~= nil and utf8.len(brod) ~= nil)
	prova("zonerna klipper, så en lång rad kan inte nå nästa zon",
		hitta("Kommentar").ClipsDescendants == true
			and hitta("NoteBox").ClipsDescendants == true)

	--[[ FALSIFIERING: utan gränsen går texten igenom rå. ]]
	local langd = utf8.len(lang)
	prova("MUTATION-KONTROLL: rådata var mycket längre än gränsen",
		langd > PostRideSummary.MAX_KOMMENTAR * 4,
		("(%d tecken in, %d ut)"):format(langd, utf8.len(kommentar)))
end

--[[ ══ 5. KNAPPEN ════════════════════════════════════════════════════ ]]
print("\n── 5. Tillbaka till stallet ──")
do
	UgnetaController.ShowPostRideSummary(data())
	local kn = PostRideSummary.knapp()
	local box = hitta("KnappBox")
	local skugga = hitta("Skugga")
	prova("knappen är en riktig TextButton med Activated",
		kn ~= nil and kn.ClassName == "TextButton" and kn.Activated ~= nil)
	prova("den bär kontraktets text", kn.Text == "Tillbaka till stallet",
		('("%s")'):format(kn.Text))
	prova("den är valbar med gamepad", kn.Selectable == true)
	prova("och gamepadens fokus pekar på den medan rutan är uppe",
		GuiService.SelectedObject == kn)
	prova("skuggan är 6 px förskjuten",
		skugga ~= nil and skugga.Position.X.Offset == PostRideSummary.SKUGGA_PX
			and skugga.Position.Y.Offset == PostRideSummary.SKUGGA_PX,
		("(%s,%s px)"):format(tostring(skugga and skugga.Position.X.Offset),
			tostring(skugga and skugga.Position.Y.Offset)))
	--[[ SKUGGAN FÅR INTE FLYTTA HITBOXEN. Den är ett SYSKON i behållaren,
	     inte ett barn till knappen och inte en egen rad i listan: knappen
	     ligger i 0,0 och fyller behållaren, och behållaren är det layouten
	     mäter. ]]
	prova("men den flyttar inte knappens hitbox",
		kn.Position.X.Offset == 0 and kn.Position.Y.Offset == 0
			and kn.Size.X.Scale == 1 and kn.Size.Y.Scale == 1)
	prova("och den skiftar inte layouten — behållaren är knappens storlek",
		box ~= nil and box.Size.X.Scale == 1
			and skugga.Parent == box and skugga.LayoutOrder == nil,
		("(box %s · skugga i %s)"):format(tostring(box and box.Size.X.Scale),
			tostring(skugga and skugga.Parent and skugga.Parent.Name)))

	--[[ DEBOUNCE: ett tryck ger exakt en stängningsavsikt. ]]
	local stangda = 0
	PostRideSummary.vidStang(function() stangda += 1 end)
	kn.Activated:Fire()
	kn.Activated:Fire()
	kn.Activated:Fire()
	prova("tre snabba tryck ger EN stängning", stangda == 1,
		("(%d)"):format(stangda))
	prova("och rutan är stängd", PostRideSummary.oppen() == false)
	prova("den lämnar ingen osynlig inputblockerare",
		hitta("PostRideSummary").Visible == false)
	prova("och gamepadens fokus lämnas tillbaka",
		GuiService.SelectedObject == nil,
		("(%s)"):format(tostring(GuiService.SelectedObject)))
	--[[ Och den går att öppna igen: en debounce som fastnar hade sett
	     likadan ut i mätningen ovan. ]]
	UgnetaController.ShowPostRideSummary(data())
	prova("nästa pass kan öppna rutan igen", PostRideSummary.oppen() == true)
	PostRideSummary.vidStang(nil)
end

--[[ ══ 6. LIVSCYKELN ═════════════════════════════════════════════════ ]]
print("\n── 6. En panel, hur många anrop som helst ──")
do
	for _ = 1, 8 do UgnetaController.ShowPostRideSummary(data()) end
	prova("åtta anrop ger EN MainFrame", rakna("PostRideSummary") == 1,
		("(%d)"):format(rakna("PostRideSummary")))
	prova("och EN stängningsknapp", rakna("TillbakaTillStallet") == 1,
		("(%d)"):format(rakna("TillbakaTillStallet")))
	prova("och fortfarande EN lektionsyta", rakna("UBRFUgneta") == 1)

	--[[ IDEMPOTENS: samma data igen byter inget, och rutan blinkar inte. ]]
	local fore = PostRideSummary.text()
	UgnetaController.ShowPostRideSummary(data())
	prova("samma passhändelse igen är idempotent",
		PostRideSummary.text() == fore and PostRideSummary.oppen() == true)

	--[[ INGEN GAMMAL DATA. Ett nytt innehåll skriver över det gamla helt. ]]
	UgnetaController.ShowPostRideSummary(data({
		telemetri = { { etikett = "Bara en rad", varde = 1 } },
		ugnetaKommentar = "Ny kommentar.",
	}))
	local m = PostRideSummary.matare()
	prova("nytt innehåll lämnar inget kvar av det gamla",
		m[1].etikett.Text == "Bara en rad" and m[2].ram.Visible == false
			and select(1, PostRideSummary.text()) == "Ny kommentar.",
		('("%s" · rad 2 %s)'):format(m[1].etikett.Text, tostring(m[2].ram.Visible)))
end

print("\n── Klienten kan inte skapa progression ur visningsdata ──")
do
	local intentFore = #Net.get("RidingIntent")._skickat
	local syncFore = #Net.get("StateSync")._skickat
	UgnetaController.ShowPostRideSummary(data({
		telemetri = {
			{ etikett = "XP", varde = 9999 },
			{ etikett = "Nivå", varde = 4242 },
		},
	}))
	local m = PostRideSummary.matare()
	prova("manipulerade värden blir en full mätare, inte ett betyg",
		fyllMal(m[1]) == 1 and fyllMal(m[2]) == 1,
		("(%s / %s)"):format(tostring(fyllMal(m[1])), tostring(fyllMal(m[2]))))
	prova("och ingenting skickades till servern",
		#Net.get("RidingIntent")._skickat == intentFore
			and #Net.get("StateSync")._skickat == syncFore,
		("(intent %d · sync %d)"):format(#Net.get("RidingIntent")._skickat,
			#Net.get("StateSync")._skickat))
	PostRideSummary.stang()
end

--[[ ══ LAYOUTEN PÅ RIKTIGA YTOR ═══════════════════════════════════════

	`PostRideSummary.layout` är ren och går att prova mot en viewport utan
	att något ritas — samma disciplin som `ReplayController.radLayout`.
	Golvet är att panelen ryms innanför 94 % av höjden OCH att knappen är
	med i den höjden: en stängningsknapp utanför bild är inte en
	designdetalj, det är hela vägen ut ur rutan. ]]
print("\n── Panelen ryms på telefon, iPad och PC ──")
do
	--[[ GUI-ytan är viewporten minus topbarens 36 px, precis som
	     `TouchControls` räknar den. ]]
	local YTOR = {
		{ namn = "iPhone 13 landskap", W = 844, H = 354 },
		{ namn = "liten telefon landskap", W = 568, H = 284 },
		{ namn = "iPhone porträtt", W = 390, H = 808 },
		{ namn = "iPad 9 landskap", W = 1080, H = 774 },
		{ namn = "iPad Pro landskap", W = 1376, H = 996 },
		{ namn = "PC 1080p", W = 1920, H = 1044 },
	}
	for _, y in YTOR do
		for antal = 0, 2 do
			local L = PostRideSummary.layout(y.W, y.H, antal)
			local ryms = L.hojd <= math.floor(0.94 * y.H) + 1
				and L.bredd <= math.floor(0.92 * y.W) + 1
				and L.knapp >= 28 and L.skala > 0.60
			prova(("%s, %d mätare"):format(y.namn, antal), ryms,
				("(%dx%d px · skala %.2f · knapp %.0f px)"):format(L.bredd,
					L.hojd, L.skala, L.knapp))
		end
	end
end

--[[ ══ 12. RESERVLOGGEN OCH RESERVZONERNA ════════════════════════════

	Loggen bor i VÄNSTERBANDET: `TouchControls` blickyta börjar på 34 % av
	bredden, så vänstra tredjedelen är det enda som varken kameran eller
	gångartsknapparna gör anspråk på. Den ligger dessutom under bannern och
	ovanför spaken. Talen räknas, de antas inte. ]]
print("\n── 12. Reservloggen håller sina zoner ──")
do
	local YTOR = {
		{ namn = "PC utan pekreglage", W = 1920, H = 1044, spak = math.huge },
		{ namn = "iPad Pro landskap", W = 1376, H = 996, spak = 828 },
		{ namn = "iPhone 13 landskap", W = 844, H = 354, spak = 209 },
		{ namn = "liten telefon landskap", W = 568, H = 284, spak = 168 },
	}
	for _, y in YTOR do
		local L = UgnetaBubbla.loggLayout(y.W, y.H, y.spak)
		local underBannern = L.y >= CoachBanner.TOPP + CoachBanner.HOJD
		local ovanforSpaken = L.y + L.hojd <= math.min(y.spak, y.H)
		local iVansterbandet = L.x + L.bredd <= 0.34 * y.W + 1
		prova(("%s: %d rader"):format(y.namn, L.rader),
			L.rader >= 1 and underBannern and ovanforSpaken and iVansterbandet,
			("(x %d..%d av %.0f · y %d..%d, spaken vid %s)"):format(L.x,
				L.x + L.bredd, 0.34 * y.W, L.y, L.y + L.hojd,
				if y.spak == math.huge then "—" else tostring(y.spak)))
	end

	--[[ FALSIFIERING: pressas spaken upp i loggens band ska antalet rader
	     KRYMPA. Gör det inte det är "ovanför spaken" inte en mätning. ]]
	local tre = UgnetaBubbla.loggLayout(844, 354, 209).rader
	local en = UgnetaBubbla.loggLayout(844, 354, 140).rader
	prova("MUTATION: en högre spak trycker ihop loggen", en < tre,
		("(%d rader -> %d)"):format(tre, en))
	local ingen = UgnetaBubbla.loggLayout(844, 354, 100).rader
	prova("och når spaken ända upp i bannerns band ritas ingen logg alls",
		ingen == 0, ("(%d rader)"):format(ingen))
end

--[[ ══ 8. ÖPPNAS EXAKT EN GÅNG, VID GILTIG AVSITTNING ════════════════

	Genom produktionens egen väg: `MountChanged`, RenderStepped, knappen
	och `CharacterRemoving` — inte genom direktanrop av controllern. Det är
	skillnaden mellan att prova att funktionen finns och att prova att
	spelaren får den. ]]
print("\n── 8. Rutan vid giltig avsittning, aldrig vid ogiltig ──")
do
	PostRideSummary.stang()
	local ridhus
	do
		local anlaggning = Instance.new("Folder")
		anlaggning.Name = "Anläggning"
		anlaggning.Parent = workspace
		ridhus = Instance.new("Model")
		ridhus.Name = "UBRF"
		ridhus.Parent = anlaggning
		local bana = Instance.new("Part")
		bana.Name = "Ridbanan"
		bana.Size = Vector3.new(60, 0.18, 196)
		bana.Position = Vector3.new(0, 0, 98)
		bana.Parent = ridhus
		local syd = Instance.new("Part")
		syd.Name = "Sarg syd"
		syd.Size = Vector3.new(60, 4, 0.3)
		syd.Position = Vector3.new(0, 0, 0)
		syd.Parent = ridhus
	end

	local hast = __makeHastModell("Bamse")
	hast.Parent = workspace
	local dt = 1 / 30

	--[[ En ridd stund: lektionen presenteras, spelaren kvitterar, och
	     sedan rids det. Det är de bildrutorna som ger passet underlag. ]]
	local function rid(sekunder)
		for _ = 1, math.floor(sekunder / dt) do RunService.RenderStepped:Fire(dt) end
	end
	local function kvittera()
		local kn = hitta("Knapp")
		if kn and kn.Visible then kn.Activated:Fire() end
	end

	Net.get("MountChanged").OnClientEvent:Fire(hast, player)
	rid(0.5)
	kvittera()
	rid(2)
	local sess = UgnetaController.passSession()
	prova("passet har samlat underlag", sess ~= nil and sess.ramar > 0,
		("(%d bildrutor)"):format(if sess then sess.ramar else 0))

	--[[ OGILTIGT SLUT 1: karaktären försvinner. Respawn, inte ett pass. ]]
	player.CharacterRemoving:Fire(player.Character)
	prova("en respawn öppnar INTE sammanfattningen",
		PostRideSummary.oppen() == false)

	--[[ OGILTIGT SLUT 2: ett hästbyte. ]]
	Net.get("MountChanged").OnClientEvent:Fire(hast, player)
	rid(0.5); kvittera(); rid(2)
	local hast2 = __makeHastModell("Sigge")
	hast2.Parent = workspace
	Net.get("MountChanged").OnClientEvent:Fire(hast2, player)
	prova("ett hästbyte öppnar INTE sammanfattningen",
		PostRideSummary.oppen() == false)

	--[[ GILTIGT SLUT: servern flyttar uppsittningen — den auktoritativa
	     avsittningen. ]]
	rid(0.5); kvittera(); rid(2)
	Net.get("MountChanged").OnClientEvent:Fire(hast2, nil)
	prova("serverns egen avsittning öppnar den", PostRideSummary.oppen() == true)
	prova("och exakt EN panel finns", rakna("PostRideSummary") == 1,
		("(%d)"):format(rakna("PostRideSummary")))
	local rader = PostRideSummary.matare()
	local synliga = 0
	for _, m in rader do if m.ram.Visible then synliga += 1 end end
	prova("den visar 1–2 observationer, inte råa mätserier",
		synliga >= 1 and synliga <= 2, ("(%d rader)"):format(synliga))
	local kommentar, rubrik, regel = PostRideSummary.text()
	prova("teoritexten hör till aktivt tema",
		regel == Sprak.t(RidKanon.UGNETA.TEMA.handen.teori.regel)
			and rubrik == Sprak.t("ugneta.teori.rubrik"),
		('("%s")'):format(regel))
	prova("och den har en kommentar, inte ett tomt fält", kommentar ~= "",
		('("%s")'):format(kommentar))

	--[[ EN GÅNG. En upprepad avsittningssignal får inte öppna en till. ]]
	Net.get("MountChanged").OnClientEvent:Fire(hast2, nil)
	Net.get("MountChanged").OnClientEvent:Fire(hast2, nil)
	prova("en upprepad avsittningssignal ger ingen andra panel",
		rakna("PostRideSummary") == 1, ("(%d)"):format(rakna("PostRideSummary")))

	--[[ INGEN GAMMAL DATA VID NÄSTA PASS. ]]
	Net.get("MountChanged").OnClientEvent:Fire(hast, player)
	prova("en ny uppsittning stänger förra passets ruta",
		PostRideSummary.oppen() == false)
	local ny = UgnetaController.passSession()
	prova("och passet börjar från noll", ny ~= nil and ny.ramar == 0,
		("(%d bildrutor)"):format(if ny then ny.ramar else -1))

	--[[ ETT PASS UTAN UNDERLAG FÅR INGEN RUTA. Sitt av direkt. ]]
	Net.get("MountChanged").OnClientEvent:Fire(hast, nil)
	prova("ett pass utan en enda ridd bildruta ger ingen ruta",
		PostRideSummary.oppen() == false)
end

print("")
if fel == 0 then
	print("Alla mätningar gick igenom.")
else
	print(("%d FEL"):format(fel))
end
