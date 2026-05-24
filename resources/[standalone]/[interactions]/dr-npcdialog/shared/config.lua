
Config = {
    MenuAlign = "left", -- left or right
    Dialogs = {

        { 
            Ped = {
                Enable = true,
                coords = vector4(1304.48, 4229.45, 33.91, 100.29),
                hash = "a_m_m_farmer_01", -- Check here https://docs.fivem.net/docs/game-references/ped-models/
                animDict = "amb@world_human_hang_out_street@female_arms_crossed@idle_a",
                animName = "idle_a"
            },
            Blip = { -- https://docs.fivem.net/docs/game-references/blips/
                Enable = true,
                coords = vector3(1304.48, 4229.45, 33.91),
                sprite = 88,
                color = 2,
                scale = 0.5,
                text = "Fishing"
            },
            Menu = {
                Label = "Fishing",
                Description = "MENU",
                Icon = "fas fa-briefcase", -- https://fontawesome.com/v5/search | You can use Pro Icons too
            },
            AutoMessage = { -- This is an automatic message system that sends automatic message when you open dialog menu.
                Enable = true,
                AutoMessages = {
                    {type = "question", text = "Welcome, choose what you want to do."},
                    --{type = "message",  text = "This is an automatic message."}
                }
            },
            Buttons = {
                [1] = { -- Button 2 and answers
                    label = "Fishing Shop",
                    systemAnswer = {enable = true, type = "message", text = "On Shop"},
                    playerAnswer = {enable = true, text ="Ok"},
                    maxClick = 1,
                    onClick = function()
                        -- Write your export or events here
                        -- exports[GetCurrentResourceName()]:closeMenu()
                        TriggerEvent('qb-uwucafe:client:openShop')
                        exports[GetCurrentResourceName()]:closeMenu()
                    end
                },
                [2] = { -- Button 3 and answers
                    label = "See Leaderboard",
                    systemAnswer = {enable = true, type = "message", text = "Check Leaderboard"},
                    playerAnswer = {enable = true, text = "Checking"},
                    maxClick = 1,
                    onClick = function() 
                        TriggerServerEvent('leaderboard:open')
                        exports[GetCurrentResourceName()]:closeMenu()
                    end
                },
                [3] = { -- Button 4 and answers
                label = "Start Delivery",
                systemAnswer = {enable = true, type = "message", text = "Delivery Started"},
                playerAnswer = {enable = false, text = "Understood. Head to the rendezvous point, and be ready to move fast."},
                maxClick = 1,
                onClick = function()
                    
                    TriggerEvent('delivery:start')

                    -- Write your export or events here
                    exports[GetCurrentResourceName()]:closeMenu()
                end
                },
                [4] = { -- Button 4 and answers
                    label = "Leave Conversation",
                    systemAnswer = {enable = false, type = "message", text = "The authorities are closing in. We need a clear path for extraction."},
                    playerAnswer = {enable = false, text = "Understood. Head to the rendezvous point, and be ready to move fast."},
                    maxClick = 1,
                    onClick = function()
                        -- Write your export or events here
                        exports[GetCurrentResourceName()]:closeMenu()
                    end
                },
                -- Don't write more than 5 buttons
            },
            Interaction = {
                Target = {
                    Enable = true,
                    Distance = 2.0,
                    Label = "Contact",
                    Icon = "fa-solid fa-address-book"
                },
                Text = {
                    Enable = false,
                    Distance = 3.0,
                    Label = "[E] Contact"
                },
                DrawText = {
                    Enable = false,
                    Distance = 3.0,
                    Show = function()
                        DrDrawText("Contact", "left")
                    end,
                    Hide = function()
                        DrHideText()
                    end
                }
            }
        },
    }
}
