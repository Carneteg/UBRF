--!nostrict
--[[
	UI-KONTEXTEN: SKÖTSELNS FRAMSTEGSKORT HÖR TILL BOXEN (PO-order
	2026-09-20).

	Ordern, ord för ord:

	  "The top-right «Take care of her» progress card belongs to
	   horse-care/box mode only. It must NOT remain as a permanent riding
	   HUD."

	── VAD SOM VAR FEL, MÄTT INNAN NÅGOT ÄNDRADES ─────────────────────

	Studio-MCP mot place `UBRF`, solo playtest på `a0d6730`, en och samma
	session:

	  vid boxen, `halsa` på tur
	      Sparare.Vaxla.Rubrik      "Greet her calmly"
	      Sparare.Vaxla.Framsteg    "0/5"
	      Sparare.Hjalp             "Walk up from the side. Say her
	                                 name before you touch her."
	      Interaktion.Instruktion   "Walk up from the side. Say her
	                                 name before you touch her."   <- SAMMA
	      båda Visible              true                           <- SAMTIDIGT
	      prompter på Trixie        LedPrompt, RidaNuPrompt        <- OCH DE

	  i kopplet mot ridhuset
	      UBRFForberedelse.Enabled  true
	      Sparare                   uppe, "Greet her calmly · 0/5"  <- FEL

	  uppsutten
	      UBRFForberedelse.Enabled  false                           <- redan rätt

	Ritten var alltså aldrig problemet — `avsluta` släcker ytan på
	`vy.status == "riding"`, och det hade den gjort sedan #161. Felen var
	LEDNINGEN, DUBBLETTEN och KONKURRENSEN.

	── VAD DEN HÄR SPECEN MÄTER ───────────────────────────────────────

	  1. skötsel: kortet finns, och det bär titel + framsteg,
	  2. dubbletten: instruktionen står på EN yta, inte två,
	  3. ledning: kortet är borta — men nederkanten står kvar, för den
	     bär ledningens egen instruktion och dess nej,
	  4. ridning: kortet är borta och hela ytan är släckt,
	  5. återvändandet: kortet kommer tillbaka med SAMMA progression,
	  6. konkurrensen — 1 MÅL → 1 INSTRUKTION → 1 HANDLING (avsnitt 3–3d).

	── AVSNITT 3–3d: PRODUCT CLARIFICATION 2026-09-20 ─────────────────

	Ordern smalnar punkt 6 och säger HUR den ska lösas:

	  "Treat prompt visibility by current task relevance, not by «care
	   panel visible» as a blanket rule."

	Det skiljer den från `8aba0f3`, som frågade panelen och backades ut.
	Fyra mätningar, en per punkt i ordern:

	  3   aktivt skötselsteg → varken `LedPrompt` eller `MountPrompt`
	      konkurrerar, och regeln är INTE en global gömning: går man
	      ifrån henne är båda tillbaka,
	  3b  ledsteget → `LedPrompt` finns, och den finns i `leda` och
	      ingen annan förberedelsefas,
	  3c  redan i kopplet → släpp-vägen lever mitt i ett skötselsteg,
	      OCH serverns ledbesked når klienten även när knappen var gömd
	      när det kom (buggen som fällde `8aba0f3`),
	  3d  eftervården → `MountPrompt` viker för «Lossa sadelgjorden»
	      trots att `Pass.farSittaUpp` fortfarande säger ja, och kommer
	      tillbaka av sig själv när momenten är gjorda.

	DET SOM INTE ÄR TESTAT HÄR är om «Rida nu» också borde vika. Ordern
	namnger Lead och Mount; genvägen till sadeln står kvar som ett
	uttryckligt produktval (FUN FIRST / RIDE FIRST), och avsnitt 3 mäter
	att den gör det. Ska den bort är det Tobias beslut, inte en städning.

	Kedjan drivs genom PRODUKTIONENS egna vägar: `PreparationController
	.tillampa` (samma väg som `PreparationSync`) och `LedSync
	.OnClientEvent` (samma väg som servern släpper och tar kopplet). Ett
	direktanrop av `satLeder` hade mätt funktionen i stället för
	kopplingen, och det är precis den sortens grönt som #119 fälldes för.

	BÄNKGRÄNS: hur kortet SER ut när det försvinner — om bytet känns
	tvärt, om nederkanten räcker som enda yta — är en mänsklig grind och
	står som sådan i PR-texten.

	Kör: python3 roblox/tests/build.py tests/klient-uikontext.spec.luau
	     && luau roblox/tests/.build/klient-uikontext.spec.luau
]]

local fel = 0
local function prova(vad, ok, detalj)
	if ok then
		print(("  OK   %s%s"):format(vad, if detalj then "  " .. detalj else ""))
	else
		fel += 1
		print(("  FEL  %s%s"):format(vad, if detalj then "  " .. detalj else ""))
	end
end

local Players = game:GetService("Players")
local Taggar = game:GetService("CollectionService")
local RSt = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local Net = Networking
local PC = PreparationController
local IC = InteractionController

Sprak.satLocale("sv-se")

local function barn(inst, namn)
	for _, b in ipairs(inst and inst._barn or {}) do
		if b.Name == namn then return b end
	end
	return nil
end

