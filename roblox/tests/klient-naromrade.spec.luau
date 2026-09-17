--!nostrict
--[[
	NÄROMRÅDET — touchvägen till allt man kan göra vid hästen (#235).

	Tobias verifierade på FYSISK iPhone att First Playable är ospelbart
	före ridning: sadel och träns går inte att hämta, hästen går inte att
	interagera med, ledningen går inte att starta.

	Mätt i Studio med iPhone 13-emulering, spelaren 4,3 studs från sin
	egen hästs utrustning:

	    ProximityPromptService.PromptShown   0 gånger på 2 sekunder
	    prompter inom sin räckvidd           5 stycken

	Två fel i samma bild: promptlagret ritar ingenting i vår stack, och
	även när det gör det ska tummen träffa rätt av fem flytande knappar
	i djupet.

	VAD SPECEN MÄTER, och varför just det:

	  1. att alla FYRA interaktionsfamiljerna — utrustning, boxdörr,
	     ledning och uppsittning — får en rad. Kravet i #235 punkt 7 är
	     uttryckligen att ingen av dem får sakna touchväg;
	  2. att trycket går genom promptens EGEN väg, alltså att serverns
	     handlare körs precis som med en tangent. En mobil genväg förbi
	     servern vore ett sämre fel än det vi rättar;
	  3. att ordningen är närmast först — det är det spelaren menar;
	  4. att listan inte ritas på skrivbord och inte medan man rider.

	VAD SOM INTE MÄTS: hur det ser ut, och om tummen faktiskt når. Det är
	Tobias fysiska iPhone-grind och står som sådan i rapporten.

	Kör: python3 roblox/tests/build.py tests/klient-naromrade.spec.luau
	     && luau roblox/tests/.build/klient-naromrade.spec.luau
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

local N = Naromrade

--[[ En prompt i världen, som tjänsterna bygger dem. ]]
local function nyPrompt(namn, handling, objekt, lage, rackvidd, hold)
	local del = Instance.new("Part")
	del.Name = namn
	del.Position = lage
	del.Parent = workspace
	local p = Instance.new("ProximityPrompt")
	p.Name = namn .. "Prompt"
	p.ActionText = handling
	p.ObjectText = objekt or ""
	p.MaxActivationDistance = rackvidd or 8
	p.HoldDuration = hold or 0
	p.RequiresLineOfSight = false
	p.Parent = del
	return p, del
end

local HAR = Vector3.new(0, 0, 0)

print("\n── Alla fyra interaktionsfamiljerna får en rad ──")

do
	--[[ Samma fyra familjer som #235 räknar upp, på de avstånd mätningen
		i Studio faktiskt gav. ]]
	local tack = nyPrompt("Sadel", "Ta sadel och träns", "Trixie", Vector3.new(4.3, 0, 0))
	local dorr = nyPrompt("Boxdörr MB 7", "Öppna", "", Vector3.new(2.5, 0, 0))
	local led = nyPrompt("Häst", "Led Trixie", "Trixie", Vector3.new(6, 0, 0), 12)
	local upp = nyPrompt("Sadelpunkt", "Sitt upp", "Trixie", Vector3.new(6.5, 0, 0), 12)

	local nara = N.nara(HAR, { workspace })
	local funna = {}
	for _, p in ipairs(nara) do funna[p.ActionText] = true end

	check("utrustningen har en touchväg", funna["Ta sadel och träns"] == true)
	check("boxdörren har en touchväg", funna["Öppna"] == true)
	check("ledningen har en touchväg", funna["Led Trixie"] == true)
	check("uppsittningen har en touchväg", funna["Sitt upp"] == true)

	--[[ ORDNINGEN ÄR NÄRMAST FÖRST. Det spelaren menar är det hon står
		vid, inte det som råkade hittas först i trädet. ]]
	check("närmast först", nara[1] == dorr and nara[2] == tack,
		("[1]=%s [2]=%s"):format(nara[1] and nara[1].ActionText or "-",
			nara[2] and nara[2].ActionText or "-"))

	--[[ RÄCKVIDDEN ÄR PROMPTENS EGEN. En prompt utanför sin räckvidd är
		inte en handling som går att göra, och får därför ingen rad —
		annars hade listan lovat något servern sedan nekar. ]]
	local langt = nyPrompt("Långtbort", "Öppna", "", Vector3.new(40, 0, 0))
	local nara2 = N.nara(HAR, { workspace })
	local harLangt = false
	for _, p in ipairs(nara2) do if p == langt then harLangt = true end end
	check("en prompt utanför sin egen räckvidd får ingen rad", harLangt == false)

	--[[ En avstängd prompt är inte heller en handling. ]]
	dorr.Enabled = false
	local nara3 = N.nara(HAR, { workspace })
	local harDorr = false
	for _, p in ipairs(nara3) do if p == dorr then harDorr = true end end
	check("en avstängd prompt får ingen rad", harDorr == false)
	dorr.Enabled = true

	--[[ Fästpunkter räknas som världslägen. Uppsittningens prompt hänger
		i sadelpunkten, inte i en del — utan det här tappar listan just
		den familj #235 räknar upp sist. ]]
	local varddel = Instance.new("Part")
	varddel.Position = Vector3.new(3, 0, 0)
	varddel.Parent = workspace
	local fast = Instance.new("Attachment")
	fast.Position = Vector3.new(0, 0, 0)
	fast.Parent = varddel
	local pf = Instance.new("ProximityPrompt")
	pf.ActionText = "Sitt upp (fäste)"
	pf.MaxActivationDistance = 8
	pf.RequiresLineOfSight = false
	pf.Parent = fast
	local nara4 = N.nara(HAR, { workspace })
	local harFaste = false
	for _, p in ipairs(nara4) do if p == pf then harFaste = true end end
	check("en prompt som hänger i en Attachment kommer också med", harFaste == true)
end

print("\n── Listan RITAS, och trycket går genom promptens EGEN väg ──")

do
	for _, d in ipairs(workspace:GetChildren()) do
		if d:IsA("BasePart") then d:Destroy() end
	end

	--[[ EN RIKTIG KARAKTÄR. Utan `HumanoidRootPart` har `rita()` ingen
		punkt att mäta från, och listan blir tom — då blir varje mätning
		nedan sann av sig själv.

		DET VAR PRECIS DET FELET FÖRSTA VERSIONEN AV DEN HÄR SPECEN
		GJORDE. Tre mutationer kom ut GRÖNA i falsifieringen: trycket som
		aldrig nådde prompten, skyddet mot en föräldralös prompt, och att
		listan släcks under ritten. Alla tre "passerade" för att proven
		mätte stubben eller en tom lista i stället för produktionens väg.
		Ett prov som inte kan bli rött är ingen grind. ]]
	local Players = game:GetService("Players")
	local UIS = game:GetService("UserInputService")
	local kar = Instance.new("Model")
	kar.Name = "Spelare"
	local rot = Instance.new("Part")
	rot.Name = "HumanoidRootPart"
	rot.Position = Vector3.new(0, 0, 0)
	rot.Parent = kar
	kar.Parent = workspace
	Players.LocalPlayer.Character = kar

	UIS.TouchEnabled = true
	N.stopp()
	N.start()

	local sadel = nyPrompt("Sadel", "Ta sadel och träns", "Trixie", Vector3.new(3, 0, 0))
	local dorr = nyPrompt("Boxdörr MB 7", "Öppna", "", Vector3.new(5, 0, 0))
	--[[ `satRider(false)` ritar om direkt — samma väg `init.client`
		använder vid avsittning, och deterministisk till skillnad från att
		vänta på nästa bildruta. ]]
	N.satRider(false)

	local synliga = N._rader()
	check("listan RITAS med en rad per handling", #synliga == 2,
		("%d rader: %s"):format(#synliga, table.concat(synliga, " | ")))
	check("närmast först också på skärmen",
		synliga[1] ~= nil and synliga[1]:find("Ta sadel") ~= nil,
		tostring(synliga[1]))
	check("raden bär både handlingen och objektet",
		synliga[1] ~= nil and synliga[1]:find("Trixie") ~= nil,
		tostring(synliga[1]))

	--[[ TRYCKET GENOM NÄROMRÅDETS EGEN VÄG. Att anropa promptens
		`InputHoldBegin` själv hade mätt stubben, inte den här filen. ]]
	local fyrade = 0
	sadel.Triggered:Connect(function() fyrade += 1 end)
	N._tryckPa(1)
	task.wait()
	check("ett tryck på rad 1 utlöser promptens egen Triggered",
		fyrade == 1, tostring(fyrade))

	local dorrFyrade = 0
	dorr.Triggered:Connect(function() dorrFyrade += 1 end)
	N._tryckPa(2)
	task.wait()
	check("och rad 2 utlöser SIN prompt, inte den förstas",
		dorrFyrade == 1 and fyrade == 1,
		("sadel %d · dörr %d"):format(fyrade, dorrFyrade))

	--[[ EN RAD KAN LIGGA KVAR EN BILDRUTA efter att hästen försvunnit.
		Trycket måste tåla det — utan att kasta och utan att utlösa. ]]
	sadel.Parent = nil
	local okTryck = pcall(function() N._tryckPa(1) end)
	task.wait()
	check("ett tryck på en prompt utan förälder kastar inte", okTryck == true)
	check("och utlöser ingenting", fyrade == 1, tostring(fyrade))

	--[[ MEDAN MAN RIDER äger `TouchControls` skärmen. ]]
	N.satRider(true)
	check("medan man rider är listan släckt", #N._rader() == 0,
		("%d rader"):format(#N._rader()))
	N.satRider(false)
	check("och den kommer tillbaka vid avsittning", #N._rader() > 0,
		("%d rader"):format(#N._rader()))
	N.stopp()
end

print("\n── Skrivbordet rörs inte ──")

do
	local UIS = game:GetService("UserInputService")
	UIS.TouchEnabled = false
	N.stopp()
	N.start()
	N.satRider(false)
	check("utan pekskärm byggs ingenting", #N._rader() == 0)
	UIS.TouchEnabled = true
	N.stopp()
end

if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("\nklient-naromrade.spec: alla gröna")
end
