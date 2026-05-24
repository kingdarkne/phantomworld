local isRagdoll = false

RegisterCommand("+ragdoll", function()
	local ped = PlayerPedId()

	if not IsPedSittingInAnyVehicle(ped) and not IsPedFalling(ped) and not IsPedSwimming(ped) and not IsPedSwimmingUnderWater(ped) and not IsPauseMenuActive() then
		isRagdoll = true

		while isRagdoll do
			SetPedToRagdoll(ped, 1000, 1000, 0, false, false, false)

			Wait(100)
		end
	end
end, false)

RegisterCommand("-ragdoll", function()
	isRagdoll = false
end, false)

RegisterKeyMapping("+ragdoll", "Ragdoll", "keyboard", AK4Y.RagdollKey)
