--[[
	HANDIGHETEN — är världen speglad?

	Tobias fysiska Studio-test: interiörerna ser spegelvända ut. Den här
	specen avgör saken med mätning i stället för intryck.

	── VARFÖR VANLIGA PARITETSPROV INTE KAN SE DET ────────────────────────

	Alla paritetskontroller jämför webben med Roblox. Är båda speglade på
	SAMMA sätt är de överens — de är överens om att ha fel. Och ett
	koordinatprov ("stallet ligger öster om ridhuset") överlever också en
	spegling, för DATAN är rätt. Det som går sönder är vad man SER när man
	står i världen.

	── VAD SOM MÄTS ───────────────────────────────────────────────────────

	Handighet är en vänster/höger-relation från en blickpunkt, och det är
	den enda sortens påstående en spegling inte överlever.

	Regeln, en gång:

	    en betraktare med blickriktningen f och uppåt u har
	    höger = f × u                    (högerhänt system)

	Kartregeln, en gång:

	    kartan har +x öster och +y norr (src/site.js rad 3), så
	    den som ser SÖDERUT har VÄSTER till höger,
	    den som ser NORRUT har ÖSTER till höger.

	Stämmer de två överens är världen rättvänd. Gör de inte det är den
	speglad, och ingen rotation lagar det — rotationer bevarar handighet.

	── ANKARNA ────────────────────────────────────────────────────────────

	Gyllene ankaret är ordagrant ur `references/SITEPLAN.md` (ankomstvyn):

	    "Står man på grusplanen har man ridhuset till höger och stallet
	     till vänster"

	Resten härleds ur kompassen plus lägen som SITEPLAN verifierar —
	hagarna öster om stallet, grusvägen väster om ridhuset, hästgången
	mellan husen. Inga koordinater hittas på här.

	Lägena LÄSES UR DEN BYGGDA VÄRLDEN, inte ur källan: frågan är vad som
	hamnade i Roblox.

	Kör: python3 roblox/tests/build.py tests/handighet.spec.luau
	     && luau roblox/tests/.build/handighet.spec.luau
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

local G = UBRFKomplex
local modell = workspace:FindFirstChild("Anläggning"):FindFirstChild("UBRF")

--[[ Byggnadens mitt i VÄRLDEN, läst ur dess grundplatta. Grunden byggs av
	`byggHus` med byggnadens id i namnet och är den enda delen som med
	säkerhet täcker hela fotavtrycket. ]]
local function husmitt(id: string): Vector3?
	for _, d in ipairs(modell:GetDescendants()) do
		if d.Name == (id .. " grund") and d.CFrame then
			return d.CFrame.Position
		end
	end
	return nil
end

--[[ ══ MAPPNINGEN MÄTS, DEN ANTAS ALDRIG ════════════════════════════════

	Första versionen räknade om site → värld med produktionens EGEN
	funktion. Det gjorde provet värdelöst: kopplade man bort speglingen
	vände både världen och provets ram, och grinden förblev grön. Ett prov
	som följer med felet mäter ingenting — och den fällan är precis den
	ordern varnar för när den säger att specen inte får rättas för att
	matcha buggen.

	Nu LÄSES mappningen ur den byggda världen. Varje byggnad har en känd
	mittpunkt på kartan (`rekt` i UBRFKomplex, samma tal `byggHus` bygger
	grundplattan av) och en mätbar mittpunkt i världen. Paren bestämmer
	den affina avbildningen:

	    X = aX·x + bX·y + cX
	    Z = aZ·x + bZ·y + cZ

	Tre par löser den exakt; resten KONTROLLERAR att den stämmer, alltså
	att bygget inte förvrängt kartan. Ur lösningen faller norr och öster ut
	som MÄTVÄRDEN, och det är dem kompassregeln prövas mot. ]]
local par: { { id: string, x: number, y: number, X: number, Z: number } } = {}
for _, b in ipairs(G.byggnader) do
	local p = husmitt(b.id)
	if p then
		table.insert(par, {
			id = b.id,
			x = b.rekt.x + b.rekt.w / 2,
			y = b.rekt.y + b.rekt.h / 2,
			X = p.X, Z = p.Z,
		})
	end
end

--[[ Tre par som spänner upp en riktig triangel. Största arean ger den
	stabilaste lösningen; tre hus på rad hade gett en singulär matris. ]]
local function area2(a, b, c): number
	return math.abs((b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x))
end
local A, B, C = nil, nil, nil
local storst = 0
for i = 1, #par do
	for j = i + 1, #par do
		for k = j + 1, #par do
			local s = area2(par[i], par[j], par[k])
			if s > storst then storst, A, B, C = s, par[i], par[j], par[k] end
		end
	end
end

print("\n── Mappningen, mätt ur den byggda världen ──")
check("tre hus spänner upp en yta att lösa avbildningen ur",
	A ~= nil and storst > 1,
	if A then ("%s · %s · %s (area %.0f m²)"):format(A.id, B.id, C.id, storst / 2)
		else ("bara %d hus hittades"):format(#par))

local aX, bX, cX, aZ, bZ, cZ = 1, 0, 0, 0, 1, 0
if A and B and C then
	local dx2, dy2 = B.x - A.x, B.y - A.y
	local dx3, dy3 = C.x - A.x, C.y - A.y
	local det = dx2 * dy3 - dy2 * dx3
	local function los(f1: number, f2: number, f3: number): (number, number, number)
		local g2, g3 = f2 - f1, f3 - f1
		local a = (g2 * dy3 - g3 * dy2) / det
		local b = (g3 * dx2 - g2 * dx3) / det
		return a, b, f1 - a * A.x - b * A.y
	end
	aX, bX, cX = los(A.X, B.X, C.X)
	aZ, bZ, cZ = los(A.Z, B.Z, C.Z)
end

local function varldspunkt(x: number, y: number): Vector3
	return Vector3.new(aX * x + bX * y + cX, 0, aZ * x + bZ * y + cZ)
end

--[[ Stämmer den lösta avbildningen för ALLA hus? Gör den inte det är
	kartan förvrängd i bygget, och då säger resten av provet ingenting om
	verkligheten. ]]
do
	local varst, varstId = 0, "-"
	for _, q in ipairs(par) do
		local p = varldspunkt(q.x, q.y)
		local d = math.sqrt((p.X - q.X) ^ 2 + (p.Z - q.Z) ^ 2)
		if d > varst then varst, varstId = d, q.id end
	end
	check(("avbildningen stämmer för alla %d husen — kartan är inte förvrängd"):format(#par),
		#par >= 4 and varst < 0.5,
		("största avvikelse %.3f studs (%s)"):format(varst, varstId))
end

--[[ Blickriktningar i VÄRLDEN, hämtade ur den MÄTTA avbildningen: site +y
	är norr på kartan, och kolumnen (bX, bZ) säger vart norr tog vägen i
	bygget. Att skriva Vector3.new(0, 0, -1) här hade varit att anta svaret
	på den enda fråga provet ställer. ]]
local function normerad(x: number, z: number)
	local l = math.sqrt(x * x + z * z)
	if l < 1e-9 then return { x = 0, z = 0 } end
	return { x = x / l, z = z / l }
end
local NORR = normerad(bX, bZ)
local SODER = { x = -NORR.x, z = -NORR.z }
local OSTER = normerad(aX, aZ)

--[[ ── REGELN ────────────────────────────────────────────────────────────
	Är A till vänster om B för en betraktare som ser i riktningen `blick`?
	`höger = blick × upp` i ett högerhänt system; A är till vänster när
	(A − B) pekar MOT vänster, alltså har negativ komponent längs höger. ]]
--[[ Kryssprodukten skrivs ut för hand: bänkens Vector3 är en stubbe utan
	`Cross`/`Unit`, och att provet skulle bero på stubbens finesser vore en
	egen sorts osäkerhet. Med upp = (0,1,0) är

	    (bx, by, bz) × (0,1,0) = (−bz, 0, bx)

	vilket är hela räkningen. ]]
local function hogerAv(bx: number, bz: number): (number, number)
	return -bz, bx
end

local function arVanster(a, b, blick): (boolean, number)
	local hx, hz = hogerAv(blick.x, blick.z)
	local proj = (a.X - b.X) * hx + (a.Z - b.Z) * hz
	return proj < 0, proj
end

print("\n── Handigheten i den byggda världen ──")
print(("   norr i världen  = (%.1f, %.1f)"):format(NORR.x, NORR.z))
print(("   öster i världen = (%.1f, %.1f)"):format(OSTER.x, OSTER.z))

--[[ ══ KOMPASSEN ═════════════════════════════════════════════════════════
	Den ENDA egentliga frågan, ställd rent: har den som ser söderut väster
	till höger, som på en karta? Allt annat nedan är samma sak sagd med
	byggnader, och finns för att ett fel ska gå att peka på. ]]
do
	local mitt = varldspunkt(100, 100)
	local vasterut = varldspunkt(90, 100)
	local vanster, proj = arVanster(vasterut, mitt, SODER)
	check("den som ser SÖDERUT har väster till HÖGER (kartans regel)",
		not vanster,
		("väster ligger %s (projektion %.1f)"):format(
			vanster and "till vänster ✗" or "till höger ✓", proj))

	local norrut = varldspunkt(100, 100)
	local osterut = varldspunkt(110, 100)
	local v2, p2 = arVanster(osterut, norrut, NORR)
	check("och den som ser NORRUT har öster till HÖGER",
		not v2,
		("öster ligger %s (projektion %.1f)"):format(
			v2 and "till vänster ✗" or "till höger ✓", p2))
end

--[[ ══ ANKOMSTVYN — SITEPLANS EGNA ORD ═══════════════════════════════════
	"Står man på grusplanen har man ridhuset till höger och stallet till
	vänster." Grusplanen ligger norr om gavlarna, så blicken går söderut. ]]
do
	local ridhus = husmitt("ridhus")
	local stall = husmitt("stall")
	check("båda husen finns i den byggda världen",
		ridhus ~= nil and stall ~= nil,
		if ridhus and stall
			then ("ridhus X %.0f Z %.0f · stall X %.0f Z %.0f")
				:format(ridhus.X, ridhus.Z, stall.X, stall.Z)
			else "saknas")
	if ridhus and stall then
		local ridhusVanster = arVanster(ridhus, stall, SODER)
		check("ANKOMSTVYN: ridhuset till HÖGER och stallet till VÄNSTER",
			not ridhusVanster,
			ridhusVanster
				and "ridhuset hamnar till VÄNSTER om stallet — världen är speglad"
				or "som SITEPLAN beskriver ankomsten")
	end
end

--[[ ══ TRE ANKARE PER BYGGNAD ════════════════════════════════════════════
	Betraktaren står i den norra gaveln och ser in i huset, alltså söderut.
	Grannarnas lägen är verifierade i SITEPLAN: hagarna öster om stallet,
	grusvägen väster om ridhuset, hästgången mellan husen. Med blicken
	söderut ska ÖSTER ligga till vänster och VÄSTER till höger. ]]
local ANKARE = {
	{ hus = "ridhus", blick = "söder", grannar = {
		{ namn = "stallet (öster)", p = varldspunkt(161.6, 90.0), vantasVanster = true },
		{ namn = "grusvägen längs ridhuset (väster)", p = varldspunkt(115.0, 70.0), vantasVanster = false },
		{ namn = "hästgången (öster)", p = varldspunkt(147.0, 84.6), vantasVanster = true },
	} },
	{ hus = "stall", blick = "söder", grannar = {
		{ namn = "hage Ö1 (öster)", p = varldspunkt(192.0, 79.0), vantasVanster = true },
		{ namn = "ridhuset (väster)", p = varldspunkt(130.5, 80.4), vantasVanster = false },
		{ namn = "hästgången (väster)", p = varldspunkt(147.0, 84.6), vantasVanster = false },
	} },
}

for _, a in ipairs(ANKARE) do
	local mitt = husmitt(a.hus)
	if mitt then
		local fel = {}
		for _, g in ipairs(a.grannar) do
			local vanster = arVanster(g.p, mitt, SODER)
			if vanster ~= g.vantasVanster then
				table.insert(fel, ("%s hamnar till %s"):format(
					g.namn, vanster and "vänster" or "höger"))
			end
		end
		check(("%s: alla tre ankare stämmer sett från norra gaveln, blick söderut"):format(a.hus),
			#fel == 0,
			#fel > 0 and table.concat(fel, " · ") or "3 av 3")
	end
end

--[[ ══ MUTATIONEN SOM MÅSTE FÄLLA ════════════════════════════════════════
	Ordern kräver att en avsiktlig spegling av EN axel blir röd. Den körs
	här, inbyggt, mot samma regel: speglar man världen ska varje ankare
	byta sida. Gör de inte det mäter regeln ingenting. ]]
do
	--[[ VILKEN AXEL som ska speglas är inte godtyckligt, och första
		versionen tog fel. För en betraktare som ser NORR–SYD avgörs
		vänster/höger av skillnaden i X; speglar man Z byter man norr mot
		söder — kompassen — men inte sidorna i just den vyn. Mutationen
		blev då grön och mätte ingenting.

		Här speglas därför X för nord/syd-vyn, och Z för öst/väst-vyn.
		Båda måste vända ankaret. ]]
	local ridhus, stall = husmitt("ridhus"), husmitt("stall")
	if ridhus and stall then
		local function spegladX(p) return { X = -p.X, Z = p.Z } end
		local nu = arVanster(ridhus, stall, SODER)
		local sedan = arVanster(spegladX(ridhus), spegladX(stall), SODER)
		check("en spegling av X vänder ankomstankaret — regeln mäter handighet",
			nu ~= sedan,
			("före %s · efter %s"):format(
				nu and "vänster" or "höger", sedan and "vänster" or "höger"))

		--[[ Samma sak för en vy längs öst–väst: där avgör Z, och en
			Z-spegling måste vända den. ]]
		local function spegladZ(p) return { X = p.X, Z = -p.Z } end
		local nuO = arVanster(ridhus, stall, OSTER)
		local sedanO = arVanster(spegladZ(ridhus), spegladZ(stall), OSTER)
		check("och en spegling av Z vänder öst–väst-ankaret",
			nuO ~= sedanO,
			("före %s · efter %s"):format(
				nuO and "vänster" or "höger", sedanO and "vänster" or "höger"))
	end
end

if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	print("HANDIGHET: VÄRLDEN ÄR SPEGLAD mot den verifierade siteplanen.")
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error("handighet.spec: " .. fails .. " fel")
end
print("\nhandighet.spec: alla gröna")
