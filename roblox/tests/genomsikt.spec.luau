--!nostrict
--[[
	Mätningar på inomhusläsbarheten: vilka väggar tonas.

	Regeln är densamma som webbens v3dTonas — en del vars fotavtryck skär
	sträckan kamera → karaktär skymmer, med marginal runt delen och en
	slutmarginal före karaktären. Tre saker kan gå fel och alla tre mäts:
	en vägg bredvid sträckan tonas i onödan, en vägg mellan tonas inte, och
	väggen karaktären står intill tonas fast den inte skymmer någon.

	Kör: python3 roblox/tests/build.py tests/genomsikt.spec.luau
	     && luau roblox/tests/.build/genomsikt.spec.luau
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

local function del(namn, x, z, w, d)
	return { Name = namn, Position = Vector3.new(x, 5, z), Size = Vector3.new(w, 10, d) }
end

print("\nGenomsikt")

-- Kameran 12 studs bakom karaktären längs z. En vägg tvärs sträckan på z = 6.
local kam, fig = Vector3.new(0, 5, 0), Vector3.new(0, 3, 12)
local mellan  = del("mellan",  0, 6, 8, 0.5)     -- tvärs, mitt emellan
local bredvid = del("bredvid", 6, 6, 0.5, 8)     -- längs sträckan, 6 studs åt sidan
local intill  = del("intill",  0, 12.4, 8, 0.5)  -- väggen karaktären står mot
local bakom   = del("bakom",   0, 16, 8, 0.5)    -- bortom karaktären

check("väggen mellan kameran och karaktären skymmer", Genomsikt.skymmer(mellan.Position, mellan.Size, kam, fig))
check("väggen bredvid sträckan skymmer inte", not Genomsikt.skymmer(bredvid.Position, bredvid.Size, kam, fig))
check("väggen karaktären står intill skymmer inte", not Genomsikt.skymmer(intill.Position, intill.Size, kam, fig))
check("en vägg bortom karaktären skymmer inte", not Genomsikt.skymmer(bakom.Position, bakom.Size, kam, fig))

-- Marginalen: en vägg vars kant ligger 0,6 studs från sträckan tonas ändå,
-- så att en vägg som skymmer halva kroppen räknas.
local kant = del("kant", 4.6, 6, 8, 0.5)   -- sträcker sig x 0,6 → 8,6
check("marginalen fångar en vägg som nuddar sträckan", Genomsikt.skymmer(kant.Position, kant.Size, kam, fig, 1.0))
check("utan marginal fångas den inte", not Genomsikt.skymmer(kant.Position, kant.Size, kam, fig, 0))

local valda = Genomsikt.valj({ mellan, bredvid, intill, bakom, kant }, kam, fig)
local namn = {}
for _, d in ipairs(valda) do table.insert(namn, d.Name) end
table.sort(namn)
check("valj ger exakt de skymmande delarna", table.concat(namn, ",") == "kant,mellan", table.concat(namn, ","))

-- Sträcka av längd noll: inget skymmer, ingen division med noll.
check("kameran i karaktären: ingenting tonas", not Genomsikt.skymmer(mellan.Position, mellan.Size, fig, fig))

if fails > 0 then
	print(string.format("%d mätning(ar) föll.", fails))
else
	print("Alla mätningar gick igenom.")
end
