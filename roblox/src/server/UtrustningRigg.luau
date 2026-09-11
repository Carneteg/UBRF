--!strict
--[[
	SADELN OCH TRÄNSET SOM FYSISKA SAKER.

	Före den här filen var utrustningen ett tillståndsbyte: spelaren stod
	vid hästen, tryckte på ett HUD-steg, och sadeln fanns. Ingen sadel hade
	hämtats, ingen hade rörts, och steget gick lika bra att kvittera av
	någon som aldrig sett en sadel. Det är den blockerande produktluckan
	16:21: ansvaret kring hästen ska VARA gameplay, inte dekoration.

	VAR HÄNGER DE? PÅ HÄSTENS EGEN BOXFRONT, och det är läst ur källan:

	    references/buildings/stall/KORT.md § Boxarna från gången
	    "På fronterna hänger sadlar med underlag, täcken, grimmor, träns
	     och benskydd — mycket saker, tätt."  [ej byggt i spelet ännu]

	Ordern pekade mot sadelkammaren. Sadelkammarens egen bild
	(`stall-inne-03-sadelkammaren.jpg`) visar uttryckligen INGA sadelbockar
	— bara säkerhetsvästar på krokrader och en hylla med ridstövlar — och
	`docs/F02-B-INREDNINGSMATRIS.md` har redan fällt det som
	`REFERENCE GAP`: "sadlar, träns och övrig utrustning ... syns inte i
	bilden och byggs inte". Att ställa sadelbockar där hade varit att hitta
	på en UBRF-detalj för att fylla ett hål. Boxfronten är den enda
	VERIFIERADE platsen, och den är därför den som byggs. Avvikelsen är
	rapporterad, inte tyst.

	FORMEN ÄR SPELABSTRAKTION, precis som hästriggen: enkla lådor med rätt
	läge, rätt namn och rätt attribut. Filmen mäter ingen sadel. Ett riktigt
	nät kan bytas in utan att någon annan rad här ändras.

	Filen bygger INGEN miljö. Boxfronterna, väggarna och gången är Replits
	yta; det här är gameplay-innehåll som ställs relativt anläggningen på
	samma sätt som hästarna, och `roblox/buildings/` rörs inte.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UtrustningRigg = {}

local TAG = "Utrustning"
local M = 3                     -- studs per meter, som BuildKit.M

--[[ Höjd över golvet till sakens mitt. En sadel på en sadelhängare sitter i
	midjehöjd och tränset ovanför den; båda är SPELABSTRAKTION, valda för
	att synas och gå att sikta på från gången. ]]
local H_SADEL, H_TRANS = 1.15, 1.72

local MATT = {
	sadel = Vector3.new(0.46, 0.34, 0.56),
	trans = Vector3.new(0.10, 0.46, 0.24),
}
local FARG = {
	sadel = Color3.fromRGB(104, 62, 38),
	trans = Color3.fromRGB(58, 38, 26),
}

local function delad(namn: string)
	local ok, m = pcall(function()
		if namn == "Stallet" then return require(ReplicatedStorage.Stallet) end
		return require(ReplicatedStorage.UBRFSpelData)
	end)
	if not ok then return nil end
	return m
end

local function anlaggningsbas(): CFrame?
	local folder = workspace:FindFirstChild("Anläggning")
	local komplex = folder and folder:FindFirstChild("UBRF")
	if not komplex or not (komplex :: any).PrimaryPart then return nil end
	return ((komplex :: any).PrimaryPart :: BasePart).CFrame
end

local function mapp(): Folder
	local f = workspace:FindFirstChild("Utrustning")
	if f and f:IsA("Folder") then return f end
	local ny = Instance.new("Folder")
	ny.Name = "Utrustning"
	ny.Parent = workspace
	return ny
end

--[[ En sak på en boxfront. `sort` är "sadel" eller "trans". ]]
function UtrustningRigg.bygg(hastId: string, sort: string, bas: CFrame): Model?
	local Stallet = delad("Stallet")
	if not Stallet then return nil end
	local plats = (Stallet :: any).utrustningsplats(hastId, sort)
	if not plats then return nil end

	local hojd = if sort == "sadel" then H_SADEL else H_TRANS
	--[[ Samma teckenbyte som hästriggen: site-y är norr på kartan, världen
		är en högerhänt avbild där norr är −Z. Härledningen står i
		`BuildKit.tomtlage`; tecknet står här med samma namn att söka på. ]]
	local cf = bas * CFrame.new(plats.varld.x * M, hojd * M, -plats.varld.y * M)

	local modell = Instance.new("Model")
	--[[ Instansnamn är ASCII och för utvecklare; spelaren läser aldrig
		dem. Prompttexten kommer ur språkkanonen (`utr.sadel` / `utr.trans`). ]]
	modell.Name = (if sort == "sadel" then "Sadel" else "Trans") .. "_" .. hastId

	local p = Instance.new("Part")
	p.Name = if sort == "sadel" then "Sadel" else "Trans"
	p.Size = MATT[sort] * M
	p.CFrame = cf
	p.Color = FARG[sort]
	p.Material = Enum.Material.Fabric
	p.Anchored = true
	--[[ Den hänger på fronten och ska inte kunna stänga gången. Spelaren
		går förbi den, inte in i den. ]]
	p.CanCollide = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = modell
	modell.PrimaryPart = p

	if sort == "sadel" then
		--[[ Underlägget hör till sadeln — kanonens första sadelfas lägger
			det högt på manken innan sadeln kommer på. Att det hänger med
			sadeln är läst ur samma källrad: "sadlar med underlag". ]]
		local u = Instance.new("Part")
		u.Name = "Underlagg"
		u.Size = Vector3.new(0.52, 0.40, 0.06) * M
		u.CFrame = cf * CFrame.new(0, -0.06 * M, -0.32 * M)
		u.Color = Color3.fromRGB(236, 233, 224)
		u.Material = Enum.Material.Fabric
		u.Anchored = true
		u.CanCollide = false
		u.Parent = modell
	end

	modell:SetAttribute("HastId", hastId)
	modell:SetAttribute("UtrSort", sort)
	modell.Parent = mapp()
	--[[ Taggen SIST, av samma skäl som i hästriggen: en halvbyggd modell
		ska inte kunna plockas upp. ]]
	CollectionService:AddTag(modell, TAG)
	return modell
end

--[[ Hela stallets utrustning. Returnerar antalet byggda saker. ]]
function UtrustningRigg.start(): number
	local Stallet = delad("Stallet")
	local Data = delad("UBRFSpelData")
	if not Stallet or not Data then
		warn("[Utrustning] Stallet eller speldatan saknas — ingen utrustning byggd.")
		return 0
	end
	local bas = anlaggningsbas()
	if not bas then
		warn("[Utrustning] anläggningen är inte byggd — ingen utrustning byggd.")
		return 0
	end

	local ids = {}
	for id in pairs((Data :: any).hastar or {}) do table.insert(ids, id) end
	table.sort(ids)

	local byggda = 0
	for _, id in ipairs(ids) do
		for _, sort in ipairs({ "sadel", "trans" }) do
			if UtrustningRigg.bygg(id, sort, bas) then byggda += 1 end
		end
	end
	print(("[Utrustning] %d saker hänger på boxfronterna"):format(byggda))
	return byggda
end

--[[ Saken som hör till den här hästen, eller nil. Slås upp på attributen och
	inte på namnet: namnet är för människor. ]]
function UtrustningRigg.saken(hastId: string, sort: string): Model?
	for _, m in CollectionService:GetTagged(TAG) do
		if m:IsA("Model") and m:GetAttribute("HastId") == hastId
			and m:GetAttribute("UtrSort") == sort then
			return m
		end
	end
	return nil
end

UtrustningRigg.TAG = TAG

return UtrustningRigg
