--!nostrict
--[[ ETT TEMA PER PASS — QA-review av `082062c`, blockerare 2

	Förut valde `Lektion.liveCue` den svagaste dimensionen i VARJE
	bildruta. Ugneta hoppade därför mellan «Mjukare hand», «Sitt stilla»
	och «Titta dit du ska» under samma volt, och en ryttare som får tre
	saker att tänka på hinner inte med någon.

	Fem grindar mäts här, var och en för sig och var och en falsifierbar:

	  1. ETT TEMA — valt en gång, och det ändras inte för att något
	     annat blir sämre senare.
	  2. TEMAFILTRET — hon säger ingenting om det som inte är dagens sak.
	  3. MÖNSTER FÖRE KOMMENTAR — ett enda dåligt ögonblick är brus.
	  4. SPÄRR UTAN KÖ — det som hann rättas under spärren sägs inte
	     när spärren släpper.
	  5. HÄSTENS DAG ELLER RYTTARENS FEL — och tystnad när det inte
	     går att avgöra.

	Kör: python3 roblox/tests/build.py tests/ugnetatema.spec.luau
	     && luau roblox/tests/.build/ugnetatema.spec.luau ]]

local fel = 0
local function prova(vad, ok, detalj)
	if ok then
		print(("  OK   %s%s"):format(vad, if detalj then "  " .. detalj else ""))
	else
		fel += 1
		print(("  FEL  %s%s"):format(vad, if detalj then "  " .. detalj else ""))
	end
end

local T = UgnetaTema
local UG = RidKanon.UGNETA
local DIMS = Ugneta.dimensionerFor("storvolt")   -- linje, rytm, balans
local DT = 1 / 30

--[[ Övningen väljs med flit ur kanon och inte som en påhittad lista:
     ändrar webben vad en 20 m volt bedöms på ska det här provet följa
     med, inte fortsätta mäta en dimension som inte längre finns. ]]
print(("-- dimensioner ur kanon: %s --"):format(table.concat(DIMS, ", ")))

--[[ Stega `sek` sekunder med en fast mätning. Returnerar allt hon sa. ]]
local function kor(tema, sek, kvalitet, hast, spanning)
	local sagt = {}
	local t = 0
	while t < sek do
		local txt, bra, kalla = T.steg(tema, DT, kvalitet, hast, spanning, DIMS)
		if txt ~= "" then
			table.insert(sagt, { txt = txt, bra = bra, kalla = kalla })
		end
		t += DT
	end
	return sagt
end

local function texter(sagt)
	local ut = {}
	for _, s in ipairs(sagt) do table.insert(ut, s.txt) end
	return table.concat(ut, " | ")
end

--[[ En volt där LINJEN är svag och allt annat bra. Temat ska bli linje. ]]
local function svagLinje() return { linje = 0.20, rytm = 0.95, balans = 0.95 } end
--[[ …och sedan tvärtom: linjen räddad, rytmen kollapsad. ]]
local function svagRytm()  return { linje = 0.95, rytm = 0.10, balans = 0.95 } end
local function alltBra()   return { linje = 0.95, rytm = 0.95, balans = 0.95 } end

--[[ ══ 1. ETT TEMA, VALT EN GÅNG ══════════════════════════════════ ]]
do
	print("")
	print("-- 1. Ett tema, och det står kvar --")

	local tema = T.nytt("storvolt")
	prova("temat är OVALT innan hon sett något", tema.dim == nil)

	--[[ Halva valfönstret räcker inte. Att välja tidigare hade gjort
	     temat till ett ögonblicksvärde igen. ]]
	kor(tema, T.VAL_SEK * 0.5, svagLinje())
	prova("och fortfarande ovalt halvvägs genom valfönstret",
		tema.dim == nil, ("valtid=%.2f"):format(tema.valtid))

	kor(tema, T.VAL_SEK, svagLinje())
	prova("efter valfönstret är dagens tema den svagaste dimensionen",
		tema.dim == "linje", tostring(tema.dim))

	--[[ DET AVGÖRANDE: nu blir rytmen mycket sämre än linjen någonsin
	     var. Ett tema som valdes om varje bildruta hade bytt här. ]]
	kor(tema, 30, svagRytm())
	prova("temat BYTER INTE när något annat blir sämre",
		tema.dim == "linje", tostring(tema.dim))
