--!strict
--[[ GAMEPLAYSERVICE — skötseln och passet, server-auktoritativt.

	Gate G01 skiva S2b byggde förberedelsen. #161 gör den till gameplay och
	lägger dagen runt den. Loopen är hela vägen:

	    Hälsa → Visitera → Rykta → Gör i ordning → Led → Sitt upp
	      → rid → sitt av → eftervård → passet räknas → spara → ny dag

	Ansvarsfördelningen är hela poängen med filen:

	  · `SparService` äger det varaktiga lagret och varje skrivning.
	  · `StallService` äger vilken kanonisk `HorseId` spelaren fått.
	  · `Preparation` äger förberedelsens regler — momenten, ordningen,
	    fyndet och välfärdsstoppet. Ren logik, provas utan Studio.
	  · `Pass` äger dagen efter uppsittningen — eftervården och när ett
	    pass får räknas.
	  · `HorseService` äger uppsittning, avsittning och ridningen. Den här
	    filen sitter uppsittning ALDRIG själv; den registrerar ett villkor
	    via `setMountGate`.
	  · Den här filen äger BINDNINGEN: vilken modell i världen som är den
	    tilldelade identiteten, avstånden, och tidpunkterna.

	Klienten får aldrig flytta fram förberedelsen. Den skickar en avsikt
	("jag vill krafsa vänster fram") och får hela sanningen tillbaka.
	Skälet är inte fusk i ett familjespel — det är att två klienter annars
	kan tro olika saker om samma häst, och då är det inte längre servern
	som håller loopen. Samma regel gäller passet och sparningen: det finns
	ingen väg in där en klient skickar ett tillstånd.
]]

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Core = require(ReplicatedStorage.HorseCore)
local Preparation = require(ReplicatedStorage.HorseCore.Preparation)
local Pass = require(ReplicatedStorage.HorseCore.Pass)
local Sparning = require(ReplicatedStorage.HorseCore.Sparning)
local Net = Core.Networking

local HorseService = require(script.Parent.HorseService)
local StallService = require(script.Parent.StallService)
local SparService = require(script.Parent.SparService)

local GameplayService = {}

local TAG = "Horse"

--[[ Så nära man måste stå för att få göra ett steg. Servern äger talet;
	klienten får inte skicka med sitt eget avstånd.

	Stod först på 16 med kommentaren att man ryktar NÄRMARE än man sitter upp
	— men `MountRange` är 14, så talet sa raka motsatsen till kommentaren.
	Senior review fällde motsägelsen på #61.

	12 studs är valt: faktiskt närmare än uppsittningens 14, och samma tal som
	den tidigare S2-specen använde. Game feel avgörs i Studio, inte här. ]]
local STEG_RACKVIDD = 12

--[[ Hur många pass en häst vilar efter ett rapporterat fynd. Talet är
	litet med flit: en familjespelare ska märka att hästen är borta ur
	rotationen nästa gång, inte förlora henne i en vecka. ]]
local VILA_PASS = 2

local state: { [Player]: Preparation.State } = {}
local passState: { [Player]: Pass.State } = {}
local bunden: { [Player]: Model } = {}

--[[ Ett strikt växande serienummer per spelare. Varje vy servern skickar —
	spontan sync eller svar på handskakningen — bär sitt nummer, så att
	klienten kan kasta en gammal vy som råkar komma sist. Krav 10. ]]
local revision: { [Player]: number } = {}

local function nastaRev(player: Player): number
	revision[player] = (revision[player] or 0) + 1
	return revision[player]
end

--[[ ── Bindningen ──────────────────────────────────────────────────── ]]

--[[ Modellen vars `HorseId` är EXAKT den tilldelade, och som ingen annan
	spelare redan är bunden till.

	Ingen närmast-häst-fallback. Att binda närmaste Horse-taggade modell är
	frestande — det gör att något alltid händer — men det gör också att
	spelaren gör i ordning fel individ utan att få veta det. Hellre
	`waiting_model`. ]]
