# Oxo Admin (`norse_awsome_admins`)
A modern FiveM admin panel for ESX / QBcore / QBOX with a clean NUI, roles system, and deep integration with bans and prison (via `tk_jail`).


## Norse Development Links:
Norse Dev Store:   https://norse-development.tebex.io/
Norse Dev YouTube: https://www.youtube.com/@Norse-Dev
Norse Dev Discord: https://discord.gg/j5EsFMeZrJ

#Admin
add_ace group.admin oxoadmin.menu allow
add_ace group.admin oxoadmin.self allow
add_ace group.admin oxoadmin.player allow
add_ace group.admin oxoadmin.server allow
add_ace group.admin oxoadmin.vehicle allow
add_ace group.admin oxoadmin.zones allow
add_ace group.admin oxoadmin.bans allow
add_ace group.admin oxoadmin.dev allow
add_ace group.superadmin oxoadmin.console allow
add_ace group.superadmin oxoadmin.code allow
add_ace group.admin oxoadmin.roles allow

## Features

- **Framework support**
  - ESX, QBcore, QBOX, or standalone (`Config.Framework`)
- **Admin UI (F12)**
  - Self tools: heal, revive, noclip, god mode, invisibility, staff name/RP name, staff duty, skin/ped
  - Player moderation: kick, ban, prison ban (tk_jail auto-jail), heal/revive/kill, bring, goto, spectate, freeze, noclip, god mode, invisibility
  - Economy & inventory: give/remove money, clear inventory (with logging), open inventory (ox_inventory), give items
  - Appearance: open skin menu / Oxo Ped Shop
  - Communication: private messages, warning messages (with logging)
  - Job management: set player job + grade (ESX/QB/QBOX)
- **Server tools**
  - Cleanup world (vehicles, peds, objects, or all)
  - Weather control (Renewed-Weathersync + ox_lib)
  - Announcements (qs-announce)
- **Vehicle tools**
  - Spawn vehicle, repair, delete closest, max mods, max fuel, plate & color tools, torque multiplier
  - View / manage player owned vehicles (ESX `owned_vehicles`)
- **Mob hit system**
  - Staff-triggered troll action **and** safe server-to-server hook for revenge orders coming from Ono Hitman Contracts / Ono Menu
  - Differentiates between staff "troll" usage and revenge-driven orders so notifications, logging, and permissions stay accurate
- **Zones system**
  - Create/edit zones at your position: safe, speed, restricted, or custom
  - Effects: invincible, disarm, speed limit, job-restricted access, schedule (hours), blip icon/color
- **Bans & prison-bans**
  - SQL-backed bans table (`oxoadmin_bans`) with in-memory JSON fallback
  - Prison bans integrated with `tk_jail` (default) or `rcore_prison`:
    - On prison ban: calls `exports['tk_jail']:jail(player, minutes)` and resets movement
    - On prison-ban *pardon*: unjails online players and clears ESX `users` jail fields so they are not re-jailed
  - Per-player ban history and server-wide lists
- **Staff & roles**
  - Custom roles with granular permissions (Self/Player/Server/Vehicle/Dev/Zones/Bans/Console/Code)
  - Staff metadata: country + DOB/age
  - Staff history: bans and actions taken
- **Duty tracking & focus**
  - Tracks total duty time per staff member in SQL (`oxoadmin_staffduty`) with JSON fallback
  - Off-duty "Duty focus" card showing Today / Last 7 days / Last 30 days
  - Monthly requirement with progress bar and detailed Last 30 days pill
  - 30-day activity graph of on-duty hours with average line and per-day columns
- **Dev & console**
  - Mini panel (F11) for quick tools
  - Raycast dev tools (copy vec3/vec4, delete entity)
  - Live console runner and Lua code runner (sandboxed)

## Installation

1. **Dependencies** (recommended)
   - **Database**: `oxmysql`
   - **Framework**: `es_extended` (ESX) or `qb-core` or `qbx_core`
   - **Inventory**: `ox_inventory` (default) or ESX inventory
   - **Clothing/Skin**: `rcore_clothing` (default), or `esx_skin` / `qb-clothing` / `fivem-appearance`
   - **Jail**: `tk_jail` (default) or `rcore_prison` (optional) for prison bans
   - **Weather & UI**:
     - `ox_lib` (for `lib.notify` and Renewed-Weathersync callback)
     - `Renewed-Weathersync` (optional, for server weather control)
   - **Announcements**: `qs-announce` (for server-wide announcements)
   - **Name tags** (optional): a resource that listens to `oxoadmin:setStaffTag` and `oxoadmin:setCustomName` (e.g. NameAbovePlayer)

