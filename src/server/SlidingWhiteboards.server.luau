-- SlidingWhiteboards: whiteboards whose middle panels slide sideways to show a TV behind them.
-- A whiteboard is a Model tagged "SlidingWhiteboard" with:
--   child models that have a Vector3 attribute "OpenOffset" (how far they slide when opened)
--   ProximityPrompt "SlidePrompt" (E) somewhere inside (on the slide button)
-- Open/closed state is kept in the "Open" attribute; other scripts can set "RequestOpen" (true/false).
local CS = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local INFO = TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

local function setup(board)
	local prompt = board:FindFirstChild("SlidePrompt", true)
	if not prompt then return end

	-- remember every sliding part's closed position
	local sliders = {}
	for _, m in ipairs(board:GetChildren()) do
		local offset = m:GetAttribute("OpenOffset")
		if typeof(offset) == "Vector3" then
			local parts = {}
			if m:IsA("BasePart") then parts[m] = m.CFrame end
			for _, p in ipairs(m:GetDescendants()) do
				if p:IsA("BasePart") then parts[p] = p.CFrame end
			end
			table.insert(sliders, { offset = offset, parts = parts })
		end
	end

	local busy = false
	local function setOpen(open)
		if busy then return end
		busy = true
		local last
		for _, s in ipairs(sliders) do
			local off = open and s.offset or Vector3.zero
			for p, cf in pairs(s.parts) do
				last = TweenService:Create(p, INFO, { CFrame = cf + off })
				last:Play()
			end
		end
		if last then last.Completed:Wait() end
		board:SetAttribute("Open", open)
		prompt.ActionText = open and "Close whiteboard" or "Open whiteboard"
		busy = false
		-- a request that came in while sliding
		local want = board:GetAttribute("RequestOpen")
		if want ~= nil and want ~= open then setOpen(want) end
	end

	prompt.Triggered:Connect(function()
		local open = not board:GetAttribute("Open")
		board:SetAttribute("RequestOpen", open)
		setOpen(open)
	end)
	board:GetAttributeChangedSignal("RequestOpen"):Connect(function()
		local want = board:GetAttribute("RequestOpen")
		if want ~= nil and want ~= board:GetAttribute("Open") then setOpen(want) end
	end)
	board:SetAttribute("Open", false)
	board:SetAttribute("RequestOpen", false)
	prompt.ActionText = "Open whiteboard"
end

for _, b in ipairs(CS:GetTagged("SlidingWhiteboard")) do task.spawn(setup, b) end
CS:GetInstanceAddedSignal("SlidingWhiteboard"):Connect(setup)
