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
local TackService = require(script.Parent.TackService)
local Komplex = require(ReplicatedStorage.UBRFKomplex)
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
			if not ok then
				skicka(player)
				return false, skal
			end
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
			pasattDel = DEL_NYCKEL[typ]
		end
	end

	local ok, avslag = Preparation.utforMoment(s, fasId, momentId, s.hastId, utforare)
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
	return ok, avslag
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
function GameplayService.ridaNu(player: Player): (boolean, string?, string?)
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
					local ok, avslag = GameplayService.moment(player, f.id, m.id, "auto")
					--[[ `tack.redan_pa` är samma sort som `forb.redan_gjort`: inte
						ett fel, utan ett moment som redan är utfört. Utan den här
						raden svarade ett andra «Rida nu» med ett UTRUSTNINGSFEL på
						en häst som bara var färdig — se noten vid `spel.redan_redo`
						ovan. Fail-closed är oförändrat: allt ANNAT nej avbryter
						fortfarande hela förberedelsen. ]]
					if not ok and avslag ~= "forb.redan_gjort"
							and avslag ~= "tack.redan_pa" then
						skicka(player)
						return false, avslag
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
			local ok, avslag = GameplayService.moment(player, "leda", m.id, "auto")
			if not ok and avslag ~= "forb.redan_gjort" then
				skicka(player)
				return false, avslag
			end
		end
	end

	skicka(player)
	local klar, varfor, arg = Preparation.provaUppsittning(s, s.hastId)
	return klar, varfor, arg
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

function GameplayService.valdFor(player: Player): { [string]: string }?
	return valdUtrustning[player]
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
function GameplayService.farSittaUpp(player: Player, modell: Model): (boolean, string?, string?)
	local s = state[player]
	--[[ Krav 6 och 7 avgörs av regeln, inte här. Kvar i tjänsten är bara
		det instansnära: att modellen dessutom är den vi FAKTISKT bundit,
		så att två modeller med samma id aldrig kan bli utbytbara. ]]
	--[[ Argumentet följer med: välfärdsstoppets skäl är en ram (nyckel) och
		fyndets mening (argument). Se noten i `HorseService.tryMount`. ]]
	local ok, skal, arg = Preparation.provaModell(s, modell:GetAttribute("HorseId"))
	if not ok then
		return false, skal, arg
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

local function glom(player: Player)
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
	Net.get("RidaNu").OnServerInvoke = function(player)
		return GameplayService.ridaNu(player)
	end

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
	LedService.satRattHastKrok(function(player)
		return bunden[player] or GameplayService.bind(player)
	end)

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
		return false, "spel.gammal_klient"
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
	--[[ Ingen `GetPlayers()`-loop här heller (#162 re-review): den band mot
		ett `passnummer()` som föll till 1 när saven ännu var nil.
		`efterLaddning` kör hooken direkt för dem som redan är redo. ]]
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
