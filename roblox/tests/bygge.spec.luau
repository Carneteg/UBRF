--!nostrict
--[[
	Kör byggskriptet på riktigt och mäter vad det producerade.

	Review 02 krävde bevis för att den generade miljön faktiskt byggs, inte
	bara att den kompilerar. Det här är så nära det går utan Studio: BuildKit,
	Geometri, UBRFKomplex och Anlaggningen körs mot Roblox-stubbar, och sedan
	mäts delarna som kom ut — antal, position, storlek och om något solitt står
	i vägen för cirkulationen.

	Vad den INTE ersätter: Studio. Utseende, material, ljus, prestanda och
	skärmdumparna finns inte här, och gaten är inte parity-ready förrän någon
	kört den där.

	Kör: python3 roblox/tests/build.py tests/bygge.spec.luau
	     && luau roblox/tests/.build/bygge.spec.luau
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

local M = BuildKit.M            -- studs per meter
local modell = workspace:FindFirstChild("Anläggning"):FindFirstChild("UBRF")

print("Byggskriptet kördes utan fel")
check("modellen finns i workspace", modell ~= nil)

local delar = modell:GetDescendants()
check("den byggde faktiskt något", #delar > 200, #delar .. " delar")

-- Delarnas fotavtryck i METER, tillbaka i spelets koordinater.
local function fot(d)
	local p, s = d.CFrame.Position, d.Size
	return { x = (p.X - s.X / 2) / M, y = (p.Z - s.Z / 2) / M,
		w = s.X / M, h = s.Z / M,
		z0 = (p.Y - s.Y / 2) / M, z1 = (p.Y + s.Y / 2) / M }
end

local function raknaNamn(monster)
	local n = 0
	for _, d in ipairs(delar) do
		if string.find(d.Name, monster, 1, true) then n += 1 end
	end
	return n
end

print("\nByggnadsmassan")

for _, id in ipairs({ "ridhus", "stall", "hastgang" }) do
	check(id .. " fick fyra väggar",
		raknaNamn(id .. " syd") == 1 and raknaNamn(id .. " norr") == 1
			and raknaNamn(id .. " vast") == 1 and raknaNamn(id .. " ost") == 1)
end

check("taken byggdes", raknaNamn("Takfall") == #UBRFKomplex.byggnader * 2,
	raknaNamn("Takfall") .. " takfall för " .. #UBRFKomplex.byggnader .. " hus")

check("dörrmarkörerna byggdes", raknaNamn("Dörr ") == #UBRFKomplex.dorrar,
	raknaNamn("Dörr ") .. " st")

do
	-- Ligger hästgångens väggar verkligen mellan husen i den byggda modellen?
	local hg = nil
	for _, d in ipairs(delar) do
		if d.Name == "hastgang vast" then hg = fot(d) end
	end
	-- Läget LÄSES UR ridhusets fotavtryck. 143 stod hårdkodat här och föll när
	-- ridhusets mätta bredd flyttade östväggen till 144,57 — fast gången satt
	-- precis rätt. Tredje testet i sviten med samma sjuka.
	local rh
	for _, b in ipairs(UBRFKomplex.byggnader) do
		if b.id == "ridhus" then rh = b.rekt end
	end
	check("hästgångens västvägg står vid ridhusets östvägg",
		hg ~= nil and rh ~= nil and math.abs(hg.x - (rh.x + rh.w)) < 0.05,
		hg and rh and string.format("gången x = %.2f, ridhusets östvägg x = %.2f",
			hg.x, rh.x + rh.w) or "hittades inte")
end

print("\nStallets insida")

check("fyra boxrader byggdes", raknaNamn("Boxfront W") > 0 and raknaNamn("Boxfront MA") > 0
	and raknaNamn("Boxfront MB") > 0 and raknaNamn("Boxfront E") > 0,
	string.format("W %d, MA %d, MB %d, E %d fronter", raknaNamn("Boxfront W"),
		raknaNamn("Boxfront MA"), raknaNamn("Boxfront MB"), raknaNamn("Boxfront E")))

check("två gångar och tvärkorridoren fick golv",
	raknaNamn("Stallgång") == #UBRFKomplex.stall.gangytor,
	raknaNamn("Stallgång") .. " gångytor")

--[[ De här fyra testerna finns för att KNOWN MISMATCH-en ska smälla om den
	kommer tillbaka. Roblox byggde fronterna i brunt trä medan fotona och
	webben visade mörk antracit i galvad ram, och ingen spec märkte det —
	specen mätte att fronter FANNS, inte vad de var gjorda av.

	Alla fyra läser det delade G.identitet, inte avskrivna tal. Ett test som
	skriver av färgen mäter ett minne av datan i stället för datan. ]]
local function forstaNamn(monster)
	for _, d in ipairs(delar) do
		if string.find(d.Name, monster, 1, true) then return d end
	end
	return nil
end
local function sammaFarg(a, b)
	return a ~= nil and b ~= nil
		and math.abs(a.R - b.R) < 0.01 and math.abs(a.G - b.G) < 0.01
		and math.abs(a.B - b.B) < 0.01
end

local BFI = UBRFKomplex.identitet.stall.boxfront
local SGI = UBRFKomplex.identitet.stall.stallgang

do
	local f = forstaNamn("Boxfront W")
	check("boxfronten har den mätta panelfärgen, inte en egen",
		sammaFarg(f and f.Color, BFI.heldel),
		f and string.format("rgb(%d,%d,%d)", f.Color.R * 255, f.Color.G * 255,
			f.Color.B * 255) or "hittades inte")
end

do
	local r = forstaNamn("Frontregel")
	check("fronten har vågräta reglar med luft emellan, inte en tät skiva",
		r ~= nil and math.abs(r.Size.Z / M - (UBRFKomplex.stall.boxB - 0.30)) < 0.01
			and math.abs(r.Size.Y / M - BFI.regelD) < 0.01,
		r and string.format("%.2f x %.2f m", r.Size.Y / M, r.Size.Z / M) or "saknas")
	check("antalet reglar per box följer datan",
		raknaNamn("Frontregel") == raknaNamn("Boxfront ") * BFI.reglar,
		raknaNamn("Frontregel") .. " reglar på " .. raknaNamn("Boxfront ") .. " fronter")
end

do
	local b = forstaNamn("Limträbalk")
	local pl = forstaNamn("Stalltak plåt")
	check("limträstommen byggdes i den mätta tonen",
		sammaFarg(b and b.Color, SGI.limtra),
		b and "finns" or "SAKNAS — taket är stallgångens tydligaste drag")
	check("takplåten byggdes i den mätta tonen",
		sammaFarg(pl and pl.Color, SGI.takplat), pl and "finns" or "SAKNAS")
end

check("pendelarmaturerna över gångarna byggdes",
	raknaNamn("Stallarmatur") > 0,
	raknaNamn("Stallarmatur") .. " st — de gör undertaket läsbart i i05")

do
	local gy = forstaNamn("Stallgång")
	check("gången har den mätta markstensfärgen, inte en egen",
		sammaFarg(gy and gy.Color, UBRFKomplex.stall.gangSten),
		gy and string.format("rgb(%d,%d,%d)", gy.Color.R * 255, gy.Color.G * 255,
			gy.Color.B * 255) or "hittades inte")
end

check("stallklockan byggdes", raknaNamn("Stallklocka") == 1,
	raknaNamn("Stallklocka") .. " st")

--[[ KLUBBRUMMEN är rum: brandplanen ritar dem som rum och stall-inne-01..04
	visar slutna rum. SERVICEBUKTARNA är det inte — det testet krävde förut
	att SPOLSPILTA byggdes som en namngiven volym, alltså precis den täta låda
	som underkändes i spelarvyn. Ett test kan låsa fast ett fel, och det här
	gjorde det. Nu mäts det som källorna visar. ]]
check("ridhusets fönsterband byggdes ovanför panelen",
	raknaNamn("Ridhus fönsterband") == 1 and raknaNamn("Fönsterpost") > 0,
	raknaNamn("Fönsterpost") .. " poster")

check("klubbrummen byggdes som rum",
	raknaNamn("UPPEHÅLLSRUM") == 1 and raknaNamn("SADELKAMMARE") == 1
		and raknaNamn("TEORISAL") == 1)

do
	local oppna = 0
	for _, r in ipairs(UBRFKomplex.stall.service) do
		if r.oppen then oppna += 1 end
	end
	check("servicebuktarna byggdes som ÖPPNA bukter, inte som täta lådor",
		oppna > 0 and raknaNamn("SPOLSPILTA") == 0
			and raknaNamn("SPÅNFÖRRÅD") == 0
			and raknaNamn("Buktpanel") == oppna,
		string.format("%d öppna, %d buktpaneler, %d täta volymer",
			oppna, raknaNamn("Buktpanel"),
			raknaNamn("SPOLSPILTA") + raknaNamn("SPÅNFÖRRÅD")))

	check("spolbommarna står fristående i bukten",
		raknaNamn("Spolbom") > 0, raknaNamn("Spolbom") .. " st")
	check("spånsäckarna byggdes", raknaNamn("Spånsäckar") > 0,
		raknaNamn("Spånsäckar") .. " st")
	check("rörstråket längs serviceväggen byggdes",
		raknaNamn("Servicerör") == oppna * 2,
		raknaNamn("Servicerör") .. " rör")
	check("gaveldörrens dagsljus och exit-skylt byggdes",
		raknaNamn("Gaveldagsljus") == 1 and raknaNamn("Exitskylt syd") == 1)
end

--[[ Den blanka återvändsgränden: väggen mot servicedelen fick sina hål ur
	gångarnas lägen och blev tät framför varje boxrad. Testet mäter att
	planens egna öppningar faktiskt bryter väggen. ]]
do
	local vagg = nil
	for _, v in ipairs(UBRFKomplex.stall.tvarvaggar) do
		if v.oppningar ~= nil then vagg = v end
	end
	local utan = #Geometri.tvarvaggBitar(UBRFKomplex.stall)
	local med = if vagg then #Geometri.tvarvaggBitar(UBRFKomplex.stall, vagg) else utan
	check("tvärväggen öppnas av planens öppningar, inte bara av gångarna",
		vagg ~= nil and med > utan,
		string.format("%d bitar utan planens öppningar, %d med", utan, med))
end

--[[ Review 02: "no overlapping solid geometry blocks the intended
     circulation" och "major entrances/passages are usable". Två mätningar,
     därför att det finns två sätt att stänga en passage.

     1 · En vägg TVÄRS en gång. Den skulle bara nudda gångytans kant på
         djupet och glider igenom ett areamått — det var precis så den
         obrutna tvärväggen först slank förbi. Alltså mäts i stället att
         varje gång har ett verkligt gap i varje tvärvägg.
     2 · Något solitt som står MITT I en gångyta: en box, ett rum, en
         möbel. Där är area rätt mått, mätt mot en yta som krympts med
         väggtjockleken så att väggar längs kanten inte räknas som hinder. ]]
do
	local S = UBRFKomplex.stall

	-- 1 · Går varje gång genom varje tvärvägg?
	local vaggY = {}
	for _, d in ipairs(delar) do
		if string.find(d.Name, "Tvärvägg", 1, true) then
			local f = fot(d)
			local nyckel = string.format("%.1f", f.y)
			vaggY[nyckel] = vaggY[nyckel] or {}
			table.insert(vaggY[nyckel], f)
		end
	end

	local antalVaggar = 0
	for _ in pairs(vaggY) do antalVaggar += 1 end
	check("tvärväggarna byggdes", antalVaggar == #S.tvarvaggar,
		antalVaggar .. " vägglinjer")

	for nyckel, bitar in pairs(vaggY) do
		for id, g in pairs(S.gangar) do
			local x0, x1 = S.origo.x + g.x0, S.origo.x + g.x1
			-- Täcker någon vägbit gångens mitt? Då är passagen murad.
			local mitt = (x0 + x1) / 2
			local murad = false
			for _, b in ipairs(bitar) do
				if mitt > b.x + 0.01 and mitt < b.x + b.w - 0.01 then murad = true end
			end
			check(string.format("gång %s går igenom tvärväggen vid y = %s", id, nyckel),
				not murad, string.format("gången x %.1f–%.1f", x0, x1))
		end
	end

	--[[ 2 · Står en BOX mitt i en gångyta?

	     Bara boxarna mäts här. Rummen — sadelkammare, uppehållsrum, teorisal,
	     spolspilta, spånförråd — ligger med flit inuti klubb- och
	     servicehallarnas gångytor: webbkoden behandlar gångytan som en grov
	     gångbar region och kolliderar sedan mot rummen var för sig
	     (`vandringKollision` i src/world.js). Att räkna dem som hinder vore
	     att mäta fel sak, och gjorde det första gången: sadelkammaren
	     flaggades som ett 9 m² blockage fast den är en vägg man går runt.

	     Att hallarna ändå går att gå i mäts i stället som fri yta nedan. ]]
	local KANT = 0.25                      -- väggtjocklek; kantnära räknas inte
	local varsta, var = 0, nil
	for _, d in ipairs(delar) do
		if d.CanCollide and string.find(d.Name, "Box", 1, true) then
			local f = fot(d)
			if f.z0 < 1.7 then                       -- under mankhöjd
				for i, g in ipairs(S.gangytor) do
					local gv = { x = S.origo.x + g.x + KANT, y = S.origo.y + g.y + KANT,
						w = g.w - 2 * KANT, h = g.h - 2 * KANT }
					local a = Geometri.overlapp(f, gv)
					if a > varsta then varsta, var = a, d.Name .. " i gångyta " .. i end
				end
			end
		end
	end
	check("ingen box står mitt i en gångyta", varsta < 0.05,
		if var then string.format("värst %.3f m² — %s", varsta, var) else "inget överlapp")

	-- 3 · Blir det golv kvar att gå på när rummen dragits bort?
	for i, g in ipairs(S.gangytor) do
		local gv = { x = S.origo.x + g.x, y = S.origo.y + g.y, w = g.w, h = g.h }
		local yta = g.w * g.h
		local upptaget = 0
		for _, lista in ipairs({ S.rum, S.service }) do
			for _, r in ipairs(lista) do
				upptaget += Geometri.overlapp(
					{ x = S.origo.x + r.rekt.x, y = S.origo.y + r.rekt.y,
						w = r.rekt.w, h = r.rekt.h }, gv)
			end
		end
		local fritt = (yta - upptaget) / yta
		--[[ Tröskeln är 35 %, inte 50. Gångyta 5 — passagen i klubbdelen —
		     är till precis hälften uppehållsrummets fotavtryck, och det är
		     avsiktligt: kvar blir en 3,6 m bred remsa att gå på. En tröskel
		     vid 50 % hade balanserat på flyttalsbruset i just den ytan och
		     vält åt ena eller andra hållet utan att något ändrats. ]]
		check(string.format("gångyta %d har golv kvar att gå på", i), fritt > 0.35,
			string.format("%.0f %% fritt av %.0f m²", fritt * 100, yta))
	end
end

print("\nRidhusets insida")

do
	local bana = nil
	for _, d in ipairs(delar) do
		if d.Name == "Ridbanan 20x60" then bana = fot(d) end
	end
	check("banan byggdes 20 × 60 m", bana ~= nil
		and math.abs(bana.w - 20) < 0.01 and math.abs(bana.h - 60) < 0.01,
		bana and string.format("%.1f × %.1f m vid (%.1f, %.1f)",
			bana.w, bana.h, bana.x, bana.y) or "hittades inte")
	-- Gränserna LÄSES UR fotavtrycket. De stod som 118/143/44/119, och när
	-- ridhusets verifierade längd flyttade södra gaveln från y = 44 till
	-- 41,82 föll testet fast banan låg precis där den skulle. En gräns som
	-- inte läser datan mäter inte datan.
	local rh
	for _, b in ipairs(UBRFKomplex.byggnader) do
		if b.id == "ridhus" then rh = b.rekt end
	end
	check("banan ligger inne i ridhuset", bana ~= nil and rh ~= nil
		and bana.x >= rh.x - 0.01 and bana.x + bana.w <= rh.x + rh.w + 0.01
		and bana.y >= rh.y - 0.01 and bana.y + bana.h <= rh.y + rh.h + 0.01,
		bana and rh and string.format("banan y %.2f..%.2f i huset %.2f..%.2f",
			bana.y, bana.y + bana.h, rh.y, rh.y + rh.h) or nil)
end

check("sargen byggdes med en port i norr",
	raknaNamn("Sarg norr väst") == 1 and raknaNamn("Sarg norr öst") == 1
		and raknaNamn("Sarg syd") == 1)

check("östra sargen byggdes i två delar, med grinden emellan",
	raknaNamn("Sarg öst syd") == 1 and raknaNamn("Sarg öst norr") == 1
		and raknaNamn("Sarg öst") == 2,
	"annars är hästgången dekoration")

do
	-- Grinden ska vara ett verkligt gap, inte två delar som möts.
	local syd, norr = nil, nil
	for _, d in ipairs(delar) do
		if d.Name == "Sarg öst syd" then syd = fot(d) end
		if d.Name == "Sarg öst norr" then norr = fot(d) end
	end
	local gap = if syd and norr then (norr.y - (syd.y + syd.h)) else -1
	check("grinden är ett verkligt gap i sargen", gap > 2.5,
		string.format("%.2f m", gap))
end

--[[ Läktaren är ett PLANT DÄCK med solid front, inte trappsteg. Testets gamla
	lydelse ("två sektioner om fyra steg") mätte den struktur som fotona
	motsäger; den är utbytt tillsammans med bygget. ]]
check("läktaren byggdes som plant däck i två sektioner",
	raknaNamn("Läktardäck") == 2 and raknaNamn("Läktarfront") == 2
		and raknaNamn("Läktarsteg") == 0,
	string.format("%d däck, %d fronter, %d gamla stegdelar",
		raknaNamn("Läktardäck"), raknaNamn("Läktarfront"),
		raknaNamn("Läktarsteg")))

--[[ Topologin fotona kräver, mätt som RELATION och inte mot talen: man ska
	från däcket se över fronten ner i banan. Ändras höjderna i site.js ska
	det här testet fortsätta gälla — annars är höjderna fel. ]]
do
	local L = UBRFKomplex.ridhus.laktare
	check("man ser från däcket över fronten ner i banan",
		L.dackZ < L.frontTopp and L.frontTopp > 0
			and L.dackZ + 1.25 > L.frontTopp,
		string.format("däck %.2f, fronttopp %.2f", L.dackZ, L.frontTopp))
end

do
	-- Inget läktarsteg får stå i hästgångens öppning. Bygger man läktaren i
	-- ett stycke muras gången igen, och det syns först när någon går där.
	local R2 = UBRFKomplex.ridhus
	local g = R2.laktare.gap
	local y0, y1 = R2.origo.y + g.y0, R2.origo.y + g.y1
	local ivagen = 0
	for _, d in ipairs(delar) do
		if string.find(d.Name, "Läktarsteg", 1, true) then
			local f = fot(d)
			if f.y < y1 - 0.1 and f.y + f.h > y0 + 0.1 then ivagen += 1 end
		end
	end
	check("inget läktarsteg står i hästgångens öppning", ivagen == 0,
		ivagen .. " i vägen")
end

do
	-- Kortändans läktare ersatte de glasade rummen längs långsidan.
	local K = UBRFKomplex.ridhus.kortanda
	check("kortändans trappstegsblock byggdes",
		raknaNamn("Kortändans steg") == K.steg,
		raknaNamn("Kortändans steg") .. " steg av " .. K.steg)
	check("kortändan har två trappor upp",
		raknaNamn("Kortändans trappa") == #K.trappor,
		raknaNamn("Kortändans trappa") .. " trappor")
	--[[ Glasbandet BRYTS av trapporna — en obruten remsa är den "generiska
		upprepade fönsterrad" som ordern uttryckligen inte vill ha. Antalet
		segment räknas ur samma `trappor`-tal som bygget använder, så testet
		mäter regeln och inte ett tal. ]]
	--[[ C-ändans identitet i Roblox. Webben har haft vit vägg, klocka och
		kompassros sedan cfdb89a; Roblox byggde bara steg, trappor och glas.
		Klockan mäts som RELATION — mellan trapporna — inte mot ett tal. ]]
	do
		local vv = forstaNamn("Kortändans vita vägg")
		check("kortändans vita vägg byggdes mellan bänkar och glas",
			vv ~= nil and sammaFarg(vv.Color, UBRFKomplex.ridhus.hallvagg),
			vv and string.format("del rgb(%d,%d,%d) mot data rgb(%d,%d,%d)", vv.Color.R*255, vv.Color.G*255, vv.Color.B*255, UBRFKomplex.ridhus.hallvagg.R*255, UBRFKomplex.ridhus.hallvagg.G*255, UBRFKomplex.ridhus.hallvagg.B*255) or "SAKNAS")
		local bk = forstaNamn("Kortändans steg")
		check("bänkarna läser den mätta bankfärgen, inte en egen",
			bk ~= nil and sammaFarg(bk.Color, K.bank),
			bk and string.format("rgb(%d,%d,%d)", bk.Color.R*255, bk.Color.G*255,
				bk.Color.B*255) or "saknas")
	end
	check("kortändans klocka byggdes", raknaNamn("Kortändans klocka") == 1)
	check("kompassrosen byggdes som linjeritad stjärna",
		raknaNamn("Kompassros") == 4, raknaNamn("Kompassros") .. " stavar")
	if K.klocka and #K.trappor >= 2 then
		local lo = math.min(K.trappor[1], K.trappor[2])
		local hi = math.max(K.trappor[1], K.trappor[2])
		check("klockan sitter MELLAN de två trapporna",
			K.klocka.x > lo and K.klocka.x < hi,
			string.format("klocka x %.2f, trappor %.1f och %.1f",
				K.klocka.x, lo, hi))
	end
	if K.stjarna then
		check("kompassrosen sitter vänster om vänstra trappan",
			K.stjarna.x < math.min(K.trappor[1], K.trappor[2]),
			string.format("stjärna x %.2f", K.stjarna.x))
	end

	local vantade = #K.trappor + 1
	check("glasbandet byggdes i segment som bryts av trapporna",
		raknaNamn("Kortändans glasband") == vantade
			and raknaNamn("Glaspost") > 0,
		string.format("%d segment (väntat %d), %d poster",
			raknaNamn("Kortändans glasband"), vantade, raknaNamn("Glaspost")))
end

--[[ Båset byggdes här som EN slät låda medan webben haft nivå, trappa,
	räcken och tak sedan Review 03 — en Roblox-only brist på just det som gör
	båset igenkännbart i ridhus-inne-03. Testet mäter delarna, inte att något
	som heter "Domarbås" finns. ]]
--[[ Review 10:s två paritetsblockerare. Båda var Roblox-only sanningar som
	stod kvar när webben rättades: sanden i gammal ljus beige, och taket helt
	obyggt medan webben hade stomme och undertak. Testerna läser den DELADE
	datan, så en ny divergens fäller dem. ]]
do
	local R2 = UBRFKomplex.ridhus
	local sd = forstaNamn("Ridbanan")
	check("bansanden läser den delade mätta sandFarg",
		sd ~= nil and sammaFarg(sd.Color, R2.sandFarg),
		sd and string.format("rgb(%d,%d,%d) mot data rgb(%d,%d,%d)",
			sd.Color.R*255, sd.Color.G*255, sd.Color.B*255,
			R2.sandFarg.R*255, R2.sandFarg.G*255, R2.sandFarg.B*255) or "saknas")

	local tb = forstaNamn("Ridhus takbalk")
	local tf = forstaNamn("Ridhus takfall")
	check("ridhusets takstomme och undertak byggs i Roblox",
		tb ~= nil and tf ~= nil and raknaNamn("Ridhus takfall") == 2,
		string.format("%d balkar, %d takfall", raknaNamn("Ridhus takbalk"),
			raknaNamn("Ridhus takfall")))
	check("takstommen läser den mätta balkfärgen, inte varmt limträ",
		tb ~= nil and sammaFarg(tb.Color, R2.takfarg.balk),
		tb and string.format("rgb(%d,%d,%d)", tb.Color.R*255, tb.Color.G*255,
			tb.Color.B*255) or "saknas")
	check("undertaket läser den mätta plåtfärgen",
		tf ~= nil and sammaFarg(tf.Color, R2.takfarg.plat))
	-- Balkantalet följer delningen, inte ett tal skrivet här.
	local vantade = math.ceil((R2.langd - R2.takstomme.start) / R2.takstomme.delning)
	check("antalet takbalkar följer takstomme.delning",
		raknaNamn("Ridhus takbalk") == vantade,
		raknaNamn("Ridhus takbalk") .. " av " .. vantade)
end

check("domarbåset byggdes med nivå, tak, trappa och räcken",
	raknaNamn("Domarbåsets nivå") == 1 and raknaNamn("Domarbåsets tak") == 2
		and raknaNamn("Domarbåsets trappsteg") > 0
		and raknaNamn("Domarbåsets räcke") > 0
		and raknaNamn("Exit-skylt") == 1,
	string.format("nivå %d, takfall %d, steg %d, räcken %d, skylt %d",
		raknaNamn("Domarbåsets nivå"), raknaNamn("Domarbåsets tak"),
		raknaNamn("Domarbåsets trappsteg"), raknaNamn("Domarbåsets räcke"),
		raknaNamn("Exit-skylt")))

check("klockan byggdes", raknaNamn("Klockan") == 1)

do
	-- Sargen får inte stänga porten man rider in genom.
	local vast, ost = nil, nil
	for _, d in ipairs(delar) do
		if d.Name == "Sarg norr väst" then vast = fot(d) end
		if d.Name == "Sarg norr öst" then ost = fot(d) end
	end
	local gap = if vast and ost then (ost.x - (vast.x + vast.w)) else -1
	check("porten är ett verkligt gap i sargen", gap > 1.5 and gap < 4,
		string.format("%.2f m", gap))
end

print("\nIgenkänningsdragen — Review 03:s visual parity blocker")

do
	local I = UBRFKomplex.identitet
	local stall = nil
	for _, b in ipairs(UBRFKomplex.byggnader) do if b.id == "stall" then stall = b end end

	-- Stallets exteriör.
	check("takhuvarna byggdes, en per box", raknaNamn("Takhuv ") == I.stall.huvrad.antal,
		raknaNamn("Takhuv ") .. " av " .. I.stall.huvrad.antal)

	do
		-- Huvarna ska sitta på NOCKEN, inte bredvid huset.
		local cx, fel = stall.rekt.x + stall.rekt.w / 2, 0
		local n = 0
		for _, d in ipairs(delar) do
			if string.find(d.Name, "Takhuv ", 1, true) then
				n += 1
				local f = fot(d)
				if math.abs(f.x + f.w / 2 - cx) > 0.2 then fel += 1 end
				if f.z0 < stall.hN - 0.5 then fel += 1 end
			end
		end
		check("huvarna sitter på nocklinjen", n > 0 and fel == 0, fel .. " fel av " .. n)
	end

	check("snörasskyddet byggdes på båda takfallen", raknaNamn("Snörasskydd") == 2)
	check("förstukvisten byggdes", raknaNamn("Förstukvist") >= 3,
		raknaNamn("Förstukvist") .. " delar")
	check("balkongen byggdes", raknaNamn("Balkong") == 2)
	check("spiraltrappan byggdes", raknaNamn("Spiraltrappsteg") == I.stall.spiraltrappa.steg,
		raknaNamn("Spiraltrappsteg") .. " steg")

	do
		-- Förstukvisten ska sitta på VÄSTRA långsidan, utanför väggen.
		local f = nil
		for _, d in ipairs(delar) do
			if d.Name == "Förstukvist golv" then f = fot(d) end
		end
		check("förstukvisten skjuter ut ur västra långsidan",
			f ~= nil and f.x < stall.rekt.x + 0.01 and f.x + f.w >= stall.rekt.x - 0.01,
			f and string.format("x %.1f–%.1f, husets vägg %.1f",
				f.x, f.x + f.w, stall.rekt.x) or "hittades inte")
	end

	do
		-- Balkongen ska sitta på KLUBBGAVELN i norr, i gavelns mitt.
		local f = nil
		for _, d in ipairs(delar) do
			if d.Name == "Balkong" then f = fot(d) end
		end
		local gm = stall.rekt.x + stall.rekt.w / 2
		check("balkongen sitter mitt på klubbgaveln",
			f ~= nil and math.abs(f.x + f.w / 2 - gm) < 0.2
				and f.y >= stall.rekt.y + stall.rekt.h - 0.01,
			f and string.format("mitt x %.1f, gavelns mitt %.1f", f.x + f.w / 2, gm) or "saknas")
	end

	--[[ Ridhusets interiörfynd.

		De två testerna här löd förut "byggdes på BÅDA sidor" och krävde
		2 × läkt. De kodade alltså in det fel som fotot motsäger — panelen
		täcker EN DEL av EN långsida — och höll det på plats: Roblox byggde
		den på båda sidor i full längd medan sviten var grön.

		Ett test som skriver av bygget i stället för källan skyddar felet.
		De mäter nu RELATIONERNA mot den delade datan. ]]
	do
		local O = I.ridhus.ovreVagg
		local R2 = UBRFKomplex.ridhus
		check("den rostbruna panelen byggdes på EN långsida",
			raknaNamn("Övre långvägg") == 1,
			raknaNamn("Övre långvägg") .. " väggar")
		check("väggläkten följer panelen, inte båda sidor",
			raknaNamn("Väggläkt") == O.listar,
			raknaNamn("Väggläkt") .. " av " .. O.listar)

		local v = forstaNamn("Övre långvägg")
		local f = v and fot(v)
		check("panelen täcker BARA sitt stycke, inte hela hallen",
			f ~= nil and math.abs(f.h - (O.y1 - O.y0)) < 0.2
				and f.h < R2.langd * 0.75,
			f and string.format("%.1f m av hallens %.1f", f.h, R2.langd) or "saknas")

		--[[ LOKALA koordinater. Första versionen jämförde f.x (världsläge,
			~118) mot bredd/2 (~12,5) och föll fast bygget var riktigt — samma
			sjuka som testerna redan fällts på i den här sviten. ]]
		local mitt = R2.bredd / 2
		local lokalX = f and (f.x - R2.origo.x)
		check("panelen ligger på den sida sidor.panel pekar ut",
			lokalX ~= nil and (if O.sida == "W" then lokalX < mitt else lokalX > mitt),
			f and string.format("sida %s, lokal x %.1f av %.1f",
				O.sida, lokalX, R2.bredd) or "saknas")

		--[[ Sponsorskyltarna fanns inte alls i Roblox. Antal OCH ordning
			mäts: förenklad grafik är i sin ordning, fel antal eller fel
			ordning är det inte. ]]
		check("sponsorskyltarna byggdes, lika många som i datan",
			raknaNamn("Sponsorskylt") == #R2.skyltar,
			raknaNamn("Sponsorskylt") .. " av " .. #R2.skyltar)
		do
			local utanfor = 0
			for _, d in ipairs(delar) do
				if string.find(d.Name, "Sponsorskylt", 1, true) then
					local sf = fot(d)
					if sf.y < R2.origo.y + O.y0 - 0.5
						or sf.y + sf.h > R2.origo.y + O.y1 + 0.5 then
						utanfor += 1
					end
				end
			end
			check("alla sponsorskyltar sitter innanför panelens stycke",
				utanfor == 0, utanfor .. " utanför")
		end
	end
	check("takets stålprofiler byggdes",
		raknaNamn("Stålprofil") == #I.ridhus.takProfiler.andelar,
		raknaNamn("Stålprofil") .. " st")
	check("kabelstegarna byggdes med stegpinnar",
		raknaNamn("Kabelstege") == 2 * #I.ridhus.kabelstegar.andelar
			and raknaNamn("Stegpinne") > 20,
		raknaNamn("Stegpinne") .. " pinnar")
	check("ventilationskanalerna byggdes med don",
		raknaNamn("Ventkanal") == #I.ridhus.ventkanaler.andelar
			and raknaNamn("Ventdon") > 5,
		raknaNamn("Ventdon") .. " don")

	do
		-- Allt i taket ska sitta i TAKET, inte i ögonhöjd.
		local lagt = 0
		for _, d in ipairs(delar) do
			local n = d.Name
			if string.find(n, "Stålprofil", 1, true) or string.find(n, "Kabelstege", 1, true)
				or string.find(n, "Ventkanal", 1, true) then
				if fot(d).z0 < UBRFKomplex.ridhus.tak - 2.5 then lagt += 1 end
			end
		end
		check("takinstallationerna sitter uppe i taket", lagt == 0,
			lagt .. " för lågt")
	end

	do
		-- Den övre långväggen ska börja ovanför sargen och sluta under taket.
		local R2 = UBRFKomplex.ridhus
		local f = nil
		for _, d in ipairs(delar) do
			if d.Name == "Övre långvägg" then f = fot(d) end
		end
		check("övre långväggen sitter mellan sargen och taket",
			f ~= nil and f.z0 >= R2.sargH - 0.01 and f.z1 <= R2.tak + 0.01,
			f and string.format("z %.2f–%.2f, sarg %.2f, tak %.2f",
				f.z0, f.z1, R2.sargH, R2.tak) or "saknas")
	end
end

print("\nBanområdet — staket och belysning")

-- Uteridbanan hade inget staket alls i Roblox: webben ritade två reglar, och
-- primärplattformen ritade ingenting. Fotona i references/omnejd/banan-01..03
-- visar TRE reglar. Mät att det faktiskt kom ut åt båda hållen.
do
	local S = UBRFKomplex.banomrade.staket

	-- Uteridbanans västra långsida går x=176 från y=119 till y=159.
	-- Räkna det liggande virket längs den linjen och kontrollera att det
	-- är EN toppregel, EN sandsyll och eltrådarna — inte en stapel reglar.
	-- Banans rektangel LÄSES ur den exporterade geometrin. Koordinaterna stod
	-- avskrivna här (x = 176, y 119–159) och föll när banans MÄTTA kortsida
	-- flyttade den — fast staketet satt precis rätt. Fjärde stället i den här
	-- sviten med samma sjuka; därför exporteras banorna nu med namn.
	local B = UBRFKomplex.banor.uteridbanan
	local function langsVastraLangsidan(namn)
		local ut = {}
		for _, d in ipairs(delar) do
			if d.Name == namn then
				local f = fot(d)
				if math.abs(f.x + f.w / 2 - B.x) < 0.2 and f.h > B.h * 0.5 then
					table.insert(ut, f.z0 + (f.z1 - f.z0) / 2)
				end
			end
		end
		return ut
	end

	local topp = langsVastraLangsidan("Staketets toppregel")
	check("uteridbanan har en toppregel", #topp == 1, #topp .. " funna")
	check("toppregeln sitter på rätt höjd",
		#topp == 1 and math.abs(topp[1] - S.toppregel.z) < 0.02,
		#topp == 1 and string.format("%.2f m", topp[1]) or "kunde inte mätas")

	local syll = langsVastraLangsidan("Sandsyll")
	check("uteridbanan har sandsyllen som håller sanden", #syll == 1,
		#syll .. " funna")

	local trad = langsVastraLangsidan("Eltrad")
	check("eltrådarna följer BANOMRADE", #trad == #S.tradar,
		#trad .. " trådar av " .. #S.tradar)

	-- Hagarna omsluter gräs, inte sand, och ska INTE ha någon syll.
	-- Hage Ö1 går x=178 från y=65 till y=93.
	local hagsyll = 0
	for _, d in ipairs(delar) do
		if d.Name == "Sandsyll" then
			local f = fot(d)
			local mx, my = f.x + f.w / 2, f.y + f.h / 2
			local vid = false
			for _, r in pairs(UBRFKomplex.banor) do
				if mx >= r.x - 1 and mx <= r.x + r.w + 1
					and my >= r.y - 1 and my <= r.y + r.h + 1 then vid = true end
			end
			if not vid then hagsyll += 1 end
		end
	end
	check("hagarna har ingen sandsyll", hagsyll == 0, hagsyll .. " funna")

	local stolpar = raknaNamn("Staketstolpe")
	check("staketet fick stolpar", stolpar > 40, stolpar .. " stolpar")
	check("isolatorerna sitter på stolparna",
		raknaNamn("Isolator") > 0, raknaNamn("Isolator") .. " isolatorer")
end

-- Belysningsmasterna: dubbel armatur på tvärarm, en mast i vart och ett av
-- uteridbanans fyra hörn.
do
	-- B måste hämtas HÄR också: den var deklarerad i staketblocket ovanför och
	-- syntes inte i det här. Specen kraschade därför på B.x — och min gamla
	-- kontroll räknade rader som börjar med FEL, fick noll, och kallade det
	-- grönt. roblox/tests/kor.sh kräver numera att specen NÅR sin slutrad.
	local B = UBRFKomplex.banor.uteridbanan
	local MA = UBRFKomplex.banomrade.mast
	local master, armaturer = raknaNamn("Belysningsmast"), raknaNamn("Mastarmatur")
	local i_props = 0
	for _, pr in ipairs(UBRFKomplex.props) do
		if pr.typ == "mast" then i_props += 1 end
	end
	check("varje mast i datan blev en mast i modellen",
		master == i_props, master .. " byggda av " .. i_props .. " i datan")
	check("varje mast har två armaturer", armaturer == master * 2,
		armaturer .. " armaturer på " .. master .. " master")

	-- Hörnen på uteridbanan (x 176..196, y 119..159).
		local horn = { { B.x, B.y }, { B.x + B.w, B.y },
		               { B.x, B.y + B.h }, { B.x + B.w, B.y + B.h } }
	local traffar = 0
	for _, h in ipairs(horn) do
		for _, d in ipairs(delar) do
			if d.Name == "Belysningsmast" then
				local f = fot(d)
				if math.abs(f.x + f.w / 2 - h[1]) < 0.5
					and math.abs(f.y + f.h / 2 - h[2]) < 0.5 then
					traffar += 1
					break
				end
			end
		end
	end
	check("uteridbanans fyra hörn har var sin mast", traffar == 4,
		traffar .. " av 4 hörn")

	local hojd = 0
	for _, d in ipairs(delar) do
		if d.Name == "Belysningsmast" then hojd = fot(d).z1 end
	end
	check("masten är lika hög som i datan",
		math.abs(hojd - MA.hojd) < 0.05, string.format("%.2f m", hojd))
end

print("\nHela modellen")

do
	-- Ingenting ska ha hamnat utanför tomten. En del som gör det betyder att
	-- något räknats i studs där det skulle vara meter, eller tvärtom.
	local ute = 0
	for _, d in ipairs(delar) do
		local f = fot(d)
		if f.x < -5 or f.y < -5 or f.x + f.w > UBRFKomplex.bredd + 5
			or f.y + f.h > UBRFKomplex.djup + 5 then ute += 1 end
	end
	check("ingen del hamnade utanför tomten", ute == 0, ute .. " utanför")
end

do
	-- Attributnamnen måste vara rena ASCII; stubben kastar annars. Att vi kom
	-- hit betyder att alla SetAttribute-anrop klarade sig.
	check("alla attributnamn är giltiga i Roblox", true,
		"stubben fäller å/ä/ö och skriptet kom igenom")
end

--[[ ── Skärmtaken över entrédörrarna ──────────────────────────────
	`skarm` låg i den delade geometrin och ritades av webben, men
	Anlaggningen.luau läste aldrig fältet — dörrarna stod som nakna luckor i
	Roblox medan de på webben bar ett vitt skärmtak. Ingen grind märkte det,
	för ingen frågade efter delarna.

	Provet räknar mot GEOMETRIN i stället för mot ett fast tal: fäller någon
	bort byggandet blir det noll, och läggs en dörr till i datan följer
	kravet med av sig självt. ]]
do
	local medSkarm = 0
	for _, bg in ipairs(UBRFKomplex.byggnader) do
		for _, o in ipairs(bg.oppningar or {}) do
			if o.skarm then medSkarm += 1 end
		end
	end
	check("geometrin har dörrar med skärmtak", medSkarm > 0, medSkarm .. " st")

	--[[ `raknaNamn` matchar PLAIN (string.find med plain=true), inte mönster.
		Första versionen av det här provet skickade "^Skärmtak$" och fick noll
		— inte för att delarna saknades, utan för att ankarna lästes som
		bokstäver. ]]
	local tak, konsoler = raknaNamn("Skärmtak"), raknaNamn("Skärmkonsol")
	check("varje skärmtaksdörr har fått sin platta", tak == medSkarm,
		tak .. " plattor mot " .. medSkarm .. " dörrar")
	check("varje skärmtak står på två konsoler", konsoler == medSkarm * 2,
		konsoler .. " konsoler mot " .. (medSkarm * 2) .. " väntade")

	--[[ Stallets klubbdörr mot grusplanen är den som avgör om entrén LÄSER
		som en entré från ankomsten. Den ska ha ett skärmtak. ]]
	local stall = nil
	for _, bg in ipairs(UBRFKomplex.byggnader) do
		if bg.id == "stall" then stall = bg end
	end
	local klubbdorr = false
	for _, o in ipairs(stall and stall.oppningar or {}) do
		if o.sida == "N" and o.typ == "dorrgul" and o.skarm then klubbdorr = true end
	end
	check("stallets klubbdörr mot grusplanen bär skärmtak", klubbdorr)
end

if fails > 0 then
	print(string.format("\n%d FEL", fails))
	error("bygge.spec: " .. fails .. " fel")
end
print("\nalla gröna")
