--!strict
--[[
	Nätverkslagret.

	Ett ställe som skapar och hittar fjärrobjekten, så att varken servern
	eller klienten letar i ReplicatedStorage på egen hand. Servern skapar
	dem; klienten väntar in dem.

	Regeln för vad som får skickas: klienten skickar *avsikt* och sin egen
	simulerade position. Servern skickar *sanning* om ägarskap, uppsittning
	och uthållighet. Klienten får aldrig sätta ett värde som andra spelare
	påverkas av.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Networking = {}

local FOLDER_NAME = "HorseRemotes"

local DEFINITIONS = {
	MountRequest = "RemoteFunction",    -- klient → server: får jag sitta upp?
	DismountRequest = "RemoteFunction",
	MountChanged = "RemoteEvent",       -- server → alla: vem rider vad
	StateSync = "RemoteEvent",          -- klient → server: tempo och gångart
	StaminaSync = "RemoteEvent",        -- server → ägaren: uthållighet
	HorseReaction = "RemoteEvent",      -- server → alla: gnägg, stegring, reaktion
	PreparationStep = "RemoteFunction",  -- klient → server: jag vill göra det här steget
	PreparationSync = "RemoteEvent",     -- server → ägaren: hela förberedelsens sanning
	PreparationHello = "RemoteFunction", -- klient → server: listenern är ansluten, ge mig nuläget
	--[[ #161. Skötselns MOMENT och passets eftervård.

	     Alla tre är avsikter — "jag vill krafsa vänster fram", "jag säger
	     till ridläraren", "jag lossar gjorden" — och inget av dem bär ett
	     resultat. Det finns med flit ingen remote som tar emot ett
	     saveobjekt, ett passtal eller ett hästminne: servern äger varje
	     skrivning, och en klient som inte KAN skicka ett tillstånd kan
	     heller inte fejka ett. ]]
	PreparationMoment = "RemoteFunction",  -- klient → server: jag utför det här momentet
	PreparationSvar = "RemoteFunction",    -- klient → server: mitt svar på ett fynd
	PassSync = "RemoteEvent",              -- server → ägaren: passets läge och eftervård
	PassMoment = "RemoteFunction",         -- klient → server: ett eftervårdsmoment
	LedBorja = "RemoteFunction",           -- klient → server: jag börjar leda den här hästen
	LedSlapp = "RemoteFunction",           -- klient → server: jag släpper
	LedSync = "RemoteEvent",               -- server → ägaren: leder jag, och hur långt har hon kommit
	--[[ RIDE FIRST: "Rida nu". Klienten skickar en avsikt; servern gör
	     stallets förberedelse och svarar med hela sanningen. ]]
	RidaNu = "RemoteFunction",             -- klient → server: låt stallet göra i ordning henne
	--[[ #235 FAS 2: SADEL `HELD -> EQUIPPED`. Klienten pekar ut vilken
		 häst hon står vid; servern äger allt annat — att hon verkligen bär
		 sadeln, att den är RÄTT hästs, avståndet, ordningen och själva
		 bygget. Modellen i argumentet är alltså en FRÅGA, inte ett
		 påstående. ]]
	SadlaHast = "RemoteFunction",          -- klient → server: lägg sadeln jag bär på den här hästen
}

local cache: { [string]: Instance } = {}

local function folder(): Folder
	local existing = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if existing then
		return existing :: Folder
	end
	if RunService:IsServer() then
		local f = Instance.new("Folder")
		f.Name = FOLDER_NAME
		f.Parent = ReplicatedStorage
		return f
	end
	return ReplicatedStorage:WaitForChild(FOLDER_NAME, 30) :: Folder
end

function Networking.get(name: string): any
	if cache[name] then
		return cache[name]
	end
	local class = DEFINITIONS[name]
	assert(class, ("[Horse] Okänt fjärrobjekt %q"):format(name))

	local parent = folder()
	local existing = parent:FindFirstChild(name)
	if not existing and RunService:IsServer() then
		existing = Instance.new(class)
		existing.Name = name
		existing.Parent = parent
	elseif not existing then
		existing = parent:WaitForChild(name, 30)
	end
	cache[name] = existing :: Instance
	return existing
end

--[[ Facit över vilka fjärrobjekt som SKA finnas, utlämnat för
     `Integritet.luau` (#171).

     Kopian är avsiktlig: integritetsgrinden ska kunna läsa listan utan att
     kunna ändra den. Och den ska läsa DEN HÄR listan — inte en egen kopia.
     En andra namnlista hade blivit en andra sanning, och då mäter grinden
     till slut sig själv i stället för koden.

     Varför det behövs: `folder()` och `get()` återanvänder det som redan
     ligger i ReplicatedStorage. Det är rätt i drift, men det betyder att ett
     borttaget eller omdöpt fjärrobjekt ligger kvar osynligt i en sparad
     place. Utan facit går den skillnaden inte att mäta. ]]
function Networking.definitioner(): { [string]: string }
	local kopia: { [string]: string } = {}
	for namn, klass in DEFINITIONS do
		kopia[namn] = klass
	end
	return kopia
end

--[[ Servern kallar den här en gång vid start så att allt finns innan
     första klienten frågar efter det. ]]
function Networking.init()
	assert(RunService:IsServer(), "Networking.init körs bara på servern")
	for name in DEFINITIONS do
		Networking.get(name)
	end
end

return Networking
