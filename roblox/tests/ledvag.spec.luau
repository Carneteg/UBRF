--!nostrict
--[[
	EN NY VÄG FÅR BÖRJA MED REN KLOCKA — 90°-hörnet.

	ROBLOX_RUNTIME_ROUTING_ACCEPTANCE / M3.1.

	── VAD SOM HÄNDE I STUDIO ────────────────────────────────────────

	Gluggen mellan `Tvärvägg 1:1` (slutar X 466,47) och `Tvärvägg 1:2`
	(börjar X 474,28) är 7,81 studs bred. Hästen är 1,76 bred och 6,44
	lång med huvudskyddet inräknat, och ska svänga ~90° från en
	öst-västlig gång ner genom gluggen.

	Uppmätt pose när hon fastnade:

	    häst      475,30 · 184,80   kurs −90   v 0,01
	    flanken   når Z 185,68 — väggen börjar 185,70
	    delmål    472,4 · 190,8   (rakt söder om väggen)
	    ror       Tvärvägg 1:2

	Hon låg så i 6,7 sekunder och frigjorde sig vid `stillaSedan` 7,3.
	`NAV_FASTNAT` är 8,0. Det var en kapplöpning, och den förlorades i
	ett av tre fullrutt-pass — därav `led.fastnat`.

	── VAD SOM FAKTISKT VAR TRASIGT ──────────────────────────────────

	Planeraren KLARADE hörnet. `ComputeAsync` från exakt den posen ger
	sex vägpunkter rakt genom gluggen — mätt efteråt på samma
	koordinater. Men vägen fanns aldrig kvar:

	     9,9 s   nav 2/5    en väg på fem punkter fanns
	    10,1 s   nav 1/0    den var borta

	Regeln «EN VÄG SOM INTE BÄR SKA KASTAS» i `_steg` river vägen när
	`stillaSedan > NAV_STILLA`. Klockan stod redan på fem sekunder från
	tiden FÖRE vägen fanns, så varje ny väg revs innan hon hunnit ta ett
	steg på den. Sex planförsök, sex kastade lösningar.

	Regelns egen avsikt är att mäta tid PÅ VÄGEN. Klockan nollställs
	därför när vägen installeras. Ingen tidsgräns är ändrad.

	── VAD SOM MÄTS ──────────────────────────────────────────────────

	  1. en väg som kommer in medan hon står stilla överlever,
	  2. och hon får faktiskt gå på den,
	  3. men en väg som inte bär kastas fortfarande — skyddet är kvar,
	  4. och `navPlaner` får inga gratisförsök av nollställningen.

	Kör: python3 roblox/tests/build.py tests/ledvag.spec.luau
	     && luau roblox/tests/.build/ledvag.spec.luau
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

local RunService = game:GetService("RunService")
RunService._server = true

local M = 3
local DT = 1 / 30
local NAV_STILLA = 1.2

local nastaId = 400
local function nySpelare(namn, pos)
	nastaId += 1
	local k = Instance.new("Model")
	k.Name = "Karaktar"
	local rot = Instance.new("Part")
	rot.Name = "HumanoidRootPart"
	rot.Size = vec(2, 2, 1)
	rot.CFrame = CFrame.new(pos)
	rot.Parent = k
	k.PrimaryPart = rot
	local hum = Instance.new("Humanoid")
	hum.Name = "Humanoid"
	hum.Parent = k
	k.Parent = workspace
	return { Name = namn, UserId = nastaId, Character = k,
		CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }, rot
end

local function nyHast(id, pos)
	local m = Instance.new("Model")
	m.Name = id
	m:SetAttribute("HorseId", id)
	local kropp = Instance.new("Part")
	kropp.Name = "HumanoidRootPart"
	kropp.Size = vec(1.76, 2.21, 5.24)
	kropp.CFrame = CFrame.new(pos)
	kropp.Parent = m
	m.PrimaryPart = kropp
	local hum = Instance.new("Humanoid")
	hum.Name = "Humanoid"
	hum.Parent = m
	m.Parent = workspace
	return m, kropp
end

--[[ Den uppmätta posen, i världskoordinater. Hästen står kilad; spelaren
	har redan runt hörnet och söderut. ]]
local HAST = vec(475.3, 3, 184.8)
local SPELARE = vec(471.7, 3, 200.3)

--[[ Vägen planeraren FAKTISKT gav i Studio från den posen, förkortad till
	sina bärande punkter. Den går väst ut ur klämman och sedan söderut
	genom gluggen. ]]
local VAGEN = {
	vec(475, 3, 185), vec(473, 3, 184), vec(473, 3, 186),
	vec(472, 3, 189), vec(472, 3, 192),
}

--[[ Stubben haller inne vagen tills `efter` anrop har gjorts. Det ar
	vad Studio matte: hon stod stilla i fem sekunder INNAN planeraren
	svarade, och det ar just den klockan som rev vagen. ]]
local function vagEfter(efter)
	local n = 0
	return function()
		n += 1
		if n <= efter then return nil end
		return VAGEN
	end
end

local function nyttPass(svar)
	LedService._glomForProv()
	local hast, hastkropp = nyHast("hast_vag", HAST)
	local sp, rot = nySpelare("Ledare_vag", SPELARE + vec(0, 0, -16))
	local ok, skal = LedService.borja(sp, hast, hast)
	if not ok then return nil, nil, nil, tostring(skal) end
	local l = LedService.lage(sp)
	l.lamnatBox = true
	--[[ Spelaren flyttas till sitt uppmätta läge EFTER starten: `borja`
		kräver räckvidd, och passet ska mäta hörnet, inte kopplingen.
		`spar` töms så att spårföljningen inte har en egen väg att ge —
		det är NAVVÄGEN som provas här. ]]
	rot.CFrame = CFrame.new(SPELARE)
	table.clear(l.spar)
	__pathSvar = svar
	__pathMal = {}
	return l, hastkropp, sp, nil
end

print("")
print("EN NY VÄG FÅR BÖRJA MED REN KLOCKA (M3.1 — 90°-hörnet)")

print("-- 1. En väg som kommer in medan hon står stilla överlever --")

do
	--[[ Hästen rör sig inte — hon är kilad. Bänken har ingen fysik, så
		det sköter sig självt: ingenting flyttar henne. ]]
	local l, hastkropp, sp, fel = nyttPass(vagEfter(2))
	check("passet startar", fel == nil, tostring(fel))
	if l then
		--[[ Låt klockan gå förbi NAV_STILLA innan någon väg finns — det är
			exakt situationen i Studio: fem sekunder stillastående INNAN
			planeraren svarade. ]]
		--[[ Klockan mats MEDAN sparet ar tomt pa vag. Efterat gar den inte
			att lasa: installationen nollstaller den, vilket ar hela
			rattelsen. ]]
		local toppUtanVag, bildrutor = 0, 0
		for i = 1, 200 do
			LedService._steg(DT)
			bildrutor = i
			if #l.navVag > 0 then break end
			if l.stillaSedan > toppUtanVag then toppUtanVag = l.stillaSedan end
		end
		check("klockan hann förbi NAV_STILLA innan någon väg fanns",
			toppUtanVag > NAV_STILLA,
			("stillaSedan nådde %.2f s utan väg, på %d bildrutor"):format(toppUtanVag, bildrutor))
		check("och planeraren har faktiskt frågats",
			#__pathMal > 0, ("%d mål begärda"):format(#__pathMal))
		check("en väg kom in", #l.navVag > 0, ("%d vägpunkter"):format(#l.navVag))
		--[[ ETT ENDA STEG TILL. Det var allt som behovdes for att den gamla
			koden skulle riva vagen: `stillaSedan` stod kvar over NAV_STILLA
			fran tiden fore vagen fanns. ]]
		local fanns = #l.navVag
		LedService._steg(DT)
		check("vägen finns kvar efter nästa bildruta",
			#l.navVag > 0, ("%d vägpunkter före, %d efter"):format(fanns, #l.navVag))
		check("och klockan nollställdes när vägen installerades",
			l.stillaSedan < NAV_STILLA, ("stillaSedan %.2f s"):format(l.stillaSedan))
	end
end

print("")
print("-- 2. Hon går faktiskt på den --")

do
	local l, hastkropp, sp, fel = nyttPass(function() return VAGEN end)
	check("passet startar", fel == nil, tostring(fel))
	if l then
		for _ = 1, 60 do LedService._steg(DT) end
		--[[ Hon flyttas längs vägen för hand — bänken har ingen fysik, så
			det är så man mäter att indexet vandrar. Varje anhalt är en av
			planerarens egna punkter. ]]
		local nadda = 0
		for steg = 2, #VAGEN do
			hastkropp.CFrame = CFrame.new(VAGEN[steg])
			LedService._steg(DT)
			if l.navIx > nadda then nadda = l.navIx end
		end
		check("vägpunktsindexet vandrar framåt när hon går vägen",
			nadda >= 3, ("navIx nådde %d av %d"):format(nadda, #l.navVag))
		--[[ ATT VAGEN AR SLUT AR RATT UTFALL, inte ett fel: `_steg` tommer
			`navVag` nar sista vagpunkten nats och lamnar over till
			sparfoljningen igen. Det som mats ar att hon hann HELA vagen
			utan att den revs under henne. ]]
		check("hon förbrukade vägen i stället för att få den riven",
			nadda >= #VAGEN, ("navIx nådde %d, vägen var %d punkter"):format(nadda, #VAGEN))
	end
end

print("")
print("-- 3. Skyddet är kvar: en väg som inte bär kastas ändå --")

do
	--[[ Samma väg, men hästen rör sig ALDRIG. Då är vägen en väg hon inte
		kan bära, och den ska kastas när klockan hunnit förbi NAV_STILLA
		igen — räknat FRÅN att vägen kom. ]]
	local l, hastkropp, sp, fel = nyttPass(function() return VAGEN end)
	check("passet startar", fel == nil, tostring(fel))
	if l then
		for _ = 1, 60 do LedService._steg(DT) end
		check("en väg installerades", #l.navVag > 0, ("%d punkter"):format(#l.navVag))
		--[[ NAV_STILLA är 1,2 s = 36 bildrutor. Femtio räcker med marginal,
			och hästen står blick stilla hela tiden. ]]
		local revs, varv = false, 0
		for i = 1, 200 do
			LedService._steg(DT)
			varv = i
			if #l.navVag == 0 then revs = true break end
		end
		check("vägen kastas när hon inte kommer någonstans PÅ den",
			revs, ("%d punkter kvar efter %d bildrutor, stillaSedan %.2f, badGa=%s"):format(
				#l.navVag, varv, l.stillaSedan, tostring(l.badGa)))
	end
end

print("")
print("-- 4. Nollställningen ger inga gratis planförsök --")

do
	--[[ `NAV_MAX_PLANER` finns för att en blockerad häst inte ska mala
		servern. Nollställningen av klockan får inte återställa räknaren
		via `if l.lamnatBox and l.stillaSedan == 0 then l.navPlaner = 0 end`.
		Hästen står still hela passet, så varje väg kastas och en ny
		begärs — räknaren ska nå taket och stanna där. ]]
	local l, hastkropp, sp, fel = nyttPass(function() return VAGEN end)
	check("passet startar", fel == nil, tostring(fel))
	if l then
		for _ = 1, 900 do LedService._steg(DT) end
		check("planeringsräknaren står kvar på sitt tak",
			l.navPlaner >= 6, ("navPlaner %d"):format(l.navPlaner))
		--[[ Och antalet FAKTISKA anrop till planeraren är bundet av taket,
			inte av hur många bildrutor som gått. Varje anrop provar mål
			plus reserv, alltså som mest två per försök. ]]
		check("och antalet vägberäkningar är bundet av taket, inte av tiden",
			#__pathMal <= 12, ("%d beräkningar över 900 bildrutor"):format(#__pathMal))
	end
end

__pathSvar = nil

print("")
if fails > 0 then
	print(("ledvag.spec: %d mätning(ar) föll."):format(fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("ledvag.spec: alla gröna")
end
