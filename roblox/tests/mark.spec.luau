--[[
	MARKEN BÄR — grinden som saknades när Tobias föll ur världen.

	P0 ur det fysiska Studio-testet: spawnen låg rätt, men den som gick ut
	från förstukvisten föll genom marken och dog. Orsaken var en rad i
	`Anlaggningen.byggMark`: varje marklager byggdes `CanCollide = false`.
	Marken var DEKOR. Det enda som bar spelaren var husens golv.

	Varför ingen befintlig grind såg det: `spelbarhet.spec` mäter golv och
	gångbarhet i en region runt STALLET — kedjan spawn → dörr → box. Inne i
	den regionen bär husgolven, så kartan var full. Tomten utanför mättes
	aldrig. Grinden mätte rätt sak på fel yta.

	Den här specen mäter hela tomten, och den mäter STÖD — inte gångbarhet.
	Frågan är den enklaste möjliga: finns det någonstans en spelare kan stå
	där det inte finns något under fötterna?

	Kör: python3 roblox/tests/build.py tests/mark.spec.luau
	     && luau roblox/tests/.build/mark.spec.luau
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

local M = BuildKit.M
local modell = workspace:FindFirstChild("Anläggning"):FindFirstChild("UBRF")
--[[ Kartans ram. Världen byggs i den och vänds en gång till en högerhänt
	Y-upp-värld där norr är −Z (`BuildKit.tomtlage`); `BuildKit.tomtkoord`
	är vägen tillbaka. Provet mäter markens bärighet i SITE-koordinater,
	samma tal som `UBRFKomplex.mark` och `references/SITEPLAN.md`. ]]
local bas = (modell :: any).PrimaryPart.CFrame

local MAXGOLV = 3.0    -- högre än så är ett tak, inte ett golv
local UNDER   = -0.05  -- lite slack neråt: marklagrets ovansida ligger på 0

--[[ Alla KOLLIDERANDE lådor i meter, i tomtens koordinater. Samma läsning
	som spelbarhetsgrinden gör — en yta som inte kolliderar bär ingen. ]]
local lador = {}
for _, d in ipairs(modell:GetDescendants()) do
	if d.CFrame and d.Size and d.CanCollide ~= false and d.Transparency ~= 1 then
		local c, s = d.CFrame.Position, d.Size
		local cx, cz = BuildKit.tomtkoord(bas, c)
		table.insert(lador, {
			namn = d.Name,
			x0 = cx - s.X / (2 * M), x1 = cx + s.X / (2 * M),
			z0 = cz - s.Z / (2 * M), z1 = cz + s.Z / (2 * M),
			y1 = (c.Y + s.Y / 2) / M,
		})
	end
end

--[[ Höjden på den yta man står på i punkten, eller nil om det inte finns
	någon. Den högsta ytan under takhöjd vinner: står man på en trappa är
	det trappan man står på, inte marken under. ]]
local function stodI(x, z): number?
	local basta = nil
	for _, l in ipairs(lador) do
		if x >= l.x0 and x <= l.x1 and z >= l.z0 and z <= l.z1
			and l.y1 >= UNDER and l.y1 <= MAXGOLV then
			if basta == nil or l.y1 > basta then basta = l.y1 end
		end
	end
	return basta
end

print(("\n── Marken: %d kolliderande delar, tomt %d×%d m ──")
	:format(#lador, UBRFKomplex.bredd, UBRFKomplex.djup))

--[[ ══ 1. VARJE MARKLAGER FINNS OCH BÄR ═════════════════════════════════
	Läses ur de byggda delarna via attributet `UBRFMark`, inte ur källan:
	frågan är vad som hamnade i världen, inte vad koden tänkte bygga. ]]
do
	local byggda, utanStod = 0, {}
	for _, d in ipairs(modell:GetDescendants()) do
		local typ = d.GetAttribute and d:GetAttribute("UBRFMark")
		if typeof(typ) == "string" then
			byggda += 1
			if d.CanCollide == false then table.insert(utanStod, typ) end
		end
	end
	check("varje marklager i geometrin är byggt", byggda == #UBRFKomplex.mark,
		("%d byggda av %d i datan"):format(byggda, #UBRFKomplex.mark))
	check("och varje byggt marklager KOLLIDERAR", #utanStod == 0,
		#utanStod > 0 and ("utan kollision: " .. table.concat(utanStod, ", "))
			or ("%d lager bär"):format(byggda))
end

--[[ ══ 2. INGEN PUNKT PÅ TOMTEN SAKNAR MARK ═════════════════════════════
	Det direkta påståendet om felet. Rutnätet är grovt med flit — det här
	mäter inte gångbarhet mellan väggar, det mäter att det finns något
	under fötterna överallt där en spelare kan hamna. ]]
local RUTA = 2.0
do
	local utan, provade = {}, 0
	local nx = math.floor(UBRFKomplex.bredd / RUTA)
	local nz = math.floor(UBRFKomplex.djup / RUTA)
	for ix = 0, nx do
		for iz = 0, nz do
			local x = math.min(ix * RUTA, UBRFKomplex.bredd - 0.01)
			local z = math.min(iz * RUTA, UBRFKomplex.djup - 0.01)
			provade += 1
			if stodI(x, z) == nil then
				if #utan < 6 then
					table.insert(utan, ("(%.0f, %.0f)"):format(x, z))
				end
			end
		end
	end
	check("ingen punkt på tomten saknar mark under fötterna", #utan == 0,
		#utan > 0 and ("hål vid " .. table.concat(utan, " ") .. " …")
			or ("%d punkter provade"):format(provade))
end

--[[ ══ 3. DE REPRESENTATIVA YTORNA ═══════════════════════════════════════
	Punkterna HÄRLEDS ur geometrin — marklagrens egna mittpunkter och
	byggnadernas egna mitter — så att inga koordinater hittas på här. ]]
do
	local rapport = {}
	for _, m in ipairs(UBRFKomplex.mark) do
		local x = m.rekt.x + m.rekt.w / 2
		local z = m.rekt.y + m.rekt.h / 2
		local y = stodI(x, z)
		if y == nil then table.insert(rapport, m.typ) end
	end
	check("varje markytas egen mittpunkt bär", #rapport == 0,
		#rapport > 0 and table.concat(rapport, ", ")
			or (#UBRFKomplex.mark .. " ytor provade"))

	--[[ Vägen MELLAN byggnaderna: elva punkter jämnt fördelade på linjen
		mellan varje par av byggnadsmitter. Det är den sträcka en spelare
		leder hästen längs, och den som förut gick rakt ut i tomrummet. ]]
	local hus = {}
	for _, b in ipairs(UBRFKomplex.byggnader) do
		table.insert(hus, { id = b.id,
			x = b.rekt.x + b.rekt.w / 2, z = b.rekt.y + b.rekt.h / 2 })
	end
	local trasiga, strackor = {}, 0
	for i = 1, #hus do
		for j = i + 1, #hus do
			strackor += 1
			for k = 0, 10 do
				local t = k / 10
				local x = hus[i].x + (hus[j].x - hus[i].x) * t
				local z = hus[i].z + (hus[j].z - hus[i].z) * t
				if stodI(x, z) == nil and #trasiga < 6 then
					table.insert(trasiga, ("%s→%s vid %.0f%%"):format(hus[i].id, hus[j].id, t * 100))
				end
			end
		end
	end
	check("sträckorna mellan byggnaderna bär hela vägen", #trasiga == 0,
		#trasiga > 0 and table.concat(trasiga, " · ")
			or ("%d sträckor mellan %d byggnader"):format(strackor, #hus))
end

--[[ ══ 4. STEGET UT FRÅN SPAWNEN ═════════════════════════════════════════
	Det Tobias faktiskt gjorde: stod på plattan framför entrén och gick
	därifrån. Ringen runt spawnen mäts i åtta riktningar och tre avstånd. ]]
do
	local spawn = nil
	for _, d in ipairs(workspace:GetDescendants()) do
		if d.ClassName == "SpawnLocation" and d:GetAttribute("UBRFStart") == true then
			spawn = d
		end
	end
	check("spawnen finns och är märkt UBRFStart", spawn ~= nil,
		spawn and spawn.Name or "ingen")
	if spawn then
		local sx, sz = BuildKit.tomtkoord(bas, spawn.CFrame.Position)
		check("spawnen själv står på något", stodI(sx, sz) ~= nil,
			("(%.1f, %.1f)"):format(sx, sz))
		local hal = {}
		for _, avstand in ipairs({ 2.0, 5.0, 10.0 }) do
			for v = 0, 7 do
				local vinkel = v * math.pi / 4
				local x = sx + math.cos(vinkel) * avstand
				local z = sz + math.sin(vinkel) * avstand
				if x >= 0 and x <= UBRFKomplex.bredd and z >= 0 and z <= UBRFKomplex.djup then
					if stodI(x, z) == nil then
						table.insert(hal, ("%.0f m i riktning %d"):format(avstand, v))
					end
				end
			end
		end
		check("och man kan gå därifrån åt alla håll utan att falla", #hal == 0,
			#hal > 0 and table.concat(hal, " · ") or "24 punkter runt spawnen bär")
	end
end

--[[ ══ 4b. STÖDET HÄNGER IHOP HELA VÄGEN ═══════════════════════════════

	Att varje punkt HAR mark räcker inte som påstående om att man kan gå
	dit: två plan på olika höjd har också mark i varje punkt. Den här
	mätningen sprider sig från spawnen över de punkter som bär, och tillåter
	bara steg en Humanoid klarar (0,55 m). Når den varje markytas mitt
	hänger det uppburna underlaget ihop.

	Väggar räknas INTE som hinder här. Det är med flit: det här är en
	mätning av UNDERLAGET, inte av vägen mellan rum — den senare äger
	`spelbarhet.spec`, och den sammanblandningen var just det som gjorde att
	hålet i marken aldrig syntes. ]]
do
	local STEG = 0.55
	local nx = math.floor(UBRFKomplex.bredd / RUTA)
	local nz = math.floor(UBRFKomplex.djup / RUTA)
	local function punkt(ix, iz)
		return math.min(ix * RUTA, UBRFKomplex.bredd - 0.01),
			math.min(iz * RUTA, UBRFKomplex.djup - 0.01)
	end
	local hojd, nadd = {}, {}
	local function nyckel(ix, iz) return iz * (nx + 1) + ix end
	for ix = 0, nx do
		for iz = 0, nz do
			local x, z = punkt(ix, iz)
			hojd[nyckel(ix, iz)] = stodI(x, z)
		end
	end

	local spawn = nil
	for _, d in ipairs(workspace:GetDescendants()) do
		if d.ClassName == "SpawnLocation" and d:GetAttribute("UBRFStart") == true then
			spawn = d
		end
	end
	local spawnX, spawnY = 0, 0
	if spawn then spawnX, spawnY = BuildKit.tomtkoord(bas, spawn.CFrame.Position) end
	local startIx = math.floor(spawnX / RUTA)
	local startIz = math.floor(spawnY / RUTA)
	local ko = { { startIx, startIz } }
	nadd[nyckel(startIx, startIz)] = true
	local raknare = 0
	while #ko > 0 do
		local c = table.remove(ko)
		raknare += 1
		local h = hojd[nyckel(c[1], c[2])]
		for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
			local ix, iz = c[1] + d[1], c[2] + d[2]
			if ix >= 0 and ix <= nx and iz >= 0 and iz <= nz then
				local k = nyckel(ix, iz)
				local hn = hojd[k]
				if not nadd[k] and hn ~= nil and h ~= nil and math.abs(hn - h) <= STEG then
					nadd[k] = true
					table.insert(ko, { ix, iz })
				end
			end
		end
	end

	local onadda = {}
	for _, m in ipairs(UBRFKomplex.mark) do
		local x = m.rekt.x + m.rekt.w / 2
		local z = m.rekt.y + m.rekt.h / 2
		local ix = math.floor(x / RUTA)
		local iz = math.floor(z / RUTA)
		if not nadd[nyckel(ix, iz)] and #onadda < 6 then
			table.insert(onadda, m.typ)
		end
	end
	check("stödet hänger ihop från spawnen till varje markytas mitt",
		#onadda == 0,
		#onadda > 0 and ("onådda: " .. table.concat(onadda, ", "))
			or ("%d punkter nådda från spawnen"):format(raknare))
end

--[[ ══ 5. MARKEN LIGGER I ETT PLAN — OCH UNDER GOLVEN ══════════════════

	Första versionen krävde att alla marklager hade EXAKT samma ovansida.
	Avsikten var rätt — inget osynligt steg mitt på gården — men kravet var
	för starkt, och P1-4 i Tobias andra Studio-test visade varför: femton
	coplanära ytor är odefinierade för djupbufferten. Gräsmattan täcker
	hela tomten och låg i samma plan som grusplanen, så renderaren visade
	en slumpmässig blandning, och inne i husen blev gräset det man såg.

	Kravet är därför nu det som avsikten egentligen var:

	  1. ingen höjdskillnad mellan två marklager får vara ett STEG
	     (avatarens tröskel är 0,55 m; marginalen här är 0,05 m),
	  2. och HELA marken ligger under husgolvens nivå 0, så att ett golv
	     alltid vinner inomhus.

	Det är en svagare regel på punkt 1 och en ny, starkare regel på punkt
	2 — och det är punkt 2 som fångar felet Tobias såg. ]]
do
	local hojder, lista = {}, {}
	for _, d in ipairs(modell:GetDescendants()) do
		if d.GetAttribute and typeof(d:GetAttribute("UBRFMark")) == "string" then
			local y = (d.CFrame.Position.Y + d.Size.Y / 2) / M
			table.insert(lista, y)
			hojder[("%.3f"):format(y)] = true
		end
	end
	table.sort(lista)
	local lagst, hogst = lista[1], lista[#lista]
	check("inget marklager bildar ett steg mot ett annat",
		#lista > 0 and (hogst - lagst) <= 0.05,
		("%d lager, %.3f m till %.3f m (spann %.3f m)")
			:format(#lista, lagst or 0, hogst or 0, (hogst or 0) - (lagst or 0)))
	check("och hela marken ligger UNDER husgolven, så inget gräs kan ligga överst inomhus",
		#lista > 0 and hogst < 0,
		("högsta marklager %.3f m mot husgolvens 0"):format(hogst or 0))

	--[[ Att lagren dessutom har SKILDA nivåer är vad som gör ordningen
		entydig för djupbufferten. Lika nivåer är inte ett steg, men de är
		det som gav fläckarna av gräs på grusplanen. ]]
	local unika = 0
	for _ in pairs(hojder) do unika += 1 end
	check("varje marklager har sin egen nivå — ingen coplanär z-fight",
		unika == #lista, ("%d nivåer för %d lager"):format(unika, #lista))
end

if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error("mark.spec: " .. fails .. " fel")
end
print("\nmark.spec: alla gröna")
