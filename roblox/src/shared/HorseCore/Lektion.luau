--!strict
--[[
	LEKTIONEN — G02-C:s försökslifecycle på Roblox.

	Det här är modulen som saknades. Roblox hade Ugnetas bedömnings-
	KONTRAKT (HorseCore/Ugneta) och en HUD (UgnetaController), men inget
	som faktiskt körde en lektion: ingen mätning per bildruta, inget
	försök 1 → 2, ingen som avgjorde när kortet skulle upp. Provet kunde
	därför bara visa att HUD:en gick att anropa — inte att en spelare som
	rider en ritt får undervisningen. Det är precis läktarfelet (#114):
	hjälpfunktionen grön, produktionskedjan oansluten.

	Modulen är REN: inga Instances, ingen RunService, inga globala
	tillstånd. Den tar telemetri in och ger händelser ut, vilket är just
	det som gör att bänken kan spela upp en hel ritt.

	INGEN EGEN SANNING. Övningarnas ordning och text, dimensionerna,
	live-ordförrådet, trösklarna och kvalitetsformelns tal läses ur
	RidKanon.UGNETA, som genereras ur webbens src/larare.js. Ändrar
	webben en tröskel följer Roblox med i samma commit.
]]

local RidKanon = require(script.Parent.RidKanon)
local Ugneta = require(script.Parent.Ugneta)

local Lektion = {}

local UG = RidKanon.UGNETA
local KV = UG.KVALITET

Lektion.ORDNING = UG.ORDNING
Lektion.OVNINGAR = UG.OVNINGAR

--[[ VAD SOM INTE GÅR ATT MÄTA HÄR — deklarerat, inte tigit ihjäl.

	Webbens `rytm` och halva `linje` kommer ur utbildningsskalan
	(`G.ride.skala.takt` / `.rakriktning`), en modell som bara finns i
	src/model.js. Roblox har ingen utbildningsskala. Två val fanns:
	räkna fram något eget som SER ut som takt, eller säga att den inte
	är mätt. Det första hade varit en påhittad siffra i en pedagogik som
	påstår sig komma ur riktig telemetri, så det andra gäller.

	En omätt dimension är `nil` — inte 0. Skillnaden är hela poängen:
	en nolla hade gjort rytmen till den svagaste dimensionen i varje
	20 m volt, och Ugneta hade tjatat om takten hon aldrig sett. ]]
Lektion.SAKNAS = { "rytm" }

--[[ DEKLARERADE SKILLNADER mot webben. Står som data så att en spec kan
	kräva att listan stämmer — en skillnad som växer fram i tysthet är
	en parallell sanning, en som står uppräknad är ett beslut. ]]
Lektion.SKILLNAD = {
	--[[ Webben väljer live-cue ur passets fokus (LARARE.fokus), som i sin
	     tur väljs ur ryttarens färdigheter (`fard()`). Roblox har ingen
	     ryttarmodell ännu, så cue:n väljs ur den svagaste MÄTTA
	     dimensionen i övningens kontrakt. Samma ordförråd
	     (RidKanon.UGNETA.LIVE), samma koppling (DIM_CUE), annan ingång. ]]
	"live-cue väljs ur svagaste mätta dimension, inte ur passets fokus",
	--[[ Rytmen, se SAKNAS. ]]
	"rytm är inte mätt på Roblox och räknas inte in i bedömningen",
}

local function klamp(v: number?): number
	if v == nil or v ~= v then return 0 end
	if v < 0 then return 0 end
	if v > 1 then return 1 end
	return v
end

--[[ KVALITETEN, ur telemetrin och ingenting annat.

	Samma formel som webbens `ugnetaKvalitet` med samma tal, hämtade ur
	RidKanon.UGNETA.KVALITET. `tm` är exakt det HorseCore/Telemetri.las
	returnerar — modulen läser inte hästen, den läser mätningen. ]]
function Lektion.kvalitet(tm: { [string]: any }): { [string]: number? }
	local radie: number
	local r = tm.svangradie
	if type(r) == "number" and r == r and r ~= math.huge then
		radie = klamp(1 - math.abs(r - KV.VOLT_RADIE) / KV.VOLT_SPANN)
	else
		--[[ Rak linje: ingen radie att bedöma. Webben faller tillbaka på
		     rakriktningen ur utbildningsskalan; den finns inte här, så
		     linjen är omätt i det ögonblicket i stället för påhittad. ]]
		radie = -1
	end
	local svarstid = tonumber(tm.svarstid) or 0
	local etab = tonumber(tm.etableringstid) or 0
	local svar = if svarstid > 0 then klamp(1 - svarstid / KV.SVARSTID_TAK) else KV.OMATT
	local etablering = if etab > 0 then klamp(1 - etab / KV.ETABLERING_TAK) else KV.OMATT
	local parad = klamp(tonumber(tm.paradKvalitet) or 0)
	local fokus = klamp(tonumber(tm.fokus) or 0)
	local lugn = 1 - klamp(tonumber(tm.spanning) or 0)
	local fart = tonumber(tm.fart) or 0
	local onskad = tonumber(tm.onskadFart) or fart
	return {
		--[[ Bara radietermen. Webbens andra halva (LINJE_RAK ×
		     rakriktning) har ingen källa här; att skala upp radien till
		     1,0 hade gett en bättre linje än den som faktiskt mätts. ]]
		linje = if radie >= 0 then klamp(radie) else nil,
		rytm = nil,                       -- se Lektion.SAKNAS
		balans = klamp(tonumber(tm.balans) or 0),
		mjukhet = klamp(tonumber(tm.mjukhet) or 0),
		timing = klamp(KV.TIMING_SVAR * svar + KV.TIMING_ETABLERING * etablering
			+ KV.TIMING_PARAD * parad),
		respons = klamp(KV.RESPONS_FOKUS * fokus + KV.RESPONS_LUGN * lugn
			+ KV.RESPONS_SVAR * svar),
		tempo = if onskad > KV.TEMPO_GOLV
			then klamp(1 - math.abs(fart - onskad) / math.max(onskad, KV.TEMPO_NAMNARE))
			else 1,
	}
end

--[[ ── Passet ──────────────────────────────────────────────────────
	Sex övningar i kanonens ordning, två försök på var och en. Samma
	lifecycle som webbens `stegaLektion`: betyget hör till sista
	försöket, och ett nytt försök NOLLSTÄLLER mätningen explicit i stället
	för att patchas i nästa bildruta. ]]
export type Prov = { n: number, sum: { [string]: number }, matt: { [string]: number } }
export type Pass = {
	ix: number,
	forsokNr: number,
	tid: number,
	prov: Prov,
	historik: { [string]: { { [string]: number } } },
	klar: boolean,
}

--[[ Hur länge ett försök rids innan det bedöms. Webbens moment har en
     egen tid per övning; Roblox har ingen momentbank ännu, så längden
     är EN siffra här och deklareras som spelbeslut, inte som mätning. ]]
Lektion.FORSOK_SEK = 22
Lektion.MIN_MATNINGAR = 2

local function tomtProv(): Prov
	return { n = 0, sum = {}, matt = {} }
end

function Lektion.nyttPass(): Pass
	return { ix = 1, forsokNr = 1, tid = 0, prov = tomtProv(),
		historik = {}, klar = false }
end

function Lektion.ovningId(pass: Pass): string?
	return Lektion.ORDNING[pass.ix]
end

function Lektion.ovning(pass: Pass): { rubrik: string, punkter: { string } }?
	local id = Lektion.ovningId(pass)
	if not id then return nil end
	return Lektion.OVNINGAR[id]
end

--[[ Ett prov per bildruta. Bara mätta dimensioner räknas — `matt`
	håller reda på hur många prov varje dimension faktiskt fått, så en
	dimension som var omätt halva försöket inte får ett medelvärde
	utspätt med nollor. ]]
function Lektion.matning(pass: Pass, tm: { [string]: any })
	local q = Lektion.kvalitet(tm)
	local p = pass.prov
	p.n += 1
	for k, v in q do
		if v ~= nil then
			p.sum[k] = (p.sum[k] or 0) + v
			p.matt[k] = (p.matt[k] or 0) + 1
		end
	end
end

function Lektion.medel(pass: Pass): { [string]: number }
	local ut = {}
	for k, s in pass.prov.sum do
		local n = pass.prov.matt[k] or 0
		if n > 0 then ut[k] = s / n end
	end
	return ut
end

--[[ Avsluta försöket och lämna underlaget till Ugneta. `fore` är nil på
	första försöket — det är den skillnaden hela UX-variant 3 hänger på. ]]
export type Handelse = {
	ovningId: string,
	nu: { [string]: number },
	fore: { [string]: number }?,
	forsokNr: number,
	sista: boolean,
}

function Lektion.avslutaForsok(pass: Pass): Handelse?
	local id = Lektion.ovningId(pass)
	if not id then return nil end
	if pass.prov.n < Lektion.MIN_MATNINGAR then return nil end
	local nu = Lektion.medel(pass)
	local lista = pass.historik[id]
	if not lista then lista = {}; pass.historik[id] = lista end
	local fore = lista[#lista]
	table.insert(lista, nu)
	local sista = pass.forsokNr >= 2
	return { ovningId = id, nu = nu, fore = fore, forsokNr = pass.forsokNr,
		sista = sista }
end

--[[ Vidare: nästa försök på samma övning, eller nästa övning. Mätningen
	byts HÄR, inte i nästa bildruta. ]]
function Lektion.vidare(pass: Pass)
	if pass.forsokNr < 2 then
		pass.forsokNr += 1
	else
		pass.ix += 1
		pass.forsokNr = 1
		if pass.ix > #Lektion.ORDNING then pass.klar = true end
	end
	pass.tid = 0
	pass.prov = tomtProv()
end

--[[ ── Live-cue ────────────────────────────────────────────────────
	Några ord, inte ett kort. Väljs ur den svagaste MÄTTA dimensionen i
	övningens kontrakt — se Lektion.SKILLNAD för varför ingången är en
	annan än webbens. Ordförrådet är kanonens. ]]
function Lektion.liveCue(pass: Pass, q: { [string]: number? }): (string, boolean)
	local id = Lektion.ovningId(pass)
	if not id then return "", false end
	local svag, svagV = nil, math.huge
	for _, k in Ugneta.dimensionerFor(id) do
		local v = q[k]
		if v ~= nil and v < svagV then svag, svagV = k, v end
	end
	if not svag then return "", false end
	local cue = UG.DIM_CUE[svag]
	if not cue then return "", false end
	local bra = svagV >= KV.SVAG
	local rad = UG.LIVE[cue]
	if not rad then return "", false end
	return (if bra then rad.bra else rad.fel), bra
end

--[[ ── Platsen vid sargen ──────────────────────────────────────────
	Uttryckt i BANANS egna mått, precis som webbens `ugnetaPlats()`:
	`u` är andel av bredden, `bortomC` meter bortom dressyrlayoutens
	C-linje. Den som bygger gestalten löser upp den mot den byggda
	banan — ingen andra uppfattning om var sargen går. ]]
Lektion.PLATS = UG.PLATS

return Lektion
