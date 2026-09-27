--!nostrict
--[[ SKÖTSELMINNET — spelarens egna första gånger (C). docs/CARE-MEMORY-CONTRACT.md.

	KOHERENS-bänken med integration-specens sessionsuppställning:
	- SparService, StallService, HorseService och GameplayService startas i
	  produktionens ordning;
	- spelaren släpps in genom PlayerAdded, och riggen byggs för den häst
	  stallet gav;
	- momenten går genom `GameplayService.moment` (samma väg som
	  `PreparationMoment`) med kanonens moment.

	SKRIVEN FÖR SENARE KÖRNING (bygg nu, testa sist). Inte körd.
	ETIKETTER:
	- SYNKRONT: bänkens `task.defer` kör skrivförsöket direkt;
	- VERKLIGT FÖRDRÖJT: på schemat `__schemaPa`, avsnitt 9 (en skötselmarkörs
	  egen skrivning) och 11 (en passkrivning, samma persistenssteg som
	  avslutaPass, anropat direkt);
	- SYNTETISK VY: avsnitt 12:s fråga och återlämning (fält som servern
	  skickar, genom PreparationSync-lyssnaren); sessionen och historiken där
	  är riktiga (LocalPlayer);
	- REGELNIVÅ: välfärdsstoppet (avsnitt 6) körs med ett riktigt
	  Preparation-tillstånd och riktiga regler, och kroken anropas direkt;
	  inte genom tjänsten, eftersom fyndets pass inte kan väljas för
	  stallets häst i bänken;
	- KLIENTEN: serverns egen projektion levereras genom klientens händelse
	  (bänkens FireClient levererar bara till LocalPlayer, och sessionens
	  spelare är en annan tabell). ]]
local fails, total = 0, 0
local function check(namn, villkor, detalj)
	total += 1
	if not villkor then fails += 1 end
	print((if villkor then "  OK   " else "  FEL  ") .. namn .. (if detalj then "  " .. tostring(detalj) else ""))
end
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Taggar = game:GetService("CollectionService")
local vec = Vector3.new
local LM = LektionsMinne
local nastaUid = 9600

local function nySpelare(namn, uid, pos)
	local k = Instance.new("Model"); k.Name = "Karaktar"
	local rot = Instance.new("Part"); rot.Name = "HumanoidRootPart"; rot.Size = vec(2, 2, 1)
	rot.CFrame = CFrame.new(pos); rot.Parent = k
	local hum = Instance.new("Humanoid"); hum.Name = "Humanoid"; hum.Parent = k
	return { Name = namn, UserId = uid, Character = k, CharacterAdded = __signal_ny(),
		CharacterRemoving = __signal_ny() }
end
local startad = false
local function nySession(namn, forbered)
	nastaUid += 1
	local sp = nySpelare(namn, nastaUid, vec(6, 0, 0))
	SparService._glomForProv(sp)
	if forbered then forbered(sp) end
	RunService._server = true
	if not startad then
		__datastore.nollstall()
		Taggar:nollstall()
		SparService._glomHookarForProv()
		SparService.start(); StallService.start(); HorseService.start(); GameplayService.start()
		startad = true
	end
	Players._spelare = { sp }
	Players.PlayerAdded:Fire(sp)
	if Players.PlayerAdded.slutfor then Players.PlayerAdded:slutfor() end
	local hastId = StallService.hastIdFor(sp)
	if hastId then
		local h = (UBRFSpel.hastar or {})[hastId]
		local m = HastRigg.bygg(hastId, (h and h.namn) or hastId, CFrame.new(vec(0, 0, 0)))
		m.Parent = workspace
		Taggar:AddTag(m, "Horse")
	end
	return sp, hastId
end
local function lamna(sp)
	Players.PlayerRemoving:Fire(sp)
	Players._spelare = {}
end
local function proj(sp) return LM._projektion(LM._tillstandForProv(sp)) end
local function rad(sp) return __datastore._data["spelare_" .. sp.UserId] end
local function radMarkor(sp, sid)
	local r = rad(sp)
	return r and r.framsteg and r.framsteg[LM.nyckel("skotsel:" .. sid)]
