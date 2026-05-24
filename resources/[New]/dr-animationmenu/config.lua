AK4Y = {}

AK4Y.MenuKey = "F7"         -- Key to open the menu.
AK4Y.Language = "en"        -- Menu language. You can add your own translations in the `Languages` table.

AK4Y.MaxDistancesForPreview = { -- Maximum distances for the preview character.
	[0] = 5.0,          -- CAMERA VIEW - THIRD PERSON CLOSE
	[1] = 7.5,          -- CAMERA VIEW - THIRD PERSON MEDIUM RANGE
	[2] = 10.0,         -- CAMERA VIEW - THIRD PERSON FAR
	[3] = 0.0,          -- CAMERA VIEW - CINEMATIC MODE
	[4] = 4.0           -- CAMERA VIEW - FIRST PERSON
}

AK4Y.MaxDistanceForSharedEmotes = 3.0 -- Maximum distance for shared emotes. If players are farther apart than this, they can't send invites.
AK4Y.AllowedInCars = false       -- If true, players can use emotes while in a vehicle.

AK4Y.Notify = function(msg, title, type)
	TriggerEvent("QBCore:Notify", msg, type == "info" and "primary" or type, 5000)
end

AK4Y.ShortcutKey = 21  -- Key to use the saved animation. (21 = SHIFT)
AK4Y.CrouchKey = "LCONTROL" -- Key to toggle the crouch animation. (Left Ctrl - use LCONTROL for FiveM)
AK4Y.CancelKey = "X"   -- Key to cancel the current animation. (X)
AK4Y.CancelHandsUp = true -- If true, the player raises their hands if there’s no animation to cancel.
AK4Y.PointKey = "B"    -- Key to toggle the pointing animation. (B)
AK4Y.RagdollKey = "U"  -- Key to toggle the ragdoll animation. (U)
AK4Y.AnimationAcceptKey = "Y" -- Key to accept the invite.
AK4Y.AnimationDeclineKey = "N" -- Key to decline the invite.