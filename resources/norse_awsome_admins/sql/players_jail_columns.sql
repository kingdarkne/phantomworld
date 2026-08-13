-- norse_awsome_admins / prison jail columns for Qbox `players` table.
-- Fixes: Unknown column 'jail_time' in 'SELECT'
-- Safe to re-run (IF NOT EXISTS).

ALTER TABLE `players`
  ADD COLUMN IF NOT EXISTS `jail_time` INT(11) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS `jail_type` VARCHAR(50) NULL DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS `jail_cell` VARCHAR(50) NULL DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS `jail_cell_items` LONGTEXT NULL DEFAULT NULL;
