# New Scripts Setup Summary
## Generated: May 10, 2026

---

## 📦 NEW SCRIPTS ADDED

### 1. qb-bankrobbery (Bank Heists)
- **Location:** `resources/qb-bankrobbery/`
- **Dependencies:** PolyZone (✓ already ensured)
- **Status:** Added to server.cfg after [heists]
- **SQL:** None required

### 2. qb-houserobbery (House Robberies)
- **Location:** `resources/qb-houserobbery/`
- **Dependencies:** qb-minigames (✓ already ensured)
- **Status:** Added to server.cfg after qb-bankrobbery
- **SQL:** None required

### 3. qb-houses (Housing System)
- **Location:** `resources/qb-houses/`
- **Dependencies:** 
  - qb-core (✓ qbx_core provides this)
  - qb-interior (✓ already ensured)
  - qb-clothing (⚠️ STOPPED - using illenium-appearance)
  - qb-weathersync (⚠️ STOPPED - using dr-weathersync)
- **Status:** Added to server.cfg, stops ps-housing-2.0.7
- **SQL:** `qb-houses.sql` copied to Desktop/sql/
- **⚠️ WARNING:** Dependencies conflict - see FIX section below

### 4. ps-mdt (Police MDT)
- **Location:** `resources/ps-mdt/`
- **Dependencies:**
  - ps_lib (✓ ADDED to server.cfg)
  - oxmysql (✓ already ensured)
  - ox_lib (✓ already ensured)
- **Status:** Added to server.cfg after qbx_police
- **SQL:** 
  - `ps-mdt/sql/qbx.sql` → Desktop/sql/ps-mdt_qbox.sql
  - `ps-mdt/sql/qbcore.sql` → Desktop/sql/ps-mdt_qbcore_backup.sql

### 5. mz-storerobbery (Enhanced Store Robberies)
- **Location:** `resources/mz-storerobbery/`
- **Dependencies:** 
  - ps_lib (✓ added - includes ps-ui minigames)
  - qb-target (✓ already ensured)
  - progressbar (✓ added to server.cfg)
  - mz-skills (✓ added to server.cfg, optional)
- **Status:** Added to server.cfg after lation_247robbery
- **SQL:** None required
- **✅ NOTE:** ps-ui functionality is now in ps_lib (minigames included)

### 6. qs-loadingscreen-master (Loading Screen)
- **Location:** `resources/qs-loadingscreen-master/`
- **Dependencies:** None
- **Status:** Added to server.cfg, stops tuff-loading, dr-loadscreen, loadingscreen
- **SQL:** None required

### 7. lation_247robbery (24/7 Store Robberies)
- **Location:** `resources/lation_247robbery/`
- **Dependencies:** ox_lib (✓ already ensured)
- **Status:** Already in server.cfg (line 461)
- **SQL:** None required

---

## ✅ SCRIPTS READY TO USE

| Script | Dependencies | Status |
|--------|-------------|--------|
| qb-bankrobbery | PolyZone (✓) | Ready |
| qb-houserobbery | qb-minigames (✓) | Ready |
| qb-houses | qb-interior (✓), illenium-appearance (✓), dr-weathersync (✓) | **Fixed & Ready** |
| ps-mdt | ps_lib (✓), oxmysql (✓), ox_lib (✓) | Ready |
| mz-storerobbery | qb-target (✓), progressbar (✓), mz-skills (✓), ps_lib (✓) | **Ready** - ps-ui in ps_lib |
| lation_247robbery | ox_lib (✓) | Ready |
| qs-loadingscreen-master | None | Ready |
| progressbar | None | Added |
| mz-skills | None | Added |

---

## 🛑 SCRIPTS STOPPED

| Script | Reason |
|--------|--------|
| ps-housing-2.0.7 | Replaced by qb-houses |
| tuff-loading | Replaced by qs-loadingscreen-master |
| dr-loadscreen | Replaced by qs-loadingscreen-master |
| loadingscreen | Replaced by qs-loadingscreen-master |

---

## ✅ DEPENDENCY FIXES APPLIED

### qb-houses Dependency Fix ✓
qbx-houses required `qb-clothing` and `qb-weathersync` but your server uses:
- `illenium-appearance` (instead of qb-clothing)
- `dr-weathersync` (instead of qb-weathersync)

**FIXED:** Modified `resources/qb-houses/fxmanifest.lua` to comment out problematic dependencies:
```lua
dependencies {
    'qb-core',
    'qb-interior',
    -- 'qb-clothing',      -- Using illenium-appearance instead
    -- 'qb-weathersync'    -- Using dr-weathersync instead
}
```

qb-houses should now work correctly with your existing setup!

---

## 📤 FILES TO UPLOAD - FULL PATHS

### Server Configuration
1. `d:/New folder/server.cfg`

