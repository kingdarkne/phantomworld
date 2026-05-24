# Isolation System for norse_awsome_admins

## Overview
The isolation system allows staff to send misbehaving prisoners to solitary confinement as a disciplinary measure. Isolation is separate from regular prison sentences and escalates with each offense.

## Features
- **Automatic Time Calculation**: 1st offense = 1 hour, 2nd = 2 hours, 3rd = 3 hours, then +1 hour per offense
- **Prison Sentence Pausing**: When a player is sent to isolation, their prison sentence is paused and resumes when they're released
- **Dedicated Isolation Cells**: 8 isolation cell locations configured at Bolingbroke Prison
- **Chat Restrictions**: Players in isolation or prison cannot use text chat
- **Permission-Based**: Two new permissions control isolation access

## Database Setup
Run the SQL migration to create the isolation tracking table:
```sql
-- File: sql/isolation.sql
CREATE TABLE IF NOT EXISTS `oxoadmin_isolation` (
  `id`                INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `identifier`        VARCHAR(64)  NOT NULL,
  `name`              VARCHAR(64)  NOT NULL,
  `offense_count`     INT UNSIGNED NOT NULL DEFAULT 0,
  `isolation_minutes` INT UNSIGNED NOT NULL,
  `started`           INT UNSIGNED NOT NULL,
  `expires`           INT UNSIGNED NOT NULL,
  `paused_jail_time`  INT UNSIGNED DEFAULT NULL,
  `staff`             VARCHAR(64)  NOT NULL,
  `active`            TINYINT(1)   NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `idx_identifier_active` (`identifier`,`active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

## Configuration
Located in `config/config.lua`:

```lua
Config.Isolation = {
    Enabled = true,
    Cells = {
        vec4(1691.90, 2542.43, 45.63, 0.0),
        vec4(1691.45, 2545.59, 45.63, 0.0),
        vec4(1691.35, 2549.03, 45.63, 0.0),
        vec4(1692.18, 2552.40, 45.63, 0.0),
        vec4(1691.82, 2555.96, 45.63, 0.0),
        vec4(1651.22, 2571.32, 45.56, 0.0),
        vec4(1641.88, 2569.88, 45.56, 0.0),
        vec4(1629.34, 2570.39, 45.56, 0.0)
    },
    BaseMinutes = {
        [1] = 60,  -- 1st offense: 1 hour
        [2] = 120, -- 2nd offense: 2 hours
        [3] = 180  -- 3rd offense: 3 hours
    },
    IncrementMinutes = 60, -- 4th+ offenses: 3 hours + (count-3)*60
    PauseJailSentence = true -- Pause regular prison time during isolation
}
```

## Permissions
Two new permissions have been added:

### PlayerIsolation
- **Description**: Send to Isolation
- **Usage**: Allows staff to send players to isolation cells
- **Default**: Admin role

### PlayerIsolationPardon
- **Description**: Pardon Isolation
- **Usage**: Allows staff to release players from isolation back to prison
- **Default**: Admin role

Configure these in the Roles tab of the admin panel.

## Usage

### Sending a Player to Isolation
1. Open the admin panel
2. Navigate to the Players tab
3. Select the target player
4. In the Moderation section, click **"Send to Isolation"**
5. The player will be:
   - Teleported to a random isolation cell
   - Given isolation time based on their offense count
   - Have their prison sentence paused (if applicable)
   - Unable to use text chat

### Pardoning from Isolation
1. Select the player currently in isolation
2. Click **"Pardon Isolation"**
3. The player will be:
   - Released from isolation
   - Returned to their regular prison sentence
   - Teleported back to general prison population
   - Able to use chat again (once released from prison)

## How It Works

### Isolation Time Calculation
- **1st offense**: 60 minutes (1 hour)
- **2nd offense**: 120 minutes (2 hours)
- **3rd offense**: 180 minutes (3 hours)
- **4th offense**: 240 minutes (4 hours)
- **5th offense**: 300 minutes (5 hours)
- And so on...

### Prison Sentence Management
When `PauseJailSentence = true`:
1. Player's current prison time is saved to the database
2. Prison time is set to a high value (999999) to prevent automatic release
3. Upon isolation pardon, the original prison time is restored
4. The player continues their prison sentence from where it was paused

### Chat Blocking
- Players in **prison** cannot use text chat
- Players in **isolation** cannot use text chat
- System messages inform the player why their chat was blocked
- Chat blocking is automatic and requires no additional configuration

## Integration with tk_jail
The isolation system integrates seamlessly with the tk_jail prison resource:
- Uses tk_jail's teleport system for moving players
- Reads/writes prison time from tk_jail's database tables
- Compatible with both ESX and QBCore frameworks
- No modifications to tk_jail required

## Troubleshooting

### Players not teleporting to isolation
- Verify tk_jail resource is running
- Check that isolation cell coordinates are correct
- Ensure `Config.Isolation.Enabled = true`

### Prison time not pausing
- Verify database columns exist (run isolation.sql)
- Check `Config.PauseJailSentence = true`
- Ensure proper framework detection (ESX/QBCore)

### Chat still working for prisoners
- Verify the chatMessage event handler is loading
- Check that Config.Isolation.Enabled = true
- Test with a clean cache/restart

## Technical Details

### Database Tables
- **oxoadmin_isolation**: Tracks all isolation records
- **users** (ESX) or **players** (QBCore): Contains jail_time column

### Events
- **oxoadmin:player** (a='isolation'): Triggers isolation
- **oxoadmin:player** (a='isolationPardon'): Pardons isolation
- **tk_jail:forceTeleport**: Teleports player to cell
- **chatMessage**: Intercepts and blocks chat messages

### Server Functions
- `getIsolationOffenseCount()`: Counts previous isolation records
- `calcIsolationMinutes()`: Calculates time based on offense count
- `teleportToIsolationCell()`: Random cell selection and teleport
- `pauseJailSentence()`: Saves and pauses prison time
- `resumeJailSentence()`: Restores prison time
- `addIsolation()`: Creates isolation record
- `pardonIsolation()`: Releases from isolation

## Notes
- Isolation cells are randomly selected to prevent predictability
- All isolation actions are logged to the admin action log
- Server-wide announcements are made when players enter/exit isolation
- The system is framework-agnostic (ESX/QBCore/QBOX compatible)
