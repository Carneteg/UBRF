--!nostrict
--[[ KLIENTENS EGNA FLÖDE — får spelaren lektionen, och KAN hon välja?

	Senior review av 09e07da, blocker 1: UgnetaController var byggd men
	inte inkopplad. Ett prov som anropar controllern själv bevisar bara
	att funktionen finns — samma fel som läktarprovet som mätte
	hjälpfunktionen i stället för spelarens väg (#114).

	Senior review av c53a2c7: provet mätte fortfarande fel sak. Det såg
	texten "Prova igen" och att state gick vidare — men knappen var en
	TextLabel utan input och lifecyclen gick vidare på en timer. Provet
	kunde alltså inte skilja ett val från en nedräkning.

	Därför mäter den här specen två saker den förut inte mätte:
	  1. att INGENTING händer medan kortet väntar (ingen mätning, inget
	     försök 2), och
	  2. att det som får det att hända är en VERKLIG inmatning —
	     UserInputService.InputBegan och knappens eget Activated, alltså
	     tangent/gamepad och mus/finger.

	Specen kör init.client.luau. Skriptet har redan laddats när raderna
	nedan körs: det har kopplat sig till RenderStepped, MountChanged,
	InputBegan och CharacterRemoving. Provet FYRAR de signalerna, precis
	som Roblox gör, och läser vad spelaren ser.

	GRÄNSEN, uttalad: bänken är inte en klient. GUI:t byggs mot stubbar,
	så den här specen säger ingenting om hur kortet SER UT eller känns i
	Studio — bara att kedjan finns och att den bär rätt innehåll. ]]

local fel = 0
local function prova(vad, ok, detalj)
	if ok then
		print(("  OK   %s%s"):format(vad, if detalj then " " .. detalj else ""))
	else
		fel += 1
		print(("  FEL  %s%s"):format(vad, if detalj then " " .. detalj else ""))
	end
end

print("\nKLIENTENS FLÖDE — LEKTIONEN GENOM RENDERSTEPPED\n")

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

prova("klienten kopplade sig till RenderStepped",
	#RunService.RenderStepped._lyssnare > 0,
	("(%d lyssnare)"):format(#RunService.RenderStepped._lyssnare))

local gui = player._gui
local function hitta(namn)
	local function sok(nod)
		if type(nod) ~= "table" then return nil end
		if nod.Name == namn then return nod end
		for _, b in ipairs(nod._barn or {}) do
			local t = sok(b)
			if t then return t end
		end
		return nil
	end
	return sok(gui)
end

--[[ EN VERKLIG TANGENTTRYCKNING. Samma signal Roblox fyrar, med
	gameProcessedEvent = false — provet rör inte LektionController. ]]
local function tryck(tangent)
	UserInputService.InputBegan:Fire({ KeyCode = Enum.KeyCode[tangent] }, false)
end

--[[ SITT UPP genom produktionens egen väg. ]]
local Net = Networking
local hast = __makeHastModell("Bamse")
hast.Parent = workspace
prova("bänken har en hästmodell klienten kan bygga en rigg av",
	select(1, RigAdapter.build(hast)) ~= nil,
	tostring(select(2, RigAdapter.build(hast))))

Net.get("MountChanged").OnClientEvent:Fire(hast, player)
prova("uppsittningen startade lektionen",
	LektionController.pagar() == true,
	("(pågår %s)"):format(tostring(LektionController.pagar())))

local dt = 1 / 30
local sedda = {}
local function bildrutor(sek)
	for _ = 1, math.floor(sek / dt) do
		RunService.RenderStepped:Fire(dt)
		local c = hitta("Live")
		if c and c.Visible and c.Text ~= "" then sedda[c.Text] = true end
	end
end

bildrutor(1)
local rubrik, knapp = hitta("Rubrik"), hitta("Knapp")
prova("övningen presenteras i klientens loop",
	rubrik ~= nil and rubrik.Text ~= "",
	('("%s")'):format(rubrik and rubrik.Text or "-"))
prova("knappen är en riktig TextButton, inte en skylt",
	knapp ~= nil and knapp.ClassName == "TextButton"
		and knapp.Activated ~= nil,
	("(%s · Activated %s)"):format(knapp and knapp.ClassName or "-",
		tostring(knapp and knapp.Activated ~= nil)))

--[[ VÄNTAN MÄTER INGENTING. Här satt den gamla timern: efter sex
	sekunder började mätningen av sig själv, oavsett om ryttaren var
	redo. Rid långt förbi ett helt försök och kräv att ingenting rört
	sig. ]]
bildrutor(Lektion.FORSOK_SEK + 4)
local pass = LektionController.pass()
prova("kortet väntar på spelaren — ingen mätning under tiden",
	LektionController.lage() == "presentation" and pass.tid == 0
		and pass.prov.n == 0,
	('(läge "%s" · tid %.1f · prov %d)'):format(LektionController.lage(),
		pass.tid, pass.prov.n))

--[[ SPELAREN STARTAR. Tangenten, genom klientens egen InputBegan. ]]
tryck("R")
prova("R startar försöket — tangenten går genom klientens inmatning",
	LektionController.lage() == "rider",
	('(läge "%s")'):format(LektionController.lage()))

bildrutor(Lektion.FORSOK_SEK + 0.5)
local kort = hitta("Kort")
knapp = hitta("Knapp")
pass = LektionController.pass()
prova("efter försök 1 visas kortet, utan att provet rört controllern",
	kort ~= nil and kort.Visible == true,
	("(Visible %s)"):format(tostring(kort and kort.Visible)))
prova("med en tryckbar Prova igen",
	knapp ~= nil and knapp.Visible == true
		and string.find(knapp.Text, "Prova igen", 1, true) ~= nil,
	('("%s" · synlig %s)'):format(knapp and knapp.Text or "-",
		tostring(knapp and knapp.Visible)))
--[[ …och spelaren ser att tangenten finns. Bänken är en skrivbordsklient
	(KeyboardEnabled), så ledtexten ska vara R. ]]
prova("och knappen visar att R gör samma sak",
	knapp ~= nil and string.find(knapp.Text, "(R)", 1, true) ~= nil,
	('("%s")'):format(knapp and knapp.Text or "-"))

--[[ FÖRSÖK 2 FÅR INTE BÖRJA AV SIG SJÄLVT. Det här är blockeraren. ]]
local tidVidKort = pass.tid
bildrutor(12)
pass = LektionController.pass()
prova("försök 2 startar INTE utan spelarens handling",
	pass.forsokNr == 1 and LektionController.lage() == "efter"
		and pass.tid == tidVidKort,
	("(försök %d · läge \"%s\" · tid oförändrad %s)"):format(pass.forsokNr,
		LektionController.lage(), tostring(pass.tid == tidVidKort)))

--[[ MUS OCH FINGER: knappens eget Activated, samma väg en tryckning på
	skärmen tar. ]]
knapp.Activated:Fire()
pass = LektionController.pass()
prova("knappen startar försök 2 — och mätningen nollställs",
	pass.forsokNr == 2 and pass.ix == 1 and pass.tid == 0
		and pass.prov.n == 0 and LektionController.lage() == "rider",
	("(övning %d · försök %d · tid %.1f · prov %d)"):format(pass.ix,
		pass.forsokNr, pass.tid, pass.prov.n))
prova("och kortet är borta när ritten återupptas",
	kort.Visible == false, ("(Visible %s)"):format(tostring(kort.Visible)))

bildrutor(Lektion.FORSOK_SEK + 0.5)
knapp = hitta("Knapp")
prova("efter försök 2 väntar en jämförelse med Nästa övning",
	knapp ~= nil and knapp.Visible == true
		and string.find(knapp.Text, "Nästa övning", 1, true) ~= nil
		and LektionController.lage() == "efter",
	('("%s" · läge "%s")'):format(knapp and knapp.Text or "-",
		LektionController.lage()))

tryck("ButtonY")
pass = LektionController.pass()
prova("gamepadens Y går vidare till nästa övning",
	pass.ix == 2 and pass.forsokNr == 1,
	("(övning %d, försök %d)"):format(pass.ix, pass.forsokNr))

bildrutor(1)
local punkt = hitta("Punkt1")
prova("nästa övning presenteras",
	punkt ~= nil and punkt.Text ~= "" and LektionController.lage() == "presentation",
	('("%s" · läge "%s")'):format(punkt and punkt.Text or "-",
		LektionController.lage()))

--[[ LIVE-CHIPET ska ha kommit någon gång under de två försöken, av sig
	självt — ingen i provet har anropat `live`. ]]
local antal = 0
for _ in sedda do antal += 1 end
prova("live-chipet kom av sig självt under ritten", antal > 0,
	("(%d olika cues)"):format(antal))

--[[ SÄKERHET medan kortet väntar. Karaktären försvinner — en riktig
	säkerhetshändelse — och både ytan OCH den väntande fortsättningen
	ska vara borta. Annars kunde ett R-tryck efteråt starta ett försök
	på en häst som inte finns. ]]
prova("lektionen väntar på spelaren just nu",
	LektionController.vantar() == true, "(inför säkerhetsavbrottet)")
player.CharacterRemoving:Fire(player.Character)
prova("karaktären försvinner → ingen lektion pågår",
	LektionController.pagar() == false,
	("(pågår %s)"):format(tostring(LektionController.pagar())))
prova("och lärarytan är släckt",
	hitta("Kort").Visible == false and hitta("Live").Visible == false,
	("(kort %s · chip %s)"):format(tostring(hitta("Kort").Visible),
		tostring(hitta("Live").Visible)))
--[[ HUD:ens EGEN flagga måste läsas här. `LektionController.vantar()`
	returnerar false så snart passet är borta, alltså även om HUD:en
	fortfarande stod och väntade — en kontroll som bara läser den är
	sann oavsett om säkerheten städade eller inte. Det är precis en
	sådan vakuumkontroll det här provet finns för att undvika, och en
	falsifiering (säkerhet som lämnar kvar väntan) visade att den förra
	formuleringen inte blev röd. ]]
prova("den väntande fortsättningen kastades med",
	UgnetaController.vantar() == false
		and LektionController.vantar() == false
		and LektionController.fortsatt() == false,
	("(HUD väntar %s · lektionen väntar %s · fortsatt %s)"):format(
		tostring(UgnetaController.vantar()),
		tostring(LektionController.vantar()),
		tostring(LektionController.fortsatt())))

--[[ …och varken loopen eller tangenten får väcka något efteråt. ]]
bildrutor(3)
tryck("R")
knapp.Activated:Fire()
prova("en avsutten spelare får ingen undervisning",
	hitta("Kort").Visible == false and hitta("Live").Visible == false
		and LektionController.pagar() == false,
	"(kort och chip fortsatt släckta, R och knappen utan verkan)")

--[[ ══ SÄKERHET FÖRE SERVERSVAR ═══════════════════════════════════
	Senior review av b303530, punkt 1. Förut anropades
	`DismountRequest:InvokeServer()` FÖRE `dismount()`. `InvokeServer`
	yieldar, så ett långsamt eller uteblivet svar lämnade lektionen igång
	och lärarytan uppe efter att spelaren bett om att få sitta av.

	Provet mäter ORDNINGEN, inte bara slutresultatet: fjärranropet
	rapporterar vad lektionen hade för läge i det ögonblick det kördes.
	Var städningen redan gjord är svaret false. Anropet kastar dessutom,
	vilket är det värsta realistiska serverfallet — klienten får inte
	återuppliva något på ett uteblivet svar. ]]
do
	local spar = { anrop = 0, pagarVidAnrop = nil, kortVidAnrop = nil }
	local fjarr = Net.get("DismountRequest")
	fjarr.InvokeServer = function()
		spar.anrop += 1
		spar.pagarVidAnrop = LektionController.pagar()
		spar.kortVidAnrop = hitta("Kort").Visible
		error("serversvar uteblev")
	end

	--[[ Sitt upp igen och rid en bit, så att det FINNS en lektion att
	     städa bort när avsittningen begärs. ]]
	Net.get("MountChanged").OnClientEvent:Fire(hast, player)
	bildrutor(1)
	tryck("R")
	bildrutor(3)
	prova("en lektion pågår inför avsittningen",
		LektionController.pagar() == true,
		("(pågår %s)"):format(tostring(LektionController.pagar())))

	tryck("E")
	prova("serveranropet skedde EFTER den lokala städningen",
		spar.anrop == 1 and spar.pagarVidAnrop == false
			and spar.kortVidAnrop == false,
		("(anrop %d · pågick %s · kort %s)"):format(spar.anrop,
			tostring(spar.pagarVidAnrop), tostring(spar.kortVidAnrop)))
	prova("ett uteblivet serversvar återupplivar ingenting",
		LektionController.pagar() == false
			and hitta("Kort").Visible == false and hitta("Live").Visible == false
			and LektionController.fortsatt() == false,
		"(lektion av, kort och chip släckta, ingen väntan kvar)")

	--[[ UPPREPAD AVSITTNING: varken dubbel städning eller en andra
	     begäran till servern. ]]
	tryck("E")
	tryck("E")
	prova("upprepad avsittning ger ingen ny begäran",
		spar.anrop == 1,
		("(%d anrop totalt)"):format(spar.anrop))

	--[[ SENT INPUT EFTER AVBROTT får inte starta något. ]]
	tryck("R")
	bildrutor(2)
	prova("sent R efter avbrottet startar ingen lektion",
		LektionController.pagar() == false and hitta("Kort").Visible == false,
		"(fortsatt avsutten)")
end

--[[ ══ LEDTEXTEN FÖLJER INMATNINGEN, INTE PLATTFORMEN ═════════════
	Tobias beslut 2026-09-07: knappen ska visa att R fungerar. Men en ren
	pekenhet ska INTE få en bokstav hon inte kan trycka på. Provet växlar
	inmatningsförmågorna och läser vad knappen faktiskt säger. ]]
do
	local usv = game:GetService("UserInputService")
	local kb, gp, touch = usv.KeyboardEnabled, usv.GamepadEnabled, usv.TouchEnabled

	local function knappTextMed(tangentbord, gamepad, pek)
		usv.KeyboardEnabled, usv.GamepadEnabled, usv.TouchEnabled =
			tangentbord, gamepad, pek
		UgnetaController.visa("Rubrik", { "punkt" }, true, "Prova igen")
		return hitta("Knapp").Text
	end

	local medTgb = knappTextMed(true, false, false)
	local medPad = knappTextMed(false, true, false)
	local baraPek = knappTextMed(false, false, true)

	prova("tangentbord ger R-ledtext",
		string.find(medTgb, "(R)", 1, true) ~= nil, ('("%s")'):format(medTgb))
	prova("gamepad ger Y-ledtext i stället",
		string.find(medPad, "(Y)", 1, true) ~= nil
			and string.find(medPad, "(R)", 1, true) == nil,
		('("%s")'):format(medPad))
	prova("en ren pekenhet får ingen bokstav hon inte kan trycka på",
		string.find(baraPek, "(R)", 1, true) == nil
			and string.find(baraPek, "(Y)", 1, true) == nil
			and string.find(baraPek, "Prova igen", 1, true) ~= nil,
		('("%s")'):format(baraPek))

	usv.KeyboardEnabled, usv.GamepadEnabled, usv.TouchEnabled = kb, gp, touch
	UgnetaController.sakerhetTarOver()
end

--[[ ══ G02-D: RIDANALYSEN GENOM SAMMA LOOP ════════════════════════

	DEN HÄR DELEN ÄR REGRESSIONEN FÖR DET SOM FÖLL I CI.

	Felet var inte i produktionskoden och inte i posen: `ReplayController`
	och `HorseCore/Inspelning` lades bara till i EN av bunterna i
	roblox/tests/build.py (PARITET), inte i KLIENT. `LektionController`
	require:ar bägge, så i klientbunten blev require:t nil — och det syntes
	först som "attempt to index nil with 'aktiv'" ur RenderStepped-loopen,
	alltså långt ifrån orsaken.

	Provet nedan går därför genom init.client.luau och dess RenderStepped,
	precis som resten av den här specen. Faller en modul ur någon av
	listorna dör loopen här igen, med samma fel, och specen blir röd.

	FALSIFIERAT: raderna nedan har körts med `ReplayController` borttagen ur
	KLIENT-listan — då dör bunten på require:t innan den första mätningen,
	exakt som CI-körningen gjorde. De har också körts med `Inspelning`
	borttagen ur samma lista, med samma utfall.

	GRÄNSEN, uttalad: bänken kör ingen fysik. `humanoid:Move` spelas in men
	flyttar ingen rigg, så hästen står stilla om ingen flyttar henne. Där
	ritten behöver en UTSTRÄCKNING flyttar provet riggens root självt — det
	är vad Roblox-fysiken hade gjort — och det står här så att ingen läser
	panelens bana som ett bevis för rörelsemodellen. Den mäts i
	movement.spec. ]]
do
	print("\n── G02-D: RIDANALYS, INSPELNING OCH VALEN ──")

	prova("Inspelning finns i klientbunten",
		type(Inspelning) == "table" and type(Inspelning.ny) == "function",
		("(%s)"):format(type(Inspelning)))
	prova("ReplayController finns i klientbunten",
		type(ReplayController) == "table" and type(ReplayController.aktiv) == "function",
		("(%s)"):format(type(ReplayController)))

	--[[ ── Inspelningens kontrakt, utan loop ────────────────────────── ]]

	prova("bara övningar MED definition spelas in",
		Inspelning.spelasIn("storvolt") == true
			and Inspelning.spelasIn("trav_skritt") == true
			and Inspelning.spelasIn("horn") == false
			and Inspelning.spelasIn(nil) == false,
		"(storvolt/trav_skritt ja · horn nej)")
	prova("versionen kommer ur kanonen, inte ur en siffra i koden",
		Inspelning.version("storvolt") == RidKanon.INSPELNING.OVNING.storvolt.version,
		("(v%s)"):format(tostring(Inspelning.version("storvolt"))))
	prova("en okänd övning ger ingen inspelare alls",
		Inspelning.ny("finns_inte") == nil, "(nil)")

	--[[ POSEN. Beställningens punkt 3: en pose där positionen är omätbar
	     men riktningen ÄR mätt ska behålla riktningen. Ett tidigare utkast
	     kastade hela posen på ett trasigt fält. ]]
	do
		local r = Inspelning.ny("storvolt", "bamse")
		local nan = 0 / 0
		Inspelning.sampla(r, 0.06, { gangart = "trav" },
			{ x = nan, z = 5.5, yaw = 1.25 })
		local s1 = r.post.sampel[1]
		prova("trasig x kastar INTE en giltig yaw",
			s1 ~= nil and s1.x == nil and s1.z == 5.5 and s1.yaw == 1.25,
			("(x %s · z %s · yaw %s)"):format(tostring(s1 and s1.x),
				tostring(s1 and s1.z), tostring(s1 and s1.yaw)))

		Inspelning.sampla(r, 0.06, { gangart = "trav" },
			{ x = 2, z = 3, yaw = math.huge })
		local s2 = r.post.sampel[2]
		prova("oändlig yaw blir okänd — inte noll",
			s2 ~= nil and s2.yaw == nil and s2.x == 2,
			("(yaw %s · x %s)"):format(tostring(s2 and s2.yaw), tostring(s2 and s2.x)))

		Inspelning.sampla(r, 0.06, { gangart = "trav" }, nil)
		local s3 = r.post.sampel[3]
		prova("en helt saknad pose ger okänt läge — inte origo",
			s3 ~= nil and s3.x == nil and s3.z == nil and s3.yaw == nil,
			"(x/z/yaw nil)")

		--[[ Klockan. En sträng är inte ett tal, och en bildruta på 4,2 s
		     efter en flikväxling är inte en ritt. ]]
		local fore = #r.post.sampel
		Inspelning.sampla(r, "0.06", { gangart = "trav" }, { x = 1, z = 1, yaw = 0 })
		Inspelning.sampla(r, 4.2, { gangart = "trav" }, { x = 1, z = 1, yaw = 0 })
		Inspelning.sampla(r, -0.06, { gangart = "trav" }, { x = 1, z = 1, yaw = 0 })
		prova("sträng-dt, jättesteg och negativ tid skriver ingenting",
			#r.post.sampel == fore, ("(%d sampel, oförändrat)"):format(#r.post.sampel))
		prova("och en inspelare som är nil svarar false i stället för att krascha",
			Inspelning.sampla(nil, 0.06, {}, nil) == false, "(false)")
	end

	--[[ VERSIONSKOMPATIBILITET. Tre svar, aldrig ett tyst ja. ]]
	do
		local r = Inspelning.ny("storvolt", "bamse")
		Inspelning.sampla(r, 0.06, { gangart = "trav" }, { x = 0, z = 0, yaw = 0 })
		local post = Inspelning.avsluta(r)
		prova("en färsk post är läsbar", Inspelning.lasbar(post).lage == "ok",
			("(%s)"):format(Inspelning.lasbar(post).lage))

		local gammal = table.clone(post); gammal.ovningVersion = 0
		local g = Inspelning.lasbar(gammal)
		prova("en äldre övningsversion är läsbar men MÄRKT",
			g.ok == true and g.lage == "gammal" and g.skal ~= "",
			('("%s")'):format(g.skal))

		local framtid = table.clone(post); framtid.schema = 99
		local f = Inspelning.lasbar(framtid)
		prova("ett okänt schema avvisas med skäl",
			f.ok == false and f.lage == "nej" and f.skal ~= "",
			('("%s")'):format(f.skal))
		prova("en okänd övning avvisas med skäl",
			Inspelning.lasbar({ schema = 1, ovning = "finns_inte" }).lage == "nej",
			"(nej)")
		prova("panelen öppnar inte en post den inte får tolka",
			ReplayController.oppna(framtid) == false
				and ReplayController.oppna({ schema = 1, ovning = "storvolt",
					ovningVersion = 1, sampel = {} }) == false
				and ReplayController.aktiv() == false,
			"(false · false · inte aktiv)")
	end

	--[[ ── Genom loopen ─────────────────────────────────────────────── ]]

	Net.get("MountChanged").OnClientEvent:Fire(hast, player)
	prova("uppsittningen startade en ny lektion",
		LektionController.pagar() == true,
		("(pågår %s)"):format(tostring(LektionController.pagar())))

	--[[ Riggens root, så att provet kan ge ritten en utsträckning. ]]
	local root = hast:FindFirstChild("HumanoidRootPart")

	--[[ DRIVNINGSRÄKNAREN. Pausen skyddar EN sak: att MovementController
	     inte driver hästen medan spelaren läser. Drivningen syns i
	     humanoidens `Move`, alltså i produktionens egen väg ut mot Roblox,
	     och det är den här räknaren som mäter den.

	     Ett tidigare utkast läste i stället `pass.tid`, och det provet gick
	     ALDRIG att göra rött: `LektionController.steg` returnerar redan
	     tidigt när kortet väntar, så tiden står stilla oavsett om
	     init.client fryser ridningen eller inte. Falsifieringen visade det
	     — pausen togs bort och provet var fortfarande grönt. ]]
	local hum = hast:FindFirstChild("Humanoid")
	local drivningar = 0
	local origMove = hum.Move
	hum.Move = function(self, ...) drivningar += 1; return origMove(self, ...) end
	local vinkel = 0
	local function ridBildrutor(sek)
		for _ = 1, math.floor(sek / dt) do
			--[[ En 10 m volt, körd av provet eftersom bänken saknar fysik. ]]
			vinkel += dt * 0.6
			root.Position = vec(10 * math.cos(vinkel), 3, 10 * math.sin(vinkel))
			root.CFrame = cframe(root.Position, vec(0, 0, 1), vinkel)
			RunService.RenderStepped:Fire(dt)
		end
	end

	--[[ Kort som visats efter en övning UTAN inspelning, och hur många av
	     dem som ändå erbjöd "Se ritten". Räknas i `tillOvning` eftersom det
	     är den som passerar de oinspelade övningarna. ]]
	local seddaUtanInspelning, seddaMedKnappUtanInspelning = 0, 0

	--[[ Rid fram till storvolten genom spelarens egna handlingar. ]]
	local function tillOvning(id)
		for _ = 1, 80 do
			local p = LektionController.pass()
			if not p or p.klar then return false end
			if Lektion.ovningId(p) == id and LektionController.lage() == "presentation" then
				return true
			end
			if LektionController.lage() == "rider" then
				ridBildrutor(Lektion.FORSOK_SEK + 0.6)
			elseif LektionController.vantar() then
				if LektionController.lage() == "efter"
					and not Inspelning.spelasIn(Lektion.ovningId(p)) then
					seddaUtanInspelning += 1
					local k = hitta("SeRitten")
					if k and k.Visible then seddaMedKnappUtanInspelning += 1 end
				end
				tryck("R")
			else
				ridBildrutor(0.4)
			end
		end
		return false
	end

	prova("spelaren rider sig fram till 20 m volten",
		tillOvning("storvolt") == true,
		('(övning "%s")'):format(tostring(Lektion.ovningId(LektionController.pass()))))

	--[[ FÖRSÖK 1 PÅ STORVOLTEN. ]]
	tryck("R")
	ridBildrutor(Lektion.FORSOK_SEK + 0.6)

	local seRitten = hitta("SeRitten")
	local gaVidare = hitta("GaVidare")
	prova("efter försök 1 erbjuds Se ritten",
		seRitten ~= nil and seRitten.ClassName == "TextButton"
			and seRitten.Visible == true and seRitten.Activated ~= nil,
		("(%s · synlig %s)"):format(seRitten and seRitten.ClassName or "-",
			tostring(seRitten and seRitten.Visible)))
	prova("och Gå vidare — tre vägar ut, inte en",
		gaVidare ~= nil and gaVidare.Visible == true
			and hitta("Knapp").Visible == true,
		("(Se ritten %s · Gå vidare %s · huvudknapp %s)"):format(
			tostring(seRitten and seRitten.Visible),
			tostring(gaVidare and gaVidare.Visible),
			tostring(hitta("Knapp").Visible)))

	--[[ KONTROLLMÄTNINGEN FÖRST: räknaren måste ha gått upp under ritten,
	     annars mäter frysprovet nedan ingenting alls. ]]
	local drivnaUnderRitt = drivningar
	prova("hästen drevs under själva ritten — räknaren mäter något",
		drivnaUnderRitt > 0, ("(%d Move-anrop)"):format(drivnaUnderRitt))

	--[[ HÄSTEN STÅR STILLA MEDAN KORTET VÄNTAR. Utan pausen red hon vidare
	     bakom panelen och försöket hon tittade på hann bli ogiltigt. ]]
	do
		for _ = 1, 60 do RunService.RenderStepped:Fire(dt) end
		prova("hästen drivs INTE medan kortet väntar",
			drivningar == drivnaUnderRitt,
			("(%d Move-anrop, oförändrat under 60 bildrutor)"):format(drivningar))
	end

	--[[ SE RITTEN genom fingret — knappens eget Activated. ]]
	seRitten.Activated:Fire()
	prova("Se ritten öppnar analysen",
		LektionController.replayAktiv() == true
			and hitta("Bana") ~= nil,
		("(aktiv %s)"):format(tostring(LektionController.replayAktiv())))
	prova("kortets väntan lever kvar bakom panelen — valet är inte gjort",
		UgnetaController.vantar() == true,
		("(väntar %s)"):format(tostring(UgnetaController.vantar())))

	do
		local bana = hitta("Bana")
		local nu, fore = 0, 0
		for _, b in ipairs(bana._barn) do
			if b.Name == "Nu" then nu += 1 elseif b.Name == "Fore" then fore += 1 end
		end
		prova("ritten är ritad ur riktiga sampel",
			nu > 10, ("(%d punkter)"):format(nu))
		prova("men inget spöke efter FÖRSTA försöket — ingen påhittad ideallinje",
			fore == 0 and ReplayController.lage().harFore == false,
			("(%d spökpunkter)"):format(fore))
		prova("och panelen säger varför i stället för att lämna ett hål",
			hitta("Status").Text ~= "",
			('("%s")'):format(hitta("Status").Text))
	end

	--[[ UPPSPELNINGEN ÄNDRAR ALDRIG POSTEN. ]]
	do
		local lage0 = ReplayController.lage()
		local sek0 = lage0.sekunder
		for _ = 1, 120 do RunService.RenderStepped:Fire(dt) end
		local lage1 = ReplayController.lage()
		prova("uppspelningen rör sig framåt av sig själv",
			lage1.tid > lage0.tid, ("(%.2f → %.2f s)"):format(lage0.tid, lage1.tid))
		prova("och posten är oförändrad — uppspelningen är ren avläsning",
			lage1.sekunder == sek0, ("(%.2f s före och efter)"):format(sek0))

		ReplayController.hoppa(-5)
		prova("hoppa bakåt klampas till noll, inte till negativ tid",
			ReplayController.lage().tid >= 0,
			("(%.2f s)"):format(ReplayController.lage().tid))
		prova("halv fart går att välja",
			ReplayController.vaxlaFart() == 0.5 and ReplayController.vaxlaFart() == 1,
			"(0,5× → 1×)")
	end

	--[[ RIDNINGEN ÄR FRYST ÄVEN MEDAN ANALYSEN STÅR UPPE. Samma räknare,
	     samma skäl. ]]
	do
		local fore = drivningar
		for _ = 1, 60 do RunService.RenderStepped:Fire(dt) end
		prova("hästen drivs inte bakom ridanalysen",
			drivningar == fore,
			("(%d Move-anrop, oförändrat)"):format(drivningar))
	end

	--[[ TILLBAKA. Tangenten stänger PANELEN, inte kortet bakom den. ]]
	tryck("R")
	prova("R stänger analysen och lämnar valet kvar",
		LektionController.replayAktiv() == false
			and UgnetaController.vantar() == true
			and hitta("Kort").Visible == true,
		("(aktiv %s · väntar %s)"):format(
			tostring(LektionController.replayAktiv()),
			tostring(UgnetaController.vantar())))

	--[[ FÖRSÖK 2, sedan spöket. ]]
	tryck("R")
	prova("Prova igen startar försök 2 på samma övning",
		LektionController.pass().forsokNr == 2
			and Lektion.ovningId(LektionController.pass()) == "storvolt",
		("(försök %d)"):format(LektionController.pass().forsokNr))
	ridBildrutor(Lektion.FORSOK_SEK + 0.6)

	tryck("T")
	prova("T öppnar analysen efter försök 2",
		LektionController.replayAktiv() == true,
		("(aktiv %s)"):format(tostring(LektionController.replayAktiv())))
	do
		local bana = hitta("Bana")
		local fore = 0
		for _, b in ipairs(bana._barn) do if b.Name == "Fore" then fore += 1 end end
		prova("nu ligger FÖRRA försöket bakom som spöke — spelarens eget",
			fore > 10 and ReplayController.lage().harFore == true,
			("(%d spökpunkter)"):format(fore))
	end

	--[[ AVSITTNING MEDAN ANALYSEN STÅR UPPE. Säkerhet vinner. ]]
	player.CharacterRemoving:Fire(player.Character)
	prova("karaktären försvinner → analysen stängs med allt annat",
		LektionController.replayAktiv() == false
			and LektionController.pagar() == false
			and hitta("Kort").Visible == false,
		("(aktiv %s · pågår %s)"):format(
			tostring(LektionController.replayAktiv()),
			tostring(LektionController.pagar())))
	for _ = 1, 30 do RunService.RenderStepped:Fire(dt) end
	tryck("T")
	tryck("G")
	prova("och varken T eller G väcker något efteråt",
		LektionController.replayAktiv() == false
			and LektionController.pagar() == false,
		"(fortsatt avsutten)")

	--[[ SENT ÅTERANROP. `stang` får köra sitt återanrop EN gång, aldrig
	     två — inte ens när återanropet självt stänger igen. ]]
	do
		local r = Inspelning.ny("storvolt", "bamse")
		Inspelning.sampla(r, 0.06, { gangart = "trav" }, { x = 0, z = 0, yaw = 0 })
		Inspelning.sampla(r, 0.06, { gangart = "trav" }, { x = 1, z = 1, yaw = 0 })
		local post = Inspelning.avsluta(r)
		local n = 0
		local aterintratt = false
		ReplayController.oppna(post, nil, function()
			n += 1
			--[[ ETT återinträde, inte oändligt många. Med den felaktiga
			     ordningen (kör återanropet innan `stangFn` nollas) blir
			     `n` 2 och raden nedan röd — utan bottenlös rekursion som
			     hade dödat hela specen i stället för att peka på felet. ]]
			if not aterintratt then
				aterintratt = true
				ReplayController.stang()
			end
		end)
		ReplayController.stang()
		ReplayController.stang()
		prova("stängningens återanrop körs exakt en gång",
			n == 1, ("(%d anrop)"):format(n))
		prova("och en stängd panel svarar false i stället för att göra något",
			ReplayController.spelaPausa() == false
				and ReplayController.hoppa(1) == false
				and ReplayController.aktiv() == false,
			"(false · false · inte aktiv)")
	end

	--[[ MINDRE RÖRELSE. Har spelaren bett om det startar panelen PAUSAD
	     i stället för att sätta igång en markör som rör sig av sig själv. ]]
	do
		local gs = game:GetService("GuiService")
		local r = Inspelning.ny("storvolt", "bamse")
		for i = 1, 40 do
			Inspelning.sampla(r, 0.06, { gangart = "trav" }, { x = i, z = i, yaw = 0 })
		end
		local post = Inspelning.avsluta(r)

		gs.ReducedMotionEnabled = false
		ReplayController.oppna(post)
		local normal = ReplayController.lage().spelar
		ReplayController.stang()

		gs.ReducedMotionEnabled = true
		ReplayController.oppna(post)
		local reducerad = ReplayController.lage().spelar
		ReplayController.stang()
		gs.ReducedMotionEnabled = false

		prova("normalt startar analysen av sig själv", normal == true, "(spelar)")
		prova("med mindre rörelse startar den pausad — inget innehåll går förlorat",
			reducerad == false and #post.sampel > 10,
			("(pausad · %d sampel kvar att scrubba)"):format(#post.sampel))
	end

	--[[ ══ GÅ VIDARE BEDÖMER EN GÅNG, INTE TVÅ ═══════════════════════
		Ett tidigare utkast lät panelen sätta en hoppa-flagga och återinträda
		i lifecyclen. Då bedömdes momentet två gånger och godkäntgränsen
		flyttade sig tyst. Provet mäter historiken, inte skärmen. ]]
	do
		Net.get("MountChanged").OnClientEvent:Fire(hast, player)
		prova("en ny lektion att mäta Gå vidare i",
			LektionController.pagar() == true, "(pågår)")
		prova("och spelaren rider fram till storvolten igen",
			tillOvning("storvolt") == true,
			('(övning "%s")'):format(tostring(Lektion.ovningId(LektionController.pass()))))

		tryck("R")
		ridBildrutor(Lektion.FORSOK_SEK + 0.6)
		local p = LektionController.pass()
		local historik = p.historik["storvolt"]
		local efterForsok1 = if historik then #historik else 0
		prova("försök 1 är bedömt exakt en gång",
			efterForsok1 == 1, ("(%d post i historiken)"):format(efterForsok1))

		--[[ Gå vidare genom tangenten. ]]
		tryck("G")
		p = LektionController.pass()
		historik = p.historik["storvolt"]
		prova("Gå vidare hoppar över omridningen",
			Lektion.ovningId(p) ~= "storvolt" and p.forsokNr == 1,
			('(nu "%s", försök %d)'):format(tostring(Lektion.ovningId(p)), p.forsokNr))
		prova("men bedömningen räknas fortfarande EN gång, inte två",
			historik ~= nil and #historik == efterForsok1,
			("(%d post i historiken, oförändrat)"):format(
				if historik then #historik else -1))
		prova("och ingen andra väntan blev kvar",
			UgnetaController.gaVidare() == false,
			("(gaVidare %s)"):format(tostring(UgnetaController.gaVidare())))

		--[[ ══ DEN ANDRA ÖVNINGEN SPELAS OCKSÅ IN ═══════════════════════
			Beställningen säger `storvolt` OCH `trav_skritt`. Att bara prova
			den ena hade lämnat den andra på ett påstående. Spelaren rider
			vidare genom passet med sina egna handlingar. ]]
		prova("spelaren rider vidare till övergången trav → skritt",
			tillOvning("trav_skritt") == true,
			('(övning "%s")'):format(tostring(Lektion.ovningId(LektionController.pass()))))
		--[[ Vägen dit går genom `horn`, som INTE har någon definition och
		     därför inte spelas in. Kortet efter den får inget "Se ritten" —
		     en knapp som öppnar någon ANNAN övnings ritt vore värre än
		     ingen knapp alls. ]]
		prova("en oinspelad övning erbjuder inte att se ritten",
			seddaUtanInspelning > 0 and seddaMedKnappUtanInspelning == 0,
			("(%d kort efter oinspelad övning, %d med Se ritten)"):format(
				seddaUtanInspelning, seddaMedKnappUtanInspelning))

		tryck("R")
		ridBildrutor(Lektion.FORSOK_SEK + 0.6)
		prova("också trav → skritt går att se om",
			hitta("SeRitten").Visible == true,
			("(Se ritten %s)"):format(tostring(hitta("SeRitten").Visible)))
		tryck("T")
		prova("och analysen öppnar på DEN övningens ritt, inte voltens",
			LektionController.replayAktiv() == true
				and ReplayController.lage().sekunder > 0,
			("(%.1f s)"):format(ReplayController.lage().sekunder))

		--[[ ══ TILLGÄNGLIGHET ═══════════════════════════════════════════
			Panelen ska gå att använda med finger, tangent och gamepad.
			Provet läser knapparna som de faktiskt byggdes. ]]
		do
			local knappar = { "Spela", "Bak", "Fram", "Fart", "Stang" }
			local alla, minHojd = true, math.huge
			for _, namn in knappar do
				local k = hitta(namn)
				if not k or k.ClassName ~= "TextButton" or k.Activated == nil then
					alla = false
				else
					minHojd = math.min(minHojd, k.Size.Y.Offset)
				end
			end
			prova("alla fem kontroller är riktiga knappar med Activated",
				alla, ("(%d knappar)"):format(#knappar))
			--[[ 44 px är minsta träffyta som går att peka på med ett finger.
			     Familjen spelar på iPad och telefon. ]]
			prova("och de är minst 44 px höga — fingret ska träffa",
				minHojd >= 44, ("(minsta höjd %d px)"):format(minHojd))

			--[[ ══ RYMS KONTROLLERNA PÅ EN TELEFON? ═══════════════════
				Den här mätningen fanns INTE i förra rundan, och det var
				felet. Provet mätte knapparnas höjd men aldrig om raden fick
				plats. Panelen är 90 % av viewporten minus 24 px; med fem
				fasta 104 px-knappar, mellanrum och en 120 px tidsruta krävde
				raden 670 px och rymdes först vid 1024 px viewport. På en
				390 px telefon fanns 327 px — knapparna gick inte att nå, och
				sviten var grön.

				Nu mäts det som faktiskt betyder något: att VARJE knapp
				ligger helt innanför raden, på varje skärmstorlek familjen
				spelar på. ]]
			local cam = game:GetService("Workspace").CurrentCamera
			local vpFore = cam.ViewportSize

			local function matVid(bredd, hojd)
				cam.ViewportSize = { _typ = "Vector2", X = bredd, Y = hojd }
				ReplayController.tillampaLayout()
				local L = ReplayController.layout()
				local utanfor, minB, minH = 0, math.huge, math.huge
				for _, namn in knappar do
					local k = hitta(namn)
					if k then
						local hoger = k.Position.X.Offset + k.Size.X.Offset
						if hoger > L.bredd + 0.5 then utanfor += 1 end
						minB = math.min(minB, k.Size.X.Offset)
						minH = math.min(minH, k.Size.Y.Offset)
					end
				end
				return { utanfor = utanfor, minB = minB, minH = minH,
					rader = L.rader, perRad = L.perRad, bredd = L.bredd }
			end

			--[[ Kontraktet läses ur modulen, inte skrivet av här: ett prov
			     som bär sin egen kopia av minimimåttet kan glida ifrån
			     koden utan att något blir rött. ]]
			local L = ReplayController.layout()

			--[[ De skärmar familjen faktiskt spelar på. ]]
			local skarmar = {
				{ namn = "telefon 390×844", b = 390, h = 844 },
				{ namn = "liten telefon 320×568", b = 320, h = 568 },
				{ namn = "iPad porträtt 768×1024", b = 768, h = 1024 },
				{ namn = "iPad landskap 1024×768", b = 1024, h = 768 },
				{ namn = "skrivbord 1920×1080", b = 1920, h = 1080 },
			}
			for _, sk in skarmar do
				local m = matVid(sk.b, sk.h)
				--[[ Tre krav, inte ett: ingen knapp utanför raden, ingen
				     under 44 px hög, och ingen smalare än KNAPP_MIN.
				     Breddkravet är det som skiljer en LÄSBAR knapp från en
				     som råkar rymmas — en falsifiering där raden aldrig
				     bryts klarade nämligen "ryms" genom att krympa varje
				     knapp till 60 px, och då mätte provet inget. ]]
				prova(("alla kontroller ryms på %s"):format(sk.namn),
					m.utanfor == 0 and m.minH >= 44 and m.minB >= L.minBredd,
					("(%d utanför · %d×%d px minst, krav %d×%d · %d rad(er) à %d)"):format(
						m.utanfor, m.minB, m.minH, L.minBredd, 44,
						m.rader, m.perRad))
			end

			--[[ …och att provet MÄTER något: den smalaste skärmen måste
			     faktiskt ha tvingat fram fler rader än den bredaste. Utan
			     den här kontrollen hade en layout som ignorerade bredden
			     kunnat gå grön på alla fem raderna ovan. ]]
			local smal = matVid(390, 844)
			local bred = matVid(1920, 1080)
			prova("den smala skärmen bryter raden, den breda gör det inte",
				smal.rader > bred.rader and bred.rader == 1,
				("(telefon %d rader · skrivbord %d rad)"):format(
					smal.rader, bred.rader))

			cam.ViewportSize = vpFore
			ReplayController.tillampaLayout()

			--[[ LEDTEXTEN FÖLJER INMATNINGEN, inte plattformen — samma regel
			     som Ugnetas kort. En ren pekenhet ska inte få en bokstav hon
			     inte kan trycka på. ]]
			local usv = game:GetService("UserInputService")
			local kb, gp, touch = usv.KeyboardEnabled, usv.GamepadEnabled, usv.TouchEnabled
			local post = ReplayController.lage()
			local function stangOppna(tangentbord, gamepad, pek)
				usv.KeyboardEnabled, usv.GamepadEnabled, usv.TouchEnabled =
					tangentbord, gamepad, pek
				ReplayController.stang()
				local r = Inspelning.ny("storvolt", "bamse")
				for i = 1, 30 do
					Inspelning.sampla(r, 0.06, { gangart = "trav" }, { x = i, z = i, yaw = 0 })
				end
				ReplayController.oppna(Inspelning.avsluta(r))
				return hitta("Stang").Text
			end
			local medTgb = stangOppna(true, false, false)
			local medPad = stangOppna(false, true, false)
			local baraPek = stangOppna(false, false, true)
			prova("tangentbord ger R-ledtext på Tillbaka",
				string.find(medTgb, "(R)", 1, true) ~= nil, ('("%s")'):format(medTgb))
			prova("gamepad ger Y-ledtext i stället",
				string.find(medPad, "(Y)", 1, true) ~= nil
					and string.find(medPad, "(R)", 1, true) == nil,
				('("%s")'):format(medPad))
			prova("en ren pekenhet får ingen bokstav hon inte kan trycka på",
				string.find(baraPek, "(R)", 1, true) == nil
					and string.find(baraPek, "(Y)", 1, true) == nil
					and string.find(baraPek, "Tillbaka", 1, true) ~= nil,
				('("%s")'):format(baraPek))
			usv.KeyboardEnabled, usv.GamepadEnabled, usv.TouchEnabled = kb, gp, touch
			ReplayController.stang()
			if post then end
		end

		--[[ Städa upp efter oss: nästa block ska inte ärva en pågående ritt. ]]
		player.CharacterRemoving:Fire(player.Character)
	end
end

if fel > 0 then
	print(("\n%d mätningar föll."):format(fel))
else
	print("\nAlla mätningar gick igenom.")
end
