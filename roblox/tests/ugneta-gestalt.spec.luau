--[[ UGNETA SOM GESTALT — står hon där, och står hon rätt?

	Blocker 2 i senior review av 09e07da: webben hade fått en igenkännbar
	Ugneta men Roblox bara lärar-UX:en, och Roblox är primär spelplattform.

	Provet körs ovanpå den FÄRDIGBYGGDA anläggningen. Det är hela poängen:
	placeringen räknas ut genom att mäta mellan "Ridbanan" och "Sarg syd",
	alltså mot delar som faktiskt står i workspace. Ett prov mot
	handskrivna koordinater hade mött en andra modell av huset — och två
	uppfattningar om var något står är läktarfelet (#114). ]]

local fel = 0
local function prova(vad, ok, detalj)
	if ok then
		print(("  OK   %s"):format(vad))
	else
		fel += 1
		print(("  FEL  %s — %s"):format(vad, tostring(detalj)))
	end
end

print("\nUGNETA VID SARGEN — GESTALTEN\n")

local anlaggning = workspace:FindFirstChild("Anläggning")
local hus = anlaggning and anlaggning:FindFirstChild("UBRF")
prova("anläggningen är byggd och heter UBRF", hus ~= nil, tostring(hus))

local bana = hus and hus:FindFirstChild("Ridbanan")
local syd = hus and hus:FindFirstChild("Sarg syd")
prova("banan och A-ändens sarg finns att mäta emot",
	bana ~= nil and syd ~= nil,
	("Ridbanan %s · Sarg syd %s"):format(tostring(bana), tostring(syd)))

--[[ INGEN GESTALT INNAN LEKTIONEN. Hon ska inte stå i ridhuset dygnet
	runt; hon hör till lektionen. ]]
prova("hon står inte där innan lektionen börjat", not UgnetaGestalt.finns(),
	tostring(UgnetaGestalt.finns()))

local m = UgnetaGestalt.visa(hus)
prova("hon byggs när lektionen börjar", m ~= nil and UgnetaGestalt.finns(),
	tostring(m))

--[[ IGENKÄNNBAR: grått hår och glasögon är hela skillnaden mot en anonym
	figur i kavaj. Det var precis det blockern gällde. ]]
local har = m and m:FindFirstChild("Grått hår")
local glas = m and m:FindFirstChild("Glasögon")
local ansikte = m and m:FindFirstChild("Ansikte")
prova("hon har grått hår", har ~= nil, tostring(har))
prova("hon har glasögon", glas ~= nil, tostring(glas))
prova("hon har ett ansikte att bära dem på", ansikte ~= nil, tostring(ansikte))

local GRA = Color3.fromRGB(201, 205, 210)
prova("håret är faktiskt grått, inte kavajens färg",
	har ~= nil and math.abs(har.Color.R - GRA.R) < 0.01
		and math.abs(har.Color.G - GRA.G) < 0.01,
	har and ("%.2f/%.2f/%.2f"):format(har.Color.R, har.Color.G, har.Color.B) or "-")

--[[ HON FÅR ALDRIG STOPPA EN HÄST. En instruktör som är ett hinder mitt i
	ridhuset är sämre än ingen instruktör alls. ]]
local kolliderar = false
for _, d in (m and m:GetChildren() or {}) do
	if d.CanCollide then kolliderar = true end
end
prova("ingen del av henne kolliderar", not kolliderar, tostring(kolliderar))

--[[ PLACERINGEN. Hon ska stå bortom dressyrlayoutens C-linje, alltså i
	den zon där den fysiska ridytan fortsätter — inte på dressyrbanan och
	inte utanför huset. Avståndet mäts från A-sargen, samma punkt koden
	själv utgår från. ]]
local M = 3
local P = RidKanon.UGNETA.PLATS
local plats = UgnetaGestalt.plats(hus)
prova("placeringen går att räkna fram ur det byggda", plats ~= nil, tostring(plats))
if plats and syd and bana then
	local fran = plats.pos - syd.Position
	local langs = fran.X * plats.motC.X + fran.Y * plats.motC.Y + fran.Z * plats.motC.Z
	local vantat = (P.langd + P.bortomC) * M
	prova("hon står bortom C-linjen, på det avstånd kanonen anger",
		math.abs(langs - vantat) < 0.2,
		("%.2f studs från A, väntat %.2f"):format(langs, vantat))

	--[[ …och innanför sargen i andra änden. Banans längd läses ur den
	     byggda delen, inte ur en siffra skriven här. ]]
	local banlangd = math.max(bana.Size.X, bana.Size.Z)
	prova("hon står innanför banans norra sarg, inte i väggen",
		langs < banlangd,
		("%.2f studs från A · banan %.2f studs lång"):format(langs, banlangd))

	prova("hon står på golvet, inte i det",
		math.abs(plats.pos.Y - (bana.Position.Y + bana.Size.Y / 2)) < 0.01,
		("y %.2f mot sandens överkant %.2f"):format(plats.pos.Y,
			bana.Position.Y + bana.Size.Y / 2))
end

--[[ Hon ska bort när lektionen slutar. ]]
UgnetaGestalt.dolj()
prova("hon försvinner när lektionen avbryts", not UgnetaGestalt.finns(),
	tostring(UgnetaGestalt.finns()))

--[[ UTAN BYGGNAD, INGEN GISSNING. Saknas huset ska hon inte hamna på
	(0,0,0) — en figur på en påhittad plats är värre än ingen figur. ]]
prova("utan byggd bana placeras hon inte alls",
	UgnetaGestalt.plats(nil) == nil and UgnetaGestalt.visa(nil) == nil,
	"nil in gav nil ut")

if fel > 0 then
	print(("\n%d mätningar föll."):format(fel))
else
	print("\nAlla mätningar gick igenom.")
end
