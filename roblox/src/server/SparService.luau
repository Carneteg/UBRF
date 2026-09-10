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
local anmarkning: { [Player]: string? } = {}
--[[ Sant medan en skrivning pågår för spelaren. Två samtidiga
	`UpdateAsync` på samma nyckel throttlas av Roblox och kan dessutom
	komma i fel ordning; den här flaggan gör att avslut + utloggning inte
	blir två skrivningar i luften samtidigt. ]]
local skriver: { [Player]: boolean } = {}

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

function SparService.ladda(player: Player): Sparning.Save
	local b = hamtaButik()
	if not b then
		sparade[player] = Sparning.tom()
		kanSpara[player] = false
		anmarkning[player] = "inget datalager"
		return sparade[player]
	end

	local ok, rad = medRetry("läsning av " .. player.Name, function()
		return b:GetAsync(nyckelFor(player))
	end)

	if not ok then
		--[[ FALL 1 i filhuvudet. Sessionssave, ingen skrivning. ]]
		sparade[player] = Sparning.tom()
		kanSpara[player] = false
		anmarkning[player] = "läsfel"
		warn(("[Spar] %s spelar utan sparning — läsningen gick inte igenom."):format(player.Name))
		return sparade[player]
	end

	local save, notering = Sparning.migrera(rad)
	sparade[player] = save
	anmarkning[player] = notering

	if notering == "framtida" then
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

	local ok = select(1, medRetry("skrivning för " .. player.Name, function()
		return b:UpdateAsync(nyckelFor(player), function(gammal)
			--[[ Slå ihop med det som faktiskt står i lagret, inte med det vi
				råkade läsa vid inloggningen. Mellan då och nu kan en annan
				server ha skrivit. ]]
			local bas = select(1, Sparning.migrera(gammal))

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
					--[[ Skador slås ihop åt det FÖRSIKTIGA hållet: den
						längsta vilan vinner. En sammanslagning får aldrig
						förkorta en vila — det vore samma fail-open som PR
						#154 stängde på webben. ]]
					if m.skada and (not fanns.skada or m.skada.passKvar > fanns.skada.passKvar) then
						fanns.skada = m.skada
					end
				end
			end

			if andra then andra(bas) end

			--[[ Minnet uppdateras till det sammanslagna, så att nästa
				skrivning utgår från samma sanning som lagret. ]]
			sparade[player] = bas
			return Sparning.tillRad(bas)
		end)
	end))

	skriver[player] = false
	if not ok then
		warn(("[Spar] %s kunde inte sparas nu. Framstegen ligger kvar i minnet "
			.. "och försöks igen."):format(player.Name))
	end
	return ok
end

local function glom(player: Player)
	sparade[player] = nil
	kanSpara[player] = nil
	anmarkning[player] = nil
	skriver[player] = nil
end

--[[ ── LIVSCYKEL ──────────────────────────────────────────────────── ]]

function SparService.start()
	Players.PlayerAdded:Connect(function(player)
		SparService.ladda(player)
	end)
	for _, player in Players:GetPlayers() do
		SparService.ladda(player)
	end

	Players.PlayerRemoving:Connect(function(player)
		--[[ Sista skrivningen. Den körs synkront i signalen med flit:
			Roblox håller servern vid liv tills PlayerRemoving-lyssnarna
			returnerat, men bara då. En `task.spawn` här hade gjort att
			sista passet ibland inte hann skrivas. ]]
		SparService.skriv(player)
		glom(player)
	end)

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

return SparService
