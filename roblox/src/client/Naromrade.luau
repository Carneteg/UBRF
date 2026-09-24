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

local Naromrade = {}

--[[ ── MÅTTEN ──────────────────────────────────────────────────────

	44 px är golvet för en träffyta i `docs/KONTROLLMATRIS.md` regel 5.
	52 ger marginal och är samma höjd som ridningens egna knappar i
	`TouchControls`, så att de två ytorna känns som samma spel. ]]
local KNAPP_H = 52
local KNAPP_B = 190
local LUFT = 8
local KANT = 16

--[[ Hur många rader som ritas. Fler än så är inte ett val, det är en
	lista — och mätningen ovan hittade fem konkurrerande prompter, så
	taket måste rymma dem utan att fylla skärmen. ]]
local MAX_RADER = 5

--[[ Hur ofta listan räknas om. Tätare än så kostar utan att synas;
	glesare gör att en rad ligger kvar när man gått därifrån. ]]
local TAKT = 0.2

local gui: ScreenGui? = nil
local ram: Frame? = nil
local rader: { TextButton } = {}
local koppling: RBXScriptConnection? = nil
local sedan = 0
local rider = false
local senaste: { ProximityPrompt } = {}
--[[ #246 C: prompter vars EGNA UI vi släckt, och stilen de hade innan.
     Nyckeln är prompten själv, så att en som försvinner ur världen tas
     med av skräpsamlaren utan att lämna en post efter sig. ]]
local slackta: { [ProximityPrompt]: any } = {}

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
	if not ok or kod == nil or kod == Enum.KeyCode.Unknown then return nil end
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
	--[[ Tangenten sist och inom hakparenteser, så att den korta etiketten
	     fortfarande är det man läser först. ]]
	if tangent then text ..= "  [" .. tangent .. "]" end
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
function Naromrade.iRackvidd(fran: Vector3, sok: { Instance }): { ProximityPrompt }
	local ut: { ProximityPrompt } = {}
	local avstand: { [ProximityPrompt]: number } = {}
	for _, rot in ipairs(sok) do
		for _, d in ipairs(rot:GetDescendants()) do
			if d:IsA("ProximityPrompt") and d.Enabled then
				local p = varldslage(d)
				if p then
					local a = (p - fran).Magnitude
					if a <= d.MaxActivationDistance then
						table.insert(ut, d)
						avstand[d] = a
					end
				end
			end
		end
	end
	table.sort(ut, function(a, b) return avstand[a] < avstand[b] end)
	return ut
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

	Inom en klass gäller avståndet precis som förut: rangen kommer ur
	`iRackvidd`, som redan sorterat närmast först. Dörrar försvinner alltså
	inte; de hamnar efter hästens steg i stället för före det.

	URVALET STYR BÅDE RADERNA OCH SLÄCKNINGEN (rättelse #264). Raden här
	sa förut motsatsen — att urvalet styr raderna men inte vilka bilder
	som släcks. Det var det som gjorde dörren oanvändbar. Se noten ovan. ]]
function Naromrade.nara(fran: Vector3, sok: { Instance },
	minHast: string?, tak: number?): { ProximityPrompt }
	local alla = Naromrade.iRackvidd(fran, sok)
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
		     egen. Dess bild släcks ändå — `rita` läser `iRackvidd`. ]]
		if k ~= 3 then
			table.insert(ut, d)
			klass[d] = k
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
	--[[ Taket klipps EFTER sorteringen: det spelaren menar får aldrig
		trängas bort av något som råkade hittas först. ]]
	local n = math.max(1, math.min(tak or MAX_RADER, MAX_RADER))
	while #ut > n do table.remove(ut) end
	return ut
end

local function nyKnapp(i: number): TextButton
	local b = Instance.new("TextButton")
	b.Name = "Rad" .. i
	b.Size = UDim2.fromOffset(KNAPP_B, KNAPP_H)
	b.Position = UDim2.fromOffset(0, (i - 1) * (KNAPP_H + LUFT))
	b.BackgroundColor3 = Color3.fromRGB(24, 27, 33)
	b.BackgroundTransparency = 0.12
	b.TextColor3 = Color3.fromRGB(236, 232, 222)
	b.Font = Enum.Font.GothamMedium
	b.TextSize = 15
	b.TextScaled = true
	b.TextWrapped = true
	b.AutoButtonColor = false
	b.BorderSizePixel = 0
	b.Visible = false
	local tak = Instance.new("UITextSizeConstraint")
	tak.MaxTextSize = 15
	tak.MinTextSize = 9
	tak.Parent = b
	local horn = Instance.new("UICorner")
	horn.CornerRadius = UDim.new(0, 12)
	horn.Parent = b
	return b
end

