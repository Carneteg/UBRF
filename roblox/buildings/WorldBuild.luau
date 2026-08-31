--!strict
--[[
	WorldBuild — gör den redan verifierade anläggningen spelbar.

	Körs EFTER Anlaggningen.luau. Den ersätter bara de fyra solida
	fasadväggarna per byggnad med motsvarande segment runt de öppningar som
	redan finns i UBRFKomplex. Ingen ny UBRF-geometri hittas på.

	Den återanvänder de befintliga dörr-/portpanelerna, ger dem runtime-data
	och ProximityPrompt, och skapar en gameplay-spawn vid ankomsten.
]]

local WorldBuild = {}

local SIDE_NAME = {
	S = "syd",
	N = "norr",
	W = "vast",
	E = "ost",
}

--[[ Fönsterlistan bor i WorldGeometry — den avgör både vad som blir hål och vad
     som får en prompt, och två kopior hade en dag svarat olika. Den skickas
     därför med dit den behövs i stället för att finnas här också. ]]

local function openingsForSide(building, sida: string)
	local out = {}
	for _, o in ipairs(building.oppningar or {}) do
		if o.sida == sida then table.insert(out, o) end
	end
	return out
end

local function facadeLength(r, sida: string): number
	return if sida == "S" or sida == "N" then r.w else r.h
end

local function segmentBox(BK, model: Model, base: CFrame, b, sida: string, seg, color: Color3, material: Enum.Material, t: number)
	local r = b.rekt
	local len = seg.s1 - seg.s0
	local h = seg.y1 - seg.y0
	local name = string.format("%s %s fasad %.2f-%.2f %.2f-%.2f",
		b.id, SIDE_NAME[sida], seg.s0, seg.s1, seg.y0, seg.y1)

	if sida == "S" then
		return BK.box(model, base, name, r.x + seg.s0, seg.y0, r.y,
			len, h, t, color, material)
	elseif sida == "N" then
		return BK.box(model, base, name, r.x + r.w - seg.s1, seg.y0, r.y + r.h - t,
			len, h, t, color, material)
	elseif sida == "E" then
		return BK.box(model, base, name, r.x + r.w - t, seg.y0, r.y + seg.s0,
			t, h, len, color, material)
	else
		return BK.box(model, base, name, r.x, seg.y0, r.y + r.h - seg.s1,
			t, h, len, color, material)
	end
end

local function replaceFacade(BK, WG, model: Model, base: CFrame, b, sida: string)
	local oldName = b.id .. " " .. SIDE_NAME[sida]
	local old = model:FindFirstChild(oldName)
	if not (old and old.ClassName == "Part") then
		warn("[WorldBuild] Hittar inte fasaden " .. oldName)
		return
	end

	local wall = old :: Part
	local color = wall.Color
	local material = wall.Material
	wall.Transparency = 1
	wall.CanCollide = false
	wall.CanQuery = false
	wall.CanTouch = false

	--[[ Tjockleken läses UR väggen som ersätts, inte ur en egen literal.
	     Den stod som 0.3 här och som VAGGT = 0.3 i Anlaggningen — två kopior av
	     samma tal, alltså en dag då den ena ändras och segmenten hamnar på ett
	     annat djup än väggen de ersätter. ]]
	local tjocklek = (if sida == "S" or sida == "N" then wall.Size.Z else wall.Size.X) / BK.M

	--[[ Bara passager blir riktiga hål. Fönster får INTE bli det.

	     Först punkterades varje öppning, fönster med. Det gav ingen spelvinst
	     — man går inte genom ett fönster — men gjorde varje valv till ett
	     genomgående hål i en 0,3 m tjock vägg med en tunn glasruta vid yttre
	     livet. På de norra gavlarna, som är just det `ankomsten` visar rakt
	     framifrån, sitter nio av fjorton öppningar och är valv. Fasaden i den
	     vyn slutade alltså se ut som den gjorde när F01 godkändes.

	     Dörrar och portar behöver hålet; det är hela poängen med PR:en. ]]
	local passager = WG.passager(openingsForSide(b, sida))

	local segments = WG.fasadBitar(facadeLength(b.rekt, sida), b.hV, passager)
	for _, seg in ipairs(segments) do
		segmentBox(BK, model, base, b, sida, seg, color, material, tjocklek)
	end
