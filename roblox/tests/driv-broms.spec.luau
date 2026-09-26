--!nostrict
--[[
	KONTEXTUELL RID-UX — DRIV OCH BROMS.

	Arkitekturbeslut och Acceptance Contract 2026-09-17. Kontraktet har
	fyra grindar, och den här filen mäter tre av dem i körande kod. Den
	fjärde — att panelens kod är BORTA ur källan — går inte att mäta i en
	bänk som bara ser det som kompilerats in; den ligger i
	`tools/kolla-reglagepanel.py`, som läser filerna på disk.

	  1. `ContextActionService` har helt ersatt den tidigare
	     ridnings-UI-logiken: två namngivna handlingar, kontraktets
	     tangenter, pekknappar som CAS själv ritar — och ingen egen
	     `TextButton` i vår ScreenGui.
	  2. Tillståndsmaskinen tvingar spelaren att stega genom varje
	     gångart:  Rygga ↔ Halt ↔ Skritt ↔ Trav ↔ Galopp.
	  3. Ingen hållen knapp krävs för fortsatt rörelse.
	  4. (se ovan)

	VARFÖR EN EGEN SPEC när `touch`, `movement` och `klient` redan rör vid
	delarna: de mäter var sin modul. Kontraktet är en kedja mellan tre —
	`Input`, `MovementController` och `TouchControls` — och ett fel i
	skarven mellan dem är grönt i alla tre var för sig. Det var precis så
	den gamla panelen kunde vara "mätt" och ändå falla på iPad.

	Kör: python3 roblox/tests/build.py tests/driv-broms.spec.luau
	     && luau roblox/tests/.build/driv-broms.spec.luau
]]

local fel = 0
local function check(vad, ok, detalj)
	if ok then
		print(("  OK   %s%s"):format(vad, if detalj then "  " .. detalj else ""))
	else
		fel += 1
		print(("  FEL  %s%s"):format(vad, if detalj then "  " .. detalj else ""))
	end
end

local UIS = game:GetService("UserInputService")
local CAS = game:GetService("ContextActionService")
local spelare = game:GetService("Players").LocalPlayer
local kam = workspace.CurrentCamera
spelare:WaitForChild("PlayerGui")
local playerGui = spelare:FindFirstChildOfClass("PlayerGui")

local STATS = {
	Speed = 0.5, Acceleration = 0.5, Agility = 0.5, Stamina = 0.5,
	MaxStamina = 100, Temperament = "Calm",
}

local function barn(inst, namn)
	for _, b in ipairs(inst and inst._barn or {}) do
		if b.Name == namn then return b end
	end
	return nil
end

--[[ Styrd klocka, samma skäl som i `touch.spec`: spärren är en tidsregel
     och provet ska kunna flytta tiden i stället för att sova. ]]
local klocka = 5000.0
Input._klocka = function() return klocka end
local function efterSparren()
	klocka += Input.IMPULS_SPARR + 0.01
end

local function nyttEkipage()
	Input.unbind()
	Input.bind()
	efterSparren()
	return MovementController.new(__makeRig(), STATS)
end

--[[ En avsikt som inputlagret hade kunnat producera. Allt som inte anges
     är noll — och poängen med hela beslutet är att det räcker. ]]
local function avsikt(o)
	o = o or {}
	return { forward = o.forward or 0, steer = o.steer or 0,
		gaitUp = o.gaitUp or false, gaitDown = o.gaitDown or false,
		jump = false, rein = 0, parad = o.parad or 0, seat = 0 }
end

--[[ En HJÄLP, hela vägen genom produktionens kedja: CAS-handlingen fyrar,
     `Input.consume()` läser flanken, och `MovementController` får den.

     Det är den här funktionen som gör specen till en kedjemätning i
     stället för tre modulmätningar. Går något sönder i skarven — en
     handling som inte är bunden, en flank som inte konsumeras, en avsikt
     som tappas — blir varje mätning nedan röd. ]]
local function hjalp(mc, handling, sekunder)
	efterSparren()
	local fn = CAS._bound[handling]
	if not fn then return false end
	fn(handling, Enum.UserInputState.Begin, { KeyCode = Enum.KeyCode.Unknown })
	local dt = 1 / 60
	local forsta = Input.consume()
	mc:step(forsta, dt)
	--[[ Resten av tiden är TOM. Ingen knapp hålls, ingen axel skrivs. ]]
	for _ = 2, math.floor((sekunder or 1.5) / dt) do
		mc:step(avsikt(), dt)
	end
	return true
end

