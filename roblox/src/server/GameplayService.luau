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
--[[ Dagsformens kanon. Belöningen för egen skötsel räknas ur samma
     START-tabell som webben, inte ur en egen konstant. ]]
local RidKanon = require(ReplicatedStorage.HorseCore.RidKanon)
local Sparning = require(ReplicatedStorage.HorseCore.Sparning)
--[[ Rosterns egennamn. Utrustningen kan tillhöra en ANNAN häst än den
	spelaren rider — det är hela poängen med att man kan ta fel sadel — och
	då räcker inte `StallService.hastFor`. Namnet slås upp i samma
	genererade kanon som resten av spelet läser. ]]
local Spel = require(ReplicatedStorage.UBRFSpel)
local LedService = require(script.Parent.LedService)
--[[ #182: ledningen oppnar boxdorren i samma tryck. Se `satDorrKrok`.
	`DorrService` ager dorrarna; den har raden ar bara kopplingen. ]]
local DorrService = require(script.Parent.DorrService)
local TackService = require(script.Parent.TackService)
--[[ #235 FAS 2: rollbacken river en halvlagd del direkt. `TackService`
	har ingen vag som tar av UTAN eftervardens ordningsgrindar, och de
	grindarna hor inte hemma i en angring. ]]
local TackRigg = require(script.Parent.TackRigg)
--[[ #235 FAS 1: fronten ager den fysiska upphangningen, den har filen
	ager vem som bar vad. Ingen cirkel — forradet tar sin mottagare som
	parameter och kanner inte den har modulen. ]]
local TackForradService = require(script.Parent.TackForradService)
local Komplex = require(ReplicatedStorage.UBRFKomplex)
local Net = Core.Networking

local HorseService = require(script.Parent.HorseService)
local StallService = require(script.Parent.StallService)
local SparService = require(script.Parent.SparService)
local Aktor = require(ReplicatedStorage.HorseCore.Aktor)
--[[ #259 Gate 1A: takten framfor de klientanropade fjarrfunktionerna.
	En delad skopa, inte en per handlare — se `Skopa.luau`. ]]
local Skopa = require(script.Parent.Skopa)

local GameplayService = {}

local TAG = "Horse"

--[[ Så nära man måste stå för att få göra ett steg. Servern äger talet;
	klienten får inte skicka med sitt eget avstånd.

	Stod först på 16 med kommentaren att man ryktar NÄRMARE än man sitter upp
	— men `MountRange` är 14, så talet sa raka motsatsen till kommentaren.
	Senior review fällde motsägelsen på #61.

	12 studs är valt: faktiskt närmare än uppsittningens 14, och samma tal som
	den tidigare S2-specen använde. Game feel avgörs i Studio, inte här.

	SEDAN P0-3 STÅR TALET I `Config`. Klienten behöver samma gräns för att
	HUD:en ska kunna säga sanningen om vad som går att göra, och två
	kopior av ett tal är en gräns som glider isär. Servern äger fortfarande
	BESLUTET — klienten får aldrig skicka med sitt eget avstånd. ]]
local STEG_RACKVIDD = Core.Config.STEG_RACKVIDD

--[[ Hur många pass en häst vilar efter ett rapporterat fynd. Talet är
	litet med flit: en familjespelare ska märka att hästen är borta ur
	rotationen nästa gång, inte förlora henne i en vecka. ]]
local VILA_PASS = 2

local state: { [Player]: Preparation.State } = {}
local passState: { [Player]: Pass.State } = {}
local bunden: { [Player]: Model } = {}
--[[ Sadelkammarens val per spelare: `{ sadel = hastId, trans = hastId }`.
	Tomt betyder "tog sin egen" — webben låter en spelare gå direkt till
	boxen utan att passera sadelkammaren, och då är utrustningen hennes. ]]
local valdUtrustning: { [Player]: { [string]: string } } = {}

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

--[[ En hästs egennamn ur rostern. Okänt id ger nil, inte en gissning. ]]
local function hastnamnFor(hastId: string?): string?
	if type(hastId) ~= "string" or hastId == "" then return nil end
	local h = Spel.hastar[hastId]
	return if h and type(h.namn) == "string" then h.namn else nil
end

