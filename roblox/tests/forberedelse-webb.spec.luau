--!nostrict
--[[ PARITETSUTSKRIFT, INTE GRIND. Skriver Roblox förberedelseregler som
	rader som tools/forberedelsetest.mjs läser och jämför mot webbens port
	(src/forberedelse.js). Inte med i kor.sh: den mäter inget krav själv —
	det är webbtestet som fäller om plattformarna glidit isär.

	Format:
	  MOMENT <fas> <id>,<id>,…   (felaktiga alternativ med prefix !)
	  FYND <häst> <pass> <punkt|nil>
	  ANDEL <scenario> <värde med 6 decimaler> ]]

for _, f in ipairs(Preparation.stegFaser()) do
	local ids = {}
	for _, m in ipairs(Preparation.moment(f.id)) do
		table.insert(ids, (if m.fel then "!" else "") .. m.id)
	end
	print("MOMENT " .. f.id .. " " .. table.concat(ids, ","))
end

local HASTAR = { "blackrock_jack", "troy", "lydia", "toblerone", "cosmo", "air", "larry", "dexter" }
for _, h in ipairs(HASTAR) do
	for pass = 1, 12 do
		print(string.format("FYND %s %d %s", h, pass, tostring(Preparation.fyndFor(h, pass))))
	end
end

-- Andelen: allt stallets, och spelaren hälsar + visiterar själv resten auto.
local s = Preparation.nyState("troy", 1)
Preparation.autoForbered(s)
print(string.format("ANDEL auto %.6f", Preparation.egenAndel(s)))
local s2 = Preparation.nyState("troy", 1)
Preparation.utforMoment(s2, "halsa", "halsa2", "troy")
for _, m in ipairs(Preparation.moment("visitera")) do
	Preparation.utforMoment(s2, "visitera", m.id, "troy")
end
Preparation.autoForbered(s2)
print(string.format("ANDEL blandad %.6f", Preparation.egenAndel(s2)))
print("alla gröna")
