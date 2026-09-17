--!strict
--[[
	SADELN OCH TRÄNSET DÄR DE FAKTISKT HÄNGER — på hästens egen boxfront.

	══ VARFÖR TJÄNSTEN FINNS ═══════════════════════════════════════════

	`TackService` kunde neka fel sadel serverauktoritärt, men ingenting i
	Roblox kunde LÄMNA ett felaktigt val: `GameplayService.valjUtrustning`
	hade ingen anropare. Utrustningen togs alltid från spelarens egen häst,
	och webbens hela poäng — att man kan gå fel och lära sig av det — fanns
	därmed bara som ett API. Ny död arkitektur, alltså, av samma slag som
	`Attachments`-mappen som städades bort i samma blockerare.

	Den här tjänsten är anroparen. Varje häst får sin sadel och sitt träns
	att hänga på sin EGEN boxfront, med sitt namn i prompten. Tar man dem
	vid fel box bär man fel hästs utrustning, och `TackService.satPa` säger
	då exakt det webbens sadelkammare säger.

	══ VARFÖR BOXFRONTEN OCH INTE SADELKAMMAREN ════════════════════════

	Webben lägger byglarna i sadelkammaren. Verkligheten gör det inte:

	  references/buildings/stall/KORT.md:305
	  "På fronterna hänger sadlar med underlag, täcken, grimmor, träns och
	   benskydd — mycket saker, tätt."  [ej byggt i spelet ännu]

	Och sadelkammarens egen referensbild (`stall-inne-03-sadelkammaren.jpg`)
	visar stövlar och täcken, inte sadlar. Källordningen i CLAUDE.md sätter
	verifierade referenser över nuvarande implementation, så platsen följer
	fotot och inte webben. Webbens sadelkammare är INTE ändrad — skillnaden
	är rapporterad för beslut i stället för tyst omskriven.

	Det bygger dessutom bort en dokumenterad [ej byggt i spelet ännu] ur
	stallkortet.

	══ GEOMETRIN ÄR PROTOTYP ═══════════════════════════════════════════

	Samma medvetna val som i `TackRigg`: lådor i rätt storlek på rätt
	ställe. `HORSE_VISUAL_QUALITY_GATE` byter ut utrustningen.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Spel = require(ReplicatedStorage.UBRFSpel)
local Stallet = require(ReplicatedStorage.Stallet)
local G = require(ReplicatedStorage.UBRFKomplex)

local TackForradService = {}

local M = 3          -- studs per meter, som BuildKit.M
local ANLAGGNING = "Anläggning"
local MAPP = "Tackförråd"

local LADER      = Color3.fromRGB(96, 61, 36)
local LADER_MORK = Color3.fromRGB(64, 41, 25)
local FILT       = Color3.fromRGB(226, 222, 212)
local METALL     = Color3.fromRGB(154, 155, 147)

--[[ Vem som tar emot valet. Skickas in av `start()` så att tjänsten går
	att prova utan hela GameplayService.

	MOTTAGAREN TAR EN TYP I TAGET (#235 FAS 1).

	Den tog forut HELA PARET i ett anrop (#169), och skalet var gott: ett
	par ar inte ett par om halva bytet gick igenom. Men FAS 1 i #235 delar
	upp arbetet i en overgang at gangen — SADEL: WORLD -> HELD — och da far
	sadeln inte langre slapa med sig transet.

	Atomiciteten forsvinner inte, den flyttar: `GameplayService.valjPar`
	star kvar for den som ska ha bada (`ridaNu`, dar stallet gor i ordning
	hela hasten), och den provar fortfarande bada innan den skriver nagot.
	Boxfronten anropar i stallet en typ.

	Tranget rors INTE i FAS 1. Det hanger kvar pa sin krok tills FAS 3
	ger det sin egen overgang. ]]
local mottagare: ((Player, string?, string?) -> (boolean, string?))? = nil

local function bas(): CFrame?
	local modell = workspace:FindFirstChild(ANLAGGNING)
	local ubrf = modell and modell:FindFirstChild("UBRF")
	return ubrf and ubrf.PrimaryPart and ubrf.PrimaryPart.CFrame or nil
end

local function radFor(id: string)
	for _, r in ipairs(G.stall.rader) do
		if r.id == id then return r end
	end
	return nil
end

local function del(foralder: Instance, namn: string, storlek: Vector3,
	cf: CFrame, farg: Color3, material: Enum.Material?): BasePart
	local p = Instance.new("Part")
	p.Name = namn
	p.Size = storlek
	p.CFrame = cf
	p.Color = farg
	p.Material = material or Enum.Material.Leather
	p.Anchored = true
	--[[ Hängande utrustning är inte ett hinder i gången. Hästen leds förbi
		boxfronterna på väg ut, och ledningen är låst mark. ]]
	p.CanCollide = false
	p.CanQuery = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = foralder
	return p
end

--[[ Var hästens utrustning hänger, i SITE-koordinater.

	Boxens mittpunkt kommer ur `Stallet.box`, som redan är den delade
	sanningen om var hästen står. Fronten sitter på den sida `vetter` pekar
	— samma uttryck som `byggBoxrader` väljer sin `fx` med — och
	utrustningen hänger en bit UT från den, i gången där spelaren går.

	Räknas den här om på egen hand hamnar utrustningen i boxen i stället
	för i gången för de två rader som vetter åt −x; det var precis det
	felet som en gång satte sexton hästar i stallgången. ]]
function TackForradService.lage(hastId: string): { [string]: any }?
	local box = Stallet.boxFor(hastId)
	if not box then return nil end
	local rad = radFor(box.rad)
	if not rad then return nil end
	local origoX = box.varld.x - box.lokal.x
	local frontX = origoX + rad.x0 + (if rad.vetter > 0 then rad.djup else 0)
	return {
		x = frontX + rad.vetter * 0.28,
		y = box.varld.y,
		vetter = rad.vetter,
		rad = box.rad,
		plats = box.plats,
	}
end

--[[ ATT TA UTRUSTNINGEN. Egen funktion och inte en anonym stängning i
	prompten, för att den ska gå att PRÖVA: en `ProximityPrompt.Triggered`
	kan inte fyras utanför Studio, och då hade routingen — att man verkligen
	får med sig den hästs utrustning vars front man stod vid — bara varit
	mätbar för hand.

	INGEN PRÖVNING AV VEM UTRUSTNINGEN TILLHÖR HÄR. Att kunna ta fel hästs
	sadel ÄR poängen; felet ska mötas när utrustningen sätts på hästen, med
	skälet, precis som på webben. ]]
function TackForradService.tagSadel(spelare: Player, hastId: string, namn: string?): (boolean, string?)
	local f = mottagare
	if not f then return false, "tack.ingen_mottagare" end
	--[[ ENDAST SADELN (#235 FAS 1). Se noten vid `mottagare`. ]]
	local ok, skal = f(spelare, hastId, "sadel")
	--[[ LOGGEN SKA VARA SANN (#169 P3). Den skrev förut att spelaren tog
		sadel och träns oavsett svaret, och blev därmed falsk QA-evidens i
		exakt de lägen man behöver den. Nu står det som hände, och ett nej
		bär sitt skäl. ]]
	if ok == true then
		print(("[Tack] %s tog %ss sadel."):format(spelare.Name, namn or hastId))
		return true
	end
	warn(("[Tack] %s fick INTE %ss sadel: %s"):format(
		spelare.Name, namn or hastId, tostring(skal)))
	--[[ SKALET FOLJER MED UT. Ett naket `false` gor att ingen — varken
		spelaren, loggen eller ett prov — kan skilja «for langt bort» fran
		«nagon annan har den», och da gar den skillnaden inte att grinda. ]]
	return false, skal
end

--[[ TRANSET (#235 FAS 3). Samma vag, samma mottagare, en annan typ.
	Att skriva en andra mottagare hade gett tva sanningar om vad en
	hamtning ar; det enda som skiljer ar strangen. ]]
function TackForradService.tagTrans(spelare: Player, hastId: string, namn: string?): (boolean, string?)
	local f = mottagare
	if not f then return false, "tack.ingen_mottagare" end
	local ok, skal = f(spelare, hastId, "trans")
	if ok == true then
		print(("[Tack] %s tog %ss trans."):format(spelare.Name, namn or hastId))
		return true
	end
	warn(("[Tack] %s fick INTE %ss trans: %s"):format(
		spelare.Name, namn or hastId, tostring(skal)))
	return false, skal
end

--[[ En hästs utrustning på hennes front: sadeln med underlägget under sig,
	tränset på egen krok bredvid — så som fotot visar dem, tätt. ]]
local function hangUpp(foralder: Folder, b: CFrame, hastId: string, namn: string): Model?
	local l = TackForradService.lage(hastId)
	if not l then return nil end

	local modell = Instance.new("Model")
	modell.Name = "Utrustning " .. namn
	modell:SetAttribute("ForHast", hastId)

	local function vid(dy: number, h: number): CFrame
		--[[ Site-y är norr på kartan och världen är dess högerhända avbild,
			så norr är −Z. Samma teckenbyte som `StallService.satMarkor`. ]]
		return b * CFrame.new(l.x * M, h * M, -(l.y + dy) * M)
	end

	--[[ ── TVA GRUPPER, INTE SEX LOSA DELAR (#235 FAS 1) ─────────────

		Sadeln ska kunna LAMNA fronten utan att transet gor det. Delarna
		lag forut direkt under modellen, och da fanns ingen yta att ta
		bort: `hangUpp` visste vilka delar som var sadelns, men ingen
		annan gjorde det.

		Grupperna bar `UBRFForrad` med typen, sa att `satSynlig` nedan
		kan slacka precis en av dem. Samma monster som `TackRigg` redan
		anvander for att halla isar buret och pasatt. ]]
	local sadelgrupp = Instance.new("Model")
	sadelgrupp.Name = "Sadelplats"
	sadelgrupp:SetAttribute("UBRFForrad", "sadel")
	sadelgrupp.Parent = modell

	local transgrupp = Instance.new("Model")
	transgrupp.Name = "Transplats"
	transgrupp:SetAttribute("UBRFForrad", "trans")
	transgrupp.Parent = modell

	del(sadelgrupp, "Underlägg", Vector3.new(0.10 * M, 0.46 * M, 0.60 * M),
		vid(-0.42, 1.20), FILT, Enum.Material.Fabric)
	local sadel = del(sadelgrupp, "Sadel", Vector3.new(0.34 * M, 0.30 * M, 0.52 * M),
		vid(-0.42, 1.56), LADER)
	del(sadelgrupp, "Sadelns gjord", Vector3.new(0.08 * M, 0.34 * M, 0.10 * M),
		vid(-0.42, 1.24), LADER_MORK)
	sadelgrupp.PrimaryPart = sadel

	--[[ TRANSKROKEN hor till fronten och inte till transet: kroken sitter
		kvar aven nar transet tas ned. Den ligger darfor UTANFOR gruppen. ]]
	del(modell, "Tränskrok", Vector3.new(0.14 * M, 0.04 * M, 0.04 * M),
		vid(0.42, 1.62), METALL, Enum.Material.Metal)
	local trans = del(transgrupp, "Träns", Vector3.new(0.05 * M, 0.40 * M, 0.26 * M),
		vid(0.42, 1.40), LADER)
	del(transgrupp, "Tyglar", Vector3.new(0.04 * M, 0.30 * M, 0.16 * M),
		vid(0.42, 1.16), LADER_MORK)
	transgrupp.PrimaryPart = trans

	--[[ NAMNSKYLTEN. Webbens sadelkammare har den på bygeln — "Namnskyltarna
		sitter på byglarna" — och här är den prompten. Hästens namn är ett
		EGENNAMN och skickas som argument, inte som översatt text. ]]
	--[[ EN PROMPT, EN HANDLING (#235 FAS 1). Den hamtade forut hela paret
		med ett tryck. Tranget far sin egen i FAS 3; tills dess hanger det
		kvar utan prompt, och det ar avsiktligt — inte en gloms. ]]
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "SadelPrompt"
	prompt.ActionText = "Ta sadeln"
	prompt:SetAttribute("SprakNyckel", "tack.ta_sadeln")
	prompt.ObjectText = namn .. "s sadel"
	prompt:SetAttribute("SprakObjekt", "tack.sadel_for")
	prompt:SetAttribute("SprakArg", namn)
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.ClickablePrompt = true
	--[[ EGEN KNAPP (#182 del 3). Sadeln delade `E` med boxdorren och
		uppsittningen, och de tre ar natbara samtidigt vid boxen.
		`G` och `ButtonL1` ar «ga vidare» respektive gangart ned — bada
		lever bara i sadeln, och utrustning hamtar man till fots. ]]
	prompt.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow
	prompt.KeyboardKeyCode = Enum.KeyCode.G
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonL1
	prompt.Parent = sadel

	prompt.Triggered:Connect(function(spelare)
		TackForradService.tagSadel(spelare, hastId, namn)
	end)

	--[[ ── TRANSETS EGEN PROMPT (#235 FAS 3) ─────────────────────

		Samma state-machine som sadeln, en egen handling. Den viktiga
		skillnaden mot att bara kopiera raderna ovan ar TANGENTEN.

		Bada hanger pa samma front och ar inom rackhall samtidigt. Lat
		de dela Roblox standardvarde (`E` / `ButtonX`) hade vi byggt
		precis det #235 rapporterade: flera prompter i djupet dar bara
		den narmaste gar att na, och spelaren far gissa vilken.

		`T` for trans ar mnemoniskt och delas med «se ritten», som bara
		lever i sadeln; `ButtonB` ar halvhalten, ocksa bara i sadeln.
		Samma kontextregel som `docs/KONTROLLMATRIS.md` redan bar. ]]
	local transPrompt = Instance.new("ProximityPrompt")
	transPrompt.Name = "TransPrompt"
	transPrompt.ActionText = "Ta transet"
	transPrompt:SetAttribute("SprakNyckel", "tack.ta_transet")
	transPrompt.ObjectText = namn .. "s trans"
	transPrompt:SetAttribute("SprakObjekt", "tack.trans_for")
	transPrompt:SetAttribute("SprakArg", namn)
	transPrompt.HoldDuration = 0
	transPrompt.MaxActivationDistance = 8
	transPrompt.RequiresLineOfSight = false
	transPrompt.ClickablePrompt = true
	transPrompt.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow
	transPrompt.KeyboardKeyCode = Enum.KeyCode.T
	transPrompt.GamepadKeyCode = Enum.KeyCode.ButtonB
	transPrompt.Parent = trans

	transPrompt.Triggered:Connect(function(spelare)
		TackForradService.tagTrans(spelare, hastId, namn)
	end)

	modell.PrimaryPart = sadel
	modell.Parent = foralder
	return modell
end

--[[ ══ UTRUSTNINGEN LAMNAR FRONTEN NAR NAGON BAR DEN (#235 FAS 1) ═════

	Kravet ar att sadeln «omedelbart lamnar boxfront/rack visuellt» vid
	lyckad pickup. Den satt kvar forut: spelaren fick en buren sadel OCH
	sag den hanga kvar pa fronten, alltsa tva sadlar.

	Grupperna slacks, de rivs inte. Skalet ar ATERSTALLNINGEN: en spelare
	som kopplar ned, dor eller lamnar passet ska lamna tillbaka sadeln,
	och en riven modell hade maste byggas om ur geometrin. `Transparency`
	plus `CanQuery` racker — och prompten stangs av, sa att ingen kan ta
	en sadel som redan bars.

	Servern ager detta. Klienten far se resultatet replikeras. ]]
local function grupp(hastId: string, typ: string): Model?
	local m = TackForradService.forHast(hastId)
	if not m then return nil end
	for _, g in ipairs(m:GetChildren()) do
		if g:IsA("Model") and g:GetAttribute("UBRFForrad") == typ then return g end
	end
	return nil
end

function TackForradService.satSynlig(hastId: string, typ: string, synlig: boolean): boolean
	local g = grupp(hastId, typ)
	if not g then return false end
	for _, d in ipairs(g:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Transparency = if synlig then 0 else 1
			d.CanQuery = synlig
		elseif d:IsA("ProximityPrompt") then
			d.Enabled = synlig
		end
	end
	g:SetAttribute("UBRFPaFronten", synlig)
	return true
end

--[[ Hanger utrustningen kvar pa fronten? Provets och tjanstens gemensamma
	fraga — lasen ur VARLDEN, inte ur ett register. ]]
--[[ FINNS UPPHANGNINGEN ALLS? Skild fran `paFronten`, som svarar pa om
	delen HANGER dar. De tva ar olika fragor: en saknad grupp ar ett
	byggfel, en tom krok ar ett normalt lage — sadeln ligger da pa
	hasten. #235 FAS 2 behover kunna skilja dem at for att neka en
	hamtning fran en TOM krok utan att samtidigt sla undan benen pa
	FAS 1:s prov for en SAKNAD grupp. ]]
function TackForradService.harPlats(hastId: string, typ: string): boolean
	return grupp(hastId, typ) ~= nil
end

function TackForradService.paFronten(hastId: string, typ: string): boolean
	local g = grupp(hastId, typ)
	if not g then return false end
	return g:GetAttribute("UBRFPaFronten") ~= false
end

function TackForradService.mapp(): Folder?
	local f = workspace:FindFirstChild(MAPP)
	return (f and f:IsA("Folder")) and f or nil
end

--[[ Hur många hästar som faktiskt fick sin utrustning upphängd. Provet
	läser den i stället för att lita på att bygget inte tystnade. ]]
function TackForradService.antal(): number
	local f = TackForradService.mapp()
	if not f then return 0 end
	local n = 0
	for _, m in ipairs(f:GetChildren()) do
		if m:IsA("Model") and m:GetAttribute("ForHast") then n += 1 end
	end
	return n
end

--[[ Utrustningen som hänger på en viss hästs front. ]]
function TackForradService.forHast(hastId: string): Model?
	local f = TackForradService.mapp()
	if not f then return nil end
	for _, m in ipairs(f:GetChildren()) do
		if m:IsA("Model") and m:GetAttribute("ForHast") == hastId then return m end
	end
	return nil
end

function TackForradService.start(ta: ((Player, string?, string?) -> (boolean, string?))?)
	mottagare = ta

	local b = bas()
	if not b then
		warn("[Tack] Anläggningen är inte byggd — ingen utrustning hängd.")
		return
	end

	local gammal = TackForradService.mapp()
	if gammal then gammal:Destroy() end

	local f = Instance.new("Folder")
	f.Name = MAPP
	f.Parent = workspace

	local hangda = 0
	for _, id in ipairs(Spel.ordning) do
		local h = Spel.hastar[id]
		if h and hangUpp(f, b, id, tostring(h.namn)) then hangda += 1 end
	end
	print(("[Tack] Utrustning upphängd på %d av %d boxfronter.")
		:format(hangda, #Spel.ordning))
end

return TackForradService
