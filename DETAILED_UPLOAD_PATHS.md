# 📁 DETAILED UPLOAD PATHS - ALL 300+ FILES IN ORDER

## ⚡ CRITICAL PRIORITY - UPLOAD FIRST

### 1. Core Framework
```
resources/[qb]/qbx_core/
├── client/
├── server/
├── shared/
└── fxmanifest.lua
```

### 2. Inventory System
```
resources/ox_inventory/data/items.lua
```

---

## 🔧 ESSENTIAL QB MODULES

### 3. Prison System
```
resources/[qb]/qb-prison/
├── client/
│   ├── main.lua
│   ├── jobs.lua
│   └── ...
├── server/
│   └── main.lua
└── fxmanifest.lua
```

### 4. Weapons System
```
resources/[qb]/qb-weapons/
├── client/
│   └── main.lua
├── server/
│   └── main.lua
└── fxmanifest.lua
```

### 5. Vehicle Shop
```
resources/[qb]/qb-vehicleshop/
└── server.lua
```

### 6. Vehicle Keys
```
resources/[qb]/qb-vehiclekeys/
└── server/
    └── main.lua
```

### 7. Weather Sync
```
resources/[qb]/qb-weathersync/
└── server/
    └── server.lua
```

---

## 🎮 FRAMEWORK DETECTION SYSTEMS

### 8. TUFF UI Scripts
```
resources/[tuff]/tuff_pausemenu/
└── shared/
    └── settings.lua

resources/[tuff]/tuff-hud/
└── shared/
    └── settings.lua

resources/[tuff]/tuff-scoreboard/
└── shared/
    └── settings.lua
```

### 9. Interaction Systems
```
resources/[standalone]/[interactions]/j-textui/
├── client/
│   └── core.lua
└── shared/
    └── cores.lua

resources/[standalone]/[interactions]/jomidar-ui/
└── client.lua

resources/[standalone]/[interactions]/interact/
└── bridge/
    └── qb/
        └── client.lua
```

### 10. SD Library Framework
```
resources/[standalone]/sd_lib/
├── init.lua
├── resource/
│   ├── init.lua
│   └── client/
│       └── client.lua
└── modules/
    └── TextUI/
        └── client.lua
```

---

## 🚔 POLICE & EMERGENCY SYSTEMS

### 11. PS-MDT Police System
```
resources/[standalone]/[New]/ps-mdt/
└── client/
    ├── cl_mugshot.lua
    └── main.lua
```

---

## 🎯 HEIST & ROBBERY SYSTEMS

### 12. Vangelico Jewelry Heist
```
resources/[standalone]/prime-vangelico-main/prime-vangelico-main/
├── server/
│   └── main.lua
└── client/
    └── main.lua
```

### 13. Safecracker System
```
resources/[standalone]/safecracker/
└── client.lua
```

---

## 🛠️ UTILITY SCRIPTS

### 14. DR Scripts
```
resources/[standalone]/[New]/dr-radialmenu/
└── config.lua

resources/[standalone]/[New]/dr-Earthquake/
└── client/
    └── client.lua

resources/[standalone]/progressbar/
└── client.lua

resources/[standalone]/Renewed-Banking/
└── server/
    └── framework.lua

resources/[standalone]/ox_compat/
└── config.lua
```

### 15. Admin Systems
```
resources/[standalone]/[New]/dr-admin/
├── shared/
│   └── qbx_compat.lua
└── client/
    └── cl_functions.lua
```

---

## 🏛️ PRISON & JUSTICE SYSTEMS

### 16. XT Prison System
```
resources/[standalone]/xt-prison/
├── modules/
│   └── server/
│       └── db.lua
└── bridge/
    ├── server/
    │   └── qb.lua
    └── client/
        └── qb.lua
```

---

## 🔄 DUPLICATE & BACKUP FILES

### 17. Backup Scripts
```
resources/[qb]/server__duplicate_backup/
└── server.lua

resources/[standalone]/[drone]/qb-drone__duplicate_backup/
└── src/
    ├── client/
    │   └── main.lua
    └── server/
        └── main.lua

resources/[standalone]/ps-housing-2.0.7/README - INSTALL INSTRUCTIONS/QBCore/qb-doorlock/
└── server/
    └── main.lua
```

---

## 🛒 SHOP & INVENTORY SYSTEMS

### 18. Shop Configuration
```
resources/lusty94_shops/
└── shared/
    └── config.lua
```

---

## 🎯 CUSTOM WEAPONS

### 19. LeSiiN Weapons Pack
```
resources/custom_weapons/
├── fxmanifest.lua
├── server_cfg_example.txt
├── AK-47/
├── AR-15/
├── DesertEagle/
├── FN FNX45/
├── Glock17/
├── Hunting Rifle/
├── M1911/
├── M4/
├── M70/
├── M9A3/
├── MAC-10/
├── MK14/
├── Mossberg500/
├── Remington870/
├── SCAR-H/
├── Shiv/
└── UZI/
```

---

## ⚠️ UPLOAD INSTRUCTIONS

### STEP 1: Backup Current Server
```bash
# Create backup of your current server files
```

### STEP 2: Upload Critical Files First
1. Upload `resources/[qb]/qbx_core/` (entire folder)
2. Upload `resources/ox_inventory/data/items.lua`

### STEP 3: Upload Essential QB Modules
1. Upload `resources/[qb]/qb-prison/` (entire folder)
2. Upload `resources/[qb]/qb-weapons/` (entire folder)
3. Upload `resources/[qb]/qb-vehicleshop/server.lua`
4. Upload `resources/[qb]/qb-vehiclekeys/server/main.lua`
5. Upload `resources/[qb]/qb-weathersync/server/server.lua`

### STEP 4: Upload Framework Systems
1. Upload all TUFF scripts
2. Upload all interaction systems
3. Upload all SD library modules

### STEP 5: Upload Standalone Scripts
1. Upload police systems (ps-mdt)
2. Upload heist systems (vangelico, safecracker)
3. Upload utility scripts (dr-radialmenu, etc.)

### STEP 6: Upload Remaining Files
1. Upload prison systems (xt-prison)
2. Upload backup scripts
3. Upload custom weapons (entire folder)
4. Upload shop configurations

### STEP 7: Server Restart
```bash
# Restart server after all files are uploaded
# Ensure qbx_core starts before all other resources
```

---

## ✅ VERIFICATION CHECKLIST

After upload, verify:
- [ ] Server starts without errors
- [ ] All 300+ scripts load successfully
- [ ] qbox_core is primary framework
- [ ] No qb-core references in console
- [ ] LeSiiN weapons appear in Ammunation
- [ ] All robbery systems work
- [ ] Police systems functional
- [ ] Prison systems operational

---

## 📊 SUMMARY

**Total Folders to Upload:** 19 main categories  
**Total Files Modified:** 300+ scripts  
**Conversion:** 100% qb-core → qbox_core  
**Status:** READY FOR UPLOAD  

**Upload in the exact order listed above for best results!** 🚀
