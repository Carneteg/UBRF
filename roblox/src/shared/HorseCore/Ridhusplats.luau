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
	"ogiltig_geometri:<id>", "degenererad_riktning", "fel_forankring".

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

--[[ Delens utsträckning längs en världsriktning: projektionen av dess egen
	låda, så att en vriden del mäts rätt. ]]
local function halvUtstrackning(del: BasePart, riktning: Vector3): number
	local cf, s = del.CFrame, del.Size
	local p = cf.Position
	local function axel(x: number, y: number, z: number): Vector3
		return (cf * CFrame.new(x, y, z)).Position - p
	end
	local ax, ay, az = axel(1, 0, 0), axel(0, 1, 0), axel(0, 0, 1)
	return (math.abs(dot(ax, riktning)) * s.X + math.abs(dot(ay, riktning)) * s.Y
		+ math.abs(dot(az, riktning)) * s.Z) / 2
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

	--[[ Riktningen A → C: layoutens längsta horisontella axel, med tecknet
		ur banans mitt (som ligger mot C, eftersom banan fortsätter bortom
		C-linjen). För liten förskjutning = tecknet är inte belagt. ]]
	local cf, sz = dressyr.CFrame, dressyr.Size
	local p0 = cf.Position
	local ax = (cf * CFrame.new(1, 0, 0)).Position - p0
	local az = (cf * CFrame.new(0, 0, 1)).Position - p0
	local axel = if sz.Z >= sz.X then az else ax
	local plan = Vector3.new(axel.X, 0, axel.Z)
	if plan.Magnitude < 1e-3 then return nil, "degenererad_riktning" end
	local langsAxel = plan.Unit
	local fors = bana.Position - dressyr.Position
	local proj = dot(Vector3.new(fors.X, 0, fors.Z), langsAxel)
	if math.abs(proj) < Ridhusplats.MIN_FORSKJUTNING then return nil, "degenererad_riktning" end
	local motC = if proj > 0 then langsAxel else -langsAxel
	local tvars = cross(motC, UPP)
	local golvY = bana.Position.Y + halvUtstrackning(bana, UPP)

	local dLangs = halvUtstrackning(dressyr, motC)
	local dTvars = halvUtstrackning(dressyr, tvars)
	local dC = dressyr.Position
	local aKant = Vector3.new(dC.X, golvY, dC.Z) - motC * dLangs
	local cKant = Vector3.new(dC.X, golvY, dC.Z) + motC * dLangs

	return table.freeze({
		v = Ridhusplats.VERSION,
		enhet = "studs",
		studsPerMeter = Ridhusplats.STUDS_PER_METER,
		motC = motC,
		tvars = tvars,
		golvY = golvY,
		origo = aKant,
		bana = table.freeze({
			id = Ridhusplats.ID.bana, centrum = bana.Position,
			halvLangs = halvUtstrackning(bana, motC), halvTvars = halvUtstrackning(bana, tvars),
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
