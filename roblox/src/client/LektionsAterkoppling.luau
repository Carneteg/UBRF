--!strict
--[[ UGNETAS ÅTERKOPPLING NÄR EN ÖVNING ÄR SLUT — docs/LESSON-FEEDBACK-CONTRACT.md.

	EN liten formaterare för de tio ridlektionerna och ledningslektionen.
	Den bygger bara på det FRYSTA resultatet för det visade försöket och
	lägger till ett nästa övningssteg. Inget betyg, ingen gemensam mätare,
	ingen jämförelse, inget minne, ingen belöning. Texten räknas fram vid
	varje panelfråga ur aktuell bild och aktuellt språk och sparas aldrig —
	därför kan varken dubbla bilder, omritningar eller språkbyten ge en
	dubbel eller gammal sammanfattning. ]]
local Sprak = require(game:GetService("ReplicatedStorage").HorseCore.Sprak)
--[[ C2: kort eller detaljerad text (docs/INSTRUCTOR-TEXT-CONTROLS-CONTRACT.md). ]]
local Installning = require(script.Parent.LararInstallning)

local A = {}

--[[ R1: BEVIS ÄR BEVIS. Ett fält som saknas, har fel typ eller inte är ett
	ändligt tal är INTE ett uppmätt noll — då blir texten ärlig ("inga
	detaljer"). Validering sker FÖRE all aritmetik och formatering, så att
	ett trasigt resultat aldrig kastar och `?` aldrig står som ett mått. ]]
local function fin(x: any): boolean
	return type(x) == "number" and x == x and x ~= math.huge and x ~= -math.huge
end
local function ickeNeg(x: any): boolean
	return fin(x) and x >= 0
end
local function heltal(x: any): boolean
	return ickeNeg(x) and x % 1 == 0
end
local function lista(t: any): boolean
	return type(t) == "table"
end

local function tal(x: number, dec: number?): string
	local s = string.format("%." .. tostring(dec or 1) .. "f", x)
	if Sprak.eget() == "sv" then s = string.gsub(s, "%.", ",") end
	return s
end

--[[ Sammanfattningen per typ: bara fält som producenten faktiskt fryser,
	och producentens egen övnings-/figuridentitet där den finns. Varje
	nödvändigt fält prövas först; nil betyder "inga detaljer". Ett
	observerat noll (en tom lista, 0 m skuld) är giltigt där producenten
	kan frysa det. ]]
local function sammanfattning(typ: string, r: any): string?
	if typ == "volt" then
		local a = r.avsnitt
		if type(a) ~= "table" or type(a.referens) ~= "table" then return nil end
		if not (heltal(a.varv) and a.varv >= 1 and fin(a.referens.radie) and a.referens.radie > 0
			and ickeNeg(a.medelAvvikelse) and ickeNeg(a.tid)) then return nil end
		return Sprak.t("aterkoppling.volt.klar", tostring(a.varv), tal(a.referens.radie, 0),
			tal(a.medelAvvikelse), tal(a.tid, 0))
	elseif typ == "halt" then
		if r.mal ~= "X" or not (ickeNeg(r.skrittMeter) and ickeNeg(r.haltSekunder)) then return nil end
		return Sprak.t("aterkoppling.halt.klar", tal(r.skrittMeter), tal(r.haltSekunder))
	elseif typ == "overgang" then
		if r.mal ~= "T1->T2" or not (ickeNeg(r.travMeter) and ickeNeg(r.skrittMeter)) then return nil end
		return Sprak.t("aterkoppling.overgang.klar", tal(r.travMeter), tal(r.skrittMeter))
	elseif typ == "serpentin" then
		if r.rutt ~= "serpentin-3" or not (ickeNeg(r.meter) and lista(r.korsningar)) then return nil end
		return Sprak.t("aterkoppling.serpentin.klar", tal(r.meter, 0), tostring(#r.korsningar))
	elseif typ == "tempo" then
		if r.ovning ~= "jamn_skritt" or r.enhet ~= "m/s" then return nil end
		if not (ickeNeg(r.meter) and ickeNeg(r.sekunder) and fin(r.medelFart) and r.medelFart > 0
			and ickeNeg(r.spridning)) then return nil end
		return Sprak.t("aterkoppling.tempo.klar", tal(r.meter), tal(r.sekunder), tal(r.medelFart, 2),
			tal(r.spridning * 100, 0))
	elseif typ == "vag_mitt" or typ == "vag_diag" then
		if r.figur ~= typ or not (ickeNeg(r.meter) and fin(r.langd) and r.langd > 0) then return nil end
		return Sprak.t("aterkoppling." .. typ .. ".klar", tal(r.meter), tal(r.langd))
	elseif typ == "halvvolt" then
		if r.figur ~= "halvvolt" or not (ickeNeg(r.meter) and lista(r.skarvar) and fin(r.skuld)) then
			return nil
		end
		local text = Sprak.t("aterkoppling.halvvolt.klar", tal(r.meter), tostring(#r.skarvar))
		if r.skuld > 0.05 then
			text ..= " " .. Sprak.t("aterkoppling.halvvolt.skuld", tal(r.skuld))
		end
		return text
	elseif typ == "galopp" then
		if r.ovning ~= "galoppfattning" or r.galoppsida ~= "ej_bedomd" then return nil end
		if not (ickeNeg(r.travMeter) and ickeNeg(r.galoppMeter)) then return nil end
		return Sprak.t("aterkoppling.galopp.klar", tal(r.travMeter), tal(r.galoppMeter))
	elseif typ == "markbom" then
		if r.ovning ~= "markbom" or r.passage ~= "rotplan" then return nil end
		if not (ickeNeg(r.inridningM) and ickeNeg(r.utridningM)) then return nil end
		return Sprak.t("aterkoppling.markbom.klar", tal(r.inridningM), tal(r.utridningM))
	elseif typ == "hornet" then
		if r.figur ~= "hornet" or r.mitt ~= true or not (ickeNeg(r.meter) and fin(r.langd) and r.langd > 0) then
			return nil
		end
		return Sprak.t("aterkoppling.hornet.klar", tal(r.meter), tal(r.langd))
	elseif typ == "clearround" then
		--[[ D2a (docs/D2-CLEAR-ROUND-DAY-CONTRACT.md): den FÖRENKLADE bedömningen.
			Aldrig "felfri", aldrig rosett — rivningar bedöms inte ännu. ]]
		if r.ovning ~= "clearround" or r.bedomning ~= "forenklad" or not (r.forsokNr == 1 or r.forsokNr == 2) then
			return nil
		end
		if r.tid ~= nil and not ickeNeg(r.tid) then return nil end
		local tid = if r.tid ~= nil then tal(r.tid, 0) else "–"
		local rad: string? = nil
		if r.utfall == "inga_observerade_fel" then
			rad = Sprak.t("aterkoppling.clearround.inga_fel", tid)
		elseif r.utfall == "observerade_fel" then
			if not heltal(r.olydnader) then return nil end
			rad = if r.fel ~= nil and heltal(r.fel)
				then Sprak.t("aterkoppling.clearround.fel", tostring(r.olydnader), tostring(r.fel), tid)
				else Sprak.t("aterkoppling.clearround.fel_okand", tostring(r.olydnader), tid)
		elseif r.utfall == "utesluten" then
			rad = if r.orsak == "fel_vag" then Sprak.t("aterkoppling.clearround.utesluten_fel_vag")
				elseif r.orsak == "tillaten_tid" then Sprak.t("aterkoppling.clearround.utesluten_tid")
				elseif r.orsak == "olydnader" then Sprak.t("aterkoppling.clearround.utesluten_olydnader")
				else nil
		elseif r.utfall == "utesluten_ej_faststalld" then
			rad = Sprak.t("aterkoppling.clearround.utesluten_okand")
		elseif r.utfall == "ej_startad" then
			rad = Sprak.t("aterkoppling.clearround.ej_startad")
		elseif r.utfall == "ej_bedomd" then
			rad = Sprak.t("aterkoppling.clearround.ej_bedomd")
		elseif r.utfall == "avbruten" then
			rad = Sprak.t("aterkoppling.clearround.avbruten")
		end
		if not rad then return nil end
		if r.omstartMojlig == true then rad ..= " " .. Sprak.t("aterkoppling.clearround.omstart") end
		return rad .. " " .. Sprak.t("aterkoppling.clearround.forenklad")
	elseif typ == "leda" then
		if not (ickeNeg(r.meter) and ickeNeg(r.sekunder)) then return nil end
		return Sprak.t("aterkoppling.leda.klar", tal(r.meter), tal(r.sekunder, 0))
	end
	return nil
end

--[[ C1: typerna med en jämförelse av ett uppmätt avstånd (mindre är närmare),
	med sina egna ordagranna nycklar. ]]
local NARMARE = {
	volt = { narmare = "aterkoppling.volt.narmare", forra = "aterkoppling.volt.forra",
		kort = "aterkoppling.volt.narmare_kort" },
	halt = { narmare = "aterkoppling.halt.narmare", forra = "aterkoppling.halt.forra",
		kort = "aterkoppling.halt.narmare_kort" },
}

--[[ Hör resultatet till det VISADE försöket? "ja", "kontext" (ledningen:
	samma försök men en annan bunden häst/modell eller karaktär sedan det
	slutfördes) eller "nej".
	`kontext` = { typ, ritt } för ridlektionerna, { typ = "leda", userId } för
	ledningen. R1: ledningens resultat bär den kontextepok (`kontextNr`) det
	slutfördes i; bilden bär den nuvarande. Producenten räknar upp epoken vid
	varje byte av bunden MODELL (instansen — en ersättare med samma HorseId
	räknas) och av KARAKTÄR, även i complete. ]]
local function tillhor(b: any, kontext: any): string
	local r = b and b.resultat
	if type(r) ~= "table" then return "nej" end
	if kontext.typ == "leda" then
		if not (heltal(b.forsokNr) and r.forsokNr == b.forsokNr and r.userId ~= nil
			and r.userId == kontext.userId) then return "nej" end
		if not (heltal(r.kontextNr) and heltal(b.kontextNr)) then return "nej" end
		return if r.kontextNr == b.kontextNr then "ja" else "kontext"
	end
	return if b.forsokId ~= nil and r.forsokId == b.forsokId and b.rittId ~= nil and r.rittId == b.rittId
		and b.rittId == kontext.ritt and (b.typ or "volt") == kontext.typ then "ja" else "nej"
end

--[[ Texten för ett avslutat försök, eller nil när bilden inte är avslutad
	(då gäller lektionens vanliga text). ]]
function A.text(b: any, kontext: any): string?
	if type(b) ~= "table" or type(kontext) ~= "table" then return nil end
	local typ = kontext.typ
	if b.lage == "complete" then
		local hor = tillhor(b, kontext)
		if hor == "kontext" then return Sprak.t("aterkoppling.leda.annan") end
		local s = if hor == "ja" then sammanfattning(typ, b.resultat) else nil
		if not s then return Sprak.t("aterkoppling.okant") end
		--[[ C2: KORT bygger på SAMMA validerade bevis — `s` finns bara om
			bindningen och varje fält höll. Siffrorna utelämnas, statusen, nästa
			steg och galopp-/markbomsbegränsningarna står kvar (egna ord,
			ingen avkapning). ]]
		-- D2a: clear round-domen ÄR beskedet, och det förenklade förbehållet med — inget kortas bort.
		if Installning.detalj() == "kort" and typ ~= "clearround" then
			s = Sprak.t("aterkoppling." .. typ .. ".kort")
		end
		--[[ Tempocoachning: jämförelsen med förra DISTINKTA fullföljningen i
			samma ritt — bara när den är bunden till det här försöket och
			talen är ändliga. "Jämnare" bara när de avrundade procenten
			faktiskt skiljer sig åt rätt håll; annars neutralt. ]]
		local j = b.jamforelse
		if typ == "tempo" and type(j) == "table" and j.forsokId == b.forsokId and j.forraForsokId ~= b.forsokId
			and fin(j.spridning) and j.spridning >= 0 and fin(j.forraSpridning) and j.forraSpridning >= 0 then
			local nu, forr = math.floor(j.spridning * 100 + 0.5), math.floor(j.forraSpridning * 100 + 0.5)
			if Installning.detalj() == "kort" then
				if nu < forr then s ..= " " .. Sprak.t("tempocoach.jamnare_kort") end
			else
				s ..= " " .. Sprak.t(if nu < forr then "tempocoach.jamnare" else "tempocoach.forra",
					tostring(forr), tostring(nu))
			end
		end
		--[[ C1, volten och haltet (docs/CIRCLE-COMPARISON-CONTRACT.md,
			docs/HALT-COMPARISON-CONTRACT.md): ett avstånd i meter — till linjen
			respektive till X — mot förra DISTINKTA fullföljningen i samma
			lektionsobjekt, bundet till det här försöket. "Närmare" bara när de
			visade tiondelarna faktiskt minskat; annars neutralt. Aldrig orsak,
			aldrig behärskning. ]]
		local nycklar = NARMARE[typ]
		if nycklar and type(j) == "table" and j.forsokId == b.forsokId and j.forraForsokId ~= b.forsokId
			and ickeNeg(j.avvikelse) and ickeNeg(j.forraAvvikelse) then
			local nu, forr = math.floor(j.avvikelse * 10 + 0.5), math.floor(j.forraAvvikelse * 10 + 0.5)
			if Installning.detalj() == "kort" then
				if nu < forr then s ..= " " .. Sprak.t(nycklar.kort) end
			else
				s ..= " " .. Sprak.t(if nu < forr then nycklar.narmare else nycklar.forra,
					tal(forr / 10), tal(nu / 10))
			end
		end
		return s .. " " .. Sprak.t("aterkoppling." .. typ .. ".nasta")
	elseif b.lage == "timeout" then
		--[[ Neutralt: ingen gratulation, inget lånat resultat, ingen påhittad
			orsak — serverns egen framstegssiffra och ett konkret tips. ]]
		if Installning.detalj() == "kort" then
			return Sprak.t("aterkoppling.timeout_kort") .. " " .. Sprak.t("aterkoppling." .. typ .. ".igen")
		end
		local procent = if fin(b.progress) then math.clamp(math.floor(b.progress), 0, 99) else 0
		return Sprak.t("aterkoppling.timeout", tostring(procent)) .. " "
			.. Sprak.t("aterkoppling." .. typ .. ".igen")
	end
	return nil
end

return A
