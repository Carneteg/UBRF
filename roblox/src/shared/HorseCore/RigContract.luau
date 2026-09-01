--!strict
--[[
	Riggkontraktet som prov — issue #31.

	`RigAdapter.build()` är MED FLIT förlåtande. Hittar den ingen
	`BodyCollider` tar den `PrimaryPart`; finns inte den heller tar den den
	största delen som inte är ett skinnat nät. Saknas en `Animator` skapar den
	en. Det är rätt för körtiden — spelet ska inte krascha för att någon byggt
	modellen slarvigt.

	Följden är att `build()` lyckas på riggar som INTE uppfyller kontraktet i
	`HORSE-MODEL-SPEC.md`. En häst vars kollision är det skinnade nätet studsar
	mot marken i takt med gångarten, och `build()` säger ingenting om det.

	Den här modulen är den stränga halvan. Den svarar på en annan fråga än
	adaptern: inte *"kan spelet ladda den här?"* utan *"får den här riggen
	accepteras som UBRF:s häst?"*.

	Vad den INTE kan svara på står i `RigContract.EJ_PROVAT`. Den listan är
	en del av leveransen, inte en brasklapp: en kontroll som tiger om sina
	blinda fläckar läses som fullständig, och då blir grönt ett falskt besked.
]]

local RigAdapter = require(script.Parent.RigAdapter)
local Config = require(script.Parent.Config)

local RigContract = {}

--[[ De fem fästpunkterna. Namnen är kontraktet; `Map_<namn>` får peka om
     dem, och det är RigAdapter.hittaDel som följer den omdöpningen. ]]
RigContract.ATTACHMENTS = {
	"SaddleAttachment",
	"LeftReinAttachment",
	"RightReinAttachment",
	"LeftStirrupAttachment",
	"RightStirrupAttachment",
}

--[[ Obligatoriska klipp enligt HORSE-MODEL-SPEC § Animationer. `RiderSeated`
     står inte här: den spelas på spelarens egen Animator, inte hästens, och
     hör därför inte till hästriggens kontrakt. ]]
RigContract.KLIPP = {
	"Idle", "Walk", "Trot", "Canter", "Gallop",
	"JumpAir", "JumpLand", "Stop", "BackUp",
	"TurnLeft", "TurnRight",
}

