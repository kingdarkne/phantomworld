CREATE TABLE IF NOT EXISTS `oxoadmin_names` (
  `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `identifier` VARCHAR(64)  NOT NULL,
  `type`       ENUM('fx','rp') NOT NULL,
  `name`       VARCHAR(64)  NOT NULL,
  `created`    INT UNSIGNED NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_identifier_type` (`identifier`,`type`),
  UNIQUE KEY `uniq_identifier_type_name` (`identifier`,`type`,`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
