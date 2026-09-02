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
	c.__mul = function(a, b)
		return cframe(a.Position, a.LookVector, (a.Yaw or 0) + (b.Yaw or 0),
			(a.Pitch or 0) + (b.Pitch or 0), (a.Roll or 0) + (b.Roll or 0))
	end
	return setmetatable(c, c)
end
CFrame = {
	new = cframe,
	lookAt = function(a, b) return cframe(a, b) end,
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
	KeyCode = setmetatable({}, { __index = function(_, k) return k end }),
	UserInputState = { Begin = 1, End = 2 },
	UserInputType = { Gamepad1 = 1 },
	ContextActionResult = { Sink = 1 },
	CameraType = { Scriptable = 1, Custom = 2 },
	NormalId = { Top = 1 },
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
	SizeConstraint = { RelativeXY = 1, RelativeXX = 2, RelativeYY = 3 },
	FillDirection = { Horizontal = 1, Vertical = 2 },
	SortOrder = { Name = 1, Custom = 2, LayoutOrder = 3 },
	AutomaticSize = { None = 0, X = 1, Y = 2, XY = 3 },
}

--[[ UI-typerna. HUD:en bara skapar dem och läser dem aldrig isär, så de
     lagras som vad de är — inga beräkningar, ingen låtsad Roblox-matematik. ]]
function UDim2_new(xs, xo, ys, yo)
	return { _typ = "UDim2", XScale = xs, XOffset = xo, YScale = ys, YOffset = yo }
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
	CurrentCamera = { CFrame = cframe(), FieldOfView = 70, CameraType = 2 },
	--[[ Ingen anläggning byggd i bänken. StallService frågar efter den för
	     att kunna sätta en boxmarkör, och SKA då varna och hoppa över
	     markören i stället för att krascha — det är produktionens egen
	     nil-väg, och den provas nu på riktigt. ]]
	_barn = {},
	FindFirstChild = function(self, namn)
		for _, b in ipairs(self._barn) do if b.Name == namn then return b end end
		return nil
	end,
}

local __services = {
	ReplicatedStorage = nil,   -- sätts efter att __Core byggts
	Workspace = workspace,     -- kameran hämtar den som tjänst
	RunService = {
		Heartbeat = { Connect = function() return { Disconnect = function() end } end },
		RenderStepped = { Connect = function() return { Disconnect = function() end } end },
		--[[ `_server` lades till för S2b: GameplayService är serverkod och
		     Networking väljer väg på IsServer. Standard är oförändrad (klient),
		     så alla äldre specar mäter exakt samma sak som förut. ]]
		_server = false,
		IsClient = function(self) return not self._server end,
		IsServer = function(self) return self._server == true end,
	},
	Players = {
		LocalPlayer = {
			Name = "Spelare", UserId = 1,
			Character = { Name = "Spelare" },
			FindFirstChild = function() return nil end,
			FindFirstChildOfClass = function() return nil end,
			--[[ HUD:en parentas hit. Utan den gick PreparationController inte
			     att köra alls i bänken. ]]
			WaitForChild = function(self, namn)
				self._gui = self._gui or { Name = namn, _barn = {} }
				return self._gui
			end,
		},
		_spelare = {},
		GetPlayers = function(self) return self._spelare end,
		PlayerAdded = { Connect = function() return { Disconnect = function() end } end },
		PlayerRemoving = { Connect = function() return { Disconnect = function() end } end },
	},
	--[[ Spaken sätts av testet när gamepad ska mätas. TouchEnabled är falskt:
	     bänken mäter kontraktet, inte gesterna — GUI:t byggs bara i Studio. ]]
	UserInputService = {
		_pad = {},
		GetGamepadState = function(self) return self._pad end,
		TouchEnabled = false,
		InputChanged = { Connect = function() return { Disconnect = function() end } end },
		InputEnded = { Connect = function() return { Disconnect = function() end } end },
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
	CollectionService = {
		_taggade = {},
		GetTagged = function(self, tagg) return self._taggade[tagg] or {} end,
		AddTag = function(self, inst, tagg)
			self._taggade[tagg] = self._taggade[tagg] or {}
			table.insert(self._taggade[tagg], inst)
		end,
		GetInstanceAddedSignal = function()
			return { Connect = function() return { Disconnect = function() end } end }
		end,
		GetInstanceRemovedSignal = function()
			return { Connect = function() return { Disconnect = function() end } end }
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
function __rs:WaitForChild(namn) return self:FindFirstChild(namn) end

game = {
	GetService = function(_, name)
		if name == "ReplicatedStorage" then return __rs end
		return assert(__services[name], "ingen stub för tjänsten " .. name)
	end,
	Players = __services.Players,
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
local function __signal()
	local sig = { _lyssnare = {} }
	function sig:Connect(fn)
		table.insert(self._lyssnare, fn)
		return { Disconnect = function() end }
	end
	function sig:Fire(...)
		for _, fn in ipairs(self._lyssnare) do fn(...) end
	end
	return sig
end
__signal_ny = __signal

local function __nyInstans(klass)
	local inst = {
		ClassName = klass, Name = "", AnimationId = "",
		_barn = {}, _attr = {}, Parent = nil,
	}
	function inst:GetAttribute(k) return self._attr[k] end
	function inst:SetAttribute(k, v) self._attr[k] = v end
	function inst:FindFirstChild(namn)
		for _, b in ipairs(self._barn) do if b.Name == namn then return b end end
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
	function inst:Destroy()
		local far = rawget(self, "Parent")
		if far and far._barn then
			for i, b in ipairs(far._barn) do
				if b == self then table.remove(far._barn, i) break end
			end
		end
	end
	if klass == "TextButton" then inst.Activated = __signal() end
	if klass == "RemoteEvent" then
		inst.OnClientEvent = __signal()
		inst.OnServerEvent = __signal()
		inst._skickat = {}
		function inst:FireClient(spelare, ...) table.insert(self._skickat, { spelare, ... }) end
		function inst:FireAllClients(...) table.insert(self._skickat, { ... }) end
	end
	if klass == "RemoteFunction" then
		inst.OnServerInvoke = nil
	end
	--[[ Parent sätts via metatabell så att barnlistan hålls i takt; koden
	     skriver `x.Parent = y` och förväntar sig att y ser x. ]]
	return setmetatable(inst, {
		__newindex = function(t, k, v)
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
}
