-- AdminServer: Samar College admin panel (TEAM PRUC).
-- Owner = OWNER_IDS + the experience's creator. Co-admins are stored in a DataStore and
-- can be added/removed by the owner only. Every request is checked here on the server.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local RS = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local PlayerRecords = require(script.Parent:WaitForChild("PlayerRecords"))
local PlayerReports = require(script.Parent:WaitForChild("PlayerReports"))
local LevelConfig = require(RS:WaitForChild("LevelConfig"))
local ShopItems = require(RS:WaitForChild("ShopItems"))

local OWNER_IDS = { [2697306367] = true } -- Aka_Yuuki (Umi)
if game.CreatorType == Enum.CreatorType.User and game.CreatorId > 0 then OWNER_IDS[game.CreatorId] = true end
local TOPIC = "SC_AdminActions"
local MAX_LEVEL = #LevelConfig.Levels
local EDITABLE_STATS = { "EventsCommon", "EventsRare", "QuizzesPassed", "EventsParkour", "EventsEscape", "EventsPhotobooth" }
local EVENT_STATS = { "EventsCommon", "EventsRare", "EventsParkour", "EventsEscape", "EventsPhotobooth" }

---------------------------------------------------------------- remotes & signals
local remotes = RS:FindFirstChild("AdminRemotes") or Instance.new("Folder")
remotes.Name = "AdminRemotes" remotes.Parent = RS
local fn = remotes:FindFirstChild("AdminRequest") or Instance.new("RemoteFunction")
fn.Name = "AdminRequest" fn.Parent = remotes
local adminNotice = remotes:FindFirstChild("AdminNotice") or Instance.new("RemoteEvent") -- new reports etc. (admins only)
adminNotice.Name = "AdminNotice" adminNotice.Parent = remotes
local signals = ServerStorage:FindFirstChild("AdminSignals") or Instance.new("Folder")
signals.Name = "AdminSignals" signals.Parent = ServerStorage
local refreshGear = signals:FindFirstChild("RefreshGear") or Instance.new("BindableEvent")
refreshGear.Name = "RefreshGear" refreshGear.Parent = signals

---------------------------------------------------------------- stores
local adminStore, banStore
pcall(function() adminStore = DataStoreService:GetDataStore("SamarCollege_Admins_v1") end)
pcall(function() banStore = DataStoreService:GetDataStore("SamarCollege_Bans_v1") end)

local coAdmins = {} -- [userId] = { name = , by = , at = }
local function loadAdmins()
	if not adminStore then return end
	local ok, data = pcall(function() return adminStore:GetAsync("coadmins") end)
	if ok and type(data) == "table" then
		coAdmins = {}
		for k, v in pairs(data) do coAdmins[tonumber(k)] = v end
	end
end
loadAdmins()

local function isOwner(userId) return OWNER_IDS[userId] == true end
local function isAdmin(userId) return isOwner(userId) or coAdmins[userId] ~= nil end
local function roleOf(userId) return isOwner(userId) and "Owner" or (coAdmins[userId] and "Co-Admin" or "Player") end

---------------------------------------------------------------- give the panel to admins
local template = ServerStorage:WaitForChild("AdminPanelGui")
local function givePanel(player)
	if not isAdmin(player.UserId) then
		local pg = player:FindFirstChild("PlayerGui")
		local g = pg and pg:FindFirstChild("AdminPanelGui") if g then g:Destroy() end
		return
	end
	local pg = player:WaitForChild("PlayerGui")
	if not pg:FindFirstChild("AdminPanelGui") then template:Clone().Parent = pg end
end

---------------------------------------------------------------- helpers
local function findPlayer(userId) return Players:GetPlayerByUserId(userId) end

