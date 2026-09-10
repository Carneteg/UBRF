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
RidKanon.TELEMETRI_FALT = { "balans", "beddGangart", "cue", "cueAlder", "energi", "etableringstid", "fart", "fokus", "gangart", "gangartGlapp", "hast", "hjalper", "iOvergang", "kurvatur", "mjukhet", "onskadFart", "overgangstid", "paradAlder", "paradKvalitet", "rytm", "spanning", "steglangd", "svangradie", "svarAlder", "svarstid", "uppsutten", "vridhastighet" }

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

--[[ KONTRAKTET G02-C LÄSER (G02-B punkt 5).

     Telemetrin ska exponera BÅDE hjälpen och responsen, och en
     läsare måste kunna se vilka fält som är vad. HJALP_FALT är vad
     ryttaren gör, SVAR_FALT vad hästen svarar. Listorna kommer ur
     webbens moduler, inte ur en handskriven uppräkning. ]]
RidKanon.SVAR_FALT = { "balans", "energi", "fokus", "mjukhet", "paradAlder", "paradKvalitet", "spanning", "svarAlder", "svarstid" }

--[[ HÄSTENS SVAR (G02-B punkt 2, src/riding/svar.js).

     Fördröjning, fokus, balans och energi som riktiga storheter. Webben
     har dem i modellen; Roblox har dem inte alls ännu, och det står som
     LUCKA i paritetsspecen i stället för att fyllas med gissningar.

     ENERGI_TAPP/ENERGI_ATER är per sekund och per gångart, med webbens
     namn. Roblox gångartsnamn översätts av RidKanon.MOTSVARIGHET. ]]
--[[ KONTAKTEN — modellens K-konstanter som hjälpsemantiken behöver.

     Skänkelns tröskel och tygelns kontaktband ÄGS av src/model.js och
     läses härifrån av Roblox-sidan i stället för att skrivas av. Det är
     samma tal som avgör om en halvhalt är välriden på webben. ]]
RidKanon.KONTAKT = {
	SKANKEL_TROSKEL = 0.28,
	SKANKEL_FOR_MYCKET = 0.85,
	SKANKEL_NEUTRAL = 0.42,
	TYGEL_BAND_MIN = 0.22,
	TYGEL_BAND_MAX = 0.58,
	TYGEL_NEUTRAL = 0.34,
	TYGEL_MAX = 0.8,
	TYGEL_HART = 0.72,
	SITS_NEUTRAL = 0.2,
	SITS_PARAD = 0.78,
	SITS_MAX = 0.85,
	AIDS_TAU = 0.3,
	AMPLITUD_SKALA = 0.22,
	MJUKHET_EMA = 3,
	SPANNING_STIGNING = 1.1,
	SPANNING_FALL = 0.42,
}

--[[ SKOLHÄSTPROFILERNA (G02-B punkt 3). Multiplikatorer på SVAR
     ovan — INTE egna kodvägar. `skolhast` är 1,00 rakt igenom och
     därmed modellens utgångsläge; varje annan profil mäts mot den.

     Vilken häst som har vilken profil ligger i UBRFSpelData
     (fältet `profil`), tilldelad ur ridskolans egna beskrivningar.
     Se src/spel/hastar.js för citaten. ]]
