--!strict
--[[ Studio-vyerna för Gate F01, uträknade ur geometrin i stället för
	nedskrivna som siffror. Flyttas ett hus eller en läktare i src/site.js
	följer kamerorna med.

	Review 11 kräver att den manuella kontrollen når fram till varje yta som
	byggts under interiörpasset. En enda generisk "ridhuset"-vy räcker inte:
	panelen, fönsterbandet, kortändan vid C, båset vid E, takstommen och
	sanden syns inte från samma punkt.

	Använd i Studio efter att Anlaggningen.luau körts:

	    Vyer.lista()              -- skriver ut vad som finns
	    Vyer.ga("kortandan")      -- ställer kameran

	Vyerna är grupperade i komplexet, ridhuset inne och stallet inne.
	ANTALET står avsiktligt inte skrivet här: lista() räknar tabellen och
	skriver ut summan. En siffra i en kommentar hade blivit ännu en sanning
	att hålla i synk — samma fel som redan fällt objektantalet i
	STUDIO-KONTROLL.md.

	Måtten i meter, samma koordinatsystem som resten: origo i sydväst,
	+x öster, +y norr. BuildKit räknar om till studs.

	INGA handskrivna geometrisanningar här. Varje kamera är ett uttryck i
	UBRFKomplex-data. Står en siffra rakt i en vy är det en bugg — då mäter
	vyn ett minne av datan i stället för datan, vilket är precis det felet
	som fällt silon, gårdsplanen och sponsorskyltarna i det här arbetet. ]]

local Vyer = {}

local BK = BuildKit
local G = UBRFKomplex

local function hus(id)
	for _, b in ipairs(G.byggnader) do
		if b.id == id then return b end
	end
	error("hittar inte byggnaden " .. id)
end

local ridhus, stall, hg = hus("ridhus"), hus("stall"), hus("hastgang")
local S, R = G.stall, G.ridhus
local Ro, So = R.origo, S.origo

-- Gårdarna på var sida om hästgången.
local gardMitt = (ridhus.rekt.x + ridhus.rekt.w + stall.rekt.x) / 2
local sodraGard = (math.max(ridhus.rekt.y, stall.rekt.y) + hg.rekt.y) / 2
local norraGard = (hg.rekt.y + hg.rekt.h
	+ math.min(ridhus.rekt.y + ridhus.rekt.h, stall.rekt.y + stall.rekt.h)) / 2

--[[ Långsidorna läses ur RIDHUSINNE.sidor, inte antas. Orienteringen är
	fortfarande REFERENCE GAP: visar sig läktaren ligga på andra sidan
	speglas hela interiören, och då ska kamerorna vända med. ]]
local Sid = R.sidor
local function langsidaX(sida: string, marginal: number): number
	return if sida == "W" then marginal else R.bredd - marginal
end

local panelX = langsidaX(Sid.panel, 0.2)          -- väggens insida
local panelBetraktare = langsidaX(Sid.laktare, 6.0) -- står mitt emot panelen
local basX = R.domarbas.x
local basBetraktare = langsidaX(Sid.panel, 8.0)   -- står mitt emot båset
--[[ Läktarvyn stod förut på ett fast "bana.x + 4", alltså alltid västerut.
	Speglas interiören hamnade betraktaren INTILL läktaren i stället för mitt
	emot den. Nu läses även den ur sidor. ]]
local laktareBetraktare = langsidaX(Sid.panel, 4.6)

-- Banans mitt och kortsidor.
local B = R.bana
local banMittX = B.x + B.w / 2
local banSyd, banNorr = B.y, B.y + B.h

-- Kortändan vid C och panelens stycke.
local K = R.kortanda
local kortandaMittX = (K.x0 + K.x1) / 2
local kortandaKlockH = K.sockelH + K.steg * K.stegH + K.klocka.overBlock
-- Blockets kant mot banan: y0 när det vänder sig söderut, annars y1.
local kortandaBanKant = if K.vand == "S" then K.y0 else K.y1

