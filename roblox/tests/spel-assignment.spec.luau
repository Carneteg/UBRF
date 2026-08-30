--!nostrict
local fails = 0
local function check(namn, villkor, detalj)
	if villkor then
		print(string.format("  OK   %s%s", namn, detalj and ("  " .. detalj) or ""))
	else
		fails += 1
		print(string.format("  FEL  %s%s", namn, detalj and ("  " .. detalj) or ""))
	end
end

print("\n── G01: StallService-regeln har en unik identitet per aktiv spelare ──")
local uid = 123456
local prefererad = Stallet.tilldela(uid)
check("stabil preferens finns", prefererad ~= nil and UBRFSpel.hastar[prefererad] ~= nil, tostring(prefererad))

local ledig = Stallet.tilldelaLedig(uid, {})
check("ledig prefererad häst väljs först", ledig == prefererad,
	string.format("prefererad=%s fick=%s", tostring(prefererad), tostring(ledig)))

local upptagna = { [prefererad] = true }
local reserv = Stallet.tilldelaLedig(uid, upptagna)
check("upptagen preferens ger en annan häst", reserv ~= nil and reserv ~= prefererad,
	string.format("prefererad=%s reserv=%s", tostring(prefererad), tostring(reserv)))

local alla = {}
for _, id in ipairs(UBRFSpel.ordning) do alla[id] = true end
check("alla upptagna ger nil", Stallet.tilldelaLedig(uid, alla) == nil)

-- Simulera en server som reserverar efter varje tilldelning. Ingen identitet
-- får då delas så länge det finns minst lika många hästar som spelare.
local reserverade, sedda = {}, {}
local antal = math.min(#UBRFSpel.ordning, 12)
for i = 1, antal do
	local id = Stallet.tilldelaLedig(1000 + i, reserverade)
	if id then
		if sedda[id] then
			check("spelare " .. i .. " fick unik häst", false, id .. " var redan tagen")
		else
			sedda[id] = true
			reserverade[id] = true
			check("spelare " .. i .. " fick unik häst", true, id)
		end
	else
		check("spelare " .. i .. " fick en ledig häst", false, "nil")
	end
end

local d = Stallet.dagensHast(uid, { [prefererad] = true })
check("dagensHast respekterar upptagna identiteter",
	d ~= nil and d.id ~= prefererad and d.box ~= nil and d.namn ~= nil,
	d and d.id or "nil")

if fails > 0 then
	print(string.format("\n%d FEL", fails))
	error("spel-assignment.spec: " .. fails .. " fel")
end
print("\nG01 assignment: alla gröna")
