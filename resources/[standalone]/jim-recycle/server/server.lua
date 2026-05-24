local function oxItemExists(name)
	local d = exports.ox_inventory:Items(name)
	return d ~= nil
end

AddEventHandler('onResourceStart', function(resource) if GetCurrentResourceName() ~= resource then return end
	if Config.Inv == "ox" then
		for k in pairs(Config.Prices) do if not oxItemExists(k) then print("^5Debug^7: ^6Prices^7: ^2Missing ox_inventory item^7: '^6"..k.."^7'") end end
		if not oxItemExists("recyclablematerial") then print("^5Debug^7: ^2Missing ox_inventory item^7: '^6recyclablematerial^7'") end
		for _, v in pairs(Config.ScrapItems) do if not oxItemExists(v) then print("^5Debug^7: ^6ScrapItems^7: ^2Missing ox_inventory item^7: '^6"..v.."^7'") end end
		for _, v in pairs(Config.DumpItems) do if not oxItemExists(v) then print("^5Debug^7: ^2DumpItems^7: ^2Missing ox_inventory item^7: '^6"..v.."^7'") end end
		return
	end
	for k in pairs(Config.Prices) do if not Core.Shared.Items[k] then print("^5Debug^7: ^6Prices^7: ^2Missing Item from ^4QBCore^7.^4Shared^7.^4Items^7: '^6"..k.."^7'") end end
	if not Core.Shared.Items["recyclablematerial"] then print("^5Debug^7: ^2Missing Item from ^4QBCore^7.^4Shared^7.^4Items^7: '^6recyclablematerial^7'") end
	for _, v in pairs(Config.ScrapItems) do if not Core.Shared.Items[v] then print("^5Debug^7: ^6ScrapItems^7: ^2Missing Item from ^4QBCore^7.^4Shared^7.^4Items^7: '^6"..v.."^7'") end end
	for _, v in pairs(Config.DumpItems) do if not Core.Shared.Items[v] then print("^5Debug^7: ^2DumpItems^7: ^2Missing Item from ^4QBCore^7.^4Shared^7.^4Items^7: '^6"..v.."^7'") end end
end)

Core.Functions.CreateCallback('jim-recycle:GetCash', function(source, cb) cb(Core.Functions.GetPlayer(source).Functions.GetMoney("cash")) end)

RegisterServerEvent("jim-recycle:DoorCharge", function()
	local src = source
	if Config.Inv == "ox" then TriggerEvent("jim-recycle:server:toggleItem", false, "money", Config.PayAtDoor, src)
	else Core.Functions.GetPlayer(src).Functions.RemoveMoney("cash", Config.PayAtDoor) end
end)

