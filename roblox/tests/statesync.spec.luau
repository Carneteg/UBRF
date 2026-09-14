--!nostrict
--[[
	STATESYNC-AUKTORITET — #169 P1.

	Auditen: `onStateSync(player, gait, speed)` prövade typ, känt gångartsnamn
	och ett tempospann, och skrev sedan båda RAKT in i replikerade attribut.
	`stepStamina` läste `Gait`-attributet och räknade tröttheten ur det.

	Två hål följde av det.

	1. En modifierad klient kunde säga `gait = "halt"` medan hästen
	   galopperade. Servern gav då ÅTERHÄMTNING åt en häst i full fart — och
	   gjorde det tyst, eftersom ingen mätte vad hästen faktiskt gjorde.

	2. Ingen takt-gräns fanns. Varje accepterad händelse skrev två
	   replikerade attribut, och klienten bestämde själv hur ofta.

	Specen provar båda riktningarna: att den ärliga ritten går igenom
	oförändrad, och att varje spoof faller. Den första halvan är minst lika
	viktig — en grind som stryper legitim synk läser som trasig styrning, och
	hade plockats bort i stället för justerats.

	Kör: python3 roblox/tests/build.py tests/statesync.spec.luau
	     && luau roblox/tests/.build/statesync.spec.luau
]]

local fails = 0
local function check(namn, villkor, detalj)
	if villkor then
		print(string.format("  OK   %s%s", namn, detalj and ("  " .. detalj) or ""))
	else
		fails += 1
		print(string.format("  FEL  %s%s", namn, detalj and ("  " .. detalj) or ""))
	end
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Taggar = game:GetService("CollectionService")

local vec = Vector3.new

