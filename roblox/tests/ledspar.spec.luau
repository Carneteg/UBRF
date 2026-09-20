--!nostrict
--[[
	SPÅRET ÄR RUTTHISTORIK — en oförbrukad smula får inte raderas.

	ROBLOX_RUNTIME_ROUTING_ACCEPTANCE / M3, produktbeslut 2026-09-20.

	── VAD SOM HÄNDE I STUDIO ────────────────────────────────────────

	Hela ledrutten box E 8 -> ridhuset, sju pass. Hon släpptes på samma
	ställe varje gång. Ögonblicksbilden vid stoppunkten:

	    hast      488,6 · 184,8   kurs −90   v 0,01
	    spelare   471,3 · 207,2   koppel 9,4 m
	    delmal    472,8 · 187,1
	    rör       Tvärvägg 1:2 @ 485 · 186  (Z 185,7..186,3 · X 474,25..496,55)
	    strålen mot målet   Tvärvägg 1:2 på 5,8 studs

	Hästen står NORR om väggen, målet ligger SÖDER om den, och linjen dit
	går rakt igenom. Spelaren tog sig söderut runt väggens VÄSTRA ände.

	Orsaken: `gallraSpar` kastade smulor efter SPELARENS avstånd. Smulorna
	hon behövde gå på — 488 · 184, 480 · 184, 475 · 184 — låg 7,7..9,7 m
	från spelaren och var redan kastade. Kvar fanns bara en punkt vars
	raka linje går genom väggen.

	Och talen garanterade det:

	    MAL_AVVIK  7,0 m   så långt från SPELAREN fick en smula ligga
	    KOPPEL     9,0 m   så långt efter får HÄSTEN hamna

	Spåret gallrades alltså 2 m INNANFÖR kopplet. Det finns ett band där
	kopplet håller men vägen redan är borta — hon är garanterat väglös
	innan hon släpps.

	── INVARIANTEN, ORDAGRANT UR PRODUKTBESLUTET ─────────────────────

	  > En ledd häst får inte förlora en OFÖRBRUKAD smula medan
	  > ledningen fortfarande är giltig. Spelarens avstånd får avgöra
	  > kopplet. Det får inte radera rutthistorik som hästen ännu inte
	  > har gått igenom.

	Kopplet (`KOPPEL`) är OFÖRÄNDRAT. Ingen ny metergräns är uppfunnen.

	── VAD SOM MÄTS ──────────────────────────────────────────────────

	  1. regeln direkt, på funktionen: förbrukat gallras, oförbrukat inte,
	  2. scenariot: spelaren rundar ett hinder, hästen är KVAR INOM
	     kopplet, och smulorna hon behöver ligger längre från spelaren än
	     det gamla taket,
	  3. och punkten hon FAKTISKT dras mot ligger på den gångna vägen —
	     inte på en rak linje mot spelaren.

	Mätning 3 är den som får verkligheten att stämma. Att behålla smulan
	och sedan klampa målpunkten tillbaka mot spelaren hade gett exakt
	samma trasiga linje: klampningen är också `MAL_AVVIK`, och den får
	inte heller flytta rutthistorik.

	Kör: python3 roblox/tests/build.py tests/ledspar.spec.luau
	     && luau roblox/tests/.build/ledspar.spec.luau
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

local RunService = game:GetService("RunService")
RunService._server = true

local M = 3
local DT = 1 / 30

local nastaId = 300
local function nySpelare(namn, pos)
	nastaId += 1
	local k = Instance.new("Model")
	k.Name = "Karaktar"
	local rot = Instance.new("Part")
	rot.Name = "HumanoidRootPart"
	rot.Size = vec(2, 2, 1)
	rot.CFrame = CFrame.new(pos)
	rot.Parent = k
	k.PrimaryPart = rot
	local hum = Instance.new("Humanoid")
	hum.Name = "Humanoid"
	hum.Parent = k
	k.Parent = workspace
	return { Name = namn, UserId = nastaId, Character = k,
		CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }, rot
end

local function nyHast(id, pos)
	local m = Instance.new("Model")
	m.Name = id
	m:SetAttribute("HorseId", id)
	local kropp = Instance.new("Part")
	kropp.Name = "HumanoidRootPart"
	kropp.Size = vec(1.86, 2.34, 5.55)
	kropp.CFrame = CFrame.new(pos)
	kropp.Parent = m
	m.PrimaryPart = kropp
	local hum = Instance.new("Humanoid")
	hum.Name = "Humanoid"
	hum.Parent = m
	m.Parent = workspace
	return m, kropp
end

print("")
print("SPÅRET ÄR RUTTHISTORIK (M3 — Tvärvägg 1:2)")

--[[ ══ 1. REGELN DIREKT PÅ FUNKTIONEN ══════════════════════════════

	Samma skäl som taket och den gamla gallringen prövas direkt i
	`ledning-integration.spec`: spårgrenen kräver att hästen lämnat en
	box, och en regel som bara går att mäta genom ett scenario man knappt
	kan bygga är obevisad. ]]
print("-- 1. Regeln direkt: förbrukat gallras, oförbrukat behålls --")

do
	local hast = vec(0, 3, 0)
	--[[ Förbrukad: hästen står PÅ smulan. Gränsen är `START_R`, samma tal
		som hysteresen börjar gå vid — en punkt hon inte tänker gå till
		får inte vara hennes mål. ]]
	local forbrukad = {
		hast + vec(0.5 * M, 0, 0),
		hast + vec(4.0 * M, 0, 0),
	}
	LedService._gallraSpar(forbrukad, hast)
	check("en smula hästen står på är förbrukad och gallras",
		#forbrukad == 1, ("%d kvar av 2"):format(#forbrukad))

	--[[ Oförbrukad, och LÅNGT bort: det är precis det fallet som den
		gamla regeln kastade när det var spelaren som mättes. Referensen
		är nu HÄSTENS läge. ]]
	local oforbrukad = {
		hast + vec(9.0 * M, 0, 0),
		hast + vec(12.0 * M, 0, 0),
	}
	LedService._gallraSpar(oforbrukad, hast)
	check("en oförbrukad smula 9 m bort behålls — den är rutthistorik",
		#oforbrukad == 2, ("%d kvar av 2"):format(#oforbrukad))

	--[[ Och gallringen tömmer aldrig spåret helt, så hon blir aldrig
		mållös av en städning. ]]
	local sista = { hast + vec(0.2 * M, 0, 0) }
	LedService._gallraSpar(sista, hast)
	check("den sista smulan gallras aldrig bort — hon blir aldrig mållös",
		#sista == 1, ("%d kvar av 1"):format(#sista))

	--[[ ══ EN VÄG SOM KORSAR SIG SJÄLV ═══════════════════════════════

		ChatGPT:s slutreview på `3ecaa16` reproducerade det här, och det
		är samma fel som hela specen finns för — rak linje i stället för
		färdväg, en gång till.

		Gallringen sökte den GLOBALT närmaste smulan i hela spåret och
		kastade allt före den. En väg som böjer tillbaka — spelaren
		rundar något och passerar nära hästen igen — har då en SENARE
		smula fysiskt närmast, och hela sträckan hon har kvar att gå
		raderades i ett svep.

		    fyra oförbrukade smulor på rutten
		    den fjärde korsar tillbaka till 0,5 m från hästen
		    nästa hon faktiskt ska gå till ligger 2,0 m bort
		    -> med global sökning: 1 av 4 kvar

		2,0 m är mer än `START_R` (1,80). Hon har alltså inte nått någon
		av dem, och ingen får gallras. Förbrukning måste vara MONOTON i
		ruttens ordning: bara framsteg framifrån räknas, aldrig fysisk
		närhet till något längre fram. ]]
	do
		local korsande = {
			hast + vec(2.0 * M, 0, 0),          -- nästa på vägen, 2,0 m
			hast + vec(4.0 * M, 0, 0),
			hast + vec(4.0 * M, 0, 3.0 * M),
			hast + vec(0.0 * M, 0, 0.5 * M),    -- böjer tillbaka, 0,5 m
		}
		LedService._gallraSpar(korsande, hast)
		check("en väg som korsar sig själv gallrar INGEN oförbrukad smula",
			#korsande == 4, ("%d kvar av 4"):format(#korsande))
		check("och den första kvar är fortfarande nästa på rutten",
			#korsande > 0
				and math.abs(korsande[1].X - (hast.X + 2.0 * M)) < 0.01,
			#korsande > 0 and ("forsta ligger %.2f m bort"):format(
				(vec(korsande[1].X, 0, korsande[1].Z) - vec(hast.X, 0, hast.Z)).Magnitude / M)
				or "spåret tomt")

		--[[ ══ SUCCESSIVT NÄRMARE ÄR INTE FRAMSTEG ════════════════

			ChatGPT:s andra reviewrond, på `399ffab`. Första rättelsen bytte
			global närmaste mot «är nästa smula närmare än den första, så är
			den första passerad». Det är SAMMA FEL, en granne i taget.

			En rutt som böjer sig successivt tillbaka mot en eftersäpande
			häst har avstånd som faller hela vägen:

			    p1 4,00 m   p2 3,16 m   p3 2,24 m   p4 0,50 m

			Loopen gick då framåt genom alla tre och lämnade 1 av 4, fast
			hon aldrig varit vid någon av dem. NÄRHET ÄR INTE FRAMSTEG —
			varken till något längre fram eller till nästa granne. Det enda
			beviset att hon gått en punkt är att hon HAR VARIT där. ]]
		do
			local bojer = {
				hast + vec(4.0 * M, 0, 0),            -- 4,00 m
				hast + vec(3.0 * M, 0, 1.0 * M),      -- 3,16 m
				hast + vec(2.0 * M, 0, 1.0 * M),      -- 2,24 m
				hast + vec(0.5 * M, 0, 0),            -- 0,50 m
			}
			LedService._gallraSpar(bojer, hast)
			check("successivt narmare framtida smulor far inte bli falskt framsteg",
				#bojer == 4, ("%d kvar av 4"):format(#bojer))
		end
	end
end

--[[ ══ 2 och 3. SCENARIOT — spelaren rundar hindret ═══════════════

	Geometrin är den uppmätta, förenklad till sin klass:

	    hindret   en vägg längs Z = 186, från X = 474 och österut
	    hästen    484 · 184        norr om väggen
	    spelaren  startar intill henne och går väst längs Z = 184 till
	              X = 471 — förbi väggens
	              västra ände — och sedan söderut

	SPELARENS SLUTLÄGE ÄR VALT SÅ ATT HÄSTEN ÄR KVAR INOM KOPPLET. Bandet
	är smalt med flit: `MAL_AVVIK` (7 m) ligger 2 m innanför `KOPPEL`
	(9 m), och det är just i det bandet felet bor. Specen mäter därför
	BÅDE att hon är inom kopplet OCH att smulorna låg utanför det gamla
	taket — blir något av det osant mäter scenariot inte längre rätt sak. ]]
print("")
print("-- 2. Spelaren rundar hindret, hästen är kvar inom kopplet --")

local HAST = vec(484, 3, 184)
local SLUT = vec(471, 3, 206.5)
local VAGG_Z = 186

LedService._glomForProv()
local hast, hastkropp = nyHast("hast_spar", HAST)
--[[ SPELAREN STARTAR INTILL HÄSTEN, inte tolv studs bort. En ledning
	börjar där man når henne, och smulorna börjar därför vid hennes
	egen kropp. Första versionen satte spelaren på 496 — exakt
	`RACKVIDD` 4 m bort — och då låg de första smulorna BAKOM hästen.
	Med monoton förbrukning når hon dem aldrig, så de gallras aldrig,
	och hon skulle gå dit först och vända. Det är en verklig men
	ovanlig ytterkant; scenariot här ska mäta hindret, inte den. ]]
local sp, rot = nySpelare("Ledare_spar", vec(485, 3, 184))
local okStart, skalStart = LedService.borja(sp, hast, hast)
check("ledningen startar", okStart == true, tostring(skalStart))

local l = LedService.lage(sp)
if l then l.lamnatBox = true end

--[[ Spelaren går: först västerut längs Z = 184, sedan söderut vid
	X = 471. Hästen står still — hon är blockerad, precis som i Studio. ]]
local function ga(fran, till, steg)
	for i = 1, steg do
		rot.CFrame = CFrame.new(fran:Lerp(till, i / steg))
		LedService._steg(DT)
	end
end
ga(vec(485, 3, 184), vec(471, 3, 184), 40)
ga(vec(471, 3, 184), SLUT, 40)

l = LedService.lage(sp)
check("ledningen lever fortfarande", l ~= nil)

local koppel = (vec(rot.Position.X, 0, rot.Position.Z)
	- vec(hastkropp.Position.X, 0, hastkropp.Position.Z)).Magnitude / M
check("och hästen är KVAR INOM kopplet — annars mäter scenariot fel sak",
	koppel < 9.0, ("koppel %.2f m, gräns 9,00"):format(koppel))

--[[ LÅG DE SMULOR HON BEHÖVER VERKLIGEN UTANFÖR DET GAMLA TAKET?

	Mätt på den GÅNGNA VÄGEN, inte på det som råkar finnas kvar i spåret
	— frågan är om scenariot ligger i bandet, och det svaret får inte
	bero på den regel som provas. (480 · 184) är en punkt spelaren
	bevisligen gick på, och en punkt hästen måste passera för att komma
	runt hindret. ]]
local BEHOVS = vec(480, 3, 184)
local behovsAvstand = (vec(BEHOVS.X, 0, BEHOVS.Z)
	- vec(rot.Position.X, 0, rot.Position.Z)).Magnitude / M
check("och den väg hon behöver låg utanför det gamla taket på 7 m",
	behovsAvstand > 7.0,
	("480 · 184 ligger %.2f m från spelaren, gamla taket 7,00"):format(behovsAvstand))

local norrOmVaggen = 0
if l then
	for _, sm in ipairs(l.spar) do
		if sm.Z < VAGG_Z then norrOmVaggen += 1 end
	end
end
check("spåret har kvar vägen norr om hindret",
	norrOmVaggen > 0, ("%d smulor norr om Z = %d, av %d"):format(
		norrOmVaggen, VAGG_Z, l and #l.spar or 0))

check("och delmålet ligger där — inte på andra sidan hindret",
	l ~= nil and l.delmal ~= nil and l.delmal.Z < VAGG_Z,
	l and l.delmal and ("delmål %.1f · %.1f"):format(l.delmal.X, l.delmal.Z) or "inget delmål")

print("")
print("-- 3. Punkten hon FAKTISKT dras mot ligger på den gångna vägen --")

--[[ Delmålet räcker inte. `styrMot` klampar målpunkten mot spelaren
	innan den skrivs till riggen, och den klampningen är också
	`MAL_AVVIK`. Behålls smulan men klamps punkten tillbaka blir linjen
	exakt lika trasig. Det som måste mätas är riggens VÄRLDSPUNKT. ]]
local rigg = LedService.riggFor(sp)
local malv = rigg and rigg.mal and rigg.mal.WorldPosition
check("riggen har en målpunkt", malv ~= nil)
check("och den ligger norr om hindret, där spelaren faktiskt gick",
	malv ~= nil and malv.Z < VAGG_Z,
	malv and ("riggmål %.1f · %.1f, hinder Z = %d"):format(malv.X, malv.Z, VAGG_Z) or "-")

--[[ SAMMA SAK UTAN GEOMETRI. Väggen är ett tal i den här specen; regeln
	är det inte.

	«Målpunkten sammanfaller med en smula» DUGER INTE som mätning — den
	kom ut grön även mot den trasiga koden, eftersom den punkt hon drogs
	mot råkade vara en av de smulor som fanns kvar. Det som skiljer är
	att spåret fortfarande går FÖRBI HENNE: har hennes egen del av vägen
	raderats ligger närmaste kvarvarande smula långt bort.

	GRÄNSEN ÄR HÄRLEDD, inte vald. Gallringen tar allt hon passerat och
	allt inom `START_R` (1,80 m), och smulor läggs 0,60 m isär. Nästa
	oförbrukade smula ligger därför mellan 1,80 och 2,40 m framför henne.
	Taket sätts strax ovanför bandet.

	Mot den gamla regeln: 4,40 m. Med rutthistoriken kvar: 1,83 m. ]]
local narmastHast = math.huge
if l then
	for _, sm in ipairs(l.spar) do
		local d = (vec(sm.X, 0, sm.Z)
			- vec(hastkropp.Position.X, 0, hastkropp.Position.Z)).Magnitude / M
		if d < narmastHast then narmastHast = d end
	end
end
check("spåret går fortfarande förbi hästen — hennes egen del är inte raderad",
	narmastHast <= 2.6, ("närmaste smula %.2f m från hästen, band 1,80..2,40"):format(narmastHast))

--[[ OCH HON SKICKAS FRAMÅT, inte tillbaka. Utan gallringen av det hon
	passerat överlever den allra äldsta smulan tills hon gått TILLBAKA
	till den: mätt i bänken blev delmålet 495,4 · 184 för en häst på
	484 · 184 som skulle västerut. Spelaren gick mot lägre X. ]]
check("och delmålet ligger i den riktning spelaren gick, inte bakåt",
	l ~= nil and l.delmal ~= nil and l.delmal.X < hastkropp.Position.X,
	l and l.delmal and ("delmål X %.1f, hästen X %.1f"):format(
		l.delmal.X, hastkropp.Position.X) or "-")

--[[ ══ 4. RINGBUFFERTEN FÅR INTE KASTA OFÖRBRUKAD RUTT ════════

	ChatGPT:s tredje reviewrond, på `c92b08e`. Taket löd
	`if #spar > 40 then table.remove(spar, 1) end` — och den raden tar
	bort FRAMSIDAN, alltid, oavsett om hon gått dit eller inte.

	Reproduktionen: spelaren går ett varv med 6 m radie, hela tiden
	innanför kopplets 9 m; hästen står kvar i mitten. Varje smula på
	cirkeln ligger 6 m bort, alltså långt utanför `START_R` — hon har
	inte gått en enda av dem. Smulor läggs var 0,6 m, sa efter 24,6 m
	ar bufferten full och den äldsta oanvända vägen börjar falla bort.

	Det är samma invariant som hela specen — en giltig ledning får inte
	förlora rutthistorik hon inte gått — men brottet sker i minnestaket
	i stället for i gallringen. ]]
print("")
print("-- 4. Ringbufferten far inte kasta oforbrukad rutt --")

do
	LedService._glomForProv()
	local MITT = vec(300, 3, 300)
	local hastR, hastkroppR = nyHast("hast_ring", MITT)
	local spR, rotR = nySpelare("Ledare_ring", MITT + vec(2 * M, 0, 0))
	local okR = LedService.borja(spR, hastR, hastR)
	check("ledningen startar for ringprovet", okR == true)
	local lR = LedService.lage(spR)
	if lR then lR.lamnatBox = true end

	--[[ Ett varv med 6 m radie. Kopplet ar 9 m, sa sessionen ar giltig
		hela tiden — det matas nedan och ar inte ett antagande. ]]
	local R, forsta, maxSpar, maxKoppel = 6 * M, nil, 0, 0
	for i = 1, 140 do
		local a = (i / 126) * 2 * math.pi
		rotR.CFrame = CFrame.new(MITT + vec(math.cos(a) * R, 0, math.sin(a) * R))
		LedService._steg(DT)
		local l = LedService.lage(spR)
		if l == nil then break end
		if forsta == nil and #l.spar > 0 then forsta = l.spar[1] end
		if #l.spar > maxSpar then maxSpar = #l.spar end
		local d = (vec(rotR.Position.X, 0, rotR.Position.Z)
			- vec(hastkroppR.Position.X, 0, hastkroppR.Position.Z)).Magnitude / M
		if d > maxKoppel then maxKoppel = d end
	end

	local lSlut = LedService.lage(spR)
	check("ledningen ar giltig hela varvet — annars mater provet fel sak",
		lSlut ~= nil and maxKoppel < 9.0, ("maxkoppel %.2f m, grans 9,00"):format(maxKoppel))
	check("och bufferten fylldes — annars provas inget tak",
		maxSpar >= 40, ("sparet nadde %d"):format(maxSpar))
	check("spelaren gick langre an taket racker till",
		lSlut ~= nil, "sessionen lever")

	--[[ HÄSTEN RÖRDE SIG ALDRIG. Ingen smula pa cirkeln ar inom
		`START_R`, sa ingen kan vara forbrukad. Den forsta som lades ska
		darfor fortfarande ligga forst. ]]
	check("den forsta oforbrukade smulan ligger kvar frami spare",
		forsta ~= nil and lSlut ~= nil and #lSlut.spar > 0
			and (lSlut.spar[1] - forsta).Magnitude < 0.01,
		forsta and lSlut and #lSlut.spar > 0
			and ("forst nu %.1f,%.1f — lades %.1f,%.1f"):format(
				lSlut.spar[1].X, lSlut.spar[1].Z, forsta.X, forsta.Z) or "-")
	check("och sparet ar fortfarande begransat",
		lSlut ~= nil and #lSlut.spar <= 40, ("%d smulor"):format(lSlut and #lSlut.spar or -1))
end

--[[ ══ 5. EN ÅTERUPPTAGEN ANTECKNING FÅR INTE BYGGA EN BRO ═════

	ChatGPT:s fjärde reviewrond, på `1ae5c53`. Rond 3 slutade kasta
	framsidan — men när hästen sedan förbrukar EN smula och en plats
	blir ledig, läggs spelarens NUVARANDE läge till efter den gamla
	svansen. Har hon gått en omväg medan antecknandet var pausat blir
	det ett enda påhittat segment tvärs över hela det osedda stycket.

	Uppmätt i review: ett segment på 6,26 m — en väg ingen har gått.

	Spåret slutade alltså radera sanning och började tillverka den i
	stället. Måttet nedan är det enkla: inget segment i spåret får vara
	längre än det tjänsten själv kallar ett hopp. ]]
print("")
print("-- 5. Aterupptagen anteckning far inte bygga en bro --")

do
	LedService._glomForProv()
	local MITT = vec(700, 3, 700)
	local hastB, kroppB = nyHast("hast_bro", MITT)
	local spB, rotB = nySpelare("Ledare_bro", MITT + vec(2 * M, 0, 0))
	check("ledningen startar for broprovet", LedService.borja(spB, hastB, hastB) == true)
	local lB = LedService.lage(spB)
	if lB then lB.lamnatBox = true end

	--[[ 1 · fyll bufferten pa en 6 m-cirkel, hasten kvar i mitten. ]]
	local R = 6 * M
	for i = 1, 130 do
		local a = (i / 126) * 2 * math.pi
		rotB.CFrame = CFrame.new(MITT + vec(math.cos(a) * R, 0, math.sin(a) * R))
		LedService._steg(DT)
	end
	lB = LedService.lage(spB)
	check("bufferten ar full och antecknandet pausat",
		lB ~= nil and #lB.spar >= 40, ("%d smulor"):format(lB and #lB.spar or -1))

	--[[ 2 · spelaren gar en OSEDD omvag medan det ar pausat — vidare
		runt SAMMA cirkel. Da halls hon 6 m fran hasten hela tiden,
		alltsa innanfor kopplets 9 m, och sessionen lever. Forsta
		versionen gick diagonalt bort, kom 12,8 m ifran och slapptes
		— provet matte da en dod session och kom ut gront. ]]
	local svans = lB and lB.spar[#lB.spar]
	for i = 131, 156 do
		local a = (i / 126) * 2 * math.pi
		rotB.CFrame = CFrame.new(MITT + vec(math.cos(a) * R, 0, math.sin(a) * R))
		LedService._steg(DT)
	end
	lB = LedService.lage(spB)
	local gap = svans and (vec(rotB.Position.X, 0, rotB.Position.Z)
		- vec(svans.X, 0, svans.Z)).Magnitude / M or 0
	check("det finns ett oantecknat gap mellan svansen och spelaren",
		gap > 3.0, ("%.2f m"):format(gap))
	check("och sessionen lever — annars mater provet en dod ledning",
		LedService.lage(spB) ~= nil,
		("koppel %.2f m"):format((vec(rotB.Position.X, 0, rotB.Position.Z)
			- vec(kroppB.Position.X, 0, kroppB.Position.Z)).Magnitude / M))

	--[[ 3 · hasten forbrukar EN smula: hon stalls pa den framsta, sa att
		en plats blir ledig. Sedan tillbaka, och ett steg till. ]]
	if lB and #lB.spar > 0 then kroppB.CFrame = CFrame.new(lB.spar[1]) end
	LedService._steg(DT)
	kroppB.CFrame = CFrame.new(MITT)
	for _ = 1, 3 do LedService._steg(DT) end

	lB = LedService.lage(spB)
	local langsta = 0
	if lB then
		for i = 2, #lB.spar do
			local d = (vec(lB.spar[i].X, 0, lB.spar[i].Z)
				- vec(lB.spar[i-1].X, 0, lB.spar[i-1].Z)).Magnitude / M
			if d > langsta then langsta = d end
		end
	end
	check("aterupptagen loggning skapar inte ett ogangbart hopp i rutthistoriken",
		langsta <= 3.0, ("sista/langsta segmentet %.2f m, hoppgransen 3,00"):format(langsta))
end

print("")
if fails > 0 then
	print(("ledspar.spec: %d mätning(ar) föll."):format(fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("ledspar.spec: alla gröna")
end
