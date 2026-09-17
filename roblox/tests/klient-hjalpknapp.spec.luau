--!nostrict
--[[ ?-KNAPPEN FÅR INTE LIGGA ÖVER GÅNGARTERNA PÅ EN TELEFON I LANDSKAP (#227)

	`KontrollHjalp` ritar sin permanenta `?`-knapp uppe till höger, 48 px
	med 12 px marginal, i en ScreenGui som respekterar topbaren. Filhuvudet
	i modulen säger att hörnet är ledigt: spaken nere till vänster,
	ridknapparna nere till höger. På en iPad stämmer det. På en telefon i
	landskap gör det inte det: #208-skalan trycker ihop gångartsgallret
	tills det når nästan upp till topbaren, och då ligger `?` (DisplayOrder
	16) rakt över HALT/SKRITT (HorseTouch, DisplayOrder 8). Uppmätt i
	#221:s spec, iPhone 13 i landskap: `?` x 689..737 · y 48..96 mot
	gångarterna x 565..729 · y 45..191.

	Kontraktet som mäts här:
	  1. REPRODUKTIONEN — på sin ursprungliga plats hade `?` legat över
	     gångarterna på alla tre telefonerna (inte på iPad). Utan den raden
	     mäter resten ingenting.
	  2. medan man rider ligger `?` FRI från spak, gångarter och hjälpare,
	     helt på skärmen, fortfarande 48 px och SYNLIG — hjälpen göms inte
	     under ritten,
	  3. den öppnar och stänger hjälpen som förut (återöppningen, #161), och
	     `H` gör detsamma,
	  4. en vridning mitt i ritten lägger `?` rätt mot de OMBYGGDA reglagen,
	  5. avsittningen lämnar tillbaka `?` i hörnet,
	  6. iPaden är oförändrad: `?` står kvar i hörnet, pixel för pixel.

	38 PX-FRÅGAN (#227 punkt 5) mäts också, men som DOKUMENTATION: på den
	uppmätta iPhone 13-skärmen ger #208-skalan exakt 44 px gångartsknappar
	(golvet i KONTROLLMATRIS regel 5). På den antagna 568×320-skärmen ger
	samma skala 38 px — och två galler med tre rader à 44 px behöver mer
	höjd än skärmen har. Det är en konflikt mellan två krav, inte ett
	layoutfel som går att rätta utan omdesign; specen skriver ut talen och
	fäller inget.

	SKÄRMARNA är samma som i klient-reservzon.spec, med samma källor:
	749×367 (#185, avläst), 844×390 och 568×320 (klient.spec i landskap),
	1024×768 iPad som kontroll. Bänken har ingen layoutmotor: rutorna
	räknas ur UDim2 som Roblox gör, i skärmens pixlar med topbar 36.

	Kör: python3 roblox/tests/build.py tests/klient-hjalpknapp.spec.luau
	     && luau roblox/tests/.build/klient-hjalpknapp.spec.luau ]]

local fel = 0
local function prova(vad, ok, detalj)
	if ok then
		print(("  OK   %s%s"):format(vad, if detalj then "  " .. detalj else ""))
	else
		fel += 1
		print(("  FEL  %s%s"):format(vad, if detalj then "  " .. detalj else ""))
	end
end

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local player = Players.LocalPlayer
local cam = workspace.CurrentCamera
local Net = Networking

local function inset()
	return GuiService:GetGuiInset().Y
end
local function barn(inst, namn)
	for _, b in ipairs(inst and inst._barn or {}) do
		if b.Name == namn then return b end
	end
	return nil
end
--[[ En rams ruta i skärmens pixlar. Hjälpknappens och HorseTouch:s
	ScreenGui respekterar båda topbaren, så deras GUI-yta är viewporten
	minus inset och skärm-y är GUI-y plus inset. AnchorPoint räknas in. ]]
local function rekt(f, W, Hg, dy)
	local p, s, a = f.Position, f.Size, f.AnchorPoint or { X = 0, Y = 0 }
	local b = W * s.X.Scale + s.X.Offset
	local h = Hg * s.Y.Scale + s.Y.Offset
	local x = W * p.X.Scale + p.X.Offset - a.X * b
	local y = Hg * p.Y.Scale + p.Y.Offset - a.Y * h + dy
	return { x0 = x, y0 = y, x1 = x + b, y1 = y + h }
end
local function skar(a, b)
	return a.x0 < b.x1 and b.x0 < a.x1 and a.y0 < b.y1 and b.y0 < a.y1
end
local function r2s(r)
	return ("x %d..%d y %d..%d"):format(r.x0, r.x1, r.y0, r.y1)
end

--[[ ══ RESERVZONEN EFTER ATT PANELEN REVS ═══════════════════════════

     `Gangarter` och `Knappar` var två `Frame` vi själva byggde, och de gick
     att mäta med `rekt()`. Panelen revs 2026-09-17: DRIV, BROMS och SITT AV
     är `ContextActionService`-handlingar, och deras knappar ligger i
     Roblox EGEN `ContextActionGui` — en yta vår kod varken skapar, äger
     eller kan flytta.

     Reserven mäts därför mot det KONTRAKT resten av klienten faktiskt
     läser: `TouchControls.reglageBredd()` och `reglageTopp()`. Det är de
     två talen lektionskortet och hjälpknappen viker undan för, och det är
     alltså exakt den ruta som ska vara fri. Mätningen blev starkare av
     bytet, inte svagare — den mäter nu det andra moduler tror på i stället
     för ett internt ramnamn.

     Rutan heter `Handlingar`, så att loggen säger vad den är. ]]
local function handlingsrekt(W, H)
	local b = TouchControls.reglageBredd()
	local t = TouchControls.reglageTopp()
	if b <= 0 or t == math.huge then return nil end
	return { x0 = W - b, x1 = W, y0 = t, y1 = H }
end

local RESERV = { "Spak" }
local function reserv(W, H)
	local ht = barn(player._gui, "HorseTouch")
	if not ht then return nil end
	local ut = {}
	for _, namn in ipairs(RESERV) do
		local f = barn(ht, namn)
		if f then ut[namn] = rekt(f, W, H - inset(), inset()) end
	end
	ut.Handlingar = handlingsrekt(W, H)
	return ut, ht
end
local function hjalpRekt(W, H)
	local b = KontrollHjalp._oppnaKnapp()
	if not b then return nil end
	return rekt(b, W, H - inset(), inset()), b
end
--[[ Knappens URSPRUNGLIGA plats — hörnet, 12 px in — räknad ur knappens
	egen storlek. Det är reproduktionen: så låg den före #227. ]]
local function hornet(W, H, b)
	local s = b.Size.X.Offset
	return { x0 = W - 12 - s, x1 = W - 12, y0 = inset() + 12, y1 = inset() + 12 + s }
end
local function krockar(r, res)
	local lista = {}
	for namn, rr in pairs(res or {}) do
		if skar(r, rr) then table.insert(lista, namn) end
	end
	table.sort(lista)
	return lista
end

local dt = 1 / 30
local function bildrutor(n)
	for _ = 1, n do RunService.RenderStepped:Fire(dt) end
end
local function tryck(kod)
	UIS.InputBegan:Fire({ KeyCode = kod }, false)
end

local SKARMAR = {
	{ namn = "iPhone 13 landskap", W = 749, H = 367, telefon = true, vrid = { W = 844, H = 390 },
		kalla = "#185, avläst ur levande klient" },
	{ namn = "telefon 844×390 landskap", W = 844, H = 390, telefon = true, vrid = { W = 749, H = 367 },
		kalla = "klient.spec/varldshud.spec 'telefon 390×844'" },
	{ namn = "liten telefon 568×320 landskap", W = 568, H = 320, telefon = true, vrid = { W = 749, H = 367 },
		kalla = "klient.spec 'liten telefon 320×568'" },
	{ namn = "iPad landskap 1024×768", W = 1024, H = 768, telefon = false, vrid = { W = 749, H = 367 },
		kalla = "forberedelse.spec/klient.spec" },
}

local foreKb, foreGp, foreTouch = UIS.KeyboardEnabled, UIS.GamepadEnabled, UIS.TouchEnabled
local foreVp = cam.ViewportSize

--[[ En ren pekenhet: då byggs `?`. Samma beslut `KontrollHjalp.start` gör i
	produktion, och samma väg klient.spec tar. ]]
UIS.KeyboardEnabled, UIS.GamepadEnabled, UIS.TouchEnabled = false, false, true
KontrollHjalp.start()
prova("en pekenhet får en permanent ?-knapp", KontrollHjalp._oppnaKnapp() ~= nil)

for _, sk in ipairs(SKARMAR) do
	local W, H = sk.W, sk.H
	print(("\n── %s (%d×%d, topbar %d px) · källa: %s ──"):format(
		sk.namn, W, H, inset(), sk.kalla))
	cam.ViewportSize = { _typ = "Vector2", X = W, Y = H }

	--[[ I stallet: ingen reserv, knappen i hörnet. ]]
	local fore, b = hjalpRekt(W, H)
	prova("i stallet står ? i hörnet", fore ~= nil and fore.x1 == W - 12 and fore.y0 == inset() + 12,
		fore and r2s(fore))

	--[[ Uppsittningen genom produktionens egen väg. ]]
	local hast = __makeHastModell("Bamse" .. W)
	hast.Parent = workspace
	Net.get("MountChanged").OnClientEvent:Fire(hast, player)
	bildrutor(3)
	local res, ht = reserv(W, H)
	prova("uppsittningen monterade pekreglagen", res ~= nil)
	--[[ Första uppsittningen visar hjälpen av sig själv (#161). Stäng den,
		så att knappen är den som mäts. ]]
	if KontrollHjalp.synlig() then KontrollHjalp.dolj() end

	--[[ ══ 1. REPRODUKTIONEN GÅR INTE LÄNGRE ATT GÖRA ═══════════════════

		#227 var att #208-skalan tryckte ihop gångartsgallret tills det nådde
		nästan upp till topbaren, och `?` (y 48..96) låg rakt i det. Panelen
		revs 2026-09-17 och de tre handlingarna ligger i ett 2×2 som är
		hälften så högt — reserven börjar nu långt under hörnet på ALLA
		mätta skärmar, telefonerna inkluderade.

		Att låta raden stå kvar hade varit ett prov som kräver en bugg.
		I stället mäts REGELN, och den mäts åt båda hållen:

		  a) hörnet är fritt på varje skärm i tabellen,
		  b) men skulle reserven någonsin nå upp dit igen viker `?` undan.

		(b) matas med en påhittad reserv rakt in i `reservAndrad`, alltså
		exakt den kanal `TouchControls` använder. Utan (b) vore (a) grön
		också om undanvikandet var borttaget. ]]
	local horn = hornet(W, H, b)
	local hornKrock = krockar(horn, res)
	prova("hörnet är fritt: handlingsblocket når inte upp till ?",
		#hornKrock == 0,
		("? %s · handlingar %s"):format(r2s(horn),
			res and res.Handlingar and r2s(res.Handlingar) or "-"))
	do
		--[[ En reserv som når HELA vägen upp — det gamla gallret i
			miniatyr. Knappen ska då stå till vänster om den. ]]
		--[[ En px OVANFÖR knappens underkant, i GUI-koordinater.

			`reglageTopp` mäts i `TouchControls` GUI-yta — viewporten minus
			topbaren — och `placeraOppna` jämför mot samma yta. `horn` ovan
			är däremot skärmens pixlar, alltså GUI plus inset. Talen är
			`KontrollHjalp`s egna men modullokala, så provet räknar dem ur
			knappen i stället för att kopiera dem hit. ]]
		local hogUppe = horn.y1 - inset() - 1
		KontrollHjalp.reservAndrad(200, hogUppe)
		local vikt = hjalpRekt(W, H)
		prova("MUTATION: en reserv som når hörnet får ? att vika undan",
			vikt.x1 < horn.x1, ("? högerkant %d mot hörnets %d"):format(vikt.x1, horn.x1))
		--[[ Och tillbaka till verkligheten. ]]
		KontrollHjalp.reservAndrad(TouchControls.reglageBredd(),
			TouchControls.reglageTopp())
	end

	--[[ 2. UNDER RITTEN. ]]
	local r = hjalpRekt(W, H)
	local k = krockar(r, res)
	prova("under ritten ligger ? fri från spaken och de tre handlingarna",
		#k == 0, ("? %s%s"):format(r2s(r), if #k > 0 then " · skär " .. table.concat(k, ", ") else ""))
	prova("? ligger helt på skärmen, under topbaren",
		r.x0 >= 0 and r.y0 >= inset() and r.x1 <= W and r.y1 <= H, r2s(r))
	prova("? är fortfarande 48 px i båda led",
		b.Size.X.Offset >= 48 and b.Size.Y.Offset >= 48,
		("%d×%d"):format(b.Size.X.Offset, b.Size.Y.Offset))
	prova("hjälpen göms inte under ritten: ? är synlig", b.Visible ~= false)
	--[[ SAMMA SVAR PÅ ALLA SKÄRMAR nu när blocket är lågt: `?` står kvar i
		hörnet, pixel för pixel, på telefon som på iPad. Telefonens
		särbehandling var en följd av gallrets höjd, inte av skärmen. ]]
	prova("? står kvar i hörnet, pixel för pixel",
		r.x0 == horn.x0 and r.x1 == horn.x1 and r.y0 == horn.y0 and r.y1 == horn.y1, r2s(r))

	--[[ 3. ÅTERÖPPNINGEN. ]]
	b.Activated:Fire()
	prova("? öppnar hjälpen", KontrollHjalp.synlig() == true)
	prova("och göms medan panelen står uppe", b.Visible == false)
	KontrollHjalp.dolj()
	local r3 = hjalpRekt(W, H)
	prova("stängd hjälp ger tillbaka ? på samma plats som förut",
		b.Visible == true and r3.x0 == r.x0 and r3.y0 == r.y0, r2s(r3))
	tryck(Enum.KeyCode.H)
	local viaH = KontrollHjalp.synlig()
	tryck(Enum.KeyCode.H)
	prova("H växlar hjälpen som förut", viaH == true and KontrollHjalp.synlig() == false)

	--[[ 4. VRIDNING MITT I RITTEN: reglagen byggs om (#208) och ? ska
		följa de nya reglagen, inte de gamla. Bänkens `AbsoluteSize` är ett
		rått fält, så provet fyrar signalen självt — samma sätt som
		touch.spec. ]]
	cam.ViewportSize = { _typ = "Vector2", X = sk.vrid.W, Y = sk.vrid.H }
	if ht then ht:GetPropertyChangedSignal("AbsoluteSize"):Fire() end
	task.wait()
	local res2 = reserv(sk.vrid.W, sk.vrid.H)
	local r4 = hjalpRekt(sk.vrid.W, sk.vrid.H)
	local k4 = krockar(r4, res2)
	prova(("efter vridning till %d×%d ligger ? fri från de ombyggda reglagen"):format(sk.vrid.W, sk.vrid.H),
		res2 ~= nil and #k4 == 0,
		("? %s · handlingar %s%s"):format(r2s(r4),
			res2 and res2.Handlingar and r2s(res2.Handlingar) or "-",
			if #k4 > 0 then " · skär " .. table.concat(k4, ", ") else ""))
	cam.ViewportSize = { _typ = "Vector2", X = W, Y = H }
	local ht2 = barn(player._gui, "HorseTouch")
	if ht2 then ht2:GetPropertyChangedSignal("AbsoluteSize"):Fire() end
	task.wait()

	--[[ 38 PX-FRÅGAN, dokumenterad. ]]
	local ht3 = barn(player._gui, "HorseTouch")
	local halt = ht3 and barn(barn(ht3, "Gangarter"), "Halt")
	local res3 = reserv(W, H)
	if halt and res3 and res3.Gangarter and res3.Knappar then
		local kh = halt.Size.Y.Offset
		local Hg = H - inset()
		--[[ Vad två galler med tre rader à 44 px hade BEHÖVT, med de
			mellanrum layouten faktiskt använder på den här skärmen:
			radluft ur gallrets höjd, gapet mellan gallren, och kanten
			under det nedre. Räknat ur instanserna, inte ur en kopia. ]]
		local gallerH = res3.Gangarter.y1 - res3.Gangarter.y0
		local radluft = (gallerH - 3 * kh) / 2
		local gap = res3.Knappar.y0 - res3.Gangarter.y1
		local kant = (H - res3.Knappar.y1)
		local behov44 = 2 * (3 * 44 + 2 * radluft) + gap + kant
		print(("       gångartsknapp %d×%d px · GUI-höjd %d · två galler à 3×44 px behöver %d px%s"):format(
			halt.Size.X.Offset, kh, Hg, behov44,
			if behov44 > Hg then " → KONFLIKT: ryms inte utan omdesign" else " → ryms"))
		if W == 749 then
			prova("på den uppmätta iPhone 13-skärmen når gångartsknappen 44 px-golvet",
				kh >= 44, ("%d px"):format(kh))
		end
	end

	--[[ 5. AVSITTNINGEN. ]]
	Net.get("MountChanged").OnClientEvent:Fire(hast, nil)
	local r5 = hjalpRekt(W, H)
	prova("efter avsittningen står ? i hörnet igen",
		reserv(W, H) == nil and r5.x1 == W - 12 and r5.y0 == inset() + 12, r2s(r5))
end

UIS.KeyboardEnabled, UIS.GamepadEnabled, UIS.TouchEnabled = foreKb, foreGp, foreTouch
cam.ViewportSize = foreVp

if fel > 0 then
	print(("\n%d mätningar föll."):format(fel))
else
	print("\nAlla mätningar gick igenom.")
end
