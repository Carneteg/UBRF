--!nostrict
--[[ UGNETAS ÅTERKOPPLING NÄR EN ÖVNING ÄR SLUT — docs/LESSON-FEEDBACK-CONTRACT.md.

	KLIENT-bänken. `LektionsAterkoppling.text` anropas med bilder formade som
	varje producents frysta `resultat` (fältnamnen ur lektionsmodulerna och
	LedLektion). Den fulla kedjan server → bild → panel per typ är PLANERAD,
	inte skriven.

	SKRIVEN FÖR SENARE KÖRNING (bygg nu, testa sist). Inte körd. ]]
local fails, total = 0, 0
local function check(namn, villkor, detalj)
	total += 1
	if not villkor then fails += 1 end
	print((if villkor then "  OK   " else "  FEL  ") .. namn .. (if detalj then "  " .. tostring(detalj) else ""))
end
local A = LektionsAterkoppling
Sprak.satVal("sv")

local function har(s, del) return type(s) == "string" and string.find(s, del, 1, true) ~= nil end

--[[ Producentformade resultat, ett per typ. ]]
--[[ R1: med producenternas egna identitetsfält (mal/rutt/ovning/figur/
	enhet/galoppsida/passage), exakt som de fryses i källan. ]]
local RESULTAT = {
	volt = { avsnitt = { varv = 1, referens = { radie = 10 }, medelAvvikelse = 0.84, tid = 41.2 } },
	halt = { mal = "X", skrittMeter = 6.3, haltSekunder = 3.1 },
	overgang = { mal = "T1->T2", travMeter = 12.5, skrittMeter = 4.2 },
	serpentin = { rutt = "serpentin-3", meter = 58.4, korsningar = { {}, {} } },
	tempo = { ovning = "jamn_skritt", enhet = "m/s", meter = 20.4, sekunder = 16.0, medelFart = 1.27,
		spridning = 0.08 },
	vag_mitt = { figur = "vag_mitt", meter = 36.1, langd = 40 },
	vag_diag = { figur = "vag_diag", meter = 41.7, langd = 44.7 },
	halvvolt = { figur = "halvvolt", meter = 31.6, skarvar = { {}, {} }, skuld = 0 },
	galopp = { ovning = "galoppfattning", travMeter = 8.4, galoppMeter = 9.9, galoppsida = "ej_bedomd" },
	markbom = { ovning = "markbom", inridningM = 4.1, utridningM = 3.2, passage = "rotplan" },
}
local FAKTA = { -- en siffra ur resultatet som måste stå i texten (sv, decimalkomma)
	volt = "0,8", halt = "6,3", overgang = "12,5", serpentin = "58", tempo = "1,27",
	vag_mitt = "36,1", vag_diag = "41,7", halvvolt = "31,6", galopp = "9,9", markbom = "4,1",
}

local function ridBild(typ, lage, res)
	local r = res and table.clone(res) or nil
	if r then r.forsokId = 7; r.rittId = "ritt-1" end
	return { lage = lage, typ = if typ == "volt" then nil else typ, forsokId = 7, rittId = "ritt-1",
		progress = if lage == "complete" then 100 else 63, resultat = r }
end
local function ridKontext(typ) return { typ = typ, ritt = "ritt-1" } end

print("\n── 1. Klart försök: sammanfattning ur det frysta resultatet och ett nästa steg ──")
for typ, res in RESULTAT do
	local t = A.text(ridBild(typ, "complete", res), ridKontext(typ))
	check(typ .. ": faktum ur resultatet står i texten", har(t, FAKTA[typ]), t)
	check(typ .. ": ett nästa steg följer", har(t, Sprak.t("aterkoppling." .. typ .. ".nasta")), t)
	check(typ .. ": inget påhittat betyg", not har(t, "%") or typ == "tempo", t)
end
do
	local t = A.text(ridBild("galopp", "complete", RESULTAT.galopp), ridKontext("galopp"))
	check("galopp: galoppsidan bedöms inte, och det sägs", har(t, "bedömdes inte"), t)
	t = A.text(ridBild("markbom", "complete", RESULTAT.markbom), ridKontext("markbom"))
	check("markbom: hovavståndet mäts inte, och det sägs", har(t, "mäts inte"), t)
	t = A.text(ridBild("tempo", "complete", RESULTAT.tempo), ridKontext("tempo"))
	check("tempo: jämn fart, aldrig takt", har(t, "jämn") and not har(t, "takt"), t)
	local skuld = table.clone(RESULTAT.halvvolt); skuld.skuld = 1.4
	t = A.text(ridBild("halvvolt", "complete", skuld), ridKontext("halvvolt"))
	check("halvvolt: okrediterad drift under halt sägs ärligt", har(t, "1,4") and har(t, "räknades inte"), t)
	t = A.text(ridBild("halvvolt", "complete", RESULTAT.halvvolt), ridKontext("halvvolt"))
	check("halvvolt: ingen skuldmening när skulden är noll", not har(t, "räknades inte"), t)
