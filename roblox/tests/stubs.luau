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
	Material = setmetatable({}, { __index = function(_, k) return k end }),
}

workspace = {
	Raycast = function(_, origin, dir)
		--[[ Plan mark under hästen. Sluttningar testas separat om det
		     behövs; hit finns för att grounded ska bli sant. ]]
		return { Position = vec(origin.X, 0, origin.Z), Normal = vec(0, 1, 0),
			Instance = { Name = "Baseplate" }, Material = Enum.Material.Grass }
	end,
	CurrentCamera = { CFrame = cframe(), FieldOfView = 70, CameraType = 2 },
}

local __services = {
	ReplicatedStorage = nil,   -- sätts efter att __Core byggts
	Workspace = workspace,     -- kameran hämtar den som tjänst
	RunService = {
		Heartbeat = { Connect = function() return { Disconnect = function() end } end },
		RenderStepped = { Connect = function() return { Disconnect = function() end } end },
		IsClient = function() return true end,
		IsServer = function() return false end,
	},
	Players = { LocalPlayer = {
		Character = { Name = "Spelare" },
		FindFirstChild = function() return nil end,
		FindFirstChildOfClass = function() return nil end,
	} },
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
	CollectionService = {
		GetTagged = function() return {} end,
		GetInstanceAddedSignal = function()
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

game = {
	GetService = function(_, name)
		if name == "ReplicatedStorage" then return { HorseCore = __Core } end
		return assert(__services[name], "ingen stub för tjänsten " .. name)
	end,
	Players = __services.Players,
}
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

task = { delay = function(_, fn) __senasteDelay = fn end }
