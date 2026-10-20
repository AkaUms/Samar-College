-- Animates the CCTV monitor wall (clock, blinking REC, scan line) and blinks camera LEDs.
local post = script.Parent
local camFolder = post.Parent:WaitForChild("CCTV_Cameras")
local feeds, leds = {}, {}
for _, d in ipairs(post:GetDescendants()) do
	if d:IsA("SurfaceGui") and d.Name == "Feed" then table.insert(feeds, d) end
end
for _, d in ipairs(camFolder:GetDescendants()) do
	if d:IsA("BasePart") and d:GetAttribute("CCTV_LED") then table.insert(leds, d) end
end
local on = true
local t0 = os.clock()
task.spawn(function()
	while true do
		local y = ((os.clock() - t0) * 0.35) % 1
		for _, g in ipairs(feeds) do
			local f = g:FindFirstChildOfClass("Frame")
			local sc = f and f:FindFirstChild("Scan")
			if sc then sc.Position = UDim2.new(0, 0, y, 0) end
		end
		task.wait(0.1)
	end
end)
while true do
	on = not on
	local stamp = os.date("%Y-%m-%d  %H:%M:%S")
	for _, g in ipairs(feeds) do
		local f = g:FindFirstChildOfClass("Frame")
		if f then
			local rec, tm = f:FindFirstChild("Rec"), f:FindFirstChild("Time")
			if rec then rec.TextTransparency = on and 0 or 0.85 end
			if tm then tm.Text = stamp end
		end
	end
	for _, l in ipairs(leds) do l.Transparency = on and 0 or 0.7 end
	task.wait(0.5)
end