local function hittaModell(player: Player, hastId: string): Model?
	--[[ Kandidaterna samlas här; VALET görs i Preparation. Tjänsten har med
		flit ingen egen kopia av villkoret — se modulens kommentar. ]]
	local kandidater = {}
	for _, modell in CollectionService:GetTagged(TAG) do
		if modell:IsA("Model") then
			table.insert(kandidater, { id = modell:GetAttribute("HorseId"), modell = modell })
		end
	end
	local upptagna = {}
	for annan, m in pairs(bunden) do
		if annan ~= player then upptagna[m] = true end
	end
	return Preparation.valjModell(kandidater, hastId, upptagna) :: Model?
end

local function status(player: Player): string
	local s = state[player]
	if not s then return Preparation.STATUS.VANTAR_MODELL end
	--[[ Välfärdsstoppet läses FÖRE ritten. En spelare som stoppat arbetet
		sitter inte upp, men om hon på något sätt ändå gjorde det ska HUD:en
		säga varför hästen inte arbetar — inte "du rider". ]]
	if s.stoppad then return Preparation.STATUS.STOPPAD end
	if HorseService.horseOf(player) then return Preparation.STATUS.RIDER end
	if not bunden[player] then return Preparation.STATUS.VANTAR_MODELL end
	return if Preparation.redo(s) then Preparation.STATUS.REDO else Preparation.STATUS.FORBEREDER
end

local function vyFor(player: Player)
	return Preparation.vy(state[player], status(player), nastaRev(player))
end

--[[ Spontan sanning till ägaren. Den kan gå förlorad om klienten ännu inte
	anslutit sin listener — en RemoteEvent köas inte åt en framtida
	lyssnare — och det är precis därför `PreparationHello` finns. Att bara
	FireClient härifrån var felet senior review fällde: en klient som
	anslöt sent startade utan hästId, steg och ready-state. ]]
local function skicka(player: Player)
	Net.get("PreparationSync"):FireClient(player, vyFor(player))
end

local function skickaPass(player: Player)
	Net.get("PassSync"):FireClient(player, Pass.vy(passState[player], nastaRev(player)))
end

--[[ Passnumret för dagen som börjar. Ur sparningen, alltså serverns tal.

	Faller sparningen är talet 1, och det betyder "första dagen" — vilket
	gör dagen FRI FRÅN FYND. Det är avsiktligt fail-safe åt spelarens håll
	i just den här frågan: ett datalagerfel ska inte kunna hitta på en
	skada som sedan inte går att spara bort. ]]
local function passnummer(player: Player): number
	local save = SparService.save(player)
	return if save then Sparning.aktuelltPass(save) else 1
end

--[[ Försök binda identiteten till en modell. Anropas vid ankomst och varje
	gång en Horse-taggad modell dyker upp — en rigg som strömmas in eller
	byggs senare ska fångas upp utan att spelaren gör om något. ]]
function GameplayService.bind(player: Player): Model?
	local hastId = StallService.hastIdFor(player)
	if not hastId then return nil end

	if not state[player] or state[player].hastId ~= hastId then
		state[player] = Preparation.nyState(hastId, passnummer(player))
		--[[ Passet skapas samtidigt som förberedelsen, och `passId` sätts
			EN gång här. Räknades det om vid avslutet vore kvittot i
			`Sparning.registreraPass` värdelöst — se `Pass.byggId`. ]]
		passState[player] = Pass.nyState(hastId,
			Pass.byggId(player.UserId, hastId, passnummer(player)))
		bunden[player] = nil
	end

	local modell = hittaModell(player, hastId)
	if modell then
		bunden[player] = modell
	else
		bunden[player] = nil
	end
	skicka(player)
	skickaPass(player)
	return modell
end

--[[ ── Stegen ──────────────────────────────────────────────────────── ]]

local function avstandOk(player: Player, modell: Model): boolean
	local karaktar = player.Character
	local rot = karaktar and karaktar:FindFirstChild("HumanoidRootPart")
	if not (rot and rot:IsA("BasePart")) then return false end
	local pivot = modell.PrimaryPart or modell:FindFirstChildWhichIsA("BasePart")
	if not pivot then return false end
	return (rot.Position - pivot.Position).Magnitude <= STEG_RACKVIDD
