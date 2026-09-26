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
--[[ Slice C: `CharacterRemoving`-kopplingen bor i `SparService`s
	`efterLaddning`-hook, sa datalagret maste vara igang for att den vagen
	ska finnas. Efter `GameplayService.start()`, som registrerar hooken. ]]
SparService.start()

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

	--[[ EN PROMPT PER HANDLING — det är regeln, och den är oförändrad.

		Fram till FAS 3 stod här «exakt EN prompt», eftersom tränset ännu
		inte fått sin. Nu har det det, och kravet är därför exakt TVÅ: en
		för sadeln och en för tränset. Det som aldrig får komma tillbaka
		är den gamla prompten som hämtade HELA PARET i ett tryck — då gick
		FAS 1 och FAS 3 att göra samtidigt, och ingen av dem gick att
		falsifiera för sig.

		Att de två inte krockar med varandra på tangent och handkontroll
		mäts i `tack-fas3.spec`. ]]
	local promptar = {}
	if modell then
		for _, d in ipairs(modell:GetDescendants()) do
			if d:IsA("ProximityPrompt") then table.insert(promptar, d.Name) end
		end
	end
	table.sort(promptar)
	check("det finns exakt TVÅ prompter på fronten — en per handling",
		#promptar == 2 and promptar[1] == "SadelPrompt"
			and promptar[2] == "TransPrompt",
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

print("\n── Kroppen dör med sadeln i handen ──")

--[[ Robustness Slice C.

	Den burna sadeln är en fysisk del under KARAKTÄREN. Dör hon, eller
	byts kroppen vid en respawn, försvinner delen med den — men
	`burenAv` stod kvar och pekade på spelaren. Sadeln var då reserverad
	av någon som inte hade den, och ingen annan kunde ta den förrän
	ägaren själv rörde förrådet igen eller kopplade ner helt.

	Provet går genom PRODUKTIONENS EGEN väg: `player.CharacterRemoving`,
	samma signal Roblox fyrar. Ingen hjälpare anropas direkt. ]]
do
	local a, karA = nySpelare("Fas1c", 9310, vid + Vector3.new(3, 0, 0))
	Players._spelare = { a }
	--[[ SAMMA VAG IN SOM EN RIKTIG SPELARE. `CharacterRemoving` kopplas
	     inne i `SparService.efterLaddning`-hooken, och den kors nar saven
	     laddats — alltsa via `PlayerAdded`. Att anropa kroken direkt hade
	     varit att prova en genvag forbi den koppling som ar under test. ]]
	Players.PlayerAdded:Fire(a)
	task.wait()

	local ok = TackForradService.tagSadel(a, HAST, "Trixie")
	check("A tar sadeln", ok == true)
	check("registret pekar på A",
		GameplayService.barasAv("sadel", HAST) == a)
	check("och fronten är tom",
		TackForradService.paFronten(HAST, "sadel") == false)
	check("och valet säger att hon bär den",
		(GameplayService.valdFor(a) or {}).sadel == HAST,
		tostring((GameplayService.valdFor(a) or {}).sadel))

	--[[ KROPPEN FÖRSVINNER. Produktionens signal, inget direktanrop. ]]
	a.CharacterRemoving:Fire(karA)
	task.wait()

	check("REGISTRET SLÄPPTE SADELN",
		GameplayService.barasAv("sadel", HAST) == nil,
		tostring(GameplayService.barasAv("sadel", HAST)))
	check("den burna delen är borta ur karaktären",
		TackRigg.hittaBuren(karA, "sadel") == nil,
		tostring(TackRigg.hittaBuren(karA, "sadel")))
	check("sadeln hänger tillbaka på fronten",
		TackForradService.paFronten(HAST, "sadel") == true)
	--[[ PRESENTATIONEN OCKSÅ. Registret kan vara rensat medan vyn
	     fortfarande påstår att hon bär något som inte finns. ]]
	check("OCH VYN PÅSTÅR INTE LÄNGRE ATT HON BÄR DEN",
		(GameplayService.valdFor(a) or {}).sadel == nil,
		tostring((GameplayService.valdFor(a) or {}).sadel))

	--[[ Beviset på att registret verkligen SLÄPPTE och inte bara
	     nollades: någon annan kan ta sadeln direkt. ]]
	local b, karB = nySpelare("Fas1e", 9311, vid + Vector3.new(4, 0, 0))
	Players._spelare = { a, b }
	check("B KAN TA SAMMA SADEL DIREKT EFTERÅT",
		TackForradService.tagSadel(b, HAST, "Trixie") == true)
	GameplayService.slappBuret(b)

	--[[ ── PASSET MÄTS INTE HÄR, OCH DET ÄR ETT MEDVETET VAL ──────

		Slice C är tack och ingenting annat: `state`, `passState` och
		`bunden` ska överleva ett kroppsbyte precis som förut.

		Men det går inte att mäta i DEN HÄR bänken. Ingen spelare här har
		en bunden häst — `tack-fas1` arbetar mot `TackForradService`
		direkt — så `statusFor` svarar `waiting_model` oavsett om passet
		nollställs eller inte. Jag skrev först två rader som jämförde
		`waiting_model` med `waiting_model`; falsifieringen kunde inte få
		dem röda, och då mätte de ingenting.

		Kravet mäts i stället där det GÅR: `integration.spec:663-665`
		(«skötseln räknas fortfarande som gjord efter respawnen») kör
		samma `CharacterRemoving`-väg med en riktig bunden häst och
		avbockade moment. Falsifieringsarmen «passet nollställs också»
		riktas därför mot den specen, inte mot den här. ]]

	--[[ ── IDEMPOTENS ──────────────────────────────────────────────
		Två kroppsbyten i rad ska inte ge ett fel, och inte heller ta
		tillbaka något från den som hunnit ta sadeln. ]]
	Players._spelare = { a, b }
	check("B tar sadeln igen inför idempotensprovet",
		TackForradService.tagSadel(b, HAST, "Trixie") == true)
	a.CharacterRemoving:Fire(karA)
	task.wait()
	check("A:s ANDRA KROPPSBYTE RÖR INTE B:s SADEL",
		GameplayService.barasAv("sadel", HAST) == b,
		tostring(GameplayService.barasAv("sadel", HAST)))

	--[[ ── OCH FRÅNKOPPLINGEN GÖR FORTFARANDE HELA JOBBET ─────────
		`PlayerRemoving` ska stada resten även när kroppsstädningen
		redan körts, och den ska inte återuppliva något. ]]
	Players.PlayerRemoving:Fire(a)
	task.wait()
	check("A:s frånkoppling går igenom efter kroppsstädningen",
		GameplayService.valdFor(a) == nil)
	check("och den återupplivar inte A:s sadel",
		GameplayService.barasAv("sadel", HAST) == b,
		tostring(GameplayService.barasAv("sadel", HAST)))
	GameplayService.slappBuret(b)
	Players.PlayerRemoving:Fire(b)
	Players._spelare = { spelare }
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

print("\n── En sadel i taget: bytet far inte lamna den forsta last ──")

do
	--[[ FYNDET UR REVIEW 2. `TackService.satBuren` ar uttryckligen byggd
		for att BYTA ut en buren sadel mot en annan hasts. Gjorde `valjEn`
		det lag den FORSTA hastens agarpost kvar och hennes front forblev
		slackt: hennes sadel last for alla, i handerna pa ingen.

		Provet gar hela vagen — tar den forsta sadeln, gar till en annan
		box, forsoker igen — och mater sedan BADA hastarna. Ett prov som
		bara sett den nya hasten hade missat precis det som var fel. ]]
	local mapp = TackForradService.mapp()
	local annanId, annanModell
	if mapp then
		for _, m in ipairs(mapp:GetChildren()) do
			local fh = m:IsA("Model") and tostring(m:GetAttribute("ForHast") or "")
			if fh and fh ~= "" and fh ~= HAST and m.PrimaryPart then
				annanId, annanModell = fh, m
				break
			end
		end
	end
	check("det finns en andra hast med egen boxfront att prova mot",
		annanId ~= nil, tostring(annanId))

	local sjunde, kar7, rot7 = nySpelare("Fas1g", 9307, vid + Vector3.new(2, 0, 0))
	Players._spelare = { sjunde }

	local ok1 = TackForradService.tagSadel(sjunde, HAST, "Trixie")
	check("hon tar forst Trixies sadel", ok1 == true)

	--[[ OCH GAR TILL DEN ANDRA BOXEN. Utan flytten nekas hon av avstandet
		och provet hade matt fel regel. ]]
	rot7.CFrame = CFrame.new(annanModell.PrimaryPart.Position + Vector3.new(2, 0, 0))

	local ok2, skal2 = TackForradService.tagSadel(sjunde, annanId, "Den andra")
	check("den andra hastens sadel nekas", ok2 == false, tostring(skal2))
	check("och nejet sager varfor", skal2 == "tack.bar_redan_annan", tostring(skal2))

	--[[ INGENTING FAR HA ANDRATS. Varken hos den hon bar eller hos den
		hon inte fick. ]]
	check("Trixies sadel ar fortfarande fysiskt i handerna",
		TackService.barBuren(sjunde, "sadel") == HAST,
		tostring(TackService.barBuren(sjunde, "sadel")))
	check("Trixies front ar fortfarande tom",
		TackForradService.paFronten(HAST, "sadel") == false)
	check("den andra hastens sadel hanger kvar synlig pa sin front",
		TackForradService.paFronten(annanId, "sadel") == true)
	check("den andra hasten har ingen agare",
		GameplayService.barasAv("sadel", annanId) == nil,
		tostring(GameplayService.barasAv("sadel", annanId)))

	--[[ EXAKT EN AGARNYCKEL. Rakningen gar over ALLA boxfronter, inte bara
		de tva provet kanner vid namn — en stale post nagon annanstans ar
		lika mycket en last sadel. ]]
	local mina = {}
	if mapp then
		for _, m in ipairs(mapp:GetChildren()) do
			local fh = m:IsA("Model") and tostring(m:GetAttribute("ForHast") or "")
			if fh and fh ~= "" and GameplayService.barasAv("sadel", fh) == sjunde then
				table.insert(mina, fh)
			end
		end
	end
	check("spelaren ager exakt EN sadel i hela stallet", #mina == 1,
		("%d: %s"):format(#mina, table.concat(mina, ", ")))

	--[[ OCH HON KAN LAMNA TILLBAKA OCH TA DEN ANDRA. Annars vore nejet en
		atervandsgrand i stallet for en regel. ]]
	GameplayService.slappBuret(sjunde)
	check("nar hon lamnat tillbaka hanger Trixies sadel pa fronten igen",
		TackForradService.paFronten(HAST, "sadel") == true)
	local ok3, skal3 = TackForradService.tagSadel(sjunde, annanId, "Den andra")
	check("och da gar den andra hastens sadel att ta", ok3 == true, tostring(skal3))
	GameplayService.slappBuret(sjunde)
end

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
