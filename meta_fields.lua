local MP = minetest.get_modpath("keyring")
keyring.fields = {}

--[[
-- Used to store keys in the container.
-- format (must be serialized with minetest.serialize():
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

--[[
-- Used to allow edition of keys by users the keyring is shared with.
-- 0: Not allowed
-- 1: Allowed
--]]
keyring.fields.shared_key_management = "_keyring.shared_key_management"

--[[
-- Used to keep user description in keys.
-- Contains a string.
--]]
keyring.fields.description = "_keyring_user_description"

--[[
-- Used to track if the keyring is shared
-- format: values separated with spaces
-- values can be usernames or factions (use `faction:<factionid>`)
--]]
keyring.fields.shared = "_keyring_shared"

dofile(MP.."/meta_fields_utils.lua")
