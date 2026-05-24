/*
  ------------------------------------------------------------------------------------------------
    Next Housing - Complete housing system
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
    
    Documentation: https://www.nextcorestudio.com/docs/next-housing/
    Website: https://www.nextcorestudio.com/
    Script Page: https://www.nextcorestudio.com/scripts/next-housing/
    Tebex: https://junnho.tebex.io/package/7057755

--------------------------------------------------------------------------------------------------
*/
CREATE TABLE IF NOT EXISTS `next_housing` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `bidentifier` varchar(50) NOT NULL COMMENT 'Builder identifier',
  `bname` varchar(50) NOT NULL COMMENT 'Builder name',
  `oidentifier` varchar(50) DEFAULT NULL COMMENT 'Owner identifier',
  `oname` varchar(50) DEFAULT NULL COMMENT 'Owner name',
  `house_coords` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`house_coords`)) COMMENT 'House entrance coordinates (JSON)',
  `garage_coords` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`garage_coords`)) COMMENT 'Garage coordinates (JSON)',
  `interior` int(11) NOT NULL COMMENT 'Interior type ID',
  `is_locked` tinyint(1) DEFAULT 1 COMMENT 'Is the house locked',
  `is_buyable` tinyint(1) DEFAULT 1 COMMENT 'Is the house available for purchase',
  `price` int(11) DEFAULT NULL COMMENT 'House price',
  `images` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`images`)) COMMENT 'House images array (JSON)',
  `belongs_to_agency` tinyint(1) DEFAULT 0 COMMENT 'Does the house belong to the real estate agency',
  `name` varchar(255) DEFAULT NULL COMMENT 'Custom house name',
  PRIMARY KEY (`id`),
  KEY `idx_oidentifier` (`oidentifier`),
  KEY `idx_bidentifier` (`bidentifier`),
  KEY `idx_belongs_agency` (`belongs_to_agency`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

CREATE TABLE IF NOT EXISTS `next_housing_keys` (
  `id` int(20) NOT NULL AUTO_INCREMENT,
  `house_id` int(11) DEFAULT NULL COMMENT 'Reference to next_housing.id',
  `identifier` varchar(50) DEFAULT NULL COMMENT 'Player identifier with key access',
  `name` varchar(50) DEFAULT NULL COMMENT 'Player name with key access',
  PRIMARY KEY (`id`),
  KEY `house_id` (`house_id`),
  KEY `idx_identifier` (`identifier`),
  CONSTRAINT `next_housing_keys_ibfk_1` FOREIGN KEY (`house_id`) REFERENCES `next_housing` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

CREATE TABLE IF NOT EXISTS `next_housing_player_positions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(50) NOT NULL COMMENT 'Player identifier',
  `house_id` int(11) DEFAULT NULL COMMENT 'Reference to next_housing.id',
  `is_inside` tinyint(1) DEFAULT 0 COMMENT 'Is player inside a house',
  `interior_coords` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`interior_coords`)) COMMENT 'Player position inside house (JSON)',
  `last_updated` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Last position update timestamp',
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_identifier` (`identifier`),
  KEY `house_id` (`house_id`),
  CONSTRAINT `next_housing_positions_ibfk_1` FOREIGN KEY (`house_id`) REFERENCES `next_housing` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

CREATE TABLE IF NOT EXISTS `next_housing_settings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `config_key` varchar(120) NOT NULL COMMENT 'Global setting key',
  `config_value` longtext DEFAULT NULL COMMENT 'Setting value',
  `updated_by` varchar(50) DEFAULT 'system' COMMENT 'Last updater identifier',
  `updated_at` timestamp DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'Last update timestamp',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_nh_settings_config_key` (`config_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

CREATE TABLE IF NOT EXISTS `next_housing_contracts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `house_id` int(11) NOT NULL COMMENT 'Reference to next_housing.id',
  `agent_id` varchar(50) NOT NULL COMMENT 'Real estate agent identifier',
  `agent_name` varchar(50) NOT NULL COMMENT 'Real estate agent name',
  `player_id` varchar(50) NOT NULL COMMENT 'Player identifier (buyer/renter)',
  `player_name` varchar(50) NOT NULL COMMENT 'Player name (buyer/renter)',
  `type` enum('sale','rent') NOT NULL COMMENT 'Contract type: sale or rent',
  `price` int(11) NOT NULL COMMENT 'Contract price',
  `status` enum('pending','active','completed','cancelled','expired','terminated') DEFAULT 'pending' COMMENT 'Contract status',
  `origin` enum('agency','pap') DEFAULT 'agency' COMMENT 'Contract source: agency or PAP',
  `rent_duration_months` int(11) DEFAULT NULL COMMENT 'Rental duration in months (for rent type)',
  `next_payment_date` datetime DEFAULT NULL COMMENT 'Next payment date (for rent type)',
  `commission_rate` decimal(5,2) DEFAULT 5.00 COMMENT 'Commission rate percentage',
  `commission_amount` int(11) DEFAULT 0 COMMENT 'Commission amount',
  `created_at` timestamp DEFAULT CURRENT_TIMESTAMP COMMENT 'Contract creation timestamp',
  `signed_at` datetime DEFAULT NULL COMMENT 'Contract signing date',
  `expires_at` datetime DEFAULT NULL COMMENT 'Contract expiration date',
  `name` varchar(255) DEFAULT NULL COMMENT 'Custom contract name',
  PRIMARY KEY (`id`),
  KEY `house_id` (`house_id`),
  KEY `agent_id` (`agent_id`),
  KEY `player_id` (`player_id`),
  KEY `status` (`status`),
  CONSTRAINT `next_housing_contracts_ibfk_1` FOREIGN KEY (`house_id`) REFERENCES `next_housing` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

CREATE TABLE IF NOT EXISTS `next_housing_pap` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `house_id` int(11) NOT NULL COMMENT 'Reference to next_housing.id',
  `seller_id` varchar(50) NOT NULL COMMENT 'Seller identifier',
  `seller_name` varchar(100) NOT NULL COMMENT 'Seller name',
  `type` enum('sale','rent') NOT NULL DEFAULT 'sale' COMMENT 'Listing type: sale or rent',
  `price` int(11) NOT NULL COMMENT 'Listing price',
  `rent_duration_months` int(11) DEFAULT NULL COMMENT 'Rental duration in months (for rent type)',
  `description` text DEFAULT NULL COMMENT 'Listing description',
  `buyer_id` varchar(50) DEFAULT NULL COMMENT 'Buyer identifier (when offer is made)',
  `buyer_name` varchar(100) DEFAULT NULL COMMENT 'Buyer name (when offer is made)',
  `offer_amount` int(11) DEFAULT NULL COMMENT 'Offer amount (if different from listing price)',
  `offer_message` text DEFAULT NULL COMMENT 'Message from buyer',
  `messages` text DEFAULT NULL COMMENT 'JSON array of chat messages between buyer and seller',
  `status` enum('active','offer_pending','accepted','completed','cancelled','terminated') DEFAULT 'active' COMMENT 'Transaction status',
  `created_at` timestamp DEFAULT CURRENT_TIMESTAMP COMMENT 'Listing creation timestamp',
  `expires_at` datetime DEFAULT NULL COMMENT 'Listing expiration date',
  `completed_at` datetime DEFAULT NULL COMMENT 'Transaction completion date',
  PRIMARY KEY (`id`),
  KEY `house_id` (`house_id`),
  KEY `seller_id` (`seller_id`),
  KEY `buyer_id` (`buyer_id`),
  KEY `status` (`status`),
  CONSTRAINT `next_housing_pap_ibfk_1` FOREIGN KEY (`house_id`) REFERENCES `next_housing` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
