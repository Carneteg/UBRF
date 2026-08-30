--!nostrict
--[[
	Körbara stubbar för G01:s server- och klientregler utanför Studio.

	De ersätter inte Studio. De gör assignment-binding, avstånd, mount-gate,
	prompt-synlighet och HUD-layout falsifierbara i luau-CLI.
]]

local V3 = {}
V3.__index = V3
function V3.__sub(a, b) return Vector3.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
function V3.__add(a, b) return Vector3.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
Vector3 = {
	new = function(x, y, z)
		local v = setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, V3)
		v.Magnitude = math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z)
		return v
	end,
}

warn = function(...) print("[warn]", ...) end

local __ko = {}
task = {
	defer = function(f, ...) table.insert(__ko, { f = f, args = table.pack(...) }) end,
	delay = function(_, f) table.insert(__ko, { f = f, args = table.pack() }) end,
	spawn = function(f, ...) f(...) end,
	wait = function() end,
}
function __korDeferrade()
	local varv = 0
	while #__ko > 0 do
		varv += 1
		assert(varv < 100, "task.defer verkar loopa i all oändlighet")
		local ko = __ko
		__ko = {}
		for _, post in ipairs(ko) do post.f(table.unpack(post.args, 1, post.args.n)) end
	end
end

local function signal()
	local l = {}
	return {
		Connect = function(_, f) table.insert(l, f); return { Disconnect = function() end } end,
		_fire = function(...) for _, f in ipairs(l) do f(...) end end,
	}
end
__signal = signal

UDim = { new = function(sk, off) return { Scale = sk or 0, Offset = off or 0 } end }
UDim2 = {
	new = function(xs, xo, ys, yo)
		return { X = { Scale = xs or 0, Offset = xo or 0 },
			Y = { Scale = ys or 0, Offset = yo or 0 } }
	end,
	fromOffset = function(x, y)
		return { X = { Scale = 0, Offset = x or 0 }, Y = { Scale = 0, Offset = y or 0 } }
	end,
}
Vector2 = { new = function(x, y) return { X = x or 0, Y = y or 0 } end }
Color3 = {
	fromRGB = function(r, g, b) return { R = r, G = g, B = b } end,
	new = function(r, g, b) return { R = r, G = g, B = b } end,
}
Enum = setmetatable({}, { __index = function(t, k)
	local v = setmetatable({}, { __index = function(_, n) return n end })
	rawset(t, k, v); return v
end })

local function instans(klass, namn)
	local attr, barn = {}, {}
	local i
	i = {
		ClassName = klass, Name = namn or klass, Children = barn,
		Position = if klass == "TextLabel" or klass == "Frame" or klass == "TextButton"
			then UDim2.new(0, 0, 0, 0) else Vector3.new(0, 0, 0),
		Size = if klass == "TextLabel" or klass == "Frame" or klass == "TextButton"
			then UDim2.new(0, 0, 0, 0) else nil,
		IsA = function(self, k)
			if k == klass then return true end
			if k == "BasePart" then return klass == "Part" or klass == "MeshPart" end
			if k == "Instance" then return true end
			return false
		end,
		GetFullName = function(self) return self.Name end,
		SetAttribute = function(_, k, v)
			assert(string.match(k, "^[A-Za-z0-9_]+$"),
				"Roblox tillåter bara [A-Za-z0-9_] i attributnamn, fick: " .. tostring(k))
			attr[k] = v
		end,
		GetAttribute = function(_, k) return attr[k] end,
		GetAttributeChangedSignal = function() return signal() end,
		FindFirstChild = function(self, n)
			for _, b in ipairs(barn) do if b.Name == n then return b end end
			return nil
		end,
		Destroy = function(self) self.Parent = nil end,
	}
	return setmetatable(i, {
		__index = function(_, k)
			if k == "Parent" then return rawget(i, "__parent") end
			return rawget(i, k)
		end,
		__newindex = function(t, k, v)
			if k == "Parent" then
				local gammal = rawget(t, "__parent")
				if gammal and gammal.Children then
					for n, b in ipairs(gammal.Children) do
						if b == t then table.remove(gammal.Children, n) break end
					end
				end
				rawset(t, "__parent", v)
				if v and v.Children then table.insert(v.Children, t) end
			else
				rawset(t, k, v)
			end
		end,
	})
end
__instans = instans
Instance = { new = function(k) return instans(k) end }

local __rawtypeof = typeof
typeof = function(v)
	if type(v) == "table" and v.ClassName then return "Instance" end
	return __rawtypeof(v)
end

function __spelare(namn, userId)
	local p = instans("Player", namn)
	p.UserId = userId
	local rot = instans("Part", "HumanoidRootPart")
	rot.Position = Vector3.new(0, 0, 0)
	local kar = instans("Model", "Character")
	table.insert(kar.Children, rot)
	p.Character = kar
	p._root = rot
	return p
end

