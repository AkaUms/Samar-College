# Changelog

Each heading is the date and time of the push, in Philippine Time (PHT, UTC+08:00).

## 2026-10-24 8:30pm
- **Office of the Senior Vice President for Administration (1F)**, next to the clinic, built from a real photo and grouped as `1F_Ground/02_Rooms/SVP_AdminOffice` (Structure, Outside, Inside, Lighting). Its door, front walls, door header and floor were moved in and renamed (`OfficeDoor`, `FrontWall_NorthOfDoor` / `_SouthOfDoor` / `_OverDoor`, `Slab`; old names in the `OldName` attribute).
  - **Outside**: green blade sign "Office of the Senior Vice President for Administration" with the school seal, door with natural wood planks, a glass strip, office-hours notice, deadbolt and brass bolt (they move with the door), dark wood door frame, three carved wooden notice boards behind glass (Administration board with a "RELEASED" memorandum, office hours, reminders and a calendar; Announcements board with "Know your Electives" posters; Office Directory), white slatted bench (3 seats), Wi-Fi access point, black and blue cable bundle, 2 bare bulbs, a "Please keep to the right" hanging sign.
  - The wooden glass case between the clinic and this office is now the carved **Administration** notice board (the photo shows it is a notice board), replacing the clinic's "Health Corner" cabinet.
  - **Inside**: cream walls with wood wainscot panelling, beige tiles, white ceiling grid. Front office: administrative assistant's desk facing the door (computer, phone, trays, visitor's logbook, name plate), return desk with a printer, 2 staff workstations with a divider, waiting sofa with a coffee table and plant, 3 steel filing cabinets, water dispenser, photocopier, Vision / Mission frames, "Our Services" board.
  - **SVP's own room** behind a wood-and-glass partition with its own door: executive desk (computer, desk lamp, phone, name plate, pen set, stamp pad, mini flag), leather executive chair, 2 visitor chairs, credenza with books, a trophy, a plaque and a photo, framed certificates, bookshelf, 3-seat sofa and 2 armchairs on a rug with a glass coffee table, Philippine flag and school flag, plants, wall TV.
  - **Sit** (E): 17 seats — bench outside, assistant's chair, visitor chair, 2 staff chairs, 2-seat waiting sofa, SVP's chair, 2 visitor chairs, 3-seat sofa, 2 armchairs.
  - **Lights**: "OFFICE LIGHTS" (by the door) and "SVP OFFICE LIGHTS" (by the inner door), 3 tube lights each, E on / off only, always at Medium.
- **New: on / off devices** (`PowerToggles` server script, tag `PowerToggle`): 2 aircons (E on the wall controller: louver opens, cold-air mist, display and LED), 4 computers, the desk lamp and the TV (F, so they never clash with E "Sit").
- **New: live wall clocks** (`LiveClocks` client script, tag `LiveClock`): clocks show the real Philippine time with a moving second hand. The clinic clock now uses it too.

## 2026-10-24 7:48pm
- **Medical and Dental Clinic (1F)** detailed from real photos, grouped as `1F_Ground/02_Rooms/MedicalDentalClinic` (Structure, Outside, Inside, Lighting). The door, window, 2 beds and 2 IV pumps were moved in and renamed (`ClinicDoor`, `Window_Corridor`, `Bed_1` / `Bed_2`, `IVPump_1` / `IVPump_2`; old names kept in the `OldName` attribute).
  - **Room**: cream plaster walls with a mint wainscot, dark green skirting and white chair rail (added on the inside only, so the corridor and the next room keep their look), white tile floor with a green border, door mat, white ceiling with a panel grid and cove trim.
  - **Outside**: green double-sided "Medical and Dental Clinic" blade sign with the clinic seal, white grille over the window with posters (Medical Services and clinic hours, Dental Clinic schedule, Leptospirosis, Tuberculosis, Dengue), door with a vision glass, "We're Open" card, clinic hours card, "Clinic" plate, kick plate and open padlock (all move with the door), 3-gang switch plate with blue conduit, memorandum, "Health Corner" display cabinet, 2 corridor tube lights.
  - **Inside**: nurse's desk (monitor, BP monitor, stethoscope, logbook, name plate) with a swivel chair and 2 patient chairs, logbook table by the door ("Please log in"), 4-seat waiting bench, wall clock, fire extinguisher, first-aid box (green cross), sink counter with mirror, soap and paper towels, yellow / black waste bins, handwashing poster, medicine cabinet, examination couch with a step stool and curtain, beam scale, wheelchair, oxygen tank, aircon, clinic reminders, window curtains.
  - **Dental area**: dental chair with a ceiling lamp, cuspidor and instrument tray, dentist stool, long dental cabinet (autoclave, gloves, face masks, UV sterilizer), x-ray viewer, "Brush twice a day" poster, folding privacy screen.
  - **Ward**: privacy curtains on ceiling tracks, bed-head panels (O₂ / vacuum / air outlets, sockets, call button, lamp, bed number), bedside table, 2 visitor chairs.
  - **Sit** (E): 15 seats — nurse's chair, 2 patient chairs, 4 waiting seats, examination couch, wheelchair, dental chair, dentist stool, 2 beds, 2 visitor chairs. The beds' old touch seats were removed, so nobody sits by walking into a bed.
  - **Lights**: 6 tube lights, the dental lamp and the x-ray viewer on a "CLINIC LIGHTS" switch by the door — E on / off only (no brightness button), always at Medium.

