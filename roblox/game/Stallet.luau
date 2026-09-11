--!strict
--[[ STALLET — vilken häst som är din, och var hon står.

	Ren logik, inga Roblox-anrop. Det är med flit: det här är regler, och
	regler ska gå att prova utan Studio. StallService gör instanserna.

	Boxarnas LÄGEN kommer ur UBRFKomplex.stall — samma mätta data som
	byggnaden byggs av. Ingen koordinat är skriven här.

	VILKEN häst som står i VILKEN box är däremot [antagande]. Det finns inget
	verifierat underlag för UBRF:s faktiska boxfördelning, och jag hittar inte
	på en. Fördelningen här är spelmekanik: stabil, jämnt spridd över
	stallets fyra rader, och utbytbar den dag verkligheten säger något annat.
]]

local Stallet = {}

local RS = game:GetService("ReplicatedStorage")
local Spel = require(RS.UBRFSpel)
local G = require(RS.UBRFKomplex)

local S = G.stall

--[[ FÖRSTA DAGENS HÄST. Produktregel, inte spelmekanik: en ny spelares
	första dag rids på Blackrock Jack.

	Webbens motsvarighet är `FORSTA_DAGEN_HAST` i `src/scenes.js`. Att den
	står på två ställen är en dubbel sanning, och därför vaktas de mot
	varandra av `tools/kolla-forstadagen.py` i CI — ändras den ena utan den
	andra faller grinden. Regeln hör hemma HÄR på Roblox-sidan, i modulen
	som äger tilldelningen; `scenes.js` är webbens vy-lager. ]]
Stallet.FORSTA_DAGEN_HAST = "blackrock_jack"

--[[ Boxrutnätet härleds ur stalldatan i stället för att räknas upp:
	fyra rader × antalBoxar per rad. Ändras stallet följer boxarna med.

	OBS: DET HÄR ÄR NUMRERINGSRYMDEN, INTE ANTALET BOXAR SOM FINNS.

	Talet är 52 (4 × 13) medan världen bygger 49 fack, och skillnaden
	rapporterades som en odiagnostiserad diskrepans i runtime-QA:n. Den är
	inte en bugg: `S.brott` skär två passager genom raderna, och de facken
	finns inte. `hastgang` tar ett fack ur rad W (12 kvar) och `ostport` två
	ur rad E (11 kvar) — 13 + 13 + 12 + 11 = 49.

	`box(n)` returnerar därför `nil` för just de tre numren, med flit: en
	påhittad koordinat hade varit värre än ett nil. Den som räknar boxar ska
	räkna `S.fack`, inte det här talet. Förhållandet mäts i
	`spelbarhet.spec` så att det inte kan glida tyst. ]]
function Stallet.boxantal(): number
	return #S.rader * S.antalBoxar
end

--[[ Box nummer n (1-baserat) → rad, plats i raden, och mittpunkt i
	VÄRLDSKOORDINATER. Ordningen är rad för rad, norrut i varje rad. ]]
