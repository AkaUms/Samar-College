-- HotbarClient: bottom inventory hotbar (keys 1-9 / tap).
-- Equipment & Cosmetic: press to equip / unequip.  Flashlight: press again to hold / put away.
-- Consumable: press to use one (shows count).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local gui = script.Parent
local shopItems = require(RS:WaitForChild("ShopItems"))
local remotes = RS:WaitForChild("ShopRemotes")
local equipRemote = remotes:WaitForChild("EquipItem")
local useRemote = remotes:WaitForChild("UseItem")

pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) end)

local SLOTS = 9
local C = {
	panel = Color3.fromRGB(22, 26, 36), slot = Color3.fromRGB(34, 40, 54), slotHover = Color3.fromRGB(46, 54, 72),
	stroke = Color3.fromRGB(70, 82, 104), equip = Color3.fromRGB(72, 214, 120), consume = Color3.fromRGB(255, 196, 64),
	cosmetic = Color3.fromRGB(176, 132, 255), equipment = Color3.fromRGB(86, 170, 255), text = Color3.fromRGB(235, 240, 248), dim = Color3.fromRGB(140, 150, 170),
}
local CAT_COLOR = { Equipment = C.equipment, Consumable = C.consume, Cosmetic = C.cosmetic }

local function corner(p, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r) c.Parent = p return c end
local function stroke(p, col, t) local s = Instance.new("UIStroke") s.Color = col s.Thickness = t or 1.5 s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border s.Parent = p return s end

-- ===== layout =====
local holder = Instance.new("Frame") holder.Name = "Hotbar" holder.AnchorPoint = Vector2.new(0.5, 1)
holder.Position = UDim2.new(0.5, 0, 1, -14) holder.Size = UDim2.fromOffset(SLOTS * 62 + 24, 84)
holder.BackgroundColor3 = C.panel holder.BackgroundTransparency = 0.18 holder.Parent = gui
corner(holder, 16) stroke(holder, C.stroke, 1.2)
local scale = Instance.new("UIScale") scale.Parent = holder
local function rescale() local w = workspace.CurrentCamera.ViewportSize.X scale.Scale = math.clamp(w / (SLOTS * 62 + 60), 0.55, 1) end
rescale() workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)

local title = Instance.new("TextLabel") title.Name = "Title" title.BackgroundTransparency = 1
title.AnchorPoint = Vector2.new(0, 1) title.Position = UDim2.new(0, 14, 0, -2) title.Size = UDim2.fromOffset(260, 20)
title.Font = Enum.Font.GothamBold title.TextSize = 13 title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = C.text title.Text = "🎒 INVENTORY" title.TextStrokeTransparency = 0.6 title.Parent = holder
local hint = title:Clone() hint.Name = "Hint" hint.AnchorPoint = Vector2.new(1, 1) hint.Position = UDim2.new(1, -14, 0, -2)
hint.TextXAlignment = Enum.TextXAlignment.Right hint.Font = Enum.Font.Gotham hint.TextSize = 12 hint.TextColor3 = C.dim
hint.Text = "1-9 to use  •  [I] Bag" hint.Parent = holder

local row = Instance.new("Frame") row.BackgroundTransparency = 1 row.Position = UDim2.fromOffset(12, 12) row.Size = UDim2.new(1, -24, 0, 58) row.Parent = holder
local lay = Instance.new("UIListLayout") lay.FillDirection = Enum.FillDirection.Horizontal lay.Padding = UDim.new(0, 6)
lay.HorizontalAlignment = Enum.HorizontalAlignment.Center lay.Parent = row

-- tooltip
local tip = Instance.new("Frame") tip.Name = "Tooltip" tip.AnchorPoint = Vector2.new(0.5, 1) tip.Size = UDim2.fromOffset(190, 52)
tip.BackgroundColor3 = C.panel tip.BackgroundTransparency = 0.05 tip.Visible = false tip.ZIndex = 20 tip.Parent = gui
corner(tip, 10) local tipStroke = stroke(tip, C.stroke, 1.2)
local tipName = Instance.new("TextLabel") tipName.BackgroundTransparency = 1 tipName.Position = UDim2.fromOffset(10, 6) tipName.Size = UDim2.new(1, -20, 0, 18)
tipName.Font = Enum.Font.GothamBold tipName.TextSize = 14 tipName.TextColor3 = C.text tipName.TextXAlignment = Enum.TextXAlignment.Left tipName.ZIndex = 21 tipName.Parent = tip
local tipDesc = tipName:Clone() tipDesc.Position = UDim2.fromOffset(10, 25) tipDesc.Size = UDim2.new(1, -20, 0, 20)
tipDesc.Font = Enum.Font.Gotham tipDesc.TextSize = 11 tipDesc.TextColor3 = C.dim tipDesc.TextWrapped = true tipDesc.Parent = tip

