--!nostrict
--[[
	FÖRENKLINGEN PÅ KLIENTEN — #273 SIMPLIFY (S1, S2, S3).

	Tobias beslut 2026-10-01. En ny spelare ska bara behöva förstå styra,
	snabbare, långsammare/stanna och interagera/sitta av.

	VAD SOM MÄTS, genom klientens riktiga moduler och `init.client`:

	  1  S1  kontrollistan öppnas ALDRIG av sig själv — inte heller vid
	         första uppsittningen, mätt genom produktionens egen
	         `MountChanged`-väg. `H` öppnar och stänger den.
	  2  S1  vänstermenyns kärna är fyra rader, och ingen av dem är en
	         avancerad hjälp. Listan har kärnan först och hjälperna under
	         rubriken «Avancerat». På en ren pekyta finns ingen avancerad rad.
	  3  S2  skötselpanelen visar EN handling per fas, och detaljmeningarna
	         står i kunskapslagret — för varje handling i kedjan.
	  4  S3  eftervården är ett VAL: «Stallet tar hand om henne» eller «Ta
	         hand om henne själv». Själv ger en handling i taget, och stallet
	         finns kvar som väg ut.

	NOT TESTED: hur det ser ut och känns på en riktig skärm. Det är Tobias
	speltest — PC, iPad och iPhone.

	Kör: python3 roblox/tests/build.py tests/klient-forenkling.spec.luau
	     && luau roblox/tests/.build/klient-forenkling.spec.luau
]]

local fel = 0
local antal = 0
local function prova(vad, ok, detalj)
	antal += 1
	if ok then
		print(("  OK   %s%s"):format(vad, if detalj then "  " .. tostring(detalj) else ""))
	else
		fel += 1
		print(("  FEL  %s%s"):format(vad, if detalj then "  " .. tostring(detalj) else ""))
	end
end

local Players = game:GetService("Players")
local Taggar = game:GetService("CollectionService")
local RSt = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local Net = Networking
local PC = PreparationController

Sprak.satLocale("sv-se")

RunService._server = true
Net.get("MountRequest")
Net.get("LedBorja")
Net.get("LedSlapp")
Net.get("LedSync")
Net.get("RidaNu")
Net.get("PreparationHandling")
Net.get("PassHandling")
RunService._server = false
RSt:SetAttribute("G01Enabled", true)

local HAST_ID = "trixie"
local hast = __makeHastModell("Trixie")
hast:SetAttribute("HorseId", HAST_ID)
hast:SetAttribute("HorseName", "Trixie")
hast.Parent = workspace
Taggar:AddTag(hast, "Horse")
local hastRot = hast:FindFirstChild("HumanoidRootPart")

local karaktar = Instance.new("Model")
karaktar.Name = "Spelare"
local kropp = Instance.new("Part")
kropp.Name = "HumanoidRootPart"
kropp.Size = Vector3.new(2, 2, 1)
kropp.CFrame = CFrame.new(hastRot.CFrame.Position)
kropp.Parent = karaktar
karaktar.Parent = workspace
player.Character = karaktar

local function bildrutor(n)
	for _ = 1, n do RunService.RenderStepped:Fire(1 / 30) end
end
local function tryck(kod)
	UIS.InputBegan:Fire({ KeyCode = kod }, false)
end

