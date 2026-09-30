--!nostrict
--[[
	JEV-SKUGGAN PÅ SERVERN OCH KROKEN PÅ KLIENTEN (JEV-POC-2, #270, A').
	Kontraktet §5–§8 och §11 punkt 2, 5–10.

	Servern körs med inskjutna beroenden: ett räknande nätverk, en klocka
	provet styr och en hemlighet som är en vaktpost. Klientkroken mäts
	genom den RIKTIGA LektionController-loopen — samma väg som ugneta.spec.

	Kör: python3 roblox/tests/build.py tests/jevskugga-server.spec.luau
	     && luau roblox/tests/.build/jevskugga-server.spec.luau
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

local SENTINEL = "SEKRET-VAKTPOST-7f3a"

local function json(v, ut)
	ut = ut or {}
	if type(v) == "table" then
		local nycklar = {}
		for k in v do table.insert(nycklar, k) end
		table.sort(nycklar, function(a, b) return tostring(a) < tostring(b) end)
		table.insert(ut, "{")
		for _, k in nycklar do
			table.insert(ut, '"' .. tostring(k) .. '":')
			json(v[k], ut)
			table.insert(ut, ",")
		end
		table.insert(ut, "}")
	else
		table.insert(ut, tostring(v))
	end
	return table.concat(ut)
end

--[[ En spelare som inte TÅL skrivningar: varje fältskrivning eller
     SetAttribute räknas. Skuggan får läsa `horseOf` och inget annat. ]]
local skrivningar = 0
local function spelare(namn, uppsuten)
	local p = { Name = namn, DisplayName = namn, UserId = 900000 + #namn, _hast = uppsuten }
	function p:SetAttribute() skrivningar += 1 end
	return setmetatable({}, {
		__index = p,
		__newindex = function() skrivningar += 1 end,
	})
end

local function giltigt(over)
	local t = { ovningId = "storvolt", forsokNr = 1, nu = { linje = 0.62, balans = 0.41, tempo = 0.9 } }
	for k, v in over or {} do t[k] = v end
	return t
end

local function svarMed(choice, conf)
	return { Success = true, StatusCode = 200,
		Body = { model = "jev-1.13.0", answers = { focus = { type = "choice", choice = choice, confidence = conf } } } }
end

local function nyaDeps()
	local d = { http = 0, hemlighet = 0, loggar = {}, tid = 1000, vantande = {}, synkron = true }
	d.svar = function() return svarMed("balans", 0.9) end
	d.remote = {
		_attr = {},
		SetAttribute = function(self, k, v) self._attr[k] = v end,
		GetAttribute = function(self, k) return self._attr[k] end,
		OnServerEvent = { Connect = function(_, fn)
			d.handler = fn
			return { Disconnect = function() d.handler = nil end }
		end },
	}
	d.horseOf = function(pl) return pl._hast end
	d.hamtaHemlighet = function() d.hemlighet += 1; return SENTINEL end
	d.begar = function(req) d.http += 1; d.req = req; return d.svar(req) end
	d.kodaJson = function(v) return json(v) end
	d.avkodaJson = function(s)
		if s == "TRASIG" then error("kan inte avkoda") end
		return s
	end
	d.klocka = function() return d.tid end
	d.spawn = function(f)
		if d.synkron then f() else table.insert(d.vantande, f) end
	end
	d.logg = function(s) table.insert(d.loggar, s) end
	return d
end

local function starta()
	JevShadow._aterstall()
	local d = nyaDeps()
	JevShadow._start(d)
	return d
end

local function sista() local p = JevShadow.prov(); return p[#p] end

print("\n── Ogiltigt underlag når aldrig nätverket ──")
do
	local d = starta()
	local rid = spelare("A", true)
	local fall = {
		giltigt({ ovningId = "piaff" }),
		giltigt({ nu = { linje = 0 / 0 } }),
		giltigt({ nu = { linje = math.huge } }),
		giltigt({ nu = { linje = 42 } }),
		giltigt({ nu = {} }),
		giltigt({ userId = 1 }),
		giltigt({ ugnetaFokus = "linje" }),
		giltigt({ nu = { tempo_variation = "???", line_error = 42 } }),  -- X09
		"skräp", 17,
	}
	for _, f in fall do
		d.handler(rid, f)
	end
	d.handler(rid, nil)
	table.insert(fall, "nil")
	local alla = true
	for _, p in JevShadow.prov() do
		if p.kalla ~= "invalid_input" then alla = false end
		for k in p do
			if k ~= "id" and k ~= "t" and k ~= "kalla" and k ~= "reason" then alla = false end
		end
	end
	prova("varje ogiltigt prov blir invalid_input med bara id, t, kalla, skäl",
		#JevShadow.prov() == #fall and alla, ("%d prov"):format(#JevShadow.prov()))
	prova("noll förfrågningar och ingen hemlighet läst", d.http == 0 and d.hemlighet == 0,
		("http %d, hemlighet %d"):format(d.http, d.hemlighet))
end

print("\n── Ett giltigt prov: jämförelsen och Jevs svar ──")
do
	local d = starta()
	local rid = spelare("A", true)
	local payload = giltigt()
	local fore = json(payload)
	local k = JevShadow._mottag(rid, payload)
	local p = sista()
	local vantatFokus = JevShadowPolicy.ugneta(JevShadowPolicy.validera(giltigt()))
	prova("provet skickas och blir jev", k == "skickad" and p.kalla == "jev", p.kalla)
	prova("Ugnetas fokus är regelns, räknat på servern", p.ugneta.fokus == vantatFokus, p.ugneta.fokus)
	prova("Jevs fokus och säkerhet sparas", p.jev.fokus == "balans" and p.jev.confidence == 0.9
		and p.jev.model == "jev-1.13.0")
	prova("agree räknas", p.agree == (p.jev.fokus == p.ugneta.fokus), tostring(p.agree))
	prova("latensen mäts", type(p.latensMs) == "number")
	prova("förfrågan: POST, tidsgräns 4 s, hemligheten bara i Authorization",
		d.req.Method == "POST" and d.req.Timeout == 4 and d.req.Headers.Authorization == SENTINEL
			and string.find(d.req.Body, SENTINEL, 1, true) == nil)
	prova("kroppen bär ingen identitet", string.find(d.req.Body, "900001", 1, true) == nil
		and string.find(d.req.Body, "Name", 1, true) == nil)
	prova("klientens tabell är orörd", json(payload) == fore)
end

print("\n── Hård grind: inte uppsuten, ingen hemlighet ──")
do
	local d = starta()
	JevShadow._mottag(spelare("B", nil), giltigt())
	prova("inte uppsuten enligt servern → hard_gate, noll förfrågningar",
		sista().kalla == "hard_gate" and sista().reason == "ej_uppsuten" and d.http == 0)
	d.hamtaHemlighet = function() return nil end
	JevShadow._mottag(spelare("C", true), giltigt())
	prova("ingen hemlighet → hard_gate", sista().reason == "ingen_hemlighet" and d.http == 0)
	d.hamtaHemlighet = function() error("Can't find secret with given key") end
	JevShadow._mottag(spelare("D", true), giltigt())
	prova("hemlighet som kastar → hard_gate", sista().reason == "ingen_hemlighet" and d.http == 0)
end

print("\n── Takten ──")
do
	local d = starta()
	local rid = spelare("E", true)
	for i = 1, 5 do
		JevShadow._mottag(rid, giltigt())
		d.tid += 1
	end
	prova("fem prov inom 10 s → en förfrågan", d.http == 1, ("http %d"):format(d.http))
	d.tid += 10
	JevShadow._mottag(rid, giltigt())
	prova("efter spärren → en till", d.http == 2, ("http %d"):format(d.http))

	d = starta()
	d.synkron = false
	local r2 = spelare("F", true)
	JevShadow._mottag(r2, giltigt())
	d.tid += 11
	JevShadow._mottag(r2, giltigt())
	prova("en förfrågan i luften per spelare", sista().reason == "i_luften", sista().reason)
	for _, f in d.vantande do f() end

	d = starta()
	local skickade = 0
	for i = 1, 25 do
		if JevShadow._mottag(spelare("G" .. i, true), giltigt()) == "skickad" then skickade += 1 end
		d.tid += 2
	end
	prova("25 spelare på 50 s → högst 20 förfrågningar", d.http == 20 and skickade == 20,
		("http %d"):format(d.http))
	prova("resten är hard_gate globalt_tak", sista().reason == "globalt_tak", sista().reason)
	d.tid += 61
	JevShadow._mottag(spelare("H", true), giltigt())
	prova("och taket släpper efter en minut", d.http == 21, ("http %d"):format(d.http))
end

print("\n── Fel i Jev-vägen stannar i skuggan ──")
do
	local fall = {
		{ "timeout (kastar)", function() error("HttpError: Timedout") end, "timeout" },
		{ "anslutningsfel", function() error("HttpError: ConnectFail") end, "api_error" },
		{ "kastar okänt fel efter tidsgränsen", "SEN", "timeout" },
		{ "svarar sent men svarar", "SENT_SVAR", "jev" },
		{ "500", function() return { Success = false, StatusCode = 500, Body = "x" } end, "api_error" },
		{ "401", function() return { Success = false, StatusCode = 401, Body = "x" } end, "api_error" },
		{ "Success men 204 utan kropp", function() return { Success = true, StatusCode = 302, Body = "" } end, "api_error" },
		{ "trasig JSON", function() return { Success = true, StatusCode = 200, Body = "TRASIG" } end, "api_error" },
		{ "okänd etikett", function() return svarMed("line", 0.9) end, "api_error" },
		{ "confidence NaN", function() return svarMed("linje", 0 / 0) end, "api_error" },
		{ "svar som inte är tabell", function() return "hej" end, "api_error" },
		{ "hemligheten i felmeddelandet", function(req)
			error("misslyckades med " .. tostring(req.Headers.Authorization)) end, "api_error" },
	}
	for _, f in fall do
		local d = starta()
		if f[2] == "SEN" then
			d.svar = function() d.tid += 5; error("något") end
		elseif f[2] == "SENT_SVAR" then
			d.svar = function() d.tid += 5; return svarMed("linje", 0.5) end
		else
			d.svar = f[2]
		end
		local ok, k = pcall(JevShadow._mottag, spelare("I", true), giltigt())
		prova(("%s → %s, inget fel ut"):format(f[1], f[3]),
			ok and k == "skickad" and sista().kalla == f[3] and (f[3] == "jev") == (sista().jev ~= nil),
			("%s/%s"):format(tostring(sista().kalla), tostring(sista().reason)))
		local _, andra = pcall(JevShadow._mottag, spelare("J", true), giltigt())
		prova("  och nästa spelare kan skickas direkt", andra == "skickad")
	end
	-- Handlaren via fjärrobjektet sväljer även ett internt fel.
	local d = starta()
	d.kodaJson = function() error("intern") end
	local ok = pcall(d.handler, spelare("K", true), giltigt())
	prova("ett internt fel i handlaren läcker inte ut", ok and sista().kalla == "api_error", sista().reason)
end

print("\n── Hemligheten syns aldrig ──")
do
	local d = starta()
	local allt = {}
	local rid = spelare("L", true)
	d.svar = function(req) error("fel " .. tostring(req.Headers.Authorization)) end
	JevShadow._mottag(rid, giltigt())
	d.tid += 11
	d.svar = function() return svarMed("linje", 0.4) end
	JevShadow._mottag(rid, giltigt())
	d.tid += 11
	d.svar = function() return { Success = false, StatusCode = 401, Body = SENTINEL } end
	JevShadow._mottag(rid, giltigt())
	for _, l in d.loggar do table.insert(allt, l) end
	table.insert(allt, json(JevShadow.prov()))
	table.insert(allt, json(JevShadow.sammanfattning()))
	local text = table.concat(allt, "\n")
	prova("vaktposten finns inte i loggen, bufferten eller sammanfattningen",
		string.find(text, SENTINEL, 1, true) == nil and #d.loggar == 3, ("%d loggrader"):format(#d.loggar))
	prova("loggraden bär bara id, källa och statuskod",
		string.match(d.loggar[3], "^%[JevSkugga%] s%d+ kalla=api_error status=401$") ~= nil, d.loggar[3])
end

print("\n── Servern skriver ingenting i spelet ──")
do
	skrivningar = 0
	local d = starta()
	local rid = spelare("M", true)
	JevShadow._mottag(rid, giltigt())
	d.tid += 11
	d.svar = function() error("HttpError: Timedout") end
	JevShadow._mottag(rid, giltigt())
	JevShadow._mottag(rid, giltigt({ nu = { linje = 9 } }))
	JevShadow._mottag(spelare("N", nil), giltigt())
	prova("noll skrivningar på spelaren i alla vägar", skrivningar == 0, ("%d"):format(skrivningar))
	local s = JevShadow.sammanfattning()
	prova("sammanfattningen räknar källorna", s.antal == 4 and s.kallor.jev == 1 and s.kallor.timeout == 1
		and s.kallor.invalid_input == 1 and s.kallor.hard_gate == 1, json(s.kallor))
end

print("\n── Flaggan AV: ingenting ──")
do
	JevShadow._aterstall()
	local hemligheter, http = 0, 0
	local ss = { _attr = {} }
	function ss:GetAttribute(k) return self._attr[k] end
	__services.ServerStorage = ss
	__services.HttpService = {
		GetSecret = function() hemligheter += 1; return { AddPrefix = function() return SENTINEL end } end,
		RequestAsync = function() http += 1; return svarMed("linje", 0.5) end,
		JSONEncode = function(_, v) return json(v) end,
		JSONDecode = function(_, s) return s end,
	}
	local startad = JevShadow.start(function() return true end)
	prova("start med flaggan av startar inte", startad == false)
	prova("ingen lyssnare: mottagaren svarar av", JevShadow._mottag(spelare("O", true), giltigt()) == "av")
	prova("ingen hemlighet läst, inget nätverk, inga prov",
		hemligheter == 0 and http == 0 and #JevShadow.prov() == 0)
	ss._attr.JevShadowEnabled = "true"
	prova("strängen \"true\" är inte på", JevShadow.start(function() return true end) == false)
	ss._attr.JevShadowEnabled = true
	local okStart, startad2 = pcall(JevShadow.start, function() return true end)
	prova("flaggan PÅ startar (med riktigt Networking-fjärrobjekt)", okStart and startad2 == true,
		tostring(startad2))
	if okStart then
		local r = Networking.get("JevSkugga")
		prova("och fjärrobjektet blir Aktiv", r:GetAttribute("Aktiv") == true)
	end
	JevShadow._aterstall()
end

print("\n── Klientkroken ändrar ingenting spelaren ser ──")
local function tele(over)
	local t = {
		uppsutten = true, gangart = "trav", fart = 3.0, onskadFart = 3.0,
		svangradie = 10, balans = 0.80, mjukhet = 0.75, fokus = 0.80,
		spanning = 0.20, svarstid = 0.12, etableringstid = 0.8,
		paradKvalitet = 0.70,
	}
	for k, v in over or {} do t[k] = v end
	return t
end
local function ettForsok()
	LektionController.start(nil)
	LektionController.steg(1 / 30, tele())
	LektionController.fortsatt()
	local dt = 1 / 30
	for _ = 1, math.floor((Lektion.FORSOK_SEK + 0.3) / dt) do
		LektionController.steg(dt, tele({ mjukhet = 0.30, balans = 0.55 }))
	end
	local rubrik, text = CoachBanner.text()
	local pass = LektionController.pass()
	local utfall = json({ rubrik = rubrik, text = text, ix = pass.ix, nr = pass.forsokNr,
		historik = pass.historik, vantar = LektionController.vantar() })
	LektionController.avbryt()
	return utfall
end

local skickat = {}
local fjarr = { Name = "JevSkugga", _attr = {} }
function fjarr:GetAttribute(k) return self._attr[k] end
function fjarr:FireServer(p) table.insert(skickat, p); if self._kasta then error("nätet föll") end end
local mapp = { Name = "HorseRemotes" }
function mapp:FindFirstChild(n) if n == "JevSkugga" then return fjarr end return nil end

local utan = ettForsok()                    -- ingen mapp alls
rawset(__rs, "HorseRemotes", mapp)
local inaktiv = ettForsok()                 -- fjärrobjekt utan Aktiv
local antalInaktiv = #skickat
fjarr._attr.Aktiv = true
local aktiv = ettForsok()
local p = skickat[#skickat]
fjarr._kasta = true
local kastar = ettForsok()
rawset(__rs, "HorseRemotes", nil)

prova("utan Aktiv fyras ingenting", antalInaktiv == 0, ("%d"):format(antalInaktiv))
prova("med Aktiv fyras exakt ett prov per försök", #skickat == 2, ("%d"):format(#skickat))
prova("kortet, passet och historiken är identiska av/på/kastar",
	utan == inaktiv and utan == aktiv and utan == kastar and string.find(utan, "historik", 1, true) ~= nil,
	if utan ~= aktiv then ("\n    av:  %s\n    på:  %s"):format(utan, aktiv) else nil)
if p then
	local nycklar = {}
	for k in p do table.insert(nycklar, k) end
	table.sort(nycklar)
	prova("provet bär exakt forsokNr, nu, ovningId (fore saknas på försök 1)",
		table.concat(nycklar, ",") == "forsokNr,nu,ovningId", table.concat(nycklar, ","))
	prova("och går igenom serverns validering", JevShadowPolicy.validera(p) ~= nil)
end

if fel > 0 then
	print(("%d mätning(ar) föll."):format(fel))
else
	print("jevskugga-server: alla gröna")
end