RidKanon.PROFILER = {
	skolhast = { namn = "Skolhäst", kort = "pålitlig, går med i alla grupper", svar = 1, klar = 1, balans = 1, fokus = 1, tapp = 1, ater = 1 },
	kanslig = { namn = "Känslig", kort = "svarar på lite, kräver en mjuk hand", svar = 0.72, klar = 1.45, balans = 1.35, fokus = 1.25, tapp = 1.15, ater = 1 },
	tung = { namn = "Tyngre modell", kort = "tar tid, står stadigt, vill ha tydlighet", svar = 1.38, klar = 1.3, balans = 0.7, fokus = 0.85, tapp = 1.25, ater = 0.85 },
	arbetsvillig = { namn = "Arbetsvillig", kort = "bjuder till och orkar länge", svar = 0.86, klar = 0.85, balans = 0.9, fokus = 1.05, tapp = 0.8, ater = 1.2 },
}

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
	BALANS_VIKT = 0.3,
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
	SP_HART = 2.6,
	SP_BAND = 0.9,
	SP_OMJUK = 0.85,
	SP_SKANKEL = 1.1,
	SP_SITS_GALOPP = 0.7,
	SP_SITS_TROSKEL = 0.75,
	SP_SPO = 0.15,
	SP_SPO_RADD = 1.6,
	SP_STALLRO = 0.5,
	SP_SADEL = 0.7,
	SP_UNDERLAG = 0.25,
	SP_SKYGG = 0.18,
	SP_SKYGG_UTE = 1.5,
	SP_KANSL_BAS = 0.55,
	SP_KANSL = 0.9,
	SP_LUGN_RANG = 0.6,
	SP_LUGN_FORLAT = 0.5,
	SP_LUGN_MJUK = 0.6,
	SP_LUGN_DAGSFORM = 0.3,
	SP_LUGN_VIKT = 0.45,
	SP_STIG_BAS = 0.6,
	SP_STIG_KANSL = 0.8,
	SP_FALL_BAS = 0.5,
	SP_FALL_FORLAT = 1,
}

--[[ GOLDEN-RADER — webbens egna svar på bestämda indata.

     Räknade av src/riding/hjalper.js och src/riding/svar.js när den
     här filen genererades. Roblox-specen kör SIN kod på samma indata
     och jämför: driver de två isär blir den röd, även om varenda
     konstant fortfarande stämmer. Att konstanterna är lika bevisar
     inte att formlerna är det. ]]
