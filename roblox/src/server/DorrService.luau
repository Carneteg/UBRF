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

local function textFor(blad: BasePart): string
	local etikett = blad:GetAttribute("Etikett")
	local byggnad = blad:GetAttribute("Byggnad")
	if typeof(etikett) == "string" and etikett ~= "" then
		return etikett
	end
	return if typeof(byggnad) == "string" then byggnad else "Dörr"
end

local function rustaDorr(blad: BasePart)
	if stangt[blad] then return end
	stangt[blad] = blad.CFrame
	oppna[blad] = false
	blad.CanCollide = true

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "DorrPrompt"
	--[[ #162 lokalisering: texten som skapas här är SVENSKA STANDARDEN, och
		nyckeln intill är den klienten skriver om den med (`Prompttext`).
		En prompt replikeras till alla spelare och kan därför inte ha en
		spelares språk på servern. Skulle klientmodulen fattas ser spelaren
		svenska — inte en tom prompt. ]]
	prompt.ActionText = "Öppna"
	prompt:SetAttribute("SprakNyckel", "dorr.oppna")
	prompt.ObjectText = textFor(blad)
	--[[ Byggnadens/dörrens egen etikett är ett namn i världen och översätts
		inte; bara det generiska "Dörr" har en nyckel. ]]
	if prompt.ObjectText == "Dörr" then
		prompt:SetAttribute("SprakObjekt", "dorr.objekt")
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
		--[[ Nyckeln FÖRST, texten sedan: klientens `Prompttext` lyssnar på
			attributet, och en svensk standardtext intill gör att prompten
			är läsbar även utan klientmodulen. ]]
		prompt:SetAttribute("SprakNyckel", if nu then "dorr.stang" else "dorr.oppna")
		prompt.ActionText = if nu then "Stäng" else "Öppna"
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
