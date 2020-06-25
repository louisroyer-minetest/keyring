-- Translation support
local S = minetest.get_translator("keyring")

minetest.register_craftitem("keyring:keyring", {
	description = S("Keyring"),
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
	_doc_items_longdesc = S("A keyring to store your keys."),
	_doc_items_usagehelp = S("Left-click on a locked node to select a key, "
		.."then works as a regular key. "
		.."Some nodes support right-clicking to select key and open at once.\n"
		.."Click pointing no node to access key-management interface "
		.."(keys can be renamed or taken off).\n"
		.."Some crafts let you add keys to the keyring."),
})

-- list of wires since there is currently no group:wire in basic_materials
local wires = {
	"basic_materials:gold_wire",
	"basic_materials:copper_wire",
	"basic_materials:steel_wire"
}

for _, wire in pairs(wires) do
	-- craft with wire
	minetest.register_craft({
		output = "keyring:keyring",
		recipe = {
			{ "",   wire,            "" },
			{ wire, "default:key", wire },
			{ "",   wire,            "" },
		},
		replacements = {
			{ wire, "basic_materials:empty_spool" },
			{ wire, "basic_materials:empty_spool" },
			{ wire, "basic_materials:empty_spool" },
			{ wire, "basic_materials:empty_spool" }
		},
	})
	-- craft with 4 group:key
	-- to make the adding of keys in keyring easier (but at a cost)
	minetest.register_craft({
		output = "keyring:keyring",
		recipe = {
			{ "group:key", wire, "group:key" },
			{ wire,        "",          wire },
			{ "group:key", wire, "group:key" },
		},
		replacements = {
			{ wire, "basic_materials:empty_spool" },
			{ wire, "basic_materials:empty_spool" },
			{ wire, "basic_materials:empty_spool" },
			{ wire, "basic_materials:empty_spool" }
		},
	})
end


-- craft to add a key
minetest.register_craft({
	output = "keyring:keyring",
	recipe = { "keyring:keyring", "group:key" },
	type = "shapeless",
})
