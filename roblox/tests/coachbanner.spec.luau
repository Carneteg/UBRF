--!nostrict
--[[
	COACH BANNER — KONTRAKTET I #244, MÄTT.

	Beställningen 2026-09-18 ersätter Ugnetas RPG-lika nederpanel med en
	minimalistisk, toppcentrerad banner. Den här specen mäter de åtta
	acceptanspunkterna, i den ordning de står i issuet:

	  1. gamla nederpanelen skapas eller visas inte längre,
	  2. lektionens egna händelser visas i bannern,
	  3. ingen bannertext bär (R), (H) eller annan tangentreferens,
	  4. upprepade Show lämnar EN banner, senaste texten, senaste timern,
	  5. Hide/avbryt/avsittning hindrar gamla callbacks från att komma
	     tillbaka,
	  6. telefon, iPad porträtt/landskap och PC håller texten innanför,
	  7. en touch-session visar inga tangentbordshjälprutor,
	  8. (sviten i sin helhet — kor.sh).

	Kör: python3 roblox/tests/build.py tests/coachbanner.spec.luau
	     && luau roblox/tests/.build/coachbanner.luau
]]

local fails = 0
local function check(namn, ok, detalj)
	if ok then
		print(string.format("  OK   %s%s", namn, if detalj then " " .. detalj else ""))
	else
		fails += 1
		print(string.format("  FEL  %s%s", namn, if detalj then " " .. detalj else ""))
	end
end

print("")
print("COACH BANNER (#244)")

UgnetaController.start()

local gui = game:GetService("Players").LocalPlayer._gui

local function sokI(rot, namn)
	if type(rot) ~= "table" then return nil end
	if rot.Name == namn then return rot end
	for _, b in ipairs(rot._barn or {}) do
		local t = sokI(b, namn)
		if t then return t end
	end
	return nil
end

--[[ RÄKNAR I HELA PlayerGui. Det är rätt yta för frågan "finns det två
     lektionsytor?" — och fel yta för "vad heter rutan i lektionen?", se
     `hitta` nedan. ]]
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

--[[ SÖKER I LEKTIONENS YTA, inte i hela PlayerGui. Skälet är konkret:
     `Rubrik` är ett namn FYRA moduler använder — DinHast, KontrollHjalp,
     PreparationController och ReplayController. Ett osorterat svep hade
     hittat någon annans rubrik och rapporterat att nederpanelen lever
     kvar, eller — värre — hittat den och kallat den någon annans. ]]
local function hitta(namn)
	return sokI(sokI(gui, "UBRFUgneta"), namn)
end

--[[ `Color3.R` är 0–1 i Roblox, inte 0–255. Kontraktet talar i 0–255, så
     provet räknar tillbaka i stället för att jämföra mot en bråkdel — ett
     tal som `0.0784` i en assertion hade varit oläsbart mot beställningen. ]]
local function rgb(f)
	if not f then return -1, -1, -1 end
	local function b(x) return math.floor((x or 0) * 255 + 0.5) end
	return b(f.R), b(f.G), b(f.B)
end
local function arFarg(f, r, g, b)
	local fr, fg, fb = rgb(f)
	return fr == r and fg == g and fb == b
end

--[[ Stegar bannern i 60 Hz tills villkoret slår in, och svarar med hur
     LÅNG tid det tog. Provet mäter alltså den faktiska visningstiden i
     stället för att räkna bildrutor på en gräns och hoppas hamna rätt —
     en fast loop på exakt 4,9 s låg på fel sida med en enda bildruta. ]]
local function stegaTills(villkor, maxSek)
	local dt = 1 / 60
	local gatt = 0
	while gatt < (maxSek or 30) do
		if villkor() then return gatt end
		CoachBanner.steg(dt)
		gatt += dt
	end
	return gatt
end

--[[ ══ 1. DEN GAMLA NEDERPANELEN ÄR BORTA ═══════════════════════════════

	Kravet är "skapas eller visas inte längre", alltså inte "är dold".
	Provet mäter att instanserna inte FINNS i den byggda ytan. Att koden
	dessutom är borta ur källan mäts av `tools/kolla-nederpanel.py`, som
	kor.sh kör — en Luau-bänk kan inte se skillnad på en riven panel och en
	panel bakom `Visible = false`. ]]
