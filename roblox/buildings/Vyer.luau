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

local ORDNING = { "Komplexet", "Ridhuset inne", "Stallet inne" }

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
