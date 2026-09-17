--!nostrict
--[[
	SADELN: WORLD -> HELD (#235 FAS 1).

	Tobias verifierade på fysisk iPhone att First Playable är ospelbart
	före ridning. ChatGPTs arkitekturorder delar arbetet i faser med stopp
	emellan, och FAS 1 är EN övergång: sadeln från boxfronten till
	spelarens händer. Tränset hör till FAS 3 och ska inte röras.

	DEN HÄR SPECEN MÄTER BARA DEN ÖVERGÅNGEN, och den mäter den genom
	produktionens egen väg: `TackForradService` bygger upphängningen,
	`GameplayService.valjEn` är mottagaren, `TackService`/`TackRigg` gör
	den fysiska delen. Ingen avskrift, ingen stubbad mottagare.

	FALSIFIERINGSFALLEN kommer ur reviewen, ordagrant:

	  · spam pickup            — två tryck får inte ge två sadlar
	  · två spelare samma sadel — den andra ska nekas
	  · för långt bort         — servern äger avståndet, inte prompten
	  · reset/disconnect       — ingen orphan weld, ingen låst sadel
	  · orphan state           — registret ska släppa
	  · tränset                — ska ligga kvar på kroken

	VAD SOM INTE MÄTS: hur det ser ut, och om ett finger på en riktig
	iPhone eller iPad når fram. Det är Tobias fysiska gate och står som
	sådan i rapporten. Ingen automatisk mätning här är ett FAS 1 PASS.

	Kör: python3 roblox/tests/build.py tests/tack-fas1.spec.luau
	     && luau roblox/tests/.build/tack-fas1.spec.luau
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

--[[ Världen som produktionen bygger den. `Anlaggningen` har redan körts i
	den här bänken; boxfronterna hängs av tjänsten själv. ]]
TackForradService.start(GameplayService.valjEn)

--[[ OCH PRODUKTIONENS EGEN UPPSTART. Utan den finns ingen koppling fran
	`Players.PlayerRemoving` till `glom`, och provet nedan hade mott
	registret sjalvt i stallet for den vag en spelare som stanger spelet
	faktiskt tar. ]]
GameplayService.start()

local HAST = "trixie"
local lage = TackForradService.lage(HAST)
local modell = TackForradService.forHast(HAST)
local vid = modell and modell.PrimaryPart and modell.PrimaryPart.Position
	or Vector3.new(0, 0, 0)

--[[ ETT NEJ FAR INTE LAMNA SPAR.

	Den gemensamma regeln bakom reviewens tre fynd. Sager servern nej ska
	varlden se ut exakt som innan: ingen sadel i handerna, ingen agare i
	registret, inget val i `valdUtrustning` — och, dar fronten finns kvar
	att titta pa, sadeln fortfarande synlig pa kroken.

	Ett halvt utfort `WORLD -> HELD` ar varre an ett rent nej, for resten
	av spelet laser sedan det halva som sanning. ]]
local function ingetSpar(vem, karaktar, hastId, varfor, frontKvar)
	check(varfor .. ": ingen buren sadel i handerna",
		TackRigg.hittaBuren(karaktar, "sadel") == nil,
		tostring(TackRigg.hittaBuren(karaktar, "sadel")))
	check(varfor .. ": ingen agare i registret",
		GameplayService.barasAv("sadel", hastId) == nil,
		tostring(GameplayService.barasAv("sadel", hastId)))
	local val = GameplayService.valdFor(vem)
	check(varfor .. ": inget val i valdUtrustning",
		val == nil or val.sadel == nil,
		tostring(val and val.sadel))
	if frontKvar then
		check(varfor .. ": sadeln hanger kvar pa fronten",
			TackForradService.paFronten(hastId, "sadel") == true)
	end
end

print("\n── Upphängningen är två grupper, inte sex lösa delar ──")

do
	check("hästens utrustning hänger på hennes front", modell ~= nil)
	local sadelgrupp, transgrupp
	if modell then
		for _, g in ipairs(modell:GetChildren()) do
			if g:IsA("Model") and g:GetAttribute("UBRFForrad") == "sadel" then sadelgrupp = g end
			if g:IsA("Model") and g:GetAttribute("UBRFForrad") == "trans" then transgrupp = g end
		end
	end
	check("sadeln är en egen grupp", sadelgrupp ~= nil)
	check("tränset är en egen grupp", transgrupp ~= nil)

	--[[ EN PROMPT, EN HANDLING. Fanns det två skulle FAS 1 och FAS 3 gå
		att göra i samma tryck igen. ]]
	local promptar = {}
	if modell then
		for _, d in ipairs(modell:GetDescendants()) do
			if d:IsA("ProximityPrompt") then table.insert(promptar, d.Name) end
		end
	end
	check("det finns exakt EN prompt på fronten — tränsets kommer i FAS 3",
		#promptar == 1 and promptar[1] == "SadelPrompt",
		table.concat(promptar, ", "))
end

print("\n── WORLD → HELD genom produktionens egen väg ──")

local spelare, karaktar, rot = nySpelare("Fas1", 9301, vid + Vector3.new(2, 0, 0))
Players._spelare = { spelare }

do
	check("sadeln hänger på fronten innan hon tar den",
		TackForradService.paFronten(HAST, "sadel") == true)
	check("och hon bär ingenting", TackService.barBuren(spelare, "sadel") == nil,
		tostring(TackService.barBuren(spelare, "sadel")))

	local ok, skal = TackForradService.tagSadel(spelare, HAST, "Trixie")
	check("«Ta sadeln» går igenom", ok == true, tostring(skal))

	--[[ OCH OM DEN INTE GICK IGENOM far den inte ha lamnat halvfardigt
		state efter sig. Reviewen bad uttryckligen om ett prov som tvingar
		`satBuren` att falla och kontrollerar att varken val, agarskap
		eller front hunnit andras. Den vagen gar inte att na inifran
		varlden — `satBuren` faller bara nar karaktaren saknas, och det
		nekas redan tidigare — sa den provas genom mutation (R5), och det
		ar HAR natet sitter. Tyst nar allt fungerar, rott nar bygget
		faller och nagot anda committats. ]]
	if not ok then
		ingetSpar(spelare, karaktar, HAST, "bygget foll", true)
	end

	check("sadeln bärs nu av spelaren, serverauktoritärt",
		TackService.barBuren(spelare, "sadel") == HAST,
		tostring(TackService.barBuren(spelare, "sadel")))
	check("och den LÄMNADE boxfronten visuellt",
		TackForradService.paFronten(HAST, "sadel") == false)

	--[[ TRÄNSET SKA LIGGA KVAR. Hela poängen med FAS 1. ]]
	check("tränset hänger kvar på kroken — FAS 3 är inte påbörjad",
		TackForradService.paFronten(HAST, "trans") == true)
	check("och hon bär inget träns",
		TackService.barBuren(spelare, "trans") == nil,
		tostring(TackService.barBuren(spelare, "trans")))

	--[[ DEN FYSISKA DELEN, inte bara ett register. ]]
	local buren = TackRigg.hittaBuren(karaktar, "sadel")
	check("det finns en FYSISK buren sadel i karaktären", buren ~= nil,
		buren and buren.Name or "ingen")
	if buren then
		check("den är oankrad, kolliderar inte och är masslös",
			buren.Anchored == false and buren.CanCollide == false
				and buren.Massless == true,
			("ankrad %s · koll %s · masslös %s"):format(tostring(buren.Anchored),
				tostring(buren.CanCollide), tostring(buren.Massless)))
		--[[ INGEN FRAME-LOOP: den hålls på plats av en svets, inget annat. ]]
		local svets = buren:FindFirstChildOfClass("WeldConstraint")
		check("och den hålls av en WeldConstraint, inte av en loop", svets ~= nil)
	end
end

print("\n── Spam pickup ──")

do
	local fore = TackService.barBuren(spelare, "sadel")
	local ok2 = TackForradService.tagSadel(spelare, HAST, "Trixie")
	local ok3 = TackForradService.tagSadel(spelare, HAST, "Trixie")
	check("upprepade tryck säger fortfarande ja", ok2 == true and ok3 == true)
	check("men sadeln är densamma", TackService.barBuren(spelare, "sadel") == fore)

	--[[ EN sadel, inte tre. Ett register som räknat upp hade synts här. ]]
	local mapp = TackRigg.burenMapp(karaktar)
	local antal = 0
	if mapp then
		for _, d in ipairs(mapp:GetChildren()) do
			if d:IsA("BasePart") and d:GetAttribute("UBRFBuren") == "sadel" then
				antal += 1
			end
		end
	end
	check("och det finns exakt EN buren sadel i världen", antal == 1,
		("%d st"):format(antal))
end

print("\n── Två spelare, samma sadel ──")

do
	local andra, kar2 = nySpelare("Fas1b", 9302, vid + Vector3.new(3, 0, 0))
	Players._spelare = { spelare, andra }
	local ok, skal = TackForradService.tagSadel(andra, HAST, "Trixie")
	--[[ OCH NEKAS MED RATT SKAL. Ett naket `false` hade gatt igenom aven
		om hon nekats for att hon stod for langt bort. ]]
	check("den andra spelaren nekas — for att sadeln redan ar tagen",
		ok == false and skal == "tack.redan_tagen", tostring(skal))
	check("och hon bär ingen sadel", TackService.barBuren(andra, "sadel") == nil,
		tostring(TackService.barBuren(andra, "sadel")))
	check("den första bär den fortfarande",
		GameplayService.barasAv("sadel", HAST) == spelare)
end

print("\n── För långt bort ──")

do
	local tredje, kar3, rot3 = nySpelare("Fas1c", 9303, vid + Vector3.new(400, 0, 0))
	Players._spelare = { spelare, tredje }
	--[[ Först måste den första släppa, annars nekas den tredje av
		ägarskapet i stället för av avståndet — och då mäter provet fel
		regel. ]]
	GameplayService.slappBuret(spelare)
	local ok, skal = TackForradService.tagSadel(tredje, HAST, "Trixie")
	check("en hämtning från andra sidan gården nekas", ok == false, tostring(skal))
	check("servern äger avståndet — inte promptens räckvidd",
		skal == "spel.for_langt", tostring(skal))
	check("och hon bär ingen sadel",
		TackService.barBuren(tredje, "sadel") == nil,
		tostring(TackService.barBuren(tredje, "sadel")))
end

print("\n── Reset och disconnect lämnar ingen orphan ──")

do
	Players._spelare = { spelare }
	local ok = TackForradService.tagSadel(spelare, HAST, "Trixie")
	check("hon tar sadeln igen", ok == true)
	check("fronten är tom", TackForradService.paFronten(HAST, "sadel") == false)
	check("och registret pekar på henne",
		GameplayService.barasAv("sadel", HAST) == spelare)

	--[[ SPELAREN LÄMNAR. Produktionens egen väg: `PlayerRemoving`. ]]
	Players.PlayerRemoving:Fire(spelare)
	task.wait()

	check("registret släppte sadeln",
		GameplayService.barasAv("sadel", HAST) == nil,
		tostring(GameplayService.barasAv("sadel", HAST)))
	check("och sadeln hänger tillbaka på fronten",
		TackForradService.paFronten(HAST, "sadel") == true)
	check("ingen buren sadel ligger kvar i karaktären",
		TackRigg.hittaBuren(karaktar, "sadel") == nil,
		tostring(TackRigg.hittaBuren(karaktar, "sadel")))

	--[[ OCH NÅGON ANNAN KAN TA DEN. Det är beviset på att registret inte
		bara nollades utan verkligen släppte. ]]
	local fjarde, kar4 = nySpelare("Fas1d", 9304, vid + Vector3.new(2, 0, 0))
	Players._spelare = { fjarde }
	local okNy = TackForradService.tagSadel(fjarde, HAST, "Trixie")
	check("nästa spelare kan ta sadeln efteråt", okNy == true)
	GameplayService.slappBuret(fjarde)
end

--[[ ── FAIL-CLOSED OCH ATOMICITET ──────────────────────────────────

	Tre fynd ur senior review av `0b86f48`. Alla tre var felvagar: de syns
	inte nar allt fungerar, och det ar precis darfor de behover egna prov.

	Den gemensamma regeln: ETT NEJ FAR INTE LAMNA SPAR. Sager servern nej
	ska varlden se ut exakt som innan — ingen sadel i handerna, ingen
	agare, inget val i `valdUtrustning`. Ett halvt utfort `WORLD -> HELD`
	ar varre an ett rent nej, for resten av spelet laser sedan det halva
	som sanning. ]]

print("\n── Fail-closed: ingen front att mata avstandet fran ──")

do
	local femte, kar5 = nySpelare("Fas1e", 9305, vid + Vector3.new(2, 0, 0))
	Players._spelare = { femte }

	--[[ En hast utan boxfront. Forut lod provet `if plats and ...`, och
		utan plats HOPPADE servern over avstandet och slappte igenom
		hamtningen. En validering som tiger nar den inte kan mata ar ingen
		validering — svaret ska vara nej. ]]
	local ok, skal = TackForradService.tagSadel(femte, "hast-utan-front", "Spoket")
	check("en hamtning utan fysisk front nekas", ok == false, tostring(skal))
	check("och nejet sager varfor — inte «for langt», utan «ingen front»",
		skal == "tack.ingen_front", tostring(skal))
	ingetSpar(femte, kar5, "hast-utan-front", "ingen front")
end

print("\n── Fail-closed: fronten slapper inte sin sadel ──")

do
	local sjatte, kar6 = nySpelare("Fas1f", 9306, vid + Vector3.new(2, 0, 0))
	Players._spelare = { sjatte }

	--[[ `satSynlig` returnerade sitt svar och ingen lyssnade. Gick
		slackningen fel kunde spelaren sta i HELD med sadeln kvar synlig
		pa kroken — tva sadlar for ogat, en i state. Har rivs gruppen bort
		sa att slackningen MASTE falla. ]]
	local modell6 = TackForradService.forHast(HAST)
	local sadelgrupp
	for _, g in ipairs(modell6:GetChildren()) do
		if g:IsA("Model") and g:GetAttribute("UBRFForrad") == "sadel" then sadelgrupp = g end
	end
	check("sadelgruppen finns att riva", sadelgrupp ~= nil)
	sadelgrupp:Destroy()

	local ok, skal = TackForradService.tagSadel(sjatte, HAST, "Trixie")
	check("pickup nekas nar fronten inte slapper", ok == false, tostring(skal))
	check("och nejet sager varfor", skal == "tack.front_slapper_inte", tostring(skal))

	--[[ ROLLBACK. Den burna sadeln HANN byggas innan slackningen foll, och
		maste darfor rivas igen. Blir den kvar star spelaren med en sadel
		hon aldrig fick — den orphan reviewen pekade pa. ]]
	ingetSpar(sjatte, kar6, HAST, "fronten slapper inte")
end

RunService._server = false

if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("\ntack-fas1.spec: alla gröna")
end
