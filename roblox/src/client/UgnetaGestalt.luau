--!strict
--[[
	UGNETA SOM GESTALT — hon står vid sargen, inte bara i ett HUD-kort.

	Blocker 2 i senior review av 09e07da: webben hade fått en igenkännbar
	Ugneta (grått hår, glasögon) men Roblox hade bara lärar-UX:en. Roblox
	är primär spelplattform, och den aktiva produktgaten säger att hon
	ska vara FYSISKT närvarande under lektionen.

	Enkelt och i husets stil: samma primitiver som resten av anläggningen
	bygger med (Part, SmoothPlastic, meter × 3 studs). Ingen ny art
	direction, ingen karaktärsrigg, inget hopp i detaljnivå.

	PLATSEN LÄSES UR DET BYGGDA, INTE UR EN ANDRA MODELL. Punkten kommer
	ur RidKanon.UGNETA.PLATS — samma tal som webbens `ugnetaPlats()` — och
	löses upp mot de delar som faktiskt står i workspace ("Ridbanan" och
	"Sarg syd"). Läktarlärdomen (#114) var att rendering och logik inte
	får ha var sin uppfattning om var något står; att räkna om ridhusets
	origo här hade varit exakt det felet igen.

	[antagande] Att UBRF:s instruktör står just vid C är inte belagt i
	referensmaterialet — se motiveringen i src/larare.js. Ytan finns
	verifierat: den fysiska ridytan fortsätter 5,5 m bortom
	dressyrlayoutens C-linje, så hon står på golv som är mätt, inte på
	golv som är hittat på.
]]

local RidKanon = require(game:GetService("ReplicatedStorage").HorseCore.RidKanon)

local UgnetaGestalt = {}

local M = 3                              -- studs per meter, som BuildKit
local function studs(m: number): number return m * M end

--[[ Färgerna är webbfigurens, så hon är samma person på båda ytorna. ]]
local KAVAJ   = Color3.fromRGB(75, 90, 82)
local ANSIKTE = Color3.fromRGB(226, 192, 162)
local HAR     = Color3.fromRGB(201, 205, 210)   -- grått
local GLAS    = Color3.fromRGB(43, 46, 52)

local modell: Model? = nil

local function del(mor: Model, namn: string, storlek: Vector3, pos: Vector3,
	farg: Color3): Part
	local p = Instance.new("Part")
	p.Name = namn
	p.Anchored = true
	p.CanCollide = false                  -- hon ska aldrig stoppa en häst
	p.Size = storlek
	p.CFrame = CFrame.new(pos)
	p.Color = farg
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = mor
	return p
end

--[[ VAR STÅR HON? Räknas ur de byggda delarna:

	  "Ridbanan"  ger banans mitt och mått,
	  "Sarg syd"  ger A-änden, och därmed VILKET håll som är C.

	Utan den andra delen hade tecknet på längdaxeln varit en gissning om
	hur ridhuset råkar vara vridet i världen. Nu kommer riktningen ur
	geometrin själv. ]]
export type Plats = { pos: Vector3, motC: Vector3 }

function UgnetaGestalt.plats(ridhus: Instance?): Plats?
	if not ridhus then return nil end
	--[[ Grunt uppslag: BuildKit.box hänger delarna direkt under byggnadens
	     Model, så det är där de står. En rekursiv sökning hade letat efter
	     en struktur produktionen inte har. ]]
	local bana = ridhus:FindFirstChild("Ridbanan")
	local syd = ridhus:FindFirstChild("Sarg syd")
	if not bana or not syd then return nil end
	local b = bana :: BasePart
	local a = syd :: BasePart
	local langs = b.Position - a.Position
	if langs.Magnitude < 1e-3 then return nil end
	local motC = langs.Unit                     -- från A mot C

	local P = RidKanon.UGNETA.PLATS
	--[[ Dressyrlayouten är förankrad i A och `P.langd` meter lång; hon står
	     `P.bortomC` meter bortom dess C-linje. Den fysiska ridytan
	     fortsätter förbi den linjen, vilket är just varför punkten finns
	     i huset — se modulhuvudet. ]]
	local fot = a.Position + motC * studs(P.langd + P.bortomC)
	--[[ Höjd: sandens överkant, så hon står PÅ golvet i stället för i det. ]]
	local golv = b.Position.Y + b.Size.Y / 2
	return { pos = Vector3.new(fot.X, golv, fot.Z), motC = motC }
end

--[[ Bygger gestalten. Måtten är webbfigurens (src/scen3d.js: kavaj som
	klot 0,20 × 0,33 × 0,18 m, ansikte r 0,132, hår strax ovanför,
	glasögonbågar fram) omsatta till lådor och klot i husets stil. ]]
function UgnetaGestalt.visa(ridhus: Instance?): Model?
	local plats = UgnetaGestalt.plats(ridhus)
	if not plats then return nil end
	UgnetaGestalt.dolj()
	local m = Instance.new("Model")
	m.Name = "Ugneta"
	m:SetAttribute("Roll", "ridinstruktor")
	m:SetAttribute("Fidelity", "ANTAGANDE")
	m.Parent = workspace

	local p = plats.pos
	--[[ Hon tittar mot A, dit ekipaget rider — alltså är ansiktets
	     framsida -motC. Riktningen räknas ur geometrin, inte ur en
	     CFrames LookVector: vektormatematiken är densamma i Studio och i
	     bänken, och platsen är just det ett prov ska kunna mäta. ]]
	local fram = -plats.motC
	local function vid(dy: number) return Vector3.new(p.X, p.Y + studs(dy), p.Z) end

	del(m, "Kavaj", Vector3.new(studs(0.40), studs(0.66), studs(0.36)),
		vid(0.55), KAVAJ)
	del(m, "Ansikte", Vector3.new(studs(0.26), studs(0.26), studs(0.26)),
		vid(0.99), ANSIKTE)
	--[[ GRÅTT HÅR OCH GLASÖGON är hela igenkänningen. Utan dem är hon en
	     figur i kavaj, vilket var precis vad blockern gällde. ]]
	del(m, "Grått hår", Vector3.new(studs(0.30), studs(0.23), studs(0.30)),
		vid(1.045), HAR)
	del(m, "Glasögon", Vector3.new(studs(0.24), studs(0.05), studs(0.03)),
		vid(0.985) + fram * studs(0.12), GLAS)

	m.PrimaryPart = m:FindFirstChild("Kavaj") :: BasePart?
	modell = m
	return m
end

function UgnetaGestalt.dolj()
	if modell then
		modell:Destroy()
		modell = nil
	end
end

function UgnetaGestalt.finns(): boolean
	return modell ~= nil
end

return UgnetaGestalt
