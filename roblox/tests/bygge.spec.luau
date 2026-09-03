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
-- Exakt namn, inte delsträng: "Slutet rum sluten_volym" får inte räkna
-- "Slutet rum sluten_volym_v" som en träff.
local function raknaExakt(namn)
	local n = 0
	for _, d in ipairs(delar) do
		if d.Name == namn then n += 1 end
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
--[[ Omgranskat 2026-09-03: separata fönster per väggfält, inte ett band. ]]
do
	local falt = Geometri.ridhusFalt(UBRFKomplex.ridhus)
	local vantade = 0
	for _, f in ipairs(falt) do
		if math.min(UBRFKomplex.identitet.ridhus.fonsterband.faltBredd or 3.0, (f[2] - f[1]) - 1.0) >= 0.8 then vantade += 1 end
	end
	check("ridhusets fönster byggdes ett per väggfält, inget löpande band",
		raknaNamn("Ridhus fönster ") == vantade and vantade > 5 and raknaNamn("Ridhus fönsterband") == 0,
		string.format("%d fönster mot %d fält", raknaNamn("Ridhus fönster "), vantade))
	check("väggpelarna står på fältgränserna på båda långsidorna",
		raknaNamn("Väggpelare W") == raknaNamn("Väggpelare E") and raknaNamn("Väggpelare W") >= #falt - 1
			and raknaNamn("Väggpelare W") > 5,
		string.format("%d W, %d E, %d fält", raknaNamn("Väggpelare W"), raknaNamn("Väggpelare E"), #falt))
end

--[[ KLUBBDELEN ur utrymningsplanen, rättad av Product Owner 2026-09-03.

	Provet hette "klubbrummen byggdes som rum" och räknade tre lådor med
	rätt namn. Det låste fast fel sak: rummen är golv man går på, och det
	som ska stämma är väggarna, dörrarna, rutten och rummens inbördes lägen
	— det Tobias beskrev från sin egen runda. ]]
do
	local S = UBRFKomplex.stall
	local K = S.klubb
	local function rum(id)
		for _, r in ipairs(K.rum) do if r.id == id then return r end end
		return nil
	end
	local function vagg(id)
		for _, v in ipairs(K.vaggar) do if v.id == id then return v end end
		return nil
	end

	-- 1 · Varje vägg byggdes i precis så många bitar som dess öppningar ger.
	for _, v in ipairs(K.vaggar) do
		local bitar = Geometri.vaggBitar(v)
		local byggda = raknaNamn("Klubbvägg " .. v.id .. ":")
		check(string.format("klubbväggen %s byggdes i planens bitar", v.id),
			byggda == #bitar, string.format("%d byggda mot %d i datan", byggda, #bitar))
	end

	--[[ 2 · Den genomgående väggen har BARA planens två dörrar. Samma prov
		som fällde `foljGangar` förra rundan, nu på rätt vägg: öppen bredd i det
		BYGGDA mot summan av de deklarerade öppningarna. Fler hål faller,
		färre likaså. ]]
	local genom = vagg("genomgaende")
	check("den genomgående väggen finns i datan", genom ~= nil)
	local inre = nil
	if genom then
		local murat = 0
		for _, d in ipairs(delar) do
			if string.find(d.Name, "Klubbvägg genomgaende:", 1, true) then murat += fot(d).w end
		end
		local hal = 0
		for _, o in ipairs(genom.oppningar) do
			hal += math.min(o.x1, S.bredd) - math.max(o.x0, 0)
			if o.id == "inre_entre" then inre = o end
		end
		check("den genomgående väggen har bara planens två dörrar",
			#genom.oppningar == 2 and math.abs((S.bredd - murat) - hal) < 0.15,
			string.format("%.2f m öppet, planen anger %.2f m i %d dörrar",
				S.bredd - murat, hal, #genom.oppningar))
		--[[ Tobias: "rakt fram genom den inre entrén kommer man in i
			stallgång A". Dörren måste alltså överlappa gång A:s x-intervall,
			inte en boxrad. Mätt mot samma `gangar` som bygget använder. ]]
		local A = S.gangar.A
		check("den inre entrén mynnar rakt i stallgång A",
			inre ~= nil and inre.x1 > A.x0 + 0.05 and inre.x0 < A.x1 - 0.05,
			inre and string.format("dörren x %.1f–%.1f, gång A x %.2f–%.2f",
				inre.x0, inre.x1, A.x0, A.x1) or "ingen inre entré i datan")
	end

	--[[ 3 · RUTTEN Tobias beskrev, provad mot det BYGGDA: entrén i gaveln →
		uppehållsrummet → lobbyn mellan toaletterna → den inre entrén → gång A.
		Ingen kolliderande del under mankhöjd får stå på någon provpunkt. Muras
		en dörr igen, eller byggs ett rum som låda, faller det här. ]]
	local rutt = {
		{ 4.55, 69.0 }, { 4.55, 66.5 }, { 4.5, 63.0 }, { 4.5, 61.0 }, { 4.9, 58.5 },
		{ 4.55, 57.45 }, { 4.9, 56.0 }, { 5.5, 53.5 }, { 5.5, 50.0 },
	}
	local blockerad = nil
	for _, p in ipairs(rutt) do
		local px, py = S.origo.x + p[1], S.origo.y + p[2]
		for _, d in ipairs(delar) do
			if d.CanCollide then
				local f = fot(d)
				--[[ Golvplattor och trösklar räknas inte: något man snubblar
					på är inte en vägg. Det som spärrar en rutt är delar som når
					över knähöjd och är mer än en platta tjocka. ]]
				local sparrar = f.z1 - f.z0 > 0.3 and f.z1 > 0.6 and f.z0 < 1.7
				if sparrar and px > f.x and px < f.x + f.w and py > f.y and py < f.y + f.h then
					blockerad = blockerad or string.format("%s vid (%.1f, %.1f)", d.Name, p[1], p[2])
				end
			end
		end
	end
	check("rutten entré → uppehållsrum → inre entré → gång A är fri från solitt",
		blockerad == nil, blockerad or (#rutt .. " provpunkter fria"))

	--[[ 4 · Rummens inbördes lägen, som Tobias gav dem. "Vänster" är gående
		riktning söderut från parkeringen, alltså öster. ]]
	local U, T, SK = rum("uppehallsrum"), rum("teorisal"), rum("sadelkammare")
	local W1, W2, SV = rum("wc_v"), rum("wc_o"), rum("sluten_volym")
	check("planens klubbrum finns i datan",
		U and T and SK and W1 and W2 and SV)
	if U and T and SK and W1 and W2 and SV and inre then
		check("teorisalen ligger till vänster om uppehållsrummet (öster)",
			T.rekt.x >= U.rekt.x + U.rekt.w - 0.01,
			string.format("teorisal x %.1f, uppehållsrummets östkant %.1f", T.rekt.x, U.rekt.x + U.rekt.w))
		check("sadelkammaren nås vänster och sedan höger: öster om uppehållsrummet, söder om teorisalen",
			SK.rekt.x >= U.rekt.x + U.rekt.w - 0.01 and SK.rekt.y + SK.rekt.h <= T.rekt.y + 0.01)
		check("toaletterna sitter en på var sida om den inre entrén",
			W1.rekt.x + W1.rekt.w <= inre.x0 + 0.01 and W2.rekt.x >= inre.x1 - 0.01
				and W1.rekt.y < K.y0 + 0.01 and W2.rekt.y < K.y0 + 0.01,
			string.format("WC x %.1f–%.1f | dörr %.1f–%.1f | WC x %.1f–%.1f",
				W1.rekt.x, W1.rekt.x + W1.rekt.w, inre.x0, inre.x1, W2.rekt.x, W2.rekt.x + W2.rekt.w))
		check("planens symbolruta byggs som namnlös sluten volym — inget trapphus, ingen trappa i Stallhuset",
			SV.stangt == true and (SV.label == nil or SV.label == "")
				and raknaExakt("Slutet rum sluten_volym") == 1
				and rum("trapphus") == nil and raknaNamn("Slutet rum trapphus") == 0
				and raknaNamn("Trappsteg") == 0,
			string.format("label %q, %d slutna volymer, %d trapphus, %d trappsteg",
				tostring(SV.label), raknaExakt("Slutet rum sluten_volym"),
				raknaNamn("Slutet rum trapphus"), raknaNamn("Trappsteg")))
		check("Ö-toaletten är sluten tills dess dörr är belagd",
			W2.stangt == true and raknaNamn("Slutet rum wc_o") == 1)
	end
end

--[[ Etikettplattor bara för rum som har ett namn. Rum med `label = ""` är
	avsiktligt namnlösa (funktion REFERENCE GAP): webben ritar ingen text för
	dem, och Roblox får inte bygga en tom "Rumsetikett "-platta — det vore
	Roblox-egen geometri i rum som ska vara tomma. Tom sträng är sann i Luau,
	så bygget måste pröva längden, inte bara att fältet finns. ]]
do
	local S2, R3 = UBRFKomplex.stall, UBRFKomplex.ridhus
	local vantade, namnlosa = 0, 0
	for _, block in ipairs({ S2.klubb, R3.entrehall }) do
		for _, r in ipairs(block.rum or {}) do
			if not r.stangt then
				if r.label ~= nil and r.label ~= "" then vantade += 1 else namnlosa += 1 end
			end
		end
	end
	local tomma, byggda = 0, 0
	for _, d in ipairs(delar) do
		if d.Name == "Rumsetikett " or d.Name == "Rumsetikett" then tomma += 1 end
		if string.find(d.Name, "Rumsetikett", 1, true) == 1 then byggda += 1 end
	end
	check("namnlösa öppna rum får ingen tom etikettplatta i Roblox",
		namnlosa > 0 and tomma == 0,
		string.format("%d namnlösa öppna rum, %d tomma plattor", namnlosa, tomma))
	check("etikettplattor byggs för exakt de namngivna öppna rummen",
		byggda == vantade and vantade > 0,
		string.format("%d plattor mot %d namngivna öppna rum", byggda, vantade))
end

--[[ Inomhusläsbarhet: varje inre väggbit och sluten volym ska bära
	attributet `Genomsiktlig`, annars kan klientens Genomsikt inte tona den
	när den står mellan kameran och karaktären — och då försvinner spelaren
	bakom väggen igen (Product Owner 2026-09-03). ]]
do
	local med, utan = 0, 0
	for _, d in ipairs(delar) do
		local n = d.Name
		if n:find("Klubbvägg", 1, true) == 1 or n:find("Entrévägg", 1, true) == 1
			or n:find("Slutet rum", 1, true) == 1 then
			if d:GetAttribute("Genomsiktlig") == true then med += 1 else utan += 1 end
		end
	end
	check("inre väggbitar och slutna volymer bär attributet Genomsiktlig",
		utan == 0 and med > 20, string.format("%d med, %d utan", med, utan))
end

--[[ SPATIAL CANON v2 i bygget: varje Klubbvägg-bit och slutet rum bär
	CanonId/SourceId/Confidence/Primitiv (SCV2-02, SCV2-05), ingen del står i
	uppehållsrummets öppna yta (SCV2-01), och den återkallade volymen är
	inte byggd. ]]
do
	local S3 = UBRFKomplex.stall
	local o = S3.origo
	local zon = nil
	for _, z in ipairs(S3.klubb.oppna or {}) do if z.id == "stall_uppehall_open" then zon = z end end
	local utan, i_ytan, med = {}, {}, 0
	for _, d in ipairs(delar) do
		local n = d.Name
		if n:find("Klubbvägg", 1, true) == 1 or n:find("Slutet rum", 1, true) == 1 then
			local f = fot(d)
			-- bara stallets delar: klubbväggarna heter Klubbvägg, entrédelens Entrévägg
			local iStall = f.x >= o.x - 1 and f.x <= o.x + S3.bredd + 1 and f.y >= o.y - 1 and f.y <= o.y + S3.langd + 1
			if iStall then
				if d:GetAttribute("CanonId") and d:GetAttribute("SourceId") and d:GetAttribute("Confidence") and d:GetAttribute("Primitiv") then
					med += 1
				else
					table.insert(utan, n)
				end
				if zon then
					for _, q in ipairs(zon.rekt) do
						local ox = math.min(f.x + f.w, o.x + q.x + q.w) - math.max(f.x, o.x + q.x)
						local oy = math.min(f.y + f.h, o.y + q.y + q.h) - math.max(f.y, o.y + q.y)
						if ox > 0.12 and oy > 0.12 then table.insert(i_ytan, n) end
					end
				end
			end
		end
	end
	check("SCV2-02/05: alla klubbväggar och slutna volymer i stallet bär kanon-attribut i Roblox",
		#utan == 0 and med > 10, #utan > 0 and table.concat(utan, ", ") or (med .. " delar med provenance"))
	check("SCV2-01: ingen byggd vägg eller volym står i uppehållsrummets öppna yta",
		#i_ytan == 0, #i_ytan > 0 and table.concat(i_ytan, ", ") or "ytan är fri")
	check("den återkallade volymen och det lilla rummet är inte byggda",
		raknaExakt("Slutet rum sluten_volym_v") == 0 and raknaExakt("Slutet rum litet_rum") == 0)
end

--[[ HÄSTFÖRBINDELSEN bryter BARA västra boxraden — Product Owner 2026-09-03:
	"hästförbindelsen bryter boxraden ungefär på mitten". Planen visar
	mittraderna och östra raden obrutna förbi samma höjd. Spelet hade en
	tvärgång genom alla fyra rader; den är borta. ]]
do
	local S = UBRFKomplex.stall
	local b = S.brott and S.brott[1]
	check("brottet finns och ligger i västra raden", b ~= nil and b.rad == "W")
	if b then
		local rader = {}
		for _, r in ipairs(S.rader) do rader[r.id] = r end
		local nW, nMA = #Geometri.boxfack(S, rader.W), #Geometri.boxfack(S, rader.MA)
		check("västra raden har ett fack färre än mittraden",
			nW == nMA - 1, string.format("W %d, MA %d", nW, nMA))
		check("mittraderna och östra raden är obrutna, lika många fack som planen",
			nMA == S.antalBoxar and #Geometri.boxfack(S, rader.MB) == S.antalBoxar
				and #Geometri.boxfack(S, rader.E) == S.antalBoxar,
			string.format("MA %d, MB %d, E %d mot %d", nMA,
				#Geometri.boxfack(S, rader.MB), #Geometri.boxfack(S, rader.E), S.antalBoxar))
		--[[ Mätt i det byggda: ingen boxfront i W-raden står i brottet, och
			minst en boxfront i mittraden gör det — annars är raden inte obruten. ]]
		local iW, iMA = 0, 0
		for _, d in ipairs(delar) do
			local f = fot(d)
			local overlappar = f.y < S.origo.y + b.y1 - 0.05 and f.y + f.h > S.origo.y + b.y0 + 0.05
			if overlappar and string.find(d.Name, "Boxfront W", 1, true) then iW += 1 end
			if overlappar and string.find(d.Name, "Boxfront MA", 1, true) then iMA += 1 end
		end
		check("ingen boxfront står i hästförbindelsens brott i västra raden", iW == 0, iW .. " fronter")
		check("mittraden fortsätter obruten förbi brottet", iMA >= 1, iMA .. " fronter")
		--[[ Brottet och fasadens hästgångsdörr är EN förbindelse: dörren in
			till stallet (`dorrar.hastgang`) står inne i brottet. ]]
		local hd = nil
		for _, d in ipairs(S.dorrar) do if d.id == "hastgang" then hd = d end end
		check("hästgångens dörr står i brottet",
			hd ~= nil and hd.pos[2] > b.y0 and hd.pos[2] < b.y1,
			hd and string.format("dörr y %.2f, brott %.2f–%.2f", hd.pos[2], b.y0, b.y1) or "ingen dörr")
		check("webbens facklista och Roblox regel ger samma fack",
			S.fack ~= nil and #S.fack.W == nW and #S.fack.MA == nMA,
			S.fack and string.format("webb W %d MA %d", #S.fack.W, #S.fack.MA) or "inget fack-fält")
	end
end

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
	--[[ Väggen provet handlar om är den mot SERVICEDELEN — den som ska få hål
		av planen UTÖVER gångarnas. F02-A la till en vägg i klubbdelen som
		också har `oppningar` men som inte följer gångarna, och den plockades
		upp här i stället: 1 bit mot 3, alltså rött. Provet valde "sista
		väggen med öppningar", vilket råkade vara rätt så länge det bara fanns
		en. Villkoret är skärpt, inte lättat. ]]
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

	--[[ Tvärväggarna i den här listan ligger alla i boxhallen och ska ha ett
		hål där varje gång passerar. Klubbdelens väggar, som inte följer
		gångarna, ligger i `klubb.vaggar` och provas för sig ovan — det är
		därför flaggan `foljGangar` och dess prov är borta: ingen vägg i den här
		listan behöver undantaget längre. ]]
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

	--[[ Ingen trappa och inget trapphus i Stallhuset.

		Planens symbol i klubbdelens ruta lästes en gång som en egen trappa upp,
		och en runda senare som ett "trapphus". Ingen av läsningarna har en
		oberoende källa. Den vertikala förbindelse som är belagd är ridhusets:
		läktarplanet, C-kortändans trappor och den glasade gången
		(`RIDHUSINNE.kortanda.trappor`). Rått foto/film slår en symboltolkning.

		Villkoren för den påhittade trappan är därför borta, inte omskrivna, och
		rutan bär varken namn eller skylt (`sluten_volym`, funktion REFERENCE
		GAP). Om någon vill ge den en funktion igen krävs verifierat underlag —
		inte bara en symbol i utrymningsplanen. ]]

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
		if d.Name == "Ridbanan" then bana = fot(d) end
	end
	local R0 = UBRFKomplex.ridhus
	check("banan byggdes som den fysiska ridytan sarg till sarg, inte 60 m", bana ~= nil
		and math.abs(bana.w - R0.bana.w) < 0.01 and math.abs(bana.h - R0.bana.h) < 0.01
		and bana.h > 60,
		bana and string.format("%.1f × %.1f m vid (%.1f, %.1f)",
			bana.w, bana.h, bana.x, bana.y) or "hittades inte")
	check("A-sargen står mot A-gaveln i bygget — ingen flermeterszon bakom (ridhus-inne-23)",
		bana ~= nil and (bana.y - R0.origo.y) <= 0.5 and (bana.y - R0.origo.y) >= -0.01,
		bana and string.format("gap %.2f m", bana.y - R0.origo.y) or "saknas")
	check("dressyrlayouten 20 × 60 byggdes som osynlig markör med förankring A",
		raknaNamn("Dressyrlayout 20x60") == 1)
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

--[[ Norra sargen i två stycken med spelets gap emellan. Gapet är en
	SPELABSTRAKTION (ingen bild visar en grind; bredden vald) och ska
	byggas MÄRKT som sådan: en markördel med klass och fidelity som
	attribut, okolliderande. Testet mäter märkningen, inte verkligheten. ]]
check("sargen byggdes i två stycken i norr, med spelets gap emellan",
	raknaNamn("Sarg norr väst") == 1 and raknaNamn("Sarg norr öst") == 1
		and raknaNamn("Sarg syd") == 1)
do
	local m = forstaNamn("Spelabstraktion sargport")
	check("spelets sargport är byggd som märkt SPELABSTRAKTION, inte som fidelity",
		m ~= nil and m.CanCollide == false and m:GetAttribute("Klass") == "SPELABSTRAKTION"
			and m:GetAttribute("Fidelity") == "REFERENCE GAP",
		m and tostring(m:GetAttribute("Klass")) or "markör saknas")
end

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
check("läktaren byggdes som ETT plant däck, utan gap",
	raknaNamn("Läktardäck") == 1 and raknaNamn("Läktarfront") == 1
		and raknaNamn("Läktarsteg") == 0,
	string.format("%d däck, %d fronter, %d gamla stegdelar",
		raknaNamn("Läktardäck"), raknaNamn("Läktarfront"),
		raknaNamn("Läktarsteg")))

--[[ Fronten ska stå mot BANAN. Efter speglingen till väster låg den mot
	ytterväggen i ett första försök — däcket löper från x0 i positiv x-led
	på båda sidor, och "x0 − 0,10" är bara fronten när läktaren står i öster.
	Mätt: fronten ska ligga på banans sida av däcket. ]]
do
	local R2 = UBRFKomplex.ridhus
	local dack, front = forstaNamn("Läktardäck"), forstaNamn("Läktarfront")
	if dack and front then
		local fd, ff = fot(dack), fot(front)
		local banX = R2.origo.x + R2.bana.x + R2.bana.w / 2
		local dackMitt = fd.x + fd.w / 2
		local frontMot = if banX > dackMitt then ff.x >= fd.x + fd.w - 0.2 else ff.x + ff.w <= fd.x + 0.2
		check("läktarfronten står på banans sida av däcket", frontMot,
			string.format("däck x %.2f–%.2f, front x %.2f, banans mitt %.2f",
				fd.x, fd.x + fd.w, ff.x, banX))
	end
end

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

--[[ ENTRÉDELEN ur planen, byggd med samma byggare som stallets klubbdel.
	Provas som väggbitar mot deklarerade luckor, slutna rum som volymer och
	en fri rutt: från huvudentrén i västväggen, söderut genom korridoren,
	väster om C-blocket och genom sargporten ut på banan. ]]
do
	local R2 = UBRFKomplex.ridhus
	local E = R2.entrehall
	if E then
		for _, v in ipairs(E.vaggar) do
			local bitar = Geometri.vaggBitar(v)
			local byggda = raknaNamn("Entrévägg " .. v.id .. ":")
			check(string.format("entréväggen %s byggdes i planens bitar", v.id),
				byggda == #bitar, string.format("%d byggda mot %d i datan", byggda, #bitar))
		end
		check("toaletterna och schaktet byggdes som slutna volymer",
			raknaNamn("Slutet rum wc_n1") == 1 and raknaNamn("Slutet rum wc_n2") == 1
				and raknaNamn("Slutet rum schakt") == 1)
		--[[ Blocker 1: den kryssade rutan får inte byggas som "hiss" och får
			ingen etikettplatta — funktionen är okänd. ]]
		check("inget byggs som hiss, och schaktet har ingen rumsetikett",
			raknaNamn("hiss") == 0 and raknaNamn("HISS") == 0 and raknaNamn("Rumsetikett HISS") == 0)
		check("C-blocket står som ett solitt bänkblock i hallens södra kant",
			raknaNamn("Kortändans steg") == R2.kortanda.steg
				and raknaNamn("Kortändans sockel") == 1)
		--[[ Rutten. Provpunkterna följer planens gröna pilar: in i korridoren,
			söderut längs västväggen, ut väster om bänkblocket och genom porten. ]]
		local o = R2.origo
		-- rutten går genom SPELETS sargport (spelabstraktion), inte en fidelity-port
		local sp = UBRFKomplex.spelabstraktioner.ridhus.sargport
		local px0 = sp.x0 + 0.3
		local rutt = {
			{ 1.1, 74.2 }, { 1.1, 70.0 }, { 1.1, 66.0 }, { 1.1, 64.6 },
			{ 3.2, 66.5 }, { px0 + 0.6, 66.5 }, { px0 + 0.6, R2.bana.y + R2.bana.h - 1.5 },
			{ px0 + 0.6, R2.bana.y + R2.bana.h - 4.0 },
		}
		local blockerad = nil
		for _, p in ipairs(rutt) do
			local wx, wy = o.x + p[1], o.y + p[2]
			for _, d in ipairs(delar) do
				if d.CanCollide then
					local f = fot(d)
					local sparrar = f.z1 - f.z0 > 0.3 and f.z1 > 0.6 and f.z0 < 1.7
					if sparrar and wx > f.x and wx < f.x + f.w and wy > f.y and wy < f.y + f.h then
						blockerad = blockerad or string.format("%s vid (%.1f, %.1f)", d.Name, p[1], p[2])
					end
				end
			end
		end
		check("rutten entré → korridoren → väster om C-blocket → sargporten → banan är fri",
			blockerad == nil, blockerad or (#rutt .. " provpunkter fria"))
	end
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

--[[ "Klockan byggdes" provade den andra klockan vid en trätrappa i hallen.
	Den var en dubblett av C-blockets klocka och är borta; C-blockets provas
	ovan. Här mäts i stället att ingen dubblett smugit sig in igen. ]]
check("bara C-blockets klocka finns — ingen andra klocka i hallen",
	raknaNamn("Kortändans klocka") == 1 and raknaNamn("Klockan") == 0,
	string.format("%d C-klockor, %d andra", raknaNamn("Kortändans klocka"), raknaNamn("Klockan")))

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
		--[[ Förstukvisten ska sitta på NORRA GAVELN, utanför väggen, mot
			grusplanen. Provet vaktade fram till 2026-09-02 att den satt på
			VÄSTRA långsidan — det var rätt då och fångade riktigt när
			produktägaren bytte plats på verandan och gavelns enkla
			skärmtaksdörr. Villkoret är flyttat, inte borttaget. ]]
		local f = nil
		for _, d in ipairs(delar) do
			if d.Name == "Förstukvist golv" then f = fot(d) end
		end
		local norr = stall.rekt.y + stall.rekt.h
		check("förstukvisten skjuter ut ur norra gaveln",
			f ~= nil and f.y + f.h > norr + 0.01 and f.y <= norr + 0.01,
			f and string.format("y %.1f–%.1f, gavelns vägg %.1f",
				f.y, f.y + f.h, norr) or "hittades inte")
		--[[ ...och den ska ligga i gavelns bredd, inte hänga utanför hörnet. ]]
		check("förstukvisten ryms innanför gavelns hörn",
			f ~= nil and f.x >= stall.rekt.x - 0.01
				and f.x + f.w <= stall.rekt.x + stall.rekt.w + 0.01,
			f and string.format("x %.1f–%.1f, gaveln %.1f–%.1f", f.x, f.x + f.w,
				stall.rekt.x, stall.rekt.x + stall.rekt.w) or "hittades inte")
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
		--[[ Omgranskat 2026-09-03: panelen går hörn till hörn längs hela
			hallens långsida (ridhus-inne-31, -17), fram till entrédelen. ]]
		check("panelen täcker hallens hela långsida, A-gaveln → entrédelen",
			f ~= nil and math.abs(f.h - (O.y1 - O.y0)) < 0.2
				and math.abs(f.h - (R2.langd - R2.entre)) < 0.2,
			f and string.format("%.1f m av hallens %.1f", f.h, R2.langd - R2.entre) or "saknas")

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

	--[[ Stallets två entrédörrar, efter att produktägaren bytte plats på
		verandan och den enkla skärmtaksdörren 2026-09-02:

		  · gaveln mot grusplanen har entrédörren UNDER FÖRSTUKVISTEN, och
		    ska därför INTE ha ett eget skärmtak — verandan är dess tak,
		  · långsidan har den enkla dörren, och den SKA ha skärmtaket.

		Provet vaktar bytet åt båda håll. Skrivs bara den ena finns inget
		som hindrar att båda får skärmtak, eller ingen. ]]
	local stall = nil
	for _, bg in ipairs(UBRFKomplex.byggnader) do
		if bg.id == "stall" then stall = bg end
	end
	local gavelSkarm, langsidaSkarm = false, false
	for _, o in ipairs(stall and stall.oppningar or {}) do
		if o.typ == "dorrgul" and o.z0 == 0 then
			if o.sida == "N" and o.skarm then gavelSkarm = true end
			if o.sida == "W" and o.skarm then langsidaSkarm = true end
		end
	end
	check("gavelns entrédörr har INGET eget skärmtak — verandan är dess tak",
		not gavelSkarm)
	check("långsidans enkla dörr bär skärmtaket", langsidaSkarm)

	--[[ Förstukvisten ska stå på gaveln, inte på långsidan. `uFranOst` är
		gavelkonventionen; fanns `uFranNorr` kvar låg den på långsidan. ]]
	local K = UBRFKomplex.identitet.stall.forstukvist
	check("förstukvisten är placerad på gaveln", K.uFranOst ~= nil,
		"uFranOst = " .. tostring(K.uFranOst))
	check("verandan står fri från spiraltrappan",
		UBRFKomplex.identitet.stall.spiraltrappa.franGavelmitt
			> K.bredd / 2 + UBRFKomplex.identitet.stall.spiraltrappa.radie / 2,
		"trappa " .. UBRFKomplex.identitet.stall.spiraltrappa.franGavelmitt
			.. " m mot verandans kant " .. (K.bredd / 2))
end

if fails > 0 then
	print(string.format("\n%d FEL", fails))
	error("bygge.spec: " .. fails .. " fel")
end
print("\nalla gröna")
