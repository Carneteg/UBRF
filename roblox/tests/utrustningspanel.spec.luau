--!nostrict
--[[
	EQUIPMENT & RIDER GEAR GATE (#165) — klienten och enhetspariteten.

	Ordern 03:46: hjälm, sadel och träns ska gå att sätta på och ta av på
	tangentbord/mus, handkontroll, iPad- och iPhone-touch genom samma
	tillstånd, utan odokumenterade tangenter och utan att stjäla rörelse-
	eller kamerareglage. Det som mäts här:

	  1. panelen ritar utrustningsraderna ur `vy.utrustning` (serverns
	     världsläsning), som 44 px-knappar bland momenten;
	  2. fingret/musen: knappens `Activated` skickar `Utrustning` med
	     rätt typ och riktning;
	  3. tangentbord och handkontroll: markeringen går mellan knapparna
	     och `Enter`/`A` trycker på SAMMA knapp — genom klientens egen
	     `InputBegan`, inte genom ett direktanrop;
	  4. hjälpen namnger reglagen per inmatning och pekar aldrig på en
	     tangent för en ren pekenhet;
	  5. ingenting ritas medan man rider; eftervården visar hjälmen av.

	Kör: python3 roblox/tests/build.py tests/utrustningspanel.spec.luau
	     && luau roblox/tests/.build/utrustningspanel.spec.luau
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
local UserInputService = game:GetService("UserInputService")

--[[ En karaktär så att HUD:ens avståndsfråga har en kropp; ingen häst i
	världen → avståndet är nil → inom räckhåll. ]]
do
	local k = Instance.new("Model")
	k.Name = "Spelare"
	local r = Instance.new("Part")
	r.Name = "HumanoidRootPart"
	r.Size = Vector3.new(2, 2, 1)
	r.CFrame = CFrame.new(Vector3.new(0, 0, 0))
	r.Parent = k
	k.Parent = workspace
	Players.LocalPlayer.Character = k
end

local remote = Networking.get("Utrustning")
local function senastSkickat()
	local s = remote._skickat[#remote._skickat]
	return s
end
local function antalSkickat() return #remote._skickat end

local hastId = Stallet.FORSTA_DAGEN_HAST
local state = Preparation.nyState(hastId, 1)
--[[ HUD:en ritar bara om på en NYARE revision (`Preparation.farRita`), så
	varje vy här får ett högre nummer — precis som serverns `nastaRev`. ]]
local revN = 0
local function vyMed(utr, status)
	revN += 1
	local vy = Preparation.vy(state, status or "preparing", revN, "Jack")
	vy.utrustning = utr
	return vy
end

local function knapp(id) return PreparationController._ytor().moment:FindFirstChild(id) end
local function synlig(id) local k = knapp(id) return k ~= nil and k.Visible == true end

-- ══ 1. RADERNA ═════════════════════════════════════════════════════════
print("\n── 1. Utrustningsraderna ritas ur serverns världsläsning ──")
do
	PreparationController.tillampa(vyMed({ hjalm = false, sadel = true, trans = true,
		underlagg = true, hjalmKravs = true, rider = false }))
	PreparationController.uppdateraKontext()
	--[[ Hopfälld visar panelen bara momentet på tur; raderna nedan står
		bakom "Visa alla" — samma knapp som resten av skötseln. ]]
	check("hopfälld: utrustningsraderna står bakom 'Visa alla', som momenten",
		not synlig("utr:hjalm_pa") and PreparationController.layout().interaktionVal >= 4,
		tostring(PreparationController.layout().interaktionVal))
	if not PreparationController.layout().interaktionUt then PreparationController._vaxlaInteraktion() end
	check("'Ta på hjälmen' finns när hjälmen är av", synlig("utr:hjalm_pa"))
	check("'Ta av sadeln' finns när sadeln sitter på", synlig("utr:sadel_av"))
	check("'Ta av tränset' finns när tränset sitter på", synlig("utr:trans_av"))
	check("men inte 'Ta av hjälmen'", not synlig("utr:hjalm_av"))
	local k = knapp("utr:hjalm_pa")
	check("raden är en riktig knapp med 44 px träffyta (KONTROLLMATRIS regel 5)",
		k ~= nil and k.ClassName == "TextButton"
			and k.Size.Y.Offset == PreparationController.TRAFFYTA, k and tostring(k.Size.Y.Offset) or "-")
	check("och texten kommer ur språkkanonen", k ~= nil and k.Text == Sprak.t("tack.hjalm_pa"),
		k and k.Text or "-")
	check("den går att trycka på (kopplad)", PreparationController._momentGarAttTrycka("utr:hjalm_pa"))

	PreparationController.tillampa(vyMed({ hjalm = true, sadel = false, trans = false,
		underlagg = false, hjalmKravs = true, rider = false }))
	check("med hjälmen på: 'Ta av hjälmen', inga av-rader för sadel/träns",
		synlig("utr:hjalm_av") and not synlig("utr:hjalm_pa")
			and not synlig("utr:sadel_av") and not synlig("utr:trans_av"))
end

-- ══ 2. FINGRET OCH MUSEN ═══════════════════════════════════════════════
print("\n── 2. Fingret/musen: knappen skickar avsikten ──")
do
	PreparationController.tillampa(vyMed({ hjalm = false, sadel = true, trans = true,
		underlagg = true, hjalmKravs = true, rider = false }))
	local n0 = antalSkickat()
	knapp("utr:hjalm_pa").Activated:Fire()
	local s = senastSkickat()
	check("'Ta på hjälmen' skickar Utrustning(hjalm, true)",
		antalSkickat() == n0 + 1 and s ~= nil and s[1] == "hjalm" and s[2] == true,
		s and (tostring(s[1]) .. "," .. tostring(s[2])) or "inget")
	--[[ Medan svaret är på väg är nästa tryck spärrat (`vantarPa`); servern
		svarar direkt i bänken så spärren släpper i `skicka`s task. ]]
	task.wait()
	knapp("utr:sadel_av").Activated:Fire()
	s = senastSkickat()
	check("'Ta av sadeln' skickar Utrustning(sadel, false)",
		s ~= nil and s[1] == "sadel" and s[2] == false)
	task.wait()
	knapp("utr:trans_av").Activated:Fire()
	s = senastSkickat()
	check("'Ta av tränset' skickar Utrustning(trans, false)",
		s ~= nil and s[1] == "trans" and s[2] == false)
	task.wait()
end

-- ══ 3. TANGENTBORD OCH HANDKONTROLL ════════════════════════════════════
print("\n── 3. Tangentbord och handkontroll: markeringen trycker på samma knapp ──")
local function tryck(kod)
	UserInputService.InputBegan:Fire({ KeyCode = kod, UserInputType = Enum.UserInputType.Keyboard }, false)
end
do
	PreparationController.tillampa(vyMed({ hjalm = false, sadel = true, trans = true,
		underlagg = true, hjalmKravs = true, rider = false }))
	if PreparationController.layout().interaktionUt then PreparationController._vaxlaInteraktion() end
	check("ingen markering från början", PreparationController._vald() == nil)
	tryck(KontrollHjalp.PANEL_NASTA_TANGENT)
	local forsta = PreparationController._vald()
	check("pil ned markerar den första tryckbara knappen", forsta ~= nil, tostring(forsta))
	check("och fäller ut panelen så att alla val syns — utan musknappen 'Visa alla'",
		PreparationController.layout().interaktionUt == true and synlig("utr:hjalm_pa"))
	--[[ Gå hela varvet: markeringen ska nå utrustningsraderna och sedan
		börja om — ingen knapp får vara onåbar. ]]
	local sedda, steg = {}, 0
	repeat
		sedda[PreparationController._vald() or "?"] = true
		tryck(KontrollHjalp.PANEL_NASTA_TANGENT)
		steg += 1
	until PreparationController._vald() == forsta or steg > 40
	check("markeringen når alla tre utrustningsraderna och går runt",
		sedda["utr:hjalm_pa"] and sedda["utr:sadel_av"] and sedda["utr:trans_av"] and steg <= 40,
		("%d steg"):format(steg))
	--[[ Markera hjälmraden och tryck Enter. ]]
	steg = 0
	while PreparationController._vald() ~= "utr:hjalm_pa" and steg < 40 do
		tryck(KontrollHjalp.PANEL_NASTA_TANGENT)
		steg += 1
	end
	local m = knapp("utr:hjalm_pa"):FindFirstChild("Markering")
	check("den markerade knappen bär en synlig markering", m ~= nil and m.ClassName == "UIStroke")
	local n0 = antalSkickat()
	tryck(KontrollHjalp.PANEL_AKTIVERA_TANGENT)
	local s = senastSkickat()
	check("Enter skickar exakt det fingret hade skickat: Utrustning(hjalm, true)",
		antalSkickat() == n0 + 1 and s ~= nil and s[1] == "hjalm" and s[2] == true)
	task.wait()
	--[[ Pil upp går bakåt; handkontrollens styrkors gör samma sak. ]]
	tryck(KontrollHjalp.PANEL_FOREGAENDE_TANGENT)
	local bak = PreparationController._vald()
	tryck(KontrollHjalp.PANEL_NASTA_GAMEPAD)
	check("pil upp går bakåt och styrkors höger framåt igen",
		bak ~= "utr:hjalm_pa" and PreparationController._vald() == "utr:hjalm_pa", tostring(bak))
	steg = 0
	while PreparationController._vald() ~= "utr:trans_av" and steg < 40 do
		tryck(KontrollHjalp.PANEL_NASTA_GAMEPAD)
		steg += 1
	end
	n0 = antalSkickat()
	tryck(KontrollHjalp.PANEL_AKTIVERA_GAMEPAD)
	s = senastSkickat()
	check("A på handkontrollen trycker på den markerade raden: Utrustning(trans, false)",
		antalSkickat() == n0 + 1 and s ~= nil and s[1] == "trans" and s[2] == false)
	task.wait()
	--[[ Reglagen är dokumenterade i KontrollHjalp, inte gissade. ]]
	check("bindningarna är namngivna konstanter i KontrollHjalp",
		KontrollHjalp.PANEL_FOREGAENDE_GAMEPAD == Enum.KeyCode.DPadLeft
			and KontrollHjalp.PANEL_NASTA_GAMEPAD == Enum.KeyCode.DPadRight
			and KontrollHjalp.PANEL_AKTIVERA_GAMEPAD == Enum.KeyCode.ButtonA
			and KontrollHjalp.PANEL_AKTIVERA_TANGENT == Enum.KeyCode.Return)
	--[[ En markering på en rad som försvinner släpps. ]]
	PreparationController.tillampa(vyMed({ hjalm = true, sadel = false, trans = false,
		underlagg = false, hjalmKravs = true, rider = false }))
	check("markeringen släpps när raden inte längre visas",
		PreparationController._vald() == nil or synlig(PreparationController._vald()),
		tostring(PreparationController._vald()))
end

-- ══ 4. HJÄLPEN ═════════════════════════════════════════════════════════
print("\n── 4. Hjälpen namnger reglagen per inmatning ──")
do
	local usv = UserInputService
	local kb, gp, touch = usv.KeyboardEnabled, usv.GamepadEnabled, usv.TouchEnabled
	local function raderMed(t, g, p)
		usv.KeyboardEnabled, usv.GamepadEnabled, usv.TouchEnabled = t, g, p
		local m = {}
		for _, r in KontrollHjalp.rader() do m[r.vad] = r.reglage end
		return m
	end
	local tgb, pad, pek = raderMed(true, false, false), raderMed(false, true, false), raderMed(false, false, true)
	local vad = Sprak.t("hjalp.utrustning")
	check("tangentbordet: pil upp/ned + Enter", tgb[vad] == "↑ ↓ + Enter", tostring(tgb[vad]))
	check("handkontrollen: styrkors vänster/höger + A", pad[vad] == "◀ ▶ + A", tostring(pad[vad]))
	check("pekenheten: knapparna i panelen — ingen tangent",
		pek[vad] == Sprak.t("touch.panelknapparna") and not tostring(pek[vad]):find("Enter", 1, true),
		tostring(pek[vad]))
	usv.KeyboardEnabled, usv.GamepadEnabled, usv.TouchEnabled = kb, gp, touch
end

-- ══ 5. RIDNING OCH EFTERVÅRD ═══════════════════════════════════════════
print("\n── 5. Inget på hästryggen; hjälmen av i eftervården ──")
do
	PreparationController.tillampa(vyMed({ hjalm = true, sadel = true, trans = true,
		underlagg = true, hjalmKravs = true, rider = true }, "riding"))
	check("medan man rider ritas inga utrustningsrader",
		not synlig("utr:hjalm_av") and not synlig("utr:sadel_av") and not synlig("utr:trans_av"))
	tryck(KontrollHjalp.PANEL_NASTA_TANGENT)
	check("och markeringen har inget att fastna på", PreparationController._vald() == nil)

	local moment = {}
	for i, m in ipairs(Pass.moment()) do
		table.insert(moment, { id = m.id, namn = m.namn, text = m.text, klar = false })
	end
	PreparationController.tillampa(vyMed({ hjalm = true, sadel = true, trans = true,
		underlagg = true, hjalmKravs = true, rider = false }, "preparing"))
	revN += 1
	PreparationController.tillampaPass({ lage = "aftercare", moment = moment,
		nastaMoment = moment[1].id, klar = false, rev = revN })
	check("eftervården visar 'Ta av hjälmen'", synlig("utr:hjalm_av"))
	check("men INTE sadel/träns av — de är eftervårdens egna moment",
		not synlig("utr:sadel_av") and not synlig("utr:trans_av") and synlig("sadel") and synlig("trans"))
end

if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("\nutrustningspanel.spec: alla gröna")
end
