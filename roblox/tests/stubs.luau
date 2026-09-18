--[[ __MATERIAL injiceras har av build.py ]]
local __MATERIAL = {}

--[[ Ett strikt enum: svarar bara pa namn som finns i listan, och kastar
	annars. __MATERIAL injiceras av roblox/tests/build.py ur
	roblox/tests/roblox-material.txt.

	Forsta versionen svarade pa ALLT, och da passerade
	materialnamnet CorrugatedMetal — som inte finns i Roblox — hela sviten och
	sprack forst nar en manniska korde bygget i Studio. En stubb som sager ja
	till allt provar ingenting. ]]
local function __striktEnum(vad, tillatna)
	--[[ Tom lista betyder att filen INTE byggdes via build.py, alltsa att
		injektionen uteblev. Utan den har vakten sag det ut som att VARJE
		material var ogiltigt, och felmeddelandet pekade at helt fel hall. ]]
	assert(#tillatna > 0,
		"__MATERIAL ar tom: bygg specen med roblox/tests/build.py, eller kor "
		.. "paketet med tools/kor-paket.py")
	local m = {}
	for _, n in ipairs(tillatna) do m[n] = n end
	return setmetatable({}, { __index = function(_, k)
		if m[k] then return k end
		error(("%s is not a valid member of \"Enum.%s\" — se roblox/tests/roblox-material.txt")
			:format(tostring(k), vad), 2)
	end })
end

--!nostrict
--[[
	Roblox-stubbar för mätningarna utanför Studio.

	Bara det rörelsekoden faktiskt rör: vektorer med de operatorer den
	använder, en Humanoid som sparar WalkSpeed och rörelseriktning, en root
	med CFrame, och ett workspace vars Raycast alltid ger plan mark. Allt
	annat i spelet — animation, ljud, nätverk — ligger utanför och behöver
	ingen stub.

	Om en stub saknas kraschar bänken med tjänstens namn, i stället för att
	tyst mäta fel sak.
]]

