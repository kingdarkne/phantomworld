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

Locales['bn'] = {
    
    ['you_are_dead'] = 'আপনি মারা গেছেন',
    ['you_are_unconscious'] = 'আপনি অচেতন',
    ['it_will_take_time'] = 'আপনার শক্তি ফিরে আসতে কিছু সময় লাগবে',
    ['alert_sent_to_ems'] = 'জরুরি পরিষেবায় সতর্কতা পাঠানো হয়েছে',
    ['call_emergency_services'] = 'জরুরি পরিষেবা কল করুন',
    ['respawn'] = 'সুস্থ হওয়া',
    ['bleeding_out'] = 'আপনি রক্তপাত করছেন',
    ['time_remaining'] = 'অবশিষ্ট সময়: %s',
    ['early_respawn_available'] = 'তাড়াতাড়ি পুনরুজ্জীবন উপলব্ধ',
    ['press_to_respawn'] = 'পুনরুজ্জীবিত করতে %s চাপুন',
    ['press_to_call_ems'] = 'জরুরি পরিষেবা কল করতে %s চাপুন',
    ['calling_ems'] = 'জরুরি পরিষেবা কল করা হচ্ছে...',
    ['ems_called'] = 'জরুরি পরিষেবা কল করা হয়েছে!',
    ['ems_cooldown'] = 'আবার কল করার আগে আপনাকে অপেক্ষা করতে হবে',
    ['voice_blocked'] = 'আপনি মারা গেলে কথা বলতে পারবেন না',
    ['weapons_removed'] = 'আপনার অস্ত্র সরানো হয়েছে',
    ['revived'] = 'আপনাকে পুনরুজ্জীবিত করা হয়েছে',
    ['respawned'] = 'আপনি পুনরুজ্জীবিত হয়েছেন',

    
    ['ems_alert_title'] = 'জরুরি পরিষেবা সতর্কতা',
    ['ems_alert_description'] = '%s সাহায্য প্রয়োজন!',
    ['ems_alert_location'] = 'অবস্থান: %s',
    ['ems_alert_victim'] = 'শিকার: %s',

    
    ['admin_title'] = 'Next Death',
    ['menu_title'] = 'প্রধান মেনu',
    ['timers'] = 'বিলম্ব',
    ['early_respawn'] = 'তাড়াতাড়ি পুনরুজ্জীবন',
    ['early_respawn_desc'] = 'খেলোয়াড়দের পুনর্জন্মের অনুমতি দেয়।',
    ['time_before_early_respawn'] = 'তাড়াতাড়ি পুনরুজ্জীবনের আগে সময়',
    ['forced_respawn'] = 'বাধ্যতামূলক রেসপন',
    ['forced_respawn_desc'] = 'টাইমার শূন্যে পৌঁছালে খেলোয়াড়কে হাসপাতালে পুনর্জন্ম দেয়।',
    ['time_before_forced_respawn'] = 'বাধ্যতামূলক রেসপনের পূর্ববর্তী সময়',

    ['options'] = 'সরঞ্জাম',
    ['remove_weapons_on_respawn'] = 'পুনর্জন্মের সময় অস্ত্র কেড়ে নিন',
    ['remove_weapons_desc'] = 'খেলোয়াড় পুনর্জন্ম নিলে তার সমস্ত অস্ত্র সরিয়ে দেয়।',
    ['drop_weapon_on_death'] = 'মৃত্যুতে বর্তমান অস্ত্র মাটিতে ফেলে দিন',
    ['drop_weapon_desc'] = 'মৃত্যুর সময় খেলোয়াড়কে তার বর্তমান অস্ত্র মাটিতে ফেলে দিতে বাধ্য করে।',

    ['lose_inventory_on_respawn'] = 'রেসপনের সময় ইনভেন্টরি হারান',
    ['lose_inventory_desc'] = 'রেসপনের সময় খেলোয়াড়ের ইনভেন্টরি থেকে আইটেম সরিয়ে দেয়। খেলোয়াড় ইন-গেমে বা অ্যাডমিন দ্বারা পুনরুজ্জীবিত হলে কিছুই সরানো হয় না।',
    ['inventory_whitelist'] = 'ইনভেন্টরি হোয়াইটলিস্ট',
    ['inventory_whitelist_desc'] = 'আইটেম যা সরানো হবে না (কমা দিয়ে আলাদা করা)।',
    ['save'] = 'সংরক্ষণ',
    ['saved'] = 'সংরক্ষিত',

    ['respawn_location'] = 'পুনরুজ্জীবন অবস্থান',
    ['respawn_at_location'] = 'হাসপাতালে পুনর্জন্ম নিন (একক পুনর্জন্ম)',
    ['respawn_at_location_desc'] = 'সক্ষম থাকলে, টাইমার শূন্যে পৌঁছালে খেলোয়াড়কে হাসপাতালে পুনর্জন্ম নেওয়ার অনুমতি দেয়।',
    ['revive_at_location'] = 'হাসপাতালে পুনর্জন্ম (বহিরাগত রিস্পন)',
    ['revive_at_location_desc'] = 'সক্রিয় থাকলে, অন্য খেলোয়াড় দ্বারা রিভাইভ হওয়া খেলোয়াড় স্বয়ংক্রিয়ভাবে হাসপাতালে টেলিপোর্ট হবে।',
    ['admin_hospital_coords'] = 'স্থানাঙ্ক',
    ['get_current_position'] = 'বর্তমান অবস্থান পান',
    ['nearest_respawn_point_enabled'] = 'মাল্টি রিস্পন',
    ['nearest_respawn_point_enabled_desc'] = 'সক্রিয় থাকলে, খেলোয়াড় সবচেয়ে কাছের কাস্টম রিস্পন পয়েন্টে রিস্পন হবে।',
    ['custom_respawn_points'] = 'কাস্টম রিস্পন পয়েন্ট',
    ['custom_respawn_points_desc'] = 'সব কাস্টম পয়েন্ট নিচে দেখানো হয় এবং সরাসরি সম্পাদনা করা যায়।',
    ['add_respawn_point'] = 'রিস্পন পয়েন্ট যোগ করুন',
    ['respawn_point'] = 'পয়েন্ট %s',
    ['remove_respawn_point'] = 'মুছুন',
    ['respawn_point_label'] = 'লেবেল',
    ['respawn_point_heading'] = 'দিক',
    ['hospital_label'] = 'হাসপাতাল',


    ['bonus'] = 'ক্ষয়ক্ষতি',
    ['damage_indicator_title'] = 'ক্ষতি নির্দেশক',
    ['damages_desc'] = 'ভিজ্যুয়াল এফেক্টস কনফিগার করুন।',
    ['damage_vignette_enabled'] = 'ক্ষতি প্রভাব সক্রিয় করুন',
    ['damage_vignette_opacity'] = 'ক্ষতি অস্বচ্ছতা',
    ['damage_vignette_color'] = 'প্রভাব রঙ',

    ['configuration'] = 'কনফিগারেশন',
    ['parametres'] = 'প্যারামিটার',
    ['language'] = 'ভাষা',
    ['language_description'] = 'ইন্টারফেস ভাষা।',
    ['found_bug'] = 'কোনো বাগ খুঁজে পেয়েছেন? আমাদের জানান:',
    ['detected_inventory'] = 'সনাক্ত করা ইনভেন্টরি :',

    
    ['config_saved_successfully'] = 'কনফিগারেশন সফলভাবে সংরক্ষণ করা হয়েছে!',
    ['admin_saved'] = 'কনফিগারেশন সংরক্ষণ করা হয়েছে!',
    ['admin_error'] = 'সংরক্ষণে ত্রুটি',
    ['no_inventory_detected'] = 'কোনটি সনাক্ত করা যায়নি',
    ['notification_death'] = 'আপনি মারা গেছেন',
    ['notification_bleeding'] = 'আপনি রক্তপাত করছেন - সাহায্যের জন্য কল করুন!',
    ['notification_ems_called'] = 'জরুরি পরিষেবা কল করা হয়েছে!',
    ['notification_ems_cooldown'] = 'জরুরি পরিষেবা আবার কল করার আগে অপেক্ষা করুন',
    ['notification_revived'] = 'আপনাকে পুনরুজ্জীবিত করা হয়েছে',
    ['notification_weapons_removed'] = 'মনে হচ্ছে আপনি আপনার জিনিসপত্র হারিয়ে ফেলেছেন',
    ['notification_regained_consciousness'] = 'আপনি সচেতনতা ফিরে পেয়েছেন',

    
    ['command_revive'] = 'একজন খেলোয়াড়কে পুনরুজ্জীবিত করুন',
    ['command_reload_config'] = 'কনফিগারেশন পুনরায় লোড করুন',
    ['command_no_permission'] = 'আপনার এই কমান্ড ব্যবহার করার অনুমতি নেই',

    
    ['time_minutes'] = '%d মিনিট',
    ['time_seconds'] = '%d সেকেন্ড',
    ['time_minutes_seconds'] = '%d মিনিট %d সেকেন্ড',
    ['error'] = 'ত্রুটি',
    ['invalid_player_id'] = 'অবৈধ প্লেয়ার আইডি',
    ['item_pickup_failed'] = 'আইটেম তোলা ব্যর্থ হয়েছে (ইনভেন্টরি কি পূর্ণ?)',
    ['timer_respawn_order_warning'] = 'বাধ্যতামূলক পুনর্জীবন সময়টি আগাম পুনর্জীবন সময়ের চেয়ে বেশি হতে হবে। এভাবে রেখে দিলে কোনো সেটিং সংরক্ষণ করা হবে না।',
    ['success'] = 'সফল',
    ['alert'] = 'সতর্কতা',
    ['info'] = 'তথ্য',
    ['notification_title_error'] = 'ত্রুটি',
    ['notification_title_success'] = 'সফল',
    ['notification_title_alert'] = 'সতর্কতা',
    ['notification_title_info'] = 'তথ্য',
    ['admin_invalid_player_id'] = 'অবৈধ প্লেয়ার আইডি',
    ['admin_invalid_id'] = 'অবৈধ আইডি',
    ['admin_player_not_found'] = 'প্লেয়ার পাওয়া যায়নি',
    ['admin_not_dead'] = 'আপনি মৃত নন',
    ['admin_kill_target_success'] = 'আপনি %s কে হত্যা করেছেন',
    ['admin_killed_by_admin'] = 'আপনাকে একজন অ্যাডমিন হত্যা করেছে',
    ['admin_revive_target_success'] = 'আপনি %s কে পুনরুজ্জীবিত করেছেন',
    ['admin_revived_by_admin'] = 'আপনাকে একজন অ্যাডমিন পুনরুজ্জীবিত করেছে',
    ['admin_weapon_remove_failed'] = 'ইনভেন্টরি থেকে অস্ত্র সরানো যায়নি',
    ['admin_invalid_time'] = 'অবৈধ সময় মান',
    ['admin_invalid_coords'] = 'অবৈধ কোঅর্ডিনেট',
    ['notification_unconscious'] = 'আপনি অচেতন',
    ['press_e_to_pickup'] = 'তুলতে E চাপুন',
    ['unknown'] = 'অজানা',
    ['unknown_location'] = 'অজানা অবস্থান',
    ['admin_db_not_loaded'] = 'কনফিগারেশন ডাটাবেস লোড হয়নি। সেভ ব্লক করা হয়েছে।',
}
