-- Translation support
local S = minetest.get_translator("keyring")
local F = minetest.formspec_escape

-- context
local context = {}
local selected = {}
local key_list = {}
minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	context[name] = nil
	selected[name] = nil
	key_list[name] = nil
end)


minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname == "keyring:edit" then
		local name = player:get_player_name()
		-- clean context
		if fields.quit and not fields.key_enter then
			context[name] = nil
			selected[name] = nil
			key_list[name] = nil
			return
		end

		-- check abuses
		local item = player:get_wielded_item()
		local meta = item:get_meta()
		if item:get_name() ~= "keyring:keyring"
			and item:get_name() ~= "keyring:personnal_keyring" then
			keyring.log("Player "..name..
				" sent a keyring action but has no keyring in hand.")
			return
		end
		local krs = meta:get_string(keyring.fields.KRS)
		if krs ~= context[name] then
			keyring.log("Player "..name
				.." sent a keyring action but has not the right keyring in hand.")
			return
		end

		local keyring_owner = meta:get_string("owner")
		local keyring_allowed = (keyring_owner == nil)
			or (keyring_owner == name) or (keyring_owner == "")
		if not keyring_allowed then
			if not minetest.check_player_privs(name, { keyring_inspect=true }) then
				keyring.log(player:get_player_name()
					.." sent command to manage keys of a keyring owned by "
					..(keyring_owner or "unknown player"))
			end
			return
		end

		-- make owner
		if fields.make_private ~= nil then
			if fields.make_private == "true" then
				meta:set_string("owner", name)
				meta:set_string("description",
					ItemStack("keyring:personnal_keyring"):get_description()
					.." "..S("(owned by @1)", name))
			elseif fields.make_private == "false" then
				meta:set_string("owner", "")
				meta:set_string("description",
					ItemStack("keyring:personnal_keyring"):get_description())
			end
			player:set_wielded_item(item)
			keyring.formspec(item, minetest.get_player_by_name(name))
		end

		-- key selection
		if fields.selected_key ~= nil then
			local event = minetest.explode_textlist_event(fields.selected_key)
			if event.type ~= "INV" then
				if key_list[name] == nil or event.index > #key_list[name] then
					keyring.log("Player "..name
						.." selected a key in keyring interface"
						.." but this key does not exist.")
					return
				end
				selected[name] = event.index
			end
		end

		if selected[name] then
			-- no name provided for renaming
			if (fields.rename or (fields.key_enter and fields.key_enter_field
				and fields.key_enter_field == "new_name"))
				and ((not fields.new_name) or fields.new_name == "") then
				minetest.chat_send_player(name, S("You must enter a name first."))
				return
			end
			-- add user description
			if (fields.rename or (fields.key_enter and fields.key_enter_field
				and fields.key_enter_field == "new_name"))
				and key_list[name] and selected[name] and selected[name] <= #key_list[name]
				and fields.new_name and fields.new_name ~= "" and selected[name] then
				local u_krs = minetest.deserialize(krs)
				u_krs[key_list[name][selected[name]]].user_description = fields.new_name
				meta:set_string(keyring.fields.KRS, minetest.serialize(u_krs))
				player:set_wielded_item(item)
				keyring.formspec(item, minetest.get_player_by_name(name))
				return
			end
			-- put the key out of keyring
			if fields.remove and selected[name] and key_list[name] and selected[name]
				and selected[name] <= #key_list[name] then
				local key = ItemStack("default:key")
				local u_krs = minetest.deserialize(krs)
				local key_meta = key:get_meta()
				key_meta:set_string("secret", selected[name])
				key_meta:set_string(keyring.fields.description,
					u_krs[key_list[name][selected[name]]].user_description)
				key_meta:set_string("description",
					u_krs[key_list[name][selected[name]]].description)
				local inv = minetest.get_player_by_name(name):get_inventory()
				if inv:room_for_item("main", key) then
					-- remove key from keyring
					local number = u_krs[key_list[name][selected[name]]].number
					if number > 1 then
						-- remove only 1 key
						u_krs[key_list[name][selected[name]]].number = number -1
					else
						u_krs[key_list[name][selected[name]]] = nil
					end
					-- apply
					item:get_meta():set_string(keyring.fields.KRS, minetest.serialize(u_krs))
					player:set_wielded_item(item)
					keyring.formspec(item, minetest.get_player_by_name(name))

					-- add key to inventory
					inv:add_item("main", key)
				else
					minetest.chat_send_player(name,
						S("There is no room in your inventory for a key."))
				end
				return
			end
		end
		-- no selected key, but removing/renaming asked
		if (fields.rename or fields.remove or (fields.key_enter and fields.key_enter_field
			and fields.key_enter_field == "new_name")) and not selected[name] then
			minetest.chat_send_player(name, S("You must select a key first."))
			return
		end

	end
end)

--[[ Get key list
-- parameter: serialized krs and player name
-- return: key list
--]]
function get_key_list(serialized_krs, name)
	local krs = minetest.deserialize(serialized_krs) or {}
	local list = ""
	local first = true
	local index = 1
	key_list[name] = {}
	for k, v in pairs(krs) do
		key_list[name][index] = k
		index = index +1
		if not first then
			list = list..","
		else
			first = false
		end
		list = list..F(v.user_description or v.description)
		if (v.number > 1) then
			list = list..F(" (×"..v.number..")")
		end
	end
	return list
end

--[[
-- itemstack: a keyring:keyring
-- player: the player to show formspec
--]]
keyring.formspec = function(itemstack, player)
	local name = player:get_player_name()
	local keyring_owner = itemstack:get_meta():get_string("owner")
	local keyring_allowed = (keyring_owner == nil)
		or (keyring_owner == player:get_player_name())
		or (keyring_owner == "")
	local has_list_priv = minetest.check_player_privs(name, { keyring_inspect=true })
	if not (keyring_allowed or has_list_priv) then
		keyring.log(player:get_player_name()
			.." tryed to access key management of a keyring owned by "
			..(keyring_owner or "unknown player"))
		minetest.chat_send_player(name, S("You are not allowed to use this keyring."))
		return itemstack
	end
	local keyring_type = itemstack:get_name()
	local krs = itemstack:get_meta():get_string(keyring.fields.KRS)
	local formspec = "formspec_version[3]"
		.."size[10.75,11.25]"
		.."label[1,1;"..F(S("List of keys in the keyring")).."]"
		.."textlist[1,1.75;8.75,"
	if keyring_type == "keyring:personnal_keyring" then
		if keyring_allowed then
			formspec = formspec.."6"
		else
			-- has keyring_inspect privilege but is not owner
			formspec = formspec.."9"
		end
	else
		formspec = formspec.."7"
	end
	formspec = formspec..";selected_key;"..get_key_list(krs, name).."]"
	if keyring_allowed then
		if keyring_type == "keyring:personnal_keyring" then
			formspec = formspec.."checkbox[1,8.5;make_private;"
				..F(S("Make this keyring private"))
				..";"..((keyring_owner and keyring_owner ~="") and "true" or "false")
				.."]"
		end
		formspec = formspec.."button[1,9;5,1;rename;"..F(S("Rename key")).."]"
			.."field[6.5,9;3.25,1;new_name;;]"
			.."field_close_on_enter[new_name;false]"
			.."button[1,10;5,1;remove;"..F(S("Remove key")).."]"
	end
	formspec = formspec.."button_exit[6.5,10;3.25,1;exit;"..F(S("Exit")).."]"

	-- context
	context[name] = krs
	minetest.show_formspec(name, "keyring:edit", formspec)
	return itemstack
end
