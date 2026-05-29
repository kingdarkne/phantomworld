-- Phantom Core - Custom Emote System
-- High-quality emote system with categories and favorites

local emotes = {
    Greetings = {
        { name = 'Wave', dict = 'anim@mp_player_intincar_upper_lower_wave', anim = 'a_wave' },
        { name = 'Salute', dict = 'anim@mp_player_intincarsalutestd@ds@', anim = 'idle_a' },
        { name = 'Thumbs Up', dict = 'anim@mp_player_intselfiethumbs', anim = 'idle_a' },
        { name = 'Point', dict = 'gestures@f@standing@casual', anim = 'gesture_point' },
        { name = 'Come Here', dict = 'missbigrank01', anim = 'idle_a' },
    },
    Dance = {
        { name = 'Dance 1', dict = 'anim@amb@nightclub@dancers@podium_dancers@', anim = 'hi_dance_fidget_podium_dancer_01' },
        { name = 'Dance 2', dict = 'anim@amb@nightclub@dancers@solomun_entourage@', anim = 'mi_dance_fidget_solomun_entourage_01' },
        { name = 'Dance 3', dict = 'anim@amb@nightclub@dancers@tai_pei_entourage@', anim = 'mi_dance_fidget_tai_pei_entourage_01' },
        { name = 'Dance 4', dict = 'anim@amb@nightclub@lazlow@hi_podium@', anim = 'danceidle_hi_11_buttwiggle_b_lazlow' },
        { name = 'Dance 5', dict = 'anim@amb@nightclub@lazlow@hi_dancefloor@', anim = 'dance_hi_hi_lazlow_b_lazlow' },
    },
    Actions = {
        { name = 'Sit', dict = 'anim@heists@prison_heistunfinished_biztarget_idle', anim = 'target_idle' },
        { name = 'Lean', dict = 'anim@amb@world_human_leaning@female@wall@back@holding_elbow@idle_a', anim = 'idle_a' },
        { name = 'Kneel', dict = 'anim@amb@world_human_kneel@male@base@base', anim = 'base' },
        { name = 'Cross Arms', dict = 'anim@amb@world_human_hangout_street@male_c@base', anim = 'base' },
        { name = 'Hands Up', dict = 'missminuteman_1ig_2', anim = 'handsup_base' },
    },
    Sports = {
        { name = 'Flex', dict = 'amb@world_human_muscle_flex@arms_at_side@base', anim = 'base' },
        { name = 'Jog', dict = 'amb@world_human_jog_standing@male@idle_a', anim = 'idle_a' },
        { name = 'Pushups', dict = 'amb@world_human_push_ups@male@base', anim = 'base' },
        { name = 'Situps', dict = 'amb@world_human_sit_ups@male@base', anim = 'base' },
        { name = 'Yoga', dict = 'amb@world_human_yoga@female@base', anim = 'base_a' },
    },
    Work = {
        { name = 'Inspect', dict = 'anim@amb@world_human_janitor@male@idle_a', anim = 'idle_a' },
        { name = 'Clean', dict = 'timetable@maid@cleaning_surface@base', anim = 'base' },
        { name = 'Type', dict = 'anim@heists@ornate_bank@grab_cash', anim = 'grab' },
        { name = 'Notebook', dict = 'missheistdockssetup1clipboard@base', anim = 'base' },
        { name = 'Camera', dict = 'amb@world_human_paparazzi@male@base', anim = 'base' },
    },
}

local favoriteEmotes = {}
local currentEmote = nil
local emoteMenuOpen = false

-- Play emote
function PlayEmote(category, emoteIndex)
    local emote = emotes[category][emoteIndex]
    
    if currentEmote then
        ClearEmote()
    end
    
    if PlayAnimation(emote.dict, emote.anim, -1, 49) then
        currentEmote = {
            category = category,
            index = emoteIndex
        }
        
        SendNotification({
            notificationType = 'info',
            message = 'Playing emote: ' .. emote.name
        })
    else
        SendNotification({
            notificationType = 'error',
            message = 'Failed to play emote'
        })
    end
end

-- Clear emote
function ClearEmote()
    if currentEmote then
        ClearAnimation()
        currentEmote = nil
    end
end

