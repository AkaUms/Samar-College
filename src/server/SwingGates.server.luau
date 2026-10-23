-- SwingGates: metal grille gates (one or two leaves) that swing open / closed with E.
-- A gate is a Model tagged "SwingGate" with:
--   leaf models that have a number attribute "OpenAngle" (degrees around Y) and an anchored part "Hinge";
--   every other part of the leaf is unanchored and welded to its Hinge, so turning the Hinge swings the leaf
--   ProximityPrompt "GatePrompt" somewhere inside (on the lock box)
-- Open/closed state is kept in the "Open" attribute; other scripts can set "RequestOpen" (true/false).
local CS = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local INFO = TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

local function setup(gate)
	local prompt = gate:FindFirstChild("GatePrompt", true)
	if not prompt then return end

	local leaves = {}
	for _, m in ipairs(gate:GetChildren()) do
		local angle = m:GetAttribute("OpenAngle")
		local hinge = m:FindFirstChild("Hinge")
		if type(angle) == "number" and hinge and hinge:IsA("BasePart") then
			table.insert(leaves, { hinge = hinge, closed = hinge.CFrame, angle = math.rad(angle) })
		end
	end

	local busy = false
	local function setOpen(open)
		if busy then return end
		busy = true
		local last
		for _, l in ipairs(leaves) do
			local goal = open and (l.closed * CFrame.Angles(0, l.angle, 0)) or l.closed
			last = TweenService:Create(l.hinge, INFO, { CFrame = goal })
			last:Play()
		end
		if last then last.Completed:Wait() end
		gate:SetAttribute("Open", open)
		prompt.ActionText = open and "Close gate" or "Open gate"
		busy = false
		local want = gate:GetAttribute("RequestOpen")
		if want ~= nil and want ~= open then setOpen(want) end
	end

	prompt.Triggered:Connect(function()
		local open = not gate:GetAttribute("Open")
		gate:SetAttribute("RequestOpen", open)
		setOpen(open)
	end)
	gate:GetAttributeChangedSignal("RequestOpen"):Connect(function()
		local want = gate:GetAttribute("RequestOpen")
		if want ~= nil and want ~= gate:GetAttribute("Open") then setOpen(want) end
	end)
	gate:SetAttribute("Open", false)
	gate:SetAttribute("RequestOpen", false)
	prompt.ActionText = "Open gate"
end

for _, g in ipairs(CS:GetTagged("SwingGate")) do task.spawn(setup, g) end
CS:GetInstanceAddedSignal("SwingGate"):Connect(setup)
