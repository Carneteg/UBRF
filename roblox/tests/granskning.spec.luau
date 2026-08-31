--!nostrict
--[[
	F02:s granskningsläge — zonerna, dollhouse och vymodulen.

	Zonerna ska HÄRLEDAS ur UBRFKomplex, ligga inne i sina hus, bära en
	källklass ur gate-dokumentet, och luckorna ska finnas med som luckor.
	Dollhouse ska gömma taken och kunna sätta tillbaka dem exakt.

	Kör: python3 roblox/tests/build.py tests/granskning.spec.luau
	     && luau roblox/tests/.build/granskning.spec.luau
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

local TILLATNA = { PLAN = true, FOTO = true, DERIVED = true, GAP = true }

print("\n── Zonerna härleds ur datan ──")
local zoner = Granskning.zoner(UBRFKomplex)
do
	check("det finns zoner att granska", #zoner >= 12, #zoner .. " st")

	local utanforHus, feltyp, obyggdaPlan, gap = 0, 0, 0, 0
	for _, z in ipairs(zoner) do
		if not TILLATNA[z.klass] then feltyp += 1 end
		if z.klass == "GAP" then gap += 1 end
		if z.klass == "PLAN" and not z.byggd then obyggdaPlan += 1 end
		if z.rekt then
			local hus = UBRFKomplex[z.hus]
			if z.rekt.x < -0.01 or z.rekt.y < -0.01
				or z.rekt.x + z.rekt.w > hus.bredd + 0.01
				or z.rekt.y + z.rekt.h > hus.langd + 0.01 then
				utanforHus += 1
				print("       utanför: " .. z.id)
			end
		end
	end
	check("varje zon bär en klass ur gate-dokumentet", feltyp == 0, feltyp .. " okända")
	check("varje ritbar zon ligger inne i sitt hus", utanforHus == 0, utanforHus .. " utanför")

	--[[ Luckorna ÄR leverabeln. Försvinner de ur listan har någon "städat"
		bort precis det Fas 1 finns för att visa. ]]
	check("ridhusets entrédel finns med som OBYGGD",
		obyggdaPlan >= 1, obyggdaPlan .. " obyggda PLAN-zoner")
	check("minst två REFERENCE GAP-zoner finns kvar", gap >= 2, gap .. " st")

	local entredel
	for _, z in ipairs(zoner) do
		if z.id == "ridhus_entredel" then entredel = z end
	end
	check("entrédelen har entre-djupet ur datan",
		entredel and entredel.rekt and math.abs(entredel.rekt.h - UBRFKomplex.ridhus.entre) < 0.001,
		entredel and entredel.rekt and tostring(entredel.rekt.h) or "saknas")
end

print("\n── Zonplattorna byggs med identitet ──")
do
	local mapp = workspace:FindFirstChild("Anläggning")
	local ubrf = mapp and mapp:FindFirstChild("UBRF")
	check("det finns en byggd värld att lägga plattor i", ubrf ~= nil)
	if ubrf then
		local antal = Granskning.byggZoner(BuildKit, UBRFKomplex, ubrf, ubrf.PrimaryPart.CFrame)
		local ritbara = 0
		for _, z in ipairs(zoner) do
			if z.rekt then ritbara += 1 end
		end
		check("en platta per ritbar zon", antal == ritbara, antal .. " av " .. ritbara)

		local medId = 0
		for _, i in ipairs(ubrf:GetDescendants()) do
			if i:GetAttribute("RoomId") and i:GetAttribute("EvidenceClass") then medId += 1 end
		end
		check("varje platta bär RoomId och EvidenceClass", medId == antal,
			medId .. " av " .. antal)

		--[[ Andra passet får inte ackumulera plattor — samma regel som
			dörrprompterna och spawnen. ]]
		local antal2 = Granskning.byggZoner(BuildKit, UBRFKomplex, ubrf, ubrf.PrimaryPart.CFrame)
		check("andra passet dubblar inte plattorna", antal2 == antal,
			antal .. " → " .. antal2)
	end
end

print("\n── Dollhouse gömmer taken och sätter tillbaka dem ──")
do
	local mapp = workspace:FindFirstChild("Anläggning")
	local ubrf = mapp and mapp:FindFirstChild("UBRF")
	if ubrf then
		local gomda = Granskning.dollhouse(ubrf, true)
		check("det fanns takdelar att gömma", gomda > 0, gomda .. " st")

		local synliga = 0
		for _, i in ipairs(ubrf:GetDescendants()) do
			if i:GetAttribute("TakDel") == true and i.Transparency < 1 then
				synliga += 1
			end
		end
		check("alla takdelar är gömda", synliga == 0, synliga .. " synliga")

		local tillbaka = Granskning.dollhouse(ubrf, false)
		check("samma antal kom tillbaka", tillbaka == gomda, tillbaka .. " av " .. gomda)

		local kvarGomda = 0
		for _, i in ipairs(ubrf:GetDescendants()) do
			if i:GetAttribute("TakDel") == true and i.Transparency >= 1 then
				kvarGomda += 1
			end
		end
		check("ingen takdel blev kvar genomskinlig", kvarGomda == 0, kvarGomda .. " st")
	end
end

print("\n── Vymodulen: två kameror per zon, och fel som hörs ──")
do
	local modul = Granskning.vyModul(BuildKit, UBRFKomplex)
	check("två vyer per zon", #modul.vyer == #zoner * 2,
		#modul.vyer .. " för " .. #zoner .. " zoner")

	local ok = pcall(modul.ga, "finns_inte")
	check("okänd vy kastas i stället för att tigas bort", ok == false)

	local ok2 = pcall(modul.ga, modul.vyer[1].id)
	check("en riktig vy går att gå till", ok2 == true)

	--[[ Varje vytext ska bära källklassen — det är den Tobias bedömer mot. ]]
	local utanKlass = 0
	for _, v in ipairs(modul.vyer) do
		if not (string.find(v.text, "PLAN", 1, true)
			or string.find(v.text, "FOTO", 1, true)
			or string.find(v.text, "DERIVED", 1, true)
			or string.find(v.text, "GAP", 1, true)) then
			utanKlass += 1
		end
	end
	check("varje vytext bär sin källklass", utanKlass == 0, utanKlass .. " utan")
end

if fails > 0 then
	print(string.format("\n%d FEL", fails))
	error("granskning.spec: " .. fails .. " fel")
end
print("\ngranskningen: alla gröna")
