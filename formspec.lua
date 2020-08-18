-- Translation support
local S = minetest.get_translator("keyring")
local F = minetest.formspec_escape

-- context
local context = {}
local selected = {}
local selected_player = {}
local selected_player_num = {}
local key_list = {}
local tab = {}
local function reset_context(name)
	context[name] = nil
	selected[name] = nil
	selected_player[name] = nil
	selected_player_num[name] = nil
	key_list[name] = nil
	tab[name] = nil
end

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	reset_context(name)
end)

local form_allowed = {}

keyring.form = {}
--[[
-- Features:
-- - translator: function used for translation
-- - virtual_symbol: String or nil (default)
-- - title_tab: bool
-- - title_tab_management: String or nil (default)
-- - title_tab_settings: String or nil (default)
-- - msg_not_allowed_edit: String or nil (default)
-- - msg_is_public: String or nil (default)
-- - msg_you_own: String or nil (default)
-- - msg_is_owned_by: Untranslated String or nil (default)
-- - msg_is_shared_with: String or nil (default)
-- - msg_not_allowed_use: String or nil (default)
-- - msg_not_shared: String or nil (default)
-- - msg_list_of_keys: String or nil (default)
-- - msg_no_key: String or nil (default)
-- - remove_key: bool
-- - rename_key: bool
-- - set_owner: bool
-- - share: bool
-- - share_management: bool (default: true)
-- - msg_manage_keys: String or nil (default)
-- - msg_not_manage_keys: String or nil (default)
-- - msg_button_allow_manage_keys: String or nil (default)
-- - msg_button_deny_manage_keys: String or nil (default)
--
--]]
keyring.form.register_allowed = function(itemname, features)
	form_allowed[itemname] = features
end


