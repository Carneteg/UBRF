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
local karaktar, spelarRot = nyKaraktar(START)
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
local function req(op, p)
	seq += 1
	return LedLektion.begar(p or spelare, op, seq)
end
local function bild() local _, _, b = LedLektion.begar(spelare, "sync"); return b end
local function led() return LedService.borja(spelare, MIN) end

-- ── Hela vägen: start, leda, resa, ankomst ──
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
local ok2, fel2 = LedLektion.begar(andra, "start", 1)
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
local a1 = { LedLektion.begar(spelare, "retry", base + 1) }
local a2 = { LedLektion.begar(spelare, "retry", base + 1) }
check("a replayed request returns the same answer", a1[1] == a2[1] and a1[2] == a2[2])
local okAnnan = LedLektion.begar(spelare, "finish", base + 1)
check("the same sequence with another operation is refused", okAnnan == false)
LedLektion.begar(spelare, "sync", nil)
LedLektion.begar(spelare, "finish", base + 3)
local okGammal, felGammal = LedLektion.begar(spelare, "start", base + 2) -- aldrig använd, men äldre
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

if fails > 0 then error(tostring(fails) .. " FEL") end
print(string.format("\nLEDLEKTION: %d prov, alla gröna", total))
