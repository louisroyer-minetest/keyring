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