end

print("\n── 2. Fel försök, fel ritt, fel typ eller inget resultat: ärligt, inget lånat ──")
do
	local okant = Sprak.t("aterkoppling.okant")
	local b = ridBild("halt", "complete", RESULTAT.halt); b.resultat.forsokId = 6
	check("annat försök ger ingen sammanfattning", A.text(b, ridKontext("halt")) == okant)
	b = ridBild("halt", "complete", RESULTAT.halt); b.resultat.rittId = "ritt-0"
	check("resultat från en annan ritt ger ingen sammanfattning", A.text(b, ridKontext("halt")) == okant)
	b = ridBild("halt", "complete", RESULTAT.halt)
	check("bilden hör till en annan ritt än den aktuella",
		A.text(b, { typ = "halt", ritt = "ritt-2" }) == okant)
	check("typen stämmer inte", A.text(b, ridKontext("overgang")) == okant)
	b = ridBild("volt", "complete", RESULTAT.volt); b.typ = "halt"
	check("en volt-kontext tar inte en haltbild", A.text(b, ridKontext("volt")) == okant)
	b = ridBild("halt", "complete", nil)
	check("inget resultat", A.text(b, ridKontext("halt")) == okant)
	b = ridBild("halt", "complete", { forsokId = 7, rittId = "ritt-1" })
	check("resultat utan de fält typen behöver", A.text(b, ridKontext("halt")) == okant)
	b = ridBild("halt", "complete", RESULTAT.halt); b.forsokId = nil; b.resultat.forsokId = nil
	check("försök utan identitet binds inte", A.text(b, ridKontext("halt")) == okant)
end

print("\n── 3. Tiden slut och stängt: neutralt, inget resultat ──")
for typ, res in RESULTAT do
	local b = ridBild(typ, "timeout", res) -- ett resultat som skulle lånas om det kunde
	local t = A.text(b, ridKontext(typ))
	check(typ .. ": timeout ger serverns procent och ett konkret tips",
		har(t, "63") and har(t, Sprak.t("aterkoppling." .. typ .. ".igen")), t)
	check(typ .. ": timeout lånar inget resultat",
		not har(t, FAKTA[typ]) and not har(t, Sprak.t("aterkoppling." .. typ .. ".nasta")), t)
	check(typ .. ": stängt ger ingen återkoppling", A.text(ridBild(typ, "closed", res), ridKontext(typ)) == nil)
	check(typ .. ": under ritten ger ingen återkoppling",
		A.text(ridBild(typ, "riding", nil), ridKontext(typ)) == nil)
end
do
	local b = ridBild("halt", "timeout", nil); b.progress = 100
	check("timeout säger aldrig 100 %", har(A.text(b, ridKontext("halt")), "99"))
	b.progress = nil
	check("timeout utan procent säger 0", har(A.text(b, ridKontext("halt")), " 0 "))
end