-- Panelens stycke: sponsorerna hänger i det, så vyn siktar på dess mitt.
local OV = G.identitet.ridhus.ovreVagg
local panelMittY = (OV.y0 + OV.y1) / 2
local panelToppH = R.tak - OV.underTak

-- Takstommens nockhöjd inifrån.
local nockH = R.tak + R.takstomme.resning

-- Gång A i stallet, och servicedelen i dess södra ände.
local gangA = S.gangar.A
local gangAx = gangA and (gangA.x0 + gangA.x1) / 2 or S.bredd / 2
local serviceDjup = 0
for _, sv in ipairs(S.service) do
	serviceDjup = math.max(serviceDjup, sv.rekt.y + sv.rekt.h)
end

Vyer.vyer = {
	--[[ ── Komplexet ── behålls från Review 03; de bedömer tomten, inte
		interiören, och är fortfarande det som avgör igenkänningen utifrån. ]]
	{
		id = "oversikt",
		grupp = "Komplexet",
		text = "Översikt uppifrån — jämför med satellitbilden",
		fran = { x = gardMitt, y = sodraGard - 40, h = 95 },
		mot = { x = gardMitt, y = (sodraGard + norraGard) / 2 },
		krav = "Två parallella huvudvolymer, EN tvärgående förbindelse mellan dem, och mellanrummet delat i två gårdsytor.",
	},
	{
		id = "ankomsten",
		grupp = "Komplexet",
		text = "Grusplanen mot de norra gavlarna — så man kommer till UBRF",
		fran = { x = gardMitt, y = math.min(ridhus.rekt.y + ridhus.rekt.h,
			stall.rekt.y + stall.rekt.h) + 16, h = 1.7 },
		mot = { x = gardMitt, y = norraGard },
		krav = "Ridhuset till höger, stallet till vänster, och husen ska läsa som ETT komplex. Gavlarna ligger INTE i liv — stallet skjuter fram; storleken på förskjutningen är REFERENCE GAP.",
	},
	{
		id = "gardarna",
		grupp = "Komplexet",
		text = "Södra gårdsytan norrut, mot hästgången",
		fran = { x = gardMitt, y = sodraGard - 6, h = 1.7 },
		mot = { x = gardMitt, y = hg.rekt.y + hg.rekt.h / 2 },
		krav = "Gården ska STÄNGAS av hästgången. Ser man rakt igenom till nästa gårdsyta är förbindelsen fel byggd.",
	},

	--[[ ── Ridhuset inne ── en vy per yta Review 11 räknar upp. ]]
	{
		id = "banan",
		grupp = "Ridhuset inne",
		text = "Banan söderut från C-blocket — sand, sarg och A i söder",
		fran = { x = Ro.x + banMittX, y = Ro.y + banNorr - 2, h = 1.7 },
		mot = { x = Ro.x + banMittX, y = Ro.y + banSyd + B.h * 0.25 },
		aim = 1.1,
		krav = "Sanden dovt brungrå, inte ljus beige eller orange. Sargen ljus med mörkt sockelband. Gapet i norra sargens västra ände är SPELETS sargport — en SPELABSTRAKTION med gul genomskinlig markör, INTE verifierad UBRF-geometri (ingen bild visar en grind där; REFERENCE GAP). Bedöm sargen, inte gapet.",
	},
	{
		id = "sponsorvaggen",
		grupp = "Ridhuset inne",
		text = "Panelen med sponsorskyltarna och fönsterbandet ovanför",
		fran = { x = Ro.x + panelBetraktare, y = Ro.y + panelMittY, h = 1.7 },
		mot = { x = Ro.x + panelX, y = Ro.y + panelMittY },
		aim = panelToppH,
		krav = "Panelen på EN långsida och bara en DEL av den, med tre vita läkt. Sex skyltar hänger PÅ panelen. Fönsterbandet löper förbi panelens stycke, med poster som syns som poster.",
	},
	{
		id = "kortandan",
		grupp = "Ridhuset inne",
		text = "C-blocket vid norra änden — trappstegsblock, glasband, klocka och kompassros",
		fran = { x = Ro.x + kortandaMittX, y = Ro.y + kortandaBanKant - 16, h = 1.7 },
		mot = { x = Ro.x + kortandaMittX, y = Ro.y + kortandaBanKant },
		aim = kortandaKlockH,
		krav = "Block på sockel, två trappor med räcken, glasbandet BRUTET av trapporna, vit vägg mellan bänkarnas ovankant och glasets underkant, klockan mellan trapporna och kompassrosen vänster om den vänstra.",
	},
	{
		id = "domarbaset",
		grupp = "Ridhuset inne",
		text = "Domarbåset vid E, från banan",
		fran = { x = Ro.x + basBetraktare, y = Ro.y + R.domarbas.y, h = 1.7 },
		mot = { x = Ro.x + basX, y = Ro.y + R.domarbas.y },
		aim = 2.6,
		krav = "Båset står PÅ läktardäcket, utanför sargen — inte inne på banan. Sadeltak med utskjutande takfot, trappa med räcke på båda sidor, grön exit-skylt vid öppningen.",
	},
	{
		id = "takstommen",
		grupp = "Ridhuset inne",
		text = "Taket inifrån banan — balkar, stål, kabelstegar och ventilation",
		fran = { x = Ro.x + banMittX, y = Ro.y + banSyd + B.h * 0.35, h = 1.7 },
		mot = { x = Ro.x + banMittX, y = Ro.y + banSyd + B.h * 0.62 },
		aim = nockH,
		krav = "Takstolarna MÖRKT GRÅBRUNA och nära neutrala — inte varmt limträ som stallets. Stålprofiler tvärs balkarna, kabelstegar MED stegpinnar, runda ventilationskanaler. Taket ska läsa som konstruktion, inte som en platt skiva.",
	},
	{
		id = "laktaren",
		grupp = "Ridhuset inne",
		text = "Läktaren längs västra långsidan, obruten, med domarbåset",
		fran = { x = Ro.x + laktareBetraktare, y = Ro.y + R.domarbas.y, h = 1.7 },
		mot = { x = Ro.x + R.laktare.x0 + R.laktare.dackDjup / 2, y = Ro.y + R.domarbas.y },
		krav = "Läktaren på VÄSTRA långsidan, ett plant däck med solid front mot banan, utan gap. Domarbåset står på däcket med öppningen mot banan.",
	},
	{
		id = "grinden",
		grupp = "Ridhuset inne",
		text = "Grinden mot hästgången i östra sargen — mitt emot läktaren",
		fran = { x = Ro.x + B.x + B.w - 8, y = Ro.y + (R.sargGrind.y0 + R.sargGrind.y1) / 2, h = 1.7 },
		mot = { x = Ro.x + B.x + B.w, y = Ro.y + (R.sargGrind.y0 + R.sargGrind.y1) / 2 },
		krav = "Sargen ska ha en GRIND rakt fram, på sidan MITT EMOT läktaren. Är sargen obruten går det inte att leda hästen ut på banan.",
	},
	{
		id = "entrehallen",
		grupp = "Ridhuset inne",
		text = "Innanför huvudentrén (fasadens dörr under kvisten): den öppna entréhallen norrut, receptionens glas till höger, toaletterna i bortre hörnet",
		fran = { x = Ro.x + 1.3, y = Ro.y + 67.0, h = 1.7 },
		mot = { x = Ro.x + 1.3, y = Ro.y + 76.5 },
		krav = "Spatial Canon v2 (RIDHUS-V1/V3): entrédelen är EN öppen yta — ingen korridor av rumslådor, inga skåpkorridorväggar, ingen cellrad, inga rum mot nordöstra hörnet. Det enda som står är två smala toaletter i NV-hörnet (WALL, plan + PO), den kryssade rutan `schakt` som sluten volym UTAN namn (funktion REFERENCE GAP, får inte heta hiss) och receptionens GLASS-parti (låg bröstning + glas, ridhus-klubb-01/-02) — aldrig en opak låda. Varje vägg/glas bär CanonId/SourceId/Confidence. Inga uppfunna möbler.",
	},
	{
		id = "c_trapporna_fran_foten",
		grupp = "Ridhuset inne",
		text = "På översta bänkraden vid klockväggen: vänstra C-trappan stiger västerut längs gaveln upp till övre gången",
		fran = { x = Ro.x + 15.6, y = Ro.y + 69.6, h = (R.kortanda.sockelH or 0) + R.kortanda.steg * R.kortanda.stegH + 1.7 },
		mot = { x = Ro.x + 12.0, y = Ro.y + 69.6 },
		krav = "Product Owner 2026-09-03 (senior review 17:18): C-ändans TVÅ raka trappor med träräcke (ridhus-inne-01, IMG_0192-f01/-f02, ridhus-inne-07) — loppen går LÄNGS gaveln, foten vid klockväggen, stigande utåt (vänstra mot väster, högra mot öster) från översta bänkraden till caféplanet, med vitt snedställt sidostycke mot banan. Båda ska gå att KLIVA i Studio: spelets bänkradssteg vid blockets västra ände (Spelabstraktion bankradsteg — märkt spelabstraktion, inte fidelity), raderna, trappan (Trappa c_trappa_v/o steg 1–9) och in i övre gången (Övre gångens golv). Inget steg över 0,19 m. Ingen osynlig ramp.",
	},
	{
		id = "c_trapporna_fran_toppen",
		grupp = "Ridhuset inne",
		text = "I övre gången ovanför vänstra trappans topp: ner över loppet, bänkraderna och banan",
		fran = { x = Ro.x + 12.8, y = Ro.y + 71.2, h = R.cafe.z0 + 1.7 },
		mot = { x = Ro.x + 13.5, y = Ro.y + 66.0 },
		krav = "Samma trappor sedda uppifrån (ridhus-klubb-10: trappan ner, banan öppen): övre gången har golv på caféplanet norr om glasbandet, glasbandet är BRUTET där loppen står, och man kan gå ner för trappan till bänkraderna utan att fastna. Rummen innanför (Café Krubban) är REFERENCE GAP och ska inte vara byggda.",
	},
	{
		id = "entrehallen_mot_banan",
		grupp = "Ridhuset inne",
		text = "Från den öppna entréhallen söderut mot sargporten och banan",
		fran = { x = Ro.x + 2.0, y = Ro.y + 70.0, h = 1.7 },
		mot = { x = Ro.x + 2.0, y = Ro.y + 62.0 },
		krav = "Spatial Canon v2 (RIDHUS-V2, SCV2-03): kedjan huvudentré → öppen hall → sargport (SPELABSTRAKTION) → banan ska SYNAS som en öppen förbindelse och gå att gå utan att klippa, teleportera eller passera en fidelity-vägg. Ingen vägg och ingen möbel får skapa en smal korridor på vägen.",
	},

	--[[ ── Stallet inne ── servicevyn är den som tidigare underkändes. ]]
	{
		id = "servicedelen",
		grupp = "Stallet inne",
		text = "Servicedelen — spolspiltan, spånförrådet och gaveldagern",
		fran = { x = So.x + S.bredd / 2, y = So.y + serviceDjup + 4, h = 1.7 },
		mot = { x = So.x + S.bredd / 2, y = So.y + 1 },
		aim = 2.0,
		krav = "Båda serviceboxarna ÖPPNA mot gången, inte igenbommade rum. Ljusare servicegolv än gången. Dager från gavelöppningen, med exit-skylten ovanför.",
	},
	{
		id = "stallgangen",
		grupp = "Stallet inne",
		text = "Inne i gång A, mot hästförbindelsens brott i västra raden",
		fran = { x = So.x + gangAx, y = So.y + S.boxStartY + 2, h = 1.7 },
		mot = { x = So.x + gangAx, y = So.y + (S.brott[1].y0 + S.brott[1].y1) / 2 },
		krav = "Boxar på båda sidor, boxfronterna antracit med galvad ram och FEM liggande reglar. Västra raden ska ha ETT brott på hästgångens höjd; mittraderna fortsätter obrutna — ingen korridor tvärs huset.",
	},
	{
		id = "klubbdelen",
		grupp = "Stallet inne",
		text = "Innanför entrén: uppehållsrummet, med toaletterna och den inre entrén rakt fram",
		fran = { x = So.x + 4.55, y = So.y + 68.5, h = 1.7 },
		mot = { x = So.x + 4.55, y = So.y + S.klubb.y0 },
		krav = "Spatial Canon v2: uppehållsrummet är EN öppen L-formad yta (västdelen + östdelen öster om entrén) utan någon inre vägg eller sluten volym — den tidigare 1,0 × 4,4-volymen är återkallad av Product Owner. Planens symbolruta står som sluten volym utan namn till vänster (öster; funktion REFERENCE GAP), två toaletter i bortre änden (WC-V 3,0 m bred med dörr mot lobbyn) med den inre entrén emellan, och genom den stallgång A rakt fram. Varje vägg bär CanonId/SourceId/Confidence. Väggar mellan kameran och karaktären ska tona.",
	},
}


