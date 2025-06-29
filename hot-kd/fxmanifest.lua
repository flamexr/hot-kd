fx_version 'cerulean'
game 'gta5'

author 'Flame Santo'
description 'K/D Script'
version '1.0.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/client.lua'
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'server/server.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/target-aim-svgrepo-com.svg',
    'html/death-skull-svgrepo-com.svg'
}
