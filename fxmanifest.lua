fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'notbad-rockstar-editor'
author 'NotBad'
description 'Rockstar Editor toolkit: recording, action replay, photos, cinematic mode and a clean menu. https://discord.gg/JG49fzm2zF'
version '2.0.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}

shared_scripts {
    'config.lua',
    'locales/*.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}