local function resolve(query)
	if type(query) ~= "string" and type(query) ~= "number" then return nil, "Type a username or user ID" end
	query = tostring(query):gsub("^%s+", ""):gsub("%s+$", ""):gsub("^@", "")
	if query == "" then return nil, "Type a username or user ID" end
	-- in-server display name / username match first
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Name:lower() == query:lower() or p.DisplayName:lower() == query:lower() or tostring(p.UserId) == query then
			return p.UserId, p.Name, p.DisplayName
		end
	end
	local id = tonumber(query)
	if id then
		local ok, name = pcall(function() return Players:GetNameFromUserIdAsync(id) end)
		if ok and name then return id, name, name end
		return nil, "No Roblox user with ID " .. query
	end
	local ok, uid = pcall(function() return Players:GetUserIdFromNameAsync(query) end)
	if ok and uid then
		local ok2, real = pcall(function() return Players:GetNameFromUserIdAsync(uid) end)
		return uid, ok2 and real or query, ok2 and real or query
	end
	return nil, "No Roblox user named \"" .. query .. "\""
end

local function getBan(userId)
	if not banStore then return nil end
	local ok, b = pcall(function() return banStore:GetAsync("b_" .. userId) end)
	if ok and type(b) == "table" and (b.untilTime or 0) > os.time() then return b end
	return nil
end

local function fmtDuration(sec)
	sec = math.max(0, math.floor(sec))
	local d, h, m = math.floor(sec / 86400), math.floor(sec % 86400 / 3600), math.floor(sec % 3600 / 60)
	if d > 0 then return string.format("%dd %dh", d, h) end
	if h > 0 then return string.format("%dh %dm", h, m) end
	if m > 0 then return string.format("%dm %ds", m, sec % 60) end
	return sec .. "s"
end

local function itemList()
	local out = {}
	for cat, items in pairs(ShopItems) do
		out[cat] = {}
		for _, it in ipairs(items) do table.insert(out[cat], { Id = it.Id, Name = it.Name, Icon = it.Icon }) end
	end
	return out
end

-- live state of a player in THIS server, in the same shape as a save
local function liveData(p)
	local snap = PlayerData.snapshot(p) or PlayerData.fresh()
	snap.LevelTime = math.floor(PlayerData.getLevelTime(p))
	snap.Time = math.floor(PlayerData.getTime(p))
	return snap
end

local function publish(msg)
	pcall(function() MessagingService:PublishAsync(TOPIC, msg) end)
end

---------------------------------------------------------------- applying changes to an ONLINE player (this server)
local function applyLive(p, c)
	if c.reset then
		local fresh = PlayerData.fresh()
		PlayerData.setTime(p, 0)
		PlayerData.resetLevelTime(p)
		p:SetAttribute("LevelUnlocked", 1) p:SetAttribute("SelectedLevel", 1)
		for name, v in pairs(p:GetAttributes()) do
			if name:match("^Owned_") or name:match("^Equipped_") then p:SetAttribute(name, nil) end
		end
		local inv = p:FindFirstChild("Inventory")
		if inv then for _, v in ipairs(inv:GetChildren()) do v:Destroy() end end
		local w = p:FindFirstChild("Wallet")
		if w then for cur, amt in pairs(fresh.Coins) do local v = w:FindFirstChild(cur) if v then v.Value = amt end end end
		for _, stat in ipairs(PlayerData.STATS) do p:SetAttribute(stat, 0) end
		refreshGear:Fire(p)
		return
	end
	if c.level then
		local lv = math.clamp(math.floor(c.level), 1, MAX_LEVEL)
		p:SetAttribute("LevelUnlocked", lv)
		p:SetAttribute("SelectedLevel", lv)
		PlayerData.resetLevelTime(p) -- promote/demote restarts the quiz timer
	end
	if c.coins then
		local w = p:FindFirstChild("Wallet")
		for cur, amt in pairs(c.coins) do
			local v = w and w:FindFirstChild(cur)
			if v then v.Value = math.max(0, math.floor(amt)) end
		end
	end
	if c.owned then
		for id, own in pairs(c.owned) do
			p:SetAttribute("Owned_" .. id, own and true or nil)
			if not own then p:SetAttribute("Equipped_" .. id, nil) end
		end
	end
	if c.inventory then
		local inv = p:FindFirstChild("Inventory")
		if not inv then inv = Instance.new("Folder") inv.Name = "Inventory" inv.Parent = p end
		for id, n in pairs(c.inventory) do
			n = math.max(0, math.floor(n))
			local v = inv:FindFirstChild(id)
			if not v then v = Instance.new("IntValue") v.Name = id v.Parent = inv end
			v.Value = n
			if n == 0 then p:SetAttribute("Equipped_" .. id, nil) end
		end
	end
	if c.stats then
		for stat, n in pairs(c.stats) do p:SetAttribute(stat, math.max(0, math.floor(n))) end
		local total = 0
		for _, s in ipairs(EVENT_STATS) do total += p:GetAttribute(s) or 0 end
		p:SetAttribute("EventsJoined", total)
	end
	refreshGear:Fire(p)
