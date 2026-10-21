-- HUDClient.lua
-- Left rail (Bag, Map) + Settings button + one main panel.
-- Keys: [I] Bag, [M] Map. Other scripts can open a page with MainHUD.OpenPanel:Fire("Bag").

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local gui = script.Parent
local panel = gui:WaitForChild("Panel")
local pages = panel:WaitForChild("Pages")
local title = panel:WaitForChild("Title")
local subtitle = panel:WaitForChild("Subtitle")
local rail = gui:WaitForChild("Rail")
local settingsButton = gui:WaitForChild("SettingsButton")
local toast = gui:WaitForChild("Toast")
local confirm = gui:WaitForChild("Confirm")

local ACCENT = Color3.fromRGB(20, 140, 100)
local BG2 = Color3.fromRGB(42, 42, 55)
local STROKE = Color3.fromRGB(75, 75, 95)
local MUTED = Color3.fromRGB(165, 165, 180)
local GOOD = Color3.fromRGB(120, 220, 170)

------------------------------------------------------------ helpers
local toastToken = 0
local function showToast(message)
	if not message or message == "" then return end
	toastToken += 1
	local my = toastToken
	toast.Text = message
	toast.Visible = true
	task.delay(2.2, function() if toastToken == my then toast.Visible = false end end)
end

-- shrink everything on small (phone) screens
local scale = gui:WaitForChild("AutoScale")
local UIS_ = game:GetService("UserInputService")
local railLayout = rail:FindFirstChildOfClass("UIListLayout")
local function rescale()
	local v = gui.AbsoluteSize
	if v.Y < 2 then v = workspace.CurrentCamera.ViewportSize end
	local s = math.clamp(v.Y / 760, v.Y < 330 and 0.55 or 0.6, 1) -- short phones (Galaxy S/A) a bit smaller
	scale.Scale = s
	-- side buttons: size the rail to its buttons (Profile, Bag, Map, Admin)
	local contentH = railLayout and (railLayout.AbsoluteContentSize.Y / math.max(s, 0.01)) or 240
	rail.Size = UDim2.fromOffset(72, math.max(contentH, 60))
	if UIS_.TouchEnabled and v.Y < 700 then
		-- phones: keep the buttons near the top so the thumbstick (bottom-left) never covers them
		rail.AnchorPoint = Vector2.new(0, 0)
		rail.Position = UDim2.fromOffset(10, 6)
	else
		rail.AnchorPoint = Vector2.new(0, 0.5)
		rail.Position = UDim2.new(0, 14, 0.5, 0)
	end
end
rescale()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(rescale)
if railLayout then railLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(rescale) end

------------------------------------------------------------ page switching
local PAGES = {
	Bag = { frame = pages:WaitForChild("BagPage"), button = rail:WaitForChild("BagButton"), title = "Bag",
		sub = "Cosmetic = looks only · Equipment = has an effect · Consumable = used up" },
	Map = { frame = pages:WaitForChild("MapPage"), button = rail:WaitForChild("MapButton"), title = "Map",
		sub = "Tap a pin to see the place, tap again (or Go) to teleport" },
	Settings = { frame = pages:WaitForChild("SettingsPage"), button = settingsButton, title = "Settings", sub = "" },
}
local current = nil
local onOpen = {}

local function highlight(name)
	for key, page in pairs(PAGES) do
		local s = page.button:FindFirstChildOfClass("UIStroke")
		if s then
			s.Color = (key == name) and ACCENT or STROKE
			s.Thickness = (key == name) and 2.5 or 1.5
		end
	end
end

local function openPage(name)
	if current == name and panel.Visible then
		panel.Visible = false
		current = nil
		highlight(nil)
		return
	end
	current = name
	for key, page in pairs(PAGES) do page.frame.Visible = (key == name) end
	title.Text = PAGES[name].title
	subtitle.Text = PAGES[name].sub
	panel.Visible = true
	highlight(name)
	if onOpen[name] then onOpen[name]() end
end

local function closePanel()
	panel.Visible = false
	current = nil
	highlight(nil)
end

