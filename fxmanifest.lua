fx_version 'cerulean'
game 'gta5'
author 'MaDHouSe79'
description 'MH ParkingV2 - A Realistic Vehicle Parking System'
version '1.0.11'
repository 'https://github.com/MaDHouSe79/mh-parkingV2'
shared_scripts {
    -- '@qbx_core/modules/lib.lua', -- only use this of you use qbx Framework
    '@ox_lib/init.lua',
    'shared/locale.lua',
    'locales/en.lua',
    'shared/functions.lua',
}
client_scripts {
    'core/framework/client.lua',
    'core/functions/client.lua',
    'client/main.lua',
}
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/sv_config.lua',
    'core/framework/server.lua',
    'core/functions/server.lua',
    'server/main.lua',
    'server/update.lua',
}

lua54 'yes'
