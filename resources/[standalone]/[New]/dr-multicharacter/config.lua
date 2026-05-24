Config = {}
Config.Interior = vector3(-1008.19, -475.38, 50.03)          -- Interior to load where characters are previewed vector4(-798.99, 170.74, 76.75, 66.99)
Config.DefaultSpawn = vector3(-1005.9592, -475.7525, 50.0268)  -- Default spawn coords if you have start apartments disabled
Config.PedCoords = vector4(-1009.85, -479.09, 50.03, 123.37) -- Create preview ped at these coordinates
Config.HiddenCoords = vector4(-806.87, 184.58, 75.0, 207.57) -- Hides your actual ped while you are in selection
Config.CamCoords = vector4(-1007.4, -474.82, 50.20, 147.99)  -- Camera coordinates for character preview screen vector4(-800.37, 170.68, 76.75, 260.85)
Config.EnableDeleteButton = false -- Define if the player can delete the character or not

Config.DefaultNumberOfCharacters = 2 --  Max 4 // Dont Go More Than 4
Config.PlayersNumberOfCharacters = { -- Define maximum amount of player characters by rockstar license (you can find this license in your server's database in the player table)
    { license = "license:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx", numberOfChars = 2 },
}

Config.cinematiclocation = {
    [1] = vector4(-1007.53, -480.73, 50.22, 15.44), --start
    [2] = vector4(-1007.53, -479.14, 50.52, 15.44), --start left to right
    [3] = vector4(-1004.53, -477.33, 50.52, 75.44),  --stop right
    [4] = vector4(-1006.53, -473.53, 50.52, 135.00),  --move other way and right to left
    [5] = vector4(-1011.03, -476.33, 50.52, 275.00),  --stop left
}