RidKanon.PROV = {
	hjalper = {
		{ in_ = { skankel = 0.42, tygel = 0.34, styrning = 0 }, ut = { innerTygel = 0.34, ytterTygel = 0.34, ytterstod = 1, bojSida = 0 } },
		{ in_ = { skankel = 0.42, tygel = 0.34, styrning = 0.72 }, ut = { innerTygel = 0.60136, ytterTygel = 0.25432, ytterstod = 0.397375, bojSida = 1 } },
		{ in_ = { skankel = 0.62, tygel = 0.57, styrning = 0.72 }, ut = { innerTygel = 0.74028, ytterTygel = 0.42636, ytterstod = 0.666187, bojSida = 1 } },
		{ in_ = { skankel = 0.78, tygel = 0.8, styrning = 0.36 }, ut = { innerTygel = 0.8396, ytterTygel = 0.6992, ytterstod = 1, bojSida = 1 } },
		{ in_ = { skankel = 0.05, tygel = 0.22, styrning = 0.72 }, ut = { innerTygel = 0.52888, ytterTygel = 0.16456, ytterstod = 0.257125, bojSida = 1 } },
	},
	paradKvalitet = {
		{ in_ = { skankel = 0.42, tygel = 0.34 }, ut = 0.75 },
		{ in_ = { skankel = 0.42, tygel = 0.34 }, ut = 0.75 },
		{ in_ = { skankel = 0.62, tygel = 0.57 }, ut = 0.863889 },
		{ in_ = { skankel = 0.78, tygel = 0.8 }, ut = 0.7 },
		{ in_ = { skankel = 0.05, tygel = 0.22 }, ut = 0.35 },
	},
	svarstid = {
		{ in_ = { profil = "skolhast", kanslighet = 0.5, fokus = 1, energi = 1, klarhet = 0 }, ut = 0.19 },
		{ in_ = { profil = "skolhast", kanslighet = 0.5, fokus = 1, energi = 0.6, klarhet = 0.75 }, ut = 0.155 },
		{ in_ = { profil = "kanslig", kanslighet = 0.8, fokus = 1, energi = 1, klarhet = 0.4 }, ut = 0.06 },
		{ in_ = { profil = "tung", kanslighet = 0.3, fokus = 1, energi = 0.5, klarhet = 0.2 }, ut = 0.34384 },
		{ in_ = { profil = "arbetsvillig", kanslighet = 0.6, fokus = 1, energi = 0.9, klarhet = 1 }, ut = 0.07496 },
	},
	balans = {
		{ in_ = { profil = "skolhast", utbildning = 0.6, bojkrav = 0, ytterstod = 1, fartkrav = 0, iOvergang = false, sits = 0.2 }, ut = 1 },
		{ in_ = { profil = "skolhast", utbildning = 0.6, bojkrav = 1, ytterstod = 0.4, fartkrav = 0, iOvergang = false, sits = 0.2 }, ut = 0.4834 },
		{ in_ = { profil = "kanslig", utbildning = 0.72, bojkrav = 1, ytterstod = 0.67, fartkrav = 0.2, iOvergang = true, sits = 0.55 }, ut = 0.449139 },
		{ in_ = { profil = "tung", utbildning = 0.9, bojkrav = 0.8, ytterstod = 0.3, fartkrav = 0.5, iOvergang = false, sits = 0.78 }, ut = 0.765962 },
		{ in_ = { profil = "skolhast", utbildning = 0.6, bojkrav = 1, ytterstod = 0.67, fartkrav = 0, iOvergang = false, sits = 0.2 }, ut = 0.60517 },
		{ in_ = { profil = "skolhast", utbildning = 0.6, bojkrav = 1, ytterstod = 0.67, fartkrav = 0, iOvergang = false, sits = 0.78 }, ut = 0.85117 },
	},
	spanning = {
		{ in_ = { tygel = 0.34, skankel = 0.42, sits = 0.2, mjukhet = 1, rang = 0.5, gangart = "skritt", kanslighet = 0.5, forlatande = 0.6, skygghet = 0.2, utomhus = false }, ut = 0 },
		{ in_ = { tygel = 0.78, skankel = 0.42, sits = 0.2, mjukhet = 0.6, rang = 0.5, gangart = "trav", kanslighet = 0.8, forlatande = 0.4, skygghet = 0.42, utomhus = false }, ut = 0.338932 },
		{ in_ = { tygel = 0.62, skankel = 0.9, sits = 0.82, mjukhet = 0.3, rang = 0.3, gangart = "galopp", kanslighet = 0.35, forlatande = 0.95, skygghet = 0.05, utomhus = true }, ut = 0.271703 },
	},
	fokus = {
		{ in_ = { mjukhet = 1, spanning = 0, utomhus = false, parad = 0, profil = "skolhast" }, ut = 0.8 },
		{ in_ = { mjukhet = 1, spanning = 0, utomhus = false, parad = 0.93, profil = "skolhast" }, ut = 1 },
		{ in_ = { mjukhet = 0.5, spanning = 0.4, utomhus = true, parad = 0, profil = "kanslig" }, ut = 0.43 },
		{ in_ = { mjukhet = 0.8, spanning = 0.1, utomhus = false, parad = 0.6, profil = "tung" }, ut = 0.8322 },
	},
	infall = {
		{ in_ = { balans = 1, bojkrav = 1 }, ut = 0 },
		{ in_ = { balans = 0.73, bojkrav = 1 }, ut = 0.081 },
		{ in_ = { balans = 0.5, bojkrav = 0.5 }, ut = 0.075 },
		{ in_ = { balans = 0, bojkrav = 1 }, ut = 0.3 },
	},
	energiTakt = {
		{ in_ = { gangart = "halt", profil = "skolhast" }, ut = 0.0009 },
		{ in_ = { gangart = "halt", profil = "kanslig" }, ut = 0.0009 },
		{ in_ = { gangart = "halt", profil = "tung" }, ut = 0.000765 },
		{ in_ = { gangart = "halt", profil = "arbetsvillig" }, ut = 0.00108 },
		{ in_ = { gangart = "skritt", profil = "skolhast" }, ut = 0 },
		{ in_ = { gangart = "skritt", profil = "kanslig" }, ut = -0.000063 },
		{ in_ = { gangart = "skritt", profil = "tung" }, ut = -0.000168 },
		{ in_ = { gangart = "skritt", profil = "arbetsvillig" }, ut = 0.000168 },
		{ in_ = { gangart = "trav", profil = "skolhast" }, ut = -0.00062 },
		{ in_ = { gangart = "trav", profil = "kanslig" }, ut = -0.000713 },
		{ in_ = { gangart = "trav", profil = "tung" }, ut = -0.000775 },
		{ in_ = { gangart = "trav", profil = "arbetsvillig" }, ut = -0.000496 },
		{ in_ = { gangart = "galopp", profil = "skolhast" }, ut = -0.00125 },
		{ in_ = { gangart = "galopp", profil = "kanslig" }, ut = -0.001437 },
		{ in_ = { gangart = "galopp", profil = "tung" }, ut = -0.001562 },
		{ in_ = { gangart = "galopp", profil = "arbetsvillig" }, ut = -0.001 },
	},
}

