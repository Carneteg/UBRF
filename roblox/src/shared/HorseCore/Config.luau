--!strict
--[[
	Konfigurationen — hästens siffror, raserna och animations-id:na.

	Ingen siffra för en enskild häst finns hårdkodad i logiken. Allt läses
	ur Configuration-instanser på modellen, med värdena här som fallback.
	Det är det som gör att en ny ras eller en ny modell fungerar direkt, och
	att en enskild häst går att trimma i Studio utan att kod ändras.

	Tre konfigurationsblock, som i den föreslagna hierarkin:
	  HorseStats      — lynne och förmåga
	  GaitConfig      — avvikelser från standardgångarterna
	  AnimationConfig — animations-id per tillstånd
]]

local Config = {}

--[[ ── HorseStats ────────────────────────────────────────────────────
     Normaliserade 0..1 där inget annat anges. Fälten är samma som den
     befintliga hästdatan använder, så en häst går att flytta över utan
     att värdena tolkas om. ]]
Config.STATS = {
	HorseName = "Namnlös",
	Breed = "Warmblood",
	Level = 1,

	Speed = 0.50,         -- skalar gångarternas maxtempo
	Acceleration = 0.50,  -- skalar accel/retard
	Agility = 0.50,       -- skalar svarvheten
	Endurance = 0.50,     -- skalar uthållighetens storlek och återhämtning
	JumpStrength = 0.50,
	Temperament = "Calm", -- Calm | Energetic | Sensitive | Brave | Stubborn

	MaxStamina = 100,
	BondLevel = 0,
}

--[[ ── Rörelse ──────────────────────────────────────────────────────── ]]
Config.MOVEMENT = {
	--[[ ── Svängen som kurvatur ──────────────────────────────────────
	     Styraxeln ber om en KURVATUR i 1/meter — hur snävt hästen böjer
	     sig — och vridhastigheten faller ut som kurvatur × tempo. Det
	     betyder att svängradien blir 1/kurvatur oavsett fart, alltså att
	     en snabbare gångart automatiskt ger en vidare båge.

	     Förut räknades vridhastigheten direkt och växte med farten
	     (TurnRateBase + TurnRateGain × tempo, tak 2,20 rad/s). I
	     fyrsprång gav det 126 grader i sekunden, vilket gör att man viker
	     hästen genom en sväng i stället för att rida den. De gamla
	     fälten är borta; gångartens turn-faktor lever kvar och skalar
	     kurvaturtaket i stället för vridhastigheten.

	     CurvatureMax är satt så att full styrning i skritt ger ungefär
	     3,3 m radie, samma som webbversionens modell. ]]
	CurvatureMax = 0.30,   -- 1/m vid full styrning i skritt
	CurvatureTauPress = 0.13,   -- sekunder att lägga sig i bågen
	CurvatureTauRelease = 0.19, -- längre: att räta upp sig tar tid
	TurnAccel = 6.0,       -- hur snabbt svängen får fäste, rad/s²

	--[[ Vändning på stället. Kurvaturmodellen ger noll vridning vid noll
	     fart — omega är kurvatur GÅNGER tempo — och det är rätt under
	     ritt: en häst i rörelse ska inte kunna snurra på fläcken. Men en
	     häst som STÅR ska kunna vrida sig, och tillståndsmaskinen har ett
	     eget läge för det. Den här termen blandas in där farten är låg
	     och tonas ut helt när hästen går. ]]
	TurnInPlaceRate = 0.85,   -- rad/s vid full styrning från stillastående
	TurnInPlaceBelow = 0.55,  -- m/s: över detta finns den inte alls

	--[[ Rampen på styrutslaget, sekunder. En tangent är av eller på, så
	     utan den finns bara tre lägen: helt vänster, rakt, helt höger.
	     Press är kortare än Release: svängen ska ta direkt men lämnas
	     mjukt. Hålls tiderna under ~0,2 s känns styrningen fortfarande
	     omedelbar — över det börjar den kännas trög. ]]
	SteerTauPress = 0.11,
	SteerTauRelease = 0.17,

	--[[ Lutningen samordnad med webbversionen. Signalen är densamma på
	     båda — centripetalkraften, alltså vridhastighet × tempo, vilket
	     är samma storhet som kurvatur × tempo² — men Roblox tillät 0,26
	     rad (15°) mot webbens 0,075 (4,3°). Femton grader läser som
	     motorcykel; en häst lutar sig knappt. ]]
	LeanMax = 0.075,       -- radianer roll i skarp sväng ≈ 4,3°
	LeanGain = 0.012,      -- roll per (rad/s × m/s)
	LeanTau = 0.16,        -- utjämning, sekunder

	ReverseSpeed = 1.1,    -- m/s bakåt
	BrakeExtra = 2.4,      -- m/s² extra retardation vid begärt stopp

	JumpPower = 42,        -- studs/s uppåt
	JumpMinSpeed = 1.6,
	JumpCooldown = 0.85,
	JumpStamina = 6,

	SlopeAlign = 0.55,     -- hur mycket av markens lutning kroppen tar
	SlopeTau = 0.25,       -- utjämning, sekunder — utan den skakar hästen
	ProbeDepth = 8,        -- studs, markavkänningens räckvidd
}

