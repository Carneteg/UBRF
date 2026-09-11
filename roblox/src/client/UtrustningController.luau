--!strict
--[[
	ATT HÄMTA SADELN OCH TRÄNSET.

	En ProximityPrompt per sak, skapad på klienten precis som
	uppsittningsprompten — servern slipper replikera dem, och texten kan
	skrivas på spelarens eget språk direkt.

	Prompten visas BARA på din egen hästs utrustning. Trettiotre boxar gånger
	två saker är sextiosex prompter i samma gång, och en spelare som ser dem
	alla lär sig ingenting om vilken som är hennes. Servern avvisar ändå fel
	hästs sak (`utr.fel_hast`) — det här är läsbarhet, inte säkerhet.

	Klienten bestämmer aldrig att hon bär något. Prompten skickar en AVSIKT
	("jag vill ta den där saken") och servern räknar ut rätt häst, avståndet
	och tillståndet.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Core = require(ReplicatedStorage.HorseCore)
local Net = Core.Networking
local Sprak = require(ReplicatedStorage.HorseCore.Sprak)

local UtrustningController = {}

local TAG = "Utrustning"

local prompts: { [Model]: ProximityPrompt } = {}
local minHast: (() -> string?)? = nil
local vidHamtad: (() -> ())? = nil

--[[ Beslutet utan instanser, så att det går att fälla i en spec. En sak
	visas när den hör till MIN häst och ingen redan bär den. ]]
function UtrustningController.promptSynlig(tillhor: any, minId: string?,
	bars: any): boolean
	if typeof(minId) ~= "string" or minId == "" then return false end
	if typeof(tillhor) ~= "string" then return false end
	if bars == true then return false end
	return tillhor == minId
end

local function farVisas(modell: Model): boolean
	local minId = if minHast then minHast() else nil
	return UtrustningController.promptSynlig(
		modell:GetAttribute("HastId"), minId, modell:GetAttribute("Bars"))
end

local function taBort(modell: Model)
	local p = prompts[modell]
	if p then
		p:Destroy()
		prompts[modell] = nil
	end
end

local function lagg(modell: Model)
	if prompts[modell] then return end
	if not farVisas(modell) then return end
	local fast = modell.PrimaryPart or modell:FindFirstChildWhichIsA("BasePart")
	if not fast then return end

	local sort = modell:GetAttribute("UtrSort")
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "UtrustningPrompt"
	prompt.ActionText = Sprak.t("utr.ta")
	prompt.ObjectText = Sprak.t(if sort == "sadel" then "utr.sadel" else "utr.trans")
	prompt.HoldDuration = 0.25
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = fast

	prompt.Triggered:Connect(function()
		local ok, skal = Net.get("HamtaUtrustning"):InvokeServer(modell)
		if ok then
			--[[ Saken sitter nu på avataren; prompten ska bort direkt och
				inte först vid nästa sync. ]]
			taBort(modell)
			if vidHamtad then vidHamtad() end
		else
			warn(("[Utrustning] Kunde inte hämta: %s (%s)"):format(
				Sprak.t(tostring(skal)), tostring(skal)))
		end
	end)

	prompts[modell] = prompt
end

--[[ Räkna om vilka prompter som får finnas. Anropas när servern skickat ny
	sanning: hästen tilldelas EFTER att modellerna redan står i världen, så
	utan det här får spelaren aldrig sin prompt. ]]
function UtrustningController.uppdatera()
	for _, m in CollectionService:GetTagged(TAG) do
		if m:IsA("Model") then
			if farVisas(m) then lagg(m) else taBort(m) end
		end
	end
end

function UtrustningController.start(hastIdFn: () -> string?, efterHamtning: (() -> ())?)
	minHast = hastIdFn
	vidHamtad = efterHamtning
	UtrustningController.uppdatera()
	CollectionService:GetInstanceAddedSignal(TAG):Connect(function(inst)
		if inst:IsA("Model") then lagg(inst) end
	end)
	CollectionService:GetInstanceRemovedSignal(TAG):Connect(function(inst)
		if inst:IsA("Model") then taBort(inst :: Model) end
	end)
end

function UtrustningController.setEnabled(enabled: boolean)
	for _, prompt in prompts do
		prompt.Enabled = enabled
	end
end

return UtrustningController
