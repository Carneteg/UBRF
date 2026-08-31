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
	--[[ fasadBitar är generisk: den punkterar vad den än får. Den andra
		öppningen här sitter en meter upp, och provar att hålet hamnar rätt i
		HÖJDLED — inte att fönster ska punkteras. Vilka öppningar som ens
		skickas in avgörs av WorldGeometry.passager, som prövas nedan. ]]
	check("en högt sittande öppnings mitt är ett hål", not windowBlocked)
end

print("\n── Fönster blir INTE hål, passager blir det ──")
do
	--[[ Först punkterades varje öppning, fönster med. Man går inte genom ett
		fönster, så det gav ingen spelvinst — men varje valv blev ett
		genomgående hål i en tjock vägg, och fasaderna slutade se ut som i den
		godkända F01-granskningen. Värst i `ankomsten`: de två norra gavlarna
		bär nio valv av fjorton öppningar. ]]
	for _, typ in ipairs({ "fonster", "rund", "valv" }) do
		check(typ .. " räknas som fönster", WorldGeometry.arFonster(typ))
	end
	for _, typ in ipairs({ "dorr", "dorrvit", "dorrgul", "dorrmork", "portbla", "portsilver", "portplat" }) do
		check(typ .. " räknas INTE som fönster", not WorldGeometry.arFonster(typ))
	end

	local kvar = WorldGeometry.passager({
		{ typ = "valv" }, { typ = "dorrvit" }, { typ = "fonster" },
		{ typ = "portbla" }, { typ = "rund" },
	})
	check("bara passagerna blir kvar", #kvar == 2, #kvar .. " st")
	check("och det är rätt två",
		kvar[1] and kvar[1].typ == "dorrvit" and kvar[2] and kvar[2].typ == "portbla",
		tostring(kvar[1] and kvar[1].typ) .. " + " .. tostring(kvar[2] and kvar[2].typ))

	--[[ Den skarpa räkningen: de två norra gavlarna i `ankomsten`. Punkteras
		fönstren igen faller den här. ]]
	local valv, passager = 0, 0
	for _, b in ipairs(UBRFKomplex.byggnader) do
		if b.id == "ridhus" or b.id == "stall" then
			local norr = {}
			for _, o in ipairs(b.oppningar or {}) do
				if o.sida == "N" then
					table.insert(norr, o)
					if WorldGeometry.arFonster(o.typ) then valv += 1 end
				end
			end
			passager += #WorldGeometry.passager(norr)
		end
	end
	check("de norra gavlarna bär nio fönster som INTE punkteras", valv == 9, valv .. " st")
	check("och fem passager som gör det", passager == 5, passager .. " st")
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

--[[ ── Att köra paketet TVÅ gånger ────────────────────────────────
	Den som bygger om i Studio kör inte alltid i en tom värld. Ackumuleras en
	andra DoorPrompt per dörr får spelaren dubbla "Öppna" på samma dörrblad,
	och en andra UBRFSpawn gör startpunkten till ett lotteri. ]]
do
	local function rakna(rot, namn)
		local n = 0
		for _, b in ipairs(rot:GetDescendants()) do
			if b.Name == namn then n += 1 end
		end
		return n
	end

	local modell = workspace:FindFirstChild("Anläggning")
	local ubrf = modell and modell:FindFirstChild("UBRF")
	check("det finns en UBRF-modell att bygga om i", ubrf ~= nil)

	if ubrf then
		local promptFore = rakna(ubrf, "DoorPrompt")
		local spawnFore = rakna(ubrf, "UBRFSpawn")
		check("första passet gav dörrprompter", promptFore > 0, promptFore .. " st")
		check("första passet gav exakt en spawn", spawnFore == 1, spawnFore .. " st")

		--[[ Varje dörrblad ska stå i SIN EGEN öppning.

			Panelen slogs förut upp som "närmaste Part med rätt namn", utan
			avståndsgräns. Namnet är typen, och två öppningar på samma fasad kan
			ha samma typ — då avgör namnet ingenting och de kan byta panel med
			varandra utan att något säger ifrån. Nu bär panelen BuildingId och
			OpeningId från bygget, och läget räknas ur öppningen.

			Provet mäter varje byggd dörr mot det läge dess ÄGANDE öppning ger. ]]
		local M, DJUP = BuildKit.M, BuildKit.OPPNINGSDJUP
		local matta, varsta, varstNamn = 0, 0, "—"
		local utanId = 0
		for _, b in ipairs(UBRFKomplex.byggnader) do
			for index, o in ipairs(b.oppningar or {}) do
				if not WorldGeometry.arFonster(o.typ) then
					local panel
					for _, i in ipairs(ubrf:GetDescendants()) do
						if i:GetAttribute("BuildingId") == b.id
							and i:GetAttribute("OpeningId") == index
							and i:GetAttribute("UBRFDoor") == true then
							panel = i break
						end
					end
					if not panel then
						utanId += 1
					else
						local mx, mz = Geometri.oppningsMitt(b.rekt, o.sida, o.u, o.b)
						local _, _, along, side = Geometri.oppningsHorn(b.rekt, o.sida, o.u, o.b)
						local ut = if side > 0 then DJUP / 2 else -DJUP / 2
						local vx = M * (mx + (if along == "X" then 0 else ut))
						local vy = M * (o.z0 + o.h / 2)
						local vz = M * (mz + (if along == "X" then ut else 0))
						local p = panel.CFrame.Position
						local d = math.max(math.abs(p.X - vx), math.abs(p.Y - vy), math.abs(p.Z - vz))
						matta += 1
						if d > varsta then
							varsta = d
							varstNamn = string.format("%s #%d %s", b.id, index, o.typ)
						end
					end
				end
			end
		end
		check("varje dörr hittades på sin egen identitet", utanId == 0, utanId .. " utan")
		check("alla 17 dörrar mättes", matta == 17, matta .. " st")
		check("varje blad står i sin ägande öppning", varsta < 0.001,
			string.format("värst %.4f studs (%s)", varsta, varstNamn))

		--[[ Segmenten ska ligga på VÄGGENS djup, inte på ett eget tal. Stod som
			0.3 i WorldBuild och som VAGGT = 0.3 i Anlaggningen; ändras den ena
			sitter fasaden plötsligt framför eller bakom dörrbladen. Nu läses
			den ur väggen, och det här mäter att den gjorde det. ]]
		local vagg, segment
		for _, i in ipairs(ubrf:GetDescendants()) do
			if i.Name == "ridhus norr" then vagg = i end
			if not segment and string.find(i.Name, "ridhus norr fasad", 1, true) then
				segment = i
			end
		end
		check("den gamla norrväggen finns kvar att mäta mot", vagg ~= nil)
		check("ett norrsegment byggdes", segment ~= nil)
		if vagg and segment then
			check("segmentet har väggens tjocklek",
				math.abs(segment.Size.Z - vagg.Size.Z) < 0.001,
				string.format("segment %.3f, vägg %.3f", segment.Size.Z, vagg.Size.Z))
		end

		WorldBuild.apply(BuildKit, UBRFKomplex, Geometri, WorldGeometry)

		local promptEfter = rakna(ubrf, "DoorPrompt")
		local spawnEfter = rakna(ubrf, "UBRFSpawn")
		check("andra passet ger INTE dubbla dörrprompter",
			promptEfter == promptFore,
			string.format("%d före, %d efter", promptFore, promptEfter))
		check("andra passet ger INTE en andra spawn",
			spawnEfter == 1, spawnEfter .. " st")
	end
end

if fails > 0 then
	print(string.format("\n%d FEL", fails))
	error("world.spec: " .. fails .. " fel")
end
print("\nspelbar värld: alla gröna")
