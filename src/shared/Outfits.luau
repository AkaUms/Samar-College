-- Outfits.lua
-- Builds clothing out of coloured body parts + small welded parts, so it works on
-- R6 and R15 characters without needing uploaded shirt/pants images.
-- Used to dress the NPCs (Guard, Teacher, Cashier) and for shop cosmetics on players.
--
--   Outfits.wear(character, "Guard")      -- put on an outfit or cosmetic
--   Outfits.remove(character, "Guard")    -- take it off again (restores original look)
--   Outfits.removeAll(character)

local Outfits = {}

local EMERALD = Color3.fromRGB(0, 135, 85)      -- Samar College emerald green
local EMERALD_DARK = Color3.fromRGB(0, 95, 60)
local GOLD = Color3.fromRGB(220, 180, 60)
local WHITE = Color3.fromRGB(245, 245, 245)
local NAVY = Color3.fromRGB(30, 42, 78)
local NAVY_DARK = Color3.fromRGB(22, 26, 40)
local BLACK = Color3.fromRGB(25, 25, 28)
local CHARCOAL = Color3.fromRGB(45, 45, 52)

------------------------------------------------------------------ helpers

local function isR15(character)
	return character:FindFirstChild("UpperTorso") ~= nil
end

-- Named regions so outfits don't care about the rig type
local R6_PARTS = {
	head = {"Head"},
	chest = {"Torso"},
	waist = {},
	upperArms = {"Left Arm", "Right Arm"},
	lowerArms = {},
	hands = {},
	upperLegs = {"Left Leg", "Right Leg"},
	lowerLegs = {},
	feet = {},
}
local R15_PARTS = {
	head = {"Head"},
	chest = {"UpperTorso"},
	waist = {"LowerTorso"},
	upperArms = {"LeftUpperArm", "RightUpperArm"},
	lowerArms = {"LeftLowerArm", "RightLowerArm"},
	hands = {"LeftHand", "RightHand"},
	upperLegs = {"LeftUpperLeg", "RightUpperLeg"},
	lowerLegs = {"LeftLowerLeg", "RightLowerLeg"},
	feet = {"LeftFoot", "RightFoot"},
}

local function regionParts(character, region)
	local names = (isR15(character) and R15_PARTS or R6_PARTS)[region] or {}
	local parts = {}
	for _, n in ipairs(names) do
		local p = character:FindFirstChild(n)
		if p and p:IsA("BasePart") then table.insert(parts, p) end
	end
	return parts
end

local function torso(character)
	return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
end

-- Where things sit, relative to the torso / head, for each rig
local function chestCF(character)
	local t = torso(character)
	if not t then return nil end
	return isR15(character) and t.CFrame * CFrame.new(0, 0.1, 0) or t.CFrame * CFrame.new(0, 0.35, 0)
end

local function waistCF(character)
	if isR15(character) then
		local lt = character:FindFirstChild("LowerTorso")
		return lt and lt.CFrame
	end
	local t = character:FindFirstChild("Torso")
	return t and t.CFrame * CFrame.new(0, -0.75, 0)
end

-- Distance from the torso centre to its front surface (custom bodies are thicker)
local function frontZ(character, extra)
	local t = torso(character)
	local depth = t and t.Size.Z or 1
	return -(depth / 2) - (extra or 0.03)
end

local function torsoDepth(character)
	local t = torso(character)
	return t and t.Size.Z or 1
end

local function getFolder(character, outfitName)
	local folder = character:FindFirstChild("Outfit_" .. outfitName)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Outfit_" .. outfitName
		folder.Parent = character
	end
	return folder
end

-- Add a small welded decoration part
local function addPart(folder, attachTo, cf, props)
	local p = Instance.new("Part")
	p.Name = props.Name or "Piece"
	p.Shape = props.Shape or Enum.PartType.Block
	p.Size = props.Size
	p.Color = props.Color or WHITE
	p.Material = props.Material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.Anchored = false
	p.CastShadow = false
	p.CFrame = cf
	local w = Instance.new("WeldConstraint")
	w.Part0 = attachTo
	w.Part1 = p
	w.Parent = p
	p.Parent = folder
	return p
end

local function addLabel(part, face, text, textColor, bgColor)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 80
	gui.LightInfluence = 1
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = bgColor and 0 or 1
	label.BackgroundColor3 = bgColor or WHITE
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.TextColor3 = textColor
	label.Parent = gui
	gui.Parent = part
end

-- Attribute names can't contain spaces ("Left Arm"), so store them with underscores
local function origKey(partName)
	return "Orig_" .. string.gsub(partName, "%s", "_")
end

-- Recolour body regions, remembering the original colours so they can be restored
local function paint(character, folder, region, color)
	for _, part in ipairs(regionParts(character, region)) do
		local key = origKey(part.Name)
		if folder:GetAttribute(key) == nil then
			folder:SetAttribute(key, part.Color)
		end
		part.Color = color
	end
