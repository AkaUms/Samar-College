-- AdminClient: Samar College admin panel UI (only given to admins by AdminServer).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local gui = script.Parent
local req = RS:WaitForChild("AdminRemotes"):WaitForChild("AdminRequest")

local C = {
	bg = Color3.fromRGB(24, 26, 34), panel = Color3.fromRGB(32, 34, 46), card = Color3.fromRGB(42, 45, 60),
	input = Color3.fromRGB(22, 24, 32), stroke = Color3.fromRGB(70, 74, 96), text = Color3.fromRGB(240, 240, 245),
	dim = Color3.fromRGB(160, 164, 186), green = Color3.fromRGB(39, 120, 70), green2 = Color3.fromRGB(60, 170, 100),
	gold = Color3.fromRGB(240, 196, 70), red = Color3.fromRGB(200, 60, 60), blue = Color3.fromRGB(60, 120, 210),
}

---------------------------------------------------------------- tiny UI helpers
local function corner(o, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r or 10) c.Parent = o return c end
local function stroke(o, col, t) local s = Instance.new("UIStroke") s.Color = col or C.stroke s.Thickness = t or 1 s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border s.Parent = o return s end
local function pad(o, n) local p = Instance.new("UIPadding") for _, k in ipairs({ "PaddingTop", "PaddingBottom", "PaddingLeft", "PaddingRight" }) do p[k] = UDim.new(0, n) end p.Parent = o return p end
local function list(o, gap, horizontal)
	local l = Instance.new("UIListLayout") l.Padding = UDim.new(0, gap or 6) l.SortOrder = Enum.SortOrder.LayoutOrder
	if horizontal then l.FillDirection = Enum.FillDirection.Horizontal l.VerticalAlignment = Enum.VerticalAlignment.Center end
	l.Parent = o return l
end
local function frame(parent, size, pos, col, name)
	local f = Instance.new("Frame") f.Size = size f.Position = pos or UDim2.new() f.BackgroundColor3 = col or C.card f.BorderSizePixel = 0
	if name then f.Name = name end f.Parent = parent return f
end
local function label(parent, text, size, font, col, props)
	local l = Instance.new("TextLabel") l.BackgroundTransparency = 1 l.Text = text l.TextSize = size or 14
	l.Font = font or Enum.Font.GothamBold l.TextColor3 = col or C.text l.TextXAlignment = Enum.TextXAlignment.Left
	l.Size = UDim2.new(1, 0, 0, (size or 14) + 6) l.TextWrapped = true
	for k, v in pairs(props or {}) do l[k] = v end
	if not (props and props.Size) then l.AutomaticSize = Enum.AutomaticSize.Y end -- long text wraps onto more lines
	l.Parent = parent return l
end
local function button(parent, text, col, size, props)
	local b = Instance.new("TextButton") b.AutoButtonColor = true b.BackgroundColor3 = col or C.card b.Text = text
	b.Font = Enum.Font.GothamBold b.TextSize = 14 b.TextColor3 = C.text b.Size = size or UDim2.fromOffset(120, 34)
	for k, v in pairs(props or {}) do b[k] = v end b.Parent = parent corner(b, 8) return b
end
local function textbox(parent, placeholder, size, numeric)
	local t = Instance.new("TextBox") t.BackgroundColor3 = C.input t.PlaceholderText = placeholder or "" t.Text = ""
	t.PlaceholderColor3 = Color3.fromRGB(110, 114, 136) t.TextColor3 = C.text t.Font = Enum.Font.Gotham t.TextSize = 14
	t.ClearTextOnFocus = false t.Size = size or UDim2.new(1, 0, 0, 34) t.TextXAlignment = Enum.TextXAlignment.Left
	t.Parent = parent corner(t, 8) stroke(t, C.stroke) pad(t, 8)
	if numeric then
		t:GetPropertyChangedSignal("Text"):Connect(function()
			local clean = t.Text:gsub("[^%d]", "")
			if clean ~= t.Text then t.Text = clean end
		end)
	end
	return t
end
local function cardSection(parent, title, order)
	local c = frame(parent, UDim2.new(1, -4, 0, 0), nil, C.card) c.AutomaticSize = Enum.AutomaticSize.Y c.LayoutOrder = order or 0
	corner(c, 12) stroke(c, C.stroke) pad(c, 12) list(c, 8)
	label(c, title, 15, Enum.Font.GothamBlack, C.gold).LayoutOrder = -1
	return c
end
local function row(parent, h, order)
	local r = frame(parent, UDim2.new(1, 0, 0, h or 34), nil, C.card) r.BackgroundTransparency = 1 r.LayoutOrder = order or 0
	list(r, 8, true) return r
end

-- dates and times are shown in the viewer's own time zone
local serverOffset = 0 -- server clock minus this computer's clock
local function nowS() return os.time() + serverOffset end
local function fmtDT(t, fmt)
	if type(t) ~= "number" or t <= 0 then return "—" end
	local ok, s = pcall(function() return DateTime.fromUnixTimestamp(t):FormatLocalTime(fmt, "en-us") end)
	return ok and s or "—"
end
local function fmtDay(t) return fmtDT(t, "MMM D, YYYY") end
local function fmtClock(t) return fmtDT(t, "h:mm A") end
local function fmtWhen(t) return fmtDT(t, "MMM D, h:mm A") end
local function fmtDur(sec)
	sec = math.max(0, math.floor(tonumber(sec) or 0))
	local d, h, m = sec // 86400, sec % 86400 // 3600, sec % 3600 // 60
	if d > 0 then return d .. "d " .. h .. "h" end
	if h > 0 then return h .. "h " .. string.format("%02d", m) .. "m" end
	if m > 0 then return m .. "m" end
	return sec .. "s"
end
local function ago(t)
	if type(t) ~= "number" or t <= 0 then return "—" end
	local s = nowS() - t
	if s < 60 then return "just now" end
	return fmtDur(s) .. " ago"
end

---------------------------------------------------------------- shell
pcall(function() gui.ClipToDeviceSafeArea = false end)
local dim = frame(gui, UDim2.new(1, 800, 1, 800), UDim2.fromOffset(-400, -400), Color3.new(0, 0, 0)) dim.BackgroundTransparency = 0.45 dim.Visible = false dim.Active = true
dim.AnchorPoint = Vector2.zero dim.Position = UDim2.fromOffset(-400, -400) dim.BorderSizePixel = 0
local panel = frame(gui, UDim2.fromOffset(940, 600), UDim2.fromScale(0.5, 0.5), C.bg, "AdminPanel")
panel.AnchorPoint = Vector2.new(0.5, 0.5) panel.Visible = false corner(panel, 16) stroke(panel, C.gold, 1.6)
local scale = Instance.new("UIScale") scale.Parent = panel
local function rescale()
	local v = gui.AbsoluteSize
	if v.X < 2 then v = workspace.CurrentCamera.ViewportSize end
	scale.Scale = math.clamp(math.min((v.X - 16) / 940, (v.Y - 12) / 600), 0.3, 1)
end
rescale() workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(rescale)

local head = frame(panel, UDim2.new(1, 0, 0, 58), nil, C.green) corner(head, 16)
frame(head, UDim2.new(1, 0, 0, 16), UDim2.new(0, 0, 1, -16), C.green)
label(head, "🛡  ADMIN PANEL", 20, Enum.Font.GothamBlack, C.text, { Position = UDim2.fromOffset(18, 8), Size = UDim2.new(0.6, 0, 0, 24) })
local roleL = label(head, "TEAM PRUC • Samar College", 13, Enum.Font.GothamBold, Color3.fromRGB(205, 240, 215), { Position = UDim2.fromOffset(18, 33), Size = UDim2.new(0.6, 0, 0, 18) })
local closeB = button(head, "X", C.red, UDim2.fromOffset(36, 36), { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), TextSize = 18, Font = Enum.Font.GothamBlack })

