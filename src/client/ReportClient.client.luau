-- ReportClient: the 🚩 Report button on the left side buttons and the "Report a player" window.
-- Pick who, what they did, and (if you want) tell the admins more. ReportServer checks and saves it,
-- and the admin team sees it in the admin panel (📋 Player Records → 🚩 Reports).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local ReportConfig = require(RS:WaitForChild("ReportConfig"))
local submit = RS:WaitForChild("ReportRemotes"):WaitForChild("SubmitReport")

local C = {
	bg = Color3.fromRGB(24, 26, 34), panel = Color3.fromRGB(32, 34, 46), card = Color3.fromRGB(42, 45, 60),
	input = Color3.fromRGB(22, 24, 32), stroke = Color3.fromRGB(70, 74, 96), text = Color3.fromRGB(240, 240, 245),
	dim = Color3.fromRGB(160, 164, 186), red = Color3.fromRGB(200, 60, 60), green = Color3.fromRGB(39, 120, 70),
	green2 = Color3.fromRGB(60, 170, 100), gold = Color3.fromRGB(240, 196, 70),
}

local function corner(o, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r or 10) c.Parent = o return c end
local function stroke(o, col, t) local s = Instance.new("UIStroke") s.Color = col or C.stroke s.Thickness = t or 1 s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border s.Parent = o return s end
local function frame(parent, size, pos, col)
	local f = Instance.new("Frame") f.Size = size f.Position = pos or UDim2.new() f.BackgroundColor3 = col or C.card f.BorderSizePixel = 0 f.Parent = parent return f
end
local function label(parent, text, size, font, col, props)
	local l = Instance.new("TextLabel") l.BackgroundTransparency = 1 l.Text = text l.TextSize = size or 14
	l.Font = font or Enum.Font.GothamBold l.TextColor3 = col or C.text l.TextXAlignment = Enum.TextXAlignment.Left
	l.Size = UDim2.new(1, 0, 0, (size or 14) + 6) l.TextWrapped = true
	for k, v in pairs(props or {}) do l[k] = v end
	if not (props and props.Size) then l.AutomaticSize = Enum.AutomaticSize.Y end
	l.Parent = parent return l
end
local function button(parent, text, col, size, props)
	local b = Instance.new("TextButton") b.AutoButtonColor = true b.BackgroundColor3 = col or C.card b.Text = text
	b.Font = Enum.Font.GothamBold b.TextSize = 14 b.TextColor3 = C.text b.Size = size
	for k, v in pairs(props or {}) do b[k] = v end b.Parent = parent corner(b, 8) return b
end
local function sortList(o, gap)
	local l = Instance.new("UIListLayout") l.Padding = UDim.new(0, gap or 8) l.SortOrder = Enum.SortOrder.LayoutOrder l.Parent = o return l
end

---------------------------------------------------------------- window
local gui = Instance.new("ScreenGui")
gui.Name = "ReportGui" gui.ResetOnSpawn = false gui.DisplayOrder = 15 gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local dim = frame(gui, UDim2.new(1, 800, 1, 800), UDim2.fromOffset(-400, -400), Color3.new(0, 0, 0))
dim.BackgroundTransparency = 0.5 dim.Visible = false dim.Active = true
local panel = frame(gui, UDim2.fromOffset(560, 540), UDim2.fromScale(0.5, 0.5), C.bg)
panel.Name = "ReportPanel" panel.AnchorPoint = Vector2.new(0.5, 0.5) panel.Visible = false corner(panel, 16) stroke(panel, C.red, 1.6)
local scale = Instance.new("UIScale") scale.Parent = panel
local function rescale()
	local v = gui.AbsoluteSize
	if v.X < 2 then v = workspace.CurrentCamera.ViewportSize end
	scale.Scale = math.clamp(math.min((v.X - 16) / 560, (v.Y - 12) / 540), 0.3, 1)
end
rescale()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(rescale)

local head = frame(panel, UDim2.new(1, 0, 0, 54), nil, Color3.fromRGB(150, 45, 45)) corner(head, 16)
frame(head, UDim2.new(1, 0, 0, 16), UDim2.new(0, 0, 1, -16), Color3.fromRGB(150, 45, 45))
label(head, "🚩  Report a player", 20, Enum.Font.GothamBlack, C.text, { Position = UDim2.fromOffset(18, 6), Size = UDim2.new(1, -80, 0, 26) })
label(head, "Tell the Samar College admins about someone breaking the rules", 12, Enum.Font.Gotham, Color3.fromRGB(255, 215, 215),
	{ Position = UDim2.fromOffset(18, 31), Size = UDim2.new(1, -80, 0, 16) })
