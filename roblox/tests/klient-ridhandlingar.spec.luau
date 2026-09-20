--!nostrict
--[[
	RIDHANDLINGARNA PÅ PEKSKÄRM — bundna bara i sadeln, borta på varje
	väg ur den, och bara avsikt på tråden (#17).

	══ VAD #17 BEGÄR OCH VAD SOM REDAN FINNS ═══════════════════════════

	Ordern på #17 (07:19 UTC 2026-09-18) ber om `ContextActionService`-
	handlingar för DRIV och BROMS som binds ENBART när spelaren är
	auktoritativt uppsutten, rivs på alla utgångar, placeras ur reserv-
	geometrin och bara producerar semantiska avsikter genom #233:s
	kontrakt. Auditen mot `main` @ `2cfc23b` visar att #238 och #241 redan
	bär det: `ActionDriv`/`ActionBroms` binds i `Input.bind()` vid
	`mount()`, rivs i `Input.unbind()` vid `dismount()`, kläs av
	`TouchControls` genom `SetTitle`/`SetPosition`, och når tråden som
	`RidingIntent(rittId, "driv"|"broms", sekvens)`.

	Det som INTE fanns var ett prov som mäter hela livscykeln genom
	produktionens egen väg — `MountChanged` in, varje utgång ut — och
	kräver att handlingarna, knapparna och pekytan är borta EFTERÅT, och
	att ett tryck strax före utgången varken lämnar avsikt kvar eller når
	tråden. `driv-broms.spec` binder `Input` själv, `klient.spec` mäter
	avsittningens knapp; ingen mätte DRIV/BROMS över utgångarna.

	══ VAD SOM MÄTS ═════════════════════════════════════════════════════

	  1. Till fots: ingen av de tre handlingarna, ingen knapp, ingen pekyta.
	  2. Uppsittning genom `MountChanged`: alla tre bundna EXAKT en gång,
	     med pekknappar i CAS egen yta, ≥ 44 px, placerade i skärmens
	     nedre högra hörn innanför GUI-ytan — på iPhone 13 och iPad.
	  3. Ett DRIV-tryck via CAS ger EN `RidingIntent` med rittmärke,
	     handlingen `driv` och löpnummer; ett andra tryck inom spärren ger
	     ingen; efter spärren ger det en till. `End` på knappen gör
	     ingenting — ett släpp är inte en hjälp.
	  4. Sex utgångar, var och en med en avsikt och ett spakutslag
	     STRAX FÖRE: `MountChanged(häst, nil)`, `MountChanged(häst, annan
	     ryttare)`, `CharacterRemoving`, riggen lämnar `workspace`,
	     SITT AV-handlingen (DismountRequest), och hästbyte. Efteråt är
	     handlingarna rivna, knapparna borta, pekytan borta, nästa
	     bildrutas avsikt neutral, och ett tryck når varken CAS eller
	     tråden.
	  5. Hästbyte binder om exakt en gång — inga dubbla handlingar.

	Bänkgräns: gesten mäts inte (ingen pekskärm i bänken); det som mäts är
	kedjan från CAS-handling till tråd. Tap/hold-distinktionen i ordern
	går inte att uttrycka i #233-kontraktet utan att ändra serverns
	semantik och står som rapporterad kontraktslucka i PR:en, inte här.

	Kör: python3 roblox/tests/build.py tests/klient-ridhandlingar.spec.luau
	     && luau roblox/tests/.build/klient-ridhandlingar.spec.luau
]]

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
local CAS = game:GetService("ContextActionService")
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
local dt = 1 / 30
local function bildrutor(n, steg)
	for _ = 1, n do RunService.RenderStepped:Fire(steg or dt) end
end

--[[ En styrd klocka för spärren, som i touch.spec. ]]
local klocka = 5000.0
Input._klocka = function() return klocka end

--[[ Räknar VARJE BindAction per handling: stubbens `_bound` är en tabell
	och döljer en dubbelbindning. ]]
local bindningar = {}
do
	local orig = CAS.BindAction
	CAS.BindAction = function(self, namn, ...)
		bindningar[namn] = (bindningar[namn] or 0) + 1
		return orig(self, namn, ...)
	end
end

local HANDLINGAR = { Input.DRIV, Input.BROMS, Input.AVSITT }
local function bundna()
	local n = 0
	for _, h in ipairs(HANDLINGAR) do
		if CAS._bound[h] ~= nil then n += 1 end
	end
	return n
end
local function knappar()
	local n = 0
	for _, h in ipairs(HANDLINGAR) do
		if CAS:GetButton(h) ~= nil then n += 1 end
	end
	return n
end
local function pekyta()
	return barn(player._gui, "HorseTouch")
end

--[[ Kortet tar över en bildruta in i ritten och kastar varje avsikt tills
	det kvitteras — samma väg som klient.spec går. ]]
local function kvitteraKort()
	for _ = 1, 8 do
		if not LektionController.vantar() then break end
		LektionController.gaVidare()
		bildrutor(1)
	end
	return not LektionController.vantar()
end

local remote = Net.get("RidingIntent")
local tillstand = Net.get("RidTillstand")
local avsittning = Net.get("DismountRequest")

--[[ En färsk häst per fall: en rigg överlever inte avsittningen i bänken. ]]
local hastNr = 0
local function nyHast()
	hastNr += 1
	local h = __makeHastModell("Provhast" .. hastNr)
	h:SetAttribute("RidSession", "ritt-" .. hastNr)
	h.Parent = workspace
	return h
end

--[[ Sitter upp genom produktionens egen väg och ställer ritten i skritt så
	att ett DRIV har någonstans att ta vägen. ]]
local function sittUpp(h)
	Net.get("MountChanged").OnClientEvent:Fire(h, player)
	bildrutor(2)
	kvitteraKort()
	tillstand.OnClientEvent:Fire({ hast = h, ritt = h:GetAttribute("RidSession"),
		gangart = "walk", ryggar = false, version = 10 + hastNr })
	bildrutor(1)
	remote._skickat = {}
	Input.nollaImpulsSparr()
end

--[[ Ett tryck på en handling genom CAS — exakt spelarens väg. ]]
local function tryck(handling, lage)
	local fn = CAS._bound[handling]
	if not fn then return false end
	fn(handling, lage or Enum.UserInputState.Begin, { KeyCode = Enum.KeyCode.Unknown })
	return true
end

local foreTouch, foreVp = UIS.TouchEnabled, cam.ViewportSize
UIS.TouchEnabled = true
cam.ViewportSize = { _typ = "Vector2", X = 749, Y = 367 }

--[[ ══ 1. TILL FOTS ═══════════════════════════════════════════════════ ]]
print("\n── 1. Till fots finns ingen ridhandling ──")
do
	prova("ingen av DRIV, BROMS eller SITT AV är bunden", bundna() == 0,
		("(%d bundna)"):format(bundna()))
	prova("och ingen pekknapp finns", knappar() == 0)
	prova("och ingen pekyta", pekyta() == nil)
	remote._skickat = {}
	prova("ett tryck till fots når inte CAS", tryck(Input.DRIV) == false)
	bildrutor(2)
	prova("och ingenting går på tråden", #remote._skickat == 0)
end

--[[ ══ 2. UPPSUTTEN: BUNDNA EN GÅNG, PLACERADE INNANFÖR SKÄRMEN ══════ ]]
print("\n── 2. Uppsittningen binder de tre handlingarna en gång ──")
local SKARMAR = {
	{ namn = "iPhone 13 landskap", W = 749, H = 367 },
	{ namn = "iPad landskap", W = 1024, H = 768 },
}
for _, sk in ipairs(SKARMAR) do
	local W, H = sk.W, sk.H
	cam.ViewportSize = { _typ = "Vector2", X = W, Y = H }
	local fore = {}
	for _, h in ipairs(HANDLINGAR) do fore[h] = bindningar[h] or 0 end
	local h = nyHast()
	sittUpp(h)
	prova(("%s: alla tre handlingarna är bundna"):format(sk.namn), bundna() == 3,
		("(%d)"):format(bundna()))
	local enGang = true
	for _, namn in ipairs(HANDLINGAR) do
		if (bindningar[namn] or 0) - fore[namn] ~= 1 then enGang = false end
	end
	prova("och var och en bands EXAKT en gång", enGang,
		("(driv +%d · broms +%d · sitt av +%d)"):format(
			(bindningar[Input.DRIV] or 0) - fore[Input.DRIV],
			(bindningar[Input.BROMS] or 0) - fore[Input.BROMS],
			(bindningar[Input.AVSITT] or 0) - fore[Input.AVSITT]))
	prova("alla tre ritar en pekknapp som CAS äger", knappar() == 3)
	prova("pekytan med spaken finns", pekyta() ~= nil and TouchControls.isActive())

	--[[ Placeringen: `SetPosition` ankrar i nedre högra hörnet, innanför
		GUI-ytan (viewporten minus topbaren), och knappen är ≥ 44 px. ]]
	local Hg = H - inset()
	local inne, stora = true, true
	for _, namn in ipairs({ Input.DRIV, Input.BROMS }) do
		local p = CAS._plats[namn]
		local b = CAS:GetButton(namn)
		if not p or not b then inne = false; stora = false; break end
		local x1 = W * p.X.Scale + p.X.Offset
		local y1 = Hg * p.Y.Scale + p.Y.Offset
		local kd = b.Size.X.Offset
		if kd < 44 then stora = false end
		if x1 > W or y1 > Hg or x1 - kd < W / 2 or y1 - kd < 0 then inne = false end
		print(("       %-12s hörn %d,%d  storlek %d px"):format(namn, x1, y1 + inset(), kd))
	end
	prova("DRIV och BROMS är minst 44 px", stora)
	prova("och ligger i skärmens nedre högra hörn, innanför GUI-ytan", inne)
	prova("reserven rapporteras — kort och hjälp kan vika undan",
		TouchControls.reglageBredd() > 0 and TouchControls.reglageTopp() < H,
		("(bredd %d · topp %d)"):format(TouchControls.reglageBredd(), TouchControls.reglageTopp()))

	--[[ Städa: av genom servern. ]]
	Net.get("MountChanged").OnClientEvent:Fire(h, nil)
	bildrutor(1)
end
cam.ViewportSize = { _typ = "Vector2", X = 749, Y = 367 }

--[[ ══ 3. ETT TRYCK ÄR EN AVSIKT ═══════════════════════════════════════ ]]
print("\n── 3. Ett tryck på DRIV är en avsikt på tråden, inte ett tillstånd ──")
do
	local h = nyHast()
	sittUpp(h)
	klocka += 10
	prova("DRIV-trycket når handlingen", tryck(Input.DRIV) == true)
	bildrutor(2)
	local paket = remote._skickat[1]
	prova("exakt EN RidingIntent gick ut", #remote._skickat == 1,
		("(%d paket)"):format(#remote._skickat))
	prova("och den bär rittmärket", paket ~= nil and paket[1] == h:GetAttribute("RidSession"),
		("(%s)"):format(tostring(paket and paket[1])))
	prova("handlingen är `driv` — ingen gångart, ingen fart, inget CFrame",
		paket ~= nil and paket[2] == Ridtrappa.DRIV and type(paket[3]) == "number",
		("(%s, %s)"):format(tostring(paket and paket[2]), tostring(paket and paket[3])))

	--[[ Spärren: ett andra tryck inom 0,60 s ger ingen ny avsikt, oavsett
		bildrutetakt. ]]
	remote._skickat = {}
	klocka += 0.20
	tryck(Input.DRIV)
	bildrutor(3, 1 / 120)
	tryck(Input.DRIV)
	bildrutor(3, 1 / 20)
	prova("två tryck inom spärren ger ingen ny avsikt", #remote._skickat == 0,
		("(%d paket)"):format(#remote._skickat))
	klocka += 1.0
	tryck(Input.DRIV)
	bildrutor(2)
	prova("efter spärren går nästa tryck ut", #remote._skickat == 1,
		("(%d paket)"):format(#remote._skickat))

	--[[ ETT SLÄPP ÄR INTE EN HJÄLP: `End` på BROMS gör ingenting. Det är
		den halva av #17:s hold-krav som kontraktet faktiskt bär. ]]
	remote._skickat = {}
	klocka += 1.0
	tryck(Input.BROMS, Enum.UserInputState.End)
	bildrutor(2)
	prova("ett släpp på BROMS ger ingen avsikt", #remote._skickat == 0)
	tryck(Input.BROMS, Enum.UserInputState.Begin)
	bildrutor(2)
	prova("men ett tryck ger `broms`", #remote._skickat == 1
		and remote._skickat[1][2] == Ridtrappa.BROMS,
		("(%s)"):format(tostring(remote._skickat[1] and remote._skickat[1][2])))
	klocka += 1.0
	tryck(Input.BROMS, Enum.UserInputState.End)
	bildrutor(2)
	prova("och släppet efteråt lägger inte till en andra", #remote._skickat == 1)

	Net.get("MountChanged").OnClientEvent:Fire(h, nil)
	bildrutor(1)
end

--[[ ══ 4. SEX UTGÅNGAR ═══════════════════════════════════════════════ ]]
print("\n── 4. Varje väg ur sadeln river handlingarna och lämnar inget kvar ──")

local annan = { Name = "Annan", UserId = 424242,
	CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }

local UTGANGAR = {
	{ namn = "MountChanged(häst, nil) — servern sätter av",
		ut = function(h) Net.get("MountChanged").OnClientEvent:Fire(h, nil) end },
	{ namn = "MountChanged(häst, annan ryttare)",
		ut = function(h) Net.get("MountChanged").OnClientEvent:Fire(h, annan) end },
	{ namn = "CharacterRemoving — respawn",
		ut = function() player.CharacterRemoving:Fire(player.Character) end },
	{ namn = "riggen lämnar workspace",
		ut = function(h) h.Parent = nil; bildrutor(1) end },
	{ namn = "SITT AV-handlingen (DismountRequest)",
		ut = function()
			avsittning._skickat = {}
			tryck(Input.AVSITT)
		end,
		efter = function()
			prova("   avsittningen gick till servern", #avsittning._skickat == 1,
				("(%d anrop)"):format(#avsittning._skickat))
		end },
}

for _, ug in ipairs(UTGANGAR) do
	print(("\n   · %s"):format(ug.namn))
	local h = nyHast()
	sittUpp(h)
	prova("   uppsutten med tre handlingar", bundna() == 3 and knappar() == 3)

	--[[ STRAX FÖRE utgången: spaken i utslag och en DRIV-flank obehandlad.
		Spaken skriver genom `Input.setTouch`, samma anrop TouchControls
		gör när fingret rör sig. ]]
	klocka += 10
	Input.setTouch(0.7, -0.4)
	Input.drivImpuls()
	remote._skickat = {}

	ug.ut(h)
	bildrutor(1)
	if ug.efter then ug.efter() end

	prova("   handlingarna är rivna", bundna() == 0, ("(%d kvar)"):format(bundna()))
	prova("   pekknapparna är borta", knappar() == 0, ("(%d kvar)"):format(knappar()))
	prova("   pekytan är borta", pekyta() == nil and not TouchControls.isActive())
	local i = Input.consume()
	prova("   nästa avsikt är neutral — inget spakutslag, ingen flank",
		i.forward == 0 and i.steer == 0 and i.gaitUp == false and i.gaitDown == false,
		("(forward %.2f · steer %.2f · upp %s)"):format(i.forward, i.steer, tostring(i.gaitUp)))
	prova("   ett tryck efteråt når inte CAS", tryck(Input.DRIV) == false)
	bildrutor(3)
	prova("   och den obehandlade flanken nådde aldrig tråden",
		#remote._skickat == 0, ("(%d paket)"):format(#remote._skickat))
end

--[[ ══ 5. HÄSTBYTE: RIVS OCH BINDS OM EXAKT EN GÅNG ═════════════════ ]]
print("\n── 5. Hästbyte mitt i ritten binder om en gång, inte två ──")
do
	local h1 = nyHast()
	sittUpp(h1)
	local fore = bindningar[Input.DRIV] or 0
	klocka += 10
	Input.setTouch(0.5, 0.5)
	Input.drivImpuls()
	remote._skickat = {}

	local h2 = nyHast()
	Net.get("MountChanged").OnClientEvent:Fire(h2, player)
	bildrutor(2)
	kvitteraKort()
	prova("efter bytet är handlingarna bundna", bundna() == 3, ("(%d)"):format(bundna()))
	prova("DRIV bands om EXAKT en gång", (bindningar[Input.DRIV] or 0) - fore == 1,
		("(+%d)"):format((bindningar[Input.DRIV] or 0) - fore))
	prova("en pekknapp per handling, inte två", knappar() == 3)
	local antalYtor = 0
	for _, b in ipairs(player._gui._barn or {}) do
		if b.Name == "HorseTouch" then antalYtor += 1 end
	end
	prova("exakt EN pekyta", antalYtor == 1, ("(%d)"):format(antalYtor))
	prova("den gamla rittens flank och spakutslag följde inte med",
		#remote._skickat == 0 and select(1, Input.consume()).forward == 0)

	--[[ Och den nya ritten svarar — med det NYA rittmärket. ]]
	tillstand.OnClientEvent:Fire({ hast = h2, ritt = h2:GetAttribute("RidSession"),
		gangart = "walk", ryggar = false, version = 99 })
	bildrutor(1)
	remote._skickat = {}
	Input.nollaImpulsSparr()
	klocka += 10
	tryck(Input.DRIV)
	bildrutor(2)
	prova("ett DRIV på den nya hästen bär det nya märket",
		#remote._skickat == 1 and remote._skickat[1][1] == h2:GetAttribute("RidSession"),
		("(%s)"):format(tostring(remote._skickat[1] and remote._skickat[1][1])))

	Net.get("MountChanged").OnClientEvent:Fire(h2, nil)
	bildrutor(1)
	prova("och avsittningen efter bytet lämnar noll handlingar", bundna() == 0)
end

--[[ == EN VARNING SOM ALLTID FYRAR AR INGEN VARNING ==================

	ROBLOX_RUNTIME_ROUTING, matt i Studio 2026-09-20: varje uppsittning
	skrev

		[Horse] Saknade animationer (18): Idle, ..., Graze

	i en build dar det ar AVSETT att inga klipp finns — `HastGang` driver
	benen procedurellt just for att hastens karnrorelse inte ska hanga pa
	en annan skapares assets, och `AnimationConfig` skapas darfor tom.

	Raden drunknade tva riktiga `led.`-varningar i samma logg. En varning
	som alltid fyrar gor fragan "varnar den har builden om nagot?"
	vardelos, och det ar den fragan runtime-QA staller.

	Provet mater BADA riktningarna. Att tystnaden finns sager lite; att
	varningen fortfarande FYRAR nar konfigurationen ar HALVFYLLD ar det
	som skiljer en rattelse fran ett borttaget larm. ]]
print("\n-- Animationsvarningen --")
do
	local function varningarMed(text)
		local n = 0
		for _, v in ipairs(__varningar) do
			if string.find(v, text, 1, true) then n += 1 end
		end
		return n
	end

	--[[ TOM KONFIGURATION — produktionens lage. ]]
	local h = nyHast()
	local fore = varningarMed("Saknade animationer")
	sittUpp(h)
	prova("en tom AnimationConfig ger INGEN varning",
		varningarMed("Saknade animationer") == fore,
		("(%d -> %d)"):format(fore, varningarMed("Saknade animationer")))
	Net.get("MountChanged").OnClientEvent:Fire(h, nil)
	bildrutor(1)

	--[[ HALVFYLLD KONFIGURATION — ett riktigt paketeringsfel. Tva id:n
		satta, resten tomma; animatorn svarar med ett spar sa att de tva
		faktiskt LADDAS och `laddade` blir storre an noll. ]]
	local h2 = nyHast()
	local cfg = Instance.new("Configuration")
	cfg.Name = "AnimationConfig"
	cfg.Parent = h2
	local satta = 0
	for _, nyckel in ipairs(Config.ANIMATION_KEYS) do
		if satta < 2 then
			cfg:SetAttribute(nyckel, "rbxassetid://1234567")
			satta += 1
		end
	end
	local animator = h2:FindFirstChild("Animator", true)
	function animator:LoadAnimation() return __makeTrack() end
	local fore2 = varningarMed("Saknade animationer")
	sittUpp(h2)
	local efter2 = varningarMed("Saknade animationer")
	prova("en HALVFYLLD AnimationConfig varnar fortfarande",
		efter2 > fore2, ("(%d -> %d)"):format(fore2, efter2))
	prova("och varningen sager hur manga av hur manga",
		varningarMed("av " .. tostring(#Config.ANIMATION_KEYS)) > 0,
		__varningar[#__varningar] or "-")
	Net.get("MountChanged").OnClientEvent:Fire(h2, nil)
	bildrutor(1)
end

UIS.TouchEnabled = foreTouch
cam.ViewportSize = foreVp

print("")
if fel > 0 then
	print(("%d mätningar föll."):format(fel))
	error(("%d fel"):format(fel))
else
	print("Alla mätningar gick igenom.")
end
