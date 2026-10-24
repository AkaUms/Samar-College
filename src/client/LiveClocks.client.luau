-- LiveClocks: wall clocks show the real time (Philippine Time, UTC+8).
-- A clock is anything tagged "LiveClock" with GUI frames named HourHand, MinuteHand and
-- (optional) SecondHand, anchored at the centre of the face (AnchorPoint 0.5, 1; Rotation 0 = 12 o'clock).
-- Attribute "UtcOffset" (hours) changes the time zone of one clock.
local CS = game:GetService("CollectionService")

local clocks = {} -- clock -> { hour = {}, minute = {}, second = {} }

local function add(clock)
	local hands = { hour = {}, minute = {}, second = {} }
	for _, d in ipairs(clock:GetDescendants()) do
		if d:IsA("GuiObject") then
			if d.Name == "HourHand" then table.insert(hands.hour, d)
			elseif d.Name == "MinuteHand" then table.insert(hands.minute, d)
			elseif d.Name == "SecondHand" then table.insert(hands.second, d) end
		end
	end
	clocks[clock] = hands
end

local function remove(clock)
	clocks[clock] = nil
end

for _, c in ipairs(CS:GetTagged("LiveClock")) do add(c) end
CS:GetInstanceAddedSignal("LiveClock"):Connect(add)
CS:GetInstanceRemovedSignal("LiveClock"):Connect(remove)

while true do
	local now = DateTime.now().UnixTimestampMillis / 1000
	for clock, hands in pairs(clocks) do
		-- a clock that streamed in before its hands: look for them again
		if #hands.hour == 0 and #hands.minute == 0 then add(clock) hands = clocks[clock] end
		local t = now + (clock:GetAttribute("UtcOffset") or 8) * 3600
		local sec = t % 60
		local min = (t / 60) % 60
		local hour = (t / 3600) % 12
		for _, h in ipairs(hands.hour) do h.Rotation = hour * 30 end
		for _, h in ipairs(hands.minute) do h.Rotation = min * 6 end
		for _, h in ipairs(hands.second) do h.Rotation = math.floor(sec) * 6 end
	end
	task.wait(1)
end
