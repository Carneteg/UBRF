--!strict
--[[ LEDA HÄSTEN TILL RIDHUSET (till fots) — docs/LEADING-LESSON-CONTRACT.md.

	EN lektion i området ledning: led din egen häst till den BEFINTLIGA
	målzonen (`LedService.malzon`, ridbanans rektangel). Den OBSERVERAR vanlig
	ledning; den leder, släpper, flyttar eller kvitterar ingenting själv.
	Ingen ridsession, ingen RidForsok, ingen krok i LedService, ingen ändring
	av förberedelsens steg eller historia. De historiska flaggorna
	`harNattMal`/`harLamnatBox` används aldrig.

	Bevis var 0,25 s: hästens rot (PrimaryPart) medan DEN HÄR spelaren leder
	SAMMA bundna häst — färsk plan förflyttning sedan baslinjen, och
	därefter ankomst och kvar i målzonen. Hopp, luckor, byte av häst,
	uppsittning, saknad karaktär och ändrad målzon nollställer. Siffrorna
	är spelantaganden. Sessionslokalt; ingen persistens, ingen belöning. ]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.HorseCore.Networking)
local Aktor = require(ReplicatedStorage.HorseCore.Aktor)
local LedService = require(script.Parent.LedService)
local Skopa = require(script.Parent.Skopa)

local LedLektion = {}
LedLektion.VERSION = "server-ledning-1"

local M = 3 -- studs per meter, som BuildKit.M
local STEG_S = 0.25
local RESA_M = 12.0
local HOPP_M = 3.0
local LUCKA_S = 1.0
local FRAMME_PROV = 4
local DEADLINE = 300
local MAX_REQUESTS = 16
LedLektion.GRANSER = table.freeze({ STEG_S = STEG_S, RESA_M = RESA_M, HOPP_M = HOPP_M,
	LUCKA_S = LUCKA_S, FRAMME_PROV = FRAMME_PROV, DEADLINE = DEADLINE })

type Beroenden = { rattHast: (Player) -> Model?, rider: (Player) -> boolean }
local beroenden: Beroenden? = nil
local tillstand: { [Player]: any } = {}
local klocka = 0 -- serverns lektionstid (s), summan av stegen
local ackum = 0

local AKTIVA = { lead_first = true, leading = true }

local function malNyckel(): string?
	local z = LedService.malzon()
	if not z then return nil end
	return string.format("%.4f|%.4f|%.4f|%.4f", z.x, z.y, z.w, z.h)
end

local function hastRot(modell: Model?): BasePart?
	if not modell or not modell.Parent then return nil end
	local r = modell.PrimaryPart
	if not r or not r.Parent then return nil end
	return r
end

local function levande(player: Player): boolean
	local k = (player :: any).Character
	local hum = k and k:FindFirstChildOfClass("Humanoid")
	if hum == nil or k:FindFirstChild("HumanoidRootPart") == nil then return false end
	local liv = (hum :: any).Health
	return type(liv) == "number" and liv > 0
end

