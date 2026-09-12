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

local HastVisual = require(script.Parent.HastVisual)
local Utseende = require(ReplicatedStorage.HorseCore.Utseende)

--[[ ══ VILKA HÄSTAR SOM BÄR ETT RIKTIGT NÄT ═══════════════════════

	Hela rostern, sedan Tobias godkände K3 som bas.

	Det här VAR en lista, och listan var rätt så länge den beskrev ett
	undantag: en häst av trettiotre, sedan fyra, sedan nio. Nu är nätet
	regeln och lådan undantaget — och då ska koden säga det, inte rada
	upp trettiotre identiska rader som alla betyder "som alla andra".

	`UTAN_NAT` finns för att undantaget ska gå att skriva ned den dag det
	behövs, med ett skäl. Den är tom idag, och det är själva poängen. ]]
local STANDARDPROFIL = "k3"
local UTAN_NAT: { [string]: string } = {}

--[[ Vilken visuell profil en häst ska bära, och varför. Svarar nil när
	hästen med flit ska stå kvar i lådor. ]]
local function visuellProfil(hastId: string): string?
	if UTAN_NAT[hastId] then return nil end
	return STANDARDPROFIL
end

--[[ ══ KROPPENS GRUNDFORM ══════════════════════════════════════════

	Talen nedan beskriver en kategori D-ponny på 1,45 m: Blackrock Jacks
	mått, och länge hela rostens. De är en SPELABSTRAKTION och ingen
	mätning av ett verkligt djur.

	══ VARFÖR DE NU SKALAS PER HÄST ═══════════════════════════════════

	Efter rosterkonverteringen bar varje häst sitt eget UTSEENDE — Marabou
	1,27 m, Allan 1,78 — men samma FYSISKA hölje. Uppmätt var `HipHeight`
	2,01 studs för var och en av de trettiotre, alltså byggd ur den här
	1,45:an. Allans kollisionslåda var en ponnys, och den lilla ponnyns
	var en varmblodshästs.

	Det syntes inte förrän man mätte, men det är fel på riktigt: hur stort
	utrymme en häst tar i en box, hur nära en vägg hon kan stå och var
	ryttaren hamnar är alla frågor om KROPPEN, inte om nätet.

	Grundformen skalas därför linjärt med hästens egen mankhöjd. Formen är
	densamma — en häst är inte en annan form för att hon är högre — och
	proportionerna kommer ur den enda mätta hästen vi har. ]]
local GRUND_MANKHOJD = 1.45
local GRUND_L, GRUND_B, GRUND_H = 1.85, 0.62, 0.78

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
	p.CanCollide = false        -- bara rotdelen kolliderar
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

--[[ Kroppens mått för en häst med mankhöjden `mankhojd` (meter).
	Egen funktion för att provet ska kunna läsa SAMMA räkning som riggen
	byggs med — två räkningar hade kunnat glida isär. ]]
function JackRigg.kroppsmatt(mankhojd: number?): { [string]: number }
	local h = if type(mankhojd) == "number" and mankhojd > 0.5 and mankhojd < 2.5
		then mankhojd else GRUND_MANKHOJD
	local k = h / GRUND_MANKHOJD
	local kroppH = GRUND_H * k
	return {
		mankhojd = h, skala = k,
		L = GRUND_L * k, B = GRUND_B * k, H = kroppH,
		--[[ Marken till kroppens undersida. Att den räknas som mankhöjd
			MINUS kroppshöjd och inte skalas för sig är vad som håller
			hovarna på marken: benlängden är det som blir över. ]]
		benH = h - kroppH,
	}
end

--[[ Bygger riggen vid `bas` (världs-CFrame, hästens mitt i marknivå).
	`mankhojd` är hästens egen, i meter; utelämnad blir det grundformen. ]]
