fx_version 'cerulean'
game 'gta5'
author 'MaDHouSe79'
description 'MH ParkingV2 - A Realistic Vehicle Parking'
version '1.0.0'
repository 'https://github.com/MaDHouSe79/mh-parkingV2'
shared_scripts {'@qb-core/shared/locale.lua', 'locales/en.lua'}
client_scripts {'client/cl_config.lua', 'client/main.lua'}
server_scripts {'@oxmysql/lib/MySQL.lua', 'server/sv_config.lua', 'server/main.lua', 'server/update.lua'}
dependencies {'/onesync', 'oxmysql', 'qb-core', 'qb-vehiclekeys'}
lua54 'yes'