--!strict
--[[
	Riggadaptern — den enda plats som vet hur en hästmodell ser ut inuti.

	All annan kod tar emot en Rig och rör aldrig modellen direkt. Det är
	det som gör att hästmodellen går att byta utan att ridlogiken skrivs om.

	Adaptern kräver INTE att en köpt modell döps om. Varje sökt namn kan
	pekas om med ett attribut på modellen, t.ex.

	    Map_Saddle       = "SeatPart"
	    Map_HumanoidRoot = "Body"
	    Map_Head         = "Bone_Head_01"

	Hittas inget alls gissar den på klass och position i stället, och
	rapporterar vad den gissade. Det som saknas rapporteras som fel med
	namn — systemet ska aldrig halvfungera tyst.
]]

local Types = require(script.Parent.Types)

local RigAdapter = {}

--[[ Attachment-punkter. Alla frivilliga utom Saddle. ]]
local ATTACHMENTS = {
	"RiderSeat", "SaddleAttachment", "Saddle",
	"LeftReinAttachment", "RightReinAttachment",
	"LeftStirrupAttachment", "RightStirrupAttachment",
	"LeadRope", "HoofFL", "HoofFR", "HoofRL", "HoofRR",
}

--[[ Ben som koden får röra procedurellt. Alla frivilliga — animationen
     bär rörelsen, de här är bara till för blick, öron och svans. Saknas
     de tappar man polish, inget mer. ]]
local BONES = {
	"Root", "Pelvis", "Spine01", "Spine02", "Chest",
	"Neck01", "Neck02", "Head", "Jaw",
	"TailBase", "Tail01", "Tail02", "Tail03",
	"Mane01", "Mane02", "Mane03", "LeftEar", "RightEar",
}

--[[ Namnet att leta efter: attributet Map_<nyckel> vinner, annars nyckeln. ]]
local function mapped(model: Model, key: string): string
	local override = model:GetAttribute("Map_" .. key)
	if typeof(override) == "string" and override ~= "" then
		return override
	end
	return key
end

local function findByName(model: Model, key: string): Instance?
	return model:FindFirstChild(mapped(model, key), true)
end

--[[ Kroppens kollisionsdel. Aldrig nätet självt: ett skinnat nät har en
     hölje-hitbox som ändrar form med animationen, och då studsar hästen
     mot marken när benen rör sig. ]]
