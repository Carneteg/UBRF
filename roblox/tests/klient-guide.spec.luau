--!nostrict
--[[ ONBOARDINGENS STEGKORT — docs/ONBOARDING-STEP-CARD-CONTRACT.md (Tobias C: två vägar).

	Tobias i Play (2026-09-28): rutan till vänster sa fasens namn, inte vad
	han skulle göra härnäst. Nu säger samma ruta ETT steg i taget, härlett ur
	spelets läge. Specen kör `init.client.luau` på riktigt (KLIENT-bänken),
	matar SERVERNS vy genom `PreparationController.tillampa` byggd av den
	riktiga `Preparation`, och läser panelen genom `Naromrade._panel()`.

	VAD BÄNKEN INTE KAN: om texterna är TYDLIGA för ett öga, och hur de ryms
	på en telefon. Det står på Tobias checklista. ]]
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
Sprak.satLocale("sv-se")

RunService._server = true
Net.get("MountRequest"); Net.get("LedBorja"); Net.get("LedSlapp"); Net.get("LedSync")
local ridaNuAnrop = 0
Net.get("RidaNu").OnServerInvoke = function() ridaNuAnrop += 1; return true end
RunService._server = false
RSt:SetAttribute("G01Enabled", true)

local HAST_ID = "trixie"
local hast = __makeHastModell("Trixie")
hast:SetAttribute("HorseId", HAST_ID)
hast:SetAttribute("HorseName", "Trixie")
hast.Parent = workspace
Taggar:AddTag(hast, "Horse")
local hastRot = hast:FindFirstChild("HumanoidRootPart")

local karaktar = Instance.new("Model"); karaktar.Name = "Spelare"
local kropp = Instance.new("Part"); kropp.Name = "HumanoidRootPart"; kropp.Size = Vector3.new(2, 2, 1)
kropp.CFrame = CFrame.new(hastRot.CFrame.Position)
kropp.Parent = karaktar
karaktar.Parent = workspace
player.Character = karaktar
local vidHasten = hastRot.CFrame.Position
local langtBort = vidHasten + Vector3.new(80, 0, 0)

-- En stalldörr vid «spawn» (långt från hästen), stängd.
local dorrDel = Instance.new("Part"); dorrDel.Name = "Dorrblad"; dorrDel.CFrame = CFrame.new(langtBort + Vector3.new(0, 0, 3))
dorrDel:SetAttribute("UBRFDorr", "stall N dorrgul")
dorrDel.Parent = workspace
local dorr = Instance.new("ProximityPrompt"); dorr.Name = "DorrPrompt"; dorr.ActionText = "Öppna"; dorr.ObjectText = "Dörr"
dorr:SetAttribute("SprakNyckel", "dorr.oppna")
dorr.MaxActivationDistance = 10
dorr.Parent = dorrDel

local rev = 0
local state = Preparation.nyState(HAST_ID, 1)
local function visa(status, buren)
	rev += 1
	PC.tillampa(Preparation.vy(state, status, rev, "Trixie", buren))
	PC.uppdateraKontext()
	IC.uppdatera()
	N.satRider(false)
end
local function bar(...)
	return { hastId = HAST_ID, hastnamn = "Trixie", delar = { ... } }
end
local function gorFas(fasId)
	while true do
		local m = Preparation.nastaMoment(state, fasId)
		if not m then break end
		if not Preparation.utforMoment(state, fasId, m.id, HAST_ID) then break end
	end
