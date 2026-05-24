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

Locales['ar'] = {
    
    ['you_are_dead'] = 'أنت ميت',
    ['you_are_unconscious'] = 'أنت فاقد للوعي',
    ['it_will_take_time'] = 'سيستغرق الأمر بعض الوقت قبل أن تستعيد قوتك',
    ['alert_sent_to_ems'] = 'تم إرسال تنبيه إلى خدمات الطوارئ',
    ['call_emergency_services'] = 'اتصل بخدمات الطوارئ',
    ['respawn'] = 'التعافي',
    ['bleeding_out'] = 'أنت تنزف',
    ['time_remaining'] = 'الوقت المتبقي: %s',
    ['early_respawn_available'] = 'إعادة الإحياء المبكرة متاحة',
    ['press_to_respawn'] = 'اضغط %s لإعادة الإحياء',
    ['press_to_call_ems'] = 'اضغط %s للاتصال بخدمات الطوارئ',
    ['calling_ems'] = 'جاري الاتصال بخدمات الطوارئ...',
    ['ems_called'] = 'تم استدعاء خدمات الطوارئ!',
    ['ems_cooldown'] = 'يجب عليك الانتظار قبل الاتصال مرة أخرى',
    ['voice_blocked'] = 'لا يمكنك التحدث عندما تكون ميتاً',
    ['weapons_removed'] = 'تم إزالة أسلحتك',
    ['revived'] = 'تم إحياؤك',
    ['respawned'] = 'لقد تم إحياؤك',

    
    ['ems_alert_title'] = 'تنبيه خدمات الطوارئ',
    ['ems_alert_description'] = '%s يحتاج إلى مساعدة!',
    ['ems_alert_location'] = 'الموقع: %s',
    ['ems_alert_victim'] = 'الضحية: %s',

    
    ['admin_title'] = 'Next Death',
    ['menu_title'] = 'القائمة الرئيسية',
    ['timers'] = 'التأخيرات',
    ['early_respawn'] = 'إعادة الإحياء المبكرة',
    ['early_respawn_desc'] = 'يسمح للاعبين بإعادة النشوء قبل انتهاء مؤقت النزيف.',
    ['time_before_early_respawn'] = 'الوقت قبل إعادة الإحياء المبكرة',
    ['forced_respawn'] = 'إعادة التوليد القسري',
    ['forced_respawn_desc'] = 'يؤدي تلقائيا إلى إعادة نشوء اللاعب في المستشفى عندما يصل مؤقت النزيف إلى الصفر.',
    ['time_before_forced_respawn'] = 'الوقت قبل إعادة التوليد القسري',

    ['options'] = 'المعدات',
    ['remove_weapons_on_respawn'] = 'تجريد الأسلحة عند إعادة الإحياء',
    ['remove_weapons_desc'] = 'يزيل جميع أسلحة اللاعب عندما يعاود الظهور.',
    ['drop_weapon_on_death'] = 'إسقاط السلاح الحالي على الأرض',
    ['drop_weapon_desc'] = 'يجعل اللاعب يسقط سلاحه الحالي على الأرض عند الموت.',

    ['lose_inventory_on_respawn'] = 'فقدان المخزون عند إعادة الإحياء',
    ['lose_inventory_desc'] = 'يزيل العناصر من مخزون اللاعب عند إعادة الإحياء. لا يتم إزالة أي شيء إذا تم إنعاش اللاعب داخل اللعبة أو بواسطة المسؤولين.',
    ['inventory_whitelist'] = 'القائمة البيضاء للمخزون',
    ['inventory_whitelist_desc'] = 'العناصر التي لن يتم إزالتها (مفصولة بفاصلة).',
    ['save'] = 'حفظ',
    ['saved'] = 'تم الحفظ',

    ['respawn_location'] = 'موقع إعادة الإحياء',
    ['respawn_at_location'] = 'إعادة النشوء في المستشفى (إعادة نشوء فردي)',
    ['respawn_at_location_desc'] = 'يسمح للاعب بإعادة النشوء في المستشفى عند تفعيل الخيار ووصول المؤقت إلى الصفر.',
    ['revive_at_location'] = 'إعادة الظهور في المستشفى (إعادة ظهور خارجية)',
    ['revive_at_location_desc'] = 'عند التفعيل، اللاعب الذي يتم إنعاشه من طرف آخر سيتم نقله تلقائيا إلى المستشفى.',
    ['admin_hospital_coords'] = 'الإحداثيات',
    ['get_current_position'] = 'الحصول على الموقع الحالي',
    ['nearest_respawn_point_enabled'] = 'إعادة ظهور متعددة',
    ['nearest_respawn_point_enabled_desc'] = 'عند التفعيل، سيظهر اللاعب في أقرب نقطة إعادة ظهور مخصصة.',
    ['custom_respawn_points'] = 'نقاط إعادة الظهور المخصصة',
    ['custom_respawn_points_desc'] = 'جميع النقاط المخصصة تظهر أدناه ويمكن تعديلها مباشرة.',
    ['add_respawn_point'] = 'إضافة نقطة إعادة ظهور',
    ['respawn_point'] = 'نقطة %s',
    ['remove_respawn_point'] = 'حذف',
    ['respawn_point_label'] = 'الاسم',
    ['respawn_point_heading'] = 'الاتجاه',
    ['hospital_label'] = 'المستشفى',


    ['bonus'] = 'الأضرار',
    ['damage_indicator_title'] = 'مؤشر الضرر',
    ['damages_desc'] = 'تكوين المؤثرات البصرية (ظلال ملونة) التي تظهر على الشاشة عند تعرض اللاعبين للضرر.',
    ['damage_vignette_enabled'] = 'تفعيل تأثيرات الضرر',
    ['damage_vignette_opacity'] = 'شفافية الضرر',
    ['damage_vignette_color'] = 'لون التأثير',

    ['configuration'] = 'الإعدادات',
    ['parametres'] = 'المعاملات',
    ['language'] = 'اللغة',
    ['language_description'] = 'لغة الواجهة.',
    ['found_bug'] = 'وجدت خطأ؟ أخبرنا:',
    ['detected_inventory'] = 'تم اكتشاف المخزون :',

    
    ['config_saved_successfully'] = 'تم حفظ الإعدادات بنجاح!',
    ['admin_saved'] = 'تم حفظ الإعدادات!',
    ['admin_error'] = 'خطأ في الحفظ',
    ['no_inventory_detected'] = 'لم يتم اكتشاف أي منها',
    ['notification_death'] = 'أنت ميت',
    ['notification_bleeding'] = 'أنت تنزف - اتصل للمساعدة!',
    ['notification_ems_called'] = 'تم استدعاء خدمات الطوارئ!',
    ['notification_ems_cooldown'] = 'انتظر قبل الاتصال بخدمات الطوارئ مرة أخرى',
    ['notification_revived'] = 'تم إحياؤك',
    ['notification_weapons_removed'] = 'يبدو أنك فقدت ممتلكاتك',
    ['notification_regained_consciousness'] = 'لقد استعدت وعيك',

    
    ['command_revive'] = 'إحياء لاعب',
    ['command_reload_config'] = 'إعادة تحميل الإعدادات',
    ['command_no_permission'] = 'ليس لديك إذن لاستخدام هذا الأمر',

    
    ['time_minutes'] = '%d دقيقة',
    ['time_seconds'] = '%d ثانية',
    ['time_minutes_seconds'] = '%d دقيقة %d ثانية',
    ['error'] = 'خطأ',
    ['invalid_player_id'] = 'معرف لاعب غير صالح',
    ['item_pickup_failed'] = 'فشل التقاط العنصر (المخزون ممتلئ؟)',
    ['timer_respawn_order_warning'] = 'يجب أن يكون وقت إعادة الإحياء الإجباري أعلى من وقت إعادة الإحياء المبكر. إذا تركت الإعدادات هكذا، فلن يتم حفظ أي إعداد.',
    ['success'] = 'نجاح',
    ['alert'] = 'تنبيه',
    ['info'] = 'معلومة',
    ['notification_title_error'] = 'خطأ',
    ['notification_title_success'] = 'نجاح',
    ['notification_title_alert'] = 'تنبيه',
    ['notification_title_info'] = 'معلومة',
    ['admin_invalid_player_id'] = 'معرف لاعب غير صالح',
    ['admin_invalid_id'] = 'معرف غير صالح',
    ['admin_player_not_found'] = 'اللاعب غير موجود',
    ['admin_not_dead'] = 'أنت لست ميتا',
    ['admin_kill_target_success'] = 'لقد قتلت %s',
    ['admin_killed_by_admin'] = 'تم قتلك بواسطة إداري',
    ['admin_revive_target_success'] = 'لقد أنعشت %s',
    ['admin_revived_by_admin'] = 'تم إنعاشك بواسطة إداري',
    ['admin_weapon_remove_failed'] = 'تعذر إزالة السلاح من المخزون',
    ['admin_invalid_time'] = 'قيم وقت غير صالحة',
    ['admin_invalid_coords'] = 'إحداثيات غير صالحة',
    ['notification_unconscious'] = 'أنت فاقد الوعي',
    ['press_e_to_pickup'] = 'اضغط E للالتقاط',
    ['unknown'] = 'غير معروف',
    ['unknown_location'] = 'موقع غير معروف',
    ['admin_db_not_loaded'] = 'لم يتم تحميل قاعدة بيانات الإعدادات. تم منع الحفظ.',
}