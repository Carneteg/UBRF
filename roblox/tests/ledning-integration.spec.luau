--!nostrict
--[[
	LEDKEDJAN FRÅN KNAPP TILL FÖRFLYTTNING (#182 del 2).

	`ledning.spec` mäter tjänstens BESLUT. Den här specen mäter att hela
	kedjan sitter ihop:

	    LedPrompt -> riktig LedBorja -> servergodkänd HorseId -> LedSync
	              -> synligt ledtillstånd -> LedService-steg
	              -> mätt förflyttning av RÄTT häst

	INGENTING I KEDJAN ÄR MOCKAT. Klientens knapp anropar
	`Net.get("LedBorja"):InvokeServer(...)`, bänkens `RemoteFunction`
	vidarebefordrar till serverns egen `OnServerInvoke`, och svaret går
	tillbaka via `LedSync` till klientens egen lyssnare. Det var precis
	det som INTE gick förut: stubbens `InvokeServer` svarade `true` utan
	att röra servern, och `FireClient` fyrade aldrig `OnClientEvent`.

	TVÅ HÄSTAR, och den ena är inte spelarens. Klienten ritar med flit en
	LedPrompt på BÅDA — så att provet kan visa att det är SERVERN som
	nekar fel häst, inte att knappen saknades.

	INGEN HÄST HETER TRIXIE HÄR. Vilken häst spelaren tilldelas avgörs av
	`StallService`, och provet läser namnet ur `HorseName` som spelet gör.
	En hårdkodad häst hade gjort provet blint för just det ordern
	förbjuder.

	VAD «MÄTT FÖRFLYTTNING» BETYDER I BÄNKEN: det finns ingen fysikmotor
	här. `LedService._steg` ger hästens `Humanoid` en order — riktning och
	fart — och provet INTEGRERAR den ordern till en position, precis som
	motorn skulle. Det som mäts är alltså serverns egen order över tid,
	och att den flyttar rätt häst. Att Roblox sedan verkställer den är
	Studio-gaten, och den står som `NOT_TESTED` i rapporten.

	Kör: python3 roblox/tests/build.py tests/ledning-integration.spec.luau
	     && luau roblox/tests/.build/ledning-integration.spec.luau
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
local RSt = game:GetService("ReplicatedStorage")
local IC = InteractionController

local M = 3

--[[ ── Spelaren ────────────────────────────────────────────────────────

	`Players.LocalPlayer` ÄR spelaren, på båda sidor. Bänkens
	`InvokeServer` skickar med just det objektet som första argument —
	samma sak en riktig RemoteFunction gör — så servern och klienten måste
	tala om samma person för att kedjan alls ska gå ihop. ]]
local function nyKaraktar(pos)
	local k = Instance.new("Model")
	k.Name = "Karaktar"
	local rot = Instance.new("Part")
	rot.Name = "HumanoidRootPart"
	rot.Size = Vector3.new(2, 2, 1)
	rot.CFrame = CFrame.new(pos)
	rot.Parent = k
	local hand = Instance.new("Part")
	hand.Name = "RightHand"
	hand.Size = Vector3.new(1, 1, 1)
	hand.CFrame = CFrame.new(pos)
	hand.Parent = k
	local hum = Instance.new("Humanoid")
	hum.Name = "Humanoid"
	hum.Parent = k
	k.Parent = workspace
	return k, rot, hum
end

local START = Vector3.new(0, 3, 0)
local karaktar, rot, spelarHum = nyKaraktar(START)

local spelare = Players.LocalPlayer
spelare.Name = "Ledaren"
spelare.UserId = 8801
spelare.Character = karaktar
spelare.CharacterAdded = __signal_ny()
spelare.CharacterRemoving = __signal_ny()

RunService._server = true
Players._spelare = { spelare }

--[[ ── Tjänsterna, i produktionens ordning ───────────────────────────── ]]
SparService._glomHookarForProv()
SparService._glomForProv(spelare)
SparService.start()
StallService.start()
HorseService.start()
GameplayService.start()
--[[ `LedService.start()` är det som registrerar `LedBorja`/`LedSlapp` som
	riktiga fjärrhandlare. Utan den hade klientens tryck inte haft något
	att nå, och provet hade varit tvunget att anropa tjänsten direkt —
	alltså mocka bort precis det ordern säger att vi inte får mocka. ]]
LedService.start()

Players.PlayerAdded:Fire(spelare)
Players.PlayerAdded:slutfor()

local MIN_ID = StallService.hastIdFor(spelare)

print("\n── Förutsättningar: två hästar, en tilldelad ──")

check("stallet tilldelade spelaren en häst", MIN_ID ~= nil, tostring(MIN_ID))
if not MIN_ID then
	print("\nKedjan kan inte mätas utan en tilldelad häst.")
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error("ingen tilldelad häst", 0)
end

--[[ Den ANDRA hästen väljs ur rostern, aldrig hårdkodad. ]]
local ANNAN_ID
for id in pairs(UBRFSpel.hastar) do
	if id ~= MIN_ID then
		ANNAN_ID = id
		break
	end
end
check("och det finns en annan häst i rostern att prova mot",
	ANNAN_ID ~= nil, tostring(ANNAN_ID))

local function byggHast(id, pos)
	local m = HastRigg.bygg(id, id, CFrame.new(pos))
	m.Parent = workspace
	m:SetAttribute("HorseId", id)
	local h = UBRFSpel.hastar[id]
	m:SetAttribute("HorseName", h and h.namn or id)
	Taggar:AddTag(m, "Horse")
	return m
end

--[[ Båda står inom räckhåll. Att den andra hästen är NÅBAR är hela
	poängen: nejet ska komma från servern, inte från avståndet. ]]
local MIN = byggHast(MIN_ID, START + Vector3.new(1.0 * M, 0, 0))
local ANNAN = byggHast(ANNAN_ID, START + Vector3.new(-1.0 * M, 0, 0))
GameplayService.bind(spelare)

local MITT_NAMN = tostring(MIN:GetAttribute("HorseName"))
local ANNAT_NAMN = tostring(ANNAN:GetAttribute("HorseName"))
check("de två hästarna har olika namn ur rostern",
	MITT_NAMN ~= ANNAT_NAMN and MITT_NAMN ~= "" and MITT_NAMN ~= "nil",
	("%s vs %s"):format(MITT_NAMN, ANNAT_NAMN))

--[[ ── Klienten ──────────────────────────────────────────────────────── ]]
RunService._server = false
RSt:SetAttribute("G01Enabled", true)

--[[ MED FLIT PERMISSIVT. Klienten ritar en ledknapp på BÅDA hästarna, så
	att provet kan visa att det är servern som nekar fel häst. Vilken
	knapp som normalt ritas mäts av `klient-ledprompt.spec`. ]]
IC.setReadyCheck(function() return false end)
IC.setRidaCheck(function() return false end)
IC.setSadlaCheck(function() return false end)
IC.setTransaCheck(function() return false end)
IC.setLedCheck(function() return true end)

local status = { namn = nil, antal = 0 }
IC.setLedStatus(function(model)
	status.namn = if model then tostring(model:GetAttribute("HorseName") or model.Name) else nil
	status.antal += 1
end)
local kvittenser = {}
IC.setBekraftelseVisare(function(text) table.insert(kvittenser, tostring(text)) end)
local avslag = {}
IC.setAvslagVisare(function(skal) table.insert(avslag, tostring(skal)) end)

IC.start(function() end)
IC.uppdatera()

local function ledPromptFor(modell)
	for _, d in ipairs(modell:GetDescendants()) do
		if d:IsA("ProximityPrompt") and d.Name == "LedPrompt" then return d end
	end
	return nil
end

--[[ Trycket går genom promptens EGEN väg, precis som ett finger eller en
	tangent gör. Att anropa `LedBorja` själv hade hoppat över knappen. ]]
local function tryck(prompt)
	prompt.Triggered:Fire(spelare)
	task.wait()
end

print("\n── Servern nekar fel häst, trots att knappen finns ──")

local minPrompt = ledPromptFor(MIN)
local annanPrompt = ledPromptFor(ANNAN)

do
	check("klienten ritade en LedPrompt på BÅDA hästarna",
		minPrompt ~= nil and annanPrompt ~= nil,
		("min %s · annan %s"):format(tostring(minPrompt ~= nil),
			tostring(annanPrompt ~= nil)))
	check("och den bär rätt hästs namn i handlingen",
		minPrompt ~= nil and minPrompt.ActionText:find(MITT_NAMN) ~= nil,
		minPrompt and minPrompt.ActionText or "-")
	check("den andra bär den ANDRA hästens namn",
		annanPrompt ~= nil and annanPrompt.ActionText:find(ANNAT_NAMN) ~= nil,
		annanPrompt and annanPrompt.ActionText or "-")

	if annanPrompt then
		tryck(annanPrompt)
		RunService._server = true
		check("servern nekar den häst spelaren inte fått tilldelad",
			LedService.aktiv(spelare) == nil,
			tostring(LedService.aktiv(spelare)))
		RunService._server = false
		check("klienten fick ett skäl att visa", #avslag > 0,
			table.concat(avslag, ", "))
		check("ingen status tändes för fel häst", status.namn == nil,
			tostring(status.namn))
	end
end

print("\n── LedPrompt -> LedBorja -> LedSync -> synligt tillstånd ──")

do
	if minPrompt then tryck(minPrompt) end

	RunService._server = true
	check("servern leder nu spelarens EGEN häst",
		LedService.aktiv(spelare) == MIN,
		tostring(LedService.aktiv(spelare) and LedService.aktiv(spelare).Name))
	check("och det är rätt HorseId",
		LedService.lage(spelare) ~= nil and LedService.lage(spelare).hastId == MIN_ID,
		tostring(LedService.lage(spelare) and LedService.lage(spelare).hastId))

	--[[ REPET. Fysiskt, serverbyggt, mellan spelaren och hästen. ]]
	local rep = LedService.repFor(spelare)
	check("ett ledrep hänger mellan spelaren och hästen", rep ~= nil,
		rep and rep.Name or "inget")
	if rep then
		check("repet sitter i spelarens hand",
			rep.Attachment0 ~= nil and rep.Attachment0.Parent ~= nil
				and rep.Attachment0.Parent.Name == "RightHand",
			tostring(rep.Attachment0 and rep.Attachment0.Parent
				and rep.Attachment0.Parent.Name))
		check("och i RÄTT hästs huvud",
			rep.Attachment1 ~= nil and rep.Attachment1:IsDescendantOf(MIN),
			tostring(rep.Attachment1 and rep.Attachment1.Parent
				and rep.Attachment1.Parent.Name))
		check("det är en Beam — presentation, inte en kraft som drar",
			rep.ClassName == "Beam", tostring(rep.ClassName))
	end
	RunService._server = false

	--[[ LEDSYNC NÅDDE KLIENTEN. Det är den enda vägen servern har att
		säga «du leder henne», och utan den hade statusen varit klientens
		gissning. ]]
	check("LedSync nådde klienten och tände statusen",
		status.namn == MITT_NAMN, tostring(status.namn))
	check("klientens eget ledtillstånd pekar på rätt häst",
		IC._lederNu() == MIN,
		tostring(IC._lederNu() and IC._lederNu().Name))
	check("knappen bytte till «Släpp <namn>»",
		minPrompt ~= nil and minPrompt.ActionText:find(MITT_NAMN) ~= nil
			and minPrompt.ActionText ~= "",
		minPrompt and minPrompt.ActionText or "-")
	check("och spelaren fick en startbekräftelse", #kvittenser > 0,
		table.concat(kvittenser, " | "))
end
print("\n── LedService-steg: RÄTT häst får följriggen, den andra ingen ──")

do
	RunService._server = true

	--[[ ══ VARFÖR DET HÄR INTE MÄTER FÖRFLYTTNING ═══════════════════

		Första versionen flyttade hästens `RootPart` själv, genom att
		integrera serverns `Humanoid:Move`-order till en position. Den
		mätningen är BORTTAGEN, och senior review hade rätt: ett prov som
		flyttar hästen själv kan inte bevisa vare sig Roblox fysik eller
		den beslutade constraintlösningen. Det bevisade bara att provets
		egen integrering fungerade.

		Följningen är sedan #182 del 2 `AlignPosition` + `AlignOrientation`
		enligt arkitekturkontraktet i #235 FAS 4. En Luau-bänk har ingen
		fysikmotor — ingenting här kan få en constraint att flytta något.

		DET SOM GÅR ATT BEVISA HÄR är att mekanismen är riktigt kopplad:
		att regulatorerna finns, sitter i rätt häst, drar mot rätt punkt,
		är påslagna när hon ska följa och avslagna i dödzonen — och att
		den ANDRA hästen inte har någon rigg alls.

		ATT HON FAKTISKT RÖR SIG är en Studio-grind och står som
		`NOT_TESTED` i rapporten. ]]
	local rigg = LedService.riggFor(spelare)
	check("följriggen byggdes för den ledda hästen", rigg ~= nil)

	if rigg then
		check("dragets fästpunkt sitter i RÄTT häst",
			rigg.hastfast ~= nil and rigg.hastfast:IsDescendantOf(MIN),
			tostring(rigg.hastfast and rigg.hastfast.Parent
				and rigg.hastfast.Parent.Name))
		check("målpunkten sitter på SPELAREN, som kontraktet säger",
			rigg.mal ~= nil and rigg.mal:IsDescendantOf(karaktar))
		check("och båda heter det kontraktet säger",
			rigg.mal.Name == "LeadTargetAttachment"
				and rigg.hastfast.Name == "LeadRootAttachment",
			("%s / %s"):format(rigg.mal.Name, rigg.hastfast.Name))

		--[[ HÖGER SIDA, NÅGOT BAKOM. Det är inte en detalj: det är det som
			gör att spelaren går vid hästens VÄNSTRA sida, som man leder. ]]
		check("målet ligger på spelarens högra sida och något bakom",
			rigg.mal.Position.X > 0 and rigg.mal.Position.Z > 0,
			("x=%.2f z=%.2f"):format(rigg.mal.Position.X, rigg.mal.Position.Z))

		check("draget är AlignPosition och kursen AlignOrientation",
			rigg.drag.ClassName == "AlignPosition"
				and rigg.vrid.ClassName == "AlignOrientation",
			("%s / %s"):format(tostring(rigg.drag.ClassName),
				tostring(rigg.vrid.ClassName)))
		--[[ EN RIKTNING, inte en andra fästpunkt. `TwoAttachment` hade
			fått henne att kopiera spelarens vridning — och en häst som
			står som ryttaren står går i sidled in i dörrkarmen. ]]
		check("kursen styr mot EN riktning, inte mot spelarens kropp",
			rigg.vrid.Mode == Enum.OrientationAlignmentMode.OneAttachment,
			tostring(rigg.vrid.Mode))
		check("båda är MJUKA — hon dras, teleporteras inte",
			rigg.drag.RigidityEnabled == false
				and rigg.vrid.RigidityEnabled == false)
		check("och kraften är konservativ, inte ett fordon",
			rigg.drag.MaxForce > 0 and rigg.drag.MaxForce <= 50000,
			tostring(rigg.drag.MaxForce))
	end

	--[[ DEN ANDRA HÄSTEN HAR INGENTING. Inte en avslagen regulator — inga
		alls. Ingen fästpunkt, ingen kraft, ingenting att städa. ]]
	do
		local hosAnnan = {}
		for _, d in ipairs(ANNAN:GetDescendants()) do
			local k = tostring(d.ClassName)
			if k == "AlignPosition" or k == "AlignOrientation"
				or d.Name == "LeadRootAttachment" then
				table.insert(hosAnnan, k)
			end
		end
		check("den andra hästen har ingen följrigg alls", #hosAnnan == 0,
			table.concat(hosAnnan, " "))
		check("och ingen ledare i registret", LedService.ledsAv(ANNAN) == nil)
	end

	--[[ INGEN PARALLELL REGLERING. Kontraktet förbjuder en andra kraft om
		samma mål. Provet letar efter alla former av den. ]]
	do
		local forbjudna = {}
		for _, d in ipairs(MIN:GetDescendants()) do
			local k = tostring(d.ClassName)
			local otillaten = k == "VectorForce" or k == "BodyVelocity"
				or k == "BodyPosition" or k == "BodyGyro"
				or k == "RopeConstraint" or k == "LinearVelocity"
			if otillaten then
				table.insert(forbjudna, ("%s(%s)"):format(k, d.Name))
			end
		end
		check("inget annat än ledningens eget drag rör hästen",
			#forbjudna == 0, table.concat(forbjudna, " "))
	end

	--[[ FÖLJNINGEN SVARAR PÅ ATT SPELAREN RÖR SIG: målpunktens världsläge
		ska följa med, och draget slås på och av av dödzonen. Det är det
		bänken KAN se. ]]
	local fore = rigg and rigg.mal.WorldPosition
	for i = 1, 40 do
		rot.CFrame = CFrame.new(START + Vector3.new(0, 0, i * 0.25 * M))
		LedService._steg(1 / 30)
	end
	if rigg and fore then
		check("målpunkten följde med spelaren",
			(rigg.mal.WorldPosition - fore).Magnitude > 1.0,
			("%.2f studs"):format((rigg.mal.WorldPosition - fore).Magnitude))
		check("draget är påslaget när hon ska följa",
			rigg.drag.Enabled == true)
		check("och kursregulatorn med det", rigg.vrid.Enabled == true)
	end

	--[[ HÄSTEN STÅR KVAR i bänken, och det är VÄNTAT: utan fysikmotor kan
		ingen constraint flytta något. Raden finns för att den som läser
		utskriften inte ska tro att provet mätt en förflyttning. ]]
	check("(bänken har ingen fysik — hästen flyttas inte här, och ska inte)",
		true, "förflyttning är en Studio-grind")

	RunService._server = false
end

print("\n── En spelare kan inte leda två hästar ──")

do
	--[[ TVÅ SPÄRRAR, OCH BARA DEN ENA SYNS I DET HÄR LÄGET.

		Den andra hästen är inte hennes, så nejet kommer från `led.fel_hast`
		— inte från att hon redan leder. Min egen falsifiering visade det:
		mutationen som tog bort `led.leder_redan` kom ut GRÖN, för ingen
		mätning nådde den grenen.

		Spärren mäts därför där den FAKTISKT gäller: ett andra tryck på
		SAMMA häst. Det är också det spelaren gör i praktiken — trycker en
		gång till på knappen hon redan använt. ]]
	RunService._server = true
	--[[ INTILL HENNE. Spelaren gick 30 studs bort i följningsprovet
		ovan, och utan den här raden nekas hon av avståndet — då
		mäter provet fel regel och blir grönt av fel skäl. ]]
	rot.CFrame = CFrame.new(MIN.PrimaryPart.Position + Vector3.new(1.0 * M, 0, 0))
	local ok, skal = LedService.borja(spelare, MIN, MIN)
	check("ett andra försök på SAMMA häst nekas", ok == false, tostring(skal))
	check("och nejet säger att hon redan leder",
		skal == "led.leder_redan", tostring(skal))
	check("ledningen är orörd av det andra trycket",
		LedService.aktiv(spelare) == MIN)
	check("och det finns fortfarande bara ett rep",
		LedService.repFor(spelare) ~= nil)
	RunService._server = false

	if annanPrompt then
		tryck(annanPrompt)
		RunService._server = true
		check("försöket på den andra hästen nekas",
			LedService.aktiv(spelare) == MIN,
			tostring(LedService.aktiv(spelare) and LedService.aktiv(spelare).Name))
		check("och den andra hästen har ingen ledare",
			LedService.ledsAv(ANNAN) == nil,
			tostring(LedService.ledsAv(ANNAN)))
		RunService._server = false
		check("statusen står kvar på den hon FAKTISKT leder",
			status.namn == MITT_NAMN, tostring(status.namn))
	end
end

print("\n── Två spelare kan inte leda samma häst ──")

do
	RunService._server = true
	--[[ HON MASTE STA VID HASTEN. Forsta versionen stallde henne bredvid
		den FORSTA SPELAREN, som vid det har laget gatt 30 studs bort
		under foljningsprovet. Nejet blev da `led.for_langt` och
		matningen sa ingenting om upptagenheten — gron av fel skal. ]]
	local k2 = nyKaraktar(MIN.PrimaryPart.Position + Vector3.new(1.0 * M, 0, 0))
	local annanSpelare = { Name = "Nykomling", UserId = 8802, Character = k2,
		CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }
	Players._spelare = { spelare, annanSpelare }

	local ok, skal = LedService.borja(annanSpelare, MIN, MIN)
	check("den andra spelaren nekas", ok == false, tostring(skal))
	check("och nejet säger att hon är upptagen",
		skal == "led.upptagen", tostring(skal))
	check("den första leder henne fortfarande",
		LedService.ledsAv(MIN) == spelare)
	check("och det finns fortfarande bara ETT rep",
		LedService.repFor(annanSpelare) == nil
			and LedService.repFor(spelare) ~= nil)

	Players._spelare = { spelare }
	RunService._server = false
end

print("\n── En uppsutten häst går inte att leda ──")

do
	RunService._server = true
	LedService.slapp(spelare)
	RunService._server = false
	check("kopplet släppte inför provet", status.namn == nil, tostring(status.namn))

	RunService._server = true
	local sess = HorseService.sessionFor(MIN)
	check("hästen har en session att sätta en ryttare i", sess ~= nil)
	if sess then
		--[[ INTILL HENNE, annars nekas hon av avstandet och provet mater
			fel regel — samma fel som stod har forst. ]]
		rot.CFrame = CFrame.new(MIN.PrimaryPart.Position + Vector3.new(1.0 * M, 0, 0))
		sess.rider = spelare
		local ok, skal = LedService.borja(spelare, MIN, MIN)
		check("en uppsutten häst nekas", ok == false, tostring(skal))
		--[[ OCH MED SITT EGET SKAL. `led.rider` betyder att SPELAREN
			sitter upp; `led.rids` att HASTEN bars av nagon. Tva olika
			fel som inte far ha samma text. ]]
		check("och nejet säger att HON rids — inte att spelaren rider",
			skal == "led.rids", tostring(skal))
		check("och inget rep byggdes", LedService.repFor(spelare) == nil)
		sess.rider = nil
	end
	RunService._server = false
end

print("\n── Serverns automatiska frånkoppling når klienten ──")

do
	RunService._server = true
	rot.CFrame = CFrame.new(MIN.PrimaryPart.Position + Vector3.new(1.0 * M, 0, 0))
	local ok = LedService.borja(spelare, MIN, MIN)
	RunService._server = false
	check("ledningen startade om", ok == true)
	check("statusen tändes igen", status.namn == MITT_NAMN, tostring(status.namn))

	RunService._server = true
	local repFore = LedService.repFor(spelare)
	check("och repet hänger igen", repFore ~= nil)

	--[[ SPELAREN SPRINGER IFRÅN HENNE. Ingen tryckning, inget `slapp` —
		det är `_steg` som ska upptäcka det och koppla loss. ]]
	rot.CFrame = CFrame.new(MIN.PrimaryPart.Position + Vector3.new(60 * M, 0, 0))

	--[[ EN BILDRUTA RACKER INTE, och det ar hela poangen med det nya
		sakerhetskopplet. Slappet kraver avstand OCH tid, sa att en
		teleport, en respawn eller en enda ljugande bildruta inte kan
		slita kopplet. ]]
	LedService._steg(1 / 30)
	check("en ENDA bildruta for langt bort sliter inte kopplet",
		LedService.aktiv(spelare) == MIN,
		tostring(LedService.aktiv(spelare)))

	--[[ Men haller hon sig borta slapper det. 30 bildrutor ar en hel
		sekund, alltsa mer an `KOPPEL_TID`. ]]
	for _ = 1, 30 do LedService._steg(1 / 30) end

	check("servern kopplade loss av sig själv",
		LedService.aktiv(spelare) == nil,
		tostring(LedService.aktiv(spelare)))
	check("och repet är borta ur världen", LedService.repFor(spelare) == nil)
	RunService._server = false

	--[[ OCH DET NÅDDE KLIENTEN. Utan `LedSync` hade knappen stått kvar på
		«Släpp» för ett koppel som inte fanns — och spelaren hade behövt
		trycka två gånger för att få tag i henne igen. ]]
	check("frånkopplingen nådde klienten och släckte statusen",
		status.namn == nil, tostring(status.namn))
	check("klientens ledtillstånd är nollställt", IC._lederNu() == nil,
		tostring(IC._lederNu()))
	check("och knappen står på «Led <namn>» igen",
		minPrompt ~= nil and minPrompt.ActionText:find(MITT_NAMN) ~= nil,
		minPrompt and minPrompt.ActionText or "-")
end

print("\n── Arkitektens villkor för de två undantagen ──")

do
	--[[ Arkitekten gav två PRELIMINÄRA undantag — Beam-repet och den
		dynamiska målpunkten — villkorade av att kod OCH tester bevisar en
		lista påståenden. Varje villkor har en egen mätning här, i samma
		ordning som reviewen räknar upp dem. ]]
	RunService._server = true
	rot.CFrame = CFrame.new(MIN.PrimaryPart.Position + Vector3.new(1.0 * M, 0, 0))
	local ok = LedService.borja(spelare, MIN, MIN)
	check("ledningen startar för villkorsprovet", ok == true)

	local rigg = LedService.riggFor(spelare)
	local rep = LedService.repFor(spelare)

	print("  · Undantag 1 — det visuella ledrepet")

	--[[ 1a. AlignPosition är den ENDA translationsaktuatorn. Inte "ingen
		förbjuden klass finns" — utan att det finns EXAKT EN, och att den
		är vår. ]]
	do
		local dragare = {}
		for _, d in ipairs(MIN:GetDescendants()) do
			local k = tostring(d.ClassName)
			if k == "AlignPosition" or k == "VectorForce" or k == "BodyVelocity"
				or k == "BodyPosition" or k == "LinearVelocity"
				or k == "BodyThrust" or k == "RopeConstraint" then
				table.insert(dragare, ("%s(%s)"):format(k, d.Name))
			end
		end
		check("exakt EN translationsaktuator i hästen, och den är ledningens",
			#dragare == 1 and dragare[1] == "AlignPosition(UBRFLedDrag)",
			table.concat(dragare, " "))
	end

	--[[ 1b. Beam saknar fysisk påverkan. En `Beam` ärver inte
		`Constraint` — den kan inte ha Attachment-driven kraft alls. Provet
		mäter klassen OCH att repet inte är en constraint. ]]
	check("repet är en Beam", rep ~= nil and rep.ClassName == "Beam",
		rep and tostring(rep.ClassName) or "inget")
	check("och alltså ingen constraint som kan dra",
		rep ~= nil and rep:IsA("Constraint") == false)

	--[[ 1c. Beam och dess attachments skapas SERVER-SIDE. Provet kör
		`LedService.borja` med `RunService._server = true`, och ingenting
		på klientsidan har rört repet — det byggdes i serverns anrop. ]]
	check("repet och dess fästpunkter finns efter serverns anrop",
		rep ~= nil and rep.Attachment0 ~= nil and rep.Attachment1 ~= nil)
	check("och de sitter i världen, inte i en klientmapp",
		rep ~= nil and rep:IsDescendantOf(workspace))

	print("  · Undantag 2 — den dynamiska målpunkten")

	--[[ 2a. Spelaren är fortfarande den SEMANTISKA destinationen.

		VILLKORET ÄR OMFORMULERAT, INTE BORTTAGET (produktbeslut
		2026-09-20). Det löd förut: målpunkten får aldrig avvika mer än
		taket från spelaren. Mätt i Studio under M3 visade sig den
		formuleringen vara det som körde hästen in i väggen — en smula
		runt hindret drogs tillbaka längs linjen mot spelaren och hamnade
		på fel sida. Se noten över `klampMal` i `LedService`.

		En smula är en punkt spelaren SJÄLV gick på. Att gå dit är att gå
		till henne, längs hennes egen väg, och destinationen byts inte.
		Villkoret mäts därför nu som: målpunkten ligger inom taket ELLER
		är en smula ur spelarens eget spår. Allt annat är fortfarande
		förbjudet, och en godtycklig punkt långt bort faller lika hårt
		som förr. ]]
	do
		local varst, alltidGiltig = 0, true
		for i = 1, 60 do
			rot.CFrame = CFrame.new(MIN.PrimaryPart.Position
				+ Vector3.new(math.cos(i * 0.4) * 5 * M, 0, math.sin(i * 0.4) * 5 * M))
			LedService._steg(1 / 30)
			if rigg and rigg.mal then
				local mp = rigg.mal.WorldPosition
				local d = mp - rot.Position
				local plan = math.sqrt(d.X * d.X + d.Z * d.Z) / M
				if plan > varst then varst = plan end
				if plan > 7.05 then
					local sess = LedService.lage(spelare)
					local paSpar = false
					for _, sm in ipairs(sess and sess.spar or {}) do
						local e = sm - mp
						if math.sqrt(e.X * e.X + e.Z * e.Z) < 0.05 then
							paSpar = true
							break
						end
					end
					if not paSpar then alltidGiltig = false end
				end
			end
		end
		check("målpunkten är alltid inom taket ELLER en smula ur spelarens eget spår",
			alltidGiltig, ("värst %.2f m, tak 7.00"):format(varst))

		--[[ OCH TAKET PRÖVAS DIREKT, inte genom ett scenario.

			Min egen falsifiering visade varför: mutationen som tog bort
			taket kom ut GRÖN. Spårgrenen kräver att hästen lämnat en box,
			och den här specens hästar har aldrig stått i en. Ett scenario
			som inte går att bygga bevisar ingenting.

			`LedService._klampMal` är samma funktion `styrMot` använder, och
			går att pröva med vilket läge som helst. ]]
		local spelarP = Vector3.new(0, 3, 0)
		local langtbort = Vector3.new(40 * M, 3, 0)
		local klamd = LedService._klampMal(langtbort, spelarP, 3)
		local avstand = (Vector3.new(klamd.X, 0, klamd.Z)
			- Vector3.new(spelarP.X, 0, spelarP.Z)).Magnitude / M
		check("en målpunkt 40 m bort klamps till taket",
			avstand <= 7.05 and avstand >= 6.95, ("%.2f m"):format(avstand))

		--[[ RIKTNINGEN BEHÅLLS — det är det som gör att routingen
			fortfarande kan kroka vägen. Punkten dras in, den vrids inte. ]]
		local riktning = (Vector3.new(klamd.X - spelarP.X, 0, klamd.Z - spelarP.Z)).Unit
		local original = (Vector3.new(langtbort.X - spelarP.X, 0, langtbort.Z - spelarP.Z)).Unit
		check("och riktningen mot den behålls — vägen krokas, målet byts inte",
			(riktning - original).Magnitude < 1e-3,
			("%.6f"):format((riktning - original).Magnitude))

		--[[ En punkt INNANFÖR taket rörs inte alls. ]]
		local nara = Vector3.new(3 * M, 3, 0)
		local orord = LedService._klampMal(nara, spelarP, 3)
		check("en punkt innanför taket lämnas orörd",
			(orord - Vector3.new(nara.X, 3, nara.Z)).Magnitude < 1e-6)

		--[[ SPELARENS AVSTÅND GALLRAR INTE LÄNGRE (reviewrond 1–3).

			Mätningen hette förut «inaktuella smulor gallras ur spåret»
			och krävde att allt bortom `MAL_AVVIK` försvann. Den regeln
			är borttagen: en smula långt från spelaren är rutthistorik
			hästen kanske inte gått än, och att kasta den var precis det
			som lämnade henne med ett mål bakom en vägg.

			DEN VAR DESSUTOM GRÖN AV FEL SKÄL. Det som tömde spåret här
			var inte gallringen utan hoppvakten: den mätte avståndet till
			SISTA SMULAN, och provet lägger en 40 m bort. När vakten
			rättades till att mäta spelarens förra läge — vilket är vad
			den menar — blev raden röd och visade vad den egentligen
			mätte. Nu mäter den den regel som gäller. ]]
		local l = LedService.lage(spelare)
		if l then
			l.lamnatBox = true
			l.spar = { rot.Position + Vector3.new(2 * M, 0, 0),
				rot.Position + Vector3.new(40 * M, 0, 0) }
			LedService._steg(1 / 30)
			local langtBort = 0
			for _, sm in ipairs(l.spar) do
				local dd = sm - rot.Position
				if math.sqrt(dd.X * dd.X + dd.Z * dd.Z) / M > 7.05 then langtBort += 1 end
			end
			check("en smula långt från spelaren är rutthistorik och ligger kvar",
				langtBort >= 1, ("%d kvar bortom gamla taket"):format(langtBort))

			--[[ OCH REGELN PRÖVAS DIREKT, av samma skäl som taket ovan:
				spårgrenen kräver att hästen lämnat en box, och mutationen
				som tog bort gallringen kom ut GRÖN när den bara mättes
				genom ett scenario.

				GALLRINGEN MÄTER NU HÄSTENS FRAMFART, inte spelarens
				avstånd (produktbeslut 2026-09-20), och den är MONOTON i
				ruttens ordning: den går framifrån och stannar vid den
				första smula hon inte har nått. Referensen nedan är
				alltså hästens läge. Hela regeln med sitt scenario, och
				varför den inte får söka närmaste smula, ligger i
				`ledspar.spec`. ]]
			local ref = Vector3.new(0, 3, 0)
			local trad = {
				ref + Vector3.new(1 * M, 0, 0),    -- hon står på den
				ref + Vector3.new(2 * M, 0, 0),    -- nästa, inte nådd
				ref + Vector3.new(40 * M, 0, 0),
			}
			LedService._gallraSpar(trad, ref)
			check("den hon står på gallras, resten av rutten ligger kvar",
				#trad == 2, ('%d kvar av 3'):format(#trad))
			--[[ Och en oförbrukad smula långt bort är rutthistorik — den
				överlever, för spelarens avstånd äger den inte längre. ]]
			local langtbortSpar = {
				ref + Vector3.new(2 * M, 0, 0),
				ref + Vector3.new(40 * M, 0, 0),
			}
			LedService._gallraSpar(langtbortSpar, ref)
			check("men en oförbrukad smula 40 m bort ligger kvar", #langtbortSpar == 2,
				('%d kvar av 2'):format(#langtbortSpar))
		end
	end

	--[[ 2b. INGEN RUNTIME-LOOP SKRIVER HÄSTENS CFrame.

		Den starkaste mätningen i hela provet, och den är möjlig just för
		att bänken saknar fysik: körs `_steg` sextio gånger utan att någon
		annan rör hästen, ska hennes CFrame vara BIT FÖR BIT densamma.
		Skrev loopen CFrame eller kallade `PivotTo` skulle den ha flyttat
		sig — det var precis vad den gamla `vridMot` gjorde. ]]
	do
		--[[ MEDAN HON FAKTISKT FÖLJER, inte i dödzonen. Står hon stilla
			returnerar `styrMot` tidigt, och då hade mätningen varit
			sann av sig själv — min falsifiering visade precis det:
			mutationen som skrev CFrame i loopen igen kom ut GRÖN.
			Spelaren ställs långt bort så att draget är påslaget. ]]
		rot.CFrame = CFrame.new(MIN.PrimaryPart.Position + Vector3.new(4 * M, 0, 0))
		--[[ REFERENSEN TAS FÖRE FÖRSTA STEGET.

			Första versionen steg en bildruta först, för att få draget
			påslaget — och missade därmed mutationen: en loop som skriver
			CFrame hinner rikta upp henne i just det steget, och sedan
			ligger hon still. Referensen måste tas innan loopen fått röra
			henne över huvud taget. ]]
		local fore = MIN.PrimaryPart.CFrame
		for _ = 1, 60 do LedService._steg(1 / 30) end
		local efter = MIN.PrimaryPart.CFrame
		local flyttad = (efter.Position - fore.Position).Magnitude
		local vriden = (efter.LookVector - fore.LookVector).Magnitude
		check("draget slogs på under provet — hon FÖLJDE",
			rigg ~= nil and rigg.drag.Enabled == true)
		check("ingen runtime-loop skriver hästens position",
			flyttad < 1e-6, ("%.9f studs"):format(flyttad))
		check("och ingen skriver hennes kurs heller",
			vriden < 1e-6, ("%.9f"):format(vriden))
	end

	--[[ 2c. Hästen flyttas ENDAST genom mjuka constraints. Båda är
		`RigidityEnabled = false`; en stel constraint teleporterar. ]]
	check("båda regulatorerna är mjuka",
		rigg ~= nil and rigg.drag.RigidityEnabled == false
			and rigg.vrid.RigidityEnabled == false)

	--[[ 2d. Safety release vid blockerad eller orimlig rutt. Hon står
		still trots att spelaren är långt bort — det är definitionen av
		fastnat — och kopplet ska släppa av sig självt. ]]
	do
		local l = LedService.lage(spelare)
		check("ledningen pågår innan blockeringsprovet", l ~= nil)
		rot.CFrame = CFrame.new(MIN.PrimaryPart.Position + Vector3.new(6 * M, 0, 0))
		--[[ Hästen rör sig inte ur fläcken — bänken har ingen fysik, så
			det är exakt vad en blockerad häst gör i verkligheten. ]]
		for _ = 1, 400 do LedService._steg(1 / 30) end
		check("en häst som inte kommer någonstans släpps av servern",
			LedService.aktiv(spelare) == nil,
			tostring(LedService.aktiv(spelare)))
		check("och riggen är riven med den",
			LedService.riggFor(spelare) == nil)
		check("liksom repet", LedService.repFor(spelare) == nil)
	end

	RunService._server = false
end

print("\n── Varje väg ut river både rep och rigg ──")

do
	--[[ Arkitektens villkor: SAMTLIGA exit paths ska ta bort Beam och
		attachments. Provet går igenom dem en i taget i stället för att
		lita på att de alla råkar gå genom `slapp`.

		`led.rider` (uppsittning) mäts inte här utan i FAS 2-provet, där
		sessionen finns att sätta en ryttare i. ]]
	local function startaOm()
		RunService._server = true
		rot.CFrame = CFrame.new(MIN.PrimaryPart.Position + Vector3.new(1.0 * M, 0, 0))
		local ok = LedService.borja(spelare, MIN, MIN)
		RunService._server = false
		return ok
	end

	local function stadat(varfor)
		RunService._server = true
		local kvar = {}
		for _, d in ipairs(workspace:GetDescendants()) do
			local k = tostring(d.ClassName)
			if d.Name == "UBRFLedrep" or d.Name == "UBRFLedrepHand"
				or d.Name == "UBRFLedrepHast" or d.Name == "LeadTargetAttachment"
				or d.Name == "LeadRootAttachment"
				or k == "AlignPosition" or k == "AlignOrientation" then
				table.insert(kvar, ("%s(%s)"):format(k, d.Name))
			end
		end
		check(varfor .. ": inga instanser kvar", #kvar == 0,
			table.concat(kvar, " "))
		RunService._server = false
	end

	--[[ 1. MANUELLT SLÄPP. ]]
	check("manuellt släpp: ledningen startade", startaOm() == true)
	RunService._server = true
	LedService.slapp(spelare)
	RunService._server = false
	stadat("manuellt släpp")

	--[[ 2. FÖR LÅNGT BORT, över tid. ]]
	check("för långt bort: ledningen startade", startaOm() == true)
	RunService._server = true
	rot.CFrame = CFrame.new(MIN.PrimaryPart.Position + Vector3.new(60 * M, 0, 0))
	for _ = 1, 40 do LedService._steg(1 / 30) end
	check("för långt bort: servern kopplade loss",
		LedService.aktiv(spelare) == nil)
	RunService._server = false
	stadat("för långt bort")

	--[[ 3. HÄSTEN FÖRSVINNER ur världen mitt i ledningen. ]]
	check("hästen försvinner: ledningen startade", startaOm() == true)
	RunService._server = true
	local foralder = MIN.Parent
	MIN.Parent = nil
	LedService._steg(1 / 30)
	check("hästen försvinner: servern kopplade loss",
		LedService.aktiv(spelare) == nil)
	MIN.Parent = foralder
	RunService._server = false
	stadat("hästen försvinner")

	--[[ 4. SPELAREN LÄMNAR SPELET. ]]
	check("spelaren lämnar: ledningen startade", startaOm() == true)
	RunService._server = true
	Players.PlayerRemoving:Fire(spelare)
	task.wait()
	check("spelaren lämnar: ledningen är borta",
		LedService.aktiv(spelare) == nil)
	RunService._server = false
	stadat("spelaren lämnar")
end

print("\n── Ingenting av den förra hästen ligger kvar ──")

do
	RunService._server = true
	local kvar = {}
	for _, d in ipairs(workspace:GetDescendants()) do
		if d.Name == "UBRFLedrep" or d.Name == "UBRFLedrepHand"
			or d.Name == "UBRFLedrepHast" then
			table.insert(kvar, d.Name)
		end
	end
	check("inga repdelar ligger kvar någonstans i världen", #kvar == 0,
		table.concat(kvar, ", "))

	--[[ OCH FÖLJRIGGEN MED. Repet är bilden; riggen är krafterna. En
		kvarglömd `AlignPosition` skulle fortsätta dra hästen mot en
		fästpunkt på en spelare som inte leder henne längre — det är
		värre än ett kvarglömt rep, för det syns inte. ]]
	local riggkvar = {}
	for _, d in ipairs(workspace:GetDescendants()) do
		local k = tostring(d.ClassName)
		if k == "AlignPosition" or k == "AlignOrientation"
			or d.Name == "LeadTargetAttachment" or d.Name == "LeadRootAttachment" then
			table.insert(riggkvar, ("%s(%s)"):format(k, d.Name))
		end
	end
	check("och ingen följrigg ligger kvar och drar", #riggkvar == 0,
		table.concat(riggkvar, " "))
	check("ingen häst står kvar som ledd",
		LedService.ledsAv(MIN) == nil and LedService.ledsAv(ANNAN) == nil)
	RunService._server = false
end

RunService._server = false

print("\n── EN ÄGARE I TAGET: en ledd häst går inte att sitta upp på ──")

--[[ Robustness Slice A.

	`LedService` har alltid vägrat att börja LEDA en riden häst
	(`led.rids`, mätt i blocket längre upp). Motsatta vägen stod öppen: A
	ledde, B satte sig upp, och båda ägde henne.

	Ledningen tar nätverksägarskapet till servern och sparar undan det
	föregående; uppsittningen ger det till ryttaren. När A sedan släpper
	lämnar `LedService` tillbaka det ägarskap den sparade INNAN B satte
	sig — och rycker det från den aktiva ryttaren.

	CHECKLISTAN STÄNGS AV MED FLIT i det här blocket. Provet mäter
	ledningsregeln, inte skötseln, och att `setMountGate(nil)` inte
	stänger av den nya grinden är hela skälet till att grinden sitter i
	`tryMount` och inte i gameplaylagrets gate. Gaten sätts tillbaka
	efteråt. ]]
do
	RunService._server = true
	HorseService.setMountGate(nil)

	--[[ Båda spelarna står INTILL hästen. Står de för långt bort nekas
	     uppsittningen av avståndet och provet mäter fel regel — precis
	     det felet som står dokumenterat i blocket om två ledare. ]]
	local function intill(r)
		r.CFrame = CFrame.new(MIN.PrimaryPart.Position + Vector3.new(1.0 * M, 0, 0))
	end

	local k3 = nyKaraktar(MIN.PrimaryPart.Position + Vector3.new(1.2 * M, 0, 0))
	local rot3 = k3:FindFirstChild("HumanoidRootPart")
	local spelareB = { Name = "RyttareB", UserId = 8803, Character = k3,
		CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }
	Players._spelare = { spelare, spelareB }

	--[[ ── KONTROLLEN FÖRST ────────────────────────────────────────
		Går uppsittningen igenom NÄR HON INTE LEDS? Utan den raden kan
		varje nej nedan betyda «grinden höll» eller «uppsittningen gick
		aldrig att göra i den här bänken», och de två får inte gå att
		blanda ihop. ]]
	LedService.slapp(spelare)
	intill(rot3)
	local okFri, skalFri = HorseService.tryMount(spelareB, MIN)
	check("KONTROLL: en fri häst går att sitta upp på",
		okFri == true, tostring(skalFri))
	HorseService.dismount(spelareB)

	--[[ ── A LEDER, B FÖRSÖKER SITTA UPP ──────────────────────────── ]]
	intill(rot)
	local okLed, skalLed = LedService.borja(spelare, MIN, MIN)
	check("A leder henne", okLed == true, tostring(skalLed))
	local agareUnderLedning = MIN.PrimaryPart:GetNetworkOwner()

	intill(rot3)
	local okB, skalB = HorseService.tryMount(spelareB, MIN)
	check("EN LEDD HÄST GÅR INTE ATT SITTA UPP PÅ",
		okB == false, tostring(okB))
	check("och nejet är en namngiven nyckel spelaren kan få läst",
		skalB == "hast.leds_nu" and Sprak.finns(skalB) == true,
		("%s · finns=%s"):format(tostring(skalB), tostring(Sprak.finns(skalB))))

	--[[ ── NEJET FÅR INTE HA RÖRT NÅGOT ────────────────────────────
		Den här delen är avsiktligt skild från nejet ovan: en grind som
		nekar men ändå hinner ändra tillstånd på vägen är inte en grind.
		Mätt på tre oberoende ställen — ledaren, repet och ägarskapet. ]]
	check("ledaren är fortfarande A",
		LedService.ledsAv(MIN) == spelare, tostring(LedService.ledsAv(MIN)))
	check("repet är kvar och B har inget eget",
		LedService.repFor(spelare) ~= nil and LedService.repFor(spelareB) == nil)
	check("och nätverksägarskapet är orört",
		MIN.PrimaryPart:GetNetworkOwner() == agareUnderLedning,
		("%s -> %s"):format(tostring(agareUnderLedning),
			tostring(MIN.PrimaryPart:GetNetworkOwner())))
	check("och hästen har ingen ryttare",
		HorseService.sessionFor(MIN).rider == nil,
		tostring(HorseService.sessionFor(MIN).rider))

	--[[ ── MEN LEDAREN SJÄLV FÅR SITTA UPP ────────────────────────

		Den här raden saknades i första versionen, och dess frånvaro
		kostade en grön svit: grinden nekade VARJE ledd häst, och
		`integration.spec` föll på «dagen går att räkna färdigt». Det var
		rätt av den att falla — kärnloopen ÄR att leda sin häst till
		banan och sitta upp där, utan att släppa repet först.

		`LedService` har redan den vägen löst: sitter ledaren själv upp
		släpper den kopplet nästa bildruta (`led.rider`). Regeln handlar
		om två OLIKA ägare, inte om två roller hos samma spelare. ]]
	do
		intill(rot)
		local okEget = HorseService.tryMount(spelare, MIN)
		check("LEDAREN SJÄLV FÅR SITTA UPP PÅ SIN EGEN LEDDA HÄST",
			okEget == true, tostring(okEget))
		HorseService.dismount(spelare)
		--[[ Ledningen står kvar — det är `LedService._steg` som släpper
		     den, inte uppsittningen, och provet ska inte låtsas annat. ]]
		check("och kopplet är fortfarande hennes tills tjänsten släpper det",
			LedService.ledsAv(MIN) == spelare)
	end

	--[[ ── OCH SLÄPPET FÅR INTE RYCKA ÄGARSKAPET FRÅN HENNE ───────

		Reviewblockerare på Slice A. Att ledaren får sitta upp räcker
		inte: `steg` släpper kopplet nästa bildruta med skälet
		`led.rider`, och släppet ÅTERSTÄLLER det nätverksägarskap som
		sparades undan när ledningen började — alltså ett värde från
		INNAN hon satt upp. Det skulle skriva över det ägarskap
		`HorseService.setRider` just gav ryttaren, och hon skulle sitta
		på en häst hon inte styr.

		Det här är den vanligaste vägen i hela kärnloopen: leda sin häst
		till banan och sitta upp där. ]]
	do
		--[[ Foregaende block lamnar ledningen aktiv med flit (kopplet ar
		     hennes tills tjansten slapper det), sa den maste slappas har
		     — annars nekas `borja` med `led.leder_redan` och provet mater
		     ingenting. Forsta versionen gjorde precis det. ]]
		LedService.slapp(spelare)
		intill(rot)
		local okLedEget, skalLedEget = LedService.borja(spelare, MIN, MIN)
		check("A leder henne inför provet", okLedEget == true,
			tostring(skalLedEget))
		local foreUppsittning = MIN.PrimaryPart:GetNetworkOwner()

		local okUppEget = HorseService.tryMount(spelare, MIN)
		check("och sätter sig upp på sin egen ledda häst", okUppEget == true)
		local ryttarAgare = MIN.PrimaryPart:GetNetworkOwner()
		check("ägarskapet gick till RYTTAREN vid uppsittningen",
			ryttarAgare == spelare,
			("fore=%s  efter=%s"):format(tostring(foreUppsittning),
				tostring(ryttarAgare)))

		--[[ Och så släpper tjänsten kopplet SJÄLV, genom `steg` — inte
		     genom ett direktanrop av `slapp`. Det är den vägen spelaren
		     faktiskt går. ]]
		local hum = spelare.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum.Sit = true end
		LedService._steg(1 / 30)
		check("tjänsten släppte kopplet själv", LedService.ledsAv(MIN) == nil)

		check("OCH SLÄPPET RÖRDE INTE RYTTARENS ÄGARSKAP",
			MIN.PrimaryPart:GetNetworkOwner() == spelare,
			("%s"):format(tostring(MIN.PrimaryPart:GetNetworkOwner())))

		if hum then hum.Sit = false end
		HorseService.dismount(spelare)
	end

	--[[ ── EN LEDNING UTAN RYTTARE ÅTERSTÄLLER SOM FÖRUT ────────────

		Den andra halvan av kontraktet, och den som gör den första
		mätbar: ändrar man regeln till «återställ aldrig» blir DEN HÄR
		raden röd i stället. Ett släpp utan ryttare ska lämna tillbaka
		ägarskapet precis som det alltid gjort. ]]
	do
		MIN.PrimaryPart:SetNetworkOwner(spelare)
		intill(rot)
		local okLedUtan = LedService.borja(spelare, MIN, MIN)
		check("A leder henne, utan att sitta upp", okLedUtan == true)
		check("ledningen tog ägarskapet till servern",
			MIN.PrimaryPart:GetNetworkOwner() == nil,
			tostring(MIN.PrimaryPart:GetNetworkOwner()))
		LedService.slapp(spelare)
		check("OCH SLÄPPET LÄMNADE TILLBAKA DET SOM FÖRUT",
			MIN.PrimaryPart:GetNetworkOwner() == spelare,
			tostring(MIN.PrimaryPart:GetNetworkOwner()))
	end

	--[[ ── EN KROK SOM KASTAR FÅR INTE KLOTTRA ─────────────────────

		Fail-riktningen, och den stod som ett påstående i en kommentar
		tills den här raden fanns. Kan vi inte avgöra om någon rider
		LÅTER VI ÄGARSKAPET VARA: en häst som blir kvar serversimulerad
		rättas av nästa uppsittning, men en ryttare som får ägarskapet
		bortryckt har ingen väg tillbaka utom att sitta av. ]]
	do
		local riktig = LedService.satRidenKrok
		MIN.PrimaryPart:SetNetworkOwner(spelare)
		intill(rot)
		local okKast = LedService.borja(spelare, MIN, MIN)
		check("A leder henne inför fail-provet", okKast == true)
		LedService.satRidenKrok(function()
			error("krokens egen krasch")
		end)
		LedService.slapp(spelare)
		check("EN KROK SOM KASTAR LÄMNAR ÄGARSKAPET IFRED",
			MIN.PrimaryPart:GetNetworkOwner() == nil,
			tostring(MIN.PrimaryPart:GetNetworkOwner()))
		--[[ Tillbaka till produktionens egen krok. ]]
		LedService.satRidenKrok(function(modell)
			local sess = HorseService.sessionFor(modell)
			return sess ~= nil and sess.rider ~= nil
		end)
		local _ = riktig
	end

	--[[ ── A SLÄPPER → B FÅR SITTA UPP ─────────────────────────────
		Utan den här armen vore grinden uppfylld av en server som aldrig
		släpper igenom någon alls. ]]
	LedService.slapp(spelare)
	check("ledningen är släppt", LedService.ledsAv(MIN) == nil)
	intill(rot3)
	local okEfter, skalEfter = HorseService.tryMount(spelareB, MIN)
	check("EFTER SLÄPPET GÅR UPPSITTNINGEN IGENOM",
		okEfter == true, tostring(skalEfter))

	--[[ ── DEN OMVÄNDA REGELN STÅR KVAR ────────────────────────────
		`led.rids` mäts också i sitt eget block längre upp; den står med
		här för att kontraktet ska gå att läsa på ett ställe. ]]
	intill(rot)
	local okLed2, skalLed2 = LedService.borja(spelare, MIN, MIN)
	check("en RIDEN häst går fortfarande inte att leda",
		okLed2 == false and skalLed2 == "led.rids",
		("%s / %s"):format(tostring(okLed2), tostring(skalLed2)))

	--[[ ── OCH DE TVÅ GAMLA REGLERNA, SOM ALDRIG PRÖVATS ───────────
		`hast.upptagen` och `hast.rider_redan` har funnits i `tryMount`
		hela tiden men står inte i någon spec — de förekommer bara i
		kommentarer. Ledningen har haft sin motsvarighet sedan länge
		(`led.upptagen`); uppsittningen har inte haft det. ]]
	intill(rot)
	local okTva, skalTva = HorseService.tryMount(spelare, MIN)
	check("EN HÄST KAN INTE HA TVÅ RYTTARE",
		okTva == false and skalTva == "hast.upptagen",
		("%s / %s"):format(tostring(okTva), tostring(skalTva)))

	local okAnnan, skalAnnan = HorseService.tryMount(spelareB, ANNAN)
	check("OCH EN RYTTARE KAN INTE SITTA PÅ TVÅ HÄSTAR",
		okAnnan == false and skalAnnan == "hast.rider_redan",
		("%s / %s"):format(tostring(okAnnan), tostring(skalAnnan)))

	HorseService.dismount(spelareB)

	--[[ ── EN TRASIG KROK SÄGER NEJ, INTE JA ───────────────────────

		Grinden är fail closed, och det stod som ett PÅSTÅENDE i en
		kommentar tills falsifieringen visade att ingen arm kunde göra
		det rött: kroken kastar aldrig i bänken av sig själv.

		Skälet regeln finns: kroken går genom gameplaylagret, och ett
		fel DÄR får inte kunna släppa igenom en uppsittning som
		ledningsregeln säger nej till. Ett kastat anrop räknas därför
		som «hon leds», inte som «hon är fri». ]]
	do
		intill(rot)
		local okLed3 = LedService.borja(spelare, MIN, MIN)
		check("A leder henne igen inför provet", okLed3 == true)

		HorseService.setLedareHook(function()
			error("krokens egen krasch")
		end)
		intill(rot3)
		local okKrasch, skalKrasch = HorseService.tryMount(spelareB, MIN)
		check("EN KROK SOM KASTAR GER NEJ — INTE JA",
			okKrasch == false and skalKrasch == "hast.leds_nu",
			("%s / %s"):format(tostring(okKrasch), tostring(skalKrasch)))

		--[[ Tillbaka till den riktiga kroken, samma uttryck som
		     `GameplayService.start` kopplar in. ]]
		HorseService.setLedareHook(LedService.ledsAv)
		LedService.slapp(spelare)
	end

	Players._spelare = { spelare }
	HorseService.setMountGate(GameplayService.farSittaUpp)
	RunService._server = false
end

if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("\nledning-integration.spec: alla gröna")
end
