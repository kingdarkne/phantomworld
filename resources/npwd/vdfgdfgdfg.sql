-- 1) Confirm player_groups now returns rows
SELECT `group`, type, grade FROM player_groups WHERE citizenid = 'TUX06165';

-- 2) Confirm phone update with quotes works
UPDATE users SET phone_number = '822-404-1594' WHERE identifier = '1c35ffbda8c427b2a6354135e978246e6a3ce302';
SELECT phone_number FROM users WHERE identifier = '1c35ffbda8c427b2a6354135e978246e6a3ce302';