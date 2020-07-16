-- Translation support
local S = minetest.get_translator("keyring")


keyring.craft_common = {}

--[[ itemstack: the keyring:keyring used
-- placer: the player using the keyring
-- meta: meta of the pointed node
--]]
keyring.craft_common.select_key = function(itemstack, placer, meta)
	local i_meta = itemstack:get_meta()
	local name = placer:get_player_name()
	local keyring_owner = i_meta:get_string("owner")
	local keyring_access = keyring.fields.utils.owner.is_edit_allowed(keyring_owner, name)
	local owner = meta:get_string("owner")
	local secret = meta:get_string("key_lock_secret")
	if (secret == i_meta:get_string("secret") and keyring_access)
		or owner == name or owner == "" then
		-- nothing to do, abort to avoid spamming the chat
		return itemstack
	end
	if not keyring_access then
		keyring.log("action", "Player "..name.." tryed to use personal keyring of "
			..(keyring_owner or "unkwown player"))
		-- resetting immediatly the secret to avoid unallowed uses
		i_meta:set_string("secret", "")
		if placer:get_wielded_item():get_meta():get_string(
			keyring.fields.KRS) == i_meta:get_string(keyring.fields.KRS) then
			placer:set_wielded_item(itemstack)
		end
		minetest.chat_send_player(name, S("You are not allowed to use this keyring."))
		return
	end
	if secret ~= "" and keyring.fields.utils.KRS.in_serialized_keyring(
		itemstack, secret) then
		local u_desc = minetest.deserialize(
			i_meta:get_string(keyring.fields.KRS))[secret].user_description
		minetest.chat_send_player(name, S("Key found in keyring and selected (@1).",
			(u_desc ~= nil and u_desc ~= "") and u_desc or
			minetest.deserialize(i_meta:get_string(keyring.fields.KRS))[secret].description))
		i_meta:set_string("secret", secret)
		-- update immediatly wielded item
		if placer:get_wielded_item():get_meta():get_string(
			keyring.fields.KRS) == i_meta:get_string(keyring.fields.KRS) then
			placer:set_wielded_item(itemstack)
		end
	else
		minetest.chat_send_player(name, S("Key not found in keyring."))
	end
	return itemstack
end


-- copy `on_place` from `default:key`
local key_on_place = ItemStack("default:key"):get_definition().on_place

keyring.craft_common.keyring_on_place = function(itemstack, placer, pointed_thing)
	-- we try to select a key before using it
	local pos = pointed_thing.under
	local is = keyring.craft_common.select_key(itemstack, placer, minetest.get_meta(pos))
	return key_on_place(is, placer, pointed_thing)
end

keyring.craft_common.utils = {}

--[[
-- Returns a table with properties of the craft:
-- consumme_one: if 1 container is consummed
-- consumme_all: if all is consummed
-- is_owned: if at least one item is owned
-- is_craft_forbidden: if the craft is forbidden
-- result_name: name of the craft result
--]]
keyring.craft_common.utils.get_craft_properties = function(old_craft_grid, craft_result,
	player_name)
	local props = {
		consumme_one = true,
		consumme_all = false,
		is_owned = false,
		is_craft_forbidden = false,
		result_name = craft_result
	}
	for position, item in pairs(old_craft_grid) do
		local item_name = item:get_name()
		if props.consumme_one and
			(minetest.get_item_group(item_name, "wire") == 1) then
			-- default -> consumme container
			-- if contains a wire -> never consumme
			props.consumme_one = false
		end
		if (not props.consumme_all) and (item_name == "basic_materials:padlock") then
			props.consumme_all = true
		end
		local owner = item:get_meta():get_string("owner")
		if owner ~= "" then
			if minetest.get_item_group(item_name, "virtual_key") ~= 1 then
				-- ownership of virtual key is checked, but does not determine
				-- the ownership of resulting keyring
				props.is_owned = true
			end
			props.is_craft_forbidden = not keyring.fields.utils.owner.is_edit_allowed(owner,
				player_name)
			if props.is_craft_forbidden then
				return props
			end
		end
	end
	return props
end

--[[
-- Returns a table with properties of the item:
-- is_key_group: true if item is in "group key"
-- is_virtual_group: true if item is in group "virtual key"
-- is_container_group: true if item is in group "key_container"
-- is_owned: true if item is owned
-- name: item name
-- krs: if item is a key container, contains the value of krs
-- shared: if item is a key, contains the value of shared
-- secret: if item is a key but not a container, contains the secret key
-- u_desc: if item is a key but not a container, contains the user description
--]]
keyring.craft_common.utils.get_item_properties = function(item)
	local props = {
		krs = "",
		shared = "",
		secret = "",
		u_desc = "",
	}
	props.name = item:get_name()
	props.is_key_group = (minetest.get_item_group(props.name, "key") == 1)
	props.is_virtual_group = (minetest.get_item_group(props.name, "virtual_key") == 1)
	props.is_container_group = (minetest.get_item_group(props.name, "key_container") == 1)
	local item_meta = item:get_meta()
	props.is_owned = (item_meta:get_string("owner") ~= "")
	if props.is_container_group then
		props.krs = item_meta:get_string(keyring.fields.KRS)
		props.shared = item_meta:get_string(keyring.fields.shared)
	else
		props.secret = item_meta:get_string("secret")
		props.u_desc = item_meta:get_string(keyring.fields.description)
	end
	return props
end

