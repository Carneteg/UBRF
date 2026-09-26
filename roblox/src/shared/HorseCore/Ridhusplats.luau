--!strict
--[[ RIDHUSPLATS — ridhusets plats löst ur de BYGGDA delarna (#264 INFRA-PLATS1).

	En liten gemensam platsgrund för server och klient, så att instruktörens
	gestalt, framtida ridvägsövningar och tävlingar läser SAMMA plats som den
	byggda anläggningen — inte en andra koordinatkatalog.

	── KÄLLAN ────────────────────────────────────────────────────────
	`src/site.js` → `UBRFKomplex.ridhus` (bana, dressyr) → `Anlaggningen`
	(`byggRidhusInre`) bygger och speglar två delar direkt under ridhusets
	modell, med attributet `PlatsId`:

	  · `ridhus_bana`     "Ridbanan" — den FYSISKA ridytan sarg till sarg,
	  · `ridhus_dressyr`  "Dressyrlayout 20x60" — layouten, förankrad i A
	                      (attributet `Forankring` = "A").

	Båda är okolliderande och sågas därför aldrig av öppningssteget.
	"Sarg syd" används INTE: den sågas av södra dörren i två bitar med
	samma namn och utan attribut, så en bit hittad på namn är ingen stabil
	identitet (uppmätt i INFRA-PLATS1).

	Den fysiska banan och dressyrlayouten är SKILDA ytor: banan fortsätter
	bortom layoutens C-linje. De blandas aldrig ihop här.

	── ENHETER OCH AXLAR ──────────────────────────────────────────────
	Världen i studs; det lokala systemet i meter (STUDS_PER_METER = 3, samma
	som `BuildKit.M`). Lokala axlar, ur geometrin och inte ur en antagen
	vridning:
	  · v  längs banan, från A mot C (`motC`: layoutens längdaxel i planet,
	       med tecknet ur att banan fortsätter bortom C — banans mitt ligger
	       alltså mot C från layoutens mitt),
	  · u  tvärs, `tvars` = motC × upp,
	  · h  höjd över sandens överkant.
	Origo är dressyrlayoutens A-kant, mitt på.

	── GILTIGHET ─────────────────────────────────────────────────────
	Varje upplösning läser de levande delarna på nytt; inget cachas, så en
	borttagen del ger aldrig en gammal giltig plats. Saknad, feltypad eller
	dubbel identitet, icke-ändliga mått, degenererad riktning eller fel
	förankring ger (nil, skäl) — aldrig en gissad reserv. Skälen:
	"ingen_byggnad", "saknas:<id>", "feltyp:<id>", "dubbelt_id:<id>",
	"ogiltig_geometri:<id>", "ogiltig_bas:<id>", "lutande_yta:<id>",
	"ej_samriktade", "ej_a_forankrad", "layout_utanfor_bana",
	"degenererad_riktning", "fel_forankring".

	Allt returnerat är fryst. ]]

local Ridhusplats = {}

Ridhusplats.VERSION = 1
Ridhusplats.STUDS_PER_METER = 3
Ridhusplats.ID = { bana = "ridhus_bana", dressyr = "ridhus_dressyr" }
--[[ Minsta avstånd (studs) mellan banans och layoutens mitt längs
	längdaxeln för att tecknet A → C ska vara belagt. ]]
Ridhusplats.MIN_FORSKJUTNING = 0.5

local UPP = Vector3.new(0, 1, 0)

--[[ Skalär- och kryssprodukt uttryckligen, så att modulen bara behöver
	komponenterna, +, − och skalning — samma i motorn som i båda bänkarna. ]]
local function dot(a: Vector3, b: Vector3): number
	return a.X * b.X + a.Y * b.Y + a.Z * b.Z
end
local function cross(a: Vector3, b: Vector3): Vector3
	return Vector3.new(a.Y * b.Z - a.Z * b.Y, a.Z * b.X - a.X * b.Z, a.X * b.Y - a.Y * b.X)
end

local function andligt(v: any): boolean
	return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge
end

local function vektorOk(p: any): boolean
	if p == nil then return false end
	local ok, x, y, z = pcall(function() return p.X, p.Y, p.Z end)
	return ok and andligt(x) and andligt(y) and andligt(z)
end

--[[ ── DEN BEGRÄNSADE MODELLENS FÖRUTSÄTTNINGAR (granskning R1) ────────
	Modellen stödjer EN sorts underlag: två horisontella, samriktade,
	rektangulära ytor, där layouten är A-förankrad i banans A-ände och
	ligger helt inom banan. En gemensam godtycklig girning och flytt av hela
	byggnaden är giltig. Allt annat ger ett uttryckligt nej — ingen
	omskrivande ruta får maskera en vriden eller förskjuten yta.

	Toleranser (spelantaganden, i dagens byggda bana uppfyllda med marginal):
	  · TOL_AXEL     basaxlarnas längd och inbördes vinkelräthet (1e-3),
	  · TOL_RIKTNING |cos| för horisontell yta och samriktade längdaxlar
	                 (1 − 1e-4, alltså under ~0,8°),
	  · TOL_LAGE     A-förankring och "inom banan", i studs (0,1). ]]
Ridhusplats.TOL_AXEL = 1e-3
Ridhusplats.TOL_RIKTNING = 1e-4
Ridhusplats.TOL_LAGE = 0.1

type Ram = { p: Vector3, langs: Vector3, tvarsAxel: Vector3, halvLangs: number, halvTvars: number, halvHojd: number }

--[[ En dels ram: ändliga basaxlar som är enhetsvektorer och vinkelräta,
	positiva mått, och uppaxeln längs världens upp. Längdaxeln är den längre
	av de två horisontella axlarna. (ram, nil) eller (nil, skäl). ]]
local function ram(del: BasePart, id: string): (Ram?, string?)
	local cf, s = del.CFrame, del.Size
	local p = cf.Position
	if not (vektorOk(p) and vektorOk(s)) then return nil, "ogiltig_geometri:" .. id end
	if not (s.X > 0 and s.Y > 0 and s.Z > 0) then return nil, "ogiltig_geometri:" .. id end
	local function axel(x: number, y: number, z: number): Vector3
		return (cf * CFrame.new(x, y, z)).Position - p
	end
	local ax, ay, az = axel(1, 0, 0), axel(0, 1, 0), axel(0, 0, 1)
	if not (vektorOk(ax) and vektorOk(ay) and vektorOk(az)) then return nil, "ogiltig_bas:" .. id end
	for _, v in ipairs({ ax, ay, az }) do
		if math.abs(v.Magnitude - 1) > Ridhusplats.TOL_AXEL then return nil, "ogiltig_bas:" .. id end
	end
	if math.abs(dot(ax, ay)) > Ridhusplats.TOL_AXEL or math.abs(dot(ay, az)) > Ridhusplats.TOL_AXEL
		or math.abs(dot(ax, az)) > Ridhusplats.TOL_AXEL then
		return nil, "ogiltig_bas:" .. id
	end
	if dot(ay, UPP) < 1 - Ridhusplats.TOL_RIKTNING then return nil, "lutande_yta:" .. id end
	local langsX = s.X >= s.Z
	return {
		p = p,
		langs = if langsX then ax else az,
		tvarsAxel = if langsX then az else ax,
		halvLangs = (if langsX then s.X else s.Z) / 2,
		halvTvars = (if langsX then s.Z else s.X) / 2,
		halvHojd = s.Y / 2,
	}, nil
end

local function hitta(ridhus: Instance): ({ [string]: BasePart }?, string?)
	local funna: { [string]: { any } } = {}
	--[[ Grunt uppslag, som `UgnetaGestalt` redan gjorde: `BuildKit.box`
		hänger delarna direkt under byggnadens Model. ]]
	for _, d in ipairs(ridhus:GetChildren()) do
		local ok, id = pcall(function() return d:GetAttribute("PlatsId") end)
		if ok and type(id) == "string" then
			funna[id] = funna[id] or {}
			table.insert(funna[id], d)
		end
	end
	local ut: { [string]: BasePart } = {}
	for _, id in ipairs({ Ridhusplats.ID.bana, Ridhusplats.ID.dressyr }) do
		local lista = funna[id]
		if not lista or #lista == 0 then return nil, "saknas:" .. id end
		if #lista > 1 then return nil, "dubbelt_id:" .. id end
		local d = lista[1]
		if not d:IsA("BasePart") then return nil, "feltyp:" .. id end
		local ok, cf, s = pcall(function() return d.CFrame, d.Size end)
		if not ok or not vektorOk(s) or not cf or not vektorOk(cf.Position) then
			return nil, "ogiltig_geometri:" .. id
		end
		ut[id] = d :: BasePart
	end
	return ut, nil
end

--[[ Löser ridhusets plats ur de byggda delarna. (plats, nil) eller
	(nil, skäl). ]]
function Ridhusplats.los(ridhus: Instance?): (any, string?)
	if not ridhus then return nil, "ingen_byggnad" end
	local d, skal = hitta(ridhus)
	if not d then return nil, skal end
	local bana, dressyr = d[Ridhusplats.ID.bana], d[Ridhusplats.ID.dressyr]

	local ok, forankring = pcall(function() return dressyr:GetAttribute("Forankring") end)
	if not ok or forankring ~= "A" then return nil, "fel_forankring" end

	local rb, fb = ram(bana, Ridhusplats.ID.bana)
	if not rb then return nil, fb end
	local rd, fd = ram(dressyr, Ridhusplats.ID.dressyr)
	if not rd then return nil, fd end

	--[[ Samriktade längdaxlar (tecknet spelar ingen roll här). ]]
	if math.abs(dot(rb.langs, rd.langs)) < 1 - Ridhusplats.TOL_RIKTNING then
		return nil, "ej_samriktade"
	end

	--[[ Riktningen A → C: layoutens längdaxel, med tecknet ur banans mitt
		(som ligger mot C, eftersom banan fortsätter bortom C-linjen). För
		liten förskjutning = tecknet är inte belagt. ]]
	local langsAxel = Vector3.new(rd.langs.X, 0, rd.langs.Z).Unit
	local fors = rb.p - rd.p
	local proj = dot(Vector3.new(fors.X, 0, fors.Z), langsAxel)
	if math.abs(proj) < Ridhusplats.MIN_FORSKJUTNING then return nil, "degenererad_riktning" end
	local motC = if proj > 0 then langsAxel else -langsAxel
	local tvars = cross(motC, UPP)

	--[[ A-förankring: layoutens A-kant och banans A-ände sammanfaller längs
		banan. Inom banan: layoutens tvärsläge och C-kant ryms i banan. ]]
	local banaA = rb.p - motC * rb.halvLangs
	local layoutA = rd.p - motC * rd.halvLangs
	if math.abs(dot(layoutA - banaA, motC)) > Ridhusplats.TOL_LAGE then return nil, "ej_a_forankrad" end
	local tvarsFors = math.abs(dot(fors, tvars))
	if tvarsFors + rd.halvTvars > rb.halvTvars + Ridhusplats.TOL_LAGE
		or rd.halvLangs * 2 > rb.halvLangs * 2 + Ridhusplats.TOL_LAGE then
		return nil, "layout_utanfor_bana"
	end

	local golvY = rb.p.Y + rb.halvHojd
	local dLangs, dTvars = rd.halvLangs, rd.halvTvars
	local dC = rd.p
	local aKant = Vector3.new(dC.X, golvY, dC.Z) - motC * dLangs
	local cKant = Vector3.new(dC.X, golvY, dC.Z) + motC * dLangs
	--[[ Ingen egen slutvakt för de härledda värdena: varje indata ovan är
		redan prövad som ändlig (läge, mått, ortonormala axlar), och det som
		härleds är summor, skalningar och en normering av en horisontell axel
		som prövats vara nära enhetslängd. En sådan vakt var död kod och
		överlevde sin mutation (INFRA-PLATS1 R1). ]]

	return table.freeze({
		v = Ridhusplats.VERSION,
		enhet = "studs",
		studsPerMeter = Ridhusplats.STUDS_PER_METER,
		motC = motC,
		tvars = tvars,
		golvY = golvY,
		origo = aKant,
		bana = table.freeze({
			id = Ridhusplats.ID.bana, centrum = rb.p,
			halvLangs = rb.halvLangs, halvTvars = rb.halvTvars,
		}),
		dressyr = table.freeze({
			id = Ridhusplats.ID.dressyr, centrum = dC, forankring = "A",
			halvLangs = dLangs, halvTvars = dTvars, A = aKant, C = cKant,
		}),
	}), nil
end

--[[ Världsläge (studs) → lokalt (meter): u tvärs, h över golvet, v från A. ]]
function Ridhusplats.tillLokal(plats: any, varld: Vector3): Vector3
	local M = plats.studsPerMeter
	local d = varld - plats.origo
	return Vector3.new(dot(d, plats.tvars) / M, (varld.Y - plats.golvY) / M, dot(d, plats.motC) / M)
end

--[[ Lokalt (meter) → världsläge (studs). Inversen av `tillLokal`. ]]
function Ridhusplats.tillVarld(plats: any, lokal: Vector3): Vector3
	local M = plats.studsPerMeter
	local p = plats.origo + plats.tvars * (lokal.X * M) + plats.motC * (lokal.Z * M)
	return Vector3.new(p.X, plats.golvY + lokal.Y * M, p.Z)
end

--[[ Ligger ett världsläge inom ytan ("bana" eller "dressyr") i planet?
	Kanten räknas som inom. ]]
function Ridhusplats.inom(plats: any, yta: string, varld: Vector3): boolean
	local r = if yta == "bana" then plats.bana elseif yta == "dressyr" then plats.dressyr else nil
	if not r then return false end
	local d = varld - r.centrum
	return math.abs(dot(d, plats.motC)) <= r.halvLangs + 1e-6
		and math.abs(dot(d, plats.tvars)) <= r.halvTvars + 1e-6
end

return Ridhusplats
