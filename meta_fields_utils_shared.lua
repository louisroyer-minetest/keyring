keyring.fields.utils.shared = {}

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
	-- Check if shared with the player
	if keyring.fields.utils.shared.is_shared_with_raw(playername, list) then
		return true
	end
	-- Additional checks for factions
	if keyring.settings.playerfactions then
		if factions.version == nil then
			-- backward compatibility
			local p_fac = factions.get_player_faction(playername)
			if p_fac and (" "..list.." "):find(" faction:"..p_fac.." ", 1, true) then
				return true
			end
		else
			for match in (" "..list.." "):gmatch(
				"faction:([^ ]+)%f[ ]") do
				if factions.player_is_in_faction(match, playername) then
					return true
				end
			end
		end
	end
	return false
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

--[[
-- Get playername from list and index
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
