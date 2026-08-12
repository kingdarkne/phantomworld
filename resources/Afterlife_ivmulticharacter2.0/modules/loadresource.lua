CreateThread(function()
	while true do
		if NetworkIsSessionStarted() then
			LoadResource()
			break
		end
		Wait(100)
	end
end)


LoadResource = function()
	print('[Multicharacter] LoadResource started...')

	-- Close NC loading screen once the session is ready (do not hard-wait 60s)
	local waited = 0
	while waited < 5000 do
		Wait(250)
		waited = waited + 250
		if waited >= 1500 then
			break
		end
	end

	ShutdownLoadingScreen()
	ShutdownLoadingScreenNui()
	DisplayRadar(false)
	TriggerServerEvent('Update:RoutingBucket', math.random(1000, 10000))

	-- Wait for player ped to exist
	local attempts = 0
	while not DoesEntityExist(PlayerPedId()) and attempts < 50 do
		Wait(100)
		attempts = attempts + 1
	end

	if not DoesEntityExist(PlayerPedId()) then
		print('[Multicharacter] ERROR: Player ped does not exist!')
		return
	end

	print('[Multicharacter] Player ped ready, fading in...')
	DoScreenFadeIn(500)
	Wait(500)

	-- JOIN ORDER: loading screen → city tour → multichar → outfit → spawn
	local tourDone = false
	local tourHandler
	tourHandler = AddEventHandler('phantom_citytour:client:finished', function()
		tourDone = true
	end)

	local started = false
	if GetResourceState('phantom_citytour') == 'started' then
		local ok, err = pcall(function()
			exports['phantom_citytour']:StartCityTourPreMultichar()
			started = true
		end)
		if not ok then
			print(('[Multicharacter] City tour failed to start: %s'):format(tostring(err)))
		end
	else
		print('[Multicharacter] phantom_citytour not started — skipping tour')
	end

	if started then
		local timeout = GetGameTimer() + 180000 -- 3 min max
		while not tourDone and GetGameTimer() < timeout do
			Wait(200)
		end
	end

	if tourHandler then
		RemoveEventHandler(tourHandler)
	end

	-- Hand off to character select
	CharactersMenu()
end
