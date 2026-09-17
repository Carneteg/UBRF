--!strict
--[[
	NÄROMRÅDET — en gemensam touchyta för allt man kan göra vid hästen.

	══ VARFÖR DEN FINNS (#235) ═══════════════════════════════════════

	Tobias verifierade på FYSISK iPhone att First Playable är ospelbart
	före ridning: sadel och träns går inte att hämta, hästen går inte att
	interagera med, och ledningen går därför inte att starta alls.

	Mätt i Studio med iPhone 13-emulering, spelaren 4,3 studs från sin
	egen hästs utrustning på boxfronten:

	    ProximityPromptService.PromptShown   0 gånger på 2 sekunder
	    prompter inom sin räckvidd           5 stycken

	      Boxdörr MB 7   "Open"                        2,5 st
	      Sadel          "Take the saddle and bridle"  4,3 st   ← den hon vill ha
	      Sadel          (en annan hästs)              6,7 st
	      Boxdörr E 7    "Open"                        7,2 st
	      hästen         "Ride now"                    8,4 st

	Två fel i samma bild. Prompterna RENDERAS inte i vår stack — och även
	när de gör det ska spelaren träffa rätt av fem flytande knappar som
	ligger i djupet, med tummen, på en telefon i landskap.

	══ VAD DEN HÄR FILEN GÖR, OCH INTE GÖR ═══════════════════════════

	Den ritar en LISTA över det som faktiskt går att göra där spelaren
	står, som riktiga knappar i skärmens plan, och trycker på spelarens
	vägnar på den prompt raden hör till.

	Den innehåller INGEN gameplaylogik. Inga remotes, ingen distans-
	prövning, ingen ägarskapskontroll, inga egna regler. Varje rad
	aktiverar `prompt:InputHoldBegin()` / `InputHoldEnd()` — promptens
	EGEN väg — så att serverns handlare, dess avståndskrav och dess
	nej:er gäller precis som förut. Tas en prompt bort försvinner raden;
	nekar servern syns nejet där nejen alltid synts.

	Det är skillnaden mot en "mobil gameplayväg": det finns ingen. Det
	här är en annan KNAPP till samma handling.

	══ VARFÖR INTE BARA FLYTTA PROMPTERNA ════════════════════════════

	För att trängseln är verklig och inte ett layoutfel: boxfronterna
	står tätt, och hästen, hennes utrustning och två boxdörrar ÄR nära
	varandra i verkligheten. `docs/ASSET-SOURCE-OF-TRUTH.md` och
	byggnadskorten säger var de står; att glesa ut dem för att en knapp
	ska bli lättare att träffa vore att flytta anläggningen för att lösa
	ett UI-problem, vilket `CLAUDE.md` uttryckligen förbjuder.

	══ BARA PEKSKÄRM, BARA TILL FOTS ═════════════════════════════════

	Skrivbord och handkontroll rörs inte: `start` returnerar direkt utan
	`TouchEnabled`. Och medan man rider äger `TouchControls` skärmen —
	då är närområdet släckt, för ridningens reglage har sina egna ytor
	och sin egen reserv.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Sprak = require(ReplicatedStorage.HorseCore.Sprak)

local Naromrade = {}

--[[ ── MÅTTEN ──────────────────────────────────────────────────────

	44 px är golvet för en träffyta i `docs/KONTROLLMATRIS.md` regel 5.
	52 ger marginal och är samma höjd som ridningens egna knappar i
	`TouchControls`, så att de två ytorna känns som samma spel. ]]
local KNAPP_H = 52
local KNAPP_B = 190
local LUFT = 8
local KANT = 16

--[[ Hur många rader som ritas. Fler än så är inte ett val, det är en
	lista — och mätningen ovan hittade fem konkurrerande prompter, så
	taket måste rymma dem utan att fylla skärmen. ]]
local MAX_RADER = 5

--[[ Hur ofta listan räknas om. Tätare än så kostar utan att synas;
	glesare gör att en rad ligger kvar när man gått därifrån. ]]
local TAKT = 0.2

local gui: ScreenGui? = nil
local ram: Frame? = nil
local rader: { TextButton } = {}
local koppling: RBXScriptConnection? = nil
local sedan = 0
local rider = false
local senaste: { ProximityPrompt } = {}

--[[ Vad raden ska heta. Promptens egen `ActionText` är redan spelarens
	språk — den sätts av tjänsterna ur språkkanonen — och `ObjectText`
	säger vilken häst eller dörr det gäller. Två rader som annars vore
	identiska ("Öppna", "Öppna") blir åtskilda av objektet. ]]
local function etikett(p: ProximityPrompt): string
	local handling = p.ActionText
	if handling == nil or handling == "" then handling = Sprak.t("interaktion.anvand") end
	local objekt = p.ObjectText
	if objekt ~= nil and objekt ~= "" then
		return ("%s — %s"):format(handling, objekt)
	end
	return handling
end

--[[ Var prompten sitter i världen. En prompt kan hänga i en `Attachment`
	lika gärna som i en `BasePart`; båda har ett världsläge, och utan den
	här skillnaden tappar listan varje prompt som sitter på en fästpunkt
	— till exempel uppsittningens, som hänger i sadelpunkten. ]]
local function varldslage(p: ProximityPrompt): Vector3?
	local f = p.Parent
	if f and f:IsA("BasePart") then return f.Position end
	if f and f:IsA("Attachment") then return f.WorldPosition end
	return nil
end

--[[ Allt spelaren kan göra just nu, närmast först.

	Ren funktion av världen och ett läge — inga instanser skapas — så att
	den går att mäta i bänken utan att någon GUI behöver finnas. ]]
function Naromrade.nara(fran: Vector3, sok: { Instance }): { ProximityPrompt }
	local ut: { ProximityPrompt } = {}
	local avstand: { [ProximityPrompt]: number } = {}
	for _, rot in ipairs(sok) do
		for _, d in ipairs(rot:GetDescendants()) do
			if d:IsA("ProximityPrompt") and d.Enabled then
				local p = varldslage(d)
				if p then
					local a = (p - fran).Magnitude
					if a <= d.MaxActivationDistance then
						table.insert(ut, d)
						avstand[d] = a
					end
				end
			end
		end
	end
	table.sort(ut, function(a, b) return avstand[a] < avstand[b] end)
	--[[ Taket klipps EFTER sorteringen: det som är närmast är det
		spelaren menar, och det får aldrig trängas bort av något längre
		bort som råkade hittas först. ]]
	while #ut > MAX_RADER do table.remove(ut) end
	return ut
end

local function nyKnapp(i: number): TextButton
	local b = Instance.new("TextButton")
	b.Name = "Rad" .. i
	b.Size = UDim2.fromOffset(KNAPP_B, KNAPP_H)
	b.Position = UDim2.fromOffset(0, (i - 1) * (KNAPP_H + LUFT))
	b.BackgroundColor3 = Color3.fromRGB(24, 27, 33)
	b.BackgroundTransparency = 0.12
	b.TextColor3 = Color3.fromRGB(236, 232, 222)
	b.Font = Enum.Font.GothamMedium
	b.TextSize = 15
	b.TextScaled = true
	b.TextWrapped = true
	b.AutoButtonColor = false
	b.BorderSizePixel = 0
	b.Visible = false
	local tak = Instance.new("UITextSizeConstraint")
	tak.MaxTextSize = 15
	tak.MinTextSize = 9
	tak.Parent = b
	local horn = Instance.new("UICorner")
	horn.CornerRadius = UDim.new(0, 12)
	horn.Parent = b
	return b
end

--[[ TRYCKET GÅR GENOM PROMPTENS EGEN VÄG. Ingen genväg till servern,
	ingen kopia av handlaren: `InputHoldBegin` är exakt vad en tangent
	eller ett tryck på promptens egen knapp gör, och `HoldDuration`
	respekteras därför precis som förut. ]]
local function tryck(p: ProximityPrompt)
	if p == nil or p.Parent == nil or not p.Enabled then return end
	p:InputHoldBegin()
	if p.HoldDuration and p.HoldDuration > 0 then
		task.delay(p.HoldDuration + 0.05, function()
			if p.Parent then p:InputHoldEnd() end
		end)
	else
		p:InputHoldEnd()
	end
end

local function bygg()
	if gui then return end
	local spelare = Players.LocalPlayer
	local mapp = spelare:FindFirstChildOfClass("PlayerGui")
	if not mapp then return end

	local g = Instance.new("ScreenGui")
	g.Name = "UBRFNaromrade"
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = false
	--[[ Över Roblox egna pekreglage (0) och över skötselpanelen (10), så
		att listan aldrig hamnar under något som inte är en handling.
		Under hjälpknappen (16), som ska gå att nå alltid. ]]
	g.DisplayOrder = 14
	g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	g.Parent = mapp
	gui = g

	local f = Instance.new("Frame")
	f.Name = "Lista"
	f.BackgroundTransparency = 1
	f.Size = UDim2.fromOffset(KNAPP_B, MAX_RADER * (KNAPP_H + LUFT))
	--[[ VÄNSTERKANTEN, NEDTILL. Skötsel-HUD:ens spårare bor uppe till
		höger och lektionskortet nedtill i mitten; vänsterkanten är den
		enda som är fri medan man går till fots. Ridningens spak bor
		också där — men då rider man, och då är den här ytan släckt. ]]
	f.Position = UDim2.new(0, KANT, 1, -(MAX_RADER * (KNAPP_H + LUFT)) - KANT)
	f.Parent = g
	ram = f

	for i = 1, MAX_RADER do
		local b = nyKnapp(i)
		b.Parent = f
		b.MouseButton1Click:Connect(function()
			local p = senaste[i]
			if p then tryck(p) end
		end)
		rader[i] = b
	end
end

local function rita()
	local f = ram
	if not f then return end
	local spelare = Players.LocalPlayer
	local karaktar = spelare.Character
	local rot = karaktar and karaktar:FindFirstChild("HumanoidRootPart")

	--[[ Medan man rider äger `TouchControls` skärmen, och till fots utan
		kropp finns ingenting att stå nära. Båda släcker listan hellre än
		att visa en rad som inte går att lita på. ]]
	if rider or not (rot and rot:IsA("BasePart")) then
		senaste = {}
		for _, b in ipairs(rader) do b.Visible = false end
		return
	end

	senaste = Naromrade.nara((rot :: BasePart).Position, { workspace })
	for i, b in ipairs(rader) do
		local p = senaste[i]
		if p then
			b.Text = etikett(p)
			b.Visible = true
		else
			b.Visible = false
		end
	end
end

--[[ Provets fönster in: vad står på skärmen just nu? ]]
function Naromrade._rader(): { string }
	local ut = {}
	for _, b in ipairs(rader) do
		if b.Visible then table.insert(ut, b.Text) end
	end
	return ut
end

function Naromrade._tryckPa(i: number)
	local p = senaste[i]
	if p then tryck(p) end
end

--[[ Ridningen äger skärmen medan den pågår. Sätts från `init.client`,
	samma väg som `DinHast.satDold`. ]]
function Naromrade.satRider(v: boolean)
	rider = v
	rita()
end

function Naromrade.start()
	--[[ SKRIVBORDET RÖRS INTE. Utan pekskärm finns tangenterna, och en
		extra knapplista hade bara tagit plats. ]]
	if not UserInputService.TouchEnabled then return end
	bygg()
	if koppling then koppling:Disconnect() end
	koppling = RunService.RenderStepped:Connect(function(dt)
		sedan += dt
		if sedan < TAKT then return end
		sedan = 0
		rita()
	end)
end

function Naromrade.stopp()
	if koppling then
		koppling:Disconnect()
		koppling = nil
	end
	if gui then
		gui:Destroy()
		gui = nil
	end
	ram = nil
	rader = {}
	senaste = {}
end

return Naromrade
