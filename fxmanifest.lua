--[[ ===================================================== ]] --
--[[          MH Realistic Parking V2 by MaDHouSe79        ]] --
--[[ ===================================================== ]] --
fx_version 'cerulean'
game 'gta5'

author 'MaDHouSe79'
description 'MH Parking V2.'
version '1.0.15'
repository 'https://github.com/MaDHouSe79/mh-parkingV2'

shared_scripts {
	'@ox_lib/init.lua',
	'shared/locale.lua',
	'locales/en.lua',
	'shared/configs/config.lua',
	'shared/configs/vehicles.lua',
	'shared/configs/trailers.lua',
	'shared/functions.lua',
}

client_scripts {
	'core/framework/client.lua',
	'core/functions/client.lua',
	'client/main.lua',
}

server_scripts {
	'@mysql-async/lib/MySQL.lua',
	'core/framework/server.lua',
	'core/functions/server.lua',
	'server/main.lua',
	'server/update.lua',
}

lua54 'yes'
