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
		ser grön ut i räkningen ovan. Egennamn och tangentnamn undantas
		inte här: katalogen innehåller inga. ]]
	local samma = {}
	for _, nyckel in ipairs(nycklar) do
		if Sprak.iSprak("sv", nyckel) == Sprak.iSprak("en", nyckel) then
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

print("\n── Lärarkortet (Ugneta) ──")
do
	local svRubrik = pa("sv-se", function() return Sprak.t("ugneta.rubrik") end)
	local enRubrik = pa("en-us", function() return Sprak.t("ugneta.rubrik") end)
	check("lärarkortets rubrik byter språk", svRubrik ~= enRubrik,
		string.format("sv %q · en %q", svRubrik, enRubrik))
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
if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("\nsprak.spec: alla gröna")
end
