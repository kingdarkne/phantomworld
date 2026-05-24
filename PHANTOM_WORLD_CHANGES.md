# Phantom World Server Changes - April 2026

## Overview
This document details all changes made to the Phantom World FiveM server to improve the dealership, gun stores, car customs, HUD, fines system, add a tips system, and migrate to Renzu-based systems.

---

## RENZU MIGRATION

The server has been migrated to use Renzu scripts as the primary system for spawn, multicharacter, and vehicle customs.

### Renzu Scripts Installed

#### 1. Renzu Spawn (Already Installed)
- **Location:** `resources/renzu_spawn/`
- **Purpose:** Primary spawn selector with multiple spawn locations
- **Features:**
  - 8 spawn locations: Pillbox Hospital, MRPD, Bennys, Legion Square, Job Center, City Hall, Paleto Garage, Sandy Airstrip
  - Collision load timeout protection
  - Integration with Renzu multicharacter

#### 2. Renzu Multicharacter (Already Installed)
- **Location:** `resources/renzu_multicharacter/`
- **Purpose:** Character creation and management system
- **Features:**
  - Support for 4 character slots per player (configurable)
  - Character deletion capability
  - Automatic framework detection (ESX/QBCore)
  - Skin menu compatibility (illenium-appearance, qb-clothing, fivem-appearance, skinchanger)
  - Spawn selector integration with Renzu spawn
  - Custom animations for character selection/deletion
  - Status indicators (in vehicle, is dead, premium, in jail, etc.)
  - Configurable intro camera sequence

#### 3. Renzu Customs (Newly Created)
- **Location:** `resources/renzu_customs/`
- **Purpose:** Advanced vehicle customization system
- **Files Created:**
  - `fxmanifest.lua` - Resource manifest
  - `config.lua` - Configuration with shop locations and features
  - `client.lua` - Client-side logic
  - `server.lua` - Server-side logic with database integration
  - `html/index.html` - NUI interface
  - `html/style.css` - UI styling
  - `html/script.js` - UI JavaScript

### Renzu Customs Features

#### Shop Locations (5 locations)
1. **Bennys Original Motorworks** (-205.68, -1312.12, 30.89)
2. **Los Santos Customs** (-338.72, -136.31, 38.57)
3. **LSC Airport** (-1155.53, -2013.36, 13.16)
4. **LSC Harmony** (1176.88, 2640.25, 37.75)
5. **LSC Paleto** (107.52, 6625.29, 31.79)

#### Custom Features
- **Custom Turbo Upgrades:**
  - Racing Turbo (+25% power, +20% torque)
  - Sports Turbo (+15% power, +12% torque)
  - Street Turbo (+8% power, +6% torque)
  - Custom BOV sound with server sync option

- **Custom Engine Upgrades:**
  - Stage 1 (+10% power, +8% torque)
  - Stage 2 (+20% power, +15% torque)
  - Stage 3 (+35% power, +25% torque)
  - Stage 4 (+50% power, +35% torque)

- **Custom Tire Upgrades:**
  - Drag Tires (3.0 traction, 2.5 grip)
  - Racing Tires (2.5 traction, 2.2 grip)
  - Sports Tires (2.0 traction, 1.8 grip)
  - Street Tires (1.5 traction, 1.3 grip)

- **Interactive Features:**
  - Install/uninstall vehicle mods on the go
  - Carry vehicle parts as props
  - Built-in parts inventory system
  - Stock room for available parts
  - Spray paint with custom RGB colors
  - Multiple paint types (matte, metallic, chrome)

#### Database Integration
- Custom vehicle data stored in `renzu_customs` table
- Tracks custom turbo, engine, tires, and paint per vehicle plate
- Auto-creates table on resource start

### Server.cfg Changes for Renzu Migration

#### Lines 195-201 (Renzo Systems)
```
ensure renzu_spawn
ensure renzu_multicharacter
ensure renzu_customs
stop qbx_spawn
stop qbx_apartments
stop qbx_interior
stop [qb]/qbx_customs
```

#### Lines 232-234 (Customs System)
```
# Los Santos Customs / Benny's - Using Renzu Customs instead of qbx_customs
# ensure qbx_customs
ensure renzu_customs
```

#### Line 262 (Standalone Resources)
```
ensure renzu_customs
```

