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

--[[ ══ GRANSKNING R1 ════════════════════════════════════════════════ ]]

--[[ En väg genom en lista v-värden vid u, med ett golv per läge. ]]
local function sekvens(modell, h, u, vs, golvlista)
	for i, v in ipairs(vs) do
		local g = if golvlista then golvlista[i] else "Sand"
		if g == false then g = nil end
		steg(modell, lage(h, u, v), 0.25, g)
	end
end
local function sistaVid(m, id)
	local f = forsokVid(m, id)
	return f[#f], #f
end

print("\n── R1 fynd 1: att nå planet och vända är inte passage ──")
do
	local m = sitUpp(anna, hastA, start)
	local ID = "ridhus_hinder_bla_24"
	sekvens(hastA, H, 0, { -12, -8, -4, 0, -4, -8, -12 })
	local f = sistaVid(m, ID)
	check("planet nått och tillbaka: ingen passage", f.utfall == "ingen_passage", f.utfall)
	sekvens(hastA, H, 0, { -12, -8, -4, 0, 0, 0, -4, -8, -12 })
	f = sistaVid(m, ID)
	check("stilla på planet och tillbaka: ingen passage", f.utfall == "ingen_passage", f.utfall)
	sekvens(hastA, H, 0, { -12, -8, -4, 0.1, -0.1, 0.2, -4, -8, -12 })
	f = sistaVid(m, ID)
	check("brus kring planet: ingen passage", f.utfall == "ingen_passage", f.utfall)
	sekvens(hastA, H, 0, { -12, -8, -4, 0, 2, 4, 8, 12 })
	f = sistaVid(m, ID)
	check("KONTROLL: genom planet via exakt noll är passage framåt", f.utfall == "passage"
		and f.riktning == "fram", f.utfall .. " " .. tostring(f.riktning))
	sekvens(hastA, H, 0, { 12, 8, 4, 0, 0, -2, -4, -8, -12 })
	f = sistaVid(m, ID)
	check("KONTROLL: baklänges via planet (två prov på det) är passage bak", f.utfall == "passage"
		and f.riktning == "bak", f.utfall .. " " .. tostring(f.riktning))
	sekvens(hastA, H, H.bredd / 2 + 1, { -12, -8, -4, 0, 2, 4, 8, 12 })
	f = sistaVid(m, ID)
	check("utanför bredden via planet: sidan om", f.utfall == "sidan_om", f.utfall)
	HorseService.dismount(anna)
end

print("\n── R2: korsningen ur den observerade vägen, inte kordan ──")
do
	local m = sitUpp(anna, hastA, start)
	local ID = "ridhus_hinder_bla_24"
	--[[ Ett läge i (u, v); samma höjd, mark, 0,25 s. Halva bredden är 4,2. ]]
	local function uv(par)
		for _, p in ipairs(par) do steg(hastA, lage(H, p[1], p[2]), 0.25, "Sand") end
	end
	local function utfall() return sistaVid(m, ID).utfall end

	uv({ { 0, -12 }, { 0, -8 }, { 0, -4 }, { 5, 0 }, { 0, 4 }, { 0, 8 }, { 0, 12 } })
	check("1: planet nås vid u=5, utanför bommen: sidan om", utfall() == "sidan_om", utfall())
	uv({ { 0, 12 }, { 0, 8 }, { 0, 4 }, { 5, 0 }, { 0, -4 }, { 0, -8 }, { 0, -12 } })
	check("1 baklänges: sidan om", utfall() == "sidan_om", utfall())

	uv({ { 5, -12 }, { 5, -8 }, { 5, -4 }, { 0, 0 }, { 5, 4 }, { 5, 8 }, { 5, 12 } })
	check("2: korsningen vid u=0 fast ändarna är utanför: passage", utfall() == "passage"
		and sistaVid(m, ID).riktning == "fram", utfall())
	uv({ { 5, 12 }, { 5, 8 }, { 5, 4 }, { 0, 0 }, { 5, -4 }, { 5, -8 }, { 5, -12 } })
	check("2 baklänges: passage bak", utfall() == "passage" and sistaVid(m, ID).riktning == "bak", utfall())

	uv({ { 0, -12 }, { 0, -8 }, { 0, -4 }, { 5, -0.1 }, { 5, 0.1 }, { 0, 4 }, { 0, 8 }, { 0, 12 } })
	check("3: ett observerat segment korsar vid u=5 inne i toleransbandet: sidan om",
		utfall() == "sidan_om", utfall())
	uv({ { 0, -12 }, { 0, -8 }, { 0, -4 }, { 5, -0.1 }, { 5, 0.05 }, { 5, 0.2 }, { 0, 4 }, { 0, 8 }, { 0, 12 } })
	check("3 med flera punkter inom bandet: sidan om", utfall() == "sidan_om", utfall())
	uv({ { 5, -12 }, { 5, -8 }, { 5, -4 }, { 0, -0.1 }, { 0, 0.1 }, { 5, 4 }, { 5, 8 }, { 5, 12 } })
	check("3 omvänt: korsning vid u=0 inne i bandet är passage", utfall() == "passage", utfall())

	uv({ { 0, -12 }, { 0, -8 }, { 0, -4 }, { 0, 0 }, { 0, 4 }, { 0, 8 }, { 0, 12 } })
	check("KONTROLL: rak väg genom u=0 är passage", utfall() == "passage", utfall())
	uv({ { 5, -12 }, { 5, -8 }, { 5, -4 }, { 5, 0 }, { 5, 4 }, { 5, 8 }, { 5, 12 } })
	check("KONTROLL: rak väg vid u=5 är sidan om", utfall() == "sidan_om", utfall())
	check("ingen rivning i något av fallen", (function()
		for _, f in ipairs(forsokVid(m, ID)) do if f.rivning ~= false then return false end end
		return true
	end)())

	--[[ Det SENASTE planmötet gäller: först planet vid u=0 och tillbaka,
		sedan en korsning vid u=5 i samma försök. ]]
	uv({ { 0, -12 }, { 0, -8 }, { 0, -4 }, { 0, 0 }, { 0, -4 }, { 5, -4 }, { 5, 0 }, { 5, 4 }, { 5, 8 }, { 5, 12 } })
	check("planmöte vid u=0 och tillbaka, sedan korsning vid u=5: sidan om", utfall() == "sidan_om", utfall())
	uv({ { 5, -12 }, { 5, -8 }, { 5, -4 }, { 5, 0 }, { 5, -4 }, { 0, -4 }, { 0, 0 }, { 0, 4 }, { 0, 8 }, { 0, 12 } })
	check("planmöte vid u=5 och tillbaka, sedan korsning vid u=0: passage", utfall() == "passage", utfall())

	--[[ Ett försök vars första läge ligger PÅ planet har ingen bekräftad
		sida än; den första bekräftelsen är ingen sidväxling. ]]
	uv({ { 12, 0 }, { 10, 0 }, { 5, 0 }, { 3, 0 }, { 3, 4 }, { 3, 8 }, { 3, 12 } })
	check("första läget på planet: den första bekräftade sidan är ingen passage",
		utfall() == "ingen_passage", utfall())

	--[[ Ett brott tar kandidaten med sig: planet nås vid u=0, roten
		saknas, och hästen dyker upp på andra sidan. Ingen passage. ]]
	uv({ { 0, -12 }, { 0, -8 }, { 0, -4 }, { 0, 0 } })
	local r = sess(hastA).rig.root
	local foralder = r.Parent
	r.Parent = nil
	steg(hastA, nil)
	r.Parent = foralder
	--[[ Efter brottet: baslinje vid v=4, sedan in i zonen och ut. ]]
	uv({ { 0, 4 }, { 0, 5 }, { 0, 12 } })
	local alla = forsokVid(m, ID)
	check("brott efter planträff: det avbrutna försöket är okänt", alla[#alla - 1].giltighet == "brott"
		and alla[#alla - 1].utfall == "okant", alla[#alla - 1].giltighet)
	check("och nästa försök ärver ingen kandidat", alla[#alla].utfall ~= "passage", alla[#alla].utfall)
	HorseService.dismount(anna)
end

print("\n── R1 fynd 2: okänd markevidens bryter landningskedjan ──")
do
	local m = sitUpp(anna, hastA, start)
	local ID = "ridhus_hinder_bla_24"
	local vag = { -12, -8, -4, -2, 2, 4, 8, 12 }
	sekvens(hastA, H, 0, vag, { "Sand", "Sand", "Sand", "Air", false, "Sand", "Sand", "Sand" })
	local f = sistaVid(m, ID)
	check("luft → okänt → mark: landningen är okänd, inte observerad",
		f.luftfas == "observerad" and f.landning == "okand", f.luftfas .. "/" .. f.landning)
	sekvens(hastA, H, 0, vag, { "Sand", "Sand", "Air", false, false, "Sand", "Sand", "Sand" })
	f = sistaVid(m, ID)
	check("upprepat okänt: fortfarande okänd", f.landning == "okand", f.landning)
	sekvens(hastA, H, 0, vag, { "Sand", "Air", false, "Sand", "Air", "Sand", "Sand", "Sand" })
	f = sistaVid(m, ID)
	check("återhämtning: en NY luft → mark efter luckan är en observerad landning",
		f.landning == "observerad", f.landning)
	sekvens(hastA, H, 0, vag, { "Sand", "Sand", "Sand", "Air", "Sand", "Sand", "Sand", "Sand" })
	f = sistaVid(m, ID)
	check("KONTROLL: luft direkt följd av mark är observerad", f.landning == "observerad", f.landning)
	sekvens(hastA, H, 0, vag, { "Sand", "Sand", "Sand", "Air", false, false, false, false })
	f = sistaVid(m, ID)
	check("luft → okänt utan senare mark: okänd", f.landning == "okand", f.landning)
	HorseService.dismount(anna)
end

print("\n── R1 fynd 3: registrets livscykel genom de riktiga callbackarna ──")
do
	local ID = "ridhus_hinder_bla_24"
	local original = perId[ID]
	local function kopia()
		local p = Instance.new("Part")
		p.Name = "Ersattningsbom"
		p.Size = original.Size
		p.CFrame = original.CFrame
		p:SetAttribute("HinderId", ID)
		return p
	end
	--[[ Dubblett under en aktiv ritt. ]]
	local m = sitUpp(anna, hastA, start)
	sekvens(hastA, H, 0, { -12, -8, -4 })
	check("KONTROLL: ett försök pågår", sistaVid(m, ID).utfall == "pagar")
	local dubblett = kopia()
	dubblett.Parent = workspace
	workspace.DescendantAdded:Fire(dubblett)
	local f = sistaVid(m, ID)
	check("en ny del med samma id: pågående försök stängs som ogiltigt", f.giltighet == "hinder_ogiltigt"
		and f.utfall == "okant", f.giltighet .. " " .. f.utfall)
	check("och båda avvisas", HinderObservation.register().hinder[ID] == nil
		and HinderObservation.register().avvisade[ID] == "dubbelt_id")
	local _, antal = sistaVid(m, ID)
	sekvens(hastA, H, 0, { -2, 2, 4, 8, 12 })
	local _, antal2 = sistaVid(m, ID)
	check("inga nya försök och ingen retroaktiv passage under dubbletten", antal2 == antal
		and sistaVid(m, ID).utfall == "okant")

	--[[ Dubbletten tas bort: originalet blir giltigt igen. ]]
	workspace.DescendantRemoving:Fire(dubblett)
	dubblett.Parent = nil
	check("dubbletten borta: originalet är giltigt igen", HinderObservation.register().hinder[ID] ~= nil
		and HinderObservation.register().avvisade[ID] == nil)
	check("och registret håller en del för id:t", HinderObservation._delarForProv(ID) == 1,
		tostring(HinderObservation._delarForProv(ID)))

	--[[ Borttagning och ensam ersättare med samma id. ]]
	sekvens(hastA, H, 0, { -12, -8, -4 })
	workspace.DescendantRemoving:Fire(original)
	local gammal = sistaVid(m, ID)
	check("borttagningen stänger det pågående försöket", gammal.giltighet == "hinder_borttaget")
	check("registret är tomt för id:t mellan borttagning och ersättning",
		HinderObservation.register().hinder[ID] == nil and HinderObservation._delarForProv(ID) == 0)
	local ersattare = kopia()
	ersattare.Parent = workspace
	workspace.DescendantAdded:Fire(ersattare)
	check("en ensam ersättare med samma id godtas", HinderObservation.register().hinder[ID] ~= nil
		and HinderObservation.register().avvisade[ID] == nil)
	sekvens(hastA, H, 0, { -12, -8, -4, 0, 2, 4, 8, 12 })
	local nu, antal3 = sistaVid(m, ID)
	check("ersättaren ger ett NYTT försök, och det gamla ärvs inte", nu.utfall == "passage"
		and gammal.utfall == "okant" and antal3 >= 2)

	--[[ Upprepad cykel: minnet växer inte. ]]
	local senast = ersattare
	for _ = 1, 20 do
		workspace.DescendantRemoving:Fire(senast)
		senast.Parent = nil
		senast = kopia()
		senast.Parent = workspace
		workspace.DescendantAdded:Fire(senast)
	end
	check("tjugo cykler: en levande del, giltigt hinder", HinderObservation._delarForProv(ID) == 1
		and HinderObservation.register().hinder[ID] ~= nil)

	--[[ Återställ originalet för block efter detta. ]]
	workspace.DescendantRemoving:Fire(senast)
	senast.Parent = nil
	workspace.DescendantAdded:Fire(original)
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
