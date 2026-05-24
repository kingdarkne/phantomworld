local QBCore = DrGetQBCore()

local isJudge = false
local isPolice = false
local isTow = false
local isTaxi = false
local isMedic = false
local isDead = false
local myJob = "Unemployed"
local isHandcuffed = false
local hasOxygenTankOn = false
local bennyscivpoly = false
local onDuty = false
local inGarage = false
local inDepots = false

rootMenuConfig = {
    {
        id = "blips",
        displayName = "GPS",
        icon = "#blips",
        enableMenu = function()
            local Player = QBCore.Functions.GetPlayerData()
            local md = Player and Player.metadata
            if not md then return false end
            local inlaststand = md.inlaststand
            local isdead = md.isdead

            return not isdead and not inlaststand
        end,
        subMenus = { "blips:gasstations", "blips:barbershop", "blips:tattooshop", "blips:snrbuns", "fk:karakol", "fk:hastane", "fk:galeri", "fk:motel" }
    },
    {
        id = "General",
        displayName = "General",
        icon = "#globe-europe",
        enableMenu = function()
            local Player = QBCore.Functions.GetPlayerData()
            local md = Player and Player.metadata
            if not md then return false end
            local inlaststand = md.inlaststand
            local isdead = md.isdead

            return not inlaststand and not isdead
        end,
        subMenus = {"general:givenum", "drug:sell", "general:unseatnearest", "general:parkvehicle", "general:garage"}
    },
    {
        id = "copDead",
        displayName = "11-A",
        icon = "#police-dead",
        functionName = "police:client:SendPoliceEmergencyAlert",
        enableMenu = function()
            local Player = QBCore.Functions.GetPlayerData()
            local md = Player and Player.metadata
            if not md then return false end
            local inlaststand = md.inlaststand
            local isdead = md.isdead

            return isPolice and inlaststand and isdead
        end,
    },
    {
        id = "Police",
        displayName = "Police Interaction",
        icon = "#police-action",
        enableMenu = function()
            local Player = QBCore.Functions.GetPlayerData()
            local md = Player and Player.metadata
            if not md then return false end
            local inlaststand = md.inlaststand
            local isdead = md.isdead

            return isPolice and not isDead
        end,
        subMenus = {
            "police:mdt", 
            "general:cuff", 
            "police:seizecash", 
            "police:inspect", 
            "police:storecar", 
            "police:statuscheck", 
            "police:searchplayer", 
            "police:jail", 
            "police:takeoffmask",
            -- Police objects submenu items added below
            "spawnpion",        -- Cone
            "spawnhek",         -- Gate
            "spawnschotten",    -- Speed Limit Sign
            "spawntent",        -- Tent
            "spawnverlichting", -- Lighting
            "spikestrip",       -- Spike Strips
            "deleteobject"      -- Remove object
                }
    },
    {
        id = "PoliceObjects",
        displayName = "Police Objects",
        icon = "#police-action",
        enableMenu = function()
            local Player = QBCore.Functions.GetPlayerData()
            local md = Player and Player.metadata
            if not md then return false end
            local inlaststand = md.inlaststand
            local isdead = md.isdead

            return isPolice and not isDead and onDuty
        end,
        subMenus = {"spawnpion", "spawnhek", "spawnschotten", "spawntent"}
    },
    {
        id = "Ambulance",
        displayName = "Ambulance",
        icon = "#hospital-amb",
        enableMenu = function()
            return isMedic and not isDead and onDuty
        end,
        subMenus = {"medic:status", "medic:revive", "medic:treat"}
    },
    {
        id = "Tow",
        displayName = "Tow",
        icon = "#tow-job",
        enableMenu = function()
            local Player = QBCore.Functions.GetPlayerData()
            local md = Player and Player.metadata
            if not md then return false end
            local inlaststand = md.inlaststand
            local isdead = md.isdead

            return isTow and not isDead and onDuty
        end,
        subMenus = {"tow:togglenpc", "tow:vehicle"}
    },
    {
        id = "Taxi",
        displayName = "Taxi",
        icon = "#taxi-job",
        enableMenu = function()
            local Player = QBCore.Functions.GetPlayerData()
            local md = Player and Player.metadata
            if not md then return false end
            local inlaststand = md.inlaststand
            local isdead = md.isdead

            return isTaxi and not isDead and onDuty
        end,
        subMenus = {"taxi:npc", "taxi-meter", "taxi:startmeter"}
    },
    {
        id = "Escort",
        displayName = "Escort",
        icon = "#general-escort",
        functionName = "police:client:EscortPlayer",
        enableMenu = function()
            local Player = QBCore.Functions.GetPlayerData()
            local md = Player and Player.metadata
            if not md then return false end
            local inlaststand = md.inlaststand
            local isdead = md.isdead

            return not isdead and not inlaststand
        end
    },
    {
        id = "Vip",
        displayName = "Vip",
        icon = "#general-vip",
        functionName = "dr-vipSystem:openMenu",
        enableMenu = function()
            local Player = QBCore.Functions.GetPlayerData()
            local md = Player and Player.metadata
            if not md then return false end
            local inlaststand = md.inlaststand
            local isdead = md.isdead

            return not isdead and not inlaststand
        end
    },
    {
        id = "Vehicle",
        displayName = "Vehicle",
        icon = "#general-car",
        functionName = "carmenuOpen",
        enableMenu = function()
            return not isDead and IsPedInAnyVehicle(PlayerPedId(), true)
        end
   
    }
}