end
local function gor(sp, fas, mid) return GameplayService.moment(sp, fas, mid) end
local function gorFas(sp, fas, stoppVid)
	while true do
		local s = GameplayService.stateFor(sp)
		local m = Preparation.nastaMoment(s, fas)
		if not m or (stoppVid and stoppVid(m.id)) then return true end
		local ok, skal = gor(sp, fas, m.id)
		if not ok then return false, fas .. "/" .. m.id .. ": " .. tostring(skal) end
	end
end
local function korrektHalsning()
	for _, m in ipairs(Preparation.moment("halsa")) do if not m.fel then return m.id end end
end
local function felHalsning()
	for _, m in ipairs(Preparation.moment("halsa")) do if m.fel then return m.id end end
end

print("\n── 0. Definitionerna ur kanon ──")
check("nycklarna är versionerade och i en egen namnrymd", LM.nyckel("skotsel:rykta") ~= nil
	and string.sub(LM.nyckel("skotsel:rykta"), 1, 8) == "skotsel:" and LM.nyckel("skotsel:okand") == nil
	and LM.nyckel("halt") ~= LM.nyckel("skotsel:halsa"))
check("hovarna är fyra, bara hov:-momenten", #LM._skotselMoment("hovar") == 4)
check("hälsningens kvalificerande moment är bara de riktiga alternativen",
	#LM._skotselMoment("halsa") == #Preparation.moment("halsa") - 1)

print("\n── 1. Hälsningen: fel val inget, rätt val med egen hand = gjort (SYNKRONT) ──")
local A, A_hast = nySession("Egen")
do
	check("KONTROLL: laddad, betrodd, häst tilldelad", A_hast ~= nil and SparService.betroddLasning(A))
	check("allt ej klarat från början", proj(A).skotsel.halsa == "ej_klarad" and proj(A).skotsel.hovar == "ej_klarad")
	local okFel = gor(A, "halsa", felHalsning())
	check("fel alternativ: nej, och ingen markör", okFel == false and proj(A).skotsel.halsa == "ej_klarad")
	local okRatt = gor(A, "halsa", korrektHalsning())
	check("rätt alternativ med egen hand: sparad", okRatt == true and proj(A).skotsel.halsa == "sparad")
	local f = radMarkor(A, "halsa")
	check("lagret: en boolesk markör 1/1, ingen tid", f ~= nil and f.forsok == 1 and f.klarade == 1 and f.senast == 0)
end

print("\n── 2. Visitation, ryktning, hovar: först vid SISTA momentet (SYNKRONT) ──")
do
	local vis = Preparation.moment("visitera")
	local sista = vis[#vis].id
	check("KONTROLL: visitationen utan det sista", gorFas(A, "visitera", function(id) return id == sista end))
	check("före sista punkten: inte gjort", proj(A).skotsel.visitera == "ej_klarad")
	gor(A, "visitera", sista)
	check("efter sista punkten, frisk dag (pass 1): gjort", proj(A).skotsel.visitera == "sparad")
	check("KONTROLL: ryktningen", gorFas(A, "rykta"))
	check("ryktningen: gjort", proj(A).skotsel.rykta == "sparad")
	GameplayService.valjUtrustning(A, "sadel", A_hast)
	GameplayService.valjUtrustning(A, "trans", A_hast)
	check("KONTROLL: bara hovarna", gorFas(A, "iordning", function(id) return string.sub(id, 1, 4) == "utr:" end))
	check("hovarna före utrustningen: gjort, fast fasen inte är klar",
		proj(A).skotsel.hovar == "sparad" and not Preparation.fasKlar(GameplayService.stateFor(A), "iordning"))
	local okDubbel = gor(A, "rykta", Preparation.moment("rykta")[1].id)
	check("dubblett: nej, markören oförändrad 1/1", okDubbel == false and radMarkor(A, "rykta").forsok == 1)
end

print("\n── 3. Fel ordning ger inget (SYNKRONT) ──")
local B, B_hast = nySession("Ordning")
do
	local okOrdning = gor(B, "rykta", Preparation.moment("rykta")[1].id)
	check("ryktning före hälsning: nej, inget", okOrdning == false and proj(B).skotsel.rykta == "ej_klarad")
	check("en annan spelares arbete ger B inget", proj(B).skotsel.halsa == "ej_klarad")
end

print("\n── 4. Helt automatiskt (Rida nu) och blandat (SYNKRONT) ──")
do
	local okNu = GameplayService.ridaNu(B)
	local s = GameplayService.stateFor(B)
	check("KONTROLL: stallet förberedde", s ~= nil and Preparation.fasKlar(s, "rykta"))
	local p = proj(B).skotsel
	check("Rida nu ger inga egna markörer", p.halsa == "ej_klarad" and p.visitera == "ej_klarad"
		and p.rykta == "ej_klarad" and p.hovar == "ej_klarad", tostring(okNu))
	lamna(B) -- så att nästa session inte delar häst med en kvarvarande spelare
end
local C, C_hast = nySession("Blandat")
do
	gor(C, "halsa", korrektHalsning())
	gorFas(C, "visitera")
	local rykt = Preparation.moment("rykta")
	gor(C, "rykta", rykt[1].id) -- ett eget
	GameplayService.ridaNu(C) -- resten av stallet
	check("blandad ryktning (ett eget, resten auto): inte gjort", proj(C).skotsel.rykta == "ej_klarad")
	check("men hälsningen och visitationen som hon gjorde själv: gjort",
		proj(C).skotsel.halsa == "sparad" and proj(C).skotsel.visitera == "sparad")
	lamna(C)
end

print("\n── 5. En ny tilldelning / nytt tillstånd tar inte bort historiken (SYNKRONT) ──")
do
	lamna(A)
	SparService._glomForProv(A)
	Players._spelare = { A }
	Players.PlayerAdded:Fire(A)
	if Players.PlayerAdded.slutfor then Players.PlayerAdded:slutfor() end
	local p = proj(A).skotsel
	check("betrodd omläsning: det egna arbetet står kvar som sparat",
		p.halsa == "sparad" and p.visitera == "sparad" and p.rykta == "sparad" and p.hovar == "sparad")
	local s = GameplayService.stateFor(A)
	check("historiken gör INTE dagens skötsel klar", s == nil or not Preparation.fasKlar(s, "halsa"))
end

print("\n── 6. Välfärdsstoppet (REGELNIVÅ: riktigt tillstånd, kroken direkt) ──")
do
	local D, D_hast = nySession("Fynd")
	local pass, st = nil, nil
	for pnr = 2, 60 do
		local k = Preparation.nyState(D_hast, pnr)
		if k.fynd then pass, st = pnr, k; break end
	end
	check("KONTROLL: ett pass med fynd för hästen", st ~= nil)
	if st then
		for _, m in ipairs(Preparation.moment("halsa")) do
			if not m.fel then Preparation.utforMoment(st, "halsa", m.id, D_hast); break end
		end
		for _, m in ipairs(Preparation.moment("visitera")) do
			local ok = Preparation.utforMoment(st, "visitera", m.id, D_hast)
			if ok then LM.skotselMoment(D, st, "visitera", m.id, nil) end
			if st.fyndSett then break end
		end
		check("KONTROLL: fyndet är sett", st.fyndSett == true)
		local okSvar = Preparation.svaraFynd(st, Preparation.fyndSvar()[1].id)
		for _, s2 in ipairs(Preparation.fyndSvar()) do
			if not s2.fel then Preparation.svaraFynd(st, s2.id) end
		end
		check("KONTROLL: rätt rapport stoppade arbetet", st.stoppad ~= nil, tostring(okSvar))
		check("en visitation med fynd blir aldrig 'gjord'", proj(D).skotsel.visitera == "ej_klarad")
	end
	lamna(D)
end

print("\n── 7. Lagring: fel och återhämtning, fullt, okänd historik (SYNKRONT) ──")
do
	local E = nySession("Lagring")
	__datastore.felSkriv = true
	gor(E, "halsa", korrektHalsning())
	check("skrivfel: 'gjort nu – inte sparat än'", proj(E).skotsel.halsa == "vantar")
	__datastore.felSkriv = false
	LM._forsokSparaForProv(E)
	check("återhämtning: sparad", proj(E).skotsel.halsa == "sparad")
	-- Fullt framsteg: markören får inte plats.
	local save = SparService.save(E)
	local n = 0
	for _ in pairs(save.framsteg) do n += 1 end
	for i = 1, Sparning.MAX_FRAMSTEG - n do save.framsteg["fyll" .. i] = { forsok = 1, klarade = 0, senast = 0 } end
	local vis = Preparation.moment("visitera")
	gorFas(E, "visitera")
	check("fullt: visitationen står som väntande, aldrig sparad", proj(E).skotsel.visitera == "vantar")
	for i = 1, Sparning.MAX_FRAMSTEG do save.framsteg["fyll" .. i] = nil end
	lamna(E)
	local F = nySession("Lasfel", function() __datastore.felLas = true end)
	__datastore.felLas = false
	local p = proj(F)
	check("läsfel: historiken och alla fyra är okända", p.historik == "okand" and p.skotsel.halsa == "okand"
		and p.skotsel.hovar == "okand")
	lamna(F)
end

print("\n── 8. Klienten: ordning, avsnittet i värdens hjälplista, SV/EN (KLIENTEN) ──")
do
	local PC, NR = PreparationController, Naromrade
	local ev = Networking.get("LektionsMinneSync")
	local server = proj(A)
	ev.OnClientEvent:Fire(server)
	local h = PC._skotselHistorik()
	check("avsnittet: rubriken och alla fyra som gjorda", h ~= nil and string.find(h, Sprak.t("skotselminne.rubrik"), 1,
		true) ~= nil and select(2, string.gsub(h, Sprak.t("skotselminne.sparad"), "")) >= 4, h)
	-- Ett äldre svar efter en nyare push ersätter inte.
	local aldre = table.clone(server); aldre.rev = server.rev - 1
	aldre.skotsel = { halsa = "ej_klarad", visitera = "ej_klarad", rykta = "ej_klarad", hovar = "ej_klarad" }
	ev.OnClientEvent:Fire(aldre)
	check("ett äldre svar ersätter inte nyare fakta", string.find(PC._skotselHistorik(),
		Sprak.t("skotselminne.ej_klarad"), 1, true) == nil)
	-- Okänd historik: en neutral rad.
	local okand = table.clone(server); okand.session = server.session + 1; okand.rev = 0; okand.historik = "okand"
	okand.skotsel = { halsa = "okand", visitera = "okand", rykta = "okand", hovar = "okand" }
	ev.OnClientEvent:Fire(okand)
	check("okänd historik: den neutrala raden", string.find(PC._skotselHistorik(), Sprak.t("skotselminne.okand"),
		1, true) ~= nil)
	Sprak.satVal("en")
	check("på engelska", string.find(PC._skotselHistorik(), "I can't read your care history", 1, true) ~= nil)
	Sprak.satVal("sv")
	--[[ Värden: avsnittet i hjälplistan, inga nya rader. Kräver att bänkens
		LocalPlayer har en skötselvy (PreparationController.panel); saknas den
		är värddelen INTE provad här — det skrivs ut, inte räknas som grönt. ]]
	if PC.panel() ~= nil then
		local fore = #NR._val()
		NR.satRider(false)
		local knapp = NR._panel().hjalpKnapp
		check("KONTROLL: hjälpknappen finns", knapp ~= nil)
		if knapp then knapp.MouseButton1Click:Fire() end
		NR.satRider(false)
		check("hjälplistan bär avsnittet efter dagens steg",
			string.find(NR._panel().hjalp, Sprak.t("skotselminne.okand"), 1, true) ~= nil, NR._panel().hjalp)
		check("inga nya rader i panelen", #NR._val() == fore, ("%d / %d"):format(fore, #NR._val()))
		if knapp then knapp.MouseButton1Click:Fire() end
	else
		print("  HOPPAT  värddelen: bänkens LocalPlayer har ingen skötselvy (PLANERAT)")
	end
end

print("\n── 9. VERKLIGT FÖRDRÖJT: skötsel medan en skrivning är i luften, och avfärd under den ──")
do
	local G, G_hast = nySession("Luft")
	-- A-markör (hälsning) står som väntande (skrivfel), sedan skrivs den på schemat och väntar efter landning.
	__datastore.felSkriv = true
	gor(G, "halsa", korrektHalsning())
	__datastore.felSkriv = false
	check("KONTROLL: hälsningen väntar", proj(G).skotsel.halsa == "vantar")
	__schemaPa(true)
	__datastore.efterSkriv = function() __datastore.efterSkriv = nil; task.wait() end
	task.spawn(LM._forsokSparaForProv, G)
	__schemaSteg()
	check("KONTROLL: skrivningen i luften, raden landad", LM._tillstandForProv(G).skriverNu == true
		and radMarkor(G, "halsa") ~= nil)
	-- B: en hel visitation medan skrivningen väntar.
	gorFas(G, "visitera")
	check("visitationen under en skrivning i luften: väntande, i den ersatta cachen, inte i lagret",
		proj(G).skotsel.visitera == "vantar" and SparService.save(G).framsteg[LM.nyckel("skotsel:visitera")] ~= nil
		and radMarkor(G, "visitera") == nil)
	-- Avfärd medan skrivningen väntar: den begränsade dräneringen.
	Players.PlayerRemoving:Fire(G)
	__schemaTomKo()
	__schemaPa(false)
	check("avfärden dränerade: visitationen finns i lagret", radMarkor(G, "visitera") ~= nil)
	SparService._glomForProv(G)
	Players._spelare = { G }
	Players.PlayerAdded:Fire(G)
	if Players.PlayerAdded.slutfor then Players.PlayerAdded:slutfor() end
	check("betrodd omläsning: båda sparade", proj(G).skotsel.halsa == "sparad" and proj(G).skotsel.visitera == "sparad")
	lamna(G)
end

print("\n── 10. Versionspolicyn: samma definition samma nyckel, reviderad definition ny nyckel ──")
do
	local fore = LM.nyckel("skotsel:rykta")
	check("samma definition ger samma nyckel", LM.nyckel("skotsel:rykta") == fore)
	LM._satSkotselVersionForProv("rykta", "v2")
	local reviderad = LM.nyckel("skotsel:rykta")
	check("en reviderad definition (höjd version) ger en ny nyckel", reviderad ~= fore)
	LM._satSkotselVersionForProv("rykta", "v1")
	check("tillbaka: samma nyckel som förut (ingen omsättning av en oförändrad definition)",
		LM.nyckel("skotsel:rykta") == fore)
end

print("\n── 11. VERKLIGT FÖRDRÖJT: en passkrivning i luften och en skötselmarkör under den ──")
--[[ Skrivningen är samma persistenssteg som `GameplayService.avslutaPass`
	gör (`Sparning.registreraPass` + `SparService.skriv(player)`), anropat
	DIREKT — inte hela avslutaPass-flödet. ]]
do
	local H = nySession("Passkrivning")
	gor(H, "halsa", korrektHalsning())
	gorFas(H, "visitera")
	__schemaPa(true)
	__datastore.efterSkriv = function() __datastore.efterSkriv = nil; task.wait() end
	task.spawn(function()
		Sparning.registreraPass(SparService.save(H), "prov-pass-1", 1)
		SparService.skriv(H)
	end)
	__schemaSteg()
	check("KONTROLL: passkrivningen i luften, raden landad", rad(H) ~= nil and rad(H).passId["prov-pass-1"] ~= nil)
	gorFas(H, "rykta") -- skötseln fullföljs under den
	check("ryktningen under passkrivningen: väntande (egen skrivning nekad som upptagen)",
		proj(H).skotsel.rykta == "vantar" and radMarkor(H, "rykta") == nil)
	__schemaTomKo()
	__schemaPa(false)
	check("efter passkrivningen: markören finns i den ersatta cachen", SparService.save(H).framsteg[LM.nyckel(
		"skotsel:rykta")] ~= nil)
	LM._forsokSparaForProv(H)
	check("och bekräftas av minnets eget försök", proj(H).skotsel.rykta == "sparad" and radMarkor(H, "rykta") ~= nil)
	check("passkvittot står kvar", rad(H).passId["prov-pass-1"] ~= nil)
	lamna(H)
end

print("\n── 12. Den RIKTIGA LocalPlayer-skötselvyn: historiken bredvid en fråga och en återlämning, fyra rader, SV/EN ──")
--[[ Sessionen körs med `Players.LocalPlayer`, så att serverns
	PreparationSync och minnespushar faktiskt når klienten (bänkens
	FireClient levererar till LocalPlayer). Frågan och återlämningen läggs i
	en SYNTETISK vy genom samma PreparationSync-lyssnare (fält som servern
	skickar) — samma grepp som utrustning-rattelse-specen. ]]
do
	local lp = Players.LocalPlayer
	nastaUid += 1
	lp.UserId = nastaUid
	lp.Name = "Lokal"
	lp.Character = nySpelare("Lokal", nastaUid, vec(6, 0, 0)).Character
	lp.CharacterAdded = lp.CharacterAdded or __signal_ny()
	lp.CharacterRemoving = lp.CharacterRemoving or __signal_ny()
	SparService._glomForProv(lp)
	Players._spelare = { lp }
	Players.PlayerAdded:Fire(lp)
	if Players.PlayerAdded.slutfor then Players.PlayerAdded:slutfor() end
	local hid = StallService.hastIdFor(lp)
	if hid then
		local h = (UBRFSpel.hastar or {})[hid]
		local m = HastRigg.bygg(hid, (h and h.namn) or hid, CFrame.new(vec(0, 0, 0)))
		m.Parent = workspace
		Taggar:AddTag(m, "Horse")
	end
	local PC, NR = PreparationController, Naromrade
	check("KONTROLL: den lokala skötselvyn finns", PC.panel() ~= nil)
	gor(lp, "halsa", korrektHalsning()) -- riktig hälsning: markören pushas till klienten
	check("KONTROLL: klienten fick historiken", PC._skotselHistorik() ~= nil)
	local sync = Networking.get("PreparationSync")
	local rev = 10 ^ 6
	sync.OnClientEvent:Fire({ hastId = hid, hastnamn = "Häst", status = "preparing", steg = {}, nasta = nil,
		redo = false, burenUtrustning = nil, rev = rev,
		burnaDelar = { { typ = "sadel", hastId = "annan_hast", hastnamn = "Annan", registrerad = true, forvarv = 1 } },
		moment = { { id = "q1", namn = "Svar 1", fel = true }, { id = "q2", namn = "Svar 2" } } })
	local pd = PC.panel()
	check("frågan har företräde och sidan ryms i fyra rader", pd ~= nil and #pd.val <= 4
		and pd.val[1] ~= nil and pd.val[1].rattelse ~= true)
	NR.satRider(false)
	local fore = #NR._val()
	local knapp = NR._panel().hjalpKnapp
	check("KONTROLL: hjälpknappen finns", knapp ~= nil)
	if knapp then knapp.MouseButton1Click:Fire() end
	NR.satRider(false)
	local hjalp = NR._panel().hjalp
	check("hjälplistan bär historiken efter dagens steg (hälsningen gjord)", string.find(hjalp,
		Sprak.t("skotselminne.halsa"), 1, true) ~= nil and string.find(hjalp, Sprak.t("skotselminne.rubrik"), 1, true) ~= nil,
		hjalp)
	check("historiken lägger inte till någon rad", #NR._val() == fore)
	Sprak.satVal("en")
	NR.satRider(false)
	check("på engelska", string.find(NR._panel().hjalp, "What you have done yourself", 1, true) ~= nil)
	Sprak.satVal("sv")
	if knapp then knapp.MouseButton1Click:Fire() end
	lamna(lp)
end

RunService._server = false
if fails > 0 then error(tostring(fails) .. " FEL") end
print(string.format("\nSKOTSELMINNE: %d prov, alla gröna", total))