end

-- applying changes to a SAVE (player offline)
local function applyToSave(d, c)
	if c.reset then return PlayerData.fresh() end
	if c.level then
		local lv = math.clamp(math.floor(c.level), 1, MAX_LEVEL)
		d.LevelUnlocked = lv d.SelectedLevel = lv d.LevelTime = 0 d.Title = LevelConfig.name(lv)
	end
	if c.coins then
		d.Coins = d.Coins or { Common = PlayerData.STARTING_COINS.Common, Event = PlayerData.STARTING_COINS.Event }
		for cur, amt in pairs(c.coins) do d.Coins[cur] = math.max(0, math.floor(amt)) end
	end
	if c.owned then
		local set, eq = {}, {}
		for _, id in ipairs(d.Owned) do set[id] = true end
		for _, id in ipairs(d.Equipped) do eq[id] = true end
		for id, own in pairs(c.owned) do set[id] = own and true or nil if not own then eq[id] = nil end end
		d.Owned, d.Equipped = {}, {}
		for id in pairs(set) do table.insert(d.Owned, id) end
		for id in pairs(eq) do table.insert(d.Equipped, id) end
	end
	if c.inventory then
		for id, n in pairs(c.inventory) do
			n = math.max(0, math.floor(n))
			d.Inventory[id] = n > 0 and n or nil
		end
	end
	if c.stats then
		for stat, n in pairs(c.stats) do d[stat] = math.max(0, math.floor(n)) end
		local total = 0
		for _, s in ipairs(EVENT_STATS) do total += tonumber(d[s]) or 0 end
		d.EventsJoined = total
	end
	return d
end

-- clean the client's change table (never trust the client)
local function sanitize(c)
	if type(c) ~= "table" then return nil end
	local out = {}
	if c.reset == true then out.reset = true return out end
	if tonumber(c.level) then out.level = tonumber(c.level) end
	if type(c.coins) == "table" then
		out.coins = {}
		for _, cur in ipairs({ "Common", "Event" }) do if tonumber(c.coins[cur]) then out.coins[cur] = math.clamp(tonumber(c.coins[cur]), 0, 1e9) end end
	end
	local valid = {}
	for cat, items in pairs(ShopItems) do for _, it in ipairs(items) do valid[it.Id] = cat end end
	if type(c.owned) == "table" then
		out.owned = {}
		for id, v in pairs(c.owned) do if valid[id] and valid[id] ~= "Consumable" then out.owned[id] = v == true end end
	end
	if type(c.inventory) == "table" then
		out.inventory = {}
		for id, v in pairs(c.inventory) do if valid[id] == "Consumable" and tonumber(v) then out.inventory[id] = math.clamp(tonumber(v), 0, 99999) end end
	end
	if type(c.stats) == "table" then
		out.stats = {}
		for _, s in ipairs(EDITABLE_STATS) do if tonumber(c.stats[s]) then out.stats[s] = math.clamp(tonumber(c.stats[s]), 0, 1e7) end end
	end
	return out
end

local function commit(userId, c)
	local p = findPlayer(userId)
	if p then
		applyLive(p, c)
		task.spawn(PlayerData.save, p)
		return true, "Saved — applied live to " .. p.Name
	end
	-- not in this server: tell other servers (if they have the player) and edit the save
	publish({ a = "apply", u = userId, c = c })
	local ok, err = PlayerData.updateOffline(userId, function(d) return applyToSave(d, c) end)
	if not ok then return false, "Could not save: " .. tostring(err) end
	return true, "Saved to the player's data (offline / other server)"
