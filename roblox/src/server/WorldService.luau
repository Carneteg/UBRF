--!strict
--[[
	WorldService — spelbar anläggning: dörrar och startposition.

	Byggpaketet skapar dörrpanelerna och lagrar stängd/öppen CFrame som
	attribut. Servern äger själva togglingen så alla spelare ser samma dörrläge.

	UBRFSpawn är också byggd ur anläggningsgeometrin. CharacterAdded flyttas dit
	för att en gammal/default SpawnLocation långt från UBRF inte ska vinna.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local WorldService = {}

local boundDoors: { [BasePart]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local busy: { [BasePart]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local function updatePrompt(door: BasePart)
	local prompt = door:FindFirstChild("DoorPrompt")
	if prompt and prompt:IsA("ProximityPrompt") then
		prompt.ActionText = if door:GetAttribute("DoorOpen") == true then "Stäng" else "Öppna"
	end
end

local function setupDoor(inst: Instance)
	if not inst:IsA("BasePart") or inst:GetAttribute("UBRFDoor") ~= true then return end
	local door = inst :: BasePart
	if boundDoors[door] then return end

	local closed = door:GetAttribute("DoorClosedCFrame")
	local opened = door:GetAttribute("DoorOpenCFrame")
	if typeof(closed) ~= "CFrame" or typeof(opened) ~= "CFrame" then
		warn("[World] Dörr saknar giltiga CFrame-attribut: " .. door:GetFullName())
		return
	end

	local prompt = door:FindFirstChild("DoorPrompt")
	if not (prompt and prompt:IsA("ProximityPrompt")) then
		warn("[World] Dörr saknar DoorPrompt: " .. door:GetFullName())
		return
	end

	boundDoors[door] = true
	updatePrompt(door)

	prompt.Triggered:Connect(function(_player)
		if busy[door] or not door.Parent then return end
		busy[door] = true

		local isOpen = door:GetAttribute("DoorOpen") == true
		local target = if isOpen then closed else opened
		local mode = door:GetAttribute("DoorMode")
		local duration = if mode == "slide" then 0.70 else 0.42

		-- Under rörelsen ska dörrbladet inte kunna slå fast en avatar i en vägg.
		door.CanCollide = false
		local tween = TweenService:Create(
			door,
			TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ CFrame = target }
		)
		tween:Play()
		tween.Completed:Wait()

		local nowOpen = not isOpen
		door:SetAttribute("DoorOpen", nowOpen)
		-- I slutläget ligger panelen utanför själva passageöppningen och får vara
		-- fysisk igen. Det ger en riktig dörr, inte en genomskinlig kuliss.
		door.CanCollide = true
		updatePrompt(door)
		busy[door] = nil
	end)
end

local function findSpawn(): SpawnLocation?
	local folder = workspace:FindFirstChild("Anläggning")
	local model = folder and folder:FindFirstChild("UBRF")
	local spawn = model and model:FindFirstChild("UBRFSpawn")
	return if spawn and spawn:IsA("SpawnLocation") then spawn else nil
end

local function placeCharacter(character: Model)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not (root and root:IsA("BasePart")) then return end

	local spawn = findSpawn()
	if not spawn then
		-- Byggpaketet kan komma in någon bildruta efter spelaren i Studio.
		for _ = 1, 50 do
			task.wait(0.1)
			spawn = findSpawn()
			if spawn then break end
		end
	end
	if not spawn then
		warn("[World] UBRFSpawn saknas — lämnar Roblox standardspawn orörd.")
		return
	end

	character:PivotTo(spawn.CFrame * CFrame.new(0, 3.5, 0))
end

local function setupPlayer(player: Player)
	player.CharacterAdded:Connect(function(character)
		task.defer(placeCharacter, character)
	end)
	if player.Character then task.defer(placeCharacter, player.Character) end
end

function WorldService.start()
	for _, inst in ipairs(workspace:GetDescendants()) do
		setupDoor(inst)
	end
	workspace.DescendantAdded:Connect(function(inst)
		setupDoor(inst)
		if inst:IsA("SpawnLocation") and inst.Name == "UBRFSpawn" then
			-- Om världen byggs efter att Play redan startat flyttas befintliga
			-- avatarer till den nya korrekta ankomsten en gång.
			for _, player in ipairs(Players:GetPlayers()) do
				if player.Character then task.defer(placeCharacter, player.Character) end
			end
		end
	end)

	for _, player in ipairs(Players:GetPlayers()) do setupPlayer(player) end
	Players.PlayerAdded:Connect(setupPlayer)
	print("[World] Dörrar + UBRFSpawn igång")
end

return WorldService