--[[
-- Returns a table containing
-- - is_use_allowed: bool
-- - msg_not_use_allowed: String
-- - display_title_tabs: bool
-- - title_tab_management: String
-- - title_tab_settings: String
-- - msg_owner: String
-- - display_set_owner_button: bool
-- - is_owned: bool
-- - display_msg_shared: bool
-- - msg_shared: String
-- - msg_shared_pos: String containing pos
-- - display_shared_list: bool
-- - shared_list_start_pos: String containing start pos
-- - shared_list_size: String containing size
-- - display_share_button: bool
-- - display_unshare_button: bool
-- - msg_list_keys: String
-- - display_keys_list: bool
-- - keys_list_size: String containing size
-- - key_virtual_symbol: String
-- - display_rename_button: bool
-- - display_remove_button: bool
-- - msg_manage_keys: String
-- - msg_manage_keys_pos: String containing start pos
-- - display_manage_keys_button: bool
-- - msg_manage_keys_button: String
-- - manage_keys_button_pos: String containing start pos
-- - action_manage_keys_button: String containing name of action button
--
--]]
local function get_formspec_properties(itemstack, player)
	local props = {}
	local item_name = itemstack:get_name()
	local FA = form_allowed[item_name]
	local item_meta = itemstack:get_meta()
	local player_name = player:get_player_name()
	local keyring_owner = item_meta:get_string("owner")
	local keyring_allowed = keyring.fields.utils.owner.is_edit_allowed(keyring_owner,
		player_name)
	local has_list_priv = minetest.check_player_privs(player_name, { keyring_inspect=true })
	local shared = item_meta:get_string(keyring.fields.shared)
	local is_shared_with = keyring.fields.utils.shared.is_shared_with(player_name, shared)
	local shared_key_management = item_meta:get_int(
		keyring.fields.shared_key_management)
	local key_management_allowed = keyring.fields.utils.owner.is_key_management_allowed(
		keyring_owner, shared, shared_key_management, player_name)
	local has_keys = next(minetest.deserialize(
		item_meta:get_string(keyring.fields.KRS)) or {}) or false

	props.is_use_allowed = (keyring_allowed or has_list_priv or is_shared_with) and FA
		and true or false
	if not props.is_use_allowed then
		props.msg_not_use_allowed = FA.msg_not_allowed_use
			or S("You are not allowed to use this keyring.")
		return props
	end

	props.display_title_tabs = FA.title_tab
	if props.display_title_tabs then
		props.title_tab_management = FA.title_tab_management or S("Keys management")
		props.title_tab_settings = FA.title_tab_settings or S("Keyring settings")
	end

	if keyring_owner == player_name then
		props.msg_owner = FA.msg_you_own or S("You own this keyring.")
		props.display_set_owner_button = FA.set_owner or false
		props.is_owned = true
		props.display_share_button = FA.share or false
		props.display_unshare_button = FA.share and (shared ~= nil) and (shared ~= "") or false
		props.display_manage_keys_button = FA.share_management
			and (shared ~= nil) and (shared ~= "") or true
	elseif keyring_owner ~= "" then
		props.msg_owner = (FA.translator and FA.msg_is_owned_by)
			and FA.translator(FA.msg_is_owned_by, keyring_owner)
			or S("This keyring is owned by @1.", keyring_owner)
		props.display_set_owner_button = false
		props.is_owned = true
		props.display_share_button = false
		props.display_unshare_button = false
		props.display_manage_keys_button = false
	else
		props.msg_owner = FA.msg_is_public or S("This keyring is public.")
		props.display_set_owner_button = FA.set_owner or false
		props.is_owned = false
		props.display_share_button = false
		props.display_unshare_button = false
		props.display_manage_keys_button = false
	end

	if props.is_owned then
		props.display_msg_shared = true
		props.msg_shared_pos = props.display_set_owner_button and "3" or "2"
		local slstart = props.display_set_owner_button and 3.75 or 2.75
		props.shared_list_start_pos = tostring(slstart)
		local slsize = 3
			+ ((not props.display_set_owner_button) and 1 or 0)
			+ ((not props.display_share_button) and 1 or 0)
			- (props.display_manage_keys_button and 1 or 0)
		props.shared_list_size = tostring(slsize)
		if (shared ~= nil) and (shared ~= "") then
			props.display_shared_list = FA.share or false
			props.msg_shared = FA.msg_is_shared_with or S("This keyring is shared with:")
			if shared_key_management == 1 then
				props.msg_manage_keys = FA.msg_manage_keys
					or S("They are able to use the keyring and to manage keys.")
				props.msg_manage_keys_button = FA.msg_button_deny_manage_keys
					or S("Deny key management")
				props.action_manage_keys_button = "deny_shared_management"
			else
				props.msg_manage_keys = FA.msg_not_manage_keys
					or S("They are able to use the keyring but not to manage keys.")
				props.msg_manage_keys_button = FA.msg_button_allow_manage_keys
					or S("Allow key management")
				props.action_manage_keys_button = "allow_shared_management"
			end
			props.msg_manage_keys_pos = tostring(slstart + slsize + 0.75)
			props.manage_keys_button_pos = tostring(slstart + slsize + 1.25)
		else
			props.display_shared_list = false
			props.msg_shared = FA.msg_not_shared or S("This keyring is not shared.")
		end
	end
	if has_keys then
		props.display_keys_list = true
		props.msg_list_keys = FA.msg_list_of_keys or S("List of keys in the keyring")
		props.key_virtual_symbol = FA.virtual_symbol or S("[virtual]")
		props.display_rename_button = FA.rename_key and key_management_allowed or false
		props.display_remove_button = FA.remove_key and key_management_allowed or false
	else
		props.display_keys_list = false
		props.msg_list_keys = FA.msg_no_key or S("There is no key in the keyring.")
		props.display_rename_button = false
		props.display_remove_button = false
	end
	props.keys_list_size = props.display_rename_button and "7" or "8"
	return props
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	-- guard
	if not (formname == "keyring:edit") then
		return
	end
	local name = player:get_player_name()
	-- clean context
	if fields.quit and not fields.key_enter then
		reset_context(name)
		return
	end

	-- check abuses
	local item = player:get_wielded_item()
	local item_name = item:get_name()
	local meta = item:get_meta()
	local FA = form_allowed[item_name]
	-- check item is allowed
	if FA == nil then
		keyring.log("action", "Player "..name..
			" sent a keyring action but the selected item ("..item_name..") is not allowed.")
		return
	end

	-- check item group
	if not (minetest.get_item_group(item_name, "key_container") == 1) then
		keyring.log("action", "Player "..name..
			" sent a keyring action but the selected item ("
			..item_name..") is not a key container.")
		return
	end
	local krs = meta:get_string(keyring.fields.KRS)
	if krs ~= context[name] then
		keyring.log("action", "Player "..name
			.." sent a keyring action but the selected item is not the right key container.")
		return
	end

	-- edits rights not required for this section
	if FA.title_tab then
		-- tabheader selection
		if fields.header == "2" then
			tab[name] = true
		elseif fields.header == "1" then
			tab[name] = nil
		end
		if fields.header then
			keyring.form.formspec(item, minetest.get_player_by_name(name))
		end
	end

	-- check for edits
	local keyring_owner = meta:get_string("owner")
	local shared = meta:get_string(keyring.fields.shared)
	local keyring_allowed = keyring.fields.utils.owner.is_edit_allowed(keyring_owner, name)
	local key_management_allowed = keyring.fields.utils.owner.is_key_management_allowed(
		keyring_owner, shared, meta:get_int(keyring.fields.shared_key_management), name)
	if not key_management_allowed then
		if (not minetest.check_player_privs(name, { keyring_inspect=true })) and
			not keyring.fields.utils.shared.is_shared_with(name, shared) then
			keyring.log("action", "Player "..name
				.." sent command to manage keys of a "..item_name.." owned by "
				..(keyring_owner or "unknown player"))
		end
		return
	end

	if FA.share or FA.set_owner then
		-- make owner
		if fields.make_private or fields.make_public and FA.set_owner then
			if not keyring_allowed then
				minetest.chat_send_player(name,
					FA.msg_not_allowed_edit or
					S("You are not allowed to edit settings of this keyring."))
				return
			end
			if fields.make_private  then
				meta:set_string("owner", name)
				meta:set_string("description",
					minetest.registered_items[item_name].description
					.." ("..S("owned by @1", name)..")")
			elseif fields.make_public then
				meta:set_string("owner", "")
				meta:set_string("description",
					minetest.registered_items[item_name].description)
			end
			player:set_wielded_item(item)
			keyring.form.formspec(item, minetest.get_player_by_name(name))
		end
		if (keyring_owner == name) and (FA.share_management ~= false) then
			if fields.allow_shared_management then
				meta:set_int(keyring.fields.shared_key_management, 1)
				player:set_wielded_item(item)
				keyring.form.formspec(item, minetest.get_player_by_name(name))
			elseif fields.deny_shared_management then
				meta:set_int(keyring.fields.shared_key_management, 0)
				player:set_wielded_item(item)
				keyring.form.formspec(item, minetest.get_player_by_name(name))
			end
		end
		if (keyring_owner == name) and FA.share then
			if fields.share_player_dropdown and fields.player_dropdown
				and fields.player_dropdown ~= "" then
				meta:set_string(keyring.fields.shared, shared..
					((shared ~="") and " " or "")..fields.player_dropdown)
				player:set_wielded_item(item)
				keyring.form.formspec(item, minetest.get_player_by_name(name))
			end
			if (fields.share_player_button or (fields.key_enter and fields.key_enter_field
				and fields.key_enter_field == "share_player")) and fields.share_player
				and fields.share_player ~= "" then
				local concat = fields.share_player
				for _, v in ipairs({"%[", "]", ",", ";", "\\"}) do
					concat = concat:gsub(v," ")
				end
				meta:set_string(keyring.fields.shared, shared..
					((shared ~="") and " " or "")..concat)
					player:set_wielded_item(item)
				keyring.form.formspec(item, minetest.get_player_by_name(name))
			end
			if fields.unshare and selected_player[name]
				and selected_player[name] ~= "" then
				shared = keyring.fields.utils.shared.remove(selected_player[name], shared)
				if keyring.fields.utils.shared.get_from_index(
					selected_player_num[name], shared) == "" then
					selected_player_num[name] = selected_player_num[name] -1
				end
				selected_player[name] = keyring.fields.utils.shared.get_from_index(
					selected_player_num[name], shared)
				meta:set_string(keyring.fields.shared, shared)
				player:set_wielded_item(item)
				keyring.form.formspec(item, minetest.get_player_by_name(name))
			end

			-- refresh selected player
			if fields.selected_player then
				local event = minetest.explode_textlist_event(fields.selected_player)
				if event.type ~= "INV" then
					selected_player[name] = keyring.fields.utils.shared.get_from_index(
						event.index, shared)
					if selected_player[name] == "" then
						keyring.log("action", "Player "..name
							.." selected a player in "..item_name.." settings interface"
							.." but this player is not in the list.")
					else
						selected_player_num[name] = event.index
					end
				end
			end

			-- warn player
			if (fields.share_player_button or (fields.key_enter and fields.key_enter_field
				and fields.key_enter_field == "share_player")) and ((not fields.share_player)
				or fields.share_player == "") then
				minetest.chat_send_player(name, S("You must enter a player name first."))
			end
			if (fields.unshare and ((not selected_player[name])
				or selected_player[name] == ""))
				or (fields.share_player_dropdown and ((not fields.player_dropdown)
				or fields.player_dropdown == "")) then
				minetest.chat_send_player(name, S("You must select a player first."))
			end
		end
	end

	-- key selection
	if fields.selected_key ~= nil then
		local event = minetest.explode_textlist_event(fields.selected_key)
		if event.type ~= "INV" then
			if key_list[name] == nil or event.index > #key_list[name] then
				keyring.log("action", "Player "..name
					.." selected a key in "..item_name.." interface"
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
			and fields.new_name and fields.new_name ~= "" and selected[name]
			and FA.rename_key and key_management_allowed then
			local u_krs = minetest.deserialize(krs)
			u_krs[key_list[name][selected[name]]].user_description = fields.new_name
			meta:set_string(keyring.fields.KRS, minetest.serialize(u_krs))
			player:set_wielded_item(item)
			keyring.form.formspec(item, minetest.get_player_by_name(name))
			return
		end
		-- put the key out of keyring
		if fields.remove and selected[name] and key_list[name] and selected[name]
			and selected[name] <= #key_list[name] and FA.remove_key and key_management_allowed then
			local key = ItemStack("default:key")
			local u_krs = minetest.deserialize(krs)
			local key_meta = key:get_meta()
			key_meta:set_string("secret", selected[name])
			key_meta:set_string(keyring.fields.description,
				u_krs[key_list[name][selected[name]]].user_description)
			key_meta:set_string("description",
				u_krs[key_list[name][selected[name]]].description)
			local inv = minetest.get_player_by_name(name):get_inventory()
			local number = u_krs[key_list[name][selected[name]]].number
			local virtual = u_krs[key_list[name][selected[name]]].virtual
			if inv:room_for_item("main", key) or ((number == 0) and virtual) then
				-- remove key from keyring
				if (number > 1) or (number == 1 and virtual) then
					-- remove only 1 key
					u_krs[key_list[name][selected[name]]].number = number -1
				elseif (number == 1) or ((number == 0) and virtual) then
					u_krs[key_list[name][selected[name]]] = nil
				end
				-- apply
				item:get_meta():set_string(keyring.fields.KRS, minetest.serialize(u_krs))
				player:set_wielded_item(item)
				keyring.form.formspec(item, minetest.get_player_by_name(name))

				if not (number == 0 and virtual) then
					-- add key to inventory
					inv:add_item("main", key)
				end
			else
				minetest.chat_send_player(name, S("There is no room in your inventory for a key."))
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
end)

