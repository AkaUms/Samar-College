-- HUDConfig.lua
-- Settings for the Bag / Map / Settings HUD. Edit freely.

return {
	-- Place ID of the separate Elementary (kids) server. 0 = not set up yet.
	ElementaryPlaceId = 0,

	-- World area that your map image covers (top-down, image top = MinZ, left = MinX).
	-- Pins are placed on the image using these bounds.
	MapBounds = { MinX = -130, MaxX = 330, MinZ = -400, MaxZ = 380 },

	-- Places on the map. Position = where the player is teleported (standing height).
	-- Optional MapX / MapY (0-1) override the pin position on the image.
	Places = {
		{ Id = "MainGate",      Name = "Main Gate",            Icon = "🚪", Position = Vector3.new(252, 20, -26) },
		{ Id = "Courtyard",     Name = "Courtyard",            Icon = "🏀", Position = Vector3.new(125, 3.5, 15) },
		{ Id = "Canteen",       Name = "Canteen (Cashier)",    Icon = "🍽️", Position = Vector3.new(102, 4.5, 154) },
		{ Id = "DeansOffice",   Name = "Dean's Office",       Icon = "🏛️", Position = Vector3.new(205, 4, -135) },
	},

	TeleportCooldown = 3, -- seconds between map teleports
}
