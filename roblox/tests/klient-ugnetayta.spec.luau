--!nostrict
--[[
	UGNETAS YTA OCH SPRÅKFLAGGAN (#264 GAIT_READABILITY_AND_UGNETA).

	Ordern, i det här provets delar:

	  · Ugneta är ridinstruktören, med EN liten yta uppe till höger: namn
	    och titel, språkflaggan och högst ett meddelande. Handlingarna —
	    även lektionens Fortsätt/Prova igen — står kvar i panelen nere till
	    vänster, och samma undervisningsmening står inte på båda ställena.
	  · Flaggan visar det språk som GÄLLER och byter vid tryck. Bytet ska
	    ändra det som REDAN står — Ugnetas text, lektionens val och
	    panelens rader — utan att ritten startar om, att en handling
	    dubbleras eller att lektionen går vidare.
	  · Språkvalet går genom `Sprak` (ett val, en prenumeration), inte
	    genom en andra boolean i ytan. Per spelare på servern.
	  · Gammal coachning kastas vid språkbyte.

	Kedjan körs genom produktionens egna vägar: klienten startas av
	`init.client.luau` i banken, panelen är värd, flaggans egen handling
	(`_vaxlaSprak` — samma funktion som knappens `Activated`) byter.

	BÄNKGRÄNS: hur ytan SER ut, och att flaggorna läses som flaggor, är en
	mänsklig grind och redovisas som NOT_TESTED utan renderad bild.

	Kör: python3 roblox/tests/build.py tests/klient-ugnetayta.spec.luau
	     && luau roblox/tests/.build/klient-ugnetayta.spec.luau
]]

local fel = 0
local function prova(vad, ok, detalj)
	if ok then
		print(("  OK   %s%s"):format(vad, if detalj then "  " .. detalj else ""))
	else
		fel += 1
		print(("  FEL  %s%s"):format(vad, if detalj then "  " .. detalj else ""))
	end
end

local RunService = game:GetService("RunService")
local UC = UgnetaController
local NR = Naromrade

Sprak.satLocale("sv-se")
RunService.Heartbeat:Fire(1 / 60)

--[[ En kropp med ett LÄGE: panelen ritar inga handlingar utan en rot att
     mäta från (kontraktet: respawn ger inga handlingar som kan fyra).
     Samma attrapp som klient-uikontext bygger. ]]
do
	local karaktar = Instance.new("Model")
	karaktar.Name = "Spelare"
	local kropp = Instance.new("Part")
	kropp.Name = "HumanoidRootPart"
	kropp.Size = Vector3.new(2, 2, 1)
	kropp.CFrame = CFrame.new(Vector3.new(0, 3, 0))
	kropp.Parent = karaktar
	karaktar.Parent = workspace
	game:GetService("Players").LocalPlayer.Character = karaktar
end

print("\n── 1. Språket: ett val, en prenumeration ──")
do
	local anrop = 0
	local koppla = Sprak.vidByte(function() anrop += 1 end)
	Sprak.satVal("en")
	prova("satVal byter det uppslaget svarar", Sprak.t("ugneta.titel") == "Ugneta · Riding instructor",
		Sprak.t("ugneta.titel"))
	Sprak.satVal("en")
	prova("samma val två gånger meddelar en gång", anrop == 1, ("%d anrop"):format(anrop))
	prova("ett tredje språk avvisas", Sprak.satVal("de") == false and Sprak.eget() == "en")
	koppla()
	Sprak.satVal("sv")
	prova("en frånkopplad lyssnare hörs inte mer", anrop == 1, ("%d anrop"):format(anrop))

	--[[ PER SPELARE på servern: två spelare, två val. ]]
	local function spelare(val, locale)
		return { LocaleId = locale,
			GetAttribute = function(_, n) if n == Sprak.ATTRIBUT then return val end return nil end }
	end
	local a, b = spelare("en", "sv-se"), spelare(nil, "sv-se")
	prova("serverns svar följer VARJE spelares eget val",
		Sprak.forSpelare(a, "ugneta.titel") == "Ugneta · Riding instructor"
			and Sprak.forSpelare(b, "ugneta.titel") == "Ugneta · Ridinstruktör",
		("%s / %s"):format(Sprak.forSpelare(a, "ugneta.titel"), Sprak.forSpelare(b, "ugneta.titel")))
	prova("och ett ogiltigt attribut faller tillbaka på locale",
		Sprak.sprakForSpelare(spelare("xx", "sv-se")) == "sv")
end

print("\n── 2. Ugnetas yta uppe till höger ──")
do
	local y = UC._larare()
	prova("ytan står uppe när panelen är värd", y.synlig == true)
	prova("med namn och svensk titel", y.titel == "Ugneta · Ridinstruktör", y.titel)
	prova("och flaggan visar det språk som gäller: svenska",
		y.flagga == "Svenska" and y.sv and not y.en, y.flagga)
	local k = y.knapp
	prova("flaggans träffyta är minst 44×44 och går att fokusera",
		k ~= nil and k.Size.X.Offset >= 44 and k.Size.Y.Offset >= 44 and k.Selectable == true,
		k and ("%dx%d"):format(k.Size.X.Offset, k.Size.Y.Offset) or "saknas")
	local r = y.ram
	prova("ytan är ankrad uppe till höger, radie högst 8",
		r ~= nil and r.AnchorPoint.X == 1 and r.AnchorPoint.Y == 0
			and r.Size.X.Offset >= 260 and r.Size.X.Offset <= 300)

	UC._vaxlaSprak()
	local e = UC._larare()
	prova("ETT TRYCK PÅ FLAGGAN: engelska, på plats",
		Sprak.eget() == "en" and e.titel == "Ugneta · Riding instructor"
			and e.flagga == "English" and e.en and not e.sv,
		("%s · %s"):format(e.titel, e.flagga))
	UC._vaxlaSprak()
	prova("och ett tryck till: tillbaka till svenska",
		Sprak.eget() == "sv" and UC._larare().titel == "Ugneta · Ridinstruktör")
end

print("\n── 3. Ett besked som står kvar översätts på plats ──")
do
	--[[ Lektionens «ej bedömd»-besked, genom samma byggarväg lektionen
	     använder. Det väntar på spelaren; valet står i panelen. ]]
	UC.visa(function()
		return Sprak.t("ugneta.ej_bedomd.rubrik"), { Sprak.t("ugneta.ej_bedomd.punkt") },
			true, Sprak.t("ugneta.prova_igen")
	end)
	NR.satRider(false)
	local function valText()
		local ut = {}
		for _, v in ipairs(NR._val()) do table.insert(ut, tostring(v.text)) end
		return ut
	end
	local fore = valText()
	prova("utgångsläget: lektionen väntar och valet står i panelen",
		UC.vantar() == true and #fore == 1
			and string.find(fore[1], Sprak.iSprak("sv", "ugneta.prova_igen"), 1, true) ~= nil,
		table.concat(fore, " | "))
	local texten = UC._larare().text
	prova("och beskedet står i Ugnetas yta, inte i panelens återkoppling",
		texten ~= "" and NR._panel().ater ~= texten
			and string.find(NR._panel().ater, Sprak.iSprak("sv", "ugneta.ej_bedomd.punkt"), 1, true) == nil,
		("yta %q · panel %q"):format(texten, NR._panel().ater))

	UC._vaxlaSprak()
	NR.satRider(false)
	local efter = valText()
	prova("SPRÅKBYTET: samma val, nu på engelska",
		#efter == 1 and string.find(efter[1], Sprak.iSprak("en", "ugneta.prova_igen"), 1, true) ~= nil,
		table.concat(efter, " | "))
	prova("och lektionen väntar fortfarande — ingenting gick vidare",
		UC.vantar() == true)
	prova("och Ugnetas text är översatt på plats",
		string.find(UC._larare().text, Sprak.iSprak("en", "ugneta.ej_bedomd.punkt"), 1, true) ~= nil,
		UC._larare().text)
	UC.fortsatt()
	NR.satRider(false)
	prova("valet gick att göra EN gång efter bytet", UC.vantar() == false and #valText() == 0)
	UC.dolj()
	UC._vaxlaSprak()
end

print("\n── 3b. Efter ett säkerhetsavbrott översätts den kvarliggande övningen ──")
do
	--[[ Mätt i Studio: två monteringar inom 23 ms, och övningens text låg
	     kvar i bannerns etiketter medan byggaren kastats. ]]
	UC.visa(function()
		return Sprak.t("ugneta.ovning.halt_skritt.rubrik"), { Sprak.t("ugneta.ovning.halt_skritt.p1") },
			true, Sprak.t("ugneta.borja_lektionen")
	end)
	UC.sakerhetTarOver()
	UC._vaxlaSprak()
	local m, d = CoachBanner.text()
	prova("övningens text följer bytet även efter avbrottet",
		d == Sprak.iSprak("en", "ugneta.ovning.halt_skritt.p1"), ("%q / %q"):format(m, d))
	prova("och avbrottets väntan väcks inte av bytet", UC.vantar() == false and #NR._val() == 0)
	UC._vaxlaSprak()
end

print("\n── 4. Gammal coachning kastas vid byte ──")
do
	UC.live("KOMMENTAR", true)
	prova("utgångsläget: chipets kommentar står i Ugnetas yta",
		UC._larare().text == "KOMMENTAR", UC._larare().text)
	UC._vaxlaSprak()
	prova("efter bytet står den inte kvar på fel språk",
		UC._larare().text ~= "KOMMENTAR", UC._larare().text)
	UC.dolj()
	UC._vaxlaSprak()
end

print("\n── 5. Ridraden: nyckel och argument, aldrig en fryst mening ──")
do
	UC.ridrad("ugneta.rad.borja_skritt", { "W / ↑" })
	local sv = UC._larare().text
	UC._vaxlaSprak()
	UC.ridrad("ugneta.rad.borja_skritt", { "W / ↑" })
	local en = UC._larare().text
	prova("samma rad på båda språken, med spelarens egen tangent",
		sv == Sprak.iSprak("sv", "ugneta.rad.borja_skritt", "W / ↑")
			and en == Sprak.iSprak("en", "ugneta.rad.borja_skritt", "W / ↑"),
		("%q / %q"):format(sv, en))
	UC._vaxlaSprak()
	UC.ridrad(nil)
end

print("\n── 6. Ugnetas ridrad: beröm för det som hänt, aldrig före ──")
do
	local R = UgnetaRad
	local s = R.ny()
	local function steg(sek, inn)
		local n, a
		local t = 0
		while t < sek do
			n, a = R.steg(s, 0.1, inn)
			t += 0.1
		end
		return n, a
	end
	local bas = { uppsutten = true, lektion = false, driv = "W / ↑", travTillaten = true }
	local function med(o)
		local t = table.clone(bas)
		for k, v in pairs(o) do t[k] = v end
		return t
	end
	local n = steg(0.5, med({ gait = "halt" }))
	prova("i halt, första halvsekunden: tyst", n == nil, tostring(n))
	local n2, a2 = steg(1.5, med({ gait = "halt" }))
	prova("sedan: börja i skritt, med spelarens egen knapp",
		n2 == "ugneta.rad.borja_skritt" and a2 and a2[1] == "W / ↑", tostring(n2))
	local n3 = steg(1.0, med({ gait = "walk" }))
	prova("ingen beröm för skritt innan den är etablerad", n3 ~= "ugneta.rad.bra_skritt", tostring(n3))
	local n4 = steg(3.0, med({ gait = "walk" }))
	prova("etablerad skritt: beröm för just det", n4 == "ugneta.rad.bra_skritt", tostring(n4))
	local n5 = steg(7.0, med({ gait = "walk" }))
	prova("berömmet skymmer inte målet: sedan nästa steg, trav",
		n5 == "ugneta.rad.be_om_trav", tostring(n5))
	local n6 = steg(1.0, med({ gait = "walk", lektion = true }))
	prova("under en lektion är raden tyst — lektionen äger rösten", n6 == nil, tostring(n6))
	local n7 = steg(0.2, { uppsutten = false })
	prova("avsittning kastar allt", n7 == nil and s.gait == nil and next(s.sagt) == nil)

	--[[ R1 fynd 2: berömmet för skritten får inte överleva skritten. ]]
	local function skrittBerom()
		local ny = R.ny()
		for k, v in pairs(ny) do s[k] = v end
		s.gait, s.forra, s.berom, s.lektion = nil, nil, nil, nil
		steg(0.1, med({ gait = "walk" }))
		return steg(3.1, med({ gait = "walk" }))
	end
	for _, till in ipairs({ "halt", "trot", "canter" }) do
		local fore = skrittBerom()
		local efter = R.steg(s, 0.1, med({ gait = till }))
		prova(("beröm för skritt, sedan %s: berömmet följer inte med"):format(till),
			fore == "ugneta.rad.bra_skritt" and efter ~= "ugneta.rad.bra_skritt",
			("%s → %s"):format(tostring(fore), tostring(efter)))
	end
	local fore = skrittBerom()
	local iLektion = R.steg(s, 0.1, med({ gait = "walk", lektion = true }))
	local efterLektion = R.steg(s, 0.1, med({ gait = "walk", lektion = false }))
	prova("in i en lektion och ut igen: det gamla berömmet är borta",
		fore == "ugneta.rad.bra_skritt" and iLektion == nil
			and efterLektion ~= "ugneta.rad.bra_skritt",
		("%s → %s → %s"):format(tostring(fore), tostring(iLektion), tostring(efterLektion)))
	--[[ Och i halt efter skritten står inget beröm för skritten kvar, hur
	     länge hon än står. (Börja-i-skritt gäller bara den som aldrig rört
	     sig, så här är raden tyst.) ]]
	skrittBerom()
	local halt = steg(2.0, med({ gait = "halt" }))
	prova("i halt efter skritten: ingen beröm för skritt",
		halt ~= "ugneta.rad.bra_skritt", tostring(halt))
end

print("\n── 6b. Världens prompter och panelens rader byter språk på plats ──")
do
	--[[ En dörr som servern byggt: nyckeln står på prompten, klienten
	     skriver texten (`Prompttext`). ]]
	local del = Instance.new("Part")
	del.Name = "Provdorr"
	del.CFrame = CFrame.new(Vector3.new(2, 3, 0))
	local p = Instance.new("ProximityPrompt")
	p.Name = "DorrPrompt"
	p:SetAttribute("SprakNyckel", "dorr.oppna")
	p.ActionText = Sprak.iSprak("sv", "dorr.oppna")
	p.Parent = del
	del.Parent = workspace
	local sv = p.ActionText
	UC._vaxlaSprak()
	local en = p.ActionText
	prova("dörrens text skrivs om när flaggan byter",
		sv == Sprak.iSprak("sv", "dorr.oppna") and en == Sprak.iSprak("en", "dorr.oppna"),
		("%q → %q"):format(sv, en))
	UC._vaxlaSprak()
	del:Destroy()
end

print("\n── 7. Lyssnarna växer inte ──")
do
	local fore = Sprak._antalLyssnare()
	UC.start()
	UC.start()
	prova("ytan kopplar sin språklyssnare EN gång, hur ofta den än startas",
		Sprak._antalLyssnare() == fore, ("%d → %d"):format(fore, Sprak._antalLyssnare()))
end

if fel > 0 then
	print(("\n%d mätning(ar) föll."):format(fel))
	error("klient-ugnetayta.spec: " .. fel .. " fel")
end
print("\nklient-ugnetayta.spec: alla gröna")
