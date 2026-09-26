--!nostrict
--[[
	RIDFÖRSÖKEN — #264 INFRA-FORSOK1.

	KOHERENS-bänken: det riktiga ridhuset, `HorseService.start()`, riktiga
	uppsittningar (`tryMount`), riktiga hjärtslag genom observationerna och
	riktiga avslut (`dismount`, `DismountRequest`, `Died`, `PlayerRemoving`,
	avregistrering via taggen). Försöken nås bara genom HorseServices
	server-API: `startaForsok`, `avbrytForsok`, `forsok`, `forsokVolt`.

	EVIDENSNIVÅ: BANK_ONLY. Ingen motor, ingen klient.
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

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Taggar = game:GetService("CollectionService")
local vec = Vector3.new
local TAU = 2 * math.pi

local hus = workspace:FindFirstChild("Anläggning"):FindFirstChild("UBRF")
local RP = Ridhusplats.los(hus)
assert(RP, "ridhuset ska gå att lösa")

Taggar:nollstall()
RunService._server = true
RunService.Heartbeat:nollstall()
HorseService.setMountGate(nil)
HorseService.start()

--[[ Spioner: inget i försöken får skriva till sparningen. ]]
local sparAnrop = 0
for _, namn in ipairs({ "noteraForsok", "registreraResultat", "registreraPris", "registreraPass", "satSkada" }) do
	local fn = Sparning[namn]
	Sparning[namn] = function(...) sparAnrop += 1; return fn(...) end
end
local skrivFn = SparService.skriv
SparService.skriv = function(...) sparAnrop += 1; return skrivFn(...) end
local lagerSkriv0 = __datastore.forsok and __datastore.forsok.skriv or 0

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
local function nySpelare(namn, id)
	return { Name = namn, UserId = id, Character = nyKaraktar(), CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }
end
local anna = nySpelare("Anna", 701)
local bea = nySpelare("Bea", 702)
local cecilia = nySpelare("Cecilia", 703)
Players._spelare = { anna, bea, cecilia }

local HOJD
local function lage(u, v)
	local p = Ridhusplats.tillVarld(RP, vec(u, 0, v))
	return vec(p.X, HOJD, p.Z)
end

local hastA = HastRigg.bygg("forsok_a", "Försök A", CFrame.new(Ridhusplats.tillVarld(RP, vec(0, 0, 10))))
hastA.Parent = workspace
Taggar:AddTag(hastA, "Horse")
local hastB = HastRigg.bygg("forsok_b", "Försök B", CFrame.new(Ridhusplats.tillVarld(RP, vec(5, 0, 50))))
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
	sess(m).energi = 1
	RunService.Heartbeat:Fire(dt or 0.25)
end
local function sitUpp(sp, m, hem)
	hem = hem or lage(0, 10)
	flytta(m, hem)
	local kr = sp.Character:FindFirstChild("HumanoidRootPart")
	kr.Position = hem + vec(6, 0, 0)
	kr.CFrame = CFrame.new(hem + vec(6, 0, 0))
	local ok, skal, marke = HorseService.tryMount(sp, m)
	assert(ok, "uppsittningen föll: " .. tostring(skal))
	sess(m).energi = 1
	return marke
end
local CU, CV, R, N = 0, 30, 10, 36
local function varv(m, rikt)
	steg(m, lage(CU + R, CV), 5)
	for i = 1, N do
		local a = rikt * TAU * i / N
		steg(m, lage(CU + R * math.cos(a), CV + R * math.sin(a)))
	end
end
local function antal() return RidForsok._antalForProv() end
local function fryst(t) return pcall(function() t.tillstand = "x" end) == false end

print("\n── Fri ridning: inga försök ──")
local m1
do
	local r0, f0 = antal()
	m1 = sitUpp(anna, hastA)
	varv(hastA, 1)
	local r1, f1 = antal()
	check("uppsittning och ridning skapar inget försök", f1 == f0 and r1 == r0 + 1,
		("ritter %d → %d, försök %d → %d"):format(r0, r1, f0, f1))
	check("ingen aktivt försök i den fria ritten", RidForsok.aktivt(m1) == nil)
	check("KONTROLL: voltmätningen gick (ett varv i fri ridning)", HorseService.volt(m1).pagar.varv == 1)
end

print("\n── Nekas utan mutation ──")
do
	local _, f0 = antal()
	local function nej(namn, skalVantat, ok, skal, id)
		check(namn, ok == false and skal == skalVantat and id == nil, tostring(skal))
	end
	nej("en spelare som inte rider", "forsok.ingen_ritt", HorseService.startaForsok(bea, m1, 1, "storvolt", "server-referens-1"))
	nej("ingen spelare", "forsok.ingen_ritt", HorseService.startaForsok(nil, m1, 1, "storvolt", "server-referens-1"))
	nej("ett påhittat rittId", "forsok.fel_ritt", HorseService.startaForsok(anna, "r-falsk", 1, "storvolt", "server-referens-1"))
	nej("rittId saknas", "forsok.fel_ritt", HorseService.startaForsok(anna, nil, 1, "storvolt", "server-referens-1"))
	nej("klientens storvolt v1 är en annan definition", "forsok.okand_definition",
		HorseService.startaForsok(anna, m1, 1, "storvolt", 1))
	nej("okänd övning", "forsok.okand_definition", HorseService.startaForsok(anna, m1, 2, "slalom", "server-referens-1"))
	nej("sekvens 0", "forsok.ogiltig_sekvens", HorseService.startaForsok(anna, m1, 0, "storvolt", "server-referens-1"))
	nej("sekvens 3,5", "forsok.ogiltig_sekvens", HorseService.startaForsok(anna, m1, 3.5, "storvolt", "server-referens-1"))
	nej("sekvens NaN", "forsok.ogiltig_sekvens", HorseService.startaForsok(anna, m1, 0 / 0, "storvolt", "server-referens-1"))
	nej("sekvens som text", "forsok.ogiltig_sekvens", HorseService.startaForsok(anna, m1, "3", "storvolt", "server-referens-1"))
	local _, f1 = antal()
	check("inga försök skapades av nejen", f1 == f0 and RidForsok.aktivt(m1) == nil)
end

print("\n── Start under accepterad ritt, dubblett och retry ──")
local f1
do
	--[[ Sekvens 1 och 2 användes av nejen ovan (definitionsnejen minns
		sina utfall). Starten tar 13, så att 3–12 blir äldre och oanvända. ]]
	local ok, skal, id = HorseService.startaForsok(anna, m1, 13, "storvolt", "server-referens-1")
	f1 = id
	check("start: ok med servergenererat forsokId", ok == true and skal == nil and type(id) == "string", tostring(skal))
	local b = HorseService.forsok(id)
	check("identitet ur HorseService: ritt, häst, ryttare", b.rittId == m1 and b.hastId == "forsok_a" and b.userId == 701)
	check("övning och definition", b.ovning == "storvolt" and b.definition == "server-referens-1")
	check("tillstånd aktivt, ingen bedömning, inget resultatfält", b.tillstand == "aktivt" and b.bedomning == "ingen"
		and b.resultat == nil and b.slut == nil and b.orsak == nil)
	check("startmarkören: ändlig ritt-tid och voltens högsta avsnitt", type(b.start.t) == "number" and b.start.t == b.start.t
		and b.start.t > 0 and b.start.voltHogsta == HorseService.volt(m1).pagar.nr, ("t %s, högsta %s"):format(
		tostring(b.start.t), tostring(b.start.voltHogsta)))
	check("bilden är fryst", fryst(b) and pcall(function() b.start.t = 0 end) == false)

	local ok2, _, id2 = HorseService.startaForsok(anna, m1, 13, "storvolt", "server-referens-1")
	check("retry med samma sekvens: samma forsokId, inget nytt", ok2 == true and id2 == f1 and select(2, antal()) == 1)
	local ok3, skal3, id3 = HorseService.startaForsok(anna, m1, 14, "storvolt", "server-referens-1")
	check("ett aktivt per ritt: en ny start nekas och pekar på det aktiva", ok3 == false
		and skal3 == "forsok.redan_aktivt" and id3 == f1, tostring(skal3))
	local ok4, skal4 = HorseService.startaForsok(anna, m1, 2, "storvolt", "server-referens-1")
	check("en äldre sekvens ger sitt gamla utfall (definitionsnejet), inget nytt", ok4 == false
		and skal4 == "forsok.okand_definition", tostring(skal4))
end

print("\n── Voltdata från före starten tillskrivs inte försöket ──")
do
	--[[ Ett helt varv reds FÖRE starten, i ett avsnitt som fortfarande
		pågår. Det avsnittet innehåller data från före starten. ]]
	local fore = HorseService.volt(m1).pagar
	local lista, fel = HorseService.forsokVolt(f1)
	check("det pågående avsnittet vid starten tillskrivs inte", fel == nil and #lista == 0, tostring(fel))
	--[[ Fortsätter i samma avsnitt: fortfarande inte försökets. ]]
	for i = 1, N do
		local a = TAU * i / N
		steg(hastA, lage(CU + R * math.cos(a), CV + R * math.sin(a)))
	end
	check("KONTROLL: samma avsnitt, nu två varv", HorseService.volt(m1).pagar.nr == fore.nr
		and HorseService.volt(m1).pagar.varv == 2)
	lista = HorseService.forsokVolt(f1)
	check("att fortsätta i det avsnittet gör det inte till försökets", #lista == 0)
	--[[ Ett nytt avsnitt efter starten: det kan tillskrivas. ]]
	varv(hastA, -1)
	lista = HorseService.forsokVolt(f1)
	check("ett avsnitt som började efter starten tillskrivs", #lista == 1 and lista[1].nr > fore.nr
		and lista[1].varv == 1 and lista[1].riktning == "negativ")
	check("urvalet är fryst och bara ett urval (ingen ny beräkning)", pcall(function() lista[1] = nil end) == false
		and lista[1] == HorseService.volt(m1).pagar)
end

print("\n── Avbryt, retry och en gammal begäran ──")
do
	local ok, skal, id = HorseService.avbrytForsok(anna, m1, 15, f1)
	local b = HorseService.forsok(f1)
	check("avbryt: stängt med orsak, slutmarkör efter start", ok == true and id == f1 and b.tillstand == "stangt"
		and b.orsak == "avbrutet" and b.slut.t >= b.start.t and b.slut.voltHogsta >= b.start.voltHogsta, tostring(skal))
	check("ett stängt försök är inte godkänt", b.bedomning == "ingen" and b.resultat == nil)
	local ok2, _, id2 = HorseService.avbrytForsok(anna, m1, 15, f1)
	check("retry av avbrytet: samma utfall, samma bild", ok2 == true and id2 == f1 and HorseService.forsok(f1) == b)
	local ok3, skal3 = HorseService.avbrytForsok(anna, m1, 16, f1)
	check("ett nytt avbryt av ett stängt försök nekas", ok3 == false and skal3 == "forsok.redan_stangt", tostring(skal3))
	local ok4, _, id4 = HorseService.startaForsok(anna, m1, 13, "storvolt", "server-referens-1")
	check("den gamla startbegäran efter stängningen: samma stängda försök, inget nytt", ok4 == true and id4 == f1
		and RidForsok.aktivt(m1) == nil and HorseService.forsok(f1).tillstand == "stangt")
	local ok5, skal5 = HorseService.startaForsok(anna, m1, 5, "storvolt", "server-referens-1")
	check("en äldre okänd sekvens är inaktuell", ok5 == false and skal5 == "forsok.inaktuell_begaran", tostring(skal5))
	local ok6, skal6 = HorseService.avbrytForsok(anna, m1, 17, "f-falsk")
	check("avbryt av ett okänt försök", ok6 == false and skal6 == "forsok.okant", tostring(skal6))

	--[[ Dublettminnet är begränsat: efter MAX_BEGARAN nyare begäranden
		är sekvens 13 gallrad och därmed inaktuell — den öppnar ändå inget. ]]
	for s = 18, 18 + RidForsok.MAX_BEGARAN do HorseService.startaForsok(anna, m1, s, "okand", "x") end
	local ok7, skal7 = HorseService.startaForsok(anna, m1, 13, "storvolt", "server-referens-1")
	check("gallrad dublett: inaktuell, inget nytt försök", ok7 == false and skal7 == "forsok.inaktuell_begaran"
		and RidForsok.aktivt(m1) == nil, tostring(skal7))
end

print("\n── Ritten stänger försöket: nekad och accepterad avsittning ──")
local f2
do
	local ok, _, id = HorseService.startaForsok(anna, m1, 100, "storvolt", "server-referens-1")
	f2 = id
	check("ett nytt försök i samma ritt efter det stängda", ok == true and id ~= f1)
	local tak = Skopa.GRANSER.DismountRequest.tak
	for _ = 1, tak do Skopa.slapp(anna, "DismountRequest") end
	local dr = Networking.get("DismountRequest")
	local okA, skalA = dr.OnServerInvoke(anna)
	check("KONTROLL: avsittningen nekas av takten", okA == false and skalA == "takt.for_snabbt", tostring(skalA))
	check("nekad avsittning: försöket är kvar och aktivt", HorseService.forsok(f2).tillstand == "aktivt"
		and RidForsok.aktivt(m1) ~= nil and hastA:GetAttribute("RidSession") == m1)
	steg(hastA, lage(0, 12))
	local okD = HorseService.dismount(anna)
	local b = HorseService.forsok(f2)
	check("accepterad avsittning stänger försöket", okD == true and b.tillstand == "stangt"
		and b.orsak == "ritt_slut:avsittning" and b.slut.t >= b.start.t, tostring(b.orsak))
	check("exakt en gång: ett andra ritt-slut ändrar ingenting",
		RidForsok.rittSlut(m1, "dog", 999, nil) == false and HorseService.forsok(f2) == b)
	local okG, skalG = HorseService.startaForsok(anna, m1, 101, "storvolt", "server-referens-1")
	check("den stängda ritten tar inte emot en start", okG == false and skalG == "forsok.ingen_ritt", tostring(skalG))
end

print("\n── Död, lämnande, avregistrering, återuppsittning ──")
do
	local function fall(namn, orsak, gor)
		local m = sitUpp(anna, hastA)
		local _, _, id = HorseService.startaForsok(anna, m, 1, "storvolt", "server-referens-1")
		gor(m)
		local b = HorseService.forsok(id)
		check(namn .. ": stängt med orsak", b and b.tillstand == "stangt" and b.orsak == "ritt_slut:" .. orsak,
			b and tostring(b.orsak))
		if HorseService.horseOf(anna) then HorseService.dismount(anna) end
		check(namn .. ": fortfarande samma stängda bild", HorseService.forsok(id) == b)
		return m, id
	end
	fall("döden", "dog", function() anna.Character:FindFirstChildOfClass("Humanoid").Died:Fire() end)
	fall("spelaren lämnar", "lamnar", function() Players.PlayerRemoving:Fire(anna) end)
	fall("hästen avregistreras", "hast_avregistrerad", function() Taggar:RemoveTag(hastA, "Horse") end)
	Taggar:AddTag(hastA, "Horse")

	local mGammal, idGammal = fall("avsittning före återuppsittning", "avsittning", function() HorseService.dismount(anna) end)
	local mNy = sitUpp(anna, hastA)
	check("återuppsittning är en ny ritt utan aktivt försök", mNy ~= mGammal and RidForsok.aktivt(mNy) == nil)
	local okS, skalS = HorseService.startaForsok(anna, mGammal, 50, "storvolt", "server-referens-1")
	check("den gamla rittens id nekas (inaktuell ritt)", okS == false and skalS == "forsok.fel_ritt", tostring(skalS))
	check("det gamla försöket återupplivas inte", HorseService.forsok(idGammal).tillstand == "stangt")
	HorseService.dismount(anna)
end

print("\n── Två ryttare ──")
do
	local ma = sitUpp(anna, hastA)
	local mb = sitUpp(bea, hastB, lage(5, 50))
	local _, _, fa = HorseService.startaForsok(anna, ma, 1, "storvolt", "server-referens-1")
	local _, _, fb = HorseService.startaForsok(bea, mb, 1, "storvolt", "server-referens-1")
	check("var sitt försök, var sin identitet", fa ~= fb and HorseService.forsok(fa).userId == 701
		and HorseService.forsok(fb).userId == 702 and HorseService.forsok(fb).hastId == "forsok_b")
	local okX, skalX = HorseService.startaForsok(anna, mb, 2, "storvolt", "server-referens-1")
	check("annan spelares ritt nekas", okX == false and skalX == "forsok.fel_ritt", tostring(skalX))
	local okY, skalY = HorseService.avbrytForsok(bea, mb, 2, fa)
	check("annan spelares försök kan inte avbrytas", okY == false and skalY == "forsok.okant"
		and HorseService.forsok(fa).tillstand == "aktivt", tostring(skalY))
	local okZ, skalZ = HorseService.avbrytForsok(cecilia, ma, 1, fa)
	check("en spelare som inte rider kan inte avbryta", okZ == false and skalZ == "forsok.ingen_ritt")
	HorseService.dismount(anna)
	check("den enas avsittning rör inte den andras försök", HorseService.forsok(fa).tillstand == "stangt"
		and HorseService.forsok(fb).tillstand == "aktivt")
	HorseService.dismount(bea)
end

print("\n── Gallrad historik, minnestak och ring ──")
do
	local m = sitUpp(anna, hastA)
	local _, _, id = HorseService.startaForsok(anna, m, 1, "storvolt", "server-referens-1")
	for _ = 1, VoltObservation.MAX_AVSNITT + 3 do
		steg(hastA, lage(0, 11)); steg(hastA, lage(0, 12)); steg(hastA, lage(0, 12), 5)
	end
	local lista, fel = HorseService.forsokVolt(id)
	check("försökets första avsnitt är gallrat: tydligt fel, ingen lista", lista == nil
		and fel == "forsok.historik_gallrad", tostring(fel))
	check("ett okänt försök", select(2, HorseService.forsokVolt("f-falsk")) == "forsok.okant")
	HorseService.avbrytForsok(anna, m, 2, id)
	local forsta
	for s = 3, 3 + 2 * RidForsok.MAX_PER_RITT, 2 do
		local _, _, fid = HorseService.startaForsok(anna, m, s, "storvolt", "server-referens-1")
		forsta = forsta or fid
		HorseService.avbrytForsok(anna, m, s + 1, fid)
	end
	check("högst MAX_PER_RITT försök per ritt: det äldsta är gallrat", HorseService.forsok(id) == nil
		and HorseService.forsok(forsta) == nil)
	HorseService.dismount(anna)
	for _ = 1, RidForsok.MAX_AVSLUTADE + 5 do
		sitUpp(anna, hastA)
		HorseService.dismount(anna)
	end
	local r, f = antal()
	check("ritterna i en ring", r <= RidForsok.MAX_AVSLUTADE + 2, ("%d ritter, %d försök"):format(r, f))
	check("gallrade ritters försök är borta", HorseService.forsok(f1) == nil and HorseService.forsok(f2) == nil)
end

print("\n── Ingen sparning, inget resultat ──")
do
	check("inga anrop till Sparning/SparService", sparAnrop == 0, tostring(sparAnrop))
	check("inga skrivningar till lagret", (__datastore.forsok and __datastore.forsok.skriv or 0) == lagerSkriv0)
end

if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
end
print("\nALLA FÖRSÖKSMÄTNINGAR OK")
