data:extend({
	{
		name = "ltnc-show-button",
		setting_type = "runtime-per-user",
		type = "bool-setting",
		default_value = true,
	},
	{
		name = "ltnc-window-height",
		setting_type = "runtime-per-user",
		type = "int-setting",
		default_value = 750,
		minimum_value = 500,
		maximum_value = 2000,
	},
	{
		name = "ltnc-debug-level",
    setting_type = "runtime-global",    
		type = "string-setting",
    default_value = "1",
    allowed_values = {"0", "1", "2"},
	},
	{
		name = "ltnc-debug-print",
    setting_type = "runtime-global",    
		type = "bool-setting",
		default_value = false,
	},
})
