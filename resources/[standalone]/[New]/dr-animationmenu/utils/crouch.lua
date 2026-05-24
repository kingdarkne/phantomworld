local isCrouching = false

RegisterKeyMapping("+crouch", "Crouch", "keyboard", AK4Y.CrouchKey)

RegisterCommand("+crouch", function()
	local ped = PlayerPedId()

	if not IsPedSittingInAnyVehicle(ped) and not IsPedFalling(ped) and not IsPedSwimming(ped) and not IsPedSwimmingUnderWater(ped) and not IsPauseMenuActive() then
		isCrouching = not isCrouching
		ClearPedTasks(ped)

		if isCrouching then
			ResetPedMovementClipset(ped, 1.0)
			ResetPedWeaponMovementClipset(ped)
			ResetPedStrafeClipset(ped)

			SetPedStealthMovement(ped, false, 'DEFAULT_ACTION')

			local walkStyle = GetResourceKvpString("ak4y_emotes:walkStyle")

			if walkStyle then
				LoadAnimSet(walkStyle)
				SetPedMovementClipset(ped, walkStyle, 0.2)
				RemoveAnimSet(walkStyle)
			end
		else
			LoadAnimSet('move_ped_crouched')
			SetPedMovementClipset(ped, 'move_ped_crouched', 1.0)
			SetPedStrafeClipset(ped, 'move_ped_crouched_strafing')
		end
	end
end, false)
