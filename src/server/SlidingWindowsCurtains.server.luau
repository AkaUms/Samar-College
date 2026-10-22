-- SlidingWindowsCurtains: E to open / close sliding windows and curtains.
--   Models tagged "SlidingWindow": child model "SlidingSash" slides by the unit's SlideX attribute (studs on X).
--   Models tagged "SlidingCurtain": every "Fold" part moves between its ClosedX and OpenX attributes.
-- Open/closed state is stored in the "Open" attribute (also set "RequestOpen" from other scripts).
local CS = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local function partsOf(model)
	local t = {}
	for _, p in ipairs(model:GetDescendants()) do if p:IsA("BasePart") then t[p] = p.CFrame end end
	return t
end

local function setupWindow(unit)
	local sash = unit:WaitForChild("SlidingSash", 5)
	local prompt = unit:FindFirstChild("WindowPrompt", true)
	if not sash or not prompt then return end
	local base = partsOf(sash)
	local info = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	local busy = false
	local function set(open)
		if busy then return end busy = true
		local dx = open and (unit:GetAttribute("SlideX") or -4) or 0
		local last
		for p, cf in pairs(base) do last = TweenService:Create(p, info, { CFrame = cf + Vector3.new(dx, 0, 0) }) last:Play() end
		if last then last.Completed:Wait() end
		unit:SetAttribute("Open", open)
		prompt.ActionText = open and "Close window" or "Open window"
		busy = false
	end
	prompt.Triggered:Connect(function() set(not unit:GetAttribute("Open")) end)
	unit:GetAttributeChangedSignal("RequestOpen"):Connect(function()
		local w = unit:GetAttribute("RequestOpen")
		if w ~= nil and w ~= unit:GetAttribute("Open") then set(w) end
	end)
	unit:SetAttribute("Open", false)
end

local function setupCurtain(model)
	local prompt = model:FindFirstChild("CurtainPrompt", true)
	if prompt and prompt:IsA("BasePart") then prompt = prompt:FindFirstChildOfClass("ProximityPrompt") end
	if not prompt then return end
	local folds = {}
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") and p:GetAttribute("ClosedX") then table.insert(folds, p) end
	end
	local info = TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	local busy = false
	local function set(open)
		if busy then return end busy = true
		local last
		for _, f in ipairs(folds) do
			local x = open and f:GetAttribute("OpenX") or f:GetAttribute("ClosedX")
			local cf = f.CFrame
			last = TweenService:Create(f, info, { CFrame = cf + Vector3.new(x - cf.Position.X, 0, 0) })
			last:Play()
		end
		if last then last.Completed:Wait() end
		model:SetAttribute("Open", open)
		prompt.ActionText = open and "Close curtains" or "Open curtains"
		busy = false
	end
	prompt.Triggered:Connect(function() set(not model:GetAttribute("Open")) end)
	model:GetAttributeChangedSignal("RequestOpen"):Connect(function()
		local w = model:GetAttribute("RequestOpen")
		if w ~= nil and w ~= model:GetAttribute("Open") then set(w) end
	end)
	model:SetAttribute("Open", false)
end

for _, m in ipairs(CS:GetTagged("SlidingWindow")) do task.spawn(setupWindow, m) end
CS:GetInstanceAddedSignal("SlidingWindow"):Connect(setupWindow)
for _, m in ipairs(CS:GetTagged("SlidingCurtain")) do task.spawn(setupCurtain, m) end
CS:GetInstanceAddedSignal("SlidingCurtain"):Connect(setupCurtain)
