--!nostrict
--[[ D1 — KLASSPROFIL A: CLEAR ROUND (docs/D1-CLEAR-ROUND-PROFILE-CONTRACT.md).

	Ren regelmodul, egen minimal bunt. Varje fall är räknat för hand ur
	references/rules/TR-III-2025-hoppning-A-clear-round.md (SvRF TR III 2025,
	moment 314.1.1, 301.3.1.2, 381, 384.1, 388.2). ]]
local fails, total = 0, 0
local function check(name, yes, detalj)
	total += 1
	if not yes then fails += 1 end
	print((if yes then "  OK   " else "  FEL  ") .. name .. (if detalj then "  " .. tostring(detalj) else ""))
end
local K = Klassprofil

local function runda(over)
	local r = { forsok = 1, hojdM = 0.80, ponny = false, nedslag = 0, olydnader = 0, avfallning = false,
		felVag = false, overMaxtidS = 0, overTillatenTid = false }
	for k, v in over or {} do r[k] = v end
	return r
end
local function fmt(u)
	return ("giltig=%s utesluten=%s felfri=%s fel=%s rosett=%s omstart=%s skal=%s"):format(tostring(u.giltig),
		tostring(u.utesluten), tostring(u.felfri), tostring(u.fel), tostring(u.rosett), tostring(u.omstartMojlig),
		tostring(u.skal))
end

print("\n── Felfritt och fel (381, 314.1.1) ──")
local u = K.clearRound(runda())
check("felfritt första försök: felfri, 0 fel, clear round-rosett, ingen omstart", u.giltig and u.utesluten == false
	and u.felfri and u.fel == 0 and u.rosett == "clear_round" and u.omstartMojlig == false, fmt(u))
u = K.clearRound(runda({ forsok = 2 }))
check("samma felfria ritt i försök 2: ingen rosett ([REFERENCE GAP])", u.felfri and u.rosett == nil
	and u.omstartMojlig == false, fmt(u))
u = K.clearRound(runda({ nedslag = 1 }))
check("ett nedslag: 4 fel, ej felfri, omstart möjlig, räknas inte som start", u.fel == 4 and not u.felfri
	and u.rosett == nil and u.omstartMojlig and u.omstartRaknasSomStart == false, fmt(u))
u = K.clearRound(runda({ nedslag = 2, olydnader = 1 }))
check("två nedslag och en olydnad: 12 fel", u.fel == 12 and u.utesluten == false, fmt(u))
u = K.clearRound(runda({ overMaxtidS = 0.1 }))
check("0,1 s över maxtid: 1 tidsfel (påbörjat intervall)", u.fel == 1 and not u.felfri, fmt(u))
u = K.clearRound(runda({ overMaxtidS = 4.0 }))
check("4,0 s över maxtid: 1 tidsfel", u.fel == 1, fmt(u))
u = K.clearRound(runda({ overMaxtidS = 4.1 }))
check("4,1 s över maxtid: 2 tidsfel", u.fel == 2, fmt(u))
u = K.clearRound(runda({ nedslag = 1, overMaxtidS = 5 }))
check("ett nedslag och 5 s över maxtid: 4 + 2 = 6", u.fel == 6, fmt(u))

print("\n── Olydnader (381: t.o.m. 1,05/Lätt C +5) ──")
u = K.clearRound(runda({ olydnader = 1 }))
check("en olydnad: 4 fel", u.fel == 4 and u.utesluten == false, fmt(u))
u = K.clearRound(runda({ olydnader = 2 }))
check("två olydnader: ej felfri, ingen felsumma ([REFERENCE GAP] «8 fel»), inte utesluten", not u.felfri
	and u.fel == nil and u.utesluten == false and u.omstartMojlig, fmt(u))
u = K.clearRound(runda({ olydnader = 3 }))
check("tre olydnader: utesluten, omstart möjlig i försök 1", u.utesluten == true and u.fel == nil
	and not u.felfri and u.omstartMojlig, fmt(u))

