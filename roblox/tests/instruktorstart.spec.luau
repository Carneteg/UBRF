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
	  lämnar över (VERKLIGT FÖRDRÖJDA fall, avsnitt 9);
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
local function tryck(nyckel)
	local k = knapp(nyckel)
	if k then k.skicka() end
	return k ~= nil
end
local function text() return UC.panel(4).text or "" end
local function har(t, del) return string.find(t, del, 1, true) ~= nil end
local function borjar(t, del) return string.sub(t, 1, #del) == del end
local HALT = Sprak.t("halsning.halt")
local function h() return VC._halsningForProv() end

print("\n── 1. Val och sync ensamt ger ingen hälsning ──")
VC.valj("halt")
check("KONTROLL: lektionssidan är halt och klar att starta", knapp("haltlektion.start") ~= nil)
check("att välja och synka ger ingen hälsning", h() == nil and not har(text(), HALT))

print("\n── 2. Godtagen Start: en hälsning, först i uppgiftens text ──")
do
	tryck("haltlektion.start")
	local t = text()
	check("KONTROLL: servern godtog startet (ett aktivt försök)", h() ~= nil and h().typ == "halt")
	check("hälsningen står först, och uppgiften efter den", borjar(t, HALT) and #t > #HALT + 1, t)
	check("sidan har fortfarande högst fyra rader och Avsluta", #UC.panel(4).knappar <= 4
		and knapp("haltlektion.finish") ~= nil)
	local forsok = h().forsokId
	-- En dubblettbild av samma försök (push) hälsar inte igen.
	local b = VC._halsningForProv()
	local kvar = b.kvar
	-- Serverns egen bild av samma försök, levererad som en push.
	local _, _, samma = HorseService.voltLektionsBegaran(p, id, "sync", nil, "halt")
	syncEv.OnClientEvent:Fire(samma)
	check("en dubblettbild hälsar inte igen", h() ~= nil and h().forsokId == forsok and h().kvar <= kvar)
	-- Språk: samma hälsning på engelska, ingen ny.
	Sprak.satVal("en")
	check("på engelska: samma hälsning, inte en ny", borjar(text(), Sprak.iSprak("en", "halsning.halt"))
		and h().forsokId == forsok)
	Sprak.satVal("sv")
	-- Livslängd: 6 s, sedan borta för gott.
	VC.steg(3)
	check("efter 3 s står den kvar", h() ~= nil and borjar(text(), HALT))
	VC.steg(3.1)
	check("efter 6 s är den borta", h() == nil and not har(text(), HALT))
	I.satDetalj("kort"); I.satDetalj("detaljerad"); Sprak.satVal("en"); Sprak.satVal("sv")
	check("detalj- och språkbyten väcker den inte", h() == nil and not har(text(), HALT))
	VC.steg(100)
	check("och den kommer aldrig tillbaka", h() == nil)
end

print("\n── 3. Retry hälsar det nya försöket en gång ──")
do
	still(0, 18, G.HALT_FORE + 0.5)
	aid("driv")
	for v = 19, X.v - 1 do step(X.u, v) end
	aid("broms")
	still(X.u, X.v - 0.5, G.HALT_EFTER + 0.75)
	check("KONTROLL: försöket är slutfört och Retry visas", knapp("voltlektion.retry") ~= nil)
	check("slutförandet hälsar inte", h() == nil and not har(text(), HALT))
	tryck("voltlektion.retry")
	check("Retry: en hälsning för det nya försöket", h() ~= nil and borjar(text(), HALT))
	tryck("haltlektion.finish")
	check("Avsluta tar bort hälsningen", h() == nil and not har(text(), HALT))
end

print("\n── 4. Nekat, transportfel och bara serverns start ──")
do
	VC.valj("halt")
	remote.InvokeServer = function(self, ...) return false, "request", nil end
	tryck("haltlektion.start")
	check("ett nekat start hälsar inte", h() == nil)
	remote.InvokeServer = riktigInvoke
	tryck("voltlektion.sync") -- felet ("network") visar bara Synka; den rensar det
	check("KONTROLL: Start visas igen", knapp("haltlektion.start") ~= nil)
	remote.InvokeServer = function() error("nätet föll (bänk)") end
	tryck("haltlektion.start")
	check("ett transportfel hälsar inte", h() == nil)
	remote.InvokeServer = riktigInvoke
	tryck("voltlektion.sync")
	-- Servern startar själv (inte klientens begäran): klienten ser bara bilden.
	local bok = s.lektionsBegaran
	local seq = (bok and bok.hogsta or 0) + 1
	HorseService.voltLektionsBegaran(p, id, "start", seq, "halt")
	step(0, 18)
	local _, _, bNu = HorseService.voltLektionsBegaran(p, id, "sync", nil, "halt")
	syncEv.OnClientEvent:Fire(bNu)
	check("ett aktivt försök som klienten bara SER via sync hälsar inte", h() == nil and not har(text(), HALT))
	tryck("haltlektion.finish")
end

print("\n── 5. Kommentarsvalen: Inga förbrukar, Färre delar räknaren ──")
do
	I.satKommentarer("inga")
	VC.valj("halt")
	tryck("haltlektion.start")
	check("Inga: ingen hälsning, men uppgiften står", h() == nil and not har(text(), HALT) and #text() > 0)
	I.satKommentarer("normal")
	check("tillbaka till Normalt: den förbrukade hälsningen spelas inte upp", h() == nil and not har(text(), HALT))
	tryck("haltlektion.finish")
	I.satKommentarer("farre") -- ett byte: räknaren börjar om
	tryck("haltlektion.start")
	check("Färre, första valfria kommentaren: visas", h() ~= nil)
	tryck("haltlektion.finish")
	tryck("haltlektion.start")
	check("Färre, andra: förbrukas", h() == nil)
	tryck("haltlektion.finish")
	I.satKommentarer("normal")
end

print("\n── 6. Byte av typ, återkoppling och avsittning tar bort den ──")
do
	tryck("haltlektion.start")
	check("KONTROLL: hälsning", h() ~= nil)
	VC.valj("tempo")
	check("ett annat val tar bort den", h() == nil)
	VC.valj("halt")
	tryck("haltlektion.finish")
	tryck("haltlektion.start")
	check("KONTROLL: hälsning igen (nytt försök)", h() ~= nil)
	VC.start(id, nil) -- återkoppling till samma ritt
	check("återkoppling tar bort den, och den kommer inte tillbaka", h() == nil and not har(text(), HALT))
	tryck("haltlektion.finish")
	tryck("haltlektion.start")
	check("KONTROLL: hälsning igen", h() ~= nil)
	VC.avbryt()
	check("avsittning (avbryt) tar bort den", h() == nil)
	VC.start(id, nil); UC.satLektionsVal(VC.panel)
	tryck("haltlektion.finish")
end

print("\n── 7. Alla tio typer: nyckel och rätt hälsning för typen ──")
do
	local AKTIV = "riding"
	for _, typ in { "volt", "halt", "overgang", "serpentin", "tempo", "vag_mitt", "vag_diag", "halvvolt",
		"galopp", "markbom" } do
		local n = "halsning." .. typ
		check(n .. " finns på båda språken", Sprak.iSprak("sv", n) ~= n and Sprak.iSprak("en", n) ~= n)
		VC.valj(typ)
		--[[ Svaret formas som producentens bild av ett nytt aktivt försök
			(fjärranropet byts ut i bänken; godkännandet är det enda som prövas
			här). ]]
		remote.InvokeServer = function(_, rid, op, seqNu, t)
			return true, nil, { rittId = rid, typ = if t == "volt" then nil else t, forsokId = "f-" .. t,
				revision = 10 ^ 6, sekvens = seqNu, lage = AKTIV, tips = "ride", progress = 0 }
		end
		local startNyckel = if typ == "volt" then "voltlektion.start" else nil
		local k = nil
		for _, x in ipairs(VC.panel().knappar) do
			if startNyckel == nil or x.text == Sprak.t(startNyckel) then k = k or x end
		end
		if k then k.skicka() end
		remote.InvokeServer = riktigInvoke
		check(typ .. ": hälsningen är typens egen", h() ~= nil and h().typ == typ
			and borjar(VC.panel().text or "", Sprak.t(n)), VC.panel().text)
		VC.steg(10)
	end
	VC.valj("halt")
end

print("\n── 8. Ett försök som redan slutförts hälsas inte ──")
do
	remote.InvokeServer = function(_, rid, op, seqNu, t)
		-- Pushen om att försöket redan är slutfört kommer FÖRE svaret.
		syncEv.OnClientEvent:Fire({ rittId = rid, typ = "halt", forsokId = "f-klar", revision = 10 ^ 7,
			sekvens = seqNu, lage = "complete", tips = "complete", progress = 100 })
		return true, nil, { rittId = rid, typ = "halt", forsokId = "f-klar", revision = 10 ^ 6,
			sekvens = seqNu, lage = "halt1", tips = "halt_first", progress = 0 }
	end
	local k = knapp("haltlektion.start") or knapp("voltlektion.retry")
	check("KONTROLL: Start eller Retry finns att trycka", k ~= nil)
	if k then k.skicka() end
	remote.InvokeServer = riktigInvoke
	check("ett svar vars försök redan är slutfört hälsar inte", h() == nil)
	-- Den påhittade bilden (hög revision) byts bort genom ett typbyte, så att
	-- serverns riktiga bilder tas emot igen.
	VC.valj("tempo"); VC.valj("halt")
end

print("\n── 9. VERKLIGT FÖRDRÖJT: händelse före svar, och ett sent svar efter ett nytt val ──")
do
	check("KONTROLL: halten är klar att starta", knapp("haltlektion.start") ~= nil)
	-- Händelse före svar: servern godtar, pushen går ut, svaret kommer sist.
	__schemaPa(true)
	remote.InvokeServer = function(self, ...)
		local svar = table.pack(riktigInvoke(self, ...))
		task.wait() -- svaret dröjer
		return table.unpack(svar, 1, svar.n)
	end
	tryck("haltlektion.start")
	__schemaSteg() -- servern har godtagit; svaret väntar
	-- Pushen av det nya försöket (serverns egen bild) kommer FÖRE svaret.
	local _, _, pushad = HorseService.voltLektionsBegaran(p, id, "sync", nil, "halt")
	syncEv.OnClientEvent:Fire(pushad)
	check("KONTROLL: klienten ser redan det nya försöket via pushen, utan hälsning",
		h() == nil and VC.panel() ~= nil)
	__schemaTomKo()
	check("händelse före svar: hälsningen kommer med svaret", h() ~= nil and borjar(text(), HALT))
	tryck("haltlektion.finish")
	__schemaTomKo()
	-- Ett sent godtaget svar efter ett nytt val: ingen hälsning.
	tryck("haltlektion.start")
	__schemaSteg()
	VC.valj("tempo") -- ny begäran: det väntande svaret blir inaktuellt
	__schemaTomKo()
	check("ett sent svar efter ett annat val hälsar inte", h() == nil)
	remote.InvokeServer = riktigInvoke
	__schemaPa(false)
end

UC.satLektionsVal(nil)
VC.avbryt()
Skopa._satKlockaForProv(nil)
if fails > 0 then error(tostring(fails) .. " FEL") end
print(string.format("\nINSTRUKTORSTART: %d prov, alla gröna", total))
