--!nostrict
--[[ LEDNINGSMINNET (C4) — docs/LEADING-MEMORY-CONTRACT.md. Uppställningen nedan är
	ledlektion-specens egen, ordagrant; minnets fall följer efter den. ]]
--[[ (Ledlektion-specens ursprungliga huvud:

	KOHERENS-bänken med ledning-integrations uppställning: riktig
	SparService, StallService, HorseService, GameplayService och LedService,
	en tilldelad häst och en annan häst ur rostern. Ledningen startas med
	den riktiga `LedService.borja`; hästens rot flyttas mellan uttryckliga
	`LedLektion._steg` (ingen fysik i bänken — samma skäl som i
	ledning-integration.spec). Målzonen är den riktiga (`LedService.malzon`).

	SKRIVEN FÖR SENARE KÖRNING (Tobias beslut 5855114357: bygg nu, testa
	sist). Inte körd när den skrevs. Antaganden om bänken står vid varje
	KONTROLL-prov.  ]]
local fails, total = 0, 0
local function check(name, yes, detalj)
	total += 1
	if not yes then fails += 1 end
	print((if yes then "  OK   " else "  FEL  ") .. name .. (if detalj then "  " .. tostring(detalj) else ""))
end
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Taggar = game:GetService("CollectionService")
local M, TOMTDJUP = 3, 170

local function nyKaraktar(pos)
	local k = Instance.new("Model"); k.Name = "Karaktar"
	local rot = Instance.new("Part"); rot.Name = "HumanoidRootPart"; rot.Size = Vector3.new(2, 2, 1)
	rot.CFrame = CFrame.new(pos); rot.Parent = k
	local hand = Instance.new("Part"); hand.Name = "RightHand"; hand.Size = Vector3.new(1, 1, 1)
	hand.CFrame = CFrame.new(pos); hand.Parent = k
	local hum = Instance.new("Humanoid"); hum.Name = "Humanoid"; hum.Parent = k
	k.Parent = workspace
	return k, rot, hum
end
local START = Vector3.new(0, 3, 0)
local karaktar, spelarRot, spelarHum = nyKaraktar(START)
spelarHum.Health = 100 -- realistiskt: produktionen kräver ett levande Health
local spelare = Players.LocalPlayer
spelare.Name = "Ledaren"; spelare.UserId = 8811
spelare.Character = karaktar
spelare.CharacterAdded = __signal_ny(); spelare.CharacterRemoving = __signal_ny()
RunService._server = true
Players._spelare = { spelare }

SparService._glomHookarForProv()
SparService._glomForProv(spelare)
SparService.start()
StallService.start()
HorseService.start()
GameplayService.start()
LedService.start()
LedLektion._glomForProv()
Players.PlayerAdded:Fire(spelare)
Players.PlayerAdded:slutfor()

local MIN_ID = StallService.hastIdFor(spelare)
local ANNAN_ID
for hid in pairs(UBRFSpel.hastar) do if hid ~= MIN_ID then ANNAN_ID = hid; break end end
check("KONTROLL: a bound horse and another horse exist", MIN_ID ~= nil and ANNAN_ID ~= nil)
local function byggHast(hid, pos)
	local m = HastRigg.bygg(hid, hid, CFrame.new(pos))
	m.Parent = workspace
	m:SetAttribute("HorseId", hid)
	Taggar:AddTag(m, "Horse")
	return m
end
local MIN = byggHast(MIN_ID, START + Vector3.new(1.0 * M, 0, 0))
local ANNAN = byggHast(ANNAN_ID, START + Vector3.new(-1.0 * M, 0, 0))
GameplayService.bind(spelare)
local z = LedService.malzon()
check("KONTROLL: the real goal zone exists", z ~= nil)

--[[ Tomtkoordinater → värld (samma omräkning som LedService). ]]
local function varld(tx, ty) return Vector3.new(tx * M, 3, (TOMTDJUP - ty) * M) end
local MITT_Y = z.y + z.h / 2
local UTE_X = z.x - 14 -- 14 m utanför målzonens x-kant
local hastX = UTE_X
local function flytta(tx)
	hastX = tx
	local p = varld(tx, MITT_Y)
	MIN.PrimaryPart.CFrame = CFrame.new(p); MIN.PrimaryPart.Position = p
	local q = varld(tx + 2.4, MITT_Y) -- spelaren går före henne
	spelarRot.CFrame = CFrame.new(q); spelarRot.Position = q
end
local function steg(dt) LedLektion._steg(dt or 0.25) end
local function ga(tx, stegM) -- leds fram till tx i steg om stegM meter
	stegM = stegM or 1
	local n = math.max(1, math.ceil(math.abs(tx - hastX) / stegM))
	local x0 = hastX
	for i = 1, n do flytta(x0 + (tx - x0) * i / n); steg() end
end
local seq = 0
--[[ Det försök klienten VISAR (R1): serverns nuvarande försöksnummer. ]]
--[[ Det försök och den kontext klienten VISAR (R1/R2): en riktig sync först,
	sedan serverns nuvarande försöksnummer och kontextepok. ]]
local function ctx(p)
	LedLektion.begar(p or spelare, "sync")
	local st = LedLektion._tillstandForProv(p or spelare)
	return st.forsokNr, st.kontextNr
end
local function forv(p) local f = ctx(p); return f end
local function req(op, p)
	seq += 1
	local f, k = ctx(p)
	return LedLektion.begar(p or spelare, op, seq, f, k)
end
local function bild() local _, _, b = LedLektion.begar(spelare, "sync"); return b end
local function led() return LedService.borja(spelare, MIN) end
-- Fixturens R2-bindning (samma som i ledlektion-specen): `aktuell` styr den bundna hästen.
local aktuell = MIN
LedLektion.start({
	rattHast = function(p) return if p == spelare then aktuell else nil end,
	rider = function(p) return HorseService.horseOf(p) ~= nil end,
	klar = LektionsMinne.ledningKlar,
})

--[[ ══ LEDNINGSMINNET — docs/LEADING-MEMORY-CONTRACT.md ═══════════════════
	Ovan: ledlektion-specens egen uppställning, ordagrant (fixturen). Nedan:
	minnets fall. SKRIVNA FÖR SENARE KÖRNING, inte körda.
	ETIKETTER:
	- SYNKRONT: bänkens task.defer kör skrivförsöket direkt;
	- VERKLIGT FÖRDRÖJT: avsnitt 7, på schemat;
	- PÅHITTAT: avsnitt 5 (en förfalskad tabell). ]]
local LM = LektionsMinne
local function proj() return LM._projektion(LM._tillstandForProv(spelare)) end
local function rad() return __datastore._data["spelare_" .. spelare.UserId] end
local function radMarkor()
	local r = rad()
	return r and r.framsteg and r.framsteg[LM.nyckel("ledning")]
end
local function nollstall()
	local t = LM._tillstandForProv(spelare)
	if t then t.bekraftad.ledning = nil; t.vantar.ledning = nil end
	local sv = SparService.save(spelare)
	if sv then sv.framsteg[LM.nyckel("ledning")] = nil end
	if rad() then rad().framsteg[LM.nyckel("ledning")] = nil end
end
local function helLedning()
	LedService.slapp(spelare)
	flytta(UTE_X); steg()
	local lg = bild().lage
	if lg == "lead_first" or lg == "leading" then req("finish") end
	if bild().lage == "complete" or bild().lage == "timeout" then req("retry") else req("start") end
	led(); steg()
	ga(z.x + 2)
	for _ = 1, 4 do steg() end
	return bild()
end

print("\n── L1. Första genuina fullföljandet (SYNKRONT, riktig LedLektion) ──")
do
	check("KONTROLL: laddad och betrodd, nyckeln versionerad", SparService.betroddLasning(spelare)
		and LM.nyckel("ledning") == "ledning:" .. LedLektion.VERSION)
	check("från början: inte än", proj().ledning == "ej_klarad")
	__datastore.felSkriv = true -- håll skrivningen nere så att väntande syns
	local b = helLedning()
	__datastore.felSkriv = false
	check("KONTROLL: ledningen fullföljdes", b.lage == "complete" and b.resultat ~= nil)
	check("fullföljandet ger en väntande markör, i cachen", proj().ledning == "vantar"
		and SparService.save(spelare).framsteg[LM.nyckel("ledning")] ~= nil)
	LM._forsokSparaForProv(spelare)
	local f = radMarkor()
	check("bekräftad skrivning: sparad, en boolesk markör 1/1", proj().ledning == "sparad" and f ~= nil
		and f.forsok == 1 and f.klarade == 1 and f.senast == 0)
end

print("\n── L2. Upprepning, Retry och Avsluta direkt efter (SYNKRONT) ──")
do
	local skriv0 = __datastore.forsok.skriv
	local b = helLedning()
	check("KONTROLL: andra fullföljandet", b.lage == "complete")
	check("ingen ny markör, ingen ny skrivning", proj().ledning == "sparad" and __datastore.forsok.skriv == skriv0
		and radMarkor().forsok == 1)
	nollstall()
	helLedning()
	req("retry") -- direkt efter
	check("Retry direkt efter fullföljandet: markören står kvar", proj().ledning == "sparad"
		or proj().ledning == "vantar")
	nollstall()
	LedService.slapp(spelare); flytta(UTE_X); steg()
	req("finish")
	req("start"); led(); steg(); ga(z.x + 2); for _ = 1, 4 do steg() end
	req("finish") -- direkt efter
	check("Avsluta direkt efter fullföljandet: markören står kvar", proj().ledning ~= "ej_klarad")
end

print("\n── L3. Nekat, inaktuellt, tidsgräns, gamla målflaggor, spawn i målet (SYNKRONT) ──")
do
	nollstall()
	LedService.slapp(spelare)
	flytta(z.x + 2); steg() -- hon står redan i målet
	local okIn = req("start")
	check("start med hästen i målet nekas och ger inget", okIn == false and proj().ledning == "ej_klarad")
	flytta(UTE_X); steg()
	local f, k = ctx()
	seq = LedLektion._tillstandForProv(spelare).hogsta + 1
	local okGammal = LedLektion.begar(spelare, "start", seq, f - 1, k)
	check("ett inaktuellt försök nekas och ger inget", okGammal == false and proj().ledning == "ej_klarad")
	req("start")
	LedLektion._tillstandForProv(spelare).deadline = 0
	steg()
	check("tidsgräns: aldrig en markör", bild().lage == "timeout" and proj().ledning == "ej_klarad")
	LedService._steg(1 / 30) -- LedService kan sätta sina historiska målflaggor här
	check("gamla målflaggor (harNattMal/harLamnatBox) ger ingen markör", proj().ledning == "ej_klarad")
	req("retry"); led(); steg()
	flytta(z.x + 2); for _ = 1, 6 do steg() end -- hopp rakt in, ingen resa
	check("ett hopp eller en spawn i målet ger ingen markör", bild().lage ~= "complete" and proj().ledning == "ej_klarad")
end

print("\n── L4. Släpp och nytt grepp; en annan aktör (SYNKRONT) ──")
do
	nollstall()
	req("finish"); LedService.slapp(spelare); flytta(UTE_X); steg()
	req("start"); led(); steg()
	ga(UTE_X + 6)
	LedService.slapp(spelare); led(); steg()
	ga(z.x + 2); for _ = 1, 4 do steg() end
	--[[ Nytt grepp vid UTE_X + 6: resten fram till z.x + 2 är 10 m, under
		RESA_M (12 m) — den gamla resan får inte räknas. ]]
	check("släpp och nytt grepp: den gamla resan räknas inte, inget fullföljande, ingen markör",
		bild().lage ~= "complete" and proj().ledning == "ej_klarad")
	local annan = { UserId = 8899, Name = "Annan", Character = nil }
	LedLektion.begar(annan, "sync")
	check("en annan aktörs lektion rör inte spelarens minne", LM._tillstandForProv(annan) == nil)
end

print("\n── L5. En förfalskad tabell nekas (PÅHITTAT) ──")
do
	nollstall()
	local st = LedLektion._tillstandForProv(spelare)
	local falsk = { lage = "complete", userId = spelare.UserId, forsokNr = st.forsokNr, kontextNr = st.kontextNr,
		hastId = st.hastId, resultat = table.freeze({ version = LedLektion.VERSION, userId = spelare.UserId,
			forsokNr = st.forsokNr, kontextNr = st.kontextNr, hastId = st.hastId, meter = 99, sekunder = 20,
			frammeProv = 9, malNyckel = "x" }) }
	LM.ledningKlar(spelare, falsk)
	check("en tabell som inte är modulens tillstånd ger ingen markör", proj().ledning == "ej_klarad")
end

print("\n── L6. Historiken efter en ny kontext; omladdning; lagring (SYNKRONT) ──")
do
	nollstall()
	helLedning()
	LM._forsokSparaForProv(spelare)
	check("KONTROLL: sparad", proj().ledning == "sparad")
	aktuell = ANNAN -- ny bunden häst: ny kontextepok, inget aktuellt fullföljande
	steg()
	check("historiken står kvar efter en ny kontext", proj().ledning == "sparad")
	aktuell = MIN; steg()
	-- Skrivfel och återhämtning.
	nollstall()
	__datastore.felSkriv = true
	helLedning()
	__datastore.felSkriv = false
	check("skrivfel: väntande, aldrig sparad", proj().ledning == "vantar")
	LM._forsokSparaForProv(spelare)
	check("återhämtning: sparad", proj().ledning == "sparad")
	-- Fullt framsteg.
	nollstall()
	local save = SparService.save(spelare)
	local n = 0
	for _ in pairs(save.framsteg) do n += 1 end
	for i = 1, Sparning.MAX_FRAMSTEG - n do save.framsteg["fyll" .. i] = { forsok = 1, klarade = 0, senast = 0 } end
	helLedning()
	check("fullt: väntande, aldrig sparad", proj().ledning == "vantar")
	for i = 1, Sparning.MAX_FRAMSTEG do
		save.framsteg["fyll" .. i] = nil
		if rad() then rad().framsteg["fyll" .. i] = nil end
	end
	LM._tillstandForProv(spelare).vantar.ledning = nil
end

print("\n── L7. VERKLIGT FÖRDRÖJT: fullföljande under en skrivning i luften, och avfärd under den ──")
do
	nollstall()
	--[[ PÅHITTAD väntande skötselmarkör (satt direkt i minnets tillstånd), bara
		för att skapa en skrivning i luften; själva ledningen är riktig. ]]
	local t = LM._tillstandForProv(spelare)
	t.vantar["skotsel:halsa"] = true
	__schemaPa(true)
	__datastore.efterSkriv = function() __datastore.efterSkriv = nil; task.wait() end
	task.spawn(LM._forsokSparaForProv, spelare)
	__schemaSteg()
	check("KONTROLL: skrivningen i luften", LM._tillstandForProv(spelare).skriverNu == true)
	helLedning() -- ledningen fullföljs medan skrivningen väntar
	check("fullföljt under skrivningen: väntande, i cachen, inte i lagret", proj().ledning == "vantar"
		and SparService.save(spelare).framsteg[LM.nyckel("ledning")] ~= nil and radMarkor() == nil)
	Players.PlayerRemoving:Fire(spelare)
	__schemaTomKo()
	__schemaPa(false)
	check("avfärden dränerade: ledningen i lagret", radMarkor() ~= nil)
	SparService._glomForProv(spelare)
	Players._spelare = { spelare }
	Players.PlayerAdded:Fire(spelare)
	if Players.PlayerAdded.slutfor then Players.PlayerAdded:slutfor() end
	check("betrodd omläsning: sparad", proj().ledning == "sparad")
end

print("\n── L8. Klienten: ordning, knappens markering och klar-radens text i den FAKTISKA värden, SV/EN ──")
do
	local Lc = LedLektionController
	local ev = Networking.get("LektionsMinneSync")
	Lc.start()
	UgnetaController.satLektionsVal(nil)
	UgnetaController.dolj()
	local server = proj()
	ev.OnClientEvent:Fire(server)
	check("KONTROLL: klienten håller serverns ordning", Lc._ledMinneForProv() ~= nil
		and Lc._ledMinneForProv().session == server.session)
	local aldre = table.clone(server); aldre.rev = server.rev - 1; aldre.ledning = "ej_klarad"
	ev.OnClientEvent:Fire(aldre)
	check("ett äldre svar ersätter inte", Lc._ledMinneForProv().lage == "sparad")
	local function hitta(lista, del)
		for _, k in ipairs(lista) do if string.find(k.text, del, 1, true) then return k end end
		return nil
	end
	if Lc._valtForProv() then
		local tb = hitta(UgnetaController.panel(4).knappar, Sprak.t("ledlektion.back"))
		if tb then tb.skicka() end
	end
	local sida = UgnetaController.panel(4)
	local ingang = hitta(sida.knappar, Sprak.t("ledlektion.choose"))
	check("ingången till fots bär ' · klarad' i den sammansatta värden", ingang ~= nil
		and string.find(ingang.text, Sprak.t("ledminne.markering.sparad"), 1, true) ~= nil and #sida.knappar <= 4)
	if ingang then ingang.skicka() end
	req("finish")
	Lc._synkaForProv()
	local sidaIn = UgnetaController.panel(4)
	check("klar-/stängt-sidan: historikraden efter uppgiften", string.find(sidaIn.text or "",
		Sprak.t("ledminne.sparad"), 1, true) ~= nil, sidaIn.text)
	Sprak.satVal("en")
	check("på engelska", string.find(UgnetaController.panel(4).text or "",
		"You have led her all the way before.", 1, true) ~= nil)
	Sprak.satVal("sv")
	UgnetaController.visa("Kort", {}, true, nil, true, true)
	check("med tre äldre kort: fortfarande högst fyra rader", #UgnetaController.panel(4).knappar <= 4)
	UgnetaController.dolj()
end

if fails > 0 then error(tostring(fails) .. " FEL") end
print(string.format("\nLEDNINGSMINNE: %d prov, alla gröna", total))
