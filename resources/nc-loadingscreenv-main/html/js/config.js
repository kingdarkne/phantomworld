// Configuration file for Phantom World loading screen

const config = {
    // Appearance
    appearance: {
        primaryColor: "241, 229, 66",
        accentColor: "200, 200, 40",
        backgroundImage: "https://images.unsplash.com/photo-1575203091586-611fe505bb0e?w=1920",
        youtubeURL: "",
        overlayOpacity: 0.75,
        animateLogo: true
    },

    // Features displayed on Server Info tab
    features: [
        { icon: "car",            label: "300+ Custom Vehicles — Multiple Dealerships" },
        { icon: "wrench",         label: "Advanced Mechanic Shop (kaves_mechanic)" },
        { icon: "home",           label: "Full Housing System" },
        { icon: "briefcase",      label: "Custom Jobs & Gang Territory" },
        { icon: "mask",           label: "Heists, Store Robberies & Bank Jobs" },
        { icon: "crosshairs",     label: "80+ Weapons — Licensed Gun Stores" },
        { icon: "bolt",           label: "Dynamic World Events" },
        { icon: "hospital",       label: "Advanced Medical & Revive System" },
        { icon: "gas-pump",       label: "Realistic Fuel & Vehicle Damage" },
        { icon: "mobile-alt",     label: "Full-Featured Phone System" },
        { icon: "store",          label: "Ox Inventory" },
        { icon: "fish",           label: "Fishing, Hunting & Mini-Games" }
    ],

    // STAFF — Phantom World owner only
    staff: [
        {
            name: "Phantom",
            role: "Owner",
            roleType: "admin",
            avatar: "img/avatars/founder.png",
            status: "online",
            badges: ["founder", "dev"]
        }
    ],

    // No donors
    donors: {
        diamond: [],
        gold: [],
        donationLink: ""
    },

    // Social media links
    socialMedia: {
        discord: "https://discord.gg/phantomworld",
        tiktok: "",
        youtube: "",
        instagram: ""
    },

    // Audio settings
    audio: {
        enabled: true,
        volume: 0.3,
        trackName: "Phantom World — Loading Music",
        file: "music/background.mp3"
    },

    // Tips
    tips: [
        'Welcome to Phantom World RP — Serious roleplay with a custom-built experience.',
        'Join our Discord at discord.gg/phantomworld for news, events and support.',
        'Press F3 to open the Emote Menu. Use /e [emotename] for quick emotes.',
        'Press F4 to open the Scoreboard and see who is online.',
        'Press F5 to open vMenu. Press F10 to open the Phantom main menu.',
        'Press F6 (if mechanic) to open the Mechanic Order Tablet.',
        'Press M to open your phone. Press L to lock / unlock your vehicle.',
        'Press G to toggle your engine on or off without getting out.',
        'Visit one of our many dealerships — economy, luxury, sports, trucks, boats & aircraft.',
        'Bring your vehicle to the Mechanic Shop and press E to open upgrades.',
        'No RDM — do not kill other players without a valid roleplay reason.',
        'No VDM — do not use your vehicle as a weapon.',
        'Report any bugs or rule breakers in the Discord — do not exploit.',
        'Be respectful to all players and staff at all times.',
        'Try the Speed Clicker mini-game on this screen while you wait!'
    ],

    // Advanced settings
    advanced: {
        debugMode: false,
        loadingStages: [
            { percentage: 10,  message: 'Establishing connection...' },
            { percentage: 20,  message: 'Loading world...' },
            { percentage: 35,  message: 'Loading game assets...' },
            { percentage: 50,  message: 'Loading vehicles...' },
            { percentage: 65,  message: 'Syncing player data...' },
            { percentage: 80,  message: 'Preparing Phantom World...' },
            { percentage: 90,  message: 'Finalizing setup...' },
            { percentage: 100, message: 'Welcome to Phantom World!' }
        ]
    }
};