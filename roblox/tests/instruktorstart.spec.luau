--!nostrict
--[[ UGNETAS STARTHÄLSNING — docs/INSTRUCTOR-START-CONTRACT.md.

	KOHERENS-bänken med haltlektion-specens uppställning:
	- riktig HorseService och riktigt ridhus;
	- klientens riktiga VoltLektionController, med tryck på panelens egna
	  knappar;
	- fjärranropet `VoltLektion` går genom bänkens InvokeServer till serverns
	  Skopa-grind;
	- texten läses ur den SAMMANSATTA värden `UgnetaController.panel(4)`.

	SKRIVEN FÖR SENARE KÖRNING (bygg nu, testa sist). Inte körd.
	BÄNKANTAGANDEN:
	- utan schema kör `task.spawn` direkt, så svaret kommer inom trycket
	  (SYNKRONA fall);
	- med `__schemaPa(true)` köas det, och `task.wait` i en schemalagd tråd
	  lämnar över (VERKLIGT FÖRDRÖJDA fall: bara avsnitt 9);
	- avsnitt 7 använder PÅHITTADE producentformade svar för typerna, inte
	  riktiga serverstarter;
	- säkerhet, skötsel och utrustning i värden och fysisk rendering provas
	  INTE här;
	- Skopas klocka hoppas fram (`_satKlockaForProv`), så att takten aldrig
	  nekar i bänken;
	- `FireClient` levererar till klientens lyssnare direkt. ]]
local fails, total = 0, 0
local function check(name, yes, detalj)
	total += 1
	if not yes then fails += 1 end
	print((if yes then "  OK   " else "  FEL  ") .. name .. (if detalj then "  " .. tostring(detalj) else ""))
end
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local Tags = game:GetService("CollectionService")
local vec = Vector3.new
local RP = assert(Ridhusplats.los(workspace:FindFirstChild("Anläggning"):FindFirstChild("UBRF")))
Tags:nollstall(); Run._server = true; Run.Heartbeat:nollstall()
local klocka = 0
Skopa._satKlockaForProv(function() klocka += 100; return klocka end)
HorseService.setMountGate(nil); HorseService.start()
local G = HaltLektion.GRANSER
local p = Players.LocalPlayer
do
	local c = Instance.new("Model")
	local root = Instance.new("Part"); root.Name = "HumanoidRootPart"; root.Size = vec(2, 2, 1); root.Parent = c
	local h = Instance.new("Humanoid"); h.Name = "Humanoid"; h.Parent = c
	p.Character = c; p.UserId = 951
end
Players._spelare = { p }
local horse = HastRigg.bygg("start_test", "Start test", CFrame.new(Ridhusplats.tillVarld(RP, vec(0, 0, 18))))
horse.Parent = workspace; Tags:AddTag(horse, "Horse")
local s = HorseService.sessionFor(horse)
local function point(u, v)
	local a = Ridhusplats.tillVarld(RP, vec(u, 0, v))
	return vec(a.X, s.rig.root.Position.Y, a.Z)
end
local function step(u, v, dt)
	local a = point(u, v); s.rig.root.CFrame = CFrame.new(a); s.rig.root.Position = a
	s.energi = 1; Run.Heartbeat:Fire(dt or 0.25)
end
local function still(u, v, sek) for _ = 1, math.ceil(sek / 0.25) do step(u, v) end end
step(0, 18)
local root = p.Character:FindFirstChild("HumanoidRootPart")
local a0 = point(0, 18) + vec(6, 0, 0); root.CFrame = CFrame.new(a0); root.Position = a0
local okM, _, id = HorseService.tryMount(p, horse)
check("KONTROLL: uppsuten", okM == true)
step(0, 18); step(0, 18)
local intentSeq = 0
local function aid(h)
	s.sisteHjalp = -math.huge
	s.intentPolletter = Config.RIDINPUT.SkopaTak
	intentSeq += 1
	Networking.get("RidingIntent").OnServerEvent:Fire(p, id, h, intentSeq)
