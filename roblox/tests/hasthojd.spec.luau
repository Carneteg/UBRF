--!nostrict
--[[
	HÄSTENS FYSISKA HÖLJE FÖLJER HENNES EGEN MANKHÖJD.

	══ VAD SOM VAR FEL ════════════════════════════════════════════════

	Rostern gav varje häst sin egen SYNLIGA storlek — Marabou 1,27 m,
	Blackrock Jack 1,45, Allan 1,78 — men alla 33 delade samma GAMEPLAY-
	hölje. Uppmätt i Studio före rättningen: identisk rotdel och identisk
	`HipHeight` på en ponny och en stor häst. En ponny tog alltså lika
	stor plats i dörren som en halvblodshäst, och ryttaren satt lika högt
	på båda.

	══ VAD SOM MÄTS HÄR ═══════════════════════════════════════════════

	Att höljet, `HipHeight` och sitsen räknas UR mankhöjden, och att
	grundhästen är oförändrad. Den sista punkten är lika viktig som de
	andra: Blackrock Jack är kanonisk testhäst, och hade hennes hölje
	ändrats vore varje tidigare mätning av ledning, dörrar och sarg
	ogiltig.

	Provet läser `HastRigg.kroppsmatt` — SAMMA räkning riggen byggs med,
	inte en avskrift — och bygger sedan tre riktiga riggar och mäter dem.

	Sist mäts markkontakten: ridbanans sand är ett 0,18 studs tjockt lager
	UTAN kollision ovanpå det golv som bär, och hovarna sjönk igenom den.
	Se `Markkontakt.luau` för hela mätningen.

	Kör: python3 roblox/tests/build.py tests/hasthojd.spec.luau
	     && luau roblox/tests/.build/hasthojd.spec.luau
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
local function nara(a, b, tol)
	return type(a) == "number" and type(b) == "number" and math.abs(a - b) <= (tol or 1e-6)
end

local RunService = game:GetService("RunService")
RunService._server = true

local M = 3                      -- studs per meter
local GRUND = 1.45               -- m: grundformens mankhöjd (Blackrock Jack)
local PONNY, STOR = 1.27, 1.78   -- m: Marabou och Allan, ur rostern

--[[ ══ 1. RÄKNINGEN ══════════════════════════════════════════════════ ]]
print("\n── Kroppsmåtten räknas ur mankhöjden ──")

local bas = HastRigg.kroppsmatt(GRUND)
check("grundformen har skala 1", nara(bas.skala, 1),
	string.format("skala=%.4f", bas.skala))
check("grundformens kropp är 1,85 x 0,62 x 0,78 m",
	nara(bas.L, 1.85) and nara(bas.B, 0.62) and nara(bas.H, 0.78),
	string.format("%.2f x %.2f x %.2f", bas.L, bas.B, bas.H))

for _, h in ipairs({ PONNY, GRUND, STOR }) do
	local m = HastRigg.kroppsmatt(h)
	check(string.format("%.2f m: skalan är höjdens kvot", h), nara(m.skala, h / GRUND, 1e-9),
		string.format("skala=%.4f, väntat %.4f", m.skala, h / GRUND))
	check(string.format("%.2f m: längd och bredd följer skalan", h),
		nara(m.L, 1.85 * h / GRUND, 1e-9) and nara(m.B, 0.62 * h / GRUND, 1e-9),
		string.format("L=%.3f B=%.3f", m.L, m.B))
	--[[ BENEN ÄR DET SOM BLIR ÖVER, och det är vad som håller hovarna på
		marken: skalades benlängden för sig kunde summan bli en annan höjd
		än hästens egen. ]]
	check(string.format("%.2f m: kropp + ben blir exakt mankhöjden", h),
		nara(m.benH + m.H, h, 1e-9),
		string.format("%.4f + %.4f = %.4f", m.H, m.benH, m.benH + m.H))
end

--[[ EN OTROLIG HÖJD ÄR INGEN HÖJD. Rostern har hål — `Utseende.mankhojd`
	svarar `ANTAGANDE` för de hästar Supabase saknar mått på — och ett
	skräpvärde som slinker in får inte bygga en häst på fem meter. ]]
for _, dalig in ipairs({ 0.4, 2.6, 0, -1.45 }) do
	local m = HastRigg.kroppsmatt(dalig)
	check(string.format("orimlig höjd (%s) faller tillbaka på grundformen", tostring(dalig)),
		nara(m.mankhojd, GRUND), string.format("gav %.3f", m.mankhojd))
end
do
	local m = HastRigg.kroppsmatt(nil)
	check("ingen höjd alls faller tillbaka på grundformen", nara(m.mankhojd, GRUND),
		string.format("gav %.3f", m.mankhojd))
	local t = HastRigg.kroppsmatt("stor")
	check("höjd som inte är ett tal faller tillbaka", nara(t.mankhojd, GRUND),
		string.format("gav %.3f", t.mankhojd))
end

--[[ ══ 2. RIGGARNA ══════════════════════════════════════════════════ ]]
print("\n── Tre riktiga riggar, tre olika hästar ──")

local function rigga(id, namn, hojd, x)
	local modell = HastRigg.bygg(id, namn, CFrame.new(Vector3.new(x, 0, 0)), hojd)
	modell.Parent = workspace
	return modell
end

local ponny = rigga("marabou", "Marabou", PONNY, 0)
local jack  = rigga("blackrock_jack", "Blackrock Jack", GRUND, 60)
local stor  = rigga("allan", "Allan", STOR, 120)

local function holje(modell)
	local rot = modell.PrimaryPart
	local hum = modell:FindFirstChildOfClass("Humanoid")
	local sits = modell:FindFirstChild("RiderSeat")
	local markY = rot.CFrame.Position.Y - rot.Size.Y / 2 - hum.HipHeight
	return {
		rot = rot, hum = hum, sits = sits,
		B = rot.Size.X, H = rot.Size.Y, L = rot.Size.Z,
		hip = hum.HipHeight,
		--[[ Sitsens höjd ÖVER MARKEN, inte över roten: det är den ryttaren
			känner, och den enda som går att jämföra mellan storlekar. ]]
		sitshojd = sits.CFrame.Position.Y - markY,
	}
end

local hp, hj, hs = holje(ponny), holje(jack), holje(stor)

--[[ GRUNDHÄSTEN ÄR ORÖRD. Talen nedan är uppmätta på baslinjen (SHA
	0d9f734) och står med flit som absoluta tal: ändras de har den
	kanoniska testhästens hölje ändrats, och då är varje tidigare mätning
	av dörrar, ledning och sarg ogiltig. ]]
check("Blackrock Jacks hölje är oförändrat 1,86 x 2,34 x 5,55 studs",
	nara(hj.B, 1.86, 1e-9) and nara(hj.H, 2.34, 1e-9) and nara(hj.L, 5.55, 1e-9),
	string.format("%.4f x %.4f x %.4f", hj.B, hj.H, hj.L))
check("Blackrock Jacks HipHeight är oförändrad 2,01", nara(hj.hip, 2.01, 1e-9),
	string.format("%.4f", hj.hip))

for _, rad in ipairs({ { "ponnyn", hp, PONNY }, { "grundhästen", hj, GRUND },
	{ "den stora", hs, STOR } }) do
	local namn, h, hojd = rad[1], rad[2], rad[3]
	local m = HastRigg.kroppsmatt(hojd)
	check(string.format("%s: rotdelen är kroppsmåtten i studs", namn),
		nara(h.B, m.B * M, 1e-9) and nara(h.H, m.H * M, 1e-9) and nara(h.L, m.L * M, 1e-9),
		string.format("%.2f x %.2f x %.2f", h.B, h.H, h.L))
	check(string.format("%s: HipHeight är benlängden i studs", namn),
		nara(h.hip, m.benH * M, 1e-9), string.format("%.4f", h.hip))
	--[[ SADELN LIGGER PÅ MANKEN. Höjden över marken ska därför vara
		mankhöjden plus sadelns egen tjocklek — samma tal för varje häst.
		Utan det villkoret kunde ryttaren sitta rätt på en häst och sväva
		på en annan utan att någon siffra i riggen såg fel ut. ]]
	check(string.format("%s: sitsen ligger mankhöjden + 0,08 m över marken", namn),
		nara(h.sitshojd, (hojd + 0.08) * M, 1e-6),
		string.format("%.3f studs, väntat %.3f", h.sitshojd, (hojd + 0.08) * M))
	check(string.format("%s: sitsen sitter mitt på ryggen", namn),
		nara(h.sits.CFrame.Position.X, h.rot.CFrame.Position.X, 1e-6)
		and nara(h.sits.CFrame.Position.Z, h.rot.CFrame.Position.Z, 1e-6))
end

--[[ ORDNINGEN SKA VARA SANN I VÄRLDEN, inte bara i räkningen: en ponny
	ska ta MINDRE plats än en stor häst i varje riktning. ]]
check("ponnyn är fysiskt mindre än grundhästen i alla tre riktningar",
	hp.B < hj.B and hp.H < hj.H and hp.L < hj.L and hp.hip < hj.hip,
	string.format("%.2f/%.2f/%.2f mot %.2f/%.2f/%.2f", hp.B, hp.H, hp.L, hj.B, hj.H, hj.L))
check("den stora hästen är fysiskt större än grundhästen",
	hs.B > hj.B and hs.H > hj.H and hs.L > hj.L and hs.hip > hj.hip,
	string.format("%.2f/%.2f/%.2f mot %.2f/%.2f/%.2f", hs.B, hs.H, hs.L, hj.B, hj.H, hj.L))

--[[ DÖRREN MÅSTE FORTFARANDE GÅ ATT GÅ IGENOM. Boxöppningen är 1,20 m
	(3,60 studs); det bindande måttet är kroppens BREDD, för hästen
	passerar på längden. Skalningen får aldrig göra den största hästen
	bredare än öppningen. ]]
local OPPNING = 1.20 * M
check("den största hästen ryms i boxöppningen på 1,20 m",
	hs.B < OPPNING, string.format("bredd %.2f studs mot öppning %.2f", hs.B, OPPNING))

--[[ ══ 3. MARKKONTAKTEN ═════════════════════════════════════════════ ]]
print("\n── Hovarna möter den yta man ser ──")

--[[ Bänken lägger underlag: en strålmätning som svarar OLIKA beroende på
	`RespectCanCollide` är hela poängen — skillnaden mellan den översta
	ytan över huvud taget och den översta som BÄR är dekorlagrets
	tjocklek. ]]
local function lagg(synligY, barandeY)
	__markyta = function(origin, _dir, params)
		local y = if params and params.RespectCanCollide then barandeY else synligY
		if y == nil then return nil end
		return { Position = Vector3.new(origin.X, y, origin.Z),
			Normal = Vector3.new(0, 1, 0), Instance = { Name = "prov" } }
	end
end

local rotP = jack.PrimaryPart
lagg(0.18, 0)
check("ridbanans dekorlager mäts till 0,18 studs",
	nara(Markkontakt.lagertjocklek(rotP, {}), 0.18, 1e-9),
	string.format("%.4f", Markkontakt.lagertjocklek(rotP, {})))

lagg(0, 0)
check("stallgolvet har inget lager alls", nara(Markkontakt.lagertjocklek(rotP, {}), 0))

lagg(0.005, 0)
check("ett lager under tröskeln rör ingenting",
	nara(Markkontakt.lagertjocklek(rotP, {}), 0))

--[[ ETT TJOCKT LAGER ÄR INTE ETT DEKORLAGER. Står hon på en ramp eller
	på en annan häst är skillnaden stor, och då vore lyftet fel. ]]
lagg(1.4, 0)
check("ett lager tjockare än en stud ger noll, inte ett lyft",
	nara(Markkontakt.lagertjocklek(rotP, {}), 0))

lagg(0.18, nil)
check("ingen bärande yta alls ger noll", nara(Markkontakt.lagertjocklek(rotP, {}), 0))

--[[ LYFTET RÄKNAS ALLTID UR GRUNDHÖJDEN. Utan det sparade grundvärdet
	hade varje omräkning byggt på den redan höjda siffran, och hästen
	hade vandrat uppåt en tiondel i taget. ]]
lagg(0.18, 0)
local humJ = jack:FindFirstChildOfClass("Humanoid")
local grundHip = humJ.HipHeight
Markkontakt.justera(jack, {})
check("hästen lyfts lagrets tjocklek", nara(humJ.HipHeight, grundHip + 0.18, 1e-9),
	string.format("%.4f -> %.4f", grundHip, humJ.HipHeight))
check("grundhöjden sparas på modellen",
	nara(jack:GetAttribute("UBRFHipBas"), grundHip, 1e-9))

Markkontakt.justera(jack, {})
check("en andra omräkning lägger INTE på lagret igen",
	nara(humJ.HipHeight, grundHip + 0.18, 1e-9), string.format("%.4f", humJ.HipHeight))

lagg(0, 0)
Markkontakt.justera(jack, {})
check("tillbaka på stallgolvet står hon på sin egen grundhöjd",
	nara(humJ.HipHeight, grundHip, 1e-9), string.format("%.4f", humJ.HipHeight))

__markyta = nil

if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("\nhasthojd.spec: alla gröna")
end
