--!nostrict
--[[
	RIDLOGGEN — #264 INFRA-2A.

	Mäter serverns händelselogg per ritt genom PRODUKTIONENS vägar in i
	`HorseService`: `tryMount`, `RidingIntent` via samma `OnServerEvent` som
	servern kopplar i `start()`, `dismount`, städsignalerna (död, karaktären
	borta, spelaren lämnar), trötthetstaket via `Heartbeat` och
	avregistreringen via taggen. Loggen läses genom `HorseService.ridlogg`.

	Alla block utom det sista skriver loggen enbart genom produktionen; de
	använder `RidLogg` direkt bara för `_glomForProv` mellan block. Det
	sista blocket, MODULKONTRAKT, anropar modulen direkt och är
	uttryckligen ett modulbevis (se noten där).

	EVIDENSNIVÅ: BANK_ONLY. Syntetiska sekvenser i stubbvärlden. Ingen motor,
	ingen klient, ingen riktig tid på nätet.
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

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Taggar = game:GetService("CollectionService")
local vec = Vector3.new

local function nyKaraktar(pos)
	local k = Instance.new("Model")
	k.Name = "Karaktar"
	local rot = Instance.new("Part")
	rot.Name = "HumanoidRootPart"
	rot.Size = vec(2, 2, 1)
	rot.CFrame = CFrame.new(pos)
	rot.Parent = k
	local hum = Instance.new("Humanoid")
	hum.Name = "Humanoid"
	hum.Parent = k
	local anim = Instance.new("Animator")
	anim.Name = "Animator"
	anim.Parent = hum
	return k, rot, hum
end

local function nySpelare(namn, userId, pos)
	return { Name = namn, UserId = userId, Character = (nyKaraktar(pos)),
		CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }
end

Taggar:nollstall()
RunService._server = true
RunService.Heartbeat:nollstall()
local anna = nySpelare("Anna", 201, vec(6, 0, 0))
local bea = nySpelare("Bea", 202, vec(46, 0, 0))
Players._spelare = { anna, bea }
HorseService.setMountGate(nil)
HorseService.start()

local hastA = HastRigg.bygg("blackrock_jack", "Blackrock Jack", CFrame.new(vec(0, 0, 0)))
hastA.Parent = workspace
Taggar:AddTag(hastA, "Horse")
local hastB = HastRigg.bygg("cosmo", "Cosmo", CFrame.new(vec(40, 0, 0)))
hastB.Parent = workspace
Taggar:AddTag(hastB, "Horse")

local function avsikt(sp, marke, handling, sekvens)
	Networking.get("RidingIntent").OnServerEvent:Fire(sp, marke, handling, sekvens)
end
--[[ Uppställning: töm spärren och fyll skopan, så att nästa avsikt
	prövas på sina egna meriter. Spärren mäts för sig nedan. ]]
local function redo(modell)
	local s = HorseService.sessionFor(modell)
	s.sisteHjalp = -math.huge
	s.intentPolletter = Config.RIDINPUT.SkopaTak
	return s
end
local function typer(post)
	local ut = {}
	for _, h in ipairs(post.handelser) do table.insert(ut, h.typ) end
	return table.concat(ut, ",")
end
local function sitUpp(sp, modell)
	local ok, skal, marke = HorseService.tryMount(sp, modell)
	assert(ok, "uppsittningen föll: " .. tostring(skal))
	return marke
end

print("\n── Normal ritt: uppsittning → accepterade steg → avsittning ──")
local marke1
do
	RidLogg._glomForProv()
	marke1 = sitUpp(anna, hastA)
	local p = HorseService.ridlogg(marke1)
	check("uppsittningen öppnar en post", p ~= nil and p.oppen == true and p.rittId == marke1)
	check("med hästens stabila id och ryttaren", p.hastId == "blackrock_jack" and p.userId == 201,
		tostring(p.hastId))
	check("första händelsen är uppsittning i halt", p.handelser[1].typ == "uppsittning"
		and p.handelser[1].data.gangart == "halt" and p.handelser[1].n == 1)

	redo(hastA); avsikt(anna, marke1, "driv")
	redo(hastA); avsikt(anna, marke1, "driv")
	p = HorseService.ridlogg(marke1)
	check("två accepterade DRIV ger två gångartshändelser", typer(p) == "uppsittning,gangart,gangart", typer(p))
	local h2, h3 = p.handelser[2], p.handelser[3]
	check("med gammalt och nytt läge", h2.data.fran == "halt" and h2.data.till == "walk"
		and h3.data.fran == "walk" and h3.data.till == "trot",
		("%s→%s, %s→%s"):format(h2.data.fran, h2.data.till, h3.data.fran, h3.data.till))
	check("orsaken är hjälpen", h2.data.orsak == "hjalp" and h2.data.handling == "driv")

	--[[ RYGGNING: halt + BROMS. ]]
	redo(hastA); avsikt(anna, marke1, "broms")
	redo(hastA); avsikt(anna, marke1, "broms")
	redo(hastA); avsikt(anna, marke1, "broms")
	p = HorseService.ridlogg(marke1)
	local sista = p.handelser[#p.handelser]
	check("ryggningen loggas med sin flagga", sista.data.fran == "halt" and sista.data.franRyggar == false
		and sista.data.tillRyggar == true, ("%s ryggar=%s"):format(sista.data.till, tostring(sista.data.tillRyggar)))
	redo(hastA); avsikt(anna, marke1, "driv")

	local ok = HorseService.dismount(anna)
	p = HorseService.ridlogg(marke1)
	check("avsittningen stänger posten", ok == true and p.oppen == false)
	check("som AVSLUTAD, med orsak", p.satt == "avslutad" and p.handelser[#p.handelser].typ == "avslut"
		and p.handelser[#p.handelser].data.orsak == "avsittning")
	check("och en normalt avslutad post utan tapp är bedömbar som livscykel", p.bedombar == true)

	--[[ Ordning, tid och serialiserbarhet. ]]
	local ordnad, andlig, serialiserbar = true, true, true
	local forraT = -1
	for i, h in ipairs(p.handelser) do
		if h.n ~= i then ordnad = false end
		if type(h.t) ~= "number" or h.t ~= h.t or h.t == math.huge or h.t < forraT then andlig = false end
		forraT = h.t
		for k, v in pairs(h.data) do
			local t = type(v)
			if type(k) ~= "string" or not (t == "string" or t == "number" or t == "boolean") then
				serialiserbar = false
			end
		end
	end
	check("löpnumren är 1..n i ordning", ordnad)
	check("tiden är ändlig och minskar aldrig", andlig)
	check("all data är serialiserbara skalärer", serialiserbar)

	--[[ UPPREPAD AVSITTNING: ett nej, och ingen andra avslutshändelse. ]]
	local antalFore = #p.handelser
	local igen = HorseService.dismount(anna)
	check("en andra avsittning nekas", igen == false)
	check("och lägger ingen händelse till", #HorseService.ridlogg(marke1).handelser == antalFore)
end

print("\n── Nej loggas inte: inaktuellt, dubblett, spärr, tak, skräp ──")
do
	local marke2 = sitUpp(anna, hastA)
	check("ny uppsittning ger ett NYTT märke", marke2 ~= marke1)
	local p0 = #HorseService.ridlogg(marke2).handelser

	redo(hastA); avsikt(anna, marke1, "driv")
	check("en avsikt med förra rittens märke loggas inte", #HorseService.ridlogg(marke2).handelser == p0)
	check("och rör inte den stängda posten", HorseService.ridlogg(marke1).oppen == false)

	redo(hastA); avsikt(anna, "hittepa", "driv")
	redo(hastA); avsikt(anna, marke2, "galopp")
	redo(hastA); avsikt(anna, nil, "driv")
	check("fel märke, okänd handling och saknat märke loggas inte", #HorseService.ridlogg(marke2).handelser == p0)

	redo(hastA); avsikt(anna, marke2, "driv", 5)
	local efterForsta = #HorseService.ridlogg(marke2).handelser
	check("KONTROLL: en giltig avsikt med sekvens loggas", efterForsta == p0 + 1)
	redo(hastA); avsikt(anna, marke2, "driv", 5)
	check("samma sekvens igen (återspelad) loggas inte", #HorseService.ridlogg(marke2).handelser == efterForsta)

	--[[ TAKET: rättelse utan ändring. Hon står i skritt och taket är
		skritt; `replikera` körs, men ingen övergång accepterades. ]]
	hastA:SetAttribute("GaitCeiling", "walk")
	local versionFore = hastA:GetAttribute("RidVersion")
	redo(hastA); avsikt(anna, marke2, "driv", 7)
	check("DRIV mot taket replikerar en rättelse", hastA:GetAttribute("RidVersion") > versionFore)
	check("men loggar ingen övergång", #HorseService.ridlogg(marke2).handelser == efterForsta)
	hastA:SetAttribute("GaitCeiling", nil)

	--[[ SPÄRREN: en accepterad hjälp, och direkt efter den en till utan
		att spärren nollställs. ]]
	redo(hastA); avsikt(anna, marke2, "driv", 8)
	local efterAndra = #HorseService.ridlogg(marke2).handelser
	check("KONTROLL: hjälpen före spärrprovet loggas", efterAndra == efterForsta + 1)
	HorseService.sessionFor(hastA).intentPolletter = Config.RIDINPUT.SkopaTak
	avsikt(anna, marke2, "broms", 9)
	check("en avsikt inom impulsspärren loggas inte", #HorseService.ridlogg(marke2).handelser == efterAndra)
	efterForsta = efterAndra

	--[[ BEA på en annan häst: hennes avsikter når aldrig Annas post. ]]
	local markeB = sitUpp(bea, hastB)
	redo(hastB); avsikt(bea, markeB, "driv")
	redo(hastB); avsikt(bea, marke2, "driv")
	check("två ryttare har var sin post", HorseService.ridlogg(markeB).hastId == "cosmo"
		and HorseService.ridlogg(markeB).userId == 202)
	check("Beas hjälp hamnar i hennes post", #HorseService.ridlogg(markeB).handelser == 2)
	check("och Annas märke i Beas avsikt rör ingenting", #HorseService.ridlogg(marke2).handelser == efterForsta)

	HorseService.dismount(anna)
	HorseService.dismount(bea)
end

print("\n── Avbrott: död, karaktären borta, spelaren lämnar, hästen borta ──")
do
	local function avbrott(namn, gor, forvantad)
		local m = sitUpp(anna, hastA)
		gor()
		local p = HorseService.ridlogg(m)
		check(namn .. " stänger posten som AVBRUTEN", p and p.oppen == false and p.satt == "avbruten"
			and p.handelser[#p.handelser].data.orsak == forvantad,
			p and (tostring(p.satt) .. " " .. tostring(p.handelser[#p.handelser].data.orsak)) or "ingen post")
		check(namn .. ": en avbruten post är inte bedömbar", p and p.bedombar == false)
		if HorseService.horseOf(anna) then HorseService.dismount(anna) end
	end
	avbrott("döden", function()
		anna.Character:FindFirstChildOfClass("Humanoid").Died:Fire()
	end, "dog")
	avbrott("karaktären borta", function() anna.CharacterRemoving:Fire() end, "karaktar_borta")
	avbrott("spelaren lämnar", function() Players.PlayerRemoving:Fire(anna) end, "lamnar")

	local m = sitUpp(anna, hastA)
	Taggar:RemoveTag(hastA, "Horse")
	local p = HorseService.ridlogg(m)
	check("hästen avregistreras mitt i ritten: avbruten", p and p.oppen == false and p.satt == "avbruten"
		and p.handelser[#p.handelser].data.orsak == "hast_avregistrerad")
	Taggar:AddTag(hastA, "Horse")
end

print("\n── Trötthetstaket är en accepterad serveröverång ──")
do
	RidLogg._glomForProv()
	local m = sitUpp(anna, hastA)
	--[[ Upp i galopp: trötthetstakets golv är trav (`Config.STAMINA`). ]]
	redo(hastA); avsikt(anna, m, "driv")
	redo(hastA); avsikt(anna, m, "driv")
	redo(hastA); avsikt(anna, m, "driv")
	HorseService.sessionFor(hastA).energi = 0
	RunService.Heartbeat:Fire(0.30)
	local p = HorseService.ridlogg(m)
	local sista = p.handelser[#p.handelser]
	check("taket drar ned trappan och det loggas", sista.typ == "gangart" and sista.data.orsak == "trotthet",
		sista.typ .. " " .. tostring(sista.data.orsak))
	HorseService.dismount(anna)
end

print("\n── Ögonblicksbilden går inte att skriva om ──")
do
	local m = sitUpp(anna, hastA)
	local bild = HorseService.ridlogg(m)
	local ok1 = pcall(function() bild.satt = "avslutad" end)
	local ok2 = pcall(function() bild.handelser[1].typ = "vann" end)
	local ok3 = pcall(function() bild.handelser[1].data.gangart = "canter" end)
	local ok4 = pcall(function() table.insert(bild.handelser, { typ = "falsk" }) end)
	check("posten är fryst", ok1 == false)
	check("händelserna är frysta", ok2 == false and ok4 == false)
	check("datan är fryst", ok3 == false)
	local ny = HorseService.ridlogg(m)
	check("en ny bild är orörd", ny.oppen == true and ny.handelser[1].typ == "uppsittning"
		and ny.handelser[1].data.gangart == "halt" and #ny.handelser == 1)
	HorseService.dismount(anna)
end

print("\n── Taket per ritt och kvarhållningen ──")
do
	RidLogg._glomForProv()
	local m = sitUpp(anna, hastA)
	for i = 1, RidLogg.MAX_HANDELSER + 20 do
		redo(hastA); avsikt(anna, m, if i % 2 == 1 then "driv" else "broms")
	end
	local p = HorseService.ridlogg(m)
	check("överflödet syns", p.overflode == true and p.tappade > 0, ("tappade %d"):format(p.tappade))
	check("posten växer aldrig över taket", #p.handelser <= RidLogg.MAX_HANDELSER, tostring(#p.handelser))
	HorseService.dismount(anna)
	p = HorseService.ridlogg(m)
	check("en full ritt kan ändå stängas", p.oppen == false and p.handelser[#p.handelser].typ == "avslut")
	check("men den är INTE bedömbar", p.bedombar == false)
	check("och har exakt taket, avslutet inräknat", #p.handelser == RidLogg.MAX_HANDELSER, tostring(#p.handelser))

	RidLogg._glomForProv()
	local forsta = sitUpp(anna, hastA)
	HorseService.dismount(anna)
	for _ = 1, RidLogg.MAX_AVSLUTADE do
		sitUpp(anna, hastA)
		HorseService.dismount(anna)
	end
	check("äldsta hela posten gallras när ringen är full", HorseService.ridlogg(forsta) == nil
		and RidLogg.gallrade() == 1, ("gallrade %d"):format(RidLogg.gallrade()))
	local pagaende = sitUpp(anna, hastA)
	for _ = 1, RidLogg.MAX_AVSLUTADE + 5 do
		sitUpp(bea, hastB)
		HorseService.dismount(bea)
	end
	check("en ÖPPEN post gallras aldrig", HorseService.ridlogg(pagaende) ~= nil
		and HorseService.ridlogg(pagaende).oppen == true)
	HorseService.dismount(anna)
end

print("\n── MODULKONTRAKT (inte produktionsväg): en stängd post är stängd ──")
do
	--[[ De här två vakterna kan INTE nås genom HorseService i dag: tjänsten
		skickar alltid sessionens AKTUELLA märke, och det är nil efter
		avslutet. De mäts därför direkt mot modulen, och det är uttryckligen
		ett modulbevis — inte ett bevis om produktionsvägen. Vakterna finns
		kvar som försvar mot en framtida anropare. ]]
	RidLogg._glomForProv()
	RidLogg.starta("kontrakt", "cosmo", 1, "halt", 10)
	check("KONTROLL: en öppen post tar emot en gångart",
		RidLogg.gangart("kontrakt", { fran = "halt", till = "walk" }, 11) == true)
	check("KONTROLL: första avslutet stänger", RidLogg.avsluta("kontrakt", "avslutad", "avsittning", 12) == true)
	check("en stängd post tar inte emot en gångart",
		RidLogg.gangart("kontrakt", { fran = "walk", till = "trot" }, 13) == false)
	check("och stängs inte en andra gång", RidLogg.avsluta("kontrakt", "avbruten", "dog", 14) == false)
	local p = RidLogg.ogonblick("kontrakt")
	check("posten är oförändrad efter båda nejen", #p.handelser == 3 and p.satt == "avslutad",
		("%d händelser, %s"):format(#p.handelser, tostring(p.satt)))
end

if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("\nridlogg.spec: alla gröna")
end
