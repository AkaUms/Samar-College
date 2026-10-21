-- ShopServer.lua
-- Token currencies (Common / Event), purchase validation, equip state,
-- equipment effects and consumable effects. The server validates everything.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:WaitForChild("ShopRemotes")
local buyItemRemote = remotes:WaitForChild("BuyItem")
local useItemRemote = remotes:WaitForChild("UseItem")
local equipItemRemote = remotes:WaitForChild("EquipItem")
local feedbackRemote = remotes:WaitForChild("UpdateCash") -- fires (message) to the client
local toolsFolder = ReplicatedStorage:WaitForChild("Tools")
local shopItems = require(ReplicatedStorage:WaitForChild("ShopItems"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Outfits = require(ReplicatedStorage:WaitForChild("Outfits"))

-- Starting balances for NEW players (saved players load from PlayerData).
local STARTING_TOKENS = PlayerData.STARTING_COINS
local BASE_WALKSPEED = 16
local BASE_JUMPPOWER = 50

-- Cosmetic and Equipment are bought once and can be equipped.
local EQUIPPABLE = { Cosmetic = true, Equipment = true }

-- What each Equipment item does while equipped.
local EQUIPMENT_EFFECTS = {
	RunningShoes = { Speed = 10 },
	SpringBoots = { Jump = 20 },
	Flashlight = { Tool = "Flashlight" },
}

local function findItem(itemId)
	for category, items in pairs(shopItems) do
		for _, item in ipairs(items) do
			if item.Id == itemId then
				return item, category
			end
		end
	end
	return nil
end

local function feedback(player, message)
	feedbackRemote:FireClient(player, message)
end

local function getCurrency(player, currencyName)
	local wallet = player:FindFirstChild("Wallet")
	return wallet and wallet:FindFirstChild(currencyName)
end

-- Consumable inventory (Folder of IntValues inside the player; replicates automatically)
local function getInventory(player)
	local inv = player:FindFirstChild("Inventory")
	if not inv then
		inv = Instance.new("Folder")
		inv.Name = "Inventory"
		inv.Parent = player
	end
	return inv
end

local function getItemCount(player, itemId)
	local inv = player:FindFirstChild("Inventory")
	local value = inv and inv:FindFirstChild(itemId)
	return value and value.Value or 0
end

local function addItem(player, itemId, amount)
	local inv = getInventory(player)
	local value = inv:FindFirstChild(itemId)
	if not value then
		value = Instance.new("IntValue")
		value.Name = itemId
		value.Parent = inv
	end
	value.Value += amount
end

local function removeItem(player, itemId, amount)
	local inv = player:FindFirstChild("Inventory")
	local value = inv and inv:FindFirstChild(itemId)
	if not value or value.Value < amount then return false end
	value.Value -= amount
	return true
end

-- Tools (only given while the matching Equipment item is equipped)
local function giveTool(player, toolName)
	local template = toolsFolder:FindFirstChild(toolName)
	if not template then return end
	local backpack = player:FindFirstChild("Backpack")
	if not backpack then return end
	if backpack:FindFirstChild(toolName) then return end
	local character = player.Character
	if character and character:FindFirstChild(toolName) then return end
	template:Clone().Parent = backpack
end

local function removeTool(player, toolName)
	local backpack = player:FindFirstChild("Backpack")
	local inBackpack = backpack and backpack:FindFirstChild(toolName)
	if inBackpack then inBackpack:Destroy() end
	local character = player.Character
	local inHand = character and character:FindFirstChild(toolName)
	if inHand and inHand:IsA("Tool") then inHand:Destroy() end
end

-- Recalculate speed, jump and tools from whatever Equipment is equipped
local function refreshEquipment(player)
	local speed, jump = 0, 0
	local wantedTools = {}

	for _, item in ipairs(shopItems.Equipment) do
		local fx = EQUIPMENT_EFFECTS[item.Id]
		if fx and player:GetAttribute("Equipped_" .. item.Id) then
			speed += fx.Speed or 0
			jump += fx.Jump or 0
			if fx.Tool then wantedTools[fx.Tool] = true end
		end
	end

	player:SetAttribute("EquipSpeed", speed)
	player:SetAttribute("EquipJump", jump)

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = player:GetAttribute("AdminSpeed") or (BASE_WALKSPEED + speed)
		humanoid.JumpPower = BASE_JUMPPOWER + jump
	end

	for _, item in ipairs(shopItems.Equipment) do
		local fx = EQUIPMENT_EFFECTS[item.Id]
		if fx and fx.Tool then
			if wantedTools[fx.Tool] then
				giveTool(player, fx.Tool)
			else
				removeTool(player, fx.Tool)
			end
		end
	end
end

-- Show the equipped cosmetic on the character (only one at a time)
local function refreshCosmetic(player)
	local character = player.Character
	if not character then return end
	for _, item in ipairs(shopItems.Cosmetic) do
		if Outfits.has(item.Id) then
			Outfits.remove(character, item.Id)
		end
	end
	for _, item in ipairs(shopItems.Cosmetic) do
		if player:GetAttribute("Equipped_" .. item.Id) and Outfits.has(item.Id) then
			Outfits.wear(character, item.Id)
		end
	end
end

-- Consumable item effects (triggered when USED from the inventory)
local function applyConsumable(player, item)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if item.Id == "PizzaSlice" and humanoid then
		humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + 15)
	elseif item.Id == "SmallSnack" and humanoid then
		humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + 25)
	elseif item.Id == "MedKit" and humanoid then
		humanoid.Health = humanoid.MaxHealth
	elseif item.Id == "EnergyDrink" and humanoid then
		humanoid.WalkSpeed = BASE_WALKSPEED + (player:GetAttribute("EquipSpeed") or 0) + 12
		task.delay(30, function()
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hum then hum.WalkSpeed = player:GetAttribute("AdminSpeed") or (BASE_WALKSPEED + (player:GetAttribute("EquipSpeed") or 0)) end
		end)
	elseif item.Id == "GlowStick" and character then
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			local old = hrp:FindFirstChild("GlowStickLight")
			if old then old:Destroy() end
			local light = Instance.new("PointLight")
			light.Name = "GlowStickLight"
			light.Range = 16
			light.Brightness = 1.5
			light.Color = Color3.fromRGB(120, 255, 120)
			light.Parent = hrp
			task.delay(60, function()
				if light.Parent then light:Destroy() end
			end)
		end
	elseif item.Id == "InvisibilityPotion" and character then
		local originals = {}
		for _, obj in character:GetDescendants() do
			if obj:IsA("BasePart") then
				table.insert(originals, {obj, obj.Transparency})
				obj.Transparency = 0.7
			elseif obj:IsA("Decal") then
				table.insert(originals, {obj, obj.Transparency})
				obj.Transparency = 1
			end
		end
		task.delay(10, function()
			for _, saved in ipairs(originals) do
				if saved[1].Parent then saved[1].Transparency = saved[2] end
			end
		end)
	end