for key, page in pairs(PAGES) do
	page.button.MouseButton1Click:Connect(function() openPage(key) end)
end
panel:WaitForChild("CloseButton").MouseButton1Click:Connect(closePanel)
gui:WaitForChild("OpenPanel").Event:Connect(function(name)
	if PAGES[name] then current = nil openPage(name) end
end)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.I then openPage("Bag")
	elseif input.KeyCode == Enum.KeyCode.M then openPage("Map") end
end)

------------------------------------------------------------ BAG
local shopRemotes = ReplicatedStorage:WaitForChild("ShopRemotes")
local equipRemote = shopRemotes:WaitForChild("EquipItem")
local useRemote = shopRemotes:WaitForChild("UseItem")
local shopItems = require(ReplicatedStorage:WaitForChild("ShopItems"))

local bagPage = PAGES.Bag.frame
local list = bagPage:WaitForChild("List")
local rowTemplate = list:WaitForChild("RowTemplate")
local emptyLabel = list:WaitForChild("Empty")
local tabButtons = {
	Cosmetic = bagPage.Tabs:WaitForChild("CosmeticTab"),
	Equipment = bagPage.Tabs:WaitForChild("EquipmentTab"),
	Consumable = bagPage.Tabs:WaitForChild("ConsumableTab"),
}
local bagTab = "Cosmetic"

local function countOf(id)
	local inv = player:FindFirstChild("Inventory")
	local v = inv and inv:FindFirstChild(id)
	return v and v.Value or 0
end