2. **Place the resource**

   - Drop `norse_awsome_admins` into your server's `resources` folder.
   - Ensure `tk_jail` and all dependencies are also in `resources`.

3. **Start order (example)**

   ```cfg
   ensure oxmysql
   ensure ox_lib
   ensure es_extended       # or qb-core / qbx_core
   ensure ox_inventory      # if you use it
   ensure rcore_clothing    # or your clothing resource
   ensure tk_jail
   # or: ensure rcore_prison
   ensure qs-announce
   ensure Renewed-Weathersync

   ensure norse_awsome_admins
   ```

4. **Database**

   - On first run, Oxo Admin will create its SQL tables if they do not exist:
     - `oxoadmin_bans`  (bans + prison bans)
     - `oxoadmin_names` (FX and RP name history)
     - `oxoadmin_staffmeta` (staff metadata)
   - Prison-ban integration with `tk_jail` expects the ESX `users` table to have jail columns (`jail_time`, `jail_type`, `jail_cell`, `jail_cell_items`) as in tk_jail's SQL.

## Configuration

Open `config.lua`:

- `Config.Framework` – set to `'esx'`, `'qbcore'`, `'qbox'`, or `'auto'`.
- `Config.Inventory` – `'ox_inventory'` (default) or `'esx'` for ESX inventory.
- `Config.Skin` – skin/clothing menu backend used by `/skin` and the UI Skin button:
  - `'rcore_clothing'` (default)
  - `'esx_skin'`
  - `'qb-clothing'`
  - `'fivem-appearance'`
- `Config.VehicleKeys` – vehicle keys backend (lock/unlock integration):
  - Currently only `'none'` is supported (no external keys resources are called yet).
- `Config.Fuel` – fuel system integration for Vehicle → **Max Fuel**:
  - `'lyre_fuel'` (Lyre Scripts Fuel; uses `exports['lyre_fuel']:SetFuel`)
  - `'lc_fuel'` (legacy support via `exports['lc_fuel']:SetFuel`)
  - Anything else falls back to native `SetVehicleFuelLevel`.
- `Config.StressBackend` – backend used when clicking the **Stress** button in Self tab (`'auto'`, `'esx'`, `'qb'`, `'jg'`, `'none'`).
- `Config.PrisonBackend` – jail backend used for **Prison Bans** (`'tk_jail'` or `'rcore_prison'`).
- `Config.Commands` – chat commands:
  - `/admin` (open menu)
  - `/ban`, `/kick`, `/noclip`, `/clearinv`, `/skin` (if enabled and allowed by permissions)
- `Config.Log` – if `true`, prints basic log lines to server console.
- `Config.WorldDensity` – default vehicle/ped density values used by the **Density** slider in the Server tab.
- `Config.Duty` – staff duty configuration:
  - Pay while on duty (interval, amount, per-role overrides, target account)
  - Monthly requirement window (`RequirementSecondsLast30`) used by the Duty focus UI
  - Inactivity timeout and periodic requirement checks
- `Config.MobHit` – settings for the **Mob Hit** troll event and `/mobhit` command (allowed job, reward amount/account, ped/vehicle pools).
  - Requests flagged with `fromMobCommand = true` (sent by Ono Hitman Contracts) bypass staff-duty logging but still run through the same spawn logic.

### Permissions model

Permissions are controlled in `Config.Perms`:

- **Base categories**: `MenuOpen`, `Self`, `Player`, `Server`, `Vehicle`, `Dev`, `Zones`, `Bans`, `Console`, `Code`, `Roles`.
- **Fine-grained Self**: `SelfHeal`, `SelfRevive`, `SelfNoclip`, `SelfInvincible`, `SelfInvisible`, `SelfAmmo`, `SelfArmor`, `SelfStress`, `SelfSuperjump`, `SelfRunFast2x`, `SelfSkin`, `SelfPed`, `SelfDuty`, `SelfStaffName`, `SelfRpName`.
- **Fine-grained Player** (examples):
  - `PlayerKick`, `PlayerBan`, `PlayerPrisonBan`
  - `PlayerHeal`, `PlayerRevive`, `PlayerKill`
  - `PlayerBring`, `PlayerGoto`, `PlayerSpectate`
  - `PlayerFreeze`, `PlayerUnfreeze`, `PlayerNoclip`, `PlayerInvincible`, `PlayerInvisible`
  - `PlayerClearInv`, `PlayerMoney`, `PlayerGiveItem`, `PlayerSkin`, `PlayerOpenInv`
  - **New**: `PlayerWarn`, `PlayerMessage`, `PlayerSetJob`
