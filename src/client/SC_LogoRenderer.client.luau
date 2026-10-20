-- Paints the official Samar College logo onto the gate seal using an EditableImage.
-- If EditableImage is unavailable, the hand-drawn seal underneath stays visible.
local RS = game:GetService("ReplicatedStorage")
local AssetService = game:GetService("AssetService")

local seal = workspace:WaitForChild("SamarCollege_Campus"):WaitForChild("GateFacade"):WaitForChild("Logo"):WaitForChild("SealFace")
local gui = seal:WaitForChild("Seal")

local ok, err = pcall(function()
	local logo = require(RS:WaitForChild("SC_LogoData"))
	local px, S = require(RS:WaitForChild("SC_LogoDecoder"))(logo)
	local img = AssetService:CreateEditableImage({ Size = Vector2.new(S, S) })
	img:WritePixelsBuffer(Vector2.zero, Vector2.new(S, S), px)
	local label = Instance.new("ImageLabel")
	label.Name = "OfficialLogo"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.ZIndex = 100
	label.ImageContent = Content.fromObject(img)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = label
	label.Parent = gui
	-- hide the hand-drawn version underneath
	for _, c in ipairs(gui:GetChildren()) do
		if c ~= label and c:IsA("GuiObject") then c.Visible = false end
	end
end)
if not ok then warn("[SC_LogoRenderer] could not draw official logo: " .. tostring(err)) end
