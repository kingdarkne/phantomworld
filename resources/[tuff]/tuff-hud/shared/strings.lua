return {
   CommandDesc = {
      seatbelt = "Toggle Seatbelt",
      engine   = "Toggle Engine"
   },
   Notifications = {
      SeatbeltDisabled = {
         title = "Seatbelt Unavailable",
         description = "You cannot use a seatbelt in this vehicle."
      }
   },
   Editor = {
      Title       = "EDITOR MODE",
      Description = "Customize the hud elements to your liking",
      Drag        = "Drag to Reposition",
      Scale       = "Scale to Resize",
      ESC         = "ESC to Go Back"
   },
   Settings = {
      Title       = "Hud Settings",
      Description = "Customize the hud settings to your liking",
      Category    = {
         general     = "General",
         speedometer = "Speedometer",
         status      = "Status Icons & Player Info"
      },
      General     = {
         Editor = {
            title       = "Open Editor Mode",
            description = "Customize the hud elements size & positions to your liking",
            reset       = "Reset",
            edit        = "Edit"
         },
         Performance = {
            title       = "Performance Mode",
            description = "Customize the hud fps to match your performance"
         },
         Map = {
            title       = "Map Visibility",
            description = "Customize the visibility of the map",
            never       = "Never",
            always      = "Always",
            car         = "Only In Car"
         },
         MapType = {
            title       = "Map Type",
            description = "Choose between the rectangle and circle minimap",
            SQUARE      = "Rectangle",
            CIRCLE      = "Circle"
         },
         Compass = {
            title       = "Compass Visibility",
            description = "Choose when the compass should be visible",
            CAR         = "Only In Car",
            FOOT        = "Only On Foot",
            ALWAYS      = "Always",
            NEVER       = "Never"
         },
         Waypoint = {
            title       = "Waypoint Settings",
            description = "Hide or Show the waypoint",
            show        = "Show",
            hide        = "Hide"
         },
         Cinematic = {
            title       = "Enable Cinematics",
            description = "Enable or Disable the cinematics bar"
         }
      },
      Speedometer = {
         Speedometers = {
            title       = "Select Speedometer Style",
            description = "Choose the speedometer to your liking",
            choose      = "Choose Speedometer",
            back        = "Go Back",
            select      = "Select",
            selected    = "Selected",
            One         = {
               name = "Speedometer name"
            },
            Two         = {
               name = "Speedometer name"
            },
            Three       = {
               name = "Speedometer name"
            }
         },
         SpeedUnit = {
            title       = "Set Speed Unit",
            description = "Customize the speedometer unit"
         },
         HideSpeedometer = {
            title       = "Hide Speedometer",
            description = "Hide or Show the entire speedometer"
         },
         SeatbeltAlert = {
            title       = "Enable Seatbelt Alert",
            description = "Enable or Disable alert when seatbelt is not attached"
         },
         LowFuelAlert = {
            title       = "Enable Low Fuel Alert",
            description = "Enable or Disable alert when fuel level is low"
         }
      },
      Status      = {
         ShowPlayerInfo = {
            title       = "Show Player Info",
            description = "Hide or Show the player info"
         },
         PlayerInfoStyle = {
            title       = "Player Info Style",
            description = "Choose different style for player info",
            style       = "Style "
         },
         EditPlayerInfo = {
            title       = "Edit Player Info",
            description = "Hide or show specific player info",
            reset       = "Reset",
            edit        = "Edit",
            locked      = "Locked",
            Medal       = {
               title             = "Edit Player Info",
               description       = "Hide or show specific player info",
               lockedDescription = "This section is managed by the server owner",
               serverLogo        = "Server Logo",
               playerID          = "Player ID",
               time              = "Time",
               date              = "Date",
               bank              = "Bank",
               cash              = "Cash",
               blackMoney        = "Black Money",
               job               = "Job"
            }
         },
         HideStatusIcon = {
            title       = "Hide Status Icons",
            description = "Hide or Show the status icons"
         },
         IconsVisibility = {
            title         = "Status Icons Visibility",
            description   = "Show icons when their value is below or equal to the set %.",
            reset         = "Reset",
            edit          = "Edit",
            collapse      = "Collapse",
            expand        = "Expand",
            Medal         = {
               title       = "Edit Status Icons Visibility",
               description = "Hide or show specific icons"
            },
            showWhenBelow = "Show when below or equal",
            showWhenAbove = "Show when above or equal",
            items         = {
               HEALTH  = "Health",
               ARMOR   = "Armor",
               FOOD    = "Hunger",
               WATER   = "Thirst",
               OXYGEN  = "Oxygen",
               STRESS  = "Stress",
               STAMINA = "Stamina"
            }
         },
         EditStatusIconsColors = {
            title       = "Edit Status Icons Colors",
            description = "Customize the status icons colors",
            reset       = "Reset"
         }
      }
   }
}