--[[ UTGÅNGSLÄGET (senior re-review av #87, blocker 2).

     Webben startade en ritt på spänning 0,15 och energi ≈ 0,835,
     Roblox på spänning 0 och energi 1. Formlerna var lika, ritten
     var det inte — och då är det inte samma produkt. Talen står nu
     i SVAR_START i src/riding/svar.js, exporteras hit, och BÅDA
     ytorna läser dem. Ingen siffra ändrades på webben.

     ENERGI = ENERGI_BAS + ENERGI_DAG × dagsform. RANG_* är hur
     rangen växer under ritten; Roblox höll den låst på 0,5 och
     hade därmed en tyst skillnad i hela spänningsmodellen. ]]
RidKanon.START = {
	DAGSFORM = 0.7,
	SADELLAGE = 0.8,
	RANG = 0.5,
	SPANNING = 0.15,
	MJUKHET = 0.5,
	FOKUS = 0.7,
	BALANS = 1,
	ENERGI_BAS = 0.45,
	ENERGI_DAG = 0.55,
	RANG_PIVOT = 0.55,
	RANG_MJUK = 0.02,
	RANG_SPANN = 0.012,
}

--[[ CONTEXTKÄLLORNA — allt som kommer UTIFRÅN in i ridmodellen.

     MÄTT, inte skriven: stepRide körs med hjälperna, ridtillståndets
     contextfält och context-objektet bakom en Proxy som noterar varje
     läsning, över ett svep av hjälper och gångarter.

     Roblox ska för var och en av de här ha ANTINGEN en källa i
     HorseCore.Svar.KONTEXT_HAR eller en deklarerad lucka i
     Svar.KONTEXT_SAKNAS. Paritetsspecen kräver att unionen är exakt
     den här listan. Lägger webben till en källa blir Roblox rött
     tills den fått ett hem — en lucka kan inte uppstå tyst, och
     `inga svarsluckor` kan inte längre gälla en yta som i själva
     verket kör nio ingångar på sina neutrala element. ]]
RidKanon.KONTEXT_KALLOR = { "a.parad", "a.sits", "a.skankel", "a.spo", "a.styrning", "a.tygel", "ctx.avdrift", "ctx.fard.hhAmplitud", "ctx.fard.lugn", "ctx.fard.skygghet", "ctx.fard.spanningFall", "ctx.fard.tygelband", "ctx.stallro", "ctx.svangradie", "ctx.underlag", "ctx.utomhus", "s.dagsform", "s.rang", "s.sadellage" }

--[[ CROSS-PLATFORM-SCENARIOT (senior re-review av #87, blocker 2).

     En RITT, inte en formel. Webbens riktiga stepRide, bildruta för
     bildruta, med två verkliga UBRF-hästar ur src/spel/hastar.js och
     med den context Roblox faktiskt har. Roblox-specen kör samma
     ritt genom en riktig MovementController och jämför fem storheter
     i åtta mätpunkter.

     GRÄNSEN, uttryckligen: jämförelsen börjar vid SEMANTISKA HJÄLPER
     per bildruta, inte vid tangenttryck. Inputadaptern får vara
     plattformsspecifik enligt paritetsregeln; att hjälpen leder till
     samma svar får den inte.

     STEG är glest: en rad först när en hjälp ändras, håll kvar
     mellan raderna. BEDD är vilken gångart ryttaren bad om och på
     vilken bildruta — mätt ur webbens cue-modell, så att Roblox
     tangentflank hamnar på exakt samma bildruta.

     MATT är facit med Roblox context. WEBB är samma ritt med webbens
     egen context; skillnaden mellan de två är vad de deklarerade
     luckorna är VÄRDA, i siffror, i stället för bara namngivna. ]]
RidKanon.SCENARIO = {
	HZ = 60,
	RUTOR = 720,
	STEG = {
		{ i = 0, skankel = 0.42, tygel = 0.34, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 61, skankel = 0.48, tygel = 0.34, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 62, skankel = 0.54, tygel = 0.34, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 63, skankel = 0.6, tygel = 0.34, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 64, skankel = 0.66, tygel = 0.34, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 65, skankel = 0.72, tygel = 0.34, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 66, skankel = 0.78, tygel = 0.34, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 87, skankel = 0.42, tygel = 0.34, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 181, skankel = 0.48, tygel = 0.34, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 182, skankel = 0.54, tygel = 0.34, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 183, skankel = 0.6, tygel = 0.34, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 184, skankel = 0.66, tygel = 0.34, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 185, skankel = 0.72, tygel = 0.34, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 186, skankel = 0.78, tygel = 0.34, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 208, skankel = 0.42, tygel = 0.34, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 301, skankel = 0.42, tygel = 0.351257, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 302, skankel = 0.42, tygel = 0.383926, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 303, skankel = 0.42, tygel = 0.434809, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 304, skankel = 0.42, tygel = 0.498926, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 305, skankel = 0.42, tygel = 0.57, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 306, skankel = 0.42, tygel = 0.641074, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 307, skankel = 0.42, tygel = 0.705191, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 308, skankel = 0.42, tygel = 0.756074, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 309, skankel = 0.42, tygel = 0.788743, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 310, skankel = 0.42, tygel = 0.8, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 311, skankel = 0.42, tygel = 0.788743, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 312, skankel = 0.42, tygel = 0.756074, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 313, skankel = 0.42, tygel = 0.705191, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 314, skankel = 0.42, tygel = 0.641074, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 315, skankel = 0.42, tygel = 0.57, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 316, skankel = 0.42, tygel = 0.498926, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 317, skankel = 0.42, tygel = 0.434809, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 318, skankel = 0.42, tygel = 0.383926, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 319, skankel = 0.42, tygel = 0.351257, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 320, skankel = 0.42, tygel = 0.34, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 321, skankel = 0.42, tygel = 0.351257, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 322, skankel = 0.42, tygel = 0.383926, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 323, skankel = 0.42, tygel = 0.434809, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 324, skankel = 0.42, tygel = 0.498926, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 325, skankel = 0.42, tygel = 0.57, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 326, skankel = 0.42, tygel = 0.641074, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 327, skankel = 0.42, tygel = 0.705191, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 328, skankel = 0.42, tygel = 0.756074, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 329, skankel = 0.42, tygel = 0.788743, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 330, skankel = 0.42, tygel = 0.8, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 331, skankel = 0.42, tygel = 0.788743, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 332, skankel = 0.42, tygel = 0.756074, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 333, skankel = 0.42, tygel = 0.705191, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 334, skankel = 0.42, tygel = 0.641074, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 335, skankel = 0.42, tygel = 0.57, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 336, skankel = 0.42, tygel = 0.498926, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 337, skankel = 0.42, tygel = 0.434809, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 338, skankel = 0.42, tygel = 0.383926, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 339, skankel = 0.42, tygel = 0.351257, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 340, skankel = 0.42, tygel = 0.34, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 341, skankel = 0.42, tygel = 0.351257, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 342, skankel = 0.42, tygel = 0.383926, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 343, skankel = 0.42, tygel = 0.434809, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 344, skankel = 0.42, tygel = 0.498926, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 345, skankel = 0.42, tygel = 0.57, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 346, skankel = 0.42, tygel = 0.641074, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 347, skankel = 0.42, tygel = 0.705191, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 348, skankel = 0.42, tygel = 0.756074, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 349, skankel = 0.42, tygel = 0.788743, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 350, skankel = 0.42, tygel = 0.8, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 351, skankel = 0.42, tygel = 0.788743, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 352, skankel = 0.42, tygel = 0.756074, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 353, skankel = 0.42, tygel = 0.705191, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 354, skankel = 0.42, tygel = 0.641074, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 355, skankel = 0.42, tygel = 0.57, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 356, skankel = 0.42, tygel = 0.498926, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 357, skankel = 0.42, tygel = 0.434809, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 358, skankel = 0.42, tygel = 0.383926, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 359, skankel = 0.42, tygel = 0.351257, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 360, skankel = 0.42, tygel = 0.34, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 361, skankel = 0.42, tygel = 0.351257, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 362, skankel = 0.42, tygel = 0.383926, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 363, skankel = 0.42, tygel = 0.434809, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 364, skankel = 0.42, tygel = 0.498926, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 365, skankel = 0.42, tygel = 0.57, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 366, skankel = 0.42, tygel = 0.641074, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 367, skankel = 0.42, tygel = 0.705191, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 368, skankel = 0.42, tygel = 0.756074, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 369, skankel = 0.42, tygel = 0.788743, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 370, skankel = 0.42, tygel = 0.8, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 371, skankel = 0.42, tygel = 0.788743, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 372, skankel = 0.42, tygel = 0.756074, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 373, skankel = 0.42, tygel = 0.705191, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 374, skankel = 0.42, tygel = 0.641074, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 375, skankel = 0.42, tygel = 0.57, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 376, skankel = 0.42, tygel = 0.498926, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 377, skankel = 0.42, tygel = 0.434809, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 378, skankel = 0.42, tygel = 0.383926, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 379, skankel = 0.42, tygel = 0.351257, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 380, skankel = 0.42, tygel = 0.34, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 381, skankel = 0.42, tygel = 0.351257, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 382, skankel = 0.42, tygel = 0.383926, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 383, skankel = 0.42, tygel = 0.434809, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 384, skankel = 0.42, tygel = 0.498926, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 385, skankel = 0.42, tygel = 0.57, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 386, skankel = 0.42, tygel = 0.641074, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 387, skankel = 0.42, tygel = 0.705191, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 388, skankel = 0.42, tygel = 0.756074, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 389, skankel = 0.42, tygel = 0.788743, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 390, skankel = 0.42, tygel = 0.34, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 511, skankel = 0.48, tygel = 0.34, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 512, skankel = 0.54, tygel = 0.34, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 513, skankel = 0.6, tygel = 0.34, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 514, skankel = 0.66, tygel = 0.34, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 515, skankel = 0.72, tygel = 0.34, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 516, skankel = 0.78, tygel = 0.34, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 537, skankel = 0.42, tygel = 0.34, sits = 0.2, styrning = 0, parad = 0 },
		{ i = 600, skankel = 0.42, tygel = 0.52, sits = 0.85, styrning = 0, parad = 1 },
		{ i = 612, skankel = 0.42, tygel = 0.34, sits = 0.2, styrning = 0, parad = 0 },
	},
	HASTAR = {
		{
			id = "crokino", profil = "kanslig",
			BEDD = {
				{ i = 63, gangart = "skritt" },
				{ i = 183, gangart = "trav" },
				{ i = 304, gangart = "skritt" },
				{ i = 364, gangart = "halt" },
				{ i = 513, gangart = "skritt" },
				{ i = 600, gangart = "halt" },
			},
			MATT = {
				{ t = 0.05, i = 2, gangart = "halt", svarstid = 0, balans = 0.997596, fokus = 0.698441, spanning = 0.21732, energi = 0.835045 },
				{ t = 0.3, i = 17, gangart = "halt", svarstid = 0, balans = 0.988787, fokus = 0.696309, spanning = 0.115774, energi = 0.83527 },
				{ t = 1, i = 59, gangart = "halt", svarstid = 0, balans = 0.990007, fokus = 0.714313, spanning = 0, energi = 0.8359 },
				{ t = 2.5, i = 149, gangart = "skritt", svarstid = 0.06, balans = 0.92578, fokus = 0.724444, spanning = 0, energi = 0.83633 },
				{ t = 4.5, i = 269, gangart = "trav", svarstid = 0.06, balans = 0.897508, fokus = 0.737476, spanning = 0, energi = 0.835633 },
				{ t = 6, i = 359, gangart = "skritt", svarstid = 0.06, balans = 0.855439, fokus = 0.73455, spanning = 0.160501, energi = 0.834757 },
				{ t = 8, i = 479, gangart = "halt", svarstid = 0.06, balans = 0.882612, fokus = 0.738114, spanning = 0, energi = 0.835891 },
				{ t = 9.5, i = 569, gangart = "skritt", svarstid = 0.06, balans = 0.871679, fokus = 0.739675, spanning = 0, energi = 0.836804 },
				{ t = 11, i = 659, gangart = "halt", svarstid = 0.06, balans = 0.85759, fokus = 0.796966, spanning = 0, energi = 0.837192 },
				{ t = 12, i = 719, gangart = "halt", svarstid = 0.06, balans = 0.909764, fokus = 0.794517, spanning = 0, energi = 0.838092 },
			},
			WEBB = {
				{ t = 0.05, i = 2, gangart = "galopp", svarstid = 0, balans = 0.997596, fokus = 0.698441, spanning = 0.21732, energi = 0.834963 },
				{ t = 0.3, i = 17, gangart = "galopp", svarstid = 0, balans = 0.986892, fokus = 0.695692, spanning = 0.150213, energi = 0.834571 },
				{ t = 1, i = 59, gangart = "galopp", svarstid = 0, balans = 0.987212, fokus = 0.713212, spanning = 0, energi = 0.833549 },
				{ t = 2.5, i = 149, gangart = "galopp", svarstid = 0.06, balans = 0.903574, fokus = 0.721544, spanning = 0, energi = 0.831976 },
				{ t = 4.5, i = 269, gangart = "galopp", svarstid = 0.06, balans = 0.883702, fokus = 0.73394, spanning = 0, energi = 0.829393 },
				{ t = 6, i = 359, gangart = "skritt", svarstid = 0.06, balans = 0.84926, fokus = 0.731999, spanning = 0.16586, energi = 0.827653 },
				{ t = 8, i = 479, gangart = "galopp", svarstid = 0.06, balans = 0.877449, fokus = 0.735463, spanning = 0, energi = 0.825917 },
				{ t = 9.5, i = 569, gangart = "skritt", svarstid = 0.06, balans = 0.854412, fokus = 0.735737, spanning = 0, energi = 0.824212 },
				{ t = 11, i = 659, gangart = "galopp", svarstid = 0.06, balans = 0.840339, fokus = 0.791333, spanning = 0.021187, energi = 0.822985 },
				{ t = 12, i = 719, gangart = "galopp", svarstid = 0.06, balans = 0.898805, fokus = 0.79067, spanning = 0, energi = 0.821547 },
			},
		},
		{
			id = "mac_kenzie", profil = "tung",
			BEDD = {
				{ i = 63, gangart = "skritt" },
				{ i = 183, gangart = "trav" },
				{ i = 304, gangart = "skritt" },
				{ i = 364, gangart = "halt" },
				{ i = 513, gangart = "skritt" },
				{ i = 600, gangart = "halt" },
			},
			MATT = {
				{ t = 0.05, i = 2, gangart = "halt", svarstid = 0, balans = 0.999101, fokus = 0.698672, spanning = 0.1269, energi = 0.835038 },
				{ t = 0.3, i = 17, gangart = "halt", svarstid = 0, balans = 0.99735, fokus = 0.698394, spanning = 0.0114, energi = 0.83523 },
				{ t = 1, i = 59, gangart = "halt", svarstid = 0, balans = 0.998072, fokus = 0.716768, spanning = 0, energi = 0.835765 },
				{ t = 2.5, i = 149, gangart = "skritt", svarstid = 0.201525, balans = 0.961023, fokus = 0.727581, spanning = 0, energi = 0.836166 },
				{ t = 4.5, i = 269, gangart = "trav", svarstid = 0.197856, balans = 0.944131, fokus = 0.740435, spanning = 0, energi = 0.835385 },
				{ t = 6, i = 359, gangart = "skritt", svarstid = 0.235766, balans = 0.935786, fokus = 0.741753, spanning = 0, energi = 0.834311 },
				{ t = 8, i = 479, gangart = "halt", svarstid = 0.237519, balans = 0.940157, fokus = 0.746547, spanning = 0, energi = 0.835046 },
				{ t = 9.5, i = 569, gangart = "skritt", svarstid = 0.19524, balans = 0.932981, fokus = 0.745894, spanning = 0, energi = 0.835898 },
				{ t = 11, i = 659, gangart = "halt", svarstid = 0.239529, balans = 0.929391, fokus = 0.784566, spanning = 0, energi = 0.835956 },
				{ t = 12, i = 719, gangart = "halt", svarstid = 0.239529, balans = 0.954712, fokus = 0.786087, spanning = 0, energi = 0.836721 },
			},
			WEBB = {
				{ t = 0.05, i = 2, gangart = "galopp", svarstid = 0, balans = 0.99908, fokus = 0.69866, spanning = 0.13, energi = 0.834958 },
				{ t = 0.3, i = 17, gangart = "galopp", svarstid = 0, balans = 0.997242, fokus = 0.698327, spanning = 0.0145, energi = 0.834555 },
				{ t = 1, i = 59, gangart = "galopp", svarstid = 0, balans = 0.99799, fokus = 0.716714, spanning = 0, energi = 0.833461 },
				{ t = 2.5, i = 149, gangart = "galopp", svarstid = 0.201868, balans = 0.951576, fokus = 0.727551, spanning = 0, energi = 0.831745 },
				{ t = 4.5, i = 269, gangart = "galopp", svarstid = 0.198576, balans = 0.940121, fokus = 0.740421, spanning = 0, energi = 0.828974 },
				{ t = 6, i = 359, gangart = "skritt", svarstid = 0.236714, balans = 0.934207, fokus = 0.741662, spanning = 0, energi = 0.826835 },
				{ t = 8, i = 479, gangart = "galopp", svarstid = 0.238565, balans = 0.939718, fokus = 0.746426, spanning = 0, energi = 0.825172 },
				{ t = 9.5, i = 569, gangart = "skritt", svarstid = 0.196795, balans = 0.932824, fokus = 0.745826, spanning = 0, energi = 0.82313 },
				{ t = 11, i = 659, gangart = "halt", svarstid = 0.241351, balans = 0.92467, fokus = 0.783526, spanning = 0, energi = 0.821872 },
				{ t = 12, i = 719, gangart = "galopp", svarstid = 0.241351, balans = 0.951744, fokus = 0.785379, spanning = 0, energi = 0.820387 },
			},
		},
	},
}

--[[ G02-C: Ugnetas bedömningskontrakt, ur src/larare.js. ]]
RidKanon.UGNETA = {
	MAX_OBSERVATIONER = 2,
	DIMENSIONER = { "linje", "rytm", "balans", "timing", "mjukhet", "respons", "tempo" },
	OVNING = {
		galoppfattning = { "timing", "balans", "respons" },
		halt_skritt = { "timing", "mjukhet", "respons" },
		horn = { "rytm", "balans", "linje" },
		skritt_trav = { "timing", "mjukhet", "respons" },
		storvolt = { "linje", "rytm", "balans" },
		trav_skritt = { "timing", "mjukhet", "respons" },
	},
}

return RidKanon
