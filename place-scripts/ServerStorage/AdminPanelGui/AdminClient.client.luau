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
	for k, v in pairs(props or {}) do l[k] = v end l.Parent = parent return l
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

---------------------------------------------------------------- shell
local dim = frame(gui, UDim2.fromScale(1, 1), nil, Color3.new(0, 0, 0)) dim.BackgroundTransparency = 0.45 dim.Visible = false dim.Active = true
local panel = frame(gui, UDim2.fromOffset(940, 600), UDim2.fromScale(0.5, 0.5), C.bg, "AdminPanel")
panel.AnchorPoint = Vector2.new(0.5, 0.5) panel.Visible = false corner(panel, 16) stroke(panel, C.gold, 1.6)
local scale = Instance.new("UIScale") scale.Parent = panel
local function rescale() local v = workspace.CurrentCamera.ViewportSize scale.Scale = math.min(1, (v.X - 20) / 940, (v.Y - 30) / 600) end
rescale() workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)

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
	local b = button(tabsBar, name, C.card, UDim2.fromOffset(122, 32), { LayoutOrder = order, TextSize = 13 })
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
local pAdmins = makePage("Admins", 5)

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

local resetCard = cardSection(pMod, "♻  Reset progress", 3)
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
	local chips = { target.online and "🟢 In this server" or "⚪ Not in this server", "Role: " .. target.role }
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
	notify(r.msg, r.ok) if r.ok then reselect() end
end)
unbanB.MouseButton1Click:Connect(function()
	if not target then return end
	local r = call("unban", { userId = target.userId }) notify(r.msg, r.ok) if r.ok then reselect() end
end)
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
