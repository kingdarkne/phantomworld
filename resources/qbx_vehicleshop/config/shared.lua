return {
    finance = {
        minimumDown = 10, -- minimum percentage allowed down
        maximumPayments = 24, -- maximum payments allowed
        enable = true, -- Enables the financing system. Turning this off does not affect already financed vehicles
        zone = vec3(-29.53, -1103.67, 26.42), -- Where the finance menu is located
    },

    enableFreeUseBuy = true, -- Allows players to buy from NPC shops
    enableTestDrive = true,

    vehicles = {

        -- For the configuration below, it would first look for the vehicle in models.
        -- If not found, it would check for the category in categories.
        -- If the category is also not found, it would default to the default settings.
        -- To disable a vehicle from being sold, define it within the blocklist.
        default = 'pdm',

        categories = {
            boats = 'boats',
            air = 'air',
            helicopters = 'air',     -- GTA5 class name for helicopters
            planes = 'air',          -- GTA5 class name for planes
            sports = 'sports',
            super = 'sports',         -- Supercars go to sports dealership
            sportsclassics = 'pdm',  -- Sport classics stay at PDM
            sedans = 'pdm',          -- Sedans at PDM
            coupes = 'pdm',          -- Coupes at PDM
            suvs = 'suv',            -- SUVs at suv shop
            offroad = 'suv',         -- Offroad at suv shop
            muscle = 'muscle',       -- Muscle at muscle shop
            compacts = 'economy',    -- Compacts at economy shop
            motorcycles = 'motorcycles',
            vans = 'pdm',            -- Vans at PDM
            cycles = 'economy',      -- Bicycles at economy shop
            economy = 'economy',     -- Economy class at economy shop
        },

        models = {
            -- Add overrides here ONLY for custom/addon vehicles not in GTA5 by default.
            -- All standard vehicles are routed by their GTA5 class via the categories table.
            -- Example: myCustomCar = 'sports',

            -- DISABLED: old bulk entries moved to categories table above
            --[[--- Economy (Tier 1 - Budget vehicles)
            asbo = 'economy',
            blista = 'economy',
            brioso = 'economy',
            dilettante = 'economy',
            issi2 = 'economy',
            issi3 = 'economy',
            panto = 'economy',
            prairie = 'economy',
            cogcabrio = 'economy',
            emissive = 'economy',
            surfer = 'economy',
            surfer2 = 'economy',
            washington = 'economy',

            --- Sedans
            asea = 'sedans',
            asea2 = 'sedans',
            asterope = 'sedans',
            cognoscenti = 'sedans',
            cognoscenti2 = 'sedans',
            fugitive = 'sedans',
            glendale = 'sedans',
            ingot = 'sedans',
            intruder = 'sedans',
            premier = 'sedans',
            prinz = 'sedans',
            regina = 'sedans',
            stafford = 'sedans',
            stanier = 'sedans',
            stratum = 'sedans',
            superd = 'sedans',
            tailgater = 'sedans',
            warrener = 'sedans',
            warrener2 = 'sedans',
            washington = 'sedans',

            --- Coupes
            cogcabrio = 'coupes',
            exemplar = 'coupes',
            f620 = 'coupes',
            felon = 'coupes',
            felon2 = 'coupes',
            jackal = 'coupes',
            oracle = 'coupes',
            oracle2 = 'coupes',
            sentinel = 'coupes',
            sentinel2 = 'coupes',
            windsor = 'coupes',
            windsor2 = 'coupes',
            zion = 'coupes',
            zion2 = 'coupes',

            --- Muscle
            blade = 'muscle',
            buccaneer = 'muscle',
            buccaneer2 = 'muscle',
            cheetah2 = 'muscle',
            coquette3 = 'muscle',
            dominator = 'muscle',
            dominator2 = 'muscle',
            dominator3 = 'muscle',
            dominator4 = 'muscle',
            dominator5 = 'muscle',
            dominator6 = 'muscle',
            dominator7 = 'muscle',
            duster = 'muscle',
            faction = 'muscle',
            faction2 = 'muscle',
            faction3 = 'muscle',
            gauntlet = 'muscle',
            gauntlet2 = 'muscle',
            gauntlet3 = 'muscle',
            gauntlet4 = 'muscle',
            gauntlet5 = 'muscle',
            hermes = 'muscle',
            hotknife = 'muscle',
            hustler = 'muscle',
            impaler = 'muscle',
            impaler2 = 'muscle',
            impaler3 = 'muscle',
            imperator = 'muscle',
            imperator2 = 'muscle',
            imperator3 = 'muscle',
            lurcher = 'muscle',
            moonbeam = 'muscle',
            moonbeam2 = 'muscle',
            nightshade = 'muscle',
            peyote = 'muscle',
            peyote2 = 'muscle',
            peyote3 = 'muscle',
            phoenix = 'muscle',
            picador = 'muscle',
            ratloader = 'muscle',
            ratloader2 = 'muscle',
            ruiner = 'muscle',
            ruiner2 = 'muscle',
            ruiner3 = 'muscle',
            sabregt = 'muscle',
            sabregt2 = 'muscle',
            slamvan = 'muscle',
            slamvan2 = 'muscle',
            slamvan3 = 'muscle',
            slamvan4 = 'muscle',
            slamvan5 = 'muscle',
            slamvan6 = 'muscle',
            stalion = 'muscle',
            stalion2 = 'muscle',
            tulip = 'muscle',
            vamos = 'muscle',
            vigero = 'muscle',
            vigero2 = 'musicle',
            virgo = 'muscle',
            virgo2 = 'muscle',
            virgo3 = 'muscle',
            voodoo = 'muscle',
            voodoo2 = 'muscle',
            yosemite = 'muscle',
            yosemite2 = 'muscle',
            yosemite3 = 'muscle',

            --- SUVs
            ballistic = 'suvs',
            bjxl = 'suvs',
            cavalcade = 'suvs',
            cavalcade2 = 'suvs',
            dubsta = 'suvs',
            dubsta2 = 'suvs',
            dubsta3 = 'suvs',
            fq2 = 'suvs',
            granger = 'suvs',
            gresley = 'suvs',
            habanero = 'suvs',
            huntley = 'suvs',
            landstalker = 'suvs',
            landstalker2 = 'suvs',
            mesa = 'suvs',
            mesa2 = 'suvs',
            mesa3 = 'suvs',
            novak = 'suvs',
            patriot = 'suvs',
            patriot2 = 'suvs',
            radi = 'suvs',
            rebel = 'suvs',
            rebel2 = 'suvs',
            rocoto = 'suvs',
            seminole = 'suvs',
            seminole2 = 'suvs',
            serrano = 'suvs',
            toros = 'suvs',
            xls = 'suvs',
            xls2 = 'suvs',

            --- Offroad
            bf400 = 'offroad',
            bifta = 'offroad',
            blazer = 'offroad',
            blazer2 = 'offroad',
            blazer3 = 'offroad',
            blazer4 = 'offroad',
            blazer5 = 'offroad',
            brawler = 'offroad',
            carson = 'offroad',
            dinghy = 'offroad',
            dinghy2 = 'offroad',
            dinghy3 = 'offroad',
            dinghy4 = 'offroad',
            dune = 'offroad',
            dune2 = 'offroad',
            dune3 = 'offroad',
            dune4 = 'offroad',
            dune5 = 'offroad',
            everon = 'offroad',
            kalahari = 'offroad',
            kamacho = 'offroad',
            marshall = 'offroad',
            menacer = 'offroad',
            monster = 'offroad',
            monster3 = 'offroad',
            monster4 = 'offroad',
            monster5 = 'offroad',
            nightshark = 'offroad',
            outlaw = 'offroad',
            ratbike = 'offroad',
            rcbandito = 'offroad',
            riata = 'offroad',
            sandking = 'offroad',
            sandking2 = 'offroad',
            technical = 'offroad',
            technical2 = 'offroad',
            technical3 = 'offroad',
            thrax = 'offroad',
            trophytruck = 'offroad',
            trophytruck2 = 'offroad',

            --- Compacts
            club = 'compacts',
            dilettante = 'compacts',
            dilettante2 = 'compacts',
            issi2 = 'compacts',
            issi3 = 'compacts',
            panto = 'compacts',
            prairie = 'compacts',
            rhapsody = 'compacts',
            cogcabrio = 'compacts',

            --- Motorcycles
            akuma = 'motorcycles',
            apeca = 'motorcycles',
            bati = 'motorcycles',
            bati2 = 'motorcycles',
            bf400 = 'motorcycles',
            carbonrs = 'motorcycles',
            chimera = 'motorcycles',
            cliffhanger = 'motorcycles',
            double = 'motorcycles',
            enduro = 'motorcycles',
            esskey = 'motorcycles',
            faggio = 'motorcycles',
            faggio2 = 'motorcycles',
            faggio3 = 'motorcycles',
            fcr = 'motorcycles',
            fcr2 = 'motorcycles',
            gargoyle = 'motorcycles',
            hakuchou = 'motorcycles',
            hakuchou2 = 'motorcycles',
            hexer = 'motorcycles',
            innovation = 'motorcycles',
            manchez = 'motorcycles',
            manchez2 = 'motorcycles',
            nemesis = 'motorcycles',
            nightblade = 'motorcycles',
            oppresor = 'motorcycles',
            oppresor2 = 'motorcycles',
            pcj = 'motorcycles',
            ratbike = 'motorcycles',
            ruffian = 'motorcycles',
            sanchez = 'motorcycles',
            sanchez2 = 'motorcycles',
            sanctus = 'motorcycles',
            shotaro = 'motorcycles',
            sovereign = 'motorcycles',
            thrust = 'motorcycles',
            vader = 'motorcycles',
            vindicator = 'motorcycles',
            wolfsbane = 'motorcycles',
            zombie = 'motorcycles',
            zombieb = 'motorcycles',

            --- Vans
            bison = 'vans',
            bison2 = 'vans',
            bison3 = 'vans',
            bobcatxl = 'vans',
            boxville = 'vans',
            boxville2 = 'vans',
            boxville3 = 'vans',
            boxville4 = 'vans',
            burrito = 'vans',
            burrito2 = 'vans',
            burrito3 = 'vans',
            burrito4 = 'vans',
            burrito5 = 'vans',
            camper = 'vans',
            gb200 = 'vans',
            gangburrito = 'vans',
            journey = 'vans',
            minivan = 'vans',
            minivan2 = 'vans',
            moonbeam = 'vans',
            moonbeam2 = 'vans',
            paradise = 'vans',
            pony = 'vans',
            pony2 = 'vans',
            rumpo = 'vans',
            rumpo2 = 'vans',
            rumpo3 = 'vans',
            speedo = 'vans',
            speedo2 = 'vans',
            speedo4 = 'vans',
            surfer = 'vans',
            surfer2 = 'vans',
            taco = 'vans',
            youga = 'vans',
            youga2 = 'vans',
            youga3 = 'vans',

            --- Cycles
            bmx = 'cycles',
            cruiser = 'cycles',
            fixter = 'cycles',
            scorcher = 'cycles',
            tribike = 'cycles',
            tribike2 = 'cycles',
            tribike3 = 'cycles',

            --- Boats
            squalo = 'boats',
            marquis = 'boats',
            seashark = 'boats',
            seashark2 = 'boats',
            seashark3 = 'boats',
            jetmax = 'boats',
            tropic = 'boats',
            tropic2 = 'boats',
            dinghy = 'boats',
            dinghy2 = 'boats',
            dinghy3 = 'boats',
            dinghy4 = 'boats',
            suntrap = 'boats',
            speeder = 'boats',
            speeder2 = 'boats',
            longfin = 'boats',
            toro = 'boats',
            toro2 = 'boats',

            --- Helicopters
            buzzard2 = 'air',
            frogger = 'air',
            frogger2 = 'air',
            maverick = 'air',
            swift = 'air',
            swift2 = 'air',
            seasparrow = 'air',
            seasparrow2 = 'air',
            seasparrow3 = 'air',
            supervolito = 'air',
            supervolito2 = 'air',
            volatus = 'air',
            havok = 'air',

            --- Planes
            duster = 'air',
            luxor = 'air',
            luxor2 = 'air',
            stunt = 'air',
            mammatus = 'air',
            velum = 'air',
            velum2 = 'air',
            shamal = 'air',
            vestra = 'air',
            dodo = 'air',
            howard = 'air',
            alphaz1 = 'air',
            nimbus = 'air',
            conada = 'air',
            ]]
        },

        --- Tiered pricing for vehicle categories (multiplier applied to base price)
        pricing = {
            economy = 0.5,      -- 50% of base price (cheapest)
            compacts = 0.6,     -- 60% of base price
            sedans = 0.7,       -- 70% of base price
            coupes = 0.8,       -- 80% of base price
            cycles = 0.3,       -- 30% of base price (bicycles)
            motorcycles = 0.9,  -- 90% of base price
            muscle = 1.0,       -- 100% of base price (standard)
            sports = 1.2,       -- 120% of base price
            sportsclassics = 1.1, -- 110% of base price
            suvs = 1.0,         -- 100% of base price
            offroad = 1.1,      -- 110% of base price
            vans = 0.8,         -- 80% of base price
            super = 2.0,        -- 200% of base price (most expensive)
            boats = 1.5,        -- 150% of base price
            air = 2.5,          -- 250% of base price (aircraft)
            luxury = 3.0,       -- 300% of base price (luxury/exotic)
        },

        blocklist = {
            'police',
            'police2',
            'police3',
            'police4',
            '2015polstang',
        }
    },

    ---@type table<string, Dealership>
    shops = {
        pdm = {
            type = 'free-use',
            zone = {
                shape = {
                    vec3(-56.727394104004, -1086.2325439453, 26.0),
                    vec3(-60.612808227539, -1096.7795410156, 26.0),
                    vec3(-58.26834487915, -1100.572265625, 26.0),
                    vec3(-35.927803039551, -1109.0034179688, 26.0),
                    vec3(-34.427627563477, -1108.5111083984, 26.0),
                    vec3(-32.02657699585, -1101.5877685547, 26.0),
                    vec3(-33.342102050781, -1101.0377197266, 26.0),
                    vec3(-31.292987823486, -1095.3717041016, 26.0)
                },
                size = vec3(3, 3, 4),
                targetDistance = 1,
            },
            blip = {
                label = 'Premium Deluxe Motorsport',
                coords = vec3(-45.67, -1098.34, 26.42),
                show = true,
                sprite = 326,
                color = 3,
            },
            categories = {
                sportsclassics = 'Sports Classics',
                sedans = 'Sedans',
                coupes = 'Coupes',
                suvs = 'SUVs',
                offroad = 'Offroad',
                muscle = 'Muscle',
                compacts = 'Compacts',
                motorcycles = 'Motorcycles',
                vans = 'Vans',
                cycles = 'Bicycles'
            },
            testDrive = {
                limit = 5.0,
                endBehavior = 'return'
            },
            returnLocation = vec3(-32.77, -1095.75, 26.42),
            vehicleSpawns = {
                vec4(-61.35, -1110.31, 25.86, 71.01),
                vec4(-59.61, -1104.74, 25.85, 70.13),
                vec4(-52.96, -1113.49, 25.87, 71.53),
                vec4(-52.34, -1107.93, 25.87, 71.63),
                vec4(-44.27, -1116.36, 25.87, 71.7),
                vec4(-41.75, -1111.49, 25.87, 71.5),
            },
            showroomVehicles = {
                { coords = vec4(-45.65, -1093.66, 25.44, 69.5),   vehicle = 'tailgater' },
                { coords = vec4(-48.27, -1101.86, 25.44, 294.5), vehicle = 'felon' },
                { coords = vec4(-39.6,  -1096.01, 25.44, 66.5),  vehicle = 'sentinel2' },
                { coords = vec4(-51.21, -1096.77, 25.44, 254.5), vehicle = 'f620' },
                { coords = vec4(-40.18, -1104.13, 25.44, 338.5), vehicle = 'oracle2' },
                { coords = vec4(-43.31, -1099.02, 25.44, 52.5),  vehicle = 'windsor' },
                { coords = vec4(-50.66, -1093.05, 25.44, 222.5), vehicle = 'superd' },
                { coords = vec4(-44.28, -1102.47, 25.44, 298.5), vehicle = 'cognoscenti2' },
            },
        },

        -- New Economy Dealership - Budget vehicles
        economy = {
            type = 'free-use',
            zone = {
                shape = {
                    vec3(-45.0, -1080.0, 26.0),
                    vec3(-55.0, -1080.0, 26.0),
                    vec3(-55.0, -1090.0, 26.0),
                    vec3(-45.0, -1090.0, 26.0),
                },
                size = vec3(3, 3, 4),
                targetDistance = 1,
            },
            blip = {
                label = 'Budget Auto - Affordable Cars',
                coords = vec3(-50.0, -1085.0, 26.42),
                show = true,
                sprite = 225,
                color = 5,
            },
            categories = {
                compacts = 'Compacts',
                sedans = 'Sedans',
                cycles = 'Bicycles',
            },
            testDrive = {
                limit = 5.0,
                endBehavior = 'return'
            },
            returnLocation = vec3(-48.0, -1088.0, 26.42),
            vehicleSpawns = {
                vec4(-47.0, -1082.0, 25.86, 270.0),
                vec4(-52.0, -1082.0, 25.86, 270.0),
            },
            showroomVehicles = {
                { coords = vec4(-48.5, -1083.5, 25.44, 270.0), vehicle = 'blista' },
                { coords = vec4(-51.5, -1083.5, 25.44, 270.0), vehicle = 'panto' },
            },
        },

        -- New Sports Dealership - Sports and supercars
        sports = {
            type = 'free-use',
            zone = {
                shape = {
                    vec3(-1250.0, -350.0, 36.0),
                    vec3(-1270.0, -350.0, 36.0),
                    vec3(-1270.0, -370.0, 36.0),
                    vec3(-1250.0, -370.0, 36.0),
                },
                size = vec3(3, 3, 4),
                targetDistance = 1,
            },
            blip = {
                label = 'Legendary Motorsport',
                coords = vec3(-1260.0, -360.0, 36.91),
                show = true,
                sprite = 326,
                color = 7,
            },
            categories = {
                sports = 'Sports',
                super = 'Super Cars',
                sportsclassics = 'Sports Classics',
            },
            testDrive = {
                limit = 5.0,
                endBehavior = 'return'
            },
            returnLocation = vec3(-1255.0, -365.0, 37.33),
            vehicleSpawns = {
                vec4(-1260.0, -355.0, 37.33, 90.0),
                vec4(-1260.0, -360.0, 37.33, 90.0),
            },
            showroomVehicles = {
                { coords = vec4(-1258.0, -358.0, 36.91, 90.0), vehicle = 'elegy2' },
                { coords = vec4(-1262.0, -358.0, 36.91, 90.0), vehicle = 'nero' },
            },
        },

        -- New SUV & Offroad Dealership
        suv = {
            type = 'free-use',
            zone = {
                shape = {
                    vec3(1200.0, 2650.0, 38.0),
                    vec3(1220.0, 2650.0, 38.0),
                    vec3(1220.0, 2670.0, 38.0),
                    vec3(1200.0, 2670.0, 38.0),
                },
                size = vec3(3, 3, 4),
                targetDistance = 1,
            },
            blip = {
                label = 'Benny\'s 4x4 & Trucks',
                coords = vec3(1210.0, 2660.0, 38.55),
                show = true,
                sprite = 225,
                color = 25,
            },
            categories = {
                suvs = 'SUVs',
                offroad = 'Offroad',
                vans = 'Vans',
            },
            testDrive = {
                limit = 5.0,
                endBehavior = 'return'
            },
            returnLocation = vec3(1210.0, 2665.0, 38.55),
            vehicleSpawns = {
                vec4(1205.0, 2655.0, 37.55, 0.0),
                vec4(1215.0, 2655.0, 37.55, 0.0),
            },
            showroomVehicles = {
                { coords = vec4(1208.0, 2658.0, 37.55, 0.0), vehicle = 'landstalker2' },
                { coords = vec4(1212.0, 2658.0, 37.55, 0.0), vehicle = 'cavalcade2' },
            },
        },

        -- New Muscle Car Dealership
        muscle = {
            type = 'free-use',
            zone = {
                shape = {
                    vec3(100.0, 6620.0, 31.0),
                    vec3(120.0, 6620.0, 31.0),
                    vec3(120.0, 6640.0, 31.0),
                    vec3(100.0, 6640.0, 31.0),
                },
                size = vec3(3, 3, 4),
                targetDistance = 1,
            },
            blip = {
                label = 'Classic & Muscle Auto',
                coords = vec3(110.0, 6630.0, 31.75),
                show = true,
                sprite = 225,
                color = 44,
            },
            categories = {
                muscle = 'Muscle Cars',
            },
            testDrive = {
                limit = 5.0,
                endBehavior = 'return'
            },
            returnLocation = vec3(110.0, 6635.0, 31.75),
            vehicleSpawns = {
                vec4(105.0, 6625.0, 30.75, 180.0),
                vec4(115.0, 6625.0, 30.75, 180.0),
            },
            showroomVehicles = {
                { coords = vec4(108.0, 6628.0, 30.75, 180.0), vehicle = 'dominator5' },
                { coords = vec4(112.0, 6628.0, 30.75, 180.0), vehicle = 'gauntlet5' },
            },
        },

        -- New Motorcycle Dealership
        motorcycles = {
            type = 'free-use',
            zone = {
                shape = {
                    vec3(200.0, -1000.0, 29.0),
                    vec3(220.0, -1000.0, 29.0),
                    vec3(220.0, -1020.0, 29.0),
                    vec3(200.0, -1020.0, 29.0),
                },
                size = vec3(3, 3, 4),
                targetDistance = 1,
            },
            blip = {
                label = 'Southside Speed & Cycles',
                coords = vec3(210.0, -1010.0, 29.42),
                show = true,
                sprite = 226,
                color = 46,
            },
            categories = {
                motorcycles = 'Motorcycles',
            },
            testDrive = {
                limit = 5.0,
                endBehavior = 'return'
            },
            returnLocation = vec3(210.0, -1015.0, 29.42),
            vehicleSpawns = {
                vec4(205.0, -1005.0, 28.42, 90.0),
                vec4(215.0, -1005.0, 28.42, 90.0),
            },
            showroomVehicles = {
                { coords = vec4(208.0, -1008.0, 28.42, 90.0), vehicle = 'hakuchou2' },
                { coords = vec4(212.0, -1008.0, 28.42, 90.0), vehicle = 'bati2' },
            },
        },

        -- an example of a managed dealership. You can only buy vehicles here if someone with the job "cardealer" is operating it.
        -- Coordinates are perfectly setup for https://forum.cfx.re/t/mlo-car-dealer/1983229
        -- luxury = {
        --     type = 'managed',
        --     job = 'cardealer',
        --     zone = {
        --         shape = {
        --             vec3(-1260.6973876953, -349.21334838867, 36.91),
        --             vec3(-1268.6248779297, -352.87365722656, 36.91),
        --             vec3(-1274.1533203125, -358.29794311523, 36.91),
        --             vec3(-1273.8425292969, -362.73715209961, 36.91),
        --             vec3(-1270.5701904297, -368.6716003418, 36.91),
        --             vec3(-1266.0561523438, -375.14080810547, 36.91),
        --             vec3(-1244.3684082031, -362.70278930664, 36.91),
        --             vec3(-1249.8704833984, -352.03326416016, 36.91),
        --             vec3(-1252.9503173828, -345.85726928711, 36.91)
        --         },
        --         size = vec3(3, 3, 4),
        --         targetDistance = 1,
        --     },
        --     blip = {
        --         label = 'Luxury Vehicle Shop',
        --         coords = vec3(-1255.6, -361.16, 36.91),
        --         show = true,
        --         sprite = 326,
        --         color = 3,
        --     },
        --     categories = {
        --         super = 'Super',
        --         sports = 'Sports'
        --     },
        --     testDrive = {
        --         limit = 5.0,
        --         endBehavior = 'return'
        --     },
        --     returnLocation = vec3(-1231.46, -349.86, 37.33),
        --     vehicleSpawns = {
        --         vec4(-1231.46, -349.86, 37.33, 26.61),
        --     },
        --     showroomVehicles = {
        --         { coords = vec4(-1265.31, -354.44, 35.91, 205.08), vehicle = 'italirsx' },
        --         { coords = vec4(-1270.06, -358.55, 35.91, 247.08), vehicle = 'italigtb' },
        --         { coords = vec4(-1269.21, -365.03, 35.91, 297.12), vehicle = 'nero' },
        --         { coords = vec4(-1252.07, -364.2, 35.91, 56.44), vehicle = 'nero2' },
        --         { coords = vec4(-1255.49, -365.91, 35.91, 55.63), vehicle = 'osiris' },
        --         { coords = vec4(-1249.21, -362.97, 35.91, 53.24), vehicle = 'penetrator' },
        --     }
        -- },

        boats = {
            type = 'free-use',
            zone = {
                shape = {
                    vec3(-729.39, -1315.84, 0),
                    vec3(-766.81, -1360.11, 0),
                    vec3(-754.21, -1371.49, 0),
                    vec3(-716.94, -1326.88, 0)
                },
                size = vec3(8, 8, 6),
                targetDistance = 10,
            },
            blip = {
                label = 'Marina Shop',
                coords = vec3(-738.25, -1334.38, 1.6),
                show = true,
                sprite = 410,
                color = 3,
            },
            categories = {
                boats = 'Boats'
            },
            testDrive = {
                limit = 5.0,
                endBehavior = 'return'
            },
            returnLocation = vec3(-714.34, -1343.31, 0.0),
            vehicleSpawns = {
                vec4(-727.87, -1353.1, -0.17, 137.09),
            },
            showroomVehicles = {
                { coords = vec4(-727.05, -1326.59, -0.50, 229.5), vehicle = 'seashark' },
                { coords = vec4(-732.84, -1333.5, -0.50, 229.5), vehicle = 'dinghy' },
                { coords = vec4(-737.84, -1340.83, -0.50, 229.5), vehicle = 'speeder' },
                { coords = vec4(-741.53, -1349.7, -0.50, 229.5), vehicle = 'marquis' },
            },
        },

        air = {
            type = 'free-use',
            zone = {
                shape = {
                    vec3(-1607.58, -3141.7, 12.99),
                    vec3(-1672.54, -3103.87, 12.99),
                    vec3(-1703.49, -3158.02, 12.99),
                    vec3(-1646.03, -3190.84, 12.99)
                },
                size = vec3(10, 10, 8),
                targetDistance = 5,
            },
            blip = {
                label = 'Air Shop',
                coords = vec3(-1652.76, -3143.4, 13.99),
                show = true,
                sprite = 251,
                color = 3,
            },
            categories = {
                helicopters = 'Helicopters',
                planes = 'Planes'
            },
            testDrive = {
                limit = 5.0,
                endBehavior = 'return'
            },
            returnLocation = vec3(-1628.44, -3104.7, 13.94),
            vehicleSpawns = {
                vec4(-1617.49, -3086.17, 13.94, 329.2),
            },
            showroomVehicles = {
                { coords = vec4(-1651.36, -3162.66, 12.99, 346.89), vehicle = 'volatus' },
                { coords = vec4(-1668.53, -3152.56, 12.99, 303.22), vehicle = 'luxor2' },
                { coords = vec4(-1632.02, -3144.48, 12.99, 31.08), vehicle = 'nimbus' },
                { coords = vec4(-1663.74, -3126.32, 12.99, 275.03), vehicle = 'frogger' },
            },
        },
    },
}