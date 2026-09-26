--!nostrict
--[[
	RIDPLATSOBSERVATIONEN — #264 INFRA-OBS-PLATS1.

	KOHERENS-bänken: `Anlaggningen` bygger och speglar ridhuset på riktigt,
	`HorseService.start()` startar bryggan, och ritten går genom `tryMount`,
	`RidingIntent`, `Heartbeat` → `stepStamina` → `RidObservation.sampla` →
	`RidPlatsObservation.sampla`, samt `dismount`/`Died`. Bilden läses genom
	`HorseService.ridplats`. Rotens läge flyttas mellan hjärtslagen.

	EVIDENSNIVÅ: BANK_ONLY. Syntetiska lägen, ingen fysik, ingen motor.
]]

local fails = 0
local function check(namn, villkor, detalj)
	if villkor then
		print(string.format("  OK   %s%s", namn, detalj and ("  " .. detalj) or ""))
	else
		fails += 1
		print(string.format("  FEL  %s%s", namn, detalj and ("  " .. tostring(detalj)) or ""))
	end
end
local function nara(a, b, tol) return a ~= nil and b ~= nil and math.abs(a - b) <= (tol or 1e-6) end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Taggar = game:GetService("CollectionService")
local vec = Vector3.new

local hus = workspace:FindFirstChild("Anläggning"):FindFirstChild("UBRF")
local RP = Ridhusplats.los(hus)
assert(RP, "ridhuset ska gå att lösa")

Taggar:nollstall()
RunService._server = true
RunService.Heartbeat:nollstall()
HorseService.setMountGate(nil)
HorseService.start()

local function nyKaraktar()
	local k = Instance.new("Model")
	k.Name = "Karaktar"
	local rot = Instance.new("Part")
	rot.Name = "HumanoidRootPart"
	rot.Size = vec(2, 2, 1)
	rot.CFrame = CFrame.new(vec())
	rot.Parent = k
	local hum = Instance.new("Humanoid")
	hum.Name = "Humanoid"
	hum.Parent = k
	return k
end
local anna = { Name = "Anna", UserId = 501, Character = nyKaraktar(), CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }
local bea = { Name = "Bea", UserId = 502, Character = nyKaraktar(), CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }
Players._spelare = { anna, bea }

--[[ Ett läge i ridhusets ram (u, v i meter) på rotens höjd. ]]
local HOJD
local function lage(rp, u, v)
	local p = Ridhusplats.tillVarld(rp, vec(u, 0, v))
	return vec(p.X, HOJD, p.Z)
end

local hastA = HastRigg.bygg("plats_a", "Plats A", CFrame.new(Ridhusplats.tillVarld(RP, vec(0, 0, 10))))
hastA.Parent = workspace
Taggar:AddTag(hastA, "Horse")
local hastB = HastRigg.bygg("plats_b", "Plats B", CFrame.new(Ridhusplats.tillVarld(RP, vec(5, 0, 30))))
hastB.Parent = workspace
Taggar:AddTag(hastB, "Horse")
local function sess(m) return HorseService.sessionFor(m) end
HOJD = sess(hastA).rig.root.Position.Y

local function flytta(m, p)
	local r = sess(m).rig.root
	r.Position = p
	r.CFrame = CFrame.new(p)
end
local function steg(m, p, dt)
	if p then flytta(m, p) end
	RunService.Heartbeat:Fire(dt or 0.25)
end
local function sitUpp(sp, m, hem)
	flytta(m, hem)
	local kr = sp.Character:FindFirstChild("HumanoidRootPart")
	kr.Position = hem + vec(6, 0, 0)
	kr.CFrame = CFrame.new(hem + vec(6, 0, 0))
	local ok, skal, marke = HorseService.tryMount(sp, m)
	assert(ok, "uppsittningen föll: " .. tostring(skal))
	sess(m).energi = 1
	return marke
end
local function bild(marke) return HorseService.ridplats(marke) end

