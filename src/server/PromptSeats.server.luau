-- Seats tagged "PromptSeat" only seat a player when they press the "Sit" prompt
-- (no accidental sitting when walking past in narrow rooms).
local CS = game:GetService("CollectionService")

local function setup(seat)
	if not seat:IsA("Seat") then return end
	seat.Disabled = true
	local prompt = seat:FindFirstChild("SitPrompt") or Instance.new("ProximityPrompt")
	prompt.Name = "SitPrompt"
	prompt.ActionText = "Sit"
	prompt.ObjectText = seat:GetAttribute("SeatName") or (seat.Parent and seat.Parent.Name) or "Seat"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 7
	prompt.RequiresLineOfSight = false
	prompt.Parent = seat

	prompt.Triggered:Connect(function(player)
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 or seat.Occupant then return end
		seat.Disabled = false
		seat:Sit(hum)
	end)

	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		if seat.Occupant then
			prompt.Enabled = false
		else
			seat.Disabled = true
			prompt.Enabled = true
		end
	end)
end

for _, s in ipairs(CS:GetTagged("PromptSeat")) do setup(s) end
CS:GetInstanceAddedSignal("PromptSeat"):Connect(setup)
