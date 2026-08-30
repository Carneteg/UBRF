--!nostrict
--[[
	Serverstubbar för att FAKTISKT KÖRA GameplayService utanför Studio.

	Preparation.spec provar bara den rena regelmodulen. Ingenting provade
	tjänsten som äger tilldelning, avstånd och uppsittningsspärr — alltså
	precis de regler som avgör om två spelare kan få samma häst eller om
	någon kan sitta upp på en oförberedd häst.

	Vad den INTE ersätter: Studio. Prompter, UI, replikering och game feel
	finns inte här.

	task.defer köas och körs av __korDeferrade(). Det är med flit: den som
	skriver ett prov ska själv bestämma NÄR de körs, annars går det inte att
	prova vad som händer mitt i en tilldelning.
]]

--[[ Vector3 med ett riktigt Magnitude. Forsta forsoket lat Magnitude vara
	en funktion pa en av vagarna, och da foll closeEnough pa "attempt to
	compare number < function" i stallet for att mata avstandet. ]]
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

--[[ task.defer köas. __korDeferrade() tömmer kön; nya defers under körningen
	hamnar sist och körs i samma svep, precis som Roblox gör. ]]
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

--[[ Signal med minne: provet kan fyra den för hand. ]]
local function signal()
	local l = {}
	return {
		Connect = function(_, f) table.insert(l, f); return { Disconnect = function() end } end,
		_fire = function(...) for _, f in ipairs(l) do f(...) end end,
	}
end
__signal = signal

--[[ UI-typer. Bara det GameplayController ror, och de baras vidare oforandrade
	sa att ett prov kan lasa tillbaka exakt de tal koden satte. ]]
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

--[[ Instanser: attribut, Parent, IsA och GetFullName. Det GameplayService rör. ]]
local function instans(klass, namn)
	local attr, barn = {}, {}
	local i
	i = {
		ClassName = klass, Name = namn or klass, Children = barn, Parent = nil,
		--[[ Position betyder olika saker for en Part och en TextLabel. Forst
			gav stubben Vector3 at BADA, och HUD-provet foll pa
			"attempt to index number with Offset" — for en TextLabel som inte
			satt sin Position hade da en Vector3 dar en UDim2 skulle sta. ]]
		Position = if klass == "TextLabel" or klass == "Frame" or klass == "TextButton"
			then UDim2.new(0, 0, 0, 0)
			else Vector3.new(0, 0, 0),
		Size = if klass == "TextLabel" or klass == "Frame" or klass == "TextButton"
			then UDim2.new(0, 0, 0, 0)
			else nil,
		--[[ IsA måste kunna arvet. Först returnerade den bara k == klass, och
			då var Part:IsA("BasePart") falskt — closeEnough föll på "Din
			karaktär är inte redo" i STÄLLET för på avståndet, så
			avståndsprovet blev grönt utan att mäta något. Ett prov som
			passerar av fel skäl är värre än ett som fallerar. ]]
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
	--[[ Parent bygger tradet. Utan det hittade inget prov prompten som
		klienten just skapade, for den lag ingenstans. ]]
	return setmetatable(i, {
		--[[ Parent lagras som __parent av __newindex. Utan den har raden
			returnerade i.Parent nil, och availableHorses filtrerade bort
			VARJE hast som "inte i varlden" — ett stubbfel som sag ut som ett
			tjanstefel. ]]
		__index = function(_, k)
			if k == "Parent" then return rawget(i, "__parent") end
			return rawget(i, k)
		end,
		__newindex = function(t, k, v)
			if k == "Parent" then
				--[[ Den gamla foraldern behover inte vara en instans; provet
					parentar hastar till ett vanligt bord. Utan Children-vakten
					kraschade omparentering pa ipairs(nil). ]]
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

--[[ typeof: GameplayService skiljer på sträng och Instance. ]]
local __rawtypeof = typeof
typeof = function(v)
	if type(v) == "table" and v.ClassName then return "Instance" end
	return __rawtypeof(v)
end

--[[ Spelare. Karaktärens rot flyttas av provet för att mäta avståndsregeln. ]]
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

--[[ CollectionService med en föränderlig taggmängd. ]]
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

--[[ ProximityPrompt behover Enabled och Triggered for klientprovet. ]]
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

--[[ Attributsignaler med minne, sa att ett klientprov kan andra ett attribut
	och se att lyssnaren kor. Utan det gar det inte att prova att prompten
	uppdateras nar servern byter fas. ]]
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

--[[ Players. ]]
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

--[[ LocalPlayer skapas HAR, inte i provet. Klientmodulerna laser
	Players.LocalPlayer redan vid modulladdning, alltsa innan provets kropp
	kor — satte provet den sjalv blev den nil och allt foll pa
	"attempt to index nil". ]]
__lokalSpelare = __medAttributsignal(__spelare("LokalSpelare", 101))
Players.LocalPlayer = __lokalSpelare

--[[ Nätet. RemoteFunction bär OnServerInvoke; RemoteEvent sparar det som
	skickats till varje spelare, så provet kan läsa vad klienten SKULLE fått. ]]
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

--[[ RigAdapter: riggen sitter där modellen står, så avståndsregeln blir
	mätbar genom att flytta modellen eller spelaren. ]]
local RigAdapter = {
	build = function(model)
		if model:GetAttribute("TrasigRigg") == true then
			return nil, "Hästen saknar en användbar rigg."
		end
		return { root = model, attachments = {} }
	end,
}

--[[ PlayerGui, sa att ScreenGui har nagonstans att hamna. ]]
local __playerGui = instans("PlayerGui", "PlayerGui")
__playerGuiRef = __playerGui
__lokalSpelare.WaitForChild = function(_, namn)
	if namn == "PlayerGui" then return __playerGui end
	return instans("Instance", namn)
end

--[[ RemoteEvent pa klientsidan behover OnClientEvent. ]]
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

--[[ En HorseService-attrapp som SÄGER JA till allt. Med flit: då är det bara
	G01-spärren som kan stoppa en uppsittning, och ett prov som passerar
	bevisar att spärren finns — inte att HorseService råkade neka. ]]
__monteringar = {}
__HorseServiceStub = {
	tryMount = function(player, model)
		table.insert(__monteringar, { player = player, model = model })
		return true, nil
	end,
	dismount = function(player)
		return true
	end,
}