print("\n── Uteslutning (381, 384.1, 388.2) ──")
for _, fall in { { { avfallning = true }, "avfallning" }, { { felVag = true }, "fel väg" },
	{ { overTillatenTid = true }, "tillåten tid överskriden" } } do
	u = K.clearRound(runda(fall[1]))
	check(fall[2] .. ": utesluten, ingen rosett, omstart möjlig", u.utesluten == true and not u.felfri
		and u.rosett == nil and u.fel == nil and u.omstartMojlig, fmt(u))
end
u = K.clearRound(runda({ forsok = 2, avfallning = true }))
check("uteslutning i försök 2: ingen ny omstart", u.utesluten == true and u.omstartMojlig == false, fmt(u))
u = K.clearRound(runda({ nedslag = 4 }))
check("fyra nedslag (16 hinderfel): inte utesluten, 16 fel", u.utesluten == false and u.fel == 16, fmt(u))
u = K.clearRound(runda({ nedslag = 5 }))
check("fem nedslag (20 > 16 hinderfel): utesluten", u.utesluten == true and u.fel == nil, fmt(u))
u = K.clearRound(runda({ nedslag = 3, olydnader = 1 }))
check("tre nedslag och en olydnad (16): inte utesluten", u.utesluten == false and u.fel == 16, fmt(u))
u = K.clearRound(runda({ nedslag = 2, olydnader = 2 }))
check("två nedslag och två olydnader (16 eller 20): uteslutning ej fastställd", u.utesluten == nil
	and not u.felfri and u.fel == nil, fmt(u))
u = K.clearRound(runda({ nedslag = 3, olydnader = 2 }))
check("tre nedslag och två olydnader (20 eller 24): utesluten oavsett tolkning", u.utesluten == true, fmt(u))
u = K.clearRound(runda({ nedslag = 1, olydnader = 2 }))
check("ett nedslag och två olydnader (12 eller 16): inte utesluten", u.utesluten == false and u.fel == nil, fmt(u))

print("\n── Giltighet (314.1.1) och indata ──")
u = K.clearRound(runda({ hojdM = 0.90 }))
check("0,90 m är giltigt", u.giltig and u.felfri, fmt(u))
u = K.clearRound(runda({ hojdM = 0.95 }))
check("0,95 m är inte giltigt för clear round", u.giltig == false and u.skal == "klass_over_090", fmt(u))
u = K.clearRound(runda({ ponny = true }))
check("ponny: ej giltig, namngiven referenslucka", u.giltig == false and u.skal == "ponny_klassordning_okand", fmt(u))
local NAN = 0 / 0
local trasiga = {
	{ nil, "ingen tabell" }, { runda({ forsok = 3 }), "försök 3" }, { runda({ nedslag = -1 }), "negativt nedslag" },
	{ runda({ nedslag = 1.5 }), "halvt nedslag" }, { runda({ olydnader = NAN }), "NaN olydnader" },
	{ runda({ overMaxtidS = math.huge }), "oändlig tid" }, { runda({ overMaxtidS = -1 }), "negativ tid" },
	{ runda({ hojdM = "0.8" }), "höjd som text" }, { runda({ avfallning = "nej" }), "avfallning som text" },
}
for _, t in trasiga do
	local ok, v = pcall(K.clearRound, t[1])
	check("felaktig indata kastar inte och är ogiltig: " .. t[2], ok and v.giltig == false and v.skal == "indata",
		ok and fmt(v) or tostring(v))
end
u = K.clearRound(runda())
check("svaret bär profil, regel och moment", u.profil == "A_CLEAR_ROUND" and u.regel == "SvRF TR III 2025"
	and table.find(u.moment, "314.1.1") ~= nil and table.find(u.moment, "381") ~= nil)
check("svaret är fryst", table.isfrozen(u))
check("ingen placering och ingen rosettfärg finns i svaret", u.placering == nil and u.farg == nil)

if fails > 0 then error(("%d mätning(ar) föll."):format(fails), 0) end
print(string.format("\nregelprofil.spec: %d prov, alla gröna", total))