## 2026-10-24 3:45pm
- Changelog: every push now has its own heading with the date and time it was pushed (Philippine Time).

## 2026-10-24 3:32pm
- **Main hallway (1F)** detailed from real photos, grouped as `1F_Ground/07_Common_Areas/MainHallway_1F` (Structure, Benches, HallOfFame, OfficeWindow, Lighting, CeilingDevices, Signs, Props, StairRailing):
  - Cream plaster walls and pillars (repainted parts keep their old look in the `OrigMaterial` / `OrigColor` attributes), white ceiling with cream cross beams on every pillar line, edge beams, 4 new pillars on the open side, white tiles carried over the grey strips by the far walls.
  - **Sit**: the 4 built-in concrete benches along the wall got white slab tops and 28 E "Sit" spots. The bench ledges have the `Furniture` attribute, so PromptGuard doesn't treat them as walls.
  - Two honour boards with framed portraits (plain silhouettes) and brass plaques ("Our Founders and Past Administrators", "Samar College Wall of Honor"), and an Announcements board with pinned memos and a calendar.
  - Office window: low wall with the Samar College banner, shelf with binders and a clock, jars, thermos, papers, desk fan, sagging cables, junction box, posted notices.
  - **Lights**: 7 tube lights in the hallway + 3 in the open hall beside it, on a "HALLWAY LIGHTS" switch on the pillar (E on / off, R brightness), plus an outlet plate.
  - Smoke detectors, 2 CCTV domes, bullet camera with a red "Video Surveillance – CCTV in operation" sign, brown "Caution – Do not enter – Authorized personnel only" door (locked), "Please keep this door closed" notice, white grille on the far window, blue water gallons, cartons with a WARNING storage sign, red "Cold Drinks – Refresh ka muna!" wall (own design, no brand), white stair railings with a guard on the open side.
- PromptGuard: parts with the attribute `Furniture = true` never hide an E prompt.

## 2026-10-24 2:35pm
- **🚩 Player reports**: new Report button on the left side buttons for every player. Pick who (players in your server), what they did (bullying, bad language, cheating / exploiting, scamming, inappropriate avatar or behavior, asking for / sharing personal info, dating, spamming, other) and optional details (200 characters, Roblox text filter). Limits: 1 report a minute, the same person once every 10 minutes, 15 a day. New `PlayerReports` module, `ReportServer` script, `ReportClient` and shared `ReportConfig`.
- **🚩 Reports tab** in the admin panel (📋 Player Records): filters Waiting for review / Investigating / Done / All with counts. Each report shows a check box and a status list box:
  - 🟡 **Waiting for review** — no admin has checked this report yet
  - 🔍 **Investigating by <admin> (role)** — the other admins see who took it
  - ✅ **Done — checked by <admin> (role)** with the result (Warned / Kicked / Banned / No rule broken / Other) and the proof / notes
  - Plus who reported it, the server, details, whether the reported player is online now, Go to / Join their server, Manage player, Time in / out, All reports about them, and the report's history.
  - Admins in every server get a notice when a report comes in or someone takes one; the 📋 button and tab show how many are waiting. The selected player's card shows their number of reports and a 🚩 Reports button.
