name "pwd-GARAGEGANG"
author "! ρ α η ∂ α#4470"
version "v1.3.2"
description "Gang Garage Script By Power Development"
fx_version "cerulean"
game "gta5"

client_scripts { 'client.lua', }
server_scripts {  }
shared_scripts {
    '@dr-qbx-compat/shared.lua',
    'config.lua',
    'functions.lua',
}

dependencies {
    'dr-qbx-compat',
    'qbx_core',
}

lua54 'yes'