Framework          = (GetResourceState("es_extended") == "started" and exports['es_extended']:getSharedObject()) or
    (GetResourceState("qbx_core") == "started" and exports['qbx_core']:GetCoreObject()) or nil

Settings           = {}
Settings.Framework = (GetResourceState("es_extended") == "started" and "ESX") or
    (GetResourceState("qbx_core") == "started" and "Qbox") or
    nil
Settings.Inventory = (GetResourceState("ox_inventory") == "started" and "ox_inventory") or
    (GetResourceState("qb-inventory") == "started" and "qb-inventory") or
    (GetResourceState("qs-inventory") == "started" and "qs-inventory") or "custom"
Settings.Target    = (GetResourceState("ox_target") == "started" and "ox_target") or
    (GetResourceState("qb-target") == "started" and "qb-target") or nil

-------------------------------------------------------------------------------

Settings.Debug     = false -- for debuging, it will print some info in console

local function dbgValue(value)
    if type(value) == "table" then
        if json and json.encode then
            local ok, encoded = pcall(json.encode, value)
            if ok then return encoded end
        end

        return tostring(value)
    end

    return tostring(value)
end

function dbg(message, ...)
    if not Settings or not Settings.Debug then return end

    local side = IsDuplicityVersion() and "SERVER" or "CLIENT"
    local output = tostring(message or "")
    local args = { ... }

    if #args > 0 then
        local formattedArgs = {}
        for i = 1, #args do
            formattedArgs[i] = dbgValue(args[i])
        end

        local ok, formatted = pcall(string.format, output, table.unpack(formattedArgs))

        if ok then
            output = formatted
        else
            output = output .. " " .. table.concat(formattedArgs, " ")
        end
    end

    print(("[TUFF-SCOREBOARD][%s] %s"):format(side, output))
end

dbg("Settings loaded | framework=%s | inventory=%s | target=%s", Settings.Framework, Settings.Inventory, Settings.Target)


-- if false it will anonymous (strings.lua to change it)
-- if true it will write player RP name
Settings.RealName      = true
Settings.ServerName    = "Tuff Scoreboard"
Settings.Tags          = true -- if u want tags
Settings.TagDistance   = 20.0 -- distance to show other players tag

-- if you want to disable some menu set it to false
Settings.Menu          = {
    Jobs   = true, -- for Jobs section
    Heists = true  -- for Heists section
}

Settings.Effects       = {
    Full = { -- for full menu
        blackEffect = true,
        blur        = true
    },
    Hold = {
        blackEffect = false,
        blur        = false
    }
}

Settings.Command       = { -- open full menu
    enable      = true,
    command     = "scoreboard",
    description = "Open full Scoreboard menu",
    key         = "F4"
}

Settings.Hold          = { -- open hold menu
    enable      = true,
    command     = "scoreboardhold",
    description = "Open hold Scoreboard menu",
    key         = "F8"
}

Settings.PlayerJobs    = {
    ["lumberjack"] = {
        label = "Lumberjack",
        icon = "fa-solid fa-tree"
    }
}

-- if there is no label for group it will display default
-- for example if you don't have config for group user it will use "user"
Settings.QBGroups      = { 'mod', 'admin', 'god' } -- check if player have this permission for QB, if he doesn't it returns 'user'
Settings.Role          = {                         -- player groups settings
    ["user"] = {
        label = "Player",
        icon = "fa-solid fa-user",
        color = "#F0F7FA"
    },
    ["mod"] = {
        label = "Moderator",
        icon = "fa-solid fa-user-shield",
        color = "#60A5FA"
    },
    ["admin"] = {
        label = "Administrator",
        icon = "fa-solid fa-shield-halved",
        color = "#00FFA6"
    },
    ["god"] = {
        label = "God",
        icon = "fa-solid fa-crown",
        color = "#FACC15"
    },
    ["superadmin"] = {
        label = "Super Admin",
        icon = "fa-solid fa-star",
        color = "#FB7185"
    }
}

Settings.AvaibleJobs   = {
    {
        job = "police",
        label = "Police",
        icon = "fa-solid fa-handcuffs",
        location = vector3(425.13, -979.56, 30.71)
    },
    {
        job = "ambulance",
        label = "EMS",
        icon = "fa-solid fa-truck-medical",
        location = vector3(299.58, -584.74, 43.26)
    },
    {
        job = "mechanic",
        label = "Mechanic",
        icon = "fa-solid fa-screwdriver-wrench",
        location = vector3(-337.25, -136.89, 39.01)
    },
    {
        job = "taxi",
        label = "Taxi",
        icon = "fa-solid fa-taxi",
        location = vector3(909.31, -177.28, 74.22)
    },
    {
        job = "realestate",
        label = "Real Estate",
        icon = "fa-solid fa-building",
        location = vector3(-716.07, 261.21, 84.14)
    },
    {
        job = "cardealer",
        label = "Car Dealer",
        icon = "fa-solid fa-car-side",
        location = vector3(-56.16, -1096.61, 26.42)
    },
    {
        job = "judge",
        label = "Judge",
        icon = "fa-solid fa-scale-balanced",
        location = vector3(-545.31, -204.02, 38.22)
    },
    {
        job = "lawyer",
        label = "Lawyer",
        icon = "fa-solid fa-gavel",
        location = vector3(-545.31, -204.02, 38.22)
    },
    {
        job = "reporter",
        label = "Reporter",
        icon = "fa-solid fa-microphone",
        location = vector3(-598.12, -929.75, 23.86)
    }
}

-- for job
-- "" for only one job for example "police"
-- {"", "", ""} for more jobs for example {"police", "fib"}

-- for minimum
-- minimum number needed for heist
-- for example you have more than one job it will add up for example you have 2 jobs it wil check their add up result
-- job1 + job2 >= minimum

-- for image
-- it can be image file name (assets/heists/file_name.png) or link (we don't recommend dist as a host, it's better to use fivemanage)
Settings.AvaibleHeists = {
    {
        job = "police",
        label = "Fleeca Bank",
        minimum = 2,
        image = "fleeca.png"
    },
    {
        job = "police",
        label = "24/7 Liquor Store",
        minimum = 6,
        image = "liquor.png"
    },
    {
        job = "police",
        label = "Jewelry Store",
        minimum = 4,
        image = "jewelry.png"
    },
    {
        job = "police",
        label = "Bobcat Security",
        minimum = 5,
        image = "bobcat.jpeg"
    },
    {
        job = "police",
        label = "Humane Labs",
        minimum = 6,
        image = "humanelabs.png"
    }
}