end
local X = HorseService.ridplats(id).dressyrMitt

local VC, UC, I = VoltLektionController, UgnetaController, LararInstallning
local remote = Networking.get("VoltLektion")
local riktigInvoke = remote.InvokeServer
local syncEv = Networking.get("VoltLektionSync")
Sprak.satVal("sv")
I._aterstallForProv()
VC.avbryt(); VC.start(id, nil)
UC.satLektionsVal(VC.panel)
UC.dolj()
local function knapp(nyckel)
	local t = Sprak.t(nyckel)
	for _, k in ipairs(UC.panel(4).knappar) do if k.text == t then return k end end
	return nil
end
--[[ R1: varje tryck PRÖVAR att kontrollen fanns — ett tryck som inte blev av
	får aldrig stå för en handling. ]]
local function tryck(nyckel, vad)
	local k = knapp(nyckel)
	check("KONTROLL: " .. (vad or nyckel) .. " finns att trycka", k ~= nil)
	if k then k.skicka() end
	return k ~= nil
end
local function text() return UC.panel(4).text or "" end
local function har(t, del) return string.find(t, del, 1, true) ~= nil end
local function borjar(t, del) return string.sub(t, 1, #del) == del end
local HALT = Sprak.t("halsning.halt")
local function h() return VC._halsningForProv() end
--[[ R1: ett NYTT försök går genom den riktiga väljaren: efter ett lyckat
	Avsluta är lektionen fri (valt = false) och Start finns inte förrän
	lektionen väljs igen. ]]
local function nyttForsok()
	VC.valj("halt")
	tryck("haltlektion.start", "Start")
	return RidForsok.aktivt(id) ~= nil
end
local function avsluta()
	tryck("haltlektion.finish", "Avsluta")
	check("KONTROLL: inget aktivt försök efter Avsluta", RidForsok.aktivt(id) == nil)
end
local function ramar(sek)
	for _ = 1, math.floor(sek * 60 + 0.5) do VC.steg(1 / 60) end
end

print("\n── 1. Val och sync ensamt ger ingen hälsning (SYNKRONT) ──")
VC.valj("halt")
check("KONTROLL: lektionssidan är halt och klar att starta", knapp("haltlektion.start") ~= nil)
check("att välja och synka ger ingen hälsning", h() == nil and not har(text(), HALT))

print("\n── 2. Godtagen Start: en hälsning, först i uppgiftens text (SYNKRONT) ──")
do
	tryck("haltlektion.start", "Start")
	check("KONTROLL: servern godtog startet", RidForsok.aktivt(id) ~= nil)
	local t = text()
	check("hälsningen står först, och uppgiften efter den", h() ~= nil and borjar(t, HALT) and #t > #HALT + 1, t)
	check("högst fyra rader, och Avsluta finns", #UC.panel(4).knappar <= 4 and knapp("haltlektion.finish") ~= nil)
	local forsok = h().forsokId
	local kvar = h().kvar
	local _, _, samma = HorseService.voltLektionsBegaran(p, id, "sync", nil, "halt")
	syncEv.OnClientEvent:Fire(samma) -- serverns egen bild av samma försök, som push
	check("en dubblettbild hälsar inte igen", h() ~= nil and h().forsokId == forsok and h().kvar == kvar)
	Sprak.satVal("en")
	check("på engelska: samma hälsning, inte en ny", borjar(text(), Sprak.iSprak("en", "halsning.halt"))
		and h().forsokId == forsok)
	Sprak.satVal("sv")
	--[[ Livslängden i riktiga bildrutor (1/60 s). POLICY: varje V.steg räknar
		högst 1 s, så ett långt dt räknas som 1 s. ]]
	ramar(5.9)
	check("efter 5,9 s står den kvar", h() ~= nil and borjar(text(), HALT))
	ramar(0.2)
	check("efter 6,1 s är den borta", h() == nil and not har(text(), HALT))
	I.satDetalj("kort"); I.satDetalj("detaljerad"); Sprak.satVal("en"); Sprak.satVal("sv")
	check("detalj- och språkbyten väcker den inte", h() == nil and not har(text(), HALT))
	ramar(10)
	check("och den kommer aldrig tillbaka", h() == nil)
	-- Ett långt dt: ett steg på 100 s räknas som 1 s.
	avsluta()
	check("KONTROLL: nytt försök", nyttForsok())
	VC.steg(100)
	check("långt dt räknas som 1 s: hälsningen står kvar", h() ~= nil)
	avsluta()
end

print("\n── 3. Retry hälsar det nya försöket en gång (SYNKRONT) ──")
do
	check("KONTROLL: nytt försök", nyttForsok())
	ramar(7)
	still(0, 18, G.HALT_FORE + 0.5)
	aid("driv")
	for v = 19, X.v - 1 do step(X.u, v) end
	aid("broms")
	still(X.u, X.v - 0.5, G.HALT_EFTER + 0.75)
	check("KONTROLL: försöket är slutfört och Retry visas", knapp("voltlektion.retry") ~= nil)
	check("slutförandet hälsar inte", h() == nil and not har(text(), HALT))
	tryck("voltlektion.retry", "Retry")
	check("Retry: en hälsning för det nya försöket", h() ~= nil and borjar(text(), HALT))
	avsluta()
	check("Avsluta tar bort hälsningen", h() == nil and not har(text(), HALT))
end

print("\n── 4. Nekat, transportfel och bara serverns start (SYNKRONT) ──")
do
	VC.valj("halt")
	remote.InvokeServer = function() return false, "request", nil end
	tryck("haltlektion.start", "Start")
	check("ett nekat start hälsar inte", h() == nil)
	remote.InvokeServer = riktigInvoke
	tryck("voltlektion.sync", "Synka") -- felet visar bara Synka; den rensar det
	remote.InvokeServer = function() error("nätet föll (bänk)") end
	tryck("haltlektion.start", "Start")
	check("ett transportfel hälsar inte", h() == nil)
	remote.InvokeServer = riktigInvoke
	tryck("voltlektion.sync", "Synka")
	--[[ Servern startar själv (inte klientens begäran). Begäranbokens sekvens
		hoppar fram; klientens följer via bildens `sekvens` (mottag). ]]
	local bok = s.lektionsBegaran
	HorseService.voltLektionsBegaran(p, id, "start", (bok and bok.hogsta or 0) + 1, "halt")
	local _, _, bNu = HorseService.voltLektionsBegaran(p, id, "sync", nil, "halt")
	syncEv.OnClientEvent:Fire(bNu)
	check("ett aktivt försök som klienten bara SER via sync hälsar inte", h() == nil and not har(text(), HALT))
	avsluta()
end

print("\n── 5. Kommentarsvalen (SYNKRONT) ──")
do
	I.satKommentarer("inga")
	check("KONTROLL: nytt försök", nyttForsok())
	check("Inga: ingen hälsning, men uppgiften står", h() == nil and not har(text(), HALT) and #text() > 0)
	I.satKommentarer("normal")
	check("tillbaka till Normalt: den förbrukade hälsningen spelas inte upp", h() == nil and not har(text(), HALT))
	avsluta()
	I.satKommentarer("farre") -- ett byte: räknaren börjar om
	check("KONTROLL: nytt försök", nyttForsok())
	check("Färre, första valfria kommentaren: visas", h() ~= nil)
	I.satDetalj("kort"); I.satDetalj("detaljerad") -- ett ovidkommande byte
	avsluta()
	check("KONTROLL: nytt försök", nyttForsok())
	check("Färre, andra: förbrukas (detaljbytet nollställde inte räknaren)", h() == nil)
	avsluta()
	I.satKommentarer("normal")
	-- R1: Inga MEDAN hälsningen syns, och ett snabbt Inga -> Normalt.
	check("KONTROLL: nytt försök", nyttForsok())
	check("KONTROLL: hälsningen syns i den sammansatta värden", borjar(text(), HALT))
	local fore = text()
	I.satKommentarer("inga")
	I.satKommentarer("normal") -- före nästa panelläsning
	local efter = text()
	check("Inga tar bort en synlig hälsning direkt, och Normalt väcker den inte",
		h() == nil and not har(efter, HALT), efter)
	check("uppgiften och framstegen står kvar", #efter > 0 and har(fore, efter))
	avsluta()
end

print("\n── 6. Byte av val, återkoppling och avsittning tar bort den (SYNKRONT) ──")
do
	check("KONTROLL: nytt försök", nyttForsok())
	check("KONTROLL: hälsning", h() ~= nil)
	VC.valj("tempo")
	check("ett annat val tar bort den", h() == nil)
	VC.valj("halt")
	avsluta()
	check("KONTROLL: nytt försök", nyttForsok())
	check("KONTROLL: hälsning", h() ~= nil)
	VC.start(id, nil) -- återkoppling till samma ritt
	check("återkoppling tar bort den, och den kommer inte tillbaka", h() == nil and not har(text(), HALT))
	avsluta()
	check("KONTROLL: nytt försök", nyttForsok())
	check("KONTROLL: hälsning", h() ~= nil)
	VC.avbryt()
	check("avsittning (avbryt) tar bort den", h() == nil)
	VC.start(id, nil); UC.satLektionsVal(VC.panel)
	avsluta()
end

print("\n── 7. Alla tio typer: nyckeln, och typens egen hälsning (PÅHITTADE producentformade svar) ──")
do
	--[[ Svaret byts ut mot en bild formad som producentens för ett nytt aktivt
		försök; det är INTE en riktig serverstart för de nio andra typerna.
		Revisionen är hög; varje typbyte nollställer klientens bild, och
		avsnittet slutar med ett typbyte tillbaka till halt. ]]
	for _, typ in { "volt", "halt", "overgang", "serpentin", "tempo", "vag_mitt", "vag_diag", "halvvolt",
		"galopp", "markbom" } do
		local n = "halsning." .. typ
		check(n .. " finns på båda språken", Sprak.iSprak("sv", n) ~= n and Sprak.iSprak("en", n) ~= n)
		VC.valj("tempo"); VC.valj(typ)
		remote.InvokeServer = function(_, rid, op, seqNu, t)
			return true, nil, { rittId = rid, typ = if t == "volt" then nil else t, forsokId = "f-" .. t,
				revision = 10 ^ 6, sekvens = seqNu, lage = "riding", tips = "ride", progress = 0 }
		end
		local forsta = VC.panel().knappar[1]
		check("KONTROLL: " .. typ .. " har en första knapp (Start)", forsta ~= nil)
		if forsta then forsta.skicka() end
		remote.InvokeServer = riktigInvoke
		check(typ .. ": hälsningen är typens egen", h() ~= nil and h().typ == typ
			and borjar(VC.panel().text or "", Sprak.t(n)), VC.panel().text)
		ramar(7)
	end
	VC.valj("tempo"); VC.valj("halt")
end

print("\n── 8. Ett försök som slutförts FÖRE svaret hälsas inte (SYNKRONT: pushen inom samma anrop) ──")
do
	remote.InvokeServer = function(_, rid, op, seqNu, t)
		syncEv.OnClientEvent:Fire({ rittId = rid, typ = "halt", forsokId = "f-klar", revision = 10 ^ 7,
			sekvens = seqNu, lage = "complete", tips = "complete", progress = 100 })
		return true, nil, { rittId = rid, typ = "halt", forsokId = "f-klar", revision = 10 ^ 6,
			sekvens = seqNu, lage = "halt1", tips = "halt_first", progress = 0 }
	end
	tryck("haltlektion.start", "Start")
	remote.InvokeServer = riktigInvoke
	check("ett svar vars försök redan är slutfört hälsar inte", h() == nil)
	VC.valj("tempo"); VC.valj("halt") -- den påhittade bilden bort
end

print("\n── 9. VERKLIGT FÖRDRÖJT (schemat): händelse före svar, och sena svar ──")
do
	local fordrojd = function(self, ...)
		local svar = table.pack(riktigInvoke(self, ...))
		task.wait() -- svaret dröjer
		return table.unpack(svar, 1, svar.n)
	end
	local function startFordrojd()
		--[[ Valet (och dess sync) FÖRE schemat: annars köas syncen och står
			som väntande, och Start skickas aldrig. ]]
		VC.valj("halt")
		__schemaPa(true)
		remote.InvokeServer = fordrojd
		tryck("haltlektion.start", "Start")
		__schemaSteg() -- servern har godtagit; svaret väntar
		check("KONTROLL: servern godtog startet", RidForsok.aktivt(id) ~= nil)
	end
	local function slapp()
		__schemaTomKo()
		remote.InvokeServer = riktigInvoke
		__schemaPa(false)
	end
	local function stadaForsok()
		if RidForsok.aktivt(id) then
			local bok = s.lektionsBegaran
			HorseService.voltLektionsBegaran(p, id, "finish", (bok and bok.hogsta or 0) + 1, "halt")
			local _, _, b = HorseService.voltLektionsBegaran(p, id, "sync", nil, "halt")
			syncEv.OnClientEvent:Fire(b)
		end
	end
	-- a) Händelse före svar.
	startFordrojd()
	local _, _, pushad = HorseService.voltLektionsBegaran(p, id, "sync", nil, "halt")
	syncEv.OnClientEvent:Fire(pushad)
	check("a) pushen av det nya försöket före svaret hälsar inte", h() == nil)
	slapp()
	check("a) hälsningen kommer med det godtagna svaret", h() ~= nil and borjar(text(), HALT))
	stadaForsok()
	-- b) Sent svar efter ett ANNAT val.
	startFordrojd()
	VC.valj("tempo")
	slapp()
	check("b) ett sent svar efter ett annat val hälsar inte", h() == nil)
	stadaForsok()
	-- c) Sent svar efter att SAMMA lektion valts igen (ingen sync kan skickas medan begäran väntar).
	startFordrojd()
	VC.valj("halt")
	slapp()
	check("c) samma typ vald igen: det gamla svaret hälsar inte", h() == nil)
	check("c) vyn är ärlig och användbar: det aktiva försöket med Avsluta", knapp("haltlektion.finish") ~= nil)
	stadaForsok()
	-- d) A -> B -> A innan svaret.
	startFordrojd()
	VC.valj("tempo"); VC.valj("halt")
	slapp()
	check("d) A -> B -> A: det gamla svaret hälsar inte", h() == nil)
	check("d) vyn visar det aktiva försöket", knapp("haltlektion.finish") ~= nil)
	stadaForsok()
	-- e) Sent svar efter Avsluta.
	startFordrojd()
	local fin = knapp("haltlektion.finish")
	if fin then fin.skicka() end -- Avsluta får skickas trots väntande begäran
	slapp()
	check("e) ett sent svar efter Avsluta hälsar inte", h() == nil)
	stadaForsok()
	-- f) Sent svar efter tidsgränsen (10 s).
	startFordrojd()
	for _ = 1, 11 do VC.steg(1) end
	slapp()
	check("f) ett svar efter tidsgränsen hälsar inte", h() == nil)
	stadaForsok()
	-- g) Sent svar efter återkoppling.
	startFordrojd()
	VC.start(id, nil); UC.satLektionsVal(VC.panel)
	slapp()
	check("g) ett svar efter återkoppling hälsar inte", h() == nil)
	stadaForsok()
end

UC.satLektionsVal(nil)
VC.avbryt()
Skopa._satKlockaForProv(nil)
if fails > 0 then error(tostring(fails) .. " FEL") end
print(string.format("\nINSTRUKTORSTART: %d prov, alla gröna", total))
