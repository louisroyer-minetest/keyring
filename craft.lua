-- Translation support
local S = minetest.get_translator("keyring")

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
	if secret ~= "" and keyring.fields.utils.KRS.in_serialized_keyring(
		itemstack, secret) then
		local u_desc = minetest.deserialize(
			i_meta:get_string(keyring.fields.KRS))[secret].user_description
		minetest.chat_send_player(name, S("Key found in keyring and selected (@1).",
			(u_desc ~= nil and u_desc ~= "") and u_desc or
			minetest.deserialize(i_meta:get_string(keyring.fields.KRS))[secret].description))
		i_meta:set_string("secret", secret)
		-- update immediatly wielded item
		if placer:get_wielded_item():get_meta():get_string(
			keyring.fields.KRS) == i_meta:get_string(keyring.fields.KRS) then
			placer:set_wielded_item(itemstack)
		end
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
			itemstack = keyring.formspec(itemstack, placer)
		end
		return itemstack
	end,
	on_secondary_use = function(itemstack, placer, pointed_thing)
		return keyring.formspec(itemstack, placer)
	end,
	-- mod doc
	_doc_items_longdesc = S("A keyring to store your keys."),
	_doc_items_usagehelp = S("Left-click on a locked node to select a key, "
		.."then works as a regular key. "
		.."Some nodes support right-clicking to select key and open at once.\n"
		.."Click pointing no node to access key-management interface "
		.."(keys can be renamed or taken off).\n"
		.."Some crafts let you add keys to the keyring."),
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
	-- craft with 4 group:key
	-- to make the adding of keys in keyring easier (but at a cost)
	minetest.register_craft({
		output = "keyring:keyring",
		recipe = {
			{ "group:key", wire, "group:key" },
			{ wire,        "",          wire },
			{ "group:key", wire, "group:key" },
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
				local krs = item:get_meta():get_string(keyring.fields.KRS)
				if krs ~= "" then
					-- extract keyring.fields.KRS if it exists
					for k, v in pairs(minetest.deserialize(krs) or {}) do
						-- add missing secrets
						if not keyring.fields.utils.KRS.in_keyring(secrets, k) then
							secrets[k] = v
						else
							secrets[k].number = secrets[k].number + v.number
						end
					end
				elseif item:get_name() ~= "keyring:keyring" then
					-- else extract secret
					local secret = item:get_meta():get_string("secret")
					if not keyring.fields.utils.KRS.in_keyring(secrets, secret) then
						local u_desc = item:get_meta():get_string(keyring.fields.description)
						secrets[secret] = {
							number = 1,
							description = item:get_description(),
							user_description = (u_desc ~= "") and u_desc or nil
						}
					else
						secrets[secret].number = secrets[secret].number + 1
					end
				end
			end
		end
		-- write secrets in keyring.fields.KRS
		itemstack:get_meta():set_string(keyring.fields.KRS, minetest.serialize(secrets))
		return itemstack
	end
end)
