fx_version 'cerulean'
game 'gta5'
lua54 "yes"
author 'Akkariin'
description 'A hologram speedometer script for FiveM'
url 'https://www.zerodream.net/'
version '1.0.3'

files {
	-- 'data/handling.meta',
	-- 'data/vehicles.meta',
	-- 'data/carvariations.meta',
	'ui/**/*.*',
	'ui/*.*'
}

client_script 'client.lua'
server_scripts{
	'@oxmysql/lib/MySQL.lua',
	'server.lua'
} 

shared_scripts {
	'@ox_lib/init.lua',
  }
-- data_file 'HANDLING_FILE' 'data/handling.meta'
-- data_file 'VEHICLE_METADATA_FILE' 'data/vehicles.meta'
-- data_file 'VEHICLE_VARIATION_FILE' 'data/carvariations.meta'

export 'ToggleDisplay'
