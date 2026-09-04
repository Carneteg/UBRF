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
		local G2 = S.gaveloppning
		BK.box(model, base, "Gaveldagsljus",
			o.x + G2.x, 0, o.y - 0.02, G2.bredd, G2.hojd, 0.10,
			Color3.fromRGB(234, 242, 246),
			Enum.Material.SmoothPlastic).CanCollide = false
		BK.box(model, base, "Exitskylt syd",
			o.x + G2.x + G2.bredd / 2 - G2.exitB / 2, G2.hojd + G2.exitOver,
			o.y + 0.06, G2.exitB, G2.exitH, 0.06,
			Color3.fromRGB(30, 122, 60), Enum.Material.Neon).CanCollide = false
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
	local L = R.laktare
	local FR = G.identitet.ridhus.laktarfront and G.identitet.ridhus.laktarfront.farg
	--[[ Fronten står mot BANAN. Däcket löper från x0 i positiv x-led på
		båda sidor (se site.js), så med läktaren i väster är fronten vid
		x0 + dackDjup. Skrivet som "x0 − 0,10" stod den mot ytterväggen efter
		speglingen 2026-09-03. ]]
	local lE = R.sidor and R.sidor.laktare == "E"
	local frontX = if lE then L.x0 else L.x0 + L.dackDjup
	local bakX = if lE then L.x0 + L.dackDjup else L.x0
	for s, sek in ipairs(GEO.laktarSektioner(L)) do
		local dj = sek.y1 - sek.y0
		BK.box(model, base, "Läktardäck " .. s,
			o.x + L.x0, L.dackZ, o.y + sek.y0, L.dackDjup, 0.10, dj,
			INRE.laktare, Enum.Material.WoodPlanks)
		-- Solid front mot banan, upp till kappregeln.
		BK.box(model, base, "Läktarfront " .. s,
			o.x + (if lE then frontX - 0.10 else frontX), 0, o.y + sek.y0, 0.10, L.frontTopp, dj,
			FR or INRE.laktare, Enum.Material.WoodPlanks)
		BK.box(model, base, "Läktarkapp " .. s,
			o.x + (if lE then frontX - 0.14 else frontX - 0.04), L.frontTopp, o.y + sek.y0, 0.18, L.kappH, dj,
			Color3.fromRGB(201, 188, 164), Enum.Material.WoodPlanks)
		-- Stomme under däcket, så att det inte svävar.
		BK.box(model, base, "Läktarstomme " .. s,
			o.x + (if lE then bakX - 0.3 else bakX + 0.18), 0, o.y + sek.y0, 0.12, L.dackZ, dj,
			INRE.laktare, Enum.Material.Wood).CanCollide = false
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
				BK.box(model, base, "Trappa " .. t.id .. " räckesstolpe " .. i,
					o.x + px - 0.03, st.z, o.y + pz - 0.03, 0.06, 0.95, 0.06,
					Color3.fromRGB(138, 106, 68), Enum.Material.Wood).CanCollide = false
			end
			local am, zm = (a0 + a1) / 2, (t.z0 + t.z1) / 2
			local function sned(namn, h, dz, farg, mat)
				local d = BK.box(model, base, namn, 0, 0, 0, 0.06, h, 0.06, farg, mat)
				d.CanCollide = false
				if langsX then
					d.Size = Vector3.new(BK.M * L, BK.M * h, BK.M * 0.05)
					d.CFrame = base * CFrame.new(BK.M * (o.x + am), BK.M * (zm + dz), BK.M * (o.y + sx)) * CFrame.Angles(0, 0, lut)
				else
					d.Size = Vector3.new(BK.M * 0.06, BK.M * h, BK.M * L)
					d.CFrame = base * CFrame.new(BK.M * (o.x + sx), BK.M * (zm + dz), BK.M * (o.y + am)) * CFrame.Angles(-lut, 0, 0)
				end
			end
			sned("Trappa " .. t.id .. " handledare", 0.06, 0.95, Color3.fromRGB(138, 106, 68), Enum.Material.Wood)
			if langsX then
				sned("Trappa " .. t.id .. " sidostycke", 0.90, 0.45, Color3.fromRGB(233, 229, 220), Enum.Material.Plaster)
			end
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
		byggVaggarOchRum(model, base, o, R.tak, R.entrehall, "Entrévägg", INRE.vagg)
	end
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
