--!nostrict
--[[
	#274 — «RIDA NU» ÄR INTE EN ÅTERVÄNDSGRÄND.

	Speltestet: "det går inte att rida direkt då ridläraren stoppar en".
	Välfärdsstoppet står kvar: en häst med ett riktigt fynd rids inte. Men
	stoppet får inte betyda att dagen är slut. Spelaren ska få en FRISK
	häst och kunna fortsätta samma dag:

	    fynd -> hästen stoppas -> frisk ersättare -> «Rida nu» -> uppsittning

	Det här provet mäter kedjan genom TJÄNSTEN (`GameplayService` och
	`StallService` med riktig rigg och riktig sparning), inte regeln i
	`Preparation` ensam, och de tre negativa kraven:

	  · den stoppade hästen kommer aldrig tillbaka medan hon vilar,
	  · ersättaren är aldrig vilande eller skadad,
	  · dagen räknas EN gång — fortsättningen räknar inte om den.

	Kör: python3 roblox/tests/build.py tests/ridefirst-fortsatt.spec.luau
	     && luau roblox/tests/.build/ridefirst-fortsatt.spec.luau
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

local JACK = Stallet.FORSTA_DAGEN_HAST

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

local RIGG = Vector3.new(0, 0, 0)

local function nySession(namn, userId, fore)
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

--[[ Ersättarens modell står i sin egen box; spelaren går dit. Här: samma
	punkt, efter att den stoppade hästens modell tagits bort ur världen. ]]
local function stallIn(spelare, hastId)
	local modell = HastRigg.bygg(hastId, hastId, CFrame.new(RIGG))
	modell.Parent = workspace
	Taggar:AddTag(modell, "Horse")
	spelare.Character:FindFirstChild("HumanoidRootPart").CFrame =
		CFrame.new(RIGG + Vector3.new(2, 0, 0))
	return modell
end

--[[ Ett passnummer där Jack bär ett fynd. Fyndet sätts i spelarens egen
	förberedelse — samma fält som `Preparation.nyState(hastId, pass)` sätter —
	eftersom första passet aldrig bär något: spelarens sparfil är ny. ]]
local function fyndFor(hastId)
	for p = 2, 60 do
		local f = Preparation.fyndFor(hastId, p)
		if f then return f end
	end
	return nil
end

--[[ En spelare vars rotation ger en ersättare utan eget fynd på passet
	efter (stoppet räknar dagen, så ersättaren får passnummer 2). Annars
	skulle provet mäta ett SECOND stopp i stället för fortsättningen. ]]
local function valjSpelare()
	for uid = 9300, 9500 do
		local d = Stallet.dagensHast(uid, {}, { [JACK] = true }, nil)
		if d and d.id ~= JACK and Preparation.fyndFor(d.id, 2) == nil then
			return uid, d.id, d.namn
		end
	end
	return nil
end

local UID, FORVANTAD, FORVANTAT_NAMN = valjSpelare()
check("förutsättning: en spelare med fyndfri ersättare finns", UID ~= nil)

local function svar()
	for _, s in ipairs(Preparation.fyndSvar()) do
		if not s.fel then return s.id end
	end
end

--[[ ══ 1. HELA KEDJAN ═════════════════════════════════════════════════ ]]
print("\n── Fynd → stopp → frisk ersättare → «Rida nu» → uppsittning ──")

local sp, mod1, h1 = nySession("Fortsatt", UID)
local s1 = GameplayService.stateFor(sp)
do
	check("första dagen: spelaren har Jack", h1 == JACK, tostring(h1))
	s1.fynd = fyndFor(JACK)
	check("jacks förberedelse bär ett fynd (pass med fynd)", s1.fynd ~= nil, tostring(s1.fynd))

	local ok, skal = GameplayService.ridaNu(sp)
	check("«Rida nu» stannar på det öppna fyndet — beslutet är spelarens",
		ok == false and skal == "forb.oppet_fynd", tostring(skal))

	local save = SparService.save(sp)
	local passFore = Sparning.aktuelltPass(save)
	local oksvar = GameplayService.svara(sp, svar())
	check("rätt svar tas emot", oksvar == true)
	check("hästen är STOPPAD — den rids inte", s1.stoppad ~= nil, tostring(s1.stoppad))
	local m = Sparning.hastminnen(save)[JACK]
	check("och vilan är sparad för henne",
		m ~= nil and m.skada ~= nil and m.skada.passKvar > 0,
		m and m.skada and tostring(m.skada.passKvar) or "ingen skada")
	check("dagen är räknad en gång", Sparning.aktuelltPass(save) == passFore + 1,
		("%d -> %d"):format(passFore, Sparning.aktuelltPass(save)))
	local klar = Preparation.provaUppsittning(s1, JACK)
	check("den stoppade hästen får INTE ridas", klar == false)

	local ersId, ersNamn = GameplayService.ersattareFor(sp)
	check("spelaren erbjuds en ersättare med namn", ersId ~= nil and ersNamn ~= nil,
		tostring(ersId) .. " / " .. tostring(ersNamn))
	check("och vyn till klienten bär hennes namn, så knappen kan heta något",
		GameplayService._vyForProv(sp).ersattare == ersNamn,
		tostring(GameplayService._vyForProv(sp).ersattare))
	check("ersättaren är en annan häst än den stoppade", ersId ~= nil and ersId ~= JACK)
	check("ersättaren är rotationens friska häst", ersId == FORVANTAD,
		tostring(ersId) .. " förväntad " .. tostring(FORVANTAD))
	local minnen = Sparning.hastminnen(save)
	check("ersättaren vilar inte och är inte skadad",
		ersId ~= nil and not Stallet.vilarForSkada(minnen[ersId]))

	local passEfterStopp = Sparning.aktuelltPass(save)
	local okF, skalF, nyId = GameplayService.fortsattMedAnnanHast(sp)
	check("fortsättningen lyckas och pekar ut ersättaren",
		okF == true and nyId == ersId, tostring(skalF) .. " / " .. tostring(nyId))
	check("tjänsten har tilldelat ersättaren", StallService.hastIdFor(sp) == ersId,
		tostring(StallService.hastIdFor(sp)))
	local s2 = GameplayService.stateFor(sp)
	check("det är en NY förberedelse för den friska hästen, utan stopp",
		s2 ~= nil and s2 ~= s1 and s2.hastId == ersId and s2.stoppad == nil)
	check("och utan öppet fynd (annars vore det ett andra stopp)",
		s2 ~= nil and s2.fynd == nil, tostring(s2 and s2.fynd))
	check("dagen räknas INTE en gång till av fortsättningen",
		Sparning.aktuelltPass(save) == passEfterStopp,
		("%d -> %d"):format(passEfterStopp, Sparning.aktuelltPass(save)))
	check("Jacks vila är orörd av fortsättningen",
		(Sparning.hastminnen(save)[JACK] or {}).skada ~= nil
		and Sparning.hastminnen(save)[JACK].skada.passKvar == m.skada.passKvar)

	-- Spelaren går till ersättaren. Jacks modell står kvar i sin box.
	mod1:Destroy()
	local mod2 = stallIn(sp, ersId)
	local okR, skalR = GameplayService.ridaNu(sp)
	check("«Rida nu» på ersättaren går hela vägen", okR == true, tostring(skalR))
	local okU, skalU = Preparation.provaUppsittning(GameplayService.stateFor(sp), ersId)
	check("ersättaren är uppsittningsklar", okU == true, tostring(skalU))
	local okS, skalS = GameplayService.farSittaUpp(sp, mod2)
	check("och spelaren FÅR sitta upp", okS == true, tostring(skalS))
	check("dagen räknades fortfarande bara en gång efter «Rida nu»",
		Sparning.aktuelltPass(save) == passEfterStopp)
end

--[[ ══ 2. DEN STOPPADE HÄSTEN KOMMER ALDRIG TILLBAKA ═════════════════ ]]
print("\n── Den stoppade hästen kommer aldrig tillbaka ──")

do
	local sp2 = nySession("Tillbaka", UID + 1)
	local st = GameplayService.stateFor(sp2)
	st.fynd = fyndFor(JACK)
	GameplayService.ridaNu(sp2)
	GameplayService.svara(sp2, svar())
	local save = SparService.save(sp2)
	local pass = Sparning.aktuelltPass(save)

	for i = 1, 5 do
		local d = StallService.tilldela(sp2)
		if d and d.id == JACK then
			check(("tilldelning %d ger aldrig den vilande hästen"):format(i), false, JACK)
		end
	end
	check("fem nya tilldelningar gav aldrig den vilande hästen", true)

	--[[ Sparningen kan fallera; hästen ska ändå inte komma tillbaka. Det är
		den uttryckliga undantagsparametern som håller, inte bara minnet. ]]
	local d = StallService.tilldela(sp2, JACK)
	check("tilldelning med uttryckligt undantag ger inte henne heller",
		d == nil or d.id ~= JACK, d and d.id or "nil")

	local ok1, skal1 = GameplayService.fortsattMedAnnanHast(sp2)
	local ok2, skal2 = GameplayService.fortsattMedAnnanHast(sp2)
	check("fortsättningen går en gång", ok1 == true, tostring(skal1))
	check("ett andra anrop byter inte häst och räknar inte dagen",
		ok2 == false and Sparning.aktuelltPass(save) == pass,
		tostring(skal2) .. " · pass " .. tostring(Sparning.aktuelltPass(save)))
	check("den stoppade hästen är fortfarande inte tilldelad",
		StallService.hastIdFor(sp2) ~= JACK)
end

--[[ ══ 2b. UNDANTAGET HÅLLER ÄVEN UTAN SPARNING ══════════════════════
	Vilan är sparad i fallen ovan, så provet kan inte skilja minnet från det
	uttryckliga undantaget. Här vilar ingen: en NY spelare, och hästen hon har
	är den som undantas. Faller sparningen efter ett stopp ser stallet ingen
	vila — och ändå ska hon inte komma tillbaka. ]]
print("\n── Undantaget håller även när ingen vila är sparad ──")

do
	local sp5, _, h5 = nySession("Undantag", UID + 4)
	local ers = StallService.ersattare(sp5, h5)
	check("ersättarfrågan ger en annan häst än den undantagna",
		ers ~= nil and ers.id ~= h5, ers and ers.id or "nil")
	for i = 1, 3 do
		local d = StallService.tilldela(sp5, h5)
		check(("tilldelning %d med undantag ger aldrig den undantagna"):format(i),
			d ~= nil and d.id ~= h5, d and d.id or "nil")
	end
end

--[[ ══ 2c. FORTSÄTTNINGEN SJÄLV HÅLLER UNDANTAGET ═══════════════════
	Samma krav, men genom `fortsattMedAnnanHast` och med en rotation som
	PEKAR på den stoppade: vilan hinner försvinna ur minnet (utlupen, eller
	en sparning som föll) och Jack är då frisk i stallets ögon. Anropet ska
	ändå inte ge honom tillbaka — det är `tilldela(player, undanta)` på
	anropsplatsen som håller, inte bara minnet. ]]
print("\n── Fortsättningen ger inte den stoppade tillbaka ens utan synlig vila ──")

do
	local UID6 = nil
	for uid = 9600, 9900 do
		local start = Stallet.dagensHast(uid, {}, {}, nil)
		local rep = Stallet.dagensHast(uid, {}, { [JACK] = true }, nil)
		if start and start.id == JACK and rep and Preparation.fyndFor(rep.id, 2) == nil then
			UID6 = uid
			break
		end
	end
	check("förutsättning: en spelare vars rotation pekar på Jack finns", UID6 ~= nil)
	local sp6 = nySession("Minnet", UID6)
	local st6 = GameplayService.stateFor(sp6)
	st6.fynd = fyndFor(JACK)
	GameplayService.ridaNu(sp6)
	GameplayService.svara(sp6, svar())
	local save = SparService.save(sp6)
	Sparning.raknaNerVila(save)
	check("förutsättning: vilan syns inte längre i minnet",
		not Stallet.vilarForSkada(Sparning.hastminnen(save)[JACK]))
	local ok, skal, nyId = GameplayService.fortsattMedAnnanHast(sp6)
	check("fortsättningen lyckas", ok == true, tostring(skal))
	check("men den stoppade kommer inte tillbaka", nyId ~= nil and nyId ~= JACK
		and StallService.hastIdFor(sp6) ~= JACK, tostring(nyId))
end

--[[ ══ 3. UTAN STOPP FINNS INGET ATT FORTSÄTTA FRÅN ══════════════════ ]]
print("\n── Ingen fortsättning utan ett stopp ──")

do
	local sp3, _, h3 = nySession("UtanStopp", UID + 2)
	local ok, skal = GameplayService.fortsattMedAnnanHast(sp3)
	check("utan stopp byts ingen häst", ok == false and StallService.hastIdFor(sp3) == h3,
		tostring(skal))
	check("och ingen ersättare erbjuds", GameplayService.ersattareFor(sp3) == nil)
end

--[[ ══ 4. ALLA ANDRA VILAR ═══════════════════════════════════════════ ]]
print("\n── Finns ingen frisk häst är stoppet ett besked, inte en tom knapp ──")

do
	local sp4, _, h4 = nySession("AllaVilar", UID + 3)
	local save = SparService.save(sp4)
	for id in pairs(UBRFSpel.hastar) do
		if id ~= h4 then Sparning.satSkada(save, id, 5, nil) end
	end
	local st = GameplayService.stateFor(sp4)
	st.fynd = fyndFor(h4)
	GameplayService.ridaNu(sp4)
	GameplayService.svara(sp4, svar())
	local pass = Sparning.aktuelltPass(save)
	check("hästen är stoppad", st.stoppad ~= nil)
	check("ingen ersättare finns att erbjuda", GameplayService.ersattareFor(sp4) == nil)
	check("och vyn bär inget `ersattare`-fält — ingen tom knapp",
		GameplayService._vyForProv(sp4).ersattare == nil)
	local ok, skal = GameplayService.fortsattMedAnnanHast(sp4)
	check("fortsättningen nekar, och ingen vilande häst delas ut",
		ok == false and StallService.hastIdFor(sp4) == h4 and skal ~= nil, tostring(skal))
	check("och dagen räknas inte igen", Sparning.aktuelltPass(save) == pass)
end

print("")
if fails > 0 then
	print(string.format("%d mätning(ar) föll.", fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("ridefirst-fortsatt.spec: alla gröna")
end
