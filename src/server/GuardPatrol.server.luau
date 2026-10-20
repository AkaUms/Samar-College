-- GuardPatrol.lua
-- Makes every NPC with a "PatrolRoute" attribute walk between the markers in
-- Workspace.PatrolRoutes.<RouteName> (parts named 1, 2, 3...).
-- Route folder attribute "Mode": "Loop" (1-2-3-4-1...) or "PingPong" (1-2-3-2-1...).
-- When a player opens the guard's ProximityPrompt, the guard stops and faces them.
-- Drag the markers in Studio to change where the guards walk.

local PathfindingService = game:GetService("PathfindingService")
local Workspace = game:GetService("Workspace")

local PATROL_SPEED = 8        -- walking pace (players walk at 16)
local WAIT_AT_POINT = 2       -- seconds to stand still at each marker
local TALK_PAUSE = 8          -- seconds to stop when a player talks to the guard
local WALK_ANIM = "rbxassetid://180426354" -- default R6 walk
local IDLE_ANIM = "rbxassetid://180435571" -- default R6 idle

local routesFolder = Workspace:WaitForChild("PatrolRoutes")

-- Guards walk through each other instead of blocking one another's routes
local PhysicsService = game:GetService("PhysicsService")
local GUARD_GROUP = "PatrolGuards"
pcall(function() PhysicsService:RegisterCollisionGroup(GUARD_GROUP) end)
PhysicsService:CollisionGroupSetCollidable(GUARD_GROUP, GUARD_GROUP, false)

-- Hide the markers while the game runs (they stay visible in Studio)
for _, marker in ipairs(routesFolder:GetDescendants()) do
	if marker:IsA("BasePart") then
		marker.Transparency = 1
	end
end

local function getWaypoints(routeName)
	local folder = routesFolder:FindFirstChild(routeName)
	if not folder then return nil end
	local points = {}
	for _, marker in ipairs(folder:GetChildren()) do
		local index = tonumber(marker.Name)
		if index and marker:IsA("BasePart") then
			table.insert(points, {index = index, position = marker.Position})
		end
	end
	table.sort(points, function(a, b) return a.index < b.index end)
	local positions = {}
	for _, p in ipairs(points) do table.insert(positions, p.position) end

	if folder:GetAttribute("Mode") == "PingPong" and #positions > 2 then
		for i = #positions - 1, 2, -1 do
			table.insert(positions, positions[i])
		end
	end
	return positions
end

local function setupAnimations(humanoid)
	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
	local walkAnim = Instance.new("Animation")
	walkAnim.AnimationId = WALK_ANIM
	local idleAnim = Instance.new("Animation")
	idleAnim.AnimationId = IDLE_ANIM

	local walkTrack = animator:LoadAnimation(walkAnim)
	walkTrack.Looped = true
	local idleTrack = animator:LoadAnimation(idleAnim)
	idleTrack.Looped = true
	idleTrack:Play()

	-- Switch to idle only after standing still briefly, so tiny pauses between
	-- path steps don't make the legs flicker.
	local stopToken = 0
	humanoid.Running:Connect(function(speed)
		if speed > 0.5 then
			stopToken += 1
			if not walkTrack.IsPlaying then
				idleTrack:Stop(0.2)
				walkTrack:Play(0.2)
			end
			walkTrack:AdjustSpeed(speed / 16 * 1.6)
		else
			stopToken += 1
			local token = stopToken
			task.delay(0.35, function()
				if token == stopToken and walkTrack.IsPlaying then
					walkTrack:Stop(0.25)
					idleTrack:Play(0.25)
				end
			end)
		end
	end)
end

local function flatDistance(a, b)
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

