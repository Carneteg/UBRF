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
end

--[[ ══ 2 och 3. SCENARIOT — spelaren rundar hindret ═══════════════

	Geometrin är den uppmätta, förenklad till sin klass:

	    hindret   en vägg längs Z = 186, från X = 474 och österut
	    hästen    484 · 184        norr om väggen
	    spelaren  går väst längs Z = 184 till X = 471 — förbi väggens
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
local sp, rot = nySpelare("Ledare_spar", vec(496, 3, 184))
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
ga(vec(496, 3, 184), vec(471, 3, 184), 40)
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

print("")
if fails > 0 then
	print(("ledspar.spec: %d mätning(ar) föll."):format(fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("ledspar.spec: alla gröna")
end