local closeB = button(head, "X", C.red, UDim2.fromOffset(34, 34), { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Font = Enum.Font.GothamBlack, TextSize = 18 })

local body = Instance.new("ScrollingFrame")
body.Size = UDim2.new(1, -24, 1, -138) body.Position = UDim2.fromOffset(12, 64) body.BackgroundTransparency = 1 body.BorderSizePixel = 0
body.ScrollBarThickness = 5 body.AutomaticCanvasSize = Enum.AutomaticSize.Y body.CanvasSize = UDim2.new() body.Parent = panel
sortList(body, 8)
local bp = Instance.new("UIPadding") bp.PaddingRight = UDim.new(0, 8) bp.Parent = body

local function section(text, order) local l = label(body, text, 14, Enum.Font.GothamBlack, C.gold) l.LayoutOrder = order return l end
local function grid(order, cellH)
	local g = frame(body, UDim2.new(1, 0, 0, 0), nil, C.bg) g.BackgroundTransparency = 1 g.AutomaticSize = Enum.AutomaticSize.Y g.LayoutOrder = order
	local l = Instance.new("UIGridLayout") l.CellSize = UDim2.new(0.5, -4, 0, cellH) l.CellPadding = UDim2.fromOffset(8, 8) l.SortOrder = Enum.SortOrder.LayoutOrder l.Parent = g
	return g
end

section("1.  Who?", 1)
local whoGrid = grid(2, 46)
local nobody = label(body, "Nobody else is in this server right now.", 13, Enum.Font.Gotham, C.dim) nobody.LayoutOrder = 3 nobody.Visible = false
section("2.  What did they do?", 4)
local reasonGrid = grid(5, 34)
section("3.  Tell the admins more (optional)", 6)
local details = Instance.new("TextBox")
details.Size = UDim2.new(1, 0, 0, 70) details.BackgroundColor3 = C.input details.TextColor3 = C.text details.PlaceholderColor3 = Color3.fromRGB(110, 114, 136)
details.PlaceholderText = "What happened? Where and when? (e.g. they kept swearing at me in the canteen)"
details.Text = "" details.Font = Enum.Font.Gotham details.TextSize = 14 details.MultiLine = true details.TextWrapped = true details.ClearTextOnFocus = false
details.TextXAlignment = Enum.TextXAlignment.Left details.TextYAlignment = Enum.TextYAlignment.Top details.LayoutOrder = 7 details.Parent = body
corner(details, 8) stroke(details, C.stroke)
local dp = Instance.new("UIPadding") dp.PaddingLeft = UDim.new(0, 8) dp.PaddingRight = UDim.new(0, 8) dp.PaddingTop = UDim.new(0, 6) dp.Parent = details
local counter = label(body, "0 / " .. ReportConfig.MaxDetails, 11, Enum.Font.Gotham, C.dim, { TextXAlignment = Enum.TextXAlignment.Right }) counter.LayoutOrder = 8
label(body, "Only the Samar College admins see reports. Sending false reports can get you in trouble. " ..
	"For serious problems, also use Roblox's own Report in the Roblox menu (Esc → Report).", 12, Enum.Font.Gotham, C.dim).LayoutOrder = 9

local footer = frame(panel, UDim2.new(1, -24, 0, 50), UDim2.new(0, 12, 1, -62), C.panel) corner(footer, 12)
local status = label(footer, "", 13, Enum.Font.GothamBold, C.dim, { Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -170, 1, 0), TextXAlignment = Enum.TextXAlignment.Left })
local sendB = button(footer, "🚩  Send report", C.red, UDim2.fromOffset(146, 36), { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0) })

---------------------------------------------------------------- choosing
local chosenUser, chosenReason
local whoButtons, reasonButtons = {}, {}

local function paint()
	for uid, b in pairs(whoButtons) do
		b.BackgroundColor3 = uid == chosenUser and C.green or C.card
		b:FindFirstChildOfClass("UIStroke").Color = uid == chosenUser and C.green2 or C.stroke
	end
	for id, b in pairs(reasonButtons) do b.BackgroundColor3 = id == chosenReason and C.green or C.card end
end

