-- Translation support
local S = minetest.get_translator("keyring")
local F = minetest.formspec_escape

keyring.formspec = function(itemstack, player)
	-- TODO: this formspec should allow to list all keys, their names, and number
	-- allow to change a name, and to retrieve a key into the main inventory
	local name = player:get_player_name()
	local formspec = "formspec_version[3]"
		.."size[10.75,11.25]"
		.."label[1,1;"..F(S("List of keys in the keyring")).."]"
		.."label[4,4;NOT IMPLEMENTED]" -- TODO
		.."button_exit[6.7,10;3.6,1;exit;"..F(S("Exit")).."]"
	minetest.show_formspec(name, "keyring:inv", formspec)
	return itemstack
end