end

--[[ ══ 2. TEMAFILTRET ══════════════════════════════════════════════ ]]
do
	print("")
	print("-- 2. Hon säger ingenting om det som inte är dagens sak --")

	local tema = T.nytt("storvolt")
	kor(tema, T.VAL_SEK, svagLinje())
	prova("temat är linje", tema.dim == "linje", tostring(tema.dim))

	--[[ Linjen perfekt, rytmen usel, länge. ]]
	local sagt = kor(tema, 60, svagRytm())

	--[[ Halva kontraktet: hon anvander inte rytmens ORD. ]]
	local omRytm = false
	for _, s in ipairs(sagt) do
		if s.txt == UG.LIVE.framat.fel or s.txt == UG.LIVE.framat.bra then
			omRytm = true
		end
	end
	prova("EN SVAG RYTM UTANFÖR TEMAT GER INGET ORD OM RYTMEN",
		omRytm == false, texter(sagt))

	--[[ ANDRA HALVAN, och den som falsifieringen visade saknades.

	     Tar man bort temafiltret men later CUEN sta kvar sager hon
	     fortfarande temats ord — «Titta dit du ska» — fast det ar RYTMEN
	     som ar svag. Provet ovan sag ingen skillnad: orden var ratt,
	     signalen fel. En tillsagelse om linjen medan linjen ar 0,95 ar
	     precis det felet. ]]
	local felOmLinjen = false
	for _, s in ipairs(sagt) do
		if s.txt == UG.LIVE.vagen.fel then felOmLinjen = true end
	end
	prova("OCH INGEN TILLSÄGELSE ALLS MEDAN TEMATS EGEN DIMENSION ÄR BRA",
		felOmLinjen == false, texter(sagt))
end

