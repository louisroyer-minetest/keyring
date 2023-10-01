-- Translation support
local S = minetest.get_translator("keyring")

keyring.form.register_allowed("keyring:personal_keyring", {
	remove_key = true,
	rename_key = true,
	set_owner = true,
	share = true,
	title_tab = true,
})

--[[
-- Clear secret if this is a personal keyring with an owner
--]]
function on_drop_personal_keyring(itemstack, dropper, pos)
	local meta = itemstack:get_meta()
	local owner = meta:get_string("owner")
	if owner and owner ~= "" then
		meta:set_string("secret", "")
	end
	return minetest.item_drop(itemstack, dropper, pos)
end
minetest.register_craftitem("keyring:personal_keyring", {
	description = S("Personal Keyring"),
	inventory_image = "keyring_keyring.png",
	-- mimic a key
	groups = {key = 1, key_container = 1},
	stack_max = 1,
	on_place = keyring.craft_common.keyring_on_place,

	-- on left click
	on_use = function(itemstack, placer, pointed_thing)
		local pos = pointed_thing.under
		if pos then
			itemstack = keyring.craft_common.select_key(
				itemstack, placer, minetest.get_meta(pos))
		else -- no node pointed
			itemstack = keyring.form.formspec(itemstack, placer)
		end
		return itemstack
	end,
	on_secondary_use = function(itemstack, placer, pointed_thing)
		if pointed_thing.type == "object" then
			local entity = pointed_thing.ref:get_luaentity()
			if entity then
				itemstack = keyring.craft_common.select_key(
					itemstack, placer, nil, entity)
				if itemstack == nil then
					-- avoid un-necessary calls
					return
				end
				if (not placer:get_player_control().sneak) and entity.key_on_use and
					entity.can_use_key and entity:can_use_key(placer) then
					entity:key_on_use(placer)
				elseif entity.on_rightclick then
					entity:on_rightclick(placer)
				end
			else
				itemstack = keyring.form.formspec(itemstack, placer)
			end
		else
			itemstack = keyring.form.formspec(itemstack, placer)
		end
		return itemstack
	end,
	on_drop = on_drop_personal_keyring,
	-- mod doc
	_doc_items_longdesc = S("A personal keyring to store your keys."),
	_doc_items_usagehelp = S("Left-click on a locked node to select a key, "
		.."then works as a regular key. "
		.."Some nodes support right-clicking to select key and open at once.\n"
		.."Click pointing no node to access key-management interface "
		.."(keys can be renamed or taken off).\n"
		.."Some crafts let you add keys to the keyring."),
})

minetest.register_craft({
	output = "keyring:personal_keyring",
	recipe = { "keyring:keyring", "basic_materials:padlock" },
	type = "shapeless",
})

-- craft to add a key
minetest.register_craft({
	output = "keyring:personal_keyring",
	recipe = { "keyring:personal_keyring", "group:key" },
	type = "shapeless",
})

minetest.register_craft({
	output = "keyring:personal_keyring",
	recipe = { "keyring:personal_keyring", "group:key_container" },
	type = "shapeless",
})


-- reset secret when a non owner take the keyring in inventory
minetest.register_on_player_inventory_action(
	function(player, action, inventory, inventory_info)
		-- guards
		if action ~= "take" and action ~= "put" then
			return
		end
		local player_inv = player:get_inventory()
		if not player_inv:contains_item("main",
			ItemStack("keyring:personal_keyring")) then
			return
		end
		-- resetting
		local player_name = player:get_player_name()
		for pos, item in ipairs(player_inv:get_list("main")) do
			local meta = item:get_meta()
			local owner = meta:get_string("owner")
			local shared = meta:get_string(keyring.fields.shared)
			local shared_with = keyring.fields.utils.shared.is_shared_with(player_name, shared)
			if owner and owner ~= "" and owner ~= player_name
				and not shared_with then
				meta:set_string("secret", "")
			end
			player_inv:set_stack("main", pos, item)
		end
end)
