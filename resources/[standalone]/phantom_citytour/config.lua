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
    
    -- Audio / narration (browser TTS via NUI)
    EnableNarration = true,
    BackgroundMusic = false,
    MusicVolume = 0.3,
    
    -- Timing
    LocationDisplayTime = 5.0, -- seconds
    InfoDisplayTime = 8.0, -- seconds
    TransitionDelay = 1.5, -- seconds

    -- Camera fallback if start/target share the same XY
    CameraFallbackDistance = 18.0,
    CameraFallbackHeight = 8.0,
}

-- Keybinds
Config.Keybinds = {
    StartTour = 'F7', -- Start/stop tour
    SkipLocation = 'SPACE', -- Skip current location
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
    AutoStartOnFirstJoin = true,
    ShowPromptOnSpawn = true,
    AutoStartDelay = 5, -- seconds after spawn before first-time tour begins
    RequiredPlayTime = 0, -- minutes before tour can be started again
    CooldownTime = 30, -- minutes between repeat tours (after first completion)
    ForceBeforeMultichar = false, -- freeroam should not block character select on tour
    ForceEveryJoin = false
}

-- Admin settings
Config.AdminSettings = {
    AllowAdminOverride = true,
    AdminPermissions = {
        'god', 'admin'
    },
    DebugMode = false -- Enable for development
}
