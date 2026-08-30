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
	check("hästgångens västvägg står vid ridhusets östvägg",
		hg ~= nil and math.abs(hg.x - 143) < 0.05,
		hg and string.format("x = %.2f", hg.x) or "hittades inte")
end

print("\nStallets insida")

check("fyra boxrader byggdes", raknaNamn("Boxfront W") > 0 and raknaNamn("Boxfront MA") > 0
	and raknaNamn("Boxfront MB") > 0 and raknaNamn("Boxfront E") > 0,
	string.format("W %d, MA %d, MB %d, E %d fronter", raknaNamn("Boxfront W"),
		raknaNamn("Boxfront MA"), raknaNamn("Boxfront MB"), raknaNamn("Boxfront E")))

check("två gångar och tvärkorridoren fick golv",
	raknaNamn("Stallgång") == #UBRFKomplex.stall.gangytor,
	raknaNamn("Stallgång") .. " gångytor")

check("de namngivna rummen byggdes",
	raknaNamn("UPPEHÅLLSRUM") == 1 and raknaNamn("SADELKAMMARE") == 1
		and raknaNamn("SPOLSPILTA") == 1)

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
	check("banan ligger inne i ridhuset", bana ~= nil
		and bana.x >= 118 and bana.x + bana.w <= 143
		and bana.y >= 44 and bana.y + bana.h <= 119)
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

check("läktaren byggdes i två sektioner om fyra steg",
	raknaNamn("Läktarsteg") == UBRFKomplex.ridhus.laktare.steg * 2,
	raknaNamn("Läktarsteg") .. " stegdelar")

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

check("de tre glasade rummen byggdes",
	raknaNamn("Glasat rum") == #UBRFKomplex.ridhus.glasrum)

check("domarbåset och exit-skylten byggdes",
	raknaNamn("Domarbås") == 1 and raknaNamn("Exit-skylt") == 1)

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

	-- Ridhusets interiörfynd.
	check("den mörkröda övre långväggen byggdes på båda sidor",
		raknaNamn("Övre långvägg") == 2)
	check("väggläkten byggdes", raknaNamn("Väggläkt") == 2 * I.ridhus.ovreVagg.listar,
		raknaNamn("Väggläkt") .. " st")
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

if fails > 0 then
	print(string.format("\n%d FEL", fails))
	error("bygge.spec: " .. fails .. " fel")
end
print("\nalla gröna")
