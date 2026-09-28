--!strict
--[[ HINDEROBSERVATIONEN — serverns register över BEFINTLIGA hinder och dess
	observation av passage, luftfas och överlapp per ritt (#264 INFRA-2B2).

	── REGISTRET ─────────────────────────────────────────────────────
	Hindren byggs av `Anlaggningen.luau` ur `UBRFKomplex.ridhusinne.hinder`
	(genererad ur `src/site.js`). Bommen bär attributet `HinderId`, hindrets
	stabila id ur källdatan. Registret läser bommens FAKTISKA läge och mått
	efter bygget och speglingen — aldrig listindex, namn eller byggordning.

	Per hinder: centrum (x, y, z), bredd (bommens längsta axel), breddaxel
	och normal i planet (enhetsvektorer i X/Z), bommens överkant och
	tjocklek. Allt i studs. Ett id som förekommer två gånger avvisas för
	BÅDA bommarna (vilken som är rätt går inte att veta), liksom saknat,
	ogiltigt eller icke-ändligt läge och mått. Ett avvisat hinder ger aldrig
	en passage.

	── OBSERVATIONEN ─────────────────────────────────────────────────
	`HorseService` matar den med varje GILTIGT segment ur ridobservationen
	(`RidObservation.sampla` → "segment"), och med varje brott. Ett segment
	över ett brott finns alltså aldrig, och ett brott stänger varje pågående
	försök som `brott` — utfallet är då okänt, aldrig en passage.

	REGISTRETS LIVSCYKEL (granskning R1): registret håller de LEVANDE delar
	som bär varje id. En del → giltigt hinder; två eller fler → alla
	avvisas och pågående försök stängs som `hinder_ogiltigt`. När en del
	försvinner släpps referensen, dess försök stängs som `hinder_borttaget`,
	och en ensam kvarvarande eller ersättande del med samma id blir giltig.
	Ingen ersättare ärver ett gammalt försök.

	Försök: hästen kommer in i hindrets zon (|u| ≤ bredd/2 + ZON_SIDA,
	|v| ≤ ZON_DJUP i hindrets eget system), eller ett segment korsar
	hindrets plan. Försöket står tills hon lämnar zonen, och ger då ETT
	utfall — inga upprepningar medan hon står i zonen. Nytt inträde = nytt
	försök med eget löpnummer per hinder.

	Utfall:
	  · `passage`       hästen har BEKRÄFTAT varit på båda sidor om planet
	                    (|v| > SID_TOL, 0,25 studs, spelantagande) och det
	                    senaste OBSERVERADE segmentet som nådde planet före
	                    bytet gjorde det INNANFÖR bredden (granskning R2 —
	                    aldrig kordan mellan två bekräftade lägen); `riktning` "fram" (−v → +v) eller
	                    "bak". Att nå planet och vända är ingen passage,
	  · `sidan_om`      planet korsas utanför bredden,
	  · `ingen_passage` zonen lämnades utan korsning,
	  · och giltighet `brott`, `ritten_slut` eller `hinder_borttaget`, där
	    utfallet är `okant`.

	Luftfas och landning är OBSERVATIONER av hästens `FloorMaterial` på
	servern ("luft" = Air, "mark" = annat, okänd = saknas). För en häst vars
	fysik ägs av ryttarens klient kan serverns värde vara inaktuellt; det är
	inte provat i motorn. En landning är observerad bara när luft följs
	DIREKT av mark; okänd evidens bryter kedjan (granskning R1). Observerad luftfas är inte ett bevis på ett
	korrekt hopp, och saknad markevidens är aldrig en lyckad landning.

	ÖVERLAPP ÄR INTE RIVNING. Bommen har `CanCollide = false`, så någon
	fysisk kontakt finns inte att observera: `kontakt` är alltid
	"otillganglig". `overlapp` betyder bara att hästens rot (som låda) och
	bommen (som låda) skär varandra geometriskt vid ett sampel eller vid
	korsningen. `rivning` är aldrig sann av överlapp, närhet eller passage;
	en bom som ligger kvar är aldrig riven. Har bommen flyttats sedan
	registreringen står det som `bom = "flyttad"` — en observation, inget
	straff.

	── NEDSLAG (B4a, docs/B4A-KNOCKDOWN-EVENT-CONTRACT.md) ────────────
	Varje försök bär `nedslag` = "ja" | "nej" | "okand" | "vantar", med
	`nedslagGrund` och `tNedslag`. STÄNGT VID FEL: bara en bom som KAN falla
	(`Anchored == false` och `CanCollide == true`, läst när försöket börjar)
	och som stod UPPE då (mittens höjd inom bommens tjocklek från det
	registrerade läget) kan ge "nej" — och först när NEDSLAG_FONSTER sekunder
	ritt-tid gått efter stängningen utan fall. Ett fall är att bommens mitt
	sjunkit mer än bommens tjocklek sedan försöket började, medan det pågår
	eller inom fönstret. Allt annat är "okand"; en bom som inte kan falla
	(alla i dag) ger ALDRIG "nej". Tröskel och fönster är spelantaganden som
	kalibreras i Studio. `rivning` och `overlapp` är oförändrade.

	── MINNE ─────────────────────────────────────────────────────────
	Per steg O(antal hinder). Per ritt högst MAX_FORSOK försök; fler tappas
	och `overflode` sätts. Avslutade ritter i en ring om MAX_AVSLUTADE.
	Ögonblicksbilder är frysta djupkopior. Inga lyssnare per ritt.

	Inget här är fuskskydd, poäng, domare, belöning eller persistens. ]]

local HinderObservation = {}

HinderObservation.VERSION = 1
HinderObservation.ZON_SIDA = 1.5
HinderObservation.ZON_DJUP = 6
--[[ Spelantagande: inom så här många studs från planet är sidan obestämd. ]]
HinderObservation.SID_TOL = 0.25
HinderObservation.MAX_FORSOK = 64
HinderObservation.MAX_AVSLUTADE = 32
--[[ B4a, spelantagande (kalibreras i Studio): hur länge efter att försöket
	stängts ett fall fortfarande räknas till det, i ritt-tid (s). ]]
HinderObservation.NEDSLAG_FONSTER = 2.0
local MAX_ID = 64

type Hinder = {
	id: string, cx: number, cy: number, cz: number,
	bredd: number, ux: number, uz: number, nx: number, nz: number,
	topp: number, tjocklek: number, hojdHalva: number,
	_del: BasePart?, _lage: Vector3,
}
type Forsok = {
	hinderId: string, nr: number,
	tIn: number, tUt: number?, tPassage: number?,
	utfall: string, riktning: string?, giltighet: string,
	sampel: number, luftSampel: number, markSampel: number, okandSampel: number,
	luftfas: string, landning: string, overlapp: boolean, overlappAntal: number,
	kontakt: string, rivning: boolean, bom: string,
	nedslag: string, nedslagGrund: string?, tNedslag: number?,
	_fysisk: boolean, _uppsatt: boolean, _bomY0: number?, _delRef: any, _fallT: number?, _frist: number?,
	_korsat: boolean, _sidanOm: boolean, _luftAktiv: boolean, _markEfterLuft: boolean,
	_sida: number?, _kandU: number?, _kandY: number?,
}
type Ritt = {
	v: number, rittId: string, hastId: string, userId: number,
	oppen: boolean, satt: string?, overflode: boolean, tappade: number,
	forsok: { Forsok }, _aktiva: { [string]: Forsok }, _nr: { [string]: number },
	_vantande: { [Forsok]: boolean },
}

local hinder: { [string]: Hinder } = {}
local avvisade: { [string]: string } = {}
local delar: { [string]: { [any]: boolean } } = {}
--[[ GENERATION per id (#264 markbom): räknas upp vid VARJE ändring i
	registreringen — en del som läggs till, tas bort eller prövas om, eller
	hela id:t bort. En konsument som vill veta att geometrin är SAMMA
	registrering (inte en ersättare med identiska mått) jämför den. Rent
	tillägg; inga livscykelregler ändras. ]]
local generation: { [string]: number } = {}
local ritter: { [string]: Ritt } = {}
local avslutade: { string } = {}
local gallrade = 0

local function andligt(v: any): boolean
	return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge
end

local function vektorOk(p: any): boolean
	if p == nil then return false end
	local ok, x, y, z = pcall(function() return p.X, p.Y, p.Z end)
	return ok and andligt(x) and andligt(y) and andligt(z)
end

--[[ B4a: kan bommen falla? Läst på delen; ett fel i läsningen är ett nej. ]]
local function kanFalla(del: any): boolean
	local ok, ankrad, kolliderar = pcall(function() return del.Anchored, del.CanCollide end)
	return ok and ankrad == false and kolliderar == true
end

--[[ B4a: bommens mitt i höjd just nu, eller nil när delen är borta eller
	inte går att läsa. Läst ur CFrame, som geometrin. ]]
local function bomY(del: any): number?
	local ok, y = pcall(function()
		if del == nil or del.Parent == nil then return nil end
		return del.CFrame.Position.Y
	end)
	if ok and andligt(y) then return y end
	return nil
end

--[[ ── REGISTRET ─────────────────────────────────────────────────── ]]

local function geometri(del: any): Hinder?
	local ok, cf, storlek = pcall(function() return del.CFrame, del.Size end)
	if not ok or not cf or not vektorOk(storlek) or not vektorOk(cf.Position) then return nil end
	local p = cf.Position
	--[[ Bommens längsta axel är bredden. Axlarna tas ur delens egen
		orientering, så att speglingen och en vriden bom räknas rätt. ]]
	local function axel(x: number, y: number, z: number): Vector3
		return (cf * CFrame.new(x, y, z)).Position - p
	end
	local axlar = {
		{ l = storlek.X, v = axel(1, 0, 0) },
		{ l = storlek.Y, v = axel(0, 1, 0) },
		{ l = storlek.Z, v = axel(0, 0, 1) },
	}
	table.sort(axlar, function(a, b) return a.l > b.l end)
	local bredd, axel = axlar[1].l, axlar[1].v
	if not (andligt(bredd) and bredd > 0 and vektorOk(axel)) then return nil end
	local plan = math.sqrt(axel.X * axel.X + axel.Z * axel.Z)
	if plan < 0.5 then return nil end -- en stående "bom" är inget hinder att passera
	local ux, uz = axel.X / plan, axel.Z / plan
	return {
		id = "", cx = p.X, cy = p.Y, cz = p.Z,
		bredd = bredd, ux = ux, uz = uz, nx = -uz, nz = ux,
		topp = p.Y + storlek.Y / 2, tjocklek = math.min(storlek.Y, storlek.Z, storlek.X),
		hojdHalva = storlek.Y / 2,
		_del = del, _lage = p,
	}
end

local function stangForsok(r: Ritt, f: Forsok, giltighet: string, t: number?)
	f.giltighet = giltighet
	f.tUt = t
	if giltighet ~= "fullstandig" then
		f.utfall = "okant"
		f.riktning = nil
	elseif f._korsat then
		f.utfall = "passage"
	elseif f._sidanOm then
		f.utfall = "sidan_om"
	else
		f.utfall = "ingen_passage"
	end
	f.luftfas = if f.luftSampel > 0 then "observerad"
		elseif f.okandSampel > 0 then "okand" else "ej_observerad"
	f.landning = if f.luftSampel == 0 then (if f.okandSampel > 0 then "okand" else "ingen_luftfas")
		elseif f._markEfterLuft then "observerad"
		elseif f.okandSampel > 0 then "okand" else "ej_observerad"
	local h = hinder[f.hinderId]
	local del = h and h._del
	if not h or not del or not del.Parent then
		f.bom = "okand"
	else
		local nu = del.Position
		f.bom = if (nu - h._lage).Magnitude <= 0.01 then "ligger" else "flyttad"
	end
	f.rivning = false
	--[[ B4a: nedslaget. Stängt vid fel i varje gren; "vantar" blir "nej"
		först när fönstret passerat utan fall (`vantande` nedan). ]]
	if giltighet ~= "fullstandig" then
		f.nedslag, f.nedslagGrund = "okand", "ej_fullstandigt"
	elseif not f._fysisk then
		f.nedslag, f.nedslagGrund = "okand", "bom_ej_fysisk"
	elseif not f._uppsatt then
		f.nedslag, f.nedslagGrund = "okand", "bom_ej_uppsatt"
	else
		local y = if h and h._del == f._delRef then bomY(f._delRef) else nil
		if y == nil then
			f.nedslag, f.nedslagGrund = "okand", "hinder_saknas"
		elseif f._fallT ~= nil or (f._bomY0 :: number) - y > (h :: Hinder).tjocklek then
			f.nedslag, f.nedslagGrund = "ja", "bom_foll"
			f.tNedslag = f._fallT or t
		else
			f.nedslag, f.nedslagGrund = "vantar", nil
			f._frist = (t :: number) + HinderObservation.NEDSLAG_FONSTER
			r._vantande[f] = true
		end
	end
	r._aktiva[f.hinderId] = nil
end

--[[ B4a: försök vars fönster står öppet. Ett fall inom fönstret ger "ja";
	ett passerat fönster utan fall ger "nej". En borttagen eller ersatt bom
	ger "okand". `slut` (brott/ritten slut) stänger allt som "okand". ]]
local function vantande(r: Ritt, t: number?, slut: string?)
	for f in pairs(r._vantande) do
		local h = hinder[f.hinderId]
		local y = if h and h._del == f._delRef then bomY(f._delRef) else nil
		local klar = true
		if slut then
			f.nedslag, f.nedslagGrund = "okand", slut
		elseif y == nil then
			f.nedslag, f.nedslagGrund = "okand", "hinder_saknas"
		elseif (f._bomY0 :: number) - y > (h :: Hinder).tjocklek then
			f.nedslag, f.nedslagGrund, f.tNedslag = "ja", "bom_foll", t
		elseif t ~= nil and t >= (f._frist :: number) then
			f.nedslag, f.nedslagGrund = "nej", "bom_ligger"
		else
			klar = false
		end
		if klar then r._vantande[f] = nil end
	end
end

--[[ Varje pågående försök vid hindret stängs med okänt utfall. Anropas
	INNAN registret glömmer hindret, så att bommens läge kan läsas. ]]
local function stangAktiva(id: string, giltighet: string)
	for _, r in pairs(ritter) do
		local f = r._aktiva[id]
		if f then stangForsok(r, f, giltighet, nil) end
	end
end

local function antalDelar(id: string): (number, any)
	local n, en = 0, nil
	for d in pairs(delar[id] or {}) do n += 1; en = d end
	return n, en
end

--[[ Registrerar EN levande del som bär id:t (granskning R1). Registret
	följer vilka delar som FINNS med varje id:
	  · en del           → giltigt hinder (om geometrin håller),
	  · två eller fler   → alla avvisas (`dubbelt_id`), och pågående
	                       försök stängs som `hinder_ogiltigt`,
	  · samma del igen   → ingen dubblett; geometrin läses om.
	Pågående försök ärvs aldrig av en annan geometri. ]]
local function prova(id: string)
	generation[id] = (generation[id] or 0) + 1
	local n, del = antalDelar(id)
	if n == 0 then
		delar[id] = nil
		avvisade[id] = nil
		return false, "saknas"
	end
	if n > 1 then
		stangAktiva(id, "hinder_ogiltigt")
		hinder[id] = nil
		avvisade[id] = "dubbelt_id"
		return false, "dubbelt_id"
	end
	local h = geometri(del)
	if not h then
		stangAktiva(id, "hinder_ogiltigt")
		hinder[id] = nil
		avvisade[id] = "ogiltig_geometri"
		return false, "ogiltig_geometri"
	end
	--[[ Ingen egen gren för "en annan del tar över": det kan bara ske
		efter en dubblett eller en borttagning, och båda har redan stängt
		de gamla försöken (en sådan gren var död och överlevde sin mutation). ]]
	h.id = id
	hinder[id] = h
	avvisade[id] = nil
	return true, nil
end

function HinderObservation.registrera(del: any): (boolean, string?)
	local ok, id = pcall(function() return del:GetAttribute("HinderId") end)
	if not ok or type(id) ~= "string" or id == "" or #id > MAX_ID then
		return false, "ogiltigt_id"
	end
	delar[id] = delar[id] or {}
	delar[id][del] = true
	return prova(id)
end

--[[ En del som försvinner. Referensen släpps, pågående försök vid den
	stängs som `hinder_borttaget`, och finns exakt en annan del kvar med
	samma id prövas den — så att en ensam ersättare, eller den kvarvarande
	efter en dubblett, blir giltig igen. ]]
function HinderObservation.avregistreraDel(del: any)
	for id, set in pairs(delar) do
		if set[del] then
			set[del] = nil
			local h = hinder[id]
			if h and h._del == del then
				stangAktiva(id, "hinder_borttaget")
				hinder[id] = nil
			end
			prova(id)
		end
	end
end

--[[ Hela id:t bort, med alla dess delar. ]]
function HinderObservation.avregistrera(id: string)
	generation[id] = (generation[id] or 0) + 1
	stangAktiva(id, "hinder_borttaget")
	hinder[id] = nil
	delar[id] = nil
	avvisade[id] = nil
end

function HinderObservation.start(rot: Instance)
	for _, d in ipairs(rot:GetDescendants()) do
		if d:IsA("BasePart") and d:GetAttribute("HinderId") ~= nil then
			HinderObservation.registrera(d)
		end
	end
	rot.DescendantAdded:Connect(function(d)
		if d:IsA("BasePart") and d:GetAttribute("HinderId") ~= nil then
			HinderObservation.registrera(d)
		end
	end)
	rot.DescendantRemoving:Connect(function(d)
		HinderObservation.avregistreraDel(d)
	end)
end

--[[ ── OBSERVATIONEN ─────────────────────────────────────────────── ]]

function HinderObservation.starta(rittId: string, hastId: string, userId: number): boolean
	if type(rittId) ~= "string" or rittId == "" or ritter[rittId] then return false end
	ritter[rittId] = {
		v = HinderObservation.VERSION, rittId = rittId, hastId = tostring(hastId),
		userId = tonumber(userId) or 0, oppen = true, satt = nil, overflode = false, tappade = 0,
		forsok = {}, _aktiva = {}, _nr = {}, _vantande = {},
	}
	return true
end

local function lokal(h: Hinder, p: Vector3): (number, number)
	local dx, dz = p.X - h.cx, p.Z - h.cz
	return dx * h.ux + dz * h.uz, dx * h.nx + dz * h.nz
end

local function iZon(h: Hinder, u: number, v: number): boolean
	return math.abs(u) <= h.bredd / 2 + HinderObservation.ZON_SIDA
		and math.abs(v) <= HinderObservation.ZON_DJUP
end

--[[ Rotens låda mot bommens låda, i hindrets system. `halv` är rotens
	halva mått; planets halva räknas som den större av X och Z. ]]
local function overlappar(h: Hinder, u: number, v: number, y: number, halv: Vector3?): boolean
	if not halv then return false end
	local r = math.max(halv.X, halv.Z)
	return math.abs(u) <= h.bredd / 2 + r
		and math.abs(v) <= h.tjocklek / 2 + r
		and (y - halv.Y) <= (h.cy + h.hojdHalva) and (y + halv.Y) >= (h.cy - h.hojdHalva)
end

local function nyttForsok(r: Ritt, h: Hinder, t: number): Forsok?
	if #r.forsok >= HinderObservation.MAX_FORSOK then
		r.overflode = true
		r.tappade += 1
		return nil
	end
	r._nr[h.id] = (r._nr[h.id] or 0) + 1
	local f: Forsok = {
		hinderId = h.id, nr = r._nr[h.id], tIn = t, tUt = nil, tPassage = nil,
		utfall = "pagar", riktning = nil, giltighet = "pagar",
		sampel = 0, luftSampel = 0, markSampel = 0, okandSampel = 0,
		luftfas = "okand", landning = "okand", overlapp = false, overlappAntal = 0,
		kontakt = "otillganglig", rivning = false, bom = "okand",
		nedslag = "okand", nedslagGrund = nil, tNedslag = nil,
		_fysisk = false, _uppsatt = false, _bomY0 = nil, _delRef = h._del, _fallT = nil, _frist = nil,
		_korsat = false, _sidanOm = false, _luftAktiv = false, _markEfterLuft = false,
		_sida = nil, _kandU = nil, _kandY = nil,
	}
	-- B4a: kan bommen falla, och stod den uppe när försöket började?
	f._fysisk = kanFalla(h._del)
	f._bomY0 = bomY(h._del)
	f._uppsatt = f._bomY0 ~= nil and math.abs(h.cy - (f._bomY0 :: number)) <= h.tjocklek
	table.insert(r.forsok, f)
	r._aktiva[h.id] = f
	return f
end

--[[ Ett GILTIGT segment `fran` → `till` vid ritt-tid `t`. `luft` är
	"luft", "mark" eller nil (okänd) vid `till`. `halv` är rotens halva mått. ]]
function HinderObservation.segment(rittId: string?, fran: Vector3, till: Vector3, t: number,
	luft: string?, halv: Vector3?): boolean
	local r = rittId and ritter[rittId]
	if not r or not r.oppen then return false end
	if not (vektorOk(fran) and vektorOk(till) and andligt(t)) then return false end
	vantande(r, t, nil)
	for id, h in pairs(hinder) do
		local u0, v0 = lokal(h, fran)
		local u1, v1 = lokal(h, till)
		local korsar = (v0 < 0 and v1 >= 0) or (v0 > 0 and v1 <= 0)
		local uK, yK = nil, nil
		if korsar then
			local k = v0 / (v0 - v1)
			uK = u0 + k * (u1 - u0)
			yK = fran.Y + k * (till.Y - fran.Y)
		end
		local f = r._aktiva[id]
		--[[ Ett nytt försök bara i zonen, eller där planet korsas INOM zonens
			sidogräns — aldrig var som helst längs hindrets oändliga linje. ]]
		local korsarNara = uK ~= nil and math.abs(uK) <= h.bredd / 2 + HinderObservation.ZON_SIDA
		if not f and (iZon(h, u1, v1) or korsarNara) then
			f = nyttForsok(r, h, t)
		end
		if f then
			local forst = f.sampel == 0
			f.sampel += 1
			-- B4a: ett fall medan försöket pågår (bara för en bom som kan falla).
			if f._fysisk and f._uppsatt and f._fallT == nil and h._del == f._delRef then
				local y = bomY(f._delRef)
				if y ~= nil and (f._bomY0 :: number) - y > h.tjocklek then f._fallT = t end
			end
			--[[ LANDNINGSKEDJAN (granskning R1): luft följd DIREKT av mark är
				en observerad landning. Okänd evidens bryter kedjan — en senare
				mark återupplivar inte den gamla luften. En ny luft → mark efter
				luckan räknas igen. ]]
			if luft == "luft" then
				f.luftSampel += 1
				f._luftAktiv = true
			elseif luft == "mark" then
				f.markSampel += 1
				if f._luftAktiv then f._markEfterLuft = true end
				f._luftAktiv = false
			else
				f.okandSampel += 1
				f._luftAktiv = false
			end
			--[[ KORSNINGSKANDIDATEN (granskning R2). Varje OBSERVERAT segment
				som når eller korsar planet sparar var det gjorde det, ur sin
				egen geometri. Kordan mellan två avlägsna bekräftade lägen
				används aldrig: den kan hoppa över bommens ände åt båda hållen.
				Det är det SENASTE planmötet som gäller: ett sidbyte kräver att v
				byter tecken, alltså ett nytt observerat planmöte, som skriver
				över det gamla. Kandidaten dör med försöket vid ett brott.
				Minnet är ett läge. ]]
			if (v0 <= 0 and v1 >= 0) or (v0 >= 0 and v1 <= 0) then
				local k = if v0 == v1 then 1 else v0 / (v0 - v1)
				f._kandU = u0 + k * (u1 - u0)
				f._kandY = fran.Y + k * (till.Y - fran.Y)
			end
			--[[ SIDBYTE (granskning R1): passage kräver att hästen BEKRÄFTAT
				varit på båda sidor, med |v| > SID_TOL. Prov på planet eller i
				bruset kring det ändrar ingen sida, så att nå planet och vända
				är inte en passage. Var korsningen skedde avgörs av kandidaten. ]]
			if forst and math.abs(v0) > HinderObservation.SID_TOL then
				f._sida = if v0 > 0 then 1 else -1
			end
			local sida = if v1 > HinderObservation.SID_TOL then 1
				elseif v1 < -HinderObservation.SID_TOL then -1 else 0
			if sida ~= 0 then
				if f._sida ~= nil and sida ~= f._sida then
					--[[ Kandidaten finns alltid här: ett bekräftat sidbyte betyder
						att v bytt tecken, och försökets segment är sammanhängande
						(ett brott stänger försöket), så något observerat segment
						har nått planet. ]]
					local uX, yX = f._kandU :: number, f._kandY :: number
					if math.abs(uX) <= h.bredd / 2 then
						if not f._korsat then
							f._korsat = true
							f.tPassage = t
							f.riktning = if f._sida < 0 then "fram" else "bak"
						end
						if overlappar(h, uX, 0, yX, halv) then
							f.overlapp = true
							f.overlappAntal += 1
						end
					else
						f._sidanOm = true
					end
				end
				f._sida = sida
			end
			if overlappar(h, u1, v1, till.Y, halv) then
				f.overlapp = true
				f.overlappAntal += 1
			end
			if not iZon(h, u1, v1) then
				stangForsok(r, f, "fullstandig", t)
			end
		end
	end
	return true
end

--[[ Ett brott i ridobservationen: varje pågående försök i ritten stängs
	med okänt utfall. Ingenting byggs över brottet. ]]
function HinderObservation.brott(rittId: string?, t: number?)
	local r = rittId and ritter[rittId]
	if not r or not r.oppen then return end
	for _, f in pairs(r._aktiva) do stangForsok(r, f, "brott", t) end
	vantande(r, t, "ej_fullstandigt") -- B4a: ett brott under fönstret är okänt
end

function HinderObservation.avsluta(rittId: string?, satt: string): boolean
	local r = rittId and ritter[rittId]
	if not r or not r.oppen then return false end
	for _, f in pairs(r._aktiva) do stangForsok(r, f, "ritten_slut", nil) end
	vantande(r, nil, "ritten_slut") -- B4a: ritten slut under fönstret är okänt
	r.oppen = false
	r.satt = satt
	table.insert(avslutade, r.rittId)
	while #avslutade > HinderObservation.MAX_AVSLUTADE do
		local aldst = table.remove(avslutade, 1)
		ritter[aldst] = nil
		gallrade += 1
	end
	return true
end

local function frys(t: any): any
	if type(t) ~= "table" then return t end
	local kopia = {}
	for k, v in pairs(t) do
		if type(k) ~= "string" or string.sub(k, 1, 1) ~= "_" then kopia[k] = frys(v) end
	end
	return table.freeze(kopia)
end

function HinderObservation.ogonblick(rittId: string?): any
	local r = rittId and ritter[rittId]
	if not r then return nil end
	return frys({
		v = r.v, rittId = r.rittId, hastId = r.hastId, userId = r.userId,
		oppen = r.oppen, satt = r.satt, overflode = r.overflode, tappade = r.tappade,
		enheter = { langd = "studs", tid = "s" },
		forsok = r.forsok,
	})
end

--[[ Registrets innehåll, fryst: giltiga hinder och avvisade id:n.
	`generation` (se ovan) och `flyttad` är rena tillägg (#264 markbom).
	`flyttad` är en LEVANDE jämförelse av HELA geometrin (markbom R1):
	delens nuvarande läge, breddaxel (med tecken — en vriden bom byter
	normalens riktning), bredd, tjocklek och överkant jämförs med det
	registrerade, genom samma `geometri()`. Registret läser inte om
	geometrin vid en ändring, så en konsument som använder den cachade
	geometrin måste veta när den inte längre stämmer. STÄNGD VID FEL:
	saknad del, ingen förälder, ogiltig eller icke-ändlig geometri, eller
	ett fel i läsningen räknas som ändrad. Toleranser: 0,01 studs för läge
	och mått, 1e-4 för axelns komponenter. ]]
local TOL_LAGE, TOL_AXEL = 0.01, 1e-4
local function andrad(h: Hinder): boolean
	local del = h._del
	local ok, ut = pcall(function()
		if del == nil or del.Parent == nil then return true end
		local g = geometri(del)
		if not g then return true end
		return math.abs(g.cx - h.cx) > TOL_LAGE or math.abs(g.cy - h.cy) > TOL_LAGE
			or math.abs(g.cz - h.cz) > TOL_LAGE
			or math.abs(g.ux - h.ux) > TOL_AXEL or math.abs(g.uz - h.uz) > TOL_AXEL
			or math.abs(g.bredd - h.bredd) > TOL_LAGE or math.abs(g.tjocklek - h.tjocklek) > TOL_LAGE
			or math.abs(g.topp - h.topp) > TOL_LAGE
	end)
	return (not ok) or ut ~= false
end

function HinderObservation.register(): any
	local ut = {}
	for id, h in pairs(hinder) do
		ut[id] = { id = id, x = h.cx, y = h.cy, z = h.cz, bredd = h.bredd,
			breddaxel = { x = h.ux, z = h.uz }, normal = { x = h.nx, z = h.nz }, topp = h.topp,
			tjocklek = h.tjocklek, generation = generation[id] or 0, flyttad = andrad(h),
			fysisk = kanFalla(h._del) } -- B4a
	end
	return frys({ hinder = ut, avvisade = avvisade })
end

function HinderObservation.gallrade(): number
	return gallrade
end

function HinderObservation._glomForProv()
	hinder = {}
	avvisade = {}
	delar = {}
	generation = {}
	ritter = {}
	avslutade = {}
	gallrade = 0
end

--[[ Provkrok: hur många levande delar registret håller för ett id. ]]
function HinderObservation._delarForProv(id: string): number
	return (antalDelar(id))
end

function HinderObservation._glomRitterForProv()
	ritter = {}
	avslutade = {}
	gallrade = 0
end

return HinderObservation
