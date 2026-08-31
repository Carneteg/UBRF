--!strict
-- BuildKit: små, förutsägbara byggstenar för UBRF-byggnader.
-- Alla mått i METER. 1 m = 3 studs. Origo för en byggnad = SV-hörnet på marknivå.
-- Körs i Studio via MCP run_code; klistras in före byggnadsskriptet (eller lagras som ModuleScript i ServerStorage.BuildKit).

local BuildKit = {}
BuildKit.M = 3 -- studs per meter

--[[ Hur tjock en dörr-/fönsterpanel är. Den låg som en literal inne i
     opening(), men WorldBuild behöver samma tal för att kunna räkna ut var det
     stängda dörrbladet ska stå. Två kopior av det hade betytt att bladet en dag
     hamnar bredvid sitt eget hål. ]]
BuildKit.OPPNINGSDJUP = 0.06

local function studs(m: number): number return m * BuildKit.M end

local function newPart(model: Model, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = model
	return p
end

-- Skapar/ersätter modellen. origin = världsposition för SV-hörnet (studs), rotY i grader.
function BuildKit.newBuilding(name: string, origin: Vector3, rotY: number?, meta: {[string]: any}?): (Model, CFrame)
	local folder = workspace:FindFirstChild("Anläggning") or Instance.new("Folder")
	folder.Name = "Anläggning"; folder.Parent = workspace
	local old = folder:FindFirstChild(name); if old then old:Destroy() end
	local model = Instance.new("Model"); model.Name = name; model.Parent = folder
	local root = newPart(model, "Root", Vector3.new(1, 0.2, 1), CFrame.new(origin) * CFrame.Angles(0, math.rad(rotY or 0), 0), Color3.new(1,1,1))
	root.Transparency = 1; root.CanCollide = false
	model.PrimaryPart = root
	for k, v in pairs(meta or {}) do model:SetAttribute(k, v) end
	return model, root.CFrame
end

-- Box i lokala meter-koordinater: x,z = SV-hörn, y = golvnivå; w=bredd(X), h=höjd(Y), d=djup(Z)
function BuildKit.box(model: Model, base: CFrame, name: string, x: number, y: number, z: number, w: number, h: number, d: number, color: Color3, material: Enum.Material?): Part
	local size = Vector3.new(studs(w), studs(h), studs(d))
	local cf = base * CFrame.new(studs(x + w/2), studs(y + h/2), studs(z + d/2))
	return newPart(model, name, size, cf, color, material)
end

-- Vägg längs X (facing = "S"/"N") eller längs Z ("W"/"E"). t = tjocklek.
function BuildKit.wall(model: Model, base: CFrame, name: string, x: number, z: number, length: number, height: number, t: number, along: "X"|"Z", color: Color3, material: Enum.Material?): Part
	if along == "X" then
		return BuildKit.box(model, base, name, x, 0, z, length, height, t, color, material)
	else
		return BuildKit.box(model, base, name, x, 0, z, t, height, length, color, material)
	end
end

-- Hål i vägg (fönster/dörr) görs enklast genom att lägga en Part med annan färg "utanpå" väggen: tydligt i tecknad stil.
-- x,z = position längs väggen (m), sill = höjd över mark, w,h = storlek, depth = hur mycket den sticker ut.
function BuildKit.opening(model: Model, base: CFrame, name: string, x: number, z: number, sill: number, w: number, h: number, along: "X"|"Z", side: number, color: Color3, material: Enum.Material?): Part
	local depth = BuildKit.OPPNINGSDJUP
	if along == "X" then
		return BuildKit.box(model, base, name, x, sill, z + (side > 0 and 0 or -depth), w, h, depth, color, material or Enum.Material.Glass)
	else
		return BuildKit.box(model, base, name, x + (side > 0 and 0 or -depth), sill, z, depth, h, w, color, material or Enum.Material.Glass)
	end
end

function BuildKit.window(model: Model, base: CFrame, x: number, z: number, sill: number, w: number, h: number, along: "X"|"Z", side: number, frameColor: Color3)
	local frame = BuildKit.opening(model, base, "Fönsterkarm", x - 0.08, z, sill - 0.08, w + 0.16, h + 0.16, along, side, frameColor, Enum.Material.SmoothPlastic)
	local glass = BuildKit.opening(model, base, "Glas", x, z, sill, w, h, along, side * 2, Color3.fromRGB(170, 205, 225), Enum.Material.Glass)
	glass.Transparency = 0.3
end

function BuildKit.door(model: Model, base: CFrame, name: string, x: number, z: number, w: number, h: number, along: "X"|"Z", side: number, color: Color3)
	return BuildKit.opening(model, base, name, x, z, 0, w, h, along, side, color, Enum.Material.SmoothPlastic)
end

-- Sadeltak över fotavtryck (x,z,w,d) med takfot på höjd eaveH, lutning pitchDeg, nock längs "X" eller "Z", överhäng i meter.
function BuildKit.gableRoof(model: Model, base: CFrame, x: number, z: number, w: number, d: number, eaveH: number, pitchDeg: number, ridgeAlong: "X"|"Z", overhang: number, color: Color3, material: Enum.Material?)
	local span = (ridgeAlong == "X") and d or w   -- spännvidd tvärs nocken
	local len  = (ridgeAlong == "X") and w or d   -- längd längs nocken
	local half = span / 2 + overhang
	local rise = half * math.tan(math.rad(pitchDeg))
	local thick = 0.15
	local slope = math.sqrt(half*half + rise*rise)
	local cx, cz = x + w/2, z + d/2
	for _, s in ipairs({ -1, 1 }) do
		local p = Instance.new("Part")
		p.Name = "Takfall"; p.Anchored = true
		-- Identiteten sätts när delen byggs, aldrig gissad på namn efteråt.
		-- F02:s dollhouse gömmer allt med TakDel.
		p:SetAttribute("TakDel", true)
		p.Color = color; p.Material = material or Enum.Material.SmoothPlastic
		p.Size = Vector3.new(studs(len + 2*overhang), studs(thick), studs(slope))
		local rot = (ridgeAlong == "X") and CFrame.Angles(math.rad(pitchDeg) * -s, 0, 0)
			or CFrame.Angles(0, math.rad(90), 0) * CFrame.Angles(math.rad(pitchDeg) * -s, 0, 0)
		local offX = (ridgeAlong == "X") and 0 or s * half / 2
		local offZ = (ridgeAlong == "X") and s * half / 2 or 0
		p.CFrame = base * CFrame.new(studs(cx + offX), studs(eaveH + rise/2), studs(cz + offZ)) * rot
		p.Parent = model
	end
	-- Gavelspetsar (triangel av två WedgeParts)
	local function gable(pos: number)
		for _, s in ipairs({ -1, 1 }) do
			local wdg = Instance.new("WedgePart")
			wdg.Name = "Gavelspets"; wdg.Anchored = true
			wdg.Color = model:GetAttribute("GavelFarg") or color
			wdg.Material = Enum.Material.SmoothPlastic
			wdg.Size = Vector3.new(studs(0.2), studs(rise - overhang * math.tan(math.rad(pitchDeg))), studs(span/2))
			local yaw = (ridgeAlong == "X") and (s > 0 and 0 or math.rad(180)) or (s > 0 and math.rad(90) or math.rad(-90))
			local lx = (ridgeAlong == "X") and pos or cx + s * span/4
			local lz = (ridgeAlong == "X") and cz + s * span/4 or pos
			wdg.CFrame = base * CFrame.new(studs(lx), studs(eaveH + wdg.Size.Y/BuildKit.M/2), studs(lz)) * CFrame.Angles(0, yaw, 0)
			wdg.Parent = model
		end
	end
	if ridgeAlong == "X" then gable(x + 0.1); gable(x + w - 0.1) else gable(z + 0.1); gable(z + d - 0.1) end
	return rise
end

-- Staket: stolpar + två reglar mellan punkterna (lokala meter).
function BuildKit.fence(model: Model, base: CFrame, x1: number, z1: number, x2: number, z2: number, height: number, color: Color3)
	local dx, dz = x2 - x1, z2 - z1
	local len = math.sqrt(dx*dx + dz*dz)
	local n = math.max(1, math.floor(len / 2.5))
	local yaw = math.atan2(-dz, dx)
	for i = 0, n do
		local t = i / n
		BuildKit.box(model, base, "Stolpe", x1 + dx*t - 0.06, 0, z1 + dz*t - 0.06, 0.12, height, 0.12, color, Enum.Material.Wood)
	end
	for _, hy in ipairs({ height * 0.55, height * 0.95 }) do
		local p = Instance.new("Part"); p.Name = "Regel"; p.Anchored = true; p.Color = color; p.Material = Enum.Material.Wood
		p.Size = Vector3.new(studs(len), studs(0.1), studs(0.05))
		p.CFrame = base * CFrame.new(studs(x1 + dx/2), studs(hy), studs(z1 + dz/2)) * CFrame.Angles(0, yaw, 0)
		p.Parent = model
	end
end

-- Sätter Studio-kameran i ögonhöjd på ett sätt som matchar ett foto: stå på (x,z) i lokala meter, titta mot (tx,tz).
--[[ Siktmalet lag forut fast pa 2.5 m. Det gor det omojligt att titta UPP,
	och takstommen i ridhuset gar bara att bedoma underifran. aimH ar darfor
	valbar; utan den beter sig anropet exakt som forut. ]]
--[[ Flytta kameran, eller SÄG att det inte gick — flytta den aldrig halvvägs.

     I Studio 2026-08-31 stod QA-panelen och påstod en vy medan viewporten låg
     kvar i den förra. Kamerafel ska därför vara fel som hörs, inte tystnad:
     saknas kameran, eller är någon punkt icke-finit, eller sammanfaller
     från och mot (lookAt är odefinierad då), kastas ett fel med de faktiska
     talen i, så att nästa rapport innehåller siffrorna i stället för "tom vy". ]]
function BuildKit.cameraLike(base: CFrame, x: number, z: number, tx: number, tz: number, eyeH: number?, aimH: number?)
	local cam = workspace.CurrentCamera
	if not cam then
		error("cameraLike: ingen workspace.CurrentCamera — kameran kan inte flyttas")
	end
	local from = (base * CFrame.new(studs(x), studs(eyeH or 1.6), studs(z))).Position
	local to = (base * CFrame.new(studs(tx), studs(aimH or 2.5), studs(tz))).Position

	local function andlig(p): boolean
		-- NaN är olikt sig självt; oändligheter fångas av jämförelsen mot huge.
		return p.X == p.X and p.Y == p.Y and p.Z == p.Z
			and math.abs(p.X) < math.huge and math.abs(p.Y) < math.huge and math.abs(p.Z) < math.huge
	end
	local beskrivning = string.format(
		"från (%.1f, %.1f, %.1f) mot (%.1f, %.1f, %.1f), bas (%.1f, %.1f, %.1f)",
		from.X, from.Y, from.Z, to.X, to.Y, to.Z,
		base.Position.X, base.Position.Y, base.Position.Z)
	if not (andlig(from) and andlig(to)) then
		error("cameraLike: icke-finit kameraposition — " .. beskrivning)
	end
	local dx, dy, dz = to.X - from.X, to.Y - from.Y, to.Z - from.Z
	if dx * dx + dy * dy + dz * dz < 0.0001 then
		error("cameraLike: från och mot sammanfaller, lookAt är odefinierad — " .. beskrivning)
	end

	print("[Kamera] " .. beskrivning)
	cam.CameraType = Enum.CameraType.Scriptable
	cam.CFrame = CFrame.lookAt(from, to)
end

return BuildKit
