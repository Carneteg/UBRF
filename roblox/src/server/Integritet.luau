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

--[[ ── RUNTIME SOM INTE GÅR ATT KÄNNA IGEN PÅ NAMNET ────────────────────

	`RUNTIME` ovan slår upp på namn, och det räcker för det servern bygger på
	en fast plats. Workspace fylls dessutom av objekt vars namn kommer ur
	SPELDATA eller ur spelaren: varje häst heter som hästen, och boxmarkörer
	och karaktärer heter som den som loggade in. Namnuppslag kan alltså aldrig
	fånga dem.

	Utan de här reglerna blev punkt 10e obrukbar i drift. Mätt i en levande
	server-VM på `203357f`: raden namngav 49 ospårade objekt i Workspace, men
	34 av dem var serverns egna — 33 hästar, en karaktär och en uppsättning
	boxmarkörer. De 15 som blir kvar är den faktiska driften, och det är den
	siffran raden finns för att visa.

	Varje regel pekar ut sin källa i koden. En regel utan en rad som bevisligen
	skapar objektet hör inte hemma här: då är gissningen tillbaka.

	REGLERNA ÄR AVSIKTLIGT SVAGA MOT FÖRFALSKNING — en främmande modell som
	taggar sig `Horse` läses som runtime. Det är acceptabelt just för att 10e
	RAPPORTERAR och aldrig fäller; den som vill dölja något behöver inte
	anstränga sig så mycket. Skulle en regel någon gång användas av en
	FÄLLANDE rad måste den prövas om. ]]
type Runtimeregel = { kalla: string, prov: (Instance) -> boolean }

