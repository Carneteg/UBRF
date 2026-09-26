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

	Försök: hästen kommer in i hindrets zon (|u| ≤ bredd/2 + ZON_SIDA,
	|v| ≤ ZON_DJUP i hindrets eget system), eller ett segment korsar
	hindrets plan. Försöket står tills hon lämnar zonen, och ger då ETT
	utfall — inga upprepningar medan hon står i zonen. Nytt inträde = nytt
	försök med eget löpnummer per hinder.

	Utfall:
	  · `passage`       segmentet korsar hindrets plan INNANFÖR bredden;
	                    `riktning` "fram" (−v → +v) eller "bak",
	  · `sidan_om`      planet korsas utanför bredden,
	  · `ingen_passage` zonen lämnades utan korsning,
	  · och giltighet `brott`, `ritten_slut` eller `hinder_borttaget`, där
	    utfallet är `okant`.

	Luftfas och landning är OBSERVATIONER av hästens `FloorMaterial` på
	servern ("luft" = Air, "mark" = annat, okänd = saknas). För en häst vars
	fysik ägs av ryttarens klient kan serverns värde vara inaktuellt; det är
	inte provat i motorn. Observerad luftfas är inte ett bevis på ett
	korrekt hopp, och saknad markevidens är aldrig en lyckad landning.

	ÖVERLAPP ÄR INTE RIVNING. Bommen har `CanCollide = false`, så någon
	fysisk kontakt finns inte att observera: `kontakt` är alltid
	"otillganglig". `overlapp` betyder bara att hästens rot (som låda) och
	bommen (som låda) skär varandra geometriskt vid ett sampel eller vid
	korsningen. `rivning` är aldrig sann av överlapp, närhet eller passage;
	en bom som ligger kvar är aldrig riven. Har bommen flyttats sedan
	registreringen står det som `bom = "flyttad"` — en observation, inget
	straff.

	── MINNE ─────────────────────────────────────────────────────────
	Per steg O(antal hinder). Per ritt högst MAX_FORSOK försök; fler tappas
	och `overflode` sätts. Avslutade ritter i en ring om MAX_AVSLUTADE.
	Ögonblicksbilder är frysta djupkopior. Inga lyssnare per ritt.

	Inget här är fuskskydd, poäng, domare, belöning eller persistens. ]]

local HinderObservation = {}

HinderObservation.VERSION = 1
HinderObservation.ZON_SIDA = 1.5
HinderObservation.ZON_DJUP = 6
HinderObservation.MAX_FORSOK = 64
HinderObservation.MAX_AVSLUTADE = 32
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
	_korsat: boolean, _sidanOm: boolean, _luftSist: number?, _markEfterLuft: boolean,
}
type Ritt = {
	v: number, rittId: string, hastId: string, userId: number,
	oppen: boolean, satt: string?, overflode: boolean, tappade: number,
	forsok: { Forsok }, _aktiva: { [string]: Forsok }, _nr: { [string]: number },
}

local hinder: { [string]: Hinder } = {}
local avvisade: { [string]: string } = {}
local sedda: { [string]: any } = {}
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

function HinderObservation.registrera(del: any): (boolean, string?)
	local ok, id = pcall(function() return del:GetAttribute("HinderId") end)
	if not ok or type(id) ~= "string" or id == "" or #id > MAX_ID then
		return false, "ogiltigt_id"
	end
	--[[ En DUBBLETT är en ANNAN del med samma id — då avvisas båda. Samma
		del som registreras igen (den flyttas i trädet, eller ett tidigare
		försök föll på geometrin) är ingen dubblett. ]]
	local forst = sedda[id]
	if forst == nil then
		sedda[id] = del
	elseif forst ~= del or avvisade[id] == "dubbelt_id" then
		hinder[id] = nil
		avvisade[id] = "dubbelt_id"
		return false, "dubbelt_id"
	end
	local h = geometri(del)
	if not h then
		avvisade[id] = "ogiltig_geometri"
		return false, "ogiltig_geometri"
	end
	h.id = id
	hinder[id] = h
	avvisade[id] = nil
	return true, nil
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
	r._aktiva[f.hinderId] = nil
end

--[[ Ett hinder som tagits bort: varje pågående försök vid det stängs. ]]
function HinderObservation.avregistrera(id: string)
	for _, r in pairs(ritter) do
		local f = r._aktiva[id]
		if f then stangForsok(r, f, "hinder_borttaget", nil) end
	end
	hinder[id] = nil
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
		for id, h in pairs(hinder) do
			if h._del == d then HinderObservation.avregistrera(id) end
		end
	end)
end

--[[ ── OBSERVATIONEN ─────────────────────────────────────────────── ]]

function HinderObservation.starta(rittId: string, hastId: string, userId: number): boolean
	if type(rittId) ~= "string" or rittId == "" or ritter[rittId] then return false end
	ritter[rittId] = {
		v = HinderObservation.VERSION, rittId = rittId, hastId = tostring(hastId),
		userId = tonumber(userId) or 0, oppen = true, satt = nil, overflode = false, tappade = 0,
		forsok = {}, _aktiva = {}, _nr = {},
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
		_korsat = false, _sidanOm = false, _luftSist = nil, _markEfterLuft = false,
	}
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
			f.sampel += 1
			if luft == "luft" then
				f.luftSampel += 1
				f._luftSist = t
			elseif luft == "mark" then
				f.markSampel += 1
				if f._luftSist then f._markEfterLuft = true end
			else
				f.okandSampel += 1
			end
			if korsar and uK then
				if math.abs(uK) <= h.bredd / 2 then
					if not f._korsat then
						f._korsat = true
						f.tPassage = t
						f.riktning = if v0 < 0 then "fram" else "bak"
					end
					if overlappar(h, uK, 0, yK or till.Y, halv) then
						f.overlapp = true
						f.overlappAntal += 1
					end
				else
					f._sidanOm = true
				end
			elseif overlappar(h, u1, v1, till.Y, halv) then
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
end

function HinderObservation.avsluta(rittId: string?, satt: string): boolean
	local r = rittId and ritter[rittId]
	if not r or not r.oppen then return false end
	for _, f in pairs(r._aktiva) do stangForsok(r, f, "ritten_slut", nil) end
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

--[[ Registrets innehåll, fryst: giltiga hinder och avvisade id:n. ]]
function HinderObservation.register(): any
	local ut = {}
	for id, h in pairs(hinder) do
		ut[id] = { id = id, x = h.cx, y = h.cy, z = h.cz, bredd = h.bredd,
			breddaxel = { x = h.ux, z = h.uz }, normal = { x = h.nx, z = h.nz }, topp = h.topp }
	end
	return frys({ hinder = ut, avvisade = avvisade })
end

function HinderObservation.gallrade(): number
	return gallrade
end

function HinderObservation._glomForProv()
	hinder = {}
	avvisade = {}
	sedda = {}
	ritter = {}
	avslutade = {}
	gallrade = 0
end

function HinderObservation._glomRitterForProv()
	ritter = {}
	avslutade = {}
	gallrade = 0
end

return HinderObservation
