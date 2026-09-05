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

--[[ ÖVERGÅNGSFÖRLOPPET (G02-A.1 P2/P5, harmoniserat efter senior
     review 2026-09-05). Sekunder för en NEUTRAL häst; hästens egen
     tyngd respektive acceleration skalar därifrån med 1,0 i mitten.

     upp     per gångart man går TILL
     nerMjuk längden när ryttaren bara håller emot
     nerHart  längden vid full parad — bestämdheten interpolerar
     bytpunkt hur långt in i förloppet gångartsETIKETTEN byter

     Kurvan är samma på båda ytorna: mjukstegskurvan u²(3−2u),
     som börjar och slutar med noll lutning. Roblox har talen i
     Config.MOVEMENT.Transition och paritetsspecen jämför dem. ]]
RidKanon.OVERGANG = {
	upp = {
		skritt = 0.8,
		trav = 0.95,
		galopp = 1.2,
	},
	nerMjuk = 0.98,
	nerHart = 0.78,
	bytpunkt = 0.55,
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

--[[ Sekunder från rakt till full båge (G02-A.1 P4). Kurvaturen får
     inte ändras fortare än gångartens kurvaturtak delat med den här
     tiden. Speglas i Config.MOVEMENT.CurvatureRateTime. ]]
RidKanon.KAPPA_RAT_TID = 0.32

--[[ Kameraläget per gångart ur src/scen3d.js (G02-A.1 P6). bak i
     meter bakom hästen, hojd i meter, fov som tillägg i radianer.

     ABSOLUTA tal ska INTE vara lika på de två ytorna — rendering får
     vara plattformsspecifik. FÖRHÅLLANDET mellan gångarterna ska det,
     för det är förhållandet man känner. Paritetsspecen jämför därför
     kvoter mot skritt, inte tal mot tal. ]]
RidKanon.KAMERA = {
	halt = { bak = 3.78, hojd = 1.88, fov = 0 },
	skritt = { bak = 4.05, hojd = 1.95, fov = 0 },
	trav = { bak = 4.59, hojd = 2.1, fov = 0.017 },
	galopp = { bak = 5.13, hojd = 2.25, fov = 0.07 },
}

--[[ Telemetrins fältnamn, lästa ur ett riktigt anrop av ridTelemetri. ]]
RidKanon.TELEMETRI_FALT = { "balans", "beddGangart", "cue", "cueAlder", "energi", "fart", "fokus", "gangart", "gangartGlapp", "hast", "hjalper", "iOvergang", "kurvatur", "mjukhet", "onskadFart", "overgangstid", "paradAlder", "paradKvalitet", "rytm", "spanning", "steglangd", "svangradie", "svarAlder", "svarstid", "uppsutten", "vridhastighet" }

--[[ Fält som är HÄRLEDDA, inte mätta. Ärlig märkning för G02-B. ]]
RidKanon.HARLEDDA = {  }

--[[ HJÄLPERNAS SEMANTIK (G02-B punkt 1, src/riding/hjalper.js).

     Webbens ridning har fyra AXLAR — skänkel, styrning, tygel, sits —
     och ovanpå dem ridningens ord: innertygel, yttertygel, yttertygel-
     stöd, böjsida, vikt och paraden som en EGEN signal. Inner och
     ytter härleds ur styr- och tygelaxeln, så ingen ny kontroll behövs
     på någon yta; talen nedan är översättningen.

     Roblox rörelsekärna har ännu inget hjälplager alls (se
     Telemetri.SAKNAS). Kanonen exporteras hit FÖRE implementationen
     med flit: när Roblox-sidan bygger sina hjälper ska den läsa de här
     talen, inte skriva av dem. ]]
RidKanon.HJALP = {
	INNER_BER = 0.55,
	YTTER_SLAPP = 0.35,
	STYR_FULLT = 0.72,
	STOD_KRAV = 0.3,
	TYGEL_NEUTRAL = 0.34,
	BOJ_TROSKEL = 0.05,
	PARAD_GOLV = 0.2,
	PARAD_DRIV = 0.5,
	PARAD_BAND = 0.4,
	PARAD_TROSKEL = 0.05,
}

--[[ Hjälpernas fältnamn, lästa ur ett riktigt anrop av ridTelemetri. ]]
RidKanon.HJALP_FALT = { "bojSida", "innerTygel", "parad", "sits", "skankel", "styrning", "tygel", "vikt", "ytterTygel", "ytterstod" }

--[[ Hjälpfält som är HÄRLEDDA ur axlarna, inte egna kontroller. ]]
RidKanon.HJALP_HARLEDDA = { "innerTygel", "vikt", "ytterTygel", "ytterstod" }

--[[ HÄSTENS SVAR (G02-B punkt 2, src/riding/svar.js).

     Fördröjning, fokus, balans och energi som riktiga storheter. Webben
     har dem i modellen; Roblox har dem inte alls ännu, och det står som
     LUCKA i paritetsspecen i stället för att fyllas med gissningar.

     ENERGI_TAPP/ENERGI_ATER är per sekund och per gångart, med webbens
     namn. Roblox gångartsnamn översätts av RidKanon.MOTSVARIGHET. ]]
RidKanon.SVAR = {
	SVAR_BAS = 0.12,
	SVAR_TROG = 0.14,
	SVAR_FOKUS = 0.12,
	SVAR_ENERGI = 0.1,
	SVAR_KLAR = 0.1,
	SVAR_MIN = 0.06,
	SVAR_MAX = 0.48,
	FOKUS_BAS = 0.3,
	FOKUS_MJUK = 0.3,
	FOKUS_LUGN = 0.2,
	FOKUS_UTE = 0.14,
	FOKUS_PARAD = 0.22,
	FOKUS_TAU = 2.6,
	BALANS_YTTER = 0.55,
	BALANS_FART = 0.3,
	BALANS_OVERGANG = 0.16,
	BALANS_SPANNING = 0.26,
	BALANS_UTB = 0.3,
	BALANS_TAU_NER = 1.1,
	BALANS_TAU_UPP = 2.2,
	INFALL_MAX = 0.3,
	ENERGI_TAPP = {
		halt = 0,
		skritt = 0.00042,
		trav = 0.00062,
		galopp = 0.00125,
	},
	ENERGI_ATER = {
		halt = 0.0009,
		skritt = 0.00042,
		trav = 0,
		galopp = 0,
	},
	ENERGI_SPANN = 0.45,
	ENERGI_BJUD = 0.35,
}

return RidKanon
