--!nostrict
--[[ LEDA HÄSTEN TILL RIDHUSET (till fots) — docs/LEADING-LESSON-CONTRACT.md.

	KOHERENS-bänken med ledning-integrations uppställning: riktig
	SparService, StallService, HorseService, GameplayService och LedService,
	en tilldelad häst och en annan häst ur rostern. Ledningen startas med
	den riktiga `LedService.borja`; hästens rot flyttas mellan uttryckliga
	`LedLektion._steg` (ingen fysik i bänken — samma skäl som i
	ledning-integration.spec). Målzonen är den riktiga (`LedService.malzon`).

	SKRIVEN FÖR SENARE KÖRNING (Tobias beslut 5855114357: bygg nu, testa
	sist). Inte körd när den skrevs. Antaganden om bänken står vid varje
	KONTROLL-prov. ]]
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

-- ── Hela vägen: start, leda, resa, ankomst ──
do -- Egen räckvidd: huvudchunken har högst 200 lokala register, och bunten (alla moduler plus specen) slog i taket.
flytta(UTE_X)
local ok1, _, b1 = req("start")
check("start on foot with the horse outside asks to take the horse", ok1 and b1.lage == "lead_first"
	and b1.tips == "lead_first")
local okL = led()
check("KONTROLL: the real LedService leads the bound horse", okL == true and LedService.aktiv(spelare) == MIN)
steg()
check("leading the right horse after Start sets the baseline", bild().lage == "leading" and bild().progress == 0)
ga(z.x - 0.5)
check("13.5 m of led travel outside the goal does not complete", bild().lage == "leading"
	and bild().tips == "into_arena")
ga(z.x + 2)
for _ = 1, 3 do steg() end
local done = bild()
check("entering and settling inside the real goal completes", done.lage == "complete")
check("frozen result: owner, horse, attempt, metres, seconds, arrival and goal key",
	done.resultat ~= nil and table.isfrozen(done.resultat) and done.resultat.userId == spelare.UserId
	and done.resultat.hastId == MIN_ID and done.resultat.forsokNr == 1 and done.resultat.meter >= 12
	and done.resultat.frammeProv >= 4 and type(done.resultat.malNyckel) == "string")
LedService._steg(1 / 30)
check("the preparation's own goal acknowledgement still happens normally", LedService.harNattMal(spelare))
LedService.slapp(spelare)
steg()
check("releasing after completion keeps the result", bild().lage == "complete" and bild().resultat == done.resultat)

-- ── Redan inne; gammal historisk ankomst ──
local okIn, felIn = req("retry")
check("retry with the horse still inside the goal is refused", okIn == false and felIn == "inside")
flytta(UTE_X) -- inte ledd: ingen resa
local okR = req("retry")
check("retry outside opens attempt 2 without leading", okR == true and bild().forsokNr == 2
	and bild().lage == "lead_first")
led(); steg()
flytta(z.x + 2); steg(); steg(); steg(); steg() -- hopp rakt in
check("the historical malNatt and a jump in never complete", LedService.harNattMal(spelare)
	and bild().lage ~= "complete" and bild().tips ~= "settle")

-- ── Redan ledd vid Start, fel häst, två spelare ──
req("finish")
flytta(UTE_X); steg()
check("finish never releases the horse", LedService.aktiv(spelare) == MIN)
req("start")
check("starting while already leading sets the baseline at Start", bild().lage == "leading")
req("finish")
LedService.slapp(spelare)
req("start")
local okFel = LedService.borja(spelare, ANNAN)
steg()
check("the other horse cannot be led; the lesson waits for the right one", okFel ~= true
	and bild().lage == "lead_first")
local andra = { UserId = 8812, Name = "Annan", Character = nil }
local ok2, fel2 = LedLektion.begar(andra, "start", 1, 0, 0)
check("a second player's lesson is independent (no bound horse)", ok2 == false and fel2 == "horse"
	and bild().lage == "lead_first")

-- ── Genvägar och luckor, stillastående ──
led(); steg()
ga(UTE_X + 4)
LedService.placeraVidMal(spelare, MIN)
steg()
check("placeraVidMal (a shortcut placement) is never leading", bild().lage ~= "complete"
	and bild().progress == 0)
