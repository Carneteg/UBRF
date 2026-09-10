--[[ ══════════════════════════════════════════════════════════════════
     UBRF — hela anläggningen, att klistra in i Roblox Studio.

     GENERERAD av tools/studio-paket.py. Ändra inte här; ändra i
     src/site.js (geometrin) eller i roblox/buildings/ (byggandet), och
     kör om skriptet.

     Kör en gång. Sedan:

         UBRF QA-panelen öppnas av sig själv i Studio: klicka Nästa,
         titta, klicka PASS eller FEL. UBRFQA() öppnar den igen.

         Vyer.lista()             -- vyerna Studio-kontrollen kräver
         Vyer.ga("kortandan")     -- ställ kameran för hand i stället

     Kvitteringen sker i ETT dokument:

         roblox/docs/STUDIO-QA.md                 <-- kanonisk QA-lista

     Bakgrund och detaljunderlag:

         roblox/buildings/STUDIO-KONTROLL.md      komplexet, stallet, vägarna
         roblox/docs/RIDHUS-STUDIO-CHECKLISTA.md  ridhusets interiör

     Baslinje: Review 11 (kodgate passerad, Studio återstår).
     ══════════════════════════════════════════════════════════════════ ]]


--[[ ══ BuildKit.luau ══ ]]
local BuildKit = (function()
--!strict
-- BuildKit: små, förutsägbara byggstenar för UBRF-byggnader.
-- Alla mått i METER. 1 m = 3 studs. Origo för en byggnad = SV-hörnet på marknivå.
-- Körs i Studio via MCP run_code; klistras in före byggnadsskriptet (eller lagras som ModuleScript i ServerStorage.BuildKit).

local BuildKit = {}
BuildKit.M = 3 -- studs per meter

local function studs(m: number): number return m * BuildKit.M end

local function newPart(model: Model, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = model
	return p
end

-- Skapar/ersätter modellen. origin = världsposition för SV-hörnet (studs), rotY i grader.
function BuildKit.newBuilding(name: string, origin: Vector3, rotY: number?, meta: {[string]: any}?): (Model, CFrame)
	local folder = workspace:FindFirstChild("Anläggning") or Instance.new("Folder")
	folder.Name = "Anläggning"; folder.Parent = workspace
	local old = folder:FindFirstChild(name); if old then old:Destroy() end
	local model = Instance.new("Model"); model.Name = name; model.Parent = folder
	local root = newPart(model, "Root", Vector3.new(1, 0.2, 1), CFrame.new(origin) * CFrame.Angles(0, math.rad(rotY or 0), 0), Color3.new(1,1,1))
	root.Transparency = 1; root.CanCollide = false
	model.PrimaryPart = root
	for k, v in pairs(meta or {}) do model:SetAttribute(k, v) end
	return model, root.CFrame
end

-- Box i lokala meter-koordinater: x,z = SV-hörn, y = golvnivå; w=bredd(X), h=höjd(Y), d=djup(Z)
function BuildKit.box(model: Model, base: CFrame, name: string, x: number, y: number, z: number, w: number, h: number, d: number, color: Color3, material: Enum.Material?): Part
	local size = Vector3.new(studs(w), studs(h), studs(d))
	local cf = base * CFrame.new(studs(x + w/2), studs(y + h/2), studs(z + d/2))
	return newPart(model, name, size, cf, color, material)
end

-- Vägg längs X (facing = "S"/"N") eller längs Z ("W"/"E"). t = tjocklek.
function BuildKit.wall(model: Model, base: CFrame, name: string, x: number, z: number, length: number, height: number, t: number, along: "X"|"Z", color: Color3, material: Enum.Material?): Part
	if along == "X" then
		return BuildKit.box(model, base, name, x, 0, z, length, height, t, color, material)
	else
		return BuildKit.box(model, base, name, x, 0, z, t, height, length, color, material)
	end
end

-- Hål i vägg (fönster/dörr) görs enklast genom att lägga en Part med annan färg "utanpå" väggen: tydligt i tecknad stil.
-- x,z = position längs väggen (m), sill = höjd över mark, w,h = storlek, depth = hur mycket den sticker ut.
function BuildKit.opening(model: Model, base: CFrame, name: string, x: number, z: number, sill: number, w: number, h: number, along: "X"|"Z", side: number, color: Color3, material: Enum.Material?): Part
	local depth = 0.06
	if along == "X" then
		return BuildKit.box(model, base, name, x, sill, z + (side > 0 and 0 or -depth), w, h, depth, color, material or Enum.Material.Glass)
	else
		return BuildKit.box(model, base, name, x + (side > 0 and 0 or -depth), sill, z, depth, h, w, color, material or Enum.Material.Glass)
	end
end

function BuildKit.window(model: Model, base: CFrame, x: number, z: number, sill: number, w: number, h: number, along: "X"|"Z", side: number, frameColor: Color3)
	local frame = BuildKit.opening(model, base, "Fönsterkarm", x - 0.08, z, sill - 0.08, w + 0.16, h + 0.16, along, side, frameColor, Enum.Material.SmoothPlastic)
	local glass = BuildKit.opening(model, base, "Glas", x, z, sill, w, h, along, side * 2, Color3.fromRGB(170, 205, 225), Enum.Material.Glass)
	glass.Transparency = 0.3
end

function BuildKit.door(model: Model, base: CFrame, name: string, x: number, z: number, w: number, h: number, along: "X"|"Z", side: number, color: Color3)
	return BuildKit.opening(model, base, name, x, z, 0, w, h, along, side, color, Enum.Material.SmoothPlastic)
end

-- Sadeltak över fotavtryck (x,z,w,d) med takfot på höjd eaveH, lutning pitchDeg, nock längs "X" eller "Z", överhäng i meter.
function BuildKit.gableRoof(model: Model, base: CFrame, x: number, z: number, w: number, d: number, eaveH: number, pitchDeg: number, ridgeAlong: "X"|"Z", overhang: number, color: Color3, material: Enum.Material?)
	local span = (ridgeAlong == "X") and d or w   -- spännvidd tvärs nocken
	local len  = (ridgeAlong == "X") and w or d   -- längd längs nocken
	local half = span / 2 + overhang
	local rise = half * math.tan(math.rad(pitchDeg))
	local thick = 0.15
	local slope = math.sqrt(half*half + rise*rise)
	local cx, cz = x + w/2, z + d/2
	for _, s in ipairs({ -1, 1 }) do
		local p = Instance.new("Part")
		p.Name = "Takfall"; p.Anchored = true
		p.Color = color; p.Material = material or Enum.Material.SmoothPlastic
		p.Size = Vector3.new(studs(len + 2*overhang), studs(thick), studs(slope))
		local rot = (ridgeAlong == "X") and CFrame.Angles(math.rad(pitchDeg) * -s, 0, 0)
			or CFrame.Angles(0, math.rad(90), 0) * CFrame.Angles(math.rad(pitchDeg) * -s, 0, 0)
		local offX = (ridgeAlong == "X") and 0 or s * half / 2
		local offZ = (ridgeAlong == "X") and s * half / 2 or 0
		p.CFrame = base * CFrame.new(studs(cx + offX), studs(eaveH + rise/2), studs(cz + offZ)) * rot
		p.Parent = model
	end
	-- Gavelspetsar (triangel av två WedgeParts)
	local function gable(pos: number)
		for _, s in ipairs({ -1, 1 }) do
			local wdg = Instance.new("WedgePart")
			wdg.Name = "Gavelspets"; wdg.Anchored = true
			wdg.Color = model:GetAttribute("GavelFarg") or color
			wdg.Material = Enum.Material.SmoothPlastic
			wdg.Size = Vector3.new(studs(0.2), studs(rise - overhang * math.tan(math.rad(pitchDeg))), studs(span/2))
			local yaw = (ridgeAlong == "X") and (s > 0 and 0 or math.rad(180)) or (s > 0 and math.rad(90) or math.rad(-90))
			local lx = (ridgeAlong == "X") and pos or cx + s * span/4
			local lz = (ridgeAlong == "X") and cz + s * span/4 or pos
			wdg.CFrame = base * CFrame.new(studs(lx), studs(eaveH + wdg.Size.Y/BuildKit.M/2), studs(lz)) * CFrame.Angles(0, yaw, 0)
			wdg.Parent = model
		end
	end
	if ridgeAlong == "X" then gable(x + 0.1); gable(x + w - 0.1) else gable(z + 0.1); gable(z + d - 0.1) end
	return rise
end

-- Staket: stolpar + två reglar mellan punkterna (lokala meter).
function BuildKit.fence(model: Model, base: CFrame, x1: number, z1: number, x2: number, z2: number, height: number, color: Color3)
	local dx, dz = x2 - x1, z2 - z1
	local len = math.sqrt(dx*dx + dz*dz)
	local n = math.max(1, math.floor(len / 2.5))
	local yaw = math.atan2(-dz, dx)
	for i = 0, n do
		local t = i / n
		BuildKit.box(model, base, "Stolpe", x1 + dx*t - 0.06, 0, z1 + dz*t - 0.06, 0.12, height, 0.12, color, Enum.Material.Wood)
	end
	for _, hy in ipairs({ height * 0.55, height * 0.95 }) do
		local p = Instance.new("Part"); p.Name = "Regel"; p.Anchored = true; p.Color = color; p.Material = Enum.Material.Wood
		p.Size = Vector3.new(studs(len), studs(0.1), studs(0.05))
		p.CFrame = base * CFrame.new(studs(x1 + dx/2), studs(hy), studs(z1 + dz/2)) * CFrame.Angles(0, yaw, 0)
		p.Parent = model
	end
end

-- Sätter Studio-kameran i ögonhöjd på ett sätt som matchar ett foto: stå på (x,z) i lokala meter, titta mot (tx,tz).
--[[ Siktmalet lag forut fast pa 2.5 m. Det gor det omojligt att titta UPP,
	och takstommen i ridhuset gar bara att bedoma underifran. aimH ar darfor
	valbar; utan den beter sig anropet exakt som forut. ]]
function BuildKit.cameraLike(base: CFrame, x: number, z: number, tx: number, tz: number, eyeH: number?, aimH: number?)
	local cam = workspace.CurrentCamera
	local from = base * CFrame.new(studs(x), studs(eyeH or 1.6), studs(z))
	local to = base * CFrame.new(studs(tx), studs(aimH or 2.5), studs(tz))
	cam.CameraType = Enum.CameraType.Scriptable
	cam.CFrame = CFrame.lookAt(from.Position, to.Position)
end

return BuildKit

end)()

--[[ ══ Geometri.luau ══ ]]
local Geometri = (function()
--!strict
-- Ren geometri över anläggningen: inga Roblox-anrop, inga Instance, ingen
-- rendering. Bara de uträkningar som måste betyda samma sak på båda
-- plattformarna — var en öppning sitter i en fasad, och hur brant ett tak är.
--
-- Den ligger separat just för att den ska gå att MÄTA utanför Studio.
-- roblox/tests/geometri.spec.luau kör den mot samma tal som webbspelet räknar
-- fram ur src/site.js. Ligger de i samma fil som partbygget går de inte att
-- testa, och då är pariteten ett påstående i stället för ett mätvärde.
--
-- Måtten i meter. Origo i sydväst, +x öster, +y norr — samma som src/site.js.

local Geometri = {}

export type Rekt = { x: number, y: number, w: number, h: number }

-- Fasadens p0 → p1, medurs sett utifrån. EXAKT samma konvention som `vagg` i
-- src/site.js. u i en öppning mäts från p0 längs den riktningen; ändras den
-- ena måste den andra ändras med, och specen fäller det annars.
function Geometri.vagg(r: Rekt, sida: string): (number, number, number, number)
	if sida == "S" then return r.x, r.y, r.x + r.w, r.y
	elseif sida == "E" then return r.x + r.w, r.y, r.x + r.w, r.y + r.h
	elseif sida == "N" then return r.x + r.w, r.y + r.h, r.x, r.y + r.h
	elseif sida == "W" then return r.x, r.y + r.h, r.x, r.y
	end
	error("okänd sida: " .. tostring(sida))
end

-- Utåtriktad normal för en fasad.
function Geometri.normal(sida: string): (number, number)
	if sida == "S" then return 0, -1
	elseif sida == "N" then return 0, 1
	elseif sida == "E" then return 1, 0
	elseif sida == "W" then return -1, 0
	end
	error("okänd sida: " .. tostring(sida))
end

--[[ Öppningens sydvästra hörn i världskoordinater, plus hur den ska ritas.

	På N och W går p0 → p1 mot minskande koordinat, så där räknas hörnet
	baklänges — det är den detalj som är lätt att få fel och som gör att en
	dörr hamnar i fel ände av en fasad.

	Returnerar x, z, along ("X" eller "Z") och side (+1/-1 = åt vilket håll
	öppningen sticker ut ur väggen). ]]
function Geometri.oppningsHorn(r: Rekt, sida: string, u: number, b: number)
	local x0, z0 = Geometri.vagg(r, sida)
	if sida == "S" then return x0 + u, z0, "X", -1
	elseif sida == "N" then return x0 - u - b, z0, "X", 1
	elseif sida == "E" then return x0, z0 + u, "Z", 1
	else return x0, z0 - u - b, "Z", -1 end
end

-- Öppningens mittpunkt, som den ligger i fasadlivet.
function Geometri.oppningsMitt(r: Rekt, sida: string, u: number, b: number): (number, number)
	local x, z, along = Geometri.oppningsHorn(r, sida, u, b)
	if along == "X" then return x + b / 2, z else return x, z + b / 2 end
end

-- Taklutning i grader, räknad ur takfot och nock i stället för angiven: hN - hV
-- är resningen över halva spännvidden, och spännvidden avgörs av nocken.
-- "NS" = nocken löper längs y, alltså spänner taket över byggnadens bredd.
function Geometri.taklutning(rekt: Rekt, hV: number, hN: number, nock: string): number
	local spann = if nock == "NS" then rekt.w else rekt.h
	return math.deg(math.atan((hN - hV) / (spann / 2)))
end

-- Sitter två byggnader ihop? Väggarna ska mötas, inte överlappa, och de ska ha
-- ett gemensamt stycke att mötas längs. Marginalen är en decimeter: byggmåtten
-- i src/site.js står i hela och halva meter, så ett verkligt möte träffar
-- exakt och ett glapp är alltid större än så.
function Geometri.sitterIhop(a: Rekt, b: Rekt, marginal: number?): boolean
	local m = marginal or 0.1
	local overX = math.min(a.x + a.w, b.x + b.w) - math.max(a.x, b.x)
	local overY = math.min(a.y + a.h, b.y + b.h) - math.max(a.y, b.y)
	-- Möte i x-led: gaveln mot gaveln, med ett gemensamt stycke i y-led.
	if math.abs(overX) <= m and overY > m then return true end
	-- Möte i y-led: långsidan mot långsidan.
	if math.abs(overY) <= m and overX > m then return true end
	return false
end

--[[ Boxfacken i EN rad, som lokala y-intervall.

	Facken börjar vid boxStartY och är boxB djupa fram till klubbdelen. Ett
	fack som skär ett `brott` i sin rad finns inte — där går hästförbindelsen
	genom raden. Förut hoppades ett fack över i ALLA rader för en tvärkorridor
	tvärs huset; planen har ingen sådan, bara brottet i västra raden.

	Samma regel som STALLINNE.fack i src/site.js, och det exporterade `fack`
	bär webbens lista så att specen kan jämföra de två.

	Ligger här och inte i byggskriptet därför att specen måste kunna mäta samma
	fack som byggs. Skriver man logiken två gånger mäter man inte längre det man
	bygger. ]]
function Geometri.boxfack(stall, rad): { { y0: number, y1: number } }
	local fack = {}
	local y = stall.boxStartY
	while y + stall.boxB <= stall.klubbY + 0.001 do
		local y1 = y + stall.boxB
		local bruten = false
		for _, b in ipairs(stall.brott or {}) do
			if rad ~= nil and b.rad == rad.id and y1 > b.y0 + 0.01 and y < b.y1 - 0.01 then
				bruten = true
			end
		end
		if not bruten then table.insert(fack, { y0 = y, y1 = y1 }) end
		y = y1
	end
	return fack
end

--[[ En klubbdelsvägg i bitar, med sina öppningar bortdragna.

	`typ = "tvar"` löper i x på ett fast y och har öppningar som x-intervall;
	`typ = "langs"` löper i y på ett fast x och har öppningar som y-intervall.
	Bitarna kommer i samma koordinat som väggen löper i. Webben (src/world.js,
	src/varld3d.js) bygger ur samma regel: en dörr som finns i spelet finns i
	Roblox, och en som saknas saknas på båda ställena. ]]
function Geometri.vaggBitar(vagg): { { a0: number, a1: number } }
	local a0 = if vagg.typ == "tvar" then vagg.x0 else vagg.y0
	local a1 = if vagg.typ == "tvar" then vagg.x1 else vagg.y1
	local hal = {}
	for _, o in ipairs(vagg.oppningar or {}) do
		table.insert(hal, {
			a0 = if vagg.typ == "tvar" then o.x0 else o.y0,
			a1 = if vagg.typ == "tvar" then o.x1 else o.y1,
		})
	end
	table.sort(hal, function(p, q) return p.a0 < q.a0 end)
	local bitar = {}
	local a = a0
	for _, h in ipairs(hal) do
		if h.a0 - a > 0.05 then table.insert(bitar, { a0 = a, a1 = h.a0 }) end
		if h.a1 > a then a = h.a1 end
	end
	if a1 - a > 0.05 then table.insert(bitar, { a0 = a, a1 = a1 }) end
	return bitar
end

--[[ Tvärväggens bitar, som lokala x-intervall.

	En tvärvägg går inte obruten över huset — den har ett dörrgap där varje
	gång passerar, annars vore stallgången avstängd och klubbdelen oåtkomlig.
	Webbversionen bygger den i bitar mellan gångarna; det här är samma regel,
	så att Roblox inte murar igen en passage som är öppen i spelet.

	Byggbänken hittade precis det felet första gången den kördes: en obruten
	vägg vid y = 43 låg tvärs över klubbhallens gångyta.

	Gångarna kommer som en tabell med id som nyckel, och nyckelordningen i Luau
	är inte definierad — därför sorteras de på x0 innan bitarna räknas ut. ]]
--[[ Hålen i en tvärvägg: gångarna PLUS väggens egna öppningar ur brandplanen.

	Tog förut bara gångarna. Väggen mot servicedelen blev då tät framför varje
	boxrad, och spelaren som kom in genom södra gaveln möttes av en blank
	återvändsgränd — det som underkändes i spelarvyn. Väggen får sina hål ur
	planen nu, inte ur gångarnas lägen. `vagg` är valfri; utan den blir det
	som förut. ]]
--[[ Väggarna i den här listan ligger alla i boxhallen och följer gångarna.
	Klubbdelens väggar, som inte gör det, ligger i `stall.klubb.vaggar` och
	byggs genom Geometri.vaggBitar. ]]
function Geometri.tvarvaggBitar(stall, vagg): { { x0: number, x1: number } }
	local hal = {}
	for _, g in pairs(stall.gangar) do table.insert(hal, g) end
	if vagg ~= nil and vagg.oppningar ~= nil then
		for _, o in ipairs(vagg.oppningar) do table.insert(hal, o) end
	end
	table.sort(hal, function(a, b) return a.x0 < b.x0 end)

	local bitar = {}
	local x = 0
	for _, h in ipairs(hal) do
		if h.x0 - x > 0.05 then table.insert(bitar, { x0 = x, x1 = h.x0 }) end
		if h.x1 > x then x = h.x1 end
	end
	if stall.bredd - x > 0.05 then table.insert(bitar, { x0 = x, x1 = stall.bredd }) end
	return bitar
end

--[[ Läktaren i hela stycken, med hästgångens öppning bortdragen.

	Satellitbilden lägger hästgången centralt, och där kan läktaren inte vara
	obruten — man ska kunna leda hästen igenom. Samma regel som
	`laktarSektioner` i src/site.js; bygger man läktaren i ett stycke muras
	gången igen, och det syns inte förrän någon försöker gå där. ]]
--[[ En trappas steg ur dess data — DELAD regel med webben (`trappsteg` i
	src/site.js). `t` har fotavtryck x0–x1 × y0–y1, nivåerna z0 → z1 och
	`stiger`: "N" om z växer med y, "S" om z växer när y minskar. Steghöjden
	hålls under stegMax (0,19 m) så att karaktären kliver upp för den. ]]
function Geometri.trappsteg(t): { n: number, stig: number, djup: number, axel: string, steg: { { a0: number, a1: number, z: number } } }
	local ax = t.axel or "y"
	local a0 = if ax == "x" then t.x0 else t.y0
	local a1 = if ax == "x" then t.x1 else t.y1
	local stig = t.z1 - t.z0
	local n = math.max(1, math.ceil(math.abs(stig) / (t.stegMax or 0.19)))
	local djup = (a1 - a0) / n
	local bakat = (t.stiger == "S" or t.stiger == "W")
	local steg = {}
	for i = 0, n - 1 do
		local z = t.z0 + stig * (i + 1) / n
		local b0 = if bakat then a1 - djup * (i + 1) else a0 + djup * i
		table.insert(steg, { a0 = b0, a1 = b0 + djup, z = z })
	end
	return { n = n, stig = stig / n, djup = djup, axel = ax, steg = steg }
end

function Geometri.laktarSektioner(laktare): { { y0: number, y1: number } }
	local g = laktare.gap
	if not g then return { { y0 = laktare.y0, y1 = laktare.y1 } } end
	local ut = {}
	if g.y0 - laktare.y0 > 0.2 then
		table.insert(ut, { y0 = laktare.y0, y1 = g.y0 })
	end
	if laktare.y1 - g.y1 > 0.2 then
		table.insert(ut, { y0 = g.y1, y1 = laktare.y1 })
	end
	return ut
end

--[[ Läktarens bänkrader ur datan — SAMMA regel som laktarRader i src/site.js.
	Gångbrädan ligger på däckhöjd närmast banan; rad i har sitsen på
	dackZ + (i+1)·stegH och börjar gangbrada.djup + i·rader.djup in från
	däckets bankant. `in0`/`in1` är avstånd in från bankanten, `z` sitsens
	överkant. Utan `rader`/`gangbrada` i datan finns inga rader — inte fyra
	påhittade. ]]
function Geometri.laktarRader(L): { { in0: number, in1: number, z: number } }
	local r, g = L.rader, L.gangbrada
	if not r or not g then return {} end
	local ut = {}
	for i = 0, r.antal - 1 do
		table.insert(ut, {
			in0 = g.djup + i * r.djup,
			in1 = g.djup + (i + 1) * r.djup,
			z = L.dackZ + (i + 1) * r.stegH,
		})
	end
	return ut
end

--[[ Ett inredningsobjekts fotavtryck som axelparallell rektangel i husets
	lokala meter — samma regel som inredningRekt i src/inredning.js. Vänd
	norr/söder ligger bredden längs x, vänd öster/väster längs y. ]]
function Geometri.inredningRekt(o): Rekt
	local q = math.abs(math.cos(o.rikt)) < 0.5
	local w = if q then o.matt.b else o.matt.d
	local h = if q then o.matt.d else o.matt.b
	return { x = o.pos[1] - w / 2, y = o.pos[2] - h / 2, w = w, h = h }
end

-- Överlappets area mellan två rektanglar. 0 när de bara nuddar varandra.
function Geometri.overlapp(a: Rekt, b: Rekt): number
	local dx = math.min(a.x + a.w, b.x + b.w) - math.max(a.x, b.x)
	local dy = math.min(a.y + a.h, b.y + b.h) - math.max(a.y, b.y)
	if dx <= 0 or dy <= 0 then return 0 end
	return dx * dy
end

--[[ Väggfälten längs ridhusets långsidor: mellan två takstolar, klippta
     till hallens längd (A-gaveln → entrédelens vägg). Fönstren sitter ett
     per fält och pelarna på fältgränserna. Samma regel som webbens
     ridhusFalt i src/varld3d.js. ]]
function Geometri.ridhusFalt(R): { { number } }
	local TS, slut = R.takstomme, R.langd - R.entre
	local ut = {}
	local z = 0
	local p = TS.start
	while p < slut + 0.01 do
		if p - z > 0.5 then table.insert(ut, { z, math.min(p, slut) }) end
		z = p
		p += TS.delning
	end
	if slut - z > 0.5 then table.insert(ut, { z, slut }) end
	return ut
end

return Geometri

end)()

--[[ ══ UBRFKomplex.luau ══ ]]
local UBRFKomplex = (function()
--!strict
-- GENERERAD FIL — ÄNDRA INTE FÖR HAND.
--
-- Källa: src/site.js. Kör om med:  node tools/exportera-geometri.js
--
-- Anläggningens geometri, i METER. Origo i sydväst, +x öster, +y norr.
-- I Roblox blir spelets y byggnadens z; BuildKit.M räknar om meter till studs.
--
-- Det här är samma tal som webbspelet bygger sin värld av, uträknade ur samma
-- kod — inte avskrivna. Roblox och webben kan därför inte glida isär om
-- byggnadernas mått, färger, öppningar eller om vilka hus som sitter ihop.
--
-- Fidelity-klasserna hör till byggnadskorten och audits/, inte hit. Den här
-- filen säger vad som byggs, inte hur säkert det är. Läs
-- references/buildings/*/KORT.md och references/plans/OAVGJORT.md innan du
-- litar på ett enskilt mått.

return {
	bredd = 210,
	djup = 170,
	mark = {
		{
			typ = "gras",
			rekt = {
				x = 0,
				y = 0,
				w = 210,
				h = 170,
			},
		},
		{
			typ = "aker",
			rekt = {
				x = 9,
				y = 20,
				w = 99,
				h = 100,
			},
		},
		{
			typ = "asfalt",
			rekt = {
				x = 2,
				y = 0,
				w = 5,
				h = 170,
			},
		},
		{
			typ = "asfalt",
			rekt = {
				x = 207,
				y = 0,
				w = 3,
				h = 170,
			},
		},
		{
			typ = "grus",
			rekt = {
				x = 0,
				y = 146,
				w = 118,
				h = 6,
			},
		},
		{
			typ = "grus",
			rekt = {
				x = 106,
				y = 121,
				w = 48,
				h = 34,
			},
		},
		{
			typ = "grus",
			rekt = {
				x = 144,
				y = 119,
				w = 36,
				h = 16,
			},
		},
		{
			typ = "grus",
			rekt = {
				x = 112,
				y = 20,
				w = 6,
				h = 101,
			},
		},
		{
			typ = "grus",
			rekt = {
				x = 144,
				y = 10,
				w = 62,
				h = 8,
			},
		},
		{
			typ = "grus",
			rekt = {
				x = 148,
				y = 40,
				w = 44,
				h = 15.05,
			},
		},
		{
			typ = "grus",
			rekt = {
				x = 186,
				y = 16,
				w = 8,
				h = 28,
			},
		},
		{
			typ = "grus",
			rekt = {
				x = 172.1,
				y = 61.05,
				w = 3,
				h = 61.95,
			},
		},
		{
			typ = "sand",
			rekt = {
				x = 150,
				y = 132,
				w = 18,
				h = 24,
				matt = "REFERENCE GAP",
			},
		},
		{
			typ = "sand",
			rekt = {
				x = 173,
				y = 126,
				w = 33.57,
				h = 40,
				matt = "kortsida MEASURED 33,57",
			},
		},
		{
			typ = "betong",
			rekt = {
				x = 170,
				y = 100,
				w = 6,
				h = 5,
			},
		},
	},
	byggnader = {
		{
			id = "ridhus",
			rekt = {
				x = 118,
				y = 41.82,
				w = 25,
				h = 77.18,
			},
			hV = 6.2,
			hN = 9.2,
			nock = "NS",
			fargV = Color3.fromRGB(135, 47, 64),
			fargT = Color3.fromRGB(32, 32, 34),
			svart = Color3.fromRGB(32, 32, 34),
			plat = true,
			list = 4.1,
			takfot = true,
			detalj = "ridhus",
			label = "RIDHUSET",
			oppningar = {
				{
					sida = "N",
					u = 3.1,
					b = 1.8,
					h = 2.2,
					z0 = 0,
					typ = "dorrvit",
					skarm = 2.6,
				},
				{
					sida = "N",
					u = 3.3,
					b = 1.2,
					h = 1.55,
					z0 = 4.45,
					typ = "valv",
				},
				{
					sida = "N",
					u = 8.1,
					b = 1.1,
					h = 2.1,
					z0 = 0,
					typ = "dorr",
					skarm = 2.1,
				},
				{
					sida = "N",
					u = 20.1,
					b = 1.05,
					h = 1.45,
					z0 = 1.35,
					typ = "valv",
				},
				{
					sida = "N",
					u = 24.1,
					b = 1.05,
					h = 1.45,
					z0 = 1.35,
					typ = "valv",
				},
				{
					sida = "N",
					u = 20.1,
					b = 1.05,
					h = 1.45,
					z0 = 4.45,
					typ = "valv",
				},
				{
					sida = "N",
					u = 24.1,
					b = 1.05,
					h = 1.45,
					z0 = 4.45,
					typ = "valv",
				},
				{
					sida = "N",
					u = 22.3,
					b = 1,
					h = 2.05,
					z0 = 4.02,
					typ = "dorr",
				},
				{
					sida = "W",
					u = 9,
					b = 2,
					h = 2.2,
					z0 = 0,
					typ = "dorrvit",
				},
				{
					sida = "W",
					u = 40,
					b = 1.1,
					h = 2.1,
					z0 = 0,
					typ = "dorr",
				},
				{
					sida = "W",
					u = 14,
					b = 0.9,
					h = 0.7,
					z0 = 4.9,
					typ = "fonster",
				},
				{
					sida = "W",
					u = 22,
					b = 0.9,
					h = 0.7,
					z0 = 4.9,
					typ = "fonster",
				},
				{
					sida = "W",
					u = 30,
					b = 0.9,
					h = 0.7,
					z0 = 4.9,
					typ = "fonster",
				},
				{
					sida = "E",
					u = 5,
					b = 3.4,
					h = 2.9,
					z0 = 0,
					typ = "portplat",
				},
				{
					sida = "E",
					u = 41.58,
					b = 2.4,
					h = 2.6,
					z0 = 0,
					typ = "portbla",
					intern = true,
				},
				{
					sida = "S",
					u = 8,
					b = 4,
					h = 3.6,
					z0 = 0,
					typ = "portsilver",
				},
			},
		},
		{
			id = "stall",
			rekt = {
				x = 151.1,
				y = 55.05,
				w = 21,
				h = 69.95,
			},
			hV = 4.4,
			hN = 10,
			nock = "NS",
			fargV = Color3.fromRGB(110, 47, 68),
			fargT = Color3.fromRGB(94, 100, 108),
			svart = Color3.fromRGB(38, 41, 46),
			takfot = Color3.fromRGB(238, 236, 228),
			detalj = "stall",
			sockel = 0.35,
			label = "STALLET",
			oppningar = {
				{
					sida = "W",
					u = 5.6,
					b = 1.15,
					h = 2.1,
					z0 = 0,
					typ = "dorrgul",
					skarm = 1.7,
				},
				{
					sida = "W",
					u = 2.6,
					b = 1.15,
					h = 1.55,
					z0 = 1.55,
					typ = "valv",
				},
				{
					sida = "W",
					u = 8.6,
					b = 1.15,
					h = 1.55,
					z0 = 1.55,
					typ = "valv",
				},
				{
					sida = "W",
					u = 39.2,
					b = 2.4,
					h = 2.6,
					z0 = 0,
					typ = "portbla",
					intern = true,
				},
				{
					sida = "W",
					u = 12.15,
					b = 1.15,
					h = 1.55,
					z0 = 1.55,
					typ = "valv",
				},
				{
					sida = "W",
					u = 15.65,
					b = 1.15,
					h = 1.55,
					z0 = 1.55,
					typ = "valv",
				},
				{
					sida = "W",
					u = 19.15,
					b = 1.15,
					h = 1.55,
					z0 = 1.55,
					typ = "valv",
				},
				{
					sida = "W",
					u = 22.65,
					b = 1.15,
					h = 1.55,
					z0 = 1.55,
					typ = "valv",
				},
				{
					sida = "W",
					u = 26.15,
					b = 1.15,
					h = 1.55,
					z0 = 1.55,
					typ = "valv",
				},
				{
					sida = "W",
					u = 29.65,
					b = 1.15,
					h = 1.55,
					z0 = 1.55,
					typ = "valv",
				},
				{
					sida = "W",
					u = 33.15,
					b = 1.15,
					h = 1.55,
					z0 = 1.55,
					typ = "valv",
				},
				{
					sida = "W",
					u = 36.65,
					b = 1.15,
					h = 1.55,
					z0 = 1.55,
					typ = "valv",
				},
				{
					sida = "W",
					u = 40.15,
					b = 1.15,
					h = 1.55,
					z0 = 1.55,
					typ = "valv",
				},
				{
					sida = "W",
					u = 43.65,
					b = 1.15,
					h = 1.55,
					z0 = 1.55,
					typ = "valv",
				},
				{
					sida = "W",
					u = 47.15,
					b = 1.15,
					h = 1.55,
					z0 = 1.55,
					typ = "valv",
				},
				{
					sida = "W",
					u = 50.65,
					b = 1.15,
					h = 1.55,
					z0 = 1.55,
					typ = "valv",
				},
				{
					sida = "E",
					u = 57.8,
					b = 1.15,
					h = 1.55,
					z0 = 1.55,
					typ = "valv",
				},
				{
					sida = "E",
					u = 54.3,
					b = 1.15,
					h = 1.55,
					z0 = 1.55,
					typ = "valv",
				},
				{
					sida = "E",
					u = 50.8,
					b = 1.15,
					h = 1.55,
					z0 = 1.55,
					typ = "valv",
				},
				{
					sida = "E",
					u = 47.3,
					b = 1.15,
					h = 1.55,
					z0 = 1.55,
					typ = "valv",
				},
				{
					sida = "E",
					u = 43.8,
					b = 1.15,
					h = 1.55,
					z0 = 1.55,
					typ = "valv",
				},
				{
					sida = "E",
					u = 40.3,
					b = 1.15,
					h = 1.55,
					z0 = 1.55,
					typ = "valv",
				},
				{
					sida = "E",
					u = 36.8,
					b = 1.15,
					h = 1.55,
					z0 = 1.55,
					typ = "valv",
				},
				{
					sida = "E",
					u = 33.3,
					b = 1.15,
					h = 1.55,
					z0 = 1.55,
					typ = "valv",
				},
				{
					sida = "E",
					u = 29.8,
					b = 1.15,
					h = 1.55,
					z0 = 1.55,
					typ = "valv",
				},
				{
					sida = "E",
					u = 26.3,
					b = 1.15,
					h = 1.55,
					z0 = 1.55,
					typ = "valv",
				},
				{
					sida = "E",
					u = 22.8,
					b = 1.15,
					h = 1.55,
					z0 = 1.55,
					typ = "valv",
				},
				{
					sida = "E",
					u = 19.3,
					b = 1.15,
					h = 1.55,
					z0 = 1.55,
					typ = "valv",
				},
				{
					sida = "N",
					u = 6.4,
					b = 1.15,
					h = 1.55,
					z0 = 4.75,
					typ = "valv",
				},
				{
					sida = "N",
					u = 14.6,
					b = 1.15,
					h = 1.55,
					z0 = 4.75,
					typ = "valv",
				},
				{
					sida = "N",
					u = 8.4,
					b = 1.1,
					h = 1.5,
					z0 = 2.6,
					typ = "valv",
				},
				{
					sida = "N",
					u = 12.6,
					b = 1.1,
					h = 1.5,
					z0 = 2.6,
					typ = "valv",
				},
				{
					sida = "N",
					u = 10.025,
					b = 0.95,
					h = 2.05,
					z0 = 4.6,
					typ = "dorrvit",
				},
				{
					sida = "N",
					u = 9.925,
					b = 1.15,
					h = 2.05,
					z0 = 0,
					typ = "dorrgul",
				},
				{
					sida = "N",
					u = 8.57,
					b = 0.66,
					h = 0.66,
					z0 = 1.78,
					typ = "rund",
				},
				{
					sida = "N",
					u = 11.77,
					b = 0.66,
					h = 0.66,
					z0 = 1.78,
					typ = "rund",
				},
				{
					sida = "E",
					u = 34.35,
					b = 3.6,
					h = 3.2,
					z0 = 0,
					typ = "portbla",
				},
				{
					sida = "S",
					u = 5.6,
					b = 1.15,
					h = 2.1,
					z0 = 0,
					typ = "dorrvit",
					skarm = 1.7,
				},
				{
					sida = "S",
					u = 12.5,
					b = 1.15,
					h = 2.1,
					z0 = 0,
					typ = "dorrvit",
					skarm = 1.7,
				},
				{
					sida = "S",
					u = 8.2,
					b = 1.1,
					h = 1.5,
					z0 = 1.6,
					typ = "valv",
				},
				{
					sida = "S",
					u = 10.4,
					b = 1.1,
					h = 1.5,
					z0 = 1.6,
					typ = "valv",
				},
				{
					sida = "S",
					u = 9.2,
					b = 1.1,
					h = 1.5,
					z0 = 4.6,
					typ = "valv",
				},
				{
					sida = "S",
					u = 12.4,
					b = 0.95,
					h = 2,
					z0 = 4.35,
					typ = "dorrmork",
				},
			},
		},
		{
			id = "hastgang",
			rekt = {
				x = 143,
				y = 82.85,
				w = 8.1,
				h = 3.5,
			},
			hV = 3.2,
			hN = 4,
			nock = "EW",
			fargV = Color3.fromRGB(124, 42, 36),
			fargT = Color3.fromRGB(94, 100, 108),
			label = "HÄSTGÅNGEN",
			oppningar = {
				{
					sida = "N",
					u = 4.6,
					b = 1.2,
					h = 1.4,
					z0 = 1.3,
					typ = "fonster",
				},
				{
					sida = "S",
					u = 4.6,
					b = 1.2,
					h = 1.4,
					z0 = 1.3,
					typ = "fonster",
				},
			},
		},
		{
			id = "langa",
			rekt = {
				x = 147,
				y = 34,
				w = 7,
				h = 6,
			},
			hV = 3,
			hN = 4.4,
			nock = "EW",
			fargV = Color3.fromRGB(124, 42, 36),
			fargT = Color3.fromRGB(126, 130, 136),
			label = "",
			oppningar = {
				{
					sida = "N",
					u = 4.4,
					b = 1.1,
					h = 2,
					z0 = 0,
					typ = "dorrmork",
				},
			},
		},
		{
			id = "stuga",
			rekt = {
				x = 94,
				y = 140,
				w = 6.5,
				h = 4.5,
			},
			hV = 2.5,
			hN = 3.8,
			nock = "EW",
			fargV = Color3.fromRGB(138, 58, 48),
			fargT = Color3.fromRGB(58, 62, 68),
			label = "",
			oppningar = {
				{
					sida = "E",
					u = 1.2,
					b = 1.6,
					h = 0.9,
					z0 = 1.1,
					typ = "fonster",
				},
				{
					sida = "S",
					u = 1.6,
					b = 1.4,
					h = 0.9,
					z0 = 1.1,
					typ = "fonster",
				},
			},
		},
		{
			id = "domarkur",
			rekt = {
				x = 156.75,
				y = 156.8,
				w = 4.5,
				h = 3.5,
			},
			hV = 2.3,
			hN = 3.4,
			nock = "EW",
			fargV = Color3.fromRGB(138, 58, 48),
			fargT = Color3.fromRGB(140, 58, 42),
			label = "",
			oppningar = {
				{
					sida = "S",
					u = 0.95,
					b = 2.6,
					h = 1,
					z0 = 1,
					typ = "fonster",
				},
			},
		},
		{
			id = "bod",
			rekt = {
				x = 184,
				y = 44,
				w = 5,
				h = 4,
			},
			hV = 2.3,
			hN = 3.4,
			nock = "NS",
			fargV = Color3.fromRGB(138, 58, 48),
			fargT = Color3.fromRGB(58, 62, 68),
			label = "",
			oppningar = {
				{
					sida = "S",
					u = 1.4,
					b = 1.4,
					h = 0.9,
					z0 = 1.1,
					typ = "fonster",
				},
			},
		},
		{
			id = "elbod",
			rekt = {
				x = 172.7,
				y = 59,
				w = 3,
				h = 2.5,
			},
			hV = 2,
			hN = 2.8,
			nock = "NS",
			fargV = Color3.fromRGB(138, 58, 48),
			fargT = Color3.fromRGB(58, 62, 68),
			label = "",
			oppningar = {},
		},
	},
	dorrar = {
		{
			id = "ridhus_o",
			pos = {
				143.9,
				49,
			},
			text = "In i ridhuset (durkplåtdörrarna)",
			mot = "ridhusinne",
			spawn = {
				x = 23.4,
				y = 5,
				rikt = 3.141593,
			},
		},
		{
			id = "ridhus_n",
			pos = {
				139.9,
				119.8,
			},
			text = "In i ridhuset (entrén)",
			mot = "ridhusinne",
			spawn = {
				x = 21.9,
				y = 73.4,
				rikt = -1.570796,
			},
		},
		{
			id = "cafe",
			pos = {
				124.4,
				120.2,
			},
			text = "Café Krubban (trappan upp)",
			mot = "info",
			info = "Café Krubban har stängt för kvällen. Kolla in vyn över banan från läktaren i stället.",
		},
		{
			id = "stall_n",
			pos = {
				161.6,
				126.6,
			},
			text = "Gå in i stallet (Entré, under verandan)",
			mot = "stallinne",
			spawn = {
				x = 9.6,
				y = 68.4,
				rikt = -1.570796,
			},
		},
		{
			id = "stall_n2",
			pos = {
				149.6,
				118.825,
			},
			text = "Gå in i stallet (dörren på gårdssidan)",
			mot = "stallinne",
			spawn = {
				x = 1.6,
				y = 64.35,
				rikt = 0,
			},
		},
		{
			id = "stall_s",
			pos = {
				156.7,
				53.45,
			},
			text = "Gå in i stallet (gaveldörren vid gårdsplanen)",
			mot = "stallinne",
			spawn = {
				x = 5.6,
				y = 1.6,
				rikt = 1.570796,
			},
		},
		{
			id = "ridhus_N_8",
			pos = {
				134.35,
				120.1,
			},
			text = "In i ridhuset",
			mot = "ridhusinne",
			auto = true,
			spawn = {
				x = 16.35,
				y = 75.58,
				rikt = -1.570796,
			},
		},
		{
			id = "ridhus_W_9",
			pos = {
				116.9,
				109,
			},
			text = "In i ridhuset",
			mot = "ridhusinne",
			auto = true,
			spawn = {
				x = 1.6,
				y = 67.18,
				rikt = 0,
			},
		},
		{
			id = "ridhus_W_40",
			pos = {
				116.9,
				78.45,
			},
			text = "In i ridhuset",
			mot = "ridhusinne",
			auto = true,
			spawn = {
				x = 5.2,
				y = 36.63,
				rikt = 0,
			},
		},
		{
			id = "ridhus_S_8",
			pos = {
				128,
				40.72,
			},
			text = "In i ridhuset",
			mot = "ridhusinne",
			auto = true,
			spawn = {
				x = 10,
				y = 1.6,
				rikt = 1.570796,
			},
		},
		{
			id = "stall_S_13",
			pos = {
				164.175,
				53.95,
			},
			text = "Gå in i stallet",
			mot = "stallinne",
			auto = true,
			spawn = {
				x = 13.075,
				y = 1.6,
				rikt = 1.570796,
			},
		},
	},
	stall = {
		bredd = 21,
		langd = 69.95,
		tak = 3.4,
		takresning = 2.1,
		klocka = {
			x = 0.35,
			y = 1.2,
			z = 2.7,
			r = 0.26,
		},
		gangSten = Color3.fromRGB(134, 125, 108),
		gangSpan = Color3.fromRGB(167, 150, 121),
		serviceGolv = Color3.fromRGB(174, 162, 140),
		gaveloppning = {
			x = 4.6,
			bredd = 2.6,
			hojd = 2.5,
			exitB = 0.42,
			exitH = 0.2,
			exitOver = 0.22,
		},
		vagg = Color3.fromRGB(193, 192, 195),
		boxB = 3.5,
		antalBoxar = 13,
		boxStartY = 6.8,
		klubbY = 52.85,
		brott = {
			{
				rad = "W",
				id = "hastgang",
				y0 = 28.35,
				y1 = 30.75,
			},
		},
		fack = {
			W = {
				{
					y0 = 6.8,
					y1 = 10.3,
				},
				{
					y0 = 10.3,
					y1 = 13.8,
				},
				{
					y0 = 13.8,
					y1 = 17.3,
				},
				{
					y0 = 17.3,
					y1 = 20.8,
				},
				{
					y0 = 20.8,
					y1 = 24.3,
				},
				{
					y0 = 24.3,
					y1 = 27.8,
				},
				{
					y0 = 31.3,
					y1 = 34.8,
				},
				{
					y0 = 34.8,
					y1 = 38.3,
				},
				{
					y0 = 38.3,
					y1 = 41.8,
				},
				{
					y0 = 41.8,
					y1 = 45.3,
				},
				{
					y0 = 45.3,
					y1 = 48.8,
				},
				{
					y0 = 48.8,
					y1 = 52.3,
				},
			},
			MA = {
				{
					y0 = 6.8,
					y1 = 10.3,
				},
				{
					y0 = 10.3,
					y1 = 13.8,
				},
				{
					y0 = 13.8,
					y1 = 17.3,
				},
				{
					y0 = 17.3,
					y1 = 20.8,
				},
				{
					y0 = 20.8,
					y1 = 24.3,
				},
				{
					y0 = 24.3,
					y1 = 27.8,
				},
				{
					y0 = 27.8,
					y1 = 31.3,
				},
				{
					y0 = 31.3,
					y1 = 34.8,
				},
				{
					y0 = 34.8,
					y1 = 38.3,
				},
				{
					y0 = 38.3,
					y1 = 41.8,
				},
				{
					y0 = 41.8,
					y1 = 45.3,
				},
				{
					y0 = 45.3,
					y1 = 48.8,
				},
				{
					y0 = 48.8,
					y1 = 52.3,
				},
			},
			MB = {
				{
					y0 = 6.8,
					y1 = 10.3,
				},
				{
					y0 = 10.3,
					y1 = 13.8,
				},
				{
					y0 = 13.8,
					y1 = 17.3,
				},
				{
					y0 = 17.3,
					y1 = 20.8,
				},
				{
					y0 = 20.8,
					y1 = 24.3,
				},
				{
					y0 = 24.3,
					y1 = 27.8,
				},
				{
					y0 = 27.8,
					y1 = 31.3,
				},
				{
					y0 = 31.3,
					y1 = 34.8,
				},
				{
					y0 = 34.8,
					y1 = 38.3,
				},
				{
					y0 = 38.3,
					y1 = 41.8,
				},
				{
					y0 = 41.8,
					y1 = 45.3,
				},
				{
					y0 = 45.3,
					y1 = 48.8,
				},
				{
					y0 = 48.8,
					y1 = 52.3,
				},
			},
			E = {
				{
					y0 = 6.8,
					y1 = 10.3,
				},
				{
					y0 = 10.3,
					y1 = 13.8,
				},
				{
					y0 = 13.8,
					y1 = 17.3,
				},
				{
					y0 = 17.3,
					y1 = 20.8,
				},
				{
					y0 = 20.8,
					y1 = 24.3,
				},
				{
					y0 = 24.3,
					y1 = 27.8,
				},
				{
					y0 = 27.8,
					y1 = 31.3,
				},
				{
					y0 = 31.3,
					y1 = 34.8,
				},
				{
					y0 = 34.8,
					y1 = 38.3,
				},
				{
					y0 = 38.3,
					y1 = 41.8,
				},
				{
					y0 = 41.8,
					y1 = 45.3,
				},
				{
					y0 = 45.3,
					y1 = 48.8,
				},
				{
					y0 = 48.8,
					y1 = 52.3,
				},
			},
		},
		band = {
			{
				id = "W",
				typ = "rad",
				andel = 0.209,
				vetter = 1,
				gang = "A",
				yttervagg = true,
			},
			{
				id = "A",
				typ = "gang",
				andel = 0.124,
			},
			{
				id = "MA",
				typ = "rad",
				andel = 0.178,
				vetter = -1,
				gang = "A",
				yttervagg = false,
			},
			{
				id = "MB",
				typ = "rad",
				andel = 0.176,
				vetter = 1,
				gang = "B",
				yttervagg = false,
			},
			{
				id = "B",
				typ = "gang",
				andel = 0.123,
			},
			{
				id = "E",
				typ = "rad",
				andel = 0.19,
				vetter = -1,
				gang = "B",
				yttervagg = true,
			},
		},
		rader = {
			{
				id = "W",
				x0 = 0,
				djup = 4.389,
				vetter = 1,
				gang = "A",
				yttervagg = true,
			},
			{
				id = "MA",
				x0 = 6.993,
				djup = 3.738,
				vetter = -1,
				gang = "A",
				yttervagg = false,
			},
			{
				id = "MB",
				x0 = 10.731,
				djup = 3.696,
				vetter = 1,
				gang = "B",
				yttervagg = false,
			},
			{
				id = "E",
				x0 = 17.01,
				djup = 3.99,
				vetter = -1,
				gang = "B",
				yttervagg = true,
			},
		},
		gangar = {
			A = {
				x0 = 4.389,
				x1 = 6.993,
			},
			B = {
				x0 = 14.427,
				x1 = 17.01,
			},
		},
		gangytor = {
			{
				x = 4.389,
				y = 5,
				w = 2.604,
				h = 49.35,
			},
			{
				x = 14.427,
				y = 5,
				w = 2.583,
				h = 49.35,
			},
			{
				x = 0.4,
				y = 28.35,
				w = 5.489,
				h = 2.4,
			},
			{
				x = 0.4,
				y = 52.85,
				w = 20.2,
				h = 6.1,
				tvar = true,
			},
			{
				x = 0.4,
				y = 55.95,
				w = 20.2,
				h = 13.6,
			},
			{
				x = 4.5,
				y = 0.4,
				w = 12,
				h = 6.1,
			},
		},
		rum = {},
		service = {
			{
				id = "spolspilta",
				rekt = {
					x = 0,
					y = 0,
					w = 4.5,
					h = 6.5,
				},
				label = "SPOLSPILTA",
				oppen = true,
				bommar = 3,
				panelH = 2.05,
				railZ = 1.15,
			},
			{
				id = "spanforrad",
				rekt = {
					x = 16.5,
					y = 0,
					w = 4.5,
					h = 6.5,
				},
				label = "SPÅNFÖRRÅD",
				oppen = true,
				sackar = {
					rader = 2,
					hojd = 1.15,
					djup = 1.2,
				},
				panelH = 2.05,
			},
		},
		klubb = {
			y0 = 57.45,
			vaggar = {
				{
					id = "genomgaende",
					typ = "tvar",
					y = 57.45,
					x0 = 0,
					x1 = 21,
					brand = true,
					oppningar = {
						{
							id = "inre_entre",
							x0 = 4.1,
							x1 = 5,
						},
						{
							id = "sadelkammare",
							x0 = 7.7,
							x1 = 8.8,
						},
					},
					primitiv = "WALL",
					canon_id = "stall_wall_genomgaende",
					source_id = "PLAN:stall-plan1-utrymning-rak.jpg#tvarlinje-0.1855;PO-2026-09-03:inre-entren-mellan-toaletterna",
					confidence = "VERIFIED_PLAN_OR_PHOTO",
				},
				{
					id = "wc_v_n",
					typ = "tvar",
					y = 59.95,
					x0 = 0,
					x1 = 3,
					oppningar = {
						{
							id = "wc_v_lucka_n",
							x0 = 0,
							x1 = 0.87,
						},
					},
					primitiv = "WALL",
					canon_id = "stall_wall_wc_v_n",
					source_id = "PLAN:stall-plan1-utrymning.jpg#linje-N10.0-x0.9-3.0;PO-2026-09-03:tva-toaletter",
					confidence = "VERIFIED_PLAN_OR_PHOTO",
				},
				{
					id = "wc_v_o",
					typ = "langs",
					x = 3,
					y0 = 57.45,
					y1 = 59.95,
					oppningar = {
						{
							id = "wc_v_dorr",
							y0 = 58.25,
							y1 = 59.15,
						},
					},
					primitiv = "WALL",
					canon_id = "stall_wall_wc_v_o",
					source_id = "PLAN:stall-plan1-utrymning.jpg#linje-x3.0-N10.0-12.5;PO-2026-09-03:tva-toaletter",
					confidence = "VERIFIED_PLAN_OR_PHOTO",
				},
				{
					id = "volym_v",
					typ = "langs",
					x = 5.9,
					y0 = 57.45,
					y1 = 65.05,
					primitiv = "WALL",
					canon_id = "stall_wall_symbolruta_v",
					source_id = "PLAN:stall-plan1-utrymning.jpg#symbolrutan-x5.9",
					confidence = "VERIFIED_PLAN_OR_PHOTO",
				},
				{
					id = "volym_o",
					typ = "langs",
					x = 7.3,
					y0 = 57.45,
					y1 = 65.05,
					primitiv = "WALL",
					canon_id = "stall_wall_symbolruta_o",
					source_id = "PLAN:stall-plan1-utrymning.jpg#symbolrutan-x7.3",
					confidence = "VERIFIED_PLAN_OR_PHOTO",
				},
				{
					id = "volym_n",
					typ = "tvar",
					y = 65.05,
					x0 = 5.9,
					x1 = 7.3,
					primitiv = "WALL",
					canon_id = "stall_wall_symbolruta_n",
					source_id = "PLAN:stall-plan1-utrymning.jpg#symbolrutan-N4.9",
					confidence = "VERIFIED_PLAN_OR_PHOTO",
				},
				{
					id = "volym_s",
					typ = "tvar",
					y = 59.25,
					x0 = 5.9,
					x1 = 7.3,
					primitiv = "WALL",
					canon_id = "stall_wall_symbolruta_s",
					source_id = "PLAN:stall-plan1-utrymning.jpg#symbolrutans-fot-N10.7",
					confidence = "VERIFIED_PLAN_OR_PHOTO",
				},
				{
					id = "teorisal_v",
					typ = "langs",
					x = 11.2,
					y0 = 64.35,
					y1 = 69.95,
					oppningar = {
						{
							id = "teorisal_dorr",
							y0 = 64.35,
							y1 = 66.95,
						},
					},
					primitiv = "WALL",
					canon_id = "stall_wall_teorisal_v",
					source_id = "PLAN:stall-plan1-utrymning-rak.jpg#linje-x11.2;PO-2026-09-03:teorisalen-till-vanster;FOTO:stall-inne-04-teorisalen.jpg",
					confidence = "VERIFIED_PLAN_OR_PHOTO",
				},
				{
					id = "teorisal_s",
					typ = "tvar",
					y = 64.35,
					x0 = 8.8,
					x1 = 17.3,
					primitiv = "WALL",
					canon_id = "stall_wall_teorisal_s",
					source_id = "PLAN:stall-plan1-utrymning-rak.jpg#linje-N5.6;PO-2026-09-03:sadelkammaren-vanster-sedan-hoger",
					confidence = "VERIFIED_PLAN_OR_PHOTO",
				},
				{
					id = "teorisal_o",
					typ = "langs",
					x = 17.3,
					y0 = 64.35,
					y1 = 69.95,
					primitiv = "WALL",
					canon_id = "stall_wall_teorisal_o",
					source_id = "PLAN:stall-plan1-utrymning-rak.jpg#linje-x17.3",
					confidence = "VERIFIED_PLAN_OR_PHOTO",
				},
				{
					id = "sadelkammare_o",
					typ = "langs",
					x = 15.5,
					y0 = 57.45,
					y1 = 64.35,
					primitiv = "WALL",
					canon_id = "stall_wall_sadelkammare_o",
					source_id = "PLAN:stall-plan1-utrymning-rak.jpg#linje-x15.5",
					confidence = "VERIFIED_PLAN_OR_PHOTO",
				},
				{
					id = "sadelkammare_mellan",
					typ = "tvar",
					y = 60.85,
					x0 = 9,
					x1 = 12.2,
					primitiv = "WALL",
					canon_id = "stall_wall_sadelkammare_mellan",
					source_id = "PLAN:stall-plan1-utrymning-rak.jpg#halvvagg-N9.1",
					confidence = "VERIFIED_PLAN_OR_PHOTO",
				},
			},
			oppna = {
				{
					id = "stall_uppehall_open",
					typ = "OPEN_AREA",
					canon_id = "stall_uppehall_open",
					confidence = "PRODUCT_OWNER_VERIFIED",
					source_id = "PO-2026-09-03-STALL-OPEN-01",
					rekt = {
						{
							x = 0,
							y = 59.95,
							w = 5.9,
							h = 10,
						},
						{
							x = 7.3,
							y = 64.35,
							w = 3.9,
							h = 5.6,
						},
						{
							x = 5.9,
							y = 65.05,
							w = 1.4,
							h = 4.9,
						},
					},
				},
			},
			ingaVaggar = {
				{
					id = "stall_uppehall_no_internal_wall",
					typ = "NO_WALL_ZONE",
					tacker = "stall_uppehall_open",
					canon_id = "stall_uppehall_no_internal_wall",
					aterkallat = {
						"sluten_volym_v",
						"vindfang_v",
						"vindfang_o",
						"vindfang_fot",
						"litet_v",
						"litet_s",
						"litet_rum",
					},
				},
			},
			rum = {
				{
					id = "vindfang",
					rekt = {
						x = 3.6,
						y = 67.95,
						w = 1.9,
						h = 2,
					},
					label = "",
				},
				{
					id = "uppehallsrum",
					rekt = {
						x = 0,
						y = 59.95,
						w = 5.9,
						h = 10,
					},
					label = "",
				},
				{
					id = "wc_v",
					rekt = {
						x = 0,
						y = 57.45,
						w = 3,
						h = 2.5,
					},
					label = "",
				},
				{
					id = "lobby",
					rekt = {
						x = 3,
						y = 57.45,
						w = 2.9,
						h = 2.5,
					},
					label = "",
				},
				{
					id = "wc_o",
					rekt = {
						x = 5.9,
						y = 57.45,
						w = 1.4,
						h = 1.8,
					},
					label = "",
					stangt = true,
					primitiv = "WALL",
					canon_id = "stall_volume_wc_o",
					source_id = "PLAN:stall-plan1-utrymning.jpg#cell-x5.9-7.3-N10.7-12.5;PO-2026-09-03:tva-toaletter",
					confidence = "VERIFIED_PLAN_OR_PHOTO",
				},
				{
					id = "sluten_volym",
					rekt = {
						x = 5.9,
						y = 59.25,
						w = 1.4,
						h = 5.8,
					},
					label = "",
					stangt = true,
					primitiv = "WALL",
					canon_id = "stall_volume_symbolruta",
					source_id = "PLAN:stall-plan1-utrymning.jpg#symbolrutan",
					confidence = "VERIFIED_PLAN_OR_PHOTO",
				},
				{
					id = "uppehallsrum_o",
					rekt = {
						x = 5.9,
						y = 64.35,
						w = 5.3,
						h = 5.6,
					},
					label = "",
					del = "uppehallsrum",
				},
				{
					id = "teorisal",
					rekt = {
						x = 11.2,
						y = 64.35,
						w = 6.1,
						h = 5.6,
					},
					label = "",
				},
				{
					id = "sadelkammare",
					rekt = {
						x = 7.3,
						y = 57.45,
						w = 8.2,
						h = 6.9,
					},
					label = "",
				},
				{
					id = "ostrum",
					rekt = {
						x = 15.5,
						y = 57.45,
						w = 5.5,
						h = 6.9,
					},
					label = "",
				},
				{
					id = "ostrum_n",
					rekt = {
						x = 17.3,
						y = 64.35,
						w = 3.7,
						h = 5.6,
					},
					label = "",
				},
			},
		},
		tvarvaggar = {
			{
				y = 52.85,
				brand = true,
			},
			{
				y = 6.5,
				brand = false,
				oppningar = {
					{
						x0 = 9,
						x1 = 12,
					},
				},
			},
		},
		dorrar = {
			{
				id = "ut_n",
				pos = {
					10.5,
					68.95,
				},
				ankomst = {
					9.6,
					68.4,
				},
				text = "Ut genom entrén — mot grusplanen",
				mot = "gard",
				inrikt = -1.570796,
				uttext = "Gå in i stallet (Entré, under verandan)",
				spawn = {
					x = 161.6,
					y = 126.6,
					rikt = 1.570796,
				},
			},
			{
				id = "ut_n2",
				pos = {
					1.6,
					64.35,
				},
				text = "Ut på gårdssidan",
				mot = "gard",
				inrikt = 0,
				uttext = "Gå in i stallet (dörren på gårdssidan)",
				spawn = {
					x = 149.6,
					y = 118.825,
					rikt = 3.141593,
				},
			},
			{
				id = "ut_s",
				pos = {
					5.6,
					1.6,
				},
				text = "Ut till gårdsplanen — mot Husbyvägen",
				mot = "gard",
				inrikt = 1.570796,
				uttext = "Gå in i stallet (gaveldörren vid gårdsplanen)",
				spawn = {
					x = 156.7,
					y = 53.45,
					rikt = -1.570796,
				},
			},
			{
				id = "hastgang",
				pos = {
					0.9,
					29.55,
				},
				text = "Hästgången — in i ridhuset",
				mot = "ridhusinne",
				inrikt = 3.141593,
				inne = true,
				spawn = {
					x = 23.6,
					y = 42.78,
					rikt = 3.141593,
				},
			},
			{
				id = "ut_stall_S_13",
				pos = {
					13.075,
					1.6,
				},
				text = "Ut",
				mot = "gard",
				auto = true,
				spawn = {
					x = 164.175,
					y = 53.95,
					rikt = -1.570796,
				},
			},
		},
		origo = {
			x = 151.1,
			y = 55.05,
		},
	},
	identitet = {
		stall = {
			huvrad = {
				antal = 11,
				forstaFranNorr = 12.15,
				delning = 3.5,
				sida = 0.44,
				hojd = 0.62,
				hattB = 0.66,
			},
			snorasskydd = {
				andelUpp = 0.3,
				andelUt = 0.7,
				stolpDelning = 2.2,
			},
			forstukvist = {
				uFranOst = 10.5,
				bredd = 5.2,
				djup = 2.8,
				takfot = 2.95,
				resning = 1.05,
				oppning = 1.5,
			},
			stallgang = {
				limtra = Color3.fromRGB(173, 138, 112),
				takplat = Color3.fromRGB(112, 113, 110),
			},
			boxfront = {
				heldel = Color3.fromRGB(69, 74, 79),
				ram = Color3.fromRGB(154, 155, 147),
				heldelH = 1.35,
				ramZ = 1.38,
				stolpH = 2.15,
				toppregelZ = 2.2,
				reglar = 5,
				regelD = 0.04,
			},
			balkong = {
				z = 4.55,
				bredd = 2.2,
				djup = 1.1,
				rackeH = 0.92,
			},
			spiraltrappa = {
				franGavelmitt = 3.4,
				radie = 0.7,
				steg = 18,
			},
		},
		ridhus = {
			ovreVagg = {
				overSarg = 0.1,
				underTak = 1.6,
				tjocklek = 0.08,
				listar = 3,
				sida = "E",
				y0 = 0,
				y1 = 65.68,
			},
			fonsterband = {
				h = 0.95,
				underTak = 0.5,
				tjocklek = 0.06,
				postDelning = 2.4,
				perFalt = true,
				faltBredd = 3,
				glas = Color3.fromRGB(220, 230, 236),
				karm = Color3.fromRGB(74, 59, 46),
			},
			laktarVagg = {
				pelareB = 0.24,
				pelareFarg = Color3.fromRGB(74, 58, 44),
				skarvDelning = 1.2,
				skarvFarg = Color3.fromRGB(201, 198, 188),
				skarvB = 0.03,
			},
			takProfiler = {
				andelar = {
					0.18,
					0.4,
					0.6,
					0.82,
				},
				b = 0.14,
				h = 0.3,
				underTak = 0.62,
			},
			kabelstegar = {
				andelar = {
					0.3,
					0.7,
				},
				bredd = 0.34,
				underTak = 1.02,
				pinnDelning = 0.55,
			},
			ventkanaler = {
				andelar = {
					0.24,
					0.76,
				},
				radie = 0.3,
				underTak = 0.95,
				donDelning = 6.5,
			},
		},
	},
	banomrade = {
		staket = {
			toppregel = {
				z = 1.3,
				h = 0.13,
				d = 0.09,
			},
			sandsyll = {
				z = 0.13,
				h = 0.26,
				d = 0.11,
			},
			tradar = {
				0.75,
				0.34,
			},
			tradTjocklek = 0.025,
			isolatorB = 0.07,
			isolatorH = 0.09,
			stolpH = 1.35,
			stolpDelning = 2.6,
			stolpTvarsnitt = 0.12,
		},
		mast = {
			hojd = 7.5,
			stamOver = 0.13,
			stamUnder = 0.09,
			armB = 1.3,
			armH = 0.1,
			armD = 0.1,
			lampB = 0.44,
			lampH = 0.2,
			lampD = 0.3,
			lampDelning = 0.92,
		},
	},
	traningsytor = {
		NO_STOR = {
			x = 173,
			y = 126,
			w = 33.57,
			h = 40,
			matt = "kortsida MEASURED 33,57",
		},
		NO_LITEN = {
			x = 150,
			y = 132,
			w = 18,
			h = 24,
			matt = "REFERENCE GAP",
		},
	},
	banor = {
		uteridbanan = {
			x = 150,
			y = 132,
			w = 18,
			h = 24,
			matt = "REFERENCE GAP",
		},
		paddock = {
			x = 173,
			y = 126,
			w = 33.57,
			h = 40,
			matt = "kortsida MEASURED 33,57",
		},
	},
	staket = {
		{
			typ = "tra",
			sandkant = true,
			p = {
				{
					150,
					132,
				},
				{
					168,
					132,
				},
				{
					168,
					156,
				},
				{
					150,
					156,
				},
				{
					150,
					132,
				},
			},
		},
		{
			typ = "tra",
			sandkant = true,
			p = {
				{
					173,
					126,
				},
				{
					206.57,
					126,
				},
				{
					206.57,
					166,
				},
				{
					173,
					166,
				},
				{
					173,
					126,
				},
			},
		},
		{
			typ = "tra",
			p = {
				{
					178,
					65,
				},
				{
					206,
					65,
				},
				{
					206,
					93,
				},
				{
					178,
					93,
				},
				{
					178,
					65,
				},
			},
			grindar = {
				{
					p = {
						178,
						79,
					},
					bredd = 2.4,
				},
			},
		},
		{
			typ = "tra",
			p = {
				{
					178,
					97,
				},
				{
					206,
					97,
				},
				{
					206,
					117,
				},
				{
					178,
					117,
				},
				{
					178,
					97,
				},
			},
			grindar = {
				{
					p = {
						178,
						107,
					},
					bredd = 2.4,
				},
			},
		},
		{
			typ = "el",
			p = {
				{
					112,
					20,
				},
				{
					112,
					121,
				},
			},
		},
		{
			typ = "rail",
			p = {
				{
					155,
					121.5,
				},
				{
					168,
					121.5,
				},
			},
		},
		{
			typ = "rail",
			p = {
				{
					96,
					127,
				},
				{
					96,
					136,
				},
			},
		},
	},
	props = {
		{
			typ = "silo",
			pos = {
				161.6,
				53.5,
			},
		},
		{
			typ = "balar",
			pos = {
				153.6,
				50.45,
			},
		},
		{
			typ = "grushog",
			pos = {
				122,
				131,
			},
		},
		{
			typ = "transport",
			pos = {
				133,
				125,
			},
			rikt = 0.5,
		},
		{
			typ = "bord",
			pos = {
				150,
				74,
			},
		},
		{
			typ = "bord",
			pos = {
				148,
				86,
			},
		},
		{
			typ = "bank",
			pos = {
				146,
				94,
			},
		},
		{
			typ = "stol",
			pos = {
				149,
				102,
			},
		},
		{
			typ = "skylt",
			pos = {
				118,
				82,
			},
			text = "UPPLANDS-BRO RYTTARFÖRENING",
			norm = {
				-1,
				0,
			},
		},
		{
			typ = "cafeskylt",
			pos = {
				124.4,
				119.8,
			},
			norm = {
				0,
				1,
			},
		},
		{
			typ = "flagga",
			pos = {
				123,
				149,
			},
		},
		{
			typ = "vagvisare",
			pos = {
				172,
				123,
			},
		},
		{
			typ = "stenhast",
			pos = {
				98.5,
				129.5,
			},
		},
		{
			typ = "stenhast",
			pos = {
				101.5,
				132,
			},
		},
		{
			typ = "stenhast",
			pos = {
				99.5,
				133,
			},
		},
		{
			typ = "stenhast",
			pos = {
				101,
				129,
			},
		},
		{
			typ = "mast",
			pos = {
				150,
				132,
			},
		},
		{
			typ = "mast",
			pos = {
				168,
				132,
			},
		},
		{
			typ = "mast",
			pos = {
				150,
				156,
			},
		},
		{
			typ = "mast",
			pos = {
				168,
				156,
			},
		},
		{
			typ = "mast",
			pos = {
				173,
				166,
			},
		},
		{
			typ = "torvbalar",
			pos = {
				146.4,
				137.6,
			},
		},
		{
			typ = "sopstation",
			pos = {
				150,
				56,
			},
		},
		{
			typ = "ac",
			pos = {
				143.4,
				80,
			},
			norm = {
				1,
				0,
			},
		},
		{
			typ = "ac",
			pos = {
				143.4,
				84,
			},
			norm = {
				1,
				0,
			},
		},
		{
			typ = "busskylt",
			pos = {
				8.6,
				88,
			},
		},
	},
	ridhus = {
		bredd = 25,
		langd = 77.18,
		tak = 6.2,
		entre = 11.5,
		bana = {
			x = 4.4,
			y = 0.15,
			w = 20,
			h = 65.53,
		},
		sargH = 1.35,
		dressyr = {
			x = 4.4,
			y = 0.15,
			w = 20,
			h = 60,
			forankring = "A",
		},
		sargGrind = {
			y0 = 40.88,
			y1 = 44.68,
		},
		laktare = {
			x0 = 0.6,
			y0 = 0.15,
			y1 = 65.68,
			dackZ = 0.8,
			dackDjup = 3.4,
			gangbrada = {
				djup = 0.9,
				farg = Color3.fromRGB(90, 70, 52),
			},
			rader = {
				antal = 3,
				djup = 0.8,
				stegH = 0.3,
				sittTjock = 0.06,
				farg = Color3.fromRGB(201, 181, 140),
				kantFarg = Color3.fromRGB(178, 74, 58),
			},
		},
		kortanda = {
			y0 = 65.68,
			y1 = 70.13,
			x0 = 8.6,
			x1 = 21.6,
			vand = "S",
			steg = 4,
			stegH = 0.32,
			stegD = 1.1,
			sockelH = 0.8,
			trappor = {
				{
					id = "c_trappa_v",
					x0 = 12.4,
					x1 = 15.2,
					fot = "E",
				},
				{
					id = "c_trappa_o",
					x0 = 16.4,
					x1 = 18.9,
					fot = "W",
				},
			},
			trappB = 1.1,
			glasH = 2,
			glasOver = 1.6,
			glasPost = 1.9,
			glasKarm = Color3.fromRGB(74, 59, 46),
			bank = Color3.fromRGB(134, 113, 91),
			bankSatt = Color3.fromRGB(111, 92, 73),
			klocka = {
				overBlock = 1.05,
				r = 0.34,
				x = 15.8,
			},
			stjarna = {
				overBlock = 0.85,
				r = 0.78,
				tjocklek = 0.05,
				farg = Color3.fromRGB(185, 179, 166),
				x = 10.5,
			},
		},
		domarbas = {
			x = 1.96,
			y = 30.15,
			b = 2,
			h = 2.3,
			trappa = true,
			exit = true,
		},
		cafe = {
			djup = 11.5,
			z0 = 3.68,
			z1 = 5.9,
		},
		trappor = {
			{
				id = "c_trappa_v",
				primitiv = "STAIR",
				canon_id = "ridhus_c_end_stair_west",
				axel = "x",
				x0 = 12.4,
				x1 = 15.2,
				y0 = 69.03,
				y1 = 70.13,
				z0 = 2.08,
				z1 = 3.68,
				stiger = "W",
				stegMax = 0.19,
				source_id = "PO-2026-09-03-RIDHUS-STAIRS-01;FOTO:ridhus-inne-01,IMG_0192-f01,IMG_0192-f02,ridhus-inne-07,ridhus-klubb-10;PLAN:ridhus-entreplan-utrymning.jpg#trappor-12.4-15.2-16.4-18.9",
				confidence = "VERIFIED_PLAN_OR_PHOTO",
			},
			{
				id = "c_trappa_o",
				primitiv = "STAIR",
				canon_id = "ridhus_c_end_stair_east",
				axel = "x",
				x0 = 16.4,
				x1 = 18.9,
				y0 = 69.03,
				y1 = 70.13,
				z0 = 2.08,
				z1 = 3.68,
				stiger = "E",
				stegMax = 0.19,
				source_id = "PO-2026-09-03-RIDHUS-STAIRS-01;FOTO:ridhus-inne-01,IMG_0192-f01,IMG_0192-f02,ridhus-inne-07,ridhus-klubb-10;PLAN:ridhus-entreplan-utrymning.jpg#trappor-12.4-15.2-16.4-18.9",
				confidence = "VERIFIED_PLAN_OR_PHOTO",
			},
			{
				id = "laktar_trappa_h",
				primitiv = "STAIR",
				canon_id = "ridhus_laktar_stair_h",
				axel = "y",
				x0 = 0.6,
				x1 = 1.6,
				y0 = 62.82,
				y1 = 65.68,
				z0 = 1.7,
				z1 = 3.68,
				stiger = "N",
				stegMax = 0.19,
				osakert = "bredd 1,0 m och loppets längd [uppskattning]; foten på översta radens nivå (ridhus-inne-39)",
				source_id = "PO-2026-09-04-LAKTARTRAPPA-01;FOTO:ridhus-inne-39,ridhus-inne-15,ridhus-inne-14,ridhus-inne-20,ridhus-klubb-11,ridhus-klubb-10;PLAN:ridhus-entreplan-utrymning.jpg#trappsymbol-laktarens-norra-ande",
				confidence = "VERIFIED_PLAN_OR_PHOTO",
			},
		},
		ovreGang = {
			x0 = 0.6,
			x1 = 24.4,
			y0 = 70.13,
			y1 = 72.63,
			z = 3.68,
			bredd = 2.5,
		},
		ovreGangV = {
			x0 = 0.6,
			x1 = 1.6,
			y0 = 65.68,
			y1 = 70.13,
			z = 3.68,
			bredd = 1,
			canon_id = "ridhus_upper_walkway_west",
			primitiv = "OPEN_AREA",
			source_id = "FOTO:ridhus-klubb-10,ridhus-inne-39",
			confidence = "VERIFIED_PLAN_OR_PHOTO",
		},
		entrehall = {
			y0 = 65.68,
			vaggar = {
				{
					id = "reception_s",
					typ = "tvar",
					y = 72.6,
					x0 = 0,
					x1 = 2.2,
					primitiv = "WALL",
					canon_id = "ridhus_reception_room",
					source_id = "PO-2026-09-04-RECEPTION-01;PLAN:ridhus-entreplan-utrymning.jpg#nv-celler-sydvagg-N4.5;FOTO:ridhus-klubb-01,ridhus-klubb-02,ridhus-klubb-15",
					confidence = "PRODUCT_OWNER_VERIFIED",
				},
				{
					id = "reception_dorrvagg",
					typ = "langs",
					x = 2.2,
					y0 = 72.6,
					y1 = 73.5,
					oppningar = {
						{
							id = "reception_dorr",
							y0 = 72.62,
							y1 = 73.48,
							h = 2.1,
						},
					},
					primitiv = "WALL",
					canon_id = "ridhus_reception_room",
					source_id = "PO-2026-09-04-RECEPTION-01;FOTO:ridhus-klubb-02#karm-i-glasvaggens-ande",
					confidence = "PRODUCT_OWNER_VERIFIED",
				},
				{
					id = "reception_glas",
					typ = "langs",
					x = 2.2,
					y0 = 73.5,
					y1 = 77,
					primitiv = "GLASS",
					brostning = 0.95,
					hylla = 0.32,
					canon_id = "ridhus_reception_glass",
					source_id = "PO-2026-09-03-RIDHUS-GLASS-01;PO-2026-09-04-RECEPTION-01;FOTO:ridhus-klubb-01,ridhus-klubb-02,ridhus-klubb-15;PLAN:ridhus-entreplan-utrymning.jpg#nv-celler-x1.7-2.2",
					confidence = "PRODUCT_OWNER_VERIFIED",
				},
			},
			oppna = {
				{
					id = "ridhus_open_entrance_hall",
					typ = "OPEN_AREA",
					canon_id = "ridhus_open_entrance_hall",
					confidence = "PRODUCT_OWNER_VERIFIED_TOPOLOGY",
					source_id = "PO-2026-09-03-RIDHUS-OPEN-01;PLAN:ridhus-entreplan-utrymning.jpg",
					rekt = {
						{
							x = 0,
							y = 65.68,
							w = 25,
							h = 2.47,
						},
						{
							x = 0,
							y = 68.15,
							w = 4.2,
							h = 4.45,
						},
						{
							x = 4.2,
							y = 68.15,
							w = 1.55,
							h = 1.8,
						},
						{
							x = 7.6,
							y = 68.15,
							w = 17.4,
							h = 1.8,
						},
						{
							x = 4.2,
							y = 69.95,
							w = 20.8,
							h = 2.65,
						},
						{
							x = 2.2,
							y = 72.6,
							w = 22.8,
							h = 4.58,
						},
					},
				},
			},
			ingaVaggar = {
				{
					id = "ridhus_open_hall_no_room_boxes",
					typ = "NO_WALL_ZONE",
					tacker = "ridhus_open_entrance_hall",
					canon_id = "ridhus_open_hall_no_room_boxes",
					undantag = {
						"ridhus_reception_glass",
						"ridhus_reception_room",
					},
					aterkallat = {
						"korridor_o",
						"skap_v",
						"skap_o",
						"cell_1",
						"cell_2",
						"cell_3",
						"cell_4",
						"hall_n_v",
						"hall_n_o",
						"hall_nv_s",
						"hall_mitt",
						"hall_no",
						"hall_no_s",
						"ostkorridor_v",
						"wc_n_s",
						"wc_n_mellan",
						"wc_n_o",
						"reception_glas@x2.2-N4.6-8.3",
					},
				},
			},
			rum = {
				{
					id = "entre",
					rekt = {
						x = 0,
						y = 66.18,
						w = 2.2,
						h = 2,
					},
					label = "",
				},
				{
					id = "reception",
					rekt = {
						x = 0,
						y = 72.6,
						w = 2.2,
						h = 4.58,
					},
					label = "",
					canon_id = "ridhus_reception_room",
					source_id = "PO-2026-09-04-RECEPTION-01;FOTO:ridhus-klubb-01,ridhus-klubb-02,ridhus-klubb-15",
					confidence = "PRODUCT_OWNER_VERIFIED",
				},
				{
					id = "schakt",
					rekt = {
						x = 5.78,
						y = 68.2,
						w = 1.82,
						h = 1.7,
					},
					label = "",
					stangt = true,
					primitiv = "WALL",
					canon_id = "ridhus_schakt_box",
					source_id = "PLAN:ridhus-entreplan-utrymning.jpg#kryssad-ruta-x5.75-7.6-N7.3-9.0",
					confidence = "VERIFIED_PLAN_OR_PHOTO",
				},
				{
					id = "hall",
					rekt = {
						x = 0,
						y = 65.68,
						w = 25,
						h = 11.5,
					},
					label = "",
				},
			},
		},
		skyltar = {
			{
				andel = 0.8,
				b = 5,
				text = "VÄLKOMMEN TILL UPPLANDS-BRO RYTTARFÖRENING",
				fg = Color3.fromRGB(58, 62, 68),
				bg = Color3.fromRGB(242, 237, 226),
				y = 52.544,
			},
			{
				andel = 0.71,
				b = 4,
				text = "HUVUDSPONSOR ELON BARKARBY",
				fg = Color3.fromRGB(240, 234, 220),
				bg = Color3.fromRGB(28, 28, 30),
				y = 46.6328,
			},
			{
				andel = 0.62,
				b = 3.6,
				text = "Vi tror på dig! · Sparbanken i Enköping",
				fg = Color3.fromRGB(192, 57, 43),
				bg = Color3.fromRGB(247, 242, 232),
				y = 40.7216,
			},
			{
				andel = 0.19,
				b = 3,
				text = "Agria Djurförsäkring",
				fg = Color3.fromRGB(240, 234, 220),
				bg = Color3.fromRGB(47, 92, 143),
				y = 12.4792,
			},
			{
				andel = 0.14,
				b = 2.6,
				text = "Hästsportbutik · Stigeberga Gård",
				fg = Color3.fromRGB(58, 62, 68),
				bg = Color3.fromRGB(242, 237, 226),
				y = 9.1952,
			},
			{
				andel = 0.1,
				b = 2.2,
				text = "RS Mustang · Stallströ · Foder",
				fg = Color3.fromRGB(240, 234, 220),
				bg = Color3.fromRGB(47, 92, 143),
				y = 6.568,
			},
			{
				andel = 0.064,
				b = 2.2,
				text = "RS Mustang · Stallströ · Foder",
				fg = Color3.fromRGB(240, 234, 220),
				bg = Color3.fromRGB(47, 92, 143),
				y = 4.20352,
			},
			{
				andel = 0.03,
				b = 2,
				text = "Svensk kvalitetsfoder",
				fg = Color3.fromRGB(240, 234, 220),
				bg = Color3.fromRGB(47, 92, 143),
				y = 1.9704,
			},
		},
		basTak = {
			resning = 0.42,
			utsprang = 0.18,
		},
		sidor = {
			laktare = "W",
			panel = "E",
		},
		panel = Color3.fromRGB(118, 91, 89),
		panelList = Color3.fromRGB(232, 223, 206),
		sandFarg = Color3.fromRGB(111, 93, 77),
		hallvagg = Color3.fromRGB(172, 169, 157),
		takfarg = {
			balk = Color3.fromRGB(92, 76, 69),
			plat = Color3.fromRGB(94, 91, 94),
		},
		takstomme = {
			resning = 2.8,
			delning = 6,
			start = 1,
			balkH = 0.26,
			balkD = 0.24,
			kungB = 0.22,
			kungH = 2.7,
			platT = 0.18,
		},
		dorrar = {
			{
				id = "ut_o",
				pos = {
					24.2,
					5,
				},
				text = "Ut på gården",
				mot = "gard",
				spawn = {
					x = 144.6,
					y = 49,
					rikt = 0,
				},
			},
			{
				id = "hastgang",
				pos = {
					23.6,
					42.78,
				},
				text = "Hästgången — in i stallet",
				mot = "stallinne",
				spawn = {
					x = 1.6,
					y = 29.55,
					rikt = 0,
				},
			},
			{
				id = "ut_ridhus_N_8",
				pos = {
					16.35,
					75.58,
				},
				text = "Ut",
				mot = "gard",
				auto = true,
				spawn = {
					x = 134.35,
					y = 120.1,
					rikt = 1.570796,
				},
			},
			{
				id = "ut_ridhus_W_9",
				pos = {
					1.6,
					67.18,
				},
				text = "Ut",
				mot = "gard",
				auto = true,
				spawn = {
					x = 116.9,
					y = 109,
					rikt = 3.141593,
				},
			},
			{
				id = "ut_ridhus_W_40",
				pos = {
					5.2,
					36.63,
				},
				text = "Ut",
				mot = "gard",
				auto = true,
				spawn = {
					x = 116.9,
					y = 78.45,
					rikt = 3.141593,
				},
			},
			{
				id = "ut_ridhus_S_8",
				pos = {
					10,
					1.6,
				},
				text = "Ut",
				mot = "gard",
				auto = true,
				spawn = {
					x = 128,
					y = 40.72,
					rikt = -1.570796,
				},
			},
		},
		hinder = {
			{
				x = 6.5,
				y = 24,
				b = 2.8,
				h = 0.68,
				farg = "bla",
			},
			{
				x = 13.5,
				y = 38,
				b = 2.8,
				h = 0.52,
				farg = "rod",
			},
			{
				x = 9,
				y = 50,
				b = 3,
				h = 0,
				farg = "rod",
			},
		},
		koner = {
			{
				4,
				17,
			},
			{
				16.6,
				44,
			},
			{
				11,
				58,
			},
		},
		pall = {
			x = 18.9,
			y = 20,
		},
		dynor = 12,
		lysror = {
			andelar = {
				0.3,
				0.7,
			},
			delning = 7,
			langd = 1.5,
			bredd = 0.18,
			underTak = 0.35,
			farg = Color3.fromRGB(246, 242, 228),
		},
		spegelSida = "E",
		origo = {
			x = 118,
			y = 41.82,
		},
	},
	spelabstraktioner = {
		ridhus = {
			sargport = {
				x0 = 4.7,
				x1 = 6.9,
				y = 65.68,
				bredd = 2.2,
				klass = "SPELABSTRAKTION",
				fidelity = "REFERENCE GAP",
				motiv = "planens utrymningspilar; ingen bild visar grinden; bredden vald",
			},
			bankradSteg = {
				x0 = 7,
				x1 = 8.6,
				y0 = 65.68,
				y1 = 66.78,
				z0 = 0,
				z1 = 1.12,
				axel = "x",
				stiger = "E",
				stegMax = 0.19,
				klass = "SPELABSTRAKTION",
				fidelity = "REFERENCE GAP",
				motiv = "spelets väg från hallgolvet upp på bänkraderna; inget foto visar stegen; läge och form valda",
			},
			laktarSteg = {
				x0 = 1.8,
				x1 = 4,
				y0 = 65.68,
				y1 = 67.28,
				z0 = 0,
				z1 = 0.8,
				axel = "y",
				stiger = "S",
				stegMax = 0.19,
				klass = "SPELABSTRAKTION",
				fidelity = "REFERENCE GAP",
				motiv = "spelets väg från hallgolvet upp på läktardäcket vid dess norra ände; ridhus-inne-39 visar nivåskillnaden, inte stegen; läge och form valda",
			},
		},
	},
	inredning = {
		stall = {
			{
				id = "uppehall_soffa_v",
				rum = "uppehallsrum",
				typ = "soffa",
				pos = {
					0.55,
					65.6,
				},
				rikt = 0,
				matt = {
					b = 1.85,
					d = 0.85,
					h = 0.7,
				},
				farg = Color3.fromRGB(28, 28, 30),
				ytmaterial = "Leather",
				kolliderar = true,
				kalla = "stall-inne-01",
				klass = "VERIFIED",
				lage = "DERIVED",
			},
			{
				id = "uppehall_soffa_s",
				rum = "uppehallsrum",
				typ = "soffa",
				pos = {
					2.6,
					63.85,
				},
				rikt = 1.570796,
				matt = {
					b = 1.85,
					d = 0.85,
					h = 0.7,
				},
				farg = Color3.fromRGB(28, 28, 30),
				ytmaterial = "Leather",
				kolliderar = true,
				kalla = "stall-inne-01",
				klass = "VERIFIED",
				lage = "DERIVED",
			},
			{
				id = "uppehall_bord_1",
				rum = "uppehallsrum",
				typ = "bord",
				pos = {
					1.65,
					65.2,
				},
				rikt = 0,
				matt = {
					b = 0.55,
					d = 0.55,
					h = 0.45,
				},
				farg = Color3.fromRGB(20, 20, 22),
				kolliderar = true,
				kalla = "stall-inne-01",
				klass = "VERIFIED",
				lage = "DERIVED",
			},
			{
				id = "uppehall_bord_2",
				rum = "uppehallsrum",
				typ = "bord",
				pos = {
					1.65,
					65.95,
				},
				rikt = 0,
				matt = {
					b = 0.55,
					d = 0.55,
					h = 0.45,
				},
				farg = Color3.fromRGB(20, 20, 22),
				kolliderar = true,
				kalla = "stall-inne-01",
				klass = "VERIFIED",
				lage = "DERIVED",
			},
			{
				id = "uppehall_ponny",
				rum = "uppehallsrum",
				typ = "ponny",
				pos = {
					1.1,
					67.55,
				},
				rikt = 1.570796,
				matt = {
					b = 0.45,
					d = 1.35,
					h = 1.45,
				},
				farg = Color3.fromRGB(214, 58, 140),
				farg2 = Color3.fromRGB(42, 36, 32),
				kolliderar = true,
				kalla = "stall-inne-01",
				klass = "VERIFIED",
				lage = "DERIVED",
			},
			{
				id = "uppehall_klocka",
				rum = "uppehallsrum",
				typ = "klocka",
				pos = {
					0.02,
					63.9,
				},
				rikt = 0,
				matt = {
					b = 0.3,
					d = 0.04,
					h = 0.3,
				},
				z0 = 1.9,
				farg = Color3.fromRGB(244, 242, 236),
				kalla = "stall-inne-01",
				klass = "VERIFIED",
				lage = "DERIVED",
			},
			{
				id = "uppehall_vaxt",
				rum = "uppehallsrum",
				typ = "vaxt",
				pos = {
					0.38,
					64.45,
				},
				rikt = 0,
				matt = {
					b = 0.7,
					d = 0.7,
					h = 1.9,
				},
				farg = Color3.fromRGB(78, 122, 58),
				farg2 = Color3.fromRGB(91, 91, 140),
				kolliderar = true,
				kalla = "stall-inne-01",
				klass = "VERIFIED",
				lage = "DERIVED",
			},
			{
				id = "uppehall_fotovagg",
				rum = "uppehallsrum",
				typ = "tavlor",
				pos = {
					0.02,
					65.75,
				},
				rikt = 0,
				matt = {
					b = 2.2,
					d = 0.03,
					h = 1,
				},
				z0 = 1.35,
				antal = 6,
				farg = Color3.fromRGB(30, 30, 30),
				farg2 = Color3.fromRGB(138, 154, 122),
				kalla = "stall-inne-01",
				klass = "VERIFIED",
				lage = "DERIVED",
			},
			{
				id = "teori_whiteboard_1",
				rum = "teorisal",
				typ = "whiteboard",
				pos = {
					17.2,
					68.55,
				},
				rikt = 3.141593,
				matt = {
					b = 1.5,
					d = 0.03,
					h = 1,
				},
				z0 = 0.95,
				farg = Color3.fromRGB(247, 247, 245),
				detaljer = {
					ram = true,
					hylla = true,
					arbetsmarken = "icke-semantiska",
					variant = 1,
				},
				kalla = "stall-inne-04",
				klass = "VERIFIED",
				lage = "DERIVED",
			},
			{
				id = "teori_whiteboard_2",
				rum = "teorisal",
				typ = "whiteboard",
				pos = {
					17.2,
					66.95,
				},
				rikt = 3.141593,
				matt = {
					b = 1.5,
					d = 0.03,
					h = 1,
				},
				z0 = 0.95,
				farg = Color3.fromRGB(247, 247, 245),
				detaljer = {
					ram = true,
					hylla = true,
					arbetsmarken = "icke-semantiska",
					variant = 2,
				},
				kalla = "stall-inne-04",
				klass = "VERIFIED",
				lage = "DERIVED",
			},
			{
				id = "teori_bord_1",
				rum = "teorisal",
				typ = "bord",
				pos = {
					13.2,
					68.4,
				},
				rikt = 1.570796,
				matt = {
					b = 2.4,
					d = 0.8,
					h = 0.73,
				},
				farg = Color3.fromRGB(154, 128, 101),
				farg2 = Color3.fromRGB(114, 92, 72),
				ytmaterial = "Wood",
				detaljer = {
					skivaTjocklek = 0.04,
					tra = true,
				},
				kolliderar = true,
				kalla = "stall-inne-04",
				klass = "VERIFIED",
				lage = "DERIVED",
			},
			{
				id = "teori_bord_2",
				rum = "teorisal",
				typ = "bord",
				pos = {
					13.2,
					67.6,
				},
				rikt = 1.570796,
				matt = {
					b = 2.4,
					d = 0.8,
					h = 0.73,
				},
				farg = Color3.fromRGB(154, 128, 101),
				farg2 = Color3.fromRGB(114, 92, 72),
				ytmaterial = "Wood",
				detaljer = {
					skivaTjocklek = 0.04,
					tra = true,
				},
				kolliderar = true,
				kalla = "stall-inne-04",
				klass = "VERIFIED",
				lage = "DERIVED",
			},
			{
				id = "teori_bord_3",
				rum = "teorisal",
				typ = "bord",
				pos = {
					15.6,
					68.4,
				},
				rikt = 1.570796,
				matt = {
					b = 2.4,
					d = 0.8,
					h = 0.73,
				},
				farg = Color3.fromRGB(154, 128, 101),
				farg2 = Color3.fromRGB(114, 92, 72),
				ytmaterial = "Wood",
				detaljer = {
					skivaTjocklek = 0.04,
					tra = true,
				},
				kolliderar = true,
				kalla = "stall-inne-04",
				klass = "VERIFIED",
				lage = "DERIVED",
			},
			{
				id = "teori_stol_1",
				rum = "teorisal",
				typ = "stol",
				pos = {
					12.3,
					66.9,
				},
				rikt = 1.570796,
				matt = {
					b = 0.45,
					d = 0.45,
					h = 0.85,
				},
				farg = Color3.fromRGB(242, 240, 233),
				farg2 = Color3.fromRGB(114, 92, 72),
				detaljer = {
					vitSits = true,
					traram = true,
					ryggSpjalor = 2,
				},
				kolliderar = true,
				kalla = "stall-inne-04",
				klass = "VERIFIED",
				lage = "DERIVED",
			},
			{
				id = "teori_stol_2",
				rum = "teorisal",
				typ = "stol",
				pos = {
					13.3,
					66.9,
				},
				rikt = 1.570796,
				matt = {
					b = 0.45,
					d = 0.45,
					h = 0.85,
				},
				farg = Color3.fromRGB(242, 240, 233),
				farg2 = Color3.fromRGB(114, 92, 72),
				detaljer = {
					vitSits = true,
					traram = true,
					ryggSpjalor = 2,
				},
				kolliderar = true,
				kalla = "stall-inne-04",
				klass = "VERIFIED",
				lage = "DERIVED",
			},
			{
				id = "teori_stol_3",
				rum = "teorisal",
				typ = "stol",
				pos = {
					14.3,
					66.9,
				},
				rikt = 1.570796,
				matt = {
					b = 0.45,
					d = 0.45,
					h = 0.85,
				},
				farg = Color3.fromRGB(242, 240, 233),
				farg2 = Color3.fromRGB(114, 92, 72),
				detaljer = {
					vitSits = true,
					traram = true,
					ryggSpjalor = 2,
				},
				kolliderar = true,
				kalla = "stall-inne-04",
				klass = "VERIFIED",
				lage = "DERIVED",
			},
			{
				id = "teori_stol_4",
				rum = "teorisal",
				typ = "stol",
				pos = {
					15.3,
					66.9,
				},
				rikt = 1.570796,
				matt = {
					b = 0.45,
					d = 0.45,
					h = 0.85,
				},
				farg = Color3.fromRGB(242, 240, 233),
				farg2 = Color3.fromRGB(114, 92, 72),
				detaljer = {
					vitSits = true,
					traram = true,
					ryggSpjalor = 2,
				},
				kolliderar = true,
				kalla = "stall-inne-04",
				klass = "VERIFIED",
				lage = "DERIVED",
			},
			{
				id = "teori_stol_5",
				rum = "teorisal",
				typ = "stol",
				pos = {
					16.3,
					66.9,
				},
				rikt = 1.570796,
				matt = {
					b = 0.45,
					d = 0.45,
					h = 0.85,
				},
				farg = Color3.fromRGB(242, 240, 233),
				farg2 = Color3.fromRGB(114, 92, 72),
				detaljer = {
					vitSits = true,
					traram = true,
					ryggSpjalor = 2,
				},
				kolliderar = true,
				kalla = "stall-inne-04",
				klass = "VERIFIED",
				lage = "DERIVED",
			},
			{
				id = "teori_stol_6",
				rum = "teorisal",
				typ = "stol",
				pos = {
					12.3,
					69.2,
				},
				rikt = -1.570796,
				matt = {
					b = 0.45,
					d = 0.45,
					h = 0.85,
				},
				farg = Color3.fromRGB(242, 240, 233),
				farg2 = Color3.fromRGB(114, 92, 72),
				detaljer = {
					vitSits = true,
					traram = true,
					ryggSpjalor = 2,
				},
				kolliderar = true,
				kalla = "stall-inne-04",
				klass = "VERIFIED",
				lage = "DERIVED",
			},
			{
				id = "teori_stol_7",
				rum = "teorisal",
				typ = "stol",
				pos = {
					13.3,
					69.2,
				},
				rikt = -1.570796,
				matt = {
					b = 0.45,
					d = 0.45,
					h = 0.85,
				},
				farg = Color3.fromRGB(242, 240, 233),
				farg2 = Color3.fromRGB(114, 92, 72),
				detaljer = {
					vitSits = true,
					traram = true,
					ryggSpjalor = 2,
				},
				kolliderar = true,
				kalla = "stall-inne-04",
				klass = "VERIFIED",
				lage = "DERIVED",
			},
			{
				id = "teori_stol_8",
				rum = "teorisal",
				typ = "stol",
				pos = {
					14.3,
					69.2,
				},
				rikt = -1.570796,
				matt = {
					b = 0.45,
					d = 0.45,
					h = 0.85,
				},
				farg = Color3.fromRGB(242, 240, 233),
				farg2 = Color3.fromRGB(114, 92, 72),
				detaljer = {
					vitSits = true,
					traram = true,
					ryggSpjalor = 2,
				},
				kolliderar = true,
				kalla = "stall-inne-04",
				klass = "VERIFIED",
				lage = "DERIVED",
			},
			{
				id = "teori_stol_9",
				rum = "teorisal",
				typ = "stol",
				pos = {
					15.3,
					69.2,
				},
				rikt = -1.570796,
				matt = {
					b = 0.45,
					d = 0.45,
					h = 0.85,
				},
				farg = Color3.fromRGB(242, 240, 233),
				farg2 = Color3.fromRGB(114, 92, 72),
				detaljer = {
					vitSits = true,
					traram = true,
					ryggSpjalor = 2,
				},
				kolliderar = true,
				kalla = "stall-inne-04",
				klass = "VERIFIED",
				lage = "DERIVED",
			},
			{
				id = "teori_stol_10",
				rum = "teorisal",
				typ = "stol",
				pos = {
					16.3,
					69.2,
				},
				rikt = -1.570796,
				matt = {
					b = 0.45,
					d = 0.45,
					h = 0.85,
				},
				farg = Color3.fromRGB(242, 240, 233),
				farg2 = Color3.fromRGB(114, 92, 72),
				detaljer = {
					vitSits = true,
					traram = true,
					ryggSpjalor = 2,
				},
				kolliderar = true,
				kalla = "stall-inne-04",
				klass = "VERIFIED",
				lage = "DERIVED",
			},
			{
				id = "teori_skap_mikro",
				rum = "teorisal",
				typ = "skap",
				pos = {
					16.85,
					64.85,
				},
				rikt = 3.141593,
				matt = {
					b = 0.8,
					d = 0.45,
					h = 1,
				},
				farg = Color3.fromRGB(184, 146, 92),
				mikro = true,
				kolliderar = true,
				kalla = "stall-inne-04",
				klass = "VERIFIED",
				lage = "DERIVED",
			},
			{
				id = "teori_plansch_1",
				rum = "teorisal",
				typ = "tavlor",
				pos = {
					15.9,
					64.45,
				},
				rikt = 1.570796,
				matt = {
					b = 1,
					d = 0.03,
					h = 0.75,
				},
				z0 = 1.25,
				antal = 1,
				farg = Color3.fromRGB(184, 146, 92),
				farg2 = Color3.fromRGB(232, 221, 208),
				detaljer = {
					motiv = "hastanatomi",
					variant = 1,
					etiketter = false,
				},
				kalla = "stall-inne-04",
				klass = "VERIFIED",
				lage = "DERIVED",
			},
			{
				id = "teori_plansch_2",
				rum = "teorisal",
				typ = "tavlor",
				pos = {
					14.6,
					64.45,
				},
				rikt = 1.570796,
				matt = {
					b = 1,
					d = 0.03,
					h = 0.75,
				},
				z0 = 1.25,
				antal = 1,
				farg = Color3.fromRGB(184, 146, 92),
				farg2 = Color3.fromRGB(232, 221, 208),
				detaljer = {
					motiv = "hastanatomi",
					variant = 2,
					etiketter = false,
				},
				kalla = "stall-inne-04",
				klass = "VERIFIED",
				lage = "DERIVED",
			},
			{
				id = "teori_kartong_1",
				rum = "teorisal",
				typ = "kartong",
				pos = {
					15.3,
					64.65,
				},
				rikt = 1.570796,
				matt = {
					b = 0.55,
					d = 0.45,
					h = 0.45,
				},
				farg = Color3.fromRGB(184, 154, 114),
				kolliderar = true,
				kalla = "stall-inne-04",
				klass = "VERIFIED",
				lage = "DERIVED",
			},
			{
				id = "teori_kartong_2",
				rum = "teorisal",
				typ = "kartong",
				pos = {
					14.6,
					64.65,
				},
				rikt = 1.570796,
				matt = {
					b = 0.55,
					d = 0.45,
					h = 0.45,
				},
				farg = Color3.fromRGB(184, 154, 114),
				kolliderar = true,
				kalla = "stall-inne-04",
				klass = "VERIFIED",
				lage = "DERIVED",
			},
			{
				id = "teori_kartong_3",
				rum = "teorisal",
				typ = "kartong",
				pos = {
					13.9,
					64.65,
				},
				rikt = 1.570796,
				matt = {
					b = 0.55,
					d = 0.45,
					h = 0.45,
				},
				farg = Color3.fromRGB(184, 154, 114),
				kolliderar = true,
				kalla = "stall-inne-04",
				klass = "VERIFIED",
				lage = "DERIVED",
			},
			{
				id = "teori_lysror_1",
				rum = "teorisal",
				typ = "lysror",
				pos = {
					13.6,
					67.2,
				},
				rikt = 1.570796,
				matt = {
					b = 1.5,
					d = 0.2,
					h = 0.08,
				},
				z0 = 2.75,
				farg = Color3.fromRGB(246, 242, 228),
				detaljer = {
					upphangd = true,
					holje = true,
				},
				kalla = "stall-inne-04",
				klass = "VERIFIED",
				lage = "DERIVED",
			},
			{
				id = "teori_lysror_2",
				rum = "teorisal",
				typ = "lysror",
				pos = {
					15.9,
					67.2,
				},
				rikt = 1.570796,
				matt = {
					b = 1.5,
					d = 0.2,
					h = 0.08,
				},
				z0 = 2.75,
				farg = Color3.fromRGB(246, 242, 228),
				detaljer = {
					upphangd = true,
					holje = true,
				},
				kalla = "stall-inne-04",
				klass = "VERIFIED",
				lage = "DERIVED",
			},
			{
				id = "teori_ventkanal",
				rum = "teorisal",
				typ = "ventkanal",
				pos = {
					14.25,
					69.2,
				},
				rikt = 1.570796,
				matt = {
					b = 5.6,
					d = 0.3,
					h = 0.3,
				},
				z0 = 2.6,
				farg = Color3.fromRGB(185, 189, 192),
				detaljer = {
					perforerad = true,
					halrader = 2,
					profil = "rektangular_ranna",
				},
				kalla = "stall-inne-04",
				klass = "VERIFIED",
				lage = "DERIVED",
			},
			{
				id = "sadel_vastkrokar",
				rum = "sadelkammare",
				typ = "krokrad",
				pos = {
					7.32,
					62.2,
				},
				rikt = 0,
				matt = {
					b = 3.4,
					d = 0.4,
					h = 1.05,
				},
				z0 = 1.05,
				antal = 10,
				farg = Color3.fromRGB(154, 155, 147),
				farg2 = Color3.fromRGB(35, 42, 58),
				kalla = "stall-inne-03",
				klass = "VERIFIED",
				lage = "DERIVED",
			},
			{
				id = "sadel_stovelhylla",
				rum = "sadelkammare",
				typ = "stovelhylla",
				pos = {
					10.3,
					62.2,
				},
				rikt = 3.141593,
				matt = {
					b = 3.4,
					d = 0.42,
					h = 2.15,
				},
				farg = Color3.fromRGB(242, 241, 236),
				farg2 = Color3.fromRGB(30, 30, 30),
				kolliderar = true,
				kalla = "stall-inne-03",
				klass = "VERIFIED",
				lage = "DERIVED",
			},
			{
				id = "sadel_dorr_teori",
				rum = "sadelkammare",
				typ = "dorr",
				pos = {
					8.8,
					64.29,
				},
				rikt = -1.570796,
				matt = {
					b = 1,
					d = 0.08,
					h = 2.1,
				},
				farg = Color3.fromRGB(140, 143, 146),
				farg2 = Color3.fromRGB(191, 211, 220),
				kalla = "stall-inne-03",
				klass = "VERIFIED",
				lage = "DERIVED",
			},
			{
				id = "gangA_exitskylt",
				rum = "gangA",
				typ = "exitskylt",
				pos = {
					5.45,
					57.36,
				},
				rikt = -1.570796,
				matt = {
					b = 0.32,
					d = 0.03,
					h = 0.16,
				},
				z0 = 2.15,
				farg = Color3.fromRGB(30, 154, 74),
				kalla = "stall-gang-05, KORT.md § Gångens ändar",
				klass = "VERIFIED",
				lage = "DERIVED",
			},
			{
				id = "zon_ror",
				rum = "gangA",
				typ = "ror",
				pos = {
					9.15,
					57.33,
				},
				rikt = -1.570796,
				matt = {
					b = 7.9,
					d = 0.08,
					h = 0.08,
				},
				z0 = 2.35,
				farg = Color3.fromRGB(158, 163, 167),
				kalla = "references/spatial/stall-efter-pausrum-po-v1.md § Vänster / vit servicevägg",
				klass = "VERIFIED",
				lage = "ASSUMPTION",
			},
			{
				id = "zon_ror_ned",
				rum = "gangA",
				typ = "ror",
				pos = {
					11.6,
					57.33,
				},
				rikt = -1.570796,
				lodrat = true,
				matt = {
					b = 0.08,
					d = 0.08,
					h = 2.35,
				},
				farg = Color3.fromRGB(158, 163, 167),
				kalla = "references/spatial/stall-efter-pausrum-po-v1.md § Vänster / vit servicevägg",
				klass = "VERIFIED",
				lage = "ASSUMPTION",
			},
			{
				id = "zon_dorrblad_entre",
				rum = "gangA",
				typ = "dorr",
				pos = {
					4.04,
					56.9,
				},
				rikt = 3.141593,
				matt = {
					b = 0.9,
					d = 0.05,
					h = 2.1,
				},
				farg = Color3.fromRGB(140, 143, 146),
				farg2 = Color3.fromRGB(191, 211, 220),
				kalla = "references/spatial/stall-efter-pausrum-po-v1.md § Vänster (grå dörr, metallhandtag); stall-gang-05",
				klass = "VERIFIED",
				lage = "ASSUMPTION",
			},
			{
				id = "zon_knappsats",
				rum = "gangA",
				typ = "knappsats",
				pos = {
					5.22,
					57.36,
				},
				rikt = -1.570796,
				matt = {
					b = 0.1,
					d = 0.04,
					h = 0.16,
				},
				z0 = 1.2,
				farg = Color3.fromRGB(110, 114, 117),
				kalla = "references/spatial/stall-efter-pausrum-po-v1.md § Vänster (kodlås/knappsats)",
				klass = "VERIFIED",
				lage = "ASSUMPTION",
			},
			{
				id = "zon_klocka",
				rum = "gangA",
				typ = "klocka",
				pos = {
					4.55,
					57.36,
				},
				rikt = -1.570796,
				matt = {
					b = 0.5,
					d = 0.05,
					h = 0.5,
				},
				z0 = 2.32,
				farg = Color3.fromRGB(238, 236, 228),
				kalla = "references/spatial/stall-efter-pausrum-po-v1.md § Vänster (väggklocka vid dörrzonen); KORT.md § Gångens ändar",
				klass = "VERIFIED",
				lage = "ASSUMPTION",
			},
			{
				id = "zon_brandslackare",
				rum = "gangA",
				typ = "brandslackare",
				pos = {
					3.4,
					57.31,
				},
				rikt = -1.570796,
				matt = {
					b = 0.18,
					d = 0.18,
					h = 0.55,
				},
				z0 = 0.85,
				farg = Color3.fromRGB(200, 40, 30),
				kalla = "references/spatial/stall-efter-pausrum-po-v1.md § Vänster (säkerhetsutrustning rött)",
				klass = "VERIFIED",
				lage = "ASSUMPTION",
			},
			{
				id = "zon_forsta_hjalpen",
				rum = "gangA",
				typ = "skylt",
				pos = {
					3.4,
					57.36,
				},
				rikt = -1.570796,
				matt = {
					b = 0.3,
					d = 0.06,
					h = 0.3,
				},
				z0 = 1.6,
				farg = Color3.fromRGB(46, 139, 87),
				kalla = "references/spatial/stall-efter-pausrum-po-v1.md § Vänster (säkerhetsutrustning grönt)",
				klass = "VERIFIED",
				lage = "ASSUMPTION",
			},
			{
				id = "zon_vask",
				rum = "gangA",
				typ = "vask",
				pos = {
					10.6,
					57.07,
				},
				rikt = -1.570796,
				matt = {
					b = 1.1,
					d = 0.6,
					h = 0.9,
				},
				farg = Color3.fromRGB(142, 146, 150),
				farg2 = Color3.fromRGB(201, 205, 208),
				kolliderar = true,
				kalla = "references/spatial/stall-efter-pausrum-po-v1.md § Vänster (rostfri skölj-/tvättstation)",
				klass = "VERIFIED",
				lage = "ASSUMPTION",
			},
			{
				id = "zon_korg",
				rum = "gangA",
				typ = "korg",
				pos = {
					10.6,
					57.25,
				},
				rikt = -1.570796,
				matt = {
					b = 0.8,
					d = 0.28,
					h = 0.25,
				},
				z0 = 1.45,
				farg = Color3.fromRGB(185, 189, 192),
				kalla = "references/spatial/stall-efter-pausrum-po-v1.md § Vänster (väggmonterad hylla/korg)",
				klass = "VERIFIED",
				lage = "ASSUMPTION",
			},
			{
				id = "zon_krokar",
				rum = "gangA",
				typ = "krokar",
				pos = {
					12.3,
					57.35,
				},
				rikt = -1.570796,
				matt = {
					b = 0.8,
					d = 0.12,
					h = 0.55,
				},
				z0 = 1.3,
				farg = Color3.fromRGB(142, 146, 150),
				farg2 = Color3.fromRGB(47, 93, 138),
				kalla = "references/spatial/stall-efter-pausrum-po-v1.md § Vänster (krokar/handdukar)",
				klass = "VERIFIED",
				lage = "ASSUMPTION",
			},
			{
				id = "zon_racke",
				rum = "gangA",
				typ = "racke",
				pos = {
					12.6,
					55.15,
				},
				rikt = 1.570796,
				matt = {
					b = 2.6,
					d = 0.06,
					h = 1,
				},
				farg = Color3.fromRGB(58, 61, 64),
				farg2 = Color3.fromRGB(168, 173, 176),
				kolliderar = true,
				kalla = "references/spatial/stall-efter-pausrum-po-v1.md § Mittzon (låg mörkgrå metallavskärmning)",
				klass = "VERIFIED",
				lage = "ASSUMPTION",
			},
			{
				id = "zon_hylla",
				rum = "gangA",
				typ = "hylla",
				pos = {
					9.4,
					54.95,
				},
				rikt = -1.570796,
				matt = {
					b = 1.2,
					d = 0.5,
					h = 1.25,
				},
				farg = Color3.fromRGB(58, 61, 64),
				kolliderar = true,
				kalla = "references/spatial/stall-efter-pausrum-po-v1.md § Mittzon (arbets-/förvaringshylla)",
				klass = "VERIFIED",
				lage = "ASSUMPTION",
			},
			{
				id = "zon_back_1",
				rum = "gangA",
				typ = "kartong",
				pos = {
					9.1,
					54.95,
				},
				rikt = -1.570796,
				matt = {
					b = 0.4,
					d = 0.3,
					h = 0.28,
				},
				z0 = 1.25,
				farg = Color3.fromRGB(46, 95, 168),
				kalla = "references/spatial/stall-efter-pausrum-po-v1.md § Mittzon (plastbackar)",
				klass = "VERIFIED",
				lage = "ASSUMPTION",
			},
			{
				id = "zon_back_2",
				rum = "gangA",
				typ = "kartong",
				pos = {
					9.68,
					54.95,
				},
				rikt = -1.570796,
				matt = {
					b = 0.4,
					d = 0.3,
					h = 0.28,
				},
				z0 = 1.25,
				farg = Color3.fromRGB(158, 163, 167),
				kalla = "references/spatial/stall-efter-pausrum-po-v1.md § Mittzon (plastbackar, flaskor)",
				klass = "VERIFIED",
				lage = "ASSUMPTION",
			},
			{
				id = "zon_bin",
				rum = "gangA",
				typ = "tunna",
				pos = {
					10.55,
					54.9,
				},
				rikt = 0,
				matt = {
					b = 0.6,
					d = 0.6,
					h = 0.95,
				},
				farg = Color3.fromRGB(46, 95, 168),
				farg2 = Color3.fromRGB(30, 63, 120),
				kolliderar = true,
				kalla = "references/spatial/stall-efter-pausrum-po-v1.md § Mittzon (stor blå säck/bin)",
				klass = "VERIFIED",
				lage = "ASSUMPTION",
			},
			{
				id = "zon_pall",
				rum = "gangA",
				typ = "pall",
				pos = {
					8.2,
					54.4,
				},
				rikt = 0,
				matt = {
					b = 0.5,
					d = 0.4,
					h = 0.35,
				},
				farg = Color3.fromRGB(42, 44, 46),
				kolliderar = true,
				kalla = "references/spatial/stall-efter-pausrum-po-v1.md § Mittzon (låg rull-/trappall)",
				klass = "VERIFIED",
				lage = "ASSUMPTION",
			},
			{
				id = "boxfront_tavla_1",
				rum = "gangA",
				typ = "whiteboard",
				pos = {
					4.419,
					51.45,
				},
				rikt = 0,
				matt = {
					b = 0.6,
					d = 0.03,
					h = 0.45,
				},
				z0 = 0.75,
				farg = Color3.fromRGB(255, 255, 255),
				kalla = "references/spatial/stall-efter-pausrum-po-v1.md § Höger / boxfronter (vita anslagstavlor)",
				klass = "VERIFIED",
				lage = "ASSUMPTION",
			},
			{
				id = "boxfront_tavla_2",
				rum = "gangA",
				typ = "whiteboard",
				pos = {
					4.419,
					48.65,
				},
				rikt = 0,
				matt = {
					b = 0.6,
					d = 0.03,
					h = 0.45,
				},
				z0 = 0.75,
				farg = Color3.fromRGB(255, 255, 255),
				kalla = "references/spatial/stall-efter-pausrum-po-v1.md § Höger / boxfronter (vita anslagstavlor)",
				klass = "VERIFIED",
				lage = "ASSUMPTION",
			},
			{
				id = "boxfront_brandslackare",
				rum = "gangA",
				typ = "brandslackare",
				pos = {
					4.509,
					50.05,
				},
				rikt = 0,
				matt = {
					b = 0.18,
					d = 0.18,
					h = 0.55,
				},
				z0 = 0.5,
				farg = Color3.fromRGB(200, 40, 30),
				kalla = "references/spatial/stall-efter-pausrum-po-v1.md § Höger / boxfronter (brandsläckare mellan tavlorna)",
				klass = "VERIFIED",
				lage = "ASSUMPTION",
			},
		},
		ridhus = {
			{
				id = "spegel_B",
				rum = "bana",
				typ = "spegel",
				pos = {
					24.46,
					30.15,
				},
				rikt = 3.141593,
				matt = {
					b = 3.2,
					d = 0.06,
					h = 1.6,
				},
				z0 = 1.35,
				antal = 2,
				farg = Color3.fromRGB(122, 90, 58),
				kalla = "ridhus-inne-34, -19, -31, IMG_0189-f05",
				klass = "VERIFIED",
				lage = "VERIFIED",
			},
			{
				id = "spegel_A_v",
				rum = "sydzon",
				typ = "spegel",
				pos = {
					4.8,
					0.06,
				},
				rikt = 1.570796,
				matt = {
					b = 1.5,
					d = 0.06,
					h = 1.5,
				},
				z0 = 1.35,
				antal = 1,
				farg = Color3.fromRGB(138, 106, 68),
				kalla = "ridhus-inne-23",
				klass = "VERIFIED",
				lage = "DERIVED",
			},
			{
				id = "spegel_A_o",
				rum = "sydzon",
				typ = "spegel",
				pos = {
					15.2,
					0.06,
				},
				rikt = 1.570796,
				matt = {
					b = 1.5,
					d = 0.06,
					h = 1.5,
				},
				z0 = 1.35,
				antal = 1,
				farg = Color3.fromRGB(138, 106, 68),
				kalla = "ridhus-inne-23",
				klass = "VERIFIED",
				lage = "DERIVED",
			},
			{
				id = "laktare_bommar",
				rum = "laktare",
				typ = "bommar",
				pos = {
					2.3,
					2.75,
				},
				rikt = 1.570796,
				matt = {
					b = 2.4,
					d = 0.5,
					h = 1.9,
				},
				z0 = 0.8,
				antal = 7,
				fargor = {
					Color3.fromRGB(58, 110, 165),
					Color3.fromRGB(192, 57, 43),
					Color3.fromRGB(232, 228, 218),
					Color3.fromRGB(201, 162, 60),
					Color3.fromRGB(75, 138, 62),
				},
				kalla = "ridhus-inne-21, -23",
				klass = "VERIFIED",
				lage = "DERIVED",
			},
			{
				id = "laktare_hinderstod",
				rum = "laktare",
				typ = "hinderstod",
				pos = {
					2.3,
					5.35,
				},
				rikt = 1.570796,
				matt = {
					b = 1.8,
					d = 0.6,
					h = 1.5,
				},
				z0 = 0.8,
				antal = 3,
				farg = Color3.fromRGB(240, 237, 230),
				kalla = "ridhus-inne-21",
				klass = "VERIFIED",
				lage = "DERIVED",
			},
			{
				id = "laktare_bokstavsstall",
				rum = "laktare",
				typ = "bokstavsstall",
				pos = {
					2.3,
					7.75,
				},
				rikt = 1.570796,
				matt = {
					b = 2.4,
					d = 0.35,
					h = 0.45,
				},
				z0 = 0.8,
				antal = 8,
				farg = Color3.fromRGB(244, 244, 240),
				bokstaver = "FRHVCKMA",
				kalla = "ridhus-inne-21",
				klass = "VERIFIED",
				lage = "DERIVED",
			},
			{
				id = "laktare_returtunna",
				rum = "laktare",
				typ = "tunna",
				pos = {
					2.3,
					55.75,
				},
				rikt = 0,
				matt = {
					b = 0.5,
					d = 0.5,
					h = 1.1,
				},
				z0 = 0.8,
				farg = Color3.fromRGB(142, 145, 150),
				farg2 = Color3.fromRGB(192, 57, 43),
				kalla = "ridhus-inne-43",
				klass = "FOTO",
				lage = "DERIVED",
			},
			{
				id = "laktare_stol_1",
				rum = "laktare",
				typ = "stol",
				pos = {
					2.3,
					32.35,
				},
				rikt = 0,
				matt = {
					b = 0.45,
					d = 0.45,
					h = 0.8,
				},
				z0 = 0.8,
				farg = Color3.fromRGB(212, 85, 30),
				farg2 = Color3.fromRGB(140, 143, 146),
				kalla = "ridhus-inne-40",
				klass = "FOTO",
				lage = "DERIVED",
			},
			{
				id = "laktare_stol_2",
				rum = "laktare",
				typ = "stol",
				pos = {
					2.3,
					33.05,
				},
				rikt = 0,
				matt = {
					b = 0.45,
					d = 0.45,
					h = 0.8,
				},
				z0 = 0.8,
				farg = Color3.fromRGB(212, 85, 30),
				farg2 = Color3.fromRGB(140, 143, 146),
				kalla = "ridhus-inne-40",
				klass = "FOTO",
				lage = "DERIVED",
			},
			{
				id = "skap_v_1",
				rum = "hall",
				typ = "skapbank",
				pos = {
					4.45,
					72.5,
				},
				rikt = 3.141593,
				matt = {
					b = 4.9,
					d = 0.5,
					h = 1.9,
				},
				farg = Color3.fromRGB(201, 203, 203),
				fargor = {
					Color3.fromRGB(201, 203, 203),
					Color3.fromRGB(201, 203, 203),
					Color3.fromRGB(58, 60, 64),
					Color3.fromRGB(201, 203, 203),
					Color3.fromRGB(184, 50, 46),
				},
				kolliderar = true,
				ytmaterial = "Metal",
				detaljer = {
					profil = true,
					beslag = true,
					ventilation = false,
					ram = true,
					ramfarg = Color3.fromRGB(238, 237, 231),
					sockelVent = true,
				},
				kalla = "ridhus-klubb-01, -15, IMG_0169-f02, IMG_0268-r12",
				klass = "VERIFIED",
				lage = "ASSUMPTION",
			},
			{
				id = "skap_grona",
				rum = "hall",
				typ = "skapbank",
				pos = {
					6.4,
					69.6,
				},
				rikt = 3.141593,
				matt = {
					b = 1.6,
					d = 0.5,
					h = 1.8,
				},
				ben = 0.15,
				vaningar = 2,
				farg = Color3.fromRGB(237, 234, 224),
				fargor = {
					Color3.fromRGB(127, 160, 126),
				},
				kolliderar = true,
				ytmaterial = "Metal",
				detaljer = {
					kolumner = 4,
					profil = true,
					beslag = true,
					ventilation = false,
					ram = true,
					ramfarg = Color3.fromRGB(238, 237, 231),
					sockelVent = true,
					ben = true,
				},
				kalla = "ridhus-klubb-20, -21",
				klass = "FOTO",
				lage = "ASSUMPTION",
			},
			{
				id = "skap_hoga_v",
				rum = "hall",
				typ = "skapbank",
				pos = {
					4.45,
					76.15,
				},
				rikt = 3.141593,
				matt = {
					b = 2,
					d = 0.5,
					h = 1.9,
				},
				farg = Color3.fromRGB(237, 234, 224),
				fargor = {
					Color3.fromRGB(201, 203, 203),
					Color3.fromRGB(201, 203, 203),
					Color3.fromRGB(201, 203, 203),
					Color3.fromRGB(31, 36, 48),
					Color3.fromRGB(31, 36, 48),
				},
				kolliderar = true,
				ytmaterial = "Metal",
				detaljer = {
					kolumner = 5,
					profil = true,
					beslag = true,
					ventilation = false,
					ram = true,
					ramfarg = Color3.fromRGB(238, 237, 231),
					overkantVent = true,
					sockelVent = true,
				},
				kalla = "ridhus-klubb-15, -16, -18",
				klass = "VERIFIED",
				lage = "ASSUMPTION",
			},
			{
				id = "skap_vita_2v",
				rum = "hall",
				typ = "skapbank",
				pos = {
					6.4,
					71.3,
				},
				rikt = 3.141593,
				matt = {
					b = 1.2,
					d = 0.45,
					h = 1.8,
				},
				vaningar = 2,
				farg = Color3.fromRGB(242, 240, 234),
				fargor = {
					Color3.fromRGB(233, 229, 216),
				},
				kolliderar = true,
				ytmaterial = "Metal",
				detaljer = {
					kolumner = 5,
					profil = true,
					beslag = true,
					ventilation = false,
					ram = true,
					ramfarg = Color3.fromRGB(238, 237, 231),
				},
				kalla = "ridhus-klubb-16",
				klass = "VERIFIED",
				lage = "ASSUMPTION",
			},
			{
				id = "skap_bord",
				rum = "hall",
				typ = "bord",
				pos = {
					3.4,
					74.7,
				},
				rikt = 0,
				matt = {
					b = 0.6,
					d = 0.6,
					h = 0.72,
				},
				farg = Color3.fromRGB(242, 239, 232),
				kolliderar = true,
				kalla = "ridhus-klubb-01, -15, IMG_0268-r15",
				klass = "VERIFIED",
				lage = "ASSUMPTION",
			},
			{
				id = "skap_stol_1",
				rum = "hall",
				typ = "stol",
				pos = {
					3.4,
					75.4,
				},
				rikt = -1.570796,
				matt = {
					b = 0.5,
					d = 0.5,
					h = 0.95,
				},
				farg = Color3.fromRGB(242, 239, 232),
				farg2 = Color3.fromRGB(184, 50, 46),
				kolliderar = true,
				kalla = "ridhus-klubb-01, -15, IMG_0268-r15",
				klass = "VERIFIED",
				lage = "ASSUMPTION",
			},
			{
				id = "skap_stol_2",
				rum = "hall",
				typ = "stol",
				pos = {
					3.4,
					74,
				},
				rikt = 1.570796,
				matt = {
					b = 0.5,
					d = 0.5,
					h = 0.95,
				},
				farg = Color3.fromRGB(242, 239, 232),
				farg2 = Color3.fromRGB(184, 50, 46),
				kolliderar = true,
				kalla = "ridhus-klubb-01, -15, IMG_0268-r15",
				klass = "VERIFIED",
				lage = "ASSUMPTION",
			},
			{
				id = "reception_skap",
				rum = "reception",
				typ = "skap",
				pos = {
					0.33,
					75.3,
				},
				rikt = 0,
				matt = {
					b = 2.4,
					d = 0.55,
					h = 1.15,
				},
				farg = Color3.fromRGB(201, 168, 124),
				kolliderar = true,
				kalla = "ridhus-klubb-02",
				klass = "VERIFIED",
				lage = "DERIVED",
			},
			{
				id = "reception_tavlor",
				rum = "reception",
				typ = "tavlor",
				pos = {
					0.03,
					75.3,
				},
				rikt = 0,
				matt = {
					b = 1.6,
					d = 0.03,
					h = 0.5,
				},
				z0 = 1.5,
				antal = 3,
				farg = Color3.fromRGB(42, 38, 34),
				farg2 = Color3.fromRGB(140, 138, 122),
				kalla = "ridhus-klubb-02",
				klass = "VERIFIED",
				lage = "DERIVED",
			},
			{
				id = "reception_stol",
				rum = "reception",
				typ = "stol",
				pos = {
					1.3,
					74.3,
				},
				rikt = 0,
				matt = {
					b = 0.5,
					d = 0.5,
					h = 0.95,
				},
				farg = Color3.fromRGB(242, 239, 232),
				farg2 = Color3.fromRGB(184, 50, 46),
				kolliderar = true,
				kalla = "ridhus-klubb-02",
				klass = "VERIFIED",
				lage = "DERIVED",
			},
			{
				id = "skap_stovelbank",
				rum = "hall",
				typ = "bank",
				pos = {
					4.375,
					76.86,
				},
				rikt = -1.570796,
				matt = {
					b = 1.2,
					d = 0.4,
					h = 0.45,
				},
				farg = Color3.fromRGB(201, 168, 124),
				farg2 = Color3.fromRGB(30, 30, 30),
				kolliderar = true,
				kalla = "ridhus-klubb-01, ridhus-klubb-14, IMG_0268-r03, -r05",
				klass = "VERIFIED",
				lage = "DERIVED",
			},
		},
	},
	interiorytor = {
		stallKlubb = {
			id = "stallKlubb",
			typ = "mattBetong",
			farg = Color3.fromRGB(116, 111, 102),
			material = "Concrete",
			fogar = false,
			glans = "matt",
			kalla = "stall-inne-01-uppehallsrummet.jpg, stall-inne-04-teorisalen.jpg",
			klass = "FOTO",
			fargKlass = "UPPSKATTNING",
		},
		ridhusEntre = {
			id = "ridhusEntre",
			typ = "mattPlastgolv",
			farg = Color3.fromRGB(85, 87, 90),
			material = "SmoothPlastic",
			fogar = false,
			glans = "matt",
			kalla = "ridhus-klubb-20-grona-skapen.jpg, IMG_0268.MOV",
			klass = "FOTO",
			fargKlass = "UPPSKATTNING",
		},
	},
}

end)()

--[[ ══ Vyer.luau ══ ]]
local Vyer = (function()
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
		id = "c_trapporna_fran_foten",
		grupp = "Ridhuset inne",
		text = "På översta bänkraden vid klockväggen: vänstra C-trappan stiger västerut längs gaveln upp till övre gången",
		fran = { x = Ro.x + 15.6, y = Ro.y + 69.6, h = (R.kortanda.sockelH or 0) + R.kortanda.steg * R.kortanda.stegH + 1.7 },
		mot = { x = Ro.x + 12.0, y = Ro.y + 69.6 },
		krav = "Product Owner 2026-09-03 (senior review 17:18): C-ändans TVÅ raka trappor med träräcke (ridhus-inne-01, IMG_0192-f01/-f02, ridhus-inne-07) — loppen går LÄNGS gaveln, foten vid klockväggen, stigande utåt (vänstra mot väster, högra mot öster) från översta bänkraden till caféplanet, med vitt snedställt sidostycke mot banan. Båda ska gå att KLIVA i Studio: spelets bänkradssteg vid blockets västra ände (Spelabstraktion bankradsteg — märkt spelabstraktion, inte fidelity), raderna, trappan (Trappa c_trappa_v/o steg 1–9) och in i övre gången (Övre gångens golv). Inget steg över 0,19 m. Ingen osynlig ramp.",
	},
	{
		id = "c_trapporna_fran_toppen",
		grupp = "Ridhuset inne",
		text = "I övre gången ovanför vänstra trappans topp: ner över loppet, bänkraderna och banan",
		fran = { x = Ro.x + 12.8, y = Ro.y + 71.2, h = R.cafe.z0 + 1.7 },
		mot = { x = Ro.x + 13.5, y = Ro.y + 66.0 },
		krav = "Samma trappor sedda uppifrån (ridhus-klubb-10: trappan ner, banan öppen): övre gången har golv på caféplanet norr om glasbandet, glasbandet är BRUTET där loppen står, och man kan gå ner för trappan till bänkraderna utan att fastna. Rummen innanför (Café Krubban) är REFERENCE GAP och ska inte vara byggda.",
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
	-- F02-B: inredningen, från ungefär samma håll som referensbilderna.
	{
		id = "uppehallsrummet",
		grupp = "Stallet inne",
		text = "Uppehållsrummet mot västväggen (stall-inne-01)",
		fran = { x = So.x + 5.0, y = So.y + 66.5, h = 1.6 },
		mot = { x = So.x + 1.5, y = So.y + 62.0 },
		krav = "Två svarta skinnsoffor i vinkel kring två låga svarta bord, rosa träponny med mörk sadel, rund klocka och inramade hästfoton på pärlsponten, krukväxt. INGET pentry — det går inte att placera (matrisen).",
	},
	{
		id = "teorisalen",
		grupp = "Stallet inne",
		text = "Teorisalen från dörren i västväggen (stall-inne-04)",
		fran = { x = So.x + 11.7, y = So.y + 66.0, h = 1.6 },
		mot = { x = So.x + 17.0, y = So.y + 67.5 },
		krav = "Bordsblock i ljust trä med vita stolar, två whiteboards på östväggen, skåp med mikro i sydöstra hörnet, anatomiplanscher och kartonger längs sydväggen, två lysrör och ventilationskanalen i taket.",
	},
	{
		id = "sadelkammaren",
		grupp = "Stallet inne",
		text = "Sadelkammaren från dörren i brandväggen (stall-inne-03)",
		fran = { x = So.x + 8.3, y = So.y + 59.0, h = 1.6 },
		mot = { x = So.x + 8.6, y = So.y + 64.0 },
		krav = "Säkerhetsvästar på krokrad längs västväggen till vänster, vit stövelhylla full av stövlar till höger, smal passage emellan. Dörren till teorisalen rakt fram finns INTE i F02-A:s topologi — rapporterad separat.",
	},
	{
		id = "laktarraderna",
		grupp = "Ridhuset inne",
		text = "Läktaren från banan vid H (ridhus-inne-43, -14)",
		fran = { x = Ro.x + banMittX, y = Ro.y + B.y + 50, h = 1.6 },
		mot = { x = Ro.x + R.laktare.x0 + R.laktare.dackDjup / 2, y = Ro.y + B.y + 52 },
		krav = "Bakom den vita sargen: mörk gångbräda i däckhöjd, sedan TRE stegade bänkrader i ljus furu med röda kantlister, svarta dynor på översta raden. INGEN mörk brädfront, ingen kappregel, inget räcke, inga orange stolar utspridda. Returtunnan vid H, två orange stolar bakom domarboden.",
	},
	{
		id = "hinderupplaget",
		grupp = "Ridhuset inne",
		text = "Läktardäckets södra ände från banan (ridhus-inne-21)",
		fran = { x = Ro.x + banMittX - 4, y = Ro.y + B.y + 12, h = 1.6 },
		mot = { x = Ro.x + R.laktare.x0 + R.laktare.dackDjup / 2, y = Ro.y + B.y + 4 },
		krav = "På däcket bakom sargen: lutade bommar i färg, vita hinderstöd och bokstavsstället med F R H V C K M A. På kortsidan vid A: två speglar i träram, en på var sida om dubbeldörren.",
	},
	{
		id = "skapkorridoren",
		grupp = "Ridhuset inne",
		text = "Skåpkorridoren norrut mot valvfönstret (ridhus-klubb-01)",
		fran = { x = Ro.x + 4.95, y = Ro.y + 63.0, h = 1.6 },
		mot = { x = Ro.x + 4.95, y = Ro.y + 76.0 },
		krav = "Höga grå plåtskåp med enstaka röda och mörka dörrar längs västväggen, två vita stolar med rött tyg vid ett litet bord mitt i gången, bänk med stövlar under fönstret i norra änden. Östsidans öppningar är F02-A:s — glaspartierna i bilden är en strukturell anmärkning, inte inredning.",
	},
}


--[[ ── Visuell grind (issue #78) ── de tolv fasta reviewkamerorna, samma
	ID som qa/visual-gate/kameror.json. Kameran står som spelets egen
	tredjepersonskamera: 3,6 m bakom figuren, 2,25 m över hennes golv,
	blickpunkten 2,6 m framför henne (src/varld3d.js v3dKamera). `figur`
	är var karaktären står — tests/sikt.spec.luau skjuter sträckan kamera →
	figur genom de byggda delarna och kräver att allt som skymmer bär
	`Genomsiktlig` (tonas av Genomsikt på klienten). Lägena är uttryck i
	datan, som allt annat här. ]]
local function bakom(grupp: string, id: string, text: string, hus: any, ox: number, oy: number,
	fx: number, fy: number, z: number, rikt: number, krav: string)
	local cx, cy = math.cos(rikt), math.sin(rikt)
	-- Kameran hålls innanför väggarna (0,6 m), och kläms den in mot figuren
	-- lyfts den — samma regel som webbens v3dKamera.
	local kx = math.clamp(fx - cx * 3.6, 0.6, hus.bredd - 0.6)
	local ky = math.clamp(fy - cy * 3.6, 0.6, hus.langd - 0.6)
	local nara = math.sqrt((kx - fx) ^ 2 + (ky - fy) ^ 2)
	local h = 2.25 + (if nara < 2.0 then (2.0 - nara) * 0.9 else 0)
	return {
		id = id, grupp = grupp, text = text,
		fran = { x = ox + kx, y = oy + ky, h = h + z },
		mot = { x = ox + fx + cx * 2.6, y = oy + fy + cy * 2.6 },
		aim = 1.3 + z,
		figur = { x = ox + fx, y = oy + fy, z = z },
		krav = krav,
	}
end
local function rum(id: string)
	for _, r in ipairs(S.klubb.rum) do if r.id == id then return r.rekt end end
	error("hittar inte rummet " .. id)
end
local function dorr(hus: any, id: string)
	for _, d in ipairs(hus.dorrar) do if d.id == id then return d end end
	error("hittar inte dörren " .. id)
end
local function oppning(vaggId: string, id: string)
	for _, v in ipairs(S.klubb.vaggar) do
		if v.id == vaggId then
			for _, o in ipairs(v.oppningar or {}) do if o.id == id then return o end end
		end
	end
	error("hittar inte öppningen " .. id)
end
local function trappa(id: string)
	for _, t in ipairs(R.trappor or {}) do if t.id == id then return t end end
	error("hittar inte trappan " .. id)
end
local VG = "Visuell grind"
local gangA = (S.gangar.A.x0 + S.gangar.A.x1) / 2
local K = R.kortanda
local sadelO = oppning("genomgaende", "sadelkammare")
Vyer.reviewkameror = {
	--[[ STALL-ANKOMST (runda 3): exteriör, samma ansats som spelaren kommer
		från — grusplanen norr om klubbgaveln, mot förstukvisten och
		entrédörren. Dörrens läge läses ur fasaddatan. ]]
	(function()
		local hus
		for _, b in ipairs(G.byggnader) do if b.id == "stall" then hus = b end end
		local dorrX = hus.rekt.x + S.bredd / 2
		for _, op in ipairs(hus.oppningar or {}) do
			if op.sida == "N" and op.typ == "dorrgul" then dorrX = hus.rekt.x + S.bredd - op.u - op.b / 2 end
		end
		local gavelY = hus.rekt.y + hus.rekt.h
		return {
			id = "STALL-ANKOMST", grupp = VG,
			text = "Stallhuset entré från gården — grusplanen norr om klubbgaveln, söderut mot förstukvisten och entrédörren",
			fran = { x = dorrX - 1.5, y = gavelY + 7.5, h = 1.7 },
			mot = { x = dorrX, y = gavelY },
			aim = 1.6,
			figur = { x = dorrX, y = gavelY + 6.0, z = 0 },
			krav = "Verandans sadeltak med röd gavelspets och vita vindskivor på vita stolpar, det vita ribbräcket, den ockragula entrédörren med solfjäderfönster och vit karm, ett runt fönster på var sida, lampan, spiraltrappan och balkongen till vänster (stall-fasad-04, stall-entre-01/-03/-15). Dörrmarkören står vid samma dörr som innerpunkten ut_n.",
		}
	end)(),
	--[[ Explicit kamera mot den låsta fasadens entrédörr (mitt på gaveln, läst ur
		G.byggnader stall, sida N, typ dorrgul) — samma som kameror.json. ]]
	(function()
		local hus
		for _, b in ipairs(G.byggnader) do if b.id == "stall" then hus = b end end
		local dorrX = S.bredd / 2
		for _, op in ipairs((hus and hus.oppningar) or {}) do
			if op.sida == "N" and op.typ == "dorrgul" then dorrX = S.bredd - op.u - op.b / 2 end
		end
		return {
			id = "STALL-ENTRE", grupp = VG,
			text = "Stallhuset entré — inne i uppehållsrummets östdel i ögonhöjd, norrut mot fasadens entrédörr mitt på gaveln",
			fran = { x = So.x + dorrX - 0.4, y = So.y + S.langd - 5.4, h = 1.7 },
			mot = { x = So.x + dorrX, y = So.y + S.langd },
			aim = 1.2,
			figur = { x = So.x + dorrX - 2.2, y = So.y + S.langd - 3.0, z = 0 },   -- till vänster om dörren, inte framför
			krav = "Fasadens entrédörr (ockragul, solfjäderfönster, vit karm) rakt fram med det västra runda fönstret bredvid; öppen yta fram till gaveln. Det östra runda fönstret hamnar i teorisalen — dokumenterad motsägelse (planens vindfång mot fasadens entré). Dörrbladets färg inifrån är [antagande].",
		}
	end)(),
	bakom(VG, "STALL-UPPEHALL", "Uppehållsrummet från södra änden (vid lobbyn) norrut genom hela rummet",
		S, So.x, So.y, 4.0, rum("uppehallsrum").y + 1.6, 0, math.pi / 2,
		"Rummets hela längd i ögonhöjd: västväggen till vänster, öppningen mot östdelen till höger UTAN vägg (Spatial Canon v2 stall_uppehall_open), planens symbolruta till höger, gaveln med entrén längst bort. Möblerna ur stall-inne-01 (F02-B): två svarta soffor i vinkel, låga bord, rosa träponny, klocka, växt, fotovägg."),
	--[[ Fotots vinkel (stall-inne-01): explicit kamera i rummets östra del,
		snett mot sydvästra hörnet där F02-B ställer soffgruppen. ]]
	{
		id = "STALL-UPPEHALL-SOFFA", grupp = VG,
		text = "Uppehållsrummets soffhörna — från rummets östra del snett mot sydvästra hörnet (stall-inne-01)",
		fran = { x = So.x + 4.7, y = So.y + 62.9, h = 1.6 },
		mot = { x = So.x + 0.9, y = So.y + 66.3 },
		aim = 1.0,
		figur = { x = So.x + 2.4, y = So.y + 67.2, z = 0 },   -- höger om ponnyn, utanför soffgruppen
		krav = "Två svarta soffor i vinkel kring låga bord, rosa träponny med sadel, klocka, växt, fotovägg på pärlsponten, valvfönstret i västväggen. Gruppens läge mot fönstret är ASSUMPTION (F02-B).",
	},
	--[[ Review 2026-09-04 07:54 (Tobias): dörrläsbarhet — explicit kamera i
		klubbdelens lobby mot teorisalens och sadelkammarens dörrar. ]]
	{
		id = "STALL-KLUBBDORRAR", grupp = VG,
		text = "Klubbdelens inre entré från gång A — den genomgående väggens dörrar (inre entrén, sadelkammarens dörr)",
		fran = { x = So.x + 5.2, y = So.y + S.klubbY + 1.6, h = 1.6 },
		mot = { x = So.x + 4.55, y = So.y + S.klubbY + 5.2 },
		aim = 1.15,
		figur = { x = So.x + 3.9, y = So.y + S.klubbY + 3.5, z = 0 },
		krav = "Den genomgående väggens två dörröppningar med vit karm, mörk smyg och överstycke som skiljer dem från väggen; ingen etikett behövs för att förstå var dörrarna är.",
	},
	--[[ Explicita kameror i fotonas vinklar (review 2026-09-04 08:50, blocker B/C). ]]
	{
		id = "STALL-TEORISAL", grupp = VG,
		text = "Teorisalen i stall-inne-04:s vinkel — från västra delen österut mot whiteboardväggen",
		fran = { x = So.x + 11.7, y = So.y + 67.6, h = 1.6 },
		mot = { x = So.x + 17.3, y = So.y + 67.0 },
		aim = 1.2,
		figur = { x = So.x + 15.9, y = So.y + 66.2, z = 0 },   -- längre in, mellan stolraden och planschväggen
		krav = "Whiteboardväggen rakt fram, bordsblocket med vita stolar, planscherna på sydväggen, skåpet med mikron, lysrören och spiralkanalen under det platta innertaket; ingen etikettplatta.",
	},
	{
		id = "STALL-SADELKAMMARE", grupp = VG,
		text = "Sadelkammaren i stall-inne-03:s vinkel — från södra delen norrut: västar vänster, stövelhylla höger, dörren mot teorisalen rakt fram",
		fran = { x = So.x + 8.7, y = So.y + 58.4, h = 1.6 },
		mot = { x = So.x + 8.7, y = So.y + 64.3 },
		aim = 1.2,
		figur = { x = So.x + 8.15, y = So.y + 62.5, z = 0 },   -- vänster om dörren, framför västarna
		krav = "Västarna på krokrader till vänster, den vita stövelhyllan till höger, den grå dörren med fönster rakt fram (ritad på väggen, ingen passage), platt innertak; ingen etikettplatta.",
	},
	--[[ PO 2026-09-04 15:15 (references/spatial/stall-efter-pausrum-po-v1.md):
		zonen efter pausrummet — två fasta vyer för side-by-side mot PO:s foton. ]]
	{
		id = "STALL-EFTER-PAUSRUM-V1", grupp = VG,
		text = "Från pausrummets riktning (inre entrén) ut i service-/tvättzonen och ner i stallgången",
		fran = { x = So.x + (S.klubb.vaggar[1].oppningar[1].x0 + S.klubb.vaggar[1].oppningar[1].x1) / 2, y = So.y + S.klubb.y0 - 0.55, h = 1.65 },
		mot = { x = So.x + 8.4, y = So.y + S.klubbY - 0.55 },
		aim = 1.0,
		figur = { x = So.x + 7.2, y = So.y + S.klubbY + 1.35, z = 0 },
		krav = "Öppen zon utan nya väggar: vit servicevägg bakom kameran, den låga avskärmningen, hyllan med backar, blå bin och pall i mittzonen till vänster, det mörka gångstråket rakt fram genom brandväggens öppning ner i gång A mot boxfronterna med anslagstavlor och brandsläckare; högt plåttak med balkar.",
	},
	{
		id = "STALL-EFTER-PAUSRUM-V2", grupp = VG,
		text = "Från stallgången tillbaka mot tvätt-/serviceväggen och utgångsrelationen (inre entrén med skylt och klocka)",
		fran = { x = So.x + 6.0, y = So.y + S.klubbY - 0.25, h = 1.6 },
		mot = { x = So.x + 7.6, y = So.y + S.klubb.y0 },
		aim = 1.3,
		figur = { x = So.x + 6.6, y = So.y + S.klubbY + 2.95, z = 0 },   -- mellan inre entrén och sadelkammardörren, skymmer ingen av dem
		krav = "Den vita serviceväggen med rör-/kabelstråket, den grå dörren (inre entrén) med kodlås, klocka, utrymningsskylt, brandsläckare och grön säkerhetsutrustning, den rostfria tvättstationen med korg och krokar, den grå sadelkammardörren; fri passage genom brandväggens öppning.",
	},
	bakom(VG, "STALL-GANG-A", "Gång A norrut mot klubbdelen",
		S, So.x, So.y, gangA, S.boxStartY + 6, 0, math.pi / 2,
		"Boxfronter i antracit med galvad ram på båda sidor, markstensgång, klubbdelens tvärvägg långt fram."),
	--[[ Explicit kamera (som i kameror.json): följkameran får inte plats i
		gången utan att backa in i boxraden, så reviewkameran står själv vid
		gång A:s östra kant i ögonhöjd och ser västerut genom brottet. ]]
	{
		id = "HASTPASSAGE", grupp = VG,
		text = "Från gång A:s östra kant i ögonhöjd, västerut genom brottet i västra boxraden in i hästgången",
		fran = { x = So.x + S.gangar.A.x1 - 0.2, y = So.y + dorr(S, "hastgang").pos[2] + 0.9, h = 1.7 },
		mot = { x = So.x + 0.9, y = So.y + dorr(S, "hastgang").pos[2] },
		aim = 1.2,
		figur = { x = So.x + S.gangar.A.x0 + 0.6, y = So.y + dorr(S, "hastgang").pos[2], z = 0 },
		krav = "ETT brott i västra boxraden på hästgångens höjd med dörrmarkören, boxfronter på båda sidor om brottet, figuren i gångens västra kant. Ingen tvärkorridor genom huset. Passagens insida är REFERENCE GAP.",
	},
	--[[ Explicit kamera (som i kameror.json): följkameran bakom en figur vid
		innerdörren hamnar söder om hallen, uppe på läktarens bänkrader
		(F02-B) — reviewkameran står därför själv i hallen vid dörren i
		ögonhöjd och ser norrut, figuren några meter in i hallen. ]]
	{
		id = "RIDHUS-ENTRE", grupp = VG,
		--[[ KORRIGERAD 2026-09-10 (arbetsorder #162 punkt 1/4): kameran stod i
			dörren, alltså i västremsan x 0–2,2 som slutar i receptionens
			sydvägg. Mätt därifrån är vinkeln mot glasfrontens normal 95,7° —
			baksidan av fronten — så ingen framning i fickan kunde visa glaset.
			Härifrån: 74,2°, 6,6 m till glasets mitt, kameran i gången (inte
			inne i en skåpbank). Ingen geometri rörd. ]]
		text = "Entrédelen från den plats en besökare står på när hon kommit in och vänt sig mot gången: blicken snett nordväst, receptionens glasade front läses och entréänden ligger kvar i bild",
		fran = { x = Ro.x + 3.9, y = Ro.y + 68.9, h = 1.65 },
		mot = { x = Ro.x + 2.4, y = Ro.y + 74.2 },
		aim = 1.1,
		figur = { x = Ro.x + 3.9, y = Ro.y + 72.4, z = 0 },
		krav = "Receptionens låga bröstning med hylla och glasrutor (GLASS) snett framför till vänster, skåpgodset samlat på höger sida av gången, öppen hall utan rumslådor tillbaka mot entréänden; ingen sida får läsa som två skåpväggar.",
	},
	--[[ Review 2026-09-04 07:54 (Tobias): receptionen, entrén inifrån och
		läktartrappan — explicita kameror (samma lägen som kameror.json). ]]
	{
		id = "RIDHUS-RECEPTION", grupp = VG,
		text = "Receptionen från skåpgången — glasad bröstning i nordvästra hörnet, skåpraden mitt emot (ridhus-klubb-02/-15)",
		--[[ KORRIGERAD 2026-09-10 (arbetsorder #162 punkt 3): vinkeln var redan
			bäst av alla vyer (58,7° mot glasfrontens normal), men bilden var
			för trång och figuren skymde fronten. Backad till 4,9 m med
			figuren längre bort. Första försöket la kameran på x 4,55 — INNE i
			skåpbankens volym (x 4,2–4,7), vilket tvingade fram en toning och
			gav spökgeometri i bilden. Nu står den i gången: 70,1°, 5,0 m. ]]
		fran = { x = Ro.x + 3.95, y = Ro.y + 70.6, h = 1.6 },
		mot = { x = Ro.x + 2.5, y = Ro.y + 74.6 },
		aim = 1.0,
		figur = { x = Ro.x + 3.05, y = Ro.y + 74.2, z = 0 },
		krav = "Receptionens LÅNGA låga bröstning med hyllan och de fyra glasrutorna tydligt läsbara, rummet bakom glaset med träskåp och tavlor, skåpraden mitt emot på gångens andra sida; fronten får inte skymmas av figuren eller skåpen. Inga toalettboxar i hörnet.",
	},
	{
		id = "RIDHUS-ENTRE-INNE", grupp = VG,
		text = "Huvudentrén inifrån — västerut mot fasadens entrédörr (dorrvit u 9) från hallen",
		fran = { x = Ro.x + 5.4, y = Ro.y + 68.6, h = 1.6 },
		mot = { x = Ro.x + 0.0, y = Ro.y + dorr(R, "ut_ridhus_W_9").pos[2] },
		aim = 1.1,
		figur = { x = Ro.x + 3.0, y = Ro.y + 68.7, z = 0 },
		krav = "Entrédörren i västväggen rakt fram: vit glasad dubbeldörr med vita karmar och grön utrymningsskylt ovanför, dörrmarkören vid samma dörr; öppen hall runt figuren.",
	},
	--[[ Product Owner 2026-09-04 11:56 ("Saknas skåp"): skåpförvaringen ur
		ridhus-klubb-16/-18/-20/-21 som fristående grupper i entrédelens
		västra remsa. Explicit kamera från gångens södra ände snett mot NV. ]]
	{
		id = "RIDHUS-SKAPRUM", grupp = VG,
		text = "Skåpförvaringen i entrédelens västra remsa (ridhus-klubb-16/-18/-20/-21) — från gångens södra ände snett mot nordväst",
		fran = { x = Ro.x + 3.0, y = Ro.y + 68.4, h = 1.55 },
		mot = { x = Ro.x + 0.8, y = Ro.y + 71.9 },
		aim = 1.1,
		figur = { x = Ro.x + 2.0, y = Ro.y + 71.9, z = 0 },
		krav = "Tre skåpgrupper i öppen yta utan nya väggar: de gröna tvåvåningsskåpen på svarta ben närmast, de höga grå/mörkblå skåpen längs västväggen, den vita tvåvåningsbanken under receptionens sydvägg; gången x 2,2–4,2 fri; inga rumslådor.",
	},
	{
		id = "RIDHUS-LAKTARTRAPPA", grupp = VG,
		text = "Trappan vid läktarens norra ände (H) — från hallens sydvästra hörn mot västväggen (ridhus-inne-39, ridhus-klubb-11)",
		fran = { x = Ro.x + 4.3, y = Ro.y + 69.9, h = 1.7 },
		mot = { x = Ro.x + 1.1, y = Ro.y + 65.4 },
		aim = 1.6,
		figur = { x = Ro.x + 2.4, y = Ro.y + 67.4, z = 0 },
		krav = "En trappa i mörkt trä med handledare längs västväggen vid läktarens norra ände som når övre plan; läktardäckets ände; figuren kan gå från hallgolvet upp på däcket och vidare upp.",
	},
	{
		id = "RIDHUS-SKAPKORRIDOR", grupp = VG,
		--[[ KORRIGERAD 2026-09-10 (arbetsorder #162 punkt 2/4): kameran stod vid
			y 66,7, sju meter söder om glaset och 85,1° mot dess normal — kant i
			kant, alltså en strimma, och bilden blev bara skåp. Flyttad norrut
			längs gången till 3,6 m från glasets mitt. Ingen geometri rörd. ]]
		text = "Den långa skåpgången (ridhus-klubb-01/-15) norrut: skåpraden höger, receptionens bröstning och glasrutor vänster mitt emot, bordet med stolarna, gavelns valvfönster i fonden",
		fran = { x = Ro.x + 3.3, y = Ro.y + 71.8, h = 1.65 },
		mot = { x = Ro.x + 3.2, y = Ro.y + 77.0 },
		aim = 1.0,
		figur = { x = Ro.x + 3.5, y = Ro.y + 76.6, z = 0 },
		krav = "Lång obruten skåprad till höger, receptionens låga bröstning med hylla och glasrutor till vänster mitt emot, bordet med de vita stolarna emellan, fri siktlinje till gavelns valvfönster och stövelbänken; inga korridorväggar.",
	},
	--[[ ChatGPT visual re-review 2026-09-10 av `d2e8211`: glas/skåp-relationen
		går inte att visa norrut, eftersom receptionens sydvägg
		(PRODUCT_OWNER_VERIFIED) står mellan entrén och glaset. Reviewn bad om
		kameror vid FOTOGRAFISKT LIKVÄRDIGA lägen i stället för att flytta
		verifierad geometri. De två nedan står där fotografen faktiskt stod. ]]
	{
		id = "RIDHUS-KLUBBGANG", grupp = VG,
		text = "Klubbgången från gaveländen söderut (ridhus-klubb-15:s egen ståplats): skåpraden vänster, receptionens bröstning med glasrutorna höger, bordet med stolarna emellan",
		fran = { x = Ro.x + 3.35, y = Ro.y + 76.3, h = 1.6 },
		mot = { x = Ro.x + 3.3, y = Ro.y + 70.5 },
		aim = 1.0,
		figur = { x = Ro.x + 3.85, y = Ro.y + 73.6, z = 0 },
		krav = "Skåpraden till VÄNSTER i hela gångens längd, receptionens låga vita bröstning med hylla och glasrutor till HÖGER, bordet med de två vita stolarna emellan, fri siktlinje söderut mot entrédelen; inga korridorväggar.",
	},
	--[[ RIDHUS-RECEPTIONSFRONT togs bort 2026-09-10 (arbetsorder #162 punkt 3):
		dess uppgift — den läsbara glasfronten — är RIDHUS-RECEPTIONs, och den
		kameran har korrigerats i stället. Två kameror mot samma vägg är
		utfyllnad, inte evidens. `RIDHUS-KLUBBGANG` står kvar: den är den enda
		vyn söderut och motsvarar ridhus-klubb-15:s egen vinkel. ]]
	bakom(VG, "ARENA-A", "Banan nära A, söderut mot kortsidan",
		R, Ro.x, Ro.y, R.bana.x + R.bana.w / 2, R.bana.y + 6, 0, -math.pi / 2,
		"Vit sarg med mörk sockel, A-skylten på sargen, sanden dovt brungrå."),
	bakom(VG, "ARENA-C", "Banan nära C, norrut mot C-blocket",
		R, Ro.x, Ro.y, R.bana.x + R.bana.w / 2, R.bana.y + R.bana.h - 8, 0, math.pi / 2,
		"C-blockets bänkrader, klockväggen, de två trapporna med vita sidostycken, glasbandet i tre fält."),
	bakom(VG, "LAKTARE", "Läktardäcket söderut",
		R, Ro.x, Ro.y, R.laktare.x0 + R.laktare.dackDjup / 2, (R.laktare.y0 + R.laktare.y1) / 2 + 6, R.laktare.dackZ, -math.pi / 2,
		"Plankdäck, mörk front med ljus kappregel, räcket, banan till vänster. Domarbåset står på däcket."),
	bakom(VG, "C-BLOCK-OVRE", "Från nedersta bänkraden vid klockan (som ridhus-inne-01)",
		R, Ro.x, Ro.y, K.klocka.x, K.y0 + 0.6, (K.sockelH or 0) + K.stegH, math.pi / 2,
		"Raderna, de två loppen stigande utåt, klockväggen, glasbandet, övre gången bakom. Spelets bänkradssteg (gul markör) är SPELABSTRAKTION."),
}
for _, v in ipairs(Vyer.reviewkameror) do table.insert(Vyer.vyer, v) end

local ORDNING = { "Komplexet", "Ridhuset inne", "Stallet inne", VG }

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

end)()

--[[ ══ QAPanel.luau ══ ]]
local QAPanel = (function()
--!strict
--[[ UBRF QA — utvecklarpanel för den manuella Studio-genomgången.

	Tobias ska kunna göra hela den visuella granskningen utan att röra
	kommandoraden och utan att kunna kodbasen: klicka Nästa, titta, klicka
	PASS eller FEL, gå vidare.

	VARFÖR DEN LIGGER HÄR OCH INTE I roblox/src/client/
	Panelen får aldrig bli spelar-UI. Klientmapparna paketeras in i spelet;
	den här filen gör det inte — den fogas bara in av tools/studio-paket.py
	i den fil man klistrar in i Studio. Utöver det vägrar den starta utanför
	Studio. Två spärrar, för en dev-panel som läcker ut till spelare är
	precis den sortens miss ingen upptäcker förrän den står i en release.

	Vyerna kommer ur Vyer.luau, som i sin tur räknar dem ur UBRFKomplex.
	Panelen har alltså ingen egen lista att hålla i synk.
]]

local RunService = game:GetService("RunService")

local QAPanel = {}

local Vyer: any = nil
local gui: ScreenGui? = nil
local i = 1
local resultat: { [string]: string } = {}

local FARG = {
	bak = Color3.fromRGB(28, 28, 30),
	ram = Color3.fromRGB(64, 64, 68),
	text = Color3.fromRGB(238, 234, 220),
	svag = Color3.fromRGB(150, 148, 142),
	pass = Color3.fromRGB(64, 132, 76),
	fel = Color3.fromRGB(150, 58, 52),
	knapp = Color3.fromRGB(52, 52, 56),
}

local function ny(klass: string, foralder: Instance, egenskaper: { [string]: any }): any
	local o = Instance.new(klass)
	for k, v in egenskaper do
		(o :: any)[k] = v
	end
	o.Parent = foralder
	return o
end

local function knapp(foralder: Instance, text: string, x: number, b: number,
	y: number, h: number, farg: Color3): TextButton
	local kn = ny("TextButton", foralder, {
		Text = text, Font = Enum.Font.GothamMedium, TextSize = 13,
		TextColor3 = FARG.text, BackgroundColor3 = farg, BorderSizePixel = 0,
		Position = UDim2.new(x, 0, 0, y), Size = UDim2.new(b, -6, 0, h),
		AutoButtonColor = true,
	})
	ny("UICorner", kn, { CornerRadius = UDim.new(0, 4) })
	return kn
end

--[[ Sammanfattningen skrivs till Output. Den är hela poängen med panelen:
	efter genomgången ska det gå att klistra in en färdig lista i PR:en utan
	att någon behöver minnas vad som var vad. ]]
local function sammanfatta()
	local vyer = Vyer.vyer
	local pass, fel, kvar = 0, 0, 0
	--[[ Raderna inleds med en bock, inte med ordet. roblox/tests/kor.sh
		letar efter ^\s*FEL for att hitta misslyckade prov, och en rad som
		BORJAR med FEL har fick hela qa-specen att se rod ut fast den var
		gron. Ordet star kvar for den som laser; markoren gor att provbanken
		inte forvaxlar panelens utskrift med sin egen. ]]
	print("\n── UBRF QA · resultat ──")
	for _, v in ipairs(vyer) do
		local r = resultat[v.id]
		if r == "PASS" then
			pass += 1
			print(("  ✓ PASS  %s"):format(v.id))
		elseif r == "FEL" then
			fel += 1
			print(("  ✗ FEL   %s   → skärmdump: qa-%s-FEL.png"):format(v.id, v.id))
		else
			kvar += 1
			print(("  · —     %s   (inte bedömd)"):format(v.id))
		end
	end
	print(("  %d PASS, %d FEL, %d kvar av %d"):format(pass, fel, kvar, #vyer))
	if fel > 0 then
		print("  Skriv for varje FEL vad du SAG och VAR — inte gissad orsak.")
	end
end

local uppdatera: () -> ()

function QAPanel.start(vyModul: any)
	if not RunService:IsStudio() then
		warn("[UBRF QA] Panelen startar bara i Studio.")
		return
	end
	Vyer = vyModul or Vyer
	if not Vyer or not Vyer.vyer or #Vyer.vyer == 0 then
		warn("[UBRF QA] Hittar inga vyer — kor bygget forst.")
		return
	end
	if gui then
		gui.Enabled = true
		uppdatera()
		return
	end

	local spelare = game:GetService("Players").LocalPlayer
	local mal = spelare and spelare:FindFirstChildOfClass("PlayerGui")
		or game:GetService("CoreGui")

	gui = ny("ScreenGui", mal, {
		Name = "UBRF_QA", ResetOnSpawn = false, IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})

	local ram = ny("Frame", gui :: any, {
		BackgroundColor3 = FARG.bak, BorderSizePixel = 0,
		Position = UDim2.new(0, 16, 0, 16), Size = UDim2.new(0, 300, 0, 188),
	})
	ny("UICorner", ram, { CornerRadius = UDim.new(0, 8) })
	ny("UIStroke", ram, { Color = FARG.ram, Thickness = 1 })

	ny("TextLabel", ram, {
		Text = "UBRF QA", Font = Enum.Font.GothamBold, TextSize = 12,
		TextColor3 = FARG.svag, TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 0, 8), Size = UDim2.new(1, -24, 0, 16),
	})

	local raknare = ny("TextLabel", ram, {
		Text = "", Font = Enum.Font.Gotham, TextSize = 12,
		TextColor3 = FARG.svag, TextXAlignment = Enum.TextXAlignment.Right,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 0, 8), Size = UDim2.new(1, -24, 0, 16),
	})

	local namn = ny("TextLabel", ram, {
		Text = "", Font = Enum.Font.GothamBold, TextSize = 15,
		TextColor3 = FARG.text, TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1, TextTruncate = Enum.TextTruncate.AtEnd,
		Position = UDim2.new(0, 12, 0, 28), Size = UDim2.new(1, -24, 0, 20),
	})

	local beskrivning = ny("TextLabel", ram, {
		Text = "", Font = Enum.Font.Gotham, TextSize = 12,
		TextColor3 = FARG.svag, TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 0, 50), Size = UDim2.new(1, -24, 0, 46),
	})

	local status = ny("TextLabel", ram, {
		Text = "", Font = Enum.Font.GothamMedium, TextSize = 12,
		TextColor3 = FARG.svag, TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 0, 100), Size = UDim2.new(1, -24, 0, 16),
	})

	local forra = knapp(ram, "◀", 0.03, 0.16, 122, 28, FARG.knapp)
	local nasta = knapp(ram, "▶", 0.20, 0.16, 122, 28, FARG.knapp)
	local pass = knapp(ram, "PASS", 0.38, 0.28, 122, 28, FARG.pass)
	local fel = knapp(ram, "FEL", 0.67, 0.30, 122, 28, FARG.fel)
	local aterstall = knapp(ram, "Återställ kameran", 0.03, 0.94, 154, 26, FARG.knapp)

	uppdatera = function()
		local v = Vyer.vyer[i]
		if not v then return end
		namn.Text = v.id
		beskrivning.Text = v.text
		raknare.Text = ("%d/%d"):format(i, #Vyer.vyer)
		local r = resultat[v.id]
		if r == "PASS" then
			status.Text = "PASS"
			status.TextColor3 = FARG.pass
		elseif r == "FEL" then
			status.Text = "FEL — spara qa-" .. v.id .. "-FEL.png"
			status.TextColor3 = FARG.fel
		else
			status.Text = "inte bedömd"
			status.TextColor3 = FARG.svag
		end
	end

	local function ga(steg: number)
		i = ((i - 1 + steg) % #Vyer.vyer) + 1
		local ok, err = pcall(function() Vyer.ga(Vyer.vyer[i].id) end)
		if not ok then warn("[UBRF QA] " .. tostring(err)) end
		uppdatera()
	end

	local function bedom(varde: string)
		local v = Vyer.vyer[i]
		if not v then return end
		resultat[v.id] = varde
		uppdatera()
		sammanfatta()
		if i < #Vyer.vyer then ga(1) end
	end

	forra.Activated:Connect(function() ga(-1) end)
	nasta.Activated:Connect(function() ga(1) end)
	pass.Activated:Connect(function() bedom("PASS") end)
	fel.Activated:Connect(function() bedom("FEL") end)
	aterstall.Activated:Connect(function()
		local kam = workspace.CurrentCamera
		if kam then kam.CameraType = Enum.CameraType.Custom end
	end)

	ga(0)
	print("[UBRF QA] Panelen igång. " .. #Vyer.vyer .. " vyer att gå igenom.")
end

function QAPanel.dolj()
	if gui then gui.Enabled = false end
end

QAPanel.sammanfatta = sammanfatta

return QAPanel

end)()

--[[ ══ Anlaggningen.luau ══ ]]
--!strict
-- Bygger hela UBRF-anläggningen i Studio ur den genererade geometrin.
--
-- Kör i ett run_code-anrop tillsammans med BuildKit och UBRFKomplex, eller lägg
-- båda som ModuleScripts i ServerStorage. Skriptet river sin gamla modell och
-- bygger om från grunden, precis som byggnadsskripten i _exempel.luau.
--
-- SKRIV INGA MÅTT HÄR. Alla tal kommer ur UBRFKomplex.luau, som i sin tur
-- genereras ur src/site.js — samma kod som webbspelet bygger sin värld av. Det
-- är hela poängen: Roblox och webben kan inte glida isär om anläggningens mått,
-- färger, öppningar eller om vilka hus som sitter ihop. Behöver ett mått ändras
-- ändras det i src/site.js, sedan körs `node tools/exportera-geometri.js`.
--
-- Det här skriptet får däremot ha egna åsikter om SÅDANT SOM INTE ÄR GEOMETRI:
-- material, tjocklekar, hur en öppning tecknas. Sådant är rendering, och
-- rendering får vara plattformsspecifik enligt paritetsregeln i CLAUDE.md.

local BK = BuildKit             -- inklistrad ovanför, eller require(...)
local G = UBRFKomplex           -- likaså
local GEO = Geometri            -- likaså; ren geometri, mätt i roblox/tests/
local YTOR = G.interiorytor     -- F02-C: delade interiörmaterial, inte en andra färglista

local VAGGT = 0.3               -- väggtjocklek, rendering
local MARKT = 0.2               -- marklagrets tjocklek

local MARKFARG: { [string]: Color3 } = {
	gras   = Color3.fromRGB(104, 152, 68),
	grus   = Color3.fromRGB(176, 168, 150),
	asfalt = Color3.fromRGB(78, 78, 82),
	sand   = Color3.fromRGB(206, 186, 148),
	betong = Color3.fromRGB(150, 150, 146),
	aker   = Color3.fromRGB(150, 138, 96),
}

local MARKMATERIAL: { [string]: Enum.Material } = {
	gras   = Enum.Material.Grass,
	grus   = Enum.Material.Ground,
	asfalt = Enum.Material.Asphalt,
	sand   = Enum.Material.Sand,
	betong = Enum.Material.Concrete,
	aker   = Enum.Material.Ground,
}

-- Öppningarnas färger. Namnen kommer ur src/site.js och beskriver vad man ser:
-- portbla = de blågrå skjutportarna, portplat = durkplåtsdörrarna, dorrgul =
-- den ockragula stalldörren under förstukvisten.
local OPPNINGSFARG: { [string]: Color3 } = {
	portbla    = Color3.fromRGB(94, 108, 122),
	portplat   = Color3.fromRGB(150, 152, 156),
	portsilver = Color3.fromRGB(196, 198, 202),
	dorrgul    = Color3.fromRGB(206, 158, 62),
	dorrvit    = Color3.fromRGB(238, 236, 228),
	dorrmork   = Color3.fromRGB(58, 48, 44),
	dorr       = Color3.fromRGB(228, 226, 218),
}

local function arFonster(typ: string): boolean
	return typ == "fonster" or typ == "rund" or typ == "valv"
end

local function byggMark(model: Model, base: CFrame)
	for _, m in ipairs(G.mark) do
		local p = BK.box(model, base, "Mark " .. m.typ,
			m.rekt.x, -MARKT, m.rekt.y, m.rekt.w, MARKT, m.rekt.h,
			MARKFARG[m.typ] or Color3.fromRGB(120, 120, 120),
			MARKMATERIAL[m.typ] or Enum.Material.Ground)
		p.CanCollide = false
	end
end

local function byggOppning(model: Model, base: CFrame, b, o)
	-- Var öppningen sitter är geometri och ligger därför i Geometri.luau, som
	-- är mätt mot webbkoden. Hur den tecknas är rendering och ligger här.
	local x, z, along, side = GEO.oppningsHorn(b.rekt, o.sida, o.u, o.b)

	local namn = (o.label or o.typ) .. (if o.intern then " (intern)" else "")
	if arFonster(o.typ) then
		BK.window(model, base, x, z, o.z0, o.b, o.h, along, side,
			Color3.fromRGB(238, 236, 228))
	else
		local f = OPPNINGSFARG[o.typ] or Color3.fromRGB(200, 200, 200)
		BK.opening(model, base, namn, x, z, o.z0, o.b, o.h, along, side, f,
			Enum.Material.SmoothPlastic)
	end

	--[[ Skärmtaket över en entrédörr.

		`skarm` fanns i den delade geometrin och ritades av webben, men den
		här filen läste aldrig fältet — så varje dörr som på webben bar ett
		vitt skärmtak stod i Roblox som en naken lucka i väggen. Det är just
		det som avgör om något LÄSER som en entré på håll, och stallets
		klubbdörr mot grusplanen är en av dem.

		Förenklat mot webbens `v3dSkarmtak`: där är taket en gavelform med
		två sneda sidobalkar; här är det en platta med två konsoler. Samma
		mått och samma läge — stiliserat betyder förenklat, inte påhittat. ]]
	if o.skarm then
		local UT, TJOCK, OVER = 0.80, 0.13, 0.30
		local V = Color3.fromRGB(238, 236, 228)
		local y = o.z0 + o.h + OVER
		--[[ `side` är +1/-1 och pekar ut från fasaden längs den axel väggen
			INTE löper i. Plattan skjuter ut åt det hållet. ]]
		local ut = if side > 0 then 0 else -UT
		if along == "X" then
			BK.box(model, base, "Skärmtak", x + (o.b - o.skarm) / 2, y, z + ut,
				o.skarm, TJOCK, UT, V, Enum.Material.SmoothPlastic)
			for _, s in ipairs({ 0, 1 }) do
				BK.box(model, base, "Skärmkonsol",
					x + (o.b - o.skarm) / 2 + s * (o.skarm - 0.11), y - 0.62, z + ut,
					0.11, 0.62, 0.11, V, Enum.Material.SmoothPlastic)
			end
		else
			BK.box(model, base, "Skärmtak", x + ut, y, z + (o.b - o.skarm) / 2,
				UT, TJOCK, o.skarm, V, Enum.Material.SmoothPlastic)
			for _, s in ipairs({ 0, 1 }) do
				BK.box(model, base, "Skärmkonsol", x + ut, y - 0.62,
					z + (o.b - o.skarm) / 2 + s * (o.skarm - 0.11),
					0.11, 0.62, 0.11, V, Enum.Material.SmoothPlastic)
			end
		end
	end
end

local function byggHus(model: Model, base: CFrame, b)
	local r = b.rekt
	local fasad = b.fargV
	local tak = b.fargT or fasad

	BK.box(model, base, b.id .. " grund", r.x, -0.25, r.y, r.w, 0.25, r.h,
		Color3.fromRGB(120, 120, 115), Enum.Material.Concrete)

	BK.wall(model, base, b.id .. " syd",  r.x, r.y, r.w, b.hV, VAGGT, "X", fasad)
	BK.wall(model, base, b.id .. " norr", r.x, r.y + r.h - VAGGT, r.w, b.hV, VAGGT, "X", fasad)
	BK.wall(model, base, b.id .. " vast", r.x, r.y, r.h, b.hV, VAGGT, "Z", fasad)
	BK.wall(model, base, b.id .. " ost",  r.x + r.w - VAGGT, r.y, r.h, b.hV, VAGGT, "Z", fasad)

	for _, o in ipairs(b.oppningar or {}) do
		byggOppning(model, base, b, o)
	end

	-- gableRoof vill ha nocken som "X" eller "Z". Spelets nock "NS" löper längs
	-- y, alltså längs z i Roblox.
	model:SetAttribute("GavelFarg", fasad)
	BK.gableRoof(model, base, r.x, r.y, r.w, r.h, b.hV,
		GEO.taklutning(r, b.hV, b.hN, b.nock),
		if b.nock == "NS" then "Z" else "X", 0.4, tak)
end

--[[ ══ IGENKÄNNINGSDRAGEN ═══════════════════════════════════════════

	Review 03:s tillägg: verifierade identitetsdrag fanns bara i webbens
	renderare, så primärplattformen saknade just det som avgör om någon
	känner igen UBRF. Måtten ligger nu i G.identitet, exporterade ur
	src/site.js — inte avskrivna hit.

	Bara det som gör att man känner igen huset. Dekor utan källa hör inte
	hemma här, och listar och skruvar hör inte till en fidelity-gate. ]]

local IDFARG = {
	huv     = Color3.fromRGB(78, 84, 92),
	svart   = Color3.fromRGB(38, 41, 46),
	vit     = Color3.fromRGB(238, 236, 228),
	betong  = Color3.fromRGB(194, 191, 182),
	stal    = Color3.fromRGB(154, 160, 166),
	kabel   = Color3.fromRGB(180, 185, 190),
	vent    = Color3.fromRGB(194, 199, 204),
	panel   = Color3.fromRGB(94, 44, 51),
	list    = Color3.fromRGB(238, 236, 228),
	trappa  = Color3.fromRGB(58, 62, 68),
}

local function byggStallIdentitet(model: Model, base: CFrame)
	local b = nil
	for _, x in ipairs(G.byggnader) do if x.id == "stall" then b = x end end
	if not b then return end
	local r, I = b.rekt, G.identitet.stall
	local cx = r.x + r.w / 2

	-- Huvraden på nocken, en per box. Det tydligaste draget på håll.
	local H = I.huvrad
	for i = 1, H.antal do
		local z = r.y + r.h - (H.forstaFranNorr + H.delning * (i - 1))
		BK.box(model, base, "Takhuv " .. i, cx - H.sida / 2, b.hN + 0.28 - H.hojd / 2,
			z - H.sida / 2, H.sida, H.hojd, H.sida, IDFARG.huv, Enum.Material.Metal)
		BK.box(model, base, "Huvhatt " .. i, cx - H.hattB / 2, b.hN + 0.62,
			z - H.hattB / 2, H.hattB, 0.09, H.hattB, IDFARG.huv, Enum.Material.Metal)
	end

	-- Snörasskyddet på båda takfallen, en tredjedel upp.
	local N = I.snorasskydd
	local halv, res = r.w / 2, b.hN - b.hV
	for _, sida in ipairs({ -1, 1 }) do
		local px = cx + sida * halv * N.andelUt
		local py = b.hV + res * N.andelUpp
		BK.box(model, base, "Snörasskydd " .. (if sida < 0 then "väst" else "öst"),
			px - 0.03, py + 0.14, r.y + 0.6, 0.06, 0.06, r.h - 1.2,
			IDFARG.svart, Enum.Material.Metal)
	end

	-- Förstukvisten på västra långsidan. u mäts från norra gaveln söderut.
	--[[ Förstukvisten sitter på NORRA GAVELN och skjuter ut mot grusplanen.

		Den låg på västra långsidan till 2026-09-02, då produktägaren bytte
		plats på verandan och gavelns enkla skärmtaksdörr. Spegelvänt mot
		förut: den sträcker sig nu längs x och skjuter ut i +z, i stället för
		tvärtom. `uFranOst` mäts från östra gavelhörnet, samma konvention som
		öppningarnas u på N-sidan. ]]
	local K = I.forstukvist
	local kx = r.x + r.w - K.uFranOst          -- verandans mitt längs gaveln
	local kn = r.y + r.h                       -- gavelns yttervägg
	BK.box(model, base, "Förstukvist golv", kx - K.bredd / 2, 0, kn,
		K.bredd, 0.14, K.djup, IDFARG.betong, Enum.Material.Concrete)
	BK.box(model, base, "Förstukvist tak", kx - K.bredd / 2 - 0.2, K.takfot, kn,
		K.bredd + 0.4, 0.12, K.djup + 0.2,
		b.fargT or IDFARG.huv, Enum.Material.Metal)
	for _, sida in ipairs({ -1, 1 }) do
		BK.box(model, base, "Förstukvist stolpe",
			kx + sida * (K.bredd / 2 - 0.2), 0, kn + K.djup - 0.25,
			0.15, K.takfot, 0.15, IDFARG.vit, Enum.Material.WoodPlanks)
	end
	-- Ribbräcket, med öppningen mitt för dörren. Spegelvänt med verandan:
	-- löper längs x vid gavelns yttre kant i stället för längs z.
	local sido = (K.bredd - 0.34 - K.oppning) / 2
	for _, sida in ipairs({ -1, 1 }) do
		BK.box(model, base, "Förstukvist räcke",
			kx + sida * (K.oppning / 2 + sido / 2) - sido / 2, 0.26,
			kn + K.djup - 0.21,
			sido, 1.2, 0.06, IDFARG.vit, Enum.Material.WoodPlanks)
	end

	-- Balkongen och spiraltrappan på klubbgaveln i norr.
	local BA, SP = I.balkong, I.spiraltrappa
	local gm = r.x + r.w / 2
	BK.box(model, base, "Balkong", gm - BA.bredd / 2, BA.z - 0.12,
		r.y + r.h, BA.bredd, 0.12, BA.djup, IDFARG.trappa, Enum.Material.Metal)
	BK.box(model, base, "Balkongräcke", gm - BA.bredd / 2, BA.z,
		r.y + r.h + BA.djup - 0.06, BA.bredd, BA.rackeH, 0.06,
		IDFARG.svart, Enum.Material.Metal)

	local sx = gm + SP.franGavelmitt
	BK.box(model, base, "Spiraltrappa spindel", sx - 0.09, 0, r.y + r.h + 0.53,
		0.18, BA.z + 0.5, 0.18, IDFARG.svart, Enum.Material.Metal)
	for i = 1, SP.steg do
		local vinkel = (i - 1) * 0.40
		BK.box(model, base, "Spiraltrappsteg " .. i,
			sx + math.cos(vinkel) * SP.radie / 2 - SP.radie / 2,
			BA.z * i / SP.steg,
			r.y + r.h + 0.62 + math.sin(vinkel) * SP.radie / 2 - 0.15,
			SP.radie, 0.05, 0.30, IDFARG.trappa, Enum.Material.Metal)
	end
end

local function byggRidhusIdentitet(model: Model, base: CFrame)
	local R, I = G.ridhus, G.identitet.ridhus
	local o = R.origo

	--[[ DEN ROSTBRUNA ÖVRE LÅNGVÄGGEN.

		`KNOWN MISMATCH`, rättad: Roblox byggde den på BÅDA långsidorna i
		nästan hela hallens längd. Det verifierade är motsatsen —
		`ridhus-inne-02` visar den på EN DEL av EN långsida, och resten av
		samma vägg är ljus. Webben har läst `ovreVagg.sida/y0/y1` sedan
		Review 03; Roblox gjorde det inte, och det var en av de tydligaste
		Roblox-only sanningarna som fanns kvar.

		Sidan kommer ur `sidor.panel` via `ovreVagg.sida`, så en framtida
		spegling flyttar väggen på båda ytorna samtidigt.

		Färgen läser den MÄTTA `R.panel` (#765B59 ur en färgmask på -02), inte
		IDFARG.panel — den senare var det gamla mättade rödlila. ]]
	local O = I.ovreVagg
	local y0, y1 = R.sargH + O.overSarg, R.tak - O.underTak
	local px = if O.sida == "W" then 0.16 else R.bredd - 0.16
	local pL = O.y1 - O.y0
	BK.box(model, base, "Övre långvägg", o.x + px - O.tjocklek / 2, y0,
		o.y + O.y0, O.tjocklek, y1 - y0, pL,
		R.panel or IDFARG.panel, Enum.Material.Metal)
	for i = 1, O.listar do
		local yy = y0 + 0.25 + (y1 - y0 - 0.5)
			* (if O.listar > 1 then (i - 1) / (O.listar - 1) else 0.5)
		BK.box(model, base, "Väggläkt", o.x + px - 0.05, yy, o.y + O.y0,
			0.10, 0.07, pL, R.panelList or IDFARG.list,
			Enum.Material.SmoothPlastic)
	end

	--[[ FÖNSTERBANDET byggs redan i byggRidhusInre. SPONSORSKYLTARNA byggdes
		INTE alls i Roblox — de fanns bara i webben. De hänger på panelen, i
		den ordning ridhus-inne-02 visar dem, och deras läge härleds ur
		panelens stycke i den delade datan. Förenklad grafik är i sin
		ordning; fel antal eller fel ordning är det inte. ]]
	local inat = if O.sida == "W" then 1 else -1
	for i, sk in ipairs(R.skyltar or {}) do
		local skylt = BK.box(model, base, "Sponsorskylt " .. i,
			o.x + px + inat * 0.06, y0 + (y1 - y0) * 0.30,
			o.y + sk.y - sk.b / 2, 0.05, 0.62, sk.b,
			sk.bg or Color3.fromRGB(242, 237, 226), Enum.Material.SmoothPlastic)
		skylt.CanCollide = false
		skylt:SetAttribute("Text", sk.text)
	end

	--[[ TAKSTOMMEN OCH UNDERTAKET.

		Roblox byggde stål, kabelstegar och ventilation men varken trästomme
		eller undertak — de talen fanns bara som literaler inne i webbens
		v3dRidhus. Review 10 har rätt i att en andra geometrisanning inte ska
		handkopieras hit: fakta ligger nu i `R.takstomme` och `R.takfarg`, och
		båda ytorna läser dem.

		Färgerna är MÄTTA: ridhusets takstolar är mörkt gråbruna och nästan
		neutrala, INTE varmt limträ som stallets. ]]
	local TS, TF = R.takstomme, R.takfarg
	if TS and TF then
		local halvS = R.bredd / 2
		local takL = math.sqrt(halvS ^ 2 + TS.resning ^ 2)
		local takV = math.atan2(TS.resning, halvS)
		for _, sida in ipairs({ -1, 1 }) do
			local fall = Instance.new("Part")
			fall.Name = "Ridhus takfall"; fall.Anchored = true
			fall.CanCollide = false
			fall.Color = TF.plat; fall.Material = Enum.Material.Metal
			fall.Size = Vector3.new(BK.M * takL, BK.M * TS.platT,
				BK.M * (R.langd + 0.6))
			fall.CFrame = base
				* CFrame.new(BK.M * (o.x + halvS + sida * halvS / 2),
					BK.M * (R.tak + TS.resning / 2),
					BK.M * (o.y + R.langd / 2))
				* CFrame.Angles(0, 0, -sida * takV)
			fall.Parent = model
		end
		local z = TS.start
		while z < R.langd do
			BK.box(model, base, "Ridhus takbalk", o.x, R.tak - 0.2 - TS.balkH / 2,
				o.y + z - TS.balkD / 2, R.bredd, TS.balkH, TS.balkD,
				TF.balk, Enum.Material.Wood).CanCollide = false
			BK.box(model, base, "Ridhus kungstolpe",
				o.x + halvS - TS.kungB / 2, R.tak - 0.05,
				o.y + z - TS.kungB / 2, TS.kungB, TS.kungH, TS.kungB,
				TF.balk, Enum.Material.Wood).CanCollide = false
			z += TS.delning
		end
	end

	-- MOTSÄGELSE 3: takets stål, kabelstegar och ventilation.
	local P = I.takProfiler
	for i, a in ipairs(P.andelar) do
		BK.box(model, base, "Stålprofil " .. i, o.x + R.bredd * a - P.b / 2,
			R.tak - P.underTak - P.h, o.y + 0.5, P.b, P.h, R.langd - 1,
			IDFARG.stal, Enum.Material.Metal)
	end

	local K = I.kabelstegar
	for i, a in ipairs(K.andelar) do
		local x = o.x + R.bredd * a
		for _, d in ipairs({ -K.bredd / 2, K.bredd / 2 - 0.05 }) do
			BK.box(model, base, "Kabelstege " .. i, x + d, R.tak - K.underTak,
				o.y + 1, 0.05, 0.16, R.langd - 2, IDFARG.kabel, Enum.Material.Metal)
		end
		-- Stegpinnarna. Utan dem läser stegen som ännu en balk.
		local z = 2
		while z < R.langd - 2 do
			BK.box(model, base, "Stegpinne", x - K.bredd / 2, R.tak - K.underTak,
				o.y + z, K.bredd, 0.03, 0.05, IDFARG.kabel, Enum.Material.Metal)
			z += K.pinnDelning
		end
	end

	local V = I.ventkanaler
	for i, a in ipairs(V.andelar) do
		local x = o.x + R.bredd * a
		BK.box(model, base, "Ventkanal " .. i, x - V.radie, R.tak - V.underTak - V.radie,
			o.y + 1.5, V.radie * 2, V.radie * 2, R.langd - 3,
			IDFARG.vent, Enum.Material.Metal)
		local z = 5
		while z < R.langd - 4 do
			BK.box(model, base, "Ventdon", x - 0.16, R.tak - V.underTak - 0.63,
				o.y + z - 0.16, 0.32, 0.42, 0.32, IDFARG.vent, Enum.Material.Metal)
			z += V.donDelning
		end
	end
end

-- Staketen runt banorna och hagarna. Sträckorna kommer ur G.staket, måtten
-- ur G.banomrade.staket. Trästaketet har TRE reglar — mätt i
-- references/omnejd/banan-03. Webben ritade tidigare två, och Roblox ritade
-- inga alls: uteridbanan stod helt utan inhägnad på primärplattformen.
--
-- Alla sträckor i src/site.js är axelparallella, så box räcker. Skulle en
-- diagonal sträcka läggas till måste den här funktionen byggas om.
local STAKETFARG: { [string]: { regel: Color3, stolpe: Color3 } } = {
	tra  = { regel = Color3.fromRGB(176, 161, 132), stolpe = Color3.fromRGB(138, 122, 94) },
	rail = { regel = Color3.fromRGB(122, 46, 40),  stolpe = Color3.fromRGB(106, 40, 34) },
	el   = { regel = Color3.fromRGB(140, 133, 120), stolpe = Color3.fromRGB(110, 106, 94) },
}

--[[ STAKETENS SOLIDA BITAR — grindöppningarna bortsubtraherade.

     Motsvarigheten till `staketSegment()` i src/site.js, och den finns
     av samma skäl: en grind som bara är en markör är ingen grind.
     Tobias produkttest 2026-09-06 fällde webben på precis det, och en
     rättelse som bara gällde webben hade lämnat Roblox med slutna
     hagar — paritetsregeln säger att spelvärlden ska motsvara sig
     själv på båda ytorna.

     Grinden anges som en punkt på staketlinjen plus en bredd; punkten
     projiceras på det segment den ligger på och segmentet delas. ]]
local function staketSegment(st): { { number } }
	local ut = {}
	for i = 1, #st.p - 1 do
		local x0, y0 = st.p[i][1], st.p[i][2]
		local x1, y1 = st.p[i + 1][1], st.p[i + 1][2]
		local dx, dy = x1 - x0, y1 - y0
		local L = math.sqrt(dx * dx + dy * dy)
		if L >= 1e-9 then
			local hal = {}
			for _, g in ipairs((st :: any).grindar or {}) do
				local t = ((g.p[1] - x0) * dx + (g.p[2] - y0) * dy) / (L * L)
				if t >= 0 and t <= 1 then
					local px, py = x0 + dx * t, y0 + dy * t
					--[[ Punkten måste ligga PÅ linjen, inte bara projiceras
					     på den — annars öppnar en grind på en annan sida
					     fel sträcka. ]]
					if math.sqrt((px - g.p[1]) ^ 2 + (py - g.p[2]) ^ 2) <= 0.35 then
						local halv = (g.bredd or 2.0) / 2 / L
						table.insert(hal, { math.max(0, t - halv), math.min(1, t + halv) })
					end
				end
			end
			table.sort(hal, function(a, b) return a[1] < b[1] end)
			local t0 = 0
			for _, h in ipairs(hal) do
				if h[1] > t0 then
					table.insert(ut, { x0 + dx * t0, y0 + dy * t0, x0 + dx * h[1], y0 + dy * h[1] })
				end
				t0 = math.max(t0, h[2])
			end
			if t0 < 1 then
				table.insert(ut, { x0 + dx * t0, y0 + dy * t0, x1, y1 })
			end
		end
	end
	return ut
end

local function byggStaket(model: Model, base: CFrame)
	local S = G.banomrade.staket
	for _, st in ipairs(G.staket) do
		local farg = STAKETFARG[st.typ] or STAKETFARG.tra
		-- Trästaketet vid banan är inte en stapel likadana reglar: EN kraftig
		-- toppregel, eltråd på svarta isolatorer under, och där staketet
		-- omsluter sand en grov syll i marknivå som håller sanden. Mätt i
		-- references/omnejd/banan-01. Rail och el är enklare.
		local reglar, stolpH, delning, tj
		if st.typ == "tra" then
			reglar, stolpH, delning, tj = {}, S.stolpH, S.stolpDelning, S.stolpTvarsnitt
		elseif st.typ == "rail" then
			reglar, stolpH, delning, tj = { 0.38, 0.80 }, 0.85, 3.0, 0.12
		else
			reglar, stolpH, delning, tj = { 0.70, 1.05 }, 1.0, 6.0, 0.07
		end

		for _, bit in ipairs(staketSegment(st)) do
			local a, b = { bit[1], bit[2] }, { bit[3], bit[4] }
			local dx, dz = b[1] - a[1], b[2] - a[2]
			local len = math.sqrt(dx * dx + dz * dz)
			if len >= 0.01 then
				local langsX = math.abs(dx) >= math.abs(dz)
				local x0 = math.min(a[1], b[1])
				local z0 = math.min(a[2], b[2])

				-- Liggande virke: (namn, mitthöjd, höjd, djup, färg, material)
				local liggande = {}
				if st.typ == "tra" then
					local T = S.toppregel
					table.insert(liggande, { "Staketets toppregel", T.z, T.h, T.d,
						farg.regel, Enum.Material.WoodPlanks })
					if st.sandkant then
						local Y = S.sandsyll
						table.insert(liggande, { "Sandsyll", Y.z, Y.h, Y.d,
							Color3.fromRGB(156, 138, 110), Enum.Material.Wood })
					end
					for _, y in ipairs(S.tradar) do
						table.insert(liggande, { "Eltrad", y, S.tradTjocklek, S.tradTjocklek,
							Color3.fromRGB(58, 54, 46), Enum.Material.Metal })
					end
				else
					for _, y in ipairs(reglar) do
						table.insert(liggande, { "Staketregel " .. st.typ, y, 0.10, 0.05,
							farg.regel, Enum.Material.WoodPlanks })
					end
				end

				for _, L in ipairs(liggande) do
					local namn, y, hojd, djup = L[1], L[2], L[3], L[4]
					local w = if langsX then len else djup
					local d = if langsX then djup else len
					local px = if langsX then x0 else x0 - djup / 2
					local pz = if langsX then z0 - djup / 2 else z0
					local r = BK.box(model, base, namn,
						px, y - hojd / 2, pz, w, hojd, d, L[5], L[6])
					r.CanCollide = false
				end

				local n = math.max(1, math.floor(len / delning + 0.5))
				for k = 0, n do
					local t = k / n
					local sx = a[1] + dx * t - tj / 2
					local sz = a[2] + dz * t - tj / 2
					BK.box(model, base, "Staketstolpe " .. st.typ,
						sx, 0, sz, tj, stolpH, tj,
						farg.stolpe, Enum.Material.Wood)
					-- De svarta isolatorerna som bär eltråden.
					if st.typ == "tra" then
						for _, y in ipairs(S.tradar) do
							local iso = BK.box(model, base, "Isolator",
								sx + (tj - S.isolatorB) / 2, y - S.isolatorH / 2,
								sz + (tj - S.isolatorB) / 2,
								S.isolatorB, S.isolatorH, S.isolatorB,
								Color3.fromRGB(38, 36, 31), Enum.Material.SmoothPlastic)
							iso.CanCollide = false
						end
					end
				end
			end
		end
	end
end

-- Belysningsmasterna runt uteridbanan. Dubbel armatur på en tvärarm — se den
-- närmaste masten i references/omnejd/banan-03. Lägena står i G.props.
local function byggMaster(model: Model, base: CFrame)
	local MA = G.banomrade.mast
	for _, p in ipairs(G.props) do
		if p.typ == "mast" then
			local x, z = p.pos[1], p.pos[2]
			local d = MA.stamOver * 2
			BK.box(model, base, "Belysningsmast", x - d / 2, 0, z - d / 2,
				d, MA.hojd, d, Color3.fromRGB(140, 143, 146), Enum.Material.Metal)
			local arm = BK.box(model, base, "Mastarm", x - MA.armB / 2, MA.hojd,
				z - MA.armD / 2, MA.armB, MA.armH, MA.armD,
				Color3.fromRGB(140, 143, 146), Enum.Material.Metal)
			arm.CanCollide = false
			for _, dx in ipairs({ -MA.lampDelning / 2, MA.lampDelning / 2 }) do
				local lampa = BK.box(model, base, "Mastarmatur",
					x + dx - MA.lampB / 2, MA.hojd + MA.armH - MA.lampH,
					z - MA.lampD / 2, MA.lampB, MA.lampH, MA.lampD,
					Color3.fromRGB(58, 61, 64), Enum.Material.Metal)
				lampa.CanCollide = false
			end
		end
	end
end

local function byggDorrmarkorer(model: Model, base: CFrame)
	for _, d in ipairs(G.dorrar) do
		local p = BK.box(model, base, "Dörr " .. d.id,
			d.pos[1] - 0.5, 0, d.pos[2] - 0.5, 1, 0.1, 1,
			Color3.fromRGB(240, 210, 90), Enum.Material.Neon)
		p.CanCollide = false
		p:SetAttribute("Mot", d.mot)
		p:SetAttribute("Text", d.text)
	end
end

--[[ ══ INSIDORNA ═════════════════════════════════════════════════════════

	Review 02: att datan finns i den generade modulen räcker inte om byggaren
	struntar i den. Fyra boxrader och två gångar ska gå att SE i Roblox, inte
	bara stå i en tabell.

	Det som byggs är Gate F01:s STRUKTUR — planformen, gångarna, tvärkorridoren,
	de namngivna rummen, ridbanan, läktaren. Inte möblering: ingen spånremsa,
	inga namnskyltar, inga hinder. Det är rendering och hör inte till en
	fidelity-gate.

	Interiörernas lokalkoordinater sitter i husets sydvästra hörn. Offseten
	kommer ur exporten (G.stall.origo) och räknas inte om här. ]]

local INRE = {
	golv    = Color3.fromRGB(140, 136, 128),
	gang    = Color3.fromRGB(154, 150, 142),
	vagg    = Color3.fromRGB(207, 200, 188),
	box     = Color3.fromRGB(126, 96, 66),
	front   = Color3.fromRGB(150, 150, 155),
	sand    = Color3.fromRGB(206, 186, 148),
	sarg    = Color3.fromRGB(228, 226, 218),
	laktare = Color3.fromRGB(112, 84, 60),
	glas    = Color3.fromRGB(170, 205, 225),
	rum     = Color3.fromRGB(186, 180, 170),
}

--[[ Väggar och rum ur ett planblock (stallets klubbdel, ridhusets entrédel).

	Blocket är samma tabell som webben kolliderar mot (STALLINNE.klubb,
	RIDHUSINNE.entrehall i src/site.js): väggar som segment med planens
	öppningar, rum som gångbara rektanglar. Bitarna mellan öppningarna kommer
	ur Geometri.vaggBitar — samma regel som src/world.js klubbVaggBitar — så
	att en dörr som finns i spelet finns i Roblox och en som saknas saknas på
	båda ställena.

	Rum som är `stangt` (inget läsbart dörrhål på planen) byggs som hela,
	halvgenomskinliga volymer: man ska se att de finns men inte gå in.
	Namngivna gångbara rum får en tunn, okolliderande etikettplatta med
	namnet som attribut, så att Studio kan visa vad som är vad utan att
	något solitt tillkommer. Rum med tom etikett (`label = ""`) är avsiktligt
	namnlösa — funktion REFERENCE GAP — och får ingen platta alls; webben
	ritar heller ingen text för dem. Tom sträng är sann i Luau, därför
	prövas längden uttryckligen. ]]
--[[ Spatial Canon v2 — provenance på varje vägg/glas/sluten volym i de
	omtvistade ytorna: Primitiv (WALL/GLASS), CanonId, SourceId, Confidence.
	Samma fält som webben läser ur src/site.js; bygge.spec kräver att de
	finns (SCV2-02) och att de matchar datan (SCV2-05). ]]
local function kanonAttribut(p, v)
	if v.primitiv then p:SetAttribute("Primitiv", v.primitiv) end
	if v.canon_id then p:SetAttribute("CanonId", v.canon_id) end
	if v.source_id then p:SetAttribute("SourceId", v.source_id) end
	if v.confidence then p:SetAttribute("Confidence", v.confidence) end
end

local function byggVaggarOchRum(model: Model, base: CFrame, o, h: number, K, prefix: string, farg: Color3)
	for _, v in ipairs(K.vaggar) do
		local t = v.tjock or 0.16
		local mat = if v.brand then Enum.Material.Concrete else Enum.Material.Plaster
		for j, bit in ipairs(GEO.vaggBitar(v)) do
			local namn = prefix .. " " .. v.id .. ":" .. j
			--[[ Spatial Canon v2: GLASS är en låg bröstning med en glasruta
			     över; WALL är hel. Båda bär provenance-attributen. ]]
			local glas = v.primitiv == "GLASS"
			local bh = if glas then (v.brostning or 0.95) else h
			local p
			if v.typ == "tvar" then
				p = BK.box(model, base, namn,
					o.x + bit.a0, 0, o.y + v.y - t / 2, bit.a1 - bit.a0, bh, t, farg, mat)
			else
				p = BK.box(model, base, namn,
					o.x + v.x - t / 2, 0, o.y + bit.a0, t, bh, bit.a1 - bit.a0, farg, mat)
			end
			--[[ Inomhusläsbarhet: klientens Genomsikt tonar den här biten när
			     den står mellan kameran och karaktären. Samma regel som webben. ]]
			p:SetAttribute("Genomsiktlig", true)
			kanonAttribut(p, v)
			if glas then
				local g
				if v.typ == "tvar" then
					g = BK.box(model, base, namn .. " glas",
						o.x + bit.a0, bh, o.y + v.y - 0.02, bit.a1 - bit.a0, h - bh, 0.04,
						Color3.fromRGB(191, 211, 220), Enum.Material.Glass)
				else
					g = BK.box(model, base, namn .. " glas",
						o.x + v.x - 0.02, bh, o.y + bit.a0, 0.04, h - bh, bit.a1 - bit.a0,
						Color3.fromRGB(191, 211, 220), Enum.Material.Glass)
				end
				g.Transparency = 0.55
				-- glaset tonas som en väggbit när det står mellan kamera och karaktär
				g:SetAttribute("Genomsiktlig", true)
				kanonAttribut(g, v)
				--[[ Avställningshyllan ovanpå disken mot gången och vita
					karmposter som delar glaset i rutor (ridhus-klubb-02). ]]
				if v.hylla then
					local V = Color3.fromRGB(238, 238, 232)
					local function gs(q) q.CanCollide = false; q:SetAttribute("Genomsiktlig", true); return q end
					local L2 = bit.a1 - bit.a0
					local n = math.max(1, math.floor(L2 / 0.85 + 0.5))
					if v.typ == "tvar" then
						gs(BK.box(model, base, "Glasdisk " .. v.id .. " hylla", o.x + bit.a0, bh, o.y + v.y - t / 2, L2, 0.05, v.hylla + t,
							Color3.fromRGB(242, 240, 234), Enum.Material.SmoothPlastic))
						for i = 0, n do
							local a = math.clamp(bit.a0 + L2 * i / n, bit.a0 + 0.04, bit.a1 - 0.04)
							gs(BK.box(model, base, "Glasdisk " .. v.id .. " karmpost", o.x + a - 0.04, bh, o.y + v.y - t / 2 - 0.01, 0.08, h - bh, t + 0.02, V, Enum.Material.SmoothPlastic))
						end
						gs(BK.box(model, base, "Glasdisk " .. v.id .. " karmöverstycke", o.x + bit.a0, h - 0.08, o.y + v.y - t / 2 - 0.01, L2, 0.08, t + 0.02, V, Enum.Material.SmoothPlastic))
					else
						gs(BK.box(model, base, "Glasdisk " .. v.id .. " hylla", o.x + v.x - t / 2, bh, o.y + bit.a0, v.hylla + t, 0.05, L2,
							Color3.fromRGB(242, 240, 234), Enum.Material.SmoothPlastic))
						for i = 0, n do
							local a = math.clamp(bit.a0 + L2 * i / n, bit.a0 + 0.04, bit.a1 - 0.04)
							gs(BK.box(model, base, "Glasdisk " .. v.id .. " karmpost", o.x + v.x - t / 2 - 0.01, bh, o.y + a - 0.04, t + 0.02, h - bh, 0.08, V, Enum.Material.SmoothPlastic))
						end
						gs(BK.box(model, base, "Glasdisk " .. v.id .. " karmöverstycke", o.x + v.x - t / 2 - 0.01, h - 0.08, o.y + bit.a0, t + 0.02, 0.08, L2, V, Enum.Material.SmoothPlastic))
					end
				end
			end
		end
		--[[ DÖRRARNA (PO 2026-09-04 07:54, blocker 4): varje öppning får ett
			ÖVERSTYCKE (vägg ovanför dörrhöjden) och en vit KARM med mörk smyg
			och tröskel — ridhus-klubb-03/-19, stall-inne-03. Dörrhöjd 2,1 m om
			öppningen inte anger `h`. Samma regel som webbens v3dVaggarOchRum. ]]
		for _, op in ipairs(v.oppningar or {}) do
			local q0 = if v.typ == "tvar" then op.x0 else op.y0
			local q1 = if v.typ == "tvar" then op.x1 else op.y1
			local dh = op.h or 2.1
			if q1 - q0 >= 0.3 and dh < h - 0.05 then
				local Lo, mo = q1 - q0, (q0 + q1) / 2
				local K1, K2 = Color3.fromRGB(238, 238, 232), Color3.fromRGB(140, 135, 123)
				local tj, dj = 0.10, t + 0.06
				local namnO = "Dörrkarm " .. v.id .. " " .. (op.id or "")
				local function del(suffix, x, y, z, w, hh, d, farg, kollid)
					local q = BK.box(model, base, namnO .. suffix, x, y, z, w, hh, d, farg, Enum.Material.SmoothPlastic)
					q.CanCollide = kollid == true
					q:SetAttribute("Genomsiktlig", true)
					kanonAttribut(q, v)
					return q
				end
				if v.typ == "tvar" then
					local ov = BK.box(model, base, "Överstycke " .. v.id .. " " .. (op.id or ""), o.x + q0, dh, o.y + v.y - t / 2, Lo, h - dh, t, farg, mat)
					ov:SetAttribute("Genomsiktlig", true); kanonAttribut(ov, v)
					del(" foder V", o.x + q0 - tj, 0, o.y + v.y - dj / 2, tj, dh + tj, dj, K1)
					del(" foder H", o.x + q1, 0, o.y + v.y - dj / 2, tj, dh + tj, dj, K1)
					del(" foder topp", o.x + q0 - tj, dh, o.y + v.y - dj / 2, Lo + 2 * tj, tj, dj, K1)
					del(" smyg V", o.x + q0, 0, o.y + v.y - (t - 0.01) / 2, 0.03, dh, t - 0.01, K2)
					del(" smyg H", o.x + q1 - 0.03, 0, o.y + v.y - (t - 0.01) / 2, 0.03, dh, t - 0.01, K2)
					del(" smyg topp", o.x + q0, dh - 0.03, o.y + v.y - (t - 0.01) / 2, Lo, 0.03, t - 0.01, K2)
					del(" tröskel", o.x + q0, 0, o.y + v.y - dj / 2, Lo, 0.02, dj, Color3.fromRGB(90, 86, 80))
				else
					local ov = BK.box(model, base, "Överstycke " .. v.id .. " " .. (op.id or ""), o.x + v.x - t / 2, dh, o.y + q0, t, h - dh, Lo, farg, mat)
					ov:SetAttribute("Genomsiktlig", true); kanonAttribut(ov, v)
					del(" foder V", o.x + v.x - dj / 2, 0, o.y + q0 - tj, dj, dh + tj, tj, K1)
					del(" foder H", o.x + v.x - dj / 2, 0, o.y + q1, dj, dh + tj, tj, K1)
					del(" foder topp", o.x + v.x - dj / 2, dh, o.y + q0 - tj, dj, tj, Lo + 2 * tj, K1)
					del(" smyg V", o.x + v.x - (t - 0.01) / 2, 0, o.y + q0, t - 0.01, dh, 0.03, K2)
					del(" smyg H", o.x + v.x - (t - 0.01) / 2, 0, o.y + q1 - 0.03, t - 0.01, dh, 0.03, K2)
					del(" smyg topp", o.x + v.x - (t - 0.01) / 2, dh - 0.03, o.y + q0, t - 0.01, 0.03, Lo, K2)
					del(" tröskel", o.x + v.x - dj / 2, 0, o.y + q0, dj, 0.02, Lo, Color3.fromRGB(90, 86, 80))
				end
			end
		end
	end
	for _, r in ipairs(K.rum or {}) do
		local q = r.rekt
		if r.stangt then
			local p = BK.box(model, base, "Slutet rum " .. r.id,
				o.x + q.x, 0, o.y + q.y, q.w, h * 0.9, q.h, INRE.rum, Enum.Material.Plaster)
			p.Transparency = 0.45
			p:SetAttribute("Rum", r.id)
			p:SetAttribute("Genomsiktlig", true)
			kanonAttribut(p, r)
		elseif r.label ~= nil and r.label ~= "" then
			local p = BK.box(model, base, "Rumsetikett " .. r.label,
				o.x + q.x, 0.03, o.y + q.y, q.w, 0.02, q.h, INRE.rum, Enum.Material.SmoothPlastic)
			p.CanCollide = false
			p.Transparency = 0.6
			p:SetAttribute("Rum", r.id)
			p:SetAttribute("Text", r.label)
		end
	end
end

--[[ INREDNINGEN (F02-B) ur G.inredning — samma lista som webben ritar och
	kolliderar mot (src/inredning.js). Varje post bär källa och klass, och
	de följer med som attribut så att Studio kan visa varifrån en soffa
	kommer. Byggt som lådor i objektets färg plus det som gör typen
	igenkännbar; renderingen får vara enklare än webbens, men VAR något
	står och hur stort det är är samma tal. Allt i listan är axelparallellt
	(rikt i kvartsvarv), så BK.box räcker. ]]
local function byggInredning(model: Model, base: CFrame, o, lista, prefix: string)
	for _, ob in ipairs(lista or {}) do
		local q = GEO.inredningRekt(ob)
		local z0 = ob.z0 or 0
		local namn = prefix .. " " .. ob.id
		-- Hög, opak inredning skymmer figuren som en vägg: Genomsiktlig (tonas
		-- av Genomsikt på klienten) — samma regel som webbens inredningHog.
		local hog = not (ob.typ == "lysror" or ob.typ == "exitskylt" or ob.typ == "ventkanal" or ob.typ == "spegel")
			and (z0 + ob.matt.h) >= 1.4 and ob.matt.d >= 0.3
		local function del(suffix: string, x, y, z, w, h, d, farg, mat, kollid: boolean?)
			local p = BK.box(model, base, namn .. suffix, x, y, z, w, h, d, farg, mat)
			p.CanCollide = if kollid == nil then (ob.kolliderar == true) else kollid
			if hog then p:SetAttribute("Genomsiktlig", true) end
			p:SetAttribute("Inredning", ob.id)
			p:SetAttribute("Rum", ob.rum)
			p:SetAttribute("Klass", ob.klass)
			p:SetAttribute("Kalla", ob.kalla)
            if ob.ytmaterial then p:SetAttribute("Ytmaterial", ob.ytmaterial) end
            return p
		end
		local f, f2 = ob.farg, ob.farg2 or Color3.fromRGB(107, 107, 107)
        local ytmaterial = if ob.ytmaterial == "Leather" then Enum.Material.SmoothPlastic else Enum.Material.Fabric
		local X, Y, W, H = o.x + q.x, o.y + q.y, q.w, q.h
		local typ = ob.typ
		if typ == "soffa" or typ == "fatolj" then
			del("", X, z0, Y, W, 0.42, H, f, ytmaterial)
			-- ryggen ligger på baksidan: motsatt `rikt`
			local dx = -math.cos(ob.rikt) * (q.w / 2 - 0.11) * (if math.abs(math.cos(ob.rikt)) > 0.5 then 1 else 0)
			local dy = -math.sin(ob.rikt) * (q.h / 2 - 0.11) * (if math.abs(math.sin(ob.rikt)) > 0.5 then 1 else 0)
			local rw = if math.abs(math.cos(ob.rikt)) > 0.5 then 0.22 else W
			local rh = if math.abs(math.cos(ob.rikt)) > 0.5 then H else 0.22
			del(" rygg", X + W / 2 + dx - rw / 2, z0 + 0.42, Y + H / 2 + dy - rh / 2, rw, ob.matt.h - 0.42, rh, f, ytmaterial)
		elseif typ == "bord" then
			local tj = if ob.detaljer then ob.detaljer.skivaTjocklek or 0.05 else 0.05
			del(" skiva", X, z0 + ob.matt.h - tj, Y, W, tj, H, f, Enum.Material.Wood)
			for _, bx in ipairs({ X + 0.045, X + W - 0.09 }) do
				for _, by in ipairs({ Y + 0.045, Y + H - 0.09 }) do
					del(" ben", bx, z0, by, 0.045, ob.matt.h - tj, 0.045, f2, Enum.Material.Wood, false)
				end
			end
		elseif typ == "stol" then
			del(" sits", X, z0 + 0.45, Y, W, 0.05, H, f, Enum.Material.SmoothPlastic)
			for _, bx in ipairs({ X + 0.02, X + W - 0.055 }) do
				for _, by in ipairs({ Y + 0.02, Y + H - 0.055 }) do
					del(" ben", bx, z0, by, 0.035, 0.45, 0.035, f2, Enum.Material.Wood, false)
				end
			end
			del(" rygg ram vänster", X + 0.02, z0 + 0.45, Y + 0.015, 0.045, ob.matt.h - 0.45, 0.045, f2, Enum.Material.Wood, false)
			del(" rygg ram höger", X + W - 0.065, z0 + 0.45, Y + 0.015, 0.045, ob.matt.h - 0.45, 0.045, f2, Enum.Material.Wood, false)
			for i = 1, ((ob.detaljer and ob.detaljer.ryggSpjalor) or 2) do
				del(" rygg spjäla " .. i, X + W * 0.14, z0 + 0.49 + (ob.matt.h - 0.54) * i / 3, Y + 0.015,
					W * 0.72, 0.035, 0.04, f, Enum.Material.SmoothPlastic, false)
			end
		elseif typ == "ponny" then
			del(" kropp", X + W / 2 - 0.21, z0 + 0.8, Y + H / 2 - 0.5, 0.42, 0.45, 1.0, f, Enum.Material.SmoothPlastic)
			del(" hals", X + W / 2 - 0.10, z0 + 1.0, Y + H / 2 + 0.35, 0.20, 0.55, 0.32, f, Enum.Material.SmoothPlastic)
			del(" sadel", X + W / 2 - 0.20, z0 + 1.25, Y + H / 2 - 0.25, 0.40, 0.12, 0.42, f2, Enum.Material.Fabric, false)
			del(" ben", X + W / 2 - 0.04, z0, Y + H / 2 - 0.04, 0.08, 0.8, 0.08, f, Enum.Material.SmoothPlastic, false)
		elseif typ == "klocka" then
			del("", X, z0, Y, W, ob.matt.h, H, f, Enum.Material.SmoothPlastic, false)
		elseif typ == "vaxt" then
			del(" kruka", X + W / 2 - 0.2, z0, Y + H / 2 - 0.2, 0.4, 0.35, 0.4, f2, Enum.Material.SmoothPlastic)
			del(" krona", X, z0 + ob.matt.h * 0.45, Y, W, ob.matt.h * 0.55, H, f, Enum.Material.Grass, false)
		elseif typ == "tavlor" then
			del("", X, z0, Y, W, ob.matt.h, H, f,
				Enum.Material.SmoothPlastic, false)
			local D = ob.detaljer or {}
			local langsX = math.abs(math.sin(ob.rikt)) > 0.5
			local front = if langsX
				then Y + (if math.sin(ob.rikt) > 0 then H else -0.015)
				else X + (if math.cos(ob.rikt) > 0 then W else -0.015)
			local function mark(suffix, u, low, ww, hh, color)
				if langsX then
					del(suffix, X + u, z0 + low, front, ww, hh, 0.015, color, Enum.Material.SmoothPlastic, false)
				else
					del(suffix, front, z0 + low, Y + u, 0.015, hh, ww, color, Enum.Material.SmoothPlastic, false)
				end
			end
			local langd = if langsX then W else H
			mark(" bildyta", langd * 0.08, ob.matt.h * 0.08, langd * 0.84, ob.matt.h * 0.84, f2)
			if D.motiv == "hastanatomi" then
				-- Grafiska anatomilager utan ord eller uppfunna etiketter.
				local a = if D.variant == 2 then Color3.fromRGB(140, 110, 90) else Color3.fromRGB(168, 111, 104)
				mark(" anatomi kropp", langd * 0.31, ob.matt.h * 0.48, langd * 0.34, ob.matt.h * 0.16, a)
				mark(" anatomi hals", langd * 0.62, ob.matt.h * 0.55, langd * 0.12, ob.matt.h * 0.13, a)
				mark(" anatomi huvud", langd * 0.76, ob.matt.h * 0.57, langd * 0.10, ob.matt.h * 0.07, a)
				mark(" anatomi svans", langd * 0.19, ob.matt.h * 0.50, langd * 0.13, ob.matt.h * 0.035, a)
				mark(" anatomi ben 1", langd * 0.38, ob.matt.h * 0.24, langd * 0.035, ob.matt.h * 0.25, a)
				mark(" anatomi ben 2", langd * 0.60, ob.matt.h * 0.24, langd * 0.035, ob.matt.h * 0.25, a)
				for i = 0, 3 do
					mark(" anatomi lager " .. i, langd * (0.28 + i * 0.15), ob.matt.h * 0.485,
						langd * 0.018, ob.matt.h * 0.13, Color3.fromRGB(210, 184, 168))
				end
			end
		elseif typ == "whiteboard" then
			del("", X, z0, Y, W, ob.matt.h, H, Color3.fromRGB(185, 189, 192), Enum.Material.Metal, false)
			local langsX = math.abs(math.sin(ob.rikt)) > 0.5
			local front = if langsX
				then Y + (if math.sin(ob.rikt) > 0 then H else -0.015)
				else X + (if math.cos(ob.rikt) > 0 then W else -0.015)
			if langsX then
				del(" skrivyta", X + 0.03, z0 + 0.03, front, W - 0.06, ob.matt.h - 0.06, 0.015, f, Enum.Material.SmoothPlastic, false)
				if ob.detaljer and ob.detaljer.hylla then
					del(" pennhylla", X + W * 0.04, z0 - 0.04, front, W * 0.92, 0.035, 0.08, Color3.fromRGB(174, 179, 181), Enum.Material.Metal, false)
				end
			else
				del(" skrivyta", front, z0 + 0.03, Y + 0.03, 0.015, ob.matt.h - 0.06, H - 0.06, f, Enum.Material.SmoothPlastic, false)
				if ob.detaljer and ob.detaljer.hylla then
					del(" pennhylla", front, z0 - 0.04, Y + H * 0.04, 0.08, 0.035, H * 0.92, Color3.fromRGB(174, 179, 181), Enum.Material.Metal, false)
				end
			end
			if ob.detaljer and ob.detaljer.arbetsmarken then
				local ink = if ob.detaljer.variant == 2 then Color3.fromRGB(101, 112, 90) else Color3.fromRGB(80, 106, 112)
				local langd = if langsX then W else H
				for i = 0, 5 do
					local ww = langd * (0.13 + ((i * 3 + (ob.detaljer.variant or 1)) % 5) * 0.055)
					local u = langd * 0.16 + (i % 2) * langd * 0.22
					if langsX then
						del(" arbetsmarkering " .. i, X + u, z0 + ob.matt.h * (0.18 + i * 0.105), front,
							ww, 0.018, 0.008, ink, Enum.Material.SmoothPlastic, false)
					else
						del(" arbetsmarkering " .. i, front, z0 + ob.matt.h * (0.18 + i * 0.105), Y + u,
							0.008, 0.018, ww, ink, Enum.Material.SmoothPlastic, false)
					end
				end
			end
		elseif typ == "exitskylt" then
			del("", X, z0, Y, W, ob.matt.h, H, f, Enum.Material.Neon, false)
		elseif typ == "lysror" then
			local D = ob.detaljer or {}
			if D.holje then del(" hölje", X, z0 + ob.matt.h * 0.3, Y, W, ob.matt.h * 0.7, H, Color3.fromRGB(216, 216, 211), Enum.Material.Metal, false) end
			del(" ljusyta", X + W * 0.06, z0, Y + H * 0.19, W * 0.88, ob.matt.h * 0.45, H * 0.62, f, Enum.Material.Neon, false)
			if D.upphangd then
				for _, u in ipairs({ 0.16, 0.82 }) do
					del(" vajer", X + W * u, z0 - 0.16, Y + H / 2 - 0.009, 0.018, 0.22, 0.018, Color3.fromRGB(119, 122, 123), Enum.Material.Metal, false)
				end
			end
		elseif typ == "dorr" then
			-- stängt dörrblad med karm, fönster och handtag PÅ en vägg (ingen passage)
			del(" karm", X - 0.10, 0, Y - 0.01, W + 0.20, ob.matt.h + 0.10, H + 0.02, Color3.fromRGB(238, 238, 232), Enum.Material.SmoothPlastic, false)
			del(" blad", X, 0, Y, W, ob.matt.h, H, f, Enum.Material.Metal, false)
			local g = del(" fönster", X + W * 0.29, ob.matt.h * 0.58, Y - 0.01, W * 0.42, ob.matt.h * 0.24, H + 0.02, f2, Enum.Material.Glass, false)
			g.Transparency = 0.4
		elseif typ == "spegel" then
			del(" ram", X, z0 - 0.06, Y, W, ob.matt.h + 0.12, H, f, Enum.Material.Wood, false)
			local gp = del(" glas", X, z0, Y, W, ob.matt.h, H, Color3.fromRGB(159, 179, 196), Enum.Material.Glass, false)
			gp.Reflectance = 0.6
		elseif typ == "ventkanal" then
			del("", X, z0, Y, W, ob.matt.h, H, f, Enum.Material.Metal, false)
			local D = ob.detaljer or {}
			if D.perforerad then
				local langsX = math.abs(math.sin(ob.rikt)) > 0.5
				local front = if langsX
					then Y + (if math.sin(ob.rikt) > 0 then H else -0.01)
					else X + (if math.cos(ob.rikt) > 0 then W else -0.01)
				local langd = if langsX then W else H
				for rad = 0, (D.halrader or 1) - 1 do
					for i = 0, 13 do
						local u = langd * (i + 0.5 + (rad % 2) * 0.25) / 14
						if langsX then
							del(" perforering", X + u, z0 + 0.055 + rad * 0.075, front, 0.045, 0.045, 0.01, Color3.fromRGB(95, 98, 100), Enum.Material.Metal, false)
						else
							del(" perforering", front, z0 + 0.055 + rad * 0.075, Y + u, 0.01, 0.045, 0.045, Color3.fromRGB(95, 98, 100), Enum.Material.Metal, false)
						end
					end
				end
			end
		elseif typ == "krokrad" then
			del(" skena", X, z0 + ob.matt.h - 0.05, Y, W, 0.05, H, f, Enum.Material.Metal, false)
			del(" vastar", X, z0, Y, W, ob.matt.h - 0.15, H, f2, Enum.Material.Fabric, false)
		elseif typ == "skapbank" then
			-- `vaningar` = luckor i två våningar (ridhus-klubb-16/-20), `ben` = kroppen på svarta ben (-20/-21).
			-- Ventilation byggs bara som familjens separata över-/sockelband, aldrig som ett gemensamt hålmönster.
			local ben = ob.ben or 0
			local kh = ob.matt.h - ben
			local v = ob.vaningar or 1
			del("", X, z0 + ben, Y, W, kh, H, f, Enum.Material.Metal)
			if ben > 0 then
				for _, bx in ipairs({ X + 0.03, X + W - 0.08 }) do
					for _, by in ipairs({ Y + 0.03, Y + H - 0.08 }) do
						del(" ben", bx, z0, by, 0.05, ben, 0.05, Color3.fromRGB(30, 30, 30), Enum.Material.Metal, false)
					end
				end
			end
			local D = ob.detaljer or {}
			local fargor = ob.fargor or { f }
			local n = D.kolumner or math.max(1, math.round(ob.matt.b / 0.4))
			local dh = (kh - 0.16) / v
			local langsX = math.abs(math.sin(ob.rikt)) > 0.5
			local fx = if math.cos(ob.rikt) > 0 then X + W else X - 0.01
			local fy = if math.sin(ob.rikt) > 0 then Y + H else Y - 0.01
			local langd = if langsX then W else H
			local w = langd / n
			-- u = längs fronten, inte världens X. Därmed fungerar samma
			-- beskrivning på båda sidor av gången och för alla fyra riktningar.
			local function front(suffix, u, low, ww, hh, dj, c, material)
				if langsX then
					return del(suffix, X + u, low, fy, ww, hh, dj, c, material, false)
				else
					return del(suffix, fx, low, Y + u, dj, hh, ww, c, material, false)
				end
			end
			for i = 0, n - 1 do
				local c = fargor[(i % #fargor) + 1]
				for j = 0, v - 1 do
					local zy = z0 + ben + 0.1 + j * dh
					local namn = " dorr " .. (i + 1) .. (if v > 1 then "-" .. (j + 1) else "")
					local u = i * w + 0.01
					front(namn, u, zy, w - 0.02, dh - 0.02, 0.01, c, Enum.Material.Metal)
					if D.ram then
						local rc = D.ramfarg or f
						for _, side in ipairs({ 0.002, w - 0.020 }) do
							front(namn .. " ram sida", u + side, zy, 0.018, dh, 0.018, rc, Enum.Material.Metal)
						end
						for _, low in ipairs({ zy, zy + dh - 0.018 }) do
							front(namn .. " ram tvär", u, low, w, 0.018, 0.018, rc, Enum.Material.Metal)
						end
					end
					if D.profil then
						local line = Color3.fromRGB(68, 73, 74)
						front(namn .. " profil neder", u + 0.015, zy + 0.04, w - 0.05, 0.008, 0.015, line, Enum.Material.Metal)
						for _, side in ipairs({ 0.016, w - 0.044 }) do
							front(namn .. " profil sida", u + side, zy + 0.045, 0.008, dh - 0.09, 0.015, line, Enum.Material.Metal)
						end
					end
					if D.beslag then
						front(namn .. " las", u + w * 0.75, zy + dh * 0.55, 0.055, 0.09, 0.025, Color3.fromRGB(142, 147, 149), Enum.Material.Metal)
						front(namn .. " nyckelhal", u + w * 0.765, zy + dh * 0.58, 0.018, 0.025, 0.03, Color3.fromRGB(52, 56, 59), Enum.Material.Metal)
						front(namn .. " nummerskylt", u + w * 0.13, zy + dh * 0.88, 0.035, 0.012, 0.02, Color3.fromRGB(217, 216, 209), Enum.Material.SmoothPlastic)
					end
					if D.ventilation then
						for k = 0, 2 do
							front(namn .. " ventilation " .. k, u + w * 0.285, zy + 0.035 + k * 0.025,
								w * 0.43, 0.008, 0.02, Color3.fromRGB(77, 81, 82), Enum.Material.Metal)
						end
					end
				end
			end
			if D.overkantVent then
				local hal = math.max(8, n * 4)
				for k = 0, hal - 1 do
					front(" overkantvent " .. k, langd * (0.04 + 0.92 * k / (hal - 1)),
						z0 + kh - 0.035, 0.018, 0.012, 0.022, Color3.fromRGB(77, 81, 82), Enum.Material.Metal)
				end
			end
			if D.sockelVent then
				local hal = math.max(8, n * 4)
				for k = 0, hal - 1 do
					front(" sockelvent " .. k, langd * (0.04 + 0.92 * k / (hal - 1)),
						z0 + ben + 0.025, 0.018, 0.012, 0.022, Color3.fromRGB(77, 81, 82), Enum.Material.Metal)
				end
			end
		elseif typ == "bommar" then
			local fargor = ob.fargor or { f }
			local n = ob.antal or 5
			for i = 0, n - 1 do
				local c = fargor[(i % #fargor) + 1]
				if math.abs(math.cos(ob.rikt)) > 0.5 then
					del(" bom " .. (i + 1), X + W / 2 - 0.04, z0, Y + (H / n) * (i + 0.5) - 0.04, 0.08, 1.9, 0.08, c, Enum.Material.SmoothPlastic, false)
				else
					del(" bom " .. (i + 1), X + (W / n) * (i + 0.5) - 0.04, z0, Y + H / 2 - 0.04, 0.08, 1.9, 0.08, c, Enum.Material.SmoothPlastic, false)
				end
			end
		elseif typ == "hinderstod" then
			local n = ob.antal or 3
			for i = 0, n - 1 do
				del(" stod " .. (i + 1), X + (W / n) * (i + 0.5) - 0.05, z0, Y + H / 2 - 0.05, 0.10, ob.matt.h, 0.10, f, Enum.Material.SmoothPlastic, false)
			end
		elseif typ == "bokstavsstall" then
			del(" hylla", X, z0 + 0.6, Y, W, 0.04, H, Color3.fromRGB(169, 143, 104), Enum.Material.Wood, false)
			del(" bokstaver", X, z0 + 0.64, Y, W, 0.28, H, f, Enum.Material.SmoothPlastic, false)
		elseif typ == "tunna" then
			del("", X, z0, Y, W, ob.matt.h, H, f, Enum.Material.Metal)
			del(" band", X - 0.005, z0 + ob.matt.h * 0.55, Y - 0.005, W + 0.01, 0.12, H + 0.01, f2, Enum.Material.SmoothPlastic, false)
		-- Zonen efter pausrummet (PO-referens stall-efter-pausrum-po-v1): samma tecknare som webben.
		elseif typ == "ror" then
			del("", X, z0, Y, W, ob.matt.h, H, f, Enum.Material.Metal, false)
		elseif typ == "brandslackare" then
			del("", X, z0, Y, W, ob.matt.h * 0.78, H, f, Enum.Material.Metal, false)
			del(" topp", X + W * 0.28, z0 + ob.matt.h * 0.78, Y + H * 0.28, W * 0.44, ob.matt.h * 0.22, H * 0.44, Color3.fromRGB(30, 30, 30), Enum.Material.Metal, false)
		elseif typ == "vask" then
			del("", X, z0, Y, W, ob.matt.h * 0.85, H, f, Enum.Material.Metal)
			del(" bänk", X, z0 + ob.matt.h * 0.85, Y, W, 0.05, H, f2, Enum.Material.Metal, false)
			del(" ho", X + W * 0.2, z0 + ob.matt.h * 0.85 + 0.05, Y + H * 0.2, W * 0.6, 0.02, H * 0.55, Color3.fromRGB(110, 114, 117), Enum.Material.Metal, false)
			if math.abs(math.cos(ob.rikt)) > 0.5 then
				del(" kran", X + (if math.cos(ob.rikt) > 0 then 0.06 else W - 0.10), z0 + ob.matt.h * 0.9, Y + H / 2 - 0.02, 0.04, 0.26, 0.04, f2, Enum.Material.Metal, false)
			else
				del(" kran", X + W / 2 - 0.02, z0 + ob.matt.h * 0.9, Y + (if math.sin(ob.rikt) > 0 then 0.06 else H - 0.10), 0.04, 0.26, 0.04, f2, Enum.Material.Metal, false)
			end
		elseif typ == "krokar" then
			del(" skena", X, z0 + ob.matt.h - 0.04, Y, W, 0.04, H, f, Enum.Material.Metal, false)
			del(" handduk", X + W * 0.6, z0, Y, 0.22, ob.matt.h - 0.12, H, f2, Enum.Material.Fabric, false)
		elseif typ == "racke" then
			local n = math.max(2, math.round(ob.matt.b / 1.3) + 1)
			local langs = math.abs(math.cos(ob.rikt)) > 0.5
			for i = 0, n - 1 do
				if langs then
					del(" stolpe " .. (i + 1), X + (W - 0.06) * i / (n - 1), z0, Y + H / 2 - 0.03, 0.06, ob.matt.h, 0.06, f, Enum.Material.Metal)
				else
					del(" stolpe " .. (i + 1), X + W / 2 - 0.03, z0, Y + (H - 0.06) * i / (n - 1), 0.06, ob.matt.h, 0.06, f, Enum.Material.Metal)
				end
			end
			for _, hz in ipairs({ ob.matt.h * 0.55, ob.matt.h * 0.96 }) do
				if langs then
					del(" regel", X, z0 + hz - 0.02, Y + H / 2 - 0.02, W, 0.04, 0.04, f2, Enum.Material.Metal, false)
				else
					del(" regel", X + W / 2 - 0.02, z0 + hz - 0.02, Y, 0.04, 0.04, H, f2, Enum.Material.Metal, false)
				end
			end
		else
			-- skap, kartong, bank, stovelhylla och allt annat: en låda i färgen
			del("", X, z0, Y, W, ob.matt.h, H, f,
				if typ == "stovelhylla" or typ == "skap" or typ == "bank" then Enum.Material.Wood else Enum.Material.SmoothPlastic)
		end
	end
end

--[[ Stallet: fyra boxrader, två gångar, tvärkorridor, namngivna rum.

	Raderna och gångarna kommer ur planens mätta andelar (G.stall.band), inte ur
	någon delning gjord här. Ändras STALLINNE.bredd i src/site.js flyttar sig
	allt med, på båda plattformarna samtidigt. ]]
local function byggStallInre(model: Model, base: CFrame)
	local S = G.stall
	local o = S.origo
	local h = S.tak

	-- F02-C: endast den befintliga klubbdelens golv. Samma källa och
	-- material som webben; inga nya rumsgränser eller kollisionsytor.
	do
		local Y = YTOR.stallKlubb
		local k = S.klubb
		local gp = BK.box(model, base, "Stallklubb matt golv", o.x, 0.02, o.y + k.y0,
			S.bredd, 0.004, S.langd - k.y0, Y.farg, Enum.Material.Concrete)
		gp.CanCollide = false
		gp:SetAttribute("Ytfinish", Y.typ)
		gp:SetAttribute("Kalla", Y.kalla)
		gp:SetAttribute("FargKlass", Y.fargKlass)
	end

	-- Gångytorna, inklusive tvärkorridoren. De ligger som eget golv så att man
	-- ser var man kan gå — det är cirkulationen gaten frågar efter.
	for i, g in ipairs(S.gangytor) do
		if g.tvar then
			-- Tvärkorridoren: ljus betong (bottenplattan) med gångarnas mörka stråk
			-- fortsatta fram till serviceväggen (PO-referens stall-efter-pausrum-po-v1).
			for id, gg in pairs(S.gangar) do
				local p = BK.box(model, base, "Stallgång " .. i .. " stråk " .. id,
					o.x + gg.x0, 0.02, o.y + S.klubbY, gg.x1 - gg.x0, 0.04, S.klubb.y0 - S.klubbY, S.gangSten,
					Enum.Material.Pavement)
				p.CanCollide = false
			end
		else
			local p = BK.box(model, base, "Stallgång " .. i,
				o.x + g.x, 0.02, o.y + g.y, g.w, 0.04, g.h, S.gangSten,
				Enum.Material.Pavement)
			p.CanCollide = false
		end
	end

	--[[ Boxraderna.

		SENIOR INTERIOR FIDELITY, rättad KNOWN MISMATCH: fronterna och
		mellanväggarna byggdes här i BRUNT TRÄ (rgb 126,96,66, WoodPlanks)
		medan fotona visar mörk antracitpanel i galvad stålram — och medan
		webben redan ritade dem grå. Det var två sanningar om samma yta, och
		den bruna fanns bara i den här filen. Färgerna är nu MÄTTA ur
		stall-inne-05 och stall-inne-06 och står i det delade
		G.identitet.stall.boxfront, som båda ytorna läser.

		Andra rättade felläsningen: gallret var en TÄT skiva i DiamondPlate.
		Fotona visar VÅGRÄTA runda reglar mellan lodräta ändstolpar, med
		luft emellan — man ser in i boxen. Höjderna (panel 1,35, kappregel
		1,38, stolpe 2,15, överliggare 2,20) kommer ur samma delade data och
		räknas inte om här.

		Facken kommer ur Geometri, som specen mäter. Räknar man ut dem här
		mäter specen inte längre det som byggs. ]]
	local BF = G.identitet.stall.boxfront
	for _, rad in ipairs(S.rader) do
		local x0 = o.x + rad.x0
		for i, f in ipairs(GEO.boxfack(S, rad)) do
			local namn = rad.id .. " " .. i
			-- Skiljeväggar i fackets båda ändar, i panelens ton och höjd.
			for _, par in ipairs({ { "", f.y0 }, { "b", f.y1 } }) do
				BK.box(model, base, "Boxvägg " .. namn .. par[1],
					x0, 0, o.y + par[2], rad.djup, BF.heldelH, 0.08,
					BF.heldel, Enum.Material.Metal)
			end
			-- Den täta panelen mot gången, och kappregeln ovanpå den.
			local fx = if rad.vetter > 0 then x0 + rad.djup - 0.06 else x0
			BK.box(model, base, "Boxfront " .. namn,
				fx, 0, o.y + f.y0 + 0.08, 0.06, BF.heldelH, S.boxB - 0.16,
				BF.heldel, Enum.Material.Metal)
			BK.box(model, base, "Kappregel " .. namn,
				fx - 0.02, BF.ramZ, o.y + f.y0 + 0.08, 0.10, 0.10, S.boxB - 0.16,
				BF.ram, Enum.Material.Metal)
			-- Ändstolparna, upp till överliggaren.
			for _, zy in ipairs({ f.y0 + 0.08, f.y1 - 0.08 }) do
				local st = BK.box(model, base, "Frontstolpe " .. namn,
					fx - 0.04, 0, o.y + zy - 0.07, 0.14, BF.stolpH, 0.14,
					BF.ram, Enum.Material.Metal)
				st.CanCollide = false
			end
			-- De vågräta reglarna, jämnt fördelade mellan kappregel och
			-- överliggare. Antalet står i datan, inte här.
			for g = 1, BF.reglar do
				local z = BF.ramZ + (BF.toppregelZ - BF.ramZ) * g / (BF.reglar + 1)
				local r = BK.box(model, base, "Frontregel " .. namn .. ":" .. g,
					fx - 0.01, z, o.y + f.y0 + 0.15, BF.regelD, BF.regelD,
					S.boxB - 0.30, BF.ram, Enum.Material.Metal)
				r.CanCollide = false
			end
			BK.box(model, base, "Överliggare " .. namn,
				fx - 0.04, BF.toppregelZ, o.y + f.y0 + 0.08, 0.14, 0.10,
				S.boxB - 0.16, BF.ram, Enum.Material.Metal)
		end
	end

	-- Tvärväggarna ur planen, i bitar med dörrgap där gångarna passerar. Den
	-- mot klubbdelen är en branddörrsvägg. En obruten vägg här stänger av
	-- stallgången — byggbänken fällde precis det.
	for i, v in ipairs(S.tvarvaggar) do
		for j, bit in ipairs(GEO.tvarvaggBitar(S, v)) do
			BK.box(model, base, "Tvärvägg " .. i .. ":" .. j,
				o.x + bit.x0, 0, o.y + v.y, bit.x1 - bit.x0, h, 0.2, INRE.vagg,
				if v.brand then Enum.Material.Concrete else Enum.Material.Plaster)
		end
	end

	--[[ KLUBBDELEN ur utrymningsplanen, rättad av Product Owner 2026-09-03.

		Förut tre svävande lådor med rumsnamn i en öppen hall. Nu planens
		väggar, segment för segment med dörrarna som luckor, ur samma lista
		som webben kolliderar mot. Rummen är golv man går på; bara de som är
		`stangt` (den namnlösa volymen, Ö-toaletten, det lilla rummet utan
		läsbar dörr) byggs som hela volymer. Rumsnamnen står som attribut på
		en tunn golvplatta så att Studio kan visa vad som är vad utan att
		något solitt tillkommer. ]]
	byggVaggarOchRum(model, base, o, h, S.klubb, "Klubbvägg", INRE.vagg)
	--[[ KLUBBDELENS INNERTAK (PO/ChatGPT 2026-09-04 08:50, blocker A):
		stall-inne-01/-02/-03/-04 visar ett platt vitt innertak — plattan på
		klubbväggarnas höjd över hela klubbdelen norr om den genomgående
		väggen. Genomsiktlig så att den tonas om kameran hamnar över den. ]]
	do
		local gy = nil
		for _, v in ipairs(S.klubb.vaggar) do if v.id == "genomgaende" then gy = v.y end end
		gy = gy or S.klubbY
		local tak = BK.box(model, base, "Klubbdelens innertak", o.x, 2.8, o.y + gy, S.bredd, 0.10, S.langd - gy,
			Color3.fromRGB(244, 242, 236), Enum.Material.SmoothPlastic)
		tak.CanCollide = false
		tak:SetAttribute("Genomsiktlig", true)
	end

	--[[ Taket över boxhallen: limträstomme och galvad plåt.

		Det som avgör om någon känner igen stallgången inifrån är inte
		golvet utan TAKET — de varma limträbalkarna mot den grå korrugerade
		plåten, i varje bildruta av gången. Roblox byggde ingenting av det:
		gableRoof lägger ett yttertak i fasadkortets kulör, och undersidan
		blev den kulören. Det var inte en utsmyckning som saknades, det var
		husets tydligaste inre drag.

		Färgerna är MÄTTA ur stall-inne-05 och stall-inne-06 och står i det
		delade G.identitet.stall.stallgang. Resningen står i
		G.stall.takresning — den låg som ett lokalt tal i webbens renderare
		och fanns därför inte här alls. ]]
	local SG = G.identitet.stall.stallgang
	local resn = S.takresning
	local halvB, langd = S.bredd / 2, S.langd
	local takL = math.sqrt(halvB * halvB + resn * resn)
	local takV = math.atan2(resn, halvB)
	local mx = o.x + halvB
	for _, sida in ipairs({ -1, 1 }) do
		local p = Instance.new("Part")
		p.Name = "Stalltak plåt"; p.Anchored = true; p.CanCollide = false
		p.Color = SG.takplat; p.Material = Enum.Material.Metal
		p.Size = Vector3.new(BK.M * takL, BK.M * 0.12, BK.M * langd)
		p.CFrame = base
			* CFrame.new(BK.M * (mx + sida * halvB / 2), BK.M * (h + resn / 2),
				BK.M * (o.y + langd / 2))
			* CFrame.Angles(0, 0, -sida * takV)
		p.Parent = model
	end
	-- Tvärbalkar var fjärde meter, plus nockbalken. Samma delning som webben.
	for z = 2, langd - 1, 4 do
		BK.box(model, base, "Limträbalk", o.x, h - 0.13, o.y + z - 0.11,
			S.bredd, 0.26, 0.22, SG.limtra, Enum.Material.Wood).CanCollide = false
		for _, sida in ipairs({ -1, 1 }) do
			local p = Instance.new("Part")
			p.Name = "Limträstag"; p.Anchored = true; p.CanCollide = false
			p.Color = SG.limtra; p.Material = Enum.Material.Wood
			p.Size = Vector3.new(BK.M * takL * 0.9, BK.M * 0.16, BK.M * 0.14)
			p.CFrame = base
				* CFrame.new(BK.M * (mx + sida * halvB * 0.45),
					BK.M * (h + resn * 0.45), BK.M * (o.y + z))
				* CFrame.Angles(0, 0, -sida * takV)
			p.Parent = model
		end
	end
	BK.box(model, base, "Nockbalk", mx - 0.10, h + resn - 0.20, o.y,
		0.20, 0.24, langd, SG.limtra, Enum.Material.Wood).CanCollide = false

	--[[ Pendelarmaturerna över de två gångarna.

		`KNOWN MISMATCH` som rättas här: webben har haft dem sedan Review 05,
		Roblox inte alls — och det är armaturerna som gör att undertaket läses
		som ljus galvplåt hela vägen upp i nocken i i05. Samma delning (4,5 m)
		och samma lägen som webben, ur S.gangar. Antal och typ är
		`[REFERENCE GAP]`; att de hänger i rad över gångarna är `VERIFIED`. ]]
	for z = 3, langd - 1, 4.5 do
		for _, g in ipairs({ S.gangar.A, S.gangar.B }) do
			local ax = o.x + (g.x0 + g.x1) / 2
			local upp = BK.box(model, base, "Armaturpendel",
				ax - 0.012, h - 0.16, o.y + z - 0.012, 0.024, 0.16, 0.024,
				Color3.fromRGB(142, 147, 155), Enum.Material.Metal)
			upp.CanCollide = false
			local lampa = BK.box(model, base, "Stallarmatur",
				ax - 0.20, h - 0.23, o.y + z - 0.20, 0.40, 0.09, 0.40,
				Color3.fromRGB(251, 246, 228), Enum.Material.Neon)
			lampa.CanCollide = false
		end
	end

	-- Klockan i gångens bortre ände. `VERIFIED` i två oberoende bildrutor
	-- (IMG_0160 och stall-inne-05) och byggd i webben sedan Review 05 —
	-- men inte här. Läget står i G.stall.klocka.
	if S.klocka then
		local K = S.klocka
		local ur = BK.box(model, base, "Stallklocka",
			o.x + K.x, K.z - K.r, o.y + K.y - K.r, 0.09, K.r * 2, K.r * 2,
			Color3.fromRGB(238, 236, 228), Enum.Material.SmoothPlastic)
		ur.CanCollide = false
	end

	-- Namngivna rum och servicedelar. Låga volymer med sitt namn som attribut —
	-- namnen är fidelity-fakta ur utrymningsplanen, inredningen är det inte.
	for _, lista in ipairs({ S.rum, S.service }) do
		for _, r in ipairs(lista) do
			if r.oppen then continue end
			local p = BK.box(model, base, r.label,
				o.x + r.rekt.x, 0, o.y + r.rekt.y, r.rekt.w, h * 0.9, r.rekt.h,
				INRE.rum, Enum.Material.Plaster)
			p.Transparency = 0.45
			p:SetAttribute("Rum", r.id)
			p:SetAttribute("Genomsiktlig", true)
		end
	end

	--[[ SERVICEBUKTARNA — samma rättelse som webben fick.

		`KNOWN MISMATCH`, underkänd i webbens spelarvy och lika fel här:
		spolspiltan och spånförrådet byggdes som slutna volymer. stall-inne-07
		och -09 visar öppna bukter — fristående galvade spolbommar, spånsäckar
		på pall, mörk antracitpanel mot ytterväggen och rörstråk längs den
		vita väggen. `oppen` i den delade datan avgör vilket som byggs, så
		ytorna inte kan glida isär igen.

		Panelen läser boxfronternas MÄTTA färg: i09 ger #4A4B44 mot
		fronternas #454A4F — samma produkt, olika ljus. ]]
	local mitt = S.bredd / 2
	for _, r in ipairs(S.service) do
		if not r.oppen then continue end
		local k = r.rekt
		local innerX = if k.x < mitt then k.x + 0.10 else k.x + k.w - 0.20
		local ut = if k.x < mitt then 1 else -1
		BK.box(model, base, "Buktpanel " .. r.id,
			o.x + innerX, 0, o.y + k.y + 0.15, 0.10, r.panelH, k.h - 0.3,
			BF.heldel, Enum.Material.Metal).CanCollide = false
		if r.bommar then
			for i = 1, r.bommar do
				local bz = k.y + k.h * (i - 0.2) / (r.bommar + 0.6)
				BK.box(model, base, "Spolbom " .. r.id .. " " .. i,
					o.x + innerX + ut * (k.w * 0.55), 0, o.y + bz,
					0.13, 2.0, 0.13, BF.ram, Enum.Material.Metal)
			end
			BK.box(model, base, "Bomrail " .. r.id,
				o.x + innerX + ut * 0.30, r.railZ, o.y + k.y + 0.3,
				0.10, 0.10, k.h - 0.6, BF.ram,
				Enum.Material.Metal).CanCollide = false
		end
		if r.sackar then
			local sa = r.sackar
			for rad = 0, sa.rader - 1 do
				for i = 0, 2 do
					local sp = BK.box(model, base, "Spånsäckar " .. r.id,
						o.x + innerX + ut * (0.15 + rad * (sa.djup + 0.15)), 0,
						o.y + k.y + 0.3 + ((k.h - 0.6) / 3) * i,
						sa.djup, sa.hojd, (k.h - 0.6) / 3 - 0.12,
						Color3.fromRGB(220, 214, 200), Enum.Material.Fabric)
					sp.CanCollide = false
				end
			end
		end
		-- Rörstråket längs ytterväggen, i07 och i09.
		for _, z in ipairs({ 2.15, 2.55 }) do
			BK.box(model, base, "Servicerör " .. r.id,
				o.x + innerX + ut * 0.18, z, o.y + k.y + 0.2,
				0.09, 0.09, k.h - 0.4, BF.ram,
				Enum.Material.Metal).CanCollide = false
		end
	end

	--[[ Gaveldörren i söder: ljust parti med grön utrymningsskylt över.
		`VERIFIED` i i07 och i09 — i båda ser man gräset utanför. ]]
	if S.gaveloppning then
		--[[ PO-referens stall-efter-pausrum-po-v1 § Bortre ände: grå dubbeldörr
			med grön nödutgångsskylt. i07/i09 visade dörren ÖPPEN med dagsljus
			(ett tillstånd); bladen byggs stängda, grå, med ljus ruta var. ]]
		local G2 = S.gaveloppning
		local bb = G2.bredd / 2 - 0.02
		for i, sd in ipairs({ -1, 1 }) do
			local cx = o.x + G2.x + G2.bredd / 2 + sd * (bb / 2 + 0.01)
			BK.box(model, base, "Gaveldörr blad " .. i, cx - bb / 2, 0, o.y + 0.04, bb, G2.hojd, 0.08,
				Color3.fromRGB(140, 143, 146), Enum.Material.Metal).CanCollide = false
			BK.box(model, base, "Gaveldagsljus", cx - bb * 0.25, G2.hojd * 0.50, o.y + 0.12, bb * 0.5, G2.hojd * 0.24, 0.02,
				Color3.fromRGB(234, 242, 246), Enum.Material.SmoothPlastic).CanCollide = false
		end
		BK.box(model, base, "Exitskylt syd",
			o.x + G2.x + G2.bredd / 2 - G2.exitB / 2, G2.hojd + G2.exitOver,
			o.y + 0.06, G2.exitB, G2.exitH, 0.06,
			Color3.fromRGB(30, 122, 60), Enum.Material.Neon).CanCollide = false
		-- Valvfönstren i södra gaveln inifrån, med metallgaller (samma referens). u från västra hörnet.
		local hus
		for _, b in ipairs(G.byggnader) do if b.id == "stall" then hus = b end end
		for _, op in ipairs((hus and hus.oppningar) or {}) do
			if op.sida == "S" and op.typ == "valv" and op.z0 < 3 then
				local x0 = o.x + op.u
				BK.box(model, base, "Gavelfönster inifrån, karm", x0 - 0.10, op.z0 - 0.10, o.y + 0.03,
					op.b + 0.20, op.h + 0.20, 0.06, Color3.fromRGB(238, 236, 228), Enum.Material.SmoothPlastic).CanCollide = false
				local g = BK.box(model, base, "Gavelfönster inifrån, glas", x0, op.z0, o.y + 0.10,
					op.b, op.h, 0.03, Color3.fromRGB(200, 214, 222), Enum.Material.Glass)
				g.CanCollide = false
				g.Transparency = 0.3
				for i = 0, 4 do
					BK.box(model, base, "Gavelfönster inifrån, galler", x0 + op.b * (i + 0.5) / 5 - 0.01, op.z0 + op.h * 0.02, o.y + 0.19,
						0.02, op.h * 0.92, 0.02, Color3.fromRGB(110, 114, 117), Enum.Material.Metal).CanCollide = false
				end
			end
		end
	end

	-- Inredningen ur G.inredning.stall (F02-B): uppehållsrummet, teorisalen,
	-- sadelkammaren och exitskylten vid gång A:s norra ände.
	byggInredning(model, base, o, G.inredning and G.inredning.stall, "Inredning")
	--[[ Norra gaveln inifrån (klubbgaveln): samma öppningar som den låsta
		fasaden — entrédörren mitt på gaveln med ett runt fönster på var sida
		(stall-entre-15). Dörrbladet som en del i väggen (färgen inifrån är
		[antagande], samma som utsidan), vit karm, solfjäderfönstret som ljus
		ruta; de runda fönstren som karm + glas (fyrkantig stilisering, samma
		som fasadens `rund` i BK.window). u räknas från östra hörnet. Planens
		vindfång och `ut_n` rörs inte — dokumenterad motsägelse
		(STALLINNE.klubb-noten). Samma tecknare som webben (v3dStall). ]]
	do
		local hus
		for _, b in ipairs(G.byggnader) do if b.id == "stall" then hus = b end end
		local V = Color3.fromRGB(238, 236, 228)
		for _, op in ipairs((hus and hus.oppningar) or {}) do
			if op.sida == "N" and op.z0 < 3 and (op.typ == "dorrgul" or op.typ == "rund") then
				local x0 = o.x + S.bredd - op.u - op.b
				local zIn = o.y + S.langd
				if op.typ == "dorrgul" then
					BK.box(model, base, "Klubbentrén inifrån", x0, 0, zIn - 0.09, op.b, op.h, 0.06,
						Color3.fromRGB(168, 118, 80), Enum.Material.Wood).CanCollide = false
					BK.box(model, base, "Klubbentréns karm", x0 - 0.12, op.h, zIn - 0.10,
						op.b + 0.24, 0.12, 0.07, V, Enum.Material.SmoothPlastic).CanCollide = false
					for _, sx in ipairs({ x0 - 0.12, x0 + op.b }) do
						BK.box(model, base, "Klubbentréns karm", sx, 0, zIn - 0.10,
							0.12, op.h + 0.12, 0.07, V, Enum.Material.SmoothPlastic).CanCollide = false
					end
					BK.box(model, base, "Klubbentréns solfjäderfönster", x0 + op.b * 0.13, op.h * 0.64, zIn - 0.13,
						op.b * 0.74, op.h * 0.30, 0.03, Color3.fromRGB(200, 214, 222), Enum.Material.Glass).CanCollide = false
				else
					BK.box(model, base, "Runt fönster inifrån, karm", x0 - 0.08, op.z0 - 0.08, zIn - 0.10,
						op.b + 0.16, op.h + 0.16, 0.06, V, Enum.Material.SmoothPlastic).CanCollide = false
					local g = BK.box(model, base, "Runt fönster inifrån, glas", x0, op.z0, zIn - 0.13,
						op.b, op.h, 0.03, Color3.fromRGB(184, 204, 216), Enum.Material.Glass)
					g.CanCollide = false
					g.Transparency = 0.3
				end
			end
		end
		--[[ Västväggens valvfönster inifrån (review 2026-09-04 08:50, blocker A):
			stall-inne-01 läser soffa–fönster–fotovägg–växt–ponny; fönstret är
			västväggens rundbågiga valv. Fasadens två W-valv (u från norra
			gaveln) ligger båda i uppehållsrummet. Fasadens valv står z 1,55–3,10
			men innertaket på 2,8 (fotot: bågen slutar under taklisten) — rutan
			klipps under taket; höjden inifrån är [antagande], exteriören låst.
			Samma tecknare som webben (v3dStall). ]]
		local gy0 = S.klubbY
		for _, v in ipairs(S.klubb.vaggar) do if v.id == "genomgaende" then gy0 = v.y end end
		for _, op in ipairs((hus and hus.oppningar) or {}) do
			if op.sida == "W" and op.typ == "valv" and op.z0 < 3 then
				local cy = S.langd - op.u - op.b / 2
				if cy >= gy0 then
					local h = math.min(op.h, 2.80 - 0.15 - op.z0)
					local z0 = o.y + cy - op.b / 2
					BK.box(model, base, "Valvfönster inifrån, karm", o.x + 0.03, op.z0 - 0.10, z0 - 0.10,
						0.06, h + 0.20, op.b + 0.20, V, Enum.Material.SmoothPlastic).CanCollide = false
					local g = BK.box(model, base, "Valvfönster inifrån, glas", o.x + 0.10, op.z0, z0,
						0.03, h, op.b, Color3.fromRGB(200, 214, 222), Enum.Material.Glass)
					g.CanCollide = false
					g.Transparency = 0.3
					BK.box(model, base, "Valvfönster inifrån, fönsterbräda", o.x + 0.03, op.z0 - 0.04, z0 - 0.15,
						0.22, 0.04, op.b + 0.30, V, Enum.Material.SmoothPlastic).CanCollide = false
				end
			end
		end
	end
end

--[[ Ridhuset: banan, sargen med porten, läktaren, glasrummen, domarbåset.

	20 × 60 kommer ur G.ridhus.bana och är bekräftad av Tobias. Läktaren,
	glasrummen och båset är Gate F01:s rättade interiörfakta — de är byggda
	därför att de avgör igenkänningen, inte för att de är utsmyckning. ]]
local function byggRidhusInre(model: Model, base: CFrame)
	local R = G.ridhus
	local o = R.origo
	local b = R.bana

	--[[ Ridbanan — den FYSISKA ridytan sarg till sarg (södra sargen mot
		A-gaveln, ridhus-inne-23; norra vid entrédelens gräns), inte
		dressyrens 20 × 60. Layouten ligger i R.dressyr och skrivs som
		attribut så att Studio kan visa båda. Sanden läser den delade, MÄTTA
		`R.sandFarg` (#6F5D4D ur -03), inte INRE.sand. ]]
	local sand = BK.box(model, base, "Ridbanan",
		o.x + b.x, 0, o.y + b.y, b.w, 0.06, b.h,
		R.sandFarg or INRE.sand, Enum.Material.Sand)
	sand.CanCollide = false
	sand:SetAttribute("Matt", string.format("%.0fx%.1f", b.w, b.h))
	if R.dressyr then
		local dr = R.dressyr
		sand:SetAttribute("Dressyr", string.format("%.0fx%.0f", dr.w, dr.h))
		local layout = BK.box(model, base, "Dressyrlayout 20x60",
			o.x + dr.x, 0.03, o.y + dr.y, dr.w, 0.02, dr.h,
			R.sandFarg or INRE.sand, Enum.Material.Sand)
		layout.CanCollide = false
		layout.Transparency = 1
		layout:SetAttribute("Forankring", dr.forankring or "A")
	end

	-- Sargen runt banan, med porten som en lucka i norra kortsidan.
	local sh = R.sargH
	BK.box(model, base, "Sarg väst", o.x + b.x - 0.1, 0, o.y + b.y, 0.1, sh, b.h, INRE.sarg)
	-- Östra långsidan i två stycken: grinden mot hästgången är gapet. Utan den
	-- går det inte att leda hästen mellan banan och gången, och gången blir
	-- dekoration. Webbens vägsökning fällde precis det.
	local gr = R.sargGrind
	if gr then
		BK.box(model, base, "Sarg öst syd", o.x + b.x + b.w, 0, o.y + b.y,
			0.1, sh, gr.y0 - b.y, INRE.sarg)
		BK.box(model, base, "Sarg öst norr", o.x + b.x + b.w, 0, o.y + gr.y1,
			0.1, sh, b.y + b.h - gr.y1, INRE.sarg)
	else
		BK.box(model, base, "Sarg öst", o.x + b.x + b.w, 0, o.y + b.y, 0.1, sh, b.h, INRE.sarg)
	end
	BK.box(model, base, "Sarg syd",  o.x + b.x, 0, o.y + b.y - 0.1, b.w, sh, 0.1, INRE.sarg)
	--[[ Norra kortsidan i två stycken. Gapet mellan dem är SPELABSTRAKTIONEN
		sargport (G.spelabstraktioner, src/site.js): ingen bild visar en
		grind i sargen och bredden är vald, så den är inte fidelity-geometri
		utan spelets väg från entrédelen ut på banan. Den byggs som ett gap
		plus en genomskinlig, okolliderande markör med klass som attribut,
		så att Studio visar VAD den är. (Senior Re-review 2026-09-03.) ]]
	local sp = G.spelabstraktioner.ridhus.sargport
	BK.box(model, base, "Sarg norr väst", o.x + b.x, 0, o.y + b.y + b.h,
		sp.x0 - b.x, sh, 0.1, INRE.sarg)
	BK.box(model, base, "Sarg norr öst", o.x + sp.x1, 0, o.y + b.y + b.h,
		b.x + b.w - sp.x1, sh, 0.1, INRE.sarg)
	local markor = BK.box(model, base, "Spelabstraktion sargport", o.x + sp.x0, 0, o.y + b.y + b.h - 0.05,
		sp.x1 - sp.x0, sh, 0.2, Color3.fromRGB(214, 174, 60), Enum.Material.Neon)
	markor.CanCollide = false
	markor.Transparency = 0.7
	markor:SetAttribute("Klass", sp.klass)
	markor:SetAttribute("Fidelity", sp.fidelity)
	markor:SetAttribute("Motiv", sp.motiv)

	--[[ Läktaren längs östra långsidan.

		`KNOWN MISMATCH A`, rättad på båda ytorna: den byggdes som fyra
		TRAPPSTEG i ljust trä. `ridhus-inne-01` och `-02` är båda tagna FRÅN
		läktaren och visar ett PLANT plankdäck med en solid mörkbetsad
		brädfront och en ljus kappregel — inga steg. Trappstegen finns vid
		KORTÄNDAN, under glasrummen, och byggs där nedan. De två
		strukturerna hade blandats ihop.

		Höjderna kommer ur den delade datan och är härledda ur `-03`; se
		noten i src/site.js. ]]
	--[[ F02-B: kommentaren ovan är ÖVERSPELAD. Matrisen (references/
		buildings/ridhus/INTERIOR-MATRIS.md § 2) återkallar den solida
		mörka fronten och kappregeln — de var lästa ur en beskuren
		förgrund — och slår fast att läktaren är sarg + plan GÅNGBRÄDA i
		mörkt trä + STEGADE BÄNKRADER i ljus furu längs hela långsidan
		(ridhus-inne-04, -07, -14, -43). Raderna kommer ur
		Geometri.laktarRader, samma regel som webbens laktarRader. ]]
	local L = R.laktare
	local lE = R.sidor and R.sidor.laktare == "E"
	local bankant = if lE then L.x0 else L.x0 + L.dackDjup   -- däckets kant mot banan
	local inat = if lE then 1 else -1                          -- riktning in från banan
	local g, rr = L.gangbrada, L.rader
	local bankFarg = if rr then rr.farg else INRE.laktare
	local kantFarg = if rr then rr.kantFarg else INRE.laktare
	-- Läktarens NORRA 4 m (LAKTARE_TONAD_ANDE, delad med webben) byggs som
	-- egna delar med Genomsiktlig: står figuren i entréhallen bakom dem
	-- döljer raderna henne annars (siktgrinden #78). Resten tonas aldrig,
	-- så däcket man går på förblir synligt.
	local LAKTARE_TONAD_ANDE = 4.0
	for s, sek in ipairs(GEO.laktarSektioner(L)) do
	  local bitar = if math.abs(sek.y1 - L.y1) < 0.01 and (sek.y1 - sek.y0) > 6
	    then { { y0 = sek.y0, y1 = sek.y1 - LAKTARE_TONAD_ANDE, gs = false }, { y0 = sek.y1 - LAKTARE_TONAD_ANDE, y1 = sek.y1, gs = true } }
	    else { { y0 = sek.y0, y1 = sek.y1, gs = false } }
	  for _, bit in ipairs(bitar) do
		local dj = bit.y1 - bit.y0
		local function gs(p) if bit.gs then p:SetAttribute("Genomsiktlig", true) end return p end
		local gX = if inat > 0 then bankant else bankant - g.djup
		gs(BK.box(model, base, "Läktargångbräda " .. s,
			o.x + gX, L.dackZ - 0.10, o.y + bit.y0, g.djup, 0.10, dj,
			g.farg, Enum.Material.WoodPlanks))
		for i, rad in ipairs(GEO.laktarRader(L)) do
			local x0 = if inat > 0 then bankant + rad.in0 else bankant - rad.in1
			local dju = rad.in1 - rad.in0
			gs(BK.box(model, base, "Läktarrad " .. s .. ":" .. i,
				o.x + x0, rad.z - rr.sittTjock, o.y + bit.y0, dju, rr.sittTjock, dj,
				bankFarg, Enum.Material.WoodPlanks))
			-- sättsteget ner mot banan och den röda kantlisten (-04)
			local sX = if inat > 0 then bankant + rad.in0 else bankant - rad.in0 - 0.04
			gs(BK.box(model, base, "Läktarsättsteg " .. s .. ":" .. i,
				o.x + sX, L.dackZ, o.y + bit.y0, 0.04, rad.z - L.dackZ - rr.sittTjock, dj,
				bankFarg, Enum.Material.WoodPlanks))
			gs(BK.box(model, base, "Läktarkantlist " .. s .. ":" .. i,
				o.x + sX, rad.z, o.y + bit.y0, 0.06, 0.04, dj,
				kantFarg, Enum.Material.SmoothPlastic)).CanCollide = false
		end
		-- Stomme under däcket, så att det inte svävar.
		local stX = if inat > 0 then bankant + L.dackDjup - 0.3 else bankant - L.dackDjup + 0.18
		gs(BK.box(model, base, "Läktarstomme " .. s,
			o.x + stX, 0, o.y + bit.y0, 0.12, L.dackZ, dj,
			INRE.laktare, Enum.Material.Wood)).CanCollide = false
	  end
	  do
		local dj = sek.y1 - sek.y0
		-- Elon-dynorna på översta raden (-07); förut bara i webben.
		local rader = GEO.laktarRader(L)
		local topp = rader[#rader]
		if topp and R.dynor then
			for i = 0, R.dynor - 1 do
				local z = sek.y0 + 2.0 + i * ((dj - 4) / math.max(1, R.dynor - 1))
				local dX = if inat > 0 then bankant + (topp.in0 + topp.in1) / 2 else bankant - (topp.in0 + topp.in1) / 2
				BK.box(model, base, "Läktardyna " .. (i + 1),
					o.x + dX - 0.17, topp.z, o.y + z - 0.22, 0.34, 0.06, 0.44,
					Color3.fromRGB(38, 40, 44), Enum.Material.Fabric).CanCollide = false
			end
		end
	  end
	end

	--[[ TRAPPORNA (R.trappor, Product Owner 2026-09-03): läktargångens
		trappa upp till övre gången och stegen från entréhallen upp på
		däcket. Stegen ur den delade regeln Geometri.trappsteg — samma
		steg som webbens nivåregel läser — som klossar karaktären kliver
		upp för (steghöjd < 0,19 m = 0,57 studs). Sträng och räcke på den
		fria sidan, utan kollision. Provenance som väggarna. ]]
	for _, t in ipairs(R.trappor or {}) do
		local T = GEO.trappsteg(t)
		local langsX = T.axel == "x"
		local b = if langsX then t.y1 - t.y0 else t.x1 - t.x0
		for i, st in ipairs(T.steg) do
			local tj = math.max(0.06, math.abs(T.stig))
			local p
			if langsX then
				p = BK.box(model, base, "Trappa " .. t.id .. " steg " .. i,
					o.x + st.a0, st.z - tj, o.y + t.y0, st.a1 - st.a0, tj, b,
					Color3.fromRGB(90, 66, 50), Enum.Material.WoodPlanks)
			else
				p = BK.box(model, base, "Trappa " .. t.id .. " steg " .. i,
					o.x + t.x0, st.z - tj, o.y + st.a0, b, tj, st.a1 - st.a0,
					Color3.fromRGB(90, 66, 50), Enum.Material.WoodPlanks)
			end
			p:SetAttribute("Genomsiktlig", true)
			kanonAttribut(p, t)
		end
		local a0 = if langsX then t.x0 else t.y0
		local a1 = if langsX then t.x1 else t.y1
		local lang = a1 - a0
		local bakat = (t.stiger == "S" or t.stiger == "W")
		local lut = math.atan2(t.z1 - t.z0, lang) * (if bakat then -1 else 1)
		local L = math.sqrt(lang * lang + (t.z1 - t.z0) * (t.z1 - t.z0))
		-- handledare (och för gavelloppen det vita snedställda sidostycket) på bansidan
		local sidor = if langsX then { t.y0 + 0.05 } elseif t.x0 < 1.0 then { t.x1 - 0.05 } else { t.x0 + 0.05, t.x1 - 0.05 }
		for _, sx in ipairs(sidor) do
			for i = 1, T.n, 3 do
				local st = T.steg[i]
				local c = (st.a0 + st.a1) / 2
				local px = if langsX then c else sx
				local pz = if langsX then sx else c
				local stolpe = BK.box(model, base, "Trappa " .. t.id .. " räckesstolpe " .. i,
					o.x + px - 0.03, st.z, o.y + pz - 0.03, 0.06, 0.95, 0.06,
					Color3.fromRGB(138, 106, 68), Enum.Material.Wood)
				stolpe.CanCollide = false
				stolpe:SetAttribute("Genomsiktlig", true)   -- tonas när de skymmer (som webben)
			end
			local am, zm = (a0 + a1) / 2, (t.z0 + t.z1) / 2
			local function sned(namn, h, dz, farg, mat, ds)
				local d = BK.box(model, base, namn, 0, 0, 0, 0.06, h, 0.06, farg, mat)
				d.CanCollide = false
				d:SetAttribute("Genomsiktlig", true)   -- sidostycke/handledare tonas när de skymmer
				if langsX then
					d.Size = Vector3.new(BK.M * L, BK.M * h, BK.M * 0.05)
					d.CFrame = base * CFrame.new(BK.M * (o.x + am), BK.M * (zm + dz), BK.M * (o.y + sx + (ds or 0))) * CFrame.Angles(0, 0, lut)
				else
					d.Size = Vector3.new(BK.M * 0.05, BK.M * h, BK.M * L)
					d.CFrame = base * CFrame.new(BK.M * (o.x + sx + (ds or 0)), BK.M * (zm + dz), BK.M * (o.y + am)) * CFrame.Angles(-lut, 0, 0)
				end
			end
			if langsX then
				-- Från banan är det vita sidostycket det man ser av loppet (ridhus-inne-01):
				-- ett trapets med vågrät underkant i blockets krön och överkanten längs
				-- räcket 0,9 m över stegen. Byggt som en lutande skiva över stegen plus
				-- en vit fyllnad per steg ner till blockets krön; räcket ovanpå kanten.
				local V = Color3.fromRGB(233, 229, 220)
				sned("Trappa " .. t.id .. " sidostycke", 0.90, 0.45, V, Enum.Material.Plaster, -0.10)
				local bas = math.min(t.z0, t.z1)
				for i, st in ipairs(T.steg) do
					if st.z - bas > 0.02 then
						local f = BK.box(model, base, "Trappa " .. t.id .. " sidostycke fyllnad " .. i,
							o.x + st.a0, bas, o.y + sx - 0.125, st.a1 - st.a0, st.z - bas, 0.05, V, Enum.Material.Plaster)
						f.CanCollide = false
						f:SetAttribute("Genomsiktlig", true)
					end
				end
				sned("Trappa " .. t.id .. " handledare", 0.06, 0.93, Color3.fromRGB(138, 106, 68), Enum.Material.Wood, -0.10)
			else
				-- Loppet längs y (läktartrappan vid H): den vita snedställda sidan mot
				-- raderna/banan (ridhus-inne-15/-14/-20) som för C-trapporna, vänd åt +x.
				local V = Color3.fromRGB(233, 229, 220)
				sned("Trappa " .. t.id .. " sidostycke", 0.90, 0.45, V, Enum.Material.Plaster, 0.10)
				local bas = math.min(t.z0, t.z1)
				for i, st in ipairs(T.steg) do
					if st.z - bas > 0.02 then
						local f = BK.box(model, base, "Trappa " .. t.id .. " sidostycke fyllnad " .. i,
							o.x + sx + 0.075, bas, o.y + st.a0, 0.05, st.z - bas, st.a1 - st.a0, V, Enum.Material.Plaster)
						f.CanCollide = false
						f:SetAttribute("Genomsiktlig", true)
					end
				end
				sned("Trappa " .. t.id .. " handledare", 0.06, 0.93, Color3.fromRGB(138, 106, 68), Enum.Material.Wood, 0.10)
			end
		end
	end
	--[[ SPELETS LÄKTARSTEG (G.spelabstraktioner.ridhus.laktarSteg): hallgolvet →
		läktardäcket vid däckets norra ände (PO 2026-09-04 07:54, blocker 3).
		ridhus-inne-39 visar nivåskillnaden men inte stegen — därför
		spelabstraktion, märkt som bänkradsstegen. ]]
	do
		local ls = G.spelabstraktioner and G.spelabstraktioner.ridhus and G.spelabstraktioner.ridhus.laktarSteg
		if ls and ls.x1 > ls.x0 and ls.y1 > ls.y0 then
			local T = GEO.trappsteg(ls)
			local b = ls.x1 - ls.x0
			for i, st in ipairs(T.steg) do
				local tj = math.max(0.06, math.abs(T.stig))
				local p = BK.box(model, base, "Spelabstraktion laktarsteg steg " .. i,
					o.x + ls.x0, st.z - tj, o.y + st.a0, b, tj, st.a1 - st.a0,
					Color3.fromRGB(185, 168, 134), Enum.Material.WoodPlanks)
				p:SetAttribute("Klass", ls.klass)
				p:SetAttribute("Fidelity", ls.fidelity)
				p:SetAttribute("Motiv", ls.motiv)
			end
			local markor = BK.box(model, base, "Spelabstraktion laktarsteg", o.x + ls.x0, ls.z1 + 0.3, o.y + ls.y0,
				b, 0.12, ls.y1 - ls.y0, Color3.fromRGB(214, 174, 60), Enum.Material.Neon)
			markor.CanCollide = false
			markor.Transparency = 0.7
			markor:SetAttribute("Klass", ls.klass)
			markor:SetAttribute("Fidelity", ls.fidelity)
			markor:SetAttribute("Motiv", ls.motiv)
		end
	end
	--[[ SPELETS BÄNKRADSSTEG (G.spelabstraktioner.ridhus.bankradSteg): inte
		fidelity — inget foto visar hur publiken kommer upp på raderna. Byggs
		som kliv-bara klossar MÄRKTA med Klass/Fidelity/Motiv som attribut
		(ingen CanonId/SourceId/Confidence), i neutral färg, med en gul
		genomskinlig markör som sargporten. Räknas inte in i något F02-PASS. ]]
	do
		local bs = G.spelabstraktioner and G.spelabstraktioner.ridhus and G.spelabstraktioner.ridhus.bankradSteg
		if bs and bs.x1 > bs.x0 then
			local T = GEO.trappsteg(bs)
			local b = bs.y1 - bs.y0
			for i, st in ipairs(T.steg) do
				local tj = math.max(0.06, math.abs(T.stig))
				local p = BK.box(model, base, "Spelabstraktion bankradsteg steg " .. i,
					o.x + st.a0, st.z - tj, o.y + bs.y0, st.a1 - st.a0, tj, b,
					Color3.fromRGB(185, 168, 134), Enum.Material.WoodPlanks)
				p:SetAttribute("Klass", bs.klass)
				p:SetAttribute("Fidelity", bs.fidelity)
				p:SetAttribute("Motiv", bs.motiv)
			end
			local markor = BK.box(model, base, "Spelabstraktion bankradsteg", o.x + bs.x0, bs.z1 + 0.3, o.y + bs.y0,
				bs.x1 - bs.x0, 0.12, b, Color3.fromRGB(214, 174, 60), Enum.Material.Neon)
			markor.CanCollide = false
			markor.Transparency = 0.7
			markor:SetAttribute("Klass", bs.klass)
			markor:SetAttribute("Fidelity", bs.fidelity)
			markor:SetAttribute("Motiv", bs.motiv)
		end
	end
	--[[ ÖVRE GÅNGEN (R.ovreGang): golvet på caféplanet längs banans kant som
		läktargångens trappa landar i (`ridhus-klubb-10`), och ett räcke mot
		banan där C-blockets glasband inte står — utom i trappans mynning.
		Caféets rum innanför är REFERENCE GAP och byggs inte. ]]
	if R.ovreGang then
		local G2 = R.ovreGang
		local golv = BK.box(model, base, "Övre gångens golv",
			o.x + G2.x0, G2.z - 0.26, o.y + G2.y0, G2.x1 - G2.x0, 0.26, G2.y1 - G2.y0,
			Color3.fromRGB(207, 200, 188), Enum.Material.WoodPlanks)
		golv:SetAttribute("Genomsiktlig", true)
		local trappa = nil
		for _, t in ipairs(R.trappor or {}) do if t.id == "laktargang_upp" then trappa = t end end
		local K2 = R.kortanda
		local fri = { { G2.x0, K2 and K2.x0 or G2.x1 }, { K2 and K2.x1 or G2.x1, G2.x1 } }
		for _, seg in ipairs(fri) do
			local a, b2 = seg[1], seg[2]
			local bitar = { { a, b2 } }
			if trappa and trappa.x0 < b2 and trappa.x1 > a then
				bitar = { { a, trappa.x0 }, { trappa.x1, b2 } }
			end
			for j, bit in ipairs(bitar) do
				if bit[2] - bit[1] > 0.05 then
					BK.box(model, base, "Övre gångens räcke " .. j,
						o.x + bit[1], G2.z, o.y + G2.y0 - 0.06, bit[2] - bit[1], 1.0, 0.06,
						Color3.fromRGB(233, 229, 220), Enum.Material.Plaster)
				end
			end
		end
	end

	--[[ LANDGÅNGEN PÅ ÖVRE PLAN (R.ovreGangV): från läktartrappans topp vid
		läktarens norra ände norrut till övre gången (ridhus-klubb-10,
		ridhus-inne-39). Golv på caféplanet i läktarens västra meter, räcke
		mot hallen på östra sidan. ]]
	if R.ovreGangV then
		local V2 = R.ovreGangV
		local golv = BK.box(model, base, "Övre gångens västarm golv",
			o.x + V2.x0, V2.z - 0.26, o.y + V2.y0, V2.x1 - V2.x0, 0.26, V2.y1 - V2.y0,
			Color3.fromRGB(207, 200, 188), Enum.Material.WoodPlanks)
		golv:SetAttribute("Genomsiktlig", true)
		local racke = BK.box(model, base, "Övre gångens västarm räcke",
			o.x + V2.x1 - 0.06, V2.z, o.y + V2.y0, 0.06, 1.0, V2.y1 - V2.y0,
			Color3.fromRGB(233, 229, 220), Enum.Material.Plaster)
		racke:SetAttribute("Genomsiktlig", true)
	end

	-- Kortändans läktare: trappstegsblock, två trappor och glasbandet ovanför.
	-- De glasade rummen låg förut längs LÅNGSIDAN, i läktarens liv. Fotot
	-- ridhus-inne-01 visar dem över ett trappstegsblock vid kortändan, och
	-- bokstaven C framför blocket avgör saken: C ligger mitt på en kortsida.
	local K = R.kortanda
	if K then
		local br = K.x1 - K.x0
		--[[ Blocket står på en SOCKEL. Utan den steg raderna bort från banan
			och bara den översta kom över sargen — 0,25 m på fjorton meters
			håll. `-01` visar flera rader över sargkrönet. ]]
		local SO = K.sockelH or 0
		if SO > 0 then
			BK.box(model, base, "Kortändans sockel", o.x + K.x0, 0, o.y + K.y0,
				br, SO, K.y1 - K.y0, INRE.laktare, Enum.Material.WoodPlanks)
		end
		--[[ Bänkarna läser den MÄTTA `K.bank` (#86715B ur -01), inte
			INRE.laktare. Webben hade #D8C7A4, ljus furu, vilket fotot
			motsäger — och Roblox hade sin egen ton. Två sanningar om samma
			bänk; nu delar de en. ]]
		--[[ `vand` säger var BANAN ligger. "S": blocket står i norra änden,
			stegen stiger norrut från bankanten y0 mot gavelväggen y1, där
			den vita väggen, klockan och glasbandet står. `ut` pekar från
			banan mot väggen; `bank`/`vagg` är de två kanterna. Förut var
			talen skrivna för ett block i söder med väggen vid y0. ]]
		local mS = K.vand == "S"
		local bank = if mS then K.y0 else K.y1
		local vagg = if mS then K.y1 else K.y0
		local ut = if mS then 1 else -1
		for i = 1, K.steg do
			--[[ steg i täcker stegD från bankanten inåt; klossen står på
				sockeln och når radens sitthöjd SO + i × stegH (+ plankan).
				Förut stod basen på SO + (i−1) × stegH med samma höjd, så
				raderna steg 0,64 m i stället för 0,32 — det syntes först
				när kedjan upp till C-trapporna provades (2026-09-03). ]]
			local z0 = if mS then bank + (i - 1) * K.stegD else bank - i * K.stegD
			BK.box(model, base, "Kortändans steg " .. i,
				o.x + K.x0, SO,
				o.y + z0, br, K.stegH * i + 0.1, K.stegD,
				K.bank or INRE.laktare, Enum.Material.WoodPlanks)
		end
		-- De två trapporna byggs som gångbara STAIR-primitiver ur R.trappor ovan.
		--[[ Glasbandet är INTE en obruten remsa. `ridhus-inne-01` visar att
			de två trapporna bryter det: deras vita snedställda barriärer
			skjuter upp genom bandet, och mellan dem står den vita väggen
			med klockan. Segmenten räknas ur samma `trappor`-tal som
			trapporna byggs av, så de inte kan glida isär. ]]
		local H = (K.sockelH or 0) + K.steg * K.stegH
		local gz = H + K.glasOver
		--[[ DEN VITA VÄGGEN mellan bänkarna och glasbandet, vid väggsidan.
			Roblox byggde bara steg, trappor och glas; gapet däremellan
			visade skalets material, inte den vita väggen ridhus-inne-01
			visar. Att flytta glaset uppåt räcker inte om gapet exponerar
			fel yta. ]]
		BK.box(model, base, "Kortändans vita vägg", o.x + K.x0, H,
			o.y + vagg - (if mS then 0.14 else 0.16), br, K.glasOver, 0.14,
			R.hallvagg or INRE.vagg,
			Enum.Material.Plaster).CanCollide = false

		-- Klockan MELLAN trapporna, och kompassrosen till vänster om dem,
		-- på den vita väggens bansida.
		local framfor = vagg - ut * 0.22
		if K.klocka then
			local KL = K.klocka
			BK.box(model, base, "Kortändans klocka",
				o.x + KL.x - KL.r, H + KL.overBlock - KL.r, o.y + framfor - 0.04,
				KL.r * 2, KL.r * 2, 0.08,
				Color3.fromRGB(244, 241, 232),
				Enum.Material.SmoothPlastic).CanCollide = false
		end
		if K.stjarna then
			local ST = K.stjarna
			for i = 0, 3 do
				local lang = if i % 2 == 0 then ST.r * 2 else ST.r * 1.45
				local stav = Instance.new("Part")
				stav.Name = "Kompassros"; stav.Anchored = true
				stav.CanCollide = false
				stav.Color = ST.farg
				stav.Material = Enum.Material.SmoothPlastic
				stav.Size = Vector3.new(BK.M * lang, BK.M * ST.tjocklek, BK.M * 0.05)
				stav.CFrame = base
					* CFrame.new(BK.M * (o.x + ST.x),
						BK.M * (H + ST.overBlock), BK.M * (o.y + framfor - 0.02))
					* CFrame.Angles(0, 0, i * math.pi / 4)
				stav.Parent = model
			end
		end
		local brytn = {}
		for _, t in ipairs(K.trappor or {}) do table.insert(brytn, t) end
		table.sort(brytn, function(a, b2) return a.x0 < b2.x0 end)
		local seg, sx = {}, K.x0
		for _, t in ipairs(brytn) do
			if t.x0 - sx > 0.3 then table.insert(seg, { sx, t.x0 }) end
			if t.x1 > sx then sx = t.x1 end
		end
		if K.x1 - sx > 0.3 then table.insert(seg, { sx, K.x1 }) end
		for i, sg in ipairs(seg) do
			local w = sg[2] - sg[1]
			local glas = BK.box(model, base, "Kortändans glasband " .. i,
				o.x + sg[1], gz, o.y + vagg - (if mS then 0.0 else 0.12), w, K.glasH, 0.12,
				INRE.glas, Enum.Material.Glass)
			glas.Transparency = 0.55
			glas.CanCollide = false
			local n = math.max(1, math.round(w / (K.glasPost or 1.9)))
			for j = 0, n do
				BK.box(model, base, "Glaspost",
					o.x + sg[1] + w * j / n - 0.055, gz, o.y + vagg - (if mS then 0.02 else 0.14),
					0.11, K.glasH, 0.14,
					K.glasKarm or INRE.laktare,
					Enum.Material.Wood).CanCollide = false
			end
		end
	end

	--[[ Fönstren ovanför panelen — OMGRANSKADE 2026-09-03: SEPARATA
		öppningar, en per väggfält mellan pilastrarna (ridhus-inne-31, -17,
		-24), inte ett löpande band. Fälten kommer ur Geometri.ridhusFalt,
		samma regel som webben. ]]
	local FB = G.identitet.ridhus.fonsterband
	local OV = G.identitet.ridhus.ovreVagg
	if FB and OV then
		local fx = if OV.sida == "W" then 0.16 else R.bredd - 0.16
		local fy = R.tak - FB.underTak - FB.h
		for i, falt in ipairs(GEO.ridhusFalt(R)) do
			local b = math.min(FB.faltBredd or 3.0, (falt[2] - falt[1]) - 1.0)
			if b >= 0.8 then
				local zm = (falt[1] + falt[2]) / 2
				local glas = BK.box(model, base, "Ridhus fönster " .. i,
					o.x + fx, fy, o.y + zm - b / 2, FB.tjocklek, FB.h, b,
					FB.glas, Enum.Material.Glass)
				glas.Transparency = 0.35
				glas.CanCollide = false
				for _, z in ipairs({ zm - b / 2, zm + b / 2 - 0.09 }) do
					BK.box(model, base, "Fönsterpost", o.x + fx - 0.02, fy,
						o.y + z, FB.tjocklek + 0.03, FB.h, 0.09,
						FB.karm, Enum.Material.Wood).CanCollide = false
				end
			end
		end
	end

	--[[ PELARNA på båda långsidorna där takstolarna landar: pilastrarna som
		delar panelen i fält (ridhus-inne-31) och läktarsidans mörka pelare i
		den ljusa skivpanelen (ridhus-inne-14, INTERIOR-MATRIS § 5). Utan dem
		är läktarväggen en slät yta i samma ton som alla andra väggar. ]]
	local LV = G.identitet.ridhus.laktarVagg
	if LV and OV then
		for _, falt in ipairs(GEO.ridhusFalt(R)) do
			local z = falt[2]
			if z < R.langd - R.entre - 0.01 then
				for _, sida in ipairs({ "W", "E" }) do
					local x = if sida == "W" then 0.16 else R.bredd - 0.16 - LV.pelareB
					local z0 = if sida == OV.sida then R.sargH + OV.overSarg else 0
					BK.box(model, base, "Väggpelare " .. sida, o.x + x, z0,
						o.y + z - LV.pelareB / 2, LV.pelareB, R.tak - z0, LV.pelareB,
						LV.pelareFarg, Enum.Material.Wood).CanCollide = false
				end
			end
		end
	end

	-- Domarbåset vid E, med exit-skylten över öppningen.
	--[[ Domarbåset vid E. Roblox byggde det som EN slät låda — ingen
		upphöjd nivå, ingen trappa, inga räcken, inget tak. Webben har haft
		allt det sedan Review 03, så det var en Roblox-only brist på just
		det som gör båset igenkännbart. `ridhus-inne-03`, beskuren: en liten
		mörk trästuga med SADELTAK och utskjutande takfot, på en upphöjd
		nivå, med en trappa som har räcke på BÅDA sidor. ]]
	local D = R.domarbas
	local golv = L.dackZ
	BK.box(model, base, "Domarbåsets nivå", o.x + D.x - (D.b + 1.6) / 2, 0,
		o.y + D.y - (D.b + 1.2) / 2, D.b + 1.6, golv, D.b + 1.2,
		INRE.laktare, Enum.Material.WoodPlanks)
	-- Tonas när det står mellan kameran och spelaren (webben: eget nät med
	-- toningsfotavtryck), som klubbdelens väggar.
	BK.box(model, base, "Domarbås", o.x + D.x - D.b / 2, golv,
		o.y + D.y - D.b / 2, D.b, D.h, D.b,
		Color3.fromRGB(74, 53, 36), Enum.Material.WoodPlanks):SetAttribute("Genomsiktlig", true)
	-- Öppningen mot banan, så att båset inte blir en sluten låda. Banan
	-- ligger på den sida läktaren inte står.
	local dIn = if lE then -1 else 1
	BK.box(model, base, "Domarbåsets öppning",
		o.x + D.x + (if lE then -D.b / 2 - 0.06 else D.b / 2),
		golv + D.h * 0.22, o.y + D.y - D.b * 0.31, 0.06, D.h * 0.62,
		D.b * 0.62, Color3.fromRGB(28, 26, 24),
		Enum.Material.SmoothPlastic).CanCollide = false
	-- Sadeltaket, silhuetten man känner igen båset på.
	local BT = R.basTak
	if BT then
		local bb = D.b + BT.utsprang * 2
		for _, sida in ipairs({ -1, 1 }) do
			local tak = Instance.new("Part")
			tak.Name = "Domarbåsets tak"; tak.Anchored = true
			tak.CanCollide = false
			tak.Color = Color3.fromRGB(58, 42, 28)
			tak.Material = Enum.Material.WoodPlanks
			local sl = math.sqrt((bb / 2) ^ 2 + BT.resning ^ 2)
			tak.Size = Vector3.new(BK.M * sl, BK.M * 0.09, BK.M * bb)
			tak.CFrame = base
				* CFrame.new(BK.M * (o.x + D.x + sida * bb / 4),
					BK.M * (golv + D.h + BT.resning / 2),
					BK.M * (o.y + D.y))
				* CFrame.Angles(0, 0, -sida * math.atan2(BT.resning, bb / 2))
			tak.Parent = model
		end
	end
	-- Trappan upp, med räcke på BÅDA sidor.
	if D.trappa then
		local st, sd = 5, 0.30
		local sh = golv / st
		local z0 = D.y + D.b / 2 + 0.35
		for i = 0, st - 1 do
			BK.box(model, base, "Domarbåsets trappsteg",
				o.x + D.x - 0.5, sh * i, o.y + z0 + sd * i, 1.0, sh + 0.02, sd,
				INRE.laktare, Enum.Material.WoodPlanks)
		end
		for _, sx in ipairs({ -0.52, 0.52 }) do
			for i = 0, st - 1, 2 do
				BK.box(model, base, "Domarbåsets räcke",
					o.x + D.x + sx - 0.035, sh * i, o.y + z0 + sd * i,
					0.07, golv * 0.55 + 0.32, 0.07,
					Color3.fromRGB(138, 106, 68),
					Enum.Material.Wood).CanCollide = false
			end
		end
	end
	if D.exit then
		local skylt = BK.box(model, base, "Exit-skylt",
			o.x + D.x + dIn * (D.b / 2 + 0.05) - 0.03,
			golv + D.h + 0.20, o.y + D.y - 0.25, 0.06, 0.22, 0.5,
			Color3.fromRGB(46, 160, 84), Enum.Material.Neon)
		skylt.CanCollide = false
	end

	--[[ Klockan vid "centrala trappan" är borta: den var en dubblett av
		C-blockets klocka, som sitter mellan de två trapporna. Granskningen
		2026-08-31 såg en enda klocka i alla bilder. ]]

	--[[ ENTRÉDELEN ur planen — samma schema och samma byggare som stallets
		klubbdel: väggar i bitar med planens luckor, slutna rum som volymer,
		namngivna gångbara rum som etikettplattor. ]]
	if R.entrehall then
		local Y = YTOR.ridhusEntre
		local E = R.entre or R.cafe.djup
		local gp = BK.box(model, base, "Ridhusentre matt golv", o.x + 0.2, 0.02, o.y + R.langd - E + 0.2,
			R.bredd - 0.4, 0.004, E - 0.4, Y.farg, Enum.Material.SmoothPlastic)
		gp.CanCollide = false
		gp:SetAttribute("Ytfinish", Y.typ)
		gp:SetAttribute("Kalla", Y.kalla)
		gp:SetAttribute("FargKlass", Y.fargKlass)
		byggVaggarOchRum(model, base, o, R.tak, R.entrehall, "Entrévägg", INRE.vagg)
		--[[ FASADENS DÖRRAR INIFRÅN (PO 2026-09-04 07:54, blocker 2): huvudentrén i
			västväggen (dorrvit u 9), gavlarnas dörrar — dörrblad, vitt foder,
			glasrutor i dubbeldörren och grön utrymningsskylt på insidan av
			väggen (IMG_0169-f05, ridhus-klubb-03/-19). Samma tecknare som
			webbens v3dDorrarInifran; u räknas moturs som i G.byggnader. ]]
		do
			local hus
			for _, b in ipairs(G.byggnader) do if b.id == "ridhus" then hus = b end end
			local FARG = { dorr = Color3.fromRGB(26, 26, 28), dorrgul = Color3.fromRGB(168, 118, 80), dorrvit = Color3.fromRGB(232, 226, 212),
				dorrgra = Color3.fromRGB(162, 164, 166), dorrmork = Color3.fromRGB(70, 63, 56) }
			local V = Color3.fromRGB(238, 236, 228)
			local ut = 0.14
			for _, op in ipairs((hus and hus.oppningar) or {}) do
				if FARG[op.typ] and (op.z0 or 0) <= 0.5 then
					-- lokal ram: (cx, cy) dörrens mitt på insidan, `langsX` = dörren ligger längs x
					local langsX = op.sida == "N" or op.sida == "S"
					local cx, cy, inn
					if op.sida == "W" then cx, cy, inn = ut, R.langd - op.u - op.b / 2, 1
					elseif op.sida == "N" then cx, cy, inn = R.bredd - op.u - op.b / 2, R.langd - ut, -1
					elseif op.sida == "S" then cx, cy, inn = op.u + op.b / 2, ut, 1
					else cx, cy, inn = R.bredd - ut, op.u + op.b / 2, -1 end
					local namn = "Fasaddörr inifrån " .. op.sida .. " u" .. tostring(op.u)
					local function del(suffix, du, z0, dz, w, hh, d, farg, mat)
						-- du längs dörren, dz inåt från väggens insida
						local x = if langsX then cx + du - w / 2 else cx + inn * dz - d / 2
						local y = if langsX then cy + inn * dz - d / 2 else cy + du - w / 2
						local q = BK.box(model, base, namn .. suffix, x, z0, y, if langsX then w else d, hh, if langsX then d else w, farg, mat)
						q.CanCollide = false
						return q
					end
					del(" blad", 0, 0, 0.03, op.b, op.h, 0.06, FARG[op.typ], Enum.Material.SmoothPlastic)
					local tj = 0.12
					del(" foder topp", 0, op.h, 0.04, op.b + 2 * tj, tj, 0.07, V, Enum.Material.SmoothPlastic)
					del(" foder V", -(op.b + tj) / 2, 0, 0.04, tj, op.h + tj, 0.07, V, Enum.Material.SmoothPlastic)
					del(" foder H", (op.b + tj) / 2, 0, 0.04, tj, op.h + tj, 0.07, V, Enum.Material.SmoothPlastic)
					if op.typ == "dorrvit" then
						for _, sd in ipairs({ -1, 1 }) do
							local g = del(" glas", sd * op.b * 0.24, op.h * 0.61, 0.06, op.b * 0.30, op.h * 0.22, 0.02, Color3.fromRGB(58, 74, 92), Enum.Material.Glass)
							g.Transparency = 0.3
						end
						del(" mittpost", 0, op.h * 0.04, 0.06, 0.05, op.h * 0.92, 0.05, V, Enum.Material.SmoothPlastic)
						del(" handtag", op.b * 0.07, 0.9, 0.08, 0.05, 0.30, 0.04, Color3.fromRGB(196, 199, 201), Enum.Material.Metal)
					else
						del(" handtag", op.b * 0.34, 0.97, 0.08, 0.05, 0.16, 0.05, Color3.fromRGB(196, 199, 201), Enum.Material.Metal)
					end
					local sk = del(" utrymningsskylt", 0, op.h + tj + 0.14, 0.05, 0.32, 0.16, 0.03, Color3.fromRGB(30, 154, 74), Enum.Material.Neon)
					sk.Transparency = 0.1
					del(" utrymningsskylt piktogram", 0, op.h + tj + 0.17, 0.07, 0.20, 0.10, 0.01, Color3.fromRGB(232, 245, 236), Enum.Material.SmoothPlastic)
				end
			end
		end
	end

	--[[ F02-B: det som stod framme på banan fanns bara i webben — hindren,
		konerna och uppsittningspallen (RIDHUSINNE.hinder/koner/pall, ur
		interiörfotona; lägena är ASSUMPTION). Nu samma tal här. ]]
	for i, h in ipairs(R.hinder or {}) do
		local bx, bz = o.x + R.bana.x + h.x, o.y + R.bana.y + h.y
		local bomFarg = if h.farg == "bla" then Color3.fromRGB(58, 110, 165) else Color3.fromRGB(192, 57, 43)
		for _, s in ipairs({ -1, 1 }) do
			BK.box(model, base, "Hinderstöd " .. i .. (if s < 0 then " V" else " H"),
				bx + s * h.b / 2 - 0.05, 0, bz - 0.05, 0.10, 1.5, 0.10,
				Color3.fromRGB(240, 237, 230), Enum.Material.SmoothPlastic)
		end
		BK.box(model, base, "Hinderbom " .. i,
			bx - h.b / 2, math.max(0.02, h.h), bz - 0.045, h.b, 0.09, 0.09,
			bomFarg, Enum.Material.SmoothPlastic).CanCollide = false
	end
	for i, k in ipairs(R.koner or {}) do
		BK.box(model, base, "Kon " .. i,
			o.x + R.bana.x + k[1] - 0.15, 0, o.y + R.bana.y + k[2] - 0.15, 0.30, 0.45, 0.30,
			Color3.fromRGB(232, 228, 218), Enum.Material.SmoothPlastic).CanCollide = false
	end
	if R.pall then
		BK.box(model, base, "Uppsittningspall",
			o.x + R.bana.x + R.pall.x - 0.45, 0, o.y + R.bana.y + R.pall.y - 0.5, 0.9, 0.57, 1.0,
			Color3.fromRGB(196, 168, 126), Enum.Material.Wood)
	end
	--[[ Lysrörsraderna längs hallen (RIDHUSINNE.lysror): VERIFIED att de
		finns och löper längs; delningen är ASSUMPTION. Delat tal nu. ]]
	if R.lysror then
		local ly = R.lysror
		local n = 0
		for _, andel in ipairs(ly.andelar) do
			local x = R.bredd * andel
			local y = 4
			while y < R.langd - 2 do
				n += 1
				BK.box(model, base, "Lysrör " .. n,
					o.x + x - ly.bredd / 2, R.tak - ly.underTak, o.y + y - ly.langd / 2, ly.bredd, 0.08, ly.langd,
					ly.farg, Enum.Material.Neon).CanCollide = false
				y += ly.delning
			end
		end
	end

	-- Inredningen ur G.inredning.ridhus (F02-B): speglarna, hinderupplaget på
	-- läktardäcket, skåpkorridorens skåp och stolar, entréns bänk.
	byggInredning(model, base, o, G.inredning and G.inredning.ridhus, "Inredning")
end

local model, base = BK.newBuilding("UBRF", Vector3.new(0, 0, 0), 0, {
	Referens = "references/SITEPLAN.md",
	Geometri = "roblox/buildings/UBRFKomplex.luau (genererad ur src/site.js)",
})

byggMark(model, base)
for _, b in ipairs(G.byggnader) do byggHus(model, base, b) end
byggStallInre(model, base)
byggRidhusInre(model, base)
byggStallIdentitet(model, base)
byggRidhusIdentitet(model, base)
byggStaket(model, base)
byggMaster(model, base)
byggDorrmarkorer(model, base)

print(("OK UBRF byggd: %d byggnader, %d dörrar, %d boxrader, %d gångytor, %d objekt")
	:format(#G.byggnader, #G.dorrar, #G.stall.rader, #G.stall.gangytor,
		#model:GetDescendants()))

-- Ankomstvyn: stå på grusplanen vid de norra gavlarna och titta söderut mot
-- hästgången, samma vy som webbversionen verifieras mot. Husen ska läsa som
-- ETT komplex härifrån, inte som två fristående lador.
-- BK.cameraLike(base, 148, 130, 148, 106)



Vyer.lista()
QAPanel.start(Vyer)
local __qaOk = pcall(function()
	_G.UBRFQA = function() QAPanel.start(Vyer) end
end)
print(__qaOk
	and "Skriv UBRFQA() i Command Bar for att oppna panelen igen."
	or "UBRFQA() gick inte att registrera — kor om paketet for att oppna panelen.")
