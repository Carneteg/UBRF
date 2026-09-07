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
	knapp ~= nil and knapp.Visible == true and knapp.Text == "Prova igen",
	('("%s" · synlig %s)'):format(knapp and knapp.Text or "-",
		tostring(knapp and knapp.Visible)))

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
	knapp ~= nil and knapp.Visible == true and knapp.Text == "Nästa övning"
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

if fel > 0 then
	print(("\n%d mätningar föll."):format(fel))
else
	print("\nAlla mätningar gick igenom.")
end
