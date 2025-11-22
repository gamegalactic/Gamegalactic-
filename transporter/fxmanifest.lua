fx_version 'cerulean'
game 'gta5'

author 'GameGalactic'
description 'Transporter Job (G-core Module)'
version '1.0.3'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua', -- only needed if SQLPersistence = true
    'server.lua'
}

lua54 'yes'
