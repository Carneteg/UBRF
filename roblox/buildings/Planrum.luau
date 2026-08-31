--!strict
--[[
	Planrum — rumsgränser DIGITALISERADE ur utrymningsplanerna, för F02 Fas 1.

	Källor:
	  · references/plans/stall-plan1-utrymning-rak.jpg  (rak bild, pålitligast)
	  · references/plans/ridhus-entreplan-utrymning.jpg (perspektivfoto)

	KOORDINATERNA ÄR NORMALISERADE, INTE METER. `nrekt` är andelar 0–1 av
	husets bredd och längd, lästa direkt ur planbilderna. Det är avsiktligt:

	  references/plans/PLAN1-OMMATNING-2026-08-30.md säger uttryckligen att
	  planerna SAKNAR SKALSTOCK och att stallets totalbredd fortfarande är
	  OLÖST i intervallet 15–23 m (OAVGJORT.md fråga 2). Meterrektanglar
	  räknade på en provisorisk bredd 21 m hade gjort det talet till kanon
	  bakvägen, genom rumsgeometri — precis det som redan hänt en gång i det
	  här projektet med fargexporten och objektantalet.

	Planens PROPORTIONER är PLAN-belagda. Dess METERSKALA är det inte.
	`Planrum.meter()` gör om till meter och märker resultatet ASSUMED_SCALE,
	så att skillnaden syns i QA-texten i stället för att tystna.

	AVLÄSNINGENS OSÄKERHET, per källa:
	  · stall  — `stall-plan1-utrymning-rak.jpg`, fotad rakare framifrån.
	    Proportionerna läses med ~±0,7 % av husbredden. INTE ±0,5 m: den
	    siffran förutsatte en bredd som inte är fastställd.
	  · ridhus — `ridhus-entreplan-utrymning.jpg` är ett perspektivfoto.
	    Rektifiering försöktes (tools/rektifiera-plan.py) och konvergerade
	    INTE: kantresidualen stannade på 4,9 % av bredden mot kravet 3 %.
	    Se docs/F02-DIGITALISERING.md. Tvärled är läsbart, djupled inte.

	Rum vars LÄGE syns men vars mått bilden inte bär står utan `nrekt`: de
	finns i granskningspanelen som poster men ritas inte, för en FEL rektangel
	är värre än ingen.

	FUNKTIONER HITTAS ALDRIG PÅ. Ingen rumsetikett är läsbar i något av
	fotona, så alla id:n är neutrala (rum/korridor/trapphus/schakt) — aldrig
	WC eller kontor förrän en källa säger det. Gräns = PLAN, funktion = GAP.

	niva 2 = stallets övervåning (ritas på övervåningshöjd i granskningsläget).
]]

local Planrum = {}

export type Rum = {
	id: string,
	namn: string,
	hus: string,
	niva: number,
	klass: string,
	kalla: string,
	-- Andelar 0–1 av husets bredd/längd. INTE meter — se filhuvudet.
	nrekt: { x: number, y: number, w: number, h: number }?,
}

--[[ Skalan som normaliserade koordinater räknas om med. Klassen är
     ASSUMED_SCALE och inte PLAN: talen kommer ur spelets nuvarande modell,
     inte ur planen, och stallets bredd är en öppen fråga. ]]
Planrum.SKALA = {
	stall = { bredd = 21.0, langd = 69.95, klass = "ASSUMED_SCALE",
		anm = "bredden OLÖST 15–23 m enligt OAVGJORT.md fråga 2; 21 är modellens arbetsvärde" },
	ridhus = { bredd = 25.0, langd = 77.18, klass = "ASSUMED_SCALE",
		anm = "fotavtrycket stöds av planens proportion 3,022:1 men saknar skalstock" },
}

Planrum.TOLERANS = {
	stall = "proportion ±0,7 % av husbredden (rak bild, ingen skalstock)",
	ridhus = "tvärled läsbart; djupled OLÖST — rektifiering konvergerade inte (4,9 % kantresidual)",
}

--[[ Normaliserat → meter, med skalan uttryckligen deklarerad. Returnerar
     rektangeln OCH klassen, så att den som ritar inte kan tappa bort att
     metertalen vilar på ett antagande. ]]
function Planrum.meter(rum: Rum): ({ x: number, y: number, w: number, h: number }?, string)
	if not rum.nrekt then return nil, "GAP" end
	local s = Planrum.SKALA[rum.hus]
	local n = rum.nrekt
	return {
		x = n.x * s.bredd, y = n.y * s.langd,
		w = n.w * s.bredd, h = n.h * s.langd,
	}, s.klass
