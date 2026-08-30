--!nostrict
--[[
	Roblox-stubbar för att FAKTISKT KÖRA byggskriptet utanför Studio.

	Review 02: *"Compilation plus pure-Luau geometry tests are not sufficient
	proof that the generated environment actually builds correctly in Roblox."*
	Det är sant. Den här filen gör skillnaden mellan "koden kompilerar" och
	"koden kör och producerar de här delarna med de här måtten".

	Den ersätter INTE Studio. Den kan inte säga något om utseende, ljus,
	material, prestanda eller om något ser rätt ut — bara att skriptet kör utan
	fel och att delarna hamnar där de ska. Skärmdumparna Review 02 kräver
	kommer bara ur Studio.

	Skillnaden mot stubs.luau: den här behöver riktig CFrame-translation, för
	BuildKit lägger varje del som `base * CFrame.new(x, y, z)`. Rörelsebänkens
	CFrame bär bara vinklar vidare och skulle lägga alla delar i origo.
	Rotationen är begränsad till yaw, vilket är allt byggnaderna använder.
]]

local function vec(x, y, z)
	local v = { X = x or 0, Y = y or 0, Z = z or 0 }
	local mt = {}
	mt.__index = mt
	mt.__add = function(a, b) return vec(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
	mt.__sub = function(a, b) return vec(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
	mt.__mul = function(a, b)
		if type(b) == "number" then return vec(a.X * b, a.Y * b, a.Z * b) end
		return vec(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
	end
	return setmetatable(v, mt)
end
Vector3 = { new = vec, zero = vec(0, 0, 0), yAxis = vec(0, 1, 0) }

Color3 = {
	fromRGB = function(r, g, b)
		return { R = (r or 0) / 255, G = (g or 0) / 255, B = (b or 0) / 255 }
	end,
	new = function(r, g, b) return { R = r or 0, G = g or 0, B = b or 0 } end,
}

local function cframe(pos, yaw)
	local c = { Position = pos or vec(), Yaw = yaw or 0 }
	c.LookVector = vec(math.sin(c.Yaw), 0, math.cos(c.Yaw))
	c.__mul = function(a, b)
		-- Rotera b:s förskjutning med a:s yaw och lägg till. Det är allt
		-- byggnaderna behöver: de står axelriktade, och rotY är 0.
		local s, co = math.sin(a.Yaw), math.cos(a.Yaw)
		local p = b.Position
		return cframe(vec(a.Position.X + p.X * co + p.Z * s,
			a.Position.Y + p.Y,
			a.Position.Z - p.X * s + p.Z * co), a.Yaw + b.Yaw)
	end
	return setmetatable(c, c)
end

CFrame = {
	new = function(a, b, c)
		if type(a) == "number" then return cframe(vec(a, b, c)) end
		return cframe(a)
	end,
	Angles = function(_, y, _) return cframe(nil, y or 0) end,
	lookAt = function(from, to) return cframe(from) end,
	identity = cframe(),
}

Enum = {
	Material = setmetatable({}, { __index = function(_, k) return k end }),
	SurfaceType = setmetatable({}, { __index = function(_, k) return k end }),
	CameraType = { Scriptable = 1 },
}

--[[ Instanser. Bara det BuildKit och byggskriptet rör: egenskaper, Parent som
     bygger trädet, attribut, GetDescendants och Destroy. Sätter någon en
     egenskap som inte finns i Roblox märks det inte här — det är en av
     gränserna, och den står i README. ]]
local function instance(klass)
	local barn = {}
	local attr = {}
	local i
	i = {
		ClassName = klass, Name = klass, Children = barn,
		Size = vec(), CFrame = cframe(), Transparency = 0, CanCollide = true,
		FindFirstChild = function(self, namn)
			for _, b in ipairs(barn) do if b.Name == namn then return b end end
			return nil
		end,
		Destroy = function(self)
			if self.__parent then
				for k, b in ipairs(self.__parent.Children) do
					if b == self then table.remove(self.__parent.Children, k) break end
				end
			end
		end,
		SetAttribute = function(_, k, v)
			assert(string.match(k, "^[A-Za-z0-9_]+$"),
				"Roblox tillåter bara [A-Za-z0-9_] i attributnamn, fick: " .. tostring(k))
			attr[k] = v
		end,
		GetAttribute = function(_, k) return attr[k] end,
		GetDescendants = function(self)
			local ut = {}
			local function ner(nod)
				for _, b in ipairs(nod.Children) do
					table.insert(ut, b); ner(b)
				end
			end
			ner(self)
			return ut
		end,
	}
	return setmetatable(i, {
		__index = function(_, k) return rawget(i, k) end,
		__newindex = function(t, k, v)
			if k == "Parent" then
				rawset(t, "__parent", v)
				if v then table.insert(v.Children, t) end
			else
				rawset(t, k, v)
			end
		end,
	})
end

Instance = { new = function(klass) return instance(klass) end }

workspace = instance("Workspace")
workspace.Name = "Workspace"
workspace.CurrentCamera = { CFrame = cframe(), CameraType = 1 }