end

---------------------------------------------------------------- bans & kicks
local function kickLocal(userId, msg)
	local p = findPlayer(userId)
	if p then p:Kick(msg) return true end
	return false
end
local function banMessage(b)
	return string.format("You are banned from Samar College for %s more.\nReason: %s", fmtDuration(b.untilTime - os.time()), b.reason or "No reason given")
end

Players.PlayerAdded:Connect(function(p)
	local b = getBan(p.UserId)
	if b then p:Kick(banMessage(b)) return end
	givePanel(p)
end)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(givePanel, p) end

pcall(function()
	MessagingService:SubscribeAsync(TOPIC, function(message)
		local m = message.Data
		if type(m) ~= "table" then return end
		local p = m.u and findPlayer(m.u)
		if m.a == "kick" and p then p:Kick(m.r or "You were kicked by an admin.")
		elseif m.a == "apply" and p then applyLive(p, m.c or {}) task.spawn(PlayerData.save, p)
		elseif m.a == "admins" then
			loadAdmins()
			for _, pl in ipairs(Players:GetPlayers()) do givePanel(pl) end
		end
	end)
end)

---------------------------------------------------------------- request handler
local lastCall = {}
local function protectTarget(caller, targetId)
	if isOwner(targetId) and not isOwner(caller.UserId) then return "You can't do that to the owner" end
	if coAdmins[targetId] and not isOwner(caller.UserId) and targetId ~= caller.UserId then return "Only the owner can do that to another admin" end
	return nil
end

local handlers = {}

handlers.init = function(caller)
	local list = {}
	for _, p in ipairs(Players:GetPlayers()) do table.insert(list, { userId = p.UserId, name = p.Name, displayName = p.DisplayName }) end
	return { ok = true, role = roleOf(caller.UserId), items = itemList(), levels = (function() local t = {} for i, l in ipairs(LevelConfig.Levels) do t[i] = l.Name end return t end)(),
		stats = EDITABLE_STATS, players = list, studio = game:GetService("RunService"):IsStudio() }
end

handlers.players = function()
	local list = {}
	for _, p in ipairs(Players:GetPlayers()) do table.insert(list, { userId = p.UserId, name = p.Name, displayName = p.DisplayName }) end
	return { ok = true, players = list }
end

handlers.lookup = function(caller, args)
	local userId, name, display = resolve(args.query)
	if not userId then return { ok = false, msg = name } end
	local p = findPlayer(userId)
	local data, existed
	if p then data = liveData(p) existed = true
	else
		local d, err, ex = PlayerData.readOffline(userId)
		if not d then return { ok = false, msg = "Couldn't read saved data: " .. tostring(err) } end
		data = d existed = ex
		data.LevelUnlocked = data.LevelUnlocked or 1
		data.Coins = data.Coins or { Common = PlayerData.STARTING_COINS.Common, Event = PlayerData.STARTING_COINS.Event }
	end
	local ownedSet = {} for _, id in ipairs(data.Owned or {}) do ownedSet[id] = true end
	local stats = {} for _, s in ipairs(EDITABLE_STATS) do stats[s] = tonumber(data[s]) or 0 end
	local b = getBan(userId)
	local okS, seen = pcall(PlayerRecords.brief, userId)
	local okR, reports = pcall(PlayerReports.countFor, userId)
	return { ok = true, userId = userId, name = name, displayName = p and p.DisplayName or display,
		online = p ~= nil, role = roleOf(userId), hasSave = existed, seen = okS and seen or nil, reports = okR and reports or 0,
		ban = b and { left = fmtDuration(b.untilTime - os.time()), reason = b.reason, by = b.by } or nil,
		level = tonumber(data.LevelUnlocked) or 1, time = tonumber(data.Time) or 0, levelTime = tonumber(data.LevelTime) or 0,
		coins = { Common = tonumber(data.Coins.Common) or 0, Event = tonumber(data.Coins.Event) or 0 },
		owned = ownedSet, inventory = data.Inventory or {}, stats = stats,
		powers = p and { invisible = p:GetAttribute("AdminInvisible") == true, god = p:GetAttribute("AdminGod") == true,
			fly = p:GetAttribute("AdminFly") == true, flySpeed = p:GetAttribute("AdminFlySpeed") or 50,
			speed = p:GetAttribute("AdminSpeed") } or nil }
