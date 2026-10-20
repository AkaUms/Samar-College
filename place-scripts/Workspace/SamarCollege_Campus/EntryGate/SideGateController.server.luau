-- SideGateController: swing gate for the pedestrian ENTRY / EXIT doorways.
-- Press E (either side) to open/close. Auto-closes after AUTO_CLOSE seconds.
local TweenService = game:GetService("TweenService")
local gate = script.Parent
local hinge = gate:WaitForChild("Leaf"):WaitForChild("Hinge")
local AUTO_CLOSE = 10
local TIME = 1.2
local angle = gate:GetAttribute("OpenAngle") or math.rad(90)
local label = gate:GetAttribute("Label") or "GATE"
local nice = label:sub(1,1)..label:sub(2):lower()
local closedCF = hinge.CFrame
local sound = hinge:FindFirstChild("GateSound")
local isOpen, busy, token = false, false, 0
local leafParts = {}
for _, d in ipairs(gate.Leaf:GetDescendants()) do
	if d:IsA("BasePart") and d ~= hinge then table.insert(leafParts, d) end
end
local function setSolid(on)
	for _, q in ipairs(leafParts) do q.CanCollide = on end
end

local prompts = {}
for _, d in ipairs(gate:GetDescendants()) do
	if d:IsA("ProximityPrompt") then table.insert(prompts, d) end
end
local function refresh()
	for _, pr in ipairs(prompts) do
		pr.ActionText = (isOpen and "Close " or "Open ")..nice.." Gate"
	end
end

local function move(open)
	if busy or open == isOpen then return end
	busy = true
	isOpen = open
	refresh()
	if sound and sound.SoundId ~= "" then sound:Play() end
	local goal = open and closedCF * CFrame.Angles(0, angle, 0) or closedCF
	local tw = TweenService:Create(hinge, TweenInfo.new(TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {CFrame = goal})
	setSolid(false)
	tw:Play()
	tw.Completed:Wait()
	setSolid(true)
	busy = false
	if open then
		token += 1
		local my = token
		task.delay(AUTO_CLOSE, function()
			if isOpen and token == my then move(false) end
		end)
	end
end

for _, pr in ipairs(prompts) do
	pr.Triggered:Connect(function() move(not isOpen) end)
end
refresh()