### Disabled Systems
- `qbx_spawn` - Replaced by Renzu spawn
- `qbx_apartments` - Renzu handles its own housing
- `qbx_interior` - Not needed with Renzu system
- `[qb]/qbx_customs` - Replaced by Renzu customs

### Configuration Notes

#### Renzu Spawn Config
- Multicharacters: enabled
- Collision load timeout: 20000ms
- 8 spawn locations configured

#### Renzu Multicharacter Config
- Character slots: 4 per player
- Character deletion: enabled
- Spawn selector: enabled
- Framework: Auto-detects QBCore/qbx_core
- Skin support: illenium-appearance, qb-clothing, fivem-appearance, skinchanger
- Default spawn: -1037.59, -2736.90, 20.16

#### Renzu Customs Config
- MySQL: oxmysql
- Job: mechanic
- Mechanic profit share: 50%
- Repair cost: $1500
- Custom turbo: enabled
- Custom engine: enabled
- Custom tires: enabled
- Parts inventory: enabled (max 20 parts)
- Stock room: enabled (refresh every 300 seconds)
- Spray paint: enabled ($500 per use)

---

## 6. HUD System Upgrade - Renzu HUD

### New Resource Created: `resources/renzu_hud/`

### Files Created:
- `fxmanifest.lua` - Resource manifest
- `config.lua` - Configuration with HUD settings
- `client.lua` - Client-side logic
- `server.lua` - Server-side logic with police integration
- `html/index.html` - NUI interface
- `html/style.css` - UI styling
- `html/script.js` - UI JavaScript

### Features:
- **Status Bars:** Health, Armor, Hunger, Thirst, Stress, Stamina, Oxygen with customizable colors and positions
- **Money Display:** Cash, Bank, Job, Gang information
- **Vehicle HUD:** Speed (MPH/KMH), Fuel, RPM, Gear, Engine Health
- **Wanted System:** 5-star wanted level with auto-decrease and police notification
- **Location Display:** Street name, area, direction compass
- **Voice/Radio Display:** Talking indicator, radio indicator
- **Fines Display:** Shows unpaid fines count and total amount
- **Customizable Settings:** In-game settings menu (F4) to toggle HUD elements
- **Minimap:** Square or circle shape with compass and streets
- **Performance:** Optimized update rates for different HUD elements

### Commands:
- `/togglehud` (F1) - Toggle HUD visibility
- `/toggleminimap` (F2) - Toggle minimap visibility
- `/togglevehiclehud` (F3) - Toggle vehicle HUD
- `/openhudsettings` (F4) - Open HUD settings menu
- `/setwanted [playerid] [level]` - Set player wanted level (admin)
- `/clearwanted [playerid]` - Clear player wanted level (admin)

### Integration:
- **QBCore/Qbox:** Full integration with QBCore status, money, and job systems
- **Police System:** Automatic police notification when wanted level increases
- **Fines System:** Integration with dr-fines to display unpaid fines
- **Vehicle System:** Works with all vehicles including those from renzu_customs

### Server.cfg Changes:

#### Lines 210-216 (HUD Configuration)
```
# disable default ps-hud – renzu_hud replaces qbx_hud (has wanted system, vehicle info, money, fines)
stop ps-hud
stop qbx_hud
stop dr-hud
ensure XNLRankBar
ensure dr-starterpack
ensure renzu_hud
```

#### Line 263 (Standalone Resources)
```
ensure renzu_hud
```

### Disabled Systems:
- `qbx_hud` - Replaced by renzu_hud
- `dr-hud` - Replaced by renzu_hud
- `ps-hud` - Disabled for custom HUD

### Configuration Notes:
- Framework: QBCore
- Update rates: Status (100ms), Vehicle (50ms), Money (1000ms), Location (500ms), Wanted (1000ms)
- Auto-decrease wanted level: Every 60 seconds
- Police notification: Enabled when wanted level increases
- Fines update interval: Every 30 seconds

---

## 1. Car Dealership Improvements

### File Modified: `resources/qbx_vehicleshop/config/shared.lua`

### Changes Made:
- **Added New Dealership Locations:**
  - `economy` - Budget vehicles (compacts, sedans, bicycles)
  - `sports` - Sports and supercars
  - `suv` - SUVs, offroad, and vans
  - `muscle` - Muscle cars only
  - `motorcycles` - Motorcycles only

