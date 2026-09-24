--!nostrict
--[[
	DEN BURNA UTRUSTNINGEN — mellan boxfronten och hästen (#182 del 1).

	Human-QA såg ingenting hända när prompten på boxfronten trycktes.
	Sanningen var att den GJORDE något: `GameplayService.valjPar` skrev
	två rader i en servertabell. Det var också allt. Ingen vy gick ut,
	inget dök upp i världen, och ingen kvittens namngav vad som kom på
	hästen när sadeln väl lades på.

	FYRA SAKER MÄTS HÄR, och alla fyra mot produktionens egen väg:

	  1. serverns auktoritativa vy bär `burenUtrustning` för den häst
	     utrustningen TILLHÖR,
	  2. hämtningen skickar vyn — `valjPar` får inte vara tyst,
	  3. utrustningen finns SYNLIGT i spelarens karaktär, och
	  4. den lämnar både vyn och händerna när den läggs på hästen, del
	     för del.

	VARFÖR VYN OCH VÄRLDEN MÄTS IHOP: statusen är härledd, inte bokförd
	(`Preparation.buren`). Ett prov som bara läste vyn kunde bli grönt av
	ett register som ljuger, och ett som bara läste världen kunde bli
	grönt utan att spelaren fick veta något.

	VAD BÄNKEN INTE KAN: hur den burna sadeln SER UT i Studio, och om
	64 px mellan raderna räcker för ett öga. Det är mänskliga grindar och
	står som sådana i PR-texten.

	Kör: python3 roblox/tests/build.py tests/buren-tack.spec.luau
	     && luau roblox/tests/.build/buren-tack.spec.luau
]]

local fails = 0
local function check(namn, villkor, detalj)
	if villkor then
		print(string.format("  OK   %s%s", namn, detalj and ("  " .. detalj) or ""))
	else
		fails += 1
		print(string.format("  FEL  %s%s", namn, detalj and ("  " .. detalj) or ""))
	end
end

local Players = game:GetService("Players")
local Taggar = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

--[[ ══ 1. REGELN, UTAN VÄRLD ═══════════════════════════════════════════

	`Preparation.buren` är ren och ska gå att fälla utan en enda instans.
	Det är samma skäl som resten av modulen finns till för: en regel som
	bara går att prova genom att starta en server provas aldrig. ]]

print("\n── Regeln: hämtat men inte påsatt ──")

do
	local namn = { trixie = "Trixie", marabou = "Marabou" }

	check("inget hämtat ger ingen status",
		Preparation.buren(nil, {}, namn) == nil)
	check("en tom valtabell ger ingen status",
		Preparation.buren({}, {}, namn) == nil)

	local par = Preparation.buren({ sadel = "trixie", trans = "trixie" }, {}, namn)
	check("ett hämtat par bärs", par ~= nil)
	check("och statusen namnger UTRUSTNINGENS häst",
		par ~= nil and par.hastId == "trixie" and par.hastnamn == "Trixie",
		par and ("%s / %s"):format(tostring(par.hastId), tostring(par.hastnamn)) or "-")
	check("båda delarna räknas", par ~= nil and #par.delar == 2,
		par and table.concat(par.delar, "+") or "-")

	--[[ DET HÄR ÄR REGELNS KÄRNA: påsatt utrustning är inte buren. ]]
	local halv = Preparation.buren({ sadel = "trixie", trans = "trixie" },
		{ sadel = true }, namn)
	check("en påsatt sadel bärs inte längre",
		halv ~= nil and #halv.delar == 1 and halv.delar[1] == "trans",
		halv and table.concat(halv.delar, "+") or "-")
	check("allt påsatt släcker statusen helt",
		Preparation.buren({ sadel = "trixie", trans = "trixie" },
			{ sadel = true, trans = true }, namn) == nil)

	--[[ FEL SADEL SKA SÄGA VEMS DEN ÄR. Att skriva spelarens egen häst
		där hade dolt precis det misstag momentet lär ut. ]]
	local fel = Preparation.buren({ sadel = "marabou", trans = "marabou" }, {}, namn)
	check("fel hästs utrustning namnger den ANDRA hästen",
		fel ~= nil and fel.hastnamn == "Marabou", fel and fel.hastnamn or "-")

	--[[ Okänt id får inte bli en gissning eller en tom rad. ]]
	local okand = Preparation.buren({ sadel = "spoke" }, {}, namn)
	check("ett id utan namn i rostern faller tillbaka på id:t",
		okand ~= nil and okand.hastnamn == "spoke",
		okand and okand.hastnamn or "-")
end

--[[ ══ 2. GENOM TJÄNSTERNA, MED RIGG OCH VÄRLD ═════════════════════════ ]]

local function nyKaraktar(pos)
	local k = Instance.new("Model")
	k.Name = "Karaktar"
	local rot = Instance.new("Part")
	rot.Name = "HumanoidRootPart"
	rot.Size = Vector3.new(2, 2, 1)
	rot.CFrame = CFrame.new(pos)
	rot.Parent = k
	local hum = Instance.new("Humanoid")
	hum.Name = "Humanoid"
	hum.Parent = k
	k.Parent = workspace
	return k, rot
end

local RIGG = Vector3.new(0, 0, 0)

--[[ Samma uppsättning som ridefirst.spec: riktiga tjänster, riktig rigg,
	riktig spelare. Skillnaden mot ett regelprov är hela poängen — den
	tysta `valjPar` syntes bara när tjänsten kördes. ]]
local function nySession(namn, userId)
	__datastore.nollstall()
	Taggar:nollstall()
	Players.PlayerAdded:nollstall()
	Players.PlayerRemoving:nollstall()
	RunService._server = true
	Players._spelare = {}
	SparService._glomHookarForProv()

	local k = nyKaraktar(RIGG + Vector3.new(2, 0, 0))
	local spelare = { Name = namn, UserId = userId, Character = k,
		CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }
	SparService._glomForProv(spelare)

	SparService.start()
	StallService.start()
	HorseService.start()
	GameplayService.start()

	Players._spelare = { spelare }
	Players.PlayerAdded:Fire(spelare)
	Players.PlayerAdded:slutfor()

	local hastId = StallService.hastIdFor(spelare)
	local modell = HastRigg.bygg(hastId, hastId, CFrame.new(RIGG))
	modell.Parent = workspace
	Taggar:AddTag(modell, "Horse")
	GameplayService.bind(spelare)
	k:FindFirstChild("HumanoidRootPart").CFrame = CFrame.new(RIGG + Vector3.new(2, 0, 0))
	return spelare, modell, hastId, k
end

--[[ Vyerna servern faktiskt SKICKAR, inte de vi ber om. `PreparationSync`
	är kanalen HUD:en lyssnar på; att fråga `PreparationHello` i stället
	hade mätt en annan väg än den `valjPar` använder. ]]
local vyer = {}
do
	RunService._server = true
	local sync = Networking.get("PreparationSync")
	sync.FireClient = function(_self, _spelare, vy)
		table.insert(vyer, vy)
	end
end

--[[ Går fram till det första utrustningsmomentet genom PRODUKTIONENS
	väg: varje fas före `iordning`, och sedan hovarna. Efter anropet står
	`utr:1` på tur. Bruten ut för att två block behöver samma väg fram och
	en andra kopia av den hade kunnat glida isär från kanon. ]]
local function framTillUtrustningen(sp)
	local s = GameplayService.stateFor(sp)
	for _, f in ipairs(Preparation.stegFaser()) do
		if f.id == "iordning" then break end
		for _, m in ipairs(Preparation.moment(f.id)) do
			if not m.fel and m.id then
				GameplayService.moment(sp, f.id, m.id)
				if Preparation.arVal(f.id) and Preparation.fasKlar(s, f.id) then break end
			end
		end
	end
	for _, m in ipairs(Preparation.moment("iordning")) do
		if not m.id:match("^utr:") then
			GameplayService.moment(sp, "iordning", m.id)
		end
	end
	return s
end

local spelare, modell, hastId, karaktar = nySession("Buren", 9101)

print("\n── Hämtningen syns: vy, status och en del i händerna ──")

do
	check("sessionen band hästen", GameplayService.modellFor(spelare) == modell)
	check("innan hämtningen bär spelaren ingenting",
		TackRigg.hittaBuren(karaktar, "sadel") == nil
			and TackRigg.hittaBuren(karaktar, "trans") == nil)

	vyer = {}
	local ok = GameplayService.valjPar(spelare, hastId)
	check("hämtningen gick igenom", ok == true)

	--[[ #182 DEL 1, PUNKT 2: den tysta hämtningen. Utan `skicka` här kom
		ingen vy förrän spelaren tryckte på något annat, och HUD:en kunde
		inte veta att hon bar något. ]]
	check("hämtningen SKICKADE en vy", #vyer >= 1, ("%d st"):format(#vyer))

	local vy = vyer[#vyer]
	local buren = vy and vy.burenUtrustning
	check("vyn bär burenUtrustning", buren ~= nil)
	check("för rätt häst", buren ~= nil and buren.hastId == hastId,
		buren and tostring(buren.hastId) or "-")
	check("med hästens egennamn, inte id:t",
		buren ~= nil and buren.hastnamn ~= hastId and buren.hastnamn ~= "",
		buren and tostring(buren.hastnamn) or "-")
	check("och båda delarna", buren ~= nil and #buren.delar == 2,
		buren and table.concat(buren.delar, "+") or "-")

	--[[ PUNKT 3: den SYNLIGA representationen. En status utan något i
		världen hade varit halva rättelsen — spelaren ska se sadeln. ]]
	local sadel = TackRigg.hittaBuren(karaktar, "sadel")
	local trans = TackRigg.hittaBuren(karaktar, "trans")
	check("sadeln finns som en VERKLIG del i spelarens karaktär",
		sadel ~= nil and sadel:IsA("BasePart"))
	check("och tränset likaså", trans ~= nil and trans:IsA("BasePart"))
	check("delarna bär vem utrustningen tillhör",
		sadel ~= nil and sadel:GetAttribute("ForHast") == hastId,
		sadel and tostring(sadel:GetAttribute("ForHast")) or "-")
	--[[ Buren utrustning får aldrig röra spelarens rörelse. Samma regel
		som gäller hästens: utrustning kolliderar inte. ]]
	check("den burna utrustningen kolliderar inte",
		sadel ~= nil and sadel.CanCollide == false
			and trans ~= nil and trans.CanCollide == false)
	check("och är masslös, så den inte tynger spelaren",
		sadel ~= nil and sadel.Massless == true)
	--[[ Den ska FÖLJA spelaren, alltså vara svetsad i karaktären. ]]
	check("sadeln är svetsad i spelaren",
		sadel ~= nil and sadel:FindFirstChildOfClass("WeldConstraint") ~= nil)

	--[[ Tjänsten läser VÄRLDEN, inte ett register. ]]
	check("TackService läser vad som bärs ur världen",
		TackService.barBuren(spelare, "sadel") == hastId
			and TackService.barBuren(spelare, "trans") == hastId)

	--[[ En andra hämtning av samma par ska inte bygga ett andra exemplar. ]]
	GameplayService.valjPar(spelare, hastId)
	local mapp = TackRigg.burenMapp(karaktar)
	local sadlar = 0
	for _, d in ipairs(mapp and mapp:GetChildren() or {}) do
		if d:GetAttribute("UBRFBuren") == "sadel" then sadlar += 1 end
	end
	check("en andra hämtning ger INTE en andra sadel", sadlar == 1,
		("%d st"):format(sadlar))
end

print("\n── Påsättningen flyttar utrustningen ur händerna, del för del ──")

do
	--[[ Momenten i tur och ordning genom produktionens egen väg. Stegen
		1, 2 och 5 lägger var sin fysisk del; 3 och 4 är handgrepp.
		HOVARNA FÖRST — utrustningen kommer efter dem i kanon. ]]
	local hovar = 0
	for _, m in ipairs(Preparation.moment("iordning")) do
		if not m.id:match("^utr:") then hovar += 1 end
	end
	local s = framTillUtrustningen(spelare)
	check(("de %d hovmomenten gick igenom"):format(hovar),
		Preparation.nastaMoment(s, "iordning") ~= nil
			and Preparation.nastaMoment(s, "iordning").id:match("^utr:1$") ~= nil,
		tostring(Preparation.nastaMoment(s, "iordning")
			and Preparation.nastaMoment(s, "iordning").id))

	--[[ ── STEG 1: UNDERLÄGGET ────────────────────────────────────────
		Underlägget hör till sadeln och hämtas med den. Det lämnar därför
		INTE händerna — spelaren bär sadeln vidare tills den är på. ]]
	local ok1, skal1, extra1 = GameplayService.moment(spelare, "iordning", "utr:1")
	check("underlägget går på", ok1 == true, tostring(skal1))
	check("kvittensen namnger DELEN och HÄSTEN",
		skal1 == "tack.pa_plats" and type(extra1) == "table"
			and extra1.del == "tack.del_underlagg" and type(extra1.hast) == "string"
			and extra1.hast ~= "",
		("%s / %s / %s"):format(tostring(skal1),
			tostring(type(extra1) == "table" and extra1.del),
			tostring(type(extra1) == "table" and extra1.hast)))
	check("men sadeln ligger kvar i händerna — underlägget hörde till den",
		TackService.barBuren(spelare, "sadel") == hastId)

	--[[ ── STEG 2: SADELN ─────────────────────────────────────────────
		Nu ska den lämna både händerna och statusraden. ]]
	vyer = {}
	local ok2, skal2, extra2 = GameplayService.moment(spelare, "iordning", "utr:2")
	check("sadeln går på", ok2 == true, tostring(skal2))
	check("kvittensen namnger sadeln",
		skal2 == "tack.pa_plats" and type(extra2) == "table"
			and extra2.del == "tack.del_sadel",
		tostring(type(extra2) == "table" and extra2.del))
	check("sadeln ligger FYSISKT på hästen", TackService.sadlad(modell) == true)
	check("och är därmed ur spelarens händer",
		TackService.barBuren(spelare, "sadel") == nil,
		tostring(TackService.barBuren(spelare, "sadel")))
	check("tränset bärs fortfarande",
		TackService.barBuren(spelare, "trans") == hastId)

	local vy2 = vyer[#vyer]
	local buren2 = vy2 and vy2.burenUtrustning
	check("och servervyn räknar bara tränset nu",
		buren2 ~= nil and #buren2.delar == 1 and buren2.delar[1] == "trans",
		buren2 and table.concat(buren2.delar, "+") or "-")

	--[[ Stegen 3 och 4 lägger inget nytt — ingen kvittens ska påstå det. ]]
	local ok3, skal3 = GameplayService.moment(spelare, "iordning", "utr:3")
	check("sadelbommen är ett handgrepp, ingen ny del",
		ok3 == true and skal3 ~= "tack.pa_plats", tostring(skal3))
	GameplayService.moment(spelare, "iordning", "utr:4")

	--[[ ── STEG 5: TRÄNSET ────────────────────────────────────────────
		Sista delen. Nu ska statusen slockna helt. ]]
	vyer = {}
	local ok5, skal5, extra5 = GameplayService.moment(spelare, "iordning", "utr:5")
	check("tränset går på", ok5 == true, tostring(skal5))
	check("kvittensen namnger tränset",
		skal5 == "tack.pa_plats" and type(extra5) == "table"
			and extra5.del == "tack.del_trans",
		tostring(type(extra5) == "table" and extra5.del))
	check("hästen är tränsad", TackService.transad(modell) == true)
	check("ingenting bärs längre",
		TackService.barBuren(spelare, "sadel") == nil
			and TackService.barBuren(spelare, "trans") == nil)
	check("och den burna mappen är städad ur karaktären",
		TackRigg.burenMapp(karaktar) == nil)

	local vy5 = vyer[#vyer]
	check("servervyn har ingen buren utrustning kvar",
		vy5 ~= nil and vy5.burenUtrustning == nil,
		vy5 and tostring(vy5.burenUtrustning) or "ingen vy")
end

print("\n── Kvittensen kan inte namnge en del som inte sitter där ──")

do
	--[[ FAIL CLOSED. `TackService.satPa` svarar ja när bygget gick fram,
		men VÄRLDEN är sanningen — samma regel som uppsittningsgrinden
		läser. Faller delen bort mellan bygget och kvitteringen ska
		momentet NEKAS, för annars kvitterar spelet en sadel som inte
		ligger på hästen. Det är exakt den motsägelse blockerare 5 i #162
		rev ut, i ny form.

		Kapplöpningen går inte att provocera fram på riktigt i bänken, så
		`harTack` byts ut för de anrop som momentet gör. Det är REGELN som
		mäts, inte hur den skulle kunna inträffa — och utan mätningen vore
		grinden ett påstående i en kommentar. ]]
	local sp2, mod2, id2 = nySession("Halvbygd", 9102)
	GameplayService.valjPar(sp2, id2)
	framTillUtrustningen(sp2)

	local akta = TackService.harTack
	TackService.harTack = function(m, typ)
		--[[ Underlägget «byggs» men finns aldrig i världen. Allt annat
			svarar som vanligt, så ordningskraven är oförändrade. ]]
		if typ == "underlagg" then return false end
		return akta(m, typ)
	end
	local ok, skal = GameplayService.moment(sp2, "iordning", "utr:1")
	TackService.harTack = akta

	check("ett moment vars del inte kom på plats NEKAS",
		ok == false and skal == "tack.kunde_inte_byggas", tostring(skal))
	check("och momentet är inte avbockat",
		(GameplayService.stateFor(sp2).gjorda["iordning"] or {})["utr:1"] == nil)
	check("ingen kvittens namnger en del som inte sitter där",
		skal ~= "tack.pa_plats", tostring(skal))
end

print("\n── Kvittensen blir läsbar text hos klienten ──")

do
	--[[ Servern skickar NYCKLAR. Det här mäter att klienten gör text av
		dem — och på SPELARENS språk, inte serverns. Skrev servern färdig
		text hade en engelsk spelare fått svenska, vilket är exakt det
		#162 rev ut ur nejen. ]]
	local pa = PreparationController.skalText("tack.pa_plats", nil)
	check("nyckeln finns i katalogen", Sprak.finns("tack.pa_plats") == true)
	check("och delarnas namn likaså",
		Sprak.finns("tack.del_sadel") and Sprak.finns("tack.del_trans")
			and Sprak.finns("tack.del_underlagg"))

	Sprak.satLocale("sv-se")
	local sv = Sprak.t("tack.pa_plats", Sprak.t("tack.del_sadel"), "Trixie")
	check("svensk kvittens namnger delen och hästen",
		sv:find("Trixie") ~= nil and sv:find("Sadeln") ~= nil, ("[%s]"):format(sv))
	Sprak.satLocale("en-us")
	local en = Sprak.t("tack.pa_plats", Sprak.t("tack.del_sadel"), "Trixie")
	check("engelsk kvittens är engelsk men behåller egennamnet",
		en:find("Trixie") ~= nil and en:find("saddle") ~= nil
			and en:find("Sadeln") == nil, ("[%s]"):format(en))
	Sprak.satLocale("sv-se")
	--[[ `pa` läses bara för att hålla anropet ovan vid liv; texten är
		oformaterad utan argument och ska inte mätas på innehåll. ]]
	check("skalText svarar på nyckeln", type(pa) == "string" and pa ~= "")
end

print("\n── Statusen överlever att hästen ännu inte finns ──")

do
	--[[ `waiting_model`: spelaren kan hämta sadel och träns innan riggen
		strömmat in. En vy utan häst får inte släcka en status som är
		sann — det var därför `burenUtrustning` ligger med i BÅDA
		grenarna av `Preparation.vy`. ]]
	local tom = Preparation.vy(nil, "waiting_model", 1, nil,
		{ hastId = "trixie", hastnamn = "Trixie", delar = { "sadel", "trans" } })
	check("den tomma vyn bär burenUtrustning",
		tom.burenUtrustning ~= nil and tom.burenUtrustning.hastnamn == "Trixie",
		tostring(tom.burenUtrustning and tom.burenUtrustning.hastnamn))
	check("och säger fortfarande att modellen saknas",
		tom.status == "waiting_model" and tom.hastId == nil)
end

--[[ ══ ETT MISSLYCKAT SLÄPP FÅR INTE SVARA JA (#264) ═══════════════

	Tobias rapporterade i sitt playtest 2026-09-24 att sadeln inte syntes
	på hästen och att han bar den kvar. Källan bar hålet:

	    if BARBARA[typ] then
	        pcall(function() TackService.slappBuren(player, typ) end)
	    end
	    return true

	Både `pcall`:s eget `ok` och `slappBuren`:s returvärde kastades bort,
	och `satPa` svarade JA ändå. Delen på hästen och kopian i handen är
	två påståenden om samma sak; säger de emot varandra får svaret inte
	vara «klart».

	Provet gör släppet omöjligt och mäter att svaret blir ett namngivet
	nej i stället för en falsk framgång. Den positiva kontrollen står
	kvar i blocket ovanför: ett lyckat släpp tömmer handen. ]]
do
	print("\n── Ett misslyckat släpp svarar inte ja ──")
	local spelare, modell, hastId = nySession("Slapp", 9107)

	--[[ Hon bär sadeln, precis som efter «Ta sadeln». ]]
	--[[ Paret hämtas först, som i blocket ovanför: då bär hon sadeln
	     vidare medan underlägget går på, och det är precis läget där
	     släppet ska ske. ]]
	GameplayService.valjPar(spelare, hastId)
	GameplayService.moment(spelare, "iordning", "utr:1")
	check("REPRODUKTION: hon bär sadeln",
		TackService.barBuren(spelare, "sadel") == hastId,
		tostring(TackService.barBuren(spelare, "sadel")))

	--[[ Släppet görs omöjligt. Bara bänkens väg byts; produktionskoden
	     är orörd. ]]
	local riktigSlapp = TackService.slappBuren
	TackService.slappBuren = function() return false end
	local ok, skal = TackService.satPa(spelare, modell, "sadel", hastId, modell)
	TackService.slappBuren = riktigSlapp

	check("ETT MISSLYCKAT SLÄPP SVARAR INTE JA", ok == false,
		("ok=%s skal=%s"):format(tostring(ok), tostring(skal)))
	check("och nejet är namngivet och läsbart", skal == "tack.bars_kvar",
		tostring(skal))
	--[[ ── OCH PÅSÄTTNINGEN ÄR ÅTERRULLAD ───────────────────────────

	     Det här provet välsignade förut ett permanent dubbeltillstånd:
	     sadeln på hästen OCH i handen, med motiveringen att konflikten
	     var «synlig». Granskningen visade vad det kostade — omförsöket
	     mötte `tack.redan_pa`, föll igenom och svarade JA med båda
	     exemplaren kvar:

	         first=false/tack.bars_kvar  second=true/nil
	         heldBefore=larry  heldAfter=larry  saddle=true

	     Ett avslag ska lämna världen som den var. Delen rullas därför
	     tillbaka, och ett omförsök är ett äkta nytt försök. ]]
	check("ETT AVSLAG LÄMNAR HÄSTEN OSADLAD", TackService.sadlad(modell) == false,
		tostring(TackService.sadlad(modell)))
	check("och sadeln ligger kvar i handen — inget konsumeras av ett nej",
		TackService.barBuren(spelare, "sadel") == hastId,
		tostring(TackService.barBuren(spelare, "sadel")))

	--[[ OCH DÅ LYCKAS OMFÖRSÖKET PÅ RIKTIGT: en sadel, på hästen,
	     ingen i handen. ]]
	local ok2, skal2 = TackService.satPa(spelare, modell, "sadel", hastId, modell)
	check("OMFÖRSÖKET LYCKAS UTAN DUBBLETT",
		ok2 == true and TackService.sadlad(modell) == true
			and TackService.barBuren(spelare, "sadel") == nil,
		("ok=%s skal=%s sadlad=%s bär=%s"):format(tostring(ok2), tostring(skal2),
			tostring(TackService.sadlad(modell)),
			tostring(TackService.barBuren(spelare, "sadel"))))
end

--[[ ══ SAMMA SAK FÖR TRÄNSET — OCH NÄR SLÄPPET SPRICKER (#264 R2) ═══

	Granskningen bad om täckning för BÅDA bärbara delarna och för BÅDA
	sätten ett släpp kan misslyckas. Det första provet ovanför mäter
	sadeln och ett släpp som svarar `false`.

	Tränset är inte en kopia av sadeln. `satPa("trans", …)` sätter också
	TYGLARNA, så återrullningen måste ta med dem — annars blir priset för
	ett avslag ett par tyglar utan träns, hängande i luften.

	Och `slappBuren` kan SPRICKA, inte bara svara nej. Det är därför
	anropet ligger i en `pcall`. Men en `pcall` som fångar ett fel och
	sedan struntar i sitt eget `ok` är en tystad krasch, inte en hanterad
	sådan — precis det hålet rättelsen stängde. Här kastas det på riktigt. ]]
do
	print("\n── Tränset, och ett släpp som spricker ──")

	--[[ ── A · TRÄNSET, MED TYGLARNA ─────────────────────────────────── ]]
	local spelare, modell, hastId = nySession("SlappTrans", 9108)
	local karaktar = spelare.Character
	GameplayService.valjPar(spelare, hastId)
	GameplayService.moment(spelare, "iordning", "utr:1")
	--[[ SADELN MÅSTE PÅ FÖRST. Utan det här steget nekas tränset redan
	     på `tack.sadeln_forst`, ingenting hinner fästas, och provet blir
	     grönt utan att ha rört återrullningen. Så såg det ut i första
	     skrivningen — mätningen fanns, men mätte tomma luften. ]]
	GameplayService.moment(spelare, "iordning", "utr:2")
	check("sadeln ligger på — annars nekas tränset av fel skäl",
		TackService.sadlad(modell) == true, tostring(TackService.sadlad(modell)))
	check("REPRODUKTION: hon bär tränset",
		TackService.barBuren(spelare, "trans") == hastId,
		tostring(TackService.barBuren(spelare, "trans")))

	local riktigSlapp = TackService.slappBuren
	TackService.slappBuren = function() return false end
	local okT, skalT = TackService.satPa(spelare, modell, "trans", hastId, modell)
	TackService.slappBuren = riktigSlapp

	check("ett misslyckat släpp av TRÄNSET svarar inte ja heller",
		okT == false and skalT == "tack.bars_kvar",
		("ok=%s skal=%s"):format(tostring(okT), tostring(skalT)))
	check("hästen är otränsad efter avslaget", TackService.transad(modell) == false,
		tostring(TackService.transad(modell)))
	--[[ TYGLARNA ÄR DET SOM SKILJER. De går på med tränset och måste gå
	     av med det; en halv återrullning är ett eget fel. ]]
	check("OCH TYGLARNA FÖLJDE MED TILLBAKA — ingen halv återrullning",
		TackRigg.hittaDel(modell, "tygel") == nil,
		tostring(TackRigg.hittaDel(modell, "tygel")))
	check("tränset ligger kvar i handen", TackService.barBuren(spelare, "trans") == hastId)
	local okT2 = TackService.satPa(spelare, modell, "trans", hastId, modell)
	check("och omförsöket lyckas utan dubblett",
		okT2 == true and TackService.transad(modell) == true
			and TackService.barBuren(spelare, "trans") == nil,
		("ok=%s tränsad=%s bär=%s"):format(tostring(okT2),
			tostring(TackService.transad(modell)),
			tostring(TackService.barBuren(spelare, "trans"))))

	--[[ ── B · SLÄPPET SPRICKER ────────────────────────────────────────

	     Inte «svarar nej» utan «kastar». Utan `pcall` skulle felet resa
	     upp genom `moment` och spelaren stå kvar utan svar; med `pcall`
	     men utan att läsa `ok` blir det ett tyst ja. Båda är fel. ]]
	local sp2, mod2, hast2 = nySession("SlappSpricker", 9109)
	GameplayService.valjPar(sp2, hast2)
	GameplayService.moment(sp2, "iordning", "utr:1")
	check("REPRODUKTION: hon bär sadeln",
		TackService.barBuren(sp2, "sadel") == hast2)

	local sprack = 0
	TackService.slappBuren = function()
		sprack += 1
		error("släppet sprack på riktigt", 0)
	end
	local okS, skalS = TackService.satPa(sp2, mod2, "sadel", hast2, mod2)
	TackService.slappBuren = riktigSlapp

	check("släppet kastade verkligen", sprack == 1, ("%d"):format(sprack))
	check("ETT SPRUCKET SLÄPP SVARAR INTE JA",
		okS == false and skalS == "tack.bars_kvar",
		("ok=%s skal=%s"):format(tostring(okS), tostring(skalS)))
	check("och felet reser inte vidare — spelaren får ett svar, inte en krasch",
		type(skalS) == "string")
	check("påsättningen är återrullad även när släppet kastade",
		TackService.sadlad(mod2) == false, tostring(TackService.sadlad(mod2)))
	check("sadeln ligger kvar i handen", TackService.barBuren(sp2, "sadel") == hast2)
end



if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("\nburen-tack.spec: alla gröna")
end