local function driv(mc, sek) return hjalp(mc, Input.DRIV, sek) end
local function broms(mc, sek) return hjalp(mc, Input.BROMS, sek) end

--[[ ══ 1. CAS HAR ERSATT RIDNINGENS UI-LOGIK ═════════════════════════ ]]
print("\n── 1. Två handlingar, inga egna knappar ──")
do
	Input.unbind()
	check("innan uppsittningen är ingen av handlingarna bunden",
		CAS._bound[Input.DRIV] == nil and CAS._bound[Input.BROMS] == nil)

	Input.bind()
	check("DRIV heter det kontraktet säger", Input.DRIV == "ActionDriv", Input.DRIV)
	check("BROMS likaså", Input.BROMS == "ActionBroms", Input.BROMS)
	check("båda är bundna i ContextActionService",
		CAS._bound[Input.DRIV] ~= nil and CAS._bound[Input.BROMS] ~= nil)

	--[[ `createTouchButton`. Stubben skapar knappen BARA när flaggan är
	     sann, precis som Roblox — se noten i `stubs.luau`. Utan den här
	     mätningen hade en iPad kunnat stå utan reglage med resten grönt. ]]
	check("DRIV ritar en pekknapp som CAS äger",
		CAS:GetButton(Input.DRIV) ~= nil)
	check("BROMS gör det också", CAS:GetButton(Input.BROMS) ~= nil)

	--[[ KONTRAKTETS TANGENTER. Slås upp i den lista `BindAction` fick, så
	     att mätningen är på bindningen och inte på en gissning. ]]
	local function harTangent(handling, kod)
		for _, t in ipairs(CAS._bound[handling .. "@tangenter"] or {}) do
			if t == kod then return true end
		end
		return false
	end
	check("DRIV lyssnar på W och ↑",
		harTangent(Input.DRIV, Enum.KeyCode.W)
			and harTangent(Input.DRIV, Enum.KeyCode.Up))
	check("BROMS lyssnar på S och ↓",
		harTangent(Input.BROMS, Enum.KeyCode.S)
			and harTangent(Input.BROMS, Enum.KeyCode.Down))
	check("och handkontrollen når samma två handlingar",
		harTangent(Input.DRIV, Enum.KeyCode.ButtonR1)
			and harTangent(Input.BROMS, Enum.KeyCode.ButtonL1))

	--[[ W OCH S ÄR INTE LÄNGRE EN AXEL. Den mätningen hör hemma här och
	     inte bara i `touch.spec`: det är den halvan av grind 1 som säger
	     att den gamla logiken är ERSATT och inte bara kompletterad. ]]
	__key(Enum.KeyCode.W, true)
	local i = Input.consume()
	check("W ger en impuls och rör inte framåtaxeln",
		i.gaitUp == true and i.forward == 0,
		("(gaitUp %s · forward %.1f)"):format(tostring(i.gaitUp), i.forward))

	--[[ Det gamla pek-API:t ska vara BORTA, inte tyst. Låg det kvar fanns
	     en ospärrad väg in i trappan vid sidan av handlingarna. ]]
	check("`Input.touchGait` finns inte längre", Input.touchGait == nil)
	check("`Input.touchGaitTo` finns inte längre", Input.touchGaitTo == nil)
end

