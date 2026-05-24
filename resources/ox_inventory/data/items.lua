return {
	['testburger'] = {
		label = 'Test Burger',
		weight = 220,
		degrade = 60,
		client = {
			image = 'burger_chicken.png',
			status = { hunger = 200000 },
			anim = 'eating',
			prop = 'burger',
			usetime = 2500,
			export = 'ox_inventory_examples.testburger'
		},
		server = {
			export = 'ox_inventory_examples.testburger',
			test = 'what an amazingly delicious burger, amirite?'
		},
		buttons = {
			{
				label = 'Lick it',
				action = function(slot)
					print('You licked the burger')
				end
			},
			{
				label = 'Squeeze it',
				action = function(slot)
					print('You squeezed the burger :(')
				end
			},
			{
				label = 'What do you call a vegan burger?',
				group = 'Hamburger Puns',
				action = function(slot)
					print('A misteak.')
				end
			},
			{
				label = 'What do frogs like to eat with their hamburgers?',
				group = 'Hamburger Puns',
				action = function(slot)
					print('French flies.')
				end
			},
			{
				label = 'Why were the burger and fries running?',
				group = 'Hamburger Puns',
				action = function(slot)
					print('Because they\'re fast food.')
				end
			}
		},
		consume = 0.3
	},

	['bandage'] = {
		label = 'Bandage',
		weight = 115,
		client = {
			anim = { dict = 'missheistdockssetup1clipboard@idle_a', clip = 'idle_a', flag = 49 },
			prop = { model = `prop_rolled_sock_02`, pos = vec3(-0.14, -0.14, -0.08), rot = vec3(-50.0, -50.0, 0.0) },
			disable = { move = true, car = true, combat = true },
			usetime = 2500,
		}
	},

	['black_money'] = {
		label = 'Dirty Money',
	},

	['burger'] = {
		label = 'Burger',
		weight = 220,
		client = {
			status = { hunger = 200000 },
			anim = 'eating',
			prop = 'burger',
			usetime = 2500,
			notification = 'You ate a delicious burger'
		},
	},

	['sprunk'] = {
		label = 'Sprunk',
		weight = 350,
		client = {
			status = { thirst = 200000 },
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_ld_can_01`, pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
			usetime = 2500,
			notification = 'You quenched your thirst with a sprunk'
		}
	},

	-- Used by `data/shops.lua` (General / Liquor); distinct from `kurkakola` in items_from_qb.lua
	['cola'] = {
		label = 'Cola',
		weight = 350,
		client = {
			status = { thirst = 200000 },
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_ecola_can`, pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
			usetime = 2500,
			notification = 'You drank a cola'
		}
	},

	['medikit'] = {
		label = 'Medikit',
		weight = 2200,
		client = {
			anim = { dict = 'missheistdockssetup1clipboard@idle_a', clip = 'idle_a', flag = 49 },
			disable = { move = true, car = true, combat = true },
			usetime = 5000,
		}
	},

	['parachute'] = {
		label = 'Parachute',
		weight = 8000,
		stack = false,
		client = {
			anim = { dict = 'clothingshirt', clip = 'try_shirt_positive_d' },
			usetime = 1500
		}
	},

	['garbage'] = {
		label = 'Garbage',
	},

	['paperbag'] = {
		label = 'Paper Bag',
		weight = 1,
		stack = false,
		close = false,
		consume = 0
	},

	['identification'] = {
		label = 'Identification',
		client = {
			image = 'card_id.png'
		}
	},

	['panties'] = {
		label = 'Knickers',
		weight = 10,
		consume = 0,
		client = {
			status = { thirst = -100000, stress = -25000 },
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_cs_panties_02`, pos = vec3(0.03, 0.0, 0.02), rot = vec3(0.0, -13.5, -1.5) },
			usetime = 2500,
		}
	},

	['lockpick'] = {
		label = 'Lockpick',
		weight = 160,
	},
	['advancedlockpick'] = {
		label = 'Advanced Lockpick',
		weight = 200,
	},
	['thermite'] = {
		label = 'Thermite',
		weight = 500,
		client = {
			anim = { dict = 'missheistdockssetup1clipboard@idle_a', clip = 'idle_a', flag = 49 },
			prop = { model = `prop_rolled_sock_02`, pos = vec3(-0.14, -0.14, -0.08), rot = vec3(-50.0, -50.0, 0.0) },
			disable = { move = true, car = true, combat = true },
			usetime = 2500,
		}
	},
	['drill'] = {
		label = 'Drill',
		weight = 1500,
		client = {
			anim = { dict = 'anim@amb@mechanic@male@base', clip = 'base_idle_1', flag = 49 },
			prop = { model = `prop_tool_drill`, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
			disable = { move = true, car = true, combat = true },
			usetime = 15000,
		}
	},
	['c4'] = {
		label = 'C4 Plastic',
		weight = 300,
		client = {
			anim = { dict = 'anim@amb@mechanic@male@base', clip = 'base_idle_1', flag = 49 },
			prop = { model = `prop_c4_final`, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
			disable = { move = true, car = true, combat = true },
			usetime = 5000,
		}
	},
	['bankdrill'] = {
		label = 'Bank Drill',
		weight = 2000,
		client = {
			anim = { dict = 'anim@amb@mechanic@male@base', clip = 'base_idle_1', flag = 49 },
			prop = { model = `prop_tool_drill`, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
			disable = { move = true, car = true, combat = true },
			usetime = 20000,
		}
	},
	['heistdrill'] = {
		label = 'Heist Drill',
		weight = 2500,
		client = {
			anim = { dict = 'anim@amb@mechanic@male@base', clip = 'base_idle_1', flag = 49 },
			prop = { model = `prop_tool_drill`, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
			disable = { move = true, car = true, combat = true },
			usetime = 25000,
		}
	},
	['screwdriver'] = {
		label = 'Screwdriver',
		weight = 100,
		client = {
			anim = { dict = 'anim@amb@mechanic@male@base', clip = 'base_idle_1', flag = 49 },
			prop = { model = `prop_tool_screwdriver`, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
			disable = { move = true, car = true, combat = true },
			usetime = 5000,
		}
	},
	['laptop'] = {
		label = 'Laptop',
		weight = 1500,
		client = {
			anim = { dict = 'anim@amb@office@laptops@male@', clip = 'laptop_typing', flag = 49 },
			prop = { model = `prop_laptop_01_closed`, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
			disable = { move = true, car = true, combat = true },
			usetime = 10000,
		}
	},
	['hacking_device'] = {
		label = 'Hacking Device',
		weight = 800,
		client = {
			anim = { dict = 'anim@amb@office@laptops@male@', clip = 'laptop_typing', flag = 49 },
			prop = { model = `prop_laptop_01_closed`, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
			disable = { move = true, car = true, combat = true },
			usetime = 15000,
		}
	},
	['gps'] = {
		label = 'GPS',
		weight = 200,
		client = {
			anim = { dict = 'amb@code_human_in_bus_passenger_idles@female@tablet@', clip = 'idle_a', flag = 49 },
			prop = { model = `prop_cs_tablet`, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
			disable = { move = false, car = false, combat = false },
			usetime = 2000,
		}
	},
	['binoculars'] = {
		label = 'Binoculars',
		weight = 600,
		client = {
			anim = { dict = 'amb@world_human_binoculars@male@idle_a', clip = 'idle_c', flag = 49 },
			prop = { model = `prop_binoc_01`, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
			disable = { move = false, car = false, combat = false },
			usetime = 3000,
		}
	},
	['camera'] = {
		label = 'Camera',
		weight = 500,
		client = {
			anim = { dict = 'amb@world_human_paparazzi@male@base', clip = 'base', flag = 49 },
			prop = { model = `prop_pap_camera_01`, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
			disable = { move = false, car = false, combat = false },
			usetime = 2000,
		}
	},
	['car_key'] = {
		label = 'Car Key',
		weight = 50,
		stack = false,
	},
	['lockpick_kit'] = {
		label = 'Lockpick Kit',
		weight = 500,
		client = {
			anim = { dict = 'anim@amb@mechanic@male@base', clip = 'base_idle_1', flag = 49 },
			prop = { model = `prop_tool_box_04`, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
			disable = { move = true, car = true, combat = true },
			usetime = 8000,
		}
	},
	['firstaid'] = {
		label = 'First Aid Kit',
		weight = 500,
		client = {
			anim = { dict = 'missheistdockssetup1clipboard@idle_a', clip = 'idle_a', flag = 49 },
			prop = { model = `prop_med_bag_01b`, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
			disable = { move = true, car = true, combat = true },
			usetime = 5000,
		}
	},
	['ifaks'] = {
		label = 'IFAK',
		weight = 300,
		client = {
			anim = { dict = 'missheistdockssetup1clipboard@idle_a', clip = 'idle_a', flag = 49 },
			prop = { model = `prop_med_bag_01b`, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
			disable = { move = true, car = true, combat = true },
			usetime = 3000,
		}
	},
	['painkillers'] = {
		label = 'Painkillers',
		weight = 50,
		client = {
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle', flag = 49 },
			prop = { model = `prop_pill_bottle_01`, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
			disable = { move = true, car = true, combat = true },
			usetime = 2000,
		}
	},
	['sandwich'] = {
		label = 'Sandwich',
		weight = 200,
		client = {
			status = { hunger = 300000 },
			anim = 'eating',
			prop = 'sandwich',
			usetime = 3000,
			notification = 'You ate a delicious sandwich'
		}
	},
	['chips'] = {
		label = 'Chips',
		weight = 100,
		client = {
			status = { hunger = 100000 },
			anim = 'eating',
			prop = 'chips',
			usetime = 2000,
			notification = 'You ate some chips'
		}
	},
	['chocolate'] = {
		label = 'Chocolate Bar',
		weight = 80,
		client = {
			status = { hunger = 50000 },
			anim = 'eating',
			prop = 'chocolate',
			usetime = 2000,
			notification = 'You ate a chocolate bar'
		}
	},
	['coffee'] = {
		label = 'Coffee',
		weight = 100,
		client = {
			status = { thirst = 200000 },
			anim = { dict = 'amb@world_human_aa_coffee@male@idle_a', clip = 'idle_a', flag = 49 },
			prop = { model = `prop_fib_coffee`, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
			usetime = 3000,
			notification = 'You drank coffee'
		}
	},
	['cigarette'] = {
		label = 'Cigarettes',
		weight = 50,
		client = {
			anim = { dict = 'amb@world_human_smoking@male@idle_a', clip = 'idle_c', flag = 49 },
			prop = { model = `prop_cs_ciggy_01`, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
			usetime = 3000,
		}
	},
	['lighter'] = {
		label = 'Lighter',
		weight = 30,
		client = {
			anim = { dict = 'amb@world_human_smoking@male@lighter', clip = 'lighter', flag = 49 },
			prop = { model = `prop_cs_lighter_01`, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
			usetime = 1000,
		}
	},
	['energy_drink'] = {
		label = 'Energy Drink',
		weight = 150,
		client = {
			status = { thirst = 250000 },
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle', flag = 49 },
			prop = { model = `prop_energy_drink`, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
			usetime = 3000,
			notification = 'You drank an energy drink'
		}
	},
	['ice_cream'] = {
		label = 'Ice Cream',
		weight = 100,
		client = {
			status = { thirst = 100000 },
			anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger', flag = 49 },
			prop = { model = `prop_cs_ice_cream`, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
			usetime = 3000,
			notification = 'You ate ice cream'
		}
	},
	['beer'] = {
		label = 'Beer',
		weight = 300,
		client = {
			status = { thirst = 200000 },
			anim = { dict = 'amb@world_human_drinking@male@idle_a', clip = 'idle_c', flag = 49 },
			prop = { model = `prop_beer_bottle`, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
			usetime = 3000,
			notification = 'You drank a beer'
		}
	},
	['wine'] = {
		label = 'Wine',
		weight = 300,
		client = {
			status = { thirst = 200000 },
			anim = { dict = 'amb@world_human_drinking@male@idle_a', clip = 'idle_c', flag = 49 },
			prop = { model = `prop_wine_bot_01`, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
			usetime = 3000,
			notification = 'You drank wine'
		}
	},
	['whiskey'] = {
		label = 'Whiskey',
		weight = 300,
		client = {
			status = { thirst = 200000 },
			anim = { dict = 'amb@world_human_drinking@male@idle_a', clip = 'idle_c', flag = 49 },
			prop = { model = `prop_whiskey_bottle`, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
			usetime = 3000,
			notification = 'You drank whiskey'
		}
	},
	['vodka'] = {
		label = 'Vodka',
		weight = 300,
		client = {
			status = { thirst = 200000 },
			anim = { dict = 'amb@world_human_drinking@male@idle_a', clip = 'idle_c', flag = 49 },
			prop = { model = `prop_vodka_bottle`, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
			usetime = 3000,
			notification = 'You drank vodka'
		}
	},
	['fishingrod'] = {
		label = 'Fishing Rod',
		weight = 800,
		client = {
			anim = { dict = 'amb@world_human_fishing@idle_a', clip = 'idle_c', flag = 49 },
			prop = { model = `prop_fishing_rod_01`, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
			disable = { move = false, car = false, combat = false },
			usetime = 3000,
		}
	},
	['fishbait'] = {
		label = 'Fishing Bait',
		weight = 50,
	},
	['fishcontainer'] = {
		label = 'Fish Container',
		weight = 200,
		client = {
			anim = { dict = 'anim@heists@narcotics@trash', clip = 'walk', flag = 49 },
			prop = { model = `prop_cs_crate_01`, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
			disable = { move = true, car = true, combat = true },
			usetime = 2000,
		}
	},
	['mosleyssideglass'] = {
		label = 'Mosleys Side Glass',
		weight = 500,
		client = {
			anim = { dict = 'anim@amb@mechanic@male@base', clip = 'base_idle_1', flag = 49 },
			prop = { model = `prop_car_side_glass_r`, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
			disable = { move = true, car = true, combat = true },
			usetime = 5000,
		}
	},
	['mosleysliv'] = {
		label = 'Mosleys LIV',
		weight = 600,
		client = {
			anim = { dict = 'anim@amb@mechanic@male@base', clip = 'base_idle_1', flag = 49 },
			prop = { model = `prop_car_liv_r`, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
			disable = { move = true, car = true, combat = true },
			usetime = 6000,
		}
	},
	['mosleyshorn'] = {
		label = 'Mosleys Horn',
		weight = 400,
		client = {
			anim = { dict = 'anim@amb@mechanic@male@base', clip = 'base_idle_1', flag = 49 },
			prop = { model = `prop_car_horn_r`, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
			disable = { move = true, car = true, combat = true },
			usetime = 4000,
		}
	},
	['ac_broken'] = {
		label = 'Broken AC Unit',
		weight = 800,
		client = {
			anim = { dict = 'anim@amb@mechanic@male@base', clip = 'base_idle_1', flag = 49 },
			prop = { model = `prop_aircon_s_04a`, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
			disable = { move = true, car = true, combat = true },
			usetime = 8000,
		}
	},
	['ac_compressor'] = {
		label = 'AC Compressor',
		weight = 600,
		client = {
			anim = { dict = 'anim@amb@mechanic@male@base', clip = 'base_idle_1', flag = 49 },
			prop = { model = `prop_aircon_s_03a`, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
			disable = { move = true, car = true, combat = true },
			usetime = 6000,
		}
	},
	['ac'] = {
		label = 'AC Unit',
		weight = 800,
		client = {
			anim = { dict = 'anim@amb@mechanic@male@base', clip = 'base_idle_1', flag = 49 },
			prop = { model = `prop_aircon_s_01a`, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
			disable = { move = true, car = true, combat = true },
			usetime = 8000,
		}
	},
	['ac_vent'] = {
		label = 'AC Vent',
		weight = 300,
		client = {
			anim = { dict = 'anim@amb@mechanic@male@base', clip = 'base_idle_1', flag = 49 },
			prop = { model = `prop_aircon_01_vent`, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
			disable = { move = true, car = true, combat = true },
			usetime = 3000,
		}
	},
	['handcuffs'] = {
		label = 'Handcuffs',
		weight = 200,
		client = {
			anim = { dict = 'mp_arresting', clip = 'a_uncuff', flag = 49 },
			prop = { model = `prop_cs_handcuffs_01`, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
			disable = { move = true, car = true, combat = true },
			usetime = 3000,
		}
	},
	['police_stormram'] = {
		label = 'Police Storm Ram',
		weight = 1800,
		client = {
			anim = { dict = 'anim@heists@keycard@', clip = 'idle_a', flag = 49 },
			prop = { model = `prop_tool_broom2`, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
			disable = { move = true, car = true, combat = true },
			usetime = 8000,
		}
	},
	['armor'] = {
		label = 'Body Armor',
		weight = 1000,
		client = {
			anim = { dict = 'clothingtie', clip = 'try_tie_positive_a', flag = 49 },
			prop = { model = `prop_armour_pickup`, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
			disable = { move = true, car = true, combat = true },
			usetime = 5000,
		}
	},
	['heavyarmor'] = {
		label = 'Heavy Body Armor',
		weight = 1500,
		client = {
			anim = { dict = 'clothingtie', clip = 'try_tie_positive_a', flag = 49 },
			prop = { model = `prop_armour_pickup`, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
			disable = { move = true, car = true, combat = true },
			usetime = 8000,
		}
	},
	['flashlight'] = {
		label = 'Flashlight',
		weight = 300,
		client = {
			anim = { dict = 'missheistdockssetup1', clip = 'flashlight_hands_up_a', flag = 49 },
			prop = { model = `prop_cs_flashlight`, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
			disable = { move = false, car = false, combat = false },
			usetime = 2000,
		}
	},
	['tazer'] = {
		label = 'Tazer',
		weight = 800,
		client = {
			anim = { dict = 'weapons@pistol@single', clip = 'single_aim', flag = 49 },
			prop = { model = `w_pi_stungun`, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
			disable = { move = false, car = false, combat = false },
			usetime = 2000,
		}
	},
	['nightstick'] = {
		label = 'Nightstick',
		weight = 500,
		client = {
			anim = { dict = 'weapons@melee@nightstick', clip = 'idle', flag = 49 },
			prop = { model = `w_me_nightstick`, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
			disable = { move = false, car = false, combat = false },
			usetime = 2000,
		}
	},
	['id_card'] = {
		label = 'ID Card',
		weight = 50,
		client = {
			image = 'card_id.png'
		}
	},
	['driver_license'] = {
		label = 'Driver License',
		weight = 50,
		client = {
			image = 'card_driver.png'
		}
	},
	['weapon_license'] = {
		label = 'Weapon License',
		weight = 50,
		client = {
			image = 'card_weapon.png'
		}
	},
	['lawyerpass'] = {
		label = 'Lawyer Pass',
		weight = 50,
		client = {
			image = 'card_lawyer.png'
		}
	},
	['workout_ticket'] = {
		label = 'Gym Ticket',
		weight = 20,
	},
	['markedbills'] = {
		label = 'Marked Bills',
		weight = 0,
		stack = false,
		close = false,
		consume = 0
	},

	['phone'] = {
		label = 'Phone',
		weight = 190,
		stack = false,
		consume = 0,
		client = {
			add = function(total)
				if total > 0 then
					pcall(function() return exports.npwd:setPhoneDisabled(false) end)
				end
			end,

			remove = function(total)
				if total < 1 then
					pcall(function() return exports.npwd:setPhoneDisabled(true) end)
				end
			end
		}
	},

	['money'] = {
		label = 'Money',
	},

	['mustard'] = {
		label = 'Mustard',
		weight = 500,
		client = {
			status = { hunger = 25000, thirst = 25000 },
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_food_mustard`, pos = vec3(0.01, 0.0, -0.07), rot = vec3(1.0, 1.0, -1.5) },
			usetime = 2500,
			notification = 'You.. drank mustard'
		}
	},

	['water'] = {
		label = 'Water',
		weight = 500,
		client = {
			status = { thirst = 200000 },
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_ld_flow_bottle`, pos = vec3(0.03, 0.03, 0.02), rot = vec3(0.0, 0.0, -1.5) },
			usetime = 2500,
			cancel = true,
			notification = 'You drank some refreshing water'
		}
	},

	['radio'] = {
		label = 'Radio',
		weight = 1000,
		stack = false,
		allowArmed = true
	},

	['armour'] = {
		label = 'Bulletproof Vest',
		weight = 3000,
		stack = false,
		client = {
			anim = { dict = 'clothingshirt', clip = 'try_shirt_positive_d' },
			usetime = 3500
		}
	},

	['clothing'] = {
		label = 'Clothing',
		consume = 0,
	},

	['mastercard'] = {
		label = 'Fleeca Card',
		stack = false,
		weight = 10,
		client = {
			image = 'card_bank.png'
		}
	},

	['scrapmetal'] = {
		label = 'Scrap Metal',
		weight = 80,
	},

	-- Qbox/QBX cityhall identity documents (created by qbx_idcard + qbx_cityhall)
	['id_card'] = {
		label = 'Identification Card',
		weight = 1,
		stack = false,
	},

	['driver_license'] = {
		label = "Driver License",
		weight = 1,
		stack = false,
	},

	['weaponlicense'] = {
		label = 'Weapon License',
		weight = 1,
		stack = false,
	},

	-- Rup Fishing
	['fishingrod'] = {
		label = 'Fishing Rod',
		weight = 800,
		stack = true,
		close = true,
		client = { export = 'Rup-Fishing.useRod' }
	},
	['fishbait'] = {
		label = 'Fishing Bait',
		weight = 50,
		stack = true,
		close = false,
		description = 'Use this to start fishing',
	},
	['swordfish'] = { label = 'Swordfish', weight = 200, stack = true, close = false, description = 'A Swordfish caught fishing' },
	['mahimahi'] = { label = 'Mahi Mahi', weight = 200, stack = true, close = false, description = 'A Mahi Mahi caught fishing' },
	['marlin'] = { label = 'Marlin', weight = 200, stack = true, close = false, description = 'A Marlin caught fishing' },
	['tuna'] = { label = 'Tuna', weight = 200, stack = true, close = false, description = 'A Tuna caught fishing' },
	['salmon'] = { label = 'Salmon', weight = 200, stack = true, close = false, description = 'A Salmon caught fishing' },
	['mackerel'] = { label = 'Mackerel', weight = 200, stack = true, close = false, description = 'A Mackerel caught fishing' },
	['trout'] = { label = 'Trout', weight = 200, stack = true, close = false, description = 'A Trout caught fishing' },
	['cod'] = { label = 'Cod', weight = 200, stack = true, close = false, description = 'A Cod caught fishing' },
	['carp'] = { label = 'Carp', weight = 200, stack = true, close = false, description = 'A Carp caught fishing' },
	['walleye'] = { label = 'Walleye', weight = 200, stack = true, close = false, description = 'A Walleye caught fishing' },
	['catfish'] = { label = 'Catfish', weight = 200, stack = true, close = false, description = 'A Catfish caught fishing' },
	['bass'] = { label = 'Bass', weight = 200, stack = true, close = false, description = 'A Bass caught fishing' },
	['perch'] = { label = 'Perch', weight = 200, stack = true, close = false, description = 'A Perch caught fishing' },
	['crappie'] = { label = 'Crappie', weight = 200, stack = true, close = false, description = 'A Crappie caught fishing' },
	['bluegill'] = { label = 'Bluegill', weight = 200, stack = true, close = false, description = 'A Bluegill caught fishing' },
	['talapia'] = { label = 'Talapia', weight = 200, stack = true, close = false, description = 'A Talapia caught fishing' },
	['fishbag'] = { label = 'Bag (Fishing)', weight = 200, stack = true, close = false, description = 'A bag found while fishing' },
	['fishshoe'] = { label = 'Old Shoe', weight = 200, stack = true, close = false, description = 'An old shoe found while fishing' },

	-- SM Hunting
	['meat'] = { label = 'Raw Meat', weight = 300, stack = true, close = false, description = 'Raw meat from hunting' },
	['leather'] = { label = 'Leather', weight = 200, stack = true, close = false, description = 'Leather from hunting' },
	['feathers'] = { label = 'Feathers', weight = 50, stack = true, close = false, description = 'Feathers from hunting' },

	-- Jim-Recycle
	['can'] = { label = 'Empty Can', weight = 50, stack = true, close = false, description = 'A crushed empty can' },
	['bottle'] = { label = 'Empty Bottle', weight = 80, stack = true, close = false, description = 'An empty glass/plastic bottle' },
	['recyclablematerial'] = { label = 'Recyclable Material', weight = 100, stack = true, close = false, description = 'Mixed recyclable materials' },
	['plastic'] = { label = 'Plastic', weight = 50, stack = true, close = false, description = 'Recycled plastic chunks' },
	['metalscrap'] = { label = 'Metal Scrap', weight = 150, stack = true, close = false, description = 'Recycled scrap metal' },
	['aluminum'] = { label = 'Aluminum', weight = 100, stack = true, close = false, description = 'Recycled aluminum' },

	-- ========== CUSTOM WEAPONS BY LESIIN ==========
	['weapon_ak47'] = {
		label = 'AK-47',
		weight = 13000,
		stack = false,
		close = true,
		description = 'A rapid-fire assault rifle',
		decay = 30.0,
	},
	['weapon_ar15'] = {
		label = 'AR-15',
		weight = 13000,
		stack = false,
		close = true,
		description = 'A modern assault rifle',
		decay = 30.0,
	},
	['weapon_deserteagle'] = {
		label = 'Desert Eagle',
		weight = 13000,
		stack = false,
		close = true,
		description = 'A powerful handgun',
		decay = 30.0,
	},
	['weapon_fnfnx45'] = {
		label = 'FN FNX45',
		weight = 13000,
		stack = false,
		close = true,
		description = 'A reliable pistol',
		decay = 30.0,
	},
	['weapon_glock17'] = {
		label = 'Glock 17',
		weight = 13000,
		stack = false,
		close = true,
		description = 'A popular service pistol',
		decay = 30.0,
	},
	['weapon_huntingrifle'] = {
		label = 'Hunting Rifle',
		weight = 13000,
		stack = false,
		close = true,
		description = 'A hunting rifle',
		decay = 30.0,
	},
	['weapon_m1911'] = {
		label = 'M1911',
		weight = 13000,
		stack = false,
		close = true,
		description = 'A classic pistol',
		decay = 30.0,
	},
	['weapon_m4'] = {
		label = 'M4',
		weight = 13000,
		stack = false,
		close = true,
		description = 'A versatile assault rifle',
		decay = 30.0,
	},
	['weapon_m70'] = {
		label = 'M70',
		weight = 13000,
		stack = false,
		close = true,
		description = 'A battle rifle',
		decay = 30.0,
	},
	['weapon_m9a3'] = {
		label = 'M9A3',
		weight = 13000,
		stack = false,
		close = true,
		description = 'A modern pistol',
		decay = 30.0,
	},
	['weapon_mac10'] = {
		label = 'MAC-10',
		weight = 13000,
		stack = false,
		close = true,
		description = 'A compact submachine gun',
		decay = 30.0,
	},
	['weapon_mk14'] = {
		label = 'MK14',
		weight = 13000,
		stack = false,
		close = true,
		description = 'A marksman rifle',
		decay = 30.0,
	},
	['weapon_mossberg500'] = {
		label = 'Mossberg 500',
		weight = 13000,
		stack = false,
		close = true,
		description = 'A reliable shotgun',
		decay = 30.0,
	},
	['weapon_remington870'] = {
		label = 'Remington 870',
		weight = 13000,
		stack = false,
		close = true,
		description = 'A classic shotgun',
		decay = 30.0,
	},
	['weapon_scarh'] = {
		label = 'SCAR-H',
		weight = 13000,
		stack = false,
		close = true,
		description = 'A modern battle rifle',
		decay = 30.0,
	},
	['weapon_shiv'] = {
		label = 'Shiv',
		weight = 13000,
		stack = false,
		close = true,
		description = 'A improvised weapon',
		decay = 30.0,
	},
	['weapon_uzi'] = {
		label = 'UZI',
		weight = 13000,
		stack = false,
		close = true,
		description = 'A classic submachine gun',
		decay = 30.0,
	},
}
