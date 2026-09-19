--!nostrict
--[[ VILKEN BUILD SITTER JAG I? — mätt som ett vanligt testkonto ser det (#263)

	Fysisk QA på iPad kunde inte bevisa att enheten kör den granskade
	koden. Serverloggen är stängd för ett konto utan team create, och
	Studios källhash säger bara vad Studio kör. `Byggidentitet` läser
	`ReplicatedStorage.UBRFBuild` på KLIENTEN, där den redan replikeras.

	Fyra kontrakt mäts, och de mäter olika saker med flit:

	  1. DATAT  — raderna bär rätt värden, hashen har rätt längd i båda
	     lägena, och `sha` syns ingenstans. Det sista är inget
	     stilkrav: fältet släpar per konstruktion, och en rad som
	     påstod att det var den körande commiten hade varit en lögn med
	     siffror i.
	  2. FAIL CLOSED — varje väg där identiteten saknas, har fel typ
	     eller fel form ska ge «okänd». Aldrig en nolla, aldrig en tom
	     sträng, aldrig ett standardvärde som SER matchat ut. Det är
	     den farligaste feltypen här: en QA-omgång som tror att fel
	     build är rätt.
	  3. LIVSCYKELN — två `start` ger en knapp, inte två. Panelen är
	     SLÄCKT som utgångsläge, så den kan inte fånga styrning när den
	     är stängd. Knappen göms medan panelen står uppe.
	  4. LAYOUTEN — knappen är minst 44 px (KONTROLLMATRIS regel 5),
	     ligger helt på skärmen, krockar inte med pekreglagens reserv,
	     och panelen får plats på den minsta skärm klienten mäts på.

	SKÄRMARNA och reservzonen är samma källor som `klient-hjalpknapp.spec`
	och `klient-reservzon.spec`: talen kommer ur reglagens egen layout
	genom `TouchControls.reglageBredd()`/`reglageTopp()`, inte ur en
	avskriven koordinat.

	Kör: python3 roblox/tests/build.py tests/klient-byggidentitet.spec.luau
	     && luau roblox/tests/.build/klient-byggidentitet.spec.luau ]]

local fel = 0
local function prova(vad, ok, detalj)
	if ok then
		print(("  OK   %s%s"):format(vad, if detalj then "  " .. detalj else ""))
	else
		fel += 1
		print(("  FEL  %s%s"):format(vad, if detalj then "  " .. detalj else ""))
	end
end

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local cam = workspace.CurrentCamera

local function inset()
	return GuiService:GetGuiInset().Y
end

--[[ En rams ruta i skärmens pixlar. Båda ytorna har `IgnoreGuiInset =
	false`, alltså är deras GUI-yta viewporten minus topbaren och
	skärm-y är GUI-y plus inseten. Samma räkning som hjälpknappspecen. ]]
local function rekt(f, W, Hg, dy)
	local p, s, a = f.Position, f.Size, f.AnchorPoint or { X = 0, Y = 0 }
	local b = W * s.X.Scale + s.X.Offset
	local h = Hg * s.Y.Scale + s.Y.Offset
	local x = W * p.X.Scale + p.X.Offset - a.X * b
	local y = Hg * p.Y.Scale + p.Y.Offset - a.Y * h + dy
	return { x0 = x, y0 = y, x1 = x + b, y1 = y + h }
end
local function skar(a, b)
	return a.x0 < b.x1 and b.x0 < a.x1 and a.y0 < b.y1 and b.y0 < a.y1
end
local function r2s(r)
	return ("x %d..%d y %d..%d"):format(r.x0, r.x1, r.y0, r.y1)
end

--[[ Den ÄKTA identiteten: den GENERERADE tabellen, inlinad i bunten ur
	`roblox/game/UBRFBuild.luau`. Talen nedan jämförs mot den — inte mot
	en hash skriven av för hand, som hade blivit fel dagen någon rör en
	källfil, och då hade provet mätt sin egen inaktualitet. ]]
local AKTA = UBRFBuild

--[[ Sätter en identitetsmodul i den stubbade ReplicatedStorage. `__modul`
	är bänkens söm: stubbarnas `require` svarar med den tabellen. Samma
	hjälpare som `integritet.spec` — ett mönster, en plats. ]]
local function sattIdentitet(tabell)
	local gammal = ReplicatedStorage:FindFirstChild("UBRFBuild")
	if gammal then gammal:Destroy() end
	if tabell == nil then return nil end
	local m = Instance.new("ModuleScript")
	m.Name = "UBRFBuild"
	m.__modul = tabell
	m.Parent = ReplicatedStorage
	return m
end

--[[ Bänken bär ingen `UBRFBuild`-instans av sig själv; bunten ger bara
	tabellen. Produktionen läser INSTANSEN, så provet måste ställa dit
	den innan något mäts — annars hade rad 1 mätt fail closed-vägen och
	kallat den för den riktiga. ]]
sattIdentitet(AKTA)

local function rad(rader, nyckel)
	for _, r in ipairs(rader) do
		if r.nyckel == nyckel then return r.varde end
	end
	return nil
end

--[[ Byter ut identiteten och lämnar tillbaka en återställare. Modulen
	slår upp instansen vid VARJE anrop, så bytet slår igenom utan att
	något behöver startas om. ]]
local function medBygge(tabell)
	sattIdentitet(tabell)
	return function() sattIdentitet(AKTA) end
end

--[[ ══ 1. DATAT ════════════════════════════════════════════════════ ]]
print("\n── 1. Raderna bär den riktiga identiteten ──")
do
	local rader = Byggidentitet.rader()
	prova("sju rader", #rader == 7, ("%d"):format(#rader))

	local h = rad(rader, "bygg.kallhash")
	prova("hashen visas kort som standard", h ~= nil and #h == 12, tostring(h))
	prova("och de tolv tecknen är hashens egna",
		h == AKTA.kallhash:sub(1, 12), ("%s mot %s"):format(tostring(h), AKTA.kallhash:sub(1, 12)))

	prova("hela hashen går att få ut", Byggidentitet.hash(false) == AKTA.kallhash,
		("%d tecken"):format(#Byggidentitet.hash(false)))
	prova("och den är 64 tecken", #Byggidentitet.hash(false) == 64)

	prova("källfilerna räknas ur identiteten",
		rad(rader, "bygg.kallor") == tostring(AKTA.kallor),
		("%s mot %d"):format(tostring(rad(rader, "bygg.kallor")), AKTA.kallor))
	prova("läget kommer ur identiteten",
		rad(rader, "bygg.lage") == AKTA.lage, tostring(rad(rader, "bygg.lage")))
	prova("genereringstiden kommer ur identiteten",
		rad(rader, "bygg.genererad") == AKTA.genererad,
		tostring(rad(rader, "bygg.genererad")))

	--[[ DEN VIKTIGASTE RADEN I HELA SPECEN. `sha` släpar per konstruktion
		och får aldrig presenteras som den körande buildens commit. Här
		mäts att den inte läcker ut genom NÅGON rad — inte bara att ingen
		rad heter `bygg.sha`. ]]
	local lackt = false
	for _, r in ipairs(rader) do
		if type(r.varde) == "string" and AKTA.sha ~= nil
			and r.varde:find(AKTA.sha:sub(1, 7), 1, true) then
			lackt = true
		end
	end
	prova("det eftersläpande sha:t syns inte i någon rad", not lackt,
		if lackt then "sha läckte" else ("sha=%s"):format(tostring(AKTA.sha):sub(1, 7)))
end

--[[ ══ 2. FAIL CLOSED ═══════════════════════════════════════════════ ]]
print("\n── 2. Saknad eller trasig identitet visas som okänd ──")

local OKAND = Sprak.t("bygg.okand")

local function allaOkanda(rader)
	for _, nyckel in ipairs({ "bygg.kallhash", "bygg.kallor", "bygg.lage", "bygg.genererad" }) do
		if rad(rader, nyckel) ~= OKAND then return false, nyckel end
	end
	return true, nil
end

do
	--[[ Modulen är borta. Det här är iPad-fallet som gör hela vyn
		meningsfull: en build där identiteten inte genererats ska SÄGA
		det, inte visa tomma fält som ser lugna ut. ]]
	local ater = medBygge(nil)
	local rader = Byggidentitet.rader()
	local ok, vilken = allaOkanda(rader)
	prova("utan UBRFBuild är varje identitetsrad okänd", ok, tostring(vilken))
	prova("och hashen är okänd i båda lägena",
		Byggidentitet.hash(true) == OKAND and Byggidentitet.hash(false) == OKAND)
	prova("identitet() säger nil, inte en tom tabell",
		Byggidentitet.identitet() == nil)
	ater()
	prova("återställd: hashen är tillbaka", Byggidentitet.hash(true) == AKTA.kallhash:sub(1, 12))
end

do
	--[[ Fel klass. En `Folder` som heter UBRFBuild ska inte gå att
		`require`, och vakten ska fånga det före anropet. ]]
	local gammal = ReplicatedStorage:FindFirstChild("UBRFBuild")
	if gammal then gammal:Destroy() end
	local mapp = Instance.new("Folder")
	mapp.Name = "UBRFBuild"
	mapp.Parent = ReplicatedStorage
	prova("en Folder som heter UBRFBuild ger ingen identitet",
		Byggidentitet.identitet() == nil)
	prova("och raderna blir okända", (allaOkanda(Byggidentitet.rader())))
	mapp:Destroy()
	sattIdentitet(AKTA)
end

do
	--[[ EN IDENTITET SOM INTE ÄR EN TABELL. `require` lyckas — modulen
		finns och returnerar något — men det den returnerar går inte att
		indexera. Utan typtestet kastar första uppslaget, och då dör
		panelen i stället för att säga «okänd».

		Mätningen saknades i första omgången, och falsifieringen
		visade det: B5 kom ut GRÖN, alltså mätte provet aldrig den
		vakten. ]]
	local ater = medBygge(42)
	local ok, resultat = pcall(function()
		return Byggidentitet.rader()
	end)
	prova("en icke-tabell som identitet kastar inte", ok,
		if ok then "rader gavs" else tostring(resultat):sub(1, 60))
	prova("och den ger okänt, inte ett värde",
		ok and rad(resultat, "bygg.lage") == OKAND,
		ok and tostring(rad(resultat, "bygg.lage")) or "-")
	prova("identitet() säger nil för en icke-tabell",
		Byggidentitet.identitet() == nil)
	ater()
end

do
	--[[ Trasig hash: rätt fält, fel form. 63 tecken och ett icke-hex-tecken
		är två olika sätt att vara trasig, och båda ska falla. ]]
	local ater = medBygge({
		kallhash = string.rep("a", 63), lage = "rojo", kallor = 74,
		genererad = "2026-01-01T00:00:00Z", sha = "x" })
	prova("en hash på 63 tecken är okänd", Byggidentitet.hash(true) == OKAND,
		Byggidentitet.hash(true))
	ater()

	ater = medBygge({
		kallhash = string.rep("z", 64), lage = "rojo", kallor = 74,
		genererad = "2026-01-01T00:00:00Z", sha = "x" })
	prova("en hash som inte är hex är okänd", Byggidentitet.hash(true) == OKAND,
		Byggidentitet.hash(true))
	--[[ ...men de ÖVRIGA raderna ska fortfarande visa det de har. En
		trasig hash får inte tysta hela vyn. ]]
	prova("och de övriga raderna visar ändå sitt",
		rad(Byggidentitet.rader(), "bygg.kallor") == "74")
	ater()
end

do
	--[[ Fel typ på källantalet, och tom sträng som läge. Båda ska ge
		okänd — ett fält som FINNS men är tomt bevisar ingenting. ]]
	local ater = medBygge({
		kallhash = AKTA.kallhash, lage = "", kallor = "74",
		genererad = "2026-01-01T00:00:00Z" })
	local rader = Byggidentitet.rader()
	prova("källantal som sträng är okänt", rad(rader, "bygg.kallor") == OKAND,
		tostring(rad(rader, "bygg.kallor")))
	prova("tomt läge är okänt", rad(rader, "bygg.lage") == OKAND,
		tostring(rad(rader, "bygg.lage")))
	prova("men hashen, som är hel, visas", rad(rader, "bygg.kallhash") == AKTA.kallhash:sub(1, 12))
	ater()
end

print("\n── 2b. Place, version och miljö ──")
do
	local foreP, foreV, foreJ = game.PlaceId, game.PlaceVersion, game.JobId

	--[[ Ingen av egenskaperna satt: bänkens `game` bär dem inte, precis
		som en motor som inte svarar. Då är svaret okänt. ]]
	game.PlaceId, game.PlaceVersion, game.JobId = nil, nil, nil
	local rader = Byggidentitet.rader()
	prova("utan PlaceId är platsen okänd", rad(rader, "bygg.plats") == OKAND,
		tostring(rad(rader, "bygg.plats")))
	prova("utan PlaceVersion är versionen okänd", rad(rader, "bygg.version") == OKAND,
		tostring(rad(rader, "bygg.version")))

	--[[ Referensen: "This property is 0 for all unpublished experiences."
		Noll är alltså ett SVAR, inte ett saknat värde — och det ska
		skrivas ut som opublicerad, aldrig som versionen noll. ]]
	game.PlaceId, game.PlaceVersion = 106030782437053, 0
	rader = Byggidentitet.rader()
	prova("platsen skrivs ut som heltal", rad(rader, "bygg.plats") == "106030782437053",
		tostring(rad(rader, "bygg.plats")))
	prova("version 0 skrivs som opublicerad",
		rad(rader, "bygg.version") == Sprak.t("bygg.opublicerad"),
		tostring(rad(rader, "bygg.version")))

	game.PlaceVersion = 42
	prova("en publicerad version skrivs ut som sitt tal",
		rad(Byggidentitet.rader(), "bygg.version") == "42")

	--[[ I STUDIO FÅR TALET INTE STÅ ENSAMT. Uppmätt på `a8dd254`:
		Studio rapporterade `PlaceVersion = 294` medan Rojo samtidigt
		hade synkat in arbetsträdets kod. Talet beskriver `.rbxl`-filens
		ursprung, inte det som körs — samma fälla som det eftersläpande
		`sha`, och lika förbjuden.

		Bänkens RunService säger `IsStudio() == false`, så vägen måste
		tändas här för att gå att mäta. ]]
	local foreStudio = RunService.IsStudio
	RunService.IsStudio = function() return true end
	local iStudio = rad(Byggidentitet.rader(), "bygg.version")
	prova("i Studio står versionen aldrig ensam",
		iStudio ~= "42" and iStudio:find("42", 1, true) ~= nil, tostring(iStudio))
	prova("och den säger uttryckligen att Studio kör annan kod",
		iStudio == Sprak.t("bygg.studioversion", 42), tostring(iStudio))
	prova("miljöraden säger Studio i samma läge",
		rad(Byggidentitet.rader(), "bygg.miljo") == Sprak.t("bygg.studio"),
		tostring(rad(Byggidentitet.rader(), "bygg.miljo")))
	RunService.IsStudio = foreStudio
	prova("och utanför Studio är talet rent igen",
		rad(Byggidentitet.rader(), "bygg.version") == "42")

	--[[ Miljön. Bänkens RunService säger `IsStudio() == false`, alltså
		"publicerad server" — och JobId läggs till när den finns.
		Referensen: JobId "Defaults to an empty string in Studio." ]]
	game.JobId = ""
	prova("tom JobId lägger inte till något",
		rad(Byggidentitet.rader(), "bygg.miljo") == Sprak.t("bygg.server"),
		tostring(rad(Byggidentitet.rader(), "bygg.miljo")))

	--[[ NOLLSTÄLLD UUID. Uppmätt i en Studio-multiplayerplaytest på
		`a8dd254`: motorn svarade `00000000-0000-0000-0000-000000000000`,
		trots att referensen säger "Defaults to an empty string in
		Studio". Tomhetstestet ensamt släppte igenom «· 00000000» som om
		det vore ett serverinstans-id. ]]
	game.JobId = "00000000-0000-0000-0000-000000000000"
	prova("en nollställd JobId räknas som ingen session",
		rad(Byggidentitet.rader(), "bygg.miljo") == Sprak.t("bygg.server"),
		tostring(rad(Byggidentitet.rader(), "bygg.miljo")))

	game.JobId = "4037a608-9d4e-4f83-97fa-993b0afc76a6"
	local m = rad(Byggidentitet.rader(), "bygg.miljo")
	prova("en riktig JobId namnger sessionen",
		m == Sprak.t("bygg.server") .. " · 4037a608", tostring(m))

	game.PlaceId, game.PlaceVersion, game.JobId = foreP, foreV, foreJ
end

--[[ ══ 3. LIVSCYKELN ══════════════════════════════════════════════ ]]
print("\n── 3. Livscykeln: en yta, släckt tills man ber om den ──")

local function ytor(namn)
	local n = 0
	local pg = player:FindFirstChildOfClass("PlayerGui")
	for _, b in ipairs(pg and pg._barn or {}) do
		if b.Name == namn then n += 1 end
	end
	return n
end

do
	Byggidentitet._nollstallForProv()
	Byggidentitet.start()
	prova("knappen byggdes", Byggidentitet._knapp() ~= nil)
	prova("panelen byggdes", Byggidentitet._panel() ~= nil)

	--[[ SLÄCKT SOM UTGÅNGSLÄGE. En släckt ScreenGui tar inga träffar
		alls — det är skillnaden mot en osynlig ram, och det är kravet
		om att vyn inte får fånga styrning när den är stängd. ]]
	prova("panelen är släckt tills man ber om den",
		Byggidentitet._panelGui().Enabled == false)
	prova("och synlig() håller med", Byggidentitet.synlig() == false)

	--[[ Två `start` ska ge EN yta. Det är respawnfallet: `ResetOnSpawn =
		false` gör att ytan överlever, och en andra `start` får inte lägga
		en till ovanpå. ]]
	local foreKnapp = ytor("UBRFByggidentitetKnapp")
	local forePanel = ytor("UBRFByggidentitet")
	Byggidentitet.start()
	Byggidentitet.start()
	prova("tre start ger en knappyta", ytor("UBRFByggidentitetKnapp") == foreKnapp,
		("%d"):format(ytor("UBRFByggidentitetKnapp")))
	prova("och en panelyta", ytor("UBRFByggidentitet") == forePanel,
		("%d"):format(ytor("UBRFByggidentitet")))
	prova("ytorna överlever respawn",
		Byggidentitet._panelGui().ResetOnSpawn == false)
end

do
	--[[ Öppna, stänga, växla — och knappen som göms medan panelen står
		uppe, så att två reglage för samma sak inte ligger framme. ]]
	Byggidentitet.visa()
	prova("visa() tänder panelen", Byggidentitet.synlig() == true)
	prova("och knappen göms medan den står uppe",
		Byggidentitet._knapp().Visible == false)

	--[[ STÄNGKNAPPEN MÅSTE GÅ ATT TRÄFFA MED EN TUMME. En panel som
		bara går att öppna är en engångsruta — exakt felet #153
		rapporterade som P2-4b, och golvet står i KONTROLLMATRIS regel
		5. Mätt på knappen själv, inte på avsikten. ]]
	local stang = nil
	for _, b in ipairs(Byggidentitet._panel()._barn or {}) do
		if b.Name == "StangBygg" then stang = b end
	end
	prova("stängknappen finns", stang ~= nil)
	prova("och är minst 44 px hög",
		stang ~= nil and stang.Size.Y.Offset >= 44,
		stang and ("%d×%d"):format(stang.Size.X.Offset, stang.Size.Y.Offset))

	Byggidentitet.dolj()
	prova("dolj() släcker panelen", Byggidentitet.synlig() == false)
	prova("och knappen är tillbaka", Byggidentitet._knapp().Visible == true)

	Byggidentitet.vaxla()
	prova("vaxla() öppnar", Byggidentitet.synlig() == true)
	Byggidentitet.vaxla()
	prova("vaxla() stänger", Byggidentitet.synlig() == false)
end

do
	--[[ Hashväxlingen: hela hashen ska gå att läsa av utan rättigheter,
		och panelen ska falla tillbaka till kort när den stängs — så att
		två skärmbilder ur QA går att jämföra. ]]
	Byggidentitet.visa()
	local knapp = nil
	for _, b in ipairs(Byggidentitet._panel()._barn or {}) do
		if b.Name == "HashVaxel" then knapp = b end
	end
	prova("hela raden är knappen som fäller ut hashen", knapp ~= nil)
	if knapp then
		knapp.Activated:Fire()
		prova("ett tryck ger hela hashen",
			rad(Byggidentitet.rader(), "bygg.kallhash") == AKTA.kallhash,
			("%d tecken"):format(#rad(Byggidentitet.rader(), "bygg.kallhash")))
		Byggidentitet.dolj()
		prova("stängningen fäller ihop den igen",
			rad(Byggidentitet.rader(), "bygg.kallhash") == AKTA.kallhash:sub(1, 12))
	end
end

--[[ ══ 4. LAYOUTEN ═════════════════════════════════════════════════ ]]
print("\n── 4. Knappen på riktiga skärmar ──")

local SKARMAR = {
	{ namn = "telefon 749×367 landskap", W = 749, H = 367 },
	{ namn = "telefon 844×390 landskap", W = 844, H = 390 },
	{ namn = "liten telefon 568×320 landskap", W = 568, H = 320 },
	{ namn = "iPad landskap 1024×768", W = 1024, H = 768 },
}

local foreVp = cam.ViewportSize
local foreTouch = UIS.TouchEnabled
UIS.TouchEnabled = true

for _, sk in ipairs(SKARMAR) do
	local W, H = sk.W, sk.H
	cam.ViewportSize = { _typ = "Vector2", X = W, Y = H }
	print(("\n  %s (topbar %d px)"):format(sk.namn, inset()))

	Byggidentitet._nollstallForProv()
	Byggidentitet.start()
	local b = Byggidentitet._knapp()
	local r = rekt(b, W, H - inset(), inset())

	prova("knappen är minst 44 px", b.Size.X.Offset >= 44 and b.Size.Y.Offset >= 44,
		("%d×%d"):format(b.Size.X.Offset, b.Size.Y.Offset))
	prova("knappen ligger helt på skärmen",
		r.x0 >= 0 and r.y0 >= 0 and r.x1 <= W and r.y1 <= H, r2s(r))

	--[[ Hjälpknappens band är 12..60 i GUI-pixlar. Identitetsknappen ska
		börja UNDER det, så att `?` kan tändas igen (MINIMAL_UI) utan att
		de två hamnar på varandra. Ingen befintlig yta flyttas. ]]
	local hjalpband = { x0 = 0, x1 = W, y0 = inset() + 12, y1 = inset() + 12 + 48 }
	prova("knappen ligger under hjälpknappens band",
		not skar(r, hjalpband), ("%s mot band y %d..%d"):format(
			r2s(r), hjalpband.y0, hjalpband.y1))

	--[[ Panelen ska få plats. På 568×320 är det 284 GUI-pixlar, och
		panelen är räknad mot exakt det. ]]
	Byggidentitet.visa()
	local pr = rekt(Byggidentitet._panel(), W, H - inset(), inset())
	prova("panelen får plats på skärmen",
		pr.x0 >= 0 and pr.y0 >= 0 and pr.x1 <= W and pr.y1 <= H, r2s(pr))
	Byggidentitet.dolj()
end

print("\n── 4b. Knappen viker undan för pekreglagen ──")
do
	cam.ViewportSize = { _typ = "Vector2", X = 568, Y = 320 }
	Byggidentitet._nollstallForProv()
	Byggidentitet.start()
	local W, H = 568, 320

	--[[ REPRODUKTIONEN: en reserv som når HELA vägen upp i knappens band.
		Utan undanvikningen hade knappen legat i den. Talen matas in som
		`TouchControls` rapporterar dem, genom samma publika kontrakt. ]]
	local fore = rekt(Byggidentitet._knapp(), W, H - inset(), inset())
	local reserv = { x0 = W - 120, x1 = W, y0 = inset(), y1 = H }
	prova("reproduktionen: utan undanvikning låg knappen i reserven",
		skar(fore, reserv), ("%s mot %s"):format(r2s(fore), r2s(reserv)))

	Byggidentitet.reservAndrad(120, 0)
	local efter = rekt(Byggidentitet._knapp(), W, H - inset(), inset())
	prova("efter rapporten ligger knappen fri från reserven",
		not skar(efter, reserv), ("%s mot %s"):format(r2s(efter), r2s(reserv)))
	prova("och fortfarande helt på skärmen",
		efter.x0 >= 0 and efter.x1 <= W, r2s(efter))

	--[[ EN BRED RESERV SOM BÖRJAR UNDER KNAPPENS BAND ska INTE flytta
		knappen. Det är den andra halvan av regeln, och den saknades:
		falsifieringen visade att `if true then` — alltså vik alltid
		undan — kom ut grön, eftersom en reserv med bredd 0 råkar ge
		samma x som hörnet. Med bredd 200 skiljer de sig med 200 px.

		Reglagen börjar långt under hörnet på en iPad, och där ska
		knappen stå kvar pixel för pixel. ]]
	Byggidentitet.reservAndrad(200, 250)
	local under = rekt(Byggidentitet._knapp(), W, H - inset(), inset())
	prova("en reserv UNDER bandet flyttar inte knappen",
		under.x1 == fore.x1 and under.y0 == fore.y0,
		("%s mot hörnet %s"):format(r2s(under), r2s(fore)))

	--[[ Reserven försvinner vid avsittning: hörnet ska komma tillbaka. ]]
	Byggidentitet.reservAndrad(0, math.huge)
	local ater = rekt(Byggidentitet._knapp(), W, H - inset(), inset())
	prova("när reglagen rivs får knappen hörnet tillbaka",
		ater.x1 == fore.x1 and ater.y0 == fore.y0, r2s(ater))
end

cam.ViewportSize = foreVp
UIS.TouchEnabled = foreTouch

--[[ ══ 5. SPRÅKET ══════════════════════════════════════════════════ ]]
print("\n── 5. Raderna finns på båda språken ──")
do
	local nycklar = { "bygg.rubrik", "bygg.stang", "bygg.okand", "bygg.kallhash",
		"bygg.kallor", "bygg.lage", "bygg.genererad", "bygg.plats",
		"bygg.version", "bygg.miljo", "bygg.opublicerad", "bygg.studio",
		"bygg.server" }
	local saknas = {}
	for _, n in ipairs(nycklar) do
		if not Sprak.finns(n) then table.insert(saknas, n) end
	end
	prova("varje nyckel finns i språkkanonen", #saknas == 0, table.concat(saknas, ", "))

	--[[ Och de skiljer sig mellan språken där de ska. `Version` och
		`Studio` är samma ord i båda — de räknas inte. ]]
	Sprak.satLocale("sv-se")
	local sv = Sprak.t("bygg.rubrik") .. "|" .. Sprak.t("bygg.okand")
	Sprak.satLocale("en-us")
	local en = Sprak.t("bygg.rubrik") .. "|" .. Sprak.t("bygg.okand")
	prova("svenska och engelska skiljer sig", sv ~= en, ("%s mot %s"):format(sv, en))
	Sprak.satLocale("sv-se")
end

if fel > 0 then
	print(("\nKLIENT-BYGGIDENTITET: %d fel"):format(fel))
	error(("%d fel"):format(fel))
end
--[[ Slutraden `kor.sh` letar efter. Sviten litar inte pa exitkoden
	ensam - en spec som kraschar innan den hunnit rakna ger ocksa
	noll FEL-rader, och sag darfor ut som gron. Se `kor.sh`. ]]
print("\nKLIENT-BYGGIDENTITET: alla gröna")