print("\n── 1b. Pekytan bygger inga egna reglageknappar ──")
do
	TouchControls.unmount()
	UIS.TouchEnabled = true
	kam.ViewportSize = { _typ = "Vector2", X = 1180, Y = 820 }
	Input.unbind(); Input.bind()
	local avsuttna = 0
	TouchControls.mount(Input, { dismount = function() avsuttna += 1 end })
	local ht = barn(playerGui, "HorseTouch")
	check("pekreglagen monterades", ht ~= nil and TouchControls.isActive())

	check("gångartsgallret finns inte", barn(ht, "Gangarter") == nil)
	check("hjälpargallret finns inte", barn(ht, "Knappar") == nil)
	check("spaken och blickytan står kvar",
		barn(ht, "Spak") ~= nil and barn(ht, "Blickyta") ~= nil)

	--[[ KONTRAKTETS ABSOLUTA FÖRBUD, mätt som en svepning: ingen
	     `TextButton` och ingen `ImageButton` någonstans i vår egen
	     ScreenGui. Spaken är två `Frame`, blickytan en tredje. ]]
	local knappar = {}
	local function svep(inst)
		for _, b in ipairs(inst._barn or {}) do
			local k = tostring(b.ClassName)
			if k == "TextButton" or k == "ImageButton" then
				table.insert(knappar, ("%s(%s)"):format(k, b.Name))
			end
			svep(b)
		end
	end
	svep(ht)
	check("ingen egen knapp i HorseTouch — förbudet i kontraktet",
		#knappar == 0, table.concat(knappar, " "))

	--[[ …men de tre handlingarna ÄR klädda. Utan de här raderna vore
	     mätningen ovan grön också om reglagen bara saknades. ]]
	check("DRIV har fått sin titel", CAS._titel[Input.DRIV] ~= nil,
		tostring(CAS._titel[Input.DRIV]))
	check("BROMS har fått sin titel", CAS._titel[Input.BROMS] ~= nil,
		tostring(CAS._titel[Input.BROMS]))
	check("och de säger inte samma sak",
		CAS._titel[Input.DRIV] ~= CAS._titel[Input.BROMS])
	check("båda har fått en plats genom SetPosition",
		CAS._plats[Input.DRIV] ~= nil and CAS._plats[Input.BROMS] ~= nil)

	--[[ NEDRE HÖGRA HÖRNET, och BROMS under DRIV. `SetPosition` räknar
	     från blockets ankare, så båda X- och Y-skalan ska vara 1 och
	     förskjutningarna negativa — alltså inåt och uppåt från hörnet. ]]
	local d, b = CAS._plats[Input.DRIV], CAS._plats[Input.BROMS]
	check("de ligger i skärmens nedre högra hörn",
		d.X.Scale == 1 and d.Y.Scale == 1 and d.X.Offset < 0 and d.Y.Offset < 0,
		("DRIV (%.0f,%.0f)+(%d,%d)"):format(d.X.Scale, d.Y.Scale, d.X.Offset, d.Y.Offset))
	check("BROMS ligger UNDER DRIV — upp är upp",
		b.Y.Offset > d.Y.Offset,
		("broms %d · driv %d (mindre negativt = längre ned)"):format(b.Y.Offset, d.Y.Offset))

	--[[ GENOMSKINLIGHET: kontraktet säger uttryckligen att knapparna inte
	     får vara solida block över ridningen. ]]
	local kd = CAS:GetButton(Input.DRIV)
	check("knappen är genomskinlig, inte ett solitt block",
		kd ~= nil and kd.BackgroundTransparency > 0 and kd.BackgroundTransparency < 1,
		kd and ("%.2f"):format(kd.BackgroundTransparency) or "ingen knapp")

	--[[ AVSITTNINGEN: #162 blockerare 2 får inte återuppstå när panelens
	     `SITT AV` försvinner. Vägen av hästen är en handling till, och den
	     ska ha en pekknapp. Bindningen ägs av `init.client`; provet binder
	     den själv, precis som klienten gör vid uppsittningen. ]]
	CAS:BindAction(Input.AVSITT, function(_, lage)
		if lage == Enum.UserInputState.Begin then avsuttna += 1 end
		return Enum.ContextActionResult.Sink
	end, true, Enum.KeyCode.E)
	TouchControls.unmount()
	TouchControls.mount(Input, { dismount = function() avsuttna += 1 end })
	check("avsittningen har en pekknapp", CAS:GetButton(Input.AVSITT) ~= nil)
	check("och en egen etikett", CAS._titel[Input.AVSITT] ~= nil,
		tostring(CAS._titel[Input.AVSITT]))
	check("den är svagare än ridreglagen — hittbar, inte lättryckt",
		CAS:GetButton(Input.AVSITT).BackgroundTransparency
			> CAS:GetButton(Input.BROMS).BackgroundTransparency)
	CAS._bound[Input.AVSITT]("x", Enum.UserInputState.Begin, {})
	check("och den sitter faktiskt av", avsuttna == 1, ("(%d)"):format(avsuttna))

	--[[ ══ VAKTEN MOT EN SLÄCKT `ContextActionGui` ═══════════════════

	     `egnaReglage` sätter `UserInputService.ModalEnabled` för att
	     släcka Roblox egna pekreglage. Om den raden — eller något annat —
	     också släcker CAS EGEN yta står iPad utan reglage: knapparna finns
	     men ingen ser dem. Det är den enda kända okända i den här gaten.

	     Vakten i `TouchControls` tänder ytan igen. Provet gör det som inte
	     går att göra i verkligheten utan en enhet: släcker ytan med flit
	     och mäter att monteringen tänder den.

	     DET BEVISAR INTE att `ModalEnabled` är ofarlig. Det bevisar att
	     vakten fungerar om den behövs. Frågan står kvar som NOT_TESTED. ]]
	do
		local yta = nil
		for _, g in ipairs(playerGui._barn or {}) do
			if g.Name == "ContextActionGui" then yta = g end
		end
		check("CAS-knapparna bor i sin egen yta", yta ~= nil)
		if yta then
			yta.Enabled = false
			TouchControls.unmount()
			TouchControls.mount(Input, { dismount = function() end })
			check("en släckt CAS-yta tänds av monteringen — iPad blir aldrig utan reglage",
				yta.Enabled == true, tostring(yta.Enabled))
		end
	end

	--[[ ══ OCH VAKTEN MÅSTE STÅ EFTER DEN RAD SOM KAN SLÄCKA YTAN ═════

	     Mätningen ovan släcker ytan FÖRE monteringen. Den fångar en yta
	     som redan var mörk — men det är inte det fall vakten skrevs för.

	     Det befarade fallet är att `egnaReglage(false)` SJÄLV släcker
	     `ContextActionGui` när den sätter `ModalEnabled`. Och den raden
	     körs INUTI `mount`. Låg vakten före den kunde den aldrig se sin
	     egen skada: den läste ytan, fann den tänd, och släcktes den en
	     rad senare stod iPad utan reglage med hela bänken grön.

	     Provet gör det som bara en fysisk enhet annars kan svara på:
	     kopplar `ModalEnabled` till precis den skada den misstänks göra,
	     och mäter att monteringen ändå lämnar ytan tänd. Faller den här
	     raden har vakten flyttats tillbaka före `egnaReglage`. ]]
	do
		local yta = nil
		for _, g in ipairs(playerGui._barn or {}) do
			if g.Name == "ContextActionGui" then yta = g end
		end
		--[[ NYCKELN MÅSTE BORT FÖRST. En tidigare montering har redan
		     rawsatt `ModalEnabled` på stubben, och `__newindex` fyrar bara
		     på en nyckel som SAKNAS. Utan den här raden var provet grönt
		     utan att ha mätt någonting — kroken kopplades aldrig in. ]]
		local skugga = { ModalEnabled = rawget(UIS, "ModalEnabled") }
		rawset(UIS, "ModalEnabled", nil)
		setmetatable(UIS, {
			__index = skugga,
			__newindex = function(t, k, v)
				if k == "ModalEnabled" then
					skugga[k] = v
					--[[ DET BEFARADE BETEENDET, uttryckt som kod: sant
					     släcker CAS egen yta. Ingen vet ännu om Roblox
					     gör det — poängen är att vakten ska hålla ÄVEN
					     om den gör det. ]]
					if v and yta then yta.Enabled = false end
				else
					rawset(t, k, v)
				end
			end,
		})

		TouchControls.unmount()
		yta.Enabled = true
		TouchControls.mount(Input, { dismount = function() end })
		check("ModalEnabled får inte lämna CAS-ytan släckt — vakten står efter den",
			yta.Enabled == true, ("Enabled=%s, ModalEnabled=%s")
				:format(tostring(yta.Enabled), tostring(UIS.ModalEnabled)))

		TouchControls.unmount()
		setmetatable(UIS, nil)
		UIS.ModalEnabled = skugga.ModalEnabled
		yta.Enabled = true
	end

	--[[ ══ #264 ROBLOX_HUMAN_PLAYTEST_FIX: RAMEN, OCH ORDNINGEN ══════════

	     Svaret på frågan ovan kom från Studio 2026-09-25, iPad Air-emulering:
	     YTAN var tänd. Det som var släckt var `ContextButtonFrame` MELLAN
	     ytan och knapparna — Robloxs kärnskript döljer den — och när den väl
	     tändes låg `HorseTouch`s blickyta (DisplayOrder 8) över knapparna
	     (DisplayOrder 0) och tog varje tryck. Båda är mätta i motorn,
	     inklusive falsifieringen: med ordningen 0 åt blickytan trycket på
	     GO och gångarten stod kvar.

	     Bänken bygger samma träd som motorn — knapparna i en dold ram i
	     ytan — och mäter att monteringen tänder ramen, håller den tänd
	     under ritten och lägger ytan över `HorseTouch`. ]]
	do
		local yta = nil
		for _, g in ipairs(playerGui._barn or {}) do
			if g.Name == "ContextActionGui" then yta = g end
		end
		check("CAS-ytan finns inför ramprovet", yta ~= nil)
		if yta then
			TouchControls.unmount()
			local ram = Instance.new("Frame")
			ram.Name = "ContextButtonFrame"
			ram.Visible = false
			ram.Parent = yta
			for _, h in ipairs({ Input.DRIV, Input.BROMS, Input.AVSITT }) do
				local b = CAS:GetButton(h)
				if b then b.Parent = ram end
			end
			yta.DisplayOrder = 0
			TouchControls.mount(Input, { dismount = function() end })
			check("EN DOLD RAM MELLAN YTAN OCH KNAPPARNA TÄNDS",
				ram.Visible == true, tostring(ram.Visible))
			--[[ BEVAKNINGEN UNDER RITTEN MÄTS INTE HÄR. Stubben fyrar
			     `GetPropertyChangedSignal` bara för sina bevakade egenskaper
			     (`__BEVAKADE`), och `Visible` är inte en av dem; att lägga
			     till den ändrar varje GUI-objekt i varje spec. Mätt i
			     motorn i stället, 2026-09-25: uppsutten, ramen dold med
			     flit — synlig igen 0,3 s senare. ]]
			local hojd = nil
			for _, g in ipairs(playerGui._barn or {}) do
				if g.Name == "HorseTouch" then hojd = g.DisplayOrder end
			end
			check("CAS-YTAN LIGGER ÖVER BLICKYTAN — trycket når knapparna",
				type(hojd) == "number" and type(yta.DisplayOrder) == "number"
					and yta.DisplayOrder > hojd,
				("CAS %s, HorseTouch %s"):format(tostring(yta.DisplayOrder),
					tostring(hojd)))
			TouchControls.unmount()
			ram.Visible = false
			check("vid avsittning rivs bevakningen — ramen lämnas i fred",
				ram.Visible == false, tostring(ram.Visible))
		end
	end

	TouchControls.unmount()
	CAS:UnbindAction(Input.AVSITT)
	UIS.TouchEnabled = false
end

--[[ ══ 2. TRAPPAN ═══════════════════════════════════════════════════ ]]
print("\n── 2. Rygga ↔ Halt ↔ Skritt ↔ Trav ↔ Galopp ──")
do
	local mc = nyttEkipage()
	check("hon börjar i halt", mc.loco.gait == "halt", mc.loco.gait)
	check("och ryggar inte", mc.ryggar == false)

	local upp = {}
	for _ = 1, 4 do
		driv(mc, 3.0)
		table.insert(upp, mc.loco.gait)
	end
	print("  uppåt:  halt → " .. table.concat(upp, " → "))
	check("fyra DRIV ger skritt, trav, galopp och sedan taket",
		upp[1] == "walk" and upp[2] == "trot" and upp[3] == "canter"
			and upp[4] == "canter",
		table.concat(upp, " → "))

	local ned = {}
	for _ = 1, 4 do
		broms(mc, 3.0)
		table.insert(ned, if mc.ryggar then "rygga" else mc.loco.gait)
	end
	print("  nedåt:  galopp → " .. table.concat(ned, " → "))
	check("fyra BROMS tar henne tillbaka och ett steg till, ned i rygga",
		ned[1] == "trot" and ned[2] == "walk" and ned[3] == "halt"
			and ned[4] == "rygga",
		table.concat(ned, " → "))

	--[[ GOLVET. Ett femte BROMS får inte ta henne någonstans. Pinnen mäts
	     på `ryggar` och på den BEGÄRDA gångarten — inte på `loco.gait`,
	     se noten om etiketten strax nedan. ]]
	broms(mc, 2.0)
	check("rygga är trappans nedersta pinne — det finns inget under",
		mc.ryggar == true and mc.loco.targetGait == "halt"
			and mc.loco.beddGangart == "halt",
		("(ryggar %s, bad om %s)"):format(tostring(mc.ryggar),
			tostring(mc.loco.beddGangart)))

	--[[ OCH HON BACKAR FAKTISKT. Utan farten vore "rygga" bara en flagga. ]]
	check("hon rör sig BAKÅT i rygga", mc.loco.speed < -0.5,
		("%.2f m/s"):format(mc.loco.speed))

	--[[ ══ ETIKETTEN UNDER RYGGNINGEN ═══════════════════════════════════

	     HON RYGGAR I HALT, och `loco.gait` ska säga det.

	     Här stod en `[ÖPPEN FRÅGA]` och en `print`: `loco.gait` sa "walk"
	     medan hon backade, därför att `StateMachine:step` räknade
	     gångarten ur `Gaits.forSpeed(math.abs(input.speed), …)` och
	     beloppet gjorde −1,10 m/s till 1,10 — mitt i skrittbandet.
	     Observationen stämde. Den var bara inte ofarlig.

	     VAD DEN KOSTADE, och det är skälet den är en `check` nu och inte
	     en `print`: `init.client` sänder `StateSync(loco.gait, loco.speed)`
	     tio gånger i sekunden, och `HorseService.onStateSync` har regeln

	         if speed < 0 then if gait ~= "halt" then return end

	     Paret på tråden var alltså `("walk", −1.10)`, och servern
	     FÖRKASTADE varje synk under hela ryggningen. De replikerade
	     attributen `Gait` och `Speed` frös på det som gällde innan hon
	     började backa. Serverns egen kommentar säger att klienten backar
	     med `targetGait == "halt"` — det gör den, men det är inte
	     `targetGait` som ligger på tråden.

	     Rättelsen ligger i `MovementController`, som redan har en kanal
	     för precis det här: `faktiskGangart` finns för att ANROPAREN vet
	     gångarten bättre än tempot gör under ett förlopp. Ryggningen är
	     samma slags fall. `Gaits.ORDER` är orörd och inget index har
	     flyttats. ]]
	check("hon ryggar i HALT — etiketten följer med ned i pinnen",
		mc.loco.gait == "halt",
		("loco.gait = %q vid %.2f m/s"):format(mc.loco.gait, mc.loco.speed))

	--[[ KEDJAN HELA VÄGEN UT. Mätningen ovan är etiketten; den här är
	     vad den betyder på tråden. Regeln är HorseService.onStateSync:
	     negativt tempo accepteras ENDAST i halt, och bara ned till
	     backtempot med marginal. Skulle någon flytta etiketten tillbaka
	     faller den här raden, och den säger varför. ]]
	local pGait, pSpeed = mc.loco.gait, mc.loco.speed
	local serverTarEmot = pSpeed >= 0
		or (pGait == "halt"
			and -pSpeed <= Config.MOVEMENT.ReverseSpeed + Gaits.HYSTERESIS)
	check("paret klienten sänder passerar serverns validering",
		serverTarEmot, ("StateSync(%q, %.2f)"):format(pGait, pSpeed))

	--[[ OCH ANIMATIONEN. `BackUp`-klippet spolas inte av fasen (det har
	     ingen `phase` i `STATE_ANIMATION`), så takten sätts av
	     `Gaits.playbackRate(loco.gait, |speed|)`. Med "walk" blev det
	     1,10 / 1,45 = 0,76 — klippet gick 24 % för långsamt. Halt har
	     `norm = 0` och ger 1,0, alltså klippets egen takt. ]]
	check("BackUp-klippet går i sin egen takt, inte skrittets",
		math.abs(Gaits.playbackRate(mc.loco.gait, math.abs(mc.loco.speed)) - 1) < 1e-6,
		("playbackRate = %.4f"):format(
			Gaits.playbackRate(mc.loco.gait, math.abs(mc.loco.speed))))

	--[[ ETT DRIV UR RYGGA ÄR HALT, inte skritt. Ett steg är ett steg
	     också på vägen upp ur den nedersta pinnen. ]]
	driv(mc, 2.0)
	check("ett DRIV ur rygga ger halt, inte skritt",
		mc.ryggar == false and mc.loco.gait == "halt"
			and math.abs(mc.loco.speed) < 0.2,
		("(gångart %s, %.2f m/s)"):format(mc.loco.gait, mc.loco.speed))
end

print("\n── 2b. Ingen hoppar över en gångart ──")
do
	--[[ Två saker kan ge ett hopp: en spelare som hamrar, och en gaspedal
	     som väljer gångart vid sidan av trappan. Båda mäts. ]]
	local mc = nyttEkipage()
	efterSparren()
	--[[ TIO tryck på samma bildruta — spärren ska svälja nio. ]]
	local fn = CAS._bound[Input.DRIV]
	for _ = 1, 10 do fn(Input.DRIV, Enum.UserInputState.Begin, {}) end
	mc:step(Input.consume(), 1 / 60)
	for _ = 1, 180 do mc:step(avsikt(), 1 / 60) end
	check("tio hamrade DRIV ger skritt, inte galopp",
		mc.loco.gait == "walk", mc.loco.gait)

	--[[ GASPEDALEN ÄR BORTA. Fullt framåtutslag i sex sekunder får inte
	     lyfta henne ur halt — det var den gamla regeln, och den var
	     skälet att HALT behövde ett lås. ]]
	local st = nyttEkipage()
	for _ = 1, 360 do st:step(avsikt({ forward = 1 }), 1 / 60) end
	check("ett hållet framåtutslag startar henne INTE",
		st.loco.gait == "halt" and st.loco.speed < 0.05,
		("(%s, %.3f m/s)"):format(st.loco.gait, st.loco.speed))

	--[[ …och ett hållet bakåtutslag ryggar henne inte heller. ]]
	for _ = 1, 360 do st:step(avsikt({ forward = -1 }), 1 / 60) end
	check("och ett hållet bakåtutslag ryggar henne inte",
		st.ryggar == false and st.loco.speed > -0.05,
		("(ryggar %s, %.3f m/s)"):format(tostring(st.ryggar), st.loco.speed))
end

print("\n── 2c. Taket gäller lika hårt som förut ──")
do
	local mc = nyttEkipage()
	mc:setCeiling("walk")
	driv(mc, 3.0); driv(mc, 3.0); driv(mc, 3.0)
	check("uthållighetstaket stoppar trappan vid skritt",
		mc.loco.gait == "walk", mc.loco.gait)
	--[[ Taket får inte stänga vägen NED. Rygga ligger under golvet, inte
	     under taket, och en trött häst ska kunna backa ur en ruta. ]]
	broms(mc, 2.0); broms(mc, 2.0)
	check("men vägen ned till rygga är öppen även under taket",
		mc.ryggar == true, ("(ryggar %s)"):format(tostring(mc.ryggar)))
end

--[[ ══ 3. INGEN HÅLLEN KNAPP ═════════════════════════════════════════ ]]
print("\n── 3. Hon går kvar utan att någon håller något ──")
do
	local mc = nyttEkipage()
	driv(mc, 2.0)
	check("ett DRIV satte henne i skritt", mc.loco.gait == "walk", mc.loco.gait)

	--[[ TJUGO SEKUNDER med tom avsikt. `hjalp` ovan kör redan tomma
	     bildrutor, men tjugo sekunder är en annan storleksordning: det
	     fångar allt som sakta rinner tillbaka mot noll. ]]
	local lagsta = math.huge
	for _ = 1, 20 * 60 do
		mc:step(avsikt(), 1 / 60)
		if mc.loco.speed < lagsta then lagsta = mc.loco.speed end
	end
	check("tjugo sekunder senare skrittar hon fortfarande",
		mc.loco.gait == "walk", mc.loco.gait)
	check("och tempot föll aldrig mot noll under tiden",
		lagsta > 0.8, ("lägsta %.2f m/s"):format(lagsta))
	check("humanoidens WalkSpeed är positiv hela tiden",
		mc.rig.humanoid.WalkSpeed > 0,
		("%.2f"):format(mc.rig.humanoid.WalkSpeed))

	--[[ OCH HON STANNAR PÅ BEGÄRAN. En häst som inte går att stanna är
	     lika trasig som en som inte går att starta — och utan den här
	     raden vore mätningen ovan grön också om BROMS slutat verka. ]]
	broms(mc, 4.0)
	check("ett BROMS tar henne till halt", mc.loco.gait == "halt", mc.loco.gait)
	check("och då står hon still", math.abs(mc.loco.speed) < 0.1,
		("%.3f m/s"):format(mc.loco.speed))
end

print("\n── 2d. Ryggningen väntar på att hon faktiskt står ──")
do
	--[[ ══ VARFÖR `targetGait == "halt"` STÅR KVAR I VILLKORET ═════════

	     `reverse` kunde ha varit `self.ryggar` ensamt. Det vore fel, och
	     hålet går att nå: mellan en begäran och hästens svar ligger
	     `svarstid`, och under det fönstret kan pinnen redan vara RYGGA
	     medan `targetGait` fortfarande är en gångart hon GÅR i.

	     Vägen dit är BROMS plus en halvhalt. Paraden stegar också nedåt —
	     det är en ridmässigt riktig nedåtgående hjälp, G02-B punkt 1 — och
	     den går INTE genom impulsspärren, för den är en egen hjälp. Två
	     steg ned på under 0,2 s är alltså fullt möjligt för en spelare.

	     Utan villkoret hade hon backat i SKRITTFART. Med det väntar
	     ryggningen tills hon står, precis som en häst gör.

	     Mätningen fanns inte i första utkastet, och falsifieringen sa det:
	     mutationen som tog bort villkoret lämnade hela sviten grön. ]]
	local mc = nyttEkipage()
	driv(mc, 3.0)
	check("hon skrittar inför provet", mc.loco.gait == "walk", mc.loco.gait)

	--[[ BROMS. `targetGait` följer först efter svarstiden. ]]
	efterSparren()
	local fn = CAS._bound[Input.BROMS]
	fn(Input.BROMS, Enum.UserInputState.Begin, {})
	mc:step(Input.consume(), 1 / 60)
	check("hon har BETT om halt men går fortfarande",
		mc.loco.beddGangart == "halt" and mc.loco.targetGait == "walk",
		("(bad om %s, går i %s)"):format(tostring(mc.loco.beddGangart),
			tostring(mc.loco.targetGait)))

	--[[ …och en halvhalt i samma fönster tar henne ned till pinnen. ]]
	mc:step(avsikt({ parad = 1 }), 1 / 60)
	check("halvhalten inom svarstiden stegar ned i rygga",
		mc.ryggar == true and mc.loco.targetGait == "walk",
		("(ryggar %s, går i %s)"):format(tostring(mc.ryggar),
			tostring(mc.loco.targetGait)))

	--[[ DET HÄR ÄR MÄTNINGEN, och den mäter TEMPOT — inte tecknet.

	     Ett första utkast krävde bara att farten inte blev negativ. Den
	     mätningen var grön också utan villkoret, och falsifieringen sa
	     det: fönstret är elva bildrutor långt, och på den tiden hinner
	     inte ens en rak inbromsning mot −1,10 m/s passera noll.

	     Skillnaden syns i TEMPOT. Uppmätt lägsta fart under fönstret:

	         med villkoret    1,4478 m/s   — hon bär skritten
	         utan villkoret   0,8250 m/s   — hon bromsar mot ryggfart

	     Tröskeln 1,2 ligger mellan de två med marginal åt båda hållen. ]]
	local lagsta = math.huge
	local rutor = 0
	while mc.loco.targetGait ~= "halt" and rutor < 600 do
		mc:step(avsikt(), 1 / 60)
		rutor += 1
		if mc.loco.speed < lagsta then lagsta = mc.loco.speed end
	end
	check("hon bär skritten ända fram till halten, utan att dra mot ryggfart",
		lagsta > 1.2, ("lägsta %.4f m/s på %d bildrutor"):format(lagsta, rutor))

	--[[ …men när hon väl står gör hon det. Utan den raden vore mätningen
	     ovan grön också om ryggningen slutat fungera helt. ]]
	for _ = 1, 300 do mc:step(avsikt(), 1 / 60) end
	check("och när hon står ryggar hon",
		mc.ryggar == true and mc.loco.targetGait == "halt"
			and mc.loco.speed < -0.5,
		("(%s, %.2f m/s)"):format(tostring(mc.loco.targetGait), mc.loco.speed))
end

print("\n── 3b. Spärren gäller hela kedjan, inte bara Input ──")
do
	local mc = nyttEkipage()
	driv(mc, 0.1)
	--[[ Ett andra DRIV INOM spärren — klockan flyttas INTE. ]]
	local fn = CAS._bound[Input.DRIV]
	fn(Input.DRIV, Enum.UserInputState.Begin, {})
	local i = Input.consume()
	mc:step(i, 1 / 60)
	for _ = 1, 180 do mc:step(avsikt(), 1 / 60) end
	check("ett andra DRIV inom spärren når aldrig trappan",
		i.gaitUp == false and mc.loco.gait == "walk",
		("(flank %s, gångart %s)"):format(tostring(i.gaitUp), mc.loco.gait))
end

print("\n── 3c. Spärrens tal är kanon, inte klientens eget ──")
do
	--[[ #233 Fas 4b. Spärren låg som literalen `0.60` i `Input`, och det
	     var rätt så länge den bara var UX: den hindrade hamrande på den
	     yta spelaren själv rörde.

	     Nu äger servern gångarten och mäter samma takt i
	     `HorseService.onRidingIntent`. Ett eget `0.60` på serversidan hade
	     varit en andra UX-takt som glider ifrån den här vid första
	     trimningen — och glidningen hade synts som att hjälper ibland
	     försvinner, aldrig som en siffra som står fel.

	     Raden mäter att det finns EN källa. Skrivs literalen tillbaka i
	     `Input` faller den.

	     Serverns egen grind, marginalen och stegmaskinen mäts i
	     `ridinput.spec`; här mäts bara att klienten läser kanon. ]]
	check("klientens impulsspärr ÄR Config.RIDINPUT.ImpulsSparr",
		Input.IMPULS_SPARR == Config.RIDINPUT.ImpulsSparr,
		("Input %.3f / kanon %.3f"):format(
			Input.IMPULS_SPARR, Config.RIDINPUT.ImpulsSparr))
end

if fel > 0 then
	print(("\n%d mätningar föll."):format(fel))
else
	print("\nAlla mätningar gick igenom.")
end
