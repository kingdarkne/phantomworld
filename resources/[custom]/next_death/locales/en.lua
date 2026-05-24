--[[
  ------------------------------------------------------------------------------------------------
    Next Death - Advanced death system
  ------------------------------------------------------------------------------------------------
  _   _ ________   _________ _____ ____  _____  ______ 
 | \ | |  ____\ \ / /__   __/ ____/ __ \|  __ \|  ____|
 |  \| | |__   \ V /   | | | |   | |  | | |__) | |__   
 | . ` |  __|   > <    | | | |   | |  | |  _  /|  __|  
 | |\  | |____ / . \   | | | |___| |__| | | \ \| |____ 
 |_| \_|______/_/ \_\  |_|  \_____\____/|_|  \_\______|                                                       
                                                       
  ------------------------------------------------------------------------------------------------
    Created for Nextcore Studio by Junnho
  ------------------------------------------------------------------------------------------------
    
    Author: Nextcore Studio
    Copyright © 2025 Junnho. All rights reserved.
    Copyright © 2025 Nextcore Studio. All rights reserved.
    License: EULA (see LICENSE file)
    
    Documentation: https://www.nextcorestudio.com/docs/next-death/
    Website: https://www.nextcorestudio.com/
    Script Page: https://www.nextcorestudio.com/scripts/next-death/?from=homepage
    Tebex: https://nextcorestudio.tebex.io/package/7057654

--------------------------------------------------------------------------------------------------
]]

Locales['en'] = {
    
    ['you_are_dead'] = 'You are dead',
    ['you_are_unconscious'] = 'YOU ARE UNCONSCIOUS',
    ['it_will_take_time'] = 'It will take some time before you regain your strength',
    ['alert_sent_to_ems'] = 'Alert sent to EMS',
    ['call_emergency_services'] = 'Call Emergency Services',
    ['respawn'] = 'Recover',
    ['bleeding_out'] = 'You are bleeding out',
    ['time_remaining'] = 'Time remaining: %s',
    ['early_respawn_available'] = 'Early respawn available',
    ['press_to_respawn'] = 'Press %s to respawn',
    ['press_to_call_ems'] = 'Press %s to call EMS',
    ['calling_ems'] = 'Calling EMS...',
    ['ems_called'] = 'EMS called!',
    ['ems_cooldown'] = 'You must wait before calling again',
    ['voice_blocked'] = 'You cannot speak when you are dead',
    ['weapons_removed'] = 'Your weapons have been removed',
    ['revived'] = 'You have been revived',
    ['respawned'] = 'You have respawned',

    
    ['ems_alert_title'] = 'EMS Alert',
    ['ems_alert_description'] = '%s needs help!',
    ['ems_alert_location'] = 'Location: %s',
    ['ems_alert_victim'] = 'Victim: %s',

    
    ['admin_title'] = 'Next Death',
    ['menu_title'] = 'Main Menu',
    ['timers'] = 'Delays',
    ['early_respawn'] = 'Early Respawn',
    ['early_respawn_desc'] = 'Allows players to respawn before the end of the bleedout timer.',
    ['time_before_early_respawn'] = 'Time before early respawn',
    ['forced_respawn'] = 'Forced Respawn',
    ['forced_respawn_desc'] = 'Automatically respawns the player at the hospital when the bleedout timer reaches zero.',
    ['time_before_forced_respawn'] = 'Time before forced respawn',

    ['options'] = 'Equipment',
    ['remove_weapons_on_respawn'] = 'Strip weapons on respawn',
    ['remove_weapons_desc'] = 'Removes all weapons from the player when they respawn.',
    ['drop_weapon_on_death'] = 'Drop current weapon on ground',
    ['drop_weapon_desc'] = 'Makes the player drop their current weapon on the ground upon death.',

    ['lose_inventory_on_respawn'] = 'Lose inventory on respawn',
    ['lose_inventory_desc'] = 'Removes items from the player\'s inventory upon respawn. Nothing is removed if the player is revived in-game or by admins.',
    ['inventory_whitelist'] = 'Inventory Whitelist',
    ['inventory_whitelist_desc'] = 'Items that will NOT be removed (comma separated).',
    ['save'] = 'SAVE',
    ['saved'] = 'SAVED',

    ['respawn_location'] = 'Respawn Location',
    ['respawn_at_location'] = 'Respawn at hospital (Solo Respawn)',
    ['respawn_at_location_desc'] = 'Allows the player to respawn at the hospital when enabled and the timer reaches zero.',
    ['revive_at_location'] = 'Respawn at hospital (External Respawn)',
    ['revive_at_location_desc'] = 'When enabled, a player revived by a third party will be automatically teleported to the hospital.',
    ['admin_hospital_coords'] = 'Coordinates',
    ['get_current_position'] = 'Get current position',
    ['nearest_respawn_point_enabled'] = 'Multi respawn',
    ['nearest_respawn_point_enabled_desc'] = 'If enabled, player respawns at the nearest custom respawn point.',
    ['custom_respawn_points'] = 'Custom respawn points',
    ['custom_respawn_points_desc'] = 'All custom points are listed below and can be edited directly.',
    ['add_respawn_point'] = 'Add respawn point',
    ['respawn_point'] = 'Point %s',
    ['remove_respawn_point'] = 'Remove',
    ['respawn_point_label'] = 'Label',
    ['respawn_point_heading'] = 'Heading',
    ['hospital_label'] = 'Hospital',


    ['bonus'] = 'Damages',
    ['damage_indicator_title'] = 'Damage Indicator',
    ['damages_desc'] = 'Configure the visual effects (colored vignette) that appear on the screen when players take damage.',
    ['damage_vignette_enabled'] = 'Enable damage effects',
    ['damage_vignette_opacity'] = 'Damage opacity',
    ['damage_vignette_color'] = 'Effect color',

    ['configuration'] = 'Configuration',
    ['parametres'] = 'Settings',
    ['language'] = 'Language',
    ['language_description'] = 'Interface language.',
    ['found_bug'] = 'Found a bug? Let us know:',
    ['detected_inventory'] = 'Detected inventory:',
    ['config_saved_successfully'] = 'Configuration saved successfully!',
    ['admin_saved'] = 'Configuration saved!',
    ['admin_error'] = 'Error saving configuration',
    ['no_inventory_detected'] = 'None detected',
    ['notification_death'] = 'You are dead',
    ['notification_bleeding'] = 'You are bleeding - call for help!',
    ['notification_ems_called'] = 'EMS called!',
    ['notification_ems_cooldown'] = 'Wait before calling EMS again',
    ['notification_revived'] = 'You have been revived',
    ['notification_weapons_removed'] = 'It looks like you lost your belongings',
    ['notification_regained_consciousness'] = 'You have regained consciousness',
    ['command_revive'] = 'Revive a player',
    ['command_reload_config'] = 'Reload configuration',
    ['command_no_permission'] = 'You do not have permission to use this command',
    ['time_minutes'] = '%d min',
    ['time_seconds'] = '%d sec',
    ['time_minutes_seconds'] = '%d min %d sec',
    ['error'] = 'Error',
    ['success'] = 'Success',
    ['alert'] = 'Alert',
    ['info'] = 'Info',
    ['notification_title_error'] = 'Error',
    ['notification_title_success'] = 'Success',
    ['notification_title_alert'] = 'Alert',
    ['notification_title_info'] = 'Info',
    ['invalid_player_id'] = 'Invalid Player ID',
    ['admin_invalid_player_id'] = 'Invalid player ID',
    ['admin_invalid_id'] = 'Invalid ID',
    ['admin_player_not_found'] = 'Player not found',
    ['admin_not_dead'] = 'You are not dead',
    ['admin_kill_target_success'] = 'You killed %s',
    ['admin_killed_by_admin'] = 'You were killed by an administrator',
    ['admin_revive_target_success'] = 'You revived %s',
    ['admin_revived_by_admin'] = 'You were revived by an administrator',
    ['admin_weapon_remove_failed'] = 'Unable to remove the weapon from inventory',
    ['item_pickup_failed'] = 'Could not pick up item (full inventory?)',
    ['timer_respawn_order_warning'] = 'Forced respawn delay must be higher than early respawn delay. If left as is, no settings will be saved.',
    ['admin_invalid_time'] = 'Invalid timer values',
    ['admin_invalid_coords'] = 'Invalid coordinates',
    ['notification_unconscious'] = 'You are unconscious',
    ['press_e_to_pickup'] = 'Press E to pick up',
    ['unknown'] = 'Unknown',
    ['unknown_location'] = 'Unknown Location',
    ['admin_db_not_loaded'] = 'Configuration DB not loaded. Save blocked.',
}