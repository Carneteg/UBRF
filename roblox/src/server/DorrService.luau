--!strict
--[[
	Dörrarna som gameplay.

	Blockerare i #162, funnen av Tobias i Studio: han stod vid den vita
	dörren, på den gula markören, och kom inte in. Ingenting hände och ingen
	interaktion syntes.

	Två orsaker, och båda var verkliga:

	  1. Fasaden byggdes som fyra hela väggar och öppningarna MÅLADES på
	     utsidan som 6 cm tunna paneler. Väggen bakom dörren kolliderade.
	     Det är rättat i `Anlaggningen.luau` — fasaden byggs som segment med
	     luckor där dörrarna redan står.
	  2. Ingen dörr hade någon interaktion. `ProximityPrompt` fanns på exakt
	     två ställen i hela runtime: en per häst (`InteractionController`) och
	     en vid boxen (`StallService`). Dörrarna hade `Mot`/`Text` som ingen
	     läste — de attributen är webbens scenbyte, och webbens scenbyte hör
	     inte hit: Roblox-anläggningen är EN sammanhängande place, så att gå
	     in är att gå igenom en öppning, inte att teleporteras.

	Den här tjänsten gör det andra: varje dörrblad som `Anlaggningen` märkt
	med `UBRFDorr` får en prompt, och dörren öppnas och stängs faktiskt.

	Ingen geometri flyttas. Bladet svänger runt sin egen gångjärnskant och
	går tillbaka exakt dit det stod — det stängda läget sparas vid start och
	är det enda som skrivs tillbaka.
]]

--[[ Språkkatalogen: den svenska STANDARDTEXTEN på prompten kommer ur
	katalogen, inte ur en sträng här, så att den och nyckeln klienten skriver
	om den med aldrig kan glida isär. ]]
local Sprak = require(game:GetService("ReplicatedStorage").HorseCore.Sprak)

local DorrService = {}

local OPPEN_VINKEL = 85         -- grader; 90 låter bladet ligga i väggens liv
local RACKVIDD = 8              -- m, som boxens prompt i StallService
local M = 3                     -- studs per meter, som BuildKit.M

--[[ Det stängda läget per blad. En tabell och inte ett attribut: läget ska
	inte kunna följa med en kopierad del in i en annan session och där gälla
	som sanning. ]]
local stangt: { [BasePart]: CFrame } = {}
local oppna: { [BasePart]: boolean } = {}

local function anlaggning(): Instance?
	local folder = workspace:FindFirstChild("Anläggning")
	return folder
end

--[[ Gångjärnet ligger i bladets ena lodräta kant. Vilken kant spelar ingen
	roll för framkomligheten, och att välja den låga änden längs väggens egen
	axel är förutsägbart — det är samma axel `Anlaggningen` byggde bladet i. ]]
local function gangjarn(blad: BasePart): (CFrame, Vector3)
	local langs = blad:GetAttribute("Langs")
	local halv = ((blad:GetAttribute("Bredd") :: number) or 1) * M / 2
	local lokal = if langs == "X" then Vector3.new(-halv, 0, 0) else Vector3.new(0, 0, -halv)
	return stangt[blad] * CFrame.new(lokal), lokal
end

local function satt(blad: BasePart, vidoppen: boolean)
	local gang, lokal = gangjarn(blad)
	if vidoppen then
		blad.CFrame = gang * CFrame.Angles(0, math.rad(OPPEN_VINKEL), 0) * CFrame.new(-lokal)
	else
		blad.CFrame = stangt[blad]
	end
	--[[ Kollisionen är hela poängen: en öppen dörr man inte kan gå igenom är
		samma fel som förut, bara med en animation på. ]]
	blad.CanCollide = not vidoppen
	oppna[blad] = vidoppen
end

