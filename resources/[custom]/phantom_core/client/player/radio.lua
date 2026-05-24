-- Phantom Core - Radio/Communication System
-- High-quality radio system with channels

local currentChannel = Config.Player.Radio.DefaultChannel
local radioOn = false
local radioVolume = Config.Player.Radio.Volume

-- Radio channels
local radioChannels = {
    { id = 1, name = 'Police Dispatch', encrypted = true },
    { id = 2, name = 'EMS Dispatch', encrypted = true },
    { id = 3, name = 'Fire Dispatch', encrypted = true },
    { id = 10, name = 'Public Channel 1', encrypted = false },
    { id = 11, name = 'Public Channel 2', encrypted = false },
    { id = 20, name = 'Gang Channel 1', encrypted = true },
    { id = 21, name = 'Gang Channel 2', encrypted = true },
}

-- Toggle radio
function ToggleRadio()
    radioOn = not radioOn
    
    if radioOn then
        SendNotification({
            type = 'info',
            message = 'Radio turned on - Channel ' .. currentChannel
        })
    else
        SendNotification({
            type = 'info',
            message = 'Radio turned off'
        })
    end
    
    -- This would integrate with pma-voice or similar voice system
end

-- Set radio channel
function SetRadioChannel(channel)
    if channel < 1 or channel > Config.Player.Radio.MaxChannels then
        SendNotification({
            type = 'error',
            message = 'Invalid channel (1-' .. Config.Player.Radio.MaxChannels .. ')'
        })
        return false
    end
    
    currentChannel = channel
    
    if radioOn then
        SendNotification({
            type = 'info',
            message = 'Channel set to ' .. channel
        })
    end
    
    -- This would update voice system
    return true
end

-- Increase channel
function IncreaseChannel()
    SetRadioChannel(currentChannel + 1)
end

-- Decrease channel
function DecreaseChannel()
    SetRadioChannel(currentChannel - 1)
end

-- Set radio volume
function SetRadioVolume(volume)
    radioVolume = Clamp(volume, 0.0, 1.0)
    
    -- This would update voice system
    SendNotification({
        type = 'info',
        message = 'Volume: ' .. math.floor(radioVolume * 100) .. '%'
    })
end

-- Open radio menu
function OpenRadioMenu()
    local options = {}
    
    -- Add toggle option
    table.insert(options, {
        label = radioOn and 'Turn Off Radio' or 'Turn On Radio',
        description = radioOn and 'Disable radio communication' or 'Enable radio communication',
        icon = radioOn and '🔇' or '🔊',
        args = { type = 'toggle' }
    })
    
    -- Add current channel info
    table.insert(options, {
        label = 'Current Channel: ' .. currentChannel,
        description = 'Currently tuned to channel ' .. currentChannel,
        icon = '📻',
        disabled = true
    })
    
    -- Add channel presets
    table.insert(options, {
        label = 'Channel Presets',
        description = 'Quick access to common channels',
        icon = '📋',
        args = { type = 'presets' }
    })
    
    -- Add manual channel selection
    table.insert(options, {
        label = 'Set Channel',
        description = 'Manually enter channel number',
        icon = '🔢',
        args = { type = 'setchannel' }
    })
    
    -- Add volume control
    table.insert(options, {
        label = 'Volume: ' .. math.floor(radioVolume * 100) .. '%',
        description = 'Adjust radio volume',
        icon = '🔊',
        args = { type = 'volume' }
    })
    
    ShowMenu({
        title = 'Radio System',
        options = options
    })
end

-- Open channel presets
function OpenChannelPresets()
    local options = {}
    
    for _, channel in ipairs(radioChannels) do
        table.insert(options, {
            label = channel.name,
            description = 'Channel ' .. channel.id .. (channel.encrypted and ' [Encrypted]' or ''),
            icon = channel.encrypted and '🔒' or '📻',
            args = { type = 'channel', id = channel.id }
        })
    end
    
    -- Add back button
    table.insert(options, {
        label = '← Back',
        description = 'Return to radio menu',
        icon = '⬅️',
        args = { type = 'back' }
    })
    
    ShowMenu({
        title = 'Channel Presets',
        options = options
    })
end

-- Handle menu selection
RegisterNUICallback('menuItemSelected', function(data, cb)
    if data.args.type == 'toggle' then
        ToggleRadio()
    elseif data.args.type == 'presets' then
        OpenChannelPresets()
    elseif data.args.type == 'setchannel' then
        ShowInputDialog({
            title = 'Set Channel',
            inputs = {
                {
                    type = 'number',
                    label = 'Channel Number',
                    placeholder = '1-' .. Config.Player.Radio.MaxChannels,
                    required = true
                }
            },
            callback = function(values, submitted)
                if submitted and values[1] then
                    SetRadioChannel(tonumber(values[1]))
                end
            end
        })
    elseif data.args.type == 'volume' then
        ShowInputDialog({
            title = 'Set Volume',
            inputs = {
                {
                    type = 'number',
                    label = 'Volume (0-100)',
                    placeholder = '50',
                    required = true
                }
            },
            callback = function(values, submitted)
                if submitted and values[1] then
                    SetRadioVolume(tonumber(values[1]) / 100)
                end
            end
        })
    elseif data.args.type == 'channel' then
        SetRadioChannel(data.args.id)
        CloseMenu()
    elseif data.args.type == 'back' then
        OpenRadioMenu()
    end
    cb({})
end)

RegisterNUICallback('menuClosed', function(data, cb)
    cb({})
end)

-- Key binds
CreateThread(function()
    while true do
        Wait(0)
        
        -- Toggle radio - F1 key (if not used by other systems)
        if IsControlJustPressed(0, 166) then
            ToggleRadio()
        end
        
        -- Increase channel - Mouse wheel up
        if IsControlJustPressed(0, 96) then
            IncreaseChannel()
        end
        
        -- Decrease channel - Mouse wheel down
        if IsControlJustPressed(0, 97) then
            DecreaseChannel()
        end
    end
end)

-- Register command
RegisterCommand('radio', function()
    OpenRadioMenu()
end)

-- Export functions
exports('ToggleRadio', ToggleRadio)
exports('SetRadioChannel', SetRadioChannel)
exports('SetRadioVolume', SetRadioVolume)

DebugPrint('Radio system loaded')
