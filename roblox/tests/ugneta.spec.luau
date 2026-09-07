--!nostrict
--[[
	UGNETAS LÄRAR-UX PÅ ROBLOX (G02-C, UX-variant 1 + 3).

	ChatGPT senior review 2026-09-06 på #119, blocker 1: Roblox är primär
	plattform, och kontraktsparitet räcker inte — spelaren ska få samma
	upplevelse. Den här specen mäter att UgnetaController faktiskt bygger
	den, med samma regler som webben:

	  - live under ridning är NÅGRA ORD, inte ett kort,
	  - kortet visas mellan försöken, med högst två observationer,
	  - efter försök 1 finns "Prova igen",
	  - säkerhet vinner: live-chipet släcks och kortet stängs,
	  - bedömningen kommer ur HorseCore/Ugneta, inte ur egna formler.

	Kör: python3 roblox/tests/build.py tests/ugneta.spec.luau
	     && luau roblox/tests/.build/ugneta.luau
]]

local fails = 0
local function check(namn, ok, detalj)
	if ok then
		print(string.format("  OK   %s%s", namn, if detalj then " " .. detalj else ""))
	else
		fails += 1
		print(string.format("  FEL  %s%s", namn, if detalj then " " .. detalj else ""))
	end
end

print("")
print("UGNETA — LÄRAR-UX PÅ ROBLOX")
print("")

UgnetaController.start()

local gui = game:GetService("Players").LocalPlayer._gui
local function hitta(namn)
	local function sok(nod)
		if type(nod) ~= "table" then return nil end
		if nod.Name == namn then return nod end
		for _, b in ipairs(nod._barn or {}) do
			local t = sok(b)
			if t then return t end
		end
		return nil
	end
	return sok(gui)
end

--[[ ── LIVE-REGISTRET ─────────────────────────────────────────── ]]
do
	local txt = UgnetaController.liveText("hand", false)
	check("live-cuen för handen är några ord", txt == "Mjukare hand",
		string.format('("%s")', txt))
	local bra = UgnetaController.liveText("timing", true)
	check("och beröm är lika kort", bra == "Precis så", string.format('("%s")', bra))

	local ord = 0
	for _, id in { "hand", "framat", "sits", "lugn", "timing", "vagen" } do
		for _, b in { true, false } do
			local t = UgnetaController.liveText(id, b)
			local n = 0
			for _ in string.gmatch(t, "%S+") do n += 1 end
			if n > ord then ord = n end
		end
	end
	--[[ Taket är fyra ord, inte tre: webbens egen längsta cue är
	     "Titta dit du ska". Regeln är "några ord, inte en mening" —
	     att korta ned den hade ändrat webbens pedagogik utan att någon
	     bett om det. ]]
	check("ingen live-cue är längre än fyra ord", ord <= 4,
		string.format("(längsta %d ord)", ord))

	UgnetaController.live("Mjukare hand", false)
	local chip = hitta("Live")
	check("live-chipet syns och bär texten",
		chip ~= nil and chip.Visible == true and chip.Text == "Mjukare hand",
		string.format('(Visible %s, "%s")', tostring(chip and chip.Visible),
			tostring(chip and chip.Text)))

	local kort = hitta("Kort")
	check("och kortet är INTE uppe under live-feedback",
		kort ~= nil and kort.Visible == false,
		string.format("(kortets Visible %s)", tostring(kort and kort.Visible)))

	UgnetaController.steg(3.0)
	check("live-chipet tonar ut av sig självt",
		chip.Visible == false, string.format("(Visible %s)", tostring(chip.Visible)))
end

