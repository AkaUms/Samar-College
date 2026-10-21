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
  - Owner can promote players to Co-Admin and remove them
  - Changes apply only when **Save** is pressed
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

---

## Team

**TEAM PRUC** — BSIT-4, Samar College

- Umi Ezekiel O. Bandilla
- Chris Diocton
- Philip Brian Olleta
- Rajeth Jamorawon