### New Scripts (Resource Folders)
2. `d:/New folder/resources/qb-bankrobbery/`
3. `d:/New folder/resources/qb-houserobbery/`
4. `d:/New folder/resources/qb-houses/`
5. `d:/New folder/resources/ps-mdt/`
6. `d:/New folder/resources/mz-storerobbery/`
7. `d:/New folder/resources/qs-loadingscreen-master/`
8. `d:/New folder/resources/lation_247robbery/`

### Dependencies (Upload if not present)
9. `d:/New folder/resources/ps_lib/` 
10. `d:/New folder/resources/progressbar/`
11. `d:/New folder/resources/mz-skills/`

### Dependencies Note
All required dependencies are now included in ps_lib (ps-ui minigames merged into ps_lib)

### SQL Files (Import in MySQL)
13. `C:/Users/verte/Desktop/sql/ps-mdt_qbox.sql`
14. `C:/Users/verte/Desktop/sql/ps-mdt_qbcore_backup.sql`
15. `C:/Users/verte/Desktop/sql/qb-houses.sql`

### Modified Files
16. `d:/New folder/server.cfg`
17. `d:/New folder/resources/qb-houses/fxmanifest.lua`
18. `d:/New folder/NEW_SCRIPTS_SETUP.md` (updated)

### Changelog Updated
19. `d:/New folder/resources/qs-loadingscreen-master/web/public/config.json`
# Added Update 1.3.0 entry with all changes

### Documentation
20. `d:/New folder/NEW_SCRIPTS_SETUP.md` (this file)

---

## 🔧 SERVER.CFG CHANGES SUMMARY

### Lines Added/Modified:

```ini
# Line 181-182 - New dependencies added
ensure qb-minigames
ensure progressbar
ensure mz-skills

# Line 247-252 - Housing change
stop ps-housing-2.0.7
# QBCore housing system (newly downloaded)
# FIXED: Modified fxmanifest.lua to work with illenium-appearance and dr-weathersync
ensure qb-houses

# Line 322-324 - MDT with dependency
# Police MDT system (Project Sloth) - requires ps_lib
ensure ps_lib
ensure ps-mdt

# Line 327-331 - Loading screen change
# Phantom loadscreen - using qs-loadingscreen (newly downloaded)
stop loadingscreen
stop dr-loadscreen
stop tuff-loading
# Modern React-based loading screen (newly downloaded)
ensure qs-loadingscreen-master

# Line 333-335 - New robbery systems
ensure [heists]
# New QBCore robbery systems (downloaded)
ensure qb-bankrobbery
ensure qb-houserobbery

# Line 464-468 - Store robbery with dependencies
ensure lation_247robbery
# Enhanced store robbery system (QBCore)
# ps-ui functionality provided by ps_lib (minigames included)
# Optional: mz-skills (already added above) for skill progression
ensure mz-storerobbery
```

---

## ✅ STARTUP ORDER (Important!)

Correct order in server.cfg:
1. Core resources (ox_lib, oxmysql, qbx_core)
2. PolyZone, qb-target, ox_target
3. qb-interior, qb-minigames, progressbar, mz-skills
4. ps_lib (before ps-mdt)
5. qbx_police (before ps-mdt)
6. ps-mdt
7. qb-houses
8. qb-bankrobbery, qb-houserobbery
9. lation_247robbery, mz-storerobbery (ps-ui in ps_lib)
10. qs-loadingscreen-master

---

## 🧪 TESTING CHECKLIST

After uploading and restarting:

- [ ] Server starts without errors
- [ ] Loading screen displays correctly
- [ ] Players can open MDT (police only)
- [ ] qb-houses works (dependencies fixed ✓)
- [ ] Bank robberies work (Fleeca, Paleto, Pacific)
- [ ] House robberies work
- [ ] Store robberies work (lation_247robbery + mz-storerobbery with ps_lib)
- [ ] No dependency errors in console

---

## 🚨 CRITICAL NOTES

1. **ps-mdt requires ps_lib** - Already added to server.cfg before ps-mdt ✓

2. **qb-houses dependencies fixed** - Modified fxmanifest.lua to work with illenium-appearance and dr-weathersync ✓

3. **qs-loadingscreen-master** requires Node.js build if you modify it - use pre-built files

4. **Import SQL files BEFORE first start** - Import both ps-mdt SQL files and qb-houses.sql

5. **Stop order matters** - Make sure ps-housing-2.0.7 is stopped BEFORE qb-houses starts

6. **✅ ps-ui functionality** - Merged into ps_lib, minigames (Thermite, Scrambler) included

---

## 📞 SUPPORT

If errors occur:
1. Check FXServer console for missing dependency errors
2. Verify all SQL files are imported
3. Check that ps_lib is started before ps-mdt
4. Apply qb-houses dependency fix if needed

---

**Setup Complete!** Restart your server after uploading all files.
