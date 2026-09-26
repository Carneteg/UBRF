--!nostrict
--[[
	VOLTOBSERVATIONEN — #264 INFRA-VOLT1.

	KOHERENS-bänken, samma väg som ridplatsen: `Anlaggningen` bygger
	ridhuset, `HorseService.start()` startar bryggorna, och varje steg går
	`Heartbeat` → `stepStamina` → `RidObservation.sampla` →
	`RidPlatsObservation.sampla` → `VoltObservation.sampla`. Bilden läses
	genom `HorseService.volt`. Rotens läge flyttas i ridhusets ram (meter).

	Bara vakter som inte går att nå genom produktionsvägen prövas direkt på
	modulen (dubbel bild, fel ritt, icke ändliga koordinater, ramskifte
	utan mellanliggande brott). De är märkta DIREKT.

	TOLERANSER: ändpunkterna ligger exakt på cirkeln, så en regelbunden
	N-hörning har varje kordas mittpunkt på R·cos(π/N) — radialavvikelsen
	är då exakt R·(1 − cos(π/N)) och prövas med 1e-6. Vinkelsumman är
	exakt 2π per varv; prövas med 1e-6.

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
local function f(x) return if x == nil then "nil" else ("%.6f"):format(x) end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Taggar = game:GetService("CollectionService")
local vec = Vector3.new
local TAU = 2 * math.pi
local R = VoltObservation.RADIE

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
local anna = { Name = "Anna", UserId = 601, Character = nyKaraktar(), CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }
local bea = { Name = "Bea", UserId = 602, Character = nyKaraktar(), CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }
Players._spelare = { anna, bea }

local HOJD
local ram = RP
local function lage(u, v)
	local p = Ridhusplats.tillVarld(ram, vec(u, 0, v))
	return vec(p.X, HOJD, p.Z)
end

local hastA = HastRigg.bygg("volt_a", "Volt A", CFrame.new(Ridhusplats.tillVarld(RP, vec(0, 0, 10))))
hastA.Parent = workspace
Taggar:AddTag(hastA, "Horse")
local hastB = HastRigg.bygg("volt_b", "Volt B", CFrame.new(Ridhusplats.tillVarld(RP, vec(5, 0, 50))))
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
	flytta(m, hem)
	local kr = sp.Character:FindFirstChild("HumanoidRootPart")
	kr.Position = hem + vec(6, 0, 0)
	kr.CFrame = CFrame.new(hem + vec(6, 0, 0))
	local ok, skal, marke = HorseService.tryMount(sp, m)
	assert(ok, "uppsittningen föll: " .. tostring(skal))
	sess(m).energi = 1
	return marke
end
local function bild(marke) return HorseService.volt(marke) end

local marke = sitUpp(anna, hastA, lage(0, 10))
steg(hastA, lage(0, 10)); steg(hastA, lage(0, 11))
local mitt = HorseService.ridplats(marke).dressyrMitt
local CU, CV = mitt.u, mitt.v

--[[ Ett nytt avsnitt: en lucka (brott) i startläget, sedan rörelse. ]]
local function nytt(m, u, v)
	steg(m, lage(u, v), 5)
end
--[[ Punkter på en cirkel från vinkeln `a0`, `n` steg per varv, `varv`
	varv (får vara bråk), tecken `rikt`. `dtAv(i)` ger stegets dt. ]]
local function cirkel(m, cu, cv, r, n, varv, rikt, a0, dtAv)
	a0 = a0 or 0
	nytt(m, cu + r * math.cos(a0), cv + r * math.sin(a0))
	local steg_n = math.floor(n * varv + 0.5)
	for i = 1, steg_n do
		local a = a0 + rikt * TAU * i / n
		steg(m, lage(cu + r * math.cos(a), cv + r * math.sin(a)), dtAv and dtAv(i) or 0.25)
	end
end
local function pagar(mk) return bild(mk).pagar end
local function avslutaAvsnitt(m)
	--[[ En lucka stänger det pågående avsnittet så att det kan läsas
		bland de avslutade. ]]
	steg(m, nil, 5)
end
local function senast(mk)
	local av = bild(mk).avslutade
	return av[#av]
end

print("\n── Identitet och referens ──")
do
	local b = bild(marke)
	check("övning och egen version", b.ovning == "storvolt" and b.version == "server-referens-1"
		and b.version ~= RidKanon.INSPELNING.OVNING.storvolt.version)
	check("klientens definition är orörd (version 1)", RidKanon.INSPELNING.OVNING.storvolt.version == 1)
	check("ritt, häst och ryttare", b.rittId == marke and b.hastId == "volt_a" and b.userId == 601)
	check("radien ur RidKanon (10 m)", R == RidKanon.UGNETA.KVALITET.VOLT_RADIE and R == 10)
	check("referensens centrum är dressyrlayoutens mitt: mitt på bredden, 30 m från A",
		nara(CU, 0, 1e-6) and nara(CV, 30, 1e-6), ("u %s v %s"):format(f(CU), f(CV)))
	check("enheter redovisade", b.enheter.langd == "m" and b.enheter.vinkel == "rad")
end

print("\n── Hel cirkel åt båda hållen ──")
local N = 36
local bias = R * (1 - math.cos(math.pi / N))
do
	cirkel(hastA, CU, CV, R, N, 1, 1)
	local p = pagar(marke)
	check("positiv: ett varv, nettot 2π", p.varv == 1 and nara(p.netto, TAU, 1e-6) and p.riktning == "positiv",
		f(p.netto))
	check("positiv: avvikelse = kordans R(1−cos π/N), sträckviktad", nara(p.medelAvvikelse, bias, 1e-6)
		and nara(p.rmsAvvikelse, bias, 1e-6) and nara(p.maxAvvikelse, bias, 1e-6), f(p.medelAvvikelse))
	check("positiv: återkomst till start", nara(p.aterkomst, 0, 1e-6) and p.motriktning == 0)
	check("positiv: tid och sträcka", nara(p.tid, N * 0.25, 1e-9)
		and nara(p.stracka, N * 2 * R * math.sin(math.pi / N), 1e-6), f(p.tid) .. " " .. f(p.stracka))
	check("positiv: tillräckligt underlag", p.underlag == "tillrackligt" and #p.skal == 0
		and p.status == "pagar" and p.referens.radie == R and nara(p.referens.v, CV, 1e-9))
	check("positiv: ramen står i avsnittet", p.ramId == HorseService.ridplats(marke).ramId)

	cirkel(hastA, CU, CV, R, N, 1, -1)
	local q = pagar(marke)
	check("negativ: ett varv, nettot −2π", q.varv == 1 and nara(q.netto, -TAU, 1e-6) and q.riktning == "negativ",
		f(q.netto))
	check("negativ: samma avvikelse", nara(q.medelAvvikelse, bias, 1e-6))
	check("det förra avsnittet avslutades av luckan", senast(marke).varv == 1
		and senast(marke).slut == "brott" and senast(marke).status == "avslutat")

	cirkel(hastA, CU, CV, R, N, 2, 1)
	check("två varv räknas som två", pagar(marke).varv == 2 and nara(pagar(marke).netto, 2 * TAU, 1e-6))
	cirkel(hastA, CU, CV, R, N, 1 - 1 / N, 1)
	check("ett steg kvar till varvet: inget varv", pagar(marke).varv == 0)
end

print("\n── Fel referens och fel form ──")
do
	cirkel(hastA, CU, CV + 6, R, N, 1, 1)
	local p = pagar(marke)
	--[[ Samma radie, centrum 6 m fel: referensens mitt ligger innanför
		den ridna cirkeln, så den går ett varv RUNT referensen — men
		avvikelsen avslöjar platsen. Ingen cirkel anpassas till rutten. ]]
	check("rätt radie, fel centrum: stor avvikelse", p.medelAvvikelse > 2 and p.maxAvvikelse > 5,
		f(p.medelAvvikelse))
	check("rätt radie, fel centrum: varvet runt referensen syns ändå (inget omdöme)", p.varv == 1)

	cirkel(hastA, CU, CV, 6, N, 1, 1)
	local q = pagar(marke)
	check("fel radie (6 m): avvikelse ≈ 4 m", nara(q.medelAvvikelse, R - 6 * math.cos(math.pi / N), 1e-6),
		f(q.medelAvvikelse))

	nytt(hastA, 5, 10)
	for i = 1, 20 do steg(hastA, lage(5, 10 + 2 * i)) end
	local rak = pagar(marke)
	check("rak passage förbi centrum: under ett halvt varv, inget varv", rak.varv == 0
		and math.abs(rak.netto) < math.pi and rak.motriktning == 0, f(rak.netto))
	check("rak passage: sträcka 40 m", nara(rak.stracka, 40, 1e-6))

	nytt(hastA, CU + R, CV)
	for _ = 1, 12 do steg(hastA, lage(CU + R, CV)) end
	local still = pagar(marke)
	check("stillastående: otillräckligt, inga mått", still.underlag == "otillrackligt"
		and still.skal[1] == "for_lite_rorelse" and still.medelAvvikelse == nil and still.varv == nil
		and still.netto == nil and still.riktning == nil, still.underlag)
	check("stillastående: tid och segment redovisas ändå", nara(still.tid, 12 * 0.25, 1e-9)
		and still.segment == 12 and still.stracka == 0)

	nytt(hastA, CU + R, CV)
	steg(hastA, lage(CU + R, CV + 1.5)); steg(hastA, lage(CU + R, CV + 3))
	local kort = pagar(marke)
	check("kort avsnitt (2 segment, 0,5 s): otillräckligt, inga mått", kort.underlag == "otillrackligt"
		and kort.skal[1] == "for_kort" and kort.medelAvvikelse == nil and kort.netto == nil
		and kort.segment == 2 and nara(kort.stracka, 3, 1e-6), kort.underlag)

	cirkel(hastA, CU, CV, R, N, 0.5, 1)
	check("halvvarv: π, inget varv", pagar(marke).varv == 0 and nara(pagar(marke).netto, math.pi, 1e-6))

	--[[ Fram och tillbaka: 8 × (+90°, −90°). Beloppssumman är 8π — en
		absolutvinkel skulle ge fyra varv. ]]
	nytt(hastA, CU + R, CV)
	for _ = 1, 8 do
		for i = 1, 9 do local a = TAU * i / N; steg(hastA, lage(CU + R * math.cos(a), CV + R * math.sin(a))) end
		for i = 8, 0, -1 do local a = TAU * i / N; steg(hastA, lage(CU + R * math.cos(a), CV + R * math.sin(a))) end
	end
	local fb = pagar(marke)
	check("fram och tillbaka: netto 0, inget varv", fb.varv == 0 and nara(fb.netto, 0, 1e-6), f(fb.netto))
	check("fram och tillbaka: motriktningen redovisas (4π)", nara(fb.motriktning, 4 * math.pi, 1e-6),
		f(fb.motriktning))

	--[[ Alternerande delbågar som går framåt: 5 × (+120°, −60°) = +300°
		netto; beloppen summerar till 900°. ]]
	nytt(hastA, CU + R, CV)
	local k = 0
	for _ = 1, 5 do
		for _ = 1, 12 do k += 1; local a = TAU * k / N; steg(hastA, lage(CU + R * math.cos(a), CV + R * math.sin(a))) end
		for _ = 1, 6 do k -= 1; local a = TAU * k / N; steg(hastA, lage(CU + R * math.cos(a), CV + R * math.sin(a))) end
	end
	local alt = pagar(marke)
	check("alternerande delbågar: +300° netto, inget varv", alt.varv == 0
		and nara(alt.netto, TAU * 30 / N, 1e-6) and nara(alt.motriktning, TAU * 30 / N, 1e-6), f(alt.netto))
end

print("\n── Vinkelomslag, centrum, dt och täthet ──")
do
	cirkel(hastA, CU, CV, R, N, 1, 1, math.pi - 0.05)
	check("start strax före ±π: exakt ett varv", pagar(marke).varv == 1 and nara(pagar(marke).netto, TAU, 1e-6),
		f(pagar(marke).netto))
	cirkel(hastA, CU, CV, R, N, 1, -1, -math.pi)
	check("start på −π, negativ: exakt ett varv", pagar(marke).varv == 1 and nara(pagar(marke).netto, -TAU, 1e-6))

	--[[ Rakt genom centrum: segmentet som korsar mitten har ingen
		bestämd vinkel och får ingen påhittad kurs. ]]
	nytt(hastA, CU, CV - 10)
	for i = 1, 20 do steg(hastA, lage(CU, CV - 10 + i)) end
	--[[ R1: kedjan bryts vid centrum. Tre avsnitt: före (bestämd vinkel,
		netto 0), vid centrum (okänt, två obestämda segment) och efter (en
		ny kedja från noll). Inget av dem har en vinkel som spänner över
		centrum. ]]
	local av = bild(marke).avslutade
	local fore, vid, efter = av[#av - 1], av[#av], pagar(marke)
	check("genom centrum: kedjan före slutar vid centrum, netto 0", fore.slut == "obestamd_vinkel"
		and fore.obestamda == 0 and nara(fore.netto, 0, 1e-9) and fore.varv == 0, tostring(fore.slut))
	check("genom centrum: två obestämda segment i ett eget okänt avsnitt utan mått", vid.obestamda == 2
		and vid.segment == 2 and vid.underlag == "okant" and vid.slut == "vinkel_bestamd_igen"
		and vid.netto == nil and vid.varv == nil and vid.medelAvvikelse == nil, vid.underlag)
	check("genom centrum: efteråt en ny kedja från noll", efter.obestamda == 0 and efter.nr == vid.nr + 1
		and nara(efter.netto, 0, 1e-9) and efter.underlag == "tillrackligt")

	--[[ Ett segment vars ändpunkter ligger utanför R_MIN men som passerar
		genom mitten: närmaste punkten avgör. ]]
	nytt(hastA, CU - 1.5, CV)
	steg(hastA, lage(CU + 1.5, CV), 0.4)
	check("korda genom mitten, ändar utanför R_MIN: obestämd", pagar(marke).obestamda == 1
		and pagar(marke).netto == nil)

	cirkel(hastA, CU, CV, 0.5, 12, 1, 1)
	local liten = pagar(marke)
	check("liten cirkel runt centrum: okänt, ingen vinkel och inget varv", liten.underlag == "okant"
		and liten.skal[1] == "for_nara_centrum" and liten.varv == nil and liten.netto == nil, liten.underlag)

	--[[ HorseService samlar hjärtslagen till steg om minst 0,25 s (4 Hz),
		så ett kortare dt når aldrig observationen som eget steg. Varierande
		dt prövas därför över det spann som faktiskt når den: 0,25–0,7 s
		(under ridobservationens lucka, 1,0 s). ]]
	local dts = { 0.25, 0.4, 0.7 }
	local tidSumma = 0
	for i = 1, 72 do tidSumma += dts[(i - 1) % 3 + 1] end
	cirkel(hastA, CU, CV, R, 72, 1, 1, 0.3, function(i) return dts[(i - 1) % 3 + 1] end)
	local v = pagar(marke)
	check("varierande dt: ett varv, tiden summerad", v.varv == 1 and nara(v.netto, TAU, 1e-6)
		and nara(v.tid, tidSumma, 1e-9), f(v.tid))
	check("tät provtagning (72): avvikelsen följer kordan", nara(v.medelAvvikelse, R * (1 - math.cos(math.pi / 72)), 1e-6))
	cirkel(hastA, CU, CV, R, 24, 1, 1, 0, function() return 0.4 end)
	local gles = pagar(marke)
	check("gles provtagning (24): ett varv, avvikelsen följer kordan", gles.varv == 1
		and nara(gles.medelAvvikelse, R * (1 - math.cos(math.pi / 24)), 1e-6), f(gles.medelAvvikelse))
	check("KONTROLL: inga teleportsteg i proven ovan", HorseService.ridobservation(marke).giltighet.teleporter == 0,
		tostring(HorseService.ridobservation(marke).giltighet.teleporter))
end

print("\n── R1: obruten vinkelevidens — okänd vinkel är inte noll vinkel ──")
do
	--[[ Codex reproduktioner (#5847071180), genom HorseService. Varje
		bestämd båge är högst ett halvt varv; ett helt varv har aldrig
		ridits obrutet. Inget avsnitt får alltså rapportera ett varv. ]]
	local function punkt(r, a) return lage(CU + r * math.cos(a), CV + r * math.sin(a)) end
	local function ingetVarv(namn, forsta)
		local b = bild(marke)
		local maxVarv, maxNetto = 0, 0
		for _, a in ipairs(b.avslutade) do
			if a.nr >= forsta then
				maxVarv = math.max(maxVarv, a.varv or 0)
				maxNetto = math.max(maxNetto, math.abs(a.netto or 0))
			end
		end
		if b.pagar then
			maxVarv = math.max(maxVarv, b.pagar.varv or 0)
			maxNetto = math.max(maxNetto, math.abs(b.pagar.netto or 0))
		end
		check(namn .. ": inget avsnitt har ett varv, inget netto över π", maxVarv == 0
			and maxNetto <= math.pi + 1e-6, ("varv %d, netto %s"):format(maxVarv, f(maxNetto)))
	end
	--[[ Numret som nästa avsnitt får: ett mer än det högsta hittills. ]]
	local function forstaNr()
		local b, hog = bild(marke), 0
		for _, a in ipairs(b.avslutade) do hog = math.max(hog, a.nr) end
		if b.pagar then hog = math.max(hog, b.pagar.nr) end
		return hog + 1
	end

	--[[ 1 och 2: halvcirkel (18 steg à 10°) och tillbaka längs diametern i
		1 m-steg, två gånger, åt båda hållen. ]]
	for _, rikt in ipairs({ 1, -1 }) do
		nytt(hastA, CU + R, CV)
		local nr0 = forstaNr()
		for _ = 1, 2 do
			for i = 1, 18 do steg(hastA, punkt(R, rikt * math.pi * i / 18)) end
			for x = -R + 1, R do steg(hastA, lage(CU + x, CV)) end
		end
		steg(hastA, nil, 5)
		ingetVarv(("halvcirkel + diameter (%s)"):format(if rikt > 0 then "positiv" else "negativ"), nr0)
		local b = bild(marke)
		local okanda = 0
		for _, a in ipairs(b.avslutade) do if a.nr >= nr0 and a.underlag == "okant" then okanda += 1 end end
		check(("halvcirkel + diameter (%s): varje centrumpassage är ett okänt avsnitt"):format(
			if rikt > 0 then "positiv" else "negativ"), okanda == 2, tostring(okanda))
	end

	--[[ 3: yttre positiv halvcirkel, radiellt in till 0,5 m, inre negativ
		halvcirkel (R 0,5) i 18 steg, radiellt ut, 100 stillaprov; två
		gånger. Den geometriska nettovinkeln är 0. ]]
	nytt(hastA, CU + R, CV)
	local nr3 = forstaNr()
	for _ = 1, 2 do
		for i = 1, 18 do steg(hastA, punkt(R, math.pi * i / 18)) end
		for x = R - 1, 1, -1 do steg(hastA, lage(CU - x, CV)) end
		steg(hastA, lage(CU - 0.5, CV))
		for i = 1, 18 do steg(hastA, punkt(0.5, math.pi - math.pi * i / 18)) end
		for x = 1, R do steg(hastA, lage(CU + x, CV)) end
		for _ = 1, 100 do steg(hastA, lage(CU + R, CV)) end
	end
	ingetVarv("yttre + inre halvcirkel + stillhet", nr3)

	--[[ Stillhet späder inte: 200 stillaprov på volten efter ett halvvarv
		ger inte ett varv, och stillaprov vid centrum är okänt. ]]
	cirkel(hastA, CU, CV, R, N, 0.5, 1)
	for _ = 1, 200 do steg(hastA, lage(CU - R, CV)) end
	local still = pagar(marke)
	check("stillhet på volten: fortfarande π, inget varv", still.varv == 0 and nara(still.netto, math.pi, 1e-6)
		and still.segment == 18 + 200, f(still.netto))
	nytt(hastA, CU + 0.3, CV)
	for _ = 1, 20 do steg(hastA, lage(CU + 0.3, CV)) end
	check("stillhet vid centrum: okänt, inga mått", pagar(marke).underlag == "okant" and pagar(marke).netto == nil)

	--[[ Verklig återhämtning: efter centrum ut till volten och ett helt,
		obrutet varv — då och först då ett varv, i en ny kedja. ]]
	for x = 1, R do steg(hastA, lage(CU + x, CV)) end
	local nrUt = pagar(marke).nr
	for i = 1, N - 1 do steg(hastA, punkt(R, TAU * i / N)) end
	check("återhämtning: ett steg före helt varv — inget varv", pagar(marke).varv == 0)
	steg(hastA, punkt(R, TAU))
	local ater = pagar(marke)
	check("återhämtning: helt obrutet varv efter centrum räknas i den nya kedjan", ater.varv == 1
		and ater.nr == nrUt and ater.obestamda == 0 and ater.riktning == "positiv", f(ater.netto))
	check("återhämtning: centrumstycket stängdes som okänt", senast(marke).underlag == "okant"
		and senast(marke).slut == "vinkel_bestamd_igen")
end

print("\n── Brott mitt i bågen: inget bryggas ──")
local bana = hus:FindFirstChild("Ridbanan")
local lay = hus:FindFirstChild("Dressyrlayout 20x60")
do
	local function halvOchBrott(namn, brott, aterstall, slutVantat)
		cirkel(hastA, CU, CV, R, N, 0.5, 1)
		local fore = pagar(marke)
		check(namn .. ": KONTROLL halvt varv före", fore and nara(fore.netto, math.pi, 1e-6))
		brott()
		local b = bild(marke)
		check(namn .. ": avsnittet avslutat med skäl", b.pagar == nil and senast(marke).slut == slutVantat
			and senast(marke).nr == fore.nr, tostring(senast(marke).slut))
		if aterstall then aterstall() end
		--[[ Resten av varvet efter brottet. ]]
		for i = N / 2 + 1, N do
			local a = TAU * i / N
			steg(hastA, lage(CU + R * math.cos(a), CV + R * math.sin(a)))
		end
		local e = pagar(marke)
		--[[ Nettot kan bli något över π när ramen flyttats: resten av
			varvet mäts då runt den nya ramens referens. Kravet är att de två
			halvorna aldrig blir ett varv. ]]
		check(namn .. ": återhämtning — ett nytt avsnitt, halvorna summeras inte", e ~= nil and e.nr > fore.nr
			and (e.varv == nil or e.varv == 0) and (e.netto == nil or e.netto < 1.1 * math.pi), e and f(e.netto))
	end
	local mittA = function() local a = math.pi; return lage(CU + R * math.cos(a), CV + R * math.sin(a)) end
	halvOchBrott("lucka", function() steg(hastA, mittA(), 5) end, nil, "brott")
	halvOchBrott("saknad rot", function()
		local r = sess(hastA).rig.root
		local fo = r.Parent
		r.Parent = nil
		steg(hastA, nil)
		r.Parent = fo
	end, nil, "brott")
	halvOchBrott("teleport", function() steg(hastA, lage(CU, CV + 25)); steg(hastA, mittA(), 5) end, nil, "brott")
	halvOchBrott("ogiltig plats (förankring)", function()
		lay:SetAttribute("Forankring", "C")
		steg(hastA, mittA())
	end, function() lay:SetAttribute("Forankring", "A") end, "ingen_plats:fel_forankring")
	halvOchBrott("metadata: banans id", function()
		bana:SetAttribute("PlatsId", "annat")
		steg(hastA, mittA())
	end, function() bana:SetAttribute("PlatsId", "ridhus_bana") end, "ingen_plats:saknas:ridhus_bana")
	local d = vec(0, 0, 0.3)
	halvOchBrott("ramen flyttad", function()
		bana.CFrame = CFrame.new(bana.Position + d)
		lay.CFrame = CFrame.new(lay.Position + d)
		steg(hastA, mittA())
	end, nil, "ram_ny")
	bana.CFrame = CFrame.new(bana.Position - d)
	lay.CFrame = CFrame.new(lay.Position - d)
	steg(hastA, lage(0, 10), 5)
	check("KONTROLL: ramen tillbaka på sin plats", HorseService.ridplats(marke).punkt ~= nil)
end

print("\n── Gemensam girning och flytt av ramen ──")
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
	ram = rp
	steg(hastA, lage(0, 10), 5); steg(hastA, lage(0, 11))
	local vm = HorseService.ridplats(marke).dressyrMitt
	check("vriden ram: referensen i ramens egna meter", nara(vm.u, CU, 1e-6) and nara(vm.v, CV, 1e-6),
		("u %s v %s"):format(f(vm.u), f(vm.v)))
	cirkel(hastA, vm.u, vm.v, R, N, 1, 1)
	local p = pagar(marke)
	check("vriden ram: samma varv, vinkel och avvikelse som ovriden", p.varv == 1 and nara(p.netto, TAU, 1e-6)
		and nara(p.medelAvvikelse, bias, 1e-6), f(p.medelAvvikelse))
	cirkel(hastA, vm.u, vm.v, R, N, 1, -1)
	check("vriden ram: negativt håll", pagar(marke).varv == 1 and pagar(marke).riktning == "negativ")
	RidPlatsObservation.satModell(hus)
	ram = RP
	m:Destroy()
	steg(hastA, lage(0, 10), 5); steg(hastA, lage(0, 11))
end

print("\n── DIREKT: vakter som produktionsvägen inte når ──")
do
	local id = "direkt_prov"
	local pbId = id
	VoltObservation.starta(id, "h", 1)
	local function pb(t, fu, fv, tu, tv, ramId, cu, cv)
		return table.freeze({
			rittId = pbId, status = "segment", ramId = ramId or 1, t = t,
			dressyrMitt = table.freeze({ u = cu or 0, h = 0, v = cv or 30 }),
			segment = table.freeze({ fran = table.freeze({ u = fu, h = 0, v = fv }), till = table.freeze({ u = tu, h = 0, v = tv }) }),
		})
	end
	local b1 = pb(0.25, 10, 30, 10, 31)
	VoltObservation.sampla(id, b1)
	VoltObservation.sampla(id, b1)
	check("DIREKT: samma bild två gånger räknas en gång", VoltObservation.ogonblick(id).pagar.segment == 1)
	local fel = table.freeze({ rittId = "annan", status = "segment", ramId = 1, t = 0.5,
		dressyrMitt = b1.dressyrMitt, segment = b1.segment })
	VoltObservation.sampla(id, fel)
	check("DIREKT: en annan ritts bild räknas inte", VoltObservation.ogonblick(id).pagar.segment == 1)
	VoltObservation.sampla(id, pb(0.5, 10, 31, 0 / 0, 32))
	check("DIREKT: icke ändlig koordinat avslutar avsnittet", VoltObservation.ogonblick(id).pagar == nil
		and VoltObservation.ogonblick(id).avslutade[1].slut == "ogiltigt_segment")
	VoltObservation.sampla(id, pb(0.75, 10, 30, 10, 31, 1))
	VoltObservation.sampla(id, pb(1.0, 10, 31, 10, 32, 2))
	local o = VoltObservation.ogonblick(id)
	check("DIREKT: ramskifte utan mellanliggande brott avslutar avsnittet", o.pagar.segment == 1
		and o.pagar.ramId == 2 and o.avslutade[2].slut == "ram_eller_referens_bytt")
	VoltObservation.sampla(id, pb(1.25, 10, 32, 10, 33, 2, 0.5, 30))
	o = VoltObservation.ogonblick(id)
	check("DIREKT: referensbyte i samma ram avslutar avsnittet", o.pagar.segment == 1
		and o.pagar.referens.u == 0.5 and o.avslutade[3].slut == "ram_eller_referens_bytt")
	VoltObservation.avsluta(id, "avslutad")
	local stangd = VoltObservation.ogonblick(id)
	check("DIREKT: en stängd ritt tar inte emot en bild", VoltObservation.sampla(id, pb(2, 10, 33, 10, 34, 2)) == false
		and VoltObservation.ogonblick(id) == stangd and stangd.pagar == nil)

	--[[ Referensens u är 0 i båda verkliga ramarna; en referens flyttad
		i u-led visar att båda koordinaterna används. ]]
	local id2 = "direkt_u"
	VoltObservation.starta(id2, "h", 1)
	pbId = id2
	for i = 1, N do
		local a0, a1 = TAU * (i - 1) / N, TAU * i / N
		VoltObservation.sampla(id2, pb(i * 0.25, 5 + R * math.cos(a0), 30 + R * math.sin(a0),
			5 + R * math.cos(a1), 30 + R * math.sin(a1), 1, 5, 30))
	end
	local u5 = VoltObservation.ogonblick(id2).pagar
	check("DIREKT: referens i (5, 30) — cirkeln runt den är ett varv med kordans avvikelse", u5.varv == 1
		and nara(u5.medelAvvikelse, bias, 1e-6) and u5.referens.u == 5, f(u5.medelAvvikelse))
	VoltObservation.avsluta(id2, "avslutad")
end

print("\n── KEDJAN utan Heartbeat: ogiltigt dt ──")
do
	--[[ Ogiltigt dt når aldrig observationen genom HorseService (4 Hz-
		ackumulatorn släpper bara igenom steg ≥ 0,25 s). Det prövas därför
		genom samma tre moduler i samma ordning som `stepStamina`, på en
		egen ritt: RidObservation → RidPlatsObservation → VoltObservation. ]]
	local id = "kedja_dt"
	RidObservation.starta(id, "h", 1); RidPlatsObservation.starta(id, "h", 1); VoltObservation.starta(id, "h", 1)
	local function kedja(i, dt)
		local a = TAU * i / N
		local pos = lage(CU + R * math.cos(a), CV + R * math.sin(a))
		local _, st, fr, t = RidObservation.sampla(id, pos, dt, "walk", false, 33)
		RidPlatsObservation.sampla(id, st, fr, pos, t)
		VoltObservation.sampla(id, RidPlatsObservation.ogonblick(id))
	end
	for i = 0, N / 2 do kedja(i, 0.25) end
	local fore = VoltObservation.ogonblick(id).pagar
	check("KEDJA: KONTROLL halvt varv före", fore and nara(fore.netto, math.pi, 1e-6))
	kedja(N / 2, 0)
	local b = VoltObservation.ogonblick(id)
	check("KEDJA: ogiltigt dt avslutar avsnittet", b.pagar == nil and b.avslutade[1].slut == "brott")
	for i = N / 2, N do kedja(i, 0.25) end
	local e = VoltObservation.ogonblick(id).pagar
	check("KEDJA: halvorna summeras inte", e.nr == 2 and e.varv == 0, f(e.netto))
	RidObservation.avsluta(id, "avslutad"); RidPlatsObservation.avsluta(id, "avslutad"); VoltObservation.avsluta(id, "avslutad")
end

print("\n── Två ryttare, stängd ritt, frysning, minne ──")
do
	local mb = sitUpp(bea, hastB, lage(CU + R, CV))
	nytt(hastA, CU + R, CV); flytta(hastB, lage(CU + R, CV)); RunService.Heartbeat:Fire(5)
	for i = 1, N do
		local a = TAU * i / N
		flytta(hastA, lage(CU + R * math.cos(a), CV + R * math.sin(a)))
		flytta(hastB, lage(CU + R * math.cos(-a), CV + R * math.sin(-a)))
		sess(hastA).energi = 1; sess(hastB).energi = 1
		RunService.Heartbeat:Fire(0.25)
	end
	check("två ryttare: var sitt varv åt var sitt håll", pagar(marke).varv == 1 and pagar(marke).riktning == "positiv"
		and pagar(mb).varv == 1 and pagar(mb).riktning == "negativ" and bild(mb).userId == 602)

	local gammal = bild(marke)
	steg(hastA, lage(CU + R, CV + 1))
	check("en äldre bild är orörd och fryst", gammal.pagar.segment == N
		and pcall(function() gammal.status = "x" end) == false
		and pcall(function() gammal.pagar.varv = 9 end) == false
		and pcall(function() gammal.avslutade[1] = nil end) == false
		and pcall(function() gammal.pagar.referens.radie = 1 end) == false)

	cirkel(hastA, CU, CV, R, N, 0.5, 1)
	HorseService.dismount(anna)
	local s = bild(marke)
	check("avsittningen stänger bilden och avsnittet", s.status == "stangd" and s.pagar == nil
		and s.avslutade[#s.avslutade].slut == "ritten_slut" and s.satt == "avslutad", tostring(s.satt))
	local antal = #s.avslutade
	steg(hastA, lage(CU, CV + R))
	check("en stängd ritt tar inte emot fler steg", bild(marke).status == "stangd" and #bild(marke).avslutade == antal)
	HorseService.dismount(bea)

	local ny = sitUpp(anna, hastA, lage(0, 10))
	check("ny uppsittning: ny bild utan observation", ny ~= marke and bild(ny).status == "ingen_observation"
		and bild(ny).pagar == nil and #bild(ny).avslutade == 0)
	steg(hastA, lage(0, 10))
	for _ = 1, VoltObservation.MAX_AVSNITT + 4 do
		steg(hastA, lage(0, 11)); steg(hastA, lage(0, 12)); steg(hastA, lage(0, 12), 5)
	end
	check("minnestak: högst MAX_AVSNITT avslutade avsnitt per ritt",
		#bild(ny).avslutade == VoltObservation.MAX_AVSNITT, tostring(#bild(ny).avslutade))
	anna.Character:FindFirstChildOfClass("Humanoid").Died:Fire()
	check("döden stänger som avbruten", bild(ny).status == "stangd" and bild(ny).satt == "avbruten")
	if HorseService.horseOf(anna) then HorseService.dismount(anna) end
	for _ = 1, VoltObservation.MAX_AVSLUTADE + 5 do
		sitUpp(anna, hastA, lage(0, 10))
		HorseService.dismount(anna)
	end
	check("livscykeltillståndet är begränsat", VoltObservation._antalRitterForProv() <= VoltObservation.MAX_AVSLUTADE + 2,
		tostring(VoltObservation._antalRitterForProv()))
end

if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
end
print("\nALLA VOLTMÄTNINGAR OK")
