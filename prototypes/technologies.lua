data:extend({
	{
		type = "technology",
		name = "agriculture",
		icon = "__Agriculture__/graphics/tech/agriculture.png",
		effects = {
			{
				type = "unlock-recipe",
				recipe = "ag-controller"
			}
		},
		prerequisites = {
			"advanced-material-processing"
		},
		unit = {
			count = 75,
			ingredients = {
				{"science-pack-1", 1},
				{"science-pack-2", 1}
			},
			time = 30
		}
	}
})