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


	--[[ ══ §9 `ride` GENOM DEN RIKTIGA LOOPEN ═══════════════════════════

		Lokal Studio-QA, §9: uppsutten häst, `gaitUp = true` når
		rörelselagret, och hästen rör sig **0,00 studs på 3,6 s**.

		`movement.spec` driver `MovementController` DIREKT och bevisar att
		den tar hästen ur halt och 4,4 m framåt. Controllern är alltså inte
		trasig — och just därför kunde felet ligga kvar: **ingen spec körde
		den riktiga ridloopen.** Den har två grenar, och den ena kastar
		avsikten:

		    if LektionController.vantar() or LektionController.replayAktiv() then
		        Input.consume()          -- flankerna nollställs … och kastas
		        return                   -- movement:step körs ALDRIG
		    end

		Att `Input.consume()` körs varje bildruta bevisar därför ingenting
		om att hästen drivs — den körs i BÅDA grenarna. Här mäts i stället
		`WalkSpeed` på riggen efter att den riktiga loopen kört sina
		bildrutor, och hela kontraktet mäts: pausen ska hålla, och den ska
		SLÄPPA.

		MÄTT: kortet väntar inte vid uppsittningen — det kommer EN bildruta
		in i ritten. Det var därför en avläsning vid uppsittning visade
		`vantar = false` och ändå fryst häst. ]]
	do
		prova("vid uppsittningen väntar inget kort ännu",
			LektionController.vantar() == false,
			("(vantar %s)"):format(tostring(LektionController.vantar())))

		--[[ Gångartsknappen genom produktionens egen väg in, inte genom en
			hemmagjord intent. ]]
		local d0 = drivningar
		Input.touchGait(true)
		ridBildrutor(2.5)

		prova("kortet tar över ritten en bildruta in",
			LektionController.vantar() == true,
			("(vantar %s · %d drivningar)"):format(
				tostring(LektionController.vantar()), drivningar - d0))

		--[[ KORTET SKA SÄGA VARFÖR (produktbeslut 13:29). Pausen får finnas
			— men inte som en oförklarad fryst häst. Knappen ska säga vad ett
			tryck gör, och den ska göra det på spelarens språk: den stod
			hårdkodad som "Börja" och gav en engelsk spelare ett svenskt ord. ]]
		do
			local kn = hitta("UgnetaKnapp") or hitta("Knapp")
			local txt = kn and kn.Text or ""
			prova("kortets knapp förklarar att den startar lektionen",
				txt:find(Sprak.iSprak("sv", "ugneta.borja_lektionen"), 1, true) ~= nil,
				('("%s")'):format(txt))

			--[[ …och på engelska. Samma mätning, andra locale — annars är
				det bara en svensk konstant som råkar stämma. ]]
			local fore = Sprak.eget()
			Sprak.satLocale("en-us")
			local en = Sprak.t("ugneta.borja_lektionen")
			prova("och samma knapp finns på engelska",
				en == "Continue to start the lesson" and en ~= Sprak.iSprak("sv", "ugneta.borja_lektionen"),
				('("%s")'):format(en))
			Sprak.satLocale(fore)
		end
		--[[ PAUSEN SKA HÅLLA. Rider hon vidare bakom kortet blir det
			försök spelaren just läser om ogiltigt medan hon läser. ]]
		prova("och medan kortet väntar står hästen still",
			hum.WalkSpeed == 0,
			("(WalkSpeed %.2f)"):format(hum.WalkSpeed))

		--[[ …OCH DEN SKA SLÄPPA. Det är den här raden som hade fällt en
			häst som inte gick att rida: gick hon inte igång efter att
			kortet kvitterats vore loopen bruten, inte pausande. ]]
		local slapptes = LektionController.fortsatt()
		local d1 = drivningar
		Input.touchGait(true)
		ridBildrutor(2.5)
		prova("när kortet kvitteras rider hon igång på riktigt",
			slapptes == true and hum.WalkSpeed > 0 and drivningar - d1 > 60,
			("(kvitterat %s · WalkSpeed %.2f · %d drivningar)"):format(
				tostring(slapptes), hum.WalkSpeed, drivningar - d1))
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

		--[[ ══ KONTROLLHJÄLPEN ═══════════════════════════════════════
			Tobias fråga på #151: hur sitter man upp, byter gångart och
			hoppar? Hjälpen svarar — och provet ser till att den svarar
			SANT. En hjälptext som påstår en tangent som inte är bunden är
			värre än ingen hjälp: spelaren trycker och ingenting händer. ]]
		do
			prova("hjälpen finns i klientbunten",
				type(KontrollHjalp) == "table"
					and type(KontrollHjalp.rader) == "function",
				("(%s)"):format(type(KontrollHjalp)))

			local usv = game:GetService("UserInputService")
			local kb, gp, touch = usv.KeyboardEnabled, usv.GamepadEnabled, usv.TouchEnabled

			local function raderMed(tangentbord, gamepad, pek)
				usv.KeyboardEnabled, usv.GamepadEnabled, usv.TouchEnabled =
					tangentbord, gamepad, pek
				local m = {}
				for _, r in KontrollHjalp.rader() do m[r.vad] = r.reglage end
				return m
			end

			local tgb = raderMed(true, false, false)
			local pad = raderMed(false, true, false)
			local pek = raderMed(false, false, true)

			--[[ DE TRE FRÅGORNA, ordagrant. ]]
			prova("hjälpen svarar hur man sitter upp",
				tgb["Sitt upp / sitt av"] == "E",
				('("%s")'):format(tostring(tgb["Sitt upp / sitt av"])))
			prova("…hur man byter gångart",
				tgb["Högre gångart"] == "Shift" and tgb["Lägre gångart"] == "Ctrl",
				('("%s" / "%s")'):format(tostring(tgb["Högre gångart"]),
					tostring(tgb["Lägre gångart"])))
			prova("…och hur man hoppar",
				tgb["Hoppa"] == "Space", ('("%s")'):format(tostring(tgb["Hoppa"])))

			--[[ REGLAGEN FÖLJER INMATNINGEN. En ren pekenhet får aldrig en
			     bokstav hon inte kan trycka på. ]]
			prova("gamepad får sina egna reglage, inte tangenter",
				pad["Högre gångart"] == "R1" and pad["Hoppa"] == "A",
				('("%s" / "%s")'):format(tostring(pad["Högre gångart"]),
					tostring(pad["Hoppa"])))
			--[[ #162 iPad: pekytan har inte längre ▲ FRAMÅT. Gångarten väljs
			     på en NAMNGIVEN knapp, och hjälpen pekar därför på
			     knappgruppen. Raden mäter fortfarande samma sak — att
			     pekenheten får det den faktiskt ser på skärmen. ]]
			prova("en ren pekenhet får skärmknapparnas egna etiketter",
				pek["Hoppa"] == "HOPP"
					and pek["Högre gångart"] == "Gångartsknapparna"
					and pek["Lägre gångart"] == "SAKTA"
					and pek["Tygel (kontakt)"] == "TYGEL",
				('("%s" · "%s" · "%s")'):format(tostring(pek["Hoppa"]),
					tostring(pek["Högre gångart"]), tostring(pek["Lägre gångart"])))

			--[[ Den fria blicken finns BARA på pekytan. En rad utan reglage
			     på skrivbordet hade varit en handling spelaren inte kan
			     utföra; `bara`-fältet i RADER är det som håller den borta. ]]
			prova("blicken står i pekenhetens hjälp men inte på skrivbordet",
				pek["Se dig omkring"] == "Dra på högra halvan"
					and tgb["Se dig omkring"] == nil
					and pad["Se dig omkring"] == nil,
				('("%s" · tgb=%s)'):format(tostring(pek["Se dig omkring"]),
					tostring(tgb["Se dig omkring"])))
			do
				--[[ …och ingen rad för touch får bära en ensam versal
				     bokstav, alltså en tangent. ]]
				local bokstav = 0
				for _, v in pek do
					if type(v) == "string" and #v == 1
						and v:match("%u") ~= nil then bokstav += 1 end
				end
				prova("ingen tangentbokstav slinker in i pekenhetens hjälp",
					bokstav == 0, ("(%d bokstavsreglage)"):format(bokstav))
			end

			--[[ HJÄLPEN MÅSTE STÄMMA MED INPUT.LUAU. Provet fyrar de
			     tangenter hjälpen PÅSTÅR och läser vad inputlagret gjorde.
			     Ändrar någon en bindning utan att ändra hjälpen blir den
			     här raden röd — det är hela poängen med den. ]]
			usv.KeyboardEnabled, usv.GamepadEnabled, usv.TouchEnabled = true, false, false
			local ca = game:GetService("ContextActionService")._bound.HorseControl
			prova("inputlagret är bundet så att påståendena går att prova",
				type(ca) == "function", ("(%s)"):format(type(ca)))
			if type(ca) == "function" then
				--[[ Tangenten FYRAS UR HJÄLPENS EGEN TEXT, inte ur en
				     handskriven lista här. Ett tidigare utkast fyrade
				     LeftShift oavsett vad hjälpen påstod — då mätte provet
				     att Input.luau fungerar, inte att hjälpen talar sanning,
				     och en hjälp som pekade på fel tangent hade passerat. ]]
				local NAMN = {
					["Shift"] = Enum.KeyCode.LeftShift,
					["Ctrl"] = Enum.KeyCode.LeftControl,
					["Space"] = Enum.KeyCode.Space,
					["Q"] = Enum.KeyCode.Q,
					["F"] = Enum.KeyCode.F,
					["E"] = Enum.KeyCode.E,
				}
				local function fyraEnligtHjalpen(vad)
					local kod = NAMN[tgb[vad]]
					if not kod then return nil end
					ca("HorseControl", Enum.UserInputState.Begin, { KeyCode = kod })
					local i = Input.consume()
					ca("HorseControl", Enum.UserInputState.End, { KeyCode = kod })
					return i
				end
				local upp = fyraEnligtHjalpen("Högre gångart")
				local ner = fyraEnligtHjalpen("Lägre gångart")
				local hopp = fyraEnligtHjalpen("Hoppa")
				local tygel = fyraEnligtHjalpen("Tygel (kontakt)")
				prova("tangenten hjälpen anger för HÖGRE gångart gör det också",
					upp ~= nil and upp.gaitUp == true,
					('("%s" → gaitUp %s)'):format(tostring(tgb["Högre gångart"]),
						tostring(upp and upp.gaitUp)))
				prova("…och den för LÄGRE gångart",
					ner ~= nil and ner.gaitDown == true,
					('("%s" → gaitDown %s)'):format(tostring(tgb["Lägre gångart"]),
						tostring(ner and ner.gaitDown)))
				prova("…och den för HOPP",
					hopp ~= nil and hopp.jump == true,
					('("%s" → jump %s)'):format(tostring(tgb["Hoppa"]),
						tostring(hopp and hopp.jump)))
				prova("…och den för TYGEL",
					tygel ~= nil and tygel.rein > 0,
					('("%s" → rein %s)'):format(tostring(tgb["Tygel (kontakt)"]),
						tostring(tygel and tygel.rein)))
			end

			--[[ Panelen går att stänga utan tangentbord. ]]
			KontrollHjalp.visa()
			prova("hjälpen går att visa", KontrollHjalp.synlig() == true, "(synlig)")
			local stang = hitta("StangHjalp")
			prova("och att stänga med en riktig knapp — inte bara med H",
				stang ~= nil and stang.ClassName == "TextButton"
					and stang.Size.Y.Offset >= 44,
				("(%s · %d px hög)"):format(stang and stang.ClassName or "-",
					stang and stang.Size.Y.Offset or -1))
			if stang then stang.Activated:Fire() end
			prova("knappen stänger den",
				KontrollHjalp.synlig() == false, "(dold)")

			--[[ H växlar den — och hjälpen släcks när spelaren sitter av. ]]
			tryck("H")
			local eftertryck = KontrollHjalp.synlig()
			usv.KeyboardEnabled, usv.GamepadEnabled, usv.TouchEnabled = kb, gp, touch
			prova("H växlar hjälpen genom klientens egen inmatning",
				eftertryck == true, ("(synlig %s)"):format(tostring(eftertryck)))
		end

		--[[ Städa upp efter oss: nästa block ska inte ärva en pågående ritt. ]]
		player.CharacterRemoving:Fire(player.Character)
		prova("hjälpen släcks när ritten tar slut",
			KontrollHjalp.synlig() == false,
			("(synlig %s)"):format(tostring(KontrollHjalp.synlig())))
	end
