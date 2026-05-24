Interactions = Interactions or {}

Interactions.Client = Interactions.Client or {}

Interactions.Client.InstrPrmt = Interactions.Client.InstrPrmt or {}

local lastPromptText = nil

local function BuildPromptText(text, keybinds, wasd)

    local promptText = text .. tostring(wasd or "")

    if keybinds then

        for _, keybind in ipairs(keybinds) do

            promptText = promptText .. keybind.key .. keybind.desc

        end

    end

    return promptText

end

function Interactions.Client.InstrPrmt.Show(text, keybinds, wasd, error)

    local promptText = BuildPromptText(text, keybinds, wasd)

    if promptText ~= lastPromptText then

        PlaySoundFrontend(-1, "OTHER_TEXT", "HUD_AWARDS", false)

        lastPromptText = promptText

    end

    SendNUIMessage({

        type = "showInstrPrmt",

        text = text,

        keybinds = keybinds,

        wasd = wasd,

        error = error

    })

end

function Interactions.Client.InstrPrmt.Hide()

    lastPromptText = nil

    SendNUIMessage({

        type = "hideInstrPrmt"

    })

end