-- Updated newSubMenus with policeobjects added
newSubMenus = {
    ['general:givenum'] = {
        title = "Give Contact",
        icon = "#phone-contact",
        functionName = "qb-phone:client:GiveContactDetails"
    }, 
    ['blips:gasstations'] = {
        title = "Gas Station",
        icon = "#blips-gasstations",
        functionName = "ygx:togglegas"
    },
    ['blips:barbershop'] = {
        title = "Barber",
        icon = "#blips-barbershop",
        functionName = "ygx:togglebarber"
    },
    ['fk:galeri'] = {
        title = "PDM",
        icon = "#blips-garages",
        functionName = "fk:galeri"
    },
    ['general:rob'] = {
        title = "Rob",
        icon = "#general-contact",
        functionName = "police:client:RobPlayer"
    },
    ['general:playerinvehicle'] = {
        title = "Seat Vehicle",
        icon = "#general-put-in-veh",
        functionName = "police:client:PutPlayerInVehicle"
    },
    ['general:playeroutvehicle'] = {
        title = "Unseat Vehicle",
        icon = "#general-put-in-veh",
        functionName = "police:client:SetPlayerOutVehicle"
    }, 
    ['drug:sell'] = {
        title = "Cornersell",
        icon = "#general-drug",
        functionName = "qb-drugs:client:cornerselling"
    },
    ['general:cuff'] = {
        title = "Cuff",
        icon = "#police-cuffs",
        functionName = "police:client:CuffPlayer"
    },
    ['police:statuscheck'] = {
        title = "Status Check",
        icon = "#police-checkplayerstatus",
        functionName = "hospital:client:CheckStatus"
    },
    ['police:inspect'] = {
        title = "Inspect",
        icon = "#general-police-inspect",
        functionName = "hospital:client:CheckStatus"
    },
    ['police:storecar'] = {
        title = "Park Vehicle",
        icon = "#general-parking",
        functionName = "os-policegarage:storecar"
    },
    ['police:searchplayer'] = {
        title = "Search player",
        icon = "#k9-sniff",
        functionName = "police:client:SearchPlayer"
    },
    ['police:jail'] = {
        title = "Jail Player",
        icon = "#police-cuffs",
        functionName = "police:client:JailPlayer"
    },
    ['police:seizecash'] = {
        title = "Seize Cash",
        icon = "#police-seize",
        functionName = "police:client:SeizeCash"
    },
    ['police:mdt'] = {
        title = "MDT",
        icon = "#mdt",
        functionName = "mdt:client:open"    
    },
    ['police:takeoffmask'] = {
        title = "Mask",
        icon = "#cuffs-remove-mask",
        functionName = "police:client:takeoffmask" 
    },
    -- Added police objects as individual items in newSubMenus
    ['spawnpion'] = {
        title = 'Cone',
        icon = 'triangle-exclamation',
        functionName = 'police:client:spawnCone',
        shouldClose = false
    },
    ['spawnhek'] = {
        title = 'Gate',
        icon = 'torii-gate',
        functionName = 'police:client:spawnBarrier',
        shouldClose = false
    },
    ['spawnschotten'] = {
        title = 'Speed Limit Sign',
        icon = 'sign-hanging',
        functionName = 'police:client:spawnRoadSign',
        shouldClose = false
    },
    ['spawntent'] = {
        title = 'Tent',
        icon = 'campground',
        functionName = 'police:client:spawnTent',
        shouldClose = false
    },
    ['spawnverlichting'] = {
        title = 'Lighting',
        icon = 'lightbulb',
        functionName = 'police:client:spawnLight',
        shouldClose = false
    },
    ['spikestrip'] = {
        title = 'Spike Strips',
        icon = 'caret-up',
        functionName = 'police:client:SpawnSpikeStrip',
        shouldClose = false
    },
    ['deleteobject'] = {
        title = 'Remove object',
        icon = 'trash',
        functionName = 'police:client:deleteObject',
        shouldClose = false
    },
 
    -- POLICE
    ['police:spawn1'] = {
        title = "Cone",
        icon = "#police-revokelicense",
        functionName = "police:client:spawnCone"     
    },   
['police:spawn2'] = {
    title = "Spikes",
    icon = "#police-revokelicense",
    functionName = "police:client:SpawnSpikeStrip" 
},
    ['police:del'] = {
        title = "Delete",
        icon = "#police-revokelicense",
        functionName = "police:client:deleteObjectw"     
    },
    -- HOSPITAL
    ['medic:status'] = {
        title = "StatusCheck",
        icon = "#general-cuff",
        functionName = "" 
    },
    ['medic:revive'] = {
        title = "Revive",
        icon = "#hospital-revivep",
        functionName = "hospital:client:RevivePlayer"
    },
    ['medic:treat'] = {
        title = "Heal wounds",
        icon = "#hospital-treat",
        functionName = "hospital:client:TreatWounds"
    },
    ['medic:stretcherspawn'] = {
        title = "Stretcher",
        icon = "#general-cuff",
        functionName = "hospital:client:TakeStretcher" 
    }, 
    ['medic:stretcherremove'] = {
        title = "Stretcher Remove",
        icon = "#general-cuff",
        functionName = "hospital:client:RemoveStretcher" 
    },  --TOW --TOW
    ['tow:togglenpc'] = {
        title = "Toggle Npc",
        icon = "#tow-mission",
        functionName = "jobs:client:ToggleNpc"
    }, 
    ['tow:vehicle'] = {
        title = "Tow vehicle",
        icon = "#tow-tow",
        functionName = "qb-tow:client:TowVehicle"
    },  -- Taxi
    ['taxi-meter'] = {
        title = "Toggle Npc",
        icon = "#tow-mission",
        functionName = "qb-taxi:client:toggleMeter"
    }, 
    ['taxi:npc'] = {
        title = "Taxi mission",
        icon = "#tow-tow",
        functionName = "qb-taxi:client:DoTaxiNpc"
    },  
    ['taxi:startmeter'] = {
        title = "Start/Stop meter",
        icon = "#tow-tow",
        functionName = "qb-taxi:client:enableMeter"
    },
    ['set:extra'] = {
        title = "Exra",
        icon = "#tow-tow",
        functionName = "qb-radialmenu:client:setExtra"
    },

    ['k9:spawn'] = {
        title = "Summon",
        icon = "#k9-spawn",
        functionName = "K9:Create"
    },
    ['k9:delete'] = {
        title = "Dismiss",
        icon = "#k9-dismiss",
        functionName = "K9:Delete"
    },
    ['k9:follow'] = {
        title = "Follow",
        icon = "#k9-follow",
        functionName = "K9:Follow"
    },
    ['k9:vehicle'] = {
        title = "Get in/out",
        icon = "#k9-vehicle",
        functionName = "K9:Vehicle"
    },
    ['k9:sit'] = {
        title = "Sit",
        icon = "#k9-sit",
        functionName = "K9:Sit"
    },
    ['k9:lay'] = {
        title = "Lay",
        icon = "#k9-lay",
        functionName = "K9:Lay"
    },
    ['k9:stand'] = {
        title = "Stand",
        icon = "#k9-stand",
        functionName = "K9:Stand"
    },
    ['k9:sniff'] = {
        title = "Sniff Person",
        icon = "#k9-sniff",
        functionName = "K9:Sniff"
    },
    ['k9:sniffvehicle'] = {
        title = "Sniff Vehicle",
        icon = "#k9-sniff-vehicle",
        functionName = "sniffVehicle"
    },
    ['k9:huntfind'] = {
        title = "Hunt nearest",
        icon = "#k9-huntfind",
        functionName = "K9:Huntfind"
    },
}
    

