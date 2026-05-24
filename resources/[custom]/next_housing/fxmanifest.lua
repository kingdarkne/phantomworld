--[[
  ------------------------------------------------------------------------------------------------
    Next Housing - Complete housing system
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
    
    Documentation: https://www.nextcorestudio.com/docs/next-housing/
    Website: https://www.nextcorestudio.com/
    Script Page: https://www.nextcorestudio.com/scripts/next-housing/
    Tebex: https://nextcorestudio.tebex.io/package/7057755

--------------------------------------------------------------------------------------------------
]]
fx_version 'bodacious'
games { 'gta5' }

author 'Nextcore Studio'
description 'Next Housing - Complete housing system'
version '1.8.5'

shared_scripts {
    'core/shared/init.lua',
    'core/shared/state.lua',
    'core/shared/utils.lua',
    'core/shared/framework.lua',
    'core/config.lua',
    'locales/locale.lua',
    'locales/en.lua',
    'locales/fr.lua',
    'locales/es.lua',
    'locales/de.lua',
    'locales/pt.lua',
    'locales/ru.lua',
    'locales/ar.lua',
    'locales/ja.lua',
    'locales/zh.lua',
    'locales/bn.lua',
    'locales/hi.lua',
    'locales/tr.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'core/server/server.lua',
    'core/server/database/manager.lua',
    'core/server/database/modules/shared/settings.lua',
    'core/server/database/modules/shared/shells.lua',
    'core/server/database/modules/shared/houses.lua',
    'core/server/database/modules/shared/keys.lua',
    'core/server/database/modules/shared/players.lua',
    'core/server/database/modules/shared/index.lua',
    'core/server/database/modules/admin/settings.lua',
    'core/server/database/modules/admin/settings_markers.lua',
    'core/server/database/modules/admin/shells.lua',
    'core/server/database/modules/admin/houses.lua',
    'core/server/database/modules/admin/players.lua',
    'core/server/database/modules/admin/index.lua',
    'core/server/database/modules/agency/settings.lua',
    'core/server/database/modules/agency/treasury.lua',
    'core/server/database/modules/agency/houses.lua',
    'core/server/database/modules/agency/contracts.lua',
    'core/server/database/modules/agency/players.lua',
    'core/server/database/modules/agency/index.lua',
    'core/server/database/modules/pap/settings.lua',
    'core/server/database/modules/pap/houses.lua',
    'core/server/database/modules/pap/listings.lua',
    'core/server/database/modules/pap/contracts.lua',
    'core/server/database/modules/pap/keys.lua',
    'core/server/database/modules/pap/players.lua',
    'core/server/database/modules/pap/transactions.lua',
    'core/server/database/modules/pap/index.lua',
    'core/server/database/modules/core/housing.lua',
    'core/server/database/modules/core/garage.lua',
    'core/server/database/modules/core/index.lua',
    'core/server/core/core.lua',
    'core/server/services/permissions.lua',
    'core/server/services/notifications.lua',
    'core/server/services/economy.lua',
    'core/server/features/extended.lua',
    'core/server/features/currency.lua',
    'core/server/features/housing.lua',
    'core/server/features/keys.lua',
    'core/server/features/garage.lua',
    'core/server/features/job.lua',
    'core/server/features/job/core.lua',
    'core/server/features/job/events.lua',
    'core/server/features/job/contracts.lua',
    'core/server/features/job/finance.lua',
    'core/server/features/job/houses.lua',
    'core/server/features/job/automation.lua',
    'core/server/features/job/names.lua',
    'core/server/features/pap.lua',
    'core/server/features/pap/core.lua',
    'core/server/features/pap/listings.lua',
    'core/server/features/pap/offers.lua',
    'core/server/features/pap/messages.lua',
    'core/server/features/pap/media.lua',
    'core/server/features/wardrobe.lua',
    'core/server/handlers/job.lua',
    'core/server/handlers/pap.lua',
    'core/server/handlers/wardrobe.lua',
    'core/server/handlers/settings.lua',
    'core/server/handlers/settings/markers.lua',
    'core/server/handlers/housing.lua',
    'core/server/handlers/garage.lua',
    'core/server/handlers/callbacks.lua',
    'core/server/api.lua',
}

