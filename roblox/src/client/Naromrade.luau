--!strict
--[[
	NÄROMRÅDET — en gemensam touchyta för allt man kan göra vid hästen.

	══ VARFÖR DEN FINNS (#235) ═══════════════════════════════════════

	Tobias verifierade på FYSISK iPhone att First Playable är ospelbart
	före ridning: sadel och träns går inte att hämta, hästen går inte att
	interagera med, och ledningen går därför inte att starta alls.

	Mätt i Studio med iPhone 13-emulering, spelaren 4,3 studs från sin
	egen hästs utrustning på boxfronten:

	    ProximityPromptService.PromptShown   0 gånger på 2 sekunder
	    prompter inom sin räckvidd           5 stycken

	      Boxdörr MB 7   "Open"                        2,5 st
	      Sadel          "Take the saddle and bridle"  4,3 st   ← den hon vill ha
	      Sadel          (en annan hästs)              6,7 st
	      Boxdörr E 7    "Open"                        7,2 st
	      hästen         "Ride now"                    8,4 st

	Två fel i samma bild. Prompterna RENDERAS inte i vår stack — och även
	när de gör det ska spelaren träffa rätt av fem flytande knappar som
	ligger i djupet, med tummen, på en telefon i landskap.

	══ VAD DEN HÄR FILEN GÖR, OCH INTE GÖR ═══════════════════════════

	Den ritar en LISTA över det som faktiskt går att göra där spelaren
	står, som riktiga knappar i skärmens plan, och trycker på spelarens
	vägnar på den prompt raden hör till.

	Den innehåller INGEN gameplaylogik. Inga remotes, ingen distans-
	prövning, ingen ägarskapskontroll, inga egna regler. Varje rad
	aktiverar `prompt:InputHoldBegin()` / `InputHoldEnd()` — promptens
	EGEN väg — så att serverns handlare, dess avståndskrav och dess
	nej:er gäller precis som förut. Tas en prompt bort försvinner raden;
	nekar servern syns nejet där nejen alltid synts.

	Det är skillnaden mot en "mobil gameplayväg": det finns ingen. Det
	här är en annan KNAPP till samma handling.

	══ VARFÖR INTE BARA FLYTTA PROMPTERNA ════════════════════════════

	För att trängseln är verklig och inte ett layoutfel: boxfronterna
	står tätt, och hästen, hennes utrustning och två boxdörrar ÄR nära
	varandra i verkligheten. `docs/ASSET-SOURCE-OF-TRUTH.md` och
	byggnadskorten säger var de står; att glesa ut dem för att en knapp
	ska bli lättare att träffa vore att flytta anläggningen för att lösa
	ett UI-problem, vilket `CLAUDE.md` uttryckligen förbjuder.

	══ BARA PEKSKÄRM, BARA TILL FOTS ═════════════════════════════════

	Skrivbord och handkontroll rörs inte: `start` returnerar direkt utan
	`TouchEnabled`. Och medan man rider äger `TouchControls` skärmen —
	då är närområdet släckt, för ridningens reglage har sina egna ytor
	och sin egen reserv.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Sprak = require(ReplicatedStorage.HorseCore.Sprak)
--[[ #246 E: skötselpanelens ruta, så att listan aldrig lägger sig över
     den. Ren avläsning — PreparationController äger måtten. ]]
local PreparationController = require(script.Parent.PreparationController)
--[[ #246 QA-blockerare: handlingarnas produktordning. Läses härifrån och
     skrivs inte av — se noten vid `handlingsrang`. ]]
local InteractionController = require(script.Parent.InteractionController)
--[[ #264: ridningens kärnrader när man sitter upp. Se `ritaRidhjalp`. ]]
local KontrollHjalp = require(script.Parent.KontrollHjalp)
--[[ #264: lektionens röst och val, som data. Se `UgnetaController.panel`. ]]
local UgnetaController = require(script.Parent.UgnetaController)
--[[ #264: pågår en lektion? Då står övningen i panelen uppsutten. ]]
local LektionController = require(script.Parent.LektionController)

local Naromrade = {}

--[[ ── MÅTTEN ──────────────────────────────────────────────────────

	44 px är golvet för en träffyta i `docs/KONTROLLMATRIS.md` regel 5.
	52 ger marginal och är samma höjd som ridningens egna knappar i
	`TouchControls`, så att de två ytorna känns som samma spel. ]]
--[[ Bläddringsraden är avsiktligt LÅG: den är en väg vidare, inte en
     handling, och ska inte konkurrera med raderna om blicken. ]]
local BLADDRA_H = 44
--[[ #264 PLAYER_INTERACTION_CONSOLIDATION: raderna är 44 px — kontraktets
     golv för en träffyta — och växer med radbruten text. Panelen är
     nominellt 300 px bred, 260–320 där det finns plats, och aldrig bredare
     än den användbara ytan. ]]
local KNAPP_H = 44
local KNAPP_B = 300
local PANEL_MIN = 260
local PANEL_MAX = 320
local LUFT = 6
local KANT = 16

--[[ EN PRIMÄR HANDLING OCH HÖGST TVÅ SEKUNDÄRA (#264 kontraktet). Fler
	relevanta handlingar nås genom panelens egen overflow-rad, inte genom
	fler rader och aldrig genom världsbubblor. ]]
local MAX_RADER = 3

--[[ Skötselns frågor och checklistor: högst fyra alternativ i blocket. ]]
local MAX_VAL = 4

--[[ Panelens ungefärliga fasta höjd utöver handlingsraderna: rubrik, nästa
     steg, återkoppling och hjälpraden med luft. Används för att hålla hela
     panelen inom 40 % av den användbara höjden. ]]
local PANEL_FAST = 150
--[[ #264 R2: den minsta användbara panelen — rubrikraden och en
     handlingsrad med panelens luft. Ryms den ovanför spaken står panelen
     kvar till vänster; resten bläddras inuti. ]]
local PANEL_MINSTA = 44 + KNAPP_H + 3 * LUFT + 20

--[[ Hur ofta listan räknas om. Tätare än så kostar utan att synas;
	glesare gör att en rad ligger kvar när man gått därifrån. ]]
local TAKT = 0.2

local gui: ScreenGui? = nil
local ram: Frame? = nil
local rader: { TextButton } = {}
local bladdra: TextButton? = nil
local koppling: RBXScriptConnection? = nil
local sedan = 0
local rider = false
local senaste: { ProximityPrompt } = {}
--[[ ── BLÄDDRINGEN (R3 P2) ──────────────────────────────────────────

     `sida` är vilken skärmfull av de relevanta handlingarna som står på
     raderna just nu, och `relevanta` är hela den sorterade mängden.

     Bakgrunden: listan visade så många den fick plats med och lät
     resten behålla Robloxs egna världsbubblor. Granskningen mätte
     `rows=5 nativeDoorPrompts=5` med tio dörrar — alltså precis den
     dubbla ytan ordern förbjöd, bara flyttad ett steg upp.

     Att i stället släcka det som inte fick plats vore den gamla
     dörr-regressionen igen: släckt utan rad är omöjligt att använda.
     Den tredje vägen är den här — allt relevant NÅS i listan, en sida i
     taget — och då får allt relevant också släckas. ]]
local sida = 1
local relevanta: { ProximityPrompt } = {}

--[[ ── PANELENS DELAR (#264 PLAYER_INTERACTION_CONSOLIDATION) ──────────

     `panelRam` är den enda ytan. `ram` (listan) ligger inuti den och bär
     handlingsraderna precis som förut — samma knappar, samma håll, samma
     tangentägarskap. Runt dem: rubriken, nästa steg, återkopplingen och
     hjälpen. `valRader[i]` är ett skötselval ur `PreparationController`
     när raden bär ett sådant i stället för en prompt. ]]
local panelRam: Frame? = nil
local rubrikEtikett: TextLabel? = nil
local stegEtikett: TextLabel? = nil
local aterEtikett: TextLabel? = nil
local hjalpKnapp: TextButton? = nil
local hjalpText: TextLabel? = nil
local hjalpUt = false
local valRader: { [number]: any } = {}
local valKnappar: { TextButton } = {}
local valYta: ScrollingFrame? = nil
local antalHandlingar = 0
local sistaInstruktion = ""
--[[ #264 GAIT_READABILITY_AND_UGNETA: den ridna hästens eget läge — gångart,
     målgångart och galoppsida — matat av ritloopen. Färskt eller inget. ]]
local ridLage: { [string]: any }? = nil
local ridLageTid = -math.huge
--[[ #246 C: prompter vars EGNA UI vi släckt, och stilen de hade innan.
     Nyckeln är prompten själv, så att en som försvinner ur världen tas
     med av skräpsamlaren utan att lämna en post efter sig. ]]
local slackta: { [ProximityPrompt]: any } = {}

--[[ Prompter som den här modulen håller stängda en bildruta medan
     stilen byts. Se `bytStil`. ]]
local dolda: { [ProximityPrompt]: boolean } = {}

--[[ Andra hästars prompter, som varken ska få en rad eller en bubbla.
     Fylls av `nara` och läses av `rita`. Se noten där. ]]
local bortvalda: { [ProximityPrompt]: boolean } = {}

--[[ Vad raden ska heta. Promptens egen `ActionText` är redan spelarens
	språk — den sätts av tjänsterna ur språkkanonen — och `ObjectText`
	säger vilken häst eller dörr det gäller. Två rader som annars vore
	identiska ("Öppna", "Öppna") blir åtskilda av objektet. ]]
--[[ ── ETIKETTEN SÄGER SAKEN EN GÅNG (#246 E) ─────────────────────────

	QA 2026-09-18 läste rader som `Take the saddle — Trixie saddle`. Ordet
	står två gånger, och den andra halvan bär bara EN ny upplysning:
	vems sadel det är.

	Regeln nedan tar bort de ord ur objektet som handlingen redan sagt, och
	behåller resten. `Trixie saddle` blir `Trixie`, `Trixies sadel` blir
	`Trixies`. Blir ingenting kvar — objektet sa inget nytt — utelämnas
	hela ledet.

	VARFÖR INTE RÄTTA `ObjectText` I TJÄNSTEN I STÄLLET: texten används
	också av Roblox egen prompt, där handlingen står på en EGEN rad och
	upprepningen därför inte finns. Att korta den där hade gjort prompten
	fattigare för att en lista har ont om plats. Sammanfogningen är listans
	problem, och löses här. ]]
local function ord(txt: string): { string }
	local ut = {}
	for o in string.gmatch(txt, "[^%s]+") do table.insert(ut, o) end
	return ut
end

--[[ Jämför på gemener och utan skiljetecken i kanten, så att "sadeln",
	"Sadeln" och "sadeln," räknas som samma ord. Böjningen tas INTE bort:
	"sadel" och "sadeln" är olika ord här, och att slå ihop dem hade krävt
	en stamform per språk — en regel som tyst börjar gissa. ]]
local function nyckelord(o: string): string
	return string.lower((string.gsub(o, "^[%p]*(.-)[%p]*$", "%1")))
end

function Naromrade.kortEtikett(handling: string, objekt: string?): string
	if objekt == nil or objekt == "" then return handling end
	local sagt = {}
	for _, o in ord(handling) do sagt[nyckelord(o)] = true end
	local kvar = {}
	for _, o in ord(objekt) do
		if not sagt[nyckelord(o)] then table.insert(kvar, o) end
	end
	if #kvar == 0 then return handling end
	return ("%s — %s"):format(handling, table.concat(kvar, " "))
end

--[[ Tangenten som faktiskt utlöser prompten, för den som spelar med
     tangentbord. Den läses ur prompten själv — ingen egen tabell som kan
     glida isär från det som verkligen gäller. `Unknown` betyder att
     prompten inte har någon tangent, och då står det ingen. ]]
local function tangenttext(p: ProximityPrompt): string?
	if not UserInputService.KeyboardEnabled then return nil end
	local ok, kod = pcall(function() return p.KeyboardKeyCode end)
	--[[ F15 är den döda tangenten — se `DODTANGENT`. Den står aldrig i en
	     etikett. Jämförs med namnet, för modulens konstant står längre ned. ]]
	if not ok or kod == nil or kod == Enum.KeyCode.Unknown then return nil end
	if typeof(kod) == "EnumItem" and kod.Name == "F15" then return nil end
	if kod == "F15" then return nil end
	--[[ NAMNET LÄSES FÖRSIKTIGT. I motorn är `KeyboardKeyCode` ett
	     `EnumItem` med `.Name`; provbänken modellerar `Enum.KeyCode.E`
	     som strängen «E». `tostring` på ett EnumItem ger
	     «Enum.KeyCode.E», vilket vore fel att visa för en spelare — så
	     formen prövas i stället för att antas. ]]
	if typeof(kod) == "EnumItem" then return kod.Name end
	if type(kod) == "string" and kod ~= "" then return kod end
	return nil
end

local function etikett(p: ProximityPrompt): string
	local handling = p.ActionText
	if handling == nil or handling == "" then handling = Sprak.t("interaktion.anvand") end
	local text = Naromrade.kortEtikett(handling, p.ObjectText)
	local tangent = tangenttext(p)
	--[[ ── EN HÅLL-GRIND SÄGS INNAN MAN MISSLYCKAS (#264 ROBLOX_HUMAN_PLAYTEST_FIX)

	     Speltest 2026-09-25: loggen saknar `LedBorja` helt. Mätt i Studio:
	     ett vanligt klick på raden «Lead» gav ingen `Triggered` — raden
	     börjar ett håll och klicket släpper det innan `HoldDuration`
	     (0,2 s för ledning, 0,35 s för uppsittning och Rida nu) gått.
	     Samma sak med ett kort tangenttryck.

	     Hållet är avsiktligt och står kvar; se noten vid `slappHall`. Men
	     motorns bubbla, som ritade hållringen, är borta när menyn ersätter
	     den — och då sa ingenting längre att man ska hålla. Raden säger det
	     nu själv, och `ritaFyllning` visar hur långt hållet kommit. ]]
	local hall = (p.HoldDuration or 0) > 0
	local hallOrd = if hall then Sprak.t("interaktion.hall_inne") else nil
	--[[ Tangenten sist och inom hakparenteser, så att den korta etiketten
	     fortfarande är det man läser först. ]]
	if tangent then
		text ..= "  [" .. (if hallOrd then hallOrd .. " " else "") .. tangent .. "]"
	elseif hallOrd then
		text ..= "  (" .. hallOrd .. ")"
	end
	return text
end

--[[ Var prompten sitter i världen. En prompt kan hänga i en `Attachment`
	lika gärna som i en `BasePart`; båda har ett världsläge, och utan den
	här skillnaden tappar listan varje prompt som sitter på en fästpunkt
	— till exempel uppsittningens, som hänger i sadelpunkten. ]]
local function varldslage(p: ProximityPrompt): Vector3?
	local f = p.Parent
	if f and f:IsA("BasePart") then return f.Position end
	if f and f:IsA("Attachment") then return f.WorldPosition end
	return nil
end

--[[ Allt spelaren kan göra just nu, närmast först.

	Ren funktion av världen och ett läge — inga instanser skapas — så att
	den går att mäta i bänken utan att någon GUI behöver finnas. ]]
--[[ ── VILKEN HÄST HÖR PROMPTEN TILL? (#246 D) ─────────────────────────

	Hästens rigg bär `HorseId` (satt av `HastRigg`), och boxfrontens förråd
	bär `ForHast` (satt av `TackForradService`). Uppslaget går uppåt i
	trädet från prompten och stannar vid det första svaret.

	Inget nytt attribut behövde införas, och ingen ny kanal: de två fanns
	redan, av andra skäl. Hittas inget är prompten inte hästbunden — en
	dörr, till exempel — och det är ett giltigt svar, inte ett fel. ]]
function Naromrade.hastFor(p: Instance): string?
	local nod: Instance? = p.Parent
	local varv = 0
	--[[ Sökningen stannar vid `workspace`. Ingenting ovanför roten kan
	     vara en häst eller ett förråd, och varvtaket är en enkel spärr mot
	     ett träd som av något skäl pekar i ring. ]]
	while nod ~= nil and nod ~= workspace and varv < 12 do
		local h = nod:GetAttribute("HorseId")
		if type(h) ~= "string" then h = nod:GetAttribute("ForHast") end
		if type(h) == "string" and h ~= "" then return h end
		nod = nod.Parent
		varv += 1
	end
	return nil
end

--[[ ── PRIORITERINGEN ÄR SEMANTISK, INTE BARA AVSTÅND (#246 D) ─────────

	QA 2026-09-18: listan fylldes av andra hästars sadlar och av dörrar,
	medan dagens hästs nästa steg trängdes undan. Avståndet ensamt räcker
	inte — boxfronterna står tätt, och grannens sadel kan mycket väl vara
	närmare än den egna.

	Tre klasser, i den ordning spelaren menar dem:

	    1  dagens häst och hennes utrustning
	    2  det som inte hör till någon häst — dörrar, och liknande
	    3  en ANNAN hästs utrustning

	Klass 3 tas bort helt så snart spelaren HAR en tilldelad häst: ordern
	är uttrycklig om att andra hästars sadlar inte får fylla listan. Har
	hon ingen tilldelad häst ännu står allt kvar — då vet spelet inte bättre
	än spelaren, och att gissa vore värre än att visa.

	Inom en klass gäller avståndet precis som förut. Dörrar försvinner
	alltså inte; de hamnar efter hästens steg i stället för före det. ]]
--[[ ── ALLT INOM RÄCKVIDD, UTAN URVAL ────────────────────────────────

	Touch-adaptern ÄGER promptbilderna i närområdet — inte bara bilderna
	för de handlingar den råkar få plats att rita en rad för. Den här
	funktionen svarar på den frågan, och bara den: vad ligger inom sin egen
	aktiveringsräckvidd just nu, närmast först.

	SKILD FRÅN URVALET MED FLIT. Vad som ligger inom räckvidd och vad som
	får en rad är två frågor, och `nara` svarar på den andra.

	── VAD SOM INTE LÄNGRE GÄLLER (rättelse #264) ──────────────────

	Här stod tidigare att ALLT inom räckvidd måste släckas, även det som
	filtreras bort eller blir overflow — annars skulle spelaren möta
	listan plus flytande knappar i djupet. Den slutsatsen var fel, och
	den kostade en spelbar dörr.

	En prompt som släcks utan att få en rad blir nämligen inte prydlig,
	den blir OSYNLIG OCH OANVÄNDBAR: `Style = Custom` tar bort Roblox
	egna knappar, och ritar vi ingen rad i stället finns ingen väg in.
	Tobias hittade det fysiskt — entrédörren gick inte att öppna.

	Regeln är därför: släck bara det du ERSÄTTER. Se rättelsen i `rita`. ]]
--[[ ── FÖRKANTEN (#264 ROBLOX_HUMAN_PLAYTEST_FIX) ─────────────────────

	Listan räknas om var `TAKT` sekund, men motorn visar en prompt i samma
	bildruta som den kommer inom räckvidd. I gapet däremellan hann den
	visas med Robloxs egen bubbla. Under gång längs stallgången mättes upp
	till tio samtidiga bubblor.

	Prompter som ligger strax UTANFÖR sin räckvidd släcks därför i förväg,
	utan rad och utan tangent. Det tar ingen affordans från spelaren:
	utanför räckvidd går prompten inte att använda ändå, och när den kommer
	in får den sin rad i samma takt som förut. `FORKANT` är några takter av
	gångfart (16 studs/s × 0,2 s ≈ 3,2 studs per takt). ]]
local FORKANT = 8

local function skanna(fran: Vector3, sok: { Instance }, kant: number):
	({ ProximityPrompt }, { ProximityPrompt }, { [ProximityPrompt]: number })
	local ut: { ProximityPrompt } = {}
	local fore: { ProximityPrompt } = {}
	local avstand: { [ProximityPrompt]: number } = {}
	for _, rot in ipairs(sok) do
		for _, d in ipairs(rot:GetDescendants()) do
			--[[ `dolda`: prompter den här modulen själv håller stängda en
			     bildruta medan stilen byts. De är inom räckvidd som förut. ]]
			if d:IsA("ProximityPrompt") and (d.Enabled or dolda[d]) then
				local p = varldslage(d)
				if p then
					local a = (p - fran).Magnitude
					if a <= d.MaxActivationDistance then
						table.insert(ut, d)
						avstand[d] = a
					elseif a <= d.MaxActivationDistance + kant then
						table.insert(fore, d)
					end
				end
			end
		end
	end
	table.sort(ut, function(a, b) return avstand[a] < avstand[b] end)
	return ut, fore, avstand
end

function Naromrade.iRackvidd(fran: Vector3, sok: { Instance }): { ProximityPrompt }
	local ut = skanna(fran, sok, 0)
	return ut
end

--[[ Prompterna strax utanför sin räckvidd. Se noten vid `FORKANT`. ]]
local forkant: { ProximityPrompt } = {}

--[[ EN DÖRR ÄR DÖRREN. Alla dörrprompter heter så — `DorrService` sätter
     namnet för både stalldörrar och boxdörrar. ]]
local function arDorr(p: ProximityPrompt): boolean
	return p.Name == "DorrPrompt"
end

--[[ Den dörr panelen senast visade, och hur mycket närmare en annan måste
     vara för att ta över. Se `sorterade`. ]]
local valdDorr: ProximityPrompt? = nil
local DORR_HYSTERES = 1.5

--[[ ── PRIORITERINGEN ÄR SEMANTISK, INTE BARA AVSTÅND (#246 D) ─────────

	QA 2026-09-18: listan fylldes av andra hästars sadlar och av dörrar,
	medan dagens hästs nästa steg trängdes undan. Avståndet ensamt räcker
	inte — boxfronterna står tätt, och grannens sadel kan mycket väl vara
	närmare än den egna.

	Tre klasser, i den ordning spelaren menar dem:

	    1  dagens häst och hennes utrustning
	    2  det som inte hör till någon häst — dörrar, och liknande
	    3  en ANNAN hästs utrustning

	Klass 3 tas bort helt så snart spelaren HAR en tilldelad häst: ordern
	är uttrycklig om att andra hästars sadlar inte får fylla listan. Har
	hon ingen tilldelad häst ännu står allt kvar — då vet spelet inte bättre
	än spelaren, och att gissa vore värre än att visa.

	Inom en klass gäller avståndet precis som förut: rangen kommer ur
	`iRackvidd`, som redan sorterat närmast först. Dörrar försvinner alltså
	inte; de hamnar efter hästens steg i stället för före det.

	URVALET STYR BÅDE RADERNA OCH SLÄCKNINGEN (rättelse #264). Raden här
	sa förut motsatsen — att urvalet styr raderna men inte vilka bilder
	som släcks. Det var det som gjorde dörren oanvändbar. Se noten ovan. ]]
--[[ SORTERINGEN UTAN TAKET. Bruten ut i R3: listan bläddrar numera, och
     då måste den veta vad som finns bortom första sidan. `nara` är kvar
     precis som förut — sorteringen plus taket — så allt som redan
     anropar den får samma svar. ]]
function Naromrade.sorterade(fran: Vector3, sok: { Instance },
	minHast: string?): { ProximityPrompt }
	local alla, fore, avstand = skanna(fran, sok, FORKANT)
	forkant = fore
	--[[ Nollställs per urval: en häst som gått ur räckvidd ska inte ligga
	     kvar som bortvald och hållas släckt i evighet. ]]
	table.clear(bortvalda)
	local rang: { [ProximityPrompt]: number } = {}
	for i, d in ipairs(alla) do rang[d] = i end

	local ut: { ProximityPrompt } = {}
	local klass: { [ProximityPrompt]: number } = {}
	for _, d in ipairs(alla) do
		local h = Naromrade.hastFor(d)
		local k = if h == nil then 2
			elseif minHast ~= nil and h == minHast then 1
			elseif minHast == nil then 2
			else 3
		--[[ En annan hästs utrustning får ingen RAD när spelaren har en
		     egen — och sedan R2 ingen BUBBLA heller.

		     Kommentaren här sa «dess bild släcks ändå», men det slutade
		     gälla när släckningen kopplades till urvalet i stället för
		     räckvidden. Granskningen mätte följden: `rows=1
		     unselectedDefaultPrompts=6` — listan PLUS väggen.

		     Bortvalda hästars prompter bokförs därför här, och `rita`
		     släcker dem. Det är inte samma sak som den gamla regressionen
		     med oåtkomliga dörrar: det här är handlingar som inte gäller
		     spelaren alls, och de blir varken rad eller bubbla MED
		     AVSIKT. Det som är relevant men inte fick plats behåller sin
		     bubbla, precis som invarianten kräver. ]]
		if k ~= 3 then
			table.insert(ut, d)
			klass[d] = k
		else
			bortvalda[d] = true
		end
	end
	--[[ ── RIDE FIRST GÄLLER OCKSÅ I LISTAN (#246 QA-blockerare) ──────

		Inom en klass avgjorde AVSTÅNDET ensamt, och det räckte inte.
		Trixies sadel och träns hänger närmare spelaren än hästens egen
		ridknapp, så "Rida nu" hamnade fjärde av fem — och på en telefon,
		där två eller tre rader ryms, föll den bort helt. Eftersom
		touch-ytan äger promptbilderna var den då varken rad eller knapp.

		Produktordningen finns redan accepterad i `InteractionController`:
		uppsittning överst, genvägen dit i mitten, den frivilliga omsorgen
		underst. Den läses därifrån. Avståndet avgör fortfarande INOM samma
		handlingsrang — två dörrar sorteras som förut. ]]
	local handling: { [ProximityPrompt]: number } = {}
	for _, d in ipairs(ut) do
		handling[d] = InteractionController.handlingsrang(d.Name)
	end
	table.sort(ut, function(a, b)
		if klass[a] ~= klass[b] then return klass[a] < klass[b] end
		if handling[a] ~= handling[b] then return handling[a] < handling[b] end
		return rang[a] < rang[b]
	end)
	--[[ ── HÖGST EN DÖRR (#264 ROBLOX_HUMAN_PLAYTEST_FIX) ──────────────

		Speltestet 2026-09-25 visade fyra identiska «Open — Door [X]» på
		rad, och alla fyra delade tangenten X. Stallgången har en boxdörr
		på varje sida om varje box, så i gången ligger alltid flera inom
		räckhåll — och raderna går inte att skilja åt, för ObjectText är
		«Door» på alla.

		Ordern: visa högst EN aktuell dörr, den närmaste. Den behåller
		både rad och tangent. De andra blir varken rad, bubbla eller
		tangent — samma behandling som en annan hästs sak — och den som
		vill öppna en av dem går fram till den, varpå den blir närmast.
		Dörrarna sorterades nyss på avstånd inom sin klass, så den första
		som påträffas är den närmaste. ]]
	--[[ ── STABILT VAL (#264 PLAYABLE_UI_AND_DISMOUNT_R2) ───────────────
		Den närmaste dörren bytte varje bildruta för den som stod mitt
		emellan två: raden blinkade mellan två «Öppna — Dörr» som inte går
		att skilja åt, och ett håll kunde avbrytas av bytet. Den dörr som
		redan är vald behålls så länge den är inom räckhåll och inte mer än
		`DORR_HYSTERES` studs längre bort än den närmaste. ]]
	local narmast: ProximityPrompt? = nil
	for _, d in ipairs(ut) do
		if arDorr(d) then narmast = d break end
	end
	local vald = narmast
	local forra = valdDorr
	if narmast and forra and forra ~= narmast and avstand[forra] ~= nil
		and table.find(ut, forra) ~= nil
		and avstand[forra] <= avstand[narmast] + DORR_HYSTERES then
		vald = forra
	end
	valdDorr = vald
	local i = 1
	while i <= #ut do
		local d = ut[i]
		if arDorr(d) and d ~= vald then
			table.remove(ut, i)
			bortvalda[d] = true
			continue
		end
		i += 1
	end
	return ut
end

--[[ Sorteringen plus taket. Taket klipps EFTER sorteringen: det spelaren
     menar får aldrig trängas bort av något som råkade hittas först. ]]
function Naromrade.nara(fran: Vector3, sok: { Instance },
	minHast: string?, tak: number?): { ProximityPrompt }
	local ut = Naromrade.sorterade(fran, sok, minHast)
	local n = math.max(1, math.min(tak or MAX_RADER, MAX_RADER))
	while #ut > n do table.remove(ut) end
	return ut
end

local function nyKnapp(i: number): TextButton
	local b = Instance.new("TextButton")
	b.Name = "Rad" .. i
	--[[ Full panelbredd, 44 px och uppåt: raden växer med radbruten text i
	     stället för att krympa typsnittet. Fasta storlekar, ingen
	     viewportskalning (#264 kontraktet). ]]
	b.Size = UDim2.new(1, 0, 0, KNAPP_H)
	b.AutomaticSize = Enum.AutomaticSize.Y
	b.LayoutOrder = i
	b.BackgroundColor3 = Color3.fromRGB(38, 41, 47)
	b.BackgroundTransparency = 0.1
	b.TextColor3 = Color3.fromRGB(236, 232, 222)
	b.Font = Enum.Font.GothamMedium
	b.TextSize = 14
	b.TextScaled = false
	b.TextWrapped = true
	b.TextXAlignment = Enum.TextXAlignment.Left
	b.AutoButtonColor = false
	b.BorderSizePixel = 0
	b.Visible = false
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.PaddingTop = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 6)
	pad.Parent = b
	local golv = Instance.new("UISizeConstraint")
	golv.MinSize = Vector2.new(0, KNAPP_H)
	golv.Parent = b
	local horn = Instance.new("UICorner")
	horn.CornerRadius = UDim.new(0, 6)
	horn.Parent = b
	--[[ HÅLLET SYNS (#264 ROBLOX_HUMAN_PLAYTEST_FIX). Motorns bubbla ritade
	     en ring som fylldes medan man höll; menyn ersätter bubblan och
	     ritar därför själv hur långt hållet kommit. Se `ritaFyllning`. ]]
	local fyll = Instance.new("Frame")
	fyll.Name = "Fyllning"
	fyll.Size = UDim2.fromScale(0, 1)
	fyll.BackgroundColor3 = Color3.fromRGB(236, 196, 92)
	fyll.BackgroundTransparency = 0.7
	fyll.BorderSizePixel = 0
	fyll.Visible = false
	fyll.Parent = b
	local fyllHorn = Instance.new("UICorner")
	fyllHorn.CornerRadius = UDim.new(0, 6)
	fyllHorn.Parent = fyll
	return b
end

--[[ TRYCKET GÅR GENOM PROMPTENS EGEN VÄG. Ingen genväg till servern,
	ingen kopia av handlaren: `InputHoldBegin` är exakt vad en tangent
	eller ett tryck på promptens egen knapp gör, och `HoldDuration`
	respekteras därför precis som förut. ]]
--[[ ── ETT HÅLL ÄR ETT HÅLL, INTE EN TIMER ───────────────────────────

	Här stod `InputHoldBegin` följt av `task.delay(HoldDuration + 0.05)`
	som avslutade hållet OBEROENDE av att spelaren släppte — och hela
	saken startade på `MouseButton1Click`, som i sin tur fyrar när musen
	SLÄPPS. Ett kort klick blev alltså en fullbordad håll-handling, och
	det fanns ingen väg att ångra sig.

	Det är fel på två sätt. Spelaren kunde inte avbryta genom att släppa,
	och hon kunde utlösa en håll-grind utan att hålla. Grinden finns för
	att vissa handlingar ska kräva ett medvetet ögonblick.

	Nu är livscykeln verklig: NED börjar hållet, UPP eller att markören
	lämnar knappen avslutar det, och motorn avgör själv om
	`HoldDuration` hanns med. Nollduration är oförändrad — där utlöser
	`InputHoldBegin` direkt, precis som en tangenttryckning.

	Tappas målet, går det ur räckvidd eller rivs ytan släpps hållet
	också — se `provaHallet` nedan, som `rita` kallar, och
	`slappHall` i `stopp`.

	DEN HÄR NOTEN LJÖG I EN GRANSKNINGSRUNDA. Den beskrev släppet vid
	tappat mål som om det fanns, och `rita` gjorde ingenting alls åt
	ett pågående håll. Ett finger som låg kvar på en knapp medan
	spelaren red iväg höll alltså kvar en prompt som inte längre var
	inom räckhåll, och hade den nått sin `HoldDuration` hade den
	utlösts från andra sidan stallet. Nu gör den det noten sa. ]]
local hallsPrompt: ProximityPrompt? = nil
--[[ VILKEN RAD trycket kom ifrån. Utan den är ett håll bara «någon
     prompt», och raden under fingret kan bytas ut medan hållet pågår —
     se `provaHallet`. ]]
local hallRad: number? = nil

--[[ Vilken prompt som laddas just nu, och sedan när — för fyllningen i
     raden. Sätts av radens eget håll OCH av motorns hållhändelser, så att
     ett håll på tangenten syns lika väl som ett håll på raden. ]]
local fyllPrompt: ProximityPrompt? = nil
local fyllStart = 0
local hallKopplingar: { RBXScriptConnection } = {}

local function ritaFyllning()
	for i, b in ipairs(rader) do
		local f = b:FindFirstChild("Fyllning")
		if f and f:IsA("Frame") then
			local p = senaste[i]
			if p ~= nil and p == fyllPrompt and b.Visible then
				local langd = math.max(p.HoldDuration or 0, 0.01)
				local andel = math.clamp((os.clock() - fyllStart) / langd, 0, 1)
				f.Size = UDim2.fromScale(andel, 1)
				f.Visible = true
			elseif f.Visible then
				f.Visible = false
				f.Size = UDim2.fromScale(0, 1)
			end
		end
	end
end

local function slappHall()
	local p = hallsPrompt
	hallsPrompt = nil
	hallRad = nil
	if fyllPrompt == p then fyllPrompt = nil end
	if p ~= nil and p.Parent ~= nil then
		pcall(function() p:InputHoldEnd() end)
	end
end

--[[ ── HÅLLET SITTER I EN RAD, INTE I EN LISTA ─────────────────────

	Föregångaren hette `slappTappatHall` och prövade bara att den hållna
	prompten fanns KVAR NÅGONSTANS i `senaste`. Granskningen visade vad
	som glappade: raderna är återanvända knappar, och nästa ritning kan
	ge rad 1 en helt annan prompt utan att den gamla lämnat listan.

	    REVIEW_REORDER row1NowB=true stillHoldingA=true

	Knappen under fingret visade då B medan A fortfarande höll på att
	laddas. Spelaren såg en handling och höll på en annan — och en
	hålltid som gick i mål hade utlöst den hon inte läste.

	Identiteten är alltså tryck → RAD → PROMPT, inte tryck → prompt. Står
	inte samma prompt kvar på SAMMA rad är hållet inte längre det spelaren
	började, och då avbryts det. Eftersom `InputHoldEnd` bara utlöser när
	`HoldDuration` hunnit gå blir ett avbrutet håll INGEN handling. ]]
local function provaHallet()
	local p = hallsPrompt
	if p == nil then return end
	--[[ En riven prompt ska inte skrivas på — bara glömmas. ]]
	if p.Parent == nil then
		hallsPrompt = nil
		hallRad = nil
		return
	end
	if hallRad == nil or senaste[hallRad] ~= p then
		slappHall()
	end
end

--[[ Släpp bara det håll som började på DEN HÄR raden. ]]
local function slappHallFran(rad: number)
	if hallRad ~= rad then return end
	slappHall()
end

local function borjaHall(p: ProximityPrompt, rad: number)
	if p == nil or p.Parent == nil or not p.Enabled then return end
	--[[ Ett håll i taget. Hinner ett nytt börja innan det förra släppts
	     avslutas det förra först, annars läcker vi en öppen hållning. ]]
	slappHall()
	hallsPrompt = p
	hallRad = rad
	if (p.HoldDuration or 0) > 0 then
		fyllPrompt = p
		fyllStart = os.clock()
	end
	p:InputHoldBegin()
end

--[[ ── EN INTERAKTIONSYTA, INTE TVÅ (#246 C) ──────────────────────────

	QA 2026-09-18: `UBRFNaromrade` visade upp till fem skärmknappar SAMTIDIGT
	som Roblox egna prompt-knappar renderades för samma handlingar. Två ytor
	för samma sak, och den ena ligger i djupet där tummen inte når.

	Lösningen rör inte aktiveringen. `Style = Custom` släcker Robloxs
	inbyggda UI och INGENTING annat — `InputHoldBegin`, `HoldDuration`,
	avståndskravet och serverns handlare är oförändrade. Prompten förblir
	den auktoritära vägen; det är bara dess bild som tas bort, och bara på
	de prompter listan själv ritar en rad för.

	ÅTERSTÄLLNINGEN ÄR HALVA REGELN. En prompt som glidit ur listan måste få
	tillbaka sin bild, annars blir den osynlig för den som går därifrån och
	sedan kommer tillbaka utan lista — till exempel när ridningen tar över
	skärmen. Stilen den hade sparas därför undan, och sätts tillbaka.

	SKRIVBORD OCH HANDKONTROLL RÖRS INTE: hela modulen startar aldrig utan
	`TouchEnabled`, så ingenting här kan nå en PC-spelare. ]]
--[[ STILEN SPARAS I EN TABELL, INTE RAKT AV.

	`slackta[p] = p.Style` såg riktigt ut och lagrade ingenting: en
	tilldelning av `nil` tar bort nyckeln. Registret blev därför tomt,
	`tandIgen` hittade aldrig något att återställa, och varje prompt
	släcktes om på nytt varje bildruta utan att någonsin tändas.

	Provet fångade det direkt — `_slackta()` svarade 0 medan stilen
	bevisligen var satt. En inpackad post kan aldrig vara nil, och
	därmed kan medlemskapet i registret inte glida isär från stilen det
	bär. ]]
--[[ ══ STILEN BYTS MEDAN PROMPTEN ÄR DOLD (#264 ROBLOX_HUMAN_PLAYTEST_FIX) ══

	Tobias speltest 2026-09-25: listan OCH Robloxs världsbubblor samtidigt,
	för samma handlingar. Mätt i Studio samma dag, stående vid Blackrock
	Jacks box med sju prompter inom räckvidd:

	    alla sju            Style = Custom
	    motorns bubblor     7 BillboardGui, Enabled, 4 synliga barn var

	Motorn ritar bubblan när prompten VISAS, i den stil den har då. Att
	byta till `Custom` efteråt river inte en bubbla som redan står — och
	den här modulen byter alltid efteråt, upp till en takt (0,2 s) efter
	att prompten kommit inom räckvidd. Isolerat, med listan avstängd:

	    Custom satt medan bubblan syns      bubblan står kvar
	    dold, Custom satt, visad igen       ingen bubbla

	Därför döljs prompten runt bytet. `Enabled` sätts lokalt och
	replikeras inte; serverns prompt och dess handlare är orörda.
	Återställningen går samma väg, av samma skäl åt andra hållet.

	EN BILDRUTA MELLAN, INTE NOLL. Mätt i Studio med bubblan redan uppe:

	    av, byt stil, på — i samma bildruta     bubblan står kvar
	    av, byt stil, en Heartbeat, på          bubblan borta

	Motorn ser bara läget vid bildrutans slut; en prompt som stängts och
	öppnats inom samma bildruta har för den aldrig varit dold. Återöppningen
	väntar därför en Heartbeat. Under tiden står prompten i `dolda`, så att
	skanningen fortfarande räknar den som inom räckvidd — annars föll den ur
	urvalet i nästa takt och tändes igen. `dolda` deklareras högst upp,
	för skanningen läser den. ]]
local function oppnaNastaBildruta(p: ProximityPrompt)
	dolda[p] = true
	local k: RBXScriptConnection? = nil
	k = RunService.Heartbeat:Connect(function()
		if k then k:Disconnect() end
		if dolda[p] then
			dolda[p] = nil
			if p.Parent ~= nil then p.Enabled = true end
		end
	end)
end

local function bytStil(p: ProximityPrompt, stil: Enum.ProximityPromptStyle)
	if p.Style == stil then return end
	if p.Enabled or dolda[p] then
		p.Enabled = false
		p.Style = stil
		oppnaNastaBildruta(p)
	else
		p.Style = stil
	end
end

--[[ ══ EN TANGENT, EN MOTTAGARE (#264 ROBLOX_HUMAN_PLAYTEST_FIX) ═══════

	`Style = Custom` tar Robloxs rityta och INGENTING annat — tangenten
	lever kvar på varje prompt motorn visar. Loggen från speltestet:

	    05:47:10.882  tog Blackrock Jacks sadel
	    05:47:10.882  fick INTE Bränntomts Lydias sadel: tack.bar_redan_annan

	Ett G, två mottagare, samma millisekund. Reproducerat i Studio med
	en riktig tangenttryckning: `PromptTriggered` fyrade för BÅDA
	sadlarna. Att grannens prompt var släckt spelade ingen roll.

	Tangenten tas därför bort lokalt från varje prompt som inte ÄGER den.
	Utan tangent reagerar motorn inte på tangenten, men
	`InputHoldBegin` från listan fungerar som förut — raden är fortfarande
	en väg in. Originalet sparas i posten och sätts tillbaka. ]]
local function satTangenter(p: ProximityPrompt, tangent: Enum.KeyCode,
	knapp: Enum.KeyCode)
	pcall(function()
		if p.KeyboardKeyCode ~= tangent then p.KeyboardKeyCode = tangent end
	end)
	pcall(function()
		if p.GamepadKeyCode ~= knapp then p.GamepadKeyCode = knapp end
	end)
end

local function lasTangent(p: ProximityPrompt, falt: string): Enum.KeyCode
	local ok, v = pcall(function() return (p :: any)[falt] end)
	if ok and v ~= nil then return v end
	return Enum.KeyCode.Unknown
end

--[[ ══ ETT TRYCK PÅ SKÄRMEN, EN MOTTAGARE (#264 PLAYER_INTERACTION_CONSOLIDATION) ══

	Mätt i Studio, iPad-emulering, med tangenterna redan tysta: ETT tryck på
	panelens rad utlöste tre prompter samtidigt —

	    SadelPrompt @Bränntomts Lydia   Custom  key=None  ClickablePrompt=true
	    DorrPrompt  @Anläggning         Custom  key=None  ClickablePrompt=true
	    SadelPrompt @Garnit Parasido    Custom  key=None  ClickablePrompt=true

	— och servern loggade två grannsadlar som nekades, precis det tangent-
	rättelsen skulle ha stoppat.

	ORSAKEN VAR INTE KLICKBARHETEN. Med `ClickablePrompt = false` utlöstes
	de fortfarande. Det som öppnade vägen var tangenten `Unknown`, som motorn
	behandlar som «vilken inmatning som helst» — se `DODTANGENT`. Klick-
	barheten stängs ändå, som ett andra lager: en släckt prompt har ingen
	bild att klicka på, och panelens rader aktiverar med `InputHoldBegin`,
	som klickbarheten inte rör. Originalet sparas och sätts tillbaka. ]]
local function satKlickbar(p: ProximityPrompt, v: boolean)
	pcall(function()
		if p.ClickablePrompt ~= v then p.ClickablePrompt = v end
	end)
end

local function slack(p: ProximityPrompt)
	if slackta[p] ~= nil then return end
	local klick = true
	pcall(function() klick = p.ClickablePrompt ~= false end)
	slackta[p] = { stil = p.Style,
		tangent = lasTangent(p, "KeyboardKeyCode"),
		knapp = lasTangent(p, "GamepadKeyCode"),
		klick = klick }
	satKlickbar(p, false)
	bytStil(p, Enum.ProximityPromptStyle.Custom)
end

local function aterstall(p: ProximityPrompt, post: any)
	--[[ En prompt som lämnat världen ska inte skrivas på. ]]
	if p.Parent == nil then return end
	satTangenter(p, post.tangent, post.knapp)
	satKlickbar(p, post.klick ~= false)
	bytStil(p, post.stil)
end

local function tandIgen(p: ProximityPrompt)
	local post = slackta[p]
	if post == nil then return end
	slackta[p] = nil
	aterstall(p, post)
end

local function tandAllaIgen()
	for p, post in pairs(slackta) do
		aterstall(p, post)
	end
	table.clear(slackta)
end

--[[ Tangenterna delas ut efter listans ordning: den första prompten med
     en viss tangent äger den, alla andra blir tysta på just den tangenten.
     Det som inte är relevant alls — andra hästars saker, dörrar utöver den
     närmaste, förkanten — blir tyst på alla. Allt som släckts har en post
     i `slackta`, och originalet läses därifrån. ]]
--[[ ══ DEN DÖDA TANGENTEN (#264 PLAYER_INTERACTION_CONSOLIDATION) ═══════

	Tyst betydde först `Unknown`. Mätt i Studio, iPad-emulering: en prompt
	med `KeyboardKeyCode = Unknown` svarar på VILKEN inmatning som helst —
	ett pektryck mitt i 3D-vyn, utan någon GUI under, utlöste dörren E 5.
	Samma prompt med F15 lät trycket passera. Tystnaden öppnade alltså en
	väg för fingret, och panelens egna rader slog igenom till grannens sadel.

	Tyst är därför en tangent ingen trycker: F15. Den står aldrig i en
	etikett (`tangenttext`), och originalet sätts tillbaka som förut. ]]
local DOD = Enum.KeyCode.F15
Naromrade.DODTANGENT = DOD

local function harTangent(k: Enum.KeyCode?): boolean
	return k ~= nil and k ~= Enum.KeyCode.Unknown and k ~= DOD
end

local function delaUtTangenter(ordning: { ProximityPrompt },
	tysta: { [ProximityPrompt]: boolean })
	local tagnaT: { [Enum.KeyCode]: boolean } = {}
	local tagnaK: { [Enum.KeyCode]: boolean } = {}
	for _, p in ipairs(ordning) do
		local post = slackta[p]
		if post then
			local t = post.tangent
			local k = post.knapp
			if harTangent(t) and not tagnaT[t] then
				tagnaT[t] = true
			else
				t = DOD
			end
			if harTangent(k) and not tagnaK[k] then
				tagnaK[k] = true
			else
				k = DOD
			end
			satTangenter(p, t, k)
		end
	end
	for p in pairs(tysta) do
		if slackta[p] then
			satTangenter(p, DOD, DOD)
		end
	end
end

--[[ Provets fönster in. ]]
function Naromrade._slackta(): number
	local n = 0
	for _ in pairs(slackta) do n += 1 end
	return n
end

--[[ FRAMÅTDEKLARERAD. Bläddringsknappen i `bygg` ritar om listan, och
     `rita` står längre ned — utan den här raden slöt knappen om en
     GLOBAL `rita` som var nil, och första trycket kraschade. ]]
local rita: () -> ()

local function bygg()
	if gui then return end
	local spelare = Players.LocalPlayer
	local mapp = spelare:FindFirstChildOfClass("PlayerGui")
	if not mapp then return end

	local g = Instance.new("ScreenGui")
	g.Name = "UBRFNaromrade"
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = false
	--[[ Över Roblox egna pekreglage (0) och över skötselpanelen (10), så
		att listan aldrig hamnar under något som inte är en handling.
		Under hjälpknappen (16), som ska gå att nå alltid. ]]
	g.DisplayOrder = 14
	g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	g.Parent = mapp
	gui = g

	--[[ ══ EN PANEL (#264 PLAYER_INTERACTION_CONSOLIDATION) ══════════════

		Tobias 2026-09-25: separata handlingsknappar OCH en instruktions-
		bubbla, igen. Kontraktet: EN kompakt panel som bär hästen, nästa
		steg och handlingen som utför det — uppifrån och ned:

		    rubrik        hästen en gång, och läget
		    nästa steg    en kort mening
		    handlingar    en primär, högst två sekundära, overflow
		    återkoppling  kvittens, nej, väntan
		    hjälp         fälls ut INUTI panelen

		En mörk, genomskinlig yta; den varma accenten bara på den primära
		handlingen och på hållets fyllning. Inga nästlade kort. Nere till
		vänster, ankrad i nederkanten och växer uppåt — platsen räknas i
		`rita` ur den yta som faktiskt är ledig. ]]
	local pn = Instance.new("Frame")
	pn.Name = "Panel"
	pn.AnchorPoint = Vector2.new(0, 1)
	pn.Size = UDim2.fromOffset(KNAPP_B, 0)
	pn.AutomaticSize = Enum.AutomaticSize.Y
	pn.Position = UDim2.new(0, KANT, 1, -KANT)
	pn.BackgroundColor3 = Color3.fromRGB(24, 27, 33)
	pn.BackgroundTransparency = 0.12
	pn.BorderSizePixel = 0
	pn.Visible = false
	pn.Parent = g
	local horn = Instance.new("UICorner")
	horn.CornerRadius = UDim.new(0, 8)
	horn.Parent = pn
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.PaddingTop = UDim.new(0, 10)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.Parent = pn
	local lista = Instance.new("UIListLayout")
	lista.FillDirection = Enum.FillDirection.Vertical
	lista.SortOrder = Enum.SortOrder.LayoutOrder
	lista.Padding = UDim.new(0, LUFT)
	lista.Parent = pn
	local tak = Instance.new("UISizeConstraint")
	tak.Name = "Tak"
	tak.Parent = pn
	panelRam = pn

	local function etikettYta(namn: string, ordning: number, storlek: number,
		fet: boolean): TextLabel
		local t = Instance.new("TextLabel")
		t.Name = namn
		t.LayoutOrder = ordning
		t.Size = UDim2.new(1, 0, 0, 0)
		t.AutomaticSize = Enum.AutomaticSize.Y
		t.BackgroundTransparency = 1
		t.TextColor3 = Color3.fromRGB(236, 232, 222)
		t.Font = if fet then Enum.Font.GothamBold else Enum.Font.Gotham
		t.TextSize = storlek
		t.TextScaled = false
		t.TextWrapped = true
		t.TextXAlignment = Enum.TextXAlignment.Left
		t.Text = ""
		t.Parent = pn
		return t
	end
	--[[ RUBRIKRADEN bär hästen, läget och hjälpens `?` — hjälpen tar ingen
	     egen rad i panelen, bara en träffyta på 44 px i rubrikens hörn. ]]
	local rr = Instance.new("Frame")
	rr.Name = "RubrikRad"
	rr.LayoutOrder = 1
	rr.BackgroundTransparency = 1
	rr.Size = UDim2.new(1, 0, 0, 0)
	rr.AutomaticSize = Enum.AutomaticSize.Y
	rr.Parent = pn
	local rub = etikettYta("Rubrik", 1, 16, true)
	rub.Size = UDim2.new(1, -(KNAPP_H + 4), 0, 0)
	rub.Parent = rr
	rubrikEtikett = rub
	stegEtikett = etikettYta("Steg", 2, 14, false)

	--[[ SKÖTSELNS FRÅGA RULLAR I SIN EGEN SEKTION när den inte ryms inom
	     40 % av höjden — kontraktet: långa svarslistor rullar utan att
	     dölja kärnhandlingen. Handlingsraderna under den (Rida nu, dörren,
	     ledningen) står fast och syns alltid. Höjden sätts i `placera`. ]]
	local vl = Instance.new("ScrollingFrame")
	vl.Name = "Fragan"
	vl.LayoutOrder = 3
	vl.BackgroundTransparency = 1
	vl.BorderSizePixel = 0
	vl.ScrollBarThickness = 4
	vl.ScrollingDirection = Enum.ScrollingDirection.Y
	vl.AutomaticCanvasSize = Enum.AutomaticSize.Y
	vl.CanvasSize = UDim2.new(0, 0, 0, 0)
	vl.Size = UDim2.new(1, 0, 0, 0)
	vl.Visible = false
	vl.Parent = pn
	local vlista = Instance.new("UIListLayout")
	vlista.FillDirection = Enum.FillDirection.Vertical
	vlista.SortOrder = Enum.SortOrder.LayoutOrder
	vlista.Padding = UDim.new(0, LUFT)
	vlista.Parent = vl
	valYta = vl
	for j = 1, MAX_VAL do
		local b = nyKnapp(j)
		b.Name = "FraganVal" .. j
		b.Parent = vl
		--[[ ETT SKÖTSELVAL är ett tryck, inte ett håll — samma som knappen
		     i `PreparationController` var. Handlingen är dess egen `skicka`. ]]
		b.Activated:Connect(function()
			local v = valRader[j]
			if v and v.aktiv and type(v.skicka) == "function" then v.skicka() end
		end)
		valKnappar[j] = b
	end

	local f = Instance.new("Frame")
	f.Name = "Lista"
	f.LayoutOrder = 4
	f.BackgroundTransparency = 1
	f.Size = UDim2.new(1, 0, 0, 0)
	f.AutomaticSize = Enum.AutomaticSize.Y
	f.Parent = pn
	local radlista = Instance.new("UIListLayout")
	radlista.FillDirection = Enum.FillDirection.Vertical
	radlista.SortOrder = Enum.SortOrder.LayoutOrder
	radlista.Padding = UDim.new(0, LUFT)
	radlista.Parent = f
	ram = f

	for i = 1, MAX_RADER do
		local b = nyKnapp(i)
		b.Parent = f
		--[[ NED börjar, UPP och att markören lämnar knappen avslutar.
		     `MouseButton1Click` fyrar först vid släpp och duger därför
		     inte till att STARTA ett håll. ]]
		b.MouseButton1Down:Connect(function()
			local p = senaste[i]
			if p then borjaHall(p, i) end
		end)
		--[[ ETT SLÄPP FRÅN EN ANNAN RAD ÄR INTE VÅRT. Signalerna kommer
		     från knappar som alla lever hela tiden; ett `MouseLeave` som
		     hinner efter att ett nytt håll börjat på en annan rad skulle
		     annars avsluta det nyare hållet. ]]
		b.MouseButton1Up:Connect(function() slappHallFran(i) end)
		b.MouseLeave:Connect(function() slappHallFran(i) end)
		rader[i] = b
	end

	--[[ OVERFLOW, INUTI PANELEN. Samma knapptyp och samma yta som raderna;
	     den fyrar på ett vanligt klick — att bläddra är inget man ska
	     behöva hålla inne. ]]
	local v = nyKnapp(0)
	v.Name = "Bladdra"
	v.LayoutOrder = 99
	v.Visible = false
	v.Parent = f
	v.MouseButton1Click:Connect(function()
		slappHall()
		--[[ Sidan går runt: sista sidan leder tillbaka till den första,
		     annars kräver den att spelaren vet att hon ska gå tillbaka —
		     och det finns ingen bakåtknapp. ]]
		local platser = Naromrade.radplatser()
		local sidor = if platser > 0
			then math.max(1, math.ceil(antalHandlingar / platser)) else 1
		sida = if sida >= sidor then 1 else sida + 1
		rita()
	end)
	bladdra = v

	aterEtikett = etikettYta("Aterkoppling", 5, 14, false)
	aterEtikett.TextColor3 = Color3.fromRGB(236, 196, 92)
	aterEtikett.Visible = false

	--[[ HJÄLPEN FÄLLS UT I PANELEN, inte i ett eget fönster. ]]
	local hk = Instance.new("TextButton")
	hk.Name = "Hjalp"
	hk.AnchorPoint = Vector2.new(1, 0)
	hk.Position = UDim2.new(1, 0, 0, 0)
	hk.Size = UDim2.fromOffset(KNAPP_H, KNAPP_H)
	hk.BackgroundTransparency = 1
	hk.TextColor3 = Color3.fromRGB(170, 172, 176)
	hk.Font = Enum.Font.GothamBold
	hk.TextSize = 16
	hk.AutoButtonColor = false
	hk.Text = "?"
	--[[ Den läsbara frasen hänger på knappen, som skötselns `?` gjorde. ]]
	hk:SetAttribute("Etikett", Sprak.t("panel.hjalp"))
	hk.Parent = rr
	hk.MouseButton1Click:Connect(function()
		hjalpUt = not hjalpUt
		rita()
	end)
	hjalpKnapp = hk
	hjalpText = etikettYta("HjalpText", 6, 14, false)
	hjalpText.TextColor3 = Color3.fromRGB(190, 192, 196)
	hjalpText.Visible = false
end

--[[ ── HUR MÅNGA RADER RYMS? (#246 E) ──────────────────────────────────

	Listan och skötselpanelen bor i SAMMA hörn, nere till vänster. Panelen
	är ankrad i nederkanten och växer uppåt med sitt innehåll — upp till
	52 % av skärmhöjden. QA 2026-09-18 såg dem ligga över varandra.

	Taket räknas därför ur den plats som FAKTISKT är ledig ovanför panelen,
	inte ur ett fast tal. Måtten kommer från den som äger dem
	(`PreparationController.interaktionsruta`), av samma skäl som
	`TouchControls.reglageBredd` finns: två moduler som räknar samma layout
	glider isär, och glidningen syns först som ett överlapp på en telefon.

	Räknat på kanonens provskärmar, med en panel på 150 px:

	    1180x820  iPad landskap   ledigt 654  -> 5 rader (taket)
	    1080x810  iPad landskap   ledigt 644  -> 5 rader
	     810x1080 iPad porträtt   ledigt 914  -> 5 rader
	     844x390  iPhone landskap ledigt 224  -> 3 rader
	     568x320  liten telefon   ledigt 154  -> 2 rader

	MINST EN RAD, alltid. En skärm som inte rymmer någonting är fortfarande
	en skärm spelaren ska kunna handla på, och nödvändiga handlingar måste
	förbli åtkomliga — då är det panelen som får dela plats, inte listan som
	försvinner. Prioriteringen i `nara` gör att den enda raden är rätt rad. ]]
--[[ ── ROBLOXS VÄNSTRA RÖRELSEKONTROLL, SOM YTA ─────────────────────

	Uppmätt 2026-09-24 i Studios enhetsemulator, regular 1179×819:

	    DynamicThumbstickUIModifier  ImageButton  -100,254  572×607
	    ThumbstickStart              ImageLabel     58,575  148×148
	    JumpButton                   ImageButton  1009,551  120×120

	Hela närområdesknappen (16,445..206,497) låg INUTI den första. Den
	träffytan är fem gånger större än den synliga spaken, och den är en
	`ImageButton` med `InputSink.Activate` — alltså dokumenterat sväljande.
	Vår egen rad är en `TextButton`, också `Activate`. Två sväljande ytor
	på exakt samma pixlar.

	NAMNET ANVÄNDS INTE. `DynamicThumbstickFrame` är inget dokumenterat
	barnnamn, och en rättelse som hänger på det går sönder tyst den dag
	Roblox döper om det. Ytan läses i stället på det som ÄR dokumenterat:
	`PlayerGui.TouchGui` är den container dokumentationen själv pekar ut
	när den visar hur man placerar sig relativt hoppknappen, och
	`GuiButton` är den dokumenterade formen för «sväljer aktiverings-
	trycket» (`InputSink` har `Activate` som standard just där).

	Vi tar alltså varje SYNLIG `GuiButton` i den containern vars mitt
	ligger i skärmens vänstra halva, och unionen av deras rektanglar är
	ytan listan ska hålla sig undan. Inga namn, ingen `CoreGui`, ingen
	enhetsmodell.

	`AbsolutePosition` är insetrelativ — samma rymd som vår egen ram,
	eftersom båda ytorna har `IgnoreGuiInset = false`. De går därför att
	jämföra rakt av. ]]
--[[ Har vi någonsin sett en rörelsekontroll? Se noten vid fallbacken. ]]
local kontrollSedd = false

local RESERV_B = 0.42   -- andel av bredden, när kontrollträdet saknas
local RESERV_H = 0.70   -- andel av höjden, räknat från nederkanten

--[[ Latchen är sessionslång med flit, så provbänken måste kunna nollställa
     den mellan block. Samma mönster som `_satRutaForProv` och
     `_glomSessionForProv`: en uttryckligt provmärkt väg, inte en publik
     knapp som produktionskoden kan råka trycka på. ]]
function Naromrade._glomKontrollForProv()
	kontrollSedd = false
end

--[[ Returnerar reservatet som `{x1, y0}`: högerkanten och överkanten i
     gui-pixlar. Resten av rektangeln är ointressant — listan bor nere
     till vänster, så det är bara de två kanterna den kan väja för. ]]
function Naromrade.rorelseytan(): (number, number)
	local g = gui
	local bredd = if g and g.AbsoluteSize then g.AbsoluteSize.X else 0
	local hojd = if g and g.AbsoluteSize then g.AbsoluteSize.Y else 0
	if bredd <= 0 or hojd <= 0 then return 0, math.huge end

	local spelare = Players.LocalPlayer
	local pg = spelare and spelare:FindFirstChildOfClass("PlayerGui")
	local tg = pg and pg:FindFirstChild("TouchGui")
	--[[ ── VAD SOM RÄKNAS SOM «REGLAGEN ÄR I SPEL» ────────────────────

	     Första versionen lät `kontrollSedd` bli sann först när en
	     `GuiButton` KÄNTS IGEN. Fallbacken som ska täcka «trädet finns
	     inte än eller har ändrats» krävde alltså att igenkänningen en
	     gång lyckats — cirkulärt. Känns formen aldrig igen, för att
	     spelaren valt ett annat rörelseläge eller för att Roblox bytt
	     klass, startade reservatet aldrig.

	     Signalen är därför att `TouchGui` FINNS, oberoende av om jag kan
	     tolka innehållet. Det skiljer de tre fallen åt på riktigt:

	       trädet finns, formen känd      -> den uppmätta rektangeln
	       trädet finns, formen okänd     -> reservat ur viewporten
	       trädet finns men är släckt     -> inget reservat; det är vad
	                                         `ModalEnabled` ger, och vi
	                                         gör det själva under ritt
	       inget träd, aldrig sett        -> skrivbord och bänk, orört
	       inget träd, sett tidigare      -> reservat; det försvann just nu ]]
	local tgPa = tg ~= nil and tg.Enabled ~= false
	if tgPa then kontrollSedd = true end
	local hittade = false
	local x1, y0 = 0, math.huge
	--[[ #264 PLAYER_INTERACTION_CONSOLIDATION: ridningens EGEN spak
	     (`HorseTouch.Spak`) är också en rörelsekontroll. Panelen bor kvar
	     medan man rider och får inte täcka den. ]]
	local ht = pg and pg:FindFirstChild("HorseTouch")
	local spak = ht and ht:FindFirstChild("Spak")
	if spak and spak:IsA("GuiObject") and spak.Visible
		and (ht :: any).Enabled ~= false then
		local a, b = spak.AbsolutePosition, spak.AbsoluteSize
		if a and b and b.X > 0 and b.Y > 0 then
			hittade = true
			x1 = math.max(x1, a.X + b.X)
			y0 = math.min(y0, a.Y)
		end
	end
	if tgPa then
		for _, d in ipairs(tg:GetDescendants()) do
			if d:IsA("GuiButton") and d.Visible then
				local a, b = d.AbsolutePosition, d.AbsoluteSize
				if b.X > 0 and b.Y > 0 and (a.X + b.X * 0.5) < bredd * 0.5 then
					hittade = true
					x1 = math.max(x1, a.X + b.X)
					y0 = math.min(y0, a.Y)
				end
			end
		end
	end
	if hittade then return x1, y0 end
	--[[ Trädet finns men formen känns inte igen — då gäller reservatet. ]]
	if tg ~= nil and not tgPa then return 0, math.huge end

	--[[ ── FALLBACK, OCH VARFÖR DEN ÄR LÅST TILL EN IAKTTAGELSE ──────

	     Kontrollträdet kan saknas av tre helt olika skäl, och de får inte
	     behandlas lika:

	       1. det har ännu inte byggts, eller försvann en bildruta,
	       2. Roblox har ändrat strukturen så att vi inte känner igen den,
	       3. det finns inte på den här ytan alls — skrivbordet, och
	          provbänken, där `TouchEnabled` kan vara satt utan att någon
	          rörelsekontroll existerar.

	     Ett rent `TouchEnabled`-villkor blandar ihop 3 med 1 och 2, och
	     reserverar då en tredjedel av skärmen för en kontroll som aldrig
	     kommer. Första versionen gjorde precis det och tog kapaciteten
	     från listan i bänken: sju mätningar föll, bland dem «radkapaciteten
	     är 2» som blev 1.

	     Därför latchen: vi reserverar bara när vi FAKTISKT sett en
	     rörelsekontroll den här sessionen. Då täcker fallbacken fall 1 och
	     2 — kontrollen finns, vi ser den bara inte just nu — medan fall 3
	     lämnar listan orörd. Andelarna kommer ur mätningen ovan
	     (472/1179 ≈ 0,40 i sidled, 254/761 ≈ 0,33 uppifrån) med marginal. ]]
	if not kontrollSedd then return 0, math.huge end
	return bredd * RESERV_B, hojd * (1 - RESERV_H)
end

function Naromrade.radplatser(): number
	local g = gui
	local h = if g and g.AbsoluteSize then g.AbsoluteSize.Y else 0
	if h <= 0 then return MAX_RADER end
	--[[ NOLL ÄR ETT GILTIGT SVAR sedan #264: finns ingen användbar plats
	     ska listan inte visas alls, och Robloxs egna prompter stå kvar.
	     `rita` läser det och släcker ytan. ]]
	local x, golv = Naromrade.blockplats()
	if x == nil or golv == nil then return 0 end
	--[[ #264 PLAYER_INTERACTION_CONSOLIDATION: hela panelen — rubrik, nästa
	     steg, återkoppling och hjälp (`PANEL_FAST`) plus raderna — ska rymmas
	     ovanför golvet OCH inom 40 % av höjden. Minst en rad, alltid. ]]
	local ledigt = math.min(golv - KANT, h * 0.4) - PANEL_FAST
	local n = math.floor(ledigt / (KNAPP_H + LUFT))
	return math.clamp(n, 1, MAX_RADER)
end

--[[ ── VAR BLOCKET FÅR BO ──────────────────────────────────────────

	Två villkor, och de kan inte slås ihop: skötselpanelen bor i samma
	hörn och växer uppåt, och Robloxs rörelsekontroll ligger över samma
	pixlar. Golvet är det lägsta av dem.

	VÄJER I SIDLED FÖRST NÄR DET INTE GÅR UPPÅT. Att lyfta blocket över
	kontrollen är den minsta ändringen och håller listan där spelaren
	letar efter den. Ryms inte ens EN rad där flyttas blocket i stället
	till höger om kontrollens högerkant och får sin nederkant tillbaka —
	hellre en läsbar rad på ovanlig plats än en rad som inte går att
	trycka på. Regeln «minst en rad, alltid» står kvar. ]]
--[[ ── VAR BLOCKET FÅR BO — ETT SVAR, INTE TVÅ ─────────────────────

	Returnerar vänsterkant och golv, eller `nil` när ingen användbar rad
	ryms. Tre försök i tur och ordning:

	  1. OVANFÖR kontrollen, i vänsterkanten. Minsta ändringen och där
	     spelaren letar.
	  2. BREDVID den — men bara om HELA raden får plats innanför den
	     användbara bredden. Första versionen returnerade `ytaX1 + LUFT`
	     utan högergräns: med användbar bredd 390 och en kontroll till
	     x = 250 blev det 258, och raden slutade på 448 — 58 px utanför
	     skärmen. Att i stället klampa x tillbaka hade skjutit in knappen
	     i rörelseytan igen, alltså bytt ett fel mot det andra.
	  3. INGEN RAD. Då lämnas Robloxs egna prompter tända, och det är den
	     verkliga aktiveringsvägen — modulen har den redan.

	«MINST EN RAD, ALLTID» GÄLLER INTE LÄNGRE OVILLKORLIGT, och det är
	ett medvetet brott mot den gamla noten. Regeln skrevs mot
	skötselpanelen, där ett överlapp bara är trångt. Mot rörelsekontrollen
	är en överlappande rad oanvändbar och en rad utanför skärmen är värre
	än ingen: båda ser ut som en handling men går inte att trycka på.
	Mot panelen gäller regeln oförändrat. ]]
function Naromrade.blockplats(): (number?, number?)
	local g = gui
	local b = if g and g.AbsoluteSize then g.AbsoluteSize.X else 0
	local h = if g and g.AbsoluteSize then g.AbsoluteSize.Y else 0
	if h <= 0 then return KANT, 0 end
	local ruta = PreparationController.interaktionsruta()
	--[[ Rutan står i skärmens absoluta rum; listan ritar i sitt eget.
	     Se noten där rutan sparas i `PreparationController`. ]]
	local egenY = 0
	local ap = g and (g :: any).AbsolutePosition
	if ap ~= nil and type(ap.Y) == "number" then egenY = ap.Y end
	local panelgolv = if ruta and ruta.y0 then math.min(h, ruta.y0 - egenY) else h
	local ytaX1, ytaY0 = Naromrade.rorelseytan()
	if ytaY0 >= h then return KANT, panelgolv end

	--[[ ── PANELEN STANNAR TILL VÄNSTER (#264 PLAYABLE_UI_AND_DISMOUNT_R2) ──

	     Förra rättelsen krävde att HELA panelen rymdes ovanför spaken och
	     flyttade den annars i sidled — till mitten av bilden, framför häst
	     och ryttare (mätt i Studio, iPad Air: x = 501 av 1179). Ordern:
	     panelen står kvar till vänster och det som inte ryms bläddras eller
	     rullas INUTI den ytan.

	     Villkoret är därför den minsta panel som går att använda — rubriken
	     och en handlingsrad. Panelens höjd begränsas sedan till det som
	     finns ovanför spaken (`placera`, `radplatser`). Sidledsvalet står
	     kvar som sista utväg för en skärm där inte ens det ryms. ]]
	local tak = math.min(ytaY0, panelgolv)
	if tak - KANT >= PANEL_MINSTA then return KANT, tak end

	local x = math.max(KANT, ytaX1 + LUFT)
	if b > 0 and x + KNAPP_B <= b - KANT then return x, panelgolv end

	return nil, nil
end

--[[ Kvar som läsbara namn för proven och för `rita`. ]]
function Naromrade.blockgolv(): number
	local _, golv = Naromrade.blockplats()
	return golv or 0
end

function Naromrade.blockvanster(): number
	local x = Naromrade.blockplats()
	return x or KANT
end

--[[ ── PANELENS PLATS (#264 PLAYER_INTERACTION_CONSOLIDATION) ─────────

	Nere till vänster, ankrad i nederkanten: golvet är det lägsta av
	skärmens kant och rörelsekontrollens överkant (`blockplats`). Bredden är
	nominellt 300 px, 260–320 där det finns plats, och aldrig bredare än den
	användbara ytan. Höjden tak 40 % av skärmen — det som inte ryms bläddras
	eller rullas inuti panelen, aldrig utanför. ]]
local function placera(pn: Frame)
	local g = gui
	local bredd = if g and g.AbsoluteSize then g.AbsoluteSize.X else 0
	local hojd = if g and g.AbsoluteSize then g.AbsoluteSize.Y else 0
	local x, golv = Naromrade.blockplats()
	local ledigt = if bredd > 0 then bredd - (x or KANT) - KANT else KNAPP_B
	local b = math.clamp(KNAPP_B, PANEL_MIN, PANEL_MAX)
	if ledigt < b then b = math.max(ledigt, 120) end
	pn.Size = UDim2.fromOffset(b, 0)
	local botten = math.min(golv or hojd, hojd) - KANT
	--[[ #264 R2, MÄTT I STUDIO: panelen får aldrig gå ovanför skärmen.
	     I pekläge ligger den dynamiska spakens aktiveringsyta från ungefär
	     en tredjedel av höjden och nedåt; med verkliga radhöjder och en
	     fråga uppe var panelen 300 px men bara ~195 fanns ovanför, och
	     överkanten hamnade på −89. Panelen står då uppe till vänster med sin
	     egen höjd (högst 40 %) och får gå ned i den övre delen av den
	     osynliga aktiveringsytan — den synliga spaken i nedre hörnet täcks
	     inte, och panelen ligger över spakytan i ritordningen. ]]
	local egenH = 0
	local as = (pn :: any).AbsoluteSize
	if as ~= nil and type(as.Y) == "number" then egenH = as.Y end
	if hojd > 0 then
		botten = math.max(botten, math.min(egenH, hojd * 0.4))
	end
	pn.Position = UDim2.fromOffset(x or KANT, math.max(0, botten))
	--[[ LISTANS HÖJD: det som blir kvar av 40 % när rubrik, nästa steg,
	     återkoppling och en utfälld hjälp tagit sitt. Innehållet mäts ur
	     layouten när motorn har räknat den; i bänken, där ingen layoutmotor
	     finns, räknas synliga rader. Aldrig under en rad — kärnhandlingen
	     ska alltid synas. ]]
	--[[ Svarssektionens höjd: det som blir kvar av 40 % när rubriken, nästa
	     steg, de fasta handlingsraderna, återkopplingen och en utfälld hjälp
	     tagit sitt. Handlingsraderna står fast — de rullar aldrig bort. ]]
	local vl = valYta
	if vl and vl.Visible and hojd > 0 then
		local function h(o: any): number
			if o and o.Visible and o.AbsoluteSize then return o.AbsoluteSize.Y + LUFT end
			return 0
		end
		local rr = rubrikEtikett and rubrikEtikett.Parent
		local fast = 20 + h(rr) + h(stegEtikett) + h(ram) + h(aterEtikett) + h(hjalpText)
		local lay = vl:FindFirstChildOfClass("UIListLayout")
		local innehall = lay and (lay :: any).AbsoluteContentSize
		local behov = if innehall and innehall.Y then innehall.Y else 0
		if behov <= 0 then
			local n = 0
			for _, vb in ipairs(valKnappar) do if vb.Visible then n += 1 end end
			behov = n * (KNAPP_H + LUFT)
		end
		--[[ #264 R2: taket är det som FINNS — 40 % av höjden, men aldrig mer
		     än utrymmet ovanför golvet (spaken i pekläge). Panelen stannar
		     till vänster och frågan rullar i stället. ]]
		local takH = hojd * 0.4
		local budget = math.max(KNAPP_H, takH - fast)
		--[[ Minst två alternativ syns när det finns plats: en fråga med ett
		     synligt svar ser ut som en ensam knapp. Är ytan trång syns ett
		     och ett halvt — halvan visar att sektionen rullar. ]]
		local golvVal = math.min(behov, 2 * KNAPP_H + LUFT, math.max(math.floor(KNAPP_H * 1.5), budget))
		vl.Size = UDim2.new(1, 0, 0, math.clamp(behov, golvVal, math.max(golvVal, budget)))
	end
end

--[[ Rubrikens läge — hästen EN gång, sedan läget. Står hästens namn redan i
     lägestexten («Gå till Blackrock Jack») skrivs det inte två gånger. ]]
local function rubrikFor(hastnamn: string?, lage: string?): string
	local l = lage or ""
	if hastnamn == nil or hastnamn == "" then return l end
	if l == "" then return hastnamn end
	if string.find(l, hastnamn, 1, true) then return l end
	return hastnamn .. "  ·  " .. l
end

local function stegLista(steg: { any }): string
	local ut = {}
	for _, s in ipairs(steg) do
		local tecken = if s.klar then "✓" elseif s.paTur then "•" else "·"
		table.insert(ut, tecken .. "  " .. tostring(s.namn))
	end
	return table.concat(ut, "\n")
end

local function visaHjalp(text: string)
	local hk, ht = hjalpKnapp, hjalpText
	if not (hk and ht) then return end
	hk.Visible = text ~= ""
	ht.Text = text
	ht.Visible = hjalpUt and text ~= ""
end

local function visaAterkoppling(text: string?)
	local a = aterEtikett
	if not a then return end
	a.Text = text or ""
	a.Visible = text ~= nil and text ~= ""
end

--[[ ── RUBRIK, NÄSTA STEG, ÅTERKOPPLING ──────────────────────────────────

	Ur skötselns adapter (`PreparationController.panel`). En kvittens eller
	ett nej står i återkopplingsfältet; nästa steg står kvar ovanför i
	stället för att skrivas över. Utan tilldelning: ett ärligt besked. ]]
local function fyllText(data: any, minHast: string?, hastnamn: string?)
	local lage: string
	local steg = ""
	local ater: string? = nil
	if data == nil or minHast == nil then
		lage = Sprak.t("hud.vantar_pa_hast")
	else
		lage = data.rubrik or ""
		if PreparationController.kontext() == "ledning" then
			lage = Sprak.t("panel.leder")
		end
		if data.totalt and data.totalt > 0 and data.lage ~= "raknat" then
			lage ..= ("  ·  %d/%d"):format(data.klara or 0, data.totalt)
		end
		if data.aterkoppling then
			ater = data.text
			steg = sistaInstruktion
		else
			steg = data.text or ""
			sistaInstruktion = steg
		end
	end
	if rubrikEtikett then rubrikEtikett.Text = rubrikFor(hastnamn, lage) end
	if stegEtikett then
		stegEtikett.Text = steg
		stegEtikett.Visible = steg ~= ""
	end
	visaAterkoppling(ater)
	visaHjalp(if data then stegLista(data.steg or {}) else "")
end

rita = function()
	local f = ram
	local pn = panelRam
	if not f or not pn then return end
	local spelare = Players.LocalPlayer
	local karaktar = spelare.Character
	local rot = karaktar and karaktar:FindFirstChild("HumanoidRootPart")
	local data = PreparationController.panel()
	local hastnamn = if data then data.hastnamn else nil

	--[[ ── UPPSUTTEN ────────────────────────────────────────────────────

		Stallhandlingarna försvinner; panelen bär gångarten och ridningens
		kärna ur `KontrollHjalp` — samma tabell och samma reglagetext som
		bindningarna. Ingen rad är en knapp här: handlingarna har sina
		riktiga reglage, tangenterna och ridreglagen till höger, och
		panelen säger bara vilka. Motorns bubblor får tillbaka sin bild, men
		ridningens prompter är av när man sitter upp. ]]
	if rider then
		slappHall()
		senaste = {}
		table.clear(valRader)
		if valYta then valYta.Visible = false end
		antalHandlingar = 0
		for _, b in ipairs(rader) do b.Visible = false end
		tandAllaIgen()
		local bl = bladdra
		if bl then bl.Visible = false end
		local modell = nil
		local minHast = PreparationController.hastId()
		for _, d in ipairs(workspace:GetChildren()) do
			if d:IsA("Model") and minHast ~= nil and d:GetAttribute("HorseId") == minHast then
				modell = d
				break
			end
		end
		local gang = modell and modell:GetAttribute("Gait")
		--[[ Nycklarna utskrivna, en per gångart: språkgrinden läser dem ur
		     källan, och en sammansatt nyckel går inte att pröva. ]]
		local GANGART = {
			halt = Sprak.t("gangart.halt"), walk = Sprak.t("gangart.walk"),
			trot = Sprak.t("gangart.trot"), canter = Sprak.t("gangart.canter"),
			gallop = Sprak.t("gangart.gallop"),
		}
		--[[ #264 GAIT_READABILITY_AND_UGNETA: gångart och sits, kort. Den
		     ridna hästens eget läge (`ridlage`) går före attributet: det
		     vet om en övergång pågår och vilken sida galoppen går på.
		     Under övergång «Skritt till trav», efter etablering «Trav ·
		     lättridning (assisterad)». Okänd galoppsida skrivs inte ut. ]]
		local lage = if ridLage and os.clock() - ridLageTid < 0.6 then ridLage else nil
		if lage and type(lage.gait) == "string" then gang = lage.gait end
		local gangText = if type(gang) == "string" and GANGART[gang]
			then GANGART[gang] else Sprak.t("hud.du_rider")
		local mal = lage and lage.targetGait
		if type(gang) == "string" and type(mal) == "string" and mal ~= gang
			and GANGART[gang] and GANGART[mal] and mal ~= "halt" and gang ~= "halt" then
			gangText = Sprak.t("gangart.byte", GANGART[gang], string.lower(GANGART[mal]))
		elseif gang == "trot" then
			gangText = gangText .. "  ·  " .. Sprak.t("sits.lattridning")
		elseif (gang == "canter" or gang == "gallop") and lage and lage.lead then
			gangText = gangText .. "  ·  " .. (if lage.lead == "left"
				then Sprak.t("galopp.vanster") else Sprak.t("galopp.hoger"))
		end
		if rubrikEtikett then rubrikEtikett.Text = rubrikFor(hastnamn, gangText) end
		local rader2 = {}
		for _, r in ipairs(KontrollHjalp.ridrader()) do
			table.insert(rader2, r.vad .. "  [" .. r.reglage .. "]")
		end
		--[[ Reglagen i panelen. Lektionens vägledning och Ugnetas coachning
		     står i HENNES yta uppe till höger (#264) — inte här, och inte
		     två gånger. Lektionens VAL (Prova igen, Se ritten, Gå vidare) är
		     handlingar och står kvar i panelens valsektion, med sina
		     befintliga handlingar och sin befintliga vakt. ]]
		local kropp = table.concat(rader2, "\n")
		if stegEtikett then
			stegEtikett.Text = kropp
			stegEtikett.Visible = kropp ~= ""
		end
		local ug = UgnetaController.panel()
		visaAterkoppling(nil)
		for j, k in ipairs(ug.knappar) do
			if j <= MAX_VAL then valRader[j] = k end
		end
		for j, vb in ipairs(valKnappar) do
			local k = valRader[j]
			vb.Visible = k ~= nil
			if k then
				vb.Text = tostring(k.text)
				vb.BackgroundColor3 = if k.paTur then Color3.fromRGB(92, 76, 38)
					else Color3.fromRGB(38, 41, 47)
			end
		end
		if valYta then valYta.Visible = #ug.knappar > 0 end
		local alla = {}
		for _, r in ipairs(KontrollHjalp.rader()) do
			table.insert(alla, r.vad .. "  [" .. r.reglage .. "]")
		end
		visaHjalp(table.concat(alla, "\n"))
		placera(pn)
		pn.Visible = true
		return
	end

	--[[ UTAN KROPP — respawn, eller innan karaktären laddat. Kontraktet: ett
	     begripligt läge och inga handlingar som kan fyra. Panelen står kvar
	     med rubriken och nästa steg; raderna är tomma. ]]
	if not (rot and rot:IsA("BasePart")) then
		slappHall()
		senaste = {}
		table.clear(valRader)
		if valYta then valYta.Visible = false end
		antalHandlingar = 0
		for _, b in ipairs(rader) do b.Visible = false end
		local bl = bladdra
		if bl then bl.Visible = false end
		tandAllaIgen()
		fyllText(data, PreparationController.hastId(), hastnamn)
		placera(pn)
		pn.Visible = true
		return
	end

	--[[ #246 D: dagens häst styr ordningen. `hastId` är klientens egen
	     avläsning av samma tilldelning servern gjort — ingen ny kanal. ]]
	local minHast = PreparationController.hastId()
	local platser = Naromrade.radplatser()
	--[[ Ingen användbar plats — släck panelen och lämna tillbaka Robloxs
	     prompter. En rad som ligger under rörelsekontrollen eller utanför
	     skärmen är ingen handling. ]]
	if platser <= 0 then
		slappHall()
		senaste = {}
		table.clear(valRader)
		if valYta then valYta.Visible = false end
		for _, b in ipairs(rader) do b.Visible = false end
		tandAllaIgen()
		pn.Visible = false
		return
	end
	relevanta = Naromrade.sorterade((rot :: BasePart).Position, { workspace },
		minHast)

	--[[ ── LEDNING: DÖRREN PÅ VÄGEN, SEDAN SLÄPPET ─────────────────────

		Kontraktet: medan hon leder bär panelen ledningens status och
		släppet; en dörr på vägen får tillfälligt vara den primära. Samma
		prompter som förut, bara en annan ordning — stabil inom varje
		klass. ]]
	local ordnade = table.clone(relevanta)
	if PreparationController.kontext() == "ledning" then
		local rang: { [ProximityPrompt]: number } = {}
		for i, p in ipairs(ordnade) do rang[p] = i end
		local function klass(p: ProximityPrompt): number
			if arDorr(p) then return 0 end
			if p.Name == "LedPrompt" then return 1 end
			return 2
		end
		table.sort(ordnade, function(a, b)
			local ka, kb = klass(a), klass(b)
			if ka ~= kb then return ka < kb end
			return rang[a] < rang[b]
		end)
	end

	--[[ ── HANDLINGARNA ─────────────────────────────────────────────────

		Skötselns val först när förberedelsen har något att välja: det är
		den auktoritativa uppgiften, och den som står på tur är primär.
		Därefter prompterna. Ett val utom räckhåll (`aktiv = false`) får
		ingen rad — det är samma nej som skötselknappen själv gav. ]]
	--[[ FRÅGAN ÄR ETT BLOCK, INTE TRE HANDLINGSRADER. Skötselns val står i
	     sin ursprungliga ordning — att flytta den som står på tur först
	     hade avslöjat svaret på en fråga — och prompterna blir sekundära:
	     högst två, «Rida nu» först enligt produktordningen, resten genom
	     overflow. Utan val gäller en primär och två sekundära. ]]
	local valen: { any } = {}
	--[[ EN GILTIG EFTERRITT GÅR FÖRE: den läses i panelen och avfärdas där,
	     och först sedan tar skötselns eftervård över (kontraktet). ]]
	local ug = UgnetaController.panel()
	if #ug.knappar > 0 then
		for _, k in ipairs(ug.knappar) do
			if #valen < MAX_VAL then table.insert(valen, k) end
		end
	elseif data and data.harVal then
		for _, v in ipairs(data.val) do
			if v.aktiv and #valen < MAX_VAL then table.insert(valen, v) end
		end
	end
	--[[ Under en fråga står EN sekundär handling fast — Rida nu, enligt
	     produktordningen — så att frågans alternativ får plats att synas. ]]
	local promptPlatser = if #valen > 0 then 1 else platser
	--[[ ── UTRUSTNINGSSTEGET BEHÖVER SIN VERKLIGA HANDLING ────────────────

		Mätt i Studio: momentet «Tacking up 1/5» stod på tur, servern sa
		«Saddle and bridle hang on the stall front — fetch them first» — och
		handlingen som hämtar dem låg bakom overflow, för den enda fasta
		platsen gick till Rida nu. Kontraktet: förberedelsen visar det
		aktuella steget OCH dess verkliga handling.

		Steget känns igen på momentets kanoniska id (`utr:`), aldrig på
		text. Då får dagens hästs sadel- och tränshandlingar de sekundära
		platserna, och Rida nu står kvar efter dem. ]]
	--[[ ORDNINGEN FÖLJER KANONEN, inte avståndet: «Träns på sist» —
	     `sadelfaser` 1–4 är underlägg, sadel och gjord, den sista är
	     tränset. Numret ur momentets id (`utr:N`) mot antalet utr-moment. ]]
	--[[ LEDSTEGET likadant (mätt i Studio): momentet `leda` stod på tur, ett
	     tryck på det gav «She is still in her stall» — och handlingen som
	     faktiskt leder henne ut låg bakom overflow. Dörren först, den måste
	     öppnas; sedan ledningen. ]]
	local utrustningNr: number? = nil
	local utrustningAntal = 0
	local ledaPaTur = false
	for _, v in ipairs(data and data.val or {}) do
		if type(v.id) == "string" and string.sub(v.id, 1, 4) == "utr:" then
			utrustningAntal += 1
			if v.paTur then utrustningNr = tonumber(string.sub(v.id, 5)) end
		end
		if v.paTur and v.id == "leda" then ledaPaTur = true end
	end
	if (utrustningNr ~= nil or ledaPaTur) and #valen > 0 then
		local transet = utrustningNr ~= nil and utrustningNr >= utrustningAntal
		local FORST = if ledaPaTur
			then { DorrPrompt = 1, LedPrompt = 2 }
			elseif transet
			then { TransPrompt = 1, TransaPrompt = 1, SadelPrompt = 2, SadlaPrompt = 2 }
			else { SadelPrompt = 1, SadlaPrompt = 1, TransPrompt = 2, TransaPrompt = 2 }
		local rang: { [ProximityPrompt]: number } = {}
		for i, p in ipairs(ordnade) do rang[p] = i end
		local function klass(p: ProximityPrompt): number
			local k = FORST[p.Name]
			if k == nil then return 3 end
			--[[ En dörr hör inte till någon häst; allt annat måste vara
			     dagens hästs. ]]
			if arDorr(p) then return k end
			if minHast ~= nil and Naromrade.hastFor(p) == minHast then return k end
			return 3
		end
		table.sort(ordnade, function(a, b)
			local ka, kb = klass(a), klass(b)
			if ka ~= kb then return ka < kb end
			return rang[a] < rang[b]
		end)
		promptPlatser = math.min(2, platser)
	end
	antalHandlingar = #ordnade
	local sidor = math.max(1, math.ceil(#ordnade / promptPlatser))
	--[[ Sidan klampas varje ritning: listan krymper när hon går därifrån,
	     och då får hon inte bli kvar på en sida som inte finns. ]]
	if sida > sidor then sida = sidor end
	if sida < 1 then sida = 1 end
	senaste = {}
	table.clear(valRader)
	for i, v in ipairs(valen) do valRader[i] = v end
	for j = 1, promptPlatser do
		local p = ordnade[(sida - 1) * promptPlatser + j]
		if p == nil then break end
		senaste[j] = p
	end
	--[[ Först av allt: höll hon i något som inte längre finns i panelen? ]]
	provaHallet()

	--[[ ── EN YTA, EN MOTTAGARE ──────────────────────────────────────────
		Oförändrat från ROBLOX_HUMAN_PLAYTEST_FIX: allt relevant släcks (det
		HAR en väg in, genom panelen och dess overflow), grannars saker,
		dörrar utöver den närmaste och förkanten släcks och tystas, och
		tangenterna delas ut i panelens ordning. ]]
	local slacks: { [ProximityPrompt]: boolean } = {}
	local tysta: { [ProximityPrompt]: boolean } = {}
	for _, p in ipairs(relevanta) do slacks[p] = true end
	for p in pairs(bortvalda) do slacks[p] = true; tysta[p] = true end
	for _, p in ipairs(forkant) do slacks[p] = true; tysta[p] = true end
	for p in pairs(slackta) do
		if not slacks[p] then tandIgen(p) end
	end
	for p in pairs(slacks) do slack(p) end
	--[[ TANGENTEN FÖLJER RADEN (#264, mätt i Studio): porten låg på sida 2
	     av 3 men bar ändå X, och ett X-tryck öppnade en port som inte stod
	     i panelen. En handling bakom overflow nås genom att bläddra; först
	     när dess rad syns får den sin tangent. ]]
	local paSidan: { [ProximityPrompt]: boolean } = {}
	for _, p in ipairs(senaste) do paSidan[p] = true end
	for _, p in ipairs(ordnade) do
		if not paSidan[p] then tysta[p] = true end
	end
	delaUtTangenter(senaste, tysta)

	--[[ Den varma accenten bara på den primära handlingen: med en fråga det
	     alternativ som står på tur — samma markering som skötselns egen yta
	     gav — annars första handlingen på första sidan. ]]
	local ACCENT, NEUTRAL = Color3.fromRGB(92, 76, 38), Color3.fromRGB(38, 41, 47)
	for j, b in ipairs(valKnappar) do
		local v = valRader[j]
		b.Visible = v ~= nil
		if v then
			b.Text = tostring(v.text)
			b.BackgroundColor3 = if v.paTur then ACCENT else NEUTRAL
		end
	end
	if valYta then valYta.Visible = #valen > 0 end
	for i, b in ipairs(rader) do
		local p = senaste[i]
		if p then
			b.Text = etikett(p)
			b.Visible = true
		else
			b.Visible = false
		end
		local primar = #valen == 0 and i == 1 and sida == 1 and b.Visible
		b.BackgroundColor3 = if primar then ACCENT else NEUTRAL
	end

	local bl = bladdra
	if bl then
		if sidor > 1 then
			bl.Text = ("+  %s  ·  %d/%d"):format(Sprak.t("panel.fler"), sida, sidor)
			bl.Visible = true
		else
			bl.Visible = false
		end
	end

	fyllText(data, minHast, hastnamn)
	--[[ #264 GAIT_READABILITY_AND_UGNETA: lektionens coachning skrivs inte
	     längre i panelens återkopplingsfält — den står i Ugnetas yta uppe
	     till höger. Fältet här bär uppgiftens kvittens och nej, nära
	     handlingen, och kan därför aldrig skrivas över av en kvarliggande
	     efterritt-text (det var felet prioritetsregeln här rättade förut). ]]
	placera(pn)
	pn.Visible = true
end

--[[ Provets fönster in: vad står på skärmen just nu? ]]
--[[ Radernas prompter i radordning. `_rader` ger texterna; provet som
     håller på en viss prompt behöver veta VILKEN rad den fick. ]]
--[[ Provets vägar in i bläddringen. ]]
function Naromrade._sida(): (number, number)
	local platser = Naromrade.radplatser()
	local sidor = if platser > 0
		then math.max(1, math.ceil(#relevanta / platser)) else 1
	return sida, sidor
end

function Naromrade._bladdra()
	local v = bladdra
	if v == nil or not v.Visible then return false end
	v.MouseButton1Click:Fire()
	return true
end

function Naromrade._relevanta(): { ProximityPrompt }
	local ut = {}
	for i, p in ipairs(relevanta) do ut[i] = p end
	return ut
end

function Naromrade._prompter(): { ProximityPrompt }
	--[[ Radordning, utan hål: med skötselval står prompterna efter blocket. ]]
	local ut = {}
	for i = 1, #rader do
		local p = senaste[i]
		if p then table.insert(ut, p) end
	end
	return ut
end

--[[ Provets fönster in: hur många motorlyssnare modulen håller just nu. ]]
function Naromrade._lyssnare(): number
	return #hallKopplingar + (if koppling then 1 else 0)
end

--[[ #264 PLAYER_INTERACTION_CONSOLIDATION: provets fönster in i panelen. ]]
function Naromrade._val(): { [number]: any }
	local ut = {}
	for i = 1, MAX_VAL do ut[i] = valRader[i] end
	return ut
end

function Naromrade._panel(): { [string]: any }
	local pn = panelRam
	return {
		synlig = pn ~= nil and pn.Visible,
		rubrik = if rubrikEtikett then rubrikEtikett.Text else "",
		steg = if stegEtikett and stegEtikett.Visible then stegEtikett.Text else "",
		ater = if aterEtikett and aterEtikett.Visible then aterEtikett.Text else "",
		hjalp = if hjalpText and hjalpText.Visible then hjalpText.Text else "",
		hjalpKnapp = hjalpKnapp,
		ram = pn,
	}
end

function Naromrade._rader(): { string }
	--[[ I skärmens ordning: skötselns alternativ först, sedan handlingarna. ]]
	local ut = {}
	if valYta and valYta.Visible then
		for _, b in ipairs(valKnappar) do
			if b.Visible then table.insert(ut, b.Text) end
		end
	end
	for _, b in ipairs(rader) do
		if b.Visible then table.insert(ut, b.Text) end
	end
	return ut
end

--[[ Provets väg in. `_tryckPa` är ett helt tryck: ned och upp. Vill man
     mäta ett AVBRUTET håll finns `_hallNed`/`_slappHall`. ]]
function Naromrade._tryckPa(i: number)
	local p = senaste[i]
	if p then
		borjaHall(p, i)
		slappHallFran(i)
	end
end

function Naromrade._hallNed(i: number)
	local p = senaste[i]
	if p then borjaHall(p, i) end
end

--[[ Provets väg in i «ett släpp från fel rad». ]]
function Naromrade._slappHallFran(i: number)
	slappHallFran(i)
end

function Naromrade._hallRad(): number?
	return hallRad
end

function Naromrade._slappHall()
	slappHall()
end

function Naromrade._hallsNu(): ProximityPrompt?
	return hallsPrompt
end

--[[ Ridningen äger skärmen medan den pågår. Sätts från `init.client`,
	samma väg som `DinHast.satDold`. ]]
function Naromrade.satRider(v: boolean)
	rider = v
	rita()
end

--[[ #264: den ridna hästens läge, varje bildruta från ritloopen. Bara
     gångart, målgångart och galoppsida kopieras — panelen får inte hålla
     en referens till rörelsens egen tabell. ]]
function Naromrade.ridlage(loco: any)
	if loco == nil then
		ridLage = nil
		return
	end
	ridLage = { gait = loco.gait, targetGait = loco.targetGait, lead = loco.lead }
	ridLageTid = os.clock()
end

--[[ Har spelaren en yta där en lista hör hemma? Pekskärm sedan #246,
     tangentbord och mus sedan #264. Handkontroll rörs fortfarande inte:
     där bär styrkorset prompterna och en lista tar bara plats. ]]
local function ytaBehovs(): boolean
	return UserInputService.TouchEnabled
		or UserInputService.KeyboardEnabled
		or UserInputService.MouseEnabled
end

function Naromrade.start()
	--[[ ── OCH SKRIVBORDET, SEDAN #264 ────────────────────────────────

		Här stod «SKRIVBORDET RÖRS INTE. Utan pekskärm finns tangenterna,
		och en extra knapplista hade bara tagit plats.» Det höll inte.

		Tobias playtest 2026-09-24: en vägg av Robloxs egna världsbubblor
		framför hästen — flera hästars utrustning och dörrar samtidigt —
		och ingen väg att se vad som faktiskt gick att göra. Modulen bär
		själv mätningen av varför, i noten vid knappvalet: ELVA prompter
		inom räckhåll, sex delade `E`, och av dem visades EN.

		«Tangenterna finns» är sant och otillräckligt: tangenten hjälper
		inte den som inte ser vilken handling som ligger under den, eller
		att det finns fem till bakom den som syns.

		Listan gör samma sak på PC som på pekskärm — den visar vad som
		går att göra just nu, i ett hörn, och släcker BARA de bubblor den
		ersätter. Aktiveringen är oförändrad: raden går genom
		`InputHoldBegin`, och tangenten fungerar som förut eftersom
		`Style = Custom` bara tar Robloxs egen rityta, inte dess input. ]]
	if not ytaBehovs() then return end
	bygg()
	--[[ EN PANEL (#264 PLAYER_INTERACTION_CONSOLIDATION): skötselns egna
	     ytor släcks och deras innehåll kommer hit. Varje ny vy ritar om. ]]
	PreparationController.satVard(function() rita() end)
	UgnetaController.satVard(function() rita() end)
	if koppling then koppling:Disconnect() end
	koppling = RunService.RenderStepped:Connect(function(dt)
		--[[ Fyllningen varje bildruta — ett håll på 0,2 s ryms annars
		     inom en enda takt och syns aldrig. ]]
		ritaFyllning()
		sedan += dt
		if sedan < TAKT then return end
		sedan = 0
		rita()
	end)
	--[[ Motorns egna hållhändelser: ett håll på TANGENTEN går inte genom
	     `borjaHall`, men ska synas i raden lika fullt. Finns inte tjänsten
	     (bänken) gäller bara radens eget håll. ]]
	for _, k in ipairs(hallKopplingar) do k:Disconnect() end
	table.clear(hallKopplingar)
	pcall(function()
		local PPS = game:GetService("ProximityPromptService")
		table.insert(hallKopplingar, PPS.PromptButtonHoldBegan:Connect(function(p)
			fyllPrompt = p
			fyllStart = os.clock()
		end))
		table.insert(hallKopplingar, PPS.PromptButtonHoldEnded:Connect(function(p)
			if fyllPrompt == p then fyllPrompt = nil end
		end))
		table.insert(hallKopplingar, PPS.PromptTriggered:Connect(function(p)
			if fyllPrompt == p then fyllPrompt = nil end
		end))
	end)
end

function Naromrade.stopp()
	--[[ Lämna aldrig ett öppet håll — eller en släckt prompt — efter sig. ]]
	slappHall()
	tandAllaIgen()
	PreparationController.satVard(nil)
	UgnetaController.satVard(nil)
	fyllPrompt = nil
	for _, k in ipairs(hallKopplingar) do k:Disconnect() end
	table.clear(hallKopplingar)
	if koppling then
		koppling:Disconnect()
		koppling = nil
	end
	if gui then
		gui:Destroy()
		gui = nil
	end
	ram = nil
	panelRam = nil
	rubrikEtikett, stegEtikett, aterEtikett = nil, nil, nil
	hjalpKnapp, hjalpText = nil, nil
	hjalpUt = false
	table.clear(valRader)
	table.clear(valKnappar)
	valYta = nil
	rader = {}
	bladdra = nil
	senaste = {}
	--[[ Nästa gång hon kommer hit börjar listan om från början. ]]
	relevanta = {}
	sida = 1
end

return Naromrade
