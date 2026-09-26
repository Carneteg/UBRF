--!strict
--[[ SKOPAN — en delad takt framför de klientanropade fjärrfunktionerna.

	#259 Gate 1A, ur revisionsfyndet #258 P1-2: de tretton klient→server-
	RemoteFunctions hade ingen taktbegränsning alls, medan de två
	klient→server-RemoteEvents har fullödiga skopor sedan #169 och #233.
	Mönstret fanns alltså redan i projektet — det hade bara inte nått
	fram till fjärrFUNKTIONERNA.

	Robloxs egen dokumentation lägger ansvaret på oss:

	    "Whenever server-side logic can be triggered by the client (via
	     remotes, Touched events, proximity prompts, ClickDetectors,
	     etc.), there is a possibility that this logic could be spammed
	     by exploiters or even legitimate users."
	    — scripting/security/client-server-boundary.md:150-152

	Samma sida listar `DataStoreService` och `BadgeService` som en EGEN
	kategori med inbyggda gränser (:156). Fjärrobjekt har inga.

	══ EN SKOPA, INTE TRETTON ════════════════════════════════════════

	`grind()` är hela mekanismen, och den är avsiktligt det enda stället
	som räknar polletter. Tretton egna varianter hade blivit tretton
	egna buggar, och den fjortonde handlingen hade fått en fjortonde.

	══ VAD EN GRÄNS BETYDER ══════════════════════════════════════════

	`tak` är hur många anrop som får komma i en skur, `pafyll` hur många
	polletter som växer tillbaka per sekund. En handling med
	`{ tak = 8, pafyll = 4 }` tål alltså åtta tryck i rad och därefter
	fyra i sekunden i all evighet.

	Talen är satta för en MÄNNISKA, inte för en bänk. Den som trycker så
	fort hon kan på en pekskärm ligger under fyra i sekunden; den som
	spammar över nätet ligger tusenfalt över. Mellanrummet är stort med
	flit — en gräns som ligger nära det mänskliga taket blir en gräns
	som fäller ärliga spelare på dålig uppkoppling.

	══ VARFÖR GRÄNSERNA LIGGER HÄR OCH INTE I `Config` ═══════════════

	`Config.RIDINPUT` bär skoporna för `StateSync` och `RidingIntent`,
	och det är rätt plats för dem: klienten SPEGLAR de talen för sin
	egen prediktion, så de måste vara replikerade.

	De här talen speglar ingen. De är en ren serverkontroll som ingen
	klient behöver känna till, och de hör därför hemma i serverkällan.
	Det är inte två sanningar om samma sak — det är två olika saker.

	══ AVSLAG ÄR TYST, MEN INTE OSYNLIGT ═════════════════════════════

	Ett avslag som skriver en loggrad per anrop är en loggflod med extra
	steg, och just den floden var ett av fynden i #258: `LedBorja` körde
	`warn` på varje nekat anrop utan ett enda förvillkor. Att lägga
	grinden FÖRE handlaren tar bort den floden.

	Men en helt tyst gräns går inte att upptäcka. Därför räknas avslagen
	per spelare och sammanfattas i EN rad per fönster — se
	`LOGGFONSTER`. Den som spammar kostar alltså en jämförelse och en
	räknare, inte en formaterad sträng.
]]

local Players = game:GetService("Players")

local Skopa = {}

export type Grans = { tak: number, pafyll: number }

--[[ Standarden gäller varje handling som inte står i tabellen nedan. Den
	är avsiktligt snål: en ny fjärrfunktion ska vara skyddad den dag den
	skrivs, inte den dag någon minns att lägga till den här. ]]
local STANDARD: Grans = { tak = 4, pafyll = 1 }

--[[ ══ GRÄNSERNA, EN PER HANDLING ═══════════════════════════════════

	Deklarativa med flit: den som vill veta vad servern släpper igenom
	ska kunna läsa det i en tabell, inte i tretton funktionskroppar.

	Kolumnerna är `tak` (skur) och `pafyll` (polletter per sekund). ]]
