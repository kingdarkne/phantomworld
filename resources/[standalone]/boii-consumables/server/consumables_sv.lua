----------------------------------
--<!>-- BOII | DEVELOPMENT --<!>--
----------------------------------

--<!>-- DO NOT EDIT ANYTHING BELOW THIS TEXT UNLESS YOU KNOW WHAT YOU ARE DOING SUPPORT WILL NOT BE PROVIDED IF YOU IGNORE THIS --<!>--
local Core = Config.CoreSettings.Core
local CoreFolder = Config.CoreSettings.CoreFolder
local Core = exports[CoreFolder]:GetCoreObject()
local HudEvent = Config.CoreSettings.HudEvent
--<!>-- DO NOT EDIT ANYTHING ABOVE THIS TEXT UNLESS YOU KNOW WHAT YOU ARE DOING SUPPORT WILL NOT BE PROVIDED IF YOU IGNORE THIS --<!>--

--<!>-- SERVER PRINT --<!>--
AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
      return
    end
    print('^5--<^3!^5>-- ^7BOII ^5| ^7DEVELOPMENT ^5--<^3!^5>-- ^7UTLITY: CONSUMABLES V2.0.3 ^5--<^3!^5>--^7')
end)
--<!>-- SERVER PRINT --<!>--

--<!>-- ADD/REMOVE ITEM EVENTS START --<!>--
-- Remove item event; Added due to recent qb-core update.
RegisterServerEvent('boii-consumables:sv:RemoveItem', function(itemremove, amount)
    local source = source
    local Player = Core.Functions.GetPlayer(source)
    if Player.Functions.RemoveItem(itemremove, tonumber(amount)) then
        TriggerClientEvent('inventory:client:ItemBox', source, Core.Shared.Items[itemremove], 'remove')
    end
end)
-- Add item event; Added due to recent qb-core update.
RegisterServerEvent('boii-consumables:sv:AddItem', function(itemadd, amount)
    local source = source
    local Player = Core.Functions.GetPlayer(source)
    if Player.Functions.AddItem(itemadd, tonumber(amount)) then
        TriggerClientEvent('inventory:client:ItemBox', source, Core.Shared.Items[itemadd], 'add')
    end
end)
--<!>-- ADD/REMOVE ITEM EVENTS END --<!>--

--<!>-- SET META DATA --<!>--
RegisterServerEvent('boii-consumables:sv:SetMeta', function(meta, amount)
    local src = source
    local Player = Core.Functions.GetPlayer(src)
    local hunger = Player.PlayerData.metadata['hunger']
    local thirst = Player.PlayerData.metadata['thirst']
    if meta == 'hunger' then
        newhunger = hunger+amount
        Player.Functions.SetMetaData(meta, newhunger)
        TriggerClientEvent(HudEvent, src, newhunger, thirst)
        return
    end
    if meta == 'thirst' then
        newthirst = thirst+amount
        Player.Functions.SetMetaData(meta, newthirst)
        TriggerClientEvent(HudEvent, src, hunger, newthirst)
        return
    end
end)
--<!>-- SET META DATA --<!>--

