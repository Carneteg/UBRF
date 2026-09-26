--!nostrict
--[[
	BÄNKEN SKA LJUGA SÅ LITE SOM MÖJLIGT (#264).

	`stubs.luau` uppdaterade `Parent` men lämnade barnet kvar i FÖRRA
	förälderns `_barn`, och en identisk `Parent` la till en ny post. En
	part som flyttades från A till B låg alltså kvar i `A:GetChildren()`
	OCH i B:s, och `Parent = B` två gånger gav B två poster av samma barn.

	Det är inte en detalj. Varje prov som räknar barn, letar efter en
	riven nod eller följer ett subträd mätte då något motorn aldrig gör —
	och ett sådant prov kan vara grönt av rena bänkskäl.

	Raden bar en kommentar om att bokföringen medvetet utelämnats för att
	`varldshud.spec` föll. Det skälet håller inte: ett prov får inte vara
	grönt därför att bänken har fel.

	Den här specen håller kvar den rättade semantiken. Den mäter STUBBEN,
	inte produktionskoden — det är hela poängen. En bänk utan eget prov
	är ett mätinstrument ingen kalibrerat.

	VAD DOKUMENTATIONEN FAKTISKT SÄGER, och var den tiger. Reglerna
	nedan är uppslagna i Robloxs creator-docs, inte påstådda ur minnet:

	  · `GetChildren()` definieras som "every Instance whose Parent is
	    equal to the object" — medlemskapet är HÄRLETT ur den enda
	    `Parent`-egenskapen, inte en lista man lägger till i. Dubbletter
	    är därför omöjliga, och en flyttad nod försvinner ur sin gamla
	    förälder per definition.
	  · `Destroy()` sätter `Parent` till nil OCH LÅSER egenskapen; "an
	    error is raised when setting the Parent of a destroyed object".
	  · `IsDescendantOf` är transitiv över hela förälderkedjan, så en nod
	    vars FÖRFADER kopplats bort är ute ur världen även med en egen
	    förälder kvar.

	TVÅ STÄLLEN DÄR DOKUMENTATIONEN TIGER, och där provet därför är
	försiktigt:

	  1. FELETS TEXT vid en riven nod är inte dokumenterad någonstans.
	     Provet kräver därför bara ATT det kastar, aldrig vad det säger.
	     Stubbens formulering är ett rimligt påstående, inte en mätning.
	  2. Att skriva SAMMA `Parent` igen — dokumentationen säger inget om
	     signalerna. Antalet barn är säkert (ett), och det är det provet
	     mäter. Stubben fyrar i dag DescendantRemoving + DescendantAdded
	     även för en oförändrad förälder; det är en känd avvikelse som
	     inget prov vilar på.

	Kör: python3 roblox/tests/build.py tests/stubbsemantik.spec.luau
	     && luau roblox/tests/.build/stubbsemantik.spec.luau ]]

local fel = 0
local function prova(vad, ok, detalj)
	if ok then
		print(("  OK   %s%s"):format(vad, if detalj then "  " .. detalj else ""))
	else
		fel += 1
		print(("  FEL  %s%s"):format(vad, if detalj then "  " .. detalj else ""))
	end
end

local function antalBarn(x): number
	return #x:GetChildren()
end

local function harBarn(foralder, barn): boolean
	for _, b in ipairs(foralder:GetChildren()) do
		if b == barn then return true end
	end
	return false
end

print("\n── EN NOD HAR EXAKT EN FÖRÄLDER ─────────────────────────────")
do
	local a = Instance.new("Folder")
	a.Name = "A"
	a.Parent = workspace
	local b = Instance.new("Folder")
	b.Name = "B"
	b.Parent = workspace
	local p = Instance.new("Part")
	p.Name = "Vandraren"

	p.Parent = a
	prova("barnet ligger hos A", antalBarn(a) == 1 and harBarn(a, p),
		("A har %d"):format(antalBarn(a)))

	--[[ REPRODUKTIONEN. Förut blev det här A=1, B=1 — samma nod på två
	     ställen samtidigt. ]]
	p.Parent = b
	prova("A ÄR TOM EFTER FLYTTEN", antalBarn(a) == 0,
		("A har %d"):format(antalBarn(a)))
	prova("och B har barnet", antalBarn(b) == 1 and harBarn(b, p),
		("B har %d"):format(antalBarn(b)))
	prova("och Parent pekar på B", p.Parent == b)

	--[[ SAMMA FÖRÄLDER IGEN ÄR INGEN NY POST. Förut gav det B två. ]]
	p.Parent = b
	prova("SAMMA PARENT IGEN DUBBLERAR INTE", antalBarn(b) == 1,
		("B har %d"):format(antalBarn(b)))

	--[[ LOSSAD UR VÄRLDEN: ingen förälder alls, och borta ur B. ]]
	p.Parent = nil
	prova("en lossad nod är borta ur sin förälder", antalBarn(b) == 0,
		("B har %d"):format(antalBarn(b)))
	prova("och har ingen förälder", p.Parent == nil)

	a:Destroy()
	b:Destroy()
end

print("\n── SUBTRÄDET FÖLJER MED SIN FÖRFADER ────────────────────────")
do
	local mapp = Instance.new("Folder")
	mapp.Name = "Subtrad"
	mapp.Parent = workspace
	local mitten = Instance.new("Folder")
	mitten.Name = "Mitten"
	mitten.Parent = mapp
	local lov = Instance.new("Part")
	lov.Name = "Lov"
	lov.Parent = mitten

	prova("lövet är i världen", lov:IsDescendantOf(workspace) == true)

	--[[ FÖRFADERN kopplas bort. Lövet har kvar SIN egen förälder hela
	     vägen ner — det var precis det Slice G-reviewens fynd 1 handlade
	     om — men det är inte längre i världen. ]]
	mapp.Parent = nil
	prova("LÖVET ÄR UTE UR VÄRLDEN NÄR FÖRFADERN KOPPLAS BORT",
		lov:IsDescendantOf(workspace) == false)
	prova("men har fortfarande en egen förälder", lov.Parent == mitten,
		tostring(lov.Parent))
	prova("och mellanledet har kvar sitt barn", antalBarn(mitten) == 1)

	--[[ TILLBAKA IN: hela subträdet kommer med. ]]
	mapp.Parent = workspace
	prova("och hela subträdet kommer tillbaka in",
		lov:IsDescendantOf(workspace) == true)

	mapp:Destroy()
end

print("\n── DESTROY ÄR TERMINAL ──────────────────────────────────────")
do
	local mapp = Instance.new("Folder")
	mapp.Name = "Doende"
	mapp.Parent = workspace
	local p = Instance.new("Part")
	p.Name = "Doende del"
	p.Parent = mapp

	p:Destroy()
	prova("den rivna noden är borta ur sin förälder", antalBarn(mapp) == 0,
		("mappen har %d"):format(antalBarn(mapp)))
	prova("och har ingen förälder", p.Parent == nil, tostring(p.Parent))

	--[[ LÅST. Motorn kastar vid varje senare tilldelning. ]]
	local ok = pcall(function() p.Parent = mapp end)
	prova("ATT SÄTTA PARENT PÅ EN RIVEN NOD KASTAR", ok == false)
	prova("och den kom inte tillbaka", antalBarn(mapp) == 0,
		("mappen har %d"):format(antalBarn(mapp)))

	mapp:Destroy()
end

print("")
if fel > 0 then
	print(("STUBBSEMANTIKEN: %d FEL"):format(fel))
	error("stubbsemantiken foll")
end
--[[ SLUTRADEN ÄR ETT KONTRAKT mot `kor.sh`: den letar efter "alla gröna"
     och tolkar frånvaron som en KRASCH. ]]
print("STUBBSEMANTIKEN: alla gröna")
