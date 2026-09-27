--!nostrict
--[[
	UGNETAS TEXTINSTÄLLNINGAR (C2) — docs/INSTRUCTOR-TEXT-CONTROLS-CONTRACT.md.

	KLIENT-bänken, samma uppställning som klient-ugnetayta: klienten startas
	av `init.client.luau` i banken, Naromrade är värd och Ugnetas yta står
	uppe. Knapparna trycks genom sina riktiga `Activated`. Live-kommentarerna
	går genom `UgnetaController.live` — enda anropsstället är
	LektionController, som skickar det `UgnetaTema.steg` gav oförändrat.

	SKRIVEN FÖR SENARE KÖRNING (bygg nu, testa sist). Inte körd.
	BÄNKANTAGANDEN: `Activated:Fire()` kör anslutna funktioner synkront;
	`NR.satRider(false)` ritar panelen; `_larare()` ritar ytan innan den läses.
]]
local fel, total = 0, 0
local function prova(vad, ok, detalj)
	total += 1
	if ok then
		print(("  OK   %s%s"):format(vad, if detalj then "  " .. tostring(detalj) else ""))
	else
		fel += 1
		print(("  FEL  %s%s"):format(vad, if detalj then "  " .. tostring(detalj) else ""))
	end
end
local RunService = game:GetService("RunService")
local UC = UgnetaController
local NR = Naromrade
local I = LararInstallning
local A = LektionsAterkoppling

Sprak.satLocale("sv-se")
Sprak.satVal("sv")
RunService.Heartbeat:Fire(1 / 60)
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
local function har(t, del) return type(t) == "string" and string.find(t, del, 1, true) ~= nil end
local function valKnapp(grupp, varde)
	for _, v in UC._installning().val do
		if v.grupp == grupp and v.varde == varde then return v end
	end
	return nil
end
local function tryck(grupp, varde)
	local v = valKnapp(grupp, varde)
	if v then v.knapp.Activated:Fire() end
	return v ~= nil
end
local function ytaText() return UC._larare().text end
local function panelAter() NR.satRider(false); return NR._panel().ater end

print("\n── 1. Standard och hur man hittar dit ──")
do
	prova("standard är dagens beteende: normalt och detaljerat",
		I.kommentarer() == "normal" and I.detalj() == "detaljerad")
	local y = UC._larare()
	local ins = UC._installning()
	prova("ytan står uppe med flaggan kvar", y.synlig and y.knapp ~= nil and y.knapp.Parent ~= nil)
	local k = ins.knapp
	prova("textknappen finns i huvudet, 44 hög, fokuserbar och med tydlig etikett",
		k ~= nil and k.Parent == y.knapp.Parent and k.Size.Y.Offset >= 44 and k.Selectable == true
		and k.Text == Sprak.t("installning.knapp"))
	prova("inställningarna är stängda från början", ins.oppen == false and ins.synlig == false)
	k.Activated:Fire()
	ins = UC._installning()
	prova("ett tryck öppnar området i samma yta", ins.oppen and ins.synlig)
	prova("fem val i två grupper, alla 44 höga och fokuserbara", (function()
		if #ins.val ~= 5 then return false end
		for _, v in ins.val do
			if v.knapp.Size.Y.Offset < 44 or v.knapp.Selectable ~= true then return false end
		end
		return true
	end)())
	prova("valt läge syns: Normalt och Detaljerad är valda",
		valKnapp("kommentarer", "normal").vald and valKnapp("detalj", "detaljerad").vald
		and not valKnapp("kommentarer", "farre").vald and not valKnapp("detalj", "kort").vald)
	prova("flaggan är kvar och fungerar medan området är öppet", (function()
		UC._vaxlaSprak()
		local ok = Sprak.eget() == "en" and valKnapp("kommentarer", "farre").text == "Fewer"
			and UC._installning().knapp.Text == Sprak.iSprak("en", "installning.knapp")
		UC._vaxlaSprak()
		return ok and valKnapp("kommentarer", "farre").text == "Färre"
	end)())
	UC._installning().klar.Activated:Fire()
	prova("Klar stänger området", UC._installning().oppen == false and UC._installning().synlig == false)
	UC._vaxlaInstallning()
	prova("textknappen öppnar igen", UC._installning().oppen)
