--!nostrict
--[[
	TÄVLINGSKLÄDER — DEN SERVERÄGDA LIVSCYKELN (#248 Fas B).

	Fas A gav katalogen och ordet. Det här provet mäter TJÄNSTEN som tar
	emot ordet, frågar Roblox om posterna är det de utger sig för, och
	först därefter rör en avatar — och som lämnar avataren exakt som den
	låg när något går fel.

	══ VAD SOM FAKTISKT KÖRS HÄR ═════════════════════════════════════

	Avatarsidan körs mot tjänstens EGEN standardadapter, inte mot en
	attrapp. Bänkens `Instance.new` är generisk, så `Shirt`, `Pants`,
	`ShirtTemplate`, `FindFirstChildOfClass` och `Destroy` beter sig som
	riktiga instanser gör i det avseende koden använder dem. Provet mäter
	alltså den kod som kommer att köra i Studio, inte en spegel av den.

	KATALOGSIDAN är däremot alltid en attrapp. Den frågar Roblox över
	nätet, och en Luau-bänk har inget nät. Det är hela skälet till att
	uppslaget ligger bakom en injicerbar adapter: felvägarna — API-fel,
	borttagen post, fel `AssetType` — går annars inte att fälla alls.

	══ VAD SOM INTE MÄTS ═════════════════════════════════════════════

	  · att `MarketplaceService:GetProductInfoAsync` verkligen svarar med
	    `AssetTypeId`, och att en serverskrivning av `Shirt`/`Pants` slår
	    igenom på en riktig avatar. Det är Studio-QA, inte bänk.
	  · att de sex katalog-ID:na existerar. Fas A:s prov mäter att TALEN
	    kom in i rätt fält; att de är rätt står på produktägarens
	    verifiering.

	Provet skriver inte av ett enda asset-id. Det läser dem ur katalogen,
	för att katalogen ska vara enda källan också här — och för att
	`tools/kolla-tavlingsklader.py` ska fälla den dag någon frestas.

	Kör: python3 roblox/tests/build.py tests/tavlingsklader-session.spec.luau
	     && luau roblox/tests/.build/tavlingsklader-session.spec.luau
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

local T = Tavlingsklader
local S = TavlingskladerService
local Players = game:GetService("Players")

--[[ ══ BÄNKENS VÄRLD ════════════════════════════════════════════════

	En karaktär är en `Model` med en `Humanoid` och — om provet vill det
	— ett `Shirt` och ett `Pants`. Att lagren är VALFRIA är inte
	bekvämlighet: kontraktet kräver att ett lager som ursprungligen
	SAKNADES tas bort igen vid återställning, och det går bara att mäta
	på en avatar som faktiskt saknar det. ]]
local function nyKaraktar(shirtMall, pantsMall)
	local k = Instance.new("Model")
	k.Name = "Karaktar"
	local hum = Instance.new("Humanoid")
	hum.Name = "Humanoid"
	hum.Parent = k
	if shirtMall then
		local s = Instance.new("Shirt")
		s.Name = "Shirt"
		s.ShirtTemplate = shirtMall
		s.Parent = k
	end
	if pantsMall then
		local p = Instance.new("Pants")
		p.Name = "Pants"
		p.PantsTemplate = pantsMall
		p.Parent = k
	end
	return k, hum
end

local __nastaId = 100
local function nySpelare(namn, shirtMall, pantsMall)
	__nastaId += 1
	local k, hum = nyKaraktar(shirtMall, pantsMall)
	local spelare = {
		Name = namn, UserId = __nastaId, Character = k,
		CharacterAdded = __signal_ny(),
		CharacterRemoving = __signal_ny(),
	}
	return spelare, k, hum
end

--[[ Läser av vad en avatar FAKTISKT bär. Returnerar nil för ett lager
	som inte finns — skillnaden mellan "saknas" och "finns men är tom" är
	precis den kontraktet handlar om. ]]
local function buren(karaktar)
	local s = karaktar:FindFirstChildOfClass("Shirt")
	local p = karaktar:FindFirstChildOfClass("Pants")
	return (s and s.ShirtTemplate or nil), (p and p.PantsTemplate or nil)
end

--[[ ══ KATALOGATTRAPPEN ═════════════════════════════════════════════

	Svarar det provet säger åt den att svara, räknar sina anrop, och kan
	— när provet vill mäta vad som händer MITT I ett uppslag — pausa med
	`coroutine.yield`. Den pausen är inte en konstruktion för provets
	skull: `GetProductInfoAsync` yieldar, och allt som kan hända medan
	den yieldar är precis det kontraktets sista punkt handlar om. ]]
local function nyKatalog(svar, pausa)
	local a = { anrop = 0, id = {} }
	a.assetTyp = function(assetId)
		a.anrop += 1
		table.insert(a.id, assetId)
		if pausa then coroutine.yield() end
		local s = svar[assetId]
		if s == nil then return { ok = false, fel = "okand post" } end
		return s
	end
	return a
end

--[[ Ett svar som säger "den här posten är ett giltigt plagg av rätt
	sort" för varje id i katalogen. Byggs UR katalogen. ]]
local function allaRatta()
	local svar = {}
	for _, set in ipairs(T.alla()) do
		svar[set.shirtAssetId] = { ok = true, assetTypeId = T.ASSETTYPE_SHIRT }
		svar[set.pantsAssetId] = { ok = true, assetTypeId = T.ASSETTYPE_PANTS }
	end
	return svar
end

local function tjanstMedKatalog(svar, pausa)
	local katalog = nyKatalog(svar, pausa)
	return S.nya({ katalog = katalog }), katalog
end

--[[ Nollställer de signaler som är GLOBALA i bänken. `PlayerRemoving`
	är en enda signal för hela körningen; utan nollställning kör block
	fem med block ettas lyssnare kvar, och då mäter provet spöken. ]]
local function rent()
	Players.PlayerRemoving:nollstall()
end

print("")
print("TÄVLINGSKLÄDER — SERVERÄGD LIVSCYKEL (#248 Fas B)")

--[[ ══ 1. MALLENS FORM ══════════════════════════════════════════════

	En enda mätning av konventionen, skriven ur Robloxs egen
	dokumentation: `Shirt.ShirtTemplate` är ett ContentId, och formen är
	`rbxassetid://<id>`. Resten av provet jämför mot `S.mall(...)` i
	stället för att skriva av formen gång på gång — annars hade provet
	burit en andra sanning om den. ]]
print("\n-- Mallen --")
do
	local vit = T.set("white")
	check("mallen är Robloxs ContentId-form",
		S.mall(vit.shirtAssetId) == ("rbxassetid://%d"):format(vit.shirtAssetId),
		S.mall(vit.shirtAssetId))
end

--[[ ══ 2. DE TRE SETEN APPLICERAS UR KATALOGEN ══════════════════════ ]]
print("\n-- white, pink och oak ur katalogen --")
for _, setId in ipairs(T.idn()) do
	rent()
	local tjanst = tjanstMedKatalog(allaRatta())
	local spelare, karaktar = nySpelare("Ryttare", "rbxassetid://777001", "rbxassetid://777002")
	local ok = tjanst.starta(spelare, setId)
	local s, p = buren(karaktar)
	local set = T.set(setId)
	check(("%s appliceras på båda lagren"):format(setId),
		ok and s == S.mall(set.shirtAssetId) and p == S.mall(set.pantsAssetId),
		("%s · %s"):format(tostring(s), tostring(p)))
	check(("%s är aktivt set på spelaren"):format(setId),
		tjanst.aktivt(spelare) == setId, tostring(tjanst.aktivt(spelare)))
end

--[[ ══ 3. GRÄNSEN: ORD IN, ALDRIG ASSET-ID ══════════════════════════

	Kontraktet: "Klientdata får aldrig innehålla asset-id." Mätningen är
	inte att ett asset-id avvisas — det är att det avvisas UTAN att någon
	fråga ens ställdes till katalogen. Ett nej som kommer efter ett
	nätanrop är en gräns som redan har läckt. ]]
print("\n-- Endast white/pink/oak släpps in --")
do
	local rattAssetId = T.set("white").shirtAssetId
	local avvisas = {
		{ "okänt id", "blue" },
		{ "rått asset-id som tal", rattAssetId },
		{ "rått asset-id som sträng", tostring(rattAssetId) },
		{ "fel skiftläge", "White" },
		{ "tabell", { id = "white" } },
		{ "inget id alls", nil },
	}
	for _, fall in ipairs(avvisas) do
		rent()
		local tjanst, katalog = tjanstMedKatalog(allaRatta())
		local spelare, karaktar = nySpelare("Ryttare", "rbxassetid://777001", "rbxassetid://777002")
		local ok, utfall = tjanst.starta(spelare, fall[2])
		local s, p = buren(karaktar)
		check(("%s nekas"):format(fall[1]), ok == false, tostring(utfall))
		check(("%s rör inte avataren"):format(fall[1]),
			s == "rbxassetid://777001" and p == "rbxassetid://777002")
		check(("%s frågar aldrig Roblox"):format(fall[1]),
			katalog.anrop == 0, ("%d anrop"):format(katalog.anrop))
		check(("%s lämnar ingen session"):format(fall[1]),
			tjanst.aktivt(spelare) == nil and #tjanst.aktivaSpelare() == 0)
	end
end

--[[ ══ 4. FAIL CLOSED: POSTEN MÅSTE VARA DET DEN UTGER SIG FÖR ══════

	Sex sätt ett uppslag kan gå fel, och samma krav på alla sex:
	avataren ska vara EXAKT som den låg. Att den ANDRA postens fel också
	lämnar avataren orörd är den skarpa av dem — den mäter att båda
	posterna verifieras innan den första skrivs. ]]
print("\n-- Fel post lämnar avataren intakt --")
do
	local vit = T.set("white")
	local fall = {
		{ "fel AssetType på tröjan", function(svar)
			svar[vit.shirtAssetId] = { ok = true, assetTypeId = T.ASSETTYPE_PANTS }
		end },
		{ "fel AssetType på byxan", function(svar)
			svar[vit.pantsAssetId] = { ok = true, assetTypeId = T.ASSETTYPE_SHIRT }
		end },
		{ "API-fel på tröjan", function(svar)
			svar[vit.shirtAssetId] = { ok = false, fel = "HTTP 500" }
		end },
		{ "API-fel på byxan", function(svar)
			svar[vit.pantsAssetId] = { ok = false, fel = "HTTP 500" }
		end },
		{ "posten finns inte", function(svar)
			svar[vit.shirtAssetId] = nil
		end },
		{ "modererad post svarar utan typ", function(svar)
			svar[vit.pantsAssetId] = { ok = true }
		end },
	}
	for _, f in ipairs(fall) do
		rent()
		local svar = allaRatta()
		f[2](svar)
		local tjanst = tjanstMedKatalog(svar)
		local spelare, karaktar = nySpelare("Ryttare", "rbxassetid://777001", "rbxassetid://777002")
		local ok, utfall = tjanst.starta(spelare, "white")
		local s, p = buren(karaktar)
		check(("%s nekas"):format(f[1]), ok == false, tostring(utfall))
		check(("%s lämnar avataren exakt intakt"):format(f[1]),
			s == "rbxassetid://777001" and p == "rbxassetid://777002",
			("%s · %s"):format(tostring(s), tostring(p)))
		check(("%s lämnar ingen session"):format(f[1]),
			tjanst.aktivt(spelare) == nil)
	end
end

--[[ En avatar som saknar båda lagren ska inte ha FÅTT dem av ett
	misslyckat försök. Ett tomt `Shirt` som blir kvar är precis den
	halvklädda spelaren kontraktet förbjuder. ]]
do
	rent()
	local svar = allaRatta()
	svar[T.set("white").pantsAssetId] = { ok = false, fel = "borttagen" }
	local tjanst = tjanstMedKatalog(svar)
	local spelare, karaktar = nySpelare("Naken")
	tjanst.starta(spelare, "white")
	check("ett nekat försök skapar inga tomma lager",
		karaktar:FindFirstChildOfClass("Shirt") == nil
			and karaktar:FindFirstChildOfClass("Pants") == nil)
end

--[[ ══ 5. ROLLBACK NÄR SKRIVNINGEN FALLER ═══════════════════════════

	Uppslaget kan säga ja och skrivningen ändå falla — karaktären hinner
	rivas, motorn vägrar. Attrappen här är avatarsidan, och det är enda
	stället i provet den är det: en skrivning som faller går inte att
	framkalla på en instans som lyder. ]]
print("\n-- Andra lagret faller, första rullas tillbaka --")
local function avatarSomFaller(falandeKlass)
	local standard = S.STANDARD.avatar
	return {
		lager = standard.lager,
		lasMall = standard.lasMall,
		taBort = standard.taBort,
		skrivMall = function(karaktar, klass, egenskap, mall)
			if klass == falandeKlass then return false end
			return standard.skrivMall(karaktar, klass, egenskap, mall)
		end,
	}
end

do
	rent()
	local tjanst = S.nya({ katalog = nyKatalog(allaRatta()),
		avatar = avatarSomFaller("Pants") })
	local spelare, karaktar = nySpelare("Ryttare", "rbxassetid://777001", "rbxassetid://777002")
	local ok, utfall = tjanst.starta(spelare, "white")
	local s, p = buren(karaktar)
	check("skrivfel på byxan nekas", ok == false, tostring(utfall))
	check("tröjan rullas tillbaka till sitt exakta värde",
		s == "rbxassetid://777001", tostring(s))
	check("byxan är orörd", p == "rbxassetid://777002", tostring(p))
	check("ingen session lämnas efter ett skrivfel", tjanst.aktivt(spelare) == nil)
end

do
	rent()
	local tjanst = S.nya({ katalog = nyKatalog(allaRatta()),
		avatar = avatarSomFaller("Pants") })
	local spelare, karaktar = nySpelare("Naken")
	tjanst.starta(spelare, "white")
	check("ett lager som SKAPADES av försöket tas bort igen vid rollback",
		karaktar:FindFirstChildOfClass("Shirt") == nil,
		tostring(karaktar:FindFirstChildOfClass("Shirt")))
end

--[[ ══ 6. ÅTERSTÄLLNING ═════════════════════════════════════════════ ]]
print("\n-- Avslut återställer exakt ursprungsläget --")
do
	rent()
	local tjanst = tjanstMedKatalog(allaRatta())
	local spelare, karaktar = nySpelare("Ryttare", "rbxassetid://777001", "rbxassetid://777002")
	tjanst.starta(spelare, "pink")
	tjanst.avsluta(spelare, "tavling_slut")
	local s, p = buren(karaktar)
	check("båda lagren får tillbaka sina exakta mallar",
		s == "rbxassetid://777001" and p == "rbxassetid://777002",
		("%s · %s"):format(tostring(s), tostring(p)))
	check("sessionen är borta", tjanst.aktivt(spelare) == nil
		and #tjanst.aktivaSpelare() == 0)
end

do
	rent()
	local tjanst = tjanstMedKatalog(allaRatta())
	local spelare, karaktar = nySpelare("Naken")
	tjanst.starta(spelare, "oak")
	local s1 = buren(karaktar)
	tjanst.avsluta(spelare, "tavling_slut")
	local s, p = buren(karaktar)
	check("ett ursprungligen saknat lager fanns under ritten",
		s1 == S.mall(T.set("oak").shirtAssetId), tostring(s1))
	check("ett ursprungligen saknat Shirt är BORTA igen, inte tomt",
		karaktar:FindFirstChildOfClass("Shirt") == nil and s == nil)
	check("ett ursprungligen saknat Pants är BORTA igen, inte tomt",
		karaktar:FindFirstChildOfClass("Pants") == nil and p == nil)
end

do
	rent()
	local tjanst = tjanstMedKatalog(allaRatta())
	local spelare, karaktar = nySpelare("Halv", "rbxassetid://777001", nil)
	tjanst.starta(spelare, "white")
	tjanst.avsluta(spelare, "avbrott")
	local s, p = buren(karaktar)
	check("blandat utgångsläge återställs lager för lager",
		s == "rbxassetid://777001" and p == nil
			and karaktar:FindFirstChildOfClass("Pants") == nil,
		("%s · %s"):format(tostring(s), tostring(p)))
end

--[[ ══ 7. IDEMPOTENS ════════════════════════════════════════════════

	Den farliga dubbleringen är inte att andra anropet gör något dumt —
	det är att det SPARAR OM ursprungsläget. Då blir tävlingskläderna
	spelarens original, och hon får aldrig tillbaka sina egna. ]]
print("\n-- Upprepade anrop --")
do
	rent()
	local tjanst, katalog = tjanstMedKatalog(allaRatta())
	local spelare, karaktar = nySpelare("Ryttare", "rbxassetid://777001", "rbxassetid://777002")
	tjanst.starta(spelare, "white")
	local efterForsta = katalog.anrop
	local ok2, utfall2 = tjanst.starta(spelare, "white")
	check("andra starta med samma set är ett no-op", ok2 == true, tostring(utfall2))
	check("andra starta frågar inte Roblox igen",
		katalog.anrop == efterForsta, ("%d -> %d"):format(efterForsta, katalog.anrop))
	tjanst.avsluta(spelare, "slut")
	local s, p = buren(karaktar)
	check("dubbel start skriver INTE om ursprungsläget",
		s == "rbxassetid://777001" and p == "rbxassetid://777002",
		("%s · %s"):format(tostring(s), tostring(p)))
end

do
	rent()
	local tjanst = tjanstMedKatalog(allaRatta())
	local spelare, karaktar = nySpelare("Ryttare", "rbxassetid://777001", "rbxassetid://777002")
	tjanst.starta(spelare, "white")
	tjanst.avsluta(spelare, "slut")
	--[[ Andra avslutet får inte skriva igen. Vi ändrar avataren emellan:
		om avslutet ändå återställer syns det som att spelarens egen
		ändring blir överskriven. ]]
	karaktar:FindFirstChildOfClass("Shirt").ShirtTemplate = "rbxassetid://777009"
	local ok, utfall = tjanst.avsluta(spelare, "slut igen")
	local s = buren(karaktar)
	check("andra avsluta är ett ofarligt no-op", ok == true, tostring(utfall))
	check("andra avsluta återställer inte en andra gång",
		s == "rbxassetid://777009", tostring(s))
end

do
	rent()
	local tjanst = tjanstMedKatalog(allaRatta())
	local spelare, karaktar = nySpelare("Ryttare", "rbxassetid://777001", "rbxassetid://777002")
	tjanst.starta(spelare, "white")
	local ok = tjanst.starta(spelare, "oak")
	local s, p = buren(karaktar)
	check("byte av set mitt i sessionen byter båda lagren",
		ok and s == S.mall(T.set("oak").shirtAssetId)
			and p == S.mall(T.set("oak").pantsAssetId),
		("%s · %s"):format(tostring(s), tostring(p)))
	tjanst.avsluta(spelare, "slut")
	local s2, p2 = buren(karaktar)
	check("bytet gör inte white till spelarens nya ursprungsläge",
		s2 == "rbxassetid://777001" and p2 == "rbxassetid://777002",
		("%s · %s"):format(tostring(s2), tostring(p2)))
end

--[[ ══ 8. RESPAWN, DÖD OCH FRÅNKOPPLING ═════════════════════════════ ]]
print("\n-- Livscykeln avslutar säkert --")
do
	rent()
	local tjanst = tjanstMedKatalog(allaRatta())
	local spelare, gammal, humanoid = nySpelare("Ryttare", "rbxassetid://777001", "rbxassetid://777002")
	tjanst.starta(spelare, "white")
	humanoid.Health = 0
	check("döden avslutar sessionen", tjanst.aktivt(spelare) == nil)
	local s, p = buren(gammal)
	check("döden återställer den kropp som bar kläderna",
		s == "rbxassetid://777001" and p == "rbxassetid://777002",
		("%s · %s"):format(tostring(s), tostring(p)))
end

do
	rent()
	local tjanst = tjanstMedKatalog(allaRatta())
	local spelare = nySpelare("Ryttare", "rbxassetid://777001", "rbxassetid://777002")
	tjanst.starta(spelare, "white")
	--[[ Respawn: ny kropp, och den nya kroppen bär spelarens EGNA kläder
		— Roblox klär henne själv. Tjänsten får inte röra dem. ]]
	local ny = nyKaraktar("rbxassetid://777050", "rbxassetid://777051")
	spelare.Character = ny
	spelare.CharacterAdded:Fire(ny)
	check("respawn avslutar sessionen", tjanst.aktivt(spelare) == nil)
	local s, p = buren(ny)
	check("respawn skriver INTE på den nya avataren",
		s == "rbxassetid://777050" and p == "rbxassetid://777051",
		("%s · %s"):format(tostring(s), tostring(p)))
end

do
	rent()
	local tjanst = tjanstMedKatalog(allaRatta())
	local spelare, karaktar = nySpelare("Ryttare", "rbxassetid://777001", "rbxassetid://777002")
	tjanst.starta(spelare, "white")
	spelare.CharacterRemoving:Fire(karaktar)
	check("CharacterRemoving avslutar sessionen", tjanst.aktivt(spelare) == nil)
end

do
	rent()
	local tjanst = tjanstMedKatalog(allaRatta())
	local spelare = nySpelare("Ryttare", "rbxassetid://777001", "rbxassetid://777002")
	tjanst.starta(spelare, "white")
	check("sessionen håller lyssnare medan den lever",
		#Players.PlayerRemoving._lyssnare == 1
			and #spelare.CharacterAdded._lyssnare == 1
			and #spelare.CharacterRemoving._lyssnare == 1)
	Players.PlayerRemoving:Fire(spelare)
	check("PlayerRemoving tömmer serverstate",
		tjanst.aktivt(spelare) == nil and #tjanst.aktivaSpelare() == 0)
	check("PlayerRemoving kopplar bort ALLA lyssnare",
		#Players.PlayerRemoving._lyssnare == 0
			and #spelare.CharacterAdded._lyssnare == 0
			and #spelare.CharacterRemoving._lyssnare == 0,
		("%d · %d · %d"):format(#Players.PlayerRemoving._lyssnare,
			#spelare.CharacterAdded._lyssnare, #spelare.CharacterRemoving._lyssnare))
end

do
	rent()
	local tjanst = tjanstMedKatalog(allaRatta())
	local spelare = nySpelare("Ryttare", "rbxassetid://777001", "rbxassetid://777002")
	tjanst.starta(spelare, "white")
	tjanst.avsluta(spelare, "slut")
	check("ett normalt avslut lämnar inga lyssnare kvar heller",
		#Players.PlayerRemoving._lyssnare == 0
			and #spelare.CharacterAdded._lyssnare == 0)
end

--[[ En annan spelares frånkoppling får inte städa min session. ]]
do
	rent()
	local tjanst = tjanstMedKatalog(allaRatta())
	local a = nySpelare("A", "rbxassetid://777001", "rbxassetid://777002")
	local b = nySpelare("B", "rbxassetid://777003", "rbxassetid://777004")
	tjanst.starta(a, "white")
	Players.PlayerRemoving:Fire(b)
	check("en annan spelares frånkoppling rör inte min session",
		tjanst.aktivt(a) == "white", tostring(tjanst.aktivt(a)))
end

--[[ ══ 9. TVÅ SPELARE ═══════════════════════════════════════════════ ]]
print("\n-- Två ryttare, två set --")
do
	rent()
	local tjanst = tjanstMedKatalog(allaRatta())
	local a, ka = nySpelare("A", "rbxassetid://777001", "rbxassetid://777002")
	local b, kb = nySpelare("B", "rbxassetid://777003", "rbxassetid://777004")
	tjanst.starta(a, "white")
	tjanst.starta(b, "pink")
	local sa = buren(ka)
	local sb = buren(kb)
	check("båda bär sitt eget set",
		sa == S.mall(T.set("white").shirtAssetId)
			and sb == S.mall(T.set("pink").shirtAssetId),
		("%s · %s"):format(tostring(sa), tostring(sb)))
	check("tjänsten håller två sessioner", #tjanst.aktivaSpelare() == 2)
	tjanst.avsluta(a, "slut")
	local sa2, pa2 = buren(ka)
	local sb2 = buren(kb)
	check("A återställs", sa2 == "rbxassetid://777001" and pa2 == "rbxassetid://777002")
	check("B rörs inte av A:s avslut",
		sb2 == S.mall(T.set("pink").shirtAssetId) and tjanst.aktivt(b) == "pink")
end

--[[ ══ 10. DET GAMLA SVARET SOM KOMMER FÖR SENT ═════════════════════

	Uppslaget yieldar. Under den pausen kan allt hända — spelaren dör,
	respawnar, loggar ut, eller kontexten avslutar. Kravet är att den
	tråd som VAKNAR då inte får skriva på någonting.

	Det här är provet jag lovade i kvittensen att falsifiera hårdast:
	ett prov som bara läser en flagga hade godkänt en tjänst som skriver
	ändå. Därför mäts AVATAREN, inte tjänstens självbild. ]]
print("\n-- Ett gammalt uppslag som svarar för sent --")
do
	rent()
	local tjanst = tjanstMedKatalog(allaRatta(), true)
	local spelare = nySpelare("Ryttare", "rbxassetid://777001", "rbxassetid://777002")
	local trad = coroutine.create(function() return tjanst.starta(spelare, "white") end)
	coroutine.resume(trad)
	--[[ Mitt i uppslaget: ny kropp. ]]
	local ny = nyKaraktar("rbxassetid://777050", "rbxassetid://777051")
	spelare.Character = ny
	spelare.CharacterAdded:Fire(ny)
	while coroutine.status(trad) == "suspended" do coroutine.resume(trad) end
	local s, p = buren(ny)
	check("ett uppslag som svarar efter respawn skriver inte på nya avataren",
		s == "rbxassetid://777050" and p == "rbxassetid://777051",
		("%s · %s"):format(tostring(s), tostring(p)))
	check("och lämnar ingen session", tjanst.aktivt(spelare) == nil)
end

do
	rent()
	local tjanst = tjanstMedKatalog(allaRatta(), true)
	local spelare, karaktar = nySpelare("Ryttare", "rbxassetid://777001", "rbxassetid://777002")
	local trad = coroutine.create(function() return tjanst.starta(spelare, "white") end)
	coroutine.resume(trad)
	tjanst.avsluta(spelare, "avbrott")
	while coroutine.status(trad) == "suspended" do coroutine.resume(trad) end
	local s, p = buren(karaktar)
	check("ett uppslag som svarar efter avslut skriver inte alls",
		s == "rbxassetid://777001" and p == "rbxassetid://777002",
		("%s · %s"):format(tostring(s), tostring(p)))
	check("och lämnar ingen session", tjanst.aktivt(spelare) == nil)
end

--[[ Ett setbyte som avbryts mitt i uppslaget ska inte heller skriva —
	och avbrottet ska ge tillbaka ursprungskläderna, inte det halva
	bytet. ]]
do
	rent()
	local tjanst = tjanstMedKatalog(allaRatta(), true)
	local spelare, karaktar = nySpelare("Ryttare", "rbxassetid://777001", "rbxassetid://777002")
	--[[ Första starten körs klart: attrappen pausar, så den måste
		drivas färdigt i en egen tråd den här gången. ]]
	local forsta = coroutine.create(function() return tjanst.starta(spelare, "white") end)
	while coroutine.status(forsta) == "suspended" do coroutine.resume(forsta) end
	local trad = coroutine.create(function() return tjanst.starta(spelare, "oak") end)
	coroutine.resume(trad)
	tjanst.avsluta(spelare, "avbrott")
	while coroutine.status(trad) == "suspended" do coroutine.resume(trad) end
	local s, p = buren(karaktar)
	check("ett avbrutet setbyte lämnar ursprungskläderna",
		s == "rbxassetid://777001" and p == "rbxassetid://777002",
		("%s · %s"):format(tostring(s), tostring(p)))
	check("och ingen session", tjanst.aktivt(spelare) == nil)
end

--[[ ══ 11. ÄGARSKAPETS GRÄNS ════════════════════════════════════════

	"Ändra endast klassiska Shirt/Pants." Mätningen är inte att koden ser
	ut att låta bli — det är att INGEN annan instans skapas under en hel
	livscykel. `Instance.new` byts ut och räknar. ]]
print("\n-- Ingenting annat än Shirt och Pants --")
do
	rent()
	local tjanst = tjanstMedKatalog(allaRatta())
	local spelare, karaktar = nySpelare("Naken")
	local hatt = Instance.new("Accessory")
	hatt.Name = "Hjalm"
	hatt.Parent = karaktar
	local skapade = {}
	local riktig = Instance.new
	Instance.new = function(klass)
		table.insert(skapade, klass)
		return riktig(klass)
	end
	tjanst.starta(spelare, "white")
	tjanst.avsluta(spelare, "slut")
	Instance.new = riktig
	local bara = true
	for _, klass in ipairs(skapade) do
		if klass ~= "Shirt" and klass ~= "Pants" then bara = false end
	end
	check("bara Shirt och Pants skapas under en hel livscykel",
		bara and #skapade == 2, table.concat(skapade, ", "))
	check("hjälmen sitter kvar orörd",
		karaktar:FindFirstChild("Hjalm") == hatt)
end

--[[ ══ 12. INGEN KARAKTÄR ═══════════════════════════════════════════ ]]
print("\n-- Utan kropp finns ingenting att klä --")
do
	rent()
	local tjanst, katalog = tjanstMedKatalog(allaRatta())
	local spelare = nySpelare("Ryttare", "rbxassetid://777001", "rbxassetid://777002")
	spelare.Character = nil
	local ok, utfall = tjanst.starta(spelare, "white")
	check("starta utan karaktär nekas", ok == false, tostring(utfall))
	check("och frågar inte Roblox", katalog.anrop == 0)
	local ok2 = tjanst.avsluta(spelare, "slut")
	check("avsluta utan session är ofarligt", ok2 == true)
end

print("")
if fails > 0 then
	print(string.format("%d mätning(ar) föll.", fails))
else
	print("Alla mätningar gick igenom.")
end
