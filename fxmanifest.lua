fx_version 'cerulean'
game 'gta5'
author 'MaDHouSe79'
description 'MH ParkingV2 - A Realistic Vehicle Parking System By MaDHouSe79'
version '1.0.1'
repository 'https://github.com/MaDHouSe79/mh-parkingV2'
shared_scripts {'@ox_lib/init.lua', 'shared/locale.lua', 'locales/en.lua', 'shared/config.lua'}
client_scripts {'client/main.lua'}
server_scripts {'@oxmysql/lib/MySQL.lua', 'server/main.lua', 'server/update.lua'}
dependencies {'/onesync', 'oxmysql'}
lua54 'yes'
