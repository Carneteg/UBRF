--!strict
--[[
	Planoppning — dörr-/portlägen DIGITALISERADE ur stallets utrymningsplan.

	KÄLLAN. Utrymningsplanens gröna band markerar utrymningsvägar. Där ett
	band korsar husets yttervägg finns en dörr. Det är den enda
	dörrmarkeringen i planen som går att läsa utan att gissa — de tunna
	väggluckorna inne i huset är för många och för lika ritbrus.

	Banden hittas reproducerbart av `tools/planoppningar.py`, som tröskar
	fram den gula husytan och de gröna banden och rapporterar vilka band som
	rör husytan. Fyra band gör det i `stall-plan1-utrymning-rak.jpg`.

	LÄGET ÄR INTE LIKA SÄKERT SOM FÖREKOMSTEN. Att ett band ligger på
	västväggen är en topologisk avläsning och tål inget mätfel. VAR på väggen
	det sitter beror på var husets gavlar anses börja, och gavlarna är inte
	entydiga i fotot: den gula ytan tar slut på olika ställen beroende på
	vilka kolumner man mäter i.

	Läget mättes därför med TRE oberoende definitioner av husets
	utsträckning, och spridningen mellan dem redovisas per öppning:

	  · under 2 % av huslängden  → `nandel` sätts, klass PLAN
	  · över  2 %                → `nandel` är nil, klass GAP

	Två av fyra klarar gränsen. Att skriva ut ett läge för de andra två hade
	varit att låta en avläsning som spretar 2,7 % se ut som ett mått.

	RIKTNINGEN. Planbilden har klubbänden UPPÅT; modellen har klubbänden vid
	HÖG y (`klubbY = 52,85` av 69,95). `nandel` är därför räknad från y = 0,
	alltså söder — planens andel speglad.

	INGA INNERDÖRRAR. De står som REFERENCE GAP tills en källa bär dem.
]]

local Planoppning = {}

export type Oppning = {
	id: string,
	hus: string,
	vagg: string, -- "V" | "O" | "N" | "S", husets lokala väderstreck
	klass: string, -- PLAN när läget är mätt, GAP när bara sidan är läst
	-- Andel 0–1 längs väggen, räknad från y = 0. nil = läget är inte
	-- försvarbart och öppningen finns bara som post.
	nandel: number?,
	-- Spridningen mellan de tre definitionerna, i andel av huslängden.
	spridning: number,
	kalla: string,
}

Planoppning.GRANS_SPRIDNING = 0.02

local lista: { Oppning } = {
	{
		id = "s_opp_ost_service", hus = "stall", vagg = "O", klass = "PLAN",
		nandel = 0.2334, spridning = 0.0062,
		kalla = "grönt utrymningsband genom östväggen, servicedelen "
			.. "(stall-plan1-utrymning-rak.jpg, px 953–1103 × 1459–1499)",
	},
	{
		id = "s_opp_vast_mitt", hus = "stall", vagg = "V", klass = "PLAN",
		nandel = 0.5019, spridning = 0.0134,
		kalla = "grönt utrymningsband genom västväggen, mitt på huset "
			.. "(stall-plan1-utrymning-rak.jpg, px 379–549 × 1027–1089)",
	},
	{
		id = "s_opp_vast_klubb", hus = "stall", vagg = "V", klass = "GAP",
		nandel = nil, spridning = 0.0208,
		kalla = "grönt utrymningsband genom västväggen vid klubbgränsen. "
			.. "Sidan är läst, läget spretar 2,1 % mellan tre definitioner "
			.. "av husets utsträckning — över gränsen 2 %",
	},
	{
		id = "s_opp_norr_gavel", hus = "stall", vagg = "N", klass = "GAP",
		nandel = nil, spridning = 0.0271,
		kalla = "grönt utrymningsband genom norra gaveln vid "
			.. "brandlarmscentralen. Sidan är läst, läget spretar 2,7 %",
	},
}

Planoppning.lista = lista

--[[ Ridhuset har inga digitaliserade öppningar. Planen är ett perspektivfoto
     som tre rektifieringsförsök underkänt (docs/F02-REKTIFIERING-KRAV.md), så
     ingen andel längs någon vägg är mätbar. Att ta med dem "ungefär" hade
     gett granskaren ett dörrläge att bedöma som ingen källa bär. ]]
Planoppning.RIDHUS_GAP =
	"Ridhusets dörrlägen är REFERENCE GAP: planen är inte rätbar, "
	.. "se docs/F02-REKTIFIERING-KRAV.md"

--[[ Ett mätt läge i meter, med skalklassen med sig — samma kontrakt som
     Planrum.meter. Öppningar utan nandel ger nil. ]]
function Planoppning.meter(o: Oppning, SKALA): (number?, string)
	if not o.nandel then return nil, "GAP" end
	local s = SKALA[o.hus]
	if not s then return nil, "GAP" end
	return o.nandel * s.langd, s.klass
end

--[[ Skillnaden mot den byggda modellen är en GRANSKNINGSPUNKT, inte något
     som ska rättas tyst åt något håll. Planen lägger västöppningen på
     50,2 % av längden; modellens tvärkorridor ligger på 42,3 %. Vilken som
     har rätt avgörs av Tobias i Studio, inte av mig här. ]]
Planoppning.NOTERAT_AVSTEG =
	"s_opp_vast_mitt ligger på 50,2 % av längden i planen; modellens "
	.. "tvärkorridor (tvarGang) ligger på 42,3 %. Skillnaden ≈ 5,5 m är "
	.. "OBEDÖMD — den ska tas upp i Steg A, inte rättas i tysthet."

return Planoppning
