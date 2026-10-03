--!nostrict
--[[ B4a NEDSLAGSHÄNDELSEN — docs/B4A-KNOCKDOWN-EVENT-CONTRACT.md.

	MODULKONTRAKT, minimal bänk: bara HinderObservation. Provet bygger egna
	bommar (en Part med HinderId), registrerar dem och matar segment med
	ritt-tid. En bom som "faller" flyttas av provet — ingen fysik finns här.
	Att en riktig bom i Roblox faller vid kontakt, och hur läget replikeras,
	är NOT_TESTED (Studio). Stängt vid fel: en bom som inte KAN falla ger
	aldrig "nej". ]]
local fails, total = 0, 0
local function check(name, yes, detalj)
	total += 1
	if not yes then fails += 1 end
	print((if yes then "  OK   " else "  FEL  ") .. name .. (if detalj then "  " .. tostring(detalj) else ""))
end
local vec = Vector3.new
local HO = HinderObservation
local HALV = vec(1, 1, 2) -- rotens halva mått (godtyckligt i provet)
local Y0 = 1.5 -- bommens mitt
local TJOCK = 0.3

local function bom(id, x, fysisk)
	local p = Instance.new("Part")
	p.Name = "Hinderbom " .. id
	p.Size = vec(8, TJOCK, TJOCK)
	local cf = CFrame.new(x, Y0, 0)
	p.CFrame = cf; p.Position = cf.Position
	p.Anchored = not fysisk
	p.CanCollide = fysisk
	p:SetAttribute("HinderId", id)
	p.Parent = workspace
	local ok = HO.registrera(p)
	assert(ok, "registrering")
	return p
end
local function flytta(p, dy)
	local pos = p.CFrame.Position + vec(0, dy, 0)
	p.CFrame = CFrame.new(pos); p.Position = pos
end

-- En ritt: hästen rider rakt över hindret vid x (längs z), 1 stud per 0,1 s.
local ritt, t
local function ny(namn)
	HO._glomForProv()
	ritt, t = "ritt_" .. namn, 0
	assert(HO.starta(ritt, "h", 1))
end
local function seg(x, z0, z1, luft)
	t += 0.1
	HO.segment(ritt, vec(x, 2.5, z0), vec(x, 2.5, z1), t, luft or "mark", HALV)
end
local function over(x, mitt)
	for z = -9, 8 do
		seg(x, z, z + 1)
		if mitt and z == 0 then mitt() end
	end
end
-- Tiden går vidare långt från alla hinder (utanför varje zon).
local function vanta(s)
	local n = math.ceil(s / 0.1)
	for _ = 1, n do seg(500, 500, 501) end
end
local function forsok(id, nr)
	for _, f in ipairs(HO.ogonblick(ritt).forsok) do
		if f.hinderId == id and f.nr == (nr or 1) then return f end
	end
	return nil
end
local function fmt(f)
	return f and ("%s/%s/%s t=%s"):format(f.utfall, f.nedslag, tostring(f.nedslagGrund), tostring(f.tNedslag)) or "inget försök"
end
local F = HO.NEDSLAG_FONSTER

print("\n── 1. Dagens bom (förankrad, kolliderar inte): aldrig «nej» ──")
do
	ny("idag")
	bom("a", 0, false)
	over(0)
	local f = forsok("a")
	check("passage, nedslag «okand» / bom_ej_fysisk", f and f.utfall == "passage" and f.nedslag == "okand"
		and f.nedslagGrund == "bom_ej_fysisk", fmt(f))
	vanta(F + 1)
	f = forsok("a")
	check("efter fönstret: fortfarande «okand», aldrig «nej»", f.nedslag == "okand", fmt(f))
	check("registret: fysisk = false", HO.register().hinder.a.fysisk == false)
	check("rivning och kontakt oförändrade", f.rivning == false and f.kontakt == "otillganglig")
end

print("\n── 2. Fysisk bom som ligger kvar: «vantar», sedan «nej» efter fönstret ──")
do
	ny("ligger")
	bom("a", 0, true)
	over(0)
	local f = forsok("a")
	check("vid stängningen: «vantar»", f and f.utfall == "passage" and f.nedslag == "vantar", fmt(f))
	vanta(F * 0.5)
	check("halva fönstret: fortfarande «vantar»", forsok("a").nedslag == "vantar", fmt(forsok("a")))
	vanta(F)
	f = forsok("a")
	check("efter fönstret: «nej» / bom_ligger", f.nedslag == "nej" and f.nedslagGrund == "bom_ligger", fmt(f))
	check("registret: fysisk = true", HO.register().hinder.a.fysisk == true)
end

print("\n── 3. Fysisk bom faller MEDAN försöket pågår ──")
do
	ny("under")
	local p = bom("a", 0, true)
	local tFall
	over(0, function() flytta(p, -1); tFall = t end)
	local f = forsok("a")
	check("«ja» / bom_foll direkt vid stängningen", f and f.nedslag == "ja" and f.nedslagGrund == "bom_foll", fmt(f))
	check("tNedslag är när fallet sågs (nästa segment efter flytten)", f.tNedslag ~= nil
		and f.tNedslag > tFall and f.tNedslag <= tFall + 0.1 + 1e-9, tostring(f.tNedslag))
