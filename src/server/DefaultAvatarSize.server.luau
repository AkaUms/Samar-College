-- DefaultAvatarSize.lua
-- Gives every player the same body size while keeping their own avatar look:
-- layered (3D) clothing, classic shirts/pants, hair, accessories, face and skin.
-- When a player's avatar finishes loading, only the scale values below are changed;
-- layered clothing re-wraps itself to the new body size automatically.
--
-- Change the numbers below to adjust the size for everyone.

local Players = game:GetService("Players")

local SCALES = {
	HeightScale = 1,     -- 1 = Roblox default height
	WidthScale = 1,      -- 1 = default width
	DepthScale = 1,      -- 1 = default depth
	HeadScale = 1,       -- 1 = default head size
	BodyTypeScale = 0,   -- 0 = classic body proportions
	ProportionScale = 0, -- 0 = standard (not slender)
}

local function applyDefaultSize(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local ok, desc = pcall(function() return humanoid:GetAppliedDescription() end)
	if ok and desc then
		local changed = false
		for property, value in pairs(SCALES) do
			if math.abs(desc[property] - value) > 0.001 then
				desc[property] = value
				changed = true
			end
		end
		if changed then
			local applied, err = pcall(function() humanoid:ApplyDescription(desc) end)
			if not applied then
				warn("[DefaultAvatarSize] Couldn't resize " .. character.Name .. ": " .. tostring(err))
			end
		end
	end

	-- Lets other scripts (shop cosmetics) know the body has its final size
	character:SetAttribute("AvatarSized", true)
end

local function onPlayerAdded(player)
	player.CharacterAppearanceLoaded:Connect(applyDefaultSize)
	if player.Character and player:HasAppearanceLoaded() then
		task.spawn(applyDefaultSize, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end
