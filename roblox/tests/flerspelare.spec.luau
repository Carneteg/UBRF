--!nostrict
--[[ TVÅ SPELARE I SAMMA SERVER, OCH FRIA BLICKEN

	Order 2026-09-13 12:41 listar två krav som `hastresan.spec` inte tog,
	och som ingen annan spec heller tog. Båda är mätta här, båda gick att
	mäta genom produktionens egen väg.

	1. LOKALA MARKÖRER. Varje klient ska bara se SIN egen boxmarkör och
	   sina egna prompts. Felet är dokumenterat i `DinHast.luau:275`:
	   "Mätt med två spelare inne — Player2 såg fortfarande Player1:s
	   prompt." Rättelsen är ett svep en gång i sekunden som släcker andras
	   prompts, och den stod utan prov.

	2. FRIA BLICKEN. `TouchControls` bygger en blickyta på högra delen av
	   skärmen; ett drag vrider kameran. Ordern räknar den som accepterad
	   och kräver att den inte regredierar — men ingen spec rörde den:
	   `touch.spec` provar de rena funktionerna, och blicken bor inne i
	   `mount`s stängning.

	   VARFÖR VÄNSTRA TREDJEDELEN ÄR FRI står i koden: där bor spaken, och
	   en blickyta under den hade gjort varje styrutslag till en
	   kameravridning också. Det är den mätningen som betyder något för
	   mobilen, och den hänger ihop med reservzonen i `mobillayout.spec`.

	NOT TESTED: äkta multitouch, träffstack, fysisk enhet. ]]

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
local usv = game:GetService("UserInputService")

print("\nTVÅ SPELARE OCH FRIA BLICKEN")

--[[ ══ 1. VARJE KLIENT SER BARA SIN EGEN MARKÖR ═══════════════════════

	MÄTT, INTE ANTAGET: släckningen sker DIREKT när markören parentas, inte
	efter en sekund. Min första version byggde tre markörer, kollade att
	alla var tända, körde ett svep och kollade att två släckts — och föll
	på att de andra två redan var släckta. `DinHast.start()` (som
	klientingången redan kört) lyssnar på `workspace.ChildAdded` och
	defer:ar svepet, så en främmande markör släcks i samma bildruta den
	dyker upp. Sekundsvepet är bältet; `ChildAdded` är hängslet.

	Provet mäter därför den snabba vägen, som är den spelaren märker.
	Ingen Heartbeat körs: HUD-loopen läser tilldelningsdata som inte hör
	till den här mätningen. ]]
print("\n── 1. Andras boxmarkörer och prompts släcks ──")
do
	local function markor(namn: string)
		local m = Instance.new("Model")
		m.Name = "Boxmarkor_" .. namn
		local p = Instance.new("Part")
		p.Name = "Platta"
		p.Parent = m
		local pr = Instance.new("ProximityPrompt")
		pr.Name = "Prompt"
		pr.Enabled = true
		pr.Parent = p
		m.Parent = workspace
		return m, pr
	end

	local minNamn = Players.LocalPlayer.Name
	local _, minPrompt = markor(minNamn)
	local _, annansPrompt = markor("NagonAnnan")

	check("MIN egen prompt är tänd", minPrompt.Enabled == true,
		tostring(minPrompt.Enabled))
	check("ANDRAS prompt släcktes i samma bildruta den dök upp",
		annansPrompt.Enabled == false, tostring(annansPrompt.Enabled))

	--[[ SENARE ANSLUTNING: en tredje spelares markör efter att vi är igång.
		Det är precis fallet noten i `DinHast` beskriver. ]]
	local _, tredjesPrompt = markor("SenAnslutning")
	check("en markör som dyker upp SENARE släcks också",
		tredjesPrompt.Enabled == false, tostring(tredjesPrompt.Enabled))
	check("och min egen är fortfarande tänd", minPrompt.Enabled == true,
		tostring(minPrompt.Enabled))

	--[[ NAMNPREFIXET ÄR REGELN, inte likhet på hela namnet: en modell som
		inte är en boxmarkör ska inte röras alls. ]]
	local annan = Instance.new("Model")
	annan.Name = "Boxfront MB 7"
	local ap = Instance.new("ProximityPrompt")
	ap.Name = "Prompt"
	ap.Enabled = true
	ap.Parent = annan
	annan.Parent = workspace
	check("en modell som INTE är en boxmarkör rörs inte", ap.Enabled == true,
		tostring(ap.Enabled))
end

--[[ ══ 2. BLICKYTAN LÄMNAR SPAKEN I FRED ══════════════════════════════

	Mätt på geometrin, som är det som faktiskt skyddar styrningen. Koden
	säger "vänstra tredjedelen lämnas fri: där bor spaken"; provet mäter
	att blickytan börjar till höger om spakens reservzon — samma zon som
	`mobillayout.spec` håller skötselpanelen ur. ]]
print("\n── 2. Blickytan börjar till höger om spaken ──")
do
	usv.TouchEnabled = true
	local cam = game:GetService("Workspace").CurrentCamera
	cam.ViewportSize = { _typ = "Vector2", X = 749, Y = 309 }

	local pg = Instance.new("PlayerGui")
	pg.Name = "PlayerGui"
	Players.LocalPlayer._barn = { pg }

	--[[ Hela `Input`-ytan `TouchControls` rör, ur koden och inte ur minnet:
		`grep -o "Input\.[a-zA-Z]*"`. En halv tabell hade fällt provet i
		`unmount` i stället för i mätningen, vilket är precis vad den gjorde
		första gången. ]]
	local blickar = {}
	local falskInput = {
		consume = function() end,
		setTouch = function() end,
		setTouchRein = function() end,
		setTouchSeat = function() end,
		touchGait = function() end,
		touchGaitTo = function() end,
		touchJump = function() end,
		touchParad = function() end,
	}
	local avsutten = false
	TouchControls.mount(falskInput, {
		dismount = function() avsutten = true end,
		blick = function(dx, dy) table.insert(blickar, { dx, dy }) end,
	})

	local gui = pg:FindFirstChild("HorseTouch")
	check("pekreglagen byggdes", gui ~= nil)
	local yta = gui and gui:FindFirstChild("Blickyta", true)
	local spak = gui and gui:FindFirstChild("Spak", true)
	check("blickytan finns", yta ~= nil)
	check("spaken finns", spak ~= nil)

	if yta and spak then
		local yp, ys = yta.AbsolutePosition, yta.AbsoluteSize
		local sp, ss = spak.AbsolutePosition, spak.AbsoluteSize
		check("blickytan börjar till höger om spakens högerkant",
			yp.X >= sp.X + ss.X - 0.01,
			string.format("blick x0 %.0f mot spakens kant %.0f", yp.X, sp.X + ss.X))
		check("och blickytan täcker resten av skärmen åt höger",
			yp.X + ys.X >= 749 - 1,
			string.format("blick x1 %.0f av 749", yp.X + ys.X))
		check("spaken ligger i nedre VÄNSTRA hörnet, inte under blickytan",
			sp.X < yp.X and sp.Y + ss.Y > 309 * 0.5,
			string.format("spak (%.0f · %.0f)", sp.X, sp.Y))
	end
	TouchControls.unmount()
	usv.TouchEnabled = false
end

if fails > 0 then
	print(("\n%d mätning(ar) föll."):format(fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("\nflerspelare.spec: alla gröna")
end
