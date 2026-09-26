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
--[[ Trappan Rygga ↔ Halt ↔ Skritt ↔ Trav ↔ Galopp. Samma modul klienten
     predikterar i — servern får inte ha en egen kopia av stegen. ]]
local Ridtrappa = Core.Ridtrappa
local Svar, RidKanon = Core.Svar, Core.RidKanon
--[[ Stallet äger den kanoniska hästdatan; HorseService läser den för att
     binda rätt individ till rätt ridkänsla (blocker 1). ]]
local Stallet = require(game:GetService("ReplicatedStorage").Stallet)
local Aktor = require(game:GetService("ReplicatedStorage").HorseCore.Aktor)
--[[ #259 Gate 1A: den delade takten framfor fjarrfunktionerna.
	`StateSync` och `RidingIntent` har sina EGNA skopor nedan — de ar
	RemoteEvents och deras tal speglas av klientens prediktion. ]]
local Skopa = require(script.Parent.Skopa)
local RidLogg = require(script.Parent.RidLogg)
local RidObservation = require(script.Parent.RidObservation)

local HorseService = {}

export type Session = {
	rig: Types.Rig,
	stats: { [string]: any },
	rider: Player?,
	--[[ ENERGIN ÄR DEN ENDA TRÖTTHETSSANNINGEN (senior re-review #87).
	     0–1, samma storhet och samma kanon som klientens `loco.energi`
	     och webbens `s.energi`. `Stamina`-attributet och StaminaSync är
	     dess presentation i 0–MaxStamina, inget eget tillstånd. ]]
	energi: number,
	lastExertion: number,
	lastSync: number,
	lastPosition: Vector3,
	--[[ SERVERNS EGEN MÄTNING (#169 P1). `lastPosition` fanns men lästes
	     aldrig — servern hade alltså ingen egen uppfattning om hur fort
	     hästen faktiskt rörde sig, och trodde därför på klientens ord när
	     uthålligheten räknades.

	     `observerad` är planfart i studs/s mätt mellan två hjärtslag på
	     serversidan. Den är auktoritet för trötthet; klientens påstådda
	     tempo är presentation. ]]
	observerad: number,
	--[[ Skopan för StateSync-takten. `polletter` fylls på med RATE_PAFYLL
	     per sekund upp till RATE_TAK; varje accepterad händelse kostar en.
	     Utan den kunde en klient skriva replikerade attribut hur ofta som
	     helst. ]]
	polletter: number,
	lastPollett: number,
	--[[ ── SERVERNS KANONISKA RIDTILLSTÅND (#233 Fas 4b) ───────────────
	     Här bodde ingenting förut. Gångarten fanns bara som ett attribut
	     som klienten skrev genom `StateSync`, och servern hade därför
	     inget eget minne av vilken gångart hästen var i — bara av vad
	     klienten senast påstått. Utan minne går det inte att validera en
	     ÖVERGÅNG, bara ett värde, och det var precis hålet auditen på
	     #239 mätte upp: `halt → canter` i ett hopp passerade.

	     `stegIndex` är trappans pinne, 0 = rygga och 1..4 = halt, skritt,
	     trav, galopp. Den ÄR gångartssanningen; attributen `Gait`,
	     `Ryggar` och `RidVersion` är dess replikering. ]]
	stegIndex: number,
	--[[ Sekvensen klienten senast fick igenom. Strikt växande — ett
	     återspelat eller omkastat paket ändrar ingenting. ]]
	sekvens: number,
	--[[ När den senaste hjälpen ACCEPTERADES, på serverns klocka. Det är
	     den impulsspärren mäts mot, och den är sanningen; klientens egen
	     spärr är presentation. ]]
	sisteHjalp: number,
	--[[ Vilken `sisteHjalp` vi redan skickat ett avslagsfacit for. Se
	     noten vid impulssparren: en kvittens per fonster, inte per
	     paket. ]]
	nekKvitterad: number,
	--[[ Växer vid varje accepterad ändring. Klienten kastar svar som är
	     äldre än det den redan sett, så att ett omkastat paket inte kan
	     dra tillbaka henne till en gångart hon lämnat. ]]
	ridVersion: number,
	--[[ Skopan för avsikter — samma slags DoS-vakt som `polletter`, men
	     egen: en tom StateSync-skopa får inte kunna svälja en hjälp, och
	     en hjälpspam får inte kunna strypa fartsynken. ]]
	intentPolletter: number,
	intentSenast: number,
	--[[ ── RITTENS IDENTITET (#233, ChatGPT-review av #241) ─────────────
	     Reviewen fällde första utkastet på att ett ridpaket inte var
	     bundet till den ritt det skapades i. `session.rider == player`
	     skiljer inte två ritter med SAMMA spelare: en fördröjd avsikt
	     från ritt A kunde landa efter avsittning och ny uppsittning och
	     accepteras mot ritt B — eller mot en helt annan häst, eftersom
	     `byRider` då pekar någon annanstans. Sekvensvakten hjälpte inte:
	     `nollstallRitt` nollar räknaren vid varje uppsittning, så det
	     gamla numret läste som färskt.

	     `rittId` är serverns eget märke på EN ritt, och `nil` när ingen
	     rider. Klienten får det replikerat och skickar tillbaka det med
	     varje avsikt; servern jämför innan sekvens, spärr eller tillstånd
	     rörs.

	     Märket är ingen nyckel och behöver inte vara det. Servern LITAR
	     aldrig på det — den MATCHAR det. Hästen slås ändå upp ur `byRider`
	     på avsändaren, så en annan spelares märke öppnar ingenting. ]]
	rittId: string?,
}

local sessions: { [Model]: Session } = {}
local byRider: { [Player]: Model } = {}

local TAG = "Horse"

--[[ Dagsformskroken, deklarerad har för att `setRider` ska se den. ]]
local dagsformHook: ((Player) -> number)? = nil

--[[ ── StateSync-takten (#169 P1) ───────────────────────────────────────

	Klienten synkar normalt ~10 Hz. Skopan rymmer RATE_TAK händelser och
	fylls på med RATE_PAFYLL per sekund, alltså 50 % marginal över den
	normala takten plus en liten burst för hack och omstarter. Spam tar
	slut på polletter och skrivs inte.

	Medvetet konservativt: en grind som stryper legitim synk skulle kännas
	som trasig styrning, och då hade den plockats bort i stället för
	justerats. Hellre för generös än märkbar. ]]
local RATE_TAK = 6
local RATE_PAFYLL = 15

--[[ Hur stor positionsförändring mellan två mätningar som fortfarande
	tolkas som rörelse. Över den är det en teleport, ett respawn eller ett
	fysikhopp — inte en häst som travar — och mätningen hoppas över i
	stället för att räknas som fyrsprång i en enda tick. Gallop.max är
	11 studs/s; tre gånger det är långt över allt hästen kan göra själv. ]]
local TELEPORT_GRANS = 33

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

	--[[ ── DEN TILLDELADE HÄSTENS EGNA VÄRDEN (blocker 1) ─────────────
	     Modellens `HorseId` är den kanoniska identiteten, och hästens
	     spelvärden ur UBRFSpelData skrivs på HorseStats FÖRE
	     writeDefaults. Ordningen är hela poängen:

	       ett attribut som redan finns   någon satte det i Studio → vinner
	       kanon                          skrivs här om det saknas
	       Config.STATS default           writeDefaults fyller resten

	     Först skrev jag kanonen EFTER writeDefaults och lät `Config.attr`
	     avgöra. Det gick inte: writeDefaults hade just stämplat sina
	     defaultvärden på samma Configuration, så "någon satte det i
	     Studio" gick inte att skilja från "vi skrev standardvärdet för en
	     millisekund sedan" — och varje häst red som `skolhast` ändå.
	     Uppmätt, inte resonerat: provet i forberedelse.spec sa
	     `crokino → skolhast`.

	     Utan det här ledet nådde profilerna aldrig ridcontrollern. ]]
	do
		local id = model:GetAttribute("HorseId")
		local kanon = if type(id) == "string" then Stallet.statsFor(id) else nil
		if kanon then
			local c = rig.stats :: Configuration
			for nyckel, varde in kanon do
				if varde ~= nil and c:GetAttribute(nyckel) == nil then
					c:SetAttribute(nyckel, varde)
				end
			end
		end
	end

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
		--[[ Utgångsläget ur kanonen (senior re-review #87, blocker 2).
		     Stod som 1 — en utvilad häst som webben aldrig satte upp på;
		     där börjar energin i dagsformen. ]]
		energi = Svar.startEnergi(),
		lastExertion = 0,
		lastSync = os.clock(),
		lastPosition = rig.root.Position,
		observerad = 0,
		polletter = RATE_TAK,
		lastPollett = os.clock(),
		stegIndex = Gaits.index("halt"),
		sekvens = 0,
		sisteHjalp = 0,
		nekKvitterad = -1,
		ridVersion = 0,
		intentPolletter = Config.RIDINPUT.SkopaTak,
		intentSenast = os.clock(),
	}

	model:SetAttribute("Registered", true)
	model:SetAttribute("Gait", "halt")
	--[[ Ryggningen är REPLIKERAD sedan Fas 4b. Den bars förut bara av
	     klientens `self.ryggar` och syntes inte utanför den ridande
	     klienten; en åskådare kunde inte veta skillnad på en häst som
	     stod still och en som backade. ]]
	model:SetAttribute("Ryggar", false)
	model:SetAttribute("RidVersion", 0)
	model:SetAttribute("Stamina", stats.MaxStamina)
end

--[[ Provkrokar. `register` är lokal med flit — produktionen registrerar
     via CollectionService — men blocker 1 kräver ett prov som går genom
     den RIKTIGA registreringen och läser de stats hästen faktiskt fick.
     Krokarna kallar samma kod, de duplicerar den inte. ]]
--[[ RIV SESSIONEN, LÄMNA BOKFÖRINGEN. Enda vägen att framkalla
     `hast.oregistrerad` i en bänk: läget uppstår i drift när en häst
     avregistreras under en ryttare, och utan den här kroken går grinden
     mot stale `byRider` inte att mäta alls. Provkrok, som grannarna. ]]
function HorseService._glomSessionForProv(model: Model)
	sessions[model] = nil
end

function HorseService._registerForProv(model: Model)
	register(model)
end
function HorseService._statsFor(model: Model): { [string]: any }?
	local session = sessions[model]
	return if session then session.stats else nil
end

local function unregister(model: Model)
	local session = sessions[model]
	if not session then return end
	if session.rider then
		byRider[session.rider] = nil
	end
	--[[ En häst som avregistreras under en ritt: posten stängs som avbruten
		här, annars står den öppen för alltid. `logga` deklareras längre
		ned, därför går stängningen direkt och i egen pcall. ]]
	if session.rittId then
		local ok, fel = pcall(RidLogg.avsluta, session.rittId, "avbruten", "hast_avregistrerad", os.clock())
		if not ok then warn("[Horse] ridloggen kastade: " .. tostring(fel)) end
		local ok2, fel2 = pcall(RidObservation.avsluta, session.rittId, "avbruten")
		if not ok2 then warn("[Horse] ridobservationen kastade: " .. tostring(fel2)) end
	end
	sessions[model] = nil
end

--[[ ── Uppsittning ─────────────────────────────────────────────────── ]]

local function seatCFrame(session: Session): CFrame
	return RigAdapter.saddleCFrame(session.rig)
end

--[[ ══ LIVSCYKELSTÄDNING ═════════════════════════════════════════════════

	Blockerare 3 i ChatGPT:s whole-place review #162: servern höll
	`session.rider` och `byRider[player]` men hade INGEN lyssnare för att
	avataren dör, tas bort eller kastas ur sitsen. Roblox kan lossa ryttaren
	fysiskt medan våra tabeller fortfarande säger att hon rider. Då nekas
	nästa uppsittning med "Du rider redan", hästen ligger reserverad, och
	`Pass.vidAvsittning` körs aldrig.

	Kommentaren vid `tryMount` hävdade att en `Seat` sköter frånkopplingen
	"åt oss" vid död, respawn och utloggning. Det är sant om den FYSISKA
	fastsättningen och falskt om vårt tillstånd — och det var precis den
	skillnaden som gjorde att ingen såg luckan.

	Kopplingarna görs vid uppsittning och rivs vid avsittning, så det finns
	inga lyssnare för spelare som inte rider. `PlayerAdded` rörs inte:
	SparService äger den ensam sedan blockerare 1 i #161. ]]
local stadning: { [Player]: { RBXScriptConnection } } = {}

local function slappStadning(player: Player)
	local kopplingar = stadning[player]
	if not kopplingar then return end
	stadning[player] = nil
	for _, k in ipairs(kopplingar) do
		pcall(function() k:Disconnect() end)
	end
end

--[[ Ryttarkroken deklareras HÄR och inte längre ner, och det är en
	rättelse: `setRider` läser den, och en `local` som deklareras EFTER
	funktionen fångas inte av den — namnet lästes då som en global, alltså
	alltid nil. Följden var att kroken aldrig kördes: `Pass.vidUppsittning`
	och `Pass.vidAvsittning` anropades inte, passet stannade i läget
	"before_ride" hur mycket spelaren än red, och eftervården — som kräver
	att ritten är avslutad — gick aldrig att göra. Dagen kunde alltså inte
	spelas färdigt.

	Att det inte syntes har samma orsak som `seat.C0`: ingen körning hade
	någonsin monterat en ryttare mot en riktig rigg. Kontraktet mäts nu i
	`integration.spec.luau` (punkt 9 och 11).

	Kroken får INTE avgöra något — se noten vid `riderHooks`. ]]
--[[ EN LISTA, INTE EN KROK (#263 Gate 2A).

	Faltet var en enda krok, och `GameplayService` hade tagit den.
	`ForstaRitten` behover samma besked — nar en ryttare sitter av ska
	dess sessionsstatus rivas — och alternativet hade varit en andra,
	parallell kroktyp for samma handelse.

	Att det gar att gora sa har utan risk star redan i noten ovan:
	kroken FAR inte avgora nagot. Den ar en avisering, och en avisering
	tal flera mottagare. Varje lyssnare kors i egen pcall, sa en som
	kastar tystar inte nasta. ]]
local riderHooks: { (Player, boolean) -> () } = {}

--[[ ── REPLIKERINGEN AV DET ACCEPTERADE LÄGET (#233 Fas 4b) ────────────

     Två vägar ut, med olika mottagare och samma sanning:

       attributen   → alla som ser hästen, åskådare inräknade
       RidTillstand → den ridande klienten, som ska reconcila

     `ridVersion` växer vid varje skrivning och följer med båda vägarna.
     Utan den kan ett omkastat paket dra tillbaka klienten till en gångart
     hon redan lämnat — nätverket garanterar inte ordningen, och en
     reconcile som lyder ett gammalt svar är värre än ingen reconcile.

     Funktionen är den ENDA som skriver gångartsattributen. Det är med
     flit: så länge det finns exakt ett ställe går det att läsa av vem som
     äger sanningen, och `grep` svarar på frågan. ]]
--[[ Ett märke per ritt.

     Löpnumret gör det unikt, slumpdelen gör det ogissbart nog att en
     klient inte kan tala om en ritt den inte fått märket till. `os.clock`
     blandas in så att två serverstarter inte ger samma serie — `Random`
     finns inte i bänkens stubbar, och kravet här är färskhet, inte
     kryptografi. ]]
local nastaRitt = 0
local function nyttRittId(): string
	nastaRitt += 1
	return ("r%d-%x-%x"):format(nastaRitt,
		math.floor(os.clock() * 1e6) % 0xffffff,
		math.random(0, 0xffffff))
end

--[[ ══ RIDLOGGEN (#264 INFRA-2A) ═════════════════════════════════════
	Serverns egen logg per ritt, skriven BARA där en övergång redan har
	accepterats: i `setRider` (upp och av), efter ett accepterat steg i
	`onRidingIntent`, när trötthetstaket drar ned trappan, och när
	`stannaHast` stoppar en häst som fortfarande rids.

	`replikera` är INTE en krok för loggen. Den körs också för nekade
	hjälper och för rättelser utan ändring, så en logg där hade skrivit
	övergångar som aldrig accepterades.

	Varje anrop går genom `logga`, i pcall: loggen får aldrig hindra en
	uppsittning, en avsittning eller ett steg. ]]
local function logga(fn: (...any) -> any, ...: any)
	local ok, fel = pcall(fn, ...)
	if not ok then warn("[Horse] ridloggen kastade: " .. tostring(fel)) end
end

local function loggaSteg(session: Session, franIndex: number, orsak: string, handling: string?)
	if session.rittId == nil or franIndex == session.stegIndex then return end
	logga(RidLogg.gangart, session.rittId, {
		fran = Ridtrappa.gangart(franIndex),
		franRyggar = Ridtrappa.ryggar(franIndex),
		till = Ridtrappa.gangart(session.stegIndex),
		tillRyggar = Ridtrappa.ryggar(session.stegIndex),
		orsak = orsak,
		handling = handling,
	}, os.clock())
end

local function replikera(session: Session)
	local model = session.rig.model
	local gangart = Ridtrappa.gangart(session.stegIndex)
	local ryggar = Ridtrappa.ryggar(session.stegIndex)

	session.ridVersion += 1
	model:SetAttribute("Gait", gangart)
	model:SetAttribute("Ryggar", ryggar)
	model:SetAttribute("RidVersion", session.ridVersion)

	if session.rider then
		--[[ SVARET BÄR SIN EGEN IDENTITET (ChatGPT-review av #241).
		     `version` ordnar paket INOM en hästsession; den säger
		     ingenting om VILKEN ritt eller vilken häst svaret gäller. Ett
		     sent svar från ritt A kunde därför rätta en klient som hunnit
		     sitta upp på ritt B. Hästen och rittmärket följer nu med, och
		     klienten reconcilar bara när båda stämmer. ]]
		local kRid = Aktor.klient(session.rider)
		if kRid then
			Net.get("RidTillstand"):FireClient(kRid, {
				hast = model,
				ritt = session.rittId,
				gangart = gangart,
				ryggar = ryggar,
				version = session.ridVersion,
			})
		end
	end
end

--[[ Ritten börjar och slutar i halt, och sekvensen börjar om.

     Att nolla sekvensen vid varje på- och avsittning är inte kosmetik:
     utan det bär sessionen kvar den FÖRRA ryttarens räknare, och nästa
     ryttares ärliga `sekvens = 1` hade lästs som ett återspelat paket och
     tyst kastats. Hjälpen hade då försvunnit, och felet hade sett ut som
     trasig input i stället för som en räknare som inte nollades. ]]
local function nollstallRitt(session: Session)
	session.stegIndex = Gaits.index("halt")
	session.sekvens = 0
	session.sisteHjalp = 0
	session.nekKvitterad = -1
	session.intentPolletter = Config.RIDINPUT.SkopaTak
	session.intentSenast = os.clock()
end

--[[ `orsak` gäller bara när en ryttare lämnar: "avsittning" är en
	avsittning hon själv bad om, allt annat är ett avbrott. ]]
local function setRider(session: Session, player: Player?, orsak: string?)
	local previous = session.rider
	--[[ Märket fångas FÖRE nollställningen nedan, annars finns ingen
		identitet kvar att stänga ridloggen med. ]]
	local gammalRitt = session.rittId
	session.rider = player

	if previous then
		byRider[previous] = nil
	end
	if player then
		byRider[player] = session.rig.model
	end

	--[[ ── SYNKTILLSTÅNDET FÖLJER INTE MED TILL NÄSTA RYTTARE (#169 P1) ──
	     Polletterna, mätpunkten och den observerade farten hörde till den
	     förra ryttarens ritt. Utan nollställning kunde en tom skopa göra
	     att nästa ryttares första synkar tyst släpptes, och en gammal
	     `lastPosition` ge ett falskt fartutslag i första hjärtslaget —
	     alltså dränering för en sträcka den nya ryttaren aldrig red.

	     Nollställs vid BÅDE på- och avsittning: sessionen ska aldrig bära
	     en mätning som hör till någon annan. ]]
	--[[ Dagsformen avgörs NÄR hon sätts upp på, inte när hon registreras:
		skötseln sker mellan de två, och det är den som ska synas. ]]
	--[[ DAGSFORMEN ÄR SERVERNS, OCH KLIENTEN SKA FÅ VETA DEN.

	     Den räknades förut ut här, göts in i `session.energi` och glömdes
	     sedan bort som eget begrepp. `UgnetaTema` behöver den för att
	     kunna skilja «hästen har en dålig dag» från «ryttaren sitter
	     fel», och klienten hade ingen väg till den alls — attributet
	     `Dagsform` fanns inte, så regeln föll tillbaka på skyggheten.

	     Attributet sätts av samma skäl som `RidSession` några rader ned:
	     det REPLIKERAS, och då hittar varje väg in i ritten samma värde.
	     Saknas kroken, eller är det ingen som sitter upp, tas attributet
	     BORT. Det är avsiktligt: en klient ska läsa «okänd» och tiga,
	     inte ärva föregående ryttares dagsform. ]]
	local dagsform: number? = nil
	if player and dagsformHook then
		local ok, d = pcall(dagsformHook, player)
		if ok and typeof(d) == "number" then
			dagsform = math.clamp(d, 0, 1)
			session.energi = Svar.startEnergi(dagsform)
		end
	end
	session.rig.model:SetAttribute("Dagsform", dagsform)

	session.polletter = RATE_TAK
	session.lastPollett = os.clock()
	session.lastSync = os.clock()
	session.lastPosition = session.rig.root.Position
	session.observerad = 0

	--[[ Samma skäl som raderna ovan, för ridtillståndet: trappan, spärren
	     och sekvensen hör till EN ritt. Ordningen spelar roll — ryttaren
	     är redan satt, så `replikera` når den nya ryttaren med hennes
	     utgångsläge i stället för att den förra får ett sista svar. ]]
	nollstallRitt(session)
	session.rittId = if player then nyttRittId() else nil
	--[[ Ridloggen: den gamla ritten stängs (en gång — `avsluta` är ett
		nej andra gången) och en ny öppnas för den nya ryttaren. ]]
	local logNu = os.clock()
	if gammalRitt then
		local vanlig = orsak == nil or orsak == "avsittning"
		logga(RidLogg.avsluta, gammalRitt, if vanlig then "avslutad" else "avbruten",
			orsak or "avsittning", logNu)
		logga(RidObservation.avsluta, gammalRitt, if vanlig then "avslutad" else "avbruten")
	end
	if player and session.rittId then
		local hastId = tostring(session.rig.model:GetAttribute("HorseId") or session.rig.model.Name)
		logga(RidLogg.starta, session.rittId, hastId,
			player.UserId, Ridtrappa.gangart(session.stegIndex), logNu)
		--[[ INFRA-2B1: observationen börjar utan baslinje. Första giltiga
			läget i nästa uthållighetssteg blir baslinjen, så ingen sträcka
			från före uppsittningen kan räknas in. ]]
		logga(RidObservation.starta, session.rittId, hastId, player.UserId)
	end
	--[[ ── MÄRKET REPLIKERAS, OCH DET ÄR INTE EN BEKVÄMLIGHET ──────────
	     Första utkastet lämnade märket ENBART i `tryMount`-returen. Det
	     var en trasig leverans, och felet är värt att stå kvar:

	     `MountChanged` fyras några rader ned i den HÄR funktionen, alltså
	     INNE i `tryMount` och före dess return. Klientens
	     `MountChanged`-lyssnare anropar `mount(model)` — utan märke. En
	     ritt som startade den vägen hade fått `rittId = nil`, och då hade
	     servern nekat varje hjälp: hästen hade slutat svara på DRIV och
	     BROMS helt. `klient.spec` monterar just den vägen.

	     Attributet är därför sanningen, och det sätts FÖRE `MountChanged`
	     så att varje väg in i ritten hittar ett märke. Handskakningens
	     retur är kvar som tidig antydan för det fönster där attributet
	     ännu inte replikerat.

	     Att märket syns för alla är ofarligt och värt att säga uttryckligen:
	     det ger ingen makt. Servern slår ändå upp hästen ur `byRider` på
	     AVSÄNDAREN, så en annan spelares märke öppnar ingenting. Märket är
	     en färskhetsstämpel, inte en nyckel. ]]
	session.rig.model:SetAttribute("RidSession", session.rittId)
	replikera(session)

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

	--[[ #252 DEL C: broadcasten bar SPELAREN som nyttolast. En aktor utan
	     klient gar inte att serialisera over traden, och en session utan
	     ryttare skickar redan `nil`. Testsatet hamnar i samma gren. ]]
	Net.get("MountChanged"):FireAllClients(session.rig.model, Aktor.klient(player))

	--[[ Aviseringen sist, när allt annat är gjort: kroken ska se ett
		färdigt tillstånd, inte ett halvt. ]]
	for _, hook in ipairs(riderHooks) do
		if previous and previous ~= player then
			local ok, fel = pcall(hook, previous, false)
			if not ok then warn("[Horse] ryttarkroken (av) kastade: " .. tostring(fel)) end
		end
		if player then
			local ok, fel = pcall(hook, player, true)
			if not ok then warn("[Horse] ryttarkroken (upp) kastade: " .. tostring(fel)) end
		end
	end
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

--[[ RYTTARKROKEN (#161).

	`GameplayService` behöver veta NÄR någon satt sig upp eller av, för att
	driva passets läge — och den behöver veta det för VARJE väg in och ut,
	inte bara för `MountRequest`. En krok på fjärranropet hade missat
	karaktärens död, respawn, utloggning och en modell som tas bort ur
	världen, och just de fallen är de som lämnar ett pass hängande.

	Den ligger därför i `setRider`, som är den enda punkt all uppsittning
	och avsittning faktiskt passerar — exakt samma resonemang som gjorde
	att `mountGate` sitter i `tryMount` och inte på remoten.

	Kroken får INTE avgöra något. Den är en avisering, inte en grind; ett
	fel i den ska inte kunna hindra en avsittning, och därför är anropet
	inkapslat i pcall. En spökryttare som sitter kvar för att en HUD
	kastade vore värre än en HUD som visar fel. ]]
--[[ DAGSFORMSKROKEN (FUN FIRST / RIDE FIRST).

	Hästens dagsform vid uppsittning. `GameplayService` registrerar den och
	svarar med ett tal 0–1 ur hur mycket av skötseln spelaren gjort själv.

	Kroken finns av samma skäl som `mountGate`: hästsystemet ska gå att köra
	utan gameplaylagret. Ingen krok registrerad = kanonens standarddagsform,
	alltså exakt den häst spelet alltid gett. Belöningen kan bara lyfta
	därifrån — aldrig sänka. ]]
function HorseService.setDagsformHook(hook: ((Player) -> number)?)
	dagsformHook = hook
end

--[[ ══ LEDS HON REDAN? ══════════════════════════════════

	Robustness Slice A. `LedService` har alltid vägrat att börja LEDA en
	riden häst (`led.rids`), men motsatta vägen stod öppen: A ledde, B
	satte sig upp, och båda ägde henne.

	Det är inte en kosmetisk krock. Ledningen tar nätverksägarskapet till
	servern och sparar det föregående värdet; uppsittningen ger ägarskapet
	till ryttaren. Delarna sitter i samma assembly (`Motor6D` i
	`HastRigg`), och Roblox ägarskap gäller per assembly. När A sedan
	släpper lämnar `LedService` tillbaka det ägarskap den sparade INNAN B
	satte sig — och rycker det därmed från den aktiva ryttaren. B rider en
	häst hon inte längre styr.

	LEDNINGENS SANNING BOR KVAR I `LedService`. Den här modulen får en
	KROK, inte en kopia av `ledd`-tabellen — två böcker över vem som leder
	vore samma sorts delade sanning som felet ovan.

	SEPARAT FRÅN `mountGate` MED FLIT. Grinden nedan sitter i `tryMount`
	själv och inte i gameplaylagrets gate, för `setMountGate(nil)` är en
	rimlig sak att göra i ett prov som vill hoppa över checklistan — och
	den ska inte samtidigt kunna stänga av en säkerhetsregel.

	── OCH DET ÄR «NÅGON ANNAN», INTE «någon» ────────────────

	Första versionen nekade varje ledd häst, och `integration.spec` fällde
	den omgående — med rätta. Kärnloopen ÄR att leda sin häst till banan
	och sitta upp där, utan att släppa repet först. `LedService` har redan
	den vägen löst: sitter ledaren själv upp släpper den kopplet nästa
	bildruta med skälet `led.rider` (`LedService.luau:1533-1536`).

	Problemet är två OLIKA ägare, inte två roller hos samma spelare.
	Kroken lämnar därför ut LEDAREN, inte ett ja/nej, och jämförelsen
	står här där nejet ges — så att regeln går att läsa på ett ställe.

	Ingen krok registrerad = ingen ledning känd. Hästsystemet ska gå att
	köra utan gameplaylagret, precis som med `mountGate` och dagsformen. ]]
local ledareHook: ((Model) -> Player?)? = nil

function HorseService.setLedareHook(hook: ((Model) -> Player?)?)
	ledareHook = hook
end

--[[ Lagger till en lyssnare. Ersatter INTE de befintliga — se noten vid
	`riderHooks`. ]]
function HorseService.lyssnaRyttare(hook: ((Player, boolean) -> ())?)
	if hook == nil then return end
	table.insert(riderHooks, hook)
end

--[[ Provkrok: banken kor `start()` en gang per block, och utan den har
	arver block tva block ettas lyssnare. ]]
function HorseService._glomRyttarlyssnareForProv()
	riderHooks = {}
end

function HorseService.tryMount(player: Player, model: Model): (boolean, string?, string?)
	if mountGate then
		--[[ TREDJE VÄRDET FÖLJER MED. Nejen är språknycklar sedan #162, och
			välfärdsstoppets nyckel bär fyndets mening som ARGUMENT. Kastade
			den här raden bort argumentet — vilket den gjorde — fick
			spelaren se ett bokstavligt "%s" i stället för vad hästen hade.
			Fångat av `sprak-en.spec`, inte av något jag såg i koden. ]]
		local tillaten, skal, arg = mountGate(player, model)
		if not tillaten then
			return false, skal or "hast.inte_redo", arg
		end
	end

	local session = sessions[model]
	if not session then
		return false, "hast.oregistrerad"
	end
	if session.rider then
		return false, "hast.upptagen"
	end
	if byRider[player] then
		return false, "hast.rider_redan"
	end
	--[[ EN ÄGARE I TAGET. Se noten vid `setLeddHook`. Kroken är
	     pcall:ad av samma skäl som ryttarlyssnarna: ett fel i
	     gameplaylagret ska inte kunna släppa igenom en uppsittning som
	     regeln säger nej till — därför räknas ett KASTAT anrop som
	     «hon leds» och inte som «hon är fri». Fail closed. ]]
	if ledareHook then
		local ok, ledare = pcall(ledareHook, model)
		if not ok then
			warn("[Horse] ledareHook kastade: " .. tostring(ledare))
			return false, "hast.leds_nu"
		end
		--[[ NÅGON ANNANS rep. Sitter LEDAREN själv upp är det kärnloopen,
		     och `LedService` släpper kopplet själv nästa bildruta. ]]
		if ledare ~= nil and ledare ~= player then
			return false, "hast.leds_nu"
		end
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return false, "hast.ingen_karaktar"
	end

	local range = Config.attr(session.rig.gaitConfig, "MountRange", 14)
	if (root.Position - session.rig.root.Position).Magnitude > range then
		return false, "hast.for_langt"
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false, "hast.ingen_levande"
	end

	--[[ Sitsen sköter fastsättningen. En Seat väljs framför en handgjord
	     Weld för att Roblox då hanterar frånkoppling vid död, respawn och
	     utloggning åt oss — de tre fallen som annars lämnar spökryttare. ]]
	local seat = session.rig.seat
	if seat then
		seat:Sit(humanoid)
		--[[ Blockerare 4 i reviewen: `session.rider` sattes som sanning även
			om sitsen aldrig etablerades. Då tror servern att någon rider en
			häst som står tom, och nästa försök nekas med "Du rider redan".
			Sitsen får bekräfta själv. ]]
		if seat.Occupant ~= humanoid then
			return false, "hast.sitsen_tog_inte"
		end
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

	--[[ Städningen kopplas EFTER att ryttaren är satt, så att en signal som
		fyrar direkt hittar ett tillstånd att städa. Alla tre vägarna leder
		till samma idempotenta `dismount`. ]]
	slappStadning(player)
	local kopplingar = {}
	table.insert(kopplingar, player.CharacterRemoving:Connect(function()
		HorseService.dismount(player, "karaktar_borta")
	end))
	table.insert(kopplingar, humanoid.Died:Connect(function()
		HorseService.dismount(player, "dog")
	end))
	if seat then
		--[[ Roblox kan lossa ryttaren utan att någon av ovanstående fyrar —
			en explosion, en `Sit`-ändring, en fysikträff. Occupant är den
			enda källan som alltid säger sanningen om sitsen. ]]
		table.insert(kopplingar, seat:GetPropertyChangedSignal("Occupant"):Connect(function()
			if seat.Occupant ~= humanoid then
				HorseService.dismount(player, "sitsen_slappte")
			end
		end))
	end
	stadning[player] = kopplingar
	--[[ RITTMÄRKET LÄMNAS OCKSÅ I HANDSKAKNINGEN (ChatGPT-review av
	     #241). Tredje värdet är `extra`, som bara läses på AVSLAG — där
	     bär det ett språkargument. På ja-vägen var det oanvänt.

	     Attributet `RidSession` är sanningen; det här är den tidiga
	     antydan, för det fönster där attributet ännu inte replikerat. ]]
	return true, nil, session.rittId
end

--[[ ══ AVSITTNINGENS PLATS ════════════════════════════════════════════

	══ VAD SOM MÄTTES ════════════════════════════════════════════════

	Avsittningen skrev `character:PivotTo(...)` 4,5 studs åt vänster och
	3 studs upp. Uppmätt i Studio efteråt, både mitt på öppen ridbana och
	intill sargen:

	    hästen (399.94 3.36 280.00) · ryttaren (400.00 7.59 280.00)
	    sidsteg 0.06 studs · höjd över hästroten +4.24 · Floor Plastic

	Hon stod alltså PÅ HÄSTRYGGEN — `FloorMaterial` var hästen själv.
	Flytten tog inte, och det är en tidsfråga och ingen räknefråga:
	`Humanoid.Sit = false` reser henne inte i samma bildruta. Så länge
	`seat.Occupant` fortfarande pekar på henne äger sitsen hennes läge, och
	Roblox skriver tillbaka det efter vår `PivotTo`. Att riva `SeatWeld`
	själv hjälper inte — sitsen gör en ny så länge occupanten sitter kvar.

	══ VAD SOM GÖRS I STÄLLET ════════════════════════════════════════

	Platsen räknas ur HÄSTENS EGEN GEOMETRI — aldrig ur en världskoordinat
	— och prövas mot marken och mot det som står i vägen innan hon
	placeras. Sedan placeras hon TVÅ gånger: en gång direkt, och en gång
	till när sitsen faktiskt har släppt. Den andra är den som håller.

	Vänster först, för det är så man sitter av. Är vänster sidan upptagen
	tas höger, och därefter går listan utåt från vänstersidan — snett bak,
	snett fram, rakt bak — vilket ÄR regeln "närmaste säkra läge". ]]

--[[ Fri luft mellan ryttarens kropp och hästens, i studs. ]]
local AVSITT_MARGINAL = 0.6
--[[ Marksökningen börjar så här högt över kandidatpunkten och går så här
	långt ned. Taket måste vara högre än ett trappsteg och lägre än en
	läktarrad, annars hittas fel golv. ]]
local AVSITT_TAK, AVSITT_DJUP = 6, 24
--[[ Marken vid avsittningen får skilja så här mycket från marken under
	hästen. Utan gränsen kunde hon sättas av ned i ett dike eller upp på
	en sarg som råkade ligga i strålens väg. ]]
local AVSITT_FALL = 5
--[[ Lådan som prövas mot hinder är ryttarens rotdel plus lite luft: en
	fot får inte nöta mot en boxfront, och huvudet inte mot en kappregel. ]]
local AVSITT_LADA = Vector3.new(0.4, 1.6, 0.4)
--[[ Så många bildrutor väntar den andra placeringen på att sitsen ska
	släppa. Ett tak och inte en klocka: en spec har ingen riktig tid. ]]
local AVSITT_VANTA = 30

--[[ Kandidatriktningar i HÄSTENS EGET RUM: x åt höger, z bakåt. Inga
	världskoordinater — vänder hästen sig vänder platserna med henne. ]]
local AVSITT_RIKTNINGAR: { { number } } = {
	{ -1, 0 },              -- vänster: så man sitter av
	{ 1, 0 },               -- höger: när vänster är blockerad
	{ -1, 1 }, { 1, 1 },    -- snett bakom
	{ -1, -1 }, { 1, -1 },  -- snett framför
	{ 0, 1 },               -- rakt bakom
}

local function markhojd(p: Vector3, utanfor: { Instance }): number?
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = utanfor
	--[[ Bara det som BÄR duger som mark. Ridbanans sand är ett dekorlager
		utan kollision — se `Markkontakt` — och att sätta av på den vore
		att sätta av i luften. ]]
	rp.RespectCanCollide = true
	local traff = workspace:Raycast(p + Vector3.new(0, AVSITT_TAK, 0),
		Vector3.new(0, -AVSITT_DJUP, 0), rp)
	return if traff then traff.Position.Y else nil
end

local function ledigt(cf: CFrame, storlek: Vector3, utanfor: { Instance }): boolean
	local op = OverlapParams.new()
	op.FilterType = Enum.RaycastFilterType.Exclude
	op.FilterDescendantsInstances = utanfor
	for _, d in ipairs(workspace:GetPartBoundsInBox(cf, storlek, op)) do
		if d.CanCollide then return false end
	end
	return true
end

--[[ Var ryttaren ska hamna. Publik för att provet ska kunna läsa SAMMA
	räkning som avsittningen använder — två räkningar kan glida isär.

	Svarar också VILKEN regel som gav platsen, så ett prov kan skilja
	"vänster var fri" från "vänster var blockerad" utan att gissa ur
	koordinater. ]]
function HorseService._avsittningsplats(modell: Model, karaktar: Model): (CFrame?, string?)
	local rot = modell.PrimaryPart or modell:FindFirstChild("HumanoidRootPart")
	local krot = karaktar:FindFirstChild("HumanoidRootPart")
	local hum = karaktar:FindFirstChildOfClass("Humanoid")
	if not (rot and rot:IsA("BasePart") and krot and krot:IsA("BasePart") and hum) then
		return nil, "avsitt.ingen_kropp"
	end

	local ut = math.max(krot.Size.X, krot.Size.Z) / 2 + AVSITT_MARGINAL
	--[[ HÄSTEN ÄR ETT HINDER, inte ett golv. Hon undantas därför ur
		marksökningen — annars blir hennes egen rygg "mark" — men INTE ur
		hinderprövningen, som är hela poängen med att inte hamna i henne. ]]
	local utanKar: { Instance } = { karaktar }
	local utanBada: { Instance } = { karaktar, modell }
	local hastMark = markhojd(rot.Position, utanBada)

	--[[ Två varv: första kräver fri plats, andra nöjer sig med mark.
		Andra varvet finns för att hon ALDRIG ska bli kvar på ryggen —
		står hon trångt får Roblox knuffa ut henne, och det är bättre än
		att hon blir stående ovanpå hästen. ]]
	for varv = 1, 2 do
		for _, r in ipairs(AVSITT_RIKTNINGAR) do
			local lokal = CFrame.new(
				r[1] * (rot.Size.X / 2 + ut), 0, r[2] * (rot.Size.Z / 2 + ut))
			local punkt = (rot.CFrame * lokal).Position
			local mark = markhojd(punkt, utanBada)
			local rimlig = mark ~= nil
				and (hastMark == nil or math.abs(mark - hastMark) <= AVSITT_FALL)
			if rimlig then
				local y = (mark :: number) + krot.Size.Y / 2 + hum.HipHeight
				local cf = CFrame.lookAt(Vector3.new(punkt.X, y, punkt.Z),
					Vector3.new(rot.Position.X, y, rot.Position.Z))
				if varv == 2 or ledigt(cf, krot.Size + AVSITT_LADA, utanKar) then
					local skal = if varv == 2 then "avsitt.trangt"
						elseif r[1] < 0 and r[2] == 0 then "avsitt.vanster"
						elseif r[1] > 0 and r[2] == 0 then "avsitt.hoger"
						else "avsitt.narmaste"
					return cf, skal
				end
			end
		end
	end
	return nil, "avsitt.ingen_plats"
end

--[[ #264 R2: hur många hjärtslag efter den sena placeringen utfallet
	bevakas, och vad "på hästryggen" betyder: roten inom hästens
	fotavtryck i sidled och tydligt över hennes rot i höjd.

	FÖNSTRET MÅSTE RÄCKA FÖRBI ÅTERLÄMNINGEN. Mätt i Studio (kandidat
	c1946fe, loggat på både server och klient): i de felande fallen tog
	klienten aldrig emot serverns placering. Hon hoppade ur sitsen och
	blev stående på ryggen PÅ KLIENTEN medan servern ägde kroppen. När
	ägarskapet lämnades tillbaka (hjärtslag 8) vann klientens läge och
	replikerades hjärtslag 26–34 efter avsittningen. En kontroll vid
	hjärtslag 10 kom alltså före felet. En ny placering när klienten väl
	äger kroppen fastnar (mätt: 2 s utan återfall). ]]
local AVSITT_KONTROLL = 90
local AVSITT_OMPLACERINGAR = 2
local AVSITT_RYGGHOJD = 1.5

function HorseService._paHastrygg(modell: Model, karaktar: Model): boolean
	local rot = modell.PrimaryPart or modell:FindFirstChild("HumanoidRootPart")
	local krot = karaktar:FindFirstChild("HumanoidRootPart")
	if not (rot and rot:IsA("BasePart") and krot and krot:IsA("BasePart")) then return false end
	local lokal = rot.CFrame:PointToObjectSpace(krot.Position)
	local iSidled = math.abs(lokal.X) <= rot.Size.X / 2 and math.abs(lokal.Z) <= rot.Size.Z / 2
	return iSidled and (krot.Position.Y - rot.Position.Y) > AVSITT_RYGGHOJD
end

--[[ ══ #264 PLAYER_FLOW_CLOSURE_R5: EN FASTNAD LANDNING, INTE ETT HOPP ══════

	Bevakningen såg bara «ovanför ryggen». Ett oberoende prov på 941ffeb,
	genom riktiga tryMount/dismount, satte kroppen 6 studs ovanför hästroten
	vid hjärtslag 25 med fart uppåt 12 och luftburet tillstånd — ett hopp —
	och fick en tredje placering med fart 0.

	Det uppmätta felet (c1946fe, R3) var en STÅENDE kropp på ryggen:
	+4,2 studs, tillstånd Running, fart 0,7 → 0. En luftburen kropp — i
	hopp eller fall, enligt sitt tillstånd eller sin vertikala fart — står
	inte på hästen, och får fortsätta. Landar den sedan på ryggen inom
	fönstret rättas den som förut. ]]
local AVSITT_LUFTFART = 2.0

function HorseService._luftburen(karaktar: Model): boolean
	local hum = karaktar:FindFirstChildOfClass("Humanoid")
	if hum then
		local ok, tillstand = pcall(function() return hum:GetState() end)
		if ok and (tillstand == Enum.HumanoidStateType.Freefall
			or tillstand == Enum.HumanoidStateType.Jumping) then
			return true
		end
	end
	local krot = karaktar:FindFirstChild("HumanoidRootPart")
	if krot and krot:IsA("BasePart")
		and math.abs(krot.AssemblyLinearVelocity.Y) > AVSITT_LUFTFART then
		return true
	end
	return false
end

local STANNA_HJARTSLAG = 8

local function stannaHast(session: Session)
	local hum = session.rig.humanoid
	local root = session.rig.root
	local function noll()
		if hum and hum.Parent then
			hum.WalkSpeed = 0
			hum:Move(Vector3.zero, false)
			hum.Jump = false
		end
		if root.Parent then
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end
	end
	noll()
	--[[ Stoppet är en ÄNDRING AV SERVERNS TRAPPA, inte bara av två
	     attribut. Skrevs attributen direkt här hade sessionen fortsatt
	     tro att hon travade, och nästa BROMS hade stegat ned från trav
	     till skritt på en häst som redan stod still. ]]
	local franIndex = session.stegIndex
	session.stegIndex = Gaits.index("halt")
	--[[ Loggas bara om ritten fortfarande är öppen. Efter en avsittning
		är märket redan nil och ritten stängd. ]]
	loggaSteg(session, franIndex, "stopp", nil)
	replikera(session)
	session.rig.model:SetAttribute("Speed", 0)
	task.spawn(function()
		for _ = 1, STANNA_HJARTSLAG do
			RunService.Heartbeat:Wait()
			if session.rider ~= nil then return end
			noll()
		end
	end)
end

--[[ ══ ÅTERLÄMNINGEN AV KROPPENS ÄGARSKAP ══════════════════

	Robustness Slice F. Raden löd `pcall(function() krot:SetNetworkOwner(
	spelare) end)` och kastade både utfallet och skälet. En misslyckad
	återlämning lämnade alltså kroppen serverstyrd utan ett spår av varför.

	FÖRHANDSKONTROLLEN. `BasePart:CanSetNetworkOwnership()` svarar `true`,
	eller `false` plus ett skäl som sträng — dokumenterat som just det
	sättet att veta om `SetNetworkOwner` kan anropas utan att kasta.

	VI KÄNNER INTE SKÄLTEXTERNA, och låtsas inte göra det. Roblox
	dokumenterar ATT en skälsträng kommer, men inte vilka de är; det enda
	som står om själva förbudet är att servern alltid äger ankrade delar.
	Koden jämför därför aldrig mot en sträng — den skickar vidare det den
	fick.

	OCH EN SAKNAD FÖRHANDSKONTROLL FÅR INTE TA BORT EN ÅTERLÄMNING SOM
	SKULLE HA FUNGERAT. Kastar kontrollen själv — eller finns den inte —
	säger vi det och försöker ändå. Bara ett uttryckligt `false` stoppar. ]]
local function aterlamnaAgarskap(krot: BasePart, spelare: Player,
	karaktar: Model): boolean
	local vem = ("%s/%s"):format(spelare.Name, karaktar.Name)

	local kunde, kan, skal = pcall(function()
		return krot:CanSetNetworkOwnership()
	end)
	if kunde and kan ~= true then
		warn(("[Horse] ägarskapet åter till spelaren efter avsittning NEKADES "
			.. "för %s: %s"):format(vem, tostring(skal)))
		return false
	end
	if not kunde then
		warn(("[Horse] ägarskapet åter till spelaren efter avsittning: "
			.. "förhandskontrollen gick inte att göra för %s (%s) — "
			.. "försöker ändå"):format(vem, tostring(kan)))
	end

	local satt, fel = pcall(function() krot:SetNetworkOwner(spelare) end)
	if not satt then
		warn(("[Horse] ägarskapet åter till spelaren efter avsittning "
			.. "MISSLYCKADES för %s: %s"):format(vem, tostring(fel)))
		return false
	end
	return true
end

local function stallAv(modell: Model, karaktar: Model)
	local krot = karaktar:FindFirstChild("HumanoidRootPart")
	if not (krot and krot:IsA("BasePart")) then return end
	local cf = HorseService._avsittningsplats(modell, karaktar)
	if not cf then
		warn(("[Horse] Ingen fri avsittningsplats vid %s"):format(modell.Name))
		return
	end
	local spelare = Players:GetPlayerFromCharacter(karaktar)
	--[[ Klientägarskapet skriver annars tillbaka ryttaren till sitsens läge
		bildrutan efter serverns PivotTo. Håll kroppen på servern kort över
		placeringen och lämna sedan tillbaka den till spelaren. ]]
	pcall(function() krot:SetNetworkOwner(nil) end)
	karaktar:PivotTo(cf)
	--[[ FARTEN NOLLAS. Ryttaren har hästens hastighet i kroppen när hon
		lossnar, och en flytt utan nollning slänger iväg henne. ]]
	krot.AssemblyLinearVelocity = Vector3.zero
	krot.AssemblyAngularVelocity = Vector3.zero
	if spelare then
		task.spawn(function()
			for _ = 1, 8 do RunService.Heartbeat:Wait() end
			--[[ Vakten är oförändrad: roten finns kvar, spelaren finns
			     kvar, och det är fortfarande SAMMA kropp. En ny kropp har
			     ett eget ägarskap och ska inte få det här. ]]
			if krot.Parent and spelare.Parent and spelare.Character == karaktar then
				aterlamnaAgarskap(krot, spelare, karaktar)
			end
		end)
	end
end

--[[ Avsittningen svarar med ett SKÄL när den nekar (#202 punkt 3).

	Förut föll båda nejen ut som ett naket `false`. `DismountRequest` ger
	det vidare till klienten, som skriver `skalText(nil)` — alltså den
	generiska "det gick inte nu" — och spelaren fick veta att något inte
	gick, men inte vad. Allt annat i den här kedjan bär en namngiven nyckel;
	det här var det enda hålet.

	Mätt i Studio på `e6a674c`:

	    DismountRequest              -> ok=true
	    DismountRequest igen         -> ok=false  skal=nil     <- hålet

	Dubbel avsittning är i sig inget fel — `Pass` säger det uttryckligen, och
	sitsens `Occupant`-lyssnare kan nå hit strax efter spelarens egen
	begäran. Det som ändras är bara att nejet går att läsa. ]]
--[[ SÄG VAD SOM FAKTISKT GÄLLER.

	Anropas när en avsittning nekats. Servern äger sanningen, så den
	skickar sitt eget läge till just den klienten: rider hon fortfarande
	får hon `MountChanged` med sig själv som ryttare, och klientens
	lyssnare sätter upp henne igen.

	SVARAR `false` NÄR DET INTE FANNS NÅGOT ATT RÄTTA. Är `byRider` tom
	anser servern inte att hon rider — då var klientens rivning RÄTT, och
	att skicka något hade varit att hitta på ett läge. Skillnaden är värd
	ett returvärde: ett prov ska kunna se att tystnaden var ett beslut.

	── EN TRASIG BOKFÖRING ÄR INTE ETT LÄGE ATT ÅTERVÄNDA TILL ──────

	Re-review runda 2 av `f6ff67d`. Första versionen läste `byRider` och
	litade på den. Men `hast.oregistrerad` betyder PRECIS att den kartan
	ljuger: ryttaren står bokförd på en häst vars session är borta. Att
	skicka `MountChanged` på den uppgiften hade satt upp klienten på en
	häst servern inte kan köra — en uppfunnen ritt ovanpå en trasig
	bokföring.

	Saknas sessionen städas posten i stället, och vi svarar `false`.
	Klientens rivning var då rätt, och nästa uppsittning börjar från ett
	rent läge i stället för att ärva lögnen. ]]
function HorseService.aterforena(player: Player): boolean
	local model = byRider[player]
	if not model then return false end
	if not sessions[model] then
		byRider[player] = nil
		warn("[Horse] aterforena: stale byRider utan session, posten stadad")
		return false
	end
	Net.get("MountChanged"):FireClient(player, model, Aktor.klient(player))
	return true
end

--[[ `orsak` sätts bara av tjänstens egna städvägar (död, karaktären
	borta, sitsen, spelaren lämnar) och avgör om ridloggen stängs som
	avslutad eller avbruten. `DismountRequest` skickar den aldrig vidare —
	klientens argument når inte hit — så en begärd avsittning är alltid
	"avsittning". ]]
function HorseService.dismount(player: Player, orsak: string?): (boolean, string?)
	local model = byRider[player]
	if not model then return false, "pass.rider_inte" end
	local session = sessions[model]
	--[[ Ryttaren är bokförd men sessionen är borta: ett trasigt läge, inte
		"du rider inte". Egen nyckel, så att de två går att skilja åt i en
		logg. ]]
	if not session then return false, "hast.oregistrerad" end

	--[[ Kopplingarna rivs FÖRST. Annars fyrar Occupant-lyssnaren när vi
		själva reser ryttaren och anropar `dismount` igen mitt i. ]]
	slappStadning(player)

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	--[[ Blockerare 4: avsittningen gjorde `seat:Sit(nil)`. `Seat:Sit` tar en
		humanoid som ska SÄTTA SIG; att skicka nil är inte en dokumenterad
		väg att resa någon. Den verifierade vägen är `Humanoid.Sit = false`,
		vilket lossar sitsens egen `SeatWeld`. Faller det bort tas welden
		bort direkt, så en trasig sits inte låser ryttaren fast. ]]
	if humanoid and session.rig.seat and session.rig.seat.Occupant == humanoid then
		humanoid.Sit = false
		if session.rig.seat.Occupant == humanoid then
			local weld = session.rig.seat:FindFirstChild("SeatWeld")
			if weld then weld:Destroy() end
		end
	end
	if humanoid then
		humanoid.PlatformStand = false
	end

	--[[ TILLSTÅNDET STÄDAS FÖRE KROPPEN PLACERAS.

		`setRider(session, nil)` nollar `byRider`, `RiderUserId` och
		nätverksägaren. Den låg förut SIST, efter placeringen, och det gjorde
		den fördröjda placeringen nedan omöjlig att lita på: `task.spawn`
		börjar köra direkt, alltså mitt i den här funktionen, och dess vakt
		"har hon hunnit sätta sig igen?" läste då ett `byRider` som
		fortfarande pekade på hästen hon just klev av. Vakten sa ja varje
		gång och placeringen hoppades över.

		Ordningen är dessutom den riktigare: vem som rider vad är ett
		LOGISKT tillstånd, var kroppen står är ett fysiskt. Det logiska ska
		vara sant först. ]]
	setRider(session, nil, orsak or "avsittning")
	stannaHast(session)

	if character then
		local root = character:FindFirstChild("HumanoidRootPart")
		if root then
			local weld = root:FindFirstChild("HorseMount")
			if weld then weld:Destroy() end
		end
		local modell = session.rig.model
		local seat = session.rig.seat
		--[[ Direkt, så att den som mäter i samma bildruta ser rätt läge. ]]
		stallAv(modell, character)
		--[[ OCH EN GÅNG TILL NÄR SITSEN FAKTISKT HAR SLÄPPT. Den andra
			gången är den som håller: så länge `seat.Occupant` pekar på
			ryttaren äger sitsen hennes läge och skriver tillbaka det efter
			vår flytt. Se noten vid `AVSITT_MARGINAL`. ]]
		task.spawn(function()
			for _ = 1, AVSITT_VANTA do
				local kvar = (humanoid ~= nil and humanoid.Sit)
					or (seat ~= nil and humanoid ~= nil and seat.Occupant == humanoid)
				if not kvar then break end
				task.wait()
			end
			--[[ Hann karaktären eller hästen försvinna under väntan är det
				inget kvar att placera — avsittningen kan ha kommit ur
				`CharacterRemoving`. ]]
			if not (character.Parent and modell.Parent) then return end
			--[[ OCH HANN HON SÄTTA SIG IGEN ÄR HON INTE VÅR ATT FLYTTA.
				En halv sekund räcker gott för att kliva upp på nästa häst,
				och en sen placering hade då ryckt ner henne på marken
				mitt i uppsittningen. Två frågor, båda om NUET: sitter hon
				på något, och är hon registrerad som ryttare någonstans. ]]
			if humanoid and humanoid.Sit then return end
			if byRider[player] then return end
			stallAv(modell, character)
			--[[ #264 PLAYABLE_UI_AND_DISMOUNT_R2: KONTROLLERA UTFALLET.
				Mätt i Studio (kandidat e5881dc, ren väg, mitt på banan):
				1 av 5 avsittningar lämnade henne STÅENDE PÅ HÄSTRYGGEN —
				servern såg roten 4,2 studs över hästens rot och
				`FloorMaterial` = hästen, i minst 3 s. Orsaken står vid
				`AVSITT_KONTROLL`: klientens eget läge vinner när ägarskapet
				lämnas tillbaka. Utfallet bevakas därför varje hjärtslag
				genom hela fönstret, och står hon ovanpå hästen placeras hon
				igen — högst `AVSITT_OMPLACERINGAR` gånger. ]]
			local omplacerad = 0
			for _ = 1, AVSITT_KONTROLL do
				RunService.Heartbeat:Wait()
				if not (character.Parent and modell.Parent) then return end
				if (humanoid and humanoid.Sit) or byRider[player] then return end
				if HorseService._paHastrygg(modell, character)
					and not HorseService._luftburen(character) then
					warn(("[Horse] avsittningen landade på %s — placeras igen"):format(modell.Name))
					stallAv(modell, character)
					omplacerad += 1
					if omplacerad >= AVSITT_OMPLACERINGAR then return end
				end
			end
		end)
	end
	return true, nil
end

--[[ ── Uthållighet ─────────────────────────────────────────────────── ]]

--[[ Hur fort hästen FAKTISKT rörde sig, mätt på servern (#169 P1).

	Planfart: höjdledet räknas inte, annars hade ett fall eller en trappa
	läst som galopp. Mätningen skrivs in i sessionen och används av
	tröttheten nedan.

	Teleporthoppet är inte kosmetik. Utan det ger ett respawn eller en
	fysikstöt ett enda hjärtslag med hundratals studs/s, och hästen hade
	tappat energi för en sträcka hon aldrig sprang. ]]
local function observera(session: Session, dt: number): number
	local root = session.rig.root
	if not root or not root.Parent or dt <= 0 then return session.observerad end
	local nu = root.Position
	local d = nu - session.lastPosition
	session.lastPosition = nu
	local plan = math.sqrt(d.X * d.X + d.Z * d.Z)
	if plan > TELEPORT_GRANS * dt then
		--[[ Hoppet förkastas, men positionen är redan uppdaterad: nästa
		     mätning utgår från det nya läget och inte från det gamla. ]]
		session.observerad = 0
		return 0
	end
	session.observerad = plan / dt
	return session.observerad
end

local function stepStamina(session: Session, dt: number)
	local stats = session.stats
	--[[ SERVERNS EGEN TRAPPA, inte attributet den nyss skrev (#233 Fas
	     4b). Raden läste `GetAttribute("Gait")`, vilket var rätt så länge
	     attributet var det enda minnet — men att läsa tillbaka sin egen
	     replikering är en omväg som tål en skrivning från fel håll. Nu är
	     `stegIndex` sanningen och attributet dess avtryck. ]]
	local gaitR = Ridtrappa.gangart(session.stegIndex)

	--[[ ── KLIENTEN ÄGER INTE TRÖTTHETEN (#169 P1, kvar i Fas 4b) ──────
	     Regeln stod förut mot en gångart klienten SKREV. Den gångarten
	     är serverns nu, men vakten behövs oförändrat — och det är värt
	     att säga varför, så att ingen tar bort den som överflödig:

	     nätverksägarskapet ligger hos ryttaren (`SetNetworkOwner` i
	     `setRider`), så en manipulerad klient kan flytta hästen fysiskt
	     hur fort som helst utan att skicka en enda avsikt. Serverns
	     accepterade gångart kan alltså stå i "halt" medan hästen faktiskt
	     galopperar över gården. Trappan säger vad ryttaren BEGÄRT och
	     fått; den säger inte hur fort hon rör sig.

	     Nu vägs klientens påstående mot serverns egen mätning, och den
	     HÖGRE av de två driver energin. Att ljuga nedåt ger ingenting —
	     mätningen avslöjar farten. Att ljuga uppåt ger bara mer dränering
	     än man förtjänar, alltså ingen vinst heller.

	     Bara för en RIDEN häst. En lös häst som knuffas av fysiken ska
	     inte tröttna av det. ]]
	local energiGangart = gaitR
	if session.rider then
		local observerad = observera(session, dt)
		--[[ INFRA-2B1: samma hjärtslagssteg, samma rot och samma
			teleportgräns som `observera` — men en EGEN baslinje per ritt,
			så att uthållighetens mätpunkt inte rörs. Observationen läser
			bara; den ändrar inte rörelse, uthållighet eller ägarskap. ]]
		local obsRot = session.rig.root
		logga(RidObservation.sampla, session.rittId,
			if obsRot and obsRot.Parent then obsRot.Position else nil,
			dt, Ridtrappa.gangart(session.stegIndex), Ridtrappa.ryggar(session.stegIndex),
			TELEPORT_GRANS)
		--[[ Utan `current`: hysteresen finns för att animationen inte ska
		     flimra, och den får inte kunna hålla kvar ett påstått "halt"
		     en bit upp i skrittbandet. Auktoriteten mäter på bandet. ]]
		local sedd = Gaits.forSpeed(observerad)
		if Gaits.index(sedd) > Gaits.index(gaitR) then
			energiGangart = sedd
		end
	end
	gaitR = energiGangart

	--[[ ── EN TRÖTTHETSSANNING (senior re-review #87, blocker 3) ───────
	     Här fanns förut en EGEN uthållighetsmodell: `Gaits.stamina` per
	     gångart, egen återhämtningsfördröjning och en egen skala 0–100.
	     Samtidigt räknade klienten G02-B:s `energi` med kanonens tal och
	     lät den styra framåtbjudning och svarstid. Två trötthetsmodeller
	     på samma häst: den ena kunde göra henne segare, den andra sänka
	     gångartstaket — och de kunde säga olika saker samtidigt.

	     Nu är ENERGIN den enda sanningen, med servern som auktoritet och
	     klienten som prediktion. Dräneringen är kanonens `energiTakt`,
	     alltså exakt samma tal som webben och klienten räknar med.

	     `Gaits.stamina` läses inte längre. Taket är kvar som eget
	     PRODUKTBEGREPP — en trött häst rullar ned en gångart av sig
	     själv — men det drivs nu av samma energi och inte av en andra
	     modell. Det är skillnaden mellan två begrepp och två sanningar. ]]
	local webbGangart = "halt"
	for w, r in RidKanon.MOTSVARIGHET do
		if r == gaitR then webbGangart = w end
	end
	--[[ Uthålligheten (Endurance) skalar takten: en seg häst tär
	     långsammare och hämtar sig fortare. Det är samma roll statet hade
	     i den gamla modellen, nu på kanonens kurva. ]]
	local takt = Svar.energiTakt(webbGangart, 0, stats)
	local skala = if takt < 0 then 1 / (0.6 + 0.9 * stats.Endurance)
		else (0.6 + 0.9 * stats.Endurance)
	session.energi = math.clamp(session.energi + takt * skala * dt, 0, 1)
	if takt < 0 then session.lastExertion = os.clock() end

	--[[ Uthålligheten tvingar aldrig fram ett stopp. Den sänker taket, och
	     hästen rullar ned en gångart av sig själv. Det är läsbart för
	     spelaren och känns som en trött häst, inte som en tom bensintank. ]]
	local ceiling = Gaits.SPELBAR_TOPP
	if session.energi < Config.STAMINA.LowThreshold then
		local t = session.energi / Config.STAMINA.LowThreshold
		local floorIndex = Gaits.index(Config.STAMINA.FloorGait)
		local topIndex = Gaits.index(Gaits.SPELBAR_TOPP)
		ceiling = Gaits.byIndex(math.floor(floorIndex + (topIndex - floorIndex) * t + 0.5))
	end

	local visad = session.energi * stats.MaxStamina
	session.rig.model:SetAttribute("Stamina", math.floor(visad))
	session.rig.model:SetAttribute("GaitCeiling", ceiling)

	--[[ ── TAKET DRAR NED TRAPPAN SJÄLVT (#233 Fas 4b) ─────────────────
	     Förut satt den här rättelsen i `onStateSync`: klienten fortsatte
	     rapportera galopp, och servern klampade ned det par den fick. Det
	     fungerade bara så länge klienten SA något — en klient som tystnade
	     lämnade attributet kvar över taket.

	     Nu äger servern gångarten, och då måste den sänka den själv när
	     uthålligheten sänker taket. Hästen rullar ned en gångart av sig
	     själv, precis som kommentaren ovan lovar, och ryttaren får veta
	     det genom samma reconcile-väg som ett nekat DRIV.

	     Bara nedåt. Ett stigande tak öppnar gångarten igen, men det är
	     ryttaren som ska be om steget — hästen ska inte accelerera för
	     att hon hämtat andan. ]]
	local underTak = Ridtrappa.underTak(session.stegIndex, ceiling)
	if underTak ~= session.stegIndex then
		local franIndex = session.stegIndex
		session.stegIndex = underTak
		loggaSteg(session, franIndex, "trotthet", nil)
		replikera(session)
	end

	if session.rider then
		--[[ Fjärde argumentet är energin i sin KANONISKA skala 0–1.
		     Klienten sätter sin prediktion till den; de tre första är
		     presentationen, som Debug redan visar. ]]
		local kSta = Aktor.klient(session.rider)
		if kSta then
			Net.get("StaminaSync"):FireClient(kSta, visad, stats.MaxStamina,
				ceiling, session.energi)
		end
	end
end

--[[ ══ AVSIKTEN — SERVERN ÄGER GÅNGARTEN (#233 Fas 4b) ═══════════════

     FÖRE: klienten räknade fram sin gångart, skickade RESULTATET
     `StateSync(gait, speed)`, och servern prövade om paret var rimligt.
     Det gav tre hål som auditen på #239 mätte upp och redovisade:

       · avsikten fanns inte på tråden — bara utfallet,
       · servern hade inget minne av föregående gångart och kunde därför
         inte validera en ÖVERGÅNG: `halt → canter` i ett hopp passerade
         så länge tempot följde med,
       · takten mättes bara som paket per sekund, inte som hjälper.

     EFTER: klienten skickar `driv` eller `broms`. Servern stegar sin egen
     trappa, validerar, och replikerar utfallet. Klienten får prediktera
     för att knappen ska kännas omedelbar, men hennes prediktion är en
     GISSNING som rättas av `RidTillstand`.

     Vad som INTE har ändrats, och som ordern ber mig redovisa: hästen
     rör sig fortfarande av ryttarens klient via `SetNetworkOwner`. Det
     här är en auktoritetsmigration för GÅNGARTEN, inte en fysikmigration.
     En manipulerad klient kan alltjämt flytta hästen fysiskt — men den
     kan inte längre få servern att kalla det galopp, och kan därför inte
     komma åt det taket, den uthålligheten eller den replikerade sanning
     andra spelare ser. ]]

--[[ Varför avslag är TYSTA: ett avslag som svarar med ett felmeddelande
     är en orakelmaskin för den som letar efter gränserna, och en
     bandbreddskostnad för den som spammar. Den ärliga klienten behöver
     inget skäl — den behöver SANNINGEN, och den får den genom
     `replikera`, som är samma väg som ett accepterat steg. ]]
local function onRidingIntent(player: Player, rittId: any, handling: any, sekvens: any)
	--[[ 1. RIDER HON ÖVER HUVUD TAGET, och i så fall vad?

	     Hästen står medvetet INTE i argumentet. Servern slår upp den ur
	     `byRider`, och det är precis det som gör att en spelare inte kan
	     adressera någon annans häst: det finns ingen parameter att ljuga
	     i. En klient som skickar en modell får den ignorerad. ]]
	local model = byRider[player]
	if not model then return end
	local session = sessions[model]
	if not session then return end
	--[[ Sessionen ska höra till DEN HÄR spelaren. `byRider` och
	     `session.rider` sätts båda i `setRider`, men de är två tabeller,
	     och en avsikt som kommer mitt i ett ryttarbyte ska falla i stället
	     för att träffa den som råkar stå i den ena. ]]
	if session.rider ~= player then return end

	--[[ 2. RITTEN. FÖRE skopan, sekvensen, spärren och tillståndet.

	     Ordningen är kravet ur ChatGPT-reviewen av #241, och den är inte
	     formell: varenda grind under den här raden har ett MINNE som
	     skrivs — skopan töms, sekvensen räknas upp, spärren flyttas.
	     Prövades märket efter dem kunde ett paket från en gammal ritt
	     fortfarande förbruka den nya rittens polletter eller flytta dess
	     spärr, även om steget till slut nekades.

	     Nil-märket är det viktiga fallet och inte en bivakt: mellan
	     avsittning och nästa uppsittning är `session.rittId` nil, och då
	     matchar ingen sträng. Ett fördröjt paket har inget att träffa. ]]
	if typeof(rittId) ~= "string" then return end
	if session.rittId == nil or rittId ~= session.rittId then return end

	--[[ 3. SKOPAN. En spammare ska kosta en jämförelse, inte en
	     genomgång. ]]
	local nu = os.clock()
	session.intentPolletter = math.min(Config.RIDINPUT.SkopaTak,
		session.intentPolletter + (nu - session.intentSenast) * Config.RIDINPUT.SkopaPafyll)
	session.intentSenast = nu
	if session.intentPolletter < 1 then return end
	session.intentPolletter -= 1

	--[[ 4. PAYLOADEN. Ordförrådet är två ord och ingenting annat. ]]
	if not Ridtrappa.arHandling(handling) then return end

	--[[ Sekvensen är frivillig — en klient som inte dedupliceras skickar
	     inget — men om den finns ska den vara ett tal, ändligt, och
	     STRIKT större än den senast accepterade. Ett återspelat paket har
	     samma nummer som ett redan accepterat och ändrar därför
	     ingenting.

	     NaN faller på olikheten mot sig själv, ±inf på jämförelsen mot
	     `sekvens` efter att den passerat. Ett decimaltal är tillåtet: det
	     är monotonin som är regeln, inte heltaligheten. ]]
	if sekvens ~= nil then
		if typeof(sekvens) ~= "number" then return end
		if sekvens ~= sekvens or sekvens == math.huge or sekvens == -math.huge then return end
		if sekvens <= session.sekvens then return end
	end

	--[[ 5. IMPULSSPÄRREN — serverns, inte klientens.

	     Klientens `Input.IMPULS_SPARR` finns kvar och gör samma sak den
	     alltid gjort, men den är presentation: den som byter ut sin klient
	     byter också ut den spärren. Den här raden är den som håller.

	     Marginalen är dokumenterad i `Config.RIDINPUT` och finns för att
	     två ärliga hjälper 0,60 s isär kan nå servern tätare än så. ]]
	local sparr = Config.RIDINPUT.ImpulsSparr - Config.RIDINPUT.ServerMarginal
	if nu - session.sisteHjalp < sparr then
		--[[ ETT NEJ AR OCKSA ETT SVAR (#264, spelbarhetsgranskningen).

			Raden var ett naket `return`. Klienten hade REDAN predikterat
			overgangen, sa de tva stod i olika gangarter tills nasta
			ACCEPTERADE hjalp -- och kom ingen sadan lag divergensen kvar.
			Takavslaget tio rader ner gjorde redan tvartom, av exakt samma
			skal. Det drabbar arlig input: tva tryck 0,65 s isar kan na
			hit 0,45 s isar vid varierande fordrojning.

			EN GANG PER FONSTER, inte en gang per paket. Kvittensen hor
			till den senast accepterade hjalpen, sa 200 spampaket ger ETT
			extra svar totalt. Sparren sjalv ar helt orord -- den har
			grenen andrar bara om servern SAGER nagot nar den sager nej. ]]
		if session.nekKvitterad ~= session.sisteHjalp then
			session.nekKvitterad = session.sisteHjalp
			replikera(session)
		end
		return
	end

	--[[ 6. STEGET. Ett, aldrig fler, och aldrig förbi taket uppåt.

	     `Ridtrappa.steg` returnerar oförändrat index när steget inte får
	     tas — mot taket uppåt, mot rygga nedåt. Då har ingenting hänt, och
	     då ska varken spärren eller sekvensen räknas upp: en ryttare som
	     trycker DRIV i galopp med sänkt tak ska inte straffas med en
	     förbrukad hjälp. ]]
	local tak = session.rig.model:GetAttribute("GaitCeiling") or Gaits.SPELBAR_TOPP
	local nyttIndex = Ridtrappa.steg(session.stegIndex, handling, tak)
	if nyttIndex == session.stegIndex then
		--[[ Ingen ändring — men klienten kan ha predikterat ett steg hon
		     inte fick. Hon ska rättas, annars står de i olika gångarter
		     tills nästa accepterade hjälp. ]]
		replikera(session)
		return
	end

	local franIndex = session.stegIndex
	session.stegIndex = nyttIndex
	session.sisteHjalp = nu
	if sekvens ~= nil then session.sekvens = sekvens end
	--[[ Loggas HÄR och bara här i den här handlaren: efter ritten,
		skopan, payloaden, sekvensen, spärren och steget. Varje tidigare
		`return` är ett nej, och ett nej loggas inte. ]]
	loggaSteg(session, franIndex, "hjalp", handling)
	replikera(session)
end

--[[ ── Validering av den fart klienten rapporterar ────────────────────

     REMOTEN BÄR INGEN GÅNGART LÄNGRE (#233 Fas 4b). Argumentet är farten
     och bara farten; se `Networking.DEFINITIONS` för varför det är
     strukturellt och inte en regel som kan glömmas bort.

     VILKA KONSUMENTER SOM LÄSER DEN RAPPORTERADE FARTEN — ordern ber mig
     redovisa det exakt, och svaret är kortare än väntat:

       `Speed`-attributet    skrivs här. Uppmätt med grep över hela
                             `roblox/src`: INGEN modul läser det. Det är
                             ren presentation/diagnostik, och sedan Fas 4b
                             är det också allt det kan vara.
       `Gait`-attributet     läses av `stepStamina`, och kommer sedan Fas
                             4b ur serverns egen trappa — inte härifrån.

     Missbruket begränsas alltså av två saker: farten kan inte längre
     flytta någon gångart, och `stepStamina` väger serverns EGEN
     observerade fart (`observera`) mot den accepterade gångarten. Den som
     ljuger om farten ljuger till en variabel ingen fattar beslut av. ]]
local function onStateSync(player: Player, speed: any)
	local model = byRider[player]
	if not model then return end
	local session = sessions[model]
	if not session then return end
	if session.rider ~= player then return end
	if typeof(speed) ~= "number" then return end
	--[[ NaN faller på olikheten mot sig själv; ±inf faller på gränserna. ]]
	if speed ~= speed or speed < -3 or speed > 15 then return end

	--[[ ── TAKTEN (#169 P1) ────────────────────────────────────────────
	     Varje accepterad händelse skriver två replikerade attribut. Utan
	     en gräns kunde en klient göra det tusen gånger i sekunden. Skopan
	     fylls på i efterhand så att normal 10 Hz aldrig tar slut, och
	     händelsen släpps helt när den är tom — ingen kö, inget minne att
	     fylla. ]]
	local nu = os.clock()
	session.polletter = math.min(RATE_TAK,
		session.polletter + (nu - session.lastPollett) * RATE_PAFYLL)
	session.lastPollett = nu
	if session.polletter < 1 then return end
	session.polletter -= 1

	--[[ ── FARTEN MÄTS MOT SERVERNS GÅNGART (#169 P1 → #233 Fas 4b) ────
	     Regeln var "tempot måste ligga i den PÅSTÅDDA gångartens band".
	     Den påstådda gångarten finns inte längre, och det är en skärpning:
	     bandet kommer nu ur den gångart servern själv accepterat, alltså
	     ur något klienten inte kan välja.

	     KLAMPAS, INTE NEKAS. Under en övergång passerar tempot legitimt
	     genom grannbandet — hon accelererar upp genom skrittfarten på väg
	     in i traven — och ett avslag där hade frusit `Speed` mitt i varje
	     uppstegring. Klampningen tar bort missbruket utan att strypa den
	     ärliga ritten, och eftersom ingen modul fattar beslut av `Speed`
	     är det gott nog.

	     BAKÅT ÄR ETT EGET FALL, och det höll på att kosta backningen en
	     gång redan (#239). Hon ryggar i halt, så bandet säger ingenting om
	     det; ryggningen är serverns egen trappa och gränsen är backtempot
	     med marginal. ]]
	local h = Gaits.HYSTERESIS
	local gangart = Ridtrappa.gangart(session.stegIndex)
	if speed < 0 then
		--[[ Negativ fart är bara meningsfull när servern accepterat
		     ryggning. Gör den inte det är det ett påstående utan täckning,
		     och det klampas till noll i stället för att skrivas. ]]
		if Ridtrappa.ryggar(session.stegIndex) then
			speed = math.max(speed, -(Config.MOVEMENT.ReverseSpeed + h))
		else
			speed = 0
		end
	else
		local band = Gaits.BY_NAME[gangart]
		speed = math.clamp(speed, 0, band.max + h)
	end

	--[[ `Gait` skrivs INTE här. Den raden var hela auktoritetshålet, och
	     att den är borta är poängen med Fas 4b. `replikera` är den enda
	     väg gångarten når ut. ]]
	session.rig.model:SetAttribute("Speed", speed)
	session.lastSync = nu
end

--[[ ── Livscykel ───────────────────────────────────────────────────── ]]

--[[ ══ REMOTENS EGEN VALIDERING (#252 DEL C) ═════════════════════

	`MountRequest` bar sitt eget nej — `hast.ogiltig` — for allt som inte
	ar en `Model`. Den raden har aldrig korts av nagon spec: bankens prov
	stubbar `InvokeServer` pa KLIENTSIDAN, och `OnServerInvoke` gar inte
	att lasa tillbaka ur motorn, sa en anonym funktion dar ar oatkomlig.
	BANK-AUDIT 2026-09-19 § 7 punkt 3.

	Handlaren har darfor ett namn. `Skopa.grind` ligger kvar UTANPA den:
	takten ar Gate 1A:s och fanns inte pa #256:s gren, sa hopslagningen
	behaller bada — namnet inuti, grinden runt om. ]]
function HorseService.mountRequest(player: Player, model: Model): (boolean, string?, string?)
	if typeof(model) ~= "Instance" or not model:IsA("Model") then
		return false, "hast.ogiltig"
	end
	return HorseService.tryMount(player, model)
end

--[[ ── DEN SOM LAMNAR (#252 DEL C) ──────────────────────────

	Samma skal som `GameplayService.lamnar` och `LedService.lamnar`:
	stadningen efter en spelare som gar ar en av de fyra saker
	runtime-grinden ska kunna falla pa, och den maste da kunna koras
	genom produktionens EGEN handlare i stallet for genom en kopia. ]]
function HorseService.lamnar(player: Player)
	HorseService.dismount(player, "lamnar")
	slappStadning(player)
end

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

	Net.get("MountRequest").OnServerInvoke = Skopa.grind("MountRequest",
		HorseService.mountRequest)
	--[[ ── ETT NEJ MÅSTE ÅTERFÖRENA, INTE BARA NEKA ──────────────────

	     ChatGPT-re-review av `269bec5`. Klienten river LOKALT innan den
	     frågar — säkerhet före undervisning — och står alltså av hästen
	     medan servern svarar. Svarar servern NEJ uppstår en delad
	     sanning: servern har kvar ryttaren i `byRider`, klienten har
	     rivit ekipaget.

	     Det värsta fallet är `takt.for_snabbt`. Då når anropet aldrig
	     `HorseService.dismount`, så ingenting i tjänsten kan upptäcka
	     att något behöver rättas — och spelaren blir stående bredvid en
	     häst hon enligt servern fortfarande sitter på.

	     Kommentaren i `begarAvsittning` påstod att «servern rättar oss
	     via MountChanged om den vill». Den gjorde den inte. Nu gör den
	     det, och rättelsen ligger utanför `Skopa.grind` så att den
	     täcker skopans eget nej lika väl som tjänstens. ]]
	local dismountGrind = Skopa.grind("DismountRequest",
		function(player)
			return HorseService.dismount(player)
		end)
	Net.get("DismountRequest").OnServerInvoke = function(player, ...)
		local ok, skal = dismountGrind(player, ...)
		if ok ~= true then
			HorseService.aterforena(player)
		end
		return ok, skal
	end
	Net.get("StateSync").OnServerEvent:Connect(onStateSync)
	--[[ #233 Fas 4b. Den semantiska vägen in. Ligger bredvid StateSync med
	     flit: de två är nu tydligt olika saker — den ena är en AVSIKT som
	     ändrar sanning, den andra en OBSERVATION som bara presenteras. ]]
	Net.get("RidingIntent").OnServerEvent:Connect(onRidingIntent)

	Players.PlayerRemoving:Connect(HorseService.lamnar)

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

--[[ Ridloggens post för en ritt som fryst djupkopia, eller nil när den
	aldrig fanns eller redan gallrats. Bara läsning; se `RidLogg`. Ingen
	konsument ännu (INFRA-2A). ]]
function HorseService.ridlogg(rittId: string?): any
	return RidLogg.ogonblick(rittId)
end

--[[ Ridobservationen för en ritt (INFRA-2B1): fryst djupkopia, eller nil.
	Serverns observation av klientägd fysik — inget fuskskydd, ingen
	belöning. Ingen konsument ännu. ]]
function HorseService.ridobservation(rittId: string?): any
	return RidObservation.ogonblick(rittId)
end

return HorseService
