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
local onMount: ((Model) -> ())? = nil

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
local PROMPT_RAD = { MountPrompt = -1, RidaNuPrompt = 0, LedPrompt = 1 }

local function laggIKolumn(prompt: ProximityPrompt)
	local rad = PROMPT_RAD[prompt.Name] or 0
	prompt.UIOffset = Vector2.new(0, rad * InteractionController.PROMPT_STEG)
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
		och lamnas; `ClickablePrompt` ar det som gor knappen tryckbar med
		ett finger, och `GamepadKeyCode` ger den en EGEN knapp sa att
		uppsittning, genvag och ledning inte delar `ButtonX`. ]]
	prompt.ClickablePrompt = true
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.Parent = rig.attachments.Saddle or rig.root
	laggIKolumn(prompt)

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
			onMount(model)
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
	led.ClickablePrompt = true
	led.GamepadKeyCode = Enum.KeyCode.ButtonY
	led.Parent = rig.root
	laggIKolumn(led)

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
	prompt.KeyboardKeyCode = Enum.KeyCode.R
	prompt.ClickablePrompt = true
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonB
	prompt.Parent = rig.root
	laggIKolumn(prompt)

	prompt.Triggered:Connect(function()
		local ok, skal = Net.get("RidaNu"):InvokeServer()
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
			if avslagVisare then avslagVisare(skal) end
			warn(("[Horse] Rida nu: %s (%s)"):format(
				Sprak.t(tostring(skal)), tostring(skal)))
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

function InteractionController.uppdatera()
	for _, model in CollectionService:GetTagged("Horse") do
		if model:IsA("Model") then
			if farVisas(model) then addPrompt(model) else removeMount(model) end
			if farVisasLed(model) then addLedPrompt(model) else removeLed(model) end
			if ridaCheck and ridaCheck(model) then addRidaPrompt(model)
			else removeRida(model) end
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

function InteractionController.setEnabled(enabled: boolean)
	for _, prompt in prompts do
		prompt.Enabled = enabled
	end
end

return InteractionController
