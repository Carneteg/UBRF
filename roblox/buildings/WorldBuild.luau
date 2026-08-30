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

local function arFonster(typ: string): boolean
	return typ == "fonster" or typ == "rund" or typ == "valv"
end

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

local function segmentBox(BK, model: Model, base: CFrame, b, sida: string, seg, color: Color3, material: Enum.Material)
	local r = b.rekt
	local len = seg.s1 - seg.s0
	local h = seg.y1 - seg.y0
	local t = 0.3
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

	local openings = openingsForSide(b, sida)
	local segments = WG.fasadBitar(facadeLength(b.rekt, sida), b.hV, openings)
	for _, seg in ipairs(segments) do
		segmentBox(BK, model, base, b, sida, seg, color, material)
	end
end

local function expectedOpeningPosition(BK, GEO, base: CFrame, b, o): Vector3
	local mx, mz = GEO.oppningsMitt(b.rekt, o.sida, o.u, o.b)
	return (base * CFrame.new(BK.M * mx, BK.M * (o.z0 + o.h / 2), BK.M * mz)).Position
end

local function findExistingDoor(BK, GEO, model: Model, base: CFrame, b, o, used): BasePart?
	local wantedName = (o.label or o.typ) .. (if o.intern then " (intern)" else "")
	local wanted = expectedOpeningPosition(BK, GEO, base, b, o)
	local best: BasePart? = nil
	local bestDist2 = math.huge
	for _, inst in ipairs(model:GetDescendants()) do
		if inst.ClassName == "Part" and inst.Name == wantedName and not used[inst] then
			local part = inst :: Part
			local d = part.CFrame.Position - wanted
			local dist2 = d.X * d.X + d.Y * d.Y + d.Z * d.Z
			if dist2 < bestDist2 then
				best = part
				bestDist2 = dist2
			end
		end
	end
	if best then used[best] = true end
	return best
end

local function configureDoor(BK, GEO, model: Model, base: CFrame, b, o, used)
	if arFonster(o.typ) then return end
	local door = findExistingDoor(BK, GEO, model, base, b, o, used)
	if not door then
		warn(string.format("[WorldBuild] Hittar inte dörrpanelen %s/%s/%s",
			b.id, tostring(o.sida), tostring(o.typ)))
		return
	end

	local _, _, along, side = GEO.oppningsHorn(b.rekt, o.sida, o.u, o.b)
	local closed = door.CFrame
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
end

local function buildSpawn(BK, WG, model: Model, base: CFrame, G)
	local old = model:FindFirstChild("UBRFSpawn")
	if old then old:Destroy() end

	local sx, sz, tx, tz = WG.ankomstSpawn(G.byggnader, 4)
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

	local used = {}
	local doorCount = 0
	for _, b in ipairs(G.byggnader) do
		for _, o in ipairs(b.oppningar or {}) do
			if not arFonster(o.typ) then
				configureDoor(BK, GEO, worldModel, base, b, o, used)
				doorCount += 1
			end
		end
	end

	buildSpawn(BK, WG, worldModel, base, G)
	print(string.format("[WorldBuild] Spelbar värld: %d dörr-/portöppningar + UBRFSpawn", doorCount))
	return true
end

return WorldBuild
