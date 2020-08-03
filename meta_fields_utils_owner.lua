keyring.fields.utils.owner = {}

--[[
-- True if player is allowed to edit keyring
--]]
keyring.fields.utils.owner.is_edit_allowed = function(keyring_owner, player_name)
	return (keyring_owner == nil)
	or (keyring_owner == player_name)
	or (keyring_owner == "")
end

--[[
-- True if player is allowed to manage keys.
-- - keyring_owner: "owner" meta field content
-- - list: keyring.fields.shared meta field content
-- - management_by_shared: keyring.fields.shared_key_management meta field content (int)
-- - player_name: name of the player
--]]
keyring.fields.utils.owner.is_key_management_allowed = function(keyring_owner, list,
	management_by_shared, player_name)
	return keyring.fields.utils.owner.is_edit_allowed(keyring_owner, player_name)
	or ((management_by_shared == 1)
		and keyring.fields.utils.shared.is_shared_with(player_name, list))
end
