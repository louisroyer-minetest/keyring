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


-- add key used to craft into keyring
minetest.register_on_craft(function(itemstack, player, old_craft_grid, craft_inv)
	local res_name = itemstack:get_name()
	-- guard
	if (res_name ~= "keyring:keyring") and (res_name ~= "keyring:personal_keyring") then
		return
	end
	local play_name = player:get_player_name()
	local secrets = {}
	local is_owned = false
	local shared = ""
	local result_encountered = false
	local key_item_num = 0
	local first_key_item_position = nil
	local contains_lock = false
	for position, item in pairs(old_craft_grid) do
		local item_name = item:get_name()
		local item_meta = item:get_meta()
		local keyring_owner = item:get_meta():get_string("owner")
		local keyring_allowed = keyring.fields.utils.owner.is_edit_allowed(keyring_owner,
			play_name)
		local is_key_group = (minetest.get_item_group(item_name, "key") == 1)
		if (not contains_lock) and item_name == "basic_materials:padlock" then
			contains_lock = true
		end
		-- if item is not in key group, then there is no special handling
		if is_key_group then
			if first_key_item_position == nil then
				first_key_item_position = position
			end
			key_item_num = key_item_num + 1
			if keyring_allowed then
				-- adding data from item to result
				local krs = item_meta:get_string(keyring.fields.KRS)
				if krs ~= "" then
					-- extract keyring.fields.KRS if it exists
					for k, v in pairs(minetest.deserialize(krs) or {}) do
						-- add missing secrets
						if not keyring.fields.utils.KRS.in_keyring(secrets, k) then
							secrets[k] = v
						else
							secrets[k].number = secrets[k].number + v.number
						end
					end
					-- extract shared field
					if shared ~= "" then
						-- separator
						shared = shared.." "
					end
					shared = shared..item_meta:get_string(keyring.fields.shared)
				elseif minetest.get_item_group(item_name, "key_container") ~= 1 then
					-- else extract secret
					local secret = item_meta:get_string("secret")
					if not keyring.fields.utils.KRS.in_keyring(secrets, secret) then
						local u_desc = item_meta:get_string(keyring.fields.description)
						secrets[secret] = {
							number = 1,
							description = item:get_description(),
							user_description = (u_desc ~= "") and u_desc or nil
						}
					else
						secrets[secret].number = secrets[secret].number + 1
					end
				end
				-- give back an empty keyring if it's not the resulting one
				if result_encountered then
					-- give back empty keyring
					if minetest.get_item_group(item_name, "key_container") == 1 then
						local back_item = ItemStack(item_name)
						local bi_meta = back_item:get_meta()
						-- set owner back
						bi_meta:set_string("owner", item_meta:get_string("owner"))
						-- set shared back
						bi_meta:set_string(keyring.fields.shared,
							item_meta:get_string(keyring.fields.shared))
						-- set description back
						bi_meta:set_string("description", item_meta:get_string("description"))
						-- give back
						craft_inv:set_stack("craft", position, back_item)
					end
				elseif item_name == res_name then
					result_encountered = true
				end
				if (not is_owned) and keyring_owner == play_name then
					is_owned = true
				end
			else
				keyring.log("action", "Player "..play_name.." used a key owned by "
					..(keyring_owner or "unknown player").." in a craft")
				-- put all craft material back
				for p, i in pairs(old_craft_grid) do
					craft_inv:set_stack("craft", p, i)
				end
				-- cancel craft result
				return ItemStack(nil)
			end
		end
	end
	-- give back empty containers
	if (not contains_lock) and (key_item_num == 1) and (first_key_item_position ~= nil) then
		local old_item = old_craft_grid[first_key_item_position]
		local old_name = old_item:get_name()
		local old_meta = old_item:get_meta()
		if minetest.get_item_group(old_name, "key_container") == 1 then
			local back_item = ItemStack(old_name)
			local bi_meta = back_item:get_meta()
			-- set owner back
			bi_meta:set_string("owner", old_meta:get_string("owner"))
			-- set shared back
			bi_meta:set_string(keyring.fields.shared,
				old_meta:get_string(keyring.fields.shared))
			-- set description back
			bi_meta:set_string("description", old_meta:get_string("description"))
			-- give back
			craft_inv:set_stack("craft", first_key_item_position, back_item)
		end
	end

	local meta = itemstack:get_meta()
	-- write secrets in keyring.fields.KRS
	meta:set_string(keyring.fields.KRS, minetest.serialize(secrets))

	-- write shared
	meta:set_string(keyring.fields.shared, shared)

	-- write owner
	if ((not contains_lock) and (key_item_num == 1) and (first_key_item_position ~= nil)) or
		(not is_owned) then
		return itemstack
	end
	meta:set_string("description",
		ItemStack("keyring:personal_keyring"):get_description()
		.." "..S("(owned by @1)", play_name))
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
	-- check if craft is allowed and if result would be owned
	local play_name = player:get_player_name()
	local is_owned = false
	for position, item in pairs(old_craft_grid) do
		local keyring_owner = item:get_meta():get_string("owner")
		local keyring_allowed = keyring.fields.utils.owner.is_edit_allowed(keyring_owner,
			play_name)
		local is_group_key = (minetest.get_item_group(item:get_name(), "key") == 1)
		if (not keyring_allowed) and is_group_key then
			return ItemStack(nil)
		elseif (not is_owned) and keyring_owner == play_name and is_group_key then
			is_owned = true
		end
	end
	-- if exit loop then craft is allowed
	if not is_owned then
		return itemstack
	end
	local meta = itemstack:get_meta()
	meta:set_string("description",
		ItemStack("keyring:personal_keyring"):get_description()
		.." "..S("(owned by @1)", play_name))
	meta:set_string("owner", play_name)
	return itemstack
end)
