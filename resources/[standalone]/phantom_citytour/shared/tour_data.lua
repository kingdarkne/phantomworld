-- Phantom World City Tour Locations
-- Each location represents a key spot in the city with cinematic camera positions

TourLocations = {
    {
        id = 'start',
        name = 'Welcome to Phantom World',
        description = 'Your journey begins in the heart of Los Santos, where adventure awaits around every corner.',
        category = 'introduction',
        
        -- Camera positions
        camera = {
            start = vector4(-1025.0, -2750.0, 20.0, 150.0), -- Start position
            target = vector4(-1025.0, -2750.0, 10.0, 150.0), -- Look at position
            duration = 8000, -- milliseconds
            fov = 60.0
        },
        
        -- Player position (where player appears during this scene)
        player = {
            coords = vector3(-1025.0, -2750.0, 13.0),
            heading = 150.0,
            animation = {
                dict = "amb@world_human_tourist_map@male@base",
                anim = "base"
            }
        },
        
        -- Information to display
        info = {
            title = 'Welcome to Phantom World',
            subtitle = 'Your Adventure Begins Here',
            description = 'Phantom World is a vibrant roleplay community where your story matters. From jobs and businesses to heists and friendships, every moment counts.',
            facts = {
                '🏙️ Dynamic economy with player-owned businesses',
                '👥 Active community with daily events',
                '🚔 Realistic police and emergency services',
                '🏠 Custom housing and vehicle systems'
            },
            waypoint = vector3(-1025.0, -2750.0, 13.0) -- Optional waypoint for player
        },
        
        -- Visual effects
        effects = {
            timecycle = 'cyberpunk_day',
            weather = 'EXTRASUNNY',
            time = 12.0
        }
    },
    
    {
        id = 'police_dept',
        name = 'Los Santos Police Department',
        description = 'The heart of law enforcement in Phantom World, keeping our streets safe 24/7.',
        category = 'services',
        
        camera = {
            start = vector4(425.0, -978.0, 35.0, 270.0),
            target = vector4(425.0, -978.0, 25.0, 270.0),
            duration = 7000,
            fov = 55.0
        },
        
        player = {
            coords = vector3(425.0, -978.0, 30.0),
            heading = 270.0,
            animation = {
                dict = "amb@world_human_cop_idles@male@base",
                anim = "base"
            }
        },
        
        info = {
            title = 'Los Santos Police Department',
            subtitle = 'Protect & Serve',
            description = 'Our dedicated police force ensures the safety of all citizens. Join the force or report crimes at our headquarters.',
            facts = {
                '🚓 24/7 police patrol services',
                '📞 Emergency response system',
                '🔫 Weapon licensing and permits',
                '🚗 Vehicle registration services'
            },
            waypoint = vector3(425.0, -978.0, 30.0)
        },
        
        effects = {
            timecycle = 'default',
            weather = 'CLEAR',
            time = 14.0
        }
    },
    
    {
        id = 'hospital',
        name = 'Pillbox Hill Medical Center',
        description = 'State-of-the-art medical facility providing emergency care and health services.',
        category = 'services',
        
        camera = {
            start = vector4(295.0, -583.0, 43.0, 340.0),
            target = vector4(295.0, -583.0, 33.0, 340.0),
            duration = 7000,
            fov = 50.0
        },
        
        player = {
            coords = vector3(295.0, -583.0, 43.0),
            heading = 340.0,
            animation = {
                dict = "amb@world_human_medic_check@male@base",
                anim = "base"
            }
        },
        
        info = {
            title = 'Pillbox Hill Medical Center',
            subtitle = 'Health & Wellness',
            description = 'Our medical center provides comprehensive healthcare services, from emergency treatment to routine check-ups.',
            facts = {
                '🏥 24/7 emergency services',
                '💊 Pharmacy and medication services',
                '🩺 Medical insurance system',
                '🚑 Ambulance and paramedic services'
            },
            waypoint = vector3(295.0, -583.0, 43.0)
        },
        
        effects = {
            timecycle = 'hospital',
            weather = 'CLOUDS',
            time = 10.0
        }
    },
    
    {
        id = 'city_hall',
        name = 'Los Santos City Hall',
        description = 'The center of government where citizens can access essential services.',
        category = 'government',
        
        camera = {
            start = vector4(-545.0, -204.0, 48.0, 25.0),
            target = vector4(-545.0, -204.0, 38.0, 25.0),
            duration = 7000,
            fov = 55.0
        },
        
        player = {
            coords = vector3(-545.0, -204.0, 38.0),
            heading = 25.0,
            animation = {
                dict = "amb@world_human_business_checklist@male@base",
                anim = "base"
            }
        },
        
        info = {
            title = 'Los Santos City Hall',
            subtitle = 'Civic Services',
            description = 'City Hall is your gateway to government services, job applications, property registration, and legal documentation.',
            facts = {
                '📋 Job applications and licensing',
                '🏠 Property registration services',
                '📄 Legal document processing',
                '💳 Business permit applications'
            },
            waypoint = vector3(-545.0, -204.0, 38.0)
        },
        
        effects = {
            timecycle = 'default',
            weather = 'CLEAR',
            time = 16.0
        }
    },
    
    {
        id = 'bank',
        name = 'Fleeca Bank',
        description = 'Secure banking services for all your financial needs in Phantom World.',
        category = 'services',
        
        camera = {
            start = vector4(147.0, -1040.0, 32.0, 340.0),
            target = vector4(147.0, -1040.0, 22.0, 340.0),
            duration = 6000,
            fov = 50.0
        },
        
        player = {
            coords = vector3(147.0, -1040.0, 29.0),
            heading = 340.0,
            animation = {
                dict = "amb@world_human_atm@male@base",
                anim = "base"
            }
        },
        
        info = {
            title = 'Fleeca Bank',
            subtitle = 'Financial Services',
            description = 'Manage your finances with our secure banking system. From daily transactions to major investments, we\'ve got you covered.',
            facts = {
                '💳 ATM and banking services',
                '💰 Loan and credit services',
                '🏦 Investment opportunities',
                '💸 Secure money transfers'
            },
            waypoint = vector3(147.0, -1040.0, 29.0)
        },
        
        effects = {
            timecycle = 'default',
            weather = 'EXTRASUNNY',
            time = 13.0
        }
    },
    
    {
        id = 'ammunation',
        name = 'Ammunation',
        description = 'Your premier destination for weapons, ammunition, and self-defense equipment.',
        category = 'services',
        
        camera = {
            start = vector4(810.0, -2157.0, 35.0, 270.0),
            target = vector4(810.0, -2157.0, 25.0, 270.0),
            duration = 6000,
            fov = 55.0
        },
        
        player = {
            coords = vector3(810.0, -2157.0, 29.0),
            heading = 270.0,
            animation = {
                dict = "amb@world_human_guard_patrol@male@base",
                anim = "base"
            }
        },
        
        info = {
            title = 'Ammunation',
            subtitle = 'Armed & Ready',
            description = ' licensed firearm dealer offering quality weapons and ammunition for self-defense and sporting purposes.',
            facts = {
                '🔫 Licensed weapon sales',
                '🛡️ Self-defense equipment',
                '🎯 Target shooting ranges',
                '📋 Weapon licensing services'
            },
            waypoint = vector3(810.0, -2157.0, 29.0)
        },
        
        effects = {
            timecycle = 'default',
            weather = 'CLEAR',
            time = 15.0
        }
    },
    
    {
        id = 'mechanic',
        name = 'Los Santos Customs',
        description = 'Premium vehicle modification and repair services for all your automotive needs.',
        category = 'services',
        
        camera = {
            start = vector4(-1155.0, -2005.0, 20.0, 140.0),
            target = vector4(-1155.0, -2005.0, 10.0, 140.0),
            duration = 6000,
            fov = 60.0
        },
        
        player = {
            coords = vector3(-1155.0, -2005.0, 13.0),
            heading = 140.0,
            animation = {
                dict = "amb@world_human_vehicle_mechanic@male@base",
                anim = "base"
            }
        },
        
        info = {
            title = 'Los Santos Customs',
            subtitle = 'Vehicle Excellence',
            description = 'Transform your ride with our comprehensive vehicle modification services. From performance upgrades to visual enhancements.',
            facts = {
                '🔧 Full vehicle repair services',
                '🎨 Custom paint and wraps',
                '⚡ Performance upgrades',
                '🛞 Tire and wheel services'
            },
            waypoint = vector3(-1155.0, -2005.0, 13.0)
        },
        
        effects = {
            timecycle = 'default',
            weather = 'CLEAR',
            time = 11.0
        }
    },
    
    {
        id = 'sandy_shores',
        name = 'Sandy Shores Medical Center',
        description = 'Rural medical facility serving the Sandy Shores community and surrounding areas.',
        category = 'services',
        
        camera = {
            start = vector4(1839.0, 3672.0, 40.0, 210.0),
            target = vector4(1839.0, 3672.0, 30.0, 210.0),
            duration = 7000,
            fov = 55.0
        },
        
        player = {
            coords = vector3(1839.0, 3672.0, 34.0),
            heading = 210.0,
            animation = {
                dict = "amb@world_human_medic_check@male@base",
                anim = "base"
            }
        },
        
        info = {
            title = 'Sandy Shores Medical Center',
            subtitle = 'Rural Healthcare',
            description = 'Our Sandy Shores location provides comprehensive medical services to the rural communities of Phantom World.',
            facts = {
                '🏥 Emergency medical services',
                '🚗 Ambulance coverage for rural areas',
                '💊 Pharmacy and medication',
                '🩺 General healthcare services'
            },
            waypoint = vector3(1839.0, 3672.0, 34.0)
        },
        
        effects = {
            timecycle = 'countryside_default',
            weather = 'CLEAR',
            time = 17.0
        }
    },
    
    {
        id = 'vinewood',
        name = 'Vinewood Boulevard',
        description = 'The entertainment capital of Phantom World, where dreams are made and stars are born.',
        category = 'entertainment',
        
        camera = {
            start = vector4(680.0, 50.0, 85.0, 340.0),
            target = vector4(680.0, 50.0, 75.0, 340.0),
            duration = 8000,
            fov = 60.0
        },
        
        player = {
            coords = vector3(680.0, 50.0, 80.0),
            heading = 340.0,
            animation = {
                dict = "amb@world_human_tourist_map@female@base",
                anim = "base"
            }
        },
        
        info = {
            title = 'Vinewood Boulevard',
            subtitle = 'Entertainment District',
            description = 'Experience the glamour and excitement of Vinewood, home to entertainment venues, luxury shopping, and celebrity sightings.',
            facts = {
                '🎬 Movie studios and theaters',
                '🛍️ Luxury shopping destinations',
                '🍽️ Fine dining restaurants',
                '🌟 Celebrity hotspots'
            },
            waypoint = vector3(680.0, 50.0, 80.0)
        },
        
        effects = {
            timecycle = 'cinema',
            weather = 'EXTRASUNNY',
            time = 20.0
        }
    },
    
    {
        id = 'airport',
        name = 'Los Santos International Airport',
        description = 'Your gateway to the world, connecting Phantom World to destinations far and wide.',
        category = 'transportation',
        
        camera = {
            start = vector4(-965.0, -2800.0, 20.0, 45.0),
            target = vector4(-965.0, -2800.0, 10.0, 45.0),
            duration = 7000,
            fov = 65.0
        },
        
        player = {
            coords = vector3(-965.0, -2800.0, 13.0),
            heading = 45.0,
            animation = {
                dict = "amb@world_human_tourist_stand@male@base",
                anim = "base"
            }
        },
        
        info = {
            title = 'Los Santos International Airport',
            subtitle = 'Gateway to the World',
            description = 'LSX connects Phantom World to destinations worldwide. Whether for business or pleasure, your journey starts here.',
            facts = {
                '✈️ Domestic and international flights',
                '🛃 Customs and immigration services',
                '🚗 Car rental and parking',
                '🏨 Airport hotels and lounges'
            },
            waypoint = vector3(-965.0, -2800.0, 13.0)
        },
        
        effects = {
            timecycle = 'airport',
            weather = 'CLEAR',
            time = 12.0
        }
    }
}

-- Tour categories for organization
TourCategories = {
    {
        id = 'introduction',
        name = 'Introduction',
        description = 'Welcome to Phantom World',
        icon = '🏙️',
        color = '#4CAF50'
    },
    {
        id = 'services',
        name = 'Essential Services',
        description = 'Important city services',
        icon = 'services',
        color = '#2196F3'
    },
    {
        id = 'government',
        name = 'Government',
        description = 'Civic and government services',
        icon = '🏛️',
        color = '#FF9800'
    },
    {
        id = 'entertainment',
        name = 'Entertainment',
        description = 'Fun and leisure activities',
        icon = '🎭',
        color = '#9C27B0'
    },
    {
        id = 'transportation',
        name = 'Transportation',
        description = 'Getting around the city',
        icon = '🚗',
        color = '#607D8B'
    }
}