--[[ TRYCKET GÅR GENOM PROMPTENS EGEN VÄG. Ingen genväg till servern,
	ingen kopia av handlaren: `InputHoldBegin` är exakt vad en tangent
	eller ett tryck på promptens egen knapp gör, och `HoldDuration`
	respekteras därför precis som förut. ]]
local function tryck(p: ProximityPrompt)
	if p == nil or p.Parent == nil or not p.Enabled then return end
	p:InputHoldBegin()
	if p.HoldDuration and p.HoldDuration > 0 then
		task.delay(p.HoldDuration + 0.05, function()
			if p.Parent then p:InputHoldEnd() end
		end)
	else
		p:InputHoldEnd()
	end
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
local function slack(p: ProximityPrompt)
	if slackta[p] ~= nil then return end
	slackta[p] = { stil = p.Style }
	p.Style = Enum.ProximityPromptStyle.Custom
end

local function tandIgen(p: ProximityPrompt)
	local post = slackta[p]
	if post == nil then return end
	slackta[p] = nil
	--[[ En prompt som lämnat världen ska inte skrivas på. ]]
	if p.Parent ~= nil then p.Style = post.stil end
end

local function tandAllaIgen()
	for p, post in pairs(slackta) do
		if p.Parent ~= nil then p.Style = post.stil end
	end
	table.clear(slackta)
end

--[[ Provets fönster in. ]]
function Naromrade._slackta(): number
	local n = 0
	for _ in pairs(slackta) do n += 1 end
	return n
end

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

	local f = Instance.new("Frame")
	f.Name = "Lista"
	f.BackgroundTransparency = 1
	f.Size = UDim2.fromOffset(KNAPP_B, MAX_RADER * (KNAPP_H + LUFT))
	--[[ VÄNSTERKANTEN, NEDTILL. Skötsel-HUD:ens spårare bor uppe till
		höger och lektionskortet nedtill i mitten; vänsterkanten är den
		enda som är fri medan man går till fots. Ridningens spak bor
		också där — men då rider man, och då är den här ytan släckt. ]]
	f.Position = UDim2.new(0, KANT, 1, -(MAX_RADER * (KNAPP_H + LUFT)) - KANT)
	f.Parent = g
	ram = f

	for i = 1, MAX_RADER do
		local b = nyKnapp(i)
		b.Parent = f
		b.MouseButton1Click:Connect(function()
			local p = senaste[i]
			if p then tryck(p) end
		end)
		rader[i] = b
	end
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
	local ledigt = golv - KANT - LUFT
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
	local panelgolv = if ruta and ruta.y0 then math.min(h, ruta.y0) else h
	local ytaX1, ytaY0 = Naromrade.rorelseytan()
	if ytaY0 >= h then return KANT, panelgolv end

	local tak = math.min(ytaY0, panelgolv)
	if tak - KANT - LUFT >= KNAPP_H + LUFT then return KANT, tak end

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

