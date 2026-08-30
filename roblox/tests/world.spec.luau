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
	local x, z, tx, tz = WorldGeometry.ankomstSpawn(UBRFKomplex.byggnader, 4)
	local east = ridhus.rekt.x + ridhus.rekt.w
	local west = stall.rekt.x
	local north = math.max(ridhus.rekt.y + ridhus.rekt.h, stall.rekt.y + stall.rekt.h)
	check("spawn ligger mellan ridhus och stall", x > east and x < west,
		string.format("x=%.2f mellan %.2f och %.2f", x, east, west))
	check("spawn ligger exakt 4 m framför nordligaste gaveln",
		math.abs(z - (north + 4)) < 0.001, string.format("z=%.2f", z))
	check("spawn tittar in mot anläggningen", tx == x and tz < z)
end

if fails > 0 then
	print(string.format("\n%d FEL", fails))
	error("world.spec: " .. fails .. " fel")
end
print("\nspelbar värld: alla gröna")
