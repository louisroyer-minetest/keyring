keyring.fields = {utils = {}}
--[[ Meta field KRS `_keyring_registered_secret` contains
--{
--  {
--      <secret1>, {
--          number: <number>,
--          virtual: boolean,
--          description: <description>,
--          user_description: <user_description>
--      }
--  },
--  {
--      <secret2>, {
--          number: <number>,
--          virtual: boolean,
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
keyring.fields.utils.shared = {}

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
keyring.fields.utils.owner.is_edit_allowed = function(keyring_owner, player_name)
	return (keyring_owner == nil)
	or (keyring_owner == player_name)
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

--[[
-- True if list said the keyring is shared with this faction
-- or directly to this player (not via faction)
-- parameters:
-- - name: name of the player/faction
-- - list: list of players + factions
--]]
keyring.fields.utils.shared.is_shared_with_raw = function(name, list)
	return (" "..list.." "):find(" "..name.." ", 1, true) and true or false
end

--[[
-- True if list said the keyring is shared with this player
-- either directly or via factions
--]]
keyring.fields.utils.shared.is_shared_with = function(playername, list)
	if keyring.settings.playerfactions then
		local p_fac = factions.get_player_faction(playername)
		if (p_fac ~= nil) and (" "..list.." "):find(" faction:"..p_fac.." ", 1, true) then
			return true
		end
	end
	return (" "..list.." "):find(" "..playername.." ", 1, true) and true or false
end

--[[
-- Remove name from shared list
--]]
keyring.fields.utils.shared.remove = function(playername, list)
	-- cannot use directly gsub because there is a risk of user injection
	local l = " "..list.." "
	local s_start, s_end = (l):find(" "..playername.." ", 1, true)
	if s_start == nil then
		return list
	end
	if s_start == 1 and s_end == l:len() then
		return ""
	end
	if s_start == 1 then
		return l:sub(s_end+1, -2)
	end
	if s_end == l:len() then
		return l:sub(2, s_start-1)
	end
	return l:sub(2, s_start-1).." "..l:sub(s_end+1, -2)
end

--[[ Get playername from list and index
--]]
keyring.fields.utils.shared.get_from_index = function(index, list)
	if index <= 0 then
		return ""
	end
	local last_space
	local next_space = 1
	local i = 0
	repeat
		last_space = next_space
		next_space = list:find(" ", last_space + 1, true)
		i = i + 1
	until ((i >= index) or next_space == nil)
	if i < index then
		return ""
	end
	return list:sub(last_space == 1 and last_space or last_space +1,
		next_space and next_space -1 or nil )
end
