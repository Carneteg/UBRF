--!nostrict
--[[
	TRÄNSET: WORLD -> HELD -> EQUIPPED (#235 FAS 3).

	Samma state-machine som sadeln, mot huvudet i stället för ryggen.
	Ordern säger uttryckligen «ingen separat speciallösning», och provet
	är skrivet för att kunna säga om det HÖLLS — inte bara om tränset
	råkar hamna rätt.

	TVÅ SAKER SKILJER TRÄNSET FRÅN SADELN, och båda är kanon:

	  1. ORDNINGEN. Tränset kommer SIST. En osadlad häst ska nekas med
	     `tack.sadeln_forst`, och det är inte en teknikalitet — man sadlar
	     först och tränsar sedan, för så gör man.
	  2. TYGLARNA följer med tränset. De sitter i bettet och är inget eget
	     moment i kanon; `leda` förutsätter dem («med tyglarna över
	     halsen»). Ett träns utan tyglar är inte det tillstånd spelet
	     påstår.

	MÄTT GENOM PRODUKTIONENS EGEN VÄG hela kedjan: `TackForradService`
	bygger upphängningen, `valjEn` är hämtningens mottagare, `sadla` och
	`transa` är de två påsättningarna. Ingen stubbad mottagare.

	VAD SOM INTE MÄTS: hur det ser ut, och om ett finger på en riktig
	iPhone eller iPad når fram. Det är Tobias fysiska gate.

	Kör: python3 roblox/tests/build.py tests/tack-fas3.spec.luau
	     && luau roblox/tests/.build/tack-fas3.spec.luau
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
local CollectionService = game:GetService("CollectionService")
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

local HAST = ordning[1]
local MODELL = HAST and hastar[HAST]
local FRONT = HAST and TackForradService.forHast(HAST)

print("\n── Förutsättningar ──")

check("det finns en häst med front och rigg", MODELL ~= nil, tostring(HAST))
if not MODELL then
	print("\nFAS 3 kan inte mätas utan en tränsbar häst.")
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error("ingen tränsbar häst", 0)
end

local vidFront = FRONT.PrimaryPart.Position
local vidHast = (MODELL.PrimaryPart or MODELL:FindFirstChildWhichIsA("BasePart")).Position

print("\n── Upphängningen har nu TVÅ prompter, med skilda tangenter ──")

do
	local funna = {}
	for _, d in ipairs(FRONT:GetDescendants()) do
		if d:IsA("ProximityPrompt") then funna[d.Name] = d end
	end
	check("sadelns prompt finns kvar", funna.SadelPrompt ~= nil)
	check("och tränset har fått sin egen", funna.TransPrompt ~= nil)

	if funna.SadelPrompt and funna.TransPrompt then
		--[[ DET HÄR ÄR PROVET SOM FAS 3 KRÄVER. Båda hänger på samma front
			och är inom räckhåll samtidigt. Delade de Roblox standardvärde
			hade vi byggt precis det #235 rapporterade: flera prompter i
			djupet där bara den närmaste går att nå. ]]
		--[[ SADELN BEHÅLLER Roblox standardvärde (`E` / `ButtonX`), alltså
			nil i källan. Det räcker därför INTE att jämföra de två med
			varandra — `nil ~= T` hade varit sant även om tränset också
			lämnats odefinierat. Provet kräver att tränsets tangenter är
			UTTRYCKLIGT satta, och sedan att de skiljer sig. ]]
		check("tränsets tangent är uttryckligen satt till T",
			funna.TransPrompt.KeyboardKeyCode == Enum.KeyCode.T,
			tostring(funna.TransPrompt.KeyboardKeyCode))
		check("och handkontrollsknappen till ButtonB",
			funna.TransPrompt.GamepadKeyCode == Enum.KeyCode.ButtonB,
			tostring(funna.TransPrompt.GamepadKeyCode))
		check("de delar därmed INTE tangent med sadeln",
			funna.SadelPrompt.KeyboardKeyCode ~= funna.TransPrompt.KeyboardKeyCode
				and funna.SadelPrompt.GamepadKeyCode ~= funna.TransPrompt.GamepadKeyCode,
			("%s/%s vs %s/%s"):format(
				tostring(funna.SadelPrompt.KeyboardKeyCode),
				tostring(funna.SadelPrompt.GamepadKeyCode),
				tostring(funna.TransPrompt.KeyboardKeyCode),
				tostring(funna.TransPrompt.GamepadKeyCode)))
		check("båda går att trycka på med ett finger",
			funna.SadelPrompt.ClickablePrompt == true
				and funna.TransPrompt.ClickablePrompt == true)
		--[[ Raderna måste gå att skilja åt i närområdets lista. Samma
			objekt på båda hade gett två rader som läser lika. ]]
		check("de två raderna säger olika saker",
			funna.TransPrompt.ObjectText ~= ""
				and funna.TransPrompt.ObjectText ~= funna.SadelPrompt.ObjectText,
			("%s | %s"):format(funna.SadelPrompt.ObjectText,
				funna.TransPrompt.ObjectText))
	end
end

print("\n── WORLD -> HELD: tränset hämtas för sig ──")

local spelare, karaktar, rot = nySpelare("Fas3", 9501, vidFront + Vector3.new(2, 0, 0))
Players._spelare = { spelare }

do
	check("tränset hänger på fronten innan hon tar det",
		TackForradService.paFronten(HAST, "trans") == true)

	local ok, skal = TackForradService.tagTrans(spelare, HAST, "Hon")
	check("«Ta tränset» går igenom", ok == true, tostring(skal))
	check("hon bär tränset", TackService.barBuren(spelare, "trans") == HAST)
	check("och det LÄMNADE fronten visuellt",
		TackForradService.paFronten(HAST, "trans") == false)

	--[[ SADELN HÄNGER KVAR. Hämtningarna är skilda åt — det var hela
		FAS 1:s poäng, och den får inte tappas nu när tränset kom. ]]
	check("sadeln hänger kvar på sin krok — hämtningarna är skilda",
		TackForradService.paFronten(HAST, "sadel") == true)
	check("och hon bär ingen sadel ännu",
		TackService.barBuren(spelare, "sadel") == nil)

	local buret = TackRigg.hittaBuren(karaktar, "trans")
	check("det finns ett FYSISKT buret träns", buret ~= nil,
		buret and buret.Name or "inget")
	if buret then
		check("oankrat, kolliderar inte, masslöst",
			buret.Anchored == false and buret.CanCollide == false
				and buret.Massless == true)
		check("och hållet av en WeldConstraint, inte av en loop",
			buret:FindFirstChildOfClass("WeldConstraint") ~= nil)
	end
end

print("\n── Kanonordningen: tränset kan inte komma före sadeln ──")

do
	rot.CFrame = CFrame.new(vidHast + Vector3.new(2, 0, 0))
	check("hästen är osadlad", TackService.sadlad(MODELL) == false)

	local ok, skal = GameplayService.transa(spelare, MODELL)
	check("«Tränsa» nekas på en osadlad häst", ok == false, tostring(skal))
	check("och nejet säger att sadeln kommer först",
		skal == "tack.sadeln_forst", tostring(skal))

	--[[ OCH INGENTING HANN HÄNDA. ]]
	check("hon är inte tränsad", TackService.transad(MODELL) == false)
	check("tränset ligger kvar i händerna",
		TackService.barBuren(spelare, "trans") == HAST)
	check("och inga tyglar byggdes i smyg",
		TackService.harTack(MODELL, "tygel") == false)
end

print("\n── HELD -> EQUIPPED: sadeln först, sedan tränset ──")

do
	--[[ Hon går tillbaka, hämtar sadeln och sadlar — FAS 1 och FAS 2 i
		produktionens egen ordning — och tränsar sedan. ]]
	rot.CFrame = CFrame.new(vidFront + Vector3.new(2, 0, 0))
	check("hon hämtar sadeln också",
		TackForradService.tagSadel(spelare, HAST, "Hon") == true)
	check("och bär nu BÅDA delarna",
		TackService.barBuren(spelare, "sadel") == HAST
			and TackService.barBuren(spelare, "trans") == HAST)

	rot.CFrame = CFrame.new(vidHast + Vector3.new(2, 0, 0))
	check("sadlingen går igenom", GameplayService.sadla(spelare, MODELL) == true)
	check("hon är sadlad", TackService.sadlad(MODELL) == true)

	local ok, skal = GameplayService.transa(spelare, MODELL)
	check("«Tränsa» går igenom nu", ok == true, tostring(skal))

	check("tränset sitter FYSISKT på hästen",
		TackService.transad(MODELL) == true)
	check("och TYGLARNA följde med — «leda» förutsätter dem",
		TackService.harTack(MODELL, "tygel") == true,
		tostring(TackService.harTack(MODELL, "tygel")))
	check("delen är svetsad i hästriggen",
		TackRigg.hittaDel(MODELL, "trans") ~= nil)

	--[[ INGEN DUBBLETT, samma krav som sadeln. ]]
	check("tränset är BORTA ur händerna",
		TackRigg.hittaBuren(karaktar, "trans") == nil,
		tostring(TackRigg.hittaBuren(karaktar, "trans")))
	check("och hänger INTE tillbaka på fronten",
		TackForradService.paFronten(HAST, "trans") == false)
	check("ägarposten är släppt",
		GameplayService.barasAv("trans", HAST) == nil,
		tostring(GameplayService.barasAv("trans", HAST)))

	--[[ OCH DÅ ÄR HON RIDKLAR. Det är FAS 3:s egentliga kvitto: kedjan
		sadel + träns är hela förutsättningen för att sitta upp. ]]
	local redo, varfor = TackService.ridklar(MODELL)
	check("hon är RIDKLAR — kedjan är hel", redo == true, tostring(varfor))
end

print("\n── Spam och tomma händer ──")

do
	local ok, skal = GameplayService.transa(spelare, MODELL)
	check("ett andra «Tränsa» nekas", ok == false, tostring(skal))
	check("och nejet säger att händerna är tomma",
		skal == "tack.bar_inget_trans", tostring(skal))
	check("hon bär fortfarande exakt ett träns på huvudet",
		TackService.transad(MODELL) == true)

	--[[ Den andra spärren — dubbel påsättning — nås genom att lägga
		tillbaka ett buret träns, samma väg FAS 1 bygger det. Utan det
		vore `tack.redan_pa` en gren ingen mätning rörde. ]]
	TackService.satBuren(spelare, "trans", HAST)
	local ok2, skal2 = GameplayService.transa(spelare, MODELL)
	check("en redan tränsad häst nekar ett till", ok2 == false, tostring(skal2))
	check("och nejet säger att det redan sitter på",
		skal2 == "tack.redan_pa", tostring(skal2))
	GameplayService.slappBuret(spelare)
	check("städningen tände inte fronten — tränset är hästens nu",
		TackForradService.paFronten(HAST, "trans") == false)
end

print("\n── Tomma kroken präglar inget nytt träns ──")

do
	local sen, karSen = nySpelare("Fas3b", 9502, vidFront + Vector3.new(2, 0, 0))
	Players._spelare = { sen }
	local ok, skal = TackForradService.tagTrans(sen, HAST, "Hon")
	check("en hämtning från den tomma tränskroken nekas", ok == false, tostring(skal))
	check("och nejet säger varför", skal == "tack.inte_pa_fronten", tostring(skal))
	check("inget andra träns uppstod",
		TackRigg.hittaBuren(karSen, "trans") == nil)
end

print("\n── Fel träns, för långt bort, och hästens tillstånd ──")

do
	local kallaId, felId = ordning[2], ordning[3]
	check("det finns två andra hästar att prova mot",
		kallaId ~= nil and felId ~= nil,
		("%s -> %s"):format(tostring(kallaId), tostring(felId)))

	if kallaId and felId then
		local kallFront = TackForradService.forHast(kallaId).PrimaryPart.Position
		local hon, karHon, rotHon = nySpelare("Fas3c", 9503, kallFront + Vector3.new(2, 0, 0))
		Players._spelare = { hon }
		check("hon hämtar EN hästs träns",
			TackForradService.tagTrans(hon, kallaId, "Hon") == true)

		--[[ FEL HÄST. Samma pedagogik som sadeln: att kunna ta fel är
			poängen, och felet ska räknas. ]]
		local felModell = hastar[felId]
		local felPos = (felModell.PrimaryPart
			or felModell:FindFirstChildWhichIsA("BasePart")).Position
		rotHon.CFrame = CFrame.new(felPos + Vector3.new(2, 0, 0))
		local fore = TackService.felAntal(hon)
		local ok, skal = GameplayService.transa(hon, felModell)
		check("fel hästs träns nekas", ok == false, tostring(skal))
		check("och nejet säger att det är FEL TRÄNS",
			skal == "tack.fel_trans", tostring(skal))
		check("felet räknas", TackService.felAntal(hon) == fore + 1,
			("%d -> %d"):format(fore, TackService.felAntal(hon)))
		check("fel häst fick inget träns",
			TackService.transad(felModell) == false)
		check("och inga tyglar heller",
			TackService.harTack(felModell, "tygel") == false)

		--[[ FÖR LÅNGT BORT.

			HÄSTEN MÅSTE VARA SADLAD FÖRST, annars kommer nejet från
			kanonordningen (`tack.sadeln_forst`) och provet mäter fel
			regel. Första versionen av den här mätningen gjorde precis
			det: den var grön, och sa ingenting om avståndet. ]]
		local kallModell = hastar[kallaId]
		local kallPos = (kallModell.PrimaryPart
			or kallModell:FindFirstChildWhichIsA("BasePart")).Position
		rotHon.CFrame = CFrame.new(kallFront + Vector3.new(2, 0, 0))
		check("hon hämtar hennes sadel också",
			TackForradService.tagSadel(hon, kallaId, "Hon") == true)
		rotHon.CFrame = CFrame.new(kallPos + Vector3.new(2, 0, 0))
		check("och sadlar henne", GameplayService.sadla(hon, kallModell) == true)

		rotHon.CFrame = CFrame.new(kallPos + Vector3.new(400, 0, 0))
		local ok2, skal2 = GameplayService.transa(hon, kallModell)
		check("en tränsning från andra sidan gården nekas", ok2 == false,
			tostring(skal2))
		check("och nejet kommer från AVSTÅNDET, inte från ordningen",
			skal2 == "tack.for_langt", tostring(skal2))
		check("tränset ligger kvar i händerna",
			TackService.barBuren(hon, "trans") == kallaId)
		check("och hon är fortfarande otränsad",
			TackService.transad(kallModell) == false)

		--[[ HÄSTENS EGET TILLSTÅND. Samma grind som sadeln fick i
			reviewen av `e08515f`, och den ska gälla lika hårt här. ]]
		rotHon.CFrame = CFrame.new(kallPos + Vector3.new(2, 0, 0))
		local okLed = LedService.borja(hon, kallModell, kallModell)
		check("ledningen startar", okLed == true)
		local ok3, skal3 = GameplayService.transa(hon, kallModell)
		check("en häst som LEDS går inte att tränsa", ok3 == false, tostring(skal3))
		check("och nejet säger varför", skal3 == "tack.leds_nu", tostring(skal3))
		check("leds: inga tyglar hann byggas",
			TackService.harTack(kallModell, "tygel") == false)
		check("leds: tränset ligger kvar i händerna",
			TackService.barBuren(hon, "trans") == kallaId)
		LedService.slapp(hon)

		HorseService._registerForProv(kallModell)
		local sess = HorseService.sessionFor(kallModell)
		check("hästen har en session", sess ~= nil)
		if sess then
			sess.rider = hon
			local ok4, skal4 = GameplayService.transa(hon, kallModell)
			check("en häst som RIDS går inte att tränsa", ok4 == false, tostring(skal4))
			check("och nejet säger varför", skal4 == "tack.rids_nu", tostring(skal4))
			check("rids: tränset ligger kvar i händerna",
				TackService.barBuren(hon, "trans") == kallaId)
			sess.rider = nil
		end
		GameplayService.slappBuret(hon)
	end
end

print("\n── Reset och disconnect efter en LYCKAD tränsning ──")

do
	Players._spelare = { spelare }
	Players.PlayerRemoving:Fire(spelare)
	task.wait()

	check("hästen är fortfarande tränsad — tränset följer inte spelaren ut",
		TackService.transad(MODELL) == true)
	check("och fortfarande sadlad", TackService.sadlad(MODELL) == true)
	check("tränskroken står fortfarande tom",
		TackForradService.paFronten(HAST, "trans") == false)
	check("och registret har ingen stale ägarpost",
		GameplayService.barasAv("trans", HAST) == nil,
		tostring(GameplayService.barasAv("trans", HAST)))
end

RunService._server = false

if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("\ntack-fas3.spec: alla gröna")
end
