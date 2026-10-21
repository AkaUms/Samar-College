-- AdminPowersClient: client side of the admin powers (set by AdminServer through player attributes).
--   AdminFly + AdminFlySpeed : fly (WASD / thumbstick to move, Space / E up, Ctrl / Q down)
--   AdminGod                 : the humanoid can't enter the Dead state
--   AdminInvisible           : you see a faint outline of yourself while invisible to others
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer

local flying, flyConn, lv, ao, att
local function stopFly()
	flying = false
	if flyConn then flyConn:Disconnect() flyConn = nil end
	if lv then lv:Destroy() lv = nil end
	if ao then ao:Destroy() ao = nil end
	if att then att:Destroy() att = nil end
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum.PlatformStand = false hum:ChangeState(Enum.HumanoidStateType.Freefall) end
end

local function startFly()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum then return end
	stopFly()
	flying = true
	att = Instance.new("Attachment") att.Name = "AdminFlyAttachment" att.Parent = hrp
	lv = Instance.new("LinearVelocity") lv.Attachment0 = att lv.MaxForce = math.huge lv.RelativeTo = Enum.ActuatorRelativeTo.World lv.VectorVelocity = Vector3.zero lv.Parent = hrp
	ao = Instance.new("AlignOrientation") ao.Attachment0 = att ao.Mode = Enum.OrientationAlignmentMode.OneAttachment ao.MaxTorque = math.huge ao.Responsiveness = 40 ao.Parent = hrp
	hum.PlatformStand = true
	flyConn = RunService.RenderStepped:Connect(function()
		if not hrp.Parent then stopFly() return end
		local cam = workspace.CurrentCamera
		local speed = player:GetAttribute("AdminFlySpeed") or 50
		local move = hum.MoveDirection -- world-space, works for keyboard and mobile thumbstick
		-- tilt forward movement with the camera's pitch so you can fly up/down by looking
		local look = cam.CFrame.LookVector
		local flat = Vector3.new(look.X, 0, look.Z)
		local vertical = 0
		if flat.Magnitude > 0.01 and move.Magnitude > 0.01 then
			local forwardAmount = move:Dot(flat.Unit)
			vertical += look.Y * forwardAmount
		end
		if not UIS:GetFocusedTextBox() then
			if UIS:IsKeyDown(Enum.KeyCode.Space) or UIS:IsKeyDown(Enum.KeyCode.E) then vertical += 1 end
			if UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.Q) then vertical -= 1 end
		end
		local v = Vector3.new(move.X, 0, move.Z) + Vector3.new(0, vertical, 0)
		lv.VectorVelocity = (v.Magnitude > 0 and v.Unit * math.min(v.Magnitude, 1.4) or Vector3.zero) * speed
		if flat.Magnitude > 0.01 then ao.CFrame = CFrame.lookAt(Vector3.zero, flat) end
	end)
end

local highlight
local function refresh()
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	-- fly
	if player:GetAttribute("AdminFly") then if not flying then startFly() end elseif flying then stopFly() end
	-- god
	if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Dead, not player:GetAttribute("AdminGod")) end
	-- invisible: outline only on your own screen
	if player:GetAttribute("AdminInvisible") and char then
		if not highlight or highlight.Parent ~= char then
			if highlight then highlight:Destroy() end
			highlight = Instance.new("Highlight") highlight.Name = "AdminInvisibleSelf"
			highlight.FillTransparency = 0.85 highlight.OutlineTransparency = 0.2
			highlight.FillColor = Color3.fromRGB(150, 200, 255) highlight.OutlineColor = Color3.fromRGB(150, 200, 255)
			highlight.DepthMode = Enum.HighlightDepthMode.Occluded highlight.Parent = char
		end
	elseif highlight then highlight:Destroy() highlight = nil end
end

for _, a in ipairs({ "AdminFly", "AdminFlySpeed", "AdminGod", "AdminInvisible" }) do
	player:GetAttributeChangedSignal(a):Connect(refresh)
end
player.CharacterAdded:Connect(function(char)
	flying = false flyConn = nil lv = nil ao = nil att = nil highlight = nil
	char:WaitForChild("HumanoidRootPart", 10) char:WaitForChild("Humanoid", 10)
	task.wait(0.5)
	refresh()
end)
if player.Character then task.defer(refresh) end
