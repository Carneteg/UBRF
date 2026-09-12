--!strict
--[[
	RIGGPROFILER — vad en viss hästmodell kallar sina kroppsdelar.

	══ VARFÖR DEN HÄR MODULEN FINNS ═══════════════════════════════════

	Varje köpt hästmodell har sina egna delnamn. K3 kallar bålen
	`MiddleBody`, halsen `N1..N4` och framknäet `LElbow`. Nästa modell
	kallar dem något annat.

	Gameplayet får aldrig veta det. Servern som monterar nätet och
	klienten som animerar benen frågar båda efter ANATOMI — `profil.huvud`,
	`profil.framben.v` — och profilen är det enda stället som vet vad de
	heter i just den modellen. Byts modellen byts profilen, inte koden.

	Modulen ligger DELAD därför att båda sidorna behöver samma karta:
	`HastVisual` på servern bygger, `HastGang` på klienten animerar.

	══ FRAMÅTKONVENTIONEN ═════════════════════════════════════════════

	`framatZ` säger vilket håll modellören byggde nosen åt. Är den +1
	monteras nätet med ett halvt varv i `HastVisual.montera`, och det är
	den ENDA plats i projektet där en sådan vridning får finnas. Spelets
	rot, kursintegrationen och `LookVector` rörs aldrig.
]]

local Riggprofiler = {}

--[[ `mankhojd` är modellens EGEN mankhöjd i studs, uppmätt från hovarnas
	underkant till bålens ovansida. Skalan räknas ur den i stället för att
	skrivas som en magisk faktor: byts modellen räcker det att mäta om.

	`tackfasten` är uppmätta ur modellens EGEN inbyggda utrustning INNAN
	den revs. Modellören hade redan placerat bygel- och tygelfästena
	anatomiskt rätt på sitt eget nät; att läsa av dem är skillnaden mot
	att gissa en koordinat. ]]
local PROFILER: { [string]: any } = {
	k3 = {
		kalla = "Creator Store 5878963783 (jameesbound)",
		framatZ = -1,            -- nosen på lokalt -Z: Roblox egen konvention
		mankhojd = 5.78,         -- studs, uppmätt i modellen
		rot = "HumanoidRootPart",
		bal = "MiddleBody",
		framkropp = "UpperBody",
		bakkropp = "LowerBody",
		huvud = "Head",
		hals = { "N1", "N2", "N3", "N4" },
		svans = "Tail",
		framben = {
			v = { "LShoulder", "LArm", "LElbow", "LMetacarpal", "LHand" },
			h = { "RShoulder", "Rarm", "RElbow", "RMetacarpal", "RHand" },
		},
		bakben = {
			v = { "LThigh", "LLeg", "LAnkle", "LFoot" },
			h = { "RThigh", "RLeg", "RAnkle", "RFoot" },
		},
		--[[ Det som INTE är häst och rivs vid städningen.

			`BodyPosition` och `BodyGyro` är inte kosmetik utan kvarlevor
			av modellens eget rörelsesystem. De hade dragit hästen mot ett
			eget mål mitt i vår lokomotion, och de hör till det farligaste
			i en importerad rigg just för att de ser oskyldiga ut. ]]
		riv = {
			klasser = { "Script", "LocalScript", "ModuleScript", "RemoteEvent",
				"RemoteFunction", "Sound", "BodyPosition", "BodyGyro",
				"ParticleEmitter", "Seat", "IntValue", "NumberValue", "ObjectValue" },
			namn = { "Saddle", "Reins", "Bag", "Animations", "Health", "Dust" },
		},
		--[[ Var UBRF:s egna fästpunkter ska sitta, i värddelens lokala rum.
			Uppmätt: bygelfästena satt på (±0,710 · 1,300 · −0,452) mot
			`UpperBody`, bettets tygelfästen på (±0,29 · −0,579 · −0,409)
			mot `Head`. ]]
		tackfasten = {
			--[[ RYGGEN, framsökt i tre steg och inte räknad fram.

				`MeshPart.Size` är nätets omslutande låda, och en häst
				fyller inte sin låda — varken lådans mitt eller dess topp
				ligger på ryggen. Strålar duger inte heller: ett nät utan
				laddad kollisionsgeometri svarar med lådan.

				Läget är därför satt genom att bygga utrustningen på hästen
				och titta: 0,66 la sadeln inne i bålen, 1,302 la den
				svävande ovanför manken, 0,85 fortfarande högt och för långt
				fram. 0,72 med 1,35 bakåt lägger den där en sadel ska ligga
				— strax bakom bogbladet, på ryggen. ]]
			SaddleAttachment       = { vard = "UpperBody", cf = CFrame.new(0, 0.72, 1.35) },
			--[[ BYGLARNA hänger nedanför sadeln mot bålen. De används som
				IK-mål för ryttarens fötter; `TackRigg` bygger själva
				stigbyglarna i sadeln och rör inte de här. ]]
			LeftStirrupAttachment  = { vard = "UpperBody", cf = CFrame.new(-0.750, -0.400, -0.452) },
			RightStirrupAttachment = { vard = "UpperBody", cf = CFrame.new(0.750, -0.400, -0.452) },
			--[[ TRÄNSET. `Head` är bara en BIT av huvudet — modellen delar
				upp det i Head plus fyra `HeadS` och två öron — så en punkt
				satt mot `Head`s egen låda hamnar på kinden. Uppmätt ligger
				det samlade huvudet på (0,08 · −0,09 · 0,17) med nosen på
				z = −0,77 i `Head`s lokala rum, och läget nedan är framsökt
				därifrån tills nosgrimman satt på nosryggen. ]]
			BridleAttachment       = { vard = "Head",      cf = CFrame.new(0, 0.05, 0.15) },
			--[[ BETTET i mungiporna — modellens egna tygelfästen, uppmätta
				innan dess inbyggda träns revs. Asymmetrin i originalet
				(−0,300 mot +0,280) är modellörens slarv och rättad. ]]
			LeftReinAttachment     = { vard = "Head",      cf = CFrame.new(-0.29, -0.579, -0.409) },
			RightReinAttachment    = { vard = "Head",      cf = CFrame.new(0.29, -0.579, -0.409) },
		},
		--[[ SITSEN ovanpå sadeln, inte i modellens egen Seat.

			Originalets Seat låg på 0,746 — men den hörde till originalets
			egen sadel, som är riven. Ryttaren ska sitta på UBRF:s sadel, och
			den ligger på 1,302 plus sadelns egen tjocklek. ]]
		sits = { vard = "UpperBody", cf = CFrame.new(0, 1.060, 1.350) },
	},
}

