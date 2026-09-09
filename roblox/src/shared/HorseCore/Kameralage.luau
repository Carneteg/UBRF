--!strict
--[[
	KAMERALÄGET UNDER RITTEN — G02-E del 1 (issue #150).

	Tobias produktbeslut 2026-09-08: när spelaren rider ska standard-
	kameran vara RYTTARENS perspektiv — vyn från sadeln, med hästens hals
	och öron och vägen framåt. När feedback ges får spelet TILLFÄLLIGT
	visa en annan relevant vinkel, och sedan ska kameran återgå. Mjukt,
	kort, och utan att störa kontrollkänslan.

	VAD SOM FAKTISKT FANNS INNAN. Ingen av ytorna hade ett ryttar-
	perspektiv. CameraController la ögat på Gaits.camera.dist studs BAKOM
	hästen — 14 i skritt, 23 i fyrsprång — och webbens s3Kamera gjorde
	detsamma med 3,78–5,13 m. Båda är tredjepersonskameror. Den gamla
	vyn är inte kastad; den är DEGRADERAD till feedbackvinkeln `utifran`,
	där den hör hemma: att se sig själv utifrån är pedagogiskt, men det
	är inte att rida.

	Den här modulen är webbens src/riding/kameralage.js, tal för tal och
	regel för regel. Den äger LÄGET — inte kameran. CameraController
	frågar den vad som gäller och interpolerar mellan sadeln (vikt 0) och
	vinkeln (vikt 1); modulen rör ingen Instance, ingen rörelse och ingen
	input, och kan alltså inte ändra ridkänslan.

	Reglerna, identiska med webbens:

	  1. SADELN ÄR STANDARD. Läget börjar i `ryttare` och faller alltid
	     tillbaka dit.
	  2. EN FEEDBACKVINKEL ÅT GÅNGEN, aldrig köad. En begäran tas emot
	     eller avvisas på plats — ingen begäran kan tändas senare.
	  3. TIDEN ÄR BEGRÄNSAD I KODEN. In-, håll- och uttoning, validerad
	     summa, och ett hårt tak ovanpå.
	  4. VIKTEN ÄR MJUK OCH DETERMINISTISK — smoothstep av ackumulerad
	     dt, aldrig väggklocka.

	VINKLARNA ÄR RELATIVA TILL HÄSTEN: yaw i radianer plus fyra
	MULTIPLIKATORER på den gångartsburna bom som redan finns. Därför bär
	Roblox och webben EXAKT samma tal trots studs mot meter och grader mot
	radianer. Det är samma paritetsregel som redan gäller Gaits.camera.
]]

local Kameralage = {}

export type Vinkel = {
	yaw: number, bak: number, hojd: number, fov: number, blick: number,
	["in"]: number, hall: number, ut: number,
}

export type Lage = {
	lage: string, id: string?, fas: string,
	t: number, total: number, vikt: number, startVikt: number, orsak: string?,
}

export type Upplost = {
	lage: string, id: string?, vikt: number,
	yaw: number, bak: number, hojd: number, fov: number, blick: number,
}

--[[ Neutralläget = sadelvyn. Vikt 0 betyder "ingen feedbackvinkel alls".
     Att sadeln är FRÅNVARON av en vinkel och inte ett eget specialfall är
     avsikt: går läget sönder är ryttarperspektivet kvar. ]]
Kameralage.NEUTRAL = { yaw = 0, bak = 1, hojd = 1, fov = 1, blick = 1 }

--[[ Hårda gränser. En konfiguration utanför dem registreras inte alls —
     hellre ingen vinkel än en som ställer kameran inuti hästen eller
     håller kvar bilden i en kvart. ]]
local GRANS = {
	yaw = { -math.pi, math.pi },
	bak = { 0.35, 3.0 },
	hojd = { 0.40, 4.0 },
	fov = { 0.75, 1.35 },
	blick = { -1.5, 2.5 },
	["in"] = { 0.15, 1.2 },
	hall = { 0.20, 4.0 },
	ut = { 0.15, 1.5 },
}
Kameralage.GRANS = GRANS

local MAX_TOTAL = 6.0
local MAX_UT = 1.5
local DT_TAK = 0.1
Kameralage.MAX_TOTAL = MAX_TOTAL

--[[ ── Vinklarna ─────────────────────────────────────────────────────
     Samma fyra som webben, samma tal. Fler hör till del 2 och ska in när
     det är bestämt VILKEN händelse som ska visa vad.

     Talen är DERIVED — spelkänsla, inte UBRF-fakta. ]]
local VINKLAR: { [string]: Vinkel } = {
	--[[ DEN GAMLA TREDJEPERSONSVYN, oförändrad: yaw 0 och alla
	     multiplikatorer 1 ger exakt den bom Gaits.camera beskriver. Kvar
	     som den bästa översiktsbilden vi har — men som en LÅNAD vy, inte
	     som ridningens standard. ]]
	utifran = { yaw = 0, bak = 1.00, hojd = 1.00, fov = 1.00, blick = 1.00,
		["in"] = 0.45, hall = 1.80, ut = 0.55 },
	--[[ SITSEN OCH HÄSTENS FORM. Från sidan, blicken på ekipaget. ]]
	sits = { yaw = math.pi / 2, bak = 0.95, hojd = 0.92, fov = 0.94, blick = 0.10,
		["in"] = 0.40, hall = 1.60, ut = 0.50 },
	--[[ VÄGVALET OCH AVSTÅNDET. Högre och längre bak, blicken längre fram. ]]
	vagval = { yaw = 0, bak = 1.90, hojd = 2.40, fov = 1.08, blick = 1.30,
		["in"] = 0.45, hall = 1.70, ut = 0.55 },
	--[[ HINDERANSATSEN OCH TAJMINGEN. Framifrån, låg, blicken bakom hästen
	     så att hon står mellan kameran och siktpunkten. ]]
	ansats = { yaw = math.pi, bak = 1.25, hojd = 1.05, fov = 1.00, blick = -0.35,
		["in"] = 0.40, hall = 1.50, ut = 0.50 },
}

--[[ ── Validering ────────────────────────────────────────────────────
     Körs en gång vid inläsning. En vinkel som inte håller måtten tas BORT
     i stället för att klampas: en tyst korrigering hade gjort att felet
     aldrig upptäcktes. ]]
local FALT = { "yaw", "bak", "hojd", "fov", "blick", "in", "hall", "ut" }

local function inom(v: any, g: { number }): boolean
	return typeof(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge
		and v >= g[1] and v <= g[2]
end

function Kameralage.validera(_id: string, v: any): string?
	if typeof(v) ~= "table" then return "ingen tabell" end
	for _, namn in FALT do
		if not inom(v[namn], GRANS[namn]) then
			return string.format("%s=%s utanför [%s, %s]", namn, tostring(v[namn]),
				tostring(GRANS[namn][1]), tostring(GRANS[namn][2]))
		end
	end
	local total = v["in"] + v.hall + v.ut
	if total > MAX_TOTAL then
		return string.format("in+håll+ut = %.2f s över taket %.1f s", total, MAX_TOTAL)
	end
	return nil
end

do
	local bort = {}
	for id, v in VINKLAR do
		local fel = Kameralage.validera(id, v)
		if fel then
			warn(("[Kameralage] vinkeln \"%s\" registrerades inte — %s"):format(id, fel))
			table.insert(bort, id)
		end
	end
	for _, id in bort do VINKLAR[id] = nil end
end

Kameralage.VINKLAR = VINKLAR

function Kameralage.giltig(id: any): boolean
	return typeof(id) == "string" and VINKLAR[id] ~= nil
end

function Kameralage.vinkel(id: any): Vinkel?
	if typeof(id) ~= "string" then return nil end
	return VINKLAR[id]
end

--[[ ── Tillståndet ───────────────────────────────────────────────────
     `fas` är den enda sanningen om var i övergången vi är:
       vila  — sadelvyn, vikt 0, ingen vinkel utlånad
       in    — vikten stiger mot den begärda vinkeln
       hall  — vinkeln ligger stilla på full vikt
       ut    — vikten faller tillbaka mot sadeln
     Det finns AVSIKTLIGT ingen femte fas och ingen kö. ]]
function Kameralage.skapa(): Lage
	return { lage = "ryttare", id = nil, fas = "vila",
		t = 0, total = 0, vikt = 0, startVikt = 0, orsak = nil }
end

local function mjuk(p: number): number
	local w = if p < 0 then 0 elseif p > 1 then 1 else p
	return w * w * (3 - 2 * w)
end

--[[ Begär en tillfällig feedbackvinkel.

     Returnerar true om begäran togs emot, annars false UTAN att röra
     tillståndet. Avvisning är regel, inte undantag:

     - Okänd vinkel avvisas.
     - En ANNAN vinkel medan en redan är uppe avvisas. Att byta vinkel
       mitt i en pågående vikt hade flyttat kameran ett halvt varv i en
       bildruta — ett klipp mitt i styrningen. Anroparen får släppa den
       pågående vyn först.
     - SAMMA vinkel medan den är uppe tas emot och startar om från
       nuvarande vikt; offseten är identisk, så det syns ingen skarv.

     `total` NOLLSTÄLLS BARA VID EN RIKTIGT NY BEGÄRAN (fas var "vila").
     En upprepad begäran om SAMMA vinkel medan den redan är uppe rör
     inte `total` — annars kunde en anropare som råkar begära om samma
     vinkel varje bildruta hålla kvar feedbackvyn för evigt genom att
     varje anrop nollställde klockan som MAX_TOTAL/nödbromsen läser. Den
     ORIGINALA deadlinen, räknad från första begäran, gäller oavsett hur
     många gånger samma vinkel begärs på nytt. ]]
function Kameralage.begar(st: Lage, id: any, orsak: string?): boolean
	if not st or not Kameralage.giltig(id) then return false end
	local nyBegaran = st.fas == "vila"
	if not nyBegaran and st.id ~= id then return false end
	st.lage = "feedback"
	st.id = id
	st.fas = "in"
	st.t = 0
	if nyBegaran then st.total = 0 end
	st.startVikt = st.vikt
	st.orsak = orsak
	return true
end

--[[ Släpp vyn i förtid — mjukt. Sammanhanget tog slut men spelaren rider
     vidare: uttoningen körs, och sedan är sadeln tillbaka. ]]
function Kameralage.slapp(st: Lage, orsak: string?): boolean
	if not st or st.fas == "vila" or st.fas == "ut" then return false end
	st.fas = "ut"
	st.t = 0
	st.startVikt = st.vikt
	if orsak then st.orsak = orsak end
	return true
end

--[[ Nollställ HÅRT och omedelbart — ingen uttoning.

     Scenbytet, avsittningen, overlayen och lektionsstarten. I samtliga
     fall är bilden ändå på väg att bytas ut eller täckas, och en mjuk
     uttoning över ett scenbyte hade bara betytt att den gamla vyn levde
     vidare en halv sekund in i den nya. Efter det här anropet finns ingen
     begäran kvar som kan tändas senare. ]]
function Kameralage.nollstall(st: Lage, orsak: string?): boolean
	if not st then return false end
	local varAktiv = st.fas ~= "vila"
	st.lage = "ryttare"
	st.id = nil
	st.fas = "vila"
	st.t = 0
	st.total = 0
	st.vikt = 0
	st.startVikt = 0
	st.orsak = orsak
	return varAktiv
end

function Kameralage.aktiv(st: Lage?): boolean
	return st ~= nil and (st :: Lage).fas ~= "vila"
end

--[[ Vad kameran ska använda just nu. Ren avläsning — stegar ingenting. ]]
function Kameralage.las(st: Lage?): Upplost
	local v = if st and st.vikt > 0 then Kameralage.vinkel(st.id) else nil
	if not v then
		local N = Kameralage.NEUTRAL
		return { lage = "ryttare", id = nil, vikt = 0,
			yaw = N.yaw, bak = N.bak, hojd = N.hojd, fov = N.fov, blick = N.blick }
	end
	local s = st :: Lage
	return { lage = "feedback", id = s.id, vikt = s.vikt,
		yaw = v.yaw, bak = v.bak, hojd = v.hojd, fov = v.fov, blick = v.blick }
end

--[[ Stega övergången en bildruta och lämna tillbaka det upplösta läget.

     All tid som styr faserna kommer HÄRIFRÅN. Ingen os.clock, ingen
     tick(): samma dt-följd ger samma vy, vilket är vad "deterministisk
     återgång" betyder i praktiken och vad specen mäter. ]]
function Kameralage.stega(st: Lage, dt: number): Upplost
	if not st then return Kameralage.las(nil) end
	local d = if typeof(dt) == "number" and dt == dt then dt else 0
	if d < 0 then d = 0 elseif d > DT_TAK then d = DT_TAK end

	if st.fas ~= "vila" then
		local v = Kameralage.vinkel(st.id)
		--[[ Vinkeln försvann under körning. Då är sadeln rätt svar, direkt. ]]
		if not v then
			Kameralage.nollstall(st, "vinkel-borta")
			return Kameralage.las(st)
		end
		local vv = v :: Vinkel

		st.t += d
		st.total += d

		--[[ Nödbromsen först, så att en trasig konfiguration inte kan hålla
		     kvar bilden bara för att dess egna faser aldrig tar slut. ]]
		if st.total >= MAX_TOTAL + MAX_UT then
			Kameralage.nollstall(st, "tidstak")
			return Kameralage.las(st)
		end
		if st.total >= MAX_TOTAL and st.fas ~= "ut" then
			st.fas = "ut"; st.t = 0; st.startVikt = st.vikt
		end

		if st.fas == "in" then
			local p = if vv["in"] > 0 then st.t / vv["in"] else 1
			st.vikt = st.startVikt + (1 - st.startVikt) * mjuk(p)
			if p >= 1 then st.vikt = 1; st.fas = "hall"; st.t = 0 end
		elseif st.fas == "hall" then
			st.vikt = 1
			if st.t >= vv.hall then st.fas = "ut"; st.t = 0; st.startVikt = 1 end
		end
		if st.fas == "ut" then
			local p = if vv.ut > 0 then st.t / vv.ut else 1
			st.vikt = st.startVikt * (1 - mjuk(p))
			--[[ Uttoningen når exakt noll, och DÄR nollställs allt. Ett
			     "nästan noll" hade lämnat en vinkel registrerad som inte
			     syns — ett stall-läge som senare kunde vakna. ]]
			if p >= 1 then Kameralage.nollstall(st, "atergang") end
		end
	end
	return Kameralage.las(st)
end

return Kameralage
