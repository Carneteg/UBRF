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

--[[ OKÄNT ÄR INTE NOLL (senior review av b303530, punkt 2).

	Förut lästes varje fält som `tonumber(x) or 0`. Följden var att ett
	SAKNAT mätvärde blev en giltig siffra: en telemetri som bara sa
	`{uppsutten = true}` gav balans 0 och mjukhet 0 — alltså "dålig
	ritt" — medan `lugn = 1 - klamp(spänning)` blev 1 och tempo blev 1,
	alltså beröm. Båda är påhitt om en ritt som aldrig mättes.

	`tal` skiljer de två fallen: ett verkligt uppmätt 0 är en siffra,
	ett saknat eller ogiltigt fält är `nil`. NaN och oändligheter räknas
	som saknade — de är mätfel, inte mätvärden. ]]
local function tal(v: any): number?
	local n = tonumber(v)
	if n == nil then return nil end
	if n ~= n then return nil end                 -- NaN
	if n == math.huge or n == -math.huge then return nil end
	return n
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
	--[[ Delkomponenterna. `mattes` räknar hur många av dem som faktiskt
	     kom ur telemetrin — en sammansatt dimension där INGEN del är mätt
	     får inte bli en siffra bara för att de neutrala fallbacksen råkar
	     summera till något. ]]
	local svarstidV, etabV = tal(tm.svarstid), tal(tm.etableringstid)
	local paradV, fokusV, spanningV = tal(tm.paradKvalitet), tal(tm.fokus), tal(tm.spanning)
	local fart, onskad = tal(tm.fart), tal(tm.onskadFart)

	--[[ KV.OMATT är den deklarerade neutralen för en delkomponent som
	     inte mätts. Den behålls — formeln är verifierad — men den får
	     inte ensam bära en dimension. ]]
	local svar = if svarstidV ~= nil and svarstidV > 0
		then klamp(1 - svarstidV / KV.SVARSTID_TAK) else KV.OMATT
	local etablering = if etabV ~= nil and etabV > 0
		then klamp(1 - etabV / KV.ETABLERING_TAK) else KV.OMATT
	local parad = if paradV ~= nil then klamp(paradV) else KV.OMATT
	local fokus = if fokusV ~= nil then klamp(fokusV) else KV.OMATT
	local lugn = if spanningV ~= nil then 1 - klamp(spanningV) else KV.OMATT

	local timingMatt = (svarstidV ~= nil and svarstidV > 0)
		or (etabV ~= nil and etabV > 0) or paradV ~= nil
	local responsMatt = fokusV ~= nil or spanningV ~= nil
		or (svarstidV ~= nil and svarstidV > 0)

	--[[ TEMPO kräver att den önskade farten faktiskt är mätt. Förut föll
	     `onskad` tillbaka på `fart`, och då blev avvikelsen noll och
	     tempot 1,0 — full pott ur ingenting. Saknas önskad fart är
	     tempot okänt. Är den mätt men under golvet finns inget tempokrav
	     att missa, och 1,0 är då ett riktigt svar, inte ett påhitt. ]]
	local tempo: number? = nil
	if onskad ~= nil then
		if onskad <= KV.TEMPO_GOLV then
			tempo = 1
		elseif fart ~= nil then
			tempo = klamp(1 - math.abs(fart - onskad) / math.max(onskad, KV.TEMPO_NAMNARE))
		end
	end

	local balansV, mjukhetV = tal(tm.balans), tal(tm.mjukhet)
	return {
		--[[ Bara radietermen. Webbens andra halva (LINJE_RAK ×
		     rakriktning) har ingen källa här; att skala upp radien till
		     1,0 hade gett en bättre linje än den som faktiskt mätts. ]]
		linje = if radie >= 0 then klamp(radie) else nil,
		rytm = nil,                       -- se Lektion.SAKNAS
		balans = if balansV ~= nil then klamp(balansV) else nil,
		mjukhet = if mjukhetV ~= nil then klamp(mjukhetV) else nil,
		--[[ Formlerna är oförändrade. Det enda som tillkommit är kravet
		     att minst en delkomponent verkligen mättes. ]]
		timing = if timingMatt
			then klamp(KV.TIMING_SVAR * svar + KV.TIMING_ETABLERING * etablering
				+ KV.TIMING_PARAD * parad)
			else nil,
		respons = if responsMatt
			then klamp(KV.RESPONS_FOKUS * fokus + KV.RESPONS_LUGN * lugn
				+ KV.RESPONS_SVAR * svar)
			else nil,
		tempo = tempo,
	}
end

--[[ ── Passet ──────────────────────────────────────────────────────
	Sex övningar i kanonens ordning, två försök på var och en. Samma
	lifecycle som webbens `stegaLektion`: betyget hör till sista
	försöket, och ett nytt försök NOLLSTÄLLER mätningen explicit i stället
	för att patchas i nästa bildruta. ]]
export type Prov = { n: number, sum: { [string]: number }, matt: { [string]: number },
	sek: { [string]: number } }
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

--[[ HUR MYCKET UNDERLAG SOM KRÄVS INNAN NÅGOT BEDÖMS.

	Förut räckte två bildrutor för hela försöket, och `prov.n` räknades
	upp för varje uppsutten bildruta oavsett om något faktiskt mättes.
	Två saker föll ut av det: ett försök kunde bedömas på underlag som
	inte fanns, och täckningen berodde på bildfrekvensen — 120 fps gav
	dubbelt så många "mätningar" som 60 fps på samma ritt.

	Kraven ställs därför per dimension och i SEKUNDER, inte i bildrutor.
	Antalet prov behålls som ett golv mot enstaka utstickare. ]]
Lektion.MIN_MATNINGAR = 2
Lektion.MIN_DIM_SEK = 1.0

local function tomtProv(): Prov
	return { n = 0, sum = {}, matt = {}, sek = {} }
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
--[[ Ett prov per bildruta. `dt` gör täckningen bildfrekvensoberoende:
	en dimension räknas i uppmätta SEKUNDER, inte i hur ofta loopen råkade
	titta. Saknas `dt` bidrar provet med antal men ingen tid, och kan då
	aldrig ensamt nå tidskravet — det är avsiktligt. ]]
function Lektion.matning(pass: Pass, tm: { [string]: any }, dt: number?)
	local q = Lektion.kvalitet(tm)
	local p = pass.prov
	local steg = tal(dt)
	if steg == nil or steg < 0 then steg = 0 end
	p.n += 1
	for k, v in q do
		if v ~= nil then
			p.sum[k] = (p.sum[k] or 0) + v
			p.matt[k] = (p.matt[k] or 0) + 1
			p.sek[k] = (p.sek[k] or 0) + steg
		end
	end
end

--[[ Medelvärdet för de dimensioner som har TILLRÄCKLIGT underlag. En
	dimension som bara snuddades vid under en bråkdel av försöket lämnas
	utanför i stället för att bäras fram som ett omdöme. ]]
function Lektion.medel(pass: Pass): { [string]: number }
	local ut = {}
	for k, s in pass.prov.sum do
		local n = pass.prov.matt[k] or 0
		local sek = pass.prov.sek[k] or 0
		if n >= Lektion.MIN_MATNINGAR and sek >= Lektion.MIN_DIM_SEK then
			ut[k] = s / n
		end
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
	--[[ INGEN BEDÖMNING UTAN UNDERLAG. `medel` returnerar bara de
	     dimensioner som klarat kraven; är den tom fanns det ingenting att
	     uttala sig om, och då lämnas inget omdöme alls. ]]
	local nu = Lektion.medel(pass)
	if next(nu) == nil then return nil end
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
