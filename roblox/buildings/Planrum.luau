--!strict
--[[
	Planrum — rumsgränser DIGITALISERADE ur utrymningsplanerna, för F02 Fas 1.

	Källor:
	  · references/plans/stall-plan1-utrymning-rak.jpg  (rak bild, pålitligast)
	  · references/plans/ridhus-entreplan-utrymning.jpg (perspektivfoto)

	METOD OCH ÄRLIGHET. Gränserna är lästa i uppförstorade utsnitt och
	omräknade via husens kända mått (stall 21 × 69,95 · klubbdel 17,1 djup;
	ridhus 25 × 77,18). Stallets bild är tagen rakt framifrån och läses med
	~±0,5 m; ridhusets är ett perspektivfoto där LÄNGDLED trycks ihop mot
	bildens överkant — där är tvärled (±0,5 m) pålitlig men djupled ±2 m.

	Rum vars LÄGE syns men vars mått perspektivet förstör står med rekt = nil:
	de finns i granskningspanelen som poster men ritas inte, för en FEL
	rektangel är värre än ingen. Det som låser upp dem är en rektifierad bild
	av ridhusplanen (som stallets "-rak") eller mått på plats.

	FUNKTIONER HITTAS ALDRIG PÅ. Ingen rumsetikett är läsbar i något av
	fotona, så alla id:n är neutrala (rum/korridor/trapphus/schakt) — aldrig
	WC eller kontor förrän en källa säger det. Gräns = PLAN, funktion = GAP.

	Koordinater: husets lokala system, sydvästra hörnet, meter. niva 2 =
	stallets övervåning (ritas på 3,8 m höjd i granskningsläget).
]]

local Planrum = {}

export type Rum = {
	id: string,
	namn: string,
	hus: string,
	niva: number,
	klass: string,
	kalla: string,
	rekt: { x: number, y: number, w: number, h: number }?,
}

Planrum.TOLERANS = {
	stall = "±0,5 m (rak bild)",
	ridhus = "tvärled ±0,5 m, djupled ±2 m (perspektivfoto)",
}