- **Reorganized Vehicle Categories:**
  - Added comprehensive vehicle categorization covering all GTA V vehicles
  - Categories include: economy, compacts, sedans, coupes, cycles, motorcycles, muscle, suvs, offroad, vans, sports, sportsclassics, super, boats, air

- **Implemented Tiered Pricing System:**
  - Economy: 50% of base price (cheapest)
  - Compacts: 60% of base price
  - Sedans: 70% of base price
  - Coupes: 80% of base price
  - Cycles: 30% of base price (bicycles)
  - Motorcycles: 90% of base price
  - Muscle: 100% of base price (standard)
  - Sports: 120% of base price
  - Sports Classics: 110% of base price
  - SUVs: 100% of base price
  - Offroad: 110% of base price
  - Vans: 80% of base price
  - Super: 200% of base price (most expensive)
  - Boats: 150% of base price
  - Air: 250% of base price (aircraft)
  - Luxury: 300% of base price (luxury/exotic)

- **Added 300+ Vehicle Models:** Organized all vehicles into appropriate categories

---

## 2. Gun Store Improvements

### File Modified: `resources/ox_inventory/data/shops.lua`

### Changes Made:
- **Expanded Ammunition Inventory:**
  - **Melee Weapons (10 items):** Knife, Bat, Nightstick, Hammer, Golf Club, Crowbar, Wrench, Hatchet, Machete, Flashlight
  - **Handguns (16 items):** Pistol, Pistol MK2, Combat Pistol, AP Pistol, Stun Gun, SNS Pistol, SNS Pistol MK2, Heavy Pistol, Vintage Pistol, Flare Gun, Marksman Pistol, Revolver, Revolver MK2, Double Action
  - **SMGs (7 items):** Micro SMG, SMG, SMG MK2, Assault SMG, Combat PDW, Machine Pistol, Mini SMG
  - **Shotguns (9 items):** Pump Shotgun, Pump Shotgun MK2, Sawoff Shotgun, Assault Shotgun, Bullpup Shotgun, Musket, Heavy Shotgun, DB Shotgun, Auto Shotgun, Combat Shotgun
  - **Assault Rifles (10 items):** Assault Rifle, Assault Rifle MK2, Carbine Rifle, Carbine Rifle MK2, Advanced Rifle, Special Carbine, Special Carbine MK2, Bullpup Rifle, Bullpup Rifle MK2, Compact Rifle
  - **Light Machine Guns (4 items):** MG, Combat MG, Combat MG MK2, Gusenberg
  - **Sniper Rifles (5 items):** Sniper Rifle, Heavy Sniper, Heavy Sniper MK2, Marksman Rifle, Marksman Rifle MK2
  - **Throwables (6 items):** Grenade, Molotov, Sticky Bomb, Proximity Mine, Smoke Grenade, Pipe Bomb
  - **Ammo (8 types):** 9mm, 45, 50, rifle, rifle2, shotgun, mg, sniper

- **Updated Pricing:** Realistic pricing based on weapon type and power
- **All weapons require weapon license and are registered**

---

## 3. Car Customs Enhancements

### File Modified: `resources/[qb]/qbx_customs/config/shared.lua`

### Changes Made:
- **Enhanced Pricing Structure:**
  - Cosmetic: $500
  - Colors: $1,500 (increased from $1,000)
  - Wheel Color: $500 (new)
  - Window Tint: $2,000 (new)
  - License Plate: $500 (new)
  - Engine: $15,000 - $55,000 (increased from $10,000 - $40,000)
  - Brakes: $5,000 - $20,000 (increased from $2,500 - $7,500)
  - Transmission: $10,000 - $50,000 (increased from $5,000 - $20,000)
  - Suspension: $5,000 - $30,000 (increased from $3,000 - $15,000)
  - Armor: $2,500 - $10,000 (new)
  - Turbo: $25,000 (increased from $10,000)
  - Xenon Lights: $1,000 - $3,000 (new)
  - Wheels: $5,000 (new)
  - Custom Wheels: $10,000 (new)
  - Bumper F/R: $7,500 each (new)
  - Skirts: $5,000 (new)
  - Exhaust: $5,000 (new)
  - Livery: $5,000 (new)
  - Plate Holder: $5,000 (new)

