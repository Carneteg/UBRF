--!strict
--[[
	Uppsittningen.

	En ProximityPrompt per häst, skapad på klienten så att servern slipper
	replikera dem. Prompten frågar servern om lov — klienten bestämmer
	aldrig själv att den sitter upp.
]]

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Core = require(game:GetService("ReplicatedStorage").HorseCore)
local Net, RigAdapter = Core.Networking, Core.RigAdapter

--[[ #162: prompttexten kommer ur språkkanonen. ]]
local Sprak = require(game:GetService("ReplicatedStorage").HorseCore.Sprak)

local InteractionController = {}

local prompts: { [Model]: ProximityPrompt } = {}
--[[ Ledningens egen knapp och dess läge. Läget speglar serverns svar
     och sätts aldrig av en gissning. ]]
local ledKnappar: { [Model]: ProximityPrompt } = {}
local ledPrompts: { [Model]: boolean } = {}
--[[ RIDE FIRST: "Rida nu". Egen knapp, samma mönster som de två ovan. ]]
local ridaKnappar: { [Model]: ProximityPrompt } = {}
local ridaCheck: ((Model) -> boolean)? = nil
--[[ #235 FAS 2: «Sadla». Samma mönster igen — en tabell för knapparna och
	en fråga utåt om den får ritas. ]]
local sadlaKnappar: { [Model]: ProximityPrompt } = {}
local sadlaCheck: ((Model) -> boolean)? = nil
--[[ #235 FAS 3: transets knapp. Egen tabell, samma monster. ]]
local transaKnappar: { [Model]: ProximityPrompt } = {}
local transaCheck: ((Model) -> boolean)? = nil
--[[ Andra argumentet ar rittmarket ur uppsittningshandskakningen
     (#233, ChatGPT-review av #241). ]]
local onMount: ((Model, string?) -> ())? = nil

--[[ ══ TRE KNAPPAR PÅ SAMMA HÄST FÅR INTE LIGGA PÅ VARANDRA (#182) ═════

	`MountPrompt` sitter på sadelpunkten, `LedPrompt` och `RidaNuPrompt` på
	riggens rot. De tre punkterna ligger inom någon decimeter från varandra
	på en häst, alltså ritas prompterna i praktiken PÅ SAMMA STÄLLE på
	skärmen. Spelaren läste den översta och visste inte att det fanns fler.

	Vilka kombinationer som faktiskt kan stå uppe samtidigt, läst ur
	villkoren i den här filen och ur `init.client.luau`:

	  redo                    -> MountPrompt + LedPrompt
	  `leda` är spelarens tur -> LedPrompt   + RidaNuPrompt
	  legacy (`G01Enabled`
	    uttryckligen false)   -> alla tre

	Rättelsen är INTE att gömma någon av dem — varje knapp är en riktig
	handling — utan att lägga dem i en kolumn med en fast ordning.

	ORDNINGEN ÄR PRODUKTORDNING, inte alfabetisk: FUN FIRST / RIDE FIRST
	säger att spelaren kommer för att rida. "Sitt upp" ligger därför överst
	när den finns, "Rida nu" är genvägen dit, och "Led" — den frivilliga
	omsorgen — ligger underst. Ingen av dem är dold, och ingen av dem
	kräver att spelaren gissar.

	STEGET ÄR MÄTT MOT ETT KRAV, inte valt fritt: `docs/KONTROLLMATRIS.md`
	regel 5 säger minst 44 px träffyta på varje knapp spelaren måste kunna
	nå, och en ProximityPrompt ÄR tryckbar på pekskärm
	(`ClickablePrompt`). Två prompter närmare varandra än 44 px går alltså
	inte att träffa var för sig med ett finger. 64 px ger marginal för
	promptens egen höjd.

	Att den exakta pixelhöjden i Studio SER bra ut är en mänsklig grind —
	bänken kan mäta avståndet och ordningen, inte hur det ser ut. ]]
InteractionController.PROMPT_STEG = 64

--[[ Ett nej, en kvittens, och den beständiga statusraden. Den här filen
	äger knapparna; panelen äger meddelanderaden och `DinHast` äger
	statusraden. Kopplingen görs i `init.client.luau` — samma mönster som
	`setAvslagVisare` redan hade. ]]
local bekraftelseVisare: ((any, any?) -> ())? = nil
local ledStatus: ((Model?) -> ())? = nil
--[[ VILKEN HÄST KLIENTEN TROR ATT HON LEDER. Ett enda fält, och varje
	övergång går genom `satLeder`. Det är det som gör "leder inte → leder
	→ leder inte" till en mätbar kedja i stället för tre oberoende
	knapptexter som råkade stämma. ]]
local lederNu: Model? = nil

--[[ Hastens egennamn. Ett stalle, sa att de tre knapparna aldrig kan
	kalla samma hast olika saker. Oversatts aldrig. ]]
local function hastnamn(model: Model): string
	return tostring(model:GetAttribute("HorseName") or model.Name)
end

--[[ Var i kolumnen en knapp hamnar. Produktordning, inte alfabetisk:
	uppsittningen overst, genvagen dit i mitten, den frivilliga omsorgen
	underst. Se noten vid `PROMPT_STEG`. ]]
local PROMPT_RAD = { MountPrompt = -1, RidaNuPrompt = 0, LedPrompt = 1,
	SadlaPrompt = 2, TransaPrompt = 2 }

--[[ ── SAMMA ORDNING GÄLLER ÖVERALLT (#246 QA-blockerare) ─────────────

	Tabellen ovan är produktordningen för prompternas kolumn i världen.
	Närområdeslistan på touch visar SAMMA handlingar, och den sorterade
	dem på avstånd — vilket lade "Rida nu" fjärde, efter sadel, träns och
	ledning.

	Mätt i Studio 2026-09-18 på `8a3c435`, spelaren 4 studs från Trixie,
	sju prompter inom räckvidd:

	    kapacitet 5   bridle · saddle · Lead · Ride now · Open
	    kapacitet 3   bridle · saddle · Lead
	    kapacitet 2   bridle · saddle
	    kapacitet 1   bridle

	På en telefon ryms två eller tre rader. "Rida nu" fanns alltså inte i
	listan — och dess nativebild var släckt, eftersom touch-ytan äger
	bilderna. Det gick bokstavligen inte att trycka på Ride First-vägen.

	Ordningen läses därför HÄRIFRÅN och skrivs inte av. Två moduler med
	var sin uppfattning om vad som är viktigast är precis hur det här
	felet uppstod. ]]
function InteractionController.handlingsrang(promptNamn: any): number
	local r = if type(promptNamn) == "string" then PROMPT_RAD[promptNamn] else nil
	--[[ Okända prompter — boxfronternas utrustning, dörrar, titthålet —
	     är kontextuella och hamnar efter de handlingar produktordningen
	     namnger. De försvinner inte; de trängs inte före. ]]
	return if r ~= nil then r else 3
end

--[[ ══ HANDKONTROLLEN: EN PLATS, MOT HELA KONTROLLMATRISEN ═══════════════

	Första rättelsen av #182 gav de tre prompterna var sin knapp — X, Y och
	B — och provade bara att de skilde sig från VARANDRA. De tre var alltså
	unika inbördes och kolliderade samtidigt med varsin global bindning:

	  `ButtonX`  init.client.luau  «Se ritten»
	  `ButtonY`  init.client.luau  «Lektionen vidare»
	  `ButtonB`  Input.luau        halvhalt

	Ett prov som bara jämför tre knappar med varandra kan inte se det. Hela
	`docs/KONTROLLMATRIS.md` är facit, inte de tre raderna.

	REGELN SOM GÄLLER HÄR, och som `klient-ledprompt.spec` mäter i båda
	riktningarna:

	  1. Prompterna lever BARA när spelaren INTE sitter upp. `setEnabled`
	     nedan är den grinden, och den gäller numera alla tre tabellerna —
	     inte bara uppsittningens, som var hela buggen.
	  2. Ridningens reglage lever BARA när hon SITTER UPP. `Input.bind()`
	     körs vid uppsittning och `Input.unbind()` vid avsittning, och
	     init.client.luau:s «Se ritten», «Lektionen vidare» och «Gå vidare»
	     ligger alla efter `if not ride then return end`.
	  3. Det som lever i BÅDA lägena — hjälpens `DPadUp` — får ingen prompt
	     röra. `DPadDown` (avsittning) är ride-grindad men lämnas ändå i
	     fred: styrkorsets par upp/ned är ett läst beslut ur #161/#162.

	VALET AV KNAPPAR följer av det. Lediga i hela matrisen är bara styrkors
	vänster och höger, och de går till de två knappar som är NYA på hästen:

	  `DPadRight`  «Rida nu»  — höger är vidare, ut och rid
	  `DPadLeft`   «Led …»    — vänster är att stanna kvar och sköta om

	`MountPrompt` behåller `ButtonX`. Tre skäl, i den ordningen:

	  · det är Roblox EGET standardvärde för en ProximityPrompt. Sätter vi
	    ingenting blir det ButtonX ändå — knappen går alltså inte att
	    "slippa", bara att flytta,
	  · det är den knapp en Roblox-spelare redan har i fingret för varje
	    prompt i varje annat spel, och uppsittningen är den viktigaste
	    knappen på hästen,
	  · «Se ritten» går inte att nå från marken (`not ride`-grinden) och
	    prompten går inte att nå från sadeln (regel 1) — de två kan alltså
	    aldrig vara uppe samtidigt, och provet mäter just det i stället för
	    att lita på att de inte krockar.

	Samma kontextregel bär redan TANGENTBORDET, och det är inget nytt
	påfund: `E` är både uppsittningsprompt och avsittning, och `R` är både
	«Rida nu» och «Lektionen vidare». De har fungerat hela tiden av exakt
	det skäl som regel 1 och 2 beskriver — men regel 1 var i praktiken
	bruten, så `R` i sadeln fyrade FAKTISKT «Rida nu» också. Rättelsen
	nedan stänger tangentbordets hål i samma andetag som gamepadens.

	Ändras något här ska `docs/KONTROLLMATRIS.md` ändras med det. Tabellen
	är publik för att provet och matrisen ska kunna läsa beslutet ur källan
	i stället för ur en avskrift — samma skäl som `KontrollHjalp.GAMEPADKNAPP`. ]]
InteractionController.GAMEPAD = {
	MountPrompt = Enum.KeyCode.ButtonX,
	RidaNuPrompt = Enum.KeyCode.DPadRight,
	LedPrompt = Enum.KeyCode.DPadLeft,
	--[[ #235 FAS 2. Styrkorset ar slut — vanster och hoger gick till
		de tva knappar som var nya i #182, och upp/ned ar last sedan
		#161/#162. `ButtonY` valjs pa KONTEXTREGELN, inte pa att den
		vore obunden: den ar «lektionen vidare» i `init.client.luau`,
		och den raden ligger efter `if not ride then return end`.
		«Sadla» lever bara nar spelaren star pa marken och BAR sadeln
		— alltsa nar hon inte sitter upp — sa de tva kan aldrig vara
		uppe samtidigt.

		Det ar exakt samma argument som redan bar `ButtonX` (sitt upp /
		se ritten) och tangenten `R` (rida nu / lektionen vidare). Det
		gor det inte gratis: provet fyrar knappen i BADA lagena och
		faller om nagot svarar i fel lage. Det var just den matningen
		som saknades nar ButtonX/Y/B forsta gangen valdes fel. ]]
	SadlaPrompt = Enum.KeyCode.ButtonY,
	--[[ #235 FAS 3: SAMMA plats och SAMMA knapp som sadelknappen, och
		det ar inte slarv utan kanon. Transet kommer SIST: `satPa` nekar
		det pa en osadlad hast, och sadelknappen finns bara sa lange
		hon ar osadlad. De tva kan darfor aldrig vara uppe samtidigt —
		och provet mater just det i stallet for att lita pa det.

		Vinsten ar att kolumnen stannar pa fyra rader i stallet for fem.
		Pa en telefon i landskap ar det skillnaden mellan en lista och
		en vagg. ]]
	TransaPrompt = Enum.KeyCode.ButtonY,
}

--[[ ÄR PROMPTERNA UPPE? Ett fält, inte en engångsslinga.

	`setEnabled` var förut en ren loop över de prompter som RÅKADE finnas
	när den anropades. En knapp som byggdes efteråt — och `uppdatera()`
	bygger knappar medan spelaren rider — föddes med `Enabled = true` och
	stod alltså kvar mitt i ritten. Läget måste bokföras för att kunna
	gälla också det som ännu inte finns. ]]
local promptarPa = true

--[[ Allt som är GEMENSAMT för de tre knapparna, på ett ställe: platsen i
	kolumnen, fingret, handkontrollen och om knappen alls är uppe. Låg de
	utspridda på tre skapelseställen kunde de tre glida isär — och det var
	precis så `setEnabled` kom att gälla en av tre. ]]
local function stallIn(prompt: ProximityPrompt)
	local rad = PROMPT_RAD[prompt.Name] or 0
	prompt.UIOffset = Vector2.new(0, rad * InteractionController.PROMPT_STEG)
	--[[ `ClickablePrompt` är det som gör knappen tryckbar med ett finger.
		Utan den finns ingen väg in på en ren pekenhet. ]]
	prompt.ClickablePrompt = true
	local pad = InteractionController.GAMEPAD[prompt.Name]
	if pad then prompt.GamepadKeyCode = pad end
	--[[ INGEN KNAPP FAR DOLJA EN ANNAN (#182 del 3). `OnePerButton` ar
		Roblox standard, och den visar bara den NARMASTE av flera pa
		samma knapp. Matt i den byggda varlden stod elva prompter inom
		rackhall vid en boxfront och sex delade `E` — fem av dem fanns
		utan att spelaren kunde se det. ]]
	prompt.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow
	prompt.Enabled = promptarPa
end

--[[ Vad ledknappen ska heta just nu, med hastens namn i sig. ]]
local function ledtext(model: Model, leder: boolean): string
	return Sprak.t(if leder then "led.slapp_namn" else "led.borja_namn", hastnamn(model))
end

--[[ ══ EN ENDA OVERGANG (#182) ═══════════════════════════════════════

	"leder inte -> leder -> leder inte" gick forut att harleda bara ur tre
	oberoende stallen: knappens text, `ledPrompts`-tabellen och serverns
	sync. De kunde saga olika, och human-QA sag exakt det: knappen bytte
	ord men ingenting annat pa skarmen andrades.

	Nu gar VARJE overgang genom den har funktionen, och den gor tre saker
	i samma andetag:

	  1. knapptexterna pa ALLA hastar rattas,
	  2. den bestaende statusraden tands eller slacks,
	  3. en kvittens visas — en gang, vid sjalva bytet.

	`ny` ar hasten spelaren leder nu, eller nil. Anropas bade fran
	knappens eget svar och fran serverns `LedSync`, sa att de tva aldrig
	kan glida isar. ]]
local function satLeder(ny: Model?)
	local forra = lederNu
	lederNu = ny

	for model, prompt in pairs(ledKnappar) do
		prompt.ActionText = ledtext(model, model == ny)
	end

	local status = ledStatus
	if status then status(ny) end

	if forra ~= ny then
		local visa = bekraftelseVisare
		if visa then
			if ny then
				visa(Sprak.t("led.leder", hastnamn(ny)))
			elseif forra then
				visa(Sprak.t("led.slutade", hastnamn(forra)))
			end
		end
	end
end

--[[ Provets fonster in: vilken hast tror klienten att hon leder? ]]
function InteractionController._lederNu(): Model?
	return lederNu
end

--[[ Vem som visar en KVITTENS, och vem som bar den bestaende statusraden.
	Samma monster som `setAvslagVisare`: den har filen ager knapparna,
	panelen ager meddelanderaden, `DinHast` ager statusraden. ]]
function InteractionController.setBekraftelseVisare(fn: ((any, any?) -> ())?)
	bekraftelseVisare = fn
end

function InteractionController.setLedStatus(fn: ((Model?) -> ())?)
	ledStatus = fn
end

--[[ Får uppsittningsprompten visas för den här modellen?

	Krav 8: `G01Enabled == nil` vid klientjoin får INTE ge en uppsittnings-
	prompt. Attributet replikeras, och en klient som hinner fram före servern
	läser nil — inte false.

	FÖRSTA VERSIONEN VAR FAIL-OPEN, och kommentaren påstod motsatsen.
	`g01Pa()` prövade riktigt `== true`, men svaret användes som
	`if not g01Pa() then return true` — så nil gick rakt in i legacy-grenen
	och VISADE prompten. Exakt det race kravet finns till för. Fälldes av
	senior review på #61.

	Rättningen är att sluta behandla flaggan som boolean. Den har TRE lägen:

	  nil   → göm. Vi vet ännu inte om loopen är på, och att gissa "av" är
	          att gissa åt fel håll.
	  true  → serverns ready-check avgör (`redoFor`).
	  false → legacy: hästsystemet utan G01-loopen, som före den här skivan.

	Att nil och false ger OLIKA svar är hela rättningen. ]]
local redoFor: ((Model) -> boolean)? = nil

--[[ Returnerar nil / true / false — inte en boolean. ]]
function InteractionController.g01Lage(): boolean?
	local v = ReplicatedStorage:GetAttribute("G01Enabled")
	if v == nil then return nil end
	return v == true
end

--[[ Själva beslutet, utan instanser, så att det går att fälla i en spec.
	Låg först som en lokal funktion och var då oprovbar — vilket är hur
	fail-open-buggen kunde ligga kvar bakom en kommentar som påstod rätt
	beteende. ]]
function InteractionController.promptSynlig(lage: boolean?, redo: boolean): boolean
	if lage == nil then
		return false          -- fail closed: vi vet inte än
	end
	if lage == false then
		return true           -- legacy, utan G01-loopen
	end
	return redo
end

local function farVisas(model: Model): boolean
	local redo = redoFor ~= nil and redoFor(model)
	return InteractionController.promptSynlig(InteractionController.g01Lage(), redo)
end

--[[ ══ LEDNINGEN HAR EN EGEN SYNLIGHETSREGEL ════════════════════════

	Uppsittningens prompt ska vara borta tills hästen är REDO — det är
	hela poängen med förberedelsen. Ledningen fick samma regel, och det
	låste loopen:

	    för att bocka av `leda` måste hästen fysiskt ha lämnat boxen
	      → för att hon ska gå måste kopplet fästas med `LedBorja`
	        → `LedBorja` nås bara via `LedPrompt`
	          → `LedPrompt` fanns bara när `redo` var sant
	            → `redo` är `Preparation.nasta(state) == nil`, alltså
	              sant först när `leda` REDAN är avbockad.

	Mätt i Studio, stående vid sin egen häst med allt utom `leda` klart:
	`redo=false`, noll prompter i världen. Det fanns alltså ingen väg alls
	att börja leda — inte bara en otydlig väg, och inte bara på pekskärm.

	Regeln nedan är den lilla: ledningen syns också när `leda` är det steg
	spelaren står på. Servern äger fortfarande vem som får leda vad
	(`satRattHastKrok`) och när steget får bockas av — klienten bestämmer
	bara om knappen ritas. ]]
local avslagVisare: ((any, any?) -> ())? = nil
local ledFor: ((Model) -> boolean)? = nil

function InteractionController.setLedCheck(fn: ((Model) -> boolean)?)
	ledFor = fn
end

local function farVisasLed(model: Model): boolean
	if farVisas(model) then return true end
	if InteractionController.g01Lage() ~= true then return false end
	return ledFor ~= nil and ledFor(model)
end

function InteractionController.setReadyCheck(fn: ((Model) -> boolean)?)
	redoFor = fn
end

local function addPrompt(model: Model)
	if prompts[model] then return end
	if not farVisas(model) then return end
	local rig = RigAdapter.build(model)
	if not rig then return end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "MountPrompt"
	prompt.ActionText = Sprak.t("interaktion.sitt_upp")
	prompt.ObjectText = model:GetAttribute("HorseName") or model.Name
	prompt.HoldDuration = 0.35
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	--[[ TANGENT, FINGER OCH HANDKONTROLL (#182). `E` ar Roblox standard
		och lamnas; fingret och handkontrollen satts av `stallIn`, som ager
		hela den gemensamma delen — se noten vid `GAMEPAD`. ]]
	prompt.Parent = rig.attachments.Saddle or rig.root
	stallIn(prompt)

	prompt.Triggered:Connect(function()
		--[[ TRE RETURVÄRDEN, INTE TVÅ (#204).

			`GameplayService.farSittaUpp` svarar `(false, skal, arg)`, och
			argumentet är inte kosmetik: `pass.aterstar` är formatsträngen
			"%s remains" och fyndets välfärdsstopp är en engelsk RAM runt
			en svensk mening ur skötselkanonen. Handlaren tog bara två
			värden, så det tredje föll på golvet.

			Mätt i Studio på `c30f1ff`, före rättelsen:

			    server -> ok=false skal=pass.aterstar arg=kanon:Hälsa lugnt
			    skalText(skal, nil) = "%s remains"    <- ofylld

			Hade nejet bara routats vidare utan argumentet hade spelaren
			fått läsa "%s remains". ]]
		local ok, reason, extra = Net.get("MountRequest"):InvokeServer(model)
		if ok and onMount then
			--[[ `extra` bär SKÄLETS ARGUMENT på avslag och RITTMÄRKET på ja
			     (#233, ChatGPT-review av #241). De två kan inte förväxlas:
			     grenarna är åtskilda av `ok`, och ingen av dem läser det
			     andras värde. Märket måste följa med hit, för det är
			     `init.client` som skickar avsikterna och alltså den som
			     behöver kunna tala om vilken ritt de hör till. ]]
			onMount(model, extra)
		elseif not ok then
			--[[ Skälet är en språknyckel sedan #162. Loggen skriver båda:
				nyckeln för den som felsöker, texten för den som läser
				vad spelaren faktiskt fick se.

				OCH LOGGEN ÄR INTE SPELAREN (#204). `warn` går till Output-
				fönstret; den som står vid hästen ser ingenting. Mätt i
				Studio på `c30f1ff`: fyra olika avslag, panelen oförändrad
				i alla fyra. Skälet går nu till samma meddelanderad som
				#203 gav förberedelsen. ]]
			if avslagVisare then avslagVisare(reason, extra) end
			warn(("[Horse] Kunde inte sitta upp: %s (%s)"):format(
				Sprak.t(tostring(reason)), tostring(reason)))
		end
	end)

	prompts[model] = prompt
end

local function addLedPrompt(model: Model)
	if ledKnappar[model] then return end
	if not farVisasLed(model) then return end
	local rig = RigAdapter.build(model)
	if not rig then return end

	--[[ ── LEDA (#162 blockerare 2) ──────────────────────────────────

		Ledningen behöver en egen knapp: uppsittningen och ledningen är
		två olika handlingar, och en gemensam prompt hade tvingat spelaren
		att gissa vilken hon fick. Den här sitter på samma rot men är ett
		eget objekt, och den växlar text efter läget — precis som dörrarna.

		Servern äger sanningen. Klienten frågar och skriver ut skälet;
		den avgör ingenting själv. ]]
	local led = Instance.new("ProximityPrompt")
	led.Name = "LedPrompt"
	--[[ HANDLINGEN BAR HASTENS NAMN. "Led hasten" gick inte att skilja
		fran "Rida nu" nar de lag pa varandra; "Led Trixie" gor det, utan
		att spelaren behover lasa objektraden under. ]]
	led.ActionText = ledtext(model, false)
	led.ObjectText = hastnamn(model)
	led.HoldDuration = 0.2
	led.MaxActivationDistance = 12
	led.RequiresLineOfSight = false
	led.KeyboardKeyCode = Enum.KeyCode.L
	led.Parent = rig.root
	stallIn(led)

	led.Triggered:Connect(function()
		local leder = ledPrompts[model] == true
		--[[ ETT if-else-UTTRYCK BÄR BARA ETT VÄRDE (#204).

			Raden såg ut att ta emot `(ok, skal)` från båda grenarna, men
			`if a then f() else g()` är ett UTTRYCK i Luau och trunkeras
			till sitt första värde. `skal` var därför alltid `nil` — och
			det syntes inte så länge nejet ändå bara gick till `warn`, som
			skriver "nil" utan att någon reagerar.

			Mätt i banken när avslaget routades till panelen: spelaren fick
			"Det gick inte just nu" i stället för "Walk up to her first".

			Ett `if`-STATEMENT bär båda värdena. ]]
		local ok, skal
		if leder then
			ok, skal = Net.get("LedSlapp"):InvokeServer()
		else
			ok, skal = Net.get("LedBorja"):InvokeServer(model)
		end
		if ok then
			ledPrompts[model] = if leder then nil else true
			--[[ EN VAG IN. Texten sattes forut har och en gang till i
				`LedSync`; nu gor `satLeder` bada, plus statusraden och
				kvittensen. Se noten vid funktionen. ]]
			satLeder(if leder then nil else model)
		else
			--[[ Samma sak här (#204): `led.for_langt` och `led.fel_hast`
				är sådant spelaren behöver veta, inte sådant som hör hemma
				i Output. Mätt i Studio på `c30f1ff`: panelen oförändrad
				vid båda. ]]
			if avslagVisare then avslagVisare(skal) end
			warn(("[Led] %s (%s)"):format(Sprak.t(tostring(skal)), tostring(skal)))
		end
	end)
	ledKnappar[model] = led
end

local function removeMount(model: Model)
	local prompt = prompts[model]
	if prompt then
		prompt:Destroy()
		prompts[model] = nil
	end
end

--[[ Kopplet rivs ALDRIG medan hon faktiskt leds: prompten är spelarens
	enda väg att släppa igen, och en knapp som försvinner mitt i ledningen
	hade lämnat henne fast i andra änden av repet. ]]
local function removeLed(model: Model)
	if ledPrompts[model] == true then return end
	local led = ledKnappar[model]
	if led then
		led:Destroy()
		ledKnappar[model] = nil
		ledPrompts[model] = nil
	end
end

local function removePrompt(model: Model)
	removeMount(model)
	removeLed(model)
end

--[[ Räkna om vilka prompter som får finnas.

	Behövs för att `addPrompt` bara körs när en modell dyker upp. Utan det
	här skulle en spelare som blir klar med förberedelsen aldrig få sin
	prompt — modellen fanns ju redan när loopen startade — och en som sitter
	upp skulle behålla den. Anropas när servern skickat ny sanning. ]]
--[[ ══ «RIDA NU» ══════════════════════════════════════════════════════

	Produktbeslut FUN FIRST / RIDE FIRST. Spelaren kommer för att rida;
	skötseln ska göra ritten bättre, inte vara en vägspärr.

	Knappen sitter PÅ HÄSTEN och inte i förberedelsekortet. Två skäl, båda
	praktiska: kortet mäts på pixelnivå av fyra specar och tål inte ett nytt
	element utan att layoutproven skrivs om, och hästen är ändå där spelaren
	står när tanken "jag vill rida nu" uppstår.

	Den försvinner så fort förberedelsen är klar — då är `MountPrompt`
	svaret i stället, och två knappar som gör nästan samma sak vore precis
	den sortens valfrihet som bromsar. ]]
local function addRidaPrompt(model: Model)
	if ridaKnappar[model] then return end
	if not (ridaCheck and ridaCheck(model)) then return end
	local rig = RigAdapter.build(model)
	if not rig then return end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "RidaNuPrompt"
	prompt.ActionText = Sprak.t("interaktion.rida_nu")
	prompt.ObjectText = model:GetAttribute("HorseName") or model.Name
	prompt.HoldDuration = 0.35
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	--[[ `R` DELAS MED «Lektionen vidare», och det går bara ihop så länge
		regel 1 vid `GAMEPAD` håller: knappen är avstängd i sadeln, och
		lektionen svarar inte från marken. ]]
	prompt.KeyboardKeyCode = Enum.KeyCode.R
	prompt.Parent = rig.root
	stallIn(prompt)

	prompt.Triggered:Connect(function()
		--[[ TRE VÄRDEN, INTE TVÅ (#246 A).

		     Exakt samma fel som `MountRequest` ovan hade, och som noten
		     där beskriver — men här var det aldrig rättat. Raden tog
		     `ok, skal` av serverns `(boolean, string?, string?)`, så
		     argumentet föll på golvet hos den SISTA mottagaren i kedjan.

		     Studio-QA 2026-09-18, touch, Trixie sadlad och ledning igång:

		         server -> ok=false skal=forb.fel_tur arg=kanon:Hälsa lugnt
		         spelaren ser  "wrong turn — %s is next"

		     Att bara rätta servern hade inte hjälpt: nejet passerar här
		     sist, och en kedja är hel först när varje led bär vidare. ]]
		local ok, skal, arg = Net.get("RidaNu"):InvokeServer()
		if not ok then
			--[[ Nej:et är oftast välfärdsstoppet: stallet såg något på
				henne idag. Det ska LÄSAS, inte tystas.

				OCH `warn` ÄR ATT TYSTA DET (#202). Raden nedan låg ensam
				här och skrev i Output-fönstret — synligt för den som har
				Studio öppet, osynligt för spelaren. Mätt i Studio på
				`e6a674c`: ett andra "Rida nu" svarade `tack.redan_pa` och
				panelen sa ingenting alls.

				Nu går skälet till den yta spelaren tittar på. `warn`
				står kvar för den som felsöker; nyckeln bredvid texten är
				vad loggen är till för. ]]
			if avslagVisare then avslagVisare(skal, arg) end
			--[[ Loggen ska visa DET SPELAREN SER, annars ljuger den för den
			     som felsöker. Argumentet följer därför med hit också — det
			     var den här raden som skrev "%s" i QA-loggen. ]]
			warn(("[Horse] Rida nu: %s (%s)"):format(
				if arg ~= nil then Sprak.t(tostring(skal), arg)
					else Sprak.t(tostring(skal)),
				tostring(skal)))
		end
		InteractionController.uppdatera()
	end)

	ridaKnappar[model] = prompt
end

local function removeRida(model: Model)
	local k = ridaKnappar[model]
	if k then k:Destroy() end
	ridaKnappar[model] = nil
end

--[[ Vem som avgör om knappen får visas. Samma mönster som `setLedCheck`:
	klienten frågar, gameplaylagret svarar. ]]
function InteractionController.setRidaCheck(fn: ((Model) -> boolean)?)
	ridaCheck = fn
end

--[[ Vem som VISAR ett nej för spelaren. Samma mönster igen: den här filen
	äger knappen, förberedelsepanelen äger meddelanderaden, och kopplingen
	görs i `init.client` i stället för att de två ska känna varandra. ]]
function InteractionController.setAvslagVisare(fn: ((any, any?) -> ())?)
	avslagVisare = fn
end

--[[ ══ «SADLA» (#235 FAS 2) ══════════════════════════════════════════

	Knappen finns BARA nar spelaren faktiskt bar den har hastens sadel, och
	den forsvinner i samma ogonblick sadeln ligger pa ryggen. Den ar alltsa
	inte ett lage man kan sta i utan en handling som finns nar den gar att
	gora — samma regel som «Rida nu», som forsvinner nar forberedelsen ar
	klar.

	KNAPPEN AVGOR INGENTING. `sadlaCheck` sager bara om den ritas; servern
	prover fortfarande att hon bar sadeln, att det ar RATT hasts sadel, att
	hasten inte redan ar sadlad och att hon star tillrackligt nara. Fel
	sadel ska ga att FORSOKA — det ar poangen — och nejet kommer da
	darifran. ]]
local function addSadlaPrompt(model: Model)
	if sadlaKnappar[model] then return end
	if not (sadlaCheck and sadlaCheck(model)) then return end
	local rig = RigAdapter.build(model)
	if not rig then return end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "SadlaPrompt"
	prompt.ActionText = Sprak.t("interaktion.sadla_namn", hastnamn(model))
	prompt.ObjectText = hastnamn(model)
	prompt.HoldDuration = 0.35
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	--[[ `F` DELAS MED halvhalten, som bara lever i sadeln. Samma
		kontextregel som bar `R` for «Rida nu» — se noten vid `GAMEPAD`. ]]
	prompt.KeyboardKeyCode = Enum.KeyCode.F
	--[[ PA RYGGEN, inte pa roten: det ar dit sadeln ska, och knappen ska
		peka pa platsen den handlar om. Faller sadelpunkten bort tar roten
		over sa att handlingen aldrig blir onabar. ]]
	prompt.Parent = rig.attachments.Saddle or rig.root
	stallIn(prompt)

	prompt.Triggered:Connect(function()
		local ok, skal = Net.get("SadlaHast"):InvokeServer(model)
		if ok then
			if bekraftelseVisare then
				bekraftelseVisare(skal or "tack.pa_plats", {
					del = Sprak.t("tack.del_sadel"),
					hast = hastnamn(model),
				})
			end
		elseif avslagVisare then
			avslagVisare(skal)
		end
		--[[ Knappen ska forsvinna nar sadeln ligger dar. Servern har redan
			skickat ny sanning; den har raden ar for det TRYCK som inte
			andrade nagot, sa kolumnen inte star kvar och ljuger. ]]
		InteractionController.uppdatera()
	end)

	sadlaKnappar[model] = prompt
end

local function removeSadla(model: Model)
	local k = sadlaKnappar[model]
	if k then k:Destroy() end
	sadlaKnappar[model] = nil
end

function InteractionController.setSadlaCheck(fn: ((Model) -> boolean)?)
	sadlaCheck = fn
end

--[[ ══ «TRANSA» (#235 FAS 3) ═══════════════════════════════════════

	Samma regel som «Sadla», ett steg senare i kedjan: knappen finns
	bara nar spelaren bar den har hastens trans, och forsvinner nar det
	sitter pa huvudet. Servern prover fortfarande allt — ratt trans,
	ratt hast, avstand, hastens tillstand och att sadeln ligger pa
	forst. ]]
local function addTransaPrompt(model: Model)
	if transaKnappar[model] then return end
	if not (transaCheck and transaCheck(model)) then return end
	local rig = RigAdapter.build(model)
	if not rig then return end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TransaPrompt"
	prompt.ActionText = Sprak.t("interaktion.transa_namn", hastnamn(model))
	prompt.ObjectText = hastnamn(model)
	prompt.HoldDuration = 0.35
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.F
	--[[ PA HUVUDET, inte pa ryggen: det ar dit transet ska. Faller
		fastpunkten bort tar roten over sa att handlingen aldrig blir
		onabar. ]]
	prompt.Parent = rig.attachments.BridleAttachment or rig.attachments.Head or rig.root
	stallIn(prompt)

	prompt.Triggered:Connect(function()
		local ok, skal = Net.get("TransaHast"):InvokeServer(model)
		if ok then
			if bekraftelseVisare then
				bekraftelseVisare(skal or "tack.pa_plats", {
					del = Sprak.t("tack.del_trans"),
					hast = hastnamn(model),
				})
			end
		elseif avslagVisare then
			avslagVisare(skal)
		end
		InteractionController.uppdatera()
	end)

	transaKnappar[model] = prompt
end

local function removeTransa(model: Model)
	local k = transaKnappar[model]
	if k then k:Destroy() end
	transaKnappar[model] = nil
end

function InteractionController.setTransaCheck(fn: ((Model) -> boolean)?)
	transaCheck = fn
end

function InteractionController.uppdatera()
	for _, model in CollectionService:GetTagged("Horse") do
		if model:IsA("Model") then
			if farVisas(model) then addPrompt(model) else removeMount(model) end
			if farVisasLed(model) then addLedPrompt(model) else removeLed(model) end
			if ridaCheck and ridaCheck(model) then addRidaPrompt(model)
			else removeRida(model) end
			if sadlaCheck and sadlaCheck(model) then addSadlaPrompt(model)
			else removeSadla(model) end
			if transaCheck and transaCheck(model) then addTransaPrompt(model)
			else removeTransa(model) end
		end
	end
end

--[[ ══ SERVERN ÄGER LEDNINGEN — OCH SÄGER TILL NÄR DEN UPPHÖR ══════

	Knappen växlade sin text OPTIMISTISKT när spelaren tryckte, och
	lyssnade sedan aldrig på servern igen. Kopplet kan dock släppa utan att
	spelaren tryckt: går man för långt (`led.tappade_bort`), fastnar hon
	(`led.fastnat`), sitter man upp (`led.rider`).

	Mätt i Studio: efter att ha gått ifrån hästen svarade servern
	`aktiv=nil` medan knappen fortfarande stod på "Let go". Spelaren såg
	alltså en släpp-knapp för ett koppel som inte fanns, och hade behövt
	trycka två gånger för att få tag i henne igen — utan att få veta
	varför.

	`LedService._sync` skickade redan hela sanningen, med skäl. Ingen
	lyssnade. Nu gör någon det. ]]
local function lyssnaPaLedningen()
	local ok, ev = pcall(function() return Net.get("LedSync") end)
	if not ok or not ev then return end
	(ev :: RemoteEvent).OnClientEvent:Connect(function(vy)
		local leder = type(vy) == "table" and vy.leder == true
		local hastId = if type(vy) == "table" then vy.hastId else nil
		local min: Model? = nil
		for model in pairs(ledKnappar) do
			local ar = leder and model:GetAttribute("HorseId") == hastId
			ledPrompts[model] = if ar then true else nil
			if ar then min = model end
		end
		--[[ SERVERN AR SANNINGEN, ocksa nar kopplet slapper utan att
			spelaren tryckt: for langt bort, fastnat, satte sig upp. Samma
			overgang som knappen anvander, sa att status och kvittens
			kommer aven da. ]]
		satLeder(min)
		if type(vy) == "table" and vy.skal and not leder then
			warn(("[Led] kopplet släpptes: %s (%s)")
				:format(Sprak.t(tostring(vy.skal)), tostring(vy.skal)))
		end
	end)
end

function InteractionController.start(mountCallback: (Model) -> ())
	onMount = mountCallback
	lyssnaPaLedningen()
	for _, model in CollectionService:GetTagged("Horse") do
		if model:IsA("Model") then addPrompt(model); addLedPrompt(model) end
	end
	CollectionService:GetInstanceAddedSignal("Horse"):Connect(function(inst)
		if inst:IsA("Model") then addPrompt(inst); addLedPrompt(inst) end
	end)
	CollectionService:GetInstanceRemovedSignal("Horse"):Connect(function(inst)
		if inst:IsA("Model") then removePrompt(inst :: Model) end
	end)
end

--[[ ══ EN RITT SLÄCKER ALLA KNAPPAR PÅ HÄSTEN — INTE BARA EN AV TRE ══════

	Den här funktionen tog förut bara `prompts`, alltså uppsittningen.
	`ledKnappar` och `ridaKnappar` stod kvar PÅ medan spelaren red, och en
	ProximityPrompt kräver bara närhet — närmare hästen än i sadeln kommer
	man inte. En ryttare som tryckte `R` för att gå vidare i lektionen
	fyrade därför «Rida nu» i samma tryck, och `ButtonY` för lektionen
	fyrade ledningens knapp.

	DET ÄR OCKSÅ HELA GRUNDEN för att `MountPrompt` får dela `ButtonX` med
	«Se ritten»: regel 1 vid `GAMEPAD` är sann först när den här grinden
	gäller alla tre. Innan dess var den ett påstående.

	Läget sparas i `promptarPa` så att det också gäller knappar som byggs
	EFTERÅT — `uppdatera()` kör medan man rider. ]]
function InteractionController.setEnabled(enabled: boolean)
	promptarPa = enabled
	for _, prompt in prompts do prompt.Enabled = enabled end
	for _, prompt in ledKnappar do prompt.Enabled = enabled end
	for _, prompt in ridaKnappar do prompt.Enabled = enabled end
	--[[ #235 FAS 2: OCH DEN FJARDE TABELLEN. Att `setEnabled` bara tog
		uppsittningens var den faktiska buggen i #182 — «Rida nu» och «Led»
		stod kvar pasla i sadeln och `R` fyrade tva saker i samma tryck. En
		ny knapp som glomdes har hade aterinfort exakt det felet, och
		`ButtonY` hade da varit bade «Sadla» och «lektionen vidare»
		samtidigt. Kontextregeln vid `GAMEPAD` vilar pa den har raden. ]]
	for _, prompt in sadlaKnappar do prompt.Enabled = enabled end
	for _, prompt in transaKnappar do prompt.Enabled = enabled end
end

return InteractionController
