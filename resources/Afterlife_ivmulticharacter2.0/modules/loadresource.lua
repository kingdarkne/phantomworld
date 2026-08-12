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

	-- Short settle so NUI/session attach (do not burn 5s+)
	Wait(750)

	ShutdownLoadingScreen()
	ShutdownLoadingScreenNui()
	DisplayRadar(false)
	TriggerServerEvent('Update:RoutingBucket', math.random(1000, 10000))

	-- Wait briefly for ped — never abort join if ped is late
	local attempts = 0
	while not DoesEntityExist(PlayerPedId()) and attempts < 50 do
		Wait(100)
		attempts = attempts + 1
	end

	if not DoesEntityExist(PlayerPedId()) then
		print('[Multicharacter] WARN: Player ped not ready yet — continuing to menu')
	else
		print('[Multicharacter] Player ped ready, fading in...')
	end

	DoScreenFadeIn(400)
	Wait(200)

	-- Optional city tour before multichar (disabled by default for freeroam speed)
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
			tourDone = true
		end
	else
		tourDone = true
	end

	if started and not tourDone then
		-- Cap wait tightly; freeroam config finishes immediately via finished event
		local timeout = GetGameTimer() + 45000
		while not tourDone and GetGameTimer() < timeout do
			Wait(100)
		end
		if not tourDone then
			print('[Multicharacter] City tour timed out — forcing CharactersMenu')
			pcall(function()
				exports['phantom_citytour']:StopCityTour(true)
			end)
			tourDone = true
		end
	end

	if tourHandler then
		RemoveEventHandler(tourHandler)
	end

	CharactersMenu()
end
