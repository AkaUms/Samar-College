local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

-- Configuration
local DAY_LENGTH_MINUTES = 5 -- How many real-world minutes a full day lasts

-- Calculating shift per frame
local timeSpeed = 0.05

RunService.Heartbeat:Connect(function(dt)
	-- Advance the clock time based on time passed since last frame (dt)
	Lighting.ClockTime = Lighting.ClockTime + (timeSpeed * dt)

	-- Reset the cycle back to 0 once it hits or exceeds 24 hours
	if Lighting.ClockTime >= 24 then
		Lighting.ClockTime = Lighting.ClockTime - 24
	end
end)
