local RunService = game:GetService("RunService")

local Shaft = {}
Shaft.__index = Shaft

type Shaft = {
	read model: Model,
	read root: BasePart,
	read baseCFrame: CFrame,
	rotation: number,
	rpm: number,
} & typeof(setmetatable({}, Shaft))

local function createShaft(model: Model): ()
	local self = setmetatable({
		model = model,
		root = model.PrimaryPart,
		baseCFrame = model:GetPivot(),
		rotation = 0,
		rpm = 0,
	}, Shaft)
	RunService.Heartbeat:Connect(function(dt): ()
		self:update(dt)
	end)
end

local overlapParams = OverlapParams.new()
overlapParams.IncludeInstances = { workspace.StackableStructures } -- definitely temporary

function Shaft.update(self: Shaft, dt: number): ()
	local touchingParts = workspace:GetPartsInPart(self.root)
	local isTouching = false
	local observedRPMs: { [number]: boolean } = {}
	local rpm: number
	local inheritedRotation: number
	for _, part in touchingParts do
		if not part:HasTag("RotationSource") then
			continue
		end

		isTouching = true
		inheritedRotation = part.Orientation.Z
		rpm = part:GetAttribute("RPM")
		if observedRPMs[rpm] then
			error("invalid connection, undefined behavior currently")
		end

		observedRPMs[rpm] = true
	end

	if not isTouching then
		return
	end
	self.rpm = rpm
	self.rotation = inheritedRotation
	self.root:SetAttribute("RPM", rpm)
	self:transferRotation(dt)
end

function Shaft.transferRotation(self: Shaft, dt: number): ()
	local rotationCFrame = CFrame.Angles(0, 0, math.rad(self.rotation))
	local newCFrame = self.baseCFrame * rotationCFrame
	self.model:PivotTo(newCFrame)
	self.rotation += 6 * self.rpm * dt
end

return function(id: string, api): ()
	api.structure:whenPlaced(function(info): ()
		if info.id ~= id then
			return
		end

		createShaft(info.model)
	end)
end