end

handlers.save = function(caller, args)
	local userId = tonumber(args.userId) if not userId then return { ok = false, msg = "No player selected" } end
	local deny = protectTarget(caller, userId) if deny then return { ok = false, msg = deny } end
	local c = sanitize(args.changes)
	if not c or next(c) == nil then return { ok = false, msg = "Nothing to save" } end
	if c.reset then return { ok = false, msg = "Use the Reset Progress button" } end
	local ok, msg = commit(userId, c)
	return { ok = ok, msg = msg }
end

handlers.reset = function(caller, args)
	local userId = tonumber(args.userId) if not userId then return { ok = false, msg = "No player selected" } end
	local deny = protectTarget(caller, userId) if deny then return { ok = false, msg = deny } end
	local ok, msg = commit(userId, { reset = true })
	return { ok = ok, msg = ok and "Progress reset to a brand-new student" or msg }
end

handlers.kick = function(caller, args)
	local userId = tonumber(args.userId) if not userId then return { ok = false, msg = "No player selected" } end
	if userId == caller.UserId then return { ok = false, msg = "You can't kick yourself" } end
	local deny = protectTarget(caller, userId) if deny then return { ok = false, msg = deny } end
	local reason = type(args.reason) == "string" and args.reason:sub(1, 200) or ""
	local msg = "You were kicked from Samar College by an admin." .. (reason ~= "" and ("\nReason: " .. reason) or "")
	if kickLocal(userId, msg) then return { ok = true, msg = "Kicked from this server" } end
	publish({ a = "kick", u = userId, r = msg })
	return { ok = true, msg = "Kick sent to all servers (player isn't in this one)" }
end

handlers.ban = function(caller, args)
	local userId = tonumber(args.userId) if not userId then return { ok = false, msg = "No player selected" } end
	if userId == caller.UserId then return { ok = false, msg = "You can't ban yourself" } end
	local deny = protectTarget(caller, userId) if deny then return { ok = false, msg = deny } end
	local amount = tonumber(args.amount)
	local unitSec = ({ Seconds = 1, Minutes = 60, Hours = 3600, Days = 86400 })[args.unit or ""]
	if not amount or amount <= 0 or not unitSec then return { ok = false, msg = "Enter how long to ban (number + unit)" } end
	local seconds = math.floor(math.min(amount * unitSec, 3650 * 86400))
	if not banStore then return { ok = false, msg = "Ban DataStore unavailable (enable API access)" } end
	local reason = type(args.reason) == "string" and args.reason:sub(1, 200) or ""
	local okN, tName = pcall(function() return Players:GetNameFromUserIdAsync(userId) end)
	local b = { untilTime = os.time() + seconds, reason = reason ~= "" and reason or "Banned by an admin", by = caller.Name, at = os.time(), name = okN and tName or tostring(userId) }
	local ok, err = pcall(function() banStore:SetAsync("b_" .. userId, b) end)
	if not ok then return { ok = false, msg = "Could not save ban: " .. tostring(err) } end
	local msg = banMessage(b)
	if not kickLocal(userId, msg) then publish({ a = "kick", u = userId, r = msg }) end
	return { ok = true, msg = "Banned for " .. fmtDuration(seconds) }
end

handlers.unban = function(caller, args)
	local userId = tonumber(args.userId) if not userId then return { ok = false, msg = "No player selected" } end
	if not banStore then return { ok = false, msg = "Ban DataStore unavailable" } end
	local ok, err = pcall(function() banStore:RemoveAsync("b_" .. userId) end)
	return { ok = ok, msg = ok and "Ban removed" or tostring(err) }
end

