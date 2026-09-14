--!strict
--[[
	UTRUSTNINGSKATALOGEN — vad som finns att ta på, var det fästs, och
	vilken visuell källa som bär det. EQUIPMENT & RIDER GEAR GATE (#165).

	══ VARFÖR EN KATALOG OCH INTE TRE HÅRDKODADE MODELLER ═══════════

	Ordern 2026-09-14 03:40: hjälm, sadel och träns ska vara DATADRIVEN
	utrustning, inte per-spelare/per-häst-hårdkod, och de visuella
	modellerna ur Creator Store ska kopplas till det tillstånd som redan
	finns (`TackService`, delarna i hästens `Tack`-mapp) — inte till ett
	andra system.

	Den här modulen är därför det ENDA stället som vet:

	  · vilka typer som finns och i vilken ordning de hör ihop,
	  · vilken Creator Store-modell som är kandidat för varje typ, med
	    licens- och attributionsfynd,
	  · om modellen är ANTAGEN (laddas i runtime) eller AVVISAD (primitiven
	    ritas), och varför,
	  · vilken fästpunkt på riggen (RigAdapter.tackfaste) eller på
	    spelaren (Head) delen svetsas i,
	  · om utrustningen KRÄVS för att sitta upp.

	`TackRigg` läser katalogen för att bygga, `TackService` för reglerna,
	klienten för etiketter. Ingen av dem har en egen lista.

	══ LICENS OCH ATTRIBUTION ═════════════════════════════════════════

	Alla sju kandidater i #165 är fria modeller i Roblox Creator Store
	(`IsPublicDomain = true`, `fiatProduct.isFree = true`, mätt mot
	economy- och toolbox-API:erna 2026-09-14). Creator Store-villkoren ger
	rätt att använda dem i egna upplevelser. Tränset 15966015286 bär
	kravet i sin TITEL: "[ALWAYS CREDIT RHS FOR IT!]" — beskrivningen är
	tom, så det exakta kravet finns bara där. Krediten står i
	`references/licenses/roblox-creator-store.md` och i `attribution`
	nedan, och den följer med i spelets kreditlista.

	══ HJÄLMEN — TVÅ KANDIDATER UR SPEL, DEN TREDJE ANTAGEN ═══════════

	123547958 "Moldenhauer Family Helmet" (2013) innehåller ETT Script
	(toolbox `instanceCounts.script = 1`) och kan inte hämtas utan
	inloggning (assetdelivery 401), så skriptet går inte att inspektera.
	Den avvisades i #170. 11611844698 "Adrian Helmet" (cbr44446) klarade
	prövningen (PO-val 05:01) men ersattes av Tobias 05:02 — den är inte
	längre kandidat. Båda står i `AVVISADE` så att ingen av dem kan komma
	tillbaka utan att ett prov faller.

	Den gällande kandidaten är 92445706145003 "rosto do silva 25k"
	(Bebel_dopix, 2025-04-20): fri (IsPublicDomain, isFree), 4 MeshParts,
	3 194 trianglar / 9 029 hörn, INGA skript, beskrivningen är titeln
	(inget attributionskrav), objekttyp Hat/Accessory. Samma prövning som
	sadeln och tränset, samma utfall: antagen som runtime-kandidat.
	Butiksbilden visar en svart kupa med hakrem på ett huvud — om huvudet
	och halsen i bilden är delar av modellen kan inte avgöras headless
	(assetdelivery 401): HARDWARE CHECK i Studio. Laddas den inte ritas
	primitiven i webbens gröna.

	══ VISUELL KÄLLA — ASSET ELLER PRIMITIV ═══════════════════════════

	`visual = "asset"` betyder: `TackRigg` försöker ladda modellen med
	`InsertService:LoadAsset` och passa in den i primitivens egen låda
	(samma läge, samma fästpunkt, samma svets). Går laddningen inte —
	nätet, rättigheter, ett skript i modellen, en modell utan delar —
	ritas primitiven. Tillståndet (`UBRFTack`, `ForHast`) är detsamma
	vilket som visas: utseendet är aldrig sanningen.

	Studio-QA kan tvinga primitiven utan kodändring:
	`workspace:SetAttribute("UBRFUtrustningVisual", "primitiv")`.
]]

local Utrustning = {}

export type Post = {
	typ: string,
	--[[ "hast" sitter på hästen (RigAdapter.tackfaste), "ryttare" på
		spelarens karaktär. ]]
	barare: string,
	faste: string,
	--[[ Creator Store-kandidaten, om någon. ]]
	assetId: number?,
	assetNamn: string?,
	skapare: string?,
	licens: string?,
	attribution: string?,
	trianglar: number?,
	skript: number?,
	--[[ "asset" | "primitiv" — vad TackRigg försöker rita först. ]]
	visual: string,
	--[[ Varför modellen är antagen eller avvisad. Spelaren ser den aldrig;
		granskaren gör det. ]]
	beslut: string,
	--[[ Krävs den för att sitta upp? Hjälmen ja (ridskolans regel:
		ingen rider utan hjälm). Sadel och träns prövas redan av
		`TackService.ridklar`. ]]
	kravsForRidning: boolean,
}

local LICENS = "Roblox Creator Store, fri modell (IsPublicDomain, isFree) — 2026-09-14"

local KATALOG: { Post } = {
	{
		typ = "hjalm", barare = "ryttare", faste = "Head",
		assetId = 92445706145003, assetNamn = "rosto do silva 25k",
		skapare = "Bebel_dopix", licens = LICENS,
		trianglar = 3194, skript = 0,
		visual = "asset",
		beslut = "ANTAGEN som runtime-kandidat (PO-val 2026-09-14 05:02): 4 MeshParts, "
			.. "3 194 trianglar, inga skript, fri, inget attributionskrav i titel eller "
			.. "beskrivning, objekttyp Hat/Accessory. Passas in i huvudets låda och "
			.. "svetsas i Head. Läge, skala, klippning mot avataren/kameran och om "
			.. "modellen bär eget huvud/hals (butiksbilden) är HARDWARE CHECK i Studio.",
		kravsForRidning = true,
	},
	{
		typ = "underlagg", barare = "hast", faste = "sadel",
		--[[ Underlägget hör till sadelmodellen 9639407836 ("saddle and
			Saddle pad") och byggs ur samma laddning som sadeln; ingen
			egen asset. ]]
		visual = "primitiv",
		beslut = "Primitiv: schabraket ingår i sadelmodellens laddning; ritas "
			.. "som eget lager bara när sadeln är primitiv.",
		kravsForRidning = false,
	},
	{
		typ = "sadel", barare = "hast", faste = "sadel",
		assetId = 9639407836, assetNamn = "Race horse saddle and Saddle pad",
		skapare = "Josijosi00", licens = LICENS,
		trianglar = 24540, skript = 0,
		visual = "asset",
		beslut = "ANTAGEN som runtime-kandidat: 4 MeshParts, 24 540 trianglar, "
			.. "inga skript. Orientering, skala och klippning mot riggen är "
			.. "HARDWARE CHECK i Studio — inpassningen sker mot primitivens låda.",
		kravsForRidning = false,
	},
	{
		typ = "trans", barare = "hast", faste = "trans",
		assetId = 15966015286, assetNamn = "Horse bridle [ALWAYS CREDIT RHS FOR IT!]",
		skapare = "corvyyn", licens = LICENS,
		attribution = "Träns: \"Horse bridle\" av corvyyn — credit RHS (krav i modellens titel)",
		trianglar = 1794, skript = 0,
		visual = "asset",
		beslut = "ANTAGEN som runtime-kandidat: 1 794 trianglar, inga skript, "
			.. "attribution registrerad. Orientering/skala HARDWARE CHECK.",
		kravsForRidning = false,
	},
}

local perTyp: { [string]: Post } = {}
for _, p in ipairs(KATALOG) do perTyp[p.typ] = p end

function Utrustning.katalog(): { Post }
	return KATALOG
end

function Utrustning.post(typ: string): Post?
	return perTyp[typ]
end

--[[ AVVISADE kandidater. Står här så att ett prov kan fälla varje
	katalogpost som pekar på dem — ett avvisat asset-ID ska inte kunna
	komma tillbaka tyst genom en redigering. ]]
Utrustning.AVVISADE = {
	{ assetId = 123547958, namn = "Moldenhauer Family Helmet", skapare = "skitzochase",
		skal = "1 Script i modellen, oinspekterbart (assetdelivery 401); 2013. Ersatt (PO 2026-09-14 05:01)." },
	{ assetId = 11611844698, namn = "Adrian Helmet", skapare = "cbr44446",
		skal = "Klarade prövningen (0 skript, 7 808 trianglar) men ersatt av Tobias 2026-09-14 05:02 med 92445706145003; inte längre kandidat." },
}

--[[ Typerna spelaren kan sätta på och ta av genom utrustningspanelen, i
	den ordning panelen visar dem. `tygel` hör till tränset och listas
	inte; `underlagg` följer sadeln. ]]
Utrustning.PANEL = { "hjalm", "sadel", "trans" }

--[[ Kandidater som INTE tas in i den här grinden, med skäl. Står här så
	att beslutet är läsbart ur samma modul som resten. ]]
Utrustning.HOPP = {
	{ assetId = 2780160044, namn = "horse jump #", skapare = "horsegirlltu",
		trianglar = 888, skript = 0, rost = "92 % upp (10)",
		beslut = "REKOMMENDERAD för Studio-QA: lägst trianglar per hinder, inga skript. "
			.. "Inte integrerad: skala, kollision och ridlinje kan inte mätas här." },
	{ assetId = 2314446954, namn = "(RC) Horse Jumps", skapare = "sillyAuraa",
		trianglar = 792, skript = 0, rost = "90 % upp (10)",
		beslut = "Andrahandsval: flera hinder i en modell; kräver isärplockning." },
	{ assetId = 174424237, namn = "SAFE horse jumps", skapare = "officialgrace",
		trianglar = 7680, skript = 0, rost = "83 % upp (10)",
		beslut = "Avvisad tills vidare: 7 680 trianglar för en hindersats, 2014." },
	{ assetId = 8941934960, namn = "Horse Jump", skapare = "Hoffroc",
		trianglar = nil, skript = 0, rost = "71 % upp",
		beslut = "Avvisad tills vidare: ingen nätsummering i API:et (troligen Parts), lägst röst." },
}

--[[ Vilken visuell källa som ska prövas för en typ, med Studio-QA:s
	tvingande attribut. ]]
function Utrustning.visualFor(typ: string, override: string?): string
	local p = perTyp[typ]
	if not p then return "primitiv" end
	if override == "primitiv" or override == "asset" then return override end
	return p.visual
end

--[[ Krävs utrustningen för att sitta upp? ]]
function Utrustning.kravsForRidning(typ: string): boolean
	local p = perTyp[typ]
	return p ~= nil and p.kravsForRidning == true
end

--[[ Attributionerna som ska stå i spelets kreditlista. ]]
function Utrustning.attributioner(): { string }
	local ut = {}
	for _, p in ipairs(KATALOG) do
		if p.attribution then table.insert(ut, p.attribution) end
	end
	return ut
end

return Utrustning
