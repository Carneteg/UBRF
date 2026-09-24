--!strict
--[[
	UTRUSTNINGEN SOM GAMEPLAY — vem den tillhör, vem som får sätta på den,
	och att tillståndet ALDRIG kan påstå något som världen inte visar.

	══ VARFÖR TJÄNSTEN INTE HAR NÅGON EGEN TABELL ══════════════════════

	Före blockerare 5 var "sadlad" två booleans i `Preparation.state`. Den
	sortens tillstånd kan ljuga: en klient som spoofar ett moment, ett
	avbrutet flöde eller ett fel mitt i bygget lämnar en häst som SÄGS vara
	sadlad utan att något ligger på ryggen.

	Därför för den här tjänsten inget register. `harTack()` letar upp den
	fysiska delen i hästmodellen och läser dess attribut. Finns ingen del
	finns inget tillstånd. Det gör det omöjligt för logiskt och fysiskt att
	glida isär, i stället för att göra det osannolikt.

	══ VEM UTRUSTNINGEN TILLHÖR ════════════════════════════════════════

	Webbens sadelkammare (`src/sysslor.js`) är kanon: varje häst har sin
	egen sadel på egen bygel och sitt eget träns på egen krok, med
	namnskylt, och fel utrustning nekas med ett skäl —

	  "En sadel är formad efter en bestämd rygg. På fel häst trycker den
	   antingen på manken eller på njurarna."
	  "Ett träns är inställt efter ett bestämt huvud. På fel häst hamnar
	   bettet för högt eller för lågt i munnen."

	Identiteten är alltså hästens egen id. Ingen separat utrustningstabell
	behövs och ingen hittas på: `ForHast` på delen ÄR ägarskapet, och
	felräknaren motsvarar webbens `G.felUtrustning`.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HorseCore = require(ReplicatedStorage.HorseCore)
local RigAdapter = HorseCore.RigAdapter
local Skotsel = require(ReplicatedStorage.UBRFSkotsel)
local TackRigg = require(script.Parent.TackRigg)

local TackService = {}

local M = 3
local RACKVIDD = 4.0   -- m: så nära måste man stå, som ledningen

--[[ ORDNINGEN KOMMER UR KANON, inte ur den här filen. `sadelfaser` i
	`UBRFSkotsel` är den delade listan båda plattformarna läser:

	  1 underlägget högt på manken
	  2 sadeln bakom bogbladet
	  3 sadelbommen i, manken fri
	  4 gjorda i tre tag
	  5 tränset sist

	Stegen 1, 2 och 5 skapar var sin FYSISK del. 3 och 4 är handgrepp på
	den sadel som redan ligger där — de kräver alltså att sadeln finns,
	men lägger inget nytt på hästen. Kopplingen står här, på ett ställe,
	och `fysiskFor()` är det enda som vet vilket steg som ger vad. ]]
local STEG_DEL = { [1] = "underlagg", [2] = "sadel", [5] = "trans" }
local STEG_KRAVER = { [3] = "sadel", [4] = "sadel", [5] = "sadel" }

function TackService.antalSteg(): number
	return #Skotsel.sadelfaser
end

function TackService.fysiskFor(steg: number): string?
	return STEG_DEL[steg]
end

--[[ Vad steget FÖRUTSÄTTER ligger på hästen redan. ]]
function TackService.kraver(steg: number): string?
	return STEG_KRAVER[steg]
end

--[[ EFTERVÅRDENS FYSISKA MOTSVARIGHET.

	Samma sorts karta som `STEG_DEL` ovan, och här av samma skäl: vilket
	moment som rör vilken del på hästen hör hemma på ETT ställe, och det
	stället är tjänsten som äger utrustningen.

	`Skotsel.eftervard` är kanon och listar fem moment. Två av dem rör
	något som faktiskt ligger på henne:

	  sadel  "Ta av sadel och underlägg"        → båda, i den ordningen
	  trans  "Grimma på först, sedan tränset av" → tränset; tyglarna
	         följer med i `taAv`, som de följde med på

	`gjord` lossar gjorden medan sadeln LIGGER KVAR — kanon säger det
	uttryckligen — och `ben` och `vatten` rör ingen utrustning alls. De
	har därför ingen fysisk del, och får inte hitta på en. ]]
local EFTERVARD_DEL: { [string]: { string } } = {
	sadel = { "sadel", "underlagg" },
	trans = { "trans" },
}

function TackService.eftervardsDelar(momentId: string): { string }?
	return EFTERVARD_DEL[momentId]
end

--[[ ── VÄRLDENS EGEN SANNING ──────────────────────────────────────── ]]

--[[ Bär hästen den här utrustningen, och tillhör den HENNE? En del med
	fel `ForHast` räknas inte som påsatt: det är precis den motsägelse
	tjänsten finns för att omöjliggöra. ]]
function TackService.harTack(modell: Model, typ: string): boolean
	local d = TackRigg.hittaDel(modell, typ)
	if not d then return false end
	local hastId = tostring(modell:GetAttribute("HorseId") or "")
	return tostring(d:GetAttribute("ForHast") or "") == hastId
end

function TackService.sadlad(modell: Model): boolean
	return TackService.harTack(modell, "sadel")
end

function TackService.transad(modell: Model): boolean
	return TackService.harTack(modell, "trans")
end

--[[ Allt som ska sitta på innan man får sitta upp. Läser världen. ]]
function TackService.ridklar(modell: Model): (boolean, string?)
	if not TackService.sadlad(modell) then return false, "tack.saknar_sadel" end
	if not TackService.transad(modell) then return false, "tack.saknar_trans" end
	return true
end

--[[ ── DET SPELAREN BÄR MELLAN BOXFRONTEN OCH HÄSTEN (#182) ───────────

	Samma doktrin som resten av filen, och därför inget register: den
	burna delen ligger i spelarens karaktär, och `barBuren()` läser den
	där. Hämtningens VAL bor kvar i `GameplayService.valdUtrustning` —
	det är serverns auktoritativa sanning om vilken hästs utrustning
	spelaren tog — och delarna här är dess SYNLIGA form. Att låta dem
	vara sanningen i stället hade gjort en riven del till en tyst
	avhämtning.

	Bara sadeln och tränset går att bära. Underlägget och tyglarna
	hämtas i samma upphängning och följer sin bärande del, precis som
	de gör när de sitter på hästen. ]]
local BARBARA: { [string]: boolean } = { sadel = true, trans = true }

local function karaktarFor(player: Player): Model?
	local k = (player :: any).Character
	if typeof(k) ~= "Instance" and type(k) ~= "table" then return nil end
	if not (k and (k :: any).IsA and k:IsA("Model")) then return nil end
	return k :: Model
end

--[[ Vilken hästs utrustning spelaren bär av den här typen, eller nil. ]]
function TackService.barBuren(player: Player, typ: string): string?
	local k = karaktarFor(player)
	if not k then return nil end
	local d = TackRigg.hittaBuren(k, typ)
	if not d then return nil end
	local id = tostring(d:GetAttribute("ForHast") or "")
	return if id ~= "" then id else nil
end

--[[ Lägger utrustningen i spelarens händer. Samma id igen rör ingenting;
	ett NYTT id byter ut delen, för då har spelaren gått tillbaka till en
	annan boxfront och tagit en annan hästs sadel. ]]
function TackService.satBuren(player: Player, typ: string, hastId: string?): boolean
	if not BARBARA[typ] then return false end
	local k = karaktarFor(player)
	if not k then return false end
	if type(hastId) ~= "string" or hastId == "" then return false end
	if TackService.barBuren(player, typ) == hastId then return true end
	TackRigg.slappBuren(k, typ)
	return TackRigg.byggBuren(k, typ, hastId) ~= nil
end

function TackService.slappBuren(player: Player, typ: string): boolean
	local k = karaktarFor(player)
	if not k then return false end
	return TackRigg.slappBuren(k, typ)
end

--[[ Allt ur händerna. Används när passet avslutas och när utrustningen
	byts ut i klump. ]]
function TackService.slappAllBuren(player: Player)
	for typ in pairs(BARBARA) do
		pcall(function() TackService.slappBuren(player, typ) end)
	end
end

--[[ ── ATT SÄTTA PÅ ───────────────────────────────────────────────── ]]

--[[ Felräknaren, webbens `G.felUtrustning`. Per spelare och pass. ]]
local felUtrustning: { [Player]: number } = {}
function TackService.felAntal(player: Player): number
	return felUtrustning[player] or 0
end
function TackService.nollstallFel(player: Player)
	felUtrustning[player] = nil
end

--[[ `utrustningId` är den häst utrustningen TILLHÖR — sadeln man tog i
	sadelkammaren. Den skickas med hela vägen så att fel sadel kan nekas
	här, serverauktoritärt, och inte bara i ett gränssnitt. ]]
function TackService.satPa(player: Player, modell: Model?, typ: string,
	utrustningId: string?, rattHast: Model?): (boolean, string?)
	if typeof(modell) ~= "Instance" and type(modell) ~= "table" then
		return false, "tack.ingen_hast"
	end
	local m = modell :: Model
	if not (m and (m :: any).IsA and m:IsA("Model")) then
		return false, "tack.ingen_hast"
	end
	if rattHast ~= nil and m ~= rattHast then
		return false, "tack.fel_hast"
	end
	if TackRigg.BYGGARE[typ] == nil then
		return false, "tack.okand_utrustning"
	end

	local hastId = tostring(m:GetAttribute("HorseId") or "")
	--[[ FEL UTRUSTNING. Samma regel och samma skäl som webbens
		sadelkammare: utrustningen är formad efter en bestämd rygg och ett
		bestämt huvud. Räknas, precis som `G.felUtrustning`. ]]
	if utrustningId ~= nil and utrustningId ~= hastId then
		felUtrustning[player] = (felUtrustning[player] or 0) + 1
		return false, if typ == "trans" then "tack.fel_trans" else "tack.fel_sadel"
	end

	--[[ DUBBEL PÅSÄTTNING. Den som redan ligger där ska inte få en till. ]]
	if TackRigg.hittaDel(m, typ) ~= nil then
		return false, "tack.redan_pa"
	end

	--[[ ORDNINGEN: tränset kräver sadeln, för kanon lägger det sist. ]]
	if typ == "trans" and not TackService.sadlad(m) then
		return false, "tack.sadeln_forst"
	end
	if typ == "sadel" and not TackService.harTack(m, "underlagg") then
		return false, "tack.underlagget_forst"
	end

	--[[ NÄRHETEN. Utrustning sätts på med händerna. ]]
	local karaktar = player.Character
	local rot = karaktar and karaktar:FindFirstChild("HumanoidRootPart")
	if not (rot and rot:IsA("BasePart")) then return false, "tack.ingen_karaktar" end
	local pivot = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
	if not pivot then return false, "tack.hast_saknar_kropp" end
	local avst = (Vector3.new(rot.Position.X, 0, rot.Position.Z)
		- Vector3.new(pivot.Position.X, 0, pivot.Position.Z)).Magnitude / M
	if avst > RACKVIDD then return false, "tack.for_langt" end

	--[[ ── DEN FYSISKA DELEN ──────────────────────────────────────────
		Byggs SIST, när allt annat sagt ja. Misslyckas bygget sätts inget
		tillstånd — det finns inget tillstånd att sätta, för tillståndet
		ÄR delen. Det är hela poängen med att inte föra register. ]]
	local rig = RigAdapter.build(m)
	if not rig then return false, "tack.ingen_rigg" end
	local byggare = TackRigg.BYGGARE[typ]
	local ok, del = pcall(byggare, m, rig, hastId)
	if not ok or del == nil then
		--[[ Städa efter ett halvbyggt försök så att världen inte bär
			en halv sadel som `harTack` sedan skulle kalla påsatt. ]]
		pcall(function() TackRigg.taAv(m, typ) end)
		return false, "tack.kunde_inte_byggas"
	end

	--[[ TYGLARNA HÖR TILL TRÄNSET. De sitter i bettet och är inte ett eget
		moment i kanon — `leda` säger "med tyglarna över halsen", alltså
		förutsätts de sitta när hon leds. De byggs därför med tränset och
		tas av med det. Misslyckas de tas tränset bort igen: ett träns utan
		tyglar är inte det tillstånd spelet påstår. ]]
	if typ == "trans" then
		local okT, delT = pcall(TackRigg.byggTyglar, m, rig, hastId)
		if not okT or delT == nil then
			pcall(function() TackRigg.taAv(m, "tygel") end)
			pcall(function() TackRigg.taAv(m, "trans") end)
			return false, "tack.kunde_inte_byggas"
		end
	end

	--[[ DEN BURNA DELEN FLYTTAR TILL HÄSTEN (#182). Sadeln lämnar
		händerna när den läggs på ryggen, tränset när det sitter på
		huvudet. SIST, av samma skäl som bygget ligger sist: släpptes
		den innan delen var på plats hade ett misslyckat bygge lämnat
		spelaren tomhänt med en osadlad häst.

		Underlägget släpper INTE sadeln — det ligger under henne, och
		spelaren bär sadeln vidare tills den är på. ]]
	if BARBARA[typ] then
		--[[ ── OCH UTFALLET PRÖVAS (#264) ─────────────────────────────

			Här stod `pcall(function() TackService.slappBuren(...) end)`
			och sedan `return true`. Bådadera kastades bort: `pcall`:s
			eget `ok` och `slappBuren`:s returvärde. Gick släppet inte
			fram svarade `satPa` ändå JA, och spelaren stod kvar med
			sadeln i handen på en häst som var sadlad.

			Tobias rapporterade precis det i sitt playtest 2026-09-24.
			Delen på hästen och kopian i handen är två påståenden om
			samma sak, och när de säger emot varandra får svaret inte
			vara «klart».

			Nejet är namngivet och läsbart, och tillståndet går att
			återhämta: hästen ÄR sadlad, så ett nytt försök möter
			`tack.redan_pa` och kan då släppa handen. Ingen tyst
			klientdöljning, ingen framtvingad fullbordan. ]]
		--[[ BARA OM HON FAKTISKT BÄR EN. `satPa` går också den
		     automatiska vägen, där stallet lägger på utrustningen utan
		     att någon hållit i den — då svarar `slappBuren` nej med
		     rätta, för det fanns ingenting att släppa. Första rättelsen
		     saknade det villkoret och gjorde 65 mätningar i
		     `integration.spec` röda. ]]
		local barFore = TackService.barBuren(player, typ) ~= nil
		local ok, slapptes = pcall(function()
			return TackService.slappBuren(player, typ)
		end)
		if barFore and not (ok and slapptes) then
			warn(("[Tack] %s bär kvar sin %s trots att den sitter på hästen")
				:format(player.Name, typ))
			return false, "tack.bars_kvar"
		end
	end
	return true
end

function TackService.taAv(player: Player, modell: Model?, typ: string): (boolean, string?)
	if not (modell and (modell :: any).IsA and modell:IsA("Model")) then
		return false, "tack.ingen_hast"
	end
	local m = modell :: Model
	if TackRigg.hittaDel(m, typ) == nil then
		return false, "tack.inget_pa"
	end
	--[[ ── ORDNINGEN AV ÄR EFTERVÅRDENS, INTE PÅSÄTTNINGENS BAKLÄNGES ──

		Rättelse i #211. Spärren stod förut tvärtom — den nekade SADELN
		under tränset med `tack.transet_forst` — medan dess egen kommentar
		citerade kanon rätt. Följden var att den kanoniska eftervården var
		omöjlig att utföra: `UBRFSkotsel.eftervard` tar sadeln i moment 2
		och tränset i moment 3, så vid sadelmomentet sitter tränset alltid
		kvar, och varje avsadling hade nekats.

		Kanon, vaktad av ordningsgrinden i `tools/exportera-spel.js`:

		  gjord   "Lossa gjorden några hål. Låt sadeln ligga kvar."
		  sadel   "Ta av sadel och underlägg."
		  trans   "Grimma på först, sedan tränset av."

		Skälet står i `src/spel/skotsel.js`: sadeln av innan tränset,
		annars står hon lös med sadeln kvar. Tränset är alltså det som
		HÅLLER henne medan sadeln lyfts av, och grimman kommer på innan
		det tas av. Underlägget ligger under sadeln och kan inte tas
		först — den spärren var och förblir rätt. ]]
	if typ == "trans" and TackService.sadlad(m) then
		return false, "tack.sadeln_av_forst"
	end
	if typ == "underlagg" and TackService.sadlad(m) then
		return false, "tack.sadeln_forst"
	end
	TackRigg.taAv(m, typ)
	--[[ Tyglarna följer tränset av, av samma skäl som de följer med på. ]]
	if typ == "trans" then pcall(function() TackRigg.taAv(m, "tygel") end) end
	return true
end

--[[ Allt av, i kanonordning. Används när passet avslutas.

	SVEPET PÅ SLUTET är inte ett bälte till hängslena utan en rättelse.
	`TackRigg.taAv` river en typ genom att ta den BÄRANDE delen och det som
	är svetsat i henne. Har den bärande delen försvunnit på något annat
	sätt — ett halvt bygge som städades, en rigg som byttes — hittar den
	ingenting, och sadelns valv, gjord och stigbyglar blir kvar hängande på
	en häst som spelet påstår är avsadlad.

	Funktionen heter ALLT av. Då ska den betyda det, och det enda sättet
	att mena det är att mappen är tom efteråt. ]]
function TackService.taAvAllt(modell: Model)
	for _, typ in ipairs({ "tygel", "trans", "sadel", "underlagg" }) do
		pcall(function() TackRigg.taAv(modell, typ) end)
	end
	local f = TackRigg.mapp(modell)
	if f then f:Destroy() end
end

Players.PlayerRemoving:Connect(function(player)
	felUtrustning[player] = nil
end)

return TackService