local function planM(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude / M
end

local function nytt(player: Player): any
	return { userId = player.UserId, lage = "ready", tips = "intro", revision = 0, progress = 0,
		forsokNr = 0, hogsta = 0, svar = {}, ordning = {},
		kontextNr = 0, kModell = nil, kKaraktar = nil, kHastId = nil }
end

function LedLektion.bild(s): any
	local z = LedService.malzon()
	return table.freeze({ typ = "leda", userId = s.userId, forsokNr = s.forsokNr,
		kontextNr = s.kontextNr, hastId = s.kHastId,
		revision = s.revision, sekvens = s.hogsta, lage = s.lage, tips = s.tips,
		progress = s.progress, resultat = s.resultat,
		referens = if z and s.malNyckel then table.freeze({ nyckel = s.malNyckel,
			x = z.x, y = z.y, w = z.w, h = z.h }) else nil })
end

local function sand(player: Player, s)
	local k = Aktor.klient(player)
	if k then Net.get("LedLektionSync"):FireClient(k, LedLektion.bild(s)) end
end

local function andra(s, lage, tips)
	if s.lage == lage and s.tips == tips then return end
	s.lage, s.tips = lage, tips
	s.revision += 1
end

local function satProgress(s, p: number)
	p = math.clamp(math.floor(p), 0, 99)
	if p ~= s.progress then s.progress = p; s.revision += 1 end
end

--[[ Tillbaka till "led henne": all resa och ankomst bort, samma tidsgräns. ]]
local function tillLed(s, tips)
	s.baslinje, s.sistaPos, s.sistaT = false, nil, nil
	s.ledPost, s.karaktar, s.karRot, s.hastRotId = nil, nil, nil, nil
	s.resa, s.ledTid, s.framme = 0, 0, 0
	andra(s, "lead_first", tips)
	satProgress(s, 0)
end

local function stang(player: Player, s, orsak: string)
	if orsak == "slutford" then
		--[[ C1 R1: kontextepoken det slutfördes i (additivt fält), så att
			återkopplingen aldrig tillskriver en senare bunden häst/karaktär
			det här resultatet. ]]
		s.resultat = table.freeze({ userId = s.userId, hastId = s.hastId, forsokNr = s.forsokNr,
			kontextNr = s.kontextNr,
			meter = s.resa, sekunder = s.ledTid, frammeProv = s.framme, malNyckel = s.malNyckel,
			start = s.start, version = LedLektion.VERSION })
		s.progress = 100
		s.revision += 1
		andra(s, "complete", "complete")
	else
		andra(s, "timeout", "timeout")
	end
end

--[[ R2: KONTEXTEN som en ändrande begäran gäller — den bundna MODELLEN
	(instansen, så att en ersättare med samma HorseId räknas som ny) och
	KARAKTÄREN. Ändras någon räknas `kontextNr` upp och bilden går ut. Den
	förnyas vid sync, vid varje begäran och vid varje steg, också utan
	aktivt försök, så att ett byte medan lektionen står i ready/closed/
	complete fångas innan en gammal Start/Retry når fram. Begränsad: två
	referenser och ett tal per spelare. ]]
local function uppdateraKontext(player: Player, s)
	local b = beroenden
	local modell = if b then b.rattHast(player) else nil
	local kar = (player :: any).Character
	if modell ~= s.kModell or kar ~= s.kKaraktar then
		s.kModell, s.kKaraktar = modell, kar
		s.kHastId = if modell then tostring((modell :: Model):GetAttribute("HorseId") or (modell :: Model).Name)
			else nil
		s.kontextNr += 1
		s.revision += 1
	end
end

--[[ Ett prov för en spelares aktiva försök. ]]
local function prov(player: Player, s)
	local b = beroenden
	if not b then return end
	if klocka >= s.deadline then stang(player, s, "tidsgrans"); return end
	local bunden = b.rattHast(player)
	local rot = hastRot(s.modell)
	local nyckel = malNyckel()
	--[[ Identitet och mål först: fel häst, borta häst, byte av bunden häst,
		uppsittning, saknad karaktär eller ändrad målzon nollställer. ]]
	if nyckel == nil then
		--[[ Inget mål: ingen bevisning och ingen guide (referensen blir nil). ]]
		if s.malNyckel ~= nil then s.malNyckel = nil; s.revision += 1 end
		tillLed(s, "target"); return
	end
	if nyckel ~= s.malNyckel then
		--[[ Nytt eller ändrat mål: ny referens till klienten, färsk resa. ]]
		s.malNyckel = nyckel
		s.revision += 1
		tillLed(s, "target"); return
	end
	if bunden ~= s.modell or rot == nil then tillLed(s, "horse"); return end
	if b.rider(player) then tillLed(s, "mounted"); return end
	if not levande(player) then tillLed(s, "character"); return end
	local led = LedService.lage(player)
	if led == nil then
		if s.baslinje then tillLed(s, "released") end
		return
	end
	if led.modell ~= s.modell then tillLed(s, "wrong_horse"); return end
	--[[ R1: SAMMA LEDNINGSSESSION, SAMMA KARAKTÄR, SAMMA HÄSTROT. Varje
		`borja` skapar en NY post i LedService och `slapp` tar bort den; ett
		släpp och ett nytt grepp om samma häst mellan två prov syns bara som
		en annan post. Likaså en ny karaktär (respawn) eller en ny rotdel.
		Allt sådant kastar resa och ankomst och kräver en färsk baslinje
		utanför målet. En paus i samma session är oförändrad. ]]
	local karaktar = (player :: any).Character
	local karRot = karaktar and karaktar:FindFirstChild("HumanoidRootPart")
	if s.baslinje and (led ~= s.ledPost or karaktar ~= s.karaktar or karRot ~= s.karRot
		or rot ~= s.hastRotId) then
		tillLed(s, if led ~= s.ledPost then "released" elseif rot ~= s.hastRotId then "horse" else "character")
		return
	end

	local pos = (rot :: BasePart).Position
	local z = LedService.malzon() :: any
	if not s.baslinje then
		--[[ Baslinje när ledningen av RÄTT häst ses efter Start. Står hon
			redan i målet måste hon ut först. ]]
		if LedService.iRekt(pos, z) then andra(s, "lead_first", "outside_first"); return end
		s.baslinje, s.sistaPos, s.sistaT = true, pos, klocka
		s.ledPost, s.karaktar, s.karRot, s.hastRotId = led, karaktar, karRot, rot
		s.resa, s.ledTid, s.framme = 0, 0, 0
		andra(s, "leading", "lead_on")
		return
	end
	local dt = klocka - (s.sistaT :: number)
	local d = planM(pos, s.sistaPos :: Vector3)
	if dt > LUCKA_S or d > HOPP_M then tillLed(s, "unknown"); return end
	s.sistaPos, s.sistaT = pos, klocka
	s.resa += d
	s.ledTid += dt
	if LedService.iRekt(pos, z) and s.resa >= RESA_M then
		s.framme += 1
		andra(s, "leading", "settle")
		if s.framme >= FRAMME_PROV then stang(player, s, "slutford"); return end
	else
		s.framme = 0
		andra(s, "leading", if s.resa >= RESA_M then "into_arena" else "lead_on")
	end
	satProgress(s, 90 * math.min(s.resa / RESA_M, 1) + 2 * s.framme)
end

function LedLektion._steg(dt: number)
	klocka += dt
	for player, s in pairs(tillstand) do
		local rev = s.revision
		uppdateraKontext(player, s)
		if AKTIVA[s.lage] then prov(player, s) end
		if s.revision ~= rev then sand(player, s) end
	end
end

--[[ `forvantat` (R1): det försöksnummer klienten VISAR när den skickar en
	ändrande begäran; `kontextForv` (R2): den kontext (bunden modell och
	karaktär) som visades med den. Start, Retry och Finish gäller bara om
	båda är serverns nuvarande — annars `stale_attempt` resp.
	`stale_context`, med aktuell bild, utan att röra något. Ett byte av häst
	ändrar INTE försöksnumret (det räknas bara vid Start/Retry), därför
	behövs kontexten. Båda ingår i dubblettkontrollen. ]]
function LedLektion.begar(player: any, op: any, seq: any, forvantat: any,
	kontextForv: any): (boolean, string?, any)
	if typeof(player) ~= "Instance" and type(player) ~= "table" then return false, "request", nil end
	local s = tillstand[player]
	if not s then s = nytt(player); tillstand[player] = s end
	uppdateraKontext(player, s)
	if op == "sync" then return true, nil, LedLektion.bild(s) end
	if op ~= "start" and op ~= "retry" and op ~= "finish" then return false, "unknown", nil end
	if type(seq) ~= "number" or seq ~= seq or seq < 1 or seq > 2147483647 or seq % 1 ~= 0 then
		return false, "request", nil
	end
	if type(forvantat) ~= "number" or forvantat ~= forvantat or forvantat < 0 or forvantat % 1 ~= 0
		or type(kontextForv) ~= "number" or kontextForv ~= kontextForv or kontextForv < 0
		or kontextForv % 1 ~= 0 then
		return false, "request", nil
	end
	local prev = s.svar[seq]
	if prev then
		if prev.op ~= op or prev.forvantat ~= forvantat or prev.kontextForv ~= kontextForv then
			return false, "request", nil
		end
		return prev.ok, prev.fel, prev.bild
	end
	if seq <= s.hogsta then return false, "stale", nil end
	s.hogsta = seq
	local ok, fel = false, nil
	local b = beroenden
	if forvantat ~= s.forsokNr then
		fel = "stale_attempt"
	elseif kontextForv ~= s.kontextNr then
		fel = "stale_context"
	elseif op == "finish" then
		--[[ Avsluta rör aldrig hästen eller kopplet. ]]
		ok = true
		andra(s, "closed", "closed")
	elseif AKTIVA[s.lage] then
		fel = "active"
	elseif op == "retry" and s.lage ~= "complete" and s.lage ~= "timeout" then
		fel = "request"
	elseif op == "start" and s.lage ~= "ready" and s.lage ~= "closed" then
		fel = "request"
	elseif not b then
		fel = "target"
	else
		local modell = s.kModell -- den kontext som just prövades
		local rot = hastRot(modell)
		local z = LedService.malzon()
		if z == nil then fel = "target"
		elseif modell == nil or rot == nil then fel = "horse"
		elseif b.rider(player) then fel = "mounted"
		elseif not levande(player) then fel = "character"
		elseif LedService.iRekt((rot :: BasePart).Position, z) then fel = "inside"
		else
			ok = true
			s.forsokNr += 1
			s.modell = modell
			s.hastId = tostring((modell :: Model):GetAttribute("HorseId") or (modell :: Model).Name)
			s.malNyckel = malNyckel()
			s.deadline, s.start = klocka + DEADLINE, klocka
			s.resultat = nil
			tillLed(s, "lead_first")
			s.revision += 1
			--[[ Leder hon redan RÄTT häst tas baslinjen nu. ]]
			prov(player, s)
		end
	end
	local bild = LedLektion.bild(s)
	s.svar[seq] = { op = op, forvantat = forvantat, kontextForv = kontextForv, ok = ok, fel = fel,
		bild = bild }
	table.insert(s.ordning, seq)
	while #s.ordning > MAX_REQUESTS do s.svar[table.remove(s.ordning, 1)] = nil end
	return ok, fel, bild
end

function LedLektion.lamnar(player: Player)
	tillstand[player] = nil
end

--[[ `deps.rattHast(player)` → spelarens bundna häst; `deps.rider(player)` →
	sitter spelaren upp. Kopplas av GameplayService, som äger båda svaren. ]]
local kopplad = false
function LedLektion.start(deps: Beroenden)
	beroenden = deps
	Net.get("LedLektion").OnServerInvoke = Skopa.grind("LedLektion", LedLektion.begar)
	--[[ En gång: startas tjänsten om (bänken) kopplas inga dubbla steg. ]]
	if kopplad then return end
	kopplad = true
	Players.PlayerRemoving:Connect(LedLektion.lamnar)
	RunService.Heartbeat:Connect(function(dt)
		ackum += dt
		if ackum < STEG_S then return end
		local d = ackum
		ackum = 0
		LedLektion._steg(d)
	end)
end

--[[ Provkrokar. ]]
function LedLektion._tillstandForProv(player: Player): any
	return tillstand[player]
end

function LedLektion._glomForProv()
	tillstand = {}
	klocka, ackum = 0, 0
end

return LedLektion
