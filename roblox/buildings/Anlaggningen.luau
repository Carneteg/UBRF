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
	local K = I.forstukvist
	local kz = r.y + r.h - K.uFranNorr - K.bredd / 2
	BK.box(model, base, "Förstukvist golv", r.x - K.djup, 0, kz - K.bredd / 2,
		K.djup, 0.14, K.bredd, IDFARG.betong, Enum.Material.Concrete)
	BK.box(model, base, "Förstukvist tak", r.x - K.djup - 0.2, K.takfot,
		kz - K.bredd / 2 - 0.2, K.djup + 0.2, 0.12, K.bredd + 0.4,
		b.fargT or IDFARG.huv, Enum.Material.Metal)
	for _, sida in ipairs({ -1, 1 }) do
		BK.box(model, base, "Förstukvist stolpe", r.x - K.djup + 0.1, 0,
			kz + sida * (K.bredd / 2 - 0.2), 0.15, K.takfot, 0.15,
			IDFARG.vit, Enum.Material.WoodPlanks)
	end
	-- Ribbräcket, med öppningen mitt för dörren.
	local sido = (K.bredd - 0.34 - K.oppning) / 2
	for _, sida in ipairs({ -1, 1 }) do
		BK.box(model, base, "Förstukvist räcke", r.x - K.djup + 0.15, 0.26,
			kz + sida * (K.oppning / 2 + sido / 2) - sido / 2,
			0.06, 1.2, sido, IDFARG.vit, Enum.Material.WoodPlanks)
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

	-- MOTSÄGELSE 1: mörkröd övre långvägg med vita läkt, båda långsidorna.
	local O = I.ovreVagg
	local y0, y1 = R.sargH + O.overSarg, R.tak - O.underTak
	for _, x in ipairs({ 0.16, R.bredd - 0.16 }) do
		BK.box(model, base, "Övre långvägg", o.x + x - O.tjocklek / 2, y0,
			o.y + 0.5, O.tjocklek, y1 - y0, R.langd - 1,
			IDFARG.panel, Enum.Material.Metal)
		for i = 1, O.listar do
			local yy = y0 + 0.25 + (y1 - y0 - 0.5)
				* (if O.listar > 1 then (i - 1) / (O.listar - 1) else 0.5)
			BK.box(model, base, "Väggläkt", o.x + x - 0.05, yy, o.y + 0.5,
				0.10, 0.07, R.langd - 1, IDFARG.list, Enum.Material.SmoothPlastic)
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

		for i = 1, #st.p - 1 do
			local a, b = st.p[i], st.p[i + 1]
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
			o.x + g.x, 0.02, o.y + g.y, g.w, 0.04, g.h, S.gangSten,
			Enum.Material.Pavement)
		p.CanCollide = false
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
		for i, f in ipairs(GEO.boxfack(S)) do
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
		p.Color = SG.takplat; p.Material = Enum.Material.CorrugatedMetal
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

	-- Kortändans läktare: trappstegsblock, två trappor och glasbandet ovanför.
	-- De glasade rummen låg förut längs LÅNGSIDAN, i läktarens liv. Fotot
	-- ridhus-inne-01 visar dem över ett trappstegsblock vid kortändan, och
	-- bokstaven C framför blocket avgör saken: C ligger mitt på en kortsida.
	local K = R.kortanda
	if K then
		local br = K.x1 - K.x0
		for i = 1, K.steg do
			BK.box(model, base, "Kortändans steg " .. i,
				o.x + K.x0, (i - 1) * K.stegH,
				o.y + K.y1 - i * K.stegD, br, K.stegH * i + 0.1, K.stegD,
				INRE.laktare, Enum.Material.WoodPlanks)
		end
		for i, tx in ipairs(K.trappor) do
			BK.box(model, base, "Kortändans trappa " .. i,
				o.x + tx - K.trappB / 2, 0, o.y + K.y0,
				K.trappB, K.steg * K.stegH, K.y1 - K.y0,
				INRE.laktare, Enum.Material.WoodPlanks)
		end
		local glas = BK.box(model, base, "Kortändans glasband",
			o.x + K.x0, K.steg * K.stegH + K.glasOver, o.y + K.y0 - 0.12,
			br, K.glasH, 0.12, INRE.glas, Enum.Material.Glass)
		glas.Transparency = 0.55
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