--[[ Fjärrobjekten skapas bara på servern; bänken är klient. Samma knep som
	`klient-ledprompt.spec` använder. ]]
RunService._server = true
Net.get("MountRequest")
Net.get("LedBorja")
Net.get("LedSlapp")
Net.get("LedSync")
Net.get("RidaNu")
RunService._server = false
RSt:SetAttribute("G01Enabled", true)

local HAST_ID = "trixie"

local hast = __makeHastModell("Trixie")
hast:SetAttribute("HorseId", HAST_ID)
hast:SetAttribute("HorseName", "Trixie")
hast.Parent = workspace
Taggar:AddTag(hast, "Horse")
local hastRot = hast:FindFirstChild("HumanoidRootPart")

--[[ En kropp med ett LÄGE. HUD:ens kontextfråga är ett avstånd, och
	stubbens LocalPlayer har ingen rot. Samma attrapp som
	`varldshud.spec` bygger, av samma skäl. ]]
local karaktar = Instance.new("Model")
karaktar.Name = "Spelare"
local kropp = Instance.new("Part")
kropp.Name = "HumanoidRootPart"
kropp.Size = Vector3.new(2, 2, 1)
kropp.CFrame = CFrame.new(hastRot.CFrame.Position)
kropp.Parent = karaktar
karaktar.Parent = workspace
player.Character = karaktar

--[[ SERVERNS VY, byggd ur samma modul servern använder. `rev` måste växa:
	klienten kastar en äldre vy, och det är rätt (krav 10). ]]
local rev = 0
local state = Preparation.nyState(HAST_ID, 1)
local function visa(status)
	rev += 1
	PC.tillampa(Preparation.vy(state, status, rev, "Trixie"))
	PC.uppdateraKontext()
	IC.uppdatera()
end

--[[ Klar med en fas, genom modulens egen väg. Att sätta `klara` för hand
	hade gett ett tillstånd servern aldrig kan producera. ]]
local function gorFas(fasId)
	while true do
		local m = Preparation.nastaMoment(state, fasId)
		if not m then break end
		local ok = Preparation.utforMoment(state, fasId, m.id, HAST_ID)
		if not ok then break end
	end
end

local function ytor()
	return PC._ytor()
end
local function promptar()
	local ut = {}
	for _, d in ipairs(hast:GetDescendants()) do
		if d.Name == "MountPrompt" or d.Name == "LedPrompt"
		or d.Name == "RidaNuPrompt" then
			ut[d.Name] = d
		end
	end
	return ut
end

print("\nUI-KONTEXT: SKÖTSELKORTET HÖR TILL BOXEN\n")

print("── 1. Skötseln: kortet finns, med titel och framsteg ──")

visa(Preparation.STATUS.FORBEREDER)
local y = ytor()

prova("kontexten är skötsel", PC.kontext() == "skotsel", PC.kontext())
prova("framstegskortet står på skärmen",
	y.sparare ~= nil and y.sparare.Visible == true,
	("Visible = %s"):format(tostring(y.sparare and y.sparare.Visible)))
prova("det bär en titel", y.rubrik.Text ~= "", ('"%s"'):format(y.rubrik.Text))
do
	local klara, totalt = PC._framsteg()
	prova("och det bär framstegen som två tal",
		y.framsteg.Text == ("%d/%d"):format(klara, totalt) and totalt > 0,
		('"%s"'):format(y.framsteg.Text))
end

print("\n── 2. En instruktion, en plats ──")

do
	--[[ Fälld UT är det värsta läget: förut stod hjälpraden och panelens
		instruktion uppe samtidigt med samma sträng. ]]
	if not PC._utvidgad() then PC.vaxla() end
	local pa = ytor()
	prova("panelen står uppe och bär instruktionen",
		pa.interaktion.Visible == true and pa.instruktion.Text ~= "",
		('"%s"'):format(pa.instruktion.Text))
	prova("och spårarens hjälprad är då INTE uppe med samma text",
		pa.hjalp.Visible == false,
		("hjälprad %s · texterna lika: %s"):format(
			tostring(pa.hjalp.Visible),
			tostring(pa.hjalp.Text == pa.instruktion.Text)))
	local hogdMedPanel = PC.layout().sparare.y1 - PC.layout().sparare.y0

	--[[ RADEN RIVS INTE. Utan panel är den enda platsen texten finns, och
		det är precis därför `avsluta` fäller ut spåraren i de lägena.
		Fyra räckvidder bort göms panelen — samma gräns servern mäter. ]]
	kropp.CFrame = CFrame.new(hastRot.CFrame.Position
		+ Vector3.new(Config.STEG_RACKVIDD * 4, 0, 0))
	PC.uppdateraKontext()
	local borta = ytor()
	prova("utom räckhåll finns ingen panel",
		borta.interaktion.Visible == false)
	prova("och DÅ bär spåraren texten — raden är inte borttagen",
		borta.hjalp.Visible == true and borta.hjalp.Text ~= "",
		('"%s"'):format(tostring(borta.hjalp.Text)))

	--[[ HÖJDEN FÖLJER RADEN. Reserverade kortet hjälpradens band även när
		raden inte ritas hade det stått ett tomt fält där texten förut
		låg — en städning som bara flyttar problemet från text till luft.
		Samma steglista i båda mätningarna, så skillnaden ÄR raden. ]]
	local hogdUtanPanel = PC.layout().sparare.y1 - PC.layout().sparare.y0
	prova("och kortet är exakt en hjälprad lägre när raden inte ritas",
		hogdMedPanel < hogdUtanPanel,
		("%d px utan raden mot %d px med"):format(hogdMedPanel, hogdUtanPanel))
	kropp.CFrame = CFrame.new(hastRot.CFrame.Position)
	PC.uppdateraKontext()
