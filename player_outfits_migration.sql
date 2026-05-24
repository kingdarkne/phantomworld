-- Run this ONCE if qb-clothing errors with: Unknown column 'skin' in 'field list'
-- Your DB may have player_outfits from an old schema (props, components). qb-clothing expects (skin, outfitId).
-- If you get "Duplicate column name" then the migration was already applied; you can ignore.

USE `s36165_9903ef012b`;

ALTER TABLE `player_outfits` ADD COLUMN `skin` TEXT DEFAULT NULL;
ALTER TABLE `player_outfits` ADD COLUMN `outfitId` VARCHAR(50) DEFAULT NULL;
