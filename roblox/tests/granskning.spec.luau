--!nostrict
--[[
	F02:s granskningsläge — zonerna, dollhouse och vymodulen.

	Zonerna ska HÄRLEDAS ur UBRFKomplex, ligga inne i sina hus, bära en
	källklass ur gate-dokumentet, och luckorna ska finnas med som luckor.
	Dollhouse ska gömma taken och kunna sätta tillbaka dem exakt.

	Kör: python3 roblox/tests/build.py tests/granskning.spec.luau
	     && luau roblox/tests/.build/granskning.spec.luau
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

local TILLATNA = { PLAN = true, FOTO = true, DERIVED = true, GAP = true }

print("\n── Zonerna härleds ur datan ──")
local zoner = Granskning.zoner(UBRFKomplex, Planrum)
do
	check("det finns zoner att granska", #zoner >= 12, #zoner .. " st")
	check("planrummen följde med", #zoner >= 12 + #Planrum.lista,
		#zoner .. " varav " .. #Planrum.lista .. " planrum")

	local utanforHus, feltyp, obyggdaPlan, gap = 0, 0, 0, 0
	for _, z in ipairs(zoner) do
		if not TILLATNA[z.klass] then feltyp += 1 end
		if z.klass == "GAP" then gap += 1 end
		if z.klass == "PLAN" and not z.byggd then obyggdaPlan += 1 end
		if z.rekt then
			local hus = UBRFKomplex[z.hus]
			if z.rekt.x < -0.01 or z.rekt.y < -0.01
				or z.rekt.x + z.rekt.w > hus.bredd + 0.01
				or z.rekt.y + z.rekt.h > hus.langd + 0.01 then
				utanforHus += 1
				print("       utanför: " .. z.id)
			end
		end
	end
	check("varje zon bär en klass ur gate-dokumentet", feltyp == 0, feltyp .. " okända")
	check("varje ritbar zon ligger inne i sitt hus", utanforHus == 0, utanforHus .. " utanför")

	--[[ Luckorna ÄR leverabeln. Försvinner de ur listan har någon "städat"
		bort precis det Fas 1 finns för att visa. ]]
	check("ridhusets entrédel finns med som OBYGGD",
		obyggdaPlan >= 1, obyggdaPlan .. " obyggda PLAN-zoner")
	check("minst två REFERENCE GAP-zoner finns kvar", gap >= 2, gap .. " st")

	local entredel
	for _, z in ipairs(zoner) do
		if z.id == "ridhus_entredel" then entredel = z end
	end
	check("entrédelen har entre-djupet ur datan",
		entredel and entredel.rekt and math.abs(entredel.rekt.h - UBRFKomplex.ridhus.entre) < 0.001,
		entredel and entredel.rekt and tostring(entredel.rekt.h) or "saknas")
end

print("\n── Zonplattorna byggs med identitet ──")
do
	local mapp = workspace:FindFirstChild("Anläggning")
	local ubrf = mapp and mapp:FindFirstChild("UBRF")
	check("det finns en byggd värld att lägga plattor i", ubrf ~= nil)
	if ubrf then
		local antal = Granskning.byggZoner(BuildKit, UBRFKomplex, Planrum, ubrf, ubrf.PrimaryPart.CFrame)
		local ritbara = 0
		for _, z in ipairs(zoner) do
			if z.rekt then ritbara += 1 end
		end
		check("en platta per ritbar zon", antal == ritbara, antal .. " av " .. ritbara)

		local medId = 0
		for _, i in ipairs(ubrf:GetDescendants()) do
			if i:GetAttribute("RoomId") and i:GetAttribute("EvidenceClass") then medId += 1 end
		end
		check("varje platta bär RoomId och EvidenceClass", medId == antal,
			medId .. " av " .. antal)

		--[[ Andra passet får inte ackumulera plattor — samma regel som
			dörrprompterna och spawnen. ]]
		local antal2 = Granskning.byggZoner(BuildKit, UBRFKomplex, Planrum, ubrf, ubrf.PrimaryPart.CFrame)
		check("andra passet dubblar inte plattorna", antal2 == antal,
			antal .. " → " .. antal2)
	end
end

print("\n── Dollhouse gömmer taken och sätter tillbaka dem ──")
do
	local mapp = workspace:FindFirstChild("Anläggning")
	local ubrf = mapp and mapp:FindFirstChild("UBRF")
	if ubrf then
		local gomda = Granskning.dollhouse(ubrf, true)
		check("det fanns takdelar att gömma", gomda > 0, gomda .. " st")

		local synliga = 0
		for _, i in ipairs(ubrf:GetDescendants()) do
			if i:GetAttribute("TakDel") == true and i.Transparency < 1 then
				synliga += 1
			end
		end
		check("alla takdelar är gömda", synliga == 0, synliga .. " synliga")

		local tillbaka = Granskning.dollhouse(ubrf, false)
		check("samma antal kom tillbaka", tillbaka == gomda, tillbaka .. " av " .. gomda)

		local kvarGomda = 0
		for _, i in ipairs(ubrf:GetDescendants()) do
			if i:GetAttribute("TakDel") == true and i.Transparency >= 1 then
				kvarGomda += 1
			end
		end
		check("ingen takdel blev kvar genomskinlig", kvarGomda == 0, kvarGomda .. " st")
	end
end

print("\n── Vymodulen: ritbara zoner får kameror, olösta får inte ──")
do
	local modul = Granskning.vyModul(BuildKit, UBRFKomplex, Planrum, Planoppning)
	local ritbara, olosta = 0, 0
	for _, z in ipairs(zoner) do
		if z.rekt then ritbara += 1 else olosta += 1 end
	end
	local mattaOpp, olostaOpp = 0, 0
	for _, o in ipairs(Planoppning.lista) do
		if o.nandel then mattaOpp += 1 else olostaOpp += 1 end
	end
	--[[ Ritbar zon: uppifrån + ögonhöjd. Olöst zon: EN vy, och den är
	     våningsöversikten — ingen egen kamera mot en påhittad rektangel.
	     Öppningar: en vy var. Plus tre våningsöversikter. ]]
	local vantat = ritbara * 2 + olosta + mattaOpp + olostaOpp + 3
	check("kameror bara där källan bär geometri", #modul.vyer == vantat,
		#modul.vyer .. " vyer: " .. ritbara .. " ritbara, " .. olosta
		.. " olösta, " .. (mattaOpp + olostaOpp) .. " öppningar")

	check("panelen får tredje utfallet i F02", modul.gapKnapp == true)

	--[[ DET HÄR ÄR REGRESSIONEN SOM SKA FÅNGAS. Förut fick varje zon utan
	     mått två kameror riktade mot en godtycklig 10-metersremsa vid
	     gaveln, så bilden pekade ut ett läge källan inte bär. Nu ska varje
	     olöst zon ha exakt en vy, märkt ejBedombar, och den vyns kamera
	     ska vara IDENTISK med våningsöversiktens. ]]
	local oversikt = {}
	for _, v in ipairs(modul.vyer) do
		if string.sub(v.id, 1, 9) == "oversikt_" then oversikt[v.id] = v end
	end
	local utanRektUtanFlagga, egenKamera, gapVyer = 0, 0, 0
	for _, z in ipairs(zoner) do
		if not z.rekt then
			local hittad
			for _, v in ipairs(modul.vyer) do
				if v.id == z.id .. "_kallgap" then hittad = v end
				if v.id == z.id .. "_uppifran" or v.id == z.id .. "_ogonhojd" then
					egenKamera += 1
				end
			end
			if hittad then
				gapVyer += 1
				if not hittad.ejBedombar then utanRektUtanFlagga += 1 end
				local ov = if z.hus == "stall"
					then (if (z.niva or 1) >= 2 then "oversikt_stall_plan2" else "oversikt_stall_plan1")
					else "oversikt_ridhus_entre"
				local o = oversikt[ov]
				if o and (hittad.fran.x ~= o.fran.x or hittad.fran.y ~= o.fran.y
					or hittad.fran.h ~= o.fran.h) then
					utanRektUtanFlagga += 1
				end
			end
		end
	end
	check("varje olöst zon har en GAP-vy", gapVyer == olosta, gapVyer .. "/" .. olosta)
	check("ingen olöst zon fick egen kamera mot påhittad rektangel", egenKamera == 0,
		egenKamera .. " st")
	check("GAP-vyerna är märkta och pekar på våningsöversikten",
		utanRektUtanFlagga == 0, utanRektUtanFlagga .. " avvikande")

	--[[ Plan 2:s ögonhöjdskamera ska stå PÅ övervåningen, inte på marken
	     och titta upp i undersidan. ]]
	local plan2Lagt = 0
	for _, z in ipairs(zoner) do
		if z.rekt and (z.niva or 1) >= 2 then
			for _, v in ipairs(modul.vyer) do
				if v.id == z.id .. "_ogonhojd" and v.fran.h < 3.0 then
					plan2Lagt += 1
				end
			end
		end
	end
	check("plan 2:s ögonhöjdskamera ligger över övervåningsgolvet",
		plan2Lagt == 0, plan2Lagt .. " för lågt")

	local ok = pcall(modul.ga, "finns_inte")
	check("okänd vy kastas i stället för att tigas bort", ok == false)

	local ok2 = pcall(modul.ga, modul.vyer[1].id)
	check("en riktig vy går att gå till", ok2 == true)

	--[[ Varje vytext ska bära källklassen — det är den Tobias bedömer mot. ]]
	local utanKlass = 0
	for _, v in ipairs(modul.vyer) do
		if not (string.find(v.text, "PLAN", 1, true)
			or string.find(v.text, "FOTO", 1, true)
			or string.find(v.text, "DERIVED", 1, true)
			or string.find(v.text, "GAP", 1, true)) then
			utanKlass += 1
		end
	end
	check("varje vytext bär sin källklass", utanKlass == 0, utanKlass .. " utan")
end

print("\n── Planrummen: nivåer, etiketter och det olösta ──")
do
	local plan2, utanRekt, etiketter = 0, 0, 0
	for _, r in ipairs(Planrum.lista) do
		if r.niva == 2 then plan2 += 1 end
		if not r.rekt then utanRekt += 1 end
	end
	check("övervåningen har rum", plan2 >= 5, plan2 .. " st")
	check("perspektivolösta rum finns som poster, inte som gissade rektanglar",
		utanRekt >= 5, utanRekt .. " utan rekt")

	--[[ Inga påhittade funktioner: neutrala id:n, aldrig wc/kontor/omkl. ]]
	local semantiska = 0
	for _, r in ipairs(Planrum.lista) do
		if string.find(r.id, "wc") or string.find(r.id, "kontor")
			or string.find(r.id, "omkl") or string.find(r.id, "cafe_rum") then
			semantiska += 1
			print("       semantiskt id: " .. r.id)
		end
	end
	check("inga påhittade funktionsnamn i id:na", semantiska == 0, semantiska .. " st")

	local mapp = workspace:FindFirstChild("Anläggning")
	local ubrf = mapp and mapp:FindFirstChild("UBRF")
	if ubrf then
		local hoga, medEtikett = 0, 0
		for _, i in ipairs(ubrf:GetDescendants()) do
			if i:GetAttribute("Niva") == 2 then hoga += 1 end
			if i.Name == "F02Etikett" then etiketter += 1 end
			if i:GetAttribute("RoomId") and i:FindFirstChild("F02Etikett") then
				medEtikett += 1
			end
		end
		check("plan 2-plattorna ligger på övervåningsnivå", hoga == plan2 - 1,
			hoga .. " (en plan 2-post saknar rekt)")
		check("varje platta bär en läsbar RoomId-etikett", medEtikett > 0 and etiketter >= medEtikett,
			medEtikett .. " plattor, " .. etiketter .. " etiketter")
	end
end

print("\n── Normaliserat är källan, meter är ett antagande ──")
do
	--[[ PLAN1-OMMATNING säger att planerna saknar skalstock och att stallets
		bredd är olöst 15–23 m. Meterrektanglar räknade på 21 m får därför
		inte klassas som PLAN — då blir ett arbetsvärde kanon bakvägen. ]]
	local utanN = 0
	for _, r in ipairs(Planrum.lista) do
		if r.rekt ~= nil then utanN += 1 end
	end
	check("inga meterrektanglar ligger kvar i källdatan", utanN == 0, utanN .. " st")

	local n01 = 0
	for _, r in ipairs(Planrum.lista) do
		if r.nrekt then
			local b = r.nrekt
			if b.x >= -0.001 and b.y >= -0.001
				and b.x + b.w <= 1.001 and b.y + b.h <= 1.001 then
				n01 += 1
			else
				print("       utanför 0–1: " .. r.id)
			end
		end
	end
	check("varje normaliserad rekt ligger inom 0–1", n01 == 20, n01 .. " av 20")

	for _, hus in ipairs({ "stall", "ridhus" }) do
		check(hus .. "s skala är märkt ASSUMED_SCALE",
			Planrum.SKALA[hus].klass == "ASSUMED_SCALE", Planrum.SKALA[hus].klass)
	end

	--[[ meter() ska bära klassen vidare, inte tappa den. ]]
	local forsta
	for _, r in ipairs(Planrum.lista) do
		if r.nrekt and not forsta then forsta = r end
	end
	local m, klass = Planrum.meter(forsta)
	check("meter() ger en rektangel", m ~= nil)
	check("och märker den ASSUMED_SCALE", klass == "ASSUMED_SCALE", tostring(klass))
	local utanRekt
	for _, r in ipairs(Planrum.lista) do
		if not r.nrekt and not utanRekt then utanRekt = r end
	end
	local m2, klass2 = Planrum.meter(utanRekt)
	check("ett rum utan planmått ger nil och GAP", m2 == nil and klass2 == "GAP",
		tostring(m2) .. "/" .. tostring(klass2))

	--[[ Skalklassen ska synas i QA-texten. Tystnar den där är hela poängen
		borta: den som granskar tror att metertalen är mätta. ]]
	local modul = Granskning.vyModul(BuildKit, UBRFKomplex, Planrum)
	local medSkalklass = 0
	for _, v in ipairs(modul.vyer) do
		if string.find(v.text, "ASSUMED_SCALE", 1, true) then medSkalklass += 1 end
	end
	check("planrummens vytexter bär ASSUMED_SCALE", medSkalklass >= 40,
		medSkalklass .. " vyer")
end

print("\n── Granskningsväggarna: annotering, aldrig spelgeometri ──")
do
	local mapp = workspace:FindFirstChild("Anläggning")
	local ubrf = mapp and mapp:FindFirstChild("UBRF")
	if ubrf then
		local vaggar, trappor, zongranser, oppningar = Granskning.byggVaggar(
			BuildKit, UBRFKomplex, Planrum, ubrf, ubrf.PrimaryPart.CFrame, Planoppning)

		--[[ SKILJEVÄGGAR BARA UR PLANRUM. Förut ritades fyra sidor runt VARJE
		     ritbar zon, aggregaten inräknade — boxhallen, banan, läktarbandet.
		     Talet såg då ut som fyra gånger antalet zoner och lästes som
		     "belagda väggsegment". Nu byggs de bara ur enskilda rumsgränser
		     ur planen, och delade gränser räknas EN gång. ]]
		local planrumMedRekt, aggregatMedRekt = 0, 0
		for _, z in ipairs(zoner) do
			if z.rekt then
				if z.ursprung == "planrum" then planrumMedRekt += 1
				else aggregatMedRekt += 1 end
			end
		end
		check("skiljeväggar byggs bara ur planrum, inte ur aggregat",
			vaggar <= planrumMedRekt * 4,
			vaggar .. " segment ur " .. planrumMedRekt .. " planrum")
		check("delade gränser räknas en gång", vaggar < planrumMedRekt * 4,
			vaggar .. " < " .. (planrumMedRekt * 4) .. " odeduplicerat")
		check("aggregaten får zongräns, aldrig vägg", zongranser == aggregatMedRekt,
			zongranser .. " för " .. aggregatMedRekt .. " aggregat")
		check("trapporna fick egen markering", trappor >= 3, trappor .. " st")

		--[[ ÖPPNINGARNA. Acceptance Contract säger dörrlägen; en öppning som
		     försvinner eller dubbleras ska fälla provet, inte tystna.

		     FÖRVÄNTAN SKRIVS UT HÄR, inte hämtas ur modulen. Ett prov som
		     räknar modulens egen lista mot sig själv följer med när listan
		     krymper och säger OK medan en dörr just försvann — det upptäcktes
		     genom att faktiskt ta bort en och se provet förbli grönt. ]]
		local VANTADE_OPPNINGAR = {
			s_opp_ost_service = "PLAN",
			s_opp_vast_mitt = "PLAN",
			s_opp_vast_klubb = "GAP",
			s_opp_norr_gavel = "GAP",
		}
		local vantadeMatta = 0
		for _, k in pairs(VANTADE_OPPNINGAR) do
			if k == "PLAN" then vantadeMatta += 1 end
		end
		local finns, felKlass = {}, 0
		for _, o in ipairs(Planoppning.lista) do
			finns[o.id] = o
			local v = VANTADE_OPPNINGAR[o.id]
			if not v then
				felKlass += 1
			elseif (v == "PLAN") ~= (o.nandel ~= nil) or o.klass ~= v then
				felKlass += 1
			end
		end
		local borta = 0
		for id in pairs(VANTADE_OPPNINGAR) do
			if not finns[id] then borta += 1 end
		end
		check("alla kända öppningar finns kvar i datan", borta == 0, borta .. " borta")
		check("ingen öppning bytte klass eller tillkom utan prov", felKlass == 0,
			felKlass .. " avvikande")

		local matta = vantadeMatta
		check("varje mätt öppning är byggd", oppningar == matta,
			oppningar .. " av " .. matta)
		local vmapp0 = ubrf:FindFirstChild("F02ReviewGeometry")
		local sedda = {}
		local dubbletter = 0
		if vmapp0 then
			for _, i in ipairs(vmapp0:GetDescendants()) do
				local oid = i:GetAttribute("OpeningId")
				if oid then
					if sedda[oid] then dubbletter += 1 end
					sedda[oid] = true
				end
			end
		end
		check("ingen öppning dubblerades", dubbletter == 0, dubbletter .. " st")
		local saknade = 0
		for id, k in pairs(VANTADE_OPPNINGAR) do
			if k == "PLAN" and not sedda[id] then saknade += 1 end
		end
		check("ingen mätt öppning försvann ur bygget", saknade == 0, saknade .. " st")

		--[[ Sorterna ska gå att skilja åt. Ett aggregat som ser ut som en
		     vägg är precis det granskningen inte får påstå. ]]
		local sorter = {}
		if vmapp0 then
			for _, i in ipairs(vmapp0:GetDescendants()) do
				local s2 = i:GetAttribute("F02Sort")
				if s2 then sorter[s2] = (sorter[s2] or 0) + 1 end
			end
		end
		check("fyra skilda sorter i spöklagret",
			sorter.SKILJEVAGG and sorter.ZONGRANS and sorter.TRAPPA and sorter.OPPNING,
			string.format("%s skiljevägg, %s zongräns, %s trappa, %s öppning",
				tostring(sorter.SKILJEVAGG), tostring(sorter.ZONGRANS),
				tostring(sorter.TRAPPA), tostring(sorter.OPPNING)))

		--[[ Det farliga vore att de här smyger in i spelet. Ingen av dem får
			kollidera, och alla ska bära F02Review. ]]
		local kolliderar, utanFlagga = 0, 0
		local vmapp = ubrf:FindFirstChild("F02ReviewGeometry")
		check("de ligger i en egen mapp", vmapp ~= nil)
		if vmapp then
			for _, i in ipairs(vmapp:GetDescendants()) do
				if i.CanCollide == true then kolliderar += 1 end
				if i:GetAttribute("F02Review") ~= true then utanFlagga += 1 end
			end
		end
		check("ingen granskningsvägg kolliderar", kolliderar == 0, kolliderar .. " st")
		check("alla bär F02Review", utanFlagga == 0, utanFlagga .. " utan")

		local vaggar2 = Granskning.byggVaggar(
			BuildKit, UBRFKomplex, Planrum, ubrf, ubrf.PrimaryPart.CFrame, Planoppning)
		check("andra passet dubblar inte väggarna", vaggar2 == vaggar,
			vaggar .. " → " .. vaggar2)

		local av = Granskning.visaVaggar(ubrf, false)
		check("de går att gömma", av > 0, av .. " delar")
		Granskning.visaVaggar(ubrf, true)
	end
end

print("\n── Panelens tredje utfall: GAP är aldrig PASS ──")
do
	local vyer = {
		{ id = "a" }, { id = "b" }, { id = "c", ejBedombar = true },
		{ id = "d", ejBedombar = true },
	}
	local r = QAPanel.rakna(vyer, { a = "PASS", b = "FEL", c = "GAP" })
	check("PASS, FEL, GAP och kvar räknas var för sig",
		r.pass == 1 and r.fel == 1 and r.gap == 1 and r.kvar == 1,
		string.format("%d/%d/%d/%d", r.pass, r.fel, r.gap, r.kvar))
	--[[ GAP får ALDRIG ligga i nämnaren: en källucka ska inte kunna se ut
	     som en delseger i "N av M godkända". ]]
	check("GAP ligger utanför nämnaren", r.bedombara == #vyer - r.gap,
		r.bedombara .. " bedömbara av " .. #vyer)
	check("en GAP-markering räknas inte som PASS", r.pass == 1)
	check("en ej bedömbar vy kan inte PASS:as",
		QAPanel.farBedomas(vyer[3], "PASS") == false)
	check("en ej bedömbar vy kan markeras GAP",
		QAPanel.farBedomas(vyer[3], "GAP") == true)
	check("en vanlig vy kan fortfarande PASS:as",
		QAPanel.farBedomas(vyer[1], "PASS") == true)
end

if fails > 0 then
	print(string.format("\n%d FEL", fails))
	error("granskning.spec: " .. fails .. " fel")
end
print("\ngranskningen: alla gröna")