req("finish"); LedService.slapp(spelare)
flytta(UTE_X)
req("start"); led(); steg()
ga(UTE_X + 3)
flytta(UTE_X + 3.5); steg(1.5) -- lucka i provtakten
check("an observation gap resets", bild().lage ~= "complete" and bild().tips == "unknown")
steg()
for _ = 1, 20 do steg() end
check("a stationary horse despite leading adds no travel", bild().lage == "leading" and bild().progress == 0)

-- ── Släppt före målet, målzonen, uppsittning ──
ga(UTE_X + 8)
LedService.slapp(spelare); steg()
check("release before the goal resets with guidance", bild().lage == "lead_first"
	and bild().tips == "released" and bild().progress == 0)
led(); steg()
local zon0 = z
LedService.satMalzon({ x = z.x + 1, y = z.y, w = z.w, h = z.h }); steg()
check("a changed goal resets and refreshes the reference", bild().tips == "target"
	and bild().referens ~= nil and bild().referens.x == z.x + 1)
LedService.satMalzon(nil); steg()
check("a missing goal gives no guide reference", bild().tips == "target" and bild().referens == nil)
LedService.satMalzon(zon0); steg(); steg()
check("with the goal back, a fresh baseline is needed", bild().progress == 0)
HorseService.setMountGate(nil)
local okM = HorseService.tryMount(spelare, MIN)
steg()
check("mounting stops the on-foot evidence (when the bench mount succeeds)",
	okM ~= true or bild().tips == "mounted")
if okM == true then HorseService.dismount(spelare) end

-- ── Tidsgräns, begäranbok, ägarens händelser ──
local st = LedLektion._tillstandForProv(spelare)
st.deadline = 0
steg()
check("deadline gives incomplete, never success", bild().lage == "timeout")
local base = seq
local f0, k0 = ctx()
local a1 = { LedLektion.begar(spelare, "retry", base + 1, f0, k0) }
local a2 = { LedLektion.begar(spelare, "retry", base + 1, f0, k0) }
check("a replayed request returns the same answer", a1[1] == a2[1] and a1[2] == a2[2])
local okAnnan = LedLektion.begar(spelare, "finish", base + 1, f0, k0)
check("the same sequence with another operation is refused", okAnnan == false)
local f3, k3 = ctx()
LedLektion.begar(spelare, "finish", base + 3, f3, k3)
local okGammal, felGammal = LedLektion.begar(spelare, "start", base + 2, f3, k3) -- aldrig använd, men äldre
check("an older, unused sequence is stale", okGammal == false and felGammal == "stale")
seq = base + 3
local sync = Networking.get("LedLektionSync")
local tillAnnan = 0
for _, rad in ipairs(sync._skickat or {}) do if rad[1] ~= spelare then tillAnnan += 1 end end
check("lesson events go only to their owner", tillAnnan == 0)

-- ── Retry kräver färsk resa ──
req("finish"); LedService.slapp(spelare)
flytta(UTE_X)
req("start"); led(); steg()
ga(z.x + 2)
for _ = 1, 4 do steg() end
check("a fresh full lead completes again", bild().lage == "complete")
LedService.slapp(spelare)
flytta(UTE_X)
local okRR = req("retry"); led(); steg()
check("retry needs new travel: progress starts at 0", okRR == true and bild().progress == 0
	and bild().lage == "leading")

-- ── R1: samma ledningssession, karaktär och häst ──
req("finish"); LedService.slapp(spelare)
flytta(UTE_X)
req("start"); led(); steg()
ga(UTE_X + 5)
local pauseResa = LedLektion._tillstandForProv(spelare).resa
for _ = 1, 8 do steg() end
check("R1: a pause in the SAME leading session keeps its travel", bild().lage == "leading"
	and LedLektion._tillstandForProv(spelare).resa == pauseResa and bild().progress > 0)
LedService.slapp(spelare); led() -- släpp och nytt grepp om SAMMA häst mellan två prov
steg()
check("R1: release and re-take of the same horse between samples clears the evidence",
	bild().lage == "lead_first" and bild().tips == "released" and bild().progress == 0)
