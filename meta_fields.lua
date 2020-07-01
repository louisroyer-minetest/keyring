keyring.fields = {utils = {}}
--[[ Meta field KRS `_keyring_registered_secret` contains
--{
--  {
--      <secret1>, {
--          number: <number>,
--          description: <description>,
--          user_description: <user_description>
--      }
--  },
--  {
--      <secret2>, {
--          number: <number>,
--          description: <description>,
--          user_description: <user_description>
--      }
--  },
--  …
--}
--
--]]
keyring.fields.KRS = "_keyring_registered_secrets"
keyring.fields.utils.KRS = {}
keyring.fields.utils.owner = {}

--[[ Returns true if secret is in the secrets_list.
--]]
keyring.fields.utils.KRS.in_keyring = function(secrets_list, secret)
	for k, _ in pairs(secrets_list) do
		if secret == k then
			return true
		end
	end
	return false
end

--[[ Returns true if secret is in the secrets_list of the itemstack
--]]
keyring.fields.utils.KRS.in_serialized_keyring = function(itemstack, secret)
	local krs = minetest.deserialize(
		itemstack:get_meta():get_string(keyring.fields.KRS)) or {}
	return keyring.fields.utils.KRS.in_keyring(krs, secret)
end
--
--[[ True if player is allowed to edit keyring
--]]
keyring.fields.utils.owner.is_edit_allowed = function(keyring_owner, player)
	return (keyring_owner == nil)
	or (keyring_owner == play_name)
	or (keyring_owner == "")
end

--[[
-- Used to keep user description in keys
--]]
keyring.fields.description = "_keyring_user_description"

--[[
-- Used to track if the keyring is shared
-- format: usernames separated with spaces
--]]
keyring.fields.shared = "_keyring_shared"