- **Online now**: "Where on campus" removed. Shows your server ID and every server's full ID (click, Ctrl+C to copy) and each player's server ID. Server boxes minimize / maximize (click the top bar, or Minimize all / Maximize all). Join server button on each other server and Join on each of its players.
- `StudioStores` module: the Studio test stand-ins, now shared by Player Records and Player Reports.

## 2026-10-24 1:49pm
- **Player Records** in the admin panel (📋 button in the panel header), new `PlayerRecords` module:
  - 🟢 **Online now**: everyone online in every server, grouped by server (code, place, type, players, how long it has been running). Each player shows where they are on campus (room or area, e.g. "1F · FH3 COED Room", "2F · Corridor", "San Roque Street (outside campus)"), time in, how long they've been online and their title. Buttons: Go to (same server), Join this server (other public servers), Log, Manage. Refreshes every 15 s.
  - 📚 **All players**: every player who has joined, by user ID, with title, time played, coins, number of joins, first joined and last seen (or "Online"). Sort by last seen or most time played, 20 per page with "Load more". The owner's "Add older saves" adds players from before Player Records to the list.
  - 🕒 **Time in / out**: everyone's recent time in / time out (last 3 days) and each player's full log (last 40 visits: date, time in, time out, how long, server). Search a username or ID with "Show log". Times are shown in the viewer's time zone.
  - The selected player's card now says where they are (in this server / online in server X / offline, last seen …) and has a "Time in / out" button.
  - Saved in `SamarCollege_Sessions_v1` (DataStore), `SamarCollege_LastSeen_v1` and `SamarCollege_PlayTime_v1` (ordered DataStores); live data in MemoryStore (`SC_Online_v1`, `SC_Servers_v1`, `SC_Sessions_v1`), which clears itself. In Studio without API access it works for the test session only.
- `PlayerData` notices that Studio API access is off on the first try (no 3 s retry delay and no failed-save spam), and keeps the last snapshot of a player who just left.

## 2026-10-24 3:56am
- COED classrooms FH 1 and FH 2 (1F, old `Classroom_1F_003` / `_004`), same full setup as FH 3 / FH 4, grouped as `FH1_COED_Room` / `FH2_COED_Room` (Structure, Inside, Outside); originals in ServerStorage.Backup_COED_Rooms.
  - Inside: 30 armchairs in 5 rows + teacher's chair with E "Sit", sliding whiteboard over a TV (FH 1: Assessment in Learning 1 / Types of Test Items; FH 2: Facilitating Learner-Centered Teaching / Learning Styles), 6 tube lights on a switch by the door (E on/off, R brightness), blue wainscot, tiles, drop ceiling, College of Education banner, Philippine flag, own class schedules, classroom rules, clock, PPST / Code of Ethics posters plus "Philosophies of Education" (FH 1) and "Multiple Intelligences" (FH 2), Future Educators' Corner, IM corner, flip chart, aircon, cabinet, bins, extinguisher, CCTV, smoke detector.
  - Outside, from the photo: brown panel doors with a yellow sticker, "FH 1" / "FH 2" number plates above the doors, green projecting signs on the pillars, white brick-pattern window grilles, wall plaques, corridor bulbs.
  - Corridor (`1F_Ground/07_Common_Areas/Corridor_FH1_FH2`): cross beams at the pillars with the yellow "Please keep to the right – for distancing purposes" sign, two sagging black cables on spool insulators, cable bundle with white PVC conduits along the outer edge, CCTV dome.

## 2026-10-24 3:44am
- **No more using things through walls** (`PromptGuard`, StarterPlayerScripts): every E-prompt in the game (518+ — sit, light switches, doors, gates, windows, curtains, whiteboards, NPCs, ID scanners) is hidden unless you can really reach it. A wall, door, window glass or jalousie, pillar, grille, low wall, floor or ceiling between you and it hides it; furniture does not. You also have to be able to walk to it (no reaching through windows). Windows and curtains only work from inside the room (`UseSide` attribute). Checked with an automated test that stood behind every wall next to every prompt in Play.
- Shorter ranges: Sit 5 studs (was 7), light switches 5 (was 9), doors 6 (was 10), whiteboards / grille gates / entry-exit gates 6, windows and curtains 5, NPC talk 8, main gate 10.
- Light switch prompts no longer show at the same time as a door's E prompt (they were "AlwaysShow", so one E press could switch the lights and open the door together). Now only the nearest E prompt shows.