end

local function onPlayerAdded(player)
	local data = PlayerData.load(player)

	-- Leaderboard: Time played + Title
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local timeValue = Instance.new("StringValue")
	timeValue.Name = "Time"
	timeValue.Parent = leaderstats
	local titleValue = Instance.new("StringValue")
	titleValue.Name = "Title"
	titleValue.Value = data.Title or PlayerData.DEFAULT_TITLE
	titleValue.Parent = leaderstats
	leaderstats.Parent = player

	-- Coins (hidden from the leaderboard, shown in the Coins GUI)
	local wallet = Instance.new("Folder")
	wallet.Name = "Wallet"
	for currencyName, amount in pairs(STARTING_TOKENS) do
		local value = Instance.new("IntValue")
		value.Name = currencyName
		value.Value = (data.Coins and tonumber(data.Coins[currencyName])) or amount
		value.Parent = wallet
	end
	wallet.Parent = player

	-- Restore the bag
	for _, id in ipairs(data.Owned) do player:SetAttribute("Owned_" .. id, true) end
	for _, id in ipairs(data.Equipped) do player:SetAttribute("Equipped_" .. id, true) end
	local inv = getInventory(player)
	for id, count in pairs(data.Inventory) do
		local v = Instance.new("IntValue") v.Name = id v.Value = tonumber(count) or 0 v.Parent = inv
	end

	-- Live play-time counter
	task.spawn(function()
		while player.Parent do
			local t = math.floor(PlayerData.getTime(player))
			local h, m, s = math.floor(t / 3600), math.floor(t % 3600 / 60), t % 60
			timeValue.Value = (h > 0) and string.format("%dh %02dm", h, m) or string.format("%dm %02ds", m, s)
			player:SetAttribute("PlayTimeSeconds", t)
			player:SetAttribute("LevelTimeSeconds", math.floor(PlayerData.getLevelTime(player)))
			task.wait(1)
		end
	end)

	getInventory(player)

	-- Re-apply equipped gear on every respawn
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Humanoid")
		refreshEquipment(player)
		task.wait(1)
		refreshEquipment(player)
	end)
	-- Cosmetics go on after the avatar's own clothes have loaded and the body
	-- has been resized by DefaultAvatarSize (so the pieces fit the final size)
	player.CharacterAppearanceLoaded:Connect(function(character)
		local started = os.clock()
		while character.Parent and not character:GetAttribute("AvatarSized") and os.clock() - started < 5 do
			task.wait(0.1)
		end
		refreshCosmetic(player)
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

-- Buying
buyItemRemote.OnServerEvent:Connect(function(player, itemId)
	if typeof(itemId) ~= "string" then return end

	local item, category = findItem(itemId)
	if not item then return end

	local balance = getCurrency(player, item.Currency)
	if not balance then return end

	if item.RequiredLevel and (player:GetAttribute("LevelUnlocked") or 1) < item.RequiredLevel then
		local LevelConfig = require(ReplicatedStorage:WaitForChild("LevelConfig"))
		feedback(player, "🔒 Unlocks at " .. LevelConfig.name(item.RequiredLevel) .. " — level up in your Profile!")
		return
	end

	if EQUIPPABLE[category] and player:GetAttribute("Owned_" .. item.Id) then
		feedback(player, "You already own this!")
		return
	end

	if balance.Value < item.Price then
		feedback(player, "Not enough " .. item.Currency .. " tokens!")
		return
	end

	balance.Value -= item.Price

	if EQUIPPABLE[category] then
		player:SetAttribute("Owned_" .. item.Id, true)
		feedback(player, "Purchased " .. item.Name .. "! Equip it from your inventory [I]")
	else
		addItem(player, item.Id, 1)
		feedback(player, "Bought " .. item.Name .. "! Open inventory [I]")
	end
end)

-- Equip / unequip (one item per category at a time)
equipItemRemote.OnServerEvent:Connect(function(player, itemId)
	if typeof(itemId) ~= "string" then return end

	local item, category = findItem(itemId)
	if not item then return end
	if category == "Consumable" then
		if getItemCount(player, item.Id) <= 0 then return end
	elseif not EQUIPPABLE[category] or not player:GetAttribute("Owned_" .. item.Id) then
		return
	end

	local equipNow = not player:GetAttribute("Equipped_" .. item.Id)

	for _, other in ipairs(shopItems[category]) do
		player:SetAttribute("Equipped_" .. other.Id, nil)
	end
	if equipNow then
		player:SetAttribute("Equipped_" .. item.Id, true)
	end

	if category == "Equipment" then
		refreshEquipment(player)
	elseif category == "Cosmetic" then
		refreshCosmetic(player)
	end

	feedback(player, (equipNow and "Equipped " or "Unequipped ") .. item.Name)
end)

-- Using consumables from the inventory
useItemRemote.OnServerEvent:Connect(function(player, itemId)
	if typeof(itemId) ~= "string" then return end

	local item, category = findItem(itemId)
	if not item or category ~= "Consumable" then return end
	if getItemCount(player, item.Id) <= 0 then return end

	applyConsumable(player, item)
	if removeItem(player, item.Id, 1) then
		if getItemCount(player, item.Id) <= 0 then
			player:SetAttribute("Equipped_" .. item.Id, nil)
		end
		feedback(player, "Used " .. item.Name .. "!")
	end
end)

-- Admin panel hook: re-apply equipment/cosmetics after an admin changes a player's items
local ServerStorage = game:GetService("ServerStorage")
local signals = ServerStorage:FindFirstChild("AdminSignals") or Instance.new("Folder")
signals.Name = "AdminSignals" signals.Parent = ServerStorage
local refreshGear = signals:FindFirstChild("RefreshGear") or Instance.new("BindableEvent")
refreshGear.Name = "RefreshGear" refreshGear.Parent = signals
refreshGear.Event:Connect(function(player)
	if player and player.Parent then refreshEquipment(player) refreshCosmetic(player) end
end)
