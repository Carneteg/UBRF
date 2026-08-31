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

--[[ Enum svarar pa vad som helst. Byggskriptet och QA-panelen slar upp en
	handfull olika, och en handskriven lista hade bara blivit en till sak att
	halla i synk — samma fel som redan fallit fargexporten och objektantalet.
	Priset ar att ett FELSTAVAT enum-namn inte marks har; det star i README
	som en av bankens granser. ]]
local function __allt()
	return setmetatable({}, { __index = function(_, k) return k end })
end
Enum = setmetatable({
		CameraType = { Scriptable = 1, Custom = 2 },
		--[[ Material ar STRIKT; ovriga enum svarar fortfarande pa allt.
			Materialnamnen ar de som faktiskt faller bygget i Studio. ]]
		Material = __striktEnum("Material", __MATERIAL),
	},
	{ __index = function(t, k) local v = __allt(); rawset(t, k, v); return v end })

--[[ UDim/UDim2 baras bara vidare; panelen laser dem aldrig tillbaka. Racker
	for att bevisa att den BYGGS, inte for att bevisa hur den ser ut. ]]
UDim = { new = function(skala, offset) return { Scale = skala or 0, Offset = offset or 0 } end }
UDim2 = {
	new = function(xs, xo, ys, yo)
		return { X = { Scale = xs or 0, Offset = xo or 0 },
		         Y = { Scale = ys or 0, Offset = yo or 0 } }
	end,
	fromOffset = function(x, y)
		return { X = { Scale = 0, Offset = x or 0 }, Y = { Scale = 0, Offset = y or 0 } }
	end,
}

--[[ Instanser. Bara det BuildKit och byggskriptet rör: egenskaper, Parent som
     bygger trädet, attribut, GetDescendants och Destroy. Sätter någon en
     egenskap som inte finns i Roblox märks det inte här — det är en av
     gränserna, och den står i README. ]]
--[[ En signal som MINNS sina lyssnare, sa att ett prov kan trycka pa
	knapparna. Utan _fire gar det bara att bevisa att panelen byggs, inte att
	den gor nagot nar man klickar. ]]
local function signal()
	local lyssnare = {}
	return {
		Connect = function(_, f) table.insert(lyssnare, f); return { Disconnect = function() end } end,
		_fire = function(...) for _, f in ipairs(lyssnare) do f(...) end end,
	}
end

local function instance(klass)
	local barn = {}
	local attr = {}
	local i
	i = {
		ClassName = klass, Name = klass, Children = barn,
		Size = vec(), CFrame = cframe(), Transparency = 0, CanCollide = true,
		Enabled = true,
		--[[ Knappsignalerna. Bara de tva panelen anvander; en generisk
		     signalfabrik hade dolt en felstavning. ]]
		Activated = signal(),
		MouseButton1Click = signal(),
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
			rawset(self, "__parent", nil)
		end,
		SetAttribute = function(_, k, v)
			assert(string.match(k, "^[A-Za-z0-9_]+$"),
				"Roblox tillåter bara [A-Za-z0-9_] i attributnamn, fick: " .. tostring(k))
			attr[k] = v
		end,
		GetAttribute = function(_, k) return attr[k] end,
		GetChildren = function(self) return self.Children end,
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
		--[[ Parent laser tillbaka __parent, och Destroy nollar den. Utan det
		     sag en forstord instans fortfarande "levande" ut for den som
		     fragade efter .Parent — och QA-panelens aterstart gick da inte
		     att prova har. ]]
		__index = function(_, k)
			if k == "Parent" then return rawget(i, "__parent") end
			return rawget(i, k)
		end,
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

--[[ game:GetService, minimalt.

	Byggskripten behöver det inte, men Studio-paketet gör det: QA-panelen
	frågar RunService om den kör i Studio. Utan stubben kraschar hela paketet
	på rad ett i stället för att bygga, och då går det inte att verifiera
	härifrån att filen Tobias klistrar in faktiskt kör.

	IsStudio är FALSKT här med flit. Panelen ska vägra starta utanför Studio,
	och den regeln vill jag kunna prova, inte bara påstå. ]]
--[[ warn saknades helt. Studio har den; luau-CLI:t inte. Utan stubben dog
	paketet pa QA-panelens VAGRAN-gren — alltsa exakt den gren som ska fungera
	utanfor Studio. ]]
warn = function(...) print("[warn]", ...) end

local __tjanster = {
	RunService = { IsStudio = function() return false end,
	               IsClient = function() return false end,
	               IsServer = function() return true end },
	Players = { LocalPlayer = nil },
	CoreGui = instance("CoreGui"),
	--[[ Tom med flit. Bänken HAR ingen serverkod inlagd, precis som en Studio
	     utan Rojo kopplad. Paketets servervarning ska alltså slå här — det är
	     den grenen som är intressant att kunna prova. ]]
	ServerScriptService = instance("ServerScriptService"),
	CollectionService = {
		GetTagged = function() return {} end,
		GetInstanceAddedSignal = function() return { Connect = function() end } end,
		GetInstanceRemovedSignal = function() return { Connect = function() end } end,
	},
}
game = {
	GetService = function(_, namn)
		local t = __tjanster[namn]
		if not t then error("stubben saknar tjänsten " .. tostring(namn)) end
		return t
	end,
}
