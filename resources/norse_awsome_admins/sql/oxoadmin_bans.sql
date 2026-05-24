CREATE TABLE IF NOT EXISTS `oxoadmin_bans` (
  `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `identifier` VARCHAR(64)  NOT NULL,
  `name`       VARCHAR(64)  NOT NULL,
  `reason`     TEXT         NOT NULL,
  `created`    INT UNSIGNED NOT NULL,
  `expires`    INT UNSIGNED NOT NULL,
  `staff`      VARCHAR(64)  NOT NULL,
  `type`       ENUM('ban','prison') NOT NULL DEFAULT 'ban',
  `active`     TINYINT(1)   NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `idx_identifier` (`identifier`),
  KEY `idx_type_active` (`type`,`active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
