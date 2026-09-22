--!strict
--[[
	LEKTIONEN PÅ KLIENTEN — den kedja som saknades.

	UgnetaController är en HUD och UgnetaGestalt är en figur. Ingen av dem
	kör en lektion. Den här modulen gör det, och den anropas från den
	ENDA uppdateringsloopen i init.client.luau — inte från en egen
	Heartbeat, av samma skäl som står i loopens huvud.

	Vad spelaren får, i den ordningen UX-variant 1 + 3 säger:

	  1. övningen presenteras (rubrik + två punkter, ur kanonen),
	  2. spelaren startar försöket själv,
	  3. hon rider — och får bara några ord live, aldrig ett kort,
	  4. efter försök 1: en sak som var bra, en att förbättra,
	     "Prova igen",
	  5. försök 2 på SAMMA övning, mätt från noll,
	  6. efter försök 2: en konkret jämförelse mot försök 1,
	  7. nästa övning.

	LEKTIONEN VÄNTAR PÅ SPELAREN (senior review av c53a2c7). Förut gick
	den vidare på en sexsekunderstimer, och "Prova igen" var en TextLabel
	utan input: kortet såg ut som ett val men var en nedräkning. Två fel
	föll ut av det. Spelaren kunde inte välja att försöka igen, och
	mätningen av nästa försök började medan ryttaren fortfarande läste
	kortet — timern brydde sig inte om ifall någon var redo.

	Nu finns `lage`, och det är hela rättelsen:

	  "ny"           en övning ska presenteras
	  "presentation" kortet uppe, spelaren väljer när försöket börjar
	  "rider"        DET ENDA läget där något mäts
	  "efter"        återkopplingen uppe, spelaren väljer att gå vidare
	  "ingen"        passet är slut

	Mätningen nollställs vid spelarens handling (`Lektion.vidare` i
	`fortsattning`), inte när timern råkar löpa ut.

	Mätningen kommer ur `ride.telemetri`, alltså ur HorseCore/Telemetri —
	samma avläsning webben gör. Ingen egen fysik, inga egna formler:
	bedömningen ligger i HorseCore/Lektion och HorseCore/Ugneta.

	SÄKERHET VINNER. `avbryt` släcker chip, kort och gestalt på en gång —
	och kastar den väntande fortsättningen, så att ett tangenttryck efter
	avsittningen inte kan starta ett försök på en häst som inte finns.
	Den anropas när ritten tar slut av vilket skäl som helst — inklusive
	de skäl som ÄR säkerhetshändelser: karaktären försvinner, riggen är
	borta ur workspace, servern flyttar uppsittningen. En "Bra rytm" får
	aldrig bli kvar på skärmen efter att ekipaget inte finns längre.
]]

local Lektion = require(game:GetService("ReplicatedStorage").HorseCore.Lektion)
local UgnetaController = require(script.Parent.UgnetaController)
local UgnetaGestalt = require(script.Parent.UgnetaGestalt)
--[[ Teaching Loop: summeringen rankas av SAMMA modul som varje
     forsoksbesked, inte av en andra bedomningslogik. ]]
local Ugneta = require(game:GetService("ReplicatedStorage").HorseCore.Ugneta)
--[[ QA blockerare 2: ETT tema per pass. Förut valde `Lektion.liveCue`
     den svagaste dimensionen i VARJE bildruta, så Ugneta hoppade mellan
     tre olika saker under samma volt. Regeln bor i HorseCore så att
     webben och Roblox kan dela den. ]]
local UgnetaTema = require(game:GetService("ReplicatedStorage").HorseCore.UgnetaTema)
local ReplayController = require(script.Parent.ReplayController)
local Inspelning = require(game:GetService("ReplicatedStorage").HorseCore.Inspelning)
--[[ Kortets knapptext kommer ur språkkatalogen. Den stod hårdkodad på
	svenska i logiken, vilket gav en engelsk spelare svenska ord — se noten
	vid `presentera`. ]]