local GRANSER: { [string]: Grans } = {
	--[[ SKÖTSELNS MOMENT är den enda handlingen en människa gör många av
		i rad — hon bockar av en checklista. Taket är därefter. ]]
	PreparationMoment = { tak = 10, pafyll = 4 },
	PassMoment = { tak = 10, pafyll = 4 },

	--[[ Ett fyndsvar är ett val bland få, och det görs en gång. ]]
	PreparationSvar = { tak = 4, pafyll = 1 },

	--[[ HANDSKAKNINGEN görs en gång per klientstart. Taket tre täcker en
		omstart och en respawn utan att öppna för en loop. ]]
	PreparationHello = { tak = 3, pafyll = 0.5 },

	--[[ Den döda vägen ur #161 svarar bara "gammal klient". Den behöver
		inte mer än så. ]]
	PreparationStep = { tak = 2, pafyll = 0.5 },

	--[[ UPP OCH NED UR SADELN. Ett par tryck i rad är mänskligt; en
		ström är det inte. ]]
	MountRequest = { tak = 4, pafyll = 1 },
	DismountRequest = { tak = 4, pafyll = 1 },

	--[[ LEDNINGEN. `LedBorja` var den ena av de två konkreta vägarna i
		#258: ett anrop med `nil` nekas på första raden och skrev ändå en
		`warn`. Grinden ligger nu före den raden. ]]
	LedBorja = { tak = 4, pafyll = 1 },
	LedSlapp = { tak = 4, pafyll = 1 },

	--[[ UTRUSTNINGEN bygger fysiska delar på hästen. Dyrare än ett
		listtryck, och inget en människa gör i ström. ]]
	SadlaHast = { tak = 4, pafyll = 1 },
	TransaHast = { tak = 4, pafyll = 1 },

	--[[ `RidaNu` låter stallet göra i ordning HELA hästen. Det är den
		dyraste enskilda handlingen i hela gränssnittet. ]]
	RidaNu = { tak = 3, pafyll = 0.5 },

	--[[ `MinHast` frågar efter dagens tilldelning. Svaret ändras inte
		mellan två anrop i samma sekund. ]]
	MinHast = { tak = 3, pafyll = 0.5 },

	--[[ Språkflaggan. Ett barn som trycker fram och tillbaka ska inte
		stoppas, en ström ska det. ]]
	SprakVal = { tak = 6, pafyll = 2 },
}

Skopa.STANDARD = STANDARD
Skopa.GRANSER = GRANSER

--[[ En rad per spelare och fönster, inte en per avslag. ]]
local LOGGFONSTER = 60

type Hink = { polletter: number, senast: number }

local hinkar: { [Player]: { [string]: Hink } } = {}
local avslag: { [Player]: { antal: number, sedan: number } } = {}

--[[ ── KLOCKAN, OCH VARFÖR DEN ÄR INJICERBAR ───────────────────────

	En skopa som fylls på över tid går inte att mäta i en Luau-bänk:
	`os.clock` går, men den går i CPU-tid, och ett provblock som gör tio
	anrop i rad hinner inte fylla på mätbart mycket. Ett prov som
	»väntar« genom att snurra vore både långsamt och flakigt.

	Adaptern finns därför av exakt samma skäl som katalog- och
	avataradaptrarna i `TavlingskladerService`: utan den vore
	påfyllningen ett påstående i en kommentar i stället för en mätning.
	Produktionen rör den aldrig. ]]
local klocka: () -> number = os.clock

function Skopa._satKlockaForProv(fn: (() -> number)?)
	klocka = fn or os.clock
end

function Skopa.grans(handling: string): Grans
	return GRANSER[handling] or STANDARD
end

--[[ Sammanfattar i stället för att skrika. Räknaren nollställs när raden
	skrivits, så nästa fönster räknar om från noll. ]]
local function rakna(player: Player, handling: string, nu: number)
	local a = avslag[player]
	if not a then
		a = { antal = 0, sedan = nu }
		avslag[player] = a
	end
	a.antal += 1
	if nu - a.sedan >= LOGGFONSTER then
		warn(("[Takt] %s nekades %d fjärranrop på %d s (senast %s)")
			:format(tostring((player :: any).Name), a.antal,
				math.floor(nu - a.sedan), handling))
		a.antal = 0
		a.sedan = nu
	end
end

