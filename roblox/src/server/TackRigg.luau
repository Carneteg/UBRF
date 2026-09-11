--!strict
--[[
	UTRUSTNINGEN SOM FYSISKA DELAR — sadel, underlägg, träns och tyglar.

	Blockerare 5 i #162. Före den här modulen betydde "sadlad" exakt två
	booleans i en Lua-tabell: `state.gjorda["iordning"]["utr:2"] = true`.
	Ingen del skapades, inget attribut sattes på hästen, och
	uppsittningsgrinden kunde inte pröva något annat än att booleanen fanns.
	En häst som aldrig sett en sadel satt man upp på precis som en sadlad.

	GEOMETRIN ÄR PROTOTYP, OCH DET ÄR MEDVETET. Lådor i rätt storlek på rätt
	ställe, i läderfärg. `HORSE_VISUAL_QUALITY_GATE` byter ut hästen och
	utrustningen tillsammans; att göra vacker sadel åt en låd-häst vore att
	polera fel sak. Det som MÅSTE vara rätt nu är läget och fästet.

	MODULEN VET INGENTING OM HÄSTENS MODELLSTRUKTUR. Den frågar
	`RigAdapter.tackfaste(rig, "sadel")` efter en anatomisk plats och
	svetsar i den punktens VÄRDDEL. Därför följer tränset huvudet när
	hästen sänker det, och därför fungerar hela filen oförändrad den dag
	riggen byts mot ett riktigt nät: den nya riggen behöver bara bära samma
	fyra fästpunkter på rätt kroppsdelar.

	INGEN DEL KOLLIDERAR. Utrustning ska inte kunna knuffa hästen, fastna i
	en boxdörr eller ändra hennes kollisionshölje — lokomotionen är låst och
	får inte påverkas av att hon blir sadlad.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RigAdapter = require(ReplicatedStorage.HorseCore.RigAdapter)
local Types = require(ReplicatedStorage.HorseCore.Types)

local TackRigg = {}

local M = 3   -- studs per meter, som BuildKit.M

local LADER      = Color3.fromRGB(96, 61, 36)
local LADER_MORK = Color3.fromRGB(64, 41, 25)
local FILT       = Color3.fromRGB(226, 222, 212)
local METALL     = Color3.fromRGB(176, 178, 182)

--[[ Varje del bär vem den tillhör. Attributen är den fysiska världens
	egen sanning: `TackService` läser DEM, inte en tabell vid sidan av. ]]
export type Tackdel = {
	typ: string,      -- "underlagg" | "sadel" | "trans" | "tygel"
	hastId: string,   -- vilken häst utrustningen tillhör
}

local function del(foralder: Instance, namn: string, storlek: Vector3,
	cf: CFrame, farg: Color3, material: Enum.Material?): BasePart
	local p = Instance.new("Part")
	p.Name = namn
	p.Size = storlek
	p.CFrame = cf
	p.Color = farg
	p.Material = material or Enum.Material.Leather
	p.Anchored = false
	--[[ Utrustning kolliderar ALDRIG. Se filhuvudet. ]]
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = foralder
	return p
end

local function svets(a: BasePart, b: BasePart, namn: string)
	local w = Instance.new("WeldConstraint")
	w.Name = namn
	w.Part0 = a
	w.Part1 = b
	w.Parent = b
end

--[[ Mappen som håller en hästs utrustning. En per häst, skapad först när
	något faktiskt sätts på — en tom mapp är inte ett tillstånd. ]]
function TackRigg.mapp(modell: Model, skapa: boolean?): Folder?
	local f = modell:FindFirstChild("Tack")
	if f and f:IsA("Folder") then return f end
	if not skapa then return nil end
	local ny = Instance.new("Folder")
	ny.Name = "Tack"
	ny.Parent = modell
	return ny
end

--[[ Hittar en påsatt del av en viss typ. Läser VÄRLDEN. ]]
function TackRigg.hittaDel(modell: Model, typ: string): BasePart?
	local f = TackRigg.mapp(modell)
	if not f then return nil end
	for _, d in ipairs(f:GetChildren()) do
		if d:IsA("BasePart") and d:GetAttribute("UBRFTack") == typ then
			return d
		end
	end
	return nil
end

--[[ ══ BYGGARNA ══════════════════════════════════════════════════════

	Var och en tar riggen, hittar sin anatomiska punkt och svetsar i den
	punktens värddel. Svarar nil när punkten saknas — en rigg utan
	huvudpunkt ska ge ett tydligt nej. ]]

local function fastOch(rig: Types.Rig, plats: string): (Attachment?, BasePart?)
	local a = RigAdapter.tackfaste(rig, plats)
	if not a then return nil, nil end
	local vard = a.Parent
	if not (vard and vard:IsA("BasePart")) then return nil, nil end
	return a, vard
end

--[[ UNDERLÄGGET ligger under sadeln, högt på manken. Egen del därför att
	kanon har det som ett eget moment: "Lägg underlägget högt på manken
	och skjut det bakåt i hårets riktning." ]]
function TackRigg.byggUnderlagg(modell: Model, rig: Types.Rig, hastId: string): BasePart?
	local a, vard = fastOch(rig, "sadel")
	if not (a and vard) then return nil end
	local f = TackRigg.mapp(modell, true) :: Folder
	local p = del(f, "Underlägg",
		Vector3.new(0.56 * M, 0.03 * M, 0.66 * M),
		a.WorldCFrame * CFrame.new(0, 0.015 * M, 0),
		FILT, Enum.Material.Fabric)
	p:SetAttribute("UBRFTack", "underlagg")
	p:SetAttribute("ForHast", hastId)
	svets(vard, p, "TackWeld")
	return p
end

--[[ SADELN sitter ovanpå underlägget, bakom bogbladet. Sitsen, de två
	valven och bommen som håller manken fri. ]]
function TackRigg.byggSadel(modell: Model, rig: Types.Rig, hastId: string): BasePart?
	local a, vard = fastOch(rig, "sadel")
	if not (a and vard) then return nil end
	local f = TackRigg.mapp(modell, true) :: Folder
	local bas = a.WorldCFrame * CFrame.new(0, 0.05 * M, 0)
	local sits = del(f, "Sadel",
		Vector3.new(0.44 * M, 0.07 * M, 0.52 * M), bas, LADER)
	sits:SetAttribute("UBRFTack", "sadel")
	sits:SetAttribute("ForHast", hastId)
	svets(vard, sits, "TackWeld")
	--[[ Framvalv och bakvalv: det som gör att en låda läses som en sadel. ]]
	del(f, "Sadelns framvalv", Vector3.new(0.40 * M, 0.10 * M, 0.07 * M),
		bas * CFrame.new(0, 0.04 * M, -0.24 * M), LADER_MORK)
	del(f, "Sadelns bakvalv", Vector3.new(0.42 * M, 0.08 * M, 0.07 * M),
		bas * CFrame.new(0, 0.03 * M, 0.24 * M), LADER_MORK)
	for _, d in ipairs(f:GetChildren()) do
		if d:IsA("BasePart") and d.Name:sub(1, 8) == "Sadelns " and not d:FindFirstChild("TackWeld") then
			svets(sits, d, "TackWeld")
		end
	end
	--[[ GJORDEN runt bålen, och stigbyglarna i sadeln. Båda hänger i
		sadeln och inte i hästen: tas sadeln av följer de med. ]]
	del(f, "Sadelns gjord", Vector3.new(0.62 * M, 0.06 * M, 0.10 * M),
		bas * CFrame.new(0, -0.30 * M, 0.02 * M), LADER_MORK)
	for _, sida in ipairs({ -1, 1 }) do
		local bygel = del(f, "Stigbygel", Vector3.new(0.04 * M, 0.12 * M, 0.04 * M),
			bas * CFrame.new(sida * 0.24 * M, -0.20 * M, 0), METALL, Enum.Material.Metal)
		svets(sits, bygel, "TackWeld")
	end
	for _, d in ipairs(f:GetChildren()) do
		if d:IsA("BasePart") and d ~= sits and not d:FindFirstChildOfClass("WeldConstraint") then
			svets(sits, d, "TackWeld")
		end
	end
	return sits
end

--[[ TRÄNSET sitter på HUVUDET, inte på bålen. Nackstycke, pannband och
	nosgrimma — nog för att läsas som ett träns på håll. ]]
function TackRigg.byggTrans(modell: Model, rig: Types.Rig, hastId: string): BasePart?
	local a, vard = fastOch(rig, "trans")
	if not (a and vard) then return nil end
	local f = TackRigg.mapp(modell, true) :: Folder
	local bas = a.WorldCFrame
	local huvudlag = del(f, "Träns",
		Vector3.new(0.30 * M, 0.04 * M, 0.05 * M), bas, LADER)
	huvudlag:SetAttribute("UBRFTack", "trans")
	huvudlag:SetAttribute("ForHast", hastId)
	svets(vard, huvudlag, "TackWeld")
	--[[ Kindstycken längs käkarna och nosgrimman runt nosen. ]]
	for _, sida in ipairs({ -1, 1 }) do
		local kind = del(f, "Tränsets kindstycke",
			Vector3.new(0.03 * M, 0.05 * M, 0.22 * M),
			bas * CFrame.new(sida * 0.15 * M, -0.03 * M, -0.11 * M), LADER)
		svets(huvudlag, kind, "TackWeld")
	end
	local nos = del(f, "Tränsets nosgrimma",
		Vector3.new(0.32 * M, 0.04 * M, 0.04 * M),
		bas * CFrame.new(0, -0.06 * M, -0.19 * M), LADER)
	svets(huvudlag, nos, "TackWeld")
	return huvudlag
end

--[[ TYGLARNA går från bettet i mungiporna bakåt över halsen. De hänger i
	HUVUDET, så de följer med när hon sänker det. ]]
function TackRigg.byggTyglar(modell: Model, rig: Types.Rig, hastId: string): BasePart?
	local vansterA, vard = fastOch(rig, "tygelV")
	local hogerA = RigAdapter.tackfaste(rig, "tygelH")
	if not (vansterA and hogerA and vard) then return nil end
	local f = TackRigg.mapp(modell, true) :: Folder
	local forsta: BasePart? = nil
	for _, a in ipairs({ vansterA, hogerA }) do
		local tygel = del(f, "Tygel",
			Vector3.new(0.03 * M, 0.03 * M, 0.70 * M),
			a.WorldCFrame * CFrame.new(0, 0.04 * M, 0.36 * M), LADER_MORK)
		svets(vard, tygel, "TackWeld")
		if not forsta then
			forsta = tygel
			tygel:SetAttribute("UBRFTack", "tygel")
			tygel:SetAttribute("ForHast", hastId)
		end
	end
	return forsta
end

TackRigg.BYGGARE = {
	underlagg = TackRigg.byggUnderlagg,
	sadel = TackRigg.byggSadel,
	trans = TackRigg.byggTrans,
	tygel = TackRigg.byggTyglar,
}

--[[ Tar av en typ, med allt som hänger i den. Sadeln tar sina valv, sin
	gjord och sina stigbyglar med sig — de är svetsade i henne. ]]
function TackRigg.taAv(modell: Model, typ: string): boolean
	local f = TackRigg.mapp(modell)
	if not f then return false end
	local bar = TackRigg.hittaDel(modell, typ)
	if not bar then return false end
	--[[ Delar utan eget `UBRFTack` hör till den bärande delen de är
		svetsade i. De rivs med den. ]]
	local rivs = { bar }
	for _, d in ipairs(f:GetChildren()) do
		if d:IsA("BasePart") and d:GetAttribute("UBRFTack") == nil then
			local w = d:FindFirstChildOfClass("WeldConstraint")
			if w and w.Part0 == bar then table.insert(rivs, d) end
		end
	end
	for _, d in ipairs(rivs) do d:Destroy() end
	if #f:GetChildren() == 0 then f:Destroy() end
	return true
end

return TackRigg