end

--[[ ── HJÄLPEN GÅR ATT ÖPPNA IGEN (#161, P2-4b ur #153) ────────────

	Felet: hjälpen gick att STÄNGA på varje yta men bara att ÖPPNA med `H`.
	På en iPad utan tangentbord var den därmed en engångsruta. Blocket
	nedan mäter alla tre vägarna in, genom klientens EGEN inmatning — inte
	genom att anropa `KontrollHjalp.visa()`, som hade varit grönt även med
	en trasig bindning.

	Provet ligger EFTER avsittningen med flit. Det är hela poängen: den
	gamla lyssnaren började med `if processed or not ride then return end`,
	så `H` gjorde ingenting när man inte satt upp. Ett prov som körde
	medan ritten pågick hade varit grönt före rättelsen. ]]
do
	local usv = game:GetService("UserInputService")

	prova("ingen ritt pågår när återöppningen provas", true,
		"(H prövas i stallet, inte i sadeln)")

	KontrollHjalp.dolj()
	tryck("H")
	prova("H öppnar hjälpen ÄVEN när spelaren inte rider",
		KontrollHjalp.synlig() == true,
		("(synlig %s)"):format(tostring(KontrollHjalp.synlig())))
	tryck("H")
	prova("och stänger den igen", KontrollHjalp.synlig() == false)

	--[[ GAMEPADEN. Knappen läses ur modulen, inte skriven här: står det
		`DPadUp` på två ställen kan de glida isär, och då provar specen sin
		egen tabell i stället för bindningen. ]]
	--[[ Knappen läses ur modulen och inte ur en kopia här. Att den är en
		riktig `EnumItem` går inte att mäta i bänken — stubbens `Enum.KeyCode`
		svarar med namnet som sträng — så provet mäter det som FAKTISKT
		betyder något: att den är deklarerad, att den inte krockar, och att
		den öppnar hjälpen genom klientens egen lyssnare. ]]
	prova("hjälpen deklarerar en gamepadknapp",
		KontrollHjalp.GAMEPADKNAPP ~= nil,
		("(%s)"):format(tostring(KontrollHjalp.GAMEPADKNAPP)))

	--[[ ...och den knappen får INTE vara en av ridningens. Faller det här
		har någon lagt hjälpen på ett reglage som redan gör något — precis
		det #161 förbjuder. ]]
	local tagna = {
		[Enum.KeyCode.ButtonA] = "hopp", [Enum.KeyCode.ButtonB] = "halvhalt",
		[Enum.KeyCode.ButtonX] = "se ritten", [Enum.KeyCode.ButtonY] = "lektionen vidare",
		[Enum.KeyCode.ButtonR1] = "högre gångart", [Enum.KeyCode.ButtonL1] = "lägre gångart",
		[Enum.KeyCode.ButtonR2] = "tygel", [Enum.KeyCode.ButtonL2] = "sits",
		[Enum.KeyCode.Thumbstick1] = "styrning",
	}
	prova("gamepadknappen är inte redan tagen av ridningen",
		tagna[KontrollHjalp.GAMEPADKNAPP] == nil,
		("(%s → %s)"):format(tostring(KontrollHjalp.GAMEPADKNAPP),
			tostring(tagna[KontrollHjalp.GAMEPADKNAPP] or "ledig")))

	UserInputService.InputBegan:Fire({ KeyCode = KontrollHjalp.GAMEPADKNAPP }, false)
	prova("gamepadknappen öppnar hjälpen",
		KontrollHjalp.synlig() == true,
		("(synlig %s)"):format(tostring(KontrollHjalp.synlig())))
	UserInputService.InputBegan:Fire({ KeyCode = KontrollHjalp.GAMEPADKNAPP }, false)
	prova("och stänger den igen", KontrollHjalp.synlig() == false)

	--[[ ══ BLOCKERARE 2 (#162): GAMEPADEN MÅSTE KUNNA SITTA AV ══════
		`KontrollHjalp` sa `pad = "E"` för "Sitt upp / sitt av". `E` är en
		TANGENT. `begarAvsittning` var bara bunden till `E`, medan
		uppsittningen går genom en ProximityPrompt som handkontrollen når —
		alltså kom en gamepadspelare UPP på hästen och satt kvar där, med
		en hjälptext som pekade på ett reglage hon inte hade.

		Tre mätningar: knappen finns, den krockar inte, och den SITTER AV
		på riktigt genom klientens egen lyssnare. Plus ledtexten, som var
		den andra halvan av felet. ]]
	prova("avsittningen deklarerar en gamepadknapp",
		KontrollHjalp.AVSITTNING_GAMEPAD ~= nil,
		("(%s)"):format(tostring(KontrollHjalp.AVSITTNING_GAMEPAD)))
	prova("avsittningsknappen är inte tagen av ridningen",
		tagna[KontrollHjalp.AVSITTNING_GAMEPAD] == nil,
		("(%s → %s)"):format(tostring(KontrollHjalp.AVSITTNING_GAMEPAD),
			tostring(tagna[KontrollHjalp.AVSITTNING_GAMEPAD] or "ledig")))
	prova("och inte samma som hjälpens",
		KontrollHjalp.AVSITTNING_GAMEPAD ~= KontrollHjalp.GAMEPADKNAPP,
		("(av %s · hjälp %s)"):format(tostring(KontrollHjalp.AVSITTNING_GAMEPAD),
			tostring(KontrollHjalp.GAMEPADKNAPP)))

	--[[ LEDTEXTEN. Den ska beskriva gamepadens reglage, inte en tangent —
		och den ska följa bindningen. ]]
	local avrad = KontrollHjalp._rad("Sitt upp / sitt av")
	prova("hjälpraden finns", avrad ~= nil)
	prova("hjälpraden pekar inte på en tangent för gamepad",
		avrad ~= nil and avrad.pad ~= "E" and avrad.pad ~= avrad.tgb,
		("(pad %s · tgb %s)"):format(tostring(avrad and avrad.pad),
			tostring(avrad and avrad.tgb)))

	--[[ OCH DEN SITTER AV. Uppsittning genom produktionens MountChanged,
		avsittning genom klientens InputBegan — inga direktanrop. ]]
	do
		local fjarr2 = Net.get("DismountRequest")
		local gammal = fjarr2.InvokeServer
		local anrop = 0
		fjarr2.InvokeServer = function() anrop += 1; return true end

		Net.get("MountChanged").OnClientEvent:Fire(hast, player)
		bildrutor(1)
		UserInputService.InputBegan:Fire(
			{ KeyCode = KontrollHjalp.AVSITTNING_GAMEPAD }, false)
		prova("gamepadknappen begär avsittning",
			anrop == 1, ("(%d anrop)"):format(anrop))

		fjarr2.InvokeServer = gammal
	end

	--[[ PEKSKÄRMEN. `?`-knappen byggs bara när inmatningen behöver den, så
		provet växlar till en ren pekenhet och startar om modulen — samma
		beslut `KontrollHjalp.start` gör i produktion. ]]
	local kb, gp, touch = usv.KeyboardEnabled, usv.GamepadEnabled, usv.TouchEnabled
	usv.KeyboardEnabled, usv.GamepadEnabled, usv.TouchEnabled = false, false, true
	KontrollHjalp.start()
	local knapp = KontrollHjalp._oppnaKnapp()
	prova("en pekenhet får en permanent ?-knapp",
		knapp ~= nil and knapp.ClassName == "TextButton",
		("(%s)"):format(knapp and knapp.ClassName or "ingen"))
	prova("och den når 44 px i BÅDA led",
		knapp ~= nil and knapp.Size.X.Offset >= 44 and knapp.Size.Y.Offset >= 44,
		("(%d×%d px)"):format(knapp and knapp.Size.X.Offset or -1,
			knapp and knapp.Size.Y.Offset or -1))

	if knapp then
		knapp.Activated:Fire()
		prova("?-knappen öppnar hjälpen", KontrollHjalp.synlig() == true)
		prova("och göms medan panelen står uppe", knapp.Visible == false)
		local stang = hitta("StangHjalp")
		if stang then stang.Activated:Fire() end
		prova("panelens Stäng stänger den", KontrollHjalp.synlig() == false)
		prova("och ?-knappen kommer tillbaka", knapp.Visible == true,
			("(synlig %s)"):format(tostring(knapp.Visible)))
	end

	--[[ ══ TVÅ YTOR I SAMMA HÖRN ═══════════════════════════════════════
		`?`-knappen och skötselspårarens huvud bor båda uppe till höger, och
		de ritas av var sin modul som inte känner till varandra:
		`PreparationController` reserverar bandet med ett TAL, inte med ett
		`require` — bankerna som kör den laddar inte alltid `KontrollHjalp`.

		Talet mäts därför här, mot den knapp som faktiskt byggdes. Och det
		mäts i SKÄRMENS koordinater, inte i var sitt GUI-utrymme:
		`?`-knappens ScreenGui respekterar topbaren (`IgnoreGuiInset` av)
		medan spårarens ignorerar den, så knappen hamnar en topbar längre
		ned än dess egna tal säger. Glider talen isär ligger `?` över
		rubriken hos spelaren. ]]
	if knapp then
		local vp = game:GetService("Workspace").CurrentCamera.ViewportSize
		local inset = 0
		local hamta = (game:GetService("GuiService") :: any).GetGuiInset
		if type(hamta) == "function" then
			local topp = hamta(game:GetService("GuiService"))
			if topp and type(topp.Y) == "number" then inset = topp.Y end
		end
		--[[ Knappen är ankrad i övre HÖGRA hörnet (AnchorPoint 1,0), så
			dess högerkant är positionen och vänsterkanten en bredd in. ]]
		local hx1 = vp.X * knapp.Position.X.Scale + knapp.Position.X.Offset
		local hy0 = inset + vp.Y * knapp.Position.Y.Scale + knapp.Position.Y.Offset
		local h = { x0 = hx1 - knapp.Size.X.Offset, y0 = hy0,
			x1 = hx1, y1 = hy0 + knapp.Size.Y.Offset }
		local sp = PreparationController.layout().kompakt
		local krockar = sp.x0 < h.x1 and h.x0 < sp.x1
			and sp.y0 < h.y1 and h.y0 < sp.y1
		prova("?-knappen och skötselspåraren ligger inte över varandra",
			not krockar,
			("(? %d,%d–%d,%d · spårare %d,%d–%d,%d)"):format(
				h.x0, h.y0, h.x1, h.y1, sp.x0, sp.y0, sp.x1, sp.y1))
		--[[ MUTATIONEN: kan mätningen bli röd? Lägg knappen där spåraren
			står. Krockar den inte ens då mäter raden ingenting. ]]
		local gammalY = knapp.Position
		knapp.Position = UDim2.new(1, -12, 0, sp.y0 - inset + 4)
		local hy0b = inset + vp.Y * knapp.Position.Y.Scale + knapp.Position.Y.Offset
		local hb = { x0 = hx1 - knapp.Size.X.Offset, y0 = hy0b,
			x1 = hx1, y1 = hy0b + knapp.Size.Y.Offset }
		prova("MUTATION: flyttas ?-knappen ned i spåraren fälls mätningen",
			sp.x0 < hb.x1 and hb.x0 < sp.x1 and sp.y0 < hb.y1 and hb.y0 < sp.y1,
			("(? %d,%d–%d,%d)"):format(hb.x0, hb.y0, hb.x1, hb.y1))
		knapp.Position = gammalY
	end

	--[[ Hjälpen ska tala om SIN EGEN väg in, och rätt väg för rätt
		inmatning. En rad som säger "H" till en spelare utan tangentbord är
		precis det problemet raden beskriver. ]]
	local pek = {}
	for _, r in KontrollHjalp.rader() do pek[r.vad] = r.reglage end
	prova("hjälpen listar sig själv för pekskärm",
		pek["Den här hjälpen"] == "?",
		("(%s)"):format(tostring(pek["Den här hjälpen"])))

	usv.KeyboardEnabled, usv.GamepadEnabled, usv.TouchEnabled = kb, gp, touch
end

if fel > 0 then
	print(("\n%d mätningar föll."):format(fel))
else
	print("\nAlla mätningar gick igenom.")
end
