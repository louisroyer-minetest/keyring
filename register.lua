-- Translation support
local S = minetest.get_translator("keyring")
local F = minetest.formspec_escape

local KRS = "_keyring_registered_secrets"
--[[ Meta field KRS `_keyring_registered_secret` contains
--{
--  { <secret1>, {number: <number>, description: <description>} }
--  { <secret2>, {number: <number>, description: <description>} }
--  { <secret3>, {number: <number>, description: <description>} }
--  …
--}
--
--]]

--[[ Returns true if secret is in the secrets_list.
--]]
local function in_keyring(secrets_list, secret)
	for k, _ in pairs(secrets_list) do
		if secret == k then
			return true
		end
	end
	return false
end

--[[ Returns true if secret is in the secrets_list of the itemstack
--]]
local function in_serialized_keyring(itemstack, secret)
	local krs = minetest.deserialize(itemstack:get_meta():get_string(KRS)) or {}
	return in_keyring(krs, secret)
end

local function form_keyring(itemstack, player)
	-- TODO: this formspec should allow to list all keys, their names, and number
	-- allow to change a name, and to retrieve a key into the main inventory
	local name = player:get_player_name()
	local formspec = "formspec_version[3]"
		.."size[10.75,11.25]"
		.."label[1,1;"..F(S("List of keys in the keyring")).."]"
		.."label[4,4;NOT IMPLEMENTED]" -- TODO
		.."button_exit[6.7,10;3.6,1;exit;"..F(S("Exit")).."]"
	minetest.show_formspec(name, "keyring:inv", formspec)
	return itemstack
end

--[[ itemstack: the keyring:keyring used
-- placer: the player using the keyring
-- meta: meta of the pointed node
--]]
local function select_key(itemstack, placer, meta)
	local i_meta = itemstack:get_meta()
	local name = placer:get_player_name()
	local owner = meta:get_string("owner")
	local secret = meta:get_string("key_lock_secret")
	if secret == i_meta:get_string("secret") or owner == name or owner == "" then
		-- nothing to do, abort to avoid spamming the chat
		return itemstack
	end
	if secret ~= "" and in_serialized_keyring(itemstack, secret) then
		minetest.chat_send_player(name, S("Key found in keyring and selected (@1)."),
			minetest.deserialize(i_meta:get_string(KRS))[secret].description)
		i_meta:set_string("secret", secret)
	else
		minetest.chat_send_player(name, S("Key not found in keyring."))
	end
	return itemstack
end


-- copy `on_place` from `default:key`
local key_on_place = ItemStack("default:key"):get_definition().on_place

local function keyring_on_place(itemstack, placer, pointed_thing)
	-- we try to select a key before using it
	local pos = pointed_thing.under
	local is = select_key(itemstack, placer, minetest.get_meta(pos))
	return key_on_place(is, placer, pointed_thing)
end


minetest.register_craftitem("keyring:keyring", {
	description = S("Keyring"),
	inventory_image = "keyring_keyring.png",
	-- mimic a key
	groups = {key = 1},
	stack_max = 1,
	on_place = keyring_on_place,

	-- on left click
	on_use = function(itemstack, placer, pointed_thing)
		local pos = pointed_thing.under
		if pos then
			itemstack = select_key(itemstack, placer, minetest.get_meta(pos))
		else -- no node pointed
			itemstack = form_keyring(itemstack, placer)
		end
		return itemstack
	end,
	on_secondary_use = function(itemstack, placer, pointed_thing)
		return form_keyring(itemstack, placer)
	end,
})

-- list of wires since there is currently no group:wire in basic_materials
local wires = {
	"basic_materials:gold_wire",
	"basic_materials:copper_wire",
	"basic_materials:steel_wire"
}


for _, wire in pairs(wires) do
	-- craft with wire
	minetest.register_craft({
		output = "keyring:keyring",
		recipe = {
			{ "",   wire,            "" },
			{ wire, "default:key", wire },
			{ "",   wire,            "" },
		},
		replacements = {
			{ wire, "basic_materials:empty_spool" },
			{ wire, "basic_materials:empty_spool" },
			{ wire, "basic_materials:empty_spool" },
			{ wire, "basic_materials:empty_spool" }
		},
	})
end

-- craft to add a key
minetest.register_craft({
	output = "keyring:keyring",
	recipe = { "keyring:keyring", "group:key" },
	type = "shapeless",
})

-- add key used to craft into keyring
minetest.register_on_craft(function(itemstack, player, old_craft_grid, craft_inv)
	if (itemstack:get_name() == "keyring:keyring") then
		local secrets = {}
		for _, item in pairs(old_craft_grid) do
			-- check item is of group key
			local groups = item:get_definition().groups
			if groups and groups.key == 1 then
				local krs = item:get_meta():get_string(KRS)
				if krs ~= "" then
					-- extract KRS if it exists
					for k, v in pairs(minetest.deserialize(krs)) do
						-- add missing secrets
						if not in_keyring(secrets, k) then
							secrets[k] = v
						else
							secrets[k].number = secrets[k].number + v.number
						end
					end
				else
					-- else extract secret
					local secret = item:get_meta():get_string("secret")
					if not in_keyring(secrets, secret) then
						secrets[secret] = {number = 1, description = item:get_description()}
					else
						secrets[secret].number = secrets[secret].number + 1
					end
				end
			end

		end
		-- write secrets in KRS
		itemstack:get_meta():set_string(KRS, minetest.serialize(secrets))
		return itemstack
	end
end)