--[[ ── Studs per meter ──────────────────────────────────────────────
     All spellogik räknar i meter för att matcha den befintliga
     ridmodellen. Roblox räknar i studs. Omräkningen sker på ett ställe. ]]
Config.STUDS_PER_METRE = 3.0

function Config.toStuds(metres: number): number
	return metres * Config.STUDS_PER_METRE
end

function Config.toMetres(studs: number): number
	return studs / Config.STUDS_PER_METRE
end

--[[ ── Raser ─────────────────────────────────────────────────────────
     En ras är enbart data. Ingen ras får egen controllerkod — behöver en
     ras något systemet inte kan, är det systemet som ska växa. ]]
Config.BREEDS = {
	Arabian      = { Speed = .62, Acceleration = .66, Agility = .74, Endurance = .78, JumpStrength = .55, Temperament = "Sensitive", Height = 1.52 },
	Thoroughbred = { Speed = .84, Acceleration = .74, Agility = .52, Endurance = .58, JumpStrength = .62, Temperament = "Energetic", Height = 1.63 },
	Friesian     = { Speed = .48, Acceleration = .42, Agility = .46, Endurance = .56, JumpStrength = .48, Temperament = "Calm",      Height = 1.65 },
	Icelandic    = { Speed = .44, Acceleration = .58, Agility = .70, Endurance = .82, JumpStrength = .40, Temperament = "Brave",     Height = 1.38 },
	Warmblood    = { Speed = .58, Acceleration = .55, Agility = .58, Endurance = .62, JumpStrength = .72, Temperament = "Calm",      Height = 1.66 },
	QuarterHorse = { Speed = .66, Acceleration = .82, Agility = .68, Endurance = .54, JumpStrength = .50, Temperament = "Calm",      Height = 1.52 },
	Andalusian   = { Speed = .54, Acceleration = .60, Agility = .66, Endurance = .60, JumpStrength = .54, Temperament = "Brave",     Height = 1.60 },
	Mustang      = { Speed = .60, Acceleration = .64, Agility = .72, Endurance = .74, JumpStrength = .56, Temperament = "Stubborn",  Height = 1.50 },
	Shetland     = { Speed = .30, Acceleration = .52, Agility = .76, Endurance = .70, JumpStrength = .30, Temperament = "Stubborn",  Height = 1.02 },
}

--[[ Lynnet styr uttryck, inte svårighet. Det ska märkas på hur hästen
     beter sig när den står still — aldrig på att den blir jobbig att rida. ]]
Config.TEMPERAMENTS = {
	Calm      = { idleInterval = 9.0, reactGain = 0.80, accelBias = 1.00, soundRate = 0.6 },
	Energetic = { idleInterval = 5.0, reactGain = 1.25, accelBias = 1.08, soundRate = 1.3 },
	Sensitive = { idleInterval = 6.0, reactGain = 1.35, accelBias = 1.04, soundRate = 1.1 },
	Brave     = { idleInterval = 10.0, reactGain = 0.70, accelBias = 1.02, soundRate = 0.5 },
	Stubborn  = { idleInterval = 8.0, reactGain = 0.90, accelBias = 0.92, soundRate = 0.8 },
}

--[[ ── Animationer ───────────────────────────────────────────────────
     Namnen är nycklar, inte id:n. De verkliga rbxassetid-strängarna sätts
     som attribut på AnimationConfig i modellen, så att varje ras kan ha
     egna klipp utan att koden vet om det. ]]
Config.ANIMATION_KEYS = {
	"Idle", "IdleLookAround", "IdleTailSwish", "IdleEarFlick", "IdlePawGround",
	"Walk", "Trot", "Canter", "Gallop",
	"JumpStart", "JumpAir", "JumpLand",
	"Stop", "BackUp", "TurnLeft", "TurnRight",
	"Rear", "Graze",
}

--[[ Vilket klipp ett tillstånd spelar, och hur lång övertoningen är.
     Övertoningarna är olika långa med flit: uppåt i gångart går snabbt
     (hästen tar i), nedåt går mjukare (den rullar ut). ]]
