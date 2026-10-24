-- PlayerData: saves & loads progress with DataStore.
-- Saved: total play Time, level timer, Title, level, Common/Event coins, owned items,
-- equipped items, consumable counts and event statistics.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local PlayerData = {}
PlayerData.DEFAULT_TITLE = "Junior"
PlayerData.STORE_NAME = "SamarCollege_PlayerData_v1"
PlayerData.STARTING_COINS = { Common = 200, Event = 50 }
-- event / activity counters stored as player attributes
PlayerData.STATS = { "EventsCommon", "EventsRare", "QuizzesPassed", "EventsParkour", "EventsEscape", "EventsPhotobooth", "EventsJoined" }

local store
local ok = pcall(function() store = DataStoreService:GetDataStore(PlayerData.STORE_NAME) end)
if not ok then warn("[PlayerData] DataStore unavailable (enable Studio Access to API Services). Progress will not save.") end

local cache = {}      -- userId -> loaded table
local joinTime = {}   -- userId -> os.clock() when total time was last counted
local levelJoin = {}  -- userId -> os.clock() when the level timer was last counted

function PlayerData.key(userId) return "u_" .. userId end
local function key(player) return PlayerData.key(player.UserId) end

-- a brand-new save (also used by "Reset progress")
function PlayerData.fresh()
	local d = { Time = 0, LevelTime = 0, Title = PlayerData.DEFAULT_TITLE, LevelUnlocked = 1, SelectedLevel = 1,
		Coins = { Common = PlayerData.STARTING_COINS.Common, Event = PlayerData.STARTING_COINS.Event },
		Owned = {}, Equipped = {}, Inventory = {} }
	for _, s in ipairs(PlayerData.STATS) do d[s] = 0 end
	return d
end

local function normalize(data)
	data = type(data) == "table" and data or {}
	data.Time = tonumber(data.Time) or 0
	data.Title = data.Title or PlayerData.DEFAULT_TITLE
	data.Coins = type(data.Coins) == "table" and data.Coins or nil
	data.Owned = type(data.Owned) == "table" and data.Owned or {}
	data.Equipped = type(data.Equipped) == "table" and data.Equipped or {}
	data.Inventory = type(data.Inventory) == "table" and data.Inventory or {}
	return data
end
PlayerData.normalize = normalize

function PlayerData.load(player)
	local data
	if store then
		for attempt = 1, 3 do
			local s, result = pcall(function() return store:GetAsync(key(player)) end)
			if s then data = result break end
			local msg = tostring(result)
			if msg:find("StudioAccessToApisNotAllowed") or (game:GetService("RunService"):IsStudio() and (msg:find("not allowed") or msg:find("API access"))) then
				warn("[PlayerData] Saving is OFF in Studio. Turn on Game Settings > Security > Enable Studio Access to API Services.")
				store = nil break
			end
			task.wait(1)
		end
	end
	data = normalize(data)
	cache[player.UserId] = data
	joinTime[player.UserId] = os.clock()
	levelJoin[player.UserId] = os.clock()
	return data
end

function PlayerData.get(player) return cache[player.UserId] end
function PlayerData.hasStore() return store ~= nil end

-- total seconds played (saved + this session)
function PlayerData.getTime(player)
	local d = cache[player.UserId]
	if not d then return 0 end
	return d.Time + (os.clock() - (joinTime[player.UserId] or os.clock()))
end
function PlayerData.setTime(player, seconds)
	local d = cache[player.UserId]
	if not d then return end
	d.Time = math.max(0, seconds) joinTime[player.UserId] = os.clock()
end

-- seconds played since reaching the current level (counts toward the next quiz)
function PlayerData.getLevelTime(player)
	local d = cache[player.UserId]
	if not d then return 0 end
	return (tonumber(d.LevelTime) or 0) + (os.clock() - (levelJoin[player.UserId] or os.clock()))
end
function PlayerData.setLevelTime(player, seconds)
	local d = cache[player.UserId]
	if not d then return end
	d.LevelTime = math.max(0, seconds) levelJoin[player.UserId] = os.clock()
end
function PlayerData.resetLevelTime(player) PlayerData.setLevelTime(player, 0) end

local function snapshot(player)
	local d = cache[player.UserId]
	if not d then return nil end
	local out = { Time = math.floor(PlayerData.getTime(player)), LevelTime = math.floor(PlayerData.getLevelTime(player)),
		Coins = {}, Owned = {}, Equipped = {}, Inventory = {} }
	out.LevelUnlocked = player:GetAttribute("LevelUnlocked") or d.LevelUnlocked or 1
	out.SelectedLevel = player:GetAttribute("SelectedLevel") or d.SelectedLevel or 1
	for _, s in ipairs(PlayerData.STATS) do out[s] = player:GetAttribute(s) or d[s] or 0 end
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
PlayerData.snapshot = snapshot

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

-- read / edit the save of a player who is NOT in this server
function PlayerData.readOffline(userId)
	if not store then return nil, "DataStore unavailable" end
	local s, result = pcall(function() return store:GetAsync(PlayerData.key(userId)) end)
	if not s then return nil, tostring(result) end
	return normalize(result), nil, result ~= nil
end
function PlayerData.updateOffline(userId, fn)
	if not store then return false, "DataStore unavailable" end
	local s, err = pcall(function()
		store:UpdateAsync(PlayerData.key(userId), function(old) return fn(normalize(old)) end)
	end)
	return s, err
end

-- the last snapshot of a player who just left (Player Records reads it for the time-out summary)
local lastSnap = {}
function PlayerData.lastSnapshot(userId) return lastSnap[userId] end

function PlayerData.release(player)
	local uid = player.UserId
	lastSnap[uid] = snapshot(player) or lastSnap[uid]
	PlayerData.save(player)
	cache[uid] = nil
	joinTime[uid] = nil
	levelJoin[uid] = nil
	task.delay(120, function()
		if not Players:GetPlayerByUserId(uid) then lastSnap[uid] = nil end
	end)
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