function Stallet.box(n: number)
	local antal = Stallet.boxantal()
	if n < 1 or n > antal then return nil end

	local radIndex = math.floor((n - 1) / S.antalBoxar) + 1
	local plats = (n - 1) % S.antalBoxar + 1
	local rad = S.rader[radIndex]

	--[[ BOXENS KROPP LIGGER ALLTID [x0, x0 + djup] — `vetter` säger vilken
		SIDA fronten sitter på, inte åt vilket håll boxen sträcker sig.

		Den här raden löd förut `x0 + rad.vetter * rad.djup / 2`, och för de
		två rader som vetter åt −x (MA och E) hamnade mittpunkten då på FEL
		sida om x0 — mitt i gången. Sexton av trettiotre hästar stod alltså
		i stallgången i stället för i sin box, och boxmarkören med dem.

		Att det är kroppen och inte vändningen som avgör syns i bygget:
		`byggBoxrader` lägger radens kropp på `x0 .. x0 + djup` oavsett
		`vetter` och använder `vetter` bara för att välja `fx`, frontens
		x-läge. Gångarna i `S.gangar` ligger dessutom mellan raderna, och
		den gamla formeln lade mittpunkten precis där.

		Fångat av `topologi.spec`, som frågar vilken ZON en punkt ligger i
		i stället för att jämföra ett tal med sig självt. ]]
	local x0 = rad.x0
	local xMitt = x0 + rad.djup / 2

	--[[ LÄNGS raden läses facken, inte en jämn stege.

		`S.boxStartY + (plats - 0.5) * S.boxB` antar tretton lika breda
		fack från stallets södra ände. Rad W har TOLV: `S.brott` tar bort
		ett fack där hästgången korsar raden, och `S.fack.W` saknar det
		spannet. Den jämna stegen räknade därför fel för varje plats efter
		brottet, och en häst hamnade mitt i hästgångens passage.

		Facken är samma lista bygget lägger boxväggarna av (`GEO.boxfack`
		läser den), så det här är inte en andra sanning utan densamma.

		Saknas facket finns ingen box på platsen, och då sägs det — en
		påhittad koordinat hade varit värre än ett nil. ]]
	local fack = (S.fack or {})[rad.id]
	local f = fack and fack[plats]
	if fack and not f then return nil end
	local yMitt = if f then (f.y0 + f.y1) / 2
		else S.boxStartY + (plats - 0.5) * S.boxB
	--[[ Fackets ändar behövs för att veta var frontens TÄTA panel slutar och
		boxdörren börjar — se `utrustningsplats`. ]]
	local yLag = if f then f.y0 else yMitt - S.boxB / 2
	local yHog = if f then f.y1 else yMitt + S.boxB / 2

	--[[ BOXFRONTENS YTTERSIDA — den sida som vetter mot gången.

		Kroppen ligger alltid [x0, x0 + djup]; `vetter` säger vilken ände
		fronten sitter i. Bygget lägger frontpanelen med `fx` och tjockleken
		0,06 in mot boxen, så den yta spelaren ser från gången ligger på
		`x0 + djup` respektive `x0`. Talet härleds därför ur samma två fält
		bygget läser och skrivs inte av här.

		Det här är ANKARET för allt som hänger på fronten. ]]
	local fx = if rad.vetter > 0 then x0 + rad.djup else x0

	return {
		nummer = n,
		rad = rad.id,
		plats = plats,
		gang = rad.gang,
		vetter = rad.vetter,
		lokal = { x = xMitt, y = yMitt },
		varld = { x = S.origo.x + xMitt, y = S.origo.y + yMitt },
		front = { x = fx, y = yMitt },
		frontVarld = { x = S.origo.x + fx, y = S.origo.y + yMitt },
		fack = { y0 = yLag, y1 = yHog },
	}
end

--[[ ── UTRUSTNINGEN PÅ BOXFRONTEN ─────────────────────────────────────

	`references/buildings/stall/KORT.md` § Boxarna från gången, ur filmen:

	    "På fronterna hänger sadlar med underlag, täcken, grimmor, träns
	     och benskydd — mycket saker, tätt."

	Det är den ENDA verifierade platsen i UBRF där sadlar och träns finns.
	Sadelkammarens egen bild (`stall-inne-03-sadelkammaren.jpg`) visar
	uttryckligen INGA sadelbockar — bara säkerhetsvästar på krokrader och en
	hylla med stövlar — och F02-B har redan fällt det som `REFERENCE GAP`.
	Att ställa sadelbockar där hade varit att hitta på en UBRF-detalj för att
	fylla ett hål, och det får inte göras.

	Så: dagens sadel och träns hänger på DIN hästs egen boxfront, och det är
	dit spelaren skickas.

	HUR LÅNGT UT är spelabstraktion — filmen mäter ingenting. VAR LÄNGS
	fronten är det inte: sakerna hänger på den TÄTA PANELEN, aldrig i
	boxdörrens öppning. En sadel i dörrgapet hade sett ut som en sadel i
	vägen, och hade stått där hästen ska gå ut. ]]