client_scripts {
    'core/client/client.lua',
    'core/client/init.lua',
    'core/client/features/extended.lua',
    'core/client/features/markers/state.lua',
    'core/client/features/markers/blips.lua',
    'core/client/features/markers/sprites.lua',
    'core/client/features/markers/settings.lua',
    'core/client/features/markers/bootstrap.lua',
    'core/client/ui/nui_bridge.lua',
    'core/client/features/shells.lua',
    'core/client/features/stash.lua',
    'core/client/features/wardrobe.lua',
    'core/client/features/housing.lua',
    'core/client/features/keys.lua',
    'core/client/features/garage.lua',
    'core/client/features/job.lua',
    'core/client/features/pap.lua',
    'core/client/handlers/shells.lua',
    'core/client/handlers/stash.lua',
    'core/client/handlers/wardrobe.lua',
    'core/client/handlers/housing.lua',
    'core/client/handlers/keys.lua',
    'core/client/handlers/garage.lua',
    'core/client/handlers/job.lua',
    'core/client/handlers/pap.lua',
    'core/client/handlers/callbacks.lua',
    'core/client/api.lua',
}

exports {
    'TriggerOpenWardrobe',
    'GetApiVersion',
    'IsApiReady',
    'GetContext',
    'GetLocale',
    'GetTranslations',
    'GetMarkerSettings',
    'RequestMarkerSettings',
    'OpenAdminInterface',
    'OpenHousingInterface',
    'OpenJobInterface',
    'OpenPapInterface',
    'OpenWardrobeInterface',
    'OpenGarageInterface',
    'CloseInterface',
    'IsInterfaceOpen',
    'RequestHouseList',
    'RequestHouseById',
    'RequestOwnedHouses',
    'HouseToggleLock',
    'HouseLock',
    'HouseUnlock',
    'HouseBuy',
    'HouseResetMarket',
    'HouseSetOwner',
    'HouseSetPrice',
    'KeysList',
    'KeysGrant',
    'KeysRevoke',
    'GarageListByHouseId',
    'GarageOpenByHouseId',
    'GarageStoreByHouseId',
    'GarageSpawnByHouseId',
    'JobRequestHouses',
    'JobGetHouses',
    'JobGetHouseImages',
    'JobCreateContract',
    'JobUpdateContract',
    'JobSignContract',
    'JobDeclineContract',
    'JobCancelContract',
    'JobUpdateHousePrice',
    'JobBuyHouseForAgency',
    'PapRequestData',
    'PapRequestListings',
    'PapRequestMyListings',
    'PapRequestContracts',
    'PapGetPropertyDetails',
    'PapUpdatePropertyName',
    'PapCreateListing',
    'PapDeleteListing',
    'PapMakeOffer',
    'PapAcceptOffer',
    'PapDeclineOffer',
    'PapCancelOffer',
    'PapSignContract',
    'PapDeclineContract',
    'PapTerminateContract',
    'PapGetContractData',
    'PapGetMessages',
    'PapSendMessage',
}

server_exports {
    'GetApiVersion',
    'IsApiReady',
    'GetHouseById',
    'GetHouses',
    'GetPlayerHouses',
    'PlayerHasAccessToHouse',
    'GetHouseKeys',
    'GetSetting',
    'GetSettings',
    'GetMarkerSettings',
}

ui_page 'core/ui/index.html'

files {
    'core/client/**/*.lua',
    'core/ui/images/*.jpg',
    'core/ui/images/*.webp',
    'core/ui/images/*.svg',
    'core/ui/sounds/*.mp3',
    'core/ui/index.html',
    'core/ui/script.js',
    'core/ui/assets/elements/css/multimodal.css',
    'core/ui/assets/elements/js/multimodal.js',
    'core/ui/assets/elements/js/dropdown.js',
    'core/ui/style.css',
    'core/ui/assets/elements/css/admin.css',
    'core/ui/assets/elements/js/admin.js',
    'core/ui/assets/elements/js/manager.js',
    'core/ui/assets/elements/js/job.js',
    'core/ui/assets/elements/css/job.css',
    'core/ui/assets/elements/js/pap.js',
    'core/ui/assets/elements/css/pap.css',
    'core/ui/assets/elements/js/chat.js',
    'core/ui/assets/elements/css/chat.css',
    'core/ui/assets/elements/css/icons.css',
    'core/ui/assets/elements/js/wardrobe.js',
    'core/ui/assets/elements/css/wardrobe.css',
    'core/ui/assets/elements/js/garage.js',
    'core/ui/assets/elements/css/garage.css',
    'core/config.lua',
}

escrow_ignore {
    'core/config.lua',
    'locales/*.lua',
}

dependency '/assetpacks'