steg()
check("R1: a fresh outside baseline follows", bild().lage == "leading" and bild().progress == 0)
ga(UTE_X + 8)
local nyK, nyRot, nyHum = nyKaraktar(spelarRot.Position)
nyHum.Health = 100
spelare.Character = nyK -- ny karaktär (respawn) mellan två prov, genast levande
steg()
check("R1: a replaced character between samples clears the evidence", bild().tips == "character"
	and bild().progress == 0)
spelare.Character = karaktar
local forald = MIN.Parent
MIN.Parent = nil -- den bundna hästen borta / ersatt
steg()
check("R1: a missing or replaced bound horse resets", bild().tips == "horse" and bild().progress == 0)
MIN.Parent = forald
steg()

end
-- ── R1: gamla kontroller och gamla bilder på klienten (riktiga återkallningar) ──
do -- Egen räckvidd: huvudchunken har högst 200 lokala register, och bunten (alla moduler plus specen) slog i taket.
local Lk = LedLektionController
Lk.start()
UgnetaController.satLektionsVal(nil)
UgnetaController.dolj()
req("finish"); LedService.slapp(spelare)
flytta(UTE_X)
local function hittaK(lista, txt)
	for _, k in ipairs(lista) do if k.text == txt then return k end end
	return nil
end
local e0 = hittaK(UgnetaController.panel(4).knappar, Sprak.t("ledlektion.choose"))
if e0 then e0.skicka() end
local startK = hittaK(UgnetaController.panel(4).knappar, Sprak.t("ledlektion.start"))
if startK then startK.skicka() end
local forsokA = forv()
local finishA = hittaK(UgnetaController.panel(4).knappar, Sprak.t("ledlektion.finish"))
check("KONTROLL: the page started an attempt and shows Finish", startK ~= nil and finishA ~= nil
	and bild().lage ~= "closed")
if finishA then finishA.skicka() end
-- Ett lyckat Finish stänger lektionssidan (valt = false): öppna igen via Välj.
check("KONTROLL: after Finish the on-foot entry is shown again", not Lk._valtForProv())
local e1 = hittaK(UgnetaController.panel(4).knappar, Sprak.t("ledlektion.choose"))
check("KONTROLL: the choose entry exists", e1 ~= nil)
if e1 then e1.skicka() end
local startB = hittaK(UgnetaController.panel(4).knappar, Sprak.t("ledlektion.start"))
check("KONTROLL: the reopened page shows Start", startB ~= nil)
if startB then startB.skicka() end
local forsokB = forv()
check("KONTROLL: a newer attempt is running", forsokB == forsokA + 1 and bild().lage ~= "closed")
if finishA then finishA.skicka() end -- den KVARGLÖMDA Finish från försök A
check("R1: a retained old Finish callback never closes the newer attempt",
	forv() == forsokB and bild().lage ~= "closed")
-- Klienten har gått vidare i sekvensen (den följer serverns högsta): nästa lediga.
seq = LedLektion._tillstandForProv(spelare).hogsta + 1
local _, kNu = ctx()
local okSt, felSt = LedLektion.begar(spelare, "finish", seq, forsokA, kNu)
check("R1: the server rejects an old attempt's Finish without touching the newer one",
	okSt == false and felSt == "stale_attempt" and bild().lage ~= "closed")
seq = LedLektion._tillstandForProv(spelare).hogsta + 1
local okSt2, felSt2 = LedLektion.begar(spelare, "retry", seq, forsokA, kNu)
check("R1: a stale Retry for an older attempt is rejected", okSt2 == false and felSt2 == "stale_attempt")
local aktuellBild = Lk._bildForProv()
Networking.get("LedLektionSync").OnClientEvent:Fire({ typ = "leda", forsokNr = forsokA, revision = 999,
	lage = "complete", tips = "complete", progress = 100, sekvens = 0 })
check("R1: a reordered snapshot from an older attempt never replaces the current one",
	Lk._bildForProv() == aktuellBild)
