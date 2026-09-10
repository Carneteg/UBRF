--!strict
--[[ PASSET — dagen från uppsittning till att hästen är omhändertagen.

	Ren logik, som `Preparation.luau`. `GameplayService` äger instanserna
	och nätet; den här modulen äger frågan "var i passet är spelaren, och
	vad får hon göra härnäst".

	── VARFÖR EN EGEN MODUL ─────────────────────────────────────────

	`Preparation` slutar där uppsittningen börjar. Den frågan — "är hästen
	i ordning?" — är klar när man sitter i sadeln, och att bygga in
	eftervården i samma tillstånd hade gjort `redo` tvetydigt: redo att
	sitta upp, eller redo att gå hem?

	Passet är den andra halvan, och den halvan är precis det `CLAUDE.md`
	menar med att ansvaret kring hästen ÄR gameplay:

	    sitt upp → rid → sitt av → eftervård → passet räknas

	Det sista ledet hänger på det näst sista. Ett pass går INTE att avsluta
	genom att sitta av och logga ut — `farAvsluta` är fail-closed tills
	varje eftervårdsmoment är gjort. Annars vore eftervården en
	avslutningsskärm att klicka bort, och då hade den lika gärna kunnat
	strykas.

	── EFTERVÅRDEN ÄR KANON ─────────────────────────────────────────

	Momenten hittas inte på här. De är `UBRFSkotsel.eftervard`, genererad
	ur `src/spel/skotsel.js` — samma fil som fasordningen och ryktningen
	kommer ur. Ordningen (gjord → sadel → träns, och benen medan de är
	varma) vaktas av exportgrinden i `tools/exportera-spel.js`.

	── PASSID ───────────────────────────────────────────────────────

	`passId` sätts EN gång, när passet skapas, och ändras aldrig. Det är
	kvittot `Sparning.registreraPass` slår upp, och hela idempotensen
	hänger på att det inte räknas om vid avslutet. Räknades det om vore
	varje omsändning ett nytt pass.
]]

local RS = game:GetService("ReplicatedStorage")
local Skotsel = require(RS.UBRFSkotsel)

local Pass = {}

Pass.EFTERVARD = Skotsel.eftervard

--[[ Lägena, i den ordning de kommer. Engelska av samma skäl som
	`Preparation.STATUS`: statusorden går över nätet och namnges så i
	arbetsordern; texten spelaren ser är svensk och kommer ur kanonen. ]]
Pass.LAGE = {
	FORE = "before_ride",       -- passet finns, ritten har inte börjat
	RIDER = "riding",
	EFTERVARD = "aftercare",    -- avsutten, hästen inte omhändertagen än
	KLART = "done",             -- allt gjort, passet får räknas
	RAKNAT = "recorded",        -- passet ÄR räknat och sparat
}

export type State = {
	hastId: string,
	passId: string,
	lage: string,
	gjorda: { [string]: boolean },
	--[[ Sant när passet stoppats av välfärdsskäl i stället för ritt.
		Ett stoppat pass räknas ändå som en dag — spelaren gjorde rätt —
		men det får aldrig se ut som en genomförd ritt. ]]
	stoppad: boolean,
}

--[[ `passId` byggs av servern ur spelarens id, hästen och passnumret.
	Ligger här och inte i tjänsten för att formen ska gå att prova: två
	pass i rad på samma häst måste ge OLIKA id, och samma pass måste ge
	samma id hur många gånger det än frågas. ]]
function Pass.byggId(userId: number, hastId: string, passnummer: number): string
	return ("%d:%s:%d"):format(userId, hastId, passnummer)
end

function Pass.nyState(hastId: string, passId: string): State
	return {
		hastId = hastId,
		passId = passId,
		lage = Pass.LAGE.FORE,
		gjorda = {},
		stoppad = false,
	}
end

--[[ Eftervårdens moment, i kanonens ordning och i samma form som
	`Preparation.moment` — så att HUD:en kan rita båda med samma kod. ]]
local momentCache: any = nil

function Pass.moment()
	if momentCache then return momentCache end
	local ut = {}
	for i, e in ipairs(Pass.EFTERVARD) do
		table.insert(ut, { id = e.id, namn = e.namn, text = e.text, steg = i })
	end
	momentCache = ut
	return ut
end

function Pass.nastaMoment(state: State)
	for _, m in ipairs(Pass.moment()) do
		if not state.gjorda[m.id] then return m end
	end
	return nil
end

--[[ ── ÖVERGÅNGARNA ──────────────────────────────────────────────── ]]

--[[ Har eftervården börjat? Ett enda avbockat moment räknas: då är
	hästen på väg att bli omhändertagen och dagen är i sitt slutskede. ]]
function Pass.eftervardBorjad(state: State): boolean
	for _, gjort in pairs(state.gjorda) do
		if gjort then return true end
	end
	return false
end

--[[ FÅR HON SITTA UPP?

	Regeln var "en gång per dag, punkt": allt utom läget FÖRE nekades. Den
	gjorde dagen OSPELBAR i ett fall som inte är ovanligt — ryttaren dör
	eller tappar sin karaktär mitt i ritten. `HorseService` städar då
	korrekt, passet går till eftervård, och spelaren stod kvar med en häst
	hon inte fick sitta upp på och en eftervård hon inte hade ridit fram
	till. END_TO_END_PLAYABILITY_GATE punkt 10 kräver uttryckligen att
	respawn följs av UPPSITTNING igen.

	Regeln är därför: dagen slutar när hästen börjar bli omhändertagen,
	inte första gången ryttarens fötter når marken. Har inget
	eftervårdsmoment gjorts får hon sitta upp igen — hur hon än kom av.
	Har eftervården börjat, eller är passet klart/räknat, är dagen slut.

	Passet räknas fortfarande EXAKT en gång: kvittot `passId` ändras inte
	av att man sitter upp två gånger.

	[PRODUKTBESLUT som behöver ChatGPT/Tobias: gränsen "innan eftervården
	börjat" är MIN läsning av punkt 10. Alternativen är att bara döden ger
	en ny uppsittning, eller att antalet uppsittningar per dag är fritt.
	Regeln ligger i EN funktion just för att den ska gå att flytta.] ]]
