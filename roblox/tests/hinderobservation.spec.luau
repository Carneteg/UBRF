--!nostrict
--[[
	HINDEROBSERVATIONEN — #264 INFRA-2B2.

	Körs i KOHERENS-bänken: `Anlaggningen.luau` bygger och speglar världen på
	riktigt, bommarna får sitt `HinderId` ur källdatan, och `HorseService.start()`
	registrerar dem genom sin egen startväg. Ritten går genom `tryMount`,
	`RidingIntent`, `Heartbeat` → `stepStamina` → ridobservationen →
	hinderobservationen, och `dismount`/`Died`. Hästens rot flyttas mellan
	hjärtslagen; `FloorMaterial` på hästens humanoid är ett syntetiskt
	tillstånd (`{ Name = "Air" }` eller ett markmaterial).

	Blocken märkta MODULKONTRAKT anropar modulen direkt och är modulbevis.

	EVIDENSNIVÅ: BANK_ONLY. Ingen fysik, ingen motor, ingen klient.
]]

local fails = 0
local function check(namn, villkor, detalj)
	if villkor then
		print(string.format("  OK   %s%s", namn, detalj and ("  " .. detalj) or ""))
	else
		fails += 1
		print(string.format("  FEL  %s%s", namn, detalj and ("  " .. detalj) or ""))
	end
end
local function nara(a, b, tol) return a ~= nil and b ~= nil and math.abs(a - b) <= (tol or 1e-6) end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Taggar = game:GetService("CollectionService")
local vec = Vector3.new
local M = BuildKit.M

print("\n── Bygget: befintliga hinder med stabila id:n, geometrin orörd ──")
local bommar = {}
for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("BasePart") and d:GetAttribute("HinderId") ~= nil then
		table.insert(bommar, d)
	end
end
local kalla = UBRFKomplex.ridhus.hinder
check("varje hinder i källdatan har ett id", #kalla == 3 and kalla[1].id ~= nil and kalla[2].id ~= nil
	and kalla[3].id ~= nil)