-- left column: search + players in server
local left = frame(panel, UDim2.new(0, 260, 1, -78), UDim2.fromOffset(12, 68), C.panel) corner(left, 12) pad(left, 10)
label(left, "FIND A PLAYER", 13, Enum.Font.GothamBlack, C.dim, { Size = UDim2.new(1, 0, 0, 18) })
local searchBox = textbox(left, "Username or User ID", UDim2.new(1, -78, 0, 34)) searchBox.Position = UDim2.fromOffset(0, 24)
local searchB = button(left, "Search", C.green2, UDim2.fromOffset(72, 34), { Position = UDim2.new(1, -72, 0, 24) })
label(left, "IN THIS SERVER", 13, Enum.Font.GothamBlack, C.dim, { Position = UDim2.fromOffset(0, 70), Size = UDim2.new(1, 0, 0, 18) })
local refreshB = button(left, "Refresh", C.card, UDim2.fromOffset(64, 22), { Position = UDim2.new(1, -64, 0, 68), TextSize = 11 })
local plist = Instance.new("ScrollingFrame") plist.Size = UDim2.new(1, 0, 1, -98) plist.Position = UDim2.fromOffset(0, 96)
plist.BackgroundTransparency = 1 plist.ScrollBarThickness = 5 plist.AutomaticCanvasSize = Enum.AutomaticSize.Y plist.CanvasSize = UDim2.new() plist.BorderSizePixel = 0 plist.Parent = left
list(plist, 6)

-- right side
local right = frame(panel, UDim2.new(1, -296, 1, -78), UDim2.fromOffset(284, 68), C.bg) right.BackgroundTransparency = 1
local cardP = frame(right, UDim2.new(1, 0, 0, 92), nil, C.panel) corner(cardP, 12) stroke(cardP, C.stroke)
local avatar = Instance.new("ImageLabel") avatar.Size = UDim2.fromOffset(72, 72) avatar.Position = UDim2.fromOffset(10, 10) avatar.BackgroundColor3 = C.card avatar.Parent = cardP corner(avatar, 36)
local nameL = label(cardP, "No player selected", 19, Enum.Font.GothamBlack, C.text, { Position = UDim2.fromOffset(94, 12), Size = UDim2.new(1, -110, 0, 24) })
local subL = label(cardP, "Search a username / user ID, or pick someone in this server.", 13, Enum.Font.Gotham, C.dim, { Position = UDim2.fromOffset(94, 38), Size = UDim2.new(1, -110, 0, 18) })
local chipsL = label(cardP, "", 13, Enum.Font.GothamBold, C.gold, { Position = UDim2.fromOffset(94, 60), Size = UDim2.new(1, -110, 0, 18) })

local tabsBar = frame(right, UDim2.new(1, 0, 0, 36), UDim2.fromOffset(0, 100), C.bg) tabsBar.BackgroundTransparency = 1 list(tabsBar, 6, true)
local pages = frame(right, UDim2.new(1, 0, 1, -196), UDim2.fromOffset(0, 142), C.panel) corner(pages, 12)
local footer = frame(right, UDim2.new(1, 0, 0, 46), UDim2.new(0, 0, 1, -46), C.panel) corner(footer, 12)
local pendingL = label(footer, "No unsaved changes", 14, Enum.Font.GothamBold, C.dim, { Position = UDim2.fromOffset(14, 13), Size = UDim2.new(1, -300, 0, 20) })
local discardB = button(footer, "Discard", C.card, UDim2.fromOffset(100, 34), { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -150, 0.5, 0) })
local saveB = button(footer, "💾  Save Changes", C.green2, UDim2.fromOffset(134, 34), { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0) })

local toast = label(panel, "", 14, Enum.Font.GothamBold, C.text, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 34), Size = UDim2.fromOffset(600, 28),
	BackgroundTransparency = 0.05, BackgroundColor3 = C.card, TextXAlignment = Enum.TextXAlignment.Center, Visible = false })
corner(toast, 8)
local toastToken = 0
local function notify(msg, good)
	toastToken += 1 local my = toastToken
	toast.Text = msg toast.TextColor3 = good == false and Color3.fromRGB(255, 140, 140) or (good and Color3.fromRGB(140, 240, 170) or C.text) toast.Visible = true
	task.delay(4, function() if my == toastToken then toast.Visible = false end end)
end

local pageFrames, tabButtons = {}, {}
local showPageRef
local function makePage(name, order)
	local sf = Instance.new("ScrollingFrame") sf.Name = name sf.Size = UDim2.fromScale(1, 1) sf.BackgroundTransparency = 1 sf.BorderSizePixel = 0
	sf.ScrollBarThickness = 6 sf.AutomaticCanvasSize = Enum.AutomaticSize.Y sf.CanvasSize = UDim2.new() sf.Visible = false sf.Parent = pages
	pad(sf, 12) list(sf, 10)
	local b = button(tabsBar, name, C.card, UDim2.fromOffset(101, 32), { LayoutOrder = order, TextSize = 12 })
	pageFrames[name] = sf tabButtons[name] = b
	b.MouseButton1Click:Connect(function() showPageRef(name) end)
	return sf
end
local function showPage(name)
	for n, f in pairs(pageFrames) do f.Visible = n == name tabButtons[n].BackgroundColor3 = n == name and C.green or C.card end
end
showPageRef = showPage

---------------------------------------------------------------- state
local META, target, pending = nil, nil, {}
local refreshPages -- forward

local function countPending()
	local n = 0
	if pending.level then n += 1 end
	for _, k in ipairs({ "coins", "owned", "inventory", "stats" }) do if pending[k] then for _ in pairs(pending[k]) do n += 1 end end end
	return n
end
local function updatePending()
	local n = countPending()
	pendingL.Text = n == 0 and "No unsaved changes" or ("● " .. n .. " unsaved change" .. (n == 1 and "" or "s") .. " — press Save")
	pendingL.TextColor3 = n == 0 and C.dim or C.gold
end
local function stage(cat, key, value)
	if not target then return end
	if cat == "level" then pending.level = value
	else pending[cat] = pending[cat] or {} pending[cat][key] = value end
	updatePending()
end

local function call(action, args)
	local ok, res = pcall(function() return req:InvokeServer(action, args) end)
	if not ok then return { ok = false, msg = tostring(res) } end
	return res or { ok = false, msg = "No response" }
end

---------------------------------------------------------------- pages
local pMod = makePage("Moderation", 1)
local pGrade = makePage("Grade & Coins", 2)
local pItems = makePage("Items", 3)
local pStats = makePage("Events & Stats", 4)
local pPowers = makePage("Powers", 5)
local pAdmins = makePage("Admins", 6)

-- MODERATION
local kickCard = cardSection(pMod, "👢  Kick from server", 1)
label(kickCard, "Removes the player from the game right now (they can rejoin).", 12, Enum.Font.Gotham, C.dim)
local kickReason = textbox(kickCard, "Reason (optional)")
local kickB = button(kickCard, "Kick Player", C.red, UDim2.fromOffset(150, 34))

local banCard = cardSection(pMod, "⛔  Ban player", 2)
local banInfo = label(banCard, "", 13, Enum.Font.GothamBold, Color3.fromRGB(255, 150, 150))
local banRow = row(banCard, 34)
local banAmount = textbox(banRow, "How long", UDim2.fromOffset(110, 34), true)
local units, unitButtons, banUnit = { "Seconds", "Minutes", "Hours", "Days" }, {}, "Hours"
for i, u in ipairs(units) do
	local b = button(banRow, u, C.input, UDim2.fromOffset(86, 34), { LayoutOrder = i, TextSize = 13 })
	unitButtons[u] = b
	b.MouseButton1Click:Connect(function() banUnit = u for n, bb in pairs(unitButtons) do bb.BackgroundColor3 = n == u and C.blue or C.input end end)