end

Planrum.lista = {
	-- ── RIDHUSET, entréplanet — gavelbandet (tvärled pålitlig) ──────────
	-- Läktaren ligger på höga x (RIDHUSINNE.laktare.x0 = 21), annexsidan på
	-- låga x. Gavelentrén med pil ut sitter närmast annexsidan.
	{ id = "r_entre_trapphus_01", namn = "Trapphus, hörnet mot läktarsidan",
		hus = "ridhus", niva = 1, klass = "PLAN",
		kalla = "skrafferat i gavelbandets bortre hörn",
		nrekt = { x = 0.83600, y = 0.96139, w = 0.15600, h = 0.03822 } },
	{ id = "r_entre_rum_01", namn = "Gavelrum 1", hus = "ridhus", niva = 1,
		klass = "PLAN", kalla = "gavelbandet; funktion oläslig → GAP",
		nrekt = { x = 0.54000, y = 0.96139, w = 0.24800, h = 0.03822 } },
	{ id = "r_entre_rum_02", namn = "Gavelrum 2", hus = "ridhus", niva = 1,
		klass = "PLAN", kalla = "gavelbandet; funktion oläslig → GAP",
		nrekt = { x = 0.35600, y = 0.96139, w = 0.18400, h = 0.03822 } },
	{ id = "r_entre_rum_03", namn = "Gavelrum 3", hus = "ridhus", niva = 1,
		klass = "PLAN", kalla = "gavelbandet; funktion oläslig → GAP",
		nrekt = { x = 0.21200, y = 0.96139, w = 0.14400, h = 0.03822 } },
	{ id = "r_entre_rum_04", namn = "Gavelrum 4, vid gavelentrén",
		hus = "ridhus", niva = 1, klass = "PLAN",
		kalla = "utrymningspil ut genom gaveln här — svarta dörrens rum?  funktion GAP",
		nrekt = { x = 0.06000, y = 0.96139, w = 0.15200, h = 0.03822 } },
	{ id = "r_entre_korridor_01", namn = "Gavelkorridoren",
		hus = "ridhus", niva = 1, klass = "PLAN",
		kalla = "bandet innanför gavelrummen, pil österut i det",
		nrekt = { x = 0.00800, y = 0.93029, w = 0.82800, h = 0.03110 } },

	-- ── RIDHUSET — mittblocket och annexsidan: LÄGE läst, MÅTT olösta ───
	-- Perspektivet trycker ihop djupled; en rektangel härifrån vore en
	-- gissning. Posterna finns så att Tobias kan kvittera att de SKA finnas.
	{ id = "r_entre_schakt_01", namn = "Kryssmarkerat schakt i mittblocket",
		hus = "ridhus", niva = 1, klass = "PLAN",
		kalla = "X-markerad ruta strax innanför gavelkorridoren — mått olösta" },
	{ id = "r_entre_trapphus_02", namn = "Trapphus-stacken i mittblocket",
		hus = "ridhus", niva = 1, klass = "PLAN",
		kalla = "flera skrafferade lopp i följd längs annexsidan — mått olösta" },
	{ id = "r_entre_rum_05", namn = "Förrådsraden i mittblocket",
		hus = "ridhus", niva = 1, klass = "PLAN",
		kalla = "småfack mellan schaktet och trapphuset — mått olösta" },
	{ id = "r_entre_rum_06", namn = "Stora rummet mot annexsidan",
		hus = "ridhus", niva = 1, klass = "PLAN",
		kalla = "störst i zonen, innanför långsidan — mått olösta" },
	{ id = "r_entre_rum_07", namn = "Rumsgruppen vid långsidans utgång",
		hus = "ridhus", niva = 1, klass = "PLAN",
		kalla = "utrymningspil genom långsidan intill — mått olösta" },
	{ id = "r_cafe_nedre_01", namn = "Café Krubban, nedre annexrummen",
		hus = "ridhus", niva = 1, klass = "PLAN",
		kalla = "två rum ritade UTANFÖR huvudvolymen vid gaveln, med egen trappa" },

	-- ── STALLET, plan 1 — klubbdelen (rak bild, ±0,5 m) ─────────────────
	{ id = "s_klubb_trappa_01", namn = "Raka trappan till plan 2",
		hus = "stall", niva = 1, klass = "PLAN",
		kalla = "skrafferad med vilplan, mitt-väst i klubbdelen; ligger under plan 2:s trappa",
		nrekt = { x = 0.24800, y = 0.77740, w = 0.06400, h = 0.07256 } },
	{ id = "s_klubb_schakt_01", namn = "Schaktet vid gavelns mitt",
		hus = "stall", niva = 1, klass = "PLAN",
		kalla = "vit ruta vid norra gaveln, samma läge på båda planen",
		nrekt = { x = 0.46190, y = 0.97641, w = 0.05238, h = 0.02359 } },
	{ id = "s_klubb_rum_01", namn = "Nordöstra rummet", hus = "stall", niva = 1,
		klass = "PLAN", kalla = "stort rum mot gaveln, öster om schaktet; funktion GAP",
		nrekt = { x = 0.52381, y = 0.93352, w = 0.32381, h = 0.06648 } },
	{ id = "s_klubb_rum_02", namn = "Östra mittrummet", hus = "stall", niva = 1,
		klass = "PLAN", kalla = "funktion GAP",
		nrekt = { x = 0.54286, y = 0.83917, w = 0.19524, h = 0.09149 } },
	{ id = "s_klubb_rum_03", namn = "Rummet vid östra väggen", hus = "stall", niva = 1,
		klass = "PLAN", kalla = "utrymningspil genom östväggen; funktion GAP",
		nrekt = { x = 0.73810, y = 0.84203, w = 0.25238, h = 0.13438 } },
	{ id = "s_klubb_korridor_01", namn = "Klubbdelens inre korridor",
		hus = "stall", niva = 1, klass = "PLAN",
		kalla = "bandet mellan rumsgruppen och boxhallen",
		nrekt = { x = 0.16667, y = 0.80772, w = 0.80952, h = 0.02716 } },
	{ id = "s_tvarpassage_klubb", namn = "Tvärpassagen under klubbdelen",
		hus = "stall", niva = 1, klass = "PLAN",
		kalla = "utrymningspilar genom BÅDA långsidorna vid klubbgränsen — fanns inte i modellen",
		nrekt = { x = 0.00000, y = 0.75054, w = 1.00000, h = 0.03288 } },

	-- ── STALLET, plan 2 — övervåningen (rak bild; västra delen skymd) ───
	{ id = "s2_trappa_01", namn = "Raka trappan, övre delen",
		hus = "stall", niva = 2, klass = "PLAN",
		kalla = "samma schakt som s_klubb_trappa_01",
		nrekt = { x = 0.29524, y = 0.85776, w = 0.07619, h = 0.08006 } },
	{ id = "s2_schakt_01", namn = "Schaktet, övre delen",
		hus = "stall", niva = 2, klass = "PLAN",
		kalla = "vit ruta i samma gavelläge som plan 1",
		nrekt = { x = 0.46190, y = 0.97641, w = 0.05238, h = 0.02359 } },
	{ id = "s2_storsal", namn = "Stora salen mot öster",
		hus = "stall", niva = 2, klass = "PLAN",
		kalla = "störst på planet, hela östsidan; funktion GAP",
		nrekt = { x = 0.61905, y = 0.75768, w = 0.38095, h = 0.24232 } },
	{ id = "s2_korridor_01", namn = "Övervåningens korridor",
		hus = "stall", niva = 2, klass = "PLAN",
		kalla = "bandet med balkongdörren i norr och rumsraden i söder",
		nrekt = { x = 0.19048, y = 0.82916, w = 0.42857, h = 0.02859 } },
	{ id = "s2_rum_01", namn = "Övervåningsrum 1", hus = "stall", niva = 2,
		klass = "PLAN", kalla = "rumsraden söder om korridoren; delningarna ±1 m",
		nrekt = { x = 0.21429, y = 0.75768, w = 0.14286, h = 0.07148 } },
	{ id = "s2_rum_02", namn = "Övervåningsrum 2", hus = "stall", niva = 2,
		klass = "PLAN", kalla = "rumsraden söder om korridoren; delningarna ±1 m",
		nrekt = { x = 0.35714, y = 0.75768, w = 0.11905, h = 0.07148 } },
	{ id = "s2_rum_03", namn = "Övervåningsrum 3", hus = "stall", niva = 2,
		klass = "PLAN", kalla = "rumsraden söder om korridoren; delningarna ±1 m",
		nrekt = { x = 0.47619, y = 0.75768, w = 0.11905, h = 0.07148 } },
	{ id = "s2_vastdel", namn = "Övervåningens västra del",
		hus = "stall", niva = 2, klass = "GAP",
		kalla = "skyms av kanten i planfotot — oläst, inte tom" },
} :: { Rum }

return Planrum
