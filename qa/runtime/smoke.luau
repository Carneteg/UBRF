--!nolint
--[[
	RUNTIME-SMOKEN — #252 DEL C.

	Körs SERVERSIDE i riktig Roblox-motor, antingen genom Open Cloud
	Luau Execution mot en publicerad place-version, eller lokalt i
	Studios serverruntime. Samma fil på båda ställena; den innehåller
	inga stubbar och require:ar produktionens egna moduler.

	══ VAD DEN ÄR TILL FÖR ═════════════════════════════════════════════

	Bänken i `roblox/tests/` är en handskriven stubbvärld. Den kan inte
	se saknade instanser, felaktiga instansegenskaper, en weld som inte
	byggs, fysik som inte följer eller state som inte rivs. Den här filen
	mäter precis det, i motorn.

	`audits/BANK-AUDIT-2026-09-19.md` § 7 pekar ut fyra påståenden som
	stått som «klara» utan att någonsin ha körts. De är avsnitt 6, 7, 8
	och 10 nedan, och var och en ska kunna bli röd ensam.

	══ KONTRAKTET MED DRIVAREN ═════════════════════════════════════════

	Drivaren (`tools/runtime-grind.py`) sätter före körning:

	    _G.UBRF_VANTAD_KALLHASH  -- bygg-identiteten ur PR-head
	    _G.UBRF_DEL              -- "alla" eller ett avsnittsnamn
	    _G.UBRF_MUTATION         -- falsifieringens namn, annars nil

	och läser returvärdet:

	    { kallhash, del, antal, fel, sekunder, rader = { {avsnitt, namn, ok, detalj} } }

	FAIL CLOSED: allt som inte gick att mäta räknas som FEL. En smoke som
	svarar «hoppade över» är inte ett PASS, och frånvaron av ett nej är
	inte ett ja. Kastar filen alls blir task-statusen FAILED, vilket
	drivaren också läser som rött.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local T0 = os.clock()

--[[ ══ RAPPORTEN ═════════════════════════════════════════════════════ ]]

local rader: { any } = {}
local antal, fel = 0, 0
local aktuelltAvsnitt = "-"

--[[ Vilka avsnitt som ska köras. Taket i Luau Execution är fem minuter
	per task; drivaren kan dela upp körningen på flera tasks genom
	`_G.UBRF_DEL`, och en okänd del är RÖTT, inte tomt. ]]
local DEL = tostring(_G.UBRF_DEL or "alla")
local AVSNITT = {
	"identitet", "boot", "varldsintegritet", "bindning", "tackkedjan",
	"ridanu", "mountrequest", "boxfront", "ledning", "flerledning",
	"stadning",
}

local function avsnitt(namn: string)
	aktuelltAvsnitt = namn
	print(("-- %s --"):format(namn))
end

local function kolla(namn: string, villkor: any, detalj: any?)
	antal += 1
	local ok = villkor == true
	if not ok then fel += 1 end
	table.insert(rader, {
		avsnitt = aktuelltAvsnitt,
		namn = namn,
		ok = ok,
		detalj = if detalj == nil then "" else tostring(detalj),
	})
	print(("%s  %s%s"):format(
		if ok then "OK  " else "FEL ",
		namn,
		if detalj == nil then "" else "  [" .. tostring(detalj) .. "]"))
end

--[[ ══ DET SOM INTE GÅR ATT MÄTA HÄR ═══════════════════════════════════

	Open Clouds Luau Execution kör INTE fysikintegration. Roblox
	dokumenterar det rakt ut: «In a task, physics simulation does not
	run», och `RunService:IsRunning()` är false i den här kontexten.

	Hästen leds av `AlignPosition` och `AlignOrientation` — fysik-
	constraints, enligt arkitekturkontraktet i #235 FAS 4. De skapas
	korrekt här, vilket mäts och passerar, men de integrerar aldrig. Hon
	står alltså still, och det säger ingenting om ledningens logik.

	MÄTT, INTE ANTAGET: `motorn stegade bildrutor` gav 239 bildrutor i
	run 35584589800. Heartbeat FYRAR här. Det är fysikintegrationen som
	saknas, inte schemaläggaren — och den skillnaden får inte suddas ut
	genom att kalla allt tidsberoende omätbart.

	VARFÖR EN EGEN KATEGORI I STÄLLET FÖR OK ELLER FEL:

	Som FEL ljuger grinden rött om en produktionsbugg som inte finns.
	Som OK ljuger fyra av dem grönt — en häst som aldrig rör sig kan
	inte teleportera och inte oscillera, så påståenden om FRÅNVARO av
	dålig rörelse uppfylls tomt av FRÅNVARO av rörelse. Det är samma
	felsort som `CharacterAutoLoads`-passet i #264: grönt av fel skäl.

	Raden räknas därför varken som mätning eller som fel. Den syns i
	rapporten med sitt skäl, och täckningen finns i Studio i stället.

	EGEN LISTA, INTE `rader`. Drivaren gör `if not rad.get("ok")` på varje
	rad i `rader` och skriver ut den som FEL — en rad utan dom hade alltså
	blivit ett falskt rött i sammanfattningen, exakt det vi tar bort här.
	KTX-raderna returneras därför i `ejMatbaraRader`, som drivaren inte
	rör. ]]
local ejMatbara = 0
local ejRader: { any } = {}

local function ejMatbar(namn: string, skal: string, detalj: any?)
	ejMatbara += 1
	table.insert(ejRader, {
		avsnitt = aktuelltAvsnitt,
		namn = namn,
		skal = skal,
		detalj = if detalj == nil then "" else tostring(detalj),
	})
	print(("KTX   %s  [%s]%s"):format(
		namn, skal,
		if detalj == nil then "" else "  obs: " .. tostring(detalj)))
end

--[[ Ett avsnitt som kastade är ett FEL, inte en tystnad. ]]
local function skyddat(namn: string, f: () -> ())
	if DEL ~= "alla" and DEL ~= namn then return end
	local ok, felmeddelande = pcall(f)
	if not ok then
		aktuelltAvsnitt = namn
		kolla(namn .. ": avsnittet kastade", false, felmeddelande)
	end
end

do
	local kand = false
	for _, n in ipairs(AVSNITT) do if n == DEL then kand = true end end
	if DEL ~= "alla" and not kand then
		aktuelltAvsnitt = "start"
		kolla("drivaren bad om ett känt avsnitt", false, DEL)
	end
end

--[[ ══ VÄRLDEN SKA VARA BYGGD INNAN VI MÄTER HENNE ══════════════════

	Servern bygger anläggningen och startar tjänsterna i `Start.luau`.

	FÖRRA VARIANTEN VÄNTADE, OCH DEN VÄNTAN KUNDE ALDRIG LYCKAS. Open
	Clouds Luau Execution kör inte placens egna Scripts — Roblox
	dokumenterar det rakt ut: «Server and local scripts within the place
	also do not automatically run … including invoking any module
	scripts». `init.server.luau` är ett Script, så det startade aldrig,
	och de 120 sekunderna var en garanterad förlust följd av 16 fel.
	Mätt i #264, run 35578447658: noll `[Horse]`-rader i hela loggen.

	ModuleScripts är undantaget. Vi startar därför servern SJÄLVA, genom
	produktionens egen `Start.kor()` — samma modul som `init.server.luau`
	anropar. Ingen kopia, ingen stubb: en egen uppstart här hade mätt sig
	själv i stället för spelet. ]]
local Horse = ServerScriptService:WaitForChild("Horse", 60)
local Start = require(Horse:WaitForChild("Start", 30))
local startOk = Start.kor()

local varldenStar = workspace:FindFirstChild("Anläggning") ~= nil
	and ReplicatedStorage:GetAttribute("G01Enabled") == true

--[[ ══ MODULERNA ═════════════════════════════════════════════════════

	Produktionens egna. Ingen kopia, ingen stubb. Faller ett require är
	det ett riktigt fel och smoken ska dö på det.

	`Horse` är redan hämtad ovanför, där starten kördes. ]]
local GameplayService = require(Horse.GameplayService)
local HorseService = require(Horse.HorseService)
local LedService = require(Horse.LedService)
local StallService = require(Horse.StallService)
local TackService = require(Horse.TackService)
local TackRigg = require(Horse.TackRigg)
local TackForradService = require(Horse.TackForradService)

local Preparation = require(ReplicatedStorage.HorseCore.Preparation)
local Networking = require(ReplicatedStorage.HorseCore.Networking)
local Sprak = require(ReplicatedStorage.HorseCore.Sprak)
local Spel = require(ReplicatedStorage.UBRFSpel)

local M = 3 -- studs per meter, som BuildKit.M och LedService

--[[ ══ TESTSÄTET ═════════════════════════════════════════════════════

	En aktör, inte en fejkad `Players`-tjänst. Den bär userId, namn, en
	RIKTIG karaktärsmodell med `HumanoidRootPart` och `Humanoid`, och de
	två karaktärssignalerna som tjänsterna kopplar sig till.

	`harKlient = false` är den enda avvikelsen från en spelare, och den
	är deklarerad: det finns ingen klient i andra änden av ett
	`FireClient`. Se `HorseCore/Aktor.luau`.

	Mätt i motorn: `Instance.new("Player")` och
	`Players:CreateLocalPlayer(1)` ger båda «lacking capability
	WritePlayer». Det finns alltså ingen väg till en riktig spelare här,
	och sätet är svaret på det — inte en genväg förbi något. ]]
local function nySignal()
	local lyssnare = {}
	local s = {}
	function s:Connect(f)
		table.insert(lyssnare, f)
		local c = { Connected = true }
		function c:Disconnect()
			c.Connected = false
			for i, g in ipairs(lyssnare) do
				if g == f then table.remove(lyssnare, i) break end
			end
		end
		return c
	end
	function s:Fire(...)
		for _, f in ipairs(table.clone(lyssnare)) do task.spawn(f, ...) end
	end
	return s
end

local skrap: { Instance } = {}
local saten: { any } = {}

local function nyKaraktar(namn: string, pos: Vector3): Model
	local k = Instance.new("Model")
	k.Name = namn
	local rot = Instance.new("Part")
	rot.Name = "HumanoidRootPart"
	rot.Size = Vector3.new(2, 2, 1)
	rot.CFrame = CFrame.new(pos)
	--[[ Ryttaren står still av sig själv: hon har ingen klient som
		simulerar henne, och en icke-ankrad kropp faller genom världen
		medan provet mäter något annat. ]]
	rot.Anchored = true
	rot.CanCollide = false
	rot.Transparency = 1
	rot.Parent = k
	k.PrimaryPart = rot
	local hum = Instance.new("Humanoid")
	hum.Name = "Humanoid"
	hum.Parent = k
	k.Parent = workspace
	table.insert(skrap, k)
	return k
end

local nastaUserId = 90000
local function nyttSate(namn: string, pos: Vector3)
	nastaUserId += 1
	local karaktar = nyKaraktar(namn .. "Kropp", pos)
	local sate = {
		Name = namn,
		UserId = nastaUserId,
		Character = karaktar,
		harKlient = false,
		CharacterAdded = nySignal(),
		CharacterRemoving = nySignal(),
	}
	table.insert(saten, sate)
	return sate, karaktar, karaktar.PrimaryPart
end

local function stall(sate: any, pos: Vector3)
	sate.Character.PrimaryPart.CFrame = CFrame.new(pos)
end

--[[ Ställ sätet inom räckhåll för något. Avstånden är produktionens egna
	(`STEG_RACKVIDD`, `RACKVIDD`), så provet får inte gissa dem. ]]
local function delenAv(inst: Instance?): BasePart?
	if not inst then return nil end
	if inst:IsA("BasePart") then return inst :: BasePart end
	if inst:IsA("Model") then
		local m = inst :: Model
		return m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart", true)
	end
	return nil
end

local function stallVid(sate: any, inst: Instance?, meter: number): boolean
	local del = delenAv(inst)
	if not del then return false end
	stall(sate, del.Position + Vector3.new(meter * M, 0, 0))
	return true
end

local function hastMed(id: string?): Model?
	if not id then return nil end
	for _, q in ipairs(CollectionService:GetTagged("Horse")) do
		if q:GetAttribute("HorseId") == id then return q end
	end
	return nil
end

--[[ Full nedkoppling genom produktionens EGNA handlare, i samma ordning
	som `PlayerRemoving` fyrar dem. Inte en kopia av vad de gör. ]]
local function kopplaNer(sate: any)
	pcall(HorseService.lamnar, sate)
	pcall(LedService.lamnar, sate)
	pcall(GameplayService.lamnar, sate)
end

--[[ ══ SVEP ÖVER VÄRLDEN ═════════════════════════════════════════════ ]]

local ORPHANNAMN = {
	LeadTargetAttachment = true,
	LeadRootAttachment = true,
	UBRFLedDrag = true,
	UBRFLedVrid = true,
	HorseMount = true,
	UBRFLedrep = true,
}

local function orphanSvep(): (number, string)
	local n, var = 0, {}
	for _, d in ipairs(workspace:GetDescendants()) do
		if ORPHANNAMN[d.Name] then
			n += 1
			if #var < 6 then table.insert(var, d:GetFullName()) end
		end
	end
	return n, table.concat(var, ", ")
end

local function raknaBurna(k: Model, typ: string): number
	local n = 0
	for _, d in ipairs(k:GetDescendants()) do
		if d:IsA("BasePart") and d:GetAttribute("UBRFBuren") == typ then n += 1 end
	end
	return n
end

local function raknaPaHasten(m: Model, typ: string): number
	local n = 0
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") and d:GetAttribute("UBRFTack") == typ then n += 1 end
	end
	return n
end

local function svetsFor(del: BasePart?): WeldConstraint?
	if not del then return nil end
	for _, d in ipairs(del:GetChildren()) do
		if d:IsA("WeldConstraint") then return d :: WeldConstraint end
	end
	return nil
end

--[[ ══════════════════════════════════════════════════════════════════
	1. BUILD-IDENTITET — mäter vi rätt bygge?
	══════════════════════════════════════════════════════════════════ ]]
local kallhash = "?"
skyddat("identitet", function()
	avsnitt("identitet")
	local b = ReplicatedStorage:FindFirstChild("UBRFBuild")
	kolla("ReplicatedStorage.UBRFBuild finns", b ~= nil)
	if not b then return end
	local id = require(b)
	kallhash = tostring(id.kallhash)
	kolla("identiteten bär en källhash", type(id.kallhash) == "string"
		and #tostring(id.kallhash) == 64, kallhash)
	local vantad = _G.UBRF_VANTAD_KALLHASH
	--[[ BYGG-IDENTITETEN ÄR GRINDENS FÖRSTA FRÅGA. Evidens ur fel SHA är
		precis det problem Studio/Rojo-spåret redan fångat en gång. Kan
		drivaren inte säga vilken head hon väntade sig är det RÖTT — inte
		ett hopp över. ]]
	kolla("drivaren sa vilken källhash hon väntade sig",
		type(vantad) == "string" and #tostring(vantad) == 64,
		tostring(vantad))
	kolla("den körda placen är byggd ur PR-head",
		type(vantad) == "string" and vantad == id.kallhash,
		("kord=%s vantad=%s"):format(kallhash, tostring(vantad)))
	kolla("identiteten kommer ur den mappade filen, inte en handplacerad",
		id.lage == "rojo", tostring(id.lage))
end)

--[[ ══════════════════════════════════════════════════════════════════
	2. BOOT — startade servern över huvud taget?
	══════════════════════════════════════════════════════════════════ ]]
skyddat("boot", function()
	avsnitt("boot")
	kolla("anläggningen och tjänsterna kom upp inom taket", varldenStar)
	--[[ `Start.kor()` lämnar tillbaka CRITICAL_STARTUP_GATE:s eget
		utfall, och sätter attributet ENBART när inget kritiskt fel
		inträffade och preflighten gav PASS.

		FÖRRA VARIANTEN LÄSTE `Players.CharacterAutoLoads == true` och
		kallade det ett PASS. Den egenskapen är true som MOTORNS
		STANDARDVÄRDE — så när starten aldrig kördes rapporterade
		kontrollen grönt för en server som inte bootat. Ett attribut som
		inte finns på en orörd DataModel kan inte passera så. ]]
	kolla("CRITICAL_STARTUP_GATE gav PASS (Start.kor)", startOk == true,
		tostring(startOk))
	kolla("bootens attribut är satt, och det finns inte som standard",
		ReplicatedStorage:GetAttribute(Start.FARDIG_ATTRIBUT) == true,
		tostring(ReplicatedStorage:GetAttribute(Start.FARDIG_ATTRIBUT)))
	kolla("GameplayService.start() nådde sin sista rad (G01Enabled)",
		ReplicatedStorage:GetAttribute("G01Enabled") == true)
	kolla("anläggningen är byggd i Workspace",
		workspace:FindFirstChild("Anläggning") ~= nil)
	kolla("ledningens målzon är satt ur den delade geometrin",
		LedService.malzon() ~= nil)

	local mapp = ReplicatedStorage:FindFirstChild("HorseRemotes")
	kolla("fjärrobjektens mapp finns", mapp ~= nil)
	if mapp then
		local saknas = {}
		for namn, klass in pairs(Networking.definitioner()) do
			local r = mapp:FindFirstChild(namn)
			if not r or r.ClassName ~= klass then
				table.insert(saknas, namn)
			end
		end
		table.sort(saknas)
		kolla("varje fjärrobjekt i kontraktet finns med rätt klass",
			#saknas == 0, table.concat(saknas, ", "))
	end

	local taggade = CollectionService:GetTagged("Horse")
	kolla("varje kanonisk häst är byggd och taggad",
		#taggade == #Spel.ordning,
		("%d av %d"):format(#taggade, #Spel.ordning))
	kolla("utrustning är upphängd på varje boxfront",
		TackForradService.antal() == #Spel.ordning,
		("%d av %d"):format(TackForradService.antal(), #Spel.ordning))
end)

--[[ ══════════════════════════════════════════════════════════════════
	3. VÄRLDSINTEGRITET — boxfronten, per häst
	══════════════════════════════════════════════════════════════════

	Facit är `docs/KONTROLLMATRIS.md`:

	    Ta sadeln (boxfronten)   G   ButtonL1
	    Ta tränset (boxfronten)  T   ButtonB

	Texten spelaren SER kommer ur språknyckeln, inte ur `ActionText` —
	`ActionText` är den oöversatta reserven. Därför mäts båda: att
	nyckeln sitter på prompten, och att katalogens svenska text är den
	matrisen skriver.
	══════════════════════════════════════════════════════════════════ ]]
local PROMPTFACIT = {
	{
		typ = "sadel",
		namn = "SadelPrompt",
		nyckel = "tack.ta_sadeln",
		sv = "Ta sadeln",
		tangent = Enum.KeyCode.G,
		gamepad = Enum.KeyCode.ButtonL1,
	},
	{
		typ = "trans",
		namn = "TransPrompt",
		nyckel = "tack.ta_transet",
		sv = "Ta tränset",
		tangent = Enum.KeyCode.T,
		gamepad = Enum.KeyCode.ButtonB,
	},
}
local RACKVIDD_PROMPT = 8

skyddat("varldsintegritet", function()
	avsnitt("varldsintegritet")
	local utanPlats, felPrompter, felAntal = {}, {}, {}
	for _, id in ipairs(Spel.ordning) do
		local modell = TackForradService.forHast(id)
		if not modell then
			table.insert(utanPlats, id .. ":ingen upphangning")
		else
			for _, facit in ipairs(PROMPTFACIT) do
				if not TackForradService.harPlats(id, facit.typ) then
					table.insert(utanPlats, ("%s:%s saknar grupp"):format(id, facit.typ))
				end
			end
			--[[ Grupperna ska heta det kortet säger, inte bara finnas. ]]
			for _, n in ipairs({ "Sadelplats", "Transplats" }) do
				if not modell:FindFirstChild(n) then
					table.insert(utanPlats, ("%s: %s saknas"):format(id, n))
				end
			end
			local prompter = {}
			for _, d in ipairs(modell:GetDescendants()) do
				if d:IsA("ProximityPrompt") then table.insert(prompter, d) end
			end
			if #prompter ~= 2 then
				table.insert(felAntal, ("%s:%d"):format(id, #prompter))
			end
			for _, facit in ipairs(PROMPTFACIT) do
				local p = nil
				for _, q in ipairs(prompter) do
					if q.Name == facit.namn then p = q end
				end
				if not p then
					table.insert(felPrompter, ("%s:%s saknas"):format(id, facit.namn))
				else
					local avvik = {}
					if p.KeyboardKeyCode ~= facit.tangent then
						table.insert(avvik, "tangent=" .. p.KeyboardKeyCode.Name)
					end
					if p.GamepadKeyCode ~= facit.gamepad then
						table.insert(avvik, "gamepad=" .. p.GamepadKeyCode.Name)
					end
					if p.ClickablePrompt ~= true then
						table.insert(avvik, "ClickablePrompt=false")
					end
					if p.Enabled ~= true then
						table.insert(avvik, "Enabled=false")
					end
					if p.RequiresLineOfSight ~= false then
						table.insert(avvik, "RequiresLineOfSight=true")
					end
					if p.MaxActivationDistance ~= RACKVIDD_PROMPT then
						table.insert(avvik,
							"MaxActivationDistance=" .. tostring(p.MaxActivationDistance))
					end
					if p:GetAttribute("SprakNyckel") ~= facit.nyckel then
						table.insert(avvik,
							"SprakNyckel=" .. tostring(p:GetAttribute("SprakNyckel")))
					end
					local sv = Sprak.iSprak("sv", facit.nyckel)
					if sv ~= facit.sv then
						table.insert(avvik, ("sv=%s"):format(tostring(sv)))
					end
					if #avvik > 0 then
						table.insert(felPrompter, ("%s/%s: %s")
							:format(id, facit.namn, table.concat(avvik, " ")))
					end
				end
			end
		end
	end
	kolla("Sadelplats och Transplats finns på varje hästs boxfront",
		#utanPlats == 0, table.concat(utanPlats, " | "))
	kolla("exakt två prompter på varje boxfront",
		#felAntal == 0, table.concat(felAntal, " "))
	kolla("prompternas egenskaper stämmer mot KONTROLLMATRIS",
		#felPrompter == 0, table.concat(felPrompter, " | "))
end)

--[[ ══════════════════════════════════════════════════════════════════
	4. SÄTET BINDS — stallet ger aktören en häst
	══════════════════════════════════════════════════════════════════ ]]
local sate, karaktar, rot = nyttSate("CIRyttare", Vector3.new(0, 5, 0))
local hastId: string? = nil
local hasten: Model? = nil

skyddat("bindning", function()
	avsnitt("bindning")
	StallService.tilldela(sate)
	hastId = StallService.hastIdFor(sate)
	kolla("stallet tilldelade sätet en häst", type(hastId) == "string",
		tostring(hastId))
	if not hastId then return end
	hasten = hastMed(hastId)
	kolla("hästens rigg finns i världen", hasten ~= nil, tostring(hastId))
	if not hasten then return end
	--[[ Sätet måste stå VID hästen innan bindningen: `narvaro` prövar
		avståndet, och ett prov som står i origo får `spel.for_langt` på
		allt och blir grönt av fel skäl. ]]
	kolla("sätet går att ställa vid hästen", stallVid(sate, hasten, 1))
	local bunden = GameplayService.bind(sate)
	kolla("GameplayService band sätet till rätt modell",
		bunden == hasten, tostring(bunden and bunden.Name))
	kolla("förberedelsens state finns",
		GameplayService.stateFor(sate) ~= nil)
end)

--[[ ══════════════════════════════════════════════════════════════════
	5. TACK-KEDJAN — WORLD -> HELD -> EQUIPPED, i riktig motor
	══════════════════════════════════════════════════════════════════

	Bänken kan säga att ett attribut är satt. Den kan inte säga att en
	`WeldConstraint` verkligen finns, att dess `Part0`/`Part1` pekar rätt,
	eller att delen hamnade på hästens rygg och inte i origo.
	══════════════════════════════════════════════════════════════════ ]]
skyddat("tackkedjan", function()
	avsnitt("tackkedjan")
	if not (hastId and hasten) then
		kolla("tack-kedjan kunde mätas", false, "ingen bunden häst")
		return
	end
	local id = hastId :: string
	local modell = hasten :: Model
	local front = TackForradService.forHast(id)

	for _, typ in ipairs({ "sadel", "trans" }) do
		--[[ ── WORLD ── ]]
		kolla(typ .. ": hänger på fronten innan hämtningen",
			TackForradService.paFronten(id, typ) == true)

		--[[ ── WORLD -> HELD ── ]]
		kolla(typ .. ": sätet står vid boxfronten", stallVid(sate, front, 1))
		local ok, skal = GameplayService.valjEn(sate, id, typ)
		kolla(typ .. ": hämtningen från boxfronten går igenom", ok == true,
			tostring(skal))

		local buren = TackRigg.hittaBuren(karaktar, typ)
		kolla(typ .. ": den burna delen finns FYSISKT hos bäraren",
			buren ~= nil)
		local bsvets = svetsFor(buren)
		kolla(typ .. ": den burna delen är svetsad i kroppen med WeldConstraint",
			bsvets ~= nil and bsvets.Part0 ~= nil and bsvets.Part1 ~= nil,
			if bsvets then ("%s <-> %s"):format(tostring(bsvets.Part0),
				tostring(bsvets.Part1)) else "ingen svets")
		kolla(typ .. ": exakt EN buren del hos bäraren — ingen dubblett",
			raknaBurna(karaktar, typ) == 1, raknaBurna(karaktar, typ))
		kolla(typ .. ": fronten är släckt — ingenting kvar att ta",
			TackForradService.paFronten(id, typ) == false)
		kolla(typ .. ": ägarposten pekar på bäraren",
			GameplayService.barasAv(typ, id) == sate)

		--[[ ── HELD -> EQUIPPED ── ]]
		kolla(typ .. ": sätet står vid hästen", stallVid(sate, modell, 1))
		local ok2, skal2
		if typ == "sadel" then
			ok2, skal2 = GameplayService.sadla(sate, modell)
		else
			ok2, skal2 = GameplayService.transa(sate, modell)
		end
		kolla(typ .. ": påsättningen på hästen går igenom", ok2 == true,
			tostring(skal2))

		local pa = TackRigg.hittaDel(modell, typ)
		kolla(typ .. ": delen sitter FYSISKT på hästen", pa ~= nil)
		local psvets = svetsFor(pa)
		kolla(typ .. ": delen är svetsad i hästriggen med WeldConstraint",
			psvets ~= nil and psvets.Part0 ~= nil and psvets.Part1 ~= nil,
			if psvets then ("%s <-> %s"):format(tostring(psvets.Part0),
				tostring(psvets.Part1)) else "ingen svets")
		--[[ RIKTIG CFrame-MATEMATIK. En del som byggs i origo i stället för
			i hästens lokala ram är exakt den klass av fel bänken inte kan
			se: attributet är satt, svetsen finns, och delen ligger trettio
			meter bort. ]]
		local pivot = modell.PrimaryPart
		if pa and pivot then
			local avst = (pa.Position - pivot.Position).Magnitude / M
			kolla(typ .. ": delen sitter PÅ hästen, inte i origo",
				avst < 2.0, ("%.2f m fran pivot"):format(avst))
		else
			kolla(typ .. ": delen sitter PÅ hästen, inte i origo", false,
				"ingen del eller ingen pivot")
		end
		kolla(typ .. ": ingen buren dubblett kvar hos bäraren",
			raknaBurna(karaktar, typ) == 0, raknaBurna(karaktar, typ))
		kolla(typ .. ": ingen dubblett på hästen",
			raknaPaHasten(modell, typ) == 1, raknaPaHasten(modell, typ))
		kolla(typ .. ": fronten tänds INTE igen — delen ligger på hästen",
			TackForradService.paFronten(id, typ) == false)
		kolla(typ .. ": ägarposten är släppt utan att fronten tändes",
			GameplayService.barasAv(typ, id) == nil)
	end

	kolla("hästen läses som sadlad ur världen", TackService.sadlad(modell) == true)
	kolla("hästen läses som tränsad ur världen", TackService.transad(modell) == true)

	--[[ ── ANDRA RIKTNINGEN, I KANONORDNING ────────────────────────────

		Eftervarden tar SADELN forst och transet sedan: transet ar det som
		haller henne medan sadeln lyfts av, och grimman kommer pa innan
		det tas av (`src/spel/skotsel.js`, vaktad av ordningsgrinden i
		`tools/exportera-spel.js`).

		Provet skrev forst av ordningen baklanges och fick `false` ur
		motorn. Regeln matas darfor i BADA riktningarna: det felaktiga
		greppet ska ge sitt eget nej, inte bara misslyckas. ]]
	local avFel, skalFel = TackService.taAv(sate, modell, "trans")
	kolla("tränset går INTE att ta av medan sadeln sitter kvar",
		avFel == false and skalFel == "tack.sadeln_av_forst",
		("%s %s"):format(tostring(avFel), tostring(skalFel)))
	kolla("och tränset sitter följaktligen kvar",
		raknaPaHasten(modell, "trans") == 1, raknaPaHasten(modell, "trans"))

	local av1 = TackService.taAv(sate, modell, "sadel")
	kolla("sadeln går att ta av först", av1 == true)
	kolla("och är FYSISKT borta ur hästmodellen",
		raknaPaHasten(modell, "sadel") == 0, raknaPaHasten(modell, "sadel"))
	local av2 = TackService.taAv(sate, modell, "trans")
	kolla("tränset går att ta av därefter", av2 == true)
	kolla("och är FYSISKT borta ur hästmodellen",
		raknaPaHasten(modell, "trans") == 0, raknaPaHasten(modell, "trans"))
	kolla("och tyglarna följde med tränset av",
		raknaPaHasten(modell, "tygel") == 0, raknaPaHasten(modell, "tygel"))
	local n, var = orphanSvep()
	kolla("inga orphans efter avtagningen", n == 0, var)
end)

--[[ ══════════════════════════════════════════════════════════════════
	6. «RIDA NU» GÖR HÄSTEN UPPSITTNINGSKLAR   [AUDIT § 7 punkt 1]
	══════════════════════════════════════════════════════════════════

	Aldrig körd i någon bänk före `b4d78f2`: `typeof` var ostubbad, så
	`LedService.placeraVidMal` föll på sin egen vakt och varje `ridaNu`
	svarade `spel.ingen_hast` innan slutfasen nåddes. Här körs hela
	kedjan i motorn, inklusive den verkliga förflyttningen.
	══════════════════════════════════════════════════════════════════ ]]
local sateR: any, karaktarR: Model? = nil, nil
skyddat("ridanu", function()
	avsnitt("ridanu")
	local s, k = nyttSate("CIRidaNu", Vector3.new(0, 5, 0))
	sateR, karaktarR = s, k
	StallService.tilldela(sateR)
	local id = StallService.hastIdFor(sateR)
	kolla("stallet gav en häst åt Rida-nu-sätet", type(id) == "string", tostring(id))
	if not id then return end
	local m = hastMed(id)
	kolla("hennes rigg finns", m ~= nil, tostring(id))
	if not m then return end
	kolla("sätet står vid henne", stallVid(sateR, m, 1))
	GameplayService.bind(sateR)

	local ok, varfor, arg = GameplayService.ridaNu(sateR)
	kolla("«Rida nu» går igenom i motorn", ok == true,
		("%s %s"):format(tostring(varfor), tostring(arg)))

	kolla("ledningsmomentet «lämnat boxen» är kvitterat",
		LedService.harLamnatBox(sateR) == true)
	kolla("ledningsmomentet «nått målet» är kvitterat",
		LedService.harNattMal(sateR) == true)

	--[[ Hon står FYSISKT i målzonen, inte bara bokförd där. ]]
	local zon = LedService.malzon()
	local pivot = m.PrimaryPart
	kolla("hästen står fysiskt i ridhusets målzon",
		zon ~= nil and pivot ~= nil
			and LedService.iRekt(pivot.Position, zon) == true,
		if pivot then tostring(pivot.Position) else "ingen pivot")

	local st = GameplayService.stateFor(sateR)
	local klar, skal = Preparation.provaUppsittning(st, id)
	kolla("Preparation.provaUppsittning säger ja", klar == true, tostring(skal))

	local ok2, varfor2 = GameplayService.ridaNu(sateR)
	kolla("ett andra «Rida nu» svarar spel.redan_redo — aldrig ett tackfel",
		ok2 == false and varfor2 == "spel.redan_redo",
		("%s %s"):format(tostring(ok2), tostring(varfor2)))
end)

--[[ ══════════════════════════════════════════════════════════════════
	7. MOUNTREQUEST-REMOTENS EGEN VALIDERING   [AUDIT § 7 punkt 3]
	══════════════════════════════════════════════════════════════════

	`OnServerInvoke` går inte att läsa tillbaka ur motorn, så handlaren
	har ett namn: `HorseService.mountRequest`. `start()` kopplar exakt
	den funktionen till remoten, och provet anropar samma funktion — inte
	en avskrift av dess villkor, och inte `tryMount` direkt.
	══════════════════════════════════════════════════════════════════ ]]
skyddat("mountrequest", function()
	avsnitt("mountrequest")
	kolla("handlaren är en funktion på tjänsten",
		type(HorseService.mountRequest) == "function")
	if type(HorseService.mountRequest) ~= "function" then return end

	local ok1, skal1 = HorseService.mountRequest(sateR, "inte en modell" :: any)
	kolla("en sträng nekas med hast.ogiltig",
		ok1 == false and skal1 == "hast.ogiltig",
		("%s %s"):format(tostring(ok1), tostring(skal1)))

	local ok2, skal2 = HorseService.mountRequest(sateR, nil :: any)
	kolla("nil nekas med hast.ogiltig",
		ok2 == false and skal2 == "hast.ogiltig",
		("%s %s"):format(tostring(ok2), tostring(skal2)))

	local losDel = Instance.new("Part")
	losDel.Name = "IngenHast"
	losDel.Anchored = true
	losDel.Parent = workspace
	table.insert(skrap, losDel)
	local ok3, skal3 = HorseService.mountRequest(sateR, losDel :: any)
	kolla("en Part som inte är en Model nekas med hast.ogiltig",
		ok3 == false and skal3 == "hast.ogiltig",
		("%s %s"):format(tostring(ok3), tostring(skal3)))

	--[[ EN OFÖRBEREDD HÄST ska nekas av uppsittningsgrinden, inte av
		valideringen. Att de två nejen är OLIKA är hela poängen: kommer
		`hast.ogiltig` ut på en riktig modell har valideringen svalt
		något den inte skulle. ]]
	local min = GameplayService.modellFor(sateR)
	local oforberedd = nil
	for _, q in ipairs(CollectionService:GetTagged("Horse")) do
		if q ~= min and LedService.ledsAv(q) == nil
			and HorseService.sessionFor(q) ~= nil then oforberedd = q break end
	end
	if oforberedd then
		local ok4, skal4 = HorseService.mountRequest(sateR, oforberedd)
		kolla("en RIKTIG modell får ett annat nej än hast.ogiltig",
			ok4 == false and skal4 ~= "hast.ogiltig" and skal4 ~= nil,
			tostring(skal4))
	else
		kolla("en RIKTIG modell får ett annat nej än hast.ogiltig", false,
			"hittade ingen annan registrerad hast att prova mot")
	end

	--[[ JA-VÄGEN genom samma handlare, på den häst stallet gjort i
		ordning i avsnitt 6. ]]
	if min then
		kolla("sätet står vid sin häst", stallVid(sateR, min, 1))
		local ok5, skal5 = HorseService.mountRequest(sateR, min)
		kolla("den förberedda hästen släpper upp ryttaren genom remotens handlare",
			ok5 == true, tostring(skal5))
		kolla("hästen bär ryttarens userId",
			min:GetAttribute("RiderUserId") == sateR.UserId,
			tostring(min:GetAttribute("RiderUserId")))
		kolla("tjänsten känner sessionen",
			HorseService.horseOf(sateR) == min)
	else
		kolla("den förberedda hästen släpper upp ryttaren genom remotens handlare",
			false, "ingen bunden modell")
	end
end)

--[[ ══════════════════════════════════════════════════════════════════
	8. BOXFRONTEN TÄNDS IGEN VID NEDKOPPLING   [AUDIT § 7 punkt 2]
	══════════════════════════════════════════════════════════════════

	`lamnar -> slappBuret -> satSynlig`, i integrationskontext. Mätt i
	`tack-fas1.spec` på enhetsnivå, aldrig med en aktiv förberedelse och
	en riktig nedkoppling.
	══════════════════════════════════════════════════════════════════ ]]
skyddat("boxfront", function()
	avsnitt("boxfront")
	local sateB, karaktarB = nyttSate("CIBarare", Vector3.new(0, 5, 0))
	StallService.tilldela(sateB)
	local id = StallService.hastIdFor(sateB)
	kolla("bäraren fick en häst", type(id) == "string", tostring(id))
	if not id then return end
	local m = hastMed(id)
	if not m then kolla("bärarens häst finns", false, tostring(id)) return end
	kolla("bäraren står vid henne", stallVid(sateB, m, 1))
	GameplayService.bind(sateB)
	kolla("bäraren har en aktiv förberedelse",
		GameplayService.stateFor(sateB) ~= nil)

	local front = TackForradService.forHast(id)
	kolla("bäraren står vid boxfronten", stallVid(sateB, front, 1))

	local ok, skal = GameplayService.valjEn(sateB, id, "sadel")
	kolla("bäraren hämtar sadeln mitt i förberedelsen", ok == true, tostring(skal))
	kolla("fronten är släckt medan hon bär den",
		TackForradService.paFronten(id, "sadel") == false)
	kolla("och ägarposten är hennes",
		GameplayService.barasAv("sadel", id) == sateB)

	--[[ Prompten ska vara AVSTÄNGD medan sadeln bärs — annars kan en
		andra spelare ta en sadel som inte hänger där. ]]
	local promptAv = true
	if front then
		for _, d in ipairs(front:GetDescendants()) do
			if d:IsA("ProximityPrompt") and d.Name == "SadelPrompt" and d.Enabled then
				promptAv = false
			end
		end
	end
	kolla("sadelprompten är avstängd medan sadeln bärs", promptAv)

	--[[ ── NEDKOPPLINGEN, genom produktionens egen handlare ── ]]
	GameplayService.lamnar(sateB)

	kolla("fronten tänds igen när bäraren kopplar ner",
		TackForradService.paFronten(id, "sadel") == true)
	kolla("ägarposten är släppt", GameplayService.barasAv("sadel", id) == nil)
	kolla("den burna delen är FYSISKT borta ur hennes kropp",
		raknaBurna(karaktarB, "sadel") == 0, raknaBurna(karaktarB, "sadel"))
	kolla("förberedelsens state är glömt",
		GameplayService.stateFor(sateB) == nil)

	local tandaDelar, tandPrompt = true, false
	if front then
		for _, d in ipairs(front:GetDescendants()) do
			local f = d.Parent
			if d:IsA("BasePart") and f and f:IsA("Model")
				and f:GetAttribute("UBRFForrad") == "sadel" then
				if d.Transparency ~= 0 or d.CanQuery ~= true then tandaDelar = false end
			end
			if d:IsA("ProximityPrompt") and d.Name == "SadelPrompt" and d.Enabled then
				tandPrompt = true
			end
		end
	end
	kolla("sadelns delar är synliga igen och går att peka på", tandaDelar)
	kolla("sadelprompten går att trycka på igen", tandPrompt)

	kopplaNer(sateB)
end)

--[[ ══════════════════════════════════════════════════════════════════
	9. LEDNING SOM FYSIK, INTE SOM FLAGGA
	══════════════════════════════════════════════════════════════════

	Ledningen bygger `LeadTargetAttachment` på ryttarens root och drar
	hästen dit med `AlignPosition` + `AlignOrientation`. Provet flyttar
	målet över tid och låter servern stega fysiken själv, och mäter fyra
	saker som bara går att se i en motor:

	    · hon FÖLJER inom tolerans,
	    · ingen enskild bildruta flyttar henne mer än MAX_FRAMSTEG,
	    · hon OSCILLERAR inte kring stoppunkten,
	    · allt är rivet efter släpp.
	══════════════════════════════════════════════════════════════════ ]]
local MAX_FRAMSTEG_M = 0.5   --[[ m per bildruta. Skritt är ~1,4 m/s, så
                                  taket är ~30 m/s vid 60 Hz — det fångar
                                  en teleport, inte en normal gång. ]]
local FOLJ_TOLERANS_M = 6.0  --[[ m: kopplet släpper vid 9,0 m (KOPPEL). ]]
local OSC_VANDNINGAR = 6     --[[ tecken byten längs färdriktningen efter
                                  att målet stannat. Fler än så är studs. ]]

skyddat("ledning", function()
	avsnitt("ledning")
	local sateL, karaktarL, rotL = nyttSate("CILedare", Vector3.new(0, 5, 0))
	StallService.tilldela(sateL)
	local id = StallService.hastIdFor(sateL)
	local m = hastMed(id)
	kolla("ledarens häst finns", m ~= nil, tostring(id))
	if not m then return end
	local pivot = m.PrimaryPart
	kolla("hästen har en pivot att dra i", pivot ~= nil)
	if not pivot then return end

	kolla("ledaren står vid henne", stallVid(sateL, m, 1))
	GameplayService.bind(sateL)

	local ok, skal = LedService.borja(sateL, m, m)
	kolla("ledningen börjar", ok == true, tostring(skal))
	if ok ~= true then return end

	local rigg = LedService.riggFor(sateL)
	kolla("följriggen byggdes", rigg ~= nil)
	if not rigg then return end
	kolla("LeadTargetAttachment sitter på ryttarens root",
		rigg.mal ~= nil and rigg.mal:IsA("Attachment") and rigg.mal.Parent == rotL,
		tostring(rigg.mal and rigg.mal.Parent))
	kolla("LeadRootAttachment sitter på hästens pivot",
		rigg.hastfast ~= nil and rigg.hastfast.Parent == pivot)
	kolla("draget är en AlignPosition som INTE är stel",
		rigg.drag ~= nil and rigg.drag:IsA("AlignPosition")
			and rigg.drag.RigidityEnabled == false)
	kolla("vridningen är en AlignOrientation",
		rigg.vrid ~= nil and rigg.vrid:IsA("AlignOrientation"))

	--[[ ── MOTORN SKA FAKTISKT STEGA ─────────────────────────────────
		Ett prov som mäter fysik i en motor som står stilla mäter
		ingenting. Bildrutorna räknas, och för få bildrutor är RÖTT. ]]
	local bildrutor = 0
	local maxSteg = 0
	local sist = pivot.Position
	local koppling = RunService.Heartbeat:Connect(function()
		bildrutor += 1
		local nu = pivot.Position
		local d = (nu - sist).Magnitude / M
		if d > maxSteg then maxSteg = d end
		sist = nu
	end)

	--[[ Målet flyttas över TID, inte i ett hopp: ryttaren GÅR. Hon är
		ankrad, så positionen är vår att sätta.

		TAKTEN LÄSES UR PRODUKTEN, inte vald av provet. Första utkastet
		flyttade henne 0,3 studs per bildruta — 18 studs/s, fyra gånger
		skritt — och sakerhetskopplet slappte pa `led.tappade_bort` efter
		tva sekunder. Motorn hade ratt och provet fel: en ryttare som
		springer ifran hasten SKA tappa henne. `hum.WalkSpeed` ar den fart
		`LedService` sjalv satte pa hasten nar ledningen borjade, och
		ryttaren gar nagot langsammare an sa. ]]
	local hastHum = m:FindFirstChildOfClass("Humanoid")
	local fart = if hastHum and hastHum.WalkSpeed > 0 then hastHum.WalkSpeed else 6
	--[[ Farten är en EGENSKAPSAVLÄSNING, inte observerad rörelse. Den
		säger att `LedService` skrev ett värde, inte att hästen gick i
		den takten — och utan fysikintegration kan det senare inte
		mätas här. Se KTX-blocket vid `ejMatbar`. ]]
	ejMatbar("LedService satte en gångfart på hästen",
		"egenskapsavlasning, ingen observerad rorelse",
		("%.2f studs/s"):format(fart))
	local start = pivot.Position
	local riktning = Vector3.new(1, 0, 0)
	for _ = 1, 150 do
		local dt = RunService.Heartbeat:Wait()
		rotL.CFrame = CFrame.new(rotL.Position + riktning * (fart * 0.7 * dt))
	end
	local efterGang = pivot.Position
	local ryttarLage = rotL.Position

	--[[ Målet står still. Nu mäts oscillationen. ]]
	local prover = {}
	for _ = 1, 90 do
		RunService.Heartbeat:Wait()
		table.insert(prover, pivot.Position)
	end
	koppling:Disconnect()

	kolla("motorn stegade bildrutor", bildrutor >= 200, bildrutor)

	--[[ DE FYRA RÖRELSEMÄTNINGARNA. Villkoren står kvar ordagrant och
		värdena räknas fortfarande ut och redovisas — det är bara
		DOMEN som hålls tillbaka, eftersom fysiken inte integrerar här.
		Tröskelvärdena är orörda och gäller oförändrat i Studio. ]]
	local flyttad = (efterGang - start).Magnitude / M
	ejMatbar("hästen FÖLJDE med när målet flyttades",
		"AlignPosition integrerar inte utan fysik",
		("%.2f m (krav > 1.0)"):format(flyttad))

	local avstTillRyttare = (efterGang - ryttarLage).Magnitude / M
	ejMatbar("hon höll sig inom tolerans från ryttaren",
		"tomt uppfyllt nar hon star still",
		("%.2f m (tak %.1f)"):format(avstTillRyttare, FOLJ_TOLERANS_M))

	ejMatbar("ingen enskild bildruta teleporterade henne",
		"tomt uppfyllt nar hon star still",
		("storsta steg %.3f m (tak %.2f)"):format(maxSteg, MAX_FRAMSTEG_M))

	--[[ OSCILLATION: hur många gånger byter rörelsen tecken längs
		färdriktningen efter att målet stannat? En häst som glider in
		och stannar byter noll eller en gång. En som studsar byter
		många. Rörelser under en centimeter är brus och räknas inte. ]]
	local vandningar, forra = 0, nil
	for i = 2, #prover do
		local d = (prover[i] - prover[i - 1]):Dot(riktning)
		if math.abs(d) > 0.03 then
			local tecken = if d > 0 then 1 else -1
			if forra ~= nil and tecken ~= forra then vandningar += 1 end
			forra = tecken
		end
	end
	ejMatbar("hon oscillerar inte kring stoppunkten",
		"tomt uppfyllt nar hon star still",
		("%d vandningar (tak %d)"):format(vandningar, OSC_VANDNINGAR))

	--[[ ── SLÄPPET RIVER ALLT ── ]]
	local slappt = LedService.slapp(sateL)
	kolla("släppet går igenom", slappt == true)
	kolla("LeadTargetAttachment är borta",
		rigg.mal == nil or rigg.mal.Parent == nil)
	kolla("LeadRootAttachment är borta",
		rigg.hastfast == nil or rigg.hastfast.Parent == nil)
	kolla("AlignPosition är borta", rigg.drag == nil or rigg.drag.Parent == nil)
	kolla("AlignOrientation är borta", rigg.vrid == nil or rigg.vrid.Parent == nil)
	kolla("ledningsregistret är tomt för sätet", LedService.aktiv(sateL) == nil)
	kolla("ingen annan står som ledare för hästen", LedService.ledsAv(m) == nil)

	kopplaNer(sateL)
end)

--[[ ══════════════════════════════════════════════════════════════════
	9b. FLERLEDNING — två ledda hästar samtidigt
	══════════════════════════════════════════════════════════════════

	Enhästsledningen ovan säger ingenting om vad som händer när två
	personer leder var sin häst i samma värld. Det som kan gå fel är
	inte rörelsen — det är ÄGARSKAPET: att A:s rigg hamnar på B:s häst,
	att registret svarar fel på vem som leder vem, att ett släpp river
	den andres fastpunkter, eller att en häst som redan leds går att
	ta över.

	ALLT DET ÄR STRUKTUR OCH REGISTER, och därmed mätbart här. Fysiken
	behövs inte för att avgöra om två riggar är samma instans eller om
	`ledsAv` pekar på rätt spelare. Rörelsen mäts inte här och påstås
	inte heller — den ligger i KTX-kategorin av samma skäl som i
	enhästsfallet.

	Två hästar räcker för varje påstående nedan: de fel som finns är
	förväxlingar mellan två parter, och en tredje häst hade upprepat
	samma par utan att lägga till en ny felmöjlighet.
	══════════════════════════════════════════════════════════════════ ]]
skyddat("flerledning", function()
	avsnitt("flerledning")

	local sateA, _, rotA = nyttSate("CILedareA", Vector3.new(0, 5, 20))
	local sateB, _, rotB = nyttSate("CILedareB", Vector3.new(0, 5, 40))
	StallService.tilldela(sateA)
	StallService.tilldela(sateB)
	local idA, idB = StallService.hastIdFor(sateA), StallService.hastIdFor(sateB)

	--[[ Stallet ska ge två OLIKA hästar. Ger det samma häst åt båda är
		det ett riktigt fel och resten av avsnittet vore meningslöst. ]]
	kolla("stallet gav två skilda hästar", idA ~= nil and idB ~= nil and idA ~= idB,
		("%s / %s"):format(tostring(idA), tostring(idB)))
	if idA == nil or idB == nil or idA == idB then return end

	local hA, hB = hastMed(idA), hastMed(idB)
	kolla("båda hästarna finns i världen", hA ~= nil and hB ~= nil,
		("%s / %s"):format(tostring(idA), tostring(idB)))
	if not hA or not hB then return end
	if not hA.PrimaryPart or not hB.PrimaryPart then
		kolla("båda hästarna har en pivot", false)
		return
	end

	kolla("ledarna står vid var sin häst",
		stallVid(sateA, hA, 1) and stallVid(sateB, hB, 1))
	GameplayService.bind(sateA)
	GameplayService.bind(sateB)

	local okA, skalA = LedService.borja(sateA, hA, hA)
	local okB, skalB = LedService.borja(sateB, hB, hB)
	kolla("A:s ledning börjar", okA == true, tostring(skalA))
	kolla("B:s ledning börjar medan A leder", okB == true, tostring(skalB))
	if okA ~= true or okB ~= true then return end

	--[[ ── INGEN STJÄL DEN ANDRES ─────────────────────────────────── ]]
	kolla("registret ger A sin egen häst", LedService.aktiv(sateA) == hA)
	kolla("registret ger B sin egen häst", LedService.aktiv(sateB) == hB)
	kolla("A:s häst leds av A, inte B", LedService.ledsAv(hA) == sateA)
	kolla("B:s häst leds av B, inte A", LedService.ledsAv(hB) == sateB)

	local rA, rB = LedService.riggFor(sateA), LedService.riggFor(sateB)
	kolla("båda riggarna byggdes", rA ~= nil and rB ~= nil)
	if not rA or not rB then return end

	--[[ Samma instans på två riggar vore den värsta varianten: allt
		ser rätt ut tills den ena släpper och river den andres. ]]
	kolla("riggarna delar ingen enda instans",
		rA.mal ~= rB.mal and rA.hastfast ~= rB.hastfast
			and rA.drag ~= rB.drag and rA.vrid ~= rB.vrid)
	kolla("A:s målfäste sitter på A:s ryttare", rA.mal.Parent == rotA)
	kolla("B:s målfäste sitter på B:s ryttare", rB.mal.Parent == rotB)
	kolla("A:s hästfäste sitter på A:s häst", rA.hastfast.Parent == hA.PrimaryPart)
	kolla("B:s hästfäste sitter på B:s häst", rB.hastfast.Parent == hB.PrimaryPart)

	--[[ ── TVÅ SKILDA REGLER, INTE EN ────────────────────────────────

		`borjaInre` nekar i ordning: `led.leder_redan` står FÖRE
		`led.upptagen`. En som redan leder får alltså sitt nej av att
		HON leder, inte av att hästen är tagen — och ett prov som bara
		lät B försöka hade mätt fel regel och trott sig ha täckt den
		andra.

		Båda mäts därför var för sig, och skälet läses ut. Avståndet
		ställs undan först: `led.for_langt` ligger också före båda, så
		utan det steget kunde ett nej komma av att sätet stod fel. ]]

	stallVid(sateB, hA, 1)
	local okB2, skalB2 = LedService.borja(sateB, hA, hA)
	kolla("den som redan leder får inte en häst till", okB2 ~= true,
		tostring(skalB2))
	kolla("och nekas för att hon leder, inte för avståndet",
		skalB2 == "led.leder_redan", tostring(skalB2))
	stallVid(sateB, hB, 1)

	--[[ C leder ingenting. Hon är därför den enda som kan nå
		`led.upptagen` — regeln att två inte kan leda samma häst. ]]
	local sateC = nyttSate("CILedareC", Vector3.new(0, 5, 60))
	stallVid(sateC, hA, 1)
	local okC, skalC = LedService.borja(sateC, hA, hA)
	kolla("en ledig spelare kan inte ta A:s häst", okC ~= true, tostring(skalC))
	kolla("och nekas för att hästen är upptagen", skalC == "led.upptagen",
		tostring(skalC))

	kolla("A leder fortfarande sin häst efter båda försöken",
		LedService.ledsAv(hA) == sateA and LedService.aktiv(sateA) == hA)
	kolla("B:s egen ledning överlevde försöken",
		LedService.ledsAv(hB) == sateB and LedService.aktiv(sateB) == hB)
	kolla("C fick ingen ledning av ett nekat försök",
		LedService.aktiv(sateC) == nil)

	--[[ ── A SLÄPPER. B SKA INTE MÄRKA NÅGOT ───────────────────────── ]]
	local slapptA = LedService.slapp(sateA)
	kolla("A:s släpp går igenom", slapptA == true)
	kolla("A:s register är tomt", LedService.aktiv(sateA) == nil)
	kolla("A:s häst står utan ledare", LedService.ledsAv(hA) == nil)
	kolla("A:s målfäste är borta", rA.mal == nil or rA.mal.Parent == nil)
	kolla("A:s hästfäste är borta", rA.hastfast == nil or rA.hastfast.Parent == nil)
	kolla("A:s AlignPosition är borta", rA.drag == nil or rA.drag.Parent == nil)
	kolla("A:s AlignOrientation är borta", rA.vrid == nil or rA.vrid.Parent == nil)

	kolla("B LEDER FORTFARANDE efter A:s släpp",
		LedService.aktiv(sateB) == hB and LedService.ledsAv(hB) == sateB)
	kolla("B:s målfäste rördes inte", rB.mal ~= nil and rB.mal.Parent == rotB)
	kolla("B:s hästfäste rördes inte",
		rB.hastfast ~= nil and rB.hastfast.Parent == hB.PrimaryPart)
	kolla("B:s AlignPosition rördes inte",
		rB.drag ~= nil and rB.drag.Parent ~= nil)
	kolla("B:s AlignOrientation rördes inte",
		rB.vrid ~= nil and rB.vrid.Parent ~= nil)

	--[[ ── A LEDER IGEN. Släppet får inte ha bränt hästen ─────────── ]]
	stallVid(sateA, hA, 1)
	local okIgen, skalIgen = LedService.borja(sateA, hA, hA)
	kolla("A kan leda igen efter släpp", okIgen == true, tostring(skalIgen))
	if okIgen == true then
		local rA2 = LedService.riggFor(sateA)
		kolla("den nya riggen är en NY rigg, inte den rivna",
			rA2 ~= nil and rA2.drag ~= nil and rA2.drag ~= rA.drag)
		kolla("B stördes inte av att A tog om",
			LedService.aktiv(sateB) == hB and LedService.ledsAv(hB) == sateB)
		LedService.slapp(sateA)
	end

	--[[ ── BÅDA SLÄPPTA: INGA FÖRÄLDRALÖSA CONSTRAINTS ──────────────
		Räknas över HELA världen, inte bara de två hästarna: en rigg som
		hamnat fel syns bara om man tittar utanför den man förväntar
		sig. ]]
	LedService.slapp(sateB)
	kolla("ingen leder längre", LedService.aktiv(sateA) == nil
		and LedService.aktiv(sateB) == nil)

	local kvar = {}
	for _, d in ipairs(workspace:GetDescendants()) do
		local n = d.Name
		if n == "LeadTargetAttachment" or n == "LeadRootAttachment"
			or ((d:IsA("AlignPosition") or d:IsA("AlignOrientation"))
				and d.Parent ~= nil and d.Parent:IsDescendantOf(workspace)
				and (n:match("^Lead") ~= nil)) then
			table.insert(kvar, ("%s (%s)"):format(d:GetFullName(), d.ClassName))
		end
	end
	kolla("inga föräldralösa ledningsobjekt kvar i världen",
		#kvar == 0, table.concat(kvar, " | "))

	--[[ Rörelsen. Samma skäl som i enhästsfallet — se KTX-blocket. ]]
	ejMatbar("två ledda hästar följer var sin ryttare",
		"AlignPosition integrerar inte utan fysik",
		"struktur och register mätta ovan; rorelsen kraver Studio")

	kopplaNer(sateA)
	kopplaNer(sateB)
	kopplaNer(sateC)
end)

--[[ ══════════════════════════════════════════════════════════════════
	10. STÄDNING — reset, nedkoppling, uppsittningsövergång
	══════════════════════════════════════════════════════════════════

	«Stale leaderUserId» i ordern finns inte under det namnet i koden.
	[REFERENCE GAP]: motsvarigheterna är `RiderUserId` på hästmodellen
	och `LedService`-registret (`aktiv`/`ledsAv`), och båda mäts här.
	══════════════════════════════════════════════════════════════════ ]]
skyddat("stadning", function()
	avsnitt("stadning")
	local minR = if sateR then GameplayService.modellFor(sateR) else nil

	--[[ UPPSITTNINGSÖVERGÅNGEN: sateR sitter upp sedan avsnitt 7. ]]
	if sateR and minR then
		kolla("ryttaren sitter upp innan städningen mäts",
			HorseService.horseOf(sateR) == minR)
	end

	for _, s in ipairs(saten) do kopplaNer(s) end

	if minR then
		kolla("RiderUserId är nollställt efter nedkopplingen",
			minR:GetAttribute("RiderUserId") == 0,
			tostring(minR:GetAttribute("RiderUserId")))
		kolla("sessionen har ingen ryttare kvar",
			HorseService.horseOf(sateR) == nil)
		kolla("ingen står som ledare för henne", LedService.ledsAv(minR) == nil)
	end

	local kvarState = {}
	for _, s in ipairs(saten) do
		if GameplayService.stateFor(s) ~= nil then table.insert(kvarState, s.Name) end
	end
	kolla("förberedelsens state är glömt för varje säte", #kvarState == 0,
		table.concat(kvarState, " "))

	--[[ Ingen häst i hela världen får bära en ryttare vi släppt. ]]
	local kvarRidna = {}
	for _, q in ipairs(CollectionService:GetTagged("Horse")) do
		local uid = q:GetAttribute("RiderUserId")
		if uid ~= nil and uid ~= 0 then
			table.insert(kvarRidna, ("%s=%s"):format(q.Name, tostring(uid)))
		end
	end
	kolla("ingen häst bär en stale RiderUserId", #kvarRidna == 0,
		table.concat(kvarRidna, " "))

	--[[ ── DET GLOBALA SVEPET ── ]]
	local n, var = orphanSvep()
	kolla("ingen orphan weld, attachment eller constraint i hela världen",
		n == 0, ("%d kvar: %s"):format(n, var))

	local burna = 0
	for _, s in ipairs(saten) do
		local k = s.Character
		if k and k.Parent then
			for _, d in ipairs(k:GetDescendants()) do
				if d:IsA("BasePart") and d:GetAttribute("UBRFBuren") ~= nil then
					burna += 1
				end
			end
		end
	end
	kolla("ingen buren utrustning kvar hos något säte", burna == 0, burna)

	--[[ Varje front ska hänga full igen: det är samma värld nästa spelare
		möter. Sadel och träns på avsnitt 5:s häst togs av PÅ HÄSTEN och
		hör inte tillbaka på kroken — de är eftervårdens sak, inte
		städningens. Därför jämförs listan mot en känd, namngiven mängd i
		stället för mot noll. ]]
	local slackta = {}
	for _, id in ipairs(Spel.ordning) do
		for _, typ in ipairs({ "sadel", "trans" }) do
			if TackForradService.harPlats(id, typ)
				and TackForradService.paFronten(id, typ) == false then
				table.insert(slackta, id .. "/" .. typ)
			end
		end
	end
	local vantade = {}
	if hastId and DEL == "alla" then
		table.insert(vantade, hastId .. "/sadel")
		table.insert(vantade, hastId .. "/trans")
	end
	table.sort(slackta)
	table.sort(vantade)
	kolla("inga OVÄNTAT släckta boxfronter kvar",
		table.concat(slackta, ",") == table.concat(vantade, ","),
		("slackta=[%s] vantade=[%s]"):format(
			table.concat(slackta, ","), table.concat(vantade, ",")))
end)

--[[ ══════════════════════════════════════════════════════════════════
	STÄDA EFTER OSS OCH SVARA
	══════════════════════════════════════════════════════════════════ ]]
for _, inst in ipairs(skrap) do
	pcall(function() inst:Destroy() end)
end

--[[ ══ KTX-KATEGORIN FÅR INTE SMITTA UTFALLET ═══════════════════════

	En kategori som varken är PASS eller FAIL är farlig av två skäl, och
	båda mäts här i stället för att lovas:

	  · om en KTX-rad räknades som mätning blåste den upp täckningen,
	  · om den räknades som fel gav den ett rött som inte finns.

	Kontrollen använder de VERKLIGA raderna från körningen, inte en
	attrapp: `rader` ska innehålla exakt mätningarna och ingenting annat,
	och varje KTX-rad ska ligga i sin egen lista med ett skäl. Går de
	isär är räkningen fel, och då ska det synas som ett riktigt fel. ]]
do
	aktuelltAvsnitt = "harness"
	local utanDom = 0
	for _, r in ipairs(rader) do
		if r.ok == nil then utanDom += 1 end
	end
	kolla("ingen KTX-rad har smugit sig in bland matningarna",
		utanDom == 0, ("%d rader utan dom i rader"):format(utanDom))
	kolla("KTX-raderna ligger i sin egen lista",
		#ejRader == ejMatbara,
		("%d rader, ejMatbara=%d"):format(#ejRader, ejMatbara))
	kolla("ingen KTX-rad saknar skal",
		(function()
			for _, r in ipairs(ejRader) do
				if r.skal == nil or r.skal == "" then return false end
			end
			return true
		end)(), ejMatbara)
end

local sekunder = os.clock() - T0
print(("[Smoke] %d matningar, %d FEL, %d ej matbara har, %.1f s")
	:format(antal, fel, ejMatbara, sekunder))
if antal == 0 then
	warn("[Smoke] RUNTIME_GRIND: FAIL - noll matningar gjordes")
	fel += 1
	antal += 1
	table.insert(rader, {
		avsnitt = "start", namn = "smoken matte nagot alls",
		ok = false, detalj = "noll matningar",
	})
elseif fel > 0 then
	warn(("[Smoke] RUNTIME_GRIND: FAIL - %d av %d matningar foll"):format(fel, antal))
else
	print(("[Smoke] RUNTIME_GRIND: PASS - %d matningar (%d ej matbara har)")
		:format(antal, ejMatbara))
end

return {
	kallhash = kallhash,
	del = DEL,
	mutation = tostring(_G.UBRF_MUTATION or ""),
	antal = antal,
	fel = fel,
	ejMatbara = ejMatbara,
	ejMatbaraRader = ejRader,
	sekunder = sekunder,
	rader = rader,
}
