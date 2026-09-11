--!strict
--[[
	LEDA HÄSTEN — spelaren går, hästen följer.

	Blockerare 2 i #162. Rutten var framkomlig (boxdörren i 27e5c2a, mätt
	0 av 9 punkter blockerade) men hästen leddes aldrig av någon: testet
	drev henne med `Humanoid:MoveTo` från en ingenjörs hand, och `leda`
	blev sann så fort spelaren tryckte — även med hästen kvar i boxen.

	DEN HÄR TJÄNSTEN ÄR AVSIKTLIGT LITEN. Scope guardrailen i CLAUDE.md
	säger ett lätt, responsivt ridspel och inte en simulator: ingen
	vägsökning, ingen egen fysik, ingen state machine. Hästen får ett mål
	bakom spelaren varje bildruta och går dit med sin EGEN Humanoid — samma
	lokomotion som Gate 1 mätte. Inget CFrame-släpande, ingen ankring,
	ingen teleport, ingen osynlig transportband.

	HYSTERESEN ÄR POÄNGEN. Ett enda avståndsvärde ger en häst som startar
	och stannar varje bildruta på gränsen — det syns som ryck och som att
	hon studsar kring målpunkten. Därför två trösklar: hon stannar när hon
	kommit innanför STOPP_R och börjar inte gå igen förrän avståndet
	passerat START_R. Mellan dem gör hon ingenting, och det är precis den
	dödzonen som gör att hon står stilla när spelaren står stilla.

	KOPPLET är inte en gräns för att vara sträng. Går spelaren ifrån henne
	ska ledningen SLÄPPA i stället för att hästen ska springa genom en
	vägg för att hinna ikapp — och spelaren ska få veta varför.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HorseCore = require(ReplicatedStorage.HorseCore)
local Net = HorseCore.Networking
local Gaits = require(ReplicatedStorage.HorseCore.Gaits)

local LedService = {}

local M = 3                    -- studs per meter, som BuildKit.M

--[[ Måtten är spelkänsla, inte mätningar av verkligheten, och står därför
	här och inte i den delade världsdatan. ]]
local RACKVIDD   = 4.0         -- m: så nära måste man stå för att få börja leda
local FOLJ_BAKOM = 2.4         -- m: hästens målpunkt bakom spelaren
local STOPP_R    = 1.0         -- m: innanför detta står hon still
local START_R    = 1.8         -- m: utanför detta går hon igen (hysteres)
local KOPPEL     = 9.0         -- m: längre bort och kopplet släpper

--[[ EN LEDD HÄST SKRITTAR. Farten hämtas ur gångartskanonen och skrivs
	inte av som ett tal: `Gaits.DATA.walk.norm` är skrittens nominella
	fart i m/s och är samma siffra ridningen räknar med.

	Varför det behövs: en oriden häst har `WalkSpeed = 0` — `HorseService`
	nollar den när ryttaren stiger av, och klientens MovementController
	sätter den bara medan någon rider. Mätt i Studio gav `MoveTo` då en
	riktning men noll förflyttning. Ledningen måste alltså ge henne en
	fart, och lämna tillbaka den när kopplet släpper. ]]
local function skrittfart(): number
	local w = Gaits.DATA and Gaits.DATA.walk
	return ((w and w.norm) or 1.45) * M
end

export type Led = {
	modell: Model,
	hastId: string,
	gar: boolean,          -- hysteresens läge: går hon just nu?
	lamnatBox: boolean,    -- har hon FYSISKT varit utanför boxen?
	malNatt: boolean,      -- har hon FYSISKT varit i målzonen?
	boxX: number, boxY: number,
	tidigareFart: number,
	tidigareSpelarfart: number,
	spar: { Vector3 },
	dorr: BasePart?,
	dorrUt: Vector3?,
	dorrsteg: number,
}

local ledd: { [Player]: Led } = {}
local hakar: { [string]: (Player, Led) -> () } = {}

--[[ ── Koordinater ──────────────────────────────────────────────────
	Samma omräkning som BuildKit.tomtkoord, men utan att kräva
	anläggningens bas: världen byggs alltid med tomtens origo i (0, 0,
	djup) och norr = −Z. Tjänsten ska kunna svara även innan modellen
	hittats. ]]
local TOMTDJUP = 170

local function tomt(p: Vector3): (number, number)
	return p.X / M, TOMTDJUP - p.Z / M
end

local function avstandM(a: Vector3, b: Vector3): number
	return (Vector3.new(a.X, 0, a.Z) - Vector3.new(b.X, 0, b.Z)).Magnitude / M
end

--[[ En rektangel i tomtkoordinater. `iRekt` används både för boxen och
	för målzonen, så det finns en enda regel för "är hon där". ]]
export type Rekt = { x: number, y: number, w: number, h: number }

function LedService.iRekt(p: Vector3, r: Rekt): boolean
	local x, y = tomt(p)
	return x >= r.x and x <= r.x + r.w and y >= r.y and y <= r.y + r.h
end

--[[ ── Tillståndet ─────────────────────────────────────────────────── ]]

function LedService.aktiv(player: Player): Model?
	local l = ledd[player]
	return l and l.modell or nil
end

function LedService.lage(player: Player): Led?
	return ledd[player]
end

--[[ Har hästen fysiskt lämnat sin box? Sätts av loopen när hon faktiskt
	är utanför, och nollställs aldrig — steget ska inte kunna ångras av
	att hon råkar backa tillbaka en halvmeter. ]]
function LedService.harLamnatBox(player: Player): boolean
	local l = ledd[player]
	return l ~= nil and l.lamnatBox
end

function LedService.harNattMal(player: Player): boolean
	local l = ledd[player]
	return l ~= nil and l.malNatt
end

--[[ Målzonen. Sätts av den som äger gameplayet (GameplayService) så att
	tjänsten inte behöver känna till vare sig ridhuset eller faserna. ]]
local malzon: Rekt? = nil
function LedService.satMalzon(r: Rekt?)
	malzon = r
end
function LedService.malzon(): Rekt?
	return malzon
end

--[[ ── Att börja leda ───────────────────────────────────────────────
	Varje nej har en egen nyckel. Ett enda "gick inte" hade gjort de
	negativa fallen omöjliga att skilja åt i ett test. ]]
function LedService.borja(player: Player, modell: Model?, ratt: Model?): (boolean, string?)
	--[[ `IsA` i stället för `typeof`: bänkens stubbinstanser rapporterar
		"table", och en typeof-vakt hade gjort tjänsten omöjlig att mäta
		utan att säga något om produktionen. Att modellen svarar på `IsA`
		och säger sig vara en Model är det som faktiskt betyder något. ]]
	if type(modell) ~= "table" and typeof(modell) ~= "Instance" then
		return false, "led.ingen_hast"
	end
	local kanIsA = modell ~= nil and (modell :: any).IsA ~= nil
	if not kanIsA or not (modell :: any):IsA("Model") then
		return false, "led.ingen_hast"
	end
	--[[ RÄTT HÄST. Att leda någon annans häst är inte en teknikalitet:
		hela skötselkanonen bygger på att man arbetar med SIN häst. ]]
	if ratt ~= nil and modell ~= ratt then
		return false, "led.fel_hast"
	end
	local karaktar = player.Character
	local rot = karaktar and karaktar:FindFirstChild("HumanoidRootPart")
	if not (rot and rot:IsA("BasePart")) then
		return false, "led.ingen_karaktar"
	end
	local hum = karaktar and karaktar:FindFirstChildOfClass("Humanoid")
	--[[ Sitter man upp leder man inte — då rider man. ]]
	if hum and hum.Sit then
		return false, "led.rider"
	end
	local pivot = modell.PrimaryPart or modell:FindFirstChildWhichIsA("BasePart")
	if not pivot then
		return false, "led.hast_saknar_kropp"
	end
	if avstandM(rot.Position, pivot.Position) > RACKVIDD then
		return false, "led.for_langt"
	end
	if ledd[player] then
		return false, "led.leder_redan"
	end
	--[[ Två spelare kan inte leda samma häst. ]]
	for annan, l in pairs(ledd) do
		if l.modell == modell then
			return false, "led.upptagen"
		end
	end
	local bx, by = tomt(pivot.Position)

	--[[ ── BOXDÖRREN SOM WAYPOINT ──────────────────────────────────────

		Mätt i Studio: hästen kilade sig mot `Boxfront MB 5` och norra
		skiljeväggen med `MoveDirection = 0`. Hon är 1,85 m lång och
		öppningen 1,20 m bred, och `MoveTo` styr RAKT mot målet — från ett
		hörn i facket går den linjen genom panelen.

		Spårföljningen räcker inte här: brödsmulorna ligger rätt, men hon
		måste RIKTA UPP kroppen mot öppningen innan hon går igenom. Därför
		två delmål — först en punkt rakt innanför dörren, sedan en rakt
		utanför. Två punkter, ingen vägsökning.

		Dörren letas upp EN gång, vid start, och bara om hon faktiskt står
		i en box. Leds hon på öppen yta finns ingen dörr och hela grenen
		hoppas över. ]]
	local narmasteDorr, narmast = nil, 3.2 * M
	local anlaggning = workspace:FindFirstChild("Anläggning")
	if anlaggning then
		for _, d in ipairs(anlaggning:GetDescendants()) do
			if d:IsA("BasePart") and d:GetAttribute("UBRFBoxdorr") == true then
				local avst = (d.Position - pivot.Position).Magnitude
				if avst < narmast then narmasteDorr, narmast = d, avst end
			end
		end
	end
	local dorrUt: Vector3? = nil
	if narmasteDorr then
		--[[ `Langs` säger vilken axel fronten löper i; `Utat` åt vilket
			håll gången ligger. Båda sätts av `Anlaggningen`. ]]
		local langs = narmasteDorr:GetAttribute("Langs")
		local utat = tonumber(narmasteDorr:GetAttribute("Utat")) or 1
		dorrUt = if langs == "Z"
			then Vector3.new(utat, 0, 0)
			else Vector3.new(0, 0, utat)
	end

	local hastHum = (modell :: any):FindFirstChildOfClass("Humanoid")
	local tidigareFart = hastHum and hastHum.WalkSpeed or 0
	if hastHum then
		hastHum.WalkSpeed = skrittfart()
	end
	--[[ MAN SPRINGER INTE MED EN HÄST I HANDEN.

		Roblox default är 16 studs/s — 5,3 m/s, alltså språng. En skrittande
		häst går 1,45 m/s. Mätt i Studio: spelaren drog ifrån 22 m på fyra
		sekunder, kopplet löste ut som det ska, och ledningen blev därmed
		oanvändbar.

		Spelaren går därför i ledningstakt så länge hon leder, och får sin
		egen fart tillbaka när hon släpper. Marginalen gör att hon kan gå
		före utan att hästen halkar efter. ]]
	local spelarHum2 = karaktar and karaktar:FindFirstChildOfClass("Humanoid")
	local tidigareSpelarfart = spelarHum2 and spelarHum2.WalkSpeed or 16
	if spelarHum2 then
		spelarHum2.WalkSpeed = skrittfart() * 1.15
	end
	ledd[player] = {
		tidigareFart = tidigareFart,
		tidigareSpelarfart = tidigareSpelarfart,
		modell = modell,
		hastId = tostring(modell:GetAttribute("HorseId") or ""),
		gar = false,
		lamnatBox = false,
		malNatt = false,
		boxX = bx, boxY = by,
		spar = {},
		dorr = narmasteDorr,
		dorrUt = dorrUt,
		dorrsteg = 1,
	}
	LedService._sync(player)
	return true, nil
end

--[[ Att sluta leda. `skal` är nil när spelaren själv släpper och en
	nyckel när kopplet, döden eller uppsittningen gjorde det. ]]
function LedService.slapp(player: Player, skal: string?): (boolean, string?)
	local l = ledd[player]
	if not l then
		return false, "led.leder_inte"
	end
	--[[ Hästen ska STÅ, inte fortsätta mot sitt sista mål. Utan den här
		raden gick hon vidare några meter efter att kopplet släppt. ]]
	local hum = l.modell:FindFirstChildOfClass("Humanoid")
	if hum then
		hum:Move(Vector3.zero, false)
		--[[ Farten tillbaka som den var. Lämnas den kvar står en släppt
			häst och skrittar iväg av sig själv nästa gång något rör
			hennes Humanoid. ]]
		hum.WalkSpeed = l.tidigareFart
	end
	--[[ Spelarens egen fart tillbaka. Utan den går hon kvar i
		ledningstakt resten av passet. ]]
	local karaktar2 = player.Character
	local spelarHum3 = karaktar2 and karaktar2:FindFirstChildOfClass("Humanoid")
	if spelarHum3 then
		spelarHum3.WalkSpeed = l.tidigareSpelarfart
	end
	ledd[player] = nil
	LedService._sync(player, skal)
	return true, skal
end

function LedService._sync(player: Player, skal: string?)
	local ev = Net.get("LedSync")
	local l = ledd[player]
	ev:FireClient(player, {
		leder = l ~= nil,
		hastId = l and l.hastId or nil,
		lamnatBox = l ~= nil and l.lamnatBox or false,
		malNatt = l ~= nil and l.malNatt or false,
		skal = skal,
	})
end

--[[ ── Följandet ────────────────────────────────────────────────────
	Ett steg per bildruta. Allt som händer här är att hästen får ett mål
	och att tre tillstånd uppdateras. ]]
local function steg(_dt: number)
	for player, l in pairs(ledd) do
		local karaktar = player.Character
		local rot = karaktar and karaktar:FindFirstChild("HumanoidRootPart")
		local hum = l.modell:FindFirstChildOfClass("Humanoid")
		local pivot = l.modell.PrimaryPart

		--[[ Försvann något — karaktären dog, hästen togs bort — släpper
			kopplet i stället för att loopen ska räkna på nil. ]]
		if not (rot and rot:IsA("BasePart")) or not hum or not pivot
			or not l.modell.Parent then
			LedService.slapp(player, "led.tappad")
			continue
		end

		--[[ Sitter spelaren upp mitt i ledningen är hon ryttare nu. ]]
		local spelarHum = karaktar and karaktar:FindFirstChildOfClass("Humanoid")
		if spelarHum and spelarHum.Sit then
			LedService.slapp(player, "led.rider")
			continue
		end

		local avst = avstandM(rot.Position, pivot.Position)
		if avst > KOPPEL then
			LedService.slapp(player, "led.tappade_bort")
			continue
		end

		--[[ Har hon lämnat boxen? Mäts på FAKTISK position, inte på att
			spelaren tryckt på något. ]]
		if not l.lamnatBox then
			local x, y = tomt(pivot.Position)
			if math.sqrt((x - l.boxX) ^ 2 + (y - l.boxY) ^ 2) > 2.5 then
				l.lamnatBox = true
				LedService._sync(player)
			end
		end
		if malzon and not l.malNatt and LedService.iRekt(pivot.Position, malzon) then
			l.malNatt = true
			LedService._sync(player)
		end

		--[[ HÄSTEN GÅR I SPELARENS SPÅR, inte mot en punkt bakom henne.

			En rak linje till en punkt bakom spelaren fungerar på öppen
			yta men inte genom en dörr: mätt i Studio kilade sig hästen
			fast mot `Boxfront MB 5` och norra skiljeväggen med
			`MoveDirection = 0`, för att linjen gick genom väggen.
			Boxdörren är 1,20 m och hästen 1,85 m lång — hon måste rikta
			upp sig mot öppningen, inte skära hörnet.

			Spåret löser det utan vägsökning: spelaren gick ju själv genom
			dörren. Vi sparar hennes senaste lägen och skickar hästen till
			den äldsta brödsmulan som ligger minst FOLJ_BAKOM bort. Då
			följer hon vägen som fungerade i stället för fågelvägen.

			Ringbufferten är kort med flit — den ska bära genom en dörr,
			inte minnas en rundtur. ]]
		local spar = l.spar
		local senaste = spar[#spar]
		--[[ ETT HOPP ÄR INGEN VÄG. Flyttas spelaren långt på en bildruta —
			respawn, en spec som ställer henne någon annanstans — är spåret
			dit inte gångbart, och hästen skulle skickas till en punkt hon
			aldrig kan nå. Då kastas spåret. ]]
		if senaste and (senaste - rot.Position).Magnitude > 3.0 * M then
			table.clear(spar)
			senaste = nil
		end
		if not senaste or (senaste - rot.Position).Magnitude > 0.6 * M then
			table.insert(spar, rot.Position)
			if #spar > 40 then table.remove(spar, 1) end
		end
		--[[ Smulor längre bort än kopplet hör inte hit heller. ]]
		while #spar > 0 and avstandM(spar[1], rot.Position) > KOPPEL do
			table.remove(spar, 1)
		end

		local bakom = rot.Position - rot.CFrame.LookVector * (FOLJ_BAKOM * M)
		for i = 1, #spar do
			if avstandM(spar[i], rot.Position) >= FOLJ_BAKOM then
				bakom = spar[i]
				break
			end
		end

		--[[ Så länge hon inte lämnat boxen går dörren före spåret. Steg 1
			ställer henne rakt innanför öppningen, steg 2 tar henne ut. ]]
		local viaDorr = false
		if not l.lamnatBox and l.dorr and l.dorrUt and l.dorr.Parent then
			viaDorr = true
			local ut1 = l.dorr.Position - l.dorrUt * (1.3 * M)
			local ut2 = l.dorr.Position + l.dorrUt * (2.2 * M)
			if l.dorrsteg == 1 then
				if avstandM(pivot.Position, ut1) < 0.9 then
					l.dorrsteg = 2
				else
					bakom = ut1
				end
			end
			if l.dorrsteg == 2 then bakom = ut2 end
		end
		local tillMal = avstandM(pivot.Position, bakom)

		--[[ Hon får skynda på inom SKRITTENS eget band när hon hamnat
			efter. Bandet kommer ur `Gaits`; hon börjar aldrig trava. ]]
		if hum.WalkSpeed > 0 then
			local w = Gaits.DATA and Gaits.DATA.walk
			local lag = math.clamp((avst - FOLJ_BAKOM) / 4.0, 0, 1)
			local m_s = ((w and w.norm) or 1.45) + lag * (((w and w.max) or 2.0) - ((w and w.norm) or 1.45))
			hum.WalkSpeed = m_s * M
		end

		--[[ HYSTERESEN GÄLLER FÖLJANDET, INTE DÖRREN.

			Dödzonen finns för att hon inte ska pendla kring en punkt som
			rör sig med spelaren. En waypoint rör sig inte: den ska nås.
			Mätt i Studio stod hon still 1,19 m från delmålet, eftersom
			1,19 < startröskeln 1,8 — och kom därför aldrig ut ur boxen.
			Vid dörren går hon tills hon är framme. ]]
		if viaDorr then
			if tillMal > 0.35 then
				l.gar = true
				hum:MoveTo(Vector3.new(bakom.X, pivot.Position.Y, bakom.Z))
			else
				l.gar = false
				hum:Move(Vector3.zero, false)
			end
		elseif l.gar then
			if tillMal < STOPP_R then
				l.gar = false
				hum:Move(Vector3.zero, false)
			else
				hum:MoveTo(Vector3.new(bakom.X, pivot.Position.Y, bakom.Z))
				--[[ Passerad brödsmula tas bort, annars går hon tillbaka
					till den om hon råkar komma nära igen. ]]
				if #l.spar > 0 and avstandM(pivot.Position, l.spar[1]) < 1.2 then
					table.remove(l.spar, 1)
				end
			end
		else
			if tillMal > START_R then
				l.gar = true
				hum:MoveTo(Vector3.new(bakom.X, pivot.Position.Y, bakom.Z))
			end
		end
	end
end

function LedService.start()
	Net.get("LedSync")

	Net.get("LedBorja").OnServerInvoke = function(player, modell)
		local hak = hakar.ratt
		local ratt = hak and hak(player, nil :: any) or nil
		return LedService.borja(player, modell, ratt)
	end
	Net.get("LedSlapp").OnServerInvoke = function(player)
		return LedService.slapp(player)
	end

	Players.PlayerRemoving:Connect(function(player)
		if ledd[player] then LedService.slapp(player, "led.tappad") end
	end)

	RunService.Heartbeat:Connect(steg)
	print("[Led] Ledningen igång")
end

--[[ Den som äger tilldelningen (GameplayService) lämnar en krok som
	svarar VILKEN häst spelaren får leda. Tjänsten slår inte upp det
	själv: då hade den behövt känna till skötseln. ]]
function LedService.satRattHastKrok(f: ((Player, Model?) -> Model?)?)
	hakar.ratt = f :: any
end

--[[ För specar: kör EN bildruta explicit.

	Heartbeat tickar inte i en spec, och att låta testet sätta flaggorna
	själv hade gjort mätningen värdelös — då prövar den sin egen
	uppfattning i stället för tjänstens. Den här sömmen kör exakt samma
	`steg` som produktionen, så det som mäts är det som körs. ]]
function LedService._steg(dt: number?)
	steg(dt or (1 / 60))
end

--[[ För specar: nollställ utan att röra spelare. ]]
function LedService._glomForProv()
	for p in pairs(ledd) do ledd[p] = nil end
	malzon = nil
end

return LedService