function Pass.farSittaUpp(state: State): (boolean, string?)
	if state.lage == Pass.LAGE.FORE then
		return true, nil
	end
	if state.lage == Pass.LAGE.RIDER then
		return false, "du sitter redan upp"
	end
	if state.lage == Pass.LAGE.EFTERVARD and not Pass.eftervardBorjad(state) then
		return true, nil
	end
	return false, "Du har redan ridit idag"
end

function Pass.vidUppsittning(state: State): (boolean, string?)
	local far, skal = Pass.farSittaUpp(state)
	if not far then
		return false, skal or "passet är redan igång"
	end
	state.lage = Pass.LAGE.RIDER
	return true, nil
end

--[[ Avsittningen. Den ENDA vägen in i eftervården, och den kräver att man
	faktiskt suttit upp: annars kunde en spelare hoppa direkt till
	eftervården, bocka av fem moment och få ett pass utan att ha ridit. ]]
function Pass.vidAvsittning(state: State): (boolean, string?)
	if state.lage == Pass.LAGE.EFTERVARD then
		--[[ Dubbel avsittning är inget fel — `HorseService.dismount` kan nås
			från karaktärens död, från E och från utloggning — men den får
			inte nollställa eftervården. ]]
		return true, nil
	end
	if state.lage ~= Pass.LAGE.RIDER then
		return false, "du rider inte"
	end
	state.lage = Pass.LAGE.EFTERVARD
	return true, nil
end

--[[ Ett välfärdsstopp avslutar passet utan ritt. Hästen är redan
	omhändertagen av ridläraren, så eftervården hoppas över — men passet
	måste fortfarande RÄKNAS, annars straffas spelaren för att ha gjort
	rätt. ]]
function Pass.vidValfardsstopp(state: State): (boolean, string?)
	if state.lage == Pass.LAGE.RAKNAT then
		return false, "passet är redan räknat"
	end
	state.stoppad = true
	state.lage = Pass.LAGE.KLART
	return true, nil
end

--[[ Ett eftervårdsmoment. Samma tre nej som förberedelsens moment, av
	samma skäl: fel läge, redan gjort, fel tur. ]]
function Pass.utfor(state: State, momentId: string): (boolean, string?)
	if state.lage ~= Pass.LAGE.EFTERVARD then
		if state.lage == Pass.LAGE.RIDER then
			return false, "sitt av först"
		end
		return false, "det är inte dags för eftervård"
	end
	local moment = nil
	for _, m in ipairs(Pass.moment()) do
		if m.id == momentId then moment = m end
	end
	if not moment then
		return false, "okänt moment"
	end
	if state.gjorda[momentId] then
		return false, "redan gjort"
	end
	local pa_tur = Pass.nastaMoment(state)
	if pa_tur and pa_tur.id ~= momentId then
		return false, "fel tur — " .. pa_tur.namn .. " står på tur"
	end
	state.gjorda[momentId] = true
	if Pass.nastaMoment(state) == nil then
		state.lage = Pass.LAGE.KLART
	end
	return true, nil
end

--[[ Får passet avslutas och räknas? FAIL-CLOSED: bara i KLART.

	Alla andra lägen är nej, och det inkluderar att sitta av och gå. Det är
	acceptanskravet "Avsittning leder till faktisk eftervård innan passet
	kan avslutas" — och det enda sättet att göra eftervården till gameplay
	i stället för en ruta som visas på vägen ut. ]]
function Pass.farAvsluta(state: State): (boolean, string?)
	if state.lage == Pass.LAGE.RAKNAT then
		return false, "passet är redan räknat"
	end
	if state.lage ~= Pass.LAGE.KLART then
		local m = Pass.nastaMoment(state)
		if state.lage == Pass.LAGE.RIDER then
			return false, "du sitter fortfarande upp"
		end
		if state.lage == Pass.LAGE.FORE then
			return false, "du har inte ridit än"
		end
		return false, (m and m.namn or "eftervården") .. " återstår"
	end
	return true, nil
end

--[[ Markerar passet som räknat. Skild från `farAvsluta` för att servern
	ska hinna spara MELLAN de två: räknas passet i minnet först och
	sparningen sedan faller, hade spelaren förlorat passet utan att kunna
	göra om det. ]]
function Pass.markeraRaknat(state: State)
	state.lage = Pass.LAGE.RAKNAT
end

--[[ Det klienten ska visa av passet. Samma princip som
	`Preparation.vy`: servern skickar hela sanningen, klienten räknar
	inget själv. ]]
function Pass.vy(state: State?, rev: number?)
	if not state then
		return { lage = nil, moment = {}, nastaMoment = nil, klar = false,
			stoppad = false, rev = rev or 0 }
	end
	local moment = {}
	for _, m in ipairs(Pass.moment()) do
		table.insert(moment, {
			id = m.id,
			namn = m.namn,
			text = m.text,
			klar = state.gjorda[m.id] == true,
		})
	end
	local pa_tur = Pass.nastaMoment(state)
	return {
		lage = state.lage,
		hastId = state.hastId,
		moment = moment,
		nastaMoment = pa_tur and pa_tur.id or nil,
		klar = state.lage == Pass.LAGE.KLART or state.lage == Pass.LAGE.RAKNAT,
		stoppad = state.stoppad,
		rev = rev or 0,
	}
end

return Pass
