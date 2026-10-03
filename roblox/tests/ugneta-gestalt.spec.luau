--[[ UGNETA SOM GESTALT — står hon där, och står hon rätt?

	Blocker 2 i senior review av 09e07da: webben hade fått en igenkännbar
	Ugneta men Roblox bara lärar-UX:en, och Roblox är primär spelplattform.

	Provet körs ovanpå den FÄRDIGBYGGDA anläggningen. Det är hela poängen:
	placeringen räknas ut genom att mäta mellan "Ridbanan" och "Sarg syd",
	alltså mot delar som faktiskt står i workspace. Ett prov mot
	handskrivna koordinater hade mött en andra modell av huset — och två
	uppfattningar om var något står är läktarfelet (#114). ]]

local fel = 0
local function prova(vad, ok, detalj)
	if ok then
		print(("  OK   %s"):format(vad))
	else
		fel += 1
		print(("  FEL  %s — %s"):format(vad, tostring(detalj)))
	end
end

print("\nUGNETA VID SARGEN — GESTALTEN\n")

local anlaggning = workspace:FindFirstChild("Anläggning")
local hus = anlaggning and anlaggning:FindFirstChild("UBRF")
prova("anläggningen är byggd och heter UBRF", hus ~= nil, tostring(hus))

local bana = hus and hus:FindFirstChild("Ridbanan")
local syd = hus and hus:FindFirstChild("Sarg syd")
prova("banan och A-ändens sarg finns att mäta emot",
	bana ~= nil and syd ~= nil,
	("Ridbanan %s · Sarg syd %s"):format(tostring(bana), tostring(syd)))

--[[ INGEN GESTALT INNAN LEKTIONEN. Hon ska inte stå i ridhuset dygnet
	runt; hon hör till lektionen. ]]
prova("hon står inte där innan lektionen börjat", not UgnetaGestalt.finns(),
	tostring(UgnetaGestalt.finns()))

local m = UgnetaGestalt.visa(hus)
prova("hon byggs när lektionen börjar", m ~= nil and UgnetaGestalt.finns(),
	tostring(m))

--[[ IGENKÄNNBAR: grått hår och glasögon är hela skillnaden mot en anonym
	figur i kavaj. Det var precis det blockern gällde. ]]
local har = m and m:FindFirstChild("Grått hår")
local glas = m and m:FindFirstChild("Glasögon")
local ansikte = m and m:FindFirstChild("Ansikte")
prova("hon har grått hår", har ~= nil, tostring(har))
prova("hon har glasögon", glas ~= nil, tostring(glas))
prova("hon har ett ansikte att bära dem på", ansikte ~= nil, tostring(ansikte))

local GRA = Color3.fromRGB(201, 205, 210)
prova("håret är faktiskt grått, inte kavajens färg",
	har ~= nil and math.abs(har.Color.R - GRA.R) < 0.01
		and math.abs(har.Color.G - GRA.G) < 0.01,
	har and ("%.2f/%.2f/%.2f"):format(har.Color.R, har.Color.G, har.Color.B) or "-")

--[[ HON FÅR ALDRIG STOPPA EN HÄST. En instruktör som är ett hinder mitt i
	ridhuset är sämre än ingen instruktör alls. ]]
local kolliderar = false
for _, d in (m and m:GetChildren() or {}) do
	if d.CanCollide then kolliderar = true end
end
prova("ingen del av henne kolliderar", not kolliderar, tostring(kolliderar))

--[[ PLACERINGEN. Hon ska stå bortom dressyrlayoutens C-linje, alltså i
	den zon där den fysiska ridytan fortsätter — inte på dressyrbanan och
	inte utanför huset. Avståndet mäts från A-sargen, samma punkt koden
	själv utgår från. ]]
local M = 3
local P = RidKanon.UGNETA.PLATS
local plats = UgnetaGestalt.plats(hus)
prova("placeringen går att räkna fram ur det byggda", plats ~= nil, tostring(plats))
--[[ #264 INFRA-PLATS1: A mäts från dressyrlayoutens A-kant ur
	`Ridhusplats`, inte från "Sarg syd" — den sågas av södra dörren i bitar,
	och den bit namnet ger ligger vid sidan av mittlinjen. ]]
local rp = Ridhusplats.los(hus)
if plats and rp and bana then
	local fran = plats.pos - rp.dressyr.A
	local langs = fran.X * plats.motC.X + fran.Y * plats.motC.Y + fran.Z * plats.motC.Z
	local vantat = (P.langd + P.bortomC) * M
	prova("hon står bortom C-linjen, på det avstånd kanonen anger",
		math.abs(langs - vantat) < 0.01,
		("%.2f studs från A, väntat %.2f"):format(langs, vantat))

	--[[ …och innanför sargen i andra änden. Banans längd läses ur den
	     byggda delen, inte ur en siffra skriven här. ]]
	local banlangd = math.max(bana.Size.X, bana.Size.Z)
	prova("hon står innanför banans norra sarg, inte i väggen",
		langs < banlangd,
		("%.2f studs från A · banan %.2f studs lång"):format(langs, banlangd))

	prova("hon står på golvet, inte i det",
		math.abs(plats.pos.Y - (bana.Position.Y + bana.Size.Y / 2)) < 0.01,
		("y %.2f mot sandens överkant %.2f"):format(plats.pos.Y,
			bana.Position.Y + bana.Size.Y / 2))
end

--[[ Hon ska bort när lektionen slutar. ]]
UgnetaGestalt.dolj()
prova("hon försvinner när lektionen avbryts", not UgnetaGestalt.finns(),
	tostring(UgnetaGestalt.finns()))

--[[ UTAN BYGGNAD, INGEN GISSNING. Saknas huset ska hon inte hamna på
	(0,0,0) — en figur på en påhittad plats är värre än ingen figur. ]]
prova("utan byggd bana placeras hon inte alls",
	UgnetaGestalt.plats(nil) == nil and UgnetaGestalt.visa(nil) == nil,
	"nil in gav nil ut")

--[[ ══ C2: HON VÄNDER SIG MOT RYTTAREN — docs/INSTRUCTOR-GAZE-CONTRACT.md ══
	SKRIVET FÖR SENARE KÖRNING (bygg nu, testa sist). Inte kört.
	BÄNKANTAGANDE: stubbens CFrame bär ren girning (Yaw) och sätter ihop
	`CFrame.new(p) * CFrame.Angles(0, θ, 0)` till position p och girning θ;
	positionen läses ur `del.CFrame.Position`. ]]
do
	local G = UgnetaGestalt
	local GR = G.GRANSER
	local function yawAv(d) return select(2, d.CFrame:ToOrientation()) end
	local function kort(a) return ((a + math.pi) % (2 * math.pi)) - math.pi end
	local function nara(a, b, tol) return math.abs(kort(a - b)) <= (tol or 1e-6) end
	local function delarna(mm)
		return { mm:FindFirstChild("Kavaj"), mm:FindFirstChild("Ansikte"), mm:FindFirstChild("Grått hår"),
			mm:FindFirstChild("Glasögon") }
	end
	local LOKAL_Y = { 0.55 * M, 0.99 * M, 1.045 * M, 0.985 * M }
	--[[ Alla fyra delar: samma girning, ankare och höjd oförändrade, och
		glasögonen 0,12 m framför ankaret i girningens riktning. ]]
	local function sammanhallen(mm, ankare, th)
		local ds = delarna(mm)
		for i, d in ds do
			if not d then return false, "del saknas" end
			if not nara(yawAv(d), th, 1e-6) then return false, d.Name .. " girning" end
			local p = d.CFrame.Position
			if math.abs(p.Y - (ankare.Y + LOKAL_Y[i])) > 1e-6 then return false, d.Name .. " höjd" end
			local fram = if i == 4 then 0.12 * M else 0
			local vx, vz = ankare.X + math.sin(th) * fram, ankare.Z + math.cos(th) * fram
			if math.abs(p.X - vx) > 1e-6 or math.abs(p.Z - vz) > 1e-6 then return false, d.Name .. " läge" end
		end
		return true, nil
	end
	local function modellerNamn()
		local n = 0
		for _, b in workspace:GetChildren() do if b.Name == "Ugneta" then n += 1 end end
		return n
	end

	print("\n── C2: blicken i det byggda ridhuset ──")
	local mm = G.visa(hus)
	local b = G._blick()
	prova("KONTROLL: gestalten står och har ett ankare", mm ~= nil and b.ankare ~= nil and b.delar == 4)
	local ankare = b.ankare
	local plats0 = UgnetaGestalt.plats(hus)
	prova("ankaret är platsen ur kanonen, oförändrat", ankare ~= nil and plats0 ~= nil
		and (ankare - plats0.pos).Magnitude < 1e-6)
	local ok0, v0 = sammanhallen(mm, ankare, b.neutral)
	prova("neutralt: alla fyra delar mot A, glasögonen framme", ok0 and nara(b.neutral,
		math.atan2(-plats0.motC.X, -plats0.motC.Z)), v0)
	-- Ryttare 10 m åt sidan (tvärs), stilla: hon vänder sig dit, mjukt och begränsat.
	local sida = Vector3.new(plats0.motC.Z, 0, -plats0.motC.X) -- vinkelrätt mot motC i planet
	local mal = ankare + sida * (10 * M)
	local malYaw = math.atan2(mal.X - ankare.X, mal.Z - ankare.Z)
	local fore = G._blick().yaw
	G.steg(1 / 60, { x = mal.X, z = mal.Z })
	local ett = G._blick().yaw
	prova("ett steg vrider högst 90°/s · dt, åt rätt håll", math.abs(kort(ett - fore)) <= GR.VRID_MAX / 60 + 1e-9
		and math.abs(kort(malYaw - ett)) < math.abs(kort(malYaw - fore)))
	for _ = 1, 600 do G.steg(1 / 60, { x = mal.X, z = mal.Z }) end
	local okM, vM = sammanhallen(mm, ankare, G._blick().yaw)
	prova("efter 10 s står hon mot ryttaren, med alla delar sammanhållna",
		nara(G._blick().yaw, malYaw, 1e-3) and okM, vM)

	-- Bakom henne, precis över ±π: den korta vägen.
	local bakom = ankare + plats0.motC * (20 * M) + sida * (0.01 * M)
	local bYaw = math.atan2(bakom.X - ankare.X, bakom.Z - ankare.Z)
	for _ = 1, 600 do G.steg(1 / 60, { x = bakom.X, z = bakom.Z }) end
	local nu = G._blick().yaw
	local andra = ankare + plats0.motC * (20 * M) - sida * (0.01 * M)
	G.steg(1 / 60, { x = andra.X, z = andra.Z })
	prova("över ±π vrider hon den korta vägen, aldrig ett helt varv",
		nara(nu, bYaw, 1e-3) and math.abs(kort(G._blick().yaw - nu)) <= GR.VRID_MAX / 60 + 1e-9)

	-- Nära noll, ogiltigt och saknat: ingen vridning.
	local stilla = G._blick().yaw
	G.steg(1 / 60, { x = ankare.X + 0.5, z = ankare.Z }) -- 0,17 m
	G.steg(1 / 60, { x = ankare.X, z = ankare.Z })
	G.steg(1 / 60, { x = 0 / 0, z = 1 })
	G.steg(1 / 60, { x = math.huge, z = 1 })
	G.steg(1 / 60, nil)
	G.steg(1 / 60, "inte en punkt")
	G.steg(0, { x = mal.X, z = mal.Z })
	G.steg(-1, { x = mal.X, z = mal.Z })
	G.steg(0 / 0, { x = mal.X, z = mal.Z })
	prova("nära noll, NaN/inf, saknat mål och dt ≤ 0/NaN vrider inte", G._blick().yaw == stilla)
	local okS, vS = sammanhallen(mm, ankare, stilla)
	prova("och delarna står kvar där de stod", okS, vS)

	-- Ett långt dt räknas som MAX_DT.
	local a = G._blick().yaw
	G.steg(5, { x = mal.X, z = mal.Z })
	local lang = kort(G._blick().yaw - a)
	prova("ett dt på 5 s vrider högst som 0,1 s", math.abs(lang) <= GR.VRID_MAX * GR.MAX_DT + 1e-9, lang)

	-- Långt bort (utanför banan): tillbaka mot A.
	-- Åt SIDAN (inte mot A, där neutralt redan pekar), så att provet skiljer fallen åt.
	local langt = ankare + sida * ((GR.LANGT_M + 5) * M)
	for _ = 1, 600 do G.steg(1 / 60, { x = mal.X, z = mal.Z }) end
	prova("KONTROLL: före det långa målet står hon mot sidan, inte neutralt",
		not nara(G._blick().yaw, G._blick().neutral, 0.1))
	for _ = 1, 600 do G.steg(1 / 60, { x = langt.X, z = langt.Z }) end
	prova("en ryttare längre bort än LANGT_M: hon vänder tillbaka mot A (neutralt)",
		nara(G._blick().yaw, G._blick().neutral, 1e-3))

	-- Ingen drift: tiotusen steg fram och tillbaka.
	for i = 1, 10000 do
		local q = if i % 2 == 0 then mal else bakom
		G.steg(1 / 60, { x = q.X, z = q.Z })
	end
	local okD, vD = sammanhallen(mm, ankare, G._blick().yaw)
	prova("10 000 steg: ankare, höjd och sammanhållning utan drift", okD, vD)

	-- Upprepad visa: en modell. Förstörd utifrån: inga referenser.
	G.visa(hus); G.visa(hus)
	prova("upprepad visa ger EN modell", modellerNamn() == 1, modellerNamn())
	local m2 = G._blick().modell
	m2:Destroy()
	G.steg(1 / 60, { x = mal.X, z = mal.Z })
	prova("förstörd utifrån: referenserna släpps och ingenting vrids",
		not G.finns() and G._blick().ankare == nil and G._blick().delar == 0)
	G.visa(hus)
	G.dolj()
	G.steg(1 / 60, { x = mal.X, z = mal.Z })
	prova("efter dolj: ingen modell, inget ankare, ingen vridning",
		modellerNamn() == 0 and G._blick().ankare == nil and G._blick().yaw == 0)
	prova("visa utan ridhus river en tidigare gestalt och bygger ingen", (function()
		G.visa(hus)
		local r = G.visa(nil)
		return r == nil and not G.finns() and modellerNamn() == 0
	end)())

	print("\n── C2: blicken i ett flyttat och vridet ridhus ──")
	local function syntetisk(pos, gir)
		local s = Instance.new("Model")
		local bas = CFrame.new(pos) * CFrame.Angles(0, gir, 0)
		local lb = Instance.new("Part")
		lb.Name = "Ridbanan"
		lb.Size = Vector3.new(60, 0.18, 196.59)
		lb.CFrame = bas * CFrame.new(0, 0.09, -8.295)
		lb:SetAttribute("PlatsId", "ridhus_bana")
		lb.Parent = s
		local ll = Instance.new("Part")
		ll.Name = "Dressyrlayout 20x60"
		ll.Size = Vector3.new(60, 0.06, 180)
		ll.CFrame = bas * CFrame.new(0, 0.12, 0)
		ll:SetAttribute("PlatsId", "ridhus_dressyr")
		ll:SetAttribute("Forankring", "A")
		ll.Parent = s
		return s
	end
	local vriden = syntetisk(Vector3.new(-512, 3, 77), math.rad(37))
	local mv = G.visa(vriden)
	local pv = G.plats(vriden)
	prova("KONTROLL: gestalten står i det vridna huset", mv ~= nil and pv ~= nil)
	if mv and pv then
		local bv = G._blick()
		local okV, vV = sammanhallen(mv, bv.ankare, bv.neutral)
		prova("vridet: ankaret är den vridna platsen och neutralt är mot A",
			(bv.ankare - pv.pos).Magnitude < 1e-6 and nara(bv.neutral, math.atan2(-pv.motC.X, -pv.motC.Z)) and okV, vV)
		local t = pv.pos - pv.motC * (30 * M)
		for _ = 1, 600 do G.steg(1 / 60, { x = t.X + 3 * M, z = t.Z }) end
		local tYaw = math.atan2(t.X + 3 * M - bv.ankare.X, t.Z - bv.ankare.Z)
		local okT, vT = sammanhallen(mv, bv.ankare, G._blick().yaw)
		prova("vridet: hon vänder sig mot en ryttare på banan, sammanhållen", nara(G._blick().yaw, tYaw, 1e-3) and okT, vT)
	end
	G.dolj()
end

if fel > 0 then
	print(("\n%d mätningar föll."):format(fel))
	--[[ #264 INFRA-PLATS1 R1: specen gav förut exit 0 även när en mätning
		föll, så en grön svit bevisade inte att den var grön. Nu fälls
		körningen, som i de andra specarna. ]]
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätningar föll."):format(fel), 0)
else
	print("\nAlla mätningar gick igenom.")
end
