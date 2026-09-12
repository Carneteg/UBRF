--!nostrict
--[[
	UTRUSTNINGEN — fysisk, ägd och serverauktoritär (#162 blockerare 5).

	Före den här grinden betydde "sadlad" två booleans i en Lua-tabell.
	Ingen del skapades, uppsittningen prövade ingenting fysiskt, och en
	häst som aldrig sett en sadel satt man upp på precis som en sadlad.

	DET SOM MÄTS HÄR ÄR ATT LOGISKT OCH FYSISKT INTE KAN GLIDA ISÄR.
	`TackService` för inget register: `harTack()` letar upp delen i
	hästmodellen och läser dess attribut. Specen river därför delar ur
	världen och kontrollerar att tillståndet följer med — det är den enda
	mätning som skiljer "vi råkar hålla dem i synk" från "de kan inte
	glida isär".

	Utrustningens ÄGARSKAP kommer ur webbens sadelkammare
	(`src/sysslor.js`): varje häst har sin egen sadel och sitt eget träns,
	och fel utrustning nekas med ett skäl som förklarar varför.

	Kör: python3 roblox/tests/build.py tests/tack.spec.luau
	     && luau roblox/tests/.build/tack.spec.luau
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

local RunService = game:GetService("RunService")
RunService._server = true

local function nyKaraktar(cf)
	local k = Instance.new("Model")
	k.Name = "Karaktar"
	local rot = Instance.new("Part")
	rot.Name = "HumanoidRootPart"
	rot.Size = Vector3.new(2, 2, 1)
	rot.CFrame = cf
	rot.Parent = k
	local h = Instance.new("Humanoid")
	h.Name = "Humanoid"
	h.Parent = k
	k.Parent = workspace
	return k, rot
end

local function nySpelare(namn, cf)
	local k, rot = nyKaraktar(cf)
	return { Name = namn, UserId = 1, Character = k,
		CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }, rot
end

local MIN = Vector3.new(0, 0, 0)
local hast = HastRigg.bygg("blackrock_jack", "Blackrock Jack", CFrame.new(MIN))
hast.Parent = workspace
local annan = HastRigg.bygg("marabou", "Marabou", CFrame.new(Vector3.new(60, 0, 0)))
annan.Parent = workspace
local spelare, rot = nySpelare("SagaAberg", hast.PrimaryPart.CFrame * CFrame.new(3, 0, 0))

local function nollstall()
	TackService.taAvAllt(hast)
	TackService.taAvAllt(annan)
	TackService.nollstallFel(spelare)
	rot.CFrame = hast.PrimaryPart.CFrame * CFrame.new(3, 0, 0)
end

print("\n── Riggens anatomiska fästpunkter ──")

do
	local rig = RigAdapter.build(hast)
	check("riggen byggs", rig ~= nil)
	local platser = RigAdapter.tackplatser(rig)
	local har = {}
	for _, p in ipairs(platser) do har[p] = true end
	check("riggen bär sadelns plats", har.sadel == true)
	check("riggen bär tränsets plats", har.trans == true)
	check("riggen bär båda tygelpunkterna", har.tygelV == true and har.tygelH == true)
	--[[ Sitsen är en `Seat`, inte en fästpunkt, och nås som `rig.seat`.
		Den ligger därför inte i det anatomiska uppslaget. ]]
	check("riggen bär ryttarens sits som egen del", rig.seat ~= nil)
	check("och sitsen ligger INTE i fästpunktsuppslaget",
		RigAdapter.tackfaste(rig, "sits") == nil)

	--[[ TYGLARNA HÖR TILL HUVUDET, inte till bålen. `HORSE-MODEL-SPEC.md`
		är uttrycklig, och före blockerare 5 satt de på `HumanoidRootPart`:
		"Då följer händerna med när hästen sänker huvudet, vilket är hela
		poängen med tyglar." Den här raden faller om någon flyttar tillbaka
		dem till kroppen. ]]
	local vis = hast:FindFirstChild("Visual")
	local huvud = vis and vis:FindFirstChild("Head")
	check("hästen har en huvuddel", huvud ~= nil)
	local trans = RigAdapter.tackfaste(rig, "trans")
	local tygelV = RigAdapter.tackfaste(rig, "tygelV")
	check("tränsets fästpunkt sitter på HUVUDET, inte på bålen",
		trans ~= nil and trans.Parent == huvud,
		trans and tostring(trans.Parent and trans.Parent.Name) or "saknas")
	check("tygelpunkten sitter på HUVUDET, inte på bålen",
		tygelV ~= nil and tygelV.Parent == huvud,
		tygelV and tostring(tygelV.Parent and tygelV.Parent.Name) or "saknas")
	local sadel = RigAdapter.tackfaste(rig, "sadel")
	check("sadelns fästpunkt sitter på bålen",
		sadel ~= nil and sadel.Parent == hast.PrimaryPart,
		sadel and tostring(sadel.Parent and sadel.Parent.Name) or "saknas")

	--[[ Den döda `Attachments`-mappen är borta. Den skapades, parentades
		och användes aldrig — varje attachment hamnade på kroppen. ]]
	check("ingen död Attachments-mapp lämnad i riggen",
		hast:FindFirstChild("Attachments") == nil)
end

print("\n── Ordningen kommer ur kanon ──")

do
	check("kanon har fem utrustningssteg", TackService.antalSteg() == 5,
		tostring(TackService.antalSteg()))
	check("steg 1 lägger underlägget", TackService.fysiskFor(1) == "underlagg")
	check("steg 2 lägger sadeln", TackService.fysiskFor(2) == "sadel")
	check("steg 5 lägger tränset", TackService.fysiskFor(5) == "trans")
	check("steg 3 och 4 lägger inget nytt — de är handgrepp på sadeln",
		TackService.fysiskFor(3) == nil and TackService.fysiskFor(4) == nil)
	check("men de KRÄVER att sadeln ligger där",
		TackService.kraver(3) == "sadel" and TackService.kraver(4) == "sadel")
end

print("\n── Utrustningen blir FYSISK ──")

do
	nollstall()
	check("ingen utrustning från början", not TackService.sadlad(hast))
	check("och ingen del i världen", TackRigg.hittaDel(hast, "sadel") == nil)

	local ok1 = TackService.satPa(spelare, hast, "underlagg", nil, hast)
	check("underlägget går på", ok1)
	local ok2 = TackService.satPa(spelare, hast, "sadel", nil, hast)
	check("sadeln går på", ok2)

	local del = TackRigg.hittaDel(hast, "sadel")
	check("och det finns en VERKLIG del i hästmodellen", del ~= nil)
	check("delen är en BasePart", del ~= nil and del:IsA("BasePart"))
	check("delen bär vem den tillhör", del ~= nil and del:GetAttribute("ForHast") == "blackrock_jack",
		del and tostring(del:GetAttribute("ForHast")) or "-")
	--[[ Utrustning får inte ändra hästens kollisionshölje: lokomotionen är
		låst och ska inte påverkas av att hon blir sadlad. ]]
	check("utrustningen kolliderar inte", del ~= nil and del.CanCollide == false)
	--[[ Den ska FÖLJA hästen, alltså vara svetsad i en kroppsdel. ]]
	local svets = del and del:FindFirstChildOfClass("WeldConstraint")
	check("delen är svetsad i hästen, inte fri i världen", svets ~= nil)
	check("och svetsad i en del av HÄSTEN",
		svets ~= nil and svets.Part0 ~= nil and svets.Part0:IsDescendantOf(hast))

	local ok3 = TackService.satPa(spelare, hast, "trans", nil, hast)
	check("tränset går på", ok3)
	local td = TackRigg.hittaDel(hast, "trans")
	local tsvets = td and td:FindFirstChildOfClass("WeldConstraint")
	local huvud = hast:FindFirstChild("Visual"):FindFirstChild("Head")
	check("tränset är svetsat i HUVUDET, inte i bålen",
		tsvets ~= nil and tsvets.Part0 == huvud,
		tsvets and tostring(tsvets.Part0 and tsvets.Part0.Name) or "-")

	--[[ TYGLARNA hör till tränset: `leda` säger "med tyglarna över
		halsen", alltså sitter de när hon leds. De byggs med tränset och
		hänger i HUVUDET, så de följer med när hon sänker det. ]]
	local tygel = TackRigg.hittaDel(hast, "tygel")
	check("tyglarna kom med tränset", tygel ~= nil)
	local tyglsvets = tygel and tygel:FindFirstChildOfClass("WeldConstraint")
	check("och tyglarna hänger i HUVUDET",
		tyglsvets ~= nil and tyglsvets.Part0 == huvud,
		tyglsvets and tostring(tyglsvets.Part0 and tyglsvets.Part0.Name) or "-")
	TackService.taAv(spelare, hast, "trans")
	check("tränset av tar tyglarna med sig",
		TackRigg.hittaDel(hast, "tygel") == nil)
end

print("\n── Logiskt och fysiskt kan inte glida isär ──")

do
	nollstall()
	TackService.satPa(spelare, hast, "underlagg", nil, hast)
	TackService.satPa(spelare, hast, "sadel", nil, hast)
	check("sadlad när delen finns", TackService.sadlad(hast))

	--[[ SAKNAT VISUELLT MED GILTIGT TILLSTÅND. Rivs delen ur världen ska
		tillståndet följa med i samma ögonblick — det finns inget register
		som kan minnas en sadel som inte längre är där. ]]
	TackRigg.hittaDel(hast, "sadel"):Destroy()
	check("delen riven -> hästen är inte längre sadlad", not TackService.sadlad(hast))

	--[[ VISUELLT MED OGILTIGT TILLSTÅND. En del som tillhör en ANNAN häst
		får inte räknas som påsatt, hur fysisk den än är. ]]
	nollstall()
	TackService.satPa(spelare, hast, "underlagg", nil, hast)
	TackService.satPa(spelare, hast, "sadel", nil, hast)
	TackRigg.hittaDel(hast, "sadel"):SetAttribute("ForHast", "marabou")
	check("en sadel märkt för en annan häst räknas INTE som påsatt",
		not TackService.sadlad(hast))
	check("och hon är därmed inte ridklar", not TackService.ridklar(hast))
end

print("")
print("── Avtagningen lämnar ingenting kvar ──")

do
	--[[ Hittat i den kanoniska genomspelningen efter blockerare 5, inte av
		ett prov: tränset revs och sattes på igen, och hästen bar 14 delar
		i stället för 13. Höger tygel var svetsad i HUVUDET i stället för i
		vänster tygel, och `taAv` river bara den bärande delen plus det som
		sitter i HENNE. Den överlevde alltså varje avtagning och blev kvar
		hängande vid munnen.

		Provet räknar delar över en hel av-och-på-cykel. Ett antal som
		VÄXER är det enda som skiljer "allt följde med" från "något blev
		kvar" — en typkontroll hade sagt ja åt båda. ]]
	nollstall()
	for _, typ in ipairs({ "underlagg", "sadel", "trans" }) do
		TackService.satPa(spelare, hast, typ, nil, hast)
	end
	local function antal()
		local f = hast:FindFirstChild("Tack")
		return f and #f:GetChildren() or 0
	end
	local fullt = antal()
	check("full utrustning är ett bestämt antal delar", fullt > 0, tostring(fullt))

	TackService.taAv(spelare, hast, "trans")
	local utan = antal()
	check("tränset av -> inget träns och inga tyglar kvar",
		not TackService.transad(hast) and TackRigg.hittaDel(hast, "tygel") == nil,
		("%d delar kvar"):format(utan))
	local kvarTygel = 0
	for _, d in ipairs((hast:FindFirstChild("Tack") or hast):GetChildren()) do
		if d:IsA("BasePart") and d.Name == "Tygel" then kvarTygel += 1 end
	end
	check("ingen ensam tygel hänger kvar vid munnen", kvarTygel == 0,
		("%d tyglar kvar"):format(kvarTygel))

	TackService.satPa(spelare, hast, "trans", nil, hast)
	check("tränset på igen ger SAMMA antal delar, inte fler",
		antal() == fullt, ("%d -> %d -> %d"):format(fullt, utan, antal()))

	TackService.taAvAllt(hast)
	check("allt av lämnar ingenting kvar", antal() == 0, ("%d delar"):format(antal()))
end

print("\n── Negativa fall ──")

do
	nollstall()
	--[[ FEL HÄST. ]]
	local o, s = TackService.satPa(spelare, annan, "underlagg", nil, hast)
	check("fel häst nekas", o == false and s == "tack.fel_hast", tostring(s))

	--[[ UTRUSTNING SOM TILLHÖR EN ANNAN HÄST — webbens sadelkammarfel. ]]
	local o2, s2 = TackService.satPa(spelare, hast, "underlagg", "marabou", hast)
	check("utrustning för en annan häst nekas", o2 == false and s2 == "tack.fel_sadel",
		tostring(s2))
	check("och felet räknas, som webbens felUtrustning",
		TackService.felAntal(spelare) == 1, tostring(TackService.felAntal(spelare)))
	local o2b, s2b = TackService.satPa(spelare, hast, "trans", "marabou", hast)
	check("fel TRÄNS har sitt eget skäl", o2b == false and s2b == "tack.fel_trans",
		tostring(s2b))

	--[[ ORDNINGEN. ]]
	nollstall()
	local o3, s3 = TackService.satPa(spelare, hast, "sadel", nil, hast)
	check("sadeln utan underlägg nekas", o3 == false and s3 == "tack.underlagget_forst",
		tostring(s3))
	TackService.satPa(spelare, hast, "underlagg", nil, hast)
	local o4, s4 = TackService.satPa(spelare, hast, "trans", nil, hast)
	check("tränset före sadeln nekas", o4 == false and s4 == "tack.sadeln_forst",
		tostring(s4))

	--[[ DUBBEL PÅSÄTTNING, båda typerna. ]]
	local o5, s5 = TackService.satPa(spelare, hast, "underlagg", nil, hast)
	check("underlägget två gånger nekas", o5 == false and s5 == "tack.redan_pa", tostring(s5))
	TackService.satPa(spelare, hast, "sadel", nil, hast)
	local o6, s6 = TackService.satPa(spelare, hast, "sadel", nil, hast)
	check("sadeln två gånger nekas", o6 == false and s6 == "tack.redan_pa", tostring(s6))
	TackService.satPa(spelare, hast, "trans", nil, hast)
	local o7, s7 = TackService.satPa(spelare, hast, "trans", nil, hast)
	check("tränset två gånger nekas", o7 == false and s7 == "tack.redan_pa", tostring(s7))

	--[[ FÖR LÅNGT BORT — spelaren går ifrån mitt i flödet. ]]
	nollstall()
	rot.CFrame = hast.PrimaryPart.CFrame * CFrame.new(60, 0, 0)
	local o8, s8 = TackService.satPa(spelare, hast, "underlagg", nil, hast)
	check("för långt bort nekas", o8 == false and s8 == "tack.for_langt", tostring(s8))
	rot.CFrame = hast.PrimaryPart.CFrame * CFrame.new(3, 0, 0)

	--[[ OKÄND UTRUSTNING. ]]
	local o9, s9 = TackService.satPa(spelare, hast, "grimskaft", nil, hast)
	check("okänd utrustning nekas", o9 == false and s9 == "tack.okand_utrustning", tostring(s9))

	--[[ INGEN HÄST. ]]
	local o10, s10 = TackService.satPa(spelare, nil, "sadel", nil, nil)
	check("ingen häst alls nekas", o10 == false and s10 == "tack.ingen_hast", tostring(s10))

	--[[ ATT TA AV I FEL ORDNING. Eftervården säger "sadeln av innan
		tränset, annars står hon lös med sadeln kvar". ]]
	nollstall()
	TackService.satPa(spelare, hast, "underlagg", nil, hast)
	TackService.satPa(spelare, hast, "sadel", nil, hast)
	TackService.satPa(spelare, hast, "trans", nil, hast)
	local o11, s11 = TackService.taAv(spelare, hast, "sadel")
	check("sadeln av under tränset nekas", o11 == false and s11 == "tack.transet_forst",
		tostring(s11))
	local o12 = TackService.taAv(spelare, hast, "trans")
	check("tränset av först går", o12)
	local o13 = TackService.taAv(spelare, hast, "sadel")
	check("och sedan sadeln", o13)
	local o14, s14 = TackService.taAv(spelare, hast, "sadel")
	check("att ta av något som inte sitter på nekas",
		o14 == false and s14 == "tack.inget_pa", tostring(s14))
end

print("\n── Uppsittningen prövar det FYSISKA ──")

do
	nollstall()
	local o1, s1 = TackService.ridklar(hast)
	check("utan sadel: inte ridklar", o1 == false and s1 == "tack.saknar_sadel", tostring(s1))
	TackService.satPa(spelare, hast, "underlagg", nil, hast)
	TackService.satPa(spelare, hast, "sadel", nil, hast)
	local o2, s2 = TackService.ridklar(hast)
	check("med sadel men utan träns: inte ridklar",
		o2 == false and s2 == "tack.saknar_trans", tostring(s2))
	TackService.satPa(spelare, hast, "trans", nil, hast)
	check("med både sadel och träns: ridklar", TackService.ridklar(hast))
	--[[ Och tillbaka igen när delen rivs. ]]
	TackRigg.hittaDel(hast, "trans"):Destroy()
	check("tränset rivet -> inte ridklar längre", not TackService.ridklar(hast))
end

--[[ ══ GEOMETRIN MÅSTE VARA HÄSTENS, INTE LÅDANS ════════════════════

	Den visuella granskningen av K3 fällde utrustningen på TRE punkter,
	och alla tre var samma fel: måtten var absoluta meter som en gång
	passade lådhästen.

	  · tränset var en brun PLANKA tvärs genom kinden — nosgrimman var
	    bredare än hela huvudet,
	  · gjorden var en KLOSS under bålen och gick inte runt den,
	  · tyglarna slutade i LUFTEN bakom bettet.

	Mätningarna nedan är skrivna så att var och en av de tre kan bli röd
	igen. Falsifiering: sätt tillbaka `hb * 2.9` till `0.32 * M` i
	nosgrimman och den första faller; ta bort ringen och den andra
	faller; peka tygeln på en fast punkt och den tredje faller. ]]
print("\n── Utrustningen håller hästens egna mått ──")
do
	nollstall()
	TackService.satPa(spelare, hast, "underlagg", nil, hast)
	TackService.satPa(spelare, hast, "sadel", nil, hast)
	TackService.satPa(spelare, hast, "trans", nil, hast)
	local mapp = hast:FindFirstChild("Tack")
	local huvud = hast:FindFirstChild("Head", true)
	check("tacket ligger i hästmodellen", mapp ~= nil and huvud ~= nil)

	--[[ 1. INGEN TRÄNSDEL FÅR VARA BREDARE ÄN HUVUDET. Det är precis den
		mätning som hade fällt plankan genom kinden. ]]
	local bredast, bredastNamn = 0, "-"
	local transdelar = 0
	for _, d in ipairs(mapp:GetChildren()) do
		if d:IsA("BasePart") and (d.Name == "Träns" or d.Name:find("Tränsets ", 1, true) == 1) then
			transdelar += 1
			if d.Size.X > bredast then bredast, bredastNamn = d.Size.X, d.Name end
		end
	end
	check("tränset är byggt av flera delar", transdelar >= 6, tostring(transdelar) .. " delar")
	check("ingen tränsdel är bredare än huvudet", bredast <= huvud.Size.X,
		string.format("%s %.3f mot huvudets %.3f", bredastNamn, bredast, huvud.Size.X))

	--[[ 2. GJORDEN GÅR RUNT BÅLEN. Ett band runt något har segment på
		BÅDA sidor OCH under — en kloss under bålen har bara det sista. ]]
	local sadelA = hast:FindFirstChild("SaddleAttachment", true)
	local vanster, hoger, under = false, false, false
	for _, d in ipairs(mapp:GetChildren()) do
		if d:IsA("BasePart") and d.Name == "Sadelns gjord" then
			local p = sadelA.WorldCFrame:PointToObjectSpace(d.Position)
			if p.X < -0.3 then vanster = true end
			if p.X > 0.3 then hoger = true end
			if p.Y < -1.5 and math.abs(p.X) < 0.5 then under = true end
		end
	end
	check("gjorden har segment på vänster sida", vanster)
	check("gjorden har segment på höger sida", hoger)
	check("gjorden går under bålen", under)

	--[[ 3. TYGELN SLUTAR I EN HAND. Delens längd ska vara avståndet mellan
		bettet och handpunkten — inte en konstant. ]]
	local bett = hast:FindFirstChild("LeftReinAttachment", true)
	local hand = hast:FindFirstChild("LeftHandAttachment", true)
	check("riggen bär ryttarens handläge", hand ~= nil)
	local tygel
	for _, d in ipairs(mapp:GetChildren()) do
		if d:IsA("BasePart") and d.Name == "Tygel" then tygel = tygel or d end
	end
	--[[ LÄNGDEN ensam räcker inte som mätning: en tygel som pekar åt fel
		håll kan ha rätt längd. Det som mäts är ÄNDPUNKTEN — delens läge
		plus halva längden längs dess egen blickriktning — och den ska
		ligga i handen. Falsifierat: låter man tygeln falla tillbaka på en
		fast punkt framför sadeln blir längden fortfarande nästan rätt,
		men änden hamnar 0,4 studs fel och den här raden blir röd. ]]
	local vantad = bett and hand and (hand.WorldPosition - bett.WorldPosition).Magnitude or -1
	local ande = tygel and (tygel.Position + tygel.CFrame.LookVector * (tygel.Size.Z / 2))
	local miss = (ande and hand) and (ande - hand.WorldPosition).Magnitude or 1e9
	check("tygeln slutar i ryttarens hand", miss < 0.10,
		tygel and string.format("%.3f studs fel, längd %.3f mot bett->hand %.3f",
			miss, tygel.Size.Z, vantad) or "ingen tygel")

	--[[ 4. HANDLÄGET ÄR INTE BETTET. Det var hela ryttarposefelet: IK drog
		handen mot munnen, och överkroppen följde med. ]]
	check("handläget ligger närmare sadeln än bettet gör",
		hand ~= nil and bett ~= nil and sadelA ~= nil
			and (hand.WorldPosition - sadelA.WorldPosition).Magnitude
				< (bett.WorldPosition - sadelA.WorldPosition).Magnitude,
		hand and bett and sadelA and string.format("hand %.2f, bett %.2f",
			(hand.WorldPosition - sadelA.WorldPosition).Magnitude,
			(bett.WorldPosition - sadelA.WorldPosition).Magnitude) or "-")

	--[[ 5. OCH ALLT SKA FORTFARANDE GÅ ATT TA AV. Den nya geometrin har
		fler delar; kontraktet är att inte en enda blir kvar. ]]
	local fore = #mapp:GetChildren()
	TackService.taAv(spelare, hast, "trans")
	TackService.taAv(spelare, hast, "sadel")
	TackService.taAv(spelare, hast, "underlagg")
	local kvar = hast:FindFirstChild("Tack")
	check("hela utrustningen går av utan rester",
		kvar == nil or #kvar:GetChildren() == 0,
		string.format("%d delar på, %d kvar", fore,
			kvar and #kvar:GetChildren() or 0))
end

--[[ ══ HÄSTEN FÅR ALDRIG SITTA PÅ SIN EGEN SITS ═══════════════════════

	En `Seat` fångar varje `Humanoid` vars kropp rör den, och sitsen sitter
	fastsvetsad ovanpå hästens egen rot. Uppmätt under rosterprovet: åtta
	hästar som ställdes om hamnade i sin egen sits —

	    Humanoid.Sit = true · SeatPart = RiderSeat
	    HumanoidStateType.Seated · FloorMaterial = Air

	— och en sittande humanoid svävar och slutar lyda `Move`. Tre av de
	åtta gick inte att få loss utan att svetsen revs för hand.

	Att det inte händer under vanlig ridning är sant men är inget skydd.
	Vakten mäts därför här, mot den signal Roblox själv fyrar. ]]
print("\n── Hästen kan inte sätta sig på sin egen sits ──")

do
	local sits = hast:FindFirstChild("RiderSeat")
	local hastHum = hast:FindFirstChildOfClass("Humanoid")
	check("hästen har en sits och en humanoid", sits ~= nil and hastHum ~= nil)

	--[[ FÖRSTA SPÄRREN: sitsen får inte fånga någon genom beröring alls.
		Mätt i Studio med beröringen kvar satte hon sig OM i nästa bildruta
		efter att vakten kastat ut henne, och kom 1,21 studs på fyra
		sekunder med full order att gå. Uppsittningen går ändå inte den
		vägen — `HorseService.tryMount` anropar `seat:Sit()` rakt. ]]
	check("sitsen fångar ingen genom beröring", sits.CanTouch == false,
		("CanTouch=%s"):format(tostring(sits.CanTouch)))

	--[[ Så här ser det ut när Roblox har satt hästen i hennes egen sits:
		occupant satt, en `SeatWeld` skapad, och `Sit` sann. ]]
	local weld = Instance.new("Weld")
	weld.Name = "SeatWeld"
	weld.Parent = sits
	hastHum.Sit = true
	sits.Occupant = hastHum
	sits:GetPropertyChangedSignal("Occupant"):Fire()

	check("vakten släpper svetsen", sits:FindFirstChild("SeatWeld") == nil)
	check("och reser henne igen", hastHum.Sit == false,
		("Sit=%s"):format(tostring(hastHum.Sit)))

	--[[ RYTTAREN SKA FORTFARANDE SLÄPPAS IGENOM. Vakten får bara kasta ut
		humanoider som bor i HÄSTMODELLEN; en ryttare bor i sin karaktär.
		Utan den skillnaden hade rättningen gjort hästen omöjlig att rida. ]]
	local ryttare = spelare.Character:FindFirstChildOfClass("Humanoid")
	local ryttarWeld = Instance.new("Weld")
	ryttarWeld.Name = "SeatWeld"
	ryttarWeld.Parent = sits
	ryttare.Sit = true
	sits.Occupant = ryttare
	sits:GetPropertyChangedSignal("Occupant"):Fire()

	check("ryttarens svets rörs INTE", sits:FindFirstChild("SeatWeld") ~= nil)
	check("och ryttaren sitter kvar", ryttare.Sit == true,
		("Sit=%s"):format(tostring(ryttare.Sit)))
end

if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("\ntack.spec: alla gröna")
end
