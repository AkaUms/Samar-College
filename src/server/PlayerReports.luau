-- PlayerReports: players report someone who breaks the rules, and the admin team checks every report.
-- A report goes:  🟡 Waiting for review  ->  🔍 Investigating (by an admin)  ->  ✅ Done (checked by an admin,
-- with the result and the proof). Every change is written in the report's history with who did it.
-- Saved in:
--   SamarCollege_Reports_v1          DataStore         r_<id> = the report,  t_<UserId> = ids of reports about that player
--   SamarCollege_ReportsWaiting_v1   OrderedDataStore  <id> = time reported, while waiting for review
--   SamarCollege_ReportsChecking_v1  OrderedDataStore  <id> = time reported, while an admin is investigating
--   SamarCollege_ReportsDone_v1      OrderedDataStore  <id> = time reported, once checked
--   SamarCollege_ReportsAll_v1       OrderedDataStore  <id> = time reported, every report
-- Admins in every server get a notice when a report comes in or someone takes one (MessagingService "SC_Reports").
-- Text players and admins type is passed through the Roblox text filter before anyone sees it.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local ReportConfig = require(RS:WaitForChild("ReportConfig"))
local PlayerRecords = require(script.Parent:WaitForChild("PlayerRecords"))
local StudioStores = require(script.Parent:WaitForChild("StudioStores"))

local PlayerReports = {}

local IS_STUDIO = RunService:IsStudio()
local TOPIC = "SC_Reports"
local PAGE = 15
local STATUS = { open = true, investigating = true, done = true }
local REASONS, OUTCOMES = {}, {}
for _, r in ipairs(ReportConfig.Reasons) do REASONS[r.Id] = r end
for _, o in ipairs(ReportConfig.Outcomes) do OUTCOMES[o] = true end

---------------------------------------------------------------- stores
local store, index, fake = nil, {}, false
do
	local liveDS = PlayerRecords.isLive()
	local ok = liveDS and pcall(function()
		store = DataStoreService:GetDataStore("SamarCollege_Reports_v1")
		index.open = DataStoreService:GetOrderedDataStore("SamarCollege_ReportsWaiting_v1")
		index.investigating = DataStoreService:GetOrderedDataStore("SamarCollege_ReportsChecking_v1")
		index.done = DataStoreService:GetOrderedDataStore("SamarCollege_ReportsDone_v1")
		index.all = DataStoreService:GetOrderedDataStore("SamarCollege_ReportsAll_v1")
	end)
	if not ok then
		fake = true
		store = StudioStores.dataStore()
		for _, k in ipairs({ "open", "investigating", "done", "all" }) do index[k] = StudioStores.dataStore() end
	end
end

local bodyCache = {}  -- [id] = { t = clock, r = report }
local countsCache

---------------------------------------------------------------- notices to admins (all servers)
local noticeEvent = Instance.new("BindableEvent")
PlayerReports.Notice = noticeEvent.Event
local seen = {}
local function announce(msg)
	if type(msg) ~= "table" or type(msg.k) ~= "string" or seen[msg.k] then return end
	seen[msg.k] = os.clock()
	if msg.id then bodyCache[msg.id] = nil end
	countsCache = nil
	noticeEvent:Fire(msg)
end
task.spawn(function()
	pcall(function()
		MessagingService:SubscribeAsync(TOPIC, function(m) announce(m.Data) end)
	end)
end)
local function broadcast(msg)
	announce(msg)
	task.spawn(function() pcall(function() MessagingService:PublishAsync(TOPIC, msg) end) end)
end
task.spawn(function()
	while true do
		task.wait(300)
		for k, t in pairs(seen) do if os.clock() - t > 600 then seen[k] = nil end end
	end
end)

---------------------------------------------------------------- text
local function clean(text, max)
	if type(text) ~= "string" then return "" end
	text = text:gsub("%c", " "):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
	if not utf8.len(text) then text = text:gsub("[\128-\255]", "") end
	if utf8.len(text) > max then text = text:sub(1, utf8.offset(text, max + 1) - 1) end
	return text
end

-- what everyone may see of text a player typed
local function filterText(text, fromUserId)
	if text == "" then return "" end
	local ok, res = pcall(function()
		local r = TextService:FilterStringAsync(text, fromUserId, Enum.TextFilterContext.PublicChat)
		return r:GetNonChatStringForBroadcastAsync()
	end)
	if ok and type(res) == "string" then return res end
	if IS_STUDIO then return text end
	return "[text hidden: the Roblox filter couldn't check it]"
end

---------------------------------------------------------------- reading
local function getReport(id, fresh)
	local c = bodyCache[id]
	if not fresh and c and os.clock() - c.t < 20 then return c.r end
	local ok, r = pcall(function() return store:GetAsync("r_" .. id) end)
	if not ok then return nil end
	bodyCache[id] = { t = os.clock(), r = r }
	return r