end

--[[ Allt som gäller FÖRE ett skötselmoment får göras: att spelaren har en
	häst, att hon står vid rätt modell, och att modellen finns.

	Bruten ut ur `moment` för att `svara` behöver exakt samma prövning. Låg
	den bara i `moment` gick fyndsvaret att skicka från andra sidan gården. ]]
local function narvaro(player: Player): (boolean, string?)
	local s = state[player]
	if not s then
		return false, "Du har ingen tilldelad häst"
	end
	local modell = bunden[player]
	if not modell then
		--[[ Prova en gång till: riggen kan ha dykt upp sedan sist. ]]
		modell = GameplayService.bind(player)
		if not modell then
			return false, "Din häst finns inte i världen än"
		end
	end
	if not avstandOk(player, modell) then
		return false, "Du står för långt bort"
	end
	return true, nil
end

--[[ Ett skötselmoment. ENDA vägen framåt i förberedelsen sedan #161.

	Den gamla `GameplayService.utfor(player, fasId)` — ett tryck, en hel
	fas avbockad — finns inte längre, och det är hela poängen med skivan:
	den var en checklista, och en klient som fick kvittera en fas kunde
	kvittera alla på fem anrop. Nu går varje steg framåt genom ett moment
	som `Preparation` prövar mot ordning, avstånd, individ och välfärd. ]]
function GameplayService.moment(player: Player, fasId: string, momentId: string): (boolean, string?)
	if typeof(fasId) ~= "string" or typeof(momentId) ~= "string" then
		return false, "Ogiltigt steg"
	end
	local naravaro_ok, skal = narvaro(player)
	if not naravaro_ok then
		return false, skal
	end
	local s = state[player]

	local ok, avslag = Preparation.utforMoment(s, fasId, momentId, s.hastId)
	skicka(player)
	return ok, avslag
end

--[[ Svaret på ett fynd. Rätt svar stoppar arbetet, sparar hästens vila och
	räknar passet — spelaren gjorde precis det momentet lär ut, och ska inte
	förlora dagen på det. ]]
function GameplayService.svara(player: Player, svarId: string): (boolean, string?)
	if typeof(svarId) ~= "string" then
		return false, "Ogiltigt svar"
	end
	local naravaro_ok, skal = narvaro(player)
	if not naravaro_ok then
		return false, skal
	end
	local s = state[player]

	local ok, avslag = Preparation.svaraFynd(s, svarId)
	if ok then
		--[[ Skadan skrivs INNAN passet räknas. Faller skrivningen har vi
			hellre en sparad skada utan pass än ett pass utan skada: det
			första kostar spelaren en dag, det andra sätter en halt häst i
			arbete i morgon. ]]
		local save = SparService.save(player)
		if save then
			Sparning.satSkada(save, s.hastId, VILA_PASS,
				(s.fynd and s.fynd or nil) :: any)
		end
		local p = passState[player]
		if p then
			Pass.vidValfardsstopp(p)
			GameplayService.avslutaPass(player)
		end
	end
	skicka(player)
	skickaPass(player)
	return ok, avslag
end

--[[ ── Passet ──────────────────────────────────────────────────────── ]]

function GameplayService.eftervard(player: Player, momentId: string): (boolean, string?)
	if typeof(momentId) ~= "string" then
		return false, "Ogiltigt steg"
	end
	local p = passState[player]
	if not p then
		return false, "Du har inget pass igång"
	end
	--[[ Eftervården kräver samma närvaro som skötseln: man tar av sadeln
		vid hästen, inte från läktaren. ]]
	local naravaro_ok, skal = narvaro(player)
	if not naravaro_ok then
		return false, skal
	end

	local ok, avslag = Pass.utfor(p, momentId)
	if ok and Pass.farAvsluta(p) then
		GameplayService.avslutaPass(player)
	end
	skickaPass(player)
	return ok, avslag
end

