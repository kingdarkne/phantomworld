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

Locales['ja'] = {
    
    ['you_are_dead'] = 'あなたは死亡しています',
    ['you_are_unconscious'] = 'あなたは意識不明です',
    ['it_will_take_time'] = '力を取り戻すまで時間がかかります',
    ['alert_sent_to_ems'] = '救急サービスに警告を送信しました',
    ['call_emergency_services'] = '救急サービスを呼ぶ',
    ['respawn'] = '回復',
    ['bleeding_out'] = '出血しています',
    ['time_remaining'] = '残り時間: %s',
    ['early_respawn_available'] = '早期復活が利用可能',
    ['press_to_respawn'] = '%sを押して復活',
    ['press_to_call_ems'] = '%sを押して救急サービスを呼ぶ',
    ['calling_ems'] = '救急サービスを呼んでいます...',
    ['ems_called'] = '救急サービスを呼びました!',
    ['ems_cooldown'] = '再度呼ぶ前に待つ必要があります',
    ['voice_blocked'] = '死亡している間は話すことができません',
    ['weapons_removed'] = '武器が削除されました',
    ['revived'] = '復活しました',
    ['respawned'] = '復活しました',

    
    ['ems_alert_title'] = '救急サービス警告',
    ['ems_alert_description'] = '%sが助けを必要としています!',
    ['ems_alert_location'] = '場所: %s',
    ['ems_alert_victim'] = '被害者: %s',

    
    ['admin_title'] = 'Next Death',
    ['menu_title'] = 'メインメニュー',
    ['timers'] = '遅延',
    ['early_respawn'] = '早期復活',
    ['early_respawn_desc'] = '出血タイマーが終了する前にプレイヤーがリスポーンできるようにします。',
    ['time_before_early_respawn'] = '早期復活までの時間',
    ['forced_respawn'] = '強制リスポーン',
    ['forced_respawn_desc'] = '出血タイマーがゼロになると、プレイヤーを病院で自動的にリスポーンさせます。',
    ['time_before_forced_respawn'] = '強制リスポーンまでの時間',

    ['options'] = '装備',
    ['remove_weapons_on_respawn'] = 'リスポーン時に武器を没収',
    ['remove_weapons_desc'] = 'リスポーン時にプレイヤーからすべての武器を削除します。',
    ['drop_weapon_on_death'] = '死亡時に現在の武器を地面に落とす',
    ['drop_weapon_desc'] = '死亡時にプレイヤーが現在持っている武器を地面に落とすようにします。',

    ['lose_inventory_on_respawn'] = 'リスポーン時にインベントリを失う',
    ['lose_inventory_desc'] = 'リスポーン時にプレイヤーのインベントリからアイテムを削除します。ゲーム内や管理者が蘇生させた場合は何も削除されません。',
    ['inventory_whitelist'] = 'インベントリ・ホワイトリスト',
    ['inventory_whitelist_desc'] = '削除されないアイテム（カンマ区切り）。',
    ['save'] = '保存',
    ['saved'] = '保存完了',

    ['respawn_location'] = '復活場所',
    ['respawn_at_location'] = '病院でリスポーンする (ソロリスポーン)',
    ['respawn_at_location_desc'] = '有効に設定され、タイマーがゼロになると、プレイヤーが病院でリスポーンできるようになります。',
    ['revive_at_location'] = '病院でリスポーンする (外部リスポーン)',
    ['revive_at_location_desc'] = '有効時、第三者に蘇生されたプレイヤーは自動的に病院へテレポートします。',
    ['admin_hospital_coords'] = '座標',
    ['get_current_position'] = '現在の位置を取得',
    ['nearest_respawn_point_enabled'] = 'マルチリスポーン',
    ['nearest_respawn_point_enabled_desc'] = '有効にすると、プレイヤーは最も近いカスタムリスポーン地点にリスポーンします。',
    ['custom_respawn_points'] = 'カスタムリスポーン地点',
    ['custom_respawn_points_desc'] = 'すべてのカスタム地点は下に表示され、直接編集できます。',
    ['add_respawn_point'] = 'リスポーン地点を追加',
    ['respawn_point'] = '地点 %s',
    ['remove_respawn_point'] = '削除',
    ['respawn_point_label'] = 'ラベル',
    ['respawn_point_heading'] = '向き',
    ['hospital_label'] = '病院',


    ['bonus'] = 'ダメージ',
    ['damage_indicator_title'] = 'ダメージインジケーター',
    ['damages_desc'] = 'プレイヤーがダメージを受けたときに画面に表示される視覚効果（着色されたビネット）を設定します。',
    ['damage_vignette_enabled'] = 'ダメージエフェクトを有効化',
    ['damage_vignette_opacity'] = 'ダメージの不透明度',
    ['damage_vignette_color'] = 'エフェクトの色',

    ['configuration'] = '設定',
    ['parametres'] = 'パラメータ',
    ['language'] = '言語',
    ['language_description'] = 'インターフェース言語。',
    ['found_bug'] = 'バグを見つけましたか？お知らせください:',
    ['detected_inventory'] = '検出されたインベントリ :',

    
    ['config_saved_successfully'] = '設定が正常に保存されました!',
    ['admin_saved'] = '設定を保存しました!',
    ['admin_error'] = '保存エラー',
    ['no_inventory_detected'] = '検出されませんでした',
    ['notification_death'] = 'あなたは死亡しています',
    ['notification_bleeding'] = '出血しています - 助けを呼んでください!',
    ['notification_ems_called'] = '救急サービスを呼びました!',
    ['notification_ems_cooldown'] = '救急サービスを再度呼ぶ前に待ってください',
    ['notification_revived'] = '復活しました',
    ['notification_weapons_removed'] = '持ち物を失ったようです',
    ['notification_regained_consciousness'] = '意識を取り戻しました',

    
    ['command_revive'] = 'プレイヤーを復活させる',
    ['command_reload_config'] = '設定を再読み込み',
    ['command_no_permission'] = 'このコマンドを使用する権限がありません',

    
    ['time_minutes'] = '%d分',
    ['time_seconds'] = '%d秒',
    ['time_minutes_seconds'] = '%d分%d秒',
    ['error'] = 'エラー',
    ['invalid_player_id'] = '無効なプレイヤーID',
    ['item_pickup_failed'] = 'アイテムの取得に失敗しました（インベントリがいっぱいですか？）',
    ['timer_respawn_order_warning'] = '強制リスポーンの時間は早期リスポーンより長く設定する必要があります。このままでは設定は保存されません。',
    ['success'] = '成功',
    ['alert'] = '警告',
    ['info'] = '情報',
    ['notification_title_error'] = 'エラー',
    ['notification_title_success'] = '成功',
    ['notification_title_alert'] = '警告',
    ['notification_title_info'] = '情報',
    ['admin_invalid_player_id'] = '無効なプレイヤーID',
    ['admin_invalid_id'] = '無効なID',
    ['admin_player_not_found'] = 'プレイヤーが見つかりません',
    ['admin_not_dead'] = 'あなたは死んでいません',
    ['admin_kill_target_success'] = '%s を倒しました',
    ['admin_killed_by_admin'] = '管理者に倒されました',
    ['admin_revive_target_success'] = '%s を蘇生しました',
    ['admin_revived_by_admin'] = '管理者に蘇生されました',
    ['admin_weapon_remove_failed'] = 'インベントリから武器を削除できませんでした',
    ['admin_invalid_time'] = '無効な時間設定です',
    ['admin_invalid_coords'] = '無効な座標です',
    ['notification_unconscious'] = 'あなたは意識不明です',
    ['press_e_to_pickup'] = '拾うには E を押してください',
    ['unknown'] = '不明',
    ['unknown_location'] = '不明な場所',
    ['admin_db_not_loaded'] = '設定DBが読み込まれていません。保存はブロックされました。',
}