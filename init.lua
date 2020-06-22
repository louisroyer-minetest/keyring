local MP = minetest.get_modpath("keyring")

keyring = {}

-- mod information
keyring.mod = {version = "0.1.1", author = "Louis Royer"}

keyring.log = function(s)
	minetest.log("[keyring] "..s)
end

dofile(MP.."/meta_fields.lua")
dofile(MP.."/formspec.lua")
dofile(MP.."/craft.lua")