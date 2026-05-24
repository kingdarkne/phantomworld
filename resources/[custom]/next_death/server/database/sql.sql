/*
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
*/

CREATE TABLE IF NOT EXISTS `next_death_config` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `config_key` varchar(50) NOT NULL,
    `config_value` text NOT NULL,
    `updated_by` varchar(50) DEFAULT NULL,
    `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `config_key` (`config_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `next_death_config` (`config_key`, `config_value`, `updated_by`) VALUES
('bleedout_time_ms', '300000', 'system'),
('early_respawn_time_ms', '60000', 'system'),
('allow_early_respawn', 'true', 'system'),
('forced_respawn_enabled', 'true', 'system'),
('remove_weapons_on_respawn', 'true', 'system'),
('lose_inventory_on_respawn', 'false', 'system'),
('inventory_whitelist', '', 'system'),
('drop_weapon_on_death', 'false', 'system'),
('respawn_at_location', 'true', 'system'),
('revive_at_location', 'false', 'system'),
('nearest_respawn_point_enabled', 'false', 'system'),
('respawn_locations_json', '[]', 'system'),
('hospital_x', '298.44', 'system'),
('hospital_y', '-584.89', 'system'),
('hospital_z', '43.26', 'system'),
('hospital_heading', '70.0', 'system'),
('damage_vignette_enabled', 'true', 'system'),
('damage_vignette_color', 'red', 'system'),
('damage_vignette_opacity', '70', 'system'),
('locale', 'en', 'system');
