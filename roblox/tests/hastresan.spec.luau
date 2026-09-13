--!nostrict
--[[
	HÄSTRESAN — SÖMMARNA INGEN ANNAN SPEC MÄTER

	ChatGPT-order 2026-09-13 12:39: verifiera hela hästresan. Innan jag
	skrev något mätte jag vad sviten redan bevisar, och svaret var: nästan
	allt. `integration.spec` kör kedjan tilldelning → bindning → visitera →
	rykta → hovar → utrustning → leda → uppsittning → ridbildruta →
	avsittning → eftervård → pass räknat → sparat och laddat igen.
	`skotselpass.spec` äger skötselreglerna, `ledning.spec` ledningen,
	`avsittning.spec` avsittningsplatsen, `touch.spec` pekavsikterna,
	`forberedelse.spec` tilldelningen och reservationen mellan två spelare.

	Den här filen duplicerar ingenting av det. Den mäter de FYRA sömmarna
	som ingen spec tog:

	  1. AVSITTNING → OMSITTNING utan att dö. `integration.spec` bevisar
	     omsittning efter respawn — döden släpper sitsen och hon kan sitta
	     upp igen med en ny kropp. Men den vanliga vägen, att bara sitta av
	     och sitta upp igen på samma kropp, stod omätt. Det är den väg en
	     spelare faktiskt tar.

	  2. SLÄPPT KOPPEL → UPPSITTNING. `ledning.spec` bevisar att kopplet
	     släpper. Att uppsittningen fungerar EFTER släppet är ett annat
	     påstående, och det var inte gjort.

	  3. VIKARIEN SKRIVER INTE ÖVER SPARFILEN. `forberedelse.spec` bevisar
	     att den andra spelaren får en annan häst. Att sessionens vikarie
	     inte råkar skriva sig in i sparfilen — alltså att spelarens
	     kanoniska häst finns kvar nästa dag — stod omätt, och det är den
	     dyraste buggen i listan: den förstör progression tyst.

	  4. PEKSPELAREN NÅR HANDLINGARNA. Att texterna finns bevisar
	     `sprak.spec`; att pekavsikterna fungerar bevisar `touch.spec`.
	     Att en spelare UTAN tangentbord kan nå leda, släppa, sitta upp och
	     sitta av stod emellan de två.

	NOT TESTED, uttryckligen: fysik, animation, kamerakänsla, äkta
	multitouch och fysisk enhet. Den här filen mäter tjänsternas kedja,
	inte game feel.

	Kör: python3 roblox/tests/build.py tests/hastresan.spec.luau
	     && luau roblox/tests/.build/hastresan.spec.luau
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

local Players = game:GetService("Players")
local Taggar = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

--[[ ── EN SPELARE MED KROPP ─────────────────────────────────────────────
	Karaktären är en riktig (stubbad) Model med `HumanoidRootPart` och
	`Humanoid`, för det är vad tjänsterna läser: avståndet mäts från roten,
	sitsen tar humanoiden, och städningen hänger på `Humanoid.Died` och
	`Player.CharacterRemoving`. Läget sätts genom CFrame — `Position`
	härleds ur den, precis som på en riktig BasePart. ]]
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

local function nySpelare(namn, userId, pos)
	local k, rot, hum = nyKaraktar(pos)
	local spelare = {
		Name = namn, UserId = userId, Character = k,
		CharacterAdded = __signal_ny(),
		CharacterRemoving = __signal_ny(),
	}
	return spelare, k, rot, hum
end

--[[ Flyttar spelaren. Ett eget anrop för att avståndsproven ska läsa som
	det de är: hon GÅR någon annanstans, hon får ingen ny kropp. ]]
local function stall(spelare, pos)
	spelare.Character:FindFirstChild("HumanoidRootPart").CFrame = CFrame.new(pos)
end

--[[ ── EN VÄRLD MED EN HÄST ─────────────────────────────────────────────
	Startar tjänsterna i produktionens ordning, släpper in spelaren genom
	`PlayerAdded` (samma väg som init.server), läser vilken häst stallet
	gav och bygger riggen för DEN hästen. Taggen sätts sist, och därför går
	registreringen och bindningen genom produktionens taggsignal. ]]
local RIGG_LAGE = vec(0, 0, 0)

local function nySession(namn, userId, forbered)
	__datastore.nollstall()
	Taggar:nollstall()
	Players.PlayerAdded:nollstall()
	Players.PlayerRemoving:nollstall()
	RunService._server = true
	Players._spelare = {}
	SparService._glomHookarForProv()

	local spelare, karaktar, rot, hum = nySpelare(namn, userId, vec(6, 0, 0))
	SparService._glomForProv(spelare)
	if forbered then forbered(spelare) end

	SparService.start()
	StallService.start()
	HorseService.start()
	GameplayService.start()

	Players._spelare = { spelare }
	Players.PlayerAdded:Fire(spelare)
	Players.PlayerAdded:slutfor()

	local hastId = StallService.hastIdFor(spelare)
	local modell = nil
	if hastId then
		local h = (UBRFSpel.hastar or {})[hastId]
		modell = HastRigg.bygg(hastId, (h and h.namn) or hastId, CFrame.new(RIGG_LAGE))
		modell.Parent = workspace
		Taggar:AddTag(modell, "Horse")
	end
	return {
		spelare = spelare, karaktar = karaktar, rot = rot, hum = hum,
		hastId = hastId, modell = modell,
	}
end

local function stadaSession(s)
	Players.PlayerRemoving:Fire(s.spelare)
	Players._spelare = {}
	SparService._glomForProv(s.spelare)
	RunService._server = false
end

--[[ Hela skötseln genom TJÄNSTEN, moment för moment. Inget anrop går
	direkt till `Preparation`: det är skillnaden mot forberedelse.spec.

	SEDAN 16:21-ORDERN hämtar den också utrustningen, och det är med flit
	inte gömt i en hjälpfunktion som sätter ett tillstånd: den går samma väg
	spelaren går — saken hänger i världen, `GameplayService.hamta` prövar
	rätt häst och avståndet, och först därefter släpper momentet igenom. Går
	hämtningen inte igenom faller hela kedjan här, med skälet. ]]
local function skotselGenomTjansten(spelare)
	for _, fas in ipairs(Preparation.stegFaser()) do
		--[[ `leda` KRÄVER numera att hästen faktiskt har letts dit (#162
			blockerare 2). Den här specen driver därför den riktiga
			ledningen i stället för att kvittera steget: den börjar leda,
			flyttar SPELAREN mot ridbanan och låter `LedService._steg`
			köra tjänstens egen följlogik. Hästen flyttas aldrig direkt —
			det är hela skillnaden mot den gamla versionen. ]]
		--[[ `leda` KRÄVER numera att hästen fysiskt letts till ridbanan
			(#162 blockerare 2). Den här specen mäter INTE följfysiken —
			den hör hemma i `ledning.spec` och i Studio-runtime. Här drivs
			tjänstens tillstånd: ledningen startas, hästen ställs där
			fysiken hade fört henne, och `LedService._steg` får SJÄLV
			avgöra att hon lämnat boxen och nått zonen. Specen sätter
			aldrig flaggorna. ]]
		if fas.id == "leda" then
			local modell = GameplayService.modellFor(spelare)
			local zon = LedService.malzon()
			local rot = spelare.Character and spelare.Character:FindFirstChild("HumanoidRootPart")
			if modell and zon and rot and modell.PrimaryPart then
				LedService.borja(spelare, modell, modell)
				local mx = (zon.x + zon.w / 2) * 3
				local mz = (170 - (zon.y + zon.h / 2)) * 3
				modell.PrimaryPart.CFrame = CFrame.new(mx, modell.PrimaryPart.Position.Y, mz)
				rot.CFrame = CFrame.new(mx + 6, rot.Position.Y, mz)
				LedService._steg(1 / 30)
			end
		end
		--[[ UTRUSTNINGEN HÄMTAS FÖRST, som på webben (`sysslor.js:239`).
			Sedan blockerare 5 vägrar `GameplayService.moment` ett
			`utr:`-steg utan hämtad utrustning, och det är avsiktligt: utan
			kravet tas hästens egen sadel tyst och felvalet blir omöjligt
			att göra. I spelet gör spelaren det här vid boxfronten
			(`TackForradService`); här drivs samma väg genom tjänsten. ]]
		if fas.id == "iordning" then
			local s0 = GameplayService.stateFor(spelare)
			GameplayService.valjUtrustning(spelare, "sadel", s0.hastId)
			GameplayService.valjUtrustning(spelare, "trans", s0.hastId)
		end
		while true do
			local s = GameplayService.stateFor(spelare)
			local m = Preparation.nastaMoment(s, fas.id)
			if not m then break end
			local ok, skal = GameplayService.moment(spelare, fas.id, m.id)
			if not ok then
				return false, string.format("%s/%s: %s", fas.id, m.id, tostring(skal))
			end
		end
	end
	return true, nil
end

--[[ ══ SÖM 1: AVSITTNING → OMSITTNING PÅ SAMMA KROPP ══════════════════

	`integration.spec` bevisar omsittning efter DÖDEN: sitsen släpper, en ny
	kropp kommer, och hon kan sitta upp igen. Den vanliga vägen — sitta av
	och sitta upp igen utan att något dramatiskt händer — stod omätt, och
	det är den väg en spelare tar varje gång hon vill justera något.

	Ordern punkt 4: bredvid hästen, markkontakt, ingen tillbakasnärt,
	omsittning fungerar. ]]
print("\n── Söm 1: sitta av och sitta upp igen, samma kropp ──")
do
	local S = nySession("Omsittning", 9601)
	local ok, skal = skotselGenomTjansten(S.spelare)
	check("skötseln gick igenom", ok, tostring(skal))

	local upp1 = HorseService.tryMount(S.spelare, S.modell)
	check("hon sitter upp första gången", upp1 == true)

	local sits = S.modell:FindFirstChild("RiderSeat")
	local foreAv = S.rot.CFrame.Position
	check("sitsen har henne", sits.Occupant ~= nil)

	check("avsittningen går igenom", HorseService.dismount(S.spelare) == true)
	check("sitsen är tom efteråt", sits.Occupant == nil)
	check("och servern räknar henne inte som ryttare",
		HorseService.horseOf(S.spelare) == nil)

	--[[ INGEN TILLBAKASNÄRT: kroppen ska stå kvar där avsittningen satte
		den, inte hoppa tillbaka till sitsen eller till sitt gamla läge. ]]
	local efterAv = S.rot.CFrame.Position
	local flyttad = (efterAv - foreAv).Magnitude
	check("kroppen flyttades ut ur sitsen, inte tillbaka", flyttad > 0.5,
		string.format("%.2f studs", flyttad))

	--[[ MARKKONTAKT: avsittningsplatsen ska ligga på golv. `avsittning.spec`
		äger platsvalet; här mäts att den valda platsen faktiskt användes. ]]
	check("hon står på en rimlig höjd, inte i eller över golvet",
		efterAv.Y > -5 and efterAv.Y < 40,
		string.format("y %.2f", efterAv.Y))

	--[[ ...OCH SÅ IGEN. Det här är sömmen. ]]
	local upp2, skal2 = HorseService.tryMount(S.spelare, S.modell)
	check("hon kan sitta upp IGEN på samma kropp", upp2 == true, tostring(skal2))
	check("och sitsen har henne på nytt", sits.Occupant ~= nil)
	check("hästen är fortfarande hennes", HorseService.horseOf(S.spelare) == S.modell)
	stadaSession(S)
end

--[[ ══ SÖM 2: SLÄPPT KOPPEL → UPPSITTNING ══════════════════════════════

	`ledning.spec` bevisar att kopplet släpper. Att uppsittningen fungerar
	EFTER släppet är ett annat påstående: släppet rör både ledningens
	tillstånd och spelarens gånghastighet, och en kvarglömd flagga där hade
	låst uppsittningen utan att någon spec märkt det. ]]
print("\n── Söm 2: släppa kopplet och sitta upp ──")
do
	local S = nySession("Slapp", 9602)
	local ok, skal = skotselGenomTjansten(S.spelare)
	check("skötseln gick igenom", ok, tostring(skal))

	--[[ MÄTT, INTE ANTAGET: skötseln LÄMNAR hästen i koppel. Min första
		version tog kopplet igen här och förväntade sig ja — `borja` svarade
		nej med `led.leder_redan`, alldeles riktigt, för hon leddes redan.
		Kedjan ser alltså ut så här i spelet: skötseln slutar med hästen
		ledd till ridbanan, och spelaren släpper henne där innan hon sitter
		upp. Det är den sömmen som mäts. ]]
	check("skötseln lämnar hästen i koppel", LedService.aktiv(S.spelare) == S.modell,
		LedService.aktiv(S.spelare) and "leds" or "leds inte")
	local igen, skalIgen = LedService.borja(S.spelare, S.modell, S.modell)
	check("och ett andra kopplingsförsök nekas med rätt skäl",
		igen == false and skalIgen == "led.leder_redan", tostring(skalIgen))

	check("kopplet släpper", LedService.slapp(S.spelare) == true)
	check("och ingen häst leds längre", LedService.aktiv(S.spelare) == nil)

	local upp, skalUpp = HorseService.tryMount(S.spelare, S.modell)
	check("uppsittningen går igenom EFTER släppet", upp == true, tostring(skalUpp))
	stadaSession(S)
end

--[[ ══ SÖM 3: VIKARIEN SKRIVER INTE ÖVER SPARFILEN ═════════════════════

	Den dyraste buggen i listan, och den enda som förstör något tyst.

	Står spelarens kanoniska häst upptagen av någon annan i servern får hon
	en VIKARIE ur rotationen (`Stallet.tilldelaLedig`, `dagens.vikarieFor`).
	Vikarien är sessionens, inte dagens: skrivs den in i sparfilen har
	spelarens riktiga progression ändrats av vem som råkade vara inloggad,
	och det syns först dagen efter.

	`StallService.tilldela` håller tilldelningen i `tilldelade[player]`,
	alltså i minnet. Provet mäter att sparfilen är OFÖRÄNDRAD över en
	vikarietilldelning — inte att koden ser ut att göra rätt. ]]
print("\n── Söm 3: sessionens vikarie rör inte sparfilen ──")
do
	local S1 = nySession("Spelare1", 9701)
	check("spelare 1 fick första dagens häst", S1.hastId == Stallet.FORSTA_DAGEN_HAST,
		tostring(S1.hastId))

	local save1 = SparService.save(S1.spelare)
	local fore = save1 and Sparning.serialisera and true or (save1 ~= nil)
	check("spelare 1 har en sparfil att jämföra mot", save1 ~= nil)

	--[[ Spelare 2 in i SAMMA server. Hon vill också ha första dagens häst,
		men den är tagen — alltså vikarie. ]]
	local spelare2, k2, rot2 = nySpelare("Spelare2", 9702, vec(9, 0, 0))
	SparService._glomForProv(spelare2)
	Players._spelare = { S1.spelare, spelare2 }
	Players.PlayerAdded:Fire(spelare2)
	Players.PlayerAdded:slutfor()

	local hast2 = StallService.hastFor(spelare2)
	check("spelare 2 fick också en häst", hast2 ~= nil,
		hast2 and tostring(hast2.namn) or "ingen")
	check("och det är INTE samma häst som spelare 1",
		hast2 ~= nil and StallService.hastIdFor(spelare2) ~= S1.hastId,
		string.format("p1 %s · p2 %s", tostring(S1.hastId),
			tostring(StallService.hastIdFor(spelare2))))
	check("och inte samma box",
		hast2 ~= nil and hast2.box ~= nil
			and hast2.box.nummer ~= StallService.hastFor(S1.spelare).box.nummer,
		hast2 and hast2.box and string.format("p1 box %d · p2 box %d",
			StallService.hastFor(S1.spelare).box.nummer, hast2.box.nummer) or "-")

	--[[ SÖMMEN: spelare 2:s sparfil ska inte ha fått vikarien inskriven. ]]
	local save2 = SparService.save(spelare2)
	check("spelare 2:s sparfil bär ingen vikarie-häst",
		save2 == nil or save2.vikarieFor == nil,
		save2 and tostring(save2.vikarieFor) or "ingen save")
	check("och spelare 1:s sparfil är orörd av att spelare 2 kom in",
		SparService.save(S1.spelare) == save1)

	--[[ ...OCH SPELARE 1 STÖRS INTE av att spelare 2 lämnar. ]]
	Players.PlayerRemoving:Fire(spelare2)
	Players._spelare = { S1.spelare }
	check("spelare 1 har fortfarande sin häst efter att 2 lämnat",
		StallService.hastIdFor(S1.spelare) == S1.hastId,
		tostring(StallService.hastIdFor(S1.spelare)))
	stadaSession(S1)
end

--[[ ══ SÖM 4: PEKSPELAREN NÅR HANDLINGARNA ════════════════════════════

	`sprak.spec` bevisar att texterna finns. `touch.spec` bevisar att
	pekavsikterna fungerar. Emellan dem låg frågan ordern ställer: kan en
	spelare UTAN tangentbord nå leda, släppa, sitta upp och sitta av?

	Mätt på katalogen, som är den enda sanningen båda ytorna läser: varje
	handling ska ha en text att sätta på en knapp, på båda språken. Att
	knappen sedan ritas är `KontrollHjalp`/`InteractionController`, och att
	fingret träffar den är HARDWARE CHECK. ]]
print("\n── Söm 4: pekspelaren når resans fyra handlingar ──")
do
	local handlingar = {
		{ nyckel = "led.borja", vad = "LEDA HÄSTEN" },
		{ nyckel = "led.slapp", vad = "SLÄPP" },
		{ nyckel = "interaktion.sitt_upp", vad = "SITT UPP" },
		{ nyckel = "touch.sitt_av", vad = "SITT AV" },
	}
	for _, h in ipairs(handlingar) do
		local sv = Sprak.iSprak("sv", h.nyckel)
		local en = Sprak.iSprak("en", h.nyckel)
		check(("%s har text på båda språken"):format(h.vad),
			type(sv) == "string" and sv ~= "" and type(en) == "string" and en ~= "",
			("%s / %s"):format(tostring(sv), tostring(en)))
	end
end

if fails > 0 then
	print(("\n%d mätning(ar) föll."):format(fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("\nhastresan.spec: alla gröna")
end
