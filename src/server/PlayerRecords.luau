-- PlayerRecords: who is online in every server, where they are on campus, and every time in / time out.
-- Shown in the admin panel (📋 Player Records). What is kept:
--   SamarCollege_Sessions_v1  DataStore         u_<UserId>: name, first join, last time in / out, number of joins,
--                                                 a progress summary and the last 40 sessions (time in, time out, server)
--   SamarCollege_LastSeen_v1  OrderedDataStore  <UserId> = last time seen (unix time)   -> "All players", newest first
--   SamarCollege_PlayTime_v1  OrderedDataStore  <UserId> = total seconds on campus      -> "All players", most time first
-- Live data in MemoryStore (shared by all servers, removed by itself):
--   SC_Online_v1    <UserId> -> server, place, area on campus, time in  (gone 2 min after the server stops updating it)
--   SC_Servers_v1   <JobId>  -> server code, player count, start time
--   SC_Sessions_v1  everyone's recent time in / time out (kept 3 days)
-- In Studio without "Enable Studio Access to API Services" it all still works, but only for the
-- current test session (nothing is saved).
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local HUDConfig = require(RS:WaitForChild("HUDConfig"))

local PlayerRecords = {}

local MAX_LOG = 40              -- sessions kept per player
local HEARTBEAT = 30            -- seconds between live updates
local PRESENCE_TTL = 120        -- live entries disappear this long after a server stops updating them
local FEED_TTL = 3 * 86400      -- recent time in / out list keeps 3 days
local FEED_MAX = 100
local PAGE_SIZE = 20

local IS_STUDIO = RunService:IsStudio()
local JOB = (not IS_STUDIO and game.JobId ~= "") and game.JobId or ("studio-" .. HttpService:GenerateGUID(false):gsub("-", ""):sub(1, 8))
local SERVER_CODE = IS_STUDIO and "STUDIO" or JOB:sub(1, 8):upper()
local SERVER_START = os.time()
local SERVER_KIND = IS_STUDIO and "Studio test"
	or (game.PrivateServerId ~= "" and (game.PrivateServerOwnerId ~= 0 and "VIP" or "Reserved") or "Public")
local ELEM_ID = tonumber(HUDConfig.ElementaryPlaceId) or 0
local PLACE_LABEL = (ELEM_ID ~= 0 and game.PlaceId == ELEM_ID) and "Elementary" or "Main campus"

PlayerRecords.JOB = JOB
PlayerRecords.SERVER_CODE = SERVER_CODE