-- De direkta handlaranropen ovan förbrukade sekvenser; klienten synkar den
-- riktiga vägen så att dess nästa begäran inte krockar i svarsboken.
Lk._synkaForProv()
local finNu = hittaK(UgnetaController.panel(4).knappar, Sprak.t("ledlektion.finish"))
check("KONTROLL: the current page shows Finish", finNu ~= nil)
if finNu then finNu.skicka() end
check("R1: the current attempt's own Finish still works", bild().lage == "closed")
check("R1: after Finish the on-foot entry is shown again", not Lk._valtForProv())
seq = LedLektion._tillstandForProv(spelare).hogsta
UgnetaController.dolj()
end
-- ── R2: kontexten (bunden modell och karaktär) binder ändrande begäranden ──
--[[ Bänkens StallService tilldelar alltid samma häst, så bindningen A → B görs
	genom lektionens egen beroendeinjektion — samma väg som när
	GameplayService svarar med en annan modell. Ersättning med samma HorseId
	görs med en riktig ny modell. ]]
local aktuell = MIN
do -- Egen räckvidd: huvudchunken har högst 200 lokala register, och bunten (alla moduler plus specen) slog i taket.
LedLektion.start({
	rattHast = function(p) return if p == spelare then aktuell else nil end,
	rider = function(p) return HorseService.horseOf(p) ~= nil end,
})
req("finish"); LedService.slapp(spelare)
flytta(UTE_X)
req("start"); led(); steg()
ga(z.x + 2); for _ = 1, 4 do steg() end
check("KONTROLL: a completed attempt on horse A", bild().lage == "complete" and bild().hastId == MIN_ID)
local fC, kC = ctx()
local resC = bild().resultat
aktuell = ANNAN -- bunden A → B medan lektionen står i complete
seq = LedLektion._tillstandForProv(spelare).hogsta + 1
local okC, felC, bC = LedLektion.begar(spelare, "retry", seq, fC, kC)
check("R2: an old Retry after A → B (complete) is rejected as stale_context", okC == false
	and felC == "stale_context" and bC.hastId == ANNAN_ID and bild().resultat == resC)
local fC2, kC2 = ctx()
seq += 1
local okC2 = LedLektion.begar(spelare, "retry", seq, fC2, kC2)
check("R2: a fresh sync then Retry acts on the CURRENT horse B", okC2 == true
	and LedLektion._tillstandForProv(spelare).hastId == ANNAN_ID)
seq += 1
LedLektion.begar(spelare, "finish", seq, ctx())
local fS, kS = ctx()
check("KONTROLL: closed with horse B", bild().lage == "closed")
aktuell = MIN -- B → A medan lektionen står i closed
seq += 1
local okS, felS = LedLektion.begar(spelare, "start", seq, fS, kS)
check("R2: an old Start after B → A (closed) is rejected as stale_context", okS == false
	and felS == "stale_context" and bild().lage == "closed")
flytta(UTE_X)
local fS2, kS2 = ctx()
seq += 1
local okS2 = LedLektion.begar(spelare, "start", seq, fS2, kS2)
check("R2: a fresh sync then Start acts on the current horse A", okS2 == true
	and LedLektion._tillstandForProv(spelare).hastId == MIN_ID)
-- Ersättning med SAMMA HorseId under ett aktivt försök: gammal Finish nekas.
local fA, kA = ctx()
local MIN2 = byggHast(MIN_ID, varld(UTE_X - 3, MITT_Y))
aktuell = MIN2
steg()
seq += 1
local okF, felF = LedLektion.begar(spelare, "finish", seq, fA, kA)
check("R2: a same-HorseId model replacement changes the context; an old Finish is rejected",
	okF == false and felF == "stale_context" and bild().lage ~= "closed")
local fA2, kA2 = ctx()
seq += 1
local okF2 = LedLektion.begar(spelare, "finish", seq, fA2, kA2)
check("R2: Finish with the fresh context closes", okF2 == true and bild().lage == "closed")
-- Ready: en ny spelare som aldrig startat, bindningen byts före Start.
local k3, _, h3 = nyKaraktar(varld(UTE_X, MITT_Y + 5))
h3.Health = 100
local tredje = { UserId = 8813, Name = "Tredje", Character = k3 }
local aktuell3 = MIN2
LedLektion.start({
	rattHast = function(p) return if p == spelare then aktuell elseif p == tredje then aktuell3 else nil end,
	rider = function(p) return HorseService.horseOf(p) ~= nil end,
})
local _, _, bR = LedLektion.begar(tredje, "sync")
local fR, kR = bR.forsokNr, bR.kontextNr
aktuell3 = ANNAN -- bunden A → B medan lektionen står i ready
local okR3, felR3 = LedLektion.begar(tredje, "start", 1, fR, kR)
check("R2: an old Start after A → B (ready) is rejected as stale_context", okR3 == false
	and felR3 == "stale_context")
