--!nostrict
--[[
	AVSITTNINGENS PLATS — ryttaren ska hamna BREDVID hästen, inte på henne.

	══ VAD SOM MÄTTES I STUDIO ════════════════════════════════════════

	Avsittningen skrev en flytt 4,5 studs åt vänster. Uppmätt efteråt,
	både mitt på öppen ridbana och intill sargen:

	    hästen (399.94 3.36 280.00) · ryttaren (400.00 7.59 280.00)
	    sidsteg 0.06 studs · höjd över hästroten +4.24 · Floor Plastic

	`FloorMaterial` var hästen själv: hon stod på hästryggen.

	══ VAD DEN HÄR SPECEN KAN OCH INTE KAN ════════════════════════════

	Den mäter PLATSEN: att den räknas ur hästens egen geometri, att den
	ligger utanför hennes kropp, att fötterna hamnar på det underlag som
	faktiskt bär, att vänster går före höger, att höger tas när vänster är
	upptagen, och att ingen av dem tas när marken saknas eller ligger för
	långt ned.

	Den kan INTE mäta tidsfrågan — att Roblox skriver tillbaka ryttarens
	läge så länge `seat.Occupant` pekar på henne, och att den andra
	placeringen därför är den som håller. Bänken har ingen sits som
	släpper en bildruta senare. Det är ett Studio-prov, och det står som
	NOT TESTED i leveransen.

	Kör: python3 roblox/tests/build.py tests/avsittning.spec.luau
	     && luau roblox/tests/.build/avsittning.spec.luau
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
local function nara(a, b, tol)
	return type(a) == "number" and type(b) == "number" and math.abs(a - b) <= (tol or 1e-6)
end

local RunService = game:GetService("RunService")
RunService._server = true

--[[ ── EN VÄRLD MED GOLV OCH HINDER ─────────────────────────────────

	`markFn(x, z)` svarar var det BÄRANDE golvet ligger, `hinderFn(p)` om
	en låda med mitten i `p` krockar med något. Båda är provets egna, så
	varje mätning nedan säger exakt vilken värld den gäller i. ]]
local function varld(markFn, hinderFn)
	__markyta = function(origin, _dir, params)
		--[[ MARKSÖKNINGEN SKA RESPEKTERA KOLLISION. Ridbanans sand är ett
			dekorlager utan kollision, och att sätta av på den vore att
			sätta av i luften. Svarar strålen fel sorts yta faller provet. ]]
		if not (params and params.RespectCanCollide) then
			return { Position = Vector3.new(origin.X, 900, origin.Z),
				Normal = Vector3.new(0, 1, 0), Instance = { Name = "dekorlager" } }
		end
		local y = markFn(origin.X, origin.Z)
		if y == nil then return nil end
		--[[ Strålen har en räckvidd. Ligger golvet utanför den finns det
			inget golv, precis som i världen. ]]
		if y > origin.Y or (origin.Y - y) > 24 then return nil end
		return { Position = Vector3.new(origin.X, y, origin.Z),
			Normal = Vector3.new(0, 1, 0), Instance = { Name = "golv" } }
	end
	__delarILada = function(cf, storlek, _params)
		if hinderFn and hinderFn(cf.Position, storlek) then
			return { { Name = "hinder", CanCollide = true } }
		end
		return {}
	end
end

local PLATT = function() return 0 end

local function nyKaraktar(pos)
	local k = Instance.new("Model")
	k.Name = "Karaktar"
	local rot = Instance.new("Part")
	rot.Name = "HumanoidRootPart"
	rot.Size = Vector3.new(2, 2, 1)
	rot.CFrame = CFrame.new(pos)
	rot.Parent = k
	local hum = Instance.new("Humanoid")
	hum.Name = "Humanoid"
	hum.Parent = k
	k.Parent = workspace
	return k, rot, hum
end

local function nyHast(id, namn, hojd, x)
	local m = HastRigg.bygg(id, namn, CFrame.new(Vector3.new(x, 0, 0)), hojd)
	m.Parent = workspace
	return m
end

--[[ HÄSTEN ÄR ETT HINDER. Utan henne i hinderfunktionen mäter provet
	aldrig det som var fel: att ryttaren hamnade inuti henne. Lådan
	jämförs i hästens EGET rum, så provet inte behöver räkna om världen
	varje gång hästen vrids. ]]
local function hastSomHinder(hast, extra)
	local rot = hast.PrimaryPart
	return function(p, storlek)
		local l = rot.CFrame:PointToObjectSpace(p)
		local inne = math.abs(l.X) < (rot.Size.X + storlek.X) / 2
			and math.abs(l.Z) < (rot.Size.Z + storlek.Z) / 2
		if inne then return true end
		return extra ~= nil and extra(p, storlek, l)
	end
end

local jack = nyHast("blackrock_jack", "Blackrock Jack", 1.45, 0)
local rotJ = jack.PrimaryPart
local kar, krot, khum = nyKaraktar(Vector3.new(0, 20, 0))

--[[ ══ 1. VÄNSTER NÄR VÄNSTER ÄR FRI ═════════════════════════════════ ]]
print("\n── Vänster sida först, som man sitter av ──")

varld(PLATT, hastSomHinder(jack))
local cf, skal = HorseService._avsittningsplats(jack, kar)
check("en plats hittas", cf ~= nil, tostring(skal))
check("och den är vänster sida", skal == "avsitt.vanster", tostring(skal))

local lokal = rotJ.CFrame:PointToObjectSpace(cf.Position)
check("platsen ligger till VÄNSTER i hästens eget rum", lokal.X < 0,
	string.format("lokal x %.3f", lokal.X))
check("och i höjd med henne, varken fram eller bak", nara(lokal.Z, 0, 1e-6),
	string.format("lokal z %.3f", lokal.Z))

--[[ INGEN ÖVERLAPPNING. Kravet är kropp mot kropp, inte mittpunkt mot
	mittpunkt: halva hästens bredd plus halva ryttarens måste rymmas. ]]
check("ryttarens kropp rör inte hästens",
	math.abs(lokal.X) >= rotJ.Size.X / 2 + krot.Size.X / 2,
	string.format("%.3f mot krav %.3f", math.abs(lokal.X),
		rotJ.Size.X / 2 + krot.Size.X / 2))

--[[ FÖTTERNA PÅ MARKEN. `HipHeight` är marken till rotens underkant, så
	rotens mitt ska ligga marken + halva roten + HipHeight. Ett tal för
	lågt och hon står i golvet; ett för högt och hon faller. ]]
check("fötterna står på golvet, varken i det eller ovanför",
	nara(cf.Position.Y - krot.Size.Y / 2 - khum.HipHeight, 0, 1e-6),
	string.format("markhöjd under fötterna %.4f",
		cf.Position.Y - krot.Size.Y / 2 - khum.HipHeight))

--[[ HON VÄNDER SIG MOT HÄSTEN. Att sitta av och stå med ryggen mot henne
	är fel både i verkligheten och på skärmen. ]]
local mot = (Vector3.new(rotJ.Position.X, cf.Position.Y, rotJ.Position.Z) - cf.Position)
local framat = cf.LookVector
check("och hon står vänd mot hästen",
	(framat.X * mot.X + framat.Z * mot.Z) > 0,
	string.format("look (%.2f %.2f) mot (%.2f %.2f)", framat.X, framat.Z, mot.X, mot.Z))

--[[ ══ 2. HÖGER NÄR VÄNSTER ÄR UPPTAGEN ═════════════════════════════ ]]
print("\n── Höger sida när vänster är blockerad ──")

varld(PLATT, hastSomHinder(jack, function(_p, _s, l) return l.X < 0 end))
local cf2, skal2 = HorseService._avsittningsplats(jack, kar)
check("en plats hittas ändå", cf2 ~= nil, tostring(skal2))
check("och det är höger sida", skal2 == "avsitt.hoger", tostring(skal2))
check("platsen ligger till HÖGER i hästens eget rum",
	rotJ.CFrame:PointToObjectSpace(cf2.Position).X > 0,
	string.format("lokal x %.3f", rotJ.CFrame:PointToObjectSpace(cf2.Position).X))

--[[ ══ 3. BÅDA SIDOR UPPTAGNA ════════════════════════════════════════ ]]
print("\n── Båda sidor blockerade: närmaste säkra läge ──")

--[[ En bred sarg på var sida, som i en smal box: bara framför och bakom
	finns plats. Det är precis det läge regeln "närmaste säkra" finns för. ]]
varld(PLATT, hastSomHinder(jack, function(_p, _s, l)
	return math.abs(l.Z) < 3.0
end))
local cf3, skal3 = HorseService._avsittningsplats(jack, kar)
check("en plats hittas även då", cf3 ~= nil, tostring(skal3))
check("men den är varken vänster eller höger", skal3 == "avsitt.narmaste",
	tostring(skal3))
local l3 = rotJ.CFrame:PointToObjectSpace(cf3.Position)
check("den ligger fram eller bak, inte rakt ut åt sidan", math.abs(l3.Z) > 0.5,
	string.format("lokal (%.2f %.2f)", l3.X, l3.Z))
check("och fortfarande utanför hästens kropp",
	math.abs(l3.Z) >= rotJ.Size.Z / 2,
	string.format("|z| %.2f mot halva längden %.2f", math.abs(l3.Z), rotJ.Size.Z / 2))

--[[ ══ 4. INGEN MARK, INGEN TELEPORT ═════════════════════════════════ ]]
print("\n── Marken avgör, inte riktningen ──")

--[[ Vänster sida är ett stup — golvet ligger tolv studs ned. En
	avsittning dit är inget fall att räkna på, det är en teleport ut ur
	världen, och regeln ska välja höger i stället. ]]
varld(function(x, _z)
	local l = rotJ.CFrame:PointToObjectSpace(Vector3.new(x, 0, 0))
	return if l.X < -1 then -12 else 0
end, hastSomHinder(jack))
local cf4, skal4 = HorseService._avsittningsplats(jack, kar)
check("stup till vänster väljs bort", skal4 == "avsitt.hoger", tostring(skal4))
check("och platsen står på det golv som finns där",
	nara(cf4.Position.Y - krot.Size.Y / 2 - khum.HipHeight, 0, 1e-6),
	string.format("%.4f", cf4.Position.Y - krot.Size.Y / 2 - khum.HipHeight))

--[[ Saknas bärande golv överallt finns ingen plats alls, och då ska
	räkningen SÄGA det i stället för att hitta på en höjd. ]]
varld(function() return nil end, hastSomHinder(jack))
local cf5, skal5 = HorseService._avsittningsplats(jack, kar)
check("utan golv finns ingen plats", cf5 == nil and skal5 == "avsitt.ingen_plats",
	tostring(skal5))

--[[ ══ 5. HÄSTENS EGET RUM, INTE VÄRLDENS ════════════════════════════ ]]
print("\n── Platsen följer hästen när hon vänder sig ──")

--[[ En världskoordinat hade legat kvar när hästen vred sig. Hela regeln
	bygger på att "vänster" är HENNES vänster. ]]
local vriden = nyHast("marabou", "Marabou vriden", 1.45, 200)
vriden.PrimaryPart.CFrame = vriden.PrimaryPart.CFrame * CFrame.Angles(0, math.rad(90), 0)
varld(PLATT, hastSomHinder(vriden))
local cf6, skal6 = HorseService._avsittningsplats(vriden, kar)
check("en vriden häst ger också vänster sida", skal6 == "avsitt.vanster", tostring(skal6))
local l6 = vriden.PrimaryPart.CFrame:PointToObjectSpace(cf6.Position)
check("och platsen är HENNES vänster, inte världens",
	l6.X < 0 and nara(l6.Z, 0, 1e-6),
	string.format("lokal (%.2f %.2f)", l6.X, l6.Z))

--[[ ══ 6. STORLEKEN FÖLJER MED ════════════════════════════════════════ ]]
print("\n── En stor häst kräver mer plats än en ponny ──")

local ponny = nyHast("marabou", "Marabou", 1.27, 400)
local stor = nyHast("allan", "Allan", 1.78, 600)
local function sidled(hast)
	varld(PLATT, hastSomHinder(hast))
	local c = HorseService._avsittningsplats(hast, kar)
	return math.abs(hast.PrimaryPart.CFrame:PointToObjectSpace(c.Position).X)
end
local sp, sj, ss = sidled(ponny), sidled(jack), sidled(stor)
check("ponnyn kräver minst sidled, den stora hästen mest", sp < sj and sj < ss,
	string.format("%.2f < %.2f < %.2f", sp, sj, ss))

--[[ ══ 7. HELA AVSITTNINGEN ═══════════════════════════════════════════ ]]
print("\n── Avsittningen lämnar inget efter sig ──")

varld(PLATT, hastSomHinder(jack))
HorseService.setMountGate(nil)
HorseService._registerForProv(jack)
local spelare = { Name = "SagaAberg", UserId = 1, Character = kar,
	CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }
krot.CFrame = CFrame.new(rotJ.Position.X + 3, rotJ.Position.Y, rotJ.Position.Z)

local okUpp, skalUpp = HorseService.tryMount(spelare, jack)
check("hon sitter upp", okUpp == true, tostring(skalUpp))
local sits = jack:FindFirstChild("RiderSeat")
check("sitsen har henne", sits.Occupant == khum)
check("och hästen bär hennes id",
	jack:GetAttribute("RiderUserId") == spelare.UserId,
	tostring(jack:GetAttribute("RiderUserId")))

krot.AssemblyLinearVelocity = Vector3.new(0, 0, 40)

--[[ RÄKNA FLYTTARNA. Avsittningen placerar TVÅ gånger: en gång direkt och
	en gång när sitsen har släppt. Den andra är den som håller i Studio, och
	den enda vakt bänken kan sätta mot att den tyst faller bort är att räkna
	att den faktiskt hände. Den föll bort en gång: `setRider(session, nil)`
	låg efter placeringen, så vakten "har hon hunnit sätta sig igen?" läste
	ett `byRider` som ännu pekade på hästen hon just klev av. ]]
local flyttar = 0
local egenPivot = kar.PivotTo
kar.PivotTo = function(self, cf)
	flyttar += 1
	return egenPivot(self, cf)
end

local okNed = HorseService.dismount(spelare)
kar.PivotTo = egenPivot
check("kroppen placerades två gånger: direkt och när sitsen släppte",
	flyttar == 2, string.format("%d placeringar", flyttar))
check("hon sitter av", okNed == true)

--[[ ── NEJET SKA GÅ ATT LÄSA (#202 punkt 3) ────────────────────────────

	`DismountRequest` ger returen vidare till klienten, som skriver
	`skalText(skal)`. Föll skälet ut som `nil` fick spelaren den generiska
	"det gick inte nu" — hon fick veta att något inte gick, men inte vad.
	Allt annat i kedjan bär en namngiven nyckel.

	Mätt i Studio på `e6a674c`:  andra DismountRequest -> ok=false, skal=nil

	Dubbel avsittning är i sig inget fel; det är bara nejet som ska gå att
	läsa. ]]
local okNed2, skalNed2 = HorseService.dismount(spelare)
check("en andra avsittning nekas", okNed2 == false, tostring(okNed2))
check("och den säger VARFÖR — inte nil",
	type(skalNed2) == "string" and skalNed2 ~= "",
	("[%s]"):format(tostring(skalNed2)))
check("skälet är en riktig språknyckel spelaren kan få läst",
	skalNed2 == "pass.rider_inte" and Sprak.finns(skalNed2) == true,
	("%s · finns=%s"):format(tostring(skalNed2), tostring(Sprak.finns(skalNed2))))
check("Humanoid.Sit är falskt", khum.Sit == false, tostring(khum.Sit))
check("sitsen är tom", sits.Occupant == nil, tostring(sits.Occupant))
check("sitsens egen SeatWeld är borta", sits:FindFirstChild("SeatWeld") == nil)
check("RiderUserId är nollat", jack:GetAttribute("RiderUserId") == 0,
	tostring(jack:GetAttribute("RiderUserId")))

--[[ DET SOM VAR FEL: hon stod kvar ovanpå hästen. Mätningen är därför
	inte "hon flyttades" utan "hon står inte längre över henne". ]]
local slut = kar:GetPivot().Position
local lokalSlut = rotJ.CFrame:PointToObjectSpace(slut)
check("hon står INTE ovanpå hästen",
	math.abs(lokalSlut.X) >= rotJ.Size.X / 2 + krot.Size.X / 2,
	string.format("sidled %.2f studs, höjd över hästroten %+.2f",
		math.abs(lokalSlut.X), slut.Y - rotJ.Position.Y))
check("hon står på golvet",
	nara(slut.Y - krot.Size.Y / 2 - khum.HipHeight, 0, 1e-6),
	string.format("%.4f", slut.Y - krot.Size.Y / 2 - khum.HipHeight))
check("och farten är nollad så hon inte slungas iväg",
	krot.AssemblyLinearVelocity.Magnitude == 0,
	tostring(krot.AssemblyLinearVelocity.Magnitude))

--[[ ══ 8. ETT NEJ ÅTERFÖRENAR, OCH DAGSFORMEN REPLIKERAS ════════════

	ChatGPT-re-review av `269bec5`, båda punkterna, genom de RIKTIGA
	produktionsvägarna: `HorseService.start()` installerar bindningen och
	provet anropar `DismountRequest.OnServerInvoke` — inte en kopia av
	den. ]]
print("\n── Ett nej återförenar, och dagsformen replikeras ──")
do
	HorseService.start()
	local dr = Networking.get("DismountRequest")
	local mc = Networking.get("MountChanged")
	check("DismountRequest har en riktig handlare",
		type(dr.OnServerInvoke) == "function")

	--[[ ── DAGSFORMEN ─────────────────────────────────────────────

		Den räknades ut vid uppsittning och göts in i `session.energi`.
		Klienten hade ingen väg till den: `init.client` läste
		`stats.Dagsform`, som ingen någonsin satte. Fältet var alltid
		`nil` och `UgnetaTema` föll tillbaka på skyggheten — utan att
		något kunde upptäcka det. ]]
	local spelare8 = { Name = "DagsformSaga", UserId = 8,
		Character = kar, CharacterAdded = __signal_ny(),
		CharacterRemoving = __signal_ny() }

	HorseService.setDagsformHook(function() return 0.30 end)
	check("hon sitter upp", HorseService.tryMount(spelare8, jack) == true)
	check("DAGSFORMEN REPLIKERAS SOM ATTRIBUT",
		jack:GetAttribute("Dagsform") == 0.30,
		tostring(jack:GetAttribute("Dagsform")))

	--[[ ── ÅTERFÖRENINGEN ─────────────────────────────────────────

		Det värsta fallet är `takt.for_snabbt`: anropet når aldrig
		tjänsten, så ingenting DÄR kan upptäcka att klienten redan rivit
		sitt ekipage. Skopan töms därför FÖRST, medan hon sitter upp, och
		sedan nekas en riktig avsittning. ]]
	do
		local tak = Skopa.GRANSER.DismountRequest.tak
		for _ = 1, tak do dr.OnServerInvoke(spelare8) end
		--[[ Första anropet satte henne faktiskt av. Upp igen, så att
		     servern verkligen anser att hon rider när nejet kommer. ]]
		HorseService.tryMount(spelare8, jack)

		mc._skickat = {}
		local ok, skal = dr.OnServerInvoke(spelare8)
		check("den nekas av takten", ok == false and skal == "takt.for_snabbt",
			("%s / %s"):format(tostring(ok), tostring(skal)))

		local aterforenad = false
		for _, paket in ipairs(mc._skickat) do
			if paket[1] == spelare8 and paket[2] == jack then
				aterforenad = true
			end
		end
		check("ETT NEKAT NEJ SKICKAR MountChanged TILL HENNE",
			aterforenad == true,
			("%d paket"):format(#mc._skickat))
		--[[ …och servern har henne kvar. Det är precis den delade
		     sanningen återföreningen finns för: klienten har rivit,
		     servern har inte. ]]
		check("och servern anser fortfarande att hon rider",
			sits.Occupant == khum, tostring(sits.Occupant))
	end

	--[[ INGEN UPPFUNNEN ÅTERFÖRENING. Anser servern INTE att hon rider
	     var klientens rivning rätt, och då ska ingenting skickas. Utan
	     den här raden vore grinden uppfylld av en server som alltid
	     skickar `MountChanged`. ]]
	do
		check("hon sitter av på riktigt",
			HorseService.dismount(spelare8) == true)
		mc._skickat = {}
		check("ÅTERFÖRENINGEN AVSTÅR NÄR DET INTE FANNS NÅGOT ATT RÄTTA",
			HorseService.aterforena(spelare8) == false
				and #mc._skickat == 0,
			("%d paket"):format(#mc._skickat))
		--[[ Och attributet följer med henne ut: nästa ryttare ska inte
		     ärva föregåendes dagsform. ]]
		check("dagsformen städas vid avsittning",
			jack:GetAttribute("Dagsform") == nil,
			tostring(jack:GetAttribute("Dagsform")))
	end

	HorseService.setDagsformHook(nil)
end

--[[ ══ 9. EN TRASIG BOKFÖRING ÄR INTE ETT LÄGE ATT ÅTERVÄNDA TILL ══

	Re-review runda 2, blockerare 2. `hast.oregistrerad` betyder PRECIS
	att `byRider` ljuger: ryttaren står bokförd på en häst vars session
	är borta. Att återförena på den uppgiften hade satt upp klienten på
	en häst servern inte kan köra. ]]
print("\n── Stale byRider återförenar inte ──")
do
	local mc = Networking.get("MountChanged")
	local spelare9 = { Name = "StaleSaga", UserId = 9, Character = kar,
		CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }

	check("hon sitter upp", HorseService.tryMount(spelare9, jack) == true)
	--[[ Sessionen rivs UNDER henne, bokföringen lämnas kvar. Det är
	     exakt det läge `hast.oregistrerad` rapporterar. ]]
	HorseService._glomSessionForProv(jack)
	local ok, skal = HorseService.dismount(spelare9)
	check("avsittningen svarar hast.oregistrerad",
		ok == false and skal == "hast.oregistrerad",
		("%s / %s"):format(tostring(ok), tostring(skal)))

	mc._skickat = {}
	check("ÅTERFÖRENINGEN VÄGRAR PÅ EN TRASIG BOKFÖRING",
		HorseService.aterforena(spelare9) == false and #mc._skickat == 0,
		("%d paket"):format(#mc._skickat))
	--[[ …och posten är STÄDAD, inte bara ignorerad: nästa uppsittning
	     ska börja rent i stället för att ärva lögnen. ]]
	check("och den trasiga posten är städad",
		HorseService.aterforena(spelare9) == false)
end

--[[ ══ 10. ETT NEKAT NEJ FÅR INTE TAPPA RITTENS IDENTITET ══════════

	Re-review runda 2, blockerare 1. Servern nollar INGENTING när den
	nekar — den nekade ju. `session.sekvens` står kvar, och regeln i
	`onRidingIntent` är `sekvens > session.sekvens`. En klient som
	startade om sin räknare vid återföreningen hade fått varje hjälp
	tyst kastad, och hästen hade slutat svara på DRIV och BROMS. ]]
print("\n── Rittens identitet överlever ett nekat nej ──")
do
	local dr = Networking.get("DismountRequest")
	local intent = Networking.get("RidingIntent")
	local spelare10 = { Name = "SekvensSaga", UserId = 10, Character = kar,
		CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }

	--[[ Avsnitt 9 rev jacks session med flit och lamnade henne
	     oregistrerad. Den registreras om har, annars mater det har
	     avsnittet foregaendes sopor i stallet for sin egen sak — forsta
	     korningen gjorde precis det och blev rod pa «hon sitter upp». ]]
	HorseService._registerForProv(jack)
	local okUpp10, skalUpp10 = HorseService.tryMount(spelare10, jack)
	check("hon sitter upp", okUpp10 == true, tostring(skalUpp10))
	local marke = jack:GetAttribute("RidSession")
	check("ritten har ett märke", type(marke) == "string", tostring(marke))

	--[[ IMPULSSPÄRREN ÄR ÄKTA TID. `Config.RIDINPUT.ImpulsSparr` minus
	     serverns marginal, mätt med `os.clock`. Bänken har ingen klocka
	     att skruva på här, så provet väntar ut den på riktigt. Utan det
	     hade den andra hjälpen fallit på spärren och provet hade mätt
	     spärren i stället för sekvensen. ]]
	local function vantaSparren()
		local slut = os.clock() + Config.RIDINPUT.ImpulsSparr + 0.02
		while os.clock() < slut do end
	end

	--[[ En hjälp accepteras om den ändrar serverns replikerade läge.
	     `RidVersion` räknas upp i `replikera`, som bara nås av ett
	     accepterat steg. ]]
	local function driv(sekvens): boolean
		local fore = jack:GetAttribute("RidVersion")
		intent.OnServerEvent:Fire(spelare10, marke, "driv", sekvens)
		return jack:GetAttribute("RidVersion") ~= fore
	end

	vantaSparren()
	check("en hjälp med sekvens 5 accepteras", driv(5) == true)

	--[[ Skopan töms direkt — inte genom `OnServerInvoke`, för det FÖRSTA
	     anropet hade satt henne av på riktigt och det är inte det här
	     provet handlar om. Mätningen nedan går ändå genom den riktiga
	     handlaren. ]]
	local tak = Skopa.GRANSER.DismountRequest.tak
	for _ = 1, tak do Skopa.slapp(spelare10, "DismountRequest") end

	local ok, skal = dr.OnServerInvoke(spelare10)
	check("avsittningen nekas av takten",
		ok == false and skal == "takt.for_snabbt",
		("%s / %s"):format(tostring(ok), tostring(skal)))
	check("MÄRKET ÄR OFÖRÄNDRAT — det är samma ritt",
		jack:GetAttribute("RidSession") == marke,
		tostring(jack:GetAttribute("RidSession")))

	vantaSparren()
	check("NÄSTA HJÄLP I SEKVENSEN ACCEPTERAS FORTFARANDE",
		driv(6) == true)

	--[[ DEN RAD SOM VISAR VARFÖR DET SPELAR ROLL. Hade klienten startat
	     om sin räknare vid återföreningen — som den gjorde före den här
	     rättelsen — vore nästa hjälp en etta. Servern kastar den tyst. ]]
	vantaSparren()
	check("men en OMSTARTAD räknare kastas tyst — det var buggen",
		driv(1) == false)

	HorseService.dismount(spelare10)
end

--[[ ══ ÄGARSKAPET TILLBAKA TILL SPELAREN — OCH NÄR DET INTE GÅR ═══

	Robustness Slice F.

	Raden löd `pcall(function() krot:SetNetworkOwner(spelare) end)` och
	kastade både utfallet och skälet. En misslyckad återlämning lämnade
	kroppen serverstyrd utan ett spår av varför.

	Provet går genom den RIKTIGA avsittningen och dess fördröjda
	överlämning, inte genom ett direktanrop av hjälparen.

	SCHEMAT BEHÖVS FÖR ETT AV FALLEN. Bänkens `task.spawn` kör synkront,
	så överlämningen hinner aldrig ligga och vänta — och då går vakten
	«samma kropp fortfarande?» inte att pröva. `__schemaPa(true)` köar
	trådarna så att provet kan byta kropp MELLAN avsittningen och
	överlämningen. ]]
print("\n── Ägarskapet tillbaka till spelaren ──")

local function varningarMed(text)
	local n = 0
	for _, rad in ipairs(__varningar) do
		if string.find(rad, text, 1, true) then n += 1 end
	end
	return n
end

do
	HorseService._registerForProv(jack)
	local kar2 = kar
	--[[ `Parent` MASTE VARA SATT. Vakten i den fordrojda overlamningen
	     ar `krot.Parent and spelare.Parent and spelare.Character ==
	     karaktar`, och en banktabell utan `Parent` faller pa mitten —
	     da kordes overlamningen aldrig och varenda matning nedan var
	     tyst i stallet for rod. Forsta versionen gjorde precis det. ]]
	local Spelartjanst = game:GetService("Players")
	local spelareF = { Name = "AgarSaga", UserId = 11, Character = kar2,
		Parent = Spelartjanst,
		CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }
	Spelartjanst._spelare = { spelareF }
	local krotF = kar2:FindFirstChild("HumanoidRootPart")
	check("kroppen har en rot att äga", krotF ~= nil)

	--[[ ── DET NORMALA FALLET ───────────────────────────────────── ]]
	do
		krot.CFrame = CFrame.new(rotJ.Position.X + 3, rotJ.Position.Y, rotJ.Position.Z)
		check("hon sitter upp", HorseService.tryMount(spelareF, jack) == true)
		local fore = #__varningar
		HorseService.dismount(spelareF)
		check("ÄGARSKAPET ÄR TILLBAKA HOS SPELAREN",
			krotF:GetNetworkOwner() == spelareF,
			tostring(krotF:GetNetworkOwner()))
		local nya = 0
		for i = fore + 1, #__varningar do
			if string.find(__varningar[i], "ägarskapet åter", 1, true) then
				nya += 1
			end
		end
		check("och en lyckad överlämning varnar inte", nya == 0,
			("%d varningar"):format(nya))
	end

	--[[ ── EN NY KROPP FÅR INTE DEN GAMLAS ÄGARSKAP ─────────────── ]]
	do
		HorseService._registerForProv(jack)
		krot.CFrame = CFrame.new(rotJ.Position.X + 3, rotJ.Position.Y, rotJ.Position.Z)
		spelareF.Character = kar2
		check("hon sitter upp igen", HorseService.tryMount(spelareF, jack) == true)
		krotF:SetNetworkOwner(nil)

		--[[ MÄTPUNKTEN ÄR FÖRSÖKET, INTE SLUTVÄRDET. Avsittningen gör
		     TVÅ placeringar, och den andra tar tillbaka ägarskapet till
		     servern innan den lämnar över igen. Slutägaren blir därför
		     `nil` oavsett om vakten finns — första versionen mätte det
		     och kunde inte bli röd. Det som skiljer är om överlämningen
		     ens FÖRSÖKTE ge kroppen till spelaren. ]]
		local forsokFore = rawget(krotF, "_agarskapTillSpelare") or 0
		__schemaPa(true)
		HorseService.dismount(spelareF)
		--[[ Överlämningen ligger i kön. NU byter hon kropp. ]]
		local kar3 = __makeKaraktar and __makeKaraktar() or Instance.new("Model")
		kar3.Name = "NyKropp"
		spelareF.Character = kar3
		__schemaTomKo()
		__schemaPa(false)

		check("EN GAMMAL KROPP FÅR INTE ÄGARSKAPET NÄR KROPPEN BYTTS",
			(rawget(krotF, "_agarskapTillSpelare") or 0) == forsokFore,
			("%d -> %d forsok"):format(forsokFore,
				rawget(krotF, "_agarskapTillSpelare") or 0))
		spelareF.Character = kar2
	end

	--[[ ── FÖRHANDSKONTROLLEN SÄGER NEJ ─────────────────────────── ]]
	do
		HorseService._registerForProv(jack)
		krot.CFrame = CFrame.new(rotJ.Position.X + 3, rotJ.Position.Y, rotJ.Position.Z)
		HorseService.tryMount(spelareF, jack)
		krotF:SetNetworkOwner(nil)
		--[[ Skälet kommer från PROVET. Roblox dokumenterar att en
		     skälsträng finns men inte vilka de är, så varken bänken
		     eller koden får låtsas känna dem. ]]
		rawset(krotF, "_agarskapNekas", "ankrad del (provets skal)")
		--[[ Bara forsoken att ge kroppen till SPELAREN raknas. Det
		     avsiktliga `SetNetworkOwner(nil)` mitt i avsittningen ar en
		     annan sak, och forsta versionen av raden slog ihop dem —
		     `16 -> 18` sag ut som ett forbjudet forsok men var serverns
		     egen overlamning. ]]
		local forsokFore = rawget(krotF, "_agarskapTillSpelare") or 0
		local fore = #__varningar

		HorseService.dismount(spelareF)

		check("ETT NEJ HINDRAR ÖVERLÄMNINGEN",
			krotF:GetNetworkOwner() ~= spelareF,
			tostring(krotF:GetNetworkOwner()))
		check("och inget förbjudet SetNetworkOwner försöktes",
			(rawget(krotF, "_agarskapTillSpelare") or 0) == forsokFore,
			("%d -> %d"):format(forsokFore,
				rawget(krotF, "_agarskapTillSpelare") or 0))
		local sagt, skalMed = 0, 0
		for i = fore + 1, #__varningar do
			if string.find(__varningar[i], "NEKADES", 1, true) then
				sagt += 1
				if string.find(__varningar[i], "provets skal", 1, true) then
					skalMed += 1
				end
			end
		end
		check("OCH VARNINGEN SÄGER VAD OCH VARFÖR",
			sagt >= 1 and skalMed >= 1,
			("%d varningar, %d med skalet"):format(sagt, skalMed))
		rawset(krotF, "_agarskapNekas", nil)
	end

	--[[ ── FÖRHANDSKONTROLLEN KASTAR ────────────────────────────── ]]
	do
		HorseService._registerForProv(jack)
		krot.CFrame = CFrame.new(rotJ.Position.X + 3, rotJ.Position.Y, rotJ.Position.Z)
		HorseService.tryMount(spelareF, jack)
		krotF:SetNetworkOwner(nil)
		rawset(krotF, "_agarskapKastar", true)
		local fore = #__varningar

		HorseService.dismount(spelareF)
		rawset(krotF, "_agarskapKastar", nil)

		local sagt = 0
		for i = fore + 1, #__varningar do
			if string.find(__varningar[i], "förhandskontrollen", 1, true) then
				sagt += 1
			end
		end
		check("EN KASTANDE FÖRHANDSKONTROLL DÖDAR INTE TRÅDEN",
			sagt >= 1, ("%d varningar"):format(sagt))
		--[[ …och överlämningen gjordes ÄNDÅ. En kontroll som inte går
		     att göra får inte ta bort en överlämning som fungerar. ]]
		check("och överlämningen gjordes ändå",
			krotF:GetNetworkOwner() == spelareF,
			tostring(krotF:GetNetworkOwner()))
	end

	--[[ ── SJÄLVA SÄTTNINGEN KASTAR ─────────────────────────────── ]]
	do
		HorseService._registerForProv(jack)
		krot.CFrame = CFrame.new(rotJ.Position.X + 3, rotJ.Position.Y, rotJ.Position.Z)
		HorseService.tryMount(spelareF, jack)
		local fore = #__varningar
		rawset(krotF, "_satAgarskapKastar", true)

		local levde = pcall(function() HorseService.dismount(spelareF) end)
		rawset(krotF, "_satAgarskapKastar", nil)

		check("en kastande SetNetworkOwner tar inte ner avsittningen",
			levde == true, tostring(levde))
		local sagt = 0
		for i = fore + 1, #__varningar do
			if string.find(__varningar[i], "MISSLYCKADES", 1, true) then
				sagt += 1
			end
		end
		check("OCH DEN LÄMNAR ETT SPÅR", sagt >= 1, ("%d varningar"):format(sagt))
	end
end

__markyta = nil
__delarILada = nil

if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("\navsittning.spec: alla gröna")
end