end

print("\n── 1b. Området tar ingen panelrad ──")
do
	UC.visa("Kort", {}, true, nil, true, true) -- tre äldre kortknappar
	NR.satRider(false)
	local oppen = #NR._val()
	UC._installning().klar.Activated:Fire()
	NR.satRider(false)
	local stangd = #NR._val()
	prova("samma panelrader med området öppet och stängt, högst fyra",
		oppen == stangd and stangd <= 4, ("%d / %d"):format(oppen, stangd))
	UC._vaxlaInstallning()
	UC.dolj()
end

print("\n── 2. Kommentarer: normalt ──")
do
	tryck("kommentarer", "normal")
	UC.dolj()
	UC.live("K-normal", true)
	prova("normalt: kommentaren står i chipet, ytan och panelen",
		ytaText() == "K-normal" and panelAter() == "K-normal", ("%q / %q"):format(ytaText(), panelAter()))
end

print("\n── 3. Färre: ⌈n/2⌉ av n, ingen kö ──")
do
	tryck("kommentarer", "farre")
	prova("valet slog igenom och syns som valt", I.kommentarer() == "farre" and valKnapp("kommentarer", "farre").vald)
	local sedda = {}
	for i = 1, 6 do
		UC.live("F" .. i, true)
		sedda[i] = ytaText()
	end
	prova("1:a, 3:e och 5:e visas; 2:a, 4:e och 6:e släpps",
		sedda[1] == "F1" and sedda[2] == "F1" and sedda[3] == "F3" and sedda[4] == "F3"
		and sedda[5] == "F5" and sedda[6] == "F5", table.concat(sedda, ","))
	--[[ Ett tomt ord är ingen kommentar och räknas inte. ]]
	UC.live("", true)
	UC.live("F7", true)
	prova("ett tomt ord räknas inte som en kommentar", ytaText() == "F7")
end

print("\n── 4. Inga: släcker det som står, och inget kommer tillbaka ──")
do
	prova("KONTROLL: en kommentar står uppe", ytaText() == "F7" and panelAter() == "F7")
	tryck("kommentarer", "inga")
	prova("inga: den synliga kommentaren släcks i ytan och i panelen",
		ytaText() ~= "F7" and panelAter() ~= "F7", ("%q / %q"):format(ytaText(), panelAter()))
	UC.live("SLAPPT", true)
	prova("inga: en ny valfri kommentar visas inte", ytaText() ~= "SLAPPT" and panelAter() ~= "SLAPPT")
	tryck("kommentarer", "normal")
	prova("tillbaka till normalt: den släppta kommentaren kommer INTE tillbaka",
		ytaText() ~= "SLAPPT" and panelAter() ~= "SLAPPT")
	UC.live("FARSK", true)
	prova("bara en färsk kommentar visas efter återställningen", ytaText() == "FARSK")
	UC.dolj()
end

