local MP = minetest.get_modpath("keyring")

keyring = {}

-- mod information
keyring.mod = {version = "0.1.0", author = "Louis Royer"}

dofile(MP.."/meta_fields.lua")
dofile(MP.."/formspec.lua")
dofile(MP.."/craft.lua")
