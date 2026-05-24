Dracula = {} or Dracula

Dracula.UseStartVoice = 'yes'                            -- 'yes', or 'no' if you want use the start voice
Dracula.SpawnPedLoc = vector3(-1045.0, -2750.29, 20.36) -- spawn coords , if you wanna change the coords make sure you -1 for z coords example ( 21.36 = 20.36)

Dracula.Volume = {
    UseStartVoice = 0.5, -- sound volume
    UseLoadVoice = 0.3   -- sound volume
}

Dracula.OnStart = function()
    exports["dr-HUD"]:ToggleVisible(false)
end

Dracula.OnFinish = function()
    exports["dr-HUD"]:ToggleVisible(true)
end