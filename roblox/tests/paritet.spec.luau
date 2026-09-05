--!nostrict
--[[
	PARITET WEBB ↔ ROBLOX för ridkärnan (G02-A, issue #82).

	Kärnloop, hästlogik och centrala gameplayregler ska motsvara varandra på
	de två ytorna (CLAUDE.md, Paritetsregeln). Fram till nu har det bara
	varit en text. Den här specen gör det MÄTBART: den jämför Roblox
	Gaits/Telemetri mot webbens exporterade ridkanon
	(roblox/src/shared/HorseCore/RidKanon.luau, genererad ur src/model.js och
	src/riding/telemetri.js av tools/exportera-ridkanon.mjs).

	Två sorters påståenden:

	  A. MÅSTE STÄMMA. Normtempon, undre bandgränser, hysteres, trösklarnas
	     gemensamma del, gångartsordningens gemensamma del, telemetrins
	     fältnamn, härlednings-märkningen och övergångskontraktet.

	  B. KÄNDA AVVIKELSER. De skillnader som faktiskt finns i dag står
	     uppräknade med sitt värde. Specen kräver att de ser ut EXAKT så.
	     Det gör två saker: en NY avvikelse blir röd, och en avvikelse som
	     rättas tvingar fram en ändring här i stället för att glida förbi.

	     Att jämna ut en avvikelse ändrar ridkänslan och är ett
	     produktbeslut — specen dokumenterar, den harmoniserar inte.

	Kör: python3 roblox/tests/build.py roblox/tests/paritet.spec.luau
	     && luau roblox/tests/.build/paritet.luau
]]

local fails = 0
local function check(namn, ok, detalj)
	if ok then
		print(string.format("  OK   %s %s", namn, detalj or ""))
	else
		fails += 1
		print(string.format("  FEL  %s %s", namn, detalj or ""))
	end
end

--[[ ÖPPET PRODUKTBESLUT — inte ett godkännande.

     Senior review av #86, blocker A: en plattformsskillnad i kärnrörelsen
     får inte redovisas som ett grönt "förväntat" utfall. Den är inte
     paritet; den är en fråga som väntar på Tobias.

     `beslut` skiljer sig från `check` på två sätt. Raden skrivs som `PO`,
     aldrig `OK`, så ingen kan läsa registret som ett parity-pass. Och
     värdet KONTROLLERAS ändå: stämmer det inte längre har någon ändrat en
     feel-siffra i tysthet, och då blir raden FEL. Registret dokumenterar
     alltså skillnaden utan att sanktionera den, och skyddar samtidigt mot
     att den ändras utan beslut. ]]
local oppna, oppnaBlockerande = 0, 0
local function beslut(klass, namn, oforandrat, detalj)
	if not oforandrat then
		fails += 1
		print(string.format("  FEL  %s — VÄRDET HAR ÄNDRATS UTAN BESLUT %s", namn, detalj or ""))
		return
	end
	oppna += 1
	if klass == "BLOCKERAR" then oppnaBlockerande += 1 end
	print(string.format("  PO   [%s] %s %s", klass, namn, detalj or ""))
end

local function nara(a, b, eps)
	return math.abs(a - b) <= (eps or 1e-6)
end

local function sorterad(t)
	local ut = table.clone(t)
	table.sort(ut)
	return ut
end

local function samma(a, b)
	if #a ~= #b then return false end
	for i, v in a do if b[i] ~= v then return false end end
	return true
end

print("── PARITY PASS — det som MÅSTE stämma, och gör det ──────────")

--[[ 1. Gångartsordningen. Roblox har fyrsprånget som webben saknar, men de
     fyra första stegen måste vara samma stege — annars betyder ett
     "grannbyte" olika saker på de två ytorna. ]]
do
	local ok = true
	for i, webbnamn in RidKanon.ORDNING do
		if Gaits.ORDER[i] ~= RidKanon.MOTSVARIGHET[webbnamn] then ok = false end
	end
	check("gångartsordningen: webbens stege är ett prefix av Roblox",
		ok, string.format("(%s | +%d till på Roblox)",
			table.concat(Gaits.ORDER, " → "), #Gaits.ORDER - #RidKanon.ORDNING))
end

--[[ 2. Normtempona. Gate 01:s intrimmade siffror — skritt 1,45, trav 3,20,
     galopp 5,60. Driver de isär rider samma häst i olika takt på de två
     ytorna, vilket är precis vad paritetsregeln finns för. ]]
for _, webbnamn in RidKanon.ORDNING do
	local band, g = RidKanon.BAND[webbnamn], Gaits.get(RidKanon.MOTSVARIGHET[webbnamn])
	check(string.format("normtempo %s/%s", webbnamn, g.name),
		nara(band.norm, g.norm), string.format("(%.2f = %.2f m/s)", band.norm, g.norm))
end

--[[ 3. Undre bandgränserna. Den övre för galopp skiljer sig — se B nedan. ]]
for _, webbnamn in RidKanon.ORDNING do
	local band, g = RidKanon.BAND[webbnamn], Gaits.get(RidKanon.MOTSVARIGHET[webbnamn])
	check(string.format("undre bandgräns %s/%s", webbnamn, g.name),
		nara(band.min, g.min), string.format("(%.2f = %.2f m/s)", band.min, g.min))
end

--[[ 4. Hysteresen. Utan samma värde flimrar gångarten vid olika tempon. ]]
check("hysteresen är samma på båda ytorna",
	nara(RidKanon.HYSTERES, Gaits.HYSTERESIS),
	string.format("(%.2f = %.2f m/s)", RidKanon.HYSTERES, Gaits.HYSTERESIS))

--[[ 5. Trösklarna, mätta på BÅDA ytorna på samma sätt: fråga efter
     gångarten utan tidigare gångart (då gäller inte hysteresen) och se var
     svaret byter. Ingen tabell läses av — beteendet jämförs. ]]
do
	local ok, forsta = true, nil
	for _, rad in RidKanon.TROSKLAR do
		local strax_under = Gaits.forSpeed(rad.under - 0.001, nil)
		local precis_pa = Gaits.forSpeed(rad.under, nil)
		local vantad_over = RidKanon.MOTSVARIGHET[rad.gangart]
		if precis_pa ~= vantad_over or strax_under == vantad_over then
			ok = false
			forsta = forsta or string.format("%.2f gav %s, väntade %s", rad.under, precis_pa, vantad_over)
		end
	end
	check("trösklarna ligger på samma tempon (uppmätta, inte avskrivna)",
		ok, forsta or string.format("(%d trösklar)", #RidKanon.TROSKLAR))
end

--[[ 6. Styrningens tidskonstanter. Att lägga sig i en båge ska gå fortare
     än att räta upp sig ur den, och med SAMMA siffror på båda ytorna —
     det är den halvan av svängkänslan som inte får skilja sig. ]]
check("kurvaturens tidskonstant, lägga sig i bågen",
	nara(RidKanon.KAPPA_TAU_LAGG, Config.MOVEMENT.CurvatureTauPress),
	string.format("(%.2f = %.2f s)", RidKanon.KAPPA_TAU_LAGG, Config.MOVEMENT.CurvatureTauPress))
check("kurvaturens tidskonstant, räta upp sig ur bågen",
	nara(RidKanon.KAPPA_TAU_RATA, Config.MOVEMENT.CurvatureTauRelease),
	string.format("(%.2f = %.2f s)", RidKanon.KAPPA_TAU_RATA, Config.MOVEMENT.CurvatureTauRelease))

--[[ 6b. Svängfaktorn per gångart. Skritt och trav är porterade rakt av och
     måste stämma; galoppens skiljer sig och står under B. ]]
for _, webbnamn in { "halt", "skritt", "trav" } do
	local g = Gaits.get(RidKanon.MOTSVARIGHET[webbnamn])
	check(string.format("svängfaktor %s/%s", webbnamn, g.name),
		nara(RidKanon.SVANGFAKTOR[webbnamn], g.turn),
		string.format("(%.2f = %.2f)", RidKanon.SVANGFAKTOR[webbnamn], g.turn))
end

--[[ 7. Telemetrins fältnamn. G02-B ska kunna läsa samma namn oavsett yta. ]]
check("telemetrins fältnamn är identiska",
	samma(sorterad(Telemetri.FALT), sorterad(RidKanon.TELEMETRI_FALT)),
	string.format("(%d fält)", #Telemetri.FALT))

check("samma fält är märkta som HÄRLEDDA, inte mätta",
	samma(sorterad(Telemetri.HARLEDDA), sorterad(RidKanon.HARLEDDA)),
	"(" .. table.concat(sorterad(Telemetri.HARLEDDA), ", ") .. ")")

--[[ 7. Övergångskontraktet. Samma dom på samma byte. ]]
do
	local fall = {
		{ "halt", "skritt", true }, { "skritt", "trav", true }, { "trav", "galopp", true },
		{ "galopp", "trav", true }, { "galopp", "halt", true }, { "trav", "halt", true },
		{ "halt", "trav", false }, { "halt", "galopp", false }, { "skritt", "galopp", false },
	}
	local ok, forsta = true, nil
	for _, f in fall do
		local fran, till, vantat = RidKanon.MOTSVARIGHET[f[1]], RidKanon.MOTSVARIGHET[f[2]], f[3]
		if Telemetri.lagligtByte(fran, till) ~= vantat then
			ok = false
			forsta = forsta or string.format("%s → %s", fran, till)
		end
	end
	check("övergångskontraktet dömer likadant som webbens",
		ok, forsta or string.format("(%d fall)", #fall))
end

--[[ 8. vridhastighet = kurvatur × tempo. Webbens formulering, och exakt
     det MovementController redan skriver in i loco.turnRate. ]]
do
	local ritt = Telemetri.sittUpp(Telemetri.nyRitt(), "bandit", "ridhus")
	local kurvatur = 0.1
	--[[ Fixturen bär också cue-fälten, som MovementController skriver när
	     begäran ändras (se `loco.cue` där). Utan dem skulle raden nedan
	     rapportera dem som hål trots att källan finns — och lärdomen från
	     blocker B var just att en konstruerad loco kan ljuga om vad
	     runtimen kan. Värdena är en häst mitt i en övergång: hon travar,
	     ryttaren har bett om galopp. ]]
	local loco = { gait = "trot", targetGait = "trot", speed = 3.2,
		turnRate = kurvatur * 3.2, phase = 0.25,
		cue = "framåt", cueTid = 1.0, tid = 1.4, senasteOvergang = 0.4 }
	local tm = Telemetri.las(ritt, loco, kurvatur)
	check("vridhastighet = kurvatur × tempo",
		nara(tm.vridhastighet, tm.kurvatur * tm.fart),
		string.format("(%.3f rad/s vid r = %.1f m)", tm.vridhastighet, tm.svangradie))

	--[[ 9. Luckorna ska vara EXAKT de deklarerade. Ett nytt hål blir rött. ]]
	local hal = {}
	for _, namn in Telemetri.FALT do
		if tm[namn] == nil then table.insert(hal, namn) end
	end
	check("bara de deklarerade fälten saknar källa på Roblox",
		samma(sorterad(hal), sorterad(Telemetri.SAKNAS)),
		"(" .. table.concat(sorterad(hal), ", ") .. ")")

	--[[ 10. Uppsutten/avsutten som tillstånd, inte som scen. ]]
	local upp = ritt.uppsutten and ritt.hast == "bandit"
	Telemetri.sittAv(ritt)
	check("uppsittning/avsittning är ett tillstånd på Roblox också",
		upp and ritt.uppsutten == false and ritt.hast == nil,
		string.format("upp: %s → av: %s", tostring(upp), tostring(ritt.uppsutten)))

	--[[ 11. Glappräknaren fångar ett olagligt hopp. ]]
	local r2 = Telemetri.sittUpp(Telemetri.nyRitt(), "bandit", "ridhus")
	Telemetri.foljGangart(r2, "walk")
	Telemetri.foljGangart(r2, "trot")
	local lagligt = r2.glapp
	Telemetri.foljGangart(r2, "halt")
	Telemetri.foljGangart(r2, "canter")           -- halt → galopp: glapp
	check("glappräknaren fångar ett olagligt gångartshopp",
		lagligt == 0 and r2.glapp == 1,
		string.format("(lagliga: %d glapp, halt → canter: %d glapp)", lagligt, r2.glapp))
end

print("")
print("── KÄRNRÖRELSEN: PARITY PASS, och de luckor som återstår ────")
print("   PO-beslutet 2026-09-05 gjorde webbens Gate 01-baseline till kanon")
print("   och Roblox är harmoniserad mot den. De fyra skillnader som förut")
print("   blockerade produktacceptans är därmed borta — raderna nedan mäter")
print("   nu att värdena är LIKA, inte att de skiljer sig.")
print("")
print("   KNOWN DIVERGENCES står kvar som PO-rader. De är inte godkännanden")
print("   och inte paritet; de är kända luckor med känt hem. Ändras ett värde")
print("   utan beslut blir raden FEL.")
print("")

--[[ Varje rad: vad som skiljer, webbens värde, Roblox värde. Ändras något
     av dem blir raden röd och avvikelsen måste beskrivas om — eller,
     om den rättas, tas bort här. ]]

check("galoppens övre bandgräns är densamma",
	nara(RidKanon.BAND.galopp.max, Gaits.get("canter").max),
	string.format("(webb galopp ≤ %.2f, Roblox canter ≤ %.2f m/s)",
		RidKanon.BAND.galopp.max, Gaits.get("canter").max))

beslut("LUCKA", "fyrsprånget finns bara på Roblox",
	#Gaits.ORDER == #RidKanon.ORDNING + 1 and Gaits.ORDER[5] == "gallop",
	string.format("(Roblox %s %.2f–%.2f m/s, webben saknar gångarten)",
		Gaits.get("gallop").label, Gaits.get("gallop").min, Gaits.get("gallop").max))

--[[ Cykellängden. Webbens värde är SPRANG.hast × steg vid neutral häst.
     Raden hävdade förut att avvikelsen SKA finnas — den var ett register
     över en öppen produktfråga. Efter PO-beslutet 2026-09-05 är webben
     kanon och Roblox harmoniserad mot den, så raden mäter nu det den
     heter: att de är lika. ]]
do
	local ok, rader = true, {}
	for _, par in { { "skritt", 3.50 }, { "trav", 3.50 }, { "galopp", 3.50 } } do
		local webbnamn, sprang = par[1], par[2]
		local webb = sprang * RidKanon.BAND[webbnamn].steg
		local rob = Gaits.cycleLength(RidKanon.MOTSVARIGHET[webbnamn])
		table.insert(rader, string.format("%s %.2f/%.2f", webbnamn, webb, rob))
		if not nara(webb, rob, 0.02) then ok = false end
	end
	check("cykellängden är densamma (webb/Roblox, meter)",
		ok, "(" .. table.concat(rader, ", ") .. ")")
end

--[[ Kurvaturtaket. Webben ger en snävare volt vid full styrning än Roblox.
     Skillnaden är inte kosmetisk: 0,42 mot 0,30 är 2,4 m mot 3,3 m radie i
     skritt. Uppmätt på webben i tools/ridtest.mjs — full styrning i trav
     ger en RIDD volt på 8,25 m diameter mot 1/κ = 4,12 m radie. ]]
check("kurvaturtaket vid full styrning är detsamma",
	nara(RidKanon.KAPPA_MAX, Config.MOVEMENT.CurvatureMax),
	string.format("(webb %.2f 1/m ⇒ %.1f m radie, Roblox %.2f ⇒ %.1f m, i skritt)",
		RidKanon.KAPPA_MAX, 1 / RidKanon.KAPPA_MAX,
		Config.MOVEMENT.CurvatureMax, 1 / Config.MOVEMENT.CurvatureMax))

check("galoppens svängfaktor är densamma",
	nara(RidKanon.SVANGFAKTOR.galopp, Gaits.get("canter").turn),
	string.format("(webb galopp %.2f, Roblox canter %.2f)",
		RidKanon.SVANGFAKTOR.galopp, Gaits.get("canter").turn))

beslut("LUCKA", "hjälplager, spänning och mjukhet saknas på Roblox",
	#Telemetri.SAKNAS == 5,
	"(" .. table.concat(sorterad(Telemetri.SAKNAS), ", ") .. " — G02-B ger dem källor)")

print("")
if oppna > 0 then
	print(string.format("%d kända luckor, varav %d BLOCKERAR produktacceptans av G02-A.",
		oppna, oppnaBlockerande))
	if oppnaBlockerande == 0 then
		print("KÄRNRÖRELSEN HAR PARITET: kurvaturtak, galoppens band och svängfaktor")
		print("och cykellängderna är samma tal på båda ytorna efter PO-beslutet.")
		print("Luckorna ovan ligger utanför kärnrörelsen och har känt hem — se")
		print("docs/G02-A-RIDKARNAN.md. De ger inte i sig produktacceptans.")
	else
		print("Paritetsspecen kan inte ge PARITY PASS för kärnrörelsen medan de står öppna.")
		print("Att jämna ut dem ändrar ridkänslan och är Tobias beslut — se docs/G02-A-RIDKARNAN.md.")
	end
	print("")
end
if fails > 0 then
	print(string.format("%d mätning(ar) föll.", fails))
else
	print("Alla mätningar gick igenom.")
end
