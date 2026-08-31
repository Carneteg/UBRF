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
}

function Granskning.zoner(K): { Zon }
	local S = K.stall
	local R = K.ridhus
	local ut: { Zon } = {}
	local function zon(z: Zon) table.insert(ut, z) end

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

	return ut
end

--[[ ── Zonplattor ──────────────────────────────────────────────────────── ]]

local MAPPNAMN = "F02Zoner"

function Granskning.byggZoner(BK, K, model: Model, base: CFrame)
	local gammal = model:FindFirstChild(MAPPNAMN)
	if gammal then gammal:Destroy() end
	local mapp = Instance.new("Folder")
	mapp.Name = MAPPNAMN
	mapp.Parent = model

	local antal = 0
	for _, z in ipairs(Granskning.zoner(K)) do
		if z.rekt then
			local o = K[z.hus].origo
			local p = BK.box(mapp :: any, base, "F02 " .. z.id,
				o.x + z.rekt.x, 0.12, o.y + z.rekt.y,
				z.rekt.w, 0.06, z.rekt.h,
				KLASSFARG[z.klass] or KLASSFARG.GAP, Enum.Material.Neon)
			p.CanCollide = false
			p.Transparency = zonTransparens(z.byggd)
			p:SetAttribute("RoomId", z.id)
			p:SetAttribute("EvidenceClass", z.klass)
			p:SetAttribute("Byggd", z.byggd)
			antal += 1
		end
	end
	print(string.format("[F02] %d zonplattor byggda i %s", antal, MAPPNAMN))
	return antal
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

function Granskning.vyModul(BK, K)
	local vyer = {}
	for _, z in ipairs(Granskning.zoner(K)) do
		local o = K[z.hus].origo
		local etikett = string.format("[%s%s] %s", z.klass,
			if z.byggd then "" else " · OBYGGD", z.kalla)
		local r = z.rekt or { x = 0, y = K[z.hus].langd - 10, w = K[z.hus].bredd, h = 10 }
		local cx, cy = o.x + r.x + r.w / 2, o.y + r.y + r.h / 2

		table.insert(vyer, {
			id = z.id .. "_uppifran",
			grupp = z.hus,
			text = z.namn .. " — uppifrån. " .. etikett,
			krav = "Bedöm gränser och läge mot planen, inte ytfinish.",
			fran = { x = cx, y = cy - 0.1, h = math.max(r.w, r.h) + 8 },
			mot = { x = cx, y = cy },
			aim = 0,
		})
		table.insert(vyer, {
			id = z.id .. "_ogonhojd",
			grupp = z.hus,
			text = z.namn .. " — i ögonhöjd. " .. etikett,
			krav = "Cirkulation och dörrlägen: kommer man dit man ska?",
			fran = { x = cx, y = o.y + r.y - 2, h = 1.7 },
			mot = { x = cx, y = cy },
		})
	end

	local modul = { vyer = vyer }
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

function Granskning.start(BK, K, QAPanel, model: Model, base: CFrame)
	Granskning.byggZoner(BK, K, model, base)
	Granskning.dollhouse(model, true)
	QAPanel.start(Granskning.vyModul(BK, K))
	print("[F02] Granskningsläge: dollhouse PÅ, zonplattor ute, panelen öppen.")
	print("[F02] UBRFDollhouse(false) sätter tillbaka taken.")
end

return Granskning
