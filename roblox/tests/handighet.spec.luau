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

local M = BuildKit.M
local modell = workspace:FindFirstChild("Anläggning"):FindFirstChild("UBRF")
local origo = UBRFKomplex.origo or { x = 0, y = 0 }

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

--[[ En punkt i världen ur site-koordinater — samma väg BuildKit går, så
	att provet inte uppfinner en egen mappning. ]]
local function varldspunkt(x: number, y: number): Vector3
	return Vector3.new((x + origo.x) * M, 0, (y + origo.y) * M)
end

--[[ ── REGELN ────────────────────────────────────────────────────────────
	Är A till vänster om B för en betraktare som ser i riktningen `blick`?
	`höger = blick × upp` i ett högerhänt system; A är till vänster när
	(A − B) pekar MOT vänster, alltså har negativ komponent längs höger. ]]
--[[ Krysprodukten skrivs ut för hand: bänkens Vector3 är en stubbe utan
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

--[[ Blickriktningar i VÄRLDEN, härledda ur mappningen: site +y är norr,
	och `varldspunkt` visar vart norr tar vägen. Att räkna ut dem i stället
	för att skriva Vector3.new(0,0,-1) är hela poängen — en ändrad mappning
	ska synas här, inte döljas av en hårdkodad riktning. ]]
local function riktning(x0, y0, x1, y1)
	local a, b = varldspunkt(x0, y0), varldspunkt(x1, y1)
	local dx, dz = b.X - a.X, b.Z - a.Z
	local l = math.sqrt(dx * dx + dz * dz)
	return { x = dx / l, z = dz / l }
end
local NORR = riktning(0, 0, 0, 1)
local SODER = { x = -NORR.x, z = -NORR.z }
local OSTER = riktning(0, 0, 1, 0)

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
