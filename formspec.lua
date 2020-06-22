-- Translation support
local S = minetest.get_translator("keyring")
local F = minetest.formspec_escape

-- context
local context = {}
minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	context[name] = nil
end)


minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname == "action:keyring:edit" then
		-- check abuses
		local name = player:get_player_name()
		local item = player:get_wielded_item()
		if item:get_name() ~= "keyring:keyring" then
			keyring.log("Player "..name.." sent a keyring action but has no keyring in hand.")
			return
		end
		local krs = item:get_meta():get_string(keyring.fields.KRS)
		if krs ~= context[name] then
			keyring.log("Player "..name.." sent a keyring action but has not the right keyring in hand.")
			return
		end
	end
end)

--[[ Get key list
-- parameter: serialized krs
-- return: key list
--]]
function get_keylist(serialized_krs)
	local krs = minetest.deserialize(serialized_krs or {})
	local list = ""
	local first = true
	for _, v in pairs(krs) do
		if not first then
			list = list..","
		else
			first = false
		end
		list = list..F(v.user_description or v.description)
		if (v.number > 1) then
			list = list..F("(×"..v.number..")")
		end
	end
	return list
end

--[[
-- itemstack: a keyring:keyring
-- player: the player to show formspec
--]]
keyring.formspec = function(itemstack, player)
	-- TODO: allow to change a name, and to retrieve a key into the main inventory
	local name = player:get_player_name()
	local krs = itemstack:get_meta():get_string(keyring.fields.KRS)
	local formspec = "formspec_version[3]"
		.."size[10.75,11.25]"
		.."label[1,1;"..F(S("List of keys in the keyring")).."]"
		.."textlist[1,1.75;8.75,7;test;"..get_keylist(krs).."]"
		.."button[1,9;5,1;rename;"..F(S("Rename key")).."]"
		.."label[1,9;NOT IMPLEMENTED]"
		.."field[6.5,9;3.25,1;new_name;;]"
		.."label[6.5,9;NOT IMPLEMENTED]"
		.."button[1,10;5,1;remove;"..F(S("Remove key")).."]"
		.."label[1,10;NOT IMPLEMENTED]"
		.."button_exit[6.5,10;3.25,1;exit;"..F(S("Exit")).."]"

	-- context
	context[name] = krs
	minetest.show_formspec(name, "keyring:show", formspec)
	return itemstack
end