function JackRigg.bygg(hastId: string, namn: string, bas: CFrame,
	mankhojd: number?): Model
	local matt = JackRigg.kroppsmatt(mankhojd)
	local KROPP_L, KROPP_B, KROPP_H = matt.L, matt.B, matt.H
	local BEN_H = matt.benH
	local modell = Instance.new("Model")
	modell.Name = namn

	--[[ Kroppen ÄR hästen fysiskt: den enda delen som kolliderar.

		NAMNET ÄR ETT MOTORKRAV, inte en smaksak. Roblox binder
		`Humanoid.RootPart` till den syskondel som heter EXAKT
		`HumanoidRootPart` — ingen annan. Den här delen hette
		`BodyCollider` (projektets eget namn ur `HORSE-MODEL-SPEC.md`), och
		då blev `Humanoid.RootPart` nil. Utan rot hittar Humanoiden inget
		golv (`FloorMaterial = Air`) och lägger aldrig på någon gångkraft:
		lokal Studio-QA på `9b5a570` mätte `gait=walk`, `WalkSpeed=4.93`,
		`MoveDirection=1.00` och 0,00 studs förflyttning på 3,2 sekunder.

		Falsifierat i runtime: enbart namnbytet band roten, `FloorMaterial`
		gick `Air -> Concrete` och hästen gick 2,49 studs. Det här är den
		rättelsen i källan.

		`RigAdapter.resolveRoot` letar `HumanoidRootPart` först och
		`BodyCollider` därefter, så externt byggda riggar med det gamla
		namnet fungerar fortfarande. ]]
	local kropp = Instance.new("Part")
	kropp.Name = "HumanoidRootPart"
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
	--[[ HipHeight är avståndet från marken till rotdelens UNDERSIDA. Roten
		är kroppen, och kroppen ska stå på benen — alltså benhöjden.
		Lämnas den 0 sjunker kroppen ner i marken när roten väl är bunden,
		och `HORSE-MODEL-SPEC.md` säger samma sak: mankhöjd minus halva
		kroppshöjden. ]]
	humanoid.HipHeight = BEN_H * M
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

	--[[ Fyra ben. De kolliderar inte: markkontakten sitter i rotdelen,
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
	--[[ SITSEN FÅNGAR INGEN GENOM BERÖRING. En `Seat` sätter av sig själv
		varje `Humanoid` vars kropp NUDDAR den, och sitsen sitter fastsvetsad
		ovanpå hästens egen rot — alltså mitt i hennes egen kropp.

		Uppsittningen går inte den vägen: `HorseService.tryMount` anropar
		`seat:Sit(humanoid)` rakt, och `Sit` bryr sig inte om `CanTouch`.
		Beröringsvägen har därför ingen uppgift alls i det här spelet, och
		det enda den gör är att låta hästen sätta sig på sig själv.

		Mätt i Studio med beröringen kvar: vakten nedan kastade ut henne,
		kropparna rörde varandra igen i nästa bildruta, och hon satte sig
		på nytt — `Occupant` satt, en ny `SeatWeld`, och hon rörde sig
		1,21 studs på fyra sekunder med full order att gå. Vakten räckte
		alltså inte ensam: kontakten måste också upphöra att betyda något. ]]
	sits.CanTouch = false
	sits.Parent = modell
	--[[ Namnet är INTE "SeatWeld": Roblox skapar själv en `Weld` med det
		namnet under sitsen när någon sätter sig, och `HorseService.dismount`
		letar just den när sitsen inte släpper. Två objekt med samma namn i
		samma rigg är en fälla — avsittningen kunde få tag i riggens
		bärande svets och sitsen hade lossnat från hästen. ]]
	svets(kropp, sits, "SitsFaste")

	--[[ ══ HÄSTEN FÅR ALDRIG SITTA PÅ SIN EGEN SITS ═══════════════════

		En `Seat` fångar VARJE `Humanoid` vars kropp rör den — den frågar
		inte vems humanoid det är. Sitsen sitter fastsvetsad ovanpå hästens
		egen rot, och rör de två varandra sätter hästen sig på sig själv:

		    Humanoid.Sit = true · SeatPart = RiderSeat
		    HumanoidStateType.Seated · FloorMaterial = Air

		En sittande humanoid svävar och slutar lyda `Move`. Uppmätt under
		rosterprovet: åtta hästar som ställdes om hamnade i det läget, tre
		av dem gick inte att få ur det utan att svetsen revs för hand.

		Att det inte händer under vanlig ridning är sant men inte ett
		skydd. Det räcker att en häst flyttas — en respawn, en världsladdning,
		en framtida hage — för att hon ska kunna landa i sin egen sits, och
		då står hon svävande och obrukbar tills någon startar om platsen.

		Vakten nedan lyssnar på sitsens EGEN signal och kastar ut varje
		occupant som hör hemma i den här hästen. Den rör inte spelaren:
		ryttarens humanoid bor i hennes karaktär, inte i hästmodellen. ]]
	sits:GetPropertyChangedSignal("Occupant"):Connect(function()
		local o = sits.Occupant
		if not o then return end
		--[[ Är det hästens egen humanoid — alltså en som bor i den här
			modellen — ska den ut. Allt annat är en ryttare. ]]
		if not o:IsDescendantOf(modell) then return end
		--[[ Roblox svetsar fast den som satt sig; `Sit = false` ensamt
			släpper inte svetsen, och då blir hon kvar i luften. ]]
		local w = sits:FindFirstChild("SeatWeld")
		if w then w:Destroy() end
		o.Sit = false
		o:ChangeState(Enum.HumanoidStateType.GettingUp)
		warn(("[Rigg] %s satte sig på sin egen sits och kastades ut"):format(namn))
	end)

	--[[ ══ ANATOMISKA FÄSTPUNKTER ═══════════════════════════════════

		Utrustningen och ryttarposen hänger här. Punkterna sitter på den
		KROPPSDEL de hör till, inte på en gemensam låda — det är hela
		skillnaden mellan ett träns som följer huvudet och ett som hänger i
		luften framför hästen.

		TVÅ FEL RÄTTADE 2026-09-11:

		1. Tygelpunkterna satt på `kropp`, inte på huvudet. Specen är
		   uttrycklig: `HORSE-MODEL-SPEC.md:140` — "Sätt tygelpunkterna på
		   huvudets ben, inte på BodyCollider. Då följer händerna med när
		   hästen sänker huvudet, vilket är hela poängen med tyglar."
		   De ligger nu i bettets läge, i huvudets mungipor.

		2. En `Folder` vid namn `Attachments` skapades, parentades på
		   modellen och användes ALDRIG — varje attachment hamnade på
		   `kropp`. Den är borta. En `Attachment` måste ligga på en
		   `BasePart` för att ha någon `WorldCFrame`; en mapp kan inte
		   vara gränssnittet. Gränssnittet är i stället namnen nedan, och
		   `RigAdapter.tackfaste()` slår upp dem. En framtida hästrigg
		   behöver bara bära samma namn på rätt kroppsdelar. ]]
	local function fast(vardpart: BasePart, namn: string, offset: CFrame)
		local a = Instance.new("Attachment")
		a.Name = namn
		a.CFrame = offset
		a.Parent = vardpart
		return a
	end
	--[[ RYGGEN: sadelläget, mitt på bålen, på kroppens ovansida. ]]
	fast(kropp, "SaddleAttachment", CFrame.new(0, (KROPP_H / 2) * M, 0))
	--[[ HUVUDET: tränsets läge, på huvudets mitt. Huvudets lokala -Z är
		nosen (delen byggs framåt ur halsen), så nackstycket ligger en bit
		bakåt och uppåt från mitten. ]]
	fast(huvud, "BridleAttachment", CFrame.new(0, 0.06 * M, 0.06 * M))
	--[[ BETTET: tygelpunkterna i mungiporna, på var sin sida om nosen. ]]
	fast(huvud, "LeftReinAttachment", CFrame.new(-0.14 * M, -0.04 * M, -0.20 * M))
	fast(huvud, "RightReinAttachment", CFrame.new(0.14 * M, -0.04 * M, -0.20 * M))
	--[[ STIGBYGLARNA hänger i sadeln och hör därför till bålen. ]]
	fast(kropp, "LeftStirrupAttachment", CFrame.new(-(KROPP_B / 2) * M, 0, 0))
	fast(kropp, "RightStirrupAttachment", CFrame.new((KROPP_B / 2) * M, 0, 0))
	--[[ HANDLÄGET: där ryttaren håller tyglarna, över manken strax framför
		och ovanför sadeln. Punkten är ryttarpose-rättningen efter den
		visuella granskningen av K3: händerna sköttes förut av IK mot
		BETTET, som ligger i hästens mun, och det vred överkroppen
		framstupa. Lådriggen bär samma punkt så att posen blir densamma
		oavsett om hästen har nät eller lådor. ]]
	fast(kropp, "LeftHandAttachment", CFrame.new(-0.10 * M, (KROPP_H / 2 + 0.20) * M, -0.20 * M))
	fast(kropp, "RightHandAttachment", CFrame.new(0.10 * M, (KROPP_H / 2 + 0.20) * M, -0.20 * M))

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

--[[ Hästens egen rad ur den delade sanningen. Det visuella lagret läser
	färg, tecken och mankhöjd ur den — inte ur en kopia av Jack. Saknas
	raden får hästen rosterns standardutseende, och `Utseende` säger att
	den gjorde det. ]]
local function dataFor(hastId: string): { [string]: any }?
	local Data = delad("UBRFSpelData")
	return Data and ((Data :: any).hastar or {})[hastId] or nil
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

	--[[ Hästens egen mankhöjd, ur samma karta som utseendet läser: en
		häst ska vara lika stor fysiskt som hon är visuellt. ]]
	local hd = dataFor(hastId)
	local egenHojd = Utseende.mankhojd(hd or {})
	local modell = JackRigg.bygg(hastId, namnFor(hastId), lage, egenHojd)

	--[[ ══ DET VISUELLA LAGRET ═══════════════════════════════════════

		HORSE_VISUAL_QUALITY_GATE, prototypsteget. Bara de hästar som står
		i `VISUELL` får ett riktigt nät; resten behåller lådorna. Det är
		med flit: ordern säger EN häst, och en lista är enklare att lita på
		än ett villkor.

		Monteringen sker FÖRE `Parent = workspace` och före taggen, så att
		HorseService aldrig ser en halvbyggd häst, och den sker i en pcall:
		ett visuellt lager får aldrig kunna fälla spelbarheten. Faller det
		står hästen kvar i lådor och Output säger varför. ]]
	local profil = visuellProfil(hastId)
	if profil then
		local ok, skal = pcall(function()
			local mall = HastVisual.mall(profil)
			if not mall then return "mallen saknas: ServerStorage.HastVisualer." .. profil end
			local monterad, m = HastVisual.montera(modell, mall, profil, dataFor(hastId))
			return if monterad then nil else m
		end)
		if not ok then
			warn(("[Rigg] visuellt lager föll för %s: %s"):format(hastId, tostring(skal)))
		elseif skal ~= nil then
			warn(("[Rigg] %s behåller lådorna: %s"):format(hastId, tostring(skal)))
		else
			print(("[Rigg] %s bär nu profilen %q"):format(hastId, profil))
		end
	end

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
