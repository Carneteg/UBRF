--!nostrict
--[[
	PROMPTKONKURRENS I HELA STALLKONTEXTEN (#182 del 3).

	`klient-ledprompt.spec` mäter knapparna PÅ HÄSTEN mot kontrollmatrisen.
	Den kan inte se det här: att boxmarkören, boxdörren, sadeln, tränset
	och hästens egna knappar alla ligger inom räckhåll SAMTIDIGT, byggda
	av fem olika filer som inte känner varandra.

	DET ÄR DÄR #235 KOM IFRÅN. Mätt i Studio med iPhone-emulering stod
	fem prompter inom sin räckvidd och `PromptShown` var noll. Två fel i
	samma bild, och det här provet mäter det andra: att flera samtidigt
	relevanta handlingar konkurrerar om samma knapp.

	TVÅ REGLER MÄTS, och de hänger ihop:

	  1. `Exclusivity`. Roblox standard är `OnePerButton`: av flera
	     prompter med SAMMA knapp visas bara den närmaste. Fyra handlingar
	     på `E` betyder då att tre är osynliga — spelaren vet inte ens att
	     de finns.
	  2. TANGENTEN. Två prompter som är uppe samtidigt får inte dela
	     tangent eller handkontrollsknapp. Delar de ändå måste det finnas
	     en KONTEXT som gör att de aldrig kan vara uppe samtidigt, och den
	     kontexten ska vara bevisad — inte påstådd.

	PROVET BYGGER HELA VÄRLDEN och ställer en spelare i sin box, så att
	klustret blir det verkliga och inte ett provet hittat på.

	Kör: python3 roblox/tests/build.py tests/promptkonflikt.spec.luau
	     && luau roblox/tests/.build/promptkonflikt.spec.luau
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
local RSt = game:GetService("ReplicatedStorage")
local IC = InteractionController

local M = 3

local function nyKaraktar(pos)
	local k = Instance.new("Model")
	k.Name = "Karaktar"
	for _, namn in ipairs({ "HumanoidRootPart", "UpperTorso", "RightHand" }) do
		local d = Instance.new("Part")
		d.Name = namn
		d.Size = Vector3.new(2, 2, 1)
		d.CFrame = CFrame.new(pos)
		d.Parent = k
	end
	local hum = Instance.new("Humanoid")
	hum.Name = "Humanoid"
	hum.Parent = k
	k.Parent = workspace
	return k, k:FindFirstChild("HumanoidRootPart")
end

local karaktar, rot = nyKaraktar(Vector3.new(0, 3, 0))

local spelare = Players.LocalPlayer
spelare.Name = "Stallgast"
spelare.UserId = 7701
spelare.Character = karaktar
spelare.CharacterAdded = __signal_ny()
spelare.CharacterRemoving = __signal_ny()

RunService._server = true
Players._spelare = { spelare }

SparService._glomHookarForProv()
SparService._glomForProv(spelare)
SparService.start()
StallService.start()
HorseService.start()
GameplayService.start()
LedService.start()
DorrService.start()
TackForradService.start(GameplayService.valjEn)

Players.PlayerAdded:Fire(spelare)
Players.PlayerAdded:slutfor()

local HAST_ID = StallService.hastIdFor(spelare)

print("\n── Stallkontexten: var spelaren faktiskt står ──")

check("spelaren har en tilldelad häst", HAST_ID ~= nil, tostring(HAST_ID))
local FRONT = HAST_ID and TackForradService.forHast(HAST_ID)
check("hennes boxfront finns i världen", FRONT ~= nil)

if not (HAST_ID and FRONT) then
	print("\nKonflikten kan inte mätas utan en box att stå vid.")
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error("ingen box", 0)
end

--[[ Hästen ställs vid sin egen front, som hon står i stallet. ]]
local hast = HastRigg.bygg(HAST_ID, HAST_ID,
	CFrame.new(FRONT.PrimaryPart.Position + Vector3.new(0, 0, 4)))
hast.Parent = workspace
hast:SetAttribute("HorseId", HAST_ID)
hast:SetAttribute("HorseName", UBRFSpel.hastar[HAST_ID]
	and UBRFSpel.hastar[HAST_ID].namn or HAST_ID)
Taggar:AddTag(hast, "Horse")
GameplayService.bind(spelare)

--[[ SPELAREN STÅR VID SIN BOXFRONT. Det är den punkt där flest
	handlingar är möjliga samtidigt, och därför den punkt som avgör. ]]
rot.CFrame = CFrame.new(FRONT.PrimaryPart.Position + Vector3.new(2, 0, 0))

RunService._server = false
RSt:SetAttribute("G01Enabled", true)

--[[ Hästens egna knappar ritas alla, så att provet mäter det VÄRSTA
	samtidiga läget och inte ett bekvämt. Att de inte alla kan vara uppe
	i spelet är en annan sak — och den mäts där den hör hemma. ]]
IC.setReadyCheck(function() return true end)
IC.setRidaCheck(function() return true end)
IC.setLedCheck(function() return true end)
IC.setSadlaCheck(function() return true end)
IC.setTransaCheck(function() return false end)
IC.start(function() end)
IC.uppdatera()

--[[ ── Alla prompter inom räckhåll, oavsett vem som byggde dem ────────

	Söker hela `workspace`, inte en lista provet skrivit. En ny prompt
	från en sjätte fil ska fångas av det här provet utan att någon minns
	att lägga till den. ]]
local function varldslage(p)
	local f = p.Parent
	if f and f:IsA("BasePart") then return f.Position end
	if f and f:IsA("Attachment") then return f.WorldPosition end
	return nil
end

local function promptarNara(fran)
	local ut = {}
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("ProximityPrompt") and d.Enabled then
			local pos = varldslage(d)
			if pos and (pos - fran).Magnitude <= d.MaxActivationDistance then
				table.insert(ut, d)
			end
		end
	end
	return ut
end

local nara = promptarNara(rot.Position)

do
	local namn = {}
	for _, p in ipairs(nara) do table.insert(namn, p.Name) end
	table.sort(namn)
	check("flera handlingar är möjliga samtidigt där hon står",
		#nara >= 3, ("%d st: %s"):format(#nara, table.concat(namn, ", ")))
end

print("\n── Regel 1: ingen samtidig handling får döljas ──")

do
	--[[ `OnePerButton` är Roblox STANDARD. Den som inte sätter något får
		den, och då visas bara den närmaste av flera på samma knapp.
		Handlingar som är möjliga samtidigt ska synas samtidigt. ]]
	local doljda = {}
	for _, p in ipairs(nara) do
		if p.Exclusivity ~= Enum.ProximityPromptExclusivity.AlwaysShow then
			table.insert(doljda, ("%s=%s"):format(p.Name, tostring(p.Exclusivity)))
		end
	end
	check("varje samtidigt nåbar prompt är satt att ALLTID visas",
		#doljda == 0, table.concat(doljda, " "))
end

print("\n── Regel 2: samtidiga handlingar delar inte knapp ──")

do
	--[[ Nyckeln är det spelaren trycker på. `nil` betyder Roblox
		standardvärde — `E` respektive `ButtonX` — och två prompter som
		BÅDA lämnar den odefinierad delar den lika mycket som två som
		skriver ut den. Provet normaliserar därför nil till standarden,
		annars hade den vanligaste krocken av alla varit osynlig. ]]
	local function tangent(p)
		local k = p.KeyboardKeyCode
		if k == nil or k == Enum.KeyCode.Unknown then return Enum.KeyCode.E end
		return k
	end
	local function padknapp(p)
		local k = p.GamepadKeyCode
		if k == nil or k == Enum.KeyCode.Unknown then return Enum.KeyCode.ButtonX end
		return k
	end

	local perTangent = {}
	local perPad = {}
	for _, p in ipairs(nara) do
		local t = tostring(tangent(p))
		local g = tostring(padknapp(p))
		--[[ SAMMA HANDLING PÅ OLIKA FÖREMÅL ÄR INGEN KONFLIKT.

			Tre dörrar delar `X`, två grannboxars sadlar delar `G`. Det är
			SAMMA handling på olika ting, och närheten avgör vilken — så
			fungerar en världsprompt, och så ska den fungera. Att kräva en
			egen tangent per dörr vore absurt.

			Konflikten är när TVÅ OLIKA handlingar delar knapp, för då kan
			spelaren inte välja vilken hon menar utan att flytta sig. Det
			är därför nyckeln är promptens NAMN och inte dess instans. ]]
		perTangent[t] = perTangent[t] or {}
		perPad[g] = perPad[g] or {}
		perTangent[t][p.Name] = true
		perPad[g][p.Name] = true
	end

	local function handlingarna(m)
		local ut = {}
		for namn in pairs(m) do table.insert(ut, namn) end
		table.sort(ut)
		return ut
	end

	local krockT = {}
	for t, m in pairs(perTangent) do
		local lista = handlingarna(m)
		if #lista > 1 then
			table.insert(krockT, ("%s: %s"):format(t, table.concat(lista, "+")))
		end
	end
	table.sort(krockT)
	check("inga två OLIKA handlingar delar tangent", #krockT == 0,
		table.concat(krockT, " · "))

	local krockG = {}
	for g, m in pairs(perPad) do
		local lista = handlingarna(m)
		if #lista > 1 then
			table.insert(krockG, ("%s: %s"):format(g, table.concat(lista, "+")))
		end
	end
	table.sort(krockG)
	check("inga två OLIKA handlingar delar handkontrollsknapp",
		#krockG == 0, table.concat(krockG, " · "))
end

print("\n── Boxmarkören: ett ANNAT kluster, samma regler ──")

do
	--[[ BOXMARKÖREN LIGGER FÖR SIG. Min egen falsifiering visade det:
		mutationen som gav `BoxPrompt` tillbaka Roblox standardknapp kom ut
		GRÖN, eftersom markören inte är inom räckhåll från boxfronten och
		alltså aldrig mättes.

		En regel som bara gäller där provet råkar stå är ingen regel. Den
		andra mätpunkten är därför markören själv. ]]
	local box = nil
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("ProximityPrompt") and d.Name == "BoxPrompt" then box = d end
	end
	check("boxmarkörens prompt finns i världen", box ~= nil)

	if box and box.Parent and box.Parent:IsA("BasePart") then
		local vidBox = box.Parent.Position + Vector3.new(1, 0, 0)
		local klustret = promptarNara(vidBox)
		local namn = {}
		for _, p in ipairs(klustret) do table.insert(namn, p.Name) end
		table.sort(namn)
		check("och den är nåbar där markören står", #klustret >= 1,
			("%d st: %s"):format(#klustret, table.concat(namn, ", ")))

		local sedda = {}
		local krock = {}
		for _, p in ipairs(klustret) do
			local t = p.KeyboardKeyCode
			if t == nil or t == Enum.KeyCode.Unknown then t = Enum.KeyCode.E end
			local nyckel = tostring(t)
			sedda[nyckel] = sedda[nyckel] or {}
			sedda[nyckel][p.Name] = true
		end
		for nyckel, m in pairs(sedda) do
			local lista = {}
			for n in pairs(m) do table.insert(lista, n) end
			if #lista > 1 then
				table.sort(lista)
				table.insert(krock, ("%s: %s"):format(nyckel, table.concat(lista, "+")))
			end
		end
		table.sort(krock)
		check("inga två OLIKA handlingar delar tangent vid markören",
			#krock == 0, table.concat(krock, " · "))
		check("markörens egen prompt döljs inte heller",
			box.Exclusivity == Enum.ProximityPromptExclusivity.AlwaysShow,
			tostring(box.Exclusivity))
		check("och den går att trycka på med ett finger",
			box.ClickablePrompt == true)
	end
end

print("\n── Regel 3: varje rad namnger sitt objekt ──")

do
	--[[ Fem rader som alla säger «Öppna» eller «Ta» är oanvändbara. Varje
		prompt ska namnge VAD den gäller — hästen, dörren, delen — och
		texten ska vara läsbar, inte en nyckel. ]]
	local utan = {}
	for _, p in ipairs(nara) do
		local handling = tostring(p.ActionText or "")
		local objekt = tostring(p.ObjectText or "")
		if handling == "" then
			table.insert(utan, p.Name .. "(ingen handling)")
		elseif objekt == "" and handling:find(" ") == nil then
			--[[ En handling utan objekt duger bara om handlingen SJÄLV
				namnger saken — «Led Trixie» gör det, «Öppna» inte. ]]
			table.insert(utan, p.Name .. "(varken objekt eller namn)")
		end
	end
	check("varje samtidig prompt namnger sitt objekt eller sin häst",
		#utan == 0, table.concat(utan, " "))
end

print("\n── Regel 4: alla tre inmatningarna når fram ──")

do
	--[[ KONTROLLMATRIS regel 1: ordningen är tangentbord → gamepad →
		touch, och en ren pekenhet får aldrig en bokstav hon inte kan
		trycka på. `ClickablePrompt` är det som gör knappen nåbar med ett
		finger; utan den finns ingen väg in på en telefon. ]]
	local ejFinger = {}
	for _, p in ipairs(nara) do
		if p.ClickablePrompt ~= true then table.insert(ejFinger, p.Name) end
	end
	check("varje samtidig prompt går att trycka på med ett finger",
		#ejFinger == 0, table.concat(ejFinger, " "))

	--[[ Och touchytan i #235 hittar dem alla: den söker hela världen på
		samma sätt som provet ovan, så en prompt som syns här får en rad
		där. Att raden går att träffa mäts av `klient-naromrade.spec`. ]]
	local rader = Naromrade.nara(rot.Position, { workspace })
	--[[ LISTAN HAR ETT MEDVETET TAK på fem rader. Fler är inte ett val
		utan en vägg på en telefon i landskap, och taket klipps EFTER
		sorteringen så att det närmaste alltid är kvar.

		Kravet är därför inte att listan visar alla elva, utan att varje
		rad den visar är en riktig prompt härifrån — och att det är taket,
		inte tomhet, som begränsar. Ett prov som krävt likhet hade tvingat
		bort taket och gjort telefonen sämre. ]]
	local iNara = {}
	for _, p in ipairs(nara) do iNara[p] = true end
	local frammande = 0
	for _, p in ipairs(rader) do
		if not iNara[p] then frammande += 1 end
	end
	check("varje rad i närområdet är en prompt som verkligen finns här",
		frammande == 0, ("%d främmande"):format(frammande))
	check("och listan är full — taket, inte tomhet, är det som begränsar",
		#rader == math.min(#nara, 5),
		("%d rader av %d möjliga"):format(#rader, #nara))
end

RunService._server = false

if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("\npromptkonflikt.spec: alla gröna")
end
