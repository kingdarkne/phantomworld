Config = {}

Config.npcs = {
    -- Clothing NPCs
   
    {
        name = "Roman Bellic",
        text = "What do you want, mate?",
        job = "Chop Shop",
        ped = "a_m_y_hippy_01",
        coords = vector4(203.9, -2017.5, 17.57, 278.21),
        options = {
            {
                label = "I want to work",
                event = "orbit-chopshop:jobaccept",
                type = "client",
                args = {'1'} -- Komut için argümanlar
            },
            {
                label = "Open Shop",
                event = "qb-shops:server:RestockShopItems:chopping",
                type = "server",
                args = {'2'} -- Komut için argümanlar
            },
            {
                label = "Leave conversation",
                event = "e clubdans4",
                type = "command",
                args = {'3'} -- Komut için argümanlar
            }
        }
    },
    {
        name = "Magie",
        text = "Welcome to Aldore Hospital, how can i help you?",
        job = "unemployed",
        ped = "s_f_y_scrubs_01",
        coords = vector4(-487.5885, -987.9645, 23.2893, 88.1681),
        options = {
            {
                label = "i need medial treatment",
                event = "qb-ambulancejob:checkin",
                type = "client",
                args = {'1'}
            }
        }
    },
    {
        name = "John",
        text = "Roof Running Job",
        job = "unemployed",
        ped = "cs_clay",
        coords = vector4(-658.23, -1707.72, 23.84, 181.96),
        options = {
            {
                label = "Start The Job",
                event = "jomidar-rr:sv:start",
                type = "server",
                args = {'1'}
            },
            {
                label = "Stop The Job",
                event = "jomidar-rr:stop",
                type = "client",
                args = {'2'}
           
            }
        }
    }
}
