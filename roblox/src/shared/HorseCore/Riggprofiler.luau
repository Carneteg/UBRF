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
		--[[ HELA huvudet, inte bara leden. `Head` är en BIT: modellen delar
			upp huvudet i Head plus fyra `HeadS` och två öron. Delen mäter
			0,76 x 1,24 x 1,16 medan hela huvudet mäter 1,14 x 1,99 x 1,87 —
			och ett träns byggt på delens mått hamnade INNE i nätet.

			`HastVisual` mäter de här delarnas samlade utsträckning när nätet
			monteras och skriver den som attribut, så `TackRigg` kan bygga
			ett träns som passar huvudet i stället för en sjundedel av det. ]]
		huvuddelar = { "Head", "HeadS", "LEar", "REar" },
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
		--[[ ══ UTSEENDEGRUPPERNA ═══════════════════════════════════════

			K3 har INGA texturer. Varje av de fyrtio delarna är enfärgad,
			och modellören har redan färgkodat anatomin åt oss:

			    #7C5C46  päls          kropp, hals, huvud, öron, lår, bogar
			    #70533F  päls i skugga underarm och underben
			    #4A3629  man och svans N1S..N3S, Tail, pannlugg
			    #564236  mule
			    #CACBD1  vitt tecken   fyra skenben OCH en bläs i pannan
			    #1B2A35  mörkt         hovar, kotor, ögonband

			Det betyder att hästen går att klä om per kroppsdel utan att
			röra ett enda nät — och att de fyra skenbenen och pannpartiet
			ÄR strumpor och bläs, färdiga att styras av `tecken` i
			rostern. Modellen är byggd för precis den variationen.

			Grupperna hittas alltså genom modellens EGNA ursprungsfärger,
			inte genom en namnlista: en namnlista hade blivit fel så fort
			modellören döpte om en del, medan färgkodningen är hans egen
			avsikt. Klassningen görs en gång vid monteringen, INNAN något
			målas om, och skrivs som attribut på delen.

			Vitt tecken skiljs på höjd: över manken är det en bläs, under
			buken är det en strumpa. Talet är i rotens rum. ]]
		utseende = {
			kropp    = "7C5C46",
			skugga   = "70533F",
			man      = "4A3629",
			mule     = "564236",
			tecken   = "CACBD1",
			mork     = "1B2A35",
			--[[ Över den här höjden i rotens rum är ett vitt tecken en
				bläs; under den är det en strumpa. Bläsen sitter på
				y ≈ 1,37 och skenbenen på y ≈ −2,2. ]]
			blasHojd = 0.0,
			--[[ Vilket ben ett skenben hör till, i rosterns egen
				benföljd. Namnen är K3:s; kartan är profilens jobb. ]]
			ben = {
				framV = { "LMetacarpal", "LHand" },
				framH = { "RMetacarpal", "RHand" },
				bakV  = { "LAnkle", "LFoot" },
				bakH  = { "RAnkle", "RFoot" },
			},
			hov = "Hoof",
			--[[ ══ FJORDHÄSTENS MITTSTRIMMA ═══════════════════════════

				Första försöket färgade manens MITTSEGMENT (`N2S`) mörkt.
				Det blev en fläck, inte en strimma — och uppmätt är det
				inte konstigt: K3:s manslabbar sitter alla på hästens
				HÖGRA sida (x ≈ +0,3), det finns ingen man på vänster sida
				och ingen del alls längs kammens mitt.

				En fjordhästs midtstol går längs HELA kammen, mitt i den
				upprätta manen. Den ritas därför som en egen smal remsa
				per halssegment, i x = 0 och strax ovanför halsens
				ovankant — samma sorts svetsade del som utrustningen
				använder, inte ny rasgeometri. Remsan byggs BARA för
				hästar vars foto faktiskt visar en tvåfärgad man.

				`bredd` och `hojd` är andelar av halsdelens egna mått, så
				strimman följer med när hästen skalas. ]]
			mankstrimma = {
				leder = { "N1", "N2", "N3", "N4" },
				--[[ Framsökt i två steg. 0,16 x 0,10 på höjd 0,46 la
					remsan OVANPÅ manen och den läste som en rad klossar.
					0,13 x 0,065 på 0,42 lägger den INNE i manen, där bara
					linjen längs kammen syns — vilket är vad en midtstol
					är. Andelar av halsdelens egna mått, så den följer med
					när hästen skalas. ]]
				bredd = 0.13,
				tjocklek = 0.065,
				hojd = 0.42,
			},
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
				stigbyglarna i sadeln och rör inte de här.

				FLYTTADE efter den visuella granskningen. Originalets läge
				var modellens eget, och det låg uppmätt

				    ±0,564 ut · 0,843 NED · 1,356 studs FRAM

				från sadelpunkten. En och en tredjedels stud framför sadeln
				är mer än halva bålen: ryttarens fötter drogs fram mot
				bogen, och benet hamnade långt framför henne. Det var den
				ena halvan av "ryttaren sitter för långt fram".

				Nu hänger de ±0,95 ut, 0,55 ned och 0,05 studs fram från
				sadelpunkten.

				HÖJDEN ÄR FRAMSÖKT, inte vald. Första försöket la dem 1,35
				studs ned — anatomiskt rätt, men UTOM RÄCKHÅLL: uppmätt satt
				ryttarens fot då kvar på (−0,50 · +0,22 · −1,50), alltså
				1,57 studs ÖVER bygeln, och stigläderet hängde ensamt under
				buken. En Roblox-ryttare sitter med höften 1,74 studs över
				sadelpunkten och har knappt 2,9 studs ben; en bygel 1,35 ned
				kräver nästan raka ben och IK ger upp före det.

				0,55 ned ger en böjd knäled som en ryttare faktiskt har, och
				foten når fram.

				BREDDEN flyttades ut från ±0,62 till ±0,95 studs av samma
				sorts skäl: uppmätt är bålen 0,86 studs halvbred vid sadeln,
				och en fot på 0,62 hamnade INNANFÖR sadelns egen flik. En
				ryttares ben ligger utanpå fliken, inte mellan den och
				hästen. Talen nedan är lägena omräknade till modellens egna
				enheter (skalan är 0,7526 studs per enhet). ]]
			LeftStirrupAttachment  = { vard = "UpperBody", cf = CFrame.new(-1.262, -0.011, 1.284) },
			RightStirrupAttachment = { vard = "UpperBody", cf = CFrame.new(1.262, -0.011, 1.284) },
			--[[ HÄNDERNA. NY punkt, och den andra halvan av samma problem.

				Ryttarens händer hade tidigare BETTET som IK-mål. Bettet
				ligger 3,3 studs fram och 1,5 studs ned från sadeln — det
				är hästens mun. Att dra en sittande ryttares händer dit
				vrider hela överkroppen framåt, och det är exakt de 45
				grader granskningen såg.

				En ryttare håller tyglarna ÖVER MANKEN, strax framför och
				ovanför sadeln, med böjd armbåge. Tygeln är det som spänner
				mellan handen och bettet — inte armen. Punkterna ligger
				därför 0,62 upp och 0,62 studs fram från sadelpunkten, och
				`TackRigg.byggTyglar` drar tygeln hit.

				BREDDEN är framsökt: ±0,30 låg innanför ryttarens egna axlar,
				och handen stannade uppmätt 0,91 studs utanför målet — tygeln
				slutade alltså bredvid handen i stället för i den. ±0,55 är
				där handen faktiskt hamnar. ]]
			LeftHandAttachment     = { vard = "UpperBody", cf = CFrame.new(-0.731, 1.544, 0.526) },
			RightHandAttachment    = { vard = "UpperBody", cf = CFrame.new(0.731, 1.544, 0.526) },
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
		--[[ Bålen: den led kroppens gung och vaggning skrivs på. Utan den
			går benen men kroppen står stilla, och då läses gången som en
			marionett. ]]
		bal = led(p.bal),
		huvud = led(p.huvud),
		hals = kedja(p.hals),
		svans = led(p.svans),
		framben = { v = kedja(p.framben.v), h = kedja(p.framben.h) },
		bakben = { v = kedja(p.bakben.v), h = kedja(p.bakben.h) },
	}
end

return Riggprofiler