-- Toggle emote favorite
function ToggleFavorite(category, emoteIndex)
    local emoteKey = category .. '_' .. emoteIndex
    
    if favoriteEmotes[emoteKey] then
        favoriteEmotes[emoteKey] = nil
        SendNotification({
            notificationType = 'info',
            message = 'Removed from favorites'
        })
    else
        favoriteEmotes[emoteKey] = {
            category = category,
            index = emoteIndex
        }
        SendNotification({
            notificationType = 'success',
            message = 'Added to favorites'
        })
    end
end

-- Open emote menu
function OpenEmoteMenu()
    if emoteMenuOpen then return end
    emoteMenuOpen = true
    
    local options = {}
    
    -- Add categories
    for categoryName, categoryEmotes in pairs(emotes) do
        local categoryIcon = nil
        for _, cat in ipairs(Config.Player.Emotes.Categories) do
            if cat.name == categoryName then
                categoryIcon = cat.icon
                break
            end
        end
        
        table.insert(options, {
            label = categoryName,
            description = #categoryEmotes .. ' emotes',
            icon = categoryIcon or '🎭',
            args = { type = 'category', name = categoryName }
        })
    end
    
    -- Add favorites
    local favoriteCount = 0
    for _ in pairs(favoriteEmotes) do favoriteCount = favoriteCount + 1 end
    
    if favoriteCount > 0 then
        table.insert(options, {
            label = 'Favorites',
            description = favoriteCount .. ' favorite emotes',
            icon = '⭐',
            args = { type = 'favorites' }
        })
    end
    
    -- Add clear option
    if currentEmote then
        table.insert(options, {
            label = 'Clear Emote',
            description = 'Stop playing current emote',
            icon = '❌',
            args = { type = 'clear' }
        })
    end
    
    ShowMenu({
        title = 'Emotes',
        options = options
    })
end

-- Open category menu
function OpenEmoteCategory(categoryName)
    local options = {}
    local categoryEmotes = emotes[categoryName]
    
    for i, emote in ipairs(categoryEmotes) do
        local isFavorite = favoriteEmotes[categoryName .. '_' .. i] ~= nil
        
        table.insert(options, {
            label = emote.name,
            description = isFavorite and '⭐ Favorite' or '',
            icon = '🎭',
            args = { type = 'play', category = categoryName, index = i }
        })
    end
    
    -- Add back button
    table.insert(options, {
        label = '← Back',
        description = 'Return to emote menu',
        icon = '⬅️',
        args = { type = 'back' }
    })
    
    ShowMenu({
        title = categoryName,
        options = options
    })
end

-- Open favorites menu
function OpenFavoritesMenu()
    local options = {}
    
    for emoteKey, favorite in pairs(favoriteEmotes) do
        local emote = emotes[favorite.category][favorite.index]
        
        table.insert(options, {
            label = emote.name,
            description = '⭐ Favorite',
            icon = '🎭',
            args = { type = 'play', category = favorite.category, index = favorite.index }
        })
    end
    
    -- Add back button
    table.insert(options, {
        label = '← Back',
        description = 'Return to emote menu',
        icon = '⬅️',
        args = { type = 'back' }
    })
    
    ShowMenu({
        title = 'Favorite Emotes',
        options = options
    })
end

-- Handle menu selection
RegisterNUICallback('menuItemSelected', function(data, cb)
    if data.args.type == 'category' then
        OpenEmoteCategory(data.args.name)
    elseif data.args.type == 'favorites' then
        OpenFavoritesMenu()
    elseif data.args.type == 'play' then
        PlayEmote(data.args.category, data.args.index)
        CloseMenu()
    elseif data.args.type == 'clear' then
        ClearEmote()
        CloseMenu()
    elseif data.args.type == 'back' then
        OpenEmoteMenu()
    end
    
    emoteMenuOpen = false
    cb({})
end)

RegisterNUICallback('menuClosed', function(data, cb)
    emoteMenuOpen = false
    cb({})
end)

-- Register command
RegisterCommand('pemotes', function()
    OpenEmoteMenu()
end)

-- Key bind to clear emote
CreateThread(function()
    while true do
        Wait(0)
        
        if currentEmote and IsControlJustPressed(0, 73) then -- X key
            ClearEmote()
        end
    end
end)

-- Export functions
exports('PlayEmote', PlayEmote)
exports('ClearEmote', ClearEmote)
exports('ToggleFavorite', ToggleFavorite)

DebugPrint('Emote system loaded')