end

print("\n── 3. Konkurrensen: UPPGIFTEN avgör, inte panelen ──")

--[[ PO-order 2026-09-20, PRODUCT CLARIFICATION:

	  "Treat prompt visibility by current task relevance, not by «care
	   panel visible» as a blanket rule."

	FÖRSTA FÖRSÖKET FRÅGADE PANELEN, och det backades ut (`8aba0f3`) på en
	mätning som fortfarande är sann:

	    skötselpanelen visas      `Config.STEG_RACKVIDD`
	    servern släpper kopplet   `LedService` RACKVIDD 4,0 m × M 3

	Är de LIKA finns ingen position där en PANELREGEL lämnar ledknappen
	både synlig och verksam: innanför radien göms den, utanför svarar
	servern `led.for_langt`. Talet mäts här nedan, för det är hela skälet
	till att regeln måste fråga något ANNAT än panelen.

	`LedService` ligger inte i klientbunten, så dess tal kan inte läsas
	härifrån; det står som en konstant i `init.client` och här.

	UPPGIFTSREGELN har ingen sådan död zon: `aktuellUppgift` svarar "leda"
	i de två lägen där ledningen ÄR handlingen — `leda` står på tur
	(avsnitt 3b), eller repet är redan i handen (avsnitt 3c) — och då står
	knappen mitt inne i radien, där servern också säger ja. ]]
do
	visa(Preparation.STATUS.FORBEREDER)
	local p = promptar()
	prova("ett skötselsteg står och väntar på ett tryck",
		PC.skotselstegVantar() == true and PC.nastaFas() ~= nil,
		("fas %s"):format(tostring(PC.nastaFas())))
	prova("skötselns radie är 12 studs — samma som serverns ledgräns",
		Config.STEG_RACKVIDD == 12,
		("STEG_RACKVIDD %s mot LedService 4,0 m × 3 = 12"):format(
			tostring(Config.STEG_RACKVIDD)))
	prova("uppgiften är SKÖTSEL — steget äger fokus",
		PC.aktuellUppgift() == "skotsel" and PC.skotselstegAgerFokus() == true,
		PC.aktuellUppgift())
	prova("och ledknappen konkurrerar inte med instruktionen",
		p.LedPrompt == nil,
		if p.LedPrompt then "LedPrompt kvar" else "(borta)")
	--[[ TVÅ SKÄL ATT UPPSITTNINGEN ÄR BORTA HÄR, och bara ETT av dem är
		den nya regeln: `redo` är falskt så länge en fas återstår. Raden
		mäter alltså inte grinden — det gör avsnitt 3d, i eftervården, som
		är det enda läget där `redo` och ett väntande moment möts. ]]
	prova("ingen uppsittningsknapp — både `redo` och uppgiften säger nej",
		p.MountPrompt == nil and PC.redo() == false,
		if p.MountPrompt then "MountPrompt kvar" else "(borta)")
	--[[ «RIDA NU» RÖRS INTE, och det är ett produktval värt att skriva ut.
		Ordern namnger Lead och Mount. Genvägen till sadeln är spelets eget
		svar på «jag vill inte göra det här steget» (FUN FIRST / RIDE
		FIRST), och när ledknappen viker är den dessutom den enda kvar-
		varande vägen bort från steget. Den är alltså relevant i precis de
		lägen de andra två inte är. ]]
	prova("och «Rida nu» står kvar — genvägen är aldrig irrelevant",
		p.RidaNuPrompt ~= nil,
		if p.RidaNuPrompt then "(kvar)" else "RidaNuPrompt borttagen")

	--[[ INGEN GLOBAL GÖMNING. Utom räckhåll väntar inget steg på ett
		tryck — panelen är nere — och då är uppgiften "rida" igen. Raden
		skiljer den här regeln från "göm alltid": faller den har någon
		bytt uppgiftsfrågan mot en flagga. ]]
	kropp.CFrame = CFrame.new(hastRot.CFrame.Position
		+ Vector3.new(Config.STEG_RACKVIDD * 4, 0, 0))
	PC.uppdateraKontext()
	IC.uppdatera()
	prova("går man ifrån henne är uppgiften «rida» och knappen tillbaka",
		PC.aktuellUppgift() == "rida" and promptar().LedPrompt ~= nil,
		PC.aktuellUppgift())
	kropp.CFrame = CFrame.new(hastRot.CFrame.Position)
	PC.uppdateraKontext()
	IC.uppdatera()
end

print("\n── 3b. Ledsteget är nåbart — orderns punkt 2 ──")