check("bygget märker exakt tre bommar", #bommar == 3, tostring(#bommar))
local perId = {}
for _, b in ipairs(bommar) do perId[b:GetAttribute("HinderId")] = b end
for _, h in ipairs(kalla) do
	local b = perId[h.id]
	check(("%s: bommen finns"):format(h.id), b ~= nil)
	if b then
		local langst = math.max(b.Size.X, b.Size.Y, b.Size.Z)
		check(("%s: bredden är källans %.1f m"):format(h.id, h.b), nara(langst, h.b * M, 1e-6),
			("%.3f studs"):format(langst))
		check(("%s: bommen kolliderar fortfarande inte"):format(h.id), b.CanCollide == false)
		check(("%s: namnet är oförändrat"):format(h.id), string.sub(b.Name, 1, 10) == "Hinderbom ")
	end
end

Taggar:nollstall()
RunService._server = true
RunService.Heartbeat:nollstall()
HorseService.setMountGate(nil)
HorseService.start()

local reg = HinderObservation.register()
local H = reg.hinder["ridhus_hinder_bla_24"]
check("registret har de tre hindren", reg.hinder["ridhus_hinder_bla_24"] ~= nil
	and reg.hinder["ridhus_hinder_rod_38"] ~= nil and reg.hinder["ridhus_hinder_rod_50"] ~= nil)
check("och inga avvisade", next(reg.avvisade) == nil)
check("bredden i registret är bommens", nara(H.bredd, 2.8 * M, 1e-6), tostring(H.bredd))

--[[ Ett läge i hindrets eget system: u längs bommen, v längs normalen. ]]
local HOJD
local function lage(h, u, v)
	return vec(h.x + u * h.breddaxel.x + v * h.normal.x, HOJD, h.z + u * h.breddaxel.z + v * h.normal.z)
end

local function nyKaraktar(pos)
	local k = Instance.new("Model")
	k.Name = "Karaktar"
	local rot = Instance.new("Part")
	rot.Name = "HumanoidRootPart"
	rot.Size = vec(2, 2, 1)
	rot.CFrame = CFrame.new(pos)
	rot.Parent = k
	local hum = Instance.new("Humanoid")
	hum.Name = "Humanoid"
	hum.Parent = k
	return k
end
local anna = { Name = "Anna", UserId = 401, Character = nyKaraktar(vec()), CharacterAdded = __signal_ny(),
	CharacterRemoving = __signal_ny() }
local bea = { Name = "Bea", UserId = 402, Character = nyKaraktar(vec()), CharacterAdded = __signal_ny(),
	CharacterRemoving = __signal_ny() }
Players._spelare = { anna, bea }

local start = lage(H, 0, -20)
local hastA = HastRigg.bygg("prov_a", "Prov A", CFrame.new(start))
hastA.Parent = workspace
Taggar:AddTag(hastA, "Horse")
HOJD = HorseService.sessionFor(hastA).rig.root.Position.Y
local H2 = reg.hinder["ridhus_hinder_rod_38"]
local hastB = HastRigg.bygg("prov_b", "Prov B", CFrame.new(lage(H2, 0, -20)))
hastB.Parent = workspace
Taggar:AddTag(hastB, "Horse")

local function sess(m) return HorseService.sessionFor(m) end
local function flytta(modell, p)
	local r = sess(modell).rig.root
	r.Position = p
	r.CFrame = CFrame.new(p)
end
local function golv(modell, namn)
	sess(modell).rig.humanoid.FloorMaterial = if namn then { Name = namn } else nil
end
local function steg(modell, p, dt, golvNamn)
	if p then flytta(modell, p) end
	golv(modell, golvNamn)
	RunService.Heartbeat:Fire(dt or 0.25)
end
local function sitUpp(sp, modell, hem)
	flytta(modell, hem)
	local kr = sp.Character:FindFirstChild("HumanoidRootPart")
	kr.Position = hem + vec(6, 0, 0)
	kr.CFrame = CFrame.new(hem + vec(6, 0, 0))
	local ok, skal, marke = HorseService.tryMount(sp, modell)
	assert(ok, "uppsittningen föll: " .. tostring(skal))
	sess(modell).energi = 1
	return marke
end
local function obs(m) return HorseService.hinderobservation(m) end
local function forsokVid(m, id)
	local ut = {}
	for _, f in ipairs(obs(m).forsok) do if f.hinderId == id then table.insert(ut, f) end end
	return ut
end
--[[ En väg längs v från v0 till v1 i steg om `d` studs vid u. ]]
local function rid(modell, h, u, v0, v1, d, golvFor)
	local riktning = if v1 >= v0 then 1 else -1
	local v = v0
	steg(modell, lage(h, u, v), 0.25, if golvFor then golvFor(v) else "Sand")
	while (riktning > 0 and v < v1) or (riktning < 0 and v > v1) do
		v += riktning * d
		steg(modell, lage(h, u, v), 0.25, if golvFor then golvFor(v) else "Sand")
	end
end

print("\n── Passage, riktning, luftfas och landning ──")
do
	local m = sitUpp(anna, hastA, start)
	--[[ Luft kring bommen, mark före och efter. ]]
	rid(hastA, H, 0, -10, 10, 2, function(v) return if math.abs(v) <= 2 then "Air" else "Sand" end)
	local f = forsokVid(m, "ridhus_hinder_bla_24")
	check("ett försök vid hindret", #f == 1, tostring(#f))
	local a = f[1]
	check("passage inom bredden, framåt", a and a.utfall == "passage" and a.riktning == "fram"
		and a.giltighet == "fullstandig", a and (a.utfall .. " " .. tostring(a.riktning)) or "")
	check("observerad luftfas och landning", a and a.luftfas == "observerad" and a.landning == "observerad")
	check("tidsstämplad och med ritt, häst och ryttare", a and a.tPassage ~= nil and a.tIn <= a.tPassage
		and obs(m).hastId == "prov_a" and obs(m).userId == 401)
	check("kontakt otillgänglig, ingen rivning, bommen ligger", a and a.kontakt == "otillganglig"
		and a.rivning == false and a.bom == "ligger")

	rid(hastA, H, 0, 10, -10, 2)
	f = forsokVid(m, "ridhus_hinder_bla_24")
	check("baklänges: nytt försök, riktning bak", #f == 2 and f[2].utfall == "passage" and f[2].riktning == "bak"
		and f[2].nr == 2, #f == 2 and tostring(f[2].riktning) or tostring(#f))
	check("utan luft: ingen luftfas, ingen landning", #f == 2 and f[2].luftfas == "ej_observerad"
		and f[2].landning == "ingen_luftfas")
	HorseService.dismount(anna)
end

print("\n── Sidan om, utanför, stilla i zonen, återinträde ──")
do
	local m = sitUpp(anna, hastA, start)
	local sida = H.bredd / 2 + 1
	rid(hastA, H, sida, -10, 10, 2)
	local f = forsokVid(m, "ridhus_hinder_bla_24")
	check("korsning utanför bredden är sidan om", #f == 1 and f[1].utfall == "sidan_om",
		#f > 0 and f[1].utfall or "inget")
	rid(hastA, H, H.bredd / 2 + 12, -10, 10, 2)
	check("helt utanför zonen: inget försök", #forsokVid(m, "ridhus_hinder_bla_24") == 1)

	steg(hastA, lage(H, 0, -12)); steg(hastA, lage(H, 0, -9))
	for _ = 1, 12 do steg(hastA, lage(H, 0, -3)) end
	steg(hastA, lage(H, 0, -9))
	f = forsokVid(m, "ridhus_hinder_bla_24")
	check("stilla i zonen ger ETT försök, ingen passage", #f == 2 and f[2].utfall == "ingen_passage"
		and f[2].sampel >= 12, #f == 2 and (f[2].utfall .. " " .. f[2].sampel) or tostring(#f))
	for _ = 1, 3 do steg(hastA, lage(H, 0, -3)) end
	steg(hastA, lage(H, 0, -9))
	f = forsokVid(m, "ridhus_hinder_bla_24")
	check("återinträde ger ett nytt försök", #f == 3 and f[3].nr == 3)
	HorseService.dismount(anna)
end

print("\n── Brott: teleport, saknad rot, lucka, saknad markevidens ──")
do
	local m = sitUpp(anna, hastA, start)
	steg(hastA, lage(H, 0, -10)); steg(hastA, lage(H, 0, -4))
	steg(hastA, lage(H, 0, 60))                                   -- teleport över bommen
	local f = forsokVid(m, "ridhus_hinder_bla_24")
	check("teleport över bommen: ingen passage", #f == 1 and f[1].utfall == "okant" and f[1].giltighet == "brott",
		#f > 0 and (f[1].utfall .. " " .. f[1].giltighet) or "inget")
	rid(hastA, H, 0, -10, 10, 2)
	f = forsokVid(m, "ridhus_hinder_bla_24")
	check("återhämtning: nästa legitima passage räknas", #f == 2 and f[2].utfall == "passage")

	steg(hastA, lage(H, 0, -10)); steg(hastA, lage(H, 0, -2))
	local r = sess(hastA).rig.root
	local foralder = r.Parent
	r.Parent = nil
	steg(hastA, nil)
	r.Parent = foralder
	steg(hastA, lage(H, 0, 2))
	steg(hastA, lage(H, 0, 12))
	f = forsokVid(m, "ridhus_hinder_bla_24")
	check("saknad rot mitt i försöket: brott, och ingen passage över luckan",
		f[3] and f[3].giltighet == "brott" and f[3].utfall == "okant"
			and (f[4] == nil or f[4].utfall ~= "passage"),
		f[3] and f[3].giltighet or "inget")

	steg(hastA, lage(H, 0, -10)); steg(hastA, lage(H, 0, -2))
	steg(hastA, lage(H, 0, 2), 5)                                 -- lucka på 5 s
	steg(hastA, lage(H, 0, 12))
	local sista = forsokVid(m, "ridhus_hinder_bla_24")
	local passerLucka = false
	for i = 5, #sista do if sista[i].utfall == "passage" then passerLucka = true end end
	check("en lucka i tid ger ingen passage", not passerLucka)

	rid(hastA, H, 0, -10, 10, 2, function() return nil end)
	local u = forsokVid(m, "ridhus_hinder_bla_24")
	local sist = u[#u]
	check("okänd markevidens: luftfas och landning okända, aldrig lyckade",
		sist.utfall == "passage" and sist.luftfas == "okand" and sist.landning == "okand",
		sist.luftfas .. "/" .. sist.landning)

	--[[ Luft observerad, sedan INGEN markevidens: landningen är okänd,
		inte observerad. ]]
	rid(hastA, H, 0, -10, 10, 2, function(v) return if v < -2 then "Sand" elseif v <= 2 then "Air" else nil end)
	u = forsokVid(m, "ridhus_hinder_bla_24")
	sist = u[#u]
	check("luft sedan okänt: landningen är okänd, inte lyckad",
		sist.utfall == "passage" and sist.luftfas == "observerad" and sist.landning == "okand",
		sist.luftfas .. "/" .. sist.landning)
	HorseService.dismount(anna)
end

print("\n── Två ryttare, ritten slutar i zonen, ny uppsittning ──")
do
	local ma = sitUpp(anna, hastA, start)
	local mb = sitUpp(bea, hastB, lage(H2, 0, -20))
	rid(hastB, H2, 0, -10, 10, 2)
	check("Beas passage hamnar vid hennes hinder, i hennes ritt",
		#forsokVid(mb, "ridhus_hinder_rod_38") == 1 and #forsokVid(ma, "ridhus_hinder_rod_38") == 0)
	check("och Annas ritt är tom", #obs(ma).forsok == 0)
	steg(hastA, lage(H, 0, -10)); steg(hastA, lage(H, 0, -3))
	HorseService.dismount(anna)
	local f = forsokVid(ma, "ridhus_hinder_bla_24")
	check("ritten slutar i zonen: okänt utfall", #f == 1 and f[1].giltighet == "ritten_slut" and f[1].utfall == "okant")
	local ny = sitUpp(anna, hastA, start)
	check("ny uppsittning: ny, tom observation", ny ~= ma and #obs(ny).forsok == 0)
	anna.Character:FindFirstChildOfClass("Humanoid").Died:Fire()
	check("döden stänger som avbruten", obs(ny).oppen == false and obs(ny).satt == "avbruten")
	if HorseService.horseOf(anna) then HorseService.dismount(anna) end
	HorseService.dismount(bea)
end

print("\n── Borttaget hinder ──")
do
	local m = sitUpp(anna, hastA, start)
	local H3 = reg.hinder["ridhus_hinder_rod_50"]
	flytta(hastA, lage(H3, 0, -10))
	steg(hastA, lage(H3, 0, -10)); steg(hastA, lage(H3, 0, -3))
	local bom = perId["ridhus_hinder_rod_50"]
	local foralder = bom.Parent
	workspace.DescendantRemoving:Fire(bom)
	bom.Parent = nil
	local f = forsokVid(m, "ridhus_hinder_rod_50")
	check("pågående försök vid ett borttaget hinder stängs", #f == 1 and f[1].giltighet == "hinder_borttaget"
		and f[1].utfall == "okant", #f > 0 and f[1].giltighet or "inget")
	steg(hastA, lage(H3, 0, 3)); steg(hastA, lage(H3, 0, 10))
	check("och ger inga nya försök", #forsokVid(m, "ridhus_hinder_rod_50") == 1)
	check("registret har släppt det", HinderObservation.register().hinder["ridhus_hinder_rod_50"] == nil)
	bom.Parent = foralder
	HorseService.dismount(anna)
end

print("\n── Minne och fryst bild ──")
do
	local m = sitUpp(anna, hastA, start)
	for _ = 1, HinderObservation.MAX_FORSOK + 10 do
		steg(hastA, lage(H, 0, -3))
		steg(hastA, lage(H, 0, -9))
	end
	local o = obs(m)
	check("försöken har ett tak och överflödet syns", #o.forsok == HinderObservation.MAX_FORSOK
		and o.overflode == true and o.tappade >= 5, ("%d försök, %d tappade"):format(#o.forsok, o.tappade))
	check("bilden är fryst", pcall(function() o.forsok[1].utfall = "passage" end) == false
		and pcall(function() o.satt = "x" end) == false)
	check("och bär inga interna fält", o.forsok[1]._korsat == nil)
	HorseService.dismount(anna)
end

print("\n── MODULKONTRAKT (inte produktionsväg): register och brott ──")
do
	HinderObservation._glomForProv()
	local function del(id, pos, storlek)
		local p = Instance.new("Part")
		p.Name = "Provbom"
		p.Size = storlek or vec(8, 0.3, 0.3)
		p.CFrame = CFrame.new(pos or vec())
		p:SetAttribute("HinderId", id)
		return p
	end
	check("KONTROLL: ett giltigt hinder registreras", HinderObservation.registrera(del("ok", vec(0, 1, 0))) == true)
	local a = HinderObservation.registrera(del("dubbel", vec(10, 1, 0)))
	local b, skal = HinderObservation.registrera(del("dubbel", vec(20, 1, 0)))
	check("ett dubbelt id avvisas, för båda bommarna", a == true and b == false and skal == "dubbelt_id"
		and HinderObservation.register().hinder.dubbel == nil)
	check("ett tomt id avvisas", HinderObservation.registrera(del("", vec())) == false)
	check("icke-ändlig geometri avvisas", HinderObservation.registrera(del("nan", vec(0 / 0, 0, 0))) == false)
	check("en stående bom är inget hinder", HinderObservation.registrera(del("staende", vec(), vec(0.3, 8, 0.3))) == false)

	HinderObservation.starta("k", "x", 1)
	HinderObservation.segment("k", vec(0, 1, -4), vec(0, 1, -1), 1, "mark", vec(1, 1, 1))
	HinderObservation.brott("k", 2)
	HinderObservation.segment("k", vec(0, 1, 1), vec(0, 1, 4), 3, "mark", vec(1, 1, 1))
	local o = HinderObservation.ogonblick("k")
	check("ett brott stänger försöket, och nästa segment passerar inte i efterhand",
		o.forsok[1].giltighet == "brott" and (o.forsok[2] == nil or o.forsok[2].utfall ~= "passage"))
	check("en stängd ritt tar inte emot segment", HinderObservation.avsluta("k", "avslutad") == true
		and HinderObservation.segment("k", vec(0, 1, -4), vec(0, 1, 4), 4, "mark", nil) == false)
end

if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("\nhinderobservation.spec: alla gröna")
end