Planrum.lista = {
	-- ── RIDHUSET, entréplanet — gavelbandet (tvärled pålitlig) ──────────
	-- Läktaren ligger på höga x (RIDHUSINNE.laktare.x0 = 21), annexsidan på
	-- låga x. Gavelentrén med pil ut sitter närmast annexsidan.
	{ id = "r_entre_trapphus_01", namn = "Trapphus, hörnet mot läktarsidan",
		hus = "ridhus", niva = 1, klass = "PLAN",
		kalla = "skrafferat i gavelbandets bortre hörn",
		rekt = { x = 20.9, y = 74.2, w = 3.9, h = 2.95 } },
	{ id = "r_entre_rum_01", namn = "Gavelrum 1", hus = "ridhus", niva = 1,
		klass = "PLAN", kalla = "gavelbandet; funktion oläslig → GAP",
		rekt = { x = 13.5, y = 74.2, w = 6.2, h = 2.95 } },
	{ id = "r_entre_rum_02", namn = "Gavelrum 2", hus = "ridhus", niva = 1,
		klass = "PLAN", kalla = "gavelbandet; funktion oläslig → GAP",
		rekt = { x = 8.9, y = 74.2, w = 4.6, h = 2.95 } },
	{ id = "r_entre_rum_03", namn = "Gavelrum 3", hus = "ridhus", niva = 1,
		klass = "PLAN", kalla = "gavelbandet; funktion oläslig → GAP",
		rekt = { x = 5.3, y = 74.2, w = 3.6, h = 2.95 } },
	{ id = "r_entre_rum_04", namn = "Gavelrum 4, vid gavelentrén",
		hus = "ridhus", niva = 1, klass = "PLAN",
		kalla = "utrymningspil ut genom gaveln här — svarta dörrens rum?  funktion GAP",
		rekt = { x = 1.5, y = 74.2, w = 3.8, h = 2.95 } },
	{ id = "r_entre_korridor_01", namn = "Gavelkorridoren",
		hus = "ridhus", niva = 1, klass = "PLAN",
		kalla = "bandet innanför gavelrummen, pil österut i det",
		rekt = { x = 0.2, y = 71.8, w = 20.7, h = 2.4 } },

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
		rekt = { x = 6.2, y = 60.0, w = 1.6, h = 5.6 } },
	{ id = "s_klubb_schakt_01", namn = "Schaktet vid gavelns mitt",
		hus = "stall", niva = 1, klass = "PLAN",
		kalla = "vit ruta vid norra gaveln, samma läge på båda planen",
		rekt = { x = 9.7, y = 68.3, w = 1.1, h = 1.65 } },
	{ id = "s_klubb_rum_01", namn = "Nordöstra rummet", hus = "stall", niva = 1,
		klass = "PLAN", kalla = "stort rum mot gaveln, öster om schaktet; funktion GAP",
		rekt = { x = 11.0, y = 65.3, w = 6.8, h = 4.65 } },
	{ id = "s_klubb_rum_02", namn = "Östra mittrummet", hus = "stall", niva = 1,
		klass = "PLAN", kalla = "funktion GAP",
		rekt = { x = 11.4, y = 58.7, w = 4.1, h = 6.4 } },
	{ id = "s_klubb_rum_03", namn = "Rummet vid östra väggen", hus = "stall", niva = 1,
		klass = "PLAN", kalla = "utrymningspil genom östväggen; funktion GAP",
		rekt = { x = 15.5, y = 58.9, w = 5.3, h = 9.4 } },
	{ id = "s_klubb_korridor_01", namn = "Klubbdelens inre korridor",
		hus = "stall", niva = 1, klass = "PLAN",
		kalla = "bandet mellan rumsgruppen och boxhallen",
		rekt = { x = 3.5, y = 56.5, w = 17.0, h = 1.9 } },
	{ id = "s_tvarpassage_klubb", namn = "Tvärpassagen under klubbdelen",
		hus = "stall", niva = 1, klass = "PLAN",
		kalla = "utrymningspilar genom BÅDA långsidorna vid klubbgränsen — fanns inte i modellen",
		rekt = { x = 0, y = 52.5, w = 21, h = 2.3 } },

	-- ── STALLET, plan 2 — övervåningen (rak bild; västra delen skymd) ───
	{ id = "s2_trappa_01", namn = "Raka trappan, övre delen",
		hus = "stall", niva = 2, klass = "PLAN",
		kalla = "samma schakt som s_klubb_trappa_01",
		rekt = { x = 6.2, y = 60.0, w = 1.6, h = 5.6 } },
	{ id = "s2_schakt_01", namn = "Schaktet, övre delen",
		hus = "stall", niva = 2, klass = "PLAN",
		kalla = "vit ruta i samma gavelläge som plan 1",
		rekt = { x = 9.7, y = 68.3, w = 1.1, h = 1.65 } },
	{ id = "s2_storsal", namn = "Stora salen mot öster",
		hus = "stall", niva = 2, klass = "PLAN",
		kalla = "störst på planet, hela östsidan; funktion GAP",
		rekt = { x = 13.0, y = 53.0, w = 8.0, h = 16.95 } },
	{ id = "s2_korridor_01", namn = "Övervåningens korridor",
		hus = "stall", niva = 2, klass = "PLAN",
		kalla = "bandet med balkongdörren i norr och rumsraden i söder",
		rekt = { x = 4.0, y = 58.0, w = 9.0, h = 2.0 } },
	{ id = "s2_rum_01", namn = "Övervåningsrum 1", hus = "stall", niva = 2,
		klass = "PLAN", kalla = "rumsraden söder om korridoren; delningarna ±1 m",
		rekt = { x = 4.5, y = 53.0, w = 3.0, h = 5.0 } },
	{ id = "s2_rum_02", namn = "Övervåningsrum 2", hus = "stall", niva = 2,
		klass = "PLAN", kalla = "rumsraden söder om korridoren; delningarna ±1 m",
		rekt = { x = 7.5, y = 53.0, w = 2.5, h = 5.0 } },
	{ id = "s2_rum_03", namn = "Övervåningsrum 3", hus = "stall", niva = 2,
		klass = "PLAN", kalla = "rumsraden söder om korridoren; delningarna ±1 m",
		rekt = { x = 10.0, y = 53.0, w = 2.5, h = 5.0 } },
	{ id = "s2_vastdel", namn = "Övervåningens västra del",
		hus = "stall", niva = 2, klass = "GAP",
		kalla = "skyms av kanten i planfotot — oläst, inte tom" },
} :: { Rum }

return Planrum
