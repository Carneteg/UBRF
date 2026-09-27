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
local RESULTAT = {
	volt = { avsnitt = { varv = 1, referens = { radie = 10 }, medelAvvikelse = 0.84, tid = 41.2 } },
	halt = { skrittMeter = 6.3, haltSekunder = 3.1 },
	overgang = { travMeter = 12.5, skrittMeter = 4.2 },
	serpentin = { meter = 58.4, korsningar = { {}, {} } },
	tempo = { meter = 20.4, sekunder = 16.0, medelFart = 1.27, spridning = 0.08 },
	vag_mitt = { figur = "mitt", meter = 36.1, langd = 40 },
	vag_diag = { figur = "diag", meter = 41.7, langd = 44.7 },
	halvvolt = { meter = 31.6, skarvar = { {}, {} }, skuld = 0 },
	galopp = { travMeter = 8.4, galoppMeter = 9.9, galoppsida = "ej_bedomd" },
	markbom = { inridningM = 4.1, utridningM = 3.2, passage = "rotplan" },
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
	local function ledBild(lage, nr, resNr, uid)
		return { lage = lage, forsokNr = nr, progress = 40,
			resultat = if resNr then { forsokNr = resNr, userId = uid, meter = 18.2, sekunder = 24.6 } else nil }
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
	check("två frågor ger en text, inte två sammanfattningar",
		A.text(b, ridKontext("halt")) == A.text(b, ridKontext("halt")))
end

print("\n── 6. Varje nyckel finns på båda språken ──")
for _, typ in { "volt", "halt", "overgang", "serpentin", "tempo", "vag_mitt", "vag_diag", "halvvolt",
	"galopp", "markbom", "leda" } do
	for _, del in { "klar", "nasta", "igen" } do
		local n = "aterkoppling." .. typ .. "." .. del
		check(n, Sprak.iSprak("sv", n) ~= n and Sprak.iSprak("en", n) ~= n)
	end
end

if fails > 0 then error(tostring(fails) .. " FEL") end
print(string.format("\nLEKTIONSATERKOPPLING: %d prov, alla gröna", total))