end

-- Hide the player's own Shirt / Pants / T-shirt while a full uniform is worn
local function stashClothing(character, folder)
	local stash = folder:FindFirstChild("StashedClothing") or Instance.new("Folder")
	stash.Name = "StashedClothing"
	stash.Parent = folder
	for _, c in ipairs(character:GetChildren()) do
		if c:IsA("Shirt") or c:IsA("Pants") or c:IsA("ShirtGraphic") then
			c.Parent = stash
		elseif c:IsA("Accessory") then
			local handle = c:FindFirstChild("Handle")
			if handle and handle:FindFirstChildOfClass("WrapLayer") then
				c.Parent = stash -- layered clothing would cover the uniform
			end
		end
	end
	local t = torso(character)
	local logo = t and t:FindFirstChild("roblox")
	if logo and logo:IsA("Decal") then
		folder:SetAttribute("LogoTransparency", logo.Transparency)
		logo.Transparency = 1
	end
end

local function idLanyard(folder, character, ribbonColor, cardText)
	local t = torso(character)
	local cf = chestCF(character)
	if not (t and cf) then return end
	-- two ribbon strips forming a V, plus the ID card
	addPart(folder, t, cf * CFrame.new(-0.28, 0.25, frontZ(character, 0.03)) * CFrame.Angles(0, 0, math.rad(-22)), {Name = "Lanyard", Size = Vector3.new(0.12, 0.9, 0.03), Color = ribbonColor})
	addPart(folder, t, cf * CFrame.new(0.28, 0.25, frontZ(character, 0.03)) * CFrame.Angles(0, 0, math.rad(22)), {Name = "Lanyard", Size = Vector3.new(0.12, 0.9, 0.03), Color = ribbonColor})
	local card = addPart(folder, t, cf * CFrame.new(0, -0.38, frontZ(character, 0.05)), {Name = "IDCard", Size = Vector3.new(0.45, 0.6, 0.04), Color = WHITE})
	addLabel(card, Enum.NormalId.Front, cardText, EMERALD_DARK)
end

local function cap(folder, character, color, brimColor, text, textColor)
	local head = character:FindFirstChild("Head")
	if not head then return end
	local crown = addPart(folder, head, head.CFrame * CFrame.new(0, 0.6, 0.02), {Name = "CapCrown", Size = Vector3.new(1.32, 0.42, 1.32), Color = color})
	addPart(folder, head, head.CFrame * CFrame.new(0, 0.42, -0.78), {Name = "CapBrim", Size = Vector3.new(1.0, 0.08, 0.55), Color = brimColor})
	if text then
		local front = addPart(folder, head, head.CFrame * CFrame.new(0, 0.6, -0.67), {Name = "CapBadge", Size = Vector3.new(0.9, 0.3, 0.02), Color = color})
		addLabel(front, Enum.NormalId.Front, text, textColor)
	end
	return crown
end

------------------------------------------------------------------ outfits

local BUILDERS = {}

-- Philippine school security guard: navy uniform, black cap, gold badge
BUILDERS.Guard = function(character, folder)
	stashClothing(character, folder)
	paint(character, folder, "chest", NAVY)
	paint(character, folder, "upperArms", NAVY)
	paint(character, folder, "lowerArms", NAVY)
	paint(character, folder, "waist", NAVY_DARK)
	paint(character, folder, "upperLegs", NAVY_DARK)
	paint(character, folder, "lowerLegs", NAVY_DARK)
	paint(character, folder, "feet", BLACK)
	local t = torso(character)
	local cf = chestCF(character)
	local w = waistCF(character)
	if t and cf then
		addPart(folder, t, cf * CFrame.new(0.45, 0.2, frontZ(character, 0.03)) * CFrame.Angles(0, math.rad(90), 0), {Name = "Badge", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.04, 0.38, 0.38), Color = GOLD, Material = Enum.Material.Metal})
		local tag = addPart(folder, t, cf * CFrame.new(-0.45, 0.2, frontZ(character, 0.03)), {Name = "NameTag", Size = Vector3.new(0.6, 0.18, 0.03), Color = BLACK})
		addLabel(tag, Enum.NormalId.Front, "SECURITY", WHITE)
		-- shoulder epaulettes
		addPart(folder, t, cf * CFrame.new(-0.85, 0.62, 0), {Name = "Epaulette", Size = Vector3.new(0.4, 0.06, 0.9), Color = BLACK})
		addPart(folder, t, cf * CFrame.new(0.85, 0.62, 0), {Name = "Epaulette", Size = Vector3.new(0.4, 0.06, 0.9), Color = BLACK})
	end
	if t and w then
		addPart(folder, t, w * CFrame.new(0, 0, 0), {Name = "Belt", Size = Vector3.new(2.04, 0.22, torsoDepth(character) + 0.04), Color = BLACK, Material = Enum.Material.Leather})
		addPart(folder, t, w * CFrame.new(0, 0, frontZ(character, 0.03)), {Name = "Buckle", Size = Vector3.new(0.3, 0.18, 0.04), Color = GOLD, Material = Enum.Material.Metal})
	end
	cap(folder, character, BLACK, BLACK, "SECURITY", GOLD)
