--!nostrict
--[[
	JEV-SKUGGANS REGEL (JEV-POC-2, #270, A'). Kontraktet §4, §2.2, §6, §11.

	Mäter den rena modulen: vad som får gå till Jev, vad Ugneta säger om
	samma försök (med den BEFINTLIGA regeln) och hur Jevs svar får läsas.

	Kör: python3 roblox/tests/build.py tests/jevskugga-policy.spec.luau
	     && luau roblox/tests/.build/jevskugga-policy.spec.luau
]]

local P = JevShadowPolicy
local fel = 0
local function prova(vad, ok, detalj)
	if ok then
		print(("  OK   %s%s"):format(vad, if detalj then "  " .. detalj else ""))
	else
		fel += 1
		print(("  FEL  %s%s"):format(vad, if detalj then "  " .. detalj else ""))
	end
end

--[[ Ett riktigt försöksunderlag, byggt av lifecyclen själv — inte
     handskrivet. Samma väg som klienten: matning → avslutaForsok. ]]
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

local function riktigtForsok(ix, forsokNr, over, fore)
	local pass = Lektion.nyttPass()
	pass.ix = ix
	pass.forsokNr = forsokNr
	if fore then pass.historik[Lektion.ORDNING[ix]] = { fore } end
	for _ = 1, 60 do Lektion.matning(pass, tele(over), 0.1) end
	return Lektion.avslutaForsok(pass)
end

print("\n── 1. Validatorn tar emot riktiga försök ur alla sex övningar ──")
local riktiga = {}
for ix, id in Lektion.ORDNING do
	local h1 = riktigtForsok(ix, 1, { mjukhet = 0.30 })
	local h2 = riktigtForsok(ix, 2, { mjukhet = 0.60 }, h1 and h1.nu)
	--[[ Andra försöket som INTE blev bättre: grenen `kvar`. ]]
	local h3 = riktigtForsok(ix, 2, { mjukhet = 0.28, balans = 0.40 }, h1 and h1.nu)
	for _, h in { h1, h2, h3 } do
		local payload = { ovningId = h.ovningId, forsokNr = h.forsokNr, nu = h.nu, fore = h.fore }
		local rent, skal = P.validera(payload)
		prova(("%s försök %d godkänns"):format(id, h.forsokNr), rent ~= nil, skal)
		table.insert(riktiga, payload)
	end
end
prova("andra försöket utan fore godkänns (första försöket gav inget underlag)",
	P.validera({ ovningId = "storvolt", forsokNr = 2, nu = { linje = 0.5 } }) ~= nil)

print("\n── 2. Varje regel har sitt eget röda fall ──")
local bas = { ovningId = "storvolt", forsokNr = 1, nu = { linje = 0.6, balans = 0.7 } }
local function med(over)
	local t = { ovningId = bas.ovningId, forsokNr = bas.forsokNr, nu = table.clone(bas.nu) }
	for k, v in over do
		if v == "__nil" then t[k] = nil else t[k] = v end
	end
	return t
end
local roda = {
	{ "inte en tabell", "storvolt" },
	{ "okänt fält", med({ ugnetaFokus = "linje" }) },
	{ "userId i underlaget", med({ userId = 123 }) },
	{ "numerisk nyckel", (function() local t = med({}); t[1] = 1; return t end)() },
	{ "okänd övning", med({ ovningId = "piaff" }) },
	{ "fel skiftläge på övningen", med({ ovningId = "Storvolt" }) },
	{ "övningen saknas", med({ ovningId = "__nil" }) },
	{ "forsokNr 3", med({ forsokNr = 3 }) },
	{ "forsokNr 1.5", med({ forsokNr = 1.5 }) },
	{ "forsokNr som sträng", med({ forsokNr = "1" }) },
	{ "forsokNr NaN", med({ forsokNr = 0 / 0 }) },
	{ "nu saknas", med({ nu = "__nil" }) },
	{ "nu tom", med({ nu = {} }) },
	{ "nu är en sträng", med({ nu = "0.5" }) },
	{ "okänd dimension i nu", med({ nu = { linje = 0.5, rein_pressure = 0.2 } }) },
	{ "rytm (mäts aldrig på Roblox)", med({ nu = { rytm = 0.5 } }) },
	{ "NaN i nu", med({ nu = { linje = 0 / 0 } }) },
	{ "+inf i nu", med({ nu = { linje = math.huge } }) },
	{ "-inf i nu", med({ nu = { linje = -math.huge } }) },
	{ "negativt värde", med({ nu = { linje = -0.01 } }) },
	{ "värde över 1", med({ nu = { linje = 1.01 } }) },
	{ "sträng som värde", med({ nu = { linje = "0.5" } }) },
	{ "boolean som värde", med({ nu = { linje = true } }) },
	{ "tabell som värde", med({ nu = { linje = { 0.5 } } }) },
	{ "fore med okänd dimension", med({ fore = { line_error = 0.3 } }) },
	{ "fore med NaN", med({ fore = { linje = 0 / 0 } }) },
	{ "fore tom", med({ fore = {} }) },
	{ "fore som tal", med({ fore = 0.4 }) },
	{ "metatabell", setmetatable(med({}), {}) },
	--[[ X09 ur JEV-POC-1: en sträng, ett omöjligt värde och ett okänt fält. ]]
	{ "X09 (tempo_variation=???, line_error=42, rein_pressure=null)",
		med({ nu = { tempo_variation = "???", line_error = 42 } }) },
	{ "X09 omskriven till kända namn (linje=42)", med({ nu = { linje = 42, tempo = "???" } }) },
}
for _, fall in roda do
	local rent, skal = P.validera(fall[2])
	prova(("avvisas: %s"):format(fall[1]), rent == nil and type(skal) == "string", skal)
end
do
	local m = {}
	for i = 1, 7 do m[("d%d"):format(i)] = 0.5 end
	local _, skal = P.validera(med({ nu = m }))
	prova("fler nycklar än det finns mätbara dimensioner avvisas", skal ~= nil, skal)
end

print("\n── 3. Jämförelsen ÄR den befintliga regeln ──")
local fokusSett, sortSett = {}, {}
for _, payload in riktiga do
	local rent = P.validera(payload)
	local fokus, kort = P.ugneta(rent)
	local obs = Ugneta.observationer(payload.ovningId, payload.nu, payload.fore)
	local lika = #kort == #obs
	local vantat = P.INGEN
	for i, o in obs do
		if not kort[i] or kort[i].dim ~= o.dim or kort[i].sort ~= o.sort then lika = false end
		if vantat == P.INGEN and (o.sort == "forbattra" or o.sort == "kvar") then vantat = o.dim end
	end
	prova(("%s försök %d: kortet = Ugneta.observationer"):format(payload.ovningId, payload.forsokNr), lika)
	prova(("%s försök %d: fokus = första forbattra/kvar"):format(payload.ovningId, payload.forsokNr),
		fokus == vantat, fokus)
	fokusSett[fokus] = true
	sortSett[kort[1] and kort[#kort].sort or "-"] = true
end
prova("de riktiga försöken täcker grenarna forbattra, kvar och ingen",
	sortSett.forbattra and sortSett.kvar and fokusSett[P.INGEN] == true)
do
	-- Bara beröm → ingen.
	local rent = P.validera({ ovningId = "storvolt", forsokNr = 2,
		nu = { linje = 0.95, balans = 0.95 }, fore = { linje = 0.80, balans = 0.95 } })
	local fokus, kort = P.ugneta(rent)
	prova("bara en förbättring och inget svagt kvar → fokus ingen",
		fokus == P.INGEN and #kort == 1 and kort[1].sort == "battre", fokus)
end

print("\n── 4. Jevs tillåtna svar ──")
local et = P.etiketter("storvolt")
prova("storvolt: linje, balans, ingen — inte rytm",
	table.concat(et, ",") == "linje,balans,ingen", table.concat(et, ","))
prova("halt_skritt: timing, mjukhet, respons, ingen",
	table.concat(P.etiketter("halt_skritt"), ",") == "timing,mjukhet,respons,ingen")
local function svar(choice, conf)
	return { model = "jev-1.13.0", answers = { focus = { type = "choice", choice = choice, confidence = conf } } }
end
local t, s = P.tolka(svar("linje", 0.8), "storvolt")
prova("ett tillåtet svar läses", t ~= nil and t.fokus == "linje" and t.confidence == 0.8
	and t.model == "jev-1.13.0", s)
prova("ingen är tillåtet", P.tolka(svar("ingen", 0.5), "storvolt") ~= nil)
local fulaSvar = {
	{ "okänd etikett", svar("line", 0.9) },
	{ "fel skiftläge", svar("Linje", 0.9) },
	{ "dimension ur annan övning", svar("mjukhet", 0.9) },
	{ "rytm i volten", svar("rytm", 0.9) },
	{ "confidence NaN", svar("linje", 0 / 0) },
	{ "confidence saknas", svar("linje", nil) },
	{ "confidence negativ", svar("linje", -0.1) },
	{ "confidence över 1", svar("linje", 1.2) },
	{ "confidence sträng", svar("linje", "0.9") },
	{ "choice som tal", svar(1, 0.9) },
	{ "inga answers", { model = "x" } },
	{ "inte en tabell", "linje" },
}
for _, fall in fulaSvar do
	local ok, skal = P.tolka(fall[2], "storvolt")
	prova(("avvisas: %s"):format(fall[1]), ok == nil and skal ~= nil, skal)
end

print("\n── 5. Förfrågan bär bara det validerade ──")
local function json(v, ut)
	ut = ut or {}
	local typ = type(v)
	if typ == "table" then
		local nycklar = {}
		for k in v do table.insert(nycklar, tostring(k)) end
		table.sort(nycklar)
		table.insert(ut, "{")
		for _, k in nycklar do
			table.insert(ut, '"' .. k .. '":')
			json(v[k] == nil and v[tonumber(k)] or v[k], ut)
			table.insert(ut, ",")
		end
		table.insert(ut, "}")
	else
		table.insert(ut, tostring(v))
	end
	return table.concat(ut)
end
do
	local smutsig = { ovningId = "storvolt", forsokNr = 1, nu = { linje = 0.6 } }
	local rent = P.validera(smutsig)
	local k = P.kropp(rent)
	local topp = {}
	for n in k do table.insert(topp, n) end
	table.sort(topp)
	prova("toppnivån är exakt model, questions, state", table.concat(topp, ",") == "model,questions,state",
		table.concat(topp, ","))
	local st = {}
	for n in k.state do table.insert(st, n) end
	table.sort(st)
	prova("state är exakt dimensioner, forsok, nu, ovning, saknas (fore saknas här)",
		table.concat(st, ",") == "dimensioner,forsok,nu,ovning,saknas", table.concat(st, ","))
	prova("saknas-listan är uttrycklig", table.concat(k.state.saknas, ",") == "rytm,rein_pressure,rider_body,free_text")
	prova("frågan har exakt de tillåtna etiketterna som kriterier",
		k.questions.focus.criteria.linje ~= nil and k.questions.focus.criteria.balans ~= nil
			and k.questions.focus.criteria.ingen ~= nil and k.questions.focus.criteria.rytm == nil)
	prova("nu är en kopia, inte klientens tabell", k.state.nu ~= smutsig.nu and k.state.nu.linje == 0.6)
	-- Ett underlag som bär identitet når aldrig kroppen: det avvisas redan.
	local medId = { ovningId = "storvolt", forsokNr = 1, nu = { linje = 0.6 },
		userId = 4242, Name = "Tobias", DisplayName = "T" }
	prova("identitet i underlaget → avvisas, ingen kropp byggs", P.validera(medId) == nil)
	local text = json(k)
	for _, forbjudet in { "userId", "Name", "DisplayName", "4242", "Tobias" } do
		prova(("kroppen innehåller inte %q"):format(forbjudet),
			string.find(text, forbjudet, 1, true) == nil)
	end
end

if fel > 0 then
	print(("%d mätning(ar) föll."):format(fel))
else
	print("jevskugga-policy: alla gröna")
end
