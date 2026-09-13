--!strict
--[[
	MARKKONTAKTEN — hovarna ska möta den yta man SER.

	══ VAD SOM MÄTTES ═════════════════════════════════════════════════

	Hovarna stod 0,18 studs (6 cm) NER i ridbanans sand. På stallgolvet
	stod de på 0,000. Skillnaden gick att läsa rakt av genom att skjuta en
	stråle genom alla lager under hästen:

	    Ridbanan           y 0,180   CanCollide FALSE   ← det man SER
	    Dressyrlayout      y 0,150   CanCollide FALSE
	    ridhus grund       y 0,000   CanCollide TRUE    ← det hon STÅR på
	    Mark gras          y −0,057  CanCollide TRUE

	Hästen stod alltså exakt rätt — `antagen mark −0,000`, `nätets lägsta
	−0,000` — på det golv som faktiskt kolliderar. Ovanpå det golvet
	ligger sanden som ett 0,18 studs tjockt DEKORLAGER utan kollision, och
	därför sjönk hovarna igenom den.

	Det är alltså inte ett fel i höjdsättningen och inte i nätet: det är
	ytans tjocklek. I stallet finns inget sådant lager, och där stämde det
	redan.

	══ VARFÖR DET LÖSES HÄR OCH INTE I VÄRLDEN ════════════════════════

	Den uppenbara rättningen vore att låta sanden kollidera. Men
	`roblox/buildings/` är Replits miljöfil, och ett dekorlager utan
	kollision är ett medvetet val: den strukturella grunden bär, sanden
	ritar. Att ändra det utan samordning vore att gå in i någon annans
	ansvar.

	Modulen lyfter i stället hästen så att hon står PÅ ytan i stället för
	i den, genom att lägga lagrets tjocklek till `HipHeight` — vilket är
	exakt vad `HipHeight` betyder: avståndet från marken till rotens
	underkant. Kollisionshöljet, nätet och sitsen följer med oförändrade;
	det enda som ändras är hur högt Humanoiden håller henne.

	Skillnaden räknas om när hon flyttar sig, för den är olika på olika
	underlag: noll på stallgolvet, 0,18 i ridbanan.

	══ VARFÖR TVÅ STRÅLAR OCH INTE EN ═════════════════════════════════

	`RaycastParams.RespectCanCollide` är hela mätningen. Falsk (standard)
	träffar strålen ALLT, alltså dekorlagret; sann träffar bara det som
	bär. Avståndet mellan de två svaren ÄR lagrets tjocklek, och det är
	det talet som ska adderas.
]]

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Markkontakt = {}

local TAG = "Horse"
--[[ Hur ofta markkontakten räknas om. Underlaget byts när hästen går
	genom en dörr, inte mellan två bildrutor; en halv sekund är gott om
	tid och kostar 66 strålar i sekunden för hela rostern. ]]
local TAKT = 0.5
--[[ Under den här skillnaden rörs ingenting. Utan tröskeln skulle
	`HipHeight` skrivas varje varv med samma tal, och varje skrivning är
	en replikering. ]]
local TROSKEL = 0.01
--[[ Tjockare lager än så är inte ett dekorlager utan något hon står
	ovanpå — en ramp, ett hinder, en annan häst. Då rörs ingenting. ]]
local MAX_LAGER = 1.0

--[[ Tjockleken på det icke-kolliderande lagret under `rot`: skillnaden
	mellan den översta ytan över huvud taget och den översta som bär.

	Svarar 0 när det inte finns något lager, och 0 när svaret inte går
	att lita på — en yta utan botten, eller ett lager tjockare än
	`MAX_LAGER`. Ett osäkert svar ska inte flytta en häst. ]]
function Markkontakt.lagertjocklek(rot: BasePart, utanfor: { Instance }): number
	local synlig = RaycastParams.new()
	synlig.FilterType = Enum.RaycastFilterType.Exclude
	synlig.FilterDescendantsInstances = utanfor
	synlig.RespectCanCollide = false

	local barande = RaycastParams.new()
	barande.FilterType = Enum.RaycastFilterType.Exclude
	barande.FilterDescendantsInstances = utanfor
	barande.RespectCanCollide = true

	local ned = Vector3.new(0, -30, 0)
	local a = workspace:Raycast(rot.Position, ned, synlig)
	local b = workspace:Raycast(rot.Position, ned, barande)
	if not (a and b) then return 0 end
	local d = a.Position.Y - b.Position.Y
	if d < TROSKEL or d > MAX_LAGER then return 0 end
	return d
end

--[[ Sätter en hästs markkontakt EN gång. Publik för att provet ska kunna
	mäta samma räkning som loopen kör. ]]
function Markkontakt.justera(hast: Model, alla: { Instance }): number
	local rot = hast.PrimaryPart or hast:FindFirstChild("HumanoidRootPart")
	local hum = hast:FindFirstChildOfClass("Humanoid")
	if not (rot and rot:IsA("BasePart") and hum) then return 0 end
	--[[ Grundhöjden sparas första gången: den är hästens egen, skalad ur
		hennes mankhöjd, och får aldrig gå förlorad i en omräkning. ]]
	local bas = hast:GetAttribute("UBRFHipBas")
	if type(bas) ~= "number" then
		bas = hum.HipHeight
		hast:SetAttribute("UBRFHipBas", bas)
	end
	local lager = Markkontakt.lagertjocklek(rot, alla)
	local mal = (bas :: number) + lager
	if math.abs(hum.HipHeight - mal) > TROSKEL then
		hum.HipHeight = mal
	end
	return lager
end

--[[ Startar loopen. Hästarna hämtas ur taggen, alltså samma register
	`HorseService` använder — inte en egen lista som kan glida isär. ]]
function Markkontakt.start()
	local sistaVarv = 0
	RunService.Heartbeat:Connect(function()
		local nu = os.clock()
		if nu - sistaVarv < TAKT then return end
		sistaVarv = nu
		local hastar = CollectionService:GetTagged(TAG)
		--[[ Alla hästar undantas ur strålen: en häst som råkar stå intill
			en annan ska inte mäta hennes rygg som mark. ]]
		local alla: { Instance } = {}
		for _, h in ipairs(hastar) do table.insert(alla, h) end
		for _, h in ipairs(hastar) do
			if h:IsA("Model") then
				pcall(Markkontakt.justera, h, alla)
			end
		end
	end)
	return ("markkontakten igång · takt %.1f s"):format(TAKT)
end

return Markkontakt
