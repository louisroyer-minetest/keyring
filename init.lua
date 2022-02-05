local MP = minetest.get_modpath("keyring")

keyring = {}

-- mod information
keyring.mod = {version = "1.3.0", author = "Louis Royer"}

-- keyring settings
keyring.settings =
	{
		personal_keyring = minetest.settings:get_bool("keyring.personal_keyring", true),
		playerfactions = minetest.settings:get_bool("keyring.playerfactions", true),
		override_default_can_interact_with_node = minetest.settings:get_bool(
			"keyring.override_default_can_interact_with_node", true),
	}

-- disable playerfactions if playerfactions mod is not loaded
if not minetest.get_modpath("playerfactions") then
	keyring.settings.playerfactions = false
end

-- disable override_default_can_interact_with_node if default mod is not loaded
if not minetest.get_modpath("default") then
	keyring.override_default_can_interact_with_node = false
end

-- XXX: when https://github.com/minetest/minetest/pull/7377
--      is merged, we can remove this function and %s/keyring\.log/minetest\.log/g
keyring.log = function(level, text)
	local prefix = "[keyring] "
	if text then
		minetest.log(level, prefix..text)
	else
		minetest.log(prefix..level)
	end
end

if not basic_materials.mod then
	-- If this variable is not set, then basic_materials does not provide `wire` group
	keyring.log("error", "Please use a more recent version of"
	.." basic_materials to be able to craft keyrings.")
	keyring.log("error", "Get latest version of basic_materials: "
	.."https://gitlab.com/VanessaE/basic_materials"
	.."/-/archive/master/basic_materials-master.zip")
end

if keyring.settings.override_default_can_interact_with_node then
	dofile(MP.."/override_default_can_interact_with_node.lua")
end
dofile(MP.."/privileges.lua")
dofile(MP.."/meta_fields.lua")
dofile(MP.."/formspec.lua")
dofile(MP.."/craft_common.lua")
dofile(MP.."/craft_keyring.lua")
if keyring.settings.personal_keyring then
	dofile(MP.."/craft_personal_keyring.lua")
end
