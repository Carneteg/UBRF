--!strict
--[[
	Blackrock Jack som en faktisk rigg i världen.

	P0 i ChatGPT:s whole-place review #162 16:40: det fanns INGEN hästmodell
	i First Playable-placen. Inget i repot skapade en häst-`Model`, `Seat`
	eller `Humanoid`; `HorseService` registrerar bara
	`CollectionService:GetTagged("Horse")`, och den genererade `.rbxlx`
	innehöll noll av varje. Spelaren tilldelades `blackrock_jack` i datan och
	`GameplayService.bind()` fick aldrig en modell — skötsel, uppsittning och
	ridning kunde aldrig börja.

	Det här är avsiktligt en PLATSHÅLLARRIGG, inte en hästmodell: enkla
	lådor i rätt hierarki, med rätt namn, kollision och attachment-punkter.
	`roblox/docs/HORSE-MODEL-SPEC.md` är strikt just där — hierarkin,
	kollisionen och attachmentpunkterna — och lös om utseendet. Ett riktigt
	nät kan bytas in senare utan att någon annan kod ändras.

	INGEN UBRF-DETALJ ÄR PÅHITTAD. Jacks identitet, ras och beskrivning
	kommer ur `UBRFSpelData`; hans box ur `Stallet.boxFor`. Måtten nedan är
	spelabstraktion för en ponny i kategori D (den kategori datan anger) och
	är märkta som sådana — inte en mätning av den verkliga hästen.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JackRigg = {}

local TAG = "Horse"
local M = 3                     -- studs per meter, som BuildKit.M

--[[ Kategori D är ponny upp till 1,48 m i mankhöjd. Datan ger ingen
	mankhöjd för Jack (`mankhojd = nil`), så kroppen byggs på kategorins
	övre del. Det är en SPELABSTRAKTION och ingen mätning. ]]
local MANKHOJD = 1.45
local KROPP_L, KROPP_B, KROPP_H = 1.85, 0.62, 0.78
local BEN_H = MANKHOJD - KROPP_H          -- marken till kroppens undersida

local FARG_KROPP = Color3.fromRGB(92, 68, 52)
local FARG_MAN = Color3.fromRGB(46, 34, 26)

local function del(foralder: Instance, namn: string, storlek: Vector3,
	cf: CFrame, farg: Color3): BasePart
	local p = Instance.new("Part")
	p.Name = namn
	p.Size = storlek
	p.CFrame = cf
	p.Color = farg
	p.Anchored = false
	p.CanCollide = false        -- bara BodyCollider kolliderar
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = foralder
	return p
end

local function svets(a: BasePart, b: BasePart, namn: string): WeldConstraint
	local w = Instance.new("WeldConstraint")
	w.Name = namn
	w.Part0 = a
	w.Part1 = b
	w.Parent = a
	return w
end

--[[ Bygger riggen vid `bas` (världs-CFrame, hästens mitt i marknivå). ]]
function JackRigg.bygg(hastId: string, namn: string, bas: CFrame): Model
	local modell = Instance.new("Model")
	modell.Name = namn

	--[[ BodyCollider ÄR hästen fysiskt. Den enda delen som kolliderar, och
		den `RigAdapter.resolveRoot` letar efter först. ]]
	local kropp = Instance.new("Part")
	kropp.Name = "BodyCollider"
	kropp.Size = Vector3.new(KROPP_B * M, KROPP_H * M, KROPP_L * M)
	kropp.CFrame = bas * CFrame.new(0, (BEN_H + KROPP_H / 2) * M, 0)
	kropp.Transparency = 1
	kropp.CanCollide = true
	kropp.Anchored = false
	kropp.Parent = modell
	modell.PrimaryPart = kropp

	--[[ Humanoid ger markkontakt, lutning och trappor gratis, och är den väg
		RigAdapter rekommenderar. Utan den faller `build()` tillbaka på
		AnimationController, som kräver egen fysik vi inte levererar. ]]
	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = modell
	local animator = Instance.new("Animator")
	animator.Parent = humanoid

	--[[ Visual: ingen kollision alls. Lådor, inte ett nät — utseendet är
		inte det som gör spelet spelbart, och specen är lös här. ]]
	local visual = Instance.new("Folder")
	visual.Name = "Visual"
	visual.Parent = modell

	local synlig = del(visual, "HorseMesh",
		Vector3.new(KROPP_B * M, KROPP_H * M, KROPP_L * M),
		kropp.CFrame, FARG_KROPP)
	svets(kropp, synlig, "VisualWeld")

	local hals = del(visual, "Neck",
		Vector3.new(0.34 * M, 0.62 * M, 0.34 * M),
		kropp.CFrame * CFrame.new(0, 0.34 * M, -(KROPP_L / 2 - 0.1) * M)
			* CFrame.Angles(math.rad(-24), 0, 0), FARG_KROPP)
	svets(synlig, hals, "NeckWeld")

	local huvud = del(visual, "Head",
		Vector3.new(0.28 * M, 0.30 * M, 0.62 * M),
		hals.CFrame * CFrame.new(0, 0.34 * M, -0.16 * M)
			* CFrame.Angles(math.rad(24), 0, 0), FARG_KROPP)
	svets(hals, huvud, "HeadWeld")

	local man = del(visual, "Mane",
		Vector3.new(0.10 * M, 0.46 * M, 0.30 * M),
		hals.CFrame * CFrame.new(0, 0.10 * M, 0.06 * M), FARG_MAN)
	svets(hals, man, "ManeWeld")

	local svans = del(visual, "Tail",
		Vector3.new(0.14 * M, 0.52 * M, 0.14 * M),
		kropp.CFrame * CFrame.new(0, 0.10 * M, (KROPP_L / 2) * M), FARG_MAN)
	svets(synlig, svans, "TailWeld")

	--[[ Fyra ben. De kolliderar inte: markkontakten sitter i BodyCollider,
		och kolliderande ben hade bråkat med Humanoids egen markmodell. ]]
	for _, b in ipairs({
		{ "LegFL", -1, -1 }, { "LegFR", 1, -1 }, { "LegBL", -1, 1 }, { "LegBR", 1, 1 },
	}) do
		local ben = del(visual, b[1] :: string,
			Vector3.new(0.14 * M, BEN_H * M, 0.14 * M),
			bas * CFrame.new((b[2] :: number) * (KROPP_B / 2 - 0.08) * M,
				(BEN_H / 2) * M, (b[3] :: number) * (KROPP_L / 2 - 0.22) * M),
			FARG_KROPP)
		svets(kropp, ben, "LegWeld")
	end

	--[[ RootJoint bär kroppens lutning i svängar; RiderJoint bär ryttarens.
		Att de är två skilda leder är #162:s andra blockerare: lutningen låg
		förut på `RiderSeat`, som är en `Seat` utan `C0`. ]]
	local rootJoint = Instance.new("Motor6D")
	rootJoint.Name = "RootJoint"
	rootJoint.Part0 = kropp
	rootJoint.Part1 = synlig
	rootJoint.Parent = kropp

	local riderJoint = Instance.new("Motor6D")
	riderJoint.Name = "RiderJoint"
	riderJoint.Part0 = kropp
	riderJoint.Part1 = synlig
	riderJoint.Parent = kropp

	--[[ Sitsen. Osynlig, massless, kolliderar inte — och en riktig `Seat`,
		så `HorseService.tryMount` (`seat:Sit(humanoid)`) och `seat.Occupant`
		arbetar mot det API de är skrivna för. ]]
	local sits = Instance.new("Seat")
	sits.Name = "RiderSeat"
	sits.Size = Vector3.new(0.5 * M, 0.16 * M, 0.7 * M)
	sits.CFrame = kropp.CFrame * CFrame.new(0, (KROPP_H / 2 + 0.08) * M, 0)
	sits.Transparency = 1
	sits.CanCollide = false
	sits.Massless = true
	sits.Anchored = false
	sits.Parent = modell
	--[[ Namnet är INTE "SeatWeld": Roblox skapar själv en `Weld` med det
		namnet under sitsen när någon sätter sig, och `HorseService.dismount`
		letar just den när sitsen inte släpper. Två objekt med samma namn i
		samma rigg är en fälla — avsittningen kunde få tag i riggens
		bärande svets och sitsen hade lossnat från hästen. ]]
	svets(kropp, sits, "SitsFaste")

	--[[ Attachmentpunkterna. Specen är strikt här: sadel, tyglar och
		stigbyglar är det utrustning och ryttarpose hänger på. ]]
	local fasten = Instance.new("Folder")
	fasten.Name = "Attachments"
	fasten.Parent = modell
	local function fast(namn: string, offset: CFrame)
		local a = Instance.new("Attachment")
		a.Name = namn
		a.CFrame = offset
		a.Parent = kropp
		return a
	end
	fast("SaddleAttachment", CFrame.new(0, (KROPP_H / 2) * M, 0))
	fast("LeftReinAttachment", CFrame.new(-0.18 * M, 0.30 * M, -(KROPP_L / 2) * M))
	fast("RightReinAttachment", CFrame.new(0.18 * M, 0.30 * M, -(KROPP_L / 2) * M))
	fast("LeftStirrupAttachment", CFrame.new(-(KROPP_B / 2) * M, 0, 0))
	fast("RightStirrupAttachment", CFrame.new((KROPP_B / 2) * M, 0, 0))

	for _, konf in ipairs({ "HorseStats", "GaitConfig", "AnimationConfig" }) do
		local c = Instance.new("Configuration")
		c.Name = konf
		c.Parent = modell
	end

	--[[ Identiteten. `HorseId` är den kanoniska nyckeln HorseService och
		GameplayService matchar tilldelningen mot, och taggen är det som gör
		att den registreras alls. ]]
	modell:SetAttribute("HorseId", hastId)
	modell:SetAttribute("Riggkalla", "JackRigg platshallarrigg")
	return modell
end

--[[ ══ HÄSTARNA PÅ SINA PLATSER ═══════════════════════════════════════

	P0-5 ur Tobias andra Studio-test: stallet är tomt.

	Det var sant, och rostergrinden såg det inte. Den riggar trettiotre
	hästar EN I TAGET i en testbänk, mäter dem och river dem — den bevisar
	att riggen går att bygga, aldrig att någon står i stallet. Produktionen
	byggde en enda häst: första dagens.

	Identiteterna läses ur den delade sanningen (`UBRFSpelData.hastar`),
	lägena ur `Stallet.boxFor`. Inget hittas på här: en häst utan box i
	datan får ingen påhittad plats, den rapporteras. ]]

--[[ Modulerna läses utan `WaitForChild`. Det här är SERVERKOD, och på
	servern finns ReplicatedStorage-barnen redan när skriptet körs —
	väntan fanns för klientens skull och gjorde samtidigt modulen omöjlig
	att köra i testbänken, som inte har en replikeringsgraf. ]]
local function delad(namn: string)
	local ok, m = pcall(function()
		if namn == "Stallet" then return require(ReplicatedStorage.Stallet) end
		return require(ReplicatedStorage.UBRFSpelData)
	end)
	if not ok then return nil end
	return m
end

local function namnFor(hastId: string): string
	local Data = delad("UBRFSpelData")
	local h = Data and ((Data :: any).hastar or {})[hastId]
	if h and h.namn then return tostring(h.namn) end
	return tostring(hastId)
end

--[[ Anläggningens bas. Lägena räknas relativt den, inte mot världens
	origo, eftersom modellen bär transformen. ]]
local function anlaggningsbas(): CFrame?
	local folder = workspace:FindFirstChild("Anläggning")
	local komplex = folder and folder:FindFirstChild("UBRF")
	if not komplex or not (komplex :: any).PrimaryPart then return nil end
	return ((komplex :: any).PrimaryPart :: BasePart).CFrame
end

--[[ En häst i sin egen box. Returnerar modellen, eller nil med ett skäl. ]]
function JackRigg.placera(hastId: string): (Model?, string?)
	local Stallet = delad("Stallet")
	if not Stallet then return nil, "Stallet saknas i ReplicatedStorage" end

	local box = (Stallet :: any).boxFor(hastId)
	if not box or not box.varld then return nil, "ingen box i datan" end

	local bas = anlaggningsbas()
	if not bas then return nil, "anläggningen är inte byggd" end

	--[[ VÄNDA VÄRLDEN: site-y är norr på kartan, och världen är en
		högerhänt avbild av kartan där norr är −Z. Relativt anläggningens
		`PrimaryPart` — som speglas med resten — blir omräkningen därför
		ett enda teckenbyte. Härledningen står en gång, i
		`BuildKit.tomtlage`; den här filen kan inte require:a BuildKit
		(den ligger i en annan gren av ServerScriptService och saknas i
		integrationsbänken), så tecknet står här, med samma namn att söka
		på. Felaktigt tecken fälls av `spelbarhet.spec`, som mäter var
		markören och hästen faktiskt hamnar i det byggda stallet. ]]
	local lage = bas * CFrame.new(box.varld.x * M, 0, -box.varld.y * M)

	local modell = JackRigg.bygg(hastId, namnFor(hastId), lage)
	modell.Parent = workspace
	--[[ Taggen SIST: HorseService lyssnar på `GetInstanceAddedSignal`, och
		en halvbyggd modell ska inte kunna registreras. ]]
	CollectionService:AddTag(modell, TAG)
	return modell, nil
end

--[[ Hela stallet. Första dagens häst returneras separat eftersom
	startkontraktet i `init.server.luau` hänger på just den: utan henne kan
	spelaren inte börja, och då ska starten säga det. ]]
function JackRigg.start(): Model?
	local Stallet = delad("Stallet")
	if not Stallet then
		warn("[Rigg] Stallet saknas i ReplicatedStorage — ingen häst byggd.")
		return nil
	end
	local Data = delad("UBRFSpelData")
	local hastar = (Data and (Data :: any).hastar) or {}

	--[[ Ordningen är `Spel.ordning` där den finns: samma ordning som
		boxfördelningen räknas ur, så att utskriften går att jämföra med
		stallplanen. Annars sorterade id:n — aldrig pairs-ordning, som är
		olika mellan körningar. ]]
	local ids = {}
	for id in pairs(hastar) do table.insert(ids, id) end
	table.sort(ids)

	local forsta: Model? = nil
	local byggda, utanBox = 0, {}
	for _, id in ipairs(ids) do
		local m, varfor = JackRigg.placera(id)
		if m then
			byggda += 1
			if id == (Stallet :: any).FORSTA_DAGEN_HAST then forsta = m end
		else
			table.insert(utanBox, ("%s (%s)"):format(id, tostring(varfor)))
		end
	end

	print(("[Rigg] %d av %d hästar står i sina boxar"):format(byggda, #ids))
	if #utanBox > 0 then
		warn(("[Rigg] utan plats: %s"):format(table.concat(utanBox, ", ")))
	end
	if not forsta then
		warn(("[Rigg] första dagens häst (%s) kom inte på plats.")
			:format(tostring((Stallet :: any).FORSTA_DAGEN_HAST)))
	end
	return forsta
end

return JackRigg
