--!nostrict
--[[
	Batch 0.11 (E2) — AVSITTNING BARA FRÅN HALT, i den riktiga klienten.

	Man sitter av en häst som står. Provet kör den riktiga `init.client`
	och mäter spelarens egen väg — `Input.AVSITT` i `ContextActionService`
	och pekytans SITT AV — inte en genväg in i modulen:

	  1. REGELN (`Avsittning`, ren logik) och dess tal mot webbens kanon.
	  2. Vid halt sitter knappen av DIREKT, som förut.
	  3. I rörelse sitter knappen INTE av: stallet tar ner hästen med
	     ridtrappans egna BROMS-steg, Ugneta säger vad som händer, och
	     `DismountRequest` går till servern först när hon står.
	  4. Under väntan: ett andra tryck sitter inte av i förtid, ett DRIV
	     från spelaren tar henne inte upp igen, och stallets broms
	     besvarar inget lektionskort.
	  5. Ryggar hon tas hon UPP till halt (ett DRIV), inte längre ned.
	  6. Pekytans SITT AV går samma väg.
	  7. Nödutgången: en häst som inte kommer till halt lämnas ändå efter
	     `Config.AVSITTNING.Nodutgang` sekunder.
	  8. KONTROLLMÄTNING: den gamla vägen (`begarAvsittning` direkt) hade
	     skickat `DismountRequest` i samma bildruta, i full fart.

	Det här är stubbad Luau-evidens. Det är INTE verklig motor: bänken har
	ingen server som stämmer av gångarten, ingen fysik och ingen riktig
	knapp. Att nedtagningen KÄNNS rätt, och att servern godtar stegen i
	den takt klienten ger dem, är ett Studio-prov och står som NOT TESTED.

	Kör: python3 roblox/tests/build.py tests/klient-sittav-halt.spec.luau
	     && luau roblox/tests/.build/klient-sittav-halt.spec.luau ]]

local fel = 0
local function prova(vad, ok, detalj)
	if ok then
		print(("  OK   %s%s"):format(vad, if detalj then "  " .. detalj else ""))
	else
		fel += 1
		print(("  FEL  %s%s"):format(vad, if detalj then "  " .. detalj else ""))
	end
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CAS = game:GetService("ContextActionService")
local player = Players.LocalPlayer
local Net = Networking
local dt = 1 / 30

--[[ Spärren är en tidsregel: provet äger klockan och flyttar den med
     varje bildruta, så att ridtrappans takt blir den riktiga. ]]
local nu = 1000
Input._klocka = function() return nu end
local function bildrutor(n)
	for _ = 1, n do
		nu += dt
		RunService.RenderStepped:Fire(dt)
	end
end

local dr = Net.get("DismountRequest")
local originalHandlare = dr.OnServerInvoke
local avsikt = Net.get("RidingIntent")

--[[ HÄSTENS LÄGE, BILDRUTA FÖR BILDRUTA. `init.client` lämnar bildrutans
     `loco` till `Naromrade.ridlage` efter varje ridsteg; provet läser
     samma tabell. `StateSync` duger inte som mätare — den skickas glesare
     än en bildruta, och provet ska veta farten i just den ruta regeln
     läste. ]]
local senasteLoco = nil
do
	local orig = Naromrade.ridlage
	Naromrade.ridlage = function(loco, ...)
		senasteLoco = loco
		return orig(loco, ...)
	end
end
local function fart(): number
	return if senasteLoco then senasteLoco.speed else 0
end
--[[ Vad servern fick: varje `DismountRequest`, med hästens fart och
     gångart när ritten revs. ]]
local avsittningar = {}
local function lyssna()
	avsittningar = {}
	dr.OnServerInvoke = function()
		table.insert(avsittningar, { fart = fart(), gait = senasteLoco and senasteLoco.gait })
		return true
	end
end

--[[ Pekytans krok: `init.client` lämnar den till `TouchControls.mount`
     vid uppsittningen. Bänken har ingen pekskärm, så knappen byggs inte —
     men kroken är exakt den funktion knappen hade kört. ]]