local function resolveRoot(model: Model): BasePart?
	for _, key in { "BodyCollider", "HumanoidRootPart", "Root" } do
		local found = findByName(model, key)
		if found and found:IsA("BasePart") then
			return found
		end
	end
	if model.PrimaryPart then
		return model.PrimaryPart
	end
	-- Sista utväg: största delen som inte är ett skinnat nät.
	local best, bestVolume = nil, 0
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and not (d:IsA("MeshPart") and #d:GetChildren() > 0) then
			local v = d.Size.X * d.Size.Y * d.Size.Z
			if v > bestVolume then best, bestVolume = d, v end
		end
	end
	return best
end

--[[ Bygger en Rig ur en hästmodell. Returnerar nil + skäl om något
     obligatoriskt saknas. ]]
function RigAdapter.build(model: Model): (Types.Rig?, string?)
	if not model:IsA("Model") then
		return nil, "Hästen måste vara en Model"
	end

	local root = resolveRoot(model)
	if not root then
		return nil, "Hittar ingen kroppsdel att räkna som rot. Döp en osynlig "
			.. "låda till BodyCollider, eller sätt Map_BodyCollider på modellen."
	end
	if model.PrimaryPart == nil then
		model.PrimaryPart = root
	end

	--[[ Humanoid ger markkontakt, lutning, trappor och hopp gratis och är
	     därför standardvägen. AnimationController fungerar för animationer
	     men kräver egen fysik, som det här systemet inte levererar. ]]
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local controller = model:FindFirstChildOfClass("AnimationController")
	local host: Instance? = humanoid or controller
	if not host then
		return nil, "Saknar Humanoid (rekommenderat) eller AnimationController"
	end

	local animator = host:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = host
	end

	local attachments: { [string]: Attachment } = {}
	for _, key in ATTACHMENTS do
		local found = findByName(model, key)
		if found and found:IsA("Attachment") then
			attachments[key] = found
		end
	end
	-- Saddle och SaddleAttachment är samma sak; låt båda namnen fungera.
	attachments.Saddle = attachments.Saddle or attachments.SaddleAttachment or attachments.RiderSeat

	local bones: { [string]: Bone } = {}
	for _, key in BONES do
		local found = findByName(model, key)
		if found and found:IsA("Bone") then
			bones[key] = found
		end
	end

	local seatInstance = findByName(model, "RiderSeat")
	local seat: Seat? = if seatInstance and seatInstance:IsA("Seat") then seatInstance else nil

	local rootJoint = findByName(model, "RootJoint")

	return {
		model = model,
		root = root,
		animator = animator :: Animator,
		humanoid = humanoid,
		controller = controller,
		rootJoint = if rootJoint and rootJoint:IsA("Motor6D") then rootJoint else nil,
		seat = seat,
		attachments = attachments,
		bones = bones,
		stats = findByName(model, "HorseStats") :: Configuration?,
		gaitConfig = findByName(model, "GaitConfig") :: Configuration?,
		animConfig = findByName(model, "AnimationConfig") :: Configuration?,
	}, nil
end

--[[ Vad adaptern faktiskt hittade — för /horsedebug och för felsökning när
     en inköpt modell har egna namn. ]]
function RigAdapter.describe(rig: Types.Rig): string
	local a, b = {}, {}
	for name in rig.attachments do table.insert(a, name) end
	for name in rig.bones do table.insert(b, name) end
	table.sort(a); table.sort(b)
	return ("rot=%s  fysik=%s  attachments=[%s]  ben=[%s]"):format(
		rig.root.Name,
		if rig.humanoid then "Humanoid" else "AnimationController",
		table.concat(a, ", "),
		table.concat(b, ", "))
end

--[[ Kroppens lutning — rollen i svängar och nickningen i backar — läggs på
     leden mellan roten och det synliga nätet, aldrig på roten själv. Lutar
     man roten lutar också kollisionen, och markkontakten börjar bråka.
     Saknas leden hoppas lutningen över; hästen rider fortfarande, den lutar
     bara inte. Det är rätt sorts degradering: polish försvinner, spel inte. ]]
function RigAdapter.setBodyTilt(rig: Types.Rig, roll: number, pitch: number)
	local joint = rig.rootJoint
	if not joint then return end
	local base = joint:GetAttribute("BaseC0")
	if base == nil then
		joint:SetAttribute("BaseC0", joint.C0)
		base = joint.C0
	end
	joint.C0 = (base :: CFrame) * CFrame.Angles(pitch, 0, -roll)
end

--[[ Procedurell påbyggnad ovanpå animationen: huvudet vrids något mot
     svängen, svansen följer farten. Skrivs efter att animationen har
     uppdaterat benen, annars skriver klippet över den. Aldrig så mycket
     att den tar över — det här är krydda, inte rörelse. ]]
function RigAdapter.setBoneOffset(rig: Types.Rig, name: string, offset: CFrame)
	local bone = rig.bones[name]
	if not bone then return end
	local base = bone:GetAttribute("BaseTransform")
	if base == nil then
		bone:SetAttribute("BaseTransform", bone.Transform)
		base = bone.Transform
	end
	bone.Transform = (base :: CFrame) * offset
end

function RigAdapter.saddleCFrame(rig: Types.Rig): CFrame
	local a = rig.attachments.Saddle
	if a then return a.WorldCFrame end
	if rig.seat then return rig.seat.CFrame end
	return rig.root.CFrame * CFrame.new(0, 1.6, 0)
end

return RigAdapter
