--!strict
--[[
	Granskning — F02:s granskningsläge för Studio. Fas 1: skal och gränser.

	Tobias ska kunna se den rumsliga modellen utan att slåss med tak, väggar
	eller kamera: dollhouse (tak av), zonplattor med källklass i färg, och en
	rum-för-rum-panel byggd på F01-panelens fail-closed-navigering.

	INGENTING här är spelinnehåll. Modulen följer med i Studio-paketet, aldrig
	i roblox/src/client/, och QAPanel vägrar redan utanför Studio.

	Zonerna HÄRLEDS ur UBRFKomplex — ingen egen kopia av ett enda mått. En zon
	som saknas i källdatan finns inte här heller; en lucka visas som lucka.
]]

local Granskning = {}

--[[ Källklasserna ur gate-dokumentet. GAP betyder REFERENCE GAP. ]]
local KLASSFARG: { [string]: Color3 } = {
	PLAN = Color3.fromRGB(212, 175, 55),
	FOTO = Color3.fromRGB(88, 160, 96),
	DERIVED = Color3.fromRGB(96, 130, 180),
	GAP = Color3.fromRGB(190, 70, 60),
}

--[[ Byggd yta tonas ner; obyggd lyser. Det som ska dra ögat i Fas 1 är det
     som INTE stämmer med planen, inte det som redan står. ]]
local function zonTransparens(byggd: boolean): number
	return if byggd then 0.75 else 0.35
end

export type Zon = {
	id: string,
	namn: string,
	hus: string, -- "stall" | "ridhus"
	klass: string, -- PLAN | FOTO | DERIVED | GAP
	byggd: boolean,
	kalla: string,
	-- Lokal rekt i husets interiörkoordinater. nil = zonen har ingen
	-- ritbar yta (t.ex. en hel obyggd våning) och finns bara i panelen.
	rekt: { x: number, y: number, w: number, h: number }?,
	-- 2 = stallets övervåning; plattan ritas på övervåningshöjd.
	niva: number?,
	--[[ "planrum" = en enskild rumsgräns läst ur planen. "aggregat" = en
	     sammanfattande QA-zon (boxhallen, banan, läktarbandet …). Bara
	     planrum får spökväggar; ett aggregat är inte en fysisk vägg och
	     får inte se ut som en. ]]
	ursprung: string?,
}

