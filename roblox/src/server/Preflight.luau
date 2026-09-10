--!strict
--[[
	FIRST_PLAYABLE_PREFLIGHT — grinden som ska vara grön innan någon
	människa lägger tid på fysisk acceptans.

	Bakgrund (#162, arbetsordern 15:37): vi fångade ett integrationsfel med
	en människa i Studio i stället för med en maskin. Miljöpaketet gick att
	köra och såg rätt ut, men First Playable-runtime låg inte i samma build.
	Symptomen blev fel spawn och en dörrmarkör utan interaktion.

	Preflighten mäter därför BUILDEN, inte källkoden: finns delarna verkligen
	i den place som körs, och hänger kedjan ihop? Ett grönt CI säger ingenting
	om det, för CI kör aldrig en place.

	FAIL CLOSED: saknas något skrivs `FIRST_PLAYABLE_PREFLIGHT: FAIL` med vad
	som saknas, och `ReplicatedStorage.UBRFPreflight` sätts till false.
	QA-listan säger då STOPP. Frånvaro av ett PASS är inte ett PASS.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")

local Preflight = {}

type Rad = { namn: string, ok: boolean, detalj: string? }

local function rad(ut: { Rad }, namn: string, ok: boolean, detalj: string?)
	table.insert(ut, { namn = namn, ok = ok, detalj = detalj })
end

local function finns(foralder: Instance?, namn: string): boolean
	return foralder ~= nil and foralder:FindFirstChild(namn) ~= nil
end

--[[ Buildens identitet. Skrivs av tools/bygg-place.py som en modul i
	ReplicatedStorage. Saknas den vet vi inte vad som testas, och då är det
	inte ett PASS — det var hela poängen med punkt 9. ]]
local function buildIdentitet(): (string, string)
	local m = ReplicatedStorage:FindFirstChild("UBRFBuild")
	if not m or not m:IsA("ModuleScript") then return "OKÄND", "OKÄND" end
	local ok, data = pcall(require, m)
	if not ok or typeof(data) ~= "table" then return "OKÄND", "OKÄND" end
	local d = data :: any
	return tostring(d.sha or "OKÄND"), tostring(d.miljo_sha or d.sha or "OKÄND")
end

function Preflight.matningar(varldenFinns: boolean): { Rad }
	local ut: { Rad } = {}

	--[[ 1. Paketkompletthet. ]]
	local horse = ServerScriptService:FindFirstChild("Horse")
	local klient = StarterPlayer:FindFirstChild("StarterPlayerScripts")
	rad(ut, "1a ReplicatedStorage/HorseCore", finns(ReplicatedStorage, "HorseCore"))
	for _, namn in ipairs({ "UBRFSpelData", "UBRFSkotsel", "UBRFSpel", "Stallet", "UBRFKomplex" }) do
		rad(ut, "1b ReplicatedStorage/" .. namn, finns(ReplicatedStorage, namn))
	end
	rad(ut, "1c ServerScriptService/Horse (server-runtime)", horse ~= nil)
	rad(ut, "1d StarterPlayerScripts/Horse (client-runtime)",
		klient ~= nil and finns(klient, "Horse"))
	rad(ut, "1e ServerScriptService/Varld/Anlaggningen (världsbyggaren)",
		finns(ServerScriptService:FindFirstChild("Varld"), "Anlaggningen"))
	rad(ut, "1f anläggningen är byggd", varldenFinns and workspace:FindFirstChild("Anläggning") ~= nil)

	--[[ 2. Spawnkontrakt: exakt EN avsedd spawn, och den ska stå vid rätt
		dörr. En QA-/legacy-spawn får inte vinna. ]]
	local spawnar = {}
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("SpawnLocation") then table.insert(spawnar, d) end
	end
	local egna = 0
	for _, s in ipairs(spawnar) do
		if s:GetAttribute("UBRFStart") == true then egna += 1 end
	end
	rad(ut, "2a exakt en First Playable-spawn", egna == 1,
		("%d UBRFStart av %d SpawnLocation totalt"):format(egna, #spawnar))
	rad(ut, "2b ingen annan SpawnLocation vinner", #spawnar == egna,
		("%d SpawnLocation totalt"):format(#spawnar))
	local start = nil
	for _, s in ipairs(spawnar) do
		if s:GetAttribute("UBRFStart") == true then start = s end
	end
	rad(ut, "2c spawnen står vid stallets entrédörr",
		start ~= nil and start:GetAttribute("MotDorr") == "stall N dorrgul",
		start and tostring(start:GetAttribute("MotDorr")) or "ingen spawn")

	--[[ 3. Dörrkontrakt: verklig interaktion, inte en gul markör. ]]
	local okDorr, DorrService = pcall(function()
		return require((ServerScriptService :: any).Horse.DorrService)
	end)
	local dorrar = if okDorr then (DorrService :: any).dorrar() else {}
	rad(ut, "3a dörrblad med interaktion finns", #dorrar > 0, ("%d st"):format(#dorrar))
	local medPrompt = 0
	for _, blad in ipairs(dorrar) do
		if blad:FindFirstChildOfClass("ProximityPrompt") then medPrompt += 1 end
	end
	rad(ut, "3b varje dörrblad har en prompt", #dorrar > 0 and medPrompt == #dorrar,
		("%d prompt av %d dörrar"):format(medPrompt, #dorrar))
	--[[ Att den GÅR ATT ÖPPNA och släpper igenom, inte bara att den finns. ]]
	local oppnadeOk = 0
	if okDorr then
		for _, blad in ipairs(dorrar) do
			if (DorrService :: any).provaOppna(blad) then oppnadeOk += 1 end
		end
	end
	rad(ut, "3c dörren öppnas och släpper igenom", #dorrar > 0 and oppnadeOk == #dorrar,
		("%d av %d"):format(oppnadeOk, #dorrar))

	--[[ 4. Jack-kontrakt. Identiteten LÄSES ur den delade sanningen —
		`Stallet.FORSTA_DAGEN_HAST`, samma konstant som `tools/kolla-forstadagen.py`
		håller i synk mellan webben och Roblox. Att leta på namnet "Jack" hade
		varit ett eget påhitt: hästen heter "Blackrock Jack" i datan, och
		`hastar` är dessutom en uppslagstabell och ingen lista, så en
		namnsökning hade tystnat grön utan att mäta något. ]]
	local okStall, Stallet = pcall(function()
		return require((ReplicatedStorage :: any).Stallet)
	end)
	local okData, Spel = pcall(function()
		return require((ReplicatedStorage :: any).UBRFSpelData)
	end)
	local forstaId = if okStall then tostring((Stallet :: any).FORSTA_DAGEN_HAST) else nil
	rad(ut, "4a första dagens häst är utpekad i Stallet", forstaId ~= nil and forstaId ~= "nil",
		tostring(forstaId))

	local hast = nil
	if okData and forstaId and typeof(Spel) == "table" then
		hast = ((Spel :: any).hastar or {})[forstaId]
	end
	rad(ut, "4b hästen finns i speldatan", hast ~= nil,
		if hast then tostring((hast :: any).namn) else "hittades inte")

	--[[ 4c: att hon har en box med världskoordinater. Att gången DIT är fri
		mäts inte här — det kräver karaktär och fysik, och står som
		`Physical not tested` i rapporten i stället för att gissas grönt. ]]
	local box = nil
	if okStall and forstaId then
		local okBox, b = pcall(function() return (Stallet :: any).boxFor(forstaId) end)
		if okBox then box = b end
	end
	rad(ut, "4c hästens box har världskoordinater",
		box ~= nil and (box :: any).varld ~= nil,
		if box and (box :: any).varld
			then ("x %.1f y %.1f"):format((box :: any).varld.x, (box :: any).varld.y)
			else "ingen box")

	--[[ 7. Klient/UI verkligen i builden, inte bara i repot. ]]
	local horseKlient = klient and klient:FindFirstChild("Horse")
	for _, namn in ipairs({ "KontrollHjalp", "TouchControls", "Input", "PreparationController" }) do
		rad(ut, "7 StarterPlayerScripts/Horse/" .. namn, finns(horseKlient, namn))
	end

	--[[ 8. Persistens: att vägen kan initieras. Utan API-åtkomst i Studio
		ska det bli en tydlig VARNING och aldrig ett falskt PASS — därför
		mäts bara att tjänsten finns och svarar, inte att den lyckas skriva. ]]
	rad(ut, "8 SparService finns i builden", finns(horse, "SparService"))

	return ut
end

function Preflight.kor(varldenFinns: boolean)
	local sha, miljo = buildIdentitet()
	print(("FIRST_PLAYABLE_SHA=%s"):format(sha))
	print(("FIRST_PLAYABLE_MILJO_SHA=%s"):format(miljo))

	local matt = Preflight.matningar(varldenFinns)
	local fel = {}
	for _, r in ipairs(matt) do
		if r.ok then
			print(("  OK   %s%s"):format(r.namn, if r.detalj then "  " .. r.detalj else ""))
		else
			table.insert(fel, r.namn)
			warn(("  SAKNAS  %s%s"):format(r.namn, if r.detalj then "  " .. r.detalj else ""))
		end
	end

	--[[ Okänd build är ett fel i sig: då vet ingen vad som testades. ]]
	if sha == "OKÄND" then
		table.insert(fel, "9 build-identitet (ReplicatedStorage.UBRFBuild)")
		warn("  SAKNAS  9 build-identitet — går inte att veta vilken head som testas")
	end

	local flagga = ReplicatedStorage:FindFirstChild("UBRFPreflight")
	if not flagga then
		flagga = Instance.new("BoolValue")
		flagga.Name = "UBRFPreflight"
		flagga.Parent = ReplicatedStorage
	end
	;(flagga :: BoolValue).Value = #fel == 0

	if #fel == 0 then
		print("FIRST_PLAYABLE_PREFLIGHT: PASS")
	else
		warn(("FIRST_PLAYABLE_PREFLIGHT: FAIL — %d saknas: %s")
			:format(#fel, table.concat(fel, ", ")))
		warn("STOPP: det här är inte en First Playable-build. Fortsätt INTE "
			.. "med fysisk acceptans; rapportera raderna ovan.")
	end
end

return Preflight
