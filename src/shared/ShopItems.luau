-- ShopItems.lua
-- Item catalog for the Cashier's shop.
-- Categories: Cosmetic (visual only), Equipment (has an effect while equipped), Consumable (used up).
-- RequiredLevel (optional) = LevelConfig level index needed to buy (2 = Grade 1, 4 = Grade 3, 14 = 1st Year).
-- Currency is "Common" (regular games) or "Event" (special events).
-- Add or edit items here; the shop GUI, inventory GUI and server update automatically.

return {
	Cosmetic = {
		{Id = "FoundationCap", Name = "Foundation Day Cap", Desc = "Limited event cosmetic. Visual only.", Icon = "🧢", Price = 40, Currency = "Event", RequiredLevel = 2},
		{Id = "ReadingGlasses", Name = "Reading Glasses", Desc = "A face accessory. Visual only.", Icon = "👓", Price = 60, Currency = "Common", RequiredLevel = 4},
		{Id = "CLASUniform", Name = "CLAS Uniform", Desc = "Department outfit. Visual only.", Icon = "👕", Price = 80, Currency = "Common", RequiredLevel = 14},
	},
	Equipment = {
		{Id = "RunningShoes", Name = "Running Shoes", Desc = "Walk faster while equipped.", Icon = "👟", Price = 30, Currency = "Event"},
		{Id = "SpringBoots", Name = "Spring Boots", Desc = "Jump higher while equipped.", Icon = "🥾", Price = 200, Currency = "Common"},
		{Id = "Flashlight", Name = "Flashlight", Desc = "A flashlight tool while equipped. Lights up dark areas.", Icon = "🔦", Price = 100, Currency = "Common"},
	},
	Consumable = {
		{Id = "PizzaSlice", Name = "Pizza Slice", Desc = "Restores 15 health instantly.", Icon = "🍕", Price = 15, Currency = "Common"},
		{Id = "SmallSnack", Name = "Canteen Snack", Desc = "Restores 25 health instantly.", Icon = "🍪", Price = 25, Currency = "Common"},
		{Id = "MedKit", Name = "Med Kit", Desc = "Restores all of your health instantly.", Icon = "🩹", Price = 80, Currency = "Common"},
		{Id = "EnergyDrink", Name = "Energy Drink", Desc = "Speed boost for 30 seconds.", Icon = "🥤", Price = 40, Currency = "Common"},
		{Id = "GlowStick", Name = "Glow Stick", Desc = "Attaches a light to your character for 60 seconds.", Icon = "✨", Price = 15, Currency = "Event"},
		{Id = "InvisibilityPotion", Name = "Invisibility Potion", Desc = "Turns you invisible for 10 seconds.", Icon = "🧪", Price = 100, Currency = "Common"},
	},
}
