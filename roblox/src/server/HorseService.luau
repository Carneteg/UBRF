--!strict
--[[
	HorseService — serverns auktoritet.

	Servern äger: vem som rider vad, om uppsittning får ske, uthålligheten,
	och hästarnas beständiga statistik. Den äger INTE bildruta-för-bildruta-
	positionen — den ligger hos ryttarens klient via nätverksägarskap, för
	annars går det inte att rida responsivt med Roblox latens.

	Det klienten skickar in valideras: tempo mot hästens tak, position mot
	rimlig förflyttning. Fusk ger en tillrättaläggning, inte en kick — det
	här är ett familjespel, inte en tävlingsserver.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local Core = require(game:GetService("ReplicatedStorage").HorseCore)
local Types = require(game:GetService("ReplicatedStorage").HorseCore.Types)
local Config, Gaits, RigAdapter, Net = Core.Config, Core.Gaits, Core.RigAdapter, Core.Networking
local Svar, RidKanon = Core.Svar, Core.RidKanon
--[[ Stallet äger den kanoniska hästdatan; HorseService läser den för att
     binda rätt individ till rätt ridkänsla (blocker 1). ]]
local Stallet = require(game:GetService("ReplicatedStorage").Stallet)

local HorseService = {}

export type Session = {
	rig: Types.Rig,
	stats: { [string]: any },
	rider: Player?,
	--[[ ENERGIN ÄR DEN ENDA TRÖTTHETSSANNINGEN (senior re-review #87).
	     0–1, samma storhet och samma kanon som klientens `loco.energi`
	     och webbens `s.energi`. `Stamina`-attributet och StaminaSync är
	     dess presentation i 0–MaxStamina, inget eget tillstånd. ]]
	energi: number,
	lastExertion: number,
	lastSync: number,
	lastPosition: Vector3,
}

local sessions: { [Model]: Session } = {}
local byRider: { [Player]: Model } = {}

local TAG = "Horse"

--[[ ── Registrering ────────────────────────────────────────────────── ]]

local function register(model: Model)
	if sessions[model] then return end

	local rig, err = RigAdapter.build(model)
	if not rig then
		warn(("[Horse] %s kunde inte registreras: %s"):format(model:GetFullName(), err or "okänt fel"))
		return
	end

	-- Configuration-blocken skapas om de saknas, så att allt går att skruva
	-- i Studio i stället för att ligga dolt i kod.
	local function ensure(name: string): Configuration
		local existing = model:FindFirstChild(name)
		if existing and existing:IsA("Configuration") then
			return existing
		end
		local c = Instance.new("Configuration")
		c.Name = name
		c.Parent = model
		return c
	end
	rig.stats = rig.stats or ensure("HorseStats")
	rig.gaitConfig = rig.gaitConfig or ensure("GaitConfig")
	rig.animConfig = rig.animConfig or ensure("AnimationConfig")

	--[[ ── DEN TILLDELADE HÄSTENS EGNA VÄRDEN (blocker 1) ─────────────
	     Modellens `HorseId` är den kanoniska identiteten, och hästens
	     spelvärden ur UBRFSpelData skrivs på HorseStats FÖRE
	     writeDefaults. Ordningen är hela poängen:

	       ett attribut som redan finns   någon satte det i Studio → vinner
	       kanon                          skrivs här om det saknas
	       Config.STATS default           writeDefaults fyller resten

	     Först skrev jag kanonen EFTER writeDefaults och lät `Config.attr`
	     avgöra. Det gick inte: writeDefaults hade just stämplat sina
	     defaultvärden på samma Configuration, så "någon satte det i
	     Studio" gick inte att skilja från "vi skrev standardvärdet för en
	     millisekund sedan" — och varje häst red som `skolhast` ändå.
	     Uppmätt, inte resonerat: provet i forberedelse.spec sa
	     `crokino → skolhast`.

	     Utan det här ledet nådde profilerna aldrig ridcontrollern. ]]
	do
		local id = model:GetAttribute("HorseId")
		local kanon = if type(id) == "string" then Stallet.statsFor(id) else nil
		if kanon then
			local c = rig.stats :: Configuration
			for nyckel, varde in kanon do
				if varde ~= nil and c:GetAttribute(nyckel) == nil then
					c:SetAttribute(nyckel, varde)
				end
			end
		end
	end

	Config.writeDefaults(rig.stats :: Configuration, Config.STATS)
	Config.writeDefaults(rig.gaitConfig :: Configuration, Config.MOVEMENT)

	local stats = Config.resolveStats(rig.stats)

	-- Humanoiden ställs in en gång. AutoRotate av: vi äger vridningen, annars
	-- snurrar hästen som ett fordon mot rörelseriktningen.
	local hum = rig.humanoid
	if hum then
		hum.AutoRotate = false
		hum.UseJumpPower = true
		hum.JumpPower = Config.MOVEMENT.JumpPower * (0.7 + 0.6 * stats.JumpStrength)
		hum.WalkSpeed = 0
		hum.BreakJointsOnDeath = false
		hum.RequiresNeck = false
		hum.HipHeight = Config.attr(rig.gaitConfig, "HipHeight", hum.HipHeight)
	end

	sessions[model] = {
		rig = rig,
		stats = stats,
		rider = nil,
		--[[ Utgångsläget ur kanonen (senior re-review #87, blocker 2).
		     Stod som 1 — en utvilad häst som webben aldrig satte upp på;
		     där börjar energin i dagsformen. ]]
		energi = Svar.startEnergi(),
		lastExertion = 0,
		lastSync = os.clock(),
		lastPosition = rig.root.Position,
	}

	model:SetAttribute("Registered", true)
	model:SetAttribute("Gait", "halt")
	model:SetAttribute("Stamina", stats.MaxStamina)
end

--[[ Provkrokar. `register` är lokal med flit — produktionen registrerar
     via CollectionService — men blocker 1 kräver ett prov som går genom
     den RIKTIGA registreringen och läser de stats hästen faktiskt fick.
     Krokarna kallar samma kod, de duplicerar den inte. ]]
function HorseService._registerForProv(model: Model)
	register(model)
end
function HorseService._statsFor(model: Model): { [string]: any }?
	local session = sessions[model]
	return if session then session.stats else nil
end

local function unregister(model: Model)
	local session = sessions[model]
	if not session then return end
	if session.rider then
		byRider[session.rider] = nil
	end
	sessions[model] = nil
end

--[[ ── Uppsittning ─────────────────────────────────────────────────── ]]

local function seatCFrame(session: Session): CFrame
	return RigAdapter.saddleCFrame(session.rig)
end

--[[ ══ LIVSCYKELSTÄDNING ═════════════════════════════════════════════════

	Blockerare 3 i ChatGPT:s whole-place review #162: servern höll
	`session.rider` och `byRider[player]` men hade INGEN lyssnare för att
	avataren dör, tas bort eller kastas ur sitsen. Roblox kan lossa ryttaren
	fysiskt medan våra tabeller fortfarande säger att hon rider. Då nekas
	nästa uppsittning med "Du rider redan", hästen ligger reserverad, och
	`Pass.vidAvsittning` körs aldrig.

	Kommentaren vid `tryMount` hävdade att en `Seat` sköter frånkopplingen
	"åt oss" vid död, respawn och utloggning. Det är sant om den FYSISKA
	fastsättningen och falskt om vårt tillstånd — och det var precis den
	skillnaden som gjorde att ingen såg luckan.

	Kopplingarna görs vid uppsittning och rivs vid avsittning, så det finns
	inga lyssnare för spelare som inte rider. `PlayerAdded` rörs inte:
	SparService äger den ensam sedan blockerare 1 i #161. ]]
local stadning: { [Player]: { RBXScriptConnection } } = {}

local function slappStadning(player: Player)
	local kopplingar = stadning[player]
	if not kopplingar then return end
	stadning[player] = nil
	for _, k in ipairs(kopplingar) do
		pcall(function() k:Disconnect() end)
	end
end

--[[ Ryttarkroken deklareras HÄR och inte längre ner, och det är en
	rättelse: `setRider` läser den, och en `local` som deklareras EFTER
	funktionen fångas inte av den — namnet lästes då som en global, alltså
	alltid nil. Följden var att kroken aldrig kördes: `Pass.vidUppsittning`
	och `Pass.vidAvsittning` anropades inte, passet stannade i läget
	"before_ride" hur mycket spelaren än red, och eftervården — som kräver
	att ritten är avslutad — gick aldrig att göra. Dagen kunde alltså inte
	spelas färdigt.

	Att det inte syntes har samma orsak som `seat.C0`: ingen körning hade
	någonsin monterat en ryttare mot en riktig rigg. Kontraktet mäts nu i
	`integration.spec.luau` (punkt 9 och 11).

	Kroken får INTE avgöra något — se noten vid `setRiderHook`. ]]
local riderHook: ((Player, boolean) -> ())? = nil

local function setRider(session: Session, player: Player?)
	local previous = session.rider
	session.rider = player

	if previous then
		byRider[previous] = nil
	end
	if player then
		byRider[player] = session.rig.model
	end

	session.rig.model:SetAttribute("RiderUserId", if player then player.UserId else 0)

	--[[ Nätverksägarskapet går till ryttaren så att rörelsen simuleras där
	     inputen finns. Utan det ligger en halv sekunds fördröjning i varje
	     styrutslag och hästen känns som en båt. ]]
	local ok = pcall(function()
		session.rig.root:SetNetworkOwner(player)
	end)
	if not ok then
		warn("[Horse] Kunde inte sätta nätverksägare (ankrad eller ej fysisk del?)")
	end

	Net.get("MountChanged"):FireAllClients(session.rig.model, player)

	--[[ Aviseringen sist, när allt annat är gjort: kroken ska se ett
		färdigt tillstånd, inte ett halvt. ]]
	local hook = riderHook
	if hook then
		if previous and previous ~= player then
			local ok, fel = pcall(hook, previous, false)
			if not ok then warn("[Horse] ryttarkroken (av) kastade: " .. tostring(fel)) end
		end
		if player then
			local ok, fel = pcall(hook, player, true)
			if not ok then warn("[Horse] ryttarkroken (upp) kastade: " .. tostring(fel)) end
		end
	end
end

--[[ Förberedelsegrinden.

	`HorseService` är fortfarande ENDA uppsittningsauktoritet — den här kroken
	flyttar inte beslutet, den låter `GameplayService` lägga till ett villkor
	framför det. Skälet att den ligger här och inte i fjärranropet: allt som
	monterar en ryttare går genom `tryMount`, och en grind som bara satt på
	`MountRequest` hade gått att gå runt genom vilken annan väg som helst in
	i den här filen.

	Ingen grind registrerad = ingen förändring. Hästsystemet ska gå att köra
	utan G01-loopen, annars kan movement-specarna inte prova det ensamt. ]]
local mountGate: ((Player, Model) -> (boolean, string?))? = nil

function HorseService.setMountGate(gate: ((Player, Model) -> (boolean, string?))?)
	mountGate = gate
end

--[[ RYTTARKROKEN (#161).

	`GameplayService` behöver veta NÄR någon satt sig upp eller av, för att
	driva passets läge — och den behöver veta det för VARJE väg in och ut,
	inte bara för `MountRequest`. En krok på fjärranropet hade missat
	karaktärens död, respawn, utloggning och en modell som tas bort ur
	världen, och just de fallen är de som lämnar ett pass hängande.

	Den ligger därför i `setRider`, som är den enda punkt all uppsittning
	och avsittning faktiskt passerar — exakt samma resonemang som gjorde
	att `mountGate` sitter i `tryMount` och inte på remoten.

	Kroken får INTE avgöra något. Den är en avisering, inte en grind; ett
	fel i den ska inte kunna hindra en avsittning, och därför är anropet
	inkapslat i pcall. En spökryttare som sitter kvar för att en HUD
	kastade vore värre än en HUD som visar fel. ]]
function HorseService.setRiderHook(hook: ((Player, boolean) -> ())?)
	riderHook = hook
end

function HorseService.tryMount(player: Player, model: Model): (boolean, string?, string?)
	if mountGate then
		--[[ TREDJE VÄRDET FÖLJER MED. Nejen är språknycklar sedan #162, och
			välfärdsstoppets nyckel bär fyndets mening som ARGUMENT. Kastade
			den här raden bort argumentet — vilket den gjorde — fick
			spelaren se ett bokstavligt "%s" i stället för vad hästen hade.
			Fångat av `sprak-en.spec`, inte av något jag såg i koden. ]]
		local tillaten, skal, arg = mountGate(player, model)
		if not tillaten then
			return false, skal or "hast.inte_redo", arg
		end
	end

	local session = sessions[model]
	if not session then
		return false, "hast.oregistrerad"
	end
	if session.rider then
		return false, "hast.upptagen"
	end
	if byRider[player] then
		return false, "hast.rider_redan"
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return false, "hast.ingen_karaktar"
	end

	local range = Config.attr(session.rig.gaitConfig, "MountRange", 14)
	if (root.Position - session.rig.root.Position).Magnitude > range then
		return false, "hast.for_langt"
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false, "hast.ingen_levande"
	end

	--[[ Sitsen sköter fastsättningen. En Seat väljs framför en handgjord
	     Weld för att Roblox då hanterar frånkoppling vid död, respawn och
	     utloggning åt oss — de tre fallen som annars lämnar spökryttare. ]]
	local seat = session.rig.seat
	if seat then
		seat:Sit(humanoid)
		--[[ Blockerare 4 i reviewen: `session.rider` sattes som sanning även
			om sitsen aldrig etablerades. Då tror servern att någon rider en
			häst som står tom, och nästa försök nekas med "Du rider redan".
			Sitsen får bekräfta själv. ]]
		if seat.Occupant ~= humanoid then
			return false, "hast.sitsen_tog_inte"
		end
	else
		character:PivotTo(seatCFrame(session))
		local weld = Instance.new("WeldConstraint")
		weld.Name = "HorseMount"
		weld.Part0 = root
		weld.Part1 = session.rig.root
		weld.Parent = root
		humanoid.PlatformStand = true
	end

	setRider(session, player)

	--[[ Städningen kopplas EFTER att ryttaren är satt, så att en signal som
		fyrar direkt hittar ett tillstånd att städa. Alla tre vägarna leder
		till samma idempotenta `dismount`. ]]
	slappStadning(player)
	local kopplingar = {}
	table.insert(kopplingar, player.CharacterRemoving:Connect(function()
		HorseService.dismount(player)
	end))
	table.insert(kopplingar, humanoid.Died:Connect(function()
		HorseService.dismount(player)
	end))
	if seat then
		--[[ Roblox kan lossa ryttaren utan att någon av ovanstående fyrar —
			en explosion, en `Sit`-ändring, en fysikträff. Occupant är den
			enda källan som alltid säger sanningen om sitsen. ]]
		table.insert(kopplingar, seat:GetPropertyChangedSignal("Occupant"):Connect(function()
			if seat.Occupant ~= humanoid then
				HorseService.dismount(player)
			end
		end))
	end
	stadning[player] = kopplingar
	return true, nil
end

--[[ ══ AVSITTNINGENS PLATS ════════════════════════════════════════════

	══ VAD SOM MÄTTES ════════════════════════════════════════════════

	Avsittningen skrev `character:PivotTo(...)` 4,5 studs åt vänster och
	3 studs upp. Uppmätt i Studio efteråt, både mitt på öppen ridbana och
	intill sargen:

	    hästen (399.94 3.36 280.00) · ryttaren (400.00 7.59 280.00)
	    sidsteg 0.06 studs · höjd över hästroten +4.24 · Floor Plastic

	Hon stod alltså PÅ HÄSTRYGGEN — `FloorMaterial` var hästen själv.
	Flytten tog inte, och det är en tidsfråga och ingen räknefråga:
	`Humanoid.Sit = false` reser henne inte i samma bildruta. Så länge
	`seat.Occupant` fortfarande pekar på henne äger sitsen hennes läge, och
	Roblox skriver tillbaka det efter vår `PivotTo`. Att riva `SeatWeld`
	själv hjälper inte — sitsen gör en ny så länge occupanten sitter kvar.

	══ VAD SOM GÖRS I STÄLLET ════════════════════════════════════════

	Platsen räknas ur HÄSTENS EGEN GEOMETRI — aldrig ur en världskoordinat
	— och prövas mot marken och mot det som står i vägen innan hon
	placeras. Sedan placeras hon TVÅ gånger: en gång direkt, och en gång
	till när sitsen faktiskt har släppt. Den andra är den som håller.

	Vänster först, för det är så man sitter av. Är vänster sidan upptagen
	tas höger, och därefter går listan utåt från vänstersidan — snett bak,
	snett fram, rakt bak — vilket ÄR regeln "närmaste säkra läge". ]]

--[[ Fri luft mellan ryttarens kropp och hästens, i studs. ]]
local AVSITT_MARGINAL = 0.6
--[[ Marksökningen börjar så här högt över kandidatpunkten och går så här
	långt ned. Taket måste vara högre än ett trappsteg och lägre än en
	läktarrad, annars hittas fel golv. ]]
local AVSITT_TAK, AVSITT_DJUP = 6, 24
--[[ Marken vid avsittningen får skilja så här mycket från marken under
	hästen. Utan gränsen kunde hon sättas av ned i ett dike eller upp på
	en sarg som råkade ligga i strålens väg. ]]
local AVSITT_FALL = 5
--[[ Lådan som prövas mot hinder är ryttarens rotdel plus lite luft: en
	fot får inte nöta mot en boxfront, och huvudet inte mot en kappregel. ]]
local AVSITT_LADA = Vector3.new(0.4, 1.6, 0.4)
--[[ Så många bildrutor väntar den andra placeringen på att sitsen ska
	släppa. Ett tak och inte en klocka: en spec har ingen riktig tid. ]]
local AVSITT_VANTA = 30

--[[ Kandidatriktningar i HÄSTENS EGET RUM: x åt höger, z bakåt. Inga
	världskoordinater — vänder hästen sig vänder platserna med henne. ]]
local AVSITT_RIKTNINGAR: { { number } } = {
	{ -1, 0 },              -- vänster: så man sitter av
	{ 1, 0 },               -- höger: när vänster är blockerad
	{ -1, 1 }, { 1, 1 },    -- snett bakom
	{ -1, -1 }, { 1, -1 },  -- snett framför
	{ 0, 1 },               -- rakt bakom
}

local function markhojd(p: Vector3, utanfor: { Instance }): number?
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = utanfor
	--[[ Bara det som BÄR duger som mark. Ridbanans sand är ett dekorlager
		utan kollision — se `Markkontakt` — och att sätta av på den vore
		att sätta av i luften. ]]
	rp.RespectCanCollide = true
	local traff = workspace:Raycast(p + Vector3.new(0, AVSITT_TAK, 0),
		Vector3.new(0, -AVSITT_DJUP, 0), rp)
	return if traff then traff.Position.Y else nil
end

local function ledigt(cf: CFrame, storlek: Vector3, utanfor: { Instance }): boolean
	local op = OverlapParams.new()
	op.FilterType = Enum.RaycastFilterType.Exclude
	op.FilterDescendantsInstances = utanfor
	for _, d in ipairs(workspace:GetPartBoundsInBox(cf, storlek, op)) do
		if d.CanCollide then return false end
	end
	return true
end

--[[ Var ryttaren ska hamna. Publik för att provet ska kunna läsa SAMMA
	räkning som avsittningen använder — två räkningar kan glida isär.

	Svarar också VILKEN regel som gav platsen, så ett prov kan skilja
	"vänster var fri" från "vänster var blockerad" utan att gissa ur
	koordinater. ]]
function HorseService._avsittningsplats(modell: Model, karaktar: Model): (CFrame?, string?)
	local rot = modell.PrimaryPart or modell:FindFirstChild("HumanoidRootPart")
	local krot = karaktar:FindFirstChild("HumanoidRootPart")
	local hum = karaktar:FindFirstChildOfClass("Humanoid")
	if not (rot and rot:IsA("BasePart") and krot and krot:IsA("BasePart") and hum) then
		return nil, "avsitt.ingen_kropp"
	end

	local ut = math.max(krot.Size.X, krot.Size.Z) / 2 + AVSITT_MARGINAL
	--[[ HÄSTEN ÄR ETT HINDER, inte ett golv. Hon undantas därför ur
		marksökningen — annars blir hennes egen rygg "mark" — men INTE ur
		hinderprövningen, som är hela poängen med att inte hamna i henne. ]]
	local utanKar: { Instance } = { karaktar }
	local utanBada: { Instance } = { karaktar, modell }
	local hastMark = markhojd(rot.Position, utanBada)

	--[[ Två varv: första kräver fri plats, andra nöjer sig med mark.
		Andra varvet finns för att hon ALDRIG ska bli kvar på ryggen —
		står hon trångt får Roblox knuffa ut henne, och det är bättre än
		att hon blir stående ovanpå hästen. ]]
	for varv = 1, 2 do
		for _, r in ipairs(AVSITT_RIKTNINGAR) do
			local lokal = CFrame.new(
				r[1] * (rot.Size.X / 2 + ut), 0, r[2] * (rot.Size.Z / 2 + ut))
			local punkt = (rot.CFrame * lokal).Position
			local mark = markhojd(punkt, utanBada)
			local rimlig = mark ~= nil
				and (hastMark == nil or math.abs(mark - hastMark) <= AVSITT_FALL)
			if rimlig then
				local y = (mark :: number) + krot.Size.Y / 2 + hum.HipHeight
				local cf = CFrame.lookAt(Vector3.new(punkt.X, y, punkt.Z),
					Vector3.new(rot.Position.X, y, rot.Position.Z))
				if varv == 2 or ledigt(cf, krot.Size + AVSITT_LADA, utanKar) then
					local skal = if varv == 2 then "avsitt.trangt"
						elseif r[1] < 0 and r[2] == 0 then "avsitt.vanster"
						elseif r[1] > 0 and r[2] == 0 then "avsitt.hoger"
						else "avsitt.narmaste"
					return cf, skal
				end
			end
		end
	end
	return nil, "avsitt.ingen_plats"
end

local function stallAv(modell: Model, karaktar: Model)
	local krot = karaktar:FindFirstChild("HumanoidRootPart")
	if not (krot and krot:IsA("BasePart")) then return end
	local cf = HorseService._avsittningsplats(modell, karaktar)
	if not cf then
		warn(("[Horse] Ingen fri avsittningsplats vid %s"):format(modell.Name))
		return
	end
	local spelare = Players:GetPlayerFromCharacter(karaktar)
	--[[ Klientägarskapet skriver annars tillbaka ryttaren till sitsens läge
		bildrutan efter serverns PivotTo. Håll kroppen på servern kort över
		placeringen och lämna sedan tillbaka den till spelaren. ]]
	pcall(function() krot:SetNetworkOwner(nil) end)
	karaktar:PivotTo(cf)
	--[[ FARTEN NOLLAS. Ryttaren har hästens hastighet i kroppen när hon
		lossnar, och en flytt utan nollning slänger iväg henne. ]]
	krot.AssemblyLinearVelocity = Vector3.zero
	krot.AssemblyAngularVelocity = Vector3.zero
	if spelare then
		task.spawn(function()
			for _ = 1, 8 do RunService.Heartbeat:Wait() end
			if krot.Parent and spelare.Parent and spelare.Character == karaktar then
				pcall(function() krot:SetNetworkOwner(spelare) end)
			end
		end)
	end
end

function HorseService.dismount(player: Player): boolean
	local model = byRider[player]
	if not model then return false end
	local session = sessions[model]
	if not session then return false end

	--[[ Kopplingarna rivs FÖRST. Annars fyrar Occupant-lyssnaren när vi
		själva reser ryttaren och anropar `dismount` igen mitt i. ]]
	slappStadning(player)

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	--[[ Blockerare 4: avsittningen gjorde `seat:Sit(nil)`. `Seat:Sit` tar en
		humanoid som ska SÄTTA SIG; att skicka nil är inte en dokumenterad
		väg att resa någon. Den verifierade vägen är `Humanoid.Sit = false`,
		vilket lossar sitsens egen `SeatWeld`. Faller det bort tas welden
		bort direkt, så en trasig sits inte låser ryttaren fast. ]]
	if humanoid and session.rig.seat and session.rig.seat.Occupant == humanoid then
		humanoid.Sit = false
		if session.rig.seat.Occupant == humanoid then
			local weld = session.rig.seat:FindFirstChild("SeatWeld")
			if weld then weld:Destroy() end
		end
	end
	if humanoid then
		humanoid.PlatformStand = false
	end

	--[[ TILLSTÅNDET STÄDAS FÖRE KROPPEN PLACERAS.

		`setRider(session, nil)` nollar `byRider`, `RiderUserId` och
		nätverksägaren. Den låg förut SIST, efter placeringen, och det gjorde
		den fördröjda placeringen nedan omöjlig att lita på: `task.spawn`
		börjar köra direkt, alltså mitt i den här funktionen, och dess vakt
		"har hon hunnit sätta sig igen?" läste då ett `byRider` som
		fortfarande pekade på hästen hon just klev av. Vakten sa ja varje
		gång och placeringen hoppades över.

		Ordningen är dessutom den riktigare: vem som rider vad är ett
		LOGISKT tillstånd, var kroppen står är ett fysiskt. Det logiska ska
		vara sant först. ]]
	setRider(session, nil)

	if character then
		local root = character:FindFirstChild("HumanoidRootPart")
		if root then
			local weld = root:FindFirstChild("HorseMount")
			if weld then weld:Destroy() end
		end
		local modell = session.rig.model
		local seat = session.rig.seat
		--[[ Direkt, så att den som mäter i samma bildruta ser rätt läge. ]]
		stallAv(modell, character)
		--[[ OCH EN GÅNG TILL NÄR SITSEN FAKTISKT HAR SLÄPPT. Den andra
			gången är den som håller: så länge `seat.Occupant` pekar på
			ryttaren äger sitsen hennes läge och skriver tillbaka det efter
			vår flytt. Se noten vid `AVSITT_MARGINAL`. ]]
		task.spawn(function()
			for _ = 1, AVSITT_VANTA do
				local kvar = (humanoid ~= nil and humanoid.Sit)
					or (seat ~= nil and humanoid ~= nil and seat.Occupant == humanoid)
				if not kvar then break end
				task.wait()
			end
			--[[ Hann karaktären eller hästen försvinna under väntan är det
				inget kvar att placera — avsittningen kan ha kommit ur
				`CharacterRemoving`. ]]
			if not (character.Parent and modell.Parent) then return end
			--[[ OCH HANN HON SÄTTA SIG IGEN ÄR HON INTE VÅR ATT FLYTTA.
				En halv sekund räcker gott för att kliva upp på nästa häst,
				och en sen placering hade då ryckt ner henne på marken
				mitt i uppsittningen. Två frågor, båda om NUET: sitter hon
				på något, och är hon registrerad som ryttare någonstans. ]]
			if humanoid and humanoid.Sit then return end
			if byRider[player] then return end
			stallAv(modell, character)
		end)
	end
	return true
end

--[[ ── Uthållighet ─────────────────────────────────────────────────── ]]

local function stepStamina(session: Session, dt: number)
	local stats = session.stats
	local gaitR = session.rig.model:GetAttribute("Gait") or "halt"

	--[[ ── EN TRÖTTHETSSANNING (senior re-review #87, blocker 3) ───────
	     Här fanns förut en EGEN uthållighetsmodell: `Gaits.stamina` per
	     gångart, egen återhämtningsfördröjning och en egen skala 0–100.
	     Samtidigt räknade klienten G02-B:s `energi` med kanonens tal och
	     lät den styra framåtbjudning och svarstid. Två trötthetsmodeller
	     på samma häst: den ena kunde göra henne segare, den andra sänka
	     gångartstaket — och de kunde säga olika saker samtidigt.

	     Nu är ENERGIN den enda sanningen, med servern som auktoritet och
	     klienten som prediktion. Dräneringen är kanonens `energiTakt`,
	     alltså exakt samma tal som webben och klienten räknar med.

	     `Gaits.stamina` läses inte längre. Taket är kvar som eget
	     PRODUKTBEGREPP — en trött häst rullar ned en gångart av sig
	     själv — men det drivs nu av samma energi och inte av en andra
	     modell. Det är skillnaden mellan två begrepp och två sanningar. ]]
	local webbGangart = "halt"
	for w, r in RidKanon.MOTSVARIGHET do
		if r == gaitR then webbGangart = w end
	end
	--[[ Uthålligheten (Endurance) skalar takten: en seg häst tär
	     långsammare och hämtar sig fortare. Det är samma roll statet hade
	     i den gamla modellen, nu på kanonens kurva. ]]
	local takt = Svar.energiTakt(webbGangart, 0, stats)
	local skala = if takt < 0 then 1 / (0.6 + 0.9 * stats.Endurance)
		else (0.6 + 0.9 * stats.Endurance)
	session.energi = math.clamp(session.energi + takt * skala * dt, 0, 1)
	if takt < 0 then session.lastExertion = os.clock() end

	--[[ Uthålligheten tvingar aldrig fram ett stopp. Den sänker taket, och
	     hästen rullar ned en gångart av sig själv. Det är läsbart för
	     spelaren och känns som en trött häst, inte som en tom bensintank. ]]
	local ceiling = Gaits.SPELBAR_TOPP
	if session.energi < Config.STAMINA.LowThreshold then
		local t = session.energi / Config.STAMINA.LowThreshold
		local floorIndex = Gaits.index(Config.STAMINA.FloorGait)
		local topIndex = Gaits.index(Gaits.SPELBAR_TOPP)
		ceiling = Gaits.byIndex(math.floor(floorIndex + (topIndex - floorIndex) * t + 0.5))
	end

	local visad = session.energi * stats.MaxStamina
	session.rig.model:SetAttribute("Stamina", math.floor(visad))
	session.rig.model:SetAttribute("GaitCeiling", ceiling)

	if session.rider then
		--[[ Fjärde argumentet är energin i sin KANONISKA skala 0–1.
		     Klienten sätter sin prediktion till den; de tre första är
		     presentationen, som Debug redan visar. ]]
		Net.get("StaminaSync"):FireClient(session.rider, visad, stats.MaxStamina,
			ceiling, session.energi)
	end
end

--[[ ── Validering av det klienten påstår ────────────────────────────── ]]

local function onStateSync(player: Player, gait: string, speed: number)
	local model = byRider[player]
	if not model then return end
	local session = sessions[model]
	if not session then return end
	if typeof(gait) ~= "string" or typeof(speed) ~= "number" then return end
	if not Gaits.BY_NAME[gait] then return end
	if speed ~= speed or speed < -3 or speed > 15 then return end   -- NaN och orimligt

	local ceiling = session.rig.model:GetAttribute("GaitCeiling") or Gaits.SPELBAR_TOPP
	if Gaits.index(gait) > Gaits.index(ceiling) then
		gait = ceiling
	end

	session.rig.model:SetAttribute("Gait", gait)
	session.rig.model:SetAttribute("Speed", speed)
	session.lastSync = os.clock()
end

--[[ ── Livscykel ───────────────────────────────────────────────────── ]]

function HorseService.start()
	Net.init()

	for _, model in CollectionService:GetTagged(TAG) do
		if model:IsA("Model") then register(model) end
	end
	CollectionService:GetInstanceAddedSignal(TAG):Connect(function(inst)
		if inst:IsA("Model") then register(inst) end
	end)
	CollectionService:GetInstanceRemovedSignal(TAG):Connect(function(inst)
		if inst:IsA("Model") then unregister(inst :: Model) end
	end)

	Net.get("MountRequest").OnServerInvoke = function(player, model)
		if typeof(model) ~= "Instance" or not model:IsA("Model") then
			return false, "hast.ogiltig"
		end
		return HorseService.tryMount(player, model)
	end
	Net.get("DismountRequest").OnServerInvoke = function(player)
		return HorseService.dismount(player)
	end
	Net.get("StateSync").OnServerEvent:Connect(onStateSync)

	Players.PlayerRemoving:Connect(function(player)
		HorseService.dismount(player)
		slappStadning(player)
	end)

	--[[ En loop för alla hästar, inte en per häst. Uthålligheten behöver
	     inte 60 Hz — fyra gånger i sekunden räcker och kostar nästan inget
	     även med hundra hästar i världen. ]]
	local accumulator = 0
	RunService.Heartbeat:Connect(function(dt)
		accumulator += dt
		if accumulator < 0.25 then return end
		local step = accumulator
		accumulator = 0
		for _, session in sessions do
			stepStamina(session, step)
		end
	end)
end

function HorseService.sessionFor(model: Model): Session?
	return sessions[model]
end

function HorseService.horseOf(player: Player): Model?
	return byRider[player]
end

return HorseService
