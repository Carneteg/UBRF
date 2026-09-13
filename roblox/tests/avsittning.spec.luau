--!nostrict
--[[
	AVSITTNINGENS PLATS — ryttaren ska hamna BREDVID hästen, inte på henne.

	══ VAD SOM MÄTTES I STUDIO ════════════════════════════════════════

	Avsittningen skrev en flytt 4,5 studs åt vänster. Uppmätt efteråt,
	både mitt på öppen ridbana och intill sargen:

	    hästen (399.94 3.36 280.00) · ryttaren (400.00 7.59 280.00)
	    sidsteg 0.06 studs · höjd över hästroten +4.24 · Floor Plastic

	`FloorMaterial` var hästen själv: hon stod på hästryggen.

	══ VAD DEN HÄR SPECEN KAN OCH INTE KAN ════════════════════════════

	Den mäter PLATSEN: att den räknas ur hästens egen geometri, att den
	ligger utanför hennes kropp, att fötterna hamnar på det underlag som
	faktiskt bär, att vänster går före höger, att höger tas när vänster är
	upptagen, och att ingen av dem tas när marken saknas eller ligger för
	långt ned.

	Den kan INTE mäta tidsfrågan — att Roblox skriver tillbaka ryttarens
	läge så länge `seat.Occupant` pekar på henne, och att den andra
	placeringen därför är den som håller. Bänken har ingen sits som
	släpper en bildruta senare. Det är ett Studio-prov, och det står som
	NOT TESTED i leveransen.

	Kör: python3 roblox/tests/build.py tests/avsittning.spec.luau
	     && luau roblox/tests/.build/avsittning.spec.luau
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
local function nara(a, b, tol)
	return type(a) == "number" and type(b) == "number" and math.abs(a - b) <= (tol or 1e-6)
end

local RunService = game:GetService("RunService")
RunService._server = true

--[[ ── EN VÄRLD MED GOLV OCH HINDER ─────────────────────────────────

	`markFn(x, z)` svarar var det BÄRANDE golvet ligger, `hinderFn(p)` om
	en låda med mitten i `p` krockar med något. Båda är provets egna, så
	varje mätning nedan säger exakt vilken värld den gäller i. ]]
local function varld(markFn, hinderFn)
	__markyta = function(origin, _dir, params)
		--[[ MARKSÖKNINGEN SKA RESPEKTERA KOLLISION. Ridbanans sand är ett
			dekorlager utan kollision, och att sätta av på den vore att
			sätta av i luften. Svarar strålen fel sorts yta faller provet. ]]
		if not (params and params.RespectCanCollide) then
			return { Position = Vector3.new(origin.X, 900, origin.Z),
				Normal = Vector3.new(0, 1, 0), Instance = { Name = "dekorlager" } }
		end
		local y = markFn(origin.X, origin.Z)
		if y == nil then return nil end
		--[[ Strålen har en räckvidd. Ligger golvet utanför den finns det
			inget golv, precis som i världen. ]]
		if y > origin.Y or (origin.Y - y) > 24 then return nil end
		return { Position = Vector3.new(origin.X, y, origin.Z),
			Normal = Vector3.new(0, 1, 0), Instance = { Name = "golv" } }
	end
	__delarILada = function(cf, storlek, _params)
		if hinderFn and hinderFn(cf.Position, storlek) then
			return { { Name = "hinder", CanCollide = true } }
		end
		return {}
	end
end

local PLATT = function() return 0 end

local function nyKaraktar(pos)
	local k = Instance.new("Model")
	k.Name = "Karaktar"
	local rot = Instance.new("Part")
	rot.Name = "HumanoidRootPart"
	rot.Size = Vector3.new(2, 2, 1)
	rot.CFrame = CFrame.new(pos)
	rot.Parent = k
	local hum = Instance.new("Humanoid")
	hum.Name = "Humanoid"
	hum.Parent = k
	k.Parent = workspace
	return k, rot, hum
end

local function nyHast(id, namn, hojd, x)
	local m = HastRigg.bygg(id, namn, CFrame.new(Vector3.new(x, 0, 0)), hojd)
	m.Parent = workspace
	return m
end

--[[ HÄSTEN ÄR ETT HINDER. Utan henne i hinderfunktionen mäter provet
	aldrig det som var fel: att ryttaren hamnade inuti henne. Lådan
	jämförs i hästens EGET rum, så provet inte behöver räkna om världen
	varje gång hästen vrids. ]]
local function hastSomHinder(hast, extra)
	local rot = hast.PrimaryPart
	return function(p, storlek)
		local l = rot.CFrame:PointToObjectSpace(p)
		local inne = math.abs(l.X) < (rot.Size.X + storlek.X) / 2
			and math.abs(l.Z) < (rot.Size.Z + storlek.Z) / 2
		if inne then return true end
		return extra ~= nil and extra(p, storlek, l)
	end
end

local jack = nyHast("blackrock_jack", "Blackrock Jack", 1.45, 0)
local rotJ = jack.PrimaryPart
local kar, krot, khum = nyKaraktar(Vector3.new(0, 20, 0))

--[[ ══ 1. VÄNSTER NÄR VÄNSTER ÄR FRI ═════════════════════════════════ ]]
print("\n── Vänster sida först, som man sitter av ──")

varld(PLATT, hastSomHinder(jack))
local cf, skal = HorseService._avsittningsplats(jack, kar)
check("en plats hittas", cf ~= nil, tostring(skal))
check("och den är vänster sida", skal == "avsitt.vanster", tostring(skal))

local lokal = rotJ.CFrame:PointToObjectSpace(cf.Position)
check("platsen ligger till VÄNSTER i hästens eget rum", lokal.X < 0,
	string.format("lokal x %.3f", lokal.X))
check("och i höjd med henne, varken fram eller bak", nara(lokal.Z, 0, 1e-6),
	string.format("lokal z %.3f", lokal.Z))

--[[ INGEN ÖVERLAPPNING. Kravet är kropp mot kropp, inte mittpunkt mot
	mittpunkt: halva hästens bredd plus halva ryttarens måste rymmas. ]]
check("ryttarens kropp rör inte hästens",
	math.abs(lokal.X) >= rotJ.Size.X / 2 + krot.Size.X / 2,
	string.format("%.3f mot krav %.3f", math.abs(lokal.X),
		rotJ.Size.X / 2 + krot.Size.X / 2))

--[[ FÖTTERNA PÅ MARKEN. `HipHeight` är marken till rotens underkant, så
	rotens mitt ska ligga marken + halva roten + HipHeight. Ett tal för
	lågt och hon står i golvet; ett för högt och hon faller. ]]
check("fötterna står på golvet, varken i det eller ovanför",
	nara(cf.Position.Y - krot.Size.Y / 2 - khum.HipHeight, 0, 1e-6),
	string.format("markhöjd under fötterna %.4f",
		cf.Position.Y - krot.Size.Y / 2 - khum.HipHeight))

--[[ HON VÄNDER SIG MOT HÄSTEN. Att sitta av och stå med ryggen mot henne
	är fel både i verkligheten och på skärmen. ]]
local mot = (Vector3.new(rotJ.Position.X, cf.Position.Y, rotJ.Position.Z) - cf.Position)
local framat = cf.LookVector
check("och hon står vänd mot hästen",
	(framat.X * mot.X + framat.Z * mot.Z) > 0,
	string.format("look (%.2f %.2f) mot (%.2f %.2f)", framat.X, framat.Z, mot.X, mot.Z))

--[[ ══ 2. HÖGER NÄR VÄNSTER ÄR UPPTAGEN ═════════════════════════════ ]]
print("\n── Höger sida när vänster är blockerad ──")

varld(PLATT, hastSomHinder(jack, function(_p, _s, l) return l.X < 0 end))
local cf2, skal2 = HorseService._avsittningsplats(jack, kar)
check("en plats hittas ändå", cf2 ~= nil, tostring(skal2))
check("och det är höger sida", skal2 == "avsitt.hoger", tostring(skal2))
check("platsen ligger till HÖGER i hästens eget rum",
	rotJ.CFrame:PointToObjectSpace(cf2.Position).X > 0,
	string.format("lokal x %.3f", rotJ.CFrame:PointToObjectSpace(cf2.Position).X))

--[[ ══ 3. BÅDA SIDOR UPPTAGNA ════════════════════════════════════════ ]]
print("\n── Båda sidor blockerade: närmaste säkra läge ──")

--[[ En bred sarg på var sida, som i en smal box: bara framför och bakom
	finns plats. Det är precis det läge regeln "närmaste säkra" finns för. ]]
varld(PLATT, hastSomHinder(jack, function(_p, _s, l)
	return math.abs(l.Z) < 3.0
end))
local cf3, skal3 = HorseService._avsittningsplats(jack, kar)
check("en plats hittas även då", cf3 ~= nil, tostring(skal3))
check("men den är varken vänster eller höger", skal3 == "avsitt.narmaste",
	tostring(skal3))
local l3 = rotJ.CFrame:PointToObjectSpace(cf3.Position)
check("den ligger fram eller bak, inte rakt ut åt sidan", math.abs(l3.Z) > 0.5,
	string.format("lokal (%.2f %.2f)", l3.X, l3.Z))
check("och fortfarande utanför hästens kropp",
	math.abs(l3.Z) >= rotJ.Size.Z / 2,
	string.format("|z| %.2f mot halva längden %.2f", math.abs(l3.Z), rotJ.Size.Z / 2))

--[[ ══ 4. INGEN MARK, INGEN TELEPORT ═════════════════════════════════ ]]
print("\n── Marken avgör, inte riktningen ──")

--[[ Vänster sida är ett stup — golvet ligger tolv studs ned. En
	avsittning dit är inget fall att räkna på, det är en teleport ut ur
	världen, och regeln ska välja höger i stället. ]]
varld(function(x, _z)
	local l = rotJ.CFrame:PointToObjectSpace(Vector3.new(x, 0, 0))
	return if l.X < -1 then -12 else 0
end, hastSomHinder(jack))
local cf4, skal4 = HorseService._avsittningsplats(jack, kar)
check("stup till vänster väljs bort", skal4 == "avsitt.hoger", tostring(skal4))
check("och platsen står på det golv som finns där",
	nara(cf4.Position.Y - krot.Size.Y / 2 - khum.HipHeight, 0, 1e-6),
	string.format("%.4f", cf4.Position.Y - krot.Size.Y / 2 - khum.HipHeight))

--[[ Saknas bärande golv överallt finns ingen plats alls, och då ska
	räkningen SÄGA det i stället för att hitta på en höjd. ]]
varld(function() return nil end, hastSomHinder(jack))
local cf5, skal5 = HorseService._avsittningsplats(jack, kar)
check("utan golv finns ingen plats", cf5 == nil and skal5 == "avsitt.ingen_plats",
	tostring(skal5))

--[[ ══ 5. HÄSTENS EGET RUM, INTE VÄRLDENS ════════════════════════════ ]]
print("\n── Platsen följer hästen när hon vänder sig ──")

--[[ En världskoordinat hade legat kvar när hästen vred sig. Hela regeln
	bygger på att "vänster" är HENNES vänster. ]]
local vriden = nyHast("marabou", "Marabou vriden", 1.45, 200)
vriden.PrimaryPart.CFrame = vriden.PrimaryPart.CFrame * CFrame.Angles(0, math.rad(90), 0)
varld(PLATT, hastSomHinder(vriden))
local cf6, skal6 = HorseService._avsittningsplats(vriden, kar)
check("en vriden häst ger också vänster sida", skal6 == "avsitt.vanster", tostring(skal6))
local l6 = vriden.PrimaryPart.CFrame:PointToObjectSpace(cf6.Position)
check("och platsen är HENNES vänster, inte världens",
	l6.X < 0 and nara(l6.Z, 0, 1e-6),
	string.format("lokal (%.2f %.2f)", l6.X, l6.Z))

--[[ ══ 6. STORLEKEN FÖLJER MED ════════════════════════════════════════ ]]
print("\n── En stor häst kräver mer plats än en ponny ──")

local ponny = nyHast("marabou", "Marabou", 1.27, 400)
local stor = nyHast("allan", "Allan", 1.78, 600)
local function sidled(hast)
	varld(PLATT, hastSomHinder(hast))
	local c = HorseService._avsittningsplats(hast, kar)
	return math.abs(hast.PrimaryPart.CFrame:PointToObjectSpace(c.Position).X)
end
local sp, sj, ss = sidled(ponny), sidled(jack), sidled(stor)
check("ponnyn kräver minst sidled, den stora hästen mest", sp < sj and sj < ss,
	string.format("%.2f < %.2f < %.2f", sp, sj, ss))

--[[ ══ 7. HELA AVSITTNINGEN ═══════════════════════════════════════════ ]]
print("\n── Avsittningen lämnar inget efter sig ──")

varld(PLATT, hastSomHinder(jack))
HorseService.setMountGate(nil)
HorseService._registerForProv(jack)
local spelare = { Name = "SagaAberg", UserId = 1, Character = kar,
	CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }
krot.CFrame = CFrame.new(rotJ.Position.X + 3, rotJ.Position.Y, rotJ.Position.Z)

local okUpp, skalUpp = HorseService.tryMount(spelare, jack)
check("hon sitter upp", okUpp == true, tostring(skalUpp))
local sits = jack:FindFirstChild("RiderSeat")
check("sitsen har henne", sits.Occupant == khum)
check("och hästen bär hennes id",
	jack:GetAttribute("RiderUserId") == spelare.UserId,
	tostring(jack:GetAttribute("RiderUserId")))

krot.AssemblyLinearVelocity = Vector3.new(0, 0, 40)

--[[ RÄKNA FLYTTARNA. Avsittningen placerar TVÅ gånger: en gång direkt och
	en gång när sitsen har släppt. Den andra är den som håller i Studio, och
	den enda vakt bänken kan sätta mot att den tyst faller bort är att räkna
	att den faktiskt hände. Den föll bort en gång: `setRider(session, nil)`
	låg efter placeringen, så vakten "har hon hunnit sätta sig igen?" läste
	ett `byRider` som ännu pekade på hästen hon just klev av. ]]
local flyttar = 0
local egenPivot = kar.PivotTo
kar.PivotTo = function(self, cf)
	flyttar += 1
	return egenPivot(self, cf)
end

local okNed = HorseService.dismount(spelare)
kar.PivotTo = egenPivot
check("kroppen placerades två gånger: direkt och när sitsen släppte",
	flyttar == 2, string.format("%d placeringar", flyttar))
check("hon sitter av", okNed == true)
check("Humanoid.Sit är falskt", khum.Sit == false, tostring(khum.Sit))
check("sitsen är tom", sits.Occupant == nil, tostring(sits.Occupant))
check("sitsens egen SeatWeld är borta", sits:FindFirstChild("SeatWeld") == nil)
check("RiderUserId är nollat", jack:GetAttribute("RiderUserId") == 0,
	tostring(jack:GetAttribute("RiderUserId")))

--[[ DET SOM VAR FEL: hon stod kvar ovanpå hästen. Mätningen är därför
	inte "hon flyttades" utan "hon står inte längre över henne". ]]
local slut = kar:GetPivot().Position
local lokalSlut = rotJ.CFrame:PointToObjectSpace(slut)
check("hon står INTE ovanpå hästen",
	math.abs(lokalSlut.X) >= rotJ.Size.X / 2 + krot.Size.X / 2,
	string.format("sidled %.2f studs, höjd över hästroten %+.2f",
		math.abs(lokalSlut.X), slut.Y - rotJ.Position.Y))
check("hon står på golvet",
	nara(slut.Y - krot.Size.Y / 2 - khum.HipHeight, 0, 1e-6),
	string.format("%.4f", slut.Y - krot.Size.Y / 2 - khum.HipHeight))
check("och farten är nollad så hon inte slungas iväg",
	krot.AssemblyLinearVelocity.Magnitude == 0,
	tostring(krot.AssemblyLinearVelocity.Magnitude))

__markyta = nil
__delarILada = nil

if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("\navsittning.spec: alla gröna")
end
