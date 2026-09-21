--!strict
--[[
	UGNETA-TEMA — ETT aktivt tema per pass, och tystnad om allt annat.

	── VARFÖR MODULEN FINNS ──────────────────────────────────────────

	`Lektion.liveCue` valde den SVAGASTE dimensionen i den aktuella
	bildrutan. Det låter rimligt och är fel pedagogik: den dimension som
	råkar vara svagast växlar från sekund till sekund, så Ugneta hoppade
	mellan «Mjukare hand», «Sitt stilla» och «Titta dit du ska» under
	samma volt. En ryttare som får tre olika saker att tänka på hinner
	inte med någon av dem.

	Webbens `src/larare.js` har haft rätt modell hela tiden: `LARARE.fokus`
	väljs EN gång och hålls. Roblox-sidan skrev till och med ut avvikelsen
	i klartext (`src/larare.js` rad 438): «Roblox har ingen sådan modell
	ännu och väljer i stället ur dimensionerna». Den här modulen stänger
	den luckan.

	── VAD SOM PORTERAS, OCH VAD SOM INTE GÖR DET ────────────────────

	Porterat är AVSIKTEN och REGLERNA, inte implementationen:

	  ett aktivt tema · temafiltrerad signal · mönster före kommentar ·
	  cooldown utan kö · hästens dagsform skild från ryttarens fel

	INTE porterat är webbens viktning av vilket tema som väljs. Den läser
	`fard()` — en ryttarmodell med sits, hand och känsla som Roblox inte
	har. Att hitta på en motsvarighet vore att uppfinna produkt. Temat
	väljs därför ur det Roblox FAKTISKT mäter: den svagaste dimensionen
	i snitt över passets första `VAL_SEK` sekunder. Skillnaden mot förr
	är inte i första hand VILKEN dimension som väljs — det är att valet
	görs EN gång, på ett snitt i stället för på en bildruta.

	[REFERENCE GAP] Webbens temabyte mitt i passet (`LARARE.bytt`, efter
	tre beröm och 210 s) är inte porterat. Det kräver berömräkningen och
	en passlängd Roblox inte har samma begrepp för. Ett tema per pass är
	det som gäller här tills produktbeslut säger annat.
]]

local RidKanon = require(script.Parent.RidKanon)

local UG = RidKanon.UGNETA
local KV = UG.KVALITET

local UgnetaTema = {}

--[[ ── PARAMETRARNA, OCH VAR DE KOMMER IFRÅN ────────────────────────

	De tre första speglar webbens literaler i `lararSteg`. De står som
	namngivna konstanter här därför att en falsifiering ska kunna ändra
	EN sak och se provet bli rött — en literal inne i ett uttryck går
	inte att prova utan att skriva om koden runt den.

	`SVAG_SEK` har ingen motsvarighet på webben. Webben kommenterar ett
	fel direkt; QA-reviewen av `082062c` kräver uttryckligen mönster före
	kommentar, så den regeln är NY och gäller tills vidare bara här.
	Det är en avvikelse åt det försiktiga hållet: Roblox säger mindre än
	webben, aldrig mer. ]]
UgnetaTema.VAL_SEK = 3             -- så länge tittar hon innan hon bestämmer dagens tema
UgnetaTema.SVAG_SEK = 2.5          -- så länge måste det vara svagt innan hon säger till
UgnetaTema.BEROM_SEK = 6           -- webbens `LARARE.brasedan > 6`
UgnetaTema.SPANNING_TROSKEL = 0.55 -- webbens `G.ride.spanning > 0.55`
UgnetaTema.SKYGG_TROSKEL = 0.28    -- webbens `(h.skygghet||0) > 0.28`
UgnetaTema.DAGSFORM_TROSKEL = 0.55 -- webbens `G.dagsform < 0.55`
UgnetaTema.ATTRIBUT_CD = 26        -- webbens `LARARE.attributCd = 26`

export type Tema = {
	--[[ `nil` så länge hon fortfarande tittar. Se `VAL_SEK`. ]]
	dim: string?,
	cue: string?,
	valtid: number,
	summa: { [string]: number },
	vikt: { [string]: number },
	cd: number,
	sagt: string,
	svagSedan: number,
	braSedan: number,
	attributCd: number,
}