---

## 4. HUD Design Upgrade

### File Modified: `resources/qbx_hud/config/shared.lua`

### Changes Made:
- **Added Enhanced HUD Settings:**
  - Minimal mode toggle
  - Animated status bars
  - Circular health indicator option
  - Vehicle info display (speed, fuel)
  - Location/street display
  - Money display toggle
  - Job info display
  - Voice activity indicator
  - Talking indicator
  - Radio indicator

- **Added Color Customization:**
  - Health bar: #ff4444 (red)
  - Armor bar: #4444ff (blue)
  - Hunger bar: #ffaa44 (orange)
  - Thirst bar: #44aaff (light blue)
  - Stress bar: #ff44ff (magenta)
  - Oxygen bar: #44ff44 (green)
  - Engine health: #ffffff (white)

- **Added Position Customization:**
  - Status bars: left/right/bottom
  - Money display: top-left/top-right/bottom-left/bottom-right
  - Job display: top-left/top-right/bottom-left/bottom-right
  - Vehicle info: top-left/top-right/bottom-left/bottom-right

---

## 5. Standalone Fines System

### New Resource Created: `resources/[standalone]/dr-fines/`

### Files Created:
- `fxmanifest.lua` - Resource manifest
- `config.lua` - Configuration file with fine categories and settings
- `server.lua` - Server-side logic for fines
- `client.lua` - Client-side notifications

### Features:
- **Fine Categories (40+ types):**
  - Traffic violations (speeding, red light, reckless driving, hit and run, DUI, etc.)
  - Criminal offenses (assault, battery, theft, burglary, robbery, murder, etc.)
  - Weapon offenses (illegal possession, concealed weapon without permit, etc.)
  - Drug offenses (possession, distribution, trafficking, manufacturing)
  - Other offenses (trespassing, vandalism, fraud, impersonating officer, etc.)

- **Commands:**
  - `/getfines` - View your unpaid fines
  - `/payfine [fineid]` - Pay a specific fine
  - `/payallfines` - Pay all fines (admin)
  - `/issuefine [playerid] [finetype]` - Issue a fine (admin)
  - `/finetypes` - List all fine types (admin)

- **Features:**
  - Immediate payment discount (10%)
  - Repeat offender multiplier (50% increase)
  - Fine payment via bank or cash
  - Payment deadline system
  - Late payment interest (5% per day)
  - Database storage of all fines
  - Notifications for fine issuance and payment

### Server.cfg Addition:
```
ensure dr-fines
```

---

## 6. Tips System

### New Resource Created: `resources/[standalone]/dr-tips/`

### Files Created:
- `fxmanifest.lua` - Resource manifest
- `config.lua` - Configuration with 10 tip categories
- `server.lua` - Server-side logic for tips
- `client.lua` - Client-side display
- `html/index.html` - NUI for tip display

### Tip Categories (10 total):
1. **Gun Permit Tips** - Weapon license information, safety, legal requirements
2. **Vehicle Tips** - Parking, insurance, maintenance, driving safety
3. **Job Tips** - Job duties, advancement, workplace conduct
4. **Money Tips** - Savings, budgeting, financial management
5. **Legal Tips** - Rights, law enforcement, legal consequences
6. **Health Tips** - Medical care, first aid, wellness
7. **Social Tips** - Community interaction, respect, communication
8. **Housing Tips** - Rent, maintenance, tenant rights
9. **Business Tips** - Starting a business, management, growth
10. **Emergency Tips** - Emergency services, procedures, safety

### Commands:
- `/tip` - Show a random tip
- `/tips [category]` - Show tips for a specific category

### Features:
- Tips display on player join (configurable)
- Random tips shown periodically (every 10 minutes)
- Customizable display position (top/bottom/left/right)
- Customizable colors and styling
- Animated slide-in effect
- Auto-hide after duration
- Close button for manual dismissal

### Server.cfg Addition:
```
ensure dr-tips
```

---

## 7. Chat System

### Status: Using Existing qbx_chat_theme
The server already uses `qbx_chat_theme` which provides a modern chat UI. No changes were made as the existing system is sufficient.

---

## Server.cfg Changes