local slots = {}
for i = 1, SLOTS do
	local b = Instance.new("TextButton") b.Name = "Slot" .. i b.Size = UDim2.fromOffset(56, 56) b.AutoButtonColor = false
	b.BackgroundColor3 = C.slot b.Text = "" b.LayoutOrder = i b.Parent = row
	corner(b, 12) local st = stroke(b, C.stroke, 1.5)
	local icon = Instance.new("TextLabel") icon.Name = "Icon" icon.BackgroundTransparency = 1 icon.Size = UDim2.new(1, 0, 1, -6)
	icon.Font = Enum.Font.GothamBold icon.TextScaled = true icon.Text = "" icon.Parent = b
	local pad = Instance.new("UIPadding") pad.PaddingTop = UDim.new(0, 9) pad.PaddingBottom = UDim.new(0, 4) pad.PaddingLeft = UDim.new(0, 10) pad.PaddingRight = UDim.new(0, 10) pad.Parent = icon
	local key = Instance.new("TextLabel") key.Name = "Key" key.BackgroundTransparency = 1 key.Position = UDim2.fromOffset(5, 2) key.Size = UDim2.fromOffset(14, 14)
	key.Font = Enum.Font.GothamBold key.TextSize = 11 key.TextColor3 = C.dim key.Text = tostring(i) key.TextXAlignment = Enum.TextXAlignment.Left key.Parent = b
	local count = Instance.new("TextLabel") count.Name = "Count" count.AnchorPoint = Vector2.new(1, 1) count.Position = UDim2.new(1, -3, 1, -3)
	count.Size = UDim2.fromOffset(26, 15) count.BackgroundColor3 = C.consume count.Font = Enum.Font.GothamBlack count.TextSize = 10
	count.TextColor3 = Color3.fromRGB(30, 24, 10) count.Visible = false count.Parent = b corner(count, 6)
	local eq = Instance.new("TextLabel") eq.Name = "EquippedTag" eq.AnchorPoint = Vector2.new(1, 0) eq.Position = UDim2.new(1, -3, 0, 3)
	eq.Size = UDim2.fromOffset(16, 16) eq.BackgroundColor3 = C.equip eq.Font = Enum.Font.GothamBlack eq.TextSize = 11 eq.Text = "✓"
	eq.TextColor3 = Color3.fromRGB(10, 40, 20) eq.Visible = false eq.Parent = b corner(eq, 8)
	local bar = Instance.new("Frame") bar.Name = "CatBar" bar.AnchorPoint = Vector2.new(0.5, 1) bar.Position = UDim2.new(0.5, 0, 1, -1)
	bar.Size = UDim2.new(0.5, 0, 0, 3) bar.BorderSizePixel = 0 bar.BackgroundTransparency = 1 bar.Parent = b corner(bar, 2)
	slots[i] = { button = b, stroke = st, icon = icon, count = count, eq = eq, bar = bar, item = nil, cat = nil }
end

local empty = Instance.new("TextLabel") empty.BackgroundTransparency = 1 empty.Size = UDim2.new(1, 0, 1, 0) empty.Font = Enum.Font.Gotham
empty.TextSize = 13 empty.TextColor3 = C.dim empty.Text = "No items yet — visit the Shop to buy items!" empty.Visible = false empty.ZIndex = 5 empty.Position = UDim2.fromOffset(0, 12) empty.Size = UDim2.new(1, 0, 0, 58) empty.Parent = holder

-- ===== data =====
local function countOf(id) local inv = player:FindFirstChild("Inventory") local v = inv and inv:FindFirstChild(id) return v and v.Value or 0 end
local function collect()
	local list = {}
	for _, cat in ipairs({ "Equipment", "Consumable", "Cosmetic" }) do
		for _, it in ipairs(shopItems[cat] or {}) do
			if cat == "Consumable" then if countOf(it.Id) > 0 then table.insert(list, { it, cat }) end
			elseif player:GetAttribute("Owned_" .. it.Id) then table.insert(list, { it, cat }) end
		end
	end
	return list
end

local function holdingTool(name) local ch = player.Character return ch and ch:FindFirstChild(name) and ch[name]:IsA("Tool") end

