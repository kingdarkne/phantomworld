--- Phantom World Discord Rich Presence
--- Owns presence so ND_Core / Qbox defaults ("ND Core", "Qbox Ducky") cannot win.

local APP_ID = GetConvar('phantom:discordAppId', '849173210838466561')
local ASSET_LARGE = GetConvar('phantom:discordAsset', 'phantom')
local ASSET_SMALL = GetConvar('phantom:discordAssetSmall', 'phantom')
local USE_ASSETS = GetConvarInt('phantom:discordUseAssets', 0) == 1 -- enable after uploading RPC art in Discord portal
local ACTION1_TEXT = GetConvar('phantom:discordAction1Text', 'Join Game')
local ACTION1_URL = GetConvar('phantom:discordAction1Url', 'https://cfx.re/join/3m87mo')
local ACTION2_TEXT = GetConvar('phantom:discordAction2Text', 'Discord')
local ACTION2_URL = GetConvar('phantom:discordAction2Url', 'https://discord.gg/phantomworld')
local SERVER_TITLE = GetConvar('phantom:discordServerName', 'Phantom World')
local REFRESH_MS = math.max(5000, (tonumber(GetConvar('phantom:discordRefreshSeconds', '15')) or 15) * 1000)

local function playerCountLabel()
    local count = GlobalState.PlayerCount
    local maxPlayers = GlobalState.MaxPlayers or GetConvarInt('sv_maxclients', 48)
    if type(count) == 'number' then
        return ('%s/%s online'):format(count, maxPlayers)
    end
    return nil
end

local function characterLabel()
    -- Qbox / QB
    local pd = LocalPlayer.state and LocalPlayer.state.PlayerData
    if pd and pd.charinfo then
        local first = pd.charinfo.firstname or pd.charinfo.firstName
        local last = pd.charinfo.lastname or pd.charinfo.lastName
        if first and last and first ~= '' then
            return ('%s %s'):format(first, last)
        end
    end
    -- ND fallback
    if NDCore and NDCore.player and NDCore.player.firstname then
        return ('%s %s'):format(NDCore.player.firstname, NDCore.player.lastname or '')
    end
    return nil
end

local function buildPresence()
    local charName = characterLabel()
    local players = playerCountLabel()
    if charName and players then
        return ('🌆 %s — playing as %s · %s'):format(SERVER_TITLE, charName, players)
    end
    if charName then
        return ('🌆 %s — playing as %s'):format(SERVER_TITLE, charName)
    end
    if players then
        return ('🌆 %s · %s — cfx.re/join/3m87mo'):format(SERVER_TITLE, players)
    end
    return ('🌆 %s — premium FiveM RP'):format(SERVER_TITLE)
end

local function applyPresence()
    SetDiscordAppId(APP_ID)

    if USE_ASSETS and ASSET_LARGE ~= '' then
        SetDiscordRichPresenceAsset(ASSET_LARGE)
        SetDiscordRichPresenceAssetText(SERVER_TITLE)
    end
    if USE_ASSETS and ASSET_SMALL ~= '' then
        SetDiscordRichPresenceAssetSmall(ASSET_SMALL)
        SetDiscordRichPresenceAssetSmallText(playerCountLabel() or 'Join the city')
    end

    SetDiscordRichPresenceAction(0, ACTION1_TEXT, ACTION1_URL)
    SetDiscordRichPresenceAction(1, ACTION2_TEXT, ACTION2_URL)
    SetRichPresence(buildPresence())
end

CreateThread(function()
    -- Let other frameworks finish starting, then take ownership and keep it.
    Wait(2500)
    while true do
        applyPresence()
        Wait(REFRESH_MS)
    end
end)

AddStateBagChangeHandler('PlayerCount', 'global', function()
    applyPresence()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(500)
    applyPresence()
end)

RegisterNetEvent('qbx_core:client:playerLoaded', function()
    Wait(500)
    applyPresence()
end)

print(('[phantom_discord_presence] Rich Presence ready — %s | %s | %s'):format(
    SERVER_TITLE, ACTION1_URL, ACTION2_URL
))
