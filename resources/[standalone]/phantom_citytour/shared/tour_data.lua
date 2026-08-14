-- Phantom World City Tour Locations
-- camera.start = camera eye position (x,y,z, heading used if auto-offset needed)
-- camera.target = look-at point (must differ horizontally from start)

TourLocations = {
    {
        id = 'start',
        name = 'Welcome to Phantom World',
        description = 'Your journey begins in the heart of Los Santos, where adventure awaits around every corner.',
        category = 'introduction',

        camera = {
            start = vector4(-1048.0, -2710.0, 32.0, 200.0),
            target = vector4(-1037.0, -2738.0, 14.5, 0.0),
            duration = 9000,
            fov = 55.0
        },

        player = {
            coords = vector3(-1037.0, -2738.0, 13.8),
            heading = 150.0
        },

        info = {
            title = 'Welcome to Phantom World',
            subtitle = 'Your Adventure Begins Here',
            description = 'Phantom World is a vibrant roleplay community where your story matters. From jobs and businesses to heists and friendships, every moment counts.',
            facts = {
                'Dynamic economy with player-owned businesses',
                'Active community with daily events',
                'Realistic police and emergency services',
                'Custom housing and vehicle systems'
            },
            waypoint = vector3(-1037.0, -2738.0, 13.8)
        },

        effects = {
            weather = 'EXTRASUNNY',
            time = 12
        }
    },

    {
        id = 'police_dept',
        name = 'Los Santos Police Department',
        description = 'The heart of law enforcement in Phantom World, keeping our streets safe 24/7.',
        category = 'services',

        camera = {
            start = vector4(408.0, -950.0, 42.0, 200.0),
            target = vector4(428.0, -982.0, 31.5, 0.0),
            duration = 8000,
            fov = 50.0
        },

        player = {
            coords = vector3(428.0, -982.0, 30.7),
            heading = 270.0
        },

        info = {
            title = 'Los Santos Police Department',
            subtitle = 'Protect & Serve',
            description = 'Our dedicated police force ensures the safety of all citizens. Join the force or report crimes at our headquarters.',
            facts = {
                '24/7 police patrol services',
                'Emergency response system',
                'Weapon licensing and permits',
                'Vehicle registration services'
            },
            waypoint = vector3(428.0, -982.0, 30.7)
        },

        effects = {
            weather = 'CLEAR',
            time = 14
        }
    },

    {
        id = 'hospital',
        name = 'Pillbox Hill Medical Center',
        description = 'State-of-the-art medical facility providing emergency care and health services.',
        category = 'services',

        camera = {
            start = vector4(270.0, -560.0, 52.0, 220.0),
            target = vector4(307.0, -589.0, 44.0, 0.0),
            duration = 8000,
            fov = 48.0
        },

        player = {
            coords = vector3(307.0, -589.0, 43.3),
            heading = 340.0
        },

        info = {
            title = 'Pillbox Hill Medical Center',
            subtitle = 'Health & Wellness',
            description = 'Our medical center provides comprehensive healthcare services, from emergency treatment to routine check-ups.',
            facts = {
                '24/7 emergency services',
                'Pharmacy and medication services',
                'Medical insurance system',
                'Ambulance and paramedic services'
            },
            waypoint = vector3(307.0, -589.0, 43.3)
        },

        effects = {
            weather = 'CLOUDS',
            time = 10
        }
    },

    {
        id = 'city_hall',
        name = 'Los Santos City Hall',
        description = 'The center of government where citizens can access essential services.',
        category = 'government',

        camera = {
            start = vector4(-520.0, -230.0, 55.0, 40.0),
            target = vector4(-545.0, -204.0, 40.0, 0.0),
            duration = 8000,
            fov = 50.0
        },

        player = {
            coords = vector3(-545.0, -204.0, 38.2),
            heading = 25.0
        },

        info = {
            title = 'Los Santos City Hall',
            subtitle = 'Civic Services',
            description = 'City Hall is your gateway to government services, job applications, property registration, and legal documentation.',
            facts = {
                'Job applications and licensing',
                'Property registration services',
                'Legal document processing',
                'Business permit applications'
            },
            waypoint = vector3(-545.0, -204.0, 38.2)
        },

        effects = {
            weather = 'CLEAR',
            time = 16
        }
    },

    {
        id = 'bank',
        name = 'Fleeca Bank',
        description = 'Secure banking services for all your financial needs in Phantom World.',
        category = 'services',

        camera = {
            start = vector4(130.0, -1020.0, 38.0, 200.0),
            target = vector4(150.0, -1040.0, 29.5, 0.0),
            duration = 7000,
            fov = 48.0
        },

        player = {
            coords = vector3(149.0, -1040.0, 29.4),
            heading = 340.0
        },

        info = {
            title = 'Fleeca Bank',
            subtitle = 'Financial Services',
            description = 'Manage your finances with our secure banking system. From daily transactions to major investments, we have you covered.',
            facts = {
                'ATM and banking services',
                'Loan and credit services',
                'Investment opportunities',
                'Secure money transfers'
            },
            waypoint = vector3(149.0, -1040.0, 29.4)
        },

        effects = {
            weather = 'EXTRASUNNY',
            time = 13
        }
    },

    {
        id = 'ammunation',
        name = 'Ammunation',
        description = 'Your premier destination for weapons, ammunition, and self-defense equipment.',
        category = 'services',

        camera = {
            start = vector4(828.0, -2140.0, 38.0, 230.0),
            target = vector4(814.0, -2157.0, 29.8, 0.0),
            duration = 7000,
            fov = 50.0
        },

        player = {
            coords = vector3(814.0, -2157.0, 29.6),
            heading = 270.0
        },

        info = {
            title = 'Ammunation',
            subtitle = 'Armed & Ready',
            description = 'Licensed firearm dealer offering quality weapons and ammunition for self-defense and sporting purposes.',
            facts = {
                'Licensed weapon sales',
                'Self-defense equipment',
                'Target shooting ranges',
                'Weapon licensing services'
            },
            waypoint = vector3(814.0, -2157.0, 29.6)
        },

        effects = {
            weather = 'CLEAR',
            time = 15
        }
    },

    {
        id = 'mechanic',
        name = 'Los Santos Customs',
        description = 'Premium vehicle modification and repair services for all your automotive needs.',
        category = 'services',

        camera = {
            start = vector4(-1135.0, -1985.0, 26.0, 200.0),
            target = vector4(-1155.0, -2007.0, 14.0, 0.0),
            duration = 7000,
            fov = 55.0
        },

        player = {
            coords = vector3(-1155.0, -2007.0, 13.2),
            heading = 140.0
        },

        info = {
            title = 'Los Santos Customs',
            subtitle = 'Vehicle Excellence',
            description = 'Transform your ride with our comprehensive vehicle modification services. From performance upgrades to visual enhancements.',
            facts = {
                'Full vehicle repair services',
                'Custom paint and wraps',
                'Performance upgrades',
                'Tire and wheel services'
            },
            waypoint = vector3(-1155.0, -2007.0, 13.2)
        },

        effects = {
            weather = 'CLEAR',
            time = 11
        }
    },

    {
        id = 'sandy_shores',
        name = 'Sandy Shores Medical Center',
        description = 'Rural medical facility serving the Sandy Shores community and surrounding areas.',
        category = 'services',

        camera = {
            start = vector4(1815.0, 3655.0, 48.0, 40.0),
            target = vector4(1839.0, 3672.0, 35.0, 0.0),
            duration = 8000,
            fov = 50.0
        },

        player = {
            coords = vector3(1839.0, 3672.0, 34.3),
            heading = 210.0
        },

        info = {
            title = 'Sandy Shores Medical Center',
            subtitle = 'Rural Healthcare',
            description = 'Our Sandy Shores location provides comprehensive medical services to the rural communities of Phantom World.',
            facts = {
                'Emergency medical services',
                'Ambulance coverage for rural areas',
                'Pharmacy and medication',
                'General healthcare services'
            },
            waypoint = vector3(1839.0, 3672.0, 34.3)
        },

        effects = {
            weather = 'CLEAR',
            time = 17
        }
    },

    {
        id = 'vinewood',
        name = 'Vinewood Boulevard',
        description = 'The entertainment capital of Phantom World, where dreams are made and stars are born.',
        category = 'entertainment',

        camera = {
            start = vector4(655.0, 25.0, 95.0, 35.0),
            target = vector4(690.0, 55.0, 80.0, 0.0),
            duration = 9000,
            fov = 55.0
        },

        player = {
            coords = vector3(686.0, 48.0, 83.1),
            heading = 340.0
        },

        info = {
            title = 'Vinewood Boulevard',
            subtitle = 'Entertainment District',
            description = 'Experience the glamour and excitement of Vinewood, home to entertainment venues, luxury shopping, and celebrity sightings.',
            facts = {
                'Movie studios and theaters',
                'Luxury shopping destinations',
                'Fine dining restaurants',
                'Celebrity hotspots'
            },
            waypoint = vector3(686.0, 48.0, 83.1)
        },

        effects = {
            weather = 'EXTRASUNNY',
            time = 20
        }
    },

    {
        id = 'airport',
        name = 'Los Santos International Airport',
        description = 'Your gateway to the world, connecting Phantom World to destinations far and wide.',
        category = 'transportation',

        camera = {
            start = vector4(-990.0, -2765.0, 35.0, 240.0),
            target = vector4(-1037.0, -2738.0, 16.0, 0.0),
            duration = 8000,
            fov = 60.0
        },

        player = {
            coords = vector3(-1037.0, -2738.0, 13.8),
            heading = 45.0
        },

        info = {
            title = 'Los Santos International Airport',
            subtitle = 'Gateway to the World',
            description = 'LSX connects Phantom World to destinations worldwide. Whether for business or pleasure, your journey starts here.',
            facts = {
                'Domestic and international flights',
                'Customs and immigration services',
                'Car rental and parking',
                'Airport hotels and lounges'
            },
            waypoint = vector3(-1037.0, -2738.0, 13.8)
        },

        effects = {
            weather = 'CLEAR',
            time = 12
        }
    }
}

TourCategories = {
    {
        id = 'introduction',
        name = 'Introduction',
        description = 'Welcome to Phantom World',
        icon = 'intro',
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
        icon = 'government',
        color = '#FF9800'
    },
    {
        id = 'entertainment',
        name = 'Entertainment',
        description = 'Fun and leisure activities',
        icon = 'entertainment',
        color = '#9C27B0'
    },
    {
        id = 'transportation',
        name = 'Transportation',
        description = 'Getting around the city',
        icon = 'transport',
        color = '#607D8B'
    }
}
