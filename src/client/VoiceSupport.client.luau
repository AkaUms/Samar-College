-- VoiceSupport: shows a "speaking" bubble above players' heads while they talk.
-- Mic on/off is handled by Roblox's own voice settings / top-bar mic button.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local GREEN = Color3.fromRGB(60, 200, 110)
local SPEAK_LEVEL = 0.015
local tracked = {}

local function makeBadge()
	local bb = Instance.new("BillboardGui")
	bb.Name = "VoiceIndicator"
	bb.Size = UDim2.fromScale(1.6, 1.6)
	bb.StudsOffset = Vector3.new(0, 2.6, 0)
	bb.LightInfluence = 0
	bb.MaxDistance = 80
	bb.Enabled = false
	local bg = Instance.new("Frame")
	bg.Name = "Bubble"
	bg.AnchorPoint = Vector2.new(0.5, 0.5)
	bg.Position = UDim2.fromScale(0.5, 0.5)
	bg.Size = UDim2.fromScale(0.8, 0.8)
	bg.BackgroundColor3 = GREEN
	bg.Parent = bb
	Instance.new("UICorner", bg).CornerRadius = UDim.new(0.5, 0)
	local s = Instance.new("UIStroke", bg) s.Color = Color3.new(1, 1, 1) s.Thickness = 2
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Text = "🎤"
	t.TextScaled = true
	t.Parent = bg
	return bb
end

local function track(plr)
	if tracked[plr] then return end
	local input = plr:FindFirstChildOfClass("AudioDeviceInput")
	if not input then return end
	local analyzer = Instance.new("AudioAnalyzer")
	analyzer.Name = "VoiceLevel_" .. plr.UserId
	local wire = Instance.new("Wire")
	wire.SourceInstance = input
	wire.TargetInstance = analyzer
	analyzer.Parent = script
	wire.Parent = analyzer
	tracked[plr] = { input = input, analyzer = analyzer, badge = makeBadge(), speaking = 0 }
end

local function untrack(plr)
	local t = tracked[plr]
	if not t then return end
	t.analyzer:Destroy()
	t.badge:Destroy()
	tracked[plr] = nil
end

local function watch(plr)
	track(plr)
	plr.ChildAdded:Connect(function(c) if c:IsA("AudioDeviceInput") then track(plr) end end)
end
for _, p in ipairs(Players:GetPlayers()) do watch(p) end
Players.PlayerAdded:Connect(watch)
Players.PlayerRemoving:Connect(untrack)

local pulse = 0
RunService.RenderStepped:Connect(function(dt)
	pulse += dt
	for plr, t in pairs(tracked) do
		local level = t.analyzer.RmsLevel
		if (not t.input.Muted) and level > SPEAK_LEVEL then t.speaking = 0.35 else t.speaking = math.max(0, t.speaking - dt) end
		local head = plr.Character and plr.Character:FindFirstChild("Head")
		if head and t.badge.Parent ~= head then t.badge.Adornee = head t.badge.Parent = head end
		t.badge.Enabled = head ~= nil and t.speaking > 0
		if t.badge.Enabled then
			local s = 0.8 + math.clamp(level * 6, 0, 0.25) + math.sin(pulse * 10) * 0.03
			t.badge.Bubble.Size = UDim2.fromScale(s, s)
		end
	end
end)
