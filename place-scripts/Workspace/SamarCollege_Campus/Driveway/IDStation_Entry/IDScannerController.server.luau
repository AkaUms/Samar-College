-- IDScannerController: wall-mounted dual ID tap + flap gate + ceiling dual monitors
local TweenService = game:GetService("TweenService")
local station = script.Parent
local mode = station:GetAttribute("Mode") or "ENTRY"
local OPEN_TIME = 4
local mon = station:WaitForChild("CeilingMonitors")
local scrL = mon:WaitForChild("Screen1"):WaitForChild("Display"):WaitForChild("BG")
local scrR = mon:WaitForChild("Screen2"):WaitForChild("Display"):WaitForChild("BG")
local GREEN = Color3.fromRGB(30, 150, 80)
local NAVY  = Color3.fromRGB(20, 40, 85)
local GOLD  = Color3.fromRGB(255, 215, 60)

local function clear(f) for _, c in ipairs(f:GetChildren()) do c:Destroy() end end
local function text(parent, t, pos, size, col, font, align)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1 l.Position = pos l.Size = size
	l.Text = t l.TextScaled = true l.TextColor3 = col or Color3.new(1, 1, 1)
	l.Font = font or Enum.Font.GothamBold l.TextXAlignment = align or Enum.TextXAlignment.Center
	l.Parent = parent return l
end
local function idle()
	clear(scrL) clear(scrR)
	scrL.BackgroundColor3 = NAVY scrR.BackgroundColor3 = NAVY
	text(scrL, "SAMAR COLLEGE", UDim2.fromScale(0.05, 0.06), UDim2.fromScale(0.9, 0.18), GOLD, Enum.Font.GothamBlack)
	text(scrL, mode == "ENTRY" and "WELCOME!" or "THANK YOU!", UDim2.fromScale(0.05, 0.3), UDim2.fromScale(0.9, 0.26), nil, Enum.Font.GothamBlack)
	text(scrL, "Please tap your ID\non the wall scanner", UDim2.fromScale(0.05, 0.62), UDim2.fromScale(0.9, 0.3))
	text(scrR, mode .. " LOG", UDim2.fromScale(0.05, 0.06), UDim2.fromScale(0.9, 0.16), GOLD, Enum.Font.GothamBlack)
	text(scrR, os.date("%b %d, %Y"), UDim2.fromScale(0.05, 0.3), UDim2.fromScale(0.9, 0.16))
	text(scrR, os.date("%I:%M:%S %p"), UDim2.fromScale(0.05, 0.48), UDim2.fromScale(0.9, 0.24), nil, Enum.Font.GothamBlack).Name = "Clock"
	text(scrR, "Status: READY", UDim2.fromScale(0.05, 0.8), UDim2.fromScale(0.9, 0.12), Color3.fromRGB(150, 220, 255))
