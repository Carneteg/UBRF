--!nostrict
--[[ DRESSYRBOKSTÄVERNAS SEMANTIK — #289 (rättningen efter #292).

	Galoppringen på mittlinjen hette «K». Men K är en dressyrbokstav och sitter
	på VÄSTRA sargen; en spelare som hörde «vid K» fick två olika platser. Provet
	håller isär dem:
	  · K slås upp ur den delade, genererade listan och ligger på västra sargen,
	  · galoppringen bär INGET dressyrbokstavs-id,
	  · spelartexten om ringen innehåller ingen fristående bokstav K,
	  · ett okänt eller dubblerat bokstavs-id nekas,
	  · lektionernas namngivna id (ClearRounds A/C-riktning, ankaret A) finns i listan,
	  · och lägena är de oförändrade (handskriven kanon, samma som webbens data.js).

	Kör: python3 roblox/tests/build.py tests/galopplektion-bokstaver.spec.luau
	     && luau roblox/tests/.build/galopplektion-bokstaver.spec.luau ]]
local fails = 0
local function check(namn, villkor, detalj)
	if villkor then
		print("  OK   " .. namn .. (detalj and ("  " .. tostring(detalj)) or ""))
	else
		fails += 1
		print("  FEL  " .. namn .. (detalj and ("  " .. tostring(detalj)) or ""))
	end
end

local R = UBRFKomplex.ridhus
local B = Dressyrbokstaver.standard()

--[[ Kanon, skriven FÖR HAND (data.js): fäller om listan driver, inte bara om
	uppslagaren avviker från listan. ]]
local KANON = {
	A = { 10, 0, "S" }, C = { 10, 60, "N" },
	K = { 0, 6, "W" }, V = { 0, 18, "W" }, E = { 0, 30, "W" }, S = { 0, 42, "W" }, H = { 0, 54, "W" },
	F = { 20, 6, "E" }, P = { 20, 18, "E" }, B = { 20, 30, "E" }, R = { 20, 42, "E" }, M = { 20, 54, "E" },
}
print("Kanonisk uppslagning")
local antal = 0
for id, k in pairs(KANON) do
	antal += 1
	local x, y = B.lage(id)
	check("lage " .. id, x == k[1] and y == k[2], tostring(x) .. "," .. tostring(y))
	check("sarg " .. id, B.sarg(id) == k[3], B.sarg(id))
end
check("exakt tolv bokstäver i uppslagaren", #B.alla() == 12 and antal == 12, #B.alla())
check("K är VÄSTRA sargens skylt", B.sarg("K") == "W" and select(1, B.lage("K")) == 0)

print("Galoppringen är ingen bokstav")
local G = GaloppLektion.GRANSER
check("ringens mål-id är inte en dressyrbokstav", not B.finns(GaloppLektion.MAL), GaloppLektion.MAL)
check("ringens mål-id är inte K", GaloppLektion.MAL ~= "K")
local ringX, ringY = R.dressyr.w / 2, G.K_V -- mittlinjen, 30 m från A
local sammanfaller = false
for _, id in ipairs(B.alla()) do
	local x, y = B.lage(id)
	if x == ringX and y == ringY then sammanfaller = true end
end
check("ingen dressyrbokstav sitter där ringen ligger (mittlinjen, 30 m)", not sammanfaller)

print("Spelartexten om ringen")
local PREFIX = { "galopplektion.", "aterkoppling.galopp.", "halsning.galopp" }
local funna, fristaende = 0, {}
for nyckel, post in pairs(UBRFSprak.text) do
	for _, pre in ipairs(PREFIX) do
		if string.sub(nyckel, 1, #pre) == pre then
			funna += 1
			for _, sprak in ipairs({ "sv", "en" }) do
				local t = post[sprak]
				if type(t) == "string" and string.find(t, "%f[%w]K%f[%W]") then
					table.insert(fristaende, nyckel .. "/" .. sprak)
				end
			end
		end
	end
end
check("galopptexterna hittades", funna >= 10, funna)
check("ingen galopptext säger «K» (vid K / ringen K)", #fristaende == 0, table.concat(fristaende, " "))

print("Okända och dubblerade id nekas")
check("okänt id finns inte", not B.finns("Q") and not B.finns("") and not B.finns(nil) and not B.finns(7))
check("okänt id har inget läge", B.lage("Q") == nil)
check("krav() faller för okänt id", not pcall(B.krav, "Q"))
check("krav() släpper igenom K", pcall(B.krav, "K"))
local ok1, fel1 = Dressyrbokstaver.fran({ { b = "A", x = 10, y = 0 }, { b = "A", x = 1, y = 1 } }, 20)
check("dubblerat id nekas", ok1 == nil and string.find(fel1 or "", "dubblett:A", 1, true) ~= nil, fel1)
local ok2, fel2 = Dressyrbokstaver.fran({}, 20)
check("tom lista nekas", ok2 == nil, fel2)
local ok3, fel3 = Dressyrbokstaver.fran({ { b = "", x = 1, y = 1 } }, 20)
check("tomt id nekas", ok3 == nil, fel3)
local ok4, fel4 = Dressyrbokstaver.fran({ { b = "K", y = 1 } }, 20)
check("post utan läge nekas", ok4 == nil, fel4)

print("Lektionernas namngivna id finns i listan")
for _, id in ipairs(ClearRoundLektion.RIKTNINGSID) do
	check("riktningsid " .. id .. " är en dressyrbokstav", B.finns(id))
end
local anvanda = {}
for _, h in ipairs(ClearRoundLektion.BANA) do anvanda[h.mot] = true end
for id in pairs(anvanda) do
	local pa = false
	for _, r in ipairs(ClearRoundLektion.RIKTNINGSID) do if r == id then pa = true end end
	check("banans mot=" .. id .. " finns bland de deklarerade riktningsidn", pa)
end
check("dressyrlayoutens ankare «" .. tostring(R.dressyr.forankring) .. "» är en dressyrbokstav",
	B.finns(R.dressyr.forankring))

print(fails == 0 and "alla gröna" or ("FEL: " .. fails))
if fails > 0 then error("galopplektion-bokstaver: " .. fails .. " fel") end