--[[ `phase = true` betyder att klippet INTE spelas av sin egen klocka utan
     spolas av `loco.phase`, alltså av tillryggalagd sträcka. Se
     `AnimationController:step` för varför, och `HASTRIGG-KRAVSPEC.md` § 4.

     Bara de fyra cykliska gångarterna är fasdrivna. `Jump`, `Landing`,
     `Stopping` och `TurningInPlace` är händelser: de ska ta lika lång tid
     varje gång oavsett hur långt hästen kom under dem, och en fas som
     inte tickar när hästen står still skulle låsa dem i första bildrutan.
     `BackingUp` lämnas på klockan därför att fasen bara växer med
     `moved`, som är en längd utan tecken — baklänges ser ut som framåt. ]]
Config.STATE_ANIMATION = {
	Idle           = { key = "Idle",      fade = 0.35, looped = true },
	Walk           = { key = "Walk",      fade = 0.30, looped = true, phase = true },
	Trot           = { key = "Trot",      fade = 0.22, looped = true, phase = true },
	Canter         = { key = "Canter",    fade = 0.20, looped = true, phase = true },
	Gallop         = { key = "Gallop",    fade = 0.18, looped = true, phase = true },
	Jump           = { key = "JumpAir",   fade = 0.12, looped = true },
	Landing        = { key = "JumpLand",  fade = 0.10, looped = false },
	Stopping       = { key = "Stop",      fade = 0.16, looped = false },
	BackingUp      = { key = "BackUp",    fade = 0.25, looped = true },
	TurningInPlace = { key = "TurnLeft",  fade = 0.28, looped = true },
}

Config.IDLE_VARIANTS = { "IdleLookAround", "IdleTailSwish", "IdleEarFlick", "IdlePawGround" }

--[[ ── Kamera ────────────────────────────────────────────────────────
     Basvärden; gångarterna lägger till sina egna avstånd och fov. ]]
Config.CAMERA = {
	BaseFov = 70,
	MaxFov = 80,
	Tau = 0.35,          -- hur trögt kameran följer gångartsbytet
	YawTau = 0.13,       -- hur trögt kameran följer hästens kurs
	                     -- Kort: hästen ska svänga först och bilden hinna
	                     -- ifatt. Över ~0,2 s tappar man känslan av att
	                     -- styra, under ~0,08 s rycker bilden igen.
	Shoulder = 2.0,      -- studs åt sidan
	LookAhead = 6.0,     -- studs framför hästen som kameran siktar mot
}

--[[ ── Uthållighet ───────────────────────────────────────────────────
     Får aldrig tvinga hästen till stopp. Den sänker taket, hästen rullar
     ned en gångart, och spelaren ser varför i HUD:en. ]]
Config.STAMINA = {
	LowThreshold = 0.35,   -- under detta börjar taket sjunka
	FloorGait = "trot",    -- lägsta tak uthållighet kan pressa ned till
	RecoveryDelay = 1.2,   -- sekunder efter ansträngning innan påfyllning
}

--[[ Läser ett attribut ur en Configuration med fallback och typkontroll.
     Fel typ i Studio ska aldrig krascha spelet — då används standardvärdet
     och en varning skrivs en gång per nyckel. ]]
local warned: { [string]: boolean } = {}

function Config.attr(container: Instance?, key: string, fallback: any): any
	if not container then return fallback end
	local value = container:GetAttribute(key)
	if value == nil then return fallback end
	if typeof(value) ~= typeof(fallback) then
		if not warned[key] then
			warned[key] = true
			warn(("[Horse] %s är %s, förväntade %s. Använder standardvärdet.")
				:format(key, typeof(value), typeof(fallback)))
		end
		return fallback
	end
	return value
end

--[[ Slår ihop ras och individ till en färdig statistiktabell. Individens
     attribut vinner över rasens; rasens vinner över standard. ]]
function Config.resolveStats(statsConfig: Instance?): { [string]: any }
	local out = table.clone(Config.STATS)

	local breed = Config.attr(statsConfig, "Breed", out.Breed)
	local breedRow = Config.BREEDS[breed]
	if breedRow then
		out.Breed = breed
		for key, value in breedRow do
			out[key] = value
		end
	end

	for key, fallback in out do
		out[key] = Config.attr(statsConfig, key, fallback)
	end
	return out
end

--[[ Fyller en Configuration med de attribut som saknas, så att allt går
     att se och skruva i Studio i stället för att ligga dolt i kod. ]]
function Config.writeDefaults(container: Configuration, source: { [string]: any })
	for key, value in source do
		if container:GetAttribute(key) == nil and typeof(value) ~= "table" then
			container:SetAttribute(key, value)
		end
	end
end

return Config
