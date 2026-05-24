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

Locales['pt'] = {
    
    ['you_are_dead'] = 'Você está morto',
    ['you_are_unconscious'] = 'VOCÊ ESTÁ INCONSCIENTE',
    ['it_will_take_time'] = 'Levará algum tempo antes de você recuperar suas forças',
    ['alert_sent_to_ems'] = 'Alerta enviado para serviços de emergência',
    ['call_emergency_services'] = 'Chamar serviços de emergência',
    ['respawn'] = 'Recuperar',
    ['bleeding_out'] = 'Você está sangrando',
    ['time_remaining'] = 'Tempo restante: %s',
    ['early_respawn_available'] = 'Ressuscitação antecipada disponível',
    ['press_to_respawn'] = 'Pressione %s para ressuscitar',
    ['press_to_call_ems'] = 'Pressione %s para chamar serviços de emergência',
    ['calling_ems'] = 'Chamando serviços de emergência...',
    ['ems_called'] = 'Serviços de emergência chamados!',
    ['ems_cooldown'] = 'Você deve esperar antes de chamar novamente',
    ['voice_blocked'] = 'Você não pode falar quando está morto',
    ['weapons_removed'] = 'Suas armas foram removidas',
    ['revived'] = 'Você foi ressucitado',
    ['respawned'] = 'Você ressuscitou',

    
    ['ems_alert_title'] = 'Alerta de Emergência',
    ['ems_alert_description'] = '%s precisa de ajuda!',
    ['ems_alert_location'] = 'Localização: %s',
    ['ems_alert_victim'] = 'Vítima: %s',

    
    ['admin_title'] = 'Next Death',
    ['menu_title'] = 'Menu Principal',
    ['timers'] = 'Atrasos',
    ['early_respawn'] = 'Ressuscitação Antecipada',
    ['early_respawn_desc'] = 'Permite que os jogadores renasçam antes do fim do temporizador de sangramento.',
    ['time_before_early_respawn'] = 'Tempo antes da ressuscitação antecipada',
    ['forced_respawn'] = 'Ressuscitação Forçada',
    ['forced_respawn_desc'] = 'Renasce automaticamente o jogador no hospital quando o temporizador de sangramento chega a zero.',
    ['time_before_forced_respawn'] = 'Tempo antes da ressuscitação forçada',

    ['options'] = 'Equipamentos',
    ['remove_weapons_on_respawn'] = 'Retirar armas ao renascer',
    ['remove_weapons_desc'] = 'Remove todas as armas do jogador quando ele renasce.',
    ['drop_weapon_on_death'] = 'Soltar arma atual no chão',
    ['drop_weapon_desc'] = 'Faz o jogador deixar cair a sua arma atual no chão ao morrer.',

    ['lose_inventory_on_respawn'] = 'Perder inventário ao renascer',
    ['lose_inventory_desc'] = 'Remove itens do inventário do jogador ao renascer. Nada é removido se o jogador for reanimado no jogo ou por administradores.',
    ['inventory_whitelist'] = 'Lista branca de inventário',
    ['inventory_whitelist_desc'] = 'Itens que NÃO serão removidos (separados por vírgulas).',
    ['save'] = 'SALVAR',
    ['saved'] = 'SALVO',

    ['respawn_location'] = 'Local de Ressuscitação',
    ['respawn_at_location'] = 'Renascer no hospital (Ressuscitamento solo)',
    ['respawn_at_location_desc'] = 'Permite que o jogador renasça no hospital quando ativado e o temporizador chega a zero.',
    ['revive_at_location'] = 'Renascer no hospital (Renascimento externo)',
    ['revive_at_location_desc'] = 'Quando ativado, um jogador reanimado por terceiros sera teleportado automaticamente para o hospital.',
    ['admin_hospital_coords'] = 'Coordenadas',
    ['get_current_position'] = 'Obter posicao atual',
    ['nearest_respawn_point_enabled'] = 'Multi respawn',
    ['nearest_respawn_point_enabled_desc'] = 'Quando ativado, o jogador reaparece no ponto de respawn personalizado mais proximo.',
    ['custom_respawn_points'] = 'Pontos de respawn personalizados',
    ['custom_respawn_points_desc'] = 'Todos os pontos personalizados aparecem abaixo e podem ser editados diretamente.',
    ['add_respawn_point'] = 'Adicionar ponto de respawn',
    ['respawn_point'] = 'Ponto %s',
    ['remove_respawn_point'] = 'Remover',
    ['respawn_point_label'] = 'Rotulo',
    ['respawn_point_heading'] = 'Direcao',
    ['hospital_label'] = 'Hospital',


    ['bonus'] = 'Danos',
    ['damage_indicator_title'] = 'Indicador de danos',
    ['damages_desc'] = 'Configurar os efeitos visuais (vinheta colorida) que aparecem no ecrã quando os jogadores recebem danos.',
    ['damage_vignette_enabled'] = 'Ativar efeitos de dano',
    ['damage_vignette_opacity'] = 'Opacidade do dano',
    ['damage_vignette_color'] = 'Cor do efeito',

    ['configuration'] = 'Configuração',
    ['parametres'] = 'Parâmetros',
    ['language'] = 'Idioma',
    ['language_description'] = 'Idioma da interface.',
    ['found_bug'] = 'Encontrou um bug? Avise-nos:',
    ['detected_inventory'] = 'Inventário detectado :',

    
    ['config_saved_successfully'] = 'Configuração salva com sucesso!',
    ['admin_saved'] = 'Configuração salva!',
    ['admin_error'] = 'Erro ao salvar',
    ['no_inventory_detected'] = 'Nenhum detectado',
    ['notification_death'] = 'Você está morto',
    ['notification_bleeding'] = 'Você está sangrando - chame ajuda!',
    ['notification_ems_called'] = 'Serviços de emergência chamados!',
    ['notification_ems_cooldown'] = 'Aguarde antes de chamar os serviços de emergência novamente',
    ['notification_revived'] = 'Você foi ressuscitado',
    ['notification_weapons_removed'] = 'Parece que você perdeu suas coisas',
    ['notification_regained_consciousness'] = 'Você recuperou a consciência',

    
    ['command_revive'] = 'Ressuscitar um jogador',
    ['command_reload_config'] = 'Recarregar configuração',
    ['command_no_permission'] = 'Você não tem permissão para usar este comando',

    
    ['time_minutes'] = '%d min',
    ['time_seconds'] = '%d seg',
    ['time_minutes_seconds'] = '%d min %d seg',
    ['error'] = 'Erro',
    ['invalid_player_id'] = 'ID de jogador inválido',
    ['item_pickup_failed'] = 'Falha ao recolher o item (inventário cheio?)',
    ['timer_respawn_order_warning'] = 'O tempo de respawn forçado deve ser maior que o tempo de respawn antecipado. Se deixar assim, nenhum parâmetro será salvo.',
    ['success'] = 'Sucesso',
    ['alert'] = 'Alerta',
    ['info'] = 'Informação',
    ['notification_title_error'] = 'Erro',
    ['notification_title_success'] = 'Sucesso',
    ['notification_title_alert'] = 'Alerta',
    ['notification_title_info'] = 'Informação',
    ['admin_invalid_player_id'] = 'ID de jogador inválido',
    ['admin_invalid_id'] = 'ID inválido',
    ['admin_player_not_found'] = 'Jogador não encontrado',
    ['admin_not_dead'] = 'Você não está morto',
    ['admin_kill_target_success'] = 'Você matou %s',
    ['admin_killed_by_admin'] = 'Você foi morto por um administrador',
    ['admin_revive_target_success'] = 'Você reviveu %s',
    ['admin_revived_by_admin'] = 'Você foi revivido por um administrador',
    ['admin_weapon_remove_failed'] = 'Não foi possível remover a arma do inventário',
    ['admin_invalid_time'] = 'Valores de tempo inválidos',
    ['admin_invalid_coords'] = 'Coordenadas inválidas',
    ['notification_unconscious'] = 'Você está inconsciente',
    ['press_e_to_pickup'] = 'Pressione E para pegar',
    ['unknown'] = 'Desconhecido',
    ['unknown_location'] = 'Localização desconhecida',
    ['admin_db_not_loaded'] = 'Banco de dados de configuração não carregado. Salvamento bloqueado.',
}