end

--[[ Panelen slås upp på IDENTITET, inte på närhet.

     Förut letade den här efter den närmaste Parten med rätt namn, utan någon
     avståndsgräns. Det gav rätt svar i dagens data, men namnet är typen —
     och två öppningar på samma fasad kan ha samma typ. Då avgör namnet
     ingenting, och närmast-vinner kan para ihop dem åt fel håll utan att
     någonting säger ifrån. Anlaggningen sätter BuildingId och OpeningId på
     panelen när den byggs; här läses bara de. ]]
local function findExistingDoor(model: Model, b, index: number): BasePart?
	for _, inst in ipairs(model:GetDescendants()) do
		if inst.ClassName == "Part"
			and inst:GetAttribute("BuildingId") == b.id
			and inst:GetAttribute("OpeningId") == index
		then
			return inst :: BasePart
		end
	end
	return nil
end

--[[ Dörrbladets stängda läge, räknat UR öppningen — samma källa som hålet i
     fasaden. Panelen flyttas dit i stället för att bladet ska definiera sitt
     eget läge; hål och blad kan då inte glida isär.

     Djupet är BuildKit.opening:s: en tunn skiva vid fasadlivet, på den sida
     `side` pekar ut. ]]
local function stangdCFrame(BK, GEO, base: CFrame, b, o): CFrame
	local mx, mz = GEO.oppningsMitt(b.rekt, o.sida, o.u, o.b)
	local _, _, along, side = GEO.oppningsHorn(b.rekt, o.sida, o.u, o.b)
	local halvDjup = BK.OPPNINGSDJUP / 2
	local ut = if side > 0 then halvDjup else -halvDjup
	local dx = if along == "X" then 0 else ut
	local dz = if along == "X" then ut else 0
	return base * CFrame.new(
		BK.M * (mx + dx),
		BK.M * (o.z0 + o.h / 2),
		BK.M * (mz + dz))
end

--[[ Returnerar true bara när panelen faktiskt hittades och konfigurerades.
     Förut returnerade den ingenting och anroparen räknade upp ändå, så
     räknaren visade antalet öppningar i datan — inte antalet dörrar som blev
     dörrar. Ett bygge där varenda panel saknades skrev alltså samma rad som
     ett bygge där allt gick rätt. ]]
local function configureDoor(BK, GEO, WG, model: Model, base: CFrame, b, o, index: number): boolean
	if WG.arFonster(o.typ) then return false end
	local door = findExistingDoor(model, b, index)
	if not door then
		warn(string.format("[WorldBuild] Hittar inte dörrpanelen %s/#%d/%s",
			b.id, index, tostring(o.typ)))
		return false
	end

	local _, _, along, side = GEO.oppningsHorn(b.rekt, o.sida, o.u, o.b)

	--[[ Bladet flyttas till det läge öppningen säger, i stället för att dess
	     eget nuvarande läge blir sanningen. Hål och blad delar därmed EN
	     transformkälla: byggnadens oppningar-post. ]]
	local closed = stangdCFrame(BK, GEO, base, b, o)
	door.CFrame = closed

	local mode = if string.sub(o.typ, 1, 4) == "port" then "slide" else "swing"
	local opened: CFrame

	if mode == "slide" then
		local extra = BK.M * 0.25
		if along == "X" then
			opened = closed * CFrame.new(door.Size.X + extra, 0, 0)
		else
			opened = closed * CFrame.new(0, 0, door.Size.Z + extra)
		end
	else
		local sign = if side > 0 then 1 else -1
		if along == "X" then
			local hinge = closed * CFrame.new(-door.Size.X / 2, 0, 0)
			opened = hinge * CFrame.Angles(0, math.rad(90 * sign), 0)
				* CFrame.new(door.Size.X / 2, 0, 0)
		else
			local hinge = closed * CFrame.new(0, 0, -door.Size.Z / 2)
			opened = hinge * CFrame.Angles(0, math.rad(-90 * sign), 0)
				* CFrame.new(0, 0, door.Size.Z / 2)
		end
	end

	door.Anchored = true
	door.CanCollide = true
	door:SetAttribute("UBRFDoor", true)
	door:SetAttribute("DoorMode", mode)
	door:SetAttribute("DoorClosedCFrame", closed)
	door:SetAttribute("DoorOpenCFrame", opened)
	door:SetAttribute("DoorOpen", false)
	door:SetAttribute("BuildingId", b.id)
	door:SetAttribute("OpeningId", index)
	door:SetAttribute("OpeningType", o.typ)

	local prompt = door:FindFirstChild("DoorPrompt")
	if not (prompt and prompt.ClassName == "ProximityPrompt") then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "DoorPrompt"
		prompt.Parent = door
	end
	local doorPrompt = prompt :: ProximityPrompt
	doorPrompt.ActionText = "Öppna"
	doorPrompt.ObjectText = o.label or (if mode == "slide" then "Port" else "Dörr")
	doorPrompt.HoldDuration = 0
	doorPrompt.MaxActivationDistance = 10
	doorPrompt.RequiresLineOfSight = false
	return true
