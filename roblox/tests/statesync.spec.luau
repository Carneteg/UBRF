--!nostrict
--[[
	STATESYNC -- #169 P1, migrerad i #233 Fas 4b.

	URSPRUNGET. `onStateSync(player, gait, speed)` provade typ, kant
	gangartsnamn och ett tempospann, och skrev sedan BADA rakt in i de
	replikerade attributen. `stepStamina` laste `Gait`-attributet och
	raknade trottheten ur det. Tva hal foljde:

	1. En modifierad klient kunde saga `gait = "halt"` medan hasten
	   galopperade, och fa ATERHAMTNING at en hast i full fart.
	2. Ingen takt-grans fanns; klienten bestamde sjalv hur ofta den skrev.

	FAS 4b tog bort ett tredje hal som #239:s audit matte upp: servern hade
	inget minne av foregaende gangart och kunde darfor inte validera en
	OVERGANG, bara ett varde. `halt -> canter` i ett hopp passerade.

	Remoten bar nu ETT argument -- farten -- och gangarten ar serverns.
	Specen mater darfor tre saker:

	  · att den arliga fartsynken gar igenom oforandrad och i 10 Hz,
	  · att StateSync inte langre kan rora gangarten, oavsett anrop,
	  · att #169 P1:s regler overlever migrationen: takten, avsandaren,
	    ryttarbytet, och att serverns EGEN matning av farten fortfarande
	    driver trottheten.

	Den forsta halvan ar minst lika viktig som spoofarna -- en grind som
	stryper legitim synk laser som trasig styrning, och hade plockats bort
	i stallet for justerats.

	Stegmaskinen, impulssparren och avsikten mats i `ridinput.spec`.

	Kor: python3 roblox/tests/build.py tests/statesync.spec.luau
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
	här, men `OnServerEvent` är samma signal tjänsten lyssnar på.

	ETT ARGUMENT SEDAN #233 FAS 4b. Remoten bar förut paret
	(gångart, tempo), och gångarten på tråden var serverns enda källa till
	vilken gångart hästen var i. Den går inte att skicka längre — se
	`Networking.DEFINITIONS` för varför det är strukturellt och inte en
	regel som kan glömmas bort. ]]
local function sync(spelare, speed)
	Networking.get("StateSync").OnServerEvent:Fire(spelare, speed)
end

--[[ Sätter serverns ACCEPTERADE gångart. Det här är UPPSTÄLLNING, inte
	mätning: den riktiga vägen dit är `RidingIntent`, och den mäts i
	`ridinput.spec` genom produktionens remote. Här behövs bara ett
	utgångsläge att pröva fartvägen mot, och att stega dit genom
	impulsspärren hade lagt sekunder på sviten utan att mäta något den
	här specen handlar om. ]]
local function accepteradGangart(sess, namn)
	sess.stegIndex = Gaits.index(namn)
	--[[ Attributet är serverns REPLIKERING av trappan, och de två ska
	     aldrig stå isär. Sattes bara indexet hade attributet slumpvis
	     burit ett gammalt värde, och ett prov som läser det hade mätt
	     uppställningen i stället för koden. ]]
	sess.rig.model:SetAttribute("Gait", Ridtrappa.gangart(sess.stegIndex))
	sess.rig.model:SetAttribute("Ryggar", Ridtrappa.ryggar(sess.stegIndex))
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
	accepteradGangart(session, "trot")
	sync(spelare, 3.2)
	check("vanlig synk skriver tempot",
		math.abs((modell:GetAttribute("Speed") or 0) - 3.2) < 1e-6,
		tostring(modell:GetAttribute("Speed")))
	check("och ror inte gangarten - den ar serverns",
		modell:GetAttribute("Gait") == "trot",
		tostring(modell:GetAttribute("Gait")))
end

