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
	local keyring_access = (keyring_owner == nil)
		or (keyring_owner == name) or (keyring_owner == "")
	local owner = meta:get_string("owner")
	local secret = meta:get_string("key_lock_secret")
	if (secret == i_meta:get_string("secret") and keyring_access)
		or owner == name or owner == "" then
		-- nothing to do, abort to avoid spamming the chat
		return itemstack
	end
	if not keyring_access then
		keyring.log(name.." try to use personnal keyring of "
			..(keyring_owner or "unkwown player"))
		-- resetting immediatly the secret to avoid unallowed uses
		i_meta:set_string("secret", "")
		if placer:get_wielded_item():get_meta():get_string(
			keyring.fields.KRS) == i_meta:get_string(keyring.fields.KRS) then
			placer:set_wielded_item(itemstack)
		end
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
	local play_name = player:get_player_name()
	if (res_name == "keyring:keyring") or (res_name == "keyring:personnal_keyring") then
		local secrets = {}
		for position, item in pairs(old_craft_grid) do
			local item_name = item:get_name()
			local keyring_owner = item:get_meta():get_string("owner")
			local keyring_allowed = (keyring_owner == nil)
				or (keyring_owner == play_name)
				or (keyring_owner == "")
			-- check item is of group key
			local groups = item:get_definition().groups
			if keyring_allowed and groups and groups.key == 1 then
				local krs = item:get_meta():get_string(keyring.fields.KRS)
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
				elseif item_name ~= "keyring:keyring" and
					item_name ~= "keyring:personnal_keyring" then
					-- else extract secret
					local secret = item:get_meta():get_string("secret")
					if not keyring.fields.utils.KRS.in_keyring(secrets, secret) then
						local u_desc = item:get_meta():get_string(keyring.fields.description)
						secrets[secret] = {
							number = 1,
							description = item:get_description(),
							user_description = (u_desc ~= "") and u_desc or nil
						}
					else
						secrets[secret].number = secrets[secret].number + 1
					end
				end
			elseif item_name == "keyring:personnal_keyring" and not keyring_allowed then
				keyring.log(play_name.." used a personnal keyring owned by "
					..(keyring_owner or "unknown player").." in a craft")
					-- give it back
					craft_inv:set_stack("craft", position, item)
			end
		end
		local meta = itemstack:get_meta()
		-- write secrets in keyring.fields.KRS
		meta:set_string(keyring.fields.KRS, minetest.serialize(secrets))

		-- write owner
		if res_name == "keyring:personnal_keyring" then
			local is_owned = false
			for position, item in pairs(old_craft_grid) do
				local keyring_owner = item:get_meta():get_string("owner")
				local keyring_allowed = (keyring_owner == nil)
					or (keyring_owner == play_name)
					or (keyring_owner == "")
				local groups = item:get_definition().groups
				if (not keyring_allowed) and groups and groups.key == 1 then
					-- put all craft material back
					for position, item in pairs(old_craft_grid) do
						craft_inv:set_stack("craft", position, item)
					end
					-- cancel craft result
					return ItemStack(nil)
				elseif (not is_owned) and keyring_owner == play_name
					and groups and groups.key == 1 then
					is_owned = true
				end

			end
			-- if exit loop then craft is allowed
			if is_owned then
				meta:set_string("description",
					ItemStack("keyring:personnal_keyring"):get_description()
					.." "..S("(owned by @1)", play_name))
				meta:set_string("owner", play_name)
			end
		end
		return itemstack
	end
end)

-- forbid craft if using and owned personnal_keyring
minetest.register_craft_predict(function(itemstack, player, old_craft_grid, craft_inv)
	local res_name = itemstack:get_name()
	local play_name = player:get_player_name()
	if res_name == "keyring:personnal_keyring" then
		local is_owned = false
		for position, item in pairs(old_craft_grid) do
			local keyring_owner = item:get_meta():get_string("owner")
			local keyring_allowed = (keyring_owner == nil)
				or (keyring_owner == play_name)
				or (keyring_owner == "")
			local groups = item:get_definition().groups
			if (not keyring_allowed) and groups and groups.key == 1 then
				return ItemStack(nil)
			elseif (not is_owned) and keyring_owner == play_name
				and groups and groups.key == 1 then
				is_owned = true
			end
		end
		-- if exit loop then craft is allowed
		if is_owned then
			local meta = itemstack:get_meta()
			meta:set_string("description",
				ItemStack("keyring:personnal_keyring"):get_description()
				.." "..S("(owned by @1)", play_name))
			meta:set_string("owner", play_name)
		end
		return itemstack
	end
end)
