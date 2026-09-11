--!strict
-- BuildKit: små, förutsägbara byggstenar för UBRF-byggnader.
-- Alla mått i METER. 1 m = 3 studs. Origo för en byggnad = SV-hörnet på marknivå.
-- Körs i Studio via MCP run_code; klistras in före byggnadsskriptet (eller lagras som ModuleScript i ServerStorage.BuildKit).

local BuildKit = {}
BuildKit.M = 3 -- studs per meter

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

--[[ ══ SPEGLINGEN — SITE-KARTAN BLIR EN VÄRLD ═══════════════════════════

	Tobias fysiska Studio-test: interiörerna såg spegelvända ut. De var
	det, och mer än så — HELA världen var speglad, på båda plattformarna.

	`src/site.js` rad 3: "origo i sydväst, +x öster, +y norr". Det är en
	KARTA. Roblox är högerhänt med Y uppåt och −Z framåt. Mappar man
	site-y rakt på +Z vänder man kartan:

	    höger = blick × upp
	    ser man söderut (blick = −Z) blir höger = +X = ÖSTER
	    men på en karta har man VÄSTER till höger när man ser söderut

	Ingen rotation lagar det — rotationer bevarar handighet. Bara en
	reflektion vänder den, och den kanoniska mappningen från en karta till
	en Y-upp-värld är norr = −Z.

	VARFÖR ETT EFTERPASS OCH INTE EN RAD I `box`. Världen byggs inte bara
	av `box`: det finns takvinklar, egna `CFrame.Angles`, dörrblad som
	svänger och en spawn som ser mot en dörr. Ett teckenbyte per ställe
	hade blivit ett trettiotal chanser att missa ett. Reflektionen görs
	därför EN gång, på den färdiga modellen, som en riktig
	koordinattransform:

	    läge       (x, y, z) → (x, y, D − z)
	    rotation   R → M R M   med M = diag(1, 1, −1)

	Konjugeringen är återigen en ROTATION (det(M R M) = det R = 1), så
	svängda delar följer med korrekt i stället för att bli inverterade.

	`D` är tomtens djup i studs. Reflektionen sker alltså om tomtens mitt,
	vilket håller världen kvar i samma positiva ruta — allt som råkar anta
	positiva koordinater fungerar som förut. ]]
function BuildKit.speglaCF(cf: CFrame, djupStuds: number): CFrame
	local p = cf.Position
	local nz = djupStuds - p.Z
	--[[ Riktiga Roblox-CFrames bär hela rotationsmatrisen. Byggbänkens
		stubbe bär bara position och yaw — och för en Z-spegling blir en
		Y-rotation helt enkelt negerad, vilket är precis vad den grenen
		gör. Båda vägarna uttrycker samma transform. ]]
	local ok, komp = pcall(function() return { cf:GetComponents() } end)
	if ok and komp and #komp >= 12 then
		local r00, r01, r02 = komp[4], komp[5], komp[6]
		local r10, r11, r12 = komp[7], komp[8], komp[9]
		local r20, r21, r22 = komp[10], komp[11], komp[12]
		return CFrame.new(p.X, p.Y, nz,
			r00, r01, -r02,
			r10, r11, -r12,
			-r20, -r21, r22)
	end
	return CFrame.new(Vector3.new(p.X, p.Y, nz))
		* CFrame.Angles(0, -((cf :: any).Yaw or 0), 0)
end

--[[ Speglar en färdigbyggd modell. Storlekar rörs inte: de är mått i
	delens eget system och en reflektion ändrar dem inte.

	KILEN ÄR UNDANTAGET, och det är inte en detalj. En `Part` är
	symmetrisk kring sitt eget Z-plan, så att sätta den speglade
	rotationen räcker. En `WedgePart` är det INTE: den är ett triangulärt
	prisma med sluttningen längs sin lokala Z. Konjugeringen M R M ovan
	placerar kilen som om formen också vore spegelvänd, men formen följer
	inte med — takets gavelspetsar hade pekat åt fel håll.

	Kilen är däremot symmetrisk kring sitt lokala X-plan, och för en sådan
	form är en Z-spegling samma sak som ett halvt varv kring Y:

	    (x, y, z) → (x, y, −z)   är för en X-symmetrisk form
	    (x, y, z) → (−x, y, −z)  sett som mängd

	Därför får kilen ett extra yaw på π, och då stämmer geometrin exakt. ]]
function BuildKit.speglaModell(model: Model, djupMeter: number): number
	local djupStuds = djupMeter * BuildKit.M
	local n = 0
	for _, d in ipairs(model:GetDescendants()) do
		if d.CFrame ~= nil and d.Size ~= nil then
			local cf = BuildKit.speglaCF(d.CFrame, djupStuds)
			if d.ClassName == "WedgePart" then
				cf = cf * CFrame.Angles(0, math.pi, 0)
			end
			d.CFrame = cf
			n += 1
		end
	end
	return n
end

--[[ ══ TOMTEN SEDD FRÅN DEN VÄNDA VÄRLDEN ═══════════════════════════════

	Allt som placeras EFTER bygget — boxmarkören, hästen, kamerorna — ligger
	relativt komplexets `PrimaryPart`. Den delen speglas med resten, och
	DÄRFÖR blir omräkningen en enda teckenändring, oavsett var på kartan
	anläggningen står och hur den är vriden:

	    en punkt låg på  bas * (x, h, y)
	    efter speglingen S ligger den på  S(bas * (x, h, y))
	                                    = (S·bas) * K * (x, h, y)
	    med K = diag(1, 1, −1), alltså  bas' * (x, h, −y)

	`bas'` är den speglade `PrimaryPart`. Site-koordinaten är alltså
	oförändrad — det är BARA tecknet på nord-axeln som vänder. Det är hela
	handighetsbytet, uttryckt en gång.

	Site-kanon (`references/SITEPLAN.md`, `src/site.js`) rörs inte: den
	fortsätter ha +y norr. Kartan är facit; världen är dess högerhänta
	avbild. ]]
function BuildKit.tomtlage(xSite: number, hojd: number, ySite: number): CFrame
	return CFrame.new(xSite * BuildKit.M, hojd * BuildKit.M, -ySite * BuildKit.M)
end

--[[ Vägen tillbaka: en världspunkt → site-koordinater i meter. Används av
	proven, som mäter det BYGGDA och måste kunna jämföra med kartan.
	Anläggningen byggs orotterad (rotY = 0 i `newBuilding`-anropet), så
	basen bidrar med en ren förskjutning. ]]
function BuildKit.tomtkoord(bas: CFrame, p: Vector3): (number, number)
	local b = bas.Position
	return (p.X - b.X) / BuildKit.M, -(p.Z - b.Z) / BuildKit.M
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
	local depth = 0.06
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
function BuildKit.cameraLike(base: CFrame, x: number, z: number, tx: number, tz: number, eyeH: number?, aimH: number?)
	local cam = workspace.CurrentCamera
	--[[ Kamerorna ställs EFTER att världen vänts, och `tomtlage` är den
		enda omräkningen från karta till vänd värld. Att låta kameran
		räkna själv hade gjort varje vy till ett eget tillfälle att missa
		tecknet — och en vy som tittar åt fel håll ser ut som en byggfel
		i stället för som ett kamerafel. ]]
	local from = base * BuildKit.tomtlage(x, eyeH or 1.6, z)
	local to = base * BuildKit.tomtlage(tx, aimH or 2.5, tz)
	cam.CameraType = Enum.CameraType.Scriptable
	cam.CFrame = CFrame.lookAt(from.Position, to.Position)
end

return BuildKit
