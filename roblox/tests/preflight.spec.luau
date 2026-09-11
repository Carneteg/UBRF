--!nostrict
--[[
	PREFLIGHTEN — främmande markplan.

	P0-C mätte det i Studio: `Workspace.Baseplate`, 2048 x 16 x 2048 studs,
	låg med ovansidan på y = 0,000 medan UBRF:s högsta marklager slutar på
	y = -0,018. Rutnätet vann därför som golv ÖVERALLT — på gården, inne i
	stallet och trehundra meter utanför tomten — och hela den byggda marken
	var maskerad. Spelaren gick på Roblox standardplan i en värld som såg
	byggd ut.

	Preflighten släppte igenom det. Den fällde en främmande `SpawnLocation`
	men kände inte till ett främmande MARKPLAN, och den hade ingen spec
	alls. Den här filen är den saknade grinden.

	SKÖRHETEN ÄR AVSIKTLIG I DESIGNEN: marken ligger medvetet under noll för
	att husgolven på 0 ska vinna. Det gör varje place med en kvarglömd
	baseplate tyst fel, och det är precis vad en fail-closed grind ska
	fånga — före runtime, med sökvägen utskriven.

	Kör: python3 roblox/tests/build.py tests/preflight.spec.luau
	     && luau roblox/tests/.build/preflight.spec.luau
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

--[[ Hämtar EN rad ur preflightens mätning. Specen läser tjänstens egen
	utdata — inte en kopia av villkoret — så att en rad som byter namn
	eller försvinner fäller provet i stället för att tyst sluta mätas. ]]
local function matning(prefix)
	for _, r in ipairs(Preflight.matningar(true)) do
		if r.namn:sub(1, #prefix) == prefix then return r end
	end
	return nil
end

local anlaggning = workspace:FindFirstChild("Anläggning")

print("\n── Raden finns över huvud taget ──")

local r2d = matning("2d")
check("preflighten mäter främmande markplan", r2d ~= nil,
	r2d and r2d.namn or "ingen rad som börjar på 2d")
local r2e = matning("2e")
check("preflighten mäter främmande terräng", r2e ~= nil,
	r2e and r2e.namn or "ingen rad som börjar på 2e")

print("\n── En ren UBRF passerar ──")

check("anläggningen är byggd i bänken", anlaggning ~= nil)
check("ren värld: inget främmande markplan", r2d ~= nil and r2d.ok == true,
	r2d and tostring(r2d.detalj) or "-")
check("ren värld: ingen främmande terräng", r2e ~= nil and r2e.ok == true,
	r2e and tostring(r2e.detalj) or "-")

print("\n── Roblox standardbaseplate fälls ──")

do
	--[[ Exakt de mått Studio ger en ny place. Storleken är hela regeln:
		ingen UBRF-del utanför anläggningen är i närheten av den. ]]
	local bp = Instance.new("Part")
	bp.Name = "Baseplate"
	bp.Size = Vector3.new(2048, 16, 2048)
	bp.CFrame = CFrame.new(Vector3.new(0, -8, 0))
	bp.Anchored = true
	bp.CanCollide = true
	bp.Parent = workspace

	local r = matning("2d")
	check("standardbaseplaten fäller grinden", r ~= nil and r.ok == false,
		r and tostring(r.detalj) or "-")
	--[[ Den som ska rensa ska slippa leta: sökvägen måste stå i felet. ]]
	check("felet namnger den skyldiga delen med sökväg",
		r ~= nil and r.detalj ~= nil and string.find(r.detalj, "Baseplate", 1, true) ~= nil,
		r and tostring(r.detalj) or "-")
	check("och måttet står med", r ~= nil and r.detalj ~= nil
		and string.find(r.detalj, "2048", 1, true) ~= nil)

	bp:Destroy()
	local efter = matning("2d")
	check("borttagen baseplate gör grinden grön igen",
		efter ~= nil and efter.ok == true, efter and tostring(efter.detalj) or "-")
end

print("\n── Tröskeln ──")

do
	--[[ Tröskeln är 120 studs (40 m). Under den är delen inte ett markplan,
		och över den finns ingenting eget utanför anläggningen. Båda
		sidorna mäts: en grind som aldrig blir grön är lika oanvändbar som
		en som aldrig blir röd. ]]
	local liten = Instance.new("Part")
	liten.Name = "Litet plan"
	liten.Size = Vector3.new(119, 4, 119)
	liten.CFrame = CFrame.new(Vector3.new(0, -2, 0))
	liten.Anchored = true
	liten.CanCollide = true
	liten.Parent = workspace
	local r = matning("2d")
	check("119 studs är inte ett markplan", r ~= nil and r.ok == true,
		r and tostring(r.detalj) or "-")
	liten.Size = Vector3.new(121, 4, 121)
	local r2 = matning("2d")
	check("121 studs är det", r2 ~= nil and r2.ok == false,
		r2 and tostring(r2.detalj) or "-")
	liten:Destroy()
end

do
	--[[ En genomsiktlig eller icke-kolliderande yta är ingen mark: den kan
		inte vinna som golv. Grinden ska inte fälla en himmelskupol. ]]
	local kuliss = Instance.new("Part")
	kuliss.Name = "Kuliss"
	kuliss.Size = Vector3.new(4000, 4, 4000)
	kuliss.CFrame = CFrame.new(Vector3.new(0, -40, 0))
	kuliss.Anchored = true
	kuliss.CanCollide = false
	kuliss.Parent = workspace
	local r = matning("2d")
	check("en icke-kolliderande kuliss fäller inte grinden",
		r ~= nil and r.ok == true, r and tostring(r.detalj) or "-")
	kuliss:Destroy()
end

print("\n── Terrängen räknas inte som markplan ──")

do
	--[[ `Terrain` ÄR en BasePart och rapporterar 2044 x 2044 studs även när
		den är helt tom. Mätt i en Rojo-place utan en enda voxel: raden
		flaggade `Workspace.Terrain`, och en grind som fäller varje place i
		världen mäter ingenting. Terrängen hör till 2e, som läser faktisk
		utbredning. ]]
	local terrang = Instance.new("Terrain")
	terrang.Name = "Terrain"
	terrang.Size = Vector3.new(2044, 512, 2044)
	terrang.CanCollide = true
	--[[ En tom terräng: stor `Size`, men ingen utbredning. Det är den
		kombinationen som lurade markplansregeln. ]]
	terrang.MaxExtents = { Min = Vector3.new(0, 0, 0), Max = Vector3.new(0, 0, 0) }
	terrang.Parent = workspace
	local r = matning("2d")
	check("tom terräng är inte ett främmande markplan",
		r ~= nil and r.ok == true, r and tostring(r.detalj) or "-")
	terrang:Destroy()
end

print("\n── Anläggningens egna delar är inte främmande ──")

do
	--[[ Hade regeln bara varit storleken hade UBRF:s eget markpaket fallit
		sin egen grind. Det som räknas är att delen ligger UTANFÖR
		anläggningen. ]]
	local egen = Instance.new("Part")
	egen.Name = "Egen stor markyta"
	egen.Size = Vector3.new(900, 4, 700)
	egen.CFrame = CFrame.new(Vector3.new(0, -2, 0))
	egen.Anchored = true
	egen.CanCollide = true
	egen.Parent = anlaggning
	local r = matning("2d")
	check("en stor yta INNE i anläggningen är inte främmande",
		r ~= nil and r.ok == true, r and tostring(r.detalj) or "-")
	egen:Destroy()
end

if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("\npreflight.spec: alla gröna")
end
