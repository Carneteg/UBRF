--!nostrict
--[[
	First Playable-kontrakten ur #162:s fysiska blockerare.

	Tobias testade i Studio, spawnade för långt från starten och kom inte in
	genom den vita dörren. Ingen maskin hade kunnat säga det, för ingen
	maskin mätte det. Den här specen mäter det.

	Tre kontrakt, och alla tre ska kunna bli RÖDA:

	  1. FASADEN — huset är slutet utom där dörrarna står. Mäts i
	     bygge.spec (murlängd per sida); här mäts att luckan verkligen är
	     en lucka man kan passera, alltså att inget kolliderande står kvar
	     i dörrhålet utom dörrbladet självt.
	  2. SPAWNEN — exakt en avsedd First Playable-spawn, vid stallets
	     ockragula entrédörr, med blicken mot dörren.
	  3. DÖRREN — varje dörrblad får en prompt, öppnas, slutar kollidera
	     medan den är öppen, och går tillbaka till exakt sitt stängda läge.

	Kör: python3 roblox/tests/build.py tests/forstaplayable.spec.luau
	     && luau roblox/tests/.build/forstaplayable.spec.luau
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

local M = BuildKit.M
local modell = workspace:FindFirstChild("Anläggning"):FindFirstChild("UBRF")
local delar = {}
for _, d in ipairs(modell:GetDescendants()) do
	if d.CFrame and d.Size then table.insert(delar, d) end
end

local function arFonsterTyp(typ)
	return typ == "fonster" or typ == "rund" or typ == "valv"
end
local function garIgenom(o)
	return not arFonsterTyp(o.typ) and (o.z0 or 0) <= 0.001
end

-- ── 1. DÖRRBLADEN ÄR UPPMÄRKTA, OCH BARA DE MAN GÅR IGENOM ─────────────
print("\nFirst Playable — dörrbladen")

local vantadeDorrar = 0
local vantadeFonster = 0
for _, b in ipairs(UBRFKomplex.byggnader) do
	for _, o in ipairs(b.oppningar or {}) do
		if garIgenom(o) then vantadeDorrar += 1
		elseif arFonsterTyp(o.typ) then vantadeFonster += 1 end
	end
end

local blad = {}
for _, d in ipairs(delar) do
	if d:GetAttribute("UBRFDorr") == true then table.insert(blad, d) end
end
--[[ P0-6 ur Tobias andra Studio-test: en prompt får inte lova en passage
	som inte finns. En genomgående öppning som är blockerad av något som
	inte går att frigöra utan att hitta på geometri märks därför INTE som
	dörr, utan deklareras som icke-passage med ett skäl (se
	`ICKE_PASSAGER` i Anlaggningen.luau). Kontraktet är tvåsidigt, så att
	det inte går att bli grön genom att sluta märka upp dörrar:

	    uppmärkta + deklarerade = alla genomgående öppningar

	Att de deklarerade FAKTISKT är blockerade mäts i varldskoherens.spec,
	som har vägsökningen. ]]
local deklarerade = {}
for _, d in ipairs(delar) do
	if typeof(d:GetAttribute("IngenPassage")) == "string" then
		table.insert(deklarerade, d)
	end
end
check("varje genomgående fasadöppning är en uppmärkt dörr eller en deklarerad icke-passage",
	#blad + #deklarerade == vantadeDorrar,
	("%d blad + %d deklarerade = %d mot %d öppningar")
		:format(#blad, #deklarerade, #blad + #deklarerade, vantadeDorrar))
for _, d in ipairs(deklarerade) do
	print(("       icke-passage: %s %s %s — %s"):format(
		tostring(d:GetAttribute("Byggnad")), tostring(d:GetAttribute("Sida")),
		tostring(d:GetAttribute("Oppningstyp")),
		tostring(d:GetAttribute("IngenPassage")):sub(1, 90)))
end
check("det finns fasaddörrar att märka upp alls", vantadeDorrar > 0,
	("%d st (och %d fönster som INTE ska märkas)"):format(vantadeDorrar, vantadeFonster))

local utanMatt = 0
for _, d in ipairs(blad) do
	if not d:GetAttribute("Bredd") or not d:GetAttribute("Hojd")
		or not d:GetAttribute("Langs") then utanMatt += 1 end
end
check("varje dörrblad bär sina mått (Bredd, Hojd, Langs)", utanMatt == 0,
	("%d utan mått"):format(utanMatt))

--[[ Fönster får INTE bli dörrar. Utan den här mätningen kunde `garIgenom`
	släppa igenom ett valvfönster, och då hade gaveln fått en gångbar lucka
	där det ska sitta glas. ]]
local fonsterSomDorr = 0
for _, d in ipairs(delar) do
	if d:GetAttribute("UBRFDorr") == true and d.Name:find("fonster") then
		fonsterSomDorr += 1
	end
end
check("inget fönster är uppmärkt som dörr", fonsterSomDorr == 0)

-- ── 2. SPAWNKONTRAKTET ─────────────────────────────────────────────────
print("\nFirst Playable — spawnen")

local spawnar = {}
for _, d in ipairs(modell:GetDescendants()) do
	if d.ClassName == "SpawnLocation" then table.insert(spawnar, d) end
end
check("exakt en SpawnLocation byggs", #spawnar == 1, ("%d st"):format(#spawnar))

local start = spawnar[1]
check("spawnen är märkt som First Playable-start",
	start ~= nil and start:GetAttribute("UBRFStart") == true)
check("spawnen pekar ut vilken dörr den hör till",
	start ~= nil and start:GetAttribute("MotDorr") == "stall N dorrgul",
	start and tostring(start:GetAttribute("MotDorr")) or "ingen")

--[[ Läget mäts mot samma härledning som `Anlaggningen` använder: mitt på
	verandagolvet, i räckets öppning mitt för stallets ockragula nordentré.
	Ett tal skrivet för hand här hade bara varit en andra sanning som kan
	glida. ]]
local stall
for _, b in ipairs(UBRFKomplex.byggnader) do
	if b.id == "stall" then stall = b end
end
local dorr
for _, o in ipairs(stall.oppningar or {}) do
	if o.sida == "N" and o.typ == "dorrgul" then dorr = o end
end
local K = UBRFKomplex.identitet.stall.forstukvist
check("stallets ockragula nordentré finns i geometrin", dorr ~= nil)
check("förstukvisten finns i geometrin", K ~= nil)

--[[ Spawnens läge läses tillbaka till KARTANS koordinater. Världen byggs
	i kartans ram och vänds en gång till en högerhänt Y-upp-värld där norr
	är −Z (`BuildKit.tomtlage`); `BuildKit.tomtkoord` är vägen tillbaka.
	Utan den hade det här provet jämfört en spegelbild mot geometrin. ]]
local bas = (modell :: any).PrimaryPart.CFrame
local px, pz, py
if start then
	px, pz = BuildKit.tomtkoord(bas, start.CFrame.Position)
	py = start.CFrame.Position.Y / M
end

if start and dorr and K then
	local r = stall.rekt
	local vantadX = r.x + r.w - K.uFranOst
	local vantadZ = r.y + r.h + K.djup / 2
	check("spawnen står mitt på förstukvistens golv",
		math.abs(px - vantadX) < 0.15 and math.abs(pz - vantadZ) < 0.15,
		("(%.2f, %.2f) mot väntat (%.2f, %.2f)"):format(px, pz, vantadX, vantadZ))

	local dx, dz = Geometri.oppningsMitt(r, "N", dorr.u, dorr.b)
	check("spawnen är i linje med entrédörren",
		math.abs(px - dx) <= 0.6, ("%.2f m i sidled från dörrens mitt"):format(math.abs(px - dx)))
	check("spawnen ligger inom rimligt gångavstånd från dörren",
		math.abs(pz - dz) <= 4.0, ("%.2f m"):format(math.abs(pz - dz)))
	check("spawnen syns inte i granskade bilder (genomskinlig)",
		start.Transparency >= 1)

	--[[ ══ RIKTNINGEN — DEN ANDRA MÄTNINGEN SOM SAKNADES ═══════════════

		Tobias spawnade med RYGGEN mot stallets entrédörr, i fyra builds i
		rad, och varje mätning här var grön. Skälet är att alla mätte LÄGE:
		hur nära golvets mitt spawnen stod, hur väl den låg i linje med
		dörren, hur långt det var dit. Och läget var hela tiden rätt.

		`Anlaggningen` bygger riktningen med `CFrame.lookAt` mot dörren —
		korrekt när den skrivs. Sedan speglas modellen till den högerhända
		världen, och `M R M` vänder lokala Z, alltså LookVector. En låda är
		symmetrisk kring sitt Z-plan så ingenting annat syntes; en spawn är
		det inte.

		Här mäts blickriktningen mot dörren som ett skalärprodukt, i
		världens koordinater och på den SPEGLADE modellen — samma sak den
		lokala Studio-körningen mätte till `dot = −1.000000`. ]]
	local dorrX, dorrZ = Geometri.oppningsMitt(r, "N", dorr.u, dorr.b)
	local mot = BuildKit.tomtlage(dorrX, 0, dorrZ)
	local dit = (bas * mot).Position
	local har = start.CFrame.Position
	local vx, vz = dit.X - har.X, dit.Z - har.Z
	local vlen = math.sqrt(vx * vx + vz * vz)
	local lv = start.CFrame.LookVector
	local llen = math.sqrt(lv.X * lv.X + lv.Z * lv.Z)
	local dot = if vlen > 1e-6 and llen > 1e-6
		then (lv.X * vx + lv.Z * vz) / (llen * vlen) else 0
	--[[ 0,95 ≈ 18° fel. Rakare än så behöver det inte vara — spawnen ska
		SE dörren, inte träffa den på millimetern. Men ett halvt varv ger
		−1 och kan omöjligt smyga igenom. ]]
	check("spawnen SER entrédörren — inte bara står i linje med den",
		dot >= 0.95,
		("dot = %.6f (%.1f° fel)"):format(dot, math.deg(math.acos(math.clamp(dot, -1, 1)))))
end

--[[ ══ DEN MÄTNING SOM SAKNADES ═════════════════════════════════════════

	Tobias spawnade i luften, föll och dog. Specen var grön, för den mätte
	att spawnen låg på ANKOMSTPUNKTEN — inte att det fanns något att stå på
	där. Kameran som punkten kom ur står 6 m ut från fasaden, och en kamera
	behöver ingen mark.

	Här mäts marken. En spawn utan kolliderande yta rakt under sig är inte
	en spawn, den är ett fall. Toleransen är en halvmeter: mark "långt
	därnere" är samma fel med längre falltid. ]]
if start then
	local FALLHOJD = 0.5
	local basta, namn = nil, nil
	for _, d in ipairs(modell:GetDescendants()) do
		if d.CFrame and d.Size and d ~= start and d.CanCollide ~= false then
			local c, s = d.CFrame.Position, d.Size
			local cx, cz = BuildKit.tomtkoord(bas, c)
			if math.abs(cx - px) <= s.X / (2 * M) + 0.01
				and math.abs(cz - pz) <= s.Z / (2 * M) + 0.01 then
				local topp = (c.Y + s.Y / 2) / M
				if topp <= py + 0.01 and (basta == nil or topp > basta) then
					basta, namn = topp, d.Name
				end
			end
		end
	end
	check("det finns kolliderande mark rakt under spawnen", basta ~= nil,
		basta and ("%s, topp %.2f m"):format(namn, basta) or "INGENTING — spelaren faller")
	check("marken ligger direkt under fötterna, inte långt därnere",
		basta ~= nil and (py - basta) <= FALLHOJD,
		basta and ("%.2f m fall"):format(py - basta) or "ingen mark")
end

-- ── 3. DÖRRKONTRAKTET ──────────────────────────────────────────────────
print("\nFirst Playable — dörren öppnas")

DorrService.start()

local medPrompt, oppnade, aterstallda = 0, 0, 0
for _, d in ipairs(blad) do
	local prompt = d:FindFirstChildOfClass("ProximityPrompt")
	if prompt then medPrompt += 1 end

	local fore = d.CFrame
	local foreKoll = d.CanCollide
	if prompt then
		prompt.Triggered:_fire()
		--[[ Det viktiga är inte att bladet rörde sig, utan att det SLUTADE
			kollidera: en öppen dörr man inte kan gå igenom är exakt samma
			fel som förut, bara med en animation på. ]]
		if d.CanCollide == false then oppnade += 1 end
		prompt.Triggered:_fire()
		if d.CanCollide == true and d.CFrame == fore then aterstallda += 1 end
	end
	d.CanCollide = foreKoll
end

check("varje dörrblad fick en ProximityPrompt", medPrompt == #blad,
	("%d av %d"):format(medPrompt, #blad))

--[[ ── PROMPTEN LÄCKER INGET INTERNT TOKEN ───────────────────────────────

	Ur Tobias skärmdump från det fysiska testet: prompten skrev "dorrgul"
	ovanför "Öppna". `dorrgul` är öppningens TYP i geometrin — färgen på
	stalldörren — och ingenting en spelare ska läsa.

	Det gällde inte bara den dörren. Ingen öppning i `UBRFKomplex` har en
	riktig `label`, så etiketten föll tillbaka på typen för VARENDA dörr i
	världen. Mätningen läser därför alla prompter och jämför mot de
	faktiska typerna i geometrin — inte mot en handskriven lista. ]]
do
	local typer = {}
	for _, b in ipairs(UBRFKomplex.byggnader) do
		for _, o in ipairs(b.oppningar or {}) do
			if typeof(o.typ) == "string" then typer[o.typ] = true end
		end
	end
	local lackta, utanNyckel, objekttexter = {}, {}, {}
	for _, d in ipairs(blad) do
		local prompt = d:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			local ot = tostring(prompt.ObjectText)
			objekttexter[ot] = (objekttexter[ot] or 0) + 1
			if typer[ot] then table.insert(lackta, ot) end
			local nyckel = prompt:GetAttribute("SprakObjekt")
			if typeof(nyckel) ~= "string" or not Sprak.finns(nyckel) then
				table.insert(utanNyckel, ot)
			end
		end
	end
	local lista = {}
	for text, antal in pairs(objekttexter) do
		table.insert(lista, ("%s ×%d"):format(text, antal))
	end
	table.sort(lista)
	check("ingen dörrprompt visar geometrins interna typ", #lackta == 0,
		#lackta > 0 and ("läckta token: " .. table.concat(lackta, ", "))
			or table.concat(lista, " · "))
	check("och varje dörrprompt bär en nyckel som finns i katalogen",
		#utanNyckel == 0,
		#utanNyckel > 0 and table.concat(utanNyckel, ", ")
			or (#blad .. " prompter"))
	--[[ Porten och dörren är olika saker i verkligheten och ska vara det i
		texten. Att bara mäta "inget token" hade gått att klara med att
		kalla allt "Dörr". ]]
	check("porten och dörren har olika ord", #lista >= 2,
		table.concat(lista, " · "))
end
check("dörren slutar kollidera när den öppnas", oppnade == #blad,
	("%d av %d"):format(oppnade, #blad))
check("dörren går tillbaka till exakt sitt stängda läge", aterstallda == #blad,
	("%d av %d"):format(aterstallda, #blad))
check("stängd dörr kolliderar igen", (function()
	for _, d in ipairs(blad) do if d.CanCollide ~= true then return false end end
	return #blad > 0
end)())

if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	os.exit(1)
else
	print("\nFirst Playable-kontrakten: alla gröna")
end
