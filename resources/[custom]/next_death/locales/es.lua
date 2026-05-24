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

Locales['es'] = {
    
    ['you_are_dead'] = 'Estás muerto',
    ['you_are_unconscious'] = 'ESTÁS INCONSCIENTE',
    ['it_will_take_time'] = 'Tomará tiempo antes de que recuperes tus fuerzas',
    ['alert_sent_to_ems'] = 'Alerta enviada a emergencias',
    ['call_emergency_services'] = 'Llamar a emergencias',
    ['respawn'] = 'Recuperarse',
    ['bleeding_out'] = 'Te estás desangrando',
    ['time_remaining'] = 'Tiempo restante: %s',
    ['early_respawn_available'] = 'Respawn temprano disponible',
    ['press_to_respawn'] = 'Presiona %s para revivir',
    ['press_to_call_ems'] = 'Presiona %s para llamar a emergencias',
    ['calling_ems'] = 'Llamando a emergencias...',
    ['ems_called'] = '¡Emergencias llamadas!',
    ['ems_cooldown'] = 'Debes esperar antes de llamar de nuevo',
    ['voice_blocked'] = 'No puedes hablar cuando estás muerto',
    ['weapons_removed'] = 'Tus armas han sido removidas',
    ['revived'] = 'Has sido revivido',
    ['respawned'] = 'Has revivido',

    
    ['ems_alert_title'] = 'Alerta EMS',
    ['ems_alert_description'] = '¡%s necesita ayuda!',
    ['ems_alert_location'] = 'Ubicación: %s',
    ['ems_alert_victim'] = 'Víctima: %s',

    
    ['admin_title'] = 'Next Death',
    ['menu_title'] = 'Menú Principal',
    ['timers'] = 'Retrasos',
    ['early_respawn'] = 'Respawn Temprano',
    ['early_respawn_desc'] = 'Permite a los jugadores reaparecer antes de que termine el temporizador de agonía.',
    ['time_before_early_respawn'] = 'Tiempo antes del respawn temprano',
    ['forced_respawn'] = 'Reaparición Forzada',
    ['forced_respawn_desc'] = 'Reaparece automáticamente al jugador en el hospital cuando el temporizador de agonía llega a cero.',
    ['time_before_forced_respawn'] = 'Tiempo antes de reaparición forzada',

    ['options'] = 'Equipamiento',
    ['remove_weapons_on_respawn'] = 'Quitar armas al reaparecer',
    ['remove_weapons_desc'] = 'Elimina todas las armas del jugador cuando reaparece.',
    ['drop_weapon_on_death'] = 'Soltar arma actual al suelo',
    ['drop_weapon_desc'] = 'Hace que el jugador suelte su arma actual al suelo al morir.',

    ['lose_inventory_on_respawn'] = 'Perder inventario al reaparecer',
    ['lose_inventory_desc'] = 'Elimina los objetos del inventario del jugador al reaparecer. No se elimina nada si el jugador es reanimado en el juego o por los administradores.',
    ['inventory_whitelist'] = 'Lista blanca de inventario',
    ['inventory_whitelist_desc'] = 'Objetos que NO serán eliminados (separados por comas).' ,
    ['save'] = 'GUARDAR',
    ['saved'] = 'GUARDADO',

    ['respawn_location'] = 'Ubicación de Respawn',
    ['respawn_at_location'] = 'Reaparecer en el hospital (Reaparición solo)',
    ['respawn_at_location_desc'] = 'Permite que el jugador reaparezca en el hospital cuando está activado y el temporizador llega a cero.',
    ['revive_at_location'] = 'Reaparecer en el hospital (Reaparicion externa)',
    ['revive_at_location_desc'] = 'Cuando esta activado, un jugador reanimado por un tercero sera teletransportado automaticamente al hospital.',
    ['admin_hospital_coords'] = 'Coordenadas',
    ['get_current_position'] = 'Obtener posicion actual',
    ['nearest_respawn_point_enabled'] = 'Multi respawn',
    ['nearest_respawn_point_enabled_desc'] = 'Si esta activado, el jugador reaparece en el punto de respawn personalizado mas cercano.',
    ['custom_respawn_points'] = 'Puntos de respawn personalizados',
    ['custom_respawn_points_desc'] = 'Todos los puntos personalizados se muestran abajo y se pueden editar directamente.',
    ['add_respawn_point'] = 'Agregar punto de respawn',
    ['respawn_point'] = 'Punto %s',
    ['remove_respawn_point'] = 'Eliminar',
    ['respawn_point_label'] = 'Etiqueta',
    ['respawn_point_heading'] = 'Orientacion',
    ['hospital_label'] = 'Hospital',


    ['bonus'] = 'Daños',
    ['damage_indicator_title'] = 'Indicador de daños',
    ['damages_desc'] = 'Configura los efectos visuales (viñeta de color) que aparecen en la pantalla cuando los jugadores reciben daño.',
    ['damage_vignette_enabled'] = 'Activar efectos de daño',
    ['damage_vignette_opacity'] = 'Opacidad del daño',
    ['damage_vignette_color'] = 'Color del efecto',

    ['configuration'] = 'Configuración',
    ['parametres'] = 'Parámetros',
    ['language'] = 'Idioma',
    ['language_description'] = 'Idioma de la interfaz.',
    ['found_bug'] = '¿Encontraste un error? Háznoslo saber:',
    ['detected_inventory'] = 'Inventario detectado :',

    
    ['config_saved_successfully'] = '¡Configuración guardada exitosamente!',
    ['admin_saved'] = '¡Configuración guardada!',
    ['admin_error'] = 'Error al guardar la configuración',
    ['no_inventory_detected'] = 'Ninguno detectado',
    ['notification_death'] = 'Estás muerto',
    ['notification_bleeding'] = 'Te estás desangrando - ¡llama a emergencias!',
    ['notification_ems_called'] = '¡Emergencias llamadas!',
    ['notification_ems_cooldown'] = 'Espera antes de llamar a emergencias de nuevo',
    ['notification_revived'] = 'Has sido revivido',
    ['notification_weapons_removed'] = 'Parece que has perdido tus cosas',
    ['notification_regained_consciousness'] = 'Has recuperado la conciencia',

    
    ['command_revive'] = 'Revivir un jugador',
    ['command_reload_config'] = 'Recargar configuración',
    ['command_no_permission'] = 'No tienes permiso para usar este comando',

    
    ['time_minutes'] = '%d min',
    ['time_seconds'] = '%d seg',
    ['time_minutes_seconds'] = '%d min %d seg',
    ['error'] = 'Error',
    ['invalid_player_id'] = 'ID de jugador inválida',
    ['item_pickup_failed'] = 'Error al recoger el objeto (¿inventario lleno?)',
    ['timer_respawn_order_warning'] = 'El tiempo de respawn forzado debe ser mayor que el tiempo de respawn anticipado. Si lo deja así, no se guardará ningún parámetro.',
    ['success'] = 'Éxito',
    ['alert'] = 'Alerta',
    ['info'] = 'Información',
    ['notification_title_error'] = 'Error',
    ['notification_title_success'] = 'Éxito',
    ['notification_title_alert'] = 'Alerta',
    ['notification_title_info'] = 'Información',
    ['admin_invalid_player_id'] = 'ID de jugador inválido',
    ['admin_invalid_id'] = 'ID inválido',
    ['admin_player_not_found'] = 'Jugador no encontrado',
    ['admin_not_dead'] = 'No estás muerto',
    ['admin_kill_target_success'] = 'Has matado a %s',
    ['admin_killed_by_admin'] = 'Has sido asesinado por un administrador',
    ['admin_revive_target_success'] = 'Has reanimado a %s',
    ['admin_revived_by_admin'] = 'Has sido reanimado por un administrador',
    ['admin_weapon_remove_failed'] = 'No se pudo retirar el arma del inventario',
    ['admin_invalid_time'] = 'Valores de tiempo inválidos',
    ['admin_invalid_coords'] = 'Coordenadas inválidas',
    ['notification_unconscious'] = 'Estás inconsciente',
    ['press_e_to_pickup'] = 'Pulsa E para recoger',
    ['unknown'] = 'Desconocido',
    ['unknown_location'] = 'Ubicación desconocida',
    ['admin_db_not_loaded'] = 'La base de datos de configuración no se cargó. Guardado bloqueado.',
}