--[[ Avslutar och RÄKNAR passet. Fail-closed genom `Pass.farAvsluta`, och
	idempotent genom `Sparning.registreraPass`:

	  · en dubbel serverhändelse (avslut + utloggning i samma sekund) ger
	    ETT pass, för kvittot `passId` är detsamma,
	  · en misslyckad skrivning lämnar passet oräknat i lagret men markerar
	    det INTE som räknat i minnet, så nästa försök tar det igen.

	Ordningen minne → lager är vald åt spelarens håll: `markeraRaknat`
	sätts först efter att skrivningen gick fram. ]]
function GameplayService.avslutaPass(player: Player): (boolean, string?)
	local p = passState[player]
	if not p then
		return false, "Du har inget pass igång"
	end
	local ok, skal = Pass.farAvsluta(p)
	if not ok then
		return false, skal
	end

	local save = SparService.save(player)
	if not save then
		return false, "Sparningen är inte igång"
	end

	--[[ Räkningen görs i minnesbilden först, så att `skriv` har något att
		slå ihop. Går skrivningen inte fram ligger den kvar och följer med
		nästa gång — kvittot gör det ofarligt. ]]
	local nytt = Sparning.registreraPass(save, p.passId, os.time())
	if nytt then
		Sparning.raknaNerVila(save)
		--[[ Relationen växer av att ha gjort dagen färdigt, inte av att ha
			ridit. Det är samma värdering som resten av loopen: ansvaret är
			innehållet. Talet är litet — en relation byggs över veckor. ]]
		Sparning.hojRelation(save, p.hastId, 0.04)
		Sparning.markeraForstaDagen(save, p.hastId)
	end

	local skrevs = SparService.skriv(player)
	if skrevs or not SparService.kanSpara(player) then
		--[[ Antingen skrevs det, eller så kan den här sessionen ändå inte
			spara (läsfel eller framtida sparfil). I båda fallen är passet
			klart för spelaren; i det andra får hon veta det genom
			`SparService.anmarkning`. Att låta passet hänga oavslutat i en
			session som ALDRIG kan spara vore att låsa henne i eftervården. ]]
		Pass.markeraRaknat(p)
	end

	skicka(player)
	skickaPass(player)
	return true, nil
end

--[[ ── Uppsittningsgrinden ─────────────────────────────────────────── ]]

--[[ Registreras i `HorseService`. Körs FÖRE all uppsittningslogik, så en
	oförberedd spelare aldrig hinner bli monterad och sedan kastas av. ]]
function GameplayService.farSittaUpp(player: Player, modell: Model): (boolean, string?)
	local s = state[player]
	--[[ Krav 6 och 7 avgörs av regeln, inte här. Kvar i tjänsten är bara
		det instansnära: att modellen dessutom är den vi FAKTISKT bundit,
		så att två modeller med samma id aldrig kan bli utbytbara. ]]
	local ok, skal = Preparation.provaModell(s, modell:GetAttribute("HorseId"))
	if not ok then
		return false, skal
	end
	if bunden[player] ~= modell then
		return false, "Det är inte din häst"
	end
	--[[ Passet får bara börja en gång. Ett andra `tryMount` på samma dag —
		efter en avsittning — ska inte nollställa eftervården. ]]
	local p = passState[player]
	if p and p.lage ~= Pass.LAGE.FORE then
		return false, "Du har redan ridit idag"
	end
	return true, nil
end

--[[ ── Livscykel ───────────────────────────────────────────────────── ]]

local function glom(player: Player)
	state[player] = nil
	passState[player] = nil
	bunden[player] = nil
	revision[player] = nil
end