print("\n── 4. Ledning: bunden till försöksnummer och spelare ──")
do
	local function ledBild(lage, nr, resNr, uid, kNu, kRes)
		return { lage = lage, forsokNr = nr, kontextNr = kNu or 5, progress = 40,
			resultat = if resNr then { forsokNr = resNr, userId = uid, kontextNr = kRes or 5,
				meter = 18.2, sekunder = 24.6 } else nil }
	end
	local k = { typ = "leda", userId = 42 }
	local t = A.text(ledBild("complete", 3, 3, 42), k)
	check("leda: sammanfattning och nästa steg", har(t, "18,2") and har(t, Sprak.t("aterkoppling.leda.nasta")), t)
	check("leda: annat försöksnummer", A.text(ledBild("complete", 3, 2, 42), k) == Sprak.t("aterkoppling.okant"))
	check("leda: annan spelare", A.text(ledBild("complete", 3, 3, 43), k) == Sprak.t("aterkoppling.okant"))
	t = A.text(ledBild("timeout", 3, 3, 42), k)
	check("leda: timeout neutral med tips", har(t, "40") and not har(t, "18,2")
		and har(t, Sprak.t("aterkoppling.leda.igen")), t)
	check("leda: stängt ger inget", A.text(ledBild("closed", 3, 3, 42), k) == nil)
	-- R1: samma försök, men en annan bunden häst/modell eller karaktär sedan slutet.
	t = A.text(ledBild("complete", 3, 3, 42, 6, 5), k)
	check("R1 leda: annan kontextepok ger den neutrala kontexttexten", t == Sprak.t("aterkoppling.leda.annan")
		and not har(t, "18,2") and not har(t, Sprak.t("aterkoppling.leda.nasta")), t)
	local utan = ledBild("complete", 3, 3, 42); utan.resultat.kontextNr = nil
	check("R1 leda: ett resultat utan kontextepok binds inte", A.text(utan, k) == Sprak.t("aterkoppling.okant"))
	utan = ledBild("complete", 3, 3, 42); utan.kontextNr = nil
	check("R1 leda: en bild utan kontextepok binds inte", A.text(utan, k) == Sprak.t("aterkoppling.okant"))
	check("R1 leda: saknad spelare i kontexten binds inte",
		A.text(ledBild("complete", 3, 3, nil), { typ = "leda", userId = nil }) == Sprak.t("aterkoppling.okant"))
end

print("\n── 4b. R1: saknat, felformat, icke-ändligt och fel figur är INTE noll ──")
do
	local okant = Sprak.t("aterkoppling.okant")
	local function med(typ, andra)
		local r = table.clone(RESULTAT[typ])
		if typ == "volt" then
			local a = table.clone(r.avsnitt); a.referens = table.clone(a.referens)
			for kk, v in andra do if kk == "radie" then a.referens.radie = v else a[kk] = v end end
			r.avsnitt = a
		else
			for kk, v in andra do r[kk] = v end
		end
		return A.text(ridBild(typ, "complete", r), ridKontext(typ))
	end
	local INF, NAN = math.huge, 0 / 0
	local FALL = {
		{ "serpentin", { korsningar = false }, "saknade korsningar är inte noll korsningar" },
		{ "serpentin", { korsningar = "2" }, "korsningar som sträng" },
		{ "serpentin", { rutt = "serpentin-4" }, "fel rutt" },
		{ "halvvolt", { skarvar = false }, "saknade skarvar är inte noll skarvar" },
		{ "halvvolt", { skuld = false }, "saknad skuld" },
		{ "halvvolt", { skuld = NAN }, "NaN-skuld" },
		{ "halvvolt", { figur = "volt" }, "fel figur" },
		{ "tempo", { spridning = false }, "saknad spridning är inte 0 %" },
		{ "tempo", { spridning = "0.1" }, "spridning som sträng kastar inte" },
		{ "tempo", { sekunder = false }, "saknad tid" },
		{ "tempo", { medelFart = 0 }, "medelfart noll" },
		{ "tempo", { medelFart = INF }, "oändlig medelfart" },
		{ "tempo", { enhet = "km/h" }, "fel enhet" },
		{ "tempo", { ovning = "trav" }, "fel övning" },
		{ "volt", { radie = false }, "saknad radie" },
		{ "volt", { medelAvvikelse = false }, "saknad medelavvikelse (otillräckligt underlag)" },
		{ "volt", { tid = NAN }, "NaN-tid" },
		{ "volt", { varv = 0 }, "noll varv är inte en slutförd volt" },
		{ "volt", { varv = 1.5 }, "halvt varv" },
		{ "halt", { skrittMeter = -INF }, "minus oändlig sträcka" },
		{ "halt", { mal = "A" }, "fel mål" },
		{ "overgang", { travMeter = -1 }, "negativ sträcka" },
		{ "overgang", { mal = "T2->T1" }, "fel mål" },
		{ "vag_mitt", { figur = "vag_diag" }, "diagonalens resultat under mittlinjen" },
		{ "vag_diag", { figur = "mitt" }, "gammal figurbeteckning" },
		{ "vag_mitt", { langd = 0 }, "längd noll" },
		{ "galopp", { galoppsida = "vanster" }, "en bedömd galoppsida finns inte i producenten" },
		{ "galopp", { galoppMeter = NAN }, "NaN-galopp" },
		{ "markbom", { passage = "hov" }, "annan passagegrund" },
		{ "markbom", { utridningM = false }, "saknad utridning" },
	}
	for _, f in FALL do
		local ok, t = pcall(med, f[1], f[2])
		check(f[1] .. ": " .. f[3], ok and t == okant and not har(t, "?"), tostring(t))
	end
	-- Giltiga nollor där producenten kan frysa dem.
	local t = med("serpentin", { korsningar = {} })
	check("serpentin: en tom korsningslista är ett observerat noll", har(t, " 0 "), t)
	t = med("halvvolt", { skarvar = {}, skuld = 0 })
	check("halvvolt: noll skarvar och noll skuld är giltiga", har(t, " 0 ") and not har(t, "räknades inte"), t)
	t = med("tempo", { spridning = 0 })
	check("tempo: uppmätt noll spridning är giltig", har(t, "0 %"), t)
	local b = ridBild("halt", "timeout", nil); b.progress = NAN
	check("timeout: NaN-procent blir 0, aldrig ett mått", har(A.text(b, ridKontext("halt")), " 0 "))
	b.progress = INF
	check("timeout: oändlig procent blir 0", har(A.text(b, ridKontext("halt")), " 0 "))