--<!>-- EXAMPLE ITEMS START --<!>--
-- Drinks
Core.Functions.CreateUseableItem('water', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptybottle', 'thirst', math.random(10,40), math.random(5,10), 'Drinking Water..', math.random(3,5), 'mp_player_intdrink', 'loop_bottle', 49, 'ba_prop_club_water_bottle', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)
Core.Functions.CreateUseableItem('cocacola', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptycan', 'thirst', math.random(10,40), math.random(5,10), 'Drinking CocaCola..', math.random(3,5), 'mp_player_intdrink', 'loop_bottle', 49, 'prop_ecola_can', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)
Core.Functions.CreateUseableItem('pepsi', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptycan', 'thirst', math.random(10,40), math.random(5,10), 'Drinking Pepsi..', math.random(3,5), 'mp_player_intdrink', 'loop_bottle', 49, 'prop_ld_can_01', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)
Core.Functions.CreateUseableItem('drpepper', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptycan', 'thirst', math.random(10,40), math.random(5,10), 'Drinking Dr Pepper..', math.random(3,5), 'mp_player_intdrink', 'loop_bottle', 49, 'prop_ld_can_01b', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)
Core.Functions.CreateUseableItem('mountaindew', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptycan', 'thirst', math.random(10,40), math.random(5,10), 'Drinking Mtn Dew..', math.random(3,5), 'mp_player_intdrink', 'loop_bottle', 49, 'prop_orang_can_01', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)
Core.Functions.CreateUseableItem('lemonade', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptycan', 'thirst', math.random(10,40), math.random(5,10), 'Drinking Lemonade..', math.random(3,5), 'mp_player_intdrink', 'loop_bottle', 49, 'v_res_tt_can03', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)
Core.Functions.CreateUseableItem('coffee', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptypapercup', 'thirst', math.random(10,40), math.random(5,10), 'Drinking Coffee..', math.random(3,5), 'mp_player_intdrink', 'loop_bottle', 49, 'prop_fib_coffee', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)
Core.Functions.CreateUseableItem('tea', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptypapercup', 'thirst', math.random(10,40), math.random(5,10), 'Drinking Tea..', math.random(3,5), 'mp_player_intdrink', 'loop_bottle', 49, 'p_ing_coffeecup_01', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)
Core.Functions.CreateUseableItem('hotchocolate', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptypapercup', 'thirst', math.random(10,40), math.random(5,10), 'Drinking Hot Chocolate..', math.random(3,5), 'mp_player_intdrink', 'loop_bottle', 49, 'p_amb_coffeecup_01', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)

-- Risky drinks
Core.Functions.CreateUseableItem('dirtywater', function(source, item)
    TriggerClientEvent('boii-consumables:cl:ConsumablesSickness', source, item.name, 'emptybottle', 'thirst', math.random(10,40), math.random(5,10), 50, 'Drinking Dirty Water..', math.random(3,5), 'mp_player_intdrink', 'loop_bottle', 49, 'ba_prop_club_water_bottle', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)
Core.Functions.CreateUseableItem('yellowliquid', function(source, item)
    TriggerClientEvent('boii-consumables:cl:ConsumablesSickness', source, item.name, 'emptybottle', 'thirst', math.random(10,40), math.random(5,10), 50, 'Drinking Yellow Liquid..', math.random(3,5), 'mp_player_intdrink', 'loop_bottle', 49, 'ba_prop_club_tonic_bottle', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)

-- Food
Core.Functions.CreateUseableItem('hersheysbar', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'usedwrapper', 'hunger', math.random(10,40), math.random(5,10), 'Eating A Hersheys Bar..', math.random(3,5), 'mp_player_inteat@pnq', 'loop', 49, 'prop_choc_ego', 60309, vector3(-0.005, 0.00, -0.01), vector3(175.0, 160.0, 0.0))
end)
Core.Functions.CreateUseableItem('mandms', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'cardboard', 'hunger', math.random(10,40), math.random(5,10), 'Eating M&Ms..', math.random(3,5), 'mp_player_inteat@pnq', 'loop', 49, 'prop_choc_pq', 60309, vector3(-0.005, 0.00, -0.01), vector3(175.0, 160.0, 0.0))
end)
Core.Functions.CreateUseableItem('peanutmandms', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'cardboard', 'hunger', math.random(10,40), math.random(5,10), 'Eating Peanut M&Ms..', math.random(3,5), 'mp_player_inteat@pnq', 'loop', 49, 'prop_candy_pqs', 60309, vector3(-0.005, 0.00, -0.01), vector3(175.0, 160.0, 0.0))
end)

-- Risky food
Core.Functions.CreateUseableItem('eggsandwich', function(source, item)
    TriggerClientEvent('boii-consumables:cl:ConsumablesSickness', source, item.name, 'cardboard', 'hunger', math.random(10,40), math.random(5,10), 80, 'Eating Egg Sandwhich..', math.random(3,5), 'mp_player_inteat@burger', 'mp_player_int_eat_burger_fp', 49, 'prop_sandwich_01', 60309, vector3(-0.005, 0.00, -0.01), vector3(175.0, 160.0, 0.0))
end)
Core.Functions.CreateUseableItem('tunasandwich', function(source, item)
    TriggerClientEvent('boii-consumables:cl:ConsumablesSickness', source, item.name, 'cardboard', 'hunger', math.random(10,40), math.random(5,10), 50, 'Eating Egg Sandwhich..', math.random(3,5), 'mp_player_inteat@burger', 'mp_player_int_eat_burger_fp', 49, 'prop_sandwich_01', 60309, vector3(-0.005, 0.00, -0.01), vector3(175.0, 160.0, 0.0))
end)
Core.Functions.CreateUseableItem('hamsandwich', function(source, item)
    TriggerClientEvent('boii-consumables:cl:ConsumablesSickness', source, item.name, 'cardboard', 'hunger', math.random(10,40), math.random(5,10), 20, 'Eating Egg Sandwhich..', math.random(3,5), 'mp_player_inteat@burger', 'mp_player_int_eat_burger_fp', 49, 'prop_sandwich_01', 60309, vector3(-0.005, 0.00, -0.01), vector3(175.0, 160.0, 0.0))
end)

-- Alcohol
Core.Functions.CreateUseableItem('corona', function(source, item)
    TriggerClientEvent('boii-consumables:cl:ConsumablesAlcohol', source, item.name, 'emptyglassbottle', 'thirst', math.random(10,40), math.random(5,10), 10, 'Drinking Corona..', math.random(3,5), 'mp_player_intdrink', 'loop_bottle', 49, 'prop_beer_amopen', 60309, vector3(-0.005, 0.00, -0.09), vector3(0.0, 0.0, 0.0))
end)
Core.Functions.CreateUseableItem('budweiser', function(source, item)
    TriggerClientEvent('boii-consumables:cl:ConsumablesAlcohol', source, item.name, 'emptyglassbottle', 'thirst', math.random(10,40), math.random(5,10), 10, 'Drinking Budweiser..', math.random(3,5), 'mp_player_intdrink', 'loop_bottle', 49, 'prop_beer_logopen', 60309, vector3(-0.005, 0.00, -0.09), vector3(0.0, 0.0, 0.0))
end)
Core.Functions.CreateUseableItem('vodka', function(source, item)
    TriggerClientEvent('boii-consumables:cl:ConsumablesAlcohol', source, item.name, 'emptyglassbottle', 'thirst', math.random(10,40), math.random(5,10), 10, 'Drinking Vodka..', math.random(3,5), 'mp_player_intdrink', 'loop_bottle', 49, 'prop_vodka_bottle', 60309, vector3(-0.005, 0.00, -0.09), vector3(0.0, 0.0, 0.0))
end)
Core.Functions.CreateUseableItem('whiskey', function(source, item)
    TriggerClientEvent('boii-consumables:cl:ConsumablesAlcohol', source, item.name, 'emptyglassbottle', 'thirst', math.random(10,40), math.random(5,10), 10, 'Drinking Whiskey..', math.random(3,5), 'mp_player_intdrink', 'loop_bottle', 49, 'prop_whiskey_bottle', 60309, vector3(-0.005, 0.00, -0.09), vector3(0.0, 0.0, 0.0))
end)
Core.Functions.CreateUseableItem('latte', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptycup', 'thirst', math.random(10,40), math.random(5,10), 'Drinking Latte..', math.random(3,5), 'mp_player_intdrink', 'loop_bottle', 49, 'prop_ld_flow_bottle', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)

Core.Functions.CreateUseableItem('espresso', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptycup', 'thirst', math.random(10,40), math.random(5,10), 'Drinking Espresso..', math.random(3,5), 'mp_player_intdrink', 'loop_bottle', 49, 'prop_ld_flow_bottle', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)

Core.Functions.CreateUseableItem('americano', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptycup', 'thirst', math.random(10,40), math.random(5,10), 'Drinking Americano..', math.random(3,5), 'mp_player_intdrink', 'loop_bottle', 49, 'prop_ld_flow_bottle', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)

Core.Functions.CreateUseableItem('cappuccino', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptycup', 'thirst', math.random(10,40), math.random(5,10), 'Drinking Cappuccino..', math.random(3,5), 'mp_player_intdrink', 'loop_bottle', 49, 'prop_ld_flow_bottle', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)

Core.Functions.CreateUseableItem('macchiato', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptycup', 'thirst', math.random(10,40), math.random(5,10), 'Drinking Macchiato..', math.random(3,5), 'mp_player_intdrink', 'loop_bottle', 49, 'prop_ld_flow_bottle', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)

Core.Functions.CreateUseableItem('croissant', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'usedwrapper', 'hunger', math.random(10,40), math.random(5,10), 'Eating Croissant..', math.random(3,5), 'mp_player_inteat@burger', 'mp_player_int_eat_burger_fp', 49, 'prop_sandwich_01', 60309, vector3(-0.005, 0.00, -0.01), vector3(175.0, 160.0, 0.0))
end)

Core.Functions.CreateUseableItem('pain_au_chocolat', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'usedwrapper', 'hunger', math.random(10,40), math.random(5,10), 'Eating Pain au Chocolat..', math.random(3,5), 'mp_player_inteat@burger', 'mp_player_int_eat_burger_fp', 49, 'prop_sandwich_01', 60309, vector3(-0.005, 0.00, -0.01), vector3(175.0, 160.0, 0.0))
end)

Core.Functions.CreateUseableItem('muffin', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'usedwrapper', 'hunger', math.random(10,40), math.random(5,10), 'Eating Muffin..', math.random(3,5), 'mp_player_inteat@burger', 'mp_player_int_eat_burger_fp', 49, 'prop_sandwich_01', 60309, vector3(-0.005, 0.00, -0.01), vector3(175.0, 160.0, 0.0))
end)

Core.Functions.CreateUseableItem('danish_pastry', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'usedwrapper', 'hunger', math.random(10,40), math.random(5,10), 'Eating Danish Pastry..', math.random(3,5), 'mp_player_inteat@burger', 'mp_player_int_eat_burger_fp', 49, 'prop_sandwich_01', 60309, vector3(-0.005, 0.00, -0.01), vector3(175.0, 160.0, 0.0))
end)

Core.Functions.CreateUseableItem('scone', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'usedwrapper', 'hunger', math.random(10,40), math.random(5,10), 'Eating Scone..', math.random(3,5), 'mp_player_inteat@burger', 'mp_player_int_eat_burger_fp', 49, 'prop_sandwich_01', 60309, vector3(-0.005, 0.00, -0.01), vector3(175.0, 160.0, 0.0))
end)

Core.Functions.CreateUseableItem('cheesecake', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'usedwrapper', 'hunger', math.random(10,40), math.random(5,10), 'Eating Cheesecake..', math.random(3,5), 'mp_player_inteat@burger', 'mp_player_int_eat_burger_fp', 49, 'prop_sandwich_01', 60309, vector3(-0.005, 0.00, -0.01), vector3(175.0, 160.0, 0.0))
end)

Core.Functions.CreateUseableItem('chocolate_cake', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'usedwrapper', 'hunger', math.random(10,40), math.random(5,10), 'Eating Chocolate Cake..', math.random(3,5), 'mp_player_inteat@burger', 'mp_player_int_eat_burger_fp', 49, 'prop_sandwich_01', 60309, vector3(-0.005, 0.00, -0.01), vector3(175.0, 160.0, 0.0))
end)

Core.Functions.CreateUseableItem('apple_pie', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'usedwrapper', 'hunger', math.random(10,40), math.random(5,10), 'Eating Apple Pie..', math.random(3,5), 'mp_player_inteat@burger', 'mp_player_int_eat_burger_fp', 49, 'prop_sandwich_01', 60309, vector3(-0.005, 0.00, -0.01), vector3(175.0, 160.0, 0.0))
end)

Core.Functions.CreateUseableItem('brownie', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'usedwrapper', 'hunger', math.random(10,40), math.random(5,10), 'Eating Brownie..', math.random(3,5), 'mp_player_inteat@burger', 'mp_player_int_eat_burger_fp', 49, 'prop_sandwich_01', 60309, vector3(-0.005, 0.00, -0.01), vector3(175.0, 160.0, 0.0))
end)

Core.Functions.CreateUseableItem('macarons', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'usedwrapper', 'hunger', math.random(10,40), math.random(5,10), 'Eating Macarons..', math.random(3,5), 'mp_player_inteat@burger', 'mp_player_int_eat_burger_fp', 49, 'prop_sandwich_01', 60309, vector3(-0.005, 0.00, -0.01), vector3(175.0, 160.0, 0.0))
end)

Core.Functions.CreateUseableItem('tiramisu', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'usedwrapper', 'hunger', math.random(10,40), math.random(5,10), 'Eating Tiramisu..', math.random(3,5), 'mp_player_inteat@burger', 'mp_player_int_eat_burger_fp', 49, 'prop_sandwich_01', 60309, vector3(-0.005, 0.00, -0.01), vector3(175.0, 160.0, 0.0))
end)

Core.Functions.CreateUseableItem('lemon_tart', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'usedwrapper', 'hunger', math.random(10,40), math.random(5,10), 'Eating Lemon Tart..', math.random(3,5), 'mp_player_inteat@burger', 'mp_player_int_eat_burger_fp', 49, 'prop_sandwich_01', 60309, vector3(-0.005, 0.00, -0.01), vector3(175.0, 160.0, 0.0))
end)

Core.Functions.CreateUseableItem('fruit_tart', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'usedwrapper', 'hunger', math.random(10,40), math.random(5,10), 'Eating Fruit Tart..', math.random(3,5), 'mp_player_inteat@burger', 'mp_player_int_eat_burger_fp', 49, 'prop_sandwich_01', 60309, vector3(-0.005, 0.00, -0.01), vector3(175.0, 160.0, 0.0))
end)
Core.Functions.CreateUseableItem('burgerxl', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptywrapper', 'hunger', math.random(20,50), math.random(5,10), 'Eating Three Patty Burger..', math.random(3,5), 'mp_player_inteat@burger', 'mp_player_int_eat_burger_fp', 49, 'prop_cs_burger_01', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)

Core.Functions.CreateUseableItem('chickenburger', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptywrapper', 'hunger', math.random(20,50), math.random(5,10), 'Eating Chicken Burger..', math.random(3,5), 'mp_player_inteat@burger', 'mp_player_int_eat_burger_fp', 49, 'prop_cs_burger_01', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)

Core.Functions.CreateUseableItem('chickenpotato', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptywrapper', 'hunger', math.random(20,50), math.random(5,10), 'Eating Chicken Potato..', math.random(3,5), 'mp_player_inteat@burger', 'mp_player_int_eat_burger_fp', 49, 'prop_cs_burger_01', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)

Core.Functions.CreateUseableItem('crispychicken', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptywrapper', 'hunger', math.random(20,50), math.random(5,10), 'Eating Crispy Chicken..', math.random(3,5), 'mp_player_inteat@burger', 'mp_player_int_eat_burger_fp', 49, 'prop_cs_burger_01', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)

Core.Functions.CreateUseableItem('tenderloin', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptywrapper', 'hunger', math.random(20,50), math.random(5,10), 'Eating Tenderloin..', math.random(3,5), 'mp_player_inteat@burger', 'mp_player_int_eat_burger_fp', 49, 'prop_cs_burger_01', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)

Core.Functions.CreateUseableItem('onionring', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptywrapper', 'hunger', math.random(20,50), math.random(5,10), 'Eating Onion Ring..', math.random(3,5), 'mp_player_inteat@burger', 'mp_player_int_eat_burger_fp', 49, 'prop_cs_burger_01', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)
Core.Functions.CreateUseableItem('ramen', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptybowl', 'hunger', math.random(20,50), math.random(5,10), 'Eating Ramen..', math.random(3,5), 'mp_player_inteat@pnq', 'loop', 49, 'prop_food_bag1', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)

Core.Functions.CreateUseableItem('pad_thai', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptybowl', 'hunger', math.random(20,50), math.random(5,10), 'Eating Pad Thai..', math.random(3,5), 'mp_player_inteat@pnq', 'loop', 49, 'prop_food_bag1', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)

Core.Functions.CreateUseableItem('udon', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptybowl', 'hunger', math.random(20,50), math.random(5,10), 'Eating Udon..', math.random(3,5), 'mp_player_inteat@pnq', 'loop', 49, 'prop_food_bag1', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)

Core.Functions.CreateUseableItem('pho', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptybowl', 'hunger', math.random(20,50), math.random(5,10), 'Eating Pho..', math.random(3,5), 'mp_player_inteat@pnq', 'loop', 49, 'prop_food_bag1', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)

Core.Functions.CreateUseableItem('lo_mein', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptybowl', 'hunger', math.random(20,50), math.random(5,10), 'Eating Lo Mein..', math.random(3,5), 'mp_player_inteat@pnq', 'loop', 49, 'prop_food_bag1', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)
Core.Functions.CreateUseableItem('margherita_pizza', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptybox', 'hunger', math.random(20,50), math.random(5,10), 'Eating Margherita Pizza..', math.random(3,5), 'mp_player_inteat@pnq', 'loop', 49, 'v_res_tt_pizzaplate', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)

Core.Functions.CreateUseableItem('pepperoni_pizza', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptybox', 'hunger', math.random(20,50), math.random(5,10), 'Eating Pepperoni Pizza..', math.random(3,5), 'mp_player_intdrink', 'loop', 49, 'v_res_tt_pizzaplate', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)

Core.Functions.CreateUseableItem('vegetarian_pizza', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptybox', 'hunger', math.random(20,50), math.random(5,10), 'Eating Vegetarian Pizza..', math.random(3,5), 'mp_player_inteat@pnq', 'loop', 49, 'v_res_tt_pizzaplate', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)

Core.Functions.CreateUseableItem('bbq_chicken_pizza', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptybox', 'hunger', math.random(20,50), math.random(5,10), 'Eating BBQ Chicken Pizza..', math.random(3,5), 'mp_player_inteat@pnq', 'loop', 49, 'v_res_tt_pizzaplate', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)

Core.Functions.CreateUseableItem('hawaiian_pizza', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptybox', 'hunger', math.random(20,50), math.random(5,10), 'Eating Hawaiian Pizza..', math.random(3,5), 'mp_player_inteat@pnq', 'loop', 49, 'v_res_tt_pizzaplate', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)

Core.Functions.CreateUseableItem('buffalo_chicken_pizza', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptybox', 'hunger', math.random(20,50), math.random(5,10), 'Eating Buffalo Chicken Pizza..', math.random(3,5), 'mp_player_inteat@pnq', 'loop', 49, 'v_res_tt_pizzaplate', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)

Core.Functions.CreateUseableItem('meat_lovers_pizza', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptybox', 'hunger', math.random(20,50), math.random(5,10), 'Eating Meat Lovers Pizza..', math.random(3,5), 'mp_player_inteat@pnq', 'loop', 49, 'v_res_tt_pizzaplate', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)

Core.Functions.CreateUseableItem('four_cheese_pizza', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptybox', 'hunger', math.random(20,50), math.random(5,10), 'Eating Four Cheese Pizza..', math.random(3,5), 'mp_player_inteat@pnq', 'loop', 49, 'v_res_tt_pizzaplate', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)

Core.Functions.CreateUseableItem('spinach_alfredo_pizza', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptybox', 'hunger', math.random(20,50), math.random(5,10), 'Eating Spinach Alfredo Pizza..', math.random(3,5), 'mp_player_inteat@pnq', 'loop', 49, 'v_res_tt_pizzaplate', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)

Core.Functions.CreateUseableItem('calzone', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptybox', 'hunger', math.random(20,50), math.random(5,10), 'Eating Calzone..', math.random(3,5), 'mp_player_inteat@pnq', 'loop', 49, 'v_res_tt_pizzaplate', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)
Core.Functions.CreateUseableItem('kurkakola', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptycan', 'thirst', math.random(10,40), math.random(5,10), 'Drinking CocaCola..', math.random(3,5), 'mp_player_intdrink', 'loop_bottle', 49, 'prop_ecola_can', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)

Core.Functions.CreateUseableItem('water_bottle', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptybottle', 'thirst', math.random(10,40), math.random(5,10), 'Drinking Water..', math.random(3,5), 'mp_player_intdrink', 'loop_bottle', 49, 'ba_prop_club_water_bottle', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)

Core.Functions.CreateUseableItem('coffee', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptypapercup', 'thirst', math.random(10,40), math.random(5,10), 'Drinking Coffee..', math.random(3,5), 'mp_player_intdrink', 'loop_bottle', 49, 'prop_fib_coffee', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)

Core.Functions.CreateUseableItem('icetea', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptybottle', 'thirst', math.random(10,40), math.random(5,10), 'Drinking Ice Tea..', math.random(3,5), 'mp_player_intdrink', 'loop_bottle', 49, 'prop_orang_can_01', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)

Core.Functions.CreateUseableItem('milkshake', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptybottle', 'thirst', math.random(10,40), math.random(5,10), 'Drinking Milkshake..', math.random(3,5), 'mp_player_intdrink', 'loop_bottle', 49, 'prop_ecola_can', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)

Core.Functions.CreateUseableItem('coollime', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptybottle', 'thirst', math.random(10,40), math.random(5,10), 'Drinking Cool Lime..', math.random(3,5), 'mp_player_intdrink', 'loop_bottle', 49, 'prop_orang_can_01', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)

Core.Functions.CreateUseableItem('latte', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptycup', 'thirst', math.random(10,40), math.random(5,10), 'Drinking Latte..', math.random(3,5), 'mp_player_intdrink', 'loop_bottle', 49, 'prop_ld_flow_bottle', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)

Core.Functions.CreateUseableItem('espresso', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptycup', 'thirst', math.random(10,40), math.random(5,10), 'Drinking Espresso..', math.random(3,5), 'mp_player_intdrink', 'loop_bottle', 49, 'prop_ld_flow_bottle', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)

Core.Functions.CreateUseableItem('americano', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptycup', 'thirst', math.random(10,40), math.random(5,10), 'Drinking Americano..', math.random(3,5), 'mp_player_intdrink', 'loop_bottle', 49, 'prop_ld_flow_bottle', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)

Core.Functions.CreateUseableItem('cappuccino', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptycup', 'thirst', math.random(10,40), math.random(5,10), 'Drinking Cappuccino..', math.random(3,5), 'mp_player_intdrink', 'loop_bottle', 49, 'prop_ld_flow_bottle', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)

Core.Functions.CreateUseableItem('macchiato', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptycup', 'thirst', math.random(10,40), math.random(5,10), 'Drinking Macchiato..', math.random(3,5), 'mp_player_intdrink', 'loop_bottle', 49, 'prop_ld_flow_bottle', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)

Core.Functions.CreateUseableItem('green_tea', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptycup', 'thirst', math.random(10,40), math.random(5,10), 'Drinking Green Tea..', math.random(3,5), 'mp_player_intdrink', 'loop_bottle', 49, 'prop_fib_coffee', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)
Core.Functions.CreateUseableItem('cookie', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptywrapper', 'hunger', math.random(20,50), math.random(5,10), 'Eating Cookie..', math.random(3,5), 'mp_player_inteat@pnq', 'loop', 49, 'prop_candy_pqs', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)

Core.Functions.CreateUseableItem('donut', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptywrapper', 'hunger', math.random(20,50), math.random(5,10), 'Eating Donut..', math.random(3,5), 'mp_player_inteat@pnq', 'loop', 49, 'prop_food_bs_burger2', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)

Core.Functions.CreateUseableItem('waffle', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptywrapper', 'hunger', math.random(20,50), math.random(5,10), 'Eating Waffle..', math.random(3,5), 'mp_player_inteat@pnq', 'loop', 49, 'prop_candy_pqs', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)

Core.Functions.CreateUseableItem('cheesecake', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptywrapper', 'hunger', math.random(20,50), math.random(5,10), 'Eating Cheesecake..', math.random(3,5), 'mp_player_inteat@pnq', 'loop', 49, 'prop_candy_pqs', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)

Core.Functions.CreateUseableItem('chocolate_cake', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptywrapper', 'hunger', math.random(20,50), math.random(5,10), 'Eating Chocolate Cake..', math.random(3,5), 'mp_player_inteat@pnq', 'loop', 49, 'prop_candy_pqs', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)

Core.Functions.CreateUseableItem('apple_pie', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptywrapper', 'hunger', math.random(20,50), math.random(5,10), 'Eating Apple Pie..', math.random(3,5), 'mp_player_inteat@pnq', 'loop', 49, 'prop_candy_pqs', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)

Core.Functions.CreateUseableItem('brownie', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptywrapper', 'hunger', math.random(20,50), math.random(5,10), 'Eating Brownie..', math.random(3,5), 'mp_player_inteat@pnq', 'loop', 49, 'prop_candy_pqs', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)

Core.Functions.CreateUseableItem('macarons', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptywrapper', 'hunger', math.random(20,50), math.random(5,10), 'Eating Macarons..', math.random(3,5), 'mp_player_inteat@pnq', 'loop', 49, 'prop_candy_pqs', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)

Core.Functions.CreateUseableItem('tiramisu', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptywrapper', 'hunger', math.random(20,50), math.random(5,10), 'Eating Tiramisu..', math.random(3,5), 'mp_player_inteat@pnq', 'loop', 49, 'prop_candy_pqs', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)

Core.Functions.CreateUseableItem('lemon_tart', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptywrapper', 'hunger', math.random(20,50), math.random(5,10), 'Eating Lemon Tart..', math.random(3,5), 'mp_player_inteat@pnq', 'loop', 49, 'prop_candy_pqs', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)

Core.Functions.CreateUseableItem('fruit_tart', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Consumables', source, item.name, 'emptywrapper', 'hunger', math.random(20,50), math.random(5,10), 'Eating Fruit Tart..', math.random(3,5), 'mp_player_inteat@pnq', 'loop', 49, 'prop_candy_pqs', 60309, vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, 0.0))
end)

-- 6 packs
Core.Functions.CreateUseableItem('corona6pack', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Open6Pack', source, item.name, 'corona', 'You opened a 6 pack of Corona!')
end)
Core.Functions.CreateUseableItem('budweiser6pack', function(source, item)
    TriggerClientEvent('boii-consumables:cl:Open6Pack', source, item.name, 'budweiser', 'You opened a 6 pack of Budweiser!')
end)
--<!>-- EXAMPLE ITEMS END --<!>--
