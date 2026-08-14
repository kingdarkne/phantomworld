fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Phantom World'
description 'Premium Cinematic City Tour - Experience Phantom World like never before'
version '1.0.0'

ui_page 'web/build/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/tour_data.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

files {
    'web/build/index.html',
    'web/build/audio/*.mp3',
    'web/build/audio/manifest.json'
}

dependencies {
    'qbx_core',
    'ox_lib'
}

export 'StartCityTour'
export 'StartCityTourPreMultichar'
export 'StopCityTour'
export 'IsTourActive'