- **Server**: `ServerCleanup`, `ServerWeather`, `ServerAnnounce`, `ServerChaos`, `ServerDensity`.
- **Vehicle**: `VehicleSpawn`, `VehicleRepair`, `VehicleDeleteClosest`, `VehicleMaxMods`, `VehicleMaxFuel`, `VehiclePlate`, `VehicleColor`, `VehicleLock`, `VehicleUnlock`, `VehicleTorque`.
- **Commands**: `CmdBan`, `CmdKick`, `CmdNoclip`, `CmdClearInv`, `CmdSkin`, `CmdMobhit`.

Each permission maps to:

- An ACE (e.g. `oxoadmin.player`).
- One or more framework groups (`Config.ESXGroups`, `Config.QBGroups`, `Config.QBOXGroups`).

You can:

- Grant ACEs in `server.cfg` (for standalone/admins without framework groups).
- Or use the in-game **Roles** tab to define custom roles and assign permissions via the `allPerms` list in the UI.

## Controls

- **Open full admin menu**: key mapping `oxoadmin:toggle` (default `F12`).
- **Open mini panel**: key mapping `oxoadmin:mini` (default `F11`).
- Close menus with `ESC` or close buttons.

## Prison-ban integration

- When you apply a **Prison Ban** from the Players tab:
  - Oxo Admin calculates a sentence length (minutes) based on offences and previous prison bans.
  - Adds an entry to `oxoadmin_bans` (type `prison`).
  - Calls the configured backend (see `Config.PrisonBackend`):
    - `tk_jail`: `exports['tk_jail']:jail(playerId, minutes)`
    - `rcore_prison`: `exports['rcore_prison']:Jail(playerId, minutes, reason, officerId)`
  - Resets the player's movement to avoid crawl animations.

- When you **pardon** a prison ban:
  - Removes the entry from ban storage.
  - If using `tk_jail`:
    - Unjails any *online* player with that license via `/unjail`.
    - On ESX, also clears jail state in the `users` table so the player is not teleported back to prison on rejoin.
  - If using `rcore_prison`:
    - Unjails matching *online* players via `exports['rcore_prison']:Unjail(playerId, false)`.
    - Attempts an offline unjail via `exports['rcore_prison']:UnjailOffline(identifier)`.

> Note: The `tk_jail` resource itself is not modified; Oxo Admin only calls its exports/commands and updates DB state where necessary.

## New moderation features

### Kill player

- Available in Players tab → **Health** section.
- Requires `PlayerKill` permission.
- Immediately sets the target player's health to 0 and logs the action.

### Private message

- Available in Players tab → **Communication**.
- Input a short text and click **Send PM**.
- Requires `PlayerMessage` permission.
- Sends a client-side notification via `oxoadmin:notify` (uses `ox_lib` notify when available).

### Warn player

- Available in Players tab → **Communication**.
- Input a short warning message and click **Warn**.
- Requires `PlayerWarn` permission.
- Shows a warning-style notification and logs the warning in actions history.

### Set player job

- Available in Players tab → **Job**.
- Enter `job` name and `grade`.
- Requires `PlayerSetJob` permission.
- Calls framework-specific job setters:
  - ESX: `xPlayer.setJob(job, grade)`.
  - QBcore/QBOX: `player.Functions.SetJob(job, grade)`.

### Duty tracking & Duty focus UI

- Oxo Admin tracks duty time per staff member:
  - SQL table `oxoadmin_staffduty` for total duty seconds + last on/off timestamps.
  - JSON `duty_history.json` (configurable via `Config.DutyHistoryFile` in code) for individual duty shifts used by the 30-day graph.
- When you go **off duty**, the Self tab shows a Duty focus card:
  - Hero pill with **Last 7 days** and **Lifetime** duty.
  - Detailed **Last 30 days** pill containing:
    - Inner header pill: `LAST 30 DAYS` and `X h / Y h` (actual vs monthly target).
    - Monthly target line: `Monthly target: 12.0 h • 1363% • avg 5.45 h/day • 152 h over` (values are dynamic).
    - Compact progress bar capped at 100% and color-shifted when you exceed the target.
  - 30-day activity graph rendered above the header:
    - One hollow column per day (zero days still show a tiny bar).
    - Dashed average line with label + numeric average hours per day.
    - Horizontal axis labelled `Days`, vertical axis labelled `Hours`.
- The monthly target and UI behaviour are driven by `Config.Duty.RequirementSecondsLast30` and other `Config.Duty` fields.
- Development helper: from server console you can seed 30 days of sample duty history for testing the graph:
  - `oxoseed30duty license:xxxxxxxx` (or run as a player to seed your own license).

#### Quick start: Duty Focus testing

1. **Set the monthly requirement**
   - In `config.lua`, adjust:
     - `Config.Duty.RequirementSecondsLast30 = 12*3600` (example: 12 hours).
   - Restart the resource so the change is picked up.