print("\n── Genom den riktiga tjänsten: baslinje, segment, meter ──")
local marke1
do
	marke1 = sitUpp(anna, hastA, lage(RP, 0, 10))
	check("uppsittningen öppnar en bild utan observation", bild(marke1) and bild(marke1).status == "ingen_observation"
		and bild(marke1).hastId == "plats_a" and bild(marke1).userId == 501)
	steg(hastA, lage(RP, 0, 10))
	local b0 = bild(marke1)
	check("första läget är en baslinje utan segment", b0.status == "baslinje" and b0.segment == nil
		and b0.punkt ~= nil, b0.status)
	check("punkten i meter: u 0, v 10", nara(b0.punkt.u, 0, 1e-6) and nara(b0.punkt.v, 10, 1e-6),
		("u %.4f v %.4f"):format(b0.punkt.u, b0.punkt.v))
	check("planär höjd: h är rotens höjd över sanden, i meter", nara(b0.punkt.h, (HOJD - RP.golvY) / 3, 1e-6)
		and type(b0.hojd) == "string", tostring(b0.punkt.h))
	check("platsen och ramen har identitet", b0.platsId == "ridhus" and type(b0.ramId) == "number")
	steg(hastA, lage(RP, 0, 12))
	local b1 = bild(marke1)
	check("nästa läge ger ett segment med båda ändpunkterna", b1.status == "segment" and b1.segment ~= nil
		and nara(b1.segment.fran.v, 10, 1e-6) and nara(b1.segment.till.v, 12, 1e-6), b1.status)
	check("i layouten och på banan", b1.iBana == true and b1.iDressyr == true)
	local ram0 = b1.ramId
	local losFore = RidPlatsObservation._losningarForProv()
	for i = 1, 5 do steg(hastA, lage(RP, 0, 12 + i * 2)) end
	check("en oförändrad ram löses inte om per steg", RidPlatsObservation._losningarForProv() == losFore,
		("%d → %d"):format(losFore, RidPlatsObservation._losningarForProv()))
	check("en oförändrad ram behåller sitt id över flera segment", bild(marke1).ramId == ram0
		and bild(marke1).status == "segment")
	check("tiden följer ridobservationen", bild(marke1).t ~= nil and bild(marke1).t > b1.t)

	--[[ Bortom C: bana men inte layout. ]]
	flytta(hastA, lage(RP, 0, 58)); steg(hastA, lage(RP, 0, 58))
	steg(hastA, lage(RP, 0, 60)); steg(hastA, lage(RP, 0, 62))
	local bc = bild(marke1)
	check("62 m från A: på banan, inte i layouten", bc.iBana == true and bc.iDressyr == false
		and nara(bc.punkt.v, 62, 1e-6))
end

print("\n── Brott: saknad rot, teleport, lucka ──")
do
	steg(hastA, lage(RP, 0, 30)); steg(hastA, lage(RP, 0, 32))
	local r = sess(hastA).rig.root
	local foralder = r.Parent
	r.Parent = nil
	steg(hastA, nil)
	r.Parent = foralder
	local b = bild(marke1)
	check("saknad rot: brott, ingen punkt, inget segment", b.status == "brott" and b.punkt == nil and b.segment == nil,
		b.status)
	steg(hastA, lage(RP, 0, 34))
	check("sedan en baslinje", bild(marke1).status == "baslinje" and bild(marke1).segment == nil)
	steg(hastA, lage(RP, 0, 36))
	check("och ett segment igen", bild(marke1).status == "segment")

	steg(hastA, lage(RP, 5, 55))
	local t = bild(marke1)
	check("teleport: brott, punkten är det nya läget, inget segment", t.status == "brott" and t.segment == nil
		and t.punkt ~= nil and nara(t.punkt.v, 55, 1e-6), t.status)
	steg(hastA, lage(RP, 5, 56))
	check("segmentet efter teleporten börjar i det nya läget", bild(marke1).status == "segment"
		and nara(bild(marke1).segment.fran.v, 55, 1e-6))
	steg(hastA, lage(RP, 5, 57), 5)
	check("lucka på 5 s: brott, inget segment", bild(marke1).status == "brott" and bild(marke1).segment == nil)
end

