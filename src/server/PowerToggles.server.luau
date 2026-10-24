-- PowerToggles: devices you can switch on and off (aircon, computers, TV, desk lamps ...).
-- A device is a Model tagged "PowerToggle" with:
--   ProximityPrompt "PowerPrompt" (anywhere inside; on the control panel, screen or lamp)
--   attributes: DeviceName ("aircon", "computer" ...), On (true / false), Key ("E" or "F", optional)
-- What changes when it is on / off:
--   Light objects                -> Enabled
--   ParticleEmitter / Sound      -> Enabled / Playing
--   part "Screen"                -> its SurfaceGuis show, black when off
--   part "Bulb"                  -> Neon when on
--   part "LED"                   -> green when on, dark red when off
--   part "Louver" (OpenAngle)    -> swings open when on
local CS = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local OFF_SCREEN = Color3.fromRGB(18, 18, 20)
local LED_ON = Color3.fromRGB(70, 230, 100)
local LED_OFF = Color3.fromRGB(120, 30, 30)
local LOUVER_TWEEN = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function setup(device)
	if not device:IsA("Model") then return end
	local prompt = device:FindFirstChild("PowerPrompt", true)
	if not prompt or not prompt:IsA("ProximityPrompt") then return end
	local name = device:GetAttribute("DeviceName") or "device"
	local key = device:GetAttribute("Key")
	if key and Enum.KeyCode[key] then prompt.KeyboardKeyCode = Enum.KeyCode[key] end
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
	if prompt.MaxActivationDistance > 8 then prompt.MaxActivationDistance = 8 end

	-- remember how each part looks when it is on
	for _, d in ipairs(device:GetDescendants()) do
		if d:IsA("BasePart") then
			if d.Name == "Screen" and d:GetAttribute("OnColor") == nil then d:SetAttribute("OnColor", d.Color) end
			if d.Name == "Bulb" and d:GetAttribute("OnColor") == nil then d:SetAttribute("OnColor", d.Color) end
			if d.Name == "Louver" and d:GetAttribute("ClosedCFrame") == nil then d:SetAttribute("ClosedCFrame", d.CFrame) end
		end
	end

	local function apply(animate)
		local on = device:GetAttribute("On") == true
		for _, d in ipairs(device:GetDescendants()) do
			if d:IsA("Light") then
				d.Enabled = on
			elseif d:IsA("ParticleEmitter") then
				d.Enabled = on
			elseif d:IsA("Sound") then
				if on then d:Play() else d:Stop() end
			elseif d:IsA("BasePart") then
				if d.Name == "Screen" then
					d.Color = on and (d:GetAttribute("OnColor") or d.Color) or OFF_SCREEN
					for _, g in ipairs(d:GetChildren()) do
						if g:IsA("SurfaceGui") then g.Enabled = on end
					end
				elseif d.Name == "Bulb" then
					d.Material = on and Enum.Material.Neon or Enum.Material.SmoothPlastic
					d.Color = on and (d:GetAttribute("OnColor") or d.Color) or Color3.fromRGB(205, 205, 200)
				elseif d.Name == "LED" then
					d.Material = on and Enum.Material.Neon or Enum.Material.SmoothPlastic
					d.Color = on and LED_ON or LED_OFF
				elseif d.Name == "Louver" then
					local closed = d:GetAttribute("ClosedCFrame")
					if closed then
						local goal = on and closed * CFrame.Angles(math.rad(d:GetAttribute("OpenAngle") or 30), 0, 0) or closed
						if animate then TweenService:Create(d, LOUVER_TWEEN, { CFrame = goal }):Play() else d.CFrame = goal end
					end
				end
			end
		end
		prompt.ActionText = (on and "Turn off " or "Turn on ") .. name
	end

	prompt.Triggered:Connect(function()
		device:SetAttribute("On", not (device:GetAttribute("On") == true))
	end)
	device:GetAttributeChangedSignal("On"):Connect(function() apply(true) end)
	apply(false)
end

for _, d in ipairs(CS:GetTagged("PowerToggle")) do task.spawn(setup, d) end
CS:GetInstanceAddedSignal("PowerToggle"):Connect(setup)
