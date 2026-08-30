--!strict
--[[
	WorldGeometry — ren geometri för spelbar värld.

	Anlaggningen byggdes ursprungligen med hela solida fasadväggar och lade
	fönster/dörrar som tunna färgade Parts utanpå. Det såg rätt ut på avstånd,
	men en dörr kunde aldrig bli en passage eftersom väggen bakom var hel.

	Den här modulen räknar ut vilka rektanglar av en fasad som faktiskt ska vara
	vägg när öppningarna har dragits bort. Ingen Roblox-API används här, så
	regeln kan provas utan Studio.
]]

local WorldGeometry = {}

export type Opening = { u: number, b: number, z0: number, h: number }
export type Segment = { s0: number, s1: number, y0: number, y1: number }

local function clamp(v: number, lo: number, hi: number): number
	return math.max(lo, math.min(hi, v))
end

local function uniqueSorted(values: { number }): { number }
	table.sort(values)
	local out = {}
	for _, v in ipairs(values) do
		if #out == 0 or math.abs(v - out[#out]) > 0.0001 then
			table.insert(out, v)
		end
	end
	return out
end

--[[
	Returnerar väggrektanglar i fasadens lokala koordinater.
	`s` följer samma p0→p1-riktning som öppningarnas `u` i src/site.js.
	Alla öppningar dras bort, även fönster och öppningar över marknivå.
]]
function WorldGeometry.fasadBitar(length: number, height: number, openings: { Opening }): { Segment }
	assert(length > 0 and height > 0, "fasaden måste ha positiva mått")

	local cuts = { 0, length }
	for _, o in ipairs(openings) do
		local a = clamp(o.u, 0, length)
		local b = clamp(o.u + o.b, 0, length)
		if b > a + 0.0001 then
			table.insert(cuts, a)
			table.insert(cuts, b)
		end
	end
	cuts = uniqueSorted(cuts)

	local result = {}
	for i = 1, #cuts - 1 do
		local s0, s1 = cuts[i], cuts[i + 1]
		if s1 - s0 <= 0.0001 then continue end
		local mid = (s0 + s1) / 2
		local vertical = { { y0 = 0, y1 = height } }

		for _, o in ipairs(openings) do
			if mid >= o.u - 0.0001 and mid <= o.u + o.b + 0.0001 then
				local hole0 = clamp(o.z0, 0, height)
				local hole1 = clamp(o.z0 + o.h, 0, height)
				if hole1 > hole0 + 0.0001 then
					local nextVertical = {}
					for _, v in ipairs(vertical) do
						if hole1 <= v.y0 or hole0 >= v.y1 then
							table.insert(nextVertical, v)
						else
							if hole0 - v.y0 > 0.0001 then
								table.insert(nextVertical, { y0 = v.y0, y1 = hole0 })
							end
							if v.y1 - hole1 > 0.0001 then
								table.insert(nextVertical, { y0 = hole1, y1 = v.y1 })
							end
						end
					end
					vertical = nextVertical
				end
			end
		end

		for _, v in ipairs(vertical) do
			if v.y1 - v.y0 > 0.0001 then
				table.insert(result, { s0 = s0, s1 = s1, y0 = v.y0, y1 = v.y1 })
			end
		end
	end
	return result
end

local function findBuilding(buildings, id: string)
	for _, b in ipairs(buildings) do
		if b.id == id then return b end
	end
	return nil
end

--[[
	Gameplay-spawn vid den naturliga ankomsten, inte QA-kamerans avstånd.
	Fyra meter är gameplay-marginal framför den nordligaste gaveln, inte ett
	påstående om en verklig skylt eller exakt verklig startpunkt.
]]
function WorldGeometry.ankomstSpawn(buildings, margin: number?): (number, number, number, number)
	local ridhus = findBuilding(buildings, "ridhus")
	local stall = findBuilding(buildings, "stall")
	assert(ridhus and stall, "ankomstSpawn kräver ridhus och stall")

	local innerEast = ridhus.rekt.x + ridhus.rekt.w
	local innerWest = stall.rekt.x
	local x = (innerEast + innerWest) / 2
	local north = math.max(
		ridhus.rekt.y + ridhus.rekt.h,
		stall.rekt.y + stall.rekt.h
	)
	local z = north + (margin or 4)

	-- Titta in mot mitten mellan de två huvudvolymerna.
	local targetZ = math.min(
		ridhus.rekt.y + ridhus.rekt.h,
		stall.rekt.y + stall.rekt.h
	) - 6
	return x, z, x, targetZ
end

return WorldGeometry