--[[ Vad prompten kallar öppningen — och vilken språknyckel som hör till.

	Raden hette förut `textFor` och returnerade `Etikett`, som i sin tur var
	öppningens TYP ur geometrin. Spelaren läste alltså "dorrgul" ovanför
	"Öppna". Ingen öppning i datan har en riktig etikett, så det gällde
	varenda dörr i världen.

	Nu härleds texten ur typen: `port*` är de stora portarna, allt annat är
	en dörr. Färgen i tokenet är bara färg. Ett verkligt `Etikett` (ett namn
	i världen, om datan någon gång får ett) vinner och översätts inte. ]]
local function objektFor(blad: BasePart): (string, string?)
	local etikett = blad:GetAttribute("Etikett")
	if typeof(etikett) == "string" and etikett ~= "" then
		return etikett, nil
	end
	local typ = blad:GetAttribute("Oppningstyp")
	if typeof(typ) == "string" and string.sub(typ, 1, 4) == "port" then
		return Sprak.iSprak("sv", "dorr.port"), "dorr.port"
	end
	return Sprak.iSprak("sv", "dorr.objekt"), "dorr.objekt"
end

local function rustaDorr(blad: BasePart)
	if stangt[blad] then return end
	stangt[blad] = blad.CFrame
	oppna[blad] = false
	blad.CanCollide = true

	--[[ ÖPPNINGENS MITT, och den ligger INTE i bladet.

		Mätt i Studio, och det kostade en runda: `LedService` siktade på
		dörrens `Position` för att ställa hästen rakt i öppningen — men ett
		öppet blad har svängt 85 grader ut i gången, och punkten låg då 1,7 m
		fel. Hästen fick ett delmål inne i gången i stället för i luckan och
		stod still 0,98 m därifrån.

		Det STÄNGDA läget är öppningen. Det skrivs en gång, här, och är
		synligt i Studio — den som undrar var hålet i fronten sitter kan
		läsa det på bladet i stället för att räkna baklänges ur gångjärnet. ]]
	blad:SetAttribute("UBRFOppningsmitt", blad.CFrame.Position)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "DorrPrompt"
	--[[ #162 lokalisering: texten som skapas här är SVENSKA STANDARDEN, och
		nyckeln intill är den klienten skriver om den med (`Prompttext`).
		En prompt replikeras till alla spelare och kan därför inte ha en
		spelares språk på servern. Skulle klientmodulen fattas ser spelaren
		svenska — inte en tom prompt.

		TEXTEN FÖRST, NYCKELN SIST. Ordningen är inte kosmetisk: klienten
		översätter när ATTRIBUTET ändras, så en serverskrivning efter
		attributet skriver över översättningen och replikerar sitt svenska
		ord till en engelsk spelare. Det var precis vad `Triggered` gjorde
		(se noten där), och `ObjectText` klarade sig bara för att servern
		aldrig rör den efter riggningen.

		Standardtexten hämtas dessutom ur KATALOGEN och inte som en
		bokstavlig sträng, av samma skäl som `objektFor` gör det: två
		stavningar av samma ord kan glida isär. ]]
	prompt.ActionText = Sprak.iSprak("sv", "dorr.oppna")
	prompt:SetAttribute("SprakNyckel", "dorr.oppna")
	local objekttext, objektnyckel = objektFor(blad)
	prompt.ObjectText = objekttext
	--[[ Ett verkligt namn i världen översätts inte och får därför ingen
		nyckel; det generiska ordet får det. ]]
	if objektnyckel then
		prompt:SetAttribute("SprakObjekt", objektnyckel)
	end
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = RACKVIDD
	--[[ Utan siktlinjekrav: bladet står i sin egen lucka och skymmer sig
		själv från vissa vinklar, och då försvann prompten där man faktiskt
		står — vilket är just det Tobias råkade ut för. ]]
	prompt.RequiresLineOfSight = false
	prompt.Parent = blad

	prompt.Triggered:Connect(function()
		local nu = not oppna[blad]
		satt(blad, nu)
		--[[ TEXTEN FÖRST, NYCKELN SIST — och det här är rättelsen.

			Förut stod det tvärtom, med motiveringen att klienten lyssnar på
			attributet. Men serverns skrivning av `ActionText` REPLIKERAR,
			och den kom efter klientens översättning: en spelare på `en-us`
			läste `Öppna` och `Stäng` på samtliga tretton dörrar, medan
			`ObjectText` bredvid stod korrekt på `Door`. Mätt i Studio.

			Nu sätts den svenska standarden först och attributet sist, så
			att klientens omskrivning är den sista som händer. `Prompttext`
			skriver dessutom om sig själv om någon ändå hinner före. ]]
		local nyckel = if nu then "dorr.stang" else "dorr.oppna"
		prompt.ActionText = Sprak.iSprak("sv", nyckel)
		prompt:SetAttribute("SprakNyckel", nyckel)
	end)
