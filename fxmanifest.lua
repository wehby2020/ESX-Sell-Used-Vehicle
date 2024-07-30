fx_version 'cerulean'

game 'gta5'

lua54 'yes'

description 'ESX SELL VEHICLES'

version '1.0'

client_scripts {
    "config.lua",
    'locales/en.lua',
    "client/main.lua"
}

server_scripts {
    "@mysql-async/lib/MySQL.lua",
    'locales/en.lua',
    "config.lua",
    "server/main.lua"
}

export 'GeneratePlate'

ui_page {'html/index.html'}

files {'html/index.html','html/js/*.js','html/css/*.css'}
