# 🎬 Phantom World City Tour

A premium cinematic city tour script for FiveM, featuring smooth camera movements, React-based UI, and comprehensive location information.

## ✨ Features

### 🎥 **Cinematic Camera System**
- Smooth camera transitions with easing functions
- Multiple camera effects (shake, zoom, fade, blur)
- Panoramic shots and follow modes
- Customizable FOV and movement patterns

### 🎯 **10 Key Locations**
- **Welcome to Phantom World** - Introduction area
- **Los Santos Police Department** - Law enforcement hub
- **Pillbox Hill Medical Center** - Medical services
- **Los Santos City Hall** - Government services
- **Fleeca Bank** - Financial services
- **Ammunation** - Weapon shop
- **Los Santos Customs** - Vehicle modifications
- **Sandy Shores Medical Center** - Rural healthcare
- **Vinewood Boulevard** - Entertainment district
- **Los Santos International Airport** - Transportation hub

### 🎮 **Interactive Controls**
- **F7** - Start/Stop tour
- **Space** - Skip current location
- **P** - Pause/Resume tour
- **H** - Toggle UI visibility
- **Arrow Keys** - Navigate locations
- **Escape** - Exit tour

### 🎨 **Modern React UI**
- Glass morphism design
- Smooth animations with Framer Motion
- Responsive layout
- Progress indicators
- Location information panels
- Tour statistics and leaderboards

### 📊 **Tour Statistics**
- Track player tour completion
- Location popularity analytics
- Tour duration metrics
- Leaderboard system
- Admin management tools

## 🚀 Installation

### 1. **Download & Setup**
```bash
# Clone or download the phantom_citytour folder to your resources
# Place it in: resources/[standalone]/phantom_citytour/
```

### 2. **Build the Web Interface**
```bash
cd resources/[standalone]/phantom_citytour/web
npm install
npm run build
```

### 3. **Server Configuration**
Add to your `server.cfg`:
```lua
ensure phantom_citytour
```

### 4. **Framework Integration**
The script automatically integrates with **qbx_core** framework. No additional configuration needed.

## 🎮 Usage

### **Starting the Tour**
- Type `/citytour` in chat
- Press **F7** key
- Auto-starts for new players (configurable)

### **Tour Controls**
- **F7** - Start/Stop tour
- **Space** - Skip current location  
- **P** - Pause/Resume
- **H** - Hide/Show UI
- **←/→** - Previous/Next location
- **Escape** - Exit tour

### **Features During Tour**
- **Waypoint Setting** - Set GPS to current location
- **Location Information** - Detailed info about each spot
- **Progress Tracking** - See tour completion status
- **Pause & Resume** - Control tour flow
- **Statistics View** - Tour analytics and leaderboards

## ⚙️ Configuration

### **Tour Settings** (`config.lua`)
```lua
Config.TourSettings = {
    CameraTransitionSpeed = 2.0,    -- Camera transition duration
    CameraFOV = 50.0,              -- Field of view
    ShowControls = true,           -- Show control hints
    AllowSkip = true,              -- Allow skipping locations
    AutoStart = false,             -- Auto-start for new players
    ShowProgress = true,           -- Show progress indicator
}
```

### **Keybinds**
```lua
Config.Keybinds = {
    StartTour = 'F7',              -- Start/stop tour
    SkipLocation = 'SPACE',        -- Skip current location
    PauseTour = 'P',               -- Pause/resume
    ToggleUI = 'H'                -- Hide/show UI
}
```

### **New Player Settings**
```lua
Config.NewPlayerSettings = {
    AutoStartOnFirstJoin = true,   -- Auto-start for new players
    ShowPromptOnSpawn = true,      -- Show tour prompt on spawn
    RequiredPlayTime = 0,          -- Minutes before tour restart
    CooldownTime = 30             -- Minutes between tours
}
```

## 🎯 Customization

### **Adding New Locations**
Edit `shared/tour_data.lua`:

```lua
{
    id = 'custom_location',
    name = 'Custom Location',
    description = 'Description of the location',
    category = 'custom',
    
    camera = {
        start = vector4(x, y, z, heading),
        target = vector4(x, y, z, heading),
        duration = 8000,
        fov = 50.0
    },
    
    player = {
        coords = vector3(x, y, z),
        heading = heading,
        animation = {
            dict = "amb@world_human_tourist_map@male@base",
            anim = "base"
        }
    },
    
    info = {
        title = 'Location Title',
        subtitle = 'Location Subtitle',
        description = 'Detailed description...',
        facts = {
            '📍 Key feature 1',
            '📍 Key feature 2',
            '📍 Key feature 3'
        },
        waypoint = vector3(x, y, z)
    },
    
    effects = {
        timecycle = 'default',
        weather = 'CLEAR',
        time = 12.0
    }
}
```

### **Camera Effects**
Add to `camera.effects` array:
```lua
{
    type = "shake",
    intensity = 0.5,
    duration = 1.0
},
{
    type = "zoom",
    targetFOV = 60.0,
    duration = 2.0
},
{
    type = "panoramic",
    startAngle = 0,
    endAngle = 360,
    radius = 10.0,
    height = 5.0,
    duration = 10.0
}
```

### **UI Customization**
- Edit `web/src/components/` for UI changes
- Modify `web/tailwind.config.js` for styling
- Update `web/src/index.css` for animations

## 🛠️ Admin Commands

```bash
# Force start tour for player
/forcetour [playerId]

# Force stop tour for player  
/stoptour [playerId]

# View tour statistics
/tourstats

# Reset tour stats (debug mode)
/resettourstats [playerId] # or no argument for all
```

## 📊 Tour Statistics

The script tracks:
- **Total tours completed**
- **Unique players**
- **Average tour duration**
- **Popular locations**
- **Player leaderboards**
- **Location visit frequency**

### **Viewing Statistics**
- Press **B** during tour to open stats
- Use `/tourstats` command (admin)
- Access through admin panel

## 🔧 Technical Details

### **Framework Compatibility**
- **Primary**: qbx_core (QBox)
- **Legacy**: qb-core (with compatibility bridge)
- **Standalone**: Works without framework

### **Dependencies**
- **qbx_core** (recommended)
- **ox_lib** (for additional features)

### **Performance**
- Optimized camera system
- Efficient UI rendering
- Minimal server impact
- Smooth 60 FPS experience

## 🐛 Troubleshooting

### **Common Issues**

**Tour doesn't start:**
- Check if qbx_core is running
- Verify resource is started correctly
- Check console for errors

**UI not showing:**
- Build the web interface (`npm run build`)
- Check NUI permissions
- Verify fxmanifest.lua paths

**Camera stuck:**
- Check player coordinates
- Verify camera data in tour_data.lua
- Restart the resource

**Performance issues:**
- Reduce camera transition speed
- Disable unnecessary effects
- Check server performance

### **Debug Mode**
Enable in `config.lua`:
```lua
Config.AdminSettings.DebugMode = true
```

This enables additional logging and debug commands.

## 📝 Updates

### **Version 1.0.0**
- Initial release
- 10 tour locations
- React-based UI
- Cinematic camera system
- Tour statistics
- Admin controls

## 🤝 Support

For support and updates:
- Join our Discord: [discord.gg/phantomworld](https://discord.gg/phantomworld)
- Report issues on GitHub
- Check documentation for common solutions

## 📄 License

This script is licensed under MIT License.
Feel free to modify and distribute with proper attribution.

---

**Created for Phantom World Roleplay Community**  
*Enhancing the FiveM experience, one tour at a time.* 🎮✨