end
unitButtons.Hours.BackgroundColor3 = C.blue
local banReason = textbox(banCard, "Reason (shown to the player)")
local banBtns = row(banCard, 34)
local banB = button(banBtns, "Ban Player", C.red, UDim2.fromOffset(150, 34))
local unbanB = button(banBtns, "Unban", C.card, UDim2.fromOffset(110, 34))

local banListCard = cardSection(pMod, "📋  Banned players", 3)
local banListNote = label(banListCard, "Everyone who is banned right now. Unban works even if they are offline.", 12, Enum.Font.Gotham, C.dim)
local banListRefresh = button(banListCard, "Refresh list", C.card, UDim2.fromOffset(120, 28), { TextSize = 12 })
local banListHolder = frame(banListCard, UDim2.new(1, 0, 0, 0), nil, C.card) banListHolder.BackgroundTransparency = 1 banListHolder.AutomaticSize = Enum.AutomaticSize.Y list(banListHolder, 6)
local resetCard = cardSection(pMod, "♻  Reset progress", 4)
label(resetCard, "Sets the player back to a brand-new student: Kindergarten, 0 time, starting coins, no items, all event counts 0. This saves immediately.", 12, Enum.Font.Gotham, C.dim)
local resetB = button(resetCard, "Reset Progress", C.red, UDim2.fromOffset(170, 34))

-- GRADE & COINS
local gradeCard = cardSection(pGrade, "🎓  Grade level", 1)
local gradeInfo = label(gradeCard, "", 13, Enum.Font.GothamBold, C.text)
local timeInfo = label(gradeCard, "", 12, Enum.Font.Gotham, C.dim)
local gradeBtns = row(gradeCard, 34)
local demoteB = button(gradeBtns, "◀  Demote", C.card, UDim2.fromOffset(120, 34))
local promoteB = button(gradeBtns, "Promote  ▶", C.green2, UDim2.fromOffset(120, 34))
local chipsHolder = frame(gradeCard, UDim2.new(1, 0, 0, 0), nil, C.card) chipsHolder.BackgroundTransparency = 1 chipsHolder.AutomaticSize = Enum.AutomaticSize.Y
local cgrid = Instance.new("UIGridLayout") cgrid.CellSize = UDim2.fromOffset(98, 30) cgrid.CellPadding = UDim2.fromOffset(6, 6) cgrid.SortOrder = Enum.SortOrder.LayoutOrder cgrid.Parent = chipsHolder
label(gradeCard, "Changing the level restarts the player's quiz timer (total play time is not changed).", 12, Enum.Font.Gotham, C.dim)
local levelChips = {}

local coinBoxes = {}
for i, cur in ipairs({ "Common", "Event" }) do
	local cc = cardSection(pGrade, (cur == "Common" and "🪙  Common Coin" or "⭐  Event Coin"), 1 + i)
	local r = row(cc, 34)
	local box = textbox(r, "Amount", UDim2.fromOffset(160, 34), true)
	local cl = label(r, "", 13, Enum.Font.Gotham, C.dim, { Size = UDim2.fromOffset(260, 34), TextWrapped = false })
	coinBoxes[cur] = { box = box, note = cl }
	box.FocusLost:Connect(function() if target and box.Text ~= "" then stage("coins", cur, tonumber(box.Text)) cl.Text = "→ will be set to " .. box.Text end end)
end

-- ITEMS
local itemRows = { Cosmetic = {}, Equipment = {}, Consumable = {} }
local itemCards = {}
for i, cat in ipairs({ "Cosmetic", "Equipment", "Consumable" }) do
	itemCards[cat] = cardSection(pItems, (cat == "Cosmetic" and "👕  Cosmetics" or cat == "Equipment" and "🔦  Equipment" or "🍕  Consumables"), i)
end

-- STATS
local STAT_NAMES = { EventsCommon = "Common events joined", EventsRare = "Rare events joined", QuizzesPassed = "Quizzes passed",
	EventsParkour = "Parkour events joined", EventsEscape = "Escape events joined", EventsPhotobooth = "Photobooth events joined" }
local STAT_ICONS = { EventsCommon = "🎪", EventsRare = "💎", QuizzesPassed = "📝", EventsParkour = "🏃", EventsEscape = "🚪", EventsPhotobooth = "📸" }
local statCard = cardSection(pStats, "🏆  Events & activity counts", 1)
label(statCard, "Type any number. 'Events joined' on the Profile becomes the total of the five event types.", 12, Enum.Font.Gotham, C.dim)
local statBoxes = {}

-- POWERS (instant, players in this server only)
local powCard = cardSection(pPowers, "⚡  Admin powers", 1)
label(powCard, "These switch on/off instantly (no Save needed) for the selected player — they must be in this server. They stay on through respawns until you turn them off.", 12, Enum.Font.Gotham, C.dim)
local meB = button(powCard, "Select myself", C.blue, UDim2.fromOffset(140, 30), { TextSize = 13 })
local powerUI = {}
local function powerRow(key, title, desc, withNumber, default, order)
	local card = cardSection(pPowers, title, order)
	label(card, desc, 12, Enum.Font.Gotham, C.dim)
	local r = row(card, 34)
	local box
	if withNumber then
		box = textbox(r, tostring(default), UDim2.fromOffset(110, 34), true) box.Text = tostring(default)
		label(r, "speed", 13, Enum.Font.Gotham, C.dim, { Size = UDim2.fromOffset(50, 34), TextWrapped = false })
	end
	local onB = button(r, "Turn ON", C.green2, UDim2.fromOffset(110, 32), { TextSize = 13 })
	local offB = button(r, "Turn OFF", C.red, UDim2.fromOffset(110, 32), { TextSize = 13 })
	local status = label(r, "", 13, Enum.Font.GothamBold, C.dim, { Size = UDim2.fromOffset(170, 34), TextWrapped = false })
	powerUI[key] = { box = box, status = status }
	local function send(on)
		if not target then notify("Select a player first", false) return end
		local r2 = call("power", { userId = target.userId, power = key, on = on, value = box and tonumber(box.Text) or nil })
		notify(r2.msg, r2.ok)
		if r2.ok then task.wait(0.2) local l = call("lookup", { query = tostring(target.userId) }) if l.ok then target = l refreshPages() end end
	end
	onB.MouseButton1Click:Connect(function() send(true) end)
	offB.MouseButton1Click:Connect(function() send(false) end)
end
powerRow("invisible", "👻  Invisible", "Hides the player's whole avatar and name from everyone. They see a faint outline of themselves.", false, nil, 2)
powerRow("god", "🛡  God mode", "The player can't take damage or die.", false, nil, 3)
powerRow("fly", "🕊  Fly", "Fly with WASD / thumbstick. Space or E = up, Ctrl or Q = down. Look up/down to climb or dive.", true, 50, 4)
powerRow("speed", "💨  Speed", "Sets walk speed (normal is 16). Turn OFF to go back to normal.", true, 32, 5)

-- ADMINS
local adminCard = cardSection(pAdmins, "👥  Co-admins", 1)
local adminInfo = label(adminCard, "", 13, Enum.Font.Gotham, C.dim)
local adminBtns = row(adminCard, 34)
local makeAdminB = button(adminBtns, "Make Co-Admin", C.green2, UDim2.fromOffset(160, 34))
local removeAdminB = button(adminBtns, "Remove Co-Admin", C.red, UDim2.fromOffset(170, 34))
local adminListCard = cardSection(pAdmins, "Current co-admins", 2)
local adminListHolder = frame(adminListCard, UDim2.new(1, 0, 0, 0), nil, C.card) adminListHolder.BackgroundTransparency = 1 adminListHolder.AutomaticSize = Enum.AutomaticSize.Y list(adminListHolder, 6)

