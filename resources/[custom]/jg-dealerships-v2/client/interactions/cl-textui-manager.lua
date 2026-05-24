Interactions = Interactions or {}

Interactions.Client = Interactions.Client or {}

Interactions.Client.TextUIManager = Interactions.Client.TextUIManager or {}

local TextUIManager = Interactions.Client.TextUIManager

local activeEntries   = {}
local currentShownId  = nil
local isVisible       = false

local cooldowns       = {}
local COOLDOWN_MS     = 300
function TextUIManager.Show(id, text, key, callback)

    activeEntries[id] = {

        text     = text,

        key      = key,

        callback = callback,

        priority = GetGameTimer(),

    }

    UpdateDisplay()

end

function TextUIManager.Hide(id)

    if not id then return end

    activeEntries[id] = nil

    cooldowns[id]     = nil

    UpdateDisplay()

end

function TextUIManager.IsActive()

    return isVisible

end

function TextUIManager.IsShowingId(id)

    return currentShownId == id

end

function TextUIManager.ForceHideAll()

    if isVisible then

        Framework.Client.HideTextUI()

    end

    activeEntries  = {}

    currentShownId = nil

    isVisible      = false

    cooldowns      = {}

end

function UpdateDisplay()

    local bestId   = nil

    local bestData = nil

    for id, data in pairs(activeEntries) do

        if bestId == nil or data.priority > bestData.priority then

            bestId   = id

            bestData = data

        end

    end

    if bestId then

        if currentShownId ~= bestId then

            if isVisible then

                Framework.Client.HideTextUI()

            end

            Framework.Client.ShowTextUI(bestData.text)

            currentShownId = bestId

            isVisible      = true

        end

    else

        if isVisible then

            Framework.Client.HideTextUI()

            currentShownId = nil

            isVisible      = false

        end

    end

end

CreateThread(function()

    while true do

        Wait(0)

        if isVisible and currentShownId then

            local entry = activeEntries[currentShownId]

            if entry then

                local now = GetGameTimer()

                if IsControlJustReleased(0, entry.key) then

                    local lastFired = cooldowns[currentShownId] or 0

                    if (now - lastFired) > COOLDOWN_MS then

                        cooldowns[currentShownId] = now

                        local ok, err = pcall(entry.callback)

                        if not ok then

                            print("[TextUIManager] Error in callback:", err)

                        end

                    end

                end

            end

        else

            Wait(100)
        end

    end

end)

AddEventHandler("onResourceStop", function(resourceName)

    if GetCurrentResourceName() == resourceName then

        Interactions.Client.TextUIManager.ForceHideAll()

    end

end)

exports("ForceHideTextUI", function()

    Interactions.Client.TextUIManager.ForceHideAll()

end)