end

print("\n── 5. Språkbyte: orden byts, fakta står kvar, inget sparas ──")
do
	local b = ridBild("halt", "complete", RESULTAT.halt)
	local sv = A.text(b, ridKontext("halt"))
	Sprak.satVal("en")
	local en = A.text(b, ridKontext("halt"))
	check("engelska orden", har(en, "Next time") and har(en, "6.3"), en)
	check("orden skiljer sig", sv ~= en)
	Sprak.satVal("sv")
	check("tillbaka till svenska ger samma text som först", A.text(b, ridKontext("halt")) == sv)
	-- R1: en upprepad fråga på SAMMA bild. Detta visar INTE transportordning;
	-- den provas genom de riktiga panelerna i haltlektion- och ledlektion-specarna.
	check("två frågor ger en text, inte två sammanfattningar",
		A.text(b, ridKontext("halt")) == A.text(b, ridKontext("halt")))
end

print("\n── 5b. C1 volten: jämförelsen med förra volten (docs/CIRCLE-COMPARISON-CONTRACT.md) ──")
do
	--[[ Producentens sanning: jämförelsens `avvikelse` ÄR det frysta avsnittets
		`medelAvvikelse` (samma varv), så provets data håller dem lika. ]]
	local function voltRes(nu)
		local r = table.clone(RESULTAT.volt)
		r.avsnitt = table.clone(r.avsnitt); r.avsnitt.medelAvvikelse = nu
		return r
	end
	local function medJ(nu, forr, over)
		local b = ridBild("volt", "complete", voltRes(nu))
		local j = { forsokId = 7, forraForsokId = 6, avvikelse = nu, forraAvvikelse = forr }
		for k, v in over or {} do j[k] = v end
		b.jamforelse = j
		return A.text(b, ridKontext("volt"))
	end
	local NARMARE, FORRA = "Närmare linjen än förra volten", "Förra volten"
	local utan = A.text(ridBild("volt", "complete", voltRes(0.5)), ridKontext("volt"))
	local t = medJ(0.5, 1.0)
	check("närmare: bekräftas med båda talen, förra först", har(t, NARMARE) and har(t, "i snitt 1,0 m, nu 0,5 m"), t)
	check("närmare: sammanfattningen och nästa steg står kvar",
		har(t, "radie 10") and har(t, Sprak.t("aterkoppling.volt.nasta")), t)
	t = medJ(0.8, 0.8)
	check("lika: neutralt, inget «närmare»", har(t, FORRA) and not har(t, NARMARE), t)
	t = medJ(1.2, 0.6)
	check("längre bort: neutralt, ingen kritik", har(t, FORRA) and har(t, "i snitt 0,6 m från linjen, nu 1,2 m")
		and not har(t, NARMARE), t)
	check("avrundning: 0,54 → 0,46 visar 0,5 → 0,5 och är INTE närmare",
		not har(medJ(0.46, 0.54), NARMARE) and har(medJ(0.46, 0.54), FORRA), medJ(0.46, 0.54))
	check("avrundning: 0,56 → 0,44 visar 0,6 → 0,4 och är närmare",
		har(medJ(0.44, 0.56), NARMARE) and har(medJ(0.44, 0.56), "0,6") and har(medJ(0.44, 0.56), "0,4"),
		medJ(0.44, 0.56))
	-- Bindning och bevis: inget av detta får ge en jämförelse, och inget får kasta.
	local NAN = 0 / 0
	for _, fall in {
		{ { forsokId = 8 }, "jämförelsen hör till ett annat försök" },
		{ { forraForsokId = 7 }, "förra försöket är samma som det visade" },
		{ { avvikelse = NAN }, "NaN nu" },
		{ { forraAvvikelse = math.huge }, "oändlig förra" },
		{ { avvikelse = -0.1 }, "negativt avstånd" },
		{ { forraAvvikelse = "1.0" }, "text i stället för tal" },
	} do
		local ok, tt = pcall(medJ, 0.5, 1.0, fall[1])
		check("ingen jämförelse: " .. fall[2], ok and tt == utan, tt)
	end
	do
		local b = ridBild("volt", "complete", voltRes(0.5)); b.jamforelse = "trasig"
		local ok, tt = pcall(A.text, b, ridKontext("volt"))
		check("ingen jämförelse: ingen tabell", ok and tt == utan, tt)
	end
	do -- Ogiltig sammanfattning: jämförelsen hängs aldrig på den ärliga "inga detaljer"-texten.
		local trasig = { avsnitt = { varv = 1, referens = { radie = 10 }, medelAvvikelse = false, tid = 41.2 } }
		local b = ridBild("volt", "complete", trasig)
		b.jamforelse = { forsokId = 7, forraForsokId = 6, avvikelse = 0.5, forraAvvikelse = 1.0 }
		local tt = A.text(b, ridKontext("volt"))
		check("ogiltig sammanfattning får ingen jämförelse", tt == Sprak.t("aterkoppling.okant"), tt)
	end
	do -- En annan typ läser aldrig voltens jämförelse.
		local b = ridBild("halt", "complete", RESULTAT.halt)
		b.jamforelse = { forsokId = 7, forraForsokId = 6, avvikelse = 0.5, forraAvvikelse = 1.0 }
		check("halten läser inte voltens jämförelse", not har(A.text(b, ridKontext("halt")), NARMARE))
	end
	-- KORT: bara bekräftelsen när den håller, annars ingenting.
	LararInstallning.satDetalj("kort")
	local kortUtan = A.text(ridBild("volt", "complete", voltRes(0.5)), ridKontext("volt"))
	t = medJ(0.5, 1.0)
	check("kort närmare: bara den korta bekräftelsen",
		har(t, Sprak.t("aterkoppling.volt.narmare_kort")) and not har(t, "1,0"), t)
	check("kort lika: ingenting läggs till", medJ(0.8, 0.8) == kortUtan, medJ(0.8, 0.8))
	check("kort längre bort: ingenting läggs till", medJ(1.2, 0.6) == kortUtan, medJ(1.2, 0.6))
	LararInstallning.satDetalj("detaljerad")
	-- Språkbyte: orden byts, talen står kvar.
	Sprak.satVal("en")
	t = medJ(0.5, 1.0)
	check("engelska: närmare med talen", har(t, "Closer to the line than your previous circle")
		and har(t, "1.0") and har(t, "0.5"), t)
	Sprak.satVal("sv")
	check("tillbaka till svenska", har(medJ(0.5, 1.0), NARMARE))
	for _, n in { "aterkoppling.volt.narmare", "aterkoppling.volt.forra", "aterkoppling.volt.narmare_kort" } do
		check(n, Sprak.iSprak("sv", n) ~= n and Sprak.iSprak("en", n) ~= n)
	end
