-- Samar College main gate: double swing gate (opens inward).
-- Open/close with the "Open Gate" prompt (outside or inside) or the green control button by the guard post.
-- Closes automatically after AUTO_CLOSE seconds.
local TweenService = game:GetService("TweenService")
local gate = script.Parent
local AUTO_CLOSE = 20
local TIME = 2.2

local leaves = {
	{ hinge = gate.LeafSouth.Hinge, angle = math.rad(90) },
	{ hinge = gate.LeafNorth.Hinge, angle = math.rad(-90) },
}
for _, l in ipairs(leaves) do l.closed = l.hinge.CFrame end

local isOpen, busy, token = false, false, 0
local prompts = {}
for _, d in ipairs(gate:GetDescendants()) do if d:IsA("ProximityPrompt") then table.insert(prompts, d) end end

local function setPromptText()
	for _, p in ipairs(prompts) do p.ActionText = isOpen and "Close Gate" or "Open Gate" end
	local b = gate:FindFirstChild("GateButton")
	if b then b.Color = isOpen and Color3.fromRGB(220, 60, 50) or Color3.fromRGB(40, 180, 80) end
end

local function move(open)
	if busy or open == isOpen then return end
	busy = true
	local s = gate.LeafSouth.Hinge:FindFirstChild("GateSound") if s then s:Play() end
	local tweens = {}
	for _, l in ipairs(leaves) do
		local goal = open and (l.closed * CFrame.Angles(0, l.angle, 0)) or l.closed
		local tw = TweenService:Create(l.hinge, TweenInfo.new(TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), { CFrame = goal })
		tw:Play() table.insert(tweens, tw)
	end
	tweens[1].Completed:Wait()
	isOpen = open busy = false
	setPromptText()
	if open then
		token += 1 local my = token
		task.delay(AUTO_CLOSE, function() if isOpen and token == my then move(false) end end)
	end
end

local function toggle() move(not isOpen) end
for _, p in ipairs(prompts) do p.Triggered:Connect(toggle) end
local b = gate:FindFirstChild("GateButton")
local cd = b and b:FindFirstChildOfClass("ClickDetector")
if cd then cd.MouseClick:Connect(toggle) end
setPromptText()
