--!nostrict
--[[
	PHYSICAL_WORLD_COHERENCE_GATE — stämmer världen med spelet?

	Bindande arbetsorder på #162 efter Tobias fysiska Studio-test av
	`first-playable-place-6a0e5d7`. Sex fel som ingen maskingrind såg:

	  P0-1  en grind i spelet som verkligheten saknar
	  P0-2  utrustningssteget saknar fysisk sadel/utrustningsplats
	  P0-3  instruktions-HUD:en ur synk med spelarens kontext
	  P1-4  gräs syns inne i byggnad
	  P0-5  inga hästar i stallet
	  P0-6  passage med prompt men ingen genomgång

	VARFÖR DE ÖVERLEVDE. Grindarna mätte kedjan spawn → entrédörr → Jacks
	box, och den kedjan var grön. Det som aldrig mättes var VÄRLDEN SOM
	HELHET: de andra tretton dörrarna, de andra trettiotvå hästarna,
	golvet under interiörerna, och om instruktionen på skärmen svarar mot
	något som finns.

	Den här grinden mäter det, på den byggda världen.

	Kör: python3 roblox/tests/build.py tests/varldskoherens.spec.luau
	     && luau roblox/tests/.build/varldskoherens.spec.luau
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
local function matning(namn, detalj)
	print(string.format("  mät  %s%s", namn, detalj and ("  " .. detalj) or ""))
end

local M = BuildKit.M
local G = UBRFKomplex
local modell = workspace:FindFirstChild("Anläggning"):FindFirstChild("UBRF")
local bas = modell.PrimaryPart.CFrame

--[[ Avatarens mått, samma tal som END_TO_END_PLAYABILITY_GATE. Två grindar
	som mäter samma avatar med olika mått hade varit två sanningar. ]]
local RADIE, HOJD, STEG, MAXGOLV, CELL = 0.35, 1.75, 0.55, 3.0, 0.25

--[[ Alla kolliderande delar EN gång, i kartans koordinater. `tomtkoord` är
	vägen tillbaka från den vända världen; se BuildKit.tomtlage. ]]
local alla = {}
for _, d in ipairs(modell:GetDescendants()) do
	if d.CFrame and d.Size and d.CanCollide ~= false and d.Transparency ~= 1 then
		local c, s = d.CFrame.Position, d.Size
		local cx, cz = BuildKit.tomtkoord(bas, c)
		table.insert(alla, {
			namn = d.Name, del = d,
			x0 = cx - s.X / (2 * M), x1 = cx + s.X / (2 * M),
			z0 = cz - s.Z / (2 * M), z1 = cz + s.Z / (2 * M),
			y0 = (c.Y - s.Y / 2) / M, y1 = (c.Y + s.Y / 2) / M,
		})
	end
end

--[[ ══ EN LOKAL KONFIGURATIONSRYMD ══════════════════════════════════════

	Hela tomten är 210×170 m; ett rutnät över allt hade blivit en halv
	miljon celler per dörr. Varje prov bygger därför sin egen lilla karta
	kring det som mäts. Metoden är densamma som i END_TO_END: varje hinder
	blåses upp med avatarens radie och sökningen sker för en PUNKT. ]]
local function karta(x0, z0, x1, z1, utan)
	local NX = math.ceil((x1 - x0) / CELL)
	local NZ = math.ceil((z1 - z0) / CELL)
	local k = {
		NX = NX, NZ = NZ, x0 = x0, z0 = z0,
		golv = {}, blockerad = {},
		idx = function(ix, iz) return (iz - 1) * NX + ix end,
		cellFor = function(x, z)
			return math.floor((x - x0) / CELL) + 1, math.floor((z - z0) / CELL) + 1
		end,
		mitt = function(ix, iz)
			return x0 + (ix - 0.5) * CELL, z0 + (iz - 0.5) * CELL
		end,
	}
	local lista = {}
	for _, l in ipairs(alla) do
		if l.x1 >= x0 - 1 and l.x0 <= x1 + 1 and l.z1 >= z0 - 1 and l.z0 <= z1 + 1
			and l.del ~= utan then
			table.insert(lista, l)
		end
	end

	--[[ ══ VILKEN YTA STÅR MAN PÅ? ════════════════════════════════════════

		END_TO_END-grinden tar den HÖGSTA ytan under MAXGOLV. Den regeln
		stämmer för staplade plan — man står på läktardäcket, inte på marken
		under det — men den gör ett SKÄRMTAK till ett golv. Skärmtaket över
		en entrédörr ligger på 2,63 m, alltså under MAXGOLV, och då blev
		marken utanför dörren "golv 2,63" och steget dit 2,63 m. Sex av de
		elva dörrar som föll här föll på just det, och de är inte trasiga i
		världen — en avatar går obehindrat under ett tak i 2,5 m.

		Regeln här är i stället fysisk:

		    man står på den LÄGSTA yta man får plats ovanpå.

		Marken under skärmtaket har 2,5 m fritt ovanför sig och väljs.
		Marken under läktardäcket har 1,70 m — mindre än avatarens 1,75 —
		så där väljs däcket. Samma regel ger båda svaren. ]]
	local ytor = {}
	for _, l in ipairs(lista) do
		local ax0, az0 = k.cellFor(l.x0, l.z0)
		local ax1, az1 = k.cellFor(l.x1, l.z1)
		for iz = math.max(1, az0), math.min(NZ, az1) do
			for ix = math.max(1, ax0), math.min(NX, ax1) do
				local mx, mz = k.mitt(ix, iz)
				if mx >= l.x0 and mx <= l.x1 and mz >= l.z0 and mz <= l.z1 then
					local i = k.idx(ix, iz)
					local t = ytor[i]
					if t == nil then t = {}; ytor[i] = t end
					table.insert(t, l)
				end
			end
		end
	end
	for i, t in pairs(ytor) do
		local kandidater = {}
		for _, l in ipairs(t) do
			if l.y1 <= MAXGOLV then table.insert(kandidater, l.y1) end
		end
		table.sort(kandidater)
		for _, y in ipairs(kandidater) do
			local fritt = true
			for _, l in ipairs(t) do
				if l.y1 > y + 0.001 and l.y0 < y + HOJD then fritt = false break end
			end
			if fritt then k.golv[i] = y break end
		end
		--[[ Ingen yta har full takhöjd: då står man ändå på den högsta —
			ett för lågt utrymme är en blockering, inte ett hål i världen,
			och det avgörs i nästa pass. ]]
		if k.golv[i] == nil and #kandidater > 0 then
			k.golv[i] = kandidater[#kandidater]
		end
	end

	for _, l in ipairs(lista) do
		local ax0, az0 = k.cellFor(l.x0 - RADIE, l.z0 - RADIE)
		local ax1, az1 = k.cellFor(l.x1 + RADIE, l.z1 + RADIE)
		for iz = math.max(1, az0), math.min(NZ, az1) do
			for ix = math.max(1, ax0), math.min(NX, ax1) do
				local i = k.idx(ix, iz)
				local g = k.golv[i]
				if g ~= nil and not k.blockerad[i] then
					local mx, mz = k.mitt(ix, iz)
					if mx >= l.x0 - RADIE and mx <= l.x1 + RADIE
						and mz >= l.z0 - RADIE and mz <= l.z1 + RADIE then
						if l.y1 > g + STEG and l.y0 < g + HOJD then
							k.blockerad[i] = true
						end
					end
				end
			end
		end
	end
	return k
end

local function gangbar(k, ix, iz)
	if ix < 1 or iz < 1 or ix > k.NX or iz > k.NZ then return false end
	local i = k.idx(ix, iz)
	return k.golv[i] ~= nil and not k.blockerad[i]
end

local function sok(k, fran, till)
	local sx, sz = k.cellFor(fran.x, fran.y)
	local tx, tz = k.cellFor(till.x, till.y)
	if not gangbar(k, sx, sz) then return nil, "startcellen är inte gångbar" end
	if not gangbar(k, tx, tz) then return nil, "målcellen är inte gångbar" end
	local ko, huvud = { { sx, sz } }, 1
	local steg = { [k.idx(sx, sz)] = 0 }
	while huvud <= #ko do
		local c = ko[huvud]; huvud += 1
		if c[1] == tx and c[2] == tz then return steg[k.idx(c[1], c[2])] end
		for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
			local nx, nz = c[1] + d[1], c[2] + d[2]
			local ni = k.idx(nx, nz)
			if gangbar(k, nx, nz) and steg[ni] == nil
				and math.abs(k.golv[ni] - k.golv[k.idx(c[1], c[2])]) <= STEG then
				steg[ni] = steg[k.idx(c[1], c[2])] + 1
				table.insert(ko, { nx, nz })
			end
		end
	end
	return nil, "ingen sammanhängande gångväg"
end

--[[ ══ 4. TRAVERSAL — VARJE DÖRR PROVAS GENOM ATT GÅ IGENOM DEN ═════════

	Ordern, punkt 4: "alla gameplay-kritiska dörrar/gates ska verifieras
	genom faktisk traversal, inte bara prompt/collision-toggle. Testet
	måste bevisa: approach → prompt → open → passage clearance → avatar kan
	gå igenom → andra sidan har bärande mark → kan återvända."

	P0-6 var precis det som saknades: prompten fanns, bladet slutade
	kollidera, och spelaren kom ändå inte ut. En collision-toggle bevisar
	att BLADET flyttade sig, inte att det finns en väg. ]]
print("\n4. TRAVERSAL — varje uppmärkt dörr, i båda riktningar")

--[[ Skanningarna är funktioner och inte listor: mutationerna längst ned
	ändrar världen, och då måste mätningen göras om mot den ändrade
	världen — inte mot ett minne av den gamla. ]]
local function scanBlad()
	local ut = {}
	for _, d in ipairs(modell:GetDescendants()) do
		if d:GetAttribute("UBRFDorr") == true then table.insert(ut, d) end
	end
	return ut
end
local function scanDeklarerade()
	local ut = {}
	for _, d in ipairs(modell:GetDescendants()) do
		if typeof(d:GetAttribute("IngenPassage")) == "string" then
			table.insert(ut, d)
		end
	end
	return ut
end
local blad = scanBlad()
check("världen har uppmärkta dörrblad att prova", #blad > 0, ("%d blad"):format(#blad))

--[[ `Utat` pekar ut från fasaden längs den axel väggen INTE löper i:
	along == "X" ⇒ normalen är kartans y-axel, annars x-axeln.
	Talen kommer ur `Geometri.oppningsHorn`, samma källa bygget använder. ]]
--[[ `Utat` pekar ut från fasaden längs den axel väggen INTE löper i:
	along == "X" ⇒ normalen är kartans y-axel, annars x-axeln.
	Talen kommer ur `Geometri.oppningsHorn`, samma källa bygget använder. ]]
local UT = 0.9        -- mer än väggens 0,3 m, så punkterna hamnar på var sin sida

local function idFor(b)
	return ("%s %s %s"):format(tostring(b:GetAttribute("Byggnad")),
		tostring(b:GetAttribute("Sida")), tostring(b:GetAttribute("Oppningstyp")))
end

--[[ Går det att gå igenom? Returnerar (ok, text, karta, mittpunkt).

	Kontraktet ur ordern, punkt 4: approach → open → passage clearance →
	avatar kan gå igenom → andra sidan har bärande mark → kan återvända.
	Stängd dörr ska dessutom SPÄRRA — annars mäter provet inte dörren. ]]
local function provaPassage(b)
	local c = b.CFrame.Position
	local cx, cz = BuildKit.tomtkoord(bas, c)
	local along = b:GetAttribute("Langs")
	local utat = b:GetAttribute("Utat") or 1
	local nx, nz = 0, 0
	if along == "X" then nz = utat else nx = utat end

	local ute = { x = cx + nx * UT, y = cz + nz * UT }
	local inne = { x = cx - nx * UT, y = cz - nz * UT }
	local R = 8.0
	local x0 = math.min(ute.x, inne.x) - R
	local x1 = math.max(ute.x, inne.x) + R
	local z0 = math.min(ute.y, inne.y) - R
	local z1 = math.max(ute.y, inne.y) + R

	local kStangd = karta(x0, z0, x1, z1)
	local nStangd = sok(kStangd, ute, inne)
	local kOppen = karta(x0, z0, x1, z1, b)
	local ut2in, varfor = sok(kOppen, ute, inne)
	local in2ut = sok(kOppen, inne, ute)
	local golvUte = kOppen.golv[kOppen.idx(kOppen.cellFor(ute.x, ute.y))]
	local golvInne = kOppen.golv[kOppen.idx(kOppen.cellFor(inne.x, inne.y))]

	local ok = ut2in ~= nil and in2ut ~= nil
		and golvUte ~= nil and golvInne ~= nil
	local text = ("stängd %s · öppen %s · mark ute %s inne %s"):format(
		nStangd and ("PASSERBAR (" .. nStangd .. ")") or "spärrad",
		ut2in and ("ut→in " .. ut2in .. " celler") or ("STOPP: " .. tostring(varfor)),
		golvUte and ("%.2f"):format(golvUte) or "SAKNAS",
		golvInne and ("%.2f"):format(golvInne) or "SAKNAS")
	return ok, text, kOppen, { x = cx, z = cz, nx = nx, nz = nz, along = along }
end

--[[ Kartan kring en öppning som föll, ritad ur SAMMA rutnät som sökningen
	använde. En grind som bara säger "ingen väg" tvingar nästa person att
	bygga om felsökningen från noll. ]]
local function skrivKarta(k, m)
	local ccx, ccz = k.cellFor(m.x, m.z)
	local dlangs = if m.along == "X" then 1 else 0
	print("      karta kring öppningen (. gångbar, # blockerad, ' ' inget golv, D dörrmitt)")
	for a = -6, 6 do
		local rad = ""
		for bq = -8, 8 do
			local ix = ccx + (if dlangs == 1 then bq else a)
			local iz = ccz + (if dlangs == 1 then a else bq)
			local i = k.idx(ix, iz)
			local t = " "
			if ix >= 1 and iz >= 1 and ix <= k.NX and iz <= k.NZ then
				t = if k.golv[i] == nil then " "
					elseif k.blockerad[i] then "#" else "."
			end
			if a == 0 and bq == 0 then t = "D" end
			rad = rad .. t
		end
		print("      |" .. rad .. "|")
	end
	for a = -3, 3 do
		local ix = ccx + (if dlangs == 1 then 0 else a)
		local iz = ccz + (if dlangs == 1 then a else 0)
		if ix >= 1 and iz >= 1 and ix <= k.NX and iz <= k.NZ then
			local mx, mz = k.mitt(ix, iz)
			local i = k.idx(ix, iz)
			local g2 = k.golv[i]
			local namn = {}
			for _, l in ipairs(alla) do
				if g2 ~= nil
					and mx >= l.x0 - RADIE and mx <= l.x1 + RADIE
					and mz >= l.z0 - RADIE and mz <= l.z1 + RADIE
					and l.y1 > g2 + STEG and l.y0 < g2 + HOJD then
					table.insert(namn, ("%s[y %.2f–%.2f]"):format(l.namn, l.y0, l.y1))
				end
			end
			print(("      rad %+d (%.2f, %.2f) golv %s: %s"):format(a, mx, mz,
				g2 and ("%.2f"):format(g2) or "—",
				#namn > 0 and table.concat(namn, " · ") or "FRI"))
		end
	end
end

local misslyckade = {}
for _, b in ipairs(blad) do
	local ok, text, k, m = provaPassage(b)
	matning(("%-28s"):format(idFor(b)), text)
	if not ok then
		table.insert(misslyckade, idFor(b))
		skrivKarta(k, m)
	end
end

--[[ ══ OCH INGEN ÖPPNING FÅR TYSTNA ═══════════════════════════════════

	Utan den här halvan går grinden ovan att göra grön genom att sluta
	märka upp dörrar. Kontraktet är därför tvåsidigt:

	  varje genomgående öppning i datan är ANTINGEN ett uppmärkt,
	  passerbart dörrblad ELLER en deklarerad icke-passage med ett skäl,

	och en deklarerad icke-passage måste dessutom VARA blockerad. En rad i
	listan som inte behövs är en rad som döljer en dörr som fungerar. ]]
local function arFonster(typ) return typ == "fonster" or typ == "rund" or typ == "valv" end
local genomgaende = 0
for _, bg in ipairs(G.byggnader) do
	for _, o in ipairs(bg.oppningar or {}) do
		if not arFonster(o.typ) and (o.z0 or 0) <= 0.001 then genomgaende += 1 end
	end
end
local deklarerade = scanDeklarerade()
check("varje genomgående öppning är antingen en dörr eller en deklarerad icke-passage",
	#blad + #deklarerade == genomgaende,
	("%d uppmärkta + %d deklarerade = %d mot %d genomgående öppningar i datan")
		:format(#blad, #deklarerade, #blad + #deklarerade, genomgaende))

for _, d in ipairs(deklarerade) do
	local id = ("%s %s %s"):format(tostring(d:GetAttribute("Byggnad")),
		tostring(d:GetAttribute("Sida")), tostring(d:GetAttribute("Oppningstyp")))
	matning(("icke-passage: %s"):format(id),
		tostring(d:GetAttribute("IngenPassage")):sub(1, 120))
end
local onodiga = {}
for _, d in ipairs(deklarerade) do
	local ok = provaPassage(d)
	if ok then table.insert(onodiga, idFor(d)) end
end
check("varje deklarerad icke-passage är faktiskt blockerad — ingen onödig rad",
	#onodiga == 0,
	#onodiga == 0 and ("%d deklarerade, alla blockerade"):format(#deklarerade)
		or ("dessa GÅR att passera och ska inte vara deklarerade: " .. table.concat(onodiga, ", ")))

check("varje dörr går att gå igenom i BÅDA riktningar när den är öppen",
	#misslyckade == 0,
	if #misslyckade == 0 then ("%d av %d"):format(#blad, #blad)
	else ("%d dörr(ar) faller: %s"):format(#misslyckade,
		(function()
			local n = {}
			for _, f in ipairs(misslyckade) do table.insert(n, f.id) end
			return table.concat(n, ", ")
		end)()))

--[[ ══ 2. HÄSTARNA FINNS SOM MODELLER I VÄRLDEN ══════════════════════════

	Ordern, punkt 2: "skilj på 'häst finns i data/testharness' och 'häst
	finns i actual place'."

	Rostergrinden riggar 33 hästar en i taget i en bänk och river dem. Den
	bevisar att riggen GÅR att bygga — inte att någon står i stallet. ]]
print("\n2. HÄSTARNA — modeller i workspace, inte rader i en tabell")

HastRigg.start()

local iVarlden = {}
for _, d in ipairs(workspace:GetDescendants()) do
	local hid = d:GetAttribute("HorseId")
	if hid then iVarlden[tostring(hid)] = d end
end

local roster = {}
for id in pairs((UBRFSpelData :: any).hastar or {}) do table.insert(roster, id) end
table.sort(roster)
check("rostern har hästar att placera", #roster > 0, ("%d kanoniska hästar"):format(#roster))

--[[ Rostern mäts om vid varje anrop: mutationen river en modell, och en
	lista tagen i förväg hade inte märkt det. ]]
local function iVarldenNu()
	local ut = {}
	for _, d in ipairs(workspace:GetDescendants()) do
		local hid = d:GetAttribute("HorseId")
		if hid then ut[tostring(hid)] = d end
	end
	return ut
end
local function saknadeHastar()
	local finns = iVarldenNu()
	local ut = {}
	for _, id in ipairs(roster) do
		if not finns[id] then table.insert(ut, id) end
	end
	return ut
end

local saknas, felplacerade = saknadeHastar(), {}
for _, id in ipairs(roster) do
	local m = iVarlden[id]
	if m then
		local box = (Stallet :: any).boxFor(id)
		local p = (m :: any).PrimaryPart or (m :: any):FindFirstChild("BodyCollider")
		if box and box.varld and p then
			local px, pz = BuildKit.tomtkoord(bas, p.CFrame.Position)
			local d = math.sqrt((px - box.varld.x) ^ 2 + (pz - box.varld.y) ^ 2)
			if d > 2.0 then table.insert(felplacerade, ("%s %.1f m"):format(id, d)) end
		end
	end
end

check("varje kanonisk häst finns som modell i workspace",
	#saknas == 0,
	if #saknas == 0 then ("%d av %d"):format(#roster, #roster)
	else ("%d saknas i den byggda världen (%s%s)"):format(#saknas, saknas[1],
		#saknas > 1 and (" … +" .. (#saknas - 1)) or ""))
check("och står i sin egen box", #felplacerade == 0,
	#felplacerade == 0 and "alla inom 2 m från boxens mitt"
		or table.concat(felplacerade, " · "))

--[[ ══ 3. UTRUSTNINGEN FINNS FYSISKT, OCH GÅR ATT NÅ ═══════════════════

	Ordern, punkt 3: "skötsel-/utrustningssteg har nödvändiga fysiska
	objekt eller tydligt avsedd interaktionspunkt i rätt miljö."

	P0-2: spelaren ska göra hästen redo, men miljön saknade en begriplig
	sadel-/utrustningskontext.

	Mätt: utrustningsplatsen FINNS — sadelkammaren i stallets klubbdel,
	byggd ur `G.inredning` med västkrokar och stövelhylla. Det som saknas
	är inte geometri utan en väg och en anvisning. Grinden kräver därför
	det som går att kräva utan att hitta på UBRF-detaljer:

	  a) det finns en fysisk utrustningsplats i den byggda världen,
	  b) den ligger inne i en byggnad, inte på en gräsmatta,
	  c) och den går att GÅ till från hästens box.

	Att spelet dessutom ska PEKA dit är ett designbeslut — antingen leds
	spelaren till sadelkammaren, eller så ställs en sadel vid boxen, och
	det senare vore ny inredning i en interiör som är fidelity-styrd.
	Beslutet ligger hos Tobias och står i PR-kommentaren. ]]
print("\n3. Utrustningen finns fysiskt och går att nå")

local function utrustningsdelar()
	local ut = {}
	for _, d in ipairs(modell:GetDescendants()) do
		local id = d:GetAttribute("Inredning")
		if typeof(id) == "string" and string.sub(id, 1, 6) == "sadel_" then
			table.insert(ut, d)
		end
	end
	return ut
end
local utrustning = utrustningsdelar()
check("det finns en fysisk utrustningsplats i den byggda världen",
	#utrustning > 0, ("%d delar märkta sadel_*"):format(#utrustning))

if #utrustning > 0 then
	local sx, sz, n = 0, 0, 0
	for _, d in ipairs(utrustning) do
		local cx, cz = BuildKit.tomtkoord(bas, d.CFrame.Position)
		sx, sz, n = sx + cx, sz + cz, n + 1
	end
	local mx, mz = sx / n, sz / n

	local inne = nil
	for _, b in ipairs(G.byggnader) do
		local r = b.rekt
		if mx >= r.x and mx <= r.x + r.w and mz >= r.y and mz <= r.y + r.h then
			inne = b.id
		end
	end
	check("och den ligger inne i en byggnad", inne ~= nil,
		("(%.1f, %.1f) i %s"):format(mx, mz, tostring(inne)))

	--[[ Vägen ENTRÉN → utrustningsplatsen, mätt i samma konfigurationsrymd
		som dörrarna. Ett avstånd hade sagt att det är nära; det här säger
		att det GÅR.

		Starten är punkten strax innanför stallets ockragula nordentré —
		samma punkt END_TO_END använder, och den enda som är GIVEN: en cell
		kan vara gångbar utan att vara nåbar, och boxens insida är precis
		det (boxfronten står emellan, och så ska det vara). Att starta i
		"närmaste gångbara cell vid boxen" hade kunnat starta inne i boxen
		och mätt en väg ingen kan gå. ]]
	local stall2, dorr2 = nil, nil
	for _, b in ipairs(G.byggnader) do if b.id == "stall" then stall2 = b end end
	for _, o in ipairs((stall2 and stall2.oppningar) or {}) do
		if o.sida == "N" and o.typ == "dorrgul" then dorr2 = o end
	end
	if stall2 and dorr2 then
		local dmx, dmz = Geometri.oppningsMitt(stall2.rekt, "N", dorr2.u, dorr2.b)
		local innanfor = { x = dmx, y = dmz - 0.9 }
		local mal = { x = mx, y = mz }
		local x0 = math.min(innanfor.x, mal.x) - 12
		local x1 = math.max(innanfor.x, mal.x) + 12
		local z0 = math.min(innanfor.y, mal.y) - 12
		local z1 = math.max(innanfor.y, mal.y) + 12
		local k = karta(x0, z0, x1, z1)
		local steg, varfor = sok(k, innanfor, mal)
		check("och den går att GÅ till från stallets entré",
			steg ~= nil,
			steg and ("%d celler (%.1f m)"):format(steg, steg * CELL)
				or tostring(varfor))
	end
end

--[[ ══ 5. INTERIÖRERNA HAR GOLV — INGET GRÄS BLÖDER IGENOM ═══════════════

	Ordern, punkt 5: "ingen utomhusmark får blöda genom spelbar interiör."

	Marklagren byggs över HELA tomten och ligger nu dessutom kolliderande
	(P0 marken bär). Står ett marklager överst i en punkt inomhus ser
	spelaren gräs på golvet. ]]
print("\n5. INTERIÖRERNA — golv, inte gräs")

local function oversta(x, z)
	local basta, del = nil, nil
	for _, l in ipairs(alla) do
		if x >= l.x0 and x <= l.x1 and z >= l.z0 and z <= l.z1
			and l.y1 <= MAXGOLV and (basta == nil or l.y1 > basta) then
			basta, del = l.y1, l
		end
	end
	return basta, del
end

local INTERIORER = {}
for _, b in ipairs(G.byggnader) do
	if b.id == "stall" or b.id == "ridhus" then
		table.insert(INTERIORER, { id = b.id, r = b.rekt })
	end
end

local STEGM = 1.0
local function markOverst(iv)
	local gras, provade = {}, 0
	local r = iv.r
	local x = r.x + 1.0
	while x < r.x + r.w - 1.0 do
		local z = r.y + 1.0
		while z < r.y + r.h - 1.0 do
			provade += 1
			local _, del = oversta(x, z)
			if del and del.del:GetAttribute("UBRFMark") ~= nil then
				table.insert(gras, { x = x, z = z, namn = del.namn })
			end
			z += STEGM
		end
		x += STEGM
	end
	return gras, provade
end

for _, iv in ipairs(INTERIORER) do
	local gras, provade = markOverst(iv)
	local detalj = ("%d punkter provade"):format(provade)
	if #gras > 0 then
		local x0, x1, z0, z1 = 1e9, -1e9, 1e9, -1e9
		local typer = {}
		for _, p2 in ipairs(gras) do
			x0 = math.min(x0, p2.x); x1 = math.max(x1, p2.x)
			z0 = math.min(z0, p2.z); z1 = math.max(z1, p2.z)
			typer[p2.namn] = (typer[p2.namn] or 0) + 1
		end
		local tn = {}
		for k2, v in pairs(typer) do table.insert(tn, ("%s×%d"):format(k2, v)) end
		table.sort(tn)
		detalj = ("%d av %d punkter, x %.0f–%.0f y %.0f–%.0f, %s")
			:format(#gras, provade, x0, x1, z0, z1, table.concat(tn, " · "))
	end
	check(("%s: inget marklager ligger överst inomhus"):format(iv.id), #gras == 0, detalj)
end

--[[ ══ 7b. SKYLTPARITET — KANON SOM INTE BYGGS ÄR INTE BYGGD ═══════════

	Blockerare ur Tobias tredje Studio-test: skylten UPPLANDS-BRO
	RYTTARFÖRENING saknas i Roblox trots att den ligger i källkanon och i
	den exporterade anläggningsdatan. Ett paritetsfel, inte ett
	designönskemål.

	Regeln: varje skylt i `G.props` ska finnas som en byggd del med sin
	text. Provet läser EXPORTEN och letar i den BYGGDA världen — inte
	tvärtom. Ett prov som utgår från det byggda kan aldrig se det som
	aldrig byggdes. ]]
print("\n7b. Skyltparitet — varje kanonisk skylt finns i världen")

local SKYLTTYPER = { skylt = true, cafeskylt = true }
local function byggdaSkyltar()
	local ut = {}
	for _, d in ipairs(modell:GetDescendants()) do
		local t = d:GetAttribute("Propstyp")
		if typeof(t) == "string" then table.insert(ut, d) end
	end
	return ut
end
local function saknadeSkyltar()
	local byggda = byggdaSkyltar()
	local ut = {}
	for _, pr in ipairs(G.props or {}) do
		if SKYLTTYPER[pr.typ] then
			local x, z = pr.pos[1], pr.pos[2]
			local hittad = false
			for _, d in ipairs(byggda) do
				local cx, cz = BuildKit.tomtkoord(bas, d.CFrame.Position)
				if math.abs(cx - x) < 0.5 and math.abs(cz - z) < 0.5
					and d:GetAttribute("Propstyp") == pr.typ then
					hittad = true
				end
			end
			if not hittad then
				table.insert(ut, ("%s vid (%.1f, %.1f)"):format(pr.typ, x, z))
			end
		end
	end
	return ut
end

do
	local vantade = 0
	for _, pr in ipairs(G.props or {}) do
		if SKYLTTYPER[pr.typ] then vantade += 1 end
	end
	local saknade = saknadeSkyltar()
	check("varje kanonisk skylt i exporten finns som byggd del",
		vantade > 0 and #saknade == 0,
		#saknade == 0 and ("%d av %d"):format(vantade, vantade)
			or ("saknas: " .. table.concat(saknade, " · ")))

	--[[ Och texten ska följa med — en tom skylt är inte skylten. ]]
	local utanText = {}
	for _, d in ipairs(byggdaSkyltar()) do
		local t = d:GetAttribute("Text")
		if typeof(t) ~= "string" or t == "" then
			table.insert(utanText, d.Name)
		end
	end
	check("och varje byggd skylt bär sin text",
		#utanText == 0,
		#utanText == 0 and "alla har text" or table.concat(utanText, ", "))
	for _, d in ipairs(byggdaSkyltar()) do
		matning(("skylt: %s"):format(tostring(d:GetAttribute("Propstyp"))),
			("\"%s\""):format(tostring(d:GetAttribute("Text"))))
	end
end

--[[ ── OCH RESTEN AV REKVISITAN, SOM MÄTNING ───────────────────────────

	Skyltarna är det ordern gäller, men felet är bredare: `G.props` har 26
	poster och Roblox byggde EN typ av dem. Det här är en MÄTNING och inte
	en grind — rekvisitan är miljöarbete, och att göra den till en röd
	grind här vore att ta över någon annans leverans i smyg. Men den ska
	synas, för den är mätt och den är verklig. ]]
do
	local byggdaTyper = {}
	for _, d in ipairs(modell:GetDescendants()) do
		local t = d:GetAttribute("Propstyp")
		if typeof(t) == "string" then byggdaTyper[t] = true end
	end
	byggdaTyper.mast = true   -- masterna byggs av byggMaster, utan attribut
	local saknade, antal = {}, {}
	for _, pr in ipairs(G.props or {}) do
		if not byggdaTyper[pr.typ] then
			antal[pr.typ] = (antal[pr.typ] or 0) + 1
		end
	end
	for t, n2 in pairs(antal) do table.insert(saknade, ("%s×%d"):format(t, n2)) end
	table.sort(saknade)
	matning("rekvisita i exporten som Roblox ännu inte bygger",
		#saknade == 0 and "ingen" or table.concat(saknade, " · "))
end

--[[ ══ 8. MUTATIONERNA — VARJE REGEL SKA GÅ ATT FÄLLA ═══════════════════

	Ordern, punkt 8: gör medvetet trasigt och kräv RÖTT. Utan den här
	sektionen vet ingen om reglerna ovan MÄTER något — och den här grinden
	finns just för att tre gröna grindar en gång släppte igenom en
	spegelvänd värld.

	Mutationerna körs SIST och städas inte upp: de river delar ur den
	byggda världen, och allt som skulle mätas mot en hel värld är redan
	mätt. `alla` (lådorna) är däremot en ögonblicksbild, så varje mutation
	som ska synas där skriver om den.

	FEM AV SEX LIGGER HÄR. Den sjätte — "låt HUD-steg ligga kvar efter att
	spelaren lämnat target-range" — kräver klienten och ligger därför i
	`varldshud.spec`, där den körs som sin egen kontroll: med räckvidden
	satt till oändligt får spelaren ALDRIG bli "borta", och då ska
	rubriken stå kvar. Utan den mäter HUD-provet bara att rubriken byter,
	inte att den byter av rätt skäl. ]]
print("\n8. MUTATIONER — varje regel ska gå att fälla (M4 ligger i varldshud.spec)")

local function raknaOm()
	local ut = {}
	for _, d in ipairs(modell:GetDescendants()) do
		if d.CFrame and d.Size and d.CanCollide ~= false and d.Transparency ~= 1 then
			local c, s2 = d.CFrame.Position, d.Size
			local cx, cz = BuildKit.tomtkoord(bas, c)
			table.insert(ut, {
				namn = d.Name, del = d,
				x0 = cx - s2.X / (2 * M), x1 = cx + s2.X / (2 * M),
				z0 = cz - s2.Z / (2 * M), z1 = cz + s2.Z / (2 * M),
				y0 = (c.Y - s2.Y / 2) / M, y1 = (c.Y + s2.Y / 2) / M,
			})
		end
	end
	alla = ut
end

--[[ M1: ta bort hästmodellen, lämna rosterdatan intakt. ]]
do
	local forst = iVarldenNu()[roster[1]]
	if forst then forst:Destroy() end
	check("M1: en riven hästmodell fäller närvaroregeln",
		#saknadeHastar() > 0,
		("%d saknas efter att %s revs"):format(#saknadeHastar(), tostring(roster[1])))
end

--[[ M3: ta bort utrustningsplatsen, lämna skötselsteget kvar. ]]
do
	for _, d in ipairs(utrustningsdelar()) do d:Destroy() end
	check("M3: en riven utrustningsplats fäller utrustningsregeln",
		#utrustningsdelar() == 0,
		("%d delar kvar"):format(#utrustningsdelar()))
end

--[[ M5: ta bort ett interiört golv så att marken syns igenom. ]]
do
	local stallrekt = nil
	for _, b in ipairs(G.byggnader) do if b.id == "stall" then stallrekt = b.rekt end end
	for _, d in ipairs(modell:GetDescendants()) do
		if d.Name == "stall grund" then d:Destroy() end
	end
	raknaOm()
	local gras, provade = markOverst({ id = "stall", r = stallrekt })
	check("M5: utan stallets golv ligger marken överst inomhus",
		#gras > 0, ("%d av %d punkter"):format(#gras, provade))
end

--[[ M2: lämna prompten, spärra passagen med kollision. ]]
do
	local prov = scanBlad()[1]
	if prov then
		local c = prov.CFrame.Position
		local hinder = Instance.new("Part")
		hinder.Name = "MUTATION spärr"
		hinder.Anchored = true
		hinder.Size = Vector3.new(6 * M, 3 * M, 3 * M)
		hinder.CFrame = CFrame.new(c)
		hinder.Parent = modell
		raknaOm()
		local ok = provaPassage(prov)
		check("M2: en spärrad passage fäller traversalregeln trots att prompten finns",
			ok == false, ("%s spärrad"):format(idFor(prov)))
		hinder:Destroy()
		raknaOm()
	end
end

--[[ M7: riv den kanoniska skylten. ]]
do
	for _, d in ipairs(byggdaSkyltar()) do d:Destroy() end
	check("M7: en riven kanonisk skylt fäller skyltpariteten",
		#saknadeSkyltar() > 0,
		("%d skyltar saknas efter rivningen"):format(#saknadeSkyltar()))
end

--[[ M6: lägg in en falsk grind — ett dörrblad utan öppning i kanon. ]]
do
	local falsk = Instance.new("Part")
	falsk.Name = "MUTATION falsk grind"
	falsk.Anchored = true
	falsk.Size = Vector3.new(1, 1, 1)
	falsk.CFrame = CFrame.new(0, 0, 0)
	falsk:SetAttribute("UBRFDorr", true)
	falsk:SetAttribute("Oppningstyp", "portpahittad")
	falsk.Parent = modell
	local b2, d2 = scanBlad(), scanDeklarerade()
	check("M6: en falsk grind fäller öppningskontraktet",
		#b2 + #d2 ~= genomgaende,
		("%d + %d mot %d genomgående i datan"):format(#b2, #d2, genomgaende))
	falsk:Destroy()
end

if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	print("PHYSICAL_WORLD_COHERENCE_GATE: FAIL")
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error("varldskoherens.spec: " .. fails .. " fel")
end
print("\nPHYSICAL_WORLD_COHERENCE_GATE: alla gröna")