end

-- Teacher / instructor: emerald green blazer, white blouse, dark skirt, school ID
BUILDERS.Teacher = function(character, folder)
	stashClothing(character, folder)
	paint(character, folder, "chest", EMERALD)
	paint(character, folder, "upperArms", EMERALD)
	paint(character, folder, "lowerArms", EMERALD)
	paint(character, folder, "waist", CHARCOAL)
	paint(character, folder, "upperLegs", CHARCOAL)
	paint(character, folder, "feet", BLACK)
	local t = torso(character)
	local cf = chestCF(character)
	local w = waistCF(character)
	if t and cf then
		-- white blouse showing in the blazer's V opening
		addPart(folder, t, cf * CFrame.new(0, 0.15, frontZ(character, 0.01)), {Name = "Blouse", Size = Vector3.new(0.5, 1.0, 0.03), Color = WHITE})
		addPart(folder, t, cf * CFrame.new(-0.22, 0.42, frontZ(character, 0.02)) * CFrame.Angles(0, 0, math.rad(-25)), {Name = "Lapel", Size = Vector3.new(0.18, 0.55, 0.04), Color = EMERALD_DARK})
		addPart(folder, t, cf * CFrame.new(0.22, 0.42, frontZ(character, 0.02)) * CFrame.Angles(0, 0, math.rad(25)), {Name = "Lapel", Size = Vector3.new(0.18, 0.55, 0.04), Color = EMERALD_DARK})
		local pin = addPart(folder, t, cf * CFrame.new(-0.55, 0.15, frontZ(character, 0.03)), {Name = "SchoolPin", Size = Vector3.new(0.32, 0.32, 0.03), Color = GOLD, Material = Enum.Material.Metal})
		addLabel(pin, Enum.NormalId.Front, "SC", EMERALD_DARK)
	end
	if t and w then
		-- knee-length skirt around the hips (R6 legs can't be split, so it's a separate piece)
		addPart(folder, t, w * CFrame.new(0, -0.55, 0), {Name = "Skirt", Size = Vector3.new(2.1, 1.3, 1.1), Color = CHARCOAL})
	end
	idLanyard(folder, character, EMERALD_DARK, "FACULTY")
end

-- Student working part-time at the canteen: white SC polo, green apron and cap, student ID
BUILDERS.Cashier = function(character, folder)
	stashClothing(character, folder)
	paint(character, folder, "chest", WHITE)
	paint(character, folder, "upperArms", WHITE)
	paint(character, folder, "waist", CHARCOAL)
	paint(character, folder, "upperLegs", CHARCOAL)
	paint(character, folder, "lowerLegs", CHARCOAL)
	paint(character, folder, "feet", BLACK)
	local t = torso(character)
	local cf = chestCF(character)
	local w = waistCF(character)
	if t and cf then
		addPart(folder, t, cf * CFrame.new(0, 0.62, -0.05), {Name = "Collar", Size = Vector3.new(1.0, 0.12, torsoDepth(character) + 0.08), Color = EMERALD})
		local apron = addPart(folder, t, cf * CFrame.new(0, -0.45, frontZ(character, 0.03)), {Name = "Apron", Size = Vector3.new(1.5, 1.7, 0.04), Color = EMERALD})
		addLabel(apron, Enum.NormalId.Front, "SC CANTEEN", WHITE)
		addPart(folder, t, cf * CFrame.new(0, 0.55, frontZ(character, 0.03)), {Name = "ApronStrap", Size = Vector3.new(0.8, 0.12, 0.04), Color = EMERALD})
	end
	if character:FindFirstChild("Torso") then
		-- R6: short sleeves (arms are skin-coloured below a white sleeve)
		for _, armName in ipairs({"Left Arm", "Right Arm"}) do
			local arm = character:FindFirstChild(armName)
			if arm then
				local skin = folder:GetAttribute(origKey(armName)) or arm.Color
				arm.Color = skin
				addPart(folder, arm, arm.CFrame * CFrame.new(0, 0.6, 0), {Name = "Sleeve", Size = Vector3.new(1.06, 0.85, 1.06), Color = WHITE})
			end
		end
	end
	cap(folder, character, EMERALD, EMERALD_DARK, "SC", WHITE)
	idLanyard(folder, character, EMERALD_DARK, "STUDENT")
end

------------------------------------------------------------------ shop cosmetics