--[[ ── HON TITTAR INNAN HON BESTÄMMER ──────────────────────────────

	Första versionen valde tema ur EN bildruta. Det var ömtåligt på ett
	sätt som provet genast visade: den dimension som råkade vara svagast
	i uppsittningsögonblicket blev dagens tema för hela passet, även när
	ritten sedan visade något helt annat. Ett ögonblicksvärde är inte ett
	omdöme.

	Hon samlar därför `VAL_SEK` sekunder av mätning först och väljer på
	SNITTET. Under tiden är hon tyst — vilket är rätt även pedagogiskt:
	en ridlärare tittar en stund innan hon säger vad dagen ska handla om.

	Snittet viktas med `dt`, inte med antal bildrutor, av samma skäl som
	`Lektion.matning`: en snabb klient ska inte få ett annat tema än en
	långsam på samma ritt. ]]
function UgnetaTema.valj(tema: Tema, dimensioner: { string }): string?
	local svag, svagV = nil, math.huge
	for _, k in dimensioner do
		local w = tema.vikt[k]
		if w and w > 0 then
			local snitt = tema.summa[k] / w
			if snitt < svagV then svag, svagV = k, snitt end
		end
	end
	return svag
end

--[[ Ett nytt tema för passet — ännu OVALT. Valet sker i `steg`, när det
     finns underlag. Att välja här hade krävt en mätning som inte finns
     när övningen just börjat. ]]
function UgnetaTema.nytt(ovningId: string): Tema
	return {
		dim = nil, cue = nil,
		valtid = 0, summa = {}, vikt = {},
		cd = 0, sagt = "",
		svagSedan = 0, braSedan = 0, attributCd = 0,
	}
end

--[[ ── HÄSTENS DAG ELLER RYTTARENS FEL? ─────────────────────────────

	Webbens regel: är hästen skygg eller i dålig dagsform tillskrivs
	spänningen HENNE, inte ryttaren.

	OCH DET VIKTIGA OMVÄNDA: vet vi inte tillräckligt om hästen svarar
	funktionen `nil` — «går inte att avgöra» — och anroparen tiger. Att
	falla tillbaka på «då var det nog ryttaren» hade varit att skylla på
	spelaren på saknad evidens, och det är precis det den här grinden
	finns för att hindra.

	── PARTIELL KONTEXT ÄR OCKSÅ OKÄND (re-review av `269bec5`) ──────

	Första versionen krävde bara att NÅGOT fält fanns. En häst med känd
	skygghet men okänd dagsform frikändes därför: `skygghet = 0.05`
	svarade `false`, alltså «det var inte hennes dag» — fast dagsformen
	var det enda som kunde ha sagt det. Ryttaren fick rättelsen.

	Regeln är därför asymmetrisk, och asymmetrin är hela poängen:

	  ETT känt fält som säger JA räcker — hon HAR en dålig dag, och
	  resten kan inte göra det osant.

	  Ett NEJ kräver att ALLA fält är kända. Så länge något saknas kan
	  det saknade vara just det som skulle ha sagt ja.

	Bevisbördan ligger alltså på den som vill lägga felet på spelaren. ]]
UgnetaTema.HAST_FALT = { "skygghet", "dagsform" }

function UgnetaTema.hastensEgen(hast: { [string]: any }?): boolean?
	if hast == nil then return nil end
	local saknas = false
	for _, falt in UgnetaTema.HAST_FALT do
		local v = hast[falt]
		if type(v) ~= "number" then
			saknas = true
		elseif falt == "skygghet" and v > UgnetaTema.SKYGG_TROSKEL then
			return true
		elseif falt == "dagsform" and v < UgnetaTema.DAGSFORM_TROSKEL then
			return true
		end
	end
	--[[ Inget känt fält sa ja. Säger vi nej nu måste vi ha sett allt. ]]
	if saknas then return nil end
	return false
end

--[[ ── ETT STEG ──────────────────────────────────────────────────────

	Svaret är `(text, bra, kalla)`. Tom text betyder tystnad, och tystnad
	är det normala: hon säger något bara när det finns ett MÖNSTER att
	säga något om.

	`kalla` är "" vid tystnad, annars "tema" eller "hast" — så att en
	anropare, och ett prov, kan skilja en rättelse till ryttaren från ett
	konstaterande om hästen utan att läsa texten.

	COOLDOWN UTAN KÖ. Ligger `cd` kvar räknas den ner och funktionen
	svarar tyst — den lägger INGENTING på hyllan. När spärren släpper
	fattas beslutet på det som gäller DÅ. En kö hade betytt att spelaren
	får höra om ett fel hon rättade för tio sekunder sedan. ]]