end
local function show(plr)
	clear(scrL) clear(scrR)
	scrL.BackgroundColor3 = GREEN
	text(scrL, "✔ ACCESS GRANTED", UDim2.fromScale(0.04, 0.1), UDim2.fromScale(0.92, 0.24), nil, Enum.Font.GothamBlack)
	text(scrL, (mode == "ENTRY" and "Welcome, " or "Ingat, ") .. plr.DisplayName .. "!", UDim2.fromScale(0.04, 0.42), UDim2.fromScale(0.92, 0.22))
	text(scrL, mode == "ENTRY" and "Please proceed to campus" or "Please proceed to exit", UDim2.fromScale(0.04, 0.72), UDim2.fromScale(0.92, 0.14))
	scrR.BackgroundColor3 = Color3.fromRGB(240, 240, 236)
	local band = Instance.new("Frame") band.BorderSizePixel = 0 band.BackgroundColor3 = Color3.fromRGB(39, 70, 45) band.Size = UDim2.fromScale(1, 0.2) band.Parent = scrR
	text(band, "SAMAR COLLEGE • STUDENT ID", UDim2.fromScale(0.03, 0.12), UDim2.fromScale(0.94, 0.76), GOLD, Enum.Font.GothamBlack)
	local pic = Instance.new("ImageLabel")
	pic.Size = UDim2.fromScale(0.28, 0.56) pic.Position = UDim2.fromScale(0.04, 0.27)
	pic.BackgroundColor3 = Color3.fromRGB(200, 205, 210) pic.BorderSizePixel = 0
	pic.Image = "rbxthumb://type=AvatarHeadShot&id=" .. plr.UserId .. "&w=150&h=150" pic.Parent = scrR
	local ls = plr:FindFirstChild("leaderstats")
	local title = ls and ls:FindFirstChild("Title") and tostring(ls.Title.Value) or "Student"
	local tm = ls and ls:FindFirstChild("Time") and tostring(ls.Time.Value) or "-"
	local dark = Color3.fromRGB(30, 30, 35)
	text(scrR, plr.DisplayName, UDim2.fromScale(0.36, 0.26), UDim2.fromScale(0.62, 0.15), dark, Enum.Font.GothamBlack, Enum.TextXAlignment.Left)
	text(scrR, "@" .. plr.Name, UDim2.fromScale(0.36, 0.41), UDim2.fromScale(0.62, 0.1), Color3.fromRGB(90, 90, 100), nil, Enum.TextXAlignment.Left)
	text(scrR, "Level: " .. title, UDim2.fromScale(0.36, 0.54), UDim2.fromScale(0.62, 0.11), dark, nil, Enum.TextXAlignment.Left)
	text(scrR, "Time on campus: " .. tm, UDim2.fromScale(0.36, 0.66), UDim2.fromScale(0.62, 0.1), dark, nil, Enum.TextXAlignment.Left)
	text(scrR, mode .. "  •  " .. os.date("%I:%M %p"), UDim2.fromScale(0.04, 0.87), UDim2.fromScale(0.92, 0.1), Color3.fromRGB(39, 110, 60), Enum.Font.GothamBlack)
end
idle()
task.spawn(function()
	while true do task.wait(1) local c = scrR:FindFirstChild("Clock") if c then c.Text = os.date("%I:%M:%S %p") end end
end)

-- gate
local flaps = {}
for _, f in ipairs(station:WaitForChild("FlapGate"):GetChildren()) do
	local h = f:WaitForChild("Hinge")
	table.insert(flaps, { hinge = h, closed = h.CFrame, angle = f:GetAttribute("OpenAngle"), glass = f:FindFirstChild("FlapGlass"), edge = f:FindFirstChild("FlapEdge") })
end
local function swing(open)
	for _, fl in ipairs(flaps) do
		if fl.glass then fl.glass.CanCollide = not open end
		if fl.edge then fl.edge.Color = open and Color3.fromRGB(60, 220, 110) or Color3.fromRGB(230, 60, 60) end
		TweenService:Create(fl.hinge, TweenInfo.new(0.45, Enum.EasingStyle.Quad), { CFrame = open and fl.closed * CFrame.Angles(0, fl.angle, 0) or fl.closed }):Play()
	end
end

-- two wall readers, either one opens the gate
local readers = {}
for _, r in ipairs(station:WaitForChild("WallIDPanel"):GetChildren()) do
	if r.Name:match("^Reader") then table.insert(readers, r) end
end
local busy, token = false, 0
local function setReaders(state, who)
	for _, r in ipairs(readers) do
		local scr = r:FindFirstChild("ReaderScreen")
		local st = scr and scr.ReaderGui:FindFirstChild("Status")
		if state == "ok" then
			if r == who then scr.Color = Color3.fromRGB(40, 200, 90) st.Text = "✔ OK"
			else scr.Color = Color3.fromRGB(230, 160, 30) st.Text = "WAIT" end
		else scr.Color = Color3.fromRGB(220, 40, 40) st.Text = "TAP ID" end
		r.PromptAnchor.ScanPrompt.Enabled = (state ~= "ok")
	end
end
for _, r in ipairs(readers) do
	r.PromptAnchor.ScanPrompt.Triggered:Connect(function(plr)
		if busy then return end
		busy = true
		token += 1 local my = token
		setReaders("ok", r)
		show(plr)
		swing(true)
		task.wait(OPEN_TIME)
		swing(false)
		task.wait(0.5)
		setReaders("idle")
		busy = false
		task.delay(2, function() if token == my then idle() end end)
	end)
end