function Granskning.zoner(K, Planrum): { Zon }
	local S = K.stall
	local R = K.ridhus
	local ut: { Zon } = {}
	local function zon(z: Zon)
		z.ursprung = z.ursprung or "aggregat"
		table.insert(ut, z)
	end

	-- ── STALLET ──────────────────────────────────────────────────────
	zon({ id = "stall_boxhall", namn = "Boxhallen", hus = "stall",
		klass = "PLAN", byggd = true,
		kalla = "stall-plan1-utrymning-rak.jpg, dubbelt avläst (PLAN1-OMMATNING)",
		rekt = { x = 0, y = S.boxStartY, w = S.bredd, h = S.klubbY - S.boxStartY } })

	for namn, g in pairs(S.gangar) do
		zon({ id = "stall_gang_" .. namn, namn = "Gång " .. namn, hus = "stall",
			klass = "PLAN", byggd = true,
			kalla = "banden i PLAN1-OMMATNING: gångarna ≈ 2/3 av boxdjupet",
			rekt = { x = g.x0, y = S.boxStartY, w = g.x1 - g.x0, h = S.klubbY - S.boxStartY } })
	end

	zon({ id = "stall_tvargang", namn = "Tvärkorridoren", hus = "stall",
		klass = "PLAN", byggd = true,
		kalla = "utrymningsvägen västerut mitt på planen; hästgången mynnar här",
		rekt = { x = 0, y = S.tvarGang.y0, w = S.bredd, h = S.tvarGang.y1 - S.tvarGang.y0 } })

	zon({ id = "stall_klubbdel", namn = "Klubbdelen", hus = "stall",
		klass = "PLAN", byggd = true,
		kalla = "väggtätheten vid norra gaveln; gränsen klubbY är DERIVED",
		rekt = { x = 0, y = S.klubbY, w = S.bredd, h = S.langd - S.klubbY } })

	for _, r in ipairs(S.rum) do
		zon({ id = "stall_rum_" .. r.id, namn = r.label, hus = "stall",
			klass = "DERIVED", byggd = true,
			kalla = "gränser satta före F02 — kvitteras mot planens rumsgränser",
			rekt = { x = r.rekt.x, y = r.rekt.y, w = r.rekt.w, h = r.rekt.h } })
	end

	zon({ id = "stall_servicedel", namn = "Servicedelen", hus = "stall",
		klass = "PLAN", byggd = true,
		kalla = "rumszonen vid södra gaveln; funktioner utöver spolspilta/spånförråd är GAP",
		rekt = { x = 0, y = 0, w = S.bredd, h = S.boxStartY } })

	for _, r in ipairs(S.service) do
		zon({ id = "stall_service_" .. r.id, namn = r.label, hus = "stall",
			klass = "FOTO", byggd = true,
			kalla = "stall-gang-*.jpg, INTERIOR-MATRIS.md",
			rekt = { x = r.rekt.x, y = r.rekt.y, w = r.rekt.w, h = r.rekt.h } })
	end

	zon({ id = "stall_rak_trappa", namn = "Raka trappan i klubbdelen", hus = "stall",
		klass = "GAP", byggd = false,
		kalla = "skrafferad i plan 1 — läge oläst, INTE byggd" })

	zon({ id = "stall_plan2", namn = "Plan 2 — hela övervåningen", hus = "stall",
		klass = "GAP", byggd = false,
		kalla = "Plan 2 i planfotot: korridor, rum, trappa. Ingenting byggt" })

	-- ── RIDHUSET ─────────────────────────────────────────────────────
	zon({ id = "ridhus_bana", namn = "Banan 20 × 60", hus = "ridhus",
		klass = "PLAN", byggd = true,
		kalla = "Tobias bekräftelse + planförhållandet 3,022:1 (RIDHUS-PLANMATNING)",
		rekt = { x = R.bana.x, y = R.bana.y, w = R.bana.w, h = R.bana.h } })

	zon({ id = "ridhus_laktarzon", namn = "Läktarbandet", hus = "ridhus",
		klass = "PLAN", byggd = true,
		kalla = "planens band 0–14,5 % av bredden, fem linjer i tvärsnitt",
		rekt = { x = R.laktare.x0, y = R.laktare.y0,
			w = R.bredd - R.laktare.x0, h = R.laktare.y1 - R.laktare.y0 } })

	--[[ Entrédelen: planens tydligaste OBYGGDA zon. Reserverad i datan
	     (entre), full av rum i planen, tom i spelet. Det här är plattan som
	     ska lysa. ]]
	zon({ id = "ridhus_entredel", namn = "Entrédelen — rum, korridor, trappor", hus = "ridhus",
		klass = "PLAN", byggd = false,
		kalla = "RIDHUS-PLANMATNING: 15,1 % av längden, full av rum, minst två trappor. INTE byggd",
		rekt = { x = 0, y = R.langd - R.entre, w = R.bredd, h = R.entre } })

	zon({ id = "ridhus_cafe_krubban", namn = "Café Krubban — annexets interiör", hus = "ridhus",
		klass = "GAP", byggd = false,
		kalla = "ridhus-gavel-*.jpg, KORT.md: tvåvåningsannex. Interiören obyggd" })

	--[[ De digitaliserade planrummen. Gräns = PLAN, funktion = GAP; inget av
	     dem är byggt, så alla lyser. Rum utan rekt (perspektivolösta) följer
	     med som poster utan platta. ]]
	if Planrum then
		for _, r in ipairs(Planrum.lista) do
			--[[ Meter räknas fram ur normaliserade planandelar, och klassen
			     följer med: ASSUMED_SCALE, inte PLAN. Planens proportioner är
			     belagda; dess meterskala är det inte. ]]
			local rekt, skalklass = Planrum.meter(r)
			zon({ id = r.id, namn = r.namn, hus = r.hus, klass = r.klass,
				byggd = false, niva = r.niva, rekt = rekt,
				ursprung = "planrum",
				kalla = r.kalla .. " · " .. skalklass })
		end
	end

	return ut