RegisterNetEvent("isJudge") -- these are all up to you and your job system, if person become Judge, script will see him as Judge too.
AddEventHandler("isJudge", function()
    isJudge = true
end)

RegisterNetEvent("isJudgeOff") -- opposite of the above
AddEventHandler("isJudgeOff", function()
    isJudge = false
end)

RegisterNetEvent("isTow") -- these are all up to you and your job system, if person become Judge, script will see him as Judge too.
AddEventHandler("isTow", function()
    isTow = true
end)

RegisterNetEvent("isTowOff") -- these are all up to you and your job system, if person become Judge, script will see him as Judge too.
AddEventHandler("isTowOff", function()
    isTow = false
end)

RegisterNetEvent("isTaxi") -- these are all up to you and your job system, if person become Judge, script will see him as Judge too.
AddEventHandler("isTaxi", function()
    isTaxi = true
end)

RegisterNetEvent("isTaxiOff") -- opposite of the above
AddEventHandler("isTaxiOff", function()
    isTaxi = false
end)

RegisterNetEvent("QBCore:Client:OnJobUpdate") -- dont edit this unless you don't use qb-core
AddEventHandler("QBCore:Client:OnJobUpdate", function(jobInfo)
    myJob = jobInfo.name
    if isMedic and myJob ~= "ambulance" then isMedic = false end
    if isPolice and myJob ~= "police" then isPolice = false end
    if isTow and myJob ~= "tow" then isTow = false end
    if isTaxi and myJob ~= "taxi" then isTaxi = false end
    if myJob == "police" then isPolice = true end
    if myJob == "tow" then isTow = true end
    if myJob == "taxi" then isTaxi = true end
    if myJob == "ambulance" then isMedic = true end
end)

