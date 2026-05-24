Config = {
	locale = "en",
	framework = "qb", -- "none", "esx" or "qb"
	inventory = "ox_inventory", -- "esx", "qb", "qb-inventory", "core", "qs", "tgiann", "ox_inventory", "codem" (if your inventory doesn't work try to set it to "esx" for esx or "qb" for qb)
	targetSystem = "none", -- "none", "qtarget", "qb-target" etc.
	maxSlots = 6, -- max slots for bodyguards
	maxBackups = 5, -- max amount of backup peds
	speedMetric = "KM/H", -- "KM/H" or "MPH"
	priceDeduction = { percent = 0.8, onDay = 7 }, -- price deduction
	currency = "$",
	enableBodyguardPlayerDamage = true, -- enable bodyguard player damage (to other players)
	enableBodyguardFriendlyFire = false, -- enable bodyguard friendly fire
	debug = false, -- enable debug mode
	policeJobs = {
		"police",
	},

	playersProvideWeapons = false, -- otherwise you can purchase weapons for them inside the shop
	weaponModels = { -- weapons that can be purchased (if playersProvideWeapons is false)
		{ weapon = "WEAPON_UNARMED", price = 0 }, -- price is per day
		{ weapon = "WEAPON_PISTOL", price = 500 }, -- price is per day
		{ weapon = "WEAPON_ASSAULTRIFLE", price = 1500 },
		{ weapon = "WEAPON_MICROSMG", price = 750 },
		{ weapon = "WEAPON_ASSAULTSMG", price = 1000 },
	},

	-- allowed weapons to be given to bodyguards and their item ammo name (if playersProvideWeapons is true)
	weaponConfiguration = {
		WEAPON_PISTOL = { ammoName = "AMMO-9" },
		WEAPON_ASSAULTRIFLE = { ammoName = "AMMO-RIFLE2" },
		WEAPON_MICROSMG = { ammoName = "AMMO-45" },
		WEAPON_ASSAULTSMG = { ammoName = "AMMO-RIFLE" },
	},

	-- allowed models for street recruitment (you can add more models if you want)
	acceptedModelsForStreetRecruitment = {
		[`g_m_y_famca_01`] = true,
		[`g_m_y_mexgoon_01`] = true,
		[`g_m_y_ballaorig_01`] = true,
		[`g_f_y_families_01`] = true,
		[`g_m_y_famfor_01`] = true,
		[`g_m_y_lost_01`] = true,
		[`g_m_y_lost_02`] = true,
		[`g_m_y_lost_03`] = true,
		[`g_m_y_mexgoon_02`] = true,
		[`g_m_y_salvaboss_01`] = true,
		[`g_m_y_salvagoon_01`] = true,
		[`g_m_y_salvagoon_02`] = true,
		[`g_m_importexport_01`] = true,
		[`a_m_m_afriamer_01`] = true,
		[`g_m_y_ballaeast_01`] = true,
		[`g_m_y_azteca_01`] = true,
		[`g_m_y_armgoon_02`] = true,
		[`g_m_y_ballasout_01`] = true,
		[`g_m_y_famdnf_01`] = true,
		[`g_m_y_korean_01`] = true,
		[`g_m_y_korean_02`] = true,
		[`g_m_y_korlieut_01`] = true,
		[`g_f_y_ballas_01`] = true,
	},

	-- backup peds for police, swat, highwaypatrol and sheriff, you can change the backup peds and vehicles
	backups = {
		["police"] = {
			vehicle = "police3",
			peds = {
				{ model = "csb_cop", weapon = "WEAPON_PISTOL", ammo = 1000 },
				{ model = "s_m_y_cop_01", weapon = "WEAPON_PISTOL", ammo = 1000 },
				{ model = "s_m_y_cop_01", weapon = "WEAPON_PISTOL", ammo = 1000 },
				{ model = "s_f_y_cop_01", weapon = "WEAPON_PISTOL", ammo = 1000 },
				{ model = "s_f_y_cop_01", weapon = "WEAPON_PISTOL", ammo = 1000 },
			},
		},
		["swat"] = {
			vehicle = "riot",
			peds = {
				{ model = "s_m_y_swat_01", weapon = "WEAPON_CARBINERIFLE", ammo = 1000 },
				{ model = "s_m_y_swat_01", weapon = "WEAPON_CARBINERIFLE", ammo = 1000 },
				{ model = "s_m_y_swat_01", weapon = "WEAPON_CARBINERIFLE", ammo = 1000 },
				{ model = "s_m_y_swat_01", weapon = "WEAPON_CARBINERIFLE", ammo = 1000 },
			},
		},
		["highwaypatrol"] = {
			vehicle = "police",
			peds = {
				{ model = "s_m_y_hwaycop_01", weapon = "WEAPON_PISTOL", ammo = 1000 },
				{ model = "s_m_y_hwaycop_01", weapon = "WEAPON_PISTOL", ammo = 1000 },
			},
		},
		["sheriff"] = {
			vehicle = "sheriff",
			peds = {
				{ model = "s_m_y_sheriff_01", weapon = "WEAPON_PISTOL", ammo = 1000 },
				{ model = "s_m_y_ranger_01", weapon = "WEAPON_PISTOL", ammo = 1000 },
				{ model = "s_f_y_sheriff_01", weapon = "WEAPON_PISTOL", ammo = 1000 },
				{ model = "s_m_y_ranger_01", weapon = "WEAPON_PISTOL", ammo = 1000 },
			},
		},
	},

	-- the stats recruits have
	recruitStats = {
		shooting = 2,
		driving = 2,
		armor = 2,
	},

	backupStats = {
		shooting = 4,
		driving = 4,
		armor = 4,
	},

	-- shop related
	shop = {
		bodyguard = {
			enabled = true,
			peds = {
				{
					ped = "s_m_m_chemsec_01",
					shooting = 2,
					driving = 1,
					armor = 3,
					pricePerDay = 20000,
				},
				{
					ped = "s_m_y_devinsec_01",
					shooting = 2,
					driving = 1,
					armor = 3,
					pricePerDay = 20000,
				},
				{
					ped = "s_m_m_highsec_02",
					shooting = 2,
					driving = 2,
					armor = 1,
					pricePerDay = 14000,
				},
				{
					ped = "cs_fbisuit_01",
					shooting = 3,
					driving = 1,
					armor = 2,
					pricePerDay = 15000,
				},
				{
					ped = "s_m_m_highsec_01",
					shooting = 2,
					driving = 3,
					armor = 1,
					pricePerDay = 19000,
				},
				{
					ped = "s_m_y_clubbar_01",
					shooting = 3,
					driving = 1,
					armor = 2,
					pricePerDay = 20000,
				},
			},
		},
		police = {
			enabled = true,
			peds = {

				{
					ped = "s_m_y_cop_01",
					shooting = 2,
					driving = 1,
					armor = 3,
					pricePerDay = 2000,
				},
				{
					ped = "s_m_y_hwaycop_01",
					shooting = 2,
					driving = 2,
					armor = 1,
					pricePerDay = 1000,
				},
				{
					ped = "csb_cop",
					shooting = 2,
					driving = 2,
					armor = 1,
					pricePerDay = 1000,
				},
				{
					ped = "s_m_m_snowcop_01",
					shooting = 2,
					driving = 3,
					armor = 1,
					pricePerDay = 1000,
				},
				{
					ped = "s_m_m_security_01",
					shooting = 1,
					driving = 2,
					armor = 1,
					pricePerDay = 250,
				},
				{
					ped = "mp_m_fibsec_01",
					shooting = 2,
					driving = 1,
					armor = 3,
					pricePerDay = 1250,
				},
				{
					ped = "s_f_y_cop_01",
					shooting = 3,
					driving = 1,
					armor = 2,
					pricePerDay = 1000,
				},
				{
					ped = "s_m_y_swat_01",
					shooting = 2,
					driving = 3,
					armor = 1,
					pricePerDay = 1250,
				},
			},
		},
		gang = {
			enabled = true,
			peds = {
				{
					ped = "g_m_y_famca_01",
					shooting = 2,
					driving = 2,
					armor = 1,
					pricePerDay = 1250,
				},
				{
					ped = "g_m_y_mexgoon_01",
					shooting = 2,
					driving = 3,
					armor = 2,
					pricePerDay = 1250,
				},
				{
					ped = "g_m_y_ballaorig_01",
					shooting = 3,
					driving = 2,
					armor = 1,
					pricePerDay = 1250,
				},
				{
					ped = "g_f_y_families_01",
					shooting = 2,
					driving = 2,
					armor = 2,
					pricePerDay = 1250,
				},
			},
		},
	},

	recruit = {
		recruitPriceRange = { min = 1000, max = 5000 }, -- price range for recruiting a ped from the street
		recruitDaysRange = { min = 1, max = 7 }, -- days range for recruiting a ped from the street if interested
	},

	recruitDialog = { -- chances of recruiting a ped (percentage is in decimal) NOTE DO NOTE CHANGE value ONLY percentage
		-- make sure the sum of all percentages is 1.0
		confirmJob = { -- chances of accepting the job
			{ percent = 0.4, value = "interested" },
			{ percent = 0.2, value = "no", exit = true },
			{ percent = 0.2, value = "callingCops", exit = true },
			{ percent = 0.2, value = "gangControl", exit = true },
		},
		guns = { -- chances of having gun experience
			{ percent = 0.75, value = "yes" },
			{ percent = 0.25, value = "no", exit = true },
		},
		jobCheck = { -- chances of looking for a job
			{ percent = 0.75, value = "interested" },
			{ percent = 0.25, value = "notInterested", exit = true },
		},
	},

	blips = {
		{ blipId = 311, color = 10, text = "Bodyguard Recuiter", size = 0.8, job = "none" },
		{ blipId = 311, color = 3, text = "Police Recuiter", size = 0.8, job = "police" },
		{ blipId = 311, color = 6, text = "Gang Recuiter", size = 0.8, job = "none" },
	},

	coords = {
		{
			coords = vector3(-1230.3526611328, -336.81219482422, 37.615943908691),
			heading = 24.61570930481,
			model = "cs_fbisuit_01",
			type = "Bodyguard",
			requiredJob = "none",
			enableBlip = true,
			blipIndex = 1,
		},
		{
			coords = vector3(478.39837646484, -978.67834472656, 27.983869552612),
			heading = 358.06362915039,
			model = "s_m_m_pilot_01",
			type = "Police",
			requiredJob = "police",
			enableBlip = true,
			blipIndex = 2,
		},
		{
			coords = vector3(246.38819885254, -1969.1279296875, 21.961687088013),
			heading = 222.27359008789,
			model = "g_m_m_chicold_01",
			type = "Gang",
			requiredJob = "none",
			enableBlip = true,
			blipIndex = 3,
		},
	},
	guarding = {
		enable = true,
		maxRadius = 15.0,
		minRadius = 5.0,
	},
	keyActions = {
		openShop = "E",
		guard = "E",
		guardCancel = "ESC",
		guardAreaIncrease = "UP",
		guardAreaDecrease = "DOWN",
		interactBodyguard = "G",
		vehicleMenu = "M",
		park = "E",
		cancel = "E",
		cancelPark = "BACKSPACE",
	},

	uiColors = {
		{ name = "bg", value = "#111111fe" },
		{ name = "bg2", value = "#212121" },
		{ name = "bg3", value = "#404040" },
		{ name = "textColor", value = "#f0f0f0" },
		{ name = "textSecond", value = "#878787" },
	},
}