end

--[[ ── Zonplattor ──────────────────────────────────────────────────────── ]]

local MAPPNAMN = "F02Zoner"

function Granskning.byggZoner(BK, K, Planrum, model: Model, base: CFrame)
	local gammal = model:FindFirstChild(MAPPNAMN)
	if gammal then gammal:Destroy() end
	local mapp = Instance.new("Folder")
	mapp.Name = MAPPNAMN
	mapp.Parent = model

	local antal = 0
	for _, z in ipairs(Granskning.zoner(K, Planrum)) do
		if z.rekt then
			local o = K[z.hus].origo
			-- Övervåningens plattor ritas strax över stallets takhöjd så att
			-- plan 1 och plan 2 går att skilja åt i dollhouse-läget.
			local hojd = if (z.niva or 1) >= 2 then (K[z.hus].tak or 3.4) + 0.4 else 0.12
			local p = BK.box(mapp :: any, base, "F02 " .. z.id,
				o.x + z.rekt.x, hojd, o.y + z.rekt.y,
				z.rekt.w, 0.06, z.rekt.h,
				KLASSFARG[z.klass] or KLASSFARG.GAP, Enum.Material.Neon)
			p.CanCollide = false
			p.Transparency = zonTransparens(z.byggd)
			p:SetAttribute("RoomId", z.id)
			p:SetAttribute("EvidenceClass", z.klass)
			p:SetAttribute("Byggd", z.byggd)
			p:SetAttribute("Niva", z.niva or 1)

			-- RoomId ska gå att läsa i översiktsvyn utan att klicka.
			local gui = Instance.new("SurfaceGui")
			gui.Name = "F02Etikett"
			gui.Face = Enum.NormalId.Top
			gui.Parent = p
			local text = Instance.new("TextLabel")
			text.Size = UDim2.new(1, 0, 1, 0)
			text.BackgroundTransparency = 1
			text.TextScaled = true
			text.Text = z.id
			text.TextColor3 = Color3.fromRGB(20, 20, 20)
			text.Parent = gui

			antal += 1
		end
	end
	print(string.format("[F02] %d zonplattor byggda i %s", antal, MAPPNAMN))
	return antal
end

--[[ ── Granskningsväggar ──────────────────────────────────────────────────

	Zonplattor visar VAR ett rum ligger men inte att det har väggar. Tobias
	ska kunna säga "den här väggen sitter fel", och det går inte mot en platt
	färgruta. Varje ritbar zon får därför en tunn kontur — fyra liggande
	balkar runt rektangeln — i zonens källfärg.

	Det här är ANNOTERING, inte byggnad. Allt hamnar i F02ReviewGeometry,
	allt är CanCollide = false, och ingenting befordras till spelgeometri
	förrän Tobias accepterat topologin. ]]

local VAGGMAPP = "F02ReviewGeometry"

--[[ Spöklagret. FYRA SKILDA SORTER, för de betyder olika saker:

       · SKILJEVAGG  — en rumsgräns läst ur planen. Bara planrum får sådana.
       · ZONGRANS    — en sammanfattande QA-zon (boxhallen, banan, läktaren).
                       Får golvmarkering, ALDRIG vägg: källan bär ingen vägg
                       där, och en vägg som ser ut som en vägg påstår en.
       · TRAPPA      — fotavtryck, inte kontur.
       · OPPNING     — dörrläge ur Planoppning, bara där läget är mätt.

     Skiljeväggarna DEDUPLICERAS. Två rum som delar en gräns ritade förut var
     sin vägg på samma ställe, och räkningen såg dubbelt så stor ut som
     underlaget. Nyckeln är (hus, nivå, riktning, fast koordinat, från, till)
     avrundad till 5 cm.
]]
function Granskning.skiljevaggar(K, Planrum)
	local segment: { [string]: any } = {}
	local ordning: { string } = {}
	local function lagg(hus, niva, riktning, fast, a0, a1, klass, romid)
		if a1 - a0 < 0.05 then return end
		local nyckel = string.format("%s|%d|%s|%.2f|%.2f|%.2f",
			hus, niva, riktning, fast, a0, a1)
		if segment[nyckel] then
			table.insert(segment[nyckel].rum, romid)
			return
		end
		segment[nyckel] = { hus = hus, niva = niva, riktning = riktning,
			fast = fast, a0 = a0, a1 = a1, klass = klass, rum = { romid } }
		table.insert(ordning, nyckel)
	end

	for _, z in ipairs(Granskning.zoner(K, Planrum)) do
		if z.rekt and z.ursprung == "planrum" then
			local r, n = z.rekt, z.niva or 1
			lagg(z.hus, n, "x", r.y, r.x, r.x + r.w, z.klass, z.id)
			lagg(z.hus, n, "x", r.y + r.h, r.x, r.x + r.w, z.klass, z.id)
			lagg(z.hus, n, "y", r.x, r.y, r.y + r.h, z.klass, z.id)
			lagg(z.hus, n, "y", r.x + r.w, r.y, r.y + r.h, z.klass, z.id)
		end
	end

	local ut = {}
	for _, nyckel in ipairs(ordning) do table.insert(ut, segment[nyckel]) end
	return ut