---------------------------------------------------------------- Studio stand-ins (only when the real stores are switched off)
local function fakeDataStore()
	local data, s = {}, {}
	function s:GetAsync(k) return data[k] end
	function s:SetAsync(k, v) data[k] = v end
	function s:RemoveAsync(k) local v = data[k] data[k] = nil return v end
	function s:UpdateAsync(k, fn) local v = fn(data[k]) if v ~= nil then data[k] = v end return v end
	function s:GetSortedAsync(ascending, pageSize)
		local items = {}
		for k, v in pairs(data) do table.insert(items, { key = k, value = v }) end
		table.sort(items, function(a, b) if ascending then return a.value < b.value end return a.value > b.value end)
		local page, pages = 1, {}
		function pages:GetCurrentPage()
			local out = {}
			for i = (page - 1) * pageSize + 1, math.min(#items, page * pageSize) do table.insert(out, items[i]) end
			return out
		end
		function pages:AdvanceToNextPageAsync() page += 1 pages.IsFinished = #items <= page * pageSize end
		pages.IsFinished = #items <= pageSize
		return pages
	end
	return s
end

local function fakeSortedMap()
	local data, m = {}, {}
	local function alive(k)
		local e = data[k]
		if e and e.exp < os.time() then data[k] = nil return nil end
		return e
	end
	function m:SetAsync(k, v, ttl) data[k] = { v = v, exp = os.time() + ttl } return true end
	function m:GetAsync(k) local e = alive(k) return e and e.v end
	function m:RemoveAsync(k) data[k] = nil end
	function m:UpdateAsync(k, fn, ttl)
		local e = alive(k)
		local v = fn(e and e.v)
		if v ~= nil then data[k] = { v = v, exp = os.time() + ttl } end
		return v
	end
	function m:GetRangeAsync(dir, count)
		local keys = {}
		for k in pairs(data) do if alive(k) then table.insert(keys, k) end end
		table.sort(keys, function(a, b) if dir == Enum.SortDirection.Descending then return a > b end return a < b end)
		local out = {}
		for i = 1, math.min(count, #keys) do out[i] = { key = keys[i], value = data[keys[i]].v } end
		return out
	end
	return m
end

---------------------------------------------------------------- open the stores
local stores = {}
local fakeDS, fakeMS = false, false
do
	local okDS = pcall(function()
		stores.sessions = DataStoreService:GetDataStore("SamarCollege_Sessions_v1")
		stores.lastSeen = DataStoreService:GetOrderedDataStore("SamarCollege_LastSeen_v1")
		stores.playTime = DataStoreService:GetOrderedDataStore("SamarCollege_PlayTime_v1")
	end)
	okDS = okDS and pcall(function() return stores.sessions:GetAsync("probe") end)
	if not okDS then
		fakeDS = true
		stores.sessions, stores.lastSeen, stores.playTime = fakeDataStore(), fakeDataStore(), fakeDataStore()
		if IS_STUDIO then
			warn("[PlayerRecords] DataStores are off in Studio: Player Records keeps this test session only.")
		else
			warn("[PlayerRecords] DataStores unavailable: Player Records keeps this server only.")
		end
	end
	local okMS = pcall(function()
		stores.online = MemoryStoreService:GetSortedMap("SC_Online_v1")
		stores.servers = MemoryStoreService:GetSortedMap("SC_Servers_v1")
		stores.feed = MemoryStoreService:GetSortedMap("SC_Sessions_v1")
	end)
	okMS = okMS and pcall(function() return stores.online:GetRangeAsync(Enum.SortDirection.Ascending, 1) end)
	if not okMS then
		fakeMS = true
		stores.online, stores.servers, stores.feed = fakeSortedMap(), fakeSortedMap(), fakeSortedMap()
	end
end
function PlayerRecords.isLive() return not fakeDS, not fakeMS end

local pendingWrites = 0
local function bg(fn)
	pendingWrites += 1
	task.spawn(function()
		local ok, err = pcall(fn)
		if not ok then warn("[PlayerRecords] " .. tostring(err)) end
		pendingWrites -= 1
	end)
end

---------------------------------------------------------------- where on campus (rooms, common areas, outside spots)
local zones = {}
local FLOOR_LABEL = { ["1F_Ground"] = "1F", ["2F"] = "2F", ["3F"] = "3F", ["4F"] = "4F", Roof = "Roof" }

local function partBounds(p)
	local cf, s = p.CFrame, p.Size
	local r, u, b = cf.RightVector, cf.UpVector, cf.LookVector
	local half = Vector3.new(
		math.abs(r.X) * s.X + math.abs(u.X) * s.Y + math.abs(b.X) * s.Z,
		math.abs(r.Y) * s.X + math.abs(u.Y) * s.Y + math.abs(b.Y) * s.Z,
		math.abs(r.Z) * s.X + math.abs(u.Z) * s.Y + math.abs(b.Z) * s.Z) / 2
	return cf.Position - half, cf.Position + half
end
local function boundsOf(inst)
	local mn, mx
	local list = inst:IsA("BasePart") and { inst } or inst:GetDescendants()
	for _, d in ipairs(list) do
		if d:IsA("BasePart") then
			local a, b = partBounds(d)
			mn = mn and mn:Min(a) or a
			mx = mx and mx:Max(b) or b
		end
	end
	return mn, mx
end
local function nice(name)
	local s = name:gsub("_", " ")
	s = s:gsub("%f[%w]%dF%f[%W]", "") -- the floor is already shown in front ("1F · ...")
	s = s:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
	return s
end
local function addZone(label, mn, mx, minHeight)
	if not mn then return end
	if minHeight and mx.Y - mn.Y < minHeight then mx = Vector3.new(mx.X, mn.Y + minHeight, mx.Z) end
	local size = mx - mn
	if size.Y < 3 then return end -- flat decoration groups are not places
	table.insert(zones, { label = label, mn = mn, mx = mx, vol = math.max(1, size.X * size.Y * size.Z) })
end

local function buildZones()
	local campus = workspace:FindFirstChild("SamarCollege_Campus")
	if campus then
		for folderName, floor in pairs(FLOOR_LABEL) do
			local F = campus:FindFirstChild(folderName)
			if F then
				for _, sub in ipairs({ "02_Rooms", "07_Common_Areas" }) do
					local S = F:FindFirstChild(sub)
					if S then
						for _, room in ipairs(S:GetChildren()) do
							if not room.Name:find("CeilingLights") then
								local a, b = boundsOf(room)
								addZone(floor .. " · " .. nice(room.Name), a, b)
							end
							task.wait()
						end
					end
				end
			end
		end
		local function spot(label, inst, h)
			if not inst then return end
			local a, b = boundsOf(inst)
			addZone(label, a, b, h)
		end
		local front = campus:FindFirstChild("FrontCover")
		spot("Security Post", front and front:FindFirstChild("SecurityPost"), 14)
		spot("Front Garden", front and front:FindFirstChild("Garden"), 14)
		spot("Driveway", campus:FindFirstChild("Driveway"), 14)
		spot("Main Gate", campus:FindFirstChild("MainGate"), 14)
		local tower = campus:FindFirstChild("Tower_FB_Details")
		local tc = tower and tower:FindFirstChild("Classrooms")
		if tc then
			for _, fl in ipairs(tc:GetChildren()) do
				local a, b = boundsOf(fl)
				addZone(fl.Name .. " · FB Tower classrooms", a, b)
			end
		end
	end
	-- corridors in front of the FH rooms
	addZone("1F · Corridor", Vector3.new(83, -1, -125), Vector3.new(92, 15, 112))
	addZone("2F · Corridor", Vector3.new(83, 15, -125), Vector3.new(92, 30, 112))
	-- the street outside the gate
	local street = workspace:FindFirstChild("SanRoqueStreet")
	local marks = street and street:FindFirstChild("RoadMarkings")
	if marks then
		local a, b = boundsOf(marks)
		if a then addZone("San Roque Street (outside campus)", Vector3.new(a.X - 8, a.Y - 3, a.Z), Vector3.new(b.X + 1, a.Y + 30, b.Z)) end
	end
	local shops = street and street:FindFirstChild("Buildings_West")
	if shops then
		local a, b = boundsOf(shops)
		if a then addZone("Shops across the street", a, Vector3.new(b.X - 3, b.Y, b.Z)) end -- not the sidewalk in front
	end
end
task.spawn(buildZones)

function PlayerRecords.areaOf(player)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return "Respawning" end
	local p = hrp.Position
	local best
	for _, z in ipairs(zones) do
		local a, b = z.mn, z.mx
		if p.X >= a.X and p.X <= b.X and p.Z >= a.Z and p.Z <= b.Z and p.Y >= a.Y and p.Y <= b.Y + 2 then
			if not best or z.vol < best.vol then best = z end
		end
	end
	if best then return best.label end
	local floor = p.Y < 16 and "1F" or p.Y < 31 and "2F" or p.Y < 45 and "3F" or p.Y < 59 and "4F" or "Roof"
	local near, nd
	for _, place in ipairs(HUDConfig.Places or {}) do
		local d = (place.Position - p).Magnitude
		if d < 45 and (not nd or d < nd) then near, nd = place.Name, d end
	end
	if floor == "1F" then return near and ("Near " .. near) or "Campus grounds" end
	return floor .. " · Hallway / stairs"
end

---------------------------------------------------------------- live tracking
local sess = {}          -- [userId] = { start = unix, closed = bool }
local recCache = {}      -- [userId] = { t = clock, rec = table }
local function cacheDrop(id) recCache[id] = nil end

local function summaryOf(p)
	local snap = PlayerData.snapshot(p) or PlayerData.lastSnapshot(p.UserId)
	if not snap then return {} end
	return { title = snap.Title, level = snap.LevelUnlocked, time = math.floor(tonumber(snap.Time) or 0),
		common = snap.Coins and snap.Coins.Common, event = snap.Coins and snap.Coins.Event,
		events = snap.EventsJoined, quizzes = snap.QuizzesPassed }
end
PlayerRecords.summaryOf = summaryOf

local function serverInfo()
	return { job = JOB, sc = SERVER_CODE, pl = game.PlaceId, pk = PLACE_LABEL, kind = SERVER_KIND, start = SERVER_START,
		n = #Players:GetPlayers(), max = Players.MaxPlayers, ts = os.time() }
end

local function presenceOf(p)
	local s = sess[p.UserId]
	local sum = summaryOf(p)
	return { u = p.UserId, n = p.Name, d = p.DisplayName, job = JOB, sc = SERVER_CODE, pl = game.PlaceId, pk = PLACE_LABEL,
		kind = SERVER_KIND, t = s and s.start or os.time(), a = PlayerRecords.areaOf(p), title = sum.title, lv = sum.level,
		tm = sum.time, ts = os.time() }
end

local function feedKey(t, userId) return string.format("%010d_%d", t, userId) end

local function onJoin(p)
	local id = p.UserId
	if sess[id] and not sess[id].closed then return end
	local now = os.time()
	sess[id] = { start = now }
	cacheDrop(id)
	bg(function()
		stores.sessions:UpdateAsync("u_" .. id, function(old)
			local r = type(old) == "table" and old or {}
			r.name, r.display = p.Name, p.DisplayName
			r.first = r.first or now
			r.lastIn = math.max(r.lastIn or 0, now)
			r.log = type(r.log) == "table" and r.log or {}
			for _, e in ipairs(r.log) do
				if e.i == now and e.s == SERVER_CODE then return r end -- already written
			end
			table.insert(r.log, 1, { i = now, s = SERVER_CODE, p = PLACE_LABEL })
			r.count = (r.count or 0) + 1
			while #r.log > MAX_LOG do table.remove(r.log) end
			return r
		end)
	end)
	bg(function() stores.lastSeen:SetAsync(tostring(id), now) end)
	bg(function()
		stores.feed:SetAsync(feedKey(now, id), { u = id, n = p.Name, d = p.DisplayName, i = now, s = SERVER_CODE, p = PLACE_LABEL }, FEED_TTL)
	end)
	task.delay(3, function() -- after the character has spawned, so the area is known
		local s = sess[id]
		if p.Parent and s and not s.closed and s.start == now then
			local rec = presenceOf(p)
			bg(function() stores.online:SetAsync(tostring(id), rec, PRESENCE_TTL) end)
			bg(function() stores.servers:SetAsync(JOB, serverInfo(), PRESENCE_TTL) end)
			if rec.tm then s.listed = true bg(function() stores.playTime:SetAsync(tostring(id), rec.tm) end) end -- listed under "Most time" right away
		end
	end)
end

local function onLeave(p)
	local id = p.UserId
	local s = sess[id]
	if not s or s.closed then return end
	s.closed = true
	local now, start = os.time(), s.start
	local sum = summaryOf(p)
	cacheDrop(id)
	bg(function()
		stores.sessions:UpdateAsync("u_" .. id, function(old)
			local r = type(old) == "table" and old or {}
			r.name, r.display = p.Name, p.DisplayName
			r.first = r.first or start
			r.lastIn = math.max(r.lastIn or 0, start)
			r.lastOut = now
			r.log = type(r.log) == "table" and r.log or {}
			local entry
			for _, e in ipairs(r.log) do
				if e.i == start and e.s == SERVER_CODE then entry = e break end
			end
			if not entry then
				entry = { i = start, s = SERVER_CODE, p = PLACE_LABEL }
				table.insert(r.log, entry)
				r.count = (r.count or 0) + 1
				table.sort(r.log, function(a, b) return (a.i or 0) > (b.i or 0) end)
			end
			entry.o = now
			while #r.log > MAX_LOG do table.remove(r.log) end
			if next(sum) then r.sum = sum end
			return r
		end)
	end)
	bg(function() stores.lastSeen:SetAsync(tostring(id), now) end)
	if sum.time then bg(function() stores.playTime:SetAsync(tostring(id), sum.time) end) end
	bg(function()
		stores.feed:UpdateAsync(feedKey(start, id), function(v)
			v = type(v) == "table" and v or { u = id, n = p.Name, d = p.DisplayName, i = start, s = SERVER_CODE, p = PLACE_LABEL }
			v.o = now
			return v
		end, FEED_TTL)
	end)
	bg(function()
		-- only remove the live entry if it is still ours (they may already be in another server)
		local cur = stores.online:GetAsync(tostring(id))
		if type(cur) ~= "table" or cur.job == JOB then stores.online:RemoveAsync(tostring(id)) end
	end)
end

local function heartbeat()
	local srv = serverInfo()
	bg(function() stores.servers:SetAsync(JOB, srv, PRESENCE_TTL) end)
	for _, p in ipairs(Players:GetPlayers()) do
		local s = sess[p.UserId]
		if s and not s.closed then
			local rec = presenceOf(p)
			bg(function() stores.online:SetAsync(tostring(p.UserId), rec, PRESENCE_TTL) end)
			if rec.tm and not s.listed then -- their save loaded after the first check
				s.listed = true
				bg(function() stores.playTime:SetAsync(tostring(p.UserId), rec.tm) end)
			end
		end
	end
end

Players.PlayerAdded:Connect(onJoin)
Players.PlayerRemoving:Connect(onLeave)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(onJoin, p) end
task.spawn(function()
	while true do
		task.wait(HEARTBEAT)
		heartbeat()
	end
end)
game:BindToClose(function()
	for _, p in ipairs(Players:GetPlayers()) do onLeave(p) end
	bg(function() stores.servers:RemoveAsync(JOB) end)
	local t0 = os.clock()
	while pendingWrites > 0 and os.clock() - t0 < 20 do task.wait(0.1) end
end)

---------------------------------------------------------------- reading (admin panel)
local function getRecord(id)
	local c = recCache[id]
	if c and os.clock() - c.t < 60 then return c.rec end
	local ok, rec = pcall(function() return stores.sessions:GetAsync("u_" .. id) end)
	if not ok then return nil, tostring(rec) end
	recCache[id] = { t = os.clock(), rec = rec }
	return rec
end

-- everyone online right now, in every server
local onlineCache
function PlayerRecords.online(force)
	if not force and onlineCache and os.clock() - onlineCache.t < 5 then return onlineCache.data, onlineCache.byId end
	local players, servers = {}, {}
	local ok1, items = pcall(function() return stores.online:GetRangeAsync(Enum.SortDirection.Ascending, 200) end)
	if ok1 then
		for _, it in ipairs(items) do
			local v = it.value
			if type(v) == "table" and v.u and v.job ~= JOB then players[tostring(v.u)] = v end
		end
	end
	local ok2, sitems = pcall(function() return stores.servers:GetRangeAsync(Enum.SortDirection.Ascending, 200) end)
	if ok2 then
		for _, it in ipairs(sitems) do
			local v = it.value
			if type(v) == "table" and v.job then servers[v.job] = v end
		end
	end
	-- this server is always up to date
	servers[JOB] = serverInfo()
	for _, p in ipairs(Players:GetPlayers()) do
		local s = sess[p.UserId]
		if s and not s.closed then players[tostring(p.UserId)] = presenceOf(p) end
	end
	local plist, slist, count = {}, {}, {}
	for _, v in pairs(players) do
		table.insert(plist, v)
		count[v.job] = (count[v.job] or 0) + 1
		if not servers[v.job] then servers[v.job] = { job = v.job, sc = v.sc, pl = v.pl, pk = v.pk, kind = v.kind } end
	end
	for job, s in pairs(servers) do
		local copy = table.clone(s)
		copy.here = job == JOB
		copy.count = count[job] or 0
		if copy.count > 0 or copy.here then table.insert(slist, copy) end
	end
	table.sort(slist, function(a, b)
		if a.here ~= b.here then return a.here end
		return (a.count or 0) > (b.count or 0)
	end)
	local data = { players = plist, servers = slist, here = JOB, code = SERVER_CODE, live = not fakeMS, ok = ok1 }
	onlineCache = { t = os.clock(), data = data, byId = players }
	return data, players
end

function PlayerRecords.presence(userId)
	local _, byId = PlayerRecords.online()
	return byId[tostring(userId)]
end

function PlayerRecords.serverOf(job)
	local data = PlayerRecords.online()
	for _, s in ipairs(data.servers) do if s.job == job then return s end end
	return nil
end

-- short info for the admin profile card
function PlayerRecords.brief(userId)
	local rec = getRecord(userId)
	local pr = PlayerRecords.presence(userId)
	local r = type(rec) == "table" and rec or {}
	return { first = r.first, lastIn = r.lastIn, lastOut = r.lastOut, count = r.count,
		on = pr ~= nil, sc = pr and pr.sc, a = pr and pr.a, t = pr and pr.t, job = pr and pr.job, here = pr ~= nil and pr.job == JOB }
end

local function buildRow(id, value, sort, byId)
	local row = { u = id }
	local rec = getRecord(id)
	if type(rec) == "table" then
		row.n, row.d = rec.name, rec.display
		row.first, row.lastIn, row.lastOut, row.count = rec.first, rec.lastIn, rec.lastOut, rec.count
		local s = rec.sum or {}
		row.title, row.lv, row.tm, row.cc, row.ec = s.title, s.level, s.time, s.common, s.event
	else
		-- a save from before Player Records ("Add older saves")
		local d = PlayerData.readOffline(id)
		if d then
			row.title, row.lv, row.tm = d.Title, d.LevelUnlocked, d.Time
			row.cc, row.ec = d.Coins and d.Coins.Common, d.Coins and d.Coins.Event
		end
		row.old = true
	end
	if not row.n then
		local ok, n = pcall(function() return Players:GetNameFromUserIdAsync(id) end)
		row.n = ok and n or tostring(id)
	end
	row.d = row.d or row.n
	local live = Players:GetPlayerByUserId(id)
	if live then
		local s = summaryOf(live)
		row.title, row.lv, row.tm = s.title or row.title, s.level or row.lv, s.time or row.tm
		row.cc, row.ec = s.common or row.cc, s.event or row.ec
	end
	local pr = byId[tostring(id)]
	if pr then
		row.on, row.sc, row.a, row.here = true, pr.sc, pr.a, pr.job == JOB
		row.title, row.lv, row.tm = pr.title or row.title, pr.lv or row.lv, pr.tm or row.tm
	end
	if sort == "seen" then row.seen = value end
	return row
end

-- the list of every player (20 per page)
local listState = {}
local backfillNote
function PlayerRecords.list(callerId, sort, more)
	sort = sort == "time" and "time" or "seen"
	local st = listState[callerId]
	local pages
	if more and st and st.sort == sort and not st.finished then
		local ok, err = pcall(function() st.pages:AdvanceToNextPageAsync() end)
		if not ok then return { ok = false, msg = "Couldn't load more: " .. tostring(err) } end
		pages = st.pages
	else
		local store = sort == "time" and stores.playTime or stores.lastSeen
		local ok, res = pcall(function() return store:GetSortedAsync(false, PAGE_SIZE) end)
		if not ok then return { ok = false, msg = "Couldn't read the player list: " .. tostring(res) } end
		pages = res
		st = { pages = pages, sort = sort }
		listState[callerId] = st
	end
	local entries = pages:GetCurrentPage()
	st.finished = pages.IsFinished
	local _, byId = PlayerRecords.online()
	local rows, left = {}, #entries
	for i, e in ipairs(entries) do
		task.spawn(function()
			local ok, res = pcall(buildRow, tonumber(e.key), e.value, sort, byId)
			rows[i] = ok and res or { u = tonumber(e.key), n = tostring(e.key), d = tostring(e.key), err = tostring(res) }
			left -= 1
		end)
	end
	local t0 = os.clock()
	while left > 0 and os.clock() - t0 < 20 do task.wait() end
	local out = {}
	for i = 1, #entries do if rows[i] then table.insert(out, rows[i]) end end
	return { ok = true, rows = out, more = not st.finished, sort = sort, live = not fakeDS, note = backfillNote }
end

-- one player's whole time in / time out history
function PlayerRecords.history(userId)
	cacheDrop(userId)
	local rec, err = getRecord(userId)
	if err then return { ok = false, msg = "Couldn't read the record: " .. err } end
	local r = type(rec) == "table" and rec or {}
	local name, display = r.name, r.display
	if not name then
		local ok, n = pcall(function() return Players:GetNameFromUserIdAsync(userId) end)
		name = ok and n or tostring(userId)
	end
	local sum = r.sum or {}
	local live = Players:GetPlayerByUserId(userId)
	if live then sum = summaryOf(live) display = live.DisplayName end
	if not next(sum) then
		local d = PlayerData.readOffline(userId)
		if d then sum = { title = d.Title, level = d.LevelUnlocked, time = d.Time, common = d.Coins and d.Coins.Common, event = d.Coins and d.Coins.Event } end
	end
	local pr = PlayerRecords.presence(userId)
	return { ok = true, u = userId, n = name, d = display or name, known = rec ~= nil,
		first = r.first, lastIn = r.lastIn, lastOut = r.lastOut, count = r.count, sum = sum, log = r.log or {},
		on = pr ~= nil, sc = pr and pr.sc, a = pr and pr.a, t = pr and pr.t, job = pr and pr.job, here = pr ~= nil and pr.job == JOB,
		kind = pr and pr.kind, live = not fakeDS }
end

-- everyone's recent time in / time out (newest first)
local feedCache
function PlayerRecords.activity()
	if feedCache and os.clock() - feedCache.t < 8 then return feedCache.data end
	local ok, items = pcall(function() return stores.feed:GetRangeAsync(Enum.SortDirection.Descending, FEED_MAX) end)
	if not ok then return { ok = false, msg = "Couldn't read recent activity: " .. tostring(items) } end
	local _, byId = PlayerRecords.online()
	local list = {}
	for _, it in ipairs(items) do
		local v = it.value
		if type(v) == "table" then
			local e = table.clone(v)
			local pr = byId[tostring(e.u)]
			if not e.o and pr and pr.t == e.i then e.on = true end
			table.insert(list, e)
		end
	end
	local data = { ok = true, items = list, live = not fakeMS, days = FEED_TTL // 86400 }
	feedCache = { t = os.clock(), data = data }
	return data
end

-- add players who only have an old save (from before Player Records) to the list
local backfillRunning = false
function PlayerRecords.backfill()
	if fakeDS then return false, "This needs the real DataStores (live game, or Studio with API access on)" end
	if backfillRunning then return false, "Already adding older saves, check back in a minute" end
	backfillRunning = true
	backfillNote = "Adding older saves..."
	task.spawn(function()
		local seen, added = 0, 0
		local ok, err = pcall(function()
			local store = DataStoreService:GetDataStore(PlayerData.STORE_NAME)
			local pages = store:ListKeysAsync("u_", 50)
			while true do
				for _, k in ipairs(pages:GetCurrentPage()) do
					local id = tonumber((k.KeyName:gsub("^u_", "")))
					if id then
						seen += 1
						local isNew = false
						stores.lastSeen:UpdateAsync(tostring(id), function(old)
							if old ~= nil then return nil end -- already listed
							isNew = true
							return 0 -- 0 = last seen before Player Records
						end)
						if isNew then
							added += 1
							local d = PlayerData.readOffline(id)
							if d then
								stores.playTime:UpdateAsync(tostring(id), function(old)
									if old ~= nil then return nil end
									return math.floor(tonumber(d.Time) or 0)
								end)
							end
							backfillNote = string.format("Adding older saves... %d added so far", added)
							task.wait(1.5) -- stay far below the DataStore limits
						end
					end
				end
				if pages.IsFinished then break end
				task.wait(1)
				pages:AdvanceToNextPageAsync()
			end
		end)
		backfillRunning = false
		backfillNote = ok and string.format("Older saves checked: %d saves, %d added to the list.", seen, added)
			or ("Adding older saves stopped: " .. tostring(err))
	end)
	return true, "Adding older saves in the background. Press Refresh in a minute."
end

return PlayerRecords
