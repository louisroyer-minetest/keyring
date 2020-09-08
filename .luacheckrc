std = "lua51+minetest"
unused_args = false
allow_defined_top = true
max_line_length = 90
exclude_files = {"tests/*"}

stds.minetest = {
	read_globals = {
		"minetest",
		"VoxelManip",
		"VoxelArea",
		"PseudoRandom",
		"ItemStack",
		"default",
		table = {
			fields = {
				"copy",
			},
		},
	}
}

read_globals = {
	"basic_materials",
	"factions",
}

files["override_default_can_interact_with_node.lua"] = {
	read_globals = {
		default = {
			fields = {
				can_interact_with_node = {
					read_only = false,
					other_fields = false,
				}
			}
		}
	}
}
