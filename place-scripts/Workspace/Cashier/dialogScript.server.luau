-- services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--modules
local DialogModule = require(ReplicatedStorage.DialogModule)

--references
local player = game.Players.LocalPlayer
local npc = script.Parent -- Reference to the NPC model
local npcGui = npc:WaitForChild("Head"):WaitForChild("gui")
local prompt = npc:WaitForChild("ProximityPrompt")

local dialogObject = DialogModule.new("Cashier", npc, prompt)
dialogObject:addDialog("Do you need something", {"Yes!", "..."})

--

-- what happens when triggered
prompt.Triggered:Connect(function(player)
	dialogObject:triggerDialog(player, 1)
end)

-- logic to go through dialogs
dialogObject.responded:Connect(function(responseNum, dialogNum)
	if dialogNum == 1 then
		if responseNum == 1 then
			dialogObject:hideGui("Take a look!")

			-- open the shop GUI
			local playerGui = player:FindFirstChild("PlayerGui")
			if playerGui then
				local shopGui = playerGui:FindFirstChild("ShopGui")
				if shopGui then
					shopGui.Enabled = true
				end
			end
		end
	end
end)
