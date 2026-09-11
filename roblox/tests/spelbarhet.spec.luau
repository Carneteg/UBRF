--!nostrict
--[[
	END_TO_END_PLAYABILITY_GATE — mäter SPELBARHET, inte avsikt.

	ChatGPT:s processreview #162 16:31, efter att Tobias manuellt hittat tre
	grundläggande Studio-fel i buildar som presenterats som redo. Mönstret
	var att grindarna mätte att något LÅG RÄTT, aldrig att det gick att
	SPELA: spawnen mättes mot ankomstpunkten men inte mot marken; placen
	mättes som välformad XML men inte som en place Studio läser; koden
	mättes som närvarande men inte som `require`-bar.

	Den här grinden mäter i stället en gångbar kedja genom den FAKTISKT
	BYGGDA geometrin, med avatarens verkliga mått:

	    spawn → entrédörren → in genom öppningen → Blackrock Jacks box

	Metoden är konfigurationsrymd, inte punktprov. Varje kolliderande del
	blåses upp med avatarens radie i x/z, och sökningen sker sedan för en
	PUNKT i den uppblåsta rymden. Det är matematiskt samma sak som att
	flytta en kropp med bredd genom den ursprungliga världen — och det är
	därför en dörr som är för smal för avataren faller här, medan ett
	koordinatavstånd hade sagt att den går bra.

	Golvet läses ur de ICKE uppblåsta delarna: man står på golvet man står
	på, inte på en uppblåst variant av det.

	Kör: python3 roblox/tests/build.py tests/spelbarhet.spec.luau
	     && luau roblox/tests/.build/spelbarhet.spec.luau
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

--[[ ══ AVATARENS MÅTT ═══════════════════════════════════════════════════

	Roblox standardavatar: ~2 studs bred, ~5 studs hög. I meter med M = 3
	studs/m blir det 0,67 m bred och 1,7 m hög. Radien är alltså 0,34 m;
	jag använder 0,35 för marginal. StegHöjd är vad en Humanoid klarar att
	kliva upp på utan hopp. ]]
local RADIE   = 0.35
local HOJD    = 1.75
local STEG    = 0.55
local MAXGOLV = 3.0     -- högre än så är ett tak, inte ett golv
local CELL    = 0.25

-- ── Regionen som mäts: stallet med marginal, där hela kedjan ligger ──
local stall
for _, b in ipairs(UBRFKomplex.byggnader) do
	if b.id == "stall" then stall = b end
end
local MARGINAL = 14.0
local X0 = stall.rekt.x - MARGINAL
local X1 = stall.rekt.x + stall.rekt.w + MARGINAL
local Z0 = stall.rekt.y - MARGINAL
local Z1 = stall.rekt.y + stall.rekt.h + MARGINAL
local NX = math.ceil((X1 - X0) / CELL)
local NZ = math.ceil((Z1 - Z0) / CELL)

local origo = UBRFKomplex.origo or { x = 0, y = 0 }
local function cellFor(x, z)
	return math.floor((x - X0) / CELL) + 1, math.floor((z - Z0) / CELL) + 1
end
local function mitt(ix, iz)
	return X0 + (ix - 0.5) * CELL, Z0 + (iz - 0.5) * CELL
end
local function idx(ix, iz) return (iz - 1) * NX + ix end

--[[ Delarnas lådor i METER, i TOMTENS koordinater — samma ram som
	UBRFKomplex, `references/SITEPLAN.md` och boxarnas lägen.

	Världen byggs i kartans ram och vänds en gång till en högerhänt
	Y-upp-värld där norr är −Z (`BuildKit.tomtlage`). `BuildKit.tomtkoord`
	är vägen tillbaka. Räknade provet om på egen hand skulle hela rutnätet
	ligga spegelvänt mot boxarna, och en nåbarhetsmätning i en spegelvänd
	karta säger ingenting om spelet. ]]
local bas = (modell :: any).PrimaryPart.CFrame
local lador = {}
for _, d in ipairs(modell:GetDescendants()) do
	if d:IsA("BasePart") and d.CanCollide ~= false and d.Transparency ~= 1 then
		local c, s = d.CFrame.Position, d.Size
		local cx, cz = BuildKit.tomtkoord(bas, c)
		table.insert(lador, {
			namn = d.Name,
			x0 = cx - s.X / (2 * M), x1 = cx + s.X / (2 * M),
			z0 = cz - s.Z / (2 * M), z1 = cz + s.Z / (2 * M),
			y0 = (c.Y - s.Y / 2) / M, y1 = (c.Y + s.Y / 2) / M,
			del = d,
		})
	end
end
print(("\nRegion %.0f×%.0f m, %d×%d celler, %d kolliderande delar")
	:format(X1 - X0, Z1 - Z0, NX, NZ, #lador))

--[[ ══ KARTORNA ══════════════════════════════════════════════════════════

	Två rutnät per världstillstånd:

	  golv[i]      — höjden på den yta man står på i cellen
	  blockerad[i] — står något i kroppsvolymen över den ytan

	MÄTPUNKTEN ÄR CELLENS MITT, och det är inte en detalj. Första versionen
	rasterade varje cell som en låda NUDDAR, alltså konservativt. Då blev
	dörröppningens fria korridor — 1,15 m minus avatarens 0,70 m = 0,45 m —
	noll celler bred, eftersom de uppblåsta väggsegmenten nuddade båda
	cellerna i öppningen. Grinden blev röd på en dörr som mätt är fri.
	Konservativ rastrering är fel semantik för en punktsökning i
	konfigurationsrymd: punkten ligger i cellens mitt, så det är mitten som
	ska prövas.

	Golvet läses ur de ICKE uppblåsta lådorna — man står på det golv man
	står på. Hindren läses ur de UPPBLÅSTA, vilket är det som gör
	punktsökningen ekvivalent med att flytta en kropp med bredd. ]]
local function byggKartor(lista)
	local golv, blockerad = {}, {}

	for _, l in ipairs(lista) do
		if l.y1 <= MAXGOLV then
			local ax0, az0 = cellFor(l.x0, l.z0)
			local ax1, az1 = cellFor(l.x1, l.z1)
			for iz = math.max(1, az0), math.min(NZ, az1) do
				for ix = math.max(1, ax0), math.min(NX, ax1) do
					local mx, mz = mitt(ix, iz)
					if mx >= l.x0 and mx <= l.x1 and mz >= l.z0 and mz <= l.z1 then
						local i = idx(ix, iz)
						if golv[i] == nil or l.y1 > golv[i] then golv[i] = l.y1 end
					end
				end
			end
		end
	end

	for _, l in ipairs(lista) do
		local ax0, az0 = cellFor(l.x0 - RADIE, l.z0 - RADIE)
		local ax1, az1 = cellFor(l.x1 + RADIE, l.z1 + RADIE)
		for iz = math.max(1, az0), math.min(NZ, az1) do
			for ix = math.max(1, ax0), math.min(NX, ax1) do
				local i = idx(ix, iz)
				local g = golv[i]
				if g ~= nil and not blockerad[i] then
					local mx, mz = mitt(ix, iz)
					if mx >= l.x0 - RADIE and mx <= l.x1 + RADIE
						and mz >= l.z0 - RADIE and mz <= l.z1 + RADIE then
						--[[ Ett hinder är något man varken kan gå igenom
							ELLER kliva upp på. Tröskeln är därför STEG, inte
							noll: verandans 14 cm-steg är ett steg, och
							golvet där blir stegets ovansida. ]]
						if l.y1 > g + STEG and l.y0 < g + HOJD then
							blockerad[i] = true
						end
					end
				end
			end
		end
	end

	return { golv = golv, blockerad = blockerad }
end

local function gangbarI(k, ix, iz)
	if ix < 1 or iz < 1 or ix > NX or iz > NZ then return false end
	local i = idx(ix, iz)
	return k.golv[i] ~= nil and not k.blockerad[i]
end

--[[ BFS med stegvillkor: två celler hänger ihop bara om nivåskillnaden är
	något en Humanoid kliver upp på. Utan det villkoret hade en vägg med tak
	räknats som en ramp. ]]
local function sokI(k, fran, till)
	local sx, sz = cellFor(fran.x, fran.y)
	local tx, tz = cellFor(till.x, till.y)
	if not gangbarI(k, sx, sz) then return nil, "startcellen är inte gångbar" end
	if not gangbarI(k, tx, tz) then return nil, "målcellen är inte gångbar" end

	local ko, huvud = { { sx, sz } }, 1
	local sedd = { [idx(sx, sz)] = true }
	local steg = { [idx(sx, sz)] = 0 }
	while huvud <= #ko do
		local c = ko[huvud]; huvud += 1
		if c[1] == tx and c[2] == tz then return steg[idx(c[1], c[2])] end
		for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
			local nx, nz = c[1] + d[1], c[2] + d[2]
			local ni = idx(nx, nz)
			if gangbarI(k, nx, nz) and not sedd[ni]
				and math.abs(k.golv[ni] - k.golv[idx(c[1], c[2])]) <= STEG then
				sedd[ni] = true
				steg[ni] = steg[idx(c[1], c[2])] + 1
				table.insert(ko, { nx, nz })
			end
		end
	end
	return nil, "ingen sammanhängande gångväg"
end

--[[ Alla celler man kan NÅ från en punkt. Skillnaden mot `sokI` är viktig:
	en cell kan vara gångbar utan att vara nåbar. Boxarnas insida är precis
	det — golvet finns, men boxfronten står emellan. ]]
local function naddaFran(k, fran)
	local sx, sz = cellFor(fran.x, fran.y)
	if not gangbarI(k, sx, sz) then return nil end
	local nadd = { [idx(sx, sz)] = true }
	local ko, huvud = { { sx, sz } }, 1
	while huvud <= #ko do
		local c = ko[huvud]; huvud += 1
		for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
			local nx, nz = c[1] + d[1], c[2] + d[2]
			local ni = idx(nx, nz)
			if gangbarI(k, nx, nz) and not nadd[ni]
				and math.abs(k.golv[ni] - k.golv[idx(c[1], c[2])]) <= STEG then
				nadd[ni] = true
				table.insert(ko, { nx, nz })
			end
		end
	end
	return nadd
end

--[[ Kartan runt en punkt, för felsökning. En grind som bara säger "ingen
	väg" tvingar nästa person att bygga om felsökningen från noll. ]]
local function skrivKarta(k, kring, hojd)
	local cx, cz = cellFor(kring.x, kring.y)
	local h = math.ceil((hojd or 2.0) / CELL)
	print("      karta (. gångbar, # blockerad, ' ' inget golv):")
	for iz = cz + h, cz - h, -1 do
		local rad = ""
		for ix = cx - 8, cx + 8 do
			local i = idx(ix, iz)
			rad = rad .. (k.golv[i] == nil and " " or (k.blockerad[i] and "#" or "."))
		end
		local _, mz = mitt(cx, iz)
		print(("      z %.2f |%s|  golv %s"):format(mz, rad,
			k.golv[idx(cx, iz)] and ("%.2f"):format(k.golv[idx(cx, iz)]) or "-"))
	end
end

local STANGT = byggKartor(lador)

-- ══ 1. SPAWN SURVIVAL ═══════════════════════════════════════════════════
print("\n1. Spawn survival")

local spawn
for _, d in ipairs(modell:GetDescendants()) do
	if d.ClassName == "SpawnLocation" then spawn = d end
end
check("spawnen finns i den byggda världen", spawn ~= nil)

local spos
if spawn then
	local p = spawn.CFrame.Position
	local sx0, sy0 = BuildKit.tomtkoord(bas, p)
	spos = { x = sx0, y = sy0, h = p.Y / M }
	local sx, sz = cellFor(spos.x, spos.y)
	local i = idx(sx, sz)
	local G, B = STANGT.golv, STANGT.blockerad
	check("spawncellen har golv (kolliderande yta under)", G[i] ~= nil,
		G[i] and ("golv %.2f m"):format(G[i]) or "INGET GOLV — spelaren faller")
	check("fallet från spawn till golv är ofarligt",
		G[i] ~= nil and (spos.h - G[i]) <= 0.6,
		G[i] and ("%.2f m"):format(spos.h - G[i]) or "ingen mark")
	check("spawnen har takfrihet för avataren", not B[i],
		B[i] and "något står i vägen i kroppshöjd"
			or ("%.2f m fritt över golvet"):format(HOJD))
	check("spawncellen är gångbar", gangbarI(STANGT, sx, sz))
end

-- ══ 2. GÅNGBARHET SPAWN → ENTRÉDÖRREN ═══════════════════════════════════
print("\n2. Gångbarhet spawn → entrédörren")

local dorr
for _, o in ipairs(stall.oppningar or {}) do
	if o.sida == "N" and o.typ == "dorrgul" then dorr = o end
end
check("stallets ockragula nordentré finns", dorr ~= nil)

local utanfor, innanfor, dmx, dmz
if dorr then
	dmx, dmz = Geometri.oppningsMitt(stall.rekt, "N", dorr.u, dorr.b)
	--[[ En punkt strax utanför och en strax innanför öppningen. 0,9 m är
		mer än väggens 0,3 m tjocklek, så punkterna hamnar på var sin sida
		om muren och inte inne i den. ]]
	utanfor = { x = dmx, y = dmz + 0.9 }
	innanfor = { x = dmx, y = dmz - 0.9 }
end

if spos and utanfor then
	local n, varfor = sokI(STANGT, spos, utanfor)
	check("det går att gå från spawn fram till dörren", n ~= nil,
		n and ("%d celler (%.1f m)"):format(n, n * CELL) or varfor)
end

-- ══ 3. DÖRRENS ANVÄNDBARHET ═════════════════════════════════════════════
print("\n3. Dörrens användbarhet")

DorrService.start()

local blad
if dorr then
	for _, d in ipairs(modell:GetDescendants()) do
		if d:GetAttribute("UBRFDorr") == true and d:GetAttribute("Byggnad") == "stall"
			and d:GetAttribute("Sida") == "N" then blad = d end
	end
end
check("entrédörren har ett uppmärkt dörrblad", blad ~= nil)

local prompt = blad and blad:FindFirstChildOfClass("ProximityPrompt")
check("dörrbladet har en ProximityPrompt", prompt ~= nil)

if prompt and utanfor and blad then
	local bp = blad.CFrame.Position
	local bx, bz = BuildKit.tomtkoord(bas, bp)
	local avst = math.sqrt((bx - utanfor.x) ^ 2 + (bz - utanfor.y) ^ 2)
	--[[ Prompten mäts i studs i Roblox; jämförelsen görs i meter. ]]
	check("prompten går att nå från gångytan utanför",
		avst * M <= prompt.MaxActivationDistance,
		("%.1f studs mot räckvidd %.0f"):format(avst * M, prompt.MaxActivationDistance))
end

--[[ Öppnad dörr ska ge fri passage. Mätningen görs som en ny gångsökning
	genom öppningen EFTER att bladet öppnats — det är skillnaden mellan en
	dörr som ser öppen ut och en man kommer igenom. ]]
if blad and prompt and utanfor and innanfor then
	prompt.Triggered:_fire()

	local oppnaLador = {}
	for _, l in ipairs(lador) do
		--[[ Bladet tas ur kartan BARA om det verkligen slutat kollidera.
			Att utesluta det villkorslöst var en lucka i min egen grind:
			mutationen "dörren öppnas men behåller kollisionen" gjorde bara
			CanCollide-raden röd, medan passagen förblev grön — alltså exakt
			det fel grinden finns för att fånga. Nu står bladet kvar i
			kartan när det kolliderar, och då är öppningen stängd. ]]
		if l.del ~= blad or blad.CanCollide then table.insert(oppnaLador, l) end
	end
	check("dörrbladet slutar kollidera när det öppnas", blad.CanCollide == false)

	--[[ Kartorna byggs om utan det öppnade bladet, med samma funktion som
		det stängda läget. Billigare vore att bara frita bladets celler, men
		då hade jag mätt min egen approximation och inte världen. ]]
	local OPPET = byggKartor(oppnaLador)

	local n, varfor = sokI(OPPET, utanfor, innanfor)
	if n == nil then skrivKarta(OPPET, utanfor, 2.0) end
	check("avataren kommer IGENOM öppningen när dörren är öppen", n ~= nil,
		n and ("%d celler"):format(n) or varfor)

	local n2, varfor2 = sokI(OPPET, spos, innanfor)
	check("hela kedjan spawn → in i stallet är gångbar", n2 ~= nil,
		n2 and ("%d celler (%.1f m)"):format(n2, n2 * CELL) or varfor2)

	-- ══ 4. GÅNGBARHET ENTRÉ → BLACKROCK JACKS BOX ═══════════════════════
	print("\n4. Gångbarhet entré → Blackrock Jacks box")

	local hastId = Stallet.FORSTA_DAGEN_HAST
	local box = Stallet.boxFor(hastId)
	check("första dagens häst har en box med världskoordinater",
		box ~= nil and box.varld ~= nil, hastId)

	--[[ RÄTT KONTRAKT ÄR RÄCKVIDD, INTE ATT GÅ IN I BOXEN.

		Första versionen krävde en gångväg till boxens mitt och blev röd.
		Kartan visade varför: stallgångarna är nåbara ända fram, men
		boxarnas INSIDA är inte — boxfronten står emellan. Så ska det vara.
		Man går inte in genom en boxfront, man står i gången.

		`StallService` sätter boxens `ProximityPrompt` med
		`MaxActivationDistance = 8` studs och `RequiresLineOfSight = false`.
		Kontraktet är alltså: finns en NÅDD gångyta inom räckvidden från
		boxens mitt. Att kräva mer hade varit att kräva något spelet inte
		behöver — och att kräva mindre hade släppt igenom en box man inte
		kan interagera med. ]]
	local RACKVIDD_BOX = 8 / M   -- studs → meter, samma tal som StallService

	local nadd = naddaFran(OPPET, innanfor)
	check("gångytan innanför entrén är nåbar", nadd ~= nil)

	if box and box.varld and nadd then
		local bx, bz = cellFor(box.varld.x, box.varld.y)
		local bast, bcell = nil, nil
		local R = math.ceil(6.0 / CELL)
		for dz = -R, R do
			for dx = -R, R do
				local ix, iz = bx + dx, bz + dz
				if nadd[idx(ix, iz)] then
					local mx, mz = mitt(ix, iz)
					local d2 = (mx - box.varld.x) ^ 2 + (mz - box.varld.y) ^ 2
					if bast == nil or d2 < bast then bast, bcell = d2, { ix, iz } end
				end
			end
		end
		local avst = bast and math.sqrt(bast) or nil
		check("det finns NÅDD gångyta vid Jacks box", bcell ~= nil,
			avst and ("närmast %.2f m från boxens mitt"):format(avst) or "ingen nådd yta inom 6 m")
		check("boxens prompt går att nå från gångytan",
			avst ~= nil and avst <= RACKVIDD_BOX,
			avst and ("%.2f m mot räckvidd %.2f m (8 studs)"):format(avst, RACKVIDD_BOX)
				or "ingen nådd yta")

		if bcell then
			local mx, mz = mitt(bcell[1], bcell[2])
			local n4, varfor4 = sokI(OPPET, spos, { x = mx, y = mz })
			check("HELA KEDJAN spawn → dörr → gången vid Jacks box är gångbar", n4 ~= nil,
				n4 and ("%d celler (%.1f m)"):format(n4, n4 * CELL) or varfor4)
		end
	end

	--[[ Stäng dörren igen så att specen inte lämnar världen i ett annat
		läge än den fann den. ]]
	prompt.Triggered:_fire()
end

-- ══ 5. JACK FINNS SOM RIGG ══════════════════════════════════════════════
--[[ P0 i ChatGPT:s whole-place review 16:40: det fanns INGEN hästmodell i
	placen. Min förra spelbarhetsgrind var grön ändå, för den mätte att man
	kan GÅ dit hästen borde stå. Ingen mätning frågade om hästen finns.

	Här mäts riggens KONTRAKT, inte dess utseende: att den byggs, taggas,
	bär rätt `HorseId`, och att `RigAdapter.build()` accepterar den. Måtten
	prövas inte mot bänkens CFrame-stubb — den räknar inte riktigt — utan
	strukturen, som är det koden är strikt om. ]]
print("\n5. Jack finns som rigg")

local CollectionService = game:GetService("CollectionService")
local hastId = Stallet.FORSTA_DAGEN_HAST
local rigg = HastRigg.bygg(hastId, "Blackrock Jack", CFrame.new())
rigg.Parent = workspace
CollectionService:AddTag(rigg, "Horse")

check("riggen byggs som en Model", rigg ~= nil and rigg.ClassName == "Model")
check("riggen bär rätt HorseId", rigg:GetAttribute("HorseId") == hastId,
	tostring(rigg:GetAttribute("HorseId")))
check("riggen är taggad Horse", CollectionService:HasTag(rigg, "Horse"))
check("HorseService hittar den via taggen",
	(function()
		for _, m in ipairs(CollectionService:GetTagged("Horse")) do
			if m == rigg then return true end
		end
		return false
	end)())

--[[ Det avgörande: att adaptern accepterar modellen. Utan detta stannar
	`GameplayService.bind()` i `waiting_model` och inget moment kan börja. ]]
local byggd, felmeddelande = RigAdapter.build(rigg)
check("RigAdapter.build() lyckas mot riggen", byggd ~= nil,
	felmeddelande or "ingen fel")

if byggd then
	--[[ LOCOMOTION-P0 (#162, lokal Studio-QA på 9b5a570).

		Roten MÅSTE heta exakt `HumanoidRootPart`. Roblox binder
		`Humanoid.RootPart` till den syskondelen och ingen annan; hette den
		`BodyCollider` blev RootPart nil, `FloorMaterial` blev `Air` och
		hästen rörde sig 0,00 studs trots `WalkSpeed=4.93`.

		Den här mätningen blir röd i exakt det fallet — den är skriven för
		att fånga just namnet, inte bara "någon rot finns". ]]
	check("rotdelen heter HumanoidRootPart (Roblox binder bara det namnet)",
		byggd.root ~= nil and byggd.root.Name == "HumanoidRootPart",
		byggd.root and byggd.root.Name or "ingen")
	--[[ Roblox letar rotdelen bland modellens DIREKTA barn, inte i hela
		trädet. Ligger den i en undermapp binder motorn den aldrig. ]]
	check("rotdelen är ett direkt barn till modellen (syskon till Humanoid)",
		rigg:FindFirstChild("HumanoidRootPart") == byggd.root,
		tostring(rigg:FindFirstChild("HumanoidRootPart")))
	check("rotdelen är modellens PrimaryPart",
		(rigg :: any).PrimaryPart ~= nil and (rigg :: any).PrimaryPart == byggd.root)
	check("HipHeight är satt — annars sjunker kroppen i marken",
		byggd.humanoid ~= nil and (byggd.humanoid :: any).HipHeight ~= nil
			and (byggd.humanoid :: any).HipHeight > 0,
		byggd.humanoid and tostring((byggd.humanoid :: any).HipHeight) or "ingen humanoid")
	check("roten kolliderar — hästen finns fysiskt",
		byggd.root ~= nil and byggd.root.CanCollide == true)
	check("riggen har Humanoid (markkontakt)", byggd.humanoid ~= nil)
	check("riggen har en Animator", byggd.animator ~= nil)
	--[[ #162 blockerare 2: sätet ska vara en SITS och lutningen ligga på en
		egen led. Att båda finns och är olika instanser är kontraktet. ]]
	check("RiderSeat är en Seat", byggd.seat ~= nil and byggd.seat.ClassName == "Seat",
		byggd.seat and byggd.seat.ClassName or "ingen sits")
	check("RiderJoint finns som egen Motor6D",
		byggd.riderJoint ~= nil and byggd.riderJoint.ClassName == "Motor6D",
		byggd.riderJoint and byggd.riderJoint.ClassName or "ingen led")
	check("sitsen och ryttarleden är INTE samma instans",
		byggd.seat ~= nil and byggd.riderJoint ~= nil and byggd.seat ~= byggd.riderJoint)
	check("RootJoint bär kroppslutningen", byggd.rootJoint ~= nil)
	check("sadelns attachmentpunkt finns", byggd.attachments.Saddle ~= nil)

	--[[ Och att ryttarlutningen faktiskt går att sätta mot den riktiga
		riggen, utan att kasta. Det är den rad som hade kraschat på första
		ridbildrutan. ]]
	local okLutning = pcall(function()
		RigAdapter.setRiderLean(byggd, 0.1, 0.05)
		RigAdapter.setRiderLean(byggd, 0, 0)
	end)
	check("setRiderLean kastar inte mot en riktig Seat-rigg", okLutning)
end

--[[ ══ UTRUSTNINGEN HÄNGER PÅ TÄT PANEL, INTE I BOXDÖRREN ══════════════

	`Stallet.utrustningsplats` räknar ut var sadeln och tränset hänger ur
	`S.boxB` och `boxfront.dorr.bredd`. `Anlaggningen` delar fronten kring
	dörrgapet ur exakt samma två fält — men det är ändå en härledning på två
	ställen, och en sådan går isär tyst.

	Därför MÄTS den här mot det som faktiskt byggts: varje sak ska ligga inom
	sin boxfronts panel och utanför sin boxdörr. Flyttar bygget dörren, eller
	byter den ände den sitter i, blir den här röd i stället för att en sadel
	hamnar i öppningen hästen ska gå ut genom.

	Att en sadel i dörrgapet är ett riktigt fel och inte en skönhetsfråga:
	dörren är den enda vägen ut ur boxen, mätt i Studio. ]]
print("\n── Utrustningen mot boxfrontens faktiska delar ──")
do
	--[[ Delarna slås upp på NAMN, som bygget sätter dem: "Boxfront MB 5".
		Läget räknas om till tomtkoordinater med samma funktion resten av
		specen använder. ]]
	local delFor = {}
	for _, d in ipairs(modell:GetDescendants()) do
		if d:IsA("BasePart") then
			--[[ NAMNEN MATCHAS LITTERALT, inte med `Box%a+`.

				Första versionen gjorde det senare, och `%a` matchar inte
				`ö` — "Boxdörr MB 5" föll alltså utanför uppslaget helt.
				Panelmätningen nedan såg därför ALDRIG en dörr, och dess
				"utanför boxdörren"-halva var tom. Fångat när dörr-
				waypointen mättes mot samma tabell och fick 33 × "ingen
				byggd boxdörr" i ett bygge som har 49. ]]
			local sort, box = string.match(d.Name, "^(Boxfront) (.+)$")
			if not sort then
				sort, box = string.match(d.Name, "^(Boxdörr) (.+)$")
			end
			if sort then
				local _, cz = BuildKit.tomtkoord(bas, d.Position)
				--[[ Delen löper i Z; halva dess Z-mått åt vardera sidan om
					mitten ger dess utbredning längs gången. ]]
				local halv = d.Size.Z / 2 / BuildKit.M
				delFor[sort .. "|" .. box] = { y0 = cz - halv, y1 = cz + halv }
			end
		end
	end

	local antal, fel = 0, {}
	for _, hastId in ipairs(UBRFSpel.ordning or {}) do
		local box = Stallet.boxFor(hastId)
		if box then
			local nyckel = box.rad .. " " .. box.plats
			local panel = delFor["Boxfront|" .. nyckel]
			local dorr = delFor["Boxdörr|" .. nyckel]
			for _, sort in ipairs({ "sadel", "trans" }) do
				local plats = Stallet.utrustningsplats(hastId, sort)
				antal += 1
				if not plats then
					table.insert(fel, hastId .. "/" .. sort .. ": ingen plats")
				elseif not panel then
					table.insert(fel, ("%s: ingen Boxfront %s byggd"):format(hastId, nyckel))
				else
					local y = plats.varld.y
					if y < panel.y0 - 0.01 or y > panel.y1 + 0.01 then
						table.insert(fel, ("%s/%s: %.2f utanför panelen %.2f–%.2f")
							:format(hastId, sort, y, panel.y0, panel.y1))
					end
					if dorr and y > dorr.y0 + 0.01 and y < dorr.y1 - 0.01 then
						table.insert(fel, ("%s/%s: %.2f INNE i boxdörren %.2f–%.2f")
							:format(hastId, sort, y, dorr.y0, dorr.y1))
					end
				end
			end
		end
	end
	check("varje sadel och träns hänger på tät panel, utanför boxdörren",
		antal > 0 and #fel == 0,
		("%d lägen%s"):format(antal, #fel > 0 and (" — " .. table.concat(fel, "; ")) or ""))

	--[[ DÖRR-WAYPOINTEN pekar på den FAKTISKA öppningen.

		`Stallet.boxdorr` finns för ledningen: hästen kilar sig mot fronten
		om hon styrs rakt mot ett mål utanför boxen, så hon behöver rikta upp
		sig i öppningen först (runtime-mätning 17:14). Punkterna är bara
		värda något om de ligger i öppningen, och det mäts här mot delen
		bygget faktiskt lade. ]]
	local dFel, dAntal = {}, 0
	for _, hastId in ipairs(UBRFSpel.ordning or {}) do
		local box = Stallet.boxFor(hastId)
		local d = Stallet.boxdorr(hastId)
		if box and d then
			dAntal += 1
			local byggd = delFor["Boxdörr|" .. box.rad .. " " .. box.plats]
			if not byggd then
				table.insert(dFel, hastId .. ": ingen byggd boxdörr")
			else
				local mitt = (d.span.y0 + d.span.y1) / 2
				local bMitt = (byggd.y0 + byggd.y1) / 2
				if math.abs(mitt - bMitt) > 0.05 then
					table.insert(dFel, ("%s: mitt %.2f mot byggd %.2f")
						:format(hastId, mitt, bMitt))
				end
				--[[ ...och de två waypointpunkterna ska ligga på var sin
					sida om fronten, i öppningens y-läge. ]]
				local inneUt = (d.inne.x - box.frontVarld.x) * box.vetter
				local uteUt = (d.ute.x - box.frontVarld.x) * box.vetter
				if inneUt >= 0 or uteUt <= 0 then
					table.insert(dFel, ("%s: punkterna ligger på samma sida")
						:format(hastId))
				end
				if math.abs(d.inne.y - mitt) > 0.01 or math.abs(d.ute.y - mitt) > 0.01 then
					table.insert(dFel, ("%s: punkterna är inte i öppningen"):format(hastId))
				end
			end
		end
	end
	check("dörr-waypointen ligger i den byggda öppningen, en punkt per sida",
		dAntal > 0 and #dFel == 0,
		("%d dörrar%s"):format(dAntal, #dFel > 0 and (" — " .. table.concat(dFel, "; ")) or ""))
end

--[[ ══ 52 MOT 49 BOXAR — DIAGNOSTISERAT, INTE ETT FEL ═════════════════

	Runtime-QA:n rapporterade diskrepansen som odiagnostiserad: datan säger
	52 boxar, världen bygger 49. Den mäts här i stället för att förklaras i
	en kommentar någon kan glömma uppdatera.

	`Stallet.boxantal()` är NUMRERINGSRYMDEN — fyra rader gånger tretton
	platser. `S.brott` skär två passager genom raderna, och de facken finns
	inte, så `box(n)` ger nil för dem. Skillnaden ska vara exakt så stor som
	brotten gör den. ]]
print("\n── Boxräkningen: numreringsrymd mot byggda fack ──")
do
	local S = UBRFKomplex.stall
	local rutnat = Stallet.boxantal()
	local verkliga, perRad = 0, {}
	for _, rad in ipairs(S.rader) do
		local n = #((S.fack or {})[rad.id] or {})
		verkliga += n
		table.insert(perRad, ("%s=%d"):format(rad.id, n))
	end

	local utanBox = {}
	for n = 1, rutnat do
		if not Stallet.box(n) then table.insert(utanBox, n) end
	end

	check("numreringsrymden är rader × platser",
		rutnat == #S.rader * S.antalBoxar, tostring(rutnat))
	check("de verkliga facken är färre, och det är brotten som gör det",
		verkliga < rutnat and rutnat - verkliga == #utanBox,
		("rutnät %d, fack %d (%s), nil %d"):format(rutnat, verkliga,
			table.concat(perRad, " "), #utanBox))
	--[[ Och varje nil-nummer ska ligga i ett fack som ett brott faktiskt
		skär. En box som försvunnit av något ANNAT skäl ska inte gå igenom
		den här mätningen. ]]
	local oforklarade = {}
	for _, n in ipairs(utanBox) do
		local radIndex = math.floor((n - 1) / S.antalBoxar) + 1
		local rad = S.rader[radIndex]
		local trafffad = false
		for _, b in ipairs(S.brott or {}) do
			if rad and b.rad == rad.id then trafffad = true end
		end
		if not trafffad then table.insert(oforklarade, n) end
	end
	check("varje saknad box ligger i en rad som ett brott skär",
		#oforklarade == 0,
		#oforklarade > 0 and table.concat(oforklarade, ", ") or "inga oförklarade")
end

if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	os.exit(1)
else
	print("\nEND_TO_END_PLAYABILITY_GATE: alla gröna")
end