--[[ ══ 1. KONTROLLISTAN ÖPPNAS ALDRIG AV SIG SJÄLV ══════════════════════ ]]
print("\n── 1. S1: kontrollistan öppnas aldrig av sig själv ──")
do
	KontrollHjalp.start()
	prova("före uppsittningen är listan stängd", KontrollHjalp.synlig() == false)
	prova("funktionen som öppnade den vid uppsittningen finns inte längre",
		KontrollHjalp.vidUppsittning == nil, type(KontrollHjalp.vidUppsittning))

	--[[ Uppsittningen genom produktionens egen väg, som
		`klient-hjalpknapp.spec` gör: servern säger att hon sitter upp. ]]
	local ridhast = __makeHastModell("Ridhast")
	ridhast.Parent = workspace
	Net.get("MountChanged").OnClientEvent:Fire(ridhast, player)
	bildrutor(3)
	prova("FÖRSTA uppsittningen öppnar inte listan", KontrollHjalp.synlig() == false)
	tryck(Enum.KeyCode.H)
	prova("H öppnar den", KontrollHjalp.synlig() == true)
	tryck(Enum.KeyCode.H)
	prova("H stänger den", KontrollHjalp.synlig() == false)

	--[[ En andra uppsittning öppnar den inte heller. ]]
	Net.get("MountChanged").OnClientEvent:Fire(ridhast, nil)
	bildrutor(2)
	Net.get("MountChanged").OnClientEvent:Fire(ridhast, player)
	bildrutor(3)
	prova("en ANDRA uppsittning öppnar den inte heller", KontrollHjalp.synlig() == false)
	Net.get("MountChanged").OnClientEvent:Fire(ridhast, nil)
	bildrutor(2)
	ridhast:Destroy()
end

