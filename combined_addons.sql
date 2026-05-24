-- Combined addon SQL for Dracula v5.1
-- This file concatenates the smaller resource SQLs (banking, housing, phone, MDT, vehicles, XP, etc.)
-- Import into your database after the main dracula_v5.1.sql if needed.

USE `s36165_9903ef012b`;

-- ===== resources/[qb]/qb-banking/banking.sql =====
CREATE TABLE IF NOT EXISTS `bank_accounts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(11) DEFAULT NULL,
  `account_name` varchar(50) DEFAULT NULL,
  `account_balance` int(11) NOT NULL DEFAULT 0,
  `account_type` enum('shared','job','gang') NOT NULL,
  `users` longtext,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `account_name` (`account_name`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `bank_statements` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(11) DEFAULT NULL,
  `account_name` varchar(50) DEFAULT 'checking',
  `amount` int(11) DEFAULT NULL,
  `reason` varchar(50) DEFAULT NULL,
  `statement_type` enum('deposit','withdraw') DEFAULT NULL,
  `date` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`) USING BTREE,
  KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== resources/[standalone]/ps-housing-2.0.7/properties_table.sql =====
-- ps-housing: create properties table in dracula_v5.1
-- Run this in HeidiSQL (or MySQL) on database dracula_v5.1

USE `s36165_9903ef012b`;

DROP TABLE IF EXISTS `properties`;

CREATE TABLE `properties` (
    `property_id` int(11) NOT NULL AUTO_INCREMENT,
    `owner_citizenid` varchar(11) COLLATE utf8mb4_general_ci NULL,
    `street` varchar(100) NULL,
    `region` varchar(100) NULL,
    `description` longtext NULL,
    `has_access` longtext NULL,
    `extra_imgs` longtext NULL,
    `furnitures` longtext NULL,
    `for_sale` tinyint(1) NOT NULL DEFAULT 1,
    `price` int(11) NOT NULL DEFAULT 0,
    `shell` varchar(50) NOT NULL DEFAULT '',
    `apartment` varchar(50) NULL DEFAULT NULL,
    `door_data` longtext NULL,
    `garage_data` longtext NULL,
    `zone_data` longtext NULL,
    PRIMARY KEY (`property_id`),
    UNIQUE KEY `UQ_owner_apartment` (`owner_citizenid`, `apartment`),
    KEY `owner_citizenid` (`owner_citizenid`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ===== resources/[qb]/qb-phone-pro/qb-phone/qb-phone.sql =====
-- (qb-phone-pro schema)
DROP TABLE IF EXISTS `app_store`;
CREATE TABLE IF NOT EXISTS `app_store` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(255) NOT NULL,
  `appname` varchar(255) NOT NULL,
  `appnumber` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DROP TABLE IF EXISTS `phone_gallery`;
CREATE TABLE IF NOT EXISTS `phone_gallery` (
  `citizenid` varchar(255) NOT NULL,
  `image` varchar(255) NOT NULL,
  `date` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DROP TABLE IF EXISTS `phone_invoices`;
CREATE TABLE IF NOT EXISTS `phone_invoices` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) DEFAULT NULL,
  `amount` int(11) NOT NULL DEFAULT 0,
  `society` tinytext,
  `sender` varchar(50) DEFAULT NULL,
  `sendercitizenid` varchar(50) DEFAULT NULL,
  `time` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB AUTO_INCREMENT=42 DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `phone_messages`;
CREATE TABLE IF NOT EXISTS `phone_messages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) DEFAULT NULL,
  `number` varchar(50) DEFAULT NULL,
  `messages` text,
  `time` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`),
  KEY `number` (`number`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `phone_note`;
CREATE TABLE IF NOT EXISTS `phone_note` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) DEFAULT NULL,
  `title` text,
  `text` text,
  `lastupdate` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB AUTO_INCREMENT=56 DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `phone_tweets`;
CREATE TABLE IF NOT EXISTS `phone_tweets` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) DEFAULT NULL,
  `firstName` varchar(25) DEFAULT NULL,
  `lastName` varchar(25) DEFAULT NULL,
  `type` varchar(25) DEFAULT NULL,
  `message` text,
  `url` text,
  `tweetId` varchar(25) NOT NULL,
  `date` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB AUTO_INCREMENT=289 DEFAULT CHARSET=UTF8;

DROP TABLE IF EXISTS `player_contacts`;
CREATE TABLE IF NOT EXISTS `player_contacts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) DEFAULT NULL,
  `name` varchar(50) DEFAULT NULL,
  `number` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `player_mails`;
CREATE TABLE IF NOT EXISTS `player_mails` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) DEFAULT NULL,
  `sender` varchar(50) DEFAULT NULL,
  `subject` varchar(50) DEFAULT NULL,
  `message` text,
  `read` tinyint(4) DEFAULT 0,
  `mailid` int(11) DEFAULT NULL,
  `date` timestamp NULL DEFAULT current_timestamp(),
  `button` text,
  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB AUTO_INCREMENT=49 DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `phone_chatrooms`;
CREATE TABLE `phone_chatrooms` (
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `room_code` VARCHAR(10) NOT NULL UNIQUE,
    `room_name` VARCHAR(15) NOT NULL,
    `room_owner_id` VARCHAR(20),
    `room_owner_name` VARCHAR(60),
    `room_members` TEXT,
    `room_pin` VARCHAR(50),
    `unpaid_balance` DECIMAL(10,2) DEFAULT 0,
    `is_pinned` BOOLEAN DEFAULT 0,
    `created` DATETIME DEFAULT NOW(),
    PRIMARY KEY (`id`)
);

INSERT IGNORE INTO `phone_chatrooms` (`room_code`, `room_name`, `room_owner_id`, `room_owner_name`, `is_pinned`) VALUES
	('411', '411', 'official', 'Government', 1),
	('lounge', 'The Lounge', 'official', 'Government', 1),
	('events', 'Events', 'official', 'Government', 1);

DROP TABLE IF EXISTS `phone_chatroom_messages`;
CREATE TABLE `phone_chatroom_messages` (
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `room_id` INT unsigned,
    `member_id` VARCHAR(20),
    `member_name` VARCHAR(50),
    `message` TEXT NOT NULL,
     `is_pinned` BOOLEAN DEFAULT FALSE,
     `created` DATETIME DEFAULT NOW(),
    PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS `player_jobs`;
CREATE TABLE IF NOT EXISTS `player_jobs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `jobname` varchar(50) DEFAULT NULL,
  `employees` text,
  `maxEmployee` tinyint(11) DEFAULT 15,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=106 DEFAULT CHARSET=utf8;