--[[ Vad spelaren BÄR just nu (#182). Regeln ligger i `Preparation.buren`
	och är ren; den här funktionen gör det enda tjänsten äger — läser
	VÄRLDEN för att svara på vad som redan ligger på hästen.

	Ingen bunden modell betyder att ingenting kan sitta på: en hämtad
	sadel är då fortfarande buren, och `waiting_model` ska inte släcka en
	status som är sann. ]]
local function burenFor(player: Player)
	local modell = bunden[player]
	local paHasten = {
		sadel = modell ~= nil and TackService.sadlad(modell),
		trans = modell ~= nil and TackService.transad(modell),
	}
	return Preparation.buren(valdUtrustning[player], paHasten, hastnamnFor)
end

local function vyFor(player: Player)
	--[[ Hästens egennamn följer med så att klienten kan sätta in det där
		kanonen skriver `%N`. Det översätts aldrig. ]]
	local dagens = StallService.hastFor(player)
	return Preparation.vy(state[player], status(player), nastaRev(player),
		if dagens then dagens.namn else nil, burenFor(player))
end

--[[ Spontan sanning till ägaren. Den kan gå förlorad om klienten ännu inte
	anslutit sin listener — en RemoteEvent köas inte åt en framtida
	lyssnare — och det är precis därför `PreparationHello` finns. Att bara
	FireClient härifrån var felet senior review fällde: en klient som
	anslöt sent startade utan hästId, steg och ready-state. ]]
local function skicka(player: Player)
	--[[ #252 DEL C: vyn gar till aktorens KLIENT. En aktor utan klient
	     — testsatet i runtime-grinden, eller en spelare som just kopplat
	     ned — far ingen sandning. Sanningen ar oforandrad; det ar bara
	     presentationen som inte har nagon mottagare. ]]
	local k = Aktor.klient(player)
	if not k then return end
	Net.get("PreparationSync"):FireClient(k, vyFor(player))
end

local function skickaPass(player: Player)
	local k = Aktor.klient(player)
	if not k then return end
	Net.get("PassSync"):FireClient(k, Pass.vy(passState[player], nastaRev(player)))
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
		return false, "spel.ingen_hast"
	end
	local modell = bunden[player]
	if not modell then
		--[[ Prova en gång till: riggen kan ha dykt upp sedan sist. ]]
		modell = GameplayService.bind(player)
		if not modell then
			return false, "spel.hast_saknas"
		end
	end
	if not avstandOk(player, modell) then
		return false, "spel.for_langt"
	end
	return true, nil
end

--[[ Ett skötselmoment. ENDA vägen framåt i förberedelsen sedan #161.

	Den gamla `GameplayService.utfor(player, fasId)` — ett tryck, en hel
	fas avbockad — finns inte längre, och det är hela poängen med skivan:
	den var en checklista, och en klient som fick kvittera en fas kunde
	kvittera alla på fem anrop. Nu går varje steg framåt genom ett moment
	som `Preparation` prövar mot ordning, avstånd, individ och välfärd. ]]
--[[ `utforare` skickas ALDRIG av klienten: remoten längst ned vidarebefordrar
	bara fas och moment. Den sätts av `ridaNu` när stallet gör arbetet, så
	att omsorgsbonusen räknar spelarens hand och inte stallets. ]]
--[[ KVITTENSENS NYCKLAR (#182). Vilket utrustningssteg som lägger vilken
	del på hästen vet `TackService` och bara den — klienten ska inte räkna
	ut kopplingen en gång till. Servern skickar därför NYCKELN och dess
	argument; texten sätts på klienten, där spelarens språk finns. ]]
local DEL_NYCKEL: { [string]: string } = {
	underlagg = "tack.del_underlagg",
	sadel = "tack.del_sadel",
	trans = "tack.del_trans",
}

function GameplayService.moment(player: Player, fasId: string, momentId: string,
	utforare: string?): (boolean, string?, any?)
	if typeof(fasId) ~= "string" or typeof(momentId) ~= "string" then
		return false, "spel.ogiltigt_steg"
	end
	local naravaro_ok, skal = narvaro(player)
	if not naravaro_ok then
		return false, skal
	end
	local s = state[player]

	--[[ ── `leda` KRÄVER ATT HON FAKTISKT ÄR LEDD DIT ────────────────

		Blockerare 2: steget blev sant så fort spelaren tryckte, och mätt
		i Studio stod hästen kvar i box 31 genom hela förberedelsen.
		En knapptryckning är inte ett bevis på att något hänt i världen.

		Nu prövas två FYSISKA villkor, båda satta av `LedService` ur
		hästens verkliga position och aldrig av något i gränssnittet:
		att hon lämnat boxen, och att hon nått ridbanan. Ordningen på
		nejen är medveten — står hon kvar i boxen är det det spelaren
		behöver höra, inte att hon inte är framme. ]]
	if fasId == "leda" then
		if not LedService.harLamnatBox(player) then
			return false, "led.kvar_i_boxen"
		end
		if LedService.malzon() ~= nil and not LedService.harNattMal(player) then
			return false, "led.inte_framme"
		end
	end

	--[[ ── UTRUSTNINGEN SKA FINNAS PÅ HÄSTEN, INTE I EN BOOLEAN ──────

		Blockerare 5. Ett `utr:`-moment satte förut `state.gjorda` och
		ingenting annat: ingen del skapades, och uppsittningsgrinden kunde
		bara pröva att booleanen fanns. En häst som aldrig sett en sadel
		satt man upp på precis som en sadlad.

		Nu byggs den FYSISKA delen FÖRST, och momentet kvitteras bara om
		den faktiskt kom på plats. Nekar `TackService` — fel häst, fel
		utrustning, för långt bort, redan påsatt — kvitteras ingenting, och
		logiskt och fysiskt kan därför inte glida isär.

		Stegen 3 och 4 (sadelbommen, gjorden) lägger inget nytt på hästen;
		de är handgrepp på den sadel som redan ligger där. De prövas mot
		att den gör det. ]]
	--[[ Vilken del det här momentet lade på hästen, som språknyckel. Satt
		bara när en FYSISK del faktiskt kom på plats — kvittensen namnger
		aldrig något som inte sitter där. ]]
	local pasattDel: string? = nil
	local steg = tonumber(momentId:match("^utr:(%d+)$"))
	if fasId == "iordning" and steg then
		local modell = bunden[player]
		if not modell then return false, "spel.ingen_hast" end
		local kraver = TackService.kraver(steg)
		if kraver and not TackService.harTack(modell, kraver) then
			return false, if kraver == "sadel" then "tack.saknar_sadel" else "tack.saknar_underlagg"
		end
		local typ = TackService.fysiskFor(steg)
		if typ then
			--[[ UTRUSTNINGEN MÅSTE VARA HÄMTAD. Webben gör samma sak och
				med samma innebörd: `sysslor.js:239` vägrar öppna
				"visitera, rykta, kratsa, sadla" utan `G.utrustning`, med
				texten att hästens sadel hänger på sin egen plats.

				Här är den platsen boxfronten (`TackForradService`), och
				kravet är det som gör felvalet möjligt att GÖRA. Föll det
				här kravet bort togs utrustningen tyst från spelarens egen
				häst, och då kan man inte ta fel sadel ens om man vill —
				webbens hela pedagogik ligger i att man kan. ]]
			--[[ UNDERLÄGGET HÖR TILL SADELN och hämtas med den. Både
				verkligheten och webben säger det: stallkortet skriver
				"sadlar med underlag" om det som hänger på fronten, och
				webbens sadelkammare har en bygel per häst, inte en bygel
				för sadeln och en till för schabraket. Det är därför
				`TackForradService` bygger underlägget i samma upphängning
				— och därför valet slås upp på sadeln här. ]]
			local valNyckel = if typ == "underlagg" then "sadel" else typ
			local vald = valdUtrustning[player]
			local utrustningId = vald and vald[valNyckel]
			if utrustningId == nil then
				skicka(player)
				return false, "tack.hamta_forst"
			end
			local ok, skal = TackService.satPa(player, modell, typ,
				utrustningId, modell)
			--[[ ── REDAN PÅ ÄR INTE ETT NEJ ───────────────────────────

				Tobias sadlade Troy själv och tryckte «Rida nu». Svaret
				blev `forb.fel_tur` med `Utrustning 1/5` — alltså «det är
				inte din tur att göra det du redan gjort».

				Kedjan: `satPa` svarar `tack.redan_pa` när en del av den
				sorten redan sitter på hästen, och den här raden
				returnerade DÅ direkt — innan `Preparation.utforMoment`.
				Det LOGISKA momentet kvitterades alltså aldrig, medan det
				FYSISKA var gjort. `ridaNuInre` tolererar `tack.redan_pa`
				och gick vidare till nästa moment, som därmed var ur tur,
				och nejet namngav det moment som faktiskt stod på tur.

				`tack.redan_pa` kommer EFTER ägarkontrollen i `satPa`: fel
				sadel svarar `tack.fel_sadel` långt innan. Att den här
				sorten redan sitter där betyder alltså att rätt sak är på
				plats, inte att något är trasigt. Världen är sanningen —
				det är samma regel raden nedanför redan tillämpar — så
				momentet ska kvitteras på samma grund, inte hoppas över.

				VEM SOM GJORDE DET GÅR INTE ATT LÄSA UR GEOMETRIN, och
				första rättelsen försökte ändå. Den bokförde momentet som
				spelarens så fort utrustningen redan satt på hästen — även
				mitt i en helt automatisk förberedelse, där stallet självt
				satt dit den ett varv tidigare. Granskningen mätte
				`ownU1=auto ownU2=true` i ett rent auto-pass.

				En påsatt sadel är ett faktum om VÄRLDEN, inte om vem som
				lyfte den. Slutledningen är därför borttagen: momentet
				kvitteras — det var `fel_tur`-felet — men med den utförare
				anropet faktiskt bär. Verkligt registrerat handarbete rörs
				inte; påhittat blir det aldrig. ]]
			if not ok and skal ~= "tack.redan_pa" then
				skicka(player)
				return false, skal
			end
			local redanPa = not ok
			--[[ ── OCH DEN SKA FAKTISKT SITTA DÄR (#182) ──────────────
				`satPa` svarar ja när bygget gick fram, men VÄRLDEN är
				sanningen — det är samma regel uppsittningsgrinden läser
				genom `TackService.ridklar`. Föll delen bort mellan bygget
				och den här raden ska momentet inte kvitteras: en kvittens
				som namnger en sadel som inte ligger på hästen vore precis
				den motsägelse `TackService` finns för att omöjliggöra. ]]
			if not TackService.harTack(modell, typ) then
				skicka(player)
				return false, "tack.kunde_inte_byggas"
			end
			--[[ Kvittensen namnger bara det som FAKTISKT kom på henne nu.
			     Låg det redan där är det ingen nyhet för spelaren — se
			     noten vid `tack.pa_plats` längre ned. ]]
			if not redanPa then pasattDel = DEL_NYCKEL[typ] end
		end
	end

	--[[ TREDJE VÄRDET FÖLJER MED (#246 A). Se noten i `Preparation`. ]]
	local ok, avslag, avslagArg =
		Preparation.utforMoment(s, fasId, momentId, s.hastId, utforare)
	skicka(player)
	--[[ KVITTENSEN NAMNGER DELEN OCH HÄSTEN. Den går ut som svarets andra
		och tredje värde — samma kanal som nejen redan använder — så att
		klienten inte behöver en egen väg in för ett lyckat moment. Bara
		när något faktiskt kom på henne; ett vanligt moment kvitteras som
		förut av klientens egen text. ]]
	if ok and pasattDel then
		return true, "tack.pa_plats", {
			del = pasattDel,
			hast = hastnamnFor(s.hastId) or s.hastId,
		}
	end
	return ok, avslag, avslagArg
end

--[[ ══ RIDA NU ════════════════════════════════════════════════════════

	Produktbeslut FUN FIRST / RIDE FIRST: spelaren kommer för att rida.
	Skötseln ska göra ritten bättre — inte vara en vägspärr.

	`ridaNu` är STALLETS förberedelse, inte en genväg förbi den. Hästen ska
	efteråt vara lika korrekt och säkert förberedd som om spelaren gjort
	varje moment själv; spelet får aldrig lära ut fel hästhantering för att
	spara tid.

	Därför går den genom `GameplayService.moment` — samma väg, samma
	prövningar, samma FYSISKA utrustning. Blockerare 5 i #162 var just att
	ett `utr:`-moment satte en boolean utan att någon sadel kom på hästen;
	en egen genväg här hade återinfört det felet i ny form. Det som inte
	går igenom den riktiga vägen ska inte heller kvitteras.

	Utrustningen väljs åt spelaren först — det är stallet som lagt fram
	hennes egen sadel, och `TackService.satPa` prövar fortfarande att den
	hör till rätt häst.

	VAD SOM INTE KRINGGÅS: välfärdsstoppet. Hästens dagstillstånd finns
	oavsett om någon tittar, och har stallet sett något blir det kvar EXAKT
	ETT beslut för spelaren — vad gör vi åt det. Ett steg, inte nio, och
	hästen rids fortfarande inte om hon inte ska ridas. Första passet bär
	aldrig något fynd, så en ny spelare kommer rakt upp i sadeln. ]]
--[[ Sjalva handlingen. Loggen ligger i skalet nedan — «Rida nu» har ett
	dussin vagar ut, och en loggrad per return hade garanterat glidit
	isar fran koden. ]]
local function ridaNuInre(player: Player): (boolean, string?, string?)
	local naravaro_ok, skal = narvaro(player)
	if not naravaro_ok then return false, skal end
	local s = state[player]
	if not s then return false, "spel.ingen_hast" end
	local modell = bunden[player]
	if not modell then return false, "spel.ingen_hast" end

	--[[ ══ HON STÅR REDAN FÄRDIG (#202 punkt 2) ═══════════════════════

		Ett andra "Rida nu" svarade `tack.redan_pa` — alltså ett
		utrustningsfel, för att auto-förberedelsen nedan gick rakt in i
		`TackService.satPa` på en sadel som redan låg på hästen. Sant om
		mekaniken, fel om vad som hänt: ingenting är trasigt, hon är klar.

		Mätt i Studio på `e6a674c`, tio extra aktiveringar varav fem
		parallella:

		    RidaNu #2..#11  ->  false, tack.redan_pa

		Spelaren möter det sällan, för prompten förbrukas efter lyckad
		aktivering — men den som når fjärranropet på något annat sätt får
		ett svar som pekar på fel sak.

		Frågan ställs till samma regel som uppsittningen använder, inte till
		en egen kopia. Idempotensen är oförändrad: det första anropet gör
		jobbet, alla följande rör ingenting. ]]
	if select(1, Preparation.provaUppsittning(s, s.hastId)) then
		return false, "spel.redan_redo"
	end

	--[[ Stallet har lagt fram hennes egen utrustning — som ett par, av
		samma skäl som boxfronten gör det. ]]
	local okPar, skalPar = GameplayService.valjPar(player, s.hastId)
	if not okPar then return false, skalPar or "tack.okand_utrustning" end

	--[[ ── FAIL CLOSED ────────────────────────────────────────────────

		Varje moment går genom den riktiga vägen, och VARJE returvärde
		respekteras. Misslyckas ett fysiskt steg — sadeln kom inte på,
		fel häst, för långt bort — avbryts hela förberedelsen med det
		riktiga nejet.

		Tidigare fyllde `autoForbered` i resten efteråt och gjorde hästen
		"klar" ändå. Ett produktfel ska ge ett riktigt nej, inte döljas av
		auto-state. `forb.redan_gjort` är inget fel: det betyder att
		spelaren redan hunnit göra momentet själv. ]]
	for _, f in ipairs(Preparation.stegFaser()) do
		if f.id ~= "leda" then
			local val = Preparation.arVal(f.id)
			for _, m in ipairs(Preparation.moment(f.id)) do
				if not m.fel and m.id then
					local ok, avslag, avslagArg =
						GameplayService.moment(player, f.id, m.id, "auto")
					--[[ `tack.redan_pa` är samma sort som `forb.redan_gjort`: inte
						ett fel, utan ett moment som redan är utfört. Utan den här
						raden svarade ett andra «Rida nu» med ett UTRUSTNINGSFEL på
						en häst som bara var färdig — se noten vid `spel.redan_redo`
						ovan. Fail-closed är oförändrat: allt ANNAT nej avbryter
						fortfarande hela förberedelsen. ]]
					if not ok and avslag ~= "forb.redan_gjort"
							and avslag ~= "tack.redan_pa" then
						skicka(player)
						--[[ ARGUMENTET MED (#246 A). Den här tidiga returen var
						     den QA-loggen faktiskt gick igenom: sadeln hämtad,
						     ledning igång, och ett moment ur fel fas svarade
						     `forb.fel_tur`. Utan argumentet blev nejet ett
						     bokstavligt "%s" utan väg vidare. ]]
						return false, avslag, avslagArg
					end
					--[[ En valfas behöver ETT riktigt alternativ. ]]
					if val and Preparation.fasKlar(s, f.id) then break end
				end
			end
			if not Preparation.fasKlar(s, f.id) then
				skicka(player)
				return false, "pass.aterstar", Preparation.kanontext(f.namn)
			end
		end
	end

	--[[ ── LEDNINGEN ÄR EN VERKLIG FÖRFLYTTNING ───────────────────────

		Stallet leder ut henne på riktigt. `placeraVidMal` flyttar hästen
		och sätter flaggorna BARA om hon sedan bevisligen står i målzonen.

		Därefter kvitteras `leda` genom den VANLIGA momentvägen, som
		prövar `LedService.harLamnatBox` och `harNattMal`. Ingen genväg
		förbi den grinden: står hon kvar i boxen faller momentet, och då
		blir hästen inte heller uppsittningsklar. ]]
	local flyttad, flyttfel = LedService.placeraVidMal(player, modell)
	if not flyttad then
		skicka(player)
		return false, flyttfel
	end
	for _, m in ipairs(Preparation.moment("leda")) do
		if not m.fel and m.id then
			local ok, avslag, avslagArg =
				GameplayService.moment(player, "leda", m.id, "auto")
			if not ok and avslag ~= "forb.redan_gjort" then
				skicka(player)
				return false, avslag, avslagArg
			end
		end
	end

	skicka(player)
	local klar, varfor, arg = Preparation.provaUppsittning(s, s.hastId)
	return klar, varfor, arg
end

--[[ #264 GAIT_READABILITY_AND_UGNETA: spelarens språkval. Argumentet är en
	fråga från klienten och valideras här: "sv" eller "en", annars nej. Det
	enda som skrivs är spelarens eget attribut, som `Sprak.sprakForSpelare`
	läser — så att det servern säger till henne följer flaggan. ]]
function GameplayService.sprakVal(player: Player, val: any): (boolean, string?)
	if val ~= "sv" and val ~= "en" then return false, nil end
	player:SetAttribute("UBRFSprak", val)
	return true, val
end

function GameplayService.ridaNu(player: Player): (boolean, string?, string?)
	--[[ #182 del 2: loggevidens. «Rida nu» ar genvagen forbi hela
		forberedelsen, och nar den nekar vill man veta VILKEN hast och
		VILKET steg som sa nej — inte bara att det blev nej. ]]
	local s0 = state[player]
	local id = s0 and s0.hastId or nil
	local ok, varfor, arg = ridaNuInre(player)
	if ok then
		print(("[Led] %s · %s · RidaNu"):format(
			tostring(player.Name), tostring(id or "-")))
	else
		warn(("[Led] %s · %s · RidaNu NEKAD: %s"):format(
			tostring(player.Name), tostring(id or "-"), tostring(varfor)))
	end
	return ok, varfor, arg
end

--[[ Hästens dagsform vid uppsittning, 0–1.

	BELÖNINGEN FÖR OMSORG. Den som gjort skötseln själv får en märkbart
	harmoniskare häst; den som valt "Rida nu" får en fullt fungerande ritt.
	Skillnaden ska läsa som "jag tog extra bra hand om henne" — aldrig som
	"jag hoppade över, därför fungerar hon dåligt".

	Därför ligger golvet på kanonens egen standarddagsform: `ridaNu` ger
	exakt den häst spelet annars alltid gett. Egen skötsel lyfter därifrån
	och uppåt. Ingen väg leder NEDÅT.

	STORLEKEN ÄR MEDVETET LITEN. Första versionen gav +0,25 dagsform, vilket
	lyfte startenergin 0,835 → 0,967 — omkring 16 %. Det är nog för att
	göra frivillig skötsel till en optimeringsplikt: den som vill ha den
	bästa hästen MÅSTE då borsta. Precis det den här principen finns för
	att undvika.

	+0,06 ger ungefär tre procent mer uthållighet. Det räcker för att
	kännas — hon håller gångarten en aning längre — utan att någon behöver
	räkna på det. Den stora belöningen ska ligga i hur hon ÄR: lugnare,
	mjukare i svaret, positivare kroppsspråk. De kanalerna hör till nästa
	pass; den här raden ska inte växa för att kompensera. ]]
local DAGSFORM_BONUS = 0.06

function GameplayService.dagsformFor(player: Player): number
	local bas = RidKanon.START.DAGSFORM
	local s = state[player]
	if not s then return bas end
	local andel = Preparation.egenAndel(s)
	return math.clamp(bas + DAGSFORM_BONUS * andel, 0, 1)
end

--[[ Sadelkammarens val: vilken hästs sadel och träns spelaren tagit med
	sig. Webbens `visaSadelkammare` gör samma val, och samma fel går att
	göra — utrustningen prövas mot hästen när den sätts på.

	── PRÖVNINGEN ÄR SKILD FRÅN SKRIVNINGEN (#169) ──────────────────────

	Sadel och träns hämtas TILLSAMMANS, och ett par är inte ett par om
	halva bytet gick igenom. Förut skrevs de av två oberoende anrop: det
	första committade, det andra kunde neka, och spelaren stod med den nya
	hästens sadel och den gamlas träns.

	Mätt på `a096d68` genom modulens egen söm, med en mottagare som nekar
	tränset — alltså precis det Equipment Gate är på väg att införa:

	    FÖRE:  sadel=gammal_hast  trans=gammal_hast
	    tag() returnerade: false
	    EFTER: sadel=ny_hast      trans=gammal_hast   <- blandat par

	Därför: `prova` svarar utan att röra något, `skriv` rör utan att fråga.
	Ett par prövas HELT innan något skrivs. Skrivningen är rena
	tabellskrivningar och kan inte falla halvvägs, så rollback behövs inte —
	men ordningen gör att den inte heller kan behövas. Växer prövningen
	(reservation, fas, avstånd, lagersaldo) ärver paret det automatiskt. ]]
local function provaVal(_player: Player, typ: string, hastId: string?): (boolean, string?)
	if typ ~= "sadel" and typ ~= "trans" then
		return false, "tack.okand_utrustning"
	end
	--[[ ID:t prövas, inte bara dess TYP (#169). En tom sträng har rätt typ
		och betyder ingenting; `moment` hade sedan läst den som en hämtad
		utrustning och skickat den vidare till `TackService.satPa`, där den
		aldrig kan matcha en häst. Nejet hör hemma där valet görs. ]]
	if typeof(hastId) ~= "string" or hastId == "" then
		return false, "tack.okand_utrustning"
	end
	return true
end

local function skrivVal(player: Player, typ: string, hastId: string?)
	valdUtrustning[player] = valdUtrustning[player] or {}
	valdUtrustning[player][typ] = hastId
end

function GameplayService.valjUtrustning(player: Player, typ: string, hastId: string?): (boolean, string?)
	local ok, skal = provaVal(player, typ, hastId)
	if not ok then return false, skal end
	skrivVal(player, typ, hastId)
	return true
end

--[[ Hela hämtningen: sadel OCH träns, eller ingetdera. Den väg
	`TackForradService` tar, och den väg `ridaNu` tar — samma garanti på
	båda ställena, för det är samma par. ]]
function GameplayService.valjPar(player: Player, hastId: string?): (boolean, string?)
	local delar = { "sadel", "trans" }
	for _, typ in ipairs(delar) do
		local ok, skal = provaVal(player, typ, hastId)
		if not ok then return false, skal end
	end
	for _, typ in ipairs(delar) do
		skrivVal(player, typ, hastId)
	end
	--[[ ── DET SPELAREN TOG SKA SYNAS (#182) ──────────────────────────

		Hämtningen var fram till nu enbart två tabellskrivningar: inget i
		världen, inget i HUD:en. Human-QA tryckte på boxfrontens prompt
		och kunde inte se att något hänt alls.

		Två rader, båda nödvändiga och båda på ETT ställe:

		  · den fysiska delen läggs i spelarens händer,
		  · vyn går ut, så att den beständiga statusraden tänds i samma
		    andetag.

		`skicka` anropas här och inte hos anroparen av samma skäl som
		atomiciteten flyttades hit i #169: boxfronten och «Rida nu» är
		två anropare av samma hämtning, och en garanti som ligger hos
		anroparen finns bara så länge alla kommer ihåg den. ]]
	for _, typ in ipairs(delar) do
		TackService.satBuren(player, typ, hastId)
	end
	skicka(player)
	return true
end

--[[ ══ EN UTRUSTNING I TAGET, MED AGARE (#235 FAS 1) ═════════════════

	FAS 1 ar «SADEL: WORLD -> HELD», och den overgangen ska ga att
	falsifiera ensam. `valjPar` ovan star kvar for `ridaNu`, dar stallet
	gor i ordning hela hasten; boxfronten gar hit.

	TRE SAKER SOM `valjPar` INTE GJORDE:

	  1. EN typ. Tranget rors inte.
	  2. AGARSKAP. Tva spelare far inte bara samma sadel. Registret nedan
	     ar serverns, och nyckeln ar hastens id plus typen — alltsa den
	     fysiska sadeln pa den fronten, inte «en sadel».
	  3. Utrustningen LAMNAR fronten. Annars star den bade i handerna och
	     pa kroken, och spelaren ser tva.

	Ingen `Tool`, ingen `Backpack`, ingen klientauktoritativ state: den
	burna delen svetsas server-side i `TackRigg.byggBuren`, och det enda
	klienten far ar resultatet. ]]
local burenAv: { [string]: Player } = {}

local function agarnyckel(typ: string, hastId: string): string
	return hastId .. "/" .. typ
end

--[[ Slapper allt den har spelaren bar — annars later registret en sadel
	vara tagen for alltid av nagon som inte finns kvar.

	TVA ANROPARE, OCH BARA TVA: `lamnar` (hela sessionen) och
	`karaktarBorta` (kroppen dog eller byttes). Raden har pastod tidigare
	en tredje, «nar passet tar slut», och den var aldrig kopplad. Ett
	pastaende om en livscykelvag som inte finns ar varre an inget: nasta
	lasare litar pa den. ]]
function GameplayService.slappBuret(player: Player)
	for nyckel, agare in pairs(burenAv) do
		if agare == player then
			burenAv[nyckel] = nil
			local hastId, typ = nyckel:match("^(.+)/([^/]+)$")
			if hastId and typ then
				pcall(function() TackForradService.satSynlig(hastId, typ, true) end)
			end
		end
	end
	pcall(function() TackService.slappAllBuren(player) end)
end

--[[ AR HON KVAR? En `Player` som lamnat har `Parent == nil`, men det ar
	inte hela sanningen: `PlayerRemoving` hinner fyra innan foraldern
	nollas, och en bank har inga foraldrar alls. `Players:GetPlayers()` ar
	tjanstens egen lista och det som faktiskt avgor om agaren finns kvar.
	Utan det hade en levande agare sett ut som en gengangare, och den
	andra spelaren hade fatt ta sadeln ur handerna pa henne. ]]
local function kvarInne(p: Player): boolean
	if p.Parent ~= nil then return true end
	for _, q in ipairs(Players:GetPlayers()) do
		if q == p then return true end
	end
	return false
end

--[[ Vem bar den har fronten utrustning? Provets fonster in. ]]
function GameplayService.barasAv(typ: string, hastId: string): Player?
	return burenAv[agarnyckel(typ, hastId)]
end

function GameplayService.valjEn(player: Player, hastId: string?, typ: string?): (boolean, string?)
	local t = typ or "sadel"
	local ok, skal = provaVal(player, t, hastId)
	if not ok then return false, skal end
	local id = hastId :: string

	--[[ NARHETEN ar serverns, inte promptens. En prompt har sin egen
		rackvidd, men den ar klientens presentation — servern maste sjalv
		kunna neka en hamtning fran andra sidan garden. ]]
	local karaktar = player.Character
	local rot = karaktar and karaktar:FindFirstChild("HumanoidRootPart")
	if not (rot and rot:IsA("BasePart")) then return false, "tack.ingen_karaktar" end

	--[[ FAIL-CLOSED (#235 review). Forut lod provet `if plats and ...`:
		fanns ingen front, eller ingen `PrimaryPart` att mata fran, HOPPADE
		servern over avstandsprovet och slappte igenom hamtningen. En
		auktoritativ validering som tiger nar den inte kan mata ar ingen
		validering. Saknas platsen ar svaret nej. ]]
	local modell = TackForradService.forHast(id)
	local plats = modell and modell.PrimaryPart
	if not (plats and plats:IsA("BasePart")) then return false, "tack.ingen_front" end
	if (rot.Position - plats.Position).Magnitude > STEG_RACKVIDD then
		return false, "spel.for_langt"
	end

	--[[ AGARSKAPET. Bar hon den redan ar svaret ja utan att nagot andras
		— ett andra tryck far inte bygga en andra sadel. ]]
	local nyckel = agarnyckel(t, id)
	local agare = burenAv[nyckel]
	if agare == player then return true end
	if agare ~= nil and kvarInne(agare) then return false, "tack.redan_tagen" end

	--[[ EN SADEL I TAGET (#235 review 2). `TackService.satBuren` ar
		uttryckligen byggd for att BYTA ut en buren sadel mot en annan
		hasts. Gjorde vi det har lag den FORSTA hastens agarpost kvar och
		hennes front forblev slackt — hennes sadel last for alla, i
		handerna pa ingen.

		FAS 1 loser det genom att inte tillata bytet. Ingen swap-logik,
		inget att rulla tillbaka: nejet kommer INNAN nagot andras, och
		spelaren far lamna tillbaka sadeln hon bar forst. ]]
	--[[ DEN MASTE FAKTISKT HANGA DAR (#235 FAS 2). Agarskapet ovan
		skyddar mot att TVA spelare bar samma sadel, men inte mot att
		den inte finns kvar att ta: nar FAS 2 flyttat sadeln till
		hastens rygg star kroken tom och agarposten ar slappt — och
		da slapptes hamtningen igenom och praglade en ANDRA sadel ur
		tomma luften. Det fann FAS 2:s eget prov.

		Grinden ar medvetet smal: den galler bara nar gruppen FINNS
		och sager att delen inte hanger dar. Saknas hela gruppen ar
		det ett annat fel, och det bars av `tack.front_slapper_inte`
		nere i transaktionen. ]]
	if TackForradService.harPlats(id, t)
		and TackForradService.paFronten(id, t) == false then
		return false, "tack.inte_pa_fronten"
	end

	local barNu = TackService.barBuren(player, t)
	if barNu ~= nil and barNu ~= id then return false, "tack.bar_redan_annan" end

	--[[ ── EN TRANSAKTION, I DEN HAR ORDNINGEN ────────────────────────

		validera -> bygg den burna sadeln -> slack den pa fronten -> committa

		Forut skrevs valet FORST och den fysiska delen byggdes sedan. Gick
		bygget fel stod `valdUtrustning` kvar och pastod att spelaren hade
		sadeln hon aldrig fick — stale state som resten av spelet sedan
		lasar som sanning. Och frontens slackning ignorerade sitt eget
		svar, sa hon kunde sta i HELD med sadeln kvar synlig pa kroken.

		Nu andras ingenting bestaende forran badadera lyckats, och det som
		hann bli gjort rullas tillbaka nar nagot faller. ]]
	local bar_redan = barNu == id
	if not TackService.satBuren(player, t, id) then
		return false, "tack.kunde_inte_byggas"
	end

	--[[ `satSynlig` ar allt-eller-inget: den nekar pa en saknad grupp INNAN
		den rort nagot, sa ett falskt svar betyder att fronten star orord. ]]
	if not TackForradService.satSynlig(id, t, false) then
		--[[ ROLLBACK. Bara det VI byggde tas bort: bar hon redan delen nar
			vi kom lamnar vi den, for da har vi inte skapat den och ska
			inte heller riva den. Det speglar `satBuren`, som returnerar
			true utan att bygga nagot nar id:t ar detsamma.

			`bar_redan` AR I DAG ONABAR. Min egen falsifiering visade det:
			mutationen `bar_redan = false` kom ut GRON. Vagen dit kraver
			att hon fysiskt bar just den har sadeln utan att sta i
			registret, och bade `slappBuret` och `glom` rensar bada
			halvorna tillsammans — plus att grinden ovan nu nekar all
			annan buren sadel.

			Grenen star kvar anda, for den ar parad med `satBuren`s egen
			gren och blir levande i det ogonblick FAS 2 tillater ett byte.
			Att ta bort den nu vore att flytta felet till den som bygger
			bytet. Den redovisas som en kand svag mutation i stallet for
			att gommas. ]]
		if not bar_redan then
			pcall(function() TackService.slappBuren(player, t) end)
		end
		return false, "tack.front_slapper_inte"
	end

	--[[ COMMIT. Forst nu finns det en fysisk sadel i handerna och en tom
		krok pa fronten — alltsa forst nu ar `WORLD -> HELD` sant. ]]
	skrivVal(player, t, id)
	burenAv[nyckel] = player
	skicka(player)
	return true
end

function GameplayService.valdFor(player: Player): { [string]: string }?
	return valdUtrustning[player]
end

--[[ ══ FAS 2: SADEL `HELD -> EQUIPPED` (#235) ════════════════════════

	FAS 1 lamnade spelaren med en sadel i handerna och ingen vag att lagga
	den pa hasten. Det har ar den vagen, och ingenting mer: tranget hor
	till FAS 3 och ledningen till FAS 4.

	ORDNINGEN ar densamma som i FAS 1, av samma skal:

	    validera -> lagg underlagget -> bygg sadeln -> bekrafta varlden
	              -> committa agandet

	Ingenting bestaende andras forran allt lyckats, och det som hann bli
	gjort rullas tillbaka nar nagot faller.

	VARFOR `satPa` OCH INTE EN EGEN VAG: `TackService.satPa` ar redan den
	serverauktoritativa pasattningen — den ager fel-hast, fel-sadel med
	felraknare, dubbelpasattning, ordningen, avstandet, bygget och att den
	burna delen slapps NAR delen sitter. Att skriva en andra vag bredvid
	den hade gett tva sanningar om vad "sadlad" betyder, och det ar precis
	det `TackService` finns for att omojliggora.

	DET HAR LAGRET TILLFOR TRE SAKER som `satPa` inte kan veta:

	  1. att utrustningens identitet lases ur det spelaren FYSISKT BAR,
	     inte ur `valdUtrustning`. Registret ar en avsikt; handerna ar ett
	     faktum, och FAS 2:s hela poang ar att flytta ett fysiskt foremal.
	  2. UNDERLAGGET. Kanon lagger det under sadeln, och `satPa` nekar
	     darfor sadeln utan det. Det hanger i samma upphangning och hamtas
	     med sadeln — alltsa hor det till samma handling. Utan det kunde
	     «Sadla» aldrig lyckas.
	  3. AGANDET. Sadeln ligger nu pa hasten, inte pa boxfronten, sa
	     agarposten ska slappas UTAN att fronten tands igen.

	INGEN FLYTT AV MODELLEN, och det ar ett medvetet avsteg fran ordens
	ordalydelse «flytta modellen till hastens SaddleAttachment». Den burna
	sadeln ar en forenklad rekvisita — ett valv och ett underlagg man bar
	framfor magen — medan den pasatta ar sadel, gjord och stigbyglar pa en
	rygg. Att flytta den forsta till ryggen hade gett fel form pa hasten.
	`TackRigg` bygger darfor den pasatta delen och river den burna, vilket
	ger SAMMA observerbara garantier: ingen dubblett hos spelaren, ingen pa
	boxfronten, en fysisk del svetsad i hastriggen server-side. Avsteget ar
	redovisat i rapporten, inte gomt. ]]

--[[ Slapper agandet UTAN att hanga tillbaka nagot pa fronten.

	Skillnaden mot `slappBuret` ar hela poangen: dar slapper spelaren
	utrustningen och den ska tillbaka pa kroken. Har har den flyttat till
	HASTEN, och en front som tandes igen hade visat en andra sadel
	hangande bredvid den som redan ligger pa ryggen. ]]
function GameplayService.slappAgande(typ: string, hastId: string)
	burenAv[agarnyckel(typ, hastId)] = nil
end

function GameplayService.sadla(player: Player, modell: Model?): (boolean, string?)
	--[[ HASTEN. Klientens modell ar en fraga, inte ett pastaende: allt
		nedan provas mot varlden och mot vad spelaren faktiskt bar. ]]
	if typeof(modell) ~= "Instance" and type(modell) ~= "table" then
		return false, "tack.ingen_hast"
	end
	local m = modell :: Model
	if not (m and (m :: any).IsA and m:IsA("Model")) then
		return false, "tack.ingen_hast"
	end
	local hastId = tostring(m:GetAttribute("HorseId") or "")
	if hastId == "" then return false, "tack.ingen_hast" end

	--[[ HANDERNA AR FACIT. Bar hon ingen sadel finns ingenting att sadla
		med, hur mycket `valdUtrustning` an pastar. ]]
	local bar = TackService.barBuren(player, "sadel")
	if bar == nil then return false, "tack.bar_ingen_sadel" end

	--[[ HASTENS EGET TILLSTAND (#235 FAS 2 review). Ordern kraver att
		SERVERN validerar horse-state, och att klienten slacker knappen
		i vissa lagen ar presentation — inte en regel.

		Sanningen hamtas dar den redan bor: `LedService` vet vem som
		leder henne, `HorseService` vem som sitter pa henne. Ingen ny
		boolean, ingen parallell tabell — tva sanningar om var hasten ar
		vore precis det fel hela fasindelningen finns for att undvika.

		OCH FORE ALLT FYSISKT. Nejet ligger over bade underlagget och
		bygget, sa en ledd hast kan inte fa ett halvt ekipage pa sig.

		Regeln ar verklig och inte teknisk: en hast som gar i kopplet
		star inte still att sadla, och pa en uppsutten sitter redan
		nagon. ]]
	if LedService.ledsAv(m) ~= nil then return false, "tack.leds_nu" end
	local session = HorseService.sessionFor(m)
	if session ~= nil and session.rider ~= nil then
		return false, "tack.rids_nu"
	end

	--[[ FEL SADEL SKA GA ATT GORA. Att kunna ta fel sadel ar hela den
		pedagogiska poangen — webbens sadelkammare gor likadant — och
		`satPa` bar bade nejet och felraknaren. Anropet nedan ror inget
		annat: det returnerar innan nagon del byggs. ]]
	if bar ~= hastId then
		return TackService.satPa(player, m, "sadel", bar, m)
	end

	--[[ DUBBEL PASATTNING agas av `satPa`, inte av ett andra prov har.
		Har lag forut en egen `sadlad`-grind, och min egen falsifiering
		visade att den var overflodig: mutationen som tog bort den kom
		ut GRON, for `satPa` nekar redan med samma skal via
		`TackRigg.hittaDel`. Tva sanningar om vad «sadlad» betyder ar
		precis det `TackService` finns for att omojliggora, sa den
		redundanta halvan ar borta. Provet mater fortfarande nejet. ]]

	--[[ UNDERLAGGET FORST, och bara om det inte redan ligger dar. Det
		slapper INTE den burna sadeln — `BARBARA` sager att bara sadel och
		trans bars — sa ett fel harifran lamnar handerna ororda. ]]
	local la_underlagg = false
	if not TackService.harTack(m, "underlagg") then
		local okU, skalU = TackService.satPa(player, m, "underlagg", bar, m)
		if not okU then return false, skalU end
		la_underlagg = true
	end

	local function angraUnderlagget()
		if la_underlagg then
			pcall(function() TackRigg.taAv(m, "underlagg") end)
		end
	end

	local okS, skalS = TackService.satPa(player, m, "sadel", bar, m)
	if not okS then
		angraUnderlagget()
		return false, skalS
	end

	--[[ OCH VARLDEN AR SANNINGEN. Samma regel som momentkvittensen och
		uppsittningsgrinden laser: `satPa` svarar ja nar bygget gick fram,
		men foll delen bort daremellan ar hon inte sadlad. Da ska sadeln
		tillbaka i handerna — inte forsvinna.

		GRENEN AR I DAG ONABAR, och min egen falsifiering visade det:
		mutationen som tog bort hela provet kom ut GRON. Vagen dit kraver
		att `satPa` svarar ja medan delen INTE finns, och det intraffar
		bara om nagot river henne mellan tva rader.

		Den star kvar anda, av samma skal som momentflodets egen rad nagra
		hundra rader upp — den ar precedensen, inte ett nytt pahitt. Ett
		«sadlad» som inte gar att se i varlden ar precis den motsagelse
		`TackService` finns for att omojliggora, och nasta fas flyttar fler
		delar mellan hander och rygg. Redovisad som kand svag mutation i
		stallet for att raknas bort. ]]
	if not TackService.harTack(m, "sadel") then
		pcall(function() TackRigg.taAv(m, "sadel") end)
		angraUnderlagget()
		pcall(function() TackService.satBuren(player, "sadel", hastId) end)
		return false, "tack.kunde_inte_byggas"
	end

	--[[ COMMIT. Forst nu ligger sadeln fysiskt pa hasten och ar borta ur
		handerna — alltsa forst nu ar `HELD -> EQUIPPED` sant. ]]
	GameplayService.slappAgande("sadel", hastId)
	skicka(player)
	return true, "tack.pa_plats"
end

--[[ ══ FAS 3: TRANS `HELD -> EQUIPPED` (#235) ════════════════════════

	SAMMA state-machine som sadeln, mot huvudet i stallet for ryggen.
	Ordern sager uttryckligen «ingen separat speciallosning», och det ar
	darfor den har funktionen ar sa kort: allt som ar GEMENSAMT bor redan
	i `TackService.satPa`, och det enda som skiljer ar typen.

	TVA SAKER SKILJER TRANSET FRAN SADELN, och bada ar kanon:

	  1. ORDNINGEN. Transet kommer SIST. `satPa` nekar det pa en osadlad
	     hast med `tack.sadeln_forst`, och den regeln ar inte teknisk —
	     man sadlar forst och transar sedan, for sa gor man.
	  2. TYGLARNA foljer med. De sitter i bettet och ar inget eget moment
	     i kanon; `satPa` bygger och river dem med transet, och rullar
	     tillbaka bada om nagon av dem faller.

	Inget underlagg har, av samma skal: det hor till sadeln. ]]
function GameplayService.transa(player: Player, modell: Model?): (boolean, string?)
	if typeof(modell) ~= "Instance" and type(modell) ~= "table" then
		return false, "tack.ingen_hast"
	end
	local m = modell :: Model
	if not (m and (m :: any).IsA and m:IsA("Model")) then
		return false, "tack.ingen_hast"
	end
	local hastId = tostring(m:GetAttribute("HorseId") or "")
	if hastId == "" then return false, "tack.ingen_hast" end

	local bar = TackService.barBuren(player, "trans")
	if bar == nil then return false, "tack.bar_inget_trans" end

	--[[ HASTENS EGET TILLSTAND, samma grind som sadeln fick i reviewen av
		`e08515f`. En hast som gar i kopplet star inte still att transa —
		och pa en uppsutten sitter redan nagon. ]]
	if LedService.ledsAv(m) ~= nil then return false, "tack.leds_nu" end
	local session = HorseService.sessionFor(m)
	if session ~= nil and session.rider ~= nil then
		return false, "tack.rids_nu"
	end

	--[[ FEL TRANS SKA GA ATT GORA, precis som fel sadel. `satPa` bar bade
		nejet (`tack.fel_trans`) och felraknaren, och returnerar innan
		nagon del byggs. ]]
	if bar ~= hastId then
		return TackService.satPa(player, m, "trans", bar, m)
	end

	local okT, skalT = TackService.satPa(player, m, "trans", bar, m)
	if not okT then return false, skalT end

	--[[ OCH VARLDEN AR SANNINGEN. Samma ONABARA forsvarsrad som sadelns
		(se noten dar), och min falsifiering gav samma svar: mutationen
		som tog bort tyglarna ur provet kom ut GRON.

		Skalet ar att `satPa` redan river BADA om tyglarna faller — det
		ar bevisat, mutation T7 ar rod. Raden har ar alltsa ett andra
		lager over ett forsta som haller.

		Den star kvar av samma skal som sadelns: momentflodet har samma
		rad, och ett «transad» som inte gar att se i varlden ar precis den
		motsagelse `TackService` finns for att omojliggora. Att den
		dessutom kraver TYGLARNA ar inte kosmetik — `leda` forutsatter dem
		(«med tyglarna over halsen»), och ett trans utan tyglar ar inte
		det tillstand spelet pastar. Redovisad som kand svag mutation. ]]
	if not (TackService.harTack(m, "trans") and TackService.harTack(m, "tygel")) then
		pcall(function() TackRigg.taAv(m, "tygel") end)
		pcall(function() TackRigg.taAv(m, "trans") end)
		pcall(function() TackService.satBuren(player, "trans", hastId) end)
		return false, "tack.kunde_inte_byggas"
	end

	GameplayService.slappAgande("trans", hastId)
	skicka(player)
	return true, "tack.pa_plats"
end

--[[ Svaret på ett fynd. Rätt svar stoppar arbetet, sparar hästens vila och
	räknar passet — spelaren gjorde precis det momentet lär ut, och ska inte
	förlora dagen på det. ]]
function GameplayService.svara(player: Player, svarId: string): (boolean, string?)
	if typeof(svarId) ~= "string" then
		return false, "spel.ogiltigt_svar"
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

function GameplayService.eftervard(player: Player, momentId: string): (boolean, string?, string?)
	if typeof(momentId) ~= "string" then
		return false, "spel.ogiltigt_steg"
	end
	local p = passState[player]
	if not p then
		return false, "spel.inget_pass"
	end
	--[[ Eftervården kräver samma närvaro som skötseln: man tar av sadeln
		vid hästen, inte från läktaren. ]]
	local naravaro_ok, skal = narvaro(player)
	if not naravaro_ok then
		return false, skal
	end

	--[[ ── UTRUSTNINGEN TAS AV PÅ RIKTIGT (#211) ──────────────────────

		Eftervårdens moment satte förut `state.gjorda` och ingenting
		annat. Det är samma fel som blockerare 5 på förberedelsens sida,
		fast åt andra hållet: `TackService.taAv` och `taAvAllt` fanns men
		ingen levande väg anropade dem, så en avslutad ritt lämnade sadel,
		underlägg, träns och tyglar kvar på hästen för alltid medan
		passvyn sa "Ta av sadeln  ✓".

		Kedjan är därför densamma som i `moment` ovan, och av samma skäl:

		  1. REGELN FRÅGAS FÖRST, utan att något ändras. `farUtfora` är
		     `utfor` utan avbockningen — se noten i `Pass`. Lyftes sadeln
		     av och regeln sedan nekade momentet stod hon avsadlad med
		     momentet ogjort.
		  2. DEN FYSISKA DELEN TAS AV, ur den bundna modellen. `momentId`
		     kommer från klienten men slås upp i kanon; VILKEN häst och
		     VILKEN del det gäller väljer servern. Ingen klient kan peka
		     ut en annan hästs utrustning.
		  3. FÖRST DÄREFTER bockas momentet av.

		`tack.inget_pa` är inget fel här. Momentets mening är att
		utrustningen ska vara AV när det är gjort, och ligger den redan av
		— en omsändning, en del som revs ur världen, en häst som aldrig
		blev sadlad — är världen redan sann. Att neka då hade låst
		eftervården, och med den passet: `Pass.farAvsluta` är
		fail-closed. ]]
	local far, farSkal, farArg = Pass.farUtfora(p, momentId)
	if not far then
		--[[ VYN SKICKAS ÄVEN NÄR SVARET ÄR NEJ. Så gjorde raden förut —
			`skickaPass` låg efter `Pass.utfor` och kördes på båda utfallen
			— och en klient som drivit isär rättas då av samma tryck som
			gav henne nejet. Att låta det tidiga nejet smita förbi hade
			varit en regression, inte en förenkling. ]]
		skickaPass(player)
		return false, farSkal, farArg
	end
	local delar = TackService.eftervardsDelar(momentId)
	if delar then
		local modell = bunden[player]
		if not modell then return false, "spel.ingen_hast" end
		for _, typ in ipairs(delar) do
			local okAv, skalAv = TackService.taAv(player, modell, typ)
			if not okAv and skalAv ~= "tack.inget_pa" then
				skickaPass(player)
				return false, skalAv
			end
		end
	end

	--[[ TREDJE VÄRDET FÖLJER MED. `pass.fel_tur` bär momentets namn som
		argument, och raden kastade bort det — spelaren fick se ett
		bokstavligt "%s" i stället för vilket moment som stod på tur.
		Samma rättelse som gjordes i `HorseService.tryMount`. ]]
	local ok, avslag, arg = Pass.utfor(p, momentId)
	if ok and Pass.farAvsluta(p) then
		GameplayService.avslutaPass(player)
	end
	skickaPass(player)
	return ok, avslag, arg
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
		return false, "spel.inget_pass"
	end
	local ok, skal = Pass.farAvsluta(p)
	if not ok then
		return false, skal
	end

	--[[ ── DAGEN SLUTAR MED EN TOM HÄST (#211) ────────────────────────

		Svepet är inte ett hängsle till eftervårdens moment — de har redan
		tagit av sadeln, underlägget och tränset, annars står vi inte här:
		`Pass.farAvsluta` är fail-closed och släpper bara igenom ett pass
		där varje moment är gjort. Det städar RESTER, och `taAvAllt` finns
		för just det, med sitt eget skäl skrivet i `TackService`:

		  `TackRigg.taAv` river den BÄRANDE delen och det som är svetsat i
		  henne. Har den bärande delen försvunnit på något annat sätt — en
		  rigg som byttes, ett halvt bygge som städades, en del som revs
		  ur världen — hittar den ingenting, och sadelns valv, gjord och
		  stigbyglar blir kvar hängande på en häst som spelet påstår är
		  avsadlad.

		Mätt i `integration.spec` punkt 12b: rivs sadeldelen mellan två
		moment går dagen att räkna färdigt, men hästen bar rester tills
		svepet lades här.

		INGEN RYTTARE UPPE. Ett stoppat pass kan nå hit från ett annat
		läge än eftervården (`Pass.vidValfardsstopp` sätter KLART direkt),
		och att lyfta av en sadel under en ryttare vore precis den
		motsägelse mellan tillstånd och värld som `TackService` finns för
		att omöjliggöra. Villkoret är en spärr, inte en mätpunkt: ingen
		känd väg når hit med någon i sadeln. ]]
	local modell = bunden[player]
	if modell and HorseService.horseOf(player) == nil then
		TackService.taAvAllt(modell)
	end

	local save = SparService.save(player)
	if not save then
		return false, "spel.ingen_sparning"
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
--[[ ── FIRST RIDE-KROKEN (#263 Gate 2A) ────────────────────────────

	`ForstaRitten` registrerar sig har vid start. Kroken svarar pa EN
	fraga: ar det har spelarens allra forsta ritt, last ur bestandig
	sparning? Den tar inget klientargument och kan inte satas av en
	klient. ]]
local forstaRitten: ((Player, Model) -> boolean)? = nil

function GameplayService.satForstaRitten(fn: ((Player, Model) -> boolean)?)
	forstaRitten = fn
end

--[[ Slapper First Ride igenom det har nejet? Se den langa noten inne i
	`farSittaUpp` for vad som far ersattas och vad som aldrig far det. ]]
local function forstaRittenSlapper(player: Player, modell: Model, s: any,
	skal: string?): boolean
	if forstaRitten == nil then return false end
	--[[ BARA CHECKLISTAN. `pass.aterstar` ar det enda skal
		`provaUppsittning` ger for en ogjord fas; varje annat nej ar
		identitet eller valfard och star kvar. ]]
	if skal ~= "pass.aterstar" then return false end
	--[[ VALFARDSSTOPPET, uttryckligen och inte underforstatt. Skulle
		`provaUppsittning` nagon gang bytta ordning pa sina nej ska den
		har raden halla anda. ]]
	if s ~= nil and s.stoppad then return false end
	local ok, svar = pcall(forstaRitten :: any, player, modell)
	return ok and svar == true
end

--[[ Provkrok: satter valfardsstoppet i spelarens EGNA tillstand, samma
	falt som visitationens fynd skriver. Den finns for att ett prov ska
	kunna mata att First Ride-grenen INTE kringgar stoppet — utan den
	kom mutationen som tog bort den kontrollen ut gron, och da matte
	provet inte det villkor som skyddar hasten. ]]
function GameplayService._stoppaForProv(player: Player, text: string)
	local s = state[player]
	if s then (s :: any).stoppad = text end
end

function GameplayService.farSittaUpp(player: Player, modell: Model): (boolean, string?, string?)
	local s = state[player]
	--[[ Krav 6 och 7 avgörs av regeln, inte här. Kvar i tjänsten är bara
		det instansnära: att modellen dessutom är den vi FAKTISKT bundit,
		så att två modeller med samma id aldrig kan bli utbytbara. ]]
	--[[ Argumentet följer med: välfärdsstoppets skäl är en ram (nyckel) och
		fyndets mening (argument). Se noten i `HorseService.tryMount`. ]]
	local ok, skal, arg = Preparation.provaModell(s, modell:GetAttribute("HorseId"))
	if not ok then
		--[[ ══ FIRST RIDE (#263 Gate 2A) ═══════════════════════════════

			Den ENDA vägen upp i sadeln som inte går genom en avbockad
			checklista, och den är avsiktligt smal.

			Vad den ersätter: `pass.aterstar` — att spelaren själv inte
			har utfört skötselmomenten. Ingenting annat.

			Vad den INTE ersätter, och varför:

			  `forb.lararen_tar_over` — välfärdsstoppet. En häst med ett
			  fynd ska ingen sitta upp på, aldrig, oavsett hur ny
			  ryttaren är. Prövas uttryckligen nedan och inte bara genom
			  att skälet råkar vara ett annat.

			  `spel.inte_din_hast`, `forb.inte_din_hast`,
			  `spel.ingen_hast` — identiteten. En ny spelare får sin
			  tilldelade häst, inte vilken som helst.

			  `TackService.ridklar` längst ned — det FYSISKA. Den raden
			  körs oförändrat, så hästen måste faktiskt bära sadel och
			  träns. Kanon är entydig: hästen ska alltid vara korrekt
			  förberedd när ritten börjar, oavsett vem som gjorde
			  arbetet, och spelet får aldrig lära ut fel hästhantering
			  för att spara tid.

			Kroken ägs av `ForstaRitten` och svarar ur beständig
			sparning, inte ur ett klientargument. Saknas kroken — ingen
			`ForstaRitten.start()` — är grenen stängd. ]]
		if not forstaRittenSlapper(player, modell, s, skal) then
			return false, skal, arg
		end
	end
	if bunden[player] ~= modell then
		return false, "spel.inte_din_hast"
	end
	--[[ Passet får bara räknas en gång, och eftervården får inte
		nollställas av ett andra `tryMount`. REGELN ligger i `Pass` och
		inte här: tjänsten hade en egen kopia (`p.lage ~= FORE`), och den
		kopian låste ute en spelare som dött mitt i ritten — se
		`Pass.farSittaUpp`. Nu finns villkoret på ett ställe. ]]
	local p = passState[player]
	if p then
		local far, skalPass = Pass.farSittaUpp(p)
		if not far then
			return false, skalPass or "spel.redan_ridit"
		end
	end
	--[[ ── UPPSITTNINGEN PRÖVAS MOT DET FYSISKA ───────────────────────

		`Preparation.provaModell` ovan prövar att momenten är gjorda. Den
		här raden prövar att utrustningen FINNS PÅ HÄSTEN, läst ur
		modellen och inte ur ett tillstånd. Skulle de två någonsin säga
		olika — en spoofad kvittering, ett halvt bygge — vinner världen. ]]
	local klar, tackSkal = TackService.ridklar(modell)
	if not klar then
		return false, tackSkal
	end
	return true, nil
end

--[[ ── Livscykel ───────────────────────────────────────────────────── ]]

--[[ ── DEN SOM LAMNAR (#252 DEL C) ───────────────────────

	Handlaren var en lokal `glom`, och `Players.PlayerRemoving` var enda
	vagen in i den. Runtime-grinden maste kunna kora EXAKT den har
	vagen — `lamnar -> slappBuret -> satSynlig` — utan en riktig
	`Player`, och en signal gar inte att fyra fran koden.

	Alternativet hade varit att provet anropade `slappBuret` sjalvt.
	Det hade varit en ANDRA sanning om vad «spelaren lamnade» betyder,
	och da mater grinden till slut sig sjalv. Handlaren far darfor ett
	namn; `PlayerRemoving` kopplar samma funktion som forut. ]]
--[[ ══ KARAKTAREN FORSVINNER — BARA TACKET, INTE PASSET ═════════

	Robustness Slice C.

	Den burna sadeln är en fysisk del under KARAKTAREN. Dor hon, eller
	byts kroppen vid en respawn, forsvinner delen med den — men
	`burenAv` stod kvar och pekade pa spelaren. Sadeln var da reserverad
	av nagon som inte hade den, och ingen annan kunde ta den forran
	agaren sjalv rorde forradet igen eller kopplade ner helt.

	`valdUtrustning` foljer med av samma skal. Den ar en AVSIKT — «jag
	har hamtat Jacks sadel» — och den avsikten dog med handerna. Lamnas
	den kvar pastar forberedelsevyn att spelaren barer nagot som inte
	finns, och resten av spelet laser den pastaenden som sanning.

	PASSET ROR VI INTE. `state`, `passState`, `bunden` och avbockade
	skotselmoment ska overleva en respawn exakt som forut — det ar
	testat sedan tidigare (`integration.spec`: «skotseln raknas
	fortfarande som gjord efter respawnen»). Den har vagen ar tack, och
	ingenting annat.

	IDEMPOTENT. `slappBuret` itererar och rensar; att kora den tva
	ganger, eller efter `lamnar`, gor ingenting mer. ]]
function GameplayService.karaktarBorta(player: Player)
	GameplayService.slappBuret(player)
	valdUtrustning[player] = nil
	--[[ Och vyn till den klient som fortfarande finns kvar — en
	     respawnande spelare ar inte borta, hon har bara ny kropp.
	     `pcall`: ett fel i presentationen far inte hindra stadningen. ]]
	pcall(function() skicka(player) end)
end

function GameplayService.lamnar(player: Player)
	--[[ #235 FAS 1: en spelare som gar far inte lamna en sadel «tagen»
		for alltid. Registret slapps och fronten far tillbaka sin
		utrustning — inga orphans, varken i state eller i varlden. ]]
	GameplayService.slappBuret(player)
	state[player] = nil
	passState[player] = nil
	bunden[player] = nil
	revision[player] = nil
	--[[ HÄMTNINGEN GLÖMS MED RESTEN (#182). Tabellen levde kvar efter att
		spelaren lämnat: en ny session på samma `Player`-objekt hade ärvt
		gårdagens sadelval, och `burenFor` hade då tänt statusraden för en
		utrustning ingen hämtat. Delarna i händerna dör med karaktären;
		valet gjorde det inte. ]]
	valdUtrustning[player] = nil
end

function GameplayService.start()
	HorseService.setMountGate(GameplayService.farSittaUpp)
	--[[ Belöningen för egen skötsel: dagsformen vid uppsittning. ]]
	HorseService.setDagsformHook(GameplayService.dagsformFor)
	--[[ EN ÄGARE I TAGET (Robustness Slice A). Speglingen av
	     `LedService.satRidenHake` några rader ned: den vägen stängdes
	     redan, den här står öppen. `ledsAv` är `LedService`s egen
	     sanning — hästsystemet får fråga, inte föra egen bok. ]]
	HorseService.setLedareHook(LedService.ledsAv)
	Net.get("RidaNu").OnServerInvoke = Skopa.grind("RidaNu", function(player)
		return GameplayService.ridaNu(player)
	end)

	--[[ #264 GAIT_READABILITY_AND_UGNETA: språkflaggan. Bara "sv" eller
		"en" tas emot, och bara spelarens EGET attribut skrivs. ]]
	Net.get("SprakVal").OnServerInvoke = Skopa.grind("SprakVal", function(player, val)
		return GameplayService.sprakVal(player, val)
	end)

	--[[ #235 FAS 2. Samma monster som `RidaNu`: klienten skickar en
		avsikt, servern svarar med hela sanningen. ]]
	Net.get("SadlaHast").OnServerInvoke = Skopa.grind("SadlaHast", function(player, modell)
		return GameplayService.sadla(player, modell)
	end)

	--[[ #235 FAS 3: samma monster, en annan typ. ]]
	Net.get("TransaHast").OnServerInvoke = Skopa.grind("TransaHast", function(player, modell)
		return GameplayService.transa(player, modell)
	end)

	--[[ ── LEDNINGEN (#162 blockerare 2) ──────────────────────────────

		Målzonen är RIDBANAN, inte "utanför stallet". Källan säger att
		hästen leds inomhus mellan stallet och ridhuset, och `leda`-fasens
		egen text är "Led till ridhuset" — steget är inte gjort förrän hon
		faktiskt står där.

		Rektangeln räknas ur den delade datan (ridhusets rekt plus banans
		lokala rekt) och skrivs inte av som tal här. Ändras banan i
		`src/site.js` följer zonen med. ]]
	local hus, bana
	for _, b in ipairs(Komplex.byggnader) do
		if b.id == "ridhus" then hus = b end
	end
	bana = Komplex.ridhus and Komplex.ridhus.bana
	if hus and bana then
		LedService.satMalzon({
			x = hus.rekt.x + bana.x, y = hus.rekt.y + bana.y,
			w = bana.w, h = bana.h,
		})
	else
		warn("[Led] Ridbanans rektangel saknas i datan — leda kan inte zonprövas.")
	end

	--[[ Vilken häst spelaren FÅR leda är skötselns fråga, inte
		ledningens. Kroken svarar med den bundna modellen. ]]
	--[[ #182 del 2: och VEM som sitter pa henne. `HorseService` ager
		sessionerna; `LedService` fragar genom kroken i stallet for
		att fa ett eget beroende. ]]
	--[[ #182: stalldorren hor till ledningen, inte till ett eget tryck.
		`DorrService` ager dorrarna; kroken later `LedService` be om
		att den oppnas utan att kanna till dem. ]]
	LedService.satDorrKrok(function(blad)
		return DorrService.satLage(blad, true)
	end)

	LedService.satRidenKrok(function(modell)
		local sess = HorseService.sessionFor(modell)
		return sess ~= nil and sess.rider ~= nil
	end)

	LedService.satRattHastKrok(function(player)
		return bunden[player] or GameplayService.bind(player)
	end)

	--[[ Uppsittningen och avsittningen driver passets läge. De hakas på
		`HorseService` i stället för att `GameplayService` skulle lyssna på
		remoten: allt som monterar en ryttare går genom `tryMount`, och en
		krok på fjärranropet hade missat varje annan väg in. ]]
	HorseService.lyssnaRyttare(function(player: Player, sitter: boolean)
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

	Net.get("PreparationMoment").OnServerInvoke = Skopa.grind("PreparationMoment",
		function(player, fasId, momentId)
			return GameplayService.moment(player, fasId, momentId)
		end)
	Net.get("PreparationSvar").OnServerInvoke = Skopa.grind("PreparationSvar",
		function(player, svarId)
			return GameplayService.svara(player, svarId)
		end)
	Net.get("PassMoment").OnServerInvoke = Skopa.grind("PassMoment",
		function(player, momentId)
			return GameplayService.eftervard(player, momentId)
		end)

	--[[ `PreparationStep` finns kvar i nätkontraktet men gör inget mer än
		att säga ifrån. Att ta bort den helt hade gjort att en klient från
		en äldre version tyst fick nil tillbaka och stod och väntade; nu får
		den ett begripligt nej. Fasen går inte att kvittera den vägen — det
		är hela ändringen i #161. ]]
	Net.get("PreparationStep").OnServerInvoke = Skopa.grind("PreparationStep",
		function(_player, _fasId)
			return false, "spel.gammal_klient"
		end)

	--[[ Handskakningen. Klienten anropar den FÖRST efter att den anslutit sin
		`PreparationSync`-listener, och får hela nuläget i retur. Det gör
		starttillståndet deterministiskt oavsett vem som hann först.

		Svaret bär samma revision som en spontan sync, så om en nyare sync
		hinner före svaret kastar klienten svaret i stället för att backa. ]]
	Net.get("PreparationHello").OnServerInvoke = Skopa.grind("PreparationHello",
		--[[ AVSLAGSFORMEN AR HANDLARENS EGEN. Handskakningen svarar med en
			VY; klienten gor `if ok and vy then ritaOmNyare(vy) end`. `nil` ar
			alltsa den form den redan hanterar, och ett `false` hade varit en
			ny form att lara sig. ]]
		function(player)
			if not state[player] then
				GameplayService.bind(player)
			end
			--[[ Passvyn skickas som en egen sync i samma andetag. Utan den
				startade en klient som anslöt mitt i eftervården utan att veta
				att det fanns en eftervård — samma hål som handskakningen
				byggdes för att täta på förberedelsen. ]]
			skickaPass(player)
			return vyFor(player)
		end,
		function() return nil end)

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
		--[[ Slice C: kroppen dor eller byts. Den burna sadeln lag i
		     karaktaren och forsvinner med den — registret maste folja
		     med, annars ar hon reserverad av nagon som inte har henne.
		     `CharacterRemoving` ar sanningen; ingen pollning. ]]
		player.CharacterRemoving:Connect(function()
			GameplayService.karaktarBorta(player)
		end)
	end)
	--[[ Ingen `GetPlayers()`-loop här heller (#162 re-review): den band mot
		ett `passnummer()` som föll till 1 när saven ännu var nil.
		`efterLaddning` kör hooken direkt för dem som redan är redo. ]]
	Players.PlayerRemoving:Connect(GameplayService.lamnar)

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
