--!nostrict
--[[
	Spelbar värld: fasadhål och spawn.
	Provar den rena WorldGeometry-modulen mot den exporterade UBRF-geometrin.
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

local function covers(seg, s, y)
	return s > seg.s0 + 0.0001 and s < seg.s1 - 0.0001
		and y > seg.y0 + 0.0001 and y < seg.y1 - 0.0001
end

print("\n── Fasadsegment lämnar riktiga hål ──")
do
	local bits = WorldGeometry.fasadBitar(10, 3, {
		{ u = 2, b = 2, z0 = 0, h = 2 },
		{ u = 6, b = 1, z0 = 1, h = 1 },
	})
	local doorBlocked = false
	local windowBlocked = false
	for _, seg in ipairs(bits) do
		if covers(seg, 3, 1) then doorBlocked = true end
		if covers(seg, 6.5, 1.5) then windowBlocked = true end
	end
	check("markdörrens mitt är ett hål", not doorBlocked)
	check("fönstrets mitt är ett hål", not windowBlocked)
end

print("\n── Alla exporterade markdörrar är passagehål ──")
local doorCount = 0
for _, b in ipairs(UBRFKomplex.byggnader) do
	for _, sida in ipairs({ "S", "N", "E", "W" }) do
		local openings = {}
		for _, o in ipairs(b.oppningar or {}) do
			if o.sida == sida then table.insert(openings, o) end
		end
		local length = if sida == "S" or sida == "N" then b.rekt.w else b.rekt.h
		local bits = WorldGeometry.fasadBitar(length, b.hV, openings)
		for _, o in ipairs(openings) do
			local isWindow = o.typ == "fonster" or o.typ == "rund" or o.typ == "valv"
			if not isWindow and o.z0 <= 0.05 then
				doorCount += 1
				local blocked = false
				local s, y = o.u + o.b / 2, math.min(o.h * 0.5, 1.2)
				for _, seg in ipairs(bits) do
					if covers(seg, s, y) then blocked = true break end
				end
				check(string.format("%s %s %s har inget väggblock bakom dörren",
					b.id, sida, o.typ), not blocked)
			end
		end
	end
end
check("det finns marknära dörrar/portar att prova", doorCount >= 6, doorCount .. " st")

print("\n── Spawn ligger vid ankomsten, inte ute på tomten ──")
do
	local ridhus, stall
	for _, b in ipairs(UBRFKomplex.byggnader) do
		if b.id == "ridhus" then ridhus = b end
		if b.id == "stall" then stall = b end
	end
	--[[ INGEN marginal skickas in. Provet skickade förut in 4 själv och
		jämförde mot sin egen fyra, alltså mot en tredje kopia av talet — och
		bevisade bara att aritmetiken stämmer. Att flytta spelets spawn från
		4 till 40 m passerade grönt. Nu prövas vägen spelet faktiskt tar. ]]
	local x, z, tx, tz = WorldGeometry.ankomstSpawn(UBRFKomplex.byggnader)
	local east = ridhus.rekt.x + ridhus.rekt.w
	local west = stall.rekt.x
	local north = math.max(ridhus.rekt.y + ridhus.rekt.h, stall.rekt.y + stall.rekt.h)
	check("spawn ligger mellan ridhus och stall", x > east and x < west,
		string.format("x=%.2f mellan %.2f och %.2f", x, east, west))
	check("spawn ligger SPAWN_MARGIN framför nordligaste gaveln",
		math.abs(z - (north + WorldGeometry.SPAWN_MARGIN)) < 0.001,
		string.format("z=%.2f, marginal %.2f", z, WorldGeometry.SPAWN_MARGIN))

	--[[ En oberoende gräns på vad "vid ankomsten" betyder. Utan den kan
		konstanten sättas till 40 och provet ovan går ändå grönt — det jämför
		ju mot konstanten. Hela poängen med hotfixen var att spelaren inte
		ska starta långt ute på tomten. ]]
	check("spawn står NÄRA gaveln, inte ute på tomten",
		WorldGeometry.SPAWN_MARGIN > 0 and WorldGeometry.SPAWN_MARGIN <= 10,
		string.format("%.2f m", WorldGeometry.SPAWN_MARGIN))

	--[[ Och den får inte hamna inne i ett hus. ]]
	check("spawn ligger utanför båda byggnaderna", z > north,
		string.format("z=%.2f, nordligaste gavel %.2f", z, north))
	check("spawn tittar in mot anläggningen", tx == x and tz < z)
end

--[[ ── Den BYGGDA spawnen ──────────────────────────────────────────
	Allt ovanför prövar uttrycket. Det här prövar vad WorldBuild faktiskt
	lade i världen — det enda som spelaren möter.

	Varför det behövs: marginalen låg förut som en literal även i WorldBuild:s
	eget anrop, alltså en andra kopia som ingen assertion kunde se. Kopian är
	borttagen, men utan det här provet skulle nästa kopia kunna smyga tillbaka
	utan att något går rött. ]]
do
	WorldBuild.apply(BuildKit, UBRFKomplex, Geometri, WorldGeometry)

	local modell = workspace:FindFirstChild("Anläggning")
	local ubrf = modell and modell:FindFirstChild("UBRF")
	local spawn = ubrf and ubrf:FindFirstChild("UBRFSpawn")
	check("WorldBuild la en UBRFSpawn i världen", spawn ~= nil)

	--[[ Ingen tyst if-vakt här. Första versionen hoppade över hela
		jämförelsen när PrimaryPart saknades, och då skrevs ingenting ut alls
		— vilket ser ut som grönt. Nu FALLER den i stället. ]]
	check("modellen har en PrimaryPart att mäta mot",
		ubrf ~= nil and ubrf.PrimaryPart ~= nil,
		ubrf and tostring(ubrf.PrimaryPart) or "ingen UBRF-modell")

	if spawn and ubrf and ubrf.PrimaryPart then
		--[[ Jämförelsen görs FRAMÅT, inte genom att invertera basen: vi räknar
			ut var härledningen SKULLE lägga spawnen och mäter avståndet till
			den byggda. Första versionen inverterade basen och kraschade på en
			metod stubben saknar — och en krasch är inte ett grönt prov, vilket
			exitkoden visade. ]]
		local bas = ubrf.PrimaryPart.CFrame
		local sx, sz = WorldGeometry.ankomstSpawn(UBRFKomplex.byggnader)
		local vantad = bas * CFrame.new(BuildKit.M * sx, 0.2, BuildKit.M * sz)

		local a, b = spawn.CFrame.Position, vantad.Position
		local dx, dz = a.X - b.X, a.Z - b.Z
		check("den byggda spawnen står där härledningen säger",
			math.abs(dx) < 0.2 and math.abs(dz) < 0.2,
			string.format("avvikelse (%.3f, %.3f) studs", dx, dz))
	end
end

if fails > 0 then
	print(string.format("\n%d FEL", fails))
	error("world.spec: " .. fails .. " fel")
end
print("\nspelbar värld: alla gröna")
