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

Locales['fr'] = {
    
    ['you_are_dead'] = 'Vous êtes mort',
    ['you_are_unconscious'] = 'VOUS ÊTES INCONSCIENT',
    ['it_will_take_time'] = 'Il faudra du temps avant que vous retrouviez vos forces',
    ['alert_sent_to_ems'] = 'Alerte envoyée aux secours',
    ['call_emergency_services'] = 'Appeler les secours',
    ['respawn'] = 'Se rétablir',
    ['bleeding_out'] = 'Vous saignez',
    ['time_remaining'] = 'Temps restant: %s',
    ['early_respawn_available'] = 'Respawn anticipé disponible',
    ['press_to_respawn'] = 'Appuyez sur %s pour ressusciter',
    ['press_to_call_ems'] = 'Appuyez sur %s pour appeler les secours',
    ['calling_ems'] = 'Appel des secours...',
    ['ems_called'] = 'Secours appelés!',
    ['ems_cooldown'] = 'Vous devez attendre avant de rappeler',
    ['voice_blocked'] = 'Vous ne pouvez pas parler quand vous êtes mort',
    ['weapons_removed'] = 'Vos armes ont été retirées',
    ['revived'] = 'Vous avez été ressuscité',
    ['respawned'] = 'Vous avez respawn',

    
    ['ems_alert_title'] = 'Alerte EMS',
    ['ems_alert_description'] = '%s a besoin d\'aide!',
    ['ems_alert_location'] = 'Localisation: %s',
    ['ems_alert_victim'] = 'Victime: %s',
    ['admin_title'] = 'Next Death',
    ['menu_title'] = 'Menu Principal',
    ['timers'] = 'Délais',
    ['early_respawn'] = 'Respawn Anticipé',
    ['early_respawn_desc'] = 'Permet aux joueurs de réapparaître avant la fin du temps d\'agonie.',
    ['time_before_early_respawn'] = 'Temps avant respawn anticipé',
    ['forced_respawn'] = 'Respawn Forcé',
    ['forced_respawn_desc'] = 'Réapparaît automatiquement le joueur à l\'hôpital lorsque le temps d\'agonie atteint zéro.',
    ['time_before_forced_respawn'] = 'Temps avant respawn forcé',

    ['options'] = 'Equipements',
    ['remove_weapons_on_respawn'] = 'Désarmer au respawn',
    ['remove_weapons_desc'] = 'Supprime toutes les armes du joueur lorsqu\'il réapparaît.',
    ['drop_weapon_on_death'] = 'Lâcher l\'arme au sol',
    ['drop_weapon_desc'] = 'Fait tomber l\'arme actuelle du joueur au sol lors de sa mort.',

    ['lose_inventory_on_respawn'] = 'Perdre inventaire au respawn',
    ['lose_inventory_desc'] = 'Supprime les objets de l\'inventaire du joueur au moment du respawn. Rien n\'est supprimé si le joueur se fait soigner en jeu ou par les admins.',
    ['inventory_whitelist'] = 'Exclusions inventaire',
    ['inventory_whitelist_desc'] = 'Objets qui ne seront PAS supprimés (séparés par des virgules).',
    ['save'] = 'ENREGISTRER',
    ['saved'] = 'ENREGISTRÉ',

    ['respawn_location'] = 'Lieu de Respawn',
    ['respawn_at_location'] = 'Réapparaître à l\'hôpital (Réapparition solo)',
    ['respawn_at_location_desc'] = 'Permet de faire réapparaître le joueur à l’hôpital lorsque l’option est cochée et que le compteur arrive à zéro.',
    ['revive_at_location'] = 'Reapparaitre a l hopital (Reapparition externe)',
    ['revive_at_location_desc'] = 'Lorsque active, un joueur reanime par une tierce personne sera automatiquement teleporte a l hopital.',
    ['admin_hospital_coords'] = 'Coordonnees',
    ['get_current_position'] = 'Obtenir la position actuelle',
    ['nearest_respawn_point_enabled'] = 'Multi respawn',
    ['nearest_respawn_point_enabled_desc'] = 'Si active, le joueur reapparait au point de respawn personnalise le plus proche.',
    ['custom_respawn_points'] = 'Points de respawn personnalises',
    ['custom_respawn_points_desc'] = 'Tous les points personnalises sont affiches ci-dessous et modifiables directement.',
    ['add_respawn_point'] = 'Ajouter un point de respawn',
    ['respawn_point'] = 'Point %s',
    ['remove_respawn_point'] = 'Supprimer',
    ['respawn_point_label'] = 'Label',
    ['respawn_point_heading'] = 'Orientation',
    ['hospital_label'] = 'Hopital',


    ['bonus'] = 'Dégâts',
    ['damage_indicator_title'] = 'Indicateur de dégâts',
    ['damages_desc'] = 'Configure les effets visuels (vignette colorée) qui apparaissent sur l’écran des joueurs lorsqu’ils subissent des dégâts.',
    ['damage_vignette_enabled'] = 'Activer les effets de dégâts',
    ['damage_vignette_opacity'] = 'Opacité des dégâts',
    ['damage_vignette_color'] = 'Couleur de l\'effet',

    ['configuration'] = 'Configuration',
    ['parametres'] = 'Paramètres',
    ['language'] = 'Langue',
    ['language_description'] = 'Langue de l\'interface.',
    ['found_bug'] = 'Vous avez trouvé un bug ? Faites-le nous savoir :',
    ['detected_inventory'] = 'Inventaire détecté :',

    
    ['config_saved_successfully'] = 'Configuration sauvegardée avec succès !',
    ['admin_saved'] = 'Configuration sauvegardée!',
    ['admin_error'] = 'Erreur lors de la sauvegarde',
    ['no_inventory_detected'] = 'Aucun détecté',
    ['notification_death'] = 'Vous êtes mort',
    ['notification_bleeding'] = 'Vous saignez - appelez les secours!',
    ['notification_ems_called'] = 'Secours appelés!',
    ['notification_ems_cooldown'] = 'Attendez avant de rappeler les secours',
    ['notification_revived'] = 'Vous avez été ressuscité',
    ['notification_weapons_removed'] = 'On dirait que vous avez perdu vos affaires',
    ['notification_regained_consciousness'] = 'Vous avez retrouvé vos esprits',

    
    ['command_revive'] = 'Ressusciter un joueur',
    ['command_reload_config'] = 'Recharger la configuration',
    ['command_no_permission'] = 'Vous n\'avez pas la permission d\'utiliser cette commande',

    
    ['time_minutes'] = '%d min',
    ['time_seconds'] = '%d sec',
    ['time_minutes_seconds'] = '%d min %d sec',
    ['error'] = 'Erreur',
    ['success'] = 'Succès',
    ['alert'] = 'Alerte',
    ['info'] = 'Info',
    ['notification_title_error'] = 'Erreur',
    ['notification_title_success'] = 'Succès',
    ['notification_title_alert'] = 'Alerte',
    ['notification_title_info'] = 'Info',
    ['invalid_player_id'] = 'ID invalide',
    ['admin_invalid_player_id'] = 'ID de joueur invalide',
    ['admin_invalid_id'] = 'ID invalide',
    ['admin_player_not_found'] = 'Joueur introuvable',
    ['admin_not_dead'] = 'Vous n\'êtes pas mort',
    ['admin_kill_target_success'] = 'Vous avez tué %s',
    ['admin_killed_by_admin'] = 'Vous avez été tué par un administrateur',
    ['admin_revive_target_success'] = 'Vous avez réanimé %s',
    ['admin_revived_by_admin'] = 'Vous avez été réanimé par un administrateur',
    ['admin_weapon_remove_failed'] = 'Impossible de retirer l\'arme de l\'inventaire',
    ['item_pickup_failed'] = 'Impossible de récupérer l\'objet (inventaire plein ?)',
    ['timer_respawn_order_warning'] = 'Vous devez mettre un délai de respawn forcé plus haut que le respawn anticipé. Si vous laissez comme tel, aucun paramètre ne sera enregistré.',
    ['admin_invalid_time'] = 'Valeurs de temps invalides',
    ['admin_invalid_coords'] = 'Coordonnées invalides',
    ['notification_unconscious'] = 'Vous êtes inconscient',
    ['press_e_to_pickup'] = 'Appuyez sur E pour ramasser',
    ['unknown'] = 'Inconnu',
    ['unknown_location'] = 'Lieu inconnu',
    ['admin_db_not_loaded'] = 'Base de configuration non chargée. Sauvegarde bloquée.',
}
