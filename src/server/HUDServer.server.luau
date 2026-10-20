-- HUDServer.lua
-- Handles Map teleports (only to places listed in HUDConfig) and the
-- Elementary / Junior High+ server switch from the Settings panel.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local config = require(ReplicatedStorage:WaitForChild("HUDConfig"))
local remotes = ReplicatedStorage:WaitForChild("HUDRemotes")
local mapTeleport = remotes:WaitForChild("MapTeleport")
local switchServer = remotes:WaitForChild("SwitchServer")

local placesById = {}
for _, place in ipairs(config.Places) do
	placesById[place.Id] = place
end

local lastTeleport = {}

mapTeleport.OnServerEvent:Connect(function(player, placeId)
	if typeof(placeId) ~= "string" then return end
	local place = placesById[placeId]
	if not place then return end

	local now = os.clock()
	if lastTeleport[player] and now - lastTeleport[player] < (config.TeleportCooldown or 3) then
		mapTeleport:FireClient(player, "Wait a moment before teleporting again")
		return
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	lastTeleport[player] = now
	humanoid.Sit = false
	character:PivotTo(CFrame.new(place.Position + Vector3.new(0, 0.5, 0)))
	mapTeleport:FireClient(player, "Teleported to " .. place.Name)
end)

switchServer.OnServerEvent:Connect(function(player, target)
	if target ~= "Elementary" then return end
	local placeId = tonumber(config.ElementaryPlaceId) or 0
	if placeId <= 0 then
		switchServer:FireClient(player, "The Elementary server isn't set up yet")
		return
	end
	switchServer:FireClient(player, "Teleporting to the Elementary server...")
	local ok, err = pcall(function()
		TeleportService:TeleportAsync(placeId, { player })
	end)
	if not ok then
		warn("[HUDServer] Teleport failed: " .. tostring(err))
		switchServer:FireClient(player, "Couldn't switch servers. Try again.")
	end
end)

Players.PlayerRemoving:Connect(function(player)
	lastTeleport[player] = nil
end)