__tagged = {}
local addedSignals, removedSignals = {}, {}
local CollectionService = {
	GetTagged = function(_, tag)
		local ut = {}
		for _, m in ipairs(__tagged[tag] or {}) do table.insert(ut, m) end
		return ut
	end,
	GetInstanceAddedSignal = function(_, tag)
		addedSignals[tag] = addedSignals[tag] or signal()
		return addedSignals[tag]
	end,
	GetInstanceRemovedSignal = function(_, tag)
		removedSignals[tag] = removedSignals[tag] or signal()
		return removedSignals[tag]
	end,
}
function __taggaHast(model)
	__tagged.Horse = __tagged.Horse or {}
	table.insert(__tagged.Horse, model)
	if addedSignals.Horse then addedSignals.Horse._fire(model) end
end
function __avtaggaHast(model)
	for k, m in ipairs(__tagged.Horse or {}) do
		if m == model then table.remove(__tagged.Horse, k) break end
	end
	if removedSignals.Horse then removedSignals.Horse._fire(model) end
end

local __gamlaInstans = instans
instans = function(klass, namn)
	local i = __gamlaInstans(klass, namn)
	if klass == "ProximityPrompt" then
		i.Enabled = true
		i.Triggered = signal()
		i.ActionText = ""
		i.ObjectText = ""
	end
	return i
end
__instans = instans
Instance = { new = function(k) return instans(k) end }

function __medAttributsignal(i)
	local sig = {}
	local gammalSet = i.SetAttribute
	i.GetAttributeChangedSignal = function(_, k)
		sig[k] = sig[k] or signal()
		return sig[k]
	end
	i.SetAttribute = function(self, k, v)
		gammalSet(self, k, v)
		if sig[k] then sig[k]._fire() end
	end
	return i
end

local __spelarlista = {}
local Players = {
	PlayerAdded = signal(),
	PlayerRemoving = signal(),
	GetPlayers = function()
		local ut = {}
		for _, p in ipairs(__spelarlista) do table.insert(ut, p) end
		return ut
	end,
}
function __ansluter(p)
	p.Parent = Players
	table.insert(__spelarlista, p)
	Players.PlayerAdded._fire(p)
end
function __lamnar(p)
	for k, q in ipairs(__spelarlista) do
		if q == p then table.remove(__spelarlista, k) break end
	end
	p.Parent = nil
	Players.PlayerRemoving._fire(p)
end
__Players = Players

__lokalSpelare = __medAttributsignal(__spelare("LokalSpelare", 101))
Players.LocalPlayer = __lokalSpelare

__skickat = {}
local __remotes = {}
local Networking = {
	get = function(namn)
		if not __remotes[namn] then
			__remotes[namn] = {
				Name = namn,
				OnServerInvoke = nil,
				FireClient = function(_, spelare, ...)
					__skickat[spelare] = __skickat[spelare] or {}
					table.insert(__skickat[spelare], table.pack(...))
				end,
			}
		end
		return __remotes[namn]
	end,
}
function __anropa(namn, ...)
	local r = __remotes[namn]
	assert(r and r.OnServerInvoke, "ingen handler för " .. namn)
	return r.OnServerInvoke(...)
end
function __sistaTill(spelare)
	local k = __skickat[spelare]
	return k and k[#k] or nil
end

local RigAdapter = {
	build = function(model)
		if model:GetAttribute("TrasigRigg") == true then
			return nil, "Hästen saknar en användbar rigg."
		end
		return { root = model, attachments = {} }
	end,
}

local __playerGui = instans("PlayerGui", "PlayerGui")
__playerGuiRef = __playerGui
__lokalSpelare.WaitForChild = function(_, namn)
	if namn == "PlayerGui" then return __playerGui end
	return instans("Instance", namn)
end

local __gamlaGet = Networking.get
Networking.get = function(namn)
	local r = __gamlaGet(namn)
	if not r.OnClientEvent then
		r.OnClientEvent = signal()
		r.InvokeServer = function() return nil end
	end
	return r
end

__Core = { Networking = Networking, RigAdapter = RigAdapter }

game = {
	GetService = function(_, namn)
		if namn == "ReplicatedStorage" then return { HorseCore = __Core } end
		if namn == "Players" then return Players end
		if namn == "CollectionService" then return CollectionService end
		if namn == "RunService" then
			return { IsServer = function() return true end, IsClient = function() return false end }
		end
		error("ingen stub för tjänsten " .. tostring(namn))
	end,
}
script = { Parent = __Core }

__monteringar = {}
__HorseServiceStub = {
	tryMount = function(player, model)
		table.insert(__monteringar, { player = player, model = model })
		return true, nil
	end,
	dismount = function(player) return true end,
}

-- StallService-attrappen äger IDENTITETEN precis som produktionssystemet.
-- Provet väljer data; GameplayService får bara binda rätt HorseId-modell.
__stallData = {}
__StallServiceStub = {
	hastFor = function(player) return __stallData[player] end,
}
function __stallTilldela(player, id, namn)
	__stallData[player] = if id then {
		id = id,
		namn = namn or id,
		box = { nummer = 1, rad = "W", gang = "A" },
	} else nil
	player:SetAttribute("AssignedHorseId", id or "")
end
