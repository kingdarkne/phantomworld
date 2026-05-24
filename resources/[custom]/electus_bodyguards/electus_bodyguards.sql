CREATE TABLE IF NOT EXISTS `electus_bodyguards` (
  `identifier` varchar(46) NOT NULL,
  `slot` int(11) NOT NULL,
  `model` varchar(50) DEFAULT NULL,
  `weapon` varchar(50) DEFAULT NULL,
  `ammo` int(11) DEFAULT 0,
  `time` int(11) DEFAULT NULL,
  `days` int(11) DEFAULT NULL,
  `isDead` int(1) DEFAULT 0,
  `inService` int(1) DEFAULT 0,
  `isRecruit` int(1) unsigned zerofill DEFAULT 0,
  `isBackup` tinyint(1) DEFAULT 0,
  `components` text DEFAULT NULL,
  PRIMARY KEY (`identifier`,`slot`)
);

CREATE TABLE IF NOT EXISTS `electus_bodyguards_friends` (
  `identifier` varchar(46) NOT NULL,
  `friend` varchar(50) DEFAULT NULL
);

