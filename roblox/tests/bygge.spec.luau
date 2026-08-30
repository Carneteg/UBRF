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

check("läktaren byggdes i fyra steg",
	raknaNamn("Läktarsteg") == UBRFKomplex.ridhus.laktare.steg,
	raknaNamn("Läktarsteg") .. " steg")

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