print("\n── Ramen: oförändrad, flyttad, borttagen, ersatt, dubbel ──")
local bana = hus:FindFirstChild("Ridbanan")
local lay = hus:FindFirstChild("Dressyrlayout 20x60")
do
	steg(hastA, lage(RP, 0, 20)); steg(hastA, lage(RP, 0, 22))
	local fore = bild(marke1)
	local obsFore = HorseService.ridobservation(marke1).distans
	--[[ Flytta BÅDA delarna lika: platsen är giltig men en annan ram. ]]
	local d = vec(0, 0, 0.5)
	bana.CFrame = CFrame.new(bana.Position + d)
	lay.CFrame = CFrame.new(lay.Position + d)
	steg(hastA, lage(RP, 0, 24))
	local efter = bild(marke1)
	check("flyttad ram: nytt ram-id och inget segment mellan ramarna", efter.ramId ~= fore.ramId
		and efter.status == "ram_ny" and efter.segment == nil, efter.status)
	steg(hastA, lage(RP, 0, 26))
	check("nästa läge i den nya ramen ger ett segment igen", bild(marke1).status == "segment"
		and bild(marke1).ramId == efter.ramId)
	check("ridobservationens summor fortsätter (ramen rör inte dem)",
		HorseService.ridobservation(marke1).distans > obsFore)
	bana.CFrame = CFrame.new(bana.Position - d)
	lay.CFrame = CFrame.new(lay.Position - d)
	steg(hastA, lage(RP, 0, 28)); steg(hastA, lage(RP, 0, 30))

	--[[ Borttagen bana. ]]
	local ersattare = Instance.new("Part")
	ersattare.Name = "Ridbanan"
	ersattare.Size = bana.Size
	ersattare.CFrame = bana.CFrame
	ersattare.CanCollide = false
	ersattare:SetAttribute("PlatsId", "ridhus_bana")
	bana:Destroy()
	steg(hastA, lage(RP, 0, 32))
	local b = bild(marke1)
	check("borttagen bana: ingen plats, inget gammalt segment", b.status == "ingen_plats"
		and b.skal == "saknas:ridhus_bana" and b.segment == nil and b.punkt == nil, tostring(b.skal))
	ersattare.Parent = hus
	workspace.DescendantAdded:Fire(ersattare)
	steg(hastA, lage(RP, 0, 34))
	local e = bild(marke1)
	check("ersatt bana: platsen tillbaka i en NY ram, utan segment över bytet", e.ramId ~= nil
		and e.ramId ~= fore.ramId and e.segment == nil, e.status)
	steg(hastA, lage(RP, 0, 36))
	check("och sedan segment igen", bild(marke1).status == "segment")
	bana = ersattare

	--[[ Dubbel layout. ]]
	local dubbel = Instance.new("Part")
	dubbel.Name = "Dressyrlayout 20x60"
	dubbel.Size = lay.Size
	dubbel.CFrame = lay.CFrame
	dubbel.CanCollide = false
	dubbel:SetAttribute("PlatsId", "ridhus_dressyr")
	dubbel:SetAttribute("Forankring", "A")
	dubbel.Parent = hus
	workspace.DescendantAdded:Fire(dubbel)
	steg(hastA, lage(RP, 0, 38))
	check("dubbel layout: ingen plats", bild(marke1).status == "ingen_plats"
		and bild(marke1).skal == "dubbelt_id:ridhus_dressyr", tostring(bild(marke1).skal))
	dubbel:Destroy()
	steg(hastA, lage(RP, 0, 40))
	check("dubbletten borta: platsen tillbaka, inget segment över bytet", bild(marke1).punkt ~= nil
		and bild(marke1).segment == nil)
	steg(hastA, lage(RP, 0, 42))
	check("och segment igen", bild(marke1).status == "segment")
end