local pekHooks = nil
do
	local orig = TouchControls.mount
	TouchControls.mount = function(input, hooks)
		pekHooks = hooks
		return orig(input, hooks)
	end
end

local hastNr = 0
local function nyHast(): Model
	hastNr += 1
	nu += Input.IMPULS_SPARR + 0.05
	local h = __makeHastModell("Sittavhast" .. hastNr)
	h:SetAttribute("RidSession", "ritt-sittav-" .. hastNr)
	h:SetAttribute("RiderUserId", player.UserId)
	h:SetAttribute("GaitCeiling", "canter")
	h.Parent = workspace
	return h
end
local function sittUpp(): Model
	local h = nyHast()
	Net.get("MountChanged").OnClientEvent:Fire(h, player)
	bildrutor(1)
	--[[ Ett väntande lektionskort kvitteras: provet mäter ridningen. ]]
	if LektionController.vantar() then LektionController.fortsatt() end
	UgnetaController.dolj()
	bildrutor(1)
	return h
end
local function tryckSittAv(): boolean
	local fn = CAS._bound[Input.AVSITT]
	if fn then fn(Input.AVSITT, Enum.UserInputState.Begin, {}) end
	return fn ~= nil
end
local function rider(): boolean
	return CAS._bound[Input.AVSITT] ~= nil
end
--[[ Rid upp `n` pinnar med spelarens egen DRIV, en per spärr, och låt
     farten etablera sig. ]]
local function ridUpp(n: number)
	for _ = 1, n do
		nu += Input.IMPULS_SPARR + 0.05
		Input.drivImpuls()
		bildrutor(20)
	end
	bildrutor(60)
end
local function stada(h: Model)
	dr.OnServerInvoke = originalHandlare
	if rider() then
		--[[ Provet lämnade en ritt uppe: riv den genom serverns ord. ]]
		Net.get("MountChanged").OnClientEvent:Fire(h, nil)
	end
	h:Destroy()
	bildrutor(1)
end
local function lararText(): string
	return tostring(UgnetaController._larare().text or "")
end
local function antal(lista, handling)
	local n = 0
	for _, p in ipairs(lista) do
		if p[2] == handling then n += 1 end
	end
	return n
end

print("\n══ 1. REGELN OCH DESS TAL ════════════════════════════════════")
do
	local K = Config.AVSITTNING
	prova("talen är webbens kanon (RidKanon.AVSITTNING)",
		K.Stilla == RidKanon.AVSITTNING.STILLA and K.Nodutgang == RidKanon.AVSITTNING.NODUTGANG_S,
		("Stilla %s/%s · Nodutgang %s/%s"):format(tostring(K.Stilla), tostring(RidKanon.AVSITTNING.STILLA),
			tostring(K.Nodutgang), tostring(RidKanon.AVSITTNING.NODUTGANG_S)))
	local a = Avsittning.ny()
	prova("står hon (halt, 0 m/s) sker avsittningen NU",
		Avsittning.begar(a, "halt", 0) == "nu" and a.vantar == false)
	prova("utan begäran gör steget ingenting", Avsittning.steg(Avsittning.ny(), "canter", 5, dt) == nil)
	local b = Avsittning.ny()
	prova("i galopp blir det en BEGÄRAN", Avsittning.begar(b, "canter", 5.5) == "vantar" and b.vantar == true)
	prova("ett andra tryck sitter inte av i förtid", Avsittning.begar(b, "canter", 5.5) == "vantar")
	prova("etiketten halt räcker inte medan hon rullar",
		Avsittning.begar(Avsittning.ny(), "halt", 0.40) == "vantar")
	prova("och en häst som RYGGAR står inte (halt, −0,6 m/s)",
		Avsittning.begar(Avsittning.ny(), "halt", -0.6) == "vantar")
	--[[ Nödutgången, lika vid 30, 60 och 120 bilder i sekunden. ]]
	local tider = {}
	for _, fps in ipairs({ 30, 60, 120 }) do
		local c = Avsittning.ny()
		Avsittning.begar(c, "canter", 5.5)
		local t, ut = 0, nil
		while t < 20 and not ut do
			t += 1 / fps
			if Avsittning.steg(c, "canter", 5.5, 1 / fps) == "sitt_av" then ut = t end
		end
		table.insert(tider, ut or math.huge)
	end
	local okTid = true
	for _, t in ipairs(tider) do
		if math.abs(t - K.Nodutgang) > 1 / 30 + 1e-9 then okTid = false end
	end
	prova("nödutgången löser ut efter Nodutgang sekunder vid 30/60/120 bilder/s", okTid,
		("%.3f · %.3f · %.3f s"):format(tider[1], tider[2], tider[3]))
	--[[ Ett andra tryck startar inte om klockan. ]]
	local d = Avsittning.ny()
	Avsittning.begar(d, "trot", 3)
	local t, ut = 0, nil
	while t < 20 and not ut do
		t += dt
		if math.abs(t - 3) < dt / 2 then Avsittning.begar(d, "trot", 3) end
		if Avsittning.steg(d, "trot", 3, dt) == "sitt_av" then ut = t end
	end
	prova("ett andra tryck startar INTE om klockan",
		ut ~= nil and math.abs(ut - K.Nodutgang) <= 1 / 30 + 1e-9, tostring(ut))
