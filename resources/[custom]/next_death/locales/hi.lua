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

Locales['hi'] = {
    
    ['you_are_dead'] = 'आप मर चुके हैं',
    ['you_are_unconscious'] = 'आप बेहोश हैं',
    ['it_will_take_time'] = 'आपकी ताकत वापस आने में कुछ समय लगेगा',
    ['alert_sent_to_ems'] = 'आपातकालीन सेवाओं को अलर्ट भेजा गया',
    ['call_emergency_services'] = 'आपातकालीन सेवाएं बुलाएं',
    ['respawn'] = 'ठीक होना',
    ['bleeding_out'] = 'आप खून बहा रहे हैं',
    ['time_remaining'] = 'शेष समय: %s',
    ['early_respawn_available'] = 'जल्दी पुनर्जीवन उपलब्ध',
    ['press_to_respawn'] = 'पुनर्जीवित करने के लिए %s दबाएं',
    ['press_to_call_ems'] = 'आपातकालीन सेवाएं बुलाने के लिए %s दबाएं',
    ['calling_ems'] = 'आपातकालीन सेवाएं बुलाई जा रही हैं...',
    ['ems_called'] = 'आपातकालीन सेवाएं बुलाई गईं!',
    ['ems_cooldown'] = 'आपको फिर से बुलाने से पहले इंतजार करना होगा',
    ['voice_blocked'] = 'जब आप मर चुके हैं तो आप बात नहीं कर सकते',
    ['weapons_removed'] = 'आपके हथियार हटा दिए गए हैं',
    ['revived'] = 'आपको पुनर्जीवित किया गया है',
    ['respawned'] = 'आप पुनर्जीवित हो गए हैं',

    
    ['ems_alert_title'] = 'आपातकालीन सेवा अलर्ट',
    ['ems_alert_description'] = '%s को मदद की जरूरत है!',
    ['ems_alert_location'] = 'स्थान: %s',
    ['ems_alert_victim'] = 'पीड़ित: %s',

    
    ['admin_title'] = 'Next Death',
    ['menu_title'] = 'मुख्य मेनू',
    ['timers'] = 'देरी',
    ['early_respawn'] = 'जल्दी पुनर्जीवन',
    ['early_respawn_desc'] = 'खिलाड़ियों को पुनर्जीवित होने की अनुमति देता है।',
    ['time_before_early_respawn'] = 'जल्दी पुनर्जीवन से पहले का समय',
    ['forced_respawn'] = 'अनिवार्य पुनर्जन्म',
    ['forced_respawn_desc'] = 'टाइमर शून्य होने पर खिलाड़ी को अस्पताल में पुनर्जीवित करता है।',
    ['time_before_forced_respawn'] = 'अनिवार्य पुनर्जन्म से पहले का समय',

    ['options'] = 'उपकरण',
    ['remove_weapons_on_respawn'] = 'पुनर्जन्म पर हथियार छीन लें',
    ['remove_weapons_desc'] = 'खिलाड़ी के पुनर्जीवित होने पर उसके सभी हथियार हटा देता है।',
    ['drop_weapon_on_death'] = 'मौत पर वर्तमान हथियार जमीन पर गिराएं',
    ['drop_weapon_desc'] = 'मृत्यु होने पर खिलाड़ी को अपना वर्तमान हथियार जमीन पर गिराने के लिए मजबूर करता है।',

    ['lose_inventory_on_respawn'] = 'रिस्पॉन पर इन्वेंट्री खोना',
    ['lose_inventory_desc'] = 'रिस्पॉन होने पर खिलाड़ी की इन्वेंट्री से सामान हटा देता है। यदि खिलाड़ी को खेल में या एडमिन द्वारा पुनर्जीवित किया जाता है तो कुछ भी नहीं हटाया जाता है।',
    ['inventory_whitelist'] = 'इन्वेंट्री श्वेतसूची',
    ['inventory_whitelist_desc'] = 'वे वस्तुएं जिन्हें हटाया नहीं जाएगा (कॉमा द्वारा अलग की गई)।',
    ['save'] = 'सहेजें',
    ['saved'] = 'सहेजा गया',

    ['respawn_location'] = 'पुनर्जीवन स्थान',
    ['respawn_at_location'] = 'अस्पताल में पुनर्जीवित हों (सोलो पुनर्जन्म)',
    ['respawn_at_location_desc'] = 'सक्षम होने पर, टाइमर शून्य होने पर खिलाड़ी को अस्पताल में पुनर्जीवित होने की अनुमति देता है।',
    ['revive_at_location'] = 'अस्पताल में पुनर्जीवित करें (बाहरी रिस्पॉन)',
    ['revive_at_location_desc'] = 'सक्रिय होने पर, किसी अन्य खिलाड़ी द्वारा रिवाइव किया गया खिलाड़ी अपने आप अस्पताल टेलीपोर्ट होगा।',
    ['admin_hospital_coords'] = 'निर्देशांक',
    ['get_current_position'] = 'वर्तमान स्थिति प्राप्त करें',
    ['nearest_respawn_point_enabled'] = 'मल्टी रिस्पॉन',
    ['nearest_respawn_point_enabled_desc'] = 'सक्रिय होने पर, खिलाड़ी सबसे नजदीकी कस्टम रिस्पॉन पॉइंट पर रिस्पॉन होगा।',
    ['custom_respawn_points'] = 'कस्टम रिस्पॉन पॉइंट्स',
    ['custom_respawn_points_desc'] = 'सभी कस्टम पॉइंट नीचे दिखते हैं और सीधे एडिट किए जा सकते हैं।',
    ['add_respawn_point'] = 'रिस्पॉन पॉइंट जोड़ें',
    ['respawn_point'] = 'पॉइंट %s',
    ['remove_respawn_point'] = 'हटाएं',
    ['respawn_point_label'] = 'लेबल',
    ['respawn_point_heading'] = 'दिशा',
    ['hospital_label'] = 'अस्पताल',


    ['bonus'] = 'क्षति',
    ['damage_indicator_title'] = 'क्षति संकेतक',
    ['damages_desc'] = 'दृश्य प्रभावों (रंगीन विनेट) को कॉन्फ़िगर करें।',
    ['damage_vignette_enabled'] = 'क्षति प्रभाव सक्षम करें',
    ['damage_vignette_opacity'] = 'क्षति अपारदर्शिता',
    ['damage_vignette_color'] = 'प्रभाव रंग',

    ['configuration'] = 'कॉन्फ़िगरेशन',
    ['parametres'] = 'पैरामीटर',
    ['language'] = 'भाषा',
    ['language_description'] = 'इंटरफ़ेस भाषा।',
    ['found_bug'] = 'कोई बग मिला? हमें बताएं:',
    ['detected_inventory'] = 'पता चला इन्वेंटरी :',

    
    ['config_saved_successfully'] = 'कॉन्फ़िगरेशन सफलतापूर्वक सहेजा गया!',
    ['admin_saved'] = 'कॉन्फ़िगरेशन सहेजा गया!',
    ['admin_error'] = 'सहेजने में त्रुटि',
    ['no_inventory_detected'] = 'किसी का पता नहीं चला',
    ['notification_death'] = 'आप मर चुके हैं',
    ['notification_bleeding'] = 'आप खून बहा रहे हैं - मदद के लिए कॉल करें!',
    ['notification_ems_called'] = 'आपातकालीन सेवाएं बुलाई गईं!',
    ['notification_ems_cooldown'] = 'आपातकालीन सेवाओं को फिर से बुलाने से पहले प्रतीक्षा करें',
    ['notification_revived'] = 'आपको पुनर्जीवित किया गया है',
    ['notification_weapons_removed'] = 'लगता है कि आपने अपना सामान खो दिया है',
    ['notification_regained_consciousness'] = 'आपने होश हासिल कर लिया है',

    
    ['command_revive'] = 'एक खिलाड़ी को पुनर्जीवित करें',
    ['command_reload_config'] = 'कॉन्फ़िगरेशन पुनः लोड करें',
    ['command_no_permission'] = 'आपके पास इस कमांड का उपयोग करने की अनुमति नहीं है',

    
    ['time_minutes'] = '%d मिनट',
    ['time_seconds'] = '%d सेकंड',
    ['time_minutes_seconds'] = '%d मिनट %d सेकंड',
    ['error'] = 'त्रुटि',
    ['invalid_player_id'] = 'अमान्य खिलाड़ी आईडी',
    ['item_pickup_failed'] = 'वस्तु उठाने में विफल (क्या इन्वेंटरी भरा है?)',
    ['timer_respawn_order_warning'] = 'अनिवार्य पुनर्जीवन समय, शीघ्र पुनर्जीवन समय से अधिक होना चाहिए। यदि इसे ऐसे ही छोड़ दिया गया, तो कोई भी सेटिंग सहेजी नहीं जाएगी।',
    ['success'] = 'सफलता',
    ['alert'] = 'चेतावनी',
    ['info'] = 'जानकारी',
    ['notification_title_error'] = 'त्रुटि',
    ['notification_title_success'] = 'सफलता',
    ['notification_title_alert'] = 'चेतावनी',
    ['notification_title_info'] = 'जानकारी',
    ['admin_invalid_player_id'] = 'अमान्य खिलाड़ी आईडी',
    ['admin_invalid_id'] = 'अमान्य आईडी',
    ['admin_player_not_found'] = 'खिलाड़ी नहीं मिला',
    ['admin_not_dead'] = 'आप मरे नहीं हैं',
    ['admin_kill_target_success'] = 'आपने %s को मार दिया',
    ['admin_killed_by_admin'] = 'आपको एक एडमिन ने मार दिया',
    ['admin_revive_target_success'] = 'आपने %s को पुनर्जीवित किया',
    ['admin_revived_by_admin'] = 'आपको एक एडमिन ने पुनर्जीवित किया',
    ['admin_weapon_remove_failed'] = 'इन्वेंटरी से हथियार हटाया नहीं जा सका',
    ['admin_invalid_time'] = 'अमान्य समय मान',
    ['admin_invalid_coords'] = 'अमान्य निर्देशांक',
    ['notification_unconscious'] = 'आप बेहोश हैं',
    ['press_e_to_pickup'] = 'उठाने के लिए E दबाएं',
    ['unknown'] = 'अज्ञात',
    ['unknown_location'] = 'अज्ञात स्थान',
    ['admin_db_not_loaded'] = 'कॉन्फ़िगरेशन डेटाबेस लोड नहीं हुआ। सेव ब्लॉक किया गया।',
}