local Sprak = require(game:GetService("ReplicatedStorage").HorseCore.Sprak)

local LektionController = {}

local LIVE_CD = require(game:GetService("ReplicatedStorage").HorseCore.RidKanon).UGNETA.LIVE_CD

local pass: Lektion.Pass? = nil
local liveCd = 0
--[[ ── DAGENS TEMA ─────────────────────────────────────────────────
     Ett per pass, se `HorseCore/UgnetaTema`. `nil` betyder «inte valt
     än»: valet kräver en mätning och den finns först när hon ridit.

     Hästens sida hålls bredvid: namnet för att kunna säga vem det kom
     ifrån, kontexten för att kunna avgöra OM det kom från henne. Båda
     sätts av `satHast` vid uppsittning och nollas vid avsittning — en
     kvarglömd kontext hade låtit nästa häst ärva föregåendes lynne. ]]
local tema: UgnetaTema.Tema? = nil
local hastNamn = ""
local hastKontext: { [string]: any }? = nil

--[[ ── EN AVBRUTEN LEKTION SOM INTE VAR SLUT ───────────────

	Re-review runda 2 av `f6ff67d`, blockerare 1.

	Ett nekat nej river lektionen lokalt, och servern sätter upp
	spelaren igen med `MountChanged`. Utan den här posten fick hon ett
	NYTT pass: övningen började om, historiken var borta och dagens tema
	valdes om från ingenting — fast ritten aldrig tog slut.

	`rittMarke` är serverns märke på den ritt lektionen hör till. Posten
	är EN och bär samma märke; ett annat märke är en annan ritt, och då
	ska passet vara nytt. Den konsumeras vid första uppslaget, så en
	återförening kan inte återanvändas en andra gång. ]]
local rittMarke: any = nil
local avbrutet: { marke: any, pass: any, tema: UgnetaTema.Tema?,
	lage: string }? = nil
local liveSagt = ""
local lage = "ingen"

--[[ ── G02-D: RITTEN SPELAS IN EN GÅNG ──────────────────────────────
     En inspelare per FÖRSÖK. Den startas när mätningen startar och stängs
     när försöket stängs — samma två ögonblick, inte två egna. Skulle de
     glida isär hade replayen visat en annan ritt än den som bedömdes, och
     då hade vi haft två sanningar om samma försök.

     `inspelningar` håller posterna per övning i den ordning de rids.
     Spöket i analysen är den NÄST sista i den listan: spelarens eget förra
     försök, aldrig en uppfunnen ideallinje.

     Bara de övningar som HAR en definition i kanonen spelas in
     (Inspelning.spelasIn). En post utan version går inte att jämföra mot
     något, och att stämpla den med en påhittad version vore precis den
     falska referens som är förbjuden. ]]
local inspelare: Inspelning.Recorder? = nil
local inspelningar: { [string]: { Inspelning.Post } } = {}
local senasteOvning: string? = nil

--[[ SPELARENS HANDLING. Registreras hos HUD:en i `start` och körs när
     knappen, tangenten eller gamepadknappen fyrar — HUD:en har redan
     stängt kortet när vi kommer hit, så det här är bara lifecyclen.

     `Lektion.vidare` ligger HÄR och inte direkt efter `avslutaForsok`:
     det är spelarens val som nollställer mätningen, vilket är precis vad
     provet kan mäta. ]]
--[[ Stänger den pågående inspelningen och lägger posten i historiken.
     Idempotent: ett andra anrop har ingen inspelare att stänga. En post
     utan sampel läggs INTE undan — en tom ritt är ingen ritt, och en tom
     post i listan hade blivit ett spöke utan väg. ]]
local function stangInspelning()
	local r = inspelare
	inspelare = nil
	if not r then return end
	local post = Inspelning.avsluta(r)
	if not post or #post.sampel == 0 then return end
	local lista = inspelningar[post.ovning]
	if not lista then lista = {}; inspelningar[post.ovning] = lista end
	table.insert(lista, post)
end

