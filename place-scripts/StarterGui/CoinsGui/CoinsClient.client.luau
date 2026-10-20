-- CoinsClient: top-centre coin bar (Common + Event) with a Bag button.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local gui = script.Parent

local C = {
	panel = Color3.fromRGB(30, 30, 40), pill = Color3.fromRGB(42, 44, 58), stroke = Color3.fromRGB(78, 84, 110),
	text = Color3.fromRGB(240, 242, 248), dim = Color3.fromRGB(150, 156, 176),
	common = Color3.fromRGB(255, 200, 60), event = Color3.fromRGB(176, 120, 255),
}
local function corner(p, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r) c.Parent = p end
local function stroke(p, col, t) local s = Instance.new("UIStroke") s.Color = col s.Thickness = t or 1.4 s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border s.Parent = p return s end

local bar = Instance.new("Frame") bar.Name = "CoinBar" bar.AnchorPoint = Vector2.new(0.5, 0)
bar.Position = UDim2.new(0.5, 0, 0, 10) bar.Size = UDim2.fromOffset(312, 52)
bar.BackgroundColor3 = C.panel bar.BackgroundTransparency = 0.12 bar.Parent = gui
corner(bar, 14) stroke(bar, C.stroke, 1.2)
local scale = Instance.new("UIScale") scale.Parent = bar
local function rescale() scale.Scale = math.clamp(workspace.CurrentCamera.ViewportSize.X / 700, 0.6, 1) end
rescale() workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
local lay = Instance.new("UIListLayout") lay.FillDirection = Enum.FillDirection.Horizontal lay.VerticalAlignment = Enum.VerticalAlignment.Center
lay.HorizontalAlignment = Enum.HorizontalAlignment.Center lay.Padding = UDim.new(0, 8) lay.SortOrder = Enum.SortOrder.LayoutOrder lay.Parent = bar

local pills = {}
local function makePill(name, label, icon, color, order)
	local p = Instance.new("Frame") p.Name = name .. "Pill" p.Size = UDim2.fromOffset(146, 40) p.BackgroundColor3 = C.pill p.LayoutOrder = order p.Parent = bar
	corner(p, 12) stroke(p, color, 1.4)
	local ic = Instance.new("TextLabel") ic.Name = "Icon" ic.Size = UDim2.fromOffset(32, 32) ic.Position = UDim2.fromOffset(4, 4)
	ic.BackgroundColor3 = color ic.Text = icon ic.TextScaled = true ic.Font = Enum.Font.GothamBold ic.Parent = p corner(ic, 16)
	local pad = Instance.new("UIPadding") pad.PaddingTop = UDim.new(0, 4) pad.PaddingBottom = UDim.new(0, 4) pad.PaddingLeft = UDim.new(0, 4) pad.PaddingRight = UDim.new(0, 4) pad.Parent = ic
	local lb = Instance.new("TextLabel") lb.Name = "Label" lb.BackgroundTransparency = 1 lb.Position = UDim2.fromOffset(42, 3) lb.Size = UDim2.new(1, -46, 0, 13)
	lb.Font = Enum.Font.GothamBold lb.TextSize = 10 lb.TextColor3 = C.dim lb.Text = label lb.TextXAlignment = Enum.TextXAlignment.Left lb.Parent = p
	local amt = Instance.new("TextLabel") amt.Name = "Amount" amt.BackgroundTransparency = 1 amt.Position = UDim2.fromOffset(42, 15) amt.Size = UDim2.new(1, -46, 0, 22)
	amt.Font = Enum.Font.GothamBlack amt.TextSize = 19 amt.TextColor3 = C.text amt.Text = "0" amt.TextXAlignment = Enum.TextXAlignment.Left amt.Parent = p
	if icon == "C" then
		ic.TextColor3 = Color3.fromRGB(150, 95, 10) ic.Font = Enum.Font.GothamBlack
		local ring = Instance.new("UIStroke") ring.Color = Color3.fromRGB(255, 232, 140) ring.Thickness = 2 ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border ring.Parent = ic
	end
	local ps = Instance.new("UIScale") ps.Parent = p
	pills[name] = { frame = p, amount = amt, scale = ps, color = color, shown = nil }
end
makePill("Common", "COMMON COIN", "C", C.common, 1)
makePill("Event", "EVENT COIN", "⭐", C.event, 2)

local function fmt(n) local s = tostring(math.floor(n)) local r = s:reverse():gsub("(%d%d%d)", "%1,"):reverse() return (r:gsub("^,", "")) end

local function floatText(p, delta)
	local f = Instance.new("TextLabel") f.BackgroundTransparency = 1 f.AnchorPoint = Vector2.new(0.5, 0)
	f.Position = UDim2.new(0.5, 10, 1, 2) f.Size = UDim2.fromOffset(90, 20) f.Font = Enum.Font.GothamBlack f.TextSize = 16
	f.Text = (delta > 0 and "+" or "") .. fmt(delta) f.TextColor3 = delta > 0 and Color3.fromRGB(90, 230, 130) or Color3.fromRGB(255, 100, 100)
	f.TextStrokeTransparency = 0.4 f.Parent = p.frame
	TweenService:Create(f, TweenInfo.new(1.1), { Position = UDim2.new(0.5, 10, 1, 24), TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(1.2, function() f:Destroy() end)
end

local function show(name, value)
	local p = pills[name]
	if p.shown == nil then p.shown = value p.amount.Text = fmt(value) return end
	local from = p.shown local delta = value - from
	if delta == 0 then return end
	p.shown = value
	floatText(p, delta)
	p.scale.Scale = 1.12 TweenService:Create(p.scale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	local nv = Instance.new("NumberValue") nv.Value = from
	nv.Changed:Connect(function(v) p.amount.Text = fmt(v) end)
	local t = TweenService:Create(nv, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { Value = value }) t:Play()
	t.Completed:Connect(function() p.amount.Text = fmt(value) nv:Destroy() end)
end

local wallet = player:WaitForChild("Wallet", 30)
if wallet then
	for _, name in ipairs({ "Common", "Event" }) do
		local v = wallet:WaitForChild(name, 10)
		if v then show(name, v.Value) v.Changed:Connect(function(n) show(name, n) end) end
	end
end
