--!nostrict
--[[ KLIENTENS EGNA FLÖDE — får spelaren lektionen?

	Senior review av 09e07da, blocker 1: UgnetaController var byggd men
	inte inkopplad. Ett prov som anropar controllern själv bevisar bara
	att funktionen finns — samma fel som läktarprovet som mätte
	hjälpfunktionen i stället för spelarens väg (#114).

	Den här specen kör därför init.client.luau. Skriptet har redan
	laddats när raderna nedan körs: det har kopplat sig till
	RenderStepped, MountChanged och CharacterRemoving. Provet FYRAR de
	signalerna, precis som Roblox gör, och läser vad spelaren ser.

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

--[[ SITT UPP genom produktionens egen väg: servern säger att
	uppsittningen ändrats, precis som HorseService gör. ]]
local Net = Networking
local hast = __makeHastModell("Bamse")
--[[ Hästen står i världen. Klientloopen sitter av om riggen inte gör det,
     och det är en riktig gren — inte en bänkdetalj. ]]
hast.Parent = workspace
prova("bänken har en hästmodell klienten kan bygga en rigg av",
	select(1, RigAdapter.build(hast)) ~= nil,
	tostring(select(2, RigAdapter.build(hast))))

Net.get("MountChanged").OnClientEvent:Fire(hast, player)
prova("uppsittningen startade lektionen",
	LektionController.pagar() == true,
	("(pågår %s)"):format(tostring(LektionController.pagar())))

--[[ KÖR LOOPEN. Ingen egen stegning av LektionController — signalen
	fyras och klientens egen callback gör resten. ]]
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
local rubrik = hitta("Rubrik")
prova("övningen presenteras i klientens loop",
	rubrik ~= nil and rubrik.Text ~= "",
	('("%s")'):format(rubrik and rubrik.Text or "-"))

--[[ Rid tills försök 1 är slut. Ekipaget står stilla i bänken, men
	telemetrin skrivs varje bildruta av samma rad som i produktion —
	det är kedjan som provas, inte ridkänslan. ]]
bildrutor(LektionController.PAUS_SEK + Lektion.FORSOK_SEK + 0.5)
local kort, knapp = hitta("Kort"), hitta("Knapp")
prova("efter försök 1 visas kortet, utan att provet rört controllern",
	kort ~= nil and kort.Visible == true,
	("(Visible %s)"):format(tostring(kort and kort.Visible)))
prova("med Prova igen",
	knapp ~= nil and knapp.Visible == true,
	("(knapp %s)"):format(tostring(knapp and knapp.Visible)))
local pass = LektionController.pass()
prova("och lifecyclen står på försök 2 av samma övning",
	pass ~= nil and pass.forsokNr == 2 and pass.ix == 1,
	("(övning %d, försök %d)"):format(pass and pass.ix or -1,
		pass and pass.forsokNr or -1))

bildrutor(LektionController.PAUS_SEK + Lektion.FORSOK_SEK + 0.5)
local punkt = hitta("Punkt1")
pass = LektionController.pass()
prova("försök 2 bedöms och lektionen går vidare",
	pass ~= nil and pass.ix == 2 and punkt ~= nil and punkt.Text ~= "",
	("(övning %d · \"%s\")"):format(pass and pass.ix or -1,
		punkt and punkt.Text or "-"))

--[[ LIVE-CHIPET ska ha kommit någon gång under de två försöken, av sig
	självt — ingen i provet har anropat `live`. ]]
local antal = 0
for _ in sedda do antal += 1 end
prova("live-chipet kom av sig självt under ritten", antal > 0,
	("(%d olika cues)"):format(antal))

--[[ SÄKERHET: karaktären försvinner. Det är en riktig säkerhetshändelse
	i produktionen — och lärarytan ska släckas i samma andetag. ]]
bildrutor(2)
player.CharacterRemoving:Fire(player.Character)
prova("karaktären försvinner → ingen lektion pågår",
	LektionController.pagar() == false,
	("(pågår %s)"):format(tostring(LektionController.pagar())))
prova("och lärarytan är släckt",
	hitta("Kort").Visible == false and hitta("Live").Visible == false,
	("(kort %s · chip %s)"):format(tostring(hitta("Kort").Visible),
		tostring(hitta("Live").Visible)))

--[[ …och loopen får inte väcka något efter avsittningen. ]]
bildrutor(3)
prova("en avsutten spelare får ingen undervisning",
	hitta("Kort").Visible == false and hitta("Live").Visible == false,
	"(kort och chip fortsatt släckta)")

if fel > 0 then
	print(("\n%d mätningar föll."):format(fel))
else
	print("\nAlla mätningar gick igenom.")
end
