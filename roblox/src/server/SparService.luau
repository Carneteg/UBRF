--!strict
--[[ SPARSERVICE — Roblox varaktiga lager. Litet, versionsstämplat, serverägt.

	Före #161 fanns inget `DataStoreService` någonstans i `roblox/`. PR #154
	lämnade kroken — `StallService.hastminnen` returnerade nil med
	kommentaren *"den dagen ett DataStore läggs till är det HÄR det
	hämtas"* — och det här är den dagen.

	── ANSVARSGRÄNSEN ───────────────────────────────────────────────

	`Sparning.luau` äger SCHEMAT, migrationen och idempotensen. Den här
	filen äger NYCKELN, nätverket, retryn och felen — allt som kräver en
	riktig Roblox-server och därför inte går att fälla i bänken. Den
	uppdelningen är hela skälet till att sparlogiken går att prova alls:
	reglerna provas i `skotselpass.spec.luau`, det här lagret provas mot en
	stubbad `DataStoreService` som kan fås att fela på begäran.

	── SERVERN ÄGER VARJE SKRIVNING ─────────────────────────────────

	Det finns INGEN RemoteFunction som tar emot ett saveobjekt. Klienten
	kan inte skicka något som skrivs, varken helt eller delvis; den kan
	bara utföra spelhandlingar som servern själv värderar. Det är
	uttryckligen kravet i #161 och det är också det enda sättet att göra
	progressionen värd något.

	── FAIL-SAFE, ALDRIG FAIL-OPEN ──────────────────────────────────

	Tre fel kan hända, och de behandlas OLIKA:

	  1. Läsningen faller (nätet, throttling, utility ner).
	     → spelaren får en SESSIONSAVE som inte skrivs tillbaka.
	       Hon kan spela. Hon får inga pass räknade. Att i stället ge
	       henne en tom save och spara den hade RADERAT hennes framsteg
	       för att nätet hackade i tre sekunder.

	  2. Raden är skriven av en NYARE version (`framtida`).
	     → samma sak: spela ja, skriv nej. En gammal server ska inte
	       skriva över en nyare sparfil den inte förstår.

	  3. Skrivningen faller.
	     → retry med backoff. Håller den inte får passet stå kvar
	       oräknat i minnet; nästa avslut försöker igen. Ingen krasch,
	       och ingen gratis progression.

	`kanSpara` är den enda flaggan som styr, och den är fail-CLOSED: den
	sätts sant först när en läsning faktiskt lyckats.

	── UpdateAsync, INTE SetAsync ───────────────────────────────────

	Skrivningen går genom `UpdateAsync` och slår ihop med det som redan
	står. Två servrar (spelaren i två platser, eller en snabb rejoin under
	en shutdown) kan annars skriva över varandras pass. Sammanslagningen
	är `Sparning.migrera` på den lagrade raden följt av samma
	`registreraPass` — kvittona gör den operationen idempotent, så en
	sammanslagning aldrig kan dubbelräkna.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Sparning = require(ReplicatedStorage.HorseCore.Sparning)

local SparService = {}

--[[ Namnet bär schemaversionen. En framtida `v2` som INTE är
	bakåtkompatibel byter butik i stället för att riskera att tolka gamla
	rader fel — `Sparning.migrera` klarar de kompatibla stegen, butiksbytet
	finns för de andra. ]]
local BUTIK = "UBRF_Spelare_v1"
local NYCKEL = "spelare_%d"

local FORSOK = 3
local BACKOFF = { 1, 2, 4 }

local butik: any = nil
local sparade: { [Player]: Sparning.Save } = {}
local kanSpara: { [Player]: boolean } = {}
--[[ ANMÄRKNINGEN ÄR EN SPRÅKNYCKEL, inte ett svenskt ord (#162 punkt 2).
	Ingen yta visar den för spelaren ännu — den läses av servern själv för
	att avgöra om sessionen får spara. Men den dag den visas ska den vara
	lokaliserbar, och en svensk statuskod hade då blivit svensk text i en
	engelsk HUD. Nycklarna finns i språkkanonen (`spar.*`). ]]
local anmarkning: { [Player]: string? } = {}
--[[ Sant medan en skrivning pågår för spelaren. Två samtidiga
	`UpdateAsync` på samma nyckel throttlas av Roblox och kan dessutom
	komma i fel ordning; den här flaggan gör att avslut + utloggning inte
	blir två skrivningar i luften samtidigt. ]]
local skriver: { [Player]: boolean } = {}
--[[ Revisionen vi LÄSTE. Skrivningen jämför lagrets rad mot den här: är
	lagret nyare har någon annan hunnit skriva, och då avbryter vi i stället
	för att slå ihop. Se `rev` i Sparning. ]]
local laddadRev: { [Player]: number } = {}
-- Identiteten gör ett sent nätverkssvar ogiltigt när sessionen avslutas.
local laddningar: { [Player]: {} } = {}

--[[ Studio utan API-åtkomst, och alla lokala prov, ska INTE krascha på
	rad ett. `GetDataStore` kastar då, och resultatet är nil — vilket
	`kanSpara` redan hanterar som "spela, men spara inte". ]]
local function hamtaButik(): any
	if butik then return butik end
	local ok, b = pcall(function()
		return DataStoreService:GetDataStore(BUTIK)
	end)
	if ok and b then
		butik = b
	else
		warn("[Spar] Inget datalager tillgängligt — sessionen sparas inte. "
			.. tostring(b))
	end
	return butik
end

local function nyckelFor(player: Player): string
	return NYCKEL:format(player.UserId)
end

--[[ Retry med backoff runt ett anrop som får kasta. Returnerar
	(ok, resultat, sistaFelet). Väntar INTE efter sista försöket — det är
	bara en sekund innan spelaren får sitt svar, utan att någon vinner
	något på den. ]]
local function medRetry(vad: string, fn: () -> any): (boolean, any, string?)
	local sistaFel: string? = nil
	for i = 1, FORSOK do
		local ok, resultat = pcall(fn)
		if ok then
			return true, resultat, nil
		end
		sistaFel = tostring(resultat)
		warn(("[Spar] %s misslyckades (försök %d/%d): %s"):format(vad, i, FORSOK, sistaFel))
		if i < FORSOK then
			task.wait(BACKOFF[i] or 4)
		end
	end
	return false, nil, sistaFel
end

--[[ ── LÄSNINGEN ──────────────────────────────────────────────────── ]]

function SparService.ladda(player: Player, fortfarandeAktuell: (() -> boolean)?): Sparning.Save
	local b = hamtaButik()
	if not b then
		sparade[player] = Sparning.tom()
		laddadRev[player] = 0
		kanSpara[player] = false
		anmarkning[player] = "spar.inget_datalager"
		return sparade[player]
	end

	local ok, rad = medRetry("läsning av " .. player.Name, function()
		return b:GetAsync(nyckelFor(player))
	end)
	-- Läsningen kan ha yieldat förbi PlayerRemoving. Publicera då inget
	-- tillstånd, inte heller en sessionsave efter ett sent läsfel.
	if fortfarandeAktuell and not fortfarandeAktuell() then
		return Sparning.tom()
	end

	if not ok then
		--[[ FALL 1 i filhuvudet. Sessionssave, ingen skrivning. ]]
		sparade[player] = Sparning.tom()
		laddadRev[player] = 0
		kanSpara[player] = false
		anmarkning[player] = "spar.lasfel"
		warn(("[Spar] %s spelar utan sparning — läsningen gick inte igenom."):format(player.Name))
		return sparade[player]
	end

	local save, notering = Sparning.migrera(rad)
	sparade[player] = save
	laddadRev[player] = save.rev
	anmarkning[player] = notering

	if notering == "spar.framtida_sparfil" then
		--[[ FALL 2. En nyare sparfil vi inte förstår skrivs inte över. ]]
		kanSpara[player] = false
		warn(("[Spar] %s har en sparfil från en nyare version — sessionen sparas inte."):format(player.Name))
	elseif notering == "trasig" then
		--[[ Raden fanns men gick inte att läsa. Vi startar från noll — men
			vi SKRIVER, för annars kan spelaren aldrig komma vidare. Noll
			pass är fail-safe: en trasig rad ger aldrig progression. ]]
		kanSpara[player] = true
		warn(("[Spar] %s hade en oläsbar sparfil — startar om från noll pass."):format(player.Name))
	else
		kanSpara[player] = true
	end
	return save
end

function SparService.save(player: Player): Sparning.Save?
	return sparade[player]
end

function SparService.kanSpara(player: Player): boolean
	return kanSpara[player] == true
end

function SparService.anmarkning(player: Player): string?
	return anmarkning[player]
end

--[[ ── SKRIVNINGEN ────────────────────────────────────────────────── ]]

--[[ Den längsta av två vilor, nil-säkert. Används BARA på konfliktvägen i
	`skriv`, där en annan server hunnit skriva efter vår läsning och ingen
	av de två vilorna kan visas vara färskast.

	`nil` är inte "noll pass kvar" utan "ingen skada", och den förlorar mot
	en riktig skada: att låta en okänd session läka en häst vore att gissa
	åt fel håll. ]]
local function langstaVila(a: Sparning.Skada?, b: Sparning.Skada?): Sparning.Skada?
	if not a then return b end
	if not b then return a end
	return if b.passKvar > a.passKvar then b else a
end

--[[ `andra` får ändra den save som ligger i datalagret. Den körs INUTI
	`UpdateAsync` och kan därför köras om av Roblox — den måste vara
	idempotent, och det är precis vad `Sparning.registreraPass` garanterar.

	Returnerar sant när skrivningen gick fram. ]]
function SparService.skriv(player: Player, andra: ((Sparning.Save) -> ())?): boolean
	local minnet = sparade[player]
	if not minnet then return false end
	if not kanSpara[player] then
		return false
	end
	local b = hamtaButik()
	if not b then return false end
	if skriver[player] then
		--[[ En skrivning är redan i luften. Att köa en till på samma nyckel
			ger throttling och kan dessutom landa i fel ordning. Ändringen
			ligger kvar i minnet och går med nästa skrivning. ]]
		return false
	end
	skriver[player] = true

	--[[ Sätts inne i callbacken när skrivningen måste avbrytas. Läses efter
		anropet: `UpdateAsync` kastar inte när transformatorn returnerar nil,
		så utan flaggan hade `skriv` svarat sant om en skrivning som aldrig
		blev av. ]]
	local konflikt: string? = nil

	local ok = select(1, medRetry("skrivning för " .. player.Name, function()
		return b:UpdateAsync(nyckelFor(player), function(gammal)
			--[[ Slå ihop med det som faktiskt står i lagret, inte med det vi
				råkade läsa vid inloggningen. Mellan då och nu kan en annan
				server ha skrivit. ]]
			local bas, notering = Sparning.migrera(gammal)

			--[[ FYND 2 I OMREVIEWEN AV caac3f5: anteckningen kastades här.
				Läsningen behandlade `framtida` som icke-skrivbar, men den
				här callbacken konverterade en framtida rad till en TOM v1
				och slog in vår gamla session i den. Filhuvudets utfästelse
				gällde alltså bara inloggningen.

				Att returnera nil ur transformatorn AVBRYTER skrivningen och
				lämnar det lagrade värdet orört. Det är rätt utgång: en
				gammal server ska inte röra en sparfil den inte förstår. ]]
			if notering == "spar.framtida_sparfil" then
				konflikt = "framtida sparfil i lagret"
				return nil
			end

			--[[ REVISIONEN, OCH VAD DEN BETYDER FÖR VILAN.

				Står lagret på samma revision som vi läste har ingen annan
				skrivit sedan dess. Då ÄR minnet den senaste sanningen, och
				minnet äger vilan — inklusive att den räknats ner eller
				tagit slut. Det är fynd 1, och nedräkningen hänger på det.

				Står lagret HÖGRE har någon annan server skrivit efter vår
				läsning. Vi basar då om på den FÄRSKA raden (`bas` kommer
				ur `gammal`, alltså det som faktiskt ligger där nu) och slår
				bara ihop det som är monotont: kvitton, passtal, relation
				och första dagen. Ingen av dem kan sänka något.

				För vilan finns ingen monoton väg, och därför gissar vi inte
				åt spelarens håll: den LÄNGSTA vinner på konfliktvägen. Att
				korta en vila på en gissning vore att släppa ut en halt
				häst; att förlänga den kostar ett pass.

				RUNDA 4, P1: den här grenen AVBRÖT tidigare skrivningen. Det
				bevarade den färska skadan men lämnade `laddadRev` orörd och
				`kanSpara` sann, så nästa skrivning läste samma högre rev mot
				samma gamla `laddadRev` och avbröt igen — sessionen låg fast
				och trodde ändå att den sparade. Ombaseringen nedan är
				begränsad till ETT försök inne i samma `UpdateAsync`: läs
				färskt, slå ihop, skriv en gång. Ingen omkörningsslinga.

				Det som INTE basas om är den framtida raden ovan. Där
				förstår vi inte schemat, och då är avbrottet rätt utgång. ]]
			local last = laddadRev[player] or 0
			local nyare = bas.rev > last
			if nyare then
				warn(("[Spar] %s: lagret är revision %d, vi läste %d — basar om på den färska raden.")
					:format(player.Name, bas.rev, last))
			end

			--[[ Progressionen tas ur den HÖGSTA av de två: en gammal server
				ska aldrig kunna sänka ett passtal. Kvittona slås ihop, och
				det är de som gör sammanslagningen idempotent. ]]
			for id, nar in pairs(minnet.passId) do
				if bas.passId[id] == nil then
					bas.passId[id] = nar
					bas.pass += 1
				end
			end
			if minnet.pass > bas.pass then bas.pass = minnet.pass end

			bas.forstaDagen.klar = bas.forstaDagen.klar or minnet.forstaDagen.klar
			bas.forstaDagen.hastId = bas.forstaDagen.hastId or minnet.forstaDagen.hastId

			for id, m in pairs(minnet.hastar) do
				local fanns = bas.hastar[id]
				if not fanns then
					bas.hastar[id] = { relation = m.relation, skada = m.skada }
				else
					fanns.relation = math.max(fanns.relation, m.relation)
					if nyare then
						--[[ KONFLIKTVÄGEN: någon annan skrev efter vår
							läsning, och vi vet inte vems vila som är
							färskast. Den LÄNGSTA vinner. Regeln är gjord åt
							hästens håll, inte åt spelarens: en vila som
							blir ett pass för lång kostar en dag, en vila
							som kortas på en gissning sätter en halt häst i
							arbete.

							Vår egen nedräkning kan alltså gå förlorad just
							den här gången. Det är avsiktligt och ofarligt —
							nästa pass räknar ner igen från den rad vi nu
							basat om på. ]]
						fanns.skada = langstaVila(fanns.skada, m.skada)
					else
						--[[ MINNET ÄGER VILAN, rakt av — inte "längsta
							vinner". Ingen annan har skrivit sedan vi läste;
							minnet ÄR den senaste sanningen, och det gäller
							lika mycket när skadan räknats ner till 1 som
							när den tagit slut helt.

							Den gamla regeln ("längsta vilan vinner", alltid)
							var välmenad — den skulle hindra en gammal server
							från att korta en färsk skada — men den gjorde
							nedräkningen omöjlig: lagrets 2 slog minnets 1,
							och `sparade[player] = bas` skrev tillbaka 2 i
							minnet också. Hästen vilade för evigt. Nu gäller
							den bara där osäkerheten finns. ]]
						fanns.skada = m.skada
					end
				end
			end

			if andra then andra(bas) end

			--[[ Ny revision, räknad från den rad som FAKTISKT ligger i
				lagret — inte från den vi läste. Basar vi om måste vi hamna
				förbi den andra serverns revision, annars skulle nästa
				skrivning se en konflikt som inte finns.

				Nästa skrivning från den här sessionen jämför mot den, och en
				annan server som läste tidigare ser att lagret hunnit före. ]]
			bas.rev = math.max(bas.rev, last) + 1
			laddadRev[player] = bas.rev

			--[[ Minnet uppdateras till det sammanslagna, så att nästa
				skrivning utgår från samma sanning som lagret. ]]
			sparade[player] = bas
			return Sparning.tillRad(bas)
		end)
	end))

	skriver[player] = false
	if konflikt then
		--[[ Ingenting skrevs, och det var avsiktligt. Framstegen ligger kvar
			i minnet. Den framtida sparfilen gör dessutom sessionen
			icke-skrivbar tills spelaren kommer in på en server som förstår
			schemat — samma beslut som läsningen redan tar. ]]
		if konflikt == "framtida sparfil i lagret" then
			kanSpara[player] = false
			anmarkning[player] = "spar.framtida_sparfil"
		end
		warn(("[Spar] %s sparades INTE: %s. Inget skrevs över.")
			:format(player.Name, konflikt))
		return false
	end
	if not ok then
		warn(("[Spar] %s kunde inte sparas nu. Framstegen ligger kvar i minnet "
			.. "och försöks igen."):format(player.Name))
	end
	return ok
end

--[[ ── BARRIÄREN: LADDNINGEN ÄR KLAR ─────────────────────────────
	#162 blockerare 1. `ladda()` yieldar i `GetAsync`. Roblox startar varje
	`PlayerAdded`-anslutning på EGEN TRÅD, så en tjänst som kopplar samma
	signal själv körs medan läsningen fortfarande är i luften — mot en save
	som är nil. Det gav tre konkreta fel: `StallService.hastminnen` svarade
	nil och en häst som vilade för en skada kunde tilldelas,
	`GameplayService.passnummer` föll till 1 och därmed "första dagen", och
	startordningen i `init.server.luau` såg ut att skydda mot det utan att
	göra det.

	Startordning är inte en barriär. Den bestämmer i vilken ordning
	anslutningarna GÖRS, inte att den första blir KLAR först.

	Lösningen är att ta bort de andra anslutningarna helt. Det finns nu EN
	`PlayerAdded`-lyssnare i hela servern, den här, och den kör sina
	registrerade hookar efter att läsningen returnerat. Hookarna körs i
	registreringsordning, alltså samma ordning som `init.server.luau`
	startar tjänsterna — StallService före GameplayService, vilket är det
	beroende som redan gällde.

	Fail-safe-vägen är oförändrad: `ladda()` returnerar ALLTID en save, även
	när läsningen faller (då en sessionsave med `kanSpara = false`). Hookarna
	körs alltså alltid, och en spelare vars datalager är nere får en häst och
	kan rida. En barriär som väntade på en save som aldrig kommer hade bytt
	ett race mot en låsning. ]]
local efterLaddning: { (Player, Sparning.Save) -> () } = {}

--[[ REDO = laddningen har nått ett SLUTLÄGE för den här spelaren.

	Slutläge betyder inte "lyckades". Både en lyckad läsning och varje
	fail-safe-utgång (inget datalager, läsfel, framtida version, trasig rad)
	är slutlägen: `ladda()` returnerar alltid en save, och efter den finns
	inget mer att vänta på. Att låta ett läsfel lämna spelaren "inte redo"
	hade bytt racet mot en låsning, och #162 är uttrycklig om att en
	misslyckad laddning ska bli spelbar med `kanSpara = false`.

	Flaggan är publik därför att den är en GRIND: varje väg som tilldelar
	eller binder ska fråga den först, inte gissa utifrån startordning. ]]
local redo: { [Player]: boolean } = {}

function SparService.redo(player: Player): boolean
	return redo[player] == true
end

--[[ Registrera en hook som körs när en spelares laddning nått slutläge.

	KÖR OCKSÅ FÖR DEM SOM REDAN ÄR REDO. Det är hela skillnaden mot
	re-reviewen av `2a8938e`: där hade StallService och GameplayService egna
	`GetPlayers()`-loopar i sina `start()` för att fånga spelare som redan
	var inne — och de looparna gick förbi barriären. En spelare kan ha
	anlänt medan SparService läste, och då är hennes laddning fortfarande i
	luften när nästa tjänst startar.

	Nu finns ingen sådan loop. Registreringen är själv återhämtningen: är
	spelaren redo körs hooken direkt, är hon inte redo körs den när
	laddningen landar. Ett ställe, ingen väg runt. ]]
function SparService.efterLaddning(fn: (Player, Sparning.Save) -> ())
	table.insert(efterLaddning, fn)
	for _, player in Players:GetPlayers() do
		if redo[player] and sparade[player] then
			local ok, fel = pcall(fn, player, sparade[player])
			if not ok then
				warn(("[Spar] en efterLaddning-hook föll för %s: %s")
					:format(player.Name, tostring(fel)))
			end
		end
	end
end

--[[ Läs först, kör hookarna sedan. Varje hook körs i sin egen `pcall`: en
	tjänst som faller ska inte hindra nästa från att komma igång, och den
	spelare vars tilldelning strular ska inte också bli utan bindning.

	`redo` sätts FÖRE hookarna. Ordningen spelar roll: en hook — eller ett
	`MinHast`-anrop som kommer in medan hookarna körs — ska se ett slutfört
	slutläge, inte halva sanningen. ]]
local function laddaOchStarta(player: Player)
	local laddning = {}
	laddningar[player] = laddning
	local function aktuell(): boolean
		return laddningar[player] == laddning
	end
	local save = SparService.ladda(player, aktuell)
	if not aktuell() then return end
	redo[player] = true
	for _, fn in ipairs(efterLaddning) do
		if not aktuell() then return end
		local ok, fel = pcall(fn, player, save)
		if not ok then
			warn(("[Spar] en efterLaddning-hook föll för %s: %s")
				:format(player.Name, tostring(fel)))
		end
	end
end

local function glom(player: Player)
	laddningar[player] = nil
	sparade[player] = nil
	kanSpara[player] = nil
	anmarkning[player] = nil
	skriver[player] = nil
	redo[player] = nil
	laddadRev[player] = nil
end

--[[ ── LIVSCYKEL ──────────────────────────────────────────────────── ]]

function SparService.start()
	-- Registrera städningen innan även startens GetPlayers-läsningar kan yielda.
	Players.PlayerRemoving:Connect(function(player)
		laddningar[player] = nil
		redo[player] = nil
		SparService.skriv(player)
		glom(player)
	end)
	--[[ DEN ENDA `PlayerAdded`-lyssnaren i servern. Se barriären ovan. ]]
	Players.PlayerAdded:Connect(laddaOchStarta)
	for _, player in Players:GetPlayers() do
		laddaOchStarta(player)
	end

	if not RunService:IsStudio() then
		game:BindToClose(function()
			for _, player in Players:GetPlayers() do
				SparService.skriv(player)
			end
		end)
	end

	print("[Spar] Datalagret igång (" .. BUTIK .. ")")
end

--[[ Provkrokar. `ladda` och `skriv` är publika och provas direkt; de här
	finns för att en spec ska kunna nollställa mellan fall utan att gå
	genom PlayerRemoving respektive utan att starta en ny server.

	`_glomButikForProv` glömmer den CACHADE butiken. Cachen är rätt i
	produktion — `GetDataStore` ska inte anropas per spelare — men den gör
	att fallet "Studio utan API-åtkomst" inte går att prova efter ett
	lyckat fall i samma process, och det fallet måste gå att prova. ]]
function SparService._glomForProv(player: Player)
	glom(player)
end

function SparService._glomButikForProv()
	butik = nil
end

--[[ Glömmer de registrerade `efterLaddning`-hookarna. I produktion körs
	`start()` en gång per server och registret ska växa monotont; i bänken
	körs det en gång per provblock, och då lade block två på sig block
	ettas hookar. Det syntes som en dubblerad tilldelningsrad — alltså
	precis den sorts brus som gör att ett prov inte längre mäter det det
	påstår. ]]
function SparService._glomHookarForProv()
	efterLaddning = {}
end

return SparService