--[[ ── En häst och en ryttare, utan skötselkedjan ────────────────────────
	`setMountGate` är oregistrerad här, och då släpper `tryMount` igenom —
	tjänstens egen dokumenterade regel ("ingen grind registrerad = ingen
	förändring"). Det håller specen på DET den mäter: auktoriteten över
	StateSync, inte förberedelsens faser. ]]
local HAST_ID = "blackrock_jack"

local function nyKaraktar(pos)
	local k = Instance.new("Model")
	k.Name = "Karaktar"
	local rot = Instance.new("Part")
	rot.Name = "HumanoidRootPart"
	rot.Size = vec(2, 2, 1)
	rot.CFrame = CFrame.new(pos)
	rot.Parent = k
	local hum = Instance.new("Humanoid")
	hum.Name = "Humanoid"
	hum.Parent = k
	local anim = Instance.new("Animator")
	anim.Name = "Animator"
	anim.Parent = hum
	return k, rot, hum
end

local function nyVarld(namn, userId)
	Taggar:nollstall()
	RunService._server = true
	RunService.Heartbeat:nollstall()
	Players._spelare = {}

	local k, rot, hum = nyKaraktar(vec(6, 0, 0))
	--[[ Signalerna är inte dekor: `tryMount` kopplar städningen till
		`CharacterRemoving`, och utan dem kraschar uppsittningen. ]]
	local spelare = { Name = namn, UserId = userId, Character = k,
		CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }
	Players._spelare = { spelare }

	HorseService.setMountGate(nil)
	HorseService.start()

	local modell = HastRigg.bygg(HAST_ID, "Blackrock Jack", CFrame.new(vec(0, 0, 0)))
	modell.Parent = workspace
	Taggar:AddTag(modell, "Horse")
	return spelare, modell
end

--[[ Fyrar remoten precis som klienten gör: `FireServer` går inte att nå
	här, men `OnServerEvent` är samma signal tjänsten lyssnar på. ]]
local function sync(spelare, gait, speed)
	Networking.get("StateSync").OnServerEvent:Fire(spelare, gait, speed)
end

--[[ VÄNTAR RIKTIG TID.

	Takten mäts mot `os.clock()`, och skopan fylls på i efterhand. Ett prov
	som fyrar tio händelser i en tight slinga mäter därför en BURST, inte
	10 Hz — och första versionen av den här specen gjorde precis det och
	fällde sin egen kod för något den inte gjorde.

	Väntan är kort och sker bara i takt-proven. Alternativet — att låta
	specen mata in en egen klocka — hade krävt en testväg i produktionen,
	och då hade provet mätt testvägen. ]]
local function vanta(sekunder)
	local slut = os.clock() + sekunder
	while os.clock() < slut do end
end

--[[ Ett hjärtslag som FAKTISKT når uthålligheten: loopen samlar ihop tid
	och gör ingenting under 0,25 s. ]]
local function hjartslag(dt)
	RunService.Heartbeat:Fire(dt or 0.30)
end

--[[ Flyttar hästen i världen — alltså det servern MÄTER. Ingen attribut
	sätts här; det är hela poängen. ]]
local function flytta(modell, dx)
	local p = modell.PrimaryPart
	p.CFrame = CFrame.new(p.CFrame.Position + vec(dx, 0, 0))
end

print("\n── Den ärliga ritten går igenom oförändrad ──")

local spelare, modell = nyVarld("Ryttare", 101)
local okM = HorseService.tryMount(spelare, modell)
check("ryttaren sitter upp", okM == true)
local session = HorseService.sessionFor(modell)
check("sessionen finns", session ~= nil)

do
	sync(spelare, "trot", 3.2)
	check("vanlig synk skriver gångarten", modell:GetAttribute("Gait") == "trot",
		tostring(modell:GetAttribute("Gait")))
	check("och tempot", math.abs((modell:GetAttribute("Speed") or 0) - 3.2) < 1e-6,
		tostring(modell:GetAttribute("Speed")))
end

do
	--[[ BACKNINGEN. `MovementController` backar med `targetGait == "halt"`
		och tempo −ReverseSpeed. En konsistensregel på `math.abs(speed)`
		hade nekat varje legitim backning — den här raden finns för att
		fånga just den regressionen. ]]
	sync(spelare, "halt", -1.1)
	check("backning i halt med negativt tempo accepteras",
		modell:GetAttribute("Gait") == "halt"
			and math.abs((modell:GetAttribute("Speed") or 0) + 1.1) < 1e-6,
		("gait=%s speed=%s"):format(tostring(modell:GetAttribute("Gait")),
			tostring(modell:GetAttribute("Speed"))))
end

do
	--[[ Tio i sekunden är den normala takten — alltså 0,1 s MELLAN varje.
		Alla ska igenom, annars känns styrningen trasig. ]]
	vanta(0.5)
	local igenom = 0
	for _ = 1, 10 do
		modell:SetAttribute("Gait", "halt")
		sync(spelare, "walk", 1.45)
		if modell:GetAttribute("Gait") == "walk" then igenom += 1 end
		vanta(0.1)
	end
	check("normal 10 Hz-synk stryps inte", igenom == 10, ("%d av 10"):format(igenom))
end

print("\n── Spoof: 'halt' medan hästen faktiskt galopperar ──")

do
	sync(spelare, "halt", 0)
	local fore = session.energi
	--[[ Ingen ny synk mellan hjärtslagen: attributet står kvar på "halt",
		precis som en fuskklient hade lämnat det. Hästen FLYTTAS däremot —
		2,0 studs på 0,30 s är 6,7 studs/s, alltså canter. ]]
	hjartslag(0.30)              -- nollställer mätpunkten
	flytta(modell, 2.0)
	hjartslag(0.30)
	local efter = session.energi
	check("en häst som rör sig fort tappar energi trots att klienten säger halt",
		efter < fore, ("energi %.5f → %.5f"):format(fore, efter))
end

do
	--[[ KONTROLLPROVET. Utan det bevisar raden ovan bara att energin
		sjunker — inte att det var RÖRELSEN som gjorde det. ]]
	sync(spelare, "halt", 0)
	hjartslag(0.30)
	local fore = session.energi
	hjartslag(0.30)              -- ingen förflyttning
	local efter = session.energi
	check("en häst som verkligen står still tappar inte energi", efter >= fore,
		("energi %.5f → %.5f"):format(fore, efter))
end

print("\n── Paret gångart/tempo måste hänga ihop ──")

do
	modell:SetAttribute("Gait", "trot")
	modell:SetAttribute("Speed", 3.2)
	sync(spelare, "halt", 9.0)
	check("halt med galopptempo skrivs inte",
		modell:GetAttribute("Gait") == "trot",
		("gait=%s"):format(tostring(modell:GetAttribute("Gait"))))

	sync(spelare, "gallop", 0.1)
	check("gallop med stillastående tempo skrivs inte",
		modell:GetAttribute("Gait") == "trot",
		("gait=%s"):format(tostring(modell:GetAttribute("Gait"))))
end

print("\n── Taket ──")

do
	modell:SetAttribute("GaitCeiling", "trot")
	sync(spelare, "canter", 5.6)
	check("gångart över taket sänks till taket",
		modell:GetAttribute("Gait") == "trot",
		tostring(modell:GetAttribute("Gait")))
	--[[ Servern får inte själv skriva det par den nekar klienten: ett
		cantertempo under en travetikett är samma motsägelse. ]]
	local s = modell:GetAttribute("Speed") or 0
	check("och tempot följer med ned i takets band",
		s >= Gaits.BY_NAME.trot.min and s <= Gaits.BY_NAME.trot.max,
		("speed=%.2f"):format(s))
	modell:SetAttribute("GaitCeiling", Gaits.SPELBAR_TOPP)
end

print("\n── NaN, oändligheter och gränser ──")

do
	local function nekas(namn, gait, speed)
		modell:SetAttribute("Gait", "walk")
		modell:SetAttribute("Speed", 1.45)
		sync(spelare, gait, speed)
		check(namn, modell:GetAttribute("Gait") == "walk"
			and math.abs((modell:GetAttribute("Speed") or 0) - 1.45) < 1e-6,
			("gait=%s speed=%s"):format(tostring(modell:GetAttribute("Gait")),
				tostring(modell:GetAttribute("Speed"))))
	end
	nekas("NaN-tempo nekas", "trot", 0 / 0)
	nekas("+oändligt tempo nekas", "trot", math.huge)
	nekas("−oändligt tempo nekas", "trot", -math.huge)
	nekas("tempo över taket nekas", "gallop", 99)
	nekas("tempo långt under nekas", "walk", -50)
	nekas("okänd gångart nekas", "hoppgalopp", 3.2)
	nekas("gångart som inte är en sträng nekas", 7, 3.2)
	nekas("tempo som inte är ett tal nekas", "trot", "3.2")
end

print("\n── Takten ──")

do
	--[[ Skopan rymmer RATE_TAK och fylls på i efterhand. En burst utan
		tidsgång ska därför ta slut — annars finns ingen gräns alls. ]]
	vanta(0.5)                   -- full skopa att tömma
	modell:SetAttribute("Gait", "halt")
	local accepterade = 0
	for _ = 1, 200 do
		modell:SetAttribute("Gait", "halt")
		sync(spelare, "walk", 1.45)
		if modell:GetAttribute("Gait") == "walk" then accepterade += 1 end
	end
	check("spam skriver INTE 200 gånger", accepterade < 200,
		("%d av 200 skrevs"):format(accepterade))
	check("men något kom igenom — grinden är inte en total blockering",
		accepterade > 0, ("%d"):format(accepterade))
end

print("\n── Avsändaren ──")

do
	local frammande = { Name = "Ingen", UserId = 999, Character = nil }
	modell:SetAttribute("Gait", "walk")
	sync(frammande, "gallop", 8.6)
	check("en som inte rider hästen kan inte skriva dess gångart",
		modell:GetAttribute("Gait") == "walk",
		tostring(modell:GetAttribute("Gait")))
end

print("\n── Ryttarbytet städar synktillståndet ──")

do
	--[[ Töm skopan med den förra ryttaren. ]]
	for _ = 1, 200 do sync(spelare, "walk", 1.45) end
	local tomFore = session.polletter < 1
	check("skopan är tom efter spam", tomFore,
		("polletter %.2f"):format(session.polletter))

	local okAv = HorseService.dismount(spelare)
	check("avsittningen går igenom", okAv == true)

	--[[ En stale synk från den gamla ryttaren får inte längre skriva. ]]
	modell:SetAttribute("Gait", "halt")
	sync(spelare, "canter", 5.6)
	check("gammal ryttares synk biter inte efter avsittning",
		modell:GetAttribute("Gait") == "halt",
		tostring(modell:GetAttribute("Gait")))

	local ny = { Name = "Nasta", UserId = 202, Character = (nyKaraktar(vec(6, 0, 0))),
		CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }
	Players._spelare = { ny }
	local okNy = HorseService.tryMount(ny, modell)
	check("nästa ryttare sitter upp", okNy == true)
	check("den nya ryttaren ärver INTE en tom skopa",
		session.polletter >= 1, ("polletter %.2f"):format(session.polletter))
	check("och ingen gammal mätpunkt ligger kvar", session.observerad == 0,
		("observerad %.3f"):format(session.observerad))

	sync(ny, "walk", 1.45)
	check("den nya ryttarens första synk går igenom direkt",
		modell:GetAttribute("Gait") == "walk",
		tostring(modell:GetAttribute("Gait")))
end

if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("\nstatesync.spec: alla gröna")
end
