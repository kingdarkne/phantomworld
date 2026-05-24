--[[
  ------------------------------------------------------------------------------------------------
    Next Death - Advanced death system
  ------------------------------------------------------------------------------------------------
  _   _ ________   _________ _____ ____  _____  ______ 
 | \ | |  ____\ \ / /__   __/ ____/ __ \|  __ \|  ____|
 |  \| | |__   \ V /   | | | |   | |  | | |__) | |__   
 | . ` |  __|   > <    | | | |   | |  | |  _  /|  __|  
 | |\  | |____ / . \   | | | |___| |__| | | \ \| |____ 
 |_| \_|______/_/ \_\  |_|  \_____\____/|_|  \_\______|                                                       
                                                       
  ------------------------------------------------------------------------------------------------
    Created for Nextcore Studio by Junnho
  ------------------------------------------------------------------------------------------------
    
    Author: Nextcore Studio
    Copyright © 2025 Junnho. All rights reserved.
    Copyright © 2025 Nextcore Studio. All rights reserved.
    License: EULA (see LICENSE file)
    
    Documentation: https://www.nextcorestudio.com/docs/next-death/
    Website: https://www.nextcorestudio.com/
    Script Page: https://www.nextcorestudio.com/scripts/next-death/?from=homepage
    Tebex: https://nextcorestudio.tebex.io/package/7057654

--------------------------------------------------------------------------------------------------
]]

Locales['ru'] = {
    
    ['you_are_dead'] = 'Вы мертвы',
    ['you_are_unconscious'] = 'ВЫ БЕЗ СОЗНАНИЯ',
    ['it_will_take_time'] = 'Потребуется время, прежде чем вы восстановите силы',
    ['alert_sent_to_ems'] = 'Тревога отправлена в службу спасения',
    ['call_emergency_services'] = 'Вызвать службу спасения',
    ['respawn'] = 'Восстановиться',
    ['bleeding_out'] = 'Вы истекаете кровью',
    ['time_remaining'] = 'Оставшееся время: %s',
    ['early_respawn_available'] = 'Досрочное воскрешение доступно',
    ['press_to_respawn'] = 'Нажмите %s для воскрешения',
    ['press_to_call_ems'] = 'Нажмите %s для вызова службы спасения',
    ['calling_ems'] = 'Вызов службы спасения...',
    ['ems_called'] = 'Служба спасения вызвана!',
    ['ems_cooldown'] = 'Вы должны подождать перед повторным вызовом',
    ['voice_blocked'] = 'Вы не можете говорить, когда мертвы',
    ['weapons_removed'] = 'Ваше оружие было изъято',
    ['revived'] = 'Вас воскресили',
    ['respawned'] = 'Вы воскресли',

    
    ['ems_alert_title'] = 'Тревога службы спасения',
    ['ems_alert_description'] = '%s нужна помощь!',
    ['ems_alert_location'] = 'Местоположение: %s',
    ['ems_alert_victim'] = 'Жертва: %s',

    
    ['admin_title'] = 'Next Death',
    ['menu_title'] = 'Главное меню',
    ['timers'] = 'Задержки',
    ['early_respawn'] = 'Досрочное воскрешение',
    ['early_respawn_desc'] = 'Позволяет игрокам возродиться до окончания таймера кровотечения.',
    ['time_before_early_respawn'] = 'Время до досрочного воскрешения',
    ['forced_respawn'] = 'Принудительное возрождение',
    ['forced_respawn_desc'] = 'Автоматически возрождает игрока в больнице, когда таймер кровотечения достигает нуля.',
    ['time_before_forced_respawn'] = 'Время до принудительного возрождения',

    ['options'] = 'Снаряжение',
    ['remove_weapons_on_respawn'] = 'Обезоружить при возрождении',
    ['remove_weapons_desc'] = 'Удаляет все оружие у игрока при возрождении.',
    ['drop_weapon_on_death'] = 'Выбросить текущее оружие на землю',
    ['drop_weapon_desc'] = 'Заставляет игрока выронить текущее оружие на землю при смерти.',

    ['lose_inventory_on_respawn'] = 'Потеря инвентаря при возрождении',
    ['lose_inventory_desc'] = 'Удаляет предметы из инвентаря игрока при возрождении. Ничего не удаляется, если игрока реанимируют в игре или администраторы.',
    ['inventory_whitelist'] = 'Белый список инвентаря',
    ['inventory_whitelist_desc'] = 'Предметы, которые НЕ будут удалены (через запятую).',
    ['save'] = 'СОХРАНИТЬ',
    ['saved'] = 'СОХРАНЕНО',

    ['respawn_location'] = 'Место воскрешения',
    ['respawn_at_location'] = 'Возродиться в больнице (Соло-возрождение)',
    ['respawn_at_location_desc'] = 'Позволяет игроку возродиться в больнице, когда опция включена и таймер достигает нуля.',
    ['revive_at_location'] = 'Возродиться в больнице (Внешнее возрождение)',
    ['revive_at_location_desc'] = 'Когда включено, игрок, которого оживил другой игрок, будет автоматически телепортирован в больницу.',
    ['admin_hospital_coords'] = 'Координаты',
    ['get_current_position'] = 'Получить текущую позицию',
    ['nearest_respawn_point_enabled'] = 'Мульти-респавн',
    ['nearest_respawn_point_enabled_desc'] = 'Если включено, игрок возрождается в ближайшей пользовательской точке респавна.',
    ['custom_respawn_points'] = 'Пользовательские точки респавна',
    ['custom_respawn_points_desc'] = 'Все пользовательские точки показаны ниже и редактируются напрямую.',
    ['add_respawn_point'] = 'Добавить точку респавна',
    ['respawn_point'] = 'Точка %s',
    ['remove_respawn_point'] = 'Удалить',
    ['respawn_point_label'] = 'Метка',
    ['respawn_point_heading'] = 'Направление',
    ['hospital_label'] = 'Больница',


    ['bonus'] = 'Урон',
    ['damage_indicator_title'] = 'Индикатор урона',
    ['damages_desc'] = 'Настройка визуальных эффектов (цветная виньетка), которые появляются на экране, когда игроки получают урон.',
    ['damage_vignette_enabled'] = 'Включить эффекты урона',
    ['damage_vignette_opacity'] = 'Непрозрачность урона',
    ['damage_vignette_color'] = 'Цвет эффекта',

    ['configuration'] = 'Конфигурация',
    ['parametres'] = 'Параметры',
    ['language'] = 'Язык',
    ['language_description'] = 'Язык интерфейса.',
    ['found_bug'] = 'Нашли ошибку? Сообщите нам:',
    ['detected_inventory'] = 'Обнаруженный инвентарь :',

    
    ['config_saved_successfully'] = 'Конфигурация успешно сохранена!',
    ['admin_saved'] = 'Конфигурация сохранена!',
    ['admin_error'] = 'Ошибка при сохранении',
    ['no_inventory_detected'] = 'Ни один не обнаружен',
    ['notification_death'] = 'Вы мертвы',
    ['notification_bleeding'] = 'Вы истекаете кровью - вызовите помощь!',
    ['notification_ems_called'] = 'Служба спасения вызвана!',
    ['notification_ems_cooldown'] = 'Подождите перед повторным вызовом службы спасения',
    ['notification_revived'] = 'Вас воскресили',
    ['notification_weapons_removed'] = 'Похоже, вы потеряли свои вещи',
    ['notification_regained_consciousness'] = 'Вы пришли в сознание',

    
    ['command_revive'] = 'Воскресить игрока',
    ['command_reload_config'] = 'Перезагрузить конфигурацию',
    ['command_no_permission'] = 'У вас нет разрешения использовать эту команду',

    
    ['time_minutes'] = '%d мин',
    ['time_seconds'] = '%d сек',
    ['time_minutes_seconds'] = '%d мин %d сек',
    ['error'] = 'Ошибка',
    ['invalid_player_id'] = 'Неверный ID игрока',
    ['item_pickup_failed'] = 'Не удалось поднять предмет (инвентарь полон?)',
    ['timer_respawn_order_warning'] = 'Время принудительного респавна должно быть больше времени раннего респавна. Если оставить так, параметры не будут сохранены.',
    ['success'] = 'Успех',
    ['alert'] = 'Внимание',
    ['info'] = 'Информация',
    ['notification_title_error'] = 'Ошибка',
    ['notification_title_success'] = 'Успех',
    ['notification_title_alert'] = 'Внимание',
    ['notification_title_info'] = 'Информация',
    ['admin_invalid_player_id'] = 'Неверный ID игрока',
    ['admin_invalid_id'] = 'Неверный ID',
    ['admin_player_not_found'] = 'Игрок не найден',
    ['admin_not_dead'] = 'Вы не мертвы',
    ['admin_kill_target_success'] = 'Вы убили %s',
    ['admin_killed_by_admin'] = 'Вас убил администратор',
    ['admin_revive_target_success'] = 'Вы воскресили %s',
    ['admin_revived_by_admin'] = 'Вас воскресил администратор',
    ['admin_weapon_remove_failed'] = 'Не удалось удалить оружие из инвентаря',
    ['admin_invalid_time'] = 'Неверные значения времени',
    ['admin_invalid_coords'] = 'Неверные координаты',
    ['notification_unconscious'] = 'Вы без сознания',
    ['press_e_to_pickup'] = 'Нажмите E, чтобы поднять',
    ['unknown'] = 'Неизвестно',
    ['unknown_location'] = 'Неизвестное местоположение',
    ['admin_db_not_loaded'] = 'База конфигурации не загружена. Сохранение заблокировано.',
}