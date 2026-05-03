local RunService = game:GetService("RunService")

return function(id: string, api): ()
	api.structure:whenPlaced(function(info): ()
		if info.id ~= id then
			return
		end

		local touchingParts = workspace:GetPartsInPart(info.model.PrimaryPart)
		local isTouching = false
		local observedRPMs: { [number]: boolean } = {}
		local rpm: number
		for _, part in touchingParts do
			if not part:HasTag("RotationSource") then
				continue
			end
			isTouching = true

			rpm = part:GetAttribute("RPM")
			if observedRPMs[rpm] then
				error("invalid connection, undefined behavior rn")
			end

			observedRPMs[rpm] = true
		end

		local cframe = info.model:GetPivot()
		local rotation = 0
		RunService.Heartbeat:Connect(function(dt)
			if not isTouching then
				return
			end

			local rotationCFrame = CFrame.Angles(0, 0, math.rad(rotation))
			local newCFrame = cframe * rotationCFrame
			info.model:PivotTo(newCFrame)
			rotation += 6 * rpm * dt
		end)
	end)
end