Riggprofiler.PROFILER = PROFILER

function Riggprofiler.profil(namn: string?): any?
	if typeof(namn) ~= "string" then return nil end
	return PROFILER[namn]
end

--[[ Profilen en byggd häst faktiskt bär. Attributet sätts av
	`HastVisual.montera`; saknas det kör hästen på platshållarlådorna. ]]
function Riggprofiler.forHast(hast: Instance): any?
	return Riggprofiler.profil(hast:GetAttribute("VisuellProfil") :: any)
end

--[[ ══ LEDERNA, ANATOMISKT ════════════════════════════════════════════

	Svarar med `Motor6D`-kedjorna en gångdrivare behöver, i anatomisk
	ordning uppifrån och ned. Den som anropar får aldrig veta att det
	tredje benledet råkar heta `LMetacarpal`. ]]
function Riggprofiler.leder(hast: Instance): { [string]: any }?
	local p = Riggprofiler.forHast(hast)
	if not p then return nil end
	local visual = hast:FindFirstChild("Visual")
	local natet = visual and visual:FindFirstChild("Nät")
	if not natet then return nil end

	--[[ Leden som DRIVER en del är den vars `Part1` är delen. Den ligger
		normalt på delen själv, men en importerad rigg är inte alltid
		städad, så kedjan söks igenom som reserv. ]]
	local ledFor: { [BasePart]: Motor6D } = {}
	for _, c in ipairs(natet:GetDescendants()) do
		if c:IsA("Motor6D") and c.Part1 then ledFor[c.Part1] = c end
	end
	local function led(namn: string): Motor6D?
		local d = natet:FindFirstChild(namn, true)
		if not (d and d:IsA("BasePart")) then return nil end
		return ledFor[d]
	end
	local function kedja(namn: { string }): { Motor6D }
		local ut = {}
		for _, n in ipairs(namn) do
			local m = led(n)
			if m then table.insert(ut, m) end
		end
		return ut
	end
	return {
		profil = p,
		natet = natet,
		huvud = led(p.huvud),
		hals = kedja(p.hals),
		svans = led(p.svans),
		framben = { v = kedja(p.framben.v), h = kedja(p.framben.h) },
		bakben = { v = kedja(p.bakben.v), h = kedja(p.bakben.h) },
	}
end

return Riggprofiler