end

print("\n── 4. Fall EFTER stängningen: inom fönstret «ja», efter fönstret tillskrivs det ingen ──")
do
	ny("inom")
	local p = bom("a", 0, true)
	over(0)
	vanta(F * 0.5)
	flytta(p, -1)
	vanta(0.2)
	local f = forsok("a")
	check("inom fönstret: «ja»", f.nedslag == "ja" and f.nedslagGrund == "bom_foll", fmt(f))
	ny("efter")
	local p2 = bom("a", 0, true)
	over(0)
	vanta(F + 0.5)
	flytta(p2, -1)
	vanta(0.5)
	f = forsok("a")
	check("efter fönstret: beslutet står, «nej»", f.nedslag == "nej", fmt(f))
end

print("\n── 5. Bommen låg redan nere när försöket började ──")
do
	ny("nere")
	local p = bom("a", 0, true)
	flytta(p, -1)
	over(0)
	vanta(F + 1)
	local f = forsok("a")
	check("«okand» / bom_ej_uppsatt, aldrig «ja» eller «nej»", f and f.nedslag == "okand"
		and f.nedslagGrund == "bom_ej_uppsatt", fmt(f))
end

print("\n── 6. Brott, ritt-slut, liten rörelse och borttagen bom ──")
do
	ny("brott")
	bom("a", 0, true)
	over(0)
	HO.brott(ritt, t)
	local f = forsok("a")
	check("brott under fönstret: «okand» / ej_fullstandigt", f.nedslag == "okand" and f.nedslagGrund == "ej_fullstandigt", fmt(f))
	ny("slut")
	bom("a", 0, true)
	over(0)
	HO.avsluta(ritt, "provslut")
	f = forsok("a")
	check("ritten slut under fönstret: «okand» / ritten_slut", f.nedslag == "okand" and f.nedslagGrund == "ritten_slut", fmt(f))
	ny("liten")
	local p = bom("a", 0, true)
	over(0, function() flytta(p, -(TJOCK * 0.5)) end)
	vanta(F + 1)
	f = forsok("a")
	check("rörelse mindre än tröskeln: inget «ja» (blir «nej»)", f.nedslag == "nej", fmt(f))
	ny("borta")
	local p2 = bom("a", 0, true)
	over(0)
	p2.Parent = nil
	HO.avregistreraDel(p2)
	vanta(0.2)
	f = forsok("a")
	check("bommen borttagen under fönstret: «okand» / hinder_saknas", f.nedslag == "okand"
		and f.nedslagGrund == "hinder_saknas", fmt(f))
	ny("brottUnder")
	local p3 = bom("a", 0, true)
	for z = -9, 0 do seg(0, z, z + 1) end
	flytta(p3, -1)
	HO.brott(ritt, t)
	f = forsok("a")
	check("brott medan försöket pågår: «okand» / ej_fullstandigt (aldrig «ja» ur ett ofullständigt försök)",
		f.nedslag == "okand" and f.nedslagGrund == "ej_fullstandigt", fmt(f))
end

print("\n── 7. Två hinder: ett fall tillskrivs aldrig fel hinder ──")
do
	ny("tva")
	bom("a", 0, true)
	local pb = bom("b", 30, true)
	over(0)
	flytta(pb, -1) -- b faller, men ingen har ridit b
	vanta(F + 1)
	local fa = forsok("a")
	check("hinder a: «nej»", fa.nedslag == "nej", fmt(fa))
	check("hinder b: inget försök, inget nedslag någonstans", forsok("b") == nil)
	-- Nu rids b efter att den föll: den låg nere när försöket började.
	over(30)
	local fb = forsok("b")
	check("b rids med bommen nere: «okand» / bom_ej_uppsatt", fb and fb.nedslag == "okand"
		and fb.nedslagGrund == "bom_ej_uppsatt", fmt(fb))
end

print("\n── 8. Ögonblicksbilden: nya fält, inga privata ──")
do
	ny("bild")
	local p = bom("a", 0, true)
	over(0, function() flytta(p, -1) end)
	local b = HO.ogonblick(ritt)
	local f = b.forsok[1]
	local privata = 0
	for k in pairs(f) do if string.sub(k, 1, 1) == "_" then privata += 1 end end
	check("fälten finns, fryst, inga privata nycklar", f.nedslag == "ja" and f.nedslagGrund == "bom_foll"
		and type(f.tNedslag) == "number" and table.isfrozen(f) and privata == 0, tostring(privata))
end

if fails > 0 then error(("%d mätning(ar) föll."):format(fails), 0) end
print(string.format("\nhindernedslag.spec: %d prov, alla gröna", total))
