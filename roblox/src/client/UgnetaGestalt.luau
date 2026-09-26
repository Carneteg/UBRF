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
	"Dressyrlayout 20x60", via `Ridhusplats`). Läktarlärdomen (#114) var att rendering och logik inte
	får ha var sin uppfattning om var något står; att räkna om ridhusets
	origo här hade varit exakt det felet igen.

	[antagande] Att UBRF:s instruktör står just vid C är inte belagt i
	referensmaterialet — se motiveringen i src/larare.js. Ytan finns
	verifierat: den fysiska ridytan fortsätter 5,5 m bortom
	dressyrlayoutens C-linje, så hon står på golv som är mätt, inte på
	golv som är hittat på.
]]

local RidKanon = require(game:GetService("ReplicatedStorage").HorseCore.RidKanon)
local Ridhusplats = require(game:GetService("ReplicatedStorage").HorseCore.Ridhusplats)

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

--[[ VAR STÅR HON? Räknas ur de byggda delarna, genom `Ridhusplats`:

	  "Dressyrlayout 20x60"  ger A-kanten och längdaxeln,
	  "Ridbanan"             ger golvet och VILKET håll som är C (banan
	                         fortsätter bortom layoutens C-linje).

	Tecknet på längdaxeln är alltså ingen gissning om hur ridhuset råkar
	vara vridet i världen; det kommer ur geometrin själv. ]]
export type Plats = { pos: Vector3, motC: Vector3 }

function UgnetaGestalt.plats(ridhus: Instance?): Plats?
	--[[ #264 INFRA-PLATS1: platsen löses genom den gemensamma platsgrunden
		`Ridhusplats`, ur banan och dressyrlayouten via deras stabila
		`PlatsId`. Saknas eller tvetydigt underlag blir det ingen gestalt —
		ingen gissad reserv.

		REDOVISAD FLYTT (INFRA-PLATS1): förut räknades hon från den del som
		`FindFirstChild("Sarg syd")` råkade ge. Den sargen sågas av södra
		dörren i två bitar, och biten låg 24,6 studs vid sidan av banans
		mittlinje — riktningen blev ~14° diagonal, och hon hamnade ~6,7 m
		från mittlinjen och 0,49 m INNANFÖR layoutens C-linje. Nu står hon
		där kanonen och webben säger: mitt på (`P.u`) och `P.bortomC` meter
		bortom C, räknat från layoutens A-kant. ]]
	local rp = Ridhusplats.los(ridhus)
	if not rp then return nil end
	local motC = rp.motC                        -- från A mot C, i planet

	local P = RidKanon.UGNETA.PLATS
	--[[ Dressyrlayouten är förankrad i A och `P.langd` meter lång; hon står
	     `P.bortomC` meter bortom dess C-linje, på tvärsläget `P.u` av
	     `P.bredd`. Den fysiska ridytan fortsätter förbi C-linjen, vilket är
	     just varför punkten finns i huset — se modulhuvudet. ]]
	local fot = Ridhusplats.tillVarld(rp, Vector3.new((P.u - 0.5) * P.bredd, 0, P.langd + P.bortomC))
	--[[ Höjd: sandens överkant (`tillVarld` med h = 0), så hon står PÅ golvet. ]]
	return { pos = fot, motC = motC }
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
