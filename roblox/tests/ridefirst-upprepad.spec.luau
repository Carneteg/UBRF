--!nostrict
--[[
	UPPREPAD RITT — #290 (beslut 2026-10-04).

	Tobias fick `spel.redan_ridit` direkt efter ett lyckat «Rida nu»: passet
	från hans förra ritt stod kvar som RÄKNAT, och uppsittningen på det
	nekades. Beslutet: ett räknat pass förblir STÄNGT, men ett uttryckligt
	«Rida nu» skapar ett helt nytt förberedelse-/passpar (nytt passId) för
	hästen hon redan har. Bara `RAKNAT` släpper igenom.

	Provet driver tjänsten genom hela livscykeln med de riktiga funktionerna:
	«Rida nu» → uppsittning → avsittning → «Stallet tar hand om henne».

	Kör: python3 roblox/tests/build.py tests/ridefirst-upprepad.spec.luau
	     && luau roblox/tests/.build/ridefirst-upprepad.spec.luau
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

local Players = game:GetService("Players")
local Taggar = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local RIGG = Vector3.new(0, 0, 0)

local function nyKaraktar(pos)
	local k = Instance.new("Model")
	k.Name = "Karaktar"
	local rot = Instance.new("Part")
	rot.Name = "HumanoidRootPart"
	rot.Size = Vector3.new(2, 2, 1)
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

local function nySession(namn, userId)
	__datastore.nollstall()
	Taggar:nollstall()
	Players.PlayerAdded:nollstall()
	Players.PlayerRemoving:nollstall()
	RunService._server = true
	Players._spelare = {}
	SparService._glomHookarForProv()

	local k = nyKaraktar(Vector3.new(2, 0, 0))
	local spelare = { Name = namn, UserId = userId, Character = k,
		CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }
	SparService._glomForProv(spelare)

	SparService.start()
	StallService.start()
	HorseService.start()
	GameplayService.start()

	Players._spelare = { spelare }
	Players.PlayerAdded:Fire(spelare)
	Players.PlayerAdded:slutfor()

	local hastId = StallService.hastIdFor(spelare)
	local modell = HastRigg.bygg(hastId, hastId, CFrame.new(RIGG))
	modell.Parent = workspace
	Taggar:AddTag(modell, "Horse")
	k:FindFirstChild("HumanoidRootPart").CFrame = CFrame.new(RIGG + Vector3.new(2, 0, 0))
	return spelare, modell, hastId
end

local function stada(spelare)
	Players.PlayerRemoving:Fire(spelare)
	Players._spelare = {}
	SparService._glomForProv(spelare)
	RunService._server = false
end

--[[ «Rida nu» flyttar hästen till ridhuset, så hon går efter. Samma
	drivning som en klient som följer med. ]]
local function tillHasten(spelare, modell)
	local rot = spelare.Character:FindFirstChild("HumanoidRootPart")
	local pp = modell.PrimaryPart
	if rot and pp then
		rot.CFrame = CFrame.new(pp.Position + Vector3.new(2, 0, 0))
	end
end

local function passId(sp) return GameplayService.passFor(sp).passId end
local function lage(sp) return GameplayService.passFor(sp).lage end
local function sparatPass(sp) return SparService.save(sp).pass end

print("\n── 1. En komplett ritt blir RÄKNAD och förblir stängd ──")
local sp, modell, hastId = nySession("Upprepad", 9601)
local id1
do
	local ok, skal = GameplayService.ridaNu(sp)
	check("«Rida nu» går igenom", ok == true, tostring(skal))
	tillHasten(sp, modell)
	check("uppsittningen går igenom", (HorseService.tryMount(sp, modell)) == true)
	check("avsittningen går igenom", HorseService.dismount(sp) == true)
	local okE, skalE = GameplayService.eftervardStallet(sp)
	check("«Stallet tar hand om henne» räknar passet", okE == true, tostring(skalE))
	id1 = passId(sp)
	check("passet är RÄKNAT", lage(sp) == Pass.LAGE.RAKNAT, tostring(lage(sp)))
	check("och sparat exakt en gång", sparatPass(sp) == 1, tostring(sparatPass(sp)))
	tillHasten(sp, modell)
	local okD, skalD = GameplayService.farSittaUpp(sp, modell)
	check("direkt uppsittning på det räknade passet NEKAS fortfarande",
		okD == false and skalD == "spel.redan_ridit", tostring(skalD))
	check("tryMount utan nytt «Rida nu» nekas också", (HorseService.tryMount(sp, modell)) == false)
	check("och passet är orört av nekandet", lage(sp) == Pass.LAGE.RAKNAT and passId(sp) == id1)
end

print("\n── 2. Ett uttryckligt «Rida nu» öppnar ett NYTT pass ──")
local id2
do
	local ok, skal = GameplayService.ridaNu(sp)
	check("andra «Rida nu» går igenom", ok == true, tostring(skal))
	id2 = passId(sp)
	check("det finns ett NYTT passId", id2 ~= nil and id2 ~= id1, tostring(id1) .. " → " .. tostring(id2))
	check("nytt pass startar i FORE", lage(sp) == Pass.LAGE.FORE, tostring(lage(sp)))
	check("samma tilldelade häst", GameplayService.stateFor(sp).hastId == hastId)
	check("första ritten är kvar räknad exakt en gång; den nya är INTE räknad ännu",
		sparatPass(sp) == 1, tostring(sparatPass(sp)))
	local ok2, skal2 = GameplayService.ridaNu(sp)
	check("ett andra «Rida nu» på det redan förberedda passet rör ingenting",
		ok2 == false and skal2 == "spel.redan_redo" and passId(sp) == id2 and lage(sp) == Pass.LAGE.FORE,
		tostring(skal2))
	tillHasten(sp, modell)
	check("uppsittningen på det nya passet går igenom", (HorseService.tryMount(sp, modell)) == true)
	check("ingen spel.redan_ridit — passet är RIDER", lage(sp) == Pass.LAGE.RIDER, tostring(lage(sp)))
	check("fortfarande oräknat under ritten", sparatPass(sp) == 1, tostring(sparatPass(sp)))
end

print("\n── 3. Ofärdigt pass nollställs aldrig av «Rida nu» ──")
do
	GameplayService.ridaNu(sp)
	check("I SADELN: passId och läge orörda", passId(sp) == id2 and lage(sp) == Pass.LAGE.RIDER)
	check("avsittningen går igenom", HorseService.dismount(sp) == true)
	GameplayService.ridaNu(sp)
	check("EFTERVÅRD: passId och läge orörda", passId(sp) == id2 and lage(sp) == Pass.LAGE.EFTERVARD,
		tostring(lage(sp)))
	local p = GameplayService.passFor(sp)
	local m = Pass.nastaMoment(p)
	if m then Pass.utfor(p, m.id) end
	GameplayService.ridaNu(sp)
	check("EFTERVÅRD med påbörjat moment: oförändrad",
		passId(sp) == id2 and lage(sp) == Pass.LAGE.EFTERVARD and Pass.eftervardBorjad(p))
	--[[ KLART där skrivningen inte bekräftats: passet är redan registrerat i
		MINNESBILDEN (så `passnummer` har gått fram och ett nytt id vore
		möjligt), men `RAKNAT` sattes aldrig. Då är läget ENSAMT skyddet. ]]
	Sparning.registreraPass(SparService.save(sp), p.passId, os.time())
	p.lage = Pass.LAGE.KLART
	local fore = sparatPass(sp)
	GameplayService.ridaNu(sp)
	check("KLART utan bekräftad sparning: oförändrat", passId(sp) == id2 and lage(sp) == Pass.LAGE.KLART)
	check("och inget pass räknades av «Rida nu»", sparatPass(sp) == fore and fore == 2,
		tostring(fore) .. " → " .. tostring(sparatPass(sp)))
	p.lage = Pass.LAGE.EFTERVARD
end

print("\n── 4. Det andra passet räknas först när det genomförs ──")
do
	local okE, skalE = GameplayService.eftervardStallet(sp)
	check("«Stallet tar hand om henne» räknar andra passet", okE == true, tostring(skalE))
	check("andra passet RÄKNAT", lage(sp) == Pass.LAGE.RAKNAT and passId(sp) == id2)
	check("sparat antal är nu två — vardera ritt räknad en gång", sparatPass(sp) == 2,
		tostring(sparatPass(sp)))
	local okE2 = GameplayService.eftervardStallet(sp)
	check("en andra räkning av samma pass går inte", okE2 == false and sparatPass(sp) == 2)
end

print("\n── 5. Efter pass två: nytt pass tre, och en upprepning skapar inget fjärde ──")
local id3
do
	GameplayService.ridaNu(sp)
	id3 = passId(sp)
	check("«Rida nu» efter pass två öppnar pass tre (ny id, FORE)",
		id3 ~= id2 and id3 ~= id1 and lage(sp) == Pass.LAGE.FORE, tostring(id3))
	GameplayService.ridaNu(sp)
	check("en upprepning skapar INTE ännu ett pass", passId(sp) == id3 and lage(sp) == Pass.LAGE.FORE)
	check("och inget pass räknades", sparatPass(sp) == 2, tostring(sparatPass(sp)))
end

print("\n── 6. Välfärdsstoppet står kvar på det nya passet ──")
do
	--[[ Pass tre bär ett fynd för den här hästen (`Preparation.fyndFor` är
		deterministisk per häst och passnummer). Det nya passet får INTE bli
		en väg runt stoppet: «Rida nu» stannar på beslutet och hästen går
		inte att sitta upp på. ]]
	local s3 = GameplayService.stateFor(sp)
	check("förutsättning: det nya passets förberedelse bär ett fynd", s3.fynd ~= nil, tostring(s3.fynd))
	local ok, skal = GameplayService.ridaNu(sp)
	check("«Rida nu» stannar på det öppna fyndet (fail closed)",
		ok == false and skal == "forb.oppet_fynd", tostring(skal))
	tillHasten(sp, modell)
	check("och hästen går inte att sitta upp på", (HorseService.tryMount(sp, modell)) == false)
	check("ingen sadel lades på", not TackService.harTack(modell, "sadel"))
end

stada(sp)

print("")
if fails > 0 then
	print(string.format("%d mätning(ar) föll.", fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("ridefirst-upprepad.spec: alla gröna")
end
