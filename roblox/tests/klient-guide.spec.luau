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

print("\n── 2. Vid hästen, inget gjort: STARTSKÄRMEN med bara två vägar (UI-1) ──")
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
prova("«Välj hur du börjar» med den korta instruktionen (ingen hälsningsfråga)",
	rubrik() == Sprak.t("guide.valj_rubrik", "Trixie") and steg() == Sprak.t("guide.valj_kort", "Trixie"), steg())
local vt = valTexter()
prova("exakt två val: «Rida nu — Trixie» och «Gör i ordning Trixie själv»", #vt == 2
	and vt[1] == Sprak.t("guide.val_rida_nu", "Trixie") and vt[2] == Sprak.t("guide.val_sjalv", "Trixie"), table.concat(vt, " / "))
-- `_rader()` är ALLT synligt i skärmordning (valen först, sedan promptraderna).
local synligt = N._rader()
prova("inga promptrader och inget «Fler»: det synliga är exakt de två valen", #synligt == 2
	and synligt[1] == vt[1] and synligt[2] == vt[2], table.concat(synligt, " / "))
local harHalsning = false
for _, v in ipairs(N._val()) do if v.fel ~= nil then harHalsning = true end end
prova("inga hälsningssvar på startskärmen", not harHalsning)

print("\n── 3. Den manuella kedjan genom den riktiga Preparation ──")
valMed("start:sjalv").skicka()
N.satRider(false)
prova("«Gör i ordning själv»: «Hälsa på Trixie» med fasens fråga och hälsningens val",
	rubrik() == Sprak.t("guide.halsa_rubrik", "Trixie") and steg() ~= "" and #N._val() >= 2 and valMed("start:sjalv") == nil,
	rubrik() .. " | " .. steg())
gorFas("halsa"); visa("preparing")
prova("visitera: «Kolla Trixie · x/y» med momentets egen text", borjar(rubrik(), Sprak.t("guide.visitera_rubrik", "Trixie"))
	and har(rubrik(), "/") and steg() ~= "", rubrik() .. " | " .. steg())
gorFas("visitera"); visa("preparing")
prova("rykta: «Rykta Trixie · x/y»", borjar(rubrik(), Sprak.t("guide.rykta_rubrik", "Trixie")) and steg() ~= "", rubrik())
gorFas("rykta"); visa("preparing")
prova("iordning, hovarna: «Kratsa hovarna»", rubrik() == Sprak.t("guide.hovar_rubrik", "Trixie") and steg() ~= "", rubrik())
gorMoment("iordning", "hov:"); visa("preparing")
prova("ingen utrustning buren: «Hämta sadeln»", rubrik() == Sprak.t("guide.hamta_sadel_rubrik", "Trixie")
	and steg() == Sprak.t("guide.hamta_sadel_text", "Trixie"), rubrik() .. " | " .. steg())
visa("preparing", bar("sadel"))
prova("sadeln buren, tränset inte: «Hämta tränset»", rubrik() == Sprak.t("guide.hamta_trans_rubrik", "Trixie"), rubrik())
visa("preparing", bar("sadel", "trans"))
prova("båda burna: «Lägg på sadeln» med momentets text", rubrik() == Sprak.t("guide.sadla_rubrik", "Trixie") and steg() ~= "",
	rubrik() .. " | " .. steg())
-- Underlägg och sadel på (utr:1, utr:2); resten av sadlingen (utr:3/4) medan tränset bärs.
local m1 = Preparation.nastaMoment(state, "iordning")
Preparation.utforMoment(state, "iordning", m1.id, HAST_ID)
local m2 = Preparation.nastaMoment(state, "iordning")
Preparation.utforMoment(state, "iordning", m2.id, HAST_ID)
visa("preparing", bar("trans"))
prova("sadeln på, resten av sadlingen: fortfarande «Lägg på sadeln»", rubrik() == Sprak.t("guide.sadla_rubrik", "Trixie"),
	rubrik() .. " (" .. tostring(Preparation.nastaMoment(state, "iordning").id) .. ")")
while Preparation.nastaMoment(state, "iordning") and Preparation.nastaMoment(state, "iordning").id ~= "utr:5" do
	local m = Preparation.nastaMoment(state, "iordning")
	if not Preparation.utforMoment(state, "iordning", m.id, HAST_ID) then break end
end
visa("preparing", bar("trans"))
prova("tränset på tur och buret: «Sätt på tränset»", rubrik() == Sprak.t("guide.transa_rubrik", "Trixie") and steg() ~= "",
	rubrik() .. " | " .. steg())
visa("preparing", nil)
prova("tränset på tur men inte buret: «Hämta tränset»", rubrik() == Sprak.t("guide.hamta_trans_rubrik", "Trixie"), rubrik())
gorFas("iordning"); visa("preparing")
prova("leda: «Led Trixie till ridhuset» + välj i listan", rubrik() == Sprak.t("guide.leda_rubrik", "Trixie")
	and steg() == Sprak.t("guide.leda_text"), rubrik() .. " | " .. steg())
gorFas("leda"); visa("ready_to_mount")
prova("redo: «Sitt upp på Trixie» + rid", rubrik() == Sprak.t("guide.sittupp_rubrik", "Trixie")
	and steg() == Sprak.t("guide.sittupp_text"), rubrik() .. " | " .. steg())

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
prova("engelska: «Choose how to start»/«Ride now»; efter valet «Greet Trixie» + frågan", (function()
	Sprak.satLocale("en-us")
	local k = N._guideFor(med({}), "skotsel:halsa", "Walk up from the side.", "Trixie", false, false)
	local h = N._guideFor(med({}), "skotsel:halsa", "Walk up from the side.", "Trixie", false, true)
	local r, sj = Sprak.t("guide.val_rida_nu", "Trixie"), Sprak.t("guide.val_sjalv", "Trixie")
	Sprak.satLocale("sv-se")
	return k and k.rubrik == "Choose how to start" and har(k.text, "Ride now") and not har(k.text, "Walk up")
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

print("")
if fel > 0 then
	error(("%d mätning(ar) föll."):format(fel), 0)
end
print(("klient-guide.spec: %d prov, alla gröna"):format(total))