end

function Granskning.byggVaggar(BK, K, Planrum, model: Model, base: CFrame, Planoppning)
	local gammal = model:FindFirstChild(VAGGMAPP)
	if gammal then gammal:Destroy() end
	local mapp = Instance.new("Folder")
	mapp.Name = VAGGMAPP
	mapp.Parent = model

	local T, H = 0.12, 1.9   -- konturtjocklek och höjd, båda granskningsvärden
	local vaggar, zongranser, trappor, oppningar = 0, 0, 0, 0

	local function golvhojd(hus, niva)
		return if (niva or 1) >= 2 then (K[hus].tak or 3.4) + 0.4 else 0.15
	end

	-- ── SKILJEVAGG: bara planrum, deduplicerade ──────────────────────
	for i, seg in ipairs(Granskning.skiljevaggar(K, Planrum)) do
		local o = K[seg.hus].origo
		local g = golvhojd(seg.hus, seg.niva)
		local f = KLASSFARG[seg.klass] or KLASSFARG.GAP
		local x, z, sx, sz
		if seg.riktning == "x" then
			x, z, sx, sz = seg.a0, seg.fast - T / 2, seg.a1 - seg.a0, T
		else
			x, z, sx, sz = seg.fast - T / 2, seg.a0, T, seg.a1 - seg.a0
		end
		local p = BK.box(mapp :: any, base,
			string.format("F02skiljevagg %d", i),
			o.x + x, g, o.y + z, sx, H, sz, f, Enum.Material.SmoothPlastic)
		p.CanCollide = false
		p.Transparency = 0.35
		p:SetAttribute("F02Review", true)
		p:SetAttribute("F02Sort", "SKILJEVAGG")
		p:SetAttribute("EvidenceClass", seg.klass)
		p:SetAttribute("RoomId", seg.rum[1])
		p:SetAttribute("DelasAv", #seg.rum)
		vaggar += 1
	end

	-- ── ZONGRANS: aggregat får golv, aldrig vägg ─────────────────────
	for _, z in ipairs(Granskning.zoner(K, Planrum)) do
		if z.rekt and z.ursprung ~= "planrum" then
			local o = K[z.hus].origo
			local p = BK.box(mapp :: any, base, "F02zongrans " .. z.id,
				o.x + z.rekt.x, golvhojd(z.hus, z.niva) - 0.05, o.y + z.rekt.y,
				z.rekt.w, 0.04, z.rekt.h,
				KLASSFARG[z.klass] or KLASSFARG.GAP, Enum.Material.SmoothPlastic)
			p.CanCollide = false
			p.Transparency = 0.82
			p:SetAttribute("F02Review", true)
			p:SetAttribute("F02Sort", "ZONGRANS")
			p:SetAttribute("RoomId", z.id)
			zongranser += 1
		end

		-- ── TRAPPA: fotavtryck, inte kontur ──────────────────────────
		if z.rekt and string.find(z.id, "trapp") then
			local o = K[z.hus].origo
			local p = BK.box(mapp :: any, base, "F02trappa " .. z.id,
				o.x + z.rekt.x + T, golvhojd(z.hus, z.niva), o.y + z.rekt.y + T,
				z.rekt.w - 2 * T, 0.05, z.rekt.h - 2 * T,
				Color3.fromRGB(240, 240, 240), Enum.Material.Neon)
			p.CanCollide = false
			p.Transparency = 0.4
			p:SetAttribute("F02Review", true)
			p:SetAttribute("F02Sort", "TRAPPA")
			p:SetAttribute("RoomId", z.id)
			trappor += 1
		end
	end

	-- ── OPPNING: bara där läget faktiskt är mätt ─────────────────────
	if Planoppning then
		for _, op in ipairs(Planoppning.lista) do
			local langs = Planoppning.meter(op, Planrum and Planrum.SKALA)
			local K2 = K[op.hus]
			if langs and K2 then
				local o = K2.origo
				local vx = if op.vagg == "V" then 0 else K2.bredd
				local p = BK.box(mapp :: any, base, "F02oppning " .. op.id,
					o.x + vx - 0.3, golvhojd(op.hus, 1), o.y + langs - 0.6,
					0.6, 2.1, 1.2,
					Color3.fromRGB(255, 255, 255), Enum.Material.Neon)
				p.CanCollide = false
				p.Transparency = 0.45
				p:SetAttribute("F02Review", true)
				p:SetAttribute("F02Sort", "OPPNING")
				p:SetAttribute("OpeningId", op.id)
				p:SetAttribute("EvidenceClass", op.klass)
				oppningar += 1
			end
		end
	end

	print(string.format("[F02] spöklager: %d skiljeväggar (unika, deduplicerade), "
		.. "%d zongränser, %d trappor, %d öppningar i %s "
		.. "(CanCollide=false, aldrig spelgeometri)",
		vaggar, zongranser, trappor, oppningar, VAGGMAPP))
	return vaggar, trappor, zongranser, oppningar
end

function Granskning.visaVaggar(model: Model, pa: boolean): number
	local mapp = model:FindFirstChild(VAGGMAPP)
	if not mapp then return 0 end
	local n = 0
	for _, i in ipairs(mapp:GetDescendants()) do
		if i:GetAttribute("F02Review") == true then
			i.Transparency = if pa then 0.35 else 1
			n += 1
		end
	end
	print(string.format("[F02] Granskningsväggar %s: %d delar", if pa then "PÅ" else "AV", n))
	return n
end

--[[ ── Dollhouse ───────────────────────────────────────────────────────────

	Gömmer allt som bär attributet TakDel — sätts av byggarna när taket byggs,
	aldrig gissat på namn i efterhand. Ursprunglig transparens sparas i ett
	attribut så att på/av inte förstör något. ]]

function Granskning.dollhouse(model: Model, av: boolean): number
	local antal = 0
	--[[ Ingen IsA-koll: TakDel sätts bara på Parts av byggarna, och attributet
	     ÄR identiteten här. ]]
	for _, i in ipairs(model:GetDescendants()) do
		if i:GetAttribute("TakDel") == true then
			if av then
				if i:GetAttribute("F02Transparens") == nil then
					i:SetAttribute("F02Transparens", i.Transparency)
				end
				i.Transparency = 1
				i.CanCollide = false
			else
				local t = i:GetAttribute("F02Transparens")
				if typeof(t) == "number" then
					i.Transparency = t
					i:SetAttribute("F02Transparens", nil)
				end
				i.CanCollide = true
			end
			antal += 1
		end
	end
	print(string.format("[F02] Dollhouse %s: %d takdelar", if av then "PÅ" else "AV", antal))
	return antal
end

--[[ ── Vymodul till QAPanel ────────────────────────────────────────────────

	Två kameror per zon med yta: uppifrån och i ögonhöjd, per direktivet.
	Zoner utan yta (Plan 2, caféinteriören) får en panelpost med
	klubb-/gaveldelens kamera och GAP-texten — de ska bedömas som luckor,
	inte glömmas för att de inte går att stå i. ]]

function Granskning.vyModul(BK, K, Planrum, Planoppning)
	local vyer = {}

	--[[ Översikt per våningsplan FÖRST: alla RoomId-plattor i bild samtidigt,
	     så att topologin kan jämföras mot planen innan rum-för-rum-stegningen. ]]
	local oversikter = {
		{ id = "oversikt_ridhus_entre", hus = "ridhus",
			text = "ÖVERSIKT — ridhusets entrédel, alla RoomId samtidigt",
			cx = K.ridhus.bredd / 2, cy = K.ridhus.langd - K.ridhus.entre / 2,
			spann = K.ridhus.bredd + 6 },
		{ id = "oversikt_stall_plan1", hus = "stall",
			text = "ÖVERSIKT — stallets plan 1, alla RoomId samtidigt",
			cx = K.stall.bredd / 2, cy = K.stall.langd / 2,
			spann = K.stall.langd + 8 },
		{ id = "oversikt_stall_plan2", hus = "stall",
			text = "ÖVERSIKT — stallets plan 2 (plattorna på övervåningshöjd)",
			cx = K.stall.bredd / 2, cy = K.stall.klubbY + (K.stall.langd - K.stall.klubbY) / 2,
			spann = (K.stall.langd - K.stall.klubbY) * 2 + 10 },
	}
	for _, ov in ipairs(oversikter) do
		local o = K[ov.hus].origo
		table.insert(vyer, {
			id = ov.id, grupp = ov.hus,
			text = ov.text .. ". [PLAN] Jämför topologin mot planfotot.",
			krav = "Stämmer rumsindelningen som helhet? Peka sedan rum för rum.",
			fran = { x = o.x + ov.cx, y = o.y + ov.cy - 0.1, h = ov.spann },
			mot = { x = o.x + ov.cx, y = o.y + ov.cy },
			aim = 0,
		})
	end

	for _, z in ipairs(Granskning.zoner(K, Planrum)) do
		local o = K[z.hus].origo
		local etikett = string.format("[%s%s] %s", z.klass,
			if z.byggd then "" else " · OBYGGD", z.kalla)

		if not z.rekt then
			--[[ INGEN PÅHITTAD RESERVREKTANGEL. Förut fick varje zon utan
			     mått två kameror riktade mot en godtycklig 10-metersremsa
			     vid gaveln. Texten sa GAP medan bilden pekade ut ett läge och
			     en utsträckning som ingen källa bär — och en kamera som
			     pekar någonstans är ett påstående, hur texten än lyder.

			     Zonen får i stället EN vy: våningsöversikten den hör till,
			     uttryckligen märkt som obedömbar. Panelen vägrar PASS på
			     den (ejBedombar). ]]
			local ov = if z.hus == "stall"
				then (if (z.niva or 1) >= 2 then "oversikt_stall_plan2" else "oversikt_stall_plan1")
				else "oversikt_ridhus_entre"
			local kalla_vy
			for _, kandidat in ipairs(vyer) do
				if kandidat.id == ov then kalla_vy = kandidat break end
			end
			table.insert(vyer, {
				id = z.id .. "_kallgap",
				grupp = z.hus,
				ejBedombar = true,
				text = z.namn .. " — EJ GEOMETRISKT BEDÖMBAR — REFERENCE GAP. "
					.. etikett .. " Kameran visar våningen, inte rummet: "
					.. "källan bär ingen utsträckning att peka på.",
				krav = "Kvittera som GAP. Godkänn ingen geometri som inte finns.",
				fran = kalla_vy and kalla_vy.fran or { x = o.x, y = o.y, h = 60 },
				mot = kalla_vy and kalla_vy.mot or { x = o.x, y = o.y },
				aim = 0,
			})
		else
			local r = z.rekt
			local cx, cy = o.x + r.x + r.w / 2, o.y + r.y + r.h / 2
			--[[ Plan 2:s plattor ritas på övervåningshöjd. En ögonhöjdskamera
			     på 1,7 hade stått på marken och tittat på undersidan av
			     våningen. Golvet läggs därför till. ]]
			local golv = if (z.niva or 1) >= 2 then (K[z.hus].tak or 3.4) + 0.4 else 0.0

			table.insert(vyer, {
				id = z.id .. "_uppifran",
				grupp = z.hus,
				text = z.namn .. " — uppifrån. " .. etikett,
				krav = "Bedöm gränser och läge mot planen, inte ytfinish.",
				fran = { x = cx, y = cy - 0.1, h = golv + math.max(r.w, r.h) + 8 },
				mot = { x = cx, y = cy },
				aim = golv,
			})
			table.insert(vyer, {
				id = z.id .. "_ogonhojd",
				grupp = z.hus,
				text = z.namn .. " — i ögonhöjd. " .. etikett,
				krav = "Cirkulation och dörrlägen: kommer man dit man ska?",
				fran = { x = cx, y = o.y + r.y - 2, h = golv + 1.7 },
				mot = { x = cx, y = cy },
				aim = golv + 1.5,
			})
		end
	end

	--[[ Öppningarna får egna vyer. En dörr som inte går att peka på i
	     granskningen kan inte bedömas, och Acceptance Contract säger
	     uttryckligen dörrlägen. ]]
	if Planoppning then
		for _, op in ipairs(Planoppning.lista) do
			local K2 = K[op.hus]
			local langs = Planoppning.meter(op, Planrum and Planrum.SKALA)
			if K2 then
				local o = K2.origo
				if langs then
					local vx = if op.vagg == "V" then 0 else K2.bredd
					table.insert(vyer, {
						id = op.id,
						grupp = op.hus,
						text = "Öppning " .. op.id .. " — [" .. op.klass .. "] "
							.. op.kalla,
						krav = "Sitter dörren på rätt vägg och rätt ställe längs den?",
						fran = { x = o.x + vx + (if op.vagg == "V" then -8 else 8),
							y = o.y + langs, h = 2.0 },
						mot = { x = o.x + K2.bredd / 2, y = o.y + langs },
						aim = 1.5,
					})
				else
					table.insert(vyer, {
						id = op.id,
						grupp = op.hus,
						ejBedombar = true,
						text = "Öppning " .. op.id
							.. " — EJ GEOMETRISKT BEDÖMBAR — REFERENCE GAP. "
							.. op.kalla,
						krav = "Kvittera som GAP. Väggsidan är läst, läget är det inte.",
						fran = { x = o.x + K2.bredd / 2, y = o.y + K2.langd / 2 - 0.1,
							h = K2.langd + 10 },
						mot = { x = o.x + K2.bredd / 2, y = o.y + K2.langd / 2 },
						aim = 0,
					})
				end
			end
		end
	end

	--[[ Tredje utfallet slås PÅ för F02. F01-panelen rör vi inte. ]]
	local modul = { vyer = vyer, gapKnapp = true }
	function modul.ga(id: string)
		for _, v in ipairs(vyer) do
			if v.id == id then
				local mapp = workspace:FindFirstChild("Anläggning")
				local ubrf = mapp and mapp:FindFirstChild("UBRF")
				local bas = ubrf and (ubrf :: Model).PrimaryPart
					and ((ubrf :: Model).PrimaryPart :: BasePart).CFrame
				if not bas then error("bygg Anlaggningen först") end
				BK.cameraLike(bas, v.fran.x, v.fran.y, v.mot.x, v.mot.y, v.fran.h, v.aim)
				print("── F02: " .. v.text)
				return
			end
		end
		error("okänd F02-vy: " .. id)
	end
	return modul
end

--[[ ── Start ─────────────────────────────────────────────────────────────── ]]

function Granskning.start(BK, K, QAPanel, Planrum, Planoppning, model: Model, base: CFrame)
	Granskning.byggZoner(BK, K, Planrum, model, base)
	Granskning.byggVaggar(BK, K, Planrum, model, base, Planoppning)
	Granskning.dollhouse(model, true)
	QAPanel.start(Granskning.vyModul(BK, K, Planrum, Planoppning))
	print("[F02] Granskningsläge: dollhouse PÅ, zonplattor ute, panelen öppen.")
	print("[F02] UBRFDollhouse(false) sätter tillbaka taken, "
		.. "UBRFVaggar(false) gömmer granskningsväggarna.")
end

return Granskning
