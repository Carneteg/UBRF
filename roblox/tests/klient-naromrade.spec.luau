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

--[[ ══ #246 C: EN INTERAKTIONSYTA PÅ TOUCH ═══════════════════════════

	QA 2026-09-18: `UBRFNaromrade` visade upp till fem skärmknappar samtidigt
	som Roblox EGNA prompt-knappar renderades för samma handlingar.

	Kravet är precist: prompten ska förbli den auktoritära
	aktiveringsvägen, och bara den konkurrerande BILDEN får döljas. Provet
	mäter därför tre saker — att bilden släcks, att aktiveringen överlever
	släckningen, och att den tänds igen när raden försvinner. ]]
print("\n── En interaktionsyta på touch ──")
do
	for _, d in ipairs(workspace:GetChildren()) do
		if d:IsA("BasePart") then d:Destroy() end
	end
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

	local sadel = nyPrompt("Sadel", "Ta sadeln", "Trixies sadel", Vector3.new(3, 0, 0))
	check("prompten börjar med Roblox egen stil",
		sadel.Style == Enum.ProximityPromptStyle.Default
			or sadel.Style == nil, tostring(sadel.Style))
	N.satRider(false)

	check("listan ritar en rad för handlingen", #N._rader() == 1,
		("%d rader"):format(#N._rader()))
	check("och Robloxs EGNA bild för samma handling är släckt",
		sadel.Style == Enum.ProximityPromptStyle.Custom,
		tostring(sadel.Style))
	check("exakt en prompt är släckt, inte fler", N._slackta() == 1,
		("%d"):format(N._slackta()))

	--[[ AKTIVERINGEN ÖVERLEVER. Det är hela skillnaden mot att stänga av
	     prompten: `Enabled` är orörd, och trycket går fram som förut. ]]
	check("prompten är fortfarande PÅ — bara dess bild är borta",
		sadel.Enabled == true)
	local fyrade = 0
	sadel.Triggered:Connect(function() fyrade += 1 end)
	N._tryckPa(1)
	task.wait()
	check("och den går fortfarande att aktivera genom sin egen väg",
		fyrade == 1, tostring(fyrade))

	--[[ TÄNDS IGEN när raden försvinner. En prompt som blev osynlig och
	     stannade så vore ett sämre fel än det vi rättar: spelaren som går
	     därifrån skulle möta en handling utan knapp. ]]
	N.satRider(true)
	check("under ritten är listan släckt och bilden tillbaka",
		#N._rader() == 0 and sadel.Style == Enum.ProximityPromptStyle.Default
			and N._slackta() == 0,
		("rader %d · stil %s · släckta %d"):format(#N._rader(),
			tostring(sadel.Style), N._slackta()))
	N.satRider(false)
	check("och släcks igen när listan kommer tillbaka",
		sadel.Style == Enum.ProximityPromptStyle.Custom, tostring(sadel.Style))

	--[[ …och `stopp` får inte lämna en släckt prompt efter sig. ]]
	N.stopp()
	check("stopp lämnar ingen släckt prompt kvar",
		sadel.Style == Enum.ProximityPromptStyle.Default and N._slackta() == 0,
		("stil %s · släckta %d"):format(tostring(sadel.Style), N._slackta()))

	--[[ SKRIVBORDET RÖRS INTE: utan pekskärm startar modulen aldrig, så
	     ingen prompt kan bli släckt där. ]]
	UIS.TouchEnabled = false
	N.start()
	check("utan pekskärm släcks ingen prompt alls", N._slackta() == 0,
		("%d"):format(N._slackta()))
	UIS.TouchEnabled = true
	N.stopp()
	if sadel.Parent then sadel.Parent:Destroy() end
end

--[[ ══ #246 D: PRIORITERINGEN ÄR SEMANTISK ═══════════════════════════

	Fysisk Studio-QA 2026-09-18: "Andra hästars utrustning (Marabou/
	MacKenzie) och flera dörrar konkurrerar med dagens häst", och
	"närområdeslistan" fylldes av dem.

	Avståndet ensamt räcker inte som ordning — boxfronterna står tätt, och
	grannens sadel kan mycket väl vara NÄRMARE än den egna. Provet ställer
	därför upp precis den fällan: grannens sadel närmast, den egna längst
	bort, en dörr däremellan. ]]
print("\n── Dagens häst går först, grannens utrustning bort ──")
do
	--[[ Ett förråd som tjänsten bygger det: modellen bär `ForHast`. ]]
	local function forrad(hastId, namn, handling, objekt, lage)
		local m = Instance.new("Model")
		m.Name = "Forrad_" .. hastId
		m:SetAttribute("ForHast", hastId)
		m.Parent = workspace
		local del = Instance.new("Part")
		del.Name = namn
		del.Position = lage
		del.Parent = m
		local pr = Instance.new("ProximityPrompt")
		pr.Name = namn .. "Prompt"
		pr.ActionText = handling
		pr.ObjectText = objekt or ""
		pr.MaxActivationDistance = 8
		pr.RequiresLineOfSight = false
		pr.Parent = del
		return pr
	end

	--[[ Grannens sadel ligger NÄRMAST — det är hela fällan. ]]
	local grannen = forrad("marabou", "MarabouSadel", "Ta sadeln", "Marabous sadel",
		Vector3.new(1.0, 0, 0))
	local granne2 = forrad("mackenzie", "MacKenzieSadel", "Ta sadeln",
		"MacKenzies sadel", Vector3.new(1.5, 0, 0))
	local dorr = nyPrompt("BoxdorrD", "Öppna", "MB 7", Vector3.new(3, 0, 0))
	local egen = forrad("trixie", "TrixieSadel", "Ta sadeln", "Trixies sadel",
		Vector3.new(6.5, 0, 0))

	check("hästuppslaget hittar förrådets ForHast",
		N.hastFor(egen) == "trixie" and N.hastFor(grannen) == "marabou",
		("%s / %s"):format(tostring(N.hastFor(egen)), tostring(N.hastFor(grannen))))
	check("och en dörr hör inte till någon häst", N.hastFor(dorr) == nil,
		tostring(N.hastFor(dorr)))

	--[[ UTAN tilldelad häst vet spelet inte bättre än spelaren: allt står
	     kvar, och avståndet får bestämma som förut. ]]
	local utan = N.nara(HAR, { workspace }, nil, 5)
	local harGranne = false
	for _, pr in ipairs(utan) do
		if N.hastFor(pr) == "marabou" then harGranne = true end
	end
	check("utan tilldelad häst filtreras ingenting bort", harGranne == true)

	--[[ MED tilldelad häst: hennes steg först, grannarnas borta. ]]
	local med = N.nara(HAR, { workspace }, "trixie", 5)
	check("dagens hästs handling står FÖRST, trots att den ligger längst bort",
		med[1] == egen, tostring(med[1] and med[1].ObjectText))
	local grannarKvar = 0
	for _, pr in ipairs(med) do
		local h = N.hastFor(pr)
		if h ~= nil and h ~= "trixie" then grannarKvar += 1 end
	end
	check("och ingen annan hästs utrustning finns kvar i listan",
		grannarKvar == 0, ("%d kvar"):format(grannarKvar))

	--[[ Dörren trängs INTE bort — den hamnar efter hästens steg. Ordern är
	     uttrycklig: nödvändiga dörrhandlingar får visas när de är
	     relevanta, men inte tränga undan nästa obligatoriska steg. ]]
	local harDorr = false
	for _, pr in ipairs(med) do if pr == dorr then harDorr = true end end
	check("dörren är kvar, men efter hästens steg",
		harDorr == true and med[1] ~= dorr)

	--[[ TAKET respekteras och räknas EFTER sorteringen. ]]
	local smalt = N.nara(HAR, { workspace }, "trixie", 1)
	check("med bara en radplats är den raden dagens hästs",
		#smalt == 1 and smalt[1] == egen,
		("%d rader"):format(#smalt))

	for _, pr in ipairs({ grannen, granne2, egen }) do
		if pr.Parent and pr.Parent.Parent then pr.Parent.Parent:Destroy() end
	end
	if dorr.Parent then dorr.Parent:Destroy() end
end

--[[ ══ #246 E: ETIKETTEN SÄGER SAKEN EN GÅNG ══════════════════════════
	QA läste rader som `Take the saddle — Trixie saddle`. ]]
print("\n── Etiketten utan dubblering ──")
do
	check("det QA såg blir kort och entydigt",
		N.kortEtikett("Take the saddle", "Trixie saddle") == "Take the saddle — Trixie",
		("%q"):format(N.kortEtikett("Take the saddle", "Trixie saddle")))
	check("och på svenska",
		N.kortEtikett("Ta sadeln", "Trixies sadeln") == "Ta sadeln — Trixies",
		("%q"):format(N.kortEtikett("Ta sadeln", "Trixies sadeln")))
	--[[ Säger objektet inget nytt utelämnas hela ledet. ]]
	check("ett objekt som bara upprepar handlingen faller bort",
		N.kortEtikett("Öppna", "Öppna") == "Öppna",
		("%q"):format(N.kortEtikett("Öppna", "Öppna")))
	--[[ …men det som SKILJER två rader åt får aldrig falla bort. ]]
	check("och det som skiljer två dörrar åt står kvar",
		N.kortEtikett("Öppna", "MB 7") == "Öppna — MB 7",
		("%q"):format(N.kortEtikett("Öppna", "MB 7")))
	check("tomt objekt ger bara handlingen",
		N.kortEtikett("Sitt upp", "") == "Sitt upp"
			and N.kortEtikett("Sitt upp", nil) == "Sitt upp")
end

--[[ ══ #246 E: LISTAN OCH SKÖTSELPANELEN DELAR HÖRN ══════════════════

	QA 2026-09-18: "Närområdeslistan överlappar skötselns instruktion/
	feedback nere till vänster."

	Båda är ankrade nere till vänster. Panelen växer uppåt med sitt
	innehåll; listan växer uppåt med antalet rader. Ordern räknar upp fem
	viewports som ska provas, och kravet är att de ALDRIG överlappar —
	samtidigt som nödvändiga handlingar förblir åtkomliga.

	Provet matar in panelens ruta och mäter listans svar. Reglerna som
	läser rutan är oförändrade; det är dem mätningen gäller. ]]
print("\n── Fem viewports: listan viker för skötselpanelen ──")
do
	local Players = game:GetService("Players")
	local UIS = game:GetService("UserInputService")
	UIS.TouchEnabled = true
	N.stopp()
	N.start()
	local yta = Players.LocalPlayer._gui and (function()
		local function sok(nod)
			if type(nod) ~= "table" then return nil end
			if nod.Name == "UBRFNaromrade" then return nod end
			for _, b in ipairs(nod._barn or {}) do
				local t = sok(b)
				if t then return t end
			end
			return nil
		end
		return sok(Players.LocalPlayer._gui)
	end)() or nil
	check("närområdets yta är byggd", yta ~= nil)

	--[[ Kanonens provskärmar, med panelen på 150 px — en instruktionsrad
	     plus ett par val, alltså en vardaglig höjd och inte ett värsta
	     fall. Y-värdet är panelens ÖVERKANT. ]]
	local PANEL = 150
	local ytor = {
		{ namn = "liten telefon 568x320", b = 568, h = 320 },
		{ namn = "iPhone 13 landskap 844x390", b = 844, h = 390 },
		{ namn = "iPad porträtt 810x1080", b = 810, h = 1080 },
		{ namn = "iPad landskap 1080x810", b = 1080, h = 810 },
		{ namn = "iPad landskap 1180x820", b = 1180, h = 820 },
	}
	local allaFria, allaMinstEn, rader_ = true, true, {}
	for _, v in ipairs(ytor) do
		yta.AbsoluteSize = Vector3.new(v.b, v.h, 0)
		PreparationController._satRutaForProv({
			x0 = 16, y0 = v.h - PANEL, x1 = 16 + 316, y1 = v.h })
		local n = N.radplatser()
		--[[ Listans överkant = golvet minus radernas höjd. Golvet är
		     panelens överkant; ryms raderna ovanför den syns ingenting av
		     den ena i den andra. ]]
		local listHojd = n * (52 + 8)
		local listUnderkant = v.h - 16
		local panelOverkant = v.h - PANEL
		if listUnderkant > panelOverkant then
			--[[ Listan är ankrad i nederkanten som förut; det som avgör är
			     att RADERNA får plats ovanför panelen. ]]
			if (listUnderkant - listHojd) < 0 then allaFria = false end
		end
		if n < 1 then allaMinstEn = false end
		if n * (52 + 8) + 16 + 8 > v.h then allaFria = false end
		table.insert(rader_, ("%s -> %d rader"):format(v.namn, n))
	end
	check("listan håller sig innanför skärmen på alla fem ytorna", allaFria,
		table.concat(rader_, " · "))
	check("och det finns alltid minst en rad att handla på", allaMinstEn)

	--[[ GOLVET PRÖVAS DÄR DET FAKTISKT BINDER.

	     Raden ovan var tom som bevis: på de fem ytorna blir svaret aldrig
	     under två, så en mutation som tog bort golvet kom ut GRÖN
	     (falsifiering M7). Ett prov som inte kan bli rött är ingen grind.

	     Här äter panelen hela höjden — ett verkligt fall på en liten
	     telefon i landskap med en utvidgad skötselpanel. Då ska listan
	     hellre dela plats med panelen än försvinna: nödvändiga handlingar
	     ska förbli åtkomliga, och prioriteringen i `nara` gör att den enda
	     raden är rätt rad. ]]
	yta.AbsoluteSize = Vector3.new(568, 320, 0)
	PreparationController._satRutaForProv({ x0 = 16, y0 = 4, x1 = 332, y1 = 320 })
	local trangt = N.radplatser()
	check("en panel som äter hela höjden lämnar ändå EN rad",
		trangt == 1, ("%d rader"):format(trangt))

	--[[ EN HÖG PANEL ÄTER RADER — det är hela poängen. Utan panel ska
	     taket vara det gamla. ]]
	yta.AbsoluteSize = Vector3.new(1080, 810, 0)
	PreparationController._satRutaForProv(nil)
	local utan = N.radplatser()
	PreparationController._satRutaForProv({ x0 = 16, y0 = 200, x1 = 332, y1 = 810 })
	local med = N.radplatser()
	check("en hög skötselpanel minskar antalet rader", med < utan,
		("utan panel %d · med panel %d"):format(utan, med))
	check("och utan panel är taket kanonens fem", utan == 5, ("%d"):format(utan))

	PreparationController._satRutaForProv(nil)
	N.stopp()
	UIS.TouchEnabled = false
end

--[[ ══ #246 C, OMTAG: OVERFLOW OCH BORTFILTRERADE ════════════════════

	Senior review av `c3f48c7` (CHANGES_REQUESTED): första utkastet släckte
	bara promptbilderna för de handlingar som fick en RAD. I QA-scenariot
	rymmer telefonen två rader medan fem eller fler prompter ligger inom
	räckvidd — de som inte fick plats, och grannhästens utrustning som
	filtreras bort, behöll Roblox egna flytande knappar. Ytan var alltså
	fortfarande dubbel.

	Provet ställer upp exakt den bilden och mäter reviewens sex krav. ]]
print("\n── Sex prompter, två radplatser: ingen dubbel yta ──")
do
	for _, d in ipairs(workspace:GetChildren()) do d:Destroy() end
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

	local function forrad(hastId, namn, handling, objekt, lage)
		local m = Instance.new("Model")
		m.Name = "Forrad_" .. namn
		m:SetAttribute("ForHast", hastId)
		m.Parent = workspace
		local del = Instance.new("Part")
		del.Name = namn
		del.Position = lage
		del.Parent = m
		local pr = Instance.new("ProximityPrompt")
		pr.Name = namn .. "Prompt"
		pr.ActionText = handling
		pr.ObjectText = objekt
		pr.MaxActivationDistance = 8
		pr.RequiresLineOfSight = false
		pr.Parent = del
		return pr
	end

	--[[ Grannarnas utrustning NÄRMAST — de ska filtreras bort ur listan
	     men ändå få sina bilder släckta. ]]
	local granne1 = forrad("marabou", "MarabouSadel", "Ta sadeln",
		"Marabous sadel", Vector3.new(1, 0, 0))
	local granne2 = forrad("mackenzie", "MacKenzieSadel", "Ta sadeln",
		"MacKenzies sadel", Vector3.new(1.5, 0, 0))
	--[[ Dagens häst: två handlingar, som ska bli de två raderna. ]]
	local egen1 = forrad("trixie", "TrixieSadel", "Ta sadeln", "Trixies sadel",
		Vector3.new(4, 0, 0))
	local egen2 = forrad("trixie", "TrixieTrans", "Ta tränset", "Trixies träns",
		Vector3.new(4.5, 0, 0))
	--[[ Två dörrar, som blir overflow när bara två platser finns. ]]
	local dorr1 = nyPrompt("DorrA", "Öppna", "MB 7", Vector3.new(2, 0, 0))
	local dorr2 = nyPrompt("DorrB", "Öppna", "E 7", Vector3.new(2.2, 0, 0))
	local allaSex = { granne1, granne2, egen1, egen2, dorr1, dorr2 }

	local yta = (function()
		local function sok(nod)
			if type(nod) ~= "table" then return nil end
			if nod.Name == "UBRFNaromrade" then return nod end
			for _, b in ipairs(nod._barn or {}) do
				local t = sok(b)
				if t then return t end
			end
			return nil
		end
		return sok(Players.LocalPlayer._gui)
	end)()
	--[[ Radkapacitet 2: liten telefon i landskap med en skötselpanel uppe. ]]
	yta.AbsoluteSize = Vector3.new(844, 390, 0)
	PreparationController._satRutaForProv({ x0 = 16, y0 = 190, x1 = 332, y1 = 390 })
	PreparationController._satHastIdForProv("trixie")
	check("radkapaciteten är 2 på den här ytan", N.radplatser() == 2,
		("%d"):format(N.radplatser()))

	N.satRider(false)

	local inom = N.iRackvidd(Vector3.new(0, 0, 0), { workspace })
	check("sex prompter ligger inom aktiveringsavstånd", #inom == 6,
		("%d"):format(#inom))

	local synliga = N._rader()
	check("exakt två listknappar syns", #synliga == 2,
		("%d: %s"):format(#synliga, table.concat(synliga, " | ")))
	local badeEgna = (synliga[1] or ""):find("Trixie") ~= nil
		and (synliga[2] or ""):find("Trixie") ~= nil
	check("och båda raderna är dagens hästs prioriterade handlingar",
		badeEgna, table.concat(synliga, " | "))

	--[[ INGEN av de sex behåller Robloxs egna UI — varken overflow
	     (dörrarna) eller de bortfiltrerade (grannarnas). ]]
	local kvarNative = {}
	for _, pr in ipairs(allaSex) do
		if pr.Style ~= Enum.ProximityPromptStyle.Custom then
			table.insert(kvarNative, pr.Name)
		end
	end
	check("ingen prompt inom räckvidd behåller Roblox standard-UI",
		#kvarNative == 0, table.concat(kvarNative, ", "))
	check("och alla sex står i registret, inte bara de två raderna",
		N._slackta() == 6, ("%d"):format(N._slackta()))

	--[[ AKTIVERINGEN är orörd på en bortfiltrerad prompt: ingen rad, men
	     promptens egen väg fungerar precis som förut. ]]
	check("en bortfiltrerad prompt är fortfarande aktiverbar",
		granne1.Enabled == true and granne1.MaxActivationDistance == 8)
	local grannFyrade = 0
	granne1.Triggered:Connect(function() grannFyrade += 1 end)
	granne1:InputHoldBegin()
	granne1:InputHoldEnd()
	task.wait()
	check("och dess egen väg utlöser precis som förut", grannFyrade == 1,
		tostring(grannFyrade))

	--[[ Spelaren går därifrån: alla stilar tillbaka. ]]
	rot.Position = Vector3.new(500, 0, 500)
	N.satRider(false)
	local ateAlla = true
	for _, pr in ipairs(allaSex) do
		if pr.Style ~= Enum.ProximityPromptStyle.Default then ateAlla = false end
	end
	check("när spelaren lämnat området är varje stil återställd",
		ateAlla and N._slackta() == 0,
		("släckta kvar: %d"):format(N._slackta()))

	rot.Position = Vector3.new(0, 0, 0)
	N.satRider(false)
	check("de släcks igen när hon kommer tillbaka", N._slackta() == 6,
		("%d"):format(N._slackta()))
	N.stopp()
	local efterStopp = true
	for _, pr in ipairs(allaSex) do
		if pr.Style ~= Enum.ProximityPromptStyle.Default then efterStopp = false end
	end
	check("och stopp lämnar ingen släckt prompt kvar",
		efterStopp and N._slackta() == 0, ("%d"):format(N._slackta()))

	--[[ PC-vägen är orörd: utan pekskärm släcks ingenting. ]]
	UIS.TouchEnabled = false
	N.start()
	local pcOrord = true
	for _, pr in ipairs(allaSex) do
		if pr.Style ~= Enum.ProximityPromptStyle.Default then pcOrord = false end
	end
	check("PC-vägen är orörd — ingen prompt släckt, ingen lista byggd",
		pcOrord and N._slackta() == 0 and #N._rader() == 0)
	N.stopp()

	PreparationController._satRutaForProv(nil)
	PreparationController._satHastIdForProv(nil)
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
