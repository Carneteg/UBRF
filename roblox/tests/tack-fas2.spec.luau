--!nostrict
--[[
	SADELN: HELD -> EQUIPPED (#235 FAS 2).

	FAS 1 lämnade spelaren med en sadel i händerna och ingen väg att lägga
	den på hästen. Det här provet mäter den vägen, och bara den. Tränset
	hör till FAS 3 och ledningen till FAS 4 — båda ska ligga orörda när
	provet är klart, och det mäts.

	MÄTT GENOM PRODUKTIONENS EGEN VÄG: `TackForradService` bygger
	upphängningen, `GameplayService.valjEn` är FAS 1:s mottagare,
	`GameplayService.sadla` är FAS 2:s handling, och `TackService`/
	`TackRigg` gör den fysiska delen. Ingen avskrift, ingen stubbad
	mottagare, ingen genväg förbi servern.

	FALSIFIERINGSFALLEN kommer ur arkitekturorderns egen lista, de som
	gäller den här fasen:

	  · fel häst              — A:s sadel på B ska nekas OCH räknas
	  · redan utrustad häst   — dubbel påsättning ska nekas
	  · för långt bort        — servern äger avståndet
	  · spam                  — två tryck får inte ge två sadlar
	  · bär ingenting         — «Sadla» utan sadel i händerna
	  · orphan/duplikat       — ingen sadel kvar hos spelaren ELLER på
	                            boxfronten efter en lyckad sadling
	  · reset/disconnect      — ingen låst front, inget stale ägarskap

	VAD SOM INTE MÄTS: hur det ser ut, och om ett finger på en riktig
	iPhone eller iPad når fram. Det är Tobias fysiska gate och står som
	sådan i rapporten. Ingen automatisk mätning här är ett FAS 2 PASS.

	Kör: python3 roblox/tests/build.py tests/tack-fas2.spec.luau
	     && luau roblox/tests/.build/tack-fas2.spec.luau
]]

local fails = 0
local function check(namn, villkor, detalj)
	if villkor then
		print(string.format("  OK   %s%s", namn, detalj and ("  " .. detalj) or ""))
	else
		fails += 1
		print(string.format("  FEL  %s%s", namn, detalj and ("  " .. detalj) or ""))
	end
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
RunService._server = true

local function nyKaraktar(pos)
	local k = Instance.new("Model")
	k.Name = "Karaktar"
	local rot = Instance.new("Part")
	rot.Name = "HumanoidRootPart"
	rot.Size = Vector3.new(2, 2, 1)
	rot.CFrame = CFrame.new(pos)
	rot.Parent = k
	local torso = Instance.new("Part")
	torso.Name = "UpperTorso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.CFrame = CFrame.new(pos)
	torso.Parent = k
	local hum = Instance.new("Humanoid")
	hum.Name = "Humanoid"
	hum.Parent = k
	k.Parent = workspace
	return k, rot
end

local function nySpelare(namn, userId, pos)
	local k, rot = nyKaraktar(pos)
	return { Name = namn, UserId = userId, Character = k,
		CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }, k, rot
end

TackForradService.start(GameplayService.valjEn)
GameplayService.start()

--[[ Hästen provet arbetar med, och en riktig hästmodell att sadla.

	`Anlaggningen` har byggt boxfronterna; hästmodellerna är taggade
	`Horse` och bär `HorseId`. Provet letar upp den häst vars front det
	redan känner, i stället för att bygga en egen — en egen hade mätt
	provets rigg i stället för spelets. ]]
local CollectionService = game:GetService("CollectionService")

--[[ Hästarna byggs med PRODUKTIONENS egen rigg (`HastRigg.bygg`), inte
	med en provattrapp. Det är den riggen `RigAdapter` läser och som
	`TackRigg` svetsar i — en egen modell hade mätt provets kropp i
	stället för spelets, och sadelpunkten är hela poängen här.

	Anläggningen bygger boxfronterna men inga hästar; de strömmas in i
	riktig körning. Provet ställer dem därför vid sin egen front, precis
	som de står i stallet. ]]
local hastar: { [string]: Model } = {}
local ordning: { string } = {}
do
	local mapp = TackForradService.mapp()
	if mapp then
		for _, f in ipairs(mapp:GetChildren()) do
			local id = f:IsA("Model") and tostring(f:GetAttribute("ForHast") or "")
			if id and id ~= "" and f.PrimaryPart and hastar[id] == nil then
				local m = HastRigg.bygg(id, id, CFrame.new(f.PrimaryPart.Position
					+ Vector3.new(0, 0, 6)))
				if m then
					m.Parent = workspace
					m:SetAttribute("HorseId", id)
					CollectionService:AddTag(m, "Horse")
					hastar[id] = m
					table.insert(ordning, id)
				end
			end
			if #ordning >= 4 then break end
		end
	end
end

local HAST, MODELL, FRONT
if ordning[1] then
	HAST = ordning[1]
	MODELL = hastar[HAST]
	FRONT = TackForradService.forHast(HAST)
end

print("\n── Förutsättningarna: en häst med både front och rigg ──")

check("det finns en häst med boxfront OCH modell i världen", HAST ~= nil,
	tostring(HAST))
if not HAST then
	print("\nFAS 2 kan inte mätas utan en sadlingsbar häst.")
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error("ingen sadlingsbar häst", 0)
end

--[[ Var spelaren ska stå för att BÅDE nå fronten och hästen. Fronten
	avgör FAS 1:s avstånd, hästen FAS 2:s — de är olika prov i olika
	tjänster, och båda är serverns. ]]
local vidFront = FRONT.PrimaryPart.Position
local vidHast = (MODELL.PrimaryPart or MODELL:FindFirstChildWhichIsA("BasePart")).Position

--[[ ETT NEJ FÅR INTE LÄMNA SPÅR — FAS 2:s version.

	Samma regel som FAS 1:s `ingetSpar`, men spegelvänd: här är det inte
	hämtningen som ska vara orörd utan HÄSTEN. Ett halvt utfört
	`HELD -> EQUIPPED` är värre än ett rent nej. ]]
local function hastenOrord(karaktar, modell, hastId, varfor)
	check(varfor .. ": hästen är fortfarande osadlad",
		TackService.sadlad(modell) == false)
	check(varfor .. ": sadeln är kvar i spelarens händer",
		TackService.barBuren({ Character = karaktar }, "sadel") ~= nil
			or TackRigg.hittaBuren(karaktar, "sadel") ~= nil,
		tostring(TackRigg.hittaBuren(karaktar, "sadel")))
	check(varfor .. ": ingenting hänger tillbaka på boxfronten",
		TackForradService.paFronten(hastId, "sadel") == false)
end

print("\n── Kedjan: hämta, gå till hästen, sadla ──")

local spelare, karaktar, rot = nySpelare("Fas2", 9401, vidFront + Vector3.new(2, 0, 0))
Players._spelare = { spelare }

do
	local ok1, skal1 = TackForradService.tagSadel(spelare, HAST, "Hon")
	check("FAS 1 först: sadeln hamnar i händerna", ok1 == true, tostring(skal1))
	check("och hon bär den", TackService.barBuren(spelare, "sadel") == HAST)
	check("fronten är tom", TackForradService.paFronten(HAST, "sadel") == false)
	check("hästen är ännu INTE sadlad", TackService.sadlad(MODELL) == false)

	--[[ HON GÅR TILL HÄSTEN. Utan flytten nekas hon av FAS 2:s eget
		avståndsprov, och provet hade mätt fel regel. ]]
	rot.CFrame = CFrame.new(vidHast + Vector3.new(2, 0, 0))

	local ok2, skal2 = GameplayService.sadla(spelare, MODELL)
	check("«Sadla» går igenom", ok2 == true, tostring(skal2))

	--[[ OCH OM DEN INTE GICK IGENOM får den inte ha lämnat halvfärdigt
		arbete efter sig. Det enda som kan falla mellan underlägget och
		sadeln är själva bygget, och den vägen går inte att nå inifrån
		världen — den provas genom mutation (G12), och det är HÄR nätet
		sitter.

		DET VAR MIN EGEN FALSIFIERING SOM KRÄVDE DET: mutationen som tog
		bort rollbacken kom först ut GRÖN, eftersom ingen mätning nådde
		grenen. En gren inget prov kan röra är ingen grind. ]]
	if not ok2 then
		check("bygget föll: inget underlägg ligger kvar på hästen",
			TackService.harTack(MODELL, "underlagg") == false,
			tostring(TackService.harTack(MODELL, "underlagg")))
		check("bygget föll: hästen är inte halvsadlad",
			TackService.sadlad(MODELL) == false)
		check("bygget föll: sadeln är tillbaka i spelarens händer",
			TackService.barBuren(spelare, "sadel") == HAST,
			tostring(TackService.barBuren(spelare, "sadel")))
	end

	--[[ DEN FYSISKA SANNINGEN, inte ett register. ]]
	check("sadeln ligger nu FYSISKT på hästen",
		TackService.sadlad(MODELL) == true)
	check("och underlägget under den — kanon lägger det först",
		TackService.harTack(MODELL, "underlagg") == true)
	check("delen är svetsad i hästriggen, inte lös",
		TackRigg.hittaDel(MODELL, "sadel") ~= nil)

	--[[ INGEN DUBBLETT. Ordern säger det rakt ut: ingen sadel får finnas
		kvar hos spelaren eller på boxfronten. ]]
	check("sadeln är BORTA ur spelarens händer",
		TackRigg.hittaBuren(karaktar, "sadel") == nil,
		tostring(TackRigg.hittaBuren(karaktar, "sadel")))
	check("och den hänger INTE tillbaka på boxfronten",
		TackForradService.paFronten(HAST, "sadel") == false)
	check("ägarposten är släppt — sadeln är hästens nu, inte frontens",
		GameplayService.barasAv("sadel", HAST) == nil,
		tostring(GameplayService.barasAv("sadel", HAST)))

	--[[ FAS 3 ÄR INTE PÅBÖRJAD. ]]
	check("tränset hänger kvar på kroken", TackForradService.paFronten(HAST, "trans") == true)
	check("och hästen är inte tränsad", TackService.transad(MODELL) == false)
end

print("\n── Spam: ett andra tryck får inte ge en andra sadel ──")

do
	--[[ FÖRSTA SPÄRREN är att händerna är tomma. Sadeln ligger på hästen,
		alltså finns det ingenting kvar att sadla MED — och det är den
		spärr ett andra tryck i verkligheten möter. ]]
	local ok, skal = GameplayService.sadla(spelare, MODELL)
	check("andra «Sadla» nekas", ok == false, tostring(skal))
	check("och nejet säger varför: händerna är tomma",
		skal == "tack.bar_ingen_sadel", tostring(skal))
	check("hästen bär fortfarande exakt en sadel",
		TackService.sadlad(MODELL) == true)
	check("och spelaren bär fortfarande ingen",
		TackRigg.hittaBuren(karaktar, "sadel") == nil)

	--[[ ANDRA SPÄRREN är dubbel påsättning, och den går inte att nå genom
		boxfronten: det finns EN sadel per häst, och den ligger nu på
		ryggen. Provet lägger därför tillbaka en buren sadel direkt genom
		`TackService.satBuren` — samma väg FAS 1 bygger den — för att nå
		spärren i stället för att anta att den håller.

		Utan det här hade `tack.redan_pa` varit en gren ingen mätning
		någonsin rörde. ]]
	TackService.satBuren(spelare, "sadel", HAST)
	check("hon står nu med en sadel i händerna igen",
		TackService.barBuren(spelare, "sadel") == HAST)
	local ok2, skal2 = GameplayService.sadla(spelare, MODELL)
	check("en redan sadlad häst nekar en till", ok2 == false, tostring(skal2))
	check("och nejet säger att den redan sitter på",
		skal2 == "tack.redan_pa", tostring(skal2))
	check("sadeln i händerna rördes inte av nejet",
		TackService.barBuren(spelare, "sadel") == HAST)
	GameplayService.slappBuret(spelare)
	check("och boxfronten tändes INTE av städningen — sadeln är hästens nu",
		TackForradService.paFronten(HAST, "sadel") == false)
end

print("\n── En tom krok präglar ingen ny sadel ──")

do
	--[[ FYNDET SOM FAS 2:s PROV GJORDE. FAS 1:s ägarregister skyddar mot
		att två spelare bär samma sadel, men inte mot att sadeln inte
		finns kvar att ta: när den flyttat till hästens rygg står kroken
		tom OCH ägarposten är släppt — och hämtningen släpptes igenom.
		Nästa spelare fick en andra sadel ur tomma luften, och då finns
		två sadlar för en häst som har en.

		Det är precis den duplicering FAS 2:s order förbjuder, och den
		gick inte att se förrän sadeln faktiskt kunde lämna fronten. ]]
	local sen, karSen = nySpelare("Fas2e", 9405, vidFront + Vector3.new(2, 0, 0))
	Players._spelare = { sen }

	check("kroken är tom — sadeln ligger på hästen",
		TackForradService.paFronten(HAST, "sadel") == false)
	local ok, skal = TackForradService.tagSadel(sen, HAST, "Hon")
	check("en hämtning från den tomma kroken nekas", ok == false, tostring(skal))
	check("och nejet säger varför", skal == "tack.inte_pa_fronten", tostring(skal))
	check("ingen andra sadel uppstod i händerna",
		TackRigg.hittaBuren(karSen, "sadel") == nil,
		tostring(TackRigg.hittaBuren(karSen, "sadel")))
	check("och hästen bär fortfarande sin enda sadel",
		TackService.sadlad(MODELL) == true)
end

print("\n── «Sadla» utan att bära någon sadel ──")

do
	local tom, karTom = nySpelare("Fas2b", 9402, vidHast + Vector3.new(2, 0, 0))
	Players._spelare = { spelare, tom }
	local ok, skal = GameplayService.sadla(tom, MODELL)
	check("den som inte bär något nekas", ok == false, tostring(skal))
	check("och nejet säger varför — inte «redan på»",
		skal == "tack.bar_ingen_sadel", tostring(skal))
end

print("\n── Fel häst: A:s sadel ska inte gå på B ──")

do
	--[[ ATT KUNNA TA FEL SADEL ÄR POÄNGEN. Webbens sadelkammare gör
		likadant, och felet ska RÄKNAS — inte bara nekas.

		Provet behöver TVÅ andra hästar: en vars sadel fortfarande hänger
		på kroken, och en helt annan att bära den till. Den första hästen
		duger inte som källa längre — hennes sadel ligger på ryggen, och
		kroken är tom sedan kedjan ovan. ]]
	local kallaId = ordning[2]
	local felId = ordning[3]
	check("det finns två andra hästar att korsa", kallaId ~= nil and felId ~= nil,
		("%s -> %s"):format(tostring(kallaId), tostring(felId)))

	if kallaId and felId then
		local kallFront = TackForradService.forHast(kallaId).PrimaryPart.Position
		local fel, karFel = nySpelare("Fas2c", 9403, kallFront + Vector3.new(2, 0, 0))
		Players._spelare = { fel }

		local okH = TackForradService.tagSadel(fel, kallaId, "Hon")
		check("hon hämtar EN hästs sadel", okH == true)

		--[[ OCH GÅR TILL EN ANNAN HÄST. ]]
		local felModell = hastar[felId]
		local felPos = (felModell.PrimaryPart
			or felModell:FindFirstChildWhichIsA("BasePart")).Position
		karFel:FindFirstChild("HumanoidRootPart").CFrame =
			CFrame.new(felPos + Vector3.new(2, 0, 0))

		local fore = TackService.felAntal(fel)
		local ok, skal = GameplayService.sadla(fel, felModell)
		check("fel hästs sadel nekas", ok == false, tostring(skal))
		check("och nejet säger att det är FEL SADEL",
			skal == "tack.fel_sadel", tostring(skal))
		check("felet RÄKNAS — det är ett lärandemoment, inte bara ett nej",
			TackService.felAntal(fel) == fore + 1,
			("%d -> %d"):format(fore, TackService.felAntal(fel)))

		--[[ OCH INGENTING HANN ÄNDRAS. Varken på fel häst eller i
			händerna. Inget underlägg får ha lagts på förhand — det är
			den halvan av transaktionen som är lättast att tappa. ]]
		check("fel häst är fortfarande osadlad",
			TackService.sadlad(felModell) == false)
		check("och har inte heller fått ett underlägg på förhand",
			TackService.harTack(felModell, "underlagg") == false)
		hastenOrord(karFel, felModell, kallaId, "fel häst")

		GameplayService.slappBuret(fel)
	end
end

print("\n── För långt bort: servern äger avståndet ──")

do
	local langt, karLangt, rotLangt = nySpelare("Fas2d", 9404, vidFront + Vector3.new(2, 0, 0))
	Players._spelare = { langt }

	--[[ Hon behöver en osadlad häst att sikta på. Den första är sadlad
		sedan kedjan ovan, så provet letar upp en ny — annars hade nejet
		kommit från `tack.redan_pa` och mätt fel regel. ]]
	local osadladId, osadladModell
	for _, m in ipairs(CollectionService:GetTagged("Horse")) do
		local id = m:IsA("Model") and tostring(m:GetAttribute("HorseId") or "")
		if id and id ~= "" and not TackService.sadlad(m)
			and TackForradService.forHast(id) then
			osadladId, osadladModell = id, m
			break
		end
	end
	check("det finns en osadlad häst med front att prova avståndet mot",
		osadladId ~= nil, tostring(osadladId))

	if osadladId then
		local frontPos = TackForradService.forHast(osadladId).PrimaryPart.Position
		rotLangt.CFrame = CFrame.new(frontPos + Vector3.new(2, 0, 0))
		local okH = TackForradService.tagSadel(langt, osadladId, "Hon")
		check("hon hämtar hennes sadel", okH == true)

		--[[ OCH GÅR TVÄRS ÖVER GÅRDEN. ]]
		rotLangt.CFrame = CFrame.new(frontPos + Vector3.new(400, 0, 0))
		local ok, skal = GameplayService.sadla(langt, osadladModell)
		check("en sadling från andra sidan gården nekas", ok == false, tostring(skal))
		check("och nejet säger att hon står för långt bort",
			skal == "tack.for_langt", tostring(skal))
		hastenOrord(karLangt, osadladModell, osadladId, "för långt bort")

		GameplayService.slappBuret(langt)
		check("och efter att hon lämnat tillbaka hänger sadeln på fronten igen",
			TackForradService.paFronten(osadladId, "sadel") == true)
	end
end

print("\n── Reset och disconnect efter en LYCKAD sadling ──")

do
	--[[ Sadeln ligger på hästen sedan kedjan ovan, och spelaren som la
		den där lämnar nu spelet. Registret får inte hålla kvar något, och
		fronten får INTE tändas igen — sadeln är hästens nu. ]]
	Players.PlayerRemoving:Fire(spelare)
	task.wait()

	check("hästen är fortfarande sadlad — sadeln följer inte spelaren ut",
		TackService.sadlad(MODELL) == true)
	check("boxfronten står fortfarande tom",
		TackForradService.paFronten(HAST, "sadel") == false)
	check("och registret har ingen stale ägarpost",
		GameplayService.barasAv("sadel", HAST) == nil,
		tostring(GameplayService.barasAv("sadel", HAST)))
end

RunService._server = false

if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("\ntack-fas2.spec: alla gröna")
end
