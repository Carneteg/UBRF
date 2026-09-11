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
	c.__mul = function(a, b)
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
	return { FilterType = 0, FilterDescendantsInstances = {} }
end }

Enum = {
	RaycastFilterType = { Exclude = 1 },
	HumanoidStateType = { Freefall = 1, Jumping = 2, Running = 3, Landed = 4 },
	PathStatus = { Success = 1, NoPath = 2, ClosestNoPath = 3 },
	KeyCode = setmetatable({}, { __index = function(_, k) return k end }),
	UserInputState = { Begin = 1, End = 2 },
	UserInputType = { Gamepad1 = 1 },
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
	AutomaticSize = { None = 0, X = 1, Y = 2, XY = 3 },
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
Vector2 = { new = function(x, y) return { _typ = "Vector2", X = x, Y = y } end }

--[[ `warn` fanns inte i bänken. Produktionskoden använder den på sina
     nil-vägar — t.ex. när anläggningen inte är byggd — så utan den kraschade
     just den gren som skulle bevisas fungera. Samlas i stället för att
     skrivas ut, så att ett prov kan läsa vad som varnades. ]]
__varningar = {}
function warn(...)
	table.insert(__varningar, table.concat({ ... }, " "))
end

workspace = {
	Raycast = function(_, origin, dir)
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
		return { Disconnect = function() end }
	end
	function sig:Fire(...)
		for _, fn in ipairs(self._lyssnare) do fn(...) end
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
			FindFirstChildOfClass = function() return nil end,
			--[[ HUD:en parentas hit. Utan den gick PreparationController inte
			     att köra alls i bänken. ]]
			WaitForChild = function(self, namn)
				self._gui = self._gui or { Name = namn, _barn = {} }
				return self._gui
			end,
			--[[ Karaktären kan försvinna mitt i en ritt. Klienten sitter av
			     på den signalen, och det är också där lärarytan släcks. ]]
			CharacterRemoving = __signal(),
		},
		_spelare = {},
		GetPlayers = function(self) return self._spelare end,
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
		InputChanged = { Connect = function() return { Disconnect = function() end } end },
		InputEnded = { Connect = function() return { Disconnect = function() end } end },
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
	ContextActionService = {
		_bound = {},
		BindAction = function(self, namn, fn) self._bound[namn] = fn end,
		UnbindAction = function(self, namn) self._bound[namn] = nil end,
	},
	TweenService = { Create = function() return { Play = function() end } end },
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
local __pathfinding = {
	CreatePath = function(_, params)
		__senastePathParams = params
		return {
			Status = Enum.PathStatus.NoPath,
			ComputeAsync = function() end,
			GetWaypoints = function() return {} end,
		}
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
	if klass == "TextButton" then inst.Activated = __signal() end
	--[[ `ProximityPrompt.Triggered` — samma skäl som Activated ovan.
	     Utan den gick `DorrService.start()` inte att köra i den här
	     banken, och därmed gick promptens TEXT inte att mäta. En grind
	     som inte kan köra tjänsten kan inte se vad spelaren läser. ]]
	if klass == "ProximityPrompt" then
		inst.Triggered = __signal()
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
		--[[ `MoveTo`/`Move` finns för att LedService styr hästen med dem.
		     Stubben SPEGLAR bara ordern — ingen fysik, ingen förflyttning —
		     så en spec kan mäta VART tjänsten sa åt hästen att gå. Flyttade
		     stubben delen själv hade specen mätt stubben. ]]
		inst._moveMal = nil
		inst._moveDir = nil
		function inst:MoveTo(p) self._moveMal = p end
		function inst:Move(dir) self._moveDir = dir end
	end
	if klass == "Model" then
		--[[ Modellen flyttas med `PivotTo` av både uppsittningen och
		     avsittningen. Stubben speglar bara att det HÄNDE och vart —
		     ingen fysik. ]]
		function inst:PivotTo(cf) self._pivot = cf end
		function inst:GetPivot() return self._pivot end
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
		function inst:FireClient(spelare, ...) table.insert(self._skickat, { spelare, ... }) end
		function inst:FireAllClients(...) table.insert(self._skickat, { ... }) end
	end
	if klass == "RemoteFunction" then
		inst.OnServerInvoke = nil
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
			if k == "Position" then
				local cf = rawget(t, "CFrame")
				return cf and cf.Position or nil
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

--[[ Skickar en tangenthändelse genom den bindning Input.bind() la upp. ]]
function __key(kod, nere)
	local fn = game:GetService("ContextActionService")._bound.HorseControl
	if not fn then return end
	fn("HorseControl",
		if nere then Enum.UserInputState.Begin else Enum.UserInputState.End,
		{ KeyCode = kod })
end

--[[ `spawn` kör SYNKRONT i bänken. Det är med flit: provet ska kunna mäta
     vad som hänt när `start()` returnerat, och en riktig trådväxling hade
     gjort ordningsprovet nedan tidsberoende i stället för deterministiskt.
     Det som provas är ordningen mellan anslutning och anrop, inte att Roblox
     schemalägger. ]]
task = {
	delay = function(_, fn) __senasteDelay = fn end,
	spawn = function(fn, ...) fn(...) end,
	--[[ `wait` är en no-op i bänken. SparService backar av med 1-2-4
	     sekunder mellan retryförsöken; en riktig väntan hade gjort
	     felprovet sju sekunder långt utan att mäta något annat än att
	     luau kan sova. Antalet FÖRSÖK är det som provas, och det räknar
	     datalagerstubben. ]]
	wait = function() return 0 end,
}