local _, _, bR2 = LedLektion.begar(tredje, "sync")
local okR4 = LedLektion.begar(tredje, "start", 2, bR2.forsokNr, bR2.kontextNr)
check("R2: after a fresh sync the Start acts on horse B", okR4 == true
	and LedLektion._tillstandForProv(tredje).hastId == ANNAN_ID)
MIN2.Parent = nil
aktuell = MIN
seq = LedLektion._tillstandForProv(spelare).hogsta
end

-- ── Klientens ingång till fots (källnivå) ──
local L = LedLektionController
L.start()
UgnetaController.satLektionsVal(nil)
local KAP = 4
local function hitta(lista, txt)
	for _, k in ipairs(lista) do if k.text == txt then return k end end
	return nil
end
local ingangOk = true
for n = 0, 3 do
	UgnetaController.dolj()
	if n > 0 then UgnetaController.visa("Kort", {}, n >= 1, nil, n >= 2, n >= 3) end
	local sida = UgnetaController.panel(KAP).knappar
	local e = hitta(sida, Sprak.t("ledlektion.choose"))
	if not (e and e.sekundar == true and #sida <= KAP) then ingangOk = false end
end
check("the on-foot entry is a secondary choice beside 0..3 cards", ingangOk)
UgnetaController.dolj()
local e = hitta(UgnetaController.panel(KAP).knappar, Sprak.t("ledlektion.choose"))
if e then e.skicka() end
local sida = UgnetaController.panel(KAP)
check("choosing opens the lesson page with a lesson control and Back or Finish",
	sida.ersatt == true and #sida.knappar <= KAP
	and (hitta(sida.knappar, Sprak.t("ledlektion.back")) ~= nil
		or hitta(sida.knappar, Sprak.t("ledlektion.finish")) ~= nil))
UgnetaController.satLektionsVal(VoltLektionController.panel)
VoltLektionController.avbryt(); VoltLektionController.start("led-meny-prov", nil)
local ridsida = UgnetaController.panel(KAP).knappar
check("mounted lesson menus take precedence and are unchanged",
	hitta(ridsida, Sprak.t("voltlektion.choose")) ~= nil and hitta(ridsida, Sprak.t("ledlektion.choose")) == nil)
VoltLektionController.avbryt()

-- ── C1 R1: återkopplingen efter ledningen — producent → sync → panel ──
--[[ Riktig LedLektion (med den injicerade bindningen `aktuell` ovan), riktig
	sync-väg (`L._synkaForProv`, dvs. `skicka("sync")` genom fjärranropet) och
	riktig `LedLektionController.panel()`. En slutförd ledning får aldrig
	visas som resultat för en SENARE bunden häst, en ersättare med samma
	HorseId eller en ny karaktär. ]]
do
	local Lc = LedLektionController
	local function har(t, del) return type(t) == "string" and string.find(t, del, 1, true) ~= nil end
	local function tal1(x) return (string.gsub(string.format("%.1f", x), "%.", ",")) end
	local function panelText() Lc._synkaForProv(); local p = Lc.panel(); return p and p.text end
	local ANNAN_TEXT = Sprak.t("aterkoppling.leda.annan")
	Sprak.satVal("sv")
	UgnetaController.dolj()
	if not Lc._valtForProv() then
		local e2 = hitta(UgnetaController.panel(KAP).knappar, Sprak.t("ledlektion.choose"))
		if e2 then e2.skicka() end
	end
	check("KONTROLL C1: the leading page is open", Lc._valtForProv())
	aktuell = MIN
	local function slutfor()
		LedService.slapp(spelare)
		flytta(UTE_X); steg()
		seq = LedLektion._tillstandForProv(spelare).hogsta
		local lg = bild().lage
		if lg == "lead_first" or lg == "leading" then req("finish") end
		if bild().lage == "complete" or bild().lage == "timeout" then req("retry") else req("start") end
		led(); steg()
		ga(z.x + 2)
		for _ = 1, 4 do steg() end
		return bild()
	end
	-- Oförändrad kontext: sammanfattningen visas och står kvar.
	local klar = slutfor()
	check("KONTROLL C1: a completed lead with its frozen context epoch", klar.lage == "complete"
		and klar.resultat ~= nil and klar.resultat.kontextNr == klar.kontextNr)
	local t = panelText()
	check("C1: unchanged context shows the led metres and the next step",
		har(t, tal1(klar.resultat.meter)) and har(t, Sprak.t("aterkoppling.leda.nasta")), t)
	for _ = 1, 4 do steg() end
	check("C1: further samples in the same context keep the same summary", panelText() == t)
	LararInstallning.satDetalj("kort")
	local tK = panelText()
	check("C2: concise in the same context: short line and next step, no numbers",
		har(tK, Sprak.t("aterkoppling.leda.kort")) and har(tK, Sprak.t("aterkoppling.leda.nasta"))
		and not har(tK, tal1(klar.resultat.meter)), tK)
	LararInstallning.satDetalj("detaljerad")
	-- Annan bunden häst (A → B) medan lektionen står i complete.
	aktuell = ANNAN
	steg()
	local efterB = bild()
	check("KONTROLL C1: the producer kept the result but advanced the context", efterB.lage == "complete"
		and efterB.resultat == klar.resultat and efterB.kontextNr ~= klar.resultat.kontextNr)
	t = panelText()
	check("C1: after A → B the old result is not attributed to B",
		t == ANNAN_TEXT and not har(t, tal1(klar.resultat.meter)), t)
	LararInstallning.satDetalj("kort")
	check("C2: concise keeps the stale-context text after A → B", panelText() == ANNAN_TEXT)
	LararInstallning.satDetalj("detaljerad")
	-- Den försenade äldre bilden (samma försök, lägre revision) återställer inget.
	Networking.get("LedLektionSync").OnClientEvent:Fire(klar)
	local p = Lc.panel()
	check("C1: a delayed older snapshot does not bring back A's summary", p and p.text == ANNAN_TEXT)
	-- Tillbaka till A: en NY kontextepok, fortfarande ingen gammal sammanfattning.
	aktuell = MIN
	steg()
	check("C1: returning to A is a new context, still no old summary", panelText() == ANNAN_TEXT)
	-- Ersättning med SAMMA HorseId efter ett slutfört försök.
	klar = slutfor()
	check("KONTROLL C1: completed again on A", klar.lage == "complete"
		and har(panelText(), tal1(klar.resultat.meter)))
	local MIN3 = byggHast(MIN_ID, varld(UTE_X - 3, MITT_Y))
	aktuell = MIN3
	steg()
	t = panelText()
	check("C1: a same-HorseId model replacement is not shown the old result", t == ANNAN_TEXT, t)
	aktuell = MIN
	MIN3.Parent = nil
	steg()
	-- Ny karaktär efter ett slutfört försök.
	klar = slutfor()
	check("KONTROLL C1: completed again before the character change", klar.lage == "complete")
	local nyK2, _, nyH2 = nyKaraktar(spelarRot.Position)
	nyH2.Health = 100
	spelare.Character = nyK2
	steg()
	t = panelText()
	check("C1: a replaced Character is not shown the old result", t == ANNAN_TEXT, t)
	spelare.Character = karaktar
	steg()
	-- Retry från den nya kontexten fungerar som förut och startar utan gammal text.
	LedService.slapp(spelare); flytta(UTE_X); steg()
	local okRetry = req("retry")
	t = panelText()
	check("C1: Retry in the current context starts a new attempt without any old summary",
		okRetry == true and not har(t, tal1(klar.resultat.meter)) and t ~= ANNAN_TEXT, t)
	req("finish")
	-- Tillbaka stänger sidan som förut (klienten synkar först den riktiga vägen).
	Lc._synkaForProv()
	local back = hitta(UgnetaController.panel(KAP).knappar, Sprak.t("ledlektion.back"))
	if back then back.skicka() end
	check("C1: Back still leaves the page", not Lc._valtForProv())
	UgnetaController.dolj()
end

if fails > 0 then error(tostring(fails) .. " FEL") end
print(string.format("\nLEDLEKTION: %d prov, alla gröna", total))