--[[ ── MELLAN FÖRSÖKEN ────────────────────────────────────────── ]]
do
	local nu = { linje = 0.78, rytm = 0.60, balans = 0.41,
		timing = 0.5, mjukhet = 0.5, respons = 0.5, tempo = 0.5 }
	local punkter = UgnetaController.efterForsok("storvolt", nu, nil, 1)
	local kort = hitta("Kort")
	local rubrik = hitta("Rubrik")
	local knapp = hitta("Knapp")
	check("efter försök 1 visas kortet", kort ~= nil and kort.Visible == true,
		string.format("(Visible %s)", tostring(kort and kort.Visible)))
	check("med en sak som var bra och en att förbättra",
		#punkter == 2 and string.find(punkter[1], "Bra") ~= nil
		and string.find(punkter[2], "Jobba på") ~= nil,
		string.format('("%s" / "%s")', punkter[1] or "-", punkter[2] or "-"))
	check("rubriken och knappen säger Prova igen",
		rubrik ~= nil and rubrik.Text == "Prova igen"
		and knapp ~= nil and knapp.Visible == true,
		string.format('(rubrik "%s", knapp %s)', tostring(rubrik and rubrik.Text),
			tostring(knapp and knapp.Visible)))

	local fore = { linje = 0.40, rytm = 0.50, balans = 0.60 }
	local nu2 = { linje = 0.62, rytm = 0.52, balans = 0.45 }
	local p2 = UgnetaController.efterForsok("storvolt", nu2, fore, 2)
	check("efter försök 2 jämförs det mot försök 1",
		#p2 <= 2 and string.find(p2[1], "Bättre") ~= nil
		and string.find(p2[1], "linjen") ~= nil,
		string.format('("%s")', p2[1] or "-"))
	check("och aldrig fler än kontraktets tak",
		#p2 <= Ugneta.MAX_OBSERVATIONER,
		string.format("(%d av högst %d)", #p2, Ugneta.MAX_OBSERVATIONER))

	--[[ Efter sista försöket erbjuds INGET tredje försök. Kravet stod
	     förut som "knappen är osynlig", vilket stämde när lifecyclen gick
	     vidare på en timer. Sedan senior review av c53a2c7 väntar
	     lektionen på spelaren, så kortet MÅSTE ha en väg framåt — annars
	     stod hon fast. Avsikten är oförändrad och prövas nu direkt: det
	     som erbjuds är nästa övning, aldrig ett tredje försök. ]]
	local knapp2 = hitta("Knapp")
	check("men Prova igen erbjuds inte efter sista försöket",
		knapp2 ~= nil and knapp2.Visible == true
			and knapp2.Text == "Nästa övning",
		string.format('("%s")', knapp2 and knapp2.Text or "-"))
end

--[[ ── SÄKERHET VINNER ────────────────────────────────────────── ]]
do
	UgnetaController.live("Bra rytm", true)
	local chip = hitta("Live")
	local fore = chip.Visible
	UgnetaController.sakerhetTarOver()
	local kort = hitta("Kort")
	check("ett säkerhetsmeddelande släcker live-chipet",
		fore == true and chip.Visible == false,
		string.format("(före %s → efter %s)", tostring(fore), tostring(chip.Visible)))
	check("och stänger lärarkortet",
		kort ~= nil and kort.Visible == false,
		string.format("(Visible %s)", tostring(kort and kort.Visible)))
end

--[[ ── INGEN PARALLELL SANNING ────────────────────────────────── ]]
do
	--[[ Kontraktet ska STYRA texten. Byts dimensionerna för en övning
	     ska Ugnetas ord följa med — annars har controllern en egen
	     uppfattning vid sidan av kanonen. ]]
	local nu = { linje = 0.20, rytm = 0.90, balans = 0.30,
		timing = 0.90, mjukhet = 0.20, respons = 0.30 }
	local volt = UgnetaController.efterForsok("storvolt", nu, nil, 1)
	local overgang = UgnetaController.efterForsok("halt_skritt", nu, nil, 1)
	check("volten berömmer rytmen, övergången berömmer timingen",
		string.find(volt[1] or "", "rytmen") ~= nil
		and string.find(overgang[1] or "", "timingen") ~= nil,
		string.format('(volt "%s" · övergång "%s")', volt[1] or "-", overgang[1] or "-"))
end

--[[ ══ PRODUKTIONSKEDJAN ═══════════════════════════════════════════
	Blocker 1 i senior review av 09e07da: HUD:en gick att anropa men var
	inte inkopplad i någon lektionslifecycle. Ett prov som anropar
	`efterForsok` direkt bevisar bara att funktionen finns — precis som
	läktarprovet som mätte hjälpfunktionen i stället för spelarens väg.

	Här körs i stället LektionController, den modul init.client.luau
	stegar i sin RenderStepped-loop, med telemetri av samma form som
	HorseCore/Telemetri.las lämnar. En hel ritt: presentation → live →
	försök 1-kort → försök 2 → jämförelse. ]]
do
	local function tele(over)
		local t = {
			uppsutten = true, gangart = "trav", fart = 3.0, onskadFart = 3.0,
			svangradie = 10, balans = 0.80, mjukhet = 0.75, fokus = 0.80,
			spanning = 0.20, svarstid = 0.12, etableringstid = 0.8,
			paradKvalitet = 0.70,
		}
		for k, v in over or {} do t[k] = v end
		return t
	end
	--[[ Kör loopen som klienten gör: fast bildrutetid, telemetrin in.
	     Chipet SAMPLAS varje bildruta i stället för att läsas av på slutet.
	     Skälet är produktens eget tempo: cuen har en spärr på 8–14 s och
	     står kvar i 2,6 s, så en avläsning efter en godtycklig sekund
	     mäter var i spärren man råkade hamna — inte om hon sa något. ]]
	local sedda
	local function rid(sek, over)
		local dt = 1 / 30
		sedda = {}
		for _ = 1, math.floor(sek / dt) do
			LektionController.steg(dt, tele(over))
			local c = hitta("Live")
			if c and c.Visible and c.Text ~= "" then sedda[c.Text] = true end
		end
	end

	LektionController.start(nil)          -- ingen byggd bana i den här bänken
	check("lektionen startar och pågår", LektionController.pagar() == true,
		string.format("(pågår %s)", tostring(LektionController.pagar())))

	--[[ FÖRSTA STEGET presenterar övningen ur kanonens ordning. ]]
	LektionController.steg(1 / 30, tele())
	local rubrik = hitta("Rubrik")
	local forstaOvning = Lektion.OVNINGAR[Lektion.ORDNING[1]]
	check("första övningen presenteras med kanonens rubrik",
		rubrik ~= nil and rubrik.Text == forstaOvning.rubrik,
		string.format('("%s")', rubrik and rubrik.Text or "-"))

	--[[ …och kortet försvinner när hon börjar rida. Ett kort som ligger
	     kvar mitt i ritten ÄR variant 2, den som inte valdes. ]]
	--[[ Kortet väntar nu på spelaren i stället för på en timer (senior
	     review av c53a2c7). Det är hon som startar försöket, och först
	     därefter är kortet borta. ]]
	check("presentationen väntar på spelaren", LektionController.vantar() == true,
		string.format("(väntar %s)", tostring(LektionController.vantar())))
	LektionController.fortsatt()
	rid(1)
	local kort = hitta("Kort")
	check("kortet är borta när ritten börjat", kort ~= nil and kort.Visible == false,
		string.format("(Visible %s)", tostring(kort and kort.Visible)))

	--[[ LIVE: några ord, valda ur mätningen. Här rids medvetet med hård
	     hand — mjukheten är den svagaste MÄTTA dimensionen — och då ska
	     cuen handla om handen och ingenting annat. ]]
	rid(16, { mjukhet = 0.10, balans = 0.95, fokus = 0.95, spanning = 0.02 })
	local antal = 0
	local vilka = {}
	for txt in sedda do antal += 1; table.insert(vilka, txt) end
	check("live-chipet kommer av sig självt under ritten", antal > 0,
		string.format('("%s")', table.concat(vilka, '", "')))
	check("och cuen följer den svagaste MÄTTA dimensionen",
		sedda["Mjukare hand"] == true,
		string.format('("%s")', table.concat(vilka, '", "')))
	--[[ …och den blir inte en textström: på 16 sekunders ridning hinner
	     hon säga några ord, inte en rad per sekund. ]]
	check("hon säger några ord, inte en ström", antal <= 2,
		string.format("(%d olika på 16 s)", antal))

	--[[ FÖRSÖK 1 → KORT. Rid klart RESTEN av försöket — inte en godtycklig
	     stund till. Rider man för länge hinner pausen löpa ut och försök 2
	     starta, och då mäter provet nästa försök i tron att det mäter
	     kortet. Tiden läses ur lifecyclen själv. ]]
	rid(Lektion.FORSOK_SEK - LektionController.pass().tid + 0.2,
		{ mjukhet = 0.30, balans = 0.55 })
	local knapp = hitta("Knapp")
	kort = hitta("Kort")
	check("efter försök 1 kommer kortet av sig självt",
		kort ~= nil and kort.Visible == true,
		string.format("(Visible %s)", tostring(kort and kort.Visible)))
	check("med Prova igen, alltså samma övning en gång till",
		knapp ~= nil and knapp.Visible == true,
		string.format("(knapp %s)", tostring(knapp and knapp.Visible)))
	local pass = LektionController.pass()
	--[[ …men lifecyclen står KVAR på försök 1. Förut bytte den här av sig
	     själv, och kortet var bara en nedräkning. ]]
	check("och lifecyclen står kvar på försök 1 tills spelaren väljer",
		pass ~= nil and pass.forsokNr == 1 and pass.ix == 1,
		string.format("(övning %d, försök %d)", pass and pass.ix or -1,
			pass and pass.forsokNr or -1))

	--[[ MÄTNINGEN NOLLSTÄLLS — vid spelarens handling, inte när en timer
	     råkar löpa ut. Försök 2 ska inte ärva försök 1:s ackumulator. ]]
	LektionController.fortsatt()
	pass = LektionController.pass()
	check("spelarens val startar försök 2 från noll mätningar",
		pass ~= nil and pass.forsokNr == 2 and pass.ix == 1 and pass.prov.n == 0,
		string.format("(övning %d, försök %d, n %d)", pass and pass.ix or -1,
			pass and pass.forsokNr or -1, pass and pass.prov.n or -1))

	--[[ FÖRSÖK 2, tydligt bättre. Jämförelsen ska nämna förbättringen. ]]
	rid(Lektion.FORSOK_SEK + 0.5,
		{ mjukhet = 0.92, balans = 0.90, svarstid = 0.05, etableringstid = 0.4 })
	local punkt = hitta("Punkt1")
	check("efter försök 2 jämförs det mot försök 1",
		punkt ~= nil and string.find(punkt.Text or "", "Bättre") ~= nil,
		string.format('("%s")', punkt and punkt.Text or "-"))
	LektionController.fortsatt()
	pass = LektionController.pass()
	check("och lektionen går vidare till nästa övning",
		pass ~= nil and pass.ix == 2 and pass.forsokNr == 1,
		string.format("(övning %d, försök %d)", pass and pass.ix or -1,
			pass and pass.forsokNr or -1))

	--[[ SÄKERHET AVBRYTER — genom produktionsvägen. `avbryt` är det
	     init.client.luau anropar i `dismount`, alltså också när karaktären
	     försvinner eller riggen är borta ur workspace. ]]
	--[[ Kör tills chipet FAKTISKT står uppe. Att stega en godtycklig
	     sekund och hoppas att man hamnar i cuens 2,6-sekundersfönster är
	     att mäta turen; här avbryts lektionen i det ögonblick hon säger
	     något, vilket är precis det fall regeln handlar om. ]]
	--[[ Nästa övning presenteras först, och presentationen väntar på
	     spelaren. Utan den här starten skulle loopen nedan snurra mot ett
	     kort som aldrig går vidare — och chipet aldrig komma. ]]
	LektionController.steg(1 / 30, tele())
	LektionController.fortsatt()
	do
		local dt, kvar = 1 / 30, 40
		while kvar > 0 and not hitta("Live").Visible do
			LektionController.steg(dt, tele({ mjukhet = 0.10 }))
			kvar -= dt
		end
	end
	local foreChip = hitta("Live").Visible
	LektionController.avbryt()
	check("säkerhet avbryter lektionen och släcker chipet",
		foreChip == true and hitta("Live").Visible == false,
		string.format("(före %s → efter %s)", tostring(foreChip),
			tostring(hitta("Live").Visible)))
	check("och kortet stängs samtidigt",
		hitta("Kort").Visible == false,
		string.format("(Visible %s)", tostring(hitta("Kort").Visible)))
	check("ingen lektion pågår efter avbrottet",
		LektionController.pagar() == false,
		string.format("(pågår %s)", tostring(LektionController.pagar())))
	--[[ …och en stegning efter avbrottet får inte väcka något till liv. ]]
	LektionController.steg(1, tele())
	check("och en bildruta efter avbrottet visar ingenting",
		hitta("Kort").Visible == false and hitta("Live").Visible == false,
		"(kort och chip fortsatt släckta)")
end

--[[ ══ MÄTNINGEN STYR — INTE SLUMPEN, INTE EN KONSTANT ═════════════
	Kvaliteten ska komma ur telemetrin. Provet varierar ETT fält och
	kräver att bedömningen följer med; gör den inte det mäter modulen
	något annat än ritten. ]]
do
	local bas = { uppsutten = true, gangart = "trav", fart = 3, onskadFart = 3,
		svangradie = 10, balans = 0.5, mjukhet = 0.5, fokus = 0.5,
		spanning = 0.5, svarstid = 0.3, etableringstid = 1.2, paradKvalitet = 0.5 }
	local function med(k, v)
		local t = {}
		for a, b in bas do t[a] = b end
		t[k] = v
		return Lektion.kvalitet(t)
	end
	local mjukLag, mjukHog = med("mjukhet", 0.10), med("mjukhet", 0.95)
	check("mjukheten i bedömningen kommer ur telemetrins mjukhet",
		mjukHog.mjukhet > mjukLag.mjukhet + 0.5,
		string.format("(%.2f → %.2f)", mjukLag.mjukhet, mjukHog.mjukhet))
	local snabb, trog = med("svarstid", 0.05), med("svarstid", 0.50)
	check("timingen kommer ur svarstiden",
		snabb.timing > trog.timing + 0.1,
		string.format("(%.2f → %.2f)", trog.timing, snabb.timing))
	local rakt = med("svangradie", math.huge)
	check("en rak linje ger ingen linjebedömning i stället för en påhittad",
		rakt.linje == nil,
		string.format("(linje %s)", tostring(rakt.linje)))

	--[[ DEN DEKLARERADE LUCKAN. Roblox har ingen utbildningsskala och
	     mäter därför ingen rytm. Det ska stå i SAKNAS och rytmen ska vara
	     nil — inte 0, som hade gjort den till svagast i varje volt. ]]
	local q = Lektion.kvalitet(bas)
	check("rytmen är deklarerad som omätt, inte satt till noll",
		q.rytm == nil and table.concat(Lektion.SAKNAS, ",") == "rytm",
		string.format("(rytm %s · SAKNAS %s)", tostring(q.rytm),
			table.concat(Lektion.SAKNAS, ",")))
	local obs = Ugneta.observationer("storvolt",
		{ linje = 0.90, balans = 0.40 }, nil)
	local nammerRytm = false
	for _, o in obs do if o.dim == "rytm" then nammerRytm = true end end
	check("och en omätt dimension nämns inte som svagast",
		not nammerRytm and #obs == 2,
		string.format("(%d observationer, rytm nämnd %s)", #obs, tostring(nammerRytm)))
end

--[[ ══ KANONEN ÄGER ORDEN ═══════════════════════════════════════════ ]]
do
	check("live-registret läses ur kanonen, inte ur en kopia",
		UgnetaController.liveText("hand", false)
			== RidKanon.UGNETA.LIVE.hand.fel,
		string.format('("%s")', UgnetaController.liveText("hand", false)))
	check("övningarnas ordning kommer ur kanonen",
		#Lektion.ORDNING == 6 and Lektion.ORDNING[3] == "storvolt",
		string.format("(%d övningar, tredje %s)", #Lektion.ORDNING,
			tostring(Lektion.ORDNING[3])))
	check("skillnaderna mot webben är uppräknade, inte tysta",
		#Lektion.SKILLNAD == 2,
		string.format("(%d deklarerade)", #Lektion.SKILLNAD))
end

print("")
if fails > 0 then
	print(string.format("%d mätning(ar) föll.", fails))
else
	print("Alla mätningar gick igenom.")
end