--[[ Get key list
-- parameter: serialized krs, player name and symbol utilized for virtual keys
-- return: key list
--]]
local function get_key_list(serialized_krs, name, virtual_symbol)
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
		if (v.number > 1) or (v.virtual and (v.number == 1)) then
			list = list..F(" (×"..v.number..")")
		end
		if v.virtual then
			list = list..F(v.virtual
				and (((virtual_symbol ~= "") and " " or "")..(virtual_symbol))
				or "")
		end
	end
	return list
end

--[[ Get player shared list
-- parameter: list of players separated by space, player name
-- return: return player list separated by comma
-- ]]
local function get_player_shared_list(player_list, name)
	if player_list == "" or player_list == nil then
		return ""
	end
	return player_list:gsub("%s+", ",")
end

--[[
-- Add name to list separated by separator.
-- parameters:
-- - list: the previous list
-- - name: the name to add
-- - first: true if this is the first name to add to the list
-- - separator: separator to use
--
-- returns:
-- - the new list
--]]
local function add_to_list(list, name, first, separator)
	if not first then
		list = list..separator
	end
	list = list..name
	return list
end

--[[
-- Get connected players list + player’s faction (not already in shared)
-- parameter:
-- - shared_list: list of players/factions shared with (space separated)
-- - name: player name
--]]
local function get_player_list_connected(shared_list, name)
	local list = minetest.get_connected_players()
	local res_list = ""
	local first = true
	for _, v in pairs(list) do
		local v_name = v:get_player_name()
		if (v_name ~= name) and
			not keyring.fields.utils.shared.is_shared_with_raw(v_name, shared_list) then
			res_list = add_to_list(res_list, v_name, first, ",")
			first = false
		end
	end
	if not keyring.settings.playerfactions then
		return res_list
	end

	-- playerfactions support
	local p_factions = {}
	if factions.version == nil then
		-- backward compatibility
		table.insert(p_factions, factions.get_player_faction(name))
	else
		p_factions = factions.get_player_factions(name)
	end
	for _, p_fac in ipairs(p_factions) do
		if not keyring.fields.utils.shared.is_shared_with_raw("faction:"..p_fac,
			shared_list) then
			res_list = add_to_list(res_list, "faction:"..p_fac, first, ",")
			first = false
		end
	end
	return res_list
