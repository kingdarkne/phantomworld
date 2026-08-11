// Configuration file for Phantom World loading screen

const config = {
    // Live stats come from server (handover + refresh). These are display defaults only.
    server: {
        name: "Phantom World",
        // Prefer CFX join — direct IP is the current VPS game host
        ip: "172.245.71.46",
        port: "30120",
        maxPlayers: 48,
        cfxJoin: "https://cfx.re/join/3m87mo"
    },

    // Appearance
    appearance: {
        primaryColor: "241, 229, 66",
        accentColor: "200, 200, 40",
        backgroundImage: "https://images.unsplash.com/photo-1575203091586-611fe505bb0e?w=1920",
        youtubeURL: "",
        overlayOpacity: 0.75,
        animateLogo: true
    },

    // Features displayed on Server Info tab (match live Qbox stack)
    features: [
        { icon: "car",            label: "Custom Vehicles & Dealerships" },
        { icon: "wrench",         label: "Mechanic Shops (Qbox job)" },
        { icon: "home",           label: "Housing (next_housing)" },
        { icon: "briefcase",      label: "Jobs — Police, EMS, Burger Shot, Security & more" },
        { icon: "mask",           label: "Heists, Store Robberies & Bank Jobs" },
        { icon: "crosshairs",     label: "Weapons & Ammu-Nation" },
        { icon: "bolt",           label: "Dynamic World Events" },
        { icon: "hospital",       label: "Advanced Medical & Revive (next_death)" },
        { icon: "gas-pump",       label: "Fuel & Vehicle Damage" },
        { icon: "mobile-alt",     label: "NPWD Phone" },
        { icon: "store",          label: "Ox Inventory" },
        { icon: "fish",           label: "Fishing, Hunting & Recycling" }
    ],

    // STAFF — display fallback only; online/offline synced from server (staff_roster.lua)
    staff: [
        {
            name: "Phantom",
            role: "Owner",
            roleType: "admin",
            avatar: "img/avatars/founder.png",
            discordId: "413173364216168449",
            badges: ["founder", "dev"]
        }
    ],

    // No donors
    donors: {
        diamond: [],
        gold: [],
        donationLink: ""
    },

    // Social media links (matches CFX listing)
    socialMedia: {
        discord: "https://discord.gg/Z9Mxu72zZ6",
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
        'Welcome to Phantom World RP — serious roleplay on Qbox.',
        'Join Discord: discord.gg/Z9Mxu72zZ6 for news, events and support.',
        'Connect: cfx.re/join/3m87mo or 172.245.71.46:30120',
        'Press F3 for Emotes. Use /e [emotename] for quick emotes.',
        'Press F4 for the Scoreboard. Press F5 for vMenu.',
        'Press M to open your phone (NPWD). Press L to lock your vehicle.',
        'Press G to toggle your engine. Visit City Hall for ID & jobs.',
        'Banks use omes_banking — look for Bank blips on the map.',
        'No RDM / No VDM — roleplay first.',
        'Report bugs or rule breakers in Discord — do not exploit.',
        'Be respectful to all players and staff at all times.',
        'Try the Speed Clicker mini-game on this screen while you wait!'
    ],

    // Advanced settings
    advanced: {
        debugMode: false,
        loadingStages: [
            { percentage: 10,  message: 'Establishing connection...' },
            { percentage: 20,  message: 'Loading Phantom World...' },
            { percentage: 35,  message: 'Loading game assets...' },
            { percentage: 50,  message: 'Loading vehicles...' },
            { percentage: 65,  message: 'Syncing player data...' },
            { percentage: 80,  message: 'Preparing character select...' },
            { percentage: 90,  message: 'Finalizing setup...' },
            { percentage: 100, message: 'Welcome to Phantom World!' }
        ]
    }
};