local function rita()
	local f = ram
	if not f then return end
	local spelare = Players.LocalPlayer
	local karaktar = spelare.Character
	local rot = karaktar and karaktar:FindFirstChild("HumanoidRootPart")

	--[[ Medan man rider äger `TouchControls` skärmen, och till fots utan
		kropp finns ingenting att stå nära. Båda släcker listan hellre än
		att visa en rad som inte går att lita på. ]]
	if rider or not (rot and rot:IsA("BasePart")) then
		senaste = {}
		for _, b in ipairs(rader) do b.Visible = false end
		--[[ Ingen lista — då ska Roblox egna prompter tillbaka, annars blir
		     de osynliga för någon som inte längre har en rad att trycka på. ]]
		tandAllaIgen()
		return
	end

	--[[ #246 D: dagens häst styr ordningen. `hastId` är klientens egen
	     avläsning av samma tilldelning servern gjort — ingen ny kanal. ]]
	local minHast = PreparationController.hastId()
	local platser = Naromrade.radplatser()
	--[[ Ingen användbar plats — släck listan och lämna tillbaka Robloxs
	     prompter, samma väg som när man rider. En rad som ligger under
	     rörelsekontrollen eller utanför skärmen är ingen handling. ]]
	if platser <= 0 then
		senaste = {}
		for _, b in ipairs(rader) do b.Visible = false end
		tandAllaIgen()
		return
	end
	--[[ EN fråga, ett svar: vad blir rader. Det styr numera BÅDE listan
	     och släckningen — se rättelsen längre ned. Tidigare fanns två
	     mängder här, och att de kunde gå isär var hela felet. ]]
	senaste = Naromrade.nara((rot :: BasePart).Position, { workspace },
		minHast, platser)
	--[[ Ramen följer antalet platser, så att den tomma ytan inte ligger
	     kvar över panelen och äter tryck som inte hör listan till. ]]
	f.Size = UDim2.fromOffset(KNAPP_B, platser * (KNAPP_H + LUFT))
	--[[ Blockets plats räknas, den står inte i en konstant: både
	     skötselpanelen och Robloxs rörelsekontroll kan ta hörnet. ]]
	local g = gui
	local hojd = if g and g.AbsoluteSize then g.AbsoluteSize.Y else 0
	local x, golv = Naromrade.blockplats()
	local botten = math.min(golv or hojd, hojd) - KANT
	local topp = botten - platser * (KNAPP_H + LUFT)
	f.Position = UDim2.fromOffset(x or KANT, math.max(0, topp))

	--[[ ── EN PROMPT SOM SLÄCKS MÅSTE FÅ EN RAD ────────────────────

		Här stod förut «#246 C: ALLT INOM RÄCKVIDD SLÄCKS, INTE BARA
		RADERNA», med motiveringen att det annars blev listan plus
		flytande knappar i djupet. Den regeln är BORTTAGEN, och noten
		står kvar bara för att ingen ska återinföra den.

		Varför den var fel: en släckt prompt utan rad är inte diskret, den
		är omöjlig att använda. Entrédörren blev overflow på telefonen,
		släcktes, fick ingen rad — och gick inte att öppna. Tobias hittade
		det i ett riktigt playtest.

		Ordningen spelar fortfarande roll — tänd först det som inte längre
		visas, släck sedan det som gör det — annars kan en prompt som
		ligger kvar hinna tändas och släckas i samma bildruta. ]]
	--[[ ── RÄTTELSE #264: SLÄCK BARA DET DU ERSÄTTER ─────────────────

		SPELTEST 2026-09-21: Tobias såg «Open — Door» och kunde inte
		öppna dörren. Rutten genom stallet var stängd.

		Raden ovanför löd `for _, p in ipairs(alla) do slack(p) end` —
		allt inom RÄCKVIDD släcktes, medan rader bara ritas för URVALET.
		En prompt som föll under radtaket blev därmed varken rad eller
		knapp: Roblox bild borttagen, ingen egen satt dit.

		Modulen beskrev själv den felklassen redan, vid `nara`:
		«Eftersom touch-ytan äger promptbilderna var den då varken rad
		eller knapp.» Den gången rättades ORDNINGEN så att «Rida nu»
		fick en rad. Orsaken låg kvar: taket är 2–3 rader på en telefon,
		och i en stallgång konkurrerar dörren med sadel, träns, boxfront
		och ledknapp. Faller den ur listan är den oåtkomlig.

		Invarianten är enkel och gäller utan undantag: EN AFFORDANS FÅR
		BARA TAS BORT AV EN SOM ERSÄTTER DEN. Släckningen följer därför
		urvalet, inte räckvidden.

		Priset är det review av `c3f48c7` ville undvika: en prompt som
		listan valt bort kan visa Roblox egen knapp igen. Det är en
		dubbel yta — irriterande. Alternativet var en dörr som inte går
		att öppna. Ska den dubbleringen bort är det ett FILTRERINGSVAL i
		`nara`, inte ett skäl att lämna något utan väg in. ]]
	local visas: { [ProximityPrompt]: boolean } = {}
	for _, p in ipairs(senaste) do visas[p] = true end
	for p in pairs(slackta) do
		if not visas[p] then tandIgen(p) end
	end
	for _, p in ipairs(senaste) do slack(p) end

	for i, b in ipairs(rader) do
		local p = senaste[i]
		if p then
			b.Text = etikett(p)
			b.Visible = true
		else
			b.Visible = false
		end
	end
end

--[[ Provets fönster in: vad står på skärmen just nu? ]]
function Naromrade._rader(): { string }
	local ut = {}
	for _, b in ipairs(rader) do
		if b.Visible then table.insert(ut, b.Text) end
	end
	return ut
end

function Naromrade._tryckPa(i: number)
	local p = senaste[i]
	if p then tryck(p) end
end

--[[ Ridningen äger skärmen medan den pågår. Sätts från `init.client`,
	samma väg som `DinHast.satDold`. ]]
function Naromrade.satRider(v: boolean)
	rider = v
	rita()
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
	if koppling then koppling:Disconnect() end
	koppling = RunService.RenderStepped:Connect(function(dt)
		sedan += dt
		if sedan < TAKT then return end
		sedan = 0
		rita()
	end)
end

function Naromrade.stopp()
	--[[ Lämna aldrig en släckt prompt efter sig. ]]
	tandAllaIgen()
	if koppling then
		koppling:Disconnect()
		koppling = nil
	end
	if gui then
		gui:Destroy()
		gui = nil
	end
	ram = nil
	rader = {}
	senaste = {}
end

return Naromrade
