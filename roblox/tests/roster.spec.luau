--!nostrict
--[[
	ROSTERGRINDEN — produktkravet "alla kanoniska UBRF-hästar ska vara
	ridbara" (#162).

	Kravet är inte "det finns en häst som går att rida". Det är att stacken
	är DATASTYRD: en generisk kedja som fungerar för varje individ i
	`UBRFSpelData.hastar`, utan en rad kod om någon enskild häst. Jack är
	särskild på exakt ett ställe i hela spelet — tilldelningen första dagen,
	`Stallet.FORSTA_DAGEN_HAST` — och specen mäter att det stället är det
	enda som nämner honom.

	Provet går igenom HELA rostern, en häst i taget, och för varje individ:

	  · riggen byggs ur samma `HastRigg.bygg` som Jack får,
	  · `HorseService` registrerar henne genom taggen,
	  · hennes EGNA kanonvärden når `HorseStats` (inte skolhästens
	    standardvärden),
	  · sitsen och ryttarleden finns,
	  · hon går att sitta upp på, rida en bildruta och sitta av.

	TÄCKNINGEN är själva poängen: listan kommer ur datan, så en häst som
	läggs till i rostern provas automatiskt — och en häst som inte går att
	rida FÄLLER grinden i stället för att tystna.

	UPPSITTNINGSGRINDEN ÄR AVSIKTLIGT AV här (`setMountGate(nil)`). Den är
	G01-loopens dagsregel — "din tilldelade häst, förberedd" — och den
	mäts i `integration.spec.luau`. Frågan HÄR är en annan: klarar
	hästsystemet varje individ i rostern? Med grinden på hade provet bara
	kunnat mäta den häst dagens tilldelning råkade ge.

	Kör: python3 roblox/tests/build.py tests/roster.spec.luau
	     && luau roblox/tests/.build/roster.spec.luau
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

local Taggar = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local function nyKaraktar(pos)
	local k = Instance.new("Model")
	k.Name = "Karaktar"
	local rot = Instance.new("Part")
	rot.Name = "HumanoidRootPart"
	rot.Size = vec(2, 2, 1)
	rot.CFrame = CFrame.new(pos)
	rot.Parent = k
	local hum = Instance.new("Humanoid")
	hum.Name = "Humanoid"
	hum.Parent = k
	local anim = Instance.new("Animator")
	anim.Name = "Animator"
	anim.Parent = hum
	return k, rot, hum
end

--[[ ── ROSTERN UR DATAN ──────────────────────────────────────────────── ]]
print("\n── Rostern kommer ur speldatan ──")
local roster = {}
for id, h in pairs(UBRFSpel.hastar) do
	table.insert(roster, { id = id, data = h })
end
table.sort(roster, function(a, b) return a.id < b.id end)

check("rostern har hästar", #roster > 0, #roster .. " kanoniska hästar")
check("varje häst bär id, namn och profil ur datan",
	(function()
		for _, h in ipairs(roster) do
			if type(h.id) ~= "string" or type(h.data.namn) ~= "string"
				or type(h.data.profil) ~= "string" then return false end
		end
		return true
	end)())
--[[ Jack är särskild PÅ ETT STÄLLE. Att konstanten finns och pekar på en
	häst som faktiskt står i rostern är hela hans särställning. ]]
local forsta = Stallet.FORSTA_DAGEN_HAST
check("första dagens häst är en häst ur rostern, inte ett eget fall",
	UBRFSpel.hastar[forsta] ~= nil, tostring(forsta))

--[[ ── VARJE HÄST, HELA VÄGEN ────────────────────────────────────────── ]]
print("\n── Varje kanonisk häst: rigg, registrering, egna värden, ritt ──")
RunService._server = true
Taggar:nollstall()
HorseService.start()
--[[ Se filhuvudet: dagsregeln hör till integrationsgrinden, inte hit. ]]
HorseService.setMountGate(nil)

local spelare = { Name = "Roster", UserId = 9301,
	CharacterAdded = { Connect = function() return { Disconnect = function() end } end },
	CharacterRemoving = __signal_ny() }

local sedda = {}
local byggda, ridna = 0, 0
local trasiga = {}

--[[ EN HÄST, hela vägen. Kroppen ligger i en funktion som körs under
	`pcall` av ett skäl som falsifieringen visade: en rigg som saknar sits
	får uppsittningen att KASTA, och då dog hela specen mitt i loopen. Rött
	blev det (kor.sh kräver slutraden), men loggen sa inte VILKEN häst som
	var trasig — och det är hela nyttan med en rostergrind. Nu blir ett
	kast ett namngivet fynd på just den hästen, och de övriga provas
	vidare. ]]
local function provaHast(h, i)
	local fel = {}
	local lage = vec(i * 60, 0, 0)
	local modell = HastRigg.bygg(h.id, h.data.namn, CFrame.new(lage))
	modell.Parent = workspace
	Taggar:AddTag(modell, "Horse")
	byggda += 1

	local session = HorseService.sessionFor(modell)
	local rig = session and session.rig
	local stats = HorseService._statsFor(modell)

	if not session then table.insert(fel, "inte registrerad") end
	if modell:GetAttribute("HorseId") ~= h.id then table.insert(fel, "fel HorseId") end
	if sedda[h.id] then table.insert(fel, "två modeller delar HorseId") end
	sedda[h.id] = modell
	if rig then
		if not rig.seat or rig.seat.ClassName ~= "Seat" then table.insert(fel, "ingen Seat") end
		if not rig.riderJoint then table.insert(fel, "ingen RiderJoint") end
	end
	--[[ HENNES EGNA VÄRDEN. Profilen ur datan ska stå i HorseStats; står
		standardvärdet där rider hon som en generisk skolhäst hur noga
		datan än är skriven — precis det fel #87 blocker 1 rättade, och
		det ska inte kunna komma tillbaka för EN häst i tysthet. ]]
	if not stats then
		table.insert(fel, "inga HorseStats")
	elseif stats.Profil ~= h.data.profil then
		table.insert(fel, ("profil %s ≠ datans %s"):format(tostring(stats.Profil),
			tostring(h.data.profil)))
	end

	--[[ …och att hon FAKTISKT går att rida: sitta upp, en ridbildruta,
		sitta av. Karaktären ställs vid henne, som en spelare gör. ]]
	if session and rig then
		local karaktar = nyKaraktar(lage + vec(6, 0, 0))
		spelare.Character = karaktar
		local okUpp, skalUpp = HorseService.tryMount(spelare, modell)
		if not okUpp then
			table.insert(fel, "uppsittning nekad: " .. tostring(skalUpp))
		else
			local okRitt, felRitt = pcall(function()
				local rc = RiderController.new(rig)
				rc:attach(karaktar)
				rc:step({ speed = 0, lean = 0, gait = "walk", phase = 0, heading = 0,
					turnRate = 0, grounded = true, airborne = false }, 1 / 60)
				rc:step({ speed = 3.2, lean = 0.3, gait = "trot", phase = 0.4, heading = 0,
					turnRate = 0.15, grounded = true, airborne = false }, 1 / 60)
				rc:release()
			end)
			if not okRitt then table.insert(fel, "ridbildrutan kastade: " .. tostring(felRitt)) end
			if not HorseService.dismount(spelare) then
				table.insert(fel, "avsittningen gick inte")
			elseif rig.seat and rig.seat.Occupant ~= nil then
				table.insert(fel, "spökryttare kvar i sitsen")
			else
				ridna += 1
			end
		end
	end
	return fel
end

for i, h in ipairs(roster) do
	local ok, resultat = pcall(provaHast, h, i)
	local fel = if ok then resultat else { "kastade: " .. tostring(resultat) }
	if #fel > 0 then
		table.insert(trasiga, ("%s (%s): %s"):format(h.data.namn or "?", h.id,
			table.concat(fel, ", ")))
	end
end

check("varje häst i rostern fick en rigg", byggda == #roster,
	("%d av %d"):format(byggda, #roster))
check("och ALLA går att sitta upp på, rida och sitta av", #trasiga == 0,
	#trasiga > 0 and table.concat(trasiga, " · ") or (ridna .. " hästar ridna"))
check("ingen häst delar modell med en annan (HorseId är unika)",
	(function()
		local n = 0
		for _ in pairs(sedda) do n += 1 end
		return n == #roster
	end)(), ("%d unika av %d"):format((function()
		local n = 0 for _ in pairs(sedda) do n += 1 end return n
	end)(), #roster))

--[[ TÄCKNINGEN MÄTS OCKSÅ BAKLÄNGES: varje häst i datan ska ha provats.
	Utan den här raden kunde loopen tystna på en tom lista och allt ovan
	vore grönt av sig självt. ]]
local oprovade = {}
for id in pairs(UBRFSpel.hastar) do
	if not sedda[id] then table.insert(oprovade, id) end
end
check("ingen kanonisk häst lämnades oprövad", #oprovade == 0,
	#oprovade > 0 and table.concat(oprovade, ", ") or "alla provade")

RunService._server = false

--[[ `os.exit` finns INTE i luau-CLI:t (den är nil). Ett anrop rakt ut gav
	en "attempt to call a nil value" i loggen i stället för ett läsbart
	slut — rött blev det, men av fel anledning i texten. Här används den
	om den finns, annars ger `error` den icke-nollskilda exitkoden. ]]
if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("\nroster.spec: alla gröna")
end