function UgnetaTema.steg(tema: Tema, dt: number,
	kvalitet: { [string]: number? }, hast: { [string]: any }?,
	spanning: number?, dimensioner: { string }?): (string, boolean, string)

	tema.cd -= dt
	tema.attributCd -= dt

	--[[ ── FASEN FÖRE VALET ────────────────────────────────────────
		Hon samlar underlag och säger ingenting. Tystnaden är inte ett
		glapp — den är regeln. ]]
	if tema.dim == nil then
		local dims = dimensioner
		if dims == nil then return "", false, "" end
		tema.valtid += dt
		for _, k in dims do
			local v = kvalitet[k]
			if v ~= nil then
				tema.summa[k] = (tema.summa[k] or 0) + v * dt
				tema.vikt[k] = (tema.vikt[k] or 0) + dt
			end
		end
		if tema.valtid < UgnetaTema.VAL_SEK then return "", false, "" end
		local dim = UgnetaTema.valj(tema, dims)
		if dim == nil then return "", false, "" end
		local cue = UG.DIM_CUE[dim]
		if cue == nil then return "", false, "" end
		tema.dim, tema.cue = dim, cue
	end

	--[[ TEMAFILTRET. Bara temats egen dimension läses. Att en ANNAN
	     dimension är svag är inte tyst för att den är bra — den är tyst
	     för att den inte är dagens sak. ]]
	local v = kvalitet[tema.dim :: string]

	--[[ MÖNSTRET BYGGS ÄVEN UNDER SPÄRREN. Annars hade varje cooldown
	     nollställt historien, och ett ihållande fel hade sett ut som ett
	     nytt fel varje gång spärren släppte. ]]
	if v == nil then
		--[[ Omätt bildruta bryter inte mönstret, men bygger det inte
		     heller. Att nollställa här hade gjort ett glapp i
		     telemetrin till ett «felet är borta». ]]
	elseif v < KV.SVAG then
		tema.svagSedan += dt
		tema.braSedan = 0
	else
		tema.braSedan += dt
		tema.svagSedan = 0
	end

	if tema.cd > 0 then return "", false, "" end

	--[[ HÄSTENS EGEN SPÄNNING GÅR FÖRE RYTTARENS TEMA. Har hon en dålig
	     dag ska spelaren inte få veta att hon sitter fel — hon sitter
	     kanske alldeles rätt. ]]
	local sp = spanning
	if sp ~= nil and sp > UgnetaTema.SPANNING_TROSKEL and tema.attributCd <= 0 then
		local hennes = UgnetaTema.hastensEgen(hast)
		if hennes == true then
			tema.attributCd = UgnetaTema.ATTRIBUT_CD
			tema.cd = UG.LIVE_CD.fel
			return "HAST", false, "hast"
		end
		--[[ `hennes == nil` — vi vet inte. Då tiger vi om spänningen.
		     `hennes == false` — det var inte hennes dag som spökade, och
		     temat nedan får ta vid som vanligt. ]]
	end

	if v == nil then return "", false, "" end

	local rad = UG.LIVE[tema.cue :: string]
	if not rad then return "", false, "" end

	--[[ MÖNSTER FÖRE KOMMENTAR, åt båda hållen. En enda dålig bildruta
	     är brus — en häst tappar balansen i ett hörn utan att ryttaren
	     gjort något. Ett enda BRA ögonblick är inte heller ett beröm
	     värt; webben kräver sex sekunder och det gör den här också. ]]
	local txt, bra
	if tema.svagSedan >= UgnetaTema.SVAG_SEK then
		txt, bra = rad.fel, false
	elseif tema.braSedan >= UgnetaTema.BEROM_SEK then
		txt, bra = rad.bra, true
	else
		return "", false, ""
	end

	--[[ Aldrig samma ord två gånger i rad. ]]
	if txt == tema.sagt then return "", false, "" end

	tema.sagt = txt
	tema.cd = if bra then UG.LIVE_CD.bra else UG.LIVE_CD.fel
	--[[ Efter ett beröm börjar räkningen om, annars hade sex sekunders
	     bra ridning gett beröm i varje spärrsläpp resten av passet. ]]
	if bra then tema.braSedan = 0 end
	return txt, bra, "tema"
end

return UgnetaTema