--[[ ══ 2. KÄRNAN FÖRST, HJÄLPERNA UNDER «AVANCERAT» ═════════════════════ ]]
print("\n── 2. S1: fyra kärnrader, hjälperna under «Avancerat» ──")
do
	local foreKb, foreGp, foreTouch = UIS.KeyboardEnabled, UIS.GamepadEnabled, UIS.TouchEnabled
	local AVANCERADE = { Sprak.t("hjalp.tygel"), Sprak.t("hjalp.halvhalt"),
		Sprak.t("hjalp.djupare_sits"), Sprak.t("hjalp.hoppa") }
	local function arAvancerad(text)
		for _, a in ipairs(AVANCERADE) do if a == text then return true end end
		return false
	end

	UIS.KeyboardEnabled, UIS.GamepadEnabled, UIS.TouchEnabled = true, false, false
	local karna = KontrollHjalp.ridrader()
	local namn = {}
	for _, r in ipairs(karna) do table.insert(namn, r.vad .. " [" .. r.reglage .. "]") end
	prova("vänstermenyns kärna är exakt fyra rader", #karna == 4, table.concat(namn, " | "))
	prova("upp, ned, styr, sitt upp/av — med ETT reglage var",
		#karna == 4 and karna[1].vad == Sprak.t("hjalp.hogre_gangart") and karna[1].reglage == "W / ↑"
			and karna[2].vad == Sprak.t("hjalp.lagre_gangart") and karna[2].reglage == "S / ↓"
			and karna[3].vad == Sprak.t("hjalp.styr") and karna[4].vad == Sprak.t("hjalp.sitt_upp_av"))
	local ingenAv = true
	for _, r in ipairs(karna) do if arAvancerad(r.vad) or r.avancerat then ingenAv = false end end
	prova("ingen kärnrad är en avancerad hjälp", ingenAv)

	local lista = KontrollHjalp.listrader()
	local iRubrik, rubriker = nil, 0
	for i, r in ipairs(lista) do
		if r.rubrik then rubriker += 1; iRubrik = iRubrik or i end
	end
	prova("listan har EN rubrik, «Avancerat»", rubriker == 1 and iRubrik ~= nil
		and lista[iRubrik].vad == Sprak.t("hjalp.avancerat"), tostring(iRubrik))
	local karnanForst = iRubrik ~= nil and iRubrik > 4
	for i = 1, 4 do
		if not (lista[i] and karna[i] and lista[i].vad == karna[i].vad) then karnanForst = false end
	end
	prova("kärnans fyra rader står först i listan, i samma ordning", karnanForst)
	local foreOk, efterOk, efter = true, true, 0
	for i, r in ipairs(lista) do
		if iRubrik and i < iRubrik and arAvancerad(r.vad) then foreOk = false end
		if iRubrik and i > iRubrik then
			efter += 1
			if not arAvancerad(r.vad) then efterOk = false end
		end
	end
	prova("ingen hjälp står FÖRE rubriken", foreOk)
	prova("tygel, halvhalt, sits och hopp står UNDER den — och bara de", efterOk and efter == 4, efter .. " rader")

	--[[ REN PEKYTA: där finns inget reglage för en avancerad hjälp, och då
		finns varken raden eller rubriken. ]]
	UIS.KeyboardEnabled, UIS.GamepadEnabled, UIS.TouchEnabled = false, false, true
	local pek = KontrollHjalp.listrader()
	local pekAv, pekRubrik = 0, 0
	for _, r in ipairs(pek) do
		if r.rubrik then pekRubrik += 1 end
		if arAvancerad(r.vad) then pekAv += 1 end
	end
	prova("på en ren pekyta: ingen avancerad rad och ingen rubrik", pekAv == 0 and pekRubrik == 0,
		("%d avancerade · %d rubriker"):format(pekAv, pekRubrik))
	local pekKarna = KontrollHjalp.ridrader()
	prova("pekytans kärna: DRIV, BROMS, spaken och SITT AV",
		#pekKarna == 4 and pekKarna[1].reglage == Sprak.t("touch.driv")
			and pekKarna[2].reglage == Sprak.t("touch.broms")
			and pekKarna[4].reglage == Sprak.t("touch.sitt_av"),
		#pekKarna .. " rader")

	--[[ T4: hjälperna är neutrala i grundridningen — kanonens tal. ]]
	prova("T4: kanonens krav på de avancerade hjälperna är 0 i grundridningen",
		RidKanon.SVAR.HJALP_KRAV == 0, tostring(RidKanon.SVAR.HJALP_KRAV))
	UIS.KeyboardEnabled, UIS.GamepadEnabled, UIS.TouchEnabled = foreKb, foreGp, foreTouch
end

--[[ ══ 3. EN HANDLING PER FAS, DETALJERNA I KUNSKAPSLAGRET ══════════════ ]]
print("\n── 3. S2: en handling per fas, detaljmeningarna i kunskapslagret ──")
local rev = 0
local state = Preparation.nyState(HAST_ID, 1)
local function visa(status)
	rev += 1
	PC.tillampa(Preparation.vy(state, status, rev, "Trixie"))
	PC.uppdateraKontext()
end
do
	--[[ Varje detaljmening i skötselkanonen som FÖRUT stod i kortet. ]]
	local detaljer = {}
	for _, h in ipairs(UBRFSkotsel.halsning) do table.insert(detaljer, h.text) end
	for _, p in ipairs(UBRFSkotsel.visitation.punkter) do table.insert(detaljer, p.ok) end
	for _, r in ipairs(UBRFSkotsel.rykt.redskap) do table.insert(detaljer, r.text) end
	for _, h in ipairs(UBRFSkotsel.hovar) do table.insert(detaljer, h.text) end
	for _, f in ipairs(UBRFSkotsel.sadelfaser) do table.insert(detaljer, f.t) end

	local handlingen = Net.get("PreparationHandling")
	local fore = handlingen.InvokeServer
	local skickade = {}
	handlingen.InvokeServer = function(_, id)
		table.insert(skickade, id)
		local ok, skal, h = Preparation.provaHandling(state, id, HAST_ID)
		if not ok then return false, skal end
		for _, m in ipairs(h.moment) do Preparation.utforMoment(state, h.fas, m.id, HAST_ID) end
		return true
	end

	local KEDJA = {
		{ id = "halsa", knapp = "handling.halsa", text = "handling.halsa_text", moment = 3 },
		{ id = "kolla", knapp = "handling.kolla", text = "handling.kolla_text", moment = 5 },
		{ id = "rykta", knapp = "handling.rykta", text = "handling.rykta_text", moment = 6 },
		{ id = "kratsa", knapp = "handling.kratsa", text = "handling.kratsa_text", moment = 4 },
		{ id = "sadla", knapp = "handling.sadla", text = "handling.sadla_text", moment = 4 },
		{ id = "transa", knapp = "handling.transa", text = "handling.transa_text", moment = 1 },
	}
	local summa = 0
	for _, k in ipairs(KEDJA) do
		visa(Preparation.STATUS.FORBEREDER)
		if type(__senasteDelay) == "function" then __senasteDelay() end
		visa(Preparation.STATUS.FORBEREDER)
		local synliga = PC._synligaMoment()
		local data = PC.panel() or {}
		local instr = PC._ytor().instruktion.Text
		prova(("«%s»: EN rad i panelen, och det är handlingen"):format(k.id),
			#synliga == 1 and synliga[1] == "handling:" .. k.id
				and #(data.val or {}) == 1 and data.val[1].text == Sprak.t(k.knapp),
			table.concat(synliga, ", "))
		local detaljIKort = false
		for _, d in ipairs(detaljer) do
			if string.find(instr, d, 1, true) ~= nil then detaljIKort = true end
		end
		prova(("«%s»: kortets rad är den korta, ingen detaljmening"):format(k.id),
			instr == Sprak.t(k.text) and not detaljIKort, ("[%s]"):format(instr))
		local kunskap = tostring(data.kunskap or "")
		local h = Preparation.hittaHandling(k.id)
		local allaMed = #h.moment == k.moment
		for _, m in ipairs(h.moment) do
			if string.find(kunskap, m.text, 1, true) == nil then allaMed = false end
		end
		summa += #h.moment
		prova(("«%s»: kunskapslagret bär handlingens %d meningar ordagrant"):format(k.id, k.moment), allaMed,
			("%d moment"):format(#h.moment))
		PC.begarHandling(k.id)
	end
	prova("sex handlingar skickades, i ordning",
		table.concat(skickade, ",") == "halsa,kolla,rykta,kratsa,sadla,transa", table.concat(skickade, ","))
	prova("och de bar tillsammans de 23 moment som förut var 23 klick", summa == 23, tostring(summa))
	prova("varje moment är gjort av spelaren själv", Preparation.egenAndel(state) > 0.9,
		("egen andel %.3f (ledningen återstår)"):format(Preparation.egenAndel(state)))
	if type(__senasteDelay) == "function" then __senasteDelay() end
	visa(Preparation.STATUS.FORBEREDER)
	prova("efter tränset står LEDNINGEN på tur — den är ingen handling, hon ska ledas dit",
		PC.nastaFas() == "leda" and PC._synligaMoment()[1] == "leda", tostring(PC._synligaMoment()[1]))

	--[[ ETT FYND ÄR INGEN KVITTENS. Svarar servern att ett fynd står öppet
		får panelen inte säga «Allt ser bra ut». ]]
	handlingen.InvokeServer = function() return true, "forb.oppet_fynd" end
	if type(__senasteDelay) == "function" then __senasteDelay() end
	PC.begarHandling("kolla")
	prova("ett fynd ger ingen «Allt ser bra ut»-kvittens", PC._bekraftelse() == nil,
		tostring(PC._bekraftelse()))
	handlingen.InvokeServer = fore
end

--[[ ══ 4. EFTERVÅRDEN ÄR ETT VAL ═════════════════════════════════════════ ]]
print("\n── 4. S3: eftervården är ett val ──")
do
	state = Preparation.nyState(HAST_ID, 1)
	for _, f in ipairs(Preparation.stegFaser()) do
		while true do
			local m = Preparation.nastaMoment(state, f.id)
			if not m then break end
			if not Preparation.utforMoment(state, f.id, m.id, HAST_ID) then break end
		end
	end
	local pass = Pass.nyState(HAST_ID, Pass.byggId(1, HAST_ID, 1))
	Pass.vidUppsittning(pass)
	Pass.vidAvsittning(pass)
	local prev = 9100
	local function visaPass()
		prev += 1
		PC.tillampaPass(Pass.vy(pass, prev))
		visa(Preparation.STATUS.REDO)
	end

	local remote = Net.get("PassHandling")
	local fore = remote.InvokeServer
	local skickade = {}
	remote.InvokeServer = function(_, id)
		table.insert(skickade, tostring(id))
		if id == "stallet" then
			for _, m in ipairs(Pass.moment()) do
				if not pass.gjorda[m.id] then Pass.utfor(pass, m.id, "auto") end
			end
			return true, "eftervard.stallet_klar"
		end
		for _, h in ipairs(Pass.handlingar()) do
			if h.id == id then
				for _, m in ipairs(h.moment) do Pass.utfor(pass, m.id) end
			end
		end
		return true
	end
	local function valet(id)
		for _, v in ipairs((PC.panel() or {}).val or {}) do
			if v.id == id then return v end
		end
		return nil
	end

	visaPass()
	local s1 = PC._synligaMoment()
	prova("efter avsittningen står EXAKT två val: stallet och själv",
		#s1 == 2 and valet("efter:stallet") ~= nil and valet("efter:sjalv") ~= nil, table.concat(s1, ", "))
	prova("de heter «Stallet tar hand om henne» och «Ta hand om henne själv»",
		valet("efter:stallet").text == Sprak.t("eftervard.stallet")
			and valet("efter:sjalv").text == Sprak.t("eftervard.sjalv"))
	prova("stallet är det lyfta valet — ingen straffavgift för att rida först",
		valet("efter:stallet").paTur == true and valet("efter:sjalv").paTur ~= true)
	prova("instruktionen är EN fråga, inget eftervårdsmoment",
		PC._ytor().instruktion.Text == Sprak.t("eftervard.val_text"), PC._ytor().instruktion.Text)
	local femGamla = false
	for _, m in ipairs(Pass.moment()) do
		if valet(m.id) ~= nil then femGamla = true end
	end
	prova("de fem obligatoriska momentraderna finns inte i panelen", not femGamla)

	--[[ SJÄLV: en handling i taget, och stallet kvar som väg ut. ]]
	valet("efter:sjalv").skicka()
	local s2 = PC._synligaMoment()
	prova("«själv» visar handlingen på tur och stallet som väg ut",
		#s2 == 2 and valet("efter:sadla_av") ~= nil and valet("efter:stallet") ~= nil
			and valet("efter:sjalv") == nil, table.concat(s2, ", "))
	prova("handlingen är «Ta av sadeln» med EN kort rad",
		valet("efter:sadla_av").text == Sprak.t("eftervard.sadla_av")
			and PC._ytor().instruktion.Text == Sprak.t("eftervard.sadla_av_text"))
	prova("och stallet heter nu «Stallet tar hand om resten»",
		valet("efter:stallet").text == Sprak.t("eftervard.stallet_resten"))
	local kunskap = tostring((PC.panel() or {}).kunskap or "")
	prova("kunskapslagret bär gjordens och sadelns meningar ordagrant",
		string.find(kunskap, UBRFSkotsel.eftervard[1].text, 1, true) ~= nil
			and string.find(kunskap, UBRFSkotsel.eftervard[2].text, 1, true) ~= nil, kunskap)

	valet("efter:sadla_av").skicka()
	if type(__senasteDelay) == "function" then __senasteDelay() end
	visaPass()
	prova("handlingen gick iväg som «sadla_av»", skickade[1] == "sadla_av", table.concat(skickade, ","))
	prova("nästa handling är «Ta av tränset»", valet("efter:transa_av") ~= nil
		and valet("efter:transa_av").text == Sprak.t("eftervard.transa_av"))

	--[[ Hon tröttnar: stallet gör resten. ]]
	valet("efter:stallet").skicka()
	prova("«Stallet tar hand om resten» skickar valet «stallet»", skickade[2] == "stallet",
		table.concat(skickade, ","))
	prova("och kvittensen säger att passet är klart",
		type(PC._bekraftelse()) == "string"
			and string.find(PC._bekraftelse(), Sprak.t("eftervard.stallet_klar"), 1, true) ~= nil,
		tostring(PC._bekraftelse()))
	prova("två av fem moment blev hennes egna, resten stallets",
		math.abs(Pass.egenAndel(pass) - 0.4) < 1e-9 and pass.lage == Pass.LAGE.KLART,
		("%.2f · %s"):format(Pass.egenAndel(pass), tostring(pass.lage)))
	remote.InvokeServer = fore
	if type(__senasteDelay) == "function" then __senasteDelay() end
end

print("")
if fel > 0 then
	print(("%d mätningar föll."):format(fel))
	error(("%d fel"):format(fel))
end
print(("klient-forenkling.spec: %d prov, alla gröna"):format(antal))