function GameplayService.start()
	HorseService.setMountGate(GameplayService.farSittaUpp)

	--[[ Uppsittningen och avsittningen driver passets läge. De hakas på
		`HorseService` i stället för att `GameplayService` skulle lyssna på
		remoten: allt som monterar en ryttare går genom `tryMount`, och en
		krok på fjärranropet hade missat varje annan väg in. ]]
	HorseService.setRiderHook(function(player: Player, sitter: boolean)
		local p = passState[player]
		if not p then return end
		if sitter then
			Pass.vidUppsittning(p)
		else
			Pass.vidAvsittning(p)
		end
		skicka(player)
		skickaPass(player)
	end)

	Net.get("PreparationMoment").OnServerInvoke = function(player, fasId, momentId)
		return GameplayService.moment(player, fasId, momentId)
	end
	Net.get("PreparationSvar").OnServerInvoke = function(player, svarId)
		return GameplayService.svara(player, svarId)
	end
	Net.get("PassMoment").OnServerInvoke = function(player, momentId)
		return GameplayService.eftervard(player, momentId)
	end

	--[[ `PreparationStep` finns kvar i nätkontraktet men gör inget mer än
		att säga ifrån. Att ta bort den helt hade gjort att en klient från
		en äldre version tyst fick nil tillbaka och stod och väntade; nu får
		den ett begripligt nej. Fasen går inte att kvittera den vägen — det
		är hela ändringen i #161. ]]
	Net.get("PreparationStep").OnServerInvoke = function(_player, _fasId)
		return false, "Skötseln görs moment för moment nu — uppdatera klienten."
	end

	--[[ Handskakningen. Klienten anropar den FÖRST efter att den anslutit sin
		`PreparationSync`-listener, och får hela nuläget i retur. Det gör
		starttillståndet deterministiskt oavsett vem som hann först.

		Svaret bär samma revision som en spontan sync, så om en nyare sync
		hinner före svaret kastar klienten svaret i stället för att backa. ]]
	Net.get("PreparationHello").OnServerInvoke = function(player)
		if not state[player] then
			GameplayService.bind(player)
		end
		--[[ Passvyn skickas som en egen sync i samma andetag. Utan den
			startade en klient som anslöt mitt i eftervården utan att veta
			att det fanns en eftervård — samma hål som handskakningen
			byggdes för att täta på förberedelsen. ]]
		skickaPass(player)
		return vyFor(player)
	end

	--[[ Flaggan är serverns svar på "är loopen igång". Klienten läser den
		och visar ingen uppsittningsprompt förrän den är sann. Sätts SIST i
		start(), så att den aldrig är sann innan grinden är registrerad. ]]

	--[[ BINDNINGEN HÄNGER PÅ BARRIÄREN (#162 blockerare 1). Kopplade den
		här filen `PlayerAdded` själv kunde `bind()` köras medan saven ännu
		var nil, och då föll `passnummer()` till 1 — alltså "första dagen",
		med en dag fri från fynd — för en spelare som hade tio pass bakom
		sig. Hooken körs efter att läsningen returnerat.

		Registreringsordningen ger beroendet: `StallService` hookar först
		(init.server startar den före), så `hastIdFor` har ett svar när
		bindningen sker. ]]
	SparService.efterLaddning(function(player)
		GameplayService.bind(player)
		player.CharacterAdded:Connect(function()
			GameplayService.bind(player)
		end)
	end)
	for _, player in Players:GetPlayers() do
		GameplayService.bind(player)
	end
	Players.PlayerRemoving:Connect(glom)

	--[[ En rigg som kommer in senare ska plockas upp av den som väntar på
		henne. Det är krav 2: `waiting_model` ska läka av sig själv. ]]
	CollectionService:GetInstanceAddedSignal(TAG):Connect(function(inst)
		if not inst:IsA("Model") then return end
		for _, player in Players:GetPlayers() do
			if not bunden[player] then
				GameplayService.bind(player)
			end
		end
	end)
	CollectionService:GetInstanceRemovedSignal(TAG):Connect(function(inst)
		for player, m in pairs(bunden) do
			if m == inst then
				bunden[player] = nil
				skicka(player)
			end
		end
	end)

	ReplicatedStorage:SetAttribute("G01Enabled", true)
	print("[Gameplay] Skötseln och passet igång")
end

function GameplayService.stateFor(player: Player): Preparation.State?
	return state[player]
end

function GameplayService.passFor(player: Player): Pass.State?
	return passState[player]
end

function GameplayService.modellFor(player: Player): Model?
	return bunden[player]
end

function GameplayService.statusFor(player: Player): string
	return status(player)
end

return GameplayService
