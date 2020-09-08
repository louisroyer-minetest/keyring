if default.can_interact_with_node then
	local original = default.can_interact_with_node
	default.can_interact_with_node = function(player, pos, ...)
		local result = original(player, pos, ...)
		if not result then
			local meta = minetest.get_meta(pos)
			local item = player:get_wielded_item()

			-- checking container is in hands
			if minetest.get_item_group(item:get_name(), "key_container") ~= 1 then
				return false
			end

			-- selecting key
			local new_keyring = keyring.craft_common.select_key(item, player, meta)
			if new_keyring ~= nil then
				player:set_wielded_item(new_keyring)
			end

			-- re-run the test
			return original(player, pos, ...)
		end
		return result
	end
end
