--!nostrict
--[[ SKÖTSEL-HUD:EN OCH RIDNINGENS PEKRESERV DELAR ALDRIG SKÄRM (#221)

	Ridningens pekreglage (`TouchControls`: spaken nere till vänster,
	gångarterna och hjälparna i högerkanten) reserverar sina ytor bara
	medan man rider. Skötsel-HUD:en (`PreparationController`: spåraren
	uppe till höger, interaktionspanelen nedtill) ritas medan man sköter
	hästen. På en iPad ryms båda; på en telefon i landskap gör de det
	inte: spårarens hörn ligger rakt över gångartsgallret. Mätt här, på
	iPhone 13 i landskap: spåraren x 513..737 · y 102..162 mot HALT/SKRITT/
	TRAV/GALOPP x 565..729 · y 45..191.

	Det som skyddar reglagen är inte en flytt utan en UTESLUTNING:
	`avsluta` i PreparationController släcker hela skötsel-GUI:t
	(`gui.Enabled = false`) så snart serverns vy säger `riding`, och
	`init.client` river `HorseTouch` i `dismount` innan någon ny vy kan
	rita HUD:en igen. Ingen grind mätte den uteslutningen. Det gör den här,
	genom produktionens egen väg — `MountChanged` in, `MountChanged` ut,
	vyn genom `PreparationSync`-vägen — och på flera telefonstorlekar.

	SKÄRMARNA är inte valda utan tagna ur repots egna källor:
	  749×367  iPhone 13 i landskap, avläst ur levande klient (#185,
	           forberedelse.spec)
	  844×390  "telefon 390×844" (klient.spec, varldshud.spec) i landskap
	  568×320  "liten telefon 320×568" (klient.spec) i landskap
	  1024×768 iPad i landskap — kontrollen där allt ryms

	VAD SOM INTE MÄTS HÄR: interaktionspanelen mot Roblox EGNA pekreglage
	(gå-spaken under skötseln) mäts i forberedelse.spec på de rutor som
	lästs av på riktiga enheter; här finns bara rutor för iPhone 13, så de
	andra två storlekarna är [REFERENCE GAP] för just den mätningen.
	Gångartsknapparnas egen höjd på små telefoner är #208:s skala och
	ligger utanför #221 — den skrivs ut, inte krävs. Hur det känns på en
	fysisk telefon är #206:s mänskliga grind.

	Kör: python3 roblox/tests/build.py tests/klient-reservzon.spec.luau
	     && luau roblox/tests/.build/klient-reservzon.spec.luau ]]

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
local PC = PreparationController

local function inset()
	local topp = GuiService:GetGuiInset()
	return topp.Y
end
local function barn(inst, namn)
	for _, b in ipairs(inst and inst._barn or {}) do
		if b.Name == namn then return b end
	end
	return nil
end
--[[ En rams ruta i SKÄRMENS pixlar. `Hg` är ytan ramen räknar i (hela
	viewporten om dess ScreenGui ignorerar topbaren, annars minus inset)
	och `dy` flyttar tillbaka till skärmen. Bänken har ingen layoutmotor,
	så rutan räknas ur UDim2 på samma sätt som Roblox gör. ]]
local function rekt(f, W, Hg, dy)
	local p, s = f.Position, f.Size
	local x = W * p.X.Scale + p.X.Offset
	local y = Hg * p.Y.Scale + p.Y.Offset + dy
	return { x0 = x, y0 = y, x1 = x + W * s.X.Scale + s.X.Offset,
		y1 = y + Hg * s.Y.Scale + s.Y.Offset }
end
local function skar(a, b)
	return a.x0 < b.x1 and b.x0 < a.x1 and a.y0 < b.y1 and b.y0 < a.y1
end
local function r2s(r)
	return ("x %d..%d y %d..%d"):format(r.x0, r.x1, r.y0, r.y1)
end
--[[ På skärmen = ytan påslagen och ramen synlig, hela vägen upp. Samma
	regel produktionen använder om Roblox egna reglage (`paSkarmen`). ]]
local function paSkarmen(f, yta)
	if f == nil or f.Visible == false then return false end
	if yta.Enabled == false then return false end
	return true
end

--[[ RESERVZONEN: de tre ytor spelaren måste kunna nå medan hon rider.
	Blickytan är med flit INTE med — den ligger underst i sin ScreenGui
	och tar bara det finger ingen knapp tog. ]]
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
	local Hg = H - inset()
	local ut = {}
	for _, namn in ipairs(RESERV) do
		local f = barn(ht, namn)
		if f then ut[namn] = rekt(f, W, Hg, inset()) end
	end
	ut.Handlingar = handlingsrekt(W, H)
	return ut, ht
end
--[[ Skötsel-HUD:ens ytor PÅ SKÄRMEN, i skärmens pixlar. ]]
local function hudPaSkarmen(W, H)
	local g = barn(player._gui, "UBRFForberedelse")
	local ut = {}
	if not g then return ut, nil end
	for _, f in ipairs(g._barn or {}) do
		if f.Position and f.Size and paSkarmen(f, g) then
			ut[f.Name] = rekt(f, W, H, 0)
		end
	end
	return ut, g
end
local function krockar(hud, res)
	local lista = {}
	for hn, hr in pairs(hud) do
		for rn, rr in pairs(res or {}) do
			if skar(hr, rr) then table.insert(lista, hn .. "×" .. rn) end
		end
	end
	table.sort(lista)
	return lista
end

--[[ SERVERNS VY, byggd ur samma modul servern använder. En komplett
	förberedelse: alla faser gjorda, hästen redo. ]]
local rev = 0
local function gorFas(state, fasId, hastId)
	local ok, skal = Preparation.provaSteg(state, fasId, hastId)
	if not ok then return false, skal end
	while true do
		local m = Preparation.nastaMoment(state, fasId)
		if not m then break end
		local mok, mskal = Preparation.utforMoment(state, fasId, m.id, hastId)
		if not mok then return false, mskal end
	end
	return true, nil
end
local function visa(st, status)
	rev += 1
	PC.tillampa(Preparation.vy(st, status, rev, "Cosmo"))
	PC.uppdateraKontext()
	PC.tillampaLayout()
end
local st = Preparation.nyState("cosmo", 1)
for _, f in ipairs(Preparation.FASER) do
	if f.id ~= "sittupp" then
		local ok, skal = gorFas(st, f.id, "cosmo")
		prova("förberedelsen: fasen " .. f.id .. " går att göra klar", ok, tostring(skal))
	end
end
prova("förberedelsen är komplett — hästen är redo", Preparation.redo(st))

local dt = 1 / 30
local function bildrutor(n)
	for _ = 1, n do RunService.RenderStepped:Fire(dt) end
end

--[[ Räknar hur många av skärmarna där mutationen nedan FAKTISKT slog.
     Se noten vid ankaret: krocken är en funktion av skärmstorleken, så
     kravet ställs på hela tabellen och inte på varje rad. ]]
local mutationSlog = 0

local SKARMAR = {
	{ namn = "iPhone 13 landskap", W = 749, H = 367, telefon = true,
		kalla = "#185, avläst ur levande klient" },
	{ namn = "telefon 844×390 landskap", W = 844, H = 390, telefon = true,
		kalla = "klient.spec/varldshud.spec 'telefon 390×844'" },
	{ namn = "liten telefon 568×320 landskap", W = 568, H = 320, telefon = true,
		kalla = "klient.spec 'liten telefon 320×568'" },
	{ namn = "iPad landskap 1024×768", W = 1024, H = 768, telefon = false,
		kalla = "forberedelse.spec/klient.spec" },
	--[[ #206: de två iPad-ytorna där lektionskortet mättes ligga över
		spaken respektive inte göra det. Båda avlästa ur Studios egna
		enhetsprofiler i emulering. ]]
	{ namn = "iPad 9 landskap 1080×810", W = 1080, H = 810, telefon = false,
		kalla = "#206, Studio-emulering ipad_9th_generation" },
	{ namn = "iPad Air landskap 1180×820", W = 1180, H = 820, telefon = false,
		kalla = "#206, Studio-emulering ipad_air_5th_generation" },
}

local foreTouch, foreVp = UIS.TouchEnabled, cam.ViewportSize
UIS.TouchEnabled = true

for _, sk in ipairs(SKARMAR) do
	local W, H = sk.W, sk.H
	print(("\n── %s (%d×%d, topbar %d px) · källa: %s ──"):format(
		sk.namn, W, H, inset(), sk.kalla))
	cam.ViewportSize = { _typ = "Vector2", X = W, Y = H }

	--[[ 1. FÖRE UPPSITTNINGEN: skötseln syns, reglagen finns inte. ]]
	visa(st, Preparation.STATUS.REDO)
	local hud, g = hudPaSkarmen(W, H)
	--[[ #264 PLAYER_INTERACTION_CONSOLIDATION: skötselns innehåll står i
	     den enhetliga panelen; skötselns egen yta är släckt med avsikt, så
	     att det inte finns två. «Påslagen» betyder numera att PANELEN bär
	     skötselns rubrik. ]]
	local pnl = Naromrade._panel()
	prova("före uppsittningen är skötsel-HUD:en påslagen",
		pnl.synlig and PC._rubrik() ~= ""
			and string.find(pnl.rubrik, PC._rubrik(), 1, true) ~= nil,
		("panel=%s rubrik=%q"):format(tostring(pnl.synlig), pnl.rubrik))
	prova("och skötselns egen yta är släckt — en yta, inte två",
		g == nil or g.Enabled == false)
	local _ = hud
	prova("ridningens pekreglage finns inte förrän man rider",
		reserv(W, H) == nil and not TouchControls.isActive())

	--[[ 2. UPPSITTNINGEN genom produktionens egen väg. En färsk häst per
		skärm: en rigg överlever inte avsittningen i bänken. ]]
	local hast = __makeHastModell("Bamse" .. W)
	hast.Parent = workspace
	Net.get("MountChanged").OnClientEvent:Fire(hast, player)
	bildrutor(3)
	local res, ht = reserv(W, H)
	prova("uppsittningen monterade pekreglagen", res ~= nil and TouchControls.isActive())
	if res then
		local inne = true
		for namn, r in pairs(res) do
			if r.x0 < 0 or r.y0 < inset() or r.x1 > W or r.y1 > H then inne = false end
			print(("       %-9s %s"):format(namn, r2s(r)))
		end
		prova("reservzonens tre ytor ligger helt på skärmen, under topbaren", inne)
		--[[ Handlingsknapparna ritas av `ContextActionService` och har
			ingen instans i vår hierarki att mäta. Reservens ruta är det
			enda vi äger, och den skrivs ut ovanför. ]]
	end

	--[[ ══ LEKTIONSKORTET OCH SPAKEN (#206) ═══════════════════════════

		Reserven har varit ensidig. `TouchControls.reglageBredd()` höll
		kortet borta från gångarterna och hjälparna i högerkanten; ingenting
		höll det borta från spaken i vänsterkanten. Och eftersom
		`laggUtKort` skjuter kortet åt VÄNSTER när mitten inte räcker till,
		sköt den det rakt ut över spaken.

		Mätt i Studio på `cdfe061`, emulerad iPad i landskap, kortet uppe
		och ryttaren uppsutten — träffprov över spakens bas, 70 punkter:

		    1024×768  kort x  76..716  överlapp 80 px  spaken nådde 20/70
		    1080×810  kort x 105..745  överlapp 51 px  spaken nådde 34/70
		    1180×820  kort x 269..909  överlapp  0 px  spaken nådde 54/70

		De tappade punkterna svarade `Kort`, `Rubrik`, `Punkt1`, `Punkt2`
		och `Knapp` — kortet ligger i en ScreenGui med högre `DisplayOrder`
		(10 mot 8) och vinner därför fingret. Ett tumnedslag i spakens
		högra halva startade alltså ingen styrning alls.

		PÅ TELEFON är det inte ett fel som rättas här utan den redan
		dokumenterade 568×320-konflikten: där ryms inte både ett läsbart
		kort och en fri spak. Regeln avstår därför från vänsterreserven när
		kortet skulle bli smalare än `KORT_LASBAR`, och telefonen får exakt
		den layout den hade. Provet mäter det som två skilda krav. ]]
	local ug = barn(player._gui, "UBRFUgneta")
	local kortRam = ug and barn(ug, "Kort")
	if res and ug and kortRam then
		--[[ `UBRFUgneta` ignorerar topbaren, så dess ruta räknas mot hela
			viewporten. Kortet är dessutom ankrat (0.5, 1): `Position.X` är
			MITTEN, inte vänsterkanten. Bänken har ingen layoutmotor, så
			ankaret räknas här — som Roblox gör det. ]]
		ug.AbsoluteSize = { _typ = "Vector2", X = W, Y = H }
		UgnetaController.visa("Prov", { "rad" }, true, "Igen", false, false)
		UgnetaController._laggUtKort()
		local mitt = kortRam.Position.X.Offset
		local bredd = kortRam.Size.X.Offset
		local kr = { x0 = mitt - bredd / 2, x1 = mitt + bredd / 2,
			y0 = H - 14 - kortRam.Size.Y.Offset, y1 = H - 14 }
		local sp = res.Spak
		local krock = skar(kr, sp)
		print(("       kort %s · spak %s"):format(r2s(kr), r2s(sp)))

		if sk.telefon then
			--[[ OBSERVATION, inte krav: telefonens trångmål är
				568×320-konflikten och löses inte i #206. Raden finns för
				att en framtida ändring ska SYNAS i loggen. ]]
			print(("       observation: kortet %s spaken på telefon")
				:format(if krock then "TÄCKER" else "lämnar"))
		else
			prova("surfplatta: lektionskortet lämnar spaken fri", krock == false,
				("kort %s · spak %s"):format(r2s(kr), r2s(sp)))
			prova("och kortet är fortfarande läsbart brett", bredd >= 480,
				("%d px"):format(bredd))
			prova("och det håller sig innanför handlingsreserven",
				res.Handlingar ~= nil and kr.x1 <= res.Handlingar.x0,
				("kortets högerkant %d mot reservens %d"):format(kr.x1,
					res.Handlingar and res.Handlingar.x0 or -1))
		end
		UgnetaController.dolj()
	end

	--[[ ANKARET: skulle skötselspåraren ritas på sin vanliga plats medan
		man rider hade den legat över reglagen. Räknat ur layouten (rena
		tal, oavsett om GUI:t är påslaget). Utan den här raden hade
		uteslutningen nedan kunnat vara grön utan att skydda något.

		Mäts mot `Handlingar`, alltså mot det reservkontrakt resten av
		klienten läser — se noten vid `handlingsrekt`. Telefon och iPad
		har inte längre olika svar: blocket är lika högt i förhållande till
		skärmen på båda, och spåraren ligger i vägen på båda. ]]
	--[[ ══ ANKARET FLYTTADE, OCH DET SKA STÅ HÄR VARFÖR ════════════════

		Raden krävde förut att spåraren KROCKAR med gångartsgallret på
		telefon. Gallret gick nästan upp till topbaren; spåraren ligger på
		y 102..162, och de möttes.

		Efter 2026-09-17 ligger handlingsblocket i skärmens nedre hörn och
		är 2×2 knappar högt. På den smalaste skärmen når det fortfarande
		upp i spåraren, på de bredare inte — alltså är krocken en funktion
		av skärmen och inte ett kontrakt. Att kräva den överallt hade varit
		att kräva en trång layout.

		Ankarets UPPGIFT — att visa att uteslutningen nedan skyddar något —
		bärs i stället av MUTATIONEN strax under, som nu körs på VARJE
		skärm i tabellen i stället för bara på telefonerna. Den tänder
		skötsel-GUI:t mitt i ritten och kräver att mätningen blir röd.
		Det är ett starkare ankare, för det mäter regeln i stället för en
		geometrisk tillfällighet. ]]
	local L = PC.layout()
	local ankare = res and res.Handlingar and skar(L.kompakt, res.Handlingar)
	print(("       observation: spåraren %s handlingsblocket  %s · %s"):format(
		if ankare then "SKÄR" else "ligger fri från",
		r2s(L.kompakt), res and res.Handlingar and r2s(res.Handlingar) or "-"))

	--[[ 3. RITTEN: serverns vy säger `riding`. ]]
	visa(st, Preparation.STATUS.RIDER)
	local hud2, g2 = hudPaSkarmen(W, H)
	prova("medan man rider är hela skötsel-HUD:en släckt",
		g2 ~= nil and g2.Enabled == false, ("Enabled = %s"):format(tostring(g2 and g2.Enabled)))
	local ytor = PC._ytor()
	prova("och interaktionspanelen är inte synlig",
		ytor.interaktion ~= nil and ytor.interaktion.Visible == false)
	local k = krockar(hud2, res)
	prova("ingen skötselyta på skärmen ligger över reservzonen",
		#k == 0, if #k > 0 then table.concat(k, ", ") else "(inget på skärmen)")

	--[[ MUTATION I BÄNKEN: tänds GUI:t medan man rider ska mätningen
		bli röd — annars mäter raden ovan ingenting. Släcks igen.

		TVÅ GRINDAR SEDAN PO-ORDERN 2026-09-20, och mutationen måste
		besegra BÅDA. Ytan släcks fortfarande på `ScreenGui`-nivå av
		`avsluta`, och spåraren är dessutom osynlig utanför skötselns
		kontext (`layout().spararSyns`). Bara `Enabled = true` gav därför
		en tom skärm, mutationen slog på noll av sex skärmar och ankaret
		blev blint — ett prov som slutade mäta för att koden blev
		säkrare. Den mutationen är alltså inte "tänd ytan" längre utan
		"riv hela regeln om att kortet hör till skötseln". ]]
	if g2 then
		g2.Enabled = true
		local spa = ytor.sparare
		local spaFore = spa and spa.Visible
		if spa then spa.Visible = true end
		local km = krockar(hudPaSkarmen(W, H), res)
		if spa then spa.Visible = spaFore end
		g2.Enabled = false
		--[[ Räknas i stället för att krävas per skärm. På en iPad ryms
			både skötselytorna och reglagen utan att mötas, och då slår
			mutationen inte — det är rätt, och det är inte ett provfel.
			Kravet ställs på hela tabellen efter loopen. ]]
		if #km > 0 then mutationSlog += 1 end
		print(("       mutation: tänt GUI %s reservzonen  %s"):format(
			if #km > 0 then "SKÄR" else "lämnar", table.concat(km, ", ")))
	end

	--[[ ROTATION mitt i ritten: en ny layout får inte tända HUD:en. ]]
	cam.ViewportSize = { _typ = "Vector2", X = H, Y = W }
	PC.tillampaLayout()
	local g3 = select(2, hudPaSkarmen(H, W))
	prova("en vridning mitt i ritten tänder inte skötsel-HUD:en",
		g3 ~= nil and g3.Enabled == false)
	cam.ViewportSize = { _typ = "Vector2", X = W, Y = H }
	PC.tillampaLayout()

	--[[ 4. AVSITTNINGEN: reglagen ska vara borta INNAN någon ny vy kan
		tända HUD:en igen — annars finns en bildruta där båda syns. ]]
	Net.get("MountChanged").OnClientEvent:Fire(hast, nil)
	prova("avsittningen river pekreglagen direkt, före nästa vy",
		reserv(W, H) == nil and not TouchControls.isActive())
	local g4 = select(2, hudPaSkarmen(W, H))
	prova("HUD:en är fortfarande släckt tills servern säger något annat",
		g4 ~= nil and g4.Enabled == false)
	visa(st, Preparation.STATUS.REDO)
	local _, g5 = hudPaSkarmen(W, H)
	local pnl5 = Naromrade._panel()
	prova("serverns nästa vy tänder skötseln igen — utan reglage på skärmen",
		pnl5.synlig and string.find(pnl5.rubrik, PC._rubrik(), 1, true) ~= nil
			and (g5 == nil or g5.Enabled == false) and reserv(W, H) == nil,
		("panel=%s rubrik=%q"):format(tostring(pnl5.synlig), pnl5.rubrik))

	--[[ OBSERVATION, inte krav (#221 gäller skötselpanelen): `?`-knappen i
		KontrollHjalp bor också uppe till höger, 48 px med 12 px marginal,
		i en ScreenGui som respekterar topbaren. ]]
	if res and res.Handlingar then
		local hj = { x0 = W - 12 - 48, x1 = W - 12, y0 = inset() + 12, y1 = inset() + 60 }
		print(("       observation: ?-knappen %s %s handlingsblocket"):format(
			r2s(hj), if skar(hj, res.Handlingar) then "SKÄR" else "ligger fri från"))
	end
end

--[[ ══ ANKARET FÖR HELA TABELLEN ══════════════════════════════════════

     Raden "ingen skötselyta på skärmen ligger över reservzonen" är grön
     därför att skötsel-GUI:t är SLÄCKT under ritten. Utan ett ankare vore
     den grön också om reservzonen låg i ett tomt hörn.

     Ankaret är mutationen: tänds GUI:t mitt i ritten ska mätningen falla.
     Den slår inte på varje skärm — en iPad har plats för båda — men den
     måste slå på MINST EN, annars mäter uteslutningen ingenting alls. ]]
print("")
prova("ANKARE: mutationen slog på minst en skärm i tabellen",
	mutationSlog > 0, ("(%d av %d skärmar)"):format(mutationSlog, #SKARMAR))

UIS.TouchEnabled = foreTouch
cam.ViewportSize = foreVp
PC.tillampaLayout()

if fel > 0 then
	print(("\n%d mätningar föll."):format(fel))
else
	print("\nAlla mätningar gick igenom.")
end
