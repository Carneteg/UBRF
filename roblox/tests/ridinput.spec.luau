--!nostrict
--[[
	SERVERAUKTORITATIV RIDINPUT — #233 Fas 4b.

	BAKGRUNDEN, ur post-merge-auditen på #239. Klienten räknade fram sin
	gångart, skickade RESULTATET `StateSync(gait, speed)`, och servern
	prövade om paret var rimligt. Tre hål följde:

	  · avsikten fanns aldrig på tråden — bara utfallet,
	  · servern hade inget minne av föregående gångart och kunde därför
	    inte validera en ÖVERGÅNG, bara ett värde: `halt → canter` i ett
	    hopp passerade så länge tempot följde med,
	  · takten mättes som paket per sekund, aldrig som hjälper.

	Nu skickar klienten `driv` eller `broms`. Servern stegar sin egen
	trappa, validerar, och replikerar utfallet.

	SPECEN GÅR GENOM PRODUKTIONENS REMOTES. `FireServer` går inte att nå i
	bänken, men `OnServerEvent` är samma signal `HorseService` lyssnar på,
	och servern kopplar den i sin egen `start()`. Ingen av mätningarna
	nedan anropar en intern funktion direkt.

	VAD SOM INTE MIGRERAS, och som ska stå här så att ingen tror något
	annat: hästen rör sig fortfarande av ryttarens klient via
	`SetNetworkOwner`. Det här är en auktoritetsmigration för GÅNGARTEN,
	inte en fysikmigration. En manipulerad klient kan alltjämt flytta
	hästen — men den kan inte längre få servern att kalla det galopp.

	Kör: python3 roblox/tests/build.py tests/ridinput.spec.luau
	     && luau roblox/tests/.build/ridinput.spec.luau
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

--[[ Karaktären placeras med flit: `tryMount` har en `MountRange` på 14
     studs, och en ryttare som ställs för långt bort faller på
     `hast.for_langt` innan provet hunnit mäta något. ]]
local function nySpelare(namn, userId, pos)
	return { Name = namn, UserId = userId, Character = (nyKaraktar(pos or vec(6, 0, 0))),
		CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }
end

local function nyVarld()
	Taggar:nollstall()
	RunService._server = true
	RunService.Heartbeat:nollstall()
	Players._spelare = {}

	local spelare = nySpelare("Ryttare", 101)
	Players._spelare = { spelare }

	HorseService.setMountGate(nil)
	HorseService.start()

	local modell = HastRigg.bygg(HAST_ID, "Blackrock Jack", CFrame.new(vec(0, 0, 0)))
	modell.Parent = workspace
	Taggar:AddTag(modell, "Horse")
	return spelare, modell
end

--[[ Produktionens väg in. Klienten gör `FireServer(handling, sekvens)`;
     `OnServerEvent` är samma signal på andra sidan. ]]
--[[ Rittmarket som klienten fick i uppsittningshandskakningen. Provet
     haller det i en egen variabel av samma skal klienten gor det: ett
     paket utan ratt marke ska inte na nagon ritt. ]]
local rittMarke = nil

local function avsikt(spelare, handling, sekvens, marke)
	Networking.get("RidingIntent").OnServerEvent:Fire(
		spelare, if marke ~= nil then marke else rittMarke, handling, sekvens)
end

--[[ VÄNTAR RIKTIG TID. Impulsspärren mäts mot `os.clock()` på servern.
     Att mata in en egen klocka hade krävt en testväg i produktionen, och
     då hade provet mätt testvägen. ]]
local function vanta(sekunder)
	local slut = os.clock() + sekunder
	while os.clock() < slut do end
end

--[[ Ett steg UTAN att vänta ut spärren.

     Det här är UPPSTÄLLNING, inte mätning. Spärren har ett eget block
     nedan som mäter den med riktig tid genom samma remote; att vänta ut
     den för varje uppställningssteg hade lagt ett tiotal sekunder på
     sviten utan att mäta något nytt.

     Sekvensen lämnas `nil` med flit: återspelningsregeln har också ett
     eget block, och en uppställning ska inte behöva hålla reda på en
     räknare som hör till ett annat prov. ]]
local function steg(spelare, sess, handling)
	sess.sisteHjalp = -math.huge
	sess.intentPolletter = Config.RIDINPUT.SkopaTak
	avsikt(spelare, handling, nil)
end

local function gangart(sess)
	return Ridtrappa.gangart(sess.stegIndex)
end

print("\n== Trappan: ett steg, aldrig tva ==")

local spelare, modell = nyVarld()
--[[ Tredje vardet ur handskakningen ar RITTMARKET (ChatGPT-review av
     #241). Provet tar emot det precis som klienten gor, och skickar det
     med varje avsikt. ]]
local okUpp, _skal, marke = HorseService.tryMount(spelare, modell)
rittMarke = marke
check("ryttaren sitter upp", okUpp == true)
check("och handskakningen lamnade ett rittmarke",
	typeof(rittMarke) == "string" and #rittMarke > 0, tostring(rittMarke))
local session = HorseService.sessionFor(modell)
check("sessionen finns", session ~= nil)

do
	--[[ 1. halt + DRIV -> walk ]]
	check("ritten borjar i halt", gangart(session) == "halt", gangart(session))
	steg(spelare, session, "driv")
	check("1. halt + DRIV ger skritt", gangart(session) == "walk", gangart(session))
	check("och det replikeras pa hasten",
		modell:GetAttribute("Gait") == "walk",
		tostring(modell:GetAttribute("Gait")))

	--[[ 2. walk + DRIV -> trot, ALDRIG direkt canter.

	     Det har ar hela overgangsregeln. Fore Fas 4b kunde en manipulerad
	     klient skicka `StateSync("canter", 5.6)` ur halt och servern hade
	     skrivit det: den hade inget minne att jamfora mot. ]]
	steg(spelare, session, "driv")
	check("2. skritt + DRIV ger trav, inte galopp",
		gangart(session) == "trot", gangart(session))
end

do
	--[[ 3. canter + BROMS -> trot ]]
	steg(spelare, session, "driv")
	check("uppe i galopp", gangart(session) == "canter", gangart(session))
	steg(spelare, session, "broms")
	check("3. galopp + BROMS ger trav", gangart(session) == "trot", gangart(session))
end

do
	--[[ 4. halt + BROMS -> rygga, och DRIV tillbaka -> halt.

	     Ryggningen ar en PINNE UNDER halt och har ingen egen gangartsrad:
	     hon ryggar i halt. Det ar `Ryggar` som bar pinnen, och den ar
	     replikerad sedan Fas 4b -- forut bars den bara av den ridande
	     klientens egen flagga, och en askadare kunde inte se skillnad pa
	     en hast som stod still och en som backade. ]]
	steg(spelare, session, "broms")
	steg(spelare, session, "broms")
	check("nere i halt igen", gangart(session) == "halt", gangart(session))

	steg(spelare, session, "broms")
	check("4. halt + BROMS ger ryggning",
		Ridtrappa.ryggar(session.stegIndex), ("stegIndex %d"):format(session.stegIndex))
	check("och hon ryggar i HALT - etiketten foljer med ned i pinnen",
		gangart(session) == "halt", gangart(session))
	check("ryggningen ar replikerad for askadare",
		modell:GetAttribute("Ryggar") == true,
		tostring(modell:GetAttribute("Ryggar")))

	steg(spelare, session, "driv")
	check("4b. ett DRIV ur rygga ger halt, inte skritt",
		gangart(session) == "halt" and not Ridtrappa.ryggar(session.stegIndex),
		("%s, ryggar=%s"):format(gangart(session),
			tostring(Ridtrappa.ryggar(session.stegIndex))))

	--[[ Golvet. Ett BROMS ur rygga far inte falla vidare ned i ingenting. ]]
	steg(spelare, session, "broms")
	steg(spelare, session, "broms")
	steg(spelare, session, "broms")
	check("trappan har ett golv - rygga ar nedersta pinnen",
		session.stegIndex == Ridtrappa.RYGGA,
		("stegIndex %d"):format(session.stegIndex))
	steg(spelare, session, "driv")
end

print("\n== Spamet ==")

do
	--[[ 5. Tio avsikter pa samma ogonblick ger HOGST ett steg.

	     Tva grindar traffar har, och det ar med flit: skopan (DoS) och
	     impulssparren (UX-takten). Skopan ensam hade slappt igenom fyra
	     steg pa en bildruta. ]]
	vanta(Config.RIDINPUT.ImpulsSparr)   -- full skopa, sparren utagerad
	session.stegIndex = Gaits.index("halt")
	local fore = session.stegIndex
	for i = 1, 10 do
		avsikt(spelare, "driv", i)
	end
	local steg_tagna = session.stegIndex - fore
	check("5. tio spam-avsikter ger hogst ETT accepterat steg",
		steg_tagna <= 1, ("%d steg"):format(steg_tagna))
	check("men ett steg gick igenom - grinden ar inte en total blockering",
		steg_tagna == 1, ("%d steg"):format(steg_tagna))
end

do
	--[[ SKOPAN ar inte overflodig bredvid sparren, och det ar inte
	     uppenbart -- jag trodde sjalv tvartom tills mutationen matte det.

	     Sparren mats mot `sisteHjalp`, som bara uppdateras nar ett steg
	     faktiskt ACCEPTERAS. Ett NEKAT steg lamnar den orord, och da
	     slapper sparren igenom nasta paket ocksa. En klient som star vid
	     taket och spammar DRIV far alltsa varje paket anda fram till
	     `replikera` -- tre attributskrivningar och ett `FireClient` per
	     paket, sa fort natet orkar leverera dem.

	     Skopan ar det enda som stoppar den forstarkningen. Utan den ar
	     avslaget billigare for angriparen an for servern.

	     Matningen raknar paket pa tradet, inte gangarter: det ar ARBETET
	     som ar hotat har, inte sanningen. ]]
	local remote = Networking.get("RidTillstand")
	modell:SetAttribute("GaitCeiling", "trot")
	session.stegIndex = Gaits.index("trot")
	vanta(Config.RIDINPUT.ImpulsSparr)
	session.intentPolletter = Config.RIDINPUT.SkopaTak
	remote._skickat = {}
	for i = 1, 200 do
		avsikt(spelare, "driv", i)
	end
	check("spam vid taket forstarkas inte till 200 serversvar",
		#remote._skickat <= Config.RIDINPUT.SkopaTak,
		("%d svar pa 200 avsikter, skopa %d"):format(
			#remote._skickat, Config.RIDINPUT.SkopaTak))
	modell:SetAttribute("GaitCeiling", Gaits.SPELBAR_TOPP)
end

do
	--[[ Och den arliga takten far inte strypas. En grind som ater
	     legitima hjalper laser som trasig styrning, och hade plockats bort
	     i stallet for justerats. ]]
	session.stegIndex = Gaits.index("halt")
	local igenom = 0
	for _ = 1, 3 do
		local fore = session.stegIndex
		vanta(Config.RIDINPUT.ImpulsSparr + 0.02)
		avsikt(spelare, "driv", nil)
		if session.stegIndex > fore then igenom += 1 end
	end
	check("hjalper givna i kanonens takt gar alla igenom",
		igenom == 3, ("%d av 3"):format(igenom))
end

print("\n== Aterspelning ==")

do
	--[[ 6. Samma sekvensnummer tva ganger ar ETT steg.

	     Utan regeln kan en angripare spela in ett giltigt paket och
	     skicka om det hur manga ganger som helst; sparren ensam stoppar
	     bara takten, inte upprepningen over tid. ]]
	session.stegIndex = Gaits.index("halt")
	session.sekvens = 0
	session.sisteHjalp = -math.huge
	session.intentPolletter = Config.RIDINPUT.SkopaTak
	avsikt(spelare, "driv", 7)
	check("forsta paketet med sekvens 7 accepteras",
		gangart(session) == "walk", gangart(session))

	session.sisteHjalp = -math.huge
	session.intentPolletter = Config.RIDINPUT.SkopaTak
	avsikt(spelare, "driv", 7)
	check("6. aterspelning av samma sekvens nekas",
		gangart(session) == "walk", gangart(session))

	--[[ Ett LAGRE nummer ar samma sak: paket kan komma omkastade, och den
	     som kommer efter ska inte kunna backa sanningen. ]]
	session.sisteHjalp = -math.huge
	session.intentPolletter = Config.RIDINPUT.SkopaTak
	avsikt(spelare, "driv", 3)
	check("och ett lagre nummer nekas ocksa",
		gangart(session) == "walk", gangart(session))

	session.sisteHjalp = -math.huge
	session.intentPolletter = Config.RIDINPUT.SkopaTak
	avsikt(spelare, "driv", 8)
	check("men nasta hogre nummer gar igenom",
		gangart(session) == "trot", gangart(session))
end

print("\n== Payloaden ==")

do
	--[[ 7. Okand handling och feltypad payload nekas UTAN SPAR.

	     "Utan spar" ar inte en formulering: mätningen laser bade
	     gangarten och sekvensraknaren efterat. En vakt som nekar steget
	     men anda rakner upp sekvensen hade brutit den arliga klientens
	     nasta paket. ]]
	local function nekas(namn, handling, sekvens)
		session.stegIndex = Gaits.index("walk")
		session.sekvens = 0
		session.sisteHjalp = -math.huge
		session.intentPolletter = Config.RIDINPUT.SkopaTak
		avsikt(spelare, handling, sekvens)
		check(namn, gangart(session) == "walk" and session.sekvens == 0,
			("%s, sekvens %s"):format(gangart(session), tostring(session.sekvens)))
	end
	nekas("7. okand handling nekas", "galoppera", 1)
	nekas("handling som ar ett tal nekas", 3, 1)
	nekas("handling som ar en tabell nekas", {}, 1)
	nekas("handling som ar nil nekas", nil, 1)
	nekas("tom strang nekas", "", 1)
	nekas("versalt DRIV nekas - ordforradet ar exakt", "DRIV", 1)
	nekas("sekvens som inte ar ett tal nekas", "driv", "1")
	nekas("NaN-sekvens nekas", "driv", 0 / 0)
	nekas("+oandlig sekvens nekas", "driv", math.huge)
	nekas("-oandlig sekvens nekas", "driv", -math.huge)
	nekas("sekvens som ar en tabell nekas", "driv", {})
end

print("\n== Avsandaren ==")

do
	--[[ 8. Den som inte rider kan inte pavarka nagon hast. ]]
	local frammande = { Name = "Ingen", UserId = 999, Character = nil }
	session.stegIndex = Gaits.index("walk")
	session.sisteHjalp = -math.huge
	session.intentPolletter = Config.RIDINPUT.SkopaTak
	avsikt(frammande, "driv", 1)
	check("8. en spelare utan rider-session paverkar ingen hast",
		gangart(session) == "walk", gangart(session))

	--[[ 9. En spelare kan inte styra NAGON ANNANS hast.

	     Hasten star medvetet inte i argumentet: servern slar upp den ur
	     `byRider`. Det finns alltsa ingen parameter att ljuga i, och det
	     ar starkare an en agarkontroll som kan glommas bort. Provet satter
	     upp en ANDRA ryttare pa en ANDRA hast och later henne spamma. ]]
	local hast2 = HastRigg.bygg(HAST_ID, "Andra hasten", CFrame.new(vec(40, 0, 0)))
	hast2.Parent = workspace
	Taggar:AddTag(hast2, "Horse")
	local spelare2 = nySpelare("Granne", 202, vec(44, 0, 0))
	Players._spelare = { spelare, spelare2 }
	local okTva, skalTva, markeTva = HorseService.tryMount(spelare2, hast2)
	check("den andra ryttaren sitter upp pa sin egen hast",
		okTva == true, tostring(skalTva))
	check("och fick ett EGET rittmarke - marken ar inte delade",
		typeof(markeTva) == "string" and markeTva ~= rittMarke,
		tostring(markeTva))
	local session2 = HorseService.sessionFor(hast2)

	session.stegIndex = Gaits.index("walk")
	session2.stegIndex = Gaits.index("halt")
	for i = 1, 5 do
		session2.sisteHjalp = -math.huge
		session2.intentPolletter = Config.RIDINPUT.SkopaTak
		avsikt(spelare2, "driv", i, markeTva)
	end
	check("9. grannens avsikter ror inte MIN hast",
		gangart(session) == "walk", gangart(session))
	check("de tog daremot hennes egen uppat",
		session2.stegIndex > Gaits.index("halt"),
		gangart(session2))
	HorseService.dismount(spelare2)
end

print("\n== Taket ==")

do
	--[[ 10. Taket stoppar UPPSTEG men aldrig NEDSTEG.

	     Det ar inte en detalj. Nar uthalligheten sjunker faller taket
	     under den gangart hasten redan gar i, och om taket da ocksa hade
	     klampat nedstegringen kunde en trott hast inte bromsas. ]]
	modell:SetAttribute("GaitCeiling", "trot")
	session.stegIndex = Gaits.index("trot")
	steg(spelare, session, "driv")
	check("10. DRIV vid taket stegar inte over det",
		gangart(session) == "trot", gangart(session))

	steg(spelare, session, "broms")
	check("men BROMS vid taket gar ned",
		gangart(session) == "walk", gangart(session))

	--[[ Och det svara fallet: trappan star OVER taket for att
	     uthalligheten just sankt det. Uppat ska vara stangt, nedat oppet. ]]
	session.stegIndex = Gaits.index("canter")
	steg(spelare, session, "driv")
	check("en trappa over taket kan inte stega uppat",
		gangart(session) == "canter", gangart(session))
	steg(spelare, session, "broms")
	check("men den kan alltid bromsas ned",
		gangart(session) == "trot", gangart(session))

	--[[ Det yttre taket gar inte att forhandla bort. Ett manipulerat
	     `GaitCeiling` far inte oppna fyrspranget -- gangarten webben inte
	     har, och som paritetsregeln darfor stanger. ]]
	modell:SetAttribute("GaitCeiling", "gallop")
	session.stegIndex = Gaits.index("canter")
	steg(spelare, session, "driv")
	check("manipulerat tak oppnar inte fyrspranget",
		gangart(session) == "canter", gangart(session))
	modell:SetAttribute("GaitCeiling", Gaits.SPELBAR_TOPP)
end

do
	--[[ Uthalligheten drar ned trappan SJALV nar taket sjunker.

	     Forut satt den rattelsen i `onStateSync`: klienten fortsatte
	     rapportera galopp och servern klampade ned paret den fick. Det
	     holl bara sa lange klienten SA nagot -- en klient som tystnade
	     lamnade attributet kvar over taket. ]]
	session.stegIndex = Gaits.index("canter")
	session.energi = 0.0
	RunService.Heartbeat:Fire(0.30)
	check("en utmattad hast rullar ned en gangart av sig sjalv",
		session.stegIndex < Gaits.index("canter"),
		("%s, tak %s"):format(gangart(session),
			tostring(modell:GetAttribute("GaitCeiling"))))
	session.energi = 1.0
end

print("\n== StateSync kan inte langre rora gangarten ==")

do
	--[[ 11. Det anrop en manipulerad gammal klient hade gjort.

	     Gangarten finns inte pa traden langre, sa det aldre anropet har
	     ett STRANGVARDE dar farten ska sta och faller pa typkontrollen.
	     Skillnaden mot en regel som ignorerar argumentet ar att det har
	     inte gar att glomma bort: det finns ingen gangart att lasa. ]]
	session.stegIndex = Gaits.index("halt")
	modell:SetAttribute("Speed", 0)
	Networking.get("StateSync").OnServerEvent:Fire(spelare, "canter", 5.6)
	check("11. gammal StateSync('canter', giltig fart) byter inte serverns gangart",
		gangart(session) == "halt", gangart(session))
	check("och skriver ingen fart heller - anropet foll helt",
		math.abs(modell:GetAttribute("Speed") or -1) < 1e-6,
		tostring(modell:GetAttribute("Speed")))

	--[[ Inte heller den arliga fartvagen far rora gangarten. ]]
	Networking.get("StateSync").OnServerEvent:Fire(spelare, 5.6)
	check("och en ren fartsynk ror den inte heller",
		gangart(session) == "halt", gangart(session))
end

print("\n== Klientens reconcile ==")

do
	--[[ 12. Klienten predikterar, servern nekar, klienten rattas.

	     Kedjan mats hela vagen: klientens `step()` stegar trappan i samma
	     bildruta som knappen trycks, servern nekar steget mot taket, och
	     det PAKET SERVERN FAKTISKT SANDE matas in i klientens
	     `reconcile()`. Ingen handskriven nyttolast.

	     Rigg och stats kommer ur den riktiga sessionen, sa controllern ar
	     byggd pa samma hast servern rider. ]]
	local mc = MovementController.new(session.rig, session.stats)
	local function avsiktsTabell(o)
		o = o or {}
		return { forward = 0, steer = 0, rein = 0, seat = 0, parad = 0,
			gaitUp = o.gaitUp or false, gaitDown = o.gaitDown or false,
			jump = false }
	end

	--[[ Klienten star i trav och tror att taket ar galopp. ]]
	mc:setCeiling("canter")
	mc.loco.beddGangart = "trot"
	mc.loco.targetGait = "trot"
	mc:step(avsiktsTabell({ gaitUp = true }), 1 / 60)
	check("klienten predikterar steget direkt - knappen kanns omedelbar",
		mc.loco.beddGangart == "canter", mc.loco.beddGangart)

	--[[ Servern har ett LAGRE tak och nekar. ]]
	local remote = Networking.get("RidTillstand")
	remote._skickat = {}
	modell:SetAttribute("GaitCeiling", "trot")
	session.stegIndex = Gaits.index("trot")
	steg(spelare, session, "driv")
	check("servern nekade steget", gangart(session) == "trot", gangart(session))

	local sista = remote._skickat[#remote._skickat]
	check("och svarade anda - ett nekat intent lamnar inte klienten okunnig",
		sista ~= nil and typeof(sista[2]) == "table",
		("%d paket"):format(#remote._skickat))

	local svar = sista[2]
	mc:reconcile(svar.gangart, svar.ryggar, svar.version)
	check("12. klienten reconcilar till serverns gangart",
		mc.loco.beddGangart == "trot" and mc.loco.targetGait == "trot",
		("bedd %s, target %s"):format(mc.loco.beddGangart, mc.loco.targetGait))

	--[[ DEN SUBTILA HALVAN, och den som gor provet vart att skriva.

	     `_vantar` bar hastens svarstid pa en hjalp som annu inte borjat
	     verka. Lamnas den kvar fyrar den om en stund och satter tillbaka
	     precis det `targetGait` servern nyss nekade -- reconcilen hade da
	     hallit i en halv sekund och sedan tyst upphavt sig sjalv.

	     Darfor stegas klienten framat i tid EFTER rattelsen. ]]
	for _ = 1, 120 do
		mc:step(avsiktsTabell(), 1 / 60)
	end
	check("och rattelsen haller - den vantande overgangen revs",
		mc.loco.targetGait == "trot", mc.loco.targetGait)

	--[[ Ett GAMMALT svar far inte lyda. Natet garanterar inte ordningen,
	     och en rattelse som gor fel ar varre an ingen rattelse. ]]
	mc:reconcile("halt", false, svar.version - 1)
	check("ett foraldrat svar ignoreras",
		mc.loco.beddGangart == "trot", mc.loco.beddGangart)

	mc:reconcile("walk", false, svar.version + 1)
	check("men ett nyare svar lyds",
		mc.loco.beddGangart == "walk", mc.loco.beddGangart)

	modell:SetAttribute("GaitCeiling", Gaits.SPELBAR_TOPP)
end

print("\n== Sessionsisolering: paket far inte korsa rittgransen ==")

do
	--[[ CHATGPT-REVIEW AV #241, KRAV 5.

	     Forsta utkastet band inte ett ridpaket till den ritt dar det
	     skapades. Klienten skickade bara (handling, sekvens) och nollade
	     sekvensen vid varje uppsittning; servern nollade sin raknare
	     samtidigt i `nollstallRitt`. Ett FORDROJT `RidingIntent` fran ritt A
	     kunde darfor landa efter avsittning och ny uppsittning, och
	     accepteras mot ritt B -- eller mot en annan hast, eftersom `byRider`
	     da pekade nagon annanstans. `session.rider == player` skiljer inte
	     tva ritter med SAMMA spelare, och sekvensvakten sag det gamla
	     numret som farskt just for att raknaren var nollad.

	     Provet spelar upp precis det forloppet: markets varde fran ritt A
	     sparas, ritten byts, och det gamla paketet slapps in i efterhand. ]]

	--[[ RITT A. Stega upp en pinne sa att det finns ett lage att stora. ]]
	session.stegIndex = Gaits.index("halt")
	local markeA = rittMarke
	steg(spelare, session, "driv")
	check("ritt A lever och stegar som vanligt",
		gangart(session) == "walk", gangart(session))

	--[[ Mellanlaget: efter avsittning finns ingen ritt att traffa. ]]
	check("avsittningen gar igenom", HorseService.dismount(spelare) == true)
	check("rittmarket ar borta nar ingen rider",
		session.rittId == nil, tostring(session.rittId))

	session.stegIndex = Gaits.index("halt")
	session.sisteHjalp = -math.huge
	session.intentPolletter = Config.RIDINPUT.SkopaTak
	avsikt(spelare, "driv", 99, markeA)
	check("ett fordrojt paket mellan tva ritter traffar ingenting",
		gangart(session) == "halt", gangart(session))

	--[[ RITT B: samma spelare, samma hast, ny ritt. ]]
	local okB, _skalB, markeB = HorseService.tryMount(spelare, modell)
	check("ritt B sitter upp", okB == true)
	check("och fick ett ANNAT marke an ritt A",
		typeof(markeB) == "string" and markeB ~= markeA,
		("A %s / B %s"):format(tostring(markeA), tostring(markeB)))
	rittMarke = markeB

	--[[ DET FALLET REVIEWEN BESKREV. Paketet fran ritt A anlander nu, med
	     ett sekvensnummer som ar HOGRE an ritt B:s nollstallda raknare --
	     alltsa exakt det paket som slapptes igenom fore rattelsen. ]]
	local stegFore = session.stegIndex
	local sekvensFore = session.sekvens
	local sparrFore = session.sisteHjalp
	session.sisteHjalp = -math.huge
	session.intentPolletter = Config.RIDINPUT.SkopaTak
	sparrFore = session.sisteHjalp
	avsikt(spelare, "driv", 99, markeA)

	check("5. ritt A:s paket andrar inte ritt B:s tillstand",
		session.stegIndex == stegFore,
		("stegIndex %d -> %d"):format(stegFore, session.stegIndex))
	check("och inte ritt B:s sekvensraknare",
		session.sekvens == sekvensFore,
		("sekvens %s -> %s"):format(tostring(sekvensFore), tostring(session.sekvens)))
	check("och inte ritt B:s impulssparr",
		session.sisteHjalp == sparrFore,
		("sisteHjalp %s"):format(tostring(session.sisteHjalp)))

	--[[ KONTROLLPROVET. Utan det bevisar raderna ovan bara att ingenting
	     hande -- inte att det var MARKET som stoppade paketet. Samma paket
	     med ritt B:s marke ska ga igenom. ]]
	session.sisteHjalp = -math.huge
	session.intentPolletter = Config.RIDINPUT.SkopaTak
	avsikt(spelare, "driv", 99, markeB)
	check("men samma paket med ritt B:s marke gar igenom",
		session.stegIndex > stegFore,
		("stegIndex %d -> %d"):format(stegFore, session.stegIndex))
end

do
	--[[ OCH MARKET SKA VARA ETT MARKE, inte en formalitet. ]]
	local fore = session.stegIndex
	local function nekasMarke(namn, marke)
		session.stegIndex = fore
		session.sisteHjalp = -math.huge
		session.intentPolletter = Config.RIDINPUT.SkopaTak
		avsikt(spelare, "driv", nil, marke)
		check(namn, session.stegIndex == fore,
			("stegIndex %d"):format(session.stegIndex))
	end
	nekasMarke("marke som saknas nekas", false)
	nekasMarke("marke som ar ett tal nekas", 7)
	nekasMarke("marke som ar en tabell nekas", {})
	nekasMarke("tomt marke nekas", "")
	nekasMarke("gissat marke nekas", "r1-0-0")
end

do
	--[[ OCH I ANDRA RIKTNINGEN: ett SENT SVAR fran ritt A far inte ratta
	     en klient som hunnit sitta upp pa ritt B.

	     `version` ordnar paket INOM en hastsession och sager ingenting om
	     vilken ritt svaret galler. Klienten prover darfor bade hasten och
	     ritten. Provet bygger klientens grind ur SAMMA villkor som
	     `init.client` och matar in bade ett gammalt och ett aktuellt
	     paket, sa att bada riktningarna mats. ]]
	local mc = MovementController.new(session.rig, session.stats)
	mc.loco.beddGangart = "trot"
	mc.loco.targetGait = "trot"

	--[[ Klientens ritt: hasten `modell` och det AKTUELLA market. ]]
	local aktivHast, aktivRitt = modell, rittMarke
	local function klientTarEmot(tillstand)
		if typeof(tillstand) ~= "table" then return false end
		if tillstand.hast ~= aktivHast then return false end
		if tillstand.ritt ~= aktivRitt then return false end
		mc:reconcile(tillstand.gangart, tillstand.ryggar, tillstand.version)
		return true
	end

	--[[ Det sena svaret fran ritt A: ratt hast, GAMMALT marke. ]]
	local sentFranA = { hast = modell, ritt = "r1-gammal-ritt",
		gangart = "halt", ryggar = false, version = 9999 }
	check("ett sent RidTillstand fran ritt A avvisas av klienten",
		klientTarEmot(sentFranA) == false)
	check("och klientens prediktion ar orord",
		mc.loco.beddGangart == "trot", mc.loco.beddGangart)

	--[[ En ANNAN hast med RATT marke ska ocksa falla -- hastledet bar
	     hastbytet, rittledet bar ritt-bytet pa samma hast. ]]
	local annanHast = { hast = workspace, ritt = aktivRitt,
		gangart = "halt", ryggar = false, version = 10000 }
	check("ett svar om en ANNAN hast avvisas ocksa",
		klientTarEmot(annanHast) == false)
	check("prediktionen star fortfarande kvar",
		mc.loco.beddGangart == "trot", mc.loco.beddGangart)

	--[[ KONTROLLPROVET: ratt hast OCH ratt marke gar igenom. Utan det
	     mater raderna ovan bara att grinden ar stangd, aldrig att den
	     oppnar. ]]
	local akta = { hast = modell, ritt = aktivRitt,
		gangart = "walk", ryggar = false, version = 10001 }
	check("men ett svar fran den AKTUELLA ritten lyds",
		klientTarEmot(akta) == true)
	check("och klienten reconcilade till det",
		mc.loco.beddGangart == "walk", mc.loco.beddGangart)
end

do
	--[[ MARKET MASTE FINNAS NAR `MountChanged` FYRAR.

	     Det har ar buggen i mitt eget forsta utkast, matt i stallet for
	     kommenterad. Market lag da ENBART i `tryMount`-returen, men
	     `MountChanged` fyras INNE i `setRider` och alltsa fore den returen.
	     Klientens lyssnare anropar `mount(model)` utan marke, sa en ritt
	     som startade den vagen fick `rittId = nil` och servern nekade varje
	     hjalp: hasten svarade inte langre pa DRIV eller BROMS.

	     ORDNINGEN ar det som mats, inte bara att attributet finns.
	     Lyssnaren laser attributet i samma ogonblick signalen kommer -- ar
	     det satt efterat ser den nil, precis som en riktig klient hade
	     gjort. ]]
	local settNarSignalenKom = false
	local koppling = Networking.get("MountChanged").OnClientEvent:Connect(function(m)
		settNarSignalenKom = m:GetAttribute("RidSession") ~= nil
	end)

	HorseService.dismount(spelare)
	local _ok, _s, markeC = HorseService.tryMount(spelare, modell)
	if koppling and koppling.Disconnect then koppling:Disconnect() end

	check("RidSession ar satt REDAN nar MountChanged fyrar",
		settNarSignalenKom == true, tostring(settNarSignalenKom))
	check("och attributet ar samma marke som handskakningen gav",
		modell:GetAttribute("RidSession") == markeC,
		("attribut %s / retur %s"):format(
			tostring(modell:GetAttribute("RidSession")), tostring(markeC)))

	HorseService.dismount(spelare)
	check("och det nollas vid avsittning - ingen ritt, inget marke",
		modell:GetAttribute("RidSession") == nil,
		tostring(modell:GetAttribute("RidSession")))

	local _ok2, _s2, markeD = HorseService.tryMount(spelare, modell)
	rittMarke = markeD
end

print("\n== Sparren mats med riktig tid ==")

do
	--[[ Sparren ar en TIDSREGEL, och matt i sitt eget block med riktig
	     tid genom samma remote. Blocken ovan stallde om `sisteHjalp` for
	     att komma at andra regler; den har mater den. ]]
	session.stegIndex = Gaits.index("halt")
	session.sisteHjalp = -math.huge
	session.intentPolletter = Config.RIDINPUT.SkopaTak
	avsikt(spelare, "driv", nil)
	check("forsta hjalpen gar igenom", gangart(session) == "walk", gangart(session))

	--[[ For tidigt: klart innanfor sparren minus marginalen. ]]
	session.intentPolletter = Config.RIDINPUT.SkopaTak
	avsikt(spelare, "driv", nil)
	check("en andra hjalp direkt efterat nekas",
		gangart(session) == "walk", gangart(session))

	--[[ Och slappt igenom nar tiden faktiskt gatt. Utan den har halvan
	     matte provet bara att grinden ar stangd, aldrig att den oppnar. ]]
	vanta(Config.RIDINPUT.ImpulsSparr + 0.02)
	session.intentPolletter = Config.RIDINPUT.SkopaTak
	avsikt(spelare, "driv", nil)
	check("men slapps igenom nar sparren gatt ut",
		gangart(session) == "trot", gangart(session))
end

do
	--[[ Serverns sparr ar KANON och far inte glida ifran klientens.

	     ATT KLIENTEN LASER SAMMA TAL mats i `driv-broms.spec`, dar
	     `Input` finns i banken. Har mats kanonen sjalv: att marginalen ar
	     en marginal och inte en avstangning. En `ServerMarginal` som
	     vaxte forbi sparren hade slackt grinden utan att en enda rad sag
	     fel ut. ]]
	check("serverns marginal ar mindre an sparren sjalv",
		Config.RIDINPUT.ServerMarginal > 0
			and Config.RIDINPUT.ServerMarginal < Config.RIDINPUT.ImpulsSparr,
		("%.2f"):format(Config.RIDINPUT.ServerMarginal))
end

if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("\nridinput.spec: alla gröna")
end
