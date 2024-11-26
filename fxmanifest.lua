fx_version 'cerulean'
game 'gta5'
author 'MaDHouSe79'
description 'MH ParkingV2 - A Realistic Vehicle Parking'
version '1.0.0'
repository 'https://github.com/MaDHouSe79/mh-parkingV2'
shared_scripts {
    -- '@qbx_core/modules/lib.lua', -- only use this of you use qbx Framework
    '@ox_lib/init.lua',
    'shared/locale.lua',
    'locales/en.lua',
    'shared/config.lua',
}
client_scripts {
    'framework/client/framework.lua',
    'framework/client/functions.lua',
    'client/main.lua',

}
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'framework/server/framework.lua',
    'framework/server/functions.lua',
    'server/main.lua',
    'server/update.lua',
}

dependencies {'oxmysql', 'ox_lib', 'mh-core'}
lua54 'yes'