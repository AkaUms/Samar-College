-- ReportServer: the "Report a player" window (ReportClient) sends reports through here.
-- Everything is checked in PlayerReports (player in this server, reason, cooldowns, text filter).
local RS = game:GetService("ReplicatedStorage")
local PlayerReports = require(script.Parent:WaitForChild("PlayerReports"))

local remotes = RS:FindFirstChild("ReportRemotes") or Instance.new("Folder")
remotes.Name = "ReportRemotes"
remotes.Parent = RS
local submit = remotes:FindFirstChild("SubmitReport") or Instance.new("RemoteFunction")
submit.Name = "SubmitReport"
submit.Parent = remotes

submit.OnServerInvoke = function(player, targetId, reasonId, details)
	local ok, res = pcall(PlayerReports.submit, player, targetId, reasonId, details)
	if not ok then
		warn("[ReportServer] " .. tostring(res))
		return { ok = false, msg = "Couldn't send the report. Please try again." }
	end
	return res
end
