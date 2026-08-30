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
		text = "Banan söderut — sand, sarg och porten vid A",
		fran = { x = Ro.x + banMittX, y = Ro.y + banNorr + 2, h = 1.7 },
		mot = { x = Ro.x + banMittX, y = Ro.y + banSyd + B.h * 0.25 },
		aim = 1.1,
		krav = "Sanden dovt brungrå, inte ljus beige eller orange. Sargen ljus med mörkt sockelband, och porten vid A ska vara ett GAP i norra kortsidan — inte en vägg.",
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
		text = "Kortändan vid C — trappstegsblock, glasband, klocka och kompassros",
		fran = { x = Ro.x + banMittX, y = Ro.y + K.y1 + 16, h = 1.7 },
		mot = { x = Ro.x + kortandaMittX, y = Ro.y + K.y0 },
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
		text = "Läktaren och gapet med grinden mot hästgången",
		fran = { x = Ro.x + laktareBetraktare,
			y = Ro.y + (R.laktare.gap.y0 + R.laktare.gap.y1) / 2, h = 1.7 },
		mot = { x = Ro.x + R.laktare.x0 + R.laktare.dackDjup / 2,
			y = Ro.y + (R.laktare.gap.y0 + R.laktare.gap.y1) / 2 },
		krav = "Läktaren ska ha ett GAP rakt fram, och sargen en GRIND i det gapet. Är sargen obruten går det inte att leda hästen ut på banan.",
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
		text = "Inne i gång A, mot tvärkorridoren",
		fran = { x = So.x + gangAx, y = So.y + S.boxStartY + 2, h = 1.7 },
		mot = { x = So.x + gangAx, y = So.y + (S.tvarGang.y0 + S.tvarGang.y1) / 2 },
		krav = "Boxar på båda sidor, boxfronterna antracit med galvad ram och FEM liggande reglar. Tvärkorridoren ska synas hela vägen tvärs huset.",
	},
}

local ORDNING = { "Komplexet", "Ridhuset inne", "Stallet inne" }

function Vyer.lista()
	print("Vyer för Gate F01 · Studio-kontroll enligt Review 11")
	print("Checklistor: roblox/docs/RIDHUS-STUDIO-CHECKLISTA.md (ridhuset inne)")
	print("             roblox/buildings/STUDIO-KONTROLL.md (komplexet och stallet)")
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
