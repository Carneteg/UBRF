--!nostrict
--[[
	RIDOBSERVATIONEN — #264 INFRA-2B1.

	Mäter serverns observation av ridväg och tempo genom PRODUKTIONENS
	vägar: `tryMount`, `RidingIntent` via `OnServerEvent`, `Heartbeat` (som
	`HorseService.start()` kopplar och som kör `stepStamina` → observationen),
	`dismount`, `Died`, och `StateSync`. Hästens rot flyttas mellan
	hjärtslagen med falska lägen; tiden är hjärtslagens `dt`.

	Sista blocket, MODULKONTRAKT, anropar modulen direkt för det som
	produktionen inte kan skapa (dt = 0 når aldrig observationen, eftersom
	hjärtslagen samlas till steg om minst 0,25 s). Det är ett modulbevis.

	EVIDENSNIVÅ: BANK_ONLY. Syntetiska lägen, ingen fysik, ingen motor.
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
	local anim = Instance.new("Animator")
	anim.Name = "Animator"
	anim.Parent = hum
	return k, rot, hum
end
local function nySpelare(namn, userId, pos)
	return { Name = namn, UserId = userId, Character = (nyKaraktar(pos)),
		CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }
end

Taggar:nollstall()
RunService._server = true
RunService.Heartbeat:nollstall()
local anna = nySpelare("Anna", 301, vec(6, 0, 0))
local bea = nySpelare("Bea", 302, vec(46, 0, 0))
Players._spelare = { anna, bea }
HorseService.setMountGate(nil)
HorseService.start()

local hastA = HastRigg.bygg("blackrock_jack", "Blackrock Jack", CFrame.new(vec(0, 0, 0)))
hastA.Parent = workspace
Taggar:AddTag(hastA, "Horse")
local hastB = HastRigg.bygg("cosmo", "Cosmo", CFrame.new(vec(40, 0, 0)))
hastB.Parent = workspace
Taggar:AddTag(hastB, "Horse")

local function rot(modell) return HorseService.sessionFor(modell).rig.root end
local function flytta(modell, p)
	local r = rot(modell)
	r.Position = p
	r.CFrame = CFrame.new(p)
end
--[[ Ett uthållighetssteg: placera roten, låt hjärtslaget gå. ]]
local function steg(modell, p, dt)
	if p then flytta(modell, p) end
	RunService.Heartbeat:Fire(dt or 0.25)
end
local function avsikt(sp, marke, handling)
	local s = HorseService.sessionFor(sp == anna and hastA or hastB)
	s.sisteHjalp = -math.huge
	s.intentPolletter = Config.RIDINPUT.SkopaTak
	Networking.get("RidingIntent").OnServerEvent:Fire(sp, marke, handling)
end
local function sitUpp(sp, modell)
	--[[ Tillbaka till stallplatsen: förra blockets väg kan ha lämnat
		hästen utom `MountRange`. Uppställning, inte mätning. ]]
	local hem = if modell == hastA then vec(0, 0, 0) else vec(40, 0, 0)
	flytta(modell, hem)
	local kr = sp.Character:FindFirstChild("HumanoidRootPart")
	kr.Position = hem + vec(6, 0, 0)
	kr.CFrame = CFrame.new(hem + vec(6, 0, 0))
	local ok, skal, marke = HorseService.tryMount(sp, modell)
	assert(ok, "uppsittningen föll: " .. tostring(skal))
	--[[ Full energi, så att trötthetstaket inte flyttar gångarten mitt i
		ett prov som mäter något annat. ]]
	HorseService.sessionFor(modell).energi = 1
	return marke
end
local function obs(m) return HorseService.ridobservation(m) end

print("\n── Rak väg i känd fart ──")
do
	RidObservation._glomForProv()
	local m = sitUpp(anna, hastA)
	check("uppsittningen öppnar en observation", obs(m) ~= nil and obs(m).oppen == true
		and obs(m).hastId == "blackrock_jack" and obs(m).userId == 301)
	check("utan sträcka före första steget", obs(m).distans == 0)
	avsikt(anna, m, "driv"); avsikt(anna, m, "driv")
	steg(hastA, vec(0, 0, 0))            -- baslinje
	for i = 1, 10 do steg(hastA, vec(0, 0, 2 * i)) end   -- 2 studs per 0,25 s = 8 studs/s
	local o = obs(m)
	check("sträckan är 20 studs", nara(o.distans, 20), tostring(o.distans))
	check("medelfarten är 8 studs/s", nara(o.medelFart, 8), tostring(o.medelFart))
	check("rakt fram ger ingen sväng", nara(o.svangAbs, 0, 1e-9), tostring(o.svangAbs))
	check("tio giltiga segment och obruten", o.giltighet.segment == 10 and o.giltighet.obruten == true)
	check("tid i accepterad trav, inte i observation", nara(o.tidPerGangart.trot, 2.75)
		and nara(o.obsTid, 2.5), ("trav %s, obs %s"):format(tostring(o.tidPerGangart.trot), tostring(o.obsTid)))
	check("enheterna står i posten", o.enheter.langd == "studs" and o.enheter.fart == "studs/s")
	HorseService.dismount(anna)
end

print("\n── Svängar, med omslag vid ±π ──")
do
	local m = sitUpp(anna, hastA)
	avsikt(anna, m, "driv")
	--[[ Norr (+Z) två segment, sedan öster (+X) två: en kvarts varv. ]]
	steg(hastA, vec(0, 0, 0))
	steg(hastA, vec(0, 0, 1)); steg(hastA, vec(0, 0, 2))
	steg(hastA, vec(1, 0, 2)); steg(hastA, vec(2, 0, 2))
	local o = obs(m)
	check("en kvarts varv åt ett håll", nara(math.abs(o.svangNetto), math.pi / 2, 1e-6)
		and nara(o.svangAbs, math.pi / 2, 1e-6), ("netto %.4f abs %.4f"):format(o.svangNetto, o.svangAbs))
	HorseService.dismount(anna)

	--[[ Söderut med liten avvikelse åt väster, sedan åt öster: kursen går
		från nära +π till nära −π. Svängen är liten, inte ett helt varv. ]]
	local m2 = sitUpp(anna, hastA)
	avsikt(anna, m2, "driv")
	steg(hastA, vec(0, 0, 0))
	steg(hastA, vec(0.05, 0, -1))
	steg(hastA, vec(0.05, 0, -2))
	steg(hastA, vec(0, 0, -3))
	local o2 = obs(m2)
	check("omslaget vid ±π ger en liten sväng, inte 2π", o2.svangAbs < 0.2, ("abs %.4f"):format(o2.svangAbs))
	HorseService.dismount(anna)
end

print("\n── Tempojämnhet: jämn mot ojämn fart, halt, gångartsbyte ──")
do
	local m = sitUpp(anna, hastA)
	avsikt(anna, m, "driv"); avsikt(anna, m, "driv")
	local z = 0
	steg(hastA, vec(0, 0, z))
	for _ = 1, 12 do z += 2; steg(hastA, vec(0, 0, z)) end
	local jamn = obs(m).tempo
	check("jämn fart ger ingen variation", jamn.variation ~= nil and nara(jamn.variation, 0, 1e-9)
		and jamn.gangart == "trot" and jamn.n >= 8, tostring(jamn.variation))
	for i = 1, 12 do z += if i % 2 == 0 then 3 else 1; steg(hastA, vec(0, 0, z)) end
	local ojamn = obs(m).tempo
	check("ojämn fart ger tydlig variation", ojamn.variation ~= nil and ojamn.variation > 0.3,
		tostring(ojamn.variation))

	--[[ Gångartsbyte: fönstret räknar bara den senaste gångarten. ]]
	avsikt(anna, m, "broms")
	for _ = 1, 3 do z += 1; steg(hastA, vec(0, 0, z)) end
	local byte = obs(m).tempo
	check("efter byte räcker inte underlaget för den nya gångarten", byte.skal == "for_fa_prov"
		and byte.gangart == "walk", tostring(byte.skal))
	local tider = obs(m).tidPerGangart
	check("tiden delas mellan trav och skritt", (tider.trot or 0) > 0 and (tider.walk or 0) > 0)

	--[[ Halt: accepterad halt och stilla häst. ]]
	avsikt(anna, m, "broms")
	local fore = obs(m).distans
	for _ = 1, 4 do steg(hastA, vec(0, 0, z)) end
	check("halt: ingen sträcka och tempot säger ingen rörelse", obs(m).distans == fore
		and obs(m).tempo.skal == "ingen_rorelse", tostring(obs(m).tempo.skal))
	check("halttiden räknas som accepterad halt", (obs(m).tidPerGangart.halt or 0) >= 1)
	HorseService.dismount(anna)
end

print("\n── Höjd, teleport, saknad rot, lucka ──")
do
	local m = sitUpp(anna, hastA)
	avsikt(anna, m, "driv")
	steg(hastA, vec(0, 0, 0))
	for i = 1, 4 do steg(hastA, vec(0, 5 * i, 0)) end
	local o = obs(m)
	check("bara höjdled ger ingen sträcka och ingen fart", o.distans == 0 and o.maxFart == 0)
	check("men höjden räknas för sig", nara(o.hojdSumma, 20), tostring(o.hojdSumma))

	steg(hastA, vec(0, 20, 1))
	local fore = obs(m).distans
	steg(hastA, vec(0, 20, 200))                       -- teleport
	check("en teleport räknas inte som sträcka", obs(m).distans == fore and obs(m).giltighet.teleporter == 1)
	check("och ritten är inte längre obruten", obs(m).giltighet.obruten == false)
	steg(hastA, vec(0, 20, 201))
	check("nästa legitima segment räknas från det nya läget", nara(obs(m).distans, fore + 1), tostring(obs(m).distans))
	local rutt = obs(m).rutt
	check("rutten börjar ett nytt del efter hoppet", rutt[#rutt].del > rutt[1].del)

	--[[ Saknad rot: den är urkopplad under ett steg. ]]
	local r = rot(hastA)
	local foralder = r.Parent
	r.Parent = nil
	steg(hastA, nil)
	r.Parent = foralder
	check("en saknad rot räknas som saknad, inte som halt", obs(m).giltighet.saknade == 1)
	local d2 = obs(m).distans
	steg(hastA, vec(0, 20, 205))
	check("första läget efter luckan är baslinje, inte sträcka", obs(m).distans == d2)
	steg(hastA, vec(0, 20, 206))
	check("sedan räknas det igen", nara(obs(m).distans, d2 + 1))

	--[[ Icke-ändligt läge. ]]
	steg(hastA, vec(0 / 0, 20, 207))
	check("ett NaN-läge räknas som saknat", obs(m).giltighet.saknade == 2)

	--[[ Stor lucka i tid. ]]
	steg(hastA, vec(0, 20, 210))
	local d3 = obs(m).distans
	steg(hastA, vec(0, 20, 212), 5)
	check("ett steg på 5 s är en lucka utan sträcka", obs(m).giltighet.luckor == 1 and obs(m).distans == d3)
	check("och tiden räknas som oobserverad", obs(m).oobsTid >= 5)
	HorseService.dismount(anna)
end

print("\n── Klientens fart är inte evidens ──")
do
	local m = sitUpp(anna, hastA)
	avsikt(anna, m, "driv"); avsikt(anna, m, "driv")
	steg(hastA, vec(0, 0, 0))
	for _ = 1, 6 do
		Networking.get("StateSync").OnServerEvent:Fire(anna, 12)
		steg(hastA, vec(0, 0, 0))
	end
	check("StateSync säger 12 studs/s men hästen står: ingen sträcka", obs(m).distans == 0 and obs(m).maxFart == 0)
	HorseService.dismount(anna)
end

print("\n── Två ryttare, ny uppsittning, avbrott ──")
do
	RidObservation._glomForProv()
	local ma = sitUpp(anna, hastA)
	local mb = sitUpp(bea, hastB)
	avsikt(bea, mb, "driv")
	steg(hastA, vec(0, 0, 0)); flytta(hastB, vec(40, 0, 0)); RunService.Heartbeat:Fire(0.25)
	for i = 1, 4 do flytta(hastB, vec(40, 0, 2 * i)); steg(hastA, vec(0, 0, 0)) end
	check("Beas väg hamnar i hennes observation", nara(obs(mb).distans, 8), tostring(obs(mb).distans))
	check("och inte i Annas", obs(ma).distans == 0)
	check("var sin häst och ryttare", obs(mb).hastId == "cosmo" and obs(mb).userId == 302)

	HorseService.dismount(anna)
	check("avsittningen stänger som avslutad", obs(ma).oppen == false and obs(ma).satt == "avslutad")
	local tidFore = obs(ma).tid
	steg(hastA, vec(0, 0, 50))
	check("en stängd observation tar inte emot fler steg", obs(ma).tid == tidFore and obs(ma).distans == 0)

	local ny = sitUpp(anna, hastA)
	check("ny uppsittning ger en ny, tom observation", ny ~= ma and obs(ny).distans == 0 and obs(ny).tid == 0)
	anna.Character:FindFirstChildOfClass("Humanoid").Died:Fire()
	check("döden stänger som avbruten", obs(ny).oppen == false and obs(ny).satt == "avbruten")
	if HorseService.horseOf(anna) then HorseService.dismount(anna) end
	HorseService.dismount(bea)
end

print("\n── Begränsat minne och fryst bild ──")
do
	RidObservation._glomForProv()
	local m = sitUpp(anna, hastA)
	avsikt(anna, m, "driv")
	steg(hastA, vec(0, 0, 0))
	local z = 0
	for _ = 1, 1500 do z += 2.5; steg(hastA, vec(0, 0, z)) end
	local o = obs(m)
	check("rutten har ett tak", #o.rutt <= RidObservation.MAX_RUTT and o.behallet.ruttTrunkerad == true,
		tostring(#o.rutt))
	check("fönstret har ett tak", #o.fonster == RidObservation.FONSTER, tostring(#o.fonster))
	check("summorna gäller ändå hela ritten", nara(o.distans, 1500 * 2.5), tostring(o.distans))
	check("fönstret är i tidsordning", o.fonster[1].t < o.fonster[#o.fonster].t)
	check("posten är fryst", pcall(function() o.distans = 0 end) == false)
	check("rutten och fönstret är frysta", pcall(function() o.rutt[1].x = 99 end) == false
		and pcall(function() o.fonster[1].fart = 99 end) == false)
	check("en ny bild är orörd", nara(obs(m).distans, 1500 * 2.5) and obs(m).rutt[1].x ~= 99)
	HorseService.dismount(anna)

	local forsta = sitUpp(anna, hastA)
	HorseService.dismount(anna)
	for _ = 1, RidObservation.MAX_AVSLUTADE do sitUpp(anna, hastA); HorseService.dismount(anna) end
	check("den äldsta hela avslutade observationen gallras", obs(forsta) == nil
		and RidObservation.gallrade() >= 1, tostring(RidObservation.gallrade()))
end

print("\n── MODULKONTRAKT (inte produktionsväg): dt = 0 och ogiltiga dt ──")
do
	RidObservation._glomForProv()
	RidObservation.starta("k", "cosmo", 1)
	check("KONTROLL: ett giltigt första steg (baslinje)", RidObservation.sampla("k", vec(0, 0, 0), 0.25, "walk", false, 33) == false
		and RidObservation.ogonblick("k").giltighet.ogiltigaDt == 0)
	RidObservation.sampla("k", vec(0, 0, 1), 0, "walk", false, 33)
	RidObservation.sampla("k", vec(0, 0, 1), -1, "walk", false, 33)
	RidObservation.sampla("k", vec(0, 0, 1), 0 / 0, "walk", false, 33)
	local o = RidObservation.ogonblick("k")
	check("dt = 0, negativt och NaN räknas inte", o.giltighet.ogiltigaDt == 3 and o.distans == 0 and nara(o.tid, 0.25))
	check("KONTROLL: ett första avslut stänger", RidObservation.avsluta("k", "avslutad") == true)
	check("en stängd observation tar inte emot ett steg",
		RidObservation.sampla("k", vec(0, 0, 2), 0.25, "walk", false, 33) == false
			and nara(RidObservation.ogonblick("k").tid, 0.25))
	check("och stängs inte en andra gång", RidObservation.avsluta("k", "avbruten") == false
		and RidObservation.ogonblick("k").satt == "avslutad")
end

if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("\nridobservation.spec: alla gröna")
end