do
	--[[ Produktbeslut 2026-09-17, och #162 blockerare 2: `leda` bockas av
		genom att hon FYSISKT leds till ridhuset. Göms knappen i DEN fasen
		finns ingen väg att fästa kopplet, och loopen låser. Svepet går
		igenom hela dagen, en fas i taget, och mäter BÅDA leden: knappen är
		borta i de fyra första och finns i den femte. ]]
	state = Preparation.nyState(HAST_ID, 1)
	local fel_i_fas = {}
	for _, f in ipairs(Preparation.stegFaser()) do
		visa(Preparation.STATUS.FORBEREDER)
		local ledsteg = f.id == "leda"
		local finns = promptar().LedPrompt ~= nil
		if PC.nastaFas() ~= f.id then
			table.insert(fel_i_fas, ("turordning %s≠%s"):format(
				tostring(PC.nastaFas()), f.id))
		elseif finns ~= ledsteg then
			table.insert(fel_i_fas, ("%s: knapp=%s väntat=%s"):format(
				f.id, tostring(finns), tostring(ledsteg)))
		end
		if not ledsteg then gorFas(f.id) end
	end
	prova("ledknappen viker i skötselstegen och finns i ledsteget",
		#fel_i_fas == 0,
		if #fel_i_fas > 0 then table.concat(fel_i_fas, ", ") else "alla 5 faser")
	visa(Preparation.STATUS.FORBEREDER)
	prova("och i `leda` är uppgiften LEDA, mitt inne i serverns radie",
		PC.nastaFas() == "leda" and PC.aktuellUppgift() == "leda"
			and PC.skotselstegVantar() == true,
		("fas %s · uppgift %s"):format(tostring(PC.nastaFas()),
			PC.aktuellUppgift()))
end

print("\n── 3c. Redan i kopplet: släpp-vägen lever — orderns punkt 4 ──")

--[[ TVÅ SAKER MÄTS HÄR, och den andra är en bugg som fanns FÖRE den här
	regeln.

	`lyssnaPaLedningen` härledde "vilken häst leder jag" ur de ledknappar
	som RÅKADE finnas: loopen gick över `ledKnappar`. Fanns ingen knapp
	blev svaret nil, och en ledning servern redan startat nådde aldrig
	klienten — varken statusraden, kvittensen eller HUD-kontexten.

	Det är fel oavsett synlighetsregel; servern släpper och tar kopplet på
	egen hand (`led.for_langt`, `led.tappade_bort`, `led.rider`). Men det
	blir en SPÄRR så fort knappen får gömmas, och det var det som fällde
	`8aba0f3`. Hästen slås nu upp ur `Horse`-taggen via `vy.hastId`.

	Provet ställer därför upp det värsta läget med flit: ett vanligt
	skötselsteg står och väntar, ledknappen är GÖMD, och servern säger att
	kopplet är fäst. ]]
do
	state = Preparation.nyState(HAST_ID, 1)
	visa(Preparation.STATUS.FORBEREDER)
	prova("utgångsläget: skötselsteg väntar och ingen ledknapp finns",
		PC.aktuellUppgift() == "skotsel" and promptar().LedPrompt == nil,
		("fas %s"):format(tostring(PC.nastaFas())))

	Net.get("LedSync").OnClientEvent:Fire({ leder = true, hastId = HAST_ID })
	prova("serverns besked når klienten ÄVEN utan knapp att härleda ur",
		IC._lederNu() ~= nil and PC._leder() == true,
		("lederNu %s · PC._leder %s"):format(
			tostring(IC._lederNu() and IC._lederNu().Name),
			tostring(PC._leder())))
	prova("uppgiften är LEDA — repet i handen slår steget",
		PC.aktuellUppgift() == "leda", PC.aktuellUppgift())
	local led = promptar().LedPrompt
	prova("och släpp-knappen finns, mitt i skötselsteget",
		led ~= nil, if led then "(kvar)" else "LedPrompt gömd — fast i repet")
	--[[ RÄTT ORD PÅ KNAPPEN. Byggdes den efter `satLeder` stod «Led
		Trixie» på en häst som redan går i repet, och trycket hade blivit
		ett `LedBorja` på ett fäst koppel. ]]
	prova("den bär släpp-texten, inte «Led Trixie»",
		led ~= nil and led.ActionText == Sprak.t("led.slapp_namn", "Trixie"),
		('"%s"'):format(tostring(led and led.ActionText)))

	Net.get("LedSync").OnClientEvent:Fire({ leder = false, hastId = nil,
		skal = "led.tappade_bort" })
	prova("och när servern släpper är steget i fokus igen",
		PC.aktuellUppgift() == "skotsel" and promptar().LedPrompt == nil
			and PC._leder() == false,
		PC.aktuellUppgift())
end

print("\n── 3d. Eftervården: «Sitt upp» viker — orderns punkt 3 ──")

--[[ DET ENDA LÄGET DÄR `redo` OCH ETT VÄNTANDE MOMENT MÖTS, och därför
	det enda läget där Mount-grinden betyder något. Det är också precis
	bilden i orderns acceptansstycke: «active aftercare instruction (e.g.
	loosen girth) · care progress visible · Lead/Mount competing».

	En tidigare version av det här avsnittet drog slutsatsen att grinden
	inte behövdes, för `Pass.farSittaUpp` släpper med flit en andra ritt.
	Ordern avgör den frågan åt andra hållet: «do not show Mount beside an
	active care instruction merely because a second ride is technically
	allowed». HANDLINGEN finns kvar på servern — det mäts nedan — det är
	KNAPPEN som viker. ]]
do
	state = Preparation.nyState(HAST_ID, 1)
	for _, fas in ipairs(Preparation.stegFaser()) do gorFas(fas.id) end
	visa(Preparation.STATUS.REDO)
	prova("hästen är redo och inget moment väntar — uppgiften är RIDA",
		PC.redo() == true and PC.nastaFas() == nil
			and PC.aktuellUppgift() == "rida",
		("redo %s · fas %s · uppgift %s"):format(tostring(PC.redo()),
			tostring(PC.nastaFas()), PC.aktuellUppgift()))
	prova("och uppsittningsknappen finns", promptar().MountPrompt ~= nil)

	--[[ RITTEN OCH AVSITTNINGEN, genom passets egen modul. `PassSync` är
		den väg servern skickar det här, och `tillampaPass` är klientens
		mottagare — samma kedja, inte en genväg förbi den. ]]
	local pass = Pass.nyState(HAST_ID, Pass.byggId(1, HAST_ID, 1))
	Pass.vidUppsittning(pass)
	Pass.vidAvsittning(pass)
	PC.tillampaPass(Pass.vy(pass, 9000))
	visa(Preparation.STATUS.REDO)
	local e = ytor()
	prova("i eftervården möts `redo` och en full panel",
		e.interaktion.Visible == true and #PC._synligaMoment() > 0
			and PC.redo() == true,
		("%d moment"):format(#PC._synligaMoment()))
	prova("servern tillåter fortfarande en andra uppsittning",
		Pass.farSittaUpp(pass) == true,
		("Pass.farSittaUpp = %s"):format(tostring(Pass.farSittaUpp(pass))))
	prova("men uppgiften är SKÖTSEL, så knappen står inte bredvid texten",
		PC.aktuellUppgift() == "skotsel" and promptar().MountPrompt == nil,
		if promptar().MountPrompt then "MountPrompt kvar" else "(borta)")
	prova("och ledknappen konkurrerar inte heller i eftervården",
		promptar().LedPrompt == nil,
		if promptar().LedPrompt then "LedPrompt kvar" else "(borta)")

	--[[ ══ #264 PLAYER_INTERACTION_CONSOLIDATION: SAMMA LÄGE, I PANELEN ══

		Kontraktet: i eftervården förklarar panelen det faktiska steget och
		erbjuder dess handling; en orelaterad Mount-rekommendation står inte
		bredvid. En giltig efterritt läses i panelen och avfärdas där, och
		FÖRST DÄREFTER tar eftervården över. Mätt genom produktionens väg —
		passets vy, skötselns adapter, panelens egen ritning. ]]
	local NR = Naromrade
	NR.satRider(false)
	game:GetService("RunService").Heartbeat:Fire(1 / 60)
	local pnl = NR._panel()
	local valText = {}
	for _, v in pairs(NR._val()) do table.insert(valText, tostring(v.text)) end
	local pgui = game:GetService("Players").LocalPlayer:FindFirstChildOfClass("PlayerGui")
	local skotselYta = pgui and pgui:FindFirstChild("UBRFForberedelse")
	prova("EN YTA: panelen bär eftervården, skötselns egen yta är släckt",
		pnl.synlig and #valText > 0
			and (skotselYta == nil or skotselYta.Enabled == false),
		("panel %s · %d val: %s"):format(tostring(pnl.synlig), #valText,
			table.concat(valText, " | ")))
	local mountRad = false
	for _, t in ipairs(NR._rader()) do
		if string.find(t, Sprak.t("interaktion.sitt_upp"), 1, true) then mountRad = true end
	end
	prova("och ingen Mount-rad står bredvid eftervårdens instruktion",
		not mountRad, table.concat(NR._rader(), " | "))

	--[[ EFTERRITTEN GÅR FÖRE. Lektionens summering visas genom sin egen väg
		(`UgnetaController.efterritt`); panelen ska bära dess knapp i stället
		för eftervårdens val tills spelaren avfärdat den. ]]
	UgnetaController.efterritt({ { dim = "rytm", sort = "bra" } })
	NR.satRider(false)
	local efterVal = {}
	for _, v in pairs(NR._val()) do table.insert(efterVal, tostring(v.text)) end
	prova("EN GILTIG EFTERRITT LÄSES I PANELEN FÖRE EFTERVÅRDEN",
		#efterVal == 1 and string.find(efterVal[1],
			Sprak.t("ugneta.efterritt.stang"), 1, true) ~= nil
			and NR._panel().ater ~= "",
		("val: %s · återkoppling %q"):format(table.concat(efterVal, " | "),
			NR._panel().ater))
	--[[ Avfärdad genom panelens egen rad — samma handling som knappen. ]]
	local forsta = NR._val()[1]
	if forsta and forsta.skicka then forsta.skicka() end
	NR.satRider(false)
	local efterAvfard = {}
	for _, v in pairs(NR._val()) do table.insert(efterAvfard, tostring(v.text)) end
	prova("och när den avfärdats tar eftervården över igen",
		UgnetaController.vantar() == false and #efterAvfard == #valText,
		("%d val: %s"):format(#efterAvfard, table.concat(efterAvfard, " | ")))

	--[[ ETT SENT SVAR ERSÄTTER INTE PANELEN. En äldre vy — ett helt annat
		tillstånd, en tidigare revision — kommer fram efter den aktuella.
		Skötseln kastar den (krav 10), och panelen läser skötselns
		tillstånd, inte vyn: rubrik och val ska stå orörda. ]]
	local rubrikFore = NR._panel().rubrik
	local valFore = #efterAvfard
	PC.tillampa(Preparation.vy(Preparation.nyState(HAST_ID, 1),
		Preparation.STATUS.FORBEREDER, rev - 3, "Trixie"))
	NR.satRider(false)
	local valEfter = 0
	for _ in pairs(NR._val()) do valEfter += 1 end
	--[[ ETT NEJ EFTER VYN SYNS I PANELEN. Mätt i Studio: servern nekade ett
		skötselmoment och panelens återkopplingsfält var tomt, för nejet
		skrevs bara i skötselns egna, släckta etiketter. ]]
	PC.visaAvslagFor("hud.gick_inte_nu")
	NR.satRider(false)
	prova("ETT NEJ SOM KOMMER EFTER VYN STÅR I PANELENS ÅTERKOPPLING",
		NR._panel().ater == Sprak.t("hud.gick_inte_nu"),
		("återkoppling %q"):format(NR._panel().ater))
	prova("och nästa steg står kvar ovanför nejet",
		NR._panel().steg ~= "" and NR._panel().steg ~= NR._panel().ater,
		("steg %q"):format(NR._panel().steg))
	--[[ Samma väg för ett JA: en kvittens utifrån (ledningen lånar den)
		kommer efter vyn och ska också nå panelen, inte bara skötselns
		släckta etiketter. ]]
	local kvitto = "KVITTENS EFTER VYN"
	PC.visaBekraftelseFor(kvitto)
	NR.satRider(false)
	prova("EN KVITTENS SOM KOMMER EFTER VYN STÅR I PANELENS ÅTERKOPPLING",
		string.find(NR._panel().ater, kvitto, 1, true) ~= nil,
		("återkoppling %q"):format(NR._panel().ater))
	prova("ETT SENT SVAR FRÅN EN TIDIGARE VY ERSÄTTER INTE PANELEN",
		NR._panel().rubrik == rubrikFore and valEfter == valFore,
		("rubrik %q → %q · val %d → %d"):format(rubrikFore, NR._panel().rubrik,
			valFore, valEfter))

	--[[ ANDRA LEDET AV PUNKT 3: «When no care step is waiting / ride is
		the relevant next action — Mount may return.» Eftervården görs klar
		genom passets egen modul, och knapparna ska komma tillbaka av sig
		själva. Utan den här raden hade en regel som gömmer Mount för alltid
		efter första ritten kommit ut grön. ]]
	while true do
		local m = Pass.nastaMoment(pass)
		if not m then break end
		if not Pass.utfor(pass, m.id) then break end
	end
	PC.tillampaPass(Pass.vy(pass, 9001))
	visa(Preparation.STATUS.REDO)
	prova("när eftervården är gjord är uppgiften RIDA och knappen tillbaka",
		PC.aktuellUppgift() == "rida" and promptar().MountPrompt ~= nil
			and promptar().LedPrompt ~= nil,
		("uppgift %s · %d moment kvar"):format(PC.aktuellUppgift(),
			#PC._synligaMoment()))

	--[[ Tillbaka till en vanlig dag för resten av specen: avsnitt 4 och 5
		mäter ledningen mot skötseln, inte mot en eftervård. ]]
	PC.tillampaPass(Pass.vy(Pass.nyState(HAST_ID, Pass.byggId(1, HAST_ID, 2)),
		9002))
	state = Preparation.nyState(HAST_ID, 1)
	for _, fas in ipairs(Preparation.stegFaser()) do
		if fas.id ~= "leda" then gorFas(fas.id) end
	end
	visa(Preparation.STATUS.FORBEREDER)
end

print("\n── 3e. Stegets verkliga handling står först (#264) ──")

--[[ Mätt i Studio, två gånger: momentet stod på tur men handlingen som
	utför det låg bakom overflow, för den enda fasta platsen gick till Rida
	nu. Kontraktet: förberedelsen visar det aktuella steget OCH dess
	verkliga handling. Steget känns igen på momentets kanoniska id.

	  ledsteget     dörren först (den ska öppnas), sedan ledningen
	  utrustningen  sadeln först, tränset sist (kanon: «Träns på sist») ]]
do
	local NR = Naromrade
	local function sakMed(namn, promptNamn, lage, forHast)
		local del = Instance.new("Part")
		del.Name = namn
		del.Size = Vector3.new(1, 1, 1)
		del.CFrame = CFrame.new(lage)
		if forHast then del:SetAttribute("ForHast", forHast) end
		local p = Instance.new("ProximityPrompt")
		p.Name = promptNamn
		p.ActionText = promptNamn
		p.KeyboardKeyCode = Enum.KeyCode.X
		p.MaxActivationDistance = 10
		p.Enabled = true
		p.Parent = del
		del.Parent = workspace
		return del, p
	end
	local function namnIPanelen()
		local ut = {}
		for _, p in ipairs(NR._prompter()) do table.insert(ut, p.Name) end
		return ut
	end
	local function paTur()
		for _, v in ipairs(NR._val()) do
			if v.paTur then return tostring(v.id) end
		end
		return "-"
	end
	local bas = kropp.CFrame.Position

	-- Ledsteget: skötseln är gjord, `leda` står på tur (slutet av 3d).
	local dorr = sakMed("Grind", "DorrPrompt", bas + Vector3.new(2, 0, 0))
	NR.satRider(false)
	local ordning = namnIPanelen()
	prova("LEDSTEGET: dörren och ledningen står först, i den ordningen",
		paTur() == "leda" and ordning[1] == "DorrPrompt"
			and ordning[2] == "LedPrompt",
		("på tur %s · %s"):format(paTur(), table.concat(ordning, " | ")))
	dorr:Destroy()

	-- Utrustningen: allt före `iordning` gjort, och hovarna i den.
	local forrad = Instance.new("Model")
	forrad.Name = "Boxfront"
	forrad:SetAttribute("ForHast", HAST_ID)
	local sadel = sakMed("Sadelhylla", "SadelPrompt", bas + Vector3.new(1.5, 0, 0))
	local trans = sakMed("Transkrok", "TransPrompt", bas + Vector3.new(1.0, 0, 0))
	sadel.Parent = forrad
	trans.Parent = forrad
	forrad.Parent = workspace
	state = Preparation.nyState(HAST_ID, 1)
	for _, fas in ipairs(Preparation.stegFaser()) do
		if fas.id == "iordning" then break end
		gorFas(fas.id)
	end
	local function gorTill(stopp)
		while true do
			local m = Preparation.nastaMoment(state, "iordning")
			if not m or stopp(m.id) then break end
			if not Preparation.utforMoment(state, "iordning", m.id, HAST_ID) then break end
		end
	end
	gorTill(function(id) return string.sub(id, 1, 4) == "utr:" end)
	visa(Preparation.STATUS.FORBEREDER)
	NR.satRider(false)
	local forst = namnIPanelen()
	prova("UTRUSTNINGEN: sadeln först, tränset efter — inte Rida nu",
		paTur() == "utr:1" and forst[1] == "SadelPrompt"
			and forst[2] == "TransPrompt",
		("på tur %s · %s"):format(paTur(), table.concat(forst, " | ")))

	local antal = 0
	for _, m in ipairs(Preparation.moment and Preparation.moment("iordning") or {}) do
		if string.sub(m.id, 1, 4) == "utr:" then antal += 1 end
	end
	gorTill(function(id) return id == "utr:" .. antal end)
	visa(Preparation.STATUS.FORBEREDER)
	NR.satRider(false)
	local sist = namnIPanelen()
	prova("och i sista utrustningssteget står tränset först",
		antal > 1 and paTur() == "utr:" .. antal and sist[1] == "TransPrompt",
		("%d utr-moment · på tur %s · %s"):format(antal, paTur(),
			table.concat(sist, " | ")))
	forrad:Destroy()

	-- Tillbaka till utgångsläget för avsnitt 4: `leda` står på tur.
	state = Preparation.nyState(HAST_ID, 1)
	for _, fas in ipairs(Preparation.stegFaser()) do
		if fas.id ~= "leda" then gorFas(fas.id) end
	end
	visa(Preparation.STATUS.FORBEREDER)
end

print("\n── 3f. Frågans alternativ är lika före svaret (R2) ──")
do
	--[[ #264 PLAYABLE_UI_AND_DISMOUNT_R2: hälsningens första alternativ är
	     fel men fick guldet (på tur), och fyndets rätta svar fick det
	     (`not s.fel`) — båda talade om svaret innan spelaren valt. ]]
	local NR = Naromrade
	local function lyfta()
		local ut = {}
		for _, v in ipairs(NR._val()) do
			if v.paTur then table.insert(ut, tostring(v.text)) end
		end
		return ut, #NR._val()
	end
	state = Preparation.nyState(HAST_ID, 1)
	visa(Preparation.STATUS.FORBEREDER)
	NR.satRider(false)
	local harFel = false
	for _, v in ipairs(NR._val()) do if v.fel then harFel = true end end
	local l1, n1 = lyfta()
	prova("HÄLSNINGEN: inget alternativ lyft före svaret",
		harFel and n1 >= 2 and #l1 == 0,
		("%d alternativ, lyfta: %s"):format(n1, table.concat(l1, " | ")))

	local vy = Preparation.vy(state, Preparation.STATUS.FORBEREDER, rev + 1, "Trixie")
	rev += 1
	vy.svar = { { id = "fel1", namn = "Fel svar", fel = true }, { id = "ratt", namn = "Rätt svar", fel = false } }
	vy.fynd = "Något i hoven"
	PC.tillampa(vy)
	NR.satRider(false)
	local l2, n2 = lyfta()
	prova("FYNDET: det rätta svaret lyfts inte fram",
		n2 == 2 and #l2 == 0, ("%d alternativ, lyfta: %s"):format(n2, table.concat(l2, " | ")))

	state = Preparation.nyState(HAST_ID, 1)
	for _, fas in ipairs(Preparation.stegFaser()) do
		if fas.id ~= "leda" then gorFas(fas.id) end
	end
	visa(Preparation.STATUS.FORBEREDER)
end

print("\n── 4. Ledningen: kortet är borta, nederkanten står kvar ──")

do
	local fore = ytor().framsteg.Text
	Net.get("LedSync").OnClientEvent:Fire({ leder = true, hastId = HAST_ID })
	local l = ytor()
	prova("kontexten är ledning", PC.kontext() == "ledning", PC.kontext())
	prova("klienten vet att hon leder — genom serverns egen kanal",
		PC._leder() == true)
	prova("framstegskortet är BORTA", l.sparare.Visible == false,
		("Visible = %s"):format(tostring(l.sparare.Visible)))
	--[[ Nederkanten får INTE följa med. Den bär `leda`-momentet, och den
		bär ledningens kvittenser och nej (`led.tappade_bort`,
		`led.kvar_i_boxen`). Släcktes den hade ledningen blivit stum. ]]
	prova("men instruktionsytan lever — den är den relevanta ytan nu",
		l.interaktion.Visible == true and l.instruktion.Text ~= "",
		('"%s"'):format(tostring(l.instruktion.Text)))
	prova("och släpp-knappen står kvar — man ska kunna släppa igen",
		promptar().LedPrompt ~= nil)

	print("\n── 5. Tillbaka i boxen: samma progression ──")
	Net.get("LedSync").OnClientEvent:Fire({ leder = false, hastId = nil,
		skal = "led.tappade_bort" })
	local ater = ytor()
	prova("kontexten är skötsel igen", PC.kontext() == "skotsel", PC.kontext())
	prova("kortet är tillbaka", ater.sparare.Visible == true)
	prova("med exakt de framsteg som gällde när det försvann",
		ater.framsteg.Text == fore,
		('"%s" -> "%s"'):format(tostring(fore), tostring(ater.framsteg.Text)))
end

print("\n── 6. Ritten: kortet är borta, hela ytan är släckt ──")

do
	visa(Preparation.STATUS.RIDER)
	local r = ytor()
	local g = barn(player._gui, "UBRFForberedelse")
	prova("kontexten är ridning", PC.kontext() == "ridning", PC.kontext())
	prova("hela skötselytan är släckt",
		g ~= nil and g.Enabled == false,
		("Enabled = %s"):format(tostring(g and g.Enabled)))
	--[[ TVÅ GRINDAR, med flit. `Enabled` är ytans, `Visible` är kortets.
		Den som tänder ytan av misstag — en layoutpassning, en ny panel i
		samma ScreenGui — ska inte kunna få tillbaka framstegskortet i
		sadeln på köpet. ]]
	prova("och kortet är dessutom osynligt i sig",
		r.sparare.Visible == false,
		("Visible = %s"):format(tostring(r.sparare.Visible)))

	print("\n── 6b. Avsittningen tar tillbaka det ──")
	visa(Preparation.STATUS.FORBEREDER)
	prova("kortet är uppe igen efter avsittning",
		PC.kontext() == "skotsel" and ytor().sparare.Visible == true)
end

print("\n── 7. Ledningens regel lånar inte uppsittningens ──")

--[[ AVSNITTET FINNS FÖR ATT EN MUTATION KOM UT GRÖN.

	`farVisasLed` löd förut `if farVisas(model) then return true end` före
	allt annat: var hästen REDO ritades ledknappen oavsett vad `ledFor`
	sa. Falsifieringen som återinförde den raden ändrade ingenting —
	uppsittningens grind i `init.client` säger ju också nej så fort ett
	skötselsteg äger fokus, så de två guarderna stod i serie och den
	yttre räckte.

	DET ÄR PRECIS DÄRFÖR KOPPLINGEN ÄR FARLIG: ledningens synlighet
	vilade på uppsittningens svar, och den som en dag ändrar Mount-regeln
	hade flyttat ledknappen på köpet utan att något prov sagt ifrån.

	Mätningen tvingar isär dem. Uppsittningens svar sätts till ETT
	ORUBBLIGT JA — precis det svar den gamla raden lät passera — medan
	uppgiften är skötsel. Ledknappen ska ändå vara borta.

	ANDRA RADEN ÄR INTE DEKORATION: utan den hade provet varit grönt även
	om stubben inte bet, och då hade det mätt ingenting alls. ]]
do
	state = Preparation.nyState(HAST_ID, 1)
	visa(Preparation.STATUS.FORBEREDER)
	prova("utgångsläget: uppgiften är skötsel",
		PC.aktuellUppgift() == "skotsel", PC.aktuellUppgift())

	--[[ Sätts SIST i specen. `setReadyCheck` har ingen avläsare, så den
		äkta grinden ur `init.client` går inte att lägga tillbaka utan att
		skriva av den — och en avskrift hade varit en andra sanning om
		regeln. ]]
	IC.setReadyCheck(function(): boolean return true end)
	IC.uppdatera()
	local p = promptar()
	prova("stubben biter — uppsittningsknappen kommer fram på hennes ja",
		p.MountPrompt ~= nil,
		if p.MountPrompt then "(kvar)" else "MountPrompt uteblev — provet mäter inget")
	prova("men ledknappen är fortfarande borta — den lyder sin egen regel",
		p.LedPrompt == nil,
		if p.LedPrompt then "LedPrompt tänd av uppsittningens svar" else "(borta)")
end

print("")
if fel > 0 then
	print(("%d mätningar föll."):format(fel))
	error(("%d fel"):format(fel))
else
	print("Alla mätningar gick igenom.")
end