end

print("\n── 5c. C1 haltet: närmare X än förra haltet (docs/HALT-COMPARISON-CONTRACT.md) ──")
do
	local function medJ(nu, forr, over)
		local b = ridBild("halt", "complete", RESULTAT.halt)
		local j = { forsokId = 7, forraForsokId = 6, avvikelse = nu, forraAvvikelse = forr }
		for k, v in over or {} do j[k] = v end
		b.jamforelse = j
		return A.text(b, ridKontext("halt"))
	end
	local NARMARE, FORRA = "Närmare X än förra haltet", "Förra haltet"
	local utan = A.text(ridBild("halt", "complete", RESULTAT.halt), ridKontext("halt"))
	local t = medJ(0.3, 0.9)
	check("halt närmare: bekräftas, förra först", har(t, NARMARE) and har(t, "0,9 m från X, nu 0,3 m"), t)
	check("halt närmare: sammanfattningen och nästa steg står kvar",
		har(t, FAKTA.halt) and har(t, Sprak.t("aterkoppling.halt.nasta")), t)
	check("halt närmare: voltens ord används inte", not har(t, "linjen"), t)
	t = medJ(0.6, 0.6)
	check("halt lika: neutralt", har(t, FORRA) and not har(t, NARMARE), t)
	t = medJ(1.2, 0.4)
	check("halt längre bort: neutralt, förra först", har(t, FORRA) and har(t, "0,4 m från X, nu 1,2 m")
		and not har(t, NARMARE), t)
	check("halt avrundning: 0,54 → 0,46 är INTE närmare", not har(medJ(0.46, 0.54), NARMARE))
	check("halt avrundning: 0,56 → 0,44 är närmare", har(medJ(0.44, 0.56), NARMARE))
	local NAN = 0 / 0
	for _, fall in {
		{ { forsokId = 8 }, "annat försök" },
		{ { forraForsokId = 7 }, "samma försök som förra" },
		{ { avvikelse = NAN }, "NaN" },
		{ { forraAvvikelse = -math.huge }, "minus oändligt" },
		{ { avvikelse = -0.2 }, "negativt" },
	} do
		local ok, tt = pcall(medJ, 0.3, 0.9, fall[1])
		check("halt ingen jämförelse: " .. fall[2], ok and tt == utan, tt)
	end
	do -- Ogiltig sammanfattning: ingen jämförelse på "inga detaljer".
		local b = ridBild("halt", "complete", { mal = "Y", skrittMeter = 6.3, haltSekunder = 3.1 })
		b.jamforelse = { forsokId = 7, forraForsokId = 6, avvikelse = 0.3, forraAvvikelse = 0.9 }
		check("halt: ogiltig sammanfattning får ingen jämförelse",
			A.text(b, ridKontext("halt")) == Sprak.t("aterkoppling.okant"))
	end
	do -- Volten läser voltens nycklar, haltet haltets — samma jämförelse, olika typ.
		local b = ridBild("volt", "complete", RESULTAT.volt)
		b.jamforelse = { forsokId = 7, forraForsokId = 6, avvikelse = 0.3, forraAvvikelse = 0.9 }
		local tv = A.text(b, ridKontext("volt"))
		check("volten får inte haltets ord", not har(tv, NARMARE) and har(tv, "Närmare linjen"), tv)
	end
	LararInstallning.satDetalj("kort")
	local kortUtan = A.text(ridBild("halt", "complete", RESULTAT.halt), ridKontext("halt"))
	check("halt kort närmare: bara den korta bekräftelsen",
		har(medJ(0.3, 0.9), Sprak.t("aterkoppling.halt.narmare_kort")) and not har(medJ(0.3, 0.9), "0,9"))
	check("halt kort lika och längre bort: ingenting", medJ(0.6, 0.6) == kortUtan and medJ(1.2, 0.4) == kortUtan)
	LararInstallning.satDetalj("detaljerad")
	Sprak.satVal("en")
	t = medJ(0.3, 0.9)
	check("halt engelska", har(t, "Closer to X than your previous halt") and har(t, "0.9 m from X, now 0.3 m"), t)
	Sprak.satVal("sv")
	for _, n in { "aterkoppling.halt.narmare", "aterkoppling.halt.forra", "aterkoppling.halt.narmare_kort" } do
		check(n, Sprak.iSprak("sv", n) ~= n and Sprak.iSprak("en", n) ~= n)
	end
end

print("\n── 6. Varje nyckel finns på båda språken ──")
for _, typ in { "volt", "halt", "overgang", "serpentin", "tempo", "vag_mitt", "vag_diag", "halvvolt",
	"galopp", "markbom", "leda" } do
	for _, del in { "klar", "nasta", "igen" } do
		local n = "aterkoppling." .. typ .. "." .. del
		check(n, Sprak.iSprak("sv", n) ~= n and Sprak.iSprak("en", n) ~= n)
	end
end
check("aterkoppling.leda.annan", Sprak.iSprak("sv", "aterkoppling.leda.annan") ~= "aterkoppling.leda.annan"
	and Sprak.iSprak("en", "aterkoppling.leda.annan") ~= "aterkoppling.leda.annan")

if fails > 0 then error(tostring(fails) .. " FEL") end
print(string.format("\nLEKTIONSATERKOPPLING: %d prov, alla gröna", total))