local UT_AVSTAND = 0.28          -- hur långt ut i gången krokarna sticker
local PANELMARGINAL = 0.08       -- samma marginal fronten byggs med

--[[ Var hänger `sort` ("sadel" / "trans") för den här hästen?

	Ren geometri, inga instanser: platsen ska gå att prova utan Studio, och
	riggen ska inte kunna ha en egen mening om var utrustningen sitter.

	PANELENS UTBREDNING RÄKNAS UR SAMMA TVÅ FÄLT BYGGET LÄSER — `S.boxB` och
	`boxfront.dorr.bredd`. Det är ändå en härledning på två ställen, så den
	VAKTAS av en mätning mot den byggda världen i `spelbarhet.spec`: varje
	sak ska ligga inom sin boxfronts panel och utanför sin boxdörr. Skulle
	bygget flytta dörren blir mätningen röd, inte tyst fel. ]]
function Stallet.utrustningsplats(hastId: string, sort: string)
	local box = Stallet.boxFor(hastId)
	if not box then return nil end
	if sort ~= "sadel" and sort ~= "trans" then return nil end

	local BF = (G.identitet and G.identitet.stall and G.identitet.stall.boxfront) or {}
	local frontL = S.boxB - 2 * PANELMARGINAL
	local dorrB = if BF.dorr then math.min(BF.dorr.bredd, frontL - 0.30) else 0
	local fastL = frontL - dorrB

	--[[ Panelen börjar i fackets lägre ände; dörren tar dess bortre del.
		Sadeln på första tredjedelen av panelen, tränset på andra — två
		lägen med luft emellan, båda på tät panel. ]]
	local panelStart = box.fack.y0 + PANELMARGINAL
	local del = if sort == "sadel" then 1 else 2
	local y = panelStart + fastL * del / 3

	return {
		nummer = box.nummer,
		rad = box.rad,
		gang = box.gang,
		vetter = box.vetter,
		lokal = { x = box.front.x + box.vetter * UT_AVSTAND, y = y },
		varld = { x = box.frontVarld.x + box.vetter * UT_AVSTAND,
			y = S.origo.y + y },
	}
end

--[[ Hästarnas boxar sprids över raderna i stället för att fylla en rad i
	taget. Annars står alla sjutton i rad W och stallets andra halva är tom,
	vilket ser ut som ett fel även om det inte är ett. ]]
function Stallet.boxNummerFor(hastId: string): number?
	local index = nil
	for k, id in ipairs(Spel.ordning) do
		if id == hastId then index = k break end
	end
	if not index then return nil end

	local rader = #S.rader
	local rad = (index - 1) % rader                    -- 0-baserad rad
	local plats = math.floor((index - 1) / rader)      -- 0-baserad plats
	if plats >= S.antalBoxar then return nil end
	return rad * S.antalBoxar + plats + 1
end

function Stallet.boxFor(hastId: string)
	local n = Stallet.boxNummerFor(hastId)
	return n and Stallet.box(n) or nil
end

--[[ Tilldelningen ska vara STABIL: samma spelare ska möta samma häst när hon
	kommer tillbaka, annars finns det inget förhållande att bygga. Den ska
	också vara förutsägbar i prov, alltså ingen slump.

	Här stod först math.abs(userId), med kommentaren att det skyddade mot de
	negativa UserId Studio ger i Play Solo. Falsifieringen visade att provet
	INTE föll när abs togs bort: Luas modulo följer divisorns tecken, så
	-12345 % 17 är 14, inte -14. Skyddet var alltså dött och kommentaren
	påstod något den inte gjorde. Provet står kvar — att negativa id fungerar
	är fortfarande värt att hålla fast — men koden låtsas inte längre. ]]