-- Foundation Day Cap (emerald with gold "SC")
BUILDERS.FoundationCap = function(character, folder)
	cap(folder, character, EMERALD, GOLD, "SC", GOLD)
end

-- Reading Glasses
BUILDERS.ReadingGlasses = function(character, folder)
	local head = character:FindFirstChild("Head")
	if not head then return end
	-- Avatar heads have a FaceFrontAttachment at eye level (what real glasses use);
	-- classic R6 heads don't, so fall back to a fixed spot.
	local face = head:FindFirstChild("FaceFrontAttachment")
	local y = face and (face.Position.Y - 0.05) or 0.12
	-- always in front of the face surface, even on heads that bulge past the attachment
	local z = face and math.min(face.Position.Z - 0.08, -(head.Size.Z / 2 + 0.07)) or -0.62
	local halfWidth = math.max(head.Size.X, 1.1) / 2
	for _, x in ipairs({-0.26, 0.26}) do
		addPart(folder, head, head.CFrame * CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(90), 0), {Name = "Lens", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.05, 0.36, 0.36), Color = BLACK})
		local glass = addPart(folder, head, head.CFrame * CFrame.new(x, y, z - 0.02) * CFrame.Angles(0, math.rad(90), 0), {Name = "Glass", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.02, 0.28, 0.28), Color = Color3.fromRGB(200, 230, 255), Material = Enum.Material.Glass})
		glass.Transparency = 0.5
	end
	addPart(folder, head, head.CFrame * CFrame.new(0, y + 0.02, z), {Name = "Bridge", Size = Vector3.new(0.2, 0.05, 0.04), Color = BLACK})
	for _, x in ipairs({-halfWidth, halfWidth}) do
		addPart(folder, head, head.CFrame * CFrame.new(x, y, z / 2), {Name = "Arm", Size = Vector3.new(0.04, 0.05, math.abs(z)), Color = BLACK})
	end
end

-- CLAS department uniform (white polo, emerald collar & trim, CLAS patch)
BUILDERS.CLASUniform = function(character, folder)
	stashClothing(character, folder)
	paint(character, folder, "chest", WHITE)
	paint(character, folder, "upperArms", WHITE)
	paint(character, folder, "waist", CHARCOAL)
	paint(character, folder, "upperLegs", CHARCOAL)
	paint(character, folder, "lowerLegs", CHARCOAL)
	paint(character, folder, "feet", BLACK)
	local t = torso(character)
	local cf = chestCF(character)
	if t and cf then
		addPart(folder, t, cf * CFrame.new(0, 0.62, -0.05), {Name = "Collar", Size = Vector3.new(1.0, 0.12, torsoDepth(character) + 0.08), Color = EMERALD})
		addPart(folder, t, cf * CFrame.new(0, 0.2, frontZ(character, 0.02)), {Name = "Placket", Size = Vector3.new(0.14, 0.75, 0.03), Color = EMERALD})
		local patch = addPart(folder, t, cf * CFrame.new(-0.5, 0.15, frontZ(character, 0.03)), {Name = "Patch", Size = Vector3.new(0.5, 0.32, 0.03), Color = EMERALD})
		addLabel(patch, Enum.NormalId.Front, "CLAS", WHITE)
	end
end

------------------------------------------------------------------ public API

function Outfits.has(outfitName)
	return BUILDERS[outfitName] ~= nil
end

function Outfits.remove(character, outfitName)
	local folder = character:FindFirstChild("Outfit_" .. outfitName)
	if not folder then return end
	-- restore colours
	for _, part in ipairs(character:GetChildren()) do
		if part:IsA("BasePart") then
			local original = folder:GetAttribute(origKey(part.Name))
			if original then part.Color = original end
		end
	end
	-- restore clothing and logo
	local stash = folder:FindFirstChild("StashedClothing")
	if stash then
		for _, c in ipairs(stash:GetChildren()) do c.Parent = character end
	end
	local logoT = folder:GetAttribute("LogoTransparency")
	if logoT then
		local t = torso(character)
		local logo = t and t:FindFirstChild("roblox")
		if logo then logo.Transparency = logoT end
	end
	folder:Destroy()
end

function Outfits.removeAll(character)
	for _, child in ipairs(character:GetChildren()) do
		local name = string.match(child.Name, "^Outfit_(.+)$")
		if name and child:IsA("Folder") then
			Outfits.remove(character, name)
		end
	end
end

function Outfits.wear(character, outfitName)
	local builder = BUILDERS[outfitName]
	if not builder or not character then return false end
	Outfits.remove(character, outfitName) -- avoid stacking duplicates
	local folder = getFolder(character, outfitName)
	local ok, err = pcall(builder, character, folder)
	if not ok then
		warn("[Outfits] Failed to build " .. outfitName .. ": " .. tostring(err))
	end
	return ok
end

return Outfits
