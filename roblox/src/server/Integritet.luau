--!strict
--[[
	PLACE-INTEGRITET — vad i placen är källstyrt, vad är runtime, vad är
	främmande?

	Bakgrund (#171). En läsande Studio-audit av den anslutna UBRF-placen
	visade en obehaglig kombination: Rojo-träden stämde exakt mot repot, och
	ändå gick det inte att lita på ett enda QA-resultat ur placen.

	Två skäl.

	1. `ReplicatedStorage.UBRFBuild` var handplacerad och pekade på en head
	   44 commits gammal. Preflightens punkt 9 läste den och sa PASS. Grinden
	   som ska svara på "vilken kod testas?" svarade alltså med fel svar.

	2. Placen bar kvarglömda objekt som ingen källa äger: främmande importer
	   i Workspace-roten, och runtime-skapade objekt som sparats ned i
	   edit-läge.

	SKILLNADEN SOM SPELAR ROLL, och som den här modulen finns för att mäta:

	`TackForradService.start` river sin mapp och bygger om den vid varje
	serverstart. En kvarglömd `Workspace.Tackförråd` är därför skräp i
	editorn men självläkande i drift.

	`Networking.get` gör tvärtom: den ÅTERANVÄNDER det som redan ligger i
	ReplicatedStorage. Ett fjärrobjekt som tagits bort ur koden eller döpts
	om ligger alltså kvar i en sparad place och följer med in i runtime, där
	ingen längre vet vem som äger det.

	Bara den andra sorten är ett riktigt driftfel. Grinden fäller därför den,
	och rapporterar den första. Att fälla allt hade gjort grinden till brus,
	och en grind som alltid är röd slutar man läsa.

	INGEN AV DE HÄR FUNKTIONERNA TAR BORT NÅGOT. #171 är uttrycklig: klassa
	först, radera bara det som bevisats icke-kanoniskt, och aldrig blint.
	Modulen mäter och namnger. Vad som ska städas är Tobias beslut.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local StarterPlayer = game:GetService("StarterPlayer")

--[[ Networking läses LAT och i pcall. Preflighten ska kunna rapportera att
	HorseCore saknas — inte dö på att den saknas. En grind som kraschar när
	bygget är trasigt lämnar ingen rad efter sig, och en tom rapport är den
	sortens tystnad som #171 handlar om. ]]
local function facit(): { [string]: string }?
	local ok, Networking = pcall(function()
		return require(ReplicatedStorage.HorseCore.Networking)
	end)
	if not ok or typeof(Networking) ~= "table" then return nil end
	local ok2, def = pcall(function()
		return (Networking :: any).definitioner()
	end)
	if not ok2 or typeof(def) ~= "table" then return nil end
	return def :: any
end

local Integritet = {}

export type Klass = "kanonisk" | "runtime" | "verktyg" | "ospårad"
export type Post = { namn: string, klass: Klass, detalj: string? }

--[[ Lägen en GENERERAD identitet får ha. Den handplacerade modulen ur #171
	hade `lage = "rojo-live"` och ingen `kallhash` alls — den faller på båda
	raderna, vilket är hela poängen. ]]
local KANDA_LAGEN = { rojo = true, place = true }

--[[ Objekt som koden skapar vid körning. De är inte källstyrda och ska
	inte vara det, men de är heller inte främmande.

	Listan är kort med flit: varje namn här är ett ställe där en människa
	måste ha läst koden och sett var det skapas. Sökvägarna står i
	`docs/STUDIO-PLACE-INTEGRITY.md`. ]]
local RUNTIME: { [string]: { [string]: string } } = {
	ReplicatedStorage = {
		HorseRemotes = "HorseCore/Networking.luau",
		MinHast = "server/StallService.luau",
		UBRFPreflight = "server/Preflight.luau",
	},
	Workspace = {
		["Anläggning"] = "server/Varld/Anlaggningen.luau",
		["Tackförråd"] = "server/TackForradService.luau",
	},
}

--[[ Motorns egna barn i Workspace. De finns i varje place och ägs varken
	av Rojo eller av oss. ]]
local MOTORKLASSER = { Terrain = true, Camera = true }

--[[ Verktygsspår: plugin- och synkartefakter. De hör inte till bygget men
	är heller inte okända — och de ska inte fälla en grind, eftersom de dyker
	upp och försvinner med verktygen som skapade dem. ]]
local function arVerktyg(namn: string): boolean
	return namn:sub(1, 2) == "__"
end

--[[ Identiteten. Returnerar nil när den saknas eller inte går att läsa —
	fail closed sköts av den som frågar, inte av ett tyst standardvärde. ]]
function Integritet.identitet(): { [string]: any }?
	local m = ReplicatedStorage:FindFirstChild("UBRFBuild")
	if not m or not m:IsA("ModuleScript") then return nil end
	local ok, data = pcall(require, m)
	if not ok or typeof(data) ~= "table" then return nil end
	return data :: any
end

--[[ Vad Rojo äger, enligt den genererade identiteten. Tom tabell när
	identiteten saknas: då är INGET bevisat källstyrt, och klassningen blir
	konservativ i stället för generös. ]]
local function rojoAgda(tjanst: string): { [string]: boolean }
	local ut: { [string]: boolean } = {}
	local id = Integritet.identitet()
	local karta = id and (id.rojo :: any)
	local lista = karta and karta[tjanst]
	if typeof(lista) == "table" then
		for _, namn in ipairs(lista) do ut[tostring(namn)] = true end
	end
	return ut
end

function Integritet.klassificera(tjanst: string, barn: Instance): Klass
	if MOTORKLASSER[barn.ClassName] then return "kanonisk" end
	if rojoAgda(tjanst)[barn.Name] then return "kanonisk" end
	local runtime = RUNTIME[tjanst]
	if runtime and runtime[barn.Name] then return "runtime" end
	if arVerktyg(barn.Name) then return "verktyg" end
	return "ospårad"
end

--[[ Hela inventeringen för en tjänst. Används av rapporten och av
	policydokumentet; den fäller ingenting själv. ]]
function Integritet.inventering(tjanst: string): { Post }
	local tjansten: Instance? = ({
		ReplicatedStorage = ReplicatedStorage,
		ServerScriptService = ServerScriptService,
		ServerStorage = ServerStorage,
		StarterPlayer = StarterPlayer,
		Workspace = workspace,
	} :: any)[tjanst]
	local ut: { Post } = {}
	if not tjansten then return ut end
	for _, barn in ipairs(tjansten:GetChildren()) do
		local klass = Integritet.klassificera(tjanst, barn)
		local detalj = nil
		local runtime = RUNTIME[tjanst]
		if klass == "runtime" and runtime then detalj = runtime[barn.Name] end
		table.insert(ut, { namn = barn.Name, klass = klass, detalj = detalj })
	end
	table.sort(ut, function(a, b) return a.namn < b.namn end)
	return ut
end

--[[ Fjärrobjekt som ligger i placen men inte längre finns i facit.

	Den här överlever till runtime — `Networking.get` återanvänder mappen —
	och är därför den enda artefakten som fäller grinden hårt.

	Returnerar nil när facit inte går att läsa: "kan inte mätas" är inte
	samma sak som "inget hittat", och bara den ena av dem får bli grön. ]]
function Integritet.okandaRemotes(): { string }?
	local mapp = ReplicatedStorage:FindFirstChild("HorseRemotes")
	if not mapp then return {} end
	local def = facit()
	if not def then return nil end
	local ut: { string } = {}
	for _, r in ipairs(mapp:GetChildren()) do
		if not def[r.Name] then
			table.insert(ut, ("%s (%s)"):format(r.Name, r.ClassName))
		end
	end
	table.sort(ut)
	return ut
end

--[[ Fjärrobjekt som facit kräver men som har FEL KLASS i placen. En
	RemoteEvent där koden väntar sig en RemoteFunction kastar först när
	någon anropar den — alltså mitt i ett spelprov, inte i grinden. ]]
function Integritet.felklassadeRemotes(): { string }?
	local mapp = ReplicatedStorage:FindFirstChild("HorseRemotes")
	if not mapp then return {} end
	local def = facit()
	if not def then return nil end
	local ut: { string } = {}
	for namn, klass in def do
		local r = mapp:FindFirstChild(namn)
		if r and r.ClassName ~= klass then
			table.insert(ut, ("%s är %s, ska vara %s"):format(namn, r.ClassName, klass))
		end
	end
	table.sort(ut)
	return ut
end

function Integritet.osparade(tjanst: string): { string }
	local ut: { string } = {}
	for _, post in ipairs(Integritet.inventering(tjanst)) do
		if post.klass == "ospårad" then table.insert(ut, post.namn) end
	end
	return ut
end

--[[ Raderna som Preflighten lägger in. Samma form som dess egna: namn, ok,
	detalj — så att specen kan läsa dem ur tjänstens utdata i stället för att
	göra om villkoret. ]]
export type Rad = { namn: string, ok: boolean, detalj: string? }

function Integritet.rader(): { Rad }
	local ut: { Rad } = {}
	local function rad(namn: string, ok: boolean, detalj: string?)
		table.insert(ut, { namn = namn, ok = ok, detalj = detalj })
	end

	--[[ 9. BUILD-IDENTITET. Fail closed i fyra steg: finns, går att läsa,
		är genererad, och bär en hash med rätt form. Punkt 9 hade tidigare
		bara det första steget, och det var därför en handplacerad modul med
		fel SHA kunde hålla den grön i 44 commits. ]]
	local id = Integritet.identitet()
	rad("9a build-identitet finns och går att läsa", id ~= nil,
		if id then "ReplicatedStorage.UBRFBuild" else "saknas eller trasig")

	local lage = id and tostring(id.lage) or "OKÄND"
	rad("9b identiteten är genererad, inte handplacerad",
		id ~= nil and KANDA_LAGEN[lage] == true,
		("lage=%s"):format(lage))

	local hash = id and tostring(id.kallhash or "") or ""
	local formOk = #hash == 64 and hash:match("^%x+$") ~= nil
	rad("9c källhashen har rätt form", formOk,
		if hash == "" then "ingen kallhash — identiteten är inte genererad"
		else ("%s (%d tecken)"):format(hash:sub(1, 12), #hash))

	rad("9d identiteten vet hur många källor den räknade",
		id ~= nil and typeof(id.kallor) == "number" and (id.kallor :: number) > 0,
		if id then tostring(id.kallor) else "-")

	--[[ 10. KVARGLÖMDA RUNTIME-ARTEFAKTER. ]]
	local okanda = Integritet.okandaRemotes()
	rad("10a inga okända fjärrobjekt i HorseRemotes",
		okanda ~= nil and #okanda == 0,
		if okanda == nil then "Networking går inte att läsa — kan inte mätas"
		elseif #okanda == 0 then "alla matchar Networking.definitioner()"
		else table.concat(okanda, "; "))

	local felklassade = Integritet.felklassadeRemotes()
	rad("10b varje fjärrobjekt har rätt klass",
		felklassade ~= nil and #felklassade == 0,
		if felklassade == nil then "Networking går inte att läsa — kan inte mätas"
		elseif #felklassade == 0 then "-" else table.concat(felklassade, "; "))

	--[[ 10c ReplicatedStorage är den tjänst där en ospårad modul gör mest
		skada: allt där replikeras till varje klient. ]]
	local osparade = Integritet.osparade("ReplicatedStorage")
	rad("10c inget ospårat i ReplicatedStorage", #osparade == 0,
		if #osparade == 0 then "-" else table.concat(osparade, ", "))

	return ut
end

return Integritet
