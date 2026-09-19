--!nostrict
--[[
	TAKTEN FRAMFÖR FJÄRRFUNKTIONERNA (#259 Gate 1A, ur #258 P1-2).

	De tretton klient→server-RemoteFunctions hade ingen taktbegränsning
	alls. De två klient→server-RemoteEvents hade fullödiga skopor sedan
	#169 och #233 — mönstret fanns, men hade inte nått fjärrFUNKTIONERNA.

	══ VAD SOM FAKTISKT KÖRS HÄR ═════════════════════════════════════

	Två nivåer, och den andra är den som betyder något.

	  1. `Skopa` själv: skur, påfyllning, isolering, städning.
	  2. De två KONKRETA amplifieringsvägarna ur #258, genom RIKTIGA
	     `OnServerInvoke`-handlare som `LedService.start` och
	     `GameplayService.start` registrerat. Provet anropar alltså exakt
	     den funktion nätet hade nått — inte en avskrift av regeln.

	Nivå 2 är hela skälet till att specen ligger på integrationsbunten.
	En grind som bara mäter räknaren hade varit grön även om ingen
	handlare vore lindad.

	══ TIDEN ════════════════════════════════════════════════════════

	Bänken har ingen riktig tid. `os.clock` går i CPU-tid, och tio anrop
	i rad hinner inte fylla på mätbart. Påfyllningen mäts därför genom
	`Skopa._satKlockaForProv` — samma skäl som katalogadaptern i
	`TavlingskladerService` finns för: utan den vore påfyllningen ett
	påstående i en kommentar.

	Kör: python3 roblox/tests/build.py tests/takt.spec.luau
	     && luau roblox/tests/.build/takt.spec.luau
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

local S = Skopa
local Players = game:GetService("Players")

--[[ ══ BÄNKENS VÄRLD ════════════════════════════════════════════════ ]]

local __nastaId = 500
local function nySpelare(namn)
	__nastaId += 1
	return { Name = namn, UserId = __nastaId,
		CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }
end

--[[ En klocka provet äger. Stegas för hand; ingen riktig tid går. ]]
local nu = 0
local function satTid(t) nu = t end
local function ga(sekunder) nu += sekunder end

--[[ Varje block börjar från noll: tömda hinkar, nollställda signaler och
	en tid som inte bär förra blockets sekunder. ]]
local function rent()
	S._nollstallForProv()
	S._satKlockaForProv(function() return nu end)
	satTid(0)
	Players.PlayerRemoving:nollstall()
	__varningar = {}
end

--[[ Hur många anrop släpps igenom i en obruten skur? ]]
local function skur(spelare, handling, forsok)
	local slappta = 0
	for _ = 1, forsok do
		if S.slapp(spelare, handling) then slappta += 1 end
	end
	return slappta
end

local function varningar(prefix)
	local n = 0
	for _, rad in ipairs(__varningar) do
		if string.sub(rad, 1, #prefix) == prefix then n += 1 end
	end
	return n
end

print("")
print("TAKTEN FRAMFÖR FJÄRRFUNKTIONERNA (#259 Gate 1A)")

--[[ ══ 1. GRÄNSERNA ÄR DEKLARATIVA OCH TÄCKER ALLA TRETTON ══════════

	Ordern kräver en enda källsanning. Mätningen är inte att tabellen
	finns — det är att VARJE handling som lindats har en gräns, och att
	listan här inte är en andra kopia: namnen kommer ur `S.GRANSER`. ]]
print("\n-- Gränserna --")
do
	local handlingar = {
		"MountRequest", "DismountRequest", "RidaNu", "SadlaHast", "TransaHast",
		"PreparationMoment", "PreparationSvar", "PassMoment",
		"PreparationStep", "PreparationHello", "LedBorja", "LedSlapp", "MinHast",
	}
	check("alla tretton handlingar har en egen gräns",
		#handlingar == 13, ("%d"):format(#handlingar))
	local saknas = {}
	for _, h in ipairs(handlingar) do
		if S.GRANSER[h] == nil then table.insert(saknas, h) end
	end
	check("ingen av dem faller tillbaka på standarden",
		#saknas == 0, table.concat(saknas, ", "))
	local rimliga = true
	local trasig = nil
	for namn, g in pairs(S.GRANSER) do
		if type(g.tak) ~= "number" or type(g.pafyll) ~= "number"
			or g.tak < 1 or g.pafyll <= 0 then
			rimliga = false
			trasig = namn
		end
	end
	check("varje gräns har ett tak ≥ 1 och en påfyllning > 0",
		rimliga, tostring(trasig))
	--[[ En okänd handling ska skyddas, inte släppas fri. Det är hela
		skälet till att standarden finns. ]]
	check("en okänd handling får standardgränsen",
		S.grans("HandlingSomInteFinns").tak == S.STANDARD.tak)
end

--[[ ══ 2. SKUREN AVVISAS ════════════════════════════════════════════ ]]
print("\n-- Skur och spam avvisas --")
do
	rent()
	local a = nySpelare("A")
	local tak = S.GRANSER.LedBorja.tak
	local slappta = skur(a, "LedBorja", 50)
	check("en skur på 50 anrop släpper igenom exakt takets antal",
		slappta == tak, ("%d av 50, tak %d"):format(slappta, tak))
	check("och det 51:a anropet nekas också",
		S.slapp(a, "LedBorja") == false)
end

do
	rent()
	local a = nySpelare("A")
	--[[ Handlingarna har EGNA hinkar. En tömd skötselskopa får inte låsa
		uppsittningen — det vore en gräns som straffar fel handling. ]]
	skur(a, "PreparationMoment", 100)
	check("en tömd hink låser inte en annan handling",
		S.slapp(a, "MountRequest") == true)
end

--[[ ══ 3. PÅFYLLNINGEN ══════════════════════════════════════════════ ]]
print("\n-- Polletterna fylls på över tid --")
do
	rent()
	local a = nySpelare("A")
	local g = S.GRANSER.LedBorja
	skur(a, "LedBorja", g.tak + 5)
	check("hinken är tom", S.slapp(a, "LedBorja") == false)

	--[[ En sekund ger `pafyll` polletter. Med pafyll = 1 betyder det
		exakt ett anrop till, och inte två. ]]
	ga(1)
	check("efter en sekund släpps ETT anrop igenom",
		S.slapp(a, "LedBorja") == true)
	check("men inte två", S.slapp(a, "LedBorja") == false)

	--[[ Och påfyllningen har ett TAK. Att stå still i en timme ska inte
		ge en skur på tusen. ]]
	ga(3600)
	local slappta = skur(a, "LedBorja", 100)
	check("en lång paus fyller på till taket, inte förbi det",
		slappta == g.tak, ("%d, tak %d"):format(slappta, g.tak))
end

--[[ ══ 4. EN SPELARES BUDGET RÖR INTE EN ANNANS ═════════════════════ ]]
print("\n-- Budgetarna är per spelare --")
do
	rent()
	local a = nySpelare("A")
	local b = nySpelare("B")
	skur(a, "LedBorja", 100)
	check("A har tömt sin hink", S.slapp(a, "LedBorja") == false)
	local tak = S.GRANSER.LedBorja.tak
	check("B har full hink kvar",
		skur(b, "LedBorja", tak) == tak)
	check("och A är fortfarande tom efter att B förbrukat sin",
		S.slapp(a, "LedBorja") == false)
end

--[[ ══ 5. STÄDNINGEN ════════════════════════════════════════════════ ]]
print("\n-- Städningen vid frånkoppling --")
do
	rent()
	S.start()
	local a = nySpelare("A")
	local b = nySpelare("B")
	skur(a, "LedBorja", 2)
	skur(b, "MountRequest", 2)
	check("två spelare håller budget", S.kvarvarande() == 2,
		("%d"):format(S.kvarvarande()))
	Players.PlayerRemoving:Fire(a)
	check("A:s budget är borta efter frånkoppling",
		S.kvarvarande() == 1, ("%d"):format(S.kvarvarande()))
	Players.PlayerRemoving:Fire(b)
	check("och när båda gått är registret tomt",
		S.kvarvarande() == 0, ("%d"):format(S.kvarvarande()))
end

do
	rent()
	S.start()
	local a = nySpelare("A")
	--[[ Även avslagsräknaren ska bort. Den är en egen Player-nycklad
		tabell, och en tabell som aldrig töms är samma läcka en våning
		ned — precis det #258 pekade ut på andra ställen. ]]
	skur(a, "RidaNu", 50)
	check("en spelare som nekats håller fortfarande en post",
		S.kvarvarande() == 1)
	Players.PlayerRemoving:Fire(a)
	check("och även avslagsräknaren städas",
		S.kvarvarande() == 0, ("%d"):format(S.kvarvarande()))
end

do
	rent()
	local a = nySpelare("A")
	--[[ RESPAWN ÄR INGEN PÅFYLLNING. Budgeten följer spelaren, inte
		kroppen: annars vore en död en gratis skopa, och det är en väg in
		i precis det missbruk grinden finns för. ]]
	skur(a, "RidaNu", 100)
	a.CharacterAdded:Fire({})
	check("en respawn ger inte tillbaka polletterna",
		S.slapp(a, "RidaNu") == false)
end

--[[ ══ 6. AVSLAG ÄR TYST — MEN INTE OSYNLIGT ════════════════════════

	Kravet i ordern: "Skapa inte loggflod vid avvisning." Mätningen är
	inte att koden ser tyst ut — det är att tusen avslag ger noll rader,
	och att den som verkligen spammar ändå syns. ]]
print("\n-- Avslag skriver ingen loggflod --")
do
	rent()
	local a = nySpelare("A")
	skur(a, "RidaNu", 1000)
	check("tusen avslag ger noll loggrader",
		varningar("[Takt]") == 0, ("%d rader"):format(varningar("[Takt]")))

	--[[ …men en spammare ska gå att upptäcka. En rad per fönster. ]]
	ga(61)
	skur(a, "RidaNu", 500)
	check("men efter ett fönster sammanfattas de i EN rad",
		varningar("[Takt]") == 1, ("%d rader"):format(varningar("[Takt]")))
	ga(61)
	skur(a, "RidaNu", 500)
	check("och nästa fönster ger en till, inte femhundra",
		varningar("[Takt]") == 2, ("%d rader"):format(varningar("[Takt]")))
end

--[[ ══ 7. FAIL CLOSED ═══════════════════════════════════════════════ ]]
print("\n-- Utan spelare släpps ingenting --")
do
	rent()
	check("nil-anropare nekas", S.slapp(nil, "RidaNu") == false)
	check("en sträng som anropare nekas", S.slapp("A", "RidaNu") == false)
	check("och ingen budget skapas av försöket",
		S.kvarvarande() == 0, ("%d"):format(S.kvarvarande()))
end

--[[ ══ 8. GRINDEN KÖR INTE HANDLAREN NÄR DEN NEKAR ══════════════════

	Det här är kravet "rate limit får inte bli en väg att acceptera
	ogiltiga anrop eller läcka data", mätt åt båda hållen: handlaren ska
	köras när den släpps igenom, och ALDRIG när den nekas. ]]
print("\n-- Grinden kör handlaren, eller ingenting --")
do
	rent()
	local a = nySpelare("A")
	local korda = 0
	local lindad = S.grind("RidaNu", function(player, arg)
		korda += 1
		return true, arg
	end)
	local tak = S.GRANSER.RidaNu.tak
	for _ = 1, tak do lindad(a, "x") end
	check("handlaren körs för varje släppt anrop",
		korda == tak, ("%d av %d"):format(korda, tak))
	local ok, skal = lindad(a, "x")
	check("ett nekat anrop kör INTE handlaren",
		korda == tak, ("%d"):format(korda))
	check("och svarar med ett översättbart skäl, inte en rå kod",
		ok == false and skal == "takt.for_snabbt", tostring(skal))
end

do
	rent()
	local a = nySpelare("A")
	--[[ Handlare med egen nej-form. Handskakningen svarar med en VY och
		`MinHast` med en hästpost; ett `false` där hade varit en ny form
		klienten aldrig sett. ]]
	local lindad = S.grind("RidaNu", function() return { vy = true } end,
		function() return nil end)
	for _ = 1, S.GRANSER.RidaNu.tak do lindad(a) end
	check("en handlare med egen avslagsform får sin egen form",
		lindad(a) == nil)
end

--[[ ══ 9. DE TVÅ KONKRETA VÄGARNA UR #258 ═══════════════════════════

	Nu genom RIKTIGA handlare. `LedService.start` och
	`GameplayService.start` registrerar dem; provet anropar exakt den
	funktion nätet hade nått. ]]
print("\n-- #258:s två amplifieringsvägar --")

--[[ VÄG 1: `LedBorja(nil)`.

	`borjaInre` nekar på sin FÖRSTA rad — `led.ingen_hast` — och `borja`
	loggade ändå en `warn` per anrop genom `logg`. Ett anrop krävde
	varken närhet, häst eller session. Grinden ligger nu före båda. ]]
do
	rent()
	LedService.start()
	local ledBorja = Networking.get("LedBorja")
	check("LedBorja har en handlare", type(ledBorja.OnServerInvoke) == "function")

	local a = nySpelare("Spammare")
	local svar = {}
	for _ = 1, 200 do
		local ok, skal = ledBorja.OnServerInvoke(a, nil)
		svar[tostring(skal)] = (svar[tostring(skal)] or 0) + 1
	end
	local tak = S.GRANSER.LedBorja.tak
	check("200 anrop når handlaren högst takets antal gånger",
		(svar["led.ingen_hast"] or 0) == tak,
		("%d nådde handlaren, tak %d"):format(svar["led.ingen_hast"] or 0, tak))
	check("resten nekas av takten",
		(svar["takt.for_snabbt"] or 0) == 200 - tak,
		("%d"):format(svar["takt.for_snabbt"] or 0))
	--[[ DEN MÄTNING SOM FYNDET HANDLADE OM: loggfloden. Före grinden gav
		200 anrop 200 `[Led]`-rader. ]]
	check("och loggfloden är borta — högst en rad per släppt anrop",
		varningar("[Led]") <= tak,
		("%d rader, tak %d"):format(varningar("[Led]"), tak))
end

--[[ VÄG 2: `PreparationMoment` när spelaren är OBUNDEN.

	`narvaro` anropar då `bind()`, som itererar alla taggade hästar och
	avslutar med TVÅ `FireClient`. Ett anrop blev alltså O(antal hästar)
	plus två utgående paket — och det gick att upprepa fritt. ]]
do
	rent()
	GameplayService.start()
	local moment = Networking.get("PreparationMoment")
	check("PreparationMoment har en handlare",
		type(moment.OnServerInvoke) == "function")

	local a = nySpelare("Spammare")
	local natt = 0
	for _ = 1, 200 do
		local _, skal = moment.OnServerInvoke(a, "iordning", "utr:1")
		if skal ~= "takt.for_snabbt" then natt += 1 end
	end
	local tak = S.GRANSER.PreparationMoment.tak
	check("200 anrop når handlaren högst takets antal gånger",
		natt == tak, ("%d nådde handlaren, tak %d"):format(natt, tak))
end

--[[ FÖRSTÄRKNINGEN MÄTT I UTGÅENDE PAKET.

	Att räkna hur många anrop som når handlaren mäter grinden. Det mäter
	inte KOSTNADEN, och kostnaden var halva fyndet: ett anrop som nekas
	djupt inne i en tjänst har redan hunnit göra sitt arbete och skicka
	sina paket.

	Vägen hit är `PreparationHello`, och den är vald för att den
	replikerar OVILLKORLIGT: `skickaPass` ligger före returen och körs
	oavsett hur handlaren slutar. Ett anrop är alltså garanterat ett
	utgående paket, och 200 anrop var garanterat 200.

	Första utkastet mätte `PreparationMoment` i stället, och den raden
	kom ut grön med NOLL paket — i bänken har spelaren ingen tilldelad
	häst, så `bind` returnerar innan den hinner skicka något. Måttet var
	tomt: det hade varit grönt även utan grind. ]]
do
	rent()
	GameplayService.start()
	local hello = Networking.get("PreparationHello")
	local pass = Networking.get("PassSync")
	check("PreparationHello har en handlare",
		type(hello.OnServerInvoke) == "function")

	local a = nySpelare("Spammare")
	local fore = #pass._skickat
	for _ = 1, 200 do hello.OnServerInvoke(a) end
	local paket = #pass._skickat - fore
	local tak = S.GRANSER.PreparationHello.tak
	check("200 anrop ger högst takets antal utgående paket",
		paket == tak, ("%d paket på 200 anrop, tak %d"):format(paket, tak))
end

--[[ ══ 10. NORMALA FLÖDEN PASSERAR FORTFARANDE ══════════════════════

	Den viktigaste mätningen i hela specen. En gräns som stoppar en
	människa är en regression, inte ett skydd.

	Takten i en riktig skötsel: en människa som trycker så fort hon kan
	på en pekskärm ligger runt fyra i sekunden. Mätningen gör tjugo
	moment i den takten och kräver att INGET av dem nekas. ]]
print("\n-- En människa i normal takt släpps igenom --")
do
	rent()
	local a = nySpelare("Ryttare")
	local nekade = 0
	for _ = 1, 20 do
		if not S.slapp(a, "PreparationMoment") then nekade += 1 end
		ga(0.25)
	end
	check("tjugo skötselmoment i fyra per sekund nekas aldrig",
		nekade == 0, ("%d nekade"):format(nekade))
end

do
	rent()
	local a = nySpelare("Ryttare")
	--[[ En hel normal session: handskakning, dagens häst, sadla, transa,
		leda, rida nu, sitta upp, sitta av. En gång var, i mänsklig takt. ]]
	local flode = {
		"PreparationHello", "MinHast", "SadlaHast", "TransaHast",
		"LedBorja", "LedSlapp", "RidaNu", "MountRequest", "DismountRequest",
	}
	local nekade = {}
	for _, handling in ipairs(flode) do
		if not S.slapp(a, handling) then table.insert(nekade, handling) end
		ga(1)
	end
	check("en hel normal sessionskedja passerar utan ett enda nej",
		#nekade == 0, table.concat(nekade, ", "))
end

do
	rent()
	local a = nySpelare("Ryttare")
	--[[ DUBBELTRYCK PÅ PEKSKÄRM. Ett finger som studsar ger två anrop på
		några millisekunder, och det ska inte kosta spelaren något. ]]
	local nekade = 0
	for _ = 1, 2 do
		if not S.slapp(a, "SadlaHast") then nekade += 1 end
	end
	check("ett dubbeltryck på pekskärm nekas inte",
		nekade == 0, ("%d"):format(nekade))
end

--[[ Klockan lämnas tillbaka: en spec som byter ut en global och inte
	lämnar tillbaka den mäter nästa spec åt den. ]]
S._satKlockaForProv(nil)

print("")
if fails > 0 then
	print(string.format("%d mätning(ar) föll.", fails))
else
	print("Alla mätningar gick igenom.")
end