local function saveAdmins()
	if not adminStore then return false, "Admin DataStore unavailable (enable API access)" end
	local out = {}
	for id, v in pairs(coAdmins) do out[tostring(id)] = v end
	local ok, err = pcall(function() adminStore:SetAsync("coadmins", out) end)
	publish({ a = "admins" })
	return ok, err
end

handlers.setAdmin = function(caller, args)
	if not isOwner(caller.UserId) then return { ok = false, msg = "Only the owner can manage co-admins" } end
	local userId = tonumber(args.userId) if not userId then return { ok = false, msg = "No player selected" } end
	if isOwner(userId) then return { ok = false, msg = "That's the owner" } end
	if args.make then
		coAdmins[userId] = { name = tostring(args.name or userId), by = caller.Name, at = os.time() }
	else
		coAdmins[userId] = nil
	end
	local ok, err = saveAdmins()
	local p = findPlayer(userId) if p then givePanel(p) end
	if not ok then return { ok = false, msg = tostring(err) } end
	return { ok = true, msg = args.make and "Promoted to Co-Admin" or "Removed from Co-Admin (now a regular player)" }
end

handlers.listAdmins = function(caller)
	local list = {}
	for id, v in pairs(coAdmins) do table.insert(list, { userId = id, name = v.name, by = v.by }) end
	return { ok = true, admins = list, canManage = isOwner(caller.UserId) }
end

---------------------------------------------------------------- admin powers (players in this server)
local NORMAL_SPEED = 16
local invisSaved = {} -- [character] = { [instance] = { prop, value } }

local function setInvisible(p, on)
	local char = p.Character
	if not char then return end
	if on then
		if invisSaved[char] then return end
		local saved = {}
		for _, d in ipairs(char:GetDescendants()) do
			if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then saved[d] = { "Transparency", d.Transparency } d.Transparency = 1 d:SetAttribute("AdminHidden", true)
			elseif d:IsA("Decal") or d:IsA("Texture") then saved[d] = { "Transparency", d.Transparency } d.Transparency = 1 d:SetAttribute("AdminHidden", true)
			elseif d:IsA("BillboardGui") or d:IsA("SurfaceGui") then saved[d] = { "Enabled", d.Enabled } d.Enabled = false
			elseif d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") or d:IsA("PointLight") then saved[d] = { "Enabled", d.Enabled } d.Enabled = false end
		end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then saved[hum] = { "DisplayDistanceType", hum.DisplayDistanceType } hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
		invisSaved[char] = saved
		-- things added later (tools, hats) also hidden
		saved.__conn = char.DescendantAdded:Connect(function(d)
			task.defer(function()
				if not invisSaved[char] then return end
				if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then invisSaved[char][d] = { "Transparency", d.Transparency } d.Transparency = 1 d:SetAttribute("AdminHidden", true)
				elseif d:IsA("Decal") or d:IsA("Texture") then invisSaved[char][d] = { "Transparency", d.Transparency } d.Transparency = 1 d:SetAttribute("AdminHidden", true) end
			end)
		end)
	else
		local saved = invisSaved[char]
		if not saved then return end
		if saved.__conn then saved.__conn:Disconnect() saved.__conn = nil end
		for inst, v in pairs(saved) do
			if typeof(inst) == "Instance" and inst.Parent then
				if inst:GetAttribute("AdminHidden") then inst:SetAttribute("AdminHidden", nil) end
				inst[v[1]] = v[2]
			end
		end
		invisSaved[char] = nil
	end
end

local godConns = {}
local function setGod(p, on)
	local char = p.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if godConns[p] then godConns[p]:Disconnect() godConns[p] = nil end
	if not hum then return end
	if on then
		hum.MaxHealth = math.huge hum.Health = math.huge
		godConns[p] = hum.HealthChanged:Connect(function(h) if h < math.huge then hum.Health = math.huge end end)
	else
		hum.MaxHealth = 100 hum.Health = 100
	end
end

local function applySpeed(p)
	refreshGear:Fire(p) -- ShopServer uses AdminSpeed (if set) when it sets WalkSpeed
	local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
	local sp = p:GetAttribute("AdminSpeed")
	if hum and sp then hum.WalkSpeed = sp end
