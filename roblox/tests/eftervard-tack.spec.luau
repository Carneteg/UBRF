--!nostrict
--[[
	EFTERVÅRDENS UTRUSTNING — sadeln och tränset ska FAKTISKT komma av
	hästen när eftervårdens moment görs, serverauktoritärt (#211).

	══ VAD SOM SAKNADES ═════════════════════════════════════════════════

	`GameplayService.eftervard` kvitterade "Ta av sadeln" och "Ta av
	tränset" i passet — men rörde aldrig hästen. `TackService.taAvAllt`
	fanns ("används när passet avslutas") utan en enda anropare. Efter en
	fullständig, räknad dag stod hästen alltså kvar sadlad och tränsad i
	världen, medan passet påstod att hon var omhändertagen.

	══ VAD KANON SÄGER ══════════════════════════════════════════════════

	`src/spel/skotsel.js` EFTERVARD, i ordning:

	  gjord   "Lossa gjorden — Låt sadeln ligga kvar."
	  sadel   "Ta av sadeln — Ta av sadel och underlägg."
	  trans   "Ta av tränset — Grimma på först, sedan tränset av."
	  ben, vatten

	Att ta av är alltså MANUELLA moment, inte något som sker av sig
	självt vid avsittningen. Regeln här bevarar den sanningen: avtagningen
	sker i momentet, av spelaren, vid hästen — och ingenting tas av
	vid en avsittning som inte är eftervård.

	Kanon säger också "sadeln av innan tränset". Tjänstens avtagningsspärr
	stod TVÄRTOM (sadeln nekades under tränset, med skälet
	`tack.transet_forst`) och gjorde kanonordningen omöjlig. Provet mäter
	ordningen som kanon skriver den.

	══ VAD SOM MÄTS ═════════════════════════════════════════════════════

	  1. Giltig avtagning: gjord lämnar allt på; sadel tar sadel + underlägg
	     (tränset kvar); trans tar träns + tyglar; ben/vatten räknar passet
	     och lämnar hästen tom. Tillstånd och värld säger samma sak i varje
	     steg — `harTack` läser världen, och mappen är tom på slutet.
	  2. Idempotens: samma moment två gånger är `pass.redan_gjort` utan att
	     något ändras på hästen.
	  3. Fel spelare / fel häst: en andra spelares eftervård kan inte ta av
	     den förstas häst, och hennes eget pass rubbas inte.
	  4. Ogiltigt/ofullständigt: under ritt, fel tur, för långt bort och
	     före ritt lämnar utrustningen orörd med rätt skäl.
	  5. Transient avsittning/återuppsittning innan eftervården börjat
	     lämnar utrustningen på.
	  6. Välfärdsstopp: passet räknas utan att någon utrustning ligger kvar.

	Bänkgräns: `CollectionService:GetInstanceAddedSignal` dispatchar inte
	i stubbarna, så `GameplayService.bind` anropas direkt — samma funktion
	kroken anropar. Uppsittning/avsittning går genom `HorseService`, så
	riderkroken driver passet på produktionens väg.

	Kör: python3 roblox/tests/build.py tests/eftervard-tack.spec.luau
	     && luau roblox/tests/.build/eftervard-tack.spec.luau
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
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local function gorFas(state, fasId, hastId)
	local ok, skal, arg = Preparation.provaSteg(state, fasId, hastId)
	if not ok then return false, skal, arg end
	while true do
		local m = Preparation.nastaMoment(state, fasId)
		if not m then break end
		local mok, mskal, marg = Preparation.utforMoment(state, fasId, m.id, hastId)
		if not mok then return false, mskal, marg end
	end
	return true, nil
end

--[[ Karaktär vid en given plats, med humanoid — det `tryMount` och
	närvaroregeln behöver. ]]
local function nyKaraktar(namn, cf)
	local k = Instance.new("Model")
	k.Name = namn
	local rot = Instance.new("Part")
	rot.Name = "HumanoidRootPart"
	rot.Size = Vector3.new(2, 2, 1)
	rot.CFrame = cf
	rot.Parent = k
	local h = Instance.new("Humanoid")
	h.Name = "Humanoid"
	h.Parent = k
	k.Parent = workspace
	return k, rot
end

--[[ Servern startad tom: tjänsterna igång, ingen spelare inne. ]]
local function startaServer()
	__datastore.nollstall()
	RunService._server = true
	Players.PlayerAdded:nollstall()
	Players.PlayerRemoving:nollstall()
	CollectionService:nollstall()
	SparService._glomHookarForProv()
	Players._spelare = {}
	SparService.start()
	StallService.start()
	HorseService.start()
	GameplayService.start()
end

--[[ En spelare in på en startad server, hela dagen fram till
	uppsittningen: riggen byggd och taggad, karaktären vid hästen,
	skötseln gjord och utrustningen fysiskt på. Returnerar allt provet
	behöver. Flera spelare kan läggas till på samma server — det är så
	fel-häst-fallet mäts. ]]
local function laggTill(namn, userId, offsetX)
	local spelare = { Name = namn, UserId = userId,
		CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }
	SparService._glomForProv(spelare)
	table.insert(Players._spelare, spelare)
	Players.PlayerAdded:Fire(spelare)

	local hastId = StallService.hastIdFor(spelare)
	check(namn .. " har en tilldelad häst", hastId ~= nil, tostring(hastId))
	local modell = HastRigg.bygg(hastId, tostring(hastId),
		CFrame.new(Vector3.new(offsetX or 0, 0, 0)))
	modell.Parent = workspace
	CollectionService:AddTag(modell, "Horse")
	check("taggen registrerade hästen i HorseService", HorseService.sessionFor(modell) ~= nil)

	local k, rot = nyKaraktar(namn .. "Kropp", modell.PrimaryPart.CFrame * CFrame.new(3, 0, 0))
	spelare.Character = k
	GameplayService.bind(spelare)
	check(namn .. " är bunden till SIN modell", GameplayService.modellFor(spelare) == modell)

	local st = GameplayService.stateFor(spelare)
	for _, f in ipairs(Preparation.stegFaser()) do
		local ok, skal = gorFas(st, f.id, hastId)
		check("fasen " .. f.id .. " går att göra", ok, tostring(skal))
	end
	for _, typ in ipairs({ "underlagg", "sadel", "trans" }) do
		local tok, tskal = TackService.satPa(spelare, modell, typ, nil, modell)
		check("utrustningen " .. typ .. " går på", tok, tostring(tskal))
	end
	check("hon är ridklar", TackService.ridklar(modell))

	return { spelare = spelare, modell = modell, rot = rot, hastId = hastId,
		pass = GameplayService.passFor(spelare) }
end

local function nyDag(namn, userId, offsetX)
	startaServer()
	return laggTill(namn, userId, offsetX)
end

local function pa(modell)
	local ut = {}
	for _, typ in ipairs({ "underlagg", "sadel", "trans", "tygel" }) do
		if TackRigg.hittaDel(modell, typ) ~= nil then table.insert(ut, typ) end
	end
	return table.concat(ut, ",")
end

local function ridOchSittAv(D)
	local okUpp, skalUpp = HorseService.tryMount(D.spelare, D.modell)
	check("uppsittningen går genom HorseService", okUpp, tostring(skalUpp))
	check("passet står i RIDER", D.pass.lage == Pass.LAGE.RIDER, tostring(D.pass.lage))
	local okAv, skalAv = HorseService.dismount(D.spelare)
	check("avsittningen går genom HorseService", okAv, tostring(skalAv))
	check("passet står i EFTERVÅRD", D.pass.lage == Pass.LAGE.EFTERVARD, tostring(D.pass.lage))
	--[[ Avsittningen kan flytta karaktären; ställ henne vid hästen igen
		så att närvaroregeln mäter momentet och inte placeringen. ]]
	D.rot.CFrame = D.modell.PrimaryPart.CFrame * CFrame.new(3, 0, 0)
end

--[[ ══ 1. GILTIG AVTAGNING, moment för moment ══════════════════════ ]]
print("\n── 1. Eftervårdens moment tar FAKTISKT av utrustningen ──")
do
	local D = nyDag("Eftervard", 9401)
	ridOchSittAv(D)
	check("ANKARE: allt sitter på efter avsittningen — avsittning är inte avtagning",
		pa(D.modell) == "underlagg,sadel,trans,tygel", pa(D.modell))

	local ok1, s1 = GameplayService.eftervard(D.spelare, "gjord")
	check("gjord: går", ok1, tostring(s1))
	check("gjord: sadeln ligger kvar", pa(D.modell) == "underlagg,sadel,trans,tygel", pa(D.modell))

	local ok2, s2 = GameplayService.eftervard(D.spelare, "sadel")
	check("sadel: går", ok2, tostring(s2))
	check("sadel: sadel OCH underlägg är av, tränset kvar",
		pa(D.modell) == "trans,tygel", pa(D.modell))
	check("sadel: tjänsten läser samma sak ur världen",
		not TackService.sadlad(D.modell) and not TackService.harTack(D.modell, "underlagg")
			and TackService.transad(D.modell))
	check("sadel: momentet är kvitterat i passet", D.pass.gjorda.sadel == true)

	local ok3, s3 = GameplayService.eftervard(D.spelare, "trans")
	check("trans: går", ok3, tostring(s3))
	check("trans: träns och tyglar är av", pa(D.modell) == "", pa(D.modell))
	check("trans: utrustningsmappen är tom", TackRigg.mapp(D.modell) == nil
		or #TackRigg.mapp(D.modell):GetChildren() == 0)

	local ok4, s4 = GameplayService.eftervard(D.spelare, "ben")
	check("ben: går", ok4, tostring(s4))
	local ok5, s5 = GameplayService.eftervard(D.spelare, "vatten")
	check("vatten: går", ok5, tostring(s5))
	check("passet är RÄKNAT", D.pass.lage == Pass.LAGE.RAKNAT, tostring(D.pass.lage))
	check("och hästen står tom i världen", pa(D.modell) == "", pa(D.modell))
	check("uppsittning nekas efter dagen",
		select(1, GameplayService.farSittaUpp(D.spelare, D.modell)) == false)
end

--[[ ══ 2. IDEMPOTENS ══════════════════════════════════════════════ ]]
print("\n── 2. Samma moment två gånger ändrar ingenting ──")
do
	local D = nyDag("Dubbel", 9402)
	ridOchSittAv(D)
	GameplayService.eftervard(D.spelare, "gjord")
	local ok1, s1 = GameplayService.eftervard(D.spelare, "sadel")
	check("sadel: första gången går", ok1, tostring(s1))
	local fore = pa(D.modell)
	local ok2, s2 = GameplayService.eftervard(D.spelare, "sadel")
	check("sadel: andra gången är `pass.redan_gjort`",
		ok2 == false and s2 == "pass.redan_gjort", tostring(s2))
	check("och hästen är oförändrad", pa(D.modell) == fore, pa(D.modell))
	check("och passet står kvar i eftervården",
		D.pass.lage == Pass.LAGE.EFTERVARD and D.pass.gjorda.trans == nil)
	local ok3, s3 = GameplayService.eftervard(D.spelare, "gjord")
	check("gjord igen är också `pass.redan_gjort`",
		ok3 == false and s3 == "pass.redan_gjort", tostring(s3))
	check("och tränset sitter fortfarande på", TackService.transad(D.modell))
end

--[[ ══ 3. FEL SPELARE / FEL HÄST ══════════════════════════════════ ]]
print("\n── 3. En annan spelare kan inte ta av MIN häst ──")
do
	--[[ Två spelare på samma server, två hästar, båda i eftervården med
		gjorden lossad. B ställer sig intill A:s häst — så nära att en
		tjänst som läste "närmaste häst" hade hittat den — och skickar
		"Ta av sadeln". Bara B:s egen häst får ändras. ]]
	local A = nyDag("Agare", 9403, 0)
	local B = laggTill("Granne", 9404, 60)
	check("de rider olika hästar", A.modell ~= B.modell and A.hastId ~= B.hastId,
		tostring(A.hastId) .. " / " .. tostring(B.hastId))
	ridOchSittAv(A)
	ridOchSittAv(B)
	GameplayService.eftervard(A.spelare, "gjord")
	GameplayService.eftervard(B.spelare, "gjord")
	check("båda står i eftervården med gjorden lossad",
		A.pass.gjorda.gjord and B.pass.gjorda.gjord)

	--[[ B intill A:s häst, långt från sin egen. ]]
	B.rot.CFrame = A.modell.PrimaryPart.CFrame * CFrame.new(-3, 0, 0)
	local foreA, foreB = pa(A.modell), pa(B.modell)
	local okB, sB = GameplayService.eftervard(B.spelare, "sadel")
	check("B:s `sadel` intill A:s häst nekas (B är inte vid SIN häst)",
		okB == false and sB == "spel.for_langt", tostring(sB))
	check("A:s häst är orörd", pa(A.modell) == foreA, pa(A.modell))
	check("B:s häst är orörd", pa(B.modell) == foreB, pa(B.modell))
	check("A:s pass är orört", A.pass.gjorda.sadel == nil)
	check("B:s pass är orört", B.pass.gjorda.sadel == nil)

	--[[ B tillbaka vid sin egen: nu går momentet, och det är B:s sadel
		som försvinner — inte A:s. ]]
	B.rot.CFrame = B.modell.PrimaryPart.CFrame * CFrame.new(3, 0, 0)
	local okB2, sB2 = GameplayService.eftervard(B.spelare, "sadel")
	check("B:s `sadel` vid sin egen häst går", okB2, tostring(sB2))
	check("B:s häst är avsadlad", pa(B.modell) == "trans,tygel", pa(B.modell))
	check("A:s häst är FORTFARANDE sadlad", pa(A.modell) == foreA, pa(A.modell))
	check("A:s pass är fortfarande orört", A.pass.gjorda.sadel == nil)

	--[[ Och A tar av sin egen. ]]
	local okA, sA = GameplayService.eftervard(A.spelare, "sadel")
	check("A får ta av sin sadel", okA, tostring(sA))
	check("och nu är A:s häst avsadlad", pa(A.modell) == "trans,tygel", pa(A.modell))
	check("utan att B:s ändrats", pa(B.modell) == "trans,tygel", pa(B.modell))
end

--[[ ══ 4. OGILTIGT / OFULLSTÄNDIGT ════════════════════════════════ ]]
print("\n── 4. Ogiltiga försök lämnar utrustningen på ──")
do
	local D = nyDag("Ogiltig", 9405)
	local ALLT = "underlagg,sadel,trans,tygel"

	--[[ a) FÖRE RITTEN. ]]
	local okF, sF = GameplayService.eftervard(D.spelare, "sadel")
	check("a) före ritten nekas med `pass.inte_dags`",
		okF == false and sF == "pass.inte_dags", tostring(sF))
	check("   och allt sitter på", pa(D.modell) == ALLT, pa(D.modell))

	--[[ b) UNDER RITTEN. ]]
	local okUpp, skalUpp = HorseService.tryMount(D.spelare, D.modell)
	check("uppsittningen går", okUpp, tostring(skalUpp))
	local okR, sR = GameplayService.eftervard(D.spelare, "sadel")
	check("b) under ritten nekas med `pass.sitt_av_forst`",
		okR == false and sR == "pass.sitt_av_forst", tostring(sR))
	check("   och allt sitter på", pa(D.modell) == ALLT, pa(D.modell))
	HorseService.dismount(D.spelare)
	D.rot.CFrame = D.modell.PrimaryPart.CFrame * CFrame.new(3, 0, 0)

	--[[ c) FEL TUR: sadeln före gjorden. ]]
	local okT, sT = GameplayService.eftervard(D.spelare, "sadel")
	check("c) sadeln före gjorden nekas med `pass.fel_tur`",
		okT == false and sT == "pass.fel_tur", tostring(sT))
	check("   och allt sitter på", pa(D.modell) == ALLT, pa(D.modell))

	--[[ d) TRÄNSET FÖRE SADELN — kanon: "sadeln av innan tränset". ]]
	GameplayService.eftervard(D.spelare, "gjord")
	local okO, sO = GameplayService.eftervard(D.spelare, "trans")
	check("d) tränset före sadeln nekas (fel tur)", okO == false and sO == "pass.fel_tur",
		tostring(sO))
	check("   och tränset sitter på", TackService.transad(D.modell) and TackService.sadlad(D.modell))

	--[[ e) FÖR LÅNGT BORT. ]]
	D.rot.CFrame = D.modell.PrimaryPart.CFrame * CFrame.new(40, 0, 0)
	local okL, sL = GameplayService.eftervard(D.spelare, "sadel")
	check("e) på 40 studs nekas med `spel.for_langt`",
		okL == false and sL == "spel.for_langt", tostring(sL))
	check("   och sadeln sitter på", TackService.sadlad(D.modell), pa(D.modell))
	check("   och momentet är inte kvitterat", D.pass.gjorda.sadel == nil)
	D.rot.CFrame = D.modell.PrimaryPart.CFrame * CFrame.new(3, 0, 0)

	--[[ f) OKÄNT MOMENT och fel typ. ]]
	local okX, sX = GameplayService.eftervard(D.spelare, "hovar")
	check("f) okänt moment nekas", okX == false and sX == "pass.okant_moment", tostring(sX))
	local okY, sY = GameplayService.eftervard(D.spelare, 42)
	check("   icke-sträng nekas", okY == false and sY == "spel.ogiltigt_steg", tostring(sY))
	check("   och allt sitter på", pa(D.modell) == ALLT, pa(D.modell))

	--[[ g) OFULLSTÄNDIG: sadeln av, men passet är inte klart — hästen
		ska stå tränsad, inte tom, och passet får inte räknas. ]]
	local okS, sS = GameplayService.eftervard(D.spelare, "sadel")
	check("g) sadeln av går", okS, tostring(sS))
	check("   tränset sitter kvar tills sitt moment", pa(D.modell) == "trans,tygel", pa(D.modell))
	check("   passet är INTE räknat", D.pass.lage == Pass.LAGE.EFTERVARD, tostring(D.pass.lage))
	local okAvsl, sAvsl = GameplayService.avslutaPass(D.spelare)
	check("   och kan inte avslutas i förtid", okAvsl == false, tostring(sAvsl))
