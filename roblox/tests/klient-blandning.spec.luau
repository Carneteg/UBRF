--!nostrict
--[[ UI-2 + UI-3 — docs/P2-UGNETA-INSTRUCTION-CONTRACT.md §§ 1–3, 5.

	Ugneta instruerar, spelaren handlar, och EN språk syns åt gången.
	Specen kör `init.client.luau` på riktigt (KLIENT-bänken), matar serverns
	vy genom `PreparationController.tillampa` byggd av den riktiga
	`Preparation`, och läser ALLT synligt i komponenten:

	  · Ugnetas dockade yta (`UgnetaController._larare`): titel, flagga,
	    instruktion,
	  · panelen (`Naromrade._panel` / `_rader`): rubrik, instruktion,
	    återkoppling, hjälp, val och promptrader.

	Hela kedjan till fots går två varv: på svenska, och på engelska efter
	att Ugnetas EGEN flagga vänts (samma väg som spelarens tryck). Varje
	synlig sträng prövas mot andra språket:

	  · svenska läge: ingen engelsk katalogtext och inga engelska
	    funktionsord,
	  · engelska läge: inga å/ä/ö, ingen svensk katalogtext och inga
	    svenska funktionsord.

	Hästens egennamn undantas. VAD BÄNKEN INTE KAN: hur rutan SER UT och
	om den ryms på en riktig iPad — det står på Tobias lista. ]]
local fel, total = 0, 0
local function prova(vad, ok, detalj)
	total += 1
	if not ok then fel += 1 end
	print((if ok then "  OK   " else "  FEL  ") .. vad .. (if detalj then "  " .. tostring(detalj) else ""))
end
local Players = game:GetService("Players")
local Taggar = game:GetService("CollectionService")
local RSt = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local Net = Networking
local PC = PreparationController
local IC = InteractionController
local N = Naromrade
local U = UgnetaController
Sprak.satLocale("sv-se")

RunService._server = true
Net.get("MountRequest"); Net.get("LedBorja"); Net.get("LedSlapp"); Net.get("LedSync")
Net.get("RidaNu").OnServerInvoke = function() return true end
Net.get("SprakVal").OnServerInvoke = function(_, val) return true, val end
RunService._server = false
RSt:SetAttribute("G01Enabled", true)

local HAST_ID, HAST_NAMN = "trixie", "Trixie"
local hast = __makeHastModell(HAST_NAMN)
hast:SetAttribute("HorseId", HAST_ID)
hast:SetAttribute("HorseName", HAST_NAMN)
hast.Parent = workspace
Taggar:AddTag(hast, "Horse")
local hastRot = hast:FindFirstChild("HumanoidRootPart")
local karaktar = Instance.new("Model"); karaktar.Name = "Spelare"
local kropp = Instance.new("Part"); kropp.Name = "HumanoidRootPart"; kropp.Size = Vector3.new(2, 2, 1)
kropp.CFrame = CFrame.new(hastRot.CFrame.Position)
kropp.Parent = karaktar
karaktar.Parent = workspace
player.Character = karaktar

local rev = 0
local state
local function visa(status, buren)
	rev += 1
	PC.tillampa(Preparation.vy(state, status, rev, HAST_NAMN, buren))
	PC.uppdateraKontext()
	IC.uppdatera()
	N.satRider(false)
end
local function bar(...) return { hastId = HAST_ID, hastnamn = HAST_NAMN, delar = { ... } } end
local function gorFas(fasId)
	while true do
		local m = Preparation.nastaMoment(state, fasId)
		if not m then break end
		if not Preparation.utforMoment(state, fasId, m.id, HAST_ID) then break end
	end
