description 'dr-uipack'
name ' dr-uipack'
author 'dr-uipack'
version 'v1.0.0'



ui_page 'html/index.html'


files {
  'html/index.html',
  'html/*.js',
  'html/*.css',
  'html/*.png',
  'html/*.JPG',
  'html/*.svg',
  'html/*.woff',
  'html/*.otf'

}

shared_scripts {
    '@dr-qbx-compat/shared.lua',
}

dependencies {
    'dr-qbx-compat',
    'qbx_core',
}

client_scripts {
    'client.lua'

}


escrow_ignore {
  'client.lua'
}

exports {
  'Progress',
}





lua54 'yes'

fx_version 'cerulean'
games {'gta5'}
dependency '/assetpacks'