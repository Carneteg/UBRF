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

--[[ Stallet: fyra boxrader, två gångar, tvärkorridor, namngivna rum.

	Raderna och gångarna kommer ur planens mätta andelar (G.stall.band), inte ur
	någon delning gjord här. Ändras STALLINNE.bredd i src/site.js flyttar sig
	allt med, på båda plattformarna samtidigt. ]]
local function byggStallInre(model: Model, base: CFrame)
	local S = G.stall
	local o = S.origo
	local h = S.tak

	-- Gångytorna, inklusive tvärkorridoren. De ligger som eget golv så att man
	-- ser var man kan gå — det är cirkulationen gaten frågar efter.
	for i, g in ipairs(S.gangytor) do
		local p = BK.box(model, base, "Stallgång " .. i,
			o.x + g.x, 0.02, o.y + g.y, g.w, 0.04, g.h, INRE.gang, Enum.Material.Concrete)
		p.CanCollide = false
	end

	-- Boxraderna. Varje rad är en länga av boxar med mellanväggar och en front
	-- mot sin gång; tvärkorridoren lämnas öppen rakt igenom.
	for _, rad in ipairs(S.rader) do
		local x0 = o.x + rad.x0
		-- Facken kommer ur Geometri, som specen mäter. Räknar man ut dem här
		-- mäter specen inte längre det som byggs.
		for i, f in ipairs(GEO.boxfack(S)) do
			-- Skiljevägg i fackets bortre ände.
			BK.box(model, base, "Boxvägg " .. rad.id .. " " .. i,
				x0, 0, o.y + f.y0, rad.djup, h * 0.62, 0.08, INRE.box, Enum.Material.WoodPlanks)
			-- Fronten mot gången, med galler upptill.
			local fx = if rad.vetter > 0 then x0 + rad.djup - 0.06 else x0
			BK.box(model, base, "Boxfront " .. rad.id .. " " .. i,
				fx, 0, o.y + f.y0 + 0.08, 0.06, h * 0.34, S.boxB - 0.16,
				INRE.box, Enum.Material.WoodPlanks)
			BK.box(model, base, "Boxgaller " .. rad.id .. " " .. i,
				fx, h * 0.42, o.y + f.y0 + 0.08, 0.06, h * 0.20, S.boxB - 0.16,
				INRE.front, Enum.Material.DiamondPlate)
			BK.box(model, base, "Boxvägg " .. rad.id .. " " .. i .. "b",
				x0, 0, o.y + f.y1, rad.djup, h * 0.62, 0.08, INRE.box, Enum.Material.WoodPlanks)
		end
	end

	-- Tvärväggarna ur planen, i bitar med dörrgap där gångarna passerar. Den
	-- mot klubbdelen är en branddörrsvägg. En obruten vägg här stänger av
	-- stallgången — byggbänken fällde precis det.
	for i, v in ipairs(S.tvarvaggar) do
		for j, bit in ipairs(GEO.tvarvaggBitar(S)) do
			BK.box(model, base, "Tvärvägg " .. i .. ":" .. j,
				o.x + bit.x0, 0, o.y + v.y, bit.x1 - bit.x0, h, 0.2, INRE.vagg,
				if v.brand then Enum.Material.Concrete else Enum.Material.Plaster)
		end
	end

	-- Namngivna rum och servicedelar. Låga volymer med sitt namn som attribut —
	-- namnen är fidelity-fakta ur utrymningsplanen, inredningen är det inte.
	for _, lista in ipairs({ S.rum, S.service }) do
		for _, r in ipairs(lista) do
			local p = BK.box(model, base, r.label,
				o.x + r.rekt.x, 0, o.y + r.rekt.y, r.rekt.w, h * 0.9, r.rekt.h,
				INRE.rum, Enum.Material.Plaster)
			p.Transparency = 0.45
			p:SetAttribute("Rum", r.id)
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

	-- Ridbanan, 20 × 60.
	local sand = BK.box(model, base, "Ridbanan 20x60",
		o.x + b.x, 0, o.y + b.y, b.w, 0.06, b.h, INRE.sand, Enum.Material.Sand)
	sand.CanCollide = false
	sand:SetAttribute("Matt", "20x60")

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
	-- Norra kortsidan i två stycken: porten är gapet mellan dem, och det är
	-- där A står — se docs/ och src/data.js.
	BK.box(model, base, "Sarg norr väst", o.x + b.x, 0, o.y + b.y + b.h,
		R.port.x0 - b.x, sh, 0.1, INRE.sarg)
	BK.box(model, base, "Sarg norr öst", o.x + R.port.x1, 0, o.y + b.y + b.h,
		b.x + b.w - R.port.x1, sh, 0.1, INRE.sarg)

	-- Läktaren längs östra långsidan, som trappsteg — i sektioner, med
	-- hästgångens öppning bortdragen. Ett obrutet block murar igen gången.
	local L = R.laktare
	for s, sek in ipairs(GEO.laktarSektioner(L)) do
		for i = 1, L.steg do
			BK.box(model, base, "Läktarsteg " .. s .. ":" .. i,
				o.x + L.x0 + (i - 1) * L.stegD, (i - 1) * L.stegH, o.y + sek.y0,
				L.stegD, L.stegH * i + 0.1, sek.y1 - sek.y0,
				INRE.laktare, Enum.Material.WoodPlanks)
		end
	end

	-- Glasade rum bakom sargen, i läktarens liv.
	for i, g in ipairs(R.glasrum) do
		local p = BK.box(model, base, "Glasat rum " .. i,
			o.x + L.x0 - 0.12, 1.0, o.y + g.y0, 0.12, 1.8, g.y1 - g.y0,
			INRE.glas, Enum.Material.Glass)
		p.Transparency = 0.55
	end

	-- Domarbåset vid E, med exit-skylten över öppningen.
	local D = R.domarbas
	BK.box(model, base, "Domarbås", o.x + D.x, 0, o.y + D.y - D.b / 2,
		1.6, D.h, D.b, INRE.laktare, Enum.Material.WoodPlanks)
	if D.exit then
		local skylt = BK.box(model, base, "Exit-skylt", o.x + D.x - 0.1,
			D.h - 0.35, o.y + D.y - 0.25, 0.06, 0.22, 0.5,
			Color3.fromRGB(46, 160, 84), Enum.Material.Neon)
		skylt.CanCollide = false
	end

	-- Klockan vid centrala trappan.
	local K = R.klocka
	local klocka = BK.box(model, base, "Klockan", o.x + K.x - K.r, K.z,
		o.y + K.y - 0.06, K.r * 2, K.r * 2, 0.12,
		Color3.fromRGB(238, 236, 228), Enum.Material.SmoothPlastic)
	klocka.CanCollide = false
end

local model, base = BK.newBuilding("UBRF", Vector3.new(0, 0, 0), 0, {
	Referens = "references/SITEPLAN.md",
	Geometri = "roblox/buildings/UBRFKomplex.luau (genererad ur src/site.js)",
})

byggMark(model, base)
for _, b in ipairs(G.byggnader) do byggHus(model, base, b) end
byggStallInre(model, base)
byggRidhusInre(model, base)
byggDorrmarkorer(model, base)

print(("OK UBRF byggd: %d byggnader, %d dörrar, %d boxrader, %d gångytor, %d objekt")
	:format(#G.byggnader, #G.dorrar, #G.stall.rader, #G.stall.gangytor,
		#model:GetDescendants()))

-- Ankomstvyn: stå på grusplanen vid de norra gavlarna och titta söderut mot
-- hästgången, samma vy som webbversionen verifieras mot. Husen ska läsa som
-- ETT komplex härifrån, inte som två fristående lador.
-- BK.cameraLike(base, 148, 130, 148, 106)