--[[ ══ 3. MÖNSTER FÖRE KOMMENTAR ═══════════════════════════════════ ]]
do
	print("")
	print("-- 3. Ett enda dåligt ögonblick är brus --")

	local tema = T.nytt("storvolt")
	kor(tema, T.VAL_SEK, svagLinje())

	--[[ Nollställ mönstret med en stund bra ridning, och släpp spärren. ]]
	kor(tema, 20, alltBra())
	tema.cd, tema.sagt = 0, ""

	--[[ EN enda dålig bildruta. En häst tappar balansen i ett hörn utan
	     att ryttaren gjort något — det ska inte ge en tillsägelse. ]]
	local en = kor(tema, DT, { linje = 0.10, rytm = 0.95, balans = 0.95 })
	prova("EN ENDA DÅLIG BILDRUTA GER INGEN TILLSÄGELSE",
		#en == 0, texter(en))

	--[[ Men ett ihållande fel gör det. Knappt under tröskeln räcker
	     inte; knappt över den räcker. ]]
	local strax = kor(tema, T.SVAG_SEK * 0.6, svagLinje())
	prova("och inte heller strax innan mönstret är uppfyllt",
		#strax == 0, ("%.2f s: %s"):format(tema.svagSedan, texter(strax)))

	local nog = kor(tema, T.SVAG_SEK, svagLinje())
	prova("ETT IHÅLLANDE FEL GER DEN",
		#nog > 0 and nog[1].txt == UG.LIVE.vagen.fel,
		texter(nog))
	prova("och den är ryttarens, inte hästens",
		#nog > 0 and nog[1].kalla == "tema",
		if #nog > 0 then nog[1].kalla else "(tyst)")
end

--[[ ══ 4. SPÄRR UTAN KÖ ════════════════════════════════════════════

	VARJE SCENARIO FÅR ETT EGET TEMA. Första versionen körde dem efter
	varandra på samma, och då hade det föregående blocket redan ätit upp
	spärren — mätningen «spärren håller» gjordes på en spärr som
	för länge sedan släppt, och blev röd utan att något var fel. ]]

--[[ Rid tills hon säger till om linjen. Returnerar temat med spärren
     nyss satt, så att varje scenario börjar på samma ställe. ]]
local function temaMedFarskSparr()
	local tema = T.nytt("storvolt")
	kor(tema, T.VAL_SEK, svagLinje())
	local sagt = kor(tema, T.SVAG_SEK + 1, svagLinje())
	return tema, sagt
end

do
	print("")
	print("-- 4. Spärren tystar, och släpper utan kö --")

	do
		local tema, forsta = temaMedFarskSparr()
		prova("hon sa till om linjen", #forsta > 0, texter(forsta))
		prova("och spärren ligger på", tema.cd > 0, ("cd=%.1f"):format(tema.cd))
	end

	--[[ SPÄRRENS EGEN SAK. Att bara mäta «hon upprepar sig inte medan
	     felet står kvar» räckte inte: dubblettskyddet `sagt` stoppar
	     samma ord ändå, så en falsifiering som tog bort spärren HELT gav
	     ingen röd rad. Provet mätte dubblettskyddet och trodde att det
	     mätte spärren.

	     De två skiljer sig först när beskedet BYTER. Sex sekunders bra
	     ridning uppfyller `BEROM_SEK`, så utan spärr kommer berömmet vid
	     6,0 s. Med spärr får det inte komma förrän vid `LIVE_CD.fel`
	     (8 s). Det fönstret mäts här. ]]
	do
		local tema = temaMedFarskSparr()
		local mellan = kor(tema, T.BEROM_SEK + 0.5, alltBra())
		prova("SPÄRREN HÅLLER ÄVEN ETT BERÖM SOM ANNARS VORE MOGET",
			#mellan == 0,
			("%.1f s in, %d ord: %s  cd=%.1f"):format(T.BEROM_SEK + 0.5,
				#mellan, texter(mellan), tema.cd))
	end

	--[[ OCH INGEN KÖ. Ryttaren rättar sig medan spärren ligger på; när
	     den släpper får hon inte höra tillsägelsen ändå. Det vore ett
	     besked om ett fel hon redan löst. ]]
	do
		local tema = temaMedFarskSparr()
		local efter = kor(tema, UG.LIVE_CD.fel + 1, alltBra())
		local omLinjeFel = false
		for _, x in ipairs(efter) do
			if x.txt == UG.LIVE.vagen.fel then omLinjeFel = true end
		end
		prova("INGEN KÖAD TILLSÄGELSE NÄR SPÄRREN SLÄPPER",
			omLinjeFel == false, texter(efter))
		--[[ …och spärren släppte verkligen, annars vore tystnaden gratis.
		     Beviset är att hon sa något NYTT som hör till nuläget. ]]
		prova("hon sa något nytt — spärren släppte alltså",
			#efter > 0, texter(efter))
		prova("och det nya hörde till NULÄGET, inte till det rättade",
			#efter > 0 and efter[1].txt == UG.LIVE.vagen.bra,
			if #efter > 0 then efter[1].txt else "(tyst)")
	end
end

--[[ ══ 5. HÄSTENS DAG ELLER RYTTARENS FEL ══════════════════════════ ]]
do
	print("")
	print("-- 5. Hästens dag skild från ryttarens fel --")

	prova("en skygg häst är hennes egen",
		T.hastensEgen({ skygghet = T.SKYGG_TROSKEL + 0.01 }) == true)
	prova("en dålig dagsform likaså",
		T.hastensEgen({ dagsform = T.DAGSFORM_TROSKEL - 0.01 }) == true)
	prova("en lugn häst i god form är det inte",
		T.hastensEgen({ skygghet = 0.05, dagsform = 0.95 }) == false)
	--[[ DEN VIKTIGASTE RADEN I PROVET. Utan uppgift om hästen svarar
	     regeln «går inte att avgöra» — inte «då var det ryttaren». ]]
	prova("OCH UTAN UPPGIFT OM HENNE GÅR DET INTE ATT AVGÖRA",
		T.hastensEgen(nil) == nil and T.hastensEgen({}) == nil,
		("nil→%s  tom→%s"):format(tostring(T.hastensEgen(nil)),
			tostring(T.hastensEgen({}))))

	--[[ PARTIELL KONTEXT ÄR OCKSÅ OKÄND (re-review av `269bec5`).

	     Första versionen krävde bara att NÅGOT fält fanns. En lugn häst
	     med okänd dagsform frikändes därför — `skygghet = 0.05` svarade
	     `false`, alltså «inte hennes dag», fast dagsformen var det enda
	     som kunde ha sagt det. Ryttaren fick rättelsen på saknad evidens.

	     Regeln är asymmetrisk med flit: ett JA från ett känt fält räcker,
	     ett NEJ kräver att allt är känt. ]]
	prova("ETT LUGNT LYNNE MEN OKÄND DAGSFORM ÄR OKÄNT, INTE FRIKÄNT",
		T.hastensEgen({ skygghet = 0.05 }) == nil,
		tostring(T.hastensEgen({ skygghet = 0.05 })))
	prova("och en god dagsform med okänt lynne likaså",
		T.hastensEgen({ dagsform = 0.95 }) == nil,
		tostring(T.hastensEgen({ dagsform = 0.95 })))
	--[[ Men ett JA behöver inte hela bilden: är hon skygg spelar det
	     ingen roll vad dagsformen säger. ]]
	prova("ett JA räcker även med halva bilden",
		T.hastensEgen({ skygghet = 0.5 }) == true
			and T.hastensEgen({ dagsform = 0.2 }) == true)

	local hogSpanning = T.SPANNING_TROSKEL + 0.1

	--[[ Skygg häst, hög spänning: beskedet tillskrivs HENNE. ]]
	do
		local tema = T.nytt("storvolt")
		kor(tema, T.VAL_SEK, alltBra(), { skygghet = 0.5 }, 0)
		local sagt = kor(tema, 1, alltBra(), { skygghet = 0.5 }, hogSpanning)
		prova("SPÄNNING HOS EN SKYGG HÄST TILLSKRIVS HENNE",
			#sagt > 0 and sagt[1].kalla == "hast",
			if #sagt > 0 then sagt[1].kalla else "(tyst)")
	end

	--[[ Lugn häst, samma spänning: INGET besked om hästen. ]]
	do
		local tema = T.nytt("storvolt")
		local lugn = { skygghet = 0.05, dagsform = 0.95 }
		kor(tema, T.VAL_SEK, alltBra(), lugn, 0)
		local sagt = kor(tema, 1, alltBra(), lugn, hogSpanning)
		local omHast = false
		for _, s in ipairs(sagt) do if s.kalla == "hast" then omHast = true end end
		prova("men inte hos en lugn häst i god form",
			omHast == false, texter(sagt))
	end

	--[[ OKÄND häst, samma spänning: tystnad, inte en gissning åt något
	     håll. ]]
	do
		local tema = T.nytt("storvolt")
		kor(tema, T.VAL_SEK, alltBra(), nil, 0)
		local sagt = kor(tema, 1, alltBra(), nil, hogSpanning)
		local omHast = false
		for _, s in ipairs(sagt) do if s.kalla == "hast" then omHast = true end end
		prova("och en okänd häst ger tystnad, inte en gissning",
			omHast == false, texter(sagt))
	end
end

if fel > 0 then
	print(("\nUGNETATEMA: %d fel"):format(fel))
	error(("%d fel"):format(fel))
end
print("\nUGNETATEMA: alla gröna")
