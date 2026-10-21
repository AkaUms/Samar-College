-- LevelServer: school level (Title) progression.
-- New players start at Kindergarten. To unlock the next level a player must
--   1) spend the level's minutes AT their current level (LevelConfig.minutesFor) — this
--      "level timer" is separate from total play time and resets after each passed quiz
--      or when an admin promotes/demotes the player, and
--   2) pass the quiz of their current highest level (server-graded).
-- Players can switch freely between any level they already unlocked.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local LevelConfig = require(RS:WaitForChild("LevelConfig"))
local QuizBank = require(script.Parent:WaitForChild("QuizBank"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local remotes = RS:WaitForChild("ProfileRemotes")

local MAX = #LevelConfig.Levels
local active = {}     -- player -> { level=, answers={}, started= }
local cooldown = {}   -- player -> os.clock() when they may retry

local function setTitle(player)
	local ls = player:FindFirstChild("leaderstats")
	local t = ls and ls:FindFirstChild("Title")
	if t then t.Value = LevelConfig.name(player:GetAttribute("SelectedLevel") or 1) end
end

local function feedback(player, msg, good)
	remotes.LevelFeedback:FireClient(player, msg, good)
	local shop = RS:FindFirstChild("ShopRemotes")
	if shop and shop:FindFirstChild("UpdateCash") then shop.UpdateCash:FireClient(player, msg) end
end

local function onPlayer(player)
	player:WaitForChild("leaderstats", 30)
	local data = PlayerData.get(player) or {}
	local unlocked = math.clamp(tonumber(data.LevelUnlocked) or 1, 1, MAX)
	local selected = math.clamp(tonumber(data.SelectedLevel) or unlocked, 1, unlocked)
	player:SetAttribute("LevelUnlocked", unlocked)
	player:SetAttribute("SelectedLevel", selected)
	for _, stat in ipairs(PlayerData.STATS) do player:SetAttribute(stat, tonumber(data[stat]) or 0) end
	-- older saves had no level timer: carry over the time already earned toward the next quiz
	if data.LevelTime == nil then
		local spentBefore = (LevelConfig.Levels[unlocked] and LevelConfig.Levels[unlocked].RequiredMinutes or 0) * 60
		PlayerData.setLevelTime(player, math.max(0, PlayerData.getTime(player) - spentBefore))
	end
	setTitle(player)
	player:GetAttributeChangedSignal("SelectedLevel"):Connect(function() setTitle(player) end)
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(onPlayer, p) end
Players.PlayerRemoving:Connect(function(p) active[p] = nil cooldown[p] = nil end)

remotes.SelectLevel.OnServerEvent:Connect(function(player, idx)
	idx = tonumber(idx)
	if not idx then return end
	idx = math.floor(idx)
	if idx < 1 or idx > (player:GetAttribute("LevelUnlocked") or 1) then return end
	player:SetAttribute("SelectedLevel", idx)
	feedback(player, "Title changed to " .. LevelConfig.name(idx), true)
end)

local function shuffle(t) for i = #t, 2, -1 do local j = math.random(i) t[i], t[j] = t[j], t[i] end return t end

remotes.StartQuiz.OnServerInvoke = function(player)
	local current = player:GetAttribute("LevelUnlocked") or 1
	if current >= MAX then return { ok = false, msg = "You already reached the highest level! 🎓" } end
	local nextLevel = LevelConfig.Levels[current + 1]
	local playedMin = PlayerData.getLevelTime(player) / 60
	local needMin = LevelConfig.minutesFor(current + 1)
	if playedMin < needMin then
		return { ok = false, msg = string.format("Stay in the game %d more minute(s) to unlock the quiz.", math.ceil(needMin - playedMin)) }
	end
	if cooldown[player] and os.clock() < cooldown[player] then
		return { ok = false, msg = string.format("Review first! Try again in %d s.", math.ceil(cooldown[player] - os.clock())) }
	end
	local bank = QuizBank[LevelConfig.name(current)] or {}
	if #bank == 0 then return { ok = false, msg = "No questions yet for " .. LevelConfig.name(current) } end
	local picks = {}
	for i = 1, #bank do picks[i] = i end
	shuffle(picks)
	local n = math.min(LevelConfig.QuestionsPerQuiz, #bank)
	local questions, answers = {}, {}
	for i = 1, n do
		local q = bank[picks[i]]
		-- shuffle options and remember where the right one went
		local order = { 1, 2, 3, 4 }
		local opts = {}
		shuffle(order)
		for k = 1, #q.O do opts[k] = q.O[order[k]] if order[k] == q.A then answers[i] = k end end
		questions[i] = { Q = q.Q, O = opts }
	end
	active[player] = { level = current, answers = answers, started = os.clock() }
	return { ok = true, level = current, levelName = LevelConfig.name(current), nextName = nextLevel.Name,
		questions = questions, pass = math.min(LevelConfig.PassScore, n) }
end

remotes.SubmitQuiz.OnServerInvoke = function(player, picked)
	local quiz = active[player]
	active[player] = nil
	if not quiz or type(picked) ~= "table" then return { ok = false } end
	if (player:GetAttribute("LevelUnlocked") or 1) ~= quiz.level then return { ok = false } end
	local score, total = 0, #quiz.answers
	local correct = {}
	for i, a in ipairs(quiz.answers) do
		correct[i] = a
		if tonumber(picked[i]) == a then score += 1 end
	end
	local need = math.min(LevelConfig.PassScore, total)
	local passed = score >= need
	if passed then
		local newLevel = quiz.level + 1
		player:SetAttribute("LevelUnlocked", newLevel)
		player:SetAttribute("SelectedLevel", newLevel)
		player:SetAttribute("QuizzesPassed", (player:GetAttribute("QuizzesPassed") or 0) + 1)
		PlayerData.resetLevelTime(player) -- the timer for the next quiz starts over
		feedback(player, "🎉 Congratulations! You are now " .. LevelConfig.name(newLevel) .. "!", true)
		task.spawn(PlayerData.save, player)
	else
		cooldown[player] = os.clock() + LevelConfig.RetryCooldown
	end
	return { ok = true, score = score, total = total, need = need, passed = passed, correct = correct,
		newName = passed and LevelConfig.name(quiz.level + 1) or nil }
end
