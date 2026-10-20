-- ShopClient.lua
-- Shop GUI: Cosmetic / Equipment / Consumable tabs, Common + Event token balances,
-- Buy / Owned buttons. The server validates every purchase.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local gui = script.Parent
local main = gui:WaitForChild("Main")
local title = main:WaitForChild("Title")
local commonLabel = main:WaitForChild("CommonLabel")
local eventLabel = main:WaitForChild("EventLabel")
local content = main:WaitForChild("Content")
local template = content:WaitForChild("ItemTemplate")
local tabs = main:WaitForChild("Tabs")
local closeButton = main:WaitForChild("CloseButton")
local inventoryButton = main:WaitForChild("InventoryButton")

local tabButtons = {
	Cosmetic = tabs:WaitForChild("CosmeticTab"),
	Equipment = tabs:WaitForChild("EquipmentTab"),
	Consumable = tabs:WaitForChild("ConsumableTab"),
}
local EQUIPPABLE = { Cosmetic = true, Equipment = true }

local ACTIVE_TAB = Color3.fromRGB(20, 140, 100)
local INACTIVE_TAB = Color3.fromRGB(55, 55, 70)
local BUY_COLOR = Color3.fromRGB(20, 140, 100)
local DISABLED_COLOR = Color3.fromRGB(70, 70, 85)
local TITLE_TEXT = title.Text

local currentTab = "Cosmetic"
local built = {} -- [category] = { {frame, item, category} }

local shopItems = nil
local buyItemRemote = nil

local function getBalance(currencyName)
	local wallet = player:FindFirstChild("Wallet")
	local value = wallet and wallet:FindFirstChild(currencyName)
	return value and value.Value or 0
end

local function refreshBalances()
	commonLabel.Text = "Common: " .. getBalance("Common")
	eventLabel.Text = "Event: " .. getBalance("Event")
end

local function refreshButtons()
	for category, entries in pairs(built) do
		for _, entry in ipairs(entries) do
			local item = entry.item
			local button = entry.frame.BuyButton
			if EQUIPPABLE[category] and player:GetAttribute("Owned_" .. item.Id) then
				button.Text = "OWNED"
				button.BackgroundColor3 = DISABLED_COLOR
				button.AutoButtonColor = false
				button.Active = false
			elseif item.RequiredLevel and (player:GetAttribute("LevelUnlocked") or 1) < item.RequiredLevel then
				local LevelConfig = require(ReplicatedStorage:WaitForChild("LevelConfig"))
				button.Text = "🔒 " .. LevelConfig.name(item.RequiredLevel)
				button.BackgroundColor3 = DISABLED_COLOR
				button.AutoButtonColor = false
				button.Active = false
			else
				button.Text = item.Price .. " " .. item.Currency
				button.Active = true
				button.AutoButtonColor = true
				button.BackgroundColor3 = (getBalance(item.Currency) >= item.Price) and BUY_COLOR or DISABLED_COLOR
			end
		end
	end
end

local function showMessage(message)
	title.Text = message
	task.delay(1.8, function()
		if title.Text == message then
			title.Text = TITLE_TEXT
		end
	end)
end

local function buildTab(category)
	if built[category] or not shopItems then return end
	local entries = {}
	for i, item in ipairs(shopItems[category] or {}) do
		local frame = template:Clone()
		frame.Name = item.Id
		frame.LayoutOrder = i
		frame.ItemName.Text = item.Name
		frame.ItemDesc.Text = item.Desc
		local iconBox = frame:FindFirstChild("IconBox")
		if iconBox then iconBox.Icon.Text = item.Icon or "?" end
		frame.BuyButton.MouseButton1Click:Connect(function()
			if buyItemRemote then buyItemRemote:FireServer(item.Id) end
		end)
		frame.Visible = false
		frame.Parent = content
		table.insert(entries, { frame = frame, item = item })
	end
	built[category] = entries
end

local function showTab(category)
	currentTab = category

	for _, entries in pairs(built) do
		for _, entry in ipairs(entries) do
			entry.frame.Visible = false
		end
	end

	buildTab(category)
	for _, entry in ipairs(built[category] or {}) do
		entry.frame.Visible = true
	end

	for name, button in pairs(tabButtons) do
		button.BackgroundColor3 = (name == category) and ACTIVE_TAB or INACTIVE_TAB
	end

	refreshBalances()
	refreshButtons()
end

-- Connect UI controls FIRST so the shop always responds,
-- even if the remotes or catalog are missing.
for name, button in pairs(tabButtons) do
	button.MouseButton1Click:Connect(function()
		showTab(name)
	end)
end

closeButton.MouseButton1Click:Connect(function()
	gui.Enabled = false
end)

inventoryButton.MouseButton1Click:Connect(function()
	local playerGui = player:FindFirstChild("PlayerGui")
	local hud = playerGui and playerGui:FindFirstChild("MainHUD")
	local open = hud and hud:FindFirstChild("OpenPanel")
	if open then
		gui.Enabled = false
		open:Fire("Bag")
	end
end)

gui:GetPropertyChangedSignal("Enabled"):Connect(function()
	if gui.Enabled then
		showTab(currentTab)
	end
end)

-- Resolve dependencies AFTER controls are connected (timeouts prevent freezing)
local remotes = ReplicatedStorage:WaitForChild("ShopRemotes", 10)
if remotes then
	buyItemRemote = remotes:FindFirstChild("BuyItem")
	local feedbackRemote = remotes:FindFirstChild("UpdateCash")
	if feedbackRemote then
		feedbackRemote.OnClientEvent:Connect(function(message)
			if message then showMessage(message) end
			refreshBalances()
			refreshButtons()
		end)
	end
else
	warn("[ShopClient] ShopRemotes not found - purchases disabled")
end

local catalog = ReplicatedStorage:WaitForChild("ShopItems", 10)
if catalog then
	shopItems = require(catalog)
else
	warn("[ShopClient] ShopItems module not found - shop cannot display items")
end

-- Keep balances and button states live
player.AttributeChanged:Connect(function(name)
	if string.match(name, "^Owned_") or name == "LevelUnlocked" then
		refreshButtons()
	end
end)

task.spawn(function()
	local leaderstats = player:WaitForChild("Wallet", 10)
	if not leaderstats then return end
	for _, currencyName in ipairs({"Common", "Event"}) do
		local value = leaderstats:WaitForChild(currencyName, 10)
		if value then
			value.Changed:Connect(function()
				refreshBalances()
				refreshButtons()
			end)
		end
	end
	refreshBalances()
	refreshButtons()
end)

if gui.Enabled then
	showTab(currentTab)
end
