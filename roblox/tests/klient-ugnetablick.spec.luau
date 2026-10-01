--!nostrict
--[[
	UGNETA VÄNDER SIG MOT RYTTAREN — livscykeln (C2, #234 §4).
	docs/INSTRUCTOR-GAZE-CONTRACT.md.

	KLIENT-bänken. Kedjan drivs genom `LektionController`:
	- `start(ridhus, marke)` bygger gestalten, som `init.client.mount` gör;
	- `steg(dt, tm, pose)` får den pose `init.client` räknar ur den bundna
	  ritten (`poseAv(ride.rig)` = { x, z, yaw } ur rotens läge);
	- `avbryt` river, som `init.client.dismount` gör.

	Ommontering, ersättning med samma HorseId och återförening efter ett
	nekat nej går alla `dismount` → `mount`, alltså `avbryt` → `start`, och
	provas så.

	SKRIVEN FÖR SENARE KÖRNING (bygg nu, testa sist). Inte körd.
	BÄNKANTAGANDEN:
	- ridhuset är syntetiskt (samma byggare som ridhusplats.spec);
	- hela `init.client`-kedjan med en byggd rigg är PLANERAD, inte skriven;
	- `VoltLektionController.valj` går i bänken utan server (dess sync
	  fångas av `pcall`), och `tarOver()` blir sann av valet.
]]
local fel, total = 0, 0
local function prova(vad, ok, detalj)
	total += 1
	if ok then
		print(("  OK   %s%s"):format(vad, if detalj then "  " .. tostring(detalj) else ""))
	else
		fel += 1
		print(("  FEL  %s%s"):format(vad, if detalj then "  " .. tostring(detalj) else ""))
	end
end
local LC, VC, G = LektionController, VoltLektionController, UgnetaGestalt
local M = 3
Sprak.satLocale("sv-se")

local function syntetisk(pos, gir)
	local s = Instance.new("Model")
	s.Name = "UBRF"
	local bas = CFrame.new(pos) * CFrame.Angles(0, gir, 0)
	local lb = Instance.new("Part")
	lb.Name = "Ridbanan"
	lb.Size = Vector3.new(60, 0.18, 196.59)
	lb.CFrame = bas * CFrame.new(0, 0.09, -8.295)
	lb:SetAttribute("PlatsId", "ridhus_bana")
	lb.Parent = s
	local ll = Instance.new("Part")
	ll.Name = "Dressyrlayout 20x60"
	ll.Size = Vector3.new(60, 0.06, 180)
	ll.CFrame = bas * CFrame.new(0, 0.12, 0)
	ll:SetAttribute("PlatsId", "ridhus_dressyr")
	ll:SetAttribute("Forankring", "A")
	ll.Parent = s
	return s
end
local HUS = syntetisk(Vector3.new(40, 0, -20), math.rad(12))
local function kort(a) return ((a + math.pi) % (2 * math.pi)) - math.pi end
local function modeller()
	local n = 0
	for _, b in workspace:GetChildren() do if b.Name == "Ugneta" then n += 1 end end
	return n
end
--[[ En hästrot, som `ride.rig.root`; posen räknas som `poseAv` gör. ]]
local rot = Instance.new("Part")
rot.Name = "HastRot"
rot.Anchored = true
rot.Parent = workspace
local function placera(p) rot.CFrame = CFrame.new(p); rot.Position = p end
local function pose()
	local p = rot.CFrame.Position
	return { x = p.X, z = p.Z, yaw = select(2, rot.CFrame:ToOrientation()) }
end
local TM = { uppsutten = true }

local plats = G.plats(HUS)
prova("KONTROLL: platsen löses i det syntetiska huset", plats ~= nil)
local sida = Vector3.new(plats.motC.Z, 0, -plats.motC.X)
local RYTTARE = plats.pos + sida * (8 * M) - plats.motC * (6 * M)
local malYaw = math.atan2(RYTTARE.X - plats.pos.X, RYTTARE.Z - plats.pos.Z)

local function rid(sek)
	for _ = 1, math.floor(sek * 60) do LC.steg(1 / 60, TM, pose()) end
end

print("\n── 1. Det gamla passet (ingen lektionsväljare) ──")
do
	LC.start(HUS, "blick-1")
	prova("start bygger EN gestalt", G.finns() and modeller() == 1)
	prova("KONTROLL: det gamla passet — ingen lektion tar över", VC.tarOver() == false)
	placera(RYTTARE)
	rid(8)
	prova("hon vänder sig mot den bundna rittens rot", math.abs(kort(G._blick().yaw - malYaw)) < 1e-3,
		G._blick().yaw)
end

print("\n── 2. Alla tio ridlektioner (VoltLektionController tar över) ──")
do
	for _, typ in { "volt", "halt", "overgang", "serpentin", "tempo", "vag_mitt", "vag_diag", "halvvolt",
		"galopp", "markbom" } do
		LC.avbryt()
		LC.start(HUS, "blick-" .. typ)
		VC.valj(typ)
		local fore = G._blick().yaw
		placera(RYTTARE)
		rid(8)
		prova(typ .. ": lektionen tar över, och hon vänder sig ändå",
			VC.tarOver() == true and math.abs(kort(G._blick().yaw - malYaw)) < 1e-3
			and math.abs(kort(fore - malYaw)) > 1e-2)
	end
end

print("\n── 3. Rivning, ommontering och en gammal pose ──")
do
	LC.avbryt()
	prova("avbryt river gestalten", not G.finns() and modeller() == 0 and G._blick().ankare == nil)
	local gammal = pose()
	LC.steg(1 / 60, TM, gammal)
	prova("en gammal pose efter rivningen gör ingenting", not G.finns() and modeller() == 0)
	-- Ny ritt (ommontering, samma HorseId-ersättning eller återförening): avbryt → start.
	LC.start(HUS, "blick-ny")
	prova("den nya ritten får en NY gestalt, neutralt vänd", G.finns() and modeller() == 1
		and G._blick().yaw == G._blick().neutral)
	local andra = plats.pos - sida * (9 * M) - plats.motC * (4 * M)
	placera(andra)
	rid(8)
	local nyYaw = math.atan2(andra.X - plats.pos.X, andra.Z - plats.pos.Z)
	prova("och följer bara den nya rittens pose", math.abs(kort(G._blick().yaw - nyYaw)) < 1e-3)
	LC.start(HUS, "blick-ny")
	LC.start(HUS, "blick-ny")
	prova("upprepad start ger fortfarande EN modell", modeller() == 1, modeller())
	LC.steg(1 / 60, TM, nil)
	prova("ingen pose (ingen bunden rigg den bildrutan): ingen vridning, inget fel", G.finns())
	LC.avbryt()
end

print("\n── 4. Utan ridhus: lektionen går, ingen gestalt ──")
do
	LC.start(nil, "blick-utan")
	prova("utan ridhus byggs ingen gestalt", not G.finns() and modeller() == 0)
	prova("men lektionspanelen är installerad som förut", VC.panel() ~= nil)
	placera(RYTTARE)
	rid(1)
	prova("och stegen med pose gör ingenting", not G.finns())
	LC.avbryt()
end

print("\n── 5. Presentationen läser bara ──")
do
	LC.start(HUS, "blick-las")
	placera(RYTTARE)
	local rotFore = rot.CFrame
	local kamera = workspace.CurrentCamera
	local kamFore = kamera and kamera.CFrame
	local karaktar = game:GetService("Players").LocalPlayer.Character
	local karFore = karaktar and karaktar:FindFirstChild("HumanoidRootPart")
		and karaktar.HumanoidRootPart.CFrame
	rid(4)
	prova("hästens rot är orörd", rot.CFrame == rotFore)
	prova("kameran är orörd", kamera == nil or kamera.CFrame == kamFore)
	prova("spelarens karaktär är orörd", karFore == nil
		or karaktar.HumanoidRootPart.CFrame == karFore)
	LC.avbryt()
end

if fel > 0 then
	print(("\n%d mätning(ar) föll."):format(fel))
	error("klient-ugnetablick.spec: " .. fel .. " fel")
end
print(("\nklient-ugnetablick.spec: %d prov, alla gröna"):format(total))
