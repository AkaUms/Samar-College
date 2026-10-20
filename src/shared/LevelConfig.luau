-- LevelConfig: school levels used for Titles, Profile and unlocking.
-- RequiredMinutes = total minutes a player must have played before they can take the quiz that unlocks that level.
local LevelConfig = {}

LevelConfig.Departments = {
	{ Name = "Elementary Department", Short = "Elementary", Color = Color3.fromRGB(64, 170, 110) },
	{ Name = "High School Department", Short = "High School", Color = Color3.fromRGB(70, 140, 230) },
	{ Name = "College / Tertiary Department", Short = "College", Color = Color3.fromRGB(230, 170, 50) },
}

LevelConfig.Levels = {
	{ Name = "Kindergarten", Dept = 1, RequiredMinutes = 0 },
	{ Name = "Grade 1",  Dept = 1, RequiredMinutes = 5 },
	{ Name = "Grade 2",  Dept = 1, RequiredMinutes = 10 },
	{ Name = "Grade 3",  Dept = 1, RequiredMinutes = 15 },
	{ Name = "Grade 4",  Dept = 1, RequiredMinutes = 20 },
	{ Name = "Grade 5",  Dept = 1, RequiredMinutes = 25 },
	{ Name = "Grade 6",  Dept = 1, RequiredMinutes = 30 },
	{ Name = "Grade 7",  Dept = 2, RequiredMinutes = 40 },
	{ Name = "Grade 8",  Dept = 2, RequiredMinutes = 50 },
	{ Name = "Grade 9",  Dept = 2, RequiredMinutes = 60 },
	{ Name = "Grade 10", Dept = 2, RequiredMinutes = 70 },
	{ Name = "Grade 11", Dept = 2, RequiredMinutes = 80 },
	{ Name = "Grade 12", Dept = 2, RequiredMinutes = 90 },
	{ Name = "1st Year", Dept = 3, RequiredMinutes = 105 },
	{ Name = "2nd Year", Dept = 3, RequiredMinutes = 120 },
	{ Name = "3rd Year", Dept = 3, RequiredMinutes = 135 },
	{ Name = "4th Year", Dept = 3, RequiredMinutes = 150 },
}

LevelConfig.QuestionsPerQuiz = 5
LevelConfig.PassScore = 4          -- correct answers needed (out of QuestionsPerQuiz)
LevelConfig.RetryCooldown = 30     -- seconds to wait after failing

function LevelConfig.find(name)
	for i, l in ipairs(LevelConfig.Levels) do if l.Name == name then return i end end
end
function LevelConfig.name(i) local l = LevelConfig.Levels[i] return l and l.Name or "?" end
function LevelConfig.dept(i) local l = LevelConfig.Levels[i] return l and LevelConfig.Departments[l.Dept] end

return LevelConfig
