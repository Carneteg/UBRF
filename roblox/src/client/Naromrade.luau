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

local function etikett(p: ProximityPrompt): string
	local handling = p.ActionText
	if handling == nil or handling == "" then handling = Sprak.t("interaktion.anvand") end
	return Naromrade.kortEtikett(handling, p.ObjectText)
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

	SKILD FRÅN URVALET MED FLIT (senior review av `c3f48c7`). Första
	utkastet släckte bara de prompter som fick en RAD. Följden i QA-
	scenariot: telefonen rymmer två rader, sex prompter ligger inom
	räckvidd, och de fyra som inte fick en rad — grannhästarnas utrustning
	som filtreras bort, och dörrarna som blir overflow — behöll Roblox egna
	flytande knappar. Spelaren mötte alltså fortfarande listan PLUS knappar
	i djupet, vilket är precis den röra #246 finns för att ta bort.

	Jag läste kontraktets "för samma handling" snävt. Kravet är en yta. ]]
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

	URVALET STYR RADERNA — INTE VILKA BILDER SOM SLÄCKS. Se noten ovan. ]]
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
function Naromrade.radplatser(): number
	local g = gui
	local h = if g and g.AbsoluteSize then g.AbsoluteSize.Y else 0
	if h <= 0 then return MAX_RADER end
	local golv = h
	local ruta = PreparationController.interaktionsruta()
	if ruta and ruta.y0 then golv = math.min(golv, ruta.y0) end
	local ledigt = golv - KANT - LUFT
	local n = math.floor(ledigt / (KNAPP_H + LUFT))
	return math.clamp(n, 1, MAX_RADER)
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
	--[[ Två frågor, två svar: vad ÄR i närheten, och vad ska bli rader.
	     Den första styr släckningen, den andra listan. ]]
	local alla = Naromrade.iRackvidd((rot :: BasePart).Position, { workspace })
	senaste = Naromrade.nara((rot :: BasePart).Position, { workspace },
		minHast, platser)
	--[[ Ramen följer antalet platser, så att den tomma ytan inte ligger
	     kvar över panelen och äter tryck som inte hör listan till. ]]
	f.Size = UDim2.fromOffset(KNAPP_B, platser * (KNAPP_H + LUFT))
	f.Position = UDim2.new(0, KANT, 1, -(platser * (KNAPP_H + LUFT)) - KANT)

	--[[ ── #246 C: ALLT INOM RÄCKVIDD SLÄCKS, INTE BARA RADERNA ──────

		Senior review av `c3f48c7`: första utkastet släckte bara de
		prompter som fick en rad. De som inte fick plats — och grannhästens
		utrustning, som filtreras bort ur listan — behöll Roblox egna
		flytande knappar. Ytan var alltså fortfarande dubbel, och just den
		rörigheten är vad ordern beskriver.

		Gränsen går vid RÄCKVIDDEN, inte vid urvalet: det touch-adaptern
		äger är närområdets bilder. Vilka av dem som blir rader är en annan
		fråga, och den avgörs av `nara`.

		Ordningen spelar roll — tänd först det som lämnat räckvidden, släck
		sedan det som är kvar — annars kan en prompt som ligger kvar hinna
		tändas och släckas i samma bildruta. ]]
	local inom: { [ProximityPrompt]: boolean } = {}
	for _, p in ipairs(alla) do inom[p] = true end
	for p in pairs(slackta) do
		if not inom[p] then tandIgen(p) end
	end
	for _, p in ipairs(alla) do slack(p) end

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

function Naromrade.start()
	--[[ SKRIVBORDET RÖRS INTE. Utan pekskärm finns tangenterna, och en
		extra knapplista hade bara tagit plats. ]]
	if not UserInputService.TouchEnabled then return end
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