RegisterServerEvent("jim-recycle:TradeItems", function(data)
    local src = source
	local table = {}
	for i = 1, #Config.RecycleAmounts["Trade"] do
		if Config.RecycleAmounts["Trade"][i].amount == data.amount then
			table = Config.RecycleAmounts["Trade"][i]
		end
	end
	TriggerEvent("jim-recycle:server:toggleItem", false, "recyclablematerial", data.amount, src)
	Wait(1000)
	for i = 1, table.itemGive do
		TriggerEvent("jim-recycle:server:toggleItem", true, Config.TradeTable[math.random(1, #Config.TradeTable)], math.random(table.Min, table.Max), src)
		Wait(100)
	end
end)

RegisterNetEvent("jim-recycle:Selling:Mat", function(data)
    local src = source
	local amount = 0
	if Config.Inv == "ox" then
		amount = exports.ox_inventory:Search(src, 'count', data.item) or 0
	else
		local itemData = Core.Functions.GetPlayer(src).Functions.GetItemByName(data.item)
		amount = itemData and itemData.amount or 0
	end
	local pay = (amount * Config.Prices[data.item])

	if amount > 0 and HasItem(src, data.item, amount) then
		TriggerEvent("jim-recycle:server:toggleItem", false, data.item, amount, src)
		Core.Functions.GetPlayer(src).Functions.AddMoney('cash', pay)
		triggerNotify(nil, Loc[Config.Lan].success["get_paid"]..pay, "success", src)
	end
	TriggerClientEvent("jim-recycle:Selling:Menu", src, data)
end)

local function dupeWarn(src, item)
	local P = Core.Functions.GetPlayer(src)
	print("^5DupeWarn: ^1"..P.PlayerData.charinfo.firstname.." "..P.PlayerData.charinfo.lastname.."^7(^1"..tostring(src).."^7) ^2Tried to remove item ^7('^3"..item.."^7')^2 but it wasn't there^7")
	if not Config.Debug then DropPlayer(src, "^1Kicked for attempting to duplicate items") end
	print("^5DupeWarn: ^1"..P.PlayerData.charinfo.firstname.." "..P.PlayerData.charinfo.lastname.."^7(^1"..tostring(src).."^7) ^2Dropped from server for item duplicating^7")
end

if Config.Inv == "ox" then
	function HasItem(src, items, amount)
		local need = amount or 1
		if need < 1 then need = 1 end
		local count = exports.ox_inventory:Search(src, 'count', items)
		if count >= need then
			if Config.Debug then print("^5Debug^7: ^3HasItem^7: ^5FOUND^7 x^3"..count.."^7 ^3"..tostring(items)) end return true
        else if Config.Debug then print("^5Debug^7: ^3HasItem^7: ^2Items ^1NOT FOUND^7") end return false end
	end
else
	function HasItem(source, items, amount)
		local amount, count = amount or 1, 0
		local Player = Core.Functions.GetPlayer(source)
		if Config.Debug then print("^5Debug^7: ^3HasItem^7: ^2Checking if player has required item^7 '^3"..tostring(items).."^7'") end
		for _, itemData in pairs(Player.PlayerData.items) do
			if itemData and (itemData.name == items) then
				if Config.Debug then print("^5Debug^7: ^3HasItem^7: ^2Item^7: '^3"..tostring(items).."^7' ^2Slot^7: ^3"..itemData.slot.." ^7x(^3"..tostring(itemData.amount).."^7)") end
				count += itemData.amount
			end
		end
		if count >= amount then if Config.Debug then print("^5Debug^7: ^3HasItem^7: ^2Items ^5FOUND^7 x^3"..count.."^7") end return true end
		if Config.Debug then print("^5Debug^7: ^3HasItem^7: ^2Items ^1NOT FOUND^7") end	return false
	end
end

RegisterNetEvent('jim-recycle:server:toggleItem', function(give, item, amount, newsrc)
	local src = newsrc or source
	local Player = Core.Functions.GetPlayer(src)
	local remamount = (amount or 1)
	if give == 0 or give == false then
		if HasItem(src, item, amount or 1) then
			if Config.Inv == "ox" then
				exports.ox_inventory:RemoveItem(src, item, amount or 1)
				if Config.Debug then
					local d = exports.ox_inventory:Items(item)
					local label = d and d.label or item
					print("^5Debug^7: ^1Removing ^2from Player^7(^2"..src.."^7) '^6"..label.."^7'(^2x^6"..(amount or "1").."^7)")
				end
			else
				while remamount > 0 do if Player.Functions.RemoveItem(item, 1) then end remamount -= 1 end
				TriggerClientEvent('inventory:client:ItemBox', src, Core.Shared.Items[item], "remove", amount or 1)
				if Config.Debug then print("^5Debug^7: ^1Removing ^2from Player^7(^2"..src.."^7) '^6"..Core.Shared.Items[item].label.."^7'(^2x^6"..(amount or "1").."^7)") end
			end
		else dupeWarn(src, item) end
	else
		if Config.Inv == "ox" then
			if exports.ox_inventory:AddItem(src, item, amount or 1) then
				if Config.Debug then
					local d = exports.ox_inventory:Items(item)
					local label = d and d.label or item
					print("^5Debug^7: ^4Giving ^2Player^7(^2"..src.."^7) '^6"..label.."^7'(^2x^6"..(amount or "1").."^7)")
				end
			end
		else
			if Player.Functions.AddItem(item, amount or 1) then
				TriggerClientEvent('inventory:client:ItemBox', src, Core.Shared.Items[item], "add", amount or 1)
				if Config.Debug then
					print("^5Debug^7: ^4Giving ^2Player^7(^2"..src.."^7) '^6"..Core.Shared.Items[item].label.."^7'(^2x^6"..(amount or "1").."^7)") end
			end
		end
	end
end)