end

--[[ Alla dörrblad i den byggda anläggningen. Attributet sätts av
	`Anlaggningen.byggOppning` för de öppningar man GÅR IGENOM — fönster och
	öppningar med bröstning får det inte, och ska inte ha en prompt. ]]
function DorrService.dorrar(): { BasePart }
	local ut = {}
	local rot = anlaggning()
	if not rot then return ut end
	for _, d in ipairs(rot:GetDescendants()) do
		if d:IsA("BasePart") and d:GetAttribute("UBRFDorr") == true then
			table.insert(ut, d)
		end
	end
	return ut
end

--[[ Boxdörrarna. Egen lista av samma skäl som noten i `start()`. ]]
function DorrService.boxdorrar(): { BasePart }
	local ut = {}
	local rot = anlaggning()
	if not rot then return ut end
	for _, d in ipairs(rot:GetDescendants()) do
		if d:IsA("BasePart") and d:GetAttribute("UBRFBoxdorr") == true then
			table.insert(ut, d)
		end
	end
	return ut
end

function DorrService.start()
	local funna = DorrService.dorrar()
	if #funna == 0 then
		--[[ Fail loud, inte tyst: en place utan byggd anläggning är precis
			det läge blockeraren handlade om, och då ska det stå i outputen
			och inte upptäckas av en människa framför en dörr som inte
			öppnas. ]]
		warn("[Dörr] Anläggningen är inte byggd — ingen dörr fick interaktion. "
			.. "First Playable kräver att världen byggs före tjänsterna.")
		return
	end
	for _, blad in ipairs(funna) do
		rustaDorr(blad)
	end
	print(("[Dörr] %d dörrar fick interaktion"):format(#funna))

	--[[ Boxdörrarna riggas med SAMMA mekanik men räknas för sig.

		De hör inte till `dorrar()`: den listan är fasadens genomgångar och
		bär kontraktet "13 blad + 1 deklarerad icke-passage". Att lägga
		trettiotre boxdörrar där hade brutit det utan att någon dörr blev
		fel — därför en egen lista och en egen rad i outputen. ]]
	local boxar = DorrService.boxdorrar()
	for _, blad in ipairs(boxar) do
		rustaDorr(blad)
	end
	print(("[Box] %d boxdörrar fick interaktion"):format(#boxar))
end

--[[ Att ställa ett blad i ett bestämt läge.

	Finns för att en MÄTNING ska kunna göra exakt det prompten gör, med
	samma gångjärn och samma kollision, i stället för att räkna ut bladets
	öppna läge en andra gång i testkoden. En andra uträkning hade kunnat
	vara fel utan att någon märkte det — och då mäter provet sin egen
	geometri i stället för spelets. Gameplayet går fortsatt genom prompten. ]]
function DorrService.satLage(blad: BasePart, oppen: boolean): boolean
	if not stangt[blad] then return false end
	satt(blad, oppen)
	return true
end

function DorrService.arOppen(blad: BasePart): boolean
	return oppna[blad] == true
end

-- För preflight och specar: går dörren att öppna, och släpper den igenom?
function DorrService.provaOppna(blad: BasePart): boolean
	if not stangt[blad] then return false end
	satt(blad, true)
	local gick = blad.CanCollide == false
	satt(blad, false)
	return gick and blad.CanCollide == true
end

return DorrService