### Line 256-258:
```
ensure [standalone]
ensure dr-fines
ensure dr-tips
```

Added the two new standalone resources to the server startup configuration.

---

## Summary of Files Changed/Created for Renzu Migration

### Modified Files:
1. `D:\New folder\server.cfg` - Added renzu_customs, disabled conflicting Qbox systems

### New Files Created:
1. `D:\New folder\resources\renzu_customs\fxmanifest.lua`
2. `D:\New folder\resources\renzu_customs\config.lua`
3. `D:\New folder\resources\renzu_customs\client.lua`
4. `D:\New folder\resources\renzu_customs\server.lua`
5. `D:\New folder\resources\renzu_customs\html\index.html`
6. `D:\New folder\resources\renzu_customs\html\style.css`
7. `D:\New folder\resources\renzu_customs\html\script.js`

### Existing Renzu Scripts (No Changes):
1. `D:\New folder\resources\renzu_spawn\` - Already installed, no changes needed
2. `D:\New folder\resources\renzu_multicharacter\` - Already installed, no changes needed

### New Files Created for HUD:
8. `D:\New folder\resources\renzu_hud\fxmanifest.lua`
9. `D:\New folder\resources\renzu_hud\config.lua`
10. `D:\New folder\resources\renzu_hud\client.lua`
11. `D:\New folder\resources\renzu_hud\server.lua`
12. `D:\New folder\resources\renzu_hud\html\index.html`
13. `D:\New folder\resources\renzu_hud\html\style.css`
14. `D:\New folder\resources\renzu_hud\html\script.js`

---
1. `D:\New folder\resources\qbx_vehicleshop\config\shared.lua` - Car dealership improvements
2. `D:\New folder\resources\ox_inventory\data\shops.lua` - Gun store expansion
3. `D:\New folder\resources\[qb]\qbx_customs\config\shared.lua` - Car customs pricing
4. `D:\New folder\resources\qbx_hud\config\shared.lua` - HUD enhancements
5. `D:\New folder\server.cfg` - Added new resources

### New Files Created:
1. `D:\New folder\resources\[standalone]\dr-fines\fxmanifest.lua`
2. `D:\New folder\resources\[standalone]\dr-fines\config.lua`
3. `D:\New folder\resources\[standalone]\dr-fines\server.lua`
4. `D:\New folder\resources\[standalone]\dr-fines\client.lua`
5. `D:\New folder\resources\[standalone]\dr-tips\fxmanifest.lua`
6. `D:\New folder\resources\[standalone]\dr-tips\config.lua`
7. `D:\New folder\resources\[standalone]\dr-tips\server.lua`
8. `D:\New folder\resources\[standalone]\dr-tips\client.lua`
9. `D:\New folder\resources\[standalone]\dr-tips\html\index.html`
10. `D:\New folder\PHANTOM_WORLD_CHANGES.md` - This documentation

---

## No Files Deleted or Moved

As requested, no existing files were deleted or moved. All changes were additive or modifications to existing files.

---

## Testing Recommendations

1. **Car Dealership:**
   - Test each new dealership location
   - Verify vehicle categories display correctly
   - Check tiered pricing calculations
   - Test vehicle spawning and purchasing

2. **Gun Stores:**
   - Verify all weapons appear in Ammunation
   - Test weapon purchasing with licenses
   - Check ammo pricing
   - Verify weapon registration

3. **Car Customs:**
   - Test all new mod categories
   - Verify pricing for each upgrade level
   - Test mod application

4. **HUD:**
   - Verify all HUD elements display correctly
   - Test color customization
   - Test position customization
   - Verify vehicle info display

5. **Fines System:**
   - Test fine issuance commands
   - Test fine payment commands
   - Verify database storage
   - Test notifications
   - Check discount and multiplier calculations

6. **Tips System:**
   - Verify tips display on join
   - Test random tip command
   - Test category-specific tips
   - Verify NUI display
   - Test positioning and styling

---

## Notes

- All scripts use QBX/QBCore framework compatibility
- Database tables are auto-created on resource start
- No external dependencies were added
- All changes are backwards compatible with existing data
- The server uses ox_lib for UI interactions
- All new resources are standalone and can be independently enabled/disabled

---

## Contact

For questions or issues with these changes, contact the server administration team.