--[[ Startar en inspelning för det försök som just börjat mätas. Anropas
     varje bildruta men gör bara något första gången: finns redan en
     inspelare är försöket igång. ]]
local function startaInspelning(p: Lektion.Pass, tm: { [string]: any }?)
	if inspelare then return end
	local id = Lektion.ovningId(p)
	if not Inspelning.spelasIn(id) then
		--[[ ÖVNINGEN SPELAS INTE IN — och då ska det INTE gå att "se ritten".
		     `senasteOvning` måste nollas här, inte bara sättas när en
		     inspelning startar. Annars pekade den kvar på FÖRRA övningen, och
		     kortet efter en oinspelad övning erbjöd "Se ritten" som öppnade
		     någon annans ritt. Falsifieringen (`trav_skritt` avstängd) visade
		     det: knappen stod kvar, grön, med voltens post bakom sig. ]]
		senasteOvning = nil
		return
	end
	local hast = if type(tm) == "table" and type(tm.hast) == "string" then tm.hast else nil
	inspelare = Inspelning.ny(id :: string, hast)
	senasteOvning = id
end

--[[ Finns det en ritt att visa för den övning som just bedömdes? ]]
local function harRitt(): boolean
	local id = senasteOvning
	if not id then return false end
	local lista = inspelningar[id]
	return lista ~= nil and #lista > 0
end

--[[ SE RITTEN. Öppnar analysen på det senaste försöket med förra försöket
     som spöke. Ridningen fryses av init.client medan panelen är uppe —
     inte här: den här modulen äger lektionen, inte rörelsen. ]]