-- ===== resources/[qb]/qb-phone/qb-phone.sql =====
-- (same schema as qb-phone-pro; kept for completeness)
DROP TABLE IF EXISTS `app_store`;
CREATE TABLE IF NOT EXISTS `app_store` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(255) NOT NULL,
  `appname` varchar(255) NOT NULL,
  `appnumber` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DROP TABLE IF EXISTS `phone_gallery`;
CREATE TABLE IF NOT EXISTS `phone_gallery` (
  `citizenid` varchar(255) NOT NULL,
  `image` varchar(255) NOT NULL,
  `date` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DROP TABLE IF EXISTS `phone_invoices`;
CREATE TABLE IF NOT EXISTS `phone_invoices` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) DEFAULT NULL,
  `amount` int(11) NOT NULL DEFAULT 0,
  `society` tinytext,
  `sender` varchar(50) DEFAULT NULL,
  `sendercitizenid` varchar(50) DEFAULT NULL,
  `time` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB AUTO_INCREMENT=42 DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `phone_messages`;
CREATE TABLE IF NOT EXISTS `phone_messages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) DEFAULT NULL,
  `number` varchar(50) DEFAULT NULL,
  `messages` text,
  `time` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`),
  KEY `number` (`number`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `phone_note`;
CREATE TABLE IF NOT EXISTS `phone_note` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) DEFAULT NULL,
  `title` text,
  `text` text,
  `lastupdate` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB AUTO_INCREMENT=56 DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `phone_tweets`;
CREATE TABLE IF NOT EXISTS `phone_tweets` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) DEFAULT NULL,
  `firstName` varchar(25) DEFAULT NULL,
  `lastName` varchar(25) DEFAULT NULL,
  `type` varchar(25) DEFAULT NULL,
  `message` text,
  `url` text,
  `tweetId` varchar(25) NOT NULL,
  `date` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB AUTO_INCREMENT=289 DEFAULT CHARSET=UTF8;

DROP TABLE IF EXISTS `player_contacts`;
CREATE TABLE IF NOT EXISTS `player_contacts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) DEFAULT NULL,
  `name` varchar(50) DEFAULT NULL,
  `number` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `player_mails`;
CREATE TABLE IF NOT EXISTS `player_mails` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) DEFAULT NULL,
  `sender` varchar(50) DEFAULT NULL,
  `subject` varchar(50) DEFAULT NULL,
  `message` text,
  `read` tinyint(4) DEFAULT 0,
  `mailid` int(11) DEFAULT NULL,
  `date` timestamp NULL DEFAULT current_timestamp(),
  `button` text,
  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB AUTO_INCREMENT=49 DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `phone_chatrooms`;
CREATE TABLE `phone_chatrooms` (
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `room_code` VARCHAR(10) NOT NULL UNIQUE,
    `room_name` VARCHAR(15) NOT NULL,
    `room_owner_id` VARCHAR(20),
    `room_owner_name` VARCHAR(60),
    `room_members` TEXT,
    `room_pin` VARCHAR(50),
    `unpaid_balance` DECIMAL(10,2) DEFAULT 0,
    `is_pinned` BOOLEAN DEFAULT 0,
    `created` DATETIME DEFAULT NOW(),
    PRIMARY KEY (`id`)
);

INSERT IGNORE INTO `phone_chatrooms` (`room_code`, `room_name`, `room_owner_id`, `room_owner_name`, `is_pinned`) VALUES
	('411', '411', 'official', 'Government', 1),
	('lounge', 'The Lounge', 'official', 'Government', 1),
	('events', 'Events', 'official', 'Government', 1);

DROP TABLE IF EXISTS `phone_chatroom_messages`;
CREATE TABLE `phone_chatroom_messages` (
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `room_id` INT unsigned,
    `member_id` VARCHAR(20),
    `member_name` VARCHAR(50),
    `message` TEXT NOT NULL,
     `is_pinned` BOOLEAN DEFAULT FALSE,
     `created` DATETIME DEFAULT NOW(),
    PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS `player_jobs`;
CREATE TABLE IF NOT EXISTS `player_jobs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `jobname` varchar(50) DEFAULT NULL,
  `employees` text,
  `maxEmployee` tinyint(11) DEFAULT 15,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=106 DEFAULT CHARSET=utf8;

-- ===== resources/omes_banking/banking_tables.sql =====
-- OMES Banking System Database Tables
CREATE TABLE IF NOT EXISTS `banking_transactions` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `identifier` varchar(50) NOT NULL,
    `type` varchar(50) NOT NULL,
    `amount` int(11) NOT NULL,
    `description` text,
    `date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `identifier` (`identifier`),
    KEY `type` (`type`),
    KEY `date` (`date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `banking_savings` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `identifier` varchar(50) NOT NULL,
    `balance` int(11) NOT NULL DEFAULT 0,
    `status` varchar(20) NOT NULL DEFAULT 'active',
    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `identifier` (`identifier`),
    KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `banking_pins` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `identifier` varchar(50) NOT NULL,
    `pin` varchar(4) NOT NULL,
    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== resources/[qb]/qb-apartments/qb-apartments.sql =====
CREATE TABLE IF NOT EXISTS `apartments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `type` varchar(255) DEFAULT NULL,
  `label` varchar(255) DEFAULT NULL,
  `citizenid` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`),
  KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=4144 DEFAULT CHARSET=latin1;