do
	--[[ BACKNINGEN. Hon ryggar i halt med tempo -ReverseSpeed. En
		konsistensregel pa `math.abs(speed)` hade nekat varje legitim
		backning, och den foll skarpt en gang redan (#239). Raden finns for
		att fanga just den regressionen.

		SKILLNADEN MOT FORE FAS 4b: det ar inte langre klientens etikett som
		avgor om negativt tempo ar tillatet, utan serverns egen
		ryggningspinne. Klienten kan inte langre oppna backningen at sig
		sjalv genom att kalla sig "halt". ]]
	session.stegIndex = Ridtrappa.RYGGA
	sync(spelare, -1.1)
	check("ryggning: negativt tempo accepteras nar SERVERN sager rygga",
		math.abs((modell:GetAttribute("Speed") or 0) + 1.1) < 1e-6,
		tostring(modell:GetAttribute("Speed")))

	--[[ Och motsatsen: samma negativa tempo nar servern INTE accepterat
		ryggning ar ett pastaende utan tackning. Det klampas till noll i
		stallet for att skrivas -- hasten backar inte for att klienten sager
		att hon gor det. ]]
	accepteradGangart(session, "walk")
	sync(spelare, -1.1)
	check("men inte nar servern star i skritt",
		math.abs(modell:GetAttribute("Speed") or -1) < 1e-6,
		tostring(modell:GetAttribute("Speed")))
end

do
	--[[ Tio i sekunden ar den normala takten - alltsa 0,1 s MELLAN varje.
		Alla ska igenom, annars kanns styrningen trasig. ]]
	vanta(0.5)
	accepteradGangart(session, "walk")
	local igenom = 0
	for _ = 1, 10 do
		modell:SetAttribute("Speed", 0)
		sync(spelare, 1.45)
		if math.abs((modell:GetAttribute("Speed") or 0) - 1.45) < 1e-6 then igenom += 1 end
		vanta(0.1)
	end
	check("normal 10 Hz-synk stryps inte", igenom == 10, ("%d av 10"):format(igenom))
end

print("\n-- Spoof: serverns gangart ar halt medan hasten galopperar --")

do
	--[[ Regeln ar #169 P1:s, och den overlever Fas 4b oforandrad. Den ar
		inte overflodig bara for att gangarten blivit serverns: ryttaren har
		fortfarande natverksagarskapet, sa en manipulerad klient kan flytta
		hasten fysiskt utan att skicka en enda avsikt. Trappan sager vad
		ryttaren BEGART och fatt, inte hur fort hon ror sig. ]]
	accepteradGangart(session, "halt")
	sync(spelare, 0)
	local fore = session.energi
	--[[ Ingen ny synk mellan hjartslagen. Hasten FLYTTAS daremot -- 2,0
		studs pa 0,30 s ar 6,7 studs/s, alltsa canter. ]]
	hjartslag(0.30)              -- nollstaller matpunkten
	flytta(modell, 2.0)
	hjartslag(0.30)
	local efter = session.energi
	check("en hast som ror sig fort tappar energi trots att servern star i halt",
		efter < fore, ("energi %.5f -> %.5f"):format(fore, efter))
end

do
	--[[ KONTROLLPROVET. Utan det bevisar raden ovan bara att energin
		sjunker - inte att det var RORELSEN som gjorde det. ]]
	accepteradGangart(session, "halt")
	sync(spelare, 0)
	hjartslag(0.30)
	local fore = session.energi
	hjartslag(0.30)              -- ingen forflyttning
	local efter = session.energi
	check("en hast som verkligen star still tappar inte energi", efter >= fore,
		("energi %.5f -> %.5f"):format(fore, efter))
end

print("\n-- StateSync kan inte langre rora gangarten --")

do
	--[[ KARNAN I FAS 4b, och den regel hela migrationen finns for.

		FORE: `StateSync("canter", 5.6)` skrev bade gangart och tempo rakt in
		i de replikerade attributen. Servern hade inget minne av foregaende
		gangart och kunde darfor inte validera en OVERGANG -- bara ett varde.
		`halt -> canter` i ett hopp passerade sa lange tempot foljde med.

		EFTER: gangarten finns inte pa traden. Det aldre anropet har ett
		STRANGVARDE dar farten ska sta, och faller pa typkontrollen utan att
		lamna spar. ]]
	accepteradGangart(session, "halt")
	modell:SetAttribute("Speed", 0)

	--[[ Exakt det anrop en manipulerad gammal klient hade gjort. ]]
	Networking.get("StateSync").OnServerEvent:Fire(spelare, "canter", 5.6)
	check("manipulerad gammal StateSync('canter', giltig fart) byter inte gangart",
		modell:GetAttribute("Gait") == "halt",
		tostring(modell:GetAttribute("Gait")))
	check("och skriver ingen fart heller - anropet foll helt",
		math.abs(modell:GetAttribute("Speed") or -1) < 1e-6,
		tostring(modell:GetAttribute("Speed")))
	check("serverns egen trappa star kvar i halt",
		session.stegIndex == Gaits.index("halt"),
		("stegIndex %d"):format(session.stegIndex))
end

print("\n-- Farten klampas mot serverns gangart, inte mot klientens --")

do
	--[[ Regeln var "tempot maste ligga i den PASTADDA gangartens band".
		Den pastadda gangarten finns inte langre, och det ar en skarpning:
		bandet kommer nu ur den gangart servern sjalv accepterat.

		KLAMPAS, INTE NEKAS. Under en overgang passerar tempot legitimt genom
		grannbandet -- hon accelererar upp genom skrittfarten pa vag in i
		traven -- och ett avslag dar hade fruset `Speed` mitt i varje
		uppstegring. ]]
	accepteradGangart(session, "walk")
	sync(spelare, 9.0)
	local s = modell:GetAttribute("Speed") or 0
	check("galopptempo under en skrittgangart klampas ned i skrittens band",
		s <= Gaits.BY_NAME.walk.max + Gaits.HYSTERESIS + 1e-9,
		("speed=%.2f, tak %.2f"):format(s, Gaits.BY_NAME.walk.max + Gaits.HYSTERESIS))

	--[[ Och det legitima fallet mitt i en uppstegring far inte strypas. ]]
	accepteradGangart(session, "trot")
	sync(spelare, 2.0)
	check("tempo pa vag upp i bandet skrivs oforandrat",
		math.abs((modell:GetAttribute("Speed") or 0) - 2.0) < 1e-6,
		tostring(modell:GetAttribute("Speed")))
end

print("\n-- NaN, oandligheter och fel typ --")

do
	local function nekas(namn, speed)
		accepteradGangart(session, "walk")
		modell:SetAttribute("Speed", 1.45)
		sync(spelare, speed)
		check(namn, math.abs((modell:GetAttribute("Speed") or 0) - 1.45) < 1e-6,
			("speed=%s"):format(tostring(modell:GetAttribute("Speed"))))
	end
	nekas("NaN-tempo nekas", 0 / 0)
	nekas("+oandligt tempo nekas", math.huge)
	nekas("-oandligt tempo nekas", -math.huge)
	nekas("tempo langt over allt hasten kan gora nekas", 99)
	nekas("tempo langt under nekas", -50)
	nekas("tempo som inte ar ett tal nekas", "3.2")
	nekas("tempo som ar en tabell nekas", {})
	nekas("inget argument alls nekas", nil)
end

print("\n-- Takten --")

do
	--[[ Skopan rymmer RATE_TAK och fylls pa i efterhand. En burst utan
		tidsgang ska darfor ta slut - annars finns ingen grans alls. ]]
	vanta(0.5)                   -- full skopa att tomma
	accepteradGangart(session, "walk")
	local accepterade = 0
	for _ = 1, 200 do
		modell:SetAttribute("Speed", 0)
		sync(spelare, 1.45)
		if math.abs((modell:GetAttribute("Speed") or 0) - 1.45) < 1e-6 then
			accepterade += 1
		end
	end
	check("spam skriver INTE 200 ganger", accepterade < 200,
		("%d av 200 skrevs"):format(accepterade))
	check("men nagot kom igenom - grinden ar inte en total blockering",
		accepterade > 0, ("%d"):format(accepterade))
end

print("\n-- Avsandaren --")

do
	local frammande = { Name = "Ingen", UserId = 999, Character = nil }
	accepteradGangart(session, "walk")
	modell:SetAttribute("Speed", 1.45)
	sync(frammande, 8.6)
	check("en som inte rider hasten kan inte skriva dess fart",
		math.abs((modell:GetAttribute("Speed") or 0) - 1.45) < 1e-6,
		tostring(modell:GetAttribute("Speed")))
	check("och inte dess gangart heller",
		modell:GetAttribute("Gait") == "walk",
		tostring(modell:GetAttribute("Gait")))
end

print("\n-- Ryttarbytet stadar synktillstandet --")

do
	--[[ Tom skopan med den forra ryttaren. ]]
	for _ = 1, 200 do sync(spelare, 1.45) end
	local tomFore = session.polletter < 1
	check("skopan ar tom efter spam", tomFore,
		("polletter %.2f"):format(session.polletter))

	local okAv = HorseService.dismount(spelare)
	check("avsittningen gar igenom", okAv == true)

	--[[ En stale synk fran den gamla ryttaren far inte langre skriva. ]]
	modell:SetAttribute("Speed", 0)
	sync(spelare, 5.6)
	check("gammal ryttares synk biter inte efter avsittning",
		math.abs(modell:GetAttribute("Speed") or -1) < 1e-6,
		tostring(modell:GetAttribute("Speed")))

	--[[ AVSITTNINGEN LAMNAR HENNE I HALT. `stannaHast` stegar serverns
		trappa till halt och replikerar det; skrevs bara attributen hade
		sessionen fortsatt tro att hon travade, och nasta BROMS hade stegat
		ned fran trav pa en hast som redan stod still. ]]
	check("och serverns trappa star i halt efter avsittningen",
		session.stegIndex == Gaits.index("halt"),
		("stegIndex %d"):format(session.stegIndex))

	local ny = { Name = "Nasta", UserId = 202, Character = (nyKaraktar(vec(6, 0, 0))),
		CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }
	Players._spelare = { ny }
	local okNy = HorseService.tryMount(ny, modell)
	check("nasta ryttare sitter upp", okNy == true)
	check("den nya ryttaren arver INTE en tom skopa",
		session.polletter >= 1, ("polletter %.2f"):format(session.polletter))
	check("och ingen gammal matpunkt ligger kvar", session.observerad == 0,
		("observerad %.3f"):format(session.observerad))

	--[[ RITTEN BORJAR I HALT, och sekvensraknaren borjar om. Utan
		nollstallningen bar sessionen kvar den forra ryttarens raknare, och
		nasta ryttares arliga `sekvens = 1` hade lasts som ett aterspelat
		paket och tyst kastats. ]]
	check("ritten borjar i halt for den nya ryttaren",
		session.stegIndex == Gaits.index("halt"),
		("stegIndex %d"):format(session.stegIndex))
	check("och sekvensraknaren ar nollad",
		session.sekvens == 0, ("sekvens %s"):format(tostring(session.sekvens)))

	accepteradGangart(session, "walk")
	modell:SetAttribute("Speed", 0)
	sync(ny, 1.45)
	check("den nya ryttarens forsta synk gar igenom direkt",
		math.abs((modell:GetAttribute("Speed") or 0) - 1.45) < 1e-6,
		tostring(modell:GetAttribute("Speed")))
end

if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("\nstatesync.spec: alla gröna")
end
