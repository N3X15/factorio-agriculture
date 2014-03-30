COLLISION_RANGE=1.2 -- lab 1.2
SELECTION_RANGE=1.5 -- lab 1.5
data:extend({
	{
		type = "smart-container",
		name = "ag-controller",
		order="a[ag-controller]",
		icon = "__Agriculture__/graphics/items/ag-controller.png",
		flags = {"placeable-neutral", "player-creation"},
		minable = {mining_time = 1,result = "ag-controller"},
		max_health = 1,
		collision_box = {{-0.9, -0.9}, {0.9, 0.9}},
		selection_box = {{-1, -1}, {1, 1}},
		inventory_size = 3,
		picture =
		{
			filename = "__Agriculture__/graphics/entity/ag-controller.png",
			priority = "high",
			width = 168,
			height = 165,
			shift = {1.6, -1.1}
		},
		energy_source =
		{
		  type = "electric",
		  usage_priority = "secondary-input",
		  emissions = 0.01 / 2.5
		},
		energy_usage = "30kW",
	},
	-- Concept stolen from Treefarm.
	{
		type = "smart-container",
		name = "ag-controller-overlay",
		order="d[remnants]-c[wall]",
		icon = "__Agriculture__/graphics/items/ag-controller.png",
		flags = {"placeable-neutral", "player-creation"},
		minable = {mining_time = 1,result = "ag-controller"},
		max_health = 1,
		collision_box = {{-0.9, -0.9}, {0.9, 0.9}},
		selection_box = {{-1, -1}, {1, 1}},
		inventory_size = 1,
		picture = {
			filename = "__Agriculture__/graphics/entity/ag-controller-overlay.png",
			priority = "extra-high",
			width = 640,
			height = 640,
			shift = {0.0, 0.0}
		}
	},
	-- Used for checking whether a tree placement is too close to something.
	-- And no, canplace{"green-tree"} doesn't work, for whatever reason
	{
		type = "container",
		name = "ag-collider",
		order="d[remnants]-c[wall]",
		icon = "__base__/graphics/icons/steel-chest.png",
		flags = {"placeable-neutral", "player-creation"},
		minable = {mining_time = 1, result = "steel-chest"},
		max_health = 200,
		corpse = "small-remnants",
		open_sound = { filename = "__base__/sound/metallic-chest-open.wav", volume=0.65 },
		close_sound = { filename = "__base__/sound/metallic-chest-close.wav", volume = 0.7 },
		resistances =
		{
		  {
			type = "fire",
			percent = 90
		  }
		},
		collision_box = {{-COLLISION_RANGE, -COLLISION_RANGE}, {COLLISION_RANGE, COLLISION_RANGE}}, -- lab: 1.2
		selection_box = {{-SELECTION_RANGE, -SELECTION_RANGE}, {SELECTION_RANGE, SELECTION_RANGE}}, -- lab: 1.5
		fast_replaceable_group = "container",
		inventory_size = 1,
		picture =
		{
		  filename = "__base__/graphics/entity/steel-chest/steel-chest.png",
		  priority = "extra-high",
		  width = 48,
		  height = 34,
		  shift = {0.2, 0}
		}
	},
})