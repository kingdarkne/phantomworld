-- ps-housing: create properties table in dracula_v5.1
-- Run this in HeidiSQL (or MySQL) on database dracula_v5.1

USE `dracula_v5.1`;

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
