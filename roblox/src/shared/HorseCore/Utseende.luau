--!strict
--[[
	UTSEENDET — från hästens egen data till en visuell konfiguration.

	══ VARFÖR DEN HÄR MODULEN FINNS ═══════════════════════════════════

	Trettiotvå hästar stod i lådor medan en var riktig. Den enkla vägen
	hade varit att klona Blackrock Jack trettiotvå gånger, och då hade
	ridskolan haft trettiotre exemplar av samma mörkbruna D-ponny —
	fjordhästen, haflingern och den 178 cm höga svenska varmblodiga
	valacken inkluderade. Det är inte UBRF.

	Modulen är därför kartan: HÄSTENS DATA IN, VISUELL KONFIGURATION UT.
	Ingenting här vet vad K3:s kroppsdelar heter, och ingenting i
	`HastVisual` vet vad en kategori D-ponny är för höjd.

	══ VAD SOM ÄR KÄLLA OCH VAD SOM INTE ÄR DET ═══════════════════════

	Supabase `public.hastar` har identitet, ras, mankhöjd, kategori,
	import och beskrivning. Den har INGEN kolumn för färg eller tecken.
	Storleken nedan kommer alltså ur källan; färgen gör det inte.

	Färgen kommer i stället ur hästens rad i den delade rostern
	(`src/spel/hastar.js` → `UBRFSpelData`), och den raden bär själv
	`visuellStatus`:

	    FOTO        färgen är AVLÄST ur bilden som `bild_url` pekar på,
	    ASSUMPTION  färgen är vald som presentation, inte avläst.

	Modulen HITTAR INTE PÅ NÅGOT. Saknas ett fält faller den tillbaka på
	rostern egna standardvärde och SÄGER att den gjorde det, i `kallor`.
	Ett `[REFERENCE GAP]` ska synas i utdata, inte döljas av en gissning.
]]

local Utseende = {}

local M = 3   -- studs per meter, som BuildKit.M

--[[ ══ STORLEKEN ═════════════════════════════════════════════════════

	Mankhöjden i meter, och varifrån den kommer.

	1. `mankhojd` i källan är centimeter och gäller rakt av. Tio av
	   trettiotre hästar har den.
	2. Annars ponnykategorin. Svenska kategorier är takhöjder — A ≤ 107,
	   B ≤ 130, C ≤ 140, D ≤ 148 cm — och talen nedan ligger strax under
	   sina tak, alltså en typisk individ i kategorin snarare än det
	   största djur som får plats i den. D ger 1,45, vilket är exakt den
	   höjd Blackrock Jack redan har: rättningen får inte flytta en häst
	   som redan står rätt.
	3. Annars typen. En häst utan både mått och kategori får 1,65 — och
	   det är ett ANTAGANDE, märkt som ett sådant. ]]
local KATEGORIHOJD: { [string]: number } = {
	A = 1.05, B = 1.27, C = 1.37, D = 1.45,
}
local HASTHOJD_ANTAGEN = 1.65

function Utseende.mankhojd(hast: { [string]: any }): (number, string)
	local cm = hast.mankhojd
	if type(cm) == "number" and cm > 50 and cm < 250 then
		return cm / 100, "KALLA"
	end
	local kat = hast.kategori
	if type(kat) == "string" and KATEGORIHOJD[kat] then
		return KATEGORIHOJD[kat], "KATEGORI"
	end
	return HASTHOJD_ANTAGEN, "ANTAGANDE"
end

--[[ ══ FÄRGERNA ══════════════════════════════════════════════════════

	Rostern standardvärden, som är webbens egna: en brun häst med mörk
	man. De ligger här som NAMNGIVNA standardvärden och inte som
	inbakade tal, så att en häst utan avläst färg går att skilja från en
	häst som råkar vara brun. ]]
Utseende.STANDARD_KROPP = Color3.fromRGB(114, 83, 59)
Utseende.STANDARD_MAN = Color3.fromRGB(47, 33, 24)
Utseende.STANDARD_HOV = Color3.fromRGB(27, 42, 53)

--[[ Mulen är mörkare än pälsen på nästan varje häst. Saknas ett avläst
	värde härleds den ur pälsen i stället för att hittas på: samma färg,
	tre fjärdedels ljushet. Det är en HÄRLEDNING och märks som en. ]]
local function morkare(f: Color3, andel: number): Color3
	return Color3.new(f.R * andel, f.G * andel, f.B * andel)
end

--[[ ══ TECKNEN ═══════════════════════════════════════════════════════

	`tecken.strumpor` är fyra tal i rosterns egen benföljd, dokumenterad
	i `src/scen3d.js`: fram vänster, fram höger, bak vänster, bak höger.
	Ordningen får inte kastas om — en häst med strumpa på höger bak ska
	ha den där på båda ytorna. ]]
Utseende.BENFOLJD = { "framV", "framH", "bakV", "bakH" }

--[[ Den visuella konfigurationen för en häst.

	Svarar ALLTID med ett fullständigt svar: varje fält har ett värde och
	`kallor` säger varifrån det kom. Den som ritar behöver då aldrig
	fråga sig om ett `nil` betyder vit, svart eller "vet inte". ]]
function Utseende.for_(hast: { [string]: any }?): { [string]: any }
	local h = hast or {}
	local hojd, hojdKalla = Utseende.mankhojd(h)

	local kropp = if typeof(h.farg) == "Color3" then h.farg else Utseende.STANDARD_KROPP
	local man = if typeof(h.man) == "Color3" then h.man else Utseende.STANDARD_MAN
	local avlast = h.visuellStatus == "FOTO"

	local mule, muleKalla
	if typeof(h.mule) == "Color3" then
		mule, muleKalla = h.mule, "FOTO"
	else
		mule, muleKalla = morkare(kropp, 0.75), "HARLEDD"
	end

	local tecken = h.tecken or {}
	local strumpor = {}
	local rada = tecken.strumpor
	for i, namn in ipairs(Utseende.BENFOLJD) do
		strumpor[namn] = (type(rada) == "table" and rada[i] == 1) or false
	end

	return {
		mankhojd = hojd,
		mankhojdStuds = hojd * M,
		kropp = kropp,
		man = man,
		--[[ Fjordhästens mörka mittstrimma i manen. Bara de hästar vars
			man faktiskt ÄR tvåfärgad bär fältet; för alla andra är hela
			manen en färg, vilket är det normala. ]]
		manKarna = if typeof(h.manKarna) == "Color3" then h.manKarna else nil,
		mule = mule,
		hov = Utseende.STANDARD_HOV,
		blas = tecken.blas == true,
		strumpor = strumpor,
		--[[ Hovskägg. Ligger i rostern som `fjader` och hör till de tunga
			raserna; det ritas inte än i Roblox men följer med i svaret så
			att den dagen kan komma utan att kartan skrivs om. ]]
		fjader = h.fjader == true,
		kallor = {
			mankhojd = hojdKalla,
			farg = if avlast then "FOTO" else "ROSTER",
			mule = muleKalla,
			tecken = if avlast then "FOTO" else "ROSTER",
		},
	}
end

return Utseende
