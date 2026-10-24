-- Spins every fan (Model with attribute Spin=true and a "Blades" model) on the client.
-- The blades turn around the Blades model's pivot Y axis (ceiling fans: straight up; stand fans:
-- set the pivot so its Y axis points forward). A fan with the attribute On = false stops
-- (stand fans are PowerToggle devices that set On).
local RunService = game:GetService("RunService")
local SPEED = math.rad(240) -- degrees per second
local fans = {}
local function add(m)
	if m:IsA("Model") and m:GetAttribute("Spin") then
		local blades = m:FindFirstChild("Blades")
		if blades and blades:IsA("Model") then
			table.insert(fans, { fan = m, model = blades, base = blades:GetPivot(), angle = 0 })
		end
	end
end
for _, d in ipairs(workspace:GetDescendants()) do add(d) end
workspace.DescendantAdded:Connect(add)
RunService.RenderStepped:Connect(function(dt)
	for _, f in ipairs(fans) do
		if f.model.Parent and f.fan:GetAttribute("On") ~= false then
			f.angle = (f.angle + SPEED * dt) % (math.pi * 2)
			f.model:PivotTo(f.base * CFrame.Angles(0, f.angle, 0))
		end
	end
end)
