# Phantom Core

High-quality custom scripts for Phantom World FiveM server with UI components, vehicle systems, player interactions, economy systems, and game mechanics.

## Features

### UI Components
- **Notifications**: Animated notification system with multiple types (info, success, warning, error, money, vehicle)
- **Progress Bars**: Circular and linear progress bars with cancellation support
- **Custom Menus**: NUI-based menu system with icons and descriptions
- **Dialog Boxes**: Input dialogs and confirmation dialogs

### Vehicle Scripts
- **Vehicle Spawner**: Category-based vehicle spawning with filtering (sports, super, sedans, SUVs, etc.)
- **Garage System**: Personal garages with impound support and vehicle storage
- **Vehicle Tuning**: Performance and visual upgrades with pricing tiers
- **Fuel System**: Enhanced fuel consumption based on RPM and speed with gas station interactions

### Player Interactions
- **Emote System**: Custom emotes with categories (greetings, dance, actions, sports, work) and favorites
- **Interaction Menu**: 3D target-based interaction for nearby players and vehicles
- **Player Actions**: Hands up, surrender, crouch, and pointing actions
- **Radio System**: Multi-channel radio with volume control and presets

### Economy Systems
- **Banking**: ATM interactions with deposit, withdraw, transfer, and transaction history
- **Shop System**: Categorized shops with cart system and tax calculation
- **Job Payouts**: Time-based job payouts with bonus multipliers
- **Tax System**: Income tax, property tax, and sales tax with automatic collection
- **Job Progression**: Rank-based job system with XP and unlockable perks

### Game Mechanics
- **Skill System**: XP-based skill leveling (strength, stamina, driving, shooting, hacking)
- **Inventory Management**: Quick sort, drop, and use functions
- **Housing System**: Property purchase with multiple tiers (apartment, house, mansion)

## Installation

1. Copy the `phantom_core` folder to your server's `resources` directory
2. Add `ensure phantom_core` to your `server.cfg` (already done)
3. Restart your server

## Configuration

Edit `shared/config.lua` to customize:
- UI settings (notifications, progress, menus)
- Vehicle settings (garage locations, fuel prices, tuning costs)
- Player settings (emotes, interactions, radio)
- Economy settings (banking, shops, jobs, taxes)
- Mechanics settings (skills, housing)

## Commands

### UI
- `/testnotifs` - Test notification system (debug mode)

### Vehicles
- `/vspawner` - Open vehicle spawner menu
- `/garage` - Open nearest garage
- `/impound` - Open impound menu
- `/tuning` - Open vehicle tuning menu

### Player
- `/pemotes` - Open emote menu
- `/interact` - Open interaction menu
- `/radio` - Open radio menu

### Economy
- `/bank` - Open banking menu
- `/shop` - Open nearest shop
- `/startjob [jobname]` - Start a job
- `/stopjob` - Stop current job
- `/tax` - Open tax menu

### Mechanics
- `/jobprogress` - View job progression
- `/skills` - View skill levels
- `/invmanage` - Open inventory management
- `/housing` - Open housing menu

## Keybinds

- **E** - Interact with nearby entities
- **X** - Clear emote / Hands up
- **K** - Surrender
- **CTRL** - Toggle crouch
- **B** - Toggle pointing
- **F1** - Toggle radio
- **Mouse Wheel** - Change radio channel

## Database Tables

The resource creates the following tables automatically:
- `phantom_skills` - Player skill levels and XP
- `phantom_housing` - Player property ownership
- `phantom_transactions` - Banking transaction history
- `phantom_purchases` - Shop purchase history

## Dependencies

- ox_lib
- qbx_core (or qb-core)
- oxmysql
- ox_inventory (for shop integration)
- illenium-appearance (for skin system)
- pma-voice (for radio integration)

## API Exports

### UI
```lua
exports['phantom_core']:SendNotification(message, type, duration)
exports['phantom_core']:ShowProgressBar(options)
exports['phantom_core']:ShowMenu(options)
exports['phantom_core']:ShowDialog(options)
```

### Vehicles
```lua
exports['phantom_core']:OpenVehicleSpawner()
exports['phantom_core']:SpawnVehicle(model, price)
exports['phantom_core']:OpenGarage()
exports['phantom_core']:OpenTuningMenu(vehicle)
```

### Player
```lua
exports['phantom_core']:PlayEmote(category, index)
exports['phantom_core']:ClearEmote()
exports['phantom_core']:ToggleHandsUp()
exports['phantom_core']:ToggleRadio()
```

### Economy
```lua
exports['phantom_core']:OpenBankingMenu()
exports['phantom_core']:OpenShopMenu(shopId)
exports['phantom_core']:StartJob(jobName)
exports['phantom_core']:GetJobProgression(jobName)
```

### Mechanics
```lua
exports['phantom_core']:AddSkillXP(skillId, xp)
exports['phantom_core']:GetSkill(skillId)
exports['phantom_core']:OpenHousingMenu()
```

## Support

For issues or questions, contact the Phantom World development team.

## Credits

Developed for Phantom World FiveM Server
Framework: QBX/QBCore