RegisterNetEvent('QBCore:Client:SetDuty') -- dont edit this unless you don't use qb-core
AddEventHandler('QBCore:Client:SetDuty', function(duty)
    local pd = QBCore.Functions.GetPlayerData()
    if pd and pd.job then myJob = pd.job.name end
    if isMedic and myJob ~= "ambulance" then isMedic = false end
    if isPolice and myJob ~= "police" then isPolice = false end
    if myJob == "police" then isPolice = true onDuty = duty end
    if myJob == "ambulance" then isMedic = true onDuty = duty end
end)

RegisterNetEvent('deathcheck') -- YOU SHOULD ADD THIS IN YOUR ambulancejob system, basically let the function trigger here when the ped playing anim and add this to
-- your revived function so everytime if person dies, this will be triggered to isDead = true, if he get revived this will be triggered to isDead = false
AddEventHandler('deathcheck', function()
    if not isDead then
        isDead = true
    else
        isDead = false
    end
end)


RegisterNetEvent("police:currentHandCuffedState") -- add this your police:client:GetCuffed @qb-policejob\client\interactions.lua
AddEventHandler("police:currentHandCuffedState", function(pIsHandcuffed)
    isHandcuffed = pIsHandcuffed
end)

RegisterNetEvent("menu:hasOxygenTank") -- add this to your oxygentank wear place, idk where is this for qb-inventory so find out please
AddEventHandler("menu:hasOxygenTank", function(pHasOxygenTank)
    hasOxygenTankOn = pHasOxygenTank
end)


RegisterNetEvent('police:client:PutInVehicle')
AddEventHandler('police:client:PutInVehicle', function()
    if isEscorted then
    end
end)