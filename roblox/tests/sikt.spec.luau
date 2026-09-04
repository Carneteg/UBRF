--!nostrict
--[[
	Siktgrinden i Roblox-spåret (issue #78 § 3).

	Webben mäter att figuren syns från spelets kamera (tools/siktgrind.mjs).
	Här mäts motsvarigheten för Roblox: från var och en av de fasta
	reviewkamerorna i Vyer.luau (gruppen "Visuell grind", samma ID som
	qa/visual-gate/kameror.json) skjuts sträckan kamera → figur genom de
	byggda delarna. Varje opak del som sträckan går igenom MÅSTE bära
	attributet `Genomsiktlig` — det är de delar klientens Genomsikt tonar —
	annars är figuren dold bakom något som aldrig kommer att tona.

	Samma slut som webben: sträckan slutar 0,5 m före figuren, så att det
	hon står intill inte räknas. Tre kroppspunkter (höft, bröst, huvud) och
	de två axlarna; fyra av fem bakom otonbar geometri = DOLD = FEL.

	Negativ kontroll: samma mätning med `Genomsiktlig` bortsett från MÅSTE
	ge minst en dold punkt — annars mäter specen ingenting.

	Kör: python3 roblox/tests/build.py tests/sikt.spec.luau
	     && luau roblox/tests/.build/sikt.spec.luau
]]

local fails = 0
local function check(namn, villkor, detalj)
	if villkor then
		print(string.format("  OK   %s%s", namn, detalj and ("  " .. detalj) or ""))
	else
		fails += 1
		print(string.format("  FEL  %s%s", namn, detalj and ("  " .. detalj) or ""))
	end
end

local M = BuildKit.M
local modell = workspace:FindFirstChild("Anläggning"):FindFirstChild("UBRF")
local delar = {}
for _, d in ipairs(modell:GetDescendants()) do
	if d.CFrame and d.Size then table.insert(delar, d) end
end

-- Delens låda i METER.
local function lada(d)
	local p, s = d.CFrame.Position, d.Size
	return { x0 = (p.X - s.X / 2) / M, x1 = (p.X + s.X / 2) / M,
		z0 = (p.Y - s.Y / 2) / M, z1 = (p.Y + s.Y / 2) / M,
		y0 = (p.Z - s.Z / 2) / M, y1 = (p.Z + s.Z / 2) / M }
end

-- Skär sträckan o + t·d, t ∈ (0, tMax), lådan? (slab-test)
local function skar(o, d, tMax, b)
	local t0, t1 = 0, tMax
	local lo = { b.x0, b.z0, b.y0 }
	local hi = { b.x1, b.z1, b.y1 }
	for k = 1, 3 do
		if math.abs(d[k]) < 1e-9 then
			if o[k] < lo[k] or o[k] > hi[k] then return false end
		else
			local a, c = (lo[k] - o[k]) / d[k], (hi[k] - o[k]) / d[k]
			if a > c then a, c = c, a end
			if a > t0 then t0 = a end
			if c < t1 then t1 = c end
			if t0 > t1 then return false end
		end
	end
	return true
end

local function opak(d)
	local t = d.Transparency or 0
	return t < 0.5 and d.CanCollide ~= false or (t < 0.5 and d.CanCollide == false and not d.Name:find("markör"))
end

local function prov(v, ignoreraGenomsiktlig)
	local fx, fy, fz = v.figur.x, v.figur.y, v.figur.z
	local kx, ky, kz = v.fran.x, v.fran.y, v.fran.h
	local vdx, vdy = fx - kx, fy - ky
	local vL = math.sqrt(vdx * vdx + vdy * vdy)
	local sx, sy = -vdy / vL, vdx / vL
	local punkter = {
		hoft = { 0, 0.9, 0 }, brost = { 0, 1.25, 0 }, huvud = { 0, 1.6, 0 },
		axelV = { -0.25 * sx, 1.25, -0.25 * sy }, axelH = { 0.25 * sx, 1.25, 0.25 * sy },
	}
	local blockerade, skymmande = 0, {}
	for namn, off in pairs(punkter) do
		local o = { kx, kz, ky }
		local mal = { fx + off[1], fz + off[2], fy + off[3] }
		local d = { mal[1] - o[1], mal[2] - o[2], mal[3] - o[3] }
		local L = math.sqrt(d[1] ^ 2 + d[2] ^ 2 + d[3] ^ 2)
		local tMax = math.max(0, L - 0.5) / L
		local block = false
		for _, del in ipairs(delar) do
			if opak(del) and (ignoreraGenomsiktlig or del:GetAttribute("Genomsiktlig") ~= true) then
				if skar(o, d, tMax, lada(del)) then
					block = true
					skymmande[del.Name] = true
				end
			end
		end
		if block then blockerade += 1 end
	end
	local namn = {}
	for n in pairs(skymmande) do table.insert(namn, n) end
	table.sort(namn)
	return blockerade, namn
end

print("\nSiktgrinden — reviewkamerorna i Vyer.luau")
check("Vyer har reviewkamerorna", Vyer.reviewkameror ~= nil and #Vyer.reviewkameror == 14,
	Vyer.reviewkameror and (#Vyer.reviewkameror .. " st") or "saknas")

local negDolda = 0
for _, v in ipairs(Vyer.reviewkameror or {}) do
	local n, namn = prov(v, false)
	check(string.format("%s: figuren syns från reviewkameran (%d/5 punkter bakom otonbar geometri)", v.id, n),
		n < 4, #namn > 0 and ("skymmande: " .. table.concat(namn, ", ")) or nil)
	local nn = prov(v, true)
	if nn >= 4 then negDolda += 1 end
end
--[[ Negativ kontroll: en KONTROLLVY som avsiktligt står bakom en tonbar
	vägg — i gång A söder om klubbdelens genomgående vägg, med figuren i
	lobbyn norr om den (S-data, inte tal). Med Genomsiktlig ska figuren
	synas (väggen tonas); utan attributet ska hon vara DOLD. Kontrollen
	ligger i specen och inte i reviewkamerorna, så att den inte tappar
	sin mening när en reviewkamera flyttas in i ett rum. ]]
local Sd, So = UBRFKomplex.stall, UBRFKomplex.stall.origo
local kx = (Sd.gangar.A.x0 + Sd.gangar.A.x1) / 2
local kontroll = {
	id = "KONTROLL-genomgaende",
	fran = { x = So.x + kx, y = So.y + Sd.klubb.y0 - 2.0, h = 2.25 },
	figur = { x = So.x + kx, y = So.y + Sd.klubb.y0 + 2.0, z = 0 },
}
local kMed = prov(kontroll, false)
local kUtan = prov(kontroll, true)
check("kontrollvyn genom den genomgående väggen: figuren syns när väggen tonas", kMed < 4, kMed .. "/5")
check("negativ kontroll: utan Genomsiktlig är figuren DOLD bakom den genomgående väggen", kUtan >= 4, kUtan .. "/5")
if negDolda > 0 then print(string.format("  (utan Genomsiktlig blir dessutom %d reviewkamera/-or dolda)", negDolda)) end

if fails > 0 then
	print(string.format("%d mätning(ar) föll.", fails))
	os.exit(1)
else
	print("Siktgrinden: alla gröna")
end
