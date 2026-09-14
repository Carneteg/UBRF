--!nostrict
--[[
	PLACE-INTEGRITET — grinden som #171 saknade.

	Den läsande Studio-auditen fann det obehagliga: Rojo-träden stämde exakt
	mot repot, och ändå var inget QA-resultat ur placen trovärdigt.
	`ReplicatedStorage.UBRFBuild` var handplacerad, pekade på en head 53
	commits gammal, och preflightens punkt 9 sa PASS ändå.

	Punkt 9 mätte nämligen bara EN sak: att fältet `sha` fanns. En modul med
	fel innehåll har också ett `sha`. Grinden kunde alltså inte skilja en
	riktig identitet från en lapp någon lagt dit för att få grönt — och det
	är precis den skillnaden som avgör om ett testresultat betyder något.

	Specen provar båda riktningarna. Att den GENERERADE identiteten passerar
	säger lite; att den HANDPLACERADE faller är hela beviset. Därför byggs
	#171:s faktiska modul upp här, ordagrant som den låg i placen.

	Kör: python3 roblox/tests/build.py tests/integritet.spec.luau
	     && luau roblox/tests/.build/integritet.spec.luau
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

local RS = game:GetService("ReplicatedStorage")

--[[ Läser EN rad ur preflightens egen mätning — inte ur `Integritet.rader()`
	direkt. Skillnaden är avsiktlig: raden ska vara inkopplad i den grind
	som faktiskt kör, annars kan den vara aldrig så korrekt utan att mäta
	något. Punkt 9 satt tidigare utanför `matningar`, och det var en del av
	varför den aldrig blev provad. ]]
local function matning(prefix)
	for _, r in ipairs(Preflight.matningar(true)) do
		if r.namn:sub(1, #prefix) == prefix then return r end
	end
	return nil
end

--[[ Sätter en identitetsmodul i den stubbade ReplicatedStorage. `__modul`
	är bänkens söm: stubbarnas `require` svarar med den tabellen. ]]
local function sattIdentitet(tabell)
	local gammal = RS:FindFirstChild("UBRFBuild")
	if gammal then gammal:Destroy() end
	if tabell == nil then return nil end
	local m = Instance.new("ModuleScript")
	m.Name = "UBRFBuild"
	m.__modul = tabell
	m.Parent = RS
	return m
end

print("\n── Raderna finns över huvud taget ──")

for _, p in ipairs({ "9a", "9b", "9c", "9d", "10a", "10b", "10c" }) do
	local r = matning(p)
	check("preflighten mäter " .. p, r ~= nil,
		r and r.namn or ("ingen rad som börjar på " .. p))
end

print("\n── Ingen identitet alls: fail closed ──")

do
	sattIdentitet(nil)
	--[[ Det HÄR är kravet: frånvaro av en identitet är inte ett PASS. En
		tom hylla betyder att ingen vet vilken kod som testas. ]]
	for _, p in ipairs({ "9a", "9b", "9c", "9d" }) do
		local r = matning(p)
		check("utan identitet faller " .. p, r ~= nil and r.ok == false,
			r and tostring(r.detalj) or "-")
	end
end

print("\n── #171:s handplacerade modul faller ──")

do
	--[[ Ordagrant den som låg i placen: rätt form, riktigt SHA, och ändå
		värdelös som identitet. `sha` finns — så den GAMLA punkt 9 hade
		sagt PASS på exakt den här tabellen. ]]
	sattIdentitet({
		sha = "3ead60990f1ae2d46bdb5531fa2dbad99abb5f3b",
		miljo_sha = "3ead60990f1ae2d46bdb5531fa2dbad99abb5f3b",
		lage = "rojo-live",
	})

	local r9a = matning("9a")
	check("modulen går att läsa — den var aldrig trasig", r9a ~= nil and r9a.ok == true,
		r9a and tostring(r9a.detalj) or "-")

	local r9b = matning("9b")
	check("handplacerad identitet fälls som icke-genererad",
		r9b ~= nil and r9b.ok == false, r9b and tostring(r9b.detalj) or "-")
	check("felet namnger läget så den som ska rätta slipper leta",
		r9b ~= nil and tostring(r9b.detalj):find("rojo%-live") ~= nil,
		r9b and tostring(r9b.detalj) or "-")

	local r9c = matning("9c")
	check("utan källhash faller formkravet", r9c ~= nil and r9c.ok == false,
		r9c and tostring(r9c.detalj) or "-")

	local r9d = matning("9d")
	check("utan källräkning faller 9d", r9d ~= nil and r9d.ok == false,
		r9d and tostring(r9d.detalj) or "-")
end

print("\n── Den genererade identiteten passerar ──")

do
	--[[ Den RIKTIGA filen ur `roblox/game/UBRFBuild.luau`, inlinad av
		byggfilen. Att prova en handskriven kopia hade mätt kopian. ]]
	sattIdentitet(UBRFBuild)
	for _, p in ipairs({ "9a", "9b", "9c", "9d" }) do
		local r = matning(p)
		check("genererad identitet passerar " .. p, r ~= nil and r.ok == true,
			r and tostring(r.detalj) or "-")
	end
	check("identiteten bär en källhash på 64 hextecken",
		#tostring(UBRFBuild.kallhash) == 64,
		tostring(UBRFBuild.kallhash):sub(1, 12) .. "…")
	check("identiteten vet vad Rojo äger",
		type(UBRFBuild.rojo) == "table" and type(UBRFBuild.rojo.ReplicatedStorage) == "table",
		"rojo.ReplicatedStorage")
end

print("\n── En förfalskad hash av rätt FORM räcker inte som bevis ──")

do
	--[[ Ärlighet om vad runtime kan och inte kan: en place kan inte räkna om
		hashen över sin egen källkod, så 9c mäter FORM, inte färskhet.
		Färskheten mäts av `tools/bygg-identitet.py --kontrollera` mot
		arbetsträdet. Specen slår fast gränsen i stället för att låta någon
		tro att 9c bevisar mer än den gör. ]]
	sattIdentitet({
		kallhash = string.rep("a", 64), lage = "rojo", kallor = 66,
		sha = "0000000000000000000000000000000000000000",
	})
	local r = matning("9c")
	check("9c släpper igenom en välformad men påhittad hash — mäter FORM",
		r ~= nil and r.ok == true, "färskheten gatas av bygg-identitet.py --kontrollera")
end

print("\n── Kvarglömda fjärrobjekt ──")

do
	sattIdentitet(UBRFBuild)
	local mapp = RS:FindFirstChild("HorseRemotes")
	if not mapp then
		mapp = Instance.new("Folder")
		mapp.Name = "HorseRemotes"
		mapp.Parent = RS
	end

	--[[ Ren mapp byggd ur facit: den ska passera. ]]
	for namn, klass in Networking.definitioner() do
		local r = Instance.new(klass)
		r.Name = namn
		r.Parent = mapp
	end
	local r10a = matning("10a")
	check("en mapp som matchar facit passerar", r10a ~= nil and r10a.ok == true,
		r10a and tostring(r10a.detalj) or "-")

	--[[ DET VERKLIGA DRIFTFELET. `Networking.get` återanvänder mappen i
		stället för att bygga om den, så ett borttaget fjärrobjekt följer
		med in i runtime och ingen vet längre vem som äger det. ]]
	local spoke = Instance.new("RemoteEvent")
	spoke.Name = "GammaltBorttagetRemote"
	spoke.Parent = mapp
	local r = matning("10a")
	check("ett okänt fjärrobjekt fäller grinden", r ~= nil and r.ok == false,
		r and tostring(r.detalj) or "-")
	check("felet namnger objektet",
		r ~= nil and tostring(r.detalj):find("GammaltBorttagetRemote") ~= nil,
		r and tostring(r.detalj) or "-")
	spoke:Destroy()
	check("grinden blir grön igen när det städats",
		(matning("10a") or {}).ok == true)

	--[[ Fel klass kastar först när någon ANROPAR objektet — alltså mitt i
		ett spelprov och inte i grinden. ]]
	local mount = mapp:FindFirstChild("MountRequest")
	if mount then mount:Destroy() end
	local fel = Instance.new("RemoteEvent")
	fel.Name = "MountRequest"
	fel.Parent = mapp
	local r10b = matning("10b")
	check("ett felklassat fjärrobjekt fäller grinden",
		r10b ~= nil and r10b.ok == false, r10b and tostring(r10b.detalj) or "-")
	fel:Destroy()
	local ratt = Instance.new("RemoteFunction")
	ratt.Name = "MountRequest"
	ratt.Parent = mapp
	check("rätt klass gör den grön igen", (matning("10b") or {}).ok == true)
end

print("\n── Klassificeringen skiljer källstyrt från skräp ──")

do
	sattIdentitet(UBRFBuild)

	local hc = RS:FindFirstChild("HorseCore")
	if not hc then
		hc = Instance.new("ModuleScript")
		hc.Name = "HorseCore"
		hc.Parent = RS
	end
	check("Rojo-ägd modul klassas som kanonisk",
		Integritet.klassificera("ReplicatedStorage", hc) == "kanonisk",
		Integritet.klassificera("ReplicatedStorage", hc))

	local remotes = RS:FindFirstChild("HorseRemotes")
	check("runtime-skapad mapp klassas som runtime, inte ospårad",
		remotes ~= nil and Integritet.klassificera("ReplicatedStorage", remotes) == "runtime",
		remotes and Integritet.klassificera("ReplicatedStorage", remotes) or "-")

	local verktyg = Instance.new("Folder")
	verktyg.Name = "__MCPGeneratedModels"
	verktyg.Parent = RS
	check("plugin-artefakt klassas som verktyg",
		Integritet.klassificera("ReplicatedStorage", verktyg) == "verktyg",
		Integritet.klassificera("ReplicatedStorage", verktyg))
	verktyg:Destroy()

	--[[ En modul ingen källa äger, i den tjänst som replikeras till varje
		klient. Den ska synas. ]]
	local skrap = Instance.new("ModuleScript")
	skrap.Name = "NagotNagonKlistradeIn"
	skrap.Parent = RS
	check("ospårad modul klassas som ospårad",
		Integritet.klassificera("ReplicatedStorage", skrap) == "ospårad",
		Integritet.klassificera("ReplicatedStorage", skrap))
	local r10c = matning("10c")
	check("ospårad modul i ReplicatedStorage fäller grinden",
		r10c ~= nil and r10c.ok == false, r10c and tostring(r10c.detalj) or "-")
	check("felet namnger modulen",
		r10c ~= nil and tostring(r10c.detalj):find("NagotNagonKlistradeIn") ~= nil,
		r10c and tostring(r10c.detalj) or "-")
	skrap:Destroy()
	check("grinden blir grön igen när den tagits bort",
		(matning("10c") or {}).ok == true)
end

print("\n── Utan identitet klassas INGET som kanoniskt ──")

do
	--[[ Konservativt med flit. Om identiteten saknas vet grinden inte vad
		Rojo äger, och då får den inte gissa generöst — det var den sortens
		välvilliga default som höll #171 grön. ]]
	sattIdentitet(nil)
	local hc = RS:FindFirstChild("HorseCore")
	check("utan identitet är även HorseCore ospårad",
		hc ~= nil and Integritet.klassificera("ReplicatedStorage", hc) == "ospårad",
		hc and Integritet.klassificera("ReplicatedStorage", hc) or "-")
	sattIdentitet(UBRFBuild)
end

if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("\nintegritet.spec: alla gröna")
end