2. **Seed 30 days of duty history for a staff member**
   - From the **server console**, run:
     - `oxoseed30duty license:your_license_here`
   - Or, as a player in game (with `MenuOpen` permission), run `oxoseed30duty` with no args to seed **your own** license.
   - This writes 30 synthetic shifts into `duty_history.json` for testing the graph and stats.

3. **Test the Duty focus UI**
   - Join the server as that staff member.
   - Go **on duty** using the Self tab (Toggle Duty), then go **off duty** again.
   - Open the full admin menu (default `F12`) → Self tab:
     - You should see the off-duty Duty focus card with:
       - Last 7 days / Lifetime pill.
       - Last 30 days pill with header, monthly target line, and progress bar.
       - The 30-day activity graph overlay above the header.

4. **Tune the visuals / target**
   - Adjust `RequirementSecondsLast30` until the target feels right for your staff.
   - Optionally clear or edit `duty_history.json` and the `oxoadmin_staffduty` table when moving from test data to live usage.

### Mob Hit (troll event)

- New troll action in the Players tab: **Mob Hit**.
  - Spawns hostile NPCs to attack the target player.
  - When the target survives, they can receive a configurable reward and a message.
- Controlled by permissions:
  - UI button: `PlayerTroll` / `PlayerTrollMobhit`.
  - Chat command: `CmdMobhit` (for `/mobhit`).
- Configured via `Config.MobHit` in `config.lua`:
  - `Command` – chat command name (default `mobhit`).
  - `AllowedJob` – restricts use to a specific job (e.g. `police`).
  - `RewardAmount` / `RewardAccount` – payout to the survivor.
  - `MobPeds` / `MobVehicles` / `MobSettings` – NPC and vehicle pools + behaviour.
- Hitman/Menu revenge flow:
  - Ono Hitman Contracts calls `TriggerEvent('oxoadmin:player', { id = targetId, a = 'troll_mobhit', fromMobCommand = true, mobhitFromName = sourceName })`.
  - Requests marked with `fromMobCommand = true` bypass staff-duty logging and permission checks but still reuse the exact same spawn logic and survivor rewards.
  - Notifications automatically mention whether the hit was sent "as part of a Revenge contract" (from Hitman/Menu) or "as part of a Troll action" (staff UI).
  - Ensure norse_awsome_admins is running **before** Ono_Hitman_Contracts so the server event is available when the menu dispatches a mob hit.
  - Recommended test: police player with revenge selects a target in Ono Menu → Info → Revenge → "Call Mob Hit". Watch the admin console for `fromMobCommand=true` log and confirm NPCs spawn + survivor reward occurs.

## UI enhancements

- The main tabs and key action buttons now use Font Awesome icons (via CDN) alongside text labels for clearer navigation:
  - Tabs: Self, Players, Server, Vehicles, Zones, Bans, Staff, Roles, Dev, Console, Code.
  - Key moderation actions: Kick, Ban, Prison Ban, Heal, Revive, Kill.
  - Communication: Send PM, Warn.
  - Job: Set Job.
  - Server: Weather Set, Announce Send.
  - Vehicles: Spawn.

You can adjust icons or remove the Font Awesome `<link>` tag in `html/index.html` if you prefer a text-only look.

## Known integration points

- **ox_lib**: Used for notify popups and Renewed-Weathersync server callback. If missing, the script falls back to basic GTA notifications and logs errors.
- **Renewed-Weathersync**: Weather change requests are proxied through the admin's client to this resource.
- **qs-announce**: Server announcements are forwarded to its UI.
- **NameAbovePlayer** (or similar): Listens to `oxoadmin:setStaffTag` and `oxoadmin:setCustomName` events to render staff/RP names.

## Troubleshooting

- If the menu does not open:
  - Check that your identifier/group has `MenuOpen` permission (via ACE, framework group, or a role in the Roles tab).
  - Ensure the resource is started *after* your framework and `ox_lib`.
- If bans or zones do not persist:
  - Confirm `oxmysql` is configured and connected.
  - If running without SQL, JSON fallbacks (`bans.json`, `prison_bans.json`, `zones.json`, `roles.json`, `actions.json`) must be writable.
- If prison bans do not move players into jail:
  - Verify the selected backend in `Config.PrisonBackend` is started (`tk_jail` or `rcore_prison`).
  - Check server console for `[OXO-ADMIN] tk_jail jail export error` or `[OXO-ADMIN] rcore_prison Jail export error`.

## License / Credits

- Oxo Admin created for OxoCodes servers.
- Integrations and naming are compatible with common FiveM ecosystems (ESX/QB/QBOX, ox_lib, ox_inventory, tk_jail, qs-announce, Renewed-Weathersync).
- Adjust and extend to fit your server's needs.
