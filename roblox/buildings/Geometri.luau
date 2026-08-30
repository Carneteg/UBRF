--!strict
-- Ren geometri över anläggningen: inga Roblox-anrop, inga Instance, ingen
-- rendering. Bara de uträkningar som måste betyda samma sak på båda
-- plattformarna — var en öppning sitter i en fasad, och hur brant ett tak är.
--
-- Den ligger separat just för att den ska gå att MÄTA utanför Studio.
-- roblox/tests/geometri.spec.luau kör den mot samma tal som webbspelet räknar
-- fram ur src/site.js. Ligger de i samma fil som partbygget går de inte att
-- testa, och då är pariteten ett påstående i stället för ett mätvärde.
--
-- Måtten i meter. Origo i sydväst, +x öster, +y norr — samma som src/site.js.

local Geometri = {}

export type Rekt = { x: number, y: number, w: number, h: number }

-- Fasadens p0 → p1, medurs sett utifrån. EXAKT samma konvention som `vagg` i
-- src/site.js. u i en öppning mäts från p0 längs den riktningen; ändras den
-- ena måste den andra ändras med, och specen fäller det annars.
function Geometri.vagg(r: Rekt, sida: string): (number, number, number, number)
	if sida == "S" then return r.x, r.y, r.x + r.w, r.y
	elseif sida == "E" then return r.x + r.w, r.y, r.x + r.w, r.y + r.h
	elseif sida == "N" then return r.x + r.w, r.y + r.h, r.x, r.y + r.h
	elseif sida == "W" then return r.x, r.y + r.h, r.x, r.y
	end
	error("okänd sida: " .. tostring(sida))
end

-- Utåtriktad normal för en fasad.
function Geometri.normal(sida: string): (number, number)
	if sida == "S" then return 0, -1
	elseif sida == "N" then return 0, 1
	elseif sida == "E" then return 1, 0
	elseif sida == "W" then return -1, 0
	end
	error("okänd sida: " .. tostring(sida))
end

--[[ Öppningens sydvästra hörn i världskoordinater, plus hur den ska ritas.

	På N och W går p0 → p1 mot minskande koordinat, så där räknas hörnet
	baklänges — det är den detalj som är lätt att få fel och som gör att en
	dörr hamnar i fel ände av en fasad.

	Returnerar x, z, along ("X" eller "Z") och side (+1/-1 = åt vilket håll
	öppningen sticker ut ur väggen). ]]
function Geometri.oppningsHorn(r: Rekt, sida: string, u: number, b: number)
	local x0, z0 = Geometri.vagg(r, sida)
	if sida == "S" then return x0 + u, z0, "X", -1
	elseif sida == "N" then return x0 - u - b, z0, "X", 1
	elseif sida == "E" then return x0, z0 + u, "Z", 1
	else return x0, z0 - u - b, "Z", -1 end
end

-- Öppningens mittpunkt, som den ligger i fasadlivet.
function Geometri.oppningsMitt(r: Rekt, sida: string, u: number, b: number): (number, number)
	local x, z, along = Geometri.oppningsHorn(r, sida, u, b)
	if along == "X" then return x + b / 2, z else return x, z + b / 2 end
end

-- Taklutning i grader, räknad ur takfot och nock i stället för angiven: hN - hV
-- är resningen över halva spännvidden, och spännvidden avgörs av nocken.
-- "NS" = nocken löper längs y, alltså spänner taket över byggnadens bredd.
function Geometri.taklutning(rekt: Rekt, hV: number, hN: number, nock: string): number
	local spann = if nock == "NS" then rekt.w else rekt.h
	return math.deg(math.atan((hN - hV) / (spann / 2)))
end

-- Sitter två byggnader ihop? Väggarna ska mötas, inte överlappa, och de ska ha
-- ett gemensamt stycke att mötas längs. Marginalen är en decimeter: byggmåtten
-- i src/site.js står i hela och halva meter, så ett verkligt möte träffar
-- exakt och ett glapp är alltid större än så.
function Geometri.sitterIhop(a: Rekt, b: Rekt, marginal: number?): boolean
	local m = marginal or 0.1
	local overX = math.min(a.x + a.w, b.x + b.w) - math.max(a.x, b.x)
	local overY = math.min(a.y + a.h, b.y + b.h) - math.max(a.y, b.y)
	-- Möte i x-led: gaveln mot gaveln, med ett gemensamt stycke i y-led.
	if math.abs(overX) <= m and overY > m then return true end
	-- Möte i y-led: långsidan mot långsidan.
	if math.abs(overY) <= m and overX > m then return true end
	return false
end

--[[ Boxfacken i en rad, som lokala y-intervall.

	Facken börjar vid boxStartY och är boxB djupa fram till klubbdelen. Facket
	som tvärkorridoren går igenom hoppas över — korridoren når båda långsidorna
	i planen, och en box där hade stängt den.

	Ligger här och inte i byggskriptet därför att specen måste kunna mäta samma
	fack som byggs. Skriver man logiken två gånger mäter man inte längre det man
	bygger. ]]
function Geometri.boxfack(stall): { { y0: number, y1: number } }
	local fack = {}
	local y = stall.boxStartY
	while y + stall.boxB <= stall.klubbY + 0.001 do
		local mitt = y + stall.boxB / 2
		if not (mitt > stall.tvarGang.y0 and mitt < stall.tvarGang.y1) then
			table.insert(fack, { y0 = y, y1 = y + stall.boxB })
		end
		y += stall.boxB
	end
	return fack
end

--[[ Tvärväggens bitar, som lokala x-intervall.

	En tvärvägg går inte obruten över huset — den har ett dörrgap där varje
	gång passerar, annars vore stallgången avstängd och klubbdelen oåtkomlig.
	Webbversionen bygger den i bitar mellan gångarna; det här är samma regel,
	så att Roblox inte murar igen en passage som är öppen i spelet.

	Byggbänken hittade precis det felet första gången den kördes: en obruten
	vägg vid y = 43 låg tvärs över klubbhallens gångyta.

	Gångarna kommer som en tabell med id som nyckel, och nyckelordningen i Luau
	är inte definierad — därför sorteras de på x0 innan bitarna räknas ut. ]]
function Geometri.tvarvaggBitar(stall): { { x0: number, x1: number } }
	local hal = {}
	for _, g in pairs(stall.gangar) do table.insert(hal, g) end
	table.sort(hal, function(a, b) return a.x0 < b.x0 end)

	local bitar = {}
	local x = 0
	for _, h in ipairs(hal) do
		if h.x0 - x > 0.05 then table.insert(bitar, { x0 = x, x1 = h.x0 }) end
		x = h.x1
	end
	if stall.bredd - x > 0.05 then table.insert(bitar, { x0 = x, x1 = stall.bredd }) end
	return bitar
end

-- Överlappets area mellan två rektanglar. 0 när de bara nuddar varandra.
function Geometri.overlapp(a: Rekt, b: Rekt): number
	local dx = math.min(a.x + a.w, b.x + b.w) - math.max(a.x, b.x)
	local dy = math.min(a.y + a.h, b.y + b.h) - math.max(a.y, b.y)
	if dx <= 0 or dy <= 0 then return 0 end
	return dx * dy
end

return Geometri