end

--[[ ══ 5. TRANSIENT AVSITTNING ════════════════════════════════════ ]]
print("\n── 5. Av och upp igen innan eftervården börjat rör inte utrustningen ──")
do
	local D = nyDag("Transient", 9406)
	ridOchSittAv(D)
	check("efter första avsittningen sitter allt på",
		pa(D.modell) == "underlagg,sadel,trans,tygel", pa(D.modell))
	local okUpp, skalUpp = HorseService.tryMount(D.spelare, D.modell)
	check("hon får sitta upp igen (eftervården är inte börjad)", okUpp, tostring(skalUpp))
	check("passet står i RIDER igen", D.pass.lage == Pass.LAGE.RIDER, tostring(D.pass.lage))
	HorseService.dismount(D.spelare)
	D.rot.CFrame = D.modell.PrimaryPart.CFrame * CFrame.new(3, 0, 0)
	--[[ Dubbel avsittning — samma väg som Occupant-lyssnaren kan ta. ]]
	HorseService.dismount(D.spelare)
	check("efter andra avsittningen sitter fortfarande allt på",
		pa(D.modell) == "underlagg,sadel,trans,tygel", pa(D.modell))
	check("och hon är fortfarande ridklar", TackService.ridklar(D.modell))
end

--[[ ══ 6. VÄLFÄRDSSTOPP ═══════════════════════════════════════════ ]]
print("\n── 6. Ett välfärdsstopp lämnar ingen utrustning kvar ──")
do
	--[[ Stoppet kommer ur skötselns fynd, alltså FÖRE utrustningen sitter
		på. Passet räknas utan ritt, och hästen får inte stå med något på:
		det som mäts är att avslutet sveper världen — inte att ett fynd
		går att tvinga fram här. ]]
	__datastore.nollstall()
	RunService._server = true
	Players.PlayerAdded:nollstall()
	Players.PlayerRemoving:nollstall()
	CollectionService:nollstall()
	SparService._glomHookarForProv()
	local spelare = { Name = "Stopp", UserId = 9407,
		CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }
	Players._spelare = {}
	SparService._glomForProv(spelare)
	SparService.start(); StallService.start(); HorseService.start(); GameplayService.start()
	Players._spelare = { spelare }
	Players.PlayerAdded:Fire(spelare)
	local hastId = StallService.hastIdFor(spelare)
	local modell = HastRigg.bygg(hastId, tostring(hastId), CFrame.new(Vector3.new(0, 0, 0)))
	modell.Parent = workspace
	CollectionService:AddTag(modell, "Horse")
	local _, rot = nyKaraktar("StoppKropp", modell.PrimaryPart.CFrame * CFrame.new(3, 0, 0))
	spelare.Character = rot.Parent
	GameplayService.bind(spelare)
	local p = GameplayService.passFor(spelare)
	--[[ Underlägget ligger redan på när stoppet kommer — ett halvt
		sadlingsmoment. ]]
	local okU = TackService.satPa(spelare, modell, "underlagg", nil, modell)
	check("underlägget ligger på före stoppet", okU)
	local okV = Pass.vidValfardsstopp(p)
	check("välfärdsstoppet tas emot", okV)
	local okS, sS = GameplayService.avslutaPass(spelare)
	check("passet räknas", okS and p.lage == Pass.LAGE.RAKNAT, tostring(sS))
	check("och inget ligger kvar på hästen", pa(modell) == "", pa(modell))
end

print("")
if fails > 0 then
	print(string.format("EFTERVÅRD-TACK: %d FEL", fails))
	error(string.format("%d fel", fails))
else
	print("EFTERVÅRD-TACK: alla gröna")
end