--[[ ── SLÄPPS DET HÄR ANROPET IGENOM? ───────────────────────────────

	Returnerar `true` och förbrukar en pollett, eller `false` och rör
	ingenting. Fail closed: en spelare utan `Player`-identitet får inget
	släppt igenom alls — det finns ingen budget att föra bok över, och en
	anonym anropare är inte ett läge tjänsten ska hitta på ett svar för. ]]
function Skopa.slapp(player: Player, handling: string): boolean
	if type(player) ~= "table" and typeof(player) ~= "Instance" then
		return false
	end
	local nu = klocka()
	local grans = Skopa.grans(handling)

	local mina = hinkar[player]
	if not mina then
		mina = {}
		hinkar[player] = mina
	end
	local hink = mina[handling]
	if not hink then
		--[[ Full skopa vid första anropet: en spelare som precis anlänt
			ska kunna göra sin handskakning och sitta upp utan att vänta
			in en påfyllning som aldrig behövts. ]]
		hink = { polletter = grans.tak, senast = nu }
		mina[handling] = hink
	end

	hink.polletter = math.min(grans.tak,
		hink.polletter + (nu - hink.senast) * grans.pafyll)
	hink.senast = nu

	if hink.polletter < 1 then
		rakna(player, handling, nu)
		return false
	end
	hink.polletter -= 1
	return true
end

--[[ ── GRINDEN ──────────────────────────────────────────────────────

	Lindar en `OnServerInvoke`-handlare. Släpps anropet inte igenom körs
	handlaren ALDRIG — det är hela poängen: typvalideringen, domänreglerna
	och de dyra världsuppslagen ligger inuti handlaren, och en nekad
	anropare ska inte kosta något av det.

	`avslag` är handlarens EGEN nej-form. De tretton handlarna svarar inte
	med samma typ — de flesta ger `(false, nyckel)`, men handskakningen
	ger en vy och `MinHast` en hästpost. Ett gemensamt `false` där hade
	varit en ny form klienten aldrig sett, och kontraktet i #259 säger att
	ingen rå felkod får nå spelaren. Den som lindar en handlare med annan
	form skickar därför med sin egen. ]]
function Skopa.grind(handling: string, fn: (...any) -> ...any,
	avslagsvar: (() -> ...any)?): (...any) -> ...any
	return function(player: Player, ...)
		if not Skopa.slapp(player, handling) then
			if avslagsvar then
				return avslagsvar()
			end
			return false, "takt.for_snabbt"
		end
		return fn(player, ...)
	end
end

--[[ Städningen. Anropas ur `PlayerRemoving` och lämnar ingen post kvar —
	varken hink eller avslagsräknare. Båda är Player-nycklade, och en
	tabell med starka nycklar som aldrig töms är samma läcka som #258
	pekade ut på andra ställen.

	RESPAWN NOLLSTÄLLER INTE. Budgeten följer spelaren, inte kroppen:
	annars vore en död en gratis påfyllning, och det är en väg in i just
	det missbruk skopan finns för. ]]
function Skopa.glom(player: Player)
	hinkar[player] = nil
	avslag[player] = nil
end

--[[ Ett mått, som `TavlingskladerService.kvarvarande`: hur många spelare
	skopan fortfarande håller något om. Finns för att "städningen är
	deterministisk" annars bara är ett påstående. ]]
function Skopa.kvarvarande(): number
	local sedda: { [Player]: boolean } = {}
	local n = 0
	for player in pairs(hinkar) do
		if not sedda[player] then
			sedda[player] = true
			n += 1
		end
	end
	for player in pairs(avslag) do
		if not sedda[player] then
			sedda[player] = true
			n += 1
		end
	end
	return n
end

--[[ Bänken har ingen riktig tid: `os.clock` går, men långsamt, och ett
	provblock som gör tio anrop i rad hinner inte fylla på något. Den här
	finns av samma skäl som `SparService._glomHookarForProv` — så att
	block två inte kör med block ettas förbrukade polletter. ]]
function Skopa._nollstallForProv()
	hinkar = {}
	avslag = {}
end

function Skopa.start()
	Players.PlayerRemoving:Connect(Skopa.glom)
	print("[Takt] Skopan igång")
end

return Skopa
