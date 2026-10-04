--!nostrict
--[[
	DRESSYRBOKSTÄVERNA I RIDHUSET — #289.

	Tobias fann i Studio att de synliga bokstäverna saknades, så Ugneta inte
	kunde säga VART ryttaren ska rida. Webben hade dem (`DRESSYRBOKSTAVER`,
	src/data.js); Roblox hade bara layout-rektangeln och ett löst bokstavsställ.

	Provet kör byggskriptet på riktigt och mäter de tolv skyltarna:
	  · exakt A C K V E S H F P B R M — ingen saknas, ingen dubbleras,
	  · rätt SARG: A syd, C norr, K V E S H väst, F P B R M öst,
	  · rätt ORDNING längs långsidorna (y växer från A mot C),
	  · rätt LÄGE mot den delade, genererade listan (ingen egen sanning),
	  · vända INÅT mot banan, med bokstaven som läsbar text.
	Och att listan Roblox läser ÄR webbens: samma id, samma x,y.

	Kör: python3 roblox/tests/build.py tests/bygge-dressyrbokstaver.spec.luau
	     && luau roblox/tests/.build/bygge-dressyrbokstaver.spec.luau
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

local modell = workspace:FindFirstChild("Anläggning"):FindFirstChild("UBRF")
check("modellen finns", modell ~= nil)
local bas = (modell :: any).PrimaryPart.CFrame
local R = UBRFKomplex.ridhus
local o, dr, ba = R.origo, R.dressyr, R.bana

--[[ Kanon, skriven FÖR HAND och med flit: provet ska fälla om listan i data.js
	eller exporten driver, inte bara om byggaren avviker från listan. ]]
local KANON = {
	A = "S", C = "N",
	K = "W", V = "W", E = "W", S = "W", H = "W",
	F = "E", P = "E", B = "E", R = "E", M = "E",
}
local ORDNING_VAST = { "K", "V", "E", "S", "H" }
local ORDNING_OST = { "F", "P", "B", "R", "M" }

local function tomt(p: Vector3)
	return BuildKit.tomtkoord(bas, Vector3.new(p.X, 0, p.Z))
end

print("Listan Roblox läser")
local lista = R.dressyrBokstaver
check("exporten bär listan", type(lista) == "table", type(lista))
check("exakt tolv poster", lista ~= nil and #lista == 12, lista and #lista or "nil")
local sedda, dubbletter = {}, {}
for _, bo in ipairs(lista or {}) do
	if sedda[bo.b] then table.insert(dubbletter, bo.b) end
	sedda[bo.b] = bo
end
check("ingen bokstav dubbleras i listan", #dubbletter == 0, table.concat(dubbletter, ","))
for id in pairs(KANON) do
	check("listan har " .. id, sedda[id] ~= nil)
end
for id in pairs(sedda) do
	check("listan har ingen okänd bokstav (" .. id .. ")", KANON[id] ~= nil)
end

print("\nSkyltarna i den byggda världen")
local skyltar, antal = {}, {}
for _, d in ipairs(modell:GetDescendants()) do
	if d:IsA("BasePart") and d:GetAttribute("BokstavId") ~= nil then
		local id = d:GetAttribute("BokstavId")
		antal[id] = (antal[id] or 0) + 1
		skyltar[id] = d
	end
end
local totalt = 0
for _, n in pairs(antal) do totalt += n end
check("exakt tolv skyltar byggdes", totalt == 12, tostring(totalt))
for id in pairs(KANON) do
	check("skylten " .. id .. " finns EXAKT en gång", antal[id] == 1, tostring(antal[id]))
end

local cx, cy = ba.x + ba.w / 2, ba.y + ba.h / 2 -- banans mitt, i huskoordinater
local function huskoord(d)
	local x, y = tomt(d.CFrame.Position)
	return x - o.x, y - o.y
end
local sidor = {}
for id, d in pairs(skyltar) do
	local hx, hy = huskoord(d)
	local sida
	if math.abs(hx - ba.x) < 1.0 then sida = "W"
	elseif math.abs(hx - (ba.x + ba.w)) < 1.0 then sida = "E"
	elseif hy < cy then sida = "S"
	else sida = "N" end
	sidor[id] = { sida = sida, x = hx, y = hy }
	check(id .. " sitter på rätt sarg (" .. KANON[id] .. ")", sida == KANON[id],
		("%s (%.2f, %.2f)"):format(sida, hx, hy))
end

print("\nOrdning längs långsidorna — y växer från A mot C")
local function stigande(ids, namn)
	local ok, forra = true, -math.huge
	local rader = {}
	for _, id in ipairs(ids) do
		local s = sidor[id]
		if not s or s.y <= forra then ok = false end
		if s then forra = s.y; table.insert(rader, ("%s=%.1f"):format(id, s.y)) end
	end
	check(namn, ok, table.concat(rader, " "))
end
stigande(ORDNING_VAST, "västra långsidan: K → V → E → S → H")
stigande(ORDNING_OST, "östra långsidan: F → P → B → R → M")
if sidor.A and sidor.C then
	check("A ligger söder om C", sidor.A.y < sidor.C.y,
		("A y=%.1f, C y=%.1f"):format(sidor.A.y, sidor.C.y))
	check("A och C står mitt på kortsidorna", math.abs(sidor.A.x - cx) < 0.5 and math.abs(sidor.C.x - cx) < 0.5)
end

print("\nLäge mot den delade listan (ingen egen sanning)")
for id, bo in pairs(sedda) do
	local s = sidor[id]
	if s then
		local ex, ey = dr.x + bo.x, dr.y + bo.y
		if bo.paSarg == "N" then ey = ba.y + ba.h end
		check(("%s ligger vid listans läge (%.1f, %.1f)"):format(id, ex, ey),
			math.abs(s.x - ex) < 0.2 and math.abs(s.y - ey) < 0.2,
			("%.2f, %.2f"):format(s.x, s.y))
	end
end

print("\nVända inåt och läsbara")
for id, d in pairs(skyltar) do
	local p = d.CFrame.Position
	-- Skriften sitter på SurfaceGui-ytan, och `BuildKit.speglaModell` byter
	-- Back ↔ Front när världen vänds (norr = −Z). Läsriktningen är därför ytans
	-- EFTERSPEGLADE sida: Front pekar längs LookVector, Back mot dess motsats.
	-- Steget fram längs den ska ta oss närmare banans mitt.
	local ytan = d:FindFirstChild("Bokstavsyta")
	local lasrikt = if ytan and ytan.Face == Enum.NormalId.Front then d.CFrame.LookVector else -d.CFrame.LookVector
	local fram = p + lasrikt * 1.0
	local x0, y0 = tomt(p)
	local x1, y1 = tomt(fram)
	local fore = (x0 - o.x - cx) ^ 2 + (y0 - o.y - cy) ^ 2
	local efter = (x1 - o.x - cx) ^ 2 + (y1 - o.y - cy) ^ 2
	check(id .. " är vänd inåt mot banan", efter < fore, ("%.1f → %.1f"):format(fore, efter))
	local yta = d:FindFirstChild("Bokstavsyta")
	local etikett = yta and yta:FindFirstChild("Text")
	check(id .. " bär sin bokstav som text", etikett ~= nil and etikett.Text == id,
		etikett and etikett.Text or "ingen etikett")
	local storlek = d.Size
	check(id .. " är läsbar: minst 0,7 m hög och 0,9 m bred",
		storlek.Y >= 0.7 * BuildKit.M - 1e-6 and storlek.X >= 0.9 * BuildKit.M - 1e-6,
		("%.2f × %.2f studs"):format(storlek.X, storlek.Y))
end

print("\nDet lösa bokstavsstället är orört")
local stall = 0
for _, d in ipairs(modell:GetDescendants()) do
	if d:IsA("BasePart") and string.find(d.Name, "bokstaver", 1, true) then stall += 1 end
end
check("bokstavsstället (hylla + list) byggs fortfarande", stall >= 1, tostring(stall))

print("")
if fails > 0 then
	print(string.format("%d mätning(ar) föll.", fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("bygge-dressyrbokstaver.spec: alla gröna")
end