--[[ Vad ingen headless kontroll kan avgöra. Kräver Studio, källfilen eller
     ögon. Redovisas av `rapport()` så att ingen läser ett grönt utfall som
     ett godkänt #31. ]]
RigContract.EJ_PROVAT = {
	"rotbenet ligger i origo och pekar framåt längs +Z — kräver skelettet",
	"klippens längd i sekunder mot tabellen — kräver animationstillgångarna",
	"triangel- och benbudget — kräver källfilen",
	"att modellen importerar rent i Studio",
	"att silhuetten läses som häst",
	"att fysiken är stabil under mount, gångarter och avsittning",
}

local function fynd(lista, regel: string, allvar: string, text: string)
	table.insert(lista, { regel = regel, allvar = allvar, text = text })
end

--[[ Måtten faller ur mankhöjden. Regeln är utläst ur HORSE-MODEL-SPEC:s egna
     varmblodssiffror (5,98 × 3,98 × 2,49 studs vid 1,66 m), inte påhittad
     ovanpå dem — se HASTRIGG-KRAVSPEC § 1. ]]
function RigContract.matt(mankhojdMeter: number)
	local h = mankhojdMeter * Config.STUDS_PER_METRE
	return { langd = h * 1.20, djup = h * 0.80, bredd = h * 0.50, hojd = h }
end

--[[ Ett skinnat nät har en hölje-hitbox som ändrar form med animationen.
     RigAdapter använder samma kännetecken när den letar reservdel: en
     MeshPart med barn är skinnad. ]]
local function arSkinnatNat(del: Instance): boolean
	return del:IsA("MeshPart") and #del:GetChildren() > 0
end

local function hamtaTal(inst: Instance, namn: string): number?
	local v = (inst :: any)[namn]
	return if typeof(v) == "number" then v else nil
end

local function hamtaBool(inst: Instance, namn: string): boolean?
	local v = (inst :: any)[namn]
	return if typeof(v) == "boolean" then v else nil
end

--[[ `opts.hastar` är rostern ur UBRFSpel.hastar när den finns; utan den
     hoppas roster-kontrollen över i stället för att gissa. `opts.harTagg`
     låter den som kör kontrollen svara på taggfrågan själv — i Studio via
     CollectionService, i bänken med en tabell. ]]
export type Val = {
	hastar: { [string]: any }?,
	harTagg: ((Instance, string) -> boolean)?,
	tolerans: number?,
}

function RigContract.kontrollera(model: Instance, opts: Val?)
	local o: Val = opts or {}
	local tol = o.tolerans or 0.15
	local ut = {}

	if not model:IsA("Model") then
		fynd(ut, "modell", "FEL", "Hästen måste vara en Model")
		return ut
	end

	--[[ ── Identitet ───────────────────────────────────────────────── ]]
	if o.harTagg and not o.harTagg(model, "Horse") then
		fynd(ut, "tagg", "FEL", "Modellen saknar CollectionService-taggen Horse")
	end

	local id = model:GetAttribute("HorseId")
	if typeof(id) ~= "string" or id == "" then
		fynd(ut, "horseid", "FEL", "HorseId saknas eller är inte en icke-tom sträng")
	elseif o.hastar and o.hastar[id] == nil then
		fynd(ut, "horseid", "FEL",
			("HorseId %q finns inte i UBRFSpel.hastar"):format(id))
	end

	--[[ ── Kroppens kollisionsdel ──────────────────────────────────────
	     STRÄNGT: bara namnet eller Map_BodyCollider räknas. RigAdapter får
	     falla tillbaka på PrimaryPart och på största delen, för spelet ska
	     rulla vidare. En acceptanskontroll får inte det: faller den tillbaka
	     godkänner den en rigg vars kollision är det skinnade nätet, vilket
	     är precis den bugg specen kallar den viktigaste regeln. ]]
	local kropp = RigAdapter.hittaDel(model, "BodyCollider")
	if kropp == nil then
		fynd(ut, "kollision", "FEL",
			"Ingen BodyCollider. Döp en osynlig låda till BodyCollider, "
			.. "eller sätt Map_BodyCollider på modellen")
	elseif not kropp:IsA("BasePart") then
		fynd(ut, "kollision", "FEL", "BodyCollider är ingen BasePart")
	elseif arSkinnatNat(kropp) then
		fynd(ut, "kollision", "FEL",
			"BodyCollider är ett skinnat nät. Hitboxen ändrar form med "
			.. "animationen och hästen studsar i takt med gångarten")
	else
		local d = kropp :: BasePart
		if hamtaBool(d, "CanCollide") == false then
			fynd(ut, "kollision", "FEL", "BodyCollider.CanCollide är false")
		end
		if hamtaBool(d, "Massless") == true then
			fynd(ut, "kollision", "FEL", "BodyCollider.Massless är true")
		end
		if (hamtaTal(d, "Transparency") or 1) < 1 then
			fynd(ut, "kollision", "VARNING",
				"BodyCollider syns (Transparency < 1); den ska vara osynlig")
		end
	end

	--[[ ── Ryttarsätet ─────────────────────────────────────────────── ]]
	local sate = RigAdapter.hittaDel(model, "RiderSeat")
	if sate == nil then
		fynd(ut, "sate", "FEL", "RiderSeat saknas")
	elseif not sate:IsA("Seat") then
		fynd(ut, "sate", "FEL", "RiderSeat är ingen Seat")
	else
		if hamtaBool(sate, "CanCollide") == true then
			fynd(ut, "sate", "FEL",
				"RiderSeat.CanCollide är true; sätet ska inte kollidera")
		end
		if hamtaBool(sate, "Massless") == false then
			fynd(ut, "sate", "FEL", "RiderSeat.Massless är false")
		end
	end

	--[[ ── Fästpunkterna ───────────────────────────────────────────── ]]
	for _, namn in RigContract.ATTACHMENTS do
		local a = RigAdapter.hittaDel(model, namn)
		if a == nil then
			fynd(ut, "attachment", "FEL", namn .. " saknas")
		elseif not a:IsA("Attachment") then
			fynd(ut, "attachment", "FEL", namn .. " är ingen Attachment")
		end
	end

	--[[ ── Humanoid ────────────────────────────────────────────────────
	     AnimationController räcker inte. Den ger animationer men ingen
	     markhantering, och det här systemet levererar ingen egen. Specen
	     säger det rakt ut, och en rigg som väljer den vägen svävar. ]]
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid == nil then
		if model:FindFirstChildOfClass("AnimationController") then
			fynd(ut, "humanoid", "FEL",
				"Modellen har AnimationController men ingen Humanoid. "
				.. "Systemet levererar ingen egen markhantering")
		else
			fynd(ut, "humanoid", "FEL", "Humanoid saknas")
		end
	else
		if humanoid:FindFirstChildOfClass("Animator") == nil then
			fynd(ut, "humanoid", "FEL", "Humanoid saknar Animator")
		end
		if hamtaBool(humanoid, "RequiresNeck") == true then
			fynd(ut, "humanoid", "FEL",
				"RequiresNeck är true; hästen har ingen Roblox-hals")
		end
		if hamtaBool(humanoid, "BreakJointsOnDeath") == true then
			fynd(ut, "humanoid", "FEL",
				"BreakJointsOnDeath är true; modellen faller isär")
		end
		local lut = hamtaTal(humanoid, "MaxSlopeAngle")
		if lut and math.abs(lut - 55) > 0.5 then
			fynd(ut, "humanoid", "VARNING",
				("MaxSlopeAngle är %.0f, specen säger 55"):format(lut))
		end
	end

	--[[ ── Skala och HipHeight, mätt mot rasens mankhöjd ───────────────
	     Kräver både en läsbar ras och en läsbar kropp. Saknas någondera
	     hoppas kontrollen över — och säger det, i stället för att räkna på
	     ett antaget varmblod och kalla utfallet mätt. ]]
	local stats = model:FindFirstChild("HorseStats")
	local ras = if stats then stats:GetAttribute("Breed") else nil
	local rasrad = if typeof(ras) == "string" then Config.BREEDS[ras] else nil

	if rasrad == nil then
		fynd(ut, "skala", "VARNING",
			"Ingen läsbar Breed i HorseStats — måtten kunde inte prövas")
	elseif kropp and kropp:IsA("BasePart") and not arSkinnatNat(kropp) then
		local vantat = RigContract.matt(rasrad.Height)
		local storlek = (kropp :: BasePart).Size
		local matt = {
			{ "längd", storlek.Z, vantat.langd },
			{ "djup", storlek.Y, vantat.djup },
			{ "bredd", storlek.X, vantat.bredd },
		}
		for _, rad in matt do
			local namn, ar, ska = rad[1] :: string, rad[2] :: number, rad[3] :: number
			if math.abs(ar - ska) > ska * tol then
				fynd(ut, "skala", "FEL",
					("BodyCollider %s är %.2f studs, väntat %.2f (±%.0f %%) "
						.. "för %s"):format(namn, ar, ska, tol * 100, ras))
			end
		end

		if humanoid then
			local hip = hamtaTal(humanoid, "HipHeight")
			local skaHip = vantat.hojd - storlek.Y / 2
			if hip and math.abs(hip - skaHip) > 0.25 then
				fynd(ut, "skala", "FEL",
					("HipHeight är %.2f, väntat %.2f (mankhöjd %.2f studs "
						.. "minus halva colliderhöjden)"):format(hip, skaHip, vantat.hojd))
			end
		end
	end

	--[[ ── Klippen ─────────────────────────────────────────────────── ]]
	local anim = model:FindFirstChild("AnimationConfig")
	if anim == nil then
		fynd(ut, "klipp", "FEL", "AnimationConfig saknas")
	else
		for _, nyckel in RigContract.KLIPP do
			local v = anim:GetAttribute(nyckel)
			if typeof(v) ~= "string" or v == "" then
				fynd(ut, "klipp", "FEL", "AnimationConfig." .. nyckel .. " saknas")
			end
		end
	end

	--[[ ── Inga skript i en köpt modell ────────────────────────────────
	     Issue #31: UBRF:s system ligger utanför tillgången. Ett skript som
	     följer med en köpt modell kör i vår värld utan att någon läst det. ]]
	for _, d in model:GetDescendants() do
		if d:IsA("BaseScript") or d:IsA("ModuleScript") then
			fynd(ut, "skript", "FEL",
				("Skript i modellen: %s. UBRF:s system ska ligga utanför "
					.. "tillgången"):format(d.Name))
		end
	end

	return ut
end

function RigContract.fel(fyndlista): number
	local n = 0
	for _, f in fyndlista do
		if f.allvar == "FEL" then n += 1 end
	end
	return n
end

function RigContract.rapport(fyndlista): string
	local rader = {}
	if #fyndlista == 0 then
		table.insert(rader, "Riggen uppfyller allt som gar att prova headless.")
	else
		for _, f in fyndlista do
			table.insert(rader, ("  %-8s %-11s %s"):format(f.allvar, f.regel, f.text))
		end
	end
	table.insert(rader, "")
	table.insert(rader, "EJ PROVAT (kraver Studio, kallfilen eller ogon):")
	for _, rad in RigContract.EJ_PROVAT do
		table.insert(rader, "  - " .. rad)
	end
	return table.concat(rader, "\n")
end

return RigContract
