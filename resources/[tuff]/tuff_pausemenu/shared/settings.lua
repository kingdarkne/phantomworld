
-- ▀█▀ █░█ ▄▀█ █▄░█ █▄▀   █▄█ █▀█ █░█   █▀▀ █▀█ █▀█   █▀█ █░█ █▀█ █▀▀ █░█ ▄▀█ █▀ █▀▀
-- ░█░ █▀█ █▀█ █░▀█ █░█   ░█░ █▄█ █▄█   █▀░ █▄█ █▀▄   █▀▀ █▄█ █▀▄ █▄▄ █▀█ █▀█ ▄█ ██▄

-- Do not touch.
Framework = (GetResourceState("es_extended") == "started" and exports['es_extended']:getSharedObject()) or (GetResourceState("qbx_core") == "started" and exports['qbx_core']:GetCoreObject()) or nil

Settings = {}
Settings.ForceStandalone = false
Settings.Framework = (GetResourceState("es_extended") == "started" and "ESX") or (GetResourceState("qbx_core") == "started" and "Qbox") or nil
Settings.Standalone = Settings.ForceStandalone or (Settings.Framework == nil)
-------------------------------------------------------------------------------

Settings.CinematicCamera = {
    enabled = true
}

Settings.PlayerInfo = {
    showName = true,
    showCash = true,
    showBank = true,
    showJob = true
}

Settings.StandaloneInfo = {
    showLogo = true,
    showId = true,
    showLocation = true
}

Settings.Socials = {
    youtube = {
        enabled = true,
        url = "https://www.youtube.com/channel/UCHHl48TO0upGaTjiNAhrarQ"
    },
    discord = {
        enabled = true,
        url = "https://discord.gg/rJGkVkqcMe"
    },
    tebex = {
        enabled = true,
        url = "https://tuff-scripts.tebex.io/"
    }
}
