# Samar College — Roblox Virtual Campus

**Store Servers Description:** A Roblox-Based Social Virtual World with Server Category Selection Based on Users' Year Level.

A virtual recreation of **Samar College, Catbalogan City, Samar** built in Roblox Studio as a BSIT-4 capstone project.
Players explore the campus, earn titles by moving up school levels (Kindergarten → 4th Year College),
shop with campus coins, and meet other students in servers grouped by year level.

> Studio place: **Samar College [Recreate]** (Place ID `79009725969202`)

---

## Progress

### Campus build
- [x] 4-storey main building rebuilt and grouped **by floor → room type** (`1F_Ground`, `2F`, `3F`, `4F`)
- [x] Classrooms (2F and 3F) with boards, armchairs, ceiling fans and lights
- [x] Computer laboratories with working-style PCs and seats
- [x] Science laboratories (2F and 3F) with lab tables, sinks, cabinets and equipment
- [x] Offices on the 3F terrace, Technical Room + storage, Photo/ID studio, stair-landing storage
- [x] Rusty GI roof on the 4th floor; 2F and 3F corridors with white railings and green awnings
- [x] **San Roque Street** outside the campus: road markings, shops across the street, utility poles and wires, parked tricycles and vehicles, hills in the background
- [x] **Gate facade** modelled on the real school: salmon gabled pediment with the **Samar College seal**, pilasters, arches, cornice, "EXIT" / "ENTRANCE" plaques
- [x] Front wall raised to awning height with a **corrugated GI metal roof** (clear panels over the garden)
- [x] **Security post**: CCTV monitor wall, computer desk, check-in standing desk, staff lockers, first-aid station, visitor chairs, notice board, key cabinet
- [x] **Garden** behind the front wall with flower beds, shrubs and trees
- [x] **Driveway** under the building: railings, painted curbs, IN/OUT lane markings, speed humps, zebra crossing, ceiling and wall lights
- [x] **Medical and Dental Clinic** (1F): clinic sign, posters and grille outside; nurse's desk, waiting bench, examination couch, dental chair, ward beds with curtains, 15 E seats and an on / off light switch inside

### Gameplay systems
- [x] **Main gate** — double swing gate, open/close with `E` (both sides) or the control button; auto-closes after 20 s
- [x] **Entry / Exit pedestrian gates** — full door-size swing gates, auto-close after 10 s
- [x] **ID scanner turnstiles** (Entry and Exit) — 2 wall-mounted ID readers each, flap gate, 2 ceiling monitors showing *ACCESS GRANTED* and a digital student ID (avatar, name, level title, time on campus)
- [x] **CCTV** — 7 cameras with blinking REC lights and an animated monitor wall
- [x] **School levels & titles** — 17 levels in 3 departments (Elementary, High School, College); unlock by play time + passing a 5-question quiz (4/5 to pass)
- [x] **Profile panel** — current title, level chips, next-level progress, student record, achievements
- [x] **Leaderboard** — *Time* (total time on campus) and *Title*
- [x] **Coins** — Common and Event coins with an on-screen counter
- [x] **Shop & inventory** — Cosmetic / Equipment / Consumable items, some locked behind school level
- [x] **Hotbar** inventory at the bottom of the screen
- [x] **Saving** — play time, level, coins and items saved with DataStore (`PlayerData`)
- [x] **Seats** use an `E` "Sit" prompt (no accidental sitting) via the `PromptSeat` tag
- [x] **NPCs** — patrolling guards, cashier, teacher with dialog
- [x] **Proximity voice chat** (mic on/off through Roblox settings)
- [x] **Map** — tap a pin to teleport to campus places
- [x] **Settings** — Elementary / Junior High+ server choice, music and sound-effect volume
- [x] Day / night cycle, ceiling fans that spin
- [x] **Admin panel** (`F2` or the 🛡 Admin button, owner + co-admins only)
  - Find players by username, user ID, or from the in-server list (online or offline)
  - Kick, timed ban (seconds / minutes / hours / days) and unban — works across servers
  - Reset progress, promote / demote grade level (restarts the quiz timer)
  - Edit Common / Event coins, add / remove cosmetics and equipment, set consumable amounts
  - Edit Common / Rare / Quiz / Parkour / Escape / Photobooth event counts
  - **Powers** (instant on/off, players in the server): invisible, god mode, fly (with speed), walk speed
  - **Banned players** list with one-click Unban
  - Owner can promote players to Co-Admin and remove them
  - Changes apply only when **Save** is pressed
  - **📋 Player Records**: who is online in every server (server IDs, minimize / maximize, Join server), every player's progress by user ID, and time in / time out logs (Go to, Join, Log, Manage)
  - **🚩 Reports**: players' reports with a status for each — Waiting for review → Investigating (by which admin) → Done (checked by which admin, result and proof); notices to all admins