local RUNTIMEREGLER: { [string]: { Runtimeregel } } = {
	Workspace = {
		{
			kalla = "server/HastRigg.luau + HastVisual.luau (taggen Horse)",
			prov = function(inst)
				local ok, taggad = pcall(function()
					return game:GetService("CollectionService"):HasTag(inst, "Horse")
				end)
				return ok and taggad == true
			end,
		},
		{
			kalla = "server/StallService.luau:62 (Boxmarkor_<spelare>)",
			prov = function(inst)
				return inst.Name:sub(1, 10) == "Boxmarkor_"
			end,
		},
		{
			kalla = "Players — spelarens egen karaktär",
			prov = function(inst)
				local ok, spelare = pcall(function()
					return game:GetService("Players"):GetPlayerFromCharacter(inst)
				end)
				return ok and spelare ~= nil
			end,
		},
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
	for _, regel in ipairs(RUNTIMEREGLER[tjanst] or {}) do
		if regel.prov(barn) then return "runtime" end
	end
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

--[[ ══ BESKRIVER IDENTITETEN KODEN SOM FAKTISKT LIGGER HÄR? (#171) ═════

	9a–9d prövar att identiteten FINNS, är GENERERAD och har rätt FORM. Ingen
	av dem prövar att den beskriver den här placens källor. En identitet som
	genererats ur ett annat källäge — en gren, en äldre commit, en place som
	tappat Rojo mitt i ett pass — går igenom alla fyra.

	DET IDEALA MÅTTET GÅR INTE ATT TA. `kallhash` är beviset, och placen bär
	källorna i `ModuleScript.Source`. Men ett SPELSKRIPT FÅR INTE LÄSA
	`Source`. Uppmätt i en levande server-VM på `a5a4b71`:

	    ServerScriptService.Horse.Integritet:247 function kallbytes
	    The current thread cannot read 'Source'
	    (lacking capability PluginOrOpenCloud)

	Ett första försök summerade just `#Source` och föll därför exakt där
	grinden bor. Talet stämde — 1 234 328 i både repo och place, mätt från
	edit-kontexten — men det går inte att nå från runtime, och en mätning som
	bara fungerar i verktyget mäter inte grinden.

	DET SOM GÅR ATT RÄKNA ÄR INSTANSERNA. `IsA` och `GetDescendants` kräver
	ingen läsrätt på källan. Antalet Rojo-ägda skriptobjekt i placen ska vara
	exakt `kallor` — identiteten själv oräknad, av samma skäl som generatorn
	utesluter den ur hashen.

	RÄKNINGEN GÅR PÅ `kallrotter`, INTE PÅ `rojo`. `rojo` säger vilka
	toppnivåinstanser som är källstyrda och räcker för att klassa skräp
	bredvid dem, men `StarterPlayerScripts` är en behållare Rojo delar med
	motorn: vid speltest lägger Roblox sina egna `RbxCharacterSounds` och
	`AtomicBinding` där. Mätt i en levande server-VM på `e5ba1ae`, med den
	grova listan: **69 mot identitetens 67 — två falska larm**, båda motorns
	egna. `kallrotter` är i stället varje `$path` i projektfilen med sin fulla
	väg, så bara det Rojo faktiskt fyller räknas.

	SVAGARE ÄN HASHEN, och det ska sägas rakt ut: en fil som redigeras utan
	att läggas till eller tas bort glider igenom. Den fångar tillagda och
	borttagna källor, och en place som synkats från ett annat projektträd.
	Resten måste försvaras utanför placen — `bygg-identitet.py --kontrollera`
	i CI räknar om hashen på riktigt. ]]
function Integritet.kallantal(): number?
	local id = Integritet.identitet()
	if not id then return nil end
	local rotter = (id :: any).kallrotter
	--[[ Saknas listan är identiteten genererad av ett äldre verktyg. Då är
		svaret "kan inte mätas" — aldrig ett tal som råkar stämma. ]]
	if typeof(rotter) ~= "table" then return nil end
	local bygget = ReplicatedStorage:FindFirstChild("UBRFBuild")
	local antal = 0
	for _, vag in ipairs(rotter) do
		local nod: Instance? = nil
		for led in tostring(vag):gmatch("[^%.]+") do
			if nod == nil then
				local ok, tjansten = pcall(game.GetService, game, led)
				nod = if ok then tjansten else nil
			else
				nod = (nod :: Instance):FindFirstChild(led)
			end
			if nod == nil then break end
		end
		if nod then
			local function rakna(d: Instance)
				if d:IsA("LuaSourceContainer") and d ~= bygget then antal += 1 end
			end
			rakna(nod)
			for _, d in ipairs(nod:GetDescendants()) do rakna(d) end
		end
	end
	return antal
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

	--[[ 9e är den som gör de fyra ovan till mer än en formkontroll. Se noten
		vid `Integritet.kallantal` för vad den kan och inte kan fånga. Saknas
		talet i identiteten är den genererad av ett äldre verktyg — och då är
		svaret "kan inte mätas", inte "grönt". ]]
	local vantad = id and id.kallor
	local faktisk = Integritet.kallantal()
	rad("9e placen bär lika många källor som identiteten räknade",
		typeof(vantad) == "number" and faktisk ~= nil and faktisk == vantad,
		if typeof(vantad) ~= "number" then
			"identiteten bär ingen kallor — kan inte mätas"
		elseif faktisk == nil then "identiteten bär ingen kallrotter — kan inte mätas"
		elseif faktisk == vantad then ("%d skriptobjekt"):format(faktisk)
		else ("placen har %d, identiteten säger %d (%+d)"):format(
			faktisk, vantad :: number, faktisk - (vantad :: number)))

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

	--[[ 10d ServerScriptService är den andra tjänsten där en ospårad sak
		NÅR RUNTIME: ett skript där körs. Samma skäl som 10c, och samma
		hårdhet. ]]
	local osparadeSSS = Integritet.osparade("ServerScriptService")
	rad("10d inget ospårat i ServerScriptService", #osparadeSSS == 0,
		if #osparadeSSS == 0 then "-" else table.concat(osparadeSSS, ", "))

	--[[ ── 10e RAPPORTERAR, FÄLLER INTE ─────────────────────────────────

		Workspace och ServerStorage bär i dag sådant ingen källa äger:
		importerade modeller i Workspace-roten, och stora artefakter i
		ServerStorage. Mätt på `a5a4b71`:

		    Workspace       15 ospårade (Jumps, SADDLE, fem Model, …)
		    ServerStorage    2 ospårade (HastVisualer 85 ättlingar,
		                     UBRF_BACKUP_SUP0062 3 477 ättlingar)

		Ingen av dem når runtime av sig själv, och #171 är uttrycklig: klassa
		först, radera bara det som bevisats icke-kanoniskt, aldrig blint. Att
		fälla grinden på dem hade gjort den permanent röd tills någon städar
		— och modulens egen not säger varför det är fel väg.

		MEN TYSTNAD VAR DET SOM GJORDE EVIDENSEN OPÅLITLIG. Före den här
		raden kunde en grön preflight läsas som "placen är ren" medan
		sjutton objekt ingen källa äger låg kvar. Raden är därför grön och
		ALLTID närvarande: antalet och namnen står i utskriften, varje
		körning, så att ingen behöver gissa. ]]
	local wsOsp = Integritet.osparade("Workspace")
	local ssOsp = Integritet.osparade("ServerStorage")
	local delar = {}
	if #wsOsp > 0 then
		table.insert(delar, ("Workspace %d: %s"):format(#wsOsp, table.concat(wsOsp, ", ")))
	end
	if #ssOsp > 0 then
		table.insert(delar, ("ServerStorage %d: %s"):format(#ssOsp, table.concat(ssOsp, ", ")))
	end
	rad("10e ospårat i Workspace/ServerStorage — redovisat, inte fällt", true,
		if #delar == 0 then "inga" else table.concat(delar, " · "))

	return ut
end

return Integritet
