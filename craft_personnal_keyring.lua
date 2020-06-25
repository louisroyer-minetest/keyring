-- Translation support
local S = minetest.get_translator("keyring")

minetest.register_craftitem("keyring:personnal_keyring", {
	description = S("Personnal Keyring"),
	inventory_image = "keyring_keyring.png",
	-- mimic a key
	groups = {key = 1},
	stack_max = 1,
	on_place = keyring.craft_common.keyring_on_place,

	-- on left click
	on_use = function(itemstack, placer, pointed_thing)
		local pos = pointed_thing.under
		if pos then
			itemstack = keyring.craft_common.select_key(
				itemstack, placer, minetest.get_meta(pos))
		else -- no node pointed
			itemstack = keyring.formspec(itemstack, placer)
		end
		return itemstack
	end,
	on_secondary_use = function(itemstack, placer, pointed_thing)
		return keyring.formspec(itemstack, placer)
	end,
	-- mod doc
	_doc_items_longdesc = S("A personnal keyring to store your keys."),
	_doc_items_usagehelp = S("Left-click on a locked node to select a key, "
		.."then works as a regular key. "
		.."Some nodes support right-clicking to select key and open at once.\n"
		.."Click pointing no node to access key-management interface "
		.."(keys can be renamed or taken off).\n"
		.."Some crafts let you add keys to the keyring."),
})

minetest.register_craft({
	output = "keyring:personnal_keyring",
	recipe = { "keyring:keyring", "basic_materials:padlock" },
	type = shapeless,
})

-- craft to add a key
minetest.register_craft({
	output = "keyring:personnal_keyring",
	recipe = { "keyring:personnal_keyring", "group:key" },
	type = "shapeless",
})
