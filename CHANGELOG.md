# Changelog

## 2026-10-21 (night)
- Profile and Admin panels: the dark background now covers the whole screen (top bar, notch and screen edges), and both panels scale to fit any phone, tablet or PC screen. Profile close button shows "X".
- Inventory hotbar fits every screen size (Android, iPhone, tablets, PC): scales to the screen and stays clear of the mobile thumbstick and jump button; shows "Tap to use" on touch devices.
- Inventory hotbar hides while Bag, Map, Settings, Profile, Admin or the Shop is open, and comes back when they close.
- Invisible power: you now see yourself at 10% opacity on your own screen only; other players still see nothing (no avatar, name or effects). Replaces the outline highlight.

## 2026-10-21 (evening)
- Admin panel (`AdminServer` + `AdminPanelGui/AdminClient`): player search, kick, timed ban / unban, reset progress, grade promote / demote, coins, items, consumables, event counts, co-admin management, Save button.
- Admin powers: invisible, god mode, fly (custom speed), walk speed — instant on/off, kept through respawns (`AdminPowersClient`).
- Banned players list with Unban buttons.
- Level progression now uses a separate per-level quiz timer (`LevelTimeSeconds`); total play time is unchanged.
- PlayerData saves the level timer and new event counters (Common, Rare, Parkour, Escape, Photobooth).

## 2026-10-21
- Gate facade: gabled pediment, pilasters, arches, cornice and EXIT / ENTRANCE plaques based on the real campus front.
- Samar College seal on the gable (redrawn in green to match the official logo); `SC_LogoData` + `SC_LogoDecoder` + `SC_LogoRenderer` show the exact logo when *Allow Mesh / Image APIs* is enabled.
- ID scanner turnstiles at Entry and Exit: single passage, 2 wall-mounted ID readers, flap gate, 2 ceiling-hung monitors with a digital student ID.
- Driveway: railings, painted curbs, lane markings, speed humps, zebra crossing, ceiling and wall lights, signs.
- Proximity voice chat speaking indicator (`VoiceSupport`) — removed again on request; voice uses Roblox defaults.

## 2026-10-20
- Main gate (double swing, prompts + control button, auto-close) and full-size Entry / Exit pedestrian gates.
- Removed a utility pole, light posts and A-frame signs blocking the road.
- Front wall raised to awning height; flat roof, then a corrugated GI metal roof with clear panels over the garden.
- Security post furnished and rearranged (CCTV wall, desks, lockers, first aid, waiting chairs, notice board, garden doorway).
- Garden with flower beds, shrubs and trees.

## 2026-10-19
- San Roque Street outside the campus (shops, poles and wires, vehicles, hills).
- Profile panel with level / quiz system, achievements, level-locked shop cosmetics.
- Leaderboard *Time* and *Title* with DataStore saving; Common / Event coin counter; hotbar fixes.

## Earlier
- Classrooms, computer labs, science labs, offices, technical room, storage rooms and Photo/ID studio detailed.
- 4F rusty GI roof, 2F / 3F corridor railings and awnings, pergola.
- Inventory hotbar, shop, NPC dialogs, guard patrol, prompt-only seats.