-- Walk to a point. Uses pathfinding around walls; falls back to a straight line.
local function walkTo(guard, humanoid, root, target)
	local path = PathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = false,
	})
	local ok = pcall(function()
		path:ComputeAsync(root.Position, target)
	end)

	local points
	if ok and path.Status == Enum.PathStatus.Success then
		points = {}
		for _, wp in ipairs(path:GetWaypoints()) do table.insert(points, wp.Position) end
	else
		points = {target}
	end

	for i, point in ipairs(points) do
		-- wait out any conversation before taking the next step
		while guard:GetAttribute("Talking") do task.wait(0.25) end
		if not guard.Parent or humanoid.Health <= 0 then return end

		-- Intermediate path steps are passed through without stopping;
		-- only the final step must be reached exactly.
		local isLast = (i == #points)
		local closeEnough = isLast and 1.5 or 3
		humanoid:MoveTo(point)

		local started = os.clock()
		local lastPos = root.Position
		local lastProgress = os.clock()
		while flatDistance(root.Position, point) > closeEnough do
			if guard:GetAttribute("Talking") then
				humanoid:MoveTo(root.Position) -- stop in place
				while guard:GetAttribute("Talking") do task.wait(0.25) end
				return -- re-path to the same target after talking
			end
			-- stuck against something: give up on this target
			if (root.Position - lastPos).Magnitude > 0.5 then
				lastPos = root.Position
				lastProgress = os.clock()
			elseif os.clock() - lastProgress > 2 then
				return false
			end
			if os.clock() - started > 8 then return false end
			humanoid:MoveTo(point) -- MoveTo times out after 8s, so keep it fresh
			task.wait(0.1)
		end
	end
	return true
end

local function startPatrol(guard)
	local humanoid = guard:FindFirstChildOfClass("Humanoid")
	local root = guard:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then return end

	local routeName = guard:GetAttribute("PatrolRoute")
	local waypoints = getWaypoints(routeName)
	if not waypoints or #waypoints < 2 then
		warn("[GuardPatrol] " .. guard:GetFullName() .. " has no usable route '" .. tostring(routeName) .. "'")
		return
	end

	for _, part in ipairs(guard:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CollisionGroup = GUARD_GROUP
		end
	end
	pcall(function() root:SetNetworkOwner(nil) end) -- server controls movement (no jitter)
	humanoid.WalkSpeed = PATROL_SPEED
	setupAnimations(humanoid)

	-- Freeze on the spot the moment a conversation starts
	guard:GetAttributeChangedSignal("Talking"):Connect(function()
		if guard:GetAttribute("Talking") then
			humanoid:MoveTo(root.Position)
		end
	end)

	-- Stop and face the player when they open the guard's prompt
	local prompt = guard:FindFirstChildWhichIsA("ProximityPrompt", true)
	if prompt then
		prompt.Triggered:Connect(function(player)
			guard:SetAttribute("Talking", true)
			humanoid:MoveTo(root.Position)
			local character = player.Character
			local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
			if playerRoot then
				local lookAt = Vector3.new(playerRoot.Position.X, root.Position.Y, playerRoot.Position.Z)
				if (lookAt - root.Position).Magnitude > 0.1 then
					root.CFrame = CFrame.lookAt(root.Position, lookAt)
				end
			end
			local stamp = os.clock()
			guard:SetAttribute("TalkStamp", stamp)
			task.delay(TALK_PAUSE, function()
				if guard:GetAttribute("TalkStamp") == stamp then
					guard:SetAttribute("Talking", nil)
				end
			end)
		end)
	end

	task.spawn(function()
		local index = 1
		local failures = 0
		while guard.Parent and humanoid.Health > 0 do
			local target = waypoints[index]
			walkTo(guard, humanoid, root, target)
			if flatDistance(root.Position, target) < 4 then
				failures = 0
				task.wait(WAIT_AT_POINT)
				index = index % #waypoints + 1
			else
				failures += 1
				if failures >= 3 then
					warn("[GuardPatrol] " .. guard.Name .. " can't reach marker " .. index .. " of " .. tostring(routeName) .. "; skipping it. Move that marker somewhere reachable.")
					failures = 0
					index = index % #waypoints + 1
				end
			end
			task.wait()
		end
	end)
end

for _, obj in ipairs(Workspace:GetChildren()) do
	if obj:IsA("Model") and obj:GetAttribute("PatrolRoute") then
		startPatrol(obj)
	end
end
