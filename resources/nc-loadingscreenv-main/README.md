# NC-LoadingScreenV4

A premium FiveM Loading Screen. Modern, customizable and feature-rich.

Youtube Preview - [Click Here](https://www.youtube.com/watch?v=TwZMQWYA630)
![Free Loading Screen - NCHub](https://github.com/user-attachments/assets/c0616c6f-9017-4e7d-a8cb-23c8d0e06b46)

## Support

If you encounter any issues or have questions, feel free to join our Discord community - [Discord.gg/NCHub](https://discord.gg/NCHub)

## Features

- **Multiple tabs**: Server Info, Staff Team, Top Donors, About, and Mini-Game
- **Dynamic backgrounds**: YouTube video or custom image support
- **Interactive elements**: Speed Clicker mini-game, social media links
- **Real-time server data**: Stats, features, staff and donor recognition
- **Audio system**: Background music with player controls
- **Modern design**: Glass-morphism UI with smooth animations
- **Easy configuration**: Simple config.js for customization

## Installation

1. Download the latest release
2. Extract to your server resources directory
3. Add `ensure nc-loadingscreenv4` to your server.cfg
4. Configure in `html/js/config.js`
5. Restart your server

## Configuration Examples

Edit `html/js/config.js` to customize your loading screen. Here are key settings:

### Appearance & Background
```javascript
appearance: {
    primaryColor: "30, 136, 229",     // Main color (RGB format)
    accentColor: "0, 176, 255",       // Secondary color (RGB format)
    
    // Use either YouTube video OR background image
    backgroundImage: "https://your-image-url.jpg",
    youtubeURL: "https://www.youtube.com/watch?v=YOUR_VIDEO_ID",
    
    overlayOpacity: 0.7,              // Background overlay (0-1)
    animateLogo: true                 // Logo animation
}
```

### Server Features
```javascript
features: [
    { icon: "shield-alt", label: "Custom Jobs" },
    { icon: "car", label: "Custom Vehicles" },
    { icon: "home", label: "Property System" }
    // Add more features with FontAwesome icons
]
```

### Staff Team
```javascript
staff: [
    { 
        name: "YourName", 
        role: "Server Owner", 
        roleType: "admin",            // admin, developer, moderator, helper
        avatar: "img/avatars/admin1.png", 
        status: "online",             // online, away, offline
        badges: ["founder", "dev"]    // founder, dev, support, events
    }
    // Add more staff members
]
```

### Social & Audio
```javascript
socialMedia: {
    discord: "https://discord.gg/YourServer",
    tiktok: "#",
    youtube: "#",
    instagram: "#"
}

audio: {
    enabled: true,
    volume: 0.2,                      // Volume (0-1)
    trackName: "Your Track - Name",   // Display name
    file: "music/background.mp3"      // Audio file path
}
```

### Loading Tips
```javascript
tips: [
    'Press F1 to open the help menu when in-game.',
    'Join our Discord server to stay updated.',
    // Add more tips
]
```

## Customization

- Replace `html/img/logo.png` with your server logo
- Add staff/donor avatars to `html/img/avatars/`
- Replace `html/music/background.mp3` with your music
