# Changelog

## 2026-10-21 (night)
- SHS Faculty Room (`FacultyRoom_SHS_2F`), from real photos. Outside: cream wall, black window frames, green curtains behind the glass, projecting "SENIOR HIGH SCHOOL FACULTY ROOM" sign, "Faculty only" plate, black grooved door with round knob. Inside: 6 teacher workstations with computers, name plates and chairs, SHS Faculty Bulletin (meeting, deadlines, advisers), learning-module shelf, steel cabinet, meeting table with monobloc chairs, stacked chairs, water dispenser, mini fridge with kettle, split aircon, clock, lights.
- Records Office and Faculty Room doors now show their black colour (union used its own wood colour before).
- SHS Records Office (`RecordsOffice_SHS_2F`), from real photos. Outside: cream wall, transom window strip, "Senior High School Records Office" sign, projecting "SENIOR HIGH SCHOOL RECORD SECTION" sign, SAVE ENERGY sign and switch, SHS Enrollment tarpaulin (academic tracks + requirements), waiting chairs; black panelled door with view window, document slot, lever and deadbolt. Inside: record shelves with labelled archive boxes and folders, steel cabinets, filing cabinets, 2 staff desks with computers, printer table, visitor chair, Document Requests board, split aircon, clock, lights.
- SSLG Office interior (`SSLG_Office_2F`): cream walls, tiled floor, fluorescent lights, SSLG tarpaulin, Philippine flag, conference table with monobloc chairs, officer's desk with computer, filing cabinet, bookshelf with binders and trophies, whiteboard meeting agenda, officers and announcement boards, ballot box and suggestion box, water dispenser, wall fan, clock, trash bin and plant.
- Stair hall outside: cream soffits under the stair flights and landing, wire bundle along the wall top.
- Stair hall beside the SSLG office (2nd floor) detailed from a real photo: cream walls, "THIS WAY – THIRD FLOOR" sign, light switch and conduit, SSLG OFFICE plaque and notice on the door, vent blocks, CCTV dome with coiled cable, warning sign, ceiling bulb, blue drum, metal grille cabinet, old wall boards, wooden louvers above the stairs, orange PVC pipe, yellow arrows on the steps (`StairHall_2F_Details`). Roof downspout that ran in front of the door now stops at the ceiling.
- Stair railings between the flights rebuilt to follow the steps' angle and reach the bottom step / top railing.
- Rooms 202, 204, 302, 303, 304, 305 changed to Senior High School classrooms: Grade 11 STEM A, HUMSS A, GAS A and Grade 12 TVL-ICT A, ABM A, STEM B — SHS subjects on the board, TV and schedules, door signs, "ADVISER" nameplate, SHS banner. Originals backed up in ServerStorage.Backup_Classrooms_PreSHS.
- Cashier's Shop window now scales to fit phones and tablets (it was 600x470 and overflowed small screens) and draws above the HUD. Old InventoryGui (disabled, replaced by the Bag) also scales and no longer reacts to [I].
- Phone / tablet layout pass (checked with Studio's device emulator, iPhone XR): side buttons sit near the top on phones so the thumbstick never covers Admin; coin bar shrinks on small screens; Bag / Map / Settings now draw above the coin bar (MainHUD DisplayOrder 10); hotbar uses the touch layout in the emulator too. All panels fit every device in Studio's device list (iPhone 7 up to iPad Pro 13 and Android TV).
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
