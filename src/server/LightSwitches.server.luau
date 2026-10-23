-- LightSwitches: wall switches that turn a group of lights on/off and change brightness.
-- A switch is a Model tagged "LightSwitch" with:
--   ObjectValue "Lights"  -> the folder/model holding the lights (PointLight / SpotLight / SurfaceLight + Neon bulbs)
--   ProximityPrompt "PowerPrompt"      (E)  on / off
--   ProximityPrompt "BrightnessPrompt" (R)  Low -> Medium -> High
--   optional part "Indicator" (green when on)
-- Each light keeps its normal brightness in the "BaseBrightness" attribute.
local CS = game:GetService("CollectionService")

local LEVELS = { { name = "Low", mult = 0.5 }, { name = "Medium", mult = 1 }, { name = "High", mult = 1.6 } }

local function setup(sw)
	local link = sw:WaitForChild("Lights", 5)
	local power = sw:FindFirstChild("PowerPrompt", true)
	local bright = sw:FindFirstChild("BrightnessPrompt", true)
	if not link or not link.Value or not power then return end
	local group = link.Value
	local indicator = sw:FindFirstChild("Indicator", true)

	local function apply()
		local on = sw:GetAttribute("On") ~= false
		local lvl = LEVELS[sw:GetAttribute("Level") or 2] or LEVELS[2]
		for _, d in ipairs(group:GetDescendants()) do
			if d:IsA("Light") then
				local base = d:GetAttribute("BaseBrightness")
				if not base then base = d.Brightness d:SetAttribute("BaseBrightness", base) end
				d.Enabled = on
				d.Brightness = base * lvl.mult
			elseif d:IsA("BasePart") and (d.Name == "Bulb" or d.Name == "Tube") then
				d.Material = on and Enum.Material.Neon or Enum.Material.SmoothPlastic
				d.Color = on and Color3.fromRGB(255, 253, 240) or Color3.fromRGB(205, 205, 200)
			end
		end
		power.ActionText = on and "Turn off lights" or "Turn on lights"
		if bright then bright.ActionText = "Brightness: " .. lvl.name bright.Enabled = on end
		if indicator then
			indicator.Color = on and Color3.fromRGB(70, 230, 90) or Color3.fromRGB(200, 40, 40)
		end
	end

	power.Triggered:Connect(function()
		sw:SetAttribute("On", not (sw:GetAttribute("On") ~= false))
	end)
	if bright then
		bright.Triggered:Connect(function()
			local l = (sw:GetAttribute("Level") or 2) % #LEVELS + 1
			sw:SetAttribute("Level", l)
		end)
	end
	sw:GetAttributeChangedSignal("On"):Connect(apply)
	sw:GetAttributeChangedSignal("Level"):Connect(apply)
	apply()
end

for _, sw in ipairs(CS:GetTagged("LightSwitch")) do task.spawn(setup, sw) end
CS:GetInstanceAddedSignal("LightSwitch"):Connect(setup)
