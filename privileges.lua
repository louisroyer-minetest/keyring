-- Translation support
local S = minetest.get_translator("keyring")

minetest.register_privilege("keyring_inspect", {
	description = S("Can list keys of private keyrings owned by other players"),
	give_to_singleplayer = false
})