end

print("\n══ 2. VID HALT: DIREKT, SOM FÖRUT ════════════════════════════")
do
	local h = sittUpp()
	lyssna()
	prova("KONTROLL: hon rider och hästen står", rider() and fart() <= Config.AVSITTNING.Stilla,
		("fart %.2f"):format(fart()))
	__schemaPa(true)
	tryckSittAv()
	__schemaTomKo()
	__schemaPa(false)
	prova("SITT AV vid halt river ritten i samma tryck", rider() == false)
	prova("och servern får EN DismountRequest", #avsittningar == 1, tostring(#avsittningar))
	stada(h)
end

print("\n══ 3. I RÖRELSE: FÖRST HALT, SEDAN AVSITTNING ════════════════")
local nedtagning = nil
do
	local h = sittUpp()
	lyssna()
	ridUpp(3)
	local fartFore = fart()
	prova("KONTROLL: hon rör sig (galopp)", fartFore > 3, ("%.2f m/s"):format(fartFore))
	avsikt._skickat = {}
	__schemaPa(true)
	tryckSittAv()
	bildrutor(1)
	prova("SITT AV i rörelse river INTE ritten", rider() == true)
	prova("och ingen DismountRequest har gått", #avsittningar == 0, tostring(#avsittningar))
	prova("Ugneta säger vad som händer", lararText() == Sprak.t("avsittning.bromsar"),
		("«%s»"):format(lararText()))
	--[[ Följ nedtagningen bildruta för bildruta. ]]
	local rutor, storstaOkning, forra = 0, 0, fart()
	while rider() and rutor < 30 * 12 do
		bildrutor(1)
		rutor += 1
		if rider() then
			storstaOkning = math.max(storstaOkning, fart() - forra)
			forra = fart()
		end
	end
	__schemaTomKo()
	__schemaPa(false)
	nedtagning = rutor * dt
	prova("avsittningen KOM", rider() == false, ("efter %.2f s"):format(nedtagning))
	prova("servern fick EN DismountRequest", #avsittningar == 1, tostring(#avsittningar))
	prova("och hon STOD då", #avsittningar == 1 and avsittningar[1].fart <= Config.AVSITTNING.Stilla,
		("%.3f m/s"):format(avsittningar[1] and avsittningar[1].fart or -1))
	prova("inom nödutgångens tid — den ska inte vara det normala",
		nedtagning < Config.AVSITTNING.Nodutgang - 0.25,
		("%.2f s av %s"):format(nedtagning, tostring(Config.AVSITTNING.Nodutgang)))
	prova("farten ökade aldrig under nedtagningen", storstaOkning <= 0.02,
		("största ökning %.3f m/s per bildruta"):format(storstaOkning))
	prova("nedtagningen gick som BROMS-steg på tråden, ett per pinne",
		antal(avsikt._skickat, Ridtrappa.BROMS) == 3 and antal(avsikt._skickat, Ridtrappa.DRIV) == 0,
		("%d broms · %d driv"):format(antal(avsikt._skickat, Ridtrappa.BROMS), antal(avsikt._skickat, Ridtrappa.DRIV)))
	prova("raden försvinner med ritten", lararText() ~= Sprak.t("avsittning.bromsar"),
		("«%s»"):format(lararText()))
	stada(h)
end

print("\n══ 4. UNDER VÄNTAN ═══════════════════════════════════════════")
do
	local h = sittUpp()
	lyssna()
	ridUpp(3)
	avsikt._skickat = {}
	__schemaPa(true)
	tryckSittAv()
	bildrutor(3)
	tryckSittAv()
	bildrutor(1)
	prova("ett andra tryck sitter inte av i förtid", rider() == true and #avsittningar == 0)
	--[[ Spelaren försöker rida vidare: DRIV, flera gånger, förbi spärren. ]]
	for _ = 1, 3 do
		nu += Input.IMPULS_SPARR + 0.05
		Input.drivImpuls()
		bildrutor(4)
	end
	prova("ett DRIV från spelaren tar henne inte upp igen",
		antal(avsikt._skickat, Ridtrappa.DRIV) == 0,
		("%d driv på tråden"):format(antal(avsikt._skickat, Ridtrappa.DRIV)))
	--[[ Ett lektionskort som väntar besvaras inte av stallets broms. ]]
	local kvitterat = 0
	local foreVantar, foreFortsatt = LektionController.vantar, LektionController.fortsatt
	LektionController.vantar = function() return true end
	LektionController.fortsatt = function() kvitterat += 1; return true end
	local rutor = 0
	while rider() and rutor < 30 * 12 do bildrutor(1); rutor += 1 end
	LektionController.vantar, LektionController.fortsatt = foreVantar, foreFortsatt
	__schemaTomKo()
	__schemaPa(false)
	prova("stallets broms besvarar inget lektionskort", kvitterat == 0, tostring(kvitterat))
	prova("och hon togs ner och sattes av ändå",
		rider() == false and #avsittningar == 1 and avsittningar[1].fart <= Config.AVSITTNING.Stilla,
		("%d avsittningar, %.3f m/s"):format(#avsittningar, avsittningar[1] and avsittningar[1].fart or -1))
	stada(h)
end

print("\n══ 5. RYGGAR HON TAS HON UPP TILL HALT ═══════════════════════")
do
	local h = sittUpp()
	lyssna()
	--[[ Ett BROMS i halt är trappans väg ned i ryggning. ]]
	nu += Input.IMPULS_SPARR + 0.05
	Input.bromsImpuls()
	bildrutor(45)
	local ryggfart = fart()
	prova("KONTROLL: hon ryggar", ryggfart < -Config.AVSITTNING.Stilla, ("%.2f m/s"):format(ryggfart))
	avsikt._skickat = {}
	__schemaPa(true)
	tryckSittAv()
	bildrutor(1)
	prova("SITT AV under ryggning river inte ritten", rider() == true and #avsittningar == 0)
	local rutor = 0
	while rider() and rutor < 30 * 12 do bildrutor(1); rutor += 1 end
	__schemaTomKo()
	__schemaPa(false)
	prova("stallet gav ETT DRIV (upp till halt) och inget BROMS",
		antal(avsikt._skickat, Ridtrappa.DRIV) == 1 and antal(avsikt._skickat, Ridtrappa.BROMS) == 0,
		("%d driv · %d broms"):format(antal(avsikt._skickat, Ridtrappa.DRIV), antal(avsikt._skickat, Ridtrappa.BROMS)))
	prova("och hon sattes av stående",
		rider() == false and #avsittningar == 1 and math.abs(avsittningar[1].fart) <= Config.AVSITTNING.Stilla,
		("%.3f m/s efter %.2f s"):format(avsittningar[1] and avsittningar[1].fart or -9, rutor * dt))
	stada(h)
end

print("\n══ 6. PEKYTANS SITT AV GÅR SAMMA VÄG ═════════════════════════")
do
	local h = sittUpp()
	lyssna()
	ridUpp(2)
	local fn = pekHooks and pekHooks.dismount
	prova("KONTROLL: pekytan fick en avsittningshandling vid uppsittningen", type(fn) == "function")
	__schemaPa(true)
	if fn then fn() end
	bildrutor(1)
	prova("pekknappen i rörelse river inte ritten", fn ~= nil and rider() == true and #avsittningar == 0,
		("fart %.2f m/s"):format(fart()))
	local rutor = 0
	while rider() and rutor < 30 * 12 do bildrutor(1); rutor += 1 end
	__schemaTomKo()
	__schemaPa(false)
	prova("och sitter av när hon står",
		rider() == false and #avsittningar == 1 and avsittningar[1].fart <= Config.AVSITTNING.Stilla,
		("%.3f m/s"):format(avsittningar[1] and avsittningar[1].fart or -1))
	stada(h)
end

print("\n══ 7. NÖDUTGÅNGEN ════════════════════════════════════════════")
do
	local h = sittUpp()
	lyssna()
	ridUpp(3)
	--[[ En häst som inte låter sig tas ner: spärren släpper aldrig igenom
	     en impuls, så trappan står kvar i galopp. ]]
	local foreBroms = Input.bromsImpuls
	Input.bromsImpuls = function() return false end
	__schemaPa(true)
	tryckSittAv()
	local rutor = 0
	while rider() and rutor < 30 * 12 do bildrutor(1); rutor += 1 end
	__schemaTomKo()
	__schemaPa(false)
	Input.bromsImpuls = foreBroms
	local tid = rutor * dt
	prova("spelaren blir inte fast i sadeln", rider() == false and #avsittningar == 1,
		("%d avsittningar"):format(#avsittningar))
	prova("avsittningen kom vid nödutgångens tid, inte före",
		math.abs(tid - Config.AVSITTNING.Nodutgang) <= 2 * dt,
		("%.2f s av %s"):format(tid, tostring(Config.AVSITTNING.Nodutgang)))
	prova("KONTROLL: hon rörde sig fortfarande — det var nödutgången, inte halten",
		#avsittningar == 1 and avsittningar[1].fart > 1, ("%.2f m/s"):format(avsittningar[1] and avsittningar[1].fart or -1))
	stada(h)
end

print("\n══ 8. KONTROLLMÄTNING: DEN GAMLA REGELN ══════════════════════")
do
	--[[ Före Batch 0.11 var varje tryck en avsittning. Sätts regeln
	     tillbaka till det ska provet SE det: en `DismountRequest` i full
	     fart. Annars hade punkt 3 varit grön oavsett vad klienten gör. ]]
	local h = sittUpp()
	lyssna()
	ridUpp(3)
	local foreBegar = Avsittning.begar
	Avsittning.begar = function() return "nu" end
	__schemaPa(true)
	tryckSittAv()
	__schemaTomKo()
	__schemaPa(false)
	Avsittning.begar = foreBegar
	prova("med den gamla regeln river SITT AV ritten i galopp — provet ser skillnaden",
		rider() == false and #avsittningar == 1 and avsittningar[1].fart > 3,
		("%.2f m/s"):format(avsittningar[1] and avsittningar[1].fart or -1))
	stada(h)
end

print("")
if nedtagning then print(("  uppmätt nedtagning galopp → halt i bänken: %.2f s"):format(nedtagning)) end
if fel > 0 then
	print(("SITTAV-HALT: %d FEL"):format(fel))
	error("sittav-halt foll")
end
--[[ SLUTRADEN AR ETT KONTRAKT mot `kor.sh`: den letar efter
     "alla gröna" och tolkar franvaron som en KRASCH. ]]
print("SITTAV-HALT: alla gröna")