end

local function reapplyPowers(p)
	if p:GetAttribute("AdminInvisible") then setInvisible(p, true) end
	if p:GetAttribute("AdminGod") then setGod(p, true) end
	if p:GetAttribute("AdminSpeed") then applySpeed(p) end
end
local function hookPlayer(p)
	p.CharacterAdded:Connect(function(char)
		char:WaitForChild("Humanoid", 10)
		task.wait(1.5) -- after avatar sizing / cosmetics
		reapplyPowers(p)
	end)
end
Players.PlayerAdded:Connect(hookPlayer)
for _, p in ipairs(Players:GetPlayers()) do hookPlayer(p) end
Players.PlayerRemoving:Connect(function(p) if godConns[p] then godConns[p]:Disconnect() godConns[p] = nil end end)

handlers.power = function(caller, args)
	local userId = tonumber(args.userId) if not userId then return { ok = false, msg = "No player selected" } end
	local deny = protectTarget(caller, userId) if deny then return { ok = false, msg = deny } end
	local p = findPlayer(userId)
	if not p then return { ok = false, msg = "Powers only work on players in THIS server" } end
	local on = args.on == true
	local kind = args.power
	if kind == "invisible" then
		p:SetAttribute("AdminInvisible", on or nil) setInvisible(p, on)
		return { ok = true, msg = "Invisible " .. (on and "ON" or "OFF") .. " for " .. p.Name }
	elseif kind == "god" then
		p:SetAttribute("AdminGod", on or nil) setGod(p, on)
		return { ok = true, msg = "God mode " .. (on and "ON" or "OFF") .. " for " .. p.Name }
	elseif kind == "fly" then
		local sp = math.clamp(tonumber(args.value) or p:GetAttribute("AdminFlySpeed") or 50, 1, 500)
		p:SetAttribute("AdminFlySpeed", sp)
		p:SetAttribute("AdminFly", on or nil)
		return { ok = true, msg = "Fly " .. (on and ("ON at speed " .. sp) or "OFF") .. " for " .. p.Name }
	elseif kind == "speed" then
		if on then
			local sp = math.clamp(tonumber(args.value) or 32, 1, 500)
			p:SetAttribute("AdminSpeed", sp)
		else
			p:SetAttribute("AdminSpeed", nil)
		end
		applySpeed(p)
		return { ok = true, msg = on and ("Speed set to " .. p:GetAttribute("AdminSpeed") .. " for " .. p.Name) or ("Speed back to normal for " .. p.Name) }
	end
	return { ok = false, msg = "Unknown power" }
end

handlers.listBans = function()
	if not banStore then return { ok = false, msg = "Ban DataStore unavailable (enable API access)" } end
	local out = {}
	local ok, err = pcall(function()
		local pages = banStore:ListKeysAsync("b_", 50)
		local keys = pages:GetCurrentPage()
		for _, k in ipairs(keys) do
			local id = tonumber((k.KeyName:gsub("^b_", "")))
			local b = id and getBan(id)
			if b then
				local name = b.name
				if not name then local okN, n = pcall(function() return Players:GetNameFromUserIdAsync(id) end) name = okN and n or tostring(id) end
				table.insert(out, { userId = id, name = name, left = fmtDuration(b.untilTime - os.time()), reason = b.reason, by = b.by })
			end
			if #out >= 50 then break end
		end
	end)
	if not ok then return { ok = false, msg = tostring(err) } end
	return { ok = true, bans = out }
end

---------------------------------------------------------------- player records (online in every server, time in / out, all players)
handlers.rec_online = function()
	local d = PlayerRecords.online()
	return { ok = true, players = d.players, servers = d.servers, live = d.live, here = d.here, now = os.time() }
end

handlers.rec_list = function(caller, args)
	local res = PlayerRecords.list(caller.UserId, args.sort, args.more == true)
	res.now = os.time()
	return res
end

handlers.rec_history = function(caller, args)
	local id = tonumber(args.userId)
	if not id then
		local uid, name = resolve(args.query)
		if not uid then return { ok = false, msg = name } end
		id = uid
	end
	local res = PlayerRecords.history(id)
	res.now = os.time()
	return res
