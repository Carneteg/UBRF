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

--[[ ══ HON VÄNDER SIG MOT RYTTAREN (C2, #234 §4) ══════════════════════
	docs/INSTRUCTOR-GAZE-CONTRACT.md.

	EN lokal presentation: hela den synliga gestalten girar kring sin
	fotpunkt (`ankare`), bara runt den lodräta axeln. Varje dels läge räknas
	om från ankaret och delens LOKALA förskjutning varje gång — ingen
	stegvis transform, alltså ingen drift. Höjd, ankare, mått, färger och
	kollision är desamma som förut.

	MÅLET kommer från anroparen som en punkt i planet ({x, z} i studs):
	LektionController.steg får den som `pose` av init.client, räknad VARJE
	bildruta ur den ritt som just nu är bunden (`ride.rig.root`). Här finns
	ingen egen sökning efter spelare, hästar eller namn, och ingen sparad
	referens till en rigg — bara talen för bildrutan.

	GRÄNSERNA (spelantaganden, i meter; 1 m = 3 studs):
	  · NARA_M 1,5: närmare än så är riktningen obestämd — hon står kvar.
	  · LANGT_M = PLATS.langd + PLATS.bortomC + PLATS.bredd/2 (= 71,4 m ur
	    RidKanon): bortom det är ryttaren utanför banan hon undervisar på —
	    hon vänder långsamt tillbaka mot A (neutralt).
	  · Saknat eller ogiltigt mål: ingen vridning, hon står som hon står.
	  · Utjämning: exponentiell mot målet med tidskonstanten TAU_S 0,4 s,
	    högst VRID_MAX 90°/s. `dt` ≤ 0 eller ogiltigt vrider inte; längre
	    `dt` än MAX_DT 0,1 s räknas som 0,1 s, så ett hack blir aldrig ett
	    ryck. Skillnaden tas alltid den korta vägen runt (±π). ]]
local P0 = RidKanon.UGNETA.PLATS
local NARA_M = 1.5
local LANGT_M = P0.langd + P0.bortomC + P0.bredd / 2
local TAU_S = 0.4
local VRID_MAX = math.rad(90)
local MAX_DT = 0.1
UgnetaGestalt.GRANSER = table.freeze({ NARA_M = NARA_M, LANGT_M = LANGT_M, TAU_S = TAU_S,
	VRID_MAX = VRID_MAX, MAX_DT = MAX_DT })

local ankare: Vector3? = nil
local delar: { { del: BasePart, lokal: Vector3 } } = {}
local yaw = 0
local neutralYaw = 0

local function andlig(x: any): boolean
	return type(x) == "number" and x == x and x ~= math.huge and x ~= -math.huge
end

--[[ Framåt för en girning: lokal +Z blir (sin θ, 0, cos θ), samma som
	`CFrame.Angles(0, θ, 0)` gör med den. ]]
local function applicera()
	local a = ankare
	if not a then return end
	local cs, sn = math.cos(yaw), math.sin(yaw)
	for _, d in delar do
		local l = d.lokal
		-- höger = (cos θ, 0, −sin θ), fram = (sin θ, 0, cos θ)
		local pos = Vector3.new(a.X + l.X * cs + l.Z * sn, a.Y + l.Y, a.Z - l.X * sn + l.Z * cs)
		d.del.CFrame = CFrame.new(pos) * CFrame.Angles(0, yaw, 0)
	end
end

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
	--[[ C2: den gamla gestalten rivs FÖRST, även när den nya inte kan
	     ställas ut — annars kunde en tidigare ritts gestalt (och dess
	     riktning) bli kvar efter en ny start utan ridhus. ]]
	UgnetaGestalt.dolj()
	local plats = UgnetaGestalt.plats(ridhus)
	if not plats then return nil end
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

	local kavaj = del(m, "Kavaj", Vector3.new(studs(0.40), studs(0.66), studs(0.36)),
		vid(0.55), KAVAJ)
	local ansikte = del(m, "Ansikte", Vector3.new(studs(0.26), studs(0.26), studs(0.26)),
		vid(0.99), ANSIKTE)
	--[[ GRÅTT HÅR OCH GLASÖGON är hela igenkänningen. Utan dem är hon en
	     figur i kavaj, vilket var precis vad blockern gällde. ]]
	local har = del(m, "Grått hår", Vector3.new(studs(0.30), studs(0.23), studs(0.30)),
		vid(1.045), HAR)
	local glas = del(m, "Glasögon", Vector3.new(studs(0.24), studs(0.05), studs(0.03)),
		vid(0.985) + fram * studs(0.12), GLAS)

	m.PrimaryPart = m:FindFirstChild("Kavaj") :: BasePart?
	modell = m
	--[[ C2: ankare och LOKALA förskjutningar (x höger, y upp, z fram), så
	     att alla fyra delar girar tillsammans kring fotpunkten. Samma lägen
	     som ovan; glasögonen ligger 0,12 m fram. Neutralt = mot A. ]]
	ankare = p
	neutralYaw = if andlig(fram.X) and andlig(fram.Z) and (fram.X ~= 0 or fram.Z ~= 0)
		then math.atan2(fram.X, fram.Z) else 0
	yaw = neutralYaw
	delar = {
		{ del = kavaj, lokal = Vector3.new(0, studs(0.55), 0) },
		{ del = ansikte, lokal = Vector3.new(0, studs(0.99), 0) },
		{ del = har, lokal = Vector3.new(0, studs(1.045), 0) },
		{ del = glas, lokal = Vector3.new(0, studs(0.985), studs(0.12)) },
	}
	applicera()
	return m
end

function UgnetaGestalt.dolj()
	if modell then
		modell:Destroy()
		modell = nil
	end
	--[[ C2: rivningen släpper allt: inga referenser, ingen vridning kvar. ]]
	ankare = nil
	delar = {}
	yaw, neutralYaw = 0, 0
end

--[[ ETT STEG AV BLICKEN. `mal` = { x, z } (studs) för den just nu bundna
	ritten, eller nil. Läser bara talen; flyttar aldrig spelaren, hästen,
	kameran eller något på servern. Utan gestalt gör den ingenting. ]]
function UgnetaGestalt.steg(dt: any, mal: any)
	local m = modell
	if not m then return end
	if m.Parent == nil then
		-- Förstörd utifrån: släpp referenserna, vrid ingenting.
		UgnetaGestalt.dolj()
		return
	end
	local a = ankare
	if not a or not andlig(dt) or dt <= 0 then return end
	local h = math.min(dt, MAX_DT)
	if type(mal) ~= "table" or not andlig(mal.x) or not andlig(mal.z) then return end
	local dx, dz = mal.x - a.X, mal.z - a.Z
	local avstand = math.sqrt(dx * dx + dz * dz) / M
	if not andlig(avstand) or avstand < NARA_M then return end
	local malYaw = if avstand <= LANGT_M then math.atan2(dx, dz) else neutralYaw
	local skillnad = ((malYaw - yaw + math.pi) % (2 * math.pi)) - math.pi
	local vrid = skillnad * (1 - math.exp(-h / TAU_S))
	vrid = math.clamp(vrid, -VRID_MAX * h, VRID_MAX * h)
	if math.abs(vrid) < 1e-5 then return end
	yaw = ((yaw + vrid + math.pi) % (2 * math.pi)) - math.pi
	applicera()
end

--[[ Provets fönster in: riktningen och ankaret, bara läsning. ]]
function UgnetaGestalt._blick(): { [string]: any }
	return { yaw = yaw, neutral = neutralYaw, ankare = ankare, delar = #delar, modell = modell }
end

function UgnetaGestalt.finns(): boolean
	return modell ~= nil
end

return UgnetaGestalt
