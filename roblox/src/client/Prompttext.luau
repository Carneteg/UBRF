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

local function skriv(prompt: ProximityPrompt)
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
end

local function koppla(inst: Instance)
	if not inst:IsA("ProximityPrompt") or kopplade[inst] then return end
	kopplade[inst] = true
	skriv(inst)
	--[[ Dörren byter nyckel mellan Öppna och Stäng. ]]
	inst:GetAttributeChangedSignal("SprakNyckel"):Connect(function() skriv(inst) end)
	inst:GetAttributeChangedSignal("SprakObjekt"):Connect(function() skriv(inst) end)
	inst:GetAttributeChangedSignal("SprakArg"):Connect(function() skriv(inst) end)
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
