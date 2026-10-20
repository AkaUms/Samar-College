-- PlayerData: saves & loads progress with DataStore.
-- Saved: play Time, Title, Common/Event coins, owned items, equipped items, consumable counts.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local PlayerData = {}
PlayerData.DEFAULT_TITLE = "Junior"

local store
local ok = pcall(function() store = DataStoreService:GetDataStore("SamarCollege_PlayerData_v1") end)
if not ok then warn("[PlayerData] DataStore unavailable (enable Studio Access to API Services). Progress will not save.") end

local cache = {}      -- userId -> loaded table
local joinTime = {}   -- userId -> os.clock() when session time last counted

local function key(player) return "u_" .. player.UserId end

function PlayerData.load(player)
	local data
	if store then
		for attempt = 1, 3 do
			local s, result = pcall(function() return store:GetAsync(key(player)) end)
			if s then data = result break end
			if tostring(result):find("StudioAccessToApisNotAllowed") then
				warn("[PlayerData] Saving is OFF in Studio. Turn on Game Settings > Security > Enable Studio Access to API Services.")
				store = nil break
			end
			task.wait(1)
		end
	end
	data = type(data) == "table" and data or {}
	data.Time = tonumber(data.Time) or 0
	data.Title = data.Title or PlayerData.DEFAULT_TITLE
	data.Coins = type(data.Coins) == "table" and data.Coins or nil
	data.Owned = type(data.Owned) == "table" and data.Owned or {}
	data.Equipped = type(data.Equipped) == "table" and data.Equipped or {}
	data.Inventory = type(data.Inventory) == "table" and data.Inventory or {}
	cache[player.UserId] = data
	joinTime[player.UserId] = os.clock()
	return data
end

function PlayerData.get(player) return cache[player.UserId] end

-- total seconds played (saved + this session)
function PlayerData.getTime(player)
	local d = cache[player.UserId]
	if not d then return 0 end
	return d.Time + (os.clock() - (joinTime[player.UserId] or os.clock()))
end

local function snapshot(player)
	local d = cache[player.UserId]
	if not d then return nil end
	local out = { Time = math.floor(PlayerData.getTime(player)), Coins = {}, Owned = {}, Equipped = {}, Inventory = {} }
	out.LevelUnlocked = player:GetAttribute("LevelUnlocked") or d.LevelUnlocked or 1
	out.SelectedLevel = player:GetAttribute("SelectedLevel") or d.SelectedLevel or 1
	out.EventsJoined = player:GetAttribute("EventsJoined") or d.EventsJoined or 0
	out.QuizzesPassed = player:GetAttribute("QuizzesPassed") or d.QuizzesPassed or 0
	local ls = player:FindFirstChild("leaderstats")
	out.Title = (ls and ls:FindFirstChild("Title") and ls.Title.Value) or d.Title
	local wallet = player:FindFirstChild("Wallet")
	if wallet then for _, v in ipairs(wallet:GetChildren()) do if v:IsA("IntValue") then out.Coins[v.Name] = v.Value end end end
	for name, value in pairs(player:GetAttributes()) do
		if value == true then
			local id = string.match(name, "^Owned_(.+)") if id then table.insert(out.Owned, id) end
			local eq = string.match(name, "^Equipped_(.+)") if eq then table.insert(out.Equipped, eq) end
		end
	end
	local inv = player:FindFirstChild("Inventory")
	if inv then for _, v in ipairs(inv:GetChildren()) do if v:IsA("IntValue") and v.Value > 0 then out.Inventory[v.Name] = v.Value end end end
	return out
end

function PlayerData.save(player)
	if not store then return end
	local snap = snapshot(player)
	if not snap then return end
	for attempt = 1, 3 do
		local s, err = pcall(function() store:SetAsync(key(player), snap) end)
		if s then return true end
		warn("[PlayerData] save failed for " .. player.Name .. ": " .. tostring(err))
		task.wait(1)
	end
end

function PlayerData.release(player)
	PlayerData.save(player)
	cache[player.UserId] = nil
	joinTime[player.UserId] = nil
end

Players.PlayerRemoving:Connect(function(player) PlayerData.release(player) end)
game:BindToClose(function()
	for _, p in ipairs(Players:GetPlayers()) do task.spawn(PlayerData.save, p) end
	task.wait(3)
end)
task.spawn(function()
	while true do
		task.wait(60)
		for _, p in ipairs(Players:GetPlayers()) do task.spawn(PlayerData.save, p) end
	end
end)

return PlayerData
