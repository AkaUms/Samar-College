-- PromptGuard: E-prompts (sit, lights, doors, gates, windows, whiteboards, NPCs ...) only work
-- when you can really reach them.
--   * A wall, door, window, pillar, floor or ceiling between you and the prompt hides it, so you
--     cannot sit, switch lights or open things on the other side of a wall.
--     Furniture (tables, chairs, desks, benches, small props) does not block.
--   * You must also be able to walk to it: you cannot reach through a window, grille or low wall.
--   * A prompt with a Vector3 attribute "UseSide" only works from that side
--     (windows and curtains: from inside the room only).
-- It hides a blocked prompt on this player's screen by setting its MaxActivationDistance to 0,
-- and gives the normal range back as soon as the path is clear.
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local TICK = 0.1
local HEAD_UP = 1.5
local KNEE_DOWN = 1.4 -- root part is ~3 studs above the floor, so this is ~1.6 above the floor

local tracked = {}        -- prompt -> { orig, written, owner }
local blockerCache = setmetatable({}, { __mode = "k" })

-- size of a part in world axes (works for rotated parts too)
local function extents(p)
	local cf, s = p.CFrame, p.Size
	local r, u, b = cf.RightVector, cf.UpVector, cf.LookVector
	local ex = math.abs(r.X) * s.X + math.abs(u.X) * s.Y + math.abs(b.X) * s.Z
	local ey = math.abs(r.Y) * s.X + math.abs(u.Y) * s.Y + math.abs(b.Y) * s.Z
	local ez = math.abs(r.Z) * s.X + math.abs(u.Z) * s.Y + math.abs(b.Z) * s.Z
	return ex, ey, ez
end

-- walls, doors, pillars, windows, cabinets, floors and ceilings block; furniture does not
local function isBlocker(p)
	local cached = blockerCache[p]
	if cached ~= nil then return cached end
	local result = false
	if p:IsA("BasePart") then
		local ex, ey, ez = extents(p)
		local h = math.max(ex, ez)
		if p.CanCollide then
			if ey >= 2.5 and h >= 1.2 and (h >= 3 or ey >= 5) then
				result = true -- wall, door, pillar, cabinet, grille / rail collider (chairs are smaller)
			elseif ey >= 0.8 and math.min(ex, ez) >= 6 then
				result = true -- thick and large: floor slab / ceiling (tables are smaller)
			elseif p.Transparency >= 0.2 and p.Transparency < 1 and ey >= 0.25 and h >= 1.5 then
				result = true -- window panes and jalousie louvres
			end
		end
		if p.Material == Enum.Material.Glass and ey >= 0.25 and h >= 1.0 then
			result = true -- window glass, even when it is not collidable (glass table tops are flat)
		end
	end
	blockerCache[p] = result
	return result
end

local function anchorOf(prompt)
	local p = prompt.Parent
	if not p then return nil end
	if p:IsA("BasePart") then return p.Position end
	if p:IsA("Attachment") then return p.WorldPosition end
	if p:IsA("Model") then return p:GetPivot().Position end
	return nil
end

-- the thing the prompt belongs to never blocks its own prompt
-- (only its small parts: a big wall piece inside the same model still blocks)
local OWNER_PART_MAX = 9
local function small(p)
	local s = p.Size
	return math.max(s.X, s.Y, s.Z) <= OWNER_PART_MAX
end
local function addSmallParts(list, inst)
	for _, d in ipairs(inst:GetDescendants()) do
		if d:IsA("BasePart") and small(d) then table.insert(list, d) end
	end
end
local function ownerOf(prompt)
	local list = {}
	local par = prompt.Parent
	if not par then return list end
	if par:IsA("Model") then
		addSmallParts(list, par) -- e.g. an NPC
		return list
	end
	local part = par:IsA("Attachment") and par.Parent or par
	if part and part:IsA("BasePart") then
		table.insert(list, part)
		-- parts welded straight to it (door leaf, hinge), but never a wall it happens to be joined to
		local ok, conn = pcall(function() return part:GetConnectedParts(false) end)
		if ok then
			for _, c in ipairs(conn) do
				if small(c) then table.insert(list, c) end
			end
		end
		local m = part:FindFirstAncestorWhichIsA("Model")
		if m and m ~= workspace then
			local _, size = m:GetBoundingBox()
			if size.Magnitude <= 25 then addSmallParts(list, m) end
		end
	end
	return list
end

local function clearPath(from, to, exclude)
	local dir = to - from
	local dist = dir.Magnitude
	if dist < 0.6 then return true end
	dir = dir.Unit
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = exclude
	params.IgnoreWater = true
	local origin = from
	local remaining = dist - 0.3
	for _ = 1, 12 do
		if remaining <= 0 then return true end
		local hit = workspace:Raycast(origin, dir * remaining, params)
		if not hit then return true end
		if isBlocker(hit.Instance) then return false end
		params:AddToFilter(hit.Instance)
		remaining -= (hit.Position - origin).Magnitude
		origin = hit.Position
	end
	return true
end

local function write(prompt, st, value)
	if prompt.MaxActivationDistance ~= value then
		st.written = value
		prompt.MaxActivationDistance = value
	end
end

local function track(prompt)
	if tracked[prompt] or not prompt:IsA("ProximityPrompt") then return end
	local st = { orig = prompt.MaxActivationDistance, written = nil, owner = nil }
	tracked[prompt] = st
	prompt.RequiresLineOfSight = false -- our own check replaces the camera-based one
	prompt:GetPropertyChangedSignal("MaxActivationDistance"):Connect(function()
		-- a change we did not make came from the server: that is the new normal range
		if prompt.MaxActivationDistance ~= st.written and prompt.MaxActivationDistance > 0 then
			st.orig = prompt.MaxActivationDistance
		end
	end)
	prompt.AncestryChanged:Connect(function()
		if not prompt:IsDescendantOf(workspace) then tracked[prompt] = nil end
	end)
	write(prompt, st, 0) -- hidden until the first check says it is reachable
end

for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("ProximityPrompt") then track(d) end
end
workspace.DescendantAdded:Connect(function(d)
	if d:IsA("ProximityPrompt") then task.defer(track, d) end
end)

while true do
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp then
		local pos = hrp.Position
		local head = pos + Vector3.new(0, HEAD_UP, 0)
		for prompt, st in pairs(tracked) do
			local a = anchorOf(prompt)
			if a then
				local d = (a - pos).Magnitude
				if d <= st.orig + 2 then
					local ok = true
					local side = prompt:GetAttribute("UseSide")
					if typeof(side) == "Vector3" and side.Magnitude > 0 then
						ok = (pos - a):Dot(side.Unit) > 0.2
					end
					if ok then
						if not st.owner then st.owner = ownerOf(prompt) end
						local exclude = { char }
						for _, o in ipairs(st.owner) do table.insert(exclude, o) end
						ok = clearPath(head, a, exclude) or clearPath(pos, a, exclude)
						if ok then
							-- you must also be able to walk there: a level path at knee height may not
							-- cross a wall (stops reaching through windows, grilles and low walls)
							local knee = pos - Vector3.new(0, KNEE_DOWN, 0)
							local flat = Vector3.new(a.X, knee.Y, a.Z)
							local off = flat - knee
							if off.Magnitude > 0.9 then
								ok = clearPath(knee, flat - off.Unit * 0.3, exclude)
							end
						end
					end
					write(prompt, st, ok and st.orig or 0)
				elseif st.written ~= 0 then
					write(prompt, st, 0)
				end
			end
		end
	end
	task.wait(TICK)
end