end

handlers.rec_activity = function()
	local res = table.clone(PlayerRecords.activity())
	res.now = os.time()
	return res
end

handlers.rec_backfill = function(caller)
	if not isOwner(caller.UserId) then return { ok = false, msg = "Only the owner can do this" } end
	local ok, msg = PlayerRecords.backfill()
	return { ok = ok, msg = msg }
end

-- go next to a player in this server
handlers.rec_goto = function(caller, args)
	local p = findPlayer(tonumber(args.userId) or 0)
	if not p then return { ok = false, msg = "That player isn't in this server" } end
	if p == caller then return { ok = false, msg = "That's you" } end
	local them = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
	local me = caller.Character
	local hum = me and me:FindFirstChildOfClass("Humanoid")
	if not them or not me or not hum then return { ok = false, msg = "No character to move" } end
	hum.Sit = false
	local spot = them.CFrame * CFrame.new(0, 0, 4)
	me:PivotTo(CFrame.lookAt(spot.Position, Vector3.new(them.Position.X, spot.Position.Y, them.Position.Z)))
	return { ok = true, msg = "Teleported next to " .. p.Name }
end

-- join the server another player is in
handlers.rec_join = function(caller, args)
	local job = type(args.job) == "string" and args.job or nil
	if not job then return { ok = false, msg = "No server selected" } end
	if job == PlayerRecords.JOB then return { ok = false, msg = "You're already in this server" } end
	local s = PlayerRecords.serverOf(job)
	if not s then return { ok = false, msg = "That server isn't online anymore" } end
	if s.kind ~= "Public" then return { ok = false, msg = "That's a " .. tostring(s.kind) .. " server, it can't be joined from here" } end
	if RunService:IsStudio() then return { ok = false, msg = "Joining another server only works in the live game" } end
	local opts = Instance.new("TeleportOptions")
	opts.ServerInstanceId = job
	local ok, err = pcall(function() TeleportService:TeleportAsync(tonumber(s.pl) or game.PlaceId, { caller }, opts) end)
	return { ok = ok, msg = ok and ("Joining server " .. tostring(s.sc) .. "...") or ("Couldn't join: " .. tostring(err)) }
end

---------------------------------------------------------------- player reports (🚩 Reports tab)
handlers.rep_list = function(caller, args)
	local res = PlayerReports.list(caller.UserId, args.filter, args.more == true, args.target)
	res.now = os.time()
	return res
end

-- status = "open" (waiting for review) | "investigating" | "done" (with outcome + proof note)
handlers.rep_status = function(caller, args)
	local res = PlayerReports.setStatus(caller, roleOf(caller.UserId), args.id, args.status, args.outcome, args.note)
	res.now = os.time()
	return res
end

handlers.rep_counts = function()
	return { ok = true, counts = PlayerReports.counts() }
end

-- tell the admins in this server about new reports and who is checking them
PlayerReports.Notice:Connect(function(msg)
	for _, p in ipairs(Players:GetPlayers()) do
		if isAdmin(p.UserId) then adminNotice:FireClient(p, msg) end
	end
end)

fn.OnServerInvoke = function(caller, action, args)
	if not isAdmin(caller.UserId) then return { ok = false, msg = "Not an admin" } end
	-- allow bursts (the panel sends a few requests when it opens), max 20 requests per 5 seconds
	local now = os.clock()
	local rec = lastCall[caller]
	if not rec or now - rec.start > 5 then rec = { start = now, n = 0 } lastCall[caller] = rec end
	rec.n += 1
	if rec.n > 20 then return { ok = false, msg = "Slow down" } end
	local h = handlers[action]
	if not h then return { ok = false, msg = "Unknown action" } end
	local ok, res = pcall(h, caller, type(args) == "table" and args or {})
	if not ok then warn("[AdminServer] " .. tostring(res)) return { ok = false, msg = "Server error: " .. tostring(res) } end
	return res
end
Players.PlayerRemoving:Connect(function(p) lastCall[p] = nil end)