---------------------------------------------------------------- build static parts from server meta
local function buildFromMeta()
	for i, name in ipairs(META.levels) do
		local b = button(chipsHolder, name, C.input, nil, { LayoutOrder = i, TextSize = 12 })
		levelChips[i] = b
		b.MouseButton1Click:Connect(function() if target then stage("level", nil, i) refreshPages() end end)
	end
	for _, cat in ipairs({ "Cosmetic", "Equipment", "Consumable" }) do
		for i, it in ipairs(META.items[cat] or {}) do
			local r = row(itemCards[cat], 34, i)
			label(r, (it.Icon or "•") .. "  " .. it.Name, 14, Enum.Font.GothamBold, C.text, { Size = UDim2.fromOffset(250, 34), TextWrapped = false })
			local status = label(r, "", 13, Enum.Font.Gotham, C.dim, { Size = UDim2.fromOffset(150, 34), TextWrapped = false })
			local entry = { status = status, id = it.Id }
			if cat == "Consumable" then
				local box = textbox(r, "Qty", UDim2.fromOffset(90, 34), true)
				entry.box = box
				box.FocusLost:Connect(function() if target and box.Text ~= "" then stage("inventory", it.Id, tonumber(box.Text)) refreshPages() end end)
			else
				local add = button(r, "Add", C.green2, UDim2.fromOffset(80, 30), { TextSize = 13 })
				local rem = button(r, "Remove", C.red, UDim2.fromOffset(90, 30), { TextSize = 13 })
				add.MouseButton1Click:Connect(function() stage("owned", it.Id, true) refreshPages() end)
				rem.MouseButton1Click:Connect(function() stage("owned", it.Id, false) refreshPages() end)
			end
			itemRows[cat][it.Id] = entry
		end
	end
	for i, s in ipairs(META.stats) do
		local r = row(statCard, 34, i)
		label(r, STAT_ICONS[s] .. "  " .. (STAT_NAMES[s] or s), 14, Enum.Font.GothamBold, C.text, { Size = UDim2.fromOffset(260, 34), TextWrapped = false })
		local box = textbox(r, "0", UDim2.fromOffset(120, 34), true)
		local note = label(r, "", 12, Enum.Font.Gotham, C.dim, { Size = UDim2.fromOffset(180, 34), TextWrapped = false })
		statBoxes[s] = { box = box, note = note }
		box.FocusLost:Connect(function() if target and box.Text ~= "" then stage("stats", s, tonumber(box.Text)) refreshPages() end end)
	end
end

---------------------------------------------------------------- render the selected player
local function fmtTime(t) t = math.floor(t or 0) local h, m = math.floor(t / 3600), math.floor(t % 3600 / 60) return h > 0 and string.format("%dh %02dm", h, m) or string.format("%dm %02ds", m, t % 60) end

function refreshPages()
	local hasT = target ~= nil
	for _, b in ipairs({ kickB, banB, unbanB, resetB, demoteB, promoteB, makeAdminB, removeAdminB, saveB, discardB }) do b.Active = hasT b.AutoButtonColor = hasT end
	if not hasT then return end
	-- card
	nameL.Text = target.displayName .. (target.displayName ~= target.name and ("  (@" .. target.name .. ")") or "")
	subL.Text = "@" .. target.name .. "  •  User ID " .. target.userId .. (target.hasSave == false and "  •  never played (no save yet)" or "")
	local seen = target.seen
	local status
	if target.online then status = "🟢 In this server"
	elseif seen and seen.on then status = "🟢 Online in server " .. tostring(seen.sc)
	else
		local last = seen and (seen.lastOut or seen.lastIn)
		status = "⚪ Offline" .. (last and ("  •  last seen " .. ago(last)) or "")
	end
	local chips = { status, "Role: " .. target.role }
	if seen and seen.on and seen.a then table.insert(chips, 2, "📍 " .. seen.a) end
	if target.ban then table.insert(chips, "⛔ Banned (" .. target.ban.left .. " left)") end
	chipsL.Text = table.concat(chips, "    ")
	avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. target.userId .. "&w=150&h=150"
	-- moderation
	banInfo.Text = target.ban and ("Currently banned — " .. target.ban.left .. " left. Reason: " .. tostring(target.ban.reason)) or "Not banned."
	-- grade
	local lv = pending.level or target.level
	gradeInfo.Text = "Current: " .. META.levels[target.level] .. (pending.level and pending.level ~= target.level and ("   →   new: " .. META.levels[pending.level] .. " (unsaved)") or "")
	timeInfo.Text = "Total time on campus: " .. fmtTime(target.time) .. "     •     Quiz timer at this level: " .. fmtTime(target.levelTime)
	for i, b in ipairs(levelChips) do
		b.BackgroundColor3 = (i == lv) and C.green2 or ((i == target.level) and C.green or C.input)
		b.Text = (i == lv and "★ " or "") .. META.levels[i]
	end
	-- coins
	for cur, e in pairs(coinBoxes) do
		local staged = pending.coins and pending.coins[cur]
		if not e.box:IsFocused() then e.box.Text = tostring(staged or target.coins[cur] or 0) end
		e.note.Text = staged and ("now " .. (target.coins[cur] or 0) .. "  →  " .. staged .. " (unsaved)") or ("now " .. (target.coins[cur] or 0))
	end
	-- items
	for cat, rows in pairs(itemRows) do
		for id, e in pairs(rows) do
			if cat == "Consumable" then
				local staged = pending.inventory and pending.inventory[id]
				local cur = tonumber(target.inventory[id]) or 0
				if not e.box:IsFocused() then e.box.Text = tostring(staged or cur) end
				e.status.Text = staged and ("has " .. cur .. " → " .. staged) or ("has " .. cur)
				e.status.TextColor3 = staged and C.gold or C.dim
			else
				local own = target.owned[id] == true
				local staged = pending.owned and pending.owned[id]
				if staged ~= nil then
					e.status.Text = (staged and "+ will be added" or "- will be removed") e.status.TextColor3 = C.gold
				else
					e.status.Text = own and "Owned" or "— Not owned" e.status.TextColor3 = own and Color3.fromRGB(140, 230, 160) or C.dim
				end
			end
		end
	end
	-- stats
	for s, e in pairs(statBoxes) do
		local staged = pending.stats and pending.stats[s]
		if not e.box:IsFocused() then e.box.Text = tostring(staged or target.stats[s] or 0) end
		e.note.Text = staged and ("was " .. (target.stats[s] or 0) .. " (unsaved)") or ""
		e.note.TextColor3 = C.gold
	end
	-- powers
	local pw = target.powers
	local function st(key, on, extra)
		local e = powerUI[key] if not e then return end
		if not pw then e.status.Text = "not in this server" e.status.TextColor3 = C.dim return end
		e.status.Text = on and ("● ON" .. (extra or "")) or "○ OFF" e.status.TextColor3 = on and Color3.fromRGB(140, 240, 170) or C.dim
	end
	st("invisible", pw and pw.invisible) st("god", pw and pw.god)
	st("fly", pw and pw.fly, pw and pw.fly and ("  (" .. tostring(pw.flySpeed) .. ")") or "")
	st("speed", pw and pw.speed ~= nil, pw and pw.speed and ("  (" .. tostring(pw.speed) .. ")") or "")
	-- admins
	local owner = META.role == "Owner"
	adminInfo.Text = owner and ("Selected: " .. target.name .. " — role " .. target.role .. ". Co-admins can use this panel but can't manage other admins.")
		or "Only the owner can add or remove co-admins."
	makeAdminB.Visible = owner and target.role == "Player"
	removeAdminB.Visible = owner and target.role == "Co-Admin"
	updatePending()
end

