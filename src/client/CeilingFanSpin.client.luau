-- Spins every ceiling fan (Model with attribute Spin=true and a "Blades" model) on the client.
local RunService = game:GetService("RunService")
local SPEED = math.rad(240) -- degrees per second
local fans = {}
local function add(m)
	if m:IsA("Model") and m:GetAttribute("Spin") then
		local blades = m:FindFirstChild("Blades")
		if blades and blades:IsA("Model") then
			table.insert(fans, {model = blades, base = blades:GetPivot()})
		end
	end
end
for _, d in ipairs(workspace:GetDescendants()) do add(d) end
workspace.DescendantAdded:Connect(add)
local angle = 0
RunService.RenderStepped:Connect(function(dt)
	angle = (angle + SPEED * dt) % (math.pi * 2)
	for _, f in ipairs(fans) do
		if f.model.Parent then
			f.model:PivotTo(f.base * CFrame.Angles(0, angle, 0))
		end
	end
end)
