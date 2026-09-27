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

local A = {}

local function tal(x: any, dec: number?): string
	if type(x) ~= "number" or x ~= x or x == math.huge or x == -math.huge then return "?" end
	local s = string.format("%." .. tostring(dec or 1) .. "f", x)
	if Sprak.eget() == "sv" then s = string.gsub(s, "%.", ",") end
	return s
end

local function antal(t: any): number
	return if type(t) == "table" then #t else 0
end

--[[ Sammanfattningen per typ: bara fält som producenten faktiskt fryser.
	Returnerar nil om ett nödvändigt fält saknas (då blir texten ärlig). ]]
local function sammanfattning(typ: string, r: any): string?
	if typ == "volt" then
		local a = r.avsnitt
		if type(a) ~= "table" or type(a.varv) ~= "number" or type(a.referens) ~= "table" then return nil end
		return Sprak.t("aterkoppling.volt.klar", tostring(a.varv), tal(a.referens.radie, 0),
			tal(a.medelAvvikelse), tal(a.tid, 0))
	elseif typ == "halt" then
		if type(r.skrittMeter) ~= "number" or type(r.haltSekunder) ~= "number" then return nil end
		return Sprak.t("aterkoppling.halt.klar", tal(r.skrittMeter), tal(r.haltSekunder))
	elseif typ == "overgang" then
		if type(r.travMeter) ~= "number" or type(r.skrittMeter) ~= "number" then return nil end
		return Sprak.t("aterkoppling.overgang.klar", tal(r.travMeter), tal(r.skrittMeter))
	elseif typ == "serpentin" then
		if type(r.meter) ~= "number" then return nil end
		return Sprak.t("aterkoppling.serpentin.klar", tal(r.meter, 0), tostring(antal(r.korsningar)))
	elseif typ == "tempo" then
		if type(r.meter) ~= "number" or type(r.medelFart) ~= "number" then return nil end
		return Sprak.t("aterkoppling.tempo.klar", tal(r.meter), tal(r.sekunder), tal(r.medelFart, 2),
			tal((r.spridning or 0) * 100, 0))
	elseif typ == "vag_mitt" or typ == "vag_diag" then
		if type(r.meter) ~= "number" or type(r.langd) ~= "number" then return nil end
		return Sprak.t("aterkoppling." .. typ .. ".klar", tal(r.meter), tal(r.langd))
	elseif typ == "halvvolt" then
		if type(r.meter) ~= "number" then return nil end
		local text = Sprak.t("aterkoppling.halvvolt.klar", tal(r.meter), tostring(antal(r.skarvar)))
		if type(r.skuld) == "number" and r.skuld > 0.05 then
			text ..= " " .. Sprak.t("aterkoppling.halvvolt.skuld", tal(r.skuld))
		end
		return text
	elseif typ == "galopp" then
		if type(r.travMeter) ~= "number" or type(r.galoppMeter) ~= "number" then return nil end
		return Sprak.t("aterkoppling.galopp.klar", tal(r.travMeter), tal(r.galoppMeter))
	elseif typ == "markbom" then
		if type(r.inridningM) ~= "number" or type(r.utridningM) ~= "number" then return nil end
		return Sprak.t("aterkoppling.markbom.klar", tal(r.inridningM), tal(r.utridningM))
	elseif typ == "leda" then
		if type(r.meter) ~= "number" or type(r.sekunder) ~= "number" then return nil end
		return Sprak.t("aterkoppling.leda.klar", tal(r.meter), tal(r.sekunder, 0))
	end
	return nil
end

--[[ Hör resultatet till det VISADE försöket?
	`kontext` = { typ, ritt } för ridlektionerna, { typ = "leda", userId } för
	ledningen. ]]
local function tillhor(b: any, kontext: any): boolean
	local r = b and b.resultat
	if type(r) ~= "table" then return false end
	if kontext.typ == "leda" then
		return type(b.forsokNr) == "number" and r.forsokNr == b.forsokNr and r.userId == kontext.userId
	end
	return b.forsokId ~= nil and r.forsokId == b.forsokId and r.rittId == b.rittId
		and b.rittId == kontext.ritt and (b.typ or "volt") == kontext.typ
end

--[[ Texten för ett avslutat försök, eller nil när bilden inte är avslutad
	(då gäller lektionens vanliga text). ]]
function A.text(b: any, kontext: any): string?
	if type(b) ~= "table" or type(kontext) ~= "table" then return nil end
	local typ = kontext.typ
	if b.lage == "complete" then
		local s = if tillhor(b, kontext) then sammanfattning(typ, b.resultat) else nil
		if not s then return Sprak.t("aterkoppling.okant") end
		return s .. " " .. Sprak.t("aterkoppling." .. typ .. ".nasta")
	elseif b.lage == "timeout" then
		--[[ Neutralt: ingen gratulation, inget lånat resultat, ingen påhittad
			orsak — serverns egen framstegssiffra och ett konkret tips. ]]
		local procent = if type(b.progress) == "number" then math.clamp(math.floor(b.progress), 0, 99) else 0
		return Sprak.t("aterkoppling.timeout", tostring(procent)) .. " "
			.. Sprak.t("aterkoppling." .. typ .. ".igen")
	end
	return nil
end

return A
