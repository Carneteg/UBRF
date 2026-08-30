--!nostrict
--[[
	GameplayService — falsifiering av G01.1:s serverregler.

	preparation.spec provar den rena regelmodulen. Det här provar TJÄNSTEN:
	tilldelning, ägarskap, avstånd och uppsittningsspärr. Det är där en
	spelare skulle kunna få två hästar, ta någon annans häst, eller sitta upp
	på en oförberedd häst — och ingenting av det gick att köra förut.

	HorseService är en attrapp som säger JA till allt. Med flit: då är det
	bara G01-spärren som kan stoppa en uppsittning, och ett grönt prov bevisar
	att spärren finns i stället för att HorseService råkade neka.

	Kör: python3 roblox/tests/build.py tests/gameplay.spec.luau
	     && luau roblox/tests/.build/gameplay.spec.luau
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

local function hast(namn, x)
	local m = __instans("Model", namn)
	m.Parent = { Name = "Workspace" }
	m.Position = Vector3.new(x or 0, 0, 0)
	m:SetAttribute("HorseName", namn)
	return m
end

local function stall(player, x)
	player._root.Position = Vector3.new(x, 0, 0)
end

local function forbered(player, model, steg)
	for _, action in ipairs(steg) do
		__anropa("G01Action", player, action, model)
	end
end

GameplayService.start(__HorseServiceStub)

print("\n── 1 & 2: ägarskapet är exklusivt åt båda håll ──")
local h1, h2 = hast("Alfa", 0), hast("Beta", 0)
__taggaHast(h1)
__taggaHast(h2)

local a = __spelare("Anna", 101)
local b = __spelare("Bo", 102)
__ansluter(a)
__ansluter(b)
__korDeferrade()

local sa = __anropa("G01GetState", a)
local sb = __anropa("G01GetState", b)
check("båda spelarna fick var sin häst",
	sa.horse ~= nil and sb.horse ~= nil, tostring(sa.horseName) .. " / " .. tostring(sb.horseName))
check("två spelare fick ALDRIG samma häst", sa.horse ~= sb.horse,
	tostring(sa.horseName) .. " mot " .. tostring(sb.horseName))
check("hästens AssignedUserId pekar på rätt spelare",
	sa.horse:GetAttribute("AssignedUserId") == a.UserId
		and sb.horse:GetAttribute("AssignedUserId") == b.UserId)

--[[ En tredje spelare utan ledig häst ska VÄNTA, inte få någon annans. ]]
local c = __spelare("Cilla", 103)
__ansluter(c)
__korDeferrade()
local sc = __anropa("G01GetState", c)
check("spelare utan ledig häst hamnar i vänteläge",
	sc.horse == nil and sc.phase == "waiting_horse", sc.phase)
check("väntande spelare stal ingen tilldelad häst",
	h1:GetAttribute("AssignedUserId") ~= c.UserId
		and h2:GetAttribute("AssignedUserId") ~= c.UserId)

--[[ Att fråga om igen får inte dela ut en andra häst. ]]
local forsta = sa.horse
for _ = 1, 5 do __anropa("G01GetState", a) end
__korDeferrade()
check("upprepade förfrågningar ger inte en andra häst",
	__anropa("G01GetState", a).horse == forsta, tostring(sa.horseName))

print("\n── 3: en annan häst går inte att förbereda ──")
stall(a, 0)
local egen = __anropa("G01GetState", a).horse
local annans = if egen == h1 then h2 else h1
local ok, skal = __anropa("G01Action", a, "approach", annans)
check("förberedelse på någon annans häst nekas", ok == false, tostring(skal))
check("fasen står kvar efter försöket",
	__anropa("G01GetState", a).phase == "approach")

print("\n── 4: avståndet gäller ──")
stall(a, 500)
local okLangt = __anropa("G01Action", a, "approach", egen)
check("förberedelse på orimligt avstånd nekas", okLangt == false)
stall(a, 0)
check("samma moment går bra nära hästen",
	__anropa("G01Action", a, "approach", egen) == true)

print("\n── 5: ordningen går inte att hoppa över ──")
--[[ Efter approach står vi i check. tack ska nekas här. ]]
check("tack kan inte hoppa över check", __anropa("G01Action", a, "tack", egen) == false)
check("groom kan inte hoppa över check", __anropa("G01Action", a, "groom", egen) == false)
check("fasen står kvar efter hoppförsök",
	__anropa("G01GetState", a).phase == "check", __anropa("G01GetState", a).phase)

print("\n── 6: uppsittning nekas före ready_to_mount ──")
local okTidig, skalTidig = __anropa("MountRequest", a, egen)
check("uppsittning nekas mitt i förberedelsen", okTidig == false, tostring(skalTidig))
check("ingen montering nådde HorseService", #__monteringar == 0,
	#__monteringar .. " monteringar")

forbered(a, egen, { "check", "groom", "tack" })
check("hela sekvensen ger ready_to_mount",
	__anropa("G01GetState", a).phase == "ready_to_mount",
	__anropa("G01GetState", a).phase)
check("mountUnlocked är sant först nu",
	__anropa("G01GetState", a).mountUnlocked == true)

--[[ Även färdigförberedd får man inte sitta upp på NÅGON ANNANS häst. ]]
local okAnnans = __anropa("MountRequest", a, annans)
check("färdig förberedelse ger inte rätt till annans häst", okAnnans == false)

local okMount = __anropa("MountRequest", a, egen)
check("uppsittning tillåts efter full förberedelse", okMount == true)
check("monteringen nådde HorseService", #__monteringar == 1)
check("fasen blev mounted", __anropa("G01GetState", a).phase == "mounted")

print("\n── 10: avsittning ger ett säkert läge att sitta upp igen ──")
__anropa("DismountRequest", a)
local efter = __anropa("G01GetState", a)
check("avsittning återgår till ready_to_mount", efter.phase == "ready_to_mount", efter.phase)
check("uppsittning är upplåst direkt efter avsittning", efter.mountUnlocked == true)
check("man kan sitta upp igen utan att göra om förberedelsen",
	__anropa("MountRequest", a, egen) == true)
__anropa("DismountRequest", a)

--[[ Efter avsittning ska inga NYA förberedelsemoment gå att köra — annars
	kan man mala feedback i all oändlighet. ]]
check("inga förberedelsemoment går att upprepa efter avsittning",
	__anropa("G01Action", a, "tack", egen) == false)

print("\n── 2 igen: hästen frigörs när spelaren lämnar ──")
local egenA = __anropa("G01GetState", a).horse
__lamnar(a)
__korDeferrade()
--[[ Poängen är att hästen inte längre är ANNAS. Att den direkt går vidare
	till den som väntat är det önskade beteendet, så provet får inte kräva 0. ]]
check("hästen tillhör inte längre spelaren som lämnade",
	egenA:GetAttribute("AssignedUserId") ~= a.UserId,
	"AssignedUserId=" .. tostring(egenA:GetAttribute("AssignedUserId")))
--[[ Den som väntat ska få hästen som just blev ledig. Provet stod först
	som "sc2.horse ~= nil or true", vilket alltid är sant — alltså inget prov
	alls. Skärpt, och då syntes buggen. ]]
local sc2 = __anropa("G01GetState", c)
check("den väntande spelaren får hästen som blev ledig",
	sc2.horse ~= nil, sc2.phase .. " / " .. tostring(sc2.horseName))

print("\n── 9: serverns feedback följer med i det som skickas ──")
--[[ Doris behöver en egen häst: Cilla tog den som blev ledig. ]]
__taggaHast(hast("Gamma", 0))
local d = __spelare("Doris", 104)
__ansluter(d)
__korDeferrade()
local sd = __anropa("G01GetState", d)
if sd.horse then
	stall(d, 0)
	sd.horse.Position = Vector3.new(0, 0, 0)
	__anropa("G01Action", d, "approach", sd.horse)
	local sista = __sistaTill(d)
	check("ett godkänt moment skickar med pedagogisk feedback",
		sista ~= nil and typeof(sista[2]) == "string" and sista[2] ~= "",
		sista and tostring(sista[2]) or "inget skickat")
else
	check("Doris fick en häst att prova feedback med", false, sd.phase)
end

if fails > 0 then
	print(string.format("\n%d FEL", fails))
	error("gameplay.spec: " .. fails .. " fel")
end
print("\nG01.1 gameplay: alla gröna")