end

-- a copy of the report with where the reported player is right now
local function decorate(r)
	local out = table.clone(r)
	local pr = r.who and PlayerRecords.presence(r.who.u)
	out.on = pr ~= nil
	out.osc = pr and pr.sc
	out.ojob = pr and pr.job
	out.here = pr ~= nil and pr.job == PlayerRecords.JOB
	return out
end

-- how many reports wait for review / are being investigated
function PlayerReports.counts()
	if countsCache and os.clock() - countsCache.t < 15 then return countsCache.c end
	local c = {}
	for _, k in ipairs({ "open", "investigating" }) do
		local ok, pages = pcall(function() return index[k]:GetSortedAsync(false, 100) end)
		if ok then c[k] = #pages:GetCurrentPage() end
	end
	countsCache = { t = os.clock(), c = c }
	return c
end

-- number of reports about one player
local targetCache = {}
function PlayerReports.countFor(userId)
	local c = targetCache[userId]
	if c and os.clock() - c.t < 30 then return c.n end
	local ok, list = pcall(function() return store:GetAsync("t_" .. userId) end)
	local n = (ok and type(list) == "table") and #list or 0
	targetCache[userId] = { t = os.clock(), n = n }
	return n
end

-- a page of reports: filter = "open" | "investigating" | "done" | "all", or every report about one player (target)
local states = {}
function PlayerReports.list(callerId, filter, more, target)
	filter = (filter == "investigating" or filter == "done" or filter == "all") and filter or "open"
	target = tonumber(target)
	local st = states[callerId]
	if more and st and st.filter == filter and st.target == target and not st.finished then
		if not target then
			local ok, err = pcall(function() st.pages:AdvanceToNextPageAsync() end)
			if not ok then return { ok = false, msg = "Couldn't load more: " .. tostring(err) } end
		end
	else
		st = { filter = filter, target = target }
		states[callerId] = st
		if target then
			local ok, list = pcall(function() return store:GetAsync("t_" .. target) end)
			if not ok then return { ok = false, msg = "Couldn't read reports: " .. tostring(list) } end
			st.ids = type(list) == "table" and list or {}
			st.pos = 0
		else
			local ok, pages = pcall(function() return index[filter]:GetSortedAsync(false, PAGE) end)
			if not ok then return { ok = false, msg = "Couldn't read reports: " .. tostring(pages) } end
			st.pages = pages
		end
	end
	local ids = {}
	if target then
		for i = st.pos + 1, math.min(#st.ids, st.pos + PAGE) do table.insert(ids, st.ids[i]) end
		st.pos += #ids
		st.finished = st.pos >= #st.ids
	else
		for _, e in ipairs(st.pages:GetCurrentPage()) do table.insert(ids, e.key) end
		st.finished = st.pages.IsFinished
	end
	-- read the reports at the same time
	local got, left = {}, #ids
	for i, id in ipairs(ids) do
		task.spawn(function()
			local r = getReport(id)
			if type(r) == "table" and not target and filter ~= "all" and r.status ~= filter then r = getReport(id, true) end
			got[i] = r
			left -= 1
		end)
	end
	local t0 = os.clock()
	while left > 0 and os.clock() - t0 < 15 do task.wait() end
	local items = {}
	for i, id in ipairs(ids) do
		local r = got[i]
		if type(r) == "table" then
			if target or filter == "all" or r.status == filter then
				table.insert(items, decorate(r))
			else
				-- the list was out of date (the report moved on): fix it
				task.spawn(function() pcall(function() index[filter]:RemoveAsync(id) end) end)
			end
		end
	end
	return { ok = true, items = items, more = not st.finished, filter = filter, target = target,
		counts = PlayerReports.counts(), live = not fake }
end

---------------------------------------------------------------- a player sends a report
local lastBy, lastPair, dayCount = {}, {}, {}
function PlayerReports.submit(player, targetId, reasonId, details)
	targetId = tonumber(targetId)
	local target = targetId and Players:GetPlayerByUserId(targetId)
	if not target then return { ok = false, msg = "That player isn't in this server anymore" } end
	if target == player then return { ok = false, msg = "You can't report yourself" } end
	local reason = type(reasonId) == "string" and REASONS[reasonId]
	if not reason then return { ok = false, msg = "Pick what they did" } end
	local uid, now = player.UserId, os.time()
	if lastBy[uid] and now - lastBy[uid] < ReportConfig.Cooldown then
		return { ok = false, msg = "Please wait " .. (ReportConfig.Cooldown - (now - lastBy[uid])) .. " seconds before sending another report" }
	end
	local pairKey = uid .. ">" .. targetId
	if lastPair[pairKey] and now - lastPair[pairKey] < ReportConfig.SameTargetCooldown then
		return { ok = false, msg = "You already reported " .. target.DisplayName .. ". The admins will check it." }
	end
	local dayKey = uid .. "_" .. (now // 86400)
	if (dayCount[dayKey] or 0) >= ReportConfig.DailyMax then
		return { ok = false, msg = "You sent a lot of reports today. Please try again tomorrow." }
	end
	lastBy[uid], lastPair[pairKey] = now, now
	dayCount[dayKey] = (dayCount[dayKey] or 0) + 1

	local text = filterText(clean(details, ReportConfig.MaxDetails), uid)
	local ok = PlayerReports.create({ u = uid, n = player.Name, d = player.DisplayName },
		{ u = targetId, n = target.Name, d = target.DisplayName }, reason.Id, text)
	if not ok then
		lastBy[uid], lastPair[pairKey] = nil, nil
		dayCount[dayKey] -= 1
		return { ok = false, msg = "Couldn't send the report. Please try again in a moment." }
	end
	return { ok = true, msg = "Thanks! Your report about " .. target.DisplayName .. " was sent to the admins." }
end

-- saves a checked report (by / who = { u = UserId, n = username, d = display name }, text already filtered)
function PlayerReports.create(by, who, reasonId, text)
	local reason = REASONS[reasonId] or REASONS.Other
	local now = os.time()
	local id = string.format("%d_%d", now, by.u)
	local rep = {
		id = id, t = now, reason = reason.Id, reasonName = reason.Name, details = text or "", status = "open",
		by = by, who = who,
		srv = { job = PlayerRecords.JOB, sc = PlayerRecords.SERVER_CODE, pl = game.PlaceId },
		log = { { t = now, a = "reported", n = by.n } },
	}
	local ok = pcall(function() store:SetAsync("r_" .. id, rep) end)
	if not ok then return false end
	pcall(function() index.open:SetAsync(id, now) end)
	pcall(function() index.all:SetAsync(id, now) end)
	pcall(function()
		store:UpdateAsync("t_" .. who.u, function(list)
			list = type(list) == "table" and list or {}
			table.insert(list, 1, id)
			while #list > 100 do table.remove(list) end
			return list
		end)
	end)
	targetCache[who.u] = nil
	broadcast({ k = id .. ":new", kind = "new", id = id, by = by.d, byn = by.n, who = who.d, whon = who.n,
		reason = reason.Name, sc = PlayerRecords.SERVER_CODE })
	return true, id
end

---------------------------------------------------------------- an admin changes the status
function PlayerReports.setStatus(caller, role, id, status, outcome, note)
	if type(id) ~= "string" or not id:match("^%d+_%d+$") then return { ok = false, msg = "Unknown report" } end
	if not STATUS[status] then return { ok = false, msg = "Unknown status" } end
	if status == "done" and not OUTCOMES[outcome] then return { ok = false, msg = "Pick the result first" } end
	local proof = status == "done" and filterText(clean(note, ReportConfig.MaxNote), caller.UserId) or nil
	local now = os.time()
	local old, rec
	local ok, err = pcall(function()
		store:UpdateAsync("r_" .. id, function(r)
			if type(r) ~= "table" then return nil end
			old = r.status
			local who = { u = caller.UserId, n = caller.Name, r = role, t = now }
			if status == "investigating" then
				r.inv, r.done = who, nil
			elseif status == "done" then
				r.inv = r.inv or who
				r.done = { u = caller.UserId, n = caller.Name, r = role, t = now, o = outcome, note = proof }
			else
				r.inv, r.done = nil, nil
			end
			r.status = status
			r.log = type(r.log) == "table" and r.log or {}
			table.insert(r.log, { t = now, a = status, n = caller.Name, r = role, o = status == "done" and outcome or nil })
			while #r.log > 20 do table.remove(r.log, 2) end -- keeps the first line (who reported it)
			rec = r
			return r
		end)
	end)
	if not ok then return { ok = false, msg = "Couldn't save: " .. tostring(err) } end
	if not rec then return { ok = false, msg = "That report doesn't exist anymore" } end
	if old ~= status then
		if index[old] then pcall(function() index[old]:RemoveAsync(id) end) end
		pcall(function() index[status]:SetAsync(id, rec.t) end)
	end
	bodyCache[id] = { t = os.clock(), r = rec }
	countsCache = nil
	broadcast({ k = id .. ":" .. status .. ":" .. now .. ":" .. caller.UserId, kind = status, id = id, admin = caller.Name,
		role = role, who = rec.who and rec.who.d, whon = rec.who and rec.who.n, o = outcome })
	local whoName = rec.who and rec.who.d or "this player"
	local msg = status == "investigating" and ("You are investigating the report about " .. whoName)
		or status == "done" and ("Report about " .. whoName .. " marked as done (" .. outcome .. ")")
		or ("Report about " .. whoName .. " is waiting for review again")
	return { ok = true, msg = msg, report = decorate(rec), counts = PlayerReports.counts() }
end

return PlayerReports
