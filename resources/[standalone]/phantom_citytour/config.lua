Config = {}

-- Framework Configuration
Config.Framework = 'qbx_core' -- Auto-detected, but can be forced

-- Tour Settings
Config.TourSettings = {
    -- Camera settings
    CameraTransitionSpeed = 2.0, -- seconds
    CameraFOV = 50.0,
    CameraHeight = 15.0,
    
    -- UI settings
    ShowControls = true,
    AllowSkip = true,
    AutoStart = false, -- Auto-start for new players
    ShowProgress = true,
    
    -- Audio settings
    BackgroundMusic = true,
    MusicVolume = 0.3,
    MusicFile = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', -- Replace with actual music
    
    -- Timing
    LocationDisplayTime = 5.0, -- seconds
    InfoDisplayTime = 8.0, -- seconds
    TransitionDelay = 1.5, -- seconds
}

-- Keybinds
Config.Keybinds = {
    StartTour = 'F7', -- Start/stop tour
    SkipLocation = 'SPACE', -- Skip current location
    SkipTour = 'BACK', -- Skip entire tour (pre-multichar + manual)
    PauseTour = 'PAUSE', -- Pause/resume (changed from P to avoid conflict)
    ToggleUI = 'H' -- Hide/show UI
}

-- Language settings
Config.Language = {
    TourTitle = 'Phantom World City Tour',
    WelcomeMessage = 'Welcome to Phantom World! Let us show you around our amazing city.',
    LocationInfo = 'Location Information',
    NextLocation = 'Next Location',
    SkipLocation = 'Skip',
    PauseTour = 'Pause',
    ResumeTour = 'Resume',
    EndTour = 'End Tour',
    TourProgress = 'Tour Progress',
    PressToStart = 'Press %s to start the tour',
    PressToSkip = 'Press %s to skip',
    PressToPause = 'Press %s to pause',
    TourCompleted = 'Tour completed! Enjoy your stay in Phantom World!'
}

-- New player settings
Config.NewPlayerSettings = {
    -- Freeroam: never block multichar. After spawn, offer an optional tour.
    AutoStartOnFirstJoin = false, -- must opt in (prompt / F7 / /citytour)
    ShowPromptOnSpawn = true, -- ask once after first spawn
    AutoStartDelay = 6, -- seconds after outfit save before tour prompt (after starter car)
    RequiredPlayTime = 0,
    CooldownTime = 5, -- minutes between manual restarts
    -- Keep false so joins stay fast
    ForceBeforeMultichar = false,
    ForceEveryJoin = false,
}

-- Admin settings
Config.AdminSettings = {
    AllowAdminOverride = true,
    AdminPermissions = {
        'god', 'admin'
    },
    DebugMode = false -- Enable for development
}