function Stallet.tilldela(userId: number): string
	local n = #Spel.ordning
	return Spel.ordning[(userId % n) + 1]
end

--[[ Tilldelning när någon annan redan står i boxen.

	`tilldela` ovan är ren modulo, och med 33 hästar betyder det att spelare
	vars UserId skiljer sig med 33 får SAMMA häst. På en ensam server syns
	det aldrig; med två spelare inne blir samma individ ledd ut ur boxen
	två gånger. G01-S2b:s acceptanskrav 3 förbjuder det.

	Regeln: börja på den häst spelaren skulle fått ändå och gå framåt tills
	en är ledig. Det bevarar stabiliteten — är din häst inte upptagen får du
	henne, varje gång — och ger ett förutsägbart andrahandsval i stället för
	slump.

	Är hela stallet upptaget returneras nil. Det är MENINGEN: hellre "vänta,
	det finns ingen häst åt dig just nu" än två ryttare på samma häst. ]]
--[[ Vilar hästen för en skada?

	Samma innebörd som webbens `hastVilarForSkada` i `src/ryttare.js`, och
	samma minnesform: `{ skada = { passKvar = n } }`. Regeln bor här och
	inte i tjänstelagret av samma skäl som resten av modulen — den ska gå
	att fälla i bänken utan Studio. ]]
function Stallet.vilarForSkada(minne: any?): boolean
	if type(minne) ~= "table" then return false end
	local skada = minne.skada
	if type(skada) ~= "table" then return false end
	local kvar = tonumber(skada.passKvar)
	return kvar ~= nil and kvar > 0
end

--[[ Vilka hästar som vilar, härlett ur spelarens sparade hästminnen. ]]
function Stallet.vilandeHastar(minnen: { [string]: any }?): { [string]: boolean }
	local ut: { [string]: boolean } = {}
	if type(minnen) ~= "table" then return ut end
	for id, m in pairs(minnen) do
		if Stallet.vilarForSkada(m) then ut[id] = true end
	end
	return ut
end

--[[ `vilande` är TVÅ nivåer, inte en till upptagen-lista.

	`upptagna` är schema: hästen är frisk, någon annan rider henne just nu.
	`vilande` är välfärd: hästen är skadad och ska inte arbeta alls. Båda
	utesluter, men de betyder olika saker, och därför står de isär — den
	dagen någon vill mjuka upp schemakravet får välfärden inte följa med.

	Webbens motsvarande spärr (#153 fix 1, PR #154) hade ett hål som den
	här inte har: när poolen tog slut föll den tillbaka på den OFILTRERADE
	listan och delade ut precis de skadade hästar filtret plockat bort.
	Här returneras nil, precis som när stallet är fullt — se kommentaren
	ovan. Tomt är ett riktigt svar, inte ett fel att gissa sig ur. ]]
--[[ `onskad` är en NAMNGIVEN häst som måste bli det, eller inget alls.

	Den finns för första dagen (#162 blockerare 3). Före den fick en ny
	spelare vilken häst som helst ur rotationen: `tilldelaLedig` såg varken
	saven eller `Sparning.forstaDagen`, och produktkravet "ny spelare →
	Jack" var därför inte uppfyllt i produktionen — bara i ett prov som
	byggde Jack för handen.

	ÖNSKAN GÅR GENOM SAMMA TVÅ GRINDAR som allt annat. Är hästen upptagen
	av någon annan, eller vilar hon för en skada, blir svaret nil — alltså
	VÄNTELÄGE, inte en ersättare. Att tysta ersätta Jack hade brutit
	produktregeln; att kringgå reservationen eller välfärden hade brutit
	#154. Nil är det enda svaret som håller båda, och det är samma svar
	webben ger i `visaIngenHastIdag`. ]]
function Stallet.tilldelaLedig(userId: number, upptagna: { [string]: boolean }?,
	vilande: { [string]: boolean }?, onskad: string?): string?
	local n = #Spel.ordning
	if n == 0 then return nil end
	local taget = upptagna or {}
	local vilar = vilande or {}
	if onskad ~= nil then
		if Spel.hastar[onskad] and not taget[onskad] and not vilar[onskad] then
			return onskad
		end
		return nil
	end
	local start = userId % n
	for steg = 0, n - 1 do
		local id = Spel.ordning[(start + steg) % n + 1]
		if not taget[id] and not vilar[id] then return id end
	end
	return nil
end

--[[ Allt en spelare behöver veta vid ankomsten, i ett svar. ]]
--[[ Hästens kanoniska spelvärden, översatta till Config.STATS namn.

     ETT ÖVERSÄTTNINGSLAGER OCH INGET ANNAT. Talen kommer ur
     UBRFSpelData, som genereras ur src/spel/hastar.js; det enda som
     händer här är att `kanslighet` blir `Kanslighet` och så vidare, så
     att `Config.resolveStats` kan läsa dem som vilka attribut som helst.

     Att det behövs alls är blocker 1 i re-reviewen: profilerna fanns i
     datat och provades syntetiskt, men den verkliga vägen
     tilldelning → bindning → uppsittning → MovementController tappade
     dem, och varje häst red som `skolhast`. ]]
function Stallet.statsFor(id: string): { [string]: any }?
	local h = Spel.hastar[id]
	if not h then return nil end
	return {
		Profil = h.profil,
		Forlatande = h.forlatande,
		Skygghet = h.skygghet,
		--[[ KÄNSLIGHETEN GÅR MED SOM TAL sedan blocker 2 i senior
		     re-review av #87. Den räknades förut bara ur temperamentet,
		     och trösklarna nedan kvantiserade bort hästen: 0,78 och 0,71
		     blev båda "Sensitive" och därmed samma 1,00 i modellen.
		     Cross-platform-scenariot mätte upp priset.

		     Temperamentet sätts fortfarande, för det styr mer än
		     känsligheten (accelBias, animation, ridkänsla), och trösklarna
		     följer Config.TEMPERAMENTS egna reactGain-nivåer. ]]
		Kanslighet = h.kanslighet,
		Temperament = if (h.kanslighet or 0.5) >= 0.70 then "Sensitive"
			elseif (h.kanslighet or 0.5) >= 0.55 then "Energetic"
			elseif (h.kanslighet or 0.5) <= 0.35 then "Brave"
			else "Calm",
		--[[ Tyngd och framåtbjudning är webbens namn på det Roblox kallar
		     Acceleration och Speed. Samma roll, andra ord. ]]
		Acceleration = 1 - (h.tyngd or 0.4),
		Speed = h.framatbjudning,
		Agility = h.utbildning,
		Endurance = h.forlatande,
	}
end

function Stallet.dagensHast(userId: number, upptagna: { [string]: boolean }?,
	vilande: { [string]: boolean }?, onskad: string?)
	local id = Stallet.tilldelaLedig(userId, upptagna, vilande, onskad)
	if not id then return nil end
	local hast = Spel.hastar[id]
	if not hast then return nil end
	return {
		id = id,
		namn = hast.namn,
		ras = hast.ras,
		typ = hast.typ,
		besk = hast.besk,
		foder = Spel.foder[id],
		box = Stallet.boxFor(id),
		--[[ Hästens SPELVÄRDEN följer med tilldelningen (senior re-review
		     #87, blocker 1). De låg i UBRFSpelData men nådde aldrig den
		     häst spelaren faktiskt red: `resolveStats` läste bara Studio-
		     attribut, så varje individ blev `skolhast` med standardvärden
		     hur noga profilerna än var tilldelade. ]]
		stats = Stallet.statsFor(id),
	}
end

return Stallet
