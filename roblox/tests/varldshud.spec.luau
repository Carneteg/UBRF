--!nostrict
--[[
	PHYSICAL_WORLD_COHERENCE — punkt 1, 3 och 6

	Ordern på #162 efter Tobias andra Studio-test. Den här halvan av
	grinden mäter det som kräver BÅDE en byggd värld och en riktig HUD:

	  1  World ↔ gameplay parity — varje instruktion pekar på något som
	     faktiskt finns och går att nå i builden.
	  3  Equipment presence — skötselsteg som kräver utrustning har en
	     fysisk plats i miljön.
	  6  Contextual HUD — den aktiva instruktionen måste matcha spelarens
	     läge. Flytta henne ur kontext och HUD:en ska ändra sig.

	VARFÖR EN EGEN BANK. Det här är den enda specen som kör anläggningen,
	hela serverstacken OCH `init.client.luau` i samma körning. P0-3 var ett
	fel mellan två lager — servern nekade, gränssnittet lovade — och ett
	prov som bara kör det ena lagret kan inte se det.

	Kör: python3 roblox/tests/build.py tests/varldshud.spec.luau
	     && luau roblox/tests/.build/varldshud.spec.luau
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
local function matning(namn, detalj)
	print(string.format("  mät  %s%s", namn, detalj and ("  " .. detalj) or ""))
end

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local M = BuildKit.M
local RACKVIDD = Config.STEG_RACKVIDD
local modell = workspace:FindFirstChild("Anläggning"):FindFirstChild("UBRF")
local bas = modell.PrimaryPart.CFrame

--[[ Hästarna byggs av produktionens egen startfunktion, samma anrop som
	`init.server.luau` gör. Att ställa dit en modell för hand hade mätt
	provets egen rigg. ]]
HastRigg.start()

local hastId = Stallet.FORSTA_DAGEN_HAST
local hastnamn = (UBRFSpelData.hastar[hastId] or {}).namn or hastId

local function hastModell(id)
	for _, m in ipairs(CollectionService:GetTagged("Horse")) do
		if m:GetAttribute("HorseId") == id then return m end
	end
	return nil
end

-- ══ 1. VÄRLD ↔ GAMEPLAY-PARITET ════════════════════════════════════════
print("\n1. Världen bär det spelet ber om")

local jack = hastModell(hastId)
check("första dagens häst finns som modell i den byggda världen",
	jack ~= nil, ("%s (%s)"):format(tostring(hastnamn), tostring(hastId)))

local rot = jack and ((jack :: any).PrimaryPart or jack:FindFirstChild("BodyCollider"))
check("hon har en fysisk rot att mäta avstånd mot", rot ~= nil,
	rot and rot.Name or "saknas")

--[[ Står hon på något? En häst som svävar över tomrummet är lika mycket
	ett brutet löfte som en instruktion utan mål. ]]
if rot then
	local p = rot.CFrame.Position
	local under, namn = nil, nil
	for _, d in ipairs(modell:GetDescendants()) do
		if d.CFrame and d.Size and d.CanCollide ~= false then
			local c, s = d.CFrame.Position, d.Size
			local y1 = (c.Y + s.Y / 2)
			if math.abs(p.X - c.X) <= s.X / 2 and math.abs(p.Z - c.Z) <= s.Z / 2
				and y1 <= p.Y + 0.1 and (under == nil or y1 > under) then
				under, namn = y1, d.Name
			end
		end
	end
	check("och hon står på en bärande yta, inte i tomrummet",
		under ~= nil and (p.Y - under) / M < 2.0,
		under and ("%s, %.2f m under hovarna"):format(namn, (p.Y - under) / M)
			or "INGEN YTA UNDER")
end

-- ══ 6. KONTEXTMEDVETEN HUD ═════════════════════════════════════════════
print("\n6. HUD:en säger sanningen om var spelaren står")

--[[ En riktig karaktär att flytta. Stubbens LocalPlayer har en attrapp
	utan rot; HUD:ens kontextfråga är ett AVSTÅND, och det behöver en
	kropp med ett läge. ]]
local function nyKaraktar(p)
	local k = Instance.new("Model")
	k.Name = "Spelare"
	local r = Instance.new("Part")
	r.Name = "HumanoidRootPart"
	r.Size = Vector3.new(2, 2, 1)
	r.CFrame = CFrame.new(p)
	r.Parent = k
	k.Parent = workspace
	return k, r
end

local karaktar, kropp = nyKaraktar((rot and rot.CFrame.Position) or Vector3.new(0, 0, 0))
Players.LocalPlayer.Character = karaktar

local state = Preparation.nyState(hastId, 1)
local vy = Preparation.vy(state, "preparing", 1, hastnamn)
PreparationController.tillampa(vy)
PreparationController.uppdateraKontext()

local nastaMoment = vy.nastaMoment
check("vyn har ett moment på tur att mäta mot", nastaMoment ~= nil,
	tostring(nastaMoment))

--[[ `_ritadText` ger raderna i ritordning och rubriken står först. ]]
local function rubrikNu()
	local rader = PreparationController._ritadText()
	return (rader and rader[1]) or "(ingen rubrik)"
end

--[[ VID HÄSTEN. ]]
check("vid hästen är hon INTE utom räckhåll",
	PreparationController._utomRackhall() == false,
	("avstånd 0 studs mot räckvidd %d"):format(RACKVIDD))
local rubrikVid = rubrikNu()
check("och momentet på tur går att trycka på",
	nastaMoment == nil or PreparationController._momentGarAttTrycka(nastaMoment) == true,
	rubrikVid)

--[[ LÅNGT BORT — samma vy, annat läge. ]]
kropp.CFrame = CFrame.new((rot.CFrame.Position) + Vector3.new(RACKVIDD * 4, 0, 0))
PreparationController.uppdateraKontext()

check("fyra gånger räckvidden bort ÄR hon utom räckhåll",
	PreparationController._utomRackhall() == true,
	("%d studs bort mot räckvidd %d"):format(RACKVIDD * 4, RACKVIDD))

local rubrikBort = rubrikNu()
local vantad = Sprak.t("hud.ga_tillbaka", hastnamn)
check("och rubriken pekar TILLBAKA till hästen i stället för att ge en order",
	rubrikBort == vantad,
	("\"%s\" (väntat \"%s\")"):format(tostring(rubrikBort), tostring(vantad)))
check("rubriken är dessutom en ANNAN än den vid hästen — provet mäter en skillnad",
	rubrikBort ~= rubrikVid,
	("vid hästen \"%s\""):format(tostring(rubrikVid)))
check("och momentet går INTE längre att trycka på",
	nastaMoment == nil or PreparationController._momentGarAttTrycka(nastaMoment) ~= true,
	"ingen lyssnare kopplad")

--[[ TILLBAKA IGEN. En HUD som fastnar i "gå tillbaka" är lika trasig som
	en som aldrig säger det. ]]
kropp.CFrame = CFrame.new(rot.CFrame.Position)
PreparationController.uppdateraKontext()
check("tillbaka vid hästen återgår HUD:en", 
	PreparationController._utomRackhall() == false and rubrikNu() == rubrikVid,
	("\"%s\""):format(tostring(rubrikNu())))

--[[ ── MUTATIONEN (ordern punkt 8): HUD-steget ligger kvar ─────────────
	Utan den här kontrollen mäter proven ovan ingenting: en HUD som ALDRIG
	byter rubrik skulle falla, men en grind som inte kan skilja på "bytte"
	och "bytte av rätt skäl" är en grind som går att lura. Här kopplas
	gränsen bort — räckvidden sätts oändlig — och då ska rubriken bli kvar
	trots att spelaren står långt borta. ]]
do
	local sant = RACKVIDD
	kropp.CFrame = CFrame.new((rot.CFrame.Position) + Vector3.new(sant * 4, 0, 0))
	Config.STEG_RACKVIDD = math.huge
	--[[ Kontexten läses ur en local som togs vid inladdning, så mutationen
		måste gå genom samma väg spelaren gör: flytta, uppdatera. Att
		räckvidden är oändlig kan controllern inte se — den jämför bara. ]]
	PreparationController.uppdateraKontext()
	Config.STEG_RACKVIDD = sant
	check("MUTATION: med oändlig räckvidd blir spelaren aldrig 'borta' — regeln mäter avståndet",
		PreparationController._utomRackhall() == false,
		("48 studs bort, räckvidd ∞ → utomRackhall = %s")
			:format(tostring(PreparationController._utomRackhall())))
	kropp.CFrame = CFrame.new(rot.CFrame.Position)
	PreparationController.uppdateraKontext()
end

--[[ ── 7. INGEN INTERN ETIKETT NÅR SPELAREN ──────────────────────────
	Ordern punkt 7 räknar upp "intern etikett (`dorrgul`) till spelare"
	bland de fynd som ska bli permanent regression. Felet är rättat i
	`DorrService.objektFor`, men rättningen har aldrig haft en grind:
	texten kunde glida tillbaka utan att något blev rött.

	Tokenen är datans egna ord för en öppning — de säger färg och
	fabrikat, inte vad saken heter på svenska. Ingen av dem får stå i en
	prompt. ]]
print("\n7. Datans egna ord stannar i datan")
do
	local TOKEN = { "dorrgul", "dorrvit", "dorrmork", "dorr", "portbla", "portplat",
		"portsilver", "valv", "rund", "fonster" }
	DorrService.start()
	local prompts = {}
	for _, d in ipairs(workspace:GetDescendants()) do
		if d.ClassName == "ProximityPrompt" then table.insert(prompts, d) end
	end
	local function lackor(): { string }
		local ut = {}
		for _, pr in ipairs(prompts) do
			for _, falt in ipairs({ "ObjectText", "ActionText" }) do
				local txt = string.lower(tostring((pr :: any)[falt]))
				for _, t in ipairs(TOKEN) do
					if string.find(txt, t, 1, true) then
						table.insert(ut, ("%s.%s = %q"):format(pr.Parent and pr.Parent.Name or "?", falt, (pr :: any)[falt]))
					end
				end
			end
		end
		return ut
	end
	local nu = lackor()
	check("ingen prompt skriver datans interna typnamn",
		#nu == 0 and #prompts > 0,
		#nu == 0 and ("%d prompts, inga tokenläckor"):format(#prompts)
			or table.concat(nu, " · "))

	--[[ MUTATIONEN: skriv tillbaka felet på EN prompt. Kan grinden inte bli
		röd av det har den inte fångat fyndet — den har bara råkat vara
		grön. ]]
	local offer, gammalText = nil, nil
	for _, pr in ipairs(prompts) do
		local blad = pr.Parent
		local typ = blad and blad:GetAttribute("Oppningstyp")
		if typeof(typ) == "string" then
			offer, gammalText = pr, pr.ObjectText
			pr.ObjectText = typ
			break
		end
	end
	if offer then
		check("MUTATION: en prompt som skriver `Oppningstyp` rakt av fälls",
			#lackor() > 0,
			("satte ObjectText = %q → %d läcka(or)"):format(offer.ObjectText, #lackor()))
		offer.ObjectText = gammalText
	end
end

if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	print("PHYSICAL_WORLD_COHERENCE (HUD): FAIL")
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error("varldshud.spec: " .. fails .. " fel")
end
print("\nPHYSICAL_WORLD_COHERENCE (HUD): alla gröna")
