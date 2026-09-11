--!nostrict
--[[
	UTRUSTNINGSGRINDEN — sadeln och tränset som FYSISK gameplay.

	Den blockerande produktluckan 16:21: utrustningssteget var ett abstrakt
	tillståndsbyte. `GameplayService.moment` prövade närvaro vid rätt häst,
	men ingenting i kedjan krävde att spelaren hade hämtat en sadel, och
	ingen sadel fanns att hämta. Man tryckte på en HUD-rad vid hästen och
	var sadlad.

	Grinden mäter det ordern räknar upp, i den ordning den räknar upp det:

	  1. saken finns på en KÄLLSTYRD plats — hästens egen boxfront, ur
	     `references/buildings/stall/KORT.md` § Boxarna från gången,
	  2. den går att hämta, och bärs sedan av spelaren,
	  3. steget går INTE att kvittera utan den,
	  4. nejen: fel häst, inte hämtad, bara sadel men inget träns, för
	     långt bort, dubbel interaktion, och något som inte är utrustning.

	VAD SOM INTE MÄTS HÄR: att boxfronten ligger i en gångbar gång och att
	sakerna faktiskt hänger i den byggda anläggningen. Det kräver världen
	och mäts av `spelbarhet`/`topologi` mot samma `Stallet`-geometri.
	Formen på sadeln är spelabstraktion och mäts inte alls.

	Kör: python3 roblox/tests/build.py tests/utrustning.spec.luau
	     && luau roblox/tests/.build/utrustning.spec.luau
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

--[[ ══ 1. PLATSEN ÄR HÄRLEDD UR BOXEN, INTE SKRIVEN ═══════════════════ ]]
print("\n── Platsen: boxfronten, för varje häst i stallet ──")
do
	check("okänd häst ger ingen plats",
		Stallet.utrustningsplats("finns_inte", "sadel") == nil)
	check("okänd sak ger ingen plats",
		Stallet.utrustningsplats(Stallet.FORSTA_DAGEN_HAST, "täcke") == nil)

	local antal, fel = 0, {}
	for _, hastId in ipairs(UBRFSpel.ordning or {}) do
		local box = Stallet.boxFor(hastId)
		if box then
			antal += 1
			local sadel = Stallet.utrustningsplats(hastId, "sadel")
			local trans = Stallet.utrustningsplats(hastId, "trans")
			if not (sadel and trans) then
				table.insert(fel, hastId .. ": ingen plats")
			else
				--[[ UTÅT MOT GÅNGEN. Boxens kropp ligger [x0, x0+djup] och
					`vetter` säger i vilken ände fronten sitter; saken ska
					hänga på gångsidan OM fronten, aldrig inne i boxen. ]]
				local utat = (sadel.lokal.x - box.front.x) * box.vetter
				if utat <= 0 then
					table.insert(fel, ("%s: %.2f in i boxen"):format(hastId, -utat))
				end
				--[[ ...men inom armlängd från fronten, inte mitt i gången. ]]
				if utat > 0.6 then
					table.insert(fel, ("%s: %.2f m ut i gången"):format(hastId, utat))
				end
				--[[ Sadeln och tränset är TVÅ saker på samma front. ]]
				local dy = math.abs(sadel.lokal.y - trans.lokal.y)
				if dy < 0.5 then
					table.insert(fel, ("%s: sakerna står på samma punkt"):format(hastId))
				end
				--[[ Och båda hänger vid HENNES fack, inte vid grannens. ]]
				if math.abs(sadel.lokal.y - box.lokal.y) > 2.0
					or math.abs(trans.lokal.y - box.lokal.y) > 2.0 then
					table.insert(fel, ("%s: utanför sitt eget fack"):format(hastId))
				end
			end
		end
	end
	check("varje häst med box har sin sadel och sitt träns på fronten",
		antal > 0 and #fel == 0,
		("%d hästar%s"):format(antal, #fel > 0 and (" — " .. table.concat(fel, "; ")) or ""))
end

--[[ ══ EN SESSION MED EN HÄST OCH HENNES UTRUSTNING ══════════════════ ]]
local RIGG_LAGE = vec(0, 0, 0)

local function nyKaraktar(pos)
	local k = Instance.new("Model")
	k.Name = "Karaktar"
	local rot = Instance.new("Part")
	rot.Name = "HumanoidRootPart"
	rot.Size = vec(2, 2, 1)
	rot.CFrame = CFrame.new(pos)
	rot.Parent = k
	local hum = Instance.new("Humanoid")
	hum.Name = "Humanoid"
	hum.Parent = k
	local anim = Instance.new("Animator")
	anim.Name = "Animator"
	anim.Parent = hum
	return k, rot, hum
end

local function nySession(namn, userId)
	__datastore.nollstall()
	Taggar:nollstall()
	Players.PlayerAdded:nollstall()
	Players.PlayerRemoving:nollstall()
	RunService._server = true
	Players._spelare = {}
	SparService._glomHookarForProv()

	local k, rot, hum = nyKaraktar(vec(6, 0, 0))
	local spelare = {
		Name = namn, UserId = userId, Character = k,
		CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny(),
	}
	SparService._glomForProv(spelare)

	SparService.start()
	StallService.start()
	HorseService.start()
	GameplayService.start()

	Players._spelare = { spelare }
	Players.PlayerAdded:Fire(spelare)
	Players.PlayerAdded:slutfor()

	local hastId = StallService.hastIdFor(spelare)
	local modell = nil
	if hastId then
		local h = (UBRFSpel.hastar or {})[hastId]
		modell = HastRigg.bygg(hastId, (h and h.namn) or hastId, CFrame.new(RIGG_LAGE))
		modell.Parent = workspace
		Taggar:AddTag(modell, "Horse")
	end
	return { spelare = spelare, rot = rot, hastId = hastId, modell = modell }
end

local function stadaSession(S)
	Players.PlayerRemoving:Fire(S.spelare)
	Players._spelare = {}
	SparService._glomForProv(S.spelare)
	RunService._server = false
end

--[[ Bygger saken med PRODUKTIONENS byggare och ställer den där provet vill
	ha den. Läget skrivs om — men attributen, hierarkin och taggen är
	produktionens, och det är dem hämtningen prövar. ]]
local function hangUpp(hastId, sort, pos)
	local m = UtrustningRigg.bygg(hastId, sort, CFrame.new(vec(0, 0, 0)))
	if not m then return nil end
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then d.CFrame = CFrame.new(pos) end
	end
	return m
end

--[[ Gör alla faser FÖRE `iordning` färdiga, så att provet står vid just
	det steg som behöver sadeln. ]]
local function framTillIordning(spelare)
	for _, fas in ipairs(Preparation.stegFaser()) do
		if fas.id == "iordning" then break end
		while true do
			local s = GameplayService.stateFor(spelare)
			local m = Preparation.nastaMoment(s, fas.id)
			if not m then break end
			local ok, skal = GameplayService.moment(spelare, fas.id, m.id)
			if not ok then return false, fas.id .. ": " .. tostring(skal) end
		end
	end
	return true, nil
end

--[[ Hovarna först: sadelstegen står inte på tur förrän de fyra hovarna är
	gjorda, och ett "fel tur" hade dolt utrustningsnejet. ]]
local function gorHovarna(spelare)
	for _ = 1, 4 do
		local s = GameplayService.stateFor(spelare)
		local m = Preparation.nastaMoment(s, "iordning")
		if not m or not string.match(m.id, "^hov:") then return m end
		GameplayService.moment(spelare, "iordning", m.id)
	end
	local s = GameplayService.stateFor(spelare)
	return Preparation.nastaMoment(s, "iordning")
end

--[[ ══ 2. SAKEN FINNS, OCH DEN GÅR ATT TA ═══════════════════════════ ]]
print("\n── Hämtningen: saken byggs, hängs upp och plockas ner ──")
do
	local S = nySession("Hamtar", 9301)
	local ok, skal = framTillIordning(S.spelare)
	check("förberedelsen når fram till utrustningsfasen", ok, tostring(skal))

	local sadel = hangUpp(S.hastId, "sadel", vec(6, 0, 0))
	check("sadeln är byggd som en modell i världen",
		sadel ~= nil and sadel:IsA("Model"))
	check("och den vet vems den är och vad den är",
		sadel:GetAttribute("HastId") == S.hastId
			and sadel:GetAttribute("UtrSort") == "sadel",
		tostring(sadel:GetAttribute("HastId")))
	check("den är taggad så klienten hittar den",
		Taggar:HasTag(sadel, "Utrustning"))
	check("och underlägget hänger med sadeln, som på fronten i filmen",
		sadel:FindFirstChild("Underlagg") ~= nil)

	local okH, skalH = GameplayService.hamta(S.spelare, sadel)
	check("spelaren får hämta sin egen sadel", okH, tostring(skalH))
	check("och bär den sedan på kroppen",
		sadel.Parent == S.spelare.Character and sadel:GetAttribute("Bars") == true,
		tostring(sadel.Parent and sadel.Parent.Name))
	check("servern vet att hon bär sadeln",
		Preparation.barUtrustning(GameplayService.stateFor(S.spelare), "sadel"))
	check("men inte tränset — det hänger kvar",
		not Preparation.barUtrustning(GameplayService.stateFor(S.spelare), "trans"))

	--[[ DUBBEL INTERAKTION. Andra trycket ska inte ge en andra sadel. ]]
	local okD, skalD = GameplayService.hamta(S.spelare, sadel)
	check("ett andra tryck på samma sadel ger nej", not okD and skalD == "utr.redan_hamtad",
		tostring(skalD))
	stadaSession(S)
end

--[[ REGELN BAKOM DUBBELTRYCKET, mätt för sig.

	Tjänsten har en egen spärr på SAKEN (`Bars`-attributet), och den fångar
	det vanliga andra trycket — men den fångar det på instansen. Regeln i
	`Preparation` är den andra linjen: två OLIKA sadlar som hör till samma
	häst får inte ge två sadlar i famnen.

	Falsifieringspasset fällde just det här: togs regeln bort blev INGEN rad
	röd, för instansspärren svarade först. En regel som inte går att fälla
	är ingen evidens, och därför mäts den direkt. ]]
print("\n── Regeln bakom dubbeltrycket ──")
do
	local st = Preparation.nyState(Stallet.FORSTA_DAGEN_HAST, 1)
	check("första hämtningen går igenom regeln", (Preparation.taUtrustning(st, "sadel")))
	local ok, skal = Preparation.taUtrustning(st, "sadel")
	check("den andra avvisas av regeln", not ok and skal == "utr.redan_hamtad",
		tostring(skal))
	local ok2, skal2 = Preparation.taUtrustning(st, "täcke")
	check("och något som inte är sadel eller träns avvisas",
		not ok2 and skal2 == "utr.okand_sak", tostring(skal2))
	check("ett nej lämnar ingen halv utrustning efter sig",
		Preparation.barUtrustning(st, "trans") == false)
end

--[[ ══ 3. STEGET GÅR INTE UTAN SAKEN ════════════════════════════════ ]]
print("\n── Nejen: utan sadel finns ingen sadling ──")
do
	local S = nySession("UtanSadel", 9302)
	check("fram till utrustningsfasen", (framTillIordning(S.spelare)))
	local m = gorHovarna(S.spelare)
	check("hovarna är gjorda och ett utrustningssteg står på tur",
		m ~= nil and string.match(m.id, "^utr:") ~= nil,
		m and m.id or "inget moment")

	--[[ HÄR ÄR HELA ORDERN: rätt häst, rätt avstånd, rätt tur — och ändå
		nej, för sadeln hänger kvar på fronten. Det var det här som gick
		igenom förut. ]]
	local ok, skal = GameplayService.moment(S.spelare, "iordning", m.id)
	check("sadelsteget avvisas när sadeln inte är hämtad",
		not ok and skal == "forb.sadeln_inte_hamtad", tostring(skal))

	--[[ ...och nejet ligger EFTER turordningen, inte före: ett senare
		utrustningssteg får fortfarande "fel tur". Annars hade den nya
		regeln kunnat dölja den gamla. ]]
	local senare = nil
	for _, mm in ipairs(Preparation.moment("iordning")) do
		if string.match(mm.id, "^utr:") and mm.id ~= m.id then senare = mm end
	end
	local okS, skalS = GameplayService.moment(S.spelare, "iordning", senare.id)
	check("ett senare utrustningssteg får fortfarande fel tur",
		not okS and skalS == "forb.fel_tur", tostring(skalS))

	--[[ Och med sadeln i handen går samma steg igenom. ]]
	local sadel = hangUpp(S.hastId, "sadel", vec(6, 0, 0))
	check("sadeln hämtas", (GameplayService.hamta(S.spelare, sadel)))
	local ok2, skal2 = GameplayService.moment(S.spelare, "iordning", m.id)
	check("samma steg går igenom med sadeln i handen", ok2, tostring(skal2))
	stadaSession(S)
end

--[[ ══ 4. BARA SADEL MEN INGET TRÄNS ════════════════════════════════ ]]
print("\n── Bara sadel: ledandet stannar vid tränset ──")
do
	local S = nySession("UtanTrans", 9303)
	check("fram till utrustningsfasen", (framTillIordning(S.spelare)))
	local sadel = hangUpp(S.hastId, "sadel", vec(6, 0, 0))
	check("sadeln hämtas", (GameplayService.hamta(S.spelare, sadel)))

	while true do
		local s = GameplayService.stateFor(S.spelare)
		local m = Preparation.nastaMoment(s, "iordning")
		if not m then break end
		local ok, skal = GameplayService.moment(S.spelare, "iordning", m.id)
		if not ok then
			check("iordningställandet går igenom med sadeln", false, tostring(skal))
			break
		end
	end
	local s = GameplayService.stateFor(S.spelare)
	check("iordningställandet är klart", s.klara["iordning"] == true)
	--[[ Sadeln sitter på hästen nu och ska inte hänga kvar på ryttaren. ]]
	check("och sadeln bärs inte längre — den ligger på hästen",
		sadel.Parent == nil or sadel.Parent ~= S.spelare.Character,
		tostring(sadel.Parent and sadel.Parent.Name))

	local m = Preparation.nastaMoment(s, "leda")
	local ok, skal = GameplayService.moment(S.spelare, "leda", m.id)
	check("ledandet avvisas utan träns", not ok and skal == "forb.transet_inte_hamtat",
		tostring(skal))

	--[[ SÖMMEN MOT LEDNINGEN, mätt uttryckligen.

		`leda` bär två villkor som kom i samma runda från två håll: att
		tränset är hämtat, och att hästen faktiskt lämnat sin box
		(`LedService`). Tränset ska komma FÖRST — man tränsar och leder
		sedan. Att provet här inte kräver ett JA utan att nejet BYTER från
		utrustningen till ledningen är hela poängen: det visar att den
		första grinden är passerad, utan att låtsas att hästen är ledd i en
		bänk som inte har någon gång att leda henne i.

		Att ledningen sedan går att göra mäts av `ledning.spec`. ]]
	local trans = hangUpp(S.hastId, "trans", vec(6, 0, 0))
	check("tränset hämtas", (GameplayService.hamta(S.spelare, trans)))
	local ok2, skal2 = GameplayService.moment(S.spelare, "leda", m.id)
	check("med tränset faller ledandet på LEDNINGEN i stället för på utrustningen",
		not ok2 and skal2 == "led.kvar_i_boxen", tostring(skal2))
	--[[ ...och tränset hänger kvar på armen. Det kommer av först när hon
		faktiskt är ledd, alltså när fasen blir klar. ]]
	check("tränset bärs fortfarande — hon är inte ledd än",
		trans.Parent == S.spelare.Character)
	stadaSession(S)
end

--[[ ══ 5. FEL HÄST, FÖR LÅNGT, OCH NÅGOT SOM INTE ÄR UTRUSTNING ═════ ]]
print("\n── Nejen vid själva hämtningen ──")
do
	local S = nySession("Nejen", 9304)

	--[[ FEL HÄST: grannens sadel, inom räckhåll. ]]
	local annan = nil
	for _, id in ipairs(UBRFSpel.ordning or {}) do
		if id ~= S.hastId then annan = id break end
	end
	local grannens = hangUpp(annan, "sadel", vec(6, 0, 0))
	local okF, skalF = GameplayService.hamta(S.spelare, grannens)
	check("grannens sadel går inte att ta", not okF and skalF == "utr.fel_hast",
		tostring(skalF))
	check("och den hänger kvar där den hängde",
		grannens.Parent ~= S.spelare.Character)

	--[[ FÖR LÅNGT: den egna sadeln, men på andra sidan stallet. ]]
	local minSadel = hangUpp(S.hastId, "sadel", vec(600, 0, 0))
	local okA, skalA = GameplayService.hamta(S.spelare, minSadel)
	check("den egna sadeln går inte att ta på avstånd",
		not okA and skalA == "utr.for_langt", tostring(skalA))
	check("och tillståndet står kvar orört efter nejet",
		not Preparation.barUtrustning(GameplayService.stateFor(S.spelare), "sadel"))

	--[[ ...men går att ta när hon gått dit. ]]
	S.rot.CFrame = CFrame.new(vec(600, 0, 0))
	local okN, skalN = GameplayService.hamta(S.spelare, minSadel)
	check("och går att ta när hon gått fram till den", okN, tostring(skalN))

	--[[ NÅGOT SOM INTE ÄR UTRUSTNING. ]]
	local sten = Instance.new("Part")
	sten.Name = "Sten"
	sten.CFrame = CFrame.new(vec(600, 0, 0))
	sten.Parent = workspace
	local okS, skalS = GameplayService.hamta(S.spelare, sten)
	check("en sten är ingen sadel", not okS and skalS == "utr.okand_sak", tostring(skalS))

	local okT, skalT = GameplayService.hamta(S.spelare, "sadel")
	check("och en sträng är inte heller det", not okT and skalT == "utr.okand_sak",
		tostring(skalT))
	stadaSession(S)
end

--[[ ══ 6. HUD:EN VET VAD SOM KRÄVS ══════════════════════════════════ ]]
print("\n── Vyn: HUD:en ska kunna säga VAD som saknas ──")
do
	local S = nySession("Vyn", 9305)
	check("fram till utrustningsfasen", (framTillIordning(S.spelare)))
	gorHovarna(S.spelare)

	local vy = Preparation.vy(GameplayService.stateFor(S.spelare), "preparing", 1, "Jack")
	check("vyn säger att steget kräver sadeln", vy.kraver == "sadel", tostring(vy.kraver))
	check("och att spelaren inte bär den",
		vy.utrustning ~= nil and vy.utrustning.sadel == false)

	local sadel = hangUpp(S.hastId, "sadel", vec(6, 0, 0))
	GameplayService.hamta(S.spelare, sadel)
	local vy2 = Preparation.vy(GameplayService.stateFor(S.spelare), "preparing", 2, "Jack")
	check("efter hämtningen bär hon den i vyn", vy2.utrustning.sadel == true)
	stadaSession(S)
end

if fails > 0 then
	error(string.format("utrustning.spec: %d fel", fails))
end
print("\nutrustning.spec: alla gröna")
