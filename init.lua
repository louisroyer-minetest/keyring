local MP = minetest.get_modpath("keyring")

keyring = {}

-- mod information
keyring.mod = {version = "1.1.2", author = "Louis Royer"}

-- keyring settings
keyring.settings =
	{
		personal_keyring = minetest.settings:get_bool("keyring.personal_keyring", true),
		dev = {tests = minetest.settings:get_bool("keyring.dev.test", false)}
	}

keyring.log = function(s)
	minetest.log("[keyring] "..s)
end

dofile(MP.."/privileges.lua")
dofile(MP.."/meta_fields.lua")
dofile(MP.."/formspec.lua")
dofile(MP.."/craft_common.lua")
dofile(MP.."/craft_keyring.lua")
if keyring.settings.personal_keyring then
	dofile(MP.."/craft_personal_keyring.lua")
end
if keyring.settings.dev.tests then
	dofile(MP.."/tests.lua")
end