end

--[[
-- itemstack: a keyring:keyring
-- player: the player to show formspec
--]]
keyring.form.formspec = function(itemstack, player)
	local item_meta = itemstack:get_meta()
	local name = player:get_player_name()
	local props = get_formspec_properties(itemstack, player)
	if not props.is_use_allowed then
		local item_name = itemstack:get_name()
		local keyring_owner = item_meta:get_string("owner")
		keyring.log("action", "Player "..name
			.." tryed to access key management of a "..item_name.." owned by "
			..(keyring_owner or "unknown player"))
		minetest.chat_send_player(name, props.msg_not_use_allowed)
		return itemstack
	end
	local krs = item_meta:get_string(keyring.fields.KRS)
	local shared = item_meta:get_string(keyring.fields.shared)
	-- formspec
	local formspec = "formspec_version[3]"
		.."size[10.75,11.25]"
	if props.display_title_tabs then
		-- tabheader
		formspec = formspec.."tabheader[0,0;10.75,1;header;"
			..props.title_tab_management
			..","..props.title_tab_settings..";"
			..(tab[name] and "2" or "1")..";false;true]"
	end
	if tab[name] then
		formspec = formspec.."label[1,1;"..F(props.msg_owner).."]"
		if props.display_set_owner_button then
			formspec = formspec.."button[1,1.5;5,1;"
				..(props.is_owned and "make_public" or"make_private")..";"
				..F(props.is_owned and S("Make public") or S("Make private"))
				.."]"
		end
		if props.display_msg_shared then
			formspec = formspec.."label[1,"..props.msg_shared_pos..";"..F(props.msg_shared).."]"
		end
		if props.display_shared_list then
			formspec = formspec.."textlist[1,"
				..props.shared_list_start_pos
				..";8.75,"..props.shared_list_size
				..";selected_player;"
				..get_player_shared_list(shared, name).."]"
				.."label[1,"
				..props.msg_manage_keys_pos
				..";"..F(props.msg_manage_keys).."]"
			if props.display_manage_keys_button then
				formspec = formspec.."button[1,"..props.manage_keys_button_pos
					..";8.75,1;"
					..props.action_manage_keys_button..";"
					..F(props.msg_manage_keys_button)
					.."]"
			end
		end
		if props.display_share_button then
			formspec = formspec
				-- dropdown
				.."dropdown[1,8;5,1;player_dropdown;"
				..get_player_list_connected(shared, name)..";0]"
				.."button[6.5,8;3.25,1;share_player_dropdown;"..F(S("Share")).."]"
				-- field
				.."field[1,9;5,1;share_player;;]"
				.."field_close_on_enter[share_player;false]"
				.."button[6.5,9;3.25,1;share_player_button;"..F(S("Share")).."]"
		end
		if props.display_unshare_button then
			formspec = formspec
				.."button[1,10;5,1;unshare;"..F(S("Unshare")).."]"
		end
	else
		formspec = formspec
			-- header label
			.."label[1,1;"..F(props.msg_list_keys).."]"
			-- list of keys
		if props.display_keys_list then
		formspec = formspec.."textlist[1,1.75;8.75,"
			..props.keys_list_size..";selected_key;"
			..get_key_list(krs, name, props.key_virtual_symbol).."]"
		end
		if props.display_rename_button then
			-- rename button
			formspec = formspec.."button[1,9;5,1;rename;"..F(S("Rename key")).."]"
			.."field[6.5,9;3.25,1;new_name;;]"
			.."field_close_on_enter[new_name;false]"
		end
		if props.display_remove_button then
			formspec = formspec.."button[1,10;5,1;remove;"..F(S("Remove key")).."]"
		end
	end
	formspec = formspec.."button_exit[6.5,10;3.25,1;exit;"..F(S("Exit")).."]"

	-- context
	context[name] = krs
	minetest.show_formspec(name, "keyring:edit", formspec)
	return itemstack
end
