--!strict
--[[
	HorseService — serverns auktoritet.

	Servern äger: vem som rider vad, om uppsittning får ske, uthålligheten,
	och hästarnas beständiga statistik. Den äger INTE bildruta-för-bildruta-
	positionen — den ligger hos ryttarens klient via nätverksägarskap, för
	annars går det inte att rida responsivt med Roblox latens.

	Det klienten skickar in valideras: tempo mot hästens tak, position mot
	rimlig förflyttning. Fusk ger en tillrättaläggning, inte en kick — det
	här är ett familjespel, inte en tävlingsserver.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local Core = require(game:GetService("ReplicatedStorage").HorseCore)
local Types = require(game:GetService("ReplicatedStorage").HorseCore.Types)
local Config, Gaits, RigAdapter, Net = Core.Config, Core.Gaits, Core.RigAdapter, Core.Networking

local HorseService = {}

export type Session = {
	rig: Types.Rig,
	stats: { [string]: any },
	rider: Player?,
	stamina: number,
	lastExertion: number,
	lastSync: number,
	lastPosition: Vector3,
}

local sessions: { [Model]: Session } = {}
local byRider: { [Player]: Model } = {}

local TAG = "Horse"

--[[ ── Registrering ────────────────────────────────────────────────── ]]

local function register(model: Model)
	if sessions[model] then return end

	local rig, err = RigAdapter.build(model)
	if not rig then
		warn(("[Horse] %s kunde inte registreras: %s"):format(model:GetFullName(), err or "okänt fel"))
		return
	end

	-- Configuration-blocken skapas om de saknas, så att allt går att skruva
	-- i Studio i stället för att ligga dolt i kod.
	local function ensure(name: string): Configuration
		local existing = model:FindFirstChild(name)
		if existing and existing:IsA("Configuration") then
			return existing
		end
		local c = Instance.new("Configuration")
		c.Name = name
		c.Parent = model
		return c
	end
	rig.stats = rig.stats or ensure("HorseStats")
	rig.gaitConfig = rig.gaitConfig or ensure("GaitConfig")
	rig.animConfig = rig.animConfig or ensure("AnimationConfig")

	Config.writeDefaults(rig.stats :: Configuration, Config.STATS)
	Config.writeDefaults(rig.gaitConfig :: Configuration, Config.MOVEMENT)

	local stats = Config.resolveStats(rig.stats)

	-- Humanoiden ställs in en gång. AutoRotate av: vi äger vridningen, annars
	-- snurrar hästen som ett fordon mot rörelseriktningen.
	local hum = rig.humanoid
	if hum then
		hum.AutoRotate = false
		hum.UseJumpPower = true
		hum.JumpPower = Config.MOVEMENT.JumpPower * (0.7 + 0.6 * stats.JumpStrength)
		hum.WalkSpeed = 0
		hum.BreakJointsOnDeath = false
		hum.RequiresNeck = false
		hum.HipHeight = Config.attr(rig.gaitConfig, "HipHeight", hum.HipHeight)
	end

	sessions[model] = {
		rig = rig,
		stats = stats,
		rider = nil,
		stamina = stats.MaxStamina,
		lastExertion = 0,
		lastSync = os.clock(),
		lastPosition = rig.root.Position,
	}

	model:SetAttribute("Registered", true)
	model:SetAttribute("Gait", "halt")
	model:SetAttribute("Stamina", stats.MaxStamina)
end

local function unregister(model: Model)
	local session = sessions[model]
	if not session then return end
	if session.rider then
		byRider[session.rider] = nil
	end
	sessions[model] = nil
end

--[[ ── Uppsittning ─────────────────────────────────────────────────── ]]

local function seatCFrame(session: Session): CFrame
	return RigAdapter.saddleCFrame(session.rig)
end

local function setRider(session: Session, player: Player?)
	local previous = session.rider
	session.rider = player

	if previous then
		byRider[previous] = nil
	end
	if player then
		byRider[player] = session.rig.model
	end

	session.rig.model:SetAttribute("RiderUserId", if player then player.UserId else 0)

	--[[ Nätverksägarskapet går till ryttaren så att rörelsen simuleras där
	     inputen finns. Utan det ligger en halv sekunds fördröjning i varje
	     styrutslag och hästen känns som en båt. ]]
	local ok = pcall(function()
		session.rig.root:SetNetworkOwner(player)
	end)
	if not ok then
		warn("[Horse] Kunde inte sätta nätverksägare (ankrad eller ej fysisk del?)")
	end

	Net.get("MountChanged"):FireAllClients(session.rig.model, player)
end

--[[ Förberedelsegrinden.

	`HorseService` är fortfarande ENDA uppsittningsauktoritet — den här kroken
	flyttar inte beslutet, den låter `GameplayService` lägga till ett villkor
	framför det. Skälet att den ligger här och inte i fjärranropet: allt som
	monterar en ryttare går genom `tryMount`, och en grind som bara satt på
	`MountRequest` hade gått att gå runt genom vilken annan väg som helst in
	i den här filen.

	Ingen grind registrerad = ingen förändring. Hästsystemet ska gå att köra
	utan G01-loopen, annars kan movement-specarna inte prova det ensamt. ]]
local mountGate: ((Player, Model) -> (boolean, string?))? = nil

function HorseService.setMountGate(gate: ((Player, Model) -> (boolean, string?))?)
	mountGate = gate
end

function HorseService.tryMount(player: Player, model: Model): (boolean, string?)
	if mountGate then
		local tillaten, skal = mountGate(player, model)
		if not tillaten then
			return false, skal or "Hästen är inte färdig att sitta upp på"
		end
	end

	local session = sessions[model]
	if not session then
		return false, "Hästen är inte registrerad"
	end
	if session.rider then
		return false, "Hästen är redan upptagen"
	end
	if byRider[player] then
		return false, "Du rider redan"
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return false, "Ingen karaktär"
	end

	local range = Config.attr(session.rig.gaitConfig, "MountRange", 14)
	if (root.Position - session.rig.root.Position).Magnitude > range then
		return false, "För långt bort"
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false, "Ingen levande karaktär"
	end

	--[[ Sitsen sköter fastsättningen. En Seat väljs framför en handgjord
	     Weld för att Roblox då hanterar frånkoppling vid död, respawn och
	     utloggning åt oss — de tre fallen som annars lämnar spökryttare. ]]
	local seat = session.rig.seat
	if seat then
		seat:Sit(humanoid)
	else
		character:PivotTo(seatCFrame(session))
		local weld = Instance.new("WeldConstraint")
		weld.Name = "HorseMount"
		weld.Part0 = root
		weld.Part1 = session.rig.root
		weld.Parent = root
		humanoid.PlatformStand = true
	end

	setRider(session, player)
	return true, nil
end

function HorseService.dismount(player: Player): boolean
	local model = byRider[player]
	if not model then return false end
	local session = sessions[model]
	if not session then return false end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if session.rig.seat and session.rig.seat.Occupant == humanoid then
		session.rig.seat:Sit(nil)
	end
	if character then
		local root = character:FindFirstChild("HumanoidRootPart")
		if root then
			local weld = root:FindFirstChild("HorseMount")
			if weld then weld:Destroy() end
			-- Sätt av åt vänster, som man gör i verkligheten.
			local side = session.rig.root.CFrame * CFrame.new(-4.5, 0, 0)
			character:PivotTo(CFrame.new(side.Position + Vector3.new(0, 3, 0)))
		end
	end
	if humanoid then
		humanoid.PlatformStand = false
	end

	setRider(session, nil)
	return true
end

--[[ ── Uthållighet ─────────────────────────────────────────────────── ]]

local function stepStamina(session: Session, dt: number)
	local stats = session.stats
	local gait = Gaits.get(session.rig.model:GetAttribute("Gait") or "halt")
	local cost = gait.stamina

	if cost > 0 then
		local drain = cost * dt / (0.6 + 0.9 * stats.Endurance)
		session.stamina = math.max(0, session.stamina - drain)
		session.lastExertion = os.clock()
	elseif os.clock() - session.lastExertion > Config.STAMINA.RecoveryDelay then
		local gain = math.abs(cost) * dt * (0.6 + 0.9 * stats.Endurance)
		session.stamina = math.min(stats.MaxStamina, session.stamina + gain)
	end

	--[[ Uthålligheten tvingar aldrig fram ett stopp. Den sänker taket, och
	     hästen rullar ned en gångart av sig själv. Det är läsbart för
	     spelaren och känns som en trött häst, inte som en tom bensintank. ]]
	local fraction = session.stamina / math.max(stats.MaxStamina, 1)
	local ceiling = "gallop"
	if fraction < Config.STAMINA.LowThreshold then
		local t = fraction / Config.STAMINA.LowThreshold
		local floorIndex = Gaits.index(Config.STAMINA.FloorGait)
		local topIndex = #Gaits.ORDER
		ceiling = Gaits.byIndex(math.floor(floorIndex + (topIndex - floorIndex) * t + 0.5))
	end

	session.rig.model:SetAttribute("Stamina", math.floor(session.stamina))
	session.rig.model:SetAttribute("GaitCeiling", ceiling)

	if session.rider then
		Net.get("StaminaSync"):FireClient(session.rider, session.stamina, stats.MaxStamina, ceiling)
	end
end

--[[ ── Validering av det klienten påstår ────────────────────────────── ]]

local function onStateSync(player: Player, gait: string, speed: number)
	local model = byRider[player]
	if not model then return end
	local session = sessions[model]
	if not session then return end
	if typeof(gait) ~= "string" or typeof(speed) ~= "number" then return end
	if not Gaits.BY_NAME[gait] then return end
	if speed ~= speed or speed < -3 or speed > 15 then return end   -- NaN och orimligt

	local ceiling = session.rig.model:GetAttribute("GaitCeiling") or "gallop"
	if Gaits.index(gait) > Gaits.index(ceiling) then
		gait = ceiling
	end

	session.rig.model:SetAttribute("Gait", gait)
	session.rig.model:SetAttribute("Speed", speed)
	session.lastSync = os.clock()
end

--[[ ── Livscykel ───────────────────────────────────────────────────── ]]

function HorseService.start()
	Net.init()

	for _, model in CollectionService:GetTagged(TAG) do
		if model:IsA("Model") then register(model) end
	end
	CollectionService:GetInstanceAddedSignal(TAG):Connect(function(inst)
		if inst:IsA("Model") then register(inst) end
	end)
	CollectionService:GetInstanceRemovedSignal(TAG):Connect(function(inst)
		if inst:IsA("Model") then unregister(inst :: Model) end
	end)

	Net.get("MountRequest").OnServerInvoke = function(player, model)
		if typeof(model) ~= "Instance" or not model:IsA("Model") then
			return false, "Ogiltig häst"
		end
		return HorseService.tryMount(player, model)
	end
	Net.get("DismountRequest").OnServerInvoke = function(player)
		return HorseService.dismount(player)
	end
	Net.get("StateSync").OnServerEvent:Connect(onStateSync)

	Players.PlayerRemoving:Connect(function(player)
		HorseService.dismount(player)
	end)

	--[[ En loop för alla hästar, inte en per häst. Uthålligheten behöver
	     inte 60 Hz — fyra gånger i sekunden räcker och kostar nästan inget
	     även med hundra hästar i världen. ]]
	local accumulator = 0
	RunService.Heartbeat:Connect(function(dt)
		accumulator += dt
		if accumulator < 0.25 then return end
		local step = accumulator
		accumulator = 0
		for _, session in sessions do
			stepStamina(session, step)
		end
	end)
end

function HorseService.sessionFor(model: Model): Session?
	return sessions[model]
end

function HorseService.horseOf(player: Player): Model?
	return byRider[player]
end

return HorseService
