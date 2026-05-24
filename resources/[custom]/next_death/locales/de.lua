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

Locales['de'] = {
    
    ['you_are_dead'] = 'Sie sind tot',
    ['you_are_unconscious'] = 'SIE SIND BEWUSSTLOS',
    ['it_will_take_time'] = 'Es wird einige Zeit dauern, bis Sie Ihre Kräfte wiedererlangen',
    ['alert_sent_to_ems'] = 'Alarm an Rettungsdienste gesendet',
    ['call_emergency_services'] = 'Rettungsdienste anrufen',
    ['respawn'] = 'Erholen',
    ['bleeding_out'] = 'Sie bluten',
    ['time_remaining'] = 'Verbleibende Zeit: %s',
    ['early_respawn_available'] = 'Frühe Wiederbelebung verfügbar',
    ['press_to_respawn'] = 'Drücken Sie %s zum Wiederbeleben',
    ['press_to_call_ems'] = 'Drücken Sie %s zum Anrufen der Rettungsdienste',
    ['calling_ems'] = 'Rettungsdienste werden angerufen...',
    ['ems_called'] = 'Rettungsdienste angerufen!',
    ['ems_cooldown'] = 'Sie müssen warten, bevor Sie erneut anrufen',
    ['voice_blocked'] = 'Sie können nicht sprechen, wenn Sie tot sind',
    ['weapons_removed'] = 'Ihre Waffen wurden entfernt',
    ['revived'] = 'Sie wurden wiederbelebt',
    ['respawned'] = 'Sie haben wiederbelebt',

    
    ['ems_alert_title'] = 'Rettungsdienst Alarm',
    ['ems_alert_description'] = '%s braucht Hilfe!',
    ['ems_alert_location'] = 'Standort: %s',
    ['ems_alert_victim'] = 'Opfer: %s',

    
    ['admin_title'] = 'Next Death',
    ['menu_title'] = 'Hauptmenü',
    ['timers'] = 'Verzögerungen',
    ['early_respawn'] = 'Frühe Wiederbelebung',
    ['early_respawn_desc'] = 'Ermöglicht es Spielern, vor Ablauf des Ausblutungstimers wieder aufzutauchen.',
    ['time_before_early_respawn'] = 'Zeit vor früher Wiederbelebung',
    ['forced_respawn'] = 'Erzwungenes Respawn',
    ['forced_respawn_desc'] = 'Lässt den Spieler automatisch im Krankenhaus wieder auferstehen, wenn der Ausblutungstimer Null erreicht.',
    ['time_before_forced_respawn'] = 'Zeit bis zum erzwungenen Respawn',

    ['options'] = 'Ausrüstung',
    ['remove_weapons_on_respawn'] = 'Waffen beim Respawn entfernen',
    ['remove_weapons_desc'] = 'Entfernt alle Waffen vom Spieler, wenn er respawnt.',
    ['drop_weapon_on_death'] = 'Aktuelle Waffe auf den Boden fallen lassen',
    ['drop_weapon_desc'] = 'Lässt den Spieler seine aktuelle Waffe bei seinem Tod auf den Boden fallen.',

    ['lose_inventory_on_respawn'] = 'Inventar beim Respawn verlieren',
    ['lose_inventory_desc'] = 'Entfernt Gegenstände aus dem Inventar des Spielers beim Respawn. Es wird nichts entfernt, wenn der Spieler im Spiel oder von Admins wiederbelebt wird.',
    ['inventory_whitelist'] = 'Inventar-Whitelist',
    ['inventory_whitelist_desc'] = 'Gegenstände, die NICHT entfernt werden (kommagetrennt).',
    ['save'] = 'SPEICHERN',
    ['saved'] = 'GESPEICHERT',

    ['respawn_location'] = 'Wiederbelebungsort',
    ['respawn_at_location'] = 'Im Krankenhaus wiederbeleben (Solo-Respawn)',
    ['respawn_at_location_desc'] = 'Ermöglicht es dem Spieler, im Krankenhaus wiedergeboren zu werden, wenn dies aktiviert ist und der Timer Null erreicht.',
    ['revive_at_location'] = 'Im Krankenhaus wiederbeleben (Externer Respawn)',
    ['revive_at_location_desc'] = 'Wenn aktiviert, wird ein Spieler, der von einer Drittpartei wiederbelebt wurde, automatisch ins Krankenhaus teleportiert.',
    ['admin_hospital_coords'] = 'Koordinaten',
    ['get_current_position'] = 'Aktuelle Position abrufen',
    ['nearest_respawn_point_enabled'] = 'Multi-Respawn',
    ['nearest_respawn_point_enabled_desc'] = 'Wenn aktiviert, respawnt der Spieler am naechsten benutzerdefinierten Respawn-Punkt.',
    ['custom_respawn_points'] = 'Benutzerdefinierte Respawn-Punkte',
    ['custom_respawn_points_desc'] = 'Alle benutzerdefinierten Punkte werden unten angezeigt und koennen direkt bearbeitet werden.',
    ['add_respawn_point'] = 'Respawn-Punkt hinzufuegen',
    ['respawn_point'] = 'Punkt %s',
    ['remove_respawn_point'] = 'Entfernen',
    ['respawn_point_label'] = 'Bezeichnung',
    ['respawn_point_heading'] = 'Ausrichtung',
    ['hospital_label'] = 'Krankenhaus',


    ['bonus'] = 'Schäden',
    ['damage_indicator_title'] = 'Schadensindikator',
    ['damages_desc'] = 'Konfiguriere die visuellen Effekte (farbige Vignette), die auf dem Bildschirm erscheinen, wenn Spieler Schaden erleiden.',
    ['damage_vignette_enabled'] = 'Schadenseffekte aktivieren',
    ['damage_vignette_opacity'] = 'Schadensdeckkraft',
    ['damage_vignette_color'] = 'Effektfarbe',

    ['configuration'] = 'Konfiguration',
    ['parametres'] = 'Einstellungen',
    ['language'] = 'Sprache',
    ['language_description'] = 'Interface-Sprache.',
    ['found_bug'] = 'Einen Fehler gefunden? Lassen Sie es uns wissen:',
    ['detected_inventory'] = 'Inventar erkannt:',

    
    ['config_saved_successfully'] = 'Konfiguration erfolgreich gespeichert!',
    ['admin_saved'] = 'Konfiguration gespeichert!',
    ['admin_error'] = 'Fehler beim Speichern',
    ['no_inventory_detected'] = 'Keiner erkannt',
    ['notification_death'] = 'Sie sind tot',
    ['notification_bleeding'] = 'Sie bluten - rufen Sie Hilfe!',
    ['notification_ems_called'] = 'Rettungsdienste angerufen!',
    ['notification_ems_cooldown'] = 'Warten Sie, bevor Sie die Rettungsdienste erneut anrufen',
    ['notification_revived'] = 'Sie wurden wiederbelebt',
    ['notification_weapons_removed'] = 'Es sieht so aus, als hättest du deine Sachen verloren',
    ['notification_regained_consciousness'] = 'Sie haben das Bewusstsein wiedererlangt',

    
    ['command_revive'] = 'Einen Spieler wiederbeleben',
    ['command_reload_config'] = 'Konfiguration neu laden',
    ['command_no_permission'] = 'Sie haben keine Berechtigung, diesen Befehl zu verwenden',

    
    ['time_minutes'] = '%d Min',
    ['time_seconds'] = '%d Sek',
    ['time_minutes_seconds'] = '%d Min %d Sek',
    ['error'] = 'Fehler',
    ['invalid_player_id'] = 'Ungültige Spieler-ID',
    ['item_pickup_failed'] = 'Gegenstand konnte nicht aufgehoben werden (Inventar voll?)',
    ['timer_respawn_order_warning'] = 'Die Zeit für den erzwungenen Respawn muss höher sein als die für den frühen Respawn. Wenn Sie es so lassen, werden keine Einstellungen gespeichert.',
    ['success'] = 'Erfolg',
    ['alert'] = 'Alarm',
    ['info'] = 'Info',
    ['notification_title_error'] = 'Fehler',
    ['notification_title_success'] = 'Erfolg',
    ['notification_title_alert'] = 'Alarm',
    ['notification_title_info'] = 'Info',
    ['admin_invalid_player_id'] = 'Ungültige Spieler-ID',
    ['admin_invalid_id'] = 'Ungültige ID',
    ['admin_player_not_found'] = 'Spieler nicht gefunden',
    ['admin_not_dead'] = 'Du bist nicht tot',
    ['admin_kill_target_success'] = 'Du hast %s getötet',
    ['admin_killed_by_admin'] = 'Du wurdest von einem Administrator getötet',
    ['admin_revive_target_success'] = 'Du hast %s wiederbelebt',
    ['admin_revived_by_admin'] = 'Du wurdest von einem Administrator wiederbelebt',
    ['admin_weapon_remove_failed'] = 'Die Waffe konnte nicht aus dem Inventar entfernt werden',
    ['admin_invalid_time'] = 'Ungültige Zeitwerte',
    ['admin_invalid_coords'] = 'Ungültige Koordinaten',
    ['notification_unconscious'] = 'Du bist bewusstlos',
    ['press_e_to_pickup'] = 'Drücke E zum Aufheben',
    ['unknown'] = 'Unbekannt',
    ['unknown_location'] = 'Unbekannter Ort',
    ['admin_db_not_loaded'] = 'Konfigurationsdatenbank nicht geladen. Speichern blockiert.',
}