local function loadAdmins()
	for _, c in ipairs(adminListHolder:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	local res = call("listAdmins", {})
	if not res.ok then return end
	if #res.admins == 0 then
		local r = row(adminListHolder, 26) label(r, "No co-admins yet.", 13, Enum.Font.Gotham, C.dim, { Size = UDim2.fromOffset(300, 26) })
	end
	for i, a in ipairs(res.admins) do
		local r = row(adminListHolder, 34, i)
		label(r, "👤  " .. tostring(a.name) .. "  (ID " .. a.userId .. ")", 14, Enum.Font.GothamBold, C.text, { Size = UDim2.fromOffset(330, 34), TextWrapped = false })
		if res.canManage then
			local rm = button(r, "Remove", C.red, UDim2.fromOffset(90, 30), { TextSize = 13 })
			rm.MouseButton1Click:Connect(function()
				local out = call("setAdmin", { userId = a.userId, make = false })
				notify(out.msg, out.ok) loadAdmins()
				if target and target.userId == a.userId then target.role = "Player" refreshPages() end
			end)
		end
	end
end

local function loadBans()
	for _, c in ipairs(banListHolder:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	local res = call("listBans", {})
	if not res.ok then local r = row(banListHolder, 26) label(r, res.msg or "Couldn't load bans", 12, Enum.Font.Gotham, Color3.fromRGB(255, 150, 150), { Size = UDim2.fromOffset(520, 26) }) return end
	if #res.bans == 0 then local r = row(banListHolder, 26) label(r, "Nobody is banned.", 13, Enum.Font.Gotham, C.dim, { Size = UDim2.fromOffset(300, 26) }) return end
	for i, b in ipairs(res.bans) do
		local r = row(banListHolder, 34, i)
		label(r, "⛔  " .. tostring(b.name) .. "  •  " .. b.left .. " left  •  " .. tostring(b.reason), 13, Enum.Font.GothamBold, C.text, { Size = UDim2.fromOffset(440, 34), TextWrapped = false, TextTruncate = Enum.TextTruncate.AtEnd })
		local ub = button(r, "Unban", C.green2, UDim2.fromOffset(90, 30), { TextSize = 13 })
		ub.MouseButton1Click:Connect(function()
			local out = call("unban", { userId = b.userId }) notify(out.msg, out.ok) loadBans()
			if target and target.userId == b.userId then target.ban = nil refreshPages() end
		end)
	end
end
banListRefresh.MouseButton1Click:Connect(loadBans)

local function select(query)
	if not query or query == "" then return end
	local res = call("lookup", { query = query })
	if not res.ok then notify(res.msg or "Not found", false) return end
	target = res pending = {}
	refreshPages()
end

local function renderPlayers(players)
	for _, c in ipairs(plist:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
	for i, p in ipairs(players) do
		local b = button(plist, "", C.card, UDim2.new(1, -6, 0, 46), { LayoutOrder = i })
		local img = Instance.new("ImageLabel") img.Size = UDim2.fromOffset(34, 34) img.Position = UDim2.fromOffset(6, 6) img.BackgroundColor3 = C.input
		img.Image = "rbxthumb://type=AvatarHeadShot&id=" .. p.userId .. "&w=48&h=48" img.Parent = b corner(img, 17)
		label(b, p.displayName, 14, Enum.Font.GothamBold, C.text, { Position = UDim2.fromOffset(48, 5), Size = UDim2.new(1, -54, 0, 18), TextWrapped = false, TextTruncate = Enum.TextTruncate.AtEnd })
		label(b, "@" .. p.name, 12, Enum.Font.Gotham, C.dim, { Position = UDim2.fromOffset(48, 24), Size = UDim2.new(1, -54, 0, 16), TextWrapped = false, TextTruncate = Enum.TextTruncate.AtEnd })
		b.MouseButton1Click:Connect(function() select(tostring(p.userId)) end)
	end
end

---------------------------------------------------------------- actions
searchB.MouseButton1Click:Connect(function() select(searchBox.Text) end)
searchBox.FocusLost:Connect(function(enter) if enter then select(searchBox.Text) end end)
refreshB.MouseButton1Click:Connect(function() local r = call("players", {}) if r.ok then renderPlayers(r.players) end end)

local function reselect() if target then select(tostring(target.userId)) end end

kickB.MouseButton1Click:Connect(function()
	if not target then return end
	local r = call("kick", { userId = target.userId, reason = kickReason.Text }) notify(r.msg, r.ok)
	task.delay(1, function() local pl = call("players", {}) if pl.ok then renderPlayers(pl.players) end reselect() end)
end)
banB.MouseButton1Click:Connect(function()
	if not target then return end
	local r = call("ban", { userId = target.userId, amount = tonumber(banAmount.Text), unit = banUnit, reason = banReason.Text })
	notify(r.msg, r.ok) if r.ok then reselect() loadBans() end
end)
unbanB.MouseButton1Click:Connect(function()
	if not target then return end
	local r = call("unban", { userId = target.userId }) notify(r.msg, r.ok) if r.ok then reselect() loadBans() end
end)
meB.MouseButton1Click:Connect(function() select(tostring(player.UserId)) end)
local resetArmed = false
resetB.MouseButton1Click:Connect(function()
	if not target then return end
	if not resetArmed then
		resetArmed = true resetB.Text = "Click again to confirm" resetB.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
		task.delay(4, function() resetArmed = false resetB.Text = "Reset Progress" resetB.BackgroundColor3 = C.red end)
		return
	end
	resetArmed = false resetB.Text = "Reset Progress" resetB.BackgroundColor3 = C.red
	local r = call("reset", { userId = target.userId }) notify(r.msg, r.ok) if r.ok then reselect() end
end)
demoteB.MouseButton1Click:Connect(function()
	if not target then return end
	stage("level", nil, math.max(1, (pending.level or target.level) - 1)) refreshPages()
end)
promoteB.MouseButton1Click:Connect(function()
	if not target then return end
	stage("level", nil, math.min(#META.levels, (pending.level or target.level) + 1)) refreshPages()
end)
makeAdminB.MouseButton1Click:Connect(function()
	if not target then return end
	local r = call("setAdmin", { userId = target.userId, name = target.name, make = true }) notify(r.msg, r.ok)
	if r.ok then target.role = "Co-Admin" refreshPages() loadAdmins() end
end)
removeAdminB.MouseButton1Click:Connect(function()
	if not target then return end
	local r = call("setAdmin", { userId = target.userId, make = false }) notify(r.msg, r.ok)
	if r.ok then target.role = "Player" refreshPages() loadAdmins() end
end)
discardB.MouseButton1Click:Connect(function() pending = {} refreshPages() for _, e in pairs(coinBoxes) do e.note.Text = "" end refreshPages() end)
saveB.MouseButton1Click:Connect(function()
	if not target then return end
	if countPending() == 0 then notify("Nothing to save", false) return end
	saveB.Text = "Saving..."
	local r = call("save", { userId = target.userId, changes = pending })
	saveB.Text = "💾  Save Changes"
	notify(r.msg, r.ok)
	if r.ok then pending = {} reselect() end
end)

---------------------------------------------------------------- PLAYER RECORDS
-- 🟢 Online now   : everyone online in every server, which server, where on campus, time in
-- 📚 All players  : every player who has joined (by user ID) with their progress and last seen
-- 🕒 Time in / out: everyone's recent time in / time out, or one player's full log
local DARK = Color3.fromRGB(40, 30, 10)
local GREEN_T = Color3.fromRGB(140, 240, 170)
local RED_T = Color3.fromRGB(255, 150, 150)
local recB = button(head, "📋  Player Records", C.gold, UDim2.fromOffset(178, 36), { AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -58, 0.5, 0), TextColor3 = DARK, TextSize = 14, Font = Enum.Font.GothamBlack })
local recView = frame(panel, UDim2.new(1, -24, 1, -78), UDim2.fromOffset(12, 68), C.bg, "PlayerRecords")
recView.BackgroundTransparency = 1 recView.Visible = false
local recBar = frame(recView, UDim2.new(1, 0, 0, 36), nil, C.bg) recBar.BackgroundTransparency = 1 list(recBar, 6, true)
local recBody = frame(recView, UDim2.new(1, 0, 1, -44), UDim2.fromOffset(0, 44), C.panel) corner(recBody, 12)

local recPages, recTabs, recTab = {}, {}, "Online"
local recMode, recLogUser, recAllSort, recAllRows = false, nil, "seen", {}
local showRec, loadAll -- forward
local function recPage(key, text, order)
	local sf = Instance.new("ScrollingFrame") sf.Name = key sf.Size = UDim2.fromScale(1, 1) sf.BackgroundTransparency = 1 sf.BorderSizePixel = 0
	sf.ScrollBarThickness = 6 sf.AutomaticCanvasSize = Enum.AutomaticSize.Y sf.CanvasSize = UDim2.new() sf.Visible = false sf.Parent = recBody
	pad(sf, 10) list(sf, 6)
	local b = button(recBar, text, C.card, UDim2.fromOffset(140, 34), { LayoutOrder = order, TextSize = 13 })
	recPages[key] = sf recTabs[key] = b
	b.MouseButton1Click:Connect(function() if key == "Log" then recLogUser = nil end showRec(key) end)
	return sf
end
local rOnline = recPage("Online", "🟢  Online now", 1)
local rAll = recPage("All", "📚  All players", 2)
local rLog = recPage("Log", "🕒  Time in / out", 3)
local recSearch = textbox(recBar, "Find a player: username or ID", UDim2.fromOffset(250, 34)) recSearch.LayoutOrder = 4
local recFindB = button(recBar, "Show log", C.green2, UDim2.fromOffset(90, 34), { LayoutOrder = 5, TextSize = 13 })
local recRefreshB = button(recBar, "Refresh", C.card, UDim2.fromOffset(110, 34), { LayoutOrder = 6, TextSize = 13 })

local function clearKids(o) for _, c in ipairs(o:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end end
local function cell(parent, text, w, col, font, size, order)
	return label(parent, tostring(text), size or 12, font or Enum.Font.Gotham, col or C.text,
		{ Size = UDim2.fromOffset(w, 34), TextWrapped = false, TextTruncate = Enum.TextTruncate.AtEnd, LayoutOrder = order or 0 })
end
local function tableRow(parent, h, order, shaded)
	local r = frame(parent, UDim2.new(1, 0, 0, h or 40), nil, C.input) r.LayoutOrder = order or 0
	r.BackgroundTransparency = shaded and 0.35 or 1 corner(r, 8)
	local p = Instance.new("UIPadding") p.PaddingLeft = UDim.new(0, 6) p.PaddingRight = UDim.new(0, 6) p.Parent = r
	list(r, 5, true)
	return r
end
local function headerRow(parent, cols, order)
	local r = tableRow(parent, 22, order)
	for i, c in ipairs(cols) do cell(r, c[1], c[2], C.dim, Enum.Font.GothamBlack, 11, i) end
	return r
end
local function personCell(parent, userId, top, bottom, w, order)
	local f = frame(parent, UDim2.fromOffset(w, 36), nil, C.card) f.BackgroundTransparency = 1 f.LayoutOrder = order or 0
	local img = Instance.new("ImageLabel") img.Size = UDim2.fromOffset(30, 30) img.Position = UDim2.fromOffset(0, 3) img.BackgroundColor3 = C.card
	img.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(userId) .. "&w=48&h=48" img.Parent = f corner(img, 15)
	label(f, top, 13, Enum.Font.GothamBold, C.text, { Position = UDim2.fromOffset(36, 1), Size = UDim2.new(1, -36, 0, 17), TextWrapped = false, TextTruncate = Enum.TextTruncate.AtEnd })
	label(f, bottom, 11, Enum.Font.Gotham, C.dim, { Position = UDim2.fromOffset(36, 19), Size = UDim2.new(1, -36, 0, 15), TextWrapped = false, TextTruncate = Enum.TextTruncate.AtEnd })
	return f
end
local function smallBtn(parent, text, col, w, order, fn)
	local b = button(parent, text, col, UDim2.fromOffset(w, 28), { TextSize = 12, LayoutOrder = order })
	b.MouseButton1Click:Connect(fn)
	return b
end
local function note(parent, text, col, order)
	local l = label(parent, text, 12, Enum.Font.Gotham, col or C.dim) l.LayoutOrder = order or 0 return l
end
local function syncClock(res) if type(res) == "table" and type(res.now) == "number" then serverOffset = res.now - os.time() end end

local function setMode(records)
	recMode = records
	left.Visible = not records right.Visible = not records recView.Visible = records
	recB.Text = records and "🛡  Manage player" or "📋  Player Records"
	if records then showRec(recTab) end
end
recB.MouseButton1Click:Connect(function() setMode(not recMode) end)
local function openLog(who)
	recLogUser = who recTab = "Log"
	if recMode then showRec("Log") else setMode(true) end
end
local function manage(userId) setMode(false) select(tostring(userId)) end
local function goTo(userId) local x = call("rec_goto", { userId = userId }) notify(x.msg, x.ok) end
local function joinServer(job) local x = call("rec_join", { job = job }) notify(x.msg, x.ok) end

-- time out text, colour and how long they stayed
local function sessionOut(e, onlineSince)
	if e.o then
		local sameDay = fmtDay(e.o) == fmtDay(e.i)
		return sameDay and fmtClock(e.o) or fmtWhen(e.o), C.text, fmtDur(e.o - e.i)
	elseif onlineSince and e.i == onlineSince then
		return "🟢 still online", GREEN_T, fmtDur(nowS() - e.i)
	end
	return "not recorded", C.dim, "—"
end

-- 🟢 ONLINE NOW
local loadingOnline = false
local function loadOnline(keepScroll)
	if loadingOnline then return end
	loadingOnline = true
	local pos = rOnline.CanvasPosition
	if not keepScroll then clearKids(rOnline) note(rOnline, "Loading who is online...") end
	local res = call("rec_online", {})
	loadingOnline = false
	clearKids(rOnline)
	if not res.ok then note(rOnline, res.msg or "Couldn't load", RED_T) return end
	syncClock(res)
	local np, ns = #res.players, #res.servers
	label(rOnline, string.format("🟢  %d player%s online in %d server%s", np, np == 1 and "" or "s", ns, ns == 1 and "" or "s"),
		16, Enum.Font.GothamBlack, C.text).LayoutOrder = 0
	note(rOnline, (res.live and "Live from every server, refreshes by itself every 15 s." or
		"Studio test: only this server is shown and nothing is saved (turn on API access for the real data).") ..
		"  Times are in your time zone.", nil, 1)
	for si, s in ipairs(res.servers) do
		local card = cardSection(rOnline, "🖥  Server " .. tostring(s.sc) .. (s.here and "   •   you are here" or ""), 10 + si)
		local top = row(card, 30, 0)
		local info = string.format("%s  •  %s  •  %d%s players", tostring(s.pk or "Main campus"), tostring(s.kind or "Public"),
			s.count or 0, s.max and ("/" .. s.max) or "")
		if s.start then info ..= "  •  running " .. fmtDur(nowS() - s.start) end
		label(top, info, 12, Enum.Font.GothamBold, C.dim, { Size = UDim2.fromOffset(600, 30), TextWrapped = false, LayoutOrder = 1 })
		if not s.here then smallBtn(top, "Join this server", C.blue, 140, 2, function() joinServer(s.job) end) end
		headerRow(card, { { "Player", 200 }, { "📍 Where on campus", 200 }, { "Time in", 66 }, { "Online for", 64 }, { "Title", 100 } }, 1)
		local mine = {}
		for _, p in ipairs(res.players) do if p.job == s.job then table.insert(mine, p) end end
		table.sort(mine, function(a, b) return (a.t or 0) < (b.t or 0) end)
		if #mine == 0 then note(card, "Nobody in this server right now.", nil, 2) end
		for i, p in ipairs(mine) do
			local r = tableRow(card, 40, 1 + i, i % 2 == 1)
			personCell(r, p.u, tostring(p.d or p.n) .. (p.u == player.UserId and "  (you)" or ""), "@" .. tostring(p.n) .. "  •  ID " .. tostring(p.u), 200, 1)
			cell(r, p.a or "—", 200, C.text, Enum.Font.GothamBold, 12, 2)
			cell(r, fmtClock(p.t), 66, C.text, nil, 12, 3)
			cell(r, fmtDur(nowS() - (p.t or nowS())), 64, GREEN_T, Enum.Font.GothamBold, 12, 4)
			cell(r, p.title or "—", 100, C.gold, Enum.Font.GothamBold, 12, 5)
			if s.here and p.u ~= player.UserId then smallBtn(r, "Go to", C.blue, 54, 6, function() goTo(p.u) end) end
			smallBtn(r, "Log", C.card, 44, 7, function() openLog(p.u) end)
			smallBtn(r, "Manage", C.green2, 64, 8, function() manage(p.u) end)
		end
	end
	if keepScroll then task.delay(0.05, function() rOnline.CanvasPosition = pos end) end
end

-- 📚 ALL PLAYERS
local function renderAll(res)
	clearKids(rAll)
	local ctl = row(rAll, 30, 0)
	smallBtn(ctl, "🕒  Last seen", recAllSort == "seen" and C.green or C.card, 130, 1, function()
		if recAllSort ~= "seen" then recAllSort = "seen" loadAll(false) end
	end)
	smallBtn(ctl, "🏆  Most time played", recAllSort == "time" and C.green or C.card, 190, 2, function()
		if recAllSort ~= "time" then recAllSort = "time" loadAll(false) end
	end)
	if META and META.role == "Owner" then
		smallBtn(ctl, "+  Add older saves", C.card, 160, 3, function() local r = call("rec_backfill", {}) notify(r.msg, r.ok) end)
	end
	note(rAll, "Every player who has joined, with their saved progress. Log = their time in / time out. Times are in your time zone." ..
		(res.note and ("\n" .. tostring(res.note)) or ""), nil, 1)
	if not res.ok then note(rAll, res.msg or "Couldn't load the list", RED_T, 2) return end
	if res.live == false then note(rAll, "Studio test: only players from this test session are listed (turn on API access for the real list).", C.gold, 2) end
	headerRow(rAll, { { "Player", 210 }, { "Title", 96 }, { "Time played", 76 }, { "Coins C / E", 80 }, { "Joins", 40 }, { "First joined", 92 }, { "Last seen", 130 } }, 3)
	if #recAllRows == 0 then note(rAll, "No players yet.", nil, 4) end
	for i, r in ipairs(recAllRows) do
		local tr = tableRow(rAll, 40, 10 + i, i % 2 == 1)
		personCell(tr, r.u, tostring(r.d or r.n), "@" .. tostring(r.n) .. "  •  ID " .. tostring(r.u), 210, 1)
		cell(tr, r.title or "—", 96, C.gold, Enum.Font.GothamBold, 12, 2)
		cell(tr, r.tm and fmtDur(r.tm) or "—", 76, C.text, nil, 12, 3)
		cell(tr, (r.cc and tostring(r.cc) or "—") .. " / " .. (r.ec and tostring(r.ec) or "—"), 80, C.text, nil, 12, 4)
		cell(tr, r.count and tostring(r.count) or "—", 40, C.text, nil, 12, 5)
		cell(tr, r.first and fmtDay(r.first) or "—", 92, C.text, nil, 12, 6)
		local last, col, font
		if r.on then
			last, col, font = (r.here and "🟢 Online here" or ("🟢 Online • " .. tostring(r.sc))), GREEN_T, Enum.Font.GothamBold
		else
			local t = r.lastOut or r.seen
			last, col = (t and t > 0) and fmtWhen(t) or "before records", C.text
		end
		cell(tr, last, 130, col, font, 12, 7)
		smallBtn(tr, "Log", C.card, 44, 8, function() openLog(r.u) end)
		smallBtn(tr, "Manage", C.green2, 64, 9, function() manage(r.u) end)
	end
	if res.more then smallBtn(rAll, "Load more players", C.card, 200, 9999, function() loadAll(true) end) end
	note(rAll, "Showing " .. #recAllRows .. " player" .. (#recAllRows == 1 and "" or "s") .. (res.more and " (more below the button)" or ""), nil, 10000)
end

local loadingAll = false
function loadAll(more)
	if loadingAll then return end
	loadingAll = true
	if not more then recAllRows = {} clearKids(rAll) note(rAll, "Loading players...") end
	local res = call("rec_list", { sort = recAllSort, more = more == true })
	loadingAll = false
	syncClock(res)
	if res.ok then for _, r in ipairs(res.rows or {}) do table.insert(recAllRows, r) end end
	local pos = rAll.CanvasPosition
	renderAll(res)
	if more then task.delay(0.05, function() rAll.CanvasPosition = pos end) end
end

-- 🕒 TIME IN / OUT
local function renderFeed(res)
	clearKids(rLog)
	if not res.ok then note(rLog, res.msg or "Couldn't load", RED_T) return end
	label(rLog, "🕒  Recent time in / time out — everyone, last " .. tostring(res.days or 3) .. " days", 16, Enum.Font.GothamBlack, C.text).LayoutOrder = 0
	note(rLog, "Newest first. Times are in your time zone. Press Log to see one player's full history." ..
		(res.live == false and "\nStudio test: only this test session is shown." or ""), nil, 1)
	headerRow(rLog, { { "Player", 200 }, { "Date", 100 }, { "Time in", 70 }, { "Time out", 120 }, { "Stayed", 76 }, { "Server", 90 } }, 2)
	if #res.items == 0 then note(rLog, "No time in / time out yet.", nil, 3) end
	for i, e in ipairs(res.items) do
		local tr = tableRow(rLog, 40, 10 + i, i % 2 == 1)
		personCell(tr, e.u, tostring(e.d or e.n), "@" .. tostring(e.n) .. "  •  ID " .. tostring(e.u), 200, 1)
		cell(tr, fmtDay(e.i), 100, C.text, nil, 12, 2)
		cell(tr, fmtClock(e.i), 70, C.text, Enum.Font.GothamBold, 12, 3)
		local outText, outCol, stayed = sessionOut(e, e.on and e.i or nil)
		cell(tr, outText, 120, outCol, Enum.Font.GothamBold, 12, 4)
		cell(tr, stayed, 76, C.text, nil, 12, 5)
		cell(tr, tostring(e.s or "—"), 90, C.dim, nil, 12, 6)
		smallBtn(tr, "Log", C.card, 44, 7, function() openLog(e.u) end)
		smallBtn(tr, "Manage", C.green2, 64, 8, function() manage(e.u) end)
	end
end

local function renderHistory(res)
	clearKids(rLog)
	local top = row(rLog, 30, 0)
	smallBtn(top, "←  Everyone's recent time in / out", C.card, 250, 1, function() recLogUser = nil showRec("Log") end)
	if not res.ok then note(rLog, res.msg or "Couldn't load", RED_T, 1) return end
	recLogUser = res.u
	local card = cardSection(rLog, "👤  " .. tostring(res.d or res.n) .. "   (@" .. tostring(res.n) .. "  •  ID " .. tostring(res.u) .. ")", 1)
	local body = row(card, 64, 0)
	local img = Instance.new("ImageLabel") img.Size = UDim2.fromOffset(60, 60) img.BackgroundColor3 = C.input img.LayoutOrder = 1
	img.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(res.u) .. "&w=150&h=150" img.Parent = body corner(img, 30)
	local info = frame(body, UDim2.fromOffset(760, 64), nil, C.card) info.BackgroundTransparency = 1 info.LayoutOrder = 2 list(info, 3)
	local status
	if res.on then
		status = "🟢 Online now — server " .. tostring(res.sc) .. (res.here and " (this server)" or "") .. "   •   📍 " .. tostring(res.a or "—") ..
			"   •   time in " .. fmtClock(res.t) .. " (" .. fmtDur(nowS() - (res.t or nowS())) .. " ago)"
	else
		status = "⚪ Offline   •   last time out " .. (res.lastOut and (fmtWhen(res.lastOut) .. " (" .. ago(res.lastOut) .. ")") or "—")
	end
	local lineProps = function(o) return { Size = UDim2.new(1, 0, 0, 18), TextWrapped = false, TextTruncate = Enum.TextTruncate.AtEnd, LayoutOrder = o } end
	label(info, status, 13, Enum.Font.GothamBold, res.on and GREEN_T or C.text, lineProps(1))
	label(info, "First joined " .. fmtWhen(res.first) .. "   •   Joins: " .. tostring(res.count or 0) .. "   •   Last time in " .. fmtWhen(res.lastIn),
		12, Enum.Font.Gotham, C.dim, lineProps(2))
	local s = res.sum or {}
	label(info, "🎓 " .. tostring(s.title or "—") .. "   •   🕒 " .. (s.time and fmtDur(s.time) or "—") .. " on campus   •   Common coins " ..
		tostring(s.common or "—") .. "   •   Event coins " .. tostring(s.event or "—"), 12, Enum.Font.GothamBold, C.gold, lineProps(3))
	local btns = row(card, 30, 1)
	smallBtn(btns, "Manage player", C.green2, 130, 1, function() manage(res.u) end)
	if res.on and res.here and res.u ~= player.UserId then
		smallBtn(btns, "Go to", C.blue, 80, 2, function() goTo(res.u) end)
	elseif res.on and not res.here and res.job then
		smallBtn(btns, "Join their server", C.blue, 150, 2, function() joinServer(res.job) end)
	end
	if not res.known then note(card, "No time in / time out saved yet: this player hasn't joined since Player Records was added.", C.gold, 2) end
	if res.live == false then note(card, "Studio test: only this test session is shown.", C.gold, 3) end

	local logCard = cardSection(rLog, "🕒  Time in / time out (last " .. #res.log .. (#res.log == 1 and " visit)" or " visits)"), 2)
	headerRow(logCard, { { "#", 30 }, { "Date", 110 }, { "Time in", 80 }, { "Time out", 130 }, { "Stayed", 80 }, { "Server", 90 }, { "Place", 120 } }, 0)
	if #res.log == 0 then note(logCard, "No visits yet.", nil, 1) end
	for i, e in ipairs(res.log) do
		local tr = tableRow(logCard, 34, i, i % 2 == 1)
		cell(tr, tostring(i), 30, C.dim, nil, 12, 1)
		cell(tr, fmtDay(e.i), 110, C.text, nil, 12, 2)
		cell(tr, fmtClock(e.i), 80, C.text, Enum.Font.GothamBold, 12, 3)
		local outText, outCol, stayed = sessionOut(e, res.on and res.t or nil)
		cell(tr, outText, 130, outCol, Enum.Font.GothamBold, 12, 4)
		cell(tr, stayed, 80, C.text, nil, 12, 5)
		cell(tr, tostring(e.s or "—"), 90, C.dim, nil, 12, 6)
		cell(tr, tostring(e.p or "—"), 120, C.dim, nil, 12, 7)
	end
end

local loadingLog = false
local function loadLog()
	if loadingLog then return end
	loadingLog = true
	clearKids(rLog) note(rLog, "Loading...")
	if recLogUser then
		local res = call("rec_history", type(recLogUser) == "number" and { userId = recLogUser } or { query = tostring(recLogUser) })
		loadingLog = false
		syncClock(res)
		renderHistory(res)
	else
		local res = call("rec_activity", {})
		loadingLog = false
		syncClock(res)
		renderFeed(res)
	end
end

function showRec(key)
	recTab = key
	for k, f in pairs(recPages) do
		f.Visible = k == key
		recTabs[k].BackgroundColor3 = k == key and C.green or C.card
	end
	if key == "Online" then task.spawn(loadOnline) elseif key == "All" then task.spawn(loadAll, false) else task.spawn(loadLog) end
end

local function findLog()
	local q = recSearch.Text:gsub("^%s+", ""):gsub("%s+$", "")
	if q == "" then notify("Type a username or user ID", false) return end
	openLog(q)
end
recFindB.MouseButton1Click:Connect(findLog)
recSearch.FocusLost:Connect(function(enter) if enter then findLog() end end)
recRefreshB.MouseButton1Click:Connect(function() showRec(recTab) end)

-- "Time in / out" button on the selected player's card
nameL.Size = UDim2.new(1, -250, 0, 24)
chipsL.TextWrapped = false chipsL.TextTruncate = Enum.TextTruncate.AtEnd
local cardLogB = button(cardP, "🕒  Time in / out", C.card, UDim2.fromOffset(140, 28), { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10), TextSize = 12 })
cardLogB.MouseButton1Click:Connect(function()
	if target then openLog(target.userId) else notify("Select a player first", false) end
end)

-- Online now refreshes itself while it is open
task.spawn(function()
	while gui.Parent do
		task.wait(15)
		if panel.Visible and recMode and recTab == "Online" then loadOnline(true) end
	end
end)

---------------------------------------------------------------- open / close
local function open()
	if not META then
		META = call("init", {})
		if not META.ok then notify(META.msg or "Not allowed", false) META = nil return end
		buildFromMeta()
		roleL.Text = "TEAM PRUC • Samar College   —   You are: " .. META.role .. (META.studio and "   (Studio test: saving needs API access)" or "")
		renderPlayers(META.players)
		showPage("Moderation")
		refreshPages()
	else
		local r = call("players", {}) if r.ok then renderPlayers(r.players) end
	end
	loadAdmins()
	task.spawn(loadBans)
	if recMode then showRec(recTab) end
	dim.Visible = true panel.Visible = true
end
local function close() panel.Visible = false dim.Visible = false end
closeB.MouseButton1Click:Connect(close)
UIS.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.F2 then if panel.Visible then close() else open() end end
end)

-- an "Admin" button on the left HUD rail (copied from the Map button's style)
task.spawn(function()
	local hud = player:WaitForChild("PlayerGui"):WaitForChild("MainHUD", 15)
	local rail = hud and hud:FindFirstChild("Rail")
	local tmpl = rail and rail:FindFirstChild("MapButton")
	if not tmpl or rail:FindFirstChild("AdminButton") then return end
	local b = tmpl:Clone() b.Name = "AdminButton" b.LayoutOrder = 10
	for _, d in ipairs(b:GetDescendants()) do if d:IsA("LuaSourceContainer") then d:Destroy() end end
	if b:FindFirstChild("Icon") then b.Icon.Text = "🛡" end
	if b:FindFirstChild("Caption") then b.Caption.Text = "Admin" end
	local st = b:FindFirstChildOfClass("UIStroke") if st then st.Color = C.gold end
	b.Parent = rail
	b.MouseButton1Click:Connect(function() if panel.Visible then close() else open() end end)
	gui.Destroying:Connect(function() b:Destroy() end)
end)
refreshPages()
