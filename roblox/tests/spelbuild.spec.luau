--!nostrict
--[[
	SPELBYGGET — vad SPELAREN ser. #176.

	Tobias rapporterade fyra gånger att en "grind" stod kvar i ridhuset. Den
	fanns: `Spelabstraktion sargport`, en 2,2 × 1,4 m gul genomskinlig
	neonplatta mitt i sargens öppning, byggd VILLKORSLÖST av
	`Anlaggningen.luau`.

	Ingen grind kunde fånga det, och skälet är obehagligt enkelt: varje spec
	i sviten byggde världen med `UBRF_QA_MARKORER = true`. Alla mätte
	QA-bygget. Ingen mätte produktvägen. Markörerna var alltså osynliga för
	testsviten och fullt synliga för spelaren — precis tvärtom mot vad någon
	trodde.

	Den här specen är den enda som körs med flaggan AV, och den mäter EN sak:
	att review-/debuggeometri inte finns i det spelaren ser, och att den
	riktiga geometrin står kvar.

	Regeln kommer inte härifrån. Den står i `docs/ACTIVE-GATE.md`,
	läktarlärdom 2, bindande sedan PR #114:

	    "Review-/debuggeometri, som de gula genomskinliga
	     trappabstraktionerna, ska vara dev/debug-only och aldrig synlig i
	     produktvyn."

	Kör: python3 roblox/tests/build.py tests/spelbuild.spec.luau
	     && luau roblox/tests/.build/spelbuild.spec.luau
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

local anlaggning = workspace:FindFirstChild("Anläggning")
local ubrf = anlaggning and anlaggning:FindFirstChild("UBRF")

local delar = {}
if ubrf then
	for _, d in ipairs(ubrf:GetDescendants()) do table.insert(delar, d) end
end

local function raknaExakt(namn)
	local n = 0
	for _, d in ipairs(delar) do if d.Name == namn then n += 1 end end
	return n
end

local function raknaPrefix(prefix)
	local n = 0
	for _, d in ipairs(delar) do
		if d.Name:sub(1, #prefix) == prefix then n += 1 end
	end
	return n
end

print("\n── Världen byggdes ──")

check("anläggningen finns", ubrf ~= nil)
check("och den är inte tom", #delar > 1000, ("%d delar"):format(#delar))

print("\n── Ingen QA-/reviewgeometri i spelarens vy ──")

do
	--[[ DE TRE MARKÖRERNA. Etiketter, inte geometri: gula, genomskinliga,
		okolliderande. Var och en ska vara borta när flaggan är av. ]]
	for _, namn in ipairs({ "Spelabstraktion sargport",
			"Spelabstraktion laktarsteg", "Spelabstraktion bankradsteg" }) do
		check(("ingen markör «%s»"):format(namn), raknaExakt(namn) == 0,
			("%d st"):format(raknaExakt(namn)))
	end

	--[[ Dörrmarkörerna var redan gatade sedan #162. Raden finns för att en
		framtida ändring inte ska kunna öppna det hålet igen. ]]
	check("inga gula dörrmarkörer", raknaPrefix("Dörr ") == 0,
		("%d st"):format(raknaPrefix("Dörr ")))

	--[[ SVEPET. Att räkna tre kända namn skyddar bara mot de tre. Den här
		raden fäller varje NY gul neonplatta någon lägger till i framtiden —
		det är skillnaden mellan att laga det här felet och att laga
		felklassen. ]]
	local gula = {}
	for _, d in ipairs(delar) do
		if d:IsA("BasePart") and d.Transparency > 0.2 and not d.CanCollide
			and d.Material == Enum.Material.Neon then
			table.insert(gula, d.Name)
		end
	end
	check("ingen genomskinlig okolliderande neonplatta alls", #gula == 0,
		if #gula == 0 then "-" else table.concat(gula, ", "))
end

print("\n── Den riktiga geometrin står kvar ──")

do
	--[[ Läktaren är PRODUCT_ACCEPTED (#81/PR #114) och kräver en gångbar
		trappa. Stegen är solida träplankor och får ALDRIG gatas bort — den
		här raden är skyddet mot att någon "städar" bort dem med markören. ]]
	check("läktarstegen finns kvar",
		raknaPrefix("Spelabstraktion laktarsteg steg ") >= 3,
		("%d steg"):format(raknaPrefix("Spelabstraktion laktarsteg steg ")))
	check("bänkradsstegen finns kvar",
		raknaPrefix("Spelabstraktion bankradsteg steg ") >= 1,
		("%d steg"):format(raknaPrefix("Spelabstraktion bankradsteg steg ")))

	--[[ Sargporten är ett GAP i sargen, inte en platta. Att markören är
		borta får inte betyda att öppningen murades igen: båda halvorna av
		norra sargen ska finnas, och ingen hel «Sarg norr». ]]
	check("norra sargens västra halva finns", raknaExakt("Sarg norr väst") == 1)
	check("norra sargens östra halva finns", raknaExakt("Sarg norr öst") == 1)
	check("och norra sargen är INTE hel — gapet är kvar",
		raknaExakt("Sarg norr") == 0)

	--[[ Att stegen fortfarande kolliderar. En markör som blivit ett steg,
		eller ett steg som tappat sin kollision, är samma fel i olika form. ]]
	local solida = 0
	for _, d in ipairs(delar) do
		if d.Name:sub(1, 31) == "Spelabstraktion laktarsteg steg" and d:IsA("BasePart")
			and d.CanCollide and d.Transparency < 0.2 then
			solida += 1
		end
	end
	check("läktarstegen är solida och går att kliva på", solida >= 3,
		("%d solida steg"):format(solida))
end

if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("\nspelbuild.spec: alla gröna")
end
