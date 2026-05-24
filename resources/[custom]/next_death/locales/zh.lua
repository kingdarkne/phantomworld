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

Locales['zh'] = {
    
    ['you_are_dead'] = '您已死亡',
    ['you_are_unconscious'] = '您已失去意识',
    ['it_will_take_time'] = '恢复力量需要一些时间',
    ['alert_sent_to_ems'] = '已向紧急服务发送警报',
    ['call_emergency_services'] = '呼叫紧急服务',
    ['respawn'] = '恢复',
    ['bleeding_out'] = '您正在流血',
    ['time_remaining'] = '剩余时间: %s',
    ['early_respawn_available'] = '提前重生可用',
    ['press_to_respawn'] = '按 %s 重生',
    ['press_to_call_ems'] = '按 %s 呼叫紧急服务',
    ['calling_ems'] = '正在呼叫紧急服务...',
    ['ems_called'] = '已呼叫紧急服务!',
    ['ems_cooldown'] = '您必须等待才能再次呼叫',
    ['voice_blocked'] = '死亡时无法说话',
    ['weapons_removed'] = '您的武器已被移除',
    ['revived'] = '您已复活',
    ['respawned'] = '您已重生',

    
    ['ems_alert_title'] = '紧急服务警报',
    ['ems_alert_description'] = '%s 需要帮助!',
    ['ems_alert_location'] = '位置: %s',
    ['ems_alert_victim'] = '受害者: %s',

    
    ['admin_title'] = 'Next Death',
    ['menu_title'] = '主菜单',
    ['timers'] = '延迟',
    ['early_respawn'] = '提前重生',
    ['early_respawn_desc'] = '允许玩家在流血计时结束前重生。',
    ['time_before_early_respawn'] = '提前重生前的时间',
    ['forced_respawn'] = '强制重生',
    ['forced_respawn_desc'] = '当流血计时到达零时自动在医院重生玩家。',
    ['time_before_forced_respawn'] = '强制重生前的时间',

    ['options'] = '装备',
    ['remove_weapons_on_respawn'] = '重生时剥夺武器',
    ['remove_weapons_desc'] = '当玩家重生时移除其所有武器。',
    ['drop_weapon_on_death'] = '死亡时将当前武器掉落在地上',
    ['drop_weapon_desc'] = '使玩家在死亡时将当前武器掉落在地上。',

    ['lose_inventory_on_respawn'] = '重生时失去物品',
    ['lose_inventory_desc'] = '玩家重生时移除其库存物品。如果玩家在游戏中或由管理员复活，则不会移除任何物品。',
    ['inventory_whitelist'] = '库存白名单',
    ['inventory_whitelist_desc'] = '不会被移除的物品（用逗号分隔）。',
    ['save'] = '保存',
    ['saved'] = '已保存',

    ['respawn_location'] = '重生位置',
    ['respawn_at_location'] = '在医院重生 (个人重生)',
    ['respawn_at_location_desc'] = '启用后，当计时器归零时，允许玩家在医院重生。',
    ['revive_at_location'] = '在医院重生 (外部重生)',
    ['revive_at_location_desc'] = '启用后，被他人救起的玩家会自动传送到医院。',
    ['admin_hospital_coords'] = '坐标',
    ['get_current_position'] = '获取当前位置',
    ['nearest_respawn_point_enabled'] = '多重重生',
    ['nearest_respawn_point_enabled_desc'] = '启用后，玩家会在最近的自定义重生点重生。',
    ['custom_respawn_points'] = '自定义重生点',
    ['custom_respawn_points_desc'] = '所有自定义重生点会显示在下方，并可直接编辑。',
    ['add_respawn_point'] = '添加重生点',
    ['respawn_point'] = '点位 %s',
    ['remove_respawn_point'] = '删除',
    ['respawn_point_label'] = '标签',
    ['respawn_point_heading'] = '朝向',
    ['hospital_label'] = '医院',


    ['bonus'] = '伤害',
    ['damage_indicator_title'] = '伤害指示器',
    ['damages_desc'] = '配置玩家承受伤害时出现在屏幕上的视觉效果（彩色渐变边框）。',
    ['damage_vignette_enabled'] = '启用伤害效果',
    ['damage_vignette_opacity'] = '伤害不透明度',
    ['damage_vignette_color'] = '效果颜色',

    ['configuration'] = '配置',
    ['parametres'] = '参数',
    ['language'] = '语言',
    ['language_description'] = '界面语言。',
    ['found_bug'] = '发现错误？告诉我们:',
    ['detected_inventory'] = '检测到的库存 :',

    
    ['config_saved_successfully'] = '配置已成功保存!',
    ['admin_saved'] = '配置已保存!',
    ['admin_error'] = '保存错误',
    ['no_inventory_detected'] = '未检测到',
    ['notification_death'] = '您已死亡',
    ['notification_bleeding'] = '您正在流血 - 呼叫帮助!',
    ['notification_ems_called'] = '已呼叫紧急服务!',
    ['notification_ems_cooldown'] = '再次呼叫紧急服务前请等待',
    ['notification_revived'] = '您已复活',
    ['notification_weapons_removed'] = '看起来你丢了你的东西',
    ['notification_regained_consciousness'] = '您已恢复意识',

    
    ['command_revive'] = '复活玩家',
    ['command_reload_config'] = '重新加载配置',
    ['command_no_permission'] = '您没有权限使用此命令',

    
    ['time_minutes'] = '%d 分钟',
    ['time_seconds'] = '%d 秒',
    ['time_minutes_seconds'] = '%d 分钟 %d 秒',
    ['error'] = '错误',
    ['invalid_player_id'] = '无效的玩家ID',
    ['item_pickup_failed'] = '物品拾取失败（背包已满？）',
    ['timer_respawn_order_warning'] = '强制重生时间必须高于提前重生时间。若保持当前配置，将不会保存任何参数。',
    ['success'] = '成功',
    ['alert'] = '警报',
    ['info'] = '信息',
    ['notification_title_error'] = '错误',
    ['notification_title_success'] = '成功',
    ['notification_title_alert'] = '警报',
    ['notification_title_info'] = '信息',
    ['admin_invalid_player_id'] = '无效的玩家ID',
    ['admin_invalid_id'] = '无效的ID',
    ['admin_player_not_found'] = '未找到玩家',
    ['admin_not_dead'] = '你没有死亡',
    ['admin_kill_target_success'] = '你击杀了 %s',
    ['admin_killed_by_admin'] = '你被管理员击杀了',
    ['admin_revive_target_success'] = '你复活了 %s',
    ['admin_revived_by_admin'] = '你被管理员复活了',
    ['admin_weapon_remove_failed'] = '无法从背包移除武器',
    ['admin_invalid_time'] = '无效的时间值',
    ['admin_invalid_coords'] = '无效的坐标',
    ['notification_unconscious'] = '你已失去意识',
    ['press_e_to_pickup'] = '按 E 键拾取',
    ['unknown'] = '未知',
    ['unknown_location'] = '未知地点',
    ['admin_db_not_loaded'] = '配置数据库未加载，已阻止保存。',
}