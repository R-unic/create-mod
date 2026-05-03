local RPM = 4
local DEGREES_PER_SECOND = 6 * RPM
local STRESS_CAPACITY = 64 * RPM

local RunService = game:GetService("RunService")

return function(id: string, api): ()
	api.structure:whenPlaced(function(info): ()
		if info.id ~= id then
			return
		end

		local source = info.model.PrimaryPart
		local cframe = info.model:GetPivot()
		local rotation = 0
		source:SetAttribute("RPM", RPM)
		RunService.Heartbeat:Connect(function(dt)
			local rotationCFrame = CFrame.Angles(0, 0, math.rad(rotation))
			local newCFrame = cframe * rotationCFrame
			info.model:PivotTo(newCFrame)
			rotation += DEGREES_PER_SECOND * dt
		end)
	end)
end