local function renderPlayers()
	for _, b in pairs(whoButtons) do b:Destroy() end
	whoButtons = {}
	local list = {}
	for _, p in ipairs(Players:GetPlayers()) do if p ~= player then table.insert(list, p) end end
	table.sort(list, function(a, b) return a.DisplayName:lower() < b.DisplayName:lower() end)
	if chosenUser and not Players:GetPlayerByUserId(chosenUser) then chosenUser = nil end
	for i, p in ipairs(list) do
		local b = button(whoGrid, "", C.card, UDim2.new(), { LayoutOrder = i })
		stroke(b, C.stroke)
		local img = Instance.new("ImageLabel") img.Size = UDim2.fromOffset(34, 34) img.Position = UDim2.fromOffset(6, 6) img.BackgroundColor3 = C.input
		img.Image = "rbxthumb://type=AvatarHeadShot&id=" .. p.UserId .. "&w=48&h=48" img.Parent = b corner(img, 17)
		label(b, p.DisplayName, 14, Enum.Font.GothamBold, C.text, { Position = UDim2.fromOffset(48, 5), Size = UDim2.new(1, -54, 0, 18), TextWrapped = false, TextTruncate = Enum.TextTruncate.AtEnd })
		label(b, "@" .. p.Name, 12, Enum.Font.Gotham, C.dim, { Position = UDim2.fromOffset(48, 24), Size = UDim2.new(1, -54, 0, 16), TextWrapped = false, TextTruncate = Enum.TextTruncate.AtEnd })
		b.MouseButton1Click:Connect(function() chosenUser = p.UserId paint() end)
		whoButtons[p.UserId] = b
	end
	nobody.Visible = #list == 0
	paint()
end

for i, r in ipairs(ReportConfig.Reasons) do
	local b = button(reasonGrid, r.Name, C.card, UDim2.new(), { LayoutOrder = i, TextSize = 13, TextWrapped = true })
	b.MouseButton1Click:Connect(function() chosenReason = r.Id paint() end)
	reasonButtons[r.Id] = b
end

details:GetPropertyChangedSignal("Text"):Connect(function()
	local n = utf8.len(details.Text) or #details.Text
	if n > ReportConfig.MaxDetails then
		details.Text = details.Text:sub(1, utf8.offset(details.Text, ReportConfig.MaxDetails + 1) - 1)
		return
	end
	counter.Text = n .. " / " .. ReportConfig.MaxDetails
end)

---------------------------------------------------------------- open / close / send
local function setStatus(text, good)
	status.Text = text
	status.TextColor3 = good == true and Color3.fromRGB(140, 240, 170) or (good == false and Color3.fromRGB(255, 150, 150) or C.dim)
end
local function open()
	renderPlayers()
	setStatus("Pick who and what they did, then press Send.")
	dim.Visible = true panel.Visible = true
end
local function close() panel.Visible = false dim.Visible = false end
closeB.MouseButton1Click:Connect(close)

local sending = false
sendB.MouseButton1Click:Connect(function()
	if sending then return end
	if not chosenUser then setStatus("Pick who you are reporting.", false) return end
	if not chosenReason then setStatus("Pick what they did.", false) return end
	sending = true
	sendB.Text = "Sending..."
	local ok, res = pcall(function() return submit:InvokeServer(chosenUser, chosenReason, details.Text) end)
	sending = false
	sendB.Text = "🚩  Send report"
	if not ok or type(res) ~= "table" then setStatus("Couldn't send it. Please try again.", false) return end
	setStatus(res.msg or "", res.ok == true)
	if res.ok then
		chosenUser, chosenReason = nil, nil
		details.Text = ""
		paint()
		task.delay(2.5, function() if panel.Visible then close() end end)
	end
end)

Players.PlayerAdded:Connect(function() if panel.Visible then renderPlayers() end end)
Players.PlayerRemoving:Connect(function() task.defer(function() if panel.Visible then renderPlayers() end end) end)

---------------------------------------------------------------- 🚩 Report button on the left side buttons
local function addRailButton(hud)
	local rail = hud and hud:FindFirstChild("Rail")
	local tmpl = rail and rail:FindFirstChild("MapButton")
	if not tmpl or rail:FindFirstChild("ReportButton") then return end
	local b = tmpl:Clone()
	b.Name = "ReportButton" b.LayoutOrder = 5
	for _, d in ipairs(b:GetDescendants()) do if d:IsA("LuaSourceContainer") then d:Destroy() end end
	if b:FindFirstChild("Icon") then b.Icon.Text = "🚩" end
	if b:FindFirstChild("Caption") then b.Caption.Text = "Report" end
	b.Parent = rail
	b.MouseButton1Click:Connect(function() if panel.Visible then close() else open() end end)
end
local pg = player:WaitForChild("PlayerGui")
pg.ChildAdded:Connect(function(c)
	if c.Name == "MainHUD" then
		c:WaitForChild("Rail", 10)
		task.wait(0.3)
		addRailButton(c)
	end
end)
task.spawn(function()
	local hud = pg:WaitForChild("MainHUD", 30)
	if hud then hud:WaitForChild("Rail", 10) task.wait(0.3) addRailButton(hud) end
end)
