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

Locales['tr'] = {
    
    ['you_are_dead'] = 'Öldünüz',
    ['you_are_unconscious'] = 'BİLİNÇSİZSİNİZ',
    ['it_will_take_time'] = 'Gücünüzü geri kazanmanız biraz zaman alacak',
    ['alert_sent_to_ems'] = 'Acil servise uyarı gönderildi',
    ['call_emergency_services'] = 'Acil servisi ara',
    ['respawn'] = 'İyileş',
    ['bleeding_out'] = 'Kanıyorsunuz',
    ['time_remaining'] = 'Kalan süre: %s',
    ['early_respawn_available'] = 'Erken yeniden doğuş mevcut',
    ['press_to_respawn'] = 'Yeniden doğmak için %s tuşuna basın',
    ['press_to_call_ems'] = 'Acil servisi aramak için %s tuşuna basın',
    ['calling_ems'] = 'Acil servis aranıyor...',
    ['ems_called'] = 'Acil servis çağrıldı!',
    ['ems_cooldown'] = 'Tekrar aramadan önce beklemeniz gerekir',
    ['voice_blocked'] = 'Öldüğünüzde konuşamazsınız',
    ['weapons_removed'] = 'Silahlarınız kaldırıldı',
    ['revived'] = 'Yeniden canlandırıldınız',
    ['respawned'] = 'Yeniden doğdunuz',

    
    ['ems_alert_title'] = 'Acil Servis Uyarısı',
    ['ems_alert_description'] = '%s yardıma ihtiyaç duyuyor!',
    ['ems_alert_location'] = 'Konum: %s',
    ['ems_alert_victim'] = 'Kurban: %s',

    
    ['admin_title'] = 'Next Death',
    ['menu_title'] = 'Ana Menü',
    ['timers'] = 'Gecikmeler',
    ['early_respawn'] = 'Erken Yeniden Doğuş',
    ['early_respawn_desc'] = 'Oyuncuların kanama süresi bitmeden yeniden doğmasına izin verir.',
    ['time_before_early_respawn'] = 'Erken yeniden doğuştan önceki süre',
    ['forced_respawn'] = 'Zorunlu Canlanma',
    ['forced_respawn_desc'] = 'Kanama süresi sıfıra ulaştığında oyuncuyu otomatik olarak hastanede yeniden doğurur.',
    ['time_before_forced_respawn'] = 'Zorunlu canlanma öncesi süre',

    ['options'] = 'Ekipmanlar',
    ['remove_weapons_on_respawn'] = 'Yeniden doğuşta silahları sil',
    ['remove_weapons_desc'] = 'Oyuncu yeniden doğduğunda tüm silahlarını kaldırır.',
    ['drop_weapon_on_death'] = 'Öldüğünde elindeki silahı yere düşür',
    ['drop_weapon_desc'] = 'Oyuncunun öldüğünde elindeki silahı yere düşürmesini sağlar.',

    ['lose_inventory_on_respawn'] = 'Yeniden doğuşta envanteri kaybet',
    ['lose_inventory_desc'] = 'Yeniden doğuşta oyuncunun envanterindeki eşyaları kaldırır. Oyuncu oyun içinde veya yöneticiler tarafından canlandırılırsa hiçbir şey kaldırılmaz.',
    ['inventory_whitelist'] = 'Envanter Beyaz Listesi',
    ['inventory_whitelist_desc'] = 'Kaldırılmayacak öğeler (virgülle ayrılmış).',
    ['save'] = 'KAYDET',
    ['saved'] = 'KAYDEDİLDİ',

    ['respawn_location'] = 'Yeniden Doğuş Konumu',
    ['respawn_at_location'] = 'Hastanede yeniden doğ (Solo Yeniden Doğuş)',
    ['respawn_at_location_desc'] = 'Etkinleştirildiğinde ve zamanlayıcı sıfıra ulaştığında oyuncunun hastanede yeniden doğmasını sağlar.',
    ['revive_at_location'] = 'Hastanede yeniden dog (Dis yeniden dogus)',
    ['revive_at_location_desc'] = 'Etkin oldugunda, baska bir oyuncu tarafindan canlandirilan oyuncu otomatik olarak hastaneye isinlanir.',
    ['admin_hospital_coords'] = 'Koordinatlar',
    ['get_current_position'] = 'Mevcut konumu al',
    ['nearest_respawn_point_enabled'] = 'Coklu respawn',
    ['nearest_respawn_point_enabled_desc'] = 'Etkinse oyuncu en yakin ozel respawn noktasinda dogar.',
    ['custom_respawn_points'] = 'Ozel respawn noktalari',
    ['custom_respawn_points_desc'] = 'Tum ozel noktalar asagida listelenir ve dogrudan duzenlenebilir.',
    ['add_respawn_point'] = 'Respawn noktasi ekle',
    ['respawn_point'] = 'Nokta %s',
    ['remove_respawn_point'] = 'Kaldir',
    ['respawn_point_label'] = 'Etiket',
    ['respawn_point_heading'] = 'Yon',
    ['hospital_label'] = 'Hastane',


    ['bonus'] = 'Hasarlar',
    ['damage_indicator_title'] = 'Hasar göstergesi',
    ['damages_desc'] = 'Oyuncular hasar aldığında ekranda görünen görsel efektleri (renkli vinyet) yapılandırın.',
    ['damage_vignette_enabled'] = 'Hasar efektlerini etkinleştir',
    ['damage_vignette_opacity'] = 'Hasar opaklığı',
    ['damage_vignette_color'] = 'Efekt rengi',

    ['configuration'] = 'Yapılandırma',
    ['parametres'] = 'Parametreler',
    ['language'] = 'Dil',
    ['language_description'] = 'Arayüz dili.',
    ['found_bug'] = 'Bir hata buldunuz mu? Bize bildirin:',
    ['detected_inventory'] = 'Tespit edilen envanter :',

    
    ['config_saved_successfully'] = 'Yapılandırma başarıyla kaydedildi!',
    ['admin_saved'] = 'Yapılandırma kaydedildi!',
    ['admin_error'] = 'Kaydetme hatası',
    ['no_inventory_detected'] = 'Hiçbiri tespit edilmedi',
    ['notification_death'] = 'Öldünüz',
    ['notification_bleeding'] = 'Kanıyorsunuz - yardım çağırın!',
    ['notification_ems_called'] = 'Acil servis çağrıldı!',
    ['notification_ems_cooldown'] = 'Acil servisi tekrar aramadan önce bekleyin',
    ['notification_revived'] = 'Yeniden canlandırıldınız',
    ['notification_weapons_removed'] = 'Eşyalarınızı kaybetmiş gibi görünüyorsunuz',
    ['notification_regained_consciousness'] = 'Bilinç kazandınız',

    
    ['command_revive'] = 'Bir oyuncuyu canlandır',
    ['command_reload_config'] = 'Yapılandırmayı yeniden yükle',
    ['command_no_permission'] = 'Bu komutu kullanma izniniz yok',

    
    ['time_minutes'] = '%d dak',
    ['time_seconds'] = '%d sn',
    ['time_minutes_seconds'] = '%d dak %d sn',
    ['error'] = 'Hata',
    ['invalid_player_id'] = 'Geçersiz Oyuncu ID\'si',
    ['item_pickup_failed'] = 'Eşya toplama başarısız oldu (envanter dolu mu?)',
    ['timer_respawn_order_warning'] = 'Zorunlu respawn süresi, erken respawn süresinden daha yüksek olmalıdır. Bu şekilde bırakırsanız hiçbir ayar kaydedilmez.',
    ['success'] = 'Başarı',
    ['alert'] = 'Uyarı',
    ['info'] = 'Bilgi',
    ['notification_title_error'] = 'Hata',
    ['notification_title_success'] = 'Başarı',
    ['notification_title_alert'] = 'Uyarı',
    ['notification_title_info'] = 'Bilgi',
    ['admin_invalid_player_id'] = 'Geçersiz oyuncu ID',
    ['admin_invalid_id'] = 'Geçersiz ID',
    ['admin_player_not_found'] = 'Oyuncu bulunamadı',
    ['admin_not_dead'] = 'Ölü değilsiniz',
    ['admin_kill_target_success'] = '%s oyuncusunu öldürdünüz',
    ['admin_killed_by_admin'] = 'Bir yönetici tarafından öldürüldünüz',
    ['admin_revive_target_success'] = '%s oyuncusunu canlandırdınız',
    ['admin_revived_by_admin'] = 'Bir yönetici tarafından canlandırıldınız',
    ['admin_weapon_remove_failed'] = 'Silah envanterden kaldırılamadı',
    ['admin_invalid_time'] = 'Geçersiz süre değerleri',
    ['admin_invalid_coords'] = 'Geçersiz koordinatlar',
    ['notification_unconscious'] = 'Bilinciniz kapalı',
    ['press_e_to_pickup'] = 'Almak için E tuşuna bas',
    ['unknown'] = 'Bilinmiyor',
    ['unknown_location'] = 'Bilinmeyen konum',
    ['admin_db_not_loaded'] = 'Yapılandırma veritabanı yüklenmedi. Kaydetme engellendi.',
}