print("\n── R1: metadata utan geometriändring, genom produktionsvägen ──")
do
	--[[ Inget `satModell`, ingen tvingad omlösning: bara ändringen och
		nästa hjärtslag. Varje fall: giltigt segment före, `ingen_plats`
		utan gammal punkt eller segment under, och efter återställning
		först en punkt utan segment och sedan ett nytt segment. ]]
	local function fall(namn, forstor, aterstall, skalVantat)
		steg(hastA, lage(RP, 0, 20)); steg(hastA, lage(RP, 0, 22))
		check(namn .. ": KONTROLL giltigt segment före", bild(marke1).status == "segment")
		forstor()
		steg(hastA, lage(RP, 0, 24))
		local b = bild(marke1)
		check(namn .. ": ingen plats, utan gammal punkt eller segment", b.status == "ingen_plats"
			and b.skal == skalVantat and b.punkt == nil and b.segment == nil,
			b.status .. " " .. tostring(b.skal))
		aterstall()
		steg(hastA, lage(RP, 0, 26))
		local e = bild(marke1)
		check(namn .. ": återställd — första punkten utan segment (inget brygg över brottet)",
			e.punkt ~= nil and e.segment == nil and e.status ~= "segment", e.status)
		steg(hastA, lage(RP, 0, 28))
		check(namn .. ": och sedan ett nytt giltigt segment", bild(marke1).status == "segment"
			and nara(bild(marke1).segment.fran.v, 26, 1e-6))
	end
	local banaNu = hus:FindFirstChild("Ridbanan")
	local layNu = hus:FindFirstChild("Dressyrlayout 20x60")
	fall("förankring A → C", function() layNu:SetAttribute("Forankring", "C") end,
		function() layNu:SetAttribute("Forankring", "A") end, "fel_forankring")
	fall("banans id byts", function() banaNu:SetAttribute("PlatsId", "annat") end,
		function() banaNu:SetAttribute("PlatsId", "ridhus_bana") end, "saknas:ridhus_bana")
	--[[ En del som redan finns i modellen får en dubblettmarkning i
		efterhand — ingen del läggs till eller tas bort. ]]
	local befintlig
	for _, c in ipairs(hus:GetChildren()) do
		if c:IsA("BasePart") and c:GetAttribute("PlatsId") == nil and c.Name == "Sarg väst" then befintlig = c break end
	end
	check("KONTROLL: en omärkt befintlig del finns", befintlig ~= nil)
	fall("sent tilldelad dubblettmarkning", function() befintlig:SetAttribute("PlatsId", "ridhus_dressyr") end,
		function() befintlig:SetAttribute("PlatsId", nil) end, "dubbelt_id:ridhus_dressyr")

	--[[ Lyssnarnas livscykel: en per barn, inga dubbletter, rivs vid
		modellbyte. ]]
	local n0, m0 = RidPlatsObservation._lyssnareForProv()
	check("en lyssnare per barn i ridhusets modell", m0 == hus and n0 == #hus:GetChildren(),
		("%d lyssnare, %d barn"):format(n0, #hus:GetChildren()))
	local tillagd = Instance.new("Part")
	tillagd.Name = "Provdel"
	tillagd.Parent = hus
	workspace.DescendantAdded:Fire(tillagd)
	steg(hastA, lage(RP, 0, 30))
	local n1 = RidPlatsObservation._lyssnareForProv()
	check("ett nytt barn får EN lyssnare", n1 == n0 + 1, ("%d → %d"):format(n0, n1))
	workspace.DescendantAdded:Fire(tillagd)
	steg(hastA, lage(RP, 0, 32))
	check("samma barn igen ger ingen dubbel lyssnare", RidPlatsObservation._lyssnareForProv() == n0 + 1)
	tillagd:Destroy()
	steg(hastA, lage(RP, 0, 34))
	check("ett borttaget barn rivs", RidPlatsObservation._lyssnareForProv() == n0)
end

print("\n── 37° vriden och flyttad ram ──")
do
	local th = math.rad(37)
	local m = Instance.new("Model")
	m.Name = "Vriden"
	m.Parent = workspace
	local bas = CFrame.new(vec(900, 0, -400)) * CFrame.Angles(0, th, 0)
	local lb = Instance.new("Part"); lb.Name = "Ridbanan"; lb.Size = vec(60, 0.18, 196.59)
	lb.CFrame = bas * CFrame.new(0, 0.09, -8.295); lb:SetAttribute("PlatsId", "ridhus_bana"); lb.Parent = m
	local ll = Instance.new("Part"); ll.Name = "Dressyrlayout 20x60"; ll.Size = vec(60, 0.06, 180)
	ll.CFrame = bas * CFrame.new(0, 0.12, 0); ll:SetAttribute("PlatsId", "ridhus_dressyr")
	ll:SetAttribute("Forankring", "A"); ll.Parent = m
	local rp = Ridhusplats.los(m)
	check("KONTROLL: den vridna ramen löses", rp ~= nil)
	RidPlatsObservation.satModell(m)
	HorseService.dismount(anna)
	local mk = sitUpp(anna, hastA, lage(rp, 3, 20))
	steg(hastA, lage(rp, 3, 20)); steg(hastA, lage(rp, 3, 22))
	local b = bild(mk)
	check("i den vridna ramen: segment i meter", b.status == "segment" and nara(b.segment.fran.u, 3, 1e-6)
		and nara(b.segment.fran.v, 20, 1e-6) and nara(b.segment.till.v, 22, 1e-6), b.status)
	check("A och C: 0 och 60 m", nara(Ridhusplats.tillLokal(rp, rp.dressyr.A).Z, 0, 1e-6)
		and nara(Ridhusplats.tillLokal(rp, rp.dressyr.C).Z, 60, 1e-6))
	HorseService.dismount(anna)
	RidPlatsObservation.satModell(hus)
	m:Destroy()
end

print("\n── Avsittning, ny uppsittning, två ryttare, frysning, livscykel ──")
do
	local ma = sitUpp(anna, hastA, lage(RP, 0, 10))
	local mb = sitUpp(bea, hastB, lage(RP, 5, 30))
	steg(hastA, lage(RP, 0, 10)); flytta(hastB, lage(RP, 5, 30)); RunService.Heartbeat:Fire(0.25)
	flytta(hastA, lage(RP, 0, 12)); flytta(hastB, lage(RP, 5, 32)); RunService.Heartbeat:Fire(0.25)
	check("två ryttare har var sin bild", bild(ma).segment and bild(mb).segment
		and nara(bild(ma).segment.till.v, 12, 1e-6) and nara(bild(mb).segment.till.v, 32, 1e-6)
		and bild(mb).userId == 502)
	local gammal = bild(ma)
	flytta(hastA, lage(RP, 0, 14)); RunService.Heartbeat:Fire(0.25)
	check("en äldre bild är orörd och fryst", nara(gammal.segment.till.v, 12, 1e-6)
		and pcall(function() gammal.status = "x" end) == false
		and pcall(function() gammal.segment.till.v = 0 end) == false)
	HorseService.dismount(anna)
	check("avsittningen stänger bilden", bild(ma).status == "stangd" and bild(ma).segment == nil)
	flytta(hastA, lage(RP, 0, 16)); RunService.Heartbeat:Fire(0.25)
	check("en stängd bild tar inte emot fler steg", bild(ma).status == "stangd")
	local ny = sitUpp(anna, hastA, lage(RP, 0, 10))
	check("ny uppsittning: ny bild utan observation", ny ~= ma and bild(ny).status == "ingen_observation")
	anna.Character:FindFirstChildOfClass("Humanoid").Died:Fire()
	check("döden stänger som avbruten", bild(ny).status == "stangd" and bild(ny).satt == "avbruten")
	if HorseService.horseOf(anna) then HorseService.dismount(anna) end
	HorseService.dismount(bea)
	for _ = 1, RidPlatsObservation.MAX_AVSLUTADE + 5 do
		sitUpp(anna, hastA, lage(RP, 0, 10))
		HorseService.dismount(anna)
	end
	check("livscykeltillståndet är begränsat", RidPlatsObservation._antalRitterForProv() <= RidPlatsObservation.MAX_AVSLUTADE + 2,
		tostring(RidPlatsObservation._antalRitterForProv()))
end

if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("\nridplats.spec: alla gröna")
end