local vec
function vec(x, y, z)
	local v = { X = x or 0, Y = y or 0, Z = z or 0 }
	function v:Dot(o) return self.X * o.X + self.Y * o.Y + self.Z * o.Z end
	function v:Lerp(o, a)
		return vec(self.X + (o.X - self.X) * a, self.Y + (o.Y - self.Y) * a,
			self.Z + (o.Z - self.Z) * a)
	end
	function v:Cross(o)
		return vec(self.Y * o.Z - self.Z * o.Y, self.Z * o.X - self.X * o.Z,
			self.X * o.Y - self.Y * o.X)
	end
	local mt = {}
	mt.__add = function(a, b) return vec(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
	mt.__sub = function(a, b) return vec(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
	mt.__mul = function(a, b)
		if type(b) == "number" then return vec(a.X * b, a.Y * b, a.Z * b) end
		if type(a) == "number" then return vec(b.X * a, b.Y * a, b.Z * a) end
		return vec(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
	end
	mt.__div = function(a, b) return vec(a.X / b, a.Y / b, a.Z / b) end
	mt.__unm = function(a) return vec(-a.X, -a.Y, -a.Z) end
	--[[ Magnitude och Unit räknas vid uppslag, inte i förväg: de används
	     bara av kamerans väggkontroll och kostar då ingenting här. ]]
	mt.__index = function(t, k)
		if k == "Magnitude" then
			return math.sqrt(t.X * t.X + t.Y * t.Y + t.Z * t.Z)
		elseif k == "Unit" then
			local m = math.sqrt(t.X * t.X + t.Y * t.Y + t.Z * t.Z)
			if m < 1e-9 then return vec(0, 0, 0) end
			return vec(t.X / m, t.Y / m, t.Z / m)
		end
		return nil
	end
	return setmetatable(v, mt)
end
Vector3 = { new = vec, yAxis = vec(0, 1, 0), zero = vec(0, 0, 0) }

-- Färger. Geometrispecen läser den genererade UBRFKomplex.luau, och där står
-- fasadfärgerna som Color3.fromRGB — de behöver inte göra något, bara finnas,
-- annars går filen inte att ladda utanför Studio.
Color3 = {
	fromRGB = function(r, g, b) return { R = (r or 0) / 255, G = (g or 0) / 255, B = (b or 0) / 255 } end,
	new = function(r, g, b) return { R = r or 0, G = g or 0, B = b or 0 } end,
}

--[[ `ColorSequence` — en fargskala over en `Beam` eller partikel.
     Ledrepet (#182 del 2) ar en Beam, och utan den har stubben kunde
     `LedService.borja` inte ens KORA i bankan: hela ledningskedjan blev
     omatbar for att en fargkonstruktor saknades. En stubb som inte
     kanner till ett API tystar inte provet, den doljer produktionen.

     Bara det bankan behover: ett varde som gar att lasa tillbaka. ]]
ColorSequenceKeypoint = {
	new = function(tid, farg) return { Time = tid or 0, Value = farg } end,
}
ColorSequence = {
	new = function(a, b)
		return { Keypoints = { { Time = 0, Value = a }, { Time = 1, Value = b or a } } }
	end,
}

local function cframe(pos, look, yaw, pitch, roll)
	local c = { Position = pos or vec(), LookVector = look or vec(0, 0, 1),
		Yaw = yaw or 0, Pitch = pitch or 0, Roll = roll or 0 }
	--[[ Multiplikation används för att vrida en led på stället. Stubben bär
	     de tre vinklarna vidare som summor så att testet kan läsa dem. Det
	     är inte riktig rotationsmatematik — men för små vinklar kring skilda
	     axlar, vilket är allt koden lägger på, ger den samma svar. ]]
	--[[ ToOrientation ger (pitch, yaw, roll) i radianer, precis som Roblox
	     -- alltsa ar select(2, ...) girningen. Stubben bar redan de tre
	     vinklarna, sa den svarar med dem i samma ordning. G02-D laser yaw
	     har for att spela in at vilket hall hasten stod. ]]
	c.ToOrientation = function(self) return self.Pitch or 0, self.Yaw or 0, self.Roll or 0 end
	--[[ ROTATIONSMATRISEN, sa langt bankan har en.

	     `BuildKit.speglaCF` har tva grenar: en riktig matrisgren, som ar den
	     Studio kor, och en girningsfallback for stubbar. Bankan foll alltid
	     till fallbacken — alltsa provades aldrig den kod som faktiskt bygger
	     varlden, och spawnens 180-gradersfel kunde inte upptackas har.

	     Nu svarar stubben med en riktig matris for REN GIRNING, vilket ar
	     allt anlaggningen lagger pa platta delar. Bar delen lutning eller
	     rullning svarar den med ingenting alls, och da tar speglingen sin
	     fallback precis som forut — hellre en arlig lucka an en matris
	     stubben inte kan sta for. ]]
	c.GetComponents = function(self)
		if math.abs(self.Pitch or 0) > 1e-9 or math.abs(self.Roll or 0) > 1e-9 then
			return
		end
		local th = self.Yaw or 0
		local ct, st = math.cos(th), math.sin(th)
		local p = self.Position or vec()
		return p.X, p.Y, p.Z,
			ct, 0, st,
			0, 1, 0,
			-st, 0, ct
	end
	--[[ VARLDSPUNKT -> EGET RUM. Exakt inversen av `__mul` nedan, for
	     samma rena girning: [ca sa; -sa ca] har inversen [ca -sa; sa ca].
	     `TackRigg` laser bygelpunkten i sadelns rum for att kunna spanna
	     stiglader dit foten faktiskt hamnar, och transet laser bettet i
	     nosryggens rum for att fa huvudets egna matt. Utan den kunde
	     banken inte prova nagot av det. ]]
	c.PointToObjectSpace = function(self, p)
		local ap = self.Position or vec()
		local ca, sa = math.cos(self.Yaw or 0), math.sin(self.Yaw or 0)
		local dx, dy, dz = (p.X or 0) - ap.X, (p.Y or 0) - ap.Y, (p.Z or 0) - ap.Z
		return vec(dx * ca - dz * sa, dy, dx * sa + dz * ca)
	end
	c.PointToWorldSpace = function(self, p)
		return (self * CFrame.new(p)).Position
	end
	--[[ ══ `CFrame ± Vector3` SAKNADES (#246) ═══════════════════════════

	     I Roblox FLYTTAR de en CFrame och lamnar rotationen orord;
	     `cf - cf.Position` ar det vanliga sattet att plocka ut ENBART
	     vridningen. `LedService.placeraVidMal` gor precis det:

	         modell:PivotTo(CFrame.new(mitt) * (pivot.CFrame - pivot.Position))

	     Stubben hade ingen `__sub` pa CFrame, sa Lua tog Vector3:ans i
	     stallet — och den raknade `a.X` pa en CFrame, alltsa nil. Hela
	     «Rida nu»-genvagens slutfas kraschade darfor i banken sa fort
	     `typeof`-vakten slapp igenom den. Bada operatorerna finns nu, och
	     de ror bara positionen. ]]
	c.__sub = function(a, b)
		local ap = a.Position or vec()
		return cframe(vec(ap.X - (b.X or 0), ap.Y - (b.Y or 0), ap.Z - (b.Z or 0)),
			a.LookVector, a.Yaw or 0, a.Pitch or 0, a.Roll or 0)
	end
	c.__add = function(a, b)
		local ap = a.Position or vec()
		return cframe(vec(ap.X + (b.X or 0), ap.Y + (b.Y or 0), ap.Z + (b.Z or 0)),
			a.LookVector, a.Yaw or 0, a.Pitch or 0, a.Roll or 0)
	end
	c.__mul = function(a, b)
		--[[ `CFrame * Vector3` ar en PUNKT i varlden, inte en ny CFrame.
		     Stubben svarade forut med en CFrame aven har, sa varje modul
		     som raknade om en lokal punkt till varlden — `TackRigg`s
		     spann-delar, till exempel — fick tillbaka nagot som inte gick
		     att mata. En Vector3-stubbe saknar `Position`; det ar
		     skillnaden mellan de tva fallen. ]]
		if b ~= nil and b.Position == nil and b.X ~= nil then
			local ca, sa = math.cos(a.Yaw or 0), math.sin(a.Yaw or 0)
			local ap = a.Position or vec()
			return vec(ap.X + b.X * ca + b.Z * sa,
				ap.Y + b.Y,
				ap.Z - b.X * sa + b.Z * ca)
		end
		--[[ FÖRFLYTTNINGEN räknas, inte bara vinklarna. Förut svarade
		     `a * b` med `a.Position` oavsett vad b var, och då hamnade
		     varje del som placeras relativt en annan — hela HastRiggs
		     rigg, till exempel — i samma punkt. Ett avståndsprov mot en
		     sådan rigg mäter ingenting. Offseten vrids med a:s girning,
		     precis som byggstubbarna gör (stubs-bygge.luau), så en
		     placering "0,4 m framåt" följer den riktning delen står i. ]]
		local off = b.Position or vec()
		local ca, sa = math.cos(a.Yaw or 0), math.sin(a.Yaw or 0)
		local ap = a.Position or vec()
		local pos = vec(ap.X + off.X * ca + off.Z * sa,
			ap.Y + off.Y,
			ap.Z - off.X * sa + off.Z * ca)
		return cframe(pos, a.LookVector, (a.Yaw or 0) + (b.Yaw or 0),
			(a.Pitch or 0) + (b.Pitch or 0), (a.Roll or 0) + (b.Roll or 0))
	end
	return setmetatable(c, c)
end
CFrame = {
	--[[ Roblox har båda formerna: `CFrame.new(x, y, z)` och
	     `CFrame.new(vector3)`. Stubben tog bara den andra, så en modul som
	     placerar en del med tal — hela HastRigg — fick ett tal där en
	     Vector3 skulle stå, och multiplikationen gick sönder på `off.X`. ]]
	new = function(a, b, c, ...)
		if type(a) == "number" then
			local m = { ... }
			--[[ TOLVTALSFORMEN: `CFrame.new(x, y, z, R00 … R22)`. Stubben
			     tog bara tre tal och kastade tyst bort rotationen, sa
			     `speglaCF`:s matrisgren gav en ovriden del har medan den
			     gav en vriden i Studio. Girningen las nu ur matrisen
			     (R02 = sin, R22 = cos) och blickriktningen ur tredje
			     kolumnen, precis som i Roblox: LookVector = -kolumn 2. ]]
			if #m >= 9 then
				local r02, r12, r22 = m[3], m[6], m[9]
				return cframe(vec(a, b or 0, c or 0),
					vec(-r02, -r12, -r22), math.atan2(r02, r22))
			end
			return cframe(vec(a, b or 0, c or 0))
		end
		return cframe(a)
	end,
	--[[ `lookAt(har, dit)` gav forut MALPUNKTEN som LookVector. Det ar inte
	     en riktning, och darfor kunde ingen grind fraga at vilket hall
	     spawnen vetter. Nu raknas en riktig enhetsriktning, och girningen
	     satts sa att den stammer med den: for R_y(th) ar
	     LookVector = (-sin th, 0, -cos th). ]]
	lookAt = function(a, b)
		local dx, dy, dz = (b.X or 0) - (a.X or 0), (b.Y or 0) - (a.Y or 0),
			(b.Z or 0) - (a.Z or 0)
		local L = math.sqrt(dx * dx + dy * dy + dz * dz)
		if L < 1e-9 then return cframe(a) end
		dx, dy, dz = dx / L, dy / L, dz / L
		return cframe(a, vec(dx, dy, dz), math.atan2(-dx, -dz))
	end,
	Angles = function(x, y, z) return cframe(nil, nil, y or 0, x or 0, z or 0) end,
	identity = cframe(),
	fromMatrix = function(p) return cframe(p) end,
}

RaycastParams = { new = function()
	--[[ `RespectCanCollide` star med for att `Markkontakt` MATER PA DEN:
	     skillnaden mellan en stral som traffar allt och en som bara traffar
	     det som bar AR lagrets tjocklek. En stub utan faltet hade latit
	     mattningen ge noll utan att provet markte det. ]]
	return { FilterType = 0, FilterDescendantsInstances = {},
		RespectCanCollide = false }
end }

Enum = {
	RaycastFilterType = { Exclude = 1 },
	HumanoidStateType = { Freefall = 1, Jumping = 2, Running = 3, Landed = 4 },
	PathStatus = { Success = 1, NoPath = 2, ClosestNoPath = 3 },
	KeyCode = setmetatable({}, { __index = function(_, k) return k end }),
	--[[ `ProximityPromptExclusivity` — vilken prompt som visas nar flera
	     delar knapp. Roblox STANDARD ar `OnePerButton`, och det ar precis
	     den standarden som gjorde fyra handlingar pa `E` till en synlig
	     och tre osynliga (#235, #182 del 3). Utan enumen i bankan gick
	     regeln inte att mata alls. ]]
	--[[ `OrientationAlignmentMode` — om `AlignOrientation` styr mot EN
	     fastpunkt (en riktning) eller mot tva (kopiera en annan kropp).
	     Ledningen anvander `OneAttachment`: hasten ska peka dit hon gar,
	     inte kopiera spelarens vridning. ]]
	OrientationAlignmentMode = setmetatable({},
		{ __index = function(_, k) return k end }),
	ProximityPromptExclusivity = setmetatable({},
		{ __index = function(_, k) return k end }),
	--[[ #246 C: `Style = Custom` slacker Robloxs EGNA prompt-UI men
	     lamnar aktiveringsvagen orord — `InputHoldBegin` fungerar precis
	     som forut. Verifierat mot
	     create.roblox.com/docs/reference/engine/enums/ProximityPromptStyle
	     (Default = 0, Custom = 1). Uppraknad, inte en __index som svarar pa
	     allt: samma skal som Material och Font. ]]
	ProximityPromptStyle = { Default = 0, Custom = 1 },

	UserInputState = { Begin = 1, End = 2 },
	--[[ #220: `Touch` tillkom med blickspecen. TouchControls sorterar
	     varje nedslag pa `UserInputType`, och utan enumen jamforde banken
	     mot nil — ett pekfinger och en mus var da samma sak. De tva
	     mus-typerna finns for att kunna mata att en mus AVVISAS. ]]
	UserInputType = { Gamepad1 = 1, Touch = 2, MouseButton1 = 3, MouseMovement = 4 },
	ContextActionResult = { Sink = 1 },
	CameraType = { Scriptable = 1, Custom = 2 },
	--[[ Front och Back tillkom med skyltarnas SurfaceGui: speglingen byter
	     dem, och utan bada kunde bytet varken goras eller matas. ]]
	NormalId = { Top = 1, Front = 2, Back = 3 },
	SurfaceGuiSizingMode = { FixedSize = 1, PixelsPerStud = 2 },
	--[[ HastRigg satter Top/BottomSurface pa riggens delar, och RiderController
	     bygger IKControl. Uppraknade, inte en __index som svarar pa allt: samma
	     skal som Material ovan. ]]
	SurfaceType = { Smooth = 1, SmoothNoOutlines = 2, Studs = 3, Inlet = 4,
		Universal = 5, Weld = 6, Glue = 7, Hinge = 8, Motor = 9, SteppingMotor = 10 },
	IKControlType = { Transform = 1, Position = 2, Rotation = 3, LookAt = 4 },
	AnimationPriority = { Core = 1, Idle = 2, Movement = 3, Action = 4 },
	--[[ STRIKT. Forst svarade Material pa vilket namn som helst, och da
	     passerade materialnamnet CorrugatedMetal — som inte finns i Roblox —
	     hela sviten och sprack forst i Studio. Listan injiceras av
	     build.py ur roblox/tests/roblox-material.txt, sa den finns pa ETT
	     stalle. ]]
	Material = __striktEnum("Material", __MATERIAL),
	--[[ De UI-enum HUD:en rör. Medvetet uppräknade och inte en __index som
	     svarar på allt: samma skäl som Material — en enum-mock som svarar ja
	     på vad som helst gör att ett stavfel passerar bänken och spricker
	     först i Studio. ]]
	ZIndexBehavior = { Sibling = 1, Global = 2 },
	Font = { Gotham = 1, GothamBold = 2, SourceSans = 3, SourceSansBold = 4 },
	TextXAlignment = { Left = 1, Center = 2, Right = 3 },
	TextYAlignment = { Top = 1, Center = 2, Bottom = 3 },
	TextTruncate = { None = 0, AtEnd = 1, SplitWord = 2 },
	SizeConstraint = { RelativeXY = 1, RelativeXX = 2, RelativeYY = 3 },
	FillDirection = { Horizontal = 1, Vertical = 2 },
	SortOrder = { Name = 1, Custom = 2, LayoutOrder = 3 },
	--[[ Layoutobjektens justering. `TouchControls.mount` ankrar bada
	     gallren i hogerkanten och nederkanten; utan enumen gick
	     monteringen inte att kora i banken (#208). ]]
	HorizontalAlignment = { Left = 1, Center = 2, Right = 3 },
	VerticalAlignment = { Top = 1, Center = 2, Bottom = 3 },
	AutomaticSize = { None = 0, X = 1, Y = 2, XY = 3 },
	--[[ #244: toningens enum. Uppraknade av samma skal som Material och de
	     ovriga UI-enumen ovan — en __index som svarar pa allt hade latit
	     `Enum.EasingStyle.Kvadratisk` passera hela sviten och falla forst i
	     Studio. Namnen ar Roblox egna. ]]
	EasingStyle = { Linear = 1, Sine = 2, Back = 3, Quad = 4, Quart = 5,
		Quint = 6, Bounce = 7, Elastic = 8, Exponential = 9, Circular = 10,
		Cubic = 11 },
	EasingDirection = { In = 1, Out = 2, InOut = 3 },
	--[[ HAR STOD `TextTransform` EN STUND, OCH DET VAR ETT FEL.
	     CoachBanner satte `TextLabel.TextTransform` for att fa versaler,
	     och stubben svarade snallt ja. Egenskapen finns inte pa TextLabel
	     (kontrollerat mot create.roblox.com/docs, klassen uppdaterad
	     2026-09-17) — i Studio hade raden kastat. Versalerna raknas nu i
	     modulen, och enumen ar borta harifran av samma skal som
	     `Enum.Material` ar strikt: en mock som svarar ja pa allt flyttar
	     felet fran sviten till Studio. ]]
}

--[[ UI-typerna. HUD:en bara skapar dem och läser dem aldrig isär, så de
     lagras som vad de är — inga beräkningar, ingen låtsad Roblox-matematik. ]]
function UDim2_new(xs, xo, ys, yo)
	--[[ Bade den platta formen (aldre specar laser XOffset) och Roblox egen
	     (Size.Y.Offset). En stub som bara har den platta formen later ett prov
	     som laser rratt fram ge nil i stallet for ett tal, och da matte provet
	     ingenting -- precis den sortens tysta halvsanning bankan finns for att
	     undvika. ]]
	return { _typ = "UDim2", XScale = xs, XOffset = xo, YScale = ys, YOffset = yo,
		X = { _typ = "UDim", Scale = xs, Offset = xo },
		Y = { _typ = "UDim", Scale = ys, Offset = yo } }
end
UDim2 = { new = UDim2_new, fromScale = function(x, y) return UDim2_new(x, 0, y, 0) end,
	fromOffset = function(x, y) return UDim2_new(0, x, 0, y) end }
UDim = { new = function(sc, off) return { _typ = "UDim", Scale = sc, Offset = off } end }
--[[ #220: Vector2 fick RAKNESATT. Blickytan i TouchControls raknar
     skillnaden mellan tva fingerlagen (`nu - forra`) och spaken summerar
     `AbsolutePosition + AbsoluteSize / 2`. Utan operatorerna gick ingen
     gest att driva genom banken. Faltformen `{ _typ, X, Y }` ar oforandrad,
     sa aldre prov som bygger en platt tabell for hand fungerar som forut. ]]
local __V2 = {}
__V2.__index = function(t, k)
	if k == "Magnitude" then return math.sqrt(t.X * t.X + t.Y * t.Y) end
	return rawget(__V2, k)
end
local function __v2(x, y)
	return setmetatable({ _typ = "Vector2", X = x, Y = y }, __V2)
end
__V2.__add = function(a, b) return __v2(a.X + b.X, a.Y + b.Y) end
__V2.__sub = function(a, b) return __v2(a.X - b.X, a.Y - b.Y) end
__V2.__unm = function(a) return __v2(-a.X, -a.Y) end
__V2.__mul = function(a, b)
	if type(a) == "number" then return __v2(a * b.X, a * b.Y) end
	if type(b) == "number" then return __v2(a.X * b, a.Y * b) end
	return __v2(a.X * b.X, a.Y * b.Y)
end
__V2.__div = function(a, b)
	if type(b) == "number" then return __v2(a.X / b, a.Y / b) end
	return __v2(a.X / b.X, a.Y / b.Y)
end
__V2.__eq = function(a, b) return a.X == b.X and a.Y == b.Y end
Vector2 = { new = __v2, zero = __v2(0, 0) }

--[[ `warn` fanns inte i bänken. Produktionskoden använder den på sina
     nil-vägar — t.ex. när anläggningen inte är byggd — så utan den kraschade
     just den gren som skulle bevisas fungera. Samlas i stället för att
     skrivas ut, så att ett prov kan läsa vad som varnades. ]]
__varningar = {}
function warn(...)
	table.insert(__varningar, table.concat({ ... }, " "))
end

--[[ EN SPEC FAR LAGGA UNDERLAG UNDER BANKEN. Standard ar fortfarande plan
     mark pa y 0; satts `__markyta` svarar strålen det provet bestammer, och
     da kan ett dekorlager utan kollision mätas pa riktigt. ]]
__markyta = nil

--[[ Samma sak for hinderprovningen: avsittningen fragar vad som star i
     vagen med `GetPartBoundsInBox`, och utan en sadan kan bänken inte
     prova skillnaden mellan en fri vansterssida och en blockerad. Satts
     `__delarILada` svarar varlden det provet bestammer; standard ar tomt,
     alltsa fri plats. ]]
__delarILada = nil

OverlapParams = { new = function()
	return { FilterType = 0, FilterDescendantsInstances = {} }
end }

workspace = {
	--[[ `ChildAdded`/`ChildRemoved` SAKNADES (#180).

	     `DinHast.start` kopplar sig till `workspace.ChildAdded` för att
	     släcka andra spelares boxmarkörer när de dyker upp — flerspelar-
	     fixen ur #162. Utan signalen dog `sprak`, `varldshud` och `klient`
	     på `attempt to index nil with 'Connect'` så fort modulen alls kom
	     med i bänken.

	     Varje Instance i Roblox har dem. Att bänkens workspace inte hade
	     det är samma sorts hål som `signal:Wait()` och
	     `Players:GetPlayerFromCharacter` — harnessen, inte spelet. ]]
	GetPartBoundsInBox = function(_, cf, storlek, params)
		if __delarILada then
			return __delarILada(cf, storlek, params)
		end
		return {}
	end,
	Raycast = function(_, origin, dir, params)
		if __markyta then
			return __markyta(origin, dir, params)
		end
		--[[ Plan mark under hästen. Sluttningar testas separat om det
		     behövs; hit finns för att grounded ska bli sant. ]]
		return { Position = vec(origin.X, 0, origin.Z), Normal = vec(0, 1, 0),
			Instance = { Name = "Baseplate" }, Material = Enum.Material.Grass }
	end,
	--[[ ViewportSize lades till for G02-D: ridanalysens kontrollrad maste
	     brytas efter den bredd som faktiskt finns, och provet stallr om den
	     for telefon och iPad. Standard ar en skrivbordsbredd. ]]
	CurrentCamera = { CFrame = cframe(), FieldOfView = 70, CameraType = 2,
		ViewportSize = { _typ = "Vector2", X = 1280, Y = 720 } },
	--[[ Ingen anläggning byggd i bänken. StallService frågar efter den för
	     att kunna sätta en boxmarkör, och SKA då varna och hoppa över
	     markören i stället för att krascha — det är produktionens egen
	     nil-väg, och den provas nu på riktigt. ]]
	_barn = {},
	FindFirstChild = function(self, namn)
		for _, b in ipairs(self._barn) do if b.Name == namn then return b end end
		return nil
	end,
	--[[ `GetChildren` SAKNADES, och hålet är samma klass som `ChildAdded`
	     ovan (#180): ingen spec hade drivit `DinHast`s Heartbeat-loop, så
	     svepet efter andra spelares boxmarkörer kördes aldrig i bänken.
	     `klient-burenstatus.spec` kör den loopen — och dog direkt på
	     "attempt to call missing method 'GetChildren' of table".

	     Varje Instance i Roblox har den, och den returnerar en NY lista;
	     att lämna ut `_barn` självt hade låtit en anropare mutera
	     världen genom sitt eget svep. Harnessen, inte spelet. ]]
	GetChildren = function(self)
		local ut = {}
		for _, b in ipairs(self._barn or {}) do table.insert(ut, b) end
		return ut
	end,
	--[[ Genomsikt.start() sveper workspace efter genomsiktliga delar och
	     lyssnar på nya. Bänken hade varken svepet eller signalen, så
	     `start` gick inte att köra — och klientbänken kör hela
	     init.client.luau, `Genomsikt.start()` inkluderad. ]]
	GetDescendants = function(self)
		local ut = {}
		local function ner(nod)
			for _, b in ipairs(nod._barn or {}) do
				table.insert(ut, b); ner(b)
			end
		end
		ner(self)
		return ut
	end,
	DescendantAdded = { Connect = function() return { Disconnect = function() end } end },
}

--[[ Signalfabriken låg förut nedanför tjänsterna. Den flyttades hit när
     klientbänken (tests/klient.spec.luau) började KÖRA init.client.luau:
     ett skript som kopplar sig till RenderStepped, InputBegan och
     CharacterRemoving går inte att prova mot en Connect som slänger sin
     callback. Nu sparas lyssnarna och provet kan driva loopen. ]]
local function __signal()
	local sig = { _lyssnare = {} }
	function sig:Connect(fn)
		table.insert(self._lyssnare, fn)
		--[[ `Disconnect` KOPPLAR FAKTISKT BORT. Den var forr en tom funktion,
		     och da kunde banken inte skilja "stadningen fungerar" fran
		     "stadningen gor ingenting": `HorseService.slappStadning` river sina
		     lyssnare forst i avsittningen, men stubben lat dem ligga kvar, och
		     sitsens Occupant-lyssnare kallade darfor `dismount` en gang till
		     inifran `dismount`. Ett aterintrade som bara fanns i matverktyget. ]]
		local sjalv = self
		return { Disconnect = function()
			for i, f in ipairs(sjalv._lyssnare) do
				if f == fn then table.remove(sjalv._lyssnare, i) break end
			end
		end }
	end
	function sig:Fire(...)
		--[[ Over en KOPIA: en lyssnare som kopplar bort sig sjalv mitt i
		     fyrningen skulle annars hoppa over nasta i listan. ]]
		local nu = table.clone(self._lyssnare)
		for _, fn in ipairs(nu) do fn(...) end
	end
	--[[ `Wait` SAKNADES, och det gjorde avsittningen omatbar (#169 P1).
	     `HorseService.stannaHast` kor `RunService.Heartbeat:Wait()` atta
	     ganger i en `task.spawn`. Stubbens `task.spawn` kor funktionen
	     synkront, sa kastet slog rakt igenom `dismount` — och
	     `integration.spec` dog mitt i provet med noll FEL-rader, alltsa
	     sag ett KRASCH ut som nagot annat an ett fel i banken.
	     Returnerar 0 sekunders delta: ingen riktig tid gar, men slingan
	     far lopa klart och avsittningen gar att mata. ]]
	function sig:Wait()
		return 0
	end
	--[[ Samma skäl som i __signalTradar: varje `start()` i ett provblock
		lägger en ny lyssnare, och utan nollställning kör block två med
		block ettas kvar. ]]
	function sig:nollstall()
		self._lyssnare = {}
	end
	return sig
end

--[[ ── PlayerAdded MED RIKTIG TRÅDVÄXLING (#162 blockerare 1) ────────

     `__signal` kör sina lyssnare synkront, en i taget, klart. Roblox gör
     INTE så med `Players.PlayerAdded`: varje anslutning startas på sin
     egen tråd, så när den första yieldar — till exempel inne i ett
     `GetAsync` — körs nästa anslutning omedelbart, med den första ännu
     halvfärdig.

     Det är precis det fönstret blockerare 1 handlar om, och med den gamla
     stubben (`Connect = function() return {Disconnect} end`) gick det inte
     ens att nå: lyssnarna anropades aldrig. CI var grön därför att racet
     låg utanför bänken, inte därför att det inte fanns.

     `Fire` startar varje lyssnare i en coroutine och lägger de som
     suspenderat i kö. `slutfor()` väcker dem. Provet får därmed hantera
     interleavingen själv, deterministiskt, utan att sova. ]]
local function __signalTradar()
	local sig = { _lyssnare = {}, _vantande = {} }
	function sig:Connect(fn)
		table.insert(self._lyssnare, fn)
		return { Disconnect = function() end }
	end
	function sig:Fire(...)
		local arg = table.pack(...)
		for _, fn in ipairs(self._lyssnare) do
			local co = coroutine.create(fn)
			local ok, fel = coroutine.resume(co, table.unpack(arg, 1, arg.n))
			if not ok then error(fel, 0) end
			if coroutine.status(co) == "suspended" then
				table.insert(self._vantande, co)
			end
		end
	end
	--[[ Väck allt som suspenderat, i den ordning de suspenderade. ]]
	function sig:slutfor()
		local varv = 0
		while #self._vantande > 0 do
			varv += 1
			assert(varv < 1000, "slutfor() snurrade — en lyssnare vaknar aldrig")
			local co = table.remove(self._vantande, 1)
			local ok, fel = coroutine.resume(co)
			if not ok then error(fel, 0) end
			if coroutine.status(co) == "suspended" then
				table.insert(self._vantande, co)
			end
		end
	end
	function sig:harVantande(): boolean
		return #self._vantande > 0
	end
	--[[ Anslutningarna ligger kvar mellan provblock, och varje `start()`
		lägger nya. Utan nollställning körde block två med block ettas
		lyssnare kvar — synligt som en dubblerad tilldelningsrad, och
		precis den sorten som gör ett prov otillförlitligt utan att bli
		rött. ]]
	function sig:nollstall()
		self._lyssnare = {}
		self._vantande = {}
	end
	return sig
end

--[[ #244: registret over skapade tweens. Global for att specarna ska na
     det — precis som `__senasteDelay` och `__taggade`. Ett prov som mater
     toningen nollstaller det sjalv med `table.clear(__tweens)`. ]]
__tweens = {}

--[[ `TweenInfo` fanns inte i banken alls: ingen produktionsmodul hade
     tonat nagot forran CoachBanner. Falten ar Roblox egna namn, sa ett
     prov kan lasa `info.Time` och `info.EasingStyle` rakt av. ]]
TweenInfo = {
	new = function(tid, stil, riktning, upprepningar, omvand, fordrojning)
		return { _typ = "TweenInfo", Time = tid, EasingStyle = stil,
			EasingDirection = riktning, RepeatCount = upprepningar or 0,
			Reverses = omvand or false, DelayTime = fordrojning or 0 }
	end,
}

local __services = {
	ReplicatedStorage = nil,   -- sätts efter att __Core byggts
	Workspace = workspace,     -- kameran hämtar den som tjänst
	RunService = {
		Heartbeat = __signal(),
		RenderStepped = __signal(),
		--[[ `_server` lades till för S2b: GameplayService är serverkod och
		     Networking väljer väg på IsServer. Standard är oförändrad (klient),
		     så alla äldre specar mäter exakt samma sak som förut. ]]
		_server = false,
		IsClient = function(self) return not self._server end,
		IsServer = function(self) return self._server == true end,
		--[[ SparService binder sin sista skrivning till `BindToClose` bara
		     utanför Studio. Bänken säger `false` — alltså "riktig server" —
		     så att den vägen faktiskt registreras och går att prova. ]]
		IsStudio = function() return false end,
	},
	Players = {
		LocalPlayer = {
			Name = "Spelare", UserId = 1,
			--[[ Karaktären svarar som en riktig Model gör innan den fått sin
			     Humanoid: RiderController ska då hoppa över IK:n i stället
			     för att krascha. Det är produktionens egen respawn-väg. ]]
			Character = { Name = "Spelare",
				FindFirstChild = function() return nil end,
				FindFirstChildOfClass = function() return nil end },
			FindFirstChild = function() return nil end,
			--[[ `FindFirstChildOfClass("PlayerGui")` svarade NIL, och det gjorde
			     att en hel produktionsväg aldrig kunde köras i bänken:
			     `PreparationController.pekreglagensKanter` frågar just så efter
			     spelarens GUI för att hitta Robloxs egen spak, och fick alltid
			     nej. Varje mätning som kallade sig "iPad landskap" körde alltså
			     SKRIVBORDSGRENEN — koden som håller panelen borta från
			     rörelsereglagen var omätt (#185).

			     Svaret är samma mapp `WaitForChild` bygger, inte en andra. Den
			     är tom tills ett prov lägger något i `_barn`, så alla äldre
			     specar får fortfarande noll pekreglage och exakt samma
			     layout som förut. ]]
			FindFirstChildOfClass = function(self, klassnamn)
				if klassnamn == "PlayerGui" then return rawget(self, "_gui") end
				return nil
			end,
			--[[ HUD:en parentas hit. Utan den gick PreparationController inte
			     att köra alls i bänken. ]]
			WaitForChild = function(self, namn)
				self._gui = self._gui or { Name = namn, _barn = {},
					--[[ Rekursivt som riktiga instanser: pekreglagen sitter
					     under `TouchGui`, inte direkt under `PlayerGui`. ]]
					FindFirstChild = function(self2, sokt, rekursivt)
						for _, b in ipairs(self2._barn) do
							if b.Name == sokt then return b end
						end
						if rekursivt then
							for _, b in ipairs(self2._barn) do
								local traff = b.FindFirstChild and b:FindFirstChild(sokt, true)
								if traff then return traff end
							end
						end
						return nil
					end }
				return self._gui
			end,
			--[[ Karaktären kan försvinna mitt i en ritt. Klienten sitter av
			     på den signalen, och det är också där lärarytan släcks. ]]
			CharacterRemoving = __signal(),
		},
		_spelare = {},
		GetPlayers = function(self) return self._spelare end,
		--[[ `GetPlayerFromCharacter` SAKNADES, och avsittningen kraschade
		     darfor mitt i `integration.spec` — med noll FEL-rader, sa det
		     laste som nagot annat an ett hal i banken (#169 P1).
		     `HorseService` anvander den i stadningen efter en ritt.
		     Slar upp i samma register som `GetPlayers`, sa provet mater
		     de spelare specen faktiskt byggt och inte en egen sanning. ]]
		GetPlayerFromCharacter = function(self, karaktar)
			if karaktar == nil then return nil end
			for _, p in ipairs(self._spelare) do
				if p.Character == karaktar then return p end
			end
			if self.LocalPlayer and self.LocalPlayer.Character == karaktar then
				return self.LocalPlayer
			end
			return nil
		end,
		--[[ Trådväxlande med flit — se __signalTradar. `PlayerRemoving` är
		     en vanlig signal: där finns inget yield-fönster att modellera. ]]
		PlayerAdded = __signalTradar(),
		PlayerRemoving = __signal(),
	},
	--[[ Spaken sätts av testet när gamepad ska mätas. TouchEnabled är falskt:
	     bänken mäter kontraktet, inte gesterna — GUI:t byggs bara i Studio. ]]
	UserInputService = {
		_pad = {},
		GetGamepadState = function(self) return self._pad end,
		--[[ Bänkens standard är en skrivbordsklient: tangentbord finns,
		     pekskärm och gamepad inte. Provet växlar dem för att mäta att
		     tangentledtexten följer inmatningen och inte plattformen. ]]
		TouchEnabled = false,
		KeyboardEnabled = true,
		GamepadEnabled = false,
		InputBegan = __signal(),
		--[[ #220: `InputChanged` och `InputEnded` slangde forut sin callback.
		     TouchControls lyssnar pa dem GLOBALT — ett finger som dras utanfor
		     spaken eller blickytan ska fortfarande folja — sa utan riktiga
		     signaler gick varken spakens eller blickens rorelse att driva.
		     Ingen stub fyrar dem sjalv; det gor bara det prov som vill. ]]
		InputChanged = __signal(),
		InputEnded = __signal(),
	},
	--[[ GuiService: G02-D:s ridanalys laser ReducedMotionEnabled for att
	     starta pausad i stallet for att satta igang en markor som ror sig av
	     sig sjalv. Standard ar falskt (vanlig klient); provet satter den
	     sant for att mata att panelen da INTE startar av sig sjalv. ]]
	GuiService = {
		ReducedMotionEnabled = false,
		--[[ Topbaren tar 36 px överst pa en riktig klient. Talet stod inte
		     har forut, och da matte HUD-grinden inset noll — alltsa ett
		     hornet som ar tommare an spelarens. ]]
		GetGuiInset = function()
			return Vector2.new(0, 36), Vector2.new(0, 0)
		end,
	},
	--[[ CAS-stubben bar forut bara handlaren. Efter arkitekturbeslutet
	     2026-09-17 ar tjansten sjalva reglaget: `createTouchButton`
	     avgor OM en pekknapp finns, `SetTitle`/`SetPosition` VAR och VAD
	     den sager, och `GetButton` ar enda vagen at storlek och
	     genomskinlighet. En stubb som slanger bort allt utom handlaren
	     kan inte mata nagot av det — och da gar kontraktets fyra grindar
	     inte att prova alls.

	     `_knapp` skapas BARA nar `createTouchButton` ar sant, precis som
	     i Roblox. Det ar den detaljen som gor "ritas knappen?" till en
	     riktig matning i stallet for ett antagande. ]]
	ContextActionService = {
		_bound = {},
		_knappar = {},
		_titel = {},
		_plats = {},
		BindAction = function(self, namn, fn, pekknapp, ...)
			self._bound[namn] = fn
			self._knappar[namn] = nil
			if pekknapp then
				--[[ Knappen far en RIKTIG foralder, som i Roblox: CAS lagger
				     sina pekknappar i en egen `ContextActionGui` under
				     PlayerGui. Utan foraldern gick vakten mot `ModalEnabled`
				     i `TouchControls` inte att mata — den letar uppat efter
				     ytan och hade alltid hittat nil. ]]
				local Pl = game:GetService("Players")
				local spelare = Pl and rawget(Pl, "LocalPlayer")
				local mapp = spelare and spelare:FindFirstChildOfClass("PlayerGui")
				local yta = mapp and mapp:FindFirstChild("ContextActionGui")
				if mapp and not yta then
					yta = Instance.new("ScreenGui")
					yta.Name = "ContextActionGui"
					yta.Parent = mapp
				end
				local b = Instance.new("ImageButton")
				b.Name = "ContextActionButton"
				rawset(b, "_cas", namn)
				b.Parent = yta
				self._knappar[namn] = b
			end
			self._bound[namn .. "@tangenter"] = { ... }
		end,
		UnbindAction = function(self, namn)
			self._bound[namn] = nil
			self._bound[namn .. "@tangenter"] = nil
			self._knappar[namn] = nil
			self._titel[namn] = nil
			self._plats[namn] = nil
		end,
		SetTitle = function(self, namn, titel) self._titel[namn] = titel end,
		SetPosition = function(self, namn, plats) self._plats[namn] = plats end,
		GetButton = function(self, namn) return self._knappar[namn] end,
	},
	--[[ ══ TWEENSERVICE SOM GAR ATT MATA (#244) ═════════════════════════
	     Stubben svarade forr med `{ Play = function() end }`, alltsa ett
	     objekt utan minne. Da gick det att prova ATT nagot tonades, men
	     inte MED VILKEN tid, easing eller malvarde — och kontraktet for
	     CoachBanner anger just 0,4 s och Quad.

	     Varje skapad tween laggs nu i `__tweens` med sitt objekt, sin
	     TweenInfo och sina malvarden, och den bar ett `Cancel` som markerar
	     den avbruten. Det ar vad provet behover for att kunna visa att ett
	     nytt `Show` FAKTISKT avbryter den gamla uttoningen. ]]
	TweenService = {
		Create = function(_, objekt, info, mal)
			local t
			t = {
				Instance = objekt, TweenInfo = info, _mal = mal,
				_spelad = false, _avbruten = false,
				Play = function(sjalv) (sjalv or t)._spelad = true end,
				Cancel = function(sjalv) (sjalv or t)._avbruten = true end,
			}
			table.insert(__tweens, t)
			return t
		end,
	},
	Debris = { AddItem = function() end },
	--[[ Taggregistret var förut tomt och osättbart, och då gick ingen
	     bindningsregel att prova: `GetTagged` svarade alltid {} och varje
	     "hittade ingen modell"-gren blev grön av fel skäl. `__taggade`
	     fylls av provet. ]]
	--[[ Taggsignalerna FYRAR nu. Förut svarade `GetInstanceAddedSignal` med
	     en tom Connect, och då gick produktionens egen väg för en rigg som
	     dyker upp SENARE inte att köra i bänken: varken `HorseService`
	     registrering eller `GameplayService` ombindning ("waiting_model ska
	     läka av sig själv") kunde mätas. En spec fick i stället gå in genom
	     provkroken `_registerForProv`, vilket bevisar att `register` gör sitt
	     — inte att någon någonsin anropar den.

	     Signalerna är per tagg, precis som i Roblox, och `AddTag`/`RemoveTag`
	     fyrar dem. `nollstall` finns av samma skäl som på PlayerAdded:
	     lyssnarna ackumuleras annars mellan provblock. ]]
	CollectionService = {
		_taggade = {},
		_lagg = {},
		_ta = {},
		GetTagged = function(self, tagg) return self._taggade[tagg] or {} end,
		HasTag = function(self, inst, tagg)
			for _, i in ipairs(self._taggade[tagg] or {}) do
				if i == inst then return true end
			end
			return false
		end,
		AddTag = function(self, inst, tagg)
			if self:HasTag(inst, tagg) then return end
			self._taggade[tagg] = self._taggade[tagg] or {}
			table.insert(self._taggade[tagg], inst)
			if self._lagg[tagg] then self._lagg[tagg]:Fire(inst) end
		end,
		RemoveTag = function(self, inst, tagg)
			for i, x in ipairs(self._taggade[tagg] or {}) do
				if x == inst then table.remove(self._taggade[tagg], i) break end
			end
			if self._ta[tagg] then self._ta[tagg]:Fire(inst) end
		end,
		GetInstanceAddedSignal = function(self, tagg)
			self._lagg[tagg] = self._lagg[tagg] or __signal()
			return self._lagg[tagg]
		end,
		GetInstanceRemovedSignal = function(self, tagg)
			self._ta[tagg] = self._ta[tagg] or __signal()
			return self._ta[tagg]
		end,
		--[[ Nollställer taggar OCH lyssnare mellan provblock. ]]
		nollstall = function(self)
			self._taggade, self._lagg, self._ta = {}, {}, {}
		end,
	},
}

--[[ __Core fylls på av byggskriptet efterhand som modulerna laddas, så att
     en modul kan nå de som står över den i beroendeordningen. ]]
__Core = {
	RigAdapter = {
		setBodyTilt = function() end,
		setRiderLean = function() end,
		resolve = function() return nil end,
		playAnimation = function() end,
		stopAnimation = function() end,
	},
}

--[[ ReplicatedStorage returnerade förut en NY tabell vid varje anrop. Det
     dög så länge bara `.HorseCore` lästes, men attribut skrivna av en modul
     försvann då ur nästa modul — och `G01Enabled` hade sett osatt ut oavsett
     vad servern gjorde. En stabil tabell, med attribut. ]]
local __rs = { HorseCore = __Core, _attr = {}, _barn = {} }
function __rs:GetAttribute(k) return self._attr[k] end
function __rs:SetAttribute(k, v) self._attr[k] = v end
function __rs:FindFirstChild(namn)
	local direkt = rawget(self, namn)
	if direkt then return direkt end
	for _, b in ipairs(self._barn) do if b.Name == namn then return b end end
	return nil
end
--[[ I produktionen SKAPAR servern fjärrmappen och dess objekt, och klienten
     väntar in dem. Bänken har ingen server, så den står in för den: ett
     efterfrågat barn som inte finns skapas här i stället för att klienten
     ska fastna i en väntan som aldrig löses ut.

     Det gäller bara uppslag klienten gör på vägen till ett fjärrobjekt.
     Ett prov som vill mäta att något SAKNAS ska använda FindFirstChild,
     som fortsatt svarar nil. ]]
function __rs:WaitForChild(namn)
	local fanns = self:FindFirstChild(namn)
	if fanns then return fanns end
	local ny = Instance.new(if namn == "HorseRemotes" then "Folder" else "RemoteEvent")
	ny.Name = namn
	ny.Parent = self
	--[[ Mappen måste kunna skapa sina egna barn på samma sätt; annars
	     stannar kedjan ett steg ner. ]]
	if ny.ClassName == "Folder" then
		function ny:WaitForChild(barnnamn)
			local b = self:FindFirstChild(barnnamn)
			if b then return b end
			local e = Instance.new("RemoteEvent")
			e.Name = barnnamn
			e.Parent = self
			return e
		end
	end
	return ny
end

--[[ ── DATALAGRET (#161) ───────────────────────────────────────────

     En stub som beter sig som `DataStoreService` i de tre avseenden
     `SparService` bryr sig om: `GetAsync` returnerar det som skrivits,
     `UpdateAsync` kör transformatorn på det lagrade värdet och skriver
     tillbaka, och BÅDA kan fås att KASTA.

     Felläget är hela poängen. Ett persistenslager vars felväg aldrig
     provats är ett persistenslager vars felväg inte finns — och #161
     kräver uttryckligen att ett DataStore-fel varken kraschar eller ger
     gratis progression. `__datastore.felLas` / `.felSkriv` sätts av
     provet, och `.forsok` räknar hur många gånger lagret faktiskt
     anropades, så retryn går att mäta i stället för att antas.

     `_data` är avsiktligt en vanlig tabell utan djupkopiering: det speglar
     att Roblox serialiserar, inte att den delar referenser — och provet
     som bryr sig om det (sammanslagningen) skriver därför alltid genom
     `UpdateAsync`, precis som produktionen. ]]
__datastore = {
	_data = {},
	felLas = false,
	felSkriv = false,
	--[[ Sant = `GetDataStore` självt kastar, alltså Studio utan
	     API-åtkomst. Då ska spelet gå att spela ändå. ]]
	felButik = false,
	--[[ Sant = `GetAsync` YIELDAR en gång innan den svarar, alltså gör det
	     nätverksanropet en riktig `GetAsync` gör. Det är den enda knappen
	     som gör blockerare 1 mätbar: utan den returnerar läsningen direkt
	     och fönstret där en annan `PlayerAdded`-lyssnare ser en halvladdad
	     save existerar inte i bänken. ]]
	fordrojLas = false,
	forsok = { las = 0, skriv = 0 },
}

function __datastore.nollstall()
	__datastore._data = {}
	__datastore.felLas = false
	__datastore.felSkriv = false
	__datastore.felButik = false
	__datastore.fordrojLas = false
	__datastore.forsok = { las = 0, skriv = 0 }
end

local __butik = {}
function __butik:GetAsync(nyckel)
	__datastore.forsok.las += 1
	--[[ Yielda FÖRE felkontrollen: en läsning som ska fela gör också sin
	     nätverkstur först, och felvägen ska mätas med samma fönster öppet. ]]
	if __datastore.fordrojLas and coroutine.isyieldable() then
		coroutine.yield()
	end
	if __datastore.felLas then error("DataStore: läsning misslyckades (stub)") end
	return __datastore._data[nyckel]
end
function __butik:SetAsync(nyckel, varde)
	__datastore.forsok.skriv += 1
	if __datastore.felSkriv then error("DataStore: skrivning misslyckades (stub)") end
	__datastore._data[nyckel] = varde
	return varde
end
function __butik:UpdateAsync(nyckel, fn)
	__datastore.forsok.skriv += 1
	if __datastore.felSkriv then error("DataStore: skrivning misslyckades (stub)") end
	local nytt = fn(__datastore._data[nyckel])
	--[[ NIL UR TRANSFORMATORN AVBRYTER SKRIVNINGEN och lämnar det lagrade
	     värdet ORÖRT. Så gör Roblox, och stubben gjorde det inte: den skrev
	     `_data[nyckel] = nil`, alltså RADERADE raden.
	     Skillnaden är hela fynd 2 i omreviewen av caac3f5 — provet som ska
	     visa att en framtida sparfil bevaras kunde inte skilja "bevarad"
	     från "raderad" så länge stubben tog bort den. ]]
	if nytt == nil then
		return __datastore._data[nyckel]
	end
	__datastore._data[nyckel] = nytt
	return nytt
end

__services.DataStoreService = {
	GetDataStore = function(_, _namn)
		if __datastore.felButik then error("DataStore: ingen API-åtkomst (stub)") end
		return __butik
	end,
}

--[[ PathfindingService: LedService använder den som lokal reserv när
     hästen sitter fast. Stubben RÄKNAR INTE ut någon väg — den speglar
     ANROPET, så en spec kan mäta att agenten måttsätts ur hästens eget
     hölje och inte ur Roblox standardvärden. `Status` är avsiktligt
     `NoPath`: bänken har ingen navmesh, och en spec ska inte kunna tro
     att den mätt en riktig väg. ]]
__senastePathParams = nil
--[[ MALEN registreras ocksa (#182). Ratelsen i `planera` provar ett
     RESERVMAL nar det valda malet inte bar, och det gar bara att mata om
     stubben minns VILKA punkter som begardes — inte bara att nagon
     begarde en vag. `__pathSvar` later en spec bestamma utfallet per mal
     och darmed spela upp exakt den situation som fangades i Studio. ]]
__pathMal = {}
__pathSvar = nil
local __pathfinding = {
	CreatePath = function(_, params)
		__senastePathParams = params
		local denna = { Status = Enum.PathStatus.NoPath, vagpunkter = {} }
		denna.ComputeAsync = function(_, start, till)
			table.insert(__pathMal, till)
			if __pathSvar then
				local svar = __pathSvar(start, till)
				if svar then
					denna.Status = Enum.PathStatus.Success
					denna.vagpunkter = svar
				end
			end
		end
		denna.GetWaypoints = function()
			local ut = {}
			for _, p in ipairs(denna.vagpunkter) do
				table.insert(ut, { Position = p })
			end
			return ut
		end
		return denna
	end,
}

game = {
	GetService = function(_, name)
		if name == "ReplicatedStorage" then return __rs end
		if name == "PathfindingService" then return __pathfinding end
		return assert(__services[name], "ingen stub för tjänsten " .. name)
	end,
	Players = __services.Players,
	--[[ `BindToClose` sparar sin callback så att provet kan fyra den —
	     serverns sista skrivning är en av de vägar ett pass kan gå
	     förlorat, och den ska gå att mäta. ]]
	BindToClose = function(_, fn) __senasteBindToClose = fn end,
}
__ReplicatedStorage = __rs
script = { Parent = __Core }

--[[ En riggstub: det MovementController rör och inget mer. ]]
function __makeRig()
	local hum = {
		WalkSpeed = 0, Jump = false, AutoRotate = true,
		_moves = {}, _state = Enum.HumanoidStateType.Running,
	}
	function hum:Move(dir) table.insert(self._moves, dir) end
	function hum:GetState() return self._state end
	function hum:ChangeState() end
	local root = {
		CFrame = cframe(vec(0, 3, 0), vec(0, 0, 1)),
		Position = vec(0, 3, 0),
		AssemblyLinearVelocity = vec(),
	}
	return { model = { Name = "Horse" }, root = root, humanoid = hum,
		bones = {}, attachments = {}, animator = nil }
end

--[[ En hästmodell av riktiga (stubbade) instanser. `__makeRig` lämnar en
     färdig Rig, vilket duger för rörelsemodulerna — men klientens `mount`
     går genom RigAdapter.build, och den kräver en Model med rot och
     Humanoid. Utan den här gick klientens egen uppsittning inte att köra
     i bänken. ]]
function __makeHastModell(namn)
	local m = Instance.new("Model")
	m.Name = namn or "Bamse"
	m:SetAttribute("HorseId", "bamse")
	local rot = Instance.new("Part")
	rot.Name = "HumanoidRootPart"
	rot.Size = vec(2, 2, 4)
	rot.CFrame = cframe(vec(0, 3, 0), vec(0, 0, 1))
	rot.Position = vec(0, 3, 0)
	rot.AssemblyLinearVelocity = vec()
	rot.Parent = m
	local hum = Instance.new("Humanoid")
	hum.Name = "Humanoid"
	hum.WalkSpeed = 0
	function hum:Move() end
	function hum:GetState() return Enum.HumanoidStateType.Running end
	function hum:ChangeState() end
	hum.Parent = m
	local anim = Instance.new("Animator")
	anim.Name = "Animator"
	anim.Parent = hum
	return m
end

--[[ `Instance.new` fanns inte här alls, bara i bygg-stubbarna. Den behövs
     för att `AnimationController:_load` skapar `Animation`-objekt. Minimal
     med flit: bara namn, klass och id, alltså precis det modulen rör. ]]
--[[ `Instance.new` gav förut bara { ClassName, Name, AnimationId }. Det räckte
     för AnimationController, men inte för att köra serverkod eller bygga en
     HUD: utan Parent, barn och signaler gick varken `Networking.folder()`
     eller `PreparationController` att prova, och då kunde produktionens
     UPPKOPPLING vara trasig medan varje regel var grön. Senior review runda 2
     fällde exakt det.

     Mocken är avsiktligt trubbig men inte magisk: den svarar bara på det
     riktiga instanser faktiskt gör här — sätta egenskaper, sätta Parent,
     hitta barn, kopplas ur, och (för knappar) ett Activated att ansluta. ]]
__signal_ny = __signal

--[[ Workspace-signalerna kopplas HAR och inte i tabellen pa rad 304:
     `workspace` definieras fore `__signal`, sa ett anrop daruppe ger
     nil och hela bankan dog pa "attempt to call a nil value" —
     tystare an det ursprungliga felet och i en helt annan fil. ]]
workspace.ChildAdded = __signal()
workspace.ChildRemoved = __signal()

--[[ ── BEVAKADE EGENSKAPER ─────────────────────────────────────────────
     Egenskaper som koden både SKRIVER och LYSSNAR på. De ligger i en
     skuggtabell (`_p`) i stället för direkt i instansen, och skälet är en
     Lua-detalj som annars gör hela mätningen tyst fel: `__newindex` fyrar
     bara när nyckeln SAKNAS i tabellen. En `rawset` vid första skrivningen
     gör alltså andra skrivningen osynlig — och då hade `Occupant`-signalen
     fyrat en gång och sedan tigit, vilket är precis det HorseService
     förlitar sig på för att städa efter en avsittning.

     Med skuggtabellen går VARJE skrivning genom `__newindex` och varje
     läsning genom `__index`, så länge namnet aldrig rawsettas. ]]
local __BEVAKADE = {
	Occupant = true, Sit = true, Health = true, SeatPart = true,
	PlatformStand = true,
	--[[ Prompttexten bevakas sedan #162:s lokaliseringsfynd. `Prompttext`
	     havdar oversattningen igen om nagon skriver over den, och utan en
	     signal har kunde bankan inte se vare sig overskrivningen eller
	     rattelsen. ]]
	ActionText = true, ObjectText = true,
}

local function __nyInstans(klass)
	local inst = {
		ClassName = klass, Name = "", AnimationId = "",
		--[[ #246 C: Roblox `ProximityPrompt.Style` ar `Default` fran borjan,
		     inte nil. Stubben lamnade den ostatt, och da gick skillnaden
		     mellan "orord" och "slackt" inte att mata. ]]
		Style = if klass == "ProximityPrompt"
			then Enum.ProximityPromptStyle.Default else nil,
		--[[ `AbsoluteSize` SAKNADES, och det fällde `ugneta.spec` (#180).

		     `UgnetaController.visaKort` räknar hur mycket fritt utrymme
		     kortet har:

		         local W = foralder and foralder.AbsoluteSize.X or 0

		     Vakten prövar `foralder` men inte egenskapen. På en riktig
		     GuiObject BEHÖVER den inte prövas — `AbsoluteSize` finns
		     alltid — så produktionen är oberörd. Stubben saknade den, och
		     provet dog på `attempt to index nil with 'X'`.

		     Noll är rätt utgångsvärde: en GUI-instans som aldrig lagts in
		     i en ritad hierarki har ingen uppmätt storlek, och koden har
		     redan en `if W > 0`-gren för just det fallet. Ett påhittat
		     mått här hade fått provet att mäta stubbens tal i stället för
		     modulens beslut. ]]
		AbsoluteSize = vec(0, 0, 0),
		AbsolutePosition = vec(0, 0, 0),
		_barn = {}, _attr = {}, _p = {}, _sig = {}, _asig = {}, Parent = nil,
	}
	--[[ `GetPropertyChangedSignal` finns på varje instans i Roblox. Den
	     fyrar när egenskapen ÄNDRAS — inte vid varje skrivning av samma
	     värde — och det är den skillnaden `dismount` bygger på. ]]
	function inst:GetPropertyChangedSignal(egenskap)
		self._sig[egenskap] = self._sig[egenskap] or __signal()
		return self._sig[egenskap]
	end
	function inst:GetAttribute(k) return self._attr[k] end
	--[[ ATTRIBUTSIGNALEN, som saknades helt.

	     `Prompttext` ar byggd kring den: servern satter en NYCKEL, klienten
	     skriver texten nar nyckeln andras. Utan signalen har kunde modulen
	     aldrig kora i bankan, och darfor kunde tretton dorrar sta pa svenska
	     for en engelsk spelare med hela sviten gron.

	     Samma semantik som Roblox: den fyrar nar vardet ANDRAS. ]]
	function inst:GetAttributeChangedSignal(k)
		self._asig[k] = self._asig[k] or __signal()
		return self._asig[k]
	end
	function inst:SetAttribute(k, v)
		local gammal = self._attr[k]
		self._attr[k] = v
		local sig = self._asig[k]
		if sig and gammal ~= v then sig:Fire() end
	end
	--[[ `FindFirstChild(namn, rekursivt)` — andra argumentet fanns inte, och
	     det spelade roll: `RigAdapter.findByName` söker REKURSIVT, och
	     riggens leder sitter under kroppsdelen. Utan rekursionen svarade
	     stubben nil, adaptern lämnade `riderJoint` tom och ryttarlutningen
	     hoppades tyst över — en degradering som inte gick att skilja från
	     en rigg som saknade leden. ]]
	function inst:FindFirstChild(namn, rekursivt)
		for _, b in ipairs(self._barn) do if b.Name == namn then return b end end
		if rekursivt then
			for _, b in ipairs(self._barn) do
				local traff = b.FindFirstChild and b:FindFirstChild(namn, true)
				if traff then return traff end
			end
		end
		return nil
	end
	--[[ Efter senior re-review av #87 går ett prov genom den RIKTIGA
	     HorseService.register, och RigAdapter letar Humanoid och Animator
	     med klass i stället för namn. Sökningen är samma linjära svep som
	     FindFirstChild, mot IsA — ingen arvshierarki uppfinns här. ]]
	function inst:FindFirstChildOfClass(klassnamn)
		for _, b in ipairs(self._barn) do
			if b.ClassName == klassnamn or (b.IsA and b:IsA(klassnamn)) then return b end
		end
		return nil
	end
	--[[ `IsA` svarar bara på den egna klassen och de få basklasser koden
	     faktiskt frågar efter. Ingen full arvshierarki: en mock som svarar
	     ja på allt hade gjort varje IsA-grind meningslös. ]]
	--[[ `FindFirstAncestorWhichIsA` saknades. `TouchControls` anvander den
	     for att kontrollera att `ContextActionService` egen yta ar tand
	     innan den lamnar over kontrollen — se vakten mot `ModalEnabled`
	     dar. Utan metoden i stubben kraschade klientbanken i stallet for
	     att mata vakten. ]]
	function inst:FindFirstAncestorWhichIsA(klassnamn)
		local f = self.Parent
		while f do
			if f.IsA and f:IsA(klassnamn) then return f end
			f = f.Parent
		end
		return nil
	end
	function inst:IsA(klassnamn)
		if klassnamn == self.ClassName then return true end
		if klassnamn == "BasePart" then
			return self.ClassName == "Part" or self.ClassName == "Seat"
				or self.ClassName == "MeshPart"
		end
		if klassnamn == "GuiObject" then
			return self.ClassName == "Frame" or self.ClassName == "TextLabel"
				or self.ClassName == "TextButton"
		end
		--[[ `LuaSourceContainer` ar basklassen for allt som bar kallkod.
		     `Integritet.kallantal` RAKNAR den over de Rojo-agda traden for att
		     kunna svara pa om identiteten beskriver placens EGEN kod (#171).
		     Den raknar just instanser, inte tecken, darfor att ett spelskript
		     inte far lasa `Source`. Utan arvet svarade banken 0 kallor, och
		     provet matte stubben i stallet for grinden. ]]
		if klassnamn == "LuaSourceContainer" then
			return self.ClassName == "ModuleScript" or self.ClassName == "Script"
				or self.ClassName == "LocalScript"
		end
		return false
	end
	--[[ Riktiga instanser kan räkna upp sina barn. Det behövdes när
	     klientbänken började bygga en häst av instanser: RigAdapter letar
	     rot, attachments och ben genom GetDescendants. ]]
	--[[ Klientloopen sitter av om riggen inte längre står i världen. Utan
	     den här kunde den vägen aldrig köras i bänken. ]]
	function inst:IsDescendantOf(mojligForfader)
		local f = rawget(self, "Parent")
		while f do
			if f == mojligForfader then return true end
			f = rawget(f, "Parent") or (type(f) == "table" and f.Parent) or nil
		end
		return false
	end
	function inst:GetChildren()
		local ut = {}
		for _, b in ipairs(self._barn) do table.insert(ut, b) end
		return ut
	end
	function inst:GetDescendants()
		local ut = {}
		local function ner(nod)
			for _, b in ipairs(nod._barn or {}) do
				table.insert(ut, b); ner(b)
			end
		end
		ner(self)
		return ut
	end
	function inst:Destroy()
		local far = rawget(self, "Parent")
		if far and far._barn then
			for i, b in ipairs(far._barn) do
				if b == self then table.remove(far._barn, i) break end
			end
		end
	end
	if klass == "TextButton" then
		inst.Activated = __signal()
		--[[ `MouseButton1Click` — gangartsknapparna i `TouchControls`
		     kopplar den, inte `Activated`. Utan den gick monteringen inte
		     att kora i banken (#208). ]]
		inst.MouseButton1Click = __signal()
		inst.MouseButton1Down = __signal()
		inst.MouseButton1Up = __signal()
		--[[ `MouseLeave` slapper tygeln och sitsen nar fingret glider av
		     knappen; `TouchControls` kopplar den pa bada. ]]
		inst.MouseLeave = __signal()
		inst.MouseEnter = __signal()
	end
	--[[ `GuiObject.InputBegan` — samma skäl som `Activated` ovan.

	     `TouchControls.mount` kopplar spaken och blickytan med
	     `bas.InputBegan` respektive `yta.InputBegan`. Utan signalen gick
	     hela monteringen inte att köra i den här banken, och därmed gick
	     reglagens LAYOUT inte att mäta — vilket är precis vad #208
	     behöver kunna göra. ]]
	if klass == "Frame" or klass == "TextButton" or klass == "TextLabel"
		or klass == "ScrollingFrame" or klass == "ImageLabel" then
		inst.InputBegan = __signal()
		inst.InputChanged = __signal()
		inst.InputEnded = __signal()
	end
	--[[ `ProximityPrompt.Triggered` — samma skäl som Activated ovan.
	     Utan den gick `DorrService.start()` inte att köra i den här
	     banken, och därmed gick promptens TEXT inte att mäta. En grind
	     som inte kan köra tjänsten kan inte se vad spelaren läser. ]]
	--[[ `Attachment.WorldPosition` ar fastpunktens lage i VARLDEN, alltso
	     vardelens lage plus fastpunktens egen forskjutning. Uppsittningens
	     prompt hanger i sadelpunkten, och utan det har ar den osynlig for
	     allt som letar prompter pa avstand (`Naromrade`, #235). ]]
	if klass == "Attachment" then
		inst.Position = Vector3.new(0, 0, 0)
	end
	if klass == "ProximityPrompt" then
		inst.Triggered = __signal()
		--[[ `Enabled` och `ClickablePrompt` ar TRUE som standard i Roblox.
		     Stubben satte dem inte alls, och da laste varje prov `nil` —
		     falskt. Produktionskod som filtrerar pa `p.Enabled`
		     (`Naromrade`, #235) sallade darfor bort precis allt i banken
		     medan den fungerade i spelet. En stubb som avviker fran API:et
		     gor proven till matningar av stubben.
		     Varden satts som VANLIGA falt och inte i `_p`: skuggtabellen
		     lases bara tillbaka for nycklar i `__BEVAKADE`, sa ett varde
		     dar hade varit osynligt — vilket var precis vad forsta
		     rattelsen rakade gora. ]]
		inst.Enabled = true
		inst.ClickablePrompt = true
		--[[ `InputHoldBegin`/`InputHoldEnd` ar spelarens EGEN vag in i en
		     prompt: tangenten, handkontrollknappen och fingret gar alla
		     genom dem, och `Triggered` fyrar nar hallet natt
		     `HoldDuration`. `Naromrade` (#235) trycker samma vag for att
		     inte bygga en parallell gameplayvag — utan de har metoderna
		     gick just den vagen inte att mata.
		     Ett hall som slapps for tidigt fyrar INTE, precis som i
		     Roblox: det ar skillnaden mellan ett tryck och en angrad
		     beroring. ]]
		function inst:InputHoldBegin()
			rawset(self, "_hallSedan", os.clock())
		end
		function inst:InputHoldEnd()
			local start = rawget(self, "_hallSedan")
			rawset(self, "_hallSedan", nil)
			if start == nil then return end
			local hold = self.HoldDuration or 0
			if hold > 0 and (os.clock() - start) < hold then return end
			self.Triggered:Fire()
		end
		--[[ Texterna satts i SKUGGTABELLEN, inte som rakt falt. Lua kallar
		     `__newindex` bara nar nyckeln SAKNAS i tabellen: ett rawset har
		     hade gjort varje senare skrivning osynlig for
		     `GetPropertyChangedSignal`, och da kunde `Prompttext`
		     inte hora nar nagon skriver over oversattningen. Felet var
		     tyst: proven las ratt varde och missade bara signalen. ]]
		inst._p.ObjectText, inst._p.ActionText = "", ""
	end
	--[[ ── SITSEN ────────────────────────────────────────────────────────
	     `Seat:Sit(humanoid)` gör tre saker i Roblox: den skapar en `Weld`
	     som heter SeatWeld under sitsen, sätter `Occupant`, och sätter
	     humanoidens `Sit` och `SeatPart`. Ingen av dem fanns i bänken, och
	     därför har hela uppsittningskedjan varit omätbar här: specarna fick
	     stubba en egen sits, och en sådan stubb blir per definition byggd
	     efter koden i stället för efter API:et. ]]
	if klass == "Seat" or klass == "VehicleSeat" then
		function inst:Sit(hum)
			if hum == nil then
				--[[ `Seat:Sit(nil)` är INTE en dokumenterad väg att resa
				     någon. Den kastar här, precis som den skulle göra i
				     Studio, så att en kodväg som försöker det faller. ]]
				error("Seat:Sit förväntar sig en Humanoid, inte nil", 2)
			end
			if self.Occupant == hum then return end
			local weld = __nyInstans("Weld")
			weld.Name = "SeatWeld"
			weld.Part0 = self
			weld.Parent = self
			hum.SeatPart = self
			hum.Sit = true
			self.Occupant = hum
		end
	end
	--[[ En led har C0 och C1, och de är CFrame.identity från början — inte
	     nil. `RigAdapter.setRiderLean` läser `joint.C0` och multiplicerar
	     den; en led utan C0 hade fällt raden på aritmetik i stället för att
	     mäta lutningen. ]]
	if klass == "Motor6D" or klass == "Weld" or klass == "Motor" then
		inst.C0 = CFrame.new(0, 0, 0)
		inst.C1 = CFrame.new(0, 0, 0)
	end
	if klass == "Humanoid" then
		inst.Died = __signal()
		inst.Health = 100
		inst.Sit = false
		--[[ `HipHeight` finns pa VARJE Humanoid i Roblox och kan aldrig vara
		     nil. Stubben saknade den, och avsittningens platsrakning -- som
		     lagger HipHeight till markhojden -- kastade darfor pa en tom
		     karaktar. En stub som saknar en egenskap produktionen alltid har
		     mater inte produktionen. Standardvardet ar R15:s eget. ]]
		inst.HipHeight = 2
		--[[ `MoveTo`/`Move` finns för att LedService styr hästen med dem.
		     Stubben SPEGLAR bara ordern — ingen fysik, ingen förflyttning —
		     så en spec kan mäta VART tjänsten sa åt hästen att gå. Flyttade
		     stubben delen själv hade specen mätt stubben. ]]
		inst._moveMal = nil
		inst._moveDir = nil
		function inst:MoveTo(p) self._moveMal = p end
		function inst:Move(dir) self._moveDir = dir end
		--[[ `ChangeState` speglas på samma sätt: stubben har ingen fysik,
		     men `HastRigg`s vakt mot att hästen sätter sig på sin egen
		     sits reser henne med den, och utan metoden kunde grinden inte
		     ens köra. Det SENASTE tillståndet sparas så att ett prov kan
		     mäta att hon faktiskt restes. ]]
		inst._tillstand = nil
		function inst:ChangeState(t) self._tillstand = t end
		function inst:GetState() return self._tillstand end
	end
	if klass == "Model" then
		--[[ Modellen flyttas med `PivotTo` av bade uppsittningen och
		     avsittningen. Stubben speglar VART -- ingen fysik.

		     Den flyttar ocksa rotdelen. Forst gjorde den bara `_pivot`, och
		     da matte ett prov pa `HumanoidRootPart.CFrame` ingenting alls:
		     avsittningen kunde stalla ryttaren var som helst utan att en
		     enda matning rorde sig. En riktig `PivotTo` FLYTTAR delarna.
		     Forenklingen ar att bara roten foljer med, inte hela kroppen
		     med sina inbordes avstand; bankens karaktarer har anda bara
		     en del som betyder nagot. ]]
		function inst:PivotTo(cf)
			self._pivot = cf
			local rot = rawget(self, "PrimaryPart") or self:FindFirstChild("HumanoidRootPart")
			if type(rot) == "table" and rawget(rot, "CFrame") ~= nil then
				rot.CFrame = cf
			end
		end
		function inst:GetPivot()
			if self._pivot then return self._pivot end
			local rot = rawget(self, "PrimaryPart") or self:FindFirstChild("HumanoidRootPart")
			if type(rot) == "table" and rawget(rot, "CFrame") ~= nil then
				return rot.CFrame
			end
			return nil
		end
	end
	--[[ `GetFullName` går uppåt tills något inte längre är en instans.
	     Bänkens `workspace` är en vanlig tabell utan Name, och en
	     ovillkorlig klättring stoppade då in nil i listan och KRASCHADE —
	     mitt i ett felmeddelande, vilket är precis när man behöver att den
	     fungerar. ]]
	function inst:GetFullName()
		local led, nod = {}, self
		while type(nod) == "table" do
			local namn = rawget(nod, "Name")
			if type(namn) ~= "string" or namn == "" then namn = rawget(nod, "ClassName") end
			if type(namn) ~= "string" then break end
			table.insert(led, 1, namn)
			nod = rawget(nod, "Parent")
		end
		return table.concat(led, ".")
	end
	function inst:FindFirstChildWhichIsA(klassnamn)
		return self:FindFirstChildOfClass(klassnamn)
	end
	if klass == "RemoteEvent" then
		inst.OnClientEvent = __signal()
		inst.OnServerEvent = __signal()
		inst._skickat = {}
		--[[ FireServer och InvokeServer finns på riktiga fjärrobjekt och
		     används av klienten (avsittning, tillståndssynk). Utan dem
		     kraschar klientens egen väg i bänken. ]]
		function inst:FireServer(...) table.insert(self._skickat, { ... }) end
		function inst:InvokeServer(...) table.insert(self._skickat, { ... }); return true end
		--[[ FireClient LEVERERAR (#182 del 2). Forut bokfordes anropet bara
		     i `_skickat`, och `OnClientEvent` fyrade aldrig. Det gjorde
		     hela server->klient-riktningen omojlig att mata: `LedSync` ar
		     den enda vagen servern har att saga "kopplet slapptes", och en
		     bank dar den signalen inte kommer fram kan inte skilja en
		     tjanst som skickar den fran en som glomt.

		     Bokforingen star kvar — prov som laser `_skickat` fungerar som
		     forut — men nu gar signalen ocksa fram. ]]
		function inst:FireClient(spelare, ...)
			table.insert(self._skickat, { spelare, ... })
			local Pl = game:GetService("Players")
			local mig = Pl and rawget(Pl, "LocalPlayer")
			--[[ Bankan har en klient. Ar mottagaren den — eller vet vi
			     inte vem klienten ar — levereras nyttolasten. ]]
			if mig == nil or spelare == nil or spelare == mig then
				self.OnClientEvent:Fire(...)
			end
		end
		function inst:FireAllClients(...)
			table.insert(self._skickat, { ... })
			self.OnClientEvent:Fire(...)
		end
	end
	if klass == "RemoteFunction" then
		inst.OnServerInvoke = nil
		inst._skickat = {}
		--[[ INVOKESERVER NAR FRAM (#182 del 2). `RemoteFunction` hade ingen
		     `InvokeServer` alls, och `RemoteEvent`s variant svarade `true`
		     utan att nagonsin rora serverns handlare.

		     Integrationsprovet for ledningen far uttryckligen INTE mocka
		     bort `LedBorja`. Da maste bankan faktiskt koppla klientens
		     anrop till `OnServerInvoke` — annars mater provet stubben och
		     sager ingenting om att kedjan haller.

		     Spelaren som forsta argument ar riktig API-form: servern far
		     alltid veta VEM som anropade. Bankan har en klient, och det ar
		     `Players.LocalPlayer`. ]]
		function inst:InvokeServer(...)
			table.insert(self._skickat, { ... })
			local handlare = rawget(self, "OnServerInvoke")
			if type(handlare) ~= "function" then return true end
			local Pl = game:GetService("Players")
			return handlare(Pl and rawget(Pl, "LocalPlayer"), ...)
		end
	end
	--[[ NATVERKSAGARSKAPET.

	     Mätt i Studio: en oriden häst intill en spelare ags AUTOMATISKT av
	     den klienten, och da nar serverns order aldrig fram. `LedService`
	     tar darfor agarskapet medan hon leds och lamnar tillbaka det. Utan
	     de har metoderna kunde banken inte se skillnad pa en tjanst som gor
	     det och en som inte gor det — och det var precis den skillnaden som
	     holl hasten stilla. ]]
	function inst:SetNetworkOwner(agare)
		rawset(self, "_agare", agare)
		rawset(self, "_agareAuto", false)
	end
	function inst:SetNetworkOwnershipAuto()
		rawset(self, "_agare", nil)
		rawset(self, "_agareAuto", true)
	end
	function inst:GetNetworkOwner() return rawget(self, "_agare") end
	function inst:GetNetworkOwnershipAuto()
		local a = rawget(self, "_agareAuto")
		--[[ Roblox startar i automatiskt lage. ]]
		if a == nil then return true end
		return a
	end

	--[[ Parent sätts via metatabell så att barnlistan hålls i takt; koden
	     skriver `x.Parent = y` och förväntar sig att y ser x. ]]
	--[[ De bevakade egenskaperna får sina startvärden genom skuggtabellen,
	     annars rawsettas de av konstruktorn ovan och slutar fyra. ]]
	local __start = { Health = rawget(inst, "Health"), Sit = rawget(inst, "Sit") }
	rawset(inst, "Health", nil); rawset(inst, "Sit", nil)
	for k, v in pairs(__start) do if v ~= nil then inst._p[k] = v end end

	return setmetatable(inst, {
		__index = function(t, k)
			if __BEVAKADE[k] then return rawget(t, "_p")[k] end
			--[[ `Position` är inget eget fält på en riktig BasePart: den
			     läses ur CFrame. Koden som mäter avstånd till en häst
			     (`GameplayService.avstandOk`, `HorseService.tryMount`)
			     läser just `Position`, och en rigg som bara satt sin
			     CFrame gav då nil. Samma härledning som byggstubbarna. ]]
			if k == "WorldPosition" and rawget(t, "ClassName") == "Attachment" then
				local f = rawget(t, "Parent")
				local egen = rawget(t, "Position") or Vector3.new(0, 0, 0)
				if f and f.Position then return f.Position + egen end
				return egen
			end
			if k == "Position" then
				local cf = rawget(t, "CFrame")
				return cf and cf.Position or nil
			end
			--[[ `Attachment.WorldCFrame` är fästpunktens läge i världen:
			     värddelens CFrame gånger punktens egen. Utrustningen byggs
			     mot den — utan den kunde bänken inte se skillnad på ett
			     träns på huvudet och ett träns i origo. ]]
			if k == "WorldCFrame" and rawget(t, "ClassName") == "Attachment" then
				local egen = rawget(t, "CFrame")
				local vard = rawget(t, "Parent")
				local vardCF = vard and rawget(vard, "CFrame")
				if vardCF and egen then return vardCF * egen end
				return egen
			end
			--[[ `Attachment.WorldPosition` ar samma sak, bara punkten.
			     Tillkom nar `TackRigg` borjade SPANNA delar mellan tva
			     riggpunkter — kindstycke, stiglader, tygel — i stallet for
			     att rita lador med gissad langd. ]]
			if k == "WorldPosition" and rawget(t, "ClassName") == "Attachment" then
				local w = t.WorldCFrame
				return w and w.Position or nil
			end
			--[[ En del som aldrig rort sig har nollhastighet, inte nil.
			     `LedService` laser den for att veta om hasten STAR — en
			     stillastaende hast far vrida sig, en gaende inte. ]]
			if k == "AssemblyLinearVelocity" then return vec() end
			return nil
		end,
		__newindex = function(t, k, v)
			if __BEVAKADE[k] then
				local p = rawget(t, "_p")
				local gammal = p[k]
				p[k] = v
				--[[ Semantiken som Roblox själv har, och som städningen
				     efter en ritt hänger på: ]]
				if k == "Sit" and v == false and gammal ~= false then
					--[[ `Humanoid.Sit = false` reser ryttaren: sitsens egen
					     SeatWeld tas bort och `Occupant` släpps. Det är den
					     verifierade vägen ur en sits. ]]
					local sits = p.SeatPart
					p.SeatPart = nil
					if sits then
						local weld = sits:FindFirstChild("SeatWeld")
						if weld then weld:Destroy() end
						if sits.Occupant == t then sits.Occupant = nil end
					end
				elseif k == "Health" and v <= 0 and (gammal == nil or gammal > 0) then
					--[[ Döden reser också ryttaren, och FÖRST därefter fyrar
					     `Died` — annars hade en lyssnare som frågar efter
					     sitsen sett en död ryttare som fortfarande sitter. ]]
					t.Sit = false
					local d = rawget(t, "Died")
					if d then d:Fire() end
				end
				local sig = rawget(t, "_sig")[k]
				if sig and gammal ~= v then sig:Fire() end
				return
			end
			if k == "Parent" then
				rawset(t, "Parent", v)
				if v and type(v) == "table" then
					v._barn = v._barn or {}
					table.insert(v._barn, t)
				end
			else
				rawset(t, k, v)
			end
		end,
	})
end

Instance = { new = __nyInstans }

--[[ ══ `typeof` SAKNADES HELT, OCH DET VAR INTE OFARLIGT (#246) ═══════

	Luau-CLI:t har en egen `typeof`, och for en stubbinstans — som ar en
	vanlig tabell — svarar den "table". Produktionen skriver sina vakter
	som Roblox kraver:

	    if typeof(modell) ~= "Instance" or not modell:IsA("Model") then
	        return false, "spel.ingen_hast"
	    end

	I banken tog den grenen ALLTID. `LedService.placeraVidMal` svarade
	darfor `spel.ingen_hast` pa varje anrop, och eftersom «Rida nu» gar
	genom just den funktionen har hela genvagens SLUTFAS aldrig varit
	matbar i banken. Felet ser ut som ett produktfel i loggen — "du har
	ingen tilldelad hast" — men ar bankens.

	Det ar precis den sortens tysta halvsanning som gor att en grind kan
	vara gron i manader medan vagen den pastar sig mata aldrig kors.

	RATTELSEN LIGGER HAR, INTE I PRODUKTIONEN. Att skriva om vakten till
	`type(x) ~= "table"` hade forsvagat en riktig kontroll for att blidka
	en stub. Nu svarar banken som Roblox gor i stallet.

	SMALT MED FLIT: bara stubbinstanser mappas om. En stubbad Vector3
	eller UDim2 bar sitt `_typ` och rors inte, och en vanlig tabell
	svarar fortfarande "table" — `init.client.luau` bygger en vakt pa
	just det. ]]
local __typeof = typeof
function typeof(v)
	if type(v) == "table" and rawget(v, "ClassName") ~= nil
			and rawget(v, "_barn") ~= nil then
		return "Instance"
	end
	return __typeof(v)
end

--[[ ── Animationsstubbar ───────────────────────────────────────────────
     `__makeRig` lämnar `animator = nil`, och därför har `AnimationController`
     ALDRIG kunnat konstrueras i en spec — modulen har varit helt omätt. Det
     är inte en detalj: felet som fasändringen rättar kunde ligga kvar just
     därför att ingen grind nådde raden.

     Spåret speglar de få egenskaper modulen rör, och det räknar anropen så
     att en spec kan mäta SKILLNADEN mellan att spola och att justera fart.
     `Length` är satt till ett tal som inte är 1, annars skulle en spec inte
     kunna se om koden glömt multiplicera med längden. ]]
function __makeTrack(length)
	local t = {
		Length = length or 0.86,
		TimePosition = 0,
		IsPlaying = false,
		Looped = false,
		Priority = nil,
		Speed = 1,
		_speedCalls = {},
		_plays = 0,
		_stops = 0,
	}
	function t:Play(fade) self.IsPlaying = true; self._plays += 1; self._fade = fade end
	function t:Stop(fade) self.IsPlaying = false; self._stops += 1; self._fade = fade end
	function t:AdjustSpeed(s) self.Speed = s; table.insert(self._speedCalls, s) end
	function t:AdjustWeight(w) self.Weight = w end
	return t
end

--[[ En rigg med animator och AnimationConfig. Alla nycklar i
     `Config.ANIMATION_KEYS` får ett id, så att inget spår hoppas över tyst
     och specen mäter det avsedda fallet och inte reservfallet. ]]
function __makeAnimRig(length)
	local rig = __makeRig()
	local spar = {}
	local cfg = { _attr = {} }
	function cfg:GetAttribute(k) return self._attr[k] end
	function cfg:SetAttribute(k, v) self._attr[k] = v end
	for _, key in __Core.Config.ANIMATION_KEYS do
		cfg._attr[key] = "rbxassetid://1"
	end
	rig.animConfig = cfg
	rig.animator = {
		LoadAnimation = function(_, anim)
			local t = __makeTrack(length)
			spar[anim.Name] = t
			return t
		end,
	}
	rig._tracks = spar
	return rig
end

--[[ En led med attribut och C0 — det setBodyTilt och setRiderLean rör.
     Instansen bär också :IsA så att den kan passera RigAdapter.build. ]]
function __makeJoint(klass)
	local j = { C0 = cframe(), _attr = {}, ClassName = klass or "Motor6D" }
	function j:GetAttribute(k) return self._attr[k] end
	function j:SetAttribute(k, v) self._attr[k] = v end
	function j:IsA(k) return k == self.ClassName end
	return j
end

--[[ Sätter gamepadens vänsterspak i stubben, så att summeringen mellan
     tangenter, spak och pekskärm går att mäta. ]]
function __setStick(x, y)
	local usv = game:GetService("UserInputService")
	if x == nil then usv._pad = {} return end
	usv._pad = { { KeyCode = Enum.KeyCode.Thumbstick1, Position = vec(x, y, 0) } }
end

--[[ Skickar en tangenthändelse genom den bindning som FAKTISKT äger
     tangenten.

     Hjälparen slog förut alltid i `HorseControl`. Efter att DRIV och
     BROMS blev egna handlingar hade det gjort varje mätning av dem grön
     av fel skäl: `HorseControl` sinkar allt den får och hade svalt W utan
     att någon trappa rörts. Nu slås tangenten upp i den lista
     `BindAction` sparade, alltså samma väg som Roblox väljer handling. ]]
function __key(kod, nere)
	local cas = game:GetService("ContextActionService")
	local lage = if nere then Enum.UserInputState.Begin else Enum.UserInputState.End
	for namn, fn in pairs(cas._bound) do
		if type(fn) == "function" then
			local tangenter = cas._bound[namn .. "@tangenter"]
			if tangenter then
				for _, t in ipairs(tangenter) do
					if t == kod then
						fn(namn, lage, { KeyCode = kod })
						return true
					end
				end
			end
		end
	end
	return false
end

--[[ Trycker DRIV eller BROMS genom CAS, alltså exakt spelarens väg, och
     svarar om impulsen gick in eller slukades av spärren. ]]
function __handling(namn)
	local cas = game:GetService("ContextActionService")
	local fn = cas._bound[namn]
	if not fn then return false end
	fn(namn, Enum.UserInputState.Begin, { KeyCode = Enum.KeyCode.Unknown })
	return true
end

--[[ `spawn` kör SYNKRONT i bänken. Det är med flit: provet ska kunna mäta
     vad som hänt när `start()` returnerat, och en riktig trådväxling hade
     gjort ordningsprovet nedan tidsberoende i stället för deterministiskt.
     Det som provas är ordningen mellan anslutning och anrop, inte att Roblox
     schemalägger. ]]
task = {
	delay = function(_, fn) __senasteDelay = fn end,
	spawn = function(fn, ...) fn(...) end,
	--[[ `defer` kor direkt i banken, precis som `spawn`. I Roblox skjuts
	     den till bildrutans slut; det som provas ar VAD den gor, inte NAR.
	     `TouchControls` anvander den for att slå ihop flera
	     storleksandringar i samma bildruta till en ombyggnad (#208). ]]
	defer = function(fn, ...) fn(...) end,
	--[[ `wait` är en no-op i bänken. SparService backar av med 1-2-4
	     sekunder mellan retryförsöken; en riktig väntan hade gjort
	     felprovet sju sekunder långt utan att mäta något annat än att
	     luau kan sova. Antalet FÖRSÖK är det som provas, och det räknar
	     datalagerstubben. ]]
	wait = function() return 0 end,
}