print("\n── Den gamla nederpanelen ──")
do
	for _, namn in { "Kort", "Avsandare", "Rubrik", "Punkt1", "Punkt2" } do
		check(("%s finns inte i lektionsytan"):format(namn), hitta(namn) == nil,
			if hitta(namn) then "(byggd ändå)" else nil)
	end
	check("och lektionen har fortfarande EN ScreenGui, inte två",
		rakna("UBRFUgneta") == 1 and gui.Name == "PlayerGui",
		("(%d st UBRFUgneta)"):format(rakna("UBRFUgneta")))
end

--[[ ══ YTANS EGENSKAPER ═══════════════════════════════════════════════ ]]
print("\n── Bannerns ram ──")
do
	local yta = sokI(gui, "UBRFUgneta")
	check("ScreenGui: ResetOnSpawn av, GuiInset ignorerad",
		yta ~= nil and yta.ResetOnSpawn == false and yta.IgnoreGuiInset == true,
		("(reset %s · inset %s)"):format(tostring(yta and yta.ResetOnSpawn),
			tostring(yta and yta.IgnoreGuiInset)))

	local b = hitta("CoachBanner")
	check("bannern är byggd och bor i lektionens yta",
		b ~= nil and b.Parent == yta)
	check("toppcentrerad under Roblox-menyn",
		b ~= nil and b.AnchorPoint.X == 0.5 and b.AnchorPoint.Y == 0
			and b.Position.X.Scale == 0.5 and b.Position.Y.Offset == 48,
		("(x %.2f+%d · y %.2f+%d)"):format(b.Position.X.Scale, b.Position.X.Offset,
			b.Position.Y.Scale, b.Position.Y.Offset))
	check("strikt kompakt höjd, 50–54 px",
		b ~= nil and b.Size.Y.Offset >= 50 and b.Size.Y.Offset <= 54,
		("(%d px)"):format(b and b.Size.Y.Offset or -1))
	check("mörk ram RGB 20,20,25 med transparens 0,35",
		b ~= nil and arFarg(b.BackgroundColor3, 20, 20, 25),
		("(%d,%d,%d)"):format(rgb(b and b.BackgroundColor3)))

	local horn, kant
	for _, barn in ipairs(b._barn) do
		if barn.ClassName == "UICorner" then horn = barn end
		if barn.ClassName == "UIStroke" then kant = barn end
	end
	check("UICorner 10 px", horn ~= nil and horn.CornerRadius.Offset == 10,
		("(%s)"):format(tostring(horn and horn.CornerRadius.Offset)))
	check("vit UIStroke 1 px", kant ~= nil and kant.Thickness == 1)

	local mal = hitta("GoalLabel")
	local detalj = hitta("InstructionLabel")
	check("målraden är GothamBold i versaler, 13–14 px, vit",
		mal ~= nil and mal.Font == Enum.Font.GothamBold
			and mal.TextSize >= 13 and mal.TextSize <= 14
			and mal.TextTransform == Enum.TextTransform.UppercaseAll
			and arFarg(mal.TextColor3, 255, 255, 255),
		("(%s · %s px)"):format(tostring(mal and mal.Font), tostring(mal and mal.TextSize)))
	check("instruktionsraden är Gotham, 11–12 px, RGB 200,200,205",
		detalj ~= nil and detalj.Font == Enum.Font.Gotham
			and detalj.TextSize >= 11 and detalj.TextSize <= 12
			and arFarg(detalj.TextColor3, 200, 200, 205),
		("(%s · %s px)"):format(tostring(detalj and detalj.Font),
			tostring(detalj and detalj.TextSize)))
	check("båda raderna kapar hellre än flyttar ramens layout",
		mal ~= nil and detalj ~= nil
			and mal.TextTruncate == Enum.TextTruncate.AtEnd
			and detalj.TextTruncate == Enum.TextTruncate.AtEnd
			and mal.TextWrapped == false and detalj.TextWrapped == false)
end

