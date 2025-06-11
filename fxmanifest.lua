fx_version 'cerulean'
game 'gta5'
description 'Azure Framework Level System (RP)'
version '1.0.0'

client_scripts {
  'client_ui.lua',
  'client_leveling.lua',
}
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

ui_page 'ui/index.html'
files {
  'ui/index.html',
}