end
local function gorMoment(fasId, prefix)
	-- Utför moment i fasen så länge nästa börjar med `prefix`.
	while true do
		local m = Preparation.nastaMoment(state, fasId)
		if not m or string.sub(m.id, 1, #prefix) ~= prefix then break end
		if not Preparation.utforMoment(state, fasId, m.id, HAST_ID) then break end
	end
end
local function flytta(pos) kropp.CFrame = CFrame.new(pos) end
local function rubrik() return N._panel().rubrik end
local function steg() return N._panel().steg end
local function borjar(t, x) return type(t) == "string" and string.sub(t, 1, #x) == x end
local function har(t, x) return type(t) == "string" and string.find(t, x, 1, true) ~= nil end

print("\nONBOARDINGENS STEGKORT\n")

print("── 1. Från spawn: dörren, sedan hästen ──")
flytta(langtBort)
visa("preparing")
prova("stängd dörr inom räckhåll, hästen långt bort: «Öppna stalldörren»",
	rubrik() == Sprak.t("guide.dorr_rubrik", "Trixie") and har(steg(), "gyllene pilen"), rubrik() .. " | " .. steg())
dorr:SetAttribute("SprakNyckel", "dorr.stang")
visa("preparing")
prova("dörren öppen: «Gå till Trixie» + följ pilen",
	rubrik() == Sprak.t("guide.ga_till_rubrik", "Trixie") and steg() == Sprak.t("guide.ga_till_text"), rubrik() .. " | " .. steg())
prova("åtgärdsraderna finns kvar (panelen visar dörren)", #N._rader() >= 1, #N._rader())

print("\n── 2. Vid hästen, inget gjort: STARTSKÄRMEN med en enda väg (UI-1) ──")
flytta(vidHasten)
visa("preparing")
local function valTexter()
	local ut = {}
	for _, v in ipairs(N._val()) do table.insert(ut, tostring(v.text)) end
	return ut
end
local function valMed(id)
	for _, v in ipairs(N._val()) do if v.id == id then return v end end
	return nil
end
prova("«Dags att rida» med den korta instruktionen (ingen hälsningsfråga)",
	rubrik() == Sprak.t("guide.valj_rubrik", "Trixie") and steg() == Sprak.t("guide.valj_kort", "Trixie", "Trixie"), steg())
local vt = valTexter()
prova("exakt ett val: «Rida nu — Trixie», inget «Gör i ordning själv»", #vt == 1
	and vt[1] == Sprak.t("guide.val_rida_nu", "Trixie") and valMed("start:sjalv") == nil, table.concat(vt, " / "))
-- `_rader()` är ALLT synligt i skärmordning (valen först, sedan promptraderna).
local synligt = N._rader()
prova("inga promptrader och inget «Fler»: det synliga är exakt det enda valet", #synligt == 1
	and synligt[1] == vt[1], table.concat(synligt, " / "))
local harHalsning = false
for _, v in ipairs(N._val()) do if v.fel ~= nil then harHalsning = true end end
prova("inga hälsningssvar på startskärmen", not harHalsning)

-- #274: hästen står bakom STÄNGD box och spelaren är vid den: dörren syns på startvägen.
dorrDel.CFrame = CFrame.new(vidHasten + Vector3.new(0, 0, 3)) -- boxdörren vid hästen
dorr:SetAttribute("SprakNyckel", "dorr.oppna")
visa("preparing")
local vt2 = valTexter()
prova("stängd box vid hästen: det enda valet finns kvar", #vt2 == 1 and vt2[1] == Sprak.t("guide.val_rida_nu", "Trixie"), table.concat(vt2, " / "))
local syn2 = N._rader()
prova("stängd box vid hästen: «Öppna dörren» är en synlig rad under valen", #syn2 == 2 and string.find(syn2[2], "Dörr", 1, true) ~= nil, table.concat(syn2, " / "))
dorr:SetAttribute("SprakNyckel", "dorr.stang")
visa("preparing")
prova("öppen box vid hästen: åter exakt ett val, ingen dörrrad", #N._rader() == 1, #N._rader())
dorrDel.CFrame = CFrame.new(langtBort + Vector3.new(0, 0, 3))
visa("preparing")

print("\n── 4. «Rida nu»-vägen: knappen på startskärmen, sedan «Sitt upp» ──")
state = Preparation.nyState(HAST_ID, 2)
visa("preparing")
prova("ny dag (efter att hästen varit redo): startskärmen igen", rubrik() == Sprak.t("guide.valj_rubrik", "Trixie")
	and valMed("start:rida_nu") ~= nil, rubrik())
local fore = ridaNuAnrop
valMed("start:rida_nu").skicka()
prova("«Rida nu — Trixie» anropar serverns RidaNu genom InteractionController.ridaNu", ridaNuAnrop == fore + 1,
	("%d → %d"):format(fore, ridaNuAnrop))
local okA = Preparation.autoForbered(state)
visa("ready_to_mount")
prova("efter «Rida nu» (stallet förberett): «Sitt upp på Trixie»", okA ~= false and rubrik() == Sprak.t("guide.sittupp_rubrik", "Trixie"),
	rubrik())

print("\n── 5. Oförändrat: stegkortet kliver inte in ──")
local G = { status = "preparing", nasta = "halsa", nastaMoment = "halsa1", redo = false, klaraFaser = 0, buren = {}, utomRackhall = false }
local function med(over) local g = table.clone(G); for k, v in pairs(over) do g[k] = v end; return g end
prova("en rättelse (annan hästs utrustning): nil", N._guideFor(med({ rattelse = true }), "skotsel:halsa", "x", "Trixie", false) == nil)
prova("välfärdsstopp: nil", N._guideFor(med({ status = "welfare_stop" }), "skotsel", "x", "Trixie", false) == nil)
prova("väntar på modellen: nil", N._guideFor(med({ status = "waiting_model" }), "vantar", "x", "Trixie", false) == nil)
prova("ritten: nil", N._guideFor(med({ status = "riding" }), "rider", "", "Trixie", false) == nil)
prova("eftervården och räknat pass: nil", N._guideFor(med({}), "eftervard", "x", "Trixie", false) == nil
	and N._guideFor(med({}), "raknat", "x", "Trixie", false) == nil)
prova("hästen långt bort och dörren STÄNGD: dörren; ÖPPEN: gå till",
	N._guideFor(med({ utomRackhall = true }), "skotsel", "", "Trixie", true).rubrik == Sprak.t("guide.dorr_rubrik", "Trixie")
	and N._guideFor(med({ utomRackhall = true }), "skotsel", "", "Trixie", false).rubrik == Sprak.t("guide.ga_till_rubrik", "Trixie"))
prova("engelska: «Time to ride»/stallet gör henne redo; efter valet «Greet Trixie» + frågan", (function()
	Sprak.satLocale("en-us")
	local k = N._guideFor(med({}), "skotsel:halsa", "Walk up from the side.", "Trixie", false, false)
	local h = N._guideFor(med({}), "skotsel:halsa", "Walk up from the side.", "Trixie", false, true)
	local r, sj = Sprak.t("guide.val_rida_nu", "Trixie"), Sprak.t("guide.val_sjalv", "Trixie")
	Sprak.satLocale("sv-se")
	return k and k.rubrik == "Time to ride" and har(k.text, "the stable gets Trixie ready") and not har(k.text, "Walk up")
		and h and h.rubrik == "Greet Trixie" and h.text == "Walk up from the side."
		and r == "Ride now — Trixie" and sj == "Get Trixie ready myself"
end)())
prova("en öppen välfärdsfråga (stallets fynd) går före: ingen guide", N._guideFor(med({ fynd = true }), "fynd", "x", "Trixie", false) == nil
	and N._guideFor(med({}), "fynd", "x", "Trixie", false) == nil)

print("\n── 6. «Rida nu» finns även när hästen strömmar in EFTER vyn ──")
do
	local function ridaNu(modell)
		for _, d in ipairs(modell:GetDescendants()) do
			if d.Name == "RidaNuPrompt" then return d end
		end
		return nil
	end
	-- En ny tilldelning till en häst vars modell ännu inte finns.
	local st2 = Preparation.nyState("cosmo", 1)
	rev += 1
	PC.tillampa(Preparation.vy(st2, "preparing", rev, "Cosmo", nil))
	IC.uppdatera()
	local cosmo = __makeHastModell("Cosmo")
	cosmo:SetAttribute("HorseId", "cosmo")
	cosmo:SetAttribute("HorseName", "Cosmo")
	cosmo.Parent = workspace
	Taggar:AddTag(cosmo, "Horse")
	for _ = 1, 40 do RunService.Heartbeat:Fire(1 / 30) end
	prova("inom en sekund finns «Rida nu» på den nyss inströmmade hästen", ridaNu(cosmo) ~= nil)
end

print("\n── 7. En ny dag med stallets FYND: välfärdsfrågan, aldrig startskärmen ──")
do
	-- Hästen var redo i avsnitt 4, så valet «själv» är nollställt: utan fyndspärren hade startskärmen tagit över.
	state = Preparation.nyState(HAST_ID, 3)
	rev += 1
	local vy = Preparation.vy(state, "preparing", rev, "Trixie")
	vy.svar = { { id = "fel1", namn = "Det går nog bra idag", fel = true }, { id = "ratt", namn = "Säg till en vuxen", fel = false } }
	vy.fynd = "Något i hoven"
	PC.tillampa(vy)
	PC.uppdateraKontext()
	N.satRider(false)
	local texter = {}
	for _, v in ipairs(N._val()) do table.insert(texter, tostring(v.text)) end
	prova("fyndets svar står i panelen, inte «Rida nu»/«själv»", valMed("start:rida_nu") == nil and valMed("start:sjalv") == nil
		and #texter >= 2, table.concat(texter, " / "))
	prova("rubriken är inte startskärmens", rubrik() ~= Sprak.t("guide.valj_rubrik", "Trixie"), rubrik())
end

print("\n── 8. #292: efter ett RÄKNAT pass finns «Rida nu», och «Sitt upp» viker ──")
do
	local function promptar()
		local ut = {}
		for _, d in ipairs(hast:GetDescendants()) do
			if d.Name == "MountPrompt" or d.Name == "RidaNuPrompt" or d.Name == "LedPrompt" then
				ut[d.Name] = d
			end
		end
		return ut
	end
	local function passVy(pass)
		rev += 1
		PC.tillampaPass(Pass.vy(pass, 5000 + rev))
		IC.uppdatera()
	end
	flytta(vidHasten)

	-- A. Ny, ofärdig förberedelse: «Rida nu» som förut.
	state = Preparation.nyState(HAST_ID, 5)
	visa("preparing")
	local passA = Pass.nyState(HAST_ID, Pass.byggId(1, HAST_ID, 5))
	passVy(passA)
	prova("A. ny förberedelse (before_ride): «Rida nu» finns och «Sitt upp» inte",
		promptar().RidaNuPrompt ~= nil and promptar().MountPrompt == nil)
	prova("A. och startkortet har «Rida nu»", valMed("start:rida_nu") ~= nil)

	-- B. Förberedd före ritt: «Sitt upp», inte «Rida nu».
	for _, f in ipairs(Preparation.stegFaser()) do gorFas(f.id) end
	visa("ready_to_mount")
	prova("B. förberett pass i before_ride: «Sitt upp» syns, «Rida nu» döljs",
		promptar().MountPrompt ~= nil and promptar().RidaNuPrompt == nil,
		("Mount %s · Rida nu %s"):format(tostring(promptar().MountPrompt ~= nil), tostring(promptar().RidaNuPrompt ~= nil)))

	-- C. Eftervård: varken upprepad «Rida nu» eller en vilseledande «Sitt upp».
	Pass.vidUppsittning(passA)
	Pass.vidAvsittning(passA)
	passVy(passA)
	visa("ready_to_mount")
	prova("C. eftervård (aftercare): ingen «Rida nu» och ingen «Sitt upp» tar fokus",
		promptar().RidaNuPrompt == nil and promptar().MountPrompt == nil and valMed("start:rida_nu") == nil,
		("Mount %s · Rida nu %s"):format(tostring(promptar().MountPrompt ~= nil), tostring(promptar().RidaNuPrompt ~= nil)))

	-- D. Räknat pass: «Rida nu» syns, «Sitt upp» är borta.
	while true do
		local m = Pass.nastaMoment(passA)
		if not m then break end
		Pass.utfor(passA, m.id, "auto")
	end
	Pass.markeraRaknat(passA)
	passVy(passA)
	visa("ready_to_mount")
	prova("D. förutsättning: passet är recorded och förberedelsen står kvar komplett",
		PC.passLage() == "recorded" and PC.redo() == true and PC.nastaFas() == nil,
		("lage %s · redo %s · fas %s"):format(tostring(PC.passLage()), tostring(PC.redo()), tostring(PC.nastaFas())))
	prova("D. recorded: «Rida nu» syns på hästen och «Sitt upp» är borta",
		promptar().RidaNuPrompt ~= nil and promptar().MountPrompt == nil,
		("Mount %s · Rida nu %s"):format(tostring(promptar().MountPrompt ~= nil), tostring(promptar().RidaNuPrompt ~= nil)))
	prova("D. startkortet bär samma enda «Rida nu»", valMed("start:rida_nu") ~= nil and #N._val() == 1, #N._val())
	local fore = ridaNuAnrop
	valMed("start:rida_nu").skicka()
	prova("D. kortet kör den befintliga «Rida nu» (InteractionController.ridaNu → servern)",
		ridaNuAnrop == fore + 1, ("%d → %d"):format(fore, ridaNuAnrop))
	prova("D. ingen skötsel eller ledning kommer tillbaka", promptar().LedPrompt == nil
		and valMed("start:sjalv") == nil)

	-- D2. Avståndet: startkortet efter recorded gäller bara «vid hästen».
	flytta(langtBort)
	visa("ready_to_mount")
	passVy(passA)
	prova("D2. recorded + UTOM räckhåll: inget aktivt «Rida nu»-startkort",
		valMed("start:rida_nu") == nil and N._panel().rubrik ~= Sprak.t("guide.valj_rubrik", "Trixie"),
		tostring(N._panel().rubrik))
	flytta(vidHasten)
	visa("ready_to_mount")
	passVy(passA)
	prova("D2. tillbaka vid hästen: exakt ett «Rida nu»-startkort igen",
		valMed("start:rida_nu") ~= nil and #N._val() == 1, #N._val())

	-- E. Servern svarar med ett nytt pass i before_ride: tillståndet byter igen.
	state = Preparation.nyState(HAST_ID, 6)
	visa("preparing")
	local passE = Pass.nyState(HAST_ID, Pass.byggId(1, HAST_ID, 6))
	passVy(passE)
	prova("E. nytt pass (before_ride) efter synk: «Rida nu» som i A, ingen «Sitt upp»",
		PC.passLage() == "before_ride" and promptar().RidaNuPrompt ~= nil and promptar().MountPrompt == nil)

	-- F. Fel häst och välfärdsfokus släcker «Rida nu» även vid recorded.
	local passF = Pass.nyState(HAST_ID, Pass.byggId(1, HAST_ID, 7))
	Pass.vidUppsittning(passF); Pass.vidAvsittning(passF)
	while true do
		local m = Pass.nastaMoment(passF)
		if not m then break end
		Pass.utfor(passF, m.id, "auto")
	end
	Pass.markeraRaknat(passF)
	state = Preparation.nyState(HAST_ID, 7)
	for _, f in ipairs(Preparation.stegFaser()) do gorFas(f.id) end
	visa("ready_to_mount")
	passVy(passF)
	hast:SetAttribute("HorseId", "annan_hast")
	IC.uppdatera()
	prova("F. fel häst: ingen «Rida nu» trots recorded", promptar().RidaNuPrompt == nil)
	hast:SetAttribute("HorseId", HAST_ID)
	state.stoppad = "skada"
	visa("welfare_stop")
	passVy(passF)
	prova("F. välfärdsstopp: ingen «Rida nu» trots recorded", promptar().RidaNuPrompt == nil
		and valMed("start:rida_nu") == nil)
	state.stoppad = nil
end

print("\n── 9. #297: förstagångsspelaren — en tydlig väg, utan skötsel och ledning ──")
do
	-- Prompterna finns på hästen även när panelen tar över (då är de avstängda och raden är handlingen).
	local function prompter(namn)
		local ut = {}
		for _, d in ipairs(hast:GetDescendants()) do
			if d:IsA("ProximityPrompt") and d.Name == namn then table.insert(ut, d) end
		end
		return ut
	end
	local FORBJUDET = { "start:sjalv", "handling:", "utr:", "leda", "hov:", "rykta", "visitera", "halsa" }
	local function forbjudetVal()
		local traffar = {}
		for _, v in ipairs(N._val()) do
			for _, p in ipairs(FORBJUDET) do
				if string.sub(tostring(v.id), 1, #p) == p then table.insert(traffar, tostring(v.id)) end
			end
		end
		return table.concat(traffar, ",")
	end
	state = Preparation.nyState(HAST_ID, 2)
	flytta(vidHasten)
	visa("preparing")
	-- Ett NYTT pass i before_ride: sektion 8 lämnade ett räknat pass, och det är inte förstagångsspelarens läge.
	rev += 1
	PC.tillampaPass(Pass.vy(Pass.nyState(HAST_ID, Pass.byggId(1, HAST_ID, 2)), 7000 + rev))
	IC.uppdatera()
	prova("9a. startkortets rubrik är «Dags att rida» — ingen uppmaning att «välja» när det bara finns en väg",
		rubrik() == Sprak.t("guide.valj_rubrik", "Trixie") and rubrik() == "Dags att rida"
		and not string.find(string.lower(rubrik()), "välj", 1, true), rubrik())
	prova("9b. kortet säger uttryckligen att stallet gör hästen redo — spelaren behöver inte sadla eller tränsa",
		steg() == Sprak.t("guide.valj_kort", "Trixie", "Trixie") and har(steg(), "stallet gör Trixie redo")
		and har(steg(), "inte sadla eller tränsa själv"), steg())
	prova("9c. exakt EN primär handling: «Rida nu — Trixie» (id start:rida_nu), inget annat val",
		#N._val() == 1 and N._val()[1].id == "start:rida_nu" and N._val()[1].text == Sprak.t("guide.val_rida_nu", "Trixie"),
		#N._val())
	prova("9d. ingen manuell skötselhandling och inget «Gör i ordning själv» bland valen", forbjudetVal() == "", forbjudetVal())
	prova("9e. den SYNLIGA panelen bär bara «Rida nu» — på touch räcker knappen, ingen tangent behövs",
		#N._rader() == 1 and N._rader()[1] == Sprak.t("guide.val_rida_nu", "Trixie"), table.concat(N._rader(), " / "))
	prova("9f. ingen ledning: hästen har ingen LedPrompt, ingen SadlaPrompt, ingen TransaPrompt",
		#prompter("LedPrompt") == 0 and #prompter("SadlaPrompt") == 0 and #prompter("TransaPrompt") == 0)
	local fore9 = ridaNuAnrop
	N._val()[1].skicka()
	prova("9g. knappen kör den kanoniska InteractionController.ridaNu (serverns RidaNu anropas)",
		ridaNuAnrop == fore9 + 1, ("%d → %d"):format(fore9, ridaNuAnrop))

	for _, f in ipairs(Preparation.stegFaser()) do gorFas(f.id) end -- stallet har gjort allt, inklusive ledningen till ridhuset
	visa("ready_to_mount")
	prova("9h. efter «Rida nu» är nästa instruktion uppsittning: hon väntar i ridhuset, välj «Sitt upp»",
		rubrik() == Sprak.t("guide.sittupp_rubrik", "Trixie") and steg() == Sprak.t("guide.sittupp_text", "Trixie")
		and har(steg(), "väntar i ridhuset") and har(steg(), "Sitt upp")
		and not har(steg(), "rykta") and not har(steg(), "tränset") and not har(steg(), "led "), steg())
	local radText = table.concat(N._rader(), " / ")
	prova("9i. «Sitt upp» är en synlig, tryckbar rad i panelen (touch behöver ingen hålltangent)",
		#prompter("MountPrompt") >= 1 and har(radText, Sprak.t("interaktion.sitt_upp")), #prompter("MountPrompt") .. " | " .. Sprak.t("interaktion.sitt_upp") .. " | " .. radText)
	prova("9j. ingen «Rida nu», skötsel eller ledning kvar efter Rida nu", #prompter("RidaNuPrompt") == 0
		and forbjudetVal() == "" and #prompter("LedPrompt") == 0)

	local klar = { status = "ready_to_mount", redo = true, nasta = "", nastaMoment = "", klaraFaser = 5, buren = {}, utomRackhall = true }
	local bort = N._guideFor(klar, "skotsel", "", "Trixie", false)
	prova("9k. efter «Rida nu», spelaren långt från ridhuset: kortet säger var hon väntar — inte «till boxen»",
		bort and bort.rubrik == Sprak.t("guide.ga_till_rubrik", "Trixie") and bort.text == Sprak.t("guide.ga_till_ridhus_text", "Trixie")
		and har(bort.text, "väntar i ridhuset") and har(bort.text, "Sitt upp") and not har(bort.text, "boxen"), bort and bort.text)
	local ejKlar = N._guideFor({ status = "preparing", redo = false, nasta = "halsa", nastaMoment = "halsa1", klaraFaser = 0,
		buren = {}, utomRackhall = true }, "skotsel", "", "Trixie", false)
	prova("9l. före «Rida nu» pekar «Följ pilen» fortfarande på boxen (hon står där)",
		ejKlar and ejKlar.text == Sprak.t("guide.ga_till_text") and har(ejKlar.text, "boxen"), ejKlar and ejKlar.text)

	local nycklar = { "guide.valj_rubrik", "guide.valj_kort", "guide.val_rida_nu", "guide.sittupp_rubrik", "guide.sittupp_text", "guide.ga_till_ridhus_text" }
	local ofullstandig = {}
	for _, loc in ipairs({ "sv-se", "en-us" }) do
		Sprak.satLocale(loc)
		for _, k in ipairs(nycklar) do
			local t = Sprak.t(k, "Trixie", "Trixie")
			if t == "" or string.find(t, "%", 1, true) or t == k then table.insert(ofullstandig, loc .. ":" .. k) end
		end
	end
	Sprak.satLocale("en-us")
	local enText = Sprak.t("guide.valj_kort", "Trixie", "Trixie") .. " | " .. Sprak.t("guide.sittupp_text", "Trixie")
		.. " | " .. Sprak.t("guide.ga_till_ridhus_text", "Trixie")
	local enRubrik = Sprak.t("guide.valj_rubrik")
	Sprak.satLocale("sv-se")
	prova("9m. sv/en: alla sex nycklarna finns, inga kvarglömda %s, engelskan är konsekvent (inget «Choose», «Mount»)",
		#ofullstandig == 0 and enRubrik == "Time to ride" and har(enText, "Mount") and not har(string.lower(enText), "choose how"),
		table.concat(ofullstandig, " ") .. " | " .. enText)
end

print("")
if fel > 0 then
	error(("%d mätning(ar) föll."):format(fel), 0)
end
print(("klient-guide.spec: %d prov, alla gröna"):format(total))