## 2026-10-24 3:04am
- Utility passage grille gate now sits at the passage entrance (moved there in Studio): grille filled up to the ceiling, "Storage – Authorized personnel only" plate moved onto the new gate head. E at the lock box opens / closes it (checked with a real prompt press in Play).

## 2026-10-24 2:58am
- Utility passage behind FH 4 (1F, `1F_Ground/07_Common_Areas/UtilityPassage_FH4`), rebuilt from a real photo:
  - **Storage grille gate** at the end: black steel grille wall with transom and a double gate that swings out with E at the lock box (padlock, chain, drop bolt; uses `SwingGates`). Inside: steel shelves with boxes, paint cans and tarps, stacked monobloc chairs, aluminium ladder, old table with toolbox and extension reel, mop bucket, bare bulb.
  - **Lights**: 3 downlights + the storage bulb on a "PASSAGE LIGHTS" switch by the entrance (E on/off, R brightness).
  - **Sit**: the old wooden chair by the wall has E "Sit".
  - Photo details: cream walls, dark floor tiles with a white tile path and hatch cover, dropped beams, sawhorse table, leaning planks and boards, blue and white PVC pipes, green electrical panel with conduits and a wire coil, white access board, plywood sheet and plywood hoarding with a corrugated top, galvanized duct and sagging cable bundle along the ceiling, bullet CCTV, WARNING video surveillance and tampering signs, "Storage – Authorized personnel only" plate.

## 2026-10-24 2:44am
- Canteen walkway, stair passage and east canopy (1F) detailed from real photos, grouped as `1F_Ground/07_Common_Areas/CanteenWalkway_Stairs` (SouthWalkway_Canopy, CanteenWalkway, StairPassage, EastCanopy_Walk, Lighting, LightSwitches, Signs):
  - New steel canopy over the south walkway: galvanized corrugated roof with foil underside, rafters, purlins and trusses, green steel posts with braces, green fascia, white gutter and downspouts. The east canopy got the same look (painted steel frame, green posts, gutter, downspouts).
  - **Sit benches**: 12 white slat benches with backrests (24 sit spots, E "Sit") — in front of the canteen windows, along the low wall, in the stair passage and under the east canopy. Old dark benches in ServerStorage.Backup_CanteenWalkway.
  - **Lights with switches**: 17 recessed downlights + stair wall light + storage bulb on the "WALKWAY LIGHTS" switch (passage entrance), 10 hanging tube lights on the "CANOPY LIGHTS" switch (pillar by the stairs). E = on/off, R = brightness Low / Medium / High.
  - **Metal grille gate**: the space under the stairs is closed off with a black steel grille; its double gate swings open / closed with E at the lock box. New `SwingGates` script (tag `SwingGate`, leaves turn on their `Hinge` by `OpenAngle`). Inside: sawhorse table with toolbox, old wooden chair, leaning planks and plywood, blue drum, bucket and broom.
  - Stairs: white handrail and balusters on the open side and landing, wall handrail, solid cream stringer and soffit, anti-slip nosing strips; invisible rail colliders so nobody falls off.
  - Tall "This way" room directory sign (Rooms 208 Poseidon, 209 Star Class, 210 Ares / 203 Hades, 204 Zeus), WARNING video surveillance signs, CCTV domes, green electrical panel with blue conduit, brown wooden cabinet, brown tiled passage floor, potted plants, floor hatch covers, hand truck and an announcements board.