local function refresh()
	local list = collect()
	empty.Visible = (#list == 0)
	for i, s in ipairs(slots) do
		local e = list[i]
		s.item, s.cat = e and e[1] or nil, e and e[2] or nil
		s.button.Visible = (#list > 0)
		if s.item then
			local equipped = player:GetAttribute("Equipped_" .. s.item.Id) == true
			s.icon.Text = s.item.Icon or "?"
			s.icon.TextTransparency = 0
			s.bar.BackgroundTransparency = 0 s.bar.BackgroundColor3 = CAT_COLOR[s.cat] or C.stroke
			s.eq.Visible = equipped
			s.eq.Text = (s.item.Id == "Flashlight" and holdingTool("Flashlight")) and "✋" or "✓"
			s.stroke.Color = equipped and C.equip or C.stroke s.stroke.Thickness = equipped and 2.4 or 1.5
			if s.cat == "Consumable" then s.count.Visible = true s.count.Text = "x" .. countOf(s.item.Id) else s.count.Visible = false end
		else
			s.icon.Text = "" s.count.Visible = false s.eq.Visible = false s.bar.BackgroundTransparency = 1
			s.stroke.Color = C.stroke s.stroke.Thickness = 1.5
		end
		s.button.BackgroundTransparency = s.item and 0 or 0.45
	end
	local total = #list
	hint.Text = (total > SLOTS and ("+" .. (total - SLOTS) .. " more in Bag  •  ") or "") .. "1-9 to use  •  [I] Bag"
end

local function pulse(s, col)
	s.button.BackgroundColor3 = col
	TweenService:Create(s.button, TweenInfo.new(0.35), { BackgroundColor3 = C.slot }):Play()
	local sc = s.button:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", s.button)
	sc.Scale = 0.88 TweenService:Create(sc, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end

local busy = {}
local function activate(i)
	local s = slots[i] if not s or not s.item then return end
	if busy[i] then return end busy[i] = true task.delay(0.35, function() busy[i] = nil end)
	local id = s.item.Id
	if s.cat == "Consumable" then
		useRemote:FireServer(id) pulse(s, C.consume)
	elseif id == "Flashlight" and player:GetAttribute("Equipped_Flashlight") then
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		local bp = player:FindFirstChild("Backpack")
		if hum then
			if holdingTool("Flashlight") then hum:UnequipTools()
			elseif bp and bp:FindFirstChild("Flashlight") then hum:EquipTool(bp.Flashlight) end
		end
		pulse(s, C.equipment) task.delay(0.15, refresh)
	else
		equipRemote:FireServer(id) pulse(s, CAT_COLOR[s.cat] or C.equip)
	end
end

for i, s in ipairs(slots) do
	s.button.MouseButton1Click:Connect(function() activate(i) end)
	s.button.MouseEnter:Connect(function()
		if not s.item then return end
		s.button.BackgroundColor3 = C.slotHover
		tipName.Text = s.item.Name
		local how = s.cat == "Consumable" and "Press to use" or (player:GetAttribute("Equipped_" .. s.item.Id) and "Press to unequip" or "Press to equip")
		if s.item.Id == "Flashlight" and player:GetAttribute("Equipped_Flashlight") then how = "Press to hold / put away" end
		tipDesc.Text = (s.item.Desc or s.cat) .. "  •  " .. how
		tipStroke.Color = CAT_COLOR[s.cat] or C.stroke
		local abs = s.button.AbsolutePosition local sz = s.button.AbsoluteSize
		tip.Position = UDim2.fromOffset(abs.X + sz.X / 2, abs.Y - 8 + (gui.IgnoreGuiInset and 0 or 0))
		tip.Visible = true
	end)
	s.button.MouseLeave:Connect(function() s.button.BackgroundColor3 = C.slot tip.Visible = false end)
end

local KEYS = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five, Enum.KeyCode.Six, Enum.KeyCode.Seven, Enum.KeyCode.Eight, Enum.KeyCode.Nine }
UIS.InputBegan:Connect(function(input, processed)
	if processed then return end
	for i, k in ipairs(KEYS) do if input.KeyCode == k then activate(i) return end end
end)

-- ===== live updates =====
player.AttributeChanged:Connect(function(n) if n:sub(1, 6) == "Owned_" or n:sub(1, 9) == "Equipped_" then refresh() end end)
local function hookInv(inv)
	inv.ChildAdded:Connect(function(v) if v:IsA("IntValue") then v.Changed:Connect(refresh) end refresh() end)
	inv.ChildRemoved:Connect(refresh)
	for _, v in ipairs(inv:GetChildren()) do if v:IsA("IntValue") then v.Changed:Connect(refresh) end end
end
local inv = player:FindFirstChild("Inventory") if inv then hookInv(inv) end
player.ChildAdded:Connect(function(c) if c.Name == "Inventory" then hookInv(c) refresh() end end)
player.CharacterAdded:Connect(function(ch) ch.ChildAdded:Connect(refresh) ch.ChildRemoved:Connect(refresh) task.wait(1) refresh() end)
if player.Character then player.Character.ChildAdded:Connect(refresh) player.Character.ChildRemoved:Connect(refresh) end
refresh()
