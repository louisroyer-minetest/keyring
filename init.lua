local MP = minetest.get_modpath("keyring")

keyring = {}

-- mod information
keyring.mod = {version = "0.1.0", author = "Louis Royer"}

keyring.log = function(s)
	minetest.log("[keyring] "..s)
end


dofile(MP.."/register.lua")
