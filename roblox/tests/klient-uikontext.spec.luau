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
	  6. konkurrensen: `LedPrompt` finns inte medan ett skötselsteg står
	     och väntar på ett tryck, med de två undantag som gör att
	     ledningsloopen ändå inte kan låsa — och varför `MountPrompt`
	     inte fick någon sådan regel (avsnitt 3c).

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

print("\n── 3. Konkurrensen: ett mål, en instruktion, en handling ──")

do
	visa(Preparation.STATUS.FORBEREDER)
	local p = promptar()
	prova("ett skötselsteg står och väntar på ett tryck",
		PC.skotselstegVantar() == true and PC.nastaFas() ~= nil,
		("fas %s"):format(tostring(PC.nastaFas())))
	prova("då finns ingen ledknapp på hästen", p.LedPrompt == nil,
		if p.LedPrompt then "LedPrompt kvar" else "(borta)")
	--[[ Uppsittningen är borta här av ett ANNAT skäl: `redo` är falskt så
		länge en fas återstår. Raden mäter alltså inte konkurrensregeln —
		se avsnitt 3c för varför Mount inte har någon. ]]
	prova("och ingen uppsittningsknapp heller — `redo` är falskt",
		p.MountPrompt == nil and PC.redo() == false,
		if p.MountPrompt then "MountPrompt kvar" else "(borta)")
	--[[ «Rida nu» RÖRS INTE. Ordern namnger Lead och Mount, och genvägen
		till sadeln är FUN FIRST / RIDE FIRST:s eget svar på «jag vill inte
		göra det här steget». Faller den här raden har städningen tagit
		med sig produktkärnan. ]]
	prova("men «Rida nu» står kvar — genvägen är aldrig irrelevant",
		p.RidaNuPrompt ~= nil,
		if p.RidaNuPrompt then "(kvar)" else "RidaNuPrompt borttagen")

	--[[ UTOM RÄCKHÅLL finns ingen panel, alltså ingen konkurrens — och då
		ska ledknappen tillbaka. Utan det här vore regeln "ledningen är
		borta så snart du har en häst". ]]
	kropp.CFrame = CFrame.new(hastRot.CFrame.Position
		+ Vector3.new(Config.STEG_RACKVIDD * 4, 0, 0))
	PC.uppdateraKontext()
	IC.uppdatera()
	prova("utom räckhåll konkurrerar ingenting, och ledknappen är tillbaka",
		PC.ledningKonkurrerar() == false and promptar().LedPrompt ~= nil)
	kropp.CFrame = CFrame.new(hastRot.CFrame.Position)
	PC.uppdateraKontext()
	IC.uppdatera()
end

print("\n── 3b. Undantaget som håller ledningsloopen öppen ──")

do
	--[[ #162 blockerare 2: `leda` bockas av genom att hon FYSISKT leds
		till ridhuset. Göms knappen när `leda` står på tur finns ingen väg
		att fästa kopplet, och loopen låser. Faller den här raden är den
		buggen tillbaka. ]]
	for _, f in ipairs(Preparation.stegFaser()) do
		if f.id ~= "leda" then gorFas(f.id) end
	end
	visa(Preparation.STATUS.FORBEREDER)
	prova("nu står `leda` på tur", PC.nastaFas() == "leda",
		tostring(PC.nastaFas()))
	prova("och då konkurrerar ledningen inte — den ÄR steget",
		PC.ledningKonkurrerar() == false)
	prova("ledknappen finns", promptar().LedPrompt ~= nil)
end

print("\n── 3c. Varför «Mount» inte fick någon konkurrensregel ──")

--[[ FÖRSTA VERSIONEN AV DET HÄR PROVET MÄTTE FEL SAK, och det är därför
	avsnittet finns.

	Raden "och ingen uppsittningsknapp heller" i avsnitt 3 står i ett läge
	där `halsa` är på tur — alltså `redo == false`, och då ritar `farVisas`
	ingen `MountPrompt` ändå. En mutation som rev en Mount-grind ur
	`setReadyCheck` kom ut GRÖN: provet mätte `redo`, inte regeln.

	Jakten på ett läge där grinden HADE betytt något gav svaret att den
	inte ska finnas:

	  fyndets fråga   `autoForbered` låter med flit bli att kvittera
	                  `visitera` medan ett fynd är osett-men-orapporterat,
	                  så `redo` är falskt hela den vägen. Ingen kollision.
	  eftervården     `redo` ÄR sant och panelen ÄR full — men `Pass
	                  .farSittaUpp` släpper uttryckligen en andra
	                  uppsittning så länge inget eftervårdsmoment är gjort.
	                  Knappen är alltså RELEVANT, och att gömma den hade
	                  varit precis den Mount-regression ordern förbjuder.

	Avsnittet mäter båda leden, så att en framtida "städning" som lägger
	till grinden blir röd här i stället för hos spelaren. ]]
do
	--[[ Hela dagen gjord, som servern gör den: momenten genom modulens
		egen väg, inte genom att sätta `klara` för hand. ]]
	state = Preparation.nyState(HAST_ID, 1)
	for _, fas in ipairs(Preparation.stegFaser()) do gorFas(fas.id) end
	visa(Preparation.STATUS.REDO)
	prova("när hästen är redo står ingen fas kvar att konkurrera med",
		PC.redo() == true and PC.nastaFas() == nil
			and PC.skotselstegVantar() == false,
		("redo %s · fas %s · steg väntar %s"):format(tostring(PC.redo()),
			tostring(PC.nastaFas()), tostring(PC.skotselstegVantar())))
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
			and PC.redo() == true and PC.skotselstegVantar() == true,
		("%d moment"):format(#PC._synligaMoment()))
	prova("men servern tillåter en andra uppsittning innan eftervården börjat",
		Pass.farSittaUpp(pass) == true,
		("Pass.farSittaUpp = %s"):format(tostring(Pass.farSittaUpp(pass))))
	prova("så knappen ska stå kvar — att gömma den vore en regression",
		promptar().MountPrompt ~= nil,
		if promptar().MountPrompt then "(kvar)" else "MountPrompt borttagen")

	--[[ Tillbaka till en vanlig dag för resten av specen: avsnitt 4 och 5
		mäter ledningen mot skötseln, inte mot en eftervård. ]]
	PC.tillampaPass(Pass.vy(Pass.nyState(HAST_ID, Pass.byggId(1, HAST_ID, 2)),
		9001))
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
	prova("och släpp-knappen rivs aldrig medan kopplet sitter",
		PC.ledningKonkurrerar() == false and promptar().LedPrompt ~= nil)

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

print("")
if fel > 0 then
	print(("%d mätningar föll."):format(fel))
	error(("%d fel"):format(fel))
else
	print("Alla mätningar gick igenom.")
end
