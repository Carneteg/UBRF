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

local model, base = BK.newBuilding("UBRF", Vector3.new(0, 0, 0), 0, {
	Referens = "references/SITEPLAN.md",
	Geometri = "roblox/buildings/UBRFKomplex.luau (genererad ur src/site.js)",
})

byggMark(model, base)
for _, b in ipairs(G.byggnader) do byggHus(model, base, b) end
byggDorrmarkorer(model, base)

print(("OK UBRF byggd: %d byggnader, %d dörrar, %d objekt")
	:format(#G.byggnader, #G.dorrar, #model:GetDescendants()))

-- Ankomstvyn: stå på grusplanen vid de norra gavlarna och titta söderut mot
-- hästgången, samma vy som webbversionen verifieras mot. Husen ska läsa som
-- ETT komplex härifrån, inte som två fristående lador.
-- BK.cameraLike(base, 148, 130, 148, 106)
