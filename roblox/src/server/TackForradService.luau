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
	att prova utan hela GameplayService. ]]
local mottagare: ((Player, string, string?) -> (boolean, string?))? = nil

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
function TackForradService.tag(spelare: Player, hastId: string, namn: string?): boolean
	local f = mottagare
	if not f then return false end
	local okS = f(spelare, "sadel", hastId)
	local okT = f(spelare, "trans", hastId)
	print(("[Tack] %s tog %ss sadel och träns."):format(
		spelare.Name, namn or hastId))
	return okS == true and okT == true
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

	del(modell, "Underlägg", Vector3.new(0.10 * M, 0.46 * M, 0.60 * M),
		vid(-0.42, 1.20), FILT, Enum.Material.Fabric)
	local sadel = del(modell, "Sadel", Vector3.new(0.34 * M, 0.30 * M, 0.52 * M),
		vid(-0.42, 1.56), LADER)
	del(modell, "Sadelns gjord", Vector3.new(0.08 * M, 0.34 * M, 0.10 * M),
		vid(-0.42, 1.24), LADER_MORK)

	del(modell, "Tränskrok", Vector3.new(0.14 * M, 0.04 * M, 0.04 * M),
		vid(0.42, 1.62), METALL, Enum.Material.Metal)
	del(modell, "Träns", Vector3.new(0.05 * M, 0.40 * M, 0.26 * M),
		vid(0.42, 1.40), LADER)
	del(modell, "Tyglar", Vector3.new(0.04 * M, 0.30 * M, 0.16 * M),
		vid(0.42, 1.16), LADER_MORK)

	--[[ NAMNSKYLTEN. Webbens sadelkammare har den på bygeln — "Namnskyltarna
		sitter på byglarna" — och här är den prompten. Hästens namn är ett
		EGENNAMN och skickas som argument, inte som översatt text. ]]
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TackPrompt"
	prompt.ActionText = "Ta sadel och träns"
	prompt:SetAttribute("SprakNyckel", "tack.ta_utrustning")
	prompt.ObjectText = namn .. "s sadel och träns"
	prompt:SetAttribute("SprakObjekt", "tack.utrustning_for")
	prompt:SetAttribute("SprakArg", namn)
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = sadel

	prompt.Triggered:Connect(function(spelare)
		TackForradService.tag(spelare, hastId, namn)
	end)

	modell.PrimaryPart = sadel
	modell.Parent = foralder
	return modell
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

function TackForradService.start(ta: ((Player, string, string?) -> (boolean, string?))?)
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
