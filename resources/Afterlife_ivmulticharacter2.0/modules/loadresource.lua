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

	-- Wait for NC loading screen to fully render before closing it
	Wait(60000)

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

	-- Now show character menu
	CharactersMenu()
end
