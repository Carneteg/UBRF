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

--[[ Samma `kanon:`-konvention som `Preparation` använder. Den ligger i båda
	modulerna med flit: `Pass` får inte require:a `Preparation` (det blir
	cirkulärt i bänkbygget), och en delad tredje modul för fyra rader vore
	dyrare än duplicerad konvention. Prefixet är kontraktet, inte koden. ]]
local Kanon = {}
Kanon.PREFIX = "kanon:"
function Kanon.kanontext(text: string?): string?
	if text == nil then return nil end
	return Kanon.PREFIX .. tostring(text)
end
Pass.kanontext = Kanon.kanontext
function Pass.arKanontext(skal: any): boolean
	return type(skal) == "string" and string.sub(skal, 1, #Kanon.PREFIX) == Kanon.PREFIX
end

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
	--[[ `true` när spelaren gjorde momentet själv, `"auto"` när stallet
		gjorde det åt henne (#273 S3) — samma märkning som `Preparation`. ]]
	gjorda: { [string]: any },
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

--[[ ══ #273 S3 (T1): EFTERVÅRDEN ÄR ETT VAL, INTE FEM KLICK ═══════════

	Tobias beslut 2026-10-01. Efter avsittningen får spelaren ett enkelt val:

	  «Stallet tar hand om henne»  passet räknas, ingen straffavgift
	  «Ta hand om henne själv»     frivillig egen eftervård, liten positiv effekt

	Momenten och deras ordning är kanonens och oförändrade. Det som ändras
	är VEM som gör dem (`gjorda[id]` är `true` eller `"auto"`) och att
	spelarens egen väg är tre handlingar i stället för fem kvittenser:

	  sadla_av   lossa gjorden + ta av sadeln      (fysiskt: sadel, underlägg)
	  transa_av  ta av tränset                     (fysiskt: träns, tyglar)
	  ta_hand    känn igenom benen + vatten och hö

	Gruppen slås upp på momentets id. Ett moment kanonen lägger till senare
	hamnar i den sista handlingen i stället för att försvinna. ]]
local HANDLING_FOR: { [string]: string } = {
	gjord = "sadla_av", sadel = "sadla_av", trans = "transa_av",
	ben = "ta_hand", vatten = "ta_hand",
}
local HANDLINGSORDNING = { "sadla_av", "transa_av", "ta_hand" }

function Pass.handlingar(): { { id: string, moment: { any } } }
	local per: { [string]: { any } } = {}
	for _, m in ipairs(Pass.moment()) do
		local id = HANDLING_FOR[m.id] or "ta_hand"
		per[id] = per[id] or {}
		table.insert(per[id], m)
	end
	local ut = {}
	for _, id in ipairs(HANDLINGSORDNING) do
		if per[id] then table.insert(ut, { id = id, moment = per[id] }) end
	end
	return ut
end

function Pass.nastaHandling(state: State)
	local n = Pass.nastaMoment(state)
	if not n then return nil end
	for _, h in ipairs(Pass.handlingar()) do
		for _, m in ipairs(h.moment) do
			if m.id == n.id then return h end
		end
	end
	return nil
end

--[[ Hur stor del av eftervården spelaren gjorde SJÄLV, 0–1. Driver den
	lilla relationsbonusen i `GameplayService.avslutaPass`. Stallets hand
	ger 0 — och det är golvet, inte ett avdrag. ]]
function Pass.egenAndel(state: State?): number
	if not state then return 0 end
	local totalt, egna = 0, 0
	for _, m in ipairs(Pass.moment()) do
		totalt += 1
		if state.gjorda[m.id] == true then egna += 1 end
	end
	if totalt == 0 then return 0 end
	return egna / totalt
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
		return false, "pass.sitter_redan"
	end
	if state.lage == Pass.LAGE.EFTERVARD and not Pass.eftervardBorjad(state) then
		return true, nil
	end
	return false, "spel.redan_ridit"
end

function Pass.vidUppsittning(state: State): (boolean, string?)
	local far, skal = Pass.farSittaUpp(state)
	if not far then
		return false, skal or "pass.redan_igang"
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
		return false, "pass.rider_inte"
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
		return false, "pass.redan_raknat"
	end
	state.stoppad = true
	state.lage = Pass.LAGE.KLART
	return true, nil
end

--[[ FÅR momentet göras? Samma tre nej som förberedelsens moment, av samma
	skäl: fel läge, redan gjort, fel tur.

	── VARFÖR FRÅGAN ÄR SKILD FRÅN SVARET (#211) ────────────────────

	Två av eftervårdens moment tar av UTRUSTNING som ligger på hästen —
	`sadel` och `trans`. Servern måste alltså röra världen i samma
	handling som den bockar av momentet, och då är ordningen avgörande:
	lyfts sadeln av först och regeln nekar sedan momentet, står hon
	avsadlad med ett moment som aldrig blev gjort. Det är exakt den
	glidning mellan tillstånd och värld som `TackService` finns för att
	omöjliggöra.

	Därför får tjänsten fråga UTAN att ändra något, och regeln ligger
	kvar på ett enda ställe: `utfor` nedan har ingen egen kopia av
	villkoren, den frågar den här funktionen. ]]
function Pass.farUtfora(state: State, momentId: string): (boolean, string?, string?)
	if state.lage ~= Pass.LAGE.EFTERVARD then
		if state.lage == Pass.LAGE.RIDER then
			return false, "pass.sitt_av_forst"
		end
		return false, "pass.inte_dags"
	end
	local moment = nil
	for _, m in ipairs(Pass.moment()) do
		if m.id == momentId then moment = m end
	end
	if not moment then
		return false, "pass.okant_moment"
	end
	if state.gjorda[momentId] then
		return false, "pass.redan_gjort"
	end
	local pa_tur = Pass.nastaMoment(state)
	if pa_tur and pa_tur.id ~= momentId then
		--[[ Fasens/momentets namn kommer ur skötselkanonen och är alltså
			innehåll, inte gränssnitt. Det taggas `kanon:` så att
			språkgrinden kan skilja "engelsk ram runt redovisad svensk
			kanontext" från "rå svenska som ingen deklarerat". ]]
		return false, "pass.fel_tur", Kanon.kanontext(pa_tur.namn)
	end
	return true, nil
end

--[[ Ett eftervårdsmoment. Prövar genom `farUtfora` och bockar av.
	`utforare == "auto"` är stallets hand; allt annat är spelarens. ]]
function Pass.utfor(state: State, momentId: string, utforare: string?): (boolean, string?, string?)
	local far, skal, arg = Pass.farUtfora(state, momentId)
	if not far then
		return false, skal, arg
	end
	state.gjorda[momentId] = if utforare == "auto" then "auto" else true
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
		return false, "pass.redan_raknat"
	end
	if state.lage ~= Pass.LAGE.KLART then
		local m = Pass.nastaMoment(state)
		if state.lage == Pass.LAGE.RIDER then
			return false, "pass.sitter_fortfarande"
		end
		if state.lage == Pass.LAGE.FORE then
			return false, "pass.inte_ridit"
		end
		return false, "pass.aterstar", Kanon.kanontext(if m then m.namn else nil)
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
		return { lage = nil, moment = {}, nastaMoment = nil, handlingar = {}, nastaHandling = nil,
			borjad = false, klar = false,
			stoppad = false, rev = rev or 0 }
	end
	local moment = {}
	for _, m in ipairs(Pass.moment()) do
		table.insert(moment, {
			id = m.id,
			namn = m.namn,
			text = m.text,
			klar = state.gjorda[m.id] ~= nil and state.gjorda[m.id] ~= false,
		})
	end
	local pa_tur = Pass.nastaMoment(state)
	--[[ #273 S3: handlingarna, och om eftervården börjat — panelen visar
		valet «stallet / själv» bara innan något är gjort. ]]
	local handlingar = {}
	for _, h in ipairs(Pass.handlingar()) do
		local klar, kunskap = true, {}
		for _, m in ipairs(h.moment) do
			if not state.gjorda[m.id] then klar = false end
			table.insert(kunskap, { id = m.id, namn = m.namn, text = m.text })
		end
		table.insert(handlingar, { id = h.id, klar = klar, kunskap = kunskap })
	end
	local paTurH = Pass.nastaHandling(state)
	return {
		lage = state.lage,
		hastId = state.hastId,
		moment = moment,
		nastaMoment = pa_tur and pa_tur.id or nil,
		handlingar = handlingar,
		nastaHandling = paTurH and paTurH.id or nil,
		borjad = Pass.eftervardBorjad(state),
		klar = state.lage == Pass.LAGE.KLART or state.lage == Pass.LAGE.RAKNAT,
		stoppad = state.stoppad,
		rev = rev or 0,
	}
end

return Pass