end

local function buildSpawn(BK, WG, model: Model, base: CFrame, G)
	local old = model:FindFirstChild("UBRFSpawn")
	if old then old:Destroy() end

	-- Ingen literal här: marginalen ligger i WorldGeometry.SPAWN_MARGIN.
	local sx, sz, tx, tz = WG.ankomstSpawn(G.byggnader)
	local from = base * CFrame.new(BK.M * sx, 0.2, BK.M * sz)
	local target = base * CFrame.new(BK.M * tx, 0.2, BK.M * tz)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "UBRFSpawn"
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.CFrame = CFrame.lookAt(from.Position, target.Position)
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.Transparency = 1
	spawn.Neutral = true
	spawn.Enabled = true
	spawn.AllowTeamChangeOnTouch = false
	spawn:SetAttribute("UBRFManagedSpawn", true)
	spawn.Parent = model
	return spawn
end

function WorldBuild.apply(BK, G, GEO, WG)
	local folder = workspace:FindFirstChild("Anläggning")
	local model = folder and folder:FindFirstChild("UBRF")
	if not (model and model.ClassName == "Model" and model.PrimaryPart) then
		warn("[WorldBuild] UBRF-modellen saknas — kör Anlaggningen först.")
		return false
	end
	local worldModel = model :: Model
	local base = (worldModel.PrimaryPart :: BasePart).CFrame

	for _, b in ipairs(G.byggnader) do
		for _, sida in ipairs({ "S", "N", "W", "E" }) do
			replaceFacade(BK, WG, worldModel, base, b, sida)
		end
	end

	local vantade, byggda = 0, 0
	for _, b in ipairs(G.byggnader) do
		for index, o in ipairs(b.oppningar or {}) do
			if not WG.arFonster(o.typ) then
				vantade += 1
				if configureDoor(BK, GEO, WG, worldModel, base, b, o, index) then
					byggda += 1
				end
			end
		end
	end

	buildSpawn(BK, WG, worldModel, base, G)

	--[[ Servern jämför mot det här i stället för mot en siffra den själv
	     hittar på. Skiljer sig bundna dörrar från byggda vet man direkt att
	     felet ligger mellan bygget och servern, inte i någondera. ]]
	worldModel:SetAttribute("DoorsBuilt", byggda)

	print(string.format("[WorldBuild] Spelbar värld: %d/%d dörr-/portöppningar + UBRFSpawn",
		byggda, vantade))
	if byggda < vantade then
		warn(string.format(
			"[WorldBuild] %d dörrpaneler hittades INTE och blev aldrig dörrar. "
			.. "Se raderna ovan för vilka.", vantade - byggda))
	end
	return true
end

return WorldBuild
