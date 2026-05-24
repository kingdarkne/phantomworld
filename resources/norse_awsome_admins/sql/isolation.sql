-- Isolation tracking for norse_awsome_admins
-- Tracks isolation status separate from prison bans

CREATE TABLE IF NOT EXISTS `oxoadmin_isolation` (
  `id`                INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `identifier`        VARCHAR(64)  NOT NULL,
  `name`              VARCHAR(64)  NOT NULL,
  `offense_count`     INT UNSIGNED NOT NULL DEFAULT 0,
  `isolation_minutes` INT UNSIGNED NOT NULL,
  `started`           INT UNSIGNED NOT NULL,
  `expires`           INT UNSIGNED NOT NULL,
  `paused_jail_time`  INT UNSIGNED DEFAULT NULL,
  `staff`             VARCHAR(64)  NOT NULL,
  `active`            TINYINT(1)   NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `idx_identifier_active` (`identifier`,`active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
