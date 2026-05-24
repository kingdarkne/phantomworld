
fx_version "cerulean"

games { "gta5" }
version "0.1.0"


loadscreen 'nui/dist/index.html'
loadscreen_manual_shutdown "yes"
loadscreen_cursor 'yes'

files {
    "nui/dist/**/*",
    'html/assets/music.mp3',
}

server_scripts { "build/sv_*.js" }
client_scripts { "build/cl_*.js" }
