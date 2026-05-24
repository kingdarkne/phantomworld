return {

    -- 🔎 Looking for more high quality scripts?
    -- 🛒 Shop Now: https://lationscripts.com
    -- 💬 Join Discord: https://discord.gg/9EbY4nM5uu
    -- 😢 How dare you leave this option false?!
    YouFoundTheBestScripts = false,

    ----------------------------------------------
    --        🛠️ Setup the basics below
    ----------------------------------------------

    setup = {
        -- Use only if needed, directed by support or know what you're doing
        -- Notice: enabling debug features will significantly increase resmon
        -- And should always be disabled in production
        debug = false,
        -- Set your interaction system below
        -- Available options are: 'ox_target', 'qb-target', 'interact' & 'custom'
        -- 'custom' needs to be added to client/functions.lua
        interact = 'ox_target',
        -- Set your notification system below
        -- Available options are: 'lation_ui', 'ox_lib', 'esx', 'qb', 'okok', 'sd-notify', 'wasabi_notify', 'mythic_notify' & 'custom'
        -- 'custom' needs to be added to client/functions.lua
        notify = 'ox_lib',
        -- Set your progress bar system below
        -- Available options are: 'lation_ui', 'ox_lib', 'qbcore' & 'custom'
        -- 'custom' needs to be added to client/functions.lua
        -- Any custom progress bar must also support animations
        progress = 'ox_lib',
        -- Set your minigame (skillcheck) system below
        -- Available options are: 'lation_ui', 'ox_lib' & 'custom'
        minigame = 'ox_lib',
        -- Set your alert & input dialog system below
        -- Available options are: 'lation_ui', 'ox_lib' & 'custom'
        dialogs = 'ox_lib',
        -- Do you want to be notified via server console if an update is available?
        -- True if yes, false if no
        version = true,
        -- Once a store robbery has succesfully started a cooldown begins
        -- This is per-player and not a global cooldown (cooldown is in seconds)
        cooldown = 600,
        -- By default, the player-based cooldowns are overridden by this global cooldown
        -- This will prevent robberies at all stores by any player until the cooldown expires
        -- If you prefer a more flexible player-based cooldown option, just disable global
        -- The duration variable here is also in seconds like above
        global = { enable = true, duration = 600 }
    },

    ----------------------------------------------
    --        👮 Setup police options
    ----------------------------------------------

    police = {
        -- How many police must be online in order to start a robbery?
        -- 0 = cops NOT required. Robbery can be done solo or with police online.
        count = 0,
        -- Add your police job(s) below
        jobs = { 'police', 'sheriff' },
        -- Set your dispatch system
        -- 'custom' works fine without a dedicated dispatch resource (just sends a generic alert)
        dispatch = 'custom',
        -- Risk feature: increases reward when cops ARE online (encourages risk/reward gameplay)
        risk = true,
        -- +10% per online cop (2 cops = +20%, 5 cops = +50%)
        percent = 10
    },

    ----------------------------------------------
    --        🏪 Setup register robbery
    ----------------------------------------------

    registers = {
        -- Set the required item name below needed to rob a cash register
        item = 'lockpick',
        -- Customize the minigame (skillcheck) difficulty below
        minigame = {
            -- Set the skillcheck difficulty levels below
            -- You can set 'easy', 'medium' or 'hard' in any order
            -- And in any amount/quantity - Learn more about the skillcheck
            -- Here: https://overextended.dev/ox_lib/Modules/Interface/Client/skillcheck
            difficulty = { 'easy', 'easy', 'easy', 'easy', 'easy','easy', },
            -- The 'inputs' are the keys that will be used for the skillcheck
            -- Minigame and can be set to any key or keys of your choice
            inputs = { 'W', 'A', 'S', 'D' }
        },
        -- After a successful register robbery, what item(s) do you want to reward?
        -- { item = 'some_item', min = 1, max = 1, chance = 100, metadata = { ['key'] = value } }
        -- The metadata table is optional
        -- The 'item' can also be an account, such as 'cash' or 'bank'
        reward = {
            -- Per register: $100,000 - $500,000 (2 registers per store = $200k-$1M)
            { item = 'cash', min = 100000, max = 500000, chance = 100 },
        },
        -- If a player fails to successfully lockpick the register
        -- There is a chance that their lockpick will break. In percentage,
        -- What chance do you want their lockpick to break? To never break, set 0
        -- To break every time, set 100
        breakChance = 50,
        -- After a player succesfully robs a register, there is this "noteChance" they
        -- "Find" the safe's PIN "under the register" and can skip the computer hacking
        -- Step if found. In percentage, what chance do they have to find this note?
        noteChance = 10
    },

    ----------------------------------------------
    --        🖥️ Setup computer hacking
    ----------------------------------------------

    computers = {
        -- Hacking the safe computer is the gateway to the big payouts.
        -- Only 2 attempts allowed - HARD difficulty.
        maxAttempts = 2,
        questionnaire = false,
        minigame = {
            -- Mostly HARD skillchecks with some medium - very hard to complete
            difficulty = { 'hard', 'hard', 'medium', 'hard', 'hard', 'medium', 'hard' },
            inputs = { 'W', 'A', 'S', 'D' }
        },
    },

    ----------------------------------------------
    --        🔐 Setup safe robbery
    ----------------------------------------------

    safes = {
        -- Safe PIN entry - only 2 attempts before it locks you out
        maxAttempts = 2,
        -- After a successful register robbery, what item(s) do you want to reward?
        -- { item = 'some_item', min = 1, max = 1, chance = 100, metadata = { ['key'] = value } }
        -- The metadata table is optional
        -- The 'item' can also be an account, such as 'cash' or 'bank'
        reward = {
            -- Tiered payouts with independent chance rolls (each rolled separately)
            -- Baseline (guaranteed): $500k - $2M
            { item = 'cash', min = 500000, max = 2000000, chance = 100 },
            -- Uncommon boost: additional $1M - $3M (25% chance)
            { item = 'cash', min = 1000000, max = 3000000, chance = 25 },
            -- Rare boost: additional $3M - $7M (8% chance)
            { item = 'cash', min = 3000000, max = 7000000, chance = 8 },
            -- Legendary jackpot: additional $15M - $50M (ONLY 1% chance!)
            { item = 'cash', min = 15000000, max = 50000000, chance = 1 },
        },
    },

    ----------------------------------------------
    --     ❓ Setup optional questionnaire
    ----------------------------------------------

    questionnaire = {
        questions = {
            [1] = {
                type = 'input',
                label = 'Question #1',
                description = 'What is a PSU?',
                icon = 'fas fa-bolt',
                required = true
            },
            [2] = {
                type = 'input',
                label = 'Question #2',
                description = 'What does "HTTPS" stand for?',
                icon = 'fas fa-lock',
                required = true
            },
            [3] = {
                type = 'input',
                label = 'Question #3',
                description = 'What is a GPU?',
                icon = 'fas fa-desktop',
                required = true
            },
            [4] = {
                type = 'select',
                label = 'Question #4',
                description = 'What does CTRL + A do?',
                icon = 'fas fa-keyboard',
                required = true,
                options = {
                    { value = 1, label = 'Copy text' },
                    { value = 2, label = 'Paste text' },
                    { value = 3, label = 'Select all' },
                    { value = 4, label = 'Print page' },
                }
            },
            -- Add more questions here, following the same format as above
            -- Be sure to increment the numbers correctly, [5], [6], etc
        },
        -- All the answers to the above questions must be placed here
        -- Put the answers in the same order the questions are above
        -- The answer to question [3] above should be [3] here as well
        -- Note: answers to type = 'select' should be the value numer
        answers = {
            [1] = 'power supply unit',
            [2] = 'hypertext transfer protocol secure',
            [3] = 'graphics processing unit',
            [4] = 3
        }
    }

}