--[[ ── Visuell grind (issue #78) ── de tolv fasta reviewkamerorna, samma
	ID som qa/visual-gate/kameror.json. Kameran står som spelets egen
	tredjepersonskamera: 3,6 m bakom figuren, 2,25 m över hennes golv,
	blickpunkten 2,6 m framför henne (src/varld3d.js v3dKamera). `figur`
	är var karaktären står — tests/sikt.spec.luau skjuter sträckan kamera →
	figur genom de byggda delarna och kräver att allt som skymmer bär
	`Genomsiktlig` (tonas av Genomsikt på klienten). Lägena är uttryck i
	datan, som allt annat här. ]]
local function bakom(grupp: string, id: string, text: string, hus: any, ox: number, oy: number,
	fx: number, fy: number, z: number, rikt: number, krav: string)
	local cx, cy = math.cos(rikt), math.sin(rikt)
	-- Kameran hålls innanför väggarna (0,6 m), och kläms den in mot figuren
	-- lyfts den — samma regel som webbens v3dKamera.
	local kx = math.clamp(fx - cx * 3.6, 0.6, hus.bredd - 0.6)
	local ky = math.clamp(fy - cy * 3.6, 0.6, hus.langd - 0.6)
	local nara = math.sqrt((kx - fx) ^ 2 + (ky - fy) ^ 2)
	local h = 2.25 + (if nara < 2.0 then (2.0 - nara) * 0.9 else 0)
	return {
		id = id, grupp = grupp, text = text,
		fran = { x = ox + kx, y = oy + ky, h = h + z },
		mot = { x = ox + fx + cx * 2.6, y = oy + fy + cy * 2.6 },
		aim = 1.3 + z,
		figur = { x = ox + fx, y = oy + fy, z = z },
		krav = krav,
	}
end
local function rum(id: string)
	for _, r in ipairs(S.klubb.rum) do if r.id == id then return r.rekt end end
	error("hittar inte rummet " .. id)
end
local function dorr(hus: any, id: string)
	for _, d in ipairs(hus.dorrar) do if d.id == id then return d end end
	error("hittar inte dörren " .. id)
end
local function oppning(vaggId: string, id: string)
	for _, v in ipairs(S.klubb.vaggar) do
		if v.id == vaggId then
			for _, o in ipairs(v.oppningar or {}) do if o.id == id then return o end end
		end
	end
	error("hittar inte öppningen " .. id)
end
local function trappa(id: string)
	for _, t in ipairs(R.trappor or {}) do if t.id == id then return t end end
	error("hittar inte trappan " .. id)
end
local VG = "Visuell grind"
local gangA = (S.gangar.A.x0 + S.gangar.A.x1) / 2
local K = R.kortanda
local sadelO = oppning("genomgaende", "sadelkammare")
Vyer.reviewkameror = {
	--[[ Explicit kamera mot den låsta fasadens entrédörr (mitt på gaveln, läst ur
		G.byggnader stall, sida N, typ dorrgul) — samma som kameror.json. ]]
	(function()
		local hus
		for _, b in ipairs(G.byggnader) do if b.id == "stall" then hus = b end end
		local dorrX = S.bredd / 2
		for _, op in ipairs((hus and hus.oppningar) or {}) do
			if op.sida == "N" and op.typ == "dorrgul" then dorrX = S.bredd - op.u - op.b / 2 end
		end
		return {
			id = "STALL-ENTRE", grupp = VG,
			text = "Stallhuset entré — inne i uppehållsrummets östdel i ögonhöjd, norrut mot fasadens entrédörr mitt på gaveln",
			fran = { x = So.x + dorrX - 0.4, y = So.y + S.langd - 5.4, h = 1.7 },
			mot = { x = So.x + dorrX, y = So.y + S.langd },
			aim = 1.2,
			figur = { x = So.x + dorrX - 2.2, y = So.y + S.langd - 3.0, z = 0 },   -- till vänster om dörren, inte framför
			krav = "Fasadens entrédörr (ockragul, solfjäderfönster, vit karm) rakt fram med det västra runda fönstret bredvid; öppen yta fram till gaveln. Det östra runda fönstret hamnar i teorisalen — dokumenterad motsägelse (planens vindfång mot fasadens entré). Dörrbladets färg inifrån är [antagande].",
		}
	end)(),
	bakom(VG, "STALL-UPPEHALL", "Uppehållsrummet från södra änden (vid lobbyn) norrut genom hela rummet",
		S, So.x, So.y, 4.0, rum("uppehallsrum").y + 1.6, 0, math.pi / 2,
		"Rummets hela längd i ögonhöjd: västväggen till vänster, öppningen mot östdelen till höger UTAN vägg (Spatial Canon v2 stall_uppehall_open), planens symbolruta till höger, gaveln med entrén längst bort. Möbler (F02-B) saknas ännu."),
	bakom(VG, "STALL-TEORISAL", "Teorisalen innanför dörren i västväggen, österut",
		S, So.x, So.y, rum("teorisal").x + 1.3, rum("teorisal").y + 1.3, 0, 0,
		"Salens tre väggar med CanonId; dörröppningen i västväggen. Möbler saknas ännu."),
	bakom(VG, "STALL-SADELKAMMARE", "Inne i sadelkammaren, österut genom rummet mot östväggen",
		S, So.x, So.y, rum("sadelkammare").x + 4.2, rum("sadelkammare").y + 3.5, 0, 0,
		"Rummets östra hälft i ögonhöjd: östväggen (x 15,5), halvväggen i söder, norrväggen mot teorisalen. Inredning saknas ännu."),
	bakom(VG, "STALL-GANG-A", "Gång A norrut mot klubbdelen",
		S, So.x, So.y, gangA, S.boxStartY + 6, 0, math.pi / 2,
		"Boxfronter i antracit med galvad ram på båda sidor, markstensgång, klubbdelens tvärvägg långt fram."),
	--[[ Explicit kamera (som i kameror.json): följkameran får inte plats i
		gången utan att backa in i boxraden, så reviewkameran står själv vid
		gång A:s östra kant i ögonhöjd och ser västerut genom brottet. ]]
	{
		id = "HASTPASSAGE", grupp = VG,
		text = "Från gång A:s östra kant i ögonhöjd, västerut genom brottet i västra boxraden in i hästgången",
		fran = { x = So.x + S.gangar.A.x1 - 0.2, y = So.y + dorr(S, "hastgang").pos[2] + 0.9, h = 1.7 },
		mot = { x = So.x + 0.9, y = So.y + dorr(S, "hastgang").pos[2] },
		aim = 1.2,
		figur = { x = So.x + S.gangar.A.x0 + 0.6, y = So.y + dorr(S, "hastgang").pos[2], z = 0 },
		krav = "ETT brott i västra boxraden på hästgångens höjd med dörrmarkören, boxfronter på båda sidor om brottet, figuren i gångens västra kant. Ingen tvärkorridor genom huset. Passagens insida är REFERENCE GAP.",
	},
	bakom(VG, "RIDHUS-ENTRE", "Huvudentrén norrut över entré/reception",
		R, Ro.x, Ro.y, dorr(R, "ut_ridhus_W_9").pos[1] - 0.3, dorr(R, "ut_ridhus_W_9").pos[2] - 0.2, 0, math.pi / 2,
		"Öppen hall utan rumslådor, receptionens glas (GLASS) till höger, toaletterna i bortre hörnet."),
	bakom(VG, "RIDHUS-SKAPKORRIDOR", "Den öppna gången där skåpen står, norrut",
		R, Ro.x, Ro.y, 4.95, R.entrehall.y0 + 2.3, 0, math.pi / 2,
		"Ingen korridorvägg (återkallade skap_v/skap_o). Skåpen är möbler (F02-B) och saknas ännu."),
	bakom(VG, "ARENA-A", "Banan nära A, söderut mot kortsidan",
		R, Ro.x, Ro.y, R.bana.x + R.bana.w / 2, R.bana.y + 6, 0, -math.pi / 2,
		"Vit sarg med mörk sockel, A-skylten på sargen, sanden dovt brungrå."),
	bakom(VG, "ARENA-C", "Banan nära C, norrut mot C-blocket",
		R, Ro.x, Ro.y, R.bana.x + R.bana.w / 2, R.bana.y + R.bana.h - 8, 0, math.pi / 2,
		"C-blockets bänkrader, klockväggen, de två trapporna med vita sidostycken, glasbandet i tre fält."),
	bakom(VG, "LAKTARE", "Läktardäcket söderut",
		R, Ro.x, Ro.y, R.laktare.x0 + R.laktare.dackDjup / 2, (R.laktare.y0 + R.laktare.y1) / 2 + 6, R.laktare.dackZ, -math.pi / 2,
		"Plankdäck, mörk front med ljus kappregel, räcket, banan till vänster. Domarbåset står på däcket."),
	bakom(VG, "C-BLOCK-OVRE", "Från nedersta bänkraden vid klockan (som ridhus-inne-01)",
		R, Ro.x, Ro.y, K.klocka.x, K.y0 + 0.6, (K.sockelH or 0) + K.stegH, math.pi / 2,
		"Raderna, de två loppen stigande utåt, klockväggen, glasbandet, övre gången bakom. Spelets bänkradssteg (gul markör) är SPELABSTRAKTION."),
}
for _, v in ipairs(Vyer.reviewkameror) do table.insert(Vyer.vyer, v) end

local ORDNING = { "Komplexet", "Ridhuset inne", "Stallet inne", VG }

function Vyer.lista()
	print(string.format("Vyer för Gate F01 · Studio-kontroll enligt Review 11 · %d vyer",
		#Vyer.vyer))
	print("Checklista: roblox/docs/STUDIO-QA.md")
	for _, grupp in ipairs(ORDNING) do
		print("\n  " .. grupp)
		for _, v in ipairs(Vyer.vyer) do
			if v.grupp == grupp then
				print(string.format("    Vyer.ga(\"%s\")%s— %s",
					v.id, string.rep(" ", math.max(1, 18 - #v.id)), v.text))
			end
		end
	end
	print("\nKör Vyer.ga(id) och ta en skärmdump från var och en.")
	print("Skriv för varje avvikelse vad du SÅG och VAR — inte gissad orsak.")
end

function Vyer.ga(id: string)
	for _, v in ipairs(Vyer.vyer) do
		if v.id == id then
			local modell = workspace:FindFirstChild("Anläggning")
			local ubrf = modell and modell:FindFirstChild("UBRF")
			local bas = ubrf and ubrf.PrimaryPart and ubrf.PrimaryPart.CFrame
			if not bas then error("bygg Anlaggningen.luau först") end
			BK.cameraLike(bas, v.fran.x, v.fran.y, v.mot.x, v.mot.y, v.fran.h, v.aim)
			print("── " .. v.text)
			print("   Att titta efter: " .. v.krav)
			return
		end
	end
	error("okänd vy: " .. id .. " — kör Vyer.lista()")
end

return Vyer
