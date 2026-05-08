local RunService = game:GetService("RunService")

local Shaft = {}
Shaft.__index = Shaft

type Shaft = {
	read model: Model,
	read root: BasePart,
	read raycastParams: RaycastParams,
	read baseCFrame: CFrame,
	rotation: number,
	rpm: number,
} & typeof(setmetatable({}, Shaft))

local function createShaft(model: Model): ()
	local raycastParams = RaycastParams.new()
	raycastParams.ExcludeInstances = { model }
	raycastParams.IgnoreWater = true

	local self = setmetatable({
		model = model,
		root = model.PrimaryPart,
		raycastParams = raycastParams,
		baseCFrame = model:GetPivot(),
		rotation = 0,
		rpm = 0,
	}, Shaft)
	RunService.Heartbeat:Connect(function(dt): ()
		self:update(dt)
	end)
end

function Shaft.getConnected(self: Shaft): { BasePart }
	local origin = self.root.Position
	local lookVector = self.root.CFrame.lookVector
	local distance = self.root.Size.Z / 2 + 0.005
	local rayAhead = workspace:Raycast(origin, lookVector * distance, self.raycastParams)
	local rayBehind = workspace:Raycast(origin, lookVector * -distance, self.raycastParams)
	local connected = {}

	if rayAhead then
		table.insert(connected, rayAhead.Instance)
	end
	if rayBehind then
		table.insert(connected, rayBehind.Instance)
	end

	return connected
end

function Shaft.update(self: Shaft, dt: number): ()
	local touchingSources = self:getConnected()
	local isTouching = false
	local observedRPMs: { [number]: boolean } = {}
	local rpm: number
	local inheritedRotation: number
	for _, source in touchingSources do
		if not source:HasTag("RotationSource") then
			continue
		end

		isTouching = true
		inheritedRotation = source.Orientation.Z
		rpm = source:GetAttribute("RPM")
		if rpm and observedRPMs[rpm] then
			error("invalid connection, undefined behavior currently")
		end

		observedRPMs[rpm] = true
	end

	if not isTouching then
		return self:setRPM(0)
	end

	self.rotation = inheritedRotation
	self:setRPM(rpm)
	self:transferRotation(dt)
	return
end

function Shaft.transferRotation(self: Shaft, dt: number): ()
	local rotationCFrame = CFrame.Angles(0, 0, math.rad(self.rotation))
	local newCFrame = self.baseCFrame * rotationCFrame
	self.model:PivotTo(newCFrame)
	self.rotation += 6 * self.rpm * dt
end

function Shaft.setRPM(self: Shaft, rpm: number): ()
	self.rpm = rpm
	self.root:SetAttribute("RPM", rpm)
end

return function(id: string, api): ()
	api.structure:whenPlaced(function(info): ()
		if info.id ~= id then
			return
		end

		createShaft(info.model)
	end)
end