print("\n── 5. Inga rör aldrig det obligatoriska ──")
do
	tryck("kommentarer", "inga")
	UC.visa(function()
		return Sprak.t("ugneta.ej_bedomd.rubrik"), { Sprak.t("ugneta.ej_bedomd.punkt") },
			true, Sprak.t("ugneta.prova_igen")
	end)
	NR.satRider(false)
	prova("lektionens besked och val står kvar under Inga",
		UC.vantar() == true and #NR._val() == 1
		and har(ytaText(), Sprak.t("ugneta.ej_bedomd.punkt")))
	UC.sakerhetTarOver()
	prova("säkerheten tar över som förut (väntan släckt, inga val kvar)",
		UC.vantar() == false and #NR._val() == 0)
	UC.ridrad("ugneta.rad.borja_skritt", { "W" })
	prova("ridraden står kvar under Inga", ytaText() == Sprak.t("ugneta.rad.borja_skritt", "W"))
	tryck("kommentarer", "normal")
	UC.dolj()
end

print("\n── 6. Underlaget ändras inte: samma temasignaler i alla lägen ──")
do
	local DIMS = Ugneta.dimensionerFor("storvolt")
	local function kor(lage)
		I.satKommentarer(lage)
		UC.dolj()
		local tema = UgnetaTema.nytt("storvolt")
		local signaler, visade = {}, 0
		local t = 0
		while t < UgnetaTema.VAL_SEK + 3 * UgnetaTema.SVAG_SEK + 30 do
			local txt, bra, _, signal = UgnetaTema.steg(tema, 1 / 30, { linje = 0.2, rytm = 0.95, balans = 0.95 },
				nil, nil, DIMS)
			if txt ~= "" then
				table.insert(signaler, tostring(signal) .. (if bra then "+" else "-"))
				local fore = ytaText()
				UC.live(txt .. "#" .. #signaler, bra)
				if ytaText() ~= fore then visade += 1 end
			end
			t += 1 / 30
		end
		return table.concat(signaler, ","), visade, #signaler
	end
	local sN, vN, nN = kor("normal")
	local sF, vF, nF = kor("farre")
	local sI, vI, nI = kor("inga")
	prova("temat, spärren och signalerna är desamma i alla tre lägen", sN == sF and sF == sI and nN > 0, sN)
	prova("färre visar ⌈n/2⌉, inga visar noll, normalt visar alla",
		vN == nN and vF == math.ceil(nF / 2) and vI == 0, ("%d/%d · %d/%d · %d/%d"):format(vN, nN, vF, nF, vI, nI))
	I.satKommentarer("normal")
	UC.dolj()
end

print("\n── 7. Kort/detaljerad på samma validerade bevis, båda språken ──")
do
	local RES = {
		volt = { avsnitt = { varv = 1, referens = { radie = 10 }, medelAvvikelse = 0.84, tid = 41.2 } },
		halt = { mal = "X", skrittMeter = 6.3, haltSekunder = 3.1 },
		overgang = { mal = "T1->T2", travMeter = 12.5, skrittMeter = 4.2 },
		serpentin = { rutt = "serpentin-3", meter = 58.4, korsningar = { {}, {} } },
		tempo = { ovning = "jamn_skritt", enhet = "m/s", meter = 20.4, sekunder = 16.0, medelFart = 1.27,
			spridning = 0.08 },
		vag_mitt = { figur = "vag_mitt", meter = 36.1, langd = 40 },
		vag_diag = { figur = "vag_diag", meter = 41.7, langd = 44.7 },
		halvvolt = { figur = "halvvolt", meter = 31.6, skarvar = { {} }, skuld = 1.4 },
		galopp = { ovning = "galoppfattning", travMeter = 8.4, galoppMeter = 9.9, galoppsida = "ej_bedomd" },
		markbom = { ovning = "markbom", inridningM = 4.1, utridningM = 3.2, passage = "rotplan" },
	}
	local SIFFRA = { volt = "0,8", halt = "6,3", overgang = "12,5", serpentin = "58", tempo = "1,27",
		vag_mitt = "36,1", vag_diag = "41,7", halvvolt = "31,6", galopp = "9,9", markbom = "4,1" }
	local function bild(typ, lage, r)
		local k = if r then table.clone(r) else nil
		if k then k.forsokId = 3; k.rittId = "r" end
		return { lage = lage, typ = if typ == "volt" then nil else typ, forsokId = 3, rittId = "r",
			progress = 55, resultat = k }
	end
	tryck("detalj", "kort")
	prova("kort är valt och syns som valt", I.detalj() == "kort" and valKnapp("detalj", "kort").vald)
	for typ, r in RES do
		local t = A.text(bild(typ, "complete", r), { typ = typ, ritt = "r" })
		prova(typ .. ": kort = egen kort rad + samma nästa steg, utan siffror",
			har(t, Sprak.t("aterkoppling." .. typ .. ".kort")) and har(t, Sprak.t("aterkoppling." .. typ .. ".nasta"))
			and not har(t, SIFFRA[typ]), t)
	end
	local tg = A.text(bild("galopp", "complete", RES.galopp), { typ = "galopp", ritt = "r" })
	local tm = A.text(bild("markbom", "complete", RES.markbom), { typ = "markbom", ritt = "r" })
	prova("kort: galoppsidan och hovavståndet sägs fortfarande", har(tg, "bedömdes inte") and har(tm, "mäts inte"))
	local ogiltig = table.clone(RES.halt); ogiltig.skrittMeter = 0 / 0
	prova("kort: ogiltigt bevis är fortfarande «inga detaljer»",
		A.text(bild("halt", "complete", ogiltig), { typ = "halt", ritt = "r" }) == Sprak.t("aterkoppling.okant"))
	local annat = bild("halt", "complete", RES.halt); annat.resultat.forsokId = 2
	prova("kort: ett annat försöks resultat binds fortfarande inte",
		A.text(annat, { typ = "halt", ritt = "r" }) == Sprak.t("aterkoppling.okant"))
	local tt = A.text(bild("halt", "timeout", RES.halt), { typ = "halt", ritt = "r" })
	prova("kort timeout: sann status och tips, ingen procent och inget resultat",
		har(tt, Sprak.t("aterkoppling.timeout_kort")) and har(tt, Sprak.t("aterkoppling.halt.igen"))
		and not har(tt, "55") and not har(tt, "6,3"), tt)
	local led = { lage = "complete", forsokNr = 2, kontextNr = 7,
		resultat = { forsokNr = 2, userId = 9, kontextNr = 6, meter = 18.2, sekunder = 24 } }
	prova("kort: ledningens kontexttext är densamma i båda lägena",
		A.text(led, { typ = "leda", userId = 9 }) == Sprak.t("aterkoppling.leda.annan"))
	Sprak.satVal("en")
	local en = A.text(bild("halt", "complete", RES.halt), { typ = "halt", ritt = "r" })
	prova("kort på engelska", en == Sprak.iSprak("en", "aterkoppling.halt.kort") .. " "
		.. Sprak.iSprak("en", "aterkoppling.halt.nasta"), en)
	Sprak.satVal("sv")
	tryck("detalj", "detaljerad")
	local d = A.text(bild("halt", "complete", RES.halt), { typ = "halt", ritt = "r" })
	prova("tillbaka till detaljerad: siffrorna ur SAMMA bild igen", har(d, "6,3"), d)
	for _, typ in { "volt", "halt", "overgang", "serpentin", "tempo", "vag_mitt", "vag_diag", "halvvolt",
		"galopp", "markbom", "leda" } do
		local n = "aterkoppling." .. typ .. ".kort"
		prova(n .. " finns på båda språken", Sprak.iSprak("sv", n) ~= n and Sprak.iSprak("en", n) ~= n)
	end
end

print("\n── 8. Livslängd: inga dubbla lyssnare, valet överlever ett nytt bygge ──")
do
	local fore = I._antalLyssnare()
	UC.start()
	UC.start()
	prova("upprepad start lägger inte till lyssnare", I._antalLyssnare() == fore,
		("%d -> %d"):format(fore, I._antalLyssnare()))
	tryck("detalj", "kort")
	UC.start()
	prova("valet står kvar efter start (sessionens minne, ingen persistens)", I.detalj() == "kort")
	prova("ogiltiga värden avvisas", I.satKommentarer("hog") == false and I.satDetalj("lang") == false)
	I.satDetalj("detaljerad")
	I.satKommentarer("normal")
end

if fel > 0 then
	print(("\n%d mätning(ar) föll."):format(fel))
	error("klient-lararinstallning.spec: " .. fel .. " fel")
end
print(("\nklient-lararinstallning.spec: %d prov, alla gröna"):format(total))