--[[ ══ TONINGEN ════════════════════════════════════════════════════════ ]]
print("\n── Toningen ──")
do
	CoachBanner.Hide()
	table.clear(__tweens)
	CoachBanner.Show("HALT → SKRITT", "Titta dit du ska.")
	local b = hitta("CoachBanner")
	check("bannern syns direkt när den visas", b.Visible == true)
	check("och tonar in, den tonar inte fram av sig själv",
		#__tweens > 0, ("(%d tweens)"):format(#__tweens))

	local rattTid, rattEasing = true, true
	for _, t in __tweens do
		if t.TweenInfo.Time ~= 0.4 then rattTid = false end
		if t.TweenInfo.EasingStyle ~= Enum.EasingStyle.Quad then rattEasing = false end
	end
	check("fade 0,4 s med Quad, som kontraktet säger", rattTid and rattEasing,
		("(tid %s · easing %s)"):format(tostring(__tweens[1].TweenInfo.Time),
			tostring(__tweens[1].TweenInfo.EasingStyle)))

	--[[ Målvärdena är kontraktets synliga transparens, inte godtyckliga
	     tal: 0,35 på ramen och 0,75 på ramkanten. ]]
	local ramMal, kantMal
	for _, t in __tweens do
		if t._mal.BackgroundTransparency then ramMal = t._mal.BackgroundTransparency end
		if t._mal.Transparency then kantMal = t._mal.Transparency end
	end
	check("intoningen slutar på synlig transparens 0,35 och kant 0,75",
		ramMal == 0.35 and kantMal == 0.75,
		("(ram %s · kant %s)"):format(tostring(ramMal), tostring(kantMal)))
end

--[[ ══ VISNINGSTIDEN ═══════════════════════════════════════════════════ ]]
print("\n── Visningstiden ──")
do
	CoachBanner.Hide()
	CoachBanner.Show("MÅL", "Detalj")
	check("standardtiden ligger i kontraktets 4–5 s",
		CoachBanner.kvar() >= 4 and CoachBanner.kvar() <= 5,
		("(%.1f s)"):format(CoachBanner.kvar()))

	--[[ Stega tills uttoningen börjar, och MÄT hur lång tid det tog.
	     Den ska vara intoningen plus måltiden — inte mindre, för då
	     försvinner texten innan den lästs, och inte mer, för då är den
	     en panel igen. ]]
	local b = hitta("CoachBanner")
	local tillUt = stegaTills(function() return CoachBanner.fas() == "ut" end, 30)
	local vantad = CoachBanner.FADE + CoachBanner.STANDARD_TID
	check("uttoningen börjar efter intoning plus måltid",
		math.abs(tillUt - vantad) < 0.05 and b.Visible == true,
		("(%.2f s, väntat %.2f s · synlig %s)"):format(tillUt, vantad,
			tostring(b.Visible)))
	local tillDold = stegaTills(function() return CoachBanner.fas() == "dold" end, 5)
	check("och uttoningen tar kontraktets 0,4 s",
		math.abs(tillDold - CoachBanner.FADE) < 0.05 and b.Visible == false,
		("(%.2f s · synlig %s)"):format(tillDold, tostring(b.Visible)))

	--[[ Egen duration ska gälla. ]]
	CoachBanner.Show("MÅL", "Detalj", 1.0)
	check("en egen visningstid gäller framför standarden",
		math.abs(CoachBanner.kvar() - 1.0) < 1e-6,
		("(%.2f s)"):format(CoachBanner.kvar()))
end

--[[ ══ 4. UPPREPADE SHOW ═══════════════════════════════════════════════
	Kravet: exakt en banner, senaste texten, senaste timern — och ingen
	blinkning, alltså ingen bildruta där den är osynlig mellan två Show. ]]
print("\n── Upprepade Show ──")
do
	CoachBanner.Hide()
	CoachBanner.Show("FÖRSTA", "Första detaljen", 5)
	local b = hitta("CoachBanner")
	local dt = 1 / 60
	for _ = 1, 120 do CoachBanner.steg(dt) end        -- 2 s in i visningen
	local kvarFore = CoachBanner.kvar()
	table.clear(__tweens)
	CoachBanner.Show("ANDRA", "Andra detaljen", 5)
	local mal, detalj = CoachBanner.text()

	check("det finns fortfarande exakt EN banner", rakna("CoachBanner") == 1,
		("(%d st)"):format(rakna("CoachBanner")))
	check("texten är den senaste, båda raderna på en gång",
		mal == "ANDRA" and detalj == "Andra detaljen",
		('("%s" / "%s")'):format(mal, detalj))
	check("timern är förnyad, inte fortsatt",
		CoachBanner.kvar() > kvarFore and math.abs(CoachBanner.kvar() - 5) < 1e-6,
		("(%.2f s → %.2f s)"):format(kvarFore, CoachBanner.kvar()))
	check("och den blinkade aldrig — Visible stod kvar hela tiden",
		b.Visible == true)

	--[[ DEN GAMLA UTTONINGEN FÅR INTE TONA NER DEN NYA TEXTEN.
	     Prövas där den faktiskt kan göra skada: ett Show som kommer när
	     uttoningen redan startat. ]]
	CoachBanner.Hide()
	CoachBanner.Show("TREDJE", "Tredje detaljen", 0.1)
	stegaTills(function() return CoachBanner.fas() == "ut" end, 5)
	check("uttoningen har startat", CoachBanner.fas() == "ut",
		("(fas %s)"):format(CoachBanner.fas()))
	local utTweens = {}
	for _, t in __tweens do
		if t._mal.BackgroundTransparency == 1 then table.insert(utTweens, t) end
	end
	CoachBanner.Show("FJÄRDE", "Fjärde detaljen", 5)
	local allaAvbrutna = #utTweens > 0
	for _, t in utTweens do if not t._avbruten then allaAvbrutna = false end end
	check("ett nytt Show avbryter den pågående uttoningen",
		allaAvbrutna, ("(%d uttoningar)"):format(#utTweens))
	check("och tar tillbaka bannern till fullt synligt läge",
		b.Visible == true and b.BackgroundTransparency == 0.35
			and CoachBanner.fas() == "kvar",
		("(fas %s · transparens %s)"):format(CoachBanner.fas(),
			tostring(b.BackgroundTransparency)))
end

--[[ ══ 5. INGEN GAMMAL CALLBACK KOMMER TILLBAKA ════════════════════════
	Modulen använder ingen `task.delay`. Provet mäter konsekvensen: efter
	Hide kan ingen mängd stegande väcka bannern, och en bänk-`task.delay`
	som ändå fyrades skulle ha satts av modulen — den är tom. ]]
print("\n── Hide och städning ──")
do
	__senasteDelay = nil
	CoachBanner.Hide()
	CoachBanner.Show("MÅL", "Detalj", 5)
	check("modulen lägger ingen fördröjd callback alls",
		__senasteDelay == nil, "(task.delay orörd)")

	local b = hitta("CoachBanner")
	CoachBanner.Hide()
	check("Hide släcker direkt, utan uttoning att invänta",
		b.Visible == false and CoachBanner.fas() == "dold" and CoachBanner.kvar() == 0)
	for _ = 1, 600 do CoachBanner.steg(1 / 60) end
	check("och tio sekunders stegande väcker den inte igen",
		b.Visible == false and CoachBanner.fas() == "dold")

	--[[ Städvägen: efter Destroy finns ingen banner kvar, och ett Show
	     utan montering får inte bygga en ny i smyg. ]]
	CoachBanner.Destroy()
	check("Destroy tar bort bannern ur ytan", rakna("CoachBanner") == 0,
		("(%d st)"):format(rakna("CoachBanner")))
	CoachBanner.Show("SKA INTE SYNAS", "ingen yta", 5)
	check("och ett Show utan monterad yta bygger ingen ny",
		rakna("CoachBanner") == 0 and CoachBanner.synlig() == false,
		("(%d st)"):format(rakna("CoachBanner")))
	--[[ Tillbaka till monterat läge för resten av filen. ]]
	CoachBanner.montera(sokI(gui, "UBRFUgneta"))
	check("montera bygger upp den igen, och bara en", rakna("CoachBanner") == 1,
		("(%d st)"):format(rakna("CoachBanner")))
	CoachBanner.montera(sokI(gui, "UBRFUgneta"))
	check("ett andra montera på samma yta lämnar fortfarande EN",
		rakna("CoachBanner") == 1, ("(%d st)"):format(rakna("CoachBanner")))
end

--[[ ══ 6. RESPONSIVITET ════════════════════════════════════════════════
	42 % är kontraktets tal för en stor skärm, men inte ett mobilkontrakt.
	Provet mäter att bredden håller sig innanför skärmen på varje yta
	kanonen provar mot, och att den inte krymper till en remsa på telefon. ]]
print("\n── Telefon, iPad och PC ──")
do
	local ytor = {
		{ namn = "PC 1920x1080", W = 1920 },
		{ namn = "iPad Pro landskap 1376", W = 1376 },
		{ namn = "iPad 9 landskap 1080", W = 1080 },
		{ namn = "iPad porträtt 810", W = 810 },
		{ namn = "iPhone 13 landskap 844", W = 844 },
		{ namn = "iPhone 13 porträtt 390", W = 390 },
		{ namn = "liten telefon 320", W = 320 },
	}
	local yta = sokI(gui, "UBRFUgneta")
	local b = hitta("CoachBanner")
	local allaInnanfor, allaLasbara, rader = true, true, {}
	for _, s in ytor do
		yta.AbsoluteSize = Vector3.new(s.W, 800, 0)
		CoachBanner.Show("MÅL", "Detalj", 5)
		local bredd = b.Size.X.Offset
		if bredd > 0.92 * s.W + 0.5 then allaInnanfor = false end
		--[[ Golvet: en banner smalare än 60 % av skärmen på en telefon är
		     en remsa, inte en banner. På stora skärmar binder taket i
		     stället, och då är 42 %-regeln den som gäller. ]]
		if bredd < math.min(0.60 * s.W, 300) - 0.5 then allaLasbara = false end
		table.insert(rader, ("%s → %d px"):format(s.namn, bredd))
	end
	check("bannern håller sig innanför skärmen på varje yta", allaInnanfor,
		table.concat(rader, " · "))
	check("och blir aldrig en remsa på telefon", allaLasbara)

	--[[ VRIDNINGEN. Samma lärdom som #206: en regel som körs en gång, när
	     något visas, lämnar ytan i gammal geometri när plattan vrids. ]]
	yta.AbsoluteSize = Vector3.new(1376, 1032, 0)
	CoachBanner.Show("MÅL", "Detalj", 5)
	local bred = b.Size.X.Offset
	yta.AbsoluteSize = Vector3.new(810, 1080, 0)
	yta:GetPropertyChangedSignal("AbsoluteSize"):Fire()
	local smal = b.Size.X.Offset
	check("bannern räknas OM när plattan vrids, inte bara när den visas",
		smal ~= bred and smal <= 0.92 * 810,
		("(%d px → %d px)"):format(bred, smal))
	yta.AbsoluteSize = Vector3.new(1376, 1032, 0)
	yta:GetPropertyChangedSignal("AbsoluteSize"):Fire()
	check("och tillbaka igen när ytan växer", b.Size.X.Offset == bred,
		("(%d px)"):format(b.Size.X.Offset))
end

--[[ ══ 2 och 3. LEKTIONEN MATAR BANNERN ════════════════════════════════
	Inte ett direktanrop av `Show`: hela poängen är att LEKTIONEN — den
	modul klientens loop stegar — lägger sin egen pedagogiska text i
	bannern. Och att ingen tangentreferens följer med in i den. ]]
print("\n── Lektionen matar bannern ──")
do
	local function tele(over)
		local t = {
			uppsutten = true, gangart = "trav", fart = 3.0, onskadFart = 3.0,
			svangradie = 10, balans = 0.80, mjukhet = 0.75, fokus = 0.80,
			spanning = 0.20, svarstid = 0.12, etableringstid = 0.8,
			paradKvalitet = 0.70,
		}
		for k, v in over or {} do t[k] = v end
		return t
	end

	--[[ Tangentbordet PÅ: det är det läge där en ledtext kan smyga in. ]]
	game:GetService("UserInputService").KeyboardEnabled = true
	LektionController.start(nil)
	LektionController.steg(1 / 30, tele())
	local mal, detalj = CoachBanner.text()
	local forsta = Lektion.OVNINGAR[Lektion.ORDNING[1]]
	check("första övningen presenteras i bannern, med kanonens rubrik",
		mal == forsta.rubrik and CoachBanner.synlig() == true,
		('("%s" / "%s")'):format(mal, detalj))
	check("och instruktionsraden är övningens egna punkter",
		detalj ~= "" and string.find(detalj, forsta.punkter[1], 1, true) ~= nil,
		('("%s")'):format(detalj))

	local function utanTangentreferens(txt)
		return string.find(txt, "(R)", 1, true) == nil
			and string.find(txt, "(H)", 1, true) == nil
			and string.find(txt, "(Y)", 1, true) == nil
	end
	check("presentationen bär ingen tangentreferens, trots tangentbord",
		utanTangentreferens(mal) and utanTangentreferens(detalj),
		('("%s" / "%s")'):format(mal, detalj))

	--[[ …medan knappen, som INTE är bannern, gärna får ha sin ledtext.
	     Kontraktet förbjuder tangentreferenser i bannerns text. ]]
	local knapp = hitta("Knapp")
	check("valet står kvar som knapp, utanför bannern",
		knapp ~= nil and knapp.Visible == true and LektionController.vantar() == true,
		("(synlig %s · väntar %s)"):format(tostring(knapp and knapp.Visible),
			tostring(LektionController.vantar())))

	--[[ ══ BANNERN STEGAS UR PRODUKTIONENS EGEN LOOP ════════════════

	     Falsifiering 2026-09-18: en mutation som tog bort
	     `CoachBanner.steg(dt)` ur `UgnetaController.steg` lämnade den här
	     specen HELT GRÖN. Skälet var att provet stegade modulen själv,
	     alltså mätte att tiden GÅR — inte att någon räknar ned den i
	     spelet. Bannern hade blivit stående för alltid på skärmen och
	     kontraktets egen spec hade inte sagt ett ord.

	     Nu stegas den på det enda sätt produktionen gör det: genom
	     lektionen, som klientens RenderStepped anropar. Provet rör inte
	     `CoachBanner.steg` med sin egen hand här. ]]
	do
		local dt, kvar = 1 / 60, CoachBanner.STANDARD_TID + 2 * CoachBanner.FADE + 1
		while kvar > 0 and CoachBanner.synlig() do
			LektionController.steg(dt, tele())
			kvar -= dt
		end
		check("bannern tonar ut genom lektionens egen stegning, inte provets",
			CoachBanner.synlig() == false and LektionController.vantar() == true,
			("(banner %s · väntar %s)"):format(tostring(CoachBanner.synlig()),
				tostring(LektionController.vantar())))
		--[[ …och VALET står kvar. Det är hela skillnaden mot en
		     nedräkning: texten går, men beslutet är fortfarande hennes. ]]
		check("men valet står kvar när texten tonat bort",
			hitta("Val").Visible == true and hitta("Knapp").Visible == true,
			("(val %s)"):format(tostring(hitta("Val").Visible)))
	end

	--[[ EFTER ETT FÖRSÖK: återkopplingen ska också hamna i bannern. ]]
	LektionController.fortsatt()
	local dt = 1 / 30
	for _ = 1, math.ceil((Lektion.FORSOK_SEK + 0.2) / dt) do
		LektionController.steg(dt, tele({ mjukhet = 0.30, balans = 0.55 }))
	end
	local mal2, detalj2 = CoachBanner.text()
	check("återkopplingen efter försök 1 visas i bannern",
		mal2 ~= mal and detalj2 ~= "" and CoachBanner.synlig() == true,
		('("%s" / "%s")'):format(mal2, detalj2))
	check("och inte heller den bär en tangentreferens",
		utanTangentreferens(mal2) and utanTangentreferens(detalj2),
		('("%s" / "%s")'):format(mal2, detalj2))

	--[[ ══ SÄKERHET SLÄCKER BANNERN ══════════════════════════════════
	     Avsittning, avbrott och respawn går alla genom `avbryt`. ]]
	LektionController.avbryt()
	check("ett avbrott släcker bannern direkt",
		CoachBanner.synlig() == false and CoachBanner.fas() == "dold",
		("(fas %s)"):format(CoachBanner.fas()))
	check("och knappraden följer med ned",
		hitta("Knapp").Visible == false and hitta("SeRitten").Visible == false
			and hitta("GaVidare").Visible == false)
	CoachBanner.steg(1)
	check("en bildruta efter avbrottet väcker ingenting",
		CoachBanner.synlig() == false)
end

--[[ ══ 7. INGA TANGENTBORDSHJÄLPRUTOR I EN TOUCH-SESSION ══════════════
	Kravet gäller den gamla hjälpytan, inte bannern. `KontrollHjalp` är
	redan släckt med sin egen `MINIMAL_UI`; provet pinnar det, så att en
	återtändning inte kan smyga förbi just det här kontraktet. ]]
print("\n── Touch-session ──")
do
	local usv = game:GetService("UserInputService")
	local kb, touch = usv.KeyboardEnabled, usv.TouchEnabled
	usv.KeyboardEnabled = false
	usv.TouchEnabled = true
	KontrollHjalp.start()
	local hjalp = sokI(gui, "UBRFKontroller")
	check("hjälprutan är inte påslagen i en touch-session",
		hjalp == nil or hjalp.Enabled == false,
		("(%s)"):format(if hjalp then tostring(hjalp.Enabled) else "ingen yta"))
	usv.KeyboardEnabled, usv.TouchEnabled = kb, touch
end

print("")
if fails > 0 then
	print(string.format("%d mätning(ar) föll.", fails))
else
	print("Alla mätningar gick igenom.")
end