--[[
-- Returns a table with
-- secrets field (krs) to use for the new keyring
-- shared field to use for the new keyring
--
-- and returns nil or the item to put back
--]]
keyring.craft_common.utils.add_to_keyring = function(keyring_props, craft_properties,
		item)
	if keyring_props == nil then
		keyring_props = {
			secrets = {},
			shared = "",
			one_consummed = false,
		}
	end
	local item_props = keyring.craft_common.utils.get_item_properties(item)
	if not (item_props.is_key_group or item_props.is_virtual_group
		or item_props.is_container_group) then
		return keyring_props, nil
	end
	if item_props.krs ~= "" then
		-- extract keyring.fields.KRS if it exists
		for k, v in pairs(minetest.deserialize(item_props.krs) or {}) do
			-- add missing secrets
			if not keyring.fields.utils.KRS.in_keyring(keyring_props.secrets, k) then
				keyring_props.secrets[k] = v
			else
				keyring_props.secrets[k].number = keyring_props.secrets[k].number + v.number
			end
			if v.virtual or item_props.is_virtual_group then
				keyring_props.secrets[k].virtual = true
			end
		end
		-- extract shared field
		if keyring_props.shared ~= "" then
			-- separator
			keyring_props.shared = keyring_props.shared.." "
		end
		keyring_props.shared = keyring_props.shared..item_props.shared
	elseif (item_props.secret ~= "") and not item_props.is_container_group then
		-- else extract secret
		if not keyring.fields.utils.KRS.in_keyring(keyring_props.secrets,
			item_props.secret) then
			keyring_props.secrets[item_props.secret] = {
				number = ((not item_props.is_virtual_group) and 1 or 0),
				description = item:get_description(),
				user_description = (item_props.u_desc ~= "") and item_props.u_desc or nil,
				virtual = item_props.is_virtual_group
			}
		elseif item_props.is_virtual_group then
			keyring_props.secrets[item_props.secret].virtual = true
		else
			keyring_props.secrets[item_props.secret].number = keyring_props
				.secrets[item_props.secret].number + 1
		end
	end
	-- give back unmodified if in group virtual_key
	if item_props.is_virtual_group then
		return keyring_props, item
	end
	-- consumme all if required
	if craft_properties.consumme_all then
		return keyring_props, nil
	end
	-- consumme container if required
	if (not keyring_props.one_consummed) and craft_properties.consumme_one and
		(craft_properties.result_name == item_props.name) and
		(craft_properties.is_owned == item_props.is_owned) then
		keyring_props.one_consummed = true
		return keyring_props, nil
	end
	-- give back other containers
	if item_props.is_container_group then
		-- removes non virtual keys
		local back_krs = {}
		for k, v in pairs(minetest.deserialize(item_props.krs) or {}) do
			if v.virtual then
				back_krs[k] = v
				back_krs.number = 0
			end
		end
		item:get_meta():set_string(keyring.fields.KRS, minetest.serialize(back_krs))
		return keyring_props, item
	end
	return keyring_props, nil
end


-- add key used to craft into keyring
minetest.register_on_craft(function(itemstack, player, old_craft_grid, craft_inv)
	local res_name = itemstack:get_name()
	-- guard
	if (res_name ~= "keyring:keyring") and (res_name ~= "keyring:personal_keyring") then
		return
	end
	local play_name = player:get_player_name()
	local craft_properties = keyring.craft_common.utils.get_craft_properties(old_craft_grid,
		res_name, play_name)
	if craft_properties.is_craft_forbidden then
		keyring.log("action", "Player "..play_name.." used a key container owned by an other"
			.." player in a craft")
		-- put all craft material back
		for p, i in pairs(old_craft_grid) do
			craft_inv:set_stack("craft", p, i)
		end
		-- cancel craft result
		return ItemStack(nil)
	end
	local keyring_properties = nil
	for position, item in pairs(old_craft_grid) do
		local back
		keyring_properties, back = keyring.craft_common.utils.add_to_keyring(keyring_properties,
			craft_properties, item)
		if back ~= nil then
			craft_inv:set_stack("craft", position, back)
		end
	end
	local meta = itemstack:get_meta()
	-- write secrets in keyring.fields.KRS
	meta:set_string(keyring.fields.KRS, minetest.serialize(keyring_properties.secrets))

	-- write shared
	meta:set_string(keyring.fields.shared, keyring_properties.shared)

	if not craft_properties.is_owned then
		return itemstack
	end
	-- write owner
	meta:set_string("description",
		ItemStack("keyring:personal_keyring"):get_description()
		.." ("..S("owned by @1", play_name)..")")
	meta:set_string("owner", play_name)
	return itemstack
end)

-- forbid craft if using and owned personal_keyring
minetest.register_craft_predict(function(itemstack, player, old_craft_grid, craft_inv)
	-- guard
	local res_name = itemstack:get_name()
	if res_name ~= "keyring:personal_keyring" then
		return
	end
	local play_name = player:get_player_name()
	local craft_properties = keyring.craft_common.utils.get_craft_properties(old_craft_grid,
		res_name, play_name)
	if craft_properties.is_craft_forbidden then
		return ItemStack(nil)
	end
	if not craft_properties.is_owned then
		return
	end
	-- showing the right description
	local meta = itemstack:get_meta()
	meta:set_string("description",
		itemstack:get_description().." ("..S("owned by @1", play_name)..")")
	meta:set_string("owner", play_name)
	return itemstack
end)