## 2026-10-24 2:19am
- COED classrooms FH 3 and FH 4 (1F, old `Classroom_1F_005` / `_006`), detailed inside and outside from a real photo. Grouped as `1F_Ground/02_Rooms/FH3_COED_Room` and `FH4_COED_Room` (Structure, Inside, Outside); originals in ServerStorage.Backup_COED_Rooms.
  - Inside: 30 armchair desks in 5 neat rows with a centre aisle, all with E "Sit" (plus the teacher's chair). Teacher's desk with laptop, books, class record and INSTRUCTOR nameplate; podium moved to the front-right so it no longer blocks the board.
  - **Sliding whiteboard with a TV behind it**: press E at the green SLIDE button — the two middle panels slide apart to show the TV (lesson slide "Principles of Teaching"), press again to cover it. Runs on the new `SlidingWhiteboards` script (tag `SlidingWhiteboard`, panels move by their `OpenOffset`).
  - 6 double-tube ceiling lights with a **light switch** inside by the door: E = on/off, R = brightness Low / Medium / High.
  - COED design: blue wainscot with white chair rail, tiled floor, drop ceiling, "College of Education" banner, Philippine flag, class schedule, classroom rules, clock, PPST 7 Domains / Bloom's Taxonomy / Code of Ethics posters, Future Educators' Corner board, Instructional Materials corner (books, globe, flash cards, abacus), flip-chart easel, split aircon, steel cabinet, BIO / NON-BIO bins, fire extinguisher, CCTV and smoke detector.
  - Outside: green projecting "FH 3" / "FH 4" signs and wall plaques, braced wooden doors (brown FH 3, dark FH 4), white steel window grilles, blue doormats, cable bundle along the wall top, ceiling bulbs, wall lamp, hanging "Please keep to the right" sign, orange PVC pipe under the awning, "No Spitting" sign on the corner pillar, emergency evacuation plan, CCTV, mop and bucket.

## 2026-10-24 1:44am
- Canteen light switch by the east door: E = turn lights on/off (bulbs go dark, green/red indicator), R = brightness Low / Medium / High. Bulbs softened (base brightness 0.55). Runs on the new `LightSwitches` script (tag `LightSwitch` + ObjectValue `Lights`), so other rooms can get switches too.

## 2026-10-24 1:35am
- Canteen (1F) rebuilt from real photos, grouped as `1F_Ground/02_Rooms/Canteen` (Details, Kitchen_Counter, Vending, Doors, Windows):
  - Dining: 9 white square tables with 36 mint-green monobloc chairs and 8 red fiberglass table-and-bench sets — 68 sit spots (E to sit). Old dark wooden table sets in ServerStorage.Backup_Canteen.
  - White walls (only the exposed wall faces), white coffered ceiling with beams and dark recessed slots, 22 ceiling bulbs, 5 ceiling-mounted oscillating fans and 4 wall fans.
  - Red "Ice Cold Drinks" fridge, two rows of blue water gallons, old CRT TV on an angle-iron bracket, yellow "Strictly no standby allowed" / "Notice" signs, wall clock, CCTV domes, BIO / NON-BIO / RECYCLE bins.
  - Counter: cream front with wood top, hanging menu board with prices, glass candy display, heated pastry display, water dispenser.
- Map teleport "Canteen (Cashier)" now drops you on the open floor inside the east door, facing the cashier (old spot put you inside the chairs). Places in `HUDConfig` can set an optional `LookAt`; `HUDServer` turns the player to face it.

## 2026-10-22 3:09pm
- Sliding windows and curtains you can use: every NB Room 1 & 2 window unit has an E prompt ("Open window"/"Close window") that slides one sash over the other; NB Room 2 curtains open to the sides and close with "Open curtains"/"Close curtains". Handled by `SlidingWindowsCurtains` (tags `SlidingWindow`, `SlidingCurtain`). An invisible safety screen stops players falling out of open windows.

## 2026-10-22 3:03pm
- NB Room 1 & 2 windows redesigned: black aluminium sliding windows (3 units × 2 sashes, latches, sills) on the corridor and back walls (`Details/Window_Corridor`, `Details/Window_Back`); old window models in the room backups. NB Room 2 curtains made solid so they show through the glass.

## 2026-10-22 2:56pm
- NB Room 2 (`2F/02_Rooms/NB_Room_2`: Structure + Details), same setup as NB Room 1 (glass-top tables, 48 sit chairs, lights, fans, boards, signs "NB ROOM 2", door glass) plus green sheer curtains and a **sliding whiteboard over the TV**: press E at the green button to slide the two whiteboard panels open (TV shows) or closed (TV covered). Old armchairs/whiteboards in ServerStorage.Backup_NBRoom2.

## 2026-10-22 2:44pm
- Student Waiting Area nook between the Records Office and Faculty Room (`2F/07_Common_Areas/Student_Nook`): black aluminium sliding window in the wall opening, green cushioned benches with 6 sit spots (E to sit), tube light, cream walls, tiled floor and step, "STUDENT WAITING AREA" sign, Core Values and Reminders posters, potted plants and a trash bin.

## 2026-10-22 2:25pm
- Sit function on every new chair (NB Room 1, SSLG Office, Records Office, Faculty Room): real Seats tagged `PromptSeat`, press E "Sit", seat faces the right way. `PromptSeats` now shows a friendly name from the `SeatName` attribute (Plastic Chair, Office Chair, Teacher's Chair).
- Explorer cleanup: rooms grouped and named by what they are.
  - 2F/02_Rooms: `NB_Room_1` (Structure + Details), `NB_Room_2`, `NB_Room_3`, `SSLG_Office`, `SHS_Records_Office`, `SHS_Faculty_Room` (Inside, Outside, Door, Windows), `Library`, `PhotoID_Studio`, `ComputerLab_1`, `ComputerLab_2`, `ScienceLab_2F`, `Room202_SHS_G11_STEM_A`, `Room204_SHS_G11_HUMSS_A`.
  - 3F/02_Rooms: `ScienceLab_3F`, `Room302_SHS_G12_TVL_ICT_A`, `Room303_SHS_G12_ABM_A`, `Room304_SHS_G11_GAS_A`, `Room305_SHS_G12_STEM_B`.
  - 2F/07_Common_Areas: `StairHall_SSLG`, `Corridor_CeilingLights`; 3F/07_Common_Areas: `Terrace_Canteen`, `StairLanding_Storage`.

## 2026-10-22 2:13pm
- NB Room 1 (`NBRoom1_2F`), rebuilt from real photos: old armchairs and whiteboards replaced (backup in ServerStorage.Backup_NBRoom1) with 12 white glass-top tables and 48 white chairs facing a wall-mounted smart TV, Vision/Mission and Goals/Objectives boards, ceiling beams, 8 tube lights, 4 ceiling-hung fans, smoke detector, CCTV, fire extinguisher, clock, cream walls and glossy tiles. Outside: cream wall, black window trim, green "NB ROOM 1" projecting signs at both doors, fire alarm bell and pull station, black doors with a horizontal glass panel.

## 2026-10-22 1:59pm
- 2nd-floor corridor: 18 tube lights along the ceiling (`Corridor_2F_CeilingLights`), one every 12 studs.

## 2026-10-21 10:27pm
- SHS Faculty Room (`FacultyRoom_SHS_2F`), from real photos. Outside: cream wall, black window frames, green curtains behind the glass, projecting "SENIOR HIGH SCHOOL FACULTY ROOM" sign, "Faculty only" plate, black grooved door with round knob. Inside: 6 teacher workstations with computers, name plates and chairs, SHS Faculty Bulletin (meeting, deadlines, advisers), learning-module shelf, steel cabinet, meeting table with monobloc chairs, stacked chairs, water dispenser, mini fridge with kettle, split aircon, clock, lights.
- Records Office and Faculty Room doors now show their black colour (union used its own wood colour before).

## 2026-10-21 9:58pm
- SHS Records Office (`RecordsOffice_SHS_2F`), from real photos. Outside: cream wall, transom window strip, "Senior High School Records Office" sign, projecting "SENIOR HIGH SCHOOL RECORD SECTION" sign, SAVE ENERGY sign and switch, SHS Enrollment tarpaulin (academic tracks + requirements), waiting chairs; black panelled door with view window, document slot, lever and deadbolt. Inside: record shelves with labelled archive boxes and folders, steel cabinets, filing cabinets, 2 staff desks with computers, printer table, visitor chair, Document Requests board, split aircon, clock, lights.

## 2026-10-21 9:48pm
- SSLG Office interior (`SSLG_Office_2F`): cream walls, tiled floor, fluorescent lights, SSLG tarpaulin, Philippine flag, conference table with monobloc chairs, officer's desk with computer, filing cabinet, bookshelf with binders and trophies, whiteboard meeting agenda, officers and announcement boards, ballot box and suggestion box, water dispenser, wall fan, clock, trash bin and plant.
- Stair hall outside: cream soffits under the stair flights and landing, wire bundle along the wall top.

## 2026-10-21 9:32pm
- Stair hall beside the SSLG office (2nd floor) detailed from a real photo: cream walls, "THIS WAY – THIRD FLOOR" sign, light switch and conduit, SSLG OFFICE plaque and notice on the door, vent blocks, CCTV dome with coiled cable, warning sign, ceiling bulb, blue drum, metal grille cabinet, old wall boards, wooden louvers above the stairs, orange PVC pipe, yellow arrows on the steps (`StairHall_2F_Details`). Roof downspout that ran in front of the door now stops at the ceiling.
- Stair railings between the flights rebuilt to follow the steps' angle and reach the bottom step / top railing.

## 2026-10-21 8:57pm
- Rooms 202, 204, 302, 303, 304, 305 changed to Senior High School classrooms: Grade 11 STEM A, HUMSS A, GAS A and Grade 12 TVL-ICT A, ABM A, STEM B — SHS subjects on the board, TV and schedules, door signs, "ADVISER" nameplate, SHS banner. Originals backed up in ServerStorage.Backup_Classrooms_PreSHS.

## 2026-10-21 8:38pm
- Cashier's Shop window now scales to fit phones and tablets (it was 600x470 and overflowed small screens) and draws above the HUD. Old InventoryGui (disabled, replaced by the Bag) also scales and no longer reacts to [I].

## 2026-10-21 8:34pm
- Phone / tablet layout pass (checked with Studio's device emulator, iPhone XR): side buttons sit near the top on phones so the thumbstick never covers Admin; coin bar shrinks on small screens; Bag / Map / Settings now draw above the coin bar (MainHUD DisplayOrder 10); hotbar uses the touch layout in the emulator too. All panels fit every device in Studio's device list (iPhone 7 up to iPad Pro 13 and Android TV).

## 2026-10-21 8:21pm
- Profile and Admin panels: the dark background now covers the whole screen (top bar, notch and screen edges), and both panels scale to fit any phone, tablet or PC screen. Profile close button shows "X".

## 2026-10-21 8:10pm
- Inventory hotbar fits every screen size (Android, iPhone, tablets, PC): scales to the screen and stays clear of the mobile thumbstick and jump button; shows "Tap to use" on touch devices.
- Inventory hotbar hides while Bag, Map, Settings, Profile, Admin or the Shop is open, and comes back when they close.

## 2026-10-21 7:28pm
- Invisible power: you now see yourself at 10% opacity on your own screen only; other players still see nothing (no avatar, name or effects). Replaces the outline highlight.

## 2026-10-21 7:15pm
- Admin powers: invisible, god mode, fly (custom speed), walk speed — instant on/off, kept through respawns (`AdminPowersClient`).
- Banned players list with Unban buttons.

## 2026-10-21 6:32pm
- Admin panel (`AdminServer` + `AdminPanelGui/AdminClient`): player search, kick, timed ban / unban, reset progress, grade promote / demote, coins, items, consumables, event counts, co-admin management, Save button.
- Level progression now uses a separate per-level quiz timer (`LevelTimeSeconds`); total play time is unchanged.
- PlayerData saves the level timer and new event counters (Common, Rare, Parkour, Escape, Photobooth).

## 2026-10-21 5:24pm
- Proximity voice chat speaking indicator (`VoiceSupport`) — removed again on request; voice uses Roblox defaults.

## 2026-10-21 1:59am
- Gate facade: gabled pediment, pilasters, arches, cornice and EXIT / ENTRANCE plaques based on the real campus front.
- Samar College seal on the gable (redrawn in green to match the official logo); `SC_LogoData` + `SC_LogoDecoder` + `SC_LogoRenderer` show the exact logo when *Allow Mesh / Image APIs* is enabled.
- ID scanner turnstiles at Entry and Exit: single passage, 2 wall-mounted ID readers, flap gate, 2 ceiling-hung monitors with a digital student ID.
- Driveway: railings, painted curbs, lane markings, speed humps, zebra crossing, ceiling and wall lights, signs.
- Main gate (double swing, prompts + control button, auto-close) and full-size Entry / Exit pedestrian gates.
- Removed a utility pole, light posts and A-frame signs blocking the road.
- Front wall raised to awning height; flat roof, then a corrugated GI metal roof with clear panels over the garden.
- Security post furnished and rearranged (CCTV wall, desks, lockers, first aid, waiting chairs, notice board, garden doorway).
- Garden with flower beds, shrubs and trees.
- San Roque Street outside the campus (shops, poles and wires, vehicles, hills).
- Profile panel with level / quiz system, achievements, level-locked shop cosmetics.
- Leaderboard *Time* and *Title* with DataStore saving; Common / Event coin counter; hotbar fixes.

## Earlier
- Classrooms, computer labs, science labs, offices, technical room, storage rooms and Photo/ID studio detailed.
- 4F rusty GI roof, 2F / 3F corridor railings and awnings, pergola.
- Inventory hotbar, shop, NPC dialogs, guard patrol, prompt-only seats.
