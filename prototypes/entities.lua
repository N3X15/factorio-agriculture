data:extend({
	{
		type = "smart-container",
		name = "ag-controller",
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
})