-- ===== resources/[qb]/qb-clothing/qb-clothing.sql =====
CREATE TABLE IF NOT EXISTS `playerskins` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(255) NOT NULL,
  `model` varchar(255) NOT NULL,
  `skin` text NOT NULL,
  `active` tinyint(2) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`),
  KEY `active` (`active`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `player_outfits` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) DEFAULT NULL,
  `outfitname` varchar(50) NOT NULL,
  `model` varchar(50) DEFAULT NULL,
  `skin` text DEFAULT NULL,
  `outfitId` varchar(50) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`),
  KEY `outfitId` (`outfitId`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4;

-- ===== resources/[qb]/qb-garages/player_vehicles.sql =====
CREATE TABLE IF NOT EXISTS `player_vehicles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `license` varchar(50) DEFAULT NULL,
  `citizenid` varchar(50) DEFAULT NULL,
  `vehicle` varchar(50) DEFAULT NULL,
  `hash` varchar(50) DEFAULT NULL,
  `mods` longtext DEFAULT NULL,
  `plate` varchar(50) NOT NULL,
  `fakeplate` varchar(50) DEFAULT NULL,
  `garage` varchar(50) DEFAULT NULL,
  `fuel` int(11) DEFAULT 100,
  `engine` float DEFAULT 1000,
  `body` float DEFAULT 1000,
  `state` int(11) DEFAULT 1,
  `depotprice` int(11) NOT NULL DEFAULT 0,
  `drivingdistance` int(50) DEFAULT NULL,
  `status` text DEFAULT NULL,
  `balance` int(11) NOT NULL DEFAULT 0,
  `paymentamount` int(11) NOT NULL DEFAULT 0,
  `paymentsleft` int(11) NOT NULL DEFAULT 0,
  `financetime` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `plate` (`plate`),
  KEY `citizenid` (`citizenid`),
  KEY `license` (`license`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== resources/[standalone]/ps-housing-2.0.7/README - INSTALL INSTRUCTIONS/QBCore/properties.sql =====
DROP table IF EXISTS `properties`;

CREATE TABLE IF NOT EXISTS `properties` (
    `property_id` int(11) NOT NULL AUTO_INCREMENT,
    `owner_citizenid` varchar(11) COLLATE utf8mb4_general_ci NULL,
    `street` VARCHAR(100) NULL,
    `region` VARCHAR(100) NULL,
    `description` LONGTEXT NULL,
    `has_access` JSON NULL DEFAULT (JSON_ARRAY()),
    `extra_imgs` JSON NULL DEFAULT (JSON_ARRAY()),
    `furnitures` JSON NULL DEFAULT (JSON_ARRAY()),
    `for_sale` tinyint(1) NOT NULL DEFAULT 1,
    `price` int(11) NOT NULL DEFAULT 0,
    `shell` varchar(50) NOT NULL,
    `apartment` varchar(50) NULL DEFAULT NULL,
    `door_data` JSON NULL DEFAULT NULL,
    `garage_data` JSON NULL DEFAULT NULL,
    `zone_data` JSON NULL DEFAULT NULL,
    PRIMARY KEY (`property_id`),
    CONSTRAINT `FK_owner_citizenid` FOREIGN KEY (`owner_citizenid`) REFERENCES `players` (`citizenid`) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT `UQ_owner_apartment` UNIQUE (`owner_citizenid`, `apartment`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ===== resources/[standalone]/[New]/dr-admin/sql/Logs.sql =====
CREATE TABLE IF NOT EXISTS `logs` (
  `Type` text DEFAULT NULL,
  `Steam` varchar(255) DEFAULT NULL,
  `Date` timestamp NULL DEFAULT current_timestamp(),
  `Log` text DEFAULT NULL,
  `Cid` varchar(50) DEFAULT NULL,
  `Data` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ===== resources/[standalone]/[New]/dr-admin/sql/Bans.sql =====
CREATE TABLE IF NOT EXISTS `bans` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `banid` varchar(50) DEFAULT NULL,
  `name` varchar(50) DEFAULT NULL,
  `steam` varchar(50) DEFAULT NULL,
  `license` varchar(50) DEFAULT NULL,
  `discord` varchar(50) DEFAULT NULL,
  `ip` varchar(50) DEFAULT NULL,
  `reason` text DEFAULT NULL,
  `bannedby` varchar(255) NOT NULL,
  `expire` int(11) DEFAULT NULL,
  `bannedon` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb3;

-- ===== resources/[qb]/qb-core/qbcore.sql =====
CREATE TABLE IF NOT EXISTS `players` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `cid` int(11) DEFAULT NULL,
  `license` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `money` text NOT NULL,
  `charinfo` text DEFAULT NULL,
  `job` text NOT NULL,
  `gang` text DEFAULT NULL,
  `position` text NOT NULL,
  `metadata` text NOT NULL,
  `inventory` longtext DEFAULT NULL,
  `last_updated` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`citizenid`),
  KEY `id` (`id`),
  KEY `last_updated` (`last_updated`),
  KEY `license` (`license`)
) ENGINE=InnoDB AUTO_INCREMENT=1;

CREATE TABLE IF NOT EXISTS `bans` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) DEFAULT NULL,
  `license` varchar(50) DEFAULT NULL,
  `discord` varchar(50) DEFAULT NULL,
  `ip` varchar(50) DEFAULT NULL,
  `reason` text DEFAULT NULL,
  `expire` int(11) DEFAULT NULL,
  `bannedby` varchar(255) NOT NULL DEFAULT 'LeBanhammer',
  PRIMARY KEY (`id`),
  KEY `license` (`license`),
  KEY `discord` (`discord`),
  KEY `ip` (`ip`)
) ENGINE=InnoDB AUTO_INCREMENT=1;

CREATE TABLE IF NOT EXISTS `player_contacts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) DEFAULT NULL,
  `name` varchar(50) DEFAULT NULL,
  `number` varchar(50) DEFAULT NULL,
  `iban` varchar(50) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB AUTO_INCREMENT=1;

-- ===== resources/[standalone]/[New]/dr-bodycam/installfiles/spy_bodycam.sql =====
CREATE TABLE IF NOT EXISTS `spy_bodycam` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `job` varchar(255) NOT NULL,
  `videolink` longtext NOT NULL,
  `street` varchar(255) NOT NULL,
  `date` varchar(255) NOT NULL,
  `playername` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=42 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- ===== resources/[standalone]/[New]/dr-fishing/sql.sql =====
DROP TABLE IF EXISTS `leaderboard`;
CREATE TABLE `leaderboard` (
    id INT AUTO_INCREMENT PRIMARY KEY,
    player_name VARCHAR(50) NOT NULL,
    length FLOAT NOT NULL,
    caught_time DATETIME NOT NULL
);

