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

--[[ ══ EN PROMPT ÄGER SINA LYSSNARE ═══════════════════════

	Robustness Slice E. Tabellen bar tidigare `true` och ingenting mer:
	fem lyssnare kopplades per prompt och INGEN vag fanns tillbaka. En
	dörr som revs låg kvar som stark modultillstånd resten av sessionen,
	och dess handlare hade ingen ägare som kunde riva dem. Dynamiska
	prompter lät därför tabellen växa hela klientsessionen.

	Nu bär den KOPPLINGARNA. Det är samma sak som hos `TouchControls`
	sedan Slice B, och av samma skäl: en platt lista per ägare räcker,
	och det enda den behöver kunna är «riv allt som hör till den här
	prompten». ]]
local kopplade: { [Instance]: { RBXScriptConnection } } = {}
--[[ Modulens egna kopplingar till varlden. En lista av samma skal som
     ovan: `start()` kors en gang i produktion, men agarskapet ska ga att
     riva pa ETT stalle. ]]
local varldKopplingar: { RBXScriptConnection } = {}
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

--[[ SLÄPP EN PROMPT. Idempotent: en prompt som både rivs och lämnar
     världen når hit två gånger, och andra gången finns ingenting kvar. ]]
local function slapp(inst: Instance)
	local kopplingar = kopplade[inst]
	if not kopplingar then return end
	kopplade[inst] = nil
	--[[ Ekoskyddet hör till en pågående skrivning och får inte bli kvar
	     som ett lås om prompten någonsin kommer tillbaka. ]]
	skriver[inst] = nil
	for _, k in ipairs(kopplingar) do
		pcall(function() k:Disconnect() end)
	end
end

local function koppla(inst: Instance)
	if not inst:IsA("ProximityPrompt") or kopplade[inst] then return end
	local kopplingar: { RBXScriptConnection } = {}
	kopplade[inst] = kopplingar
	local function ager(k: RBXScriptConnection)
		table.insert(kopplingar, k)
	end
	skriv(inst)
	--[[ Dörren byter nyckel mellan Öppna och Stäng. ]]
	ager(inst:GetAttributeChangedSignal("SprakNyckel"):Connect(function() skriv(inst) end))
	ager(inst:GetAttributeChangedSignal("SprakObjekt"):Connect(function() skriv(inst) end))
	ager(inst:GetAttributeChangedSignal("SprakArg"):Connect(function() skriv(inst) end))
	--[[ …OCH om någon skriver över texten igen.

		Servern skriver en svensk standardtext på varje prompt så att den
		går att läsa utan den här modulen. Den skrivningen replikerar, och
		den kan landa EFTER översättningen — det var så tretton dörrar kom
		att säga `Öppna` till en engelsk spelare trots att nyckeln bredvid
		var rätt. Ordningen är rättad i `DorrService`, men den här modulen
		ska inte behöva lita på att varje framtida skrivare gör rätt:
		hävdar någon en annan text hävdar vi översättningen tillbaka. ]]
	ager(inst:GetPropertyChangedSignal("ActionText"):Connect(function() skriv(inst) end))
	ager(inst:GetPropertyChangedSignal("ObjectText"):Connect(function() skriv(inst) end))
	--[[ EN PROMPT KAN RIVAS UTAN ATT LÄMNA VÄRLDEN. `DescendantRemoving`
	     i `start` täcker det ena hållet, `Destroying` det andra — en
	     dörr som förstörs där den står fyrar bara den senare. ]]
	ager(inst.Destroying:Connect(function() slapp(inst) end))
end

--[[ Provkrok: skriver om EN prompt. Låter grinden mäta samma funktion som
	produktionen kallar, i stället för en kopia av regeln. ]]
function Prompttext.skrivOm(prompt: ProximityPrompt)
	skriv(prompt)
end

--[[ Provkrokar: hur många prompter äger modulen just nu, och hur många
     lyssnare håller den på en av dem? Bara läsning. Utan dem går en
     läcka bara att mäta indirekt, genom vad en kvarlevande handlare
     råkar hinna göra. ]]
function Prompttext._kopplade(): number
	local n = 0
	for _ in pairs(kopplade) do n += 1 end
	return n
end

function Prompttext._lyssnare(prompt: Instance): number
	local k = kopplade[prompt]
	return if k then #k else 0
end

--[[ Provkrok: glöm allt. I produktion körs `start()` EN gång per klient;
     i bänken körs den en gång per provblock, och sedan
     `DescendantAdded` blev en riktig signal bär block två med sig block
     ettas kopplingar. Samma skäl som `SparService._glomHookarForProv`. ]]
function Prompttext._glomForProv()
	for inst in pairs(kopplade) do
		slapp(inst)
	end
	kopplade = {}
	skriver = {}
	--[[ OCH MODULENS EGNA VARLDSKOPPLINGAR. Utan dem raknas glomskan
	     inte: `DescendantAdded` fran det forra `start()` ligger kvar och
	     kopplar in varje prompt igen sa fort nagot ror varlden. Forsta
	     versionen missade det och `varldshud` foll pa tva matningar som
	     bada blev tysta i stallet for roda. ]]
	for _, k in ipairs(varldKopplingar) do
		pcall(function() k:Disconnect() end)
	end
	varldKopplingar = {}
end

function Prompttext.start()
	for _, inst in ipairs(workspace:GetDescendants()) do
		koppla(inst)
	end
	table.insert(varldKopplingar, workspace.DescendantAdded:Connect(koppla))
	--[[ …och den andra riktningen. Utan den växer tabellen med varje
	     dörr som byggs och rivs, resten av sessionen. ]]
	table.insert(varldKopplingar, workspace.DescendantRemoving:Connect(slapp))
	--[[ #264: språkflaggan. Varje kopplad prompt skrivs om på plats. ]]
	local frankoppla = Sprak.vidByte(function()
		for inst in pairs(kopplade) do
			if inst:IsA("ProximityPrompt") then skriv(inst) end
		end
	end)
	table.insert(varldKopplingar, { Disconnect = frankoppla } :: any)
end

return Prompttext
