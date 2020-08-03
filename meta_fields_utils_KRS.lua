keyring.fields.utils.KRS = {}

--[[
-- Returns true if secret is in the secrets_list.
--]]
keyring.fields.utils.KRS.in_keyring = function(secrets_list, secret)
	for k, _ in pairs(secrets_list) do
		if secret == k then
			return true
		end
	end
	return false
end

--[[
-- Returns true if secret is in the secrets_list of the itemstack
--]]
keyring.fields.utils.KRS.in_serialized_keyring = function(itemstack, secret)
	local krs = minetest.deserialize(
		itemstack:get_meta():get_string(keyring.fields.KRS)) or {}
	return keyring.fields.utils.KRS.in_keyring(krs, secret)
end