local function refreshBag()
	for name, b in pairs(tabButtons) do b.BackgroundColor3 = (name == bagTab) and ACCENT or BG2 end
	for _, child in ipairs(list:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "RowTemplate" then child:Destroy() end
	end
	local shown = 0
	for i, item in ipairs(shopItems[bagTab] or {}) do
		local isConsumable = bagTab == "Consumable"
		local qty = isConsumable and countOf(item.Id) or 0
		local owned = isConsumable and qty > 0 or player:GetAttribute("Owned_" .. item.Id) == true
		if owned then
			shown += 1
			local equipped = player:GetAttribute("Equipped_" .. item.Id) == true
			local row = rowTemplate:Clone()
			row.Name = item.Id
			row.LayoutOrder = i
			row.IconBox.Icon.Text = item.Icon or "?"
			row.ItemName.Text = item.Name
			row.ItemDesc.Text = item.Desc
			local status = equipped and "✓ Equipped" or "Not equipped"
			if isConsumable then status = "x" .. qty .. "  ·  " .. status end
			row.Status.Text = status
			row.Status.TextColor3 = equipped and GOOD or MUTED
			row.EquipButton.Text = equipped and "Unequip" or "Equip"
			row.EquipButton.BackgroundColor3 = equipped and BG2 or ACCENT
			row.EquipButton.MouseButton1Click:Connect(function() equipRemote:FireServer(item.Id) end)
			row.UseButton.Visible = isConsumable
			if isConsumable then
				row.UseButton.MouseButton1Click:Connect(function() useRemote:FireServer(item.Id) end)
			end
			row.Visible = true
			row.Parent = list
		end
	end
	emptyLabel.Visible = shown == 0
end

for name, b in pairs(tabButtons) do
	b.MouseButton1Click:Connect(function() bagTab = name refreshBag() end)
end
onOpen.Bag = refreshBag

local function bagChanged()
	if current == "Bag" and panel.Visible then refreshBag() end
end
player.AttributeChanged:Connect(function(attr)
	if attr:match("^Owned_") or attr:match("^Equipped_") then bagChanged() end
end)
task.spawn(function()
	local inv = player:WaitForChild("Inventory", 15)
	if not inv then return end
	local function watch(v) if v:IsA("IntValue") then v.Changed:Connect(bagChanged) end end
	for _, v in ipairs(inv:GetChildren()) do watch(v) end
	inv.ChildAdded:Connect(function(v) watch(v) bagChanged() end)
end)
-- shop/bag server messages ("Equipped ...", "Used ...") show as a toast while the HUD is open
shopRemotes:WaitForChild("UpdateCash").OnClientEvent:Connect(function(message)
	if panel.Visible then showToast(message) end
end)

------------------------------------------------------------ MAP
local config = require(ReplicatedStorage:WaitForChild("HUDConfig"))
local hudRemotes = ReplicatedStorage:WaitForChild("HUDRemotes")
local mapTeleport = hudRemotes:WaitForChild("MapTeleport")
local switchServer = hudRemotes:WaitForChild("SwitchServer")

local mapPage = PAGES.Map.frame
local mapImage = mapPage:WaitForChild("MapImage")
local pinTemplate = mapImage:WaitForChild("PinTemplate")
local pinLabel = mapImage:WaitForChild("PinLabel")
local legend = mapPage:WaitForChild("Legend")
local legendTemplate = legend:WaitForChild("LegendTemplate")
local placeholder = mapImage:WaitForChild("Placeholder")

local B = config.MapBounds
local function toMap(pos)
	local u = (pos.X - B.MinX) / (B.MaxX - B.MinX)
	local v = (pos.Z - B.MinZ) / (B.MaxZ - B.MinZ)
	return math.clamp(u, 0.03, 0.97), math.clamp(v, 0.03, 0.97)
end

local selected, selectedAt = nil, 0
local function goTo(place)
	mapTeleport:FireServer(place.Id)
	pinLabel.Visible = false
	selected = nil
end

local function selectPin(place)
	if selected == place.Id and os.clock() - selectedAt < 4 then
		goTo(place)
		return
	end
	selected, selectedAt = place.Id, os.clock()
	pinLabel.Text = (place.Icon or "") .. " " .. place.Name .. " — tap again to go"
	pinLabel.Visible = true
end

for i, place in ipairs(config.Places) do
	local u, v = place.MapX, place.MapY
	if not (u and v) then u, v = toMap(place.Position) end
	local pin = pinTemplate:Clone()
	pin.Name = place.Id
	pin.Position = UDim2.fromScale(u, v)
	pin.Visible = true
	pin.Parent = mapImage.Pins
	pin.Parent = mapImage
	pin.MouseButton1Click:Connect(function() selectPin(place) end)

	local row = legendTemplate:Clone()
	row.Name = place.Id
	row.LayoutOrder = i
	row.PlaceName.Text = (place.Icon or "") .. "  " .. place.Name
	row.Visible = true
	row.Parent = legend
	row.MouseButton1Click:Connect(function() goTo(place) end)
end

-- "you are here" dot
local me = pinTemplate:Clone()
me.Name = "YouAreHere"
me.BackgroundColor3 = Color3.fromRGB(240, 190, 60)
me.Size = UDim2.new(0, 14, 0, 14)
me.AutoButtonColor = false
me.Active = false
me.ZIndex = 5
me.Parent = mapImage
local function updateMe()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	me.Visible = root ~= nil
	if root then
		local u, v = toMap(root.Position)
		me.Position = UDim2.fromScale(u, v)
	end
end
onOpen.Map = function()
	placeholder.Visible = (mapImage.Image == "")
	pinLabel.Visible = false
	updateMe()
end
task.spawn(function()
	while true do
		task.wait(0.5)
		if current == "Map" and panel.Visible then updateMe() end
	end
end)

mapTeleport.OnClientEvent:Connect(function(message)
	showToast(message)
	if message and message:find("^Teleported") then closePanel() end
end)

------------------------------------------------------------ SETTINGS
local setPage = PAGES.Settings.frame
local elemCard = setPage.ServerChoice:WaitForChild("ElementaryCard")
local jhCard = setPage.ServerChoice:WaitForChild("JuniorHighCard")
local serverNote = setPage:WaitForChild("ServerNote")

-- this place is the Junior High+ (main campus) server
jhCard.BackgroundColor3 = Color3.fromRGB(18, 70, 52)
jhCard.UIStroke.Color = ACCENT
jhCard.UIStroke.Thickness = 2.5

local function askConfirm(message, detail, onYes)
	confirm.Card.Message.Text = message
	confirm.Card.Detail.Text = detail
	confirm.Visible = true
	local yesConn, noConn
	yesConn = confirm.Card.Yes.MouseButton1Click:Connect(function()
		yesConn:Disconnect() noConn:Disconnect()
		confirm.Visible = false
		onYes()
	end)
	noConn = confirm.Card.Cancel.MouseButton1Click:Connect(function()
		yesConn:Disconnect() noConn:Disconnect()
		confirm.Visible = false
	end)
end

elemCard.MouseButton1Click:Connect(function()
	if (tonumber(config.ElementaryPlaceId) or 0) <= 0 then
		showToast("The Elementary server isn't set up yet")
		return
	end
	askConfirm("Switch to the Elementary server?",
		"You'll leave this server and join the separate, kid-friendly Elementary server.",
		function() switchServer:FireServer("Elementary") end)
end)
jhCard.MouseButton1Click:Connect(function()
	showToast("You're already on the Junior High+ server")
end)
switchServer.OnClientEvent:Connect(showToast)

-- sound groups: music vs sound effects (assigned locally, so each player has their own volume)
local musicGroup = SoundService:WaitForChild("Music")
local sfxGroup = SoundService:WaitForChild("SFX")
local function isMusic(sound)
	local p = sound
	while p and p ~= game do
		if p.Name:lower():find("music") then return true end
		p = p.Parent
	end
	return false
end
local function assign(sound)
	if not sound:IsA("Sound") then return end
	if sound.SoundGroup and sound.SoundGroup ~= musicGroup and sound.SoundGroup ~= sfxGroup then return end
	sound.SoundGroup = isMusic(sound) and musicGroup or sfxGroup
end
for _, d in ipairs(workspace:GetDescendants()) do assign(d) end
for _, d in ipairs(SoundService:GetDescendants()) do assign(d) end
workspace.DescendantAdded:Connect(assign)
SoundService.DescendantAdded:Connect(assign)

local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local function makeSlider(frame, initial, onChange)
	local track, fill, knob, valueLabel = frame.Track, frame.Track.Fill, frame.Track.Knob, frame.Value
	local hit = track:WaitForChild("HitArea")
	local dragging = false
	local function set(alpha)
		alpha = math.clamp(alpha, 0, 1)
		fill.Size = UDim2.new(alpha, 0, 1, 0)
		knob.Position = UDim2.new(alpha, 0, 0.5, 0)
		valueLabel.Text = math.round(alpha * 100) .. "%"
		onChange(alpha)
	end
	local function setFromX(x)
		set((x - track.AbsolutePosition.X) / track.AbsoluteSize.X)
	end
	hit.MouseButton1Down:Connect(function(x)
		dragging = true
		setFromX(x)
	end)
	hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			setFromX(input.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.Touch then setFromX(input.Position.X) end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)
	-- mouse dragging: follow the cursor while the left button is held
	RunService.RenderStepped:Connect(function()
		if not dragging then return end
		if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then return end
		if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
			dragging = false
			return
		end
		setFromX(UserInputService:GetMouseLocation().X)
	end)
	set(initial)
end
makeSlider(setPage:WaitForChild("MusicSlider"), 0.7, function(a) musicGroup.Volume = a player:SetAttribute("Setting_MusicVolume", a) end)
makeSlider(setPage:WaitForChild("SFXSlider"), 0.85, function(a) sfxGroup.Volume = a player:SetAttribute("Setting_SFXVolume", a) end)

local function makeToggle(frame, attr, initial)
	local switch = frame.Switch
	local on = initial
	local function render()
		switch.BackgroundColor3 = on and ACCENT or Color3.fromRGB(80, 80, 95)
		TweenService:Create(switch.Knob, TweenInfo.new(0.12), {Position = on and UDim2.new(1, -23, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)}):Play()
		player:SetAttribute(attr, on)
	end
	switch.MouseButton1Click:Connect(function() on = not on render() end)
	render()
end
makeToggle(setPage:WaitForChild("EventAlerts"), "Setting_EventAlerts", true)
makeToggle(setPage:WaitForChild("LeaderboardUpdates"), "Setting_LeaderboardUpdates", true)