- [x] **🚩 Report a player** — every player can report someone in their server for breaking the rules (reason + details, text filtered, cooldowns)
- [x] **Separate quiz timer** — total time stays on the leaderboard; a per-level timer unlocks the next quiz and restarts after each level change

### Planned / to do
- [ ] Publish the separate **Elementary server** place and set `ElementaryPlaceId` in `HUDConfig` (the Settings switch and teleport code are ready)
- [ ] Loading screen with tips
- [ ] More school events for Event coins

See [CHANGELOG.md](CHANGELOG.md) for the dated history.

---

## Repository layout

```
src/
  server/   -> ServerScriptService   (synced by Rojo)
  shared/   -> ReplicatedStorage     (synced by Rojo)
  client/   -> StarterPlayerScripts  (synced by Rojo)
place-scripts/   reference copies of scripts that live inside GUIs or models
                 (StarterGui, Workspace, Tools) — NOT synced, they stay in the place file
```

File naming follows Rojo: `*.server.luau` = Script, `*.client.luau` = LocalScript, `*.luau` = ModuleScript.

## Working with Rojo

The project uses [Rojo](https://rojo.space) (`aftman.toml` pins `rojo 7.7.0`).

```bash
aftman install
rojo serve
```

Then connect from the Rojo plugin in Roblox Studio.
Every synced service has `ignoreUnknownInstances` turned on, so Rojo **only updates the scripts in this repo** and never deletes the parts, models or GUIs that were built in Studio.

## Studio settings the game needs

| Setting | Where | Why |
|---|---|---|
| Enable Studio Access to API Services | Game Settings → Security | DataStore saving while testing in Studio |
| Allow Mesh / Image APIs | Game Settings → Security | Draws the official logo on the gate seal (`SC_LogoRenderer`) |
| Microphone | Game Settings → Communication | Proximity voice chat |

## Where player data is kept

All of it is in Roblox's cloud for this experience (Creator Hub → Samar College [Recreate] → Configurations → **Data stores manager**), and in-game in the admin panel's **📋 Player Records**.

| Store | Type | Key | What |
|---|---|---|---|
| `SamarCollege_PlayerData_v1` | DataStore | `u_<UserId>` | Progress: time, level, title, coins, items, event counts |
| `SamarCollege_Sessions_v1` | DataStore | `u_<UserId>` | Name, first join, last time in / out, joins, progress summary, last 40 visits (time in, time out, server) |
| `SamarCollege_LastSeen_v1` | OrderedDataStore | `<UserId>` | Last time seen (unix time), for the All players list |
| `SamarCollege_PlayTime_v1` | OrderedDataStore | `<UserId>` | Total seconds played, for "Most time played" |
| `SamarCollege_Admins_v1` / `SamarCollege_Bans_v1` | DataStore | `coadmins` / `b_<UserId>` | Co-admins and bans |
| `SamarCollege_Reports_v1` | DataStore | `r_<time>_<ReporterId>` / `t_<UserId>` | Player reports (reason, details, status, who investigated / checked it, result, proof, history) / report ids about one player |
| `SamarCollege_ReportsWaiting_v1` / `…Checking_v1` / `…Done_v1` / `…All_v1` | OrderedDataStore | report id | Report lists by status, newest first |
| `SC_Online_v1` / `SC_Servers_v1` / `SC_Sessions_v1` | MemoryStore sorted maps | `<UserId>` / `<JobId>` / time + UserId | Live: who is online and where, running servers, recent time in / out (clears itself) |

---

## Team

**TEAM PRUC** — BSIT-4, Samar College

- Umi Ezekiel O. Bandilla
- Chris Diocton
- Philip Brian Olleta
- Rajeth Jamorawon
