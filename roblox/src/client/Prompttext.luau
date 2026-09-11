--!strict
--[[
	PROMPTTEXTEN — världens prompter i spelarens språk.

	En `ProximityPrompt` står i världen och replikeras till ALLA spelare;
	servern kan därför inte skriva dess text på en enskild spelares språk.
	Roblox egen väg är den här: servern sätter en NYCKEL på prompten,
	klienten skriver texten. Det är också därför den svenska texten ligger
	kvar som prompten skapas med — en klient utan den här modulen visar
	svenska i stället för ingenting.

	Nycklarna:
	  · `SprakNyckel`  — handlingen ("dorr.oppna", "stall.titta_in")
	  · `SprakObjekt`  — objektet ("dorr.objekt", "stall.star_har")
	  · `SprakArg`     — EN inskjuten sträng, t.ex. hästens namn. Den
	    översätts aldrig: ett egennamn är ett egennamn på alla språk.

	Dörren byter nyckel när den öppnas och stängs, så modulen lyssnar på
	attributändringen och inte bara på när prompten skapas.
]]

local Sprak = require(game:GetService("ReplicatedStorage").HorseCore.Sprak)

local Prompttext = {}

local kopplade: { [Instance]: boolean } = {}
--[[ Skrivskydd mot ekot: `skriv` sätter `ActionText`, vilket väcker
	lyssnaren nedan, som kallar `skriv` igen. Roblox fyrar inte signalen när
	värdet är oförändrat, så det skulle stanna av sig självt — men en gång
	för mycket per prompt och bildruta är en gång för mycket. ]]
local skriver: { [Instance]: boolean } = {}

local function skriv(prompt: ProximityPrompt)
	if skriver[prompt] then return end
	skriver[prompt] = true
	local handling = prompt:GetAttribute("SprakNyckel")
	local objekt = prompt:GetAttribute("SprakObjekt")
	local arg = prompt:GetAttribute("SprakArg")
	if typeof(handling) == "string" and handling ~= "" then
		prompt.ActionText = Sprak.t(handling)
	end
	if typeof(objekt) == "string" and objekt ~= "" then
		--[[ `SprakArg` är valfritt. En nyckel med platshållare och inget
			argument skulle annars skriva ut "%s" i klartext för spelaren. ]]
		if typeof(arg) == "string" and arg ~= "" then
			prompt.ObjectText = Sprak.t(objekt, arg)
		elseif not string.find(Sprak.iSprak("sv", objekt), "%%") then
			prompt.ObjectText = Sprak.t(objekt)
		end
	end
	skriver[prompt] = nil
end

local function koppla(inst: Instance)
	if not inst:IsA("ProximityPrompt") or kopplade[inst] then return end
	kopplade[inst] = true
	skriv(inst)
	--[[ Dörren byter nyckel mellan Öppna och Stäng. ]]
	inst:GetAttributeChangedSignal("SprakNyckel"):Connect(function() skriv(inst) end)
	inst:GetAttributeChangedSignal("SprakObjekt"):Connect(function() skriv(inst) end)
	inst:GetAttributeChangedSignal("SprakArg"):Connect(function() skriv(inst) end)
	--[[ …OCH om någon skriver över texten igen.

		Servern skriver en svensk standardtext på varje prompt så att den
		går att läsa utan den här modulen. Den skrivningen replikerar, och
		den kan landa EFTER översättningen — det var så tretton dörrar kom
		att säga `Öppna` till en engelsk spelare trots att nyckeln bredvid
		var rätt. Ordningen är rättad i `DorrService`, men den här modulen
		ska inte behöva lita på att varje framtida skrivare gör rätt:
		hävdar någon en annan text hävdar vi översättningen tillbaka. ]]
	inst:GetPropertyChangedSignal("ActionText"):Connect(function() skriv(inst) end)
	inst:GetPropertyChangedSignal("ObjectText"):Connect(function() skriv(inst) end)
end

--[[ Provkrok: skriver om EN prompt. Låter grinden mäta samma funktion som
	produktionen kallar, i stället för en kopia av regeln. ]]
function Prompttext.skrivOm(prompt: ProximityPrompt)
	skriv(prompt)
end

function Prompttext.start()
	for _, inst in ipairs(workspace:GetDescendants()) do
		koppla(inst)
	end
	workspace.DescendantAdded:Connect(koppla)
end

return Prompttext
