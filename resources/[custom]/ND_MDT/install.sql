-- ND_MDT database tables
-- Run this once in your database (HeidiSQL, phpMyAdmin, or via oxmysql on startup)

CREATE TABLE IF NOT EXISTS `nd_mdt_bolos` (
    `id`        INT          NOT NULL AUTO_INCREMENT,
    `type`      VARCHAR(50)  NOT NULL DEFAULT 'person',
    `data`      LONGTEXT     NOT NULL,
    `timestamp` INT          NOT NULL DEFAULT (UNIX_TIMESTAMP()),
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `nd_mdt_reports` (
    `id`        INT          NOT NULL AUTO_INCREMENT,
    `type`      VARCHAR(50)  NOT NULL DEFAULT 'crime',
    `data`      LONGTEXT     NOT NULL,
    `timestamp` INT          NOT NULL DEFAULT (UNIX_TIMESTAMP()),
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `nd_mdt_records` (
    `id`        INT          NOT NULL AUTO_INCREMENT,
    `character` VARCHAR(100) NOT NULL,
    `records`   LONGTEXT     NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `character` (`character`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `nd_mdt_weapons` (
    `id`         INT          NOT NULL AUTO_INCREMENT,
    `character`  VARCHAR(100) NOT NULL,
    `weapon`     VARCHAR(100) NOT NULL,
    `serial`     VARCHAR(100) NOT NULL,
    `owner_name` VARCHAR(100)          DEFAULT NULL,
    `stolen`     TINYINT(1)   NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    UNIQUE KEY `serial` (`serial`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