end
local function gorMoment(fasId, prefix)
	while true do
		local m = Preparation.nastaMoment(state, fasId)
		if not m or string.sub(m.id, 1, #prefix) ~= prefix then break end
		if not Preparation.utforMoment(state, fasId, m.id, HAST_ID) then break end
	end
end
local function valMed(id)
	for _, v in ipairs(N._val()) do if v.id == id then return v end end
	return nil
end

--[[ ── DETEKTORERNA ─────────────────────────────────────────────────── ]]
-- Katalogtext som skiljer sig mellan språken, i bitar runt platshållarna.
local function bitar(t)
	local ut = {}
	for b in string.gmatch(t, "[^%%]+") do
		b = string.gsub(b, "^[sd]", "")
		b = string.gsub(b, "^%s+", ""); b = string.gsub(b, "%s+$", "")
		if #b >= 8 then table.insert(ut, b) end
	end
	return ut
end
local BARA = { sv = {}, en = {} }
for _, k in ipairs(Sprak.nycklar()) do
	local sv, en = Sprak.iSprak("sv", k), Sprak.iSprak("en", k)
	if type(sv) == "string" and type(en) == "string" and sv ~= en then
		for _, b in ipairs(bitar(sv)) do if not string.find(en, b, 1, true) then table.insert(BARA.sv, b) end end
		for _, b in ipairs(bitar(en)) do if not string.find(sv, b, 1, true) then table.insert(BARA.en, b) end end
	end
end
local ORD = {
	sv = { "och", "inte", "med", "till", "hennes", "hon", "din", "sidan", "fram", "att", "eller", "sedan", "innan" },
	en = { "the", "your", "you", "and", "with", "her", "from", "she", "now", "get", "ready", "myself", "put", "say",
		"walk", "greet", "check", "lead", "never", "before" },
}
local EGENNAMN = { HAST_NAMN }
local function utanNamn(t)
	for _, n in ipairs(EGENNAMN) do t = string.gsub(t, n, " ") end
	return t
end
local function harOrd(t, lista)
	local s = " " .. string.lower(t) .. " "
	for _, o in ipairs(lista) do
		-- Ordgränsen räknar UTF-8-byte (å/ä/ö) som bokstav: annars blev
		-- «get» i «Sadelläget» ett eget ord.
		if string.find(s, "%f[%a\128-\255]" .. o .. "%f[^%a\128-\255]") then return o end
	end
	return nil
end
local function annatSprak(text, lage)
	local t = utanNamn(text)
	if lage == "en" then
		for _, c in ipairs({ "å", "ä", "ö", "Å", "Ä", "Ö" }) do
			if string.find(t, c, 1, true) then return "svensk bokstav " .. c end
		end
		for _, b in ipairs(BARA.sv) do if string.find(t, b, 1, true) then return "svensk katalogtext «" .. b .. "»" end end
		local o = harOrd(t, ORD.sv)
		if o then return "svenskt ord «" .. o .. "»" end
	else
		for _, b in ipairs(BARA.en) do if string.find(t, b, 1, true) then return "engelsk katalogtext «" .. b .. "»" end end
		local o = harOrd(t, ORD.en)
		if o then return "engelskt ord «" .. o .. "»" end
	end
	return nil
end

--[[ Allt synligt i komponenten just nu, med var det står. ]]
local function synligt()
	local ut = {}
	local p = N._panel()
	local l = U._larare()
	if l.synlig then
		table.insert(ut, { "ugneta.titel", l.titel })
		table.insert(ut, { "ugneta.flagga", l.flagga })
		if l.text ~= "" then table.insert(ut, { "ugneta.text", l.text }) end
	end
	for _, f in ipairs({ "rubrik", "steg", "ater", "hjalp" }) do
		if type(p[f]) == "string" and p[f] ~= "" then table.insert(ut, { "panel." .. f, p[f] }) end
	end
	for i, r in ipairs(N._rader()) do table.insert(ut, { "rad" .. i, r }) end
	return ut
end
local blandat = { sv = {}, en = {} }
local sedda = { sv = 0, en = 0 }
local function granska(vad, lage)
	for _, post in ipairs(synligt()) do
		sedda[lage] += 1
		local varfor = annatSprak(post[2], lage)
		if varfor then table.insert(blandat[lage], ("%s · %s: «%s» (%s)"):format(vad, post[1], post[2], varfor)) end
	end
end

--[[ ── EN KEDJA TILL FOTS ────────────────────────────────────────────── ]]
local function kedja(lage)
	state = Preparation.nyState(HAST_ID, 1)
	visa("preparing")
	granska("startvalet", lage)
	-- «Själv» minns tills hästen varit redo; första varvet kommer efter avsnitt 2.
	local sj = valMed("start:sjalv")
	if sj then sj.skicka() end
	N.satRider(false)
	granska("hälsningen", lage)
	for _ = 1, 3 do
		local m = Preparation.nastaMoment(state, "halsa")
		if not m then break end
		Preparation.utforMoment(state, "halsa", m.id, HAST_ID)
		visa("preparing")
		granska("hälsningen efter " .. m.id, lage)
	end
	gorFas("halsa"); visa("preparing"); granska("visitera", lage)
	gorFas("visitera"); visa("preparing"); granska("rykta", lage)
	gorFas("rykta"); visa("preparing"); granska("hovarna", lage)
	gorMoment("iordning", "hov:"); visa("preparing"); granska("hämta sadeln", lage)
	visa("preparing", bar("sadel")); granska("hämta tränset", lage)
	visa("preparing", bar("sadel", "trans")); granska("sadla", lage)
	while Preparation.nastaMoment(state, "iordning") and Preparation.nastaMoment(state, "iordning").id ~= "utr:5" do
		local m = Preparation.nastaMoment(state, "iordning")
		if not Preparation.utforMoment(state, "iordning", m.id, HAST_ID) then break end
	end
	visa("preparing", bar("trans")); granska("tränsa", lage)
	gorFas("iordning"); visa("preparing"); granska("leda", lage)
	gorFas("leda"); visa("ready_to_mount"); granska("sitt upp", lage)
end

print("\nUGNETA INSTRUERAR · ETT SPRÅK (UI-2/UI-3)\n")

print("── 1. Ugnetas yta är panelens första block ──")
state = Preparation.nyState(HAST_ID, 1)
visa("preparing")
do
	local l, p = U._larare(), N._panel()
	prova("ytan är dockad i panelen", l.dockad and l.ram ~= nil and p.ram ~= nil and l.ram.Parent == p.ram,
		tostring(l.ram and l.ram.Parent and l.ram.Parent.Name))
	prova("den ligger FÖRST (LayoutOrder 0, före rubrikraden)", l.ram and l.ram.LayoutOrder == 0)
	prova("titeln är «Ugneta · Ridinstruktör»", l.titel == Sprak.t("ugneta.titel"), l.titel)
end

print("\n── 2. Hälsningen: Ugneta instruerar, handlingarna i ordning ──")
valMed("start:sjalv").skicka()
N.satRider(false)
do
	local p = N._panel()
	local m1 = Preparation.nastaMoment(state, "halsa")
	local vals = N._val()
	prova("rubriken är «Hälsa på Trixie»", p.rubrik == Sprak.t("guide.halsa_rubrik", HAST_NAMN), p.rubrik)
	prova("instruktionen är den första handlingens, i UGNETAS yta (inte två gånger)",
		p.stegHos == "ugneta" and p.steg == m1.text, tostring(p.stegHos) .. " | " .. tostring(p.steg))
	prova("tre handlingar, ingen är ett felaktigt svar", #vals == 3 and not vals[1].fel and not vals[2].fel and not vals[3].fel,
		#vals)
	prova("bara den första står på tur", vals[1] and vals[1].paTur and not vals[2].paTur and not vals[3].paTur)
	local ok, skal = Preparation.provaMoment(state, "halsa", "halsa3", HAST_ID)
	prova("handen innan namnet nekas med «fel tur»", ok == false and skal == "forb.fel_tur", tostring(skal))
	prova("hälsningen är en checklista, inte ett val", Preparation.arVal("halsa") == false)
	local en = Preparation.momentPaSprak(m1, "en", HAST_NAMN)
	prova("kvittensen följer språket", en.kvittens == "There she can see you coming." and m1.kvittens == "Där ser hon dig komma.",
		tostring(en.kvittens))
end

print("\n── 3. Hela kedjan på svenska ──")
kedja("sv")
prova(("svenska: inget engelskt i %d synliga texter"):format(sedda.sv), #blandat.sv == 0 and sedda.sv > 40,
	table.concat(blandat.sv, " ‖ "))

print("\n── 4. Ugnetas flagga byter språk, hela kedjan på engelska ──")
U._vaxlaSprak()
prova("flaggan visar nu «English»", U._larare().flagga == "English" and Sprak.eget() == "en", U._larare().flagga)
kedja("en")
prova(("engelska: inget svenskt i %d synliga texter"):format(sedda.en), #blandat.en == 0 and sedda.en > 40,
	table.concat(blandat.en, " ‖ "))
U._vaxlaSprak()
prova("flaggan tillbaka: «Svenska»", U._larare().flagga == "Svenska" and Sprak.eget() == "sv", U._larare().flagga)

print("\n── 5. Detektorn själv: en blandad sträng fastnar ──")
prova("svenska läget fångar en engelsk handling", annatSprak("Walk up from the side, at her shoulder", "sv") ~= nil)
prova("engelska läget fångar en svensk handling", annatSprak("Gå fram från sidan vid bogen", "en") ~= nil)
prova("engelska läget fångar svenska utan omljud", annatSprak("Kolla ben och hovar innan du rider", "en") ~= nil)
prova("hästens namn fälls inte", annatSprak("Greet Trixie", "en") == nil and annatSprak("Hälsa på Trixie", "sv") == nil)

print("")
if fel > 0 then
	error(("%d mätning(ar) föll."):format(fel), 0)
end
print(("klient-blandning.spec: %d prov, alla gröna"):format(total))
