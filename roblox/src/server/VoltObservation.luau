--!strict
--[[ VOLTOBSERVATIONEN — serverns platsbundna referensmätning av en volt
	(#264 INFRA-VOLT1). En B3-grund före instruktörens konsumenter.

	Övnings-id `storvolt`, men en EGEN version: `server-referens-1`. Den
	äldre klient- och webbdefinitionen (`RidKanon.INSPELNING.OVNING.storvolt`,
	version 1, och `Lektion.kvalitet`) betyder oförändrat vad den betydde;
	inga gamla inspelningar tolkas om.

	── REFERENSEN (uttryckligt spel- och mätantagande) ───────────────
	  · Centrum: dressyrlayoutens mitt i ridhusets platsram (`Ridhusplats`,
	    via ridplatsbildens `dressyrMitt`). Inte ett officiellt program och
	    ingen allmän regel att alla volter ska ridas där.
	  · Radie: `RidKanon.UGNETA.KVALITET.VOLT_RADIE` (10), tolkad som METER —
	    20 m-volten. RidKanon anger ingen enhet; webbens skala är meter.
	  · Mätningen jämför mot referensen PÅ SIN PLATS. Ingen cirkel anpassas
	    till spelarens egen väg: en korrekt stor cirkel på fel plats ger en
	    annan radialavvikelse.

	── INDATA ─────────────────────────────────────────────────────────
	Bara ridplatsbilden (`RidPlatsObservation`) i samma uthållighetssteg:
	ett giltigt sammanhängande segment i samma ritt och ram, i meter. Ingen
	egen sampling, ingen nedsamplad rutt, ingen StateSync, ingen inspelning.

	── MÅTTEN, per avsnitt, i meter och radianer i planet (u, v) ─────
	  · `tid`, `stracka`: observerad tid och planstråcka i avsnittet.
	  · Radialavvikelse: för varje segment |r − R| i segmentets MITTPUNKT
	    (r = avståndet till referenscentrum). Viktning: sträckviktad —
	    `medelAvvikelse` = Σ |r − R| · längd / Σ längd; `rmsAvvikelse`
	    likaså kvadratiskt; `maxAvvikelse` största enskilda.
	  · Vinkel: per segment den SIGNERADE vinkeln kring centrum,
	    atan2(a × b, a · b), alltså i (−π, π] utan omslagsfel. Positiv =
	    från +u mot +v. `netto` = summan; `motriktning` = summan av belopp i
	    motsatt riktning till nettot (hur mycket som reds fram och tillbaka).
	  · Varv: `varv` = heltal av |netto| / 2π. Ett varv räknas bara på den
	    signerade nettovinkeln — fram och tillbaka tar ut sig självt och kan
	    aldrig bli ett helt varv. Flyttalsmarginal 1e-6 rad.
	  · Återkomst: `aterkomst` = avståndet (m) mellan det aktuella läget och
	    avsnittets startläge.
	  · Obestämd vinkel: ett segment vars ändpunkter, eller närmaste punkt,
	    ligger närmare centrum än `R_MIN` (1,0 m) ger ingen vinkel och
	    räknas som `obestamda`. Stillastående (längd 0) utanför R_MIN ger
	    en OBSERVERAD vinkel 0.

	── OBRUTEN VINKELEVIDENS (R1) ────────────────────────────────────
	Okänd vinkel är inte noll vinkel. Nettot och varven gäller därför bara
	en OBRUTEN kedja av segment med bestämd vinkel: ett segment med
	obestämd vinkel avslutar avsnittet (`obestamd_vinkel`). Obestämda
	segment i följd bildar ett eget avsnitt med underlaget "okant" och
	utan vinkel-, varv- eller radialmått, och det första bestämda
	segmentet efter dem avslutar det (`vinkel_bestamd_igen`) och startar
	en ny kedja från noll. Ett avsnitt blandar alltså aldrig bestämda och
	obestämda segment, och ingen andel eller procentgräns avgör varvet.
	Återhämtning kräver ny giltig evidens: ett helt varv måste ridas
	obrutet efter centrum.

	── AVSNITT OCH GILTIGHET ──────────────────────────────────────────
	Ett avsnitt pågår så länge varje steg är ett giltigt segment i samma
	ram och med samma referens. Varje annan status — baslinje, brott,
	ram_ny, ingen_plats, stängd ritt — eller ett byte av ram eller
	referens avslutar avsnittet med sitt skäl, och nästa segment börjar ett
	nytt. Inget bryggas.

	Underlag per avsnitt: "okant" (ett avsnitt av obestämda segment),
	"otillrackligt" (under MIN_TID s, MIN_SEGMENT segment eller
	MIN_STRACKA m), annars "tillrackligt". Bara vid "tillrackligt" finns
	avvikelse, vinkel, riktning, varv och återkomst i bilden; annars är de
	nil. Saknat underlag är okänt — varken perfekt eller dålig ridning.
	Tid, sträcka, segment och obestämda redovisas alltid. Inget här är poäng, godkänd övning eller belöning.

	── MINNE ─────────────────────────────────────────────────────────
	Per öppen ritt: det pågående avsnittet och högst MAX_AVSNITT avslutade.
	Avslutade ritter: en ring om MAX_AVSLUTADE. Frysta bilder. ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RidKanon = require(ReplicatedStorage.HorseCore.RidKanon)

local VoltObservation = {}

VoltObservation.OVNING = "storvolt"
VoltObservation.VERSION = "server-referens-1"
VoltObservation.RADIE = RidKanon.UGNETA.KVALITET.VOLT_RADIE
VoltObservation.R_MIN = 1.0
VoltObservation.MIN_TID = 1.0
VoltObservation.MIN_SEGMENT = 4
VoltObservation.MIN_STRACKA = 2.0
VoltObservation.TOL_VARV = 1e-6
VoltObservation.MAX_AVSNITT = 8
VoltObservation.MAX_AVSLUTADE = 32

type Avsnitt = {
	nr: number, ramId: number, cu: number, cv: number,
	tid: number, stracka: number,
	segment: number, obestamda: number, obestamt: boolean,
	viktAbs: number, viktKvad: number, maxAvvikelse: number,
	netto: number, positiv: number, negativ: number,
	startU: number, startV: number, sistU: number, sistV: number,
	slut: string?,
}
type Ritt = {
	rittId: string, hastId: string, userId: number, oppen: boolean,
	pagar: Avsnitt?, avslutade: { Avsnitt }, nr: number, bild: any,
	sistaIn: any, satt: string?, sistaT: number?,
}

local ritter: { [string]: Ritt } = {}
local avslutadeRitter: { string } = {}

local function andligt(v: any): boolean
	return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge
end

local function sammanfatta(a: Avsnitt): any
	local R = VoltObservation.RADIE
	local skal = {}
	local underlag = "tillrackligt"
	if a.obestamt then
		underlag = "okant"
		table.insert(skal, "for_nara_centrum")
	elseif a.tid < VoltObservation.MIN_TID or a.segment < VoltObservation.MIN_SEGMENT then
		underlag = "otillrackligt"
		table.insert(skal, "for_kort")
	elseif a.stracka < VoltObservation.MIN_STRACKA then
		underlag = "otillrackligt"
		table.insert(skal, "for_lite_rorelse")
	end
	--[[ Okänt är okänt: utan tillräckligt underlag finns inga mått som en
		konsument kan läsa som noll avvikelse eller noll varv. ]]
	local ok = underlag == "tillrackligt"
	local riktning = if a.netto > 0 then "positiv" elseif a.netto < 0 then "negativ" else "ingen"
	local motriktning = if a.netto >= 0 then a.negativ else a.positiv
	local varv = math.floor((math.abs(a.netto) + VoltObservation.TOL_VARV) / (2 * math.pi))
	return table.freeze({
		nr = a.nr, ramId = a.ramId,
		referens = table.freeze({ u = a.cu, v = a.cv, radie = R }),
		tid = a.tid, stracka = a.stracka, segment = a.segment, obestamda = a.obestamda,
		medelAvvikelse = if ok then a.viktAbs / a.stracka else nil,
		rmsAvvikelse = if ok then math.sqrt(a.viktKvad / a.stracka) else nil,
		maxAvvikelse = if ok then a.maxAvvikelse else nil,
		netto = if ok then a.netto else nil,
		riktning = if ok then riktning else nil,
		motriktning = if ok then motriktning else nil,
		varv = if ok then varv else nil,
		aterkomst = if ok then math.sqrt((a.sistU - a.startU) ^ 2 + (a.sistV - a.startV) ^ 2) else nil,
		underlag = underlag, skal = table.freeze(skal),
		status = if a.slut then "avslutat" else "pagar", slut = a.slut,
	})
end

local function avsluta(r: Ritt, skal: string)
	local a = r.pagar
	if not a then return end
	a.slut = skal
	table.insert(r.avslutade, a)
	while #r.avslutade > VoltObservation.MAX_AVSNITT do table.remove(r.avslutade, 1) end
	r.pagar = nil
end

local function bygg(r: Ritt, status: string)
	local av = {}
	for _, a in ipairs(r.avslutade) do table.insert(av, sammanfatta(a)) end
	r.bild = table.freeze({
		ovning = VoltObservation.OVNING, version = VoltObservation.VERSION,
		rittId = r.rittId, hastId = r.hastId, userId = r.userId,
		status = status, satt = r.satt,
		enheter = table.freeze({ langd = "m", vinkel = "rad", tid = "s" }),
		pagar = if r.pagar then sammanfatta(r.pagar) else nil,
		avslutade = table.freeze(av),
	})
end

function VoltObservation.starta(rittId: string, hastId: string, userId: number): boolean
	if type(rittId) ~= "string" or rittId == "" or ritter[rittId] then return false end
	local r: Ritt = {
		rittId = rittId, hastId = tostring(hastId), userId = tonumber(userId) or 0,
		oppen = true, pagar = nil, avslutade = {}, nr = 0, bild = nil, sistaIn = nil,
	}
	ritter[rittId] = r
	bygg(r, "ingen_observation")
	return true
end

--[[ Ett steg: ridplatsbilden från samma uthållighetssteg. ]]
function VoltObservation.sampla(rittId: string?, plats: any): boolean
	local r = rittId and ritter[rittId]
	if not r or not r.oppen then return false end
	if type(plats) ~= "table" then return false end
	--[[ Samma frysta ridplatsbild två gånger (t.ex. om ridplatsens steg
		kastade och den förra bilden låg kvar) får inte räknas dubbelt. ]]
	if plats == r.sistaIn then return false end
	r.sistaIn = plats
	if plats.rittId ~= r.rittId then return false end
	--[[ Segmentets tid är ritt-tiden sedan FÖREGÅENDE bild (dess `fran`),
		vilken status den bilden än hade — så räknas också avsnittets
		första segment. ]]
	local tFore = r.sistaT
	r.sistaT = if andligt(plats.t) then plats.t else nil

	local seg = plats.segment
	local mitt = plats.dressyrMitt
	local ramId = plats.ramId
	if plats.status ~= "segment" or type(seg) ~= "table" or type(mitt) ~= "table" or type(ramId) ~= "number" then
		local st = tostring(plats.status or "okant")
		avsluta(r, if type(plats.skal) == "string" then st .. ":" .. plats.skal else st)
		bygg(r, st)
		return true
	end

	local cu, cv = mitt.u, mitt.v
	local a = r.pagar
	if a and (a.ramId ~= ramId or a.cu ~= cu or a.cv ~= cv) then
		avsluta(r, "ram_eller_referens_bytt")
		a = nil
	end
	local fu, fv, tu, tv = seg.fran.u, seg.fran.v, seg.till.u, seg.till.v
	if not (andligt(fu) and andligt(fv) and andligt(tu) and andligt(tv) and andligt(cu) and andligt(cv)) then
		avsluta(r, "ogiltigt_segment")
		bygg(r, "ogiltigt_segment")
		return true
	end
	--[[ Vinkeln kring centrum avgörs FÖRE avsnittet: obestämd nära
		centrum — ändpunkter eller segmentets närmaste punkt innanför R_MIN. ]]
	local du, dv = tu - fu, tv - fv
	local langd = math.sqrt(du * du + dv * dv)
	local au, avc = fu - cu, fv - cv
	local bu, bvc = tu - cu, tv - cv
	local narmast = math.min(math.sqrt(au * au + avc * avc), math.sqrt(bu * bu + bvc * bvc))
	if langd > 0 then
		local k = math.clamp(-(au * du + avc * dv) / (langd * langd), 0, 1)
		local nu, nv = au + du * k, avc + dv * k
		narmast = math.min(narmast, math.sqrt(nu * nu + nv * nv))
	end
	local obestamt = narmast < VoltObservation.R_MIN
	--[[ R1: kedjan bryts vid varje växling mellan bestämd och obestämd
		vinkel, så att ett oobserverat stycke aldrig binder ihop två bågar. ]]
	if a and a.obestamt ~= obestamt then
		avsluta(r, if obestamt then "obestamd_vinkel" else "vinkel_bestamd_igen")
		a = nil
	end
	if not a then
		r.nr += 1
		a = {
			nr = r.nr, ramId = ramId, cu = cu, cv = cv,
			tid = 0, stracka = 0,
			segment = 0, obestamda = 0, obestamt = obestamt,
			viktAbs = 0, viktKvad = 0, maxAvvikelse = 0,
			netto = 0, positiv = 0, negativ = 0,
			startU = fu, startV = fv, sistU = fu, sistV = fv,
			slut = nil,
		}
		r.pagar = a
	end
	local av = a :: Avsnitt

	--[[ Tid ur ridobservationens ritt-tid. ]]
	if tFore and r.sistaT and r.sistaT > tFore then
		av.tid += r.sistaT - tFore
	end
	av.segment += 1

	av.stracka += langd

	--[[ Radialavvikelse i segmentets mittpunkt, sträckviktad. ]]
	local mu, mv = (fu + tu) / 2 - cu, (fv + tv) / 2 - cv
	local avv = math.abs(math.sqrt(mu * mu + mv * mv) - VoltObservation.RADIE)
	av.viktAbs += avv * langd
	av.viktKvad += avv * avv * langd
	if avv > av.maxAvvikelse then av.maxAvvikelse = avv end

	--[[ Ett stillastående segment (a = b) behöver ingen egen gren:
		a × b = 0 och a · b = |a|² > 0 ger atan2 exakt 0. ]]
	if obestamt then
		av.obestamda += 1
	else
		local d = math.atan2(au * bvc - avc * bu, au * bu + avc * bvc)
		av.netto += d
		if d > 0 then av.positiv += d else av.negativ -= d end
	end
	av.sistU, av.sistV = tu, tv

	bygg(r, "segment")
	return true
end

function VoltObservation.avsluta(rittId: string?, satt: string): boolean
	local r = rittId and ritter[rittId]
	if not r or not r.oppen then return false end
	avsluta(r, "ritten_slut")
	r.oppen = false
	r.satt = satt
	bygg(r, "stangd")
	table.insert(avslutadeRitter, r.rittId)
	while #avslutadeRitter > VoltObservation.MAX_AVSLUTADE do
		ritter[table.remove(avslutadeRitter, 1)] = nil
	end
	return true
end

function VoltObservation.ogonblick(rittId: string?): any
	local r = rittId and ritter[rittId]
	return if r then r.bild else nil
end

function VoltObservation._antalRitterForProv(): number
	local n = 0
	for _ in pairs(ritter) do n += 1 end
	return n
end

return VoltObservation
