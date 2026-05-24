# Phantom World Server - Upload Guide

## Complete List of Changes for Host Upload

This document lists ALL files that were modified or created for your FiveM server. Upload these files to your host.

---

## FILES TO UPLOAD

### Modified Files (5 files)

1. **D:\New folder\server.cfg**
   - Added renzu_customs, renzu_hud, dr-fines, dr-tips
   - Disabled qbx_hud, dr-hud, qbx_spawn, qbx_apartments, qbx_interior, [qb]/qbx_customs
   - **CRITICAL - Upload this file**

2. **D:\New folder\resources\qbx_vehicleshop\config\shared.lua**
   - Added 5 new dealership locations (economy, sports, suv, muscle, motorcycles)
   - Reorganized 300+ vehicles by category
   - Added tiered pricing system (30%-300% of base price)
   - **Upload this file**

3. **D:\New folder\resources\ox_inventory\data\shops.lua**
   - Expanded Ammunation from 4 weapons to 75+ weapons
   - Added melee weapons, handguns, SMGs, shotguns, assault rifles, LMGs, snipers, throwables, ammo
   - Updated pricing
   - **Upload this file**

4. **D:\New folder\resources\[qb]\qbx_customs\config\shared.lua**
   - Enhanced pricing structure with 15 mod categories
   - Added new options: wheel color, window tint, license plate, armor, xenon lights, custom wheels, body kits
   - Increased prices for performance upgrades
   - **Upload this file** (Note: This resource is now DISABLED in server.cfg in favor of renzu_customs, but keep the file)

5. **D:\New folder\PHANTOM_WORLD_CHANGES.md**
   - Documentation of all changes
   - **Upload this file** (for reference)

---

## NEW FOLDERS TO UPLOAD (Create these folders on your host)

### 1. **resources/[standalone]/dr-fines/** (NEW - Complete fines system)
Upload the entire folder with these files:
- fxmanifest.lua
- config.lua
- server.lua
- client.lua

### 2. **resources/[standalone]/dr-tips/** (NEW - Tips system)
Upload the entire folder with these files:
- fxmanifest.lua
- config.lua
- server.lua
- client.lua
- html/index.html

### 3. **resources/renzu_customs/** (NEW - Advanced vehicle customs)
Upload the entire folder with these files:
- fxmanifest.lua
- config.lua
- client.lua
- server.lua
- html/index.html
- html/style.css
- html/script.js

### 4. **resources/renzu_hud/** (NEW - Advanced HUD with wanted system)
Upload the entire folder with these files:
- fxmanifest.lua
- config.lua
- client.lua
- server.lua
- html/index.html
- html/style.css
- html/script.js

---

## EXISTING FOLDERS (Already on host - No upload needed)

These were already installed, just configured in server.cfg:
- **resources/renzu_spawn/** (Already exists)
- **resources/renzu_multicharacter/** (Already exists)

---

## DATABASE CHANGES

When you start the server for the first time after upload, these tables will be auto-created:
- `player_fines` (for dr-fines system)
- `renzu_customs` (for custom vehicle data)
- `renzu_hud_settings` (for HUD player preferences)

---

## UPLOAD ORDER (Recommended)

1. First, upload the **modified files**:
   - server.cfg (IMPORTANT - do this last after uploading new resources)
   - resources/qbx_vehicleshop/config/shared.lua
   - resources/ox_inventory/data/shops.lua
   - resources/[qb]/qbx_customs/config/shared.lua

2. Then, upload the **new folders**:
   - resources/[standalone]/dr-fines/
   - resources/[standalone]/dr-tips/
   - resources/renzu_customs/
   - resources/renzu_hud/

3. Finally, upload documentation:
   - PHANTOM_WORLD_CHANGES.md

---

## SERVER STARTUP

After upload, start your server. The following will happen automatically:
1. New resources will start
2. Database tables will be created
3. Renzu spawn/multicharacter will be active
4. Renzu customs will replace qbx_customs
5. Renzu HUD will replace qbx_hud
6. Fines and tips systems will be active

---

## VERIFICATION CHECKLIST

After upload and server start, verify:
- [ ] Server starts without errors
- [ ] New resources load (check console)
- [ ] Renzu spawn/multicharacter works
- [ ] Vehicle dealerships show new locations
- [ ] Gun stores have expanded inventory
- [ ] Renzu customs shops are active
- [ ] HUD displays correctly with wanted stars
- [ ] Fines system commands work (/getfines, /payfine)
- [ ] Tips system works (/tip, /tips)
- [ ] Wanted system commands work (/setwanted, /clearwanted)

---

## QUICK SUMMARY

**Total Files to Upload:**
- 5 Modified files
- 4 New folders (21 files total)
- 1 Documentation file

**Total: 26 files to upload**

**Critical Files:**
- server.cfg (MUST upload)
- All new resource folders

**Resources Disabled:**
- qbx_spawn → renzu_spawn
- qbx_apartments → Renzu handles housing
- qbx_interior → Not needed with Renzu
- [qb]/qbx_customs → renzu_customs
- qbx_hud → renzu_hud
- dr-hud → renzu_hud

---

## BACKUP RECOMMENDATION

Before uploading, backup these files:
1. server.cfg
2. resources/qbx_vehicleshop/config/shared.lua
3. resources/ox_inventory/data/shops.lua
4. resources/[qb]/qbx_customs/config/shared.lua

This allows you to revert if needed.

---

## CONTACT

If you encounter issues, refer to PHANTOM_WORLD_CHANGES.md for detailed documentation of all changes.