-- ===== resources/[standalone]/[New]/ps-mdt/sql/qbcore.sql =====
CREATE TABLE IF NOT EXISTS `mdt_data` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `cid` VARCHAR(20) DEFAULT NULL,
  `information` MEDIUMTEXT DEFAULT NULL,
  `tags` TEXT NOT NULL,
  `gallery` TEXT NOT NULL,
  `jobtype` VARCHAR(25) DEFAULT 'police',
  `pfp` TEXT DEFAULT NULL,
  `fingerprint` VARCHAR(50) DEFAULT NULL,
  PRIMARY KEY (`cid`),
  KEY `id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `mdt_bulletin` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` TEXT NOT NULL,
  `desc` TEXT NOT NULL,
  `author` varchar(50) NOT NULL,
  `time` varchar(20)  NOT NULL,
  `jobtype` VARCHAR(25) DEFAULT 'police',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `mdt_reports` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `author` varchar(50) DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `type` varchar(50) DEFAULT NULL,
  `details` LONGTEXT DEFAULT NULL,
  `tags` text DEFAULT NULL,
  `officersinvolved` text DEFAULT NULL,
  `civsinvolved` text DEFAULT NULL,
  `gallery` text DEFAULT NULL,
  `time` varchar(20) DEFAULT NULL,
  `jobtype` varchar(25) DEFAULT 'police',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `mdt_bolos` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `author` varchar(50) DEFAULT NULL,
  `title` varchar(50) DEFAULT NULL,
  `plate` varchar(50) DEFAULT NULL,
  `owner` varchar(50) DEFAULT NULL,
  `individual` varchar(50) DEFAULT NULL,
  `detail` text DEFAULT NULL,
  `tags` text DEFAULT NULL,
  `gallery` text DEFAULT NULL,
  `officersinvolved` text DEFAULT NULL,
  `time` varchar(20) DEFAULT NULL,
  `jobtype` varchar(25) NOT NULL DEFAULT 'police',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `mdt_convictions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `cid` varchar(50) DEFAULT NULL,
  `linkedincident` int(11) NOT NULL DEFAULT 0,
  `warrant` varchar(50) DEFAULT NULL,
  `guilty` varchar(50) DEFAULT NULL,
  `processed` varchar(50) DEFAULT NULL,
  `associated` varchar(50) DEFAULT '0',
  `charges` text DEFAULT NULL,
  `fine` int(11) DEFAULT 0,
  `sentence` int(11) DEFAULT 0,
  `recfine` int(11) DEFAULT 0,
  `recsentence` int(11) DEFAULT 0,
  `time` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `mdt_incidents` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `author` varchar(50) NOT NULL DEFAULT '',
  `title` varchar(50) NOT NULL DEFAULT '0',
  `details` LONGTEXT NOT NULL,
  `tags` text NOT NULL,
  `officersinvolved` text NOT NULL,
  `civsinvolved` text NOT NULL,
  `evidence` text NOT NULL,
  `time` varchar(20) DEFAULT NULL,
  `jobtype` varchar(25) NOT NULL DEFAULT 'police',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `mdt_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `text` text NOT NULL,
  `time` varchar(20) DEFAULT NULL,
  `jobtype` varchar(25) DEFAULT 'police',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `mdt_vehicleinfo` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `plate` varchar(50) DEFAULT NULL,
  `information` text NOT NULL,
  `stolen` tinyint(1) NOT NULL DEFAULT 0,
  `code5` tinyint(1) NOT NULL DEFAULT 0,
  `image` text NOT NULL,
  `points` int(11) DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `mdt_weaponinfo` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `serial` varchar(50) DEFAULT NULL,
  `owner` varchar(50) DEFAULT NULL,
  `information` text NOT NULL,
  `weapClass` varchar(50) DEFAULT NULL,
  `weapModel` varchar(50) DEFAULT NULL,
  `image` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `serial` (`serial`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `mdt_impound` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `vehicleid` int(11) NOT NULL,
  `linkedreport` int(11) NOT NULL,
  `fee` int(11) DEFAULT NULL,
  `time` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `mdt_clocking` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `user_id` varchar(50) NOT NULL DEFAULT '',
  `firstname` varchar(255) NOT NULL DEFAULT '',
  `lastname` varchar(255) NOT NULL DEFAULT '',
  `clock_in_time` varchar(255) NOT NULL DEFAULT '',
  `clock_out_time` varchar(50) DEFAULT NULL,
  `total_time` int(10) NOT NULL DEFAULT '0',
  PRIMARY KEY (`user_id`) USING BTREE,
  KEY `id` (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ===== resources/[standalone]/[New]/dr-rental/rentvehs.sql =====
CREATE TABLE IF NOT EXISTS `rentvehs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `vehicle` varchar(50) NOT NULL,
  `plate` varchar(50) NOT NULL,
  `time` int(100) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- ===== resources/[qb]/qb-drugs/qb-drugs.sql =====
CREATE TABLE IF NOT EXISTS `dealers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL DEFAULT '0',
  `coords` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `time` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `createdby` varchar(50) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=latin1;

-- ===== resources/[standalone]/[New]/ox_doorlock/sql/ox_doorlock.sql =====
CREATE TABLE
    IF NOT EXISTS `ox_doorlock` (
        `id` int (11) unsigned NOT NULL AUTO_INCREMENT,
        `name` varchar(50) NOT NULL,
        `data` longtext NOT NULL,
        PRIMARY KEY (`id`)
    );

-- ===== resources/[standalone]/[New]/ox_doorlock/sql/default.sql =====
INSERT IGNORE INTO `ox_doorlock` (`id`, `name`, `data`) VALUES
	(1, 'mrpd locker rooms', '{"maxDistance":2,"heading":90,"coords":{"x":450.1041259765625,"y":-985.7384033203125,"z":30.83930206298828},"groups":{"police":0},"state":1,"model":1557126584,"hideUi":false}'),
	(2, 'mrpd cells/briefing', '{"maxDistance":2,"coords":{"x":444.7078552246094,"y":-989.4454345703125,"z":30.83930206298828},"doors":[{"model":185711165,"coords":{"x":446.0079345703125,"y":-989.4454345703125,"z":30.83930206298828},"heading":0},{"model":185711165,"coords":{"x":443.40777587890627,"y":-989.4454345703125,"z":30.83930206298828},"heading":180}],"groups":{"police":0},"state":1,"hideUi":false}'),
	(3, 'mrpd cell 3', '{"maxDistance":2,"heading":90,"coords":{"x":461.8065185546875,"y":-1001.9515380859375,"z":25.06442832946777},"lockSound":"metal-locker","groups":{"police":0},"state":1,"unlockSound":"metallic-creak","model":631614199,"hideUi":false}'),
	(4, 'mrpd back entrance', '{"maxDistance":2,"coords":{"x":468.6697692871094,"y":-1014.4520263671875,"z":26.5362319946289},"doors":[{"model":-2023754432,"coords":{"x":467.37164306640627,"y":-1014.4520263671875,"z":26.5362319946289},"heading":0},{"model":-2023754432,"coords":{"x":469.9678955078125,"y":-1014.4520263671875,"z":26.5362319946289},"heading":180}],"groups":{"police":0},"state":1,"hideUi":false}'),
	(5, 'mrpd cells security door', '{"maxDistance":2,"heading":0,"coords":{"x":464.1282958984375,"y":-1003.5386962890625,"z":25.00598907470703},"autolock":5,"groups":{"police":0},"state":1,"model":-1033001619,"hideUi":false}'),
	(6, 'mrpd cell 2', '{"maxDistance":2,"heading":90,"coords":{"x":461.8064880371094,"y":-998.3082885742188,"z":25.06442832946777},"lockSound":"metal-locker","groups":{"police":0},"state":1,"unlockSound":"metallic-creak","model":631614199,"hideUi":false}'),
	(7, 'mrpd captain''s office', '{"maxDistance":2,"heading":180,"coords":{"x":446.57281494140627,"y":-980.0105590820313,"z":30.83930206298828},"groups":{"police":0},"state":1,"model":-1320876379,"hideUi":false}'),
	(8, 'mrpd gate', '{"maxDistance":6,"heading":90,"coords":{"x":488.894775390625,"y":-1017.2102661132813,"z":27.14714050292968},"groups":{"police":0},"auto":true,"state":1,"model":-1603817716,"hideUi":false}'),
	(9, 'mrpd cell 1', '{"maxDistance":2,"heading":270,"coords":{"x":461.8065185546875,"y":-993.7586059570313,"z":25.06442832946777},"lockSound":"metal-locker","groups":{"police":0},"state":1,"unlockSound":"metallic-creak","model":631614199,"hideUi":false}'),
	(10, 'mrpd cells main', '{"maxDistance":2,"heading":360,"coords":{"x":463.92010498046877,"y":-992.6640625,"z":25.06442832946777},"lockSound":"metal-locker","groups":{"police":0},"state":1,"unlockSound":"metallic-creak","model":631614199,"hideUi":false}'),
	(11, 'mrpd armoury', '{"maxDistance":2,"heading":270,"coords":{"x":453.08428955078127,"y":-982.5794677734375,"z":30.81926536560058},"autolock":5,"groups":{"police":0},"state":1,"model":749848321,"hideUi":false}');

-- ===== resources/standalone/cdn-fuel/assets/sql/cdn-fuel.sql =====
CREATE TABLE IF NOT EXISTS `fuel_stations` (
  `location` int(11) DEFAULT NULL,
  `owned` int(11) DEFAULT NULL,
  `owner` varchar(50) DEFAULT NULL,
  `fuel` int(11) DEFAULT NULL,
  `fuelprice` int(11) DEFAULT NULL,
  `balance` int(255) DEFAULT NULL,
  `label` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`location`)
) ENGINE=InnoDB;

INSERT IGNORE INTO `fuel_stations` (`location`, `owned`, `owner`, `fuel`, `fuelprice`, `balance`, `label`) VALUES
(1, 0, '0', 100000, 3, 0, 'Davis Avenue Ron'),
(2, 0, '0', 100000, 3, 0, 'Grove Street LTD'),
(3, 0, '0', 100000, 3, 0, 'Dutch London Xero'),
(4, 0, '0', 100000, 3, 0, 'Little Seoul LTD'),
(5, 0, '0', 100000, 3, 0, 'Strawberry Ave Xero'),
(6, 0, '0', 100000, 3, 0, 'Popular Street Ron'),
(7, 0, '0', 100000, 3, 0, 'Capital Blvd Ron'),
(8, 0, '0', 100000, 3, 0, 'Mirror Park LTD'),
(9, 0, '0', 100000, 3, 0, 'Clinton Ave Globe Oil'),
(10, 0, '0', 100000, 3, 0, 'North Rockford Ron'),
(11, 0, '0', 100000, 3, 0, 'Great Ocean Xero'),
(12, 0, '0', 100000, 3, 0, 'Paleto Blvd Xero'),
(13, 0, '0', 100000, 3, 0, 'Paleto Ron'),
(14, 0, '0', 100000, 3, 0, 'Paleto Globe Oil'),
(15, 0, '0', 100000, 3, 0, 'Grapeseed LTD'),
(16, 0, '0', 100000, 3, 0, 'Sandy Shores Xero'),
(17, 0, '0', 100000, 3, 0, 'Sandy Shores Globe Oil'),
(18, 0, '0', 100000, 3, 0, 'Senora Freeway Xero'),
(19, 0, '0', 100000, 3, 0, 'Harmony Globe Oil'),
(20, 0, '0', 100000, 3, 0, 'Route 68 Globe Oil'),
(21, 0, '0', 100000, 3, 0, 'Route 68 Workshop Globe O'),
(22, 0, '0', 100000, 3, 0, 'Route 68 Xero'),
(23, 0, '0', 100000, 3, 0, 'Route 68 Ron'),
(24, 0, '0', 100000, 3, 0, 'Rex\'s Diner Globe Oil'),
(25, 0, '0', 100000, 3, 0, 'Palmino Freeway Ron'),
(26, 0, '0', 100000, 3, 0, 'North Rockford LTD'),
(27, 0, '0', 100000, 3, 0, 'Alta Street Globe Oil');

-- ===== resources/XNLRankBar/XNLRankBar/XNLRankBar.sql =====
CREATE TABLE IF NOT EXISTS `experience` (
    `cid` varchar(50) NOT NULL,
    `driving` int(11) DEFAULT 0,
    `crafting` int(11) DEFAULT 0,
    UNIQUE KEY `unique_cid` (`cid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ===== resources/FiveM Vehicle Pack/SQLs/vehicles.sql =====
INSERT IGNORE INTO `vehicles` (`name`, `model`, `price`, `category`) VALUES
('Viper SRT 2016', 'viper', 149995, 'dodge'),
('Viper SRT 1999', '99viper', 47995, 'dodge'),
('Diplomat 1983', 'diplomat83', 8660, 'dodge'),
('Charger 1969', '69charger', 69995, 'dodge'),
('Charger 2010 F=F', 'SRT8F', 75000, 'dodge'),
('Challenger hellcat', 'demon', 27295, 'dodge'),
('Dodge Charger', '16charger', 79000, 'dodge'),
('Dodge Charger 2017', '2017Charger', 77745, 'dodge'),
('Dodge Challanger', '16challanger', 76000, 'dodge'),
('Dodge Ram', 'megaram', 88000, 'dodge'),
('Dodge Ram Limited', 'dl2016', 95000, 'dodge'),
('Dodge Charger', 'charger', 79000, 'dodge'),
('G65 AMG', 'g65amg', 178700, 'mercedes'),
('C63', 'c63s', 76000, 'mercedes'),
('CLA 45', 'cla45sb2', 99350, 'mercedes'),
('SLS AMG', 'slsamg', 225950, 'mercedes'),
('GT AMG', 'amggt', 120000, 'mercedes'),
('SL 63 AMG', 'benzsl63', 167595, 'mercedes'),
(' Brabus 850 S', 'brabus850', 410000, 'mercedes'),
('GLS 63 AMG 2015', 'gls63', 74843, 'mercedes'),
('Mercedes-Benz G-Wagon 6x6', 'dubsta3', 451000, 'mercedes'),
('Mercedes-Benz G-Wagon 6x6 Brabus', 'brabus700', 455000, 'mercedes'),
('Mercedes-Benz  GLE AMG', 'gle', 82000, 'mercedes'),
('Mercedes-Benz X class', 'xclass', 40830, 'mercedes'),
('Mercedes-Benz E63 AMG', 'e63amg', 124993, 'mercedes'),
('Mercedes-Benz G-Wagon Lorinser', 'g60l', 164500, 'mercedes'),
('Mercedes-Benz GL63', 'gl63', 146000, 'mercedes'),
('Mercedes-Benz ML Brabus', 'mlbrabus', 116000, 'mercedes'),
('Mercedes-Benz S-class 500', 's500w222', 124800, 'mercedes'),
('Mercedes-Benz W140', 'w140', 50000, 'mercedes'),
('R8 V10', 'r8ppi', 98500, 'audi'),
('A6', 'a615', 79000, 'audi'),
('RS7 Sportback', 'rs7', 78900, 'audi'),
('A7', 'a7', 13700, 'audi'),
('RS4', 'rs4avant', 18000, 'audi'),
('RS6', 'rs6', 28700, 'audi'),
('S3', '2015s3', 37000, 'audi'),
('S4', 'b5s4', 75000, 'audi'),
('SQ7', 'sq72016', 70750, 'audi'),
('Q8', 'q820', 82200, 'audi'),
('TT RS', '15750', 12500, 'audi'),
('Audi A8', 'a8fsi', 120050, 'audi'),
('Audi A8L W12', 'a8lw12', 124050, 'audi'),
('Audi A8', 'a8audi', 120050, 'audi'),
('Audi A4 2017', 'aaq4', 43825, 'audi'),
('Audi RS3 2011', 'rs3', 55400, 'audi'),
('Audi RS3 2018', 'rs318', 62900, 'audi'),
('Audi RS5 2011', 'rs5', 25934, 'audi'),
('Audi S1', 's1', 36930, 'audi'),
('Audi S8', 'audis8om', 156400, 'audi'),
('Audi TT', 'yAudiTTmk1', 50380, 'audi'),
('Audi Q7', 'as7', 80930, 'audi'),
('Chevrolet Tahoe', 'rancherxl', 45700, 'chevrolet'),
('1959 Chevrolet Impala', 'impala59c', 59000, 'chevrolet'),
('Chevrolet Corvette ZR1', '2019zr1', 101995, 'chevrolet'),
('Chevrolet Camaro SS', 'alpha6', 65000, 'chevrolet'),
('Chevrolet Camaro Henessey', 'exor', 200000, 'chevrolet'),
('Chevrolet C10', 'c10custom', 26000, 'chevrolet'),
('Chevrolet Silverado', 'silv86', 64390, 'chevrolet'),
('Chevrolet Corvette C7', 'c7', 89900, 'chevrolet'),
('Corvette C8', 'c8', 60000, 'chevrolet'),
('Chevrolet Blazer', 'k5blazer', 37300, 'chevrolet'),
('Chevrolet Corvette', 'forgieC7', 118470, 'chevrolet'),
('M4', 'f82', 120000, 'bmw'),
('M5', 'bmci', 98300, 'bmw'),
('M8', 'bmwm8', 162000, 'bmw'),
('i8', 'i8', 145700, 'bmw'),
('BMW 760i', 'bmwe65', 101900, 'bmw'),
('BMW E30 Alpina', 'alpinae30', 44500, 'bmw'),
('BMW M5 F90', 'm5f90', 129600, 'bmw'),
('M2', 'm2', 45000, 'bmw'),
('M3 E46 Pandem Rocket Bunny', 'm346', 25000, 'bmw'),
('M6', 'm6f13', 45000, 'bmw'),
('Z3', 'z3', 56000, 'bmw'),
('S1000RR', 'bmws', 20140, 'bmw'),
('BMW M1', 'm1procar', 658000, 'bmw'),
('BMW M3 E30', 'm3e30', 85470, 'bmw'),
('BMW M3 E46', 'm3e46', 13450, 'bmw'),
('BMW M3 GTS', 'm3', 136850, 'bmw'),
('BMW M7 2017', '17m760i', 159900, 'bmw'),
('BMW X6 M Sport', 'x6m', 101650, 'bmw'),
('Toyota GT-86', 'gt86', 35900, 'toyota'),
('Toyota Supra MK IV', 'rmodsupra', 88900, 'toyota'),
('Toyota Land Cruiser', 'fj40', 45900, 'toyota'),
('Toyota Celica', 'celica', 3968, 'toyota'),
('Velar 2018', '18Velar', 59525, 'rangerover'),
('Vogue Startech', 'rrst', 32500, 'rangerover'),
('model S', 'models', 122000, 'tesla'),
('RX-7 Tunable', 'rx7tunable', 17000, 'mazda'),
('RX8', 'rx8r', 12000, 'mazda'),
('Mazda RX-8 Mad Mike Edition', 'rx8m', 12000, 'mazda'),
('X', 'teslax', 150000, 'tesla'),
('3', 'tmodel', 190000, 'tesla'),
('Roadster', 'tr22', 250000, 'tesla'),
('Tesla Model S Prior Design', 'teslapd', 815000, 'tesla'),
('Skyline GT-R34', 'skyline', 141995, 'nissan'),
('GTR', 'gtr', 140990, 'nissan'),
('Silvia S15', 's15tex', 60000, 'nissan'),
('300zx', 'threeladyz', 36000, 'nissan'),
('GTR Liberty Walk', 'lwgtr', 46000, 'nissan'),
('R91CP', 'r91cp', 450000, 'nissan'),
('Titan', 'nissantitan17', 70000, 'nissan'),
('180sx', '180sx', 18000, 'nissan'),
('Nissan 370Z', '370z', 22770, 'nissan'),
('Nissan Patrol Nismo', 'tulenis', 49458, 'nissan'),
('Nissan Qashqai', 'qashqai16', 27250, 'nissan'),
('Lancer EVO', 'mlec', 53995, 'mitsubishi'),
('Lancer EVO', 'kuruma', 53995, 'mitsubishi'),
('Mitsubishi Lancer 9', 'evo9', 24597, 'mitsubishi'),
('Sport RS', 'sportrs', 400000, 'renault'),
('Clio 4', '17cliofl', 35000, 'renault'),
('Twingo', 'twingo', 15000, 'renault'),
('Twizy', 'twizy', 5000, 'renault'),
('Zoe', 'zoe', 15000, 'renault'),
('Renault Espace', 'pacev', 30017, 'renault'),
('XJR', 'xjr', 92370, 'jaguar'),
('XKRS GT2', 'xkgt', 110000, 'jaguar'),
('Jaguar F-Pace Hamman', 'fpacehm', 180000, 'jaguar'),
('C3', 'citroenc3', 26000, 'citroen'),
('DS4', 'ds4', 34000, 'citroen'),
('V60', 'v60pols', 83000, 'volvo'),
('V850R', 'v850r', 7500, 'volvo'),
('Raptor', 'f150', 65000, 'ford'),
('GT 2017', 'gt17', 700000, 'ford'),
('GT 40', 'fg4m', 350000, 'ford'),
('Mustang 1965', 'mustang65', 250999, 'ford'),
('Mustang GT 2015', 'shelbygt350', 67750, 'ford'),
('Ford Mustang Ken Block Edition', 'keenblock', 1500000, 'ford'),
('Ford Mustang GT', 'mgt', 55800, 'ford'),
('Ford Focus RS', 'forusrs', 43800, 'ford'),
('Ford Mustang GT', 'rmodmustang', 43800, 'ford'),
('Ford Mustang 1969 Ken Block Edition', 'fordhv2', 185000, 'ford'),
('Ford Fairlane', 'fair500', 43400, 'ford'),
('Ford Escape', 'fescape', 37699, 'ford'),
('Ford Mustang 2019', 'mustang19', 46900, 'ford'),
('Ford Mustang', 'boss302', 56000, 'ford'),
('Ford Mustang Mach1', 'mustangmach1', 32500, 'ford'),
('Ford F150 Wide', 'rrf150w', 38950, 'ford'),
('Evora GTE', 'evora', 104750, 'lotus'),
('SRT 8', 'srt8', 55000, 'jeep'),
('Wrangler', 'jeep2012', 38000, 'jeep'),
('Wrangler Trailcat', 'trailcat', 56000, 'jeep'),
('Jeep Wrangler Rubicon', 'rubi3d', 58050, 'jeep'),
('Civic 1999', 'civic', 15500, 'honda'),
('Civic Sedan', 'honci4', 28900, 'honda'),
('Civic Typer', 'fk8', 35000, 'honda'),
('CB500 X2', '500x', 6500, 'honda'),
('Gold Wing', 'goldwing', 23500, 'honda'),
('Impreza', 'ySbrImpS11', 22400, 'subaru'),
('Huracan', 'lp610', 474390, 'lamborghini'),
('Aventador S', 'aventadors', 717650, 'lamborghini'),
('Urus 2018', 'urus2018', 200950, 'lamborghini'),
('Gallardo', 'gallardo2005', 225400, 'lamborghini'),
('Veneno', 'rmodveneno', 3500000, 'lamborghini'),
('Centenario', 'lp770', 1900000, 'lamborghini'),
('Reventon', 'lamboreventon', 1680000, 'lamborghini'),
('Lamborghini Diablo', 'diablo', 304035, 'lamborghini'),
('Veyron', 'bugatti', 2250880, 'bugatti'),
('Chiron', '2019chiron', 2800000, 'bugatti'),
('Quattroporte GTS', 'mqgts', 337000, 'maserati'),
('GranTurismo', 'masgt', 262880, 'maserati'),
('Maserati Levante Novite', 'mlnovitec', 94950, 'maserati'),
('430S', 'f430s', 299054, 'ferrari'),
('Portofino', 'ferporto', 410550, 'ferrari'),
('488 Pista', 'pista', 580350, 'ferrari'),
('La Ferrari Aperta', 'aperta', 1516362, 'ferrari'),
('360 Stradale', 'fstradale', 382000, 'ferrari'),
('458 Speciale', '458speciale', 291744, 'ferrari'),
('488 Mansory', 'fm488', 1250395, 'ferrari'),
('F8 Tributo', 'f8t', 293480, 'ferrari'),
('812 Superfast', 'f812', 443000, 'ferrari'),
('F40', 'f40', 650000, 'ferrari'),
('F12 N-Largo', 'nlargo', 558000, 'ferrari'),
('Ferrari FXXK', 'fxxk', 2500000, 'ferrari'),
('Ferrari 288 GTO', 'f288gto', 1300000, 'ferrari'),
('Ferrari Enzo', 'enzo', 675000, 'ferrari'),
('Ferrari Testa Rossa', '250testarossa', 160000, 'ferrari'),
('DB11', 'db11', 821995, 'aston'),
('DBX', 'dbx', 189900, 'aston'),
('DB7', 'db7zagato', 550000, 'aston'),
('Virage', 'virage', 308295, 'aston'),
('Aston Martin Spyker', 'spyker', 330990, 'aston'),
('Aston Martin Vanquish', 'ast', 280094, 'aston'),
('Aston Martin Vantage', 'vantage', 155294, 'aston'),
('Aston Martin Vulcan', 'vulcan', 3800000, 'aston'),
('P1', 'p1', 1799888, 'mclaren'),
('P1 GTR', 'p1gtr', 2195000, 'mclaren'),
('F1', 'f1', 1200500, 'mclaren'),
('650s LW', '650slw', 365500, 'mclaren'),
('McLaren 720', '720s', 282500, 'mclaren'),
('Zonda Tricolore', 'tricolore', 1425000, 'pagani'),
('Zonda Huayra BC', 'bc', 1750352, 'pagani'),
('718 Boxster', '718boxster', 282800, 'porsche'),
('Porsche 911 Carreras', 'carreta', 374100, 'porsche'),
('Pamera', 'pturismo', 289600, 'porsche'),
('Porsche 918', '918', 887000, 'porsche'),
('Speedster 2020', 'str20', 274500, 'porsche'),
('Porsche Cayenne', 'cayenne', 144117, 'porsche'),
('Porsche Cayman S', '718caymans', 24981, 'porsche'),
('Porsche Ruf', 'pruf', 12628, 'porsche'),
('Agera R', 'acsr', 2500000, 'koenigsegg'),
('Regera', 'regera', 2000000, 'koenigsegg'),
('Bentayaga', 'bentaygam', 215000, 'bentley'),
('Supersport', 'ben17', 497000, 'bentley'),
('Bentley Continental GT 2013', 'contgt13', 43940, 'bentley'),
('Bentley Continental GT 2014', 'bcgt', 220724, 'bentley'),
('Bentley EXP', 'bexp', 246000, 'bentley'),
('Bentley Mulsanne Mulliner 2013', 'bmm', 400000, 'bentley'),
('Phantom', 'rrphantom', 855000, 'rollsroyce'),
('Sweptail', 'sweptail', 3500000, 'rollsroyce'),
('Cullinan', 'rculi', 325000, 'rollsroyce'),
('Wraith', 'wraith', 650000, 'rollsroyce'),
('RR08', 'desmo', 65000, 'ducati'),
('Terminator 2', 'hvrod', 450000, 'harley'),
('Rot night', 'hvrod2', 13995, 'harley'),
('Ninja H2', 'nh2r', 72000, 'kawasaki'),
('GSX-R 1000', 'gsxr', 18500, 'suzuki'),
('R1', 'r1', 15600, 'yamaha'),
('R6', 'r6', 21000, 'yamaha'),
('XT660 R', 'xt66', 10550, 'yamaha'),
('YZF 250', 'yzf250sm', 7699, 'yamaha'),
('Apollo Intensa Emozione', 'apolloie', 2300000, 'apollo'),
('Hauler', 'trailersmall', 50000, 'hauler'),
('Pontiac Firebird', '2018transam', 44000, 'pontiac'),
('Volkswagen Passat', 'passatr', 34362, 'volkswagen'),
('Volkswagen Touareg', 'r50', 102670, 'volkswagen'),
('Acura RSX-S', 'arxs', 7279, 'acura'),
('Acura NSX', 'filthynsx', 189900, 'acura'),
('Alfa Romeo 4C spider', '4c', 47832, 'alfaromeo'),
('Alfa Romeo 33 Stradale', 'alfa67', 300000, 'alfaromeo'),
('Alfa Romeo Disco Volante', 'ardv', 159700, 'alfaromeo'),
('Alfa Romeo Giulia Quadrifoglio', 'giulia', 64890, 'alfaromeo'),
('Alfa Romeo Giulietta Quadrifoglio Verde', 'argiu', 34600, 'alfaromeo'),
('Alfa Romeo Stelvio Quadrifoglio', 'stelvio', 91400, 'alfaromeo'),
('Alfa Romeo TZ3', 'tz3', 699999, 'alfaromeo'),
('Darmon bobber', 'dabob', 14500, 'others'),
('F4 RR', 'f4rr', 8500, 'others'),
('RSV 4', 'rsv4', 13000, 'others'),
('GMC Yukon', 'gmcyd', 115000, 'others'),
('GMC Sierra Delani', 'delanihd', 93900, 'others'),
('Hummer H6', 'h6', 125000, 'others'),
('Lexus LX 570', 'lx570', 110300, 'others'),
('Lexus RX 450h', 'rx450h', 86490, 'others'),
('Lexus RCF', 'rcf', 199990, 'others'),
('Buick GSX', 'gsxb', 105321, 'others'),
('Cadillac ATSV Coupe', 'cats', 44400, 'others'),
('Cadillac XLRV', 'xlrv', 27442, 'others'),
('Oldsmobile Delta 73', 'dlt88', 16398, 'others'),
('Chrystler 300 SRT8', '300srt8', 8116, 'others'),
('SXF 450', 'sxf450sm', 9500, 'others');

-- ===== resources/FiveM Vehicle Pack/SQLs/vehicle_categories.sql =====
INSERT IGNORE INTO `vehicle_categories` (`name`, `label`) VALUES
('mitsubishi', 'Mitsubishi'),
('mazda', 'Mazda'),
('tesla', 'Tesla'),
('chevrolet', 'Chevrolet'),
('nissan', 'Nissan'),
('toyota', 'Toyota'),
('dodge', 'Dodge'),
('mercedes', 'Mercedes'),
('bmw', 'BMW'),
('audi', 'Audi'),
('ford', 'Ford'),
('renault', 'Renault'),
('jaguar', 'Jaguar'),
('citroen', 'Citroen'),
('volvo', 'Volvo'),
('jeep', 'Jeep'),
('subaru', 'Subaru'),
('lotus', 'Lotus'),
('honda', 'Honda'),
('maserati', 'Maserati'),
('bugatti', 'Bugatti'),
('lamborghini', 'Lamborghini'),
('porsche', 'Porsche'),
('bentley', 'Bentley'),
('aston', 'Aston Martin'),
('pagani', 'Pagani'),
('mclaren', 'Mc Laren'),
('ferrari', 'Ferrari'),
('koenigsegg', 'Koenigsegg'),
('rollsroyce', 'Rolls Royce'),
('yamaha', 'Yamaha'),
('kawasaki', 'Kawasaki'),
('suzuki', 'Suzuki'),
('ducati', 'Ducati'),
('harley', 'Harley Davidson'),
('apollo', 'Apollo'),
('hauler', 'Hauler'),
('pontiac', 'Pontiac'),
('volkswagen', 'Volkswagen'),
('acura', 'Acura'),
('rangerover', 'Range Rover'),
('alfaromeo', 'Alfa Romeo'),
('others', 'Others');

-- ===== resources/jobs_creator/basjobs.sql =====
CREATE TABLE IF NOT EXISTS basjobs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    job_label VARCHAR(255) NOT NULL,
    job_name VARCHAR(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS basjob_ranks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    job_name VARCHAR(255) NOT NULL,
    job_label VARCHAR(255) NOT NULL,
    label VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    grade INT NOT NULL,
    salary INT NOT NULL
);


