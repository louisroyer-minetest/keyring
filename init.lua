local MP = minetest.get_modpath("keyring")

keyring = {}

-- mod information
keyring.mod = {version = "0.1.3", author = "Louis Royer"}

-- keyring settings
keyring.settings =
	{personnal_keyring = minetest.settings:get_bool("keyring.personnal_keyring", true)}

keyring.log = function(s)
	minetest.log("[keyring] "..s)
end

dofile(MP.."/privileges.lua")
dofile(MP.."/meta_fields.lua")
dofile(MP.."/formspec.lua")
dofile(MP.."/craft_common.lua")
dofile(MP.."/craft_keyring.lua")
if keyring.settings.personnal_keyring then
	dofile(MP.."/craft_personnal_keyring.lua")
end
