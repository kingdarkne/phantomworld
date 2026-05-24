local friends = nil

function AddFriend(friend)
	lib.callback.await("electus_bodyguards:addFriend", false, friend)
	SyncFriends()
end

function RemoveFriend(friend)
	lib.callback.await("electus_bodyguards:removeFriend", false, friend)
	SyncFriends()
end

function GetFriends()
	if not friends then
		SyncFriends()
	end
	return friends
end

function IsPedInFriendList(ped)
	local players = lib.callback.await("electus_bodyguards:getPlayers", false)
	local friendList = GetFriends()
	local isFriend = false
	
	for i = 1, #players do
		for j = 1, #friendList do
			if friendList then
				if friendList[j].friend == players[i].identifier then
					local playerPed = GetPlayerPed(GetPlayerFromServerId(tonumber(players[i].id)))
					if playerPed == ped then
						isFriend = true
						break
					end
				end
			end
		end
	end
	
	return isFriend
end

function SyncFriends()
	friends = lib.callback.await("electus_bodyguards:getFriends", false)
end

RegisterCommand("bodyguard_friends", function()
	SendReactMessage("renderComponent", {
		component = "friends",
	})
	ToggleNuiFrame(true)
end, false)
