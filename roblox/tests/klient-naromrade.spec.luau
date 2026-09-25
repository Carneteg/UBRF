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

--[[ ── EN BILDRUTA EFTER VARJE OMRITNING (#264 ROBLOX_HUMAN_PLAYTEST_FIX) ──

	`Naromrade` byter numera stil på en prompt genom att stänga den, byta,
	och öppna den igen NÄSTA Heartbeat — mätt i Studio: ett byte inom samma
	bildruta river inte motorns redan ritade bubbla. I motorn kommer den
	bildrutan alltid innan en människa hinner trycka på raden.

	Bänken har ingen egen klocka, så den bildrutan modelleras här, på ETT
	ställe: `satRider` är provets deterministiska omritning, och efter den
	fyrar bänken en Heartbeat. Inga påståenden nedan är ändrade — de gäller
	läget efter bildrutan, som i spelet. ]]
do
	local ritaOm = N.satRider
	local HB = game:GetService("RunService").Heartbeat
	N.satRider = function(v)
		ritaOm(v)
		HB:Fire(1 / 60)
	end
end

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

	--[[ MEDAN MAN RIDER bär listan ridningens kärna, inte stallets
	     handlingar (#264 ROBLOX_HUMAN_PLAYTEST_FIX). Förut var den släckt
	     — och speltestet 2026-09-25 visade att ingenting då sa hur man
	     driver, bromsar eller sitter av. Raderna är text: ingen av dem
	     pekar på en prompt. ]]
	N.satRider(true)
	local ridhjalp = KontrollHjalp.ridrader()
	check("medan man rider visar listan ridningens kärna",
		#N._rader() == #ridhjalp and #ridhjalp > 0,
		("%d rader, %d kärnrader"):format(#N._rader(), #ridhjalp))
	check("och ingen rad pekar på en stallprompt", #N._prompter() == 0,
		("%d prompter"):format(#N._prompter()))
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
	check("under ritten pekar ingen rad på en prompt och bilden är tillbaka",
		#N._prompter() == 0 and sadel.Style == Enum.ProximityPromptStyle.Default
			and N._slackta() == 0,
		("prompter %d · stil %s · släckta %d"):format(#N._prompter(),
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

	--[[ ── ROBLOXS VÄNSTRA RÖRELSEKONTROLL ────────────────────────────

		Uppmätt i Studios emulator 2026-09-24, regular 1179×819: hela
		närområdesknappen (16,445..206,497) låg inuti
		`DynamicThumbstickUIModifier`, en `ImageButton` på 572×607 vid
		(−100, 254) med `InputSink.Activate`. Två sväljande ytor på samma
		pixlar.

		Provet bygger kontrollen som en `GuiButton` i en `TouchGui` under
		`PlayerGui` — samma form som motorn, utan att låna dess namn.
		Rättelsen letar efter KLASSEN, inte namnet, så provet gör det med. ]]
	do
		local function v2(x, y) return { X = x, Y = y } end
		local function knapp(namn, x, y, b, h)
			return { Name = namn, Visible = true, _barn = {},
				AbsolutePosition = v2(x, y), AbsoluteSize = v2(b, h),
				IsA = function(_, k) return k == "GuiButton" end,
				GetDescendants = function() return {} end }
		end
		local pg = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
		--[[ Måtten är mätningens, skalade till samma yta som provet kör. ]]
		local GUI_B, GUI_H = 1179, 761
		local spak = knapp("RorelseYta", 0, 254, 472, 507)
		local hopp = knapp("HoppYta", 1009, 551, 120, 120)
		local tg = { Name = "TouchGui", _barn = { spak, hopp },
			GetDescendants = function(self) return self._barn end,
			FindFirstChild = function(self, sokt)
				for _, b in ipairs(self._barn) do
					if b.Name == sokt then return b end
				end
				return nil
			end }

		yta.AbsoluteSize = Vector3.new(GUI_B, GUI_H, 0)
		PreparationController._satRutaForProv(nil)

		--[[ KONTROLLEN FÖRST: utan kontrollträd ska ingenting ha ändrats,
		     annars kan tystnaden nedan betyda «listan flyttade alltid». ]]
		local x0, golv0 = N.blockvanster(), N.blockgolv()
		check("KONTROLL: utan rörelsekontroll står blocket kvar nere till vänster",
			x0 == 16 and golv0 == GUI_H,
			("x=%d golv=%d"):format(x0, golv0))
		local fore = N.radplatser()

		table.insert(pg._barn, tg)
		local ytaX1, ytaY0 = N.rorelseytan()
		check("rörelseytan läses ur kontrollträdet, inte ur ett namn",
			ytaX1 == 472 and ytaY0 == 254,
			("x1=%s y0=%s"):format(tostring(ytaX1), tostring(ytaY0)))

		--[[ HOPPKNAPPEN ÄR HÖGER OCH SKA INTE RÄKNAS IN. Räknades den med
		     blev reservatet hela skärmens bredd och listan hemlös. ]]
		check("och hoppknappen till höger räknas inte in", ytaX1 < GUI_B * 0.5,
			("x1=%d av %d"):format(ytaX1, GUI_B))

		local efter = N.radplatser()
		local x1b, golv1 = N.blockvanster(), N.blockgolv()
		local listTopp = golv1 - 16 - efter * (52 + 8)
		local listBotten = golv1 - 16
		check("BLOCKET LIGGER OVANFÖR RÖRELSEYTAN", listBotten <= ytaY0,
			("underkant %d, ytans överkant %d"):format(listBotten, ytaY0))
		check("och ingen rad hamnar utanför skärmen", listTopp >= 0,
			("överkant %d"):format(listTopp))
		check("och det finns fortfarande minst en rad", efter >= 1,
			("%d rader (fore %d)"):format(efter, fore))
		check("blocket står kvar i vänsterkanten när det ryms ovanför",
			x1b == 16, ("x=%d"):format(x1b))

		--[[ NÄR DET INTE RYMS UPPÅT ska blocket väja i sidled i stället
		     för att försvinna. Kontrollen får här nästan hela höjden. ]]
		local hog = knapp("HogRorelseYta", 0, 40, 472, 721)
		tg._barn = { hog, hopp }
		local trangX, trangGolv = N.blockvanster(), N.blockgolv()
		check("TRÅNGT UPPÅT: blocket väjer i sidled i stället för att försvinna",
			trangX > 472 and trangGolv == GUI_H,
			("x=%d golv=%d"):format(trangX, trangGolv))
		check("och det ligger till höger om rörelseytan",
			trangX >= 472, ("x=%d mot ytans %d"):format(trangX, 472))

		--[[ ── OKÄND FORM SKA OCKSÅ GE RESERVAT ────────────────────────

			Reviewns P1: `kontrollSedd` blev sann först när en `GuiButton`
			känts igen, så fallbacken för «trädet har ändrats» krävde att
			igenkänningen en gång lyckats. Här finns ett träd med ett
			vänsterelement som INTE är en `GuiButton` — spelaren kan ha
			valt ett annat rörelseläge, eller Roblox bytt klass. ]]
		N._glomKontrollForProv()
		local okand = knapp("OkandForm", 0, 254, 472, 507)
		okand.IsA = function(_, k) return k == "Frame" end
		tg._barn = { okand, hopp }
		local _, okandY0 = N.rorelseytan()
		check("OKÄND FORM GER ÄNDÅ RESERVAT", okandY0 < GUI_H,
			("y0=%s av %d"):format(tostring(okandY0), GUI_H))

		--[[ ── ETT SLÄCKT TRÄD ÄR INGET RESERVAT ──────────────────────

			`ModalEnabled` ger `TouchGui.Enabled = false`, och det gör vi
			själva under ritt. Då finns ingen kontroll att väja för. ]]
		N._glomKontrollForProv()
		tg.Enabled = false
		local _, slacktY0 = N.rorelseytan()
		check("ETT SLÄCKT KONTROLLTRÄD GER INGET RESERVAT",
			slacktY0 >= GUI_H, tostring(slacktY0))
		tg.Enabled = nil
		N._glomKontrollForProv()

		--[[ ── HELA RADEN INNANFÖR VYN ────────────────────────────────

			Reviewns andra P1, med dess egen geometri: användbar bredd 390,
			vänster kontroll x 0..250 från y 40 och nedåt. Sidledsflytten
			gav förut x=258 och en rad som slutade på 448 — 58 px utanför
			skärmen. Här ryms ingen användbar rad alls, och då ska listan
			släckas så att Robloxs egna prompter står kvar. ]]
		yta.AbsoluteSize = Vector3.new(390, 640, 0)
		tg._barn = { knapp("SmalRorelseYta", 0, 40, 250, 600) }
		local smalX, smalGolv = N.blockplats()
		check("SMAL VY: ingen rad ryms, och då ritas ingen",
			smalX == nil and smalGolv == nil and N.radplatser() == 0,
			("x=%s golv=%s platser=%d"):format(tostring(smalX),
				tostring(smalGolv), N.radplatser()))

		--[[ Och där sidledsflytten FAKTISKT ryms ska hela raden vara inne. ]]
		yta.AbsoluteSize = Vector3.new(844, 390, 0)
		tg._barn = { knapp("BredRorelseYta", 0, 40, 250, 350) }
		local bredX = N.blockplats()
		check("SIDLED: hela raden ligger innanför den användbara bredden",
			bredX ~= nil and bredX >= 250 and bredX + 190 <= 844 - 16,
			("x=%s, hogerkant %s av %d"):format(tostring(bredX),
				tostring(bredX and bredX + 190), 844))

		--[[ ── DEN RITADE RAMEN, INTE BARA HJÄLPFUNKTIONERNAS SVAR ─────

			Reviewns poäng: en hjälpfunktion kan svara rätt medan ramen
			ritas någon annanstans. Här läses ramens FAKTISKA position och
			storlek efter en riktig ritning. ]]
		local function listramen()
			for _, b in ipairs(yta._barn or {}) do
				if b.Name == "Lista" then return b end
			end
			return nil
		end
		N.satRider(false)
		local f = listramen()
		check("ramen finns att mäta", f ~= nil)
		if f then
			local px = f.Position and f.Position.X and f.Position.X.Offset or -1
			local py = f.Position and f.Position.Y and f.Position.Y.Offset or -1
			local bx = f.Size and f.Size.X and f.Size.X.Offset or -1
			check("DEN RITADE RAMEN ligger helt innanför vyn",
				px >= 0 and px + bx <= 844,
				("x=%d bredd=%d hogerkant=%d av 844"):format(px, bx, px + bx))
			check("och den ritade ramen börjar till höger om rörelseytan",
				px >= 250, ("x=%d mot ytans 250"):format(px))
			check("och ramen har en höjd som rymmer minst en rad",
				(f.Size and f.Size.Y and f.Size.Y.Offset or 0) >= 60,
				("hojd=%s"):format(tostring(f.Size and f.Size.Y
					and f.Size.Y.Offset)))
		end

		--[[ POSITIV KONTROLL FÖR TANGENTBORD/MUS: utan kontrollträd ska
		     ingenting av det här röra layouten.

		     TRÄDET MÅSTE FAKTISKT BORT. Första versionen tömde bara dess
		     barn och lät `TouchGui` ligga kvar — och då gäller reservatet
		     med rätta, för ett träd utan igenkänd form är precis det fall
		     P1-1 handlar om. Kontrollen mätte alltså fel sak. ]]
		for i = #pg._barn, 1, -1 do
			if pg._barn[i] == tg then table.remove(pg._barn, i) end
		end
		N._glomKontrollForProv()
		yta.AbsoluteSize = Vector3.new(1179, 761, 0)
		local musX, musGolv = N.blockplats()
		check("KONTROLL: utan kontrollträd är layouten den gamla",
			musX == 16 and musGolv == 761,
			("x=%s golv=%s"):format(tostring(musX), tostring(musGolv)))

		--[[ Städa: kontrollträdet bort, OCH latchen nollad. Den är
		     sessionslång med flit, så utan det här läckte reservatet in i
		     nästa provblock och tog kapaciteten där — sex mätningar föll
		     på en städning som inte var en städning. ]]
		for i = #pg._barn, 1, -1 do
			if pg._barn[i] == tg then table.remove(pg._barn, i) end
		end
		N._glomKontrollForProv()
	end

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

	--[[ ── KONTRAKTET HAR SVÄNGT TVÅ GÅNGER. HÄR ÄR BÅDA VÄNDNINGARNA ──

		FÖRST stod här att INGEN av de sex får behålla Roblox egna UI och
		att alla sex ska stå i registret. Det var avsikten i #246 C: en
		enda interaktionsyta på touch.

		SEDAN visade speltestet 2026-09-21 priset. En prompt som släcks
		utan att få en rad är varken rad eller knapp — Tobias såg
		«Open — Door» och kunde inte öppna dörren. Rutten genom stallet
		var stängd. Regeln blev «släck bara det du ersätter», och just
		den regeln står kvar för DÖRRARNA nedan.

		NU, R2 2026-09-24, mätte granskningen vad regeln kostade när den
		tillämpades på allt: `rows=1 unselectedDefaultPrompts=6`. Listan
		PLUS väggen av bubblor. Den dubbla ytan var inte «rätt pris» —
		den var själva röran Tobias rapporterade.

		Skillnaden som saknades är VARFÖR en prompt blev utan rad:

		  · UTAN PLATS — dörrarna här. Handlingen gäller spelaren, listan
		    räckte bara inte till.

		    I R2 behöll de sin bubbla, för listan hade ingen plats att
		    erbjuda dem. Granskningen mätte priset — `rows=5
		    nativeDoorPrompts=5` — och det var samma dubbla yta igen.

		    I R3 BLÄDDRAR listan. Dörren har en väg in på nästa sida, och
		    då får den också släckas. Invarianten från 2026-09-21 är
		    orörd i sak: ingen prompt släcks utan väg in. Det som ändrats
		    är att «väg in» inte längre betyder «syns just nu».

		  · BORTVALD — grannhästarnas utrustning. Den gäller inte
		    spelaren alls, och en bubbla för den är bara brus framför
		    dagens häst. Den släcks, MED AVSIKT och utan rad.

		Fixturens egen not ovanför sa redan det: grannarna «ska filtreras
		bort ur listan men ändå få sina bilder släckta». Koden hade
		tappat andra halvan när släckningen knöts till urvalet i stället
		för till räckvidden.

		Alltså: fyra släckta (två rader + två bortvalda), två kvar med
		sin bild (dörrarna). ]]
	local kvarNative = {}
	for _, pr in ipairs(allaSex) do
		if pr.Style ~= Enum.ProximityPromptStyle.Custom then
			table.insert(kvarNative, pr.Name)
		end
	end
	check("INGEN ANDRA YTA: ingen av de sex behåller en infödd bubbla",
		#kvarNative == 0, ("%d behöll sin bild: %s"):format(#kvarNative,
			table.concat(kvarNative, ", ")))
	--[[ Och dörrarna är inte borttappade — de ligger på sida två. ]]
	local sidaNu, sidorNu = N._sida()
	check("listan bläddrar, för fyra relevanta ryms inte på två rader",
		sidorNu == 2 and sidaNu == 1,
		("sida %d av %d"):format(sidaNu, sidorNu))
	local naddaSex: { [any]: boolean } = {}
	for _ = 1, sidorNu do
		for _, p in ipairs(N._prompter()) do naddaSex[p] = true end
		N._bladdra()
	end
	check("DÖRRARNA NÅS GENOM BLÄDDRINGEN — de är släckta, inte gömda",
		naddaSex[dorr1] == true and naddaSex[dorr2] == true,
		("A=%s B=%s"):format(tostring(naddaSex[dorr1]),
			tostring(naddaSex[dorr2])))
	--[[ GRANNHÄSTARNA är det som INTE ska gå att nå: bortvalda är
	     bortvalda, och bläddringen får inte smuggla in dem igen. ]]
	check("men grannhästarnas utrustning nås inte — bortvald är bortvald",
		naddaSex[granne1] ~= true and naddaSex[granne2] ~= true,
		("1=%s 2=%s"):format(tostring(naddaSex[granne1]),
			tostring(naddaSex[granne2])))
	local grannarSlackta = granne1.Style == Enum.ProximityPromptStyle.Custom
		and granne2.Style == Enum.ProximityPromptStyle.Custom
	check("GRANNHÄSTARNAS utrustning är släckt fast den inte fick någon rad",
		grannarSlackta, ("%s / %s"):format(tostring(granne1.Style),
			tostring(granne2.Style)))
	check("registret rymmer allt relevant OCH de bortvalda — alla sex",
		N._slackta() == 6, ("%d"):format(N._slackta()))

	--[[ AKTIVERINGEN är orörd på en bortfiltrerad prompt. Att den inte
	     syns är ett URVAL, inte ett hinder: rör spelaren dagens häst
	     igen kommer handlingen tillbaka som rad, och koden bakom är hela
	     tiden densamma. Jämför dörren, som aldrig får släckas. ]]
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
	check("släckningen kommer tillbaka när hon gör det", N._slackta() == 6,
		("%d"):format(N._slackta()))
	N.stopp()
	local efterStopp = true
	for _, pr in ipairs(allaSex) do
		if pr.Style ~= Enum.ProximityPromptStyle.Default then efterStopp = false end
	end
	check("och stopp lämnar ingen släckt prompt kvar",
		efterStopp and N._slackta() == 0, ("%d"):format(N._slackta()))

	--[[ ── ÅTERSTÄLLNING ÄR INTE «SÄTT TILL DEFAULT» ──────────────────

		R2 begärde att städningen återställer FÖREGÅENDE tillstånd. Det
		är inte samma sak som `Default`: en prompt kan mycket väl ha
		varit `Custom` innan vi rörde den — ett system med egen rityta
		ska inte få sin bild påtvingad av att spelaren gick förbi.

		`slack` lagrar `p.Style` och `tandIgen` skriver tillbaka just
		den. Provet sätter en av grannarna till `Custom` i förväg och
		mäter att den ligger kvar där. ]]
	granne2.Style = Enum.ProximityPromptStyle.Custom
	dorr1.Style = Enum.ProximityPromptStyle.Custom
	N.start()
	N.satRider(false)
	check("en prompt som redan var Custom ändrar inte mening av att släckas",
		granne2.Style == Enum.ProximityPromptStyle.Custom)

	--[[ TVÅ VÄGAR TILLBAKA, OCH BÅDA MÅSTE MÄTAS: `tandIgen` när hon
	     går ur räckvidd, `tandAllaIgen` när ytan rivs. De har var sin
	     kopia av samma rad, och första skrivningen av det här provet
	     rörde bara den ena — en mutation i `tandIgen` gav noll röda.
	     Ett prov som bara täcker halva rättelsen är halv evidens. ]]
	rot.Position = Vector3.new(500, 0, 500)
	N.satRider(false)
	check("ur räckvidd: `tandIgen` lämnar tillbaka Custom, inte Default",
		granne2.Style == Enum.ProximityPromptStyle.Custom,
		tostring(granne2.Style))
	rot.Position = Vector3.new(0, 0, 0)
	N.satRider(false)
	N.stopp()
	check("och efter städningen är den fortfarande Custom — inte Default",
		granne2.Style == Enum.ProximityPromptStyle.Custom,
		tostring(granne2.Style))
	check("dörren som aldrig släcktes är också orörd",
		dorr1.Style == Enum.ProximityPromptStyle.Custom,
		tostring(dorr1.Style))
	granne2.Style = Enum.ProximityPromptStyle.Default
	dorr1.Style = Enum.ProximityPromptStyle.Default

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

--[[ ══ RIDE FIRST FÅR INTE TRÄNGAS BORT (#246 QA-blockerare) ═════════

	Tobias fysiska Studio-QA 2026-09-18: "RIDA NU fungerar inte."

	Reproducerat i Studio på `8a3c435`, spelaren 4 studs från Trixie, sju
	prompter inom räckvidd:

	    kapacitet 5   bridle · saddle · Lead · Ride now · Open
	    kapacitet 3   bridle · saddle · Lead
	    kapacitet 2   bridle · saddle
	    kapacitet 1   bridle

	Sadeln och tränset hänger NÄRMARE spelaren än hästens egen ridknapp,
	och listan sorterade på avstånd inom klassen. På en telefon ryms två
	eller tre rader — "Rida nu" fanns alltså inte i listan. Och eftersom
	touch-ytan äger promptbilderna sedan #246 C var den varken rad eller
	knapp: Ride First-vägen gick inte att trycka på alls.

	Det är en regression min egen ändring kunde orsaka. Före #246 C hade
	nativebilden ritats kvar och spelaren kunnat trycka på den i världen.

	Provet ställer upp exakt den geometrin: omsorgshandlingarna närmast,
	ridvägen längst bort. ]]
print("\n── Rida nu trängs aldrig bort ──")
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

	--[[ Hästen med sina tre handlingar, alla på riggens rot. ]]
	local hast = Instance.new("Model")
	hast.Name = "Trixie"
	hast:SetAttribute("HorseId", "trixie")
	hast.Parent = workspace
	local riggrot = Instance.new("Part")
	riggrot.Name = "HumanoidRootPart"
	riggrot.Position = Vector3.new(6, 0, 0)          -- LÄNGST BORT
	riggrot.Parent = hast
	local function pa(mor, namn, text)
		local pr = Instance.new("ProximityPrompt")
		pr.Name = namn
		pr.ActionText = text
		pr.ObjectText = "Trixie"
		pr.MaxActivationDistance = 12
		pr.RequiresLineOfSight = false
		pr.Parent = mor
		return pr
	end
	local rida = pa(riggrot, "RidaNuPrompt", "Rida nu")
	local led = pa(riggrot, "LedPrompt", "Led Trixie")

	--[[ Boxfrontens utrustning — NÄRMAST spelaren, precis som i stallet. ]]
	local front = Instance.new("Model")
	front.Name = "Forrad"
	front:SetAttribute("ForHast", "trixie")
	front.Parent = workspace
	local sadeldel = Instance.new("Part")
	sadeldel.Name = "Sadel"
	sadeldel.Position = Vector3.new(1, 0, 0)
	sadeldel.Parent = front
	local transdel = Instance.new("Part")
	transdel.Name = "Trans"
	transdel.Position = Vector3.new(1.5, 0, 0)
	transdel.Parent = front
	pa(sadeldel, "SadelPrompt", "Ta sadeln")
	pa(transdel, "TransPrompt", "Ta tränset")

	PreparationController._satHastIdForProv("trixie")

	--[[ Först: geometrin ÄR den som fällde produkten — ridvägen ligger
	     längst bort av dagens hästs handlingar. ]]
	local inom = N.iRackvidd(Vector3.new(0, 0, 0), { workspace })
	check("alla fyra handlingarna ligger inom räckvidd", #inom == 4,
		("%d"):format(#inom))
	local narmast = inom[1]
	check("och omsorgshandlingen ligger NÄRMAST, som i stallet",
		narmast ~= nil and narmast.Name == "SadelPrompt",
		tostring(narmast and narmast.Name))

	--[[ KRAVET: Ride First-vägen får aldrig trängas bort, hur få rader som
	     än ryms. Produktbeslutet är uttryckligt — RIDA NU ska ALLTID ge
	     spelaren en fungerande väg till ridning. ]]
	for _, tak in ipairs({ 1, 2, 3, 5 }) do
		local lista = N.nara(Vector3.new(0, 0, 0), { workspace }, "trixie", tak)
		local harRida = false
		local namn = {}
		for _, pr in ipairs(lista) do
			if pr == rida then harRida = true end
			table.insert(namn, pr.ActionText)
		end
		check(("med %d radplats(er) finns Rida nu med"):format(tak), harRida,
			table.concat(namn, " | "))
	end

	--[[ …och den ligger FÖRST, före den frivilliga omsorgen. ]]
	local full = N.nara(Vector3.new(0, 0, 0), { workspace }, "trixie", 5)
	check("Rida nu står först av dagens hästs handlingar", full[1] == rida,
		tostring(full[1] and full[1].ActionText))
	check("och ledningen — den frivilliga omsorgen — kommer efter",
		full[2] == led, tostring(full[2] and full[2].ActionText))

	--[[ Omsorgen försvinner INTE. Den trängs inte före, men den finns. ]]
	local harSadel = false
	for _, pr in ipairs(full) do
		if pr.Name == "SadelPrompt" then harSadel = true end
	end
	check("och sadeln är kvar i listan, bara inte först", harSadel)

	--[[ AVSTÅNDET GÄLLER FORTFARANDE inom samma handlingsrang: sadeln
	     ligger närmare än tränset och ska stå före det. ]]
	local sadelIx, transIx
	for i, pr in ipairs(full) do
		if pr.Name == "SadelPrompt" then sadelIx = i end
		if pr.Name == "TransPrompt" then transIx = i end
	end
	check("inom samma rang avgör avståndet som förut",
		sadelIx ~= nil and transIx ~= nil and sadelIx < transIx,
		("sadel %s · träns %s"):format(tostring(sadelIx), tostring(transIx)))

	--[[ Och nativebilderna är fortsatt släckta för ALLA fyra — det var
	     #246 C:s krav, och det är just det som gör radens närvaro kritisk. ]]
	N.satRider(false)
	local kvarNative = {}
	for _, pr in ipairs(inom) do
		if pr.Style ~= Enum.ProximityPromptStyle.Custom then
			table.insert(kvarNative, pr.Name)
		end
	end
	check("ingen native promptbild är kvar — därför MÅSTE raden finnas",
		#kvarNative == 0, table.concat(kvarNative, ", "))

	N.stopp()
	PreparationController._satHastIdForProv(nil)
	UIS.TouchEnabled = false
end

print("\n── Ytan finns där den behövs, och bara där ──")

--[[ ── DET GAMLA KONTRAKTET VAR «SKRIVBORDET RÖRS INTE» ────────────────

	Här stod «utan pekskärm byggs ingenting», och det var regeln fram till
	Tobias playtest 2026-09-24. Då visade sig regeln vara felet: på PC
	fanns bara Robloxs egna världsbubblor, en vägg av dem framför hästen,
	och ingen väg att se vad som faktiskt gick att göra.

	Assertionen är ÄNDRAD, inte försvagad. Den nya regeln är vidare på ett
	sätt och lika snäv på ett annat: ytan byggs där en lista hör hemma —
	pekskärm, tangentbord eller mus — och inte annars. En spelare med
	enbart handkontroll får den fortfarande inte, för där bär styrkorset
	prompterna. ]]
do
	local UIS = game:GetService("UserInputService")
	local tidigareT, tidigareK, tidigareM =
		UIS.TouchEnabled, UIS.KeyboardEnabled, UIS.MouseEnabled

	--[[ PC: tangentbord och mus, ingen pekskärm. ]]
	UIS.TouchEnabled = false
	UIS.KeyboardEnabled = true
	UIS.MouseEnabled = true
	N.stopp()
	N.start()
	N.satRider(false)
	local rader = N._rader()
	check("PÅ SKRIVBORDET BYGGS YTAN", #rader > 0,
		("%d rader"):format(#rader))
	--[[ OCH RADEN SÄGER VILKEN TANGENT SOM UTLÖSER HANDLINGEN, annars är
	     listan en skylt utan väg vidare. Bänkens prompter sätter ingen
	     `KeyboardKeyCode` — produktionens gör det — så provet sätter en
	     och mäter att den syns, och att den som saknar tangent inte får
	     någon påhittad. ]]
	local pMed = nyPrompt("MedTangent", "Öppna", "Dörren",
		Vector3.new(1, 0, 0))
	pMed.KeyboardKeyCode = Enum.KeyCode.E
	N.satRider(false)
	local medRader = N._rader()
	local hittad, utanPahitt = false, true
	for _, t in ipairs(medRader) do
		if string.find(t, "%[E%]") then hittad = true end
		if string.find(t, "Led") and string.find(t, "%[") then utanPahitt = false end
	end
	check("och raden namnger sin tangent", hittad,
		table.concat(medRader, " | "))
	check("medan en prompt utan tangent inte får någon påhittad",
		utanPahitt, table.concat(medRader, " | "))

	--[[ HANDKONTROLL ENSAM: ingen lista, som förut. ]]
	UIS.TouchEnabled = false
	UIS.KeyboardEnabled = false
	UIS.MouseEnabled = false
	N.stopp()
	N.start()
	N.satRider(false)
	check("men med enbart handkontroll byggs ingenting",
		#N._rader() == 0, ("%d rader"):format(#N._rader()))

	UIS.TouchEnabled, UIS.KeyboardEnabled, UIS.MouseEnabled =
		tidigareT, tidigareK, tidigareM
	N.stopp()
end

--[[ ══ EN AFFORDANS FÅR BARA TAS BORT AV EN SOM ERSÄTTER DEN ══════════

	SPELTEST 2026-09-21 (#264): Tobias såg «Open — Door» och kunde inte
	öppna dörren. Rutten genom stallet var stängd.

	`rita()` släckte allt inom RÄCKVIDD men ritade rader bara för
	URVALET. En prompt under radtaket blev varken rad eller knapp —
	Roblox bild borttagen, ingen egen satt dit. Modulen beskrev själv
	felklassen redan vid `nara` («varken rad eller knapp»), men den
	gången rättades bara ordningen för «Rida nu». Orsaken låg kvar.

	Taket är fem rader, och på en telefon ofta två eller tre. En
	stallgång rymmer lätt fler prompter än så.

	INVARIANTEN HAR FÅTT SIN RIKTIGA FORM (R3 P2). Den löd «släckta ska
	aldrig bli fler än raderna», och det var en PROXY för det som
	egentligen gällde: ingen prompt får släckas utan en väg in. Proxyn
	höll så länge den enda vägen in var en synlig rad.

	Granskningen mätte vad proxyn kostade: `rows=5 nativeDoorPrompts=5`
	med tio dörrar — listan plus väggen av bubblor, bara flyttad ett steg
	upp. Listan bläddrar nu, så vägen in kan ligga på sida två.

	Provet mäter därför NÅBARHETEN direkt: varje släckt prompt ska gå att
	komma åt genom att bläddra. Det är ett strängare krav än det gamla,
	inte ett svagare — proxyn kunde vara grön med en oåtkomlig prompt så
	länge antalet stämde. ]]
do
	local UIS = game:GetService("UserInputService")
	UIS.TouchEnabled = true
	N.stopp()
	N.start()
	N.satRider(false)

	--[[ Fler prompter än det finns rader, alla inom räckvidd. ]]
	--[[ `nyPrompt` lämnar TVÅ värden (prompt, del). Skrivet utan
		parenteser gick båda in i `table.insert`, som då läste delen som
		ett index — provet kraschade i stället för att mäta. ]]
	local flock = {}
	for i = 1, 9 do
		local p = nyPrompt("Sak" .. i, "Öppna", "Dörr " .. i,
			Vector3.new(i * 0.3, 0, 0))
		table.insert(flock, p)
	end
	N.satRider(false)

	local rader = #N._rader()
	local slackta = N._slackta()
	check("fler prompter än rader ryms — det är premissen",
		#flock > rader, ("%d prompter, %d rader"):format(#flock, rader))

	--[[ ── NÅBARHETEN, MÄTT GENOM ATT FAKTISKT BLÄDDRA ──────────────

	     Vi går varvet runt i listan och samlar varje prompt som får en
	     rad på vägen. Sedan jämförs den mängden med de släckta. Ingen
	     bokföring, ingen intern tabell — samma väg en spelare har. ]]
	local _, sidor = N._sida()
	check("listan bläddrar — annars kan de nio inte nås",
		sidor > 1, ("%d sidor"):format(sidor))
	local nadda: { [any]: boolean } = {}
	for _ = 1, sidor do
		for _, p in ipairs(N._prompter()) do nadda[p] = true end
		N._bladdra()
	end
	local startSida = N._sida()
	check("och bläddringen går runt tillbaka till första sidan",
		startSida == 1, ("%d"):format(startSida))

	local utanVagIn = {}
	for _, p in ipairs(flock) do
		if p.Style == Enum.ProximityPromptStyle.Custom and not nadda[p] then
			table.insert(utanVagIn, p.Name)
		end
	end
	check("INGEN PROMPT SLÄCKS UTAN EN VÄG IN", #utanVagIn == 0,
		table.concat(utanVagIn, " | "))
	check("och alla nio nås — inte bara de som råkade rymmas",
		(function()
			for _, p in ipairs(flock) do
				if not nadda[p] then return false end
			end
			return true
		end)(), ("%d släckta"):format(slackta))
	--[[ DEN ANDRA HALVAN AV ORDERN: ingen infödd bubbla kvar. ]]
	local kvarNativeFlock = 0
	for _, p in ipairs(flock) do
		if p.Style ~= Enum.ProximityPromptStyle.Custom then
			kvarNativeFlock += 1
		end
	end
	check("OCH INGEN ANDRA YTA: noll infödda bubblor kvar",
		kvarNativeFlock == 0, ("%d kvar"):format(kvarNativeFlock))

	--[[ ── SIDAN MÅSTE KLAMPAS NÄR LISTAN KRYMPER ──────────────────

	     Hon bläddrar till sista sidan och går sedan därifrån, eller
	     handlingarna försvinner. Utan klampning blir hon kvar på en sida
	     som inte finns längre — en tom lista mitt i stallet, utan att
	     något är fel med världen.

	     Falsifieringen hittade det här hålet i PROVET, inte i koden:
	     klampningen fanns men ingen mätning rörde den. ]]
	N.satRider(false)
	--[[ BUNDEN LOOP MED FLIT. Skrivet som ett oandligt `while` hangde
	     provet i stallet for att bli rott nar bladdringen stod
	     stilla — och en timeout ar inget bevis for nagonting. Nu
	     ar taket antalet sidor, och att vi faktiskt kom fram ar en
	     egen matning. ]]
	for _ = 1, select(2, N._sida()) do
		if N._sida() >= select(2, N._sida()) then break end
		N._bladdra()
	end
	local sistaSidan, antalSidor = N._sida()
	check("hon står på sista sidan", sistaSidan == antalSidor and antalSidor > 1,
		("%d av %d"):format(sistaSidan, antalSidor))
	--[[ Sex av de nio försvinner. ]]
	for i = 4, 9 do
		if flock[i].Parent then flock[i].Parent:Destroy() end
	end
	N.satRider(false)
	local nuSida, nuSidor = N._sida()
	check("SIDAN KLAMPAS — hon hamnar inte på en sida som inte finns",
		nuSida <= nuSidor, ("%d av %d"):format(nuSida, nuSidor))
	check("och listan visar faktiskt något",
		#N._rader() > 0, ("%d rader"):format(#N._rader()))

	for _, p in ipairs(flock) do
		if p.Parent then p.Parent:Destroy() end
	end
	N.stopp()
end

--[[ ══ ETT AVBRUTET HÅLL ÄR INGEN HANDLING (#264 R2) ═══════════════

	Raden startade förut sitt håll på `MouseButton1Click` — som fyrar när
	musen SLÄPPS — och avslutade det med en `task.delay` på
	`HoldDuration + 0.05`, oberoende av spelaren. Ett kort klick blev
	alltså en fullbordad håll-handling, och det fanns ingen väg att ångra
	sig. Håll-grindar finns för att vissa saker ska kräva ett medvetet
	ögonblick; den här vägen gav bort ögonblicket gratis.

	Nu är livscykeln verklig: NED börjar, UPP eller att markören lämnar
	knappen avslutar, och motorn avgör om `HoldDuration` hanns med.

	Granskningen bad om tre avbrott: kort släpp, tappat mål eller räckvidd,
	och rivning. Alla tre mäts här, var och en mot en `Triggered`-räknare
	som ska stå kvar på noll, och med en positiv kontroll intill så att
	nollan inte kan komma av att ingenting alls är kopplat.

	BÄNKEN MÄTER DET HÄR PÅ RIKTIGT: stubbens `InputHoldEnd` fyrar bara om
	hållet nått `HoldDuration`, precis som Roblox. Se noten i stubs.luau. ]]
print("\n── Ett avbrutet håll är ingen handling ──")
do
	for _, d in ipairs(workspace:GetChildren()) do d:Destroy() end
	local Players = game:GetService("Players")
	local UIS = game:GetService("UserInputService")
	local kar = Instance.new("Model")
	kar.Name = "Spelare"
	local rot = Instance.new("Part")
	rot.Name = "HumanoidRootPart"
	rot.Position = HAR
	rot.Parent = kar
	kar.Parent = workspace
	Players.LocalPlayer.Character = kar
	UIS.TouchEnabled = true
	N.stopp()
	N.start()

	--[[ HÅLL-prompten: ett halvt sekund medvetet ögonblick. ]]
	local hall, hallDel = nyPrompt("Grinden", "Öppna", "Hagen",
		Vector3.new(2, 0, 0), 8, 0.5)
	local fyrade = 0
	hall.Triggered:Connect(function() fyrade += 1 end)
	--[[ En granne utan hålltid, till kontrollen «ett håll i taget». ]]
	local snabb = nyPrompt("Kranen", "Fyll", "Vattnet", Vector3.new(2.2, 0, 0))
	local snabbtFyrade = 0
	snabb.Triggered:Connect(function() snabbtFyrade += 1 end)

	N.satRider(false)
	local function radFor(p)
		for i, q in ipairs(N._prompter()) do
			if q == p then return i end
		end
		return nil
	end
	local iHall = radFor(hall)
	check("grinden har en rad att hålla på", iHall ~= nil, tostring(iHall))

	--[[ ── 1 · KORT SLÄPP ──────────────────────────────────────────── ]]
	N._hallNed(iHall)
	check("hållet pågår medan fingret ligger kvar", N._hallsNu() == hall)
	N._slappHall()
	check("ETT KORT SLÄPP UTLÖSER INGENTING", fyrade == 0, ("%d"):format(fyrade))
	check("och hållet är släppt", N._hallsNu() == nil)

	--[[ POSITIV KONTROLL: räknaren är inte bara död. Ett håll som får
	     ligga kvar tillräckligt länge SKA utlösa. ]]
	--[[ VÄNTAN MÄTS PÅ SAMMA KLOCKA SOM STUBBEN LÄSER. `task.wait` i
	     bänken flyttar inte `os.clock`, och första skrivningen här
	     gav därför noll utlösningar — en positiv kontroll som var
	     röd av fel skäl, vilket är exakt lika illa som grön av fel
	     skäl. Nu snurrar vi tills riktig tid faktiskt gått. ]]
	N._hallNed(iHall)
	local till = os.clock() + 0.6
	while os.clock() < till do end
	N._slappHall()
	check("men ett håll som fick ligga kvar utlöser", fyrade == 1,
		("%d"):format(fyrade))

	--[[ ── 2 · TAPPAT MÅL OCH RÄCKVIDD ─────────────────────────────── ]]
	fyrade = 0
	N._hallNed(iHall)
	check("hållet pågår igen", N._hallsNu() == hall)
	--[[ Hon rider iväg. Prompten är kvar i världen, men utom räckhåll. ]]
	rot.Position = Vector3.new(500, 0, 500)
	N.satRider(false)
	check("HÅLLET SLÄPPS NÄR MÅLET GÅR UR RÄCKVIDD", N._hallsNu() == nil)
	task.wait(0.6)
	check("och ingen handling utlöses från andra sidan stallet",
		fyrade == 0, ("%d"):format(fyrade))

	--[[ Målet RIVS medan hon håller i det. ]]
	rot.Position = HAR
	N.satRider(false)
	iHall = radFor(hall)
	N._hallNed(iHall)
	check("hållet pågår på den rivna prompten", N._hallsNu() == hall)
	hallDel:Destroy()
	N.satRider(false)
	check("HÅLLET SLÄPPS NÄR MÅLET RIVS UR VÄRLDEN", N._hallsNu() == nil)
	task.wait(0.6)
	check("och ingenting utlöses på något som inte finns",
		fyrade == 0, ("%d"):format(fyrade))

	--[[ ── 3 · RIVNING AV YTAN ──────────────────────────────────────── ]]
	local hall2, del2 = nyPrompt("Grinden2", "Öppna", "Hagen",
		Vector3.new(2, 0, 0), 8, 0.5)
	local fyrade2 = 0
	hall2.Triggered:Connect(function() fyrade2 += 1 end)
	N.satRider(false)
	local i2 = radFor(hall2)
	check("den nya grinden har en rad", i2 ~= nil, tostring(i2))
	N._hallNed(i2)
	check("hållet pågår när ytan rivs", N._hallsNu() == hall2)
	N.stopp()
	check("RIVNINGEN LÄMNAR INGET ÖPPET HÅLL", N._hallsNu() == nil)
	task.wait(0.6)
	check("och rivningen utlöser ingen handling", fyrade2 == 0,
		("%d"):format(fyrade2))

	--[[ ── 4 · ETT HÅLL I TAGET ──────────────────────────────────────

	     Hinner ett nytt håll börja innan det förra släppts ska det förra
	     avslutas först — annars ligger en öppen hållning kvar utan väg
	     tillbaka, och nästa `InputHoldEnd` hade kunnat fyra den. ]]
	N.start()
	N.satRider(false)
	local iG, iK = radFor(hall2), radFor(snabb)
	check("båda har rader", iG ~= nil and iK ~= nil,
		("%s / %s"):format(tostring(iG), tostring(iK)))
	fyrade2, snabbtFyrade = 0, 0
	N._hallNed(iG)
	N._hallNed(iK)
	check("det nya hållet ersatte det gamla", N._hallsNu() == snabb)
	check("och det gamla utlöste inte när det avbröts", fyrade2 == 0,
		("%d"):format(fyrade2))
	N._slappHall()
	check("den hålltidslösa raden utlöser direkt vid släpp",
		snabbtFyrade == 1, ("%d"):format(snabbtFyrade))

	--[[ ── 5 · DEN RIKTIGA KNAPPEN, INTE BARA TEST-HOOKARNA ──────────

	     Allt ovanför går genom `_hallNed`/`_slappHall`. De mäter
	     livscykeln, men INTE att knappen är kopplad till den — och det
	     var precis där felet satt: raden lyssnade på
	     `MouseButton1Click`, som fyrar när musen SLÄPPS, och lät en
	     timer avsluta hållet åt spelaren.

	     Här fyras knappens egna signaler. Då mäts ledningen fram också. ]]
	--[[ SÖKNINGEN MÅSTE BÖRJA I VÅR EGEN YTA. En fri namnsökning genom
	     hela `_gui` hittade ett annat «Rad1» — skötselpanelens — och
	     provet kraschade på en instans utan knappsignaler. Namnet är
	     inte unikt i spelet; ScreenGui:n är det. ]]
	local function underNod(nod, namn)
		if type(nod) ~= "table" then return nil end
		if nod.Name == namn then return nod end
		for _, b in ipairs(nod._barn or {}) do
			local t = underNod(b, namn)
			if t then return t end
		end
		return nil
	end
	local function knappFor(i)
		local min = underNod(game:GetService("Players").LocalPlayer._gui,
			"UBRFNaromrade")
		return min and underNod(min, "Rad" .. i) or nil
	end

	local hall3, del3 = nyPrompt("Grinden3", "Öppna", "Hagen",
		Vector3.new(2, 0, 0), 8, 0.5)
	local fyrade3 = 0
	hall3.Triggered:Connect(function() fyrade3 += 1 end)
	N.start()
	N.satRider(false)
	local i3 = radFor(hall3)
	local knapp = knappFor(i3)
	check("raden finns som en RIKTIG knapp med riktiga signaler",
		i3 ~= nil and knapp ~= nil and knapp.MouseButton1Down ~= nil
			and knapp.MouseLeave ~= nil,
		("i=%s knapp=%s"):format(tostring(i3), tostring(knapp ~= nil)))

	--[[ Kort tryck på den riktiga knappen: ned, upp. ]]
	knapp.MouseButton1Down:Fire()
	check("KNAPPEN BÖRJAR HÅLLET PÅ NED", N._hallsNu() == hall3)
	knapp.MouseButton1Up:Fire()
	check("och ett kort tryck på knappen utlöser ingenting",
		fyrade3 == 0 and N._hallsNu() == nil, ("%d"):format(fyrade3))

	--[[ Långt tryck på den riktiga knappen. ]]
	knapp.MouseButton1Down:Fire()
	local till2 = os.clock() + 0.6
	while os.clock() < till2 do end
	knapp.MouseButton1Up:Fire()
	check("MEN ETT LÅNGT TRYCK PÅ KNAPPEN UTLÖSER", fyrade3 == 1,
		("%d"):format(fyrade3))

	--[[ Fingret glider av knappen. ]]
	fyrade3 = 0
	knapp.MouseButton1Down:Fire()
	check("hållet pågår medan fingret ligger kvar på knappen",
		N._hallsNu() == hall3)
	knapp.MouseLeave:Fire()
	check("ATT GLIDA AV KNAPPEN SLÄPPER HÅLLET", N._hallsNu() == nil)
	local till3 = os.clock() + 0.6
	while os.clock() < till3 do end
	check("och utlöser ingen handling", fyrade3 == 0, ("%d"):format(fyrade3))

	del3:Destroy()

	del2:Destroy()
	N.stopp()
end

--[[ ══ RADEN UNDER FINGRET FÅR INTE BYTA HANDLING (#264 R3 P1) ═════

	Granskningen av 259b421 mätte:

	    REVIEW_REORDER row1NowB=true stillHoldingA=true

	Raderna är fem återanvända knappar. Ordningen kommer ur avståndet, så
	när en närmare prompt dyker upp glider allt ett steg — och rad 1 får en
	ny handling utan att den gamla lämnat listan. Kontrollen som fanns
	prövade bara MEDLEMSKAP i listan och såg därför ingenting.

	Följden: knappen visade B medan A fortfarande laddades, och en hålltid
	som gick i mål hade utlöst den handling spelaren inte läste. Det är
	värre än ett tappat håll — det är fel handling utförd.

	Identiteten är tryck → RAD → PROMPT. Står inte samma prompt kvar på
	samma rad avbryts hållet. Provet mäter båda halvorna: att raden
	verkligen byter, och att hållet INTE följer med. ]]
print("\n── Raden under fingret byter handling ──")
do
	for _, d in ipairs(workspace:GetChildren()) do d:Destroy() end
	local Players = game:GetService("Players")
	local UIS = game:GetService("UserInputService")
	local kar = Instance.new("Model")
	kar.Name = "Spelare"
	local rot = Instance.new("Part")
	rot.Name = "HumanoidRootPart"
	rot.Position = HAR
	rot.Parent = kar
	kar.Parent = workspace
	Players.LocalPlayer.Character = kar
	UIS.TouchEnabled = true
	N.stopp()
	N.start()

	--[[ A ligger närmast och hamnar på rad 1. B ligger längre bort. ]]
	local dorrA, delA = nyPrompt("DorrA", "Öppna", "A", Vector3.new(1, 0, 0), 8, 0.5)
	local dorrB, delB = nyPrompt("DorrB", "Öppna", "B", Vector3.new(5, 0, 0), 8, 0.5)
	local fyradeA, fyradeB = 0, 0
	dorrA.Triggered:Connect(function() fyradeA += 1 end)
	dorrB.Triggered:Connect(function() fyradeB += 1 end)
	N.satRider(false)
	check("REPRODUKTION: A står på rad 1", N._prompter()[1] == dorrA)

	--[[ Fingret går ned på rad 1 — alltså på A. ]]
	N._hallNed(1)
	check("hållet ligger på A, från rad 1",
		N._hallsNu() == dorrA and N._hallRad() == 1,
		("rad=%s"):format(tostring(N._hallRad())))

	--[[ B flyttar sig närmare och tar rad 1. Ingen av dem lämnar
	     räckvidden — det är hela poängen med reproduktionen. ]]
	delB.Position = Vector3.new(0.2, 0, 0)
	N.satRider(false)
	check("row1NowB: raden visar nu B", N._prompter()[1] == dorrB,
		tostring(N._prompter()[1] and N._prompter()[1].Name))
	check("och A är FORTFARANDE inom räckvidd — inte bortgången",
		(function()
			for _, p in ipairs(N._relevanta()) do
				if p == dorrA then return true end
			end
			return false
		end)())
	check("stillHoldingA MÅSTE VARA FALSKT: hållet följde inte med",
		N._hallsNu() == nil, tostring(N._hallsNu() and N._hallsNu().Name))

	--[[ Och ingenting utlöses — varken den hon tryckte på eller den hon
	     råkade få under fingret. ]]
	local till = os.clock() + 0.6
	while os.clock() < till do end
	N._slappHall()
	check("varken A eller B utlöses av ett avbrutet håll",
		fyradeA == 0 and fyradeB == 0, ("A=%d B=%d"):format(fyradeA, fyradeB))

	--[[ ── POSITIV KONTROLL ─────────────────────────────────────────

	     Nollorna ovan får inte komma av att ingenting är kopplat. Ett
	     håll som får ligga still på SIN rad ska fullbordas. ]]
	N.satRider(false)
	local iB = (function()
		for i, p in ipairs(N._prompter()) do
			if p == dorrB then return i end
		end
		return nil
	end)()
	check("B har en rad att hållas på", iB ~= nil, tostring(iB))
	N._hallNed(iB)
	local till2 = os.clock() + 0.6
	while os.clock() < till2 do end
	N._slappHall()
	check("ETT OSTÖRT HÅLL FULLBORDAS", fyradeB == 1, ("%d"):format(fyradeB))

	--[[ ── ETT SLÄPP FRÅN FEL RAD AVSLUTAR INTE ETT NYARE HÅLL ──────

	     Alla fem knappar lever hela tiden. Ett `MouseLeave` som hinner
	     efter att fingret börjat ett nytt håll på en annan rad skulle
	     annars avbryta det nya. ]]
	fyradeA, fyradeB = 0, 0
	N.satRider(false)
	local iA = (function()
		for i, p in ipairs(N._prompter()) do
			if p == dorrA then return i end
		end
		return nil
	end)()
	check("båda har var sin rad", iA ~= nil and iB ~= nil,
		("A=%s B=%s"):format(tostring(iA), tostring(iB)))
	N._hallNed(iA)
	check("hållet ligger på A:s rad", N._hallRad() == iA)
	--[[ En eftersläpande signal från B:s rad. ]]
	N._slappHallFran(iB)
	check("ETT SLÄPP FRÅN FEL RAD RÖR INTE HÅLLET",
		N._hallsNu() == dorrA and N._hallRad() == iA,
		tostring(N._hallsNu() and N._hallsNu().Name))
	--[[ Och det egna släppet fungerar fortfarande. ]]
	local till3 = os.clock() + 0.6
	while os.clock() < till3 do end
	N._slappHallFran(iA)
	check("men släppet från RÄTT rad fullbordar hållet",
		fyradeA == 1 and N._hallsNu() == nil, ("A=%d"):format(fyradeA))

	--[[ ── OCH SAMMA SAK GENOM DE RIKTIGA KNAPPARNA ────────────────

	     Mätningarna ovan går genom `_hallNed`/`_slappHallFran`. De mäter
	     regeln, men inte att KNAPPARNA följer den — och det var där
	     falsifieringen hittade en lucka: en mutation som kopplade varje
	     knapps `MouseLeave` till ett villkorslöst `slappHall` gav noll
	     röda, för inget prov rörde knapparna i det här läget.

	     Här fyras signalerna på riktigt: fingret ligger på A:s knapp,
	     och B:s knapp får ett eftersläpande `MouseLeave`. ]]
	local function knappFor(i)
		local function sok(nod, namn)
			if type(nod) ~= "table" then return nil end
			if nod.Name == namn then return nod end
			for _, b in ipairs(nod._barn or {}) do
				local t = sok(b, namn)
				if t then return t end
			end
			return nil
		end
		local min = sok(game:GetService("Players").LocalPlayer._gui,
			"UBRFNaromrade")
		return min and sok(min, "Rad" .. i) or nil
	end

	fyradeA, fyradeB = 0, 0
	N.satRider(false)
	iA = (function()
		for i, p in ipairs(N._prompter()) do
			if p == dorrA then return i end
		end
		return nil
	end)()
	iB = (function()
		for i, p in ipairs(N._prompter()) do
			if p == dorrB then return i end
		end
		return nil
	end)()
	local knappA, knappB = knappFor(iA), knappFor(iB)
	check("båda raderna finns som riktiga knappar",
		knappA ~= nil and knappB ~= nil and iA ~= iB,
		("A=%s B=%s"):format(tostring(iA), tostring(iB)))

	knappA.MouseButton1Down:Fire()
	check("knappen A började hållet", N._hallsNu() == dorrA)
	--[[ Eftersläpande signaler från GRANNRADEN. ]]
	knappB.MouseLeave:Fire()
	knappB.MouseButton1Up:Fire()
	check("EN GRANNRADS SLÄPP RÖR INTE A:S HÅLL",
		N._hallsNu() == dorrA and N._hallRad() == iA,
		tostring(N._hallsNu() and N._hallsNu().Name))
	local till4 = os.clock() + 0.6
	while os.clock() < till4 do end
	knappA.MouseButton1Up:Fire()
	check("och A:s egen knapp fullbordar hållet",
		fyradeA == 1 and fyradeB == 0,
		("A=%d B=%d"):format(fyradeA, fyradeB))

	delA:Destroy()
	delB:Destroy()
	N.stopp()
end

--[[ ══ #264 ROBLOX_HUMAN_PLAYTEST_FIX: EN YTA OCH EN MOTTAGARE ════════════

	Tobias speltest 2026-09-25: fyra identiska «Open — Door [X]», bubblor
	för andra hästar, och ett G som tog Mac Kenzies trans och prövade två
	grannars samtidigt. Mätt i Studio: `Custom` tar bara ritytan, tangenten
	lever kvar på varje visad prompt.

	Det här avsnittet mäter produktionsvägen i `rita` — inte en hjälpfunktion
	— och läser tangenten ur prompten själv, som motorn gör. ]]
print("\n── #264: en tangent, en mottagare, högst en dörr ──")
do
	local UIS = game:GetService("UserInputService")
	local Players = game:GetService("Players")
	N.stopp()
	UIS.TouchEnabled = true
	local tangentbordFore = UIS.KeyboardEnabled
	UIS.KeyboardEnabled = true
	N.start()
	local spelare = Players.LocalPlayer
	local rot = spelare.Character:FindFirstChild("HumanoidRootPart")
	rot.Position = Vector3.new(0, 0, 0)

	local function forrad(hastId, namn, handling, lage, tangent, hall)
		local m = Instance.new("Model")
		m.Name = "Forrad264_" .. namn
		m:SetAttribute("ForHast", hastId)
		m.Parent = workspace
		local del = Instance.new("Part")
		del.Name = namn
		del.Position = lage
		del.Parent = m
		local pr = Instance.new("ProximityPrompt")
		pr.Name = namn .. "Prompt"
		pr.ActionText = handling
		pr.ObjectText = ""
		pr.MaxActivationDistance = 8
		pr.HoldDuration = hall or 0
		pr.RequiresLineOfSight = false
		pr.KeyboardKeyCode = tangent
		pr.Parent = del
		return pr, m
	end
	local function dorr(namn, lage)
		local del = Instance.new("Part")
		del.Name = namn
		del.Position = lage
		del.Parent = workspace
		local pr = Instance.new("ProximityPrompt")
		pr.Name = "DorrPrompt"
		pr.ActionText = "Open"
		pr.ObjectText = "Door"
		pr.MaxActivationDistance = 8
		pr.HoldDuration = 0
		pr.RequiresLineOfSight = false
		pr.KeyboardKeyCode = Enum.KeyCode.X
		pr.Parent = del
		return pr, del
	end
	local function iRader(p)
		for i, q in ipairs(N._prompter()) do if q == p then return i end end
		return nil
	end

	--[[ Grannens sadel NÄRMAST och med samma tangent — speltestets läge. ]]
	local granne, gM = forrad("marabou", "GrannSadel", "Take the saddle",
		Vector3.new(1, 0, 0), Enum.KeyCode.G)
	local egen, eM = forrad("trixie", "EgenSadel", "Take the saddle",
		Vector3.new(3, 0, 0), Enum.KeyCode.G)
	--[[ En andra egen handling som delar tangent med den första. ]]
	local egen2, e2M = forrad("trixie", "EgenFilt", "Take the pad",
		Vector3.new(3.5, 0, 0), Enum.KeyCode.G)
	local dorrNara, dNDel = dorr("Dörr nära", Vector3.new(2, 0, 0))
	local dorrLangt, dLDel = dorr("Dörr längre", Vector3.new(5, 0, 0))

	PreparationController._satHastIdForProv("trixie")
	N.satRider(false)

	check("dagens hästs första handling ÄGER sin tangent",
		egen.KeyboardKeyCode == Enum.KeyCode.G, tostring(egen.KeyboardKeyCode))
	check("GRANNENS SADEL ÄR TYST — ett G når den inte",
		granne.KeyboardKeyCode == Enum.KeyCode.Unknown,
		tostring(granne.KeyboardKeyCode))
	check("och grannens bild är släckt", granne.Style == Enum.ProximityPromptStyle.Custom)
	check("och grannen har ingen rad", iRader(granne) == nil)
	check("en andra egen handling med samma tangent behåller sin RAD",
		iRader(egen2) ~= nil)
	check("men inte tangenten — ett G har exakt en mottagare",
		egen2.KeyboardKeyCode == Enum.KeyCode.Unknown,
		tostring(egen2.KeyboardKeyCode))
	local etikettEgen2 = N._rader()[iRader(egen2) or 0] or ""
	check("och dess rad lovar ingen tangent den inte har",
		etikettEgen2:find("%[G%]") == nil, etikettEgen2)

	local dorrRader = 0
	for _, q in ipairs(N._prompter()) do if q.Name == "DorrPrompt" then dorrRader += 1 end end
	check("HÖGST EN DÖRR i listan", dorrRader == 1, ("%d dörrar"):format(dorrRader))
	check("och det är den närmaste", iRader(dorrNara) ~= nil and iRader(dorrLangt) == nil)
	check("den närmaste dörren äger X",
		dorrNara.KeyboardKeyCode == Enum.KeyCode.X, tostring(dorrNara.KeyboardKeyCode))
	check("den andra dörren är tyst och släckt",
		dorrLangt.KeyboardKeyCode == Enum.KeyCode.Unknown
			and dorrLangt.Style == Enum.ProximityPromptStyle.Custom,
		("%s %s"):format(tostring(dorrLangt.KeyboardKeyCode), tostring(dorrLangt.Style)))

	--[[ ── DÖRRMÅLET BYTS UNDER HÅLLET ─────────────────────────────────
		Hon håller på den närmaste dörren och går så att den andra blir
		närmast. Hållet ska släppas: målet under fingret är inte längre det
		hon började på, och exakt en dörr ska stå kvar. ]]
	local iD = iRader(dorrNara)
	N._hallNed(iD)
	check("hållet på dörren pågår", N._hallsNu() == dorrNara)
	rot.Position = Vector3.new(6, 0, 0)
	N.satRider(false)
	check("NÄR DÖRRMÅLET BYTS SLÄPPS HÅLLET", N._hallsNu() == nil,
		tostring(N._hallsNu() and N._hallsNu().Name))
	local dorrar2 = 0
	for _, q in ipairs(N._prompter()) do if q.Name == "DorrPrompt" then dorrar2 += 1 end end
	check("och fortfarande exakt en dörr, nu den andra",
		dorrar2 == 1 and iRader(dorrLangt) ~= nil, ("%d dörrar"):format(dorrar2))
	check("tangenten följde med till den nya dörren",
		dorrLangt.KeyboardKeyCode == Enum.KeyCode.X
			and dorrNara.KeyboardKeyCode == Enum.KeyCode.Unknown)
	rot.Position = Vector3.new(0, 0, 0)

	--[[ ── TILLDELNINGEN ANLÄNDER SENT ──────────────────────────────────
		Innan hästen är känd vet spelet inte bättre än spelaren, och
		grannens sadel är en handling bland andra — närmast, så den äger G.
		När tilldelningen landar blir den tyst och dagens häst tar G. ]]
	PreparationController._satHastIdForProv(nil)
	N.satRider(false)
	check("utan tilldelning äger den närmaste sadeln G",
		granne.KeyboardKeyCode == Enum.KeyCode.G
			and egen.KeyboardKeyCode == Enum.KeyCode.Unknown,
		("granne %s egen %s"):format(tostring(granne.KeyboardKeyCode),
			tostring(egen.KeyboardKeyCode)))
	PreparationController._satHastIdForProv("trixie")
	N.satRider(false)
	check("TILLDELNINGEN LANDAR: grannen tyst, dagens häst tar G",
		granne.KeyboardKeyCode == Enum.KeyCode.Unknown
			and egen.KeyboardKeyCode == Enum.KeyCode.G)

	--[[ ── FÖRKANTEN ────────────────────────────────────────────────────
		Strax utanför räckvidd: släckt och tyst innan motorn hinner visa
		den. Inom räckvidd: rad och tangent. ]]
	local fore, fM = forrad("trixie", "Forkant", "Groom", Vector3.new(11, 0, 0),
		Enum.KeyCode.V)
	N.satRider(false)
	check("en prompt i förkanten är släckt och tyst, utan rad",
		fore.Style == Enum.ProximityPromptStyle.Custom
			and fore.KeyboardKeyCode == Enum.KeyCode.Unknown and iRader(fore) == nil,
		("%s %s"):format(tostring(fore.Style), tostring(fore.KeyboardKeyCode)))
	rot.Position = Vector3.new(6, 0, 0)
	N.satRider(false)
	check("inom räckvidd får den rad och sin tangent tillbaka",
		iRader(fore) ~= nil and fore.KeyboardKeyCode == Enum.KeyCode.V,
		tostring(fore.KeyboardKeyCode))
	rot.Position = Vector3.new(0, 0, 0)

	--[[ ── HÅLL-GRINDEN SÄGS I RADEN ────────────────────────────────── ]]
	local hallp, hM = forrad("trixie", "Leda", "Lead", Vector3.new(0.5, 0, 0),
		Enum.KeyCode.L, 0.2)
	N.satRider(false)
	local hallOrd = Sprak.t("interaktion.hall_inne")
	local etikettHall = N._rader()[iRader(hallp) or 0] or ""
	check("en prompt med håll-grind säger det i raden",
		etikettHall:find("[" .. hallOrd .. " L]", 1, true) ~= nil, etikettHall)
	local etikettEgen = N._rader()[iRader(egen) or 0] or ""
	check("en utan håll-grind gör det inte",
		etikettEgen:find(hallOrd, 1, true) == nil, etikettEgen)

	--[[ ── RUTAN I SKÄRMENS RUM ───────────────────────────────────────────
		Mätt i Studio: panelens ruta stod i en yta med IgnoreGuiInset
		(0, -58) och lästes i listans yta (0, 0). Listans golv hamnade
		58 px för lågt, över instruktionen. Rutan lämnas nu i skärmens
		absoluta rum, och listan räknar om till sitt eget. ]]
	do
		local yta = spelare:FindFirstChildOfClass("PlayerGui"):FindFirstChild("UBRFNaromrade")
		local forePos, foreStorlek = yta.AbsolutePosition, yta.AbsoluteSize
		yta.AbsolutePosition = Vector2.new(0, 58)
		yta.AbsoluteSize = Vector2.new(1179, 761)
		PreparationController._satRutaForProv({ x0 = 12, y0 = 697, x1 = 328, y1 = 807 })
		check("RUTAN RÄKNAS OM TILL LISTANS RUM — golvet är panelens överkant",
			N.blockgolv() == 697 - 58, ("golv %s"):format(tostring(N.blockgolv())))
		PreparationController._satRutaForProv(nil)
		yta.AbsolutePosition, yta.AbsoluteSize = forePos, foreStorlek
	end

	--[[ ── OCH ALLT ÅTERSTÄLLS NÄR HON GÅR ─────────────────────────────── ]]
	rot.Position = Vector3.new(200, 0, 0)
	N.satRider(false)
	local orort = egen.KeyboardKeyCode == Enum.KeyCode.G
		and granne.KeyboardKeyCode == Enum.KeyCode.G
		and egen2.KeyboardKeyCode == Enum.KeyCode.G
		and dorrLangt.KeyboardKeyCode == Enum.KeyCode.X
		and granne.Style == Enum.ProximityPromptStyle.Default
		and dorrLangt.Style == Enum.ProximityPromptStyle.Default
	check("utom räckhåll får varje prompt tillbaka sin tangent och sin bild",
		orort and N._slackta() == 0, ("släckta %d"):format(N._slackta()))

	for _, x in ipairs({ gM, eM, e2M, dNDel, dLDel, fM, hM }) do x:Destroy() end
	rot.Position = Vector3.new(0, 0, 0)
	PreparationController._satHastIdForProv(nil)
	UIS.KeyboardEnabled = tangentbordFore
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
