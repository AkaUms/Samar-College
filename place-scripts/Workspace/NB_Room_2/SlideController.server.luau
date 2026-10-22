-- Workspace.SamarCollege_Campus.2F.02_Rooms.NB_Room_2.Details.Inside.FrontWall.SlidingWhiteboardTV.SlideController
-- Sliding whiteboard over the TV (NB Room 2).
-- Closed: the two whiteboard panels cover the TV.  Open: they slide to the sides and show the TV.
local TweenService = game:GetService("TweenService")
local W = script.Parent
local prompt = W:WaitForChild("SlideButton"):WaitForChild("SlidePrompt")
local sliders = { W:WaitForChild("SliderLeft"), W:WaitForChild("SliderRight") }
local INFO = TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

-- remember every part's closed position
local base = {}
for _, m in ipairs(sliders) do
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then base[p] = p.CFrame end
	end
end

local busy = false
local function setOpen(open)
	if busy then return end
	busy = true
	local tweens = {}
	for _, m in ipairs(sliders) do
		local dz = open and (m:GetAttribute("OpenZ") - m:GetAttribute("ClosedZ")) or 0
		for p, cf in pairs(base) do
			if p:IsDescendantOf(m) then
				local t = TweenService:Create(p, INFO, { CFrame = cf + Vector3.new(0, 0, dz) })
				table.insert(tweens, t)
				t:Play()
			end
		end
	end
	if tweens[1] then tweens[1].Completed:Wait() end
	W:SetAttribute("Open", open)
	prompt.ActionText = open and "Close whiteboard" or "Open whiteboard"
	busy = false
end

prompt.Triggered:Connect(function()
	setOpen(not W:GetAttribute("Open"))
end)
-- other scripts (e.g. an admin/teacher tool) can also set the "RequestOpen" attribute
W:GetAttributeChangedSignal("RequestOpen"):Connect(function()
	local want = W:GetAttribute("RequestOpen")
	if want ~= nil and want ~= W:GetAttribute("Open") then setOpen(want) end
end)
setOpen(false)
