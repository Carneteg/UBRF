--!nostrict
--[[ PARITETSUTSKRIFT, INTE GRIND. Skriver Roblox förberedelseregler som
	rader som tools/forberedelsetest.mjs läser och jämför mot webbens port
	(src/forberedelse.js). Inte med i kor.sh: den mäter inget krav själv —
	det är webbtestet som fäller om plattformarna glidit isär.

	Format:
	  MOMENT <fas> <id>,<id>,…   (felaktiga alternativ med prefix !)
	  FYND <häst> <pass> <punkt|nil>
	  ANDEL <scenario> <värde med 6 decimaler>
	  TILLDELA <uid> <vilande> <önskan> <häst|nil>
	  BOX <häst> <rad> <plats> <lokal y>
	  ANTAL <antal hästar i Spel.ordning> ]]

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
-- Tilldelningen (P1b): Stallet.tilldelaLedig för (uid, vilande, önskan).
local VILANDE = {
	{ namn = "inga", set = {} },
	{ namn = "jack", set = { blackrock_jack = true } },
	{ namn = "tre", set = { air = true, allan = true, troy = true } },
}
for _, v in ipairs(VILANDE) do
	for _, onskad in ipairs({ "nil", "blackrock_jack" }) do
		--[[ Varje uid från −2 till 2n+1: alla n startrester, mer än två hela
			varv, och negativa uid (Play Solo, se `Stallet.tilldela`). Steget
			var 3 förut — med 33 hästar täckte det bara var tredje rest
			(P1b-granskningen, #266 L2). ]]
		for uid = -2, 2 * #UBRFSpel.ordning + 1 do
			local svar = Stallet.tilldelaLedig(uid, {}, v.set, if onskad == "nil" then nil else onskad)
			print(string.format("TILLDELA %d %s %s %s", uid, v.namn, onskad, tostring(svar)))
		end
	end
end
-- Boxarna (P1b, Tobias 2026-09-29): vilken rad och plats varje häst står i.
-- Ur kanonens egen ordning, inte en avskriven lista (#266 L3): en ny häst
-- ska inte kunna slinka förbi paritetsprovet. ANTAL bär kanonens längd.
print(string.format("ANTAL %d", #UBRFSpel.ordning))
for _, id in ipairs(UBRFSpel.ordning) do
	local b = Stallet.boxFor(id)
	if b then
		print(string.format("BOX %s %s %d %.3f", id, b.rad, b.plats, b.lokal.y))
	else
		print(string.format("BOX %s nil 0 0", id))
	end
end
print("alla gröna")