local function oppnaReplay()
	local id = senasteOvning
	if not id then return end
	local lista = inspelningar[id]
	if not lista or #lista == 0 then return end
	ReplayController.oppna(lista[#lista], if #lista > 1 then lista[#lista - 1] else nil)
end

local function fortsattning()
	local p = pass
	if not p then return end
	--[[ En ny mätning börjar. Inspelaren nollas HÄR, i samma handling som
	     nollställer mätningen, så att nästa försök spelas in från noll och
	     inte fortsätter i det förras post. ]]
	inspelare = nil
	if lage == "presentation" then
		lage = "rider"
	elseif lage == "efter" then
		local forra = p.ix
		Lektion.vidare(p)
		if p.klar then
			lage = "ingen"
			--[[ #244: PASSET ÄR SLUT, OCH DÅ STEGAS INGET MER.
			     `steg` returnerar direkt när passet är klart, och
			     bannerns visningstid räknas just där. Utan den här raden
			     hade den sista texten blivit stående för alltid — inte
			     för att någon visade den igen, utan för att ingen längre
			     räknade ned den. Det som stänger lektionen stänger
			     därför också dess yta. ]]
			UgnetaController.dolj()
		elseif p.ix == forra then
			--[[ SAMMA övning, nytt försök. Spelaren tryckte "Prova igen",
			     och det ÄR valet att börja om — att sedan visa samma
			     presentationskort igen vore ett andra klick för ett beslut
			     som redan är fattat. ]]
			lage = "rider"
		else
			--[[ Ny övning: den ska presenteras innan den rids. ]]
			lage = "ny"
		end
	end
	liveCd, liveSagt = 0, ""
end

--[[ Startar lektionen. `ridhus` är den byggda modellen; utan den finns
     ingen plats att ställa Ugneta på, och då körs lektionen ändå — HUD:en
     är inte beroende av gestalten. En saknad byggnad ska inte tysta
     undervisningen, bara gestalten. ]]
--[[ HÄSTEN SOM RIDS. Anropas av `init.client.mount` innan lektionen
     startar. `kontext` är riggens egna stats — `skygghet` och
     `dagsform` när de finns. Saknas de tiger `UgnetaTema` om hästens
     spänning i stället för att skylla på ryttaren. ]]
function LektionController.satHast(namn: string?, kontext: { [string]: any }?)
	hastNamn = namn or ""
	hastKontext = kontext
end

--[[ ── DAGSFORMEN FÅR KOMMA SENARE ─────────────────────────

	Re-review runda 2 av `f6ff67d`, blockerare 3.

	Servern sätter attributet `Dagsform` före `MountChanged` fyras. Det
	räcker inte: attributreplikering och en RemoteEvent är två olika
	kanaler, och deras inbördes ordning är inte garanterad hos mottagaren.
	Kom händelsen först läste `satHast` ett `nil`, och eftersom den bara
	lästes EN gång blev dagsformen okänd för hela ritten.

	Det syntes inte som ett fel. `hastensEgen` svarar `nil` på okänt och
	tiger — säkert, men tyst fel: hon hade aldrig sagt «det där kom från
	henne» även när det gjorde det.

	Den här vägen finns för att ta emot värdet NÄR det kommer, oavsett
	ordning. Den rör bara dagsformen; resten av kontexten står kvar. ]]
function LektionController.satDagsform(dagsform: number?)
	local k = hastKontext
	if k == nil then
		--[[ Ingen häst satt än. Ett värde utan häst hör ingenstans hemma
		     och ska inte bäras över till nästa. ]]
		return false
	end
	k.dagsform = dagsform
	return true
end

--[[ Läsprob för proven: vilken dagsform bär lektionens hästkontext just
     nu? Bara läsning — den kan inte ändra något, och den finns för att
     kedjan attribut → lyssnare → kontext annars bara går att mäta
     indirekt genom vad Ugneta råkar säga. ]]
function LektionController.dagsform(): number?
	local k = hastKontext
	return if k then k.dagsform else nil
end

function LektionController.start(ridhus: Instance?, marke: any)
	--[[ SAMMA RITT SOM NYSS REVS? Då fortsätter lektionen där den var.
	     Utan märke — fallet för varje anropare som inte vet om någon
	     ritt — blir det ett nytt pass, precis som förut.

	     `lage` sätts av grenarna och får INTE sättas om längre ner: ett
	     återupptaget pass ska tillbaka till SITT läge, inte till «ny»
	     med lektionskortet uppe igen. ]]
	local spar = avbrutet
	avbrutet = nil
	rittMarke = marke
	if spar ~= nil and marke ~= nil and spar.marke == marke
		and spar.pass ~= nil then
		pass = spar.pass
		tema = spar.tema
		lage = spar.lage
	else
		pass = Lektion.nyttPass()
		tema = nil
		lage = "ny"
	end
	liveCd, liveSagt = 0, ""
	inspelare = nil
	inspelningar = {}
	senasteOvning = nil
	UgnetaController.vidFortsatt(fortsattning)
	UgnetaController.vidReplay(oppnaReplay)
	--[[ GÅ VIDARE. Momentet är redan bedömt av `avslutaForsok`; det här
	     hoppar över omridningen, inte bedömningen. Lifecyclens regel ligger
	     i Lektion.hoppaOver — HUD:en flyttar inte passet själv. ]]
	UgnetaController.vidVidare(function()
		local p = pass
		if not p then return end
		inspelare = nil
		Lektion.hoppaOver(p)
		lage = if p.klar then "ingen" else "ny"
		--[[ Samma skäl som i `fortsattning` ovan: ett klart pass stegas
		     inte längre, så ytan måste stängas här. ]]
		if p.klar then UgnetaController.dolj() end
		liveCd, liveSagt = 0, ""
	end)
	UgnetaGestalt.visa(ridhus)
end

function LektionController.pagar(): boolean
	return pass ~= nil and not (pass :: Lektion.Pass).klar
end

function LektionController.pass(): Lektion.Pass?
	return pass
end

function LektionController.lage(): string
	return lage
end

--[[ Väntar lektionen på spelaren just nu? init.client frågar innan den
     tolkar tangenten, så att samma knapp kan betyda något annat när
     inget kort står uppe. ]]
function LektionController.vantar(): boolean
	return pass ~= nil and UgnetaController.vantar()
end

--[[ Spelaren gick vidare, via tangent eller gamepad. Musen och fingret
     går in genom knappens eget Activated. Returnerar false när det inte
     fanns någon väntan — då har tangenten inte betytt något här. ]]
function LektionController.fortsatt(): boolean
	if not pass then return false end
	return UgnetaController.fortsatt()
end

--[[ De två andra vägarna ut ur ett avslutat försök. Samma mönster som
     `fortsatt`: returnerar false när det inte fanns något val att göra, så
     att tangenten faller igenom till sin vanliga betydelse. ]]
function LektionController.replay(): boolean
	if not pass then return false end
	return UgnetaController.replay()
end

function LektionController.gaVidare(): boolean
	if not pass then return false end
	return UgnetaController.gaVidare()
end

--[[ Står analysen uppe? init.client fryser ridningen på den frågan — och
     frågar modulen, inte ett eget flaggvärde, så att det bara finns ett
     svar. ]]
function LektionController.replayAktiv(): boolean
	return ReplayController.aktiv()
end

--[[ Stänger analysen utan att röra kortet bakom den. Väntan är kvar: att
     ha SETT sin ritt är inte att ha valt vad som ska hända med den. ]]
function LektionController.stangReplay(): boolean
	if not ReplayController.aktiv() then return false end
	ReplayController.stang()
	return true
end

--[[ Presentationen av övningen. Kortet, men INTE mitt under ridningen:
     det visas innan försöket börjar och spelaren stänger det själv
     genom att starta.

     KNAPPEN SÄGER VAD DEN GÖR (produktbeslut 13:29). Den sa "Börja", och
     det räckte inte: ridloopen fryser hästen medan kortet väntar, så en
     spelare som satt upp och gav framåt möttes av en häst som inte rörde
     sig — utan att något förklarade varför. Lokal Studio-QA rapporterade
     det som ett rörelsefel i §9, och rotorsaken var det här kortet.

     Pausen står kvar; den skyddar försöket från att bli ogiltigt medan
     spelaren läser. Det som ändrats är att orsaken syns.

     Texten kommer dessutom ur SPRÅKKATALOGEN och inte som en svensk
     litteral i logiken. Den stod hårdkodad här, vilket gav en engelsk
     spelare ordet "Börja" — samma felklass som dörrarnas `ActionText`. ]]
local function presentera(p: Lektion.Pass)
	local o = Lektion.ovning(p)
	if not o then return end
	--[[ Rubriken och punkterna hämtas ur SPRÅKKATALOGEN, inte ur kanonens
	     svenska literaler. `RidKanon.OVNINGAR` är övningens sanning och rörs
	     inte; det som visas för spelaren är dess översatta yta.

	     Saknas nyckeln faller den tillbaka på kanonen, så en NY övning i
	     `src/larare.js` blir spelbar direkt i stället för att bli tom —
	     samma hållning som `Preparation.moment` har för en ny fas. ]]
	local ovId = Lektion.ovningId(p)
	local function kortText(del: string, reserv: string): string
		local nyckel = "ugneta.ovning." .. tostring(ovId) .. "." .. del
		if ovId and Sprak.finns(nyckel) then return Sprak.t(nyckel) end
		return reserv
	end
	local punkter = {}
	for i, reserv in ipairs(o.punkter) do
		punkter[i] = kortText("p" .. i, reserv)
	end
	UgnetaController.visa(kortText("rubrik", o.rubrik), punkter, true,
		Sprak.t("ugneta.borja_lektionen"))
	lage = "presentation"
end

--[[ ETT STEG. Anropas varje bildruta med ritt-telemetrin. ]]
function LektionController.steg(dt: number, tm: { [string]: any }?,
	pose: { [string]: any }?)
	local p = pass
	if not p or p.klar then return end
	UgnetaController.steg(dt)

	if lage == "ny" then
		presentera(p)
		return
	end

	--[[ VÄNTAN PÅ SPELAREN. Kortet står kvar, ingenting mäts, tiden växer
	     inte. Det är här den gamla timern satt, och det är därför
	     mätningen kunde börja innan ryttaren var redo. ]]
	if UgnetaController.vantar() then return end
	if lage ~= "rider" then return end

	if not tm or tm.uppsutten ~= true then return end

	--[[ Inspelningen ligger FÖRE mätningen och läser samma bildruta som
	     den. Att spela in efter `Lektion.matning` hade gett en post som
	     ligger en bildruta efter det som bedömdes. ]]
	startaInspelning(p, tm)
	Inspelning.sampla(inspelare, dt, tm, pose)

	p.tid += dt
	--[[ `dt` följer med: täckningen räknas i uppmätta sekunder, inte i
	     bildrutor, så en snabb klient inte får "mer underlag" än en
	     långsam på samma ritt. ]]
	Lektion.matning(p, tm, dt)

	--[[ ── LIVE: DAGENS TEMA, OCH TYSTNAD OM ALLT ANNAT ──────────────

		QA-review av `082062c`, blockerare 2. Förut låg spärren och
		«aldrig samma ord två gånger» här, och VALET av vad hon skulle
		säga gjordes om varje bildruta av `Lektion.liveCue` — den
		svagaste dimensionen just då. Hela regeln bor nu i `UgnetaTema`:
		ett tema, temafiltrerad signal, mönster före kommentar, spärr
		utan kö och hästens dag skild från ryttarens fel.

		Spärren räknas därför inte längre HÄR. Två spärrar hade betytt
		två sanningar om när hon får tala. ]]
	local kvalitet = Lektion.kvalitet(tm)
	local ovId = Lektion.ovningId(p)
	if tema == nil and ovId then
		tema = UgnetaTema.nytt(ovId)
	end
	local t = tema
	if t and ovId then
		local txt, bra, kalla = UgnetaTema.steg(t, dt, kvalitet,
			hastKontext, tonumber(tm.spanning), Ugneta.dimensionerFor(ovId))
		if txt ~= "" then
			--[[ Hästens rad byggs HÄR och inte i modulen: modulen är
			     delad med webben och ska inte kunna språkvägarna. Den
			     svarar med en KÄLLA, ytan väljer orden. ]]
			if kalla == "hast" then
				txt = Sprak.t("ugneta.hastens_dag"):format(
					if hastNamn ~= "" then hastNamn else Sprak.t("ugneta.hasten"))
			end
			liveSagt = txt
			UgnetaController.live(txt, bra)
		end
	end

	if p.tid < Lektion.FORSOK_SEK then return end

	--[[ FÖRSÖKET ÄR SLUT. Betyget hör till underlaget, inte till
	     lifecyclen: `avslutaForsok` lämnar medelvärdena och Ugneta
	     rangordnar dem. ]]
	--[[ Stäng försöket FÖRST. Betyget, kortet och replayen ska alla se
	     samma avslutade ritt — inte en som stängs en bildruta senare. ]]
	stangInspelning()
	local h = Lektion.avslutaForsok(p)
	if h then
		UgnetaController.efterForsok(h.ovningId, h.nu, h.fore, h.forsokNr, harRitt())
		lage = "efter"
	else
		--[[ INGET UNDERLAG → INGET OMDÖME, men spelaren får veta varför.
		     `avslutaForsok` ger nil när ingen dimension nådde kraven
		     (ryttaren satt aldrig upp, telemetrin uteblev, fälten var
		     ogiltiga). Att gissa fram ett omdöme hade blivit falskt
		     beröm eller falskt fel om en ritt som aldrig mättes — men att
		     bara tyst gå vidare vore obegripligt: hon såg ett försök ta
		     slut utan ett ord. Kortet säger därför exakt det som är
		     sant, varken mer eller mindre, och väntar på spelaren som
		     alla andra kort. ]]
		--[[ Ur katalogen, av samma skäl som presentationens knapp ovan:
			de här fyra strängarna stod hårdkodade på svenska i logiken. ]]
		UgnetaController.visa(Sprak.t("ugneta.ej_bedomd.rubrik"),
			{ Sprak.t("ugneta.ej_bedomd.punkt") },
			true, if p.forsokNr < 2 then Sprak.t("ugneta.prova_igen")
				else Sprak.t("ugneta.nasta_ovning"))
		lage = "efter"
	end
	liveCd, liveSagt = 0, ""
end

--[[ Slut på ritten, av vilket skäl som helst. Säkerhet före undervisning:
     chipet släcks, kortet stängs, den väntande fortsättningen kastas och
     gestalten tas bort. ]]
function LektionController.avbryt(skal: string?)
	--[[ ── EFTERRITTENS SUMMERING (Teaching Loop) ──────────────────

		Bara efter en avsittning spelaren själv bad om, och bara om det
		FINNS något att summera. En respawn, en riven rigg eller serverns
		egen rättelse ger tystnad — se skälet i `init.client.dismount`.

		QA-review av `082062c`, blockerare 1: summeringen VISADES här,
		och det var för tidigt. Den lokala rivningen sker med flit innan
		servern hunnit svara — säkerhet före undervisning — men servern
		kan NEKA avsittningen (`pass.rider_inte`, `hast.oregistrerad`,
		`takt.for_snabbt`). En nekad avsittning presenterades då ändå som
		en fullbordad ritt, och #234 kräver att summeringen följer en
		GILTIG auktoritativ övergång.

		Rivningen och undervisningens avslut är därför två saker nu. Den
		här funktionen river direkt och LÄMNAR TILLBAKA underlaget; den
		som vet om serverns svar blev ett ja anropar `visaEfterritt`.

		Att ta fram underlaget FÖRE rivningen är fortfarande nödvändigt:
		`pass` nollas tre rader ner, och då finns historiken inte kvar
		att summera. En ögonblicksbild överlever rivningen; en referens
		till `pass` hade inte gjort det. ]]
	local summering = Ugneta.efterrittFor(skal, if pass then pass.historik else nil)

	--[[ SPARAS FÖR EN EVENTUELL ÅTERFÖRENING. Se noten vid `avbrutet`.
	     Rivningen nedan sker oavsett — det här är en KOPIA av vad som
	     revs, inte ett skäl att låta bli att riva. ]]
	avbrutet = if pass ~= nil
		then { marke = rittMarke, pass = pass, tema = tema, lage = lage }
		else nil
	pass = nil
	tema = nil
	rittMarke = nil
	hastNamn, hastKontext = "", nil
	liveCd, liveSagt = 0, ""
	lage = "ingen"
	--[[ SÄKERHET FÖRE UNDERVISNING. Analysen stängs och inspelningen
	     kastas — en halv ritt som avbröts av en avsittning är inget att
	     spela upp, och panelen får aldrig bli kvar över ett ekipage som
	     inte finns. Posterna släpps med passet: de hörde till det. ]]
	ReplayController.stang()
	inspelare = nil
	inspelningar = {}
	senasteOvning = nil
	UgnetaController.vidFortsatt(nil)
	UgnetaController.vidReplay(nil)
	UgnetaController.vidVidare(nil)
	UgnetaController.sakerhetTarOver()
	UgnetaGestalt.dolj()

	--[[ Ytan är tom nu, och underlaget går tillbaka till anroparen
	     OVISAT. `begarAvsittning` håller det tills servern sagt ja. ]]
	return summering
end

--[[ SERVERN SA JA — då, och först då, får ritten ett avslut.

	Två eller tre punkter med en knapp att stänga med — samma yta, samma
	språkvägar och samma responsiva regler som varje annat Ugneta-besked.
	Ingen egen panel, inget nytt lektionssystem.

	`nil` är ett giltigt argument och betyder tystnad, så att anroparen
	kan skicka vidare det `avbryt` gav utan att först kontrollera det. ]]
function LektionController.visaEfterritt(summering)
	if summering then UgnetaController.efterritt(summering) end
end

return LektionController
