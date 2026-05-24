-- Qbox migration: players.userId, bank_accounts_new, player_groups
-- Run this ONCE against the same database your server uses.

-- 1) Add userId column to existing players table
-- (Already applied on your database – left commented so re-running this file is safe)
-- ALTER TABLE players
--     ADD COLUMN `userId` INT UNSIGNED DEFAULT NULL AFTER `id`;


-- 2) Create Qbox bank accounts table (used by Qbox banking)
CREATE TABLE IF NOT EXISTS bank_accounts_new (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    name VARCHAR(64) NOT NULL,        -- account identifier, e.g. job/society name
    label VARCHAR(128) DEFAULT NULL,  -- display/display name
    balance INT NOT NULL DEFAULT 0,
    PRIMARY KEY (id),
    UNIQUE KEY uniq_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- 3) Create Qbox player groups table (for Qbox group system)
CREATE TABLE IF NOT EXISTS player_groups (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    citizenid VARCHAR(50) NOT NULL,
    group_name VARCHAR(64) NOT NULL,
    grade INT NOT NULL DEFAULT 0,
    PRIMARY KEY (id),
    KEY idx_citizenid (citizenid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

