--!nostrict
--[[
	Serverstubbar för att FAKTISKT KÖRA WorldService.

	Ingenting körde den. Dörrbindningen och busy-vakten fanns alltså bara som
	kod, inte som något provat — och det var två av punkterna i
	falsifieringslistan.

	Det som gör den här bänken annorlunda: TWEEN:EN GÅR ATT HÅLLA PÅGÅENDE.
	En stubb som låter Completed:Wait() återvända direkt gör busy-vakten
	omöjlig att prova, för flaggan hinner nollställas innan nästa tryck. Här
	yieldar Wait() i stället, och provet bestämmer själv när dörren blir klar.

	Vad den INTE ersätter: Studio. Att panelen rör sig och att man kan gå
	igenom syns bara där.
]]

warn = function(...) print("[warn]", ...) end

--[[ CFrame: bara bärare. typeof måste svara "CFrame", för WorldService
	vägrar binda en dörr vars attribut inte är det. ]]
local CF = {}
CF.__index = CF
CFrame = {
	new = function(x, y, z)
		return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0, __cf = true }, CF)
	end,
}
Vector3 = { new = function(x, y, z) return { X = x or 0, Y = y or 0, Z = z or 0 } end }

local __rawtypeof = typeof
typeof = function(v)
	if type(v) == "table" and rawget(v, "__cf") then return "CFrame" end
	if type(v) == "table" and rawget(v, "ClassName") then return "Instance" end
	return __rawtypeof(v)
end

Enum = setmetatable({}, { __index = function(t, k)
	local v = setmetatable({}, { __index = function(_, n) return n end })
	rawset(t, k, v); return v
end })
TweenInfo = { new = function(...) return { ... } end }

--[[ Signal vars handlare kör i EGEN coroutine, sa att en handlare som yieldar
	inte fryser hela provet. Utan det gar busy-vakten inte att prova. ]]
local function signal()
	local l = {}
	return {
		Connect = function(_, f) table.insert(l, f); return { Disconnect = function() end } end,
		_fire = function(...)
			local args = table.pack(...)
			for _, f in ipairs(l) do
				local co = coroutine.create(f)
				coroutine.resume(co, table.unpack(args, 1, args.n))
			end
		end,
	}
end
__signal = signal

--[[ Tweens som INTE blir klara av sig själva. __slutforTweens() släpper dem. ]]
__pagaende = {}
TweenServiceStub = {
	Create = function(_, mal, info, egenskaper)
		local vantande = {}
		local tween
		tween = {
			Play = function() end,
			Completed = {
				Wait = function()
					table.insert(vantande, coroutine.running())
					coroutine.yield()
				end,
			},
			_slutfor = function()
				for k, v in pairs(egenskaper) do mal[k] = v end
				for _, co in ipairs(vantande) do coroutine.resume(co) end
			end,
		}
		table.insert(__pagaende, tween)
		return tween
	end,
}
function __slutforTweens()
	local kvar = __pagaende
	__pagaende = {}
	for _, t in ipairs(kvar) do t._slutfor() end
	return #kvar
end

--[[ Instanser. ]]
local function instans(klass, namn)
	local attr, barn = {}, {}
	local i
	i = {
		ClassName = klass, Name = namn or klass, Children = barn, Parent = nil,
		CanCollide = true, CFrame = CFrame.new(0, 0, 0),
		ActionText = "", Enabled = true,
		Triggered = signal(),
		IsA = function(_, k)
			if k == klass then return true end
			if k == "BasePart" then return klass == "Part" or klass == "MeshPart" end
			return false
		end,
		GetFullName = function(self) return self.Name end,
		SetAttribute = function(_, k, v)
			assert(string.match(k, "^[A-Za-z0-9_]+$"), "ogiltigt attributnamn: " .. tostring(k))
			attr[k] = v
		end,
		GetAttribute = function(_, k) return attr[k] end,
		FindFirstChild = function(_, n)
			for _, b in ipairs(barn) do if b.Name == n then return b end end
			return nil
		end,
		GetDescendants = function(self)
			local ut = {}
			local function ner(nod)
				for _, b in ipairs(nod.Children) do table.insert(ut, b); ner(b) end
			end
			ner(self)
			return ut
		end,
		PivotTo = function(self, cf) self.CFrame = cf end,
		WaitForChild = function(self, n) return self:FindFirstChild(n) end,
	}
	return setmetatable(i, {
		__index = function(_, k)
			if k == "Parent" then return rawget(i, "__parent") end
			return rawget(i, k)
		end,
		__newindex = function(t, k, v)
			if k == "Parent" then
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

workspace = instans("Workspace", "Workspace")
workspace.DescendantAdded = signal()

task = {
	defer = function(f, ...) f(...) end,
	wait = function() end,
	spawn = function(f, ...) f(...) end,
}

local __spelare = {}
local Players = {
	PlayerAdded = signal(),
	GetPlayers = function() return __spelare end,
}
__Players = Players

game = {
	GetService = function(_, namn)
		if namn == "Players" then return Players end
		if namn == "TweenService" then return TweenServiceStub end
		if namn == "RunService" then
			return { IsServer = function() return true end, IsClient = function() return false end }
		end
		error("ingen stub för tjänsten " .. tostring(namn))
	end,
}
script = { Parent = {} }

--[[ En färdig dörr att prova på. ]]
function __dorr(namn, medCFrame, medPrompt)
	local d = instans("Part", namn or "Dorr")
	d.Parent = workspace
	d:SetAttribute("UBRFDoor", true)
	d:SetAttribute("DoorOpen", false)
	d:SetAttribute("DoorMode", "swing")
	if medCFrame ~= false then
		d:SetAttribute("DoorClosedCFrame", CFrame.new(0, 0, 0))
		d:SetAttribute("DoorOpenCFrame", CFrame.new(5, 0, 0))
	end
	if medPrompt ~= false then
		local p = instans("ProximityPrompt", "DoorPrompt")
		p.Parent = d
	end
	return d
end
