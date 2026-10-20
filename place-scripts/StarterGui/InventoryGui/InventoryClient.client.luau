-- InventoryClient.lua
-- Grid inventory GUI: Cosmetic / Equipment show EQUIPPED or NOT EQUIPPED with an
-- EQUIP / UNEQUIP button; Consumables show a count with a USE button.
-- Toggle with the [I] key, the close button, or the Inventory button in the shop.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local gui = script.Parent
local main = gui:WaitForChild("Main")
local content = main:WaitForChild("Content")
local template = content:WaitForChild("SlotTemplate")
local closeButton = main:WaitForChild("CloseButton")

local remotes = ReplicatedStorage:WaitForChild("ShopRemotes")
local useItemRemote = remotes:WaitForChild("UseItem")
local equipItemRemote = remotes:WaitForChild("EquipItem")

local CATEGORIES = {"Cosmetic", "Equipment", "Consumable"}

-- Connect basic controls FIRST so the GUI always responds,
-- even if the item catalog is missing.
closeButton.MouseButton1Click:Connect(function()
	gui.Enabled = false
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.I then
		gui.Enabled = not gui.Enabled
	end
end)

local shopItems = nil
local catalog = ReplicatedStorage:WaitForChild("ShopItems", 10)
if catalog then
	shopItems = require(catalog)
else
	warn("[InventoryClient] ShopItems module not found - inventory cannot display items")
end

local slots = {} -- [itemId] = {frame, countLabel, useButton, category}

local function getItemCount(itemId)
	local inv = player:FindFirstChild("Inventory")
	local value = inv and inv:FindFirstChild(itemId)
	return value and value.Value or 0
end

local function refreshSlot(itemId)
	local slot = slots[itemId]
	if not slot then return end

	if slot.category ~= "Consumable" then
		local owned = player:GetAttribute("Owned_" .. itemId) == true
		local equipped = player:GetAttribute("Equipped_" .. itemId) == true
		if equipped then
			slot.countLabel.Text = "EQUIPPED"
			slot.countLabel.TextColor3 = Color3.fromRGB(120, 255, 160)
		elseif owned then
			slot.countLabel.Text = "NOT EQUIPPED"
			slot.countLabel.TextColor3 = Color3.fromRGB(255, 220, 127)
		else
			slot.countLabel.Text = "NOT OWNED"
			slot.countLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
		end
		if slot.useButton then
			slot.useButton.Visible = owned
			slot.useButton.Text = equipped and "UNEQUIP" or "EQUIP"
		end
	else
		local count = getItemCount(itemId)
		slot.countLabel.Text = "x" .. count
		slot.countLabel.TextColor3 = count > 0 and Color3.fromRGB(120, 255, 120) or Color3.fromRGB(160, 160, 160)
		if slot.useButton then
			slot.useButton.Visible = count > 0
			slot.useButton.Text = "USE"
		end
	end
end

local function refreshAll()
	for itemId in pairs(slots) do
		refreshSlot(itemId)
	end
end

local function buildSlots()
	if not shopItems then return end
	local order = 0
	for _, category in ipairs(CATEGORIES) do
		for _, item in ipairs(shopItems[category] or {}) do
			order += 1
			local frame = template:Clone()
			frame.Name = item.Id
			frame.LayoutOrder = order
			frame.ItemName.Text = (item.Icon and (item.Icon .. " ") or "") .. item.Name
			frame.CountLabel.TextSize = 13
			frame.Visible = true
			frame.Parent = content

			local useButton = frame:FindFirstChild("UseButton")
			if useButton then
				useButton.MouseButton1Click:Connect(function()
					if category == "Consumable" then
						useItemRemote:FireServer(item.Id)
					else
						equipItemRemote:FireServer(item.Id)
					end
				end)
			end

			slots[item.Id] = {
				frame = frame,
				countLabel = frame:FindFirstChild("CountLabel"),
				useButton = useButton,
				category = category,
			}
			refreshSlot(item.Id)
		end
	end
end

-- Live updates from the server-side consumable folder
local function watchValue(value)
	value.Changed:Connect(function()
		refreshSlot(value.Name)
	end)
end

local function watchInventory()
	local inv = player:WaitForChild("Inventory", 10)
	if not inv then return end
	for _, child in ipairs(inv:GetChildren()) do
		if child:IsA("IntValue") then watchValue(child) end
	end
	inv.ChildAdded:Connect(function(child)
		refreshSlot(child.Name)
		if child:IsA("IntValue") then watchValue(child) end
	end)
	inv.ChildRemoved:Connect(function(child)
		refreshSlot(child.Name)
	end)
end

-- Owned / Equipped state arrives through player attributes
player.AttributeChanged:Connect(function(name)
	local itemId = string.match(name, "^Owned_(.+)$") or string.match(name, "^Equipped_(.+)$")
	if itemId then refreshSlot(itemId) end
end)

gui:GetPropertyChangedSignal("Enabled"):Connect(function()
	if gui.Enabled then
		refreshAll()
	end
end)

buildSlots()
watchInventory()
