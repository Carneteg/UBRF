--!strict
--[[
	GENERERAD FIL — handredigera inte.

	Skrivs av tools/exportera-ridkanon.mjs ur webbens src/model.js och
	src/riding/telemetri.js. Det här är WEBBENS ridkanon, exporterad så att
	Roblox-sidan har något exakt att mäta sig mot i stället för att två
	uppsättningar siffror driver isär i tysthet.

	Modulen STYR ingenting i Roblox — Gaits.luau är fortfarande Roblox
	egna, intrimmade tabell. Den här filen används av
	roblox/tests/paritet.spec.luau för att jämföra, och för att lista de
	avvikelser som faktiskt finns. Att jämna ut en avvikelse är ett
	produktbeslut och ändrar ridkänslan; det görs aldrig av en export.

	Kör om med:  node tools/exportera-ridkanon.mjs
]]

local RidKanon = {}

--[[ Webbens gångartsordning. Roblox har en gångart till (fyrsprång);
     paritetsspecen kräver att den här är ett PREFIX av Roblox ordning. ]]
RidKanon.ORDNING = { "halt", "skritt", "trav", "galopp" }

--[[ Vilken Roblox-gångart varje webbgångart motsvarar. ]]
RidKanon.MOTSVARIGHET = {
	halt = "halt",
	skritt = "walk",
	trav = "trot",
	galopp = "canter",
}

--[[ Gångartsbanden ur src/model.js (Gait.G). min/max i m/s, norm är
     gångartens normaltempo, steg är webbens steglängdsfaktor.

     upp/ner är G02-A.1 P3: hur många m/s² hon tar respektive släpper
     INOM gångarten. De är Roblox egna accel/retard, portade till
     webben — inte en andra uppsättning tal. Paritetsspecen kräver
     att de fortfarande är identiska, och att de skiljer sig åt
     mellan gångarterna: en gemensam siffra vore just den vikt per
     gångart som P3 införde. ]]
RidKanon.BAND = {
	halt = { min = 0, max = 0.2, norm = 0, steg = 0, upp = 3.2, ner = 5.5 },
	skritt = { min = 0.9, max = 2, norm = 1.45, steg = 0.46, upp = 2.6, ner = 3.4 },
	trav = { min = 2.4, max = 4.3, norm = 3.2, steg = 0.63, upp = 2.9, ner = 3.6 },
	galopp = { min = 4.6, max = 8, norm = 5.6, steg = 1, upp = 3.4, ner = 3.2 },
}

--[[ Hysteres: hur långt utanför sitt band en gångart får leva kvar. ]]
RidKanon.HYSTERES = 0.35

--[[ Trösklarna, MÄTTA ur Gait.forTempo — inte avskrivna. ]]
RidKanon.TROSKLAR = {
	{ under = 0.25, gangart = "skritt" },
	{ under = 2.2, gangart = "trav" },
	{ under = 4.45, gangart = "galopp" },
}

--[[ STYRKANONEN ur stegaRitt() i src/game.js. Kurvaturtaket i 1/m vid
     full styrning, gångarternas svängfaktorer, och tidskonstanterna för
     att lägga sig i respektive räta upp sig ur en båge. ]]
RidKanon.KAPPA_MAX = 0.42
RidKanon.KAPPA_TAU_LAGG = 0.13
RidKanon.KAPPA_TAU_RATA = 0.19
RidKanon.SVANGFAKTOR = {
	halt = 1,
	skritt = 1,
	trav = 0.82,
	galopp = 0.52,
}

--[[ Gångartens TRÖGHET i styrningen (G02-A.1 P3). Multiplikator på
     KAPPA_TAU_LAGG/RATA. SVANGFAKTOR säger hur snävt hon KAN svänga,
     den här hur snabbt bågen ändras. Speglas i Gaits.svangTau. ]]
RidKanon.SVANGTAU = {
	halt = 1,
	skritt = 0.85,
	trav = 1,
	galopp = 1.45,
}

--[[ Telemetrins fältnamn, lästa ur ett riktigt anrop av ridTelemetri. ]]
RidKanon.TELEMETRI_FALT = { "balans", "beddGangart", "cue", "cueAlder", "fart", "fokus", "gangart", "gangartGlapp", "hast", "hjalper", "iOvergang", "kurvatur", "mjukhet", "onskadFart", "overgangstid", "rytm", "spanning", "steglangd", "svangradie", "uppsutten", "vridhastighet" }

--[[ Fält som är HÄRLEDDA, inte mätta. Ärlig märkning för G02-B. ]]
RidKanon.HARLEDDA = { "balans", "fokus" }

return RidKanon
