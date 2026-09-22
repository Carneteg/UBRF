--!nostrict
--[[
	SPRÅKGRINDEN — svenska för svenska spelare, engelska annars (#162).

	Kravet går inte att mäta genom att läsa koden: en HUD kan ha ett
	`Sprak.t(...)` på varje rad och ändå visa svenska för alla, om språket
	aldrig läses eller nyckeln inte finns. Grinden kör därför RITNINGEN två
	gånger — `sv-se` och `en-us` — och kräver att texten SKILJER SIG.

	Mätpunkterna:
	  1. katalogen: varje nyckel har båda språken, och platshållarna
	     (%s, %d) är lika många och i samma ordning,
	  2. regeln: `sv*` ger svenska, allt annat engelska,
	  3. skötsel-HUD:en, hjälpen, pekknapparna och lärarkortet ritas om,
	  4. världens prompter skrivs om på klienten — och hästens EGENNAMN
	     översätts inte,
	  5. översättningsskulden är redovisad med källa och skäl.

	Kör: python3 roblox/tests/build.py tests/sprak.spec.luau
	     && luau roblox/tests/.build/sprak.spec.luau
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

--[[ ══ 1. KATALOGEN ════════════════════════════════════════════════════ ]]
print("\n── Katalogen: båda språken, samma platshållare ──")
do
	local nycklar = Sprak.nycklar()
	check("språkkanonen har text att visa", #nycklar > 50, #nycklar .. " nycklar")
	check("ingen nyckel saknar svenska", #Sprak.saknade("sv") == 0,
		table.concat(Sprak.saknade("sv"), ", "))
	check("ingen nyckel saknar engelska", #Sprak.saknade("en") == 0,
		table.concat(Sprak.saknade("en"), ", "))

	--[[ Platshållarna måste stämma, annars kastar `string.format` — eller,
		värre, skriver ut ett tal där ett namn skulle stå. ]]
	local fel = {}
	for _, nyckel in ipairs(nycklar) do
		local sv, en = Sprak.iSprak("sv", nyckel), Sprak.iSprak("en", nyckel)
		local function markorer(text)
			local ut = {}
			for m in string.gmatch(text, "%%[sd]") do table.insert(ut, m) end
			return table.concat(ut, "")
		end
		if markorer(sv) ~= markorer(en) then
			table.insert(fel, string.format("%s (sv %s ≠ en %s)", nyckel,
				markorer(sv) == "" and "inga" or markorer(sv),
				markorer(en) == "" and "inga" or markorer(en)))
		end
	end
	check("platshållarna är samma i båda språken", #fel == 0, table.concat(fel, " · "))

	--[[ …och att en översättning FAKTISKT är en översättning. En kopierad
		svensk text i en-fältet är samma fel som ingen översättning, men
		ser grön ut i räkningen ovan.

		SAMMANFALLANDE TERMER (#180). Raden sa förut att katalogen inte
		innehåller några undantag. Det stämde när den skrevs. Sedan #179
		bär katalogen också pekknapparnas gångartsnamn, och där finns ett
		ord som ÄR samma på båda språken: "halt" är engelska och en ridterm
		i båda länderna. `en = "HALT"` är alltså en korrekt översättning som
		råkar se ut som en kopia.

		Undantaget är en uttrycklig lista, inte ett mönster: varje post
		måste motiveras här. Regeln behåller därmed sin kraft — en
		oöversatt sträng fastnar fortfarande — utan att tvinga fram en
		SÄMRE engelsk text bara för att bli grön. ]]
	--[[ Listan är TOM sedan 2026-09-17. `touch.halt` var dess enda post,
	     och den knappen finns inte längre — gångarten väljs med DRIV och
	     BROMS, vars etiketter ("DRIV"/"GO", "BROMS"/"SLOW") är riktiga
	     översättningar. En tom lista är starkast möjliga läge för regeln:
	     varje sammanfallande sträng är nu ett fynd. ]]
	local SAMMANFALLER: { [string]: string } = {}
	local samma = {}
	for _, nyckel in ipairs(nycklar) do
		if Sprak.iSprak("sv", nyckel) == Sprak.iSprak("en", nyckel)
			and not SAMMANFALLER[nyckel] then
			table.insert(samma, nyckel)
		end
	end
	check("ingen engelsk text är en kopia av den svenska", #samma == 0,
		table.concat(samma, ", "))
end

--[[ ══ 2. REGELN ════════════════════════════════════════════════════════ ]]
print("\n── Regeln: sv* ger svenska, allt annat engelska ──")
do
	check("sv-se ger svenska", Sprak.sprakFor("sv-se") == "sv")
	check("sv-fi ger också svenska", Sprak.sprakFor("sv-fi") == "sv")
	check("SV-SE ger svenska oavsett skiftläge", Sprak.sprakFor("SV-SE") == "sv")
	check("en-us ger engelska", Sprak.sprakFor("en-us") == "en")
	check("de-de ger engelska (fallbacket)", Sprak.sprakFor("de-de") == "en")
	check("tom locale ger engelska, inte krasch", Sprak.sprakFor("") == "en")
	check("nil ger engelska, inte krasch", Sprak.sprakFor(nil) == "en")
	--[[ Okänd nyckel ska ge NYCKELN, inte tom sträng: ett stavfel ska syna
		i HUD:en och i grinden. ]]
	check("en okänd nyckel ger nyckeln tillbaka",
		Sprak.iSprak("sv", "hud.finns_inte") == "hud.finns_inte")
end

--[[ ══ 3. YTORNA RITAS OM ═══════════════════════════════════════════════ ]]
local function pa(locale, fn)
	Sprak.satLocale(locale)
	local resultat = fn()
	Sprak.satLocale("sv-se")
	return resultat
end

print("\n── Skötsel-HUD:en ritas i spelarens språk ──")
do
	local hastId = Stallet.FORSTA_DAGEN_HAST
	local state = Preparation.nyState(hastId, 1)
	local function rubrikPa(locale, status)
		return pa(locale, function()
			PreparationController.tillampa(Preparation.vy(state, status, os.clock()))
			return PreparationController._rubrik()
		end)
	end
	--[[ MITT I SKÖTSELN är rubriken FASENS NAMN ur skötselkanonen.

		Raden mätte förut att rubriken var SVENSK på båda språken och
		kallade det redovisad skuld. PRODUKTBESLUTET i #162 tog bort den
		skulden: en spelare som inte läser svenska ska läsa engelska, också
		i kanonen. Kommentaren härintill sa att "ändras beslutet är det den
		här raden som ska ändras" — beslutet ändrades, och det är den här
		raden.

		Nu mäts tre saker: att svenskan är kanonens svenska fasnamn, att
		engelskan är kanonens ENGELSKA fasnamn, och att de skiljer sig. Det
		sista är det som fäller en tyst fallback: en engelsk post som råkat
		bli en kopia av den svenska ser annars ut som en översättning. ]]
	local svRubrik = rubrikPa("sv-se", Preparation.STATUS.FORBEREDER)
	local enRubrik = rubrikPa("en-us", Preparation.STATUS.FORBEREDER)
	local forstaFas = Preparation.stegFaser()[1]
	local fasnamn = forstaFas.namn
	local fasnamnEn = forstaFas.namnEn
	check("rubriken finns på svenska", svRubrik ~= "" and svRubrik ~= nil, tostring(svRubrik))
	check("mitt i skötseln är rubriken kanonens fasnamn, på spelarens språk",
		svRubrik == fasnamn and enRubrik == fasnamnEn and fasnamn ~= fasnamnEn,
		string.format("sv %q · en %q · kanon sv %q / en %q", tostring(svRubrik),
			tostring(enRubrik), tostring(fasnamn), tostring(fasnamnEn)))

	--[[ Väntelägets rubrik har en egen nyckel och mäts för sig: den var
		den enda vyn som varken har fas eller moment att falla tillbaka
		på, och en tom rubrik hade sett ut som ett språk. ]]
	local svVantar = rubrikPa("sv-se", Preparation.STATUS.VANTAR_MODELL)
	local enVantar = rubrikPa("en-us", Preparation.STATUS.VANTAR_MODELL)
	check("väntelägets rubrik översätts också", enVantar ~= svVantar
		and enVantar == Sprak.iSprak("en", "hud.vantar_pa_hast"),
		string.format("sv %q · en %q", tostring(svVantar), tostring(enVantar)))
end

print("\n── Hjälpen och pekknapparna ──")
do
	local function rader(locale)
		return pa(locale, function()
			local m = {}
			for _, r in ipairs(KontrollHjalp.rader()) do table.insert(m, r.vad) end
			return m
		end)
	end
	local sv, en = rader("sv-se"), rader("en-us")
	check("hjälpen har rader", #sv > 5, #sv .. " rader")
	check("och varje rad byter språk", (function()
		if #sv ~= #en then return false end
		for i = 1, #sv do if sv[i] == en[i] then return false end end
		return true
	end)(), string.format("sv[1] %q · en[1] %q", tostring(sv[1]), tostring(en[1])))

	--[[ Radens IDENTITET är nyckeln, inte texten: uppslaget ska hitta samma
		rad oavsett språk. Annars går hjälpen inte att prova på engelska. ]]
	check("_rad hittar raden på nyckeln", KontrollHjalp._rad("hjalp.sitt_upp_av") ~= nil)
	check("_rad hittar samma rad på den svenska texten",
		KontrollHjalp._rad("Sitt upp / sitt av") ~= nil)
	check("_rad hittar samma rad på den engelska texten",
		KontrollHjalp._rad("Mount / dismount") ~= nil)

	--[[ Pekknappen och hjälpraden om den ska säga SAMMA sak — de läser
		samma nyckel. En hjälp som säger något annat än knappen den
		beskriver är värre än ingen hjälp. ]]
	local pekEn = pa("en-us", function()
		local ut = {}
		game:GetService("UserInputService").KeyboardEnabled = false
		game:GetService("UserInputService").TouchEnabled = true
		for _, r in ipairs(KontrollHjalp.rader()) do ut[r.vad] = r.reglage end
		game:GetService("UserInputService").KeyboardEnabled = true
		game:GetService("UserInputService").TouchEnabled = false
		return ut
	end)
	check("pekreglaget i hjälpen är knappens EGEN engelska etikett",
		pekEn[Sprak.iSprak("en", "hjalp.sitt_upp_av")] == Sprak.iSprak("en", "touch.sitt_av"),
		string.format("%q", tostring(pekEn[Sprak.iSprak("en", "hjalp.sitt_upp_av")])))
end

print("\n── Lärarens besked (Ugneta) ──")
do
	--[[ #244: `ugneta.rubrik` var avsändarraden i den rivna nederpanelen
	     och finns inte längre. Provet mäter i stället knappen som ÄR kvar
	     — lektionens enda väg vidare, och den text en engelsk spelare
	     annars hade mött på svenska. ]]
	local svBorja = pa("sv-se", function() return Sprak.t("ugneta.borja_lektionen") end)
	local enBorja = pa("en-us", function() return Sprak.t("ugneta.borja_lektionen") end)
	check("knappen in i lektionen byter språk", svBorja ~= enBorja
			and svBorja ~= "ugneta.borja_lektionen",
		string.format("sv %q · en %q", svBorja, enBorja))
	local svForsok = pa("sv-se", function() return Sprak.t("ugneta.forsok", 2) end)
	local enForsok = pa("en-us", function() return Sprak.t("ugneta.forsok", 2) end)
	check("försöksnumret formateras i båda språken",
		string.find(svForsok, "2") ~= nil and string.find(enForsok, "2") ~= nil
			and svForsok ~= enForsok,
		string.format("sv %q · en %q", svForsok, enForsok))
end

print("\n── Världens prompter skrivs om på klienten ──")
do
	--[[ Samma väg produktionen går: servern sätter nycklar, klientens
		`Prompttext` skriver texten. Provet sätter attributen precis som
		`DorrService` och `StallService` gör. ]]
	local function promptMed(nyckel, objekt, arg)
		local p = Instance.new("ProximityPrompt")
		p:SetAttribute("SprakNyckel", nyckel)
		if objekt then p:SetAttribute("SprakObjekt", objekt) end
		if arg then p:SetAttribute("SprakArg", arg) end
		return p
	end

	local dorrSv = pa("sv-se", function()
		local p = promptMed("dorr.oppna", "dorr.objekt")
		Prompttext.skrivOm(p)
		return { p.ActionText, p.ObjectText }
	end)
	local dorrEn = pa("en-us", function()
		local p = promptMed("dorr.oppna", "dorr.objekt")
		Prompttext.skrivOm(p)
		return { p.ActionText, p.ObjectText }
	end)
	check("dörrprompten är svensk på sv-se", dorrSv[1] == "Öppna" and dorrSv[2] == "Dörr",
		string.format("%q / %q", tostring(dorrSv[1]), tostring(dorrSv[2])))
	check("och engelsk på en-us", dorrEn[1] == "Open" and dorrEn[2] == "Door",
		string.format("%q / %q", tostring(dorrEn[1]), tostring(dorrEn[2])))

	--[[ HÄSTENS NAMN ÖVERSÄTTS INTE. Egennamnet skickas som argument, och
		det ska stå kvar ordagrant i båda språken — en översatt häst hade
		varit precis den sorts påhitt CLAUDE.md förbjuder. ]]
	local namn = "Blackrock Jack"
	local boxSv = pa("sv-se", function()
		local p = promptMed("stall.titta_in", "stall.star_har", namn)
		Prompttext.skrivOm(p)
		return { p.ActionText, p.ObjectText }
	end)
	local boxEn = pa("en-us", function()
		local p = promptMed("stall.titta_in", "stall.star_har", namn)
		Prompttext.skrivOm(p)
		return { p.ActionText, p.ObjectText }
	end)
	check("boxprompten byter språk", boxSv[1] ~= boxEn[1] and boxSv[2] ~= boxEn[2],
		string.format("sv %q · en %q", tostring(boxSv[2]), tostring(boxEn[2])))
	check("men hästens namn står ordagrant i BÅDA språken",
		string.find(boxSv[2], namn, 1, true) ~= nil
			and string.find(boxEn[2], namn, 1, true) ~= nil,
		string.format("sv %q · en %q", tostring(boxSv[2]), tostring(boxEn[2])))

	--[[ En prompt UTAN argument får inte skriva ut "%s" för spelaren. ]]
	local utanArg = pa("en-us", function()
		local p = promptMed("stall.titta_in", "stall.star_har")
		p.ObjectText = "oförändrad"
		Prompttext.skrivOm(p)
		return p.ObjectText
	end)
	check("en nyckel med platshållare men utan argument lämnas orörd",
		string.find(utanArg, "%%s") == nil, string.format("%q", utanArg))
end

--[[ ══ 5. ÖVERSÄTTNINGSSKULDEN — OCH VAD SOM INTE FÅR LIGGA I DEN ═══════

	Här stod förut att hästarnas beskrivningar och skötselkanonens
	undervisande text var svenska med flit, och att skulden bara skulle
	vara redovisad. PRODUKTBESLUTET i #162 ändrade det: en spelare som
	inte läser svenska ska läsa engelska, också i kanonen. Båda posterna
	är översatta i sina källor och borta ur listan.

	Kvar mäts två saker: att varje kvarvarande post är motiverad, och —
	det som är hela poängen — att INGEN post säger sig ligga i First
	Playable-vägen. En builder som lägger tillbaka kanonen som "skuld"
	fälls här, inte i en review. ]]
print("\n── Översättningsskulden är redovisad och ligger utanför First Playable ──")
do
	local backlog = Sprak.backlog()
	local fel, iVagen = {}, {}
	for _, post in ipairs(backlog) do
		if type(post.kalla) ~= "string" or post.kalla == ""
			or type(post.vad) ~= "string" or post.vad == ""
			or type(post.skal) ~= "string" or #post.skal < 20 then
			table.insert(fel, tostring(post.kalla))
		end
		if post.firstPlayable ~= false then
			table.insert(iVagen, tostring(post.kalla))
		end
	end
	check("varje post bär källa, vad och ett skäl", #fel == 0,
		#fel > 0 and table.concat(fel, ", ") or (#backlog .. " poster"))
	check("ingen post ligger i First Playable-vägen", #iVagen == 0,
		#iVagen > 0 and table.concat(iVagen, ", ") or "noll poster i vägen")
	--[[ Skötselkanonen och hästarna får inte tas tillbaka in i listan. ]]
	local ater = {}
	for _, post in ipairs(backlog) do
		if string.find(post.kalla, "skotsel%.js") and not string.find(post.kalla, "—") then
			table.insert(ater, post.kalla)
		end
	end
	check("skötselkanonen står inte som skuld längre", #ater == 0,
		#ater > 0 and table.concat(ater, ", ") or "kanonen är översatt, inte skuld")
end

--[[ `os.exit` finns INTE i luau-CLI:t (den är nil). Ett anrop rakt ut gav
	en "attempt to call a nil value" i loggen i stället för ett läsbart
	slut — rött blev det, men av fel anledning i texten. Här används den
	om den finns, annars ger `error` den icke-nollskilda exitkoden. ]]

--[[ ══ EN PROMPT LEVER INTE LÄNGRE ÄN SIN DÖRR ═════════════════════

	Robustness Slice E.

	`kopplade` bar tidigare `true` och ingenting mer: fem lyssnare
	kopplades per prompt och ingen väg fanns tillbaka. En dörr som revs
	låg kvar som starkt modultillstånd resten av klientsessionen.

	Provet går genom den RIKTIGA livscykeln: `Prompttext.start()`,
	`workspace.DescendantAdded` och `DescendantRemoving` — inte bara
	`skrivOm`.

	TVÅ SKILDA LIVSCYKELFALL, och de får inte blandas ihop:

	  LOSSNAR   prompten lämnar världen UTAN att rivas, och kan komma
	            tillbaka. Det är den enda giltiga återkopplingen.
	  RIVS      prompten förstörs. Då är den TERMINAL — en förstörd
	            Instance går inte att sätta tillbaka i Roblox, och
	            bänken låser numera `Parent` på samma sätt.

	Första versionen bevisade «samma prompt kopplas om» genom att
	återförälda en RIVEN prompt. Det är inget Roblox tillåter, så
	mätningen vilade på en övergång som inte finns. ]]
print("\n── En prompt lever inte längre än sin dörr ──")
do
	local foreLocale = Sprak.eget()
	Sprak.satLocale("en-us")
	Prompttext._glomForProv()

	local rot = Instance.new("Folder")
	rot.Name = "SliceE"
	rot.Parent = workspace
	--[[ Ett hem UTANFÖR världen, dit en prompt kan lossna utan att rivas. ]]
	local avsides = Instance.new("Folder")
	avsides.Name = "SliceEAvsides"

	local function nyPrompt(namn, nyckel)
		local p = Instance.new("ProximityPrompt")
		p.Name = namn
		p:SetAttribute("SprakNyckel", nyckel)
		return p
	end

	--[[ ── EN PROMPT SOM FANNS INNAN START ─────────────────────── ]]
	local forst = nyPrompt("Forst", "dorr.oppna")
	forst.Parent = rot
	Prompttext.start()
	check("en prompt som fanns vid start översätts",
		forst.ActionText == Sprak.iSprak("en", "dorr.oppna"),
		tostring(forst.ActionText))
	check("och modulen äger den", Prompttext._lyssnare(forst) > 0,
		("%d lyssnare"):format(Prompttext._lyssnare(forst)))

	--[[ ── DE FEM REAKTIVA VÄGARNA ──────────────────────────────── ]]
	forst:SetAttribute("SprakNyckel", "dorr.stang")
	check("SprakNyckel slår igenom",
		forst.ActionText == Sprak.iSprak("en", "dorr.stang"),
		tostring(forst.ActionText))
	forst:SetAttribute("SprakObjekt", "dorr.entren")
	check("SprakObjekt slår igenom",
		forst.ObjectText == Sprak.iSprak("en", "dorr.entren"),
		tostring(forst.ObjectText))

	--[[ SprakArg, mätt på en nyckel som FAKTISKT har en platshållare —
	     `tack.sadel_for` är den `TackForradService` sätter tillsammans
	     med hästens namn. Utan argumentet skriver modulen medvetet
	     ingenting, så ett svar som inte innehåller namnet är ett fel. ]]
	forst:SetAttribute("SprakObjekt", "tack.sadel_for")
	forst:SetAttribute("SprakArg", "Trixie")
	check("SprakArg slår igenom och fyller platshållaren",
		forst.ObjectText == Sprak.iSprak("en", "tack.sadel_for", "Trixie")
			and string.find(forst.ObjectText, "Trixie") ~= nil,
		tostring(forst.ObjectText))
	forst:SetAttribute("SprakArg", "Jack")
	check("och ett NYTT argument slår igenom av sig självt",
		forst.ObjectText == Sprak.iSprak("en", "tack.sadel_for", "Jack"),
		tostring(forst.ObjectText))
	--[[ Tillbaka till en nyckel utan platshållare för resten. ]]
	forst:SetAttribute("SprakObjekt", "dorr.entren")
	forst:SetAttribute("SprakArg", "")

	forst.ActionText = "Pahittat"
	check("en överskriven ActionText hävdas tillbaka",
		forst.ActionText == Sprak.iSprak("en", "dorr.stang"),
		tostring(forst.ActionText))
	forst.ObjectText = "Pahittat"
	check("en överskriven ObjectText hävdas tillbaka",
		forst.ObjectText == Sprak.iSprak("en", "dorr.entren"),
		tostring(forst.ObjectText))

	--[[ ── EN SOM KOMMER TILL EFTERÅT ───────────────────────────── ]]
	local antalFore = Prompttext._kopplade()
	local sen = nyPrompt("Sen", "dorr.oppna")
	sen.Parent = rot
	check("EN NY PROMPT KOPPLAS AV DescendantAdded",
		Prompttext._kopplade() == antalFore + 1,
		("%d -> %d"):format(antalFore, Prompttext._kopplade()))
	check("och den översätts",
		sen.ActionText == Sprak.iSprak("en", "dorr.oppna"),
		tostring(sen.ActionText))
	local lyssnareEn = Prompttext._lyssnare(sen)

	--[[ TVÅ SAMTIDIGA ÄR ISOLERADE. ]]
	forst:SetAttribute("SprakNyckel", "dorr.oppna")
	sen:SetAttribute("SprakNyckel", "dorr.stang")
	check("två levande prompter påverkar inte varandra",
		forst.ActionText == Sprak.iSprak("en", "dorr.oppna")
			and sen.ActionText == Sprak.iSprak("en", "dorr.stang"),
		("%s / %s"):format(tostring(forst.ActionText), tostring(sen.ActionText)))

	--[[ ── FALL 1: DEN LOSSNAR, OCH KOMMER TILLBAKA ─────────────── ]]
	sen.Parent = avsides
	check("EN PROMPT SOM LÄMNAR VÄRLDEN ÄGS INTE LÄNGRE",
		Prompttext._kopplade() == antalFore,
		("%d -> %d"):format(antalFore + 1, Prompttext._kopplade()))
	check("och inga lyssnare hålls kvar på den",
		Prompttext._lyssnare(sen) == 0, ("%d"):format(Prompttext._lyssnare(sen)))

	--[[ Stale-händelser MEDAN den ligger utanför. Att tabellen är tom
	     räcker inte: en kvarlevande koppling hade fortsatt kalla
	     `skriv`. ]]
	sen.ActionText = "Kvarlamnat"
	sen:SetAttribute("SprakNyckel", "dorr.oppna")
	sen:SetAttribute("SprakObjekt", "dorr.entren")
	sen:SetAttribute("SprakArg", "Trixie")
	check("EN LOSSNAD PROMPTS HÄNDELSER RÖR INGENTING",
		sen.ActionText == "Kvarlamnat", tostring(sen.ActionText))

	sen.ActionText = ""
	sen.Parent = rot
	check("SAMMA PROMPT KOPPLAS OM NÄR DEN KOMMER TILLBAKA — EN GÅNG",
		Prompttext._kopplade() == antalFore + 1
			and Prompttext._lyssnare(sen) == lyssnareEn,
		("%d agda, %d lyssnare (var %d)"):format(Prompttext._kopplade(),
			Prompttext._lyssnare(sen), lyssnareEn))
	check("och den översätts igen",
		sen.ActionText == Sprak.iSprak("en", "dorr.oppna"),
		tostring(sen.ActionText))

	--[[ ── FALL 2: DEN RIVS, OCH ÄR DÄRMED SLUT ─────────────────── ]]
	local doomed = nyPrompt("Riven", "dorr.oppna")
	doomed.Parent = rot
	check("den rivna prompten var ägd innan",
		Prompttext._lyssnare(doomed) > 0)
	doomed:Destroy()
	check("EN RIVEN PROMPT ÄGS INTE LÄNGRE",
		Prompttext._lyssnare(doomed) == 0,
		("%d"):format(Prompttext._lyssnare(doomed)))
	doomed.ActionText = "Kvarlamnat"
	check("och dess händelser rör ingenting",
		doomed.ActionText == "Kvarlamnat", tostring(doomed.ActionText))
	--[[ …och den går INTE att sätta tillbaka. Det är hela skillnaden
	     mot fallet ovan, och bänken låser den som Roblox gör. ]]
	local gickAttAterfoda = pcall(function() doomed.Parent = rot end)
	check("EN RIVEN PROMPT ÄR TERMINAL — DEN GÅR INTE ATT ÅTERFÖDA",
		gickAttAterfoda == false, tostring(gickAttAterfoda))

	--[[ ── EN PROMPT UNDER ETT SUBTRÄD SOM FLYTTAS ──────────────── ]]
	do
		local modell = Instance.new("Model")
		modell.Name = "Dorrmodell"
		local ibland = nyPrompt("IModellen", "dorr.oppna")
		ibland.Parent = modell
		modell.Parent = rot
		check("en prompt DJUPT i ett subträd kopplas också",
			Prompttext._lyssnare(ibland) > 0,
			("%d lyssnare"):format(Prompttext._lyssnare(ibland)))
		check("och den översätts",
			ibland.ActionText == Sprak.iSprak("en", "dorr.oppna"),
			tostring(ibland.ActionText))

		--[[ Och så flyttas HELA modellen ut. `DescendantRemoving` är
		     descendant-scopad i Roblox, och dörrar sitter under modeller
		     — fyrar den bara för roten slipper prompten undan. ]]
		modell.Parent = avsides
		check("ETT FLYTTAT SUBTRÄD SLÄPPER OCKSÅ PROMPTEN I SIG",
			Prompttext._lyssnare(ibland) == 0,
			("%d lyssnare"):format(Prompttext._lyssnare(ibland)))
		ibland.ActionText = "Kvarlamnat"
		check("och dess händelser rör ingenting",
			ibland.ActionText == "Kvarlamnat", tostring(ibland.ActionText))
	end

	--[[ ── MÅNGA VARV ───────────────────────────────────────────── ]]
	local innanVarven = Prompttext._kopplade()
	for _ = 1, 8 do
		local t = nyPrompt("Tillfallig", "dorr.oppna")
		t.Parent = rot
		t:Destroy()
	end
	check("ÅTTA VARV LÄMNAR INGENTING EFTER SIG",
		Prompttext._kopplade() == innanVarven,
		("%d -> %d"):format(innanVarven, Prompttext._kopplade()))

	Prompttext._glomForProv()
	rot:Destroy()
	Sprak.satLocale(foreLocale)
end

if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("\nsprak.spec: alla gröna")
end
