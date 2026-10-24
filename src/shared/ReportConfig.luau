-- ReportConfig: what players can report someone for, and the results admins can give a report.
return {
	Reasons = {
		{ Id = "Bullying", Name = "Bullying or harassment" },
		{ Id = "Language", Name = "Bad language / swearing" },
		{ Id = "Cheating", Name = "Cheating / exploiting" },
		{ Id = "Scam", Name = "Scamming or stealing" },
		{ Id = "Inappropriate", Name = "Inappropriate avatar or behavior" },
		{ Id = "PersonalInfo", Name = "Asking for or sharing personal info" },
		{ Id = "Dating", Name = "Dating / romance roleplay" },
		{ Id = "Spam", Name = "Spamming or trolling" },
		{ Id = "Other", Name = "Other rule broken" },
	},
	-- results an admin picks when a report is done
	Outcomes = { "Warned", "Kicked", "Banned", "No rule broken", "Other" },

	MaxDetails = 200,          -- characters a player can write
	MaxNote = 300,             -- characters an admin can write as proof / notes
	Cooldown = 60,             -- seconds between two reports from the same player
	SameTargetCooldown = 600,  -- seconds before someone can report the same person again
	DailyMax = 15,             -- reports one player can send per day